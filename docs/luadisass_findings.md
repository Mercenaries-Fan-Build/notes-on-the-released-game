# LuaDisAss integration notes

**Date:** 2026-05-15

## Upstream

- Repository: https://github.com/jcmnn/LuaDisAss  
- Mercenaries 2 `scripts_vz` uses the **`LuaQ` signature** (114 chunks in retail `03197_blocks__VZ__scripts_vz_P000_Q3.block.bin`).

## This repo

- **Chunk splitter / string harvest:** [`tools/lua_script_chunks.py`](../tools/lua_script_chunks.py)  
  - Writes `output/lua_chunks/scripts_vz/*.chunk.bin`  
  - Writes `output/placements/pmc_lua_string_harvest.{json,csv}`

- **Optional disassembly:** if `LUADISASS` environment variable points to a working disassembler entry script, `lua_script_chunks.py` attempts to emit `.luaasm` files. **The default Mercs2 tree does not vendor LuaDisAss** (license/size); clone upstream locally and point `LUADISASS` at your checkout.

## Known gaps / bugs to file upstream after repro

1. **Lua version byte** in `LuaQ` header must be matched to the correct disassembler fork (5.0 vs 5.1 vs custom). Confirm with first-chunk header bytes before batch-disassembling.  
2. **Control-flow recovery** on game bytecode may still be partial — treat disassembly as hints, not ground truth.  
3. **String-only harvest** in-repo is intentionally conservative (regex for PMC / layer / spawn tokens).

## Manual verification (PMC)

Cross-check `pmc_lua_string_harvest.csv` against:

- `vz_state_pmcinterior*` filenames in `paths.txt`  
- Save-game `vz_layer_strings` (see `docs/game_data_analysis.md`)
