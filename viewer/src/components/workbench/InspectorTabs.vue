<template>
  <div class="flex h-full flex-col overflow-hidden">
    <div class="flex shrink-0 border-b border-gray-800 bg-gray-900 overflow-x-auto">
      <button
        v-for="tab in visibleTabs"
        :key="tab.id"
        class="shrink-0 px-3 py-1.5 text-[11px] font-medium transition-colors whitespace-nowrap"
        :class="activeTab === tab.id
          ? 'border-b-2 border-blue-500 text-gray-100'
          : 'text-gray-500 hover:text-gray-300'"
        @click="activeTab = tab.id"
      >{{ tab.label }}</button>
    </div>
    <div class="min-h-0 flex-1 overflow-hidden">
      <PartsPanel
        v-if="activeTab === 'parts'"
        :part-meta="partMeta"
        :part-groups="partGroups"
        :selected-index="selectedIndex"
        :visibility="visibility"
        @select-part="$emit('select-part', $event)"
        @toggle-visible="(idx, vis) => $emit('toggle-visible', idx, vis)"
      />
      <PropertiesPanel
        v-if="activeTab === 'properties'"
        :selected-index="selectedIndex"
        :part-meta="selectedPartMeta"
        :part-group="selectedPartGroup"
      />
      <SidecarsPanel
        v-if="activeTab === 'sidecars'"
        :asset="asset"
      />
      <TexturesPanel
        v-if="activeTab === 'textures'"
        :viewer="viewer"
        :asset="asset"
      />
      <LODVariantsPanel
        v-if="activeTab === 'lod'"
        :viewer="viewer"
        :part-meta="partMeta"
        :part-groups="partGroups"
      />
      <AnimationPanel
        v-if="activeTab === 'animation'"
        :viewer="viewer"
      />
      <WorkspacePanel
        v-if="activeTab === 'workspace'"
        :models="models"
        :selected-model-index="selectedModelIndex"
        @select-model="$emit('select-model', $event)"
        @focus-model="$emit('focus-model', $event)"
        @remove-model="$emit('remove-model', $event)"
        @toggle-model-visible="(idx, vis) => $emit('toggle-model-visible', idx, vis)"
      />
      <SkeletonPanel
        v-if="activeTab === 'skeleton'"
        ref="skeletonPanelRef"
        :viewer="viewer"
        @switch-to-bones="activeTab = 'bones'"
        @select-bone="(bone) => $emit('select-bone', bone)"
      />
      <BoneCreator
        v-if="activeTab === 'bones'"
        ref="boneCreatorRef"
        :viewer="viewer"
        @bones-changed="onBonesChanged"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import PartsPanel from './PartsPanel.vue'
import PropertiesPanel from './PropertiesPanel.vue'
import SidecarsPanel from './SidecarsPanel.vue'
import TexturesPanel from './TexturesPanel.vue'
import LODVariantsPanel from './LODVariantsPanel.vue'
import WorkspacePanel from './WorkspacePanel.vue'
import SkeletonPanel from './SkeletonPanel.vue'
import BoneCreator from './BoneCreator.vue'
import AnimationPanel from './AnimationPanel.vue'
import { useAnimationsStore } from '../../stores/animations.js'

const animStore = useAnimationsStore()

const props = defineProps({
  partMeta: { type: Array, default: () => [] },
  partGroups: { type: Array, default: () => [] },
  selectedIndex: { type: Number, default: -1 },
  visibility: { type: Object, default: () => ({}) },
  asset: { type: Object, default: null },
  viewer: { type: Object, default: null },
  models: { type: Array, default: () => [] },
  selectedModelIndex: { type: Number, default: -1 },
})

defineEmits([
  'select-part',
  'toggle-visible',
  'select-model',
  'focus-model',
  'remove-model',
  'toggle-model-visible',
  'select-bone',
])

const activeTab = ref('parts')
const skeletonPanelRef = ref(null)
const boneCreatorRef = ref(null)
const hasManualBones = ref(false)

const hasTextureData = computed(() =>
  !!props.asset?.sidecars?.texturesManifestJson
)

const hasLodData = computed(() =>
  props.partMeta.some(e => e?.lod_rank != null || e?.damage_state)
)

const hasMultipleModels = computed(() =>
  props.models.length > 1
)

const hasAnimData = computed(() =>
  animStore.animList.length > 0 || animStore.currentSlug !== ''
)

const hasSceneBones = computed(() => {
  if (!props.viewer) return false
  const bones = props.viewer.getBonesFromScene?.() ?? []
  return bones.length > 0
})

function onBonesChanged() {
  const manual = props.viewer?.getManualBones?.() ?? []
  hasManualBones.value = manual.length > 0
  skeletonPanelRef.value?.refreshBones?.()
}

const allTabs = [
  { id: 'parts', label: 'Parts', always: true },
  { id: 'properties', label: 'Properties', always: true },
  { id: 'textures', label: 'Textures', condition: 'texture' },
  { id: 'lod', label: 'LOD / Variants', condition: 'lod' },
  { id: 'animation', label: 'Animation', condition: 'animation' },
  { id: 'skeleton', label: 'Skeleton', condition: 'skeleton' },
  { id: 'bones', label: 'Bones', condition: 'bones' },
  { id: 'workspace', label: 'Workspace', condition: 'workspace' },
  { id: 'sidecars', label: 'Sidecars', always: true },
]

const visibleTabs = computed(() =>
  allTabs.filter(tab => {
    if (tab.always) return true
    if (tab.condition === 'texture') return hasTextureData.value
    if (tab.condition === 'lod') return hasLodData.value
    if (tab.condition === 'animation') return hasAnimData.value
    if (tab.condition === 'skeleton') return hasSceneBones.value || hasManualBones.value || props.partGroups.length > 0
    if (tab.condition === 'bones') return hasManualBones.value || props.partGroups.length > 0
    if (tab.condition === 'workspace') return hasMultipleModels.value
    return false
  })
)

const selectedPartMeta = computed(() =>
  props.selectedIndex >= 0 ? props.partMeta[props.selectedIndex] ?? null : null
)

const selectedPartGroup = computed(() =>
  props.selectedIndex >= 0 ? props.partGroups[props.selectedIndex] ?? null : null
)
</script>
