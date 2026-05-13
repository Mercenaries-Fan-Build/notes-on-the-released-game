# Mercenaries 2 asset tooling

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
