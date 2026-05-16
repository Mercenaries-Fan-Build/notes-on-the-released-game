import * as THREE from 'three'
import { AnimationMixer } from 'three'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'
import { OBJLoader } from 'three/examples/jsm/loaders/OBJLoader.js'
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js'
import { DDSLoader } from 'three/examples/jsm/loaders/DDSLoader.js'
import { RoomEnvironment } from 'three/examples/jsm/environments/RoomEnvironment.js'
import {
  classifyPart,
  getDamageState,
  passesDamageVariantFilter,
  lodGroupMaxRank,
  configureColorTexture,
  ensureNormals,
  makeMaterial,
  loadObjText,
  loadTexture,
  clearTextureCache,
} from './submesh-inspect.js'

/** Human labels for ``/api/review-assets.json`` → ``sidecars`` keys */
const REVIEW_SIDECAR_LABELS = {
  ucfxJson: 'ucfx.json',
  meshMetaJson: 'mesh.meta.json',
  dialogFragmentsJson: 'dialog_fragments.json',
  levelHintsJson: 'level_hints.json',
  havokManifestJson: 'havok/manifest.json',
  texturesManifestJson: 'textures/manifest.json',
  textureManifestRichJson: 'textures/texture_manifest.json',
  meshSceneBin: 'mesh_scene.bin',
  sharedTexturesJson: 'shared_textures.json',
}

/* ── DOM refs ── */
const viewport = document.getElementById('viewport')
const statusEl = document.getElementById('status')
const partsPanel = document.getElementById('inspect-parts-panel')
const presetsBar = document.getElementById('inspect-presets-bar')
const vehicleVariantControls = document.getElementById('inspect-vehicle-variant-controls')
const vehicleDamagedCb = document.getElementById('inspect-vehicle-damaged-cb')
const vehicleBothCb = document.getElementById('inspect-vehicle-both-cb')
const vehicleBothWrap = document.getElementById('inspect-vehicle-both-wrap')
const lodControls = document.getElementById('inspect-lod-controls')
const lodAutoCb = document.getElementById('inspect-lod-auto-cb')
const lodSlider = document.getElementById('inspect-lod-slider')
const lodLabel = document.getElementById('inspect-lod-label')
const texSelect = document.getElementById('inspect-tex-select')
const texSelector = document.getElementById('inspect-tex-selector')
const texFlipV = document.getElementById('inspect-tex-flip-v')
const inspectPanel = document.getElementById('inspectPanel')

/* ── Three.js setup ── */
function syncCanvasToViewport() {
  const w = Math.max(2, viewport.clientWidth || 0)
  const h = Math.max(2, viewport.clientHeight || 0)
  camera.aspect = w / h
  camera.updateProjectionMatrix()
  renderer.setSize(w, h)
}

const scene = new THREE.Scene()
scene.background = new THREE.Color(0x1a1a1e)

const camera = new THREE.PerspectiveCamera(50, 1, 0.01, 5000)
camera.position.set(2.5, 1.8, 2.5)

const renderer = new THREE.WebGLRenderer({ antialias: true })
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))
renderer.outputColorSpace = THREE.SRGBColorSpace
renderer.toneMapping = THREE.ACESFilmicToneMapping
renderer.toneMappingExposure = 1.02
// Asset preview: keep shadows off (no cast/receive on meshes either). Avoids accidental
// shadow frustum clipping and matches "studio" lighting expectations.
renderer.shadowMap.enabled = false
viewport.appendChild(renderer.domElement)
syncCanvasToViewport()

const pmremGenerator = new THREE.PMREMGenerator(renderer)
pmremGenerator.compileEquirectangularShader()
{
  const envRt = pmremGenerator.fromScene(new RoomEnvironment(renderer), 0.04)
  scene.environment = envRt.texture
}

const controls = new OrbitControls(camera, renderer.domElement)
controls.enableDamping = true

// Direct lights + scene.environment (RoomEnvironment IBL).  MeshStandardMaterial is very dark
// without IBL; with IBL we keep modest key/rim/fill and low ambient so materials do not clip.
scene.add(new THREE.HemisphereLight(0xcde0ff, 0x4a4632, 2.35))

const keyLight = new THREE.DirectionalLight(0xffffff, 2.2)
keyLight.castShadow = false
keyLight.position.set(4, 10, 6)
scene.add(keyLight)
scene.add(keyLight.target)

const rimLight = new THREE.DirectionalLight(0xa8c8ff, 1.35)
rimLight.castShadow = false
rimLight.position.set(-6, 4, -5)
scene.add(rimLight)
scene.add(rimLight.target)

const cameraFill = new THREE.DirectionalLight(0xffffff, 1.45)
cameraFill.castShadow = false
scene.add(cameraFill)
scene.add(cameraFill.target)
scene.add(new THREE.AmbientLight(0xffffff, 0.42))

/** Scratch for camera-aware key/rim placement (fixed world lights miss the mesh when orbit/zoom changes). */
const _keyRimDir = new THREE.Vector3()
const _keyRimSide = new THREE.Vector3()
const _keyRimUp = new THREE.Vector3(0, 1, 0)
/** Keep key light outside a small sphere around the orbit target (avoids "inside mesh" degeneracy). */
const _keyFromTarget = new THREE.Vector3()

let grid = new THREE.GridHelper(20, 40, 0x444444, 0x333333)
scene.add(grid)

/* ── Rendering state (flat, matching preview.html) ── */
let root = null
let partGroups = []
let partMeta = []
let hasLodData = false
let hasDamageData = false
let currentLodRank = 0
let globalMaxRank = 0
/** Characteristic size of the loaded mesh (world units); used for auto LOD. */
let lodRefMaxDim = 1
let availableTextures = []
let activeTexture = null
let manifestBaseDir = ''
let textureNameToUrl = {}
let perMaterialMode = false

/** AbortController for inspect panel event listeners */
let inspectUiAbort = null

/* ── Dispose / clear ── */
function disposeRoot() {
  inspectUiAbort?.abort()
  inspectUiAbort = null
  if (root) {
    root.traverse((o) => {
      if (o.geometry) o.geometry.dispose()
      if (o.material) {
        const m = o.material
        if (Array.isArray(m)) m.forEach((x) => x.dispose?.())
        else m.dispose?.()
      }
    })
    scene.remove(root)
  }
  root = null
  partGroups = []
  partMeta = []
  hasLodData = false
  hasDamageData = false
  currentLodRank = 0
  globalMaxRank = 0
  lodRefMaxDim = 1
  availableTextures = []
  activeTexture = null
  manifestBaseDir = ''
  textureNameToUrl = {}
  perMaterialMode = false
  resetInspectPanelUI()
}

