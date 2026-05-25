<template>
  <div class="flex h-full flex-col overflow-auto p-3 text-xs text-gray-300">
    <label class="mb-1 block text-[11px] text-gray-500">Character</label>
    <select
      v-model="selectedSlug"
      class="mb-3 w-full rounded border border-gray-700 bg-gray-800 px-2 py-1.5 text-xs text-gray-200"
      @change="onCharacterChange"
    >
      <option value="">-- Select --</option>
      <option v-for="a in animStore.animList" :key="a.slug" :value="a.slug">
        {{ a.display_name || a.slug }}
      </option>
    </select>

    <template v-if="clips.length > 0">
      <label class="mb-1 block text-[11px] text-gray-500">Clip</label>
      <select
        v-model="selectedClipIndex"
        class="mb-3 w-full rounded border border-gray-700 bg-gray-800 px-2 py-1.5 text-xs text-gray-200"
      >
        <option v-for="(c, i) in clips" :key="i" :value="i">
          {{ c.display_name || c.name || `Clip ${i}` }}
        </option>
      </select>

      <div class="mb-3 flex items-center gap-2">
        <button
          class="rounded bg-blue-700 px-2 py-1 text-[11px] font-medium text-white hover:bg-blue-600"
          @click="onPlay"
        >Play</button>
        <button
          class="rounded bg-gray-700 px-2 py-1 text-[11px] font-medium text-gray-200 hover:bg-gray-600"
          @click="onPause"
        >Pause</button>
        <button
          class="rounded bg-gray-700 px-2 py-1 text-[11px] font-medium text-gray-200 hover:bg-gray-600"
          @click="onStop"
        >Stop</button>
      </div>

      <label class="mb-1 block text-[11px] text-gray-500">Scrub</label>
      <input
        type="range"
        min="0"
        max="1"
        step="0.001"
        :value="scrubValue"
        class="mb-3 w-full"
        @input="onScrub"
      />

      <label class="mb-1 block text-[11px] text-gray-500">
        Speed: {{ playbackSpeed.toFixed(1) }}x
      </label>
      <input
        type="range"
        min="0.1"
        max="3.0"
        step="0.1"
        v-model.number="playbackSpeed"
        class="mb-3 w-full"
        @input="onSpeedChange"
      />

      <label class="mb-3 flex items-center gap-2 text-[11px] text-gray-400">
        <input type="checkbox" v-model="showSkeleton" @change="onToggleSkeleton" />
        Show Skeleton
      </label>
    </template>

    <div v-if="animInfo" class="mt-auto border-t border-gray-800 pt-2 text-[10px] text-gray-500">
      <div>Bones: {{ animInfo.boneCount }}</div>
      <div>Skinned verts: {{ animInfo.skinnedVertCount.toLocaleString() }}</div>
      <div>Skeleton: {{ animInfo.skeletonStatus }}</div>
      <div v-if="clips.length">Clips: {{ clips.length }}</div>
    </div>

    <div v-if="animStore.loading" class="mt-2 text-[10px] text-gray-500">Loading...</div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, watch } from 'vue'
import { useAnimationsStore } from '../../stores/animations.js'

const props = defineProps({
  viewer: { type: Object, default: null },
})

const animStore = useAnimationsStore()

const selectedSlug = ref('')
const selectedClipIndex = ref(0)
const clips = ref([])
const animInfo = ref(null)
const scrubValue = ref(0)
const playbackSpeed = ref(1.0)
const showSkeleton = ref(false)

let frameCallback = null

onMounted(() => {
  animStore.fetchAnimIndex()

  frameCallback = ({ time, duration }) => {
    if (duration > 0) {
      scrubValue.value = (time % duration) / duration
    }
  }
  props.viewer?.onAnimFrame?.(frameCallback)
})

onBeforeUnmount(() => {
  if (frameCallback) {
    props.viewer?.removeAnimFrameCallback?.(frameCallback)
  }
})

async function onCharacterChange() {
  clips.value = []
  animInfo.value = null
  selectedClipIndex.value = 0
  scrubValue.value = 0

  if (!selectedSlug.value || !props.viewer) return

  const detail = await animStore.fetchAnimDetail(selectedSlug.value)
  if (!detail?.glb_url) return

  const result = await props.viewer.loadAnimGltf(detail.glb_url)
  animInfo.value = result
  clips.value = result.clips.map((c, i) => ({
    name: c.name,
    display_name: detail.clips?.[i]?.display_name || c.name,
  }))

  animStore.currentSlug = selectedSlug.value
}

function onPlay() {
  props.viewer?.playClip?.(selectedClipIndex.value)
  animStore.isPlaying = true
}

function onPause() {
  props.viewer?.pauseAnim?.()
  animStore.isPlaying = false
}

function onStop() {
  props.viewer?.stopAnim?.()
  animStore.isPlaying = false
  scrubValue.value = 0
}

function onScrub(e) {
  const val = parseFloat(e.target.value)
  scrubValue.value = val
  props.viewer?.setAnimTime?.(val)
}

function onSpeedChange() {
  props.viewer?.setAnimSpeed?.(playbackSpeed.value)
  animStore.playbackSpeed = playbackSpeed.value
}

function onToggleSkeleton() {
  props.viewer?.toggleAnimSkeleton?.(showSkeleton.value)
}

watch(selectedClipIndex, (idx) => {
  animStore.currentClipIndex = idx
})
</script>
