<template>
  <nav class="flex items-center gap-1 border-b border-gray-800 bg-gray-900 px-4 py-2">
    <router-link to="/" class="mr-4 text-sm font-semibold text-gray-100 hover:text-white">
      Mercenaries 2
    </router-link>
    <router-link
      v-for="link in links"
      :key="link.to"
      :to="link.to"
      class="rounded px-3 py-1 text-xs font-medium transition-colors"
      :class="isActive(link.to)
        ? 'bg-gray-700 text-white'
        : 'text-gray-400 hover:bg-gray-800 hover:text-gray-200'"
    >
      {{ link.label }}
    </router-link>
  </nav>
</template>

<script setup>
import { useRoute } from 'vue-router'

const route = useRoute()

const links = [
  { to: '/', label: 'Dashboard' },
  { to: '/blocks', label: 'Block Browser' },
  { to: '/review', label: 'Review Queue' },
  { to: '/workbench', label: 'Workbench' },
  { to: '/world-cells', label: 'World Cells 3D' },
  { to: '/placements', label: 'Placement Map' },
  { to: '/zones', label: 'Zone Editor' },
  { to: '/search', label: 'Search' },
  { to: '/placement-qa', label: 'Placement QA' },
  { to: '/network-captures', label: 'Network Captures' },
]

function isActive(to) {
  if (to === '/') return route.path === '/'
  return route.path.startsWith(to)
}
</script>
