/**
 * Client-side placement index, named bbox regions, and transform overrides.
 * Re-exported from original viewer/placement-bbox-store.js for Vue components.
 */
export {
  createPlacementStore,
  createRegion,
  effectivePlacement,
  gameYawToUeYawDeg,
  mergePlacementForExport,
  placementKey,
  readRotation,
  rotationFromDegrees,
  rotationFromSinCos,
} from '../../placement-bbox-store.js'

export { createMapView } from '../../placement-bbox-map.js'
