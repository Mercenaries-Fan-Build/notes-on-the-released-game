/**
 * 2D placement map + optional Three.js GLB spot-check for Maracaibo pipeline tuning.
 */
import * as THREE from 'three'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js'

const canvas = document.getElementById('canvas2d')
const ctx = canvas.getContext('2d')
const detailEl = document.getElementById('detail')
const exportOut = document.getElementById('exportOut')
const cbLs = document.getElementById('cbLs')
const cbVz = document.getElementById('cbVz')
const srcFilter = document.getElementById('srcFilter')
const dataSource = document.getElementById('dataSource')

/** @typedef {'light' | 'cell_prop' | 'hero' | 'other'} PlacementKind */

/** @param {object} p */
function classifyPlacement(p) {
  if (p.ecs?.LightObject) return 'light'
  const ent = (p.entity_name || '').toLowerCase()
  if (/^road\b|_env_|_plant|_rock|_tree|_palm|_bush|_foliage|_foliage/.test(ent)) return 'cell_prop'
  if (/pmcoutpost|_veh_|_bld_|helicopter|boat_|skyscraper/.test(ent)) return 'hero'
  return 'other'
}

/** @param {object} p */
function dotColor(p) {
  const bt = p.block_type || ''
  if (bt === 'vz_state') return '#e8a040'
  const kind = classifyPlacement(p)
  if (kind === 'light') return '#e8d040'
  if (kind === 'cell_prop') return '#666888'
  if (kind === 'hero') return '#6ad46a'
  return '#4a9fe8'
}
const bboxInputs = {
  x_min: document.getElementById('bx0'),
  x_max: document.getElementById('bx1'),
  z_min: document.getElementById('bz0'),
  z_max: document.getElementById('bz1'),
  y_min: document.getElementById('by0'),
  y_max: document.getElementById('by1'),
}

let placements = []
let filtered = []
let world = { minX: 0, maxX: 1, minZ: 0, maxZ: 1 }

let panX = 0
let panZ = 0
let zoom = 1
let dragging = false
let dragStart = null
let lastPan = null

const PAD = 40

function worldToScreen(x, z) {
  const w = canvas.width - PAD * 2
  const h = canvas.height - PAD * 2
  const spanX = Math.max(1e-6, world.maxX - world.minX)
  const spanZ = Math.max(1e-6, world.maxZ - world.minZ)
  const cx = (x - world.minX) / spanX
  const cz = (z - world.minZ) / spanZ
  const px = PAD + (1 - cx) * w * zoom + panX
  const py = PAD + (1 - cz) * h * zoom + panZ
  return { px, py }
}

function screenToWorld(px, py) {
  const w = canvas.width - PAD * 2
  const h = canvas.height - PAD * 2
  const spanX = Math.max(1e-6, world.maxX - world.minX)
  const spanZ = Math.max(1e-6, world.maxZ - world.minZ)
  const cx = 1 - (px - panX - PAD) / (w * zoom)
  const cz = 1 - (py - panZ - PAD) / (h * zoom)
  return {
    x: world.minX + cx * spanX,
    z: world.minZ + cz * spanZ,
  }
}

// --- Bbox handle dragging ---
const HANDLE_RADIUS = 7
let bboxDragMode = null // 'corner-tl' | 'corner-tr' | 'corner-bl' | 'corner-br' | 'edge-l' | 'edge-r' | 'edge-t' | 'edge-b' | 'draw' | null
let bboxDrawStart = null

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
  const mx = (maxX - minX) * 0.05
  const mz = (maxZ - minZ) * 0.05
  return { minX: minX - mx, maxX: maxX + mx, minZ: minZ - mz, maxZ: maxZ + mz }
}

