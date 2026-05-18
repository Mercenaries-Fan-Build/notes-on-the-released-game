<template>
  <div class="flex h-full flex-col">
    <!-- Toolbar -->
    <div class="flex flex-wrap items-center gap-3 border-b border-gray-800 bg-gray-900 px-4 py-2">
      <h1 class="text-sm font-semibold text-gray-100">Block Browser</h1>

      <!-- Pack filter -->
      <select
        v-model="packFilter"
        class="rounded border border-gray-700 bg-gray-800 px-2 py-1 text-xs text-gray-200"
      >
        <option value="all">All packs ({{ store.totalAssets }})</option>
        <option v-for="p in store.packs" :key="p" :value="p">
          {{ p }} ({{ store.packCounts[p] || 0 }})
        </option>
      </select>

      <!-- Category filter -->
      <select
        v-model="categoryFilter"
        class="rounded border border-gray-700 bg-gray-800 px-2 py-1 text-xs text-gray-200"
      >
        <option value="all">All categories</option>
        <option v-for="cat in availableCategories" :key="cat" :value="cat">{{ cat }}</option>
      </select>

      <!-- Content filter -->
      <select
        v-model="contentFilter"
        class="rounded border border-gray-700 bg-gray-800 px-2 py-1 text-xs text-gray-200"
      >
        <option value="all">All content</option>
        <option value="has_mesh">Has mesh</option>
        <option value="has_textures">Has textures</option>
        <option value="has_submeshes">Has submeshes</option>
      </select>

      <!-- Search -->
      <div class="relative flex-1 min-w-[200px]">
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Search by name, path, texture…"
          class="w-full rounded border border-gray-700 bg-gray-800 px-3 py-1.5 pr-8 text-xs text-gray-200 placeholder-gray-500"
        />
        <button
          v-if="searchQuery"
          class="absolute right-2 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-300"
          @click="searchQuery = ''"
        >
          &times;
        </button>
      </div>

      <!-- View toggle -->
      <div class="flex rounded border border-gray-700">
        <button
          class="px-2.5 py-1 text-xs"
          :class="viewMode === 'table' ? 'bg-gray-700 text-white' : 'text-gray-400 hover:text-gray-200'"
          @click="viewMode = 'table'"
        >
          Table
        </button>
        <button
          class="px-2.5 py-1 text-xs"
          :class="viewMode === 'grid' ? 'bg-gray-700 text-white' : 'text-gray-400 hover:text-gray-200'"
          @click="viewMode = 'grid'"
        >
          Grid
        </button>
      </div>

      <span class="text-[10px] text-gray-500">
        {{ displayedAssets.length }} / {{ store.totalAssets }} blocks
      </span>
    </div>

    <!-- Table view -->
    <div v-if="viewMode === 'table'" class="flex-1 overflow-auto">
      <table class="w-full border-collapse text-xs">
        <thead>
          <tr>
            <th
              v-for="col in tableColumns"
              :key="col.key"
              class="sticky top-0 z-10 cursor-pointer border-b border-gray-800 bg-gray-900 px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500"
              @click="toggleSort(col.key)"
            >
              {{ col.label }}
              <span v-if="sortKey === col.key" class="ml-0.5">{{ sortDir === 1 ? '▲' : '▼' }}</span>
            </th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="a in paginatedAssets"
            :key="a.key"
            class="border-b border-gray-800/50 transition-colors hover:bg-gray-800/40"
          >
            <!-- Thumbnail -->
            <td class="w-12 px-3 py-1.5">
              <div class="flex h-8 w-8 items-center justify-center rounded bg-gray-800 text-[8px] text-gray-600">
                <span v-if="a.dds" class="text-green-500">IMG</span>
                <span v-else-if="a.manifest" class="text-blue-400">3D</span>
                <span v-else>—</span>
              </div>
            </td>
            <!-- Name -->
            <td class="max-w-[300px] truncate px-3 py-1.5">
              <router-link
                :to="{ name: 'viewer', query: assetViewerQuery(a) }"
                class="font-medium text-gray-200 hover:text-blue-300"
                :title="a.key"
              >
                {{ a.stem }}
              </router-link>
            </td>
            <!-- Pack -->
            <td class="px-3 py-1.5 text-gray-400">{{ a.pack }}</td>
            <!-- Category badge -->
            <td class="px-3 py-1.5">
              <span
                class="inline-block rounded-full px-2 py-0.5 text-[10px] font-medium"
                :class="categoryBadgeClass(classifyBlock(a.stem))"
              >
                {{ classifyBlock(a.stem) }}
              </span>
            </td>
            <!-- Content flags -->
            <td class="px-3 py-1.5">
              <div class="flex gap-1">
                <span v-if="a.manifest" class="rounded bg-blue-900/30 px-1.5 py-0.5 text-[9px] text-blue-300">mesh</span>
                <span v-if="a.textureFiles?.length" class="rounded bg-purple-900/30 px-1.5 py-0.5 text-[9px] text-purple-300">{{ a.textureFiles.length }} tex</span>
                <span v-if="a.sidecars?.havokManifestJson" class="rounded bg-amber-900/30 px-1.5 py-0.5 text-[9px] text-amber-300">havok</span>
                <span v-if="a.sidecars?.dialogFragmentsJson" class="rounded bg-rose-900/30 px-1.5 py-0.5 text-[9px] text-rose-300">dialog</span>
              </div>
            </td>
            <!-- Sidecars -->
            <td class="px-3 py-1.5 text-gray-500">
              {{ sidecarCount(a) }} json
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Pagination -->
      <div v-if="totalPages > 1" class="flex items-center justify-center gap-2 border-t border-gray-800 py-3">
        <button
          class="rounded border border-gray-700 px-3 py-1 text-xs text-gray-400 hover:bg-gray-800 disabled:opacity-30"
          :disabled="currentPage <= 1"
          @click="currentPage--"
        >
          ← Prev
        </button>
        <span class="text-xs text-gray-500">Page {{ currentPage }} / {{ totalPages }}</span>
        <button
          class="rounded border border-gray-700 px-3 py-1 text-xs text-gray-400 hover:bg-gray-800 disabled:opacity-30"
          :disabled="currentPage >= totalPages"
          @click="currentPage++"
        >
          Next →
        </button>
      </div>
    </div>

    <!-- Grid view -->
    <div v-else class="flex-1 overflow-auto p-4">
      <div class="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6">
        <router-link
          v-for="a in paginatedAssets"
          :key="a.key"
          :to="{ name: 'viewer', query: assetViewerQuery(a) }"
          class="group rounded-lg border border-gray-800 bg-gray-900 p-3 transition-colors hover:border-blue-700 hover:bg-gray-800"
        >
          <!-- Thumbnail placeholder -->
          <div class="mb-2 flex h-24 items-center justify-center rounded bg-gray-800 text-xs text-gray-600">
            <span v-if="a.dds" class="text-green-500">IMG</span>
            <span v-else-if="a.manifest" class="text-2xl text-blue-400/40">▲</span>
            <span v-else class="text-gray-700">—</span>
          </div>
          <div class="truncate text-[11px] font-medium text-gray-300 group-hover:text-blue-300" :title="a.stem">
            {{ a.stem }}
          </div>
          <div class="mt-0.5 truncate text-[10px] text-gray-500">{{ a.pack }}</div>
          <div class="mt-1.5 flex flex-wrap gap-1">
            <span
              class="rounded-full px-1.5 py-0.5 text-[9px] font-medium"
              :class="categoryBadgeClass(classifyBlock(a.stem))"
            >
              {{ classifyBlock(a.stem) }}
            </span>
          </div>
        </router-link>
      </div>

      <!-- Pagination -->
      <div v-if="totalPages > 1" class="flex items-center justify-center gap-2 py-4">
        <button
          class="rounded border border-gray-700 px-3 py-1 text-xs text-gray-400 hover:bg-gray-800 disabled:opacity-30"
          :disabled="currentPage <= 1"
          @click="currentPage--"
        >
          ← Prev
        </button>
        <span class="text-xs text-gray-500">Page {{ currentPage }} / {{ totalPages }}</span>
        <button
          class="rounded border border-gray-700 px-3 py-1 text-xs text-gray-400 hover:bg-gray-800 disabled:opacity-30"
          :disabled="currentPage >= totalPages"
          @click="currentPage++"
        >
          Next →
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useReviewAssetsStore } from '../stores/reviewAssets.js'

