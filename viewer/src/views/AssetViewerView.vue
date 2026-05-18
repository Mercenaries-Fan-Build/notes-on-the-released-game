<template>
  <div class="flex h-full">
    <!-- Sidebar -->
    <aside class="flex w-[300px] min-w-[220px] max-w-[42vw] flex-shrink-0 flex-col border-r border-gray-800 bg-gray-900 overflow-auto">
      <div class="p-3">
        <h1 class="mb-3 text-sm font-semibold text-gray-100">Asset Viewer</h1>

        <!-- Extracted assets -->
        <h2 class="mb-2 mt-3 text-[11px] font-semibold uppercase tracking-wide text-gray-400">Extracted assets</h2>
        <label class="mb-1 block text-xs text-gray-400">Pack</label>
        <select
          v-model="packFilter"
          class="mb-2 w-full rounded border border-gray-700 bg-gray-800 px-2 py-1.5 text-xs text-gray-200"
        >
          <option value="all">All packs</option>
          <option v-for="p in store.packs" :key="p" :value="p">{{ p }}</option>
        </select>
        <label class="mb-1 block text-xs text-gray-400">Filter</label>
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Name / path substring…"
          class="mb-2 w-full rounded border border-gray-700 bg-gray-800 px-2 py-1.5 text-xs text-gray-200"
        />
        <ul class="max-h-[38vh] overflow-auto text-[11px]">
          <li
            v-for="a in displayedAssets"
            :key="a.key"
            class="cursor-pointer rounded px-1.5 py-1 leading-snug break-all"
            :class="[
              selectedAsset?.key === a.key ? 'bg-blue-900/60' : 'hover:bg-gray-800',
              a.manifest ? 'text-blue-300' : 'text-gray-300'
            ]"
            :title="a.key"
            @click="selectAsset(a)"
          >
            {{ a.label || a.key }}
            <span v-if="a.manifest" class="text-gray-500"> [submeshes]</span>
          </li>
        </ul>

        <!-- Status -->
        <div ref="statusEl" class="mt-2 text-[11px] leading-relaxed text-gray-400" v-html="statusHtml" />
      </div>
    </aside>

    <!-- 3D Viewport -->
    <div ref="viewportEl" class="relative flex-1 min-w-0 min-h-0 overflow-hidden">
      <div class="pointer-events-none absolute bottom-2.5 left-2.5 text-[11px] text-gray-500/60">
        Orbit: drag &bull; Zoom: wheel
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount, watch, nextTick } from 'vue'
import { useReviewAssetsStore } from '../stores/reviewAssets.js'
import { initThreeViewer, disposeThreeViewer } from '../lib/three-viewer.js'

const store = useReviewAssetsStore()

const viewportEl = ref(null)
const statusEl = ref(null)
const packFilter = ref('all')
const searchQuery = ref('')
const selectedAsset = ref(null)
const statusHtml = ref('')

let viewer = null

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

function selectAsset(a) {
  selectedAsset.value = a
  if (viewer) viewer.loadAsset(a)
}

onMounted(async () => {
  await store.fetchAssets()

  const rootStr = store.roots.join(', ')
  const pcStr = Object.entries(store.packCounts)
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([p, n]) => `${p}: ${n}`)
    .join(' &middot; ')
  const hintsHtml = store.pipelineHints
    .map(h => `<br/><span class="text-yellow-400">${h.message || ''}</span>`)
    .join('')
  statusHtml.value = `Loaded <strong>${store.totalAssets}</strong> extracted mesh(es).${pcStr ? `<br/><span class="opacity-90 text-[10px]">${pcStr}</span>` : ''}${hintsHtml}${rootStr ? `<br/><span class="opacity-75 text-[10px]">Roots: ${rootStr}</span>` : ''}`

  await nextTick()
  viewer = initThreeViewer(viewportEl.value, (msg) => {
    statusHtml.value = msg
  })

  const params = new URLSearchParams(window.location.search)
  const manifestPath = params.get('manifest')
  const objPath = params.get('obj')
  const gltfPath = params.get('gltf')
  if (manifestPath) viewer.loadManifest(manifestPath)
  else if (objPath || gltfPath) viewer.loadUrls(objPath, gltfPath, params.get('tex') || params.get('dds'))
})

onBeforeUnmount(() => {
  if (viewer) {
    disposeThreeViewer(viewer)
    viewer = null
  }
})
</script>
