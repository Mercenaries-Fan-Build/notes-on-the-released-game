# PS3 VZ.WAD Wrapper Format

Status: **Partially documented** — inner structure confirmed, outer wrapper unknown.

## Key Findings

The PS3 version of `VZ.WAD` (1,073,739,776 bytes = exactly 1 GiB) differs
fundamentally from the PC and Xbox 360 formats:

| Platform | Header | Endianness | Block Magic |
|----------|--------|------------|-------------|
| PC       | `FFCS` at offset 0 | Little-endian | `sges` |
| Xbox 360 | `SCFF` at offset 0 | Big-endian | `segs` |
| PS3      | Unknown/encrypted  | Big-endian | `segs` |

## Structure

```
Offset    Content
──────    ────────────────────────────────
0x00000   Encrypted/obfuscated header (no recognizable magic)
          524,288 bytes (0x80800) of non-ASCII data
0x80800   First `segs` block (big-endian sges)
0x90800   Second `segs` block
0xA8800   Third `segs` block
...       More `segs` blocks follow
```

### Header analysis (offsets 0x00 - 0x80800)

- No `FFCS`, `SCFF`, `sges`, `segs`, `UCFX`, or `XFCU` magic found
- Data does not appear to be plain text or standard compression headers
- Likely a PS3-specific encryption envelope (similar to how EBOOT.BIN is encrypted)
- The `segs` blocks at 0x80800+ may represent the DATA region with a virtual
  0x80800 offset bias (INDX entries would point here)

### `segs` blocks (at 0x80800+)

The `segs` header at offset 0x80800 reads:

```
73 65 67 73 00 04 00 02    segs, version 4, 2 segments
```

This is the same big-endian sges format used by the Xbox 360:
- 4-byte magic: `segs` (same bytes as Xbox `segs`)
- Version: big-endian u16 = 4 (matches Xbox)
- Segment count: big-endian u16 = 2 (for first block)
- Followed by segment table and raw-deflate payload

## Relationship to Xbox 360 format

The inner `segs` blocks appear byte-compatible with Xbox 360's format. If the
header wrapper can be reverse-engineered (or skipped by assuming a fixed
DATA region offset), the same `ucfx_be_to_le.py` pipeline used for Xbox DLC
should work for PS3 blocks:

```
PS3 VZ.WAD → skip header (0x80800) → segs blocks → decompress → UCFX BE→LE → sges compress → PC patch WAD
```

## Source files

| Path | Size | Notes |
|------|------|-------|
| `ps3-game/USRDIR/VZ.WAD` | 1,073,739,776 | Extracted from disc / ISO |
| `Mercenaries 2 World in Flames [BLUS30056].iso` | 10,019,698,688 | Full PS3 disc image (ISO 9660 `M2WIF`) |

The ISO is a complete copy of the disc; `ps3-game/USRDIR/` is an extracted
mirror of the same content (confirmed by file listing + sizes matching
ISO capacity minus filesystem overhead).

## Open questions

1. **What is the header at 0x00000 - 0x80800?**
   - Could be a PS3 content-protection signature block
   - Could be an alternate index table with non-standard encoding
   - May require the EBOOT's runtime decryption key to decode

2. **Where are INDX, ASET, PTHS equivalents?**
   - Either embedded in the encrypted header, or
   - The PS3 engine uses a different lookup mechanism (e.g., hardcoded offsets
     in EBOOT.BIN or a separate index file)

3. **Is there a PS3 DLC package with Blow It Up Again?**
   - `ps3-update/` contains game patch PKG (v1.03) + firmware PUP
   - Neither is the DLC; a separate PSN PKG would be needed

## Header cryptanalysis strategy

Tool: [`tools/ps3_wad_header_crack.py`](../tools/ps3_wad_header_crack.py)  
Report: `analysis/cross_platform/ps3_header_crack/ps3_header_crack_report.md`

### Layout hypothesis (verified)

| Region | Size | Role |
|--------|------|------|
| `0x00000`–`0x7FFFF` | 16 × 32 KiB | Encrypted FFCS metadata (INDX/ASET/PTHS/CSUM equivalent) |
| `0x80000`–`0x807FF` | 0x800 | Gap / bridge (unknown) |
| `0x80800`–EOF | ~1 GiB − 0x80800 | Cleartext big-endian **`segs`** DATA |

The envelope is **not** a single XOR layer: first-12-byte XOR against an SCFF template
does not yield a repeating key, and per-INDX-entry XOR streams differ → **stream cipher**
(AES-CTR, RC4, or custom PRNG in EBOOT).

### Attack order (late-2000s RE playbook)

1. **Structural bypass** — Walk all `segs` blocks (no header). Decompress each block;
   scan decompressed UCFX wrappers for `name_hash == 0xB4420059` (`vz`) or ~114 BINN
   records. CPU-heavy but avoids the cipher entirely.
2. **Known-plaintext INDX** — Catalog `(rel_page_index, page_count)` from every `segs`
   offset; assume PC layout (`INDX` at `0x8000`, 12-byte BE triplets). XOR with
   ciphertext to recover keystream; analyze for RC4/AES-CTR period.
3. **Transform battery** — Single-byte XOR, repeating XOR, zlib at common offsets,
   `segs` decompress at 0, bswap32, AES-128 ECB/CBC with title-derived keys
   (`BLUS30056`, `MERCENARIES2`, MD5/SHA1 of path strings). None succeeded on retail
   sample without EBOOT key.
4. **EBOOT / ISO** — Decrypted `EBOOT.elf` is available via `scripts/decrypt_ps3_eboot.sh`
   (oscetool + `appldr` key revision 1). See `docs/ps3_eboot_analysis.md`.
   Next: PPC xref from `VZ.WAD` string → header decrypt routine.

### What does *not* work

- Plaintext `scripts_vz` / `FFCS` / `SCFF` anywhere in the file (full-file scan)
- Single-byte XOR to reveal `INDX` at `0x8000`
- AES-128 with guessed title/path keys (see crack report)
- Decompressing the header as one `segs` block at offset 0

## Next steps

- Run `ps3_wad_header_crack.py` after any new PS3 dump or EBOOT revision
- Compare PS3 `segs` catalog (~5.4k blocks in 1 GiB) vs Xbox INDX (11,087 blocks)
- Decrypt EBOOT / hook `cellFsRead` on `VZ.WAD` for the real keystream
- Xbox DLC path remains the fastest route to playable PC content
