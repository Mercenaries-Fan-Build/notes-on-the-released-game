<template>
  <div class="flex h-full">
    <!-- Sidebar -->
    <aside class="w-[320px] max-w-full flex-shrink-0 overflow-auto border-r border-gray-800 bg-gray-900 p-3">
      <h1 class="mb-2 text-sm font-semibold text-gray-100">Placement / Region Preview</h1>
      <p class="mb-3 text-[11px] leading-snug text-gray-400">
        Top-down <strong>X / Z</strong> (game space, meters).
      </p>

      <h2 class="mb-1.5 mt-3 text-[11px] font-semibold uppercase tracking-wide text-gray-500">Dataset</h2>
      <select v-model="dataSourceId" class="mb-2 w-full rounded border border-gray-700 bg-gray-800 p-1.5 text-xs text-gray-200" @change="loadData">
        <option value="maracaibo">maracaibo_placements.json</option>
        <option value="layers_static">layers_static.json (full world)</option>
      </select>

      <h2 class="mb-1.5 mt-3 text-[11px] font-semibold uppercase tracking-wide text-gray-500">Filters</h2>
      <label class="mb-1 flex items-center gap-1.5 text-[11px] text-gray-300">
        <input v-model="showLs" type="checkbox" class="accent-blue-500" /> layers_static
      </label>
      <label class="mb-1 flex items-center gap-1.5 text-[11px] text-gray-300">
        <input v-model="showVz" type="checkbox" class="accent-blue-500" /> vz_state
      </label>
      <label class="mt-1 block text-[11px] text-gray-400">Source substring</label>
      <input v-model="sourceFilterText" type="text" placeholder="e.g. mar_city" class="mb-2 w-full rounded border border-gray-700 bg-gray-800 p-1.5 text-xs text-gray-200" />

      <h2 class="mb-1.5 mt-3 text-[11px] font-semibold uppercase tracking-wide text-gray-500">Bbox overlay</h2>
      <p class="mb-1.5 text-[10px] text-gray-500">Drag edges/corners on the map, or type values. Shift+drag to draw.</p>
      <div class="mb-1.5 grid grid-cols-2 gap-x-2 gap-y-1">
        <label class="text-[10px] text-gray-400">x_min <input v-model="bboxXMin" type="text" class="mt-0.5 w-full rounded border border-gray-700 bg-gray-800 p-1 text-xs text-gray-200" /></label>
        <label class="text-[10px] text-gray-400">x_max <input v-model="bboxXMax" type="text" class="mt-0.5 w-full rounded border border-gray-700 bg-gray-800 p-1 text-xs text-gray-200" /></label>
        <label class="text-[10px] text-gray-400">z_min <input v-model="bboxZMin" type="text" class="mt-0.5 w-full rounded border border-gray-700 bg-gray-800 p-1 text-xs text-gray-200" /></label>
        <label class="text-[10px] text-gray-400">z_max <input v-model="bboxZMax" type="text" class="mt-0.5 w-full rounded border border-gray-700 bg-gray-800 p-1 text-xs text-gray-200" /></label>
      </div>

      <h2 class="mb-1 mt-3 text-[11px] font-semibold uppercase tracking-wide text-gray-500">Selection</h2>
      <pre class="max-h-[180px] overflow-auto rounded border border-gray-700 bg-gray-800 p-2 text-[11px] text-gray-300" style="white-space: pre-wrap; word-break: break-all;">{{ selectedDetail }}</pre>
    </aside>

    <!-- Map area -->
    <div class="flex flex-1 flex-col min-w-[280px] min-h-0">
      <div class="border-b border-gray-800 px-2.5 py-1.5 text-[11px] text-gray-500">
        Wheel zoom &middot; drag pan &middot; click dot to select
      </div>
      <canvas
        ref="canvasEl"
        class="flex-1 cursor-crosshair bg-[#0d0d10]"
        @mousedown="onMouseDown"
        @wheel.prevent="onWheel"
        @click="onClick"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, watch } from 'vue'

const canvasEl = ref(null)
const dataSourceId = ref('maracaibo')
const showLs = ref(true)
const showVz = ref(true)
const sourceFilterText = ref('')
const bboxXMin = ref('')
const bboxXMax = ref('')
const bboxZMin = ref('')
const bboxZMax = ref('')
const selectedDetail = ref('Click a dot…')

