# PS3 ↔ Xbox DLC Lua — structural equivalence (verified)

**Date**: 2026-10-02 · **Tool**: `tools/wad_simulator/target/release/lua_structural_dump.exe` ·
**Status**: proven. Memory note [[ps3-dlc-crack-and-klicensee]] claimed "36/36 Lua identical";
this run upgrades that from "byte-identical" to **structurally identical, 36/36** (13 are
additionally byte-identical in the raw block; the other 23 differ only in trailing
non-Lua filler, not in bytecode).

## PS3 DLC bytecode — provenance

```
pkg-unpack --pkg game-files/1ntHdj11R8gYK1qjpRcpRGHI3bEQBhL6i616GVXFV8bh78m4U6iSVyAiYJ4q9RNv6JnuURsk8CN8WWTLSdJU9cT631f4tHSHg7XBs.pkg
              -> USRDIR/DLC/DLC01/DLC01.EDAT         (271,354,672 B)
edat-decrypt --edat DLC01.EDAT --out ps3_dlc01.wad   (271,089,664 B SCFF BE,
                                                      sha256 cc58b68d61...5fca00)
```

Both tools are the Rust `ps3_dlc_crypt` CLI (uses recovered klicensee
`1896170d…fb79`). Then the PS3 inner WAD and the Xbox `output/_scratch/dlc01.doh`
were walked identically — same `parse_be_ffcs` + `_decompress_be_block` path — and
each `\x1bLua` chunk extracted to its own `.luac` file.

**Finding (block topology)**: identical on both platforms —
- block index `464`
- block path `blocks\dlc01\resident_P000_Q3.block`
- 36 `\x1bLuaQ` chunks per block, 0 LuaQ chunks in any other block.

## Lua header — matches on all 36 pairs

```
1b 4c 75 61 51 00 00 04 04 04 04 00
= Lua 5.1 "Q",  endian=big, int=4, size_t=4, instr=4, number=4, is_integral=false
```

Both platforms share this header exactly — the structural-dump `header` object
compares equal on every pair. **PS3 did not re-emit the DLC through a
little-endian or 8-byte-number compiler; it ships the Xbox BE/float build.**

## Classification

| Class | Count | Meaning |
|---|---:|---|
| **BYTE-IDENTICAL** | **13** | raw-extract sha256 matches — same chunk and same trailing padding |
| **STRUCTURAL-IDENTICAL-MODULO-SOURCE-PATH** | **23** | `lua_structural_dump` JSON equal except the `.path` field (the tool's record of its argv input); Lua `header`+`main` prototype trees compare equal |
| **REAL-DIVERGENCE** | **0** |  |
| xbox-only | 0 |  |
| ps3-only | 0 |  |

### The 23 "structural-identical" pairs — what actually differs

For every one of those 23 the only JSON diff is `.path` (the input file path on
disk, platform-dependent only because the two extracts live in different folders).
`header` and `main` compare equal. So **the Lua VM would see the same bytecode on
both platforms**.

Why isn't the raw sha256 equal, then? Our extractor bounds each chunk by "next
`\x1bLua` marker or end-of-block" (same rule `decompile_dlc_lua.py` uses). When
two LuaQ chunks pack back-to-back in the compressed block, that bound is tight
and the raw bytes match → BYTE-IDENTICAL. When there is non-Lua filler between
them, the extractor includes that filler, and the filler differs between
platforms. The trailing-byte dump shows the filler is a **Havok-5.5 packfile
fragment** (ASCII `"\x02rHavok-5.5."` right after the diverging byte):

```
xbox tail @ divergence :  00 01 00 00 00 03 00 00 00 02 00 00 00 00 00 00 00 00 00 00 02 72 "Havok-5.5."
ps3  tail @ divergence :  01 01 00 00 00 03 00 00 00 02 00 00 00 00 00 00 00 00 00 00 02 72 "Havok-5.5."
                          ^^ one bit flip in the Havok flag byte, not Lua
```

So the divergence is in Havok packfile data living in the same compressed block,
not in Lua.

## Per-pair classification (36)

**BYTE-IDENTICAL (13)** — raw-extract sha256 matches:
`dlc01_assets`, `dlc01_player`, `dlc01_pmcinterior`, `dlc01_starterdata`,
`dlccombometer`, `dlccon001`, `dlccon002`, `dlccon004_cash`, `dlccon004_tower`,
`dlccon004a`, `dlcspeedtimer`, `dlctest01_all_sound`, `tankbusterpickup`.

**STRUCTURAL-IDENTICAL-MODULO-SOURCE-PATH (23)** — `header`+`main` prototype
trees equal, only tool-side `.path` differs:
`ammobay`, `dlc01`, `dlc01_aliases`, `dlc01_briefing`, `dlc01_hero`,
`dlc01_missionhub`, `dlc01_mrxguihudradar`, `dlc01_mrxguipda`,
`dlc01_pausescreen`, `dlc01missionflow`, `dlc_moonpatrol`, `dlc_mrxguidialogbox`,
`dlc_mrxtankbuster`, `dlccon003`, `dlccon004_timer_pickup`, `dlccon050`,
`dlccopterdrop`, `dlcescalation`, `dlctest01_soundbootstrap`,
`dlcvehiclestrike`, `emplacedtowvendor`, `repairbay`, `speedtools`.

## Modder-facing takeaway

**For a mod intended to ship as both Xbox and PS3 DLC content, there is nothing
platform-specific in the DLC Lua build step.** The retail PS3 package was built
from the same compiled, debug-stripped BE-float Lua 5.1 chunks the Xbox DLC ships;
same compiler, same stripping, same byte-order, same 32-bit float number — not
re-compiled under a PS3-flavoured host. Any mod that targets the DLC Lua layer
produces one artifact that drops into both platforms. The ~34% average "shared
prefix" within the raw extraction is a *WAD-framing* artifact (Havok packfiles
cohabiting the block), not a per-platform Lua divergence; drop the WAD framing
and only Lua remains, and Lua is identical.

The parallel memory note phrasing can safely tighten to:
*"all 36 DLC Lua chunks are structurally identical across PS3 and Xbox; 13 are
also byte-identical in the raw block, the remaining 23 differ only in Havok
packfile data cohabiting the resident Lua block."*
