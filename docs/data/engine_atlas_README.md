# engine_atlas.json — Phase 1 cross-image name→address lookup

Date: 2026-10-02
Phase: 1 (string-anchor resolution across 4 images; PS3 excluded pending re-run)

## What it is

A canonical cross-image lookup table of engine functions that have been named on
two or more of the four decompiled Mercenaries 2 images:

- `pc_v1_1`     — PC Retail v1.1 unpacked (`output/_ghidra/`, image base `0x00400000`)
- `x360_profile`— Xbox 360 Profile devkit (`output/_ghidra_x360/`, base `0x82000000`)
- `x360_final`  — Xbox 360 Final devkit (`output/_ghidra_x360_final/`, base `0x82000000`)
- `x360_retail` — Xbox 360 retail JTAG unpack (`output/_ghidra_x360_retail/`, base `0x82000000`)

PS3 retail (`output/_ghidra_ps3_retail/`) is **not** in Phase 1 — the `.opd`
function-table seeder failed on that image and a re-run was pending on the user's
local machine at the time this atlas was generated. Phase 2 adds a `ps3_retail`
column with the same shape once that completes.

## How it was built

Per-image name sources (what was already on disk in this repo):

| Image         | Source file                                 | Named-fn count |
| ------------- | ------------------------------------------- | -------------- |
| `pc_v1_1`     | `output/engine_reassembled/MANIFEST.csv` (`recovered_name` column, aggregated from ghidra-rtti + fid + symbol-name + lua-binding) | 1 438 non-FUN  |
| `x360_profile`| `output/_ghidra_x360/xenon_decomp_named.c` (NameFromStrings + RttiNameCtors already applied) | 784 non-FUN   |
| `x360_final`  | `output/_ghidra_x360_final/xenon_final_decomp_named.c` (NameFromStrings only) | 301 non-FUN   |
| `x360_retail` | `output/_ghidra_x360_retail/xenon_retail_decomp_named.c` (NameFromStrings only) | 321 non-FUN   |

Resolution rule:
1. Parse the `.c` function headers (`==== <name> @<addr>  size=... ====`).
2. For each image, keep only names that are **uniquely addressable** on that
   image. A name that appears at ≥2 addresses on an image is dropped from that
   image (not from the atlas — the other three images may still resolve it
   uniquely).
3. For each name present on **≥2 images**, emit a row with per-image VAs and a
   confidence tag: `high` = 4/4, `medium` = 3/4, `low` = 2/4. Names present on
   only one image are dropped (insufficient — nothing to triangulate).

Build script: `scratchpad/build_atlas.py` (session-local; the atlas it writes is
the canonical artefact — the script is scratch).

## Coverage (actual, 2026-10-02)

| Tier          | Rows  | Notes                                                      |
| ------------- | ----- | ---------------------------------------------------------- |
| `high` (4/4)  | **1** | `entry` (PE entry point, trivially shared)                 |
| `medium` (3/4)| **35**| mostly Havok shape ctors + Massive engine threads          |
| `low` (2/4)   | **148**| mostly Xbox-only name tokens (NameFromStrings produces few symbols that survive on PC's RTTI-based attribution) |
| **TOTAL**     | **184**| canonical cross-image names                              |
| dropped (1/4) | 1 895 | insufficient — can't cross-check                           |

Target was ~500. The ceiling is set by two facts that only became clear during
build:
- **Xbox NameFromStrings only produces 295–538 names per image**, and only
  **36 of those overlap across all three Xbox builds**; the Final/Retail pair
  overlap on 151.
- **PC `recovered_name` uses class names, not method names** (one `hkpEntityListener`
  attribution covers 10+ constructor variants), so 539 PC names are non-unique
  and get dropped from the resolvable set.

## What was NOT done (and why)

- **RttiNameCtors on Final/Retail** — `tools/ghidra_x360/RttiNameCtors.java`
  takes a per-image `rtti_vtables.txt` (currently hardcoded to the Profile's,
  `output/_ghidra_x360/rtti_vtables.txt`, 307 vtables). No equivalent file
  exists for Final or Retail. Running the script against those projects with
  Profile addresses would label wrong code with wrong class names — net harm,
  not help.
  - **To unblock**: write a `WriteRttiVtables.java` post-script that walks
    Ghidra's own RTTI analysis output (`.?AV...@@` type descriptors → COLs →
    vtables), emits per-image `rtti_vtables.txt`, then run RttiNameCtors
    against each. Expected contribution: ~250–300 more `<Class>_ctor` rows
    per Xbox image, most of them shared ⇒ +100–200 atlas rows at ≥2/4.
- **Re-exporting the Final/Retail decomps.** The current `_named.c` files on
  disk already contain the output of a NameFromStrings run that completed on
  2026-09-06 (retail, named 314) and 2026-09-07 (final, named 295), verified
  in `output/_ghidra_x360_{final,retail}/run.log`. Re-running NameFromStrings
  via `-process` headless would be idempotent (same strings → same names).
  **Skipped.**

## Phase 2 — what unlocks when PS3 lands

Once `output/_ghidra_ps3_retail/eboot_decomp_named.c` exists (the `.opd` seeder
re-run on the user's local machine), re-run `build_atlas.py` after adding a
`ps3_retail` entry to its `GHIDRA_IMAGES` dict and the image's base RVA to the
`images` block. Expected to push the `high` tier from 1 to 20–40 and the
medium tier from 35 to 100+, because:
- PS3's binary ships with debug strings similar in richness to the Profile
  devkit (both are Pandemic-built, string-heavy),
- a function present on 4-of-5 images is strong triangulation.

Also: add Phase 2 column `resolution: "rtti-ctor"` once RttiNameCtors runs
against per-image vtables, to flag which rows are name-anchored vs vtable-anchored.

## Schema

```jsonc
{
  "generated": "YYYY-MM-DD",
  "schema": { ... prose ... },
  "images": {
    "<image_id>": { "base": "0x...", "path": "repo-relative source path" },
    ...
  },
  "function_count": 184,
  "resolution_histogram": { "1_of_4_dropped": N, "2_of_4_low": N, ... },
  "per_image_source_counts": {
    "<image_id>": { "total_names": N, "unique_resolvable": N },
    ...
  },
  "functions": [
    {
      "name": "<symbol>",
      "resolution": "string-anchor",
      "pc_v1_1":     "0x...",   // present if resolved on PC
      "x360_profile":"0x...",   // present if resolved on Profile
      "x360_final":  "0x...",
      "x360_retail": "0x...",
      "confidence":  "high|medium|low"
    },
    ...
  ]
}
```

Addresses are **virtual** (absolute), not RVAs. Subtract the image's `base` to
get RVA. All lowercased hex, `0x`-prefixed.