let placements = []
let filtered = []
let world = { minX: 0, maxX: 1, minZ: 0, maxZ: 1 }
let panX = 0, panZ = 0, zoom = 1
let dragging = false, dragStart = null, lastPan = null
const PAD = 40

function classifyPlacement(p) {
  if (p.ecs?.LightObject) return 'light'
  const ent = (p.entity_name || '').toLowerCase()
  if (/^road\b|_env_|_plant|_rock|_tree|_palm|_bush|_foliage/.test(ent)) return 'cell_prop'
  if (/pmcoutpost|_veh_|_bld_|helicopter|boat_|skyscraper/.test(ent)) return 'hero'
  return 'other'
}

function dotColor(p) {
  if ((p.block_type || '') === 'vz_state') return '#e8a040'
  const kind = classifyPlacement(p)
  if (kind === 'light') return '#e8d040'
  if (kind === 'cell_prop') return '#666888'
  if (kind === 'hero') return '#6ad46a'
  return '#4a9fe8'
}

function computeWorldBounds(pts) {
  let minX = Infinity, maxX = -Infinity, minZ = Infinity, maxZ = -Infinity
  for (const p of pts) {
    const pos = p.position || {}
    minX = Math.min(minX, pos.x ?? 0)
    maxX = Math.max(maxX, pos.x ?? 0)
    minZ = Math.min(minZ, pos.z ?? 0)
    maxZ = Math.max(maxZ, pos.z ?? 0)
  }
  if (!Number.isFinite(minX)) return { minX: -2000, maxX: 2000, minZ: -2000, maxZ: 2000 }
  const mx = (maxX - minX) * 0.05
  const mz = (maxZ - minZ) * 0.05
  return { minX: minX - mx, maxX: maxX + mx, minZ: minZ - mz, maxZ: maxZ + mz }
}

function worldToScreen(x, z) {
  const canvas = canvasEl.value
  if (!canvas) return { px: 0, py: 0 }
  const w = canvas.width - PAD * 2, h = canvas.height - PAD * 2
  const spanX = Math.max(1e-6, world.maxX - world.minX)
  const spanZ = Math.max(1e-6, world.maxZ - world.minZ)
  return {
    px: PAD + (1 - (x - world.minX) / spanX) * w * zoom + panX,
    py: PAD + (1 - (z - world.minZ) / spanZ) * h * zoom + panZ,
  }
}

function screenToWorld(px, py) {
  const canvas = canvasEl.value
  if (!canvas) return { x: 0, z: 0 }
  const w = canvas.width - PAD * 2, h = canvas.height - PAD * 2
  const spanX = Math.max(1e-6, world.maxX - world.minX)
  const spanZ = Math.max(1e-6, world.maxZ - world.minZ)
  return {
    x: world.minX + (1 - (px - panX - PAD) / (w * zoom)) * spanX,
    z: world.minZ + (1 - (py - panZ - PAD) / (h * zoom)) * spanZ,
  }
}

function applyFilters() {
  const sf = sourceFilterText.value.trim().toLowerCase()
  filtered = placements.filter(p => {
    const bt = p.block_type || ''
    if (bt === 'layers_static' && !showLs.value) return false
    if (bt === 'vz_state' && !showVz.value) return false
    if (sf && !(p.source || '').toLowerCase().includes(sf)) return false
    return true
  })
  world = computeWorldBounds(filtered)
  draw()
}

function draw() {
  const canvas = canvasEl.value
  if (!canvas) return
  const ctx = canvas.getContext('2d')
  const w = canvas.width, h = canvas.height
  ctx.fillStyle = '#0d0d10'
  ctx.fillRect(0, 0, w, h)

  ctx.strokeStyle = '#333'
  ctx.lineWidth = 1
  const o = worldToScreen(0, 0)
  ctx.beginPath()
  ctx.moveTo(o.px, 0); ctx.lineTo(o.px, h)
  ctx.moveTo(0, o.py); ctx.lineTo(w, o.py)
  ctx.stroke()

  const bx0 = parseFloat(bboxXMin.value), bx1 = parseFloat(bboxXMax.value)
  const bz0 = parseFloat(bboxZMin.value), bz1 = parseFloat(bboxZMax.value)
  if ([bx0, bx1, bz0, bz1].every(Number.isFinite)) {
    const c1 = worldToScreen(bx0, bz0), c2 = worldToScreen(bx1, bz1)
    const rx = Math.min(c1.px, c2.px), ry = Math.min(c1.py, c2.py)
    const rw = Math.abs(c2.px - c1.px), rh = Math.abs(c2.py - c1.py)
    ctx.fillStyle = 'rgba(106, 212, 106, 0.06)'
    ctx.fillRect(rx, ry, rw, rh)
    ctx.strokeStyle = '#6ad46a'
    ctx.lineWidth = 2
    ctx.strokeRect(rx, ry, rw, rh)
  }

  for (const p of filtered) {
    const pos = p.position || {}
    const { px, py } = worldToScreen(pos.x ?? 0, pos.z ?? 0)
    ctx.fillStyle = dotColor(p)
    ctx.beginPath()
    ctx.arc(px, py, 1.2, 0, Math.PI * 2)
    ctx.fill()
  }

  ctx.fillStyle = '#888'
  ctx.font = '11px system-ui'
  ctx.fillText(`points: ${filtered.length} / ${placements.length}`, 8, 16)
}

