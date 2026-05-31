<template>
  <div class="flex h-full flex-col bg-gray-950">
    <div class="flex flex-wrap items-end gap-3 border-b border-gray-800 bg-gray-900 px-4 py-3">
      <div>
        <h1 class="text-sm font-semibold text-gray-100">World Cells (3D)</h1>
        <p class="text-[10px] text-gray-500">
          Game Y-up preview — GLBs at c3 grid origins (same coords as UE <code class="text-gray-400">game_to_ue</code> without cm scale)
        </p>
      </div>
      <label class="text-[11px] text-gray-400">
        Region
        <select
          v-model="regionKey"
          class="ml-1 rounded border border-gray-700 bg-gray-800 px-2 py-1 text-xs text-gray-200"
          @change="onRegionChange"
        >
          <option v-for="(r, k) in regionPresets" :key="k" :value="k">{{ r.label }}</option>
        </select>
      </label>
      <label class="text-[11px] text-gray-400">
        Limit
        <input
          v-model.number="limit"
          type="number"
          min="1"
          max="500"
          class="ml-1 w-16 rounded border border-gray-700 bg-gray-800 px-2 py-1 text-xs text-gray-200"
        />
      </label>
      <label class="text-[11px] text-gray-400">
        Cell ID
        <input
          v-model="cellIdQuery"
          type="text"
          placeholder="30641"
          class="ml-1 w-20 rounded border border-gray-700 bg-gray-800 px-2 py-1 text-xs text-gray-200"
        />
      </label>
      <button
        type="button"
        class="rounded bg-indigo-700 px-3 py-1.5 text-xs font-medium text-white hover:bg-indigo-600 disabled:opacity-40"
        :disabled="loading"
        @click="loadCells"
      >
        {{ loading ? 'Loading…' : 'Load cells' }}
      </button>
      <button
        type="button"
        class="rounded border border-gray-700 px-3 py-1.5 text-xs text-gray-300 hover:bg-gray-800"
        @click="clearScene"
      >
        Clear
      </button>
      <label class="flex items-center gap-1 text-[11px] text-gray-400">
        <input v-model="showGrid" type="checkbox" class="rounded" @change="toggleGrid" />
        Grid
      </label>
      <label class="flex items-center gap-1 text-[11px] text-gray-400">
        <input v-model="wireframe" type="checkbox" class="rounded" @change="applyWireframe" />
        Wireframe
      </label>
    </div>

    <div class="relative min-h-0 flex-1">
      <div ref="viewportEl" class="h-full w-full" />
      <div class="pointer-events-none absolute left-3 top-3 max-w-md rounded bg-gray-950/85 px-3 py-2 text-[11px] text-gray-300 shadow-lg ring-1 ring-gray-800">
        <div>{{ statusLine }}</div>
        <div v-if="selectedCell" class="mt-1 text-indigo-300">
          Selected c{{ selectedCell.cell_id }} — {{ selectedCell.stem.slice(0, 48) }}…
        </div>
        <div v-if="loadErrors.length" class="mt-1 text-amber-400">
          {{ loadErrors.length }} load error(s)
        </div>
      </div>
      <div class="pointer-events-none absolute bottom-3 left-3 text-[10px] text-gray-600">
        Orbit: drag · Zoom: wheel · Click cell to select · Game metres, Y-up
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, onUnmounted, ref, shallowRef } from 'vue'
import * as THREE from 'three'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js'

const viewportEl = ref(null)
const regionPresets = ref({ maracaibo: {}, full: {} })
const regionKey = ref('maracaibo')
const limit = ref(80)
const cellIdQuery = ref('')
const loading = ref(false)
const statusLine = ref('Click Load cells')
const selectedCell = shallowRef(null)
const loadErrors = ref([])
const showGrid = ref(true)
const wireframe = ref(false)

let renderer
let scene
let camera
let controls
let worldGrid
let cellsRoot
let animId
let resizeObs

const loadedMeshes = []

function toggleGrid() {
  if (worldGrid) worldGrid.visible = showGrid.value
}

function applyWireframe() {
  for (const obj of loadedMeshes) {
    obj.traverse((child) => {
      if (child.isMesh && child.material) {
        const mats = Array.isArray(child.material) ? child.material : [child.material]
        for (const m of mats) {
          m.wireframe = wireframe.value
        }
      }
    })
  }
}

function clearScene() {
  if (!cellsRoot) return
  while (cellsRoot.children.length) {
    const ch = cellsRoot.children[0]
    cellsRoot.remove(ch)
    ch.traverse((obj) => {
      if (obj.geometry) obj.geometry.dispose()
      if (obj.material) {
        const mats = Array.isArray(obj.material) ? obj.material : [obj.material]
        for (const m of mats) mats.forEach((mat) => mat.dispose?.())
      }
    })
  }
  loadedMeshes.length = 0
  loadErrors.value = []
  selectedCell.value = null
  statusLine.value = 'Cleared'
}

function focusRegion(preset) {
  if (!preset || !camera || !controls) return
  const cx = (preset.minX + preset.maxX) / 2
  const cz = (preset.minZ + preset.maxZ) / 2
  const span = Math.max(preset.maxX - preset.minX, preset.maxZ - preset.minZ)
  camera.position.set(cx + span * 0.35, span * 0.55, cz + span * 0.35)
  controls.target.set(cx, 0, cz)
  controls.update()
}

function onRegionChange() {
  const preset = regionPresets.value[regionKey.value]
  if (preset) focusRegion(preset)
}

