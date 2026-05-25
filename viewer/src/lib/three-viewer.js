/**
 * Encapsulated Three.js viewer — manages scene, renderer, camera, orbit controls,
 * and asset loading. Returns an API object; lifecycle-safe for Vue mount/unmount.
 *
 * Ported from the original viewer/main.js.
 */
import * as THREE from 'three'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'
import { TransformControls } from 'three/examples/jsm/controls/TransformControls.js'
import { OBJLoader } from 'three/examples/jsm/loaders/OBJLoader.js'
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js'
import { DDSLoader } from 'three/examples/jsm/loaders/DDSLoader.js'
import { RoomEnvironment } from 'three/examples/jsm/environments/RoomEnvironment.js'
import { VertexNormalsHelper } from 'three/examples/jsm/helpers/VertexNormalsHelper.js'
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

function parseManifestJsonArray(rawText) {
  return JSON.parse(
    rawText
      .replace(/\bNaN\b/g, 'null')
      .replace(/\b-Infinity\b/g, 'null')
      .replace(/\bInfinity\b/g, 'null')
  )
}

function makeCheckerTexture() {
  const size = 16
  const data = new Uint8Array(size * size * 4)
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const i = (y * size + x) * 4
      const isWhite = (x + y) % 2 === 0
      const v = isWhite ? 255 : 0
      data[i] = v
      data[i + 1] = v
      data[i + 2] = v
      data[i + 3] = 255
    }
  }
  const tex = new THREE.DataTexture(data, size, size, THREE.RGBAFormat)
  tex.magFilter = THREE.NearestFilter
  tex.minFilter = THREE.NearestFilter
  tex.wrapS = THREE.RepeatWrapping
  tex.wrapT = THREE.RepeatWrapping
  tex.needsUpdate = true
  return tex
}

