# World-load streaming livelock (post-crash) — analysis & handoff

Status as of this session: the **world-load crash `0x0084DD5B` is FIXED and committed**; a **separate texture-streaming livelock** now blocks completing the load. This doc records what's proven, what's ruled out, the dead-ends (so we don't repeat them), and the one un-contradicted lead.

---

## 1. The crash (SOLVED — committed)

**`0x0084DD5B` world-load AV.** Root cause: the **MTRL material chunk's `u16` texture-count** (on-wire offset 106) was scrambled by the **Rust converter's blanket `u32` swap** — `ChunkTag::Mtrl` had no arm and fell through to `swap_u32_array`, which transposes that `u16` count with its neighbour. Engine parser **`FUN_00858790`** reads the count as a `u16` and writes `count` 12-byte `{hash, 0xF011157A, 0}` records into a **fixed 10-slot embedded array at `material+0xac`** → a valid count (≤10) becomes garbage (e.g. `4 → 0x0400`) → overrun into the pool arena → AV.

MTRL on-wire layout: `[u32/f32 × 26 = 104B][u16 flags @104][u16 count @106][u32 hash × count @108][u32 × 2 tail]`.

**Fix (committed):** per-field `convert_mtrl` in `tools/wad_simulator/crates/ucfx_byteswap/src/convert.rs` (`ChunkTag::Mtrl` arm) + `_convert_mtrl_body` in `tools/ucfx_be_to_le.py`, with Rust tests (`mtrl_u16_count_survives_swap`, …). **Verified:** crash gone, ~2,872 textures stream, free-list scan clean.

---

## 2. The streaming livelock (OPEN)

After the MTRL fix the load reaches the **final texture-streaming stage** (render targets are being created — `DebugString` shows water `_pNormalSurf`/`_pFoamMaskSurf` and cloud `mCloudSurfRT`/`mCloudOutRT`), reaches ~392k allocations, then **wedges**:

- **Main thread** spins the **loading-screen frame loop `FUN_004c9740`** (called from loader frame `FUN_004c0ec0`); it also drives the **texture-stream completion loop @ `0x004b1180`** over a ring at `[0x0117662C]`. The ring **never drains** — `count` stays `1`, read index cycles/wraps (`2872 → 2486 → 4697 …`). This is a true livelock, not slow load.
- The repeating big allocs in poolguard's timeline (`32768`/`196608`/`262144` from `FUN_00875b00`/`FUN_006955d0`/`FUN_00408ad0`) are **per-frame render scratch of the loading loop**, NOT the stuck texture re-loading (corrected mid-session).

### Ruled out
- **Heap corruption** — poolguard free-list scan: "no out-of-arena links found." Its **canary trips are false positives** on legit `.rdata` module pointers (`0x00BAB160`, `0x00BACB38`) that land in reused freed blocks.
- **Missing files** — `asset_miss_probe` (hooks `NtCreateFile`/`NtOpenFile`) logs **only Windows-system noise** (`*.mui`, `CryptnetUrlCache`, `plugins\`, `update\`), **none from the `0x876400` worker**. The `STATUS_OBJECT_NAME_NOT_FOUND (0xC0000034)` seen on the *main* thread is that stale OS probing, not a game-asset miss.

### The one un-contradicted lead
**The streaming worker's `lastStatus = STATUS_INVALID_PARAMETER (0xC000000D)`.** A streaming/D3D op is being handed a **bad parameter** — most plausibly a `CreateTexture`/surface call rejecting the stuck texture's **converted dimensions / format / mip-count** (consistent with the active `CREATED SURFACE` D3D calls). The worker `FUN_00876400` (thread `startAddr 0x876400`, busiest game thread) is a generic job-dispatcher and was **idle when paused** (only its own loop frames on the stack — no active callback), so pausing rarely catches the failing op.

### The stuck texture
- Runtime **ref-hash `0x5FF5980D`** (not in the 53k rainbow table → DLC-only name), **DXT5**, ~**512×512** (256 KB surface), object vtable `0x00baa860`.
- Failed completion gate: `(texture.flags>>6 & 7) - 1 == manager[+0x5A]`, observed **3 vs 2**. Target is produced by `FUN_008759c0` (`node[+0x5A] = src[+0xA]`); "fully ready" target is `3` (`FUN_008739e0`).

---

## 3. Dead-ends (do NOT re-chase)
1. **Mip off-by-one in the completion gate** — the consumer loop exits only when the ring *drains*, which depends on the producer; fixing the consumer-side count does nothing.
2. **Asset-miss / missing file** — `asset_miss_probe` is clean of game assets.
3. **StreamPage truncation / mip-count over-claim** — applied a non-over-claiming fix to `convert_streamed_body`'s `StreamPage` arm (`convert.rs`, ~line 1500: claim `linear_mip_chain_size`-capped resident count instead of full `mips`); **rebuilt + re-deployed → did NOT resolve the livelock.**
4. **Worker spinning on a missing asset** — worker is idle; its status is `INVALID_PARAMETER`, not `NAME_NOT_FOUND`.

### Working-tree note
- **MTRL fix = committed (real).**
- **StreamPage resident-count edit = in working tree, UNVERIFIED.** Principled (the old `Some((body, mips))` does over-claim) but it did not fix the livelock and is not oracle-validated. **Review / oracle-test or revert before shipping.**

---

## 4. Recommended next step
**Catch `INVALID_PARAMETER (0xC000000D)` at its source.** A conditional breakpoint or a probe (extend `asset_miss_probe` to hook the streaming read / `NtReadFile` / the D3D `CreateTexture` path) that dumps the **bad parameter + the texture identity** the instant a streaming/D3D op returns `0xC000000D`. That names the exact malformed field deterministically — same one-shot strategy that nailed the MTRL count — instead of pausing blind.

## 5. Key references for the next session
| Symbol | Role |
|---|---|
| `FUN_004c9740` | loading-screen frame loop (spins during the wedge) |
| `FUN_004c0ec0` | loader frame (calls `FUN_004c9740`) |
| `0x004b1180` + ring `[0x0117662C]` | texture-stream completion loop (never drains) |
| `FUN_00876400` (`startAddr 0x876400`) | streaming worker / job dispatcher |
| `FUN_008759c0` | target producer: `node[+0x5A] = src[+0xA]` |
| `FUN_008739e0` | streaming manager; target `== 3` = ready |
| `FUN_006955d0`/`FUN_00408ad0`/`FUN_00875b00` | 192K/256K/32K per-frame render scratch |
| vtable `0x00baa860` | stuck texture's class |

Full decompile corpus: `output/_ghidra/all_functions_decomp.txt` (regen via `scripts/ghidra_scripts/DecompileAllFunctions.java`, headless analyzeHeadless). Tools: `tools/poolguard` (pool/corruption probe), `tools/asset_miss_probe` (file-open tracer, hardcodes `WORKER_VA = 0x00876400`).
