<template>
  <div class="flex h-full flex-col">
    <!-- Filter Bar -->
    <div class="flex flex-wrap items-center gap-2 border-b border-gray-800 bg-gray-900 px-4 py-2">
      <h1 class="mr-2 text-sm font-semibold text-gray-100">Review Queue</h1>

      <select
        v-model="filters.review_status"
        class="rounded border border-gray-700 bg-gray-800 px-2 py-1 text-xs text-gray-200"
      >
        <option value="">All statuses</option>
        <option v-for="s in REVIEW_STATUSES" :key="s" :value="s">{{ formatStatus(s) }}</option>
      </select>

      <select
        v-model="filters.block_type"
        class="rounded border border-gray-700 bg-gray-800 px-2 py-1 text-xs text-gray-200"
      >
        <option value="">All block types</option>
        <option v-for="bt in blockTypes" :key="bt.block_type" :value="bt.block_type">
          {{ bt.block_type }} ({{ bt.count }})
        </option>
      </select>

      <select
        v-model="filters.category_id"
        class="rounded border border-gray-700 bg-gray-800 px-2 py-1 text-xs text-gray-200"
      >
        <option value="">All categories</option>
        <option v-for="c in categories" :key="c.id" :value="c.id">{{ c.name }}</option>
      </select>

      <label class="flex items-center gap-1.5 text-xs text-gray-400">
        <input
          type="checkbox"
          v-model="filters.has_geometry"
          class="rounded border-gray-600 bg-gray-800 text-blue-500 focus:ring-blue-600"
          :indeterminate="filters.has_geometry === null"
          @click="cycleGeometryFilter"
        />
        Has Geometry
      </label>

      <div class="relative min-w-[180px] flex-1">
        <input
          v-model="filters.search"
          type="text"
          placeholder="Search block name…"
          class="w-full rounded border border-gray-700 bg-gray-800 px-3 py-1.5 pr-8 text-xs text-gray-200 placeholder-gray-500"
          @keydown.enter="applyFilters"
        />
        <button
          v-if="filters.search"
          class="absolute right-2 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-300"
          @click="filters.search = ''; applyFilters()"
        >&times;</button>
      </div>

      <button
        class="rounded bg-blue-700 px-3 py-1.5 text-xs font-medium text-white transition-colors hover:bg-blue-600"
        @click="applyFilters"
      >
        Apply Filters
      </button>
    </div>

    <!-- Bulk Actions Bar -->
    <div class="flex items-center gap-3 border-b border-gray-800 bg-gray-900/70 px-4 py-1.5">
      <label class="flex items-center gap-1.5 text-xs text-gray-400">
        <input
          type="checkbox"
          :checked="allOnPageSelected"
          :indeterminate="someOnPageSelected && !allOnPageSelected"
          class="rounded border-gray-600 bg-gray-800 text-blue-500 focus:ring-blue-600"
          @change="toggleSelectAllOnPage"
        />
        Select All on Page
      </label>

      <span v-if="selectedIds.size" class="text-xs text-gray-300">
        {{ selectedIds.size }} selected
      </span>

      <template v-if="selectedIds.size">
        <select
          v-model="bulkStatus"
          class="rounded border border-gray-700 bg-gray-800 px-2 py-1 text-xs text-gray-200"
        >
          <option value="">Set Review Status…</option>
          <option v-for="s in REVIEW_STATUSES" :key="s" :value="s">{{ formatStatus(s) }}</option>
        </select>

        <select
          v-model="bulkCategoryId"
          class="rounded border border-gray-700 bg-gray-800 px-2 py-1 text-xs text-gray-200"
        >
          <option value="">Set Category…</option>
          <option v-for="c in categories" :key="c.id" :value="c.id">{{ c.name }}</option>
        </select>

        <button
          class="rounded bg-amber-700 px-3 py-1 text-xs font-medium text-white transition-colors hover:bg-amber-600 disabled:opacity-40"
          :disabled="!bulkStatus && !bulkCategoryId || bulkApplying"
          @click="applyBulk"
        >
          {{ bulkApplying ? 'Applying…' : 'Apply to Selected' }}
        </button>
      </template>
    </div>

    <!-- Main content: table + optional sidebar -->
    <div class="flex flex-1 overflow-hidden">
      <!-- Block Table -->
      <div class="flex-1 overflow-auto">
        <!-- Loading -->
        <div v-if="loading" class="py-16 text-center text-sm text-gray-500">Loading blocks…</div>

        <!-- Error -->
        <div v-else-if="error" class="m-4 rounded-lg border border-red-800 bg-red-900/20 p-4 text-sm text-red-300">
          {{ error }}
        </div>

        <!-- Empty -->
        <div v-else-if="!blocks.length" class="py-16 text-center text-sm text-gray-500">
          No blocks match the current filters.
        </div>

        <!-- Table -->
        <table v-else class="w-full border-collapse text-xs">
          <thead>
            <tr>
              <th class="sticky top-0 z-10 w-8 border-b border-gray-800 bg-gray-900 px-2 py-2"></th>
              <th
                v-for="col in TABLE_COLUMNS"
                :key="col.key"
                class="sticky top-0 z-10 cursor-pointer border-b border-gray-800 bg-gray-900 px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500"
                @click="toggleSort(col.key)"
              >
                {{ col.label }}
                <span v-if="sortKey === col.key" class="ml-0.5">{{ sortAsc ? '▲' : '▼' }}</span>
              </th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="block in blocks"
              :key="block.id"
              class="border-b border-gray-800/50 transition-colors hover:bg-gray-800/40"
              :class="{ 'bg-gray-800/30': selectedBlock?.id === block.id }"
              @click="selectBlock(block)"
            >
              <td class="px-2 py-1.5 text-center" @click.stop>
                <input
                  type="checkbox"
                  :checked="selectedIds.has(block.id)"
                  class="rounded border-gray-600 bg-gray-800 text-blue-500 focus:ring-blue-600"
                  @change="toggleSelect(block.id)"
                />
              </td>
              <td class="px-3 py-1.5 font-mono text-gray-500">{{ block.id }}</td>
              <td class="max-w-[220px] truncate px-3 py-1.5">
                <router-link
                  :to="'/blocks/' + block.id"
                  class="font-medium text-gray-200 hover:text-blue-300"
                  :title="block.stem"
                  @click.stop
                >
                  {{ truncate(block.stem, 40) }}
                </router-link>
              </td>
              <td class="max-w-[180px] truncate px-3 py-1.5 text-gray-400">{{ block.canonical_name || '—' }}</td>
              <td class="px-3 py-1.5 text-gray-400">{{ block.block_type || '—' }}</td>
              <td class="px-3 py-1.5 text-gray-400">{{ categoryName(block.category_id) }}</td>
              <td class="px-3 py-1.5">
                <span
                  class="inline-block rounded-full px-2 py-0.5 text-[10px] font-medium"
                  :class="statusBadgeClass(block.review_status)"
                >
                  {{ formatStatus(block.review_status) }}
                </span>
              </td>
              <td class="px-3 py-1.5 text-center">
                <span v-if="block.has_geometry" class="text-green-400">●</span>
                <span v-else class="text-gray-700">○</span>
              </td>
              <td class="px-3 py-1.5 text-center">
                <span v-if="block.has_textures" class="text-purple-400">●</span>
                <span v-else class="text-gray-700">○</span>
              </td>
              <td class="px-3 py-1.5 text-right font-mono text-gray-500">{{ formatBytes(block.file_size_bytes) }}</td>
              <td class="px-3 py-1.5 text-gray-500">{{ formatDate(block.updated_at) }}</td>
            </tr>
          </tbody>
        </table>

        <!-- Pagination -->
        <div class="flex items-center justify-between border-t border-gray-800 px-4 py-2">
          <div class="flex items-center gap-2">
            <span class="text-xs text-gray-500">{{ total }} total</span>
            <select
              v-model.number="pageSize"
              class="rounded border border-gray-700 bg-gray-800 px-2 py-1 text-xs text-gray-200"
              @change="applyFilters"
            >
              <option :value="25">25 / page</option>
              <option :value="50">50 / page</option>
              <option :value="100">100 / page</option>
            </select>
          </div>
          <div class="flex items-center gap-2">
            <button
              class="rounded border border-gray-700 px-3 py-1 text-xs text-gray-400 hover:bg-gray-800 disabled:opacity-30"
              :disabled="offset <= 0"
              @click="prevPage"
            >
              ← Prev
            </button>
            <span class="text-xs text-gray-500">
              Page {{ currentPage }} / {{ totalPages }}
            </span>
            <button
              class="rounded border border-gray-700 px-3 py-1 text-xs text-gray-400 hover:bg-gray-800 disabled:opacity-30"
              :disabled="offset + pageSize >= total"
              @click="nextPage"
            >
              Next →
            </button>
          </div>
        </div>
      </div>

      <!-- Quick Edit Sidebar -->
      <transition name="slide">
        <div
          v-if="selectedBlock"
          class="w-[360px] shrink-0 overflow-y-auto border-l border-gray-800 bg-gray-900 p-4"
        >
          <div class="mb-4 flex items-center justify-between">
            <h2 class="text-sm font-semibold text-gray-100">Quick Edit</h2>
            <button
              class="text-gray-500 hover:text-gray-300"
              @click="selectedBlock = null"
            >&times;</button>
          </div>

          <!-- Read-only info -->
          <div class="mb-4 space-y-2">
            <div>
              <span class="text-[10px] uppercase tracking-wider text-gray-500">Stem</span>
              <p class="break-all text-xs text-gray-300">{{ selectedBlock.stem }}</p>
            </div>
            <div>
              <span class="text-[10px] uppercase tracking-wider text-gray-500">Canonical Name</span>
              <p class="text-xs text-gray-300">{{ selectedBlock.canonical_name || '—' }}</p>
            </div>
            <div class="flex gap-4">
              <div>
                <span class="text-[10px] uppercase tracking-wider text-gray-500">Variant</span>
                <p class="text-xs text-gray-300">{{ selectedBlock.variant_type || '—' }}</p>
              </div>
              <div>
                <span class="text-[10px] uppercase tracking-wider text-gray-500">Faction</span>
                <p class="text-xs text-gray-300">{{ selectedBlock.faction_hint || '—' }}</p>
              </div>
              <div>
                <span class="text-[10px] uppercase tracking-wider text-gray-500">Region</span>
                <p class="text-xs text-gray-300">{{ selectedBlock.region_hint || '—' }}</p>
              </div>
            </div>
          </div>

          <!-- Editable fields -->
          <div class="space-y-3">
            <div>
              <label class="mb-1 block text-[10px] uppercase tracking-wider text-gray-500">Review Status</label>
              <select
                v-model="editForm.review_status"
                class="w-full rounded border border-gray-700 bg-gray-800 px-2 py-1.5 text-xs text-gray-200"
              >
                <option v-for="s in REVIEW_STATUSES" :key="s" :value="s">{{ formatStatus(s) }}</option>
              </select>
            </div>

            <div>
              <label class="mb-1 block text-[10px] uppercase tracking-wider text-gray-500">Category</label>
              <select
                v-model="editForm.category_id"
                class="w-full rounded border border-gray-700 bg-gray-800 px-2 py-1.5 text-xs text-gray-200"
              >
                <option :value="null">None</option>
                <option v-for="c in categories" :key="c.id" :value="c.id">{{ c.name }}</option>
              </select>
            </div>

            <div>
              <label class="mb-1 block text-[10px] uppercase tracking-wider text-gray-500">Review Notes</label>
              <textarea
                v-model="editForm.review_notes"
                rows="3"
                class="w-full rounded border border-gray-700 bg-gray-800 px-2 py-1.5 text-xs text-gray-200 placeholder-gray-500"
                placeholder="Add review notes…"
              ></textarea>
            </div>

            <!-- Tags -->
            <div>
              <label class="mb-1 block text-[10px] uppercase tracking-wider text-gray-500">Tags</label>
              <div class="mb-2 flex flex-wrap gap-1">
                <span
                  v-for="tag in blockTags"
                  :key="tag.id"
                  class="flex items-center gap-1 rounded-full bg-gray-800 px-2 py-0.5 text-[10px] text-gray-300"
                >
                  {{ tag.name }}
                  <button
                    class="text-gray-500 hover:text-red-400"
                    @click="removeTag(tag.id)"
                  >&times;</button>
                </span>
                <span v-if="!blockTags.length" class="text-[10px] text-gray-600">No tags</span>
              </div>
              <div class="relative">
                <input
                  v-model="tagSearch"
                  type="text"
                  placeholder="Add tag…"
                  class="w-full rounded border border-gray-700 bg-gray-800 px-2 py-1.5 text-xs text-gray-200 placeholder-gray-500"
                  @focus="showTagDropdown = true"
                  @keydown.enter.prevent="addTagFromInput"
                  @keydown.escape="showTagDropdown = false"
                />
                <div
                  v-if="showTagDropdown && filteredTags.length"
                  class="absolute left-0 top-full z-20 mt-1 max-h-40 w-full overflow-auto rounded border border-gray-700 bg-gray-800 shadow-lg"
                >
                  <button
                    v-for="tag in filteredTags"
                    :key="tag.id"
                    class="block w-full px-3 py-1.5 text-left text-xs text-gray-300 transition-colors hover:bg-gray-700"
                    @mousedown.prevent="addExistingTag(tag)"
                  >
                    {{ tag.name }}
                  </button>
                </div>
              </div>
            </div>

            <div class="flex gap-2 pt-2">
              <button
                class="flex-1 rounded bg-blue-700 px-3 py-1.5 text-xs font-medium text-white transition-colors hover:bg-blue-600 disabled:opacity-40"
                :disabled="saving"
                @click="saveEdit"
              >
                {{ saving ? 'Saving…' : 'Save' }}
              </button>
              <router-link
                :to="'/blocks/' + selectedBlock.id"
                class="rounded border border-gray-700 px-3 py-1.5 text-xs text-gray-400 transition-colors hover:bg-gray-800 hover:text-gray-200"
              >
                Full Detail →
              </router-link>
            </div>

            <div v-if="saveError" class="rounded border border-red-800 bg-red-900/20 px-3 py-2 text-xs text-red-300">
              {{ saveError }}
            </div>
            <div v-if="saveSuccess" class="rounded border border-green-800 bg-green-900/20 px-3 py-2 text-xs text-green-300">
              Saved successfully.
            </div>
          </div>
        </div>
      </transition>
    </div>

    <!-- Statistics Bar -->
    <div class="flex items-center gap-4 border-t border-gray-800 bg-gray-900 px-4 py-2">
      <span class="text-[10px] uppercase tracking-wider text-gray-500">Status Distribution</span>
      <div class="flex flex-wrap gap-2">
        <span
          v-for="stat in statusStats"
          :key="stat.status"
          class="flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-medium"
          :class="statusBadgeClass(stat.status)"
        >
          {{ formatStatus(stat.status) }}
          <span class="font-bold">{{ stat.count }}</span>
        </span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, watch } from 'vue'

