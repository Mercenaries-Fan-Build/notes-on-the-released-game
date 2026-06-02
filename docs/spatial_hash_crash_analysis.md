# Spatial Hash Table Crash Analysis: Asset Registration Overflow

**Date**: 2026-05-28 (updated 2026-06-01b)  
**Primary crash sites**: `0x248BB7C` (read), `0x248BBE2` (write) — same function `0x248BB60`  
**Status**: **ROOT CAUSE CONFIRMED & FIXED (2026-06-01b)** — the **CHDR chunk header** was byteswapped as two `u32`s, but the engine dispatcher `0x654940` reads it as `{ u16 fieldA@+0; u16 stride@+2; u32 flags@+4 }`. The whole-`u32` swap **transposes the two u16 fields**, zeroing the `u16@+2` stride gate that the engine writes to process-global `[0x01176078]`. The Transform record builder `0x0063D7C0` then strides **40** (gate `< 0x2A`) instead of **42** → cumulative 2-byte/record drift → record-1 garbage position → unclamped `cvttss2si` → wild spatial-hash cell → AV write `0x0248BBE2`. **Fix:** swap CHDR header as `u16@+0`, `u16@+2`, `u32@+4` in both converters. Verified: retail `layers_static` block 29 oracle = `00 00 38 00 02 00 00 00` (u16@+2 = 56 ≥ 42); deployed (old) block 18 = `38 00 00 00 02 00 00 00` (u16@+2 = 0, broken); fixed Python **and** Rust converters both produce `00 00 38 00 02 00 00 00` (u16@+2 = 56). Transform data still decodes to 734/734 clean Maracaibo coords. See **§2026-06-01b** below. (The earlier `schm` half-swap — §2026-06-01 — was a real but non-fatal defect; this CHDR gate is the actual crash differentiator.)

> Prior status (2026-05-31): OPEN — offline scan **0** violations on SHA `8700856a…`. **Fix target: index 18** (`dlc01_dlccon004_roads_P000_Q3`) — necessary for full-patch AV; **1-block repro WAD** sufficient. **Index 13** (`dlccon002_race`) also sufficient alone. **Index 6** (`dlccon002_roads`) ruled **OUT**. Confirmed deploy `vz-patch-keep-dlccon004-roads-only.wad` SHA **`6809da8e…`** → Shop/players then FATAL @ **`0x0248BB7C`** / `fault=0x6F319F84` after ~**30 s**. Block **18** on-disk record bytes clean; suspected runtime entity mis-base.

## 2026-06-01c — SECOND crash: EFCT effect header u16-swept (count gate zeroed) → COLR-append NULL deref

**Symptom:** after the CHDR fix the save-load no longer crashed in the spatial
hash, but a **new** first-chance access violation fired **"as the layer tries to
join"**: a **WRITE to `0x00000004`** (null + 0x4) at `mercenaries2.exe`
**`0x00493102`**, inside the particle-effect component loader `0x00492AF0`.

### The engine read (live debug + static RE)

`0x00492AF0` walks an effect container's chunks and, for a `COLR`
(`0x524C4F43`) chunk, **appends a 16-byte descriptor** into a per-effect array
at `[EDI+0x60]` indexed by `[EDI+0x70]`:

```
mov edx,[edi+0x70]      ; index (0 on first COLR)
add edx,[edi+0x60]      ; + record-array base  ← base is NULL
mov [edx+0x04], ecx     ; 0x00493102  → WRITE to 0x4  (AV)
```

At the fault: `[EDI+0x60] = NULL` (record array never allocated),
`[EDI+0x64]` = a valid sibling array, `[EDI+0x70] = 0`,
`[EDI+0x6C] = 0xFFFF9001` (a sign-extended garbage count). The array at
`[EDI+0x60]` is sized from a **sub-component count** the loader reads out of the
effect header (**`EFCT`** chunk). A zero/garbage count → zero-length (NULL)
allocation → the first `COLR` append dereferences NULL.

### The bug — EFCT swapped as a u16 array (must be u32)

`EFCT` is an 18-byte header = **`{ u32 ×4 ; u16 }`** where several u32 words pack
two `u16` sub-fields. Verified against the retail PC oracle (`vz.wad` `particle`
blocks): the constant magic **`0x0226` sits at byte +2**, and the
**sub-component count sits at byte +14** (retail values 4..11). The Python
converter routed `EFCT` to `_convert_u16_array`, which **transposes the two
halves of every u32** — moving the magic to +0 and **zeroing the +14 count**:

```
BE source (u32[3])    : 00 04 00 00
whole-u16 swap (BUGGY) : 04 00 00 00   → u16@+14 = 0x0000  → NULL alloc → CRASH
whole-u32 swap (FIX)   : 00 00 04 00   → u16@+14 = 0x0004  → allocate → OK
```

Same bug class as the CHDR `{u16;u16;u32}` gate above. (COLR content itself is
genuine 4-byte fields — BGRA color + a time/key per 16-byte stride — and was
already swapped correctly as u32; it is *not* the corrupted field.)

### Oracle + deployed-data verification (no game)

| Source | EFCT magic @+2 | count @+14 | Result |
|--------|----------------|-----------|--------|
| Retail `vz.wad` particle EFCT (native-LE oracle) | `0x0226` | 4..11 | alloc OK |
| Deployed `vz-patch.wad` EFCT (OLD u16 converter), **all 4 chunks** | (at +0) | **0** | NULL → crash |
| Re-converted from inferred BE — **fixed Python** `_convert_efct_header` | `0x0226` | nonzero | alloc OK |
| Re-converted — **fixed Rust** `convert_efct_header_inplace` | `0x0226` | nonzero | alloc OK |

Validation: every one of the **4** EFCT chunks in `vz-patch.wad` has
`count@+14 == 0` under the old output (all would crash); the fixed converter
restores `magic@+2 = 0x0226` and a nonzero `+14` count for all 4, with 0
anomalies.

**Fix:** route `EFCT` to a typed `{u32 ×4 ; u16}` swap in both converters
(`_convert_efct_header` in `tools/ucfx_be_to_le.py`,
`convert_efct_header_inplace` in `tools/wad_simulator/.../convert.rs`); keep
`EMTR` (a 2-byte u16 emitter count) as a u16 swap. Regression tests
(`tools/test_ecs_comp_byteswap.py::EfctHeaderTests`, Rust
`efct_header_u32_swap_preserves_count_gate`) assert the +14 count survives.
The deployed `vz-patch.wad` must be rebuilt with the fixed converter to clear
this crash (not done here per instruction).

---

## 2026-06-01b — ROOT CAUSE: CHDR `{u16;u16;u32}` header transposed by whole-u32 swap

**Method:** static RE of the engine chunk dispatcher + on-disk CHDR decode against
the retail PC native-LE oracle, then BE-source re-derivation (ground truth).

### The engine read (static RE)

The chunk dispatcher `0x654940` reads the **CHDR body** as:

```
struct CHDR { u16 fieldA @ +0;  u16 stride @ +2;  u32 flags @ +4; }
```

The `u16 @ +2` is stored to process-global `[0x01176078]`. The **Transform** record
builder `0x0063D7C0` uses it as the per-record **stride gate**:

```
stride = ([0x01176078] >= 0x2A) ? 42 : 40;   // 40 skips a 2-byte flags trailer
```

A stride of 40 instead of 42 introduces a **2-byte drift per record**: record 0 reads
OK, record 1 onward reads a position field 2 bytes early → garbage float → unclamped
`cvttss2si` → out-of-range spatial-hash cell → AV write `0x0248BBE2`.

### The bug

Both converters reversed the CHDR first 8 bytes as **two `u32`s**, which **transposes**
the two `u16` fields:

```
BE source              : 00 00 00 38 | 00 00 00 02
whole-u32 swap (BUGGY)  : 38 00 00 00 | 02 00 00 00   → u16@+2 = 0x0000 (0)   < 42 → stride 40 → CRASH
per-u16 swap   (FIX)    : 00 00 38 00 | 02 00 00 00   → u16@+2 = 0x0038 (56) ≥ 42 → stride 42 → OK
```

### Oracle + end-to-end verification (no game)

| Source | CHDR body (LE) | `u16@+2` | Engine stride |
|--------|----------------|----------|---------------|
| Retail `layers_static` block 29 (native-LE oracle, all 173 sub-blocks) | `00 00 38 00 02 00 00 00` | **56** | 42 (OK) |
| Deployed `vz-patch.wad` block 18 (OLD converter) | `38 00 00 00 02 00 00 00` | **0** | 40 (CRASH) |
| Re-converted block 18 — **fixed Python** | `00 00 38 00 02 00 00 00` | **56** | 42 (OK) |
| Re-converted block 18 — **fixed Rust** (`make dlc-port` path) | `00 00 38 00 02 00 00 00` | **56** | 42 (OK) |

- Retail scan: **no** CHDR with body > 16 B exists in the first 250 `layers_static`
  blocks, so the small (≤ 16 B) branch covers every real CHDR; the large/`guidmap`
  branch needed only the same `{u16;u16;u32}` header swap (rest of the region is
  reached via sibling enum/COMP/flgs descriptors and is left untouched). No
  all-`u32` CHDR is corrupted by the change.
- Converted block 18 Transform data: **734/734** records (stride 42) decode to
  finite, in-envelope Maracaibo coords with unit quaternions — the gate fix does
  not alter the stored record bytes.

### The fix (verified, parity)

- `tools/ucfx_be_to_le.py::_swap_chdr_header` (new) — swaps `u16@+0`, `u16@+2`,
  `u32@+4`; called by `_convert_chdr_body` in the small, ECS/META-large, and
  generic-large branches. Bytes beyond +8 keep each branch's prior treatment.
- `tools/wad_simulator/crates/ucfx_byteswap/src/convert.rs::swap_chdr_header_inplace`
  (new) — same logic; `convert_chdr_body_inplace` applies it in both the `≤ 16` and
  large branches.
- Regression tests: `tools/test_ecs_comp_byteswap.py::ChdrHeaderTests` and
  `convert.rs` `chdr_header_per_u16_swap_matches_retail_oracle` /
  `chdr_large_guidmap_only_swaps_header`. Python 16/16 pass; Rust `ucfx_byteswap`
  8/8 pass.

**Next step:** rebuild the patch WAD on the build machine (`make dlc-port`, Rust
path), redeploy, and re-run the in-game save-load — the spatial-hash AV
(`0x0248BBE2` / `0x0248BB7C`) should be cleared.

## 2026-06-01 — ROOT CAUSE: `schm` field-`offset` half-swap (converter bug)

**Method:** structural diff of converted DLC blocks against PC-native retail blocks
that load fine (the ground-truth oracle), then BE-source re-derivation.

### What was ruled out (offline, no game)

| Hypothesis | Test | Result |
|------------|------|--------|
| Wrong record stride | COMP inventory of block 18 vs retail `vz_mar_roads` | **Identical** strides: Transform 42, Road 44, RoadIntersection 128, HibernationControl 10, DestructionLink 20 → ruled OUT |
| Crash-specific component | Presence matrix blocks 2/6 (safe) vs 13/18 (crash) | No component in both crash blocks yet absent from both safe blocks (block 2 even has `DestructionLink`+`AtmosphereBase`) → ruled OUT |
| Entity-key collision w/ retail | Transform keys of 2/6/13/18 ∩ retail `layers_static`(62k)+`vz_mar_roads` | **0** collisions → ruled OUT |

### The bug

The `schm` (component schema) body is `u32 n_fields`, `u32 payload_stride`, then
`n_fields × {u32 type_code, u32 name_hash, u32 unk, offset_word}`. Both converters
swapped the whole body as a flat `u32` array. But the 4-byte **offset_word** is
`{ u16 byte_offset; u8 a; u8 b }` — the trailing two bytes are endian-neutral u8
fields (bit index / size). A full `u32` swap moves `byte_offset` into the **high**
16 bits; retail PC stores it in the **low** 16 bits.

Evidence (raw `offset` words; `byte_offset = value >> 16` only for our buggy output):

```
RoadIntersection field offsets (byte 4,8,12,...):
  retail vz_mar_roads : 0x0004, 0x0008, 0x000c, ... 0x0078      (byte_offset in LOW 16)
  our converted blk18 : 0x40000, 0x80000, 0xc0000, ... 0x780000 (byte_offset in HIGH 16 = N<<16)
```

### Derivation from BE source (no guessing)

Extracted the **BE** block 18 from the DLC RAR (`dlc_port --x360-rar … --start-block 18
--dump-dir`). Probed the BE offset words and tested candidate byte permutations
against retail:

| Candidate (BE bytes `[b0,b1,b2,b3]` →) | vs `vz_mar_roads` | vs `layers_static` |
|----------------------------------------|-------------------|--------------------|
| `full_u32_swap` `[b3,b2,b1,b0]` (CURRENT/BUGGY) | 6/47 | 2/12 |
| **`swap_first_u16` `[b1,b0,b2,b3]`** (FIX) | **47/47** | **12/12** |
| `swap_both_u16` `[b1,b0,b3,b2]` | 38/47 | 4/12 |

`scan_schm_type_codes`/`ComponentSchema::from_schm_body` read `byte_offset =
raw_be >> 16`, which is correct for the **BE source** (high bits = first on-disk
bytes), so the schema-driven **data** swap is unaffected — only the schm-header
output bytes were wrong.

### The fix (verified, parity)

- `tools/ucfx_be_to_le.py::_convert_schm_body` — structured swap (header u32s,
  per-field type/name/unk u32s, offset_word swap-first-u16).
- `tools/wad_simulator/crates/ucfx_byteswap/src/convert.rs::swap_schm_body_inplace`
  — same logic; replaces `swap_u32_array` at the schm-body call site.
- Re-converted blocks 18 & 13: schm offsets now **identical** to retail
  (47/47 / 12/12). Python and Rust outputs agree (48/48).

### Important caveat (is it THE crash?)

The bug is present in **every** converted DLC block, including **safe** block 6
(boots fully). So the schm half-swap is a **confirmed real conversion defect** but
is **not, by itself, the crash differentiator**. Leading theory: the engine reads
schm offsets at runtime to extract positions for **non-Transform** spatial entities
(Transform is hardcoded to stride 42), so the corrupted offset only turns fatal in
blocks that register such an entity with out-of-grid coordinates. **Game-test of the
spliced fixed WADs is required to confirm** whether the fix clears `0x248BB*`. If it
does not, the remaining differentiator is a record **value** read via these offsets
— pursue with the live x32dbg capture (§Phase 2 recipe) and the PC-EXE Ghidra decomp
(§Phase 5).

### Reusable tooling added

- `tools/splice_block_into_patch.py` — re-compress + splice one decompressed LE
  block into an existing patch WAD (no full rebuild). Used to make the fixed test
  WADs above; preserves all other blocks/ASET/PTHS and passes `validate_patch_wad`.
- Analysis helpers (kept for reproducibility): `tools/_p3_schm_halfswap_check.py`,
  `tools/_p4_derive_swap.py`, `tools/_p3_key_overlap.py`.

### To game-test (manual)

```powershell
# back up current deploy, then drop in a fixed test WAD
Copy-Item "C:\Users\Shadow\Desktop\Mercenaries 2 World in Flames\data\vz-patch.wad" `
          "C:\Users\Shadow\Desktop\Mercenaries 2 World in Flames\data\vz-patch.wad.bak-buggy"
