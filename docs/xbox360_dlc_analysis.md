# Xbox 360 DLC Archive Analysis

## Summary

The **Mercenaries 2: World in Flames** Xbox 360 DLC uses the **same FFCS/sges/UCFX format family** as the PC version, with byte-order swapping for the PowerPC architecture. All 4-byte magic signatures are reversed, all multi-byte integer fields are big-endian, and the sges compression algorithm remains raw deflate (zlib wbits=-15).

## Archive Structure

### Outer Container

| Property | Value |
|----------|-------|
| File | `Mercenaries.2.World.In.Flames.DLC.RF.X360-ZTM.rar` |
| RAR size | 325 MB |
| Extracted content | Single STFS container |
| STFS path | `45410828/00000002/86ABF01DD4E356CA0ED1302E6E3AB36C5A6E1D9345` |
| STFS size | 395,444,224 bytes (377 MB) |

### STFS LIVE Container

| Property | Value |
|----------|-------|
| Magic | `LIVE` (Xbox 360 Marketplace content) |
| Title ID | `0x45410828` (Mercenaries 2: World in Flames) |
| Display Name | "Mercs 2 - Blow It Up Again Pack" |
| Game Name | "Mercenaries 2: World In Flames" |

### STFS File Listing

| # | Name | Size | Type |
|---|------|------|------|
| 0 | `audios/` | — | Directory |
| 1 | `DLC01.doh` | 251.9 MB | Main data archive (FFCS) |
| 2 | `package.cfg` | 5 KB | Package configuration |
| 3 | `dlctest_streaming.pws` | 28.9 MB | Streaming audio |
| 4 | `vo_stream_dlctest.english.pws` | 18.5 MB | English voice-over |
| 5 | `vo_stream_dlctest.french.pws` | 16.1 MB | French voice-over |
| 6 | `vo_stream_dlctest.german.pws` | 18.4 MB | German voice-over |
| 7 | `vo_stream_dlctest.italian.pws` | 20.4 MB | Italian voice-over |
| 8 | `vo_stream_dlctest.russian.pws` | 18.5 MB | Russian voice-over |
| 9 | `vo_stream_dlctest.spanish.pws` | 20.4 MB | Spanish voice-over |

**Note**: The `.doh` extension is the Xbox 360 equivalent of the PC `.wad` — both contain FFCS data.

---

## FFCS WAD Structure (Big-Endian)

Located at STFS offset `0xD000`.

### Header

| Offset | Size | Field | Value |
|--------|------|-------|-------|
| 0x00 | 4 | Magic | `SCFF` (big-endian `FFCS`) |
| 0x04 | 4 | Version | 2 (same as PC) |
| 0x08 | 4 | Chunk count | 7 (but only 5 valid — see below) |

### Chunk Table (12-byte rows starting at offset 0x0C)

| # | Magic (BE) | LE Equiv. | Offset | Size |
|---|------------|-----------|--------|------|
| 0 | `XDNI` | INDX | 0x8000 | 2,196 |
| 1 | `ATAD` | DATA | 0x48000 | 36 |
| 2 | `MUSC` | CSUM | — | — |
| 3 | `TESA` | ASET | 0xE6F0 | 5,341 |
| 4 | `SHTP` | PTHS | 0x234C0 | 2,196 |

Chunk rows 5-6 are invalid (their magic/offset bytes overlap with the 144-byte certificate blob that starts at FFCS+0x48, identical positioning to PC).

### Certificate Blob

At FFCS+0x48 (same position as PC). 144 bytes, non-zero (contains signing data for Xbox LIVE marketplace verification).

---

## Block Inventory (PTHS)

57 block paths found in the DLC:

```
blocks\dlc01\dlc01_terrain_P000_Q3.block
blocks\dlc01\dlc01_caicara_foliage_P000_Q3.block
blocks\dlc01\dlc01_dlccon004_P000_Q3.block
blocks\dlc01\dlc01_base_P000_Q3.block
blocks\dlc01\dlc01_state_dlccon003_spawns_P000_Q3.block
blocks\dlc01\dlc01_commonlocations_P000_Q3.block
blocks\dlc01\dlc01_dlccon002_roads_P000_Q3.block
blocks\dlc01\dlc01_speedcity_roads_P000_Q3.block
blocks\dlc01\dlc01_speedcity_P000_Q3.block
blocks\dlc01\dlc01_caicara_scrub_P000_Q3.block
blocks\dlc01\dlc01_dlccon001_P000_Q3.block
blocks\dlc01\dlc01_lowresterrain_P000_Q3.block
blocks\dlc01\dlc01_state_dlccon003_P000_Q3.block
blocks\dlc01\dlc01_dlccon002_race_P000_Q3.block
blocks\dlc01\dlc01_caicara_P000_Q3.block
blocks\dlc01\dlc01_state_dlccon003_pathfinding_P000_Q3.block
blocks\dlc01\dlc01_state_missionhub_P000_Q3.block
blocks\dlc01\dlc01_state_dlccon003_atmofx_P000_Q3.block
blocks\dlc01\dlc01_dlccon004_roads_P000_Q3.block
blocks\dlc01\dlc01_caicara_roads_P000_Q3.block
blocks\dlc01\c30061_P000_Q3.block
blocks\dlc01\c30062_P000_Q3.block
blocks\dlc01\c30085_P000_Q3.block
blocks\dlc01\c30092_P000_Q3.block
blocks\dlc01\c30094_P000_Q3.block
... (57 total, including 37 c3XXXX cutscene/contract blocks)
```

