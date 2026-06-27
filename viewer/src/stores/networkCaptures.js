import { defineStore } from 'pinia'
import { ref } from 'vue'

/**
 * Network captures — every request the game made to the Modkit capture server
 * (coopserver), logged like httpbin. Covers main-menu (shell.wad) and in-game
 * (vz.wad) traffic across HTTP / FESL / Theater / raw protocols.
 * Source: GET /api/network-captures (newest first).
 */
export const useNetworkCapturesStore = defineStore('networkCaptures', () => {
  const captures = ref([])
  const total = ref(0)
  const loading = ref(false)
  const error = ref(null)

  async function fetchCaptures(params = {}) {
    loading.value = true
    error.value = null
    try {
      const q = new URLSearchParams()
      if (params.protocol) q.set('protocol', params.protocol)
      if (params.host) q.set('host', params.host)
      if (params.fesl_txn) q.set('fesl_txn', params.fesl_txn)
      if (params.search) q.set('search', params.search)
      q.set('limit', String(params.limit ?? 200))
      q.set('offset', String(params.offset ?? 0))
      const res = await fetch(`/api/network-captures?${q.toString()}`)
      if (!res.ok) throw new Error(`${res.status} ${res.statusText}`)
      const data = await res.json()
      captures.value = data.items || []
      total.value = data.total || 0
    } catch (e) {
      error.value = String(e)
      captures.value = []
    } finally {
      loading.value = false
    }
  }

  async function clearCaptures() {
    await fetch('/api/network-captures', { method: 'DELETE' })
    captures.value = []
    total.value = 0
  }

  return { captures, total, loading, error, fetchCaptures, clearCaptures }
})
