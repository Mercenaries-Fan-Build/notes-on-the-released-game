/**
 * Serves stage-2 review outputs (mesh.obj, textures/*.dds) and exposes /api/review-assets.json.
 *
 * Review roots (merged, deduped):
 *   MERCS2_REVIEW_ROOT — comma-separated paths (optional; also loaded from viewer/.env via vite.config)
 *   <repo>/output/review
 *   <repo>/output/extracted/review
 *   <repo>/extracted/review
 *   <repo>/output/(subdir)/extracted/review for each subdir under output (nested pipeline roots)
 */
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

function repoRoot() {
  return path.resolve(__dirname, '..')
}

function discoverReviewRoots() {
  const roots = new Set()
  const add = (p) => {
    try {
      const resolved = path.resolve(p)
      if (fs.existsSync(resolved) && fs.statSync(resolved).isDirectory()) {
        roots.add(resolved)
      }
    } catch {
      /* ignore */
    }
  }

  const env = process.env.MERCS2_REVIEW_ROOT
  if (env && env.trim()) {
    for (const s of env.split(',')) {
      add(s.trim())
    }
  }

  const r = repoRoot()
  add(path.join(r, 'output', 'review'))
  add(path.join(r, 'output', 'extracted', 'review'))
  add(path.join(r, 'extracted', 'review'))

  const outBase = path.join(r, 'output')
  if (fs.existsSync(outBase)) {
    try {
      const subs = fs.readdirSync(outBase, { withFileTypes: true })
      for (const d of subs) {
        if (!d.isDirectory()) continue
        add(path.join(outBase, d.name, 'extracted', 'review'))
      }
    } catch {
      /* ignore */
    }
  }

  return [...roots]
}

function isPathInside(parent, candidate) {
  const p = path.resolve(parent)
  const c = path.resolve(candidate)
  return c === p || c.startsWith(p + path.sep)
}

function encSegs(...parts) {
  return parts.map((s) => encodeURIComponent(s)).join('/')
}

/** Build ``/__review__/pack/stem/rel`` URL (rel may contain slashes). */
function reviewAssetUrl(pack, stem, rel) {
  const segs = [pack, stem, ...rel.split('/').filter(Boolean)]
  return `/__review__/${encSegs(...segs)}`
}

function fileExists(p) {
  try {
    return fs.existsSync(p) && fs.statSync(p).isFile()
  } catch {
    return false
  }
}

function listTextureDir(dir, pack, stem) {
  const texDir = path.join(dir, 'textures')
  const out = []
  if (!fs.existsSync(texDir) || !fs.statSync(texDir).isDirectory()) return out
  let files
  try {
    files = fs.readdirSync(texDir)
  } catch {
    return out
  }
  for (const f of files) {
    const lower = f.toLowerCase()
    if (lower.endsWith('.dds') || lower.endsWith('.png') || lower.endsWith('.tga') || lower.endsWith('.jpg')) {
      out.push({ name: f, url: reviewAssetUrl(pack, stem, `textures/${f}`) })
    }
  }
  return out.sort((a, b) => a.name.localeCompare(b.name))
}

/**
 * Collect every review URL we know about for one stem (mesh, textures, JSON sidecars, havok, submeshes).
 * Stems are listed if they have at least one primary visual (obj / gltf / mesh_scene) OR submeshes index OR ucfx.json.
 */