function resetInspectPanelUI() {
  if (partsPanel) partsPanel.innerHTML = ''
  if (presetsBar) {
    presetsBar.innerHTML = ''
    presetsBar.style.display = 'none'
  }
  if (vehicleVariantControls) vehicleVariantControls.style.display = 'none'
  if (vehicleDamagedCb) vehicleDamagedCb.checked = false
  if (vehicleBothCb) vehicleBothCb.checked = false
  if (vehicleBothWrap) vehicleBothWrap.style.display = 'none'
  if (lodAutoCb) lodAutoCb.checked = false
  if (lodSlider) lodSlider.disabled = false
  if (lodControls) lodControls.style.display = 'none'
  if (texSelector) texSelector.style.display = 'none'
  if (texSelect) texSelect.innerHTML = ''
  if (inspectPanel) inspectPanel.style.display = 'none'
  updateLodBadge()
}

/* ── Camera fit (FOV-aware, matching preview.html) ── */
function fitCameraToObject(object) {
  const box = new THREE.Box3().setFromObject(object)
  if (box.isEmpty()) return
  const size = box.getSize(new THREE.Vector3())
  const center = box.getCenter(new THREE.Vector3())
  const maxDim = Math.max(size.x, size.y, size.z, 0.5)
  const dist = (maxDim * 1.8) / Math.tan((camera.fov * Math.PI) / 360)
  controls.target.copy(center)
  camera.position.copy(center.clone().add(new THREE.Vector3(dist * 0.55, dist * 0.35, dist * 0.55)))
  camera.near = Math.max(0.001, maxDim / 2000)
  camera.far = Math.max(5000, maxDim * 50)
  camera.updateProjectionMatrix()
  controls.update()

  const gridSpan = Math.min(Math.max(maxDim * 6, 12), 500000)
  const divisions = Math.min(80, Math.max(12, Math.round(gridSpan / Math.max(maxDim, 0.01))))
  scene.remove(grid)
  grid.geometry?.dispose?.()
  if (grid.material) {
    if (Array.isArray(grid.material)) grid.material.forEach((m) => m.dispose?.())
    else grid.material.dispose?.()
  }
  grid = new THREE.GridHelper(gridSpan, divisions, 0x444444, 0x333333)
  grid.position.y = box.min.y
  scene.add(grid)

  lodRefMaxDim = maxDim
}

/** Shift loaded content so its world AABB center is at the origin (for single OBJ/glTF only). */
function recenterLoadedGroup(obj) {
  obj.updateMatrixWorld(true)
  const box = new THREE.Box3().setFromObject(obj)
  if (box.isEmpty()) return
  const center = box.getCenter(new THREE.Vector3())
  obj.position.sub(center)
  obj.updateMatrixWorld(true)
}

/* ── LOD / damage filter logic (matches mercs2_preview.html) ── */
function readDamageVariantOpts() {
  return {
    preferDamaged: vehicleDamagedCb?.checked ?? false,
    showBoth: vehicleBothCb?.checked ?? false,
  }
}

function isPartDefault(entry, lodTargetRank) {
  const { preferDamaged, showBoth } = readDamageVariantOpts()
  if (!passesDamageVariantFilter(entry, preferDamaged, showBoth)) return false
  if (!hasLodData) return true
  const maxRanks = lodGroupMaxRank(partMeta)
  const rank = entry.lod_rank ?? 0
  const group = entry.lod_group
  const groupMax = group != null ? maxRanks[group] || 0 : 0
  if (entry.is_vehicle_lod) {
    return lodTargetRank >= globalMaxRank && rank === Math.min(lodTargetRank, groupMax)
  }
  return rank === Math.min(lodTargetRank, groupMax)
}

function applyFilters() {
  for (let i = 0; i < partGroups.length; i++) {
    const entry = partMeta[i] || {}
    const on = isPartDefault(entry, currentLodRank)
    partGroups[i].visible = on
    const cb = partsPanel?.querySelector?.(`input[data-idx="${i}"]`)
    if (cb) cb.checked = on
  }
}

function setAllParts(vis) {
  partGroups.forEach((g, i) => {
    g.visible = vis
    const cb = partsPanel?.querySelector?.(`input[data-idx="${i}"]`)
    if (cb) cb.checked = vis
  })
}

function isolateCategory(cat) {
  partGroups.forEach((g, i) => {
    const entry = partMeta[i] || {}
    const c = classifyPart(entry)
    const show = c === cat
    g.visible = show
    const cb = partsPanel?.querySelector?.(`input[data-idx="${i}"]`)
    if (cb) cb.checked = show
  })
}

/* ── Texture application ── */
function applyTextureToAllParts(texture) {
  perMaterialMode = false
  activeTexture = texture
  for (let i = 0; i < partGroups.length; i++) {
    const entry = partMeta[i] || {}
    partGroups[i].traverse((child) => {
      if (child.isMesh) {
        if (child.material) child.material.dispose()
        child.material = makeMaterial(entry.lod_group ?? i, entry, texture)
      }
    })
  }
}

async function applyPerMaterialTextures() {
  perMaterialMode = true
  activeTexture = null
  const flipV = texFlipV ? texFlipV.checked : false
  let loadedOk = 0
  let loadFailed = 0
  let missingManifestUrl = 0
  for (let i = 0; i < partGroups.length; i++) {
    const entry = partMeta[i] || {}
    const diffuseName = entry.texture_diffuse
    const url = diffuseName ? textureNameToUrl[diffuseName] : null
    let tex = null
    if (diffuseName && !url) {
      missingManifestUrl++
      console.warn(
        `[textures] part #${i}: diffuse name "${diffuseName}" has no textures/manifest.json entry (no png URL).`,
      )
    }
    if (url) {
      try {
        tex = await loadTexture(url, flipV)
        loadedOk++
      } catch (err) {
        loadFailed++
        console.warn(`[textures] part #${i}: failed to load "${diffuseName}" from ${url}`, err)
      }
    }
    partGroups[i].traverse((child) => {
      if (child.isMesh) {
        if (child.material) child.material.dispose()
        child.material = makeMaterial(entry.lod_group ?? i, entry, tex)
      }
    })
  }
  const withDiffuse = partMeta.filter((e) => e && e.texture_diffuse).length
  const summary = `per-material: ${loadedOk} textures loaded, ${loadFailed} load errors, ${missingManifestUrl} missing URL (${withDiffuse} parts with diffuse)`
  console.info(`[textures] ${summary}`)
  if (statusEl) {
    statusEl.textContent = statusEl.textContent.replace(/\nPer-material:.*$/m, '') + `\nPer-material: ${summary}`
  }
}

function manifestHasVehicleLodMeshes() {
  return partMeta.some((e) => e && (e.is_vehicle_lod === true || classifyPart(e) === 'vehicle_lod'))
}

function updateLodBadge() {
  const el = document.getElementById('inspect-lod-badge')
  if (!el) return
  if (!hasLodData || globalMaxRank <= 0) {
    el.textContent = ''
    el.style.display = 'none'
    return
  }
  el.style.display = 'inline-block'
  const auto = lodAutoCb?.checked
  el.textContent = auto ? `LOD L${currentLodRank} (auto)` : `LOD L${currentLodRank} (manual)`
}

