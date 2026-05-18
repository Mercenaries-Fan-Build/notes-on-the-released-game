<template>
  <div class="flex h-full bg-gray-950">
    <!-- Left Sidebar — Entity List -->
    <aside class="flex w-[250px] shrink-0 flex-col overflow-y-auto border-r border-gray-800 bg-gray-900">
      <div class="border-b border-gray-800 px-3 py-2.5">
        <h1 class="text-sm font-semibold text-gray-100">Zone Editor</h1>
        <p class="mt-0.5 text-[10px] text-gray-500">Draw zones, splines &amp; spawners</p>
      </div>

      <!-- Zones Section -->
      <CollapsibleSection title="Zones" :count="zones.length" :loading="loadingZones">
        <div
          v-for="z in zones"
          :key="'z-' + z.id"
          class="group flex cursor-pointer items-center gap-2 rounded px-2 py-1.5 text-xs transition-colors"
          :class="selectedItem?.type === 'zone' && selectedItem.id === z.id ? 'bg-gray-700/60 text-white' : 'text-gray-300 hover:bg-gray-800'"
          @click="selectEntity('zone', z)"
        >
          <span class="h-2.5 w-2.5 shrink-0 rounded-sm" :style="{ background: z.color_hex || '#6366f1' }" />
          <span class="truncate">{{ z.name || 'Unnamed zone' }}</span>
          <span class="ml-auto text-[10px] text-gray-500">{{ z.zone_type || '' }}</span>
        </div>
        <div v-if="!loadingZones && !zones.length" class="px-2 py-2 text-[10px] text-gray-600">No zones yet</div>
        <template #footer>
          <button class="w-full rounded bg-indigo-600 px-2 py-1.5 text-[11px] font-medium text-white transition-colors hover:bg-indigo-500" @click="startDrawing('polygon')">
            + New Zone
          </button>
        </template>
      </CollapsibleSection>

      <!-- Splines Section -->
      <CollapsibleSection title="Splines" :count="splines.length" :loading="loadingSplines">
        <div
          v-for="s in splines"
          :key="'s-' + s.id"
          class="group flex cursor-pointer items-center gap-2 rounded px-2 py-1.5 text-xs transition-colors"
          :class="selectedItem?.type === 'spline' && selectedItem.id === s.id ? 'bg-gray-700/60 text-white' : 'text-gray-300 hover:bg-gray-800'"
          @click="selectEntity('spline', s)"
        >
          <span class="h-0.5 w-3 shrink-0 rounded" :style="{ background: s.color_hex || '#f59e0b' }" />
          <span class="truncate">{{ s.name || 'Unnamed spline' }}</span>
          <span class="ml-auto text-[10px] text-gray-500">{{ s.spline_type || '' }}</span>
        </div>
        <div v-if="!loadingSplines && !splines.length" class="px-2 py-2 text-[10px] text-gray-600">No splines yet</div>
        <template #footer>
          <button class="w-full rounded bg-indigo-600 px-2 py-1.5 text-[11px] font-medium text-white transition-colors hover:bg-indigo-500" @click="startDrawing('line')">
            + New Spline
          </button>
        </template>
      </CollapsibleSection>

      <!-- Spawners Section -->
      <CollapsibleSection title="Spawners" :count="spawners.length" :loading="loadingSpawners">
        <div
          v-for="sp in spawners"
          :key="'sp-' + sp.id"
          class="group flex cursor-pointer items-center gap-2 rounded px-2 py-1.5 text-xs transition-colors"
          :class="selectedItem?.type === 'spawner' && selectedItem.id === sp.id ? 'bg-gray-700/60 text-white' : 'text-gray-300 hover:bg-gray-800'"
          @click="selectEntity('spawner', sp)"
        >
          <span class="flex h-3 w-3 shrink-0 items-center justify-center rounded-full border border-gray-500 text-[7px] text-gray-400">S</span>
          <span class="truncate">{{ sp.name || 'Unnamed spawner' }}</span>
          <span class="ml-auto text-[10px] text-gray-500">{{ sp.spawner_type || '' }}</span>
        </div>
        <div v-if="!loadingSpawners && !spawners.length" class="px-2 py-2 text-[10px] text-gray-600">No spawners yet</div>
        <template #footer>
          <button class="w-full rounded bg-indigo-600 px-2 py-1.5 text-[11px] font-medium text-white transition-colors hover:bg-indigo-500" @click="startDrawing('point')">
            + New Spawner
          </button>
        </template>
      </CollapsibleSection>
    </aside>

    <!-- Center — Canvas + Toolbar -->
    <div class="flex flex-1 flex-col min-w-0">
      <!-- Toolbar -->
      <div class="flex items-center gap-1 border-b border-gray-800 bg-gray-900 px-2 py-1.5">
        <ToolButton icon="hand" label="Pan" :active="activeTool === 'pan'" @click="activeTool = 'pan'" />
        <ToolButton icon="cursor" label="Select" :active="activeTool === 'select'" @click="activeTool = 'select'" />
        <div class="mx-1 h-4 w-px bg-gray-700" />
        <ToolButton icon="polygon" label="Polygon" :active="activeTool === 'polygon'" @click="startDrawing('polygon')" />
        <ToolButton icon="line" label="Line" :active="activeTool === 'line'" @click="startDrawing('line')" />
        <ToolButton icon="point" label="Point" :active="activeTool === 'point'" @click="startDrawing('point')" />
        <div class="mx-1 h-4 w-px bg-gray-700" />
        <span class="ml-2 text-[10px] text-gray-500">
          <template v-if="activeTool === 'polygon'">Click to place vertices, double-click to close polygon</template>
          <template v-else-if="activeTool === 'line'">Click to place waypoints, double-click to finish</template>
          <template v-else-if="activeTool === 'point'">Click to place spawner</template>
          <template v-else-if="activeTool === 'select'">Click to select entities</template>
          <template v-else>Drag to pan, scroll to zoom</template>
        </span>
        <span class="ml-auto text-[10px] text-gray-600">
          {{ cursorWorld.x.toFixed(1) }}, {{ cursorWorld.z.toFixed(1) }} &middot; zoom {{ camera.zoom.toFixed(2) }}x
        </span>
      </div>

      <!-- Canvas -->
      <canvas
        ref="canvasEl"
        class="flex-1"
        :class="canvasCursor"
        @mousedown="onMouseDown"
        @mousemove="onMouseMove"
        @mouseup="onMouseUp"
        @wheel.prevent="onWheel"
        @click="onCanvasClick"
        @dblclick="onCanvasDblClick"
        @contextmenu.prevent="cancelDrawing"
      />
    </div>

    <!-- Right Sidebar — Properties Panel -->
    <aside
      v-if="selectedItem"
      class="flex w-[250px] shrink-0 flex-col overflow-y-auto border-l border-gray-800 bg-gray-900"
    >
      <div class="flex items-center justify-between border-b border-gray-800 px-3 py-2.5">
        <h2 class="text-xs font-semibold text-gray-200">
          {{ selectedItem.type === 'zone' ? 'Zone' : selectedItem.type === 'spline' ? 'Spline' : 'Spawner' }} Properties
        </h2>
        <button class="text-gray-500 transition-colors hover:text-gray-300" @click="selectedItem = null">&times;</button>
      </div>
      <div class="flex-1 space-y-3 p-3">
        <!-- Zone Properties -->
        <template v-if="selectedItem.type === 'zone'">
          <FormField label="Name">
            <input v-model="editForm.name" type="text" class="form-input" />
          </FormField>
          <FormField label="Zone Type">
            <select v-model="editForm.zone_type" class="form-input">
              <option value="">—</option>
              <option v-for="t in ZONE_TYPES" :key="t" :value="t">{{ t }}</option>
            </select>
          </FormField>
          <FormField label="Faction">
            <select v-model="editForm.faction_id" class="form-input">
              <option :value="null">None</option>
              <option v-for="f in factions" :key="f.id" :value="f.id">{{ f.name }}</option>
            </select>
          </FormField>
          <FormField label="Act">
            <input v-model="editForm.act" type="text" class="form-input" />
          </FormField>
          <FormField label="Color">
            <div class="flex items-center gap-2">
              <input v-model="editForm.color_hex" type="color" class="h-8 w-10 cursor-pointer rounded border border-gray-700 bg-gray-800" />
              <input v-model="editForm.color_hex" type="text" class="form-input flex-1" placeholder="#6366f1" />
            </div>
          </FormField>
          <FormField label="Opacity">
            <div class="flex items-center gap-2">
              <input v-model.number="editForm.opacity" type="range" min="0" max="1" step="0.05" class="flex-1" />
              <span class="w-8 text-right text-[10px] text-gray-400">{{ (editForm.opacity ?? 0.3).toFixed(2) }}</span>
            </div>
          </FormField>
          <div class="grid grid-cols-2 gap-2">
            <FormField label="Min Elevation">
              <input v-model.number="editForm.min_elevation" type="number" class="form-input" />
            </FormField>
            <FormField label="Max Elevation">
              <input v-model.number="editForm.max_elevation" type="number" class="form-input" />
            </FormField>
          </div>
          <FormField label="Active">
            <label class="flex items-center gap-2 text-xs text-gray-300">
              <input v-model="editForm.is_active" type="checkbox" class="accent-indigo-500" />
              <span>{{ editForm.is_active ? 'Yes' : 'No' }}</span>
            </label>
          </FormField>
          <FormField label="Description">
            <textarea v-model="editForm.description" rows="3" class="form-input resize-y" />
          </FormField>
        </template>

        <!-- Spline Properties -->
        <template v-else-if="selectedItem.type === 'spline'">
          <FormField label="Name">
            <input v-model="editForm.name" type="text" class="form-input" />
          </FormField>
          <FormField label="Spline Type">
            <select v-model="editForm.spline_type" class="form-input">
              <option value="">—</option>
              <option v-for="t in SPLINE_TYPES" :key="t" :value="t">{{ t }}</option>
            </select>
          </FormField>
          <FormField label="Zone">
            <select v-model="editForm.zone_id" class="form-input">
              <option :value="null">None</option>
              <option v-for="z in zones" :key="z.id" :value="z.id">{{ z.name || 'Zone ' + z.id }}</option>
            </select>
          </FormField>
          <FormField label="Faction">
            <select v-model="editForm.faction_id" class="form-input">
              <option :value="null">None</option>
              <option v-for="f in factions" :key="f.id" :value="f.id">{{ f.name }}</option>
            </select>
          </FormField>
          <FormField label="Loop">
            <label class="flex items-center gap-2 text-xs text-gray-300">
              <input v-model="editForm.is_loop" type="checkbox" class="accent-indigo-500" />
              <span>{{ editForm.is_loop ? 'Yes' : 'No' }}</span>
            </label>
          </FormField>
          <FormField label="Color">
            <div class="flex items-center gap-2">
              <input v-model="editForm.color_hex" type="color" class="h-8 w-10 cursor-pointer rounded border border-gray-700 bg-gray-800" />
              <input v-model="editForm.color_hex" type="text" class="form-input flex-1" placeholder="#f59e0b" />
            </div>
          </FormField>
          <FormField label="Description">
            <textarea v-model="editForm.description" rows="3" class="form-input resize-y" />
          </FormField>
          <FormField label="Properties (JSON)">
            <textarea v-model="editForm.properties_json" rows="4" class="form-input resize-y font-mono text-[10px]" placeholder='{"speed_limit": 60}' />
          </FormField>
        </template>

        <!-- Spawner Properties -->
        <template v-else-if="selectedItem.type === 'spawner'">
          <FormField label="Name">
            <input v-model="editForm.name" type="text" class="form-input" />
          </FormField>
          <FormField label="Spawner Type">
            <select v-model="editForm.spawner_type" class="form-input">
              <option value="">—</option>
              <option v-for="t in SPAWNER_TYPES" :key="t" :value="t">{{ t }}</option>
            </select>
          </FormField>
          <FormField label="Zone">
            <select v-model="editForm.zone_id" class="form-input">
              <option :value="null">None</option>
              <option v-for="z in zones" :key="z.id" :value="z.id">{{ z.name || 'Zone ' + z.id }}</option>
            </select>
          </FormField>
          <FormField label="Faction">
            <select v-model="editForm.faction_id" class="form-input">
              <option :value="null">None</option>
              <option v-for="f in factions" :key="f.id" :value="f.id">{{ f.name }}</option>
            </select>
          </FormField>
          <div class="grid grid-cols-3 gap-1">
            <FormField label="X">
              <input :value="editForm.pos_x?.toFixed(1)" type="text" class="form-input" disabled />
            </FormField>
            <FormField label="Y">
              <input v-model.number="editForm.pos_y" type="number" class="form-input" placeholder="0" />
            </FormField>
            <FormField label="Z">
              <input :value="editForm.pos_z?.toFixed(1)" type="text" class="form-input" disabled />
            </FormField>
          </div>
          <FormField label="Radius">
            <div class="flex items-center gap-2">
              <input v-model.number="editForm.radius" type="range" min="0" max="500" step="5" class="flex-1" />
              <span class="w-10 text-right text-[10px] text-gray-400">{{ editForm.radius ?? 0 }}m</span>
            </div>
          </FormField>
          <FormField label="Spawn Count">
            <input v-model.number="editForm.spawn_count" type="number" min="0" class="form-input" />
          </FormField>
          <FormField label="Respawn Time (s)">
            <input v-model.number="editForm.respawn_time" type="number" min="0" step="0.5" class="form-input" />
          </FormField>
          <FormField label="Patrol Spline">
            <select v-model="editForm.patrol_spline_id" class="form-input">
              <option :value="null">None</option>
              <option v-for="s in splines" :key="s.id" :value="s.id">{{ s.name || 'Spline ' + s.id }}</option>
            </select>
          </FormField>
          <FormField label="Properties (JSON)">
            <textarea v-model="editForm.properties_json" rows="4" class="form-input resize-y font-mono text-[10px]" placeholder='{"difficulty": "hard"}' />
          </FormField>
        </template>
      </div>

      <!-- Save / Delete -->
      <div class="border-t border-gray-800 p-3 space-y-2">
        <div v-if="saveError" class="rounded border border-red-800 bg-red-900/20 p-2 text-[10px] text-red-300">{{ saveError }}</div>
        <button
          class="w-full rounded bg-indigo-600 py-1.5 text-xs font-medium text-white transition-colors hover:bg-indigo-500 disabled:opacity-50"
          :disabled="saving"
          @click="saveEntity"
        >
          {{ saving ? 'Saving...' : (selectedItem.data?.id ? 'Update' : 'Create') }}
        </button>
        <button
          v-if="selectedItem.data?.id"
          class="w-full rounded border border-red-700 bg-red-900/20 py-1.5 text-xs font-medium text-red-300 transition-colors hover:bg-red-900/40 disabled:opacity-50"
          :disabled="saving"
          @click="deleteEntity"
        >
          Delete
        </button>
      </div>
    </aside>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onBeforeUnmount, watch, nextTick } from 'vue'

