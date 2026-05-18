/**
 * Submesh / mesh utility helpers (no class — stateless).
 * Ported from viewer/submesh-inspect.js for rendering parity.
 */
import * as THREE from 'three'
import { OBJLoader } from 'three/examples/jsm/loaders/OBJLoader.js'
import * as BufferGeometryUtils from 'three/examples/jsm/utils/BufferGeometryUtils.js'

export const partColors = [
  0xc8c8d0, 0xe8a060, 0x60c8e8, 0x80e880, 0xe880c0, 0xd0d060, 0x8080e8, 0xe86060, 0x60e8b0, 0xc0a0e0,
]

export const materialColors = {
  0: 0xc8c8d0,
  1: 0xd0a858,
  2: 0x404040,
  3: 0x60c8e8,
  4: 0xe8a060,
  5: 0x80e880,
  8: 0x88bbdd,
  9: 0xe880c0,
  10: 0x88bbdd,
  11: 0xb0b0c0,
  12: 0xe86060,
  13: 0xc0a0e0,
}

export function configureColorTexture(tex) {
  tex.colorSpace = THREE.SRGBColorSpace
  tex.flipY = false
  tex.wrapS = THREE.RepeatWrapping
  tex.wrapT = THREE.RepeatWrapping
  return tex
}

export function ensureNormals(geometry) {
  if (!geometry.getAttribute('normal')) {
    geometry = BufferGeometryUtils.mergeVertices(geometry, 1e-4)
    geometry.computeVertexNormals()
  }
  return geometry
}

export function classifyPart(entry) {
  if (entry.is_vehicle_lod) return 'vehicle_lod'
  if (entry.transparent) return 'glass'
  const bb = entry.decoded_bbox
  if (!bb || bb.length < 6) return 'other'
  const ex = bb[3] - bb[0],
    ey = bb[4] - bb[1],
    ez = bb[5] - bb[2]
  const maxE = Math.max(ex, ey, ez)
  const minE = Math.min(ex, ey, ez)
  const cy = (bb[1] + bb[4]) / 2
  if (maxE < 0.9 && minE > 0.15 && Math.abs(ey - ez) < 0.15 && cy < 0.6) return 'wheel'
  if (maxE > 3.0) return 'body'
  if (maxE > 1.5) return 'panel'
  return 'accessory'
}

export function getDamageState(entry) {
  return entry.damage_state || 'shared'
}

export function passesDamageVariantFilter(entry, preferDamaged, showBoth) {
  const ds = getDamageState(entry)
  if (showBoth) return true
  if (ds.startsWith('switch_')) {
    const side = ds.split('_').pop()
    return preferDamaged ? side === '1' : side === '0'
  }
  if (ds === 'intact') return !preferDamaged
  if (ds === 'damaged') return preferDamaged
  return true
}

export function lodGroupMaxRank(partMeta) {
  const maxRank = {}
  for (const e of partMeta) {
    const g = e.lod_group
    if (g == null) continue
    maxRank[g] = Math.max(maxRank[g] || 0, e.lod_rank || 0)
  }
  return maxRank
}

export function makeMaterial(colorIdx, entry = null, texture = null) {
  if (entry && entry.transparent) {
    const opts = {
      color: texture ? 0xffffff : materialColors[entry.material_index] || 0x88bbdd,
      metalness: 0.0,
      roughness: 0.1,
      envMapIntensity: 1.35,
      transparent: true,
      opacity: texture ? 0.5 : 0.25,
      side: THREE.DoubleSide,
      depthWrite: false,
    }
    if (texture) opts.map = texture
    return new THREE.MeshPhysicalMaterial(opts)
  }
  const matIdx = entry ? entry.material_index : null
  const color = texture
    ? 0xffffff
    : matIdx != null && materialColors[matIdx] != null
      ? materialColors[matIdx]
      : partColors[colorIdx % partColors.length]
  const cat = entry ? classifyPart(entry) : null
  const needsOffset = cat === 'accessory' || cat === 'wheel'
  const opts = {
    color,
    metalness: texture ? 0.05 : 0.15,
    roughness: texture ? 0.8 : 0.65,
    envMapIntensity: 1.35,
    side: THREE.DoubleSide,
    polygonOffset: needsOffset,
    polygonOffsetFactor: needsOffset ? -1 : 0,
    polygonOffsetUnits: needsOffset ? -1 : 0,
  }
  if (texture) opts.map = texture
  return new THREE.MeshStandardMaterial(opts)
}

export async function loadObjText(text, colorIdx = 0, entry = null, texture = null) {
  const loader = new OBJLoader()
  const obj = loader.parse(text)
  obj.traverse((child) => {
    if (child.isMesh) {
      child.geometry = ensureNormals(child.geometry)
      child.material = makeMaterial(colorIdx, entry, texture)
    }
  })
  return obj
}

const _texCache = {}

export function clearTextureCache() {
  for (const k of Object.keys(_texCache)) delete _texCache[k]
}

export async function loadTexture(url, flipV = false) {
  const cacheKey = url + (flipV ? '_fv' : '')
  if (_texCache[cacheKey]) return _texCache[cacheKey]
  const tex = await new THREE.TextureLoader().loadAsync(url)
  configureColorTexture(tex)
  tex.flipY = flipV
  _texCache[cacheKey] = tex
  return tex
}
