<template>
  <div class="flex h-full flex-col overflow-hidden text-xs text-gray-300">
    <div v-if="!hasBones && !hasManualBones" class="flex flex-1 flex-col items-center justify-center gap-3 p-6 text-center">
      <div class="text-sm text-gray-400">No skeleton found in this model</div>
      <button
        class="rounded bg-blue-600 px-3 py-1.5 text-[11px] font-medium text-white hover:bg-blue-500"
        @click="$emit('switch-to-bones')"
      >Create Skeleton</button>
    </div>

    <template v-else>
      <div class="shrink-0 border-b border-gray-800 px-3 py-2">
        <label class="flex items-center gap-2 text-[11px] text-gray-400">
          <input
            v-model="showHelper"
            type="checkbox"
            class="accent-blue-500"
            @change="onToggleHelper"
          />
          SkeletonHelper overlay
        </label>
      </div>

      <div class="min-h-0 flex-1 overflow-auto px-2 py-1">
        <div class="mb-1 text-[10px] uppercase tracking-wide text-gray-500">Bone Tree</div>
        <BoneTreeNode
          v-for="node in treeRoots"
          :key="node.id"
          :node="node"
          :depth="0"
          :selected-bone="selectedBone"
          @select="onSelectBone"
        />
        <div v-if="manualBoneNodes.length > 0" class="mt-2 mb-1 text-[10px] uppercase tracking-wide text-gray-500">Manual Bones</div>
        <BoneTreeNode
          v-for="node in manualRoots"
          :key="node.id"
          :node="node"
          :depth="0"
          :selected-bone="selectedBone"
          @select="onSelectBone"
        />
      </div>

      <div v-if="selectedBoneInfo" class="shrink-0 border-t border-gray-800 px-3 py-2 space-y-1">
        <div class="text-[10px] uppercase tracking-wide text-gray-500">Bone Info</div>
        <div class="flex justify-between">
          <span class="text-gray-500">Name</span>
          <span class="text-gray-200">{{ selectedBoneInfo.name }}</span>
        </div>
        <div class="flex justify-between">
          <span class="text-gray-500">Parent</span>
          <span class="text-gray-200">{{ selectedBoneInfo.parentName }}</span>
        </div>
        <div class="text-[10px] text-gray-500 mt-1">Local Position</div>
        <div class="grid grid-cols-3 gap-1 text-[11px]">
          <span class="text-center text-gray-400">{{ selectedBoneInfo.localPos.x }}</span>
          <span class="text-center text-gray-400">{{ selectedBoneInfo.localPos.y }}</span>
          <span class="text-center text-gray-400">{{ selectedBoneInfo.localPos.z }}</span>
        </div>
        <div class="text-[10px] text-gray-500 mt-1">World Position</div>
        <div class="grid grid-cols-3 gap-1 text-[11px]">
          <span class="text-center text-gray-400">{{ selectedBoneInfo.worldPos.x }}</span>
          <span class="text-center text-gray-400">{{ selectedBoneInfo.worldPos.y }}</span>
          <span class="text-center text-gray-400">{{ selectedBoneInfo.worldPos.z }}</span>
        </div>
        <div class="text-[10px] text-gray-500 mt-1">Local Rotation (deg)</div>
        <div class="grid grid-cols-3 gap-1 text-[11px]">
          <span class="text-center text-gray-400">{{ selectedBoneInfo.localRot.x }}</span>
          <span class="text-center text-gray-400">{{ selectedBoneInfo.localRot.y }}</span>
          <span class="text-center text-gray-400">{{ selectedBoneInfo.localRot.z }}</span>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, defineComponent, h } from 'vue'

const props = defineProps({
  viewer: { type: Object, default: null },
})

const emit = defineEmits(['switch-to-bones', 'select-bone'])

const showHelper = ref(false)
const selectedBone = ref(null)
const sceneBones = ref([])
const manualBoneNodes = ref([])
const refreshKey = ref(0)