// ─── Constants ───────────────────────────────────────────────────────────────

const WORLD_MIN = -4000
const WORLD_MAX = 4000
const ZONE_TYPES = ['city', 'district', 'mission_boundary', 'demo_space', 'faction_territory', 'ambient_region', 'restricted', 'water', 'custom']
const SPLINE_TYPES = ['patrol_path', 'road_spline', 'mission_route', 'vehicle_path', 'flight_path', 'river', 'custom']
const SPAWNER_TYPES = ['npc', 'vehicle', 'pickup', 'ambient', 'mission', 'custom']

// ─── State ───────────────────────────────────────────────────────────────────

const canvasEl = ref(null)
const zones = ref([])
const splines = ref([])
const spawners = ref([])
const factions = ref([])
const placements = ref([])
const loadingZones = ref(false)
const loadingSplines = ref(false)
const loadingSpawners = ref(false)
const loadingPlacements = ref(false)
const saving = ref(false)
const saveError = ref('')

const activeTool = ref('pan')
const selectedItem = ref(null)
const editForm = reactive({})
const drawingVertices = ref([])

const camera = reactive({ panX: 0, panY: 0, zoom: 0.08 })
const cursorWorld = reactive({ x: 0, z: 0 })
let dragging = false
let dragStart = null
let panStart = null
let animFrame = null

