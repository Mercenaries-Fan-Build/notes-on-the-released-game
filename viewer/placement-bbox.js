/**
 * Named bbox regions, filtered placement table, rotation/position overrides, 2D map.
 */
import {
  createPlacementStore,
  createRegion,
  effectivePlacement,
  gameYawToUeYawDeg,
  mergePlacementForExport,
  placementKey,
  readRotation,
  rotationFromDegrees,
  rotationFromSinCos,
} from './placement-bbox-store.js'
import { createMapView } from './placement-bbox-map.js'

const store = createPlacementStore()

const datasetSelect = document.getElementById('datasetSelect')
const datasetMeta = document.getElementById('datasetMeta')
const activeRegionSel = document.getElementById('activeRegion')
const regionList = document.getElementById('regionList')
const regionName = document.getElementById('regionName')
const bboxInputs = {
  x_min: document.getElementById('bx0'),
  x_max: document.getElementById('bx1'),
  z_min: document.getElementById('bz0'),
  z_max: document.getElementById('bz1'),
  y_min: document.getElementById('by0'),
  y_max: document.getElementById('by1'),
}
const yBand = document.getElementById('yBand')
const nameFilter = document.getElementById('nameFilter')
const sourceFilter = document.getElementById('sourceFilter')
const cbLs = document.getElementById('cbLs')
const cbVz = document.getElementById('cbVz')
const onlyOverridden = document.getElementById('onlyOverridden')
const maxRows = document.getElementById('maxRows')
const tableBody = document.getElementById('tableBody')
const statusBar = document.getElementById('statusBar')
const exportOut = document.getElementById('exportOut')
const editPanel = document.getElementById('editPanel')
const editTitle = document.getElementById('editTitle')
const ovYawDeg = document.getElementById('ovYawDeg')
const ovSin = document.getElementById('ovSin')
const ovCos = document.getElementById('ovCos')
const ovQx = document.getElementById('ovQx')
const ovQz = document.getElementById('ovQz')
const ovPx = document.getElementById('ovPx')
const ovPy = document.getElementById('ovPy')
const ovPz = document.getElementById('ovPz')
const ovNote = document.getElementById('ovNote')

const canvas = document.getElementById('canvas2d')
const mapView = createMapView(canvas, {
  onPick: (p) => selectPlacement(p),
})

let activeRegionId = null
/** @type {object|null} */
let selectedPlacement = null
/** @type {Set<string>} */
const selectedKeys = new Set()
let sortKey = 'entity_name'
let sortDir = 1
/** @type {object[]} */
let tableRows = []

function blockTypeSet() {
  const s = new Set()
  if (cbLs.checked) s.add('layers_static')
  if (cbVz.checked) s.add('vz_state')
  return s.size ? s : new Set(['layers_static', 'vz_state'])
}

function getActiveRegion() {
  return store.getRegions().find((r) => r.id === activeRegionId) || null
}

function syncRegionForm(r) {
  if (!r) return
  regionName.value = r.name || ''
  for (const k of ['x_min', 'x_max', 'z_min', 'z_max', 'y_min', 'y_max']) {
    const el = bboxInputs[k]
    if (el) el.value = r[k] != null ? String(r[k]) : ''
  }
  yBand.checked = r.y_band === true
}

function readRegionForm() {
  const num = (id) => {
    const v = parseFloat(bboxInputs[id].value)
    return Number.isFinite(v) ? v : 0
  }
  return {
    name: regionName.value.trim() || 'region',
    x_min: num('x_min'),
    x_max: num('x_max'),
    z_min: num('z_min'),
    z_max: num('z_max'),
    y_min: bboxInputs.y_min.value === '' ? null : num('y_min'),
    y_max: bboxInputs.y_max.value === '' ? null : num('y_max'),
    y_band: yBand.checked,
  }
}

function renderRegionUi() {
  const regions = store.getRegions()
  activeRegionSel.innerHTML = regions.length
    ? regions.map((r) => `<option value="${r.id}">${escapeHtml(r.name)}</option>`).join('')
    : '<option value="">(none)</option>'
  if (activeRegionId && regions.some((r) => r.id === activeRegionId)) {
    activeRegionSel.value = activeRegionId
  } else if (regions.length) {
    activeRegionId = regions[0].id
    activeRegionSel.value = activeRegionId
  } else {
    activeRegionId = null
  }

  regionList.innerHTML = regions
    .map(
      (r) =>
        `<li data-id="${r.id}" class="${r.id === activeRegionId ? 'active' : ''}">${escapeHtml(r.name)}<br><span class="muted">X ${r.x_min}…${r.x_max} Z ${r.z_min}…${r.z_max}</span></li>`,
    )
    .join('')
  for (const li of regionList.querySelectorAll('li')) {
    li.addEventListener('click', () => {
      activeRegionId = li.dataset.id || null
      const r = getActiveRegion()
      if (r) syncRegionForm(r)
      refresh()
    })
  }
  const r = getActiveRegion()
  if (r) syncRegionForm(r)
}