Copy-Item "output\data\vz-patch-block18-fixed.wad" `
          "C:\Users\Shadow\Desktop\Mercenaries 2 World in Flames\data\vz-patch.wad" -Force
# launch; watch scripts\dlc_enable_crash_*.log — expect NO FATAL @ 0x0248BB7C
```

## 2026-06-01b — Static decomp of the full spatial-register READ path (no debugger)

**Method:** the live x32dbg MCP bridge was down (`127.0.0.1:8888` refused), so the
read path was reconstructed **statically** from the cracked retail EXE
(`Mercenaries2.exe`, 53,482,288 B) with `tools/disasm_func.py` (capstone x86-32,
PE-section VA→offset map). All addresses below are confirmed against the on-disk
bytes, not runtime guesses.

### Section map surprise — the insert lives in `.securom`

| Section | VA range | Note |
|---------|----------|------|
| `.text` | `0x00401000`–`0x00B05000` | real engine code (cell-compute, accessors, register entry) |
| `.securom` | `0x023E9000`–`0x03700000` | **`0x0248BB60` bucket-insert is here** |

`0x00517DC0` is a thunk `jmp dword [0x0245A0F8]` (= `0x024E8F60`), i.e. the
"spatial hash insert" is an engine routine **relocated into the SecuROM section**
and reached via an IAT-style indirect jump. This explains its odd `0x0248B***`
VA and the off-heap `ESI`/`nvgpucomp32.dll` fault addresses (neighbouring SecuROM
data). It is **not** itself the corruption source.

### Confirmed call chain (all generic, shared with the 62k base placements)

```
register site 0x0051637F / 0x00518290
  → 0x00516C00  SpatialGridRegister(rec*, posbuf*, lod, flags)
      → 0x00515F60  GetEntityWorldPos(entity -> out vec3)
          → 0x00434F10 → 0x00434F80  DecomposeEntityTransform
      → 0x00516B10  WorldPosToCellIndex(vec3* in ECX -> cell)
      → 0x00517DC0 thunk → 0x0248BB60  bucket insert (.securom)
```

- **`0x00516B10`** reads the position straight from `[ECX+0]=X`, `[ECX+4]=Y`,
  `[ECX+8]=Z` and computes
  `cell = ((int)(Z-originZ) >> shift) * grid_width + ((int)(X-originX) >> shift)`
  (grid globals `0x0179C7B4/B6/BC/C4`). **No clamp on the final linear index** —
  a NaN/huge X or Z makes `cvttss2si → 0x80000000` and the cell index goes wild,
  exactly the documented fault.
- **`0x0248BB60`** matches the prior pseudocode byte-for-byte:
  `bucket = [0x01175DD8] + cell*0x1F0` (no bounds check), `cmp [bucket+0x1E4],0x20`
  (read crash `0x248BB7C`), `mov [bucket+count*4],val` (write crash `0x248BBE2`).

### NEW: runtime entity transform layout (from `0x00434F80`)

`0x00434F80` reads the entity's inline transform and decomposes it:

| Offset in entity | Type | Field |
|------------------|------|-------|
| `+0x00` | f32 | position **X** |
| `+0x04` | f32 | position **Y** |
| `+0x08` | f32 | position **Z** |
| `+0x0C` | s16 | quat q0 |
| `+0x0E` | s16 | quat q1 |
| `+0x10` | s16 | quat q2 |
| `+0x12` | s16 | quat q3 |

The four quat shorts are `cvtsi2ss`'d and multiplied by `[0x00BEAD80] =
0x3803126F ≈ 1/32768` → the **runtime quaternion is fixed-point int16**, not the
float32 quat stored on disk (`+0x14..+0x20` in the 42-byte Transform COMP). The
ECS loader therefore **compresses float→int16** while building the entity. (This
is the first time the in-memory transform record has been documented.)

### What this proves / narrows

- The spatial-hash path is **correct, generic code**; it services all 62k
  `layers_static` placements without issue. The bug is **not** in the hash, the
  cell math, the accessor, or the SecuROM relocation.
- The fault is a **runtime entity whose first 12 bytes (pos) are garbage**, fed
  into a bounds-check-free cell index. On-disk Transform bytes for blocks 6/13/18
  are clean (proven earlier), so corruption enters during **entity construction**
  (the ECS Transform-apply that fills `entity+0..+0x12`), not in the read path.
- This strengthens **H1** (runtime entity assembly) and effectively rules out the
  spatial code itself as a suspect.

### Sharper live-capture recipe (supersedes the insert-site breakpoints)

Break at the **source** of the bad position, not at the `.securom` insert:

1. `bp 0x00515F60` — on hit, `EAX` = entity ptr. Dump `[EAX+0..+0x12]`:
   `[+0/+4/+8]` as f32 (position), `[+0xC/+0xE/+0x10/+0x12]` as s16 (quat).
   A sane Maracaibo entity reads metres ~(−0.2, 831, 0); the toxic one shows
   NaN/huge floats **before** any cell math runs.
2. With the entity ptr, walk back one frame (`GetCallStack`) into the per-entity
   registration loop to recover the COMP source / entity type — block 18 is
   Road/RoadIntersection/DestructionLink-heavy, block 13 Anchor/AiBehavior-heavy,
   so confirm whether the toxic entity is a non-Transform component being
   registered with an uninitialised inline transform.
3. Tooling: `tools/disasm_func.py --exe <Mercenaries2.exe> --va <addr> --until-ret`
   for any further static step; `--xrefs <addr>` to find callers.

**Open next step (root cause):** find the ECS entity-construction loop that writes
`entity+0..+0x12` from a layer block's COMP set, and check whether
Road/RoadIntersection/Anchor entities in 13/18 get a Transform applied at all. This
is the remaining unknown; a single live break at `0x00515F60` would identify the
toxic entity type immediately.

## 2026-05-30c — Break-the-deadlock toolkit

| Tool | Purpose |
|------|---------|
| `tools/scan_patch_placements.py` | Rank every patch block: Transform/flgs NaN/Inf, \|coord\|>5000, BE-looking floats |
| `tools/bisect_patch_wad.py` | Print test matrix + `trim_patch_wad.py` commands (4a, 4e, half-split, top-5 exclude) |
| `make scan-patch-placements` | Run scan; `--fail-on-violations` exits 1 |
| `make bisect-patch-wad` | Bisect command sheet |
| `dlc_port` default | **Python** byteswap for **ASET type_id 9 (layer)** blocks **or** paths matching `dlc01_base` / `speedcity` / `dlccon` (`--no-byteswap-python-ecs-paths` to disable) |
| `dlc_port --fail-on-placement-violations` | Post-port gate (optional; off by default) |

```powershell
make scan-patch-placements OUTPUT=./output
make bisect-patch-wad OUTPUT=./output
.venv\Scripts\python.exe tools\audit_ecs_byteswap_parity.py --be-block path\to\xbox.block.bin
```

### 2026-05-30 — Offline gate on current deploy (`8700856a…`)

**SHA256:** `8700856a4eb77bb1ca1a7f18ae3586b4519e0d01a95bb8b8a12d05197a141ff0` (**new** — not `97242b0a…`, `1E6CA26C…`, or `46e84924…`). **2196** blocks; last index **2195** = `scripts_vz` (no separate bootstrap block at 2196).

| Gate | Result |
|------|--------|
| `scan_patch_placements` | **0** violations across 2196 blocks (7927 Transform records in 15 layer blocks; **0** flgs records) |
| `wad_simulator` + `pc-game-vz.wad` | **0** `position_violations` (109226 placements checked); 8 XMA codec warnings only |
| Prior `1E6CA26C…` sim | 22 terrain lattice hits in block 0 — **gone** on this build |

**Verdict:** Placement float / endian corruption **not** implicated on this WAD. Runtime bisect (2026-05-30d, below) implicates **arena placement layers**, not bootstrap @ 2195 or `dlc01_base`+`commonlocations` alone.

### 2026-05-30d — Runtime bisect logs (SHA `8700856a…`, user retail)

Retail PC + `dlc_enable.asi` (bootstrap **OFF**, `CRASH_PATCH=1`, `REG_PATCH=1`, `GUARD=1`, `WATCHDOG=1`). Logs under game `scripts\dlc_enable_crash_*.log`. All patch trims **carry forward** step 1–2 exclusions `0,4,12,15,16,17` unless noted.

| Log / trim | Crash? | FATAL (EIP / fault) | Last Lua before fault | Timing (post–Shell-exited) |
|------------|--------|---------------------|------------------------|----------------------------|
| **`clean_no_patch`** (no `vz-patch.wad`) | **N** | *(none)* | `[lua] Loading vz level with vz masterscript` then full boot (`Shop`, `creating player`, `New operation (170 layers)`, … `GlobalExit - Complete`) | VZ line ~**4.7 s**; session runs **60+ s** |
| **`no_bootstrap`** (`--exclude-indices …,2195`) | **Y** | `0x0248BB7C` / `0x03CEA074` (read) | `[lua] Loading vz level with vz masterscript` | VZ ~**4.4 s** → FATAL ~**5.8 s** |
| **`no_base`** (`--exclude-indices …,3,5`) | **Y** | `0x0248BBE2` / `0x03CEA014` (write) | same | VZ ~**4.3 s** → FATAL ~**5.7 s** |
| **`no_speed_city`** (exclude `speedcity` path) | **Y** | `0x0248BBE2` / `0x03CEA014` | same | VZ ~**4.2 s** → FATAL ~**4.3 s** (fastest repro) |
| **`no_arena`** (`dlc01_base,speedcity,dlccon` paths) | **N** @ spatial hash | *(none @ `0x248BB*` in 30 s window)*; late `0x00874E7D` / `0xF011157A` after watchdog timeout | `[lua] Loading vz level with vz masterscript` only (no Shop/players) | VZ ~**4.2 s**; watchdog **30 s** “no crash detected” then unrelated FATAL |

**Interpretation (IN vs OUT):**

| Ruled **OUT** as sole trigger | Evidence |
|-------------------------------|----------|
| Patch absent | `clean_no_patch` — full Venezuela boot |
| Terrain (0), all five `dlc01_state_*` (4,12,15,16,17) | Prior steps + carried on all trims |
| **`scripts_vz` @ index 2195** | `no_bootstrap` still spatial-hash crashes |
| **`dlc01_base` + `dlc01_commonlocations` only** (indices 3, 5) | `no_base` still crashes |
| **`dlc01_speedcity*` only** | `no_speed_city` still crashes |

| Ruled **IN** (culprit pool) | Evidence |
|-----------------------------|----------|
| **At least one arena layer block** among `dlc01_base`, `dlc01_speedcity*`, `dlc01_dlccon*` | `no_arena` passes spatial-hash window; all narrower trims still fail |
| **Not a single-block cut** | Removing only base+commonlocations **or** only speedcity is insufficient — likely **`dlccon*`** and/or **combination** of arena layers |

**Narrowed set:** High-Transform **`dlccon*`** blocks (e.g. indices **2**, **6**, **7**, **8**, **13**, **14**, **18** on prior inventory) plus **`dlc01_base`** / **`speedcity`** when other arena blocks remain loaded. Bootstrap and offline placement scan are **deprioritized**.

**`no_arena` late FATAL:** Different EIP/fault — treat as **secondary** (hang/incomplete VZ without arena geometry, or post-timeout exit); not the documented `0x248BB60` spatial-hash insert.

### TOP 5 suspect blocks (evidence-ranked, pre-scan on SHA `97242b0a…`)

**Run `make scan-patch-placements` on your machine** — ranks may reorder. Until then, use Transform load + bisect priority (step 2 already ruled out state overlays):

| Rank | Index | Path (typical) | Evidence |
|------|-------|----------------|----------|
| **1** | **3** | `dlc01_base_P000_Q3` | **422** Transform records; arena **layers_static** analogue; **not** in step-2 exclusions; simulator 0 flgs hits on prior build but highest “world entity” risk |
| **2** | **8** | `dlc01_speedcity_P000_Q3` | **1736** Transforms — largest layer block; path now on **Python byteswap** default |
| **3** | **2** | `dlc01_dlccon004_P000_Q3` | **1482** Transforms; user port note **dlccon004a missing** — contract arena; path `dlccon` → Python default |
| **4** | **5** | `dlc01_commonlocations_P000_Q3` | **10** Transforms but sparse **placement-critical** refs; step **4e** target with index 3 |
| **5** | **13** | `dlc01_dlccon002_race_P000_Q3` | **836** Transforms; high registration load if 4e passes |

**Ruled out (user bisect):** 0 terrain, 4/12/15/16/17 all `dlc01_state_*`. **Not ruled out:** bootstrap **2196** (`scripts_vz`), ~2100 `c3` cells (low direct Transform count), **resident** SKIPPED at port.

### Next trims (after 2026-05-30d bisect — copy/paste)

```powershell
cd C:\Users\Shadow\Desktop\notes-on-the-released-game
$RULED = "0,4,12,15,16,17"

# A — dlccon only (keep base + speedcity): PASS => culprit in dlccon*
.venv\Scripts\python.exe tools\trim_patch_wad.py -i output/data/vz-patch.wad -o output/data/vz-patch-no-dlccon.wad --exclude-indices $RULED --exclude-path-substr dlccon -v

# B — base only (keep speedcity + dlccon): PASS => dlc01_base layer
.venv\Scripts\python.exe tools\trim_patch_wad.py -i output/data/vz-patch.wad -o output/data/vz-patch-no-base-only.wad --exclude-indices $RULED --exclude-path-substr dlc01_base -v

