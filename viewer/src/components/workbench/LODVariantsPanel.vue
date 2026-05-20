<template>
  <div class="flex h-full flex-col overflow-hidden">
    <div class="flex items-center gap-2 border-b border-gray-800 px-3 py-1.5">
      <span class="text-[11px] font-medium text-gray-400">LOD / Variants</span>
    </div>

    <div class="flex-1 overflow-auto p-2 space-y-3">
      <!-- LOD Control -->
      <div class="space-y-1.5">
        <div class="flex items-center justify-between">
          <label class="text-[10px] uppercase tracking-wide text-gray-500">LOD Rank</label>
          <span class="rounded bg-gray-800 px-1.5 py-0.5 text-[10px] font-mono text-gray-300">
            L{{ currentLod ?? '?' }}{{ autoLod ? ' auto' : '' }}
          </span>
        </div>

        <div class="flex items-center gap-2">
          <input
            type="range"
            :min="0"
            :max="maxRank"
            :value="currentLod ?? 0"
            :disabled="autoLod"
            class="h-1 flex-1 appearance-none rounded bg-gray-700 accent-blue-500 disabled:opacity-40"
            @input="onLodSliderChange"
          />
          <span class="w-6 text-center text-[10px] text-gray-400">{{ maxRank }}</span>
        </div>

        <div class="flex items-center gap-2">
          <input
            id="auto-lod"
            v-model="autoLod"
            type="checkbox"
            class="h-3 w-3 accent-blue-500"
            @change="onAutoLodChange"
          />
          <label for="auto-lod" class="text-[11px] text-gray-300 select-none">Auto LOD</label>
        </div>

        <button
          class="rounded bg-gray-800 px-2 py-1 text-[11px] text-gray-300 hover:bg-gray-700"
          @click="showBestOnly"
        >Best LOD only</button>
      </div>

      <!-- Damage variant -->
      <div class="space-y-1.5">
        <label class="block text-[10px] uppercase tracking-wide text-gray-500">Damage Variant</label>
        <div class="flex gap-1">
          <button
            v-for="opt in damageOptions"
            :key="opt.value"
            class="rounded px-2 py-1 text-[11px] transition-colors"
            :class="damageMode === opt.value
              ? 'bg-blue-700 text-white'
              : 'bg-gray-800 text-gray-300 hover:bg-gray-700'"
            @click="setDamageMode(opt.value)"
          >{{ opt.label }}</button>
        </div>
      </div>

      <!-- Category filter presets -->
      <div class="space-y-1.5">
        <label class="block text-[10px] uppercase tracking-wide text-gray-500">Category Filter</label>
        <div class="flex flex-wrap gap-1">
          <button
            class="rounded px-2 py-1 text-[11px] bg-gray-800 text-gray-300 hover:bg-gray-700"
            @click="showAll"
          >Show All</button>
          <button
            class="rounded px-2 py-1 text-[11px] bg-gray-800 text-gray-300 hover:bg-gray-700"
            @click="hideAll"
          >Hide All</button>
        </div>
        <div class="flex flex-wrap gap-1">
          <button
            v-for="cat in categories"
            :key="cat"
            class="rounded px-2 py-1 text-[11px] transition-colors"
            :class="isolatedCategory === cat
              ? 'bg-blue-700 text-white'
              : 'bg-gray-800 text-gray-300 hover:bg-gray-700'"
            @click="toggleCategory(cat)"
          >{{ formatCategory(cat) }}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { lodGroupMaxRank, classifyPart } from '../../lib/submesh-inspect.js'

const props = defineProps({
  viewer: { type: Object, default: null },
  partMeta: { type: Array, default: () => [] },
  partGroups: { type: Array, default: () => [] },
})

const autoLod = ref(false)
const currentLod = ref(0)
const damageMode = ref('both')
const isolatedCategory = ref(null)

const damageOptions = [
  { value: 'intact', label: 'Intact' },
  { value: 'damaged', label: 'Damaged' },
  { value: 'both', label: 'Both' },
]

const maxRank = computed(() => {
  const ranks = lodGroupMaxRank(props.partMeta)
  let max = 0
  for (const g in ranks) {
    if (ranks[g] > max) max = ranks[g]
  }
  return max
})

const categories = computed(() => {
  const set = new Set()
  for (const entry of props.partMeta) {
    if (entry) set.add(classifyPart(entry))
  }
  return [...set].sort()
})

watch(() => props.partMeta, () => {
  currentLod.value = 0
  autoLod.value = false
  damageMode.value = 'both'
  isolatedCategory.value = null
})

function onLodSliderChange(e) {
  const rank = parseInt(e.target.value)
  currentLod.value = rank
  props.viewer?.applyLodFilter?.(rank)
}

function onAutoLodChange() {
  if (autoLod.value) {
    props.viewer?.applyLodFilter?.('best')
    currentLod.value = maxRank.value
  } else {
    props.viewer?.applyLodFilter?.(currentLod.value)
  }
}

function showBestOnly() {
  autoLod.value = false
  currentLod.value = maxRank.value
  props.viewer?.applyLodFilter?.('best')
}

function setDamageMode(mode) {
  damageMode.value = mode
  const preferDamaged = mode === 'damaged'
  const showBoth = mode === 'both'
  props.viewer?.applyDamageFilter?.(preferDamaged, showBoth)
}

function showAll() {
  isolatedCategory.value = null
  props.viewer?.setAllPartsVisible?.(true)
}

function hideAll() {
  isolatedCategory.value = null
  props.viewer?.setAllPartsVisible?.(false)
}

function toggleCategory(cat) {
  if (isolatedCategory.value === cat) {
    isolatedCategory.value = null
    props.viewer?.setAllPartsVisible?.(true)
  } else {
    isolatedCategory.value = cat
    props.viewer?.isolateCategory?.(cat)
  }
}

function formatCategory(cat) {
  return cat.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
}
</script>