const canvasCursor = computed(() => {
  if (activeTool.value === 'pan') return 'cursor-grab'
  if (activeTool.value === 'select') return 'cursor-pointer'
  return 'cursor-crosshair'
})

// ─── Inline Sub-components ───────────────────────────────────────────────────

const CollapsibleSection = {
  props: { title: String, count: Number, loading: Boolean },
  data: () => ({ open: true }),
  template: `
    <div class="border-b border-gray-800">
      <button class="flex w-full items-center gap-1.5 px-3 py-2 text-[11px] font-semibold uppercase tracking-wide text-gray-500 transition-colors hover:text-gray-300" @click="open = !open">
        <span class="text-[9px] transition-transform" :class="open ? 'rotate-90' : ''">&#9654;</span>
        {{ title }}
        <span class="ml-auto rounded-full bg-gray-800 px-1.5 py-0.5 text-[9px] font-medium text-gray-500">{{ loading ? '...' : count }}</span>
      </button>
      <div v-show="open" class="max-h-[200px] overflow-y-auto px-1 pb-1">
        <slot />
      </div>
      <div v-show="open" class="px-2 pb-2">
        <slot name="footer" />
      </div>
    </div>
  `
}

const ToolButton = {
  props: { icon: String, label: String, active: Boolean },
  emits: ['click'],
  template: `
    <button
      class="flex items-center gap-1 rounded px-2 py-1 text-[11px] font-medium transition-colors"
      :class="active ? 'bg-indigo-600 text-white' : 'text-gray-400 hover:bg-gray-800 hover:text-gray-200'"
      @click="$emit('click')"
      :title="label"
    >
      <svg v-if="icon === 'hand'" class="h-3.5 w-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 11V6a2 2 0 10-4 0v1M14 10V4a2 2 0 10-4 0v6M10 10V6a2 2 0 10-4 0v8c0 5 4 7 8 7 4.5 0 8-2.5 8-7v-4a2 2 0 10-4 0"/></svg>
      <svg v-else-if="icon === 'cursor'" class="h-3.5 w-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 3l7.07 16.97 2.51-7.39 7.39-2.51L3 3z"/></svg>
      <svg v-else-if="icon === 'polygon'" class="h-3.5 w-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="12 2 22 8.5 22 15.5 12 22 2 15.5 2 8.5"/></svg>
      <svg v-else-if="icon === 'line'" class="h-3.5 w-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="5" y1="19" x2="19" y2="5"/><circle cx="5" cy="19" r="2"/><circle cx="19" cy="5" r="2"/></svg>
      <svg v-else-if="icon === 'point'" class="h-3.5 w-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><circle cx="12" cy="12" r="8"/></svg>
      <span>{{ label }}</span>
    </button>
  `
}