# C — largest dlccon layer alone (index 2 on 8700856a inventory; re-list after port)
.venv\Scripts\python.exe tools\trim_patch_wad.py -i output/data/vz-patch.wad -o output/data/vz-patch-only-full.wad --keep-only-indices "2" --exclude-indices $RULED -v
# Deploy each as data\vz-patch.wad — expect FAIL on C if block 2 is toxic
```

Prior **4a / 4e / no_arena** results are in the table above; do not re-run unless WAD SHA changes.

### 2026-05-30e — Trim WAD bisect (SHA `8700856a…`, built trims deployed as `data\vz-patch.wad`)

Logs: `Mercenaries 2 World in Flames\scripts\dlc_enable_crash_*.log`. All trims carry step 1–2 exclusions `0,4,12,15,16,17`.

| Log | Deployed WAD | Crash? | FATAL (EIP / fault) | Last Lua before fault / at timeout | vs `clean_no_patch` |
|-----|--------------|--------|---------------------|-------------------------------------|------------------------|
| **`no-base-only`** | `vz-patch-no-base-only.wad` | **Y** | `0x0248BB7C` / `0x03CEA074` (read) | `[lua] Loading vz level with vz masterscript` | No Shop / players / GlobalExit |
| **`no-bootstrap`** | `vz-patch-no-bootstrap.wad` | **Y** | `0x0248BBE2` / `0x03CEA014` (write) | same | same |
| **`no-dlccon`** | `vz-patch-no-dlccon.wad` | **N** @ `0x248BB*` | *(none in 30 s)* | `Loading vz` only; watchdog **30 s** timeout, **no** post-timeout FATAL | Hangs at VZ (no Shop in window); **no** spatial-hash AV |
| **`dlccon_only`** | `vz-patch-dlccon004-only.wad` (1 block) | **N** | *(none)* | `Loading vz` → **Shop**, **creating player 0/1**, **`GlobalExit - Complete`** (after 30 s watchdog) | **Passes** spatial-hash window **and** full Lua boot milestones |
| **`no_arena`** | `vz-patch-no-arena.wad` | **N** @ `0x248BB*` | `0x00874E7D` / `0xF011157A` **after** 30 s timeout | `Loading vz` only; watchdog timeout then secondary FATAL | Same hang as `no-dlccon` in window; **extra** late crash on teardown |
| **`no-dlccon004`** | `vz-patch-no-dlccon004.wad` (`--exclude-indices $RULED,2`) | **Y** | `0x0248BBE2` / `0x03CEA014` (write) | `Loading vz` only (~**+4.2 s** post-Shell); no Shop / players / GlobalExit | **004 not required** for crash — siblings + base/speedcity still fault |
| **`no-dlccon-roads`** | `vz-patch-no-dlccon-roads.wad` (exclude `dlccon002`, `dlccon004_roads`, `dlccon002_race`; **keep** `dlccon004`) | **N** @ `0x248BB*` | *(none in 30 s)* | `Loading vz` only; watchdog **30 s** timeout | Same hang as `no-dlccon`; **roads/race/002 paths required** for spatial-hash AV |

**Prior logs (2026-05-30d, same SHA):** `clean_no_patch` **N** (full boot); `no_bootstrap` **Y** `0x248BB7C`; `no_base` **Y** `0x248BBE2`; `no_speed_city` **Y** `0x248BBE2`; `no_arena` **N** @ spatial hash (+ late `0x00874E7D`).

**Timing (post–Shell-exited):** `no-base-only` / `no-bootstrap` / **`no-dlccon004`** FATAL ~**4.2–5.0 s** after Shell-exited (~**4.1–4.2 s** to `Loading vz`, then ~**0.1 s** to FATAL for `no-dlccon004`). `no-dlccon` / `no_arena` / **`no-dlccon-roads`** / `dlccon_only` reach VZ ~**4.3–4.7 s**; spatial-hash-pass trims timeout at **30 s** or (`dlccon_only`) continue to Shop ~**6.4 s**.

### 2026-05-30f — `no-dlccon004` / `no-dlccon-roads` (same SHA `8700856a…`)

Logs: `Mercenaries 2 World in Flames\scripts\dlc_enable_crash-no-dlccon004.log`, `dlc_enable_crash-no-dlccon-roads.log`. ASI flags match 30e (`CRASH_PATCH=1`, `WATCHDOG=1`, `BOOTSTRAP=0`).

#### Verdict (2026-05-30f)

| Question | Answer |
|----------|--------|
| Which **`dlccon` sibling causes spatial-hash AV?** | **`dlccon002` / `dlccon002_race` / `dlccon004_roads`** path family (PTHS indices **6**, **13**, **18** on this WAD). **`no-dlccon-roads`** drops them and **passes** the `0x248BB*` window; **`no-dlccon004`** drops only index **2** and **still crashes** (`0x0248BBE2`). |
| Is **`dlccon004` (index 2) the toxic block?** | **No** — ruled out as sole cause (30e `dlccon_only`) and **not required** for crash (30f `no-dlccon004`). |
| **`no-dlccon-roads` vs `no-dlccon`?** | **Same** outcome: VZ hang, **no** `0x248BB*`, **no** Shop/players/GlobalExit in 30 s, clean watchdog timeout (**no** late `0x00874E7D`). Keeping **004** without roads/race/002 does not recover full boot. |

**Logic (30e + 30f):**

| Configuration | Spatial-hash AV | Boot past VZ |
|---------------|-----------------|--------------|
| `dlccon004` only (index **2**) | **N** | **Y** (Shop, players, GlobalExit) |
| Full patch − all `dlccon*` | **N** | **N** (hang) |
| Full patch − **002 / roads / race** paths, keep **004** | **N** | **N** (hang) |
| Full patch − **004** only, keep **002 / roads / race** | **Y** | **N** |

#### Next trims (2026-05-30f)

```powershell
cd C:\Users\Shadow\Desktop\notes-on-the-released-game
$RULED = "0,4,12,15,16,17"

# 1 — Minimal benign control (expect hang or full boot; must NOT 0x248BB*)
.venv\Scripts\python.exe tools\trim_patch_wad.py -i output/data/vz-patch.wad -o output/data/vz-patch-base-dlccon004-only.wad --keep-only-indices "2,3,2195" --exclude-indices $RULED -v

# 2 — Single suspect + base + speedcity (run one index at a time; expect Y if sufficient)
.venv\Scripts\python.exe tools/trim_patch_wad.py -i output/data/vz-patch.wad -o output/data/vz-patch-keep-dlccon-6.wad --keep-only-indices "6,3,8" --exclude-indices $RULED -v
# Repeat with --keep-only-indices "13,3,8" and "18,3,8"; confirm index 8 = speedcity via trim_patch_wad.py --list

