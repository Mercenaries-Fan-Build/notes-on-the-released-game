<template>
  <div class="h-full overflow-auto p-6">
    <h1 class="mb-6 text-2xl font-bold text-gray-100">Mercenaries 2 — Asset Dashboard</h1>

    <!-- Loading state -->
    <div v-if="store.loading" class="py-12 text-center text-sm text-gray-500">Loading asset index…</div>

    <!-- Error state -->
    <div v-else-if="store.error" class="rounded-lg border border-red-800 bg-red-900/20 p-4 text-sm text-red-300">
      Failed to load assets: {{ store.error }}
    </div>

    <template v-else>
      <!-- Stats cards -->
      <div class="mb-8 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-5">
        <StatCard label="Total Blocks" :value="store.totalAssets" icon="cube" color="blue" />
        <StatCard label="With Meshes" :value="store.assetsWithMeshes" icon="mesh" color="green" />
        <StatCard label="With Textures" :value="store.assetsWithTextures" icon="texture" color="purple" />
        <StatCard label="Packs" :value="store.packs.length" icon="pack" color="amber" />
        <StatCard label="Placements" :value="placementCount" icon="pin" color="rose" />
      </div>

      <!-- Pipeline hints -->
      <div v-if="store.pipelineHints.length" class="mb-6 space-y-2">
        <div
          v-for="(hint, i) in store.pipelineHints"
          :key="i"
          class="rounded-lg border border-yellow-800/50 bg-yellow-900/10 px-4 py-2.5 text-xs leading-relaxed text-yellow-300"
        >
          {{ hint.message }}
        </div>
      </div>

      <!-- Pack breakdown -->
      <div class="mb-8">
        <h2 class="mb-3 text-sm font-semibold text-gray-300">Pack Breakdown</h2>
        <div class="flex flex-wrap gap-2">
          <router-link
            v-for="[pack, count] in packEntries"
            :key="pack"
            :to="{ name: 'blocks', query: { pack } }"
            class="group flex items-center gap-2 rounded-lg border border-gray-800 bg-gray-900 px-3 py-2 text-xs transition-colors hover:border-blue-700 hover:bg-gray-800"
          >
            <span class="font-medium text-gray-300 group-hover:text-blue-300">{{ pack }}</span>
            <span class="rounded-full bg-gray-800 px-2 py-0.5 text-[10px] font-semibold text-gray-400 group-hover:bg-blue-900/40 group-hover:text-blue-300">
              {{ count }}
            </span>
          </router-link>
        </div>
      </div>

      <!-- Category distribution (computed from block names) -->
      <div class="mb-8">
        <h2 class="mb-3 text-sm font-semibold text-gray-300">Block Type Distribution</h2>
        <div class="flex flex-wrap gap-2">
          <span
            v-for="cat in categoryDistribution"
            :key="cat.name"
            class="flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-[10px]"
            :class="categoryBadgeClass(cat.name)"
          >
            {{ cat.name }}
            <span class="font-semibold">{{ cat.count }}</span>
          </span>
        </div>
      </div>

      <!-- Quick links -->
      <div>
        <h2 class="mb-3 text-sm font-semibold text-gray-300">Quick Links</h2>
        <div class="grid grid-cols-2 gap-3 sm:grid-cols-4">
          <router-link to="/blocks" class="rounded-lg border border-gray-800 bg-gray-900 p-4 text-center transition-colors hover:border-blue-700 hover:bg-gray-800">
            <div class="text-lg font-bold text-blue-400">Browse</div>
            <div class="mt-1 text-[10px] text-gray-500">All extracted blocks</div>
          </router-link>
          <router-link to="/review" class="rounded-lg border border-gray-800 bg-gray-900 p-4 text-center transition-colors hover:border-orange-700 hover:bg-gray-800">
            <div class="text-lg font-bold text-orange-400">Review</div>
            <div class="mt-1 text-[10px] text-gray-500">Classify & tag blocks</div>
          </router-link>
          <router-link to="/viewer" class="rounded-lg border border-gray-800 bg-gray-900 p-4 text-center transition-colors hover:border-green-700 hover:bg-gray-800">
            <div class="text-lg font-bold text-green-400">3D Viewer</div>
            <div class="mt-1 text-[10px] text-gray-500">Inspect meshes</div>
          </router-link>
          <router-link to="/placements" class="rounded-lg border border-gray-800 bg-gray-900 p-4 text-center transition-colors hover:border-purple-700 hover:bg-gray-800">
            <div class="text-lg font-bold text-purple-400">Map</div>
            <div class="mt-1 text-[10px] text-gray-500">Placement preview</div>
          </router-link>
          <router-link to="/zones" class="rounded-lg border border-gray-800 bg-gray-900 p-4 text-center transition-colors hover:border-teal-700 hover:bg-gray-800">
            <div class="text-lg font-bold text-teal-400">Zones</div>
            <div class="mt-1 text-[10px] text-gray-500">Draw boundaries & paths</div>
          </router-link>
          <router-link to="/search" class="rounded-lg border border-gray-800 bg-gray-900 p-4 text-center transition-colors hover:border-cyan-700 hover:bg-gray-800">
            <div class="text-lg font-bold text-cyan-400">Search</div>
            <div class="mt-1 text-[10px] text-gray-500">Full-text search & stats</div>
          </router-link>
          <router-link to="/placement-qa" class="rounded-lg border border-gray-800 bg-gray-900 p-4 text-center transition-colors hover:border-amber-700 hover:bg-gray-800">
            <div class="text-lg font-bold text-amber-400">QA</div>
            <div class="mt-1 text-[10px] text-gray-500">Bbox & rotation</div>
          </router-link>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useReviewAssetsStore } from '../stores/reviewAssets.js'
import StatCard from '../components/StatCard.vue'

const store = useReviewAssetsStore()
const placementCount = ref('—')

const packEntries = computed(() =>
  Object.entries(store.packCounts).sort(([a], [b]) => a.localeCompare(b))
)

function classifyBlockType(stem) {
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
  if (s.includes('layers_static') || s.includes('vz_state')) return 'placement'
  return 'other'
}

const categoryDistribution = computed(() => {
  const counts = {}
  for (const a of store.assets) {
    const cat = classifyBlockType(a.stem)
    counts[cat] = (counts[cat] || 0) + 1
  }
  return Object.entries(counts)
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => b.count - a.count)
})

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
  placement: 'border-rose-700/50 bg-rose-900/20 text-rose-300',
  other: 'border-gray-700/50 bg-gray-800/30 text-gray-400',
}

function categoryBadgeClass(name) {
  return categoryColors[name] || categoryColors.other
}

onMounted(async () => {
  if (!store.assets.length) await store.fetchAssets()
  try {
    const res = await fetch('/api/placements-catalog.json')
    if (res.ok) {
      const data = await res.json()
      const ls = data.datasets?.find(d => d.id === 'layers_static')
      if (ls?.exists) {
        const plRes = await fetch('/api/placements-dataset.json?id=layers_static')
        if (plRes.ok) {
          const plData = await plRes.json()
          placementCount.value = (plData.placements?.length ?? plData.count ?? '—').toLocaleString()
        }
      }
    }
  } catch { /* ignore */ }
})
</script>
