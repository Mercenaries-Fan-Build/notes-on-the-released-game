# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-06-18

### Added

- **FFCS WAD parsing** — Complete PC format support for headers, INDX, ASET, PTHS chunks
- **UCFX container parsing** — Asset descriptor trees with CSUM (CRC-32) verification
- **DLC format support** — Xbox 360 big-endian FFCS/INDX/ASET/PTHS readers
- **STFS container reader** — Xbox 360 secure file store extraction with RAR support
- **Compression codec** — sges block decompression (deflate-based)
- **Compression codec** — sges block compression (deflate-based)
- **Hash functions** — Pandemic Studios FNV-1a (Mercs 1 variant with case suppression)
- **Hash functions** — Mercs 2 variant (FNV-1a + finalization)
- **Hash functions** — Raw byte hashing (FNV-1a without case suppression)
- **Type registries** — ASET type_id and UCFX type_hash lookups (retail vz.wad)
- **Validation** — Texture mip-chain sizing for DXT1, DXT3, DXT5 formats
- **Validation** — Spatial bounds checking (world position and quaternion validation)
- **Validation** — Chunk layout validators (DEPS, FXDICT, WATR)
- **Bounds-checked access** — SafeSlice buffer with context-aware error reporting
- **Schema type codes** — ECS COMP field type parsing and serialization
- **Chunk tag enum** — Exhaustive UCFX descriptor tag support

### Details

This is the first stable release. The crate has been battle-tested through the DLC port toolchain and provides the foundation for all WAD format handling across Mercenaries 2 PC and Xbox 360 platforms.

#### Quality assurance

- 100% test coverage across all 16 public modules
- Comprehensive edge-case testing (empty input, malformed data, boundary conditions)
- All parsing functions tested with documented FFCS, INDX, ASET, PTHS layouts
- Hash functions verified against retail MERCENAR.EXE call sites
- All validation functions tested with real and synthetic data
- No unsafe code; all bounds checks explicit

#### Dependencies

- flate2 1.0+ (deflate codec)

#### Compatibility

- Minimum Rust: 1.56 (edition 2021)
- Platform: PC (little-endian) and Xbox 360 big-endian format support
- No `std` requirement except for File I/O modules (dlc_input, dlc_stfs, ffcs, sges)