/** Ensure glTF-imported PBR materials pick up scene.environment at a sane strength. */
function applyPbrEnvHintsToObject(obj) {
  if (!obj) return
  obj.traverse((o) => {
    if (!o.isMesh || !o.material) return
    const list = Array.isArray(o.material) ? o.material : [o.material]
    for (const m of list) {
      if (m && 'envMapIntensity' in m && m.envMapIntensity !== undefined) {
        m.envMapIntensity = 1.35
        m.needsUpdate = true
      }
    }
  })
}

function autoLodRankFromCamera() {
  if (!root || globalMaxRank <= 0) return 0
  const dist = camera.position.distanceTo(controls.target)
  const ratio = dist / Math.max(lodRefMaxDim, 1e-6)
  // Keep L0 until the camera is far out (ratio > lo); widened band so characters do not swap
  // to crude silhouette LODs at normal orbit distances.
  const lo = 4
  const hi = 20
  const t = THREE.MathUtils.clamp((ratio - lo) / (hi - lo), 0, 1)
  return Math.round(t * globalMaxRank)
}

/* ── Build parts UI (ported from preview.html buildPartsUI) ── */
function buildPartsUI() {
  inspectUiAbort?.abort()
  inspectUiAbort = new AbortController()
  const { signal } = inspectUiAbort

  partsPanel.innerHTML = ''
  presetsBar.innerHTML = ''

  if (partGroups.length < 2) {
    presetsBar.style.display = 'none'
    if (inspectPanel) inspectPanel.style.display = 'none'
    return
  }

  if (inspectPanel) {
    inspectPanel.style.display = 'block'
    inspectPanel.open = true
  }
  presetsBar.style.display = 'block'

  hasLodData = partMeta.some((e) => e.lod_group != null && e.lod_rank != null)
  hasDamageData = partMeta.some((e) => e.damage_state && e.damage_state !== 'shared')
  const maxRanks = lodGroupMaxRank(partMeta)
  const numLodGroups = Object.values(maxRanks).filter((r) => r > 0).length

  /* vehicle damage / switch variant (not LOD) */
  if (hasDamageData && vehicleVariantControls) {
    vehicleVariantControls.style.display = 'block'
    const hasSwitch = partMeta.some((e) => String(getDamageState(e)).startsWith('switch_'))
    const intactN = partMeta.filter((e) => getDamageState(e) === 'intact').length
    const damagedN = partMeta.filter((e) => getDamageState(e) === 'damaged').length
    const showBothOption = hasSwitch || (intactN > 0 && damagedN > 0)
    if (vehicleBothWrap) vehicleBothWrap.style.display = showBothOption ? 'block' : 'none'
    if (vehicleDamagedCb) vehicleDamagedCb.checked = false
    if (vehicleBothCb) vehicleBothCb.checked = false

    const onVarChange = () => applyFilters()
    vehicleDamagedCb?.addEventListener('change', onVarChange, { signal })
    vehicleBothCb?.addEventListener('change', onVarChange, { signal })
  }

  /* LOD: auto from camera distance, or manual slider */
  if (hasLodData && numLodGroups > 0) {
    globalMaxRank = Math.max(...Object.values(maxRanks), 0)
    lodControls.style.display = 'block'
    lodSlider.max = String(globalMaxRank)
    lodSlider.value = '0'
    currentLodRank = 0
    const vehicleLod = manifestHasVehicleLodMeshes()
    if (lodAutoCb) lodAutoCb.checked = vehicleLod
    lodLabel.textContent = lodAutoCb?.checked ? 'L0 auto' : 'L0'
    lodSlider.disabled = !!lodAutoCb?.checked

    const syncLodFromSlider = () => {
      const rank = parseInt(lodSlider.value, 10)
      currentLodRank = rank
      if (lodLabel) lodLabel.textContent = lodAutoCb?.checked ? `L${rank} auto` : `L${rank}`
      updateLodBadge()
      applyFilters()
    }

    lodSlider.addEventListener('input', () => syncLodFromSlider(), { signal })

    lodAutoCb?.addEventListener(
      'change',
      () => {
        if (lodAutoCb.checked) {
          lodSlider.disabled = true
          currentLodRank = autoLodRankFromCamera()
          lodSlider.value = String(currentLodRank)
          if (lodLabel) lodLabel.textContent = `L${currentLodRank} auto`
          updateLodBadge()
          applyFilters()
        } else {
          lodSlider.disabled = false
          const rank = parseInt(lodSlider.value, 10)
          currentLodRank = rank
          if (lodLabel) lodLabel.textContent = `L${rank}`
          updateLodBadge()
          applyFilters()
        }
      },
      { signal },
    )
  }

  if (hasLodData && globalMaxRank > 0) {
    const pin = document.createElement('span')
    pin.className = 'inspect-preset-btn'
    pin.title = 'Force highest-detail LOD (rank 0) and turn off distance-based auto LOD'
    pin.textContent = 'Pin L0'
    pin.addEventListener(
      'click',
      () => {
        if (lodAutoCb) lodAutoCb.checked = false
        if (lodSlider) {
          lodSlider.disabled = false
          lodSlider.value = '0'
        }
        currentLodRank = 0
        if (lodLabel) lodLabel.textContent = 'L0'
        updateLodBadge()
        applyFilters()
      },
      { signal },
    )
    presetsBar.appendChild(pin)
  }

  /* category preset buttons */
  const cats = new Set(partMeta.map((e) => classifyPart(e)))
  const presets = [
    { label: 'Show All', fn: () => setAllParts(true) },
    { label: 'Hide All', fn: () => setAllParts(false) },
  ]
  if (cats.has('wheel')) presets.push({ label: 'Wheels', fn: () => isolateCategory('wheel') })
  if (cats.has('body')) presets.push({ label: 'Body', fn: () => isolateCategory('body') })
  if (cats.has('panel')) presets.push({ label: 'Panels', fn: () => isolateCategory('panel') })
  if (cats.has('accessory')) presets.push({ label: 'Accessories', fn: () => isolateCategory('accessory') })
  if (cats.has('glass')) presets.push({ label: 'Glass', fn: () => isolateCategory('glass') })
  if (cats.has('vehicle_lod')) presets.push({ label: 'Vehicle LODs', fn: () => isolateCategory('vehicle_lod') })

  const presetsLabel = document.createElement('div')
  presetsLabel.className = 'inspect-section-label'
  presetsLabel.textContent = 'Filter by type'
  presetsBar.appendChild(presetsLabel)

  for (const p of presets) {
    const btn = document.createElement('span')
    btn.className = 'inspect-preset-btn'
    btn.textContent = p.label
    btn.addEventListener('click', p.fn, { signal })
    presetsBar.appendChild(btn)
  }

  /* per-part checkboxes */
  const panelLabel = document.createElement('div')
  panelLabel.className = 'inspect-section-label'
  panelLabel.textContent = `Parts (${partGroups.length})`
  partsPanel.appendChild(panelLabel)

  for (let i = 0; i < partGroups.length; i++) {
    const entry = partMeta[i] || {}
    const cat = classifyPart(entry)
    const rank = entry.lod_rank ?? 0
    const groupMax = entry.lod_group != null ? maxRanks[entry.lod_group] || 0 : 0
    const lodTag = groupMax > 0 ? ` L${rank}` : ''
    const ds = getDamageState(entry)
    const dsTag = hasDamageData && ds !== 'shared' ? ` ${ds}` : ''
    const lbl = document.createElement('label')
    const cb = document.createElement('input')
    cb.type = 'checkbox'
    cb.checked = true
    cb.dataset.idx = String(i)
    cb.addEventListener(
      'change',
      () => {
        partGroups[i].visible = cb.checked
      },
      { signal }
    )
    const verts = entry.vertices ?? '?'
    const faces = entry.faces ?? '?'
    lbl.appendChild(cb)
    const matTag = entry.material_index != null ? ` M${entry.material_index}` : ''
    lbl.append(` #${i} [${cat}${lodTag}${dsTag}${matTag}] ${verts}v ${faces}f`)
    if (rank > 0) lbl.style.opacity = '0.55'
    if (entry.transparent) lbl.style.color = '#88ddbb'
    else if (ds.startsWith('switch_') && ds.endsWith('_1')) lbl.style.color = '#e8a060'
    else if (ds.startsWith('switch_') && ds.endsWith('_0')) lbl.style.color = '#80c8e8'
    partsPanel.appendChild(lbl)
  }

  applyFilters()
  updateLodBadge()
}

