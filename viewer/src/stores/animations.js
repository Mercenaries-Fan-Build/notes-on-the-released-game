import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useAnimationsStore = defineStore('animations', () => {
  const animList = ref([])
  const loading = ref(false)

  async function fetchAnimIndex() {
    loading.value = true
    try {
      const res = await fetch('/api/anim-assets.json')
      if (!res.ok) throw new Error(`HTTP ${res.status}`)
      const data = await res.json()
      animList.value = data.animations || []
    } catch (e) {
      console.warn('anim index', e)
      animList.value = []
    } finally {
      loading.value = false
    }
  }

  async function fetchAnimDetail(slug) {
    try {
      const r = await fetch(`/api/anim-detail.json?slug=${encodeURIComponent(slug)}`)
      if (r.ok) return await r.json()
    } catch { /* ignore */ }
    return null
  }

  return { animList, loading, fetchAnimIndex, fetchAnimDetail }
})