export function initThreeViewer(container, setStatus) {
  const scene = new THREE.Scene()
  scene.background = new THREE.Color(0x1a1a1e)

  const camera = new THREE.PerspectiveCamera(50, 1, 0.01, 5000)
  camera.position.set(2.5, 1.8, 2.5)

  const renderer = new THREE.WebGLRenderer({ antialias: true })
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))
  renderer.outputColorSpace = THREE.SRGBColorSpace
  renderer.toneMapping = THREE.ACESFilmicToneMapping
  renderer.toneMappingExposure = 1.02
  renderer.shadowMap.enabled = false
  container.appendChild(renderer.domElement)

  const pmremGenerator = new THREE.PMREMGenerator(renderer)
  pmremGenerator.compileEquirectangularShader()
  const envRt = pmremGenerator.fromScene(new RoomEnvironment(renderer), 0.04)
  scene.environment = envRt.texture

  const controls = new OrbitControls(camera, renderer.domElement)
  controls.enableDamping = true

  const transformControls = new TransformControls(camera, renderer.domElement)
  scene.add(transformControls)
  transformControls.addEventListener('dragging-changed', (event) => {
    controls.enabled = !event.value
  })
  transformControls.addEventListener('objectChange', () => {
    if (_selectedIndex < 0 || _selectedIndex >= partGroups.length) return
    const obj = partGroups[_selectedIndex]
    for (const cb of _transformChangeCallbacks) {
      cb({
        index: _selectedIndex,
        position: { x: obj.position.x, y: obj.position.y, z: obj.position.z },
        rotation: { x: obj.rotation.x, y: obj.rotation.y, z: obj.rotation.z },
        scale: { x: obj.scale.x, y: obj.scale.y, z: obj.scale.z },
      })
    }
  })

  scene.add(new THREE.HemisphereLight(0xcde0ff, 0x4a4632, 2.35))
  const keyLight = new THREE.DirectionalLight(0xffffff, 2.2)
  keyLight.position.set(4, 10, 6)
  scene.add(keyLight)
  scene.add(keyLight.target)
  const rimLight = new THREE.DirectionalLight(0xa8c8ff, 1.35)
  rimLight.position.set(-6, 4, -5)
  scene.add(rimLight)
  scene.add(rimLight.target)
  const cameraFill = new THREE.DirectionalLight(0xffffff, 1.45)
  scene.add(cameraFill)
  scene.add(cameraFill.target)
  scene.add(new THREE.AmbientLight(0xffffff, 0.42))

  let grid = new THREE.GridHelper(20, 40, 0x444444, 0x333333)
  scene.add(grid)

  let root = null
  let partGroups = []
  let partMeta = []
  let lodRefMaxDim = 1
  let disposed = false
  let animId = null

  let models = []

  let animRoot = null
  let animMixer = null
  let animActions = []
  let animSkeletonHelper = null
  let animClock = new THREE.Clock()
  let animFrameCallbacks = []

  // Selection state
  let _selectedIndex = -1
  const _selectionCallbacks = []
  const _edgeCache = new WeakMap()

  // Transform callbacks
  const _transformChangeCallbacks = []

  // Parts-loaded callbacks
  const _partsLoadedCallbacks = []

  // Pointer world position callbacks
  const _pointerWorldCallbacks = []

  // Display mode state
  let _displayMode = 'shaded'
  const _originalMaterials = new WeakMap()
  const _normalHelpers = []
  let _checkerTex = null

  // Filter state
  let _filterState = { lodRank: null, preferDamaged: false, showBoth: true }

  // Channel isolation state
  let _channelIsolation = null
  const _channelMaterialCache = new WeakMap()

  // Pointer tracking for click detection
  let _pointerDownPos = null
  const _raycaster = new THREE.Raycaster()
  const _pointer = new THREE.Vector2()

  function syncSize() {
    const w = Math.max(2, container.clientWidth || 0)
    const h = Math.max(2, container.clientHeight || 0)
    camera.aspect = w / h
    camera.updateProjectionMatrix()
    renderer.setSize(w, h)
  }
  syncSize()

  const _keyRimDir = new THREE.Vector3()
  const _keyRimSide = new THREE.Vector3()
  const _keyRimUp = new THREE.Vector3(0, 1, 0)
  const _keyFromTarget = new THREE.Vector3()

  function animate() {
    if (disposed) return
    animId = requestAnimationFrame(animate)
    controls.update()
    cameraFill.position.copy(camera.position)
    cameraFill.target.position.copy(controls.target)

    _keyRimDir.subVectors(controls.target, camera.position)
    const dist = _keyRimDir.length()
    if (_keyRimDir.lengthSq() < 1e-12) _keyRimDir.set(0, 0, 1)
    else _keyRimDir.multiplyScalar(1 / dist)

    const ref = Math.max(lodRefMaxDim, 0.01)
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

    renderer.render(scene, camera)

    if (animMixer) {
      animMixer.update(animClock.getDelta())
      for (const cb of animFrameCallbacks) {
        const action = animActions.find(a => a.isRunning())
        if (action) {
          cb({ time: animMixer.time, duration: action.getClip().duration })
        }
      }
    }
  }
  animate()

  // --- Pointer events for selection and world position readout ---

  function onPointerDown(event) {
    const rect = renderer.domElement.getBoundingClientRect()
    _pointerDownPos = { x: event.clientX - rect.left, y: event.clientY - rect.top }
  }

  function onPointerUp(event) {
    if (!_pointerDownPos) return
    const rect = renderer.domElement.getBoundingClientRect()
    const upX = event.clientX - rect.left
    const upY = event.clientY - rect.top
    const dx = upX - _pointerDownPos.x
    const dy = upY - _pointerDownPos.y
    _pointerDownPos = null

    if (Math.sqrt(dx * dx + dy * dy) >= 3) return

    _pointer.x = (upX / rect.width) * 2 - 1
    _pointer.y = -(upY / rect.height) * 2 + 1
    _raycaster.setFromCamera(_pointer, camera)

    const meshes = []
    const meshToPartIndex = new Map()
    for (let i = 0; i < partGroups.length; i++) {
      partGroups[i].traverse((child) => {
        if (child.isMesh) {
          meshes.push(child)
          meshToPartIndex.set(child, i)
        }
      })
    }

    const intersects = _raycaster.intersectObjects(meshes, false)
    if (intersects.length > 0) {
      const hitMesh = intersects[0].object
      const idx = meshToPartIndex.get(hitMesh)
      if (idx !== undefined) {
        selectPart(idx)
      }
    } else {
      deselectAll()
    }
  }

  function onPointerMove(event) {
    if (_pointerWorldCallbacks.length === 0) return
    const rect = renderer.domElement.getBoundingClientRect()
    const px = ((event.clientX - rect.left) / rect.width) * 2 - 1
    const py = -((event.clientY - rect.top) / rect.height) * 2 + 1
    _pointer.x = px
    _pointer.y = py
    _raycaster.setFromCamera(_pointer, camera)

    const meshes = []
    for (const pg of partGroups) {
      pg.traverse((child) => {
        if (child.isMesh) meshes.push(child)
      })
    }

    const intersects = _raycaster.intersectObjects(meshes, false)
    if (intersects.length > 0) {
      const pt = intersects[0].point
      for (const cb of _pointerWorldCallbacks) {
        cb({ x: pt.x, y: pt.y, z: pt.z })
      }
    }
  }

  renderer.domElement.addEventListener('pointerdown', onPointerDown)
  renderer.domElement.addEventListener('pointerup', onPointerUp)
  renderer.domElement.addEventListener('pointermove', onPointerMove)

  // --- Selection helpers ---

  function getOrCreateEdgeHighlight(mesh) {
    if (_edgeCache.has(mesh)) return _edgeCache.get(mesh)
    const edges = new THREE.EdgesGeometry(mesh.geometry)
    const line = new THREE.LineSegments(
      edges,
      new THREE.LineBasicMaterial({ color: 0x00ffff, depthTest: true })
    )
    line.visible = false
    line.raycast = () => {} // exclude from raycasting
    mesh.add(line)
    _edgeCache.set(mesh, line)
    return line
  }

  function selectPart(index) {
    if (index < 0 || index >= partGroups.length) return
    deselectAll()
    _selectedIndex = index
    const group = partGroups[index]
    group.traverse((child) => {
      if (child.isMesh) {
        const line = getOrCreateEdgeHighlight(child)
        line.visible = true
      }
    })
    transformControls.attach(group)
    for (const cb of _selectionCallbacks) cb(index)
  }

  function deselectAll() {
    if (_selectedIndex >= 0 && _selectedIndex < partGroups.length) {
      partGroups[_selectedIndex].traverse((child) => {
        if (child.isMesh) {
          const cached = _edgeCache.get(child)
          if (cached) cached.visible = false
        }
      })
    }
    _selectedIndex = -1
    transformControls.detach()
    for (const cb of _selectionCallbacks) cb(-1)
  }

  // --- Display mode helpers ---

  function storeOriginalMaterials() {
    for (const pg of partGroups) {
      pg.traverse((child) => {
        if (child.isMesh && !_originalMaterials.has(child)) {
          _originalMaterials.set(child, child.material)
        }
      })
    }
  }

  function clearNormalHelpers() {
    for (const h of _normalHelpers) {
      h.parent?.remove(h)
      h.dispose?.()
    }
    _normalHelpers.length = 0
  }

  function applyDisplayMode(mode) {
    storeOriginalMaterials()
    clearNormalHelpers()
    _displayMode = mode

    for (const pg of partGroups) {
      pg.traverse((child) => {
        if (!child.isMesh) return
        const origMat = _originalMaterials.get(child) || child.material

        switch (mode) {
          case 'shaded':
            child.material = origMat
            child.material.wireframe = false
            child.material.needsUpdate = true
            break
          case 'wireframe':
            child.material = origMat
            child.material.wireframe = true
            child.material.needsUpdate = true
            break
          case 'normals': {
            child.material = origMat
            child.material.wireframe = false
            child.material.needsUpdate = true
            const helper = new VertexNormalsHelper(child, 0.05, 0x00ff00)
            scene.add(helper)
            _normalHelpers.push(helper)
            break
          }
          case 'uv-checker': {
            if (!_checkerTex) _checkerTex = makeCheckerTexture()
            const checkerMat = new THREE.MeshBasicMaterial({
              map: _checkerTex,
              side: THREE.DoubleSide,
            })
            child.material = checkerMat
            break
          }
        }
      })
    }
  }

  // --- Filter helpers ---

  function applyLodFilter(rank) {
    _filterState.lodRank = rank
    if (rank == null) {
      for (const pg of partGroups) pg.visible = true
      return
    }
    const maxRanks = lodGroupMaxRank(partMeta)
    for (let i = 0; i < partGroups.length; i++) {
      const entry = partMeta[i]
      if (!entry) { partGroups[i].visible = false; continue }
      const g = entry.lod_group
      if (g == null) { partGroups[i].visible = true; continue }
      const entryRank = entry.lod_rank || 0
      const maxR = maxRanks[g] || 0
      partGroups[i].visible = (rank === 'best')
        ? entryRank === maxR
        : entryRank <= rank
    }
  }

  function applyDamageFilter(preferDamaged, showBoth) {
    _filterState.preferDamaged = preferDamaged
    _filterState.showBoth = showBoth
    for (let i = 0; i < partGroups.length; i++) {
      const entry = partMeta[i]
      if (!entry) continue
      partGroups[i].visible = passesDamageVariantFilter(entry, preferDamaged, showBoth)
    }
  }

  // --- Core loading ---

  function disposeRoot() {
    deselectAll()
    clearNormalHelpers()
    for (const m of models) {
      if (m.root) {
        m.root.traverse((o) => {
          if (o.geometry) o.geometry.dispose()
          if (o.material) {
            const mat = o.material
            if (Array.isArray(mat)) mat.forEach(x => x.dispose?.())
            else mat.dispose?.()
          }
        })
        scene.remove(m.root)
      }
    }
    if (root && !models.find(m => m.root === root)) {
      root.traverse((o) => {
        if (o.geometry) o.geometry.dispose()
        if (o.material) {
          const mat = o.material
          if (Array.isArray(mat)) mat.forEach(x => x.dispose?.())
          else mat.dispose?.()
        }
      })
      scene.remove(root)
    }
    models = []
    root = null
    partGroups = []
    partMeta = []
    lodRefMaxDim = 1
    _filterState = { lodRank: null, preferDamaged: false, showBoth: true }
    _channelIsolation = null
  }

  function fitCameraToObject(object) {
    const box = new THREE.Box3().setFromObject(object)
    if (box.isEmpty()) return
    const size = box.getSize(new THREE.Vector3())
    const center = box.getCenter(new THREE.Vector3())
    const maxDim = Math.max(size.x, size.y, size.z, 0.5)
    const d = (maxDim * 1.8) / Math.tan((camera.fov * Math.PI) / 360)
    controls.target.copy(center)
    camera.position.copy(center.clone().add(new THREE.Vector3(d * 0.55, d * 0.35, d * 0.55)))
    camera.near = Math.max(0.001, maxDim / 2000)
    camera.far = Math.max(5000, maxDim * 50)
    camera.updateProjectionMatrix()
    controls.update()

    const gridSpan = Math.min(Math.max(maxDim * 6, 12), 500000)
    const divisions = Math.min(80, Math.max(12, Math.round(gridSpan / Math.max(maxDim, 0.01))))
    scene.remove(grid)
    grid.geometry?.dispose?.()
    if (grid.material) {
      if (Array.isArray(grid.material)) grid.material.forEach(m => m.dispose?.())
      else grid.material.dispose?.()
    }
    grid = new THREE.GridHelper(gridSpan, divisions, 0x444444, 0x333333)
    grid.position.y = box.min.y
    scene.add(grid)
    lodRefMaxDim = maxDim
  }

  function recenterLoadedGroup(obj) {
    obj.updateMatrixWorld(true)
    const box = new THREE.Box3().setFromObject(obj)
    if (box.isEmpty()) return
    const center = box.getCenter(new THREE.Vector3())
    obj.position.sub(center)
    obj.updateMatrixWorld(true)
  }

  function applyPbrEnvHints(obj) {
    if (!obj) return
    obj.traverse((o) => {
      if (!o.isMesh || !o.material) return
      const list = Array.isArray(o.material) ? o.material : [o.material]
      for (const m of list) {
        if (m && 'envMapIntensity' in m) {
          m.envMapIntensity = 1.35
          m.needsUpdate = true
        }
      }
    })
  }

  function firePartsLoaded() {
    for (const cb of _partsLoadedCallbacks) {
      cb(partGroups, partMeta)
    }
  }

  function makeChannelShader(texture, channelIndex) {
    return new THREE.ShaderMaterial({
      uniforms: {
        tDiffuse: { value: texture },
        channel: { value: channelIndex },
      },
      vertexShader: `
        varying vec2 vUv;
        void main() {
          vUv = uv;
          gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
      `,
      fragmentShader: `
        uniform sampler2D tDiffuse;
        uniform int channel;
        varying vec2 vUv;
        void main() {
          vec4 tex = texture2D(tDiffuse, vUv);
          float v = channel == 0 ? tex.r : channel == 1 ? tex.g : channel == 2 ? tex.b : tex.a;
          gl_FragColor = vec4(v, v, v, 1.0);
        }
      `,
    })
  }

  function applyChannelIsolation(channel) {
    storeOriginalMaterials()
    _channelIsolation = channel
    const channelMap = { r: 0, g: 1, b: 2, a: 3 }

    for (const pg of partGroups) {
      pg.traverse((child) => {
        if (!child.isMesh) return
        if (channel === null) {
          const orig = _originalMaterials.get(child)
          if (orig) child.material = orig
          return
        }
        const orig = _originalMaterials.get(child) || child.material
        const tex = orig.map || null
        if (tex) {
          child.material = makeChannelShader(tex, channelMap[channel])
        }
      })
    }
  }

  function syncModelsToFlat() {
    partGroups = []
    partMeta = []
    for (const m of models) {
      partGroups.push(...m.partGroups)
      partMeta.push(...m.partMeta)
    }
  }

  async function loadAssetAdditive(asset) {
    const modelRoot = new THREE.Group()
    const modelPartGroups = []
    const modelPartMeta = []

    if (asset.manifest) {
      const manifestUrl = asset.manifest
      const baseUrl = manifestUrl.substring(0, manifestUrl.lastIndexOf('/') + 1)
      const res = await fetch(manifestUrl)
      if (!res.ok) throw new Error(`${res.status} ${res.statusText}`)
      const entries = parseManifestJsonArray(await res.text())

      for (let i = 0; i < entries.length; i++) {
        const entry = entries[i]
        try {
          const objRes = await fetch(baseUrl + entry.file)
          if (!objRes.ok) continue
          const obj = await loadObjText(await objRes.text(), entry.lod_group ?? i, entry)
          modelRoot.add(obj)
          modelPartGroups.push(obj)
          modelPartMeta.push(entry)
        } catch { /* skip */ }
      }
    } else {
      const gltfUrl = asset.gltf || asset.meshSceneGltf || ''
      if (gltfUrl) {
        const gltf = await new Promise((resolve, reject) => {
          new GLTFLoader().load(gltfUrl, resolve, undefined, reject)
        })
        modelRoot.add(gltf.scene)
        gltf.scene.traverse((c) => {
          if (c.isMesh) {
            const wrapper = new THREE.Group()
            wrapper.add(c.clone())
            modelPartGroups.push(wrapper)
            modelPartMeta.push({ name: c.name || 'mesh' })
          }
        })
      }
    }

    scene.add(modelRoot)
    const modelIndex = models.length
    models.push({ root: modelRoot, partGroups: modelPartGroups, partMeta: modelPartMeta, asset })
    syncModelsToFlat()

    if (modelIndex === 0) {
      root = modelRoot
      fitCameraToObject(modelRoot)
    }

    firePartsLoaded()
    return modelIndex
  }

  function removeModel(modelIndex) {
    if (modelIndex < 0 || modelIndex >= models.length) return
    const m = models[modelIndex]
    deselectAll()
    if (m.root) {
      m.root.traverse((o) => {
        if (o.geometry) o.geometry.dispose()
        if (o.material) {
          const mat = o.material
          if (Array.isArray(mat)) mat.forEach(x => x.dispose?.())
          else mat.dispose?.()
        }
      })
      scene.remove(m.root)
    }
    models.splice(modelIndex, 1)
    syncModelsToFlat()
    if (models.length > 0) root = models[0].root
    else root = null
    firePartsLoaded()
  }

  function getModelCount() {
    return models.length
  }

  function getModelPartGroups(modelIndex) {
    if (modelIndex < 0 || modelIndex >= models.length) return []
    return models[modelIndex].partGroups
  }

  function getModelPartMeta(modelIndex) {
    if (modelIndex < 0 || modelIndex >= models.length) return []
    return models[modelIndex].partMeta
  }

  function transferSubmesh(partIndex, sourceModelIndex, targetModelIndex) {
    if (sourceModelIndex < 0 || sourceModelIndex >= models.length) return -1
    if (targetModelIndex < 0 || targetModelIndex >= models.length) return -1
    const src = models[sourceModelIndex]
    if (partIndex < 0 || partIndex >= src.partGroups.length) return -1

    const partGroup = src.partGroups[partIndex]
    const partMetaEntry = src.partMeta[partIndex]
    const target = models[targetModelIndex]

    target.root.attach(partGroup)

    src.partGroups.splice(partIndex, 1)
    src.partMeta.splice(partIndex, 1)

    const newIndex = target.partGroups.length
    target.partGroups.push(partGroup)
    target.partMeta.push(partMetaEntry)

    syncModelsToFlat()
    firePartsLoaded()
    return newIndex
  }

  const ro = new ResizeObserver(() => syncSize())
  ro.observe(container)

  async function loadManifest(manifestUrl) {
    disposeRoot()
    setStatus('Loading manifest\u2026')
    const baseUrl = manifestUrl.substring(0, manifestUrl.lastIndexOf('/') + 1)

    try {
      const res = await fetch(manifestUrl)
      if (!res.ok) throw new Error(`${res.status} ${res.statusText}`)
      const entries = parseManifestJsonArray(await res.text())

      root = new THREE.Group()
      let loaded = 0
      for (let i = 0; i < entries.length; i++) {
        const entry = entries[i]
        try {
          const objRes = await fetch(baseUrl + entry.file)
          if (!objRes.ok) continue
          const obj = await loadObjText(await objRes.text(), entry.lod_group ?? i, entry)
          root.add(obj)
          partGroups.push(obj)
          partMeta.push(entry)
          loaded++
        } catch { /* skip */ }
      }
      scene.add(root)
      models = [{ root, partGroups, partMeta, asset: null }]
      fitCameraToObject(root)
      const box = new THREE.Box3().setFromObject(root)
      const sz = box.getSize(new THREE.Vector3())
      setStatus(`Loaded ${loaded}/${entries.length} submeshes. Size: ${sz.x.toFixed(2)} \u00d7 ${sz.y.toFixed(2)} \u00d7 ${sz.z.toFixed(2)}`)
      firePartsLoaded()
    } catch (e) {
      setStatus(`Manifest error: ${e.message || e}`)
    }
  }

  async function loadUrls(objUrl, gltfUrl, ddsUrl) {
    disposeRoot()
    setStatus('Loading\u2026')

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
          root.traverse(c => {
            if (c.isMesh && c.material && !c.material.map) {
              c.material.map = texture
              c.material.needsUpdate = true
            }
          })
        }
        applyPbrEnvHints(root)
        scene.add(root)
        recenterLoadedGroup(root)
        models = [{ root, partGroups, partMeta, asset: null }]
        fitCameraToObject(root)
        const box = new THREE.Box3().setFromObject(root)
        const sz = box.getSize(new THREE.Vector3())
        setStatus(`Loaded glTF. Size: ${sz.x.toFixed(2)} \u00d7 ${sz.y.toFixed(2)} \u00d7 ${sz.z.toFixed(2)}`)
        firePartsLoaded()
        return
      }

      if (objUrl) {
        const obj = await new Promise((resolve, reject) => {
          new OBJLoader().load(objUrl, resolve, undefined, reject)
        })
        obj.traverse(c => {
          if (c.isMesh) {
            c.geometry = ensureNormals(c.geometry)
            c.material = makeMaterial(0, null, texture)
          }
        })
        root = obj
        scene.add(root)
        recenterLoadedGroup(root)
        models = [{ root, partGroups, partMeta, asset: null }]
        fitCameraToObject(root)
        const box = new THREE.Box3().setFromObject(root)
        const sz = box.getSize(new THREE.Vector3())
        setStatus(`Loaded OBJ. Size: ${sz.x.toFixed(2)} \u00d7 ${sz.y.toFixed(2)} \u00d7 ${sz.z.toFixed(2)}`)
        firePartsLoaded()
        return
      }

      setStatus('Enter at least one mesh URL or pick from the list.')
    } catch (e) {
      setStatus(`Error: ${e.message || e}`)
    }
  }

  async function loadAsset(a) {
    if (a.manifest) {
      await loadManifest(a.manifest)
      return
    }
    await loadUrls(a.obj || '', a.gltf || a.meshSceneGltf || '', a.dds || '')
  }

  // --- Bone management ---

  let _skeletonHelper = null
  const _manualBones = []
  const _boneGroup = new THREE.Group()
  _boneGroup.name = '__manualBoneGroup'
  scene.add(_boneGroup)
  const _boneSelectCallbacks = []
  const BONE_COLOR = 0xff4444
  const BONE_HIGHLIGHT_COLOR = 0x00ffff
  const BONE_RADIUS = 0.03

  function getBonesFromScene() {
    const bones = []
    for (const m of models) {
      if (!m.root) continue
      m.root.traverse((child) => {
        if (child.isBone) {
          const wp = new THREE.Vector3()
          child.getWorldPosition(wp)
          bones.push({
            bone: child,
            name: child.name || '(unnamed)',
            parent: child.parent?.isBone ? child.parent : null,
            worldPosition: { x: wp.x, y: wp.y, z: wp.z },
          })
        }
      })
    }
    return bones
  }

  function toggleSkeletonHelper(show) {
    if (_skeletonHelper) {
      scene.remove(_skeletonHelper)
      _skeletonHelper.dispose?.()
      _skeletonHelper = null
    }
    if (!show) return
    for (const m of models) {
      if (!m.root) continue
      let skinnedMesh = null
      m.root.traverse((child) => {
        if (!skinnedMesh && child.isSkinnedMesh) skinnedMesh = child
      })
      if (skinnedMesh) {
        _skeletonHelper = new THREE.SkeletonHelper(skinnedMesh)
        scene.add(_skeletonHelper)
        return
      }
      let rootBone = null
      m.root.traverse((child) => {
        if (!rootBone && child.isBone && (!child.parent || !child.parent.isBone)) {
          rootBone = child
        }
      })
      if (rootBone) {
        _skeletonHelper = new THREE.SkeletonHelper(rootBone)
        scene.add(_skeletonHelper)
        return
      }
    }
  }

  function _scaleBoneRadius() {
    const box = new THREE.Box3()
    for (const m of models) {
      if (m.root) box.expandByObject(m.root)
    }
    if (box.isEmpty()) return BONE_RADIUS
    const size = box.getSize(new THREE.Vector3())
    return Math.max(size.x, size.y, size.z) * 0.012
  }

  function _createBoneMarker(position, color) {
    const r = _scaleBoneRadius()
    const geo = new THREE.SphereGeometry(r, 8, 6)
    const mat = new THREE.MeshBasicMaterial({ color, depthTest: true })
    const mesh = new THREE.Mesh(geo, mat)
    mesh.position.copy(position)
    mesh.raycast = () => {}
    return mesh
  }

  function _createBoneLine(fromPos, toPos) {
    const geo = new THREE.BufferGeometry().setFromPoints([fromPos.clone(), toPos.clone()])
    const mat = new THREE.LineBasicMaterial({ color: 0xffaa44 })
    const line = new THREE.LineSegments(geo, mat)
    line.raycast = () => {}
    return line
  }

  function _updateBoneLine(entry) {
    if (entry.line) {
      _boneGroup.remove(entry.line)
      entry.line.geometry.dispose()
      entry.line.material.dispose()
      entry.line = null
    }
    if (entry.parentBone) {
      const parentEntry = _manualBones.find(b => b.bone === entry.parentBone)
      if (parentEntry) {
        entry.line = _createBoneLine(parentEntry.marker.position, entry.marker.position)
        _boneGroup.add(entry.line)
      }
    }
  }

  function addManualBone(position, parentBone = null, name = null) {
    const bone = new THREE.Bone()
    bone.position.copy(position)
    bone.name = name || `bone_${_manualBones.length}`

    if (parentBone) parentBone.add(bone)
    else _boneGroup.add(bone)

    const marker = _createBoneMarker(position, BONE_COLOR)
    _boneGroup.add(marker)

    let line = null
    if (parentBone) {
      const parentEntry = _manualBones.find(b => b.bone === parentBone)
      if (parentEntry) {
        line = _createBoneLine(parentEntry.marker.position, position)
        _boneGroup.add(line)
      }
    }

    const entry = { bone, marker, line, name: bone.name, parentBone }
    _manualBones.push(entry)
    return bone
  }

  function removeManualBone(bone) {
    const idx = _manualBones.findIndex(b => b.bone === bone)
    if (idx < 0) return

    const children = _manualBones.filter(b => b.parentBone === bone)
    for (const child of children) {
      child.parentBone = null
      if (child.line) {
        _boneGroup.remove(child.line)
        child.line.geometry.dispose()
        child.line.material.dispose()
        child.line = null
      }
    }

    const entry = _manualBones[idx]
    _boneGroup.remove(entry.marker)
    entry.marker.geometry.dispose()
    entry.marker.material.dispose()
    if (entry.line) {
      _boneGroup.remove(entry.line)
      entry.line.geometry.dispose()
      entry.line.material.dispose()
    }
    if (entry.bone.parent) entry.bone.parent.remove(entry.bone)
    _manualBones.splice(idx, 1)
  }

  function clearManualBones() {
    while (_manualBones.length > 0) {
      removeManualBone(_manualBones[_manualBones.length - 1].bone)
    }
  }

  function getManualBones() {
    return _manualBones.map(e => ({
      bone: e.bone,
      name: e.name,
      parentName: e.parentBone ? (_manualBones.find(b => b.bone === e.parentBone)?.name ?? null) : null,
      marker: e.marker,
    }))
  }

  function setManualBonePosition(bone, position) {
    const entry = _manualBones.find(b => b.bone === bone)
    if (!entry) return
    bone.position.copy(position)
    entry.marker.position.copy(position)
    _updateBoneLine(entry)
    const children = _manualBones.filter(b => b.parentBone === bone)
    for (const child of children) _updateBoneLine(child)
  }

  function setManualBoneName(bone, name) {
    const entry = _manualBones.find(b => b.bone === bone)
    if (!entry) return
    entry.name = name
    bone.name = name
  }

  function setManualBoneParent(bone, parentBone) {
    const entry = _manualBones.find(b => b.bone === bone)
    if (!entry) return
    entry.parentBone = parentBone
    _updateBoneLine(entry)
  }

  function highlightBone(bone) {
    const entry = _manualBones.find(b => b.bone === bone)
    if (entry) entry.marker.material.color.setHex(BONE_HIGHLIGHT_COLOR)

    for (const m of models) {
      if (!m.root) continue
      m.root.traverse((child) => {
        if (child.isBone && child === bone && child.children) {
          // no visual markers on scene bones
        }
      })
    }
  }

  function unhighlightAllBones() {
    for (const entry of _manualBones) {
      entry.marker.material.color.setHex(BONE_COLOR)
    }
  }

  function onBoneSelect(callback) { _boneSelectCallbacks.push(callback) }

  function raycastForBonePlace(event) {
    const rect = renderer.domElement.getBoundingClientRect()
    const px = ((event.clientX - rect.left) / rect.width) * 2 - 1
    const py = -((event.clientY - rect.top) / rect.height) * 2 + 1
    _raycaster.setFromCamera(new THREE.Vector2(px, py), camera)

    const meshes = []
    for (const pg of partGroups) {
      pg.traverse((child) => {
        if (child.isMesh) meshes.push(child)
      })
    }
    const hits = _raycaster.intersectObjects(meshes, false)
    if (hits.length > 0) return hits[0].point.clone()
    return null
  }

  // --- Focus camera on a single part ---

  function focusOnPart(index) {
    if (index < 0 || index >= partGroups.length) return
    const group = partGroups[index]
    const box = new THREE.Box3().setFromObject(group)
    if (box.isEmpty()) return
    const size = box.getSize(new THREE.Vector3())
    const center = box.getCenter(new THREE.Vector3())
    const maxDim = Math.max(size.x, size.y, size.z, 0.1)
    const d = (maxDim * 2.5) / Math.tan((camera.fov * Math.PI) / 360)
    controls.target.copy(center)
    camera.position.copy(center.clone().add(new THREE.Vector3(d * 0.55, d * 0.35, d * 0.55)))
    camera.updateProjectionMatrix()
    controls.update()
  }

  return {
    loadManifest,
    loadUrls,
    loadAsset,

    getPartGroups() { return partGroups },
    getPartMeta() { return partMeta },
    onPartsLoaded(callback) { _partsLoadedCallbacks.push(callback) },

    selectPart,
    deselectAll,
    getSelectedIndex() { return _selectedIndex },
    onSelectionChange(callback) { _selectionCallbacks.push(callback) },

    setTransformMode(mode) { transformControls.setMode(mode) },
    onTransformChange(callback) { _transformChangeCallbacks.push(callback) },

    setDisplayMode(mode) { applyDisplayMode(mode) },
    getDisplayMode() { return _displayMode },

    applyLodFilter,
    applyDamageFilter,
    setAllPartsVisible(visible) {
      for (const pg of partGroups) pg.visible = visible
    },
    isolateCategory(category) {
      for (let i = 0; i < partGroups.length; i++) {
        const entry = partMeta[i]
        if (!entry) { partGroups[i].visible = false; continue }
        partGroups[i].visible = classifyPart(entry) === category
      }
    },
    getFilterState() { return { ..._filterState } },

    focusOnPart,

    setPartVisible(index, visible) {
      if (index >= 0 && index < partGroups.length) partGroups[index].visible = visible
    },
    getPartVisible(index) {
      if (index >= 0 && index < partGroups.length) return partGroups[index].visible
      return false
    },

    onPointerWorldPosition(callback) { _pointerWorldCallbacks.push(callback) },

    loadAssetAdditive,
    removeModel,
    getModelCount,
    getModelPartGroups,
    getModelPartMeta,
    transferSubmesh,
    setChannelIsolation(channel) { applyChannelIsolation(channel) },

    getBonesFromScene,
    toggleSkeletonHelper,
    addManualBone,
    removeManualBone,
    clearManualBones,
    getManualBones,
    setManualBonePosition,
    setManualBoneName,
    setManualBoneParent,
    highlightBone,
    unhighlightAllBones,
    onBoneSelect,
    raycastForBonePlace,
    getRenderer() { return renderer },

    async loadAnimGltf(url) {
      this.clearAnimScene()
      const gltf = await new Promise((resolve, reject) => {
        new GLTFLoader().load(url, resolve, undefined, reject)
      })
      animRoot = gltf.scene
      scene.add(animRoot)

      animMixer = new THREE.AnimationMixer(animRoot)
      animClock = new THREE.Clock()
      animActions = gltf.animations.map(clip => animMixer.clipAction(clip))

      let boneCount = 0
      let skinnedVertCount = 0
      let skeletonStatus = 'none'
      animRoot.traverse((o) => {
        if (o.isBone) boneCount++
        if (o.isSkinnedMesh) {
          const pos = o.geometry?.getAttribute('position')
          if (pos) skinnedVertCount += pos.count
          skeletonStatus = 'present'
        }
      })

      fitCameraToObject(animRoot)

      return {
        clips: gltf.animations,
        boneCount,
        skinnedVertCount,
        skeletonStatus,
      }
    },

    clearAnimScene() {
      if (animSkeletonHelper) {
        scene.remove(animSkeletonHelper)
        animSkeletonHelper.dispose?.()
        animSkeletonHelper = null
      }
      if (animMixer) {
        animMixer.stopAllAction()
        animMixer.uncacheRoot(animRoot)
        animMixer = null
      }
      animActions = []
      animFrameCallbacks = []
      if (animRoot) {
        animRoot.traverse((o) => {
          if (o.geometry) o.geometry.dispose()
          if (o.material) {
            const mat = o.material
            if (Array.isArray(mat)) mat.forEach(x => x.dispose?.())
            else mat.dispose?.()
          }
        })
        scene.remove(animRoot)
        animRoot = null
      }
    },

    playClip(index) {
      if (!animMixer || index < 0 || index >= animActions.length) return
      for (const a of animActions) a.stop()
      animClock = new THREE.Clock()
      animActions[index].reset().play()
    },

    pauseAnim() {
      if (!animMixer) return
      for (const a of animActions) {
        if (a.isRunning()) a.paused = true
      }
    },

    stopAnim() {
      if (!animMixer) return
      for (const a of animActions) a.stop()
      animMixer.setTime(0)
    },

    setAnimTime(normalized) {
      if (!animMixer || animActions.length === 0) return
      const running = animActions.find(a => a.isRunning() || a.paused)
      if (!running) return
      const dur = running.getClip().duration
      animMixer.setTime(normalized * dur)
    },

    setAnimSpeed(speed) {
      for (const a of animActions) {
        a.timeScale = speed
      }
    },

    getAnimState() {
      const running = animActions.find(a => a.isRunning())
      const paused = animActions.find(a => a.paused)
      const active = running || paused
      return {
        isPlaying: !!running && !running.paused,
        currentClipIndex: active ? animActions.indexOf(active) : -1,
        time: animMixer ? animMixer.time : 0,
        duration: active ? active.getClip().duration : 0,
        speed: active ? active.timeScale : 1,
      }
    },

    toggleAnimSkeleton(show) {
      if (show && animRoot && !animSkeletonHelper) {
        animSkeletonHelper = new THREE.SkeletonHelper(animRoot)
        scene.add(animSkeletonHelper)
      } else if (!show && animSkeletonHelper) {
        scene.remove(animSkeletonHelper)
        animSkeletonHelper.dispose?.()
        animSkeletonHelper = null
      }
      if (animSkeletonHelper) animSkeletonHelper.visible = show
    },

    onAnimFrame(callback) {
      animFrameCallbacks.push(callback)
    },

    removeAnimFrameCallback(callback) {
      const idx = animFrameCallbacks.indexOf(callback)
      if (idx >= 0) animFrameCallbacks.splice(idx, 1)
    },

    dispose() {
      disposed = true
      if (animId != null) cancelAnimationFrame(animId)
      this.clearAnimScene()
      renderer.domElement.removeEventListener('pointerdown', onPointerDown)
      renderer.domElement.removeEventListener('pointerup', onPointerUp)
      renderer.domElement.removeEventListener('pointermove', onPointerMove)
      transformControls.dispose()
      scene.remove(transformControls)
      clearNormalHelpers()
      clearManualBones()
      toggleSkeletonHelper(false)
      scene.remove(_boneGroup)
      if (_checkerTex) { _checkerTex.dispose(); _checkerTex = null }
      ro.disconnect()
      disposeRoot()
      renderer.dispose()
      pmremGenerator.dispose()
      if (renderer.domElement.parentNode) {
        renderer.domElement.parentNode.removeChild(renderer.domElement)
      }
    },
  }
}

export function disposeThreeViewer(viewer) {
  if (viewer?.dispose) viewer.dispose()
}
