<template>
  <div class="flex h-full flex-col overflow-hidden">
    <div class="flex items-center gap-2 border-b border-gray-800 px-3 py-1.5">
      <span class="text-[11px] font-medium text-gray-400">Workspace</span>
      <span class="text-[10px] text-gray-500">({{ models.length }})</span>
    </div>

    <ul class="flex-1 overflow-auto p-1">
      <li
        v-for="(m, idx) in models"
        :key="m.key"
        class="flex items-center gap-1.5 rounded px-2 py-1.5 text-[11px] leading-snug transition-colors cursor-pointer"
        :class="idx === selectedModelIndex
          ? 'bg-blue-900/60 text-gray-100'
          : 'text-gray-300 hover:bg-gray-800'"
        @click="$emit('select-model', idx)"
      >
        <input
          type="checkbox"
          :checked="m.visible !== false"
          class="h-3 w-3 accent-blue-500"
          @click.stop
          @change="$emit('toggle-model-visible', idx, $event.target.checked)"
        />

        <span class="flex-1 truncate" :title="m.pack ? m.pack + '/' + m.stem : m.stem">
          <span v-if="m.pack" class="text-gray-500">{{ m.pack }}/</span>{{ m.stem }}
          <span v-if="m.detached" class="ml-1 text-[10px] text-gray-500">(detached)</span>
        </span>

        <button
          class="shrink-0 rounded p-0.5 text-gray-500 hover:bg-gray-700 hover:text-gray-200"
          title="Focus camera"
          @click.stop="$emit('focus-model', idx)"
        >
          <svg class="h-3.5 w-3.5" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5">
            <circle cx="8" cy="8" r="5" />
            <line x1="8" y1="1" x2="8" y2="3" />
            <line x1="8" y1="13" x2="8" y2="15" />
            <line x1="1" y1="8" x2="3" y2="8" />
            <line x1="13" y1="8" x2="15" y2="8" />
          </svg>
        </button>

        <button
          class="shrink-0 rounded p-0.5 text-gray-500 hover:bg-red-900/50 hover:text-red-300"
          title="Remove"
          @click.stop="$emit('remove-model', idx)"
        >
          <svg class="h-3.5 w-3.5" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5">
            <line x1="4" y1="4" x2="12" y2="12" />
            <line x1="12" y1="4" x2="4" y2="12" />
          </svg>
        </button>
      </li>
    </ul>
  </div>
</template>

<script setup>
defineProps({
  models: { type: Array, default: () => [] },
  selectedModelIndex: { type: Number, default: -1 },
})

defineEmits(['select-model', 'focus-model', 'remove-model', 'toggle-model-visible'])
</script>
