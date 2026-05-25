<template>
  <div class="absolute left-1/2 top-2 z-10 flex -translate-x-1/2 items-center gap-0.5 rounded-lg border border-gray-700/50 bg-gray-900/80 px-1.5 py-1 backdrop-blur">
    <button
      v-for="dm in displayModes"
      :key="dm.value"
      :title="dm.label"
      class="rounded px-2 py-1 text-[11px] font-medium transition-colors"
      :class="currentDisplay === dm.value ? 'bg-blue-600 text-white' : 'text-gray-400 hover:bg-gray-700 hover:text-gray-200'"
      @click="$emit('display-mode', dm.value)"
    >{{ dm.label }}</button>

    <div class="mx-1 h-4 w-px bg-gray-700" />

    <button
      v-for="tm in transformModes"
      :key="tm.value"
      :title="`${tm.label} (${tm.key})`"
      class="rounded px-2 py-1 text-[11px] font-medium transition-colors"
      :class="currentTransform === tm.value ? 'bg-cyan-700 text-white' : 'text-gray-400 hover:bg-gray-700 hover:text-gray-200'"
      @click="$emit('transform-mode', tm.value)"
    >{{ tm.label }}</button>

    <div class="mx-1 h-4 w-px bg-gray-700" />

    <button
      title="Reset Camera"
      class="rounded px-2 py-1 text-[11px] font-medium text-gray-400 transition-colors hover:bg-gray-700 hover:text-gray-200"
      @click="$emit('reset-camera')"
    >Reset</button>
  </div>
</template>

<script setup>
defineProps({
  currentDisplay: { type: String, default: 'shaded' },
  currentTransform: { type: String, default: 'translate' },
})

defineEmits(['display-mode', 'transform-mode', 'reset-camera'])

const displayModes = [
  { value: 'shaded', label: 'Shaded' },
  { value: 'wireframe', label: 'Wireframe' },
  { value: 'normals', label: 'Normals' },
  { value: 'uvcheck', label: 'UV Check' },
]

const transformModes = [
  { value: 'translate', label: 'Move', key: 'T' },
  { value: 'rotate', label: 'Rotate', key: 'R' },
  { value: 'scale', label: 'Scale', key: 'S' },
]
</script>
