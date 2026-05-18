<template>
  <div class="h-full overflow-auto bg-gray-950">
    <!-- Search Header -->
    <div class="sticky top-0 z-20 border-b border-gray-800 bg-gray-950/95 backdrop-blur px-6 pt-6 pb-4">
      <h1 class="mb-4 text-2xl font-bold text-gray-100">Search &amp; Analytics</h1>

      <div class="flex flex-col gap-3 sm:flex-row">
        <div class="relative flex-1">
          <svg class="pointer-events-none absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <input
            ref="searchInput"
            v-model="searchQuery"
            type="text"
            placeholder="Search blocks, placements, textures, dialog, missions…"
            class="w-full rounded-lg border border-gray-700 bg-gray-800 py-3 pl-12 pr-10 text-lg text-gray-200 placeholder-gray-500 transition-colors focus:border-blue-600 focus:outline-none focus:ring-1 focus:ring-blue-600"
          />
          <button
            v-if="searchQuery"
            class="absolute right-3 top-1/2 -translate-y-1/2 rounded p-1 text-gray-500 hover:text-gray-300"
            @click="searchQuery = ''; activeTab = 'dashboard'"
          >
            <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
        <select
          v-model="searchScope"
          class="rounded-lg border border-gray-700 bg-gray-800 px-4 py-3 text-sm text-gray-200 focus:border-blue-600 focus:outline-none"
        >
          <option value="all">All</option>
          <option value="blocks">Blocks</option>
          <option value="placements">Placements</option>
          <option value="textures">Textures</option>
          <option value="dialog">Dialog</option>
          <option value="lua">Lua Scripts</option>
          <option value="missions">Missions</option>
        </select>
      </div>

      <!-- Tab bar -->
      <div class="mt-3 flex gap-1">
        <button
          v-for="tab in tabs"
          :key="tab.id"
          class="rounded-t-lg px-3 py-1.5 text-xs font-medium transition-colors"
          :class="activeTab === tab.id
            ? 'bg-gray-800 text-white'
            : 'text-gray-500 hover:bg-gray-900 hover:text-gray-300'"
          @click="activeTab = tab.id"
        >
          {{ tab.label }}
        </button>
      </div>
    </div>

    <div class="p-6">
      <!-- ==================== SEARCH RESULTS ==================== -->
      <template v-if="activeTab === 'results' && debouncedQuery">
        <div v-if="searchLoading" class="py-12 text-center text-sm text-gray-500">Searching…</div>
        <div v-else-if="searchError" class="rounded-lg border border-red-800 bg-red-900/20 p-4 text-sm text-red-300">
          Search failed: {{ searchError }}
        </div>
        <div v-else-if="totalResultCount === 0" class="py-12 text-center text-sm text-gray-500">
          No results for "{{ debouncedQuery }}"
        </div>
        <div v-else class="space-y-8">
          <!-- Blocks -->
          <section v-if="(searchScope === 'all' || searchScope === 'blocks') && results.blocks.items.length">
            <div class="mb-3 flex items-center justify-between">
              <h2 class="text-sm font-semibold text-gray-300">
                Blocks
                <span class="ml-2 rounded-full bg-blue-900/30 px-2 py-0.5 text-[10px] font-normal text-blue-300">{{ results.blocks.total }}</span>
              </h2>
              <router-link
                :to="{ path: '/blocks', query: { q: debouncedQuery } }"
                class="text-[11px] text-blue-400 hover:text-blue-300"
              >Show all →</router-link>
            </div>
            <div class="overflow-hidden rounded-lg border border-gray-800">
              <table class="w-full text-xs">
                <thead>
                  <tr class="border-b border-gray-800 bg-gray-900">
                    <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Name</th>
                    <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Canonical</th>
                    <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Type</th>
                    <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Status</th>
                  </tr>
                </thead>
                <tbody>
                  <tr
                    v-for="b in results.blocks.items"
                    :key="b.id"
                    class="border-b border-gray-800/50 transition-colors hover:bg-gray-800/40"
                  >
                    <td class="px-3 py-2">
                      <router-link :to="'/blocks/' + b.id" class="font-medium text-gray-200 hover:text-blue-300">{{ b.stem }}</router-link>
                    </td>
                    <td class="px-3 py-2 text-gray-400">{{ b.canonical_name || '—' }}</td>
                    <td class="px-3 py-2">
                      <span v-if="b.block_type" class="rounded-full border border-cyan-700/50 bg-cyan-900/20 px-2 py-0.5 text-[10px] text-cyan-300">{{ b.block_type }}</span>
                    </td>
                    <td class="px-3 py-2">
                      <span class="rounded-full px-2 py-0.5 text-[10px] font-medium" :class="reviewBadgeClass(b.review_status)">{{ b.review_status }}</span>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>

          <!-- Placements -->
          <section v-if="(searchScope === 'all' || searchScope === 'placements') && results.placements.items.length">
            <div class="mb-3 flex items-center justify-between">
              <h2 class="text-sm font-semibold text-gray-300">
                Placements
                <span class="ml-2 rounded-full bg-rose-900/30 px-2 py-0.5 text-[10px] font-normal text-rose-300">{{ results.placements.total }}</span>
              </h2>
              <router-link
                :to="{ path: '/placements', query: { q: debouncedQuery } }"
                class="text-[11px] text-blue-400 hover:text-blue-300"
              >Show all →</router-link>
            </div>
            <div class="overflow-hidden rounded-lg border border-gray-800">
              <table class="w-full text-xs">
                <thead>
                  <tr class="border-b border-gray-800 bg-gray-900">
                    <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Entity</th>
                    <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Type</th>
                    <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Position</th>
                    <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">VZ Source</th>
                  </tr>
                </thead>
                <tbody>
                  <tr
                    v-for="p in results.placements.items"
                    :key="p.id"
                    class="border-b border-gray-800/50 transition-colors hover:bg-gray-800/40"
                  >
                    <td class="px-3 py-2 font-medium text-gray-200">{{ p.entity_name || '—' }}</td>
                    <td class="px-3 py-2 text-gray-400">{{ p.block_type || '—' }}</td>
                    <td class="px-3 py-2 font-mono text-[10px] text-gray-500">
                      {{ fmtCoord(p.pos_x) }}, {{ fmtCoord(p.pos_y) }}, {{ fmtCoord(p.pos_z) }}
                    </td>
                    <td class="px-3 py-2 text-gray-400">{{ p.vz_state_source || 'layers_static' }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>

          <!-- Textures -->
          <section v-if="(searchScope === 'all' || searchScope === 'textures') && results.textures.items.length">
            <div class="mb-3 flex items-center justify-between">
              <h2 class="text-sm font-semibold text-gray-300">
                Textures
                <span class="ml-2 rounded-full bg-purple-900/30 px-2 py-0.5 text-[10px] font-normal text-purple-300">{{ results.textures.total }}</span>
              </h2>
            </div>
            <div class="overflow-hidden rounded-lg border border-gray-800">
              <table class="w-full text-xs">
                <thead>
                  <tr class="border-b border-gray-800 bg-gray-900">
                    <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Name</th>
                    <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Dimensions</th>
                    <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">FourCC</th>
                    <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Channel</th>
                  </tr>
                </thead>
                <tbody>
                  <tr
                    v-for="t in results.textures.items"
                    :key="t.id"
                    class="border-b border-gray-800/50 transition-colors hover:bg-gray-800/40"
                  >
                    <td class="px-3 py-2 font-medium text-gray-200">{{ t.name }}</td>
                    <td class="px-3 py-2 font-mono text-[10px] text-gray-400">{{ t.width }}×{{ t.height }}</td>
                    <td class="px-3 py-2">
                      <span v-if="t.fourcc" class="rounded bg-gray-800 px-1.5 py-0.5 text-[10px] text-gray-300">{{ t.fourcc }}</span>
                    </td>
                    <td class="px-3 py-2">
                      <span v-if="t.texture_channel" class="rounded-full border border-purple-700/50 bg-purple-900/20 px-2 py-0.5 text-[10px] text-purple-300">{{ t.texture_channel }}</span>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>

          <!-- Dialog Fragments -->
          <section v-if="(searchScope === 'all' || searchScope === 'dialog') && results.dialog.items.length">
            <div class="mb-3 flex items-center justify-between">
              <h2 class="text-sm font-semibold text-gray-300">
                Dialog
                <span class="ml-2 rounded-full bg-amber-900/30 px-2 py-0.5 text-[10px] font-normal text-amber-300">{{ results.dialog.total }}</span>
              </h2>
            </div>
            <div class="overflow-hidden rounded-lg border border-gray-800">
              <table class="w-full text-xs">
                <thead>
                  <tr class="border-b border-gray-800 bg-gray-900">
                    <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Value</th>
                    <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Type</th>
                    <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Namespace</th>
                    <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Flags</th>
                  </tr>
                </thead>
                <tbody>
                  <tr
                    v-for="d in results.dialog.items"
                    :key="d.id"
                    class="border-b border-gray-800/50 transition-colors hover:bg-gray-800/40"
                  >
                    <td class="max-w-[300px] truncate px-3 py-2 font-medium text-gray-200" :title="d.value">{{ d.value || '—' }}</td>
                    <td class="px-3 py-2 text-gray-400">{{ d.fragment_type || '—' }}</td>
                    <td class="px-3 py-2 text-gray-400">{{ d.namespace || '—' }}</td>
                    <td class="px-3 py-2">
                      <span v-if="d.is_mission_ref" class="rounded-full border border-amber-700/50 bg-amber-900/20 px-2 py-0.5 text-[10px] text-amber-300">mission</span>
                      <span v-if="d.is_localization" class="ml-1 rounded-full border border-green-700/50 bg-green-900/20 px-2 py-0.5 text-[10px] text-green-300">i18n</span>
                      <span v-if="d.is_subtitle" class="ml-1 rounded-full border border-indigo-700/50 bg-indigo-900/20 px-2 py-0.5 text-[10px] text-indigo-300">subtitle</span>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>

          <!-- Missions -->
          <section v-if="(searchScope === 'all' || searchScope === 'missions') && filteredMissions.length">
            <div class="mb-3">
              <h2 class="text-sm font-semibold text-gray-300">
                Missions
                <span class="ml-2 rounded-full bg-green-900/30 px-2 py-0.5 text-[10px] font-normal text-green-300">{{ filteredMissions.length }}</span>
              </h2>
            </div>
            <div class="overflow-hidden rounded-lg border border-gray-800">
              <table class="w-full text-xs">
                <thead>
                  <tr class="border-b border-gray-800 bg-gray-900">
                    <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Mission ID</th>
                    <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Faction</th>
                    <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Type</th>
                    <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Act</th>
                  </tr>
                </thead>
                <tbody>
                  <tr
                    v-for="m in filteredMissions.slice(0, 10)"
                    :key="m.id"
                    class="border-b border-gray-800/50 transition-colors hover:bg-gray-800/40"
                  >
                    <td class="px-3 py-2 font-medium text-gray-200">{{ m.mission_id }}</td>
                    <td class="px-3 py-2">
                      <span v-if="m.faction" class="rounded-full border border-amber-700/50 bg-amber-900/20 px-2 py-0.5 text-[10px] text-amber-300">{{ m.faction }}</span>
                    </td>
                    <td class="px-3 py-2 text-gray-400">{{ m.type || '—' }}</td>
                    <td class="px-3 py-2 text-gray-400">{{ m.act || '—' }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>
        </div>
      </template>

      <!-- ==================== DASHBOARD ==================== -->
      <template v-if="activeTab === 'dashboard'">
        <!-- Stats Cards -->
        <div v-if="statsLoading" class="py-12 text-center text-sm text-gray-500">Loading statistics…</div>
        <div v-else-if="statsError" class="rounded-lg border border-red-800 bg-red-900/20 p-4 text-sm text-red-300">
          Failed to load stats: {{ statsError }}
        </div>
        <template v-else>
          <h2 class="mb-4 text-sm font-semibold text-gray-300">Database Statistics</h2>
          <div class="mb-8 grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-7">
            <div
              v-for="card in statCards"
              :key="card.label"
              class="rounded-lg border p-4"
              :class="card.cardClass"
            >
              <div class="text-3xl font-bold text-white">{{ fmtNum(card.value) }}</div>
              <div class="mt-1 text-sm text-gray-400">{{ card.label }}</div>
            </div>
          </div>

          <!-- Quick Stats Cards -->
          <h2 class="mb-4 text-sm font-semibold text-gray-300">Quick Stats</h2>
          <div class="mb-8 grid grid-cols-2 gap-3 sm:grid-cols-4">
            <div class="rounded-lg border border-blue-800/40 bg-blue-900/10 p-4">
              <div class="text-3xl font-bold text-white">{{ fmtNum(quickStats.withGeometry) }}</div>
              <div class="mt-1 text-sm text-gray-400">Blocks w/ Geometry</div>
              <div class="mt-1 text-[10px] text-gray-600">of {{ fmtNum(stats.blocks) }} total</div>
            </div>
            <div class="rounded-lg border border-purple-800/40 bg-purple-900/10 p-4">
              <div class="text-3xl font-bold text-white">{{ fmtNum(quickStats.withTextures) }}</div>
              <div class="mt-1 text-sm text-gray-400">Blocks w/ Textures</div>
              <div class="mt-1 text-[10px] text-gray-600">of {{ fmtNum(stats.blocks) }} total</div>
            </div>
            <div class="rounded-lg border border-green-800/40 bg-green-900/10 p-4">
              <div class="text-3xl font-bold text-white">{{ fmtNum(quickStats.reviewed) }}</div>
              <div class="mt-1 text-sm text-gray-400">Blocks Reviewed</div>
              <div class="mt-1 text-[10px] text-gray-600">of {{ fmtNum(stats.blocks) }} total</div>
            </div>
            <div class="rounded-lg border border-amber-800/40 bg-amber-900/10 p-4">
              <div class="text-3xl font-bold text-white">{{ quickStats.avgFileSize }}</div>
              <div class="mt-1 text-sm text-gray-400">Avg File Size</div>
              <div class="mt-1 text-[10px] text-gray-600">per block</div>
            </div>
          </div>

          <!-- Block Type Distribution -->
          <h2 class="mb-4 text-sm font-semibold text-gray-300">Block Type Distribution</h2>
          <div v-if="blockTypeSummary.length" class="mb-8 space-y-2">
            <div v-for="bt in blockTypeSummary" :key="bt.block_type" class="flex items-center gap-3">
              <span class="w-32 truncate text-right text-xs text-gray-400" :title="bt.block_type">{{ bt.block_type || 'unknown' }}</span>
              <div class="flex-1 overflow-hidden rounded bg-gray-800">
                <div
                  class="h-5 rounded bg-blue-600/60 transition-all"
                  :style="{ width: barWidth(bt.count, blockTypeMax) }"
                />
              </div>
              <span class="w-14 text-right font-mono text-xs text-gray-400">{{ fmtNum(bt.count) }}</span>
            </div>
          </div>

          <!-- Review Status -->
          <h2 class="mb-4 text-sm font-semibold text-gray-300">Review Status Overview</h2>
          <div v-if="reviewStatusGroups.length" class="mb-8 space-y-2">
            <div v-for="rs in reviewStatusGroups" :key="rs.status" class="flex items-center gap-3">
              <span class="w-32 text-right">
                <span class="rounded-full px-2 py-0.5 text-[10px] font-medium" :class="reviewBadgeClass(rs.status)">{{ rs.status }}</span>
              </span>
              <div class="flex-1 overflow-hidden rounded bg-gray-800">
                <div
                  class="h-5 rounded transition-all"
                  :class="reviewBarClass(rs.status)"
                  :style="{ width: barWidth(rs.count, reviewStatusMax) }"
                />
              </div>
              <span class="w-14 text-right font-mono text-xs text-gray-400">{{ fmtNum(rs.count) }}</span>
            </div>
          </div>
        </template>
      </template>

      <!-- ==================== VALIDATION ==================== -->
      <template v-if="activeTab === 'validation'">
        <div class="mb-4 flex items-center gap-3">
          <h2 class="text-sm font-semibold text-gray-300">Consistency Checks</h2>
          <div class="flex rounded border border-gray-700">
            <button
              v-for="f in ['all', 'pass', 'warn', 'fail']"
              :key="f"
              class="px-3 py-1 text-xs transition-colors"
              :class="validationFilter === f ? 'bg-gray-700 text-white' : 'text-gray-400 hover:text-gray-200'"
              @click="validationFilter = f; fetchValidation()"
            >
              {{ f === 'all' ? 'All' : f.charAt(0).toUpperCase() + f.slice(1) }}
            </button>
          </div>
        </div>

        <div v-if="validationLoading" class="py-12 text-center text-sm text-gray-500">Loading validation results…</div>
        <div v-else-if="validationError" class="rounded-lg border border-red-800 bg-red-900/20 p-4 text-sm text-red-300">
          Failed to load validation: {{ validationError }}
        </div>
        <div v-else-if="!validationResults.length" class="py-12 text-center text-sm text-gray-500">No validation results found.</div>
        <div v-else class="overflow-hidden rounded-lg border border-gray-800">
          <table class="w-full text-xs">
            <thead>
              <tr class="border-b border-gray-800 bg-gray-900">
                <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Check</th>
                <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Status</th>
                <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Block</th>
                <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Expected</th>
                <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Actual</th>
                <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Message</th>
                <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Run At</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="v in validationResults"
                :key="v.id"
                class="border-b border-gray-800/50 transition-colors hover:bg-gray-800/40"
              >
                <td class="px-3 py-2 font-medium text-gray-200">{{ v.check_name }}</td>
                <td class="px-3 py-2">
                  <span class="rounded-full px-2 py-0.5 text-[10px] font-medium" :class="validationStatusClass(v.status)">{{ v.status }}</span>
                </td>
                <td class="px-3 py-2">
                  <router-link v-if="v.block_id" :to="'/blocks/' + v.block_id" class="text-blue-400 hover:text-blue-300">{{ v.block_id }}</router-link>
                  <span v-else class="text-gray-600">—</span>
                </td>
                <td class="max-w-[120px] truncate px-3 py-2 text-gray-400" :title="v.expected_value">{{ v.expected_value || '—' }}</td>
                <td class="max-w-[120px] truncate px-3 py-2 text-gray-400" :title="v.actual_value">{{ v.actual_value || '—' }}</td>
                <td class="max-w-[200px] truncate px-3 py-2 text-gray-400" :title="v.message">{{ v.message || '—' }}</td>
                <td class="whitespace-nowrap px-3 py-2 text-gray-500">{{ fmtDate(v.run_at) }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </template>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, nextTick } from 'vue'

const searchQuery = ref('')
const debouncedQuery = ref('')
const searchScope = ref('all')
const activeTab = ref('dashboard')
const searchInput = ref(null)

const tabs = [
  { id: 'dashboard', label: 'Dashboard' },
  { id: 'results', label: 'Search Results' },
  { id: 'validation', label: 'Consistency Checks' },
]

// ---------- Debounce ----------

let debounceTimer = null
watch(searchQuery, (val) => {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(() => {
    debouncedQuery.value = val.trim()
    if (val.trim()) {
      activeTab.value = 'results'
    }
  }, 300)
})

// ---------- Stats ----------

const stats = ref({})
const statsLoading = ref(false)
const statsError = ref(null)

const statCards = computed(() => {
  const s = stats.value
  const defs = [
    { key: 'blocks',            label: 'Blocks',           cardClass: 'border-blue-800/40 bg-blue-900/10' },
    { key: 'placements',        label: 'Placements',       cardClass: 'border-rose-800/40 bg-rose-900/10' },
    { key: 'textures',          label: 'Textures',         cardClass: 'border-purple-800/40 bg-purple-900/10' },
    { key: 'categories',        label: 'Categories',       cardClass: 'border-cyan-800/40 bg-cyan-900/10' },
    { key: 'ecs_records',       label: 'ECS Records',      cardClass: 'border-green-800/40 bg-green-900/10' },
    { key: 'animation_groups',  label: 'Anim Groups',      cardClass: 'border-amber-800/40 bg-amber-900/10' },
    { key: 'world_cells',       label: 'World Cells',      cardClass: 'border-indigo-800/40 bg-indigo-900/10' },
    { key: 'wad_archives',      label: 'WAD Archives',     cardClass: 'border-gray-700/50 bg-gray-800/30' },
    { key: 'vz_state_overlays', label: 'VZ Overlays',      cardClass: 'border-emerald-800/40 bg-emerald-900/10' },
    { key: 'missions',          label: 'Missions',         cardClass: 'border-yellow-800/40 bg-yellow-900/10' },
    { key: 'factions',          label: 'Factions',         cardClass: 'border-red-800/40 bg-red-900/10' },
    { key: 'lua_chunks',        label: 'Lua Chunks',       cardClass: 'border-orange-800/40 bg-orange-900/10' },
    { key: 'dialog_fragments',  label: 'Dialog Fragments', cardClass: 'border-pink-800/40 bg-pink-900/10' },
    { key: 'aset_rows',         label: 'ASET Rows',        cardClass: 'border-teal-800/40 bg-teal-900/10' },
  ]
  return defs.map(d => ({ ...d, value: s[d.key] ?? 0 }))
})

async function fetchStats() {
  statsLoading.value = true
  statsError.value = null
  try {
    const res = await fetch('/api/stats')
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    stats.value = await res.json()
  } catch (e) {
    statsError.value = e.message
  } finally {
    statsLoading.value = false
  }
}

// ---------- Block Type Summary ----------

const blockTypeSummary = ref([])

const blockTypeMax = computed(() =>
  blockTypeSummary.value.reduce((mx, bt) => Math.max(mx, bt.count), 1)
)

async function fetchBlockTypeSummary() {
  try {
    const res = await fetch('/api/blocks/types/summary')
    if (res.ok) blockTypeSummary.value = await res.json()
  } catch { /* ignore */ }
}

// ---------- Review Status ----------

const reviewStatusGroups = ref([])

const reviewStatusMax = computed(() =>
  reviewStatusGroups.value.reduce((mx, rs) => Math.max(mx, rs.count), 1)
)

async function fetchReviewStatus() {
  try {
    const res = await fetch('/api/blocks/review-status/summary')
    if (res.ok) {
      const data = await res.json()
      reviewStatusGroups.value = data
        .map(d => ({ status: d.review_status, count: d.count }))
        .filter(d => d.count > 0)
        .sort((a, b) => b.count - a.count)
    }
  } catch { /* ignore */ }
}

// ---------- Quick Stats ----------

const quickStats = ref({
  withGeometry: 0,
  withTextures: 0,
  reviewed: 0,
  avgFileSize: '—',
})

async function fetchQuickStats() {
  try {
    const [geoRes, texRes, revRes] = await Promise.all([
      fetch('/api/blocks?has_geometry=true&limit=0'),
      fetch('/api/blocks?has_textures=true&limit=0'),
      fetch('/api/blocks?review_status=approved&limit=0'),
    ])
    if (geoRes.ok) {
      const d = await geoRes.json()
      quickStats.value.withGeometry = d.total
    }
    if (texRes.ok) {
      const d = await texRes.json()
      quickStats.value.withTextures = d.total
    }
    if (revRes.ok) {
      const d = await revRes.json()
      quickStats.value.reviewed = d.total
    }

    const sampleRes = await fetch('/api/blocks?limit=100')
    if (sampleRes.ok) {
      const sampleData = await sampleRes.json()
      const sizes = sampleData.items
        .map(b => b.file_size_bytes)
        .filter(s => s != null && s > 0)
      if (sizes.length) {
        const avg = sizes.reduce((a, b) => a + b, 0) / sizes.length
        quickStats.value.avgFileSize = fmtBytes(avg)
      }
    }
  } catch { /* ignore */ }
}

// ---------- Search ----------

const searchLoading = ref(false)
const searchError = ref(null)
const results = ref({
  blocks: { items: [], total: 0 },
  placements: { items: [], total: 0 },
  textures: { items: [], total: 0 },
  dialog: { items: [], total: 0 },
})
const allMissions = ref([])

const filteredMissions = computed(() => {
  if (!debouncedQuery.value) return []
  const q = debouncedQuery.value.toLowerCase()
  return allMissions.value.filter(m =>
    (m.mission_id || '').toLowerCase().includes(q) ||
    (m.faction || '').toLowerCase().includes(q) ||
    (m.type || '').toLowerCase().includes(q) ||
    (m.npc_name || '').toLowerCase().includes(q)
  )
})

const totalResultCount = computed(() =>
  results.value.blocks.total +
  results.value.placements.total +
  results.value.textures.total +
  results.value.dialog.total +
  filteredMissions.value.length
)

watch(debouncedQuery, (q) => {
  if (q) performSearch(q)
})

watch(searchScope, () => {
  if (debouncedQuery.value) performSearch(debouncedQuery.value)
})

async function performSearch(query) {
  searchLoading.value = true
  searchError.value = null
  const scope = searchScope.value

  try {
    const fetches = []

    if (scope === 'all' || scope === 'blocks') {
      fetches.push(
        fetch(`/api/blocks?search=${encodeURIComponent(query)}&limit=10`)
          .then(r => r.ok ? r.json() : { items: [], total: 0 })
          .then(d => { results.value.blocks = d })
      )
    } else {
      results.value.blocks = { items: [], total: 0 }
    }

    if (scope === 'all' || scope === 'placements') {
      fetches.push(
        fetch(`/api/placements?search=${encodeURIComponent(query)}&limit=10`)
          .then(r => r.ok ? r.json() : { items: [], total: 0 })
          .then(d => { results.value.placements = d })
      )
    } else {
      results.value.placements = { items: [], total: 0 }
    }

    if (scope === 'all' || scope === 'textures') {
      fetches.push(
        fetch(`/api/textures?search=${encodeURIComponent(query)}&limit=10`)
          .then(r => r.ok ? r.json() : { items: [], total: 0 })
          .then(d => { results.value.textures = d })
      )
    } else {
      results.value.textures = { items: [], total: 0 }
    }

    if (scope === 'all' || scope === 'dialog') {
      fetches.push(
        fetch(`/api/dialog-fragments?search=${encodeURIComponent(query)}&limit=10`)
          .then(r => r.ok ? r.json() : { items: [], total: 0 })
          .then(d => { results.value.dialog = d })
      )
    } else {
      results.value.dialog = { items: [], total: 0 }
    }

    if ((scope === 'all' || scope === 'missions') && !allMissions.value.length) {
      fetches.push(fetchMissions())
    }

    await Promise.all(fetches)
  } catch (e) {
    searchError.value = e.message
  } finally {
    searchLoading.value = false
  }
}

async function fetchMissions() {
  try {
    const res = await fetch('/api/missions?limit=500')
    if (res.ok) {
      const data = await res.json()
      allMissions.value = data.items || []
    }
  } catch { /* ignore */ }
}

// ---------- Validation ----------

const validationFilter = ref('all')
const validationResults = ref([])
const validationLoading = ref(false)
const validationError = ref(null)

async function fetchValidation() {
  validationLoading.value = true
  validationError.value = null
  try {
    const params = new URLSearchParams({ limit: '50' })
    if (validationFilter.value !== 'all') params.set('status', validationFilter.value)
    const res = await fetch(`/api/validation-results?${params}`)
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const data = await res.json()
    validationResults.value = data.items || []
  } catch (e) {
    validationError.value = e.message
  } finally {
    validationLoading.value = false
  }
}

// ---------- Helpers ----------

function fmtNum(n) {
  if (n == null) return '—'
  return Number(n).toLocaleString()
}

function fmtCoord(v) {
  if (v == null) return '?'
  return Number(v).toFixed(1)
}

function fmtDate(d) {
  if (!d) return '—'
  return new Date(d).toLocaleDateString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
}

function fmtBytes(bytes) {
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
  return (bytes / (1024 * 1024)).toFixed(1) + ' MB'
}

function barWidth(value, max) {
  if (!max) return '0%'
  return Math.max(1, (value / max) * 100).toFixed(1) + '%'
}

function reviewBadgeClass(status) {
  const map = {
    unreviewed:       'border border-gray-600/50 bg-gray-800/50 text-gray-400',
    auto_classified:  'border border-blue-700/50 bg-blue-900/20 text-blue-300',
    needs_review:     'border border-yellow-700/50 bg-yellow-900/20 text-yellow-300',
    in_progress:      'border border-purple-700/50 bg-purple-900/20 text-purple-300',
    reviewed:         'border border-green-700/50 bg-green-900/20 text-green-300',
    approved:         'border border-emerald-700/50 bg-emerald-900/20 text-emerald-300',
    flagged:          'border border-red-700/50 bg-red-900/20 text-red-300',
    rejected:         'border border-red-800/50 bg-red-900/30 text-red-400',
  }
  return map[status] || map.unreviewed
}

function reviewBarClass(status) {
  const map = {
    unreviewed:       'bg-gray-600/60',
    auto_classified:  'bg-blue-600/60',
    needs_review:     'bg-yellow-600/60',
    in_progress:      'bg-purple-600/60',
    reviewed:         'bg-green-600/60',
    approved:         'bg-emerald-600/60',
    flagged:          'bg-red-600/60',
    rejected:         'bg-red-800/60',
  }
  return map[status] || 'bg-gray-600/60'
}

function validationStatusClass(status) {
  const map = {
    pass: 'border border-green-700/50 bg-green-900/20 text-green-300',
    warn: 'border border-amber-700/50 bg-amber-900/20 text-amber-300',
    fail: 'border border-red-700/50 bg-red-900/20 text-red-300',
  }
  return map[status] || 'border border-gray-600/50 bg-gray-800/50 text-gray-400'
}

// ---------- Init ----------

onMounted(async () => {
  await Promise.all([
    fetchStats(),
    fetchBlockTypeSummary(),
    fetchReviewStatus(),
    fetchQuickStats(),
  ])
  await nextTick()
  searchInput.value?.focus()
})
</script>