const FormField = {
  props: { label: String },
  template: `
    <label class="block">
      <span class="mb-0.5 block text-[10px] font-medium text-gray-500">{{ label }}</span>
      <slot />
    </label>
  `
}

// ─── Coordinate Transforms ───────────────────────────────────────────────────

function worldToScreen(wx, wz) {
  const canvas = canvasEl.value
  if (!canvas) return { x: 0, y: 0 }
  const cx = canvas.width / 2
  const cy = canvas.height / 2
  return {
    x: cx + (wx * camera.zoom) + camera.panX,
    y: cy - (wz * camera.zoom) + camera.panY,
  }
}

function screenToWorld(sx, sy) {
  const canvas = canvasEl.value
  if (!canvas) return { x: 0, z: 0 }
  const cx = canvas.width / 2
  const cy = canvas.height / 2
  return {
    x: (sx - cx - camera.panX) / camera.zoom,
    z: -(sy - cy - camera.panY) / camera.zoom,
  }
}

function canvasCoords(e) {
  const canvas = canvasEl.value
  const rect = canvas.getBoundingClientRect()
  return {
    sx: ((e.clientX - rect.left) / rect.width) * canvas.width,
    sy: ((e.clientY - rect.top) / rect.height) * canvas.height,
  }
}

// ─── Drawing ─────────────────────────────────────────────────────────────────

function draw() {
  const canvas = canvasEl.value
  if (!canvas) return
  const ctx = canvas.getContext('2d')
  const w = canvas.width
  const h = canvas.height

  ctx.fillStyle = '#0a0a0f'
  ctx.fillRect(0, 0, w, h)

  drawGrid(ctx, w, h)
  drawPlacements(ctx)
  drawZones(ctx)
  drawSplines(ctx)
  drawSpawners(ctx)
  drawDrawingState(ctx)
  drawAxisLabels(ctx, w, h)
}

function drawGrid(ctx, w, h) {
  const intervals = [
    { step: 1000, color: 'rgba(255,255,255,0.08)', width: 1 },
    { step: 500, color: 'rgba(255,255,255,0.03)', width: 0.5 },
  ]

  for (const { step, color, width } of intervals) {
    ctx.strokeStyle = color
    ctx.lineWidth = width

    for (let v = Math.ceil(WORLD_MIN / step) * step; v <= WORLD_MAX; v += step) {
      const p1 = worldToScreen(v, WORLD_MIN)
      const p2 = worldToScreen(v, WORLD_MAX)
      ctx.beginPath()
      ctx.moveTo(p1.x, p1.y)
      ctx.lineTo(p2.x, p2.y)
      ctx.stroke()

      const q1 = worldToScreen(WORLD_MIN, v)
      const q2 = worldToScreen(WORLD_MAX, v)
      ctx.beginPath()
      ctx.moveTo(q1.x, q1.y)
      ctx.lineTo(q2.x, q2.y)
      ctx.stroke()
    }
  }

  // Axis lines
  const ox = worldToScreen(0, WORLD_MIN)
  const ox2 = worldToScreen(0, WORLD_MAX)
  const oz = worldToScreen(WORLD_MIN, 0)
  const oz2 = worldToScreen(WORLD_MAX, 0)

  ctx.strokeStyle = 'rgba(239,68,68,0.4)'
  ctx.lineWidth = 1.5
  ctx.beginPath()
  ctx.moveTo(ox.x, ox.y)
  ctx.lineTo(ox2.x, ox2.y)
  ctx.stroke()

  ctx.strokeStyle = 'rgba(59,130,246,0.4)'
  ctx.beginPath()
  ctx.moveTo(oz.x, oz.y)
  ctx.lineTo(oz2.x, oz2.y)
  ctx.stroke()
}

function drawAxisLabels(ctx, w, h) {
  ctx.font = '10px system-ui, sans-serif'
  ctx.fillStyle = '#6b7280'

  const step = 1000
  for (let v = Math.ceil(WORLD_MIN / step) * step; v <= WORLD_MAX; v += step) {
    if (v === 0) continue
    const px = worldToScreen(v, 0)
    if (px.x > 30 && px.x < w - 30) {
      ctx.fillText(`${v}`, px.x + 2, px.y - 4)
    }
    const pz = worldToScreen(0, v)
    if (pz.y > 15 && pz.y < h - 10) {
      ctx.fillText(`${v}`, pz.x + 4, pz.y - 2)
    }
  }

  const origin = worldToScreen(0, 0)
  ctx.fillStyle = '#9ca3af'
  ctx.fillText('0,0', origin.x + 4, origin.y - 4)
}

function drawPlacements(ctx) {
  if (!placements.value.length) return
  ctx.fillStyle = 'rgba(120,120,140,0.25)'
  for (const p of placements.value) {
    const { x, y } = worldToScreen(p.x, p.z)
    ctx.fillRect(x - 0.5, y - 0.5, 1, 1)
  }
}

