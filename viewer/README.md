# Mercenaries 2 Asset Viewer & Dashboard (Vue 3 SPA)

Vue 3 + Vite + Router + Pinia + Tailwind CSS + Three.js

## Development

```bash
npm install
npm run dev
```

## Production build

```bash
npm run build
npm run preview
```

## Routes

| Path | View | Description |
|------|------|-------------|
| `/` | Dashboard | Stats cards, pack breakdown, category distribution, quick links |
| `/blocks` | Block Browser | Filterable table/grid of all extracted blocks with category badges, content flags, pagination |
| `/viewer` | Asset Viewer | Three.js 3D viewer for OBJ/glTF/GLB meshes (ported from original `main.js`) |
| `/placements` | Placement Map | 2D X/Z world map with bbox overlay (ported from `placement-preview.js`) |
| `/placement-qa` | Placement QA | Named regions, filtered table, rotation/position overrides (ported from `placement-bbox.js`) |

## Data sources

The Vite dev server plugin (`vite-plugin-review-assets.js`) serves the same API endpoints as before:

- `/api/review-assets.json` — all extracted mesh/texture blocks from `output/review`
- `/api/placements-*.json` — placement data from `output/placements/`
- `/api/anim-assets.json` — animation GLBs from `output/animations/`
- `/__review__/pack/stem/file` — serves review tree files

Set `MERCS2_REVIEW_ROOT`, `MERCS2_PLACEMENTS_ROOT`, or `MERCS2_ANIMATIONS_ROOT` in `viewer/.env` to override auto-discovery.

## Architecture

```
viewer/
├── index.html              Single entry point
├── src/
│   ├── main.js             Vue app bootstrap
│   ├── App.vue             Root layout + navbar
│   ├── router.js           Vue Router config
│   ├── style.css           Tailwind CSS entry
│   ├── components/         Reusable UI components
│   │   ├── AppNavbar.vue
│   │   └── StatCard.vue
│   ├── views/              Route views
│   │   ├── DashboardView.vue
│   │   ├── BlockBrowserView.vue
│   │   ├── AssetViewerView.vue
│   │   ├── PlacementPreviewView.vue
│   │   └── PlacementBboxView.vue
│   ├── stores/             Pinia stores
│   │   ├── reviewAssets.js
│   │   ├── animations.js
│   │   └── placements.js
│   └── lib/                Shared logic
│       ├── three-viewer.js
│       ├── submesh-inspect.js
│       └── placement-bbox-store.js
├── placement-bbox-store.js  Original (re-exported by src/lib)
├── placement-bbox-map.js    Original (re-exported by src/lib)
├── vite-plugin-review-assets.js  Vite middleware (unchanged)
└── vite.config.js           Vue + Tailwind + review plugin
```

The original vanilla JS files (`main.js`, `placement-preview.js`, `placement-bbox.js`, `submesh-inspect.js`) are preserved at the viewer root for reference but are no longer the entry points.