function buildStemAsset(pack, stem, dir) {
  const objPath = path.join(dir, 'mesh.obj')
  const gltfPath = path.join(dir, 'mesh.gltf')
  const sceneGltfPath = path.join(dir, 'mesh_scene.gltf')
  const sceneGlbPath = path.join(dir, 'mesh_scene.glb')
  const submeshIndex = path.join(dir, 'submeshes', 'index.json')
  const ucfxPath = path.join(dir, 'ucfx.json')

  const hasObj = fileExists(objPath)
  const hasGltf = fileExists(gltfPath)
  const hasScene = fileExists(sceneGltfPath)
  const hasGlb = fileExists(sceneGlbPath)
  const hasSubmesh = fileExists(submeshIndex)
  const hasUcfx = fileExists(ucfxPath)

  if (!hasObj && !hasGltf && !hasScene && !hasGlb && !hasSubmesh && !hasUcfx) return null

  const textureFiles = listTextureDir(dir, pack, stem)
  const firstDds = textureFiles.find((t) => t.name.toLowerCase().endsWith('.dds'))
  const firstPng = textureFiles.find((t) => t.name.toLowerCase().endsWith('.png'))

  const sidecars = {
    ucfxJson: hasUcfx ? reviewAssetUrl(pack, stem, 'ucfx.json') : null,
    meshMetaJson: fileExists(path.join(dir, 'mesh.meta.json')) ? reviewAssetUrl(pack, stem, 'mesh.meta.json') : null,
    dialogFragmentsJson: fileExists(path.join(dir, 'dialog_fragments.json'))
      ? reviewAssetUrl(pack, stem, 'dialog_fragments.json')
      : null,
    levelHintsJson: fileExists(path.join(dir, 'level_hints.json')) ? reviewAssetUrl(pack, stem, 'level_hints.json') : null,
    havokManifestJson: fileExists(path.join(dir, 'havok', 'manifest.json'))
      ? reviewAssetUrl(pack, stem, 'havok/manifest.json')
      : null,
    texturesManifestJson: fileExists(path.join(dir, 'textures', 'manifest.json'))
      ? reviewAssetUrl(pack, stem, 'textures/manifest.json')
      : null,
    textureManifestRichJson: fileExists(path.join(dir, 'textures', 'texture_manifest.json'))
      ? reviewAssetUrl(pack, stem, 'textures/texture_manifest.json')
      : null,
    meshSceneBin: fileExists(path.join(dir, 'mesh_scene.bin')) ? reviewAssetUrl(pack, stem, 'mesh_scene.bin') : null,
    sharedTexturesJson: fileExists(path.join(dir, 'shared_textures.json'))
      ? reviewAssetUrl(pack, stem, 'shared_textures.json')
      : null,
  }

  const shortStem = stem.length > 56 ? `${stem.slice(0, 53)}…` : stem
  const artifactTokens = [
    stem,
    pack,
    ...textureFiles.map((t) => t.name),
    ...Object.entries(sidecars)
      .filter(([, u]) => u)
      .map(([k]) => k),
  ]
    .join(' ')
    .toLowerCase()

  return {
    key: `${pack}/${stem}`,
    label: `${pack} — ${shortStem}`,
    pack,
    stem,
    obj: hasObj ? reviewAssetUrl(pack, stem, 'mesh.obj') : null,
    gltf: hasGltf ? reviewAssetUrl(pack, stem, 'mesh.gltf') : null,
    meshSceneGltf: hasScene ? reviewAssetUrl(pack, stem, 'mesh_scene.gltf') : null,
    glb: hasGlb ? reviewAssetUrl(pack, stem, 'mesh_scene.glb') : null,
    dds: firstDds ? firstDds.url : firstPng ? firstPng.url : null,
    manifest: hasSubmesh ? reviewAssetUrl(pack, stem, 'submeshes/index.json') : null,
    textureFiles,
    sidecars,
    /** Lowercase blob for client-side filter (paths, texture names, sidecar keys). */
    artifactSearch: artifactTokens,
  }
}

function collectFromReviewRoot(reviewRoot) {
  const assets = []
  if (!fs.existsSync(reviewRoot)) return assets

  let entries
  try {
    entries = fs.readdirSync(reviewRoot, { withFileTypes: true })
  } catch {
    return assets
  }

  for (const ent of entries) {
    if (!ent.isDirectory()) continue
    const name = ent.name
    if (!name.startsWith('batch_')) continue
    const packDir = path.join(reviewRoot, name)
    let stems
    try {
      stems = fs.readdirSync(packDir, { withFileTypes: true })
    } catch {
      continue
    }
    for (const st of stems) {
      if (!st.isDirectory()) continue
      const stem = st.name
      const dir = path.join(packDir, stem)
      const row = buildStemAsset(name, stem, dir)
      if (row) assets.push(row)
    }
  }
  return assets
}

function mergeAssets(roots) {
  const seen = new Map()
  for (const root of roots) {
    for (const a of collectFromReviewRoot(root)) {
      if (!seen.has(a.key)) seen.set(a.key, a)
    }
  }
  return [...seen.values()].sort((x, y) => x.key.localeCompare(y.key))
}

function packCounts(assets) {
  const c = {}
  for (const a of assets) {
    c[a.pack] = (c[a.pack] || 0) + 1
  }
  return c
}

function dirHasBlockBins(batchDir) {
  const blocks = path.join(batchDir, 'blocks')
  try {
    if (!fs.existsSync(blocks) || !fs.statSync(blocks).isDirectory()) return false
    const files = fs.readdirSync(blocks)
    return files.some((f) => f.endsWith('.bin'))
  } catch {
    return false
  }
}

