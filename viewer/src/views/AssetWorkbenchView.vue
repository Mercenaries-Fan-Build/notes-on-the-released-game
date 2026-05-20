<template>
  <div class="flex h-full">
    <!-- Left sidebar: asset browser -->
    <aside
      class="flex flex-col border-r border-gray-800 bg-gray-900 overflow-hidden"
      :style="{ width: leftWidth + 'px', minWidth: '180px', maxWidth: '50vw' }"
    >
      <div class="shrink-0 p-3 pb-1">
        <h2 class="mb-2 text-[11px] font-semibold uppercase tracking-wide text-gray-400">Assets</h2>
        <label class="mb-1 block text-[11px] text-gray-500">Pack</label>
        <select
          v-model="packFilter"
          class="mb-2 w-full rounded border border-gray-700 bg-gray-800 px-2 py-1.5 text-xs text-gray-200"
        >
          <option value="all">All packs</option>
          <option v-for="p in store.packs" :key="p" :value="p">{{ p }}</option>
        </select>
        <label class="mb-1 block text-[11px] text-gray-500">Filter</label>
        <input
          ref="searchInputEl"
          v-model="searchQuery"
          type="text"
          placeholder="Name / path substring..."
          class="mb-2 w-full rounded border border-gray-700 bg-gray-800 px-2 py-1.5 text-xs text-gray-200"
        />
        <div class="text-[10px] text-gray-500">{{ displayedAssets.length }} results</div>
      </div>
      <ul ref="assetListEl" class="min-h-0 flex-1 overflow-auto px-2 pb-2 text-[11px]">
        <li
          v-for="(a, i) in displayedAssets"
          :key="a.key"
          :ref="el => { if (selectedAssetIndex === i) selectedAssetRow = el }"
          class="cursor-pointer rounded px-1.5 py-1 leading-snug break-all"
          :class="[
            selectedAsset?.key === a.key ? 'bg-blue-900/60' : 'hover:bg-gray-800',
            a.manifest ? 'text-blue-300' : 'text-gray-300'
          ]"
          :title="a.key"
          @click="selectAsset(a, i, $event.shiftKey)"
        >
          {{ a.label || a.key }}
          <span v-if="a.manifest" class="text-[10px] text-gray-500">(submeshes)</span>
        </li>
      </ul>
      <!-- Resize handle -->
      <div
        class="absolute right-0 top-0 z-20 h-full w-1 cursor-col-resize hover:bg-blue-500/30"
        :style="{ left: leftWidth - 2 + 'px' }"
        @mousedown="startLeftResize"
      />
    </aside>

    <!-- Center: 3D viewport -->
    <div class="relative min-h-0 min-w-0 flex-1 overflow-hidden bg-gray-950">
      <div ref="viewportEl" class="h-full w-full" />
      <ViewportToolbar
        :current-display="displayMode"
        :current-transform="transformMode"
        @display-mode="onDisplayMode"
        @transform-mode="onTransformMode"
        @reset-camera="onResetCamera"
      />
      <StatusBar
        class="absolute inset-x-0 bottom-0"
        :model-size="modelSize"
        :total-verts="totalVerts"
        :total-faces="totalFaces"
        :selected-info="selectedInfo"
      />
      <div class="pointer-events-none absolute bottom-8 left-2.5 text-[10px] text-gray-600/50">
        Orbit: drag &middot; Zoom: wheel &middot; T/R/S: transform &middot; W: wireframe &middot; F: focus
      </div>
    </div>

    <!-- Right sidebar: inspector -->
    <aside
      class="relative flex flex-col border-l border-gray-800 bg-gray-900 overflow-hidden"
      :style="{ width: rightWidth + 'px', minWidth: '200px', maxWidth: '50vw' }"
    >
      <div
        class="absolute left-0 top-0 z-20 h-full w-1 cursor-col-resize hover:bg-blue-500/30"
        @mousedown="startRightResize"
      />
      <InspectorTabs
        :part-meta="partMeta"
        :part-groups="partGroups"
        :selected-index="selectedPartIndex"
        :visibility="partVisibility"
        :asset="selectedAsset"
        :viewer="viewerRef"
        @select-part="onSelectPart"
        @toggle-visible="onToggleVisible"
      />
    </aside>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onBeforeUnmount, watch, nextTick, shallowRef } from 'vue'