const REVIEW_STATUSES = [
  'unreviewed', 'auto_classified', 'needs_review', 'in_progress',
  'reviewed', 'approved', 'flagged', 'rejected',
]

const TABLE_COLUMNS = [
  { key: 'id', label: 'ID' },
  { key: 'stem', label: 'Stem' },
  { key: 'canonical_name', label: 'Canonical Name' },
  { key: 'block_type', label: 'Type' },
  { key: 'category_id', label: 'Category' },
  { key: 'review_status', label: 'Status' },
  { key: 'has_geometry', label: 'Geo' },
  { key: 'has_textures', label: 'Tex' },
  { key: 'file_size_bytes', label: 'Size' },
  { key: 'updated_at', label: 'Updated' },
]

const STATUS_BADGE_CLASSES = {
  unreviewed: 'bg-gray-600/40 text-gray-300',
  auto_classified: 'bg-blue-700/40 text-blue-300',
  needs_review: 'bg-yellow-700/40 text-yellow-300',
  in_progress: 'bg-purple-700/40 text-purple-300',
  reviewed: 'bg-green-700/40 text-green-300',
  approved: 'bg-emerald-700/40 text-emerald-300',
  flagged: 'bg-red-700/40 text-red-300',
  rejected: 'bg-red-900/40 text-red-400',
}

