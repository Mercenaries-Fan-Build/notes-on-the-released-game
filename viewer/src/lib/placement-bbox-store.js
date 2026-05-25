/**
 * Client-side placement index, named bbox regions, and transform overrides.
 * Game space: LH Y-up metres (X E–W, Y up, Z N–S).
 */

export const STORAGE_BBOXES = 'mercs2_bbox_regions_v1'
export const STORAGE_OVERRIDES = 'mercs2_placement_overrides_v1'
export const STORAGE_UI = 'mercs2_bbox_ui_v1'

/** @typedef {{ x: number, y: number, z: number }} Vec3 */

/**
 * @typedef {object} BboxRegion
 * @property {string} id
 * @property {string} name
 * @property {number} x_min
 * @property {number} x_max
 * @property {number} z_min
 * @property {number} z_max
 * @property {number|null} [y_min]
 * @property {number|null} [y_max]
 * @property {boolean} [y_band] when false, ignore Y limits
 */

/**
 * @typedef {object} TransformOverride
 * @property {number} [rotation_y_deg]
 * @property {number} [rotation_y_rad]
 * @property {number} [rot_sin]
 * @property {number} [rot_cos]
 * @property {number} [rotation_quat_x]
 * @property {number} [rotation_quat_z]
 * @property {number} [rotation_quat_y]
 * @property {number} [rotation_quat_w]
 * @property {Vec3} [position]
 * @property {string} [note]
 */

/** @param {object} p */
export function placementKey(p) {
  if (p.entity_id) return String(p.entity_id)
  const pos = p.position || {}
  return `${p.source || '?'}:${p.sub_block ?? '?'}:${p.entity_name || '?'}:${pos.x ?? 0},${pos.y ?? 0},${pos.z ?? 0}`
}

/** @param {object} p */
export function readPosition(p) {
  const pos = p.position || {}
  return {
    x: Number(pos.x) || 0,
    y: Number(pos.y) || 0,
    z: Number(pos.z) || 0,
  }
}

/** @param {object} p */
export function readRotation(p) {
  return {
    rotation_y_deg: numOrNull(p.rotation_y_deg),
    rotation_y_rad: numOrNull(p.rotation_y_rad),
    rot_sin: numOrNull(p.rot_sin),
    rot_cos: numOrNull(p.rot_cos),
    rotation_quat_x: numOrNull(p.rotation_quat_x),
    rotation_quat_z: numOrNull(p.rotation_quat_z),
    rotation_quat_y: numOrNull(p.rotation_quat_y),
    rotation_quat_w: numOrNull(p.rotation_quat_w),
  }
}

/** @param {unknown} v */
function numOrNull(v) {
  if (v == null || v === '') return null
  const n = Number(v)
  return Number.isFinite(n) ? n : null
}

/**
 * @param {BboxRegion} bbox
 * @param {Vec3} pos
 */
export function positionInBbox(bbox, pos) {
  const x = pos.x
  const y = pos.y
  const z = pos.z
  if (x < bbox.x_min || x > bbox.x_max) return false
  if (z < bbox.z_min || z > bbox.z_max) return false
  if (bbox.y_band !== false) {
    const y0 = bbox.y_min
    const y1 = bbox.y_max
    if (y0 != null && y < y0) return false
    if (y1 != null && y > y1) return false
  }
  return true
}

/**
 * @param {object} p
 * @param {BboxRegion} bbox
 */
export function placementInBbox(p, bbox) {
  return positionInBbox(bbox, readPosition(p))
}

/**
 * @param {object} p
 * @param {BboxRegion[]} bboxes
 * @param {'any'|'all'} mode
 */
export function placementInRegions(p, bboxes, mode = 'any') {
  if (!bboxes.length) return true
  if (mode === 'all') return bboxes.every((b) => placementInBbox(p, b))
  return bboxes.some((b) => placementInBbox(p, b))
}

/**
 * @param {object} p
 * @param {Record<string, TransformOverride>} overrides
 */
