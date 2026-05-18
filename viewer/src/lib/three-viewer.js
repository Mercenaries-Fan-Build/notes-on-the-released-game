/**
 * Encapsulated Three.js viewer — manages scene, renderer, camera, orbit controls,
 * and asset loading. Returns an API object; lifecycle-safe for Vue mount/unmount.
 *
 * Ported from the original viewer/main.js.
 */
import * as THREE from 'three'
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

function parseManifestJsonArray(rawText) {
  return JSON.parse(
    rawText
      .replace(/\bNaN\b/g, 'null')
      .replace(/\b-Infinity\b/g, 'null')
      .replace(/\bInfinity\b/g, 'null')
  )
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
  }
  animate()

  function disposeRoot() {
    if (root) {
      root.traverse((o) => {
        if (o.geometry) o.geometry.dispose()
        if (o.material) {
          const m = o.material
          if (Array.isArray(m)) m.forEach(x => x.dispose?.())
          else m.dispose?.()
        }
      })
      scene.remove(root)
    }
    root = null
    partGroups = []
    partMeta = []
    lodRefMaxDim = 1
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

  const ro = new ResizeObserver(() => syncSize())
  ro.observe(container)

  async function loadManifest(manifestUrl) {
    disposeRoot()
    setStatus('Loading manifest…')
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
      fitCameraToObject(root)
      const box = new THREE.Box3().setFromObject(root)
      const sz = box.getSize(new THREE.Vector3())
      setStatus(`Loaded ${loaded}/${entries.length} submeshes. Size: ${sz.x.toFixed(2)} × ${sz.y.toFixed(2)} × ${sz.z.toFixed(2)}`)
    } catch (e) {
      setStatus(`Manifest error: ${e.message || e}`)
    }
  }

  async function loadUrls(objUrl, gltfUrl, ddsUrl) {
    disposeRoot()
    setStatus('Loading…')

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
        fitCameraToObject(root)
        const box = new THREE.Box3().setFromObject(root)
        const sz = box.getSize(new THREE.Vector3())
        setStatus(`Loaded glTF. Size: ${sz.x.toFixed(2)} × ${sz.y.toFixed(2)} × ${sz.z.toFixed(2)}`)
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
        fitCameraToObject(root)
        const box = new THREE.Box3().setFromObject(root)
        const sz = box.getSize(new THREE.Vector3())
        setStatus(`Loaded OBJ. Size: ${sz.x.toFixed(2)} × ${sz.y.toFixed(2)} × ${sz.z.toFixed(2)}`)
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

  return {
    loadManifest,
    loadUrls,
    loadAsset,
    dispose() {
      disposed = true
      if (animId != null) cancelAnimationFrame(animId)
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