const store = useReviewAssetsStore()
const route = useRoute()

const packFilter = ref('all')
const categoryFilter = ref('all')
const contentFilter = ref('all')
const searchQuery = ref('')
const viewMode = ref('table')
const sortKey = ref('stem')
const sortDir = ref(1)
const currentPage = ref(1)
const pageSize = 100

function classifyBlock(stem) {
  const s = (stem || '').toLowerCase()
  if (s.includes('_bld_') || s.includes('building')) return 'building'
  if (s.includes('_veh_') || s.includes('vehicle')) return 'vehicle'
  if (s.includes('road') || s.includes('_rd_')) return 'road'
  if (s.includes('terrain') || s.includes('lrterrain')) return 'terrain'
  if (s.includes('_tree') || s.includes('_plant') || s.includes('_palm') || s.includes('_bush') || s.includes('_rock') || s.includes('foliage')) return 'vegetation'
  if (s.includes('fence') || s.includes('wall') || s.includes('_env_')) return 'props'
  if (s.includes('anim') || s.includes('hijack')) return 'animation'
  if (s.includes('light') || s.includes('particle')) return 'effects'
  if (s.includes('c3_') || s.includes('c3cell')) return 'world_cell'
  return 'other'
}

const categoryColors = {
  building: 'border-blue-700/50 bg-blue-900/20 text-blue-300',
  vehicle: 'border-amber-700/50 bg-amber-900/20 text-amber-300',
  road: 'border-gray-600/50 bg-gray-800/50 text-gray-300',
  terrain: 'border-emerald-700/50 bg-emerald-900/20 text-emerald-300',
  vegetation: 'border-green-700/50 bg-green-900/20 text-green-300',
  props: 'border-cyan-700/50 bg-cyan-900/20 text-cyan-300',
  animation: 'border-purple-700/50 bg-purple-900/20 text-purple-300',
  effects: 'border-yellow-700/50 bg-yellow-900/20 text-yellow-300',
  world_cell: 'border-indigo-700/50 bg-indigo-900/20 text-indigo-300',
  other: 'border-gray-700/50 bg-gray-800/30 text-gray-400',
}

