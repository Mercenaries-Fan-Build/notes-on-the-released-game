---
name: browser-screenshot
description: Render a local/remote web page to a PNG with headless Chromium so Claude can visually inspect it. Use when you need to SEE a page that curl/WebFetch cannot render — especially the three.js asset viewer's WebGL canvas (localhost:5173) to skim rendered c3/model meshes and judge geometry, orientation, and placement.
---

# browser-screenshot

curl/WebFetch only return bytes/markdown — they cannot render a WebGL canvas. This skill drives
headless Chromium (Playwright) to screenshot a real render, which you then Read as an image.

## One-time setup (only if `node_modules` is missing here)

```bash
cd .claude/skills/browser-screenshot
npm install
npx playwright install chromium
```

## Deep-linking the asset viewer (no clicking)

The viewer auto-loads a mesh from URL query params (`AssetWorkbenchView.vue`):
`http://localhost:5173/workbench?obj=<objUrl>&tex=<texUrl>`
Served OBJ urls come from `/api/review-assets.json` (field `obj`, e.g. `/__review__/batch_c3build/c31914/mesh.obj`).

## Run

Single:
```bash
node .claude/skills/browser-screenshot/shot.mjs \
  --url "http://localhost:5173/workbench?obj=/__review__/batch_c3build/c31914/mesh.obj" \
  --out "<scratch>/c31914.png"
```

Batch (one browser, fast skim of many meshes) — write a JSON job list then:
```bash
node .claude/skills/browser-screenshot/shot.mjs --batch "<scratch>/jobs.json"
# jobs.json: [{ "url": "...workbench?obj=/__review__/batch_c3build/c31914/mesh.obj", "out": ".../c31914.png" }, ...]
```

Options: `--width`/`--height` (viewport, default 1600x1000), `--wait` (ms to settle after load for
WebGL frames, default 3500), `--selector` (wait for a CSS element first), `--full` (full-page).

Then **Read** each PNG to inspect it. Write PNGs to the session scratchpad, not the repo.

## Notes
- WebGL is forced through ANGLE/SwiftShader (launch args) so it renders headless.
- Needs the viewer dev server running (`cd viewer && npm run dev`). Check the port (5173, or 5174 if taken).
- If a render is blank, increase `--wait` (large OBJs load async) or check printed page errors.
