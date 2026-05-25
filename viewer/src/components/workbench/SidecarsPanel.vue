<template>
  <div class="h-full overflow-auto p-3">
    <template v-if="asset">
      <section v-if="meshSidecars.length" class="mb-4">
        <h3 class="mb-1.5 text-[11px] font-semibold uppercase tracking-wide text-gray-400">Mesh Data</h3>
        <ul class="space-y-1">
          <li v-for="s in meshSidecars" :key="s.url">
            <a
              :href="s.url"
              target="_blank"
              class="text-[11px] text-blue-400 hover:text-blue-300 hover:underline"
            >{{ s.name }}</a>
          </li>
        </ul>
      </section>

      <section v-if="textureSidecars.length" class="mb-4">
        <h3 class="mb-1.5 text-[11px] font-semibold uppercase tracking-wide text-gray-400">Textures</h3>
        <ul class="space-y-1">
          <li v-for="t in textureSidecars" :key="t.url">
            <a
              :href="t.url"
              target="_blank"
              class="text-[11px] text-blue-400 hover:text-blue-300 hover:underline"
            >{{ t.name }}</a>
          </li>
        </ul>
      </section>

      <section v-if="otherSidecars.length" class="mb-4">
        <h3 class="mb-1.5 text-[11px] font-semibold uppercase tracking-wide text-gray-400">Other</h3>
        <ul class="space-y-1">
          <li v-for="s in otherSidecars" :key="s.url">
            <a
              :href="s.url"
              target="_blank"
              class="text-[11px] text-blue-400 hover:text-blue-300 hover:underline"
            >{{ s.name }}</a>
          </li>
        </ul>
      </section>

      <div v-if="!meshSidecars.length && !textureSidecars.length && !otherSidecars.length" class="text-[11px] text-gray-500">
        No sidecars available for this asset.
      </div>
    </template>
    <div v-else class="flex h-full items-center justify-center text-xs text-gray-500">
      No asset loaded
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  asset: { type: Object, default: null },
})

const meshKeys = ['ucfxJson', 'meshMetaJson', 'manifest']
const textureKeys = ['textureFiles']

function gatherSidecars(a) {
  if (!a) return []
  const items = []
  if (a.sidecars && typeof a.sidecars === 'object') {
    for (const [key, url] of Object.entries(a.sidecars)) {
      if (url) items.push({ key, name: key, url })
    }
  }
  for (const key of ['ucfxJson', 'meshMetaJson', 'manifest', 'dialogFragmentsJson']) {
    if (a[key] && !items.some(i => i.url === a[key])) {
      items.push({ key, name: key, url: a[key] })
    }
  }
  return items
}

function gatherTextures(a) {
  if (!a?.textureFiles?.length) return []
  return a.textureFiles.map(f => {
    const url = typeof f === 'string' ? f : f.url || f.path || ''
    const name = typeof f === 'string' ? f.split('/').pop() : (f.name || f.url?.split('/').pop() || 'texture')
    return { name, url }
  })
}

const allSidecars = computed(() => gatherSidecars(props.asset))
const allTextures = computed(() => gatherTextures(props.asset))

const meshSidecars = computed(() =>
  allSidecars.value.filter(s => meshKeys.includes(s.key))
)

const textureSidecars = computed(() => allTextures.value)

const otherSidecars = computed(() =>
  allSidecars.value.filter(s => !meshKeys.includes(s.key) && !textureKeys.includes(s.key))
)
</script>
