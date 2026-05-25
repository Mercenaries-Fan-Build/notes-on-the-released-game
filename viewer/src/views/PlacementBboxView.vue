<template>
  <div class="flex h-full">
    <!-- Sidebar -->
    <aside class="w-[340px] max-w-full flex-shrink-0 overflow-auto border-r border-gray-800 bg-gray-900 p-3">
      <h1 class="mb-2 text-sm font-semibold text-gray-100">Placement Bbox &amp; Rotation QA</h1>
      <p class="mb-2 text-[10px] leading-snug text-gray-500">
        Game LH metres (X E–W, Y up, Z N–S). Overrides persist in <code>localStorage</code>.
      </p>

      <h2 class="mb-1.5 mt-3 text-[11px] font-semibold uppercase tracking-wide text-gray-500">Dataset</h2>
      <select
        v-model="selectedDataset"
        class="w-full rounded border border-gray-700 bg-gray-800 p-1.5 text-xs text-gray-200"
        @change="reloadDataset"
      >
        <option v-for="d in datasets" :key="d.id" :value="d.id">{{ d.label }}</option>
      </select>
      <div class="mt-1 text-[10px] text-gray-500">{{ datasetMeta }}</div>

      <h2 class="mb-1.5 mt-3 text-[11px] font-semibold uppercase tracking-wide text-gray-500">Named regions</h2>
      <select
        v-model="activeRegionId"
        class="w-full rounded border border-gray-700 bg-gray-800 p-1.5 text-xs text-gray-200"
        @change="onRegionChange"
      >
        <option v-for="r in regions" :key="r.id" :value="r.id">{{ r.name }}</option>
      </select>
      <ul class="mt-2 max-h-[140px] overflow-auto">
        <li
          v-for="r in regions"
          :key="r.id"
          class="mb-1 cursor-pointer rounded border p-1.5 text-[11px]"
          :class="r.id === activeRegionId ? 'border-green-500 bg-green-900/20' : 'border-transparent bg-gray-800'"
          @click="activeRegionId = r.id; onRegionChange()"
        >
          {{ r.name }}
          <br /><span class="text-[10px] text-gray-500">X {{ r.x_min }}…{{ r.x_max }} Z {{ r.z_min }}…{{ r.z_max }}</span>
        </li>
      </ul>

      <h2 class="mb-1.5 mt-3 text-[11px] font-semibold uppercase tracking-wide text-gray-500">Table filters</h2>
      <label class="mb-1 block text-[11px] text-gray-400">Entity name
        <input v-model="nameFilterText" type="text" placeholder="pmcoutpost" class="mt-0.5 w-full rounded border border-gray-700 bg-gray-800 p-1 text-xs text-gray-200" />
      </label>
      <label class="mb-1 block text-[11px] text-gray-400">Source substring
        <input v-model="sourceFilterText" type="text" placeholder="pmcoutpost_bld" class="mt-0.5 w-full rounded border border-gray-700 bg-gray-800 p-1 text-xs text-gray-200" />
      </label>
      <label class="mb-1 flex items-center gap-1.5 text-[11px] text-gray-300">
        <input v-model="showLs" type="checkbox" class="accent-blue-500" /> layers_static
      </label>
      <label class="mb-1 flex items-center gap-1.5 text-[11px] text-gray-300">
        <input v-model="showVz" type="checkbox" class="accent-blue-500" /> vz_state
      </label>
    </aside>

    <!-- Main area -->
    <div class="flex flex-1 flex-col min-w-[300px] min-h-0">
      <!-- Map -->
      <div class="border-b border-gray-800">
        <div class="px-2.5 py-1 text-[11px] text-gray-500">Wheel zoom &middot; drag pan &middot; click dot to select</div>
        <canvas ref="canvasEl" class="block h-[280px] w-full cursor-crosshair bg-[#0d0d10]" />
      </div>

      <!-- Table -->
      <div class="flex-1 overflow-auto p-2">
        <table class="w-full border-collapse text-[11px]">
          <thead>
            <tr>
              <th class="sticky top-0 z-10 cursor-pointer bg-gray-900 px-1.5 py-1 text-left" @click="toggleSort('entity_name')">entity</th>
              <th class="sticky top-0 z-10 cursor-pointer bg-gray-900 px-1.5 py-1 text-left" @click="toggleSort('x')">x</th>
              <th class="sticky top-0 z-10 cursor-pointer bg-gray-900 px-1.5 py-1 text-left" @click="toggleSort('y')">y</th>
              <th class="sticky top-0 z-10 cursor-pointer bg-gray-900 px-1.5 py-1 text-left" @click="toggleSort('z')">z</th>
              <th class="sticky top-0 z-10 cursor-pointer bg-gray-900 px-1.5 py-1 text-left" @click="toggleSort('block_type')">layer</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="row in tableRows"
              :key="row._key"
              class="border-b border-gray-800 hover:bg-white/[0.04]"
            >
              <td class="px-1.5 py-1">{{ row.entity_name || '' }}</td>
              <td class="px-1.5 py-1">{{ fmt(row.position?.x) }}</td>
              <td class="px-1.5 py-1">{{ fmt(row.position?.y) }}</td>
              <td class="px-1.5 py-1">{{ fmt(row.position?.z) }}</td>
              <td class="px-1.5 py-1">{{ row.block_type || '' }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="border-t border-gray-800 px-2.5 py-1.5 text-[11px] text-gray-500">
        {{ tableRows.length }} shown / {{ filteredTotal }} in filter &middot; {{ allPlacements.length }} loaded
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount, watch } from 'vue'
import {
  createPlacementStore,
  createRegion,
  effectivePlacement,
  placementKey,
} from '../lib/placement-bbox-store.js'