/* ── Texture manifest loading (ported from preview.html) ── */
async function loadTextureManifestForRoot(baseDir, signal) {
  const texManifestUrl = baseDir + 'textures/manifest.json?_t=' + Date.now()
  try {
    const res = await fetch(texManifestUrl)
    if (!res.ok) {
      console.warn(`[textures] manifest HTTP ${res.status} ${res.statusText}: ${texManifestUrl}`)
      return
    }
    const data = await res.json()
    const textures = data.textures || []
    const fullRes = {}
    textureNameToUrl = {}
    for (const t of textures) {
      if (!t.png) continue
      const ms = t.mip_start_logical || 0
      fullRes[t.name] = { w: t.width << ms, h: t.height << ms }
      textureNameToUrl[t.name] = baseDir + 'textures/' + t.png
    }
    availableTextures = textures
      .filter((t) => t.png && !t.name.endsWith('_nm') && !t.name.endsWith('_sm'))
      .map((t) => {
        const fr = fullRes[t.name] || { w: t.width, h: t.height }
        const tag = fr.w > t.width ? ` [mip of ${fr.w}×${fr.h}]` : ''
        return {
          name: t.name,
          url: baseDir + 'textures/' + t.png,
          width: t.width,
          height: t.height,
          fullW: fr.w,
          fullH: fr.h,
          tag,
        }
      })
    if (availableTextures.length === 0) return

    if (texSelect) {
      texSelect.innerHTML = '<option value="">(color only)</option>'
      texSelect.innerHTML += '<option value="__auto__">Auto (per-material)</option>'
      for (const t of availableTextures) {
        const opt = document.createElement('option')
        opt.value = t.url
        opt.textContent = `${t.name} (${t.width}×${t.height}${t.tag})`
        texSelect.appendChild(opt)
      }
    }
    if (texSelector) texSelector.style.display = 'block'

    /* wire texture select + flip-v events */
    if (texSelect) {
      texSelect.addEventListener(
        'change',
        async () => {
          const url = texSelect.value
          if (!root) return
          if (!url) {
            applyTextureToAllParts(null)
            statusEl.textContent = statusEl.textContent.replace(/\nTexture:.*$/m, '')
            return
          }
          if (url === '__auto__') {
            await applyPerMaterialTextures()
            statusEl.textContent =
              statusEl.textContent.replace(/\nTexture:.*$/m, '') + '\nTexture: per-material (auto)'
            return
          }
          try {
            const flipV = texFlipV ? texFlipV.checked : false
            const tex = await loadTexture(url, flipV)
            applyTextureToAllParts(tex)
            const name = availableTextures.find((t) => t.url === url)?.name || url
            statusEl.textContent =
              statusEl.textContent.replace(/\nTexture:.*$/m, '') + `\nTexture: ${name}`
          } catch (err) {
            statusEl.textContent += `\nTexture load failed: ${err}`
          }
        },
        { signal }
      )
    }

    if (texFlipV) {
      texFlipV.addEventListener(
        'change',
        async () => {
          clearTextureCache()
          const url = texSelect ? texSelect.value : ''
          if (!root || !url) return
          try {
            if (url === '__auto__') {
              await applyPerMaterialTextures()
            } else {
              const tex = await loadTexture(url, texFlipV.checked)
              applyTextureToAllParts(tex)
            }
          } catch {
            /* ignore */
          }
        },
        { signal }
      )
    }

    /* auto-select per-material mode if texture_diffuse data exists */
    const hasPerMat = partMeta.some((e) => e && e.texture_diffuse)
    if (hasPerMat && texSelect) {
      texSelect.value = '__auto__'
      perMaterialMode = true
      if (!signal?.aborted) await applyPerMaterialTextures()
    }
  } catch (e) {
    console.warn('[textures] manifest load failed:', texManifestUrl, e)
  }
}

/** Pipeline exports sometimes embed NaN in bbox arrays; strict JSON.parse rejects those. */
function parseManifestJsonArray(rawText) {
  const patched = rawText
    .replace(/\bNaN\b/g, 'null')
    .replace(/\b-Infinity\b/g, 'null')
    .replace(/\bInfinity\b/g, 'null')
  return JSON.parse(patched)
}

/* ── Manifest loading (ported directly from preview.html) ── */
async function loadManifest(manifestUrl) {
  disposeRoot()
  statusEl.textContent = 'Loading manifest…'

  const baseUrl = manifestUrl.substring(0, manifestUrl.lastIndexOf('/') + 1)
  manifestBaseDir = baseUrl.substring(0, baseUrl.lastIndexOf('submeshes/'))

  try {
    const res = await fetch(manifestUrl)
    if (!res.ok) throw new Error(`${res.status} ${res.statusText}`)
    const entries = parseManifestJsonArray(await res.text())

    root = new THREE.Group()
    let loaded = 0

    for (let i = 0; i < entries.length; i++) {
      const entry = entries[i]
      const objUrl = baseUrl + entry.file
      try {
        const objRes = await fetch(objUrl)
        if (!objRes.ok) continue
        const text = await objRes.text()
        const obj = await loadObjText(text, entry.lod_group ?? i, entry)
        root.add(obj)
        partGroups.push(obj)
        partMeta.push(entry)
        loaded++
      } catch {
        /* skip broken submeshes */
      }
      if (i % 20 === 0) statusEl.textContent = `Loading submeshes… ${i + 1}/${entries.length}`
    }

    scene.add(root)
    fitCameraToObject(root)
    buildPartsUI()

    const signal = inspectUiAbort?.signal
    await loadTextureManifestForRoot(manifestBaseDir, signal)

    const box = new THREE.Box3().setFromObject(root)
    const sz = box.getSize(new THREE.Vector3())
    const lodGroups = new Set(entries.filter((e) => e.lod_group != null).map((e) => e.lod_group)).size
    const intactCount = entries.filter((e) => e.damage_state === 'intact').length
    const damagedCount = entries.filter((e) => e.damage_state === 'damaged').length
    const matIndices = new Set(
      entries.filter((e) => e.material_index != null).map((e) => e.material_index)
    ).size
    const transparentCount = entries.filter((e) => e.transparent).length
    const dmgInfo = damagedCount > 0 ? `, ${intactCount} intact / ${damagedCount} damaged` : ''
    const matInfo = matIndices > 0 ? `, ${matIndices} materials` : ''
    const trInfo = transparentCount > 0 ? `, ${transparentCount} transparent` : ''
    statusEl.textContent = `Loaded ${loaded}/${entries.length} submeshes (${lodGroups} LOD groups${dmgInfo}${matInfo}${trInfo}). Size: ${sz.x.toFixed(2)} × ${sz.y.toFixed(2)} × ${sz.z.toFixed(2)}`
    reloadAnimIfSelected()
  } catch (e) {
    console.error(e)
    statusEl.textContent = `Manifest error: ${e.message || e}`
  }
}

