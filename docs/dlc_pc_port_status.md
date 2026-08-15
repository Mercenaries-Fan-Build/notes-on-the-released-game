# DLC PC Port — Status & Usage

## Overview

The **Blow It Up Again** Xbox 360 DLC can be converted to a PC-compatible
`vz-patch.wad` overlay file using the unified `dlc_port.py` tool. The engine
loads this patch file at startup and the 2196 DLC blocks become addressable
alongside the base game's 11,370 blocks.

## Quick start

```bash
# Full port (all 2196 DLC blocks → single patch WAD)
make dlc-port OUTPUT=./output

# Or directly:
.venv/bin/python3 tools/dlc_port.py \
    --x360-rar "Mercenaries.2.World.In.Flames.DLC.RF.X360-ZTM.rar" \
    --output output/data/vz-patch.wad \
    --extract-audio output/data/Audios/

# Test with a subset:
.venv/bin/python3 tools/dlc_port.py \
    --x360-rar "Mercenaries.2.World.In.Flames.DLC.RF.X360-ZTM.rar" \
    --max-blocks 5 --verbose \
    --output /tmp/dlc_test.wad
```

## Tool architecture

```
tools/
├── dlc_port.py           ← Unified CLI (Xbox 360 DLC → vz-patch.wad)
├── ffcs_patch_wad.py     ← Shared FFCS assembly (single + multi-block + merge)
├── ucfx_be_to_le.py      ← UCFX byte-swap (BE → LE, semantic chunk handlers)
├── x360_dlc_io.py        ← STFS I/O + BE sges decompression
└── build_patch_wad.py    ← PC mod workflow (now calls ffcs_patch_wad)
```

## Current status

| Layer | Status | Notes |
|-------|--------|-------|
| STFS extraction | Done | Dynamic hash-block map handles DLC's non-uniform layout |
| BE sges decompression | Done | Multi-segment raw deflate, 16-byte aligned |
| UCFX container swap (headers) | Done | Magic, chunk table, CSUM trailers |
| UCFX deep swap (INFO, BNDS, PRMG, IBUF, MESH, HIER, INDX) | Done | Structure-aware per-chunk |
| UCFX `decl` (vertex declaration) | Done | Xbox 12-B elements → PC 8-B `D3DVERTEXELEMENT9` *format translation* (not a swap); END-only decls → bare PC `D3DDECL_END` (reskins). See [`format_reference.md` §15.1](format_reference.md) |
| UCFX deep swap (STRM vertex data) | **Gap** | Needs per-format f16/f32/u8 swap |
| UCFX deep swap (texture BODY) | **Gap** | Possible Xbox 360 tile swizzle |
| UCFX deep swap (Havok animation) | Done | Class-aware per-field swap (`hk_class_layouts.CLASS_REGISTRY`, 14 HK550 classes) |
| UCFX `PHY2` (Havok collision) | Done | `[u32 header][section-aware packfile][u32-swapped trailing]`; fixed world-load AVs `0x00414B4C` (string scramble) + `0x0248C13E` (trailing relocation). See [`format_reference.md` §15.2](format_reference.md). *Physics `__data__` is still a blind u32 sweep (no `hkp*` layouts) — remaining gap.* |
| UCFX deep swap (Lua bytecode) | **Gap** | Endianness flag + opcode layout |
| UCFX deep swap (COMP placements) | **Gap** | 42-byte record fields |
| PC sges recompression | Done | segment_size=64KB, level=6, major=4 |
| FFCS patch WAD assembly | Done | Multi-block, INDX/ASET/PTHS/DATA, cert blob |
| Patch WAD merge (DLC + mods) | Done | `--merge-into` or `ffcs_patch_wad.merge_patch_wads()` |
| Audio extraction (.pws) | Done | `--extract-audio` writes to data/Audios/ |
| In-game runtime validation | **Pending** | Needs retail PC install + copy WAD to `data/` |
| Contract Lua activation | **Pending** | DLC contracts need ASET registration in engine |

