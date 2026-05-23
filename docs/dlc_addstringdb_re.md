# AddStringDb — reverse-engineering notes (Phase 3)

**Status:** Path plausible, not fully proven in Ghidra on current EXE.

## PC retail anchor

| Symbol | VA (file) | Notes |
|--------|-----------|-------|
| `Sys.AddStringDb` | `0x005E6180` | See [`exe_analysis_agent_a.md`](exe_analysis_agent_a.md) |

## Working hypothesis (vz-patch)

1. ASI / bootstrap calls `Sys.AddStringDb("patch01", "dlc01")`.
2. Engine resolves the second argument to a stringdb asset name such as `english_dlc01` (language prefix + module).
3. Lookup uses the same **RedVirtualDisk** overlay as `import()` — last-mounted WAD wins for matching `asset_hash`.
4. Patch WAD carries seven `{lang}_dlc01` stringdb blocks (indices vary by build); synthetic ASET rows (`type_id=7`) may be added by `dlc_port.py` when Xbox global ASET omitted them.

## Mac verification

```bash
.venv/bin/python3 tools/dlc_stringdb_forensic.py \
  --base-wad game-files/vz.wad \
  --patch-wad output/data/vz-patch.wad
```

**Decision (Phase 0f):** `_fix_stringdb_descriptors` stays **disabled by default** — heuristic byte-walk can corrupt bodies while CSUM still passes.

## Ghidra tasks (Windows / headless)

1. Decompile @ `0x005E6180` — confirm argument → hash → `RedVirtualDisk` vs separate string table.
2. Trace whether `"patch01"` is a WAD mount label or namespace only.
3. Compare retail `english_P000_Q3` load path vs DLC `english_dlc01_P000_Q3`.

## If vz-patch stringdb insufficient

See [`ui_blocks_inventory.md`](ui_blocks_inventory.md) and [`game_data_analysis.md`](game_data_analysis.md) for `shell-patch.wad` / `English-patch.wad` — only after Ghidra proves AddStringDb does not resolve from `vz-patch.wad` alone.