const BoneTreeNode = defineComponent({
  name: 'BoneTreeNode',
  props: {
    node: { type: Object, required: true },
    depth: { type: Number, default: 0 },
    selectedBone: { type: Object, default: null },
  },
  emits: ['select'],
  setup(props, { emit }) {
    const expanded = ref(true)
    const hasChildren = computed(() => props.node.children && props.node.children.length > 0)
    const isSelected = computed(() => props.selectedBone && props.selectedBone === props.node.bone)

    return () => {
      const children = []
      const indent = { paddingLeft: `${props.depth * 12}px` }

      const rowClasses = [
        'flex items-center gap-1 rounded px-1 py-0.5 cursor-pointer text-[11px] leading-snug',
        isSelected.value ? 'bg-blue-900/60 text-blue-200' : 'hover:bg-gray-800 text-gray-300',
      ].join(' ')

      const arrowSpan = hasChildren.value
        ? h('span', {
            class: 'w-3 text-[10px] text-gray-500 select-none',
            onClick: (e) => { e.stopPropagation(); expanded.value = !expanded.value },
          }, expanded.value ? '\u25BE' : '\u25B8')
        : h('span', { class: 'w-3' })

      children.push(
        h('div', {
          class: rowClasses,
          style: indent,
          onClick: () => emit('select', props.node),
        }, [arrowSpan, h('span', { class: 'truncate' }, props.node.name)])
      )

      if (hasChildren.value && expanded.value) {
        for (const child of props.node.children) {
          children.push(
            h(BoneTreeNode, {
              node: child,
              depth: props.depth + 1,
              selectedBone: props.selectedBone,
              onSelect: (n) => emit('select', n),
            })
          )
        }
      }

      return h('div', null, children)
    }
  },
})

function buildTree(bones) {
  const nodeMap = new Map()
  for (const b of bones) {
    nodeMap.set(b.bone, { ...b, id: b.name + '_' + Math.random().toString(36).slice(2, 6), children: [] })
  }
  const roots = []
  for (const b of bones) {
    const node = nodeMap.get(b.bone)
    if (b.parent && nodeMap.has(b.parent)) {
      nodeMap.get(b.parent).children.push(node)
    } else {
      roots.push(node)
    }
  }
  return roots
}

function refreshBones() {
  if (!props.viewer) return
  const raw = props.viewer.getBonesFromScene?.() ?? []
  sceneBones.value = raw

  const manual = props.viewer.getManualBones?.() ?? []
  manualBoneNodes.value = manual.map(m => ({
    bone: m.bone,
    name: m.name,
    parent: m.parentName ? manual.find(x => x.name === m.parentName)?.bone ?? null : null,
    worldPosition: { x: m.bone.position.x, y: m.bone.position.y, z: m.bone.position.z },
  }))

  refreshKey.value++
}

const hasBones = computed(() => sceneBones.value.length > 0)
const hasManualBones = computed(() => manualBoneNodes.value.length > 0)

const treeRoots = computed(() => {
  refreshKey.value
  return buildTree(sceneBones.value)
})

const manualRoots = computed(() => {
  refreshKey.value
  return buildTree(manualBoneNodes.value)
})

const RAD2DEG = 180 / Math.PI

const selectedBoneInfo = computed(() => {
  if (!selectedBone.value) return null
  const bone = selectedBone.value
  const wp = bone.getWorldPosition ? (() => {
    const v = new (window.THREE?.Vector3 || Object)()
    try { bone.getWorldPosition(v); return v } catch { return bone.position }
  })() : bone.position

  const parentName = bone.parent?.isBone
    ? (bone.parent.name || '(unnamed)')
    : manualBoneNodes.value.find(m => m.bone === bone)?.parent
      ? (manualBoneNodes.value.find(m => m.bone === bone).parent.name || '(unnamed)')
      : 'root'

  return {
    name: bone.name || '(unnamed)',
    parentName,
    localPos: {
      x: bone.position.x.toFixed(4),
      y: bone.position.y.toFixed(4),
      z: bone.position.z.toFixed(4),
    },
    worldPos: {
      x: (wp.x ?? 0).toFixed(4),
      y: (wp.y ?? 0).toFixed(4),
      z: (wp.z ?? 0).toFixed(4),
    },
    localRot: {
      x: ((bone.rotation?.x ?? 0) * RAD2DEG).toFixed(2),
      y: ((bone.rotation?.y ?? 0) * RAD2DEG).toFixed(2),
      z: ((bone.rotation?.z ?? 0) * RAD2DEG).toFixed(2),
    },
  }
})

function onToggleHelper() {
  props.viewer?.toggleSkeletonHelper?.(showHelper.value)
}

function onSelectBone(node) {
  props.viewer?.unhighlightAllBones?.()
  selectedBone.value = node.bone
  props.viewer?.highlightBone?.(node.bone)
  emit('select-bone', node.bone)
}

watch(() => props.viewer, (v) => {
  if (v) {
    v.onPartsLoaded?.(() => refreshBones())
    refreshBones()
  }
}, { immediate: true })

defineExpose({ refreshBones })
</script>
