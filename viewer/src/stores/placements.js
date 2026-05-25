import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const usePlacementsStore = defineStore('placements', () => {
  const placements = ref([])
  const loading = ref(false)
  const error = ref(null)
  const datasetId = ref('maracaibo')
  const datasetPath = ref('')
  const bbox = ref(null)

  const totalCount = computed(() => placements.value.length)

  const layersStaticCount = computed(() =>
    placements.value.filter(p => p.block_type === 'layers_static').length
  )

  const vzStateCount = computed(() =>
    placements.value.filter(p => p.block_type === 'vz_state').length
  )

  async function fetchDataset(id) {
    loading.value = true
    error.value = null
    datasetId.value = id
    try {
      const res = await fetch(`/api/placements-dataset.json?id=${encodeURIComponent(id)}`)
      if (!res.ok) throw new Error(`HTTP ${res.status}`)
      const data = await res.json()
      placements.value = Array.isArray(data) ? data : data.placements || []
      datasetPath.value = data.path || id
      bbox.value = data.bbox || null
    } catch (e) {
      error.value = e.message
      placements.value = []
    } finally {
      loading.value = false
    }
  }

  async function fetchCatalog() {
    try {
      const res = await fetch('/api/placements-catalog.json')
      if (!res.ok) return null
      return await res.json()
    } catch {
      return null
    }
  }

  return {
    placements,
    loading,
    error,
    datasetId,
    datasetPath,
    bbox,
    totalCount,
    layersStaticCount,
    vzStateCount,
    fetchDataset,
    fetchCatalog,
  }
})
