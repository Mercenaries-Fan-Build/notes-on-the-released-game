# WAD Simulator (Rust)

Engine-accurate consumption simulator for Mercenaries 2 FFCS `.wad` archives. Mirrors
Python pipeline decoders where practical and validates converted LE blocks after DLC
byte-swap.

## Workspace crates

| Crate | Binary | Role |
|-------|--------|------|
| `mercs2_formats` | (lib) | FFCS/UCFX parsing, type hashes, shared chunk validators |
| `ucfx_byteswap` | `ucfx_byteswap` | Xbox 360 BE → PC LE block conversion + post-swap validation |
| `wad_simulator` | `wad_simulator` | ASET OOB audit + full asset consumption simulation |

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
```

## Related docs

- `docs/watermap_format.md`, `docs/fxdict_format.md`
- Python counterparts: `tools/watermap_decode.py`, `tools/fxdict_codec.py`, `tools/ucfx_mesh_codec.py`