# 3 — Exclude one roads/race block at a time (narrow which of 6/13/18 is necessary)
.venv\Scripts\python.exe tools/trim_patch_wad.py -i output/data/vz-patch.wad -o output/data/vz-patch-no-dlccon002-roads.wad --exclude-indices $RULED --exclude-path-substr dlccon002_roads -v
.venv\Scripts\python.exe tools/trim_patch_wad.py -i output/data/vz-patch.wad -o output/data/vz-patch-no-dlccon002-race.wad --exclude-indices $RULED --exclude-path-substr dlccon002_race -v
.venv\Scripts\python.exe tools/trim_patch_wad.py -i output/data/vz-patch.wad -o output/data/vz-patch-no-dlccon004-roads-only.wad --exclude-indices $RULED --exclude-path-substr dlccon004_roads -v
```

Deploy each as `data\vz-patch.wad`. **Fix target** when single-block trim identified: `extract_single_block.py` on that index + `scan_patch_placements.py` / `verify_ucfx_endian.py` on decompressed UCFX.

#### Verdict (2026-05-30e)

| Question | Answer |
|----------|--------|
| Is **`dlccon` the sole bucket?** | **No.** `dlccon*` is **necessary** (`no-dlccon` passes spatial-hash window) but **not sufficient**: `dlccon004`-only WAD boots cleanly. **`dlc01_base` / `speedcity` alone** are also insufficient (`no-base-only`, `no_speed_city` still crash). Minimum hypothesis: **`dlccon` (non-004 blocks) + at least one of `dlc01_base` / `speedcity`**. |
| Does **`dlccon004` alone crash?** | **No** (`dlccon_only`); **not required** for AV (**30f** `no-dlccon004` still **Y**). |
| **`no-dlccon` vs `no_arena`?** | **Same** in the 30 s window. **Different** after timeout: `no_arena` → **`0x00874E7D`**; `no-dlccon` / **`no-dlccon-roads`** → clean timeout. |

**Ruled OUT:** `dlc01_dlccon004` (index **2**); bootstrap @ **2195**; offline float scan. **30f:** `no-dlccon004` **Y**, `no-dlccon-roads` **N** @ `0x248BB*`.

**Ruled IN:** indices **13** / **18** (`dlccon002_race`, `dlccon004_roads`) — independently sufficient for `0x248BB*` with base+speedcity (**§2026-05-30g**). Index **6** (`dlccon002_roads`) ruled **OUT** as sole cause.

### 2026-05-30g — Per-block keep-only + single-path excludes (SHA `8700856a…`)

Logs: `Mercenaries 2 World in Flames\scripts\dlc_enable_crash-{no-dlccon002-roads,no-dlccon002-race,no-dlccon004-roads,no-dlccon004-block,base-dlccon004-bootstrap,keep-dlccon002-only,keep-dlccon002-race-only,keep-dlccon004-roads-only}.log`. All trims retain step 1–2 exclusions `0,4,12,15,16,17`. ASI: `CRASH_PATCH=1`, `WATCHDOG=1`, `BOOTSTRAP=0`.

#### Result matrix

| WAD / test | Idx | Path | `0x248BB*`? | FATAL (EIP / fault) | Progress (Lua milestones) | Verdict |
|------------|-----|------|-------------|---------------------|---------------------------|---------|
| **`no-dlccon002-roads`** | drop **6** | `dlccon002_roads` | **Y** | `0x0248BB7C` / `0xAA1B29D4` (~**5.5 s**) | `Loading vz` only | **Not sufficient** to clear AV — **13+18** still crash |
| **`no-dlccon002-race`** | drop **13** | `dlccon002_race` | **Y** | `0x0248BBE2` / `0x03CEA014` (~**5.5 s**) | `Loading vz` only | **Not sufficient** — **6+18** still crash |
| **`no-dlccon004-roads`** | drop **18** | `dlccon004_roads` | **N** | *(none in 30 s)* | `Loading vz` only; watchdog **30 s** timeout | **Sufficient** to clear spatial-hash AV (VZ hang, no Shop) |
| **`no-dlccon004-block`** | drop **2** | `dlccon004` mesh | **Y** | `0x0248BB7C` / `0x03CEA074` (~**5.5 s**) | `Loading vz` only | Confirms index **2** not fix target |
| **`keep-dlccon002-only`** | **6** only + base + speedcity | `dlccon002_roads` | **N** | *(none)* | Shop → players → **`GlobalExit - Complete`** (~**30 s+**) | **Ruled OUT** — benign alone |
| **`keep-dlccon002-race-only`** | **13** only + base + speedcity | `dlccon002_race` | **Y** | `0x0248BB7C` / `0x9F84E174` (~**30 s+**, post-watchdog) | Shop → GlobalExit flow → **`CreatePlayerCharacter`** → layer stream → FATAL | **Sufficient alone** |
| **`keep-dlccon004-roads-only`** | **18** only in patch WAD (**1** block; retail supplies all `vz_*` layers) | `dlccon004_roads` | **Y** | `0x0248BB7C` / `0x6F319F84` (~**30 s+**, post-watchdog) | Shop → players → **170+238** layer stream → FATAL after `vz_state_pmc` request | **Sufficient alone** — **confirmed log 2026-05-31** |
| **`base-dlccon004-bootstrap`** | **2** + **3** + **2195** | `dlccon004` + base + bootstrap | **N** @ `0x248BB*` | `0x00874E7D` / `0xF011157A` (**after** 30 s timeout) | `Loading vz` only; watchdog timeout then **secondary** teardown AV | Hang path (same class as `no_arena`); not spatial-hash bucket |

#### Verdict (2026-05-30g)

| Question | Answer |
|----------|--------|
| Which **keep-only** (6 / 13 / 18) reproduces crash **alone**? | **13** and **18** — both hit `0x0248BB*` with a **1-block patch WAD** (+ retail `vz.wad` for world layers). **6 alone → full boot** (Shop, players, GlobalExit). **18** confirmed: SHA `6809da8e…`, log `dlc_enable_crash-keep-dlccon004-roads-only.log`. |
| Which **single path-exclude** clears `0x248BB*` from full patch? | **`no-dlccon004-roads`** only (drop index **18**). Excluding **002_roads** or **002_race** alone is **not** enough. |
| **Minimal toxic set** for full-patch spatial-hash AV? | **Index 18** (`dlccon004_roads`) is **necessary** — full patch minus **18** passes. Pair **{13, 18}** is the active duo when all three roads/race blocks present; **{6, 13}** without **18** is benign (see `no-dlccon004-roads`). |
| **Primary fix target?** | **Index 18** — `dlc01_dlccon004_roads_P000_Q3` (734 Transform records). Secondary audit: **index 13** (`dlccon002_race`, 836 records) also independently toxic. |
| **`base-dlccon004-bootstrap`?** | Control only — no `0x248BB*`; late `0x00874E7D` after hang (missing speedcity / roads content for full VZ). |

#### Byte analysis (2026-05-30g follow-up)

Extracted decompressed blocks **2 / 6 / 13 / 18** from `output/data/vz-patch.wad` and ran `scan_patch_placements.py`, `placement_scan_lib` (world envelope on), Road/RoadIntersection payload decode, and COMP inventory walks. Artifacts: `output/_scratch/byte_analysis/`.

| Idx | Path | Transforms | Violations | COMP mix (notable) | XYZ range (game m) |
|-----|------|------------|------------|--------------------|--------------------|
| **2** (safe) | `dlccon004` mesh | 1482 | **0** | LightObject 82, AtmosphereBase 5 — **no Road** | X −1700..100, Y −27..54, Z 487..1426 |
| **6** (safe alone) | `dlccon002_roads` | 596 | **0** | Road 10, RoadIntersection 12, ScrubObject 19 | X −1479..1500, Y 0..128, Z −1600..651 |
| **13** (crash alone) | `dlccon002_race` | 836 | **0** | AiBehavior 96, Anchor 115 — **no Road** | X 100..1304, Y −64..156, Z −1500..500 |
| **18** (crash; necessary) | `dlccon004_roads` | 734 | **0** | Road **75**, RoadIntersection **58**, DestructionLink **32** | X −1700..100, Y −35..24, Z 490..1384 |

**What we can prove from bytes**

- **Transform COMP `data` is clean in all four blocks** — 0 NaN/Inf, 0 `|coord|>5000`, 0 world-envelope violations, 42-byte stride with 0 remainder, no duplicate entity keys.
- **Safe block 6 and crash block 18 both have Road + RoadIntersection** with `schm` strides 44 / 128 and 0 byte remainder; Road endpoint Vec3s decode to finite in-bounds coords. Road `ref_key` u32s often point outside the block's Transform key set on **both** 6 and 18 (cross-block graph refs — not 18-specific corruption).
- **False lead ruled out:** scanning u32 fields inside RoadIntersection headers (offset +28 in the 128-byte record) as floats shows huge LE values — those are **entity-ref u32s**, not Vec3 positions. All six intersection Vec3 payloads (offset +28 in the 124-byte payload) are finite and in bounds on 6 and 18.
- **Block 13 crash path is not Road-related** — toxic bytes, if any, would be in AiBehavior / Anchor / race Transform load, not shared with 18.
- **No Xbox BE source** in repo for `audit_ecs_byteswap_parity` on these blocks; parity audit deferred until DOH/decompressed BE `.block.bin` is available.

### 2026-05-31 — Repeat hit (`keep-dlccon004-roads-only`)

#### Confirmed deployment + log (user retail, PID 11312)

| Field | Value |
|-------|--------|
| **Deployed WAD** | `output\data\vz-patch-keep-dlccon004-roads-only.wad` → game `data\vz-patch.wad` |
| **SHA256** | `6809da8ed45fdae5b8a18f4ba7aa7ca3d1f2895af9e13301b8bd6fe6b77460a9` (user **confirmed** match) |
| **Patch contents** | **1** FFCS block — index **18** `blocks\dlc01\dlc01_dlccon004_roads_P000_Q3.block` only (`trim_patch_wad.py --keep-only-indices 18`) |
| **Log file** | `Mercenaries 2 World in Flames\scripts\dlc_enable_crash-keep-dlccon004-roads-only.log` |
| **Do not confuse with** | `vz-patch-dlccon004-only.wad` (index **2** mesh) — that WAD **full-boots** |

**Timeline (ms after Shell-exited):**

| Time | Event |
|------|--------|
| ~**4406** | `[lua] Loading vz level with vz masterscript` — **no** immediate `0x248BB*` (unlike full patch ~5 s) |
| ~**5844** | `[lua] Shop - Generating Global ShopList…` |
| ~**5844–5891** | `[lua] creating player 0` / `1` |
| ~**8719–16703** | `New operation (170 layers)` + retail `vz_*` layer requests |
| ~**17219–29969** | Second op: **238** `vz_state_*` layer requests |
| ~**30016** | `Watchdog: timeout 30000 ms — no crash detected in window` |
| ~**30016+** | Layer stream **continues** (`vz_state_pmc`, …) |
| **End** | `FATAL: 0xC0000005 at 0x0248BB7C fault=0x6F319F84` |

**Interpretation:** The **30 s watchdog “no crash” line is not a pass** — the session kept running, finished most layer registration, then hit the same spatial-hash **read** fault. Crash is **delayed** (~30 s after shell) because only **block 18** is in the patch and registration happens during **heavy `vz_state` / layer streaming**, not at the first `Loading vz…` line.

**vs full patch:** Full `8700856a…` WAD still tends to AV ~**5–6 s** at VZ load (arena blocks **6/8/13/18** + base + speedcity together). **Roads-only** repro isolates **index 18** as **necessary and sufficient** for the bug class without shipping the whole DLC.

#### Known pass / fail fixtures (trim WADs)

| WAD file | Blocks | SHA256 (prefix) | Spatial `0x248BB*` | Full boot (Shop + players + no FATAL) |
|----------|--------|-----------------|---------------------|----------------------------------------|
| *(none)* | 0 | — | **N** | **Y** (`clean_no_patch`) |
| `vz-patch-dlccon004-only.wad` | 1 (idx **2**) | `786ae23b…` | **N** | **Y** |
| `vz-patch-keep-dlccon002-only.wad` | 1 (idx **6**) | `418bf0aa…` | **N** | **Y** |
| **`vz-patch-keep-dlccon004-roads-only.wad`** | **1 (idx 18)** | **`6809da8e…`** | **Y** (~30 s, this log) | **N** |
| `vz-patch-no-dlccon004-roads.wad` | 2189 | `3ab33fd6…` | **N** | **N** (VZ hang) |
| Full `vz-patch.wad` | 2196 | `8700856a…` | **Y** (~5 s) | **N** |

Full table: `output\data\trim_wad_manifest.txt`.

#### Live x32dbg (two sessions, same WAD class)

**Session A — write site (`0x248BBE2`):**

**Session B — read site (`0x248BB7C`, matches confirmed log `fault=0x6F319F84`):**

| Reg | Session A | Session B |
|-----|-----------|-----------|
| **EIP** | `0x0248BBE2` | `0x0248BB7C` |
| **EBX** | `0x20E33074` | `0x20DB6B2C` |
| **[EBX+4]** | `0x8E290015` class | `0x8E290015` (`15 00 29 8E`) |
| **[EBX+8]** | `0x4E093685` (~5×10⁸) | `0x4E01BCEC` (~10⁹) |
| **ECX** | `0xFFFF8BDB` (negative index) | **`0x038E2840`** (doc classic) |
| **ESI** | `0x6F319DA0` | `0x03CE9E90` |
| **Fault** | write `[esi+ecx*4]` | read `[esi+0x1E4]` → **`0x6F319F84`** |

**Benign hit (same function):** `ECX=0x20F` (527), EBX `0x20D496C8`, XYZ ~(1312, 0, …) — conditional `ecx>0x4000` should **not** stop here.

**Live registers (toxic hit, session A summary):**

| Reg | Value | Notes |
|-----|-------|-------|
| **EBX** | `0x20E33074` | Entity / registration object base |
| **[EBX+8]** | `0x4E093685` | **Not** a sane world Y (as float ≈ `5.76×10⁸`) |
| **ECX** | `0xFFFF8BDB` | Slot index **−29765** → bucket write AV |
| **ESI** | `0x6F319DA0` | Hash bucket base |
| **EAX** | `0x356B` | Also appears inside block **18** Transform blob (coincidence) |

**Block 18 disk pass** (`output/_scratch/byte_analysis/block_00018/…block.bin`, tool `tools/_scan_block18_road_toxic.py`):

| Check | Result |
|-------|--------|
| `0x4E093685` in Road / RoadIntersection **payload** fields | **0** hits |
| Road / intersection **Vec3** endpoints with \|float\| > 1e6 | **0** |
| Road `data` stride (schm payload 40 → record **44**) | **75** records, **0** remainder |
| Transform quats (offsets **+0x14..+0x20**, doc layout) | **734 / 734** unit-length |
| Prior **733/734 “bad quat”** in `deep_compare.json` | **False lead** — scanner used wrong quat base (treated pad/+0x10 as `qx`); re-scan with `+0x14` is clean |

**Where `0x4E093685` appears on disk (once):** Transform record **209**, byte **+34** inside the 42-byte record (spans tail / adjacent record bytes — **not** `road_lane_hash_0` at Road payload **+0x08**).

**Road payload +8 ≡ runtime `[entity+8]`?**

- If the engine treated a **Road payload** pointer as a Transform entity, `[entity+8]` would be **`road_lane_hash_0`** (u32 at payload **+0x08** per `decode_road_payload` / `docs/ecs_components.md`).
- **No** Road record in block **18** stores `0x4E093685` at that offset → **not explained by mis-swapped Road hashes on disk**.
- **Matches instead:** `[entity+8]` with entity base **`Transform_record + 26`** (22 bytes into the 38-byte payload after the u32 key). Example: record **209** key `0x00155E12` has sane **Y** at **`+0x08`** (`−15.5` m) but **`[base+26+8]` → `+0x34`** = `0x4E093685`.

**Byteswap verdict (Road / RoadIntersection):**

- `decode_road_payload` / `decode_road_intersection_payload` layouts match `convert.rs` / `ucfx_be_to_le.py`: stride **44** / **128**, numeric u32 sweep for schm-backed COMPs (`swap_numeric_records_inplace` when `is_ecs_numeric_component`).
- **No minimal `ucfx_byteswap` change for Road** justified on current LE block — typed per-field swap would be identical to the existing 44-byte record sweep.
- **Fix hypothesis:** engine-side **entity construction / spatial-hash registration** for layer blocks that load **Road** (block **18** has **75× Road**, **58× RoadIntersection** vs **10× / 12×** on benign block **6**); confirm with one x32dbg session: entity pointer at **`0x00516EF6`**, compare to Transform **`+4`** XYZ vs **`+26`** mis-base. Offline: `tools/correlate_entity_ptr.py` on decompressed block **18** (`output/_scratch/byte_analysis/`).

**Workaround (unchanged):** deploy full patch minus index **18** (`no-dlccon004-roads`) to clear `0x248BB*`.

**Example records (all sane on disk)**

| Block | Record | Entity key | Offset in Transform `data` | XYZ (LE float) | Raw +4..+0F |
|-------|--------|------------|----------------------------|----------------|-------------|
| **18** (median) | 367 | `0x00155606` (1400678) | `0x3DE6` | (−718.60, −26.23, 1040.15) | `BC 33 34 C4 72 3A D2 C1 83 68 82 44` |
| **6** (median) | 298 | `0x0014FE19` (1376473) | `0x1C04` | (478.95, 31.05, −1328.34) | — |
| **18** (first) | 0 | `0x00150626` (1377830) | `0x0000` | (−1520.89, −0.21, 831.35) | `26 06 15 00 C7 40 1F E3 44 2D 09 08` |

No record in 6 / 13 / 18 matches the x32dbg denormal pattern (`0x8E290015`) at Transform +4/+8/+0xC.

**What requires x32dbg at crash**

The spatial-hash insert reads **`[entity+4]` `[entity+8]` `[entity+0xC]`** from a **runtime entity struct**, not directly from the on-disk Transform COMP blob. With offline Transform bytes clean, the smoking gun must be captured live:

1. `bp 0x248BB6D` condition `ecx > 0x4000` on **`keep-dlccon004-roads-only`** or full patch.
2. At **`0x00516EF6`**, dump the entity pointer and floats at +4..+0xC.
3. If floats are garbage but disk Transform for that entity key is sane → **wrong in-memory layout / wrong component merged into entity**, not a bad LE port of Transform `data`.
4. Walk frame to **`0x0063DA1F`** to tie the entity key to the last-loaded block.

**Hypothesis ranking (post byte pass)**

| Rank | Mechanism | Evidence |
|------|-----------|----------|
| **H1** | **Runtime entity assembly** — engine builds searchable entity from Road / RoadIntersection / DestructionLink (18) or AiBehavior / Anchor (13) with a code path that writes or reads Transform at the wrong offset | On-disk Transform clean; crash blocks differ by **COMP mix**, not Transform float quality. 18 has **7.5×** more Road records than safe block 6 in a different arena half. |
| **H2** | **Multi-block interaction** — 18 is **necessary** in full patch (`no-dlccon004-roads` clears AV) but bytes in 18 alone are as clean as 6; failure may need base + speedcity + 004 roads registration order | Bisect 30g; no single bad Transform record explains necessity. |
| **H3** | **Stale / wrong entity pointer** in registration loop | Fits clean disk + dirty `[entity+4]` at crash; needs one x32dbg session. |
| **H4** | Transform COMP LE swap corruption | **Ruled out** for 6/13/18 (and safe **2**) by scan + manual record dumps. |
| **H5** | Misaligned 42-byte stride / every-Nth record garbage | **Ruled out** — `data_len % 42 == 0` on all four blocks. |
| **H6** | Road stride 44 vs 40 breaking adjacent Transform on disk | **Ruled out** — Road and Transform are separate COMP `data` blobs; Road payloads decode cleanly. |

**Fix direction**

1. **Ship workaround:** deploy full patch minus index **18** (`no-dlccon004-roads`) — clears `0x248BB*` (hang at VZ remains).
2. **One x32dbg session** on **`keep-dlccon004-roads-only`** to map entity key → COMP source.
3. **If entity key is Road/RoadIntersection-only:** re-port block 18 with `dlc_port.py --byteswap-python-ecs` or add typed swap for DestructionLink + Road graph fields in `ucfx_be_to_le.py`.
4. **If entity key has sane Transform on disk but bad at runtime:** treat as engine layout bug — compare schm vs compact numeric dispatch for 18's COMP set against Ghidra entity-construction for layer blocks.

**Logic update (30f + 30g):**

| Configuration | Spatial-hash AV | Boot past VZ |
|---------------|-----------------|--------------|
| Full patch (minus ruled indices) | **Y** | **N** (early `0x248BB*` ~5 s) |
| Full patch − **`dlccon004_roads`** only | **N** | **N** (hang @ `Loading vz`) |
| Full patch − **`dlccon002_roads`** or **`dlccon002_race`** only | **Y** | **N** |
| **`dlccon002_roads`** only + base + speedcity (index **6**) | **N** | **Y** |
| **`dlccon002_race`** only + base + speedcity (index **13**) | **Y** | partial (deep load, then AV) |
| **`dlccon004_roads`** only in patch (index **18**, SHA `6809da8e…`) | **Y** | partial (Shop/players, **170+238** layers, AV ~**30 s** — **confirmed log**) |

#### Next steps (post-30g)

```powershell
cd C:\Users\Shadow\Desktop\notes-on-the-released-game

# 1 — Extract + scan primary suspect (index 18)
.venv\Scripts\python.exe tools\extract_single_block.py --wad output/data/vz-patch.wad --block-index 18 --keep --scratch-root output/_scratch
.venv\Scripts\python.exe tools\scan_patch_placements.py output/_scratch/00018_dlc01_dlccon004_roads_P000_Q3.block.bin
.venv\Scripts\python.exe tools\verify_ucfx_endian.py --block output/_scratch/00018_dlc01_dlccon004_roads_P000_Q3.block.bin

# 2 — Secondary suspect (index 13) if 18 scan clean offline
.venv\Scripts\python.exe tools\extract_single_block.py --wad output/data/vz-patch.wad --block-index 13 --keep --scratch-root output/_scratch
.venv\Scripts\python.exe tools\scan_patch_placements.py output/_scratch/00013_dlc01_dlccon002_race_P000_Q3.block.bin

# 3 — Optional: confirm full patch boots when 18 excluded (already log-proven; use for gameplay smoke)
$RULED = "0,4,12,15,16,17"
.venv\Scripts\python.exe tools\trim_patch_wad.py -i output/data/vz-patch.wad -o output/data/vz-patch-no-dlccon004-roads.wad --exclude-indices $RULED --exclude-path-substr dlccon004_roads -v
```

Deploy trimmed WAD as `data\vz-patch.wad`. x32dbg on **`keep-dlccon004-roads-only`**: **Restart** after AV (cannot step from fault); `bp 0x00516EF6` and/or `bp 0x248BB6D` with **`ecx>0x4000 || (ecx & 0x80000000)`**; run **60+ s** until hit (not only at `Loading vz…`). MCP can read registers when paused.

#### Next trims (2026-05-30e) — **completed**; see **§2026-05-30f** / **§2026-05-30g**

```powershell
cd C:\Users\Shadow\Desktop\notes-on-the-released-game
$RULED = "0,4,12,15,16,17"

# 1 — Full patch minus dlccon004 only (if still Y => 004 not required for crash)
.venv\Scripts\python.exe tools\trim_patch_wad.py -i output/data/vz-patch.wad -o output/data/vz-patch-no-dlccon004.wad --exclude-indices $RULED,2 -v

# 2 — Drop dlccon roads/race; keep 004 mesh + base + speedcity
.venv\Scripts\python.exe tools\trim_patch_wad.py -i output/data/vz-patch.wad -o output/data/vz-patch-no-dlccon-roads.wad --exclude-indices $RULED --exclude-path-substr dlccon002,dlccon004_roads -v

