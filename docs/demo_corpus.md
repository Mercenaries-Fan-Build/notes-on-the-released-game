# Mercenaries 2 PC Demo — `vz.wad` corpus (verified)

**Date:** 2026-05-15  
**Status:** VERIFIED from `mercs2_ffcs_extract.py` manifests and `paths.txt` line counts.  
**Demo path (this repo):** `Mercenaries 2 World in Flames DEMO/data/vz.wad`  
**Retail reference:** `output/data/vz.wad` (from full game install under `output/`)

## Purpose

Smaller `vz.wad` (~0.97 GB vs ~2.57 GB retail) for cross-checking FFCS layout, block inventory, and PMC-adjacent metadata without re-running the full retail pipeline.

## FFCS manifest comparison

| Field | Demo | Retail |
|-------|------|--------|
| `version` | 2 | 2 |
| `file_size` | 1,015,414,784 | 2,565,537,792 |
| `INDX.meta` (path count) | 4,204 | 11,370 |
| `INDX.size` | 50,448 | 136,440 |
| `ASET.meta` (entry count) | 13,597 | 30,645 |
| `ASET.size` | 217,552 | 490,320 |
| **Bytes / ASET row** | **16** | **16** |
| `PTHS.meta` | 4,204 | 11,370 |
| `CSUM.meta` | 2,331 | 7,018 |

Demo extraction output: `output_demo/extracted/ffcs_vz_demo/` (`manifest.json`, `paths.txt`, `aset.bin`, `indx.bin`, `data.bin`, `pths.bin`).

## Path inventory (PMC-relevant)

The demo **includes** the five `vz_state_pmcinterior_*` overlays and `scripts_vz_P000_Q3.block` (same naming as retail).

The demo **does not** list the full `pmcoutpost_bld_*` set seen in retail: only `pmcoutpost_bld_fueldepot_nm` appears at P000–P003 in demo `paths.txt` (no `pmcoutpost_bld_hq*`, `hqsuites`, `hqinterior`, etc. in the demo path table).

## Implications

- **Layout validation:** `ASET` row width (16 bytes) matches retail; demo is suitable for decoding `aset.bin` structure before validating on the full graph.
- **Content gaps:** Interior / HQ meshes present in retail may be absent from demo `paths.txt`; PMC streaming work must be validated primarily against **retail** blobs, with demo used for script / layer naming cross-checks where paths overlap.
