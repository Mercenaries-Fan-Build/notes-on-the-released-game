<template>
  <div class="h-full overflow-auto p-3">
    <template v-if="selectedIndex >= 0 && partMeta">
      <section class="mb-4">
        <h3 class="mb-2 text-[11px] font-semibold uppercase tracking-wide text-gray-400">Transform</h3>
        <div class="space-y-1.5">
          <div v-for="axis in axes" :key="'pos-' + axis" class="flex items-center gap-2">
            <label class="w-14 text-[11px] text-gray-500">Pos {{ axis.toUpperCase() }}</label>
            <input
              type="number"
              step="0.01"
              :value="position[axis]"
              class="w-full rounded border border-gray-700 bg-gray-800 px-2 py-1 text-[11px] text-gray-200"
              @change="onPositionChange(axis, $event)"
            />
          </div>
          <div v-for="axis in axes" :key="'rot-' + axis" class="flex items-center gap-2">
            <label class="w-14 text-[11px] text-gray-500">Rot {{ axis.toUpperCase() }}</label>
            <input
              type="number"
              step="1"
              :value="rotation[axis]"
              class="w-full rounded border border-gray-700 bg-gray-800 px-2 py-1 text-[11px] text-gray-200"
              @change="onRotationChange(axis, $event)"
            />
          </div>
          <div v-for="axis in axes" :key="'scl-' + axis" class="flex items-center gap-2">
            <label class="w-14 text-[11px] text-gray-500">Scale {{ axis.toUpperCase() }}</label>
            <input
              type="number"
              step="0.01"
              :value="scale[axis]"
              class="w-full rounded border border-gray-700 bg-gray-800 px-2 py-1 text-[11px] text-gray-200"
              @change="onScaleChange(axis, $event)"
            />
          </div>
        </div>
      </section>

      <section class="mb-4">
        <h3 class="mb-2 text-[11px] font-semibold uppercase tracking-wide text-gray-400">Bounding Box</h3>
        <div v-if="bbox" class="grid grid-cols-3 gap-1 text-[11px]">
          <div v-for="(val, label) in bboxDisplay" :key="label" class="rounded bg-gray-800 px-2 py-1 text-center">
            <div class="text-[10px] text-gray-500">{{ label }}</div>
            <div class="text-gray-300">{{ val }}</div>
          </div>
        </div>
        <div v-else class="text-[11px] text-gray-500">N/A</div>
      </section>

      <section>
        <h3 class="mb-2 text-[11px] font-semibold uppercase tracking-wide text-gray-400">Stats</h3>
        <div class="space-y-1 text-[11px]">
          <div class="flex justify-between"><span class="text-gray-500">Vertices</span><span class="text-gray-300">{{ fmtNum(stats.vertices) }}</span></div>
          <div class="flex justify-between"><span class="text-gray-500">Faces</span><span class="text-gray-300">{{ fmtNum(stats.faces) }}</span></div>
          <div class="flex justify-between"><span class="text-gray-500">Material</span><span class="text-gray-300">M{{ partMeta.material_index ?? '?' }}</span></div>
          <div class="flex justify-between"><span class="text-gray-500">LOD Group</span><span class="text-gray-300">{{ partMeta.lod_group ?? '-' }}</span></div>
          <div class="flex justify-between"><span class="text-gray-500">LOD Rank</span><span class="text-gray-300">{{ partMeta.lod_rank ?? '-' }}</span></div>
          <div class="flex justify-between"><span class="text-gray-500">Damage State</span><span class="text-gray-300">{{ partMeta.damage_state ?? 'shared' }}</span></div>
          <div class="flex justify-between"><span class="text-gray-500">Classification</span><span class="text-gray-300">{{ classification }}</span></div>
          <div v-if="partMeta.transparent" class="flex justify-between"><span class="text-gray-500">Transparent</span><span class="text-teal-300">Yes</span></div>
        </div>
      </section>
    </template>
    <div v-else class="flex h-full items-center justify-center text-xs text-gray-500">
      No submesh selected
    </div>
  </div>
</template>

<script setup>
import { computed, reactive, watch } from 'vue'
import { classifyPart } from '../../lib/submesh-inspect.js'

const props = defineProps({
  selectedIndex: { type: Number, default: -1 },
  partMeta: { type: Object, default: null },
  partGroup: { type: Object, default: null },
})

const axes = ['x', 'y', 'z']

const position = reactive({ x: 0, y: 0, z: 0 })
const rotation = reactive({ x: 0, y: 0, z: 0 })
const scale = reactive({ x: 1, y: 1, z: 1 })

const RAD2DEG = 180 / Math.PI
const DEG2RAD = Math.PI / 180

function syncFromGroup() {
  const g = props.partGroup
  if (!g) return
  position.x = round4(g.position?.x ?? 0)
  position.y = round4(g.position?.y ?? 0)
  position.z = round4(g.position?.z ?? 0)
  rotation.x = round2((g.rotation?.x ?? 0) * RAD2DEG)
  rotation.y = round2((g.rotation?.y ?? 0) * RAD2DEG)
  rotation.z = round2((g.rotation?.z ?? 0) * RAD2DEG)
  scale.x = round4(g.scale?.x ?? 1)
  scale.y = round4(g.scale?.y ?? 1)
  scale.z = round4(g.scale?.z ?? 1)
}

watch(() => [props.selectedIndex, props.partGroup], syncFromGroup, { immediate: true })

function onPositionChange(axis, event) {
  const val = parseFloat(event.target.value)
  if (Number.isFinite(val) && props.partGroup?.position) {
    props.partGroup.position[axis] = val
    position[axis] = val
  }
}

function onRotationChange(axis, event) {
  const val = parseFloat(event.target.value)
  if (Number.isFinite(val) && props.partGroup?.rotation) {
    props.partGroup.rotation[axis] = val * DEG2RAD
    rotation[axis] = val
  }
}

function onScaleChange(axis, event) {
  const val = parseFloat(event.target.value)
  if (Number.isFinite(val) && props.partGroup?.scale) {
    props.partGroup.scale[axis] = val
    scale[axis] = val
  }
}

const stats = computed(() => {
  let vertices = 0
  let faces = 0
  props.partGroup?.traverse?.(c => {
    if (c.isMesh && c.geometry) {
      const pos = c.geometry.getAttribute('position')
      if (pos) vertices += pos.count
      const idx = c.geometry.index
      faces += idx ? idx.count / 3 : (pos ? pos.count / 3 : 0)
    }
  })
  return { vertices, faces }
})

const classification = computed(() => props.partMeta ? classifyPart(props.partMeta) : '-')

const bbox = computed(() => {
  const bb = props.partMeta?.decoded_bbox
  if (!bb || bb.length < 6) return null
  return {
    minX: bb[0], minY: bb[1], minZ: bb[2],
    maxX: bb[3], maxY: bb[4], maxZ: bb[5],
  }
})

const bboxDisplay = computed(() => {
  if (!bbox.value) return {}
  const b = bbox.value
  return {
    W: (b.maxX - b.minX).toFixed(2),
    H: (b.maxY - b.minY).toFixed(2),
    D: (b.maxZ - b.minZ).toFixed(2),
  }
})

function fmtNum(n) {
  return n == null ? '0' : Math.round(n).toLocaleString()
}

function round4(v) {
  return Math.round(v * 10000) / 10000
}

function round2(v) {
  return Math.round(v * 100) / 100
}
</script>