# 3 — Minimal repro: base + dlccon004 only (+ bootstrap if needed for ASET)
.venv\Scripts\python.exe tools\trim_patch_wad.py -i output/data/vz-patch.wad -o output/data/vz-patch-base-dlccon004-only.wad --keep-only-indices "2,3,2195" --exclude-indices $RULED -v
```

Deploy each as `data\vz-patch.wad`. **Fix target** when narrowed: highest-Transform remaining **`dlccon*`** block from `trim_patch_wad.py --list` (start **6**, **13**, **18**); run `extract_single_block.py` + `scan_patch_placements.py` on that index.

### Alternative theories (still live)

| Theory | Test | Notes |
|--------|------|-------|
| **Bootstrap / registration order** | Step **4a** or `make dlc-port-assets-only` | `scripts_vz` injects `import("dlc01")` + ASET row; can change resolve order without corrupting floats |
| **ASI CRASH_PATCH / REG_PATCH / GUARD** | Rebuild ASI with all three **0** | Rules out hook writing game memory during VZ load |
| **Retail + patch overlay** | Confirmed: no patch → no crash | Engine uses **patch INDX/ASET** over retail `vz.wad`; bad **ASET → block** still loads corrupt LE from patch |
| **929 unresolved ASET sub-entries** | `verify_dlc_import_chain` | Wrong block for hash → unrelated bytes interpreted as Transform |
| **resident SKIPPED** | Re-port after guidmap/CHDR fix; check port log | Missing contracts / wrong script DEPS — usually **different** EIP, but can disturb load order |
| **Runtime non-placement** | Simulator 0 violations + still crash | Stale deploy, or **ECX** from non-XYZ path (bad entity ptr) — x32dbg @ `0x516EF6` |

### x32dbg — capture block hash at `0x516EF6`

Break on return from spatial cell compute: **`bp 0x00516EF6`** (or conditional **`bp 0x248BB6D`** when **`ecx > 0x4000`**). On hit, read **entity pointer** from stack (**EDX** or `[esp+0x30]` per session) and dump **`[ptr+4]` `[ptr+8]` `[ptr+0xC]`** as floats — NaN/huge values are the smoking gun. Walk one frame up (**`0x0063DA1F`** block loader): note last asset hash / path if logged. To tie to a **block hash**: at `0x516EF6`, also note **EAX** (asset index being inserted) and correlate with ASET resolve in the same frame chain; MCP `GetCallStack` + memory read at the entity pointer is enough for one session without guessing indices.

### Python vs Rust parity on suspects

For each suspect, decompress the **Xbox BE** slice from DOH (or `--dump-dir` from port), then:

```powershell
.venv\Scripts\python.exe tools\audit_ecs_byteswap_parity.py --be-block output\_dumps\block_0003_be.bin
```

Mismatch → re-port with `--byteswap-python-ecs` for full ECS or rely on new default path-based Python swap.

## User bisect results (2026-05-30)

Retail PC + `dlc_enable.asi` (bootstrap **OFF**, `CRASH_PATCH=1`, `REG_PATCH=1`, `GUARD=1`). Tests used `tools/trim_patch_wad.py` on the deployed `vz-patch.wad` unless noted.

| Step | Test | Result | Interpretation |
|------|------|--------|----------------|
| **0** | No `vz-patch.wad` (rename away) | **No crash** | Fault is **patch-only**, not retail VZ |
| **1** | `--exclude-indices 0` (drop `dlc01_terrain_P000_Q3`) | **Still crash** @ `0x0248BB7C` | **Not** block **0** terrain lattice / terrain-only corruption |
| **2** | `--exclude-indices 4,12,15,16,17` (all `dlc01_state_*`) | **Still crash** @ `0x0248BBE2`, fault `0x03CE9FD8` | **Not** the five state-overlay blocks; same crash class (garbage cell index) |
| **3** | Full re-port with **stride fix** (2026-05-30b); SHA `97242b0a2e0c9f2e3a093dbb4ee24f9d368dc9a0bc4a4f55d300b11ae04f8755` | **Still crash** @ `0x0248BBE2`, fault `0x03CE9FD8` | Stride/flgs/Transform fixes **not sufficient**; proceed step 4 bisect |

### Ruled out (this build’s indices)

| Index | Path (typical) | Why ruled out |
|-------|----------------|---------------|
| **0** | `blocks\dlc01\dlc01_terrain_P000_Q3.block` | Step 1 still crashes without it |
| **4** | `dlc01_state_dlccon003_spawns_P000_Q3` | Step 2 |
| **12** | `dlc01_state_dlccon003_P000_Q3` | Step 2 |
| **15** | `dlc01_state_dlccon003_pathfinding_P000_Q3` | Step 2 |
| **16** | `dlc01_state_missionhub_P000_Q3` | Step 2 |
| **17** | `dlc01_state_dlccon003_atmofx_P000_Q3` | Step 2 |

**Caveat:** If steps 1–2 were run on a **pre–stride-fix** `vz-patch.wad` (trim without re-`dlc-port`), step 3 must be done first; otherwise bisect chases byteswap bugs already fixed in Rust/Python.

### Suspect pool after step 2

- **~2191 blocks** still present when indices `0,4,12,15,16,17` are removed from a **2197-block** full port (2197 − 6 = 2191).
- Includes **`scripts_vz` bootstrap** at index **2196** on full `make dlc-port` builds — **not** removed in step 2.
- High-priority **layer/placement** blocks **not** in `dlc01_state_*`: `dlc01_base`, `dlc01_commonlocations`, contract `dlc01_dlccon*`, arena geometry, **~2100+** `c3*` cell blocks, `resident`, stringdb, audio, meshes.

## Log correlation (`dlc_enable_crash*.log`)

Retail PC + `dlc_enable.asi` (bootstrap **OFF**, `CRASH_PATCH=1`, `REG_PATCH=1`, `GUARD=1`). See **2026-05-30d** table for per-trim logs.

| Field | Value |
|-------|-------|
| Last Lua line (spatial-hash trims) | `[lua] Loading vz level with vz masterscript` |
| FATAL (write) | `0x0248BBE2` / `fault=0x03CEA014` (`no_base`, `no_speed_city`) |
| FATAL (read) | `0x0248BB7C` / `fault=0x03CEA074` (`no_bootstrap`) |
| Timing | ~**4.2–5.8 s** post–Shell-exited to FATAL (varies by trim) |
| Control (`clean_no_patch`) | No FATAL; boot continues through layers / `GlobalExit` |

This matches the spatial-hash insert at `0x248BB60` during **main-thread WAD registration**
(call stack in §Call Stack), not the audio mixer crash (`0x83664E`, separate thread — see
`docs/audio_crash_analysis.md`).

### Instruction map (verified in x32dbg, 2026-05-30)

| EIP | Instruction | Access | Notes |
|-----|-------------|--------|-------|
| `0x248BB6D` | `mov esi, ecx` | — | **ECX = cell index** (bucket selector) |
| `0x248BB6F` | `imul esi, esi, 0x1F0` | — | `esi = cell_index × 0x1F0` |
| `0x248BB75` | `add esi, ebp` | — | `ebp = [0x01175DD8]` table base |
| `0x248BB7C` | `cmp word ptr [esi+0x1E4], dx` | **READ** | `dx = 0x20` (bucket capacity); **new crash here** |
| `0x248BBE2` | `mov dword ptr [esi+ecx*4], eax` | **WRITE** | **Prior crash**; `ecx` = slot index within bucket |

**Fault address identity:** `fault = esi + 0x1E4` on the `0x248BB7C` read. Example from log:
`fault=0x03CEA074` ⇒ `esi = 0x03CE9E90`. That `esi` is **not** `table_base + cell×0x1F0` in the
heap block; it is produced when **ECX (cell index) is garbage**, e.g. `ECX = 0x038E2840`:

```
esi = (0x2060A290 + (0x038E2840 * 0x1F0)) & 0xFFFFFFFF = 0x03CE9E90
fault = esi + 0x1E4 = 0x03CEA074
```

Same root as the older `0x248BBE2` / `nvgpucomp32.dll` write: **overflowing cell index** from corrupt
entity XYZ fed to `0x516B10`, not a different bug class.

**Step 3 write fault (2026-05-30, x32dbg MCP):** `EIP=0x0248BBE2`, `ESI=0x03CE9E90`, `ECX=0x52`,
`EBP=0x2060A290` (table base). Fault address `0x03CE9FD8` = `ESI + ECX×4` (slot write), not the
`0x248BB7C` read at `ESI+0x1E4` (`0x03CEA074`). Same garbage bucket pointer (`ESI` off-heap) from wild
cell index before insert.

**Production byte-swap:** `make dlc-port` uses **Rust** `ucfx_byteswap`, not Python `ucfx_be_to_le.py`.
Until 2026-05-30, Rust treated ECS `flgs` as a flat `u32` sweep (corrupting 42-byte vz_state placement
records); Python had a typed `_convert_vz_state_flgs` but was not on the port path. Rebuild required.

## Post–flgs-fix crash still reproduces (2026-05-30)

If retail PC + `dlc_enable.asi` still dies at `0x248BBE2` after a claimed rebuild, work through
**deployment verification** first, then the remaining corruption sources below.

### Did the fix ship? (checklist)

| Check | How |
|-------|-----|
| Rust binary rebuilt | `make build-ucfx-byteswap` — timestamp on `tools/wad_simulator/target/release/ucfx_byteswap.exe` **newer** than `convert.rs` |
| Patch re-ported | `make dlc-port DLC_RAR=... SOURCE_WAD=... OUTPUT=./output` — **not** redeploying an old `vz-patch.wad` |
| Deployed WAD is the new build | Compare SHA-256 of `output/data/vz-patch.wad` on build host vs game `data/vz-patch.wad` |
| No stale trim | If you use `make trim-patch-wad`, re-run **after** `dlc-port` |
| Port log clean | `dlc_port` must report **0 skipped** blocks; any `byte-swap failed` = block missing from patch |
| `--permissive` unused | Flag is wired in CLI but **not** passed to `byteswap_block_rust` (harmless if set) |
| Simulator gate | `wad_simulator --wad output/data/vz-patch.wad --base-wad game-files/pc-game-vz.wad` → `position_violations: 0` |

`dlc_port.py` always calls `byteswap_block_rust(decompressed)` (no Python `ucfx_be_to_le` fallback).
`base_block_cache` only caches **decompressed Xbox slices** for base-game overrides, not LE output.

### Confirmed on port path (Rust `ucfx_byteswap`)

- **ECS** containers (`type_hash` `0xE6B81A54` layer, `0x5647C35D` world_entity_data): `ChunkTag::Flgs` → `convert_vz_state_flgs_inplace` (42-byte records, mixed u32/u16).
- **ECS** `Transform` COMP `data`: typed f32 swap when component name resolves (ASCII or compact hash `0x753EB623`).
- **Non-ECS** containers: `Flgs` still uses blind `swap_u32_array` — only matters if a non-layer entry carries `flgs` placement records (unusual).

### Second bug fixed 2026-05-30: compact Transform without `schm`

Many DLC / vz_state COMP groups use **16-byte compact `info`** (hash only, no ASCII name, **no `schm`**).
Python (`ucfx_be_to_le._ECS_COMP_DEFAULT_STRIDE`) still runs `_convert_transform_records`.
Rust `convert_comp_data_inplace` previously hit `schema == None` → **full-body `swap_u32_array`**, corrupting
XYZ at +4/+8/+12 — same crash signature as bad `flgs`.

**Fix:** treat `comp_name == "Transform"` with stride 42 even when `schm` is absent (`convert.rs`).

### Third bug fixed 2026-05-30: compact non-Transform ECS components

Python `_ECS_COMP_DEFAULT_STRIDE` + `_convert_numeric_records` apply to **Road**, **RoadIntersection**,
**AiBehavior**, etc. Rust still used **whole-body `swap_u32_array`** for any compact component that was not
`Transform`, misaligning record boundaries and corrupting embedded floats.

**Fix:** `compact_default_stride()` + `swap_numeric_records_inplace()` in `convert.rs`.

### Fourth bug fixed 2026-05-30b: compact strides were payload-only, not record size

`docs/ecs_components.md`: **record stride = 4 + payload_stride** (e.g. Road payload 40 → record **44**).
Both Python `_ECS_COMP_DEFAULT_STRIDE` and Rust `compact_default_stride()` incorrectly stored **payload-only**
values (40 for Road). Blocks **with `schm`** used `4 + payload_stride` in Rust (correct); blocks **without `schm`**
used the wrong compact default (misaligned numeric swap).

**Fix:** full record strides in `convert.rs` + `ucfx_be_to_le.py`; Python `schm` map now sets
`current_stride = 4 + payload_stride` (Transform forced to 42). **ModelName** removed from string pass-through;
now swaps 8-byte records like Rust.

Non-ECS `Flgs` in `convert_generic_bodies` remains a blind `swap_u32_array` — only affects non-layer UCFX
containers; DLC `dlc01_state_*` uses the ECS path (`convert_vz_state_flgs_inplace`).

### `wad_simulator` on prior patch (SHA `1E6CA26C…`, 2197 blocks)

Current step-3 WAD SHA: `97242b0a2e0c9f2e3a093dbb4ee24f9d368dc9a0bc4a4f55d300b11ae04f8755` (re-run simulator after bisect).

### Prior simulator snapshot (`1E6CA26C…`)

| Metric | Value |
|--------|-------|
| `position_violations` | **22** (all in **block 0** only) |
| Block 0 path | `blocks\dlc01\dlc01_terrain_P000_Q3.block` |
| Pattern | Transform grid Y = ±800/±1200/±1600, X ≈ 0 — **arena terrain lattice**, not LE swap corruption |
| `flgs` placement violations | **0** |
| Transform NaN/Inf | **0** |

The 22 terrain hits are **simulator false positives** (`WORLD_Y_MIN = -500`; arena grid uses Y below that).
They are unlikely to be the `ECX = 0x038E2840` path unless the engine registers those lattice points as
world entities at load time (needs confirmation).

### Remaining placement float sources (ranked)

| Priority | Source | Risk | Notes |
|----------|--------|------|-------|
| P0 | Compact **Transform** COMP `data` (no `schm`) | Was **High** | Fixed in Rust 2026-05-30 |
| P0 | Compact **Road / numeric ECS** (no `schm`) | **High** | Fixed in Rust 2026-05-30 (`swap_numeric_records_inplace`) |
| P0 | **flgs** in ECS layer blocks (`dlc01_state_*`) | Was **High** | Fixed in ECS path; simulator shows 0 flgs violations |
| P1 | **BNDS** AABB floats on meshes | Medium | Bad bounds → wrong spatial queries; `wad_simulator` checks envelope |
| P1 | **STRM** positions (if ever registered) | Lower for hash @ `0x516B10` | Engine path reads **entity** XYZ (+4/+8/+12), not mesh verts |
| P2 | **world_entity_data** (`0x5647C35D`) | Medium | Uses ECS convert path; simulator uses `consume_structural` only (no placement scan) |
| P2 | Base-game **override** entries | Low | Whole UCFX replaced from retail PC LE — correct by definition |
| P3 | **CHDR-internal** absolute offsets | Low for port | Byteswap walks **UCFX descriptor** table (`data_area_off + row_u0`), same as Python; CHDR child table in docs is a separate view |

### DLC port: large CHDR + `guidmap` (2026-05-30)

Python `--byteswap-python-ecs` failed mid-port with:

`UnhandledByteSwapError: CHDR body has unexpected size 59051 bytes (not a multiple of 4); type_hash=0x140E8728`

- **Type:** `0x140E8728` = `pandemic_hash_m2("guidmap")` (ASET type_id 10, resident singleton).
- **Cause:** ECS-family containers can advertise a **large** CHDR `body_size` (here 59051 B, odd length). That region is also covered by sibling `enum` / `COMP` / `flgs` descriptors. Only the first **8 bytes** are CHDR scalars (`zero`, `num_chunks`); blind u32 sweep of the whole slice is wrong and the old Python check rejected odd sizes.
- **Fix:** `tools/ucfx_be_to_le.py` `_convert_chdr_body()` swaps ≤16 B wholesale, else header-only for `_ECS_STRUCTURE_TYPES` / `META`. Rust `convert_chdr_body_inplace()` mirrored in `ucfx_byteswap`. `guidmap` routed through the ECS container path.
- **Resume:** Re-run `dlc_port` from the start (or `--start-block` at the failed index). There is no `--skip-failed`; failed blocks are logged as `SKIP` when byteswap raises. After pulling the fix, a full re-port is safest so CSUMs match converted LE.

DLC blocks often have **both** `flgs` placements and **Transform** COMP data in the same `dlc01_state_*` layer block.

### Validation gaps

| Tool | Coverage | Misses |
|------|----------|--------|
| `wad_simulator` | All **resolved ASET** assets (base+patch overlay), `consume_layer` on type_id 9 | `world_entity_data` (type_id 8) not placement-scanned; won't flag compact Transform until consumed as layer |
| `verify_ucfx_endian.py` | Patch WAD scan | **`flgs` probe uses wrong offsets** (4/18/22 = Transform layout, not flgs +0x12/+0x16/+0x1A) — false negatives |
| `audit_dlc_conversion.py` | Entries with **same (hash, type_hash) in base vz.wad** | All DLC-unique ecs_node / state blocks |
| `validate_ecs_dlc.py` | DLC-unique ecs_node list | Alignment only; no world-bounds on floats |
| `ucfx_byteswap --validate-only` | CSUM, descriptors, BNDS/STRM/IBUF | Not placement-specific |

### Next bisect plan (after step 3 re-port)

**List blocks** (indices are stable for a given `vz-patch.wad` SHA):

```powershell
.venv\Scripts\python.exe tools\trim_patch_wad.py -i output/data/vz-patch.wad -o NUL --list
.venv\Scripts\python.exe tools\trim_patch_wad.py -i output/data/vz-patch.wad -o NUL --list-state-blocks
.venv\Scripts\python.exe tools\inventory_dlc_patch.py --wad output/data/vz-patch.wad
```

**Always carry forward** exclusions from steps 1–2: `0,4,12,15,16,17` (re-verify indices with `--list` after re-port).

| Step | Action | If no crash | If still crash |
|------|--------|-------------|----------------|
| **4a** | Drop bootstrap only: `--exclude-indices 2196` (or path `--exclude-path-substr scripts_vz`) | Suspect **scripts_vz / ASET dlc01 row**, not asset bytes | Bootstrap not the trigger; continue |
| **4b** | **Half by index** on assets: `--keep-only-indices 1-1099` (deploy as `vz-patch.wad`) | Culprit in **upper** half (1100–2195) | Culprit in **lower** half (1–1099) |
| **4c** | Repeat 4b on the half that still crashes (e.g. `--keep-only-indices 1100-1649`) | — | Narrow to one block |
| **4d** | Path buckets (fast cuts): `--exclude-path-substr c3` vs keep arena paths | See taxonomy below | — |
| **4e** | `make dlc-port-assets-only` → deploy **2196 blocks, no bootstrap** | Isolates bootstrap vs any asset | Any DLC asset can still fault |

`trim_patch_wad.py` also supports `--exclude-path-substr` (comma-separated) and `--keep-only-indices` with ranges (`1-1099`).

### Block taxonomy (2197-block full port, after excluding 0,4,12,15,16,17)

From Xbox DLC inventory (`docs/xbox360_dlc_analysis.md`), `tools/inventory_dlc_patch.py` buckets, and `docs/type_hash_registry.md`. **Spatial hash @ `0x516B10` reads entity Transform XYZ (+4/+8/+0xC)** — types that register world entities at VZ load matter most.

| Bucket / path pattern | ~count (2196 port) | type_hash / role | Registers XYZ at VZ load? |
|------------------------|-------------------|------------------|---------------------------|
| `c3XXXX_P000_Q3` | ~2100+ | texture, model, scrub, terrainmesh per cell | **Unlikely** direct entity hash; mesh **BNDS** wrong → bad queries, not typical `entity+4` path |
| `dlc01_base`, `dlc01_commonlocations` | 2 | **layer** (`0xE6B81A54`) — placements + Transform COMP | **Yes** — same class as `layers_static`; **not** excluded in step 2 |
| `dlc01_dlccon*`, `dlc01_caicara*`, `dlc01_speedcity*` | ~15 | model / layer mix | **Maybe** if block contains layer or world_entity entries |
| `dlc01_lowresterrain`, foliage, roads | few | terrainmesh / model | Low for entity registration |
| `dlc01_resident` / `resident` | 1 | path, script refs, possible lineregion | **Unlikely** same crash (different layouts); script **DEPS** = other crash class |
| `english_dlc01` / stringdb | few | stringdb | No |
| Audios / `.pws` (if embedded) | varies | wavebank / soundbank | No (audio thread crashes are separate) |
| `scripts_vz` (bootstrap) | **1** @ index **2196** | script (`0x42498680`) | Indirect — corrupt script registry, not typical spatial hash |
| `dlc01_state_*` | 5 | layer + flgs + Transform | **Ruled out** by user step 2 |

Use `inventory_dlc_patch.py` on **your** WAD for exact bucket counts (path buckets only — does not rank Transform counts; use scan below).

### Layer blocks ranked by Transform COMP count (SHA `97242b0a…`, 2026-05-30)

Only **20** patch blocks contain ECS **layer** (`0xE6B81A54`) with **Transform** COMP `data` (42-byte records). Top 20 (all layer+Transform blocks):

| Index | Transforms | Path |
|-------|------------|------|
| 8 | 1736 | `dlc01_speedcity_P000_Q3` |
| 2 | 1482 | `dlc01_dlccon004_P000_Q3` |
| 13 | 836 | `dlc01_dlccon002_race_P000_Q3` |
| 14 | 810 | `dlc01_caicara_P000_Q3` |
| 18 | 734 | `dlc01_dlccon004_roads_P000_Q3` |
| 6 | 596 | `dlc01_dlccon002_roads_P000_Q3` |
| 7 | 493 | `dlc01_speedcity_roads_P000_Q3` |
| **3** | **422** | **`dlc01_base_P000_Q3`** ← step **4e** |
| 19 | 236 | `dlc01_caicara_roads_P000_Q3` |
| 9 | 228 | `dlc01_caicara_scrub_P000_Q3` |
| 15 | 186 | `dlc01_state_dlccon003_pathfinding` (ruled out step 2) |
| 1 | 101 | `dlc01_caicara_foliage_P000_Q3` |
| 10 | 99 | `dlc01_dlccon001_P000_Q3` |
| 11 | 81 | `dlc01_lowresterrain_P000_Q3` |
| 0 | 81 | `dlc01_terrain_P000_Q3` (ruled out step 1) |
| 12 | 63 | `dlc01_state_dlccon003` (ruled out step 2) |
| 4 | 49 | `dlc01_state_dlccon003_spawns` (ruled out step 2) |
| 17 | 37 | `dlc01_state_dlccon003_atmofx` (ruled out step 2) |
| 16 | 32 | `dlc01_state_missionhub` (ruled out step 2) |
| **5** | **10** | **`dlc01_commonlocations_P000_Q3`** ← step **4e** |

**Bisect priority tonight:** **4a** (no bootstrap @ **2196**) → **4e** (exclude **3**, **5**) → **4b/4c** half-split. Contract/arena blocks **2,6,7,8,13,14,18** are high Transform load if 4e passes.

### Hypothesis ranking (remaining pool)

| Rank | Hypothesis | Rationale |
|------|------------|-----------|
| **H1** | **`dlc01_base` / `dlc01_commonlocations`** layer blocks | Arena **placements** with Transform/flgs; same engine path as Venezuela `layers_static`; **not** in step 2 exclusions |
| **H2** | **Compact ECS numeric** in non-state blocks (Road, etc.) | Stride fix 2026-05-30b may not be deployed; corrupt floats in COMP `data` still feed `0x516B10` |
| **H3** | **`scripts_vz` bootstrap** (index 2196) | Step 2 did not remove it; modified `scripts_vz` could register bad entities or load wrong blocks — test **4a** / `dlc-port-assets-only` |
| **H4** | **ASET → wrong block** for a hot hash | Engine resolves asset to patch block; corrupt entry in unrelated-looking `c3` block |
| **H5** | **`dlc01_resident`** (path / script / DEPS) | Different failure mode historically (`0x59d45f`); lower priority for **this** EIP |
| **H6** | **Havok / animation** in contract `c3` blocks | Usually skeleton/mesh path, not placement hash insert |
| **H7** | **Stale trim** on old port | Steps 1–2 still crash until step 3 SHA matches new `convert.rs` |

### x32dbg (one session, MCP `user-x32dbg` when attached)

Set conditional **`bp 0x248BB6D`** with **`ecx > 0x4000`**. On hit, note **ECX** (garbage cell index) and **EBP** = table base `[0x01175DD8]`. At return **`0x00516EF6`**, resolve the entity pointer (stack / **EDX** per prior sessions) and dump **`[ptr+4]` `[ptr+8]` `[ptr+0xC]`** as **floats** — bad values are NaN/Inf or byte-swapped garbage; healthy Maracaibo load looks like metres ~(−0.2, 831, 0). Walk frame **2** (`0x0063DA1F` = block loader) and correlate with the **last-loaded block** or ASET hash if logged; MCP **`GetRegisterDump`**, **`GetCallStack`**, and memory read at the entity pointer help tie the fault to a specific registration without guessing the block index.

### Step 3 — after stride-fix re-port (verify before step 4)

1. `make build-ucfx-byteswap` — `ucfx_byteswap.exe` newer than `convert.rs`.
2. `make dlc-port DLC_RAR=... SOURCE_WAD=... OUTPUT=./output` — **not** an old `vz-patch.wad` copy.
3. `certutil -hashfile output\data\vz-patch.wad SHA256` — match on game PC vs build host.
4. `wad_simulator --wad output/data/vz-patch.wad --base-wad game-files/pc-game-vz.wad --strict` — target **`position_violations: 0`** (terrain lattice may still flag block 0; know false positives).
5. **Repeat user step 2** on the **new** WAD: `--exclude-indices 0,4,12,15,16,17`. If crash **stops**, prior bisect was stale byteswap; if **still crashes**, run step **4a–4c** below.

### Bisect strategy (reference)

1. **Simulator on full patch** (after re-port).
2. **Trim bisect** — `--list`, `--keep-only-indices`, `--exclude-path-substr`, carry `0,4,12,15,16,17` forward.
3. **Single block:** `extract_single_block.py` + `placement_extractor.py` on the narrowed path.
4. **High-risk paths (post–step 2):** `dlc01_base`, `dlc01_commonlocations`, `dlc01_dlccon*`, then `c3` cells.

### Recommended bisect blocks (patch WAD) — updated

| Step | Action | User result |
|------|--------|-------------|
| 0 | No patch WAD | **Pass** (`clean_no_patch.log`) |
| 1 | `--exclude-indices 0` | **Fail** (still crash) |
| 2 | `--exclude-indices 4,12,15,16,17` | **Fail** (still crash) |
| 3 | Full re-port; SHA `8700856a…`, scan **0** violations | **Fail** (still `0x248BB*`) |
| 4a | `--exclude-indices 2195` (`no_bootstrap`) | **Fail** — bootstrap ruled out |
| 4e | `--exclude-indices 3,5` (`no_base`) | **Fail** — base+commonlocations alone ruled out |
| 4e′ | exclude `speedcity` (`no_speed_city`) | **Fail** — speedcity alone ruled out |
| 4 arena | exclude `dlc01_base,speedcity,dlccon` (`no_arena`) | **Pass** spatial-hash window — **arena bucket IN** |
| **4f** | exclude `dlccon` paths (`no-dlccon`) | **Pass** @ `0x248BB*` — **dlccon required** |
| **4g** | exclude `dlc01_base` only (`no-base-only`) | **Fail** — base alone not sole trigger |
| **4h** | `keep-only` block **2** (`dlccon_only`) | **Pass** — **dlccon004 alone benign** |
| 4b–4c | Half-split `1-1099` vs `1100-2195` | Deferred — split non-004 `dlccon` (6, 13, 18) |

`dlc01_state` indices on the **current** doc build: **4** spawns, **12** dlccon003, **15** pathfinding, **16** missionhub, **17** atmofx. Re-list after re-port.

### Action plan (other machine)

1. `make build-ucfx-byteswap && make dlc-port …`  
2. `wad_simulator --wad output/data/vz-patch.wad --base-wad …` — must show **0** position violations  
3. `make verify-dlc-endian` (know flgs offsets in script are wrong; trust simulator for placements)  
4. Copy `vz-patch.wad` + rebuilt `dlc_enable.asi`; confirm SHA-256  
5. Fresh x32dbg session: conditional bp at hash insert; capture EDX entity floats + return addresses  
6. If clean simulator but still crashes → suspect **runtime** (wrong entity pointer, not swap) or **non-placement** cell index input  
7. Bisect with `dlc-port-assets-only` or trimmed WAD if simulator is clean but game still fails  
8. File-level proof: `extract_single_block` on flagged `dlc01_state_*` block  

## Register State at Crash

| Register | Value | Meaning |
|----------|-------|---------|
| EIP | `0x0248BBE2` | Asset registry hash table insert function |
| ESI | `0x6F319DA0` | "Bucket" pointer — actually inside `nvgpucomp32.dll` (.rdata, PAGE_READONLY) |
| ECX | `0x00002E70` | "Count" read from garbage at `[ESI+0x1E4]` — bogus (should be 0–32) |
| EAX | `0x0000356B` | Value being inserted (entity/asset index = 13,675) |
| EBP | `0x2060A290` | Hash table base pointer `[0x01175DD8]` |
| EBX | `0x00003500` | (saved register) |
| EDX | `0x20E54074` | Pointer to entity data being registered |
| ESP | `0x03C0F534` | Stack pointer |

## Root Cause: Spatial Cell Index Overflow

The crash occurs in a **spatial hash table** used during WAD asset registration. An entity's
world-position coordinates are converted to a grid cell index via function `0x516B10`. That
index is then used to access a bucket in the hash table at `0x248BB60`. When the index is
too large, the computed bucket address (`base + index * 0x1F0`) overflows past the allocated
table memory and lands in unrelated address space.

### Why PAGE_READONLY didn't crash on the READ

The function reads `[ESI+0x1E4]` (at `0x6F319F84`) successfully — getting garbage value
`0x2E70` — because `nvgpucomp32.dll` data sections are readable. It then tries to WRITE
at `[ESI + 0x2E70*4]` = `[0x6F325760]` which is beyond the mapped region → ACCESS VIOLATION.

## Hash Table Structure (0x248BB60)

```
Function: 0x248BB60 (reached via thunk at 0x517DC0 → jmp [0x245A0F8])
Base pointer: [0x01175DD8] = 0x2060A290
Heap region: 0x18040000 — 0x3E266000 (610 MB allocation)
Bucket stride: 0x1F0 (496 bytes)
Max entries per bucket: 32 (capacity check: cmp [esi+0x1E4], 0x20)
Overflow chain: [bucket+0x1E8] → next bucket (heap-allocated)
```

### Bucket Layout (inferred)

```
+0x000: entry[0]  — 4 bytes × 32 slots? (data values like block/entity index)
+0x0A0: entry2[0] — 4 bytes × 32 slots? (secondary data)
+0x1E4: count     — u16, number of entries in this bucket (0–32)
+0x1E8: chain_ptr — pointer to next overflow bucket (or NULL)
```

### Insert Logic (pseudocode)

```c
void SpatialHashInsert(int cell_index, int value, int value2) {
    int* table_base = *((int*)0x01175DD8);
    char* bucket = table_base + cell_index * 0x1F0;  // NO BOUNDS CHECK!
    
    while (*(short*)(bucket + 0x1E4) >= 32) {   // bucket full?
        char* next = *(char**)(bucket + 0x1E8); // follow chain
        if (!next) { next = allocate_bucket(); *(bucket + 0x1E8) = next; }
        bucket = next;
    }
    
    short count = *(short*)(bucket + 0x1E4);
    bucket[count * 4] = value;           // ← CRASH (write to bad address)
    bucket[0xA0 + count * 4] = value2;
    *(short*)(bucket + 0x1E4) = count + 1;
}
```

## Caller Chain: Spatial Cell Computation

```
0x516C00  — Entry: computes LOD/distance value, clamps to max 0x3FFF
0x516C76  —   cmp eax, 0x3FFF; jle skip; mov eax, 0x3FFF  (CLAMP)
0x516C98  —   call 0x516B10  (spatial cell computation from entity XYZ)
0x516C9D  —   mov ebp, [esp+0x18]  ← OUTPUT of 0x516B10 = cell index
0x516EEF  —   mov ecx, ebp         ← pass cell index as bucket index
0x516EF1  —   call 0x517DC0        ← hash table insert (crashes)
```

Function `0x516B10` converts entity world-position floats to a spatial grid cell index.
It reads XYZ from a float vector pointed to by its ECX/'this' parameter. If the position
floats are corrupt (NaN, Inf, or out of expected range), `cvttss2si` produces `0x80000000`
(integer indefinite) which propagates through bit-shifts and OR operations to produce a
garbage cell index like `0x0449B62F`.

### Grid Parameters (globals)

| Address | Value | Purpose |
|---------|-------|---------|
| `0x01175DD4` | `0x01` (byte) | Spatial system enable flag |
| `0x01175DD8` | `0x2060A290` | Hash table base pointer |
| `0x0179C7B6` | (s16) | Grid divisor (used in `idiv` at 0x516CBD) |
| `0x0179C7E4` | (float) | Position-to-cell scale factor |
| `0x0179C7BC` | (float) | World origin X offset |
| `0x0179C7C4` | (float) | World origin Z offset |

## Call Stack

| # | Return Addr | Context |
|---|-------------|---------|
| 0 | `0x00516EF6` | `0x516C00` — spatial registration caller |
| 1 | `0x0051812F` | Higher-level registration loop |
| 2 | `0x0063DA1F` | WAD loading / block processing |
| 3 | `0x0063D904` | WAD streaming controller |
| 4 | `0x00654E4E` | Asset loading dispatcher |
| 5 | `0x004B11D8` | Virtual call (indirect `call edx`) |
| 6 | `0x004C9C80` | Block load orchestrator |
| 7 | `0x004C0EDB` | Main loop / tick |
| 8 | `0x004C0B6F` | Game init / startup |

## Patch WAD Verification

The patch WAD's ASET table was verified clean:
- **Block count (INDX)**: 2,197
- **ASET entries**: 5,451
- **Max block index in ASET**: 2,196 (valid — within 0 to 2,196 range)
- **No hash `0xBC10BF80`** found in either base or patch ASET tables

The value `0x356B` (13,675) being registered is NOT directly from a corrupt ASET entry.
It likely represents an internal runtime object/entity slot index that the engine computed
during block loading.

## Hypothesis: Corrupt Position Floats from Byte-Swap

The most likely cause is an entity whose XYZ position floats are corrupt after byte-swapping
(entity structure **+0x04/+0x08/+0x0C** in the crash register dump — matches **Transform** layout,
not vz_state **flgs** +0x12/+0x16/+0x1A, but both swap bugs produce garbage at engine read sites).
When `cvttss2si` converts NaN/Inf/out-of-range floats to integers, x86 returns `0x80000000`
(integer indefinite). The spatial cell computation in `0x516B10` then produces a garbage
cell index that overflows the hash table.

Potential sources (see **Post–flgs-fix** section for current status):
1. **Transform COMP `data`** — 42-byte records; compact format without `schm` was blind-swept in Rust until 2026-05-30.
2. **flgs** vz_state records — blind sweep in Rust ECS path until 2026-05-30.
3. **BNDS** / mesh bounds — unlikely to match entity +4/+8/+12 unless wrong pointer.
4. **STRM** vertex data — separate code path from entity registration at `0x516B10`.

## Next Steps: Fresh Reboot with Conditional Breakpoint

The crash log does not preserve registers. On a fresh run with x32dbg:

```
bp 0x248BB6D
```

Set **condition** `ecx > 0x4000` on that breakpoint (break at `mov esi, ecx` before `imul`).

When triggered on the **bad** entity:
1. **ECX** ≈ `0x038E2840` (or similar huge index) — not the clamped `≤ 0x3FFF` path.
2. After `add esi, ebp`, **`cmp [esi+0x1E4]`** will AV at `esi+0x1E4` (`0x248BB7C`) if index is wild.
3. At **`0x516EF6`**, dump **`[entity+4..+0xC]`** as floats — expect NaN/Inf or byte-swapped garbage.
4. Map to patch block via loader stack / last-loaded path; use `extract_single_block.py` on that block.

When triggered on a **healthy** entity (e.g. `ECX = 0x26A`), floats look like normal world coords — continue.

## All fixes exhausted? (checklist before blaming swap)

| # | Check | Pass criterion |
|---|--------|----------------|
| 1 | `make build-ucfx-byteswap` after `convert.rs` / `ucfx_be_to_le.py` change | Binary newer than sources |
| 2 | Full `make dlc-port` (not old `vz-patch.wad` copy) | Port log: **0** byte-swap failures |
| 3 | Deployed SHA-256 matches build host | e.g. `certutil -hashfile output\data\vz-patch.wad SHA256` |
| 4 | `placement_extractor.py` on `dlc01_state_*` blocks | World-range XYZ, `boot_float: 1.0` |
| 5 | Block **12** Transform COMP (63 records) | Sample ≈ `(-90, -6, 200)` — verified sane on LE patch |
| 6 | Rename test: no `vz-patch.wad` | Game loads VZ (no DLC) — isolates patch vs retail |
| 7 | Bisect step 1: exclude block **0** only | **Done** — still crashes; terrain ruled out |
| 8 | Bisect step 2: exclude **4,12,15,16,17** | **Done** — still crashes; all `dlc01_state_*` ruled out |
| 9 | `make dlc-port-assets-only` (2196, no bootstrap) | Separates loader hook vs asset corruption |
| 10 | x32dbg `bp 0x248BB6D` / `ecx > 0x4000` | Dump `[entity+4..+0xC]` floats at `0x516EF6` frame |

If 1–5 pass and 6 still crashes → treat as **runtime** (bad entity pointer, wrong component read) or **non-placement**
block (mesh/bootstrap). Use bisect 7–9 to name the block; `extract_single_block.py` + `placement_extractor.py` on that block.

### Python vs Rust parity (2026-05-30 audit)

| Topic | Python `ucfx_be_to_le.py` | Rust `convert.rs` | Notes |
|--------|---------------------------|-------------------|--------|
| ECS `comp_map` | `0xE6B81A54` only | `0xE6B81A54` + `0x5647C35D` | Rust wider; world_entity uses ECS path |
| `flgs` typed | `0xE6B81A54` only | Both ECS type hashes | DLC state blocks are `0xE6B81A54` |
| Transform COMP | Always 42-byte | Always 42-byte | Match |
| Compact numeric stride | Full record (`_ECS_COMP_DEFAULT_STRIDE`) | `compact_default_stride()` full record | Fixed 2026-05-30b |
| `schm` stride | `4 + payload_stride` (Transform→42) | `4 + payload_stride` | Fixed 2026-05-30b in Python |
| ModelName | 8-byte swap | `convert_modelname_data` | Fixed 2026-05-30b in Python |
| `LaneData` hash | In numeric set + hash map | `0x6FA2F9D4` | Match |
| Unknown `__hash_*` | u32 sweep / numeric if stride | Blind `swap_u32_array` | Rare in DLC state |
| Non-ECS `flgs` | Blind u32 | Blind u32 (`convert_generic_bodies`) | — |
| Mesh `BNDS` / `STRM` | u32 / u32 sweep | Generic tag fallback u32 | Engine entity path uses Transform, not BNDS |
| Port path | N/A (not default) | `dlc_port` default | Optional `--byteswap-python-ecs` |

### Nuclear bisect: `--byteswap-python-ecs` (one-off full port)

When step **4** narrows to ECS-heavy blocks but Rust parity is suspect, rebuild the **entire** patch with Python byteswap for any block containing ECS **layer** / world_entity (`_block_has_ecs_layer`):

```powershell
cd C:\Users\Shadow\Desktop\notes-on-the-released-game
make build-ucfx-byteswap   # still used for non-ECS blocks via Rust default path
.venv\Scripts\python.exe tools\dlc_port.py `
  --dlc-rar "<path-to-DLC.rar>" `
  --source-wad game-files/pc-game-vz.wad `
  --output output `
  --byteswap-python-ecs -v