function drawZones(ctx) {
  for (const zone of zones.value) {
    const coords = zone._coords
    if (!coords || coords.length < 3) continue

    const isSelected = selectedItem.value?.type === 'zone' && selectedItem.value.id === zone.id
    const color = zone.color_hex || '#6366f1'
    const opacity = zone.opacity ?? 0.3

    ctx.beginPath()
    for (let i = 0; i < coords.length; i++) {
      const { x, y } = worldToScreen(coords[i][0], coords[i][1])
      if (i === 0) ctx.moveTo(x, y)
      else ctx.lineTo(x, y)
    }
    ctx.closePath()

    ctx.fillStyle = hexToRgba(color, opacity)
    ctx.fill()

    ctx.strokeStyle = isSelected ? '#ffffff' : color
    ctx.lineWidth = isSelected ? 2 : 1
    ctx.stroke()

    // Label
    const centroid = polygonCentroid(coords)
    const labelPos = worldToScreen(centroid[0], centroid[1])
    ctx.font = `${isSelected ? 'bold ' : ''}11px system-ui, sans-serif`
    ctx.fillStyle = '#e5e7eb'
    ctx.textAlign = 'center'
    ctx.fillText(zone.name || 'Zone', labelPos.x, labelPos.y + 4)
    ctx.textAlign = 'start'

    if (isSelected) {
      for (const c of coords) {
        const { x, y } = worldToScreen(c[0], c[1])
        ctx.fillStyle = '#ffffff'
        ctx.fillRect(x - 3, y - 3, 6, 6)
        ctx.strokeStyle = color
        ctx.lineWidth = 1
        ctx.strokeRect(x - 3, y - 3, 6, 6)
      }
    }
  }
}

function drawSplines(ctx) {
  for (const spline of splines.value) {
    const coords = spline._coords
    if (!coords || coords.length < 2) continue

    const isSelected = selectedItem.value?.type === 'spline' && selectedItem.value.id === spline.id
    const color = spline.color_hex || '#f59e0b'

    ctx.beginPath()
    for (let i = 0; i < coords.length; i++) {
      const { x, y } = worldToScreen(coords[i][0], coords[i][1])
      if (i === 0) ctx.moveTo(x, y)
      else ctx.lineTo(x, y)
    }
    if (spline.is_loop && coords.length > 2) ctx.closePath()

    ctx.strokeStyle = isSelected ? '#ffffff' : color
    ctx.lineWidth = isSelected ? 3 : 2
    ctx.stroke()

    // Direction arrows every few segments
    for (let i = 0; i < coords.length - 1; i += Math.max(1, Math.floor(coords.length / 5))) {
      const from = worldToScreen(coords[i][0], coords[i][1])
      const to = worldToScreen(coords[i + 1][0], coords[i + 1][1])
      const mx = (from.x + to.x) / 2
      const my = (from.y + to.y) / 2
      const angle = Math.atan2(to.y - from.y, to.x - from.x)
      const sz = 6
      ctx.fillStyle = color
      ctx.beginPath()
      ctx.moveTo(mx + Math.cos(angle) * sz, my + Math.sin(angle) * sz)
      ctx.lineTo(mx + Math.cos(angle + 2.5) * sz, my + Math.sin(angle + 2.5) * sz)
      ctx.lineTo(mx + Math.cos(angle - 2.5) * sz, my + Math.sin(angle - 2.5) * sz)
      ctx.closePath()
      ctx.fill()
    }

    // Label at midpoint
    if (coords.length >= 2) {
      const mid = Math.floor(coords.length / 2)
      const lp = worldToScreen(coords[mid][0], coords[mid][1])
      ctx.font = '10px system-ui, sans-serif'
      ctx.fillStyle = '#e5e7eb'
      ctx.fillText(spline.name || 'Spline', lp.x + 6, lp.y - 4)
    }

    if (isSelected) {
      for (const c of coords) {
        const { x, y } = worldToScreen(c[0], c[1])
        ctx.fillStyle = '#ffffff'
        ctx.fillRect(x - 3, y - 3, 6, 6)
        ctx.strokeStyle = color
        ctx.lineWidth = 1
        ctx.strokeRect(x - 3, y - 3, 6, 6)
      }
    }
  }
}

function drawSpawners(ctx) {
  for (const sp of spawners.value) {
    if (sp.pos_x == null || sp.pos_z == null) continue
    const { x, y } = worldToScreen(sp.pos_x, sp.pos_z)
    const isSelected = selectedItem.value?.type === 'spawner' && selectedItem.value.id === sp.id

    // Radius circle
    if (sp.radius && sp.radius > 0) {
      const edgePt = worldToScreen(sp.pos_x + sp.radius, sp.pos_z)
      const rPx = Math.abs(edgePt.x - x)
      ctx.beginPath()
      ctx.arc(x, y, rPx, 0, Math.PI * 2)
      ctx.fillStyle = 'rgba(168,85,247,0.08)'
      ctx.fill()
      ctx.strokeStyle = 'rgba(168,85,247,0.3)'
      ctx.lineWidth = 1
      ctx.stroke()
    }

    // Marker
    ctx.beginPath()
    ctx.arc(x, y, isSelected ? 7 : 5, 0, Math.PI * 2)
    ctx.fillStyle = isSelected ? '#a855f7' : '#7c3aed'
    ctx.fill()
    ctx.strokeStyle = isSelected ? '#ffffff' : '#a855f7'
    ctx.lineWidth = isSelected ? 2 : 1
    ctx.stroke()

    // Inner dot
    ctx.beginPath()
    ctx.arc(x, y, 2, 0, Math.PI * 2)
    ctx.fillStyle = '#ffffff'
    ctx.fill()

    // Label
    ctx.font = '10px system-ui, sans-serif'
    ctx.fillStyle = '#e5e7eb'
    ctx.fillText(sp.name || 'Spawner', x + 10, y + 3)
  }
}

