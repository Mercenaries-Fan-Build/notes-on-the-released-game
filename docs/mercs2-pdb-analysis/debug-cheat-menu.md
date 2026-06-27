# Debug / Cheat Menu (decompiled)

Scope: the developer debug menu, its per-item toggle callbacks, the F-key hotkey layer, and the in-game "Cheat Menu" (God Mode / Demigod / Infinite Ammo) that the Profile devkit build (`Mercs2_Xenon_P.exe`, Jul 11 2008, PowerPC/Xbox 360) ships with.

This whole document is grounded in the Xbox PowerPC decompilation `output/_ghidra_x360/xenon_decomp_named.c`. Every VA below was confirmed to exist in that file with the quoted snippet. Strings are quoted from `output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt`.

## Summary

The Profile build contains a large, fully-wired developer debug menu — *not* just dead strings. The menu is paged ("`Debug Menu page %d / %d   [%s]`", `DebugMenu`), each item is a named entry registered with a callback function pointer, and the toggle callbacks really do flip global flags and print a status line. The shipped string dump lists ~250 menu items spanning AI, streaming, rendering, physics, audio, animation, vehicles, camera, and a cheat sub-menu (`Open Cheat Menu` → `God Mode` / `Demigod Mode` / `Infinite Ammo` / `Show God Mode Et Al`). The decompiled toggle bodies are an extremely regular template, which makes the system easy to read.

## How it works (decompiled)

### 1. Menu-item registration: `FUN_82279978`

All debug-menu items are registered by calling `FUN_82279978(menu, name, callback, enabled, category, group, 0, 0)`. The registrar itself is a tail-call thunk into the (un-decompiled) menu API:

```c
==== FUN_82279978 @82279978  size=8 ====
void FUN_82279978(void)
{                   /* WARNING: Subroutine does not return */
  FUN_829167d8();
}
```

`FUN_829167d8` is an empty stub in this decomp (`@829167d8 size=4 { return; }`) — i.e. the actual `AddMenuItem` body lives in a module Ghidra recovered only as a trampoline. Because `FUN_82279978` is a thunk, the decompiler dropped its arguments in the *callee*, but the **call sites preserve the full argument list**, so the wiring is fully readable there. (unverified: the exact field meaning of the trailing args — `enabled`, `category`, `group` — is inferred from the call-site constants `1,5,…` / `1,8,…`, not from the registrar body, which is a stub.)

The three large registration builders found are:

- `RollingCacheDbg @8227aa80` — registers the AI / streaming / lane / spawn toggles (category arg `5`).
- `FUN_8227b480 @8227b480` — registers another page (category arg `8`).
- `FUN_8227b908 @8227b908` — a guarded registrar that walks up to 10 sub-objects (stride `0x14b0`) and registers when one passes a check.

`RollingCacheDbg` is the clearest example. It captures the menu handle once and registers each item with `{name_string, callback_fn}`:

```c
==== RollingCacheDbg @8227aa80 ====
  uVar1 = DAT_830ba98c;                              // the debug-menu object
  DAT_830ba940 = FUN_82279978(...,0x822777d0,1,5,0,0,0);  // "ShowPopMap"  -> ShowPopMap @822777d0
  DAT_830ba904 = FUN_82279978(uVar1,...,0x82276c90,1,5,0,0,0); // "GlobalSpawning" -> GlobalSpawning @82276c90
  DAT_830ba908 = FUN_82279978(uVar1,...,0x82276d50,1,5,0,0,0); // "DisplayLanePops" -> DisplayLanePops @82276d50
  ...
  DAT_830ba92c = FUN_82279978(uVar1,...,0x82277410,1,5,2,0,0); // "FreezeViewport" -> FreezeViewport @82277410
```

The third argument of each call is the **callback VA** — e.g. `0x82276c90` resolves to the named function `GlobalSpawning`. The return value (an item handle) is stashed in a `DAT_830ba9xx` global that the corresponding toggle reads back to refresh its on-screen label. So the chain is: builder registers `name → callback` and remembers the item handle in a global; the callback toggles a bool and re-stamps the item's text via that handle.

### 2. The toggle-callback template (27 identical bodies)

27 menu callbacks share a byte-for-byte template (size 188–192). `GlobalSpawning` is representative:

```c
==== GlobalSpawning @82276c90 ====
  bVar1 = DAT_836dba46 == '\0';     // read the toggle flag…
  DAT_836dba46 = bVar1;             // …and invert it (the actual state being toggled)
  if (DAT_830ba904 != 0) {          // if this item's menu handle exists
    iVar2 = FUN_82276b70(DAT_830ba98c);   // resolve the menu item's text buffer
    if (iVar2 != 0) {
      if (bVar1) { uVar3 = 0x...82011aa0; }  // "On"
      else       { uVar3 = 0x...82011aa4; }  // "Off"
      FUN_82918800(auStack_60,0x40,0x...82011a88,0x...82011aa8,uVar3); // snprintf "%s %s"
      FUN_829178a8(iVar2,auStack_60,0x3f);   // copy into the item label
      *(undefined1 *)(iVar2 + 0x3f) = 0;     // NUL-terminate
    }
  }
```