# Deploy output\data\vz-patch.wad — compare SHA; game test once
```

- **`--byteswap-python-ecs`**: Python `ucfx_be_to_le.byteswap_block` for ECS-layer blocks only; Rust for everything else.
- **`--byteswap-python-ecs-fallback`**: Rust first, Python on failure (slower; use if Rust throws on one block).
- **When to try:** After **4a + 4e** still crash **and** simulator/parity clean on Rust — **or** if **4e** implicates `dlc01_base` / contract layers and you need a same-night A/B without re-bisecting.
- **Give up on Rust-only** for tonight if: step 3 SHA deployed, step **2 re-run** on new WAD still crashes, **4e** excludes base+commonlocations and still crashes → run **one** `--byteswap-python-ecs` full port before deep half-split.

`tools/audit_ecs_byteswap_parity.py` diffs Python vs Rust on a **BE** `.block.bin`.

### Bisect commands (step 4 — tonight)

**Prerequisite:** step 3 done (SHA `97242b0a…` on build host **and** game `data\`). **Mandatory:** re-run **step 2** on this SHA before 4b/4c (old bisect on `1E6CA26C…` is invalid).

```powershell
cd C:\Users\Shadow\Desktop\notes-on-the-released-game
certutil -hashfile output\data\vz-patch.wad SHA256   # expect 97242b0a2e0c9f2e3a093dbb4ee24f9d368dc9a0bc4a4f55d300b11ae04f8755