## Merge workflow (DLC + mods in one WAD)

The engine loads **one** `vz-patch.wad` per base WAD. To combine DLC blocks
with mod blocks (e.g., boundary removal, string swaps):

```bash
# 1. Build mod patch first
python3 tools/build_patch_wad.py --remove-boundaries \
    --source-wad path/to/vz.wad \
    --output data/vz-patch.wad

# 2. Merge DLC into the same WAD
python3 tools/dlc_port.py --x360-rar DLC.rar \
    --merge-into data/vz-patch.wad \
    --output data/vz-patch.wad
```

## PS3 status

**Update (2026-08-01): the PS3 "Blow It Up Again" DLC is fully decrypted.** The
earlier "no PKG obtained" note below is superseded. Source PKG
(`game-files/1ntHdj11…V8bh78m4U6…pkg`, content id
`UP0006-BLUS30056_00-MERCS2WIFDLC01NA`) was cracked end-to-end: PSN PKG
(AES-128-CTR, key `2e7b71d7c9c9a14ea3221f188828b8f8`) → inner `DLC01.EDAT`
(NPDRM EDAT, license type 3) → inner WAD (271,089,664 B, `SCFF` BE, parses with
`x360_dlc_io`). The recovered **title klicensee = `1896170d86be49b983b7135c96d6fb79`**
(a title-specific klic, not NP_KLIC_FREE), lifted as a 16-byte constant at
offset `0x103f498` of the v1.03 *patched* EBOOT via a sliding-window AES-CMAC
scan. See memory `ps3-dlc-crack-and-klicensee` for the full chain.

**Key finding — PS3 content == Xbox content.** 5287 ASET name-hashes are
identical (0 platform-only), and all **36/36 DLC Lua scripts are byte-identical
to Xbox** (`docs/mercs2-dlc-luacd/src/dlc01`). Byte differences are pure
platform re-encoding (GPU texture format, vertex packing). So the PS3 route adds
no new assets or gameplay over the Xbox route — its payoff was confirmation +
key recovery. The DLC added no gameplay C code; it is Lua over the base-game
binding surface, so a failing DLC Lua call is a reimpl fidelity bug (base-game
work), not DLC-specific. The two irreducibly-DLC artifacts are the Caicara /
Speed City level data and the arena game-mode Lua (already held).

**Tooling (2026-08-12): the crack chain is now a Rust tool.** The four reference
Python scripts were ported into the `wad_simulator` workspace and verified against
the retail package + the Python oracle outputs. Core logic lives in
`mercs2_formats::ps3_{keys,crypto,pkg,edat,self,klic}` (AES-128/256 CTR/CBC/ECB +
AES-CMAC, with FIPS-197 / NIST SP 800-38A / RFC 4493 known-answer tests); the CLI
is `crates/ps3_dlc_crypt` (`pkg-unpack` / `edat-decrypt` / `unself` / `klic-scan`).
End-to-end proof: `pkg-unpack` on the retail 400 MB PKG gives the correct
`content_id` + 16-entry table; `edat-decrypt` yields the 271,089,664-byte `SCFF`
inner WAD; `unself` (APP and NPDRM) is sha256-identical to the Python oracle ELFs;
`klic-scan` reproduces `off=0x103f498 klic=1896170d…fb79`. The Python scripts are
retained only as oracles. The decrypted inner WAD is big-endian `SCFF`, so it
feeds the same `dlc_input` + `ucfx_byteswap` + `patch_wad` pipeline as `dlc_port`.

### Original note (superseded)

The PS3 `VZ.WAD` has an unknown encrypted/obfuscated header (first 0x80800
bytes). Big-endian `segs` blocks are visible starting at offset 0x80800. Once
the header is decoded, the same `ucfx_be_to_le.py` pipeline applies. See
`docs/ps3_wad_wrapper.md` for details.
