import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

const STORAGE_KEY = 'mercs2-workbench-corrections'

export const useWorkbenchStore = defineStore('workbenchState', () => {
  const loadedModels = ref([])
  const selectedModelIndex = ref(0)
  const selectedPartIndex = ref(-1)
  const displayMode = ref('shaded')
  const transformMode = ref('translate')
  const undoStack = ref([])
  const redoStack = ref([])
  const corrections = ref([])

  const canUndo = computed(() => undoStack.value.length > 0)
  const canRedo = computed(() => redoStack.value.length > 0)
  const currentModel = computed(() => loadedModels.value[selectedModelIndex.value] || null)

  function rebuildCorrections() {
    const net = new Map()
    for (const cmd of undoStack.value) {
      const d = cmd.data
      if (cmd.type === 'transform') {
        const key = `${d.modelIndex}/${d.partIndex}`
        const existing = net.get(key) || { type: 'transform', partKey: key }
        existing.position = d.newPos
        existing.rotation = d.newRot
        existing.scale = d.newScale
        net.set(key, existing)
      } else if (cmd.type === 'visibility') {
        const key = `${d.modelIndex}/${d.partIndex}`
        const existing = net.get(key) || { type: 'visibility', partKey: key }
        existing.visible = d.newVisible
        net.set(key, existing)
      } else if (cmd.type === 'texture-assign') {
        const key = `${d.modelIndex}/${d.partIndices.join(',')}`
        net.set(key, { type: 'texture-assign', partKey: key, url: d.newMapUrl })
      } else if (cmd.type === 'submesh-transfer') {
        const key = `transfer/${d.partKey}`
        net.set(key, {
          type: 'submesh-transfer',
          partKey: d.partKey,
          sourceModelIndex: d.sourceModelIndex,
          targetModelIndex: d.targetModelIndex,
        })
      }
    }
    corrections.value = [...net.values()]
  }

  function execute(command) {
    command.exec()
    undoStack.value.push(command)
    redoStack.value = []
    rebuildCorrections()
  }

  function undo() {
    const cmd = undoStack.value.pop()
    if (!cmd) return
    cmd.undo()
    redoStack.value.push(cmd)
    rebuildCorrections()
  }

  function redo() {
    const cmd = redoStack.value.pop()
    if (!cmd) return
    cmd.exec()
    undoStack.value.push(cmd)
    rebuildCorrections()
  }

  function clearHistory() {
    undoStack.value = []
    redoStack.value = []
    corrections.value = []
  }

  function saveCorrections() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(corrections.value))
    } catch { /* quota exceeded or unavailable */ }
  }

  function loadCorrections() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY)
      if (raw) corrections.value = JSON.parse(raw)
    } catch { /* ignore parse errors */ }
  }

  function exportCorrections() {
    return JSON.stringify(corrections.value, null, 2)
  }

  function importCorrections(json) {
    try {
      corrections.value = JSON.parse(json)
    } catch { /* ignore */ }
  }

  function addModel({ key, stem, pack }) {
    const entry = { key, stem, pack, modelIndex: loadedModels.value.length }
    loadedModels.value.push(entry)
    return entry.modelIndex
  }

  function removeModel(index) {
    if (index < 0 || index >= loadedModels.value.length) return
    loadedModels.value.splice(index, 1)
    for (let i = index; i < loadedModels.value.length; i++) {
      loadedModels.value[i].modelIndex = i
    }
    undoStack.value = undoStack.value.filter(cmd => cmd.data?.modelIndex !== index)
    redoStack.value = redoStack.value.filter(cmd => cmd.data?.modelIndex !== index)
    if (selectedModelIndex.value >= loadedModels.value.length) {
      selectedModelIndex.value = Math.max(0, loadedModels.value.length - 1)
    }
    rebuildCorrections()
  }

  function getModel(index) {
    return loadedModels.value[index] || null
  }

  loadCorrections()

  return {
    loadedModels,
    selectedModelIndex,
    selectedPartIndex,
    displayMode,
    transformMode,
    undoStack,
    redoStack,
    corrections,
    canUndo,
    canRedo,
    currentModel,
    execute,
    undo,
    redo,
    clearHistory,
    saveCorrections,
    loadCorrections,
    exportCorrections,
    importCorrections,
    addModel,
    removeModel,
    getModel,
  }
})