const loading = ref(false)
const error = ref('')
const blocks = ref([])
const total = ref(0)
const offset = ref(0)
const pageSize = ref(50)
const sortKey = ref('id')
const sortAsc = ref(true)

const filters = reactive({
  review_status: '',
  block_type: '',
  category_id: '',
  has_geometry: null,
  search: '',
})

const geometryStates = [null, true, false]
let geometryIndex = 0

function cycleGeometryFilter(e) {
  e.preventDefault()
  geometryIndex = (geometryIndex + 1) % geometryStates.length
  filters.has_geometry = geometryStates[geometryIndex]
}

const blockTypes = ref([])
const categories = ref([])
const allTags = ref([])

const selectedIds = ref(new Set())
const bulkStatus = ref('')
const bulkCategoryId = ref('')
const bulkApplying = ref(false)

const selectedBlock = ref(null)
const editForm = reactive({
  review_status: 'unreviewed',
  category_id: null,
  review_notes: '',
})
const blockTags = ref([])
const tagSearch = ref('')
const showTagDropdown = ref(false)
const saving = ref(false)
const saveError = ref('')
const saveSuccess = ref(false)

const statusStats = ref([])

const currentPage = computed(() => Math.floor(offset.value / pageSize.value) + 1)
const totalPages = computed(() => Math.max(1, Math.ceil(total.value / pageSize.value)))