# Index map for this WAD (save output)
.venv\Scripts\python.exe tools\trim_patch_wad.py -i output/data/vz-patch.wad -o NUL --list > patch-block-index.txt
.venv\Scripts\python.exe tools\inventory_dlc_patch.py --wad output/data/vz-patch.wad

$RULED = "0,4,12,15,16,17"   # steps 1–2; re-verify with --list-state-blocks

# Step 2 REPEAT on new WAD (confirm state blocks still not the fix)
.venv\Scripts\python.exe tools\trim_patch_wad.py `
  -i output/data/vz-patch.wad `
  -o output/data/vz-patch-step2-retest.wad `
  --exclude-indices $RULED -v
# Deploy as vz-patch.wad → game test (~5 min). Still crash → continue 4a.

# Step 4a — bootstrap only (index 2196 = scripts_vz) — DO FIRST tonight
.venv\Scripts\python.exe tools\trim_patch_wad.py `
  -i output/data/vz-patch.wad `
  -o output/data/vz-patch-no-bootstrap.wad `
  --exclude-indices "$RULED,2196" -v
# Deploy as data\vz-patch.wad

# Step 4b — lower half (keep 1–1099; also exclude ruled-out + bootstrap)
.venv\Scripts\python.exe tools\trim_patch_wad.py `
  -i output/data/vz-patch.wad `
  -o output/data/vz-patch-lo.wad `
  --keep-only-indices 1-1099 `
  --exclude-indices "$RULED,2196" -v
# Still crashes → culprit in 1–1099 (minus ruled-out). No crash → try 4c (upper half).

# Step 4c — upper half (keep 1100–2195; exclude ruled-out + bootstrap)
.venv\Scripts\python.exe tools\trim_patch_wad.py `
  -i output/data/vz-patch.wad `
  -o output/data/vz-patch-hi.wad `
  --keep-only-indices 1100-2195 `
  --exclude-indices "$RULED,2196" -v

# Step 4d — path cut: drop c3 cell blocks (substring must match PTHS paths from --list)
.venv\Scripts\python.exe tools\trim_patch_wad.py `
  -i output/data/vz-patch.wad `
  -o output/data/vz-patch-no-c3.wad `
  --exclude-indices $RULED `
  --exclude-path-substr blocks\dlc01\c3 -v

# Step 4e — placement layers NOT ruled out in step 2 (indices 3 and 5 on current WAD)
.venv\Scripts\python.exe tools\trim_patch_wad.py `
  -i output/data/vz-patch.wad `
  -o output/data/vz-patch-no-base.wad `
  --exclude-indices 3,5 -v
# Or path form:
#   --exclude-path-substr dlc01_base,dlc01_commonlocations

certutil -hashfile output\data\vz-patch.wad SHA256
```

| Bisect outcome | Meaning |
|----------------|---------|
| **No crash** without patch WAD | Patch-only (**confirmed** step 0) |
| **No crash** step 1 (no terrain) | N/A — user **still crashes**; terrain ruled out |
| **No crash** step 2 (no state) | N/A — user **still crashes**; five `dlc01_state_*` ruled out |
| **Still crashes** step 2 | Culprit in **~2191** other blocks — use step **4a–4c** |
| **No crash** 4a (no bootstrap) | **`scripts_vz` / bootstrap** suspect |
| **No crash** 4b or 4c (one half) | Culprit in the **other** index half |
| **No crash** 4e (no base/commonlocations) | **`dlc01_base` / `dlc01_commonlocations`** suspect |
| **No crash** `dlc-port-assets-only` | Bootstrap / hook, not port asset bytes |
| **Crash after step 3 re-port + step 2** | Runtime / ASET / block not covered by stride fixes — x32dbg + narrow 4c |

After step 3: `make build-ucfx-byteswap` → `make dlc-port` → repeat step 2 trim before step 4.

### x32dbg capture (2026-05-30 sessions)

| Field | Read AV (`0x248BB7C`) | Write AV (`0x248BBE2`, step 3) |
|-------|----------------------|--------------------------------|
| EIP | `0x0248BB7C` | `0x0248BBE2` |
| ECX | `0xFFC2F4EA` (garbage **cell** index) | `0x52` (slot index within bucket) |
| ESI | `0x03CE9E90` (implied: fault−0x1E4) | `0x03CE9E90` (garbage bucket) |
| Fault | `0x03CEA074` (= ESI+0x1E4) | `0x03CE9FD8` (= ESI+ECX×4) |
| EBP | `0x2060A290` (table base) | `0x2060A290` |
| Return | `0x00516EF6` ← `0x516C00` | same (MCP call stack) |

Earlier session: entity ptr `[esp+0x30]` at `0x516EE4` → `0x6091DF00` (freed by crash time — re-break at `0x248BB6D` with `ecx > 0x4000`).

At **`0x516EF6`**: dump **`[ptr+4]` `[ptr+8]` `[ptr+0xC]`** as floats. Healthy: Maracaibo-range metres; bad: NaN / huge / byte-pattern garbage.

## Static analysis (Ghidra) — EXE variants

To resolve the runtime crash VAs (`0x0248BB7C`, return `0x00516EF6` ← `0x516C00`)
against named functions, three EXE variants are available. The crash is observed in
the **cracked** EXE (the one that runs), so it is the authoritative decomp target; the
others are for clean cross-reference.