function drawDrawingState(ctx) {
  const verts = drawingVertices.value
  if (!verts.length) return

  const tool = activeTool.value
  const color = tool === 'polygon' ? '#6366f1' : '#f59e0b'

  // Lines between placed vertices
  if (verts.length >= 2) {
    ctx.beginPath()
    for (let i = 0; i < verts.length; i++) {
      const { x, y } = worldToScreen(verts[i][0], verts[i][1])
      if (i === 0) ctx.moveTo(x, y)
      else ctx.lineTo(x, y)
    }
    ctx.strokeStyle = color
    ctx.lineWidth = 2
    ctx.setLineDash([6, 4])
    ctx.stroke()
    ctx.setLineDash([])
  }

  // Rubber band to cursor
  if (verts.length >= 1 && (tool === 'polygon' || tool === 'line')) {
    const last = verts[verts.length - 1]
    const lastScreen = worldToScreen(last[0], last[1])
    const curScreen = worldToScreen(cursorWorld.x, cursorWorld.z)
    ctx.beginPath()
    ctx.moveTo(lastScreen.x, lastScreen.y)
    ctx.lineTo(curScreen.x, curScreen.y)
    ctx.strokeStyle = 'rgba(255,255,255,0.3)'
    ctx.lineWidth = 1
    ctx.setLineDash([4, 4])
    ctx.stroke()
    ctx.setLineDash([])
  }

  // Vertex handles
  for (const v of verts) {
    const { x, y } = worldToScreen(v[0], v[1])
    ctx.fillStyle = '#ffffff'
    ctx.fillRect(x - 4, y - 4, 8, 8)
    ctx.strokeStyle = color
    ctx.lineWidth = 1.5
    ctx.strokeRect(x - 4, y - 4, 8, 8)
  }
}

// ─── Event Handlers ──────────────────────────────────────────────────────────

function onMouseDown(e) {
  if (activeTool.value === 'pan' || (activeTool.value === 'select' && e.button === 1)) {
    dragging = true
    dragStart = { x: e.clientX, y: e.clientY }
    panStart = { panX: camera.panX, panY: camera.panY }
  }
}

function onMouseMove(e) {
  const { sx, sy } = canvasCoords(e)
  const world = screenToWorld(sx, sy)
  cursorWorld.x = world.x
  cursorWorld.z = world.z

  if (dragging && dragStart && panStart) {
    camera.panX = panStart.panX + (e.clientX - dragStart.x)
    camera.panY = panStart.panY + (e.clientY - dragStart.y)
  }

  requestDraw()
}

function onMouseUp() {
  dragging = false
  dragStart = null
  panStart = null
}

function onWheel(e) {
  const { sx, sy } = canvasCoords(e)
  const before = screenToWorld(sx, sy)
  const factor = e.deltaY > 0 ? 0.9 : 1.1
  camera.zoom = Math.max(0.005, Math.min(2, camera.zoom * factor))
  const after = worldToScreen(before.x, before.z)
  camera.panX += sx - after.x
  camera.panY += sy - after.y
  requestDraw()
}

function onCanvasClick(e) {
  const { sx, sy } = canvasCoords(e)
  const world = screenToWorld(sx, sy)
  const tool = activeTool.value

  if (tool === 'polygon' || tool === 'line') {
    drawingVertices.value.push([world.x, world.z])
    requestDraw()
    return
  }

  if (tool === 'point') {
    finishSpawnerPlacement(world.x, world.z)
    return
  }

  if (tool === 'select') {
    trySelectAt(sx, sy)
  }
}

function onCanvasDblClick(e) {
  const tool = activeTool.value
  if (tool === 'polygon') {
    finishPolygonDrawing()
  } else if (tool === 'line') {
    finishLineDrawing()
  }
}

function cancelDrawing() {
  drawingVertices.value = []
  if (['polygon', 'line', 'point'].includes(activeTool.value)) {
    activeTool.value = 'select'
  }
  requestDraw()
}

function requestDraw() {
  if (animFrame) return
  animFrame = requestAnimationFrame(() => {
    animFrame = null
    draw()
  })
}

// ─── Tool Actions ────────────────────────────────────────────────────────────

function startDrawing(tool) {
  drawingVertices.value = []
  activeTool.value = tool
  if (tool !== 'point') {
    selectedItem.value = null
  }
}

function finishPolygonDrawing() {
  const verts = drawingVertices.value
  if (verts.length < 3) return

  selectedItem.value = {
    type: 'zone',
    id: null,
    data: null,
  }
  Object.assign(editForm, {
    name: '',
    zone_type: 'custom',
    faction_id: null,
    act: '',
    color_hex: '#6366f1',
    opacity: 0.3,
    min_elevation: null,
    max_elevation: null,
    is_active: true,
    description: '',
    geom_coords: [...verts],
  })
  activeTool.value = 'select'
  requestDraw()
}

function finishLineDrawing() {
  const verts = drawingVertices.value
  if (verts.length < 2) return

  selectedItem.value = {
    type: 'spline',
    id: null,
    data: null,
  }
  Object.assign(editForm, {
    name: '',
    spline_type: 'custom',
    zone_id: null,
    faction_id: null,
    is_loop: false,
    color_hex: '#f59e0b',
    description: '',
    properties_json: '',
    geom_coords: [...verts],
  })
  activeTool.value = 'select'
  requestDraw()
}

function finishSpawnerPlacement(wx, wz) {
  selectedItem.value = {
    type: 'spawner',
    id: null,
    data: null,
  }
  Object.assign(editForm, {
    name: '',
    spawner_type: 'custom',
    zone_id: null,
    faction_id: null,
    pos_x: wx,
    pos_y: 0,
    pos_z: wz,
    radius: 50,
    spawn_count: 1,
    respawn_time: 30,
    patrol_spline_id: null,
    properties_json: '',
    geom_coords: [[wx, wz]],
  })
  drawingVertices.value = [[wx, wz]]
  activeTool.value = 'select'
  requestDraw()
}