Asset naming uses the same `_P000_Q3` LOD convention as the main game. DLC-specific prefixes:
- `dlc01_terrain` — terrain data
- `dlc01_caicara_*` — Caicara region foliage, scrub, roads
- `dlc01_speedcity_*` — Speed City area
- `dlc01_dlccon*` — DLC contract/mission content
- `dlc01_state_*` — State overlays (spawns, pathfinding, atmosphere)
- `c30XXX_*` — Cutscene/contract assets

---

## sges Compression Format (Big-Endian)

### Header (32 bytes)

| Offset | Size | Field | Notes |
|--------|------|-------|-------|
| 0x00 | 4 | Magic | `segs` (big-endian `sges`) |
| 0x04 | 2 | Version | 4 (same as PC) |
| 0x06 | 2 | Segment count | `ceil(decomp_total / 65536)` |
| 0x08 | 4 | Total decompressed size | Big-endian uint32 |
| 0x0C | 4 | Total compressed size | Big-endian uint32 |
| 0x10 | 2 | Segment 1 compressed size | Bytes consumed by first deflate stream |
| 0x12 | 2 | Reserved/unknown | |
| 0x14 | 4 | Config flags | `0x21` for 1-2 segs, `0x31` for 3-4, `0x41` for 5-6, etc. |
| 0x18 | 8 | Unknown | Possibly hash or metadata |

**Key difference from PC**: The PC format has a 16-byte header. Xbox 360 has a **32-byte header** with an extra 16 bytes containing the first segment's compressed size and configuration.

### Multi-Segment Structure

For blocks where `decomp_total > 65536`:
- **Segment count** = `ceil(decomp_total / 65536)`
- Multi-segment blocks with 3+ segments use header size **48** bytes (extra 16-byte descriptor)
- Compressed data consists of **concatenated independent deflate streams**
- Each segment decompresses to exactly 65,536 bytes (last segment may be smaller)
- Between segments: **4 bytes of zero padding** (alignment)

### Decompression Algorithm

```python
import struct, zlib

def decompress_xbox_sges(data: bytes, offset: int) -> bytes:
    """Decompress big-endian Xbox 360 sges block."""
    seg_count = struct.unpack_from('>H', data, offset + 6)[0]
    decomp_total = struct.unpack_from('>I', data, offset + 8)[0]
    comp_total = struct.unpack_from('>I', data, offset + 12)[0]
    
    # Header is 32 for 1-2 segments, 48 for 3+ segments
    header_size = 32 if seg_count <= 2 else 48
    
    all_decomp = bytearray()
    remaining = data[offset + header_size : offset + header_size + comp_total]
    
    for s in range(seg_count):
        dc = zlib.decompressobj(-15)  # raw deflate
        result = dc.decompress(remaining)
        all_decomp.extend(result)
        remaining = dc.unused_data
        
        # Skip 4-byte alignment padding between segments
        if s < seg_count - 1 and remaining:
            remaining = remaining[4:]
    
    assert len(all_decomp) == decomp_total
    return bytes(all_decomp)
```

### Statistics

| Metric | Value |
|--------|-------|
| Total sges blocks | 2,196 |
| Single-segment (flags=1) | 1,196 (54.5%) |
| Multi-segment (flags>1) | 1,000 (45.5%) |
| Max segment count | 66 |
| Total compressed | 205 MB |
| Total decompressed | 363 MB |
| Overall compression ratio | 53.9% |
| Successfully decompressed (raw) | 1,251/2,196 (57%) |

**Note**: The ~43% failure rate is due to **STFS hash table interleaving** — the STFS container inserts 0x1000-byte hash blocks every 170 data blocks. A proper STFS extractor must remove these hash blocks before parsing the FFCS/sges data. The underlying compression is standard raw deflate.

---

## UCFX Asset Container (Big-Endian)

Decompressed sges blocks contain **UCFX** data with big-endian chunk tags:

