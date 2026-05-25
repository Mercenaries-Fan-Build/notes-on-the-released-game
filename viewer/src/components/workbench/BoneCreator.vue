<template>
  <div class="flex h-full flex-col overflow-hidden text-xs text-gray-300">
    <div class="shrink-0 border-b border-gray-800 px-3 py-2 space-y-2">
      <label class="flex items-center gap-2 text-[11px] text-gray-400">
        <input
          v-model="creationMode"
          type="checkbox"
          class="accent-blue-500"
        />
        Bone Creation Mode
      </label>
      <div v-if="creationMode" class="text-[10px] text-yellow-500/80">Click mesh surface to place a bone</div>
    </div>

    <div class="shrink-0 border-b border-gray-800 px-3 py-2 space-y-1">
      <div class="text-[10px] uppercase tracking-wide text-gray-500">Templates</div>
      <div class="flex gap-2">
        <button
          class="rounded bg-gray-700 px-2 py-1 text-[11px] hover:bg-gray-600"
          @click="applyTemplate('humanoid')"
        >Humanoid</button>
        <button
          class="rounded bg-gray-700 px-2 py-1 text-[11px] hover:bg-gray-600"
          @click="applyTemplate('vehicle')"
        >Vehicle</button>
      </div>
    </div>

    <div class="min-h-0 flex-1 overflow-auto px-2 py-1">
      <div class="mb-1 text-[10px] uppercase tracking-wide text-gray-500">
        Bones ({{ boneList.length }})
      </div>
      <div
        v-for="(b, i) in boneList"
        :key="b.name + i"
        class="mb-1 flex items-center gap-1 rounded px-1 py-0.5 cursor-pointer text-[11px]"
        :class="selectedIdx === i ? 'bg-blue-900/60 text-blue-200' : 'hover:bg-gray-800 text-gray-300'"
        @click="selectBone(i)"
      >
        <span class="w-3 h-3 rounded-full shrink-0" style="background: #ff4444;" />
        <span class="truncate flex-1">{{ b.name }}</span>
        <span class="text-[10px] text-gray-500">{{ b.parentName || 'root' }}</span>
      </div>
      <div v-if="boneList.length === 0" class="py-4 text-center text-gray-500 text-[11px]">
        No bones created yet
      </div>
    </div>

    <div v-if="selectedIdx >= 0 && boneList[selectedIdx]" class="shrink-0 border-t border-gray-800 px-3 py-2 space-y-1.5">
      <div class="text-[10px] uppercase tracking-wide text-gray-500">Selected Bone</div>
      <div class="flex items-center gap-1">
        <label class="w-12 text-[10px] text-gray-500">Name</label>
        <input
          :value="boneList[selectedIdx].name"
          class="flex-1 rounded border border-gray-700 bg-gray-800 px-1.5 py-0.5 text-[11px] text-gray-200"
          @input="onRenameBone($event.target.value)"
        />
      </div>
      <div class="flex items-center gap-1">
        <label class="w-12 text-[10px] text-gray-500">Parent</label>
        <select
          :value="boneList[selectedIdx].parentName || ''"
          class="flex-1 rounded border border-gray-700 bg-gray-800 px-1 py-0.5 text-[11px] text-gray-200"
          @change="onReparent($event.target.value)"
        >
          <option value="">root</option>
          <option
            v-for="(b, j) in boneList"
            :key="j"
            :value="b.name"
            :disabled="j === selectedIdx"
          >{{ b.name }}</option>
        </select>
      </div>
      <div class="text-[10px] text-gray-500 mt-1">Position</div>
      <div class="grid grid-cols-3 gap-1">
        <div v-for="axis in ['x', 'y', 'z']" :key="axis" class="flex items-center gap-0.5">
          <span class="text-[10px] text-gray-500 uppercase">{{ axis }}</span>
          <input
            :value="selectedPos[axis]"
            type="number"
            step="0.01"
            class="w-full rounded border border-gray-700 bg-gray-800 px-1 py-0.5 text-[11px] text-gray-200"
            @change="onChangePos(axis, $event.target.value)"
          />
        </div>
      </div>
      <div class="text-[10px] text-gray-500 mt-1">Rotation (deg)</div>
      <div class="grid grid-cols-3 gap-1">
        <div v-for="axis in ['x', 'y', 'z']" :key="axis" class="flex items-center gap-0.5">
          <span class="text-[10px] text-gray-500 uppercase">{{ axis }}</span>
          <input
            :value="selectedRot[axis]"
            type="number"
            step="1"
            class="w-full rounded border border-gray-700 bg-gray-800 px-1 py-0.5 text-[11px] text-gray-200"
            @change="onChangeRot(axis, $event.target.value)"
          />
        </div>
      </div>
    </div>

    <div class="shrink-0 border-t border-gray-800 px-3 py-2 flex gap-2">
      <button
        class="rounded bg-green-700 px-2 py-1 text-[11px] font-medium text-white hover:bg-green-600"
        @click="exportSkeleton"
      >Export Skeleton JSON</button>
      <button
        class="rounded bg-red-900/60 px-2 py-1 text-[11px] text-red-300 hover:bg-red-800/60"
        @click="clearAll"
      >Clear All</button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue'