import { useReviewAssetsStore } from '../stores/reviewAssets.js'
import { useWorkbenchStore } from '../stores/workbenchState.js'
import { initThreeViewer, disposeThreeViewer } from '../lib/three-viewer.js'
import { classifyPart } from '../lib/submesh-inspect.js'
import ViewportToolbar from '../components/workbench/ViewportToolbar.vue'
import StatusBar from '../components/workbench/StatusBar.vue'
import InspectorTabs from '../components/workbench/InspectorTabs.vue'

const store = useReviewAssetsStore()
const wb = useWorkbenchStore()

const viewportEl = ref(null)
const searchInputEl = ref(null)
const assetListEl = ref(null)
const selectedAssetRow = ref(null)

const packFilter = ref('all')
const searchQuery = ref('')
const selectedAsset = ref(null)
const selectedAssetIndex = ref(-1)

const leftWidth = ref(300)
const rightWidth = ref(350)

const displayMode = ref('shaded')
const transformMode = ref('translate')

const partMeta = shallowRef([])
const partGroups = shallowRef([])
const selectedPartIndex = ref(-1)
const partVisibility = reactive({})

const modelSize = ref(null)
const totalVerts = ref(null)
const totalFaces = ref(null)

let viewer = null
const viewerRef = shallowRef(null)

const filteredAssets = computed(() =>
  store.filteredAssets(packFilter.value, searchQuery.value)
)

const displayedAssets = computed(() => {
  const list = filteredAssets.value
  if (packFilter.value === 'all' && !searchQuery.value) {
    return store.interleaveByPack(list)
  }
  return list
})

const selectedInfo = computed(() => {
  if (selectedPartIndex.value < 0 || !partMeta.value.length) return ''
  const idx = selectedPartIndex.value
  const meta = partMeta.value[idx]
  if (!meta) return ''
  const cat = classifyPart(meta)
  const group = partGroups.value[idx]
  let verts = 0
  group?.traverse?.(c => {
    if (c.isMesh && c.geometry) {
      const pos = c.geometry.getAttribute('position')
      if (pos) verts += pos.count
    }
  })
  return `Part #${idx} - ${cat} - ${verts.toLocaleString()} verts`
})

function selectAsset(a, idx, additive = false) {
  selectedAsset.value = a
  selectedAssetIndex.value = idx
  selectedPartIndex.value = -1

  if (!viewer) return

  if (additive) {
    viewer.loadAssetAdditive(a).then((modelIndex) => {
      wb.addModel({ key: a.key, stem: a.stem || a.key, pack: a.pack || '' })
      syncPartsFromViewer()
    })
    return
  }

  partMeta.value = []
  partGroups.value = []
  Object.keys(partVisibility).forEach(k => delete partVisibility[k])
  wb.clearHistory()
  wb.loadedModels = []
  viewer.loadAsset(a)
  wb.addModel({ key: a.key, stem: a.stem || a.key, pack: a.pack || '' })
}

function syncPartsFromViewer() {
  if (!viewer) return
  const groups = viewer.getPartGroups?.() ?? []
  const meta = viewer.getPartMeta?.() ?? []
  partGroups.value = groups
  partMeta.value = meta
  Object.keys(partVisibility).forEach(k => delete partVisibility[k])
  for (let i = 0; i < groups.length; i++) {
    partVisibility[i] = viewer.getPartVisible?.(i) ?? true
  }
  computeModelStats()
}

