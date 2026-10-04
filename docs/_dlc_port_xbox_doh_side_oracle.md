---
status: current
evidence: proven
date: 2026-10-03
scope: `dlc_port --xbox-doh-oracle <path>` — Xbox 360 DOH side-oracle resolution for PS3-side `convert_block` rejections
inputs:
  - tools/wad_simulator/crates/dlc_port/src/xbox_doh_oracle.rs
  - tools/wad_simulator/crates/dlc_port/src/main.rs
  - tools/wad_simulator/crates/dlc_port/tests/xbox_doh_oracle_integration.rs
  - scratchpad/dlc01_pipeline/ps3_dlc01_be.scff
    sha256: cc58b68d614786ebbab79e0129a6def0c31adebdc897b2c623892935ab5fca00
  - output/_scratch/dlc01.doh (Xbox 360 oracle)
    sha256: 5b0c222d925e8c85000a925262e2b789fbf8c3e476d3d89e5935c7c018deb3ae
---

# `dlc_port --xbox-doh-oracle` — Xbox-DOH side oracle for PS3 compact-decl blocks

End-to-end spec of the opt-in flag that closes the 470-block PS3 descriptor-walker
gap by sourcing each rejected block's PC-converted body from the Xbox 360 DOH at
matching primary `name_hash`.

## Verdict

With `--xbox-doh-oracle <xbox-doh-path>` set, every PS3 block the UCFX walker
refuses as `PS3 compact decl detected` is resolved against the Xbox DOH and
drops the Xbox-DOH's LE body into the output WAD in its place. The flag is
**opt-in**: without it, `dlc_port` behaves identically to its pre-change form.
On the retail DLC01 inputs:

| Metric | Baseline PS3-only (`--x360-stfs ps3.scff`) | PS3 + `--xbox-doh-oracle dlc01.doh` | Xbox-only (`--x360-stfs dlc01.doh`) |
|---|---:|---:|---:|
| PS3-direct blocks (walker converted PS3 bytes) | 1747 | 1747 | 2188 |
| Xbox-DOH side-oracle blocks | 0 | **470** | 0 |
| Skipped (wavebank+unluac, out of scope) | 478 | 8 | 8 |
| Converted blocks in output WAD | 1747 | **2217** | 2188 |
| ASET rows routed by content | 3744 | **4403** | 4403 |
| ASET rows dropped (no shipped owner) | 1597 | **938** | 938 |
| ASET LOD rungs sentinelled to coarse tier | 629 | **8** | 8 |
| `aset_refcheck` | OK | OK | OK |
| `wad_simulator` ASET verification | 3744 / 3744 | **4403 / 4403** | 4403 / 4403 |

The oracle brings the PS3 port to **ASET-resolution parity with the pure
Xbox port** (same 4403 routed / 938 dropped / 8 sentinelled) while
shipping 29 additional PS3-only block paths the Xbox DOH does not carry
(2217 vs 2188 blocks).

The 8 remaining skips are the 7 wavebank bodies + 1 unluac block shared with
the Xbox DOH input (`docs/_dlc01_pipeline_readiness.md` §4) and are out of
scope for this oracle — they fail on both platforms with the same error.

## Flag

```
dlc_port --x360-stfs <ps3-be-scff> \
         --xbox-doh-oracle <xbox-doh|stfs|rar-extracted-doh> \
         -o <output.wad>
```

- `--xbox-doh-oracle <PATH>` accepts any input `load_stfs_or_doh` understands:
  a raw Xbox 360 DOH, an STFS container, or a BE SCFF already extracted from
  an STFS. The same loader the primary `--x360-stfs` flag uses.
- The flag is **only effective when the main input is a PS3 BE SCFF**. The
  oracle is a no-op on a pure Xbox 360 input (the walker converts every block
  cleanly), but passing it does no harm and is not refused.
- The flag has no effect without `--x360-stfs`. `--x360-rar` is not supported
  as the main input in this mode; extract the DOH out of the RAR separately.

## Semantics

1. **Load the oracle once, eagerly.** `XboxDohOracle::load` parses the Xbox
   DOH's FFCS/INDX/PTHS, decompresses every block through the same two-path
   decoder the main loop uses (BE `segs` or XFCU passthrough), converts
   BE→LE through `ucfx_byteswap::convert_block`, and indexes the result by
   the LE entry table's **primary (first-entry) `name_hash`** — the engine's
   own identifier for the block's main asset. A bad path, missing INDX, or
   container-level parse failure fails the whole run before any block is
   written.

2. **Dispatch per PS3 block.** The main loop decompresses + converts the
   PS3 block exactly as before. On a `convert_block` success the PS3 bytes
   go to the output ("ps3-direct"). On a `convert_block` error:
   - If `is_ps3_compact_decl_rejection(err)` is `true` AND the oracle is
     loaded: extract the PS3 block's primary `name_hash` from its BE entry
     table (BE u32 at offset 4), look it up in the oracle, and clone the
     oracle block's LE body into the output ("xbox-doh-side-oracle").
   - If the oracle is loaded but the hash is NOT in it: **fail the whole
     run** with a message naming the hash, the PS3 block path, and the
     Xbox DOH path. No silent fallback.
   - If `is_ps3_compact_decl_rejection(err)` is `false` (any other error:
     wavebank schema, `unluac.jar not found`, truncated UCFX, …): leave
     the historical skip path untouched. These errors are shared with the
     Xbox DOH input and are out of this oracle's scope.
   - If the oracle is **not** loaded (`--xbox-doh-oracle` absent): leave
     the historical skip path untouched. The flag is opt-in.