const store = createPlacementStore()
const canvasEl = ref(null)
const selectedDataset = ref('pmc_base')
const datasetMeta = ref('')
const datasets = ref([])
const activeRegionId = ref(null)
const nameFilterText = ref('')
const sourceFilterText = ref('')
const showLs = ref(true)
const showVz = ref(true)
const sortKey = ref('entity_name')
const sortDir = ref(1)

const allPlacements = ref([])
const regions = computed(() => store.getRegions())

function blockTypeSet() {
  const s = new Set()
  if (showLs.value) s.add('layers_static')
  if (showVz.value) s.add('vz_state')
  return s.size ? s : new Set(['layers_static', 'vz_state'])
}

const filteredList = computed(() => {
  return store.queryFiltered({
    activeRegionId: activeRegionId.value,
    nameFilter: nameFilterText.value,
    sourceFilter: sourceFilterText.value,
    blockTypes: blockTypeSet(),
    onlyOverridden: false,
    overrides: store.getOverrides(),
  })
})

const filteredTotal = computed(() => filteredList.value.length)

const tableRows = computed(() => {
  const rows = filteredList.value.map(p => ({
    ...p,
    _key: placementKey(p),
  }))
  rows.sort((a, b) => {
    const av = sortValue(a, sortKey.value)
    const bv = sortValue(b, sortKey.value)
    if (av < bv) return -sortDir.value
    if (av > bv) return sortDir.value
    return 0
  })
  return rows.slice(0, 500)
})

function sortValue(row, key) {
  if (key === 'x') return row.position?.x ?? 0
  if (key === 'y') return row.position?.y ?? 0
  if (key === 'z') return row.position?.z ?? 0
  return row[key] ?? ''
}

function toggleSort(key) {
  if (sortKey.value === key) sortDir.value *= -1
  else { sortKey.value = key; sortDir.value = 1 }
}

function fmt(n) {
  if (n == null || !Number.isFinite(n)) return '—'
  return Number(n).toFixed(3)
}

function onRegionChange() {
  const r = regions.value.find(r => r.id === activeRegionId.value)
  if (r) drawMap()
}

let panX = 0, panZ = 0, zoom = 1
let dragging = false, dragStart = null, lastPan = null

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
  const mx = Math.max(50, (maxX - minX) * 0.05)
  const mz = Math.max(50, (maxZ - minZ) * 0.05)
  return { minX: minX - mx, maxX: maxX + mx, minZ: minZ - mz, maxZ: maxZ + mz }
}

let world = { minX: -2000, maxX: 2000, minZ: -2000, maxZ: 2000 }

function worldToScreen(x, z) {
  const canvas = canvasEl.value
  if (!canvas) return { px: 0, py: 0 }
  const pad = 36
  const w = canvas.width - pad * 2, h = canvas.height - pad * 2
  const spanX = Math.max(1e-6, world.maxX - world.minX)
  const spanZ = Math.max(1e-6, world.maxZ - world.minZ)
  return {
    px: pad + (1 - (x - world.minX) / spanX) * w * zoom + panX,
    py: pad + (1 - (z - world.minZ) / spanZ) * h * zoom + panZ,
  }
}