/* ── Single OBJ / glTF loading ── */
async function loadFromInputs() {
  const objUrl = document.getElementById('objUrl').value.trim()
  const gltfUrl = document.getElementById('gltfUrl').value.trim()
  const ddsUrl = document.getElementById('ddsUrl').value.trim()

  disposeRoot()
  statusEl.textContent = 'Loading…'

  try {
    let texture = null
    if (ddsUrl) {
      const tex = await new Promise((resolve, reject) => {
        new DDSLoader().load(ddsUrl, resolve, undefined, reject)
      })
      configureColorTexture(tex)
      texture = tex
    }

    if (gltfUrl) {
      const gltf = await new Promise((resolve, reject) => {
        new GLTFLoader().load(gltfUrl, resolve, undefined, reject)
      })
      root = gltf.scene
      if (texture) {
        root.traverse((c) => {
          if (c.isMesh && c.material) {
            const m = c.material
            if (m.map) return
            m.map = texture
            m.needsUpdate = true
          }
        })
      }
      applyPbrEnvHintsToObject(root)
      scene.add(root)
      recenterLoadedGroup(root)
      fitCameraToObject(root)
      const box = new THREE.Box3().setFromObject(root)
      const sz = box.getSize(new THREE.Vector3())
      statusEl.textContent = `Loaded glTF: ${gltfUrl}\nSize: ${sz.x.toFixed(2)} × ${sz.y.toFixed(2)} × ${sz.z.toFixed(2)}`
      reloadAnimIfSelected()
      return
    }

    if (objUrl) {
      const obj = await new Promise((resolve, reject) => {
        new OBJLoader().load(objUrl, resolve, undefined, reject)
      })
      obj.traverse((c) => {
        if (c.isMesh) {
          c.geometry = ensureNormals(c.geometry)
          c.material = makeMaterial(0, null, texture)
        }
      })
      root = obj
      scene.add(root)
      recenterLoadedGroup(root)
      fitCameraToObject(root)
      const box = new THREE.Box3().setFromObject(root)
      const sz = box.getSize(new THREE.Vector3())
      statusEl.textContent = `Loaded OBJ: ${objUrl}\nSize: ${sz.x.toFixed(2)} × ${sz.y.toFixed(2)} × ${sz.z.toFixed(2)}`
      reloadAnimIfSelected()
      return
    }

    statusEl.textContent = 'Enter at least one mesh URL or pick from the list.'
  } catch (e) {
    console.error(e)
    statusEl.textContent = `Error: ${e.message || e}`
  }
}

/* ── UI wiring ── */
document.getElementById('loadBtn').addEventListener('click', loadFromInputs)

window.addEventListener('resize', syncCanvasToViewport)
if (typeof ResizeObserver !== 'undefined') {
  const ro = new ResizeObserver(() => syncCanvasToViewport())
  ro.observe(viewport)
}
requestAnimationFrame(() => {
  requestAnimationFrame(syncCanvasToViewport)
})

/* Skeletal animation state — must be declared before animate() (TDZ if placed below). */
const animClock = new THREE.Clock()
let animMixer = null
let animRoot = null
let animActions = []
let animSkeletonHelper = null
let animList = []
/** @type {{ clips?: object[], stemNumericId?: string, relatedReviewKeys?: string[], slug?: string } | null} */
let currentAnimSidecar = null

function clipRowDisplayName(row) {
  if (!row || typeof row !== 'object') return null
  return row.display_name || row.displayName || null
}

function updateAnimReviewHint(meta) {
  const el = document.getElementById('animReviewHint')
  if (!el) return
  el.replaceChildren()
  el.style.display = 'none'
  if (!meta) return
  const id = meta.stemNumericId ?? meta.stem_numeric_id
  const keys = meta.relatedReviewKeys ?? meta.related_review_keys ?? []
  if (!id && (!keys || keys.length === 0)) return
  el.style.display = 'block'
  const line = document.createElement('div')
  line.style.lineHeight = '1.45'
  if (id) {
    line.appendChild(document.createTextNode(`Batch mesh filter hint: numeric stem `))
    const code = document.createElement('code')
    code.style.fontSize = '10px'
    code.textContent = id
    line.appendChild(code)
    const b = document.createElement('button')
    b.type = 'button'
    b.textContent = 'Set asset filter'
    b.style.cssText = 'font-size:10px;padding:2px 8px;margin-left:8px;cursor:pointer;border-radius:4px'
    b.addEventListener('click', () => {
      const inp = document.getElementById('assetFilter')
      if (inp) {
        inp.value = id
        renderReviewList()
      }
    })
    line.appendChild(b)
  }
  el.appendChild(line)
  if (keys && keys.length > 0) {
    const p = document.createElement('div')
    p.style.marginTop = '5px'
    p.style.opacity = '0.92'
    const shown = keys.slice(0, 5)
    p.textContent = `Related review keys (${keys.length}): ${shown.join(' · ')}${keys.length > shown.length ? ' …' : ''}`
    el.appendChild(p)
  }
}

