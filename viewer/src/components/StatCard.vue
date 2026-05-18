<template>
  <div class="rounded-lg border p-4" :class="cardClass">
    <div class="flex items-center justify-between">
      <div>
        <div class="text-[10px] font-medium uppercase tracking-wider" :class="labelClass">{{ label }}</div>
        <div class="mt-1 text-2xl font-bold" :class="valueClass">
          {{ typeof value === 'number' ? value.toLocaleString() : value }}
        </div>
      </div>
      <div class="flex h-10 w-10 items-center justify-center rounded-lg" :class="iconBgClass">
        <svg v-if="icon === 'cube'" class="h-5 w-5" :class="iconClass" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/>
        </svg>
        <svg v-else-if="icon === 'mesh'" class="h-5 w-5" :class="iconClass" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zm10 0a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zm10 0a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"/>
        </svg>
        <svg v-else-if="icon === 'texture'" class="h-5 w-5" :class="iconClass" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/>
        </svg>
        <svg v-else-if="icon === 'pack'" class="h-5 w-5" :class="iconClass" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4"/>
        </svg>
        <svg v-else-if="icon === 'pin'" class="h-5 w-5" :class="iconClass" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/>
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/>
        </svg>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  label: { type: String, required: true },
  value: { type: [Number, String], required: true },
  icon: { type: String, default: 'cube' },
  color: { type: String, default: 'blue' },
})

const colorMap = {
  blue: {
    card: 'border-blue-800/40 bg-blue-900/10',
    label: 'text-blue-400',
    value: 'text-blue-200',
    iconBg: 'bg-blue-900/30',
    icon: 'text-blue-400',
  },
  green: {
    card: 'border-green-800/40 bg-green-900/10',
    label: 'text-green-400',
    value: 'text-green-200',
    iconBg: 'bg-green-900/30',
    icon: 'text-green-400',
  },
  purple: {
    card: 'border-purple-800/40 bg-purple-900/10',
    label: 'text-purple-400',
    value: 'text-purple-200',
    iconBg: 'bg-purple-900/30',
    icon: 'text-purple-400',
  },
  amber: {
    card: 'border-amber-800/40 bg-amber-900/10',
    label: 'text-amber-400',
    value: 'text-amber-200',
    iconBg: 'bg-amber-900/30',
    icon: 'text-amber-400',
  },
  rose: {
    card: 'border-rose-800/40 bg-rose-900/10',
    label: 'text-rose-400',
    value: 'text-rose-200',
    iconBg: 'bg-rose-900/30',
    icon: 'text-rose-400',
  },
}

const colors = computed(() => colorMap[props.color] || colorMap.blue)
const cardClass = computed(() => colors.value.card)
const labelClass = computed(() => colors.value.label)
const valueClass = computed(() => colors.value.value)
const iconBgClass = computed(() => colors.value.iconBg)
const iconClass = computed(() => colors.value.icon)
</script>
