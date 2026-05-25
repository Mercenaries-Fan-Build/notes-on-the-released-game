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
├── dlc_port.py           ← Unified CLI (replaces port_xbox_dlc.py + dlc_port_x360_to_pc.py)
├── ffcs_patch_wad.py     ← Shared FFCS assembly (single + multi-block + merge)
├── ucfx_be_to_le.py      ← UCFX byte-swap (BE → LE, deep chunk handlers)
├── x360_dlc_io.py        ← STFS I/O + BE sges decompression
├── build_patch_wad.py    ← PC mod workflow (now calls ffcs_patch_wad)
├── port_xbox_dlc.py      ← DEPRECATED — use dlc_port.py
└── dlc_port_x360_to_pc.py ← DEPRECATED — use dlc_port.py
```

## Current status

| Layer | Status | Notes |
|-------|--------|-------|
| STFS extraction | Done | Dynamic hash-block map handles DLC's non-uniform layout |
| BE sges decompression | Done | Multi-segment raw deflate, 16-byte aligned |
| UCFX container swap (headers) | Done | Magic, chunk table, CSUM trailers |
| UCFX deep swap (INFO, BNDS, PRMG, IBUF, MESH, HIER, INDX) | Done | Structure-aware per-chunk |
| UCFX deep swap (STRM vertex data) | **Gap** | Needs per-format f16/f32/u8 swap |
| UCFX deep swap (texture BODY) | **Gap** | Possible Xbox 360 tile swizzle |
| UCFX deep swap (Havok) | **Gap** | Class-aware endian flip |
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

## Deprecated tools

The following scripts are superseded by `dlc_port.py` and will be removed
in a future cleanup:

| Script | Replacement |
|--------|-------------|
| `tools/port_xbox_dlc.py` | `tools/dlc_port.py --x360-rar` |
| `tools/dlc_port_x360_to_pc.py` | `tools/dlc_port.py --x360-stfs` |

## PS3 status

The PS3 `VZ.WAD` has an unknown encrypted/obfuscated header (first 0x80800
bytes). Big-endian `segs` blocks are visible starting at offset 0x80800. Once
the header is decoded, the same `ucfx_be_to_le.py` pipeline applies. See
`docs/ps3_wad_wrapper.md` for details.

No PS3 DLC package (PKG) has been obtained. The `ps3-update/` directory
contains only the v1.03 game patch and system firmware.