function drawMap() {
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

  for (const r of regions.value) {
    const active = r.id === activeRegionId.value
    const c1 = worldToScreen(r.x_min, r.z_min)
    const c2 = worldToScreen(r.x_max, r.z_max)
    ctx.strokeStyle = active ? '#6ad46a' : '#4a7aaa'
    ctx.lineWidth = active ? 2.5 : 1.5
    if (!active) ctx.setLineDash([6, 4])
    ctx.strokeRect(Math.min(c1.px, c2.px), Math.min(c1.py, c2.py), Math.abs(c2.px - c1.px), Math.abs(c2.py - c1.py))
    ctx.setLineDash([])
  }

  const pts = tableRows.value.slice(0, 8000)
  for (const p of pts) {
    const pos = p.position || {}
    const { px, py } = worldToScreen(pos.x ?? 0, pos.z ?? 0)
    ctx.fillStyle = '#4a9fe8'
    ctx.beginPath()
    ctx.arc(px, py, 1.4, 0, Math.PI * 2)
    ctx.fill()
  }

  ctx.fillStyle = '#888'
  ctx.font = '11px system-ui'
  ctx.fillText(`map points: ${pts.length}`, 8, 16)
}

function onMouseDown(e) { dragging = true; dragStart = { x: e.clientX, y: e.clientY }; lastPan = { panX, panZ } }
function onMouseMove(e) {
  if (!dragging || !dragStart || !lastPan) return
  panX = lastPan.panX + (e.clientX - dragStart.x)
  panZ = lastPan.panZ + (e.clientY - dragStart.y)
  drawMap()
}
function onMouseUp() { dragging = false }
function onWheel(e) {
  e.preventDefault()
  zoom = Math.min(50, Math.max(0.15, zoom * (e.deltaY > 0 ? 0.92 : 1.08)))
  drawMap()
}

function resizeCanvas() {
  const canvas = canvasEl.value
  if (!canvas) return
  const wrap = canvas.parentElement
  if (!wrap) return
  const r = wrap.getBoundingClientRect()
  canvas.width = Math.max(320, Math.floor(r.width))
  canvas.height = 280
  drawMap()
}

async function loadCatalog() {
  try {
    const res = await fetch('/api/placements-catalog.json')
    if (!res.ok) return
    const data = await res.json()
    datasets.value = data.datasets || []
    const defaultId = data.defaultId || 'pmc_base'
    selectedDataset.value = datasets.value.some(d => d.id === defaultId) ? defaultId : datasets.value[0]?.id
  } catch { /* ignore */ }
}

async function reloadDataset() {
  const id = selectedDataset.value
  try {
    const res = await fetch(`/api/placements-dataset.json?id=${encodeURIComponent(id)}`)
    if (!res.ok) return
    const data = await res.json()
    const p = Array.isArray(data) ? data : data.placements || []
    allPlacements.value = p
    store.setPlacements(p, { datasetId: id, path: data.path })
    datasetMeta.value = `${data.path || id} · ${p.length} records`
    world = computeWorldBounds(p)
    drawMap()
  } catch (e) {
    datasetMeta.value = `Load failed: ${e.message}`
  }
}

watch([nameFilterText, sourceFilterText, showLs, showVz], () => drawMap())

onMounted(async () => {
  const canvas = canvasEl.value
  if (canvas) {
    canvas.addEventListener('mousedown', onMouseDown)
    canvas.addEventListener('wheel', onWheel, { passive: false })
  }
  window.addEventListener('mousemove', onMouseMove)
  window.addEventListener('mouseup', onMouseUp)
  window.addEventListener('resize', resizeCanvas)

  if (!store.getRegions().length) {
    try {
      const res = await fetch('/api/pmc-base-preset.json')
      if (res.ok) {
        const preset = await res.json()
        if (preset?.bbox) {
          const b = preset.bbox
          store.addRegion(createRegion('PMC HQ (preset)', {
            x_min: b.x_min, x_max: b.x_max,
            z_min: b.z_min, z_max: b.z_max,
            y_min: b.y_min, y_max: b.y_max,
            y_band: true,
          }))
        }
      }
    } catch { /* ignore */ }
  }
  if (store.getRegions().length) activeRegionId.value = store.getRegions()[0].id

  await loadCatalog()
  resizeCanvas()
  await reloadDataset()
})

onBeforeUnmount(() => {
  const canvas = canvasEl.value
  if (canvas) {
    canvas.removeEventListener('mousedown', onMouseDown)
    canvas.removeEventListener('wheel', onWheel)
  }
  window.removeEventListener('mousemove', onMouseMove)
  window.removeEventListener('mouseup', onMouseUp)
  window.removeEventListener('resize', resizeCanvas)
})
</script>