/** Explain missing vz / vehicle assets when FFCS exists but batch decompress was skipped. */
function pipelineHints(reviewRoots) {
  const hints = []
  const seenExtracted = new Set()
  for (const reviewRoot of reviewRoots) {
    const extractedDir = path.dirname(reviewRoot)
    if (seenExtracted.has(extractedDir)) continue
    seenExtracted.add(extractedDir)

    const ffcsVz = path.join(extractedDir, 'ffcs_vz')
    const batchVz = path.join(extractedDir, 'batch_vz')
    if (!fs.existsSync(ffcsVz)) continue
    if (dirHasBlockBins(batchVz)) continue

    hints.push({
      id: 'vz_batch_missing',
      message:
        'Found extracted/ffcs_vz but no batch_vz/blocks — vehicles and most character meshes live in vz.wad. Run the full pipeline without --quick, or decompress vz only: scripts/extract_all_from_paths.sh …/extracted/ffcs_vz (optionally --max N), then scripts/stage2_review_extract.sh <pipeline-root>.',
    })
  }
  return hints
}

function mimeFor(filePath) {
  const ext = path.extname(filePath).toLowerCase()
  const m = {
    '.obj': 'text/plain; charset=utf-8',
    '.dds': 'image/vnd-ms-dds',
    '.json': 'application/json',
    '.gltf': 'model/gltf+json',
    '.bin': 'application/octet-stream',
    '.glb': 'model/gltf-binary',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.meta.json': 'application/json',
  }
  if (filePath.endsWith('.meta.json')) return 'application/json'
  return m[ext] || 'application/octet-stream'
}

function discoverAnimationRoots() {
  const roots = new Set()
  const add = (p) => {
    try {
      const resolved = path.resolve(p)
      if (fs.existsSync(resolved) && fs.statSync(resolved).isDirectory()) {
        roots.add(resolved)
      }
    } catch {
      /* ignore */
    }
  }
  const env = process.env.MERCS2_ANIMATIONS_ROOT
  if (env && env.trim()) {
    for (const s of env.split(',')) {
      add(s.trim())
    }
  }
  add(path.join(repoRoot(), 'output', 'animations'))
  return [...roots]
}

function readJsonIfExists(filePath) {
  try {
    if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
      return JSON.parse(fs.readFileSync(filePath, 'utf8'))
    }
  } catch {
    /* ignore */
  }
  return null
}

function discoverPlacementsRoot() {
  const env = process.env.MERCS2_PLACEMENTS_ROOT
  if (env && env.trim()) {
    const p = path.resolve(env.trim())
    if (fs.existsSync(p) && fs.statSync(p).isDirectory()) return p
  }
  const r = repoRoot()
  const def = path.join(r, 'output', 'placements')
  if (fs.existsSync(def) && fs.statSync(def).isDirectory()) return def
  return null
}

const PLACEMENT_DATASETS = [
  { id: 'pmc_base', file: 'pmc_base.json', label: 'pmc_base.json (PMC testbed)' },
  { id: 'maracaibo', file: 'maracaibo_placements.json', label: 'maracaibo_placements.json' },
  { id: 'layers_static', file: 'layers_static.json', label: 'layers_static.json (full world)' },
]

function loadPlacementDataset(root, datasetId) {
  const row = PLACEMENT_DATASETS.find((d) => d.id === datasetId)
  if (!row) return { error: 'unknown_dataset', id: datasetId }
  const fp = path.join(root, row.file)
  const doc = readJsonIfExists(fp)
  if (!doc) return { error: 'file_not_found', path: fp, id: datasetId }
  const placements = Array.isArray(doc) ? doc : doc.placements || []
  const bbox = doc.bbox || null
  return {
    id: datasetId,
    path: fp,
    label: row.label,
    placements,
    count: placements.length,
    bbox,
    meta: {
      total_placements: doc.total_placements,
      layers_static_in_bbox: doc.layers_static_in_bbox,
    },
  }
}

function pmcBasePresetBbox() {
  const fp = path.join(repoRoot(), 'output', 'pmc_base_block_set.json')
  const doc = readJsonIfExists(fp)
  if (!doc) return null
  const b = doc.bbox_game_units
  if (!b || !b.min || !b.max) return null
  return {
    path: fp,
    name: 'PMC HQ',
    anchor_entity: doc.anchor_entity,
    anchor_position: doc.anchor_position,
    bbox: {
      x_min: b.min.x,
      x_max: b.max.x,
      z_min: b.min.z,
      z_max: b.max.z,
      y_min: b.min.y,
      y_max: b.max.y,
    },
  }
}

