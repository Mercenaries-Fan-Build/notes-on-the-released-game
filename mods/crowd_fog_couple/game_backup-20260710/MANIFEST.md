# crowd_fog_couple — game-folder backup (2026-07-10)

Snapshot of the modded state of `C:\Users\Shadow\Desktop\Mercenaries 2 World in Flames\` taken right
before restoring stock config. Everything here is reversible.

## What was live (the "our changes" set)
| File | sha256 | Was at | Notes |
|------|--------|--------|-------|
| `crowd_fog_couple.asi` | `e7c65a3b7ae7000de4be5d48ce425b646e86657edf06f1515afc8a1873c6f703` | `<game>/scripts/` | the 5-patch render-distance ASI (fog/cull/reach/density/geometry-LOD) |
| `cdbsizes.ini.LIVE-b968bfee` | `b968bfeeb7d5ad2db4636dfab8851b72b3b439c491f8a32764dd214f85a19deb` | `<game>/data/cdbsizes.ini` | **~2× actor/pop/vehicle pool bump** (Ai 1024→2048, ControllerCar 64→128, PopulationDensity 128→256, _HumanPhysics 384→768, …). NOT applied by the 2026-07-10 session — pre-existing external edit that pairs with the ASI's density hook. |
| `Mercs2.ini.LIVE-stock` | `0ac99dff1eec49ada563328bdcaaa435d7f7bc17efd6d5fe2b66948ae324dbae` | `<game>/Mercs2.ini` | already stock (ASI drives fog at runtime, so the INI needs no edit) |
| `crowd_fog_couple.log`, `.log.prev` | — | `<game>/` | runtime logs from test runs |

## Restored-to-stock state (current)
- `<game>/data/cdbsizes.ini` → `5c31ac5b…` (stock, from `docs/game_config/cdbsizes.ini`)
- `<game>/Mercs2.ini` → `0ac99dff…` (stock, unchanged)
- `<game>/scripts/crowd_fog_couple.asi` → removed
- Other mods (`windowed_mode.asi`, pmc_bb, lua_trace, …) → untouched

## Re-deploy the mod later
```sh
G="/c/Users/Shadow/Desktop/Mercenaries 2 World in Flames"
# 1) the ASI (fog/cull/reach/density/geometry) — rebuildable from ../src via ../Makefile
cp "mods/crowd_fog_couple/crowd_fog_couple.asi" "$G/scripts/"
# 2) (only if you want the higher crowd/vehicle CAPS) the ~2x pool bump:
cp "mods/crowd_fog_couple/game_backup-20260710/cdbsizes.ini.LIVE-b968bfee" "$G/data/cdbsizes.ini"
```
The ASI's defaults keep live counts inside STOCK pools, so step 2 is optional — needed only if you
raise `CROWD_PED_CAP`/`CROWD_VEH_CAP` past the conservative defaults. Verify by hash after copying.
```
```