function computeModelStats() {
  let verts = 0
  let faces = 0
  for (const g of partGroups.value) {
    g?.traverse?.(c => {
      if (c.isMesh && c.geometry) {
        const pos = c.geometry.getAttribute('position')
        if (pos) verts += pos.count
        const idx = c.geometry.index
        faces += idx ? idx.count / 3 : (pos ? pos.count / 3 : 0)
      }
    })
  }
  totalVerts.value = verts
  totalFaces.value = faces
}

function onSelectPart(idx) {
  selectedPartIndex.value = idx
  viewer?.selectPart?.(idx)
}

function onToggleVisible(idx, visible) {
  partVisibility[idx] = visible
  viewer?.setPartVisible?.(idx, visible)
}

function onDisplayMode(mode) {
  displayMode.value = mode
  viewer?.setDisplayMode?.(mode)
}

function onTransformMode(mode) {
  transformMode.value = mode
  viewer?.setTransformMode?.(mode)
}

function onResetCamera() {
  viewer?.resetCamera?.()
}

// --- Resize handles ---

function startLeftResize(e) {
  e.preventDefault()
  const startX = e.clientX
  const startW = leftWidth.value
  function onMove(ev) {
    leftWidth.value = Math.max(180, Math.min(window.innerWidth * 0.5, startW + (ev.clientX - startX)))
  }
  function onUp() {
    window.removeEventListener('mousemove', onMove)
    window.removeEventListener('mouseup', onUp)
  }
  window.addEventListener('mousemove', onMove)
  window.addEventListener('mouseup', onUp)
}

function startRightResize(e) {
  e.preventDefault()
  const startX = e.clientX
  const startW = rightWidth.value
  function onMove(ev) {
    rightWidth.value = Math.max(200, Math.min(window.innerWidth * 0.5, startW - (ev.clientX - startX)))
  }
  function onUp() {
    window.removeEventListener('mousemove', onMove)
    window.removeEventListener('mouseup', onUp)
  }
  window.addEventListener('mousemove', onMove)
  window.addEventListener('mouseup', onUp)
}

// --- Keyboard shortcuts ---

function isInputFocused() {
  const tag = document.activeElement?.tagName
  return tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT'
}

function onKeyDown(e) {
  if (isInputFocused()) return

  if ((e.ctrlKey || e.metaKey) && e.key === 'z' && !e.shiftKey) {
    e.preventDefault()
    wb.undo()
    return
  }
  if ((e.ctrlKey || e.metaKey) && e.key === 'z' && e.shiftKey) {
    e.preventDefault()
    wb.redo()
    return
  }
  if ((e.ctrlKey || e.metaKey) && e.key === 'Z') {
    e.preventDefault()
    wb.redo()
    return
  }
  if (e.key === 'Delete' || e.key === 'Backspace') {
    if (selectedPartIndex.value >= 0) {
      const idx = selectedPartIndex.value
      const wasVisible = viewer?.getPartVisible?.(idx) ?? true
      wb.execute({
        type: 'visibility',
        description: `Hide part #${idx}`,
        data: { modelIndex: wb.selectedModelIndex, partIndex: idx, prevVisible: wasVisible, newVisible: false },
        exec() { onToggleVisible(idx, false) },
        undo() { onToggleVisible(idx, true) },
      })
    }
    return
  }

  switch (e.key) {
    case 't':
    case 'T':
      onTransformMode('translate')
      break
    case 'r':
      onTransformMode('rotate')
      break
    case 's':
      onTransformMode('scale')
      break
    case 'w':
    case 'W':
      displayMode.value = displayMode.value === 'wireframe' ? 'shaded' : 'wireframe'
      viewer?.setDisplayMode?.(displayMode.value)
      break
    case 'n':
    case 'N':
      displayMode.value = displayMode.value === 'normals' ? 'shaded' : 'normals'
      viewer?.setDisplayMode?.(displayMode.value)
      break
    case 'h':
      if (e.shiftKey) {
        viewer?.setAllPartsVisible?.(true)
        for (const k of Object.keys(partVisibility)) partVisibility[k] = true
      } else if (selectedPartIndex.value >= 0) {
        onToggleVisible(selectedPartIndex.value, false)
      }
      break
    case 'H':
      viewer?.setAllPartsVisible?.(true)
      for (const k of Object.keys(partVisibility)) partVisibility[k] = true
      break
    case 'f':
    case 'F':
      if (selectedPartIndex.value >= 0) viewer?.focusOnPart?.(selectedPartIndex.value)
      break
    case 'ArrowDown': {
      e.preventDefault()
      const list = displayedAssets.value
      if (!list.length) break
      const next = Math.min((selectedAssetIndex.value ?? -1) + 1, list.length - 1)
      selectAsset(list[next], next)
      break
    }
    case 'ArrowUp': {
      e.preventDefault()
      const list = displayedAssets.value
      if (!list.length) break
      const prev = Math.max((selectedAssetIndex.value ?? 0) - 1, 0)
      selectAsset(list[prev], prev)
      break
    }
  }
}