export function effectivePlacement(p, overrides) {
  const key = placementKey(p)
  const ov = overrides[key]
  const pos = readPosition(p)
  const rot = readRotation(p)
  if (ov?.position) {
    pos.x = ov.position.x ?? pos.x
    pos.y = ov.position.y ?? pos.y
    pos.z = ov.position.z ?? pos.z
  }
  if (ov) {
    for (const k of [
      'rotation_y_deg',
      'rotation_y_rad',
      'rot_sin',
      'rot_cos',
      'rotation_quat_x',
      'rotation_quat_z',
      'rotation_quat_y',
      'rotation_quat_w',
    ]) {
      if (ov[k] != null) rot[k] = ov[k]
    }
  }
  return {
    key,
    position: pos,
    rotation: rot,
    overridden: Boolean(ov),
  }
}

/**
 * Convert game-space yaw (radians, around +Y) to UE yaw (degrees, around +Z).
 * Both systems are LH; the (x,y,z)→(x,z,y) basis swap preserves handedness,
 * so the sign is preserved. If empirical testing shows a negate is needed,
 * change only this function.
 * @param {number} gameYawRad
 * @returns {number} UE yaw in degrees
 */
export function gameYawToUeYawDeg(gameYawRad) {
  return (gameYawRad * 180) / Math.PI
}

/** @param {number} deg - full yaw angle in degrees */
export function rotationFromDegrees(deg) {
  const rad = (deg * Math.PI) / 180
  const halfRad = rad / 2
  return {
    rotation_y_deg: deg,
    rotation_y_rad: rad,
    rot_sin: Math.sin(halfRad),
    rot_cos: Math.cos(halfRad),
    rotation_quat_x: 0,
    rotation_quat_y: Math.sin(halfRad),
    rotation_quat_z: 0,
    rotation_quat_w: Math.cos(halfRad),
  }
}

/** @param {number} sin - quaternion qy = sin(yaw/2) @param {number} cos - quaternion qw = cos(yaw/2) */
export function rotationFromSinCos(sin, cos) {
  const rad = 2.0 * Math.atan2(sin, cos)
  const deg = (rad * 180) / Math.PI
  return {
    rotation_y_deg: deg,
    rotation_y_rad: rad,
    rot_sin: sin,
    rot_cos: cos,
    rotation_quat_x: 0,
    rotation_quat_y: sin,
    rotation_quat_z: 0,
    rotation_quat_w: cos,
  }
}

export function newRegionId() {
  return `r_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 7)}`
}

/** @param {string} name @param {Partial<BboxRegion>} bounds */
export function createRegion(name, bounds = {}) {
  return {
    id: newRegionId(),
    name: name || 'region',
    x_min: bounds.x_min ?? -500,
    x_max: bounds.x_max ?? 500,
    z_min: bounds.z_min ?? -500,
    z_max: bounds.z_max ?? 500,
    y_min: bounds.y_min ?? null,
    y_max: bounds.y_max ?? null,
    y_band: bounds.y_band ?? false,
  }
}

export function loadJsonStorage(key, fallback) {
  try {
    const raw = localStorage.getItem(key)
    if (!raw) return fallback
    return JSON.parse(raw)
  } catch {
    return fallback
  }
}

export function saveJsonStorage(key, value) {
  try {
    localStorage.setItem(key, JSON.stringify(value))
  } catch (err) {
    console.warn('localStorage save failed', key, err)
  }
}

/**
 * @param {object[]} placements
 * @param {BboxRegion} bbox
 */
export function queryPlacements(placements, bbox) {
  const out = []
  for (const p of placements) {
    if (placementInBbox(p, bbox)) out.push(p)
  }
  return out
}

/**
 * Brute-force filter with optional name/source substring and block_type set.
 * @param {object[]} placements
 * @param {object} opts
 */
export function filterPlacements(placements, opts) {
  const {
    regions = [],
    regionMode = 'any',
    activeRegionId = null,
    nameFilter = '',
    sourceFilter = '',
    blockTypes = null,
    onlyOverridden = false,
    overrides = {},
  } = opts

  let regionsUse = regions
  if (activeRegionId) {
    const one = regions.find((r) => r.id === activeRegionId)
    regionsUse = one ? [one] : []
  }

  const nameLc = nameFilter.trim().toLowerCase()
  const srcLc = sourceFilter.trim().toLowerCase()

  const out = []
  for (const p of placements) {
    if (blockTypes && !blockTypes.has(p.block_type || '')) continue
    if (nameLc && !(p.entity_name || '').toLowerCase().includes(nameLc)) continue
    if (srcLc && !(p.source || '').toLowerCase().includes(srcLc)) continue
    if (regionsUse.length && !placementInRegions(p, regionsUse, regionMode)) continue
    if (onlyOverridden && !overrides[placementKey(p)]) continue
    out.push(p)
  }
  return out
}