function categoryBadgeClass(cat) {
  return categoryColors[cat] || categoryColors.other
}

const availableCategories = computed(() => {
  const cats = new Set()
  for (const a of store.assets) cats.add(classifyBlock(a.stem))
  return [...cats].sort()
})

const filteredAssets = computed(() => {
  let list = store.assets

  if (packFilter.value !== 'all') {
    list = list.filter(a => a.pack === packFilter.value)
  }

  if (categoryFilter.value !== 'all') {
    list = list.filter(a => classifyBlock(a.stem) === categoryFilter.value)
  }

  if (contentFilter.value !== 'all') {
    if (contentFilter.value === 'has_mesh') list = list.filter(a => a.manifest || a.obj || a.gltf || a.meshSceneGltf)
    else if (contentFilter.value === 'has_textures') list = list.filter(a => a.textureFiles?.length > 0)
    else if (contentFilter.value === 'has_submeshes') list = list.filter(a => a.manifest)
  }

  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase()
    list = list.filter(a =>
      a.key.toLowerCase().includes(q) ||
      (a.stem && a.stem.toLowerCase().includes(q)) ||
      (a.artifactSearch || '').toLowerCase().includes(q)
    )
  }

  return list
})

const displayedAssets = computed(() => {
  const list = [...filteredAssets.value]
  list.sort((a, b) => {
    const av = sortValue(a)
    const bv = sortValue(b)
    if (av < bv) return -sortDir.value
    if (av > bv) return sortDir.value
    return 0
  })
  return list
})

const totalPages = computed(() => Math.max(1, Math.ceil(displayedAssets.value.length / pageSize)))

const paginatedAssets = computed(() => {
  const start = (currentPage.value - 1) * pageSize
  return displayedAssets.value.slice(start, start + pageSize)
})

function sortValue(a) {
  switch (sortKey.value) {
    case 'stem': return a.stem || ''
    case 'pack': return a.pack || ''
    case 'category': return classifyBlock(a.stem)
    default: return a.stem || ''
  }
}

function toggleSort(key) {
  if (sortKey.value === key) sortDir.value *= -1
  else { sortKey.value = key; sortDir.value = 1 }
}

function sidecarCount(a) {
  if (!a.sidecars) return 0
  return Object.values(a.sidecars).filter(Boolean).length
}

function assetViewerQuery(a) {
  if (a.manifest) return { manifest: a.manifest }
  if (a.gltf || a.meshSceneGltf) return { gltf: a.gltf || a.meshSceneGltf }
  if (a.obj) return { obj: a.obj }
  return {}
}

const tableColumns = [
  { key: 'thumb', label: '' },
  { key: 'stem', label: 'Name' },
  { key: 'pack', label: 'Pack' },
  { key: 'category', label: 'Category' },
  { key: 'content', label: 'Content' },
  { key: 'sidecars', label: 'Sidecars' },
]

watch([packFilter, categoryFilter, contentFilter, searchQuery], () => {
  currentPage.value = 1
})

onMounted(async () => {
  if (!store.assets.length) await store.fetchAssets()
  if (route.query.pack) packFilter.value = route.query.pack
  if (route.query.q) searchQuery.value = route.query.q
  if (route.query.category) categoryFilter.value = route.query.category
})
</script>