function collectMaracaiboGlbUrls() {
  const roots = discoverReviewRoots()
  const listPath = path.join(repoRoot(), 'output', 'maracaibo_asset_list.json')
  const doc = readJsonIfExists(listPath)
  if (!doc || typeof doc !== 'object' || !doc.assets) return { listPath, count: 0, items: [] }
  const out = []
  const byCat = doc.assets
  for (const [_cat, rows] of Object.entries(byCat)) {
    if (!Array.isArray(rows)) continue
    for (const row of rows) {
      const pack = row.pack
      const stem = row.stem
      if (!pack || !stem) continue
      for (const root of roots) {
        const full = path.join(root, pack, stem, 'mesh_scene.glb')
        if (fileExists(full)) {
          out.push({
            pack,
            stem,
            category: row.category || null,
            url: reviewAssetUrl(pack, stem, 'mesh_scene.glb'),
          })
          break
        }
      }
    }
  }
  return { listPath, count: out.length, items: out }
}

function collectAnimations(animRoots) {
  const out = []
  for (const root of animRoots) {
    let entries
    try {
      entries = fs.readdirSync(root, { withFileTypes: true })
    } catch {
      continue
    }
    for (const d of entries) {
      if (!d.isDirectory()) continue
      const slug = d.name
      const glb = path.join(root, slug, `${slug}.glb`)
      if (fs.existsSync(glb)) {
        const sidecarPath = path.join(root, slug, 'clips_manifest.json')
        const sidecar = readJsonIfExists(sidecarPath)
        const row = {
          slug,
          url: `/__anim__/${encSegs(slug, `${slug}.glb`)}`,
          path: glb,
          clipsManifestUrl: `/__anim__/${encSegs(slug, 'clips_manifest.json')}`,
        }
        if (sidecar && typeof sidecar === 'object') {
          if (sidecar.block_stem) row.blockStem = sidecar.block_stem
          if (sidecar.stem_numeric_id != null) row.stemNumericId = sidecar.stem_numeric_id
          if (Array.isArray(sidecar.related_review_keys)) row.relatedReviewKeys = sidecar.related_review_keys
          if (Array.isArray(sidecar.clips)) row.clips = sidecar.clips
        }
        out.push(row)
      }
    }
  }
  return out
}