const allOnPageSelected = computed(() =>
  blocks.value.length > 0 && blocks.value.every(b => selectedIds.value.has(b.id))
)
const someOnPageSelected = computed(() =>
  blocks.value.some(b => selectedIds.value.has(b.id))
)

const filteredTags = computed(() => {
  const q = tagSearch.value.toLowerCase()
  const currentIds = new Set(blockTags.value.map(t => t.id))
  return allTags.value.filter(t => !currentIds.has(t.id) && t.name.toLowerCase().includes(q))
})

const categoryMap = computed(() => {
  const m = {}
  for (const c of categories.value) m[c.id] = c.name
  return m
})

function categoryName(id) {
  return id ? (categoryMap.value[id] || `#${id}`) : '—'
}

function formatStatus(s) {
  return (s || 'unreviewed').replace(/_/g, ' ')
}

function statusBadgeClass(s) {
  return STATUS_BADGE_CLASSES[s] || STATUS_BADGE_CLASSES.unreviewed
}

function truncate(s, len) {
  if (!s) return '—'
  return s.length > len ? s.slice(0, len) + '…' : s
}

function formatBytes(n) {
  if (n == null) return '—'
  if (n < 1024) return n + ' B'
  if (n < 1048576) return (n / 1024).toFixed(1) + ' KB'
  return (n / 1048576).toFixed(1) + ' MB'
}

