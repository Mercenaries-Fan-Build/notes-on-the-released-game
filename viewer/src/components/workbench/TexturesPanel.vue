<template>
  <div class="flex h-full flex-col overflow-hidden">
    <div class="flex items-center gap-2 border-b border-gray-800 px-3 py-1.5">
      <span class="text-[11px] font-medium text-gray-400">Textures</span>
      <span v-if="textures.length" class="text-[10px] text-gray-500">({{ textures.length }})</span>
    </div>

    <div class="flex-1 overflow-auto p-2 space-y-3">
      <div v-if="!textures.length" class="text-[11px] text-gray-500 italic px-1">
        No texture manifest found for this asset.
      </div>

      <template v-if="textures.length">
        <!-- Mode controls -->
        <div class="space-y-1.5">
          <label class="block text-[10px] uppercase tracking-wide text-gray-500">Apply Mode</label>
          <div class="flex flex-wrap gap-1">
            <button
              class="rounded px-2 py-1 text-[11px] transition-colors"
              :class="mode === 'auto' ? 'bg-blue-700 text-white' : 'bg-gray-800 text-gray-300 hover:bg-gray-700'"
              @click="applyAutoMode"
            >Auto (per-material)</button>
            <button
              class="rounded px-2 py-1 text-[11px] transition-colors"
              :class="mode === 'none' ? 'bg-blue-700 text-white' : 'bg-gray-800 text-gray-300 hover:bg-gray-700'"
              @click="clearTextures"
            >No texture</button>
          </div>
        </div>

        <!-- Global override -->
        <div class="space-y-1">
          <label class="block text-[10px] uppercase tracking-wide text-gray-500">Global Override</label>
          <select
            v-model="globalOverride"
            class="w-full rounded border border-gray-700 bg-gray-800 px-2 py-1 text-xs text-gray-200"
            @change="applyGlobalOverride"
          >
            <option value="">-- none --</option>
            <option v-for="t in textures" :key="t.name" :value="t.pngUrl">{{ t.name }}</option>
          </select>
        </div>

        <!-- V-flip toggle -->
        <div class="flex items-center gap-2">
          <input
            id="vflip"
            v-model="vFlip"
            type="checkbox"
            class="h-3 w-3 accent-blue-500"
            @change="onVFlipChange"
          />
          <label for="vflip" class="text-[11px] text-gray-300 select-none">V-flip UVs</label>
        </div>

        <!-- Channel isolation -->
        <div class="space-y-1">
          <label class="block text-[10px] uppercase tracking-wide text-gray-500">Channel</label>
          <div class="flex gap-1">
            <button
              v-for="ch in ['r', 'g', 'b', 'a']"
              :key="ch"
              class="rounded px-2 py-1 text-[11px] font-mono font-bold uppercase transition-colors"
              :class="activeChannel === ch
                ? channelActiveClass(ch)
                : 'bg-gray-800 text-gray-400 hover:bg-gray-700'"
              @click="toggleChannel(ch)"
            >{{ ch }}</button>
          </div>
        </div>

        <!-- Texture list with thumbnails -->
        <div class="space-y-1">
          <label class="block text-[10px] uppercase tracking-wide text-gray-500">Available</label>
          <div class="grid grid-cols-2 gap-1.5">
            <div
              v-for="t in textures"
              :key="t.name"
              class="group cursor-pointer rounded border border-gray-700 bg-gray-800 p-1 hover:border-gray-600"
              @click="applySingleTexture(t)"
            >
              <img
                :src="t.pngUrl"
                :alt="t.name"
                class="mb-1 h-16 w-full rounded object-cover bg-gray-950"
                loading="lazy"
              />
              <div class="truncate text-[10px] text-gray-400 group-hover:text-gray-200" :title="t.name">
                {{ t.name }}
              </div>
              <div v-if="t.width" class="text-[9px] text-gray-600">{{ t.width }}x{{ t.height }}</div>
            </div>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import { loadTexture, clearTextureCache, makeMaterial } from '../../lib/submesh-inspect.js'