| Variant | Size (bytes) | MD5 | Notes |
|---------|-------------|-----|-------|
| v1.0 retail (pre-patch, pre-crack) | 17,122,568 | — | `C:\Users\Shadow\Desktop\Mercenaries2.exe`; SecuROM-packed |
| v1.1 retail (patched, **uncracked**) | 53,944,080 | `5b9976f162e050f4adcc51bb997ba97f` | `output/mercs2_v1.1_uncracked.exe` (built below) |
| v1.1 cracked (runs the game) | 53,482,288 | — | `…\Mercenaries 2 World in Flames\Mercenaries2.exe` |

The crack changes size by ~462 KB, so VAs may shift slightly between cracked and
uncracked; trust the **cracked** EXE for the observed crash addresses.

### Build the patched-but-uncracked v1.1 EXE (no crack)

The repo ships the official deltas in `tools/patches/` as `BSDIFF40` files. Apply only
the v1.0→v1.1 update (skip `mercs2_v1.1_securom_bypass.bspatch`). The bundled
`bspatch.exe` and pip `bsdiff4` (needs a C build) were both unavailable, so use the
pure-Python applier `tools/apply_bsdiff_py.py` (stdlib bz2 + numpy):

```powershell
.venv\Scripts\python.exe tools\apply_bsdiff_py.py `
  "C:\Users\Shadow\Desktop\Mercenaries2.exe" `
  "tools\patches\mercs2_v1.0_to_v1.1_update.bspatch" `
  "output\mercs2_v1.1_uncracked.exe" `
  --expect-size 53944080 --expect-md5 5b9976f162e050f4adcc51bb997ba97f
```

Verified: size + MD5 match the known-good v1.1. This is a clean retail v1.1 with **no
crack applied** — do not run it; it is a static-analysis reference only.

### Headless Ghidra runs

Ghidra 12.1 lives in `tools/ghidra_12.1_PUBLIC/`; it needs JDK 21+, provided portably
at `tools/jdk21/jdk-21.0.11+10` (set `JAVA_HOME`). Post-scripts under
`scripts/ghidra_scripts/`:

- `DecompileCrashFns.py` — decompiles the crash/loader VAs (`0x00516B10`, `0x00516C00`,
  `0x0051812F`, …) → `output/_ghidra/crash_decomp.txt`.
- `FindSpatialHash.py` — VA-independent: locates spatial-hash / asset-registration code
  by string xrefs → `output/_ghidra/<prog>_findings.txt`.

```powershell
$env:JAVA_HOME="…\tools\jdk21\jdk-21.0.11+10"
& "tools\ghidra_12.1_PUBLIC\support\analyzeHeadless.bat" "output\_ghidra\proj" mercs2 `
  -import "<EXE path>" -scriptPath "scripts\ghidra_scripts" -postScript DecompileCrashFns.py
```

(Run via PowerShell `&` direct call — a `cmd /c '… > log'` wrapper fails with
`> was unexpected at this time` due to leading-quote redirect parsing.)

### Ghidra decompilation results (cracked v1.1, 2026-06-01)

`output/_ghidra/crash_decomp.txt`. Two `.text` functions decompiled cleanly:

- **`FUN_00516b10`** (`0x00516b10`) — cell-index calc:
  ```c
  fVar4 = *param_1   - (float)DAT_0179c7bc;        // x - world_origin_x
  fVar5 = param_1[2] - (float)DAT_0179c7c4;        // z - world_origin_z
  iVar1 = (int)fVar4 >> (DAT_0179c7b4 & 0x1f);     // cell_x  (NOT clamped)
  iVar3 = (int)fVar5 >> (DAT_0179c7b4 & 0x1f);     // cell_z  (NOT clamped)
  *param_3 = DAT_0179c7b6 * iVar3 + iVar1;         // cell_index = grid_w*cell_z + cell_x
  ```
  The *size/radius* param is clamped to `0x3fff`, **but the position-derived cell_x /
  cell_z are not**. A NaN or out-of-range `x`/`z` therefore yields an absurd cell index.
- **`FUN_00516c00`** (`0x00516c00`, the captured return `0x00516EF6`) — spatial_hash_insert;
  calls `FUN_00516b10` then tail-calls `thunk_FUN_024e8f60` (in `.securom`).

The runtime crash VAs (`0x0248BB60`/`0x0248BB7C`) fall inside the **`.securom`**
block (`0x023e9000–0x037005f7`, executable) — the registration is reached through a
SecuROM-relocated thunk, so Ghidra left it undefined ("no function here").

**Conclusion — the live `ECX = 0xFFC2F4EA` garbage cell index is a direct consequence
of a corrupt entity position.** Because cell_x/cell_z are unclamped, a single DLC entity
with a NaN / out-of-Maracaibo-range `Transform` XYZ produces an OOB bucket index → the
access violation. The `schm` half-swap fix removed one corruption source (crash deferred
to a much later 408-asset batch), but at least one entity still carries a bad position.

**Next concrete step (offline, no game needed):** scan every converted DLC `Transform`
(and any position-bearing component) for non-finite floats or XYZ outside the Maracaibo
range (X ≈ ±3900, Y ≈ −103..+393, Z ≈ ±3900); whichever block has the outlier is the
remaining byte-swap/stride defect to fix in `ucfx_be_to_le.py` / `convert.rs`.

### Simulator position scan (2026-06-01) — corrupt-position theory NOT confirmed

`tools/wad_simulator` already implements exactly this check
(`crates/wad_simulator/src/placement.rs` → `is_valid_position` / `is_valid_quaternion`,
explicitly "would overflow cvttss2si and corrupt the hash table"). Ran on the full patch:

```powershell
cmd /c 'call "msvc\setup_x64.bat" && cd /d tools\wad_simulator && cargo build --release --bin wad_simulator'
tools\wad_simulator\target\release\wad_simulator.exe `
  --wad output\data\vz-patch.wad --base-wad game-files\pc-game-vz.wad   # → output/_ghidra/sim_vzpatch.log
```

Result: **Position violations: 0** and **ASET OOB: 0**. So no parseable `Transform`/`flgs`
record carries a NaN/Inf/out-of-bounds position. This **weakens the stored-bad-position
theory** — the runtime garbage cell index (`ECX = 0xFFC2F4EA`) is most likely produced
*downstream* (runtime-derived/parented position, scale, or a position-bearing component
the simulator's transform heuristic skips), not by a corrupt stored XYZ float.

Caveats: the scanned `vz-patch.wad` predates the `schm` half-swap fix, and
`validate_transform_components` only matches `transform*`/`position`/`placement`-named
components at a fixed 42-byte stride. What the scan **did** surface (candidates to chase
next): `layer` issues ×1285, `model` ×850, and structural defects in
`block[3192]`/`block[3367]` (sges `page_count` off-by-a-few + "bad magic" entry tables) —
status (DLC-specific vs base-benign) needs a base-only comparison run.

### Schema-driven scan refactor + retail oracle (2026-06-01) — stored positions cleared

The transform heuristic only checked name-matched `Transform`/42-byte-stride. Refactored
`placement.rs` to walk **every** COMP `info/schm/data` triplet, parse `ComponentSchema`
(`stride = 4 + payload_stride`), and validate all float fields (`F32`/`Vec3`/`Blob32`)
for NaN/Inf, world-bounds, and quaternion-unit (new advisory counter
`ecs_float_violations`). Now scans **589,335** records (was a small fraction).

First pass looked alarming — Position violations jumped 0 → **372** (Road `Vec3@0`,
PhysicalLink/PointLocation `Blob32@0`, …). But a base-only oracle run and the new
`tools/diff_ecs_violations.py` differential showed **PATCH−BASE = 0** and **BASE−PATCH = 0**:
the patch and retail produce byte-identical violation signatures. **The DLC introduces
zero stored position/float corruption relative to retail.**

The 372 are **retail-present false positives**: per `docs/ecs_components.md`, `Road`'s
world Vec3 endpoints are at `+0x10`/`+0x1C` (offset 0 is lane/ref data), and
`PhysicalLink`'s `Blob32@0` is physics-link data — not world positions, so blanket
world-bounds/unit checks mislabel them. Accordingly `ecs_float_violations` is **advisory,
not fatal** in the verdict; the trustworthy signal is the **differential vs a retail
oracle** (`tools/diff_ecs_violations.py`).

**Implication for the crash:** the garbage runtime cell index (`ECX = 0xFFC2F4EA`) is
**not** a corrupt stored position in any converted ECS component — those match retail
exactly. The bad world position is produced **downstream at runtime** (parented/derived
transform, an anchor/link resolved against a bad reference, or a hierarchy combine), or
in a block the simulator still can't fully parse (`block[3192]`/`block[3367]`). Next
investigation should target the runtime derivation (x32dbg at the deferred 408-asset
batch) rather than stored XYZ floats.

### Holdout-block sges decoder fix + DLC structural deltas (2026-06-01)

The large blocks the simulator couldn't parse (`block[3192]` 86 MB, `3398` 14 MB, `3239`
7.5 MB, `3367` 3.2 MB) were failing with sges `page_count` mismatch + "bad magic" entry
tables. Root cause: the Rust `decompress_sges` bounded each compressed segment's input by
the per-segment **u16 `compressed_size`**, which is unreliable for incompressible/large
segments (textures/terrain) — it can wrap or be 0, truncating the deflate input → short
output → misaligned entry walk. Fixed `mercs2_formats/src/sges.rs` to mirror
`tools/sges_decompress.py`: feed the inflater from each segment offset up to the **next
segment's offset** (cap 128 KB) and cap total output at the header's `total_uncompressed`.
Also added base/patch **source** to block labels (`blocks.rs`) for provenance.

Result: `page_count` mismatches 4 → **0**, "bad magic" thousands → **0**; blocks
`3192`/`3367`/`3239`/`3398` now decompress fully and walk cleanly (0 issues each). These
were **base** (retail) blocks — the streaming texture mip-size warnings dominate and are a
known cross-block streaming artifact (base has *more* than patch).

With the noise cleared, the patch−base differential surfaces the real **DLC-specific**
structural deltas (identical pre/post sges fix → not artifacts; all absent in retail):

| Patch-only delta | Count | Where | Read |
|------------------|-------|-------|------|
| `STRM decl stride 1712992 out of range [8,256]` | 334 | `block[367]`(81), 256/315/338/349/517/993… | `decl+4` reads a constant absurd stride → DLC STRM decl layout/byte-swap deviates from retail (mesh geometry, not placement) |
| `Havok packfile endianness byte = 0 (expected 1 = LE)` | 15 | `block[903]` `dlc01/vehiclenameanimgroup` | **embedded** Havok header `layoutRules` u32-swapped, **not** zero-padding (see below) |
| ECS `Name`/`ModelName` non-printable | 25 | various | string-field byte-swap corruption |

These are mesh/animation/string conversion defects — **separate from the spatial-hash
placement crash** (positions matched retail). But they are concrete "what we convert
wrong" leads: the Havok `+17` endian byte (`tools/ucfx_be_to_le.py` / `convert.rs` Havok
path) and the STRM `decl+4` stride are the next conversion targets. Differential tooling:
`tools/diff_ecs_violations.py` (ECS) and the normalized patch−base diff over
`ucfx_issues` in the JSON report.

#### Havok endian byte=0 root cause: embedded layoutRules u32-swap (NOT zero-padding)

Inspecting decompressed patch `block[903]`
(`dlc01/vehiclenameanimgroup_mercsbar_P000_Q3`): 18 full 8-byte Havok magics
(`57 e0 e0 57 10 c0 c0 10`). **3** are correctly converted top-level packfiles —
`layoutRules = 04 01 00 01` (ptrSize=4, **littleEndian=1**), with the `Havok-5.5.0-r1`
version string present. **15** are **embedded** header structures (no `__classnames__`/
`__types__`/version string nearby) with `layoutRules = 01 00 00 04` and `+17 = 0`.

`layoutRules` is **4 individual u8 fields** `[ptrSize, littleEndian, reusePadding,
emptyBaseClass]`. The Xbox 360 BE value is `04 00 00 01`; the correct LE conversion is
copy-as-is + set `littleEndian=1` → `04 01 00 01` (`ucfx_be_to_le.py` already does this
for the *outer* header at line ~586: `out[16:20]=be[16:20]; out[17]=1`). The 15 embedded
headers instead show `01 00 00 04` — exactly the **u32 byte-reversal** of `04 00 00 01`.
So the `__data__` swap (`_havok_swap_data_class_aware` / blind fallback) is treating each
embedded packfile header's `layoutRules` as a numeric u32 and reversing it, scrambling the
u8 fields (ptrSize→1, littleEndian→0). This is the exact "blind u32 swap corrupts mixed
u8/u32 layouts" pitfall from `AGENTS.md`.

**This rules out the zero-padding hypothesis:** the `+17` byte sits inside fully-populated,
structured header bytes (`…05 00 00 00 | 01 00 00 04 | 03 00 00 00 02…`), not appended
`0x00` padding, and the magic scan cannot match a zero run.

##### Fix implemented + validated (2026-06-01)

- **`tools/ucfx_be_to_le.py`** — new `_fix_embedded_havok_layoutrules(be, out, start, end)`
  run after the `__data__` swap in `_convert_havok_be_to_le` (both class-aware and blind
  paths). Scans the converted `__data__` region for the 8-byte packfile magic and restores
  each embedded header's 4-byte `layoutRules` verbatim from BE + sets `littleEndian=1`.
  Records a `havok_embedded_layoutrules_fixed` stat. Alignment-independent (magic is
  palindromic per u32 word). The blind-sweep tail-pad path is unaffected.
- **`tools/wad_simulator/crates/ucfx_byteswap/src/convert.rs`** — mirror
  `fix_embedded_havok_layoutrules(be, out)` + `HAVOK_PACKFILE_MAGIC`, called at the end of
  `convert_container` for BE inputs when `out.len() == container.len()`. Unit test
  `convert::tests::layoutrules_embedded_repair` (`cargo test -p ucfx_byteswap`).
- **`tools/wad_simulator/.../animation.rs`** — `consume_animation` now walks **every**
  Havok magic per body (was first-only) and reports the offset, so animgroup embedded
  headers are each checked.

Validation (no full WAD rebuild): pulled the real BE block
`vz/vehiclenameanimgroup_mercsbar_P000_Q3` from `game-files/xbox-vz.wad`
(`x360_dlc_io.parse_be_indx`/`decompress_be_sges`, offset = `page_index*0x8000`) and ran
`byteswap_ucfx_block` — all top-level Havok headers convert `04 00 00 01` → `04 01 00 01`
(LE=1), 0 remaining `!=1`. The embedded-header repair itself is covered by a direct
post-bug→post-fix test in both Python and Rust (`01 00 00 04` → `04 01 00 01`). The larger
610 KB `dlc01/` animgroup (source of the 15 embedded headers) lives in the DLC DOH, not
`xbox-vz.wad`; re-running the patch build will apply the same repair there.

## Relationship to Previous Crashes

This is a **different crash** from the PalSoundEngine/audio crash documented in
`docs/audio_crash_analysis.md`. That crash was caused by soundbank u8x4 byte-swap
corruption leading to a buffer overflow on the audio mixer thread. This crash is in
the main-thread asset loading path and relates to spatial data (positions/coordinates),
not audio.

Both crashes share the same root pattern: **byte-swap gaps in `ucfx_be_to_le.py`**
cause the engine to interpret corrupt data as valid, leading to downstream overflows.
