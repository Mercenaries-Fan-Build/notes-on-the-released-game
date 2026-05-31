/**
 * c3 streaming grid decode — mirrors game-scripts/mercs2_c3_grid.py (game Y-up metres).
 */

export const CELL_ID_BASE = 30001
export const GRID_COLS = 100
export const WORLD_MIN_X = -3900.0
export const WORLD_MAX_X = 3850.0
export const WORLD_MIN_Z = -3900.0
export const WORLD_MAX_Z = 3850.0

const CELL_SIZE_X = (WORLD_MAX_X - WORLD_MIN_X) / GRID_COLS
const CELL_SIZE_Z = (WORLD_MAX_Z - WORLD_MIN_Z) / GRID_COLS

const C3_ID_RE = /c3(\d{4})/gi
const C3_SIMPLE_RE = /^c3(\d{4})$/i

function cellIdFromDigits(fourDigits) {
  return CELL_ID_BASE - 1 + parseInt(fourDigits, 10)
}

/** @param {string} stem */
export function parseCellIdsFromStem(stem) {
  const out = []
  const re = new RegExp(C3_ID_RE.source, 'gi')
  let m
  while ((m = re.exec(stem)) !== null) {
    out.push(cellIdFromDigits(m[1]))
  }
  return out
}

/** @param {string} stem */
export function primaryCellIdFromStem(stem) {
  const ids = parseCellIdsFromStem(stem)
  return ids.length ? ids[0] : null
}

/** @param {number} cellId @param {number} [y=0] */
export function cellIdToWorldXYZ(cellId, y = 0) {
  const linear = Math.max(0, cellId - CELL_ID_BASE)
  const row = Math.floor(linear / GRID_COLS)
  const col = linear % GRID_COLS
  const x = WORLD_MIN_X + (col + 0.5) * CELL_SIZE_X
  const z = WORLD_MIN_Z + (row + 0.5) * CELL_SIZE_Z
  return { x, y, z }
}

/** @param {string} stem */
export function isC3BlockStem(stem) {
  const lower = stem.toLowerCase()
  if (/blocks__vz__c3\d{4}/.test(lower)) return true
  if (lower.includes('__shared__') && /c3\d{4}/.test(lower)) return true
  return C3_SIMPLE_RE.test(lower)
}

/** Preset bboxes in game metres (x/z filters for loading subsets). */
export const REGION_PRESETS = {
  maracaibo: { label: 'Maracaibo (approx)', minX: 400, maxX: 3200, minZ: -2200, maxZ: 400 },
  pmc_pool: { label: 'PMC pool 200m anchor', minX: 2400, maxX: 2800, minZ: -1100, maxZ: -700 },
  full: { label: 'Full map', minX: WORLD_MIN_X, maxX: WORLD_MAX_X, minZ: WORLD_MIN_Z, maxZ: WORLD_MAX_Z },
}