Key facts read straight from the code:
- The toggle's *real effect* is `DAT_836dba46 = !DAT_836dba46;` — a single global bool. The rest of the body just updates the menu label.
- `0x82011aa0` / `0x82011aa4` are the literal strings `"On"` / `"Off"` (the build's `Tog %s %s` label format at `0x82011a88` pairs the item name with this state).
- `FUN_82276b70(menuObj)` resolves the currently-highlighted item's text buffer (it indexes a 400-entry table at `menuObj+0xcf00`/`+0xd548`).

The toggle flags live in two flag-blocks: `DAT_836dba4x` (lane/spawn/road group) and `DAT_837e5bxx` (physics-link / box-collect / nav group). Confirmed members of the template family (callback VA → name → flag):

| Callback | VA | Flag global |
|---|---|---|
| `MindKiller` | `82276be0` | (special: gated on `DAT_830ba900` + a feature check, no own bool) |
| `GlobalSpawning` | `82276c90` | `DAT_836dba46` |
| `DisplayLanePops` | `82276d50` | `DAT_836dba47` |
| `RoadEndbits` | `82276e10` | `DAT_836dba45` |
| `SpawnTargets` | `82276ed0` | `DAT_836dba42` |
| `RenderLanes` | `82276f90` | `DAT_836dba44` |
| `LaneConnect` | `82277050` | `DAT_836dba48` |
| `NoSidewalkSpawn` | `82277110` | `DAT_836dba49` |
| `NoRoadSpawn` | `822771d0` | `DAT_836dba4a` |
| `RenderFCStates` | `82277290` | `DAT_836dba43` |
| `RenderSpawnPoints` | `82277350` | `DAT_836dba4b` |
| `FreezeViewport` | `82277410` | `DAT_836dba4c` |
| `ShowCurrentRegion` | `822774d0` | `DAT_836dba4d` |
| `ShowSkirmishZones` | `82277590` | `DAT_836dba50` |
| `BoxCollect` | `82277a10` | `DAT_837e5b24` |

`SpawnTargets`/`RenderLanes`/`RenderFCStates` share the `DAT_836dba4x` byte-block, confirming these are sibling spawn/lane/faction-control debug renders that the AI/spawn doc references.

### 3. `MindKiller` — the one non-trivial toggle

`MindKiller @82276be0` differs from the template: it is gated on a feature query and does not own a simple bool — it only re-labels the menu item, with the *state* coming from `FUN_8240a108()`:

```c
==== MindKiller @82276be0 ====
  cVar2 = FUN_8240a108();                       // query current MindKiller state
  if ((DAT_830ba900 != 0) && (iVar1 = FUN_82276b70(DAT_830ba98c), iVar1 != 0)) {
    if (cVar2 == '\0') { uVar3 = 0x...82011aa4; } // "Off"
    else               { uVar3 = 0x...82011aa0; } // "On"
    ...
  }
```

So `MindKiller` ("Tog MindKiller", an AI behavior kill-switch) reflects a state owned by the AI system (`FUN_8240a108`), not a menu-local bool. (unverified: what `FUN_8240a108` actually toggles in the AI sim — only that this menu item displays its boolean.)

### 4. F-key hotkey layer: `EnableFunctionKeys`

`EnableFunctionKeys @8227bad8` maps devkit keyboard function-keys to debug globals. It repeats a `read-named-key → if pressed, latch a DAT_*` block ~14 times:

```c
==== EnableFunctionKeys @8227bad8 ====
  uVar1 = FUN_8290ba80(0xffffffff820124ec);             // a key name (e.g. an F-key id)
  cVar3 = FUN_82912240(param_1,uVar1,0);                // was it pressed?
  if ((cVar3 != '\0') && (iVar2 = FUN_82911d88(param_1), *(char *)(param_1 + 0x428) == '\0')) {
    DAT_830ba8f0 = iVar2 != 0;                          // latch the toggle
  }
  ...                                                    // 13 more F-key → DAT_830ba8xx latches
```

The `DAT_830ba8xx` globals it latches are adjacent to the `DAT_830ba9xx` menu-item handles, i.e. the F-keys and the menu items poke the same debug-state region. This is the "`EnableFunctionKeys`" / "`F5 \"Switch Camera Mode\"`" devkit hotkey path referenced in the camera and gui docs.

### 5. The cheat sub-menu (strings, builder not isolated)

The string dump contains a contiguous cheat block:

```
Open Cheat Menu
Show God Mode Et Al
Infinite Ammo
Demigod Mode
God Mode
Ray Hier+HP
Ray Hierarchy
...
```

and a Lua hook `if Cheat and Cheat.DisplayOptions then Cheat.DisplayOptions() end` plus a PDA-blip test snippet, both embedded as evaluated debug-console strings near the toggle-name block (strings region ~lines 513–545). This proves the cheat menu is partly Lua-driven (the `Cheat.*` table) and partly native toggles.

(open question: I did **not** isolate a single native builder that registers `God Mode`/`Demigod Mode`/`Infinite Ammo` as menu callbacks the way `RollingCacheDbg` registers the AI toggles. The cheat items route through the Lua `Cheat` table (`Cheat.DisplayOptions`), so the gameplay effect is likely applied Lua-side and/or by a component flag rather than by a named C toggle in this decomp. Treat "God Mode is a native FUN_ toggle" as **not supported by the decompilation** — the evidence points to a Lua-bound cheat table.)

## Menu inventory (from strings)

The full menu is large; representative groupings verbatim from the string dump (each is a registered item name):

- **AI / spawn / lane:** `GlobalSpawning`, `DisplayLanePops`, `RoadEndbits`, `SpawnTargets`, `RenderLanes`, `LaneConnect`, `NoSidewalkSpawn`, `NoRoadSpawn`, `RenderFCStates`, `RenderSpawnPoints`, `ShowPopMap`, `MindKiller`, `Toggle AiPriority`, `AI Stats`, `AI Locator`, `Show Stimulus`, `Show Threat`, `Toggle CoverFinder`, `Show CoverHint`, `Toggle DropZone Debug`, `TogglePursuitDebugging`, `++PursuitLevel`/`--PursuitLevel`, `StartPursuit GUR`/`OC`/`VZ`, `ToggleHeatMap`, `ToggleUnitLimiter`.
- **Cheat:** `Open Cheat Menu`, `God Mode`, `Demigod Mode`, `Infinite Ammo`, `Show God Mode Et Al`.
- **Streaming / memory:** `Toggle Stream Debug`, `Toggle Streaming Stats`, `Toggle WAD cache stats`, `Toggle async load`, `Dump resources map`, `VidMem View`, `Main Heap View`, `Toggle Mem Budget`, `Reboot title`, `Pseudo DVD Emu`.
- **Rendering:** `Toggle Shadow`, `Toggle AA`, `Toggle LowResTerrain`, `Toggle Blob Shadows`, `Toggle RenderLights`, `Toggle Filters`, `Show Scaleform Stats`.
- **Physics:** `Physics Debug`, `Physics MT/ST`, `Sanity Check Havok`, `Render Active Islands`, `Toggle Physics Hz Lock`, `MultipleHavokSteps: On/Off`.
- **Camera:** `Camera Tweak Toggle`, `Camera Gauges`, `Toggle Camera Shake`, `Predefined Path Cam`, `Rover Free Eye Camera`, `Toggle FreeEye Cam`, `Toggle Marketing Cam`.
- **Audio:** `Debug Music`, `Debug PalMusic`, `Debug MusicSources`.
- **VFX / spawning:** `Toggle VFX`, `Huge/Large/Small/Tiny Explosion`, `Spawn US Crowd`, `Spawn Weapon Pile`, `Teleport`/`NextTeleporter`/`LastTeleporter`.

## Corrections & open questions

- **Confirmed (was inference in other docs):** The AI/camera/streaming debug toggles named in the inventories (`GlobalSpawning`, `FreezeViewport`, `RenderLanes`, etc.) are **real registered menu callbacks with live effects**, not just leftover strings — proved by `RollingCacheDbg` wiring each name to its callback VA and by the 27 toggle bodies flipping a global bool (`DAT_836dba4x`). This upgrades the camera/AI docs' "debug toggle (appears in a toggle list)" remarks from inference to code-fact.
- **`MindKiller` is special:** unlike its siblings it has no own bool; it mirrors AI state via `FUN_8240a108`. Any doc treating all toggles as identical is slightly wrong here.
- **The menu API body is missing.** `FUN_82279978 → FUN_829167d8` is a stub; the real `AddMenuItem`/text-set implementation isn't in the decomp. So the meaning of the trailing registration args (`enabled`, the `5` vs `8` category, `group`) is **inferred from call-site constants only** and could be wrong.
- **Cheat effects are Lua-bound, not native toggles (open):** I could not find a native C registrar for `God Mode`/`Demigod Mode`/`Infinite Ammo`. The `Cheat.DisplayOptions` Lua hook and the `Cheat`-table references indicate the cheat menu is driven from script. So "God Mode is implemented as a native debug toggle" is **not supported by the decompilation**; the actual god-mode effect is most plausibly a player-component flag set from Lua. Needs the Lua corpus (`docs/mercs2-luacd/`) to confirm.
- **Open:** the `DAT_830ba8xx` (F-key) vs `DAT_830ba9xx` (menu-handle) globals overlap a single debug-state region but I did not fully map which F-key drives which action (the key-name strings passed to `FUN_8290ba80` weren't symbolized in this decomp).

## Cross-references

- `docs/mercs2-pdb-analysis/ai.md` — the spawn/lane/cover/pursuit toggles and `MindKiller` belong to the AI/living-world system.
- `docs/mercs2-pdb-analysis/camera.md` — `FreezeViewport`, `Camera Tweak`, marketing/free-eye cameras.
- `docs/mercs2-pdb-analysis/game-systems.md` — the cheat/unlock path (`HasPlayerUnlockedCode`) and the Lua `Cheat` table.
- `docs/mercs2-luacd/` — the `Cheat.DisplayOptions` Lua implementation (where God Mode etc. is actually applied).