function formatDate(d) {
  if (!d) return '—'
  try {
    return new Date(d).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: '2-digit' })
  } catch { return '—' }
}

function toggleSort(key) {
  if (sortKey.value === key) {
    sortAsc.value = !sortAsc.value
  } else {
    sortKey.value = key
    sortAsc.value = true
  }
  applyFilters()
}

function toggleSelectAllOnPage() {
  const next = new Set(selectedIds.value)
  if (allOnPageSelected.value) {
    for (const b of blocks.value) next.delete(b.id)
  } else {
    for (const b of blocks.value) next.add(b.id)
  }
  selectedIds.value = next
}

function toggleSelect(id) {
  const next = new Set(selectedIds.value)
  if (next.has(id)) next.delete(id)
  else next.add(id)
  selectedIds.value = next
}

function prevPage() {
  offset.value = Math.max(0, offset.value - pageSize.value)
  fetchBlocks()
}

function nextPage() {
  offset.value += pageSize.value
  fetchBlocks()
}

function applyFilters() {
  offset.value = 0
  fetchBlocks()
}

async function fetchBlocks() {
  loading.value = true
  error.value = ''
  try {
    const params = new URLSearchParams()
    params.set('offset', offset.value)
    params.set('limit', pageSize.value)
    if (filters.review_status) params.set('review_status', filters.review_status)
    if (filters.block_type) params.set('block_type', filters.block_type)
    if (filters.category_id) params.set('category_id', filters.category_id)
    if (filters.has_geometry === true) params.set('has_geometry', 'true')
    if (filters.has_geometry === false) params.set('has_geometry', 'false')
    if (filters.search) params.set('search', filters.search)

    const res = await fetch(`/api/blocks?${params}`)
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const data = await res.json()
    blocks.value = data.items
    total.value = data.total
  } catch (e) {
    error.value = e.message || 'Failed to fetch blocks'
  } finally {
    loading.value = false
  }
}

async function fetchBlockTypes() {
  try {
    const res = await fetch('/api/blocks/types/summary')
    if (res.ok) blockTypes.value = await res.json()
  } catch { /* non-critical */ }
}

async function fetchCategories() {
  try {
    const res = await fetch('/api/categories')
    if (res.ok) categories.value = await res.json()
  } catch { /* non-critical */ }
}

async function fetchTags() {
  try {
    const res = await fetch('/api/tags')
    if (res.ok) allTags.value = await res.json()
  } catch { /* non-critical */ }
}

async function fetchStatusStats() {
  try {
    const res = await fetch('/api/blocks/review-status/summary')
    if (!res.ok) return
    const data = await res.json()
    statusStats.value = data
      .map(d => ({ status: d.review_status, count: d.count }))
      .filter(s => s.count > 0)
  } catch { /* non-critical */ }
}

