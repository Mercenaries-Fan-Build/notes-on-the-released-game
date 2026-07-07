# Per-Model Distinct-Texture Cap — Decomp Trace (OPEN)

**Status: static decomp exhausted; exact cap NOT isolated — needs live x32dbg
(2026-06-29).** Source of record: memory `per-model-distinct-texture-cap-trace`.

## The empirical question

Where is the per-model **distinct-texture** limit? A model with **13 distinct** textures
binds fine; the **same** model with **20 distinct** textures silently fails to bind (the
material never goes "awake"). Only the MTRL hashes differ — header `INFO[0]=57` /
`GEOM=17` / `MTRL=14` are identical between the two builds. A 2-shared-globals build (=9
distinct) is also OK.

## What the static decomp (`output/_ghidra/all_functions_decomp.txt`) DOES prove

- **`Mtrl_Parse` = `FUN_00858790`** (line 641892), per-material. Reads a u16 tex-count at
  `MTRL+106`, fills a FIXED **10-slot** `{hash, 0xF011157A, 0}` array at `material+0x144`
  (mirrored at `+0xac`); diffuse/primary at `+0xa4` via the `0x200`-flag path.
  Hard per-material cap: `if (9 < uVar16) goto LAB_00858ca8;` then zero-fills up to 10.
  **Not** the model-level discriminator (all materials here have count ≤ 3).
- **Texture AssetRef resolve = `FUN_00873140`** (`Stream_Resource_Acquire`) →
  `FUN_00874150` / **`FUN_008731f0`** (`Stream_Resource_LookupOrCreate`). Resolution goes
  through **global** ref-counted registries, not a per-model array:
  - `FUN_008242b0` — open-addressing hash lookup, capacity passed by caller = **0x100
    (256)** for the asset-TYPE registry, **5000** for the per-handle resource table
    (`FUN_008758a0`, base `DAT_01176630 + 0x42704`). Returns `0xFFFFFFFF` on probe-miss.
    Global.
  - Render-target managers (bloom/shimmer/water/reflect) pop from a **global** managed-
    texture free-list `DAT_011727e8` / counter `DAT_00ce8d04`. Character skins do **not**
    use this list.
- **Model asset readers** (`FUN_004a4c40` Model_ConsumeChunks, the `Renderable_
  ConsumeChunk_Mtrl*` family, `FUN_004a83d0`): every per-model array is sized from INFO
  header fields, then `Mtrl_Parse` runs per material. All header-sized ⇒ identical between
  the 9- and 20-distinct builds, exactly as observed.
- **Texture streaming nodes** (`FUN_008739e0` Stream_Manager_Tick: ready when
  `(*(node+0x30))(lvl) == 4`; producer free-stack at `ctx+0x3ffe8`, **2500 slots**; per-LOD
  head array at `ctx+0x4c380` = only 4 entries = mip levels 0..3). Global + large; not ~16.

## Conclusion

**No** per-model fixed distinct-texture array of ~13–16 (or `0x10`) exists in the parse /
bind / stream / render decomp paths examined. Character-skin textures resolve lazily via
the global registries above. A literal compile-time `if (count >= 16)` per-model cap was
**not located statically.**

The empirical signature (same header, only the hash SET differs; 13 ok / 20 fail;
2-shared-globals = 9-distinct ok) is most consistent with a cap on **distinct
NON-RESIDENT textures a single bind requests from the streaming system** (shared globals
are already resident ⇒ 0 new requests). The exact constant likely lives in
SecuROM-unpacked code (thunks `0x024e30a0` asset-resolve, `0x03290000` / `0x03290069`
MTRL handler) visible only at runtime.

## Next step to nail it (NOT yet done)

Use x32dbg on the live (unpacked) process:
- Break on `FUN_008731f0` / `FUN_00873140` while binding the 20-distinct model; count
  distinct resolves and watch for the one that returns 0 / fails to enqueue.
- Or break the streaming producer (`FUN_00873410`, `ctx+0x426f8`) and watch for a
  per-bind batch bound.

The on-disk decomp cannot see the SecuROM-packed resolve thunks.
