# Mercenaries 2 asset tooling

This repo is for **people who already have the PC game** and are fine with shells, Python, and long jobs. The docs describe **what the tools expect and what they emit** ([`tools/README.md`](tools/README.md), [`docs/format_reference.md`](docs/format_reference.md)); they are not a guarantee of “works on every machine” or line-by-line fixes for every error.

## Expected retail zip layout

[`scripts/extract_from_zip.sh`](scripts/extract_from_zip.sh) assumes a **normal Mercenaries 2: World in Flames (PC)** archive. It unzips to a temp dir, then normalizes into `<zip-dir>/output/` (or `--out-dir` / `OUTPUT_DIR`):

- **Typical case:** the zip has **one** top-level folder (e.g. the game name); that folder’s **contents** are moved into `output/`, so you do **not** get a duplicate `…/output/Mercenaries 2…/data/`.
- **Other case:** multiple top-level entries are moved into `output/` as-is.

**Hard requirement after normalization:** `output/data/*.wad` must exist. The script aborts with a clear error if `output/data` is missing or contains no `.wad` files.

If your distributor’s zip layout differs (e.g. only loose files, or `data` not where the script ends up), unpack or rearrange so **`data/`** sits at **`output/data/`**, or point `--skip-unzip` at a folder you prepared by hand.

## Common issues

These are recurring pitfalls from driving the pipeline, not an exhaustive FAQ.

- **“expected …/output/data after unzip” / no `.wad` files** — Wrong archive, incomplete download, or a non-retail repack. Confirm the zip is the full PC game and that `data/*.wad` exists after a manual unzip the way *you* expect the tree to look.
- **Stale `output/`** — If `output/data` already exists, the script **reuses** it unless you pass **`--force-unzip`**. Old or partial trees cause confusing downstream errors; delete `output` or use `--force-unzip` when in doubt.
- **`--skip-unzip` without a valid tree** — Same requirement: `output/data/*.wad` must already be present.
- **Full default run** — Processes **every** `data/*.wad` including **vz** (very large). Use **`--quick`**, **`--vz-max`**, or **`--no-decompress`** / **`--no-stage2`** when you only need a slice (see script header comments).
- **`unzip` / Python** — The zip path must be readable; the script expects **`unzip`** on `PATH` and uses **`python3`** or **`.venv/bin/python`** when present (see `extract_from_zip.sh`).

## Quick start

From **only** `Mercenaries 2 World in Flames.zip` (creates `<directory-of-zip>/output/` with full extraction by default: **all** `data/*.wad` packs batch-decompressed, then stage 2 → **`extracted/review/`**):

```bash
./scripts/extract_from_zip.sh "/path/to/Mercenaries 2 World in Flames.zip"
```

Faster partial run (shell + loading only; omit vz unless you add `--decompress-vz`): `./scripts/extract_from_zip.sh --quick "/path/to/Mercenaries 2 World in Flames.zip"`

Manual steps (existing install folder):

```bash
/usr/bin/python3 tools/mercs2_ffcs_extract.py "Mercenaries 2 World in Flames/data/vz.wad" --out output/ffcs_vz
/usr/bin/python3 tools/sges_decompress.py --data-bin output/ffcs_vz/data.bin --ffcs-out output/ffcs_vz --index 0 --out output/block0.bin
# Or decompress everything listed in paths.txt (see tools/README.md → Batch extraction):
# ./scripts/extract_all_from_paths.sh output/ffcs_vz --max 10
```

## Three.js viewer

```bash
cd viewer && npm install && npm run dev
```

With **`npm run dev`**, the sidebar loads **`mesh.obj`** / **`mesh.gltf`** from discovered review folders under the repo (see below). **`MERCS2_REVIEW_ROOT`** is optional: paths from **`viewer/.env`** (`MERCS2_*`) merge with automatic scanning.

Auto-scan adds **`output/review`**, **`output/extracted/review`**, **`extracted/review`**, and **`output/<subdir>/extracted/review`** for each subdirectory of **`output/`**. Set **`MERCS2_REVIEW_ROOT`** only for installs outside the repo (comma-separated).

The asset list uses round-robin across packs when **All packs** is selected so **`batch_vz`** entries are not buried after **`batch_shell`**. Pick **batch_vz** in **Pack** for the full vz-only list.

Static **`vite build`** output does not include that API — use **`npm run dev`** or **`vite preview`** from **`viewer/`**.

Manual load / samples still work via **Manual URLs** and files under **`viewer/public/`**.

## Docs

- [tools/README.md](tools/README.md) — all Python CLIs
- [docs/format_reference.md](docs/format_reference.md) — binary layouts, unknown fields, pipeline JSON artifacts
- [docs/quickbms_notes.md](docs/quickbms_notes.md)
- [docs/game_extractor_notes.md](docs/game_extractor_notes.md)

## Python deps (optional)

```bash
pip install -r requirements.txt
```