function applyFilters() {
  const sf = (srcFilter.value || '').trim().toLowerCase()
  filtered = placements.filter((p) => {
    const bt = p.block_type || ''
    if (bt === 'layers_static' && !cbLs.checked) return false
    if (bt === 'vz_state' && !cbVz.checked) return false
    if (sf && !(p.source || '').toLowerCase().includes(sf)) return false
    return true
  })
  world = computeWorldBounds(filtered)
  draw()
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

  const bx0 = parseFloat(bboxInputs.x_min.value)
  const bx1 = parseFloat(bboxInputs.x_max.value)
  const bz0 = parseFloat(bboxInputs.z_min.value)
  const bz1 = parseFloat(bboxInputs.z_max.value)
  const bboxValid = [bx0, bx1, bz0, bz1].every((n) => Number.isFinite(n))
  if (bboxValid) {
    const c1 = worldToScreen(bx0, bz0)
    const c2 = worldToScreen(bx1, bz1)
    const rx = Math.min(c1.px, c2.px)
    const ry = Math.min(c1.py, c2.py)
    const rw = Math.abs(c2.px - c1.px)
    const rh = Math.abs(c2.py - c1.py)

    // Fill with translucent overlay
    ctx.fillStyle = 'rgba(106, 212, 106, 0.06)'
    ctx.fillRect(rx, ry, rw, rh)
    ctx.strokeStyle = '#6ad46a'
    ctx.lineWidth = 2
    ctx.strokeRect(rx, ry, rw, rh)

    // Draw corner handles
    const corners = [
      { px: rx, py: ry },
      { px: rx + rw, py: ry },
      { px: rx, py: ry + rh },
      { px: rx + rw, py: ry + rh },
    ]
    for (const c of corners) {
      ctx.fillStyle = '#6ad46a'
      ctx.beginPath()
      ctx.arc(c.px, c.py, HANDLE_RADIUS, 0, Math.PI * 2)
      ctx.fill()
      ctx.strokeStyle = '#fff'
      ctx.lineWidth = 1.5
      ctx.stroke()
    }

    // Edge midpoints
    const edges = [
      { px: rx + rw / 2, py: ry },
      { px: rx + rw / 2, py: ry + rh },
      { px: rx, py: ry + rh / 2 },
      { px: rx + rw, py: ry + rh / 2 },
    ]
    for (const e of edges) {
      ctx.fillStyle = '#4a9fe8'
      ctx.beginPath()
      ctx.arc(e.px, e.py, 5, 0, Math.PI * 2)
      ctx.fill()
      ctx.strokeStyle = '#fff'
      ctx.lineWidth = 1
      ctx.stroke()
    }

    // Dimension labels
    const spanXWorld = Math.abs(bx1 - bx0)
    const spanZWorld = Math.abs(bz1 - bz0)
    ctx.fillStyle = '#6ad46a'
    ctx.font = '10px system-ui'
    ctx.textAlign = 'center'
    ctx.fillText(`${spanXWorld.toFixed(0)}m`, rx + rw / 2, ry - 8)
    ctx.save()
    ctx.translate(rx - 8, ry + rh / 2)
    ctx.rotate(-Math.PI / 2)
    ctx.fillText(`${spanZWorld.toFixed(0)}m`, 0, 0)
    ctx.restore()
    ctx.textAlign = 'left'
  }

  let nLight = 0
  let nCell = 0
  let nHero = 0
  for (const p of filtered) {
    const pos = p.position || {}
    const { px, py } = worldToScreen(pos.x ?? 0, pos.z ?? 0)
    const kind = classifyPlacement(p)
    if (kind === 'light') nLight += 1
    else if (kind === 'cell_prop') nCell += 1
    else if (kind === 'hero') nHero += 1
    ctx.fillStyle = dotColor(p)
    ctx.beginPath()
    ctx.arc(px, py, 1.2, 0, Math.PI * 2)
    ctx.fill()
  }

  ctx.fillStyle = '#888'
  ctx.font = '11px system-ui'
  ctx.fillText(
    `points: ${filtered.length} / ${placements.length}  lights:${nLight}  cell:${nCell}  hero:${nHero}`,
    8,
    16,
  )

  // Compass rose — mirrors UE top-down viewport (180-rotated game coords)
  const roseCx = w - 56
  const roseCy = h - 56
  const armLen = 28
  ctx.globalAlpha = 0.85

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

  ctx.strokeStyle = '#50e050'
  ctx.lineWidth = 2
  ctx.beginPath()
  ctx.moveTo(roseCx, roseCy)
  ctx.lineTo(roseCx, roseCy - armLen)
  ctx.stroke()
  ctx.fillStyle = '#50e050'
  ctx.fillText('UE +Y', roseCx + 5, roseCy - armLen + 4)

  ctx.strokeStyle = '#e05050'
  ctx.lineWidth = 1
  ctx.setLineDash([3, 3])
  ctx.beginPath()
  ctx.moveTo(roseCx, roseCy)
  ctx.lineTo(roseCx + armLen, roseCy)
  ctx.stroke()
  ctx.setLineDash([])

  ctx.strokeStyle = '#50e050'
  ctx.lineWidth = 1
  ctx.setLineDash([3, 3])
  ctx.beginPath()
  ctx.moveTo(roseCx, roseCy)
  ctx.lineTo(roseCx, roseCy + armLen)
  ctx.stroke()
  ctx.setLineDash([])

  ctx.fillStyle = '#fff'
  ctx.beginPath()
  ctx.arc(roseCx, roseCy, 2.5, 0, Math.PI * 2)
  ctx.fill()

  ctx.fillStyle = '#6080cc'
  ctx.font = '9px system-ui'
  ctx.fillText('UE +Z = height', roseCx - 22, roseCy + armLen + 14)

  ctx.globalAlpha = 1.0
}

