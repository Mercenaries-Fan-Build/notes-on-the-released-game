<template>
  <div class="flex h-full flex-col overflow-hidden">
    <div class="flex items-center gap-2 border-b border-gray-800 px-3 py-1.5">
      <span class="text-[11px] font-medium text-gray-400">{{ parts.length }} parts</span>
    </div>
    <ul ref="listEl" class="flex-1 overflow-auto p-1">
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
        <span
          class="rounded px-1 py-0.5 text-[10px] font-semibold leading-none"
          :class="categoryClass(p.classification)"
        >{{ p.classification }}</span>
        <span v-if="p.lod_rank != null" class="rounded bg-gray-700 px-1 py-0.5 text-[10px] leading-none text-gray-300">
          L{{ p.lod_rank }}
        </span>
        <span v-if="p.damage_state !== 'shared'" class="rounded bg-red-900/40 px-1 py-0.5 text-[10px] leading-none text-red-300">
          {{ p.damage_state }}
        </span>
        <span v-if="p.transparent" class="rounded bg-teal-900/40 px-1 py-0.5 text-[10px] leading-none text-teal-300">
          transparent
        </span>
        <span class="ml-auto whitespace-nowrap text-[10px] text-gray-500">
          {{ fmtNum(p.vertexCount) }}v / {{ fmtNum(p.faceCount) }}f
          <span class="text-gray-600">M{{ p.material_index ?? '?' }}</span>
        </span>
      </li>
    </ul>
  </div>
</template>

<script setup>
import { ref, watch, nextTick } from 'vue'
import { classifyPart, getDamageState } from '../../lib/submesh-inspect.js'

const props = defineProps({
  partMeta: { type: Array, default: () => [] },
  partGroups: { type: Array, default: () => [] },
  selectedIndex: { type: Number, default: -1 },
  visibility: { type: Object, default: () => ({}) },
})

defineEmits(['select-part', 'toggle-visible'])

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
      lod_group: entry.lod_group,
      transparent: entry.transparent,
    }
  })
}, { immediate: true })

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
  body: 'bg-blue-900/50 text-blue-300',
  wheel: 'bg-green-900/50 text-green-300',
  glass: 'bg-teal-900/50 text-teal-300',
  accessory: 'bg-purple-900/50 text-purple-300',
  vehicle_lod: 'bg-orange-900/50 text-orange-300',
  panel: 'bg-yellow-900/50 text-yellow-300',
  other: 'bg-gray-700 text-gray-400',
}

function categoryClass(cat) {
  return categoryColors[cat] || categoryColors.other
}
</script>
