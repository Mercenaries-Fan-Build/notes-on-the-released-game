import { defineStore } from 'pinia'
import { ref } from 'vue'

/**
 * Model-centric catalogue. A "model" is an asset hash recovered by grouping
 * submeshes across blocks (GET /api/models) — the workbench's real entities,
 * independent of how the engine packed them into blocks.
 */
export const useModelsStore = defineStore('models', () => {
  const models = ref([])
  const loading = ref(false)
  const loaded = ref(false)
  const error = ref(null)

  async function fetchModels(params = {}) {
    loading.value = true
    error.value = null
    try {
      const q = new URLSearchParams()
      if (params.q) q.set('q', params.q)
      if (params.pack && params.pack !== 'all') q.set('pack', params.pack)
      if (params.destructible) q.set('destructible', 'true')
      q.set('limit', String(params.limit ?? 1000))
      const res = await fetch(`/api/models?${q.toString()}`)
      if (!res.ok) throw new Error(`${res.status} ${res.statusText}`)
      const data = await res.json()
      models.value = data.items || []
      loaded.value = true
    } catch (e) {
      error.value = String(e)
      models.value = []
    } finally {
      loading.value = false
    }
  }

  return { models, loading, loaded, error, fetchModels }
})