function trySelectAt(sx, sy) {
  const threshold = 12

  for (const sp of spawners.value) {
    if (sp.pos_x == null || sp.pos_z == null) continue
    const { x, y } = worldToScreen(sp.pos_x, sp.pos_z)
    if (Math.hypot(sx - x, sy - y) < threshold) {
      selectEntity('spawner', sp)
      return
    }
  }

  for (const spline of splines.value) {
    if (!spline._coords || spline._coords.length < 2) continue
    for (let i = 0; i < spline._coords.length - 1; i++) {
      const a = worldToScreen(spline._coords[i][0], spline._coords[i][1])
      const b = worldToScreen(spline._coords[i + 1][0], spline._coords[i + 1][1])
      if (distToSegment(sx, sy, a.x, a.y, b.x, b.y) < threshold) {
        selectEntity('spline', spline)
        return
      }
    }
  }

  for (const zone of zones.value) {
    if (!zone._coords || zone._coords.length < 3) continue
    const screenPoly = zone._coords.map(c => worldToScreen(c[0], c[1]))
    if (pointInPolygon(sx, sy, screenPoly)) {
      selectEntity('zone', zone)
      return
    }
  }

  selectedItem.value = null
  requestDraw()
}

function selectEntity(type, entity) {
  drawingVertices.value = []
  selectedItem.value = { type, id: entity.id, data: entity }

  if (type === 'zone') {
    Object.assign(editForm, {
      name: entity.name || '',
      zone_type: entity.zone_type || '',
      faction_id: entity.faction_id ?? null,
      act: entity.act || '',
      color_hex: entity.color_hex || '#6366f1',
      opacity: entity.opacity ?? 0.3,
      min_elevation: entity.min_elevation ?? null,
      max_elevation: entity.max_elevation ?? null,
      is_active: entity.is_active ?? true,
      description: entity.description || '',
      geom_coords: entity._coords ? [...entity._coords] : [],
    })
  } else if (type === 'spline') {
    Object.assign(editForm, {
      name: entity.name || '',
      spline_type: entity.spline_type || '',
      zone_id: entity.zone_id ?? null,
      faction_id: entity.faction_id ?? null,
      is_loop: entity.is_loop ?? false,
      color_hex: entity.color_hex || '#f59e0b',
      description: entity.description || '',
      properties_json: entity.properties ? JSON.stringify(entity.properties, null, 2) : '',
      geom_coords: entity._coords ? [...entity._coords] : [],
    })
  } else if (type === 'spawner') {
    Object.assign(editForm, {
      name: entity.name || '',
      spawner_type: entity.spawner_type || '',
      zone_id: entity.zone_id ?? null,
      faction_id: entity.faction_id ?? null,
      pos_x: entity.pos_x ?? 0,
      pos_y: entity.pos_y ?? 0,
      pos_z: entity.pos_z ?? 0,
      radius: entity.radius ?? 50,
      spawn_count: entity.spawn_count ?? 1,
      respawn_time: entity.respawn_time ?? 30,
      patrol_spline_id: entity.patrol_spline_id ?? null,
      properties_json: entity.properties ? JSON.stringify(entity.properties, null, 2) : '',
      geom_coords: entity.pos_x != null ? [[entity.pos_x, entity.pos_z]] : [],
    })
  }

  requestDraw()
}

// ─── API ─────────────────────────────────────────────────────────────────────

async function fetchJson(url) {
  const res = await fetch(url)
  if (!res.ok) throw new Error(`${res.status} ${res.statusText}`)
  return res.json()
}

async function loadZones() {
  loadingZones.value = true
  try {
    const data = await fetchJson('/api/zones?limit=500')
    const items = data.items || data
    zones.value = items.map(z => ({
      ...z,
      _coords: parseGeomCoords(z, 'polygon'),
    }))
  } catch { zones.value = [] }
  loadingZones.value = false
}

async function loadSplines() {
  loadingSplines.value = true
  try {
    const data = await fetchJson('/api/splines?limit=500')
    const items = data.items || data
    splines.value = items.map(s => ({
      ...s,
      _coords: parseGeomCoords(s, 'linestring'),
    }))
  } catch { splines.value = [] }
  loadingSplines.value = false
}

async function loadSpawners() {
  loadingSpawners.value = true
  try {
    const data = await fetchJson('/api/spawners?limit=500')
    const items = data.items || data
    spawners.value = items
  } catch { spawners.value = [] }
  loadingSpawners.value = false
}

async function loadFactions() {
  try {
    const data = await fetchJson('/api/factions')
    factions.value = Array.isArray(data) ? data : (data.items || [])
  } catch { factions.value = [] }
}

async function loadPlacements() {
  loadingPlacements.value = true
  try {
    const data = await fetchJson('/api/placements?limit=500')
    const items = data.items || data
    placements.value = items.map(p => ({
      x: p.pos_x ?? p.position?.x ?? 0,
      z: p.pos_z ?? p.position?.z ?? 0,
    })).filter(p => p.x !== 0 || p.z !== 0)
  } catch { placements.value = [] }
  loadingPlacements.value = false
}

function parseGeomCoords(entity, geomType) {
  if (entity.geom_coords && Array.isArray(entity.geom_coords)) {
    return entity.geom_coords
  }
  if (entity.properties?.geom_coords && Array.isArray(entity.properties.geom_coords)) {
    return entity.properties.geom_coords
  }
  return []
}