function pickPlacement(clientX, clientY) {
  const rect = canvas.getBoundingClientRect()
  const sx = ((clientX - rect.left) / rect.width) * canvas.width
  const sy = ((clientY - rect.top) / rect.height) * canvas.height
  let best = null
  let bestD = 12
  for (const p of filtered) {
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

function canvasCoords(e) {
  const rect = canvas.getBoundingClientRect()
  return {
    sx: ((e.clientX - rect.left) / rect.width) * canvas.width,
    sy: ((e.clientY - rect.top) / rect.height) * canvas.height,
  }
}

function hitTestBboxHandle(sx, sy) {
  const bx0 = parseFloat(bboxInputs.x_min.value)
  const bx1 = parseFloat(bboxInputs.x_max.value)
  const bz0 = parseFloat(bboxInputs.z_min.value)
  const bz1 = parseFloat(bboxInputs.z_max.value)
  if (![bx0, bx1, bz0, bz1].every((n) => Number.isFinite(n))) return null

  const c1 = worldToScreen(bx0, bz0)
  const c2 = worldToScreen(bx1, bz1)
  const rx = Math.min(c1.px, c2.px)
  const ry = Math.min(c1.py, c2.py)
  const rw = Math.abs(c2.px - c1.px)
  const rh = Math.abs(c2.py - c1.py)

  const corners = [
    { mode: 'corner-tl', px: rx, py: ry },
    { mode: 'corner-tr', px: rx + rw, py: ry },
    { mode: 'corner-bl', px: rx, py: ry + rh },
    { mode: 'corner-br', px: rx + rw, py: ry + rh },
  ]
  for (const c of corners) {
    if (Math.hypot(sx - c.px, sy - c.py) <= HANDLE_RADIUS + 2) return c.mode
  }
  const edges = [
    { mode: 'edge-t', px: rx + rw / 2, py: ry },
    { mode: 'edge-b', px: rx + rw / 2, py: ry + rh },
    { mode: 'edge-l', px: rx, py: ry + rh / 2 },
    { mode: 'edge-r', px: rx + rw, py: ry + rh / 2 },
  ]
  for (const e of edges) {
    if (Math.hypot(sx - e.px, sy - e.py) <= 7) return e.mode
  }
  return null
}

canvas.addEventListener('mousedown', (e) => {
  const { sx, sy } = canvasCoords(e)

  // Shift+drag draws a brand new bbox
  if (e.shiftKey) {
    bboxDragMode = 'draw'
    bboxDrawStart = screenToWorld(sx, sy)
    return
  }

  // Check bbox handles
  const hit = hitTestBboxHandle(sx, sy)
  if (hit) {
    bboxDragMode = hit
    canvas.style.cursor = 'grabbing'
    return
  }

  // Otherwise: pan
  dragging = true
  dragStart = { x: e.clientX, y: e.clientY }
  lastPan = { panX, panZ }
})

window.addEventListener('mouseup', (e) => {
  if (bboxDragMode === 'draw' && bboxDrawStart) {
    const { sx, sy } = canvasCoords(e)
    const end = screenToWorld(sx, sy)
    bboxInputs.x_min.value = Math.min(bboxDrawStart.x, end.x).toFixed(1)
    bboxInputs.x_max.value = Math.max(bboxDrawStart.x, end.x).toFixed(1)
    bboxInputs.z_min.value = Math.min(bboxDrawStart.z, end.z).toFixed(1)
    bboxInputs.z_max.value = Math.max(bboxDrawStart.z, end.z).toFixed(1)
    updateBboxInfo()
    draw()
  }
  bboxDragMode = null
  bboxDrawStart = null
  dragging = false
  canvas.style.cursor = 'crosshair'
})

window.addEventListener('mousemove', (e) => {
  const { sx, sy } = canvasCoords(e)

  if (bboxDragMode && bboxDragMode !== 'draw') {
    const w = screenToWorld(sx, sy)
    // Depending on which handle, update appropriate bbox field
    if (bboxDragMode.includes('l') || bboxDragMode === 'corner-tl' || bboxDragMode === 'corner-bl') {
      // Screen left = higher game X after 180 flip, so this is x_max
      bboxInputs.x_max.value = w.x.toFixed(1)
    }
    if (bboxDragMode.includes('r') || bboxDragMode === 'corner-tr' || bboxDragMode === 'corner-br') {
      bboxInputs.x_min.value = w.x.toFixed(1)
    }
    if (bboxDragMode.includes('t') || bboxDragMode === 'corner-tl' || bboxDragMode === 'corner-tr') {
      bboxInputs.z_max.value = w.z.toFixed(1)
    }
    if (bboxDragMode.includes('b') || bboxDragMode === 'corner-bl' || bboxDragMode === 'corner-br') {
      bboxInputs.z_min.value = w.z.toFixed(1)
    }
    updateBboxInfo()
    draw()
    return
  }

  if (bboxDragMode === 'draw' && bboxDrawStart) {
    const end = screenToWorld(sx, sy)
    bboxInputs.x_min.value = Math.min(bboxDrawStart.x, end.x).toFixed(1)
    bboxInputs.x_max.value = Math.max(bboxDrawStart.x, end.x).toFixed(1)
    bboxInputs.z_min.value = Math.min(bboxDrawStart.z, end.z).toFixed(1)
    bboxInputs.z_max.value = Math.max(bboxDrawStart.z, end.z).toFixed(1)
    draw()
    return
  }

  if (dragging && dragStart && lastPan) {
    const dx = e.clientX - dragStart.x
    const dy = e.clientY - dragStart.y
    panX = lastPan.panX + dx
    panZ = lastPan.panZ + dy
    draw()
    return
  }

  // Update cursor based on hover
  const hit = hitTestBboxHandle(sx, sy)
  if (hit) {
    if (hit.includes('corner')) canvas.style.cursor = 'move'
    else if (hit === 'edge-l' || hit === 'edge-r') canvas.style.cursor = 'ew-resize'
    else canvas.style.cursor = 'ns-resize'
  } else {
    canvas.style.cursor = 'crosshair'
  }
})

canvas.addEventListener('wheel', (e) => {
  e.preventDefault()
  const { sx, sy } = canvasCoords(e)
  const worldBefore = screenToWorld(sx, sy)
  const f = e.deltaY > 0 ? 0.92 : 1.08
  zoom = Math.min(40, Math.max(0.2, zoom * f))
  // Zoom toward cursor position
  const afterScreen = worldToScreen(worldBefore.x, worldBefore.z)
  panX += sx - afterScreen.px
  panZ += sy - afterScreen.py
  draw()
})

canvas.addEventListener('click', (e) => {
  if (bboxDragMode) return
  const p = pickPlacement(e.clientX, e.clientY)
  if (!p) {
    detailEl.textContent = 'No point near click.'
    return
  }
  detailEl.textContent = JSON.stringify(p, null, 2)
})

function updateBboxInfo() {
  const bx0 = parseFloat(bboxInputs.x_min.value)
  const bx1 = parseFloat(bboxInputs.x_max.value)
  const bz0 = parseFloat(bboxInputs.z_min.value)
  const bz1 = parseFloat(bboxInputs.z_max.value)
  const infoEl = document.getElementById('bboxInfo')
  if (![bx0, bx1, bz0, bz1].every((n) => Number.isFinite(n))) {
    infoEl.textContent = ''
    return
  }
  const count = filtered.filter((p) => {
    const pos = p.position || {}
    const x = pos.x ?? 0
    const z = pos.z ?? 0
    return x >= bx0 && x <= bx1 && z >= bz0 && z <= bz1
  }).length
  infoEl.textContent = `${count} placements inside bbox`
}

function syncBboxInputs(bbox) {
  if (!bbox) return
  for (const k of ['x_min', 'x_max', 'z_min', 'z_max', 'y_min', 'y_max']) {
    if (bbox[k] != null && bboxInputs[k]) bboxInputs[k].value = String(bbox[k])
  }
}

function exportCli() {
  const x0 = bboxInputs.x_min.value
  const x1 = bboxInputs.x_max.value
  const z0 = bboxInputs.z_min.value
  const z1 = bboxInputs.z_max.value
  const y0 = bboxInputs.y_min.value
  const y1 = bboxInputs.y_max.value
  exportOut.value = `python3 tools/filter_maracaibo_placements.py \\\n  --layers-static output/placements/layers_static.json \\\n  --vz-state-dir output/placements/vz_state/ \\\n  --out output/placements/maracaibo_placements.json \\\n  --x-min ${x0} --x-max ${x1} --z-min ${z0} --z-max ${z1} --y-min ${y0} --y-max ${y1}`
}

document.getElementById('btnExport').addEventListener('click', async () => {
  exportCli()
  try {
    await navigator.clipboard.writeText(exportOut.value)
    exportOut.value = '(copied to clipboard)\n' + exportOut.value
  } catch {
    /* ignore */
  }
})

for (const el of Object.values(bboxInputs)) {
  el.addEventListener('change', () => {
    updateBboxInfo()
    draw()
  })
}

document.getElementById('btnReset').addEventListener('click', () => {
  for (const el of Object.values(bboxInputs)) el.value = ''
  updateBboxInfo()
  draw()
})

;[cbLs, cbVz, srcFilter].forEach((el) => el.addEventListener('input', applyFilters))
dataSource.addEventListener('change', load)

function resizeCanvas() {
  const wrap = canvas.parentElement
  const r = wrap.getBoundingClientRect()
  canvas.width = Math.max(400, Math.floor(r.width))
  canvas.height = Math.max(320, Math.floor(window.innerHeight * 0.55))
  draw()
}
window.addEventListener('resize', resizeCanvas)

async function load() {
  const useFull = dataSource.value === 'layers_static'
  const url = useFull ? '/api/placements-layers-static.json' : '/api/placements-maracaibo.json'
  const res = await fetch(url)
  if (!res.ok) {
    detailEl.textContent = `Failed to load placements: ${res.status} ${await res.text()}`
    return
  }
  const data = await res.json()
  placements = Array.isArray(data) ? data : data.placements || []
  if (data.bbox) syncBboxInputs(data.bbox)
  applyFilters()
  exportCli()
}

resizeCanvas()
load()

/** --- Optional Three.js GLB preview --- */
let threeStarted = false
const cb3d = document.getElementById('cb3d')
const threeWrap = document.getElementById('threeWrap')

async function startThreeIfNeeded() {
  if (!cb3d.checked || threeStarted) return
  threeStarted = true
  const scene = new THREE.Scene()
  scene.background = new THREE.Color(0x1a1a1e)
  const camera = new THREE.PerspectiveCamera(50, 1, 0.1, 5000)
  camera.position.set(40, 35, 40)
  const renderer = new THREE.WebGLRenderer({ antialias: true })
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))
  threeWrap.appendChild(renderer.domElement)
  const controls = new OrbitControls(camera, renderer.domElement)
  controls.target.set(0, 0, 0)
  scene.add(new THREE.AmbientLight(0xffffff, 0.85))
  const dir = new THREE.DirectionalLight(0xffffff, 0.9)
  dir.position.set(20, 80, 30)
  scene.add(dir)

  const grid = new THREE.GridHelper(200, 40, 0x444444, 0x222222)
  scene.add(grid)

  const glbRes = await fetch('/api/maracaibo-glbs.json')
  const glbDoc = await glbRes.json()
  const first = glbDoc.items && glbDoc.items[0]
  if (first && first.url) {
    const loader = new GLTFLoader()
    loader.load(
      first.url,
      (gltf) => {
        const root = gltf.scene
        root.traverse((o) => {
          if (o.isMesh) {
            o.castShadow = true
            o.receiveShadow = true
          }
        })
        scene.add(root)
      },
      undefined,
      (err) => {
        console.warn(err)
      },
    )
  }

  function loop() {
    if (!cb3d.checked) return
    const r = threeWrap.getBoundingClientRect()
    renderer.setSize(Math.max(200, r.width), Math.max(180, r.height))
    camera.aspect = r.width / r.height
    camera.updateProjectionMatrix()
    controls.update()
    renderer.render(scene, camera)
    requestAnimationFrame(loop)
  }
  loop()
}

cb3d.addEventListener('change', () => {
  if (cb3d.checked) startThreeIfNeeded()
})
