<template>
  <div class="h-full overflow-auto bg-gray-950">
    <!-- Loading -->
    <div v-if="loading" class="flex h-full items-center justify-center">
      <span class="text-sm text-gray-500">Loading block…</span>
    </div>

    <!-- Error -->
    <div v-else-if="error" class="p-6">
      <div class="rounded-lg border border-red-800 bg-red-900/20 p-4 text-sm text-red-300">
        {{ error }}
      </div>
      <router-link to="/blocks" class="mt-4 inline-block text-xs text-blue-400 hover:text-blue-300">← Back to blocks</router-link>
    </div>

    <!-- Main content -->
    <div v-else-if="block" class="mx-auto max-w-7xl p-6">

      <!-- Header bar -->
      <div class="mb-6 flex flex-wrap items-center gap-3">
        <router-link to="/blocks" class="text-gray-400 hover:text-gray-200" title="Back to blocks">
          <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
          </svg>
        </router-link>
        <h1 class="text-xl font-bold text-gray-100">{{ block.stem }}</h1>
        <span
          class="rounded-full px-2.5 py-0.5 text-[10px] font-semibold"
          :class="reviewStatusClass(block.review_status)"
        >
          {{ block.review_status || 'unknown' }}
        </span>
        <span
          v-if="block.block_type"
          class="rounded-full border border-gray-700 bg-gray-800 px-2 py-0.5 text-[10px] font-medium text-gray-300"
        >
          {{ block.block_type }}
        </span>
        <span
          v-if="block.category"
          class="rounded-full px-2 py-0.5 text-[10px] font-medium"
          :class="categoryBadgeClass(block.category)"
        >
          {{ block.category }}
        </span>
      </div>

      <!-- Info grid -->
      <div class="mb-6 grid gap-4 lg:grid-cols-3">
        <!-- Left: metadata -->
        <div class="rounded-lg border border-gray-800 bg-gray-900 p-4">
          <h2 class="mb-3 text-[11px] font-semibold uppercase tracking-wider text-gray-500">Metadata</h2>
          <dl class="space-y-1.5 text-xs">
            <InfoRow label="WAD" :value="block.wad" />
            <InfoRow label="Pack" :value="block.pack" />
            <InfoRow label="Block Index" :value="block.block_index" />
            <InfoRow label="P-Level" :value="block.p_level" />
            <InfoRow label="Q-Level" :value="block.q_level" />
            <InfoRow label="Base Asset" :value="block.base_asset_id" />
            <InfoRow label="Variant" :value="block.variant_type" />
            <InfoRow label="Faction" :value="block.faction_hint" />
            <InfoRow label="Region" :value="block.region_hint" />
          </dl>
        </div>

        <!-- Middle: file info & flags -->
        <div class="rounded-lg border border-gray-800 bg-gray-900 p-4">
          <h2 class="mb-3 text-[11px] font-semibold uppercase tracking-wider text-gray-500">Content</h2>
          <div class="mb-3 text-xs text-gray-300">
            <span class="text-gray-500">Size:</span> {{ formatBytes(block.file_size_bytes) }}
          </div>
          <div class="flex flex-wrap gap-1.5">
            <FlagBadge label="Geometry" :active="block.has_geometry" />
            <FlagBadge label="Textures" :active="block.has_textures" />
            <FlagBadge label="Havok" :active="block.has_havok" />
            <FlagBadge label="Animations" :active="block.has_animations" />
            <FlagBadge label="Lua" :active="block.has_lua" />
            <FlagBadge label="Audio" :active="block.has_audio" />
            <FlagBadge label="Dialog" :active="block.has_dialog" />
          </div>
        </div>

        <!-- Right: paths -->
        <div class="rounded-lg border border-gray-800 bg-gray-900 p-4">
          <h2 class="mb-3 text-[11px] font-semibold uppercase tracking-wider text-gray-500">Paths</h2>
          <dl class="space-y-2 text-xs">
            <PathRow label="Review Dir" :value="block.review_dir_path" />
            <PathRow label="GLB" :value="block.glb_path" />
            <PathRow label="glTF" :value="block.gltf_path" />
            <PathRow label="OBJ" :value="block.obj_path" />
          </dl>
        </div>
      </div>

      <!-- 3D Viewer -->
      <div class="mb-6 overflow-hidden rounded-lg border border-gray-800 bg-gray-900">
        <div v-if="glbUrl" class="relative">
          <div ref="viewerContainer" class="h-[400px] w-full" />
          <div class="pointer-events-none absolute bottom-2 left-3 text-[10px] text-gray-500/60">
            Orbit: drag &bull; Zoom: wheel
          </div>
        </div>
        <div v-else class="flex h-[200px] items-center justify-center text-sm text-gray-600">
          No 3D model available
        </div>
      </div>

      <!-- Mesh Metadata (if has_geometry) -->
      <div v-if="block.has_geometry && meshMeta" class="mb-6 rounded-lg border border-gray-800 bg-gray-900 p-4">
        <h2 class="mb-3 text-[11px] font-semibold uppercase tracking-wider text-gray-500">Mesh Summary</h2>
        <div class="grid grid-cols-2 gap-x-6 gap-y-1.5 text-xs sm:grid-cols-4">
          <InfoRow label="Vertices" :value="meshMeta.total_vertices?.toLocaleString()" />
          <InfoRow label="Faces" :value="meshMeta.total_faces?.toLocaleString()" />
          <InfoRow label="Topology" :value="meshMeta.topology" />
          <InfoRow label="Extraction" :value="meshMeta.extraction_method" />
          <InfoRow label="Extent X" :value="meshMeta.extent_x?.toFixed(2)" />
          <InfoRow label="Extent Y" :value="meshMeta.extent_y?.toFixed(2)" />
          <InfoRow label="Extent Z" :value="meshMeta.extent_z?.toFixed(2)" />
          <InfoRow label="Bbox Vol" :value="meshMeta.bbox_volume?.toFixed(2)" />
        </div>
      </div>

      <!-- Tabs -->
      <div class="rounded-lg border border-gray-800 bg-gray-900">
        <!-- Tab bar -->
        <div class="flex overflow-x-auto border-b border-gray-800">
          <button
            v-for="tab in visibleTabs"
            :key="tab.key"
            class="whitespace-nowrap px-4 py-2.5 text-xs font-medium transition-colors"
            :class="activeTab === tab.key
              ? 'border-b-2 border-blue-500 text-blue-400'
              : 'text-gray-500 hover:text-gray-300'"
            @click="switchTab(tab.key)"
          >
            {{ tab.label }}
          </button>
        </div>

        <!-- Tab content -->
        <div class="p-4">
          <!-- Loading indicator for tab data -->
          <div v-if="tabLoading" class="py-8 text-center text-xs text-gray-500">Loading…</div>
          <div v-else-if="tabError" class="py-4 text-xs text-red-400">{{ tabError }}</div>

          <!-- Submeshes -->
          <template v-else-if="activeTab === 'submeshes'">
            <div v-if="!submeshes.length" class="py-6 text-center text-xs text-gray-600">No submeshes found</div>
            <div v-else class="overflow-x-auto">
              <table class="w-full border-collapse text-xs">
                <thead>
                  <tr>
                    <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Index</th>
                    <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Vertices</th>
                    <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Faces</th>
                    <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Mat Idx</th>
                    <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Diffuse Texture</th>
                    <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">LOD Group</th>
                    <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Damage</th>
                    <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-right text-[10px] font-semibold uppercase tracking-wider text-gray-500">Bbox Vol</th>
                  </tr>
                </thead>
                <tbody>
                  <tr
                    v-for="sm in submeshes"
                    :key="sm.index"
                    class="border-b border-gray-800/50 transition-colors hover:bg-gray-800/40"
                  >
                    <td class="px-3 py-1.5 text-gray-300">{{ sm.index }}</td>
                    <td class="px-3 py-1.5 text-gray-300">{{ sm.vertex_count?.toLocaleString() }}</td>
                    <td class="px-3 py-1.5 text-gray-300">{{ sm.face_count?.toLocaleString() }}</td>
                    <td class="px-3 py-1.5 text-gray-400">{{ sm.material_index ?? '—' }}</td>
                    <td class="max-w-[200px] truncate px-3 py-1.5 text-gray-400" :title="sm.texture_diffuse">{{ sm.texture_diffuse || '—' }}</td>
                    <td class="px-3 py-1.5 text-gray-400">{{ sm.lod_group ?? '—' }}</td>
                    <td class="px-3 py-1.5 text-gray-400">{{ sm.damage_state || '—' }}</td>
                    <td class="px-3 py-1.5 text-right text-gray-400">{{ sm.bbox_volume != null ? sm.bbox_volume.toFixed(2) : '—' }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </template>

          <!-- Textures -->
          <template v-else-if="activeTab === 'textures'">
            <div v-if="!textures.length" class="py-6 text-center text-xs text-gray-600">No textures found</div>
            <div v-else class="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
              <div
                v-for="tex in textures"
                :key="tex.name || tex.id"
                class="rounded-lg border border-gray-800 bg-gray-800/40 p-3"
              >
                <div class="mb-1 truncate text-xs font-medium text-gray-200" :title="tex.name">{{ tex.name }}</div>
                <div class="mb-2 text-[10px] text-gray-500">
                  {{ tex.width }}×{{ tex.height }} &middot; {{ tex.fourcc || '—' }} &middot; {{ tex.channel_type || '—' }}
                </div>
                <div class="flex gap-1">
                  <span
                    v-if="tex.is_shared"
                    class="rounded-full bg-purple-900/30 px-1.5 py-0.5 text-[9px] text-purple-300"
                  >shared</span>
                  <span
                    v-if="tex.is_local"
                    class="rounded-full bg-teal-900/30 px-1.5 py-0.5 text-[9px] text-teal-300"
                  >local</span>
                </div>
              </div>
            </div>
          </template>

          <!-- Placements -->
          <template v-else-if="activeTab === 'placements'">
            <div v-if="!placements.length" class="py-6 text-center text-xs text-gray-600">No placements found</div>
            <template v-else>
              <div class="overflow-x-auto">
                <table class="w-full border-collapse text-xs">
                  <thead>
                    <tr>
                      <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Entity</th>
                      <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-right text-[10px] font-semibold uppercase tracking-wider text-gray-500">X</th>
                      <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-right text-[10px] font-semibold uppercase tracking-wider text-gray-500">Y</th>
                      <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-right text-[10px] font-semibold uppercase tracking-wider text-gray-500">Z</th>
                      <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-right text-[10px] font-semibold uppercase tracking-wider text-gray-500">Rot Y°</th>
                      <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">VZ Source</th>
                      <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-center text-[10px] font-semibold uppercase tracking-wider text-gray-500">Visible</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr
                      v-for="(pl, i) in placements"
                      :key="i"
                      class="border-b border-gray-800/50 transition-colors hover:bg-gray-800/40"
                    >
                      <td class="max-w-[180px] truncate px-3 py-1.5 text-gray-300" :title="pl.entity_name">{{ pl.entity_name || '—' }}</td>
                      <td class="px-3 py-1.5 text-right font-mono text-gray-400">{{ fmtCoord(pl.pos_x) }}</td>
                      <td class="px-3 py-1.5 text-right font-mono text-gray-400">{{ fmtCoord(pl.pos_y) }}</td>
                      <td class="px-3 py-1.5 text-right font-mono text-gray-400">{{ fmtCoord(pl.pos_z) }}</td>
                      <td class="px-3 py-1.5 text-right font-mono text-gray-400">{{ fmtCoord(pl.rotation_y_deg) }}</td>
                      <td class="max-w-[140px] truncate px-3 py-1.5 text-gray-500" :title="pl.vz_state_source">{{ pl.vz_state_source || '—' }}</td>
                      <td class="px-3 py-1.5 text-center">
                        <span
                          class="inline-block h-2 w-2 rounded-full"
                          :class="pl.visibility_default ? 'bg-green-500' : 'bg-gray-600'"
                        />
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <!-- Placement pagination -->
              <div v-if="placementMeta.total_pages > 1" class="mt-3 flex items-center justify-center gap-2 border-t border-gray-800 pt-3">
                <button
                  class="rounded border border-gray-700 px-3 py-1 text-xs text-gray-400 hover:bg-gray-800 disabled:opacity-30"
                  :disabled="placementPage <= 1"
                  @click="placementPage--; fetchTabData('placements')"
                >← Prev</button>
                <span class="text-xs text-gray-500">
                  Page {{ placementPage }} / {{ placementMeta.total_pages }}
                  ({{ placementMeta.total }} total)
                </span>
                <button
                  class="rounded border border-gray-700 px-3 py-1 text-xs text-gray-400 hover:bg-gray-800 disabled:opacity-30"
                  :disabled="placementPage >= placementMeta.total_pages"
                  @click="placementPage++; fetchTabData('placements')"
                >Next →</button>
              </div>
            </template>
          </template>

          <!-- Variants -->
          <template v-else-if="activeTab === 'variants'">
            <div v-if="!variants.group && !variants.siblings?.length" class="py-6 text-center text-xs text-gray-600">No variant data</div>
            <template v-else>
              <div v-if="variants.group" class="mb-3 text-xs text-gray-400">
                Variant group: <span class="font-medium text-gray-300">{{ variants.group.base_asset_id || variants.group.id }}</span>
                &middot; {{ variants.group.member_count || variants.siblings?.length || 0 }} member(s)
              </div>
              <div class="overflow-x-auto">
                <table class="w-full border-collapse text-xs">
                  <thead>
                    <tr>
                      <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Stem</th>
                      <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">P-Level</th>
                      <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Q-Level</th>
                      <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Variant</th>
                      <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-center text-[10px] font-semibold uppercase tracking-wider text-gray-500">Geometry</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr
                      v-for="sib in variants.siblings"
                      :key="sib.block_id"
                      class="border-b border-gray-800/50 transition-colors hover:bg-gray-800/40"
                      :class="sib.block_id === block.id ? 'bg-blue-900/20' : ''"
                    >
                      <td class="px-3 py-1.5">
                        <router-link
                          v-if="sib.block_id !== block.id"
                          :to="`/blocks/${sib.block_id}`"
                          class="text-blue-400 hover:text-blue-300"
                        >{{ sib.stem }}</router-link>
                        <span v-else class="font-medium text-gray-200">{{ sib.stem }} (current)</span>
                      </td>
                      <td class="px-3 py-1.5 text-gray-400">{{ sib.p_level ?? '—' }}</td>
                      <td class="px-3 py-1.5 text-gray-400">{{ sib.q_level ?? '—' }}</td>
                      <td class="px-3 py-1.5 text-gray-400">{{ sib.variant_type || '—' }}</td>
                      <td class="px-3 py-1.5 text-center">
                        <span
                          class="inline-block h-2 w-2 rounded-full"
                          :class="sib.has_geometry ? 'bg-green-500' : 'bg-gray-600'"
                        />
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </template>
          </template>

          <!-- Havok -->
          <template v-else-if="activeTab === 'havok'">
            <div v-if="!havokSlices.length" class="py-6 text-center text-xs text-gray-600">No havok data</div>
            <div v-else class="overflow-x-auto">
              <table class="w-full border-collapse text-xs">
                <thead>
                  <tr>
                    <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Slice</th>
                    <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-right text-[10px] font-semibold uppercase tracking-wider text-gray-500">Offset</th>
                    <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-right text-[10px] font-semibold uppercase tracking-wider text-gray-500">Size</th>
                    <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Version</th>
                    <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-center text-[10px] font-semibold uppercase tracking-wider text-gray-500">Convex Hull</th>
                  </tr>
                </thead>
                <tbody>
                  <tr
                    v-for="h in havokSlices"
                    :key="h.slice_index"
                    class="border-b border-gray-800/50 transition-colors hover:bg-gray-800/40"
                  >
                    <td class="px-3 py-1.5 text-gray-300">{{ h.slice_index }}</td>
                    <td class="px-3 py-1.5 text-right font-mono text-gray-400">0x{{ (h.file_offset ?? 0).toString(16).toUpperCase() }}</td>
                    <td class="px-3 py-1.5 text-right text-gray-400">{{ formatBytes(h.size_written) }}</td>
                    <td class="px-3 py-1.5 text-gray-400">{{ h.havok_version || '—' }}</td>
                    <td class="px-3 py-1.5 text-center">
                      <span
                        class="inline-block h-2 w-2 rounded-full"
                        :class="h.has_convex_hull ? 'bg-green-500' : 'bg-gray-600'"
                      />
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </template>

          <!-- Dialog -->
          <template v-else-if="activeTab === 'dialog'">
            <div v-if="!dialogFragments.length" class="py-6 text-center text-xs text-gray-600">No dialog fragments</div>
            <div v-else class="overflow-x-auto">
              <table class="w-full border-collapse text-xs">
                <thead>
                  <tr>
                    <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Type</th>
                    <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Value</th>
                    <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Namespace</th>
                    <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-center text-[10px] font-semibold uppercase tracking-wider text-gray-500">Mission</th>
                    <th class="sticky top-0 border-b border-gray-800 bg-gray-900 px-3 py-2 text-center text-[10px] font-semibold uppercase tracking-wider text-gray-500">L10n</th>
                  </tr>
                </thead>
                <tbody>
                  <tr
                    v-for="(d, i) in dialogFragments"
                    :key="i"
                    class="border-b border-gray-800/50 transition-colors hover:bg-gray-800/40"
                  >
                    <td class="px-3 py-1.5 text-gray-300">{{ d.fragment_type || '—' }}</td>
                    <td class="max-w-[300px] truncate px-3 py-1.5 text-gray-300" :title="d.value">{{ d.value || '—' }}</td>
                    <td class="px-3 py-1.5 text-gray-400">{{ d.namespace || '—' }}</td>
                    <td class="px-3 py-1.5 text-center">
                      <span class="inline-block h-2 w-2 rounded-full" :class="d.is_mission_ref ? 'bg-amber-500' : 'bg-gray-600'" />
                    </td>
                    <td class="px-3 py-1.5 text-center">
                      <span class="inline-block h-2 w-2 rounded-full" :class="d.is_localization ? 'bg-blue-500' : 'bg-gray-600'" />
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </template>

          <!-- Raw JSON -->
          <template v-else-if="activeTab === 'raw'">
            <div class="space-y-3">
              <CollapsibleJson title="Tag Occurrences" :data="block.tag_occurrences" />
              <CollapsibleJson title="Strings Sample" :data="block.strings_sample" />
              <CollapsibleJson title="UCFX Offsets" :data="block.ucfx_offsets" />
              <CollapsibleJson title="Raw UCFX JSON" :data="block.raw_ucfx_json" />
            </div>
          </template>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount, watch, nextTick } from 'vue'