3. **CSUM + ASET layout is the output WAD's.** The per-block UCFX CSUM
   trailer that `convert_block` writes is already in the oracle's LE body;
   nothing rewrites it. The output WAD's top-level CSUM header is rebuilt
   by `build_patch_wad_multi` using the PS3 side's `csum_value` /
   `csum_meta` as it would on any other `dlc_port` run — the oracle hit
   path does not touch WAD-level CSUM. The INDX tier byte is inherited
   from the PS3 side's `packed_field >> 24`, since the output WAD lives in
   the PS3 output's address space; the page count is recomputed from the
   actual LE body size.

4. **ASET routing stays content-based.** The main loop builds `hash_owner`
   from the entries of every converted block (both PS3-direct and
   Xbox-DOH-sourced) and routes each PS3-side ASET row to the block that
   owns its `asset_hash`. An oracle-sourced block contributes its entries
   to this map the same way a PS3-direct block does; the PS3-side ASET
   rows for assets that lived in a rejected PS3 block therefore still
   route correctly against the Xbox-DOH-sourced body.

## Loud-fail contract (no silent fallback)

Every failure mode fails the whole run with a message naming the specific
inputs:

| Trigger | Exit | Error message |
|---|---:|---|
| Oracle path missing / unreadable | 1 | `xbox-doh-oracle: open <path>: <os error>` |
| Oracle file not a parseable FFCS container | 1 | `xbox-doh-oracle: open <path>: Unknown file format: [<bytes>]` |
| PS3 block refused, primary `name_hash` unreadable (BE entry table truncated) | 1 | `block N (<path>): descriptor-walker refused as PS3-compact-decl but the BE entry table is unreadable, so no primary name_hash is available to look up in the Xbox DOH oracle at <xbox-path>. convert_block error: …` |
| PS3 block refused, primary `name_hash` not in Xbox DOH | 1 | `Xbox-DOH side-oracle miss: PS3 block [N] <path> primary name_hash=0x…. is not in the Xbox DOH container at <xbox-path>. …silent fallback is forbidden…` |

The output WAD is either 100 % resolved (every PS3-compact-decl rejection
resolved against the oracle) or does not exist. On retail DLC01 inputs the
Xbox DOH resolves all 470 rejections (0 misses).

## Lookup key — primary `name_hash`, not block path

PS3 and Xbox block paths are nearly-identical but diverge in two ways
(`docs/_dlc01_pipeline_readiness.md` §4):

- 29 PS3-only block paths plus some Xbox-only paths.
- Many `_P003_Q0` ↔ `_P001_Q2` / `_P002_Q1` LOD-tier naming shuffles.

The primary (first-entry) `name_hash` is the engine's own identifier for a
block's main asset and is cross-platform-identical. Keying on it rather
than the path lets the oracle resolve e.g. `blocks\dlc01\dlc_al_veh_tank_m1a1_P002_Q1.block`
→ `blocks\dlc01\dlc_al_veh_tank_m1a1_P000_Q3.block` (same tank, finer LOD on
PS3) without a path normalisation table.

The implementation reads the key BE from the PS3 side (BE u32 at offset 4
of the decompressed block) and LE from the Xbox side (the LE entry table
`convert_block` emits). First-wins on a hash collision inside the Xbox DOH,
matching the engine's name-registry semantics (`memory/no-arbitrary-hashes.md`).

## Retail end-to-end run

Scratchpad artifacts under
`C:/Users/Shadow/AppData/Local/Temp/claude/c--Users-Shadow-Desktop-notes-on-the-released-game/3daa7290-1887-4d90-a52c-94355e911851/scratchpad/dlc_port_side_oracle/`:

- `02_dlc_port_run.log` — full retail run.
- `04_verify.log` — `aset_refcheck` + `wad_simulator` on the output WAD.
- `05_baseline_no_oracle.log` — PS3 input with no `--xbox-doh-oracle`
  (behaviour identical to pre-change build).
- `06_xbox_only_baseline.log` — Xbox DOH input alone (behaviour identical
  to pre-change build).
- `07_loud_fail_probe.log` — oracle pointed at a non-DOH file; fails
  with exit 1 and names the bad input.
- `ps3_dlc_patch_with_xbox_oracle.wad`, sha256
  `7D02298F50BEBAD703D53897862A38CA6FBAF7984A187F69E349AD0883C5E222`,
  273,121,280 B / 260.5 MB. 2217 blocks (1747 ps3-direct + 470
  xbox-doh-side-oracle). `aset_refcheck` reports all 4403 LOD refs resolve;
  `wad_simulator` reports 4403 / 4403 ASET verified, 0 misrouted, 0 ghost.

Timing: 27.97 s for the full retail run (loading + converting both
containers + ASET resolution + sges round-trip verify on every block +
WAD assembly), on this host.

## Interactions

- Pre-existing `dlc_port.py` and the Rust `dlc_port` baseline flow are
  untouched. Running without `--xbox-doh-oracle` is byte-identical to the
  pre-change build (`05_baseline_no_oracle.log`, `06_xbox_only_baseline.log`).
- The crate still ships `[[bin]] dlc_port`; a thin `[lib]` was added so
  the integration test can drive the oracle lookup without launching the
  binary. The binary's control flow is unchanged for the baseline paths.
- The `convert_decl_ps3_compact` loud-fail arm in
  `mercs2_formats::be_to_le::convert` (sister session's work at
  `tools/wad_simulator@38119bc`) is the signal this oracle anchors on;
  its exact error phrase is locked by
  `xbox_doh_oracle::PS3_COMPACT_DECL_MARKER` and asserted in both unit and
  integration tests.
