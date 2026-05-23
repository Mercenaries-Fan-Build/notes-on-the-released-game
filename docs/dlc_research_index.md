# DLC research index

Central index for Mercenaries 2 Xbox 360 → PC DLC port work. **Phase 0 outcomes** are recorded in [`analysis/cross_platform/phase0_baseline_report.md`](../analysis/cross_platform/phase0_baseline_report.md).

## Known-good baseline: Row 13

| Item | Evidence |
|------|----------|
| Config | 2196 DLC blocks + **one** `scripts_vz` bootstrap (nohook: 114 retail-identical + `dlc01` @115) |
| Stability | 30+ min freeplay, no crash |
| Activation | ASI `import("dlc01")` + `Sys.AddStringDb("patch01","dlc01")` → **4 Fiona contracts** |
| Doc | [`analysis/cross_platform/pc_bisect_results.md`](../analysis/cross_platform/pc_bisect_results.md) |

**Phase 1 bar:** boot + import + AddStringDb + 4 contracts — not “boot only.”

## Phase 0 tools (Mac)

| Tool | Purpose |
|------|---------|
| [`tools/dlc_phase0_baseline.py`](../tools/dlc_phase0_baseline.py) | WAD hashes, resident BE/LE gate, import chain, stringdb forensic → report |
| [`tools/verify_dlc_import_chain.py`](../tools/verify_dlc_import_chain.py) | Overlay ASET + bootstrap + block 464 LuaQ endian |
| [`tools/dlc_stringdb_forensic.py`](../tools/dlc_stringdb_forensic.py) | Retail vs ported stringdb descriptor compare |
| [`tools/fix_dlc01_aset_type.py`](../tools/fix_dlc01_aset_type.py) | In-place: type_id=35, dedupe dlc01 → scripts_vz @2196 |
| [`tools/fix_patch_script_aset_dupes.py`](../tools/fix_patch_script_aset_dupes.py) | Clear script ASET on resident 464 when scripts_vz exists (Shell-exit crash) |
| [`tools/inventory_dlc_patch.py`](../tools/inventory_dlc_patch.py) | Bucket 2196+ paths → JSON inventory |
| [`tools/aset_type_ids.py`](../tools/aset_type_ids.py) | `type_hash` → ASET `type_id` map (35 types) |
| [`tools/dlc_aset_normalize.py`](../tools/dlc_aset_normalize.py) | Port-time ASET normalize + dedupe |

### Phase 0 gates (2026-05-23)

| Gate | Result |
|------|--------|
| `output/data/vz-patch.wad` vs `fresh-rebuilt/` | **Different** sha256 — not byte-identical |
| Resident block 464 LuaQ | **0 BE / 36 LE** — PC-loadable bytecode |
| Drop `scripts_vz` for bytecode alone? | **No** — Row 13 still needs bootstrap registration @115 |
| `_fix_stringdb_descriptors` | **Default off** in `dlc_port.py`; use `--fix-stringdb-descriptors` only after forensic proof |
| `dlc01` ASET | Prefer **scripts_vz block 2196**, type_id=35; remove type_id=26 duplicates |

## Port pipeline

| Doc / tool | Content |
|------------|---------|
| [`tools/dlc_port.py`](../tools/dlc_port.py) | Xbox DOH → PC `vz-patch.wad` + optional bootstrap |
| [`docs/patch_wad_format.md`](patch_wad_format.md) | FFCS overlay, local `block_index`, last-opened-wins |
| [`docs/aset_format.md`](aset_format.md) | ASET row layout + type table |
| [`docs/type_hash_registry.md`](type_hash_registry.md) | All 35 `type_hash` values |
| [`Makefile`](../Makefile) | `dlc-port`, `dlc-port-assets-only`, `dlc-phase0`, `inventory-dlc-patch` |

### `dlc_port.py` flags (bisect / Row 13)

| Flag | Default | Notes |
|------|---------|-------|
| `--no-hook` | Makefile sets | Row 13: do not patch `wifmissionflow` |
| `--no-bootstrap` | off | 2196 blocks only — **boot baseline**, not success |
| `--fix-stringdb-descriptors` | off | Heuristic SYEK/SRTS fix — dangerous if wrong |
| `--no-synth-stringdb-aset` | off | Synthetic stringdb ASET for `AddStringDb` |

## Activation & runtime

| Doc | Content |
|-----|---------|
| [`docs/dlc_pc_activation_checklist.md`](dlc_pc_activation_checklist.md) | Deploy + Windows test checklist |
| [`docs/dlc_loader_cross_reference.md`](dlc_loader_cross_reference.md) | Engine load path cross-ref |
| [`docs/dlc_extras_activation_research.md`](dlc_extras_activation_research.md) | Skins, weapons, vehicles beyond missions |
| [`tools/dlc_enable_asi/dlc_enable.c`](../tools/dlc_enable_asi/dlc_enable.c) | ASI: VZ load, `import("dlc01")`, `AddStringDb`, contracts |

## Content gaps (missions vs arena)

| Doc | Content |
|-----|---------|
| [`docs/dlc_arena_loading_analysis.md`](dlc_arena_loading_analysis.md) | Why missions work in Venezuela but arenas need `SetMasterScriptName` / layers |
| [`analysis/cross_platform/dlc_patch_inventory.json`](../analysis/cross_platform/dlc_patch_inventory.json) | Path buckets for all patch blocks |
| [`docs/xbox360_dlc_analysis.md`](xbox360_dlc_analysis.md) | STFS / DOH structure |

**Arena (after Row 13 stable):** set `DLC_ENABLE_ARENA_TRANSITION` to `1` at top of [`tools/dlc_enable_asi/dlc_enable.c`](../tools/dlc_enable_asi/dlc_enable.c) (default `0`), rebuild with `make dlc-asi-native`, watch `dlc_enable_crash.log` for `[ARENA]` lines — see arena doc §3.

## Localization (Phase 3)

| Item | Status |
|------|--------|
| `Sys.AddStringDb("patch01", "dlc01")` | **Plausible** — resolves `<lang>_dlc01` via patch ASET (7 lang blocks in patch) |
| RE notes | [`docs/dlc_addstringdb_re.md`](dlc_addstringdb_re.md) |
| Ghidra `AddStringDb` @ `0x005E6180` | **Pending** — confirm RedVirtualDisk vs separate table ([`docs/exe_analysis_agent_a.md`](exe_analysis_agent_a.md)) |
| `shell-patch` / `English-patch` | Only if vz-patch stringdb insufficient ([`docs/ui_blocks_inventory.md`](ui_blocks_inventory.md)) |

## Cross-platform analysis

| Path | Content |
|------|---------|
| [`analysis/cross_platform/pc_bisect_results.md`](../analysis/cross_platform/pc_bisect_results.md) | Windows bisect matrix |
| [`analysis/cross_platform/scripts_vz_platform_diff.md`](../analysis/cross_platform/scripts_vz_platform_diff.md) | `dlc01` not in retail PC `scripts_vz` |