import { useRoute } from 'vue-router'
import { initThreeViewer, disposeThreeViewer } from '../lib/three-viewer.js'

const route = useRoute()

const loading = ref(true)
const error = ref(null)
const block = ref(null)
const meshMeta = ref(null)

const activeTab = ref('submeshes')
const tabLoading = ref(false)
const tabError = ref(null)

const submeshes = ref([])
const textures = ref([])
const placements = ref([])
const placementPage = ref(1)
const placementMeta = ref({ total: 0, total_pages: 1 })
const variants = ref({ group: null, siblings: [] })
const havokSlices = ref([])
const dialogFragments = ref([])

const viewerContainer = ref(null)
let viewer = null
const tabDataLoaded = new Set()

const allTabs = [
  { key: 'submeshes', label: 'Submeshes', always: true },
  { key: 'textures', label: 'Textures', always: true },
  { key: 'placements', label: 'Placements', always: true },
  { key: 'variants', label: 'Variants', always: true },
  { key: 'havok', label: 'Havok', field: 'has_havok' },
  { key: 'dialog', label: 'Dialog', field: 'has_dialog' },
  { key: 'raw', label: 'Raw JSON', always: true },
]

const visibleTabs = computed(() => {
  if (!block.value) return []
  return allTabs.filter(t => t.always || block.value[t.field])
})