function rowSortValue(row, key) {
  const eff = row._eff
  switch (key) {
    case 'x':
      return eff.position.x
    case 'y':
      return eff.position.y
    case 'z':
      return eff.position.z
    case 'rotation_y_deg':
      return eff.rotation.rotation_y_deg ?? 0
    case 'rot_sin':
      return eff.rotation.rot_sin ?? 0
    case 'rot_cos':
      return eff.rotation.rot_cos ?? 0
    case 'qx':
      return eff.rotation.rotation_quat_x ?? 0
    case 'qz':
      return eff.rotation.rotation_quat_z ?? 0
  }
  return row[key] ?? ''
}

function buildTableRows() {
  const overrides = store.getOverrides()
  const filtered = store.queryFiltered({
    activeRegionId,
    nameFilter: nameFilter.value,
    sourceFilter: sourceFilter.value,
    blockTypes: blockTypeSet(),
    onlyOverridden: onlyOverridden.checked,
    overrides,
  })
  const rows = filtered.map((p) => {
    const eff = effectivePlacement(p, overrides)
    return { ...p, _eff: eff, _key: eff.key }
  })
  rows.sort((a, b) => {
    const av = rowSortValue(a, sortKey)
    const bv = rowSortValue(b, sortKey)
    if (av < bv) return -sortDir
    if (av > bv) return sortDir
    return 0
  })
  const cap = Math.max(50, Math.min(20000, parseInt(maxRows.value, 10) || 500))
  tableRows = rows.slice(0, cap)
  return { total: filtered.length, shown: tableRows.length }
}

function renderTable(stats) {
  tableBody.innerHTML = tableRows
    .map((p) => {
      const eff = p._eff
      const rot = eff.rotation
      const pos = eff.position
      const sel = selectedKeys.has(p._key) || selectedPlacement?._key === p._key
      return `<tr data-key="${escapeAttr(p._key)}" class="${sel ? 'selected' : ''}${eff.overridden ? ' overridden' : ''}">
        <td><input type="checkbox" class="row-cb" ${selectedKeys.has(p._key) ? 'checked' : ''} /></td>
        <td>${escapeHtml(p.entity_name || '')}</td>
        <td>${fmt(pos.x)}</td>
        <td>${fmt(pos.y)}</td>
        <td>${fmt(pos.z)}</td>
        <td>${fmt(rot.rotation_y_deg)}</td>
        <td>${fmt(rot.rot_sin)}</td>
        <td>${fmt(rot.rot_cos)}</td>
        <td>${fmt(rot.rotation_quat_x)}</td>
        <td>${fmt(rot.rotation_quat_z)}</td>
        <td title="${escapeAttr(p.source || '')}">${escapeHtml(shortSource(p.source))}</td>
        <td>${escapeHtml(p.block_type || '')}</td>
      </tr>`
    })
    .join('')

  for (const tr of tableBody.querySelectorAll('tr')) {
    tr.addEventListener('click', (e) => {
      if (e.target instanceof HTMLInputElement) return
      const key = tr.dataset.key
      const p = tableRows.find((r) => r._key === key)
      if (p) selectPlacement(p)
    })
    const cb = tr.querySelector('.row-cb')
    cb?.addEventListener('change', (e) => {
      e.stopPropagation()
      const key = tr.dataset.key
      if (!key) return
      if (cb.checked) selectedKeys.add(key)
      else selectedKeys.delete(key)
    })
  }

  statusBar.textContent = `${stats.shown} shown / ${stats.total} in filter · ${store.getPlacements().length} loaded · ${Object.keys(store.getOverrides()).length} overrides`
}

function refreshMap() {
  const overrides = store.getOverrides()
  const mapPts = tableRows.slice(0, 8000).map((p) => {
    const eff = effectivePlacement(p, overrides)
    const gameYawRad =
      eff.rotation.rotation_y_rad ??
      (eff.rotation.rot_sin != null && eff.rotation.rot_cos != null
        ? 2.0 * Math.atan2(eff.rotation.rot_sin, eff.rotation.rot_cos)
        : null)
    const ueYawDeg = gameYawRad != null ? gameYawToUeYawDeg(gameYawRad) : null
    return {
      _raw: p,
      _mapKey: p._key,
      position: eff.position,
      _yawRad: ueYawDeg != null ? (ueYawDeg * Math.PI) / 180 : null,
      _mapColor: eff.overridden ? '#6ad46a' : '#4a9fe8',
    }
  })
  const hl = new Set()
  if (selectedPlacement?._key) hl.add(selectedPlacement._key)
  for (const k of selectedKeys) hl.add(k)
  mapView.setData(mapPts, store.getRegions(), activeRegionId, hl)
}

