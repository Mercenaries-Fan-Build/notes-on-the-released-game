<template>
  <div class="flex h-full flex-col overflow-hidden">
    <div class="flex items-center gap-2 border-b border-gray-800 px-3 py-1.5">
      <span class="text-[11px] font-medium text-gray-400">{{ parts.length }} parts</span>
      <span v-if="treeRows" class="text-[10px] text-gray-600">· HIER tree</span>
    </div>

    <!-- HIER tree view: nodes nested by parent, submeshes under their node -->
    <ul v-if="treeRows" ref="listEl" class="flex-1 overflow-auto p-1">
      <li
        v-for="row in treeRows"
        :key="row.kind === 'node' ? `n${row.node}` : `p${row.idx}`"
      >
        <!-- HIER node header -->
        <div
          v-if="row.kind === 'node'"
          class="flex items-center gap-1.5 rounded px-2 py-1 text-[11px] leading-snug text-gray-300"
          :style="{ paddingLeft: row.depth * 12 + 4 + 'px' }"
        >
          <input
            type="checkbox"
            :checked="row.subtreeIdxs.some(i => visibility[i] !== false)"
            class="h-3 w-3 accent-blue-500"
            @change="toggleSubtree(row.subtreeIdxs, $event.target.checked)"
          />
          <span class="text-gray-600">▸</span>
          <span class="font-mono text-gray-500">node {{ row.node }}</span>
          <span
            class="rounded px-1 py-0.5 text-[10px] font-semibold leading-none"
            :class="categoryClass(row.state)"
          >{{ row.state }}</span>
          <span v-if="row.switchGroup != null" class="rounded bg-gray-800 px-1 py-0.5 text-[10px] leading-none text-gray-400">
            sw{{ row.switchGroup }}
          </span>
          <span class="ml-auto text-[10px] text-gray-600">{{ row.subtreeIdxs.length }}</span>
        </div>

        <!-- submesh under a node -->
        <div
          v-else
          :ref="el => { if (row.idx === selectedIndex) selectedRow = el }"
          class="flex cursor-pointer items-center gap-1.5 rounded px-2 py-1 text-[11px] leading-snug transition-colors"
          :class="row.idx === selectedIndex ? 'bg-blue-900/60 text-gray-100' : 'text-gray-300 hover:bg-gray-800'"
          :style="{ paddingLeft: row.depth * 12 + 4 + 'px' }"
          @click="$emit('select-part', row.idx)"
        >
          <input
            type="checkbox"
            :checked="visibility[row.idx] !== false"
            class="h-3 w-3 accent-blue-500"
            @click.stop
            @change="$emit('toggle-visible', row.idx, $event.target.checked)"
          />
          <span class="font-mono text-gray-500">#{{ row.idx }}</span>
          <span class="rounded px-1 py-0.5 text-[10px] font-semibold leading-none" :class="categoryClass(row.part.classification)">
            {{ row.part.classification }}
          </span>
          <span class="ml-auto whitespace-nowrap text-[10px] text-gray-500">
            {{ fmtNum(row.part.vertexCount) }}v
            <span class="text-gray-600">M{{ row.part.material_index ?? '?' }}</span>
          </span>
        </div>
      </li>
    </ul>

    <!-- flat fallback (no HIER data) -->
    <ul v-else ref="listEl" class="flex-1 overflow-auto p-1">
      <li
        v-for="(p, idx) in parts"
        :key="idx"
        :ref="el => { if (idx === selectedIndex) selectedRow = el }"
        class="flex cursor-pointer items-center gap-1.5 rounded px-2 py-1 text-[11px] leading-snug transition-colors"
        :class="idx === selectedIndex ? 'bg-blue-900/60 text-gray-100' : 'text-gray-300 hover:bg-gray-800'"
        @click="$emit('select-part', idx)"
      >
        <input
          type="checkbox"
          :checked="visibility[idx] !== false"
          class="h-3 w-3 accent-blue-500"
          @click.stop
          @change="$emit('toggle-visible', idx, $event.target.checked)"
        />
        <span class="font-mono text-gray-500">#{{ idx }}</span>
        <span class="rounded px-1 py-0.5 text-[10px] font-semibold leading-none" :class="categoryClass(p.classification)">{{ p.classification }}</span>
        <span v-if="p.lod_rank != null" class="rounded bg-gray-700 px-1 py-0.5 text-[10px] leading-none text-gray-300">L{{ p.lod_rank }}</span>
        <span v-if="p.damage_state !== 'shared'" class="rounded bg-red-900/40 px-1 py-0.5 text-[10px] leading-none text-red-300">{{ p.damage_state }}</span>
        <span class="ml-auto whitespace-nowrap text-[10px] text-gray-500">
          {{ fmtNum(p.vertexCount) }}v / {{ fmtNum(p.faceCount) }}f
          <span class="text-gray-600">M{{ p.material_index ?? '?' }}</span>
        </span>
      </li>
    </ul>
  </div>
