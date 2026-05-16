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

function worldToScreen(x, z) {
  const pad = 40
  const w = canvas.width - pad * 2
  const h = canvas.height - pad * 2
  const spanX = Math.max(1e-6, world.maxX - world.minX)
  const spanZ = Math.max(1e-6, world.maxZ - world.minZ)
  const cx = (x - world.minX) / spanX
  const cz = (z - world.minZ) / spanZ
  const px = pad + cx * w * zoom + panX
  const py = pad + cz * h * zoom + panZ
  return { px, py }
}

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
  if ([bx0, bx1, bz0, bz1].every((n) => Number.isFinite(n))) {
    const c1 = worldToScreen(bx0, bz0)
    const c2 = worldToScreen(bx1, bz1)
    ctx.strokeStyle = '#6ad46a'
    ctx.lineWidth = 2
    ctx.strokeRect(
      Math.min(c1.px, c2.px),
      Math.min(c1.py, c2.py),
      Math.abs(c2.px - c1.px),
      Math.abs(c2.py - c1.py),
    )
  }

  for (const p of filtered) {
    const pos = p.position || {}
    const { px, py } = worldToScreen(pos.x ?? 0, pos.z ?? 0)
    const bt = p.block_type || ''
    ctx.fillStyle = bt === 'vz_state' ? '#e8a040' : '#4a9fe8'
    ctx.beginPath()
    ctx.arc(px, py, 1.2, 0, Math.PI * 2)
    ctx.fill()
  }

  ctx.fillStyle = '#888'
  ctx.font = '11px system-ui'
  ctx.fillText(`points: ${filtered.length} / ${placements.length}`, 8, 16)
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
  const dx = e.clientX - dragStart.x
  const dy = e.clientY - dragStart.y
  panX = lastPan.panX + dx
  panZ = lastPan.panZ + dy
  draw()
})

canvas.addEventListener('wheel', (e) => {
  e.preventDefault()
  const f = e.deltaY > 0 ? 0.92 : 1.08
  zoom = Math.min(40, Math.max(0.2, zoom * f))
  draw()
})

canvas.addEventListener('click', (e) => {
  const p = pickPlacement(e.clientX, e.clientY)
  if (!p) {
    detailEl.textContent = 'No point near click.'
    return
  }
  detailEl.textContent = JSON.stringify(p, null, 2)
})

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
  el.addEventListener('change', draw)
}

;[cbLs, cbVz, srcFilter].forEach((el) => el.addEventListener('input', applyFilters))

function resizeCanvas() {
  const wrap = canvas.parentElement
  const r = wrap.getBoundingClientRect()
  canvas.width = Math.max(400, Math.floor(r.width))
  canvas.height = Math.max(320, Math.floor(window.innerHeight * 0.55))
  draw()
}
window.addEventListener('resize', resizeCanvas)

async function load() {
  const res = await fetch('/api/placements-maracaibo.json')
  if (!res.ok) {
    detailEl.textContent = `Failed to load placements: ${res.status} ${await res.text()}`
    return
  }
  const data = await res.json()
  placements = data.placements || []
  syncBboxInputs(data.bbox)
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
