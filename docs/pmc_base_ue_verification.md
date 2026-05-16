# PMC base — UE5 manual verification checklist

**Date:** 2026-05-15  
**Scripts:** [`import_pmc_base.py`](../../UnrealEngineGame/Content/Python/import_pmc_base.py), [`populate_pmc_base.py`](../../UnrealEngineGame/Content/Python/populate_pmc_base.py)

## Preconditions (host machine)

1. `make ue5-bundle OUTPUT=./output`  
2. `make extract-placements OUTPUT=./output`  
3. `make filter-pmc-base OUTPUT=./output`  
4. `make regen-pmc-glbs OUTPUT=./output` (recommended so GLBs exist for PMC meshes)  
5. Open the target map in UE 5.7 (same workflow as Maracaibo demo).

## Editor steps

1. **Run Python:** `import_pmc_base.py` — imports under `/Game/Mercs2/Meshes/PMCBase/`.  
2. **Run Python:** `populate_pmc_base.py` — spawns `StaticMeshActor`s under `World/PMC/Base` (visible) and `World/PMC/HiddenInterior` (hidden).  
3. **Outliner:** select `World/PMC/HiddenInterior`, **Alt+H** to show interior `vz_state_pmcinterior_*` props and compare against **retail or demo** gameplay around PMC HQ.  
4. **Console / stats:** note actor count vs `output/placements/pmc_base.json` length (dedup may skip collocated props).

## Pass / fail criteria

| Check | Pass |
|-------|------|
| HQ island props roughly match reference screenshots / in-game PMC | Visual spot-check |
| Interior props do **not** appear before Alt+H on HiddenInterior | Streaming MVP behaviour |
| Five `pmcinterior` variants exist as separate hidden batches (same mesh names may repeat) | Outliner source filenames differ |
| No white materials on major buildings | Interchange import path intact |

## Known limitations (this iteration)

- No `EntranceLink` trigger volumes yet — ECS portal rows are still partial (`docs/ecs_components.md`).  
- No Lua-driven `RuntimeLayer.Activate` — see `output/placements/pmc_lua_string_harvest.csv` for string leads.  
- `populate_pmc_base` uses **editor hide**, not World Partition **Data Layers** / runtime streaming.
