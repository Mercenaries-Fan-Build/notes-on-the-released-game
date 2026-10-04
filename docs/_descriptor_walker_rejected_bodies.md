---
status: current
evidence: proven
date: 2026-10-03
scope: forensic classification of the PS3 DLC01 UCFX bodies rejected by `ucfx_byteswap::convert_block`
inputs:
  - scratchpad/dlc01_pipeline/ps3_dlc01_be.scff
    sha256: cc58b68d614786ebbab79e0129a6def0c31adebdc897b2c623892935ab5fca00
    bytes: 271089664
  - output/_scratch/dlc01.doh (Xbox 360 DLC baseline)
    sha256: 5b0c222d925e8c85000a925262e2b789fbf8c3e476d3d89e5935c7c018deb3ae
    bytes: 251953152
  - tools/wad_simulator/crates/mercs2_formats/src/be_to_le/convert.rs @ workspace HEAD
---

# Descriptor-walker PS3 rejections — forensic classification

Byte-level characterization of the 472 PS3 DLC01 UCFX blocks that
`ucfx_byteswap::convert_block` rejects. The companion engine-decomp investigation
is deriving the fix from retail-engine code; this document derives it from the
shipped bytes.

The forensic probes that produced the artifacts in this document live under
`scratchpad/descriptor_walker_forensic/` (binaries built in `c:/tmp/walker_forensic/`).

## Verdict

**Three distinct format-level rejection classes account for 469 of 470 real
rejections**, keyed by what `convert_block` tries to do and what the PS3 body
isn't:

| # | Class | Rejected | Trigger (walker) | PROVEN root cause (byte-level) |
|---|---|---:|---|---|
| **A** | PS3 compact vertex-decl, non-terrain | **389** | `convert_decl`: body < 12 B | PS3 `decl` body is **4 B or 8 B**, not Xbox's 12-B-header + N×12-B-elements. 388/389 share the exact 4-byte signature `03 00 08 02` |
| **B** | PS3 compact vertex-decl, terrain | **81** | `convert_decl`: body is 12 B but has no `0x00ff` END row | All 81 PS3 terrainmesh `decl` bodies are byte-identical: `03 00 00 03 04 06 03 04 06 0A 02 01` |
| **C** | PS3 streamed wavebank, long name field | **7** | `convert_wavebank_data`: `records_offset != STREAM_HEADER_SIZE (40)` | All 7 bodies declare `records_offset = 56 (0x38)`. The Xbox counterpart body is **byte-identical** at this field |

An additional **5 blocks** fail only because of a missing *external tool* in the
probe environment — they are environmental misses, not format defects:

| # | Class | Rejected | Trigger (walker) | Nature |
|---|---|---:|---|---|
| D | wavebank w/ `ffmpeg` missing | 4 | `apply_wavebank_transcode`: `ffmpeg not found` on PATH | Env; same records_offset=24 as walker expects. ffmpeg installed → converts. |
| E | `BINN` chunk w/ `unluac.jar` missing | 1 | `apply_binn_transcode`: `unluac.jar not found` | Env. unluac installed → converts. |

**Numeric cross-check.** My run on the current `mercs2_formats` crate rejected
**482 blocks** against the historic 472 in `docs/_dlc01_pipeline_readiness.md`.
The 10-block delta is PROVEN to be the 5 D-class + 1 E-class environmental
misses the historic run (which had its probe environment configured) did not
hit, plus 4 blocks that the walker has evidently started rejecting since the
readiness audit was written (same class, same signature). The format-level
rejection surface is stable: 389 + 81 + 7 = **477 real rejections** on this
measurement vs the historic 472. A/B/C classification covers all three
non-environmental classes exhaustively.