async function saveEntity() {
  if (!selectedItem.value) return
  saving.value = true
  saveError.value = ''

  try {
    const { type, data } = selectedItem.value
    const isNew = !data?.id
    let url, method, body

    if (type === 'zone') {
      url = isNew ? '/api/zones' : `/api/zones/${data.id}`
      method = isNew ? 'POST' : 'PATCH'
      body = {
        name: editForm.name,
        zone_type: editForm.zone_type || null,
        faction_id: editForm.faction_id || null,
        act: editForm.act || null,
        color_hex: editForm.color_hex || null,
        opacity: editForm.opacity ?? 0.3,
        min_elevation: editForm.min_elevation ?? null,
        max_elevation: editForm.max_elevation ?? null,
        is_active: editForm.is_active ?? true,
        description: editForm.description || null,
        properties: { geom_coords: editForm.geom_coords || [] },
      }
    } else if (type === 'spline') {
      url = isNew ? '/api/splines' : `/api/splines/${data.id}`
      method = isNew ? 'POST' : 'PATCH'
      let props = {}
      if (editForm.properties_json) {
        try { props = JSON.parse(editForm.properties_json) } catch { throw new Error('Invalid JSON in properties') }
      }
      props.geom_coords = editForm.geom_coords || []
      body = {
        name: editForm.name || null,
        spline_type: editForm.spline_type || null,
        zone_id: editForm.zone_id || null,
        faction_id: editForm.faction_id || null,
        is_loop: editForm.is_loop ?? false,
        color_hex: editForm.color_hex || null,
        description: editForm.description || null,
        properties: props,
      }
    } else if (type === 'spawner') {
      url = isNew ? '/api/spawners' : `/api/spawners/${data.id}`
      method = isNew ? 'POST' : 'PATCH'
      let props = {}
      if (editForm.properties_json) {
        try { props = JSON.parse(editForm.properties_json) } catch { throw new Error('Invalid JSON in properties') }
      }
      body = {
        name: editForm.name || null,
        spawner_type: editForm.spawner_type || null,
        zone_id: editForm.zone_id || null,
        faction_id: editForm.faction_id || null,
        pos_x: editForm.pos_x ?? null,
        pos_y: editForm.pos_y ?? null,
        pos_z: editForm.pos_z ?? null,
        radius: editForm.radius ?? null,
        spawn_count: editForm.spawn_count ?? null,
        respawn_time: editForm.respawn_time ?? null,
        patrol_spline_id: editForm.patrol_spline_id || null,
        properties: props,
      }
    }

    const res = await fetch(url, {
      method,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    })
    if (!res.ok) {
      const errData = await res.json().catch(() => ({}))
      throw new Error(errData.detail || `${res.status} ${res.statusText}`)
    }

    const saved = await res.json()
    drawingVertices.value = []

    if (type === 'zone') { await loadZones(); selectEntity('zone', zones.value.find(z => z.id === saved.id) || saved) }
    else if (type === 'spline') { await loadSplines(); selectEntity('spline', splines.value.find(s => s.id === saved.id) || saved) }
    else { await loadSpawners(); selectEntity('spawner', spawners.value.find(s => s.id === saved.id) || saved) }

    requestDraw()
  } catch (e) {
    saveError.value = e.message
  } finally {
    saving.value = false
  }
}

async function deleteEntity() {
  if (!selectedItem.value?.data?.id) return
  if (!confirm(`Delete this ${selectedItem.value.type}?`)) return

  saving.value = true
  saveError.value = ''
  try {
    const { type, data } = selectedItem.value
    const url = `/api/${type}s/${data.id}`
    const res = await fetch(url, { method: 'DELETE' })
    if (!res.ok && res.status !== 204) {
      throw new Error(`Delete failed: ${res.status}`)
    }

    selectedItem.value = null
    drawingVertices.value = []

    if (type === 'zone') await loadZones()
    else if (type === 'spline') await loadSplines()
    else await loadSpawners()

    requestDraw()
  } catch (e) {
    saveError.value = e.message
  } finally {
    saving.value = false
  }
}

// ─── Geometry Helpers ────────────────────────────────────────────────────────

function hexToRgba(hex, alpha) {
  const h = hex.replace('#', '')
  const r = parseInt(h.substring(0, 2), 16) || 0
  const g = parseInt(h.substring(2, 4), 16) || 0
  const b = parseInt(h.substring(4, 6), 16) || 0
  return `rgba(${r},${g},${b},${alpha})`
}

function polygonCentroid(coords) {
  let sx = 0, sz = 0
  for (const [x, z] of coords) { sx += x; sz += z }
  return [sx / coords.length, sz / coords.length]
}

function distToSegment(px, py, ax, ay, bx, by) {
  const dx = bx - ax, dy = by - ay
  const lenSq = dx * dx + dy * dy
  if (lenSq === 0) return Math.hypot(px - ax, py - ay)
  const t = Math.max(0, Math.min(1, ((px - ax) * dx + (py - ay) * dy) / lenSq))
  return Math.hypot(px - (ax + t * dx), py - (ay + t * dy))
}

function pointInPolygon(px, py, poly) {
  let inside = false
  for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    const xi = poly[i].x, yi = poly[i].y
    const xj = poly[j].x, yj = poly[j].y
    if (((yi > py) !== (yj > py)) && (px < (xj - xi) * (py - yi) / (yj - yi) + xi)) {
      inside = !inside
    }
  }
  return inside
}

// ─── Canvas Resize ───────────────────────────────────────────────────────────

function resizeCanvas() {
  const canvas = canvasEl.value
  if (!canvas) return
  const rect = canvas.parentElement.getBoundingClientRect()
  const dpr = window.devicePixelRatio || 1
  canvas.width = Math.floor(rect.width * dpr)
  canvas.height = Math.floor(rect.height * dpr)
  canvas.style.width = rect.width + 'px'
  canvas.style.height = rect.height + 'px'
  const ctx = canvas.getContext('2d')
  ctx.scale(dpr, dpr)
  draw()
}

let resizeObserver = null

// ─── Lifecycle ───────────────────────────────────────────────────────────────

onMounted(async () => {
  await nextTick()
  resizeCanvas()

  resizeObserver = new ResizeObserver(resizeCanvas)
  if (canvasEl.value?.parentElement) {
    resizeObserver.observe(canvasEl.value.parentElement)
  }

  loadFactions()
  loadPlacements()
  loadZones()
  loadSplines()
  loadSpawners()
})

onBeforeUnmount(() => {
  resizeObserver?.disconnect()
  if (animFrame) cancelAnimationFrame(animFrame)
})

watch([zones, splines, spawners, placements, selectedItem], () => requestDraw(), { deep: true })
</script>

<style scoped>
@reference "tailwindcss";

.form-input {
  @apply w-full rounded border border-gray-700 bg-gray-800 px-2 py-1.5 text-xs text-gray-200 outline-none transition-colors focus:border-indigo-500;
}
</style>
