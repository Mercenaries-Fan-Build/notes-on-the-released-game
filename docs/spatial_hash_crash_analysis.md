# Spatial Hash Table Crash Analysis: Asset Registration Overflow

**Date**: 2026-05-28 (updated 2026-05-30c)  
**Primary crash sites**: `0x248BB7C` (read), `0x248BBE2` (write) — same function `0x248BB60`  
**Status**: OPEN — step 3 re-port (stride/flgs/Transform/guidmap) **still crashes** (`fault≈0x03CE9FD8`). Terrain + five `dlc01_state_*` ruled out. Next: **offline scan** + step **4a/4e** + optional Python-byteswap path blocks.

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

**Verdict:** Placement float / endian corruption **not** implicated on this WAD. If retail still faults @ `0x248BBE2`, prioritize **runtime bisect** (4a scripts @ 2195, 4e arena, ASET/ASI), not re-port for Transform/flgs.

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

### Next 15 minutes (copy/paste)

```powershell
cd C:\Users\Shadow\Desktop\notes-on-the-released-game
certutil -hashfile output\data\vz-patch.wad SHA256
make scan-patch-placements OUTPUT=./output
make bisect-patch-wad OUTPUT=./output

# 4a — bootstrap (30 s deploy test)
.venv\Scripts\python.exe tools\trim_patch_wad.py -i output/data/vz-patch.wad -o output/data/vz-patch-no-bootstrap.wad --exclude-indices "0,4,12,15,16,17,2196" -v

# 4e — base + commonlocations
.venv\Scripts\python.exe tools\trim_patch_wad.py -i output/data/vz-patch.wad -o output/data/vz-patch-no-base.wad --exclude-indices "0,4,12,15,16,17,3,5" -v

# Top placement layers (if scan agrees)
.venv\Scripts\python.exe tools\trim_patch_wad.py -i output/data/vz-patch.wad -o output/data/vz-patch-no-arena.wad --exclude-path-substr dlc01_base,speedcity,dlccon --exclude-indices "0,4,12,15,16,17" -v
```

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

## Log correlation (`dlc_enable_crash.log`, 2026-05-30)

Retail PC + `dlc_enable.asi` (bootstrap **OFF**, `CRASH_PATCH=1`, `REG_PATCH=1`, `GUARD=1`):

| Field | Value |
|-------|-------|
| Last Lua line | `[lua] Loading vz level with vz masterscript` |
| FATAL (earlier) | `exception 0xC0000005 at 0x0248BBE2 fault=0x03CEA014` |
| FATAL (2026-05-30 rebuild) | `exception 0xC0000005 at 0x0248BB7C fault=0x03CEA074` |
| Timing | ~4.3 s after VZ masterscript line (watchdog still alive) |

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
| 0 | No patch WAD | **Pass** (no crash) |
| 1 | `--exclude-indices 0` | **Fail** (still crash) |
| 2 | `--exclude-indices 4,12,15,16,17` | **Fail** (still crash) |
| 3 | Full re-port (stride fix); SHA `97242b0a…` | **Fail** (still `0x0248BBE2` / `0x03CE9FD8`) |
| 4a | `--exclude-indices 2196` or `dlc-port-assets-only` | — |
| 4b–4c | Half-split `1-1099` vs `1100-2195` (+ carry exclusions) | — |

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

## Relationship to Previous Crashes

This is a **different crash** from the PalSoundEngine/audio crash documented in
`docs/audio_crash_analysis.md`. That crash was caused by soundbank u8x4 byte-swap
corruption leading to a buffer overflow on the audio mixer thread. This crash is in
the main-thread asset loading path and relates to spatial data (positions/coordinates),
not audio.

Both crashes share the same root pattern: **byte-swap gaps in `ucfx_be_to_le.py`**
cause the engine to interpret corrupt data as valid, leading to downstream overflows.