import * as THREE from 'three'

const props = defineProps({
  viewer: { type: Object, default: null },
})

const emit = defineEmits(['bones-changed'])

const creationMode = ref(false)
const boneList = ref([])
const selectedIdx = ref(-1)
const templateUsed = ref('custom')
const RAD2DEG = 180 / Math.PI
const DEG2RAD = Math.PI / 180

const HUMANOID_TEMPLATE = [
  { name: 'hips', parent: null, position: [0, 0.9, 0] },
  { name: 'spine', parent: 'hips', position: [0, 1.0, 0] },
  { name: 'spine1', parent: 'spine', position: [0, 1.1, 0] },
  { name: 'spine2', parent: 'spine1', position: [0, 1.25, 0] },
  { name: 'neck', parent: 'spine2', position: [0, 1.45, 0] },
  { name: 'head', parent: 'neck', position: [0, 1.6, 0] },
  { name: 'left_shoulder', parent: 'spine2', position: [0.1, 1.4, 0] },
  { name: 'left_upper_arm', parent: 'left_shoulder', position: [0.25, 1.35, 0] },
  { name: 'left_lower_arm', parent: 'left_upper_arm', position: [0.5, 1.1, 0] },
  { name: 'left_hand', parent: 'left_lower_arm', position: [0.7, 0.9, 0] },
  { name: 'right_shoulder', parent: 'spine2', position: [-0.1, 1.4, 0] },
  { name: 'right_upper_arm', parent: 'right_shoulder', position: [-0.25, 1.35, 0] },
  { name: 'right_lower_arm', parent: 'right_upper_arm', position: [-0.5, 1.1, 0] },
  { name: 'right_hand', parent: 'right_lower_arm', position: [-0.7, 0.9, 0] },
  { name: 'left_upper_leg', parent: 'hips', position: [0.12, 0.85, 0] },
  { name: 'left_lower_leg', parent: 'left_upper_leg', position: [0.12, 0.45, 0] },
  { name: 'left_foot', parent: 'left_lower_leg', position: [0.12, 0.05, 0.08] },
  { name: 'right_upper_leg', parent: 'hips', position: [-0.12, 0.85, 0] },
  { name: 'right_lower_leg', parent: 'right_upper_leg', position: [-0.12, 0.45, 0] },
  { name: 'right_foot', parent: 'right_lower_leg', position: [-0.12, 0.05, 0.08] },
]

const VEHICLE_TEMPLATE = [
  { name: 'chassis', parent: null, position: [0, 0.5, 0] },
  { name: 'wheel_fl', parent: 'chassis', position: [0.8, 0.3, 1.2] },
  { name: 'wheel_fr', parent: 'chassis', position: [-0.8, 0.3, 1.2] },
  { name: 'wheel_rl', parent: 'chassis', position: [0.8, 0.3, -1.2] },
  { name: 'wheel_rr', parent: 'chassis', position: [-0.8, 0.3, -1.2] },
  { name: 'turret', parent: 'chassis', position: [0, 1.0, -0.3] },
]

function syncBoneList() {
  if (!props.viewer) { boneList.value = []; return }
  const manual = props.viewer.getManualBones?.() ?? []
  boneList.value = manual.map(m => ({
    bone: m.bone,
    name: m.name,
    parentName: m.parentName,
  }))
  emit('bones-changed')
}

const selectedPos = computed(() => {
  if (selectedIdx.value < 0 || !boneList.value[selectedIdx.value]) return { x: '0', y: '0', z: '0' }
  const bone = boneList.value[selectedIdx.value].bone
  return {
    x: bone.position.x.toFixed(4),
    y: bone.position.y.toFixed(4),
    z: bone.position.z.toFixed(4),
  }
})

const selectedRot = computed(() => {
  if (selectedIdx.value < 0 || !boneList.value[selectedIdx.value]) return { x: '0', y: '0', z: '0' }
  const bone = boneList.value[selectedIdx.value].bone
  return {
    x: (bone.rotation.x * RAD2DEG).toFixed(2),
    y: (bone.rotation.y * RAD2DEG).toFixed(2),
    z: (bone.rotation.z * RAD2DEG).toFixed(2),
  }
})