function animate() {
  requestAnimationFrame(animate)
  controls.update()
  // Pin the camera-facing fill light to the current camera position AND target so the light
  // always shines from "behind the user" at whatever they're orbiting.  Without setting the
  // target explicitly, DirectionalLight points at world origin (the feet of a stand-up model),
  // which leaves the face / chest in shadow whenever the user lifts the orbit target.
  cameraFill.position.copy(camera.position)
  cameraFill.target.position.copy(controls.target)

  // Key + rim track the orbit target but sit relative to the current view so zoom/orbit does
  // not leave the whole torso in shadow (a fixed world-space key goes "past" the model when
  // the camera dollies or orbits).
  _keyRimDir.subVectors(controls.target, camera.position)
  const dist = _keyRimDir.length()
  if (_keyRimDir.lengthSq() < 1e-12) _keyRimDir.set(0, 0, 1)
  else _keyRimDir.multiplyScalar(1 / dist)

  const ref = Math.max(lodRefMaxDim, 0.01)
  // Size-aware offsets: fixed 1.5 / 4.2 world units mis-scaled tiny vs huge assets and could
  // sit the key unrealistically close to the pivot when zoomed (harsh meridian + near-black zoom-out).
  const keyArm = Math.min(ref * 0.9, dist * 0.38)
  const keyUpOff = Math.max(ref * 0.12, 0.12)
  keyLight.position.copy(camera.position).addScaledVector(_keyRimDir, keyArm).addScaledVector(_keyRimUp, keyUpOff)
  _keyFromTarget.subVectors(keyLight.position, controls.target)
  const minKeyRadius = Math.max(ref * 0.2, 0.18)
  if (_keyFromTarget.lengthSq() < minKeyRadius * minKeyRadius) {
    _keyFromTarget.setLength(minKeyRadius)
    keyLight.position.copy(controls.target).add(_keyFromTarget)
  }
  keyLight.target.position.copy(controls.target)

  _keyRimSide.crossVectors(_keyRimDir, _keyRimUp)
  if (_keyRimSide.lengthSq() < 1e-8) _keyRimSide.set(1, 0, 0)
  const rimSide = Math.max(ref * 0.55, 0.6)
  const rimUp = Math.max(ref * 0.32, 0.35)
  _keyRimSide.normalize().multiplyScalar(rimSide)
  rimLight.position.copy(controls.target).add(_keyRimSide).addScaledVector(_keyRimUp, rimUp)
  rimLight.target.position.copy(controls.target)
  if (animMixer) {
    animMixer.update(animClock.getDelta())
    syncAnimScrubFromMixer()
  }

  if (root && hasLodData && globalMaxRank > 0 && lodAutoCb?.checked) {
    const r = autoLodRankFromCamera()
    if (r !== currentLodRank) {
      console.info(`[viewer][lod] auto rank ${currentLodRank} -> ${r} (camera/character ratio)`)
      currentLodRank = r
      if (lodSlider) lodSlider.value = String(r)
      if (lodLabel) lodLabel.textContent = `L${r} auto`
      updateLodBadge()
      applyFilters()
    }
  }
  if (lodSlider && lodAutoCb) lodSlider.disabled = !!lodAutoCb.checked

  renderer.render(scene, camera)
}
animate()

/* ── Skeletal animation panel (pipeline output/animations) ── */

function clearAnimScene() {
  if (animSkeletonHelper) {
    scene.remove(animSkeletonHelper)
    if (animSkeletonHelper.dispose) animSkeletonHelper.dispose()
    animSkeletonHelper = null
  }
  if (animRoot) {
    scene.remove(animRoot)
    animRoot.traverse((o) => {
      if (o.geometry) o.geometry.dispose?.()
      if (o.material) {
        const m = o.material
        if (Array.isArray(m)) m.forEach((x) => x.dispose?.())
        else m.dispose?.()
      }
    })
    animRoot = null
  }
  animMixer = null
  animActions = []
}

function syncAnimScrubFromMixer() {
  const scrub = document.getElementById('animScrub')
  if (!scrub || !animMixer || animActions.length === 0) return
  const a = animActions.find((x) => x && x.isRunning())
  if (!a || !a.getClip()) return
  const d = a.getClip().duration || 1
  scrub.value = String(Math.min(1, Math.max(0, animMixer.time / d)))
}

async function loadAnimIndex() {
  const sel = document.getElementById('animGlbSelect')
  if (!sel) return
  try {
    const res = await fetch('/api/anim-assets.json')
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const data = await res.json()
    animList = data.animations || []
    sel.innerHTML = ''
    if (animList.length === 0) {
      const o = document.createElement('option')
      o.value = ''
      o.textContent = '(none — run mercs2_anim_pipeline)'
      sel.appendChild(o)
      return
    }
    {
      const placeholder = document.createElement('option')
      placeholder.value = ''
      placeholder.textContent = '(select character)'
      sel.appendChild(placeholder)
    }
    for (const a of animList) {
      const o = document.createElement('option')
      o.value = a.url
      o.textContent = a.slug
      sel.appendChild(o)
    }
  } catch (e) {
    console.warn('anim index', e)
  }
}

function setAnimPanelHint(msg) {
  const el = document.getElementById('animPanelHint')
  if (el) el.textContent = msg || ''
}

function findFirstSkinnedMesh(obj) {
  let found = null
  if (!obj) return null
  obj.traverse((o) => {
    if (!found && o.isSkinnedMesh && o.skeleton?.bones?.length) found = o
  })
  return found
}

function countBones(obj) {
  let n = 0
  if (!obj) return 0
  obj.traverse((o) => {
    if (o.isBone) n++
  })
  return n
}

function pipelineSkinnedVertexCount(obj) {
  const sm = findFirstSkinnedMesh(obj)
  const pos = sm?.geometry?.attributes?.position
  return pos?.count ?? 0
}

function reloadAnimIfSelected() {
  const url = document.getElementById('animGlbSelect')?.value
  if (url) void loadAnimGltf(url)
}