onMounted(async () => {
  await store.fetchAssets()

  await nextTick()
  viewer = initThreeViewer(viewportEl.value, (msg) => {
    /* status callback - could parse model size from msg if needed */
  })
  viewerRef.value = viewer

  viewer?.onPartsLoaded?.(() => {
    syncPartsFromViewer()
  })

  viewer?.onSelectionChange?.((idx) => {
    selectedPartIndex.value = idx
    wb.selectedPartIndex = idx
  })

  let _transformStart = null
  viewer?.onSelectionChange?.((idx) => {
    if (idx >= 0) {
      const groups = viewer.getPartGroups?.() ?? []
      const obj = groups[idx]
      if (obj) {
        _transformStart = {
          pos: { x: obj.position.x, y: obj.position.y, z: obj.position.z },
          rot: { x: obj.rotation.x, y: obj.rotation.y, z: obj.rotation.z },
          scale: { x: obj.scale.x, y: obj.scale.y, z: obj.scale.z },
        }
      }
    }
  })

  viewer?.onTransformChange?.((info) => {
    if (!_transformStart) return
    const prevPos = { ..._transformStart.pos }
    const prevRot = { ..._transformStart.rot }
    const prevScale = { ..._transformStart.scale }
    const newPos = { ...info.position }
    const newRot = { ...info.rotation }
    const newScale = { ...info.scale }
    const partIdx = info.index

    _transformStart = { pos: newPos, rot: newRot, scale: newScale }

    wb.execute({
      type: 'transform',
      description: `Transform part #${partIdx}`,
      data: {
        modelIndex: wb.selectedModelIndex,
        partIndex: partIdx,
        prevPos, prevRot, prevScale,
        newPos, newRot, newScale,
      },
      exec() {
        const groups = viewer?.getPartGroups?.() ?? []
        const obj = groups[partIdx]
        if (!obj) return
        obj.position.set(newPos.x, newPos.y, newPos.z)
        obj.rotation.set(newRot.x, newRot.y, newRot.z)
        obj.scale.set(newScale.x, newScale.y, newScale.z)
      },
      undo() {
        const groups = viewer?.getPartGroups?.() ?? []
        const obj = groups[partIdx]
        if (!obj) return
        obj.position.set(prevPos.x, prevPos.y, prevPos.z)
        obj.rotation.set(prevRot.x, prevRot.y, prevRot.z)
        obj.scale.set(prevScale.x, prevScale.y, prevScale.z)
      },
    })
  })

  const params = new URLSearchParams(window.location.search)
  const manifestPath = params.get('manifest')
  const objPath = params.get('obj')
  const gltfPath = params.get('gltf')
  if (manifestPath) viewer.loadManifest(manifestPath)
  else if (objPath || gltfPath) viewer.loadUrls(objPath, gltfPath, params.get('tex') || params.get('dds'))

  window.addEventListener('keydown', onKeyDown)
})

onBeforeUnmount(() => {
  window.removeEventListener('keydown', onKeyDown)
  if (viewer) {
    disposeThreeViewer(viewer)
    viewer = null
    viewerRef.value = null
  }
})
</script>