function refresh() {
  renderRegionUi()
  const stats = buildTableRows()
  renderTable(stats)
  refreshMap()
}

function selectPlacement(p) {
  const row = p._key ? p : { ...p, _key: placementKey(p) }
  selectedPlacement = row
  const eff = effectivePlacement(row, store.getOverrides())
  editPanel.classList.remove('hidden')
  editTitle.textContent = `${p.entity_name || '?'} (${eff.key})`
  const rot = { ...readRotation(p), ...eff.rotation }
  ovYawDeg.value = rot.rotation_y_deg != null ? String(rot.rotation_y_deg) : ''
  ovSin.value = rot.rot_sin != null ? String(rot.rot_sin) : ''
  ovCos.value = rot.rot_cos != null ? String(rot.rot_cos) : ''
  ovQx.value = rot.rotation_quat_x != null ? String(rot.rotation_quat_x) : ''
  ovQz.value = rot.rotation_quat_z != null ? String(rot.rotation_quat_z) : ''
  ovPx.value = String(eff.position.x)
  ovPy.value = String(eff.position.y)
  ovPz.value = String(eff.position.z)
  const ov = store.getOverrides()[eff.key]
  ovNote.value = ov?.note || ''
  refresh()
}

function applyOverrideToKeys(keys, patch) {
  for (const key of keys) {
    store.setOverride(key, patch)
  }
}

function collectOverridePatch() {
  const patch = { note: ovNote.value.trim() || undefined }
  const deg = parseFloat(ovYawDeg.value)
  if (Number.isFinite(deg)) Object.assign(patch, rotationFromDegrees(deg))
  const s = parseFloat(ovSin.value)
  const c = parseFloat(ovCos.value)
  if (Number.isFinite(s) && Number.isFinite(c)) Object.assign(patch, rotationFromSinCos(s, c))
  const qx = parseFloat(ovQx.value)
  const qz = parseFloat(ovQz.value)
  if (Number.isFinite(qx)) patch.rotation_quat_x = qx
  if (Number.isFinite(qz)) patch.rotation_quat_z = qz
  const px = parseFloat(ovPx.value)
  const py = parseFloat(ovPy.value)
  const pz = parseFloat(ovPz.value)
  if ([px, py, pz].every(Number.isFinite)) patch.position = { x: px, y: py, z: pz }
  return patch
}

async function loadCatalog() {
  const res = await fetch('/api/placements-catalog.json')
  if (!res.ok) throw new Error(await res.text())
  return res.json()
}

async function loadDataset(id) {
  const res = await fetch(`/api/placements-dataset.json?id=${encodeURIComponent(id)}`)
  if (!res.ok) throw new Error(await res.text())
  return res.json()
}

async function loadPmcPreset() {
  const res = await fetch('/api/pmc-base-preset.json')
  if (!res.ok) return null
  return res.json()
}

async function init() {
  const prefs = store.loadUiPrefs()
  const catalog = await loadCatalog()
  datasetSelect.innerHTML = catalog.datasets
    .map((d) => `<option value="${d.id}">${escapeHtml(d.label)}</option>`)
    .join('')
  const defaultId = prefs.datasetId || catalog.defaultId || 'pmc_base'
  datasetSelect.value = catalog.datasets.some((d) => d.id === defaultId)
    ? defaultId
    : catalog.datasets[0]?.id

  if (!store.getRegions().length) {
    const preset = await loadPmcPreset()
    if (preset?.bbox) {
      const b = preset.bbox
      store.addRegion(
        createRegion('PMC HQ (preset)', {
          x_min: b.x_min,
          x_max: b.x_max,
          z_min: b.z_min,
          z_max: b.z_max,
          y_min: b.y_min,
          y_max: b.y_max,
          y_band: true,
        }),
      )
    }
  }
  if (store.getRegions().length) activeRegionId = store.getRegions()[0].id

  await reloadDataset()
  store.subscribe(refresh)
}

async function reloadDataset() {
  const id = datasetSelect.value
  store.setDatasetId(id)
  statusBar.textContent = `Loading ${id}…`
  try {
    const data = await loadDataset(id)
    const placements = Array.isArray(data) ? data : data.placements || []
    store.setPlacements(placements, {
      datasetId: id,
      path: data.path,
      meta: { bbox: data.bbox, count: data.count },
    })
    datasetMeta.textContent = `${data.path || id} · ${placements.length} records`
    if (data.bbox && !store.getRegions().some((r) => r.name.includes('dataset'))) {
      const b = data.bbox
      store.addRegion(
        createRegion('dataset bbox', {
          x_min: b.x_min,
          x_max: b.x_max,
          z_min: b.z_min,
          z_max: b.z_max,
          y_min: b.y_min,
          y_max: b.y_max,
          y_band: true,
        }),
      )
    }
    refresh()
  } catch (err) {
    statusBar.textContent = `Load failed: ${err.message}`
  }
}