const props = defineProps({
  viewer: { type: Object, default: null },
  asset: { type: Object, default: null },
})

const emit = defineEmits(['channel-isolation'])

const textures = ref([])
const mode = ref('none')
const globalOverride = ref('')
const vFlip = ref(false)
const activeChannel = ref(null)

function getBaseDir(asset) {
  if (!asset) return null
  const url = asset.gltf || asset.meshSceneGltf || asset.obj || asset.manifest || ''
  if (!url) return null
  return url.substring(0, url.lastIndexOf('/') + 1)
}

async function fetchManifest() {
  textures.value = []
  if (!props.asset?.sidecars?.texturesManifestJson) return

  const baseDir = getBaseDir(props.asset)
  if (!baseDir) return

  try {
    const res = await fetch(baseDir + 'textures/manifest.json')
    if (!res.ok) return
    const data = await res.json()
    textures.value = (Array.isArray(data) ? data : []).map(entry => ({
      name: entry.name || entry.file || 'unknown',
      pngUrl: baseDir + 'textures/' + (entry.png || entry.file || entry.name),
      width: entry.width || null,
      height: entry.height || null,
    }))
  } catch { /* ignore */ }
}

watch(() => props.asset, fetchManifest, { immediate: true })

async function applyAutoMode() {
  mode.value = 'auto'
  globalOverride.value = ''
  if (!props.viewer) return

  const meta = props.viewer.getPartMeta?.() ?? []
  const groups = props.viewer.getPartGroups?.() ?? []

  for (let i = 0; i < groups.length; i++) {
    const entry = meta[i]
    const diffuseName = entry?.texture_diffuse
    if (!diffuseName) continue

    const match = textures.value.find(t =>
      t.name === diffuseName || t.pngUrl.endsWith('/' + diffuseName)
    )
    if (!match) continue

    try {
      const tex = await loadTexture(match.pngUrl, vFlip.value)
      groups[i].traverse?.(c => {
        if (c.isMesh) {
          c.material = makeMaterial(i, entry, tex)
          c.material.needsUpdate = true
        }
      })
    } catch { /* skip */ }
  }
}

async function applyGlobalOverride() {
  if (!globalOverride.value) return
  mode.value = 'global'
  if (!props.viewer) return

  const meta = props.viewer.getPartMeta?.() ?? []
  const groups = props.viewer.getPartGroups?.() ?? []

  try {
    const tex = await loadTexture(globalOverride.value, vFlip.value)
    for (let i = 0; i < groups.length; i++) {
      groups[i].traverse?.(c => {
        if (c.isMesh) {
          c.material = makeMaterial(i, meta[i] || null, tex)
          c.material.needsUpdate = true
        }
      })
    }
  } catch { /* skip */ }
}

async function applySingleTexture(t) {
  mode.value = 'global'
  globalOverride.value = t.pngUrl
  await applyGlobalOverride()
}

function clearTextures() {
  mode.value = 'none'
  globalOverride.value = ''
  if (!props.viewer) return

  const meta = props.viewer.getPartMeta?.() ?? []
  const groups = props.viewer.getPartGroups?.() ?? []

  for (let i = 0; i < groups.length; i++) {
    groups[i].traverse?.(c => {
      if (c.isMesh) {
        c.material = makeMaterial(i, meta[i] || null, null)
        c.material.needsUpdate = true
      }
    })
  }
}

function onVFlipChange() {
  clearTextureCache()
  if (mode.value === 'auto') applyAutoMode()
  else if (mode.value === 'global' && globalOverride.value) applyGlobalOverride()
}

function toggleChannel(ch) {
  activeChannel.value = activeChannel.value === ch ? null : ch
  emit('channel-isolation', activeChannel.value)
}

function channelActiveClass(ch) {
  const map = {
    r: 'bg-red-800 text-red-200',
    g: 'bg-green-800 text-green-200',
    b: 'bg-blue-800 text-blue-200',
    a: 'bg-gray-600 text-white',
  }
  return map[ch] || ''
}
</script>