| BE Magic | LE Equiv. | Purpose |
|----------|-----------|---------|
| `XFCU` | `UCFX` | Container header |
| `RDHC` | `CHDR` | Chunk header |
| `PMOC` | `COMP` | Component definition |
| `MOEG` | `GEOM` | Geometry data |
| `HSEM` | `MESH` | Mesh definition |
| `GMRP` | `PRMG` | Primitive group |
| `MRTS` | `STRM` | Vertex stream |
| `FUBI` | `IBUF` | Index buffer |
| `LRTM` | `MTRL` | Material |
| `SGLF` | `FLGS` | Flags section |

### Decompressed Block Wrapper

Each decompressed sges block starts with a 20-byte wrapper before the UCFX data:

| Offset | Size | Field |
|--------|------|-------|
| 0x00 | 4 | Block count (usually 1) |
| 0x04 | 4 | Block hash/ID |
| 0x08 | 4 | Timestamp or build ID |
| 0x0C | 8 | Reserved (zeros) |
| 0x14 | — | UCFX data starts |

---

## Other Formats Found

### Lua Bytecode
- 2 instances found in the archive
- Version: Lua 3.15 (same custom Pandemic Lua build)
- **Big-endian** bytecode (endian flag = 0x26/38)

### PWS Audio
- 7 audio archives (streaming + localized voice-over)
- `.pws` = Pandemic Wavebank Stream (same format as PC)
- Languages: English, French, German, Italian, Russian, Spanish

---

## Format Comparison: PC vs Xbox 360

| Feature | PC (x86) | Xbox 360 (PowerPC) |
|---------|-----------|-------------------|
| Container ext. | `.wad` | `.doh` (inside STFS) |
| FFCS magic | `FFCS` | `SCFF` (reversed) |
| FFCS version | 2 | 2 |
| Byte order | Little-endian | Big-endian |
| Chunk row size | 12 bytes | 12 bytes |
| Chunk types | INDX, DATA, CSUM, ASET, PTHS | XDNI, ATAD, MUSC, TESA, SHTP |
| sges magic | `sges` | `segs` (reversed) |
| sges version | 4 | 4 |
| sges header | 16 bytes | 32 bytes (+16 per-seg metadata) |
| sges compression | raw deflate (wbits=-15) | raw deflate (wbits=-15) |
| Segment boundary | — | 64KB + 4-byte alignment pad |
| UCFX magic | `UCFX` | `XFCU` (reversed) |
| Lua endianness | LE (flag=1) | BE (flag=0) |
| Audio format | `.pws` | `.pws` (same) |
| Block paths | `blocks\vz\...` | `blocks\dlc01\...` |
| Cert blob offset | FFCS+0x48 | FFCS+0x48 (same) |
| Cert content | All zeros (PC retail) | Non-zero (Xbox LIVE signing) |

---

## Key Insights

1. **Cross-platform format compatibility**: Pandemic used the same FFCS/sges/UCFX toolchain for both platforms, with a byte-order flag controlling endianness. This means our extraction tools could support Xbox 360 data with a simple endianness parameter.

2. **DLC content is self-contained**: The "Blow It Up Again Pack" is a complete mini-WAD with terrain, foliage, roads, buildings (c30XXX blocks), state overlays, pathfinding, and audio — everything needed for the DLC map area.

3. **STFS hash tables complicate raw access**: The STFS container inserts hash/verification blocks that interrupt the linear data. A proper STFS parser (like `wxPirs`, `Velocity`, or `py360`) is needed for complete extraction. Our raw signature-scanning approach works for format identification but not complete asset extraction.

4. **64KB segment boundary is Xbox-specific**: The PC sges format uses arbitrary segment sizes. The Xbox version enforces 64KB maximum per deflate stream (likely due to Xbox 360 memory constraints or XMemDecompress API requirements).

5. **The `.doh` extension**: Previously undocumented. Likely stands for "Data Object Hub" or similar. Functions identically to PC `.wad` files.

6. **DLC area identification**: The block paths reveal this DLC adds the "Caicara" and "Speed City" areas with 4 DLC contracts (`dlccon001`–`dlccon004`), suggesting the "Blow It Up Again Pack" added new contract missions in these specific map regions.

---

## Future Work

- [ ] Implement proper STFS extraction (remove hash table blocks) to achieve 100% decompression
- [ ] Add big-endian support to `tools/sges_decompress.py` and `tools/ucfx_mesh_codec.py`
- [ ] Cross-reference DLC block names with PC main game to identify shared vs. new assets
- [ ] Extract and compare mesh/texture data between platforms (vertex format differences)
- [ ] Investigate if the PC version's data directory contains unused DLC file stubs
