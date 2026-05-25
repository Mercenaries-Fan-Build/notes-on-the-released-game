# DLC / Extras Menu Activation Research

> **Goal:** Enable the "Blow It Up Again" DLC content on PC without EA's defunct online servers.
> **Date:** 2026-05-18 (updated 2026-05-23)
> **Status:** Working. DLC contracts appear in Fiona's briefing list and are playable.

---

## Executive Summary

**The DLC problem is a script bootstrap problem, not an authentication problem.**

- The "Blow It Up Again" DLC was never released on PC (PS3/Xbox 360 only)
- The Xbox 360 DLC has been successfully ported to PC via `vz-patch.wad`
- DLC contracts are registered and unlocked via an ASI plugin (`dlc_enable.asi`)
- No existing community tool addressed DLC activation on PC — this is a first

**Working solution:** Nohook WAD (DLC asset blocks + `dlc01` script appended as entry 115) +
ASI bootstrap that calls `import("dlc01")`, registers `tMissionData`, and calls
`UnlockMission()` after flow initialization.

---

## Architecture

### How It Works

```
1. Engine loads vz-patch.wad alongside vz.wad (last-opened-wins overlay)
2. ASI hooks Debug.Printf/print() → detects "Loading vz level with vz masterscript"
3. After 60s delay (layers finish loading): import("dlc01") registers tMissionData
4. Detects "Setting flow data" → 5s delay: UnlockMission() × 4 via wifmissionflow env
5. DLC contracts appear in Fiona's briefing list
6. On accept: engine loads dlccon* bytecode on-demand via ASET hash lookup
```

### Key Technical Discoveries

| Finding | Detail |
|---------|--------|
| `dlccon*` scripts live in resident block 464 | NOT in `scripts_vz`; `import()` only searches `scripts_vz` |
| Lua globals are shadowed | `type`, `error`, `pcall`, `getfenv` are tables/stubs in the thread globals |
| `import()` works from default env | `luaL_loadbuffer` default env has `import()` as a function |
| Modifying retail entries causes hangs | Only append-only ("nohook") approach is stable |
| `_oParent` timing critical | Set during `Reset` + `SetFlowData`, not at `EnterFreeplayMusic` |
| `setfenv(unlock_fn, flow_env)` required | Inherited methods resolve globals from their own fenv |

### Components

| Component | Role |
|-----------|------|
| `vz-patch.wad` | 2197-block overlay: 2196 DLC asset blocks + `dlc01` in scripts_vz |
| `dlc_enable.asi` | Hooks net functions + Debug.Printf; runs timed bootstrap inject |
| `pmc_bb.dll` | Optional: provides console logging via `pmc_log()` |
| `dinput8.dll` | Ultimate ASI Loader — loads `.asi` plugins from `scripts/` |

---

## Community Tools (None Solve DLC)

| Tool | What It Does | Solves DLC? |
|------|--------------|-------------|
| TeknoGods | LAN/online co-op server emulator | No |
| Arcadia | EA FESL emulator (PS3 only) | No |
| PCGamingWiki | Links to TeknoGods, notes DLC was not on PC | No |
| ModDB mods | ~20 mods, none for DLC/Extras | No |

---

## Extras Menu (Not Needed)

The Extras menu gate (`IsOnlineConnected()` → dead EA servers) is bypassed entirely.
The ASI hooks `IsOnlineConnected` to return `true` and `HasPlayerUnlockedCode` to return
`true`, but DLC activation happens through the Lua bootstrap, not through the shell UI flow.

The Extras menu itself is not functional and fixing it is low priority — DLC contracts
auto-appear in Fiona's briefing list without needing the Extras UI.

---

## Remaining Gaps

| Gap | Priority | Status |
|-----|----------|--------|
| DLC title localization (`AddStringDb`) | High | Fix in dlc01 bytecode (rebuild required) |
| Briefing Spiel gfx assets | Medium | Placeholder works; proper gfx needs `Spiel_MinorContract_Dlc01_*` port |
| Voice audio deployment | Low | Files exist in `fresh-rebuilt/data/Audios/`; need manual copy |
| Arena transition (`SetMasterScriptName`) | Experimental | `[ARENA]` code in ASI — actively testing |

---

## Abandoned Approaches

These were tried and failed — documented for reference:

| Approach | Why It Failed |
|----------|---------------|
| Modify `wifmissionflow` in WAD | Hang at "Loading vz level with vz masterscript" |
| Direct C call to `_SYS._IMPORT` | Corrupts CallInfo; re-entrancy deadlock during layer load |
| `ScriptInit()` wrapper in bootstrap | Globals shadowed; `type()` call fails |
| `dynamic_import("dlccon*")` in bootstrap | AV at 0x0059C82A — re-entrant async block loading |
| Eager import during layer load | Freeze from re-entrancy (asset system iterating) |
| `EnterFreeplayMusic` as unlock trigger | Fires before `_oParent` is set (too early) |
| DNS redirect / hosts file | Would only help server auth, not script bootstrap |
| Save/registry editing | DLC state is session-level, not persisted |
| Full server emulation | Enormous effort, unknown protocol, not needed |

---

## Related Documentation

- [`docs/dlc_pc_activation_checklist.md`](dlc_pc_activation_checklist.md) — Deploy/validation workflow
- [`docs/dlc_loader_cross_reference.md`](dlc_loader_cross_reference.md) — DLC loader mechanism across platforms
- [`docs/dlc_pc_port_status.md`](dlc_pc_port_status.md) — DLC porting tool status and gaps
- [`docs/xbox360_dlc_analysis.md`](xbox360_dlc_analysis.md) — Xbox 360 DLC archive analysis
- [`docs/asi_loader_setup.md`](asi_loader_setup.md) — ASI Loader infrastructure
- [`analysis/cross_platform/pc_bisect_results.md`](../analysis/cross_platform/pc_bisect_results.md) — Bisect lessons learned
