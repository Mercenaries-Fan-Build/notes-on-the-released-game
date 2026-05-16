# Mercenaries 2 asset viewer (Three.js)

Development:

```bash
npm install
npm run dev
```

Production build:

```bash
npm run build
npm run preview
```

Put exported assets under `public/` (e.g. `public/models/car.obj`, `public/textures/foo.dds`) and enter URLs in the sidebar (`/models/car.obj`).

The dev server merges `output/review`, `output/extracted/review`, and optional `MERCS2_REVIEW_ROOT` paths and serves `/api/review-assets.json`.

**Placement / region map:** open [`placement-preview.html`](./placement-preview.html) (or run `make preview-placements OUTPUT=./output` from the repo root). It loads `/api/placements-maracaibo.json` (set `MERCS2_PLACEMENTS_ROOT` to your `output/placements` directory if it is not under the default `../output/placements`). Use the bbox fields + “Copy filter CLI args” to tune `tools/filter_maracaibo_placements.py`. Optional Three.js GLB spot-check uses `/api/maracaibo-glbs.json` + the first `mesh_scene.glb` from review roots.

Assets that include `submeshes/index.json` appear with a **`[submeshes]`** suffix; clicking one opens **Submesh inspection** (LOD slider, switch-state / damage filters, part-type presets, per-part visibility, and optional `textures/manifest.json` diffuse selection). You can also open a manifest directly with `?manifest=/__review__/batch_*/stem/submeshes/index.json`.

The bundled `public/models/sample.obj` is a tiny heuristic extract for smoke-testing the pipeline.