/** @param {object} p @param {Record<string, TransformOverride>} overrides */
export function mergePlacementForExport(p, overrides) {
  const key = placementKey(p)
  const ov = overrides[key]
  if (!ov) return { ...p }
  const merged = { ...p, position: { ...(p.position || {}) } }
  if (ov.position) Object.assign(merged.position, ov.position)
  for (const k of [
    'rotation_y_deg',
    'rotation_y_rad',
    'rot_sin',
    'rot_cos',
    'rotation_quat_x',
    'rotation_quat_z',
    'rotation_quat_y',
    'rotation_quat_w',
  ]) {
    if (ov[k] != null) merged[k] = ov[k]
  }
  if (ov.note) merged._override_note = ov.note
  merged._override_key = key
  return merged
}

export function createPlacementStore() {
  /** @type {object[]} */
  let placements = []
  /** @type {BboxRegion[]} */
  let regions = loadJsonStorage(STORAGE_BBOXES, [])
  /** @type {Record<string, TransformOverride>} */
  let overrides = loadJsonStorage(STORAGE_OVERRIDES, {})
  let datasetId = 'pmc_base'
  let datasetPath = ''
  let meta = {}

  const listeners = new Set()
  function emit() {
    for (const fn of listeners) fn()
  }
  function subscribe(fn) {
    listeners.add(fn)
    return () => listeners.delete(fn)
  }

  function persistRegions() {
    saveJsonStorage(STORAGE_BBOXES, regions)
  }
  function persistOverrides() {
    saveJsonStorage(STORAGE_OVERRIDES, overrides)
  }

  return {
    subscribe,
    getPlacements: () => placements,
    getRegions: () => regions,
    getOverrides: () => overrides,
    getDatasetId: () => datasetId,
    getDatasetPath: () => datasetPath,
    getMeta: () => meta,

    setPlacements(rows, info = {}) {
      placements = Array.isArray(rows) ? rows : []
      datasetId = info.datasetId || datasetId
      datasetPath = info.path || datasetPath
      meta = info.meta || {}
      emit()
    },

    setDatasetId(id) {
      datasetId = id
      const ui = loadJsonStorage(STORAGE_UI, {})
      ui.datasetId = id
      saveJsonStorage(STORAGE_UI, ui)
    },

    loadUiPrefs() {
      return loadJsonStorage(STORAGE_UI, {})
    },

    saveUiPrefs(patch) {
      const ui = { ...loadJsonStorage(STORAGE_UI, {}), ...patch }
      saveJsonStorage(STORAGE_UI, ui)
    },

    addRegion(region) {
      regions = [...regions, region]
      persistRegions()
      emit()
      return region
    },

    updateRegion(id, patch) {
      regions = regions.map((r) => (r.id === id ? { ...r, ...patch } : r))
      persistRegions()
      emit()
    },

    removeRegion(id) {
      regions = regions.filter((r) => r.id !== id)
      persistRegions()
      emit()
    },

    setRegions(next) {
      regions = next
      persistRegions()
      emit()
    },

    setOverride(key, patch) {
      overrides = { ...overrides, [key]: { ...(overrides[key] || {}), ...patch } }
      persistOverrides()
      emit()
    },

    clearOverride(key) {
      const next = { ...overrides }
      delete next[key]
      overrides = next
      persistOverrides()
      emit()
    },

    clearAllOverrides() {
      overrides = {}
      persistOverrides()
      emit()
    },

    importOverrides(doc) {
      if (doc && typeof doc === 'object') {
        overrides = { ...overrides, ...doc }
        persistOverrides()
        emit()
      }
    },

    exportOverrides() {
      return { ...overrides }
    },

    queryFiltered(opts) {
      return filterPlacements(placements, { overrides, ...opts, regions })
    },
  }
}