function canvasCoords(e) {
  const canvas = canvasEl.value
  const rect = canvas.getBoundingClientRect()
  return {
    sx: ((e.clientX - rect.left) / rect.width) * canvas.width,
    sy: ((e.clientY - rect.top) / rect.height) * canvas.height,
  }
}

function pickPlacement(clientX, clientY) {
  const canvas = canvasEl.value
  const rect = canvas.getBoundingClientRect()
  const sx = ((clientX - rect.left) / rect.width) * canvas.width
  const sy = ((clientY - rect.top) / rect.height) * canvas.height
  let best = null, bestD = 12
  for (const p of filtered) {
    const pos = p.position || {}
    const { px, py } = worldToScreen(pos.x ?? 0, pos.z ?? 0)
    const d = Math.hypot(px - sx, py - sy)
    if (d < bestD) { bestD = d; best = p }
  }
  return best
}

function onMouseDown(e) {
  dragging = true
  dragStart = { x: e.clientX, y: e.clientY }
  lastPan = { panX, panZ }
}

function onMouseMove(e) {
  if (!dragging || !dragStart || !lastPan) return
  panX = lastPan.panX + (e.clientX - dragStart.x)
  panZ = lastPan.panZ + (e.clientY - dragStart.y)
  draw()
}

function onMouseUp() { dragging = false }

function onWheel(e) {
  const { sx, sy } = canvasCoords(e)
  const worldBefore = screenToWorld(sx, sy)
  zoom = Math.min(40, Math.max(0.2, zoom * (e.deltaY > 0 ? 0.92 : 1.08)))
  const after = worldToScreen(worldBefore.x, worldBefore.z)
  panX += sx - after.px
  panZ += sy - after.py
  draw()
}

function onClick(e) {
  const p = pickPlacement(e.clientX, e.clientY)
  selectedDetail.value = p ? JSON.stringify(p, null, 2) : 'No point near click.'
}

function resizeCanvas() {
  const canvas = canvasEl.value
  if (!canvas) return
  const wrap = canvas.parentElement
  const r = wrap.getBoundingClientRect()
  canvas.width = Math.max(400, Math.floor(r.width))
  canvas.height = Math.max(320, Math.floor(r.height - 32))
  draw()
}

async function loadData() {
  const useFull = dataSourceId.value === 'layers_static'
  const url = useFull ? '/api/placements-layers-static.json' : '/api/placements-maracaibo.json'
  try {
    const res = await fetch(url)
    if (!res.ok) { selectedDetail.value = `Failed: ${res.status}`; return }
    const data = await res.json()
    placements = Array.isArray(data) ? data : data.placements || []
    if (data.bbox) {
      bboxXMin.value = data.bbox.x_min ?? ''
      bboxXMax.value = data.bbox.x_max ?? ''
      bboxZMin.value = data.bbox.z_min ?? ''
      bboxZMax.value = data.bbox.z_max ?? ''
    }
    applyFilters()
  } catch (e) {
    selectedDetail.value = `Load error: ${e.message}`
  }
}

watch([showLs, showVz, sourceFilterText], applyFilters)
watch([bboxXMin, bboxXMax, bboxZMin, bboxZMax], draw)

onMounted(() => {
  window.addEventListener('mousemove', onMouseMove)
  window.addEventListener('mouseup', onMouseUp)
  window.addEventListener('resize', resizeCanvas)
  resizeCanvas()
  loadData()
})

onBeforeUnmount(() => {
  window.removeEventListener('mousemove', onMouseMove)
  window.removeEventListener('mouseup', onMouseUp)
  window.removeEventListener('resize', resizeCanvas)
})
</script>
