<template>
  <div class="flex items-center justify-between border-t border-gray-800 bg-gray-900/80 px-3 py-1 text-[11px] text-gray-400 backdrop-blur">
    <span v-if="modelSize">{{ fmtDim(modelSize.x) }} x {{ fmtDim(modelSize.y) }} x {{ fmtDim(modelSize.z) }}</span>
    <span v-else>&mdash;</span>
    <span v-if="totalVerts != null">{{ fmtNum(totalVerts) }} verts &middot; {{ fmtNum(totalFaces) }} faces</span>
    <span v-else>&nbsp;</span>
    <span :class="selectedInfo ? 'text-gray-200' : 'text-gray-500'">{{ selectedInfo || 'No selection' }}</span>
  </div>
</template>

<script setup>
defineProps({
  modelSize: { type: Object, default: null },
  totalVerts: { type: Number, default: null },
  totalFaces: { type: Number, default: null },
  selectedInfo: { type: String, default: '' },
})

function fmtNum(n) {
  return n == null ? '0' : n.toLocaleString()
}

function fmtDim(v) {
  return v == null ? '?' : v.toFixed(2)
}
</script>