document.getElementById('btnSaveRegion').addEventListener('click', () => {
  const form = readRegionForm()
  const r = getActiveRegion()
  if (r) store.updateRegion(r.id, form)
  else {
    const nr = createRegion(form.name, form)
    store.addRegion(nr)
    activeRegionId = nr.id
  }
  refresh()
})

document.getElementById('btnNewRegion').addEventListener('click', () => {
  const r = createRegion('new region')
  store.addRegion(r)
  activeRegionId = r.id
  syncRegionForm(r)
  refresh()
})

document.getElementById('btnDeleteRegion').addEventListener('click', () => {
  if (!activeRegionId) return
  store.removeRegion(activeRegionId)
  activeRegionId = store.getRegions()[0]?.id || null
  refresh()
})

document.getElementById('btnPmcPreset').addEventListener('click', async () => {
  const preset = await loadPmcPreset()
  if (!preset?.bbox) {
    statusBar.textContent = 'PMC preset not found (run make build-pmc-base-set)'
    return
  }
  const b = preset.bbox
  const r = createRegion('PMC HQ (preset)', {
    x_min: b.x_min,
    x_max: b.x_max,
    z_min: b.z_min,
    z_max: b.z_max,
    y_min: b.y_min,
    y_max: b.y_max,
    y_band: true,
  })
  store.addRegion(r)
  activeRegionId = r.id
  syncRegionForm(r)
  mapView.fitToRegions([r])
  refresh()
})

activeRegionSel.addEventListener('change', () => {
  activeRegionId = activeRegionSel.value || null
  const r = getActiveRegion()
  if (r) syncRegionForm(r)
  refresh()
})

for (const el of [nameFilter, sourceFilter, cbLs, cbVz, onlyOverridden, maxRows]) {
  el.addEventListener('input', refresh)
}
for (const el of Object.values(bboxInputs)) {
  el.addEventListener('change', () => {
    const r = getActiveRegion()
    if (r) store.updateRegion(r.id, readRegionForm())
    refresh()
  })
}

datasetSelect.addEventListener('change', reloadDataset)

document.getElementById('btnApplyOverride').addEventListener('click', () => {
  if (!selectedPlacement) return
  applyOverrideToKeys([selectedPlacement._key], collectOverridePatch())
})

document.getElementById('btnClearOverride').addEventListener('click', () => {
  if (!selectedPlacement) return
  store.clearOverride(selectedPlacement._key)
  selectPlacement(selectedPlacement)
})

document.getElementById('btnApplySelection').addEventListener('click', () => {
  const patch = collectOverridePatch()
  const keys = selectedKeys.size ? [...selectedKeys] : selectedPlacement ? [selectedPlacement._key] : []
  if (!keys.length) return
  applyOverrideToKeys(keys, patch)
})

document.getElementById('btnExportOverrides').addEventListener('click', () => {
  const doc = {
    datasetId: store.getDatasetId(),
    path: store.getDatasetPath(),
    override_count: Object.keys(store.getOverrides()).length,
    overrides: store.exportOverrides(),
    merged_sample: tableRows.slice(0, 5).map((p) => mergePlacementForExport(p, store.getOverrides())),
  }
  exportOut.value = JSON.stringify(doc, null, 2)
  navigator.clipboard?.writeText(exportOut.value).catch(() => {})
})

document.getElementById('btnClearAllOverrides').addEventListener('click', () => {
  if (confirm('Clear all rotation/position overrides?')) store.clearAllOverrides()
})

for (const th of document.querySelectorAll('th[data-sort]')) {
  th.addEventListener('click', () => {
    const k = th.dataset.sort
    if (!k || k === 'sel') return
    if (sortKey === k) sortDir *= -1
    else {
      sortKey = k
      sortDir = 1
    }
    refresh()
  })
}

function fmt(n) {
  if (n == null || !Number.isFinite(n)) return '—'
  return Number(n).toFixed(3)
}

function escapeHtml(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
}

function escapeAttr(s) {
  return escapeHtml(s).replace(/'/g, '&#39;')
}

function shortSource(src) {
  if (!src) return ''
  const m = src.match(/__([^_]+(?:_[^_]+)*)_P\d+/i)
  return m ? m[1].slice(0, 40) : src.slice(-36)
}

window.addEventListener('resize', () => mapView.resize())
mapView.resize()
init()
