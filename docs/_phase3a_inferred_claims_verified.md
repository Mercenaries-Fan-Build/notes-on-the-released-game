# Phase 3.A — INFERRED-tag resolutions

**Status:** current · **Evidence:** proven for completed items; blockers noted for the rest

Follow-up pass on the four `INFERRED` tags called out in Phase 2 (see
[`.claude/plans/engine-divergence-phase3.md`](../.claude/plans/engine-divergence-phase3.md)
item A). Each item below is either `PROVEN`, `PROVEN WITH SCOPE` (verifiable set covered,
remaining set blocked on content), or `BLOCKED` (needs artifact we don't have).

## A.1 — PS3 shader TOC as (VS, PS) pairs

Phase 2 §2 inferred the PS3 shader TOC entry stride encodes `(vs_hash, vs_offset,
ps_hash, ps_offset)` based on offset-delta consistency. Verifying would require locating
the shader-loader function in a PS3 Ghidra decomp.

**Status: BLOCKED.** PS3 EBOOT Ghidra decomp is still pending on the user's local
machine (noted in commit history during the pending-decomp session). The retail
`output/_ghidra_ps3_retail/` directory doesn't yet exist with a completed run.
`output/analysis/cross_platform/ps3_eboot/EBOOT.elf` is in place; running
`./scripts/ghidra_analyze_ps3_retail.sh` from a workstation with the ~6h analysis budget
is the next concrete step.

## A.2 — Codec 0x05 = XMA2 across every retail Xbox wavebank

**Phase 2 claim**: proven only for block 3187 (one wavebank, `wpn_shared`). Open: do
all 95 retail Xbox wavebanks hold codec 0x05 XMA2 data?

**This pass**: swept all 95. Sweep harness at `scratchpad/xbox_xma2_sweep.py`; raw
decompressed blocks at `scratchpad/xbox-wb-sweep/`.

**Method per wavebank:**
1. Extract raw decompressed block via `lua_chunk_scan --extract-block N --dump-raw`.
2. Walk the outer 27-entry UCFX TOC (format proven in Phase 2 §3.7) to find the
   wavebank sub-chunk whose `type_hash == 0xF753F6D0` and `name_hash` matches the ASET
   row's `asset_hash`.
3. Parse the sub-chunk's `atad` row to find the wavebank body offset+size.
4. Parse the wavebank header (version 0x1D LE, bank_hash BE, count BE u16) and all 36-byte
   records (BE, with `data_size@+0x0C`, `decoded_sample_count@+0x10`, record-relative
   `data_offset@+0x20`).
5. For every record with codec `0x05` (i.e., `fmt == 0x05` at byte `+0x06`):
   - Verify `data_size` is a multiple of 2048 (XMA2 packet alignment).
   - Walk each 2048-byte packet, decode its XMA2 header (frame_count ≤ 63, metadata ≤ 3,
     end-of-stream sentinel `fc=0 fob=0x7FFF` allowed).
   - Compute `sum(frame_count) × 512 samples` and compare to the record's
     `decoded_sample_count` field. XMA2 produces 512 PCM samples per frame per channel;
     the record's `decoded_sample_count` tracks the decoded PCM output.
   - Pass criterion: `|predicted - decoded_sample_count| ≤ 512` (one-frame tolerance for
     EOS sentinel rounding).

### Result

| Category | Count | XMA2 fingerprint pass |
|---|---:|---|
| Embedded wavebanks (`kind=0`) | **93** | **2,043 / 2,043 records (100%)** ✅ |
| Streamed wavebanks (`kind` ≠ 0) | 2 | 0 / 165 records (data external — see below) |
| **Total** | **95** | **2,043 / 2,208 (92.5%)** |

**All 2,208 records across all 95 wavebanks use codec `0x05`.** Codec is uniform; no
other codec id appears in retail Xbox NTSC-US wavebanks.

**All 2,043 records in the 93 embedded wavebanks pass the strict XMA2 fingerprint**
(packet alignment + `sum(fc) × 512 ≈ dec_samples` within 1-frame tolerance).

**Verdict**: codec `0x05` = XMA2 is **PROVEN for every retail embedded Xbox wavebank**.

### The 2 "failures" are streamed banks (expected — data lives externally)

The 2 wavebanks that fail the fingerprint are the streamed ones:
- **`MUSIC`** at block 3126 — header carries `music.pws` as its 16-byte .pws name field.
- **`Ambience`** at block 3187 — header carries `ambience.pws` as its .pws name field.

Both have `kind` ≠ 0 (streamed), and their records' `data_offset` fields point into
external `.pws` files (same mechanism as PS3's `MUSIC.PWS` / `AMBIENCE.PWS` and PC's
`music.pws` / `ambience.pws`). The 165 "failures" are my sweep trying to read XMA2
packets at absolute block offsets that live outside the block — not codec disagreement.

**To verify codec 0x05 = XMA2 for the 2 streamed banks** we'd need the Xbox retail disc
image's streaming audio files (Xbox equivalent of `music.pws` + `ambience.pws`). The
JTAGRip extract in `game-files/Mercenaries 2 World in Flames (NTSCU)[NTSCJ) (JTAGRip)/`
contains only the WADs, not the Xbox streaming .pws. **BLOCKED on Xbox disc image**.

### Secondary finding: kind-field decode on Xbox streamed banks

Both streamed Xbox wavebank headers at offset `+0x08..+0x0B` hold the bytes `00 91 01 00`
(MUSIC) and `00 14 01 00` (Ambience). My initial decode as `(count u16 BE, kind u16 BE)`
gave `count=145/20` ✓ but `kind=256`, which doesn't match the documented `0 embedded /
1 streamed` enum. Reading those same 2 bytes `01 00` as **u16 LE** gives `kind=1` ✓.
Xbox wavebank fields are **not uniformly big-endian** — count is BE but kind is LE (or
the field at `+0x0A` is a `(flag_u8, pad_u8)` pair where byte `+0x0A == 1` signals
streamed). Either way, the practical effect for a parser is "treat non-zero `+0x0A` byte
as streamed" and read the `.pws` name from `+0x18`.

## A.3 — Pre-first-blob 0x57C-byte padding = 2048-byte XMA2 alignment

**Phase 2 claim** (inferred): the ~0x57C-byte gap between the end of the wavebank record
table and the start of the first XMA2 blob is 2048-byte alignment padding. Reasoning:
XMA2 packets are 2048-byte-aligned and the engine aligns the blob section to packet
boundaries.

**This pass**: tested `(first_blob_abs - body_abs) & 0x7FF == 0` on every wavebank.

| Category | Count | First-blob 0x800-aligned (XMA2 packet alignment) |
|---|---:|---|
| Embedded wavebanks (`kind=0`) | 93 | **93 / 93 (100%)** ✅ |
| Streamed wavebanks (`kind` ≠ 0) | 2 | N/A (data external) |

**Verdict**: 0x800-alignment of the first XMA2 blob **PROVEN for every embedded Xbox
wavebank**. The pattern is universal; the 0x57C-byte padding observation generalises.

## A.4 — PS3 chicon002 behaviour under runtime

Phase 2 §3.5 and `docs/_ps3_base_game_lua_diff.md` §4 proved the bytecode delta: PS3
ships an older `chicon002.lua` missing `_GetFlag` destruction-event callbacks that PC
and Xbox both carry. Observing the gameplay effect requires running the Chinese
Contract 002 mission on PS3 (RPCS3 or hardware) and checking the specific callback miss.

**Status: BLOCKED on runtime access.** The specific mission to boot:
- Faction: `chi` (Chinese PMC)
- Mission: `chi002` (contract 002)
- Expected observable: when the player destroys the mission's bridge / depot / HQ, the
  PS3 build fails to flag the destruction event via `self:_GetFlag("BridgeDestroyed_New")`
  et al., so dependent dialog / score / completion callbacks don't fire. PC and Xbox
  behave correctly.

Setup: load the mission, trigger each destruction event, compare on-screen state /
dialog / HUD updates to a PC playthrough. No code change needed to test — bytecode
difference is already proven.

## Summary

| Item | Status | Notes |
|---|---|---|
| **A.1** PS3 shader TOC (VS,PS) pairs | **BLOCKED** | needs PS3 Ghidra decomp run |
| **A.2** codec 0x05 = XMA2 universally | **PROVEN for 93/93 embedded**; blocked for 2 streamed | needs Xbox retail streaming .pws |
| **A.3** 0x800 XMA2 alignment universally | **PROVEN for 93/93 embedded**; N/A for streamed | — |
| **A.4** PS3 chicon002 runtime behaviour | **BLOCKED** | needs RPCS3 or PS3 hardware |

Two of the four `INFERRED` tags from Phase 2 are now `PROVEN` at the retail-sweep level.
Two remain blocked on external artifacts (PS3 Ghidra output, Xbox retail streaming
audio) and runtime access (PS3 game execution).

Artefacts produced this pass:
- `scratchpad/xbox_xma2_sweep.py` — the sweep harness.
- `scratchpad/xbox-wb-sweep/block_*.bin` — all 95 extracted Xbox wavebank blocks.
- `scratchpad/xbox-xma2-sweep4.log` — full per-wavebank verdict table.
