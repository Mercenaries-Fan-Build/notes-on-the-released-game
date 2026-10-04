# Plan: land the DLC01 shader-key repoint as a Rust helper

**Status:** proposed · **Pairs with:** `docs/_dlc01_shader_name_recovery.md`
and `tools/dlc01_shader_key_repoint.py`.

## Context

`tools/dlc01_shader_key_repoint.py` is the shipping fix for the 219 DLC01
MTRL records that cite PC-unregistered pixel-shader hashes. The project
mandate is Rust-first; the Python one-shot exists because the DLC01 PC boot
test was gated on the fix today and this agent's worktree isolation blocks
edits to the nested `tools/wad_simulator/` crates. This plan lays out the
native landing.

## Target code change (Rust)

### Library helper -- `mercs2_formats::model_edit::mtrl`

Add a sibling to the existing `repoint_container_textures`:

```rust
/// Repoint pixel-shader keys inside the MTRL material array per `(old -> new)`.
///
/// Walks every MTRL leaf in the container, iterates each material record
/// (stride `116 + count*4`), replaces any shader key the remap names, and
/// recomputes the trailing CSUM.
pub fn repoint_container_shader_keys(
    container: &mut Vec<u8>,
    remap: &std::collections::HashMap<u32, u32>,
) -> Result<usize, String>;
```

Record offsets (confirmed in `docs/shader_store_format.md` section 6):
- `+104` u16 flags, `+106` u16 tex_count (count is in the high half of the LE u32 marker)
- `+108 + 4*tex_count` u32 pixel-shader key (the repoint target)
- Record stride `116 + 4*tex_count`
- Record detection: `1 <= tex_count <= 10 && (flags & 0x0080) != 0`

**Multi-MTRL note:** the current `find_chunk` in that file returns only the
first MTRL descriptor leaf. The Python repoint learned the hard way that
multi-material containers (e.g. DLC01 `rocks01_r*_c*` blocks) carry one MTRL
leaf per material group -- walking only the first missed 19 of 29
`0x3973c300` refs. Introduce a sibling `find_chunks` returning
`Vec<(usize, usize)>` and iterate every leaf. Keep `find_chunk` for the
callers that know their container has one.

CSUM equivalence between the Python `crc32_mercs2`
(`zlib.crc32(data, 0xFFFFFFFF) ^ 0xFFFFFFFF`) and the Rust `crc32_mercs2`
(byte-by-byte init=0 CRC-32 with reversed poly `0xEDB88320`) is verified on
`test` / `UCFX` / zeros / `hello world`.

### CLI entry point -- `mercs2_probe --bin shader_key_repoint`

A new `src/bin/shader_key_repoint.rs` modelled on `aset_refcheck.rs`:

- `--input <wad>` -- FFCS patch WAD to read.
- `--output <wad>` -- destination.
- `--remap <OLD>:<NEW>` -- repeatable; a built-in default `0xf931343a:0x343af931,0x3973c300:0x343af931`
  may be exposed as `--default-dlc01`.
- Driver flow (mirrors the Python one-shot):
  1. `patch_wad::read_patch_wad(raw)` for INDX/ASET/PTHS/compressed-data.
  2. For each block: `sges::decompress_sges` -> `ucfx::walk_decompressed_block`
     -> for each container, call `repoint_container_shader_keys`.
  3. For each block that mutated: `PatchBlock::from_decompressed` to
     recompress with the preserved tier byte.
  4. Preserve CSUM-row value + meta + cert blob from the input's raw header
     (an extension to `read_patch_wad` to return `csum_meta` would simplify
     this; today `dlc_port::main` reads the CSUM row directly).
  5. `patch_wad::build_patch_wad_multi(blocks, csum_value, csum_meta, &FFCS_CERT_BLOB)`.
- Exit code: 0 on clean run; non-zero if any container's MTRL walk failed
  (unexpected CSUM mismatch, out-of-range body) -- never fall back silently.

### Tests

- `mercs2_formats/tests/`: a round-trip against a hand-rolled 2-leaf MTRL
  container -- rewrite 2 of 3 keys, assert CSUM reseals, byte-identical for
  the untouched key, byte-identical rebuild of the unmodified leaves.
- `mercs2_probe/tests/`: when `vz.wad` is discoverable
  (`find-vz-wad.sh --write`), execute the subcommand against a fixture
  patch WAD built via `build_patch_wad_multi`, run the classifier, and
  assert zero unresolved. Guard with the `SKIPPING` marker; grep the run.

## Retire the Python one-shot

Once the Rust path is landed and verified against `game-files/vz-patch.wad`:

1. Rename `tools/dlc01_shader_key_repoint.py` to `.legacy.py` (or delete it)
   and point `docs/_dlc01_shader_name_recovery.md` section 2.3 at the Rust
   binary.
2. Update the DLC01 port pipeline (`tools/dlc_port.py` / nested
   `mercs2_formats::patch_wad`) to run the repoint pass as a hermetic step
   before CSUM/ASET validation, so no future rebuild of `vz-patch.wad`
   ships the 219 records un-repointed.

## Scope / non-goals

- Do NOT attempt path-(a) shim-register in this landing. Name recovery
  across the PS3 EBOOT.elf + both Xbox decomps + the PC exe failed; shipping
  a shim without the real logical name requires inventing one, which the
  user mandate forbids ("Never invent a hash" / "Ask, don't assume").
- Do NOT change `aset_refcheck`'s contract. The repointed output has the
  same block count and block order as the input; LOD rungs stay valid.
- Do NOT introduce a "fallback / null shader" code path for mystery hashes
  (triage §5 option c). Masking a mystery key with a universal fallback
  hides future bugs; keep the remap explicit.