async function loadAnimGltf(url) {
  clearAnimScene()
  if (!url) {
    currentAnimSidecar = null
    updateAnimReviewHint(null)
    return
  }
  currentAnimSidecar = animList.find((a) => a.url === url) || null
  if (currentAnimSidecar && !currentAnimSidecar.clips && currentAnimSidecar.slug) {
    try {
      const r = await fetch(`/api/anim-detail.json?slug=${encodeURIComponent(currentAnimSidecar.slug)}`)
      if (r.ok) {
        const d = await r.json()
        currentAnimSidecar = {
          ...currentAnimSidecar,
          clips: d.clips,
          blockStem: d.block_stem,
          stemNumericId: d.stem_numeric_id,
          relatedReviewKeys: d.related_review_keys,
        }
      }
    } catch {
      /* keep index-only metadata */
    }
  }
  updateAnimReviewHint(currentAnimSidecar)

  try {
    const loader = new GLTFLoader()
    const gltf = await new Promise((resolve, reject) => {
      loader.load(url, resolve, undefined, reject)
    })
    animRoot = gltf.scene
    applyPbrEnvHintsToObject(animRoot)

    // Clips from this GLB target *this file's* node names (e.g. bone_0). The mixer root must be animRoot.
    // A previous "drive mesh" path mixed on `root` without retargeting and skipped scene.add(animRoot), so nothing moved.
    scene.add(animRoot)

    const driveMesh = document.getElementById('animDriveMeshCb')?.checked === true
    const reviewSkinned = findFirstSkinnedMesh(root)
    const pipeSkinned = findFirstSkinnedMesh(animRoot)
    const boneN = countBones(animRoot)
    const pipeVerts = pipelineSkinnedVertexCount(animRoot)

    const skelStatus = gltf.parser?.json?.asset?.extras?.skeleton_status || 'unknown'

    if (skelStatus === 'unknown') {
      const bits = []
      if (boneN > 0) bits.push(`${boneN} tracks`)
      bits.push('skeleton: not decoded')
      setAnimPanelHint(
        `${bits.join(' \u00b7 ')}. Clips target flat placeholder nodes \u2014 no real bind pose. See skeleton_status in GLB extras.`,
      )
    } else if (driveMesh && root && reviewSkinned) {
      setAnimPanelHint(
        'Retarget to a separately loaded glTF is not implemented — clips play on the pipeline armature next to your mesh. Turn this checkbox off.',
      )
    } else if (driveMesh && root && !reviewSkinned) {
      setAnimPanelHint(
        'Load a skinned review glTF in the main viewer first, or turn off retarget. Clips play on the pipeline armature.',
      )
    } else {
      const bits = []
      if (boneN > 0) bits.push(`${boneN} bones`)
      if (pipeSkinned && pipeVerts > 0) bits.push(`SkinnedMesh ${pipeVerts} verts`)
      bits.push(`skeleton: ${skelStatus}`)
      const stats = bits.length ? `${bits.join(' · ')}. ` : ''
      setAnimPanelHint(
        `${stats}Clips play on this GLB’s armature (Havok decode: wavelet / interleaved / delta).`,
      )
    }

    animClock.getDelta() /* flush accumulated time so first mixer frame is not huge */

    animMixer = new AnimationMixer(animRoot)
    animActions = (gltf.animations || []).map((clip) => animMixer.clipAction(clip))
    const clipRows = Array.isArray(currentAnimSidecar?.clips) ? currentAnimSidecar.clips : []
    const clipSel = document.getElementById('animClipSelect')
    if (clipSel) {
      clipSel.innerHTML = ''
      for (let i = 0; i < (gltf.animations || []).length; i++) {
        const c = gltf.animations[i]
        const o = document.createElement('option')
        o.value = String(i)
        const row = clipRows.find((x) => Number(x.gltf_clip_index) === i) || clipRows[i]
        const fromManifest = clipRowDisplayName(row)
        const gltfName = c.name || ''
        const poor = !gltfName || /^\d+$/.test(String(gltfName).trim())
        o.textContent = fromManifest || (!poor ? gltfName : `clip_${i}`)
        clipSel.appendChild(o)
      }
    }
    if (animActions[0]) {
      animActions.forEach((a) => a.stop())
      animActions[0].reset().play()
    }
    const sk = document.getElementById('animSkeletonCb')
    if (sk?.checked) {
      let boneCount = 0
      animRoot.traverse((o) => {
        if (o.isBone) boneCount++
      })
      if (boneCount > 0) {
        animSkeletonHelper = new THREE.SkeletonHelper(animRoot)
        scene.add(animSkeletonHelper)
      } else {
        setAnimPanelHint(
          (document.getElementById('animPanelHint')?.textContent || '') +
            ' No THREE.Bone nodes on pipeline armature — skeleton helper skipped (export may use Object3D joints only).',
        )
      }
    }
  } catch (e) {
    console.error('loadAnimGltf', e)
    setAnimPanelHint(`Failed to load animation: ${e?.message || e}`)
  }
}

document.getElementById('animPlayBtn')?.addEventListener('click', () => {
  const i = Number(document.getElementById('animClipSelect')?.value || 0)
  if (!animMixer || !animActions[i]) return
  animActions.forEach((a) => a.stop())
  animActions[i].reset().play()
})
document.getElementById('animPauseBtn')?.addEventListener('click', () => {
  animActions.forEach((a) => a.stop())
})
document.getElementById('animGlbSelect')?.addEventListener('change', (e) => {
  void loadAnimGltf(e.target.value)
})
document.getElementById('animClipSelect')?.addEventListener('change', (e) => {
  const i = Number(e.target.value)
  if (!animMixer || !animActions[i]) return
  animActions.forEach((a) => a.stop())
  animActions[i].reset().play()
})
document.getElementById('animScrub')?.addEventListener('input', (e) => {
  if (!animMixer || animActions.length === 0) return
  const a = animActions.find((x) => x && x.isRunning()) || animActions[0]
  if (!a || !a.getClip()) return
  const d = a.getClip().duration || 1
  animMixer.setTime(Number(e.target.value) * d)
})
document.getElementById('animSkeletonCb')?.addEventListener('change', () => {
  const url = document.getElementById('animGlbSelect')?.value
  if (url) void loadAnimGltf(url)
})
document.getElementById('animDriveMeshCb')?.addEventListener('change', () => {
  const url = document.getElementById('animGlbSelect')?.value
  if (url) void loadAnimGltf(url)
})

void loadAnimIndex()

/* ── Review asset index (stage 2 output) ── */

let reviewAssets = []
let packCountsFromApi = {}

function interleaveByPack(assets) {
  const byPack = new Map()
  for (const a of assets) {
    if (!byPack.has(a.pack)) byPack.set(a.pack, [])
    byPack.get(a.pack).push(a)
  }
  const packs = [...byPack.keys()].sort()
  for (const p of packs) {
    byPack.get(p).sort((x, y) => x.key.localeCompare(y.key))
  }
  const out = []
  let round = 0
  let progress = true
  while (progress) {
    progress = false
    for (const p of packs) {
      const arr = byPack.get(p)
      if (round < arr.length) {
        out.push(arr[round])
        progress = true
      }
    }
    round++
  }
  return out
}

function filterReviewAssets() {
  const pack = document.getElementById('packFilter').value
  const q = document.getElementById('assetFilter').value.trim().toLowerCase()
  let list = reviewAssets
  if (pack !== 'all') list = list.filter((a) => a.pack === pack)
  if (q)
    list = list.filter((a) => {
      const ash = (a.artifactSearch || '').toLowerCase()
      return (
        a.key.toLowerCase().includes(q) ||
        (a.label && a.label.toLowerCase().includes(q)) ||
        (a.stem && a.stem.toLowerCase().includes(q)) ||
        ash.includes(q)
      )
    })
  return list
}

function renderReviewList() {
  const ul = document.getElementById('assetList')
  ul.innerHTML = ''
  const filtered = filterReviewAssets()
  const packSel = document.getElementById('packFilter').value
  const hasFilter = document.getElementById('assetFilter').value.trim().length > 0
  const display = packSel === 'all' && !hasFilter ? interleaveByPack(filtered) : filtered

  display.forEach((a) => {
    const li = document.createElement('li')
    if (a.manifest) {
      li.classList.add('manifest-asset')
    }
    const nSide = a.sidecars ? Object.values(a.sidecars).filter(Boolean).length : 0
    const nTex = Array.isArray(a.textureFiles) ? a.textureFiles.length : 0
    let suffix = ''
    if (a.manifest) suffix += ' [submeshes]'
    if (nSide || nTex) suffix += ` · ${nSide} json · ${nTex} tex`
    li.textContent = `${a.label || a.key}${suffix}`
    li.title = a.key
    li.addEventListener('click', () => {
      document.querySelectorAll('#assetList li').forEach((x) => x.classList.remove('active'))
      li.classList.add('active')
      void applyReviewAsset(a)
    })
    ul.appendChild(li)
  })

  let extra = ''
  if (packSel === 'all' && !hasFilter && filtered.length > 0) {
    extra =
      'Round-robin across packs so smaller packs stay reachable — pick one pack above for alphabetical order within that pack.'
  }
  const meta = document.getElementById('assetListMeta')
  if (meta) meta.textContent = extra.trim()
}