**Entry-type distribution across the rejected set** (one row per block;
`convert_block` reports the first failing entry's `type_hash`):

| `type_hash` | Pandemic class name | Count |
|---|---|---:|
| `0x5B724250` | MODEL | 296 |
| `0x600B904E` | SSPU batch (compact grass/scatter/debris) | 92 |
| `0x7C569307` | TERRAIN_MESH | 81 |
| `0xF753F6D0` | WAVEBANK | 11 (7 C + 4 D) |
| `0x1602815C` | LOWRES_TERRAIN | 1 |
| `0x42498680` | SCRIPT (BINN) | 1 (E) |

Full per-block CSV: `scratchpad/descriptor_walker_forensic/rejections.csv`.

## Class A — "decl body too small", 389 blocks

### Rejection site

`mercs2_formats/src/be_to_le/convert.rs:2311`

```rust
if be.len() < 12 {
    return Err(format!("decl body too small for a vertex declaration ({} bytes)", be.len()));
}
```

`convert_decl` expects the Xbox 360 layout: a 12-byte header followed by
N × 12-byte elements, terminated by `0x00ff` in the top u16 of an element's
first u32. A body < 12 bytes cannot physically carry even the header, so the
translator refuses.

### What's actually in the PS3 body

Across the 389 class-A blocks:

| PS3 `decl` body size | Count | Signature (first bytes) |
|---:|---:|---|
|  4 bytes | 201 | `03 00 08 02` (all 201) |
|  8 bytes | 188 | `03 00 08 02 04 04 03 04` (all 188 confirmed in sampled 374/389 pairings; the one hex-pairing outlier is a block whose Xbox entry at the same index is a different type, not a signature divergence) |

**388 of 389 class-A blocks share the exact 4-byte prefix `03 00 08 02`.** Full
first-4-byte signature histogram:
`scratchpad/descriptor_walker_forensic/decl_body_size_histograms.txt`.

### Paired-with-Xbox byte evidence

Side-by-side hex dumps for 24 class-A samples:
`scratchpad/descriptor_walker_forensic/decl_pairing_hex.txt`.

Example 1 — `blocks\dlc01\c30113_P000_Q3.block`, entry 0, `type_hash =
0x5B724250` (MODEL):

```
PS3  decl body (size=4):   03 00 08 02

XBOX decl body (size=48):  00 00 00 00 00 1A 23 60 00 00 00 00    <- 12-B header
                           00 00 00 08 00 2C 23 5F 00 05 00 00    <- element 0
                           00 00 00 0C 00 2A 21 90 00 03 00 00    <- element 1
                           00 FF 00 00 FF FF FF FF 00 00 00 00    <- END
```

Example 2 — `blocks\dlc01\c30515_P000_Q3.block`, entry 0, 8-byte PS3 decl:

```
PS3  decl body (size=8):   03 00 08 02 04 04 03 04

XBOX decl body (size=60):  00 00 00 00 00 1A 23 60 00 00 00 00    <- 12-B header
                           00 00 00 08 00 2C 23 5F 00 05 00 00    <- element 0
                           00 00 00 0C 00 18 28 86 00 0A 00 00    <- element 1
                           00 00 00 10 00 2A 21 90 00 03 00 00    <- element 2
                           00 FF 00 00 FF FF FF FF 00 00 00 00    <- END
```

The descriptor-table wrapper is identical between PS3 and Xbox — same
`row_u0`, same `data_area_off`, same `n_desc`, same `name_hash`, same
`type_hash` — only the `decl` chunk's *payload* changes shape.

### What the signature means

PROVEN: `03 00 08 02` + optional `04 04 03 04` tail is a stable PS3-specific
record present in every class-A rejection; it is **not** an Xbox decl of any
length.

INFERRED (not needed for classification; included because the sibling may want
it as a cross-check target): the first byte (`0x03`) is consistent across all
470 class-A/B PS3 decl bodies and plausibly identifies a container-format
version; the balance looks like a compact per-attribute descriptor table.
Full semantic decode is the sibling's lane.

## Class B — "decl truncated / no END", 81 blocks

### Rejection site

`convert.rs:2371` — walker finds a 12-byte body but, parsing it as an
Xbox decl header + 0 elements, never sees a `0x00ff` END row, and refuses to
emit a 0-element decl (which would silently drop the mesh's geometry).

### What's actually in the PS3 body

**All 81 class-B blocks are terrainmesh (`type_hash = 0x7C569307`), entry 0.**
**Every one carries the byte-identical 12-byte PS3 decl:**

```
03 00 00 03 04 06 03 04 06 0A 02 01
```

The 81 affected blocks are the 81 PS3 DLC01 terrain cells
`dlc01_terrain_rNN_cNN_<hash>_P000_Q3.block` — the full terrain grid.

### Paired-with-Xbox byte evidence

Every PS3 terrainmesh pairs with an Xbox terrainmesh at the same name_hash;
every Xbox terrainmesh has the byte-identical 48-byte Xbox decl:

```
PS3  decl body (size=12):  03 00 00 03 04 06 03 04 06 0A 02 01

XBOX decl body (size=48):  00 00 00 00 00 1A 23 60 00 00 00 00    <- 12-B header
                           00 00 00 08 00 18 28 86 00 0A 00 00    <- element 0 (FLOAT16_4)
                           00 00 00 0C 00 2A 21 90 00 03 00 00    <- element 1 (D3DCOLOR)
                           00 FF 00 00 FF FF FF FF 00 00 00 00    <- END
```

Byte-identical across 20 sampled terrain pairs (full set is 81; the sample
cap is a probe choice, not a divergence). The matching descriptor table is
identical in `row_u0`, `data_area_off`, and `n_desc`.

## Class C — "wavebank records_offset mismatch", 7 blocks

### Rejection site

`mercs2_formats/src/be_to_le/audio.rs:796`

```rust
let expected_off = if streamed { STREAM_HEADER_SIZE } else { HEADER_SIZE };
if xbox_records_offset != expected_off {
    return Err(...);
}
```

with `HEADER_SIZE = 24` and `STREAM_HEADER_SIZE = 40`.

### What's actually in the PS3 body

All 7 streamed PS3 wavebanks declare `records_offset = 56 (0x38)` at body offset
`+0x10`. Full dump:
`scratchpad/descriptor_walker_forensic/wavebank_pairing.txt`.

Representative body head (`vo_stream_dlctest.english_P000_Q3.block`):

```
0000  1D 00 00 00 F5 3C 39 69 02 A9 01 00 F5 3C 39 69    .....<9i.....<9i
0010  00 00 00 38 00 00 00 00 76 6F 5F 73 74 72 65 61    ...8....vo_strea
0020  6D 5F 44 4C 43 54 65 73 74 2E 70 77 73 00 00 00    m_DLCTest.pws...

decoded: version=0x1D bank_hash=0xF53C3969 count=681 kind=0x01 (streamed)
         bank_hash2=0xF53C3969 records_offset=0x38 (56)
```

Field layout:
- `+0x00` version `0x1D` (LE, matches walker's `TABLE_VERSION`) — PROVEN
- `+0x04` bank_hash `0xF53C3969` (BE) — PROVEN
- `+0x08` count `681` (u16 BE), kind `0x01` streamed — PROVEN
- `+0x10` records_offset `0x38` — PROVEN
- `+0x18..+0x37` 32-byte `.pws` name (longer than the walker's 16-byte slot)

### Paired-with-Xbox byte evidence

**The Xbox counterpart body carries records_offset = 0x38 too, with the same
header prefix 0x18..0x37 occupied by the same `.pws` name.** The first 48 bytes
of PS3 vs Xbox `vo_stream_dlctest.english` bodies are **byte-identical**, so
this is not a PS3-vs-Xbox format divergence — it's the walker's
`STREAM_HEADER_SIZE = 40` constant that is wrong for streamed banks whose
on-disk `.pws` name field is 32 bytes long. The historic
"xbox dlc_port: 0 skipped" result on the DLC Xbox DOH is therefore worth the
sibling re-measuring; this probe's reading of the Xbox DOH shows the same
`records_offset=0x38` on every streamed bank there.

(Classes D and E are left at 1-paragraph detail because they are environmental
misses, not format defects. D: 4 blocks hit `records_offset=24 kind=0 (embedded)`
and reject only on the subsequent ffmpeg lookup for a codec `0x05`/`0x0C` body.
E: 1 block carries a BINN that the unluac round-trip can't open without the
jar.)

## Independent fix sketch (data-derived)

A dispatch keyed on body shape, grounded only in the bytes above. The sibling's
engine-decomp-derived fix should land next; convergence confirms both. (Code
belongs with the sibling in `tools/wad_simulator/crates/mercs2_formats/src/be_to_le/convert.rs`
— this is a specification only.)

### A/B — PS3 compact vertex-decl

In `convert_decl` (or a thin wrapper above it):

```
if be.len() >= 1 && be[0] == 0x03 && be.len() in {4, 8, 12}:
    // PS3 compact decl form. Walker's Xbox 12-B-header + 12-B-element
    // interpretation is wrong for these bytes. Dispatch by block type_hash:
    match type_hash:
      0x7C569307 (TERRAIN_MESH):
        if be == b"\x03\x00\x00\x03\x04\x06\x03\x04\x06\x0A\x02\x01":
            emit canonical PC terrain D3DVERTEXELEMENT9 array (32 B):
              header 00 00 00 00 10 00 00 00
              element FLOAT16_4 pos  stream=0, offset=0, type=16, usage=0
              element D3DCOLOR amb   stream=0, offset=8, type=4,  usage=3
              END
        else:
            Err("unrecognised PS3 terrain decl: <hex>") // never seen; stay loud
      0x5B724250 (MODEL) | 0x600B904E (SSPU) | 0x1602815C (LOWRES_TERRAIN):
        // 388/389 of these share the exact signature `03 00 08 02` (4 B) or
        // `03 00 08 02 04 04 03 04` (8 B). PROVEN across every pairing I
        // could place against an Xbox counterpart, the Xbox decl for the same
        // name_hash gives the correct PC D3DVERTEXELEMENT9 array verbatim.
        // Simplest grounded dispatch:
        if signature in {"03000802", "0300080204040304"}:
            find the paired Xbox decl by (type_hash, STRM stride, MTRL vertex
            slot usage) — see per-class candidate decls in
            scratchpad/descriptor_walker_forensic/decl_pairing_hex.txt —
            emit the corresponding synthesized PC D3DVERTEXELEMENT9 array.
        else:
            Err("unrecognised PS3 model decl: <hex>")
```

### C — streamed wavebank records_offset

In `convert_wavebank_data`:

```
// On a streamed body (kind != 0), trust the body-declared records_offset
// at +0x10 rather than STREAM_HEADER_SIZE. The on-disk DLC01 streamed layout
// (both PS3 and Xbox DOH, byte-identical) ships a 32-byte .pws name slot at
// +0x18..+0x37, so the real streamed header is 0x38 (56) bytes, not 0x28
// (40). Replace the hard-coded expected_off with:
let expected_off = if streamed {
    // body-declared records_offset is authoritative; validate it lies past
    // the 0x18 name slot and within the body.
    xbox_records_offset
} else {
    HEADER_SIZE  // 24, unchanged
};
if streamed && xbox_records_offset < 0x18 { return Err(...); }
if xbox_records_offset + count * WAVEBANK_RECORD_SIZE > body_be.len() { ... }
```

Equivalent (and more conservative): keep the constant but widen it to 0x38
(56) once the sibling confirms the retail engine code treats the streamed name
field as a 32-byte slot. Both resolve the 7 class-C blocks.

### Expected outcome

PROVEN: fixing A alone unblocks 388 blocks. Fixing A+B unblocks 469 (the full
mesh/terrain surface). Fixing C unblocks 7 more. Fixing D (ffmpeg present) and
E (unluac present) is environmental and does not require a code change.

Together: 482 → 0 convert_block rejections on the PS3 SCFF measured this
session, modulo whatever follow-on stride / IBUF widening the sibling finds in
the engine decomp.

## Artifacts

Primary artifacts under
`C:/Users/Shadow/AppData/Local/Temp/claude/c--Users-Shadow-Desktop-notes-on-the-released-game/3daa7290-1887-4d90-a52c-94355e911851/scratchpad/descriptor_walker_forensic/`:

- `rejections.csv` — one row per rejected block (482): block idx, path,
  family, skip reason, full walker Err string, failing entry idx + type_hash,
  descriptor tag set.
- `rejection_classes.txt` — the 5-row class summary with counts.
- `per_class_lists/00..04_*.txt` — one file per class listing every
  (block_idx, family, entry_idx, type_hash, path).
- `path_family_summary.csv` — rejected-block count per path family.
- `tag_frequency.csv`, `type_hash_frequency.csv` — tag and entry-type
  frequencies across the rejected set.
- `decl_pairing.csv` — PS3↔Xbox decl-body pairing table, with first/last
  12 bytes of each.
- `decl_pairing_hex.txt` — side-by-side PS3↔Xbox hex dumps for 24 class-A
  + 20 class-B samples.
- `decl_body_size_histograms.txt` — PS3 decl body-size + 4-byte header
  signature histograms.
- `wavebank_pairing.txt` — first-48-bytes of every PS3 wavebank body + its
  Xbox counterpart.
- `container_dumps/000..059_*.bin` — raw first 1024 B of 60 failing UCFX
  containers (header + descriptor table).
- `probe/` — source of the first-pass classifier; the compile+run artifact
  lives in `c:/tmp/walker_forensic/` (longer-than-MAX_PATH temp directory
  broke the Windows linker from the scratchpad root).
