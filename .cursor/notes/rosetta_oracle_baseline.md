# Rosetta Oracle — base-game BE→LE baseline

Tool: `tools/wad_be_le_oracle.py`. Converts every entry of the big-endian
`game-files/xbox-vz.wad` through the production converter (Rust
`ucfx_byteswap`, `--converter python` for the Python path) and diffs it
byte-for-byte against the PC `game-files/vz.wad` ground truth.

## Why block-path keying (not global asset hash)

`(asset_hash, type_hash)` is **not** globally unique — ~10,798 of 30,645 PC
keys recur across multiple blocks with different content (ECS layer nodes,
paths, …). The two WADs also differ in block count/order (PC 11,371 vs Xbox
11,087), so index alignment is impossible. The oracle therefore pairs per
**block path** (PTHS strings are shared) and per `(asset_hash, type_hash)`
*within* the block. Global set differences are still emitted for the
asset-inventory artifacts.

## Run

```
make build-ucfx-byteswap            # ensure the Rust binary is fresh
.venv/Scripts/python.exe tools/wad_be_le_oracle.py --converter rust --jobs 8 \
    --out-dir output/_scratch/rosetta_baseline
```

PC index ~32 s; full convert+diff ~128 s (8 threads). Artifacts in
`--out-dir`: `rosetta_oracle_report.json`, `pc_only_assets.json`,
`xbox_only_assets.json`, `pc_only_blocks.json`.

## Baseline result (fresh Rust binary, block-path keyed)

- Common blocks: **10,720** (PC-only 650, Xbox-only 367 — naming shows
  streaming/LOD restructure, e.g. PC `…_p003_q0` / `__shared__` vs Xbox
  `…_p002_q1`).
- Asset instances compared: 39,826 → **30 MATCH**, 39,796 MISMATCH.
- PC-only assets: 231 (mostly `texture` 169, `animation` 36); Xbox-only: 0.

The mismatch split (size-equal vs size-different payload) cleanly separates
two regimes:

| Regime | Signal | Types |
|--------|--------|-------|
| **True re-encode (Tier-3)** | payload **size differs** | `texture` (18,890), `mesh_A/B/C`, `ecs_node` (PC 4–20× larger), `script` |
| **Small converter bug** | payload **size equal**, few bytes differ | `path` (5,142), `animation` (4,187), and most minor types |

### Confirmed example — `path` (0xBCFE6314), size-equal, 4 bytes off

Every `path` instance mismatches in a tiny fixed region (entry payload 104 B,
diff at 0x28/0x2A and 0x2C/0x2E): two u16-ish field pairs are **transposed**
between converted and PC (`01↔02`, `04↔00`). A single converter bug ×5,194
instances — not 5,194 real differences. (Not yet fixed; logged for the
converter backlog. The oracle is the regression test for it.)

### Textures (0xF011157A) — the primary target

18,890 size-different + 2,650 size-equal + 15,225 in-block-unpaired (PC moved
the texture to a different block; they pair globally — only 169 are truly
PC-only). The converter leaves texture INFO format bytes [14:22] and the BODY
as raw Xbox passthrough (see `_convert_texture_info`, and the Rust BODY
no-op), so converted textures still carry the Xbox GPU format word + tiled
DXT body. This is the Tier-3 gap to solve (`tools/xbox_texture_solver.py`).

## PC-only / Xbox-only inventory (artifacts)

- `pc_only_assets.json`: **231** assets present in PC, absent from Xbox —
  `texture` 169, `animation` 36, `script` **2**, plus minor types. The two
  PC-only scripts mirror the `modloader` script-absence fault from the
  GlobalEnter analysis: content a pure Xbox→PC port can never supply (no BE
  source to convert).
- `xbox_only_assets.json`: **0** — the Xbox base game is an asset subset of
  the PC release (PC is the superset).
- `pc_only_blocks.json`: 651 PC-only / 369 Xbox-only block paths (streaming/LOD
  restructure between platforms).

## Texture transform — SOLVED (tools/xbox_texture_solver.py + xbox_texture_codec.py)

13,171 textures paired globally by `asset_hash` (content-addressed). The
converter currently leaves texture INFO bytes [14:22] + the DXT BODY as raw
Xbox passthrough; the solver derives the real transform from the corpus.

### INFO (field re-layout, not a FourCC passthrough)
- Format word low byte: `0x52`→DXT1, `0x54`→DXT5 (Xbox D3DFMT). `...54` is
  cleanly DXT5; `...52` is mostly DXT1 but ~20% pair with PC **DXT5** — PC
  re-authored those to a different format (same asset hash). A faithful port
  preserves the Xbox-native format.