function selectBone(idx) {
  selectedIdx.value = idx
  props.viewer?.unhighlightAllBones?.()
  if (idx >= 0 && boneList.value[idx]) {
    props.viewer?.highlightBone?.(boneList.value[idx].bone)
  }
}

function onRenameBone(name) {
  if (selectedIdx.value < 0 || !boneList.value[selectedIdx.value]) return
  const entry = boneList.value[selectedIdx.value]
  const oldName = entry.name
  props.viewer?.setManualBoneName?.(entry.bone, name)
  for (const b of boneList.value) {
    if (b.parentName === oldName) b.parentName = name
  }
  entry.name = name
}

function onReparent(parentName) {
  if (selectedIdx.value < 0 || !boneList.value[selectedIdx.value]) return
  const entry = boneList.value[selectedIdx.value]
  const parentBone = parentName ? boneList.value.find(b => b.name === parentName)?.bone ?? null : null
  props.viewer?.setManualBoneParent?.(entry.bone, parentBone)
  entry.parentName = parentName || null
}

function onChangePos(axis, val) {
  if (selectedIdx.value < 0 || !boneList.value[selectedIdx.value]) return
  const bone = boneList.value[selectedIdx.value].bone
  const pos = bone.position.clone()
  pos[axis] = parseFloat(val) || 0
  props.viewer?.setManualBonePosition?.(bone, pos)
}

function onChangeRot(axis, val) {
  if (selectedIdx.value < 0 || !boneList.value[selectedIdx.value]) return
  const bone = boneList.value[selectedIdx.value].bone
  bone.rotation[axis] = (parseFloat(val) || 0) * DEG2RAD
}

function applyTemplate(type) {
  clearAll()
  templateUsed.value = type
  const template = type === 'humanoid' ? HUMANOID_TEMPLATE : VEHICLE_TEMPLATE
  const boneMap = new Map()

  for (const def of template) {
    const parentBone = def.parent ? boneMap.get(def.parent) ?? null : null
    const pos = new THREE.Vector3(def.position[0], def.position[1], def.position[2])
    const bone = props.viewer?.addManualBone?.(pos, parentBone, def.name)
    if (bone) boneMap.set(def.name, bone)
  }
  syncBoneList()
}

function exportSkeleton() {
  const manual = props.viewer?.getManualBones?.() ?? []
  const data = {
    templateUsed: templateUsed.value,
    bones: manual.map(m => ({
      name: m.name,
      parent: m.parentName || null,
      position: [
        parseFloat(m.bone.position.x.toFixed(4)),
        parseFloat(m.bone.position.y.toFixed(4)),
        parseFloat(m.bone.position.z.toFixed(4)),
      ],
      rotation: [
        parseFloat((m.bone.rotation.x * RAD2DEG).toFixed(2)),
        parseFloat((m.bone.rotation.y * RAD2DEG).toFixed(2)),
        parseFloat((m.bone.rotation.z * RAD2DEG).toFixed(2)),
      ],
    })),
  }
  const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = 'skeleton.json'
  a.click()
  URL.revokeObjectURL(url)
}

function clearAll() {
  props.viewer?.clearManualBones?.()
  selectedIdx.value = -1
  templateUsed.value = 'custom'
  syncBoneList()
}

let _clickHandler = null

function onViewportClick(event) {
  if (!creationMode.value || !props.viewer) return
  const point = props.viewer.raycastForBonePlace?.(event)
  if (!point) return
  let parentBone = null
  if (selectedIdx.value >= 0 && boneList.value[selectedIdx.value]) {
    parentBone = boneList.value[selectedIdx.value].bone
  }
  props.viewer.addManualBone(point, parentBone)
  syncBoneList()
  selectBone(boneList.value.length - 1)
}

watch(creationMode, (on) => {
  const el = props.viewer?.getRenderer?.()?.domElement
  if (!el) return
  if (on) {
    _clickHandler = onViewportClick
    el.addEventListener('dblclick', _clickHandler)
  } else if (_clickHandler) {
    el.removeEventListener('dblclick', _clickHandler)
    _clickHandler = null
  }
})

watch(() => props.viewer, (v) => {
  if (v) {
    v.onPartsLoaded?.(() => syncBoneList())
    syncBoneList()
  }
}, { immediate: true })

onBeforeUnmount(() => {
  if (_clickHandler) {
    const el = props.viewer?.getRenderer?.()?.domElement
    el?.removeEventListener('dblclick', _clickHandler)
    _clickHandler = null
  }
})

defineExpose({ syncBoneList })
</script>
