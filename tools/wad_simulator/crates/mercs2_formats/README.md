# mercs2_formats

Binary format parsers and validators for Mercenaries 2 asset containers.

This crate provides comprehensive support for parsing, validating, and transforming Mercenaries 2 WAD file formats across PC and Xbox 360 platforms. It is a critical dependency for the DLC port toolchain and blocks publication of `ucfx_byteswap`.

## Features

- **FFCS WAD parsing** — PC format headers, INDX/ASET/PTHS chunks
- **UCFX container parsing** — Asset descriptor trees with CSUM verification
- **DLC format support** — Xbox 360 big-endian FFCS readers and STFS container extraction
- **Compression/decompression** — sges block deflate codec
- **Hash functions** — Pandemic Studios FNV-1a (Mercs 1 and Mercs 2 variants)
- **Type registries** — ASET type_id and UCFX type_hash lookups
- **Validation** — Texture mip-chain sizing, spatial bounds checking, chunk layout validation

## Public modules

- [`aset_type_ids`] — UCFX `type_hash` → ASET `type_id` map (retail vz.wad registry)
- [`chunk_validate`] — Validators for documented UCFX chunk layouts
- [`crc32`] — Mercenaries 2 CSUM: CRC-32 init=0, no final XOR
- [`dlc_input`] — Big-endian Xbox 360 DLC input parsing (BE FFCS/INDX/ASET/PTHS readers)
- [`dlc_stfs`] — STFS container reader + RAR extraction
- [`ffcs`] — FFCS WAD header, INDX, ASET, PTHS parsing
- [`hash`] — Pandemic Studios FNV-1a hashing (Mercs 1 and Mercs 2 variants)
- [`patch_wad`] — FFCS patch-WAD assembly (PC output/writer)
- [`safe_slice`] — Bounds-checked byte buffer (models engine pointer dereferences)
- [`schema`] — ECS COMP schema field type codes
- [`sges`] — sges block compression and decompression
- [`tags`] — Exhaustive chunk tag enum for UCFX descriptor tags
- [`texsize`] — Texture mip-chain sizing (DXT format calculations)
- [`types`] — ASET type_id and UCFX type_hash registry
- [`ucfx`] — UCFX container parsing and CSUM verification
- [`world`] — Game world spatial constants and validation

## Testing

Run the full test suite:

```bash
cargo test --all-features
```

With coverage:

```bash
cargo tarpaulin --all-features --out Html
```

## License

MIT License — see [LICENSE](LICENSE)