- The INFO **u16 header fields are reordered** vs PC (e.g. Xbox `…mip,arr…` vs
  PC `…arr,mip…`), the `[18:22]` LOD-bias **float is left big-endian** (bug:
  must swap), and `total_size` is the Xbox **tile-padded** size vs PC's
  **linear** mip-chain size (must be recomputed). Artifact:
  `output/_scratch/rosetta_tex/texture_info_map.json`.

### BODY (untile + within-block endian) — validated byte-exact
`tools/xbox_texture_codec.py`: XGAddress2DTiledOffset untile (verified vs Xenia
`GetTiledOffset2D` / gildor UEViewer) + 16-bit byteswap of every DXT block
word. Validated on the corpus top mip
(`xbox_texture_solver.py validate --dump …`):
- **100.00% byte-exact** for DXT5 512²/1024² and DXT1 1024²/2048² (8 textures).
- A subset of 512²-DXT1 pairs match ~60% — consistent with PC re-authoring
  those specific textures (same divergence as the INFO format-word split),
  not a codec error (the codec is proven exact on identical assets).
- Streaming: a texture hash recurs as multiple block instances/mip stubs;
  full surfaces are the large entries (xbox≥pc, ratio≈1.0–1.13). Per-entry
  pairing must be streaming-aware.

## Codec integration — DONE (ucfx_be_to_le.py + texture_extractor.py)

`xbox_texture_codec` is now wired into both the converter and the viewer:

- **Converter** (`tools/ucfx_be_to_le.py`): `_convert_texture_entry()` special-cases
  `type_hash 0xF011157A`. It locates the INFO+BODY descriptors, untiles the full
  DXT mip chain (incl. the packed mip tail), and rebuilds the 34-byte PC INFO,
  then `_convert_container` swaps those chunks in via a `tex_override` map.
  Streamed mip-stub instances (`body < tiled_body_size`) and non-DXT entries
  pass through to the generic path. Counters: `texture_untiled`,
  `texture_streamed_stub_passthrough`, `texture_nondxt_passthrough`,
  `texture_codec_error`. The block's overall size shrinks (tiled→linear);
  `byteswap_ucfx_block` already reframes around per-entry size changes.
- **Extractor** (`tools/texture_extractor.py`): `maybe_untile_xbox_texture()`
  detects an Xbox-format INFO (packed format word, not an ASCII FourCC) and
  untiles before the normal DDS/PNG path. No-op on PC textures.

### Python vs Rust INFO field widths (fixed)
INFO `[4:8]` and `[8:12]` are **u32** fields. The Rust converter byteswaps them
as u32; the Python `_convert_texture_info` swaps them as 2× u16 (position-
preserving). `rebuild_texture_info` was tuned to the Rust form (it transposes
the two u16 halves to undo the u32 swap), so the Python path must transpose
`[4:6]↔[6:8]` and `[8:10]↔[10:12]` before calling `rebuild` — done in
`_convert_texture_entry`.

### Validation (output/_scratch/_validate_membership.py)
Direct byteswap of texture blocks, comparing each Xbox **full** instance
(untiled body length == PC body length) to PC ground truth:
- **BODY: byte-exact** for all format-preserving textures (`body_ok=True`).
- **INFO `[0:12]` + `[14:32]`: byte-exact** (w/h/f4/mips/f8/f10, FourCC, LE LOD
  float, linear total_size, f26/f30) after the u32-field fix.

### Two notions of "loss" — keep them separate (RETRACTION of "unrecoverable")
An earlier note called `[12:14]`/`[32:34]` *unrecoverable*. That was wrong and
conflated two different things:

1. **Matching the retail PC `vz.wad` byte-for-byte** — here PC genuinely carries
   metadata the Xbox source never had:
   - **`[32:34]` streaming/residency tail**: PC uses a *complex* partial-residency
     form for **71.7%** of textures, the `…FFFF` sentinel for 17.9%, and the
     `2^mips-1` mip mask for 10.5% — the *same* geometry carries any of them (a PC
     build-time streaming choice). We emit the fully-resident sentinel `00…FFFF`.
   - **`[12:14]` (f12)**: PC stores a different value for a subset (PC `2` vs Xbox
     `1`); not derivable from the Xbox texture.
   - Plus the re-authored set (PC re-encoded/resized) which can never byte-match a
     pure port.
   This is a property of an *external artifact we don't control* — the PC build
   authored extra data.

