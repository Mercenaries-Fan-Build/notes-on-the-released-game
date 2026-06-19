# Mercenaries 2 Rust Tools (v1.0.0)

A comprehensive Rust toolkit for Mercenaries 2 modding and analysis.

## Published Crates

All crates available on crates.io:

| Crate | Version | Binary | Role |
|-------|---------|--------|------|
| [mercs2_formats](https://crates.io/crates/mercs2_formats) | 1.0.0 | (lib) | FFCS/UCFX parsing, type hashes, shared chunk validators |
| [ucfx_byteswap](https://crates.io/crates/ucfx_byteswap) | 1.0.0 | `ucfx_byteswap` | Xbox 360 BE → PC LE block converter + validator |
| [loadprobe](https://crates.io/crates/loadprobe) | 1.0.0 | `loadprobe` | Game log analyzer (pmc_blackbox.log) with crash/hang detection |
| [wad_simulator](https://crates.io/crates/wad_simulator) | 1.0.0 | `wad_simulator` | Engine-accurate WAD consumer with ASET OOB detection |

## Installation

### From crates.io (recommended)

```bash
# Install individual tools
cargo install mercs2_formats  # Library only, use in your own code
cargo install ucfx_byteswap  # Xbox BE→PC LE converter
cargo install loadprobe       # Game log analyzer
cargo install wad_simulator   # WAD consumption simulator
```

### From source

```bash
git clone https://github.com/Mercenaries-Fan-Build/notes-on-the-released-game.git
cd notes-on-the-released-game/tools/wad_simulator
cargo build --release --workspace
```

## Validation coverage

### `ucfx_byteswap` (post-conversion, `--strict` optional)

- Entry table + CSUM per UCFX container
- Descriptor bounds, STRM/BNDS float sanity, IBUF index bounds
- **DEPS**: `u8` count + `u32` hash array size (`1 + 4×count`)
- **watr**: 257×257 grid, 5 layers, payload **495 669** bytes
- **fxdict**: INFO `entry_count` + DICT `20 × count` bytes
- **SKIN**: container sentinel, INFO hash child, nested PRMG child

### `wad_simulator` (consumption pass)

- Models: GEOM/STRM/IBUF/BNDS/HIER/PRMG, DEPS, SKIN structure
- Layers: placement records + flgs (vz_state)
- Textures, scripts, animations (structural)
- Audio: wavebank INFO + IMA payload, soundbank xref, `.pws` audit
- Resident: **watermap** (`watr`), **fxdict** (INFO+DICT)
- **material_params**: MTRL preamble (≥104 B), PRMT alignment

DEPS endian swap is handled in `ucfx_byteswap` convert (count byte preserved).

## Build (Windows)

Requires MSVC linker (repo `msvc/setup_x64.bat`):

```bat
cmd /c "call msvc\setup_x64.bat && cd /d tools\wad_simulator && cargo build --release 2>&1"
```

## Usage

```bat
REM ASET OOB + full consumption (patch over base)
wad_simulator --wad output\data\vz-patch.wad --base-wad game-files\pc-game-vz.wad

REM Audio / PWS only
wad_simulator --wad game-files\pc-game-vz.wad --audio-only --audios-dir "path\to\Audios"

REM Convert one decompressed BE block to LE
ucfx_byteswap input.block.bin -o output.block.bin --strict

REM Validate retail PC LE block (stage 2 post-pass; no conversion)
ucfx_byteswap --validate-only path\to\block.bin
```

### Stage 2 integration

After `make review-all`, optional structural checks:

```bash
make build-ucfx-byteswap
make stage2-post-validate OUTPUT=./output
# or inline:
make review-all OUTPUT=./output STAGE2_VALIDATE_RUST=1 STAGE2_VALIDATE_GLTF=1
```

See `docs/stage2_review_improvements.md`.

## Related docs

- `docs/watermap_format.md`, `docs/fxdict_format.md`
- Python counterparts: `tools/watermap_decode.py`, `tools/fxdict_codec.py`, `tools/ucfx_mesh_codec.py`