function attachReviewMiddleware(server) {
  server.middlewares.use((req, res, next) => {
    const url = req.url.split('?')[0]

    if (url === '/api/review-assets.json') {
      const roots = discoverReviewRoots()
      const assets = mergeAssets(roots)
      const counts = packCounts(assets)
      const hints = pipelineHints(roots)
      res.setHeader('Content-Type', 'application/json; charset=utf-8')
      res.end(
        JSON.stringify({
          roots,
          count: assets.length,
          packCounts: counts,
          pipelineHints: hints,
          assets,
        })
      )
      return
    }

    if (url === '/api/placements-catalog.json') {
      const root = discoverPlacementsRoot()
      res.setHeader('Content-Type', 'application/json; charset=utf-8')
      if (!root) {
        res.statusCode = 404
        res.end(JSON.stringify({ error: 'placements_root_not_found' }))
        return
      }
      const datasets = PLACEMENT_DATASETS.map((d) => {
        const fp = path.join(root, d.file)
        return {
          id: d.id,
          label: d.label,
          file: d.file,
          exists: fs.existsSync(fp),
          path: fp,
        }
      })
      const defaultRow =
        datasets.find((d) => d.id === 'pmc_base' && d.exists) ||
        datasets.find((d) => d.exists) ||
        datasets[0]
      res.end(
        JSON.stringify({
          placementsRoot: root,
          defaultId: defaultRow?.id || 'pmc_base',
          datasets,
        }),
      )
      return
    }

    if (url.startsWith('/api/placements-dataset.json')) {
      const q = new URL(req.url, 'http://localhost').searchParams
      const id = (q.get('id') || 'pmc_base').trim()
      const root = discoverPlacementsRoot()
      res.setHeader('Content-Type', 'application/json; charset=utf-8')
      if (!root) {
        res.statusCode = 404
        res.end(JSON.stringify({ error: 'placements_root_not_found' }))
        return
      }
      const payload = loadPlacementDataset(root, id)
      if (payload.error) {
        res.statusCode = 404
        res.end(JSON.stringify(payload))
        return
      }
      res.end(JSON.stringify(payload))
      return
    }

    if (url === '/api/pmc-base-preset.json') {
      const preset = pmcBasePresetBbox()
      res.setHeader('Content-Type', 'application/json; charset=utf-8')
      if (!preset) {
        res.statusCode = 404
        res.end(JSON.stringify({ error: 'pmc_base_block_set_not_found' }))
        return
      }
      res.end(JSON.stringify(preset))
      return
    }

    if (url === '/api/placements-maracaibo.json') {
      const root = discoverPlacementsRoot()
      res.setHeader('Content-Type', 'application/json; charset=utf-8')
      if (!root) {
        res.statusCode = 404
        res.end(JSON.stringify({ error: 'placements_root_not_found', hint: 'Set MERCS2_PLACEMENTS_ROOT or run make extract-placements' }))
        return
      }
      const fp = path.join(root, 'maracaibo_placements.json')
      const doc = readJsonIfExists(fp)
      if (!doc) {
        res.statusCode = 404
        res.end(JSON.stringify({ error: 'file_not_found', path: fp }))
        return
      }
      res.end(JSON.stringify({ path: fp, ...doc }))
      return
    }

    if (url === '/api/placements-layers-static.json') {
      const root = discoverPlacementsRoot()
      res.setHeader('Content-Type', 'application/json; charset=utf-8')
      if (!root) {
        res.statusCode = 404
        res.end(JSON.stringify({ error: 'placements_root_not_found' }))
        return
      }
      const fp = path.join(root, 'layers_static.json')
      const doc = readJsonIfExists(fp)
      if (!doc) {
        res.statusCode = 404
        res.end(JSON.stringify({ error: 'file_not_found', path: fp }))
        return
      }
      const placements = Array.isArray(doc) ? doc : doc.placements || []
      res.end(JSON.stringify({ path: fp, placements, count: placements.length }))
      return
    }

    if (url === '/api/maracaibo-glbs.json') {
      const glbs = collectMaracaiboGlbUrls()
      res.setHeader('Content-Type', 'application/json; charset=utf-8')
      res.end(JSON.stringify(glbs))
      return
    }

    if (url === '/api/anim-assets.json') {
      const roots = discoverAnimationRoots()
      const anims = collectAnimations(roots)
      res.setHeader('Content-Type', 'application/json; charset=utf-8')
      res.end(JSON.stringify({ roots, count: anims.length, animations: anims }))
      return
    }

    if (url.startsWith('/api/anim-detail.json')) {
      const q = new URL(req.url, 'http://localhost').searchParams
      const slug = (q.get('slug') || '').trim()
      res.setHeader('Content-Type', 'application/json; charset=utf-8')
      if (!slug || slug.includes('/') || slug.includes('..')) {
        res.statusCode = 400
        res.end(JSON.stringify({ error: 'bad_slug' }))
        return
      }
      const roots = discoverAnimationRoots()
      for (const root of roots) {
        const sidecarPath = path.join(root, slug, 'clips_manifest.json')
        const doc = readJsonIfExists(sidecarPath)
        if (doc) {
          res.end(JSON.stringify(doc))
          return
        }
      }
      res.statusCode = 404
      res.end(JSON.stringify({ error: 'not_found', slug }))
      return
    }

    if (url.startsWith('/__anim__/')) {
      const raw = url.slice('/__anim__/'.length)
      const segments = raw.split('/').filter(Boolean).map((s) => decodeURIComponent(s))
      const rel = segments.join(path.sep)
      const roots = discoverAnimationRoots()
      for (const root of roots) {
        const full = path.normalize(path.join(root, rel))
        if (!isPathInside(root, full)) continue
        if (!fs.existsSync(full) || !fs.statSync(full).isFile()) continue
        res.setHeader('Content-Type', mimeFor(full))
        fs.createReadStream(full).pipe(res)
        return
      }
      res.statusCode = 404
      res.end('Not found')
      return
    }

    if (url.startsWith('/__review__/')) {
      const raw = url.slice('/__review__/'.length)
      const segments = raw.split('/').filter(Boolean).map((s) => decodeURIComponent(s))
      const rel = segments.join(path.sep)
      const roots = discoverReviewRoots()
      for (const root of roots) {
        const full = path.normalize(path.join(root, rel))
        if (!isPathInside(root, full)) continue
        if (!fs.existsSync(full) || !fs.statSync(full).isFile()) continue
        res.setHeader('Content-Type', mimeFor(full))
        fs.createReadStream(full).pipe(res)
        return
      }
      res.statusCode = 404
      res.end('Not found')
      return
    }

    next()
  })
}

function reviewAssetsPlugin() {
  return {
    name: 'mercs2-review-assets',
    configureServer(server) {
      attachReviewMiddleware(server)
    },
    configurePreviewServer(server) {
      attachReviewMiddleware(server)
    },
  }
}

/** @deprecated use discoverReviewRoots */
function configuredRoots() {
  return discoverReviewRoots()
}

export { reviewAssetsPlugin, configuredRoots, discoverReviewRoots, mergeAssets }