2. **Round-trip BE→LE→BE recovering the original Xbox bytes** — a property of *our
   own transform*, which we fully control. Nothing is fundamentally unrecoverable:
   - **Tiling is a proven bijection**: `output/_scratch/_retile_roundtrip.py` —
     `untile → retile` reproduces the original Xbox tiled body **24/24** byte-for-byte.
   - **Cropped padding is all-zero (24/24)** — re-padding with zeros restores it
     exactly; no information is in the dropped padding.
   - 16-bit DXT swap, LOD float swap: bijective. total_size / format word:
     recomputable from geometry.
   - The *only* bytes the shipping converter actually discards are the `[32:34]`
     streaming descriptor (overwritten with the PC sentinel by **choice**, not
     necessity). Preserve those 8 bytes (side-band or passthrough) and BE→LE→BE is
     zero-loss.

So: pixel data + all geometric INFO port byte-exact; the PC-match residual is PC
authoring metadata; and a true lossless round-trip is achievable by preserving the
streaming descriptor instead of replacing it.

## Codec ported to Rust — DONE (the path `make dlc-port` actually uses)

`dlc_port.py` converts texture blocks with the **Rust** `ucfx_byteswap` crate
(Python is only used for ECS-layer blocks), so the Python integration alone did
NOT untile DLC textures. The untile + INFO rebuild is now ported to
`tools/wad_simulator/crates/ucfx_byteswap/src/convert.rs`:

- New helpers mirror `xbox_texture_codec.py`: `tiled_block_index`,
  `untile_surface`, `swap16_blocks`, `crop_blocks`, `untile_dxt_body`
  (packed mip tail), `linear_mip_chain_size`, `tiled_body_size`,
  `rebuild_texture_info`.
- `apply_texture_untile()` runs after the generic body pass: the existing
  `convert_texture_info` already produces the basic-swapped ("rust xi") INFO, so
  it rebuilds the PC INFO from that, untiles the BODY, overwrites INFO,
  truncates+appends the linear BODY, and patches the BODY descriptor size.
  Only full (non-streamed, BODY-is-last) DXT entries; stubs/non-DXT fall
  through. `convert_block`'s Pass 2 recomputes `chunk_size` + CSUM from the new
  (shorter) container length, so the reframe needs no other changes.

### mips-detection bug (found + fixed in the Python integration)
INFO `[4:8]`/`[8:12]` are **u32** fields. Rust's `convert_texture_info` swaps
them as u32 (correct); the Python `_convert_texture_info` swaps them as 2x u16,
so `texture_geometry` (which reads the mip count from the `[4:8]` u32) read the
wrong half and under-untiled some textures (e.g. a full 512² read as mips=1 →
top mip only). Fixed in `_convert_texture_entry` by transposing the u16 halves
before geometry/rebuild. Rust was correct from the start.

### Validation
- **Rust vs Python parity** (`_validate_rust.py`), fully-untiled instances:
  **190/190 INFO+BODY byte-exact**. Two independent untile implementations
  agreeing byte-for-byte.
- **Rust vs PC ground truth** (`_validate_rust_pc.py`): 501 full instances
  scored, **220 fully byte-exact**, all 501 geometry-exact (`INFO[:26]`). The
  ~280 body diffs start at offset 0 with correct geometry — the documented PC
  **re-authoring** (DXT1-512 re-encode), confirmed because Python and Rust
  agree on those bodies while PC differs.

So `make dlc-port` now untiles Xbox textures into loadable PC textures
(byte-exact except PC-re-authored assets and the PC-authored
`[12:14]`/`[32:34]` streaming metadata — see the retraction above: that is a
PC-match residual, not a round-trip loss). Rebuild with `make build-ucfx-byteswap`.

## Regression gate

`make rosetta-oracle` (depends on `build-ucfx-byteswap`) runs the full diff;
`ROSETTA_TYPE=0xF011157A` to scope one type, `ROSETTA_JOBS=N` to parallelise.
Any converter change that regresses a previously-MATCHing asset will show up as
a new MISMATCH.

## Caveats

- Whole-container byte-equality is strict: it also flags benign container
  framing differences (descriptor offsets, padding, CSUM). Most size-equal
  mismatches are small; the texture solver compares at **chunk** granularity
  (INFO / BODY payloads) to avoid framing noise.
- `--extract-dir DIR` materializes mirrored per-entry trees
  (`pc/ xbox_le/ xbox_be/<block>/<hash>_<type>.bin`) for `diff -r` / hex
  inspection (use with `--type` to bound volume).
