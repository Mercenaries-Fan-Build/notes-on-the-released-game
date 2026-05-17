/**
 * Top-down X/Z canvas for placement bbox tool.
 */

/** @param {CanvasRenderingContext2D} ctx */
export function createMapView(canvas, hooks = {}) {
  const ctx = canvas.getContext('2d')
  let panX = 0
  let panZ = 0
  let zoom = 1
  let dragging = false
  let dragStart = null
  let lastPan = null
  let world = { minX: -2000, maxX: 2000, minZ: -2000, maxZ: 2000 }

  /** @type {object[]} */
  let points = []
  /** @type {import('./placement-bbox-store.js').BboxRegion[]} */
  let regions = []
  let activeRegionId = null
  let highlightKeys = new Set()

  function computeWorldBounds(pts) {
    let minX = Infinity
    let maxX = -Infinity
    let minZ = Infinity
    let maxZ = -Infinity
    for (const p of pts) {
      const pos = p.position || {}
      const x = pos.x ?? 0
      const z = pos.z ?? 0
      minX = Math.min(minX, x)
      maxX = Math.max(maxX, x)
      minZ = Math.min(minZ, z)
      maxZ = Math.max(maxZ, z)
    }
    if (!Number.isFinite(minX)) {
      return { minX: -2000, maxX: 2000, minZ: -2000, maxZ: 2000 }
    }
    const mx = Math.max(50, (maxX - minX) * 0.05)
    const mz = Math.max(50, (maxZ - minZ) * 0.05)
    return { minX: minX - mx, maxX: maxX + mx, minZ: minZ - mz, maxZ: maxZ + mz }
  }

  function worldToScreen(x, z) {
    const pad = 36
    const w = canvas.width - pad * 2
    const h = canvas.height - pad * 2
    const spanX = Math.max(1e-6, world.maxX - world.minX)
    const spanZ = Math.max(1e-6, world.maxZ - world.minZ)
    const cx = (x - world.minX) / spanX
    const cz = (z - world.minZ) / spanZ
    return {
      px: pad + (1 - cx) * w * zoom + panX,
      py: pad + (1 - cz) * h * zoom + panZ,
    }
  }

  function screenToWorld(px, py) {
    const pad = 36
    const w = canvas.width - pad * 2
    const h = canvas.height - pad * 2
    const spanX = Math.max(1e-6, world.maxX - world.minX)
    const spanZ = Math.max(1e-6, world.maxZ - world.minZ)
    const cx = 1 - (px - panX - pad) / (w * zoom)
    const cz = 1 - (py - panZ - pad) / (h * zoom)
    return {
      x: world.minX + cx * spanX,
      z: world.minZ + cz * spanZ,
    }
  }

  function drawRegion(bbox, color, lineWidth, dashed) {
    const c1 = worldToScreen(bbox.x_min, bbox.z_min)
    const c2 = worldToScreen(bbox.x_max, bbox.z_max)
    ctx.strokeStyle = color
    ctx.lineWidth = lineWidth
    if (dashed) ctx.setLineDash([6, 4])
    else ctx.setLineDash([])
    ctx.strokeRect(
      Math.min(c1.px, c2.px),
      Math.min(c1.py, c2.py),
      Math.abs(c2.px - c1.px),
      Math.abs(c2.py - c1.py),
    )
    ctx.setLineDash([])
  }

  function draw() {
    const w = canvas.width
    const h = canvas.height
    ctx.fillStyle = '#0d0d10'
    ctx.fillRect(0, 0, w, h)

    ctx.strokeStyle = '#333'
    ctx.lineWidth = 1
    const o = worldToScreen(0, 0)
    ctx.beginPath()
    ctx.moveTo(o.px, 0)
    ctx.lineTo(o.px, h)
    ctx.moveTo(0, o.py)
    ctx.lineTo(w, o.py)
    ctx.stroke()

    for (const r of regions) {
      const active = r.id === activeRegionId
      drawRegion(r, active ? '#6ad46a' : '#4a7aaa', active ? 2.5 : 1.5, !active)
    }

    for (const p of points) {
      const pos = p.position || {}
      const { px, py } = worldToScreen(pos.x ?? 0, pos.z ?? 0)
      const hl = highlightKeys.has(p._mapKey)
      ctx.fillStyle = hl ? '#ffcc44' : p._mapColor || '#4a9fe8'
      ctx.beginPath()
      ctx.arc(px, py, hl ? 3 : 1.4, 0, Math.PI * 2)
      ctx.fill()
      if (hl && p._yawRad != null) {
        const len = 10
        const dx = Math.sin(p._yawRad) * len
        const dy = -Math.cos(p._yawRad) * len
        ctx.strokeStyle = '#ffcc44'
        ctx.lineWidth = 1.5
        ctx.beginPath()
        ctx.moveTo(px, py)
        ctx.lineTo(px + dx, py + dy)
        ctx.stroke()
      }
    }

    ctx.fillStyle = '#888'
    ctx.font = '11px system-ui'
    ctx.fillText(`map points: ${points.length}`, 8, 16)

    // Compass rose — mirrors UE top-down viewport (180-rotated game coords)
    // After 180 flip: screen left = game +X = UE +X, screen up = game +Z = UE +Y
    const roseCx = w - 56
    const roseCy = h - 56
    const armLen = 28
    ctx.globalAlpha = 0.85

    // UE +X → left (game +X after 180 flip)
    ctx.strokeStyle = '#e05050'
    ctx.lineWidth = 2
    ctx.beginPath()
    ctx.moveTo(roseCx, roseCy)
    ctx.lineTo(roseCx - armLen, roseCy)
    ctx.stroke()
    ctx.fillStyle = '#e05050'
    ctx.font = 'bold 11px system-ui'
    ctx.textAlign = 'right'
    ctx.fillText('UE +X', roseCx - armLen - 3, roseCy + 4)
    ctx.textAlign = 'left'

    // UE +Y → up (game +Z after 180 flip)
    ctx.strokeStyle = '#50e050'
    ctx.lineWidth = 2
    ctx.beginPath()
    ctx.moveTo(roseCx, roseCy)
    ctx.lineTo(roseCx, roseCy - armLen)
    ctx.stroke()
    ctx.fillStyle = '#50e050'
    ctx.fillText('UE +Y', roseCx + 5, roseCy - armLen + 4)

    // UE -X → right (dashed)
    ctx.strokeStyle = '#e05050'
    ctx.lineWidth = 1
    ctx.setLineDash([3, 3])
    ctx.beginPath()
    ctx.moveTo(roseCx, roseCy)
    ctx.lineTo(roseCx + armLen, roseCy)
    ctx.stroke()
    ctx.setLineDash([])

    // UE -Y → down (dashed)
    ctx.strokeStyle = '#50e050'
    ctx.lineWidth = 1
    ctx.setLineDash([3, 3])
    ctx.beginPath()
    ctx.moveTo(roseCx, roseCy)
    ctx.lineTo(roseCx, roseCy + armLen)
    ctx.stroke()
    ctx.setLineDash([])

    // Center dot
    ctx.fillStyle = '#fff'
    ctx.beginPath()
    ctx.arc(roseCx, roseCy, 2.5, 0, Math.PI * 2)
    ctx.fill()

    // Z label
    ctx.fillStyle = '#6080cc'
    ctx.font = '9px system-ui'
    ctx.fillText('UE +Z = height', roseCx - 22, roseCy + armLen + 14)

    ctx.globalAlpha = 1.0
  }

  function pick(clientX, clientY) {
    const rect = canvas.getBoundingClientRect()
    const sx = ((clientX - rect.left) / rect.width) * canvas.width
    const sy = ((clientY - rect.top) / rect.height) * canvas.height
    let best = null
    let bestD = 14
    for (const p of points) {
      const pos = p.position || {}
      const { px, py } = worldToScreen(pos.x ?? 0, pos.z ?? 0)
      const d = Math.hypot(px - sx, py - sy)
      if (d < bestD) {
        bestD = d
        best = p
      }
    }
    return best
  }

  canvas.addEventListener('mousedown', (e) => {
    dragging = true
    dragStart = { x: e.clientX, y: e.clientY }
    lastPan = { panX, panZ }
  })
  window.addEventListener('mouseup', () => {
    dragging = false
  })
  window.addEventListener('mousemove', (e) => {
    if (!dragging || !dragStart || !lastPan) return
    panX = lastPan.panX + (e.clientX - dragStart.x)
    panZ = lastPan.panZ + (e.clientY - dragStart.y)
    draw()
  })
  canvas.addEventListener('wheel', (e) => {
    e.preventDefault()
    const f = e.deltaY > 0 ? 0.92 : 1.08
    zoom = Math.min(50, Math.max(0.15, zoom * f))
    draw()
  })
  canvas.addEventListener('click', (e) => {
    const p = pick(e.clientX, e.clientY)
    if (p && hooks.onPick) hooks.onPick(p._raw || p)
  })

  return {
    setData(pts, regionList, activeId, keys) {
      points = pts
      regions = regionList
      activeRegionId = activeId
      highlightKeys = keys || new Set()
      world = computeWorldBounds(
        pts.map((p) => ({ position: p.position || { x: p.x, z: p.z } })),
      )
      draw()
    },
    fitToRegions(regionList) {
      if (!regionList.length) return
      let minX = Infinity
      let maxX = -Infinity
      let minZ = Infinity
      let maxZ = -Infinity
      for (const r of regionList) {
        minX = Math.min(minX, r.x_min)
        maxX = Math.max(maxX, r.x_max)
        minZ = Math.min(minZ, r.z_min)
        maxZ = Math.max(maxZ, r.z_max)
      }
      world = { minX, maxX, minZ, maxZ }
      panX = 0
      panZ = 0
      zoom = 1
      draw()
    },
    draw,
    screenToWorld,
    resize() {
      const wrap = canvas.parentElement
      if (!wrap) return
      const r = wrap.getBoundingClientRect()
      canvas.width = Math.max(320, Math.floor(r.width))
      canvas.height = Math.max(240, Math.floor(r.height))
      draw()
    },
  }
}