function selectBlock(block) {
  selectedBlock.value = block
  editForm.review_status = block.review_status || 'unreviewed'
  editForm.category_id = block.category_id
  editForm.review_notes = block.review_notes || ''
  saveError.value = ''
  saveSuccess.value = false
  blockTags.value = []
  fetchBlockTags(block.id)
}

async function fetchBlockTags(blockId) {
  try {
    const res = await fetch(`/api/blocks/${blockId}/tags`)
    if (res.ok) blockTags.value = await res.json()
  } catch {
    blockTags.value = []
  }
}

async function saveEdit() {
  if (!selectedBlock.value) return
  saving.value = true
  saveError.value = ''
  saveSuccess.value = false
  try {
    const body = {}
    if (editForm.review_status !== selectedBlock.value.review_status) body.review_status = editForm.review_status
    if (editForm.category_id !== selectedBlock.value.category_id) body.category_id = editForm.category_id
    if (editForm.review_notes !== (selectedBlock.value.review_notes || '')) body.review_notes = editForm.review_notes

    if (Object.keys(body).length) {
      const res = await fetch(`/api/blocks/${selectedBlock.value.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      })
      if (!res.ok) throw new Error(`HTTP ${res.status}`)
      const updated = await res.json()

      const idx = blocks.value.findIndex(b => b.id === updated.id)
      if (idx !== -1) blocks.value[idx] = updated
      selectedBlock.value = updated
    }

    saveSuccess.value = true
    setTimeout(() => { saveSuccess.value = false }, 2000)
  } catch (e) {
    saveError.value = e.message || 'Save failed'
  } finally {
    saving.value = false
  }
}

async function addExistingTag(tag) {
  showTagDropdown.value = false
  tagSearch.value = ''
  if (!selectedBlock.value) return
  try {
    const res = await fetch(`/api/blocks/${selectedBlock.value.id}/tags/${tag.id}`, {
      method: 'POST',
    })
    if (res.ok || res.status === 204 || res.status === 201) {
      blockTags.value = [...blockTags.value, tag]
    }
  } catch { /* silent */ }
}

async function addTagFromInput() {
  if (!tagSearch.value.trim()) return
  const match = filteredTags.value.find(t => t.name.toLowerCase() === tagSearch.value.trim().toLowerCase())
  if (match) {
    await addExistingTag(match)
    return
  }
  const name = tagSearch.value.trim()
  const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')
  try {
    const res = await fetch('/api/tags', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name, slug }),
    })
    if (res.ok || res.status === 201) {
      const newTag = await res.json()
      allTags.value.push(newTag)
      await addExistingTag(newTag)
    }
  } catch { /* silent */ }
  tagSearch.value = ''
}

async function removeTag(tagId) {
  if (!selectedBlock.value) return
  try {
    await fetch(`/api/blocks/${selectedBlock.value.id}/tags/${tagId}`, {
      method: 'DELETE',
    })
    blockTags.value = blockTags.value.filter(t => t.id !== tagId)
  } catch { /* silent */ }
}

async function applyBulk() {
  if (!selectedIds.value.size) return
  bulkApplying.value = true
  const body = { block_ids: [...selectedIds.value] }
  if (bulkStatus.value) body.review_status = bulkStatus.value
  if (bulkCategoryId.value) body.category_id = Number(bulkCategoryId.value)

  try {
    const res = await fetch('/api/blocks/bulk-update', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    })
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    selectedIds.value = new Set()
    bulkStatus.value = ''
    bulkCategoryId.value = ''
    await fetchBlocks()
    fetchStatusStats()
  } catch { /* best effort */ }
  finally {
    bulkApplying.value = false
  }
}

watch(() => showTagDropdown.value, (v) => {
  if (v) {
    const handler = () => { showTagDropdown.value = false }
    setTimeout(() => document.addEventListener('click', handler, { once: true }), 0)
  }
})

onMounted(() => {
  fetchBlocks()
  fetchBlockTypes()
  fetchCategories()
  fetchTags()
  fetchStatusStats()
})
</script>

<style scoped>
.slide-enter-active,
.slide-leave-active {
  transition: width 0.2s ease, opacity 0.2s ease;
}
.slide-enter-from,
.slide-leave-to {
  width: 0;
  opacity: 0;
}
</style>
