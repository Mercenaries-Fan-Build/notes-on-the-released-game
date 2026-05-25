import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useReviewAssetsStore = defineStore('reviewAssets', () => {
  const assets = ref([])
  const packCounts = ref({})
  const pipelineHints = ref([])
  const roots = ref([])
  const loading = ref(false)
  const error = ref(null)

  const packs = computed(() => [...new Set(assets.value.map(a => a.pack))].sort())

  const totalAssets = computed(() => assets.value.length)

  const assetsWithMeshes = computed(() =>
    assets.value.filter(a => a.manifest || a.obj || a.gltf || a.meshSceneGltf).length
  )

  const assetsWithTextures = computed(() =>
    assets.value.filter(a => a.textureFiles?.length > 0).length
  )

  function filteredAssets(packFilter, searchQuery) {
    let list = assets.value
    if (packFilter && packFilter !== 'all') {
      list = list.filter(a => a.pack === packFilter)
    }
    if (searchQuery) {
      const q = searchQuery.toLowerCase()
      list = list.filter(a =>
        a.key.toLowerCase().includes(q) ||
        (a.label && a.label.toLowerCase().includes(q)) ||
        (a.stem && a.stem.toLowerCase().includes(q)) ||
        (a.artifactSearch || '').toLowerCase().includes(q)
      )
    }
    return list
  }

  function interleaveByPack(list) {
    const byPack = new Map()
    for (const a of list) {
      if (!byPack.has(a.pack)) byPack.set(a.pack, [])
      byPack.get(a.pack).push(a)
    }
    const packKeys = [...byPack.keys()].sort()
    for (const p of packKeys) {
      byPack.get(p).sort((x, y) => x.key.localeCompare(y.key))
    }
    const out = []
    let round = 0
    let progress = true
    while (progress) {
      progress = false
      for (const p of packKeys) {
        const arr = byPack.get(p)
        if (round < arr.length) {
          out.push(arr[round])
          progress = true
        }
      }
      round++
    }
    return out
  }

  async function fetchAssets() {
    loading.value = true
    error.value = null
    try {
      const res = await fetch('/api/review-assets.json')
      if (!res.ok) throw new Error(`HTTP ${res.status}`)
      const data = await res.json()
      assets.value = data.assets || []
      packCounts.value = data.packCounts || {}
      pipelineHints.value = data.pipelineHints || []
      roots.value = data.roots || []
    } catch (e) {
      error.value = e.message
      assets.value = []
      packCounts.value = {}
    } finally {
      loading.value = false
    }
  }

  return {
    assets,
    packCounts,
    pipelineHints,
    roots,
    loading,
    error,
    packs,
    totalAssets,
    assetsWithMeshes,
    assetsWithTextures,
    filteredAssets,
    interleaveByPack,
    fetchAssets,
  }
})