const glbUrl = computed(() => {
  if (!block.value) return null
  return block.value.glb_path || block.value.gltf_path || null
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
  other: 'border-gray-700/50 bg-gray-800/30 text-gray-400',
}

function categoryBadgeClass(cat) {
  return categoryColors[cat] || categoryColors.other
}

function reviewStatusClass(status) {
  const s = (status || '').toLowerCase()
  if (s === 'complete' || s === 'reviewed') return 'bg-green-900/40 text-green-300'
  if (s === 'partial') return 'bg-yellow-900/40 text-yellow-300'
  if (s === 'pending' || s === 'new') return 'bg-blue-900/40 text-blue-300'
  if (s === 'error' || s === 'failed') return 'bg-red-900/40 text-red-300'
  return 'bg-gray-800 text-gray-400'
}

function formatBytes(bytes) {
  if (bytes == null) return '—'
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(2)} MB`
}

function fmtCoord(v) {
  if (v == null) return '—'
  return Number(v).toFixed(2)
}

async function fetchBlock() {
  loading.value = true
  error.value = null
  try {
    const res = await fetch(`/api/blocks/${route.params.id}`)
    if (!res.ok) throw new Error(`${res.status} ${res.statusText}`)
    block.value = await res.json()
  } catch (e) {
    error.value = `Failed to load block: ${e.message}`
  } finally {
    loading.value = false
  }
}

async function fetchMeshMeta() {
  if (!block.value?.has_geometry) return
  try {
    const res = await fetch(`/api/blocks/${route.params.id}/mesh-meta`)
    if (res.ok) meshMeta.value = await res.json()
  } catch { /* non-critical */ }
}

async function fetchTabData(tab) {
  if (tab === 'raw') return
  if (tab !== 'placements' && tabDataLoaded.has(tab)) return

  tabLoading.value = true
  tabError.value = null
  try {
    const id = route.params.id
    let res, data

    switch (tab) {
      case 'submeshes':
        res = await fetch(`/api/blocks/${id}/submeshes`)
        if (!res.ok) throw new Error(`${res.status}`)
        submeshes.value = await res.json()
        break

      case 'textures':
        res = await fetch(`/api/blocks/${id}/textures`)
        if (!res.ok) throw new Error(`${res.status}`)
        textures.value = await res.json()
        break

      case 'placements': {
        const plOffset = (placementPage.value - 1) * 50
        res = await fetch(`/api/blocks/${id}/placements?offset=${plOffset}&limit=50`)
        if (!res.ok) throw new Error(`${res.status}`)
        data = await res.json()
        placements.value = data.items || []
        if (data.total != null) {
          placementMeta.value = {
            total: data.total,
            total_pages: Math.ceil(data.total / 50),
          }
        }
        break
      }

      case 'variants':
        res = await fetch(`/api/blocks/${id}/variants`)
        if (!res.ok) throw new Error(`${res.status}`)
        variants.value = await res.json()
        break

      case 'havok':
        res = await fetch(`/api/blocks/${id}/havok`)
        if (!res.ok) throw new Error(`${res.status}`)
        havokSlices.value = await res.json()
        break

      case 'dialog':
        res = await fetch(`/api/blocks/${id}/dialog`)
        if (!res.ok) throw new Error(`${res.status}`)
        dialogFragments.value = await res.json()
        break
    }
    tabDataLoaded.add(tab)
  } catch (e) {
    tabError.value = `Failed to load ${tab}: ${e.message}`
  } finally {
    tabLoading.value = false
  }
}

function switchTab(key) {
  activeTab.value = key
  fetchTabData(key)
}

async function initViewer() {
  if (!glbUrl.value || !viewerContainer.value) return
  await nextTick()
  viewer = initThreeViewer(viewerContainer.value, () => {})
  viewer.loadUrls(null, glbUrl.value, null)
}

// Navigate to a different block without full remount
watch(() => route.params.id, async (newId, oldId) => {
  if (newId && newId !== oldId) {
    tabDataLoaded.clear()
    activeTab.value = 'submeshes'
    placementPage.value = 1
    submeshes.value = []
    textures.value = []
    placements.value = []
    variants.value = { group: null, siblings: [] }
    havokSlices.value = []
    dialogFragments.value = []
    meshMeta.value = null

    if (viewer) {
      disposeThreeViewer(viewer)
      viewer = null
    }

    await fetchBlock()
    await fetchMeshMeta()
    await fetchTabData('submeshes')
    await nextTick()
    await initViewer()
  }
})

onMounted(async () => {
  await fetchBlock()
  if (block.value) {
    await Promise.all([
      fetchMeshMeta(),
      fetchTabData('submeshes'),
    ])
    await nextTick()
    await initViewer()
  }
})

onBeforeUnmount(() => {
  if (viewer) {
    disposeThreeViewer(viewer)
    viewer = null
  }
})

// --- Inline sub-components ---

const InfoRow = {
  props: { label: String, value: [String, Number] },
  template: `
    <div class="flex items-baseline gap-2">
      <dt class="w-24 shrink-0 text-gray-500">{{ label }}</dt>
      <dd class="min-w-0 truncate text-gray-300">{{ value ?? '—' }}</dd>
    </div>
  `,
}

const FlagBadge = {
  props: { label: String, active: Boolean },
  template: `
    <span
      class="rounded-full px-2 py-0.5 text-[10px] font-medium"
      :class="active
        ? 'bg-green-900/30 text-green-300'
        : 'bg-gray-800 text-gray-600'"
    >{{ label }}</span>
  `,
}

const PathRow = {
  props: { label: String, value: String },
  setup(props) {
    const copied = ref(false)
    function copy() {
      if (!props.value) return
      navigator.clipboard.writeText(props.value).then(() => {
        copied.value = true
        setTimeout(() => { copied.value = false }, 1500)
      })
    }
    return { copied, copy }
  },
  template: `
    <div>
      <dt class="text-gray-500">{{ label }}</dt>
      <dd v-if="value" class="mt-0.5 flex items-center gap-1.5">
        <span class="min-w-0 truncate text-gray-300" :title="value">{{ value }}</span>
        <button
          class="shrink-0 rounded px-1.5 py-0.5 text-[10px] transition-colors"
          :class="copied ? 'bg-green-900/40 text-green-300' : 'bg-gray-800 text-gray-500 hover:text-gray-300'"
          @click="copy"
        >{{ copied ? '✓' : 'Copy' }}</button>
      </dd>
      <dd v-else class="mt-0.5 text-gray-600">—</dd>
    </div>
  `,
}

const CollapsibleJson = {
  props: { title: String, data: [Object, Array, String] },
  setup() {
    const open = ref(false)
    return { open }
  },
  template: `
    <div class="rounded border border-gray-800">
      <button
        class="flex w-full items-center gap-2 px-3 py-2 text-left text-xs font-medium text-gray-300 hover:bg-gray-800/50"
        @click="open = !open"
      >
        <span class="text-[10px] text-gray-500">{{ open ? '▼' : '▶' }}</span>
        {{ title }}
        <span v-if="!data" class="text-gray-600">(empty)</span>
      </button>
      <div v-if="open && data" class="border-t border-gray-800 p-3">
        <pre class="max-h-[400px] overflow-auto whitespace-pre-wrap text-[11px] leading-relaxed text-gray-400">{{ typeof data === 'string' ? data : JSON.stringify(data, null, 2) }}</pre>
      </div>
    </div>
  `,
}
</script>