function reviewStemBaseDirFromAsset(a) {
  const u = (a.gltf || a.meshSceneGltf || a.obj || '').split('?')[0]
  if (!u) return ''
  const last = u.lastIndexOf('/')
  return last > 0 ? u.slice(0, last + 1) : ''
}

function renderReviewArtifactsPanel(a) {
  const panel = document.getElementById('reviewArtifactsPanel')
  if (!panel) return
  panel.replaceChildren()
  if (!a) return
  const det = document.createElement('details')
  det.open = false
  const sum = document.createElement('summary')
  sum.style.cssText = 'cursor:pointer;font-size:11px;font-weight:600;user-select:none'
  sum.textContent = 'Sidecars & data (JSON / textures — open in new tab)'
  const box = document.createElement('div')
  box.style.cssText = 'margin-top:6px;font-size:10px;line-height:1.55;max-height:220px;overflow:auto'

  const addLink = (label, url) => {
    if (!url) return
    const row = document.createElement('div')
    const la = document.createElement('a')
    la.href = url
    la.target = '_blank'
    la.rel = 'noopener noreferrer'
    la.textContent = label
    la.style.color = '#9ec8ff'
    row.appendChild(la)
    box.appendChild(row)
  }

  if (a.obj) addLink('mesh.obj', a.obj)
  if (a.gltf) addLink('mesh.gltf', a.gltf)
  if (a.meshSceneGltf) addLink('mesh_scene.gltf (+ .bin via loader)', a.meshSceneGltf)
  if (a.manifest) addLink('submeshes/index.json (LOD parts manifest)', a.manifest)

  if (a.sidecars && typeof a.sidecars === 'object') {
    for (const [k, url] of Object.entries(a.sidecars)) {
      if (!url) continue
      addLink(REVIEW_SIDECAR_LABELS[k] || k, url)
    }
  }
  if (Array.isArray(a.textureFiles) && a.textureFiles.length > 0) {
    const hd = document.createElement('div')
    hd.textContent = `textures/ (${a.textureFiles.length} files)`
    hd.style.marginTop = '8px'
    hd.style.opacity = '0.78'
    hd.style.fontWeight = '600'
    box.appendChild(hd)
    for (const tf of a.textureFiles) {
      addLink(`textures/${tf.name}`, tf.url)
    }
  }

  det.appendChild(sum)
  det.appendChild(box)
  panel.appendChild(det)
}

async function applyReviewAsset(a) {
  renderReviewArtifactsPanel(a)
  document.getElementById('objUrl').value = a.obj || ''
  document.getElementById('gltfUrl').value = a.gltf || a.meshSceneGltf || ''
  document.getElementById('ddsUrl').value = a.dds || ''
  if (a.manifest) {
    void loadManifest(a.manifest)
    return
  }
  await loadFromInputs()
  const stemBase = reviewStemBaseDirFromAsset(a)
  if (stemBase && root) {
    try {
      await loadTextureManifestForRoot(stemBase, inspectUiAbort?.signal)
    } catch {
      /* optional */
    }
  }
}

function populatePackFilter() {
  const sel = document.getElementById('packFilter')
  const cur = sel.value
  const packs = [...new Set(reviewAssets.map((a) => a.pack))].sort()
  sel.innerHTML = '<option value="all">All packs</option>'
  packs.forEach((p) => {
    const o = document.createElement('option')
    o.value = p
    o.textContent = p
    sel.appendChild(o)
  })
  if ([...sel.options].some((o) => o.value === cur)) sel.value = cur
}

let filterDebounce
document.getElementById('assetFilter').addEventListener('input', () => {
  clearTimeout(filterDebounce)
  filterDebounce = setTimeout(renderReviewList, 100)
})
document.getElementById('packFilter').addEventListener('change', renderReviewList)

async function loadReviewIndex() {
  try {
    const res = await fetch('/api/review-assets.json')
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const data = await res.json()
    reviewAssets = data.assets || []
    packCountsFromApi = data.packCounts || {}
    populatePackFilter()
    renderReviewList()
    const roots = (data.roots || []).join(', ')
    const pcStr = Object.entries(packCountsFromApi)
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([p, n]) => `${p}: ${n}`)
      .join(' · ')
    const hints = data.pipelineHints || []
    const hintsHtml = hints
      .map(
        (h) =>
          `<br/><span style="opacity:0.95;font-size:11px;color:#e8c547;">${h.message || ''}</span>`
      )
      .join('')
    statusEl.innerHTML = `Loaded <strong>${reviewAssets.length}</strong> extracted mesh(es). Click one to view.${
      pcStr ? `<br/><span style="opacity:0.9;font-size:10px;">${pcStr}</span>` : ''
    }${hintsHtml}${roots ? `<br/><span style="opacity:0.75;font-size:10px;">Roots: ${roots}</span>` : ''}`
  } catch (e) {
    console.warn('Review index unavailable (run Vite dev server from viewer/):', e)
    statusEl.textContent =
      'Pipeline index unavailable — start with npm run dev in viewer/, or use Manual URLs / Public picks.'
    reviewAssets = []
    packCountsFromApi = {}
    renderReviewList()
  }
}

/** Fall back: sample files under public/ */
const manualPresets = [{ label: 'sample.obj (public/models/)', obj: 'models/sample.obj' }]

const manualList = document.getElementById('manualAssetList')
manualPresets.forEach((p) => {
  const li = document.createElement('li')
  li.textContent = p.label
  li.addEventListener('click', () => {
    document.getElementById('objUrl').value = p.obj || ''
    document.getElementById('gltfUrl').value = p.gltf || ''
    document.getElementById('ddsUrl').value = ''
    document.querySelectorAll('#manualAssetList li').forEach((x) => x.classList.remove('active'))
    li.classList.add('active')
    loadFromInputs()
  })
  manualList.appendChild(li)
})

/* ── Boot: deep links ── */
void loadReviewIndex().then(() => {
  const q = new URLSearchParams(window.location.search)
  const manifestPath = q.get('manifest')
  const objPath = q.get('obj')
  const gltfPath = q.get('gltf')
  const texPath = q.get('tex') || q.get('dds')

  if (manifestPath) {
    void loadManifest(manifestPath)
  } else if (objPath || gltfPath || texPath) {
    document.getElementById('objUrl').value = objPath || ''
    document.getElementById('gltfUrl').value = gltfPath || ''
    document.getElementById('ddsUrl').value = texPath || ''
    void loadFromInputs()
  }
})