function buildQuery() {
  const params = new URLSearchParams()
  params.set('limit', String(limit.value))
  const cid = parseInt(cellIdQuery.value.trim(), 10)
  if (Number.isFinite(cid) && cid > 0) {
    params.set('cell_id', String(cid))
    return params
  }
  const preset = regionPresets.value[regionKey.value]
  if (preset) {
    params.set('min_x', String(preset.minX))
    params.set('max_x', String(preset.maxX))
    params.set('min_z', String(preset.minZ))
    params.set('max_z', String(preset.maxZ))
  }
  return params
}

async function loadCells() {
  loading.value = true
  loadErrors.value = []
  clearScene()
  try {
    const res = await fetch(`/api/world-cells.json?${buildQuery()}`)
    const data = await res.json()
    if (!res.ok) throw new Error(data.error || res.statusText)

    const cells = data.cells || []
    statusLine.value = `Loading 0 / ${cells.length} (matched ${data.total_matching})`

    const loader = new GLTFLoader()
    let done = 0
    let ok = 0

    await Promise.all(
      cells.map(
        (cell) =>
          new Promise((resolve) => {
            loader.load(
              cell.meshUrl,
              (gltf) => {
                const root = gltf.scene
                root.position.set(cell.position.x, cell.position.y, cell.position.z)
                root.userData = { cell }
                root.traverse((child) => {
                  if (child.isMesh) {
                    child.castShadow = false
                    child.receiveShadow = false
                  }
                })
                cellsRoot.add(root)
                loadedMeshes.push(root)
                ok += 1
                done += 1
                statusLine.value = `Loaded ${ok} / ${cells.length} (${done} finished)`
                resolve()
              },
              undefined,
              (err) => {
                loadErrors.value.push({ cell_id: cell.cell_id, err: String(err?.message || err) })
                done += 1
                statusLine.value = `Loaded ${ok} / ${cells.length} (${loadErrors.value.length} errors)`
                resolve()
              },
            )
          }),
      ),
    )

    statusLine.value = `Done: ${ok} cells, ${loadErrors.value.length} errors (${data.total_matching} matched region)`
    if (cells.length === 1) {
      selectedCell.value = cells[0]
      const p = cells[0].position
      controls.target.set(p.x, p.y, p.z)
      camera.position.set(p.x + 200, p.y + 150, p.z + 200)
      controls.update()
    }
  } catch (e) {
    statusLine.value = `Error: ${e.message}`
  } finally {
    loading.value = false
    applyWireframe()
  }
}

function onPointerDown(event) {
  if (!renderer || !camera || !cellsRoot) return
  const rect = renderer.domElement.getBoundingClientRect()
  const mouse = new THREE.Vector2(
    ((event.clientX - rect.left) / rect.width) * 2 - 1,
    -((event.clientY - rect.top) / rect.height) * 2 + 1,
  )
  const raycaster = new THREE.Raycaster()
  raycaster.setFromCamera(mouse, camera)
  const hits = raycaster.intersectObjects(cellsRoot.children, true)
  if (!hits.length) {
    selectedCell.value = null
    return
  }
  let obj = hits[0].object
  while (obj.parent && obj.parent !== cellsRoot) obj = obj.parent
  selectedCell.value = obj.userData?.cell || null
}

function initThree() {
  const container = viewportEl.value
  scene = new THREE.Scene()
  scene.background = new THREE.Color(0x12141a)

  camera = new THREE.PerspectiveCamera(55, 1, 1, 500000)
  camera.position.set(2000, 1200, -800)

  renderer = new THREE.WebGLRenderer({ antialias: true })
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))
  renderer.outputColorSpace = THREE.SRGBColorSpace
  container.appendChild(renderer.domElement)

  controls = new OrbitControls(camera, renderer.domElement)
  controls.enableDamping = true
  controls.target.set(2000, 0, -800)

  scene.add(new THREE.HemisphereLight(0xcde0ff, 0x3a3630, 1.8))
  const sun = new THREE.DirectionalLight(0xffffff, 1.6)
  sun.position.set(3000, 5000, -2000)
  scene.add(sun)

  const worldW = 7750
  const worldD = 7750
  worldGrid = new THREE.GridHelper(worldW, 100, 0x3a4555, 0x252a33)
  worldGrid.position.set(-25, 0, -25)
  scene.add(worldGrid)

  cellsRoot = new THREE.Group()
  cellsRoot.name = 'world_cells'
  scene.add(cellsRoot)

  renderer.domElement.addEventListener('pointerdown', onPointerDown)

  const tick = () => {
    animId = requestAnimationFrame(tick)
    controls.update()
    renderer.render(scene, camera)
  }
  tick()

  resizeObs = new ResizeObserver(() => {
    const w = container.clientWidth
    const h = container.clientHeight
    if (w < 1 || h < 1) return
    camera.aspect = w / h
    camera.updateProjectionMatrix()
    renderer.setSize(w, h, false)
  })
  resizeObs.observe(container)
}

onMounted(async () => {
  initThree()
  try {
    const res = await fetch('/api/world-cells.json?limit=1')
    const data = await res.json()
    regionPresets.value = data.regionPresets || regionPresets.value
    focusRegion(regionPresets.value[regionKey.value])
  } catch {
    /* presets optional */
  }
})

onUnmounted(() => {
  cancelAnimationFrame(animId)
  resizeObs?.disconnect()
  renderer?.domElement?.removeEventListener('pointerdown', onPointerDown)
  renderer?.dispose()
})
</script>
