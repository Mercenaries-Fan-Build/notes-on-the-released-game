# Vanilla boot — expected Lua script load/exec order (bisect reference)

Reconstructed from the decompiled resident Lua (`docs/mercs2-luacd/src/resident/`). This is the
**expected order a vanilla boot runs**, to bisect against a live `pmc_bb` trace (`pmc_blackbox.log` —
[[pmc-bb-native-lua-logging]]): run the retail game with `pmc_bb.dll`, then diff its `[lua]` print
order against this. **Where our reimpl hardcodes a value, the vanilla source is called out** — those are
the seams to wire so "that hardcoded shit" is gone.

## The chain

```
1. Init.lua                       engine entry — Init() sets tEvents (weapon-anim event table); no boot logic
2. gamebootstrap.lua  (GameBootstrap)
     import LevelBootstrap, MrxSoundBootstrap, MrxGuiShellBootstrap, MrxGuiBase
     ├─ SHELL path:  MrxGuiShellBootstrap.LoadShell() → EnterShell()      [main menu + save browser]
     └─ PLAY  path:  LevelBootstrap.LoadLevel(Sys.GetLevelName(), Sys.GetMasterScriptName())
3. levelbootstrap.lua :: LoadLevel(LevelName, MasterScript)
     Sys.SetLevelName / SetMasterScriptName
     Sys.RequiredAsset(LevelName.."_base", "layer",  -2)     ← the level base layer (the world)
     Sys.RequiredAsset(MasterScript,        "script", -3)     ← the master script (below)
     Sys.RequestGameState("Loading")                          ← engine streams the level, then runs the master
4. mrxbootstrap.lua   (the MASTER SCRIPT for vz)
     import MrxSoundBootstrap, MrxFactionManager, MrxGuiBootstrap, MrxLayerManager,
            MrxSupportData, MrxPlayer, MrxPmc, MrxState, MrxUtil
     Start():
        _sHeroSpawnLocation = nil
        MrxGuiBootstrap.SetOnGuiLoadedFunc(_GuiLoaded)
        MrxPlayer.SetLocalPlayerJoinedCallback(_LocalPlayerJoined)
        MrxPlayer.Start()
     SetDefaultAtmosphere()                                   ← the default "afternoon" atmosphere
5. MrxPlayer.OnPlayerJoined(id, name, cfg, bLocal, …)         [fires when the local player joins]
        vSpawnLocation = Player.GetPlayerStart()              ★ HERO SPAWN LOCATION (engine binding, world data)
        (or _tSpawnLocations[id+1] if SetSpawnLocations ran)
        CreatePlayerCharacter(bLocal, id, sTemplate, vSpawnLocation)   ★ HERO ENTITY CREATED HERE
6. _GuiLoaded()  →  MrxState.Enter(MrxState.STATE_WAITFORGAME, _End)
7. MrxPmc / MrxHq boot:
        MrxHq:_LoadInterior()
           MrxLayerManager.Add(self.tLayers, …)              ← vz_state overlays for the HQ
           vPosition = {3750, 450, -3840}                    ★ PMC INTERIOR ORIGIN (Lua literal, mrxhq.lua:652)
           MrxUtil.SpawnActor(self.tInterior.sTemplate, "HqInterior", vPosition, …)   ★ PMC BLOCKS SPAWN HERE
        MrxUtil._TeleportHero (via _TeleportHeroes / TeleportHeroesToLocations)
           Object.SetPosition(uHero, nX, nY, nZ, false)      ★ HERO TELEPORT (mrxutil.lua:328)
8. _End()  →  MrxState.Exit(STATE_WAITFORGAME)
        if Sys.StartWithResources(): MrxPmc cheats (cash/fuel/support) — dev boots only
```

`★` = a value our reimpl currently hardcodes. There are exactly three:

| ★ Seam | Vanilla source | Our reimpl today (the hardcode to kill) |
|---|---|---|
| Hero spawn location | `Player.GetPlayerStart()` (world player-start marker in the level data), else `_tSpawnLocations` | `PMC_INTERIOR_SPAWN = [3794.04, 450.75, -3911.03]` const (world.rs); exterior `[2560.26, -13.18, -926.25]` const |
| Hero teleport | `Object.SetPosition(uHero, …)` — now **wired** (`a1e5820`: hero is Lua-addressable, `Object.SetPosition` records the spawn) | (consumer of the above; mechanism done, source pending) |
| PMC interior blocks | `MrxHq:_LoadInterior` → `SpawnActor("HqInterior", {3750,450,-3840})` (Lua literal), realized via template→geometry | `load_world_data(spawn_interior)` loads the interior meshes DIRECTLY (`PMC_INTERIOR_ACTOR_ORIGIN` const); the `SpawnActor` intent is recorded but not realized (template→geometry unresolved) |

## How our default boot diverges (what to bisect)

Our `run_scene_world_loading` today short-circuits steps 2–7: it skips the `gamebootstrap → LoadLevel →
mrxbootstrap → OnPlayerJoined` chain and instead **hardcodes** the hero spawn + **directly loads** the
interior geometry. To match vanilla (and delete the hardcodes), the resident host (K1, live) must run
this chain, and the engine must back the three bindings the chain bottoms out on:

1. **`Player.GetPlayerStart()`** — return the level's player-start (decode the world player-start
   marker / take it from the save). Then `MrxPlayer.OnPlayerJoined` spawns the hero there; our
   `PlayerController` binds to `HERO_GUID` so `Object.SetPosition` moves it — **kills the spawn const**.
2. **`Sys.RequiredAsset(level_base, "layer")` / `Sys.RequestGameState("Loading")`** — our streaming
   loader is what services these (K2). Run `LoadLevel` → the streaming world loads as vanilla does.
3. **`SpawnActor("HqInterior") → geometry`** — the template→geometry resolver (the open sub-problem):
   once `"HqInterior"` resolves to the interior meshes, `MrxHq:_LoadInterior` spawns the blocks and the
   direct `load_world_data(interior)` is deleted — **kills the interior const**.

## Bisect procedure

1. Run retail vz with `pmc_bb.dll`; capture `pmc_blackbox.log`.
2. Grep its `[lua]` prints for the `@@@@@@@@@@` markers (`MrxPlayer.CreatePlayerCharacter`,
   `MrxUtil._TeleportHero: Teleporting to X,Y,Z`, `MrxHq: Spawning interior for HQ`) — that gives the
   **real GetPlayerStart coord + teleport coord + interior origin + the exact call order**.
3. Diff that order against this chain and against what our resident host actually executes (its own
   `[lua]`/println trace). The first divergence is where to wire next; the captured coords are the
   values our `Player.GetPlayerStart` must return (proving the const is dead, not guessed).