</template>

<script setup>
import { ref, watch, computed, nextTick } from 'vue'
import { classifyPart, getDamageState } from '../../lib/submesh-inspect.js'

const props = defineProps({
  partMeta: { type: Array, default: () => [] },
  partGroups: { type: Array, default: () => [] },
  selectedIndex: { type: Number, default: -1 },
  visibility: { type: Object, default: () => ({}) },
})

const emit = defineEmits(['select-part', 'toggle-visible'])

const listEl = ref(null)
const selectedRow = ref(null)
const parts = ref([])

watch(() => props.partMeta, (meta) => {
  parts.value = meta.map((entry, idx) => {
    const group = props.partGroups[idx]
    let vertexCount = 0
    let faceCount = 0
    if (group) {
      group.traverse?.(c => {
        if (c.isMesh && c.geometry) {
          const pos = c.geometry.getAttribute('position')
          if (pos) vertexCount += pos.count
          const idxBuf = c.geometry.index
          faceCount += idxBuf ? idxBuf.count / 3 : (pos ? pos.count / 3 : 0)
        }
      })
    }
    return {
      ...entry,
      classification: classifyPart(entry),
      damage_state: getDamageState(entry),
      vertexCount,
      faceCount,
      material_index: entry.material_index,
      lod_rank: entry.lod_rank,
      hier_node_idx: entry.hier_node_idx,
      hier_parent: entry.hier_parent,
      destruction_state: entry.destruction_state,
      switch_group: entry.switch_group,
    }
  })
}, { immediate: true })

// Build a pre-order, depth-annotated flattening of the HIER node tree, with each
// submesh listed under its node. Null when no submesh carries hier_node_idx (the
// viewer then shows the flat fallback list).
const treeRows = computed(() => {
  const byNode = new Map() // node -> { node, parent, parts: [partIdx] }
  let hasHier = false
  parts.value.forEach((p, idx) => {
    const node = p.hier_node_idx
    if (node == null) return
    hasHier = true
    if (!byNode.has(node)) byNode.set(node, { node, parent: p.hier_parent ?? null, parts: [] })
    byNode.get(node).parts.push(idx)
  })
  if (!hasHier) return null

  const children = new Map()
  const roots = []
  for (const n of byNode.values()) {
    const par = n.parent != null && byNode.has(n.parent) ? n.parent : null
    if (par === null) roots.push(n.node)
    else {
      if (!children.has(par)) children.set(par, [])
      children.get(par).push(n.node)
    }
  }

  const rows = []
  const visit = (node, depth) => {
    const n = byNode.get(node)
    const header = {
      kind: 'node',
      node,
      depth,
      state: parts.value[n.parts[0]]?.destruction_state || 'static',
      switchGroup: parts.value[n.parts[0]]?.switch_group,
      subtreeIdxs: [...n.parts],
    }
    rows.push(header)
    for (const pi of n.parts) rows.push({ kind: 'part', idx: pi, depth: depth + 1, part: parts.value[pi] })
    for (const c of (children.get(node) || []).sort((a, b) => a - b)) {
      header.subtreeIdxs.push(...visit(c, depth + 1))
    }
    return header.subtreeIdxs
  }
  for (const r of roots.sort((a, b) => a - b)) visit(r, 0)
  return rows
})

function toggleSubtree(idxs, visible) {
  for (const i of idxs) emit('toggle-visible', i, visible)
}

watch(() => props.selectedIndex, async () => {
  await nextTick()
  if (selectedRow.value?.scrollIntoView) {
    selectedRow.value.scrollIntoView({ block: 'nearest', behavior: 'smooth' })
  }
})

function fmtNum(n) {
  return n == null ? '0' : n.toLocaleString()
}

const categoryColors = {
  intact: 'bg-blue-900/50 text-blue-300',
  break_piece: 'bg-red-900/50 text-red-300',
  static: 'bg-gray-700 text-gray-300',
  lod: 'bg-orange-900/50 text-orange-300',
  glass: 'bg-teal-900/50 text-teal-300',
  shell: 'bg-yellow-900/50 text-yellow-300',
  large: 'bg-indigo-900/50 text-indigo-300',
  medium: 'bg-purple-900/50 text-purple-300',
  small: 'bg-purple-900/40 text-purple-200',
  mesh: 'bg-gray-700 text-gray-400',
  other: 'bg-gray-700 text-gray-400',
}

function categoryClass(cat) {
  return categoryColors[cat] || categoryColors.other
}
</script>
