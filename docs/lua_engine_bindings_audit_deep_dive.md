# Lua Engine Bindings — Deep Dive (Open Questions)

> **Date:** 2026-05-19  
> **Status:** Answers grounded in cracked `Mercenaries2.exe` (53,482,288 bytes, image base `0x00400000`), `tools/dump_lua_bindings.py`, and `docs/lua_call_sites_from_scripts.md`.  
> **Companion:** [`lua_engine_bindings_audit.md`](lua_engine_bindings_audit.md)

This document answers the five open questions from the bindings audit. Evidence levels:

| Level | Meaning |
|-------|---------|
| **CERTAIN** | Verified in EXE bytes, disassembly, working hooks, or bytecode call sites |
| **CONFIRMED** | Multiple independent repo sources agree |
| **INFERRED** | Strong structural/naming inference, not yet runtime-proven |
| **UNKNOWN** | Not enough data |

---

## Executive summary

1. **Namespace tables:** The game uses **one `luaL_Reg` array per `luaL_register(L, libname, reg)` call**, each ending with **`{NULL, NULL}`** (8 zero bytes). The audit’s file-offset cluster `0x00798770`–`0x00799200` holds **only part** of the game API (~352 bindings in 11 strict tables); the cluster **actually runs to ~`0x0079A930`** with **~41 game tables / ~1,015 bindings** before counting Lua stdlib and Scaleform Flash tables.

2. **“Unnamed” ~500+ functions:** The gap is mostly **(a)** bindings outside the narrow doc window, **(b)** **compound registration blobs** with marker pseudo-entries (not plain `{NULL,NULL}` between sub-namespaces), and **(c)** **string-only** symbols (e.g. `IsDLC`) with **no** `.rdata` `luaL_Reg` xref. Bytecode names **254** APIs used in scripts that the audit scrape did not list under the same qualified name (e.g. **`Pg.*`** vs **`Sys.*`**).

3. **Nested APIs:** Top-level globals are **`Sys`, `Net`, `Object`, `Player`, `Pg`, `Gui`, `Hud`, `Ai`, …** Sub-namespaces are created by **custom registration**: marker rows `{ptr_to"Atmosphere", 0xFFFFFFFF}` / `0xFFFFFFFE` delimit sub-tables inside one physical array; Lua sees **`Atmosphere.SetTime`**, **`Graphics.ReloadShaders`**, **`Hud.ObjectiveTray`**, not flat globals.

4. **Signatures:** Best source is **`docs/lua_call_sites_from_scripts.md`** (261 qualified patterns, 5,738 call sites). Below: high-traffic bindings with arity from bytecode; full table in that doc + `output/lua_call_sites.json`.

5. **Other `luaL_Reg` ranges:** **Yes.** Lua 5.1 **stdlib** ~`0x007923A8`–`0x00792580`, **Scaleform/Flash** ~`0x007932C8`–`0x00793BF8`, plus game tables through ~`0x0079A938`. **`0x00798770`–`0x00799200` is incomplete** as the sole scan bound.

**Artifacts:** `tools/dump_lua_bindings.py`, `output/lua_bindings_dump.json`, `output/lua_bindings_dump.csv`, `output/lua_call_sites.json`.

---

## 1. Namespace table boundaries

### 1.1 `luaL_Reg` layout (CERTAIN)

Per Lua 5.1 / engine build (`D:\Projects\Mercs2_PC\mercs2\Lua-5.1.2\src\`):

```c
typedef struct luaL_Reg {
    const char *name;   /* 4 bytes: VA in .rdata */
    lua_CFunction func; /* 4 bytes: VA in .text */
} luaL_Reg;
/* Terminator: { NULL, NULL } — 8 zero bytes */
```

- **One array per `luaL_register` / `luaL_openlib` call** for a given global table name (`"Net"`, `"Player"`, …).
- Function names in the array are **short** (`"SetTime"`); the namespace is the **second argument** to `luaL_register`, not stored in each row.
- **Hook pattern (CERTAIN):** find string in `.rdata`, locate dword xref in a registration row, patch `func` at **string_slot + 4** (`tools/dlc_enable_asi/dlc_enable.c`).

**VA vs file offset:** Docs often cite **file offsets** in the cracked EXE (e.g. `0x00798770`). Image VA = **`0x00400000` + RVA**; for `.rdata` rows here, **VA ≈ `0x00B90000` + (file_off − 0x00790000)`** (e.g. `0x007987F8` → `0x00B987F8`).

### 1.2 Termination (CERTAIN)

Normal tables end with:

```
name_va == 0 && func_va == 0
```

Example: **Event** table at file `0x007987F8` — 4 entries (`Create`, `CreatePersistent`, `Delete`, `Post`), terminator at `0x00798820`.

**Exception — compound blobs:** Between **Graphics**, **Camera**, **Atmosphere**, **Bloom**, **MotionBlur**, **Monochrome** the engine inserts **marker rows** (CERTAIN, EXE dump):

| File offset | name string VA | func_va | Role |
|-------------|----------------|---------|------|
| `0x0079A528` | `"Camera"` | `0xFFFFFFFF` | Sub-table open |
| `0x0079A568` | `"Camera"` | `0xFFFFFFFE` | Sub-table close |
| `0x0079A570` | `"Atmosphere"` | `0xFFFFFFFF` | Sub-table open |
| `0x0079A6A0` | `"Atmosphere"` | `0xFFFFFFFE` | Sub-table close |
| `0x0079A6A8` | `"Bloom"` | `0xFFFFFFFF` | … |
| `0x0079A6E8` | `"Bloom"` | `0xFFFFFFFE` | … |
| `0x0079A6F0` | `"MotionBlur"` | `0xFFFFFFFF` | … |
| `0x0079A700` | `"MotionBlur"` | `0xFFFFFFFE` | … |
| `0x0079A728` | `"Monochrome"` | `0xFFFFFFFF` | … |
| `0x0079A738` | `"Monochrome"` | `0xFFFFFFFE` | … |

A walker that only accepts `{NULL,NULL}` **splits one logical registration region into many fragments** (~`0x0079A4D0`–`0x0079A798`). Treat this as **one custom registration path** that builds nested Lua tables.

### 1.3 One table per namespace? (CONFIRMED — with compound caveat)

| Model | When |
|-------|------|
| **1:1** `luaL_Reg` array → global table | `Event`, `Weapon`, `VO`, `Vehicle`, `Sound`, `Player`, `Net`, `Object`, `Ai`, `_SYS`, … |
| **1 array → multiple Lua sub-tables** | Graphics / Camera / Atmosphere / post-process (markers above) |
| **Separate small tables** | After **Faction** (`0x00798F64`): two single-entry `Init` tables (`0x00798F94`, `0x00798FA4`) before **Player** at `0x00798FC0` — likely distinct `luaL_register` targets (UNKNOWN names) |

**Not** one giant table for the whole engine: **~41 game arrays** in `0x00798770`–`0x0079A930`, plus stdlib/Flash.

### 1.4 Primary cluster map (file offsets)

Bindings counted by walking valid `{name, func}` rows and `{NULL,NULL}` (compound markers excluded). Namespace labels combine **`.rdata` strings** (`Sys` @ `0x007BA49C`, `Pg` @ `0x007B9030`, `Net` @ `0x007B8154`, …) and **bytecode** (`Pg.GetGuidByName`).

| Start (file) | End (file) | n | In audit `0x799200`? | Namespace (evidence) | First → last |
|--------------|------------|---|----------------------|----------------------|--------------|
| `0x00798770` | `0x007987F8` | 16 | Yes | **Coop** (INFERRED) / audit said “Object” | `Create` → `_GC` |
| `0x007987F8` | `0x00798820` | 4 | Yes | **Event** (CERTAIN) | `Create` → `Post` |
| `0x00798828` | `0x00798860` | 6 | Yes | **Debug** (CONFIRMED) | `Printf` → `GetCallstack` |
| `0x00798860` | `0x007988B0` | 9 | Yes | **Weapon** (CONFIRMED) | `SetClipAmmo` → `IsPrimary` |
| `0x007988B0` | `0x00798910` | 11 | Yes | **VO** (CERTAIN) | `Cue` → `RemoveSequence` |
| `0x00798918` | `0x00798A60` | 40 | Yes | **Vehicle** (CONFIRMED) | `GetRiders` → `ClearControls` |
| `0x00798A60` | `0x00798A78` | 2 | Yes | **UNKNOWN** | `Create`, `InsertI` |
| `0x00798A78` | `0x00798C80` | 64 | Yes | **Sys** (CONFIRMED) | `WriteToConsole` → `GetForceNewGame` |
| `0x00798C98` | `0x00798F60` | 88 | Yes | **Sound** (CERTAIN) | `TestCueSound` → `_GetLibVersion` |
| `0x00798F64` | `0x00798F8C` | 5 | Yes | **Faction / Pursuit** (CERTAIN) | `Init` → `SetDelay` |
| `0x00798FC0` | `0x00799320` | 107 | Yes* | **Player** (CONFIRMED) | `GetCharacter` → `SetSwimmingSearchRadius` |
| `0x00799328` | `0x007995B0` | 80 | **No** | **Pg** (CERTAIN via bytecode; string @ `0x007B9030`) | `LoadingStaticLayers` → `SetGlobalSkirmishState` |
| `0x007995B0` | `0x00799600` | 9 | No | **StateMachine** (INFERRED) | `SendMessage` → `DebugStateMachine` |
| `0x00799608` | `0x007998C8` | 87 | No | **Object** (CONFIRMED) | `GetParent` → `RemoveFromDisposer` |
| `0x007998D0` | `0x00799BB8` | 92 | No | **Net** (CONFIRMED) | `IsPlatformConnected` → `UpdatePresence` |
| `0x00799BBC` | `0x00799BE4` | 4 | No | **UNKNOWN** (timer) | `Start` → `Resume` |
| `0x00799BE8` | `0x00799C70` | 17 | No | **Math** (string @ `0x007DD858`) | `abs` → `PolarToRect` |
| `0x00799C78` | `0x00799E20` | 52 | No | **LTI** (CONFIRMED) | `LTIMovieStart` → `FirstRun` |
| `0x00799E28` | `0x00799EF0` | 24 | No | **DevTools** (INFERRED) | `SpawnHomingProjectile` → `DumpStats` |
| `0x00799FF8` | `0x0079A390` | 114 | No | **Gui** (CONFIRMED) | `CreateWidget` → `AddPdaMapBlips` |
| `0x0079A398` | `0x0079A4D0` | 38 | No | **Gui** (markers/objectives) | `AddObjective` → `OutputToPIX` |
| `0x0079A4D0` | `0x0079A798` | ~70+ | No | **Graphics + Atmosphere + post** (compound) | See §3 |
| `0x0079A7D8` | `0x0079A850` | 14 | No | **Camera** (CONFIRMED) | `GetYaw` → `SetShot` |
| `0x0079A854` | `0x0079A88C` | 6 | No | **_SYS** (CERTAIN) | `_IMPORT` → `_GETFENV` |
| `0x0079A88C` | `0x0079A8C4` | 6 | No | **Face** (INFERRED) | `BindFaceAnimSet` → … |
| `0x0079A8C8` | `0x0079A930` | 12 | No | **Support** (INFERRED) | `SpawnCarpetBombLine` → … |
| `0x0079A938` | `0x0079AA38` | 66 | No | **Ai** (CONFIRMED) | `Temp` → `SetPriorityTarget` |

\*Player starts at `0x00798FC0`, after small `Init` tables; audit window `0x799200` ends before Player’s terminator.

**Corrections vs earlier docs:**

- **`0x00799078` is not a table base** (CERTAIN): it falls inside the **Player** array (~entry 23). Agent B’s “boundary table at `0x00799078`” is a **misaligned anchor**.
- **First table (`0x00798770`) is not `Object`** (INFERRED): entries (`SetFilter`, `GetCoopPlayerGuid`, `Eval`) match a **co-op / group query** API, not `Object.GetPosition`.

### 1.5 Counts vs audit “800–1300+” (CONFIRMED)

| Scope | Tables | Bindings | Tool / method |
|-------|--------|----------|----------------|
| Audit file `0x798770`–`0x799200` only | 11 | ~352 | Strict `{NULL,NULL}` |
| Extended game cluster `0x798770`–`0x79A930` | ~41 | ~1,015 | Manual walk + markers |
| All `.rdata` strict tables | 56 | 1,254 | Pair scan (includes stdlib/Flash) |
| `dump_lua_bindings.py` (cluster only) | ~49 | ~831 | Primary cluster; verified namespace labels only when in `VERIFIED_TABLE_LABELS` |

The **800–1300** range is **accurate** if counting **all** registration rows + stdlib + Flash + SendEvent wrappers; the **narrow doc window under-counts by ~60%**.

---

## 2. Unnamed functions (~500+ in the 800–1300 range)

### 2.1 What “unnamed” means here

| Category | ~Count | Evidence |
|----------|--------|----------|
| Bindings **outside** `0x00798770`–`0x00799200` | ~660+ | Table map §1.4 |
| **Compound blob** rows not in simple table dump | ~70 | Graphics/Atmosphere region |
| **Lua stdlib** (`string.*`, `table.*`, `coroutine.*`) | ~56 | `0x007923A8` region |
| **Scaleform Flash** bindings | ~200+ | `0x007932C8`–`0x00793BF8` |
| **Strings without `luaL_Reg` xref** | Small | e.g. `IsDLC` (below) |
| Audit listed by namespace but **no per-offset row** | ~80 “CONFIRMED” | Naming-only in prior docs |

### 2.2 Bytecode proves many “missing” names (CERTAIN)

`docs/lua_call_sites_from_scripts.md` (111 scripts, demo `scripts_vz`):

- **261** unique `Namespace.Function` patterns at **5,738** call sites.
- **254** qualified names **not** in the audit’s scrape — overwhelmingly because scripts use **`Pg.*`** and **`Hud.*`** while the audit emphasized **`Sys.*` / `Object.*`**.

Top engine APIs by script coverage (all CERTAIN from disasm):

| Binding | Scripts | Typical arity (stack args to CALL) |
|---------|---------|-----------------------------------|
| `Pg.GetGuidByName` | 52 | 1 (1108×), 2 (52×), 5 (30×), … |
| `Debug.Printf` | 47 | 1–5 common |
| `Player.GetAnyCharacter` | 41 | 0 (164×) |
| `Event.Create` | 32 | 4 (115×), 3 (32×) |
| `Object.GetPosition` | 31 | 1 (76×) |
| `Vehicle.GetDriver` | 24 | 1 (54×) |
| `Ai.Goal` | 23 | 1–5 |
| `Net.SendCustomEvent` | 17 | 3–4 |

Full list: **`docs/lua_call_sites_from_scripts.md`** + **`output/lua_call_sites.json`**.

### 2.3 EXE strings without registration row (CERTAIN)

| Symbol | String file off | `luaL_Reg` xref in `.rdata` | Notes |
|--------|-----------------|----------------------------|--------|
| `IsDLC` | `0x007E2C24` | **0** | Session flag; ASI hooks **call site** / alternate path (`docs/dlc_extras_activation_research.md`) |
| `SetSky` | `0x007B52F8` | **1** @ `0x0079A698` | In compound blob, not audit window |
| `IsDemoMode` | `0x007BA268` | **1** @ `0x00798B50` | In **Sys** table |
| `GetCash` | `0x007B92BC` | **1** @ `0x00799250` | Inside **Player** table body |

So: **presence of a string in the EXE ≠ Lua binding**; always require **xref to `.text` function pointer**.

### 2.4 Cross-reference to prior EXE docs

| Source | Contribution |
|--------|----------------|
| `docs/exe_analysis_agent_a.md` | Namespace list, bootstrap, SendEvent list |
| `docs/exe_analysis_agent_b.md` | Event disasm (`0x005F69F0`), Sound=88, boundary C++ VAs |
| `docs/exe_cross_validation.md` | Event table @ `0x007987F8`, listener type strings |
| `docs/luadisass_findings.md` | Lua 5.1 float bytecode confirmed |

**Resolved:** `Object.GetVelocity` was audit “NOT FOUND” — bytecode has **`Object.GetVelocity`** (3 scripts, arity 1). **`SpawnObject` / `CreateObject`** still **UNKNOWN** as global `Object.*` names.

---

## 3. Sub-tables vs top-level globals

### 3.1 Top-level namespaces (CERTAIN / CONFIRMED)

Registered as **global tables** via `luaL_register(L, "Name", reg)` (namespace string in `.rdata`):

| String off | Name | Table region (file) |
|------------|------|---------------------|
| `0x007BA49C` | `Sys` | `0x00798A78` |
| `0x007B9030` | `Pg` | `0x00799328` |
| `0x007B8154` | `Net` | `0x007998D0` |
| `0x007B5CC4` | `Gui` | `0x00799FF8`, `0x0079A398` |
| `0x007B3750` | `Hud` | Separate **`Hud.*`** calls in bytecode (`Hud.ObjectiveTray`, `Hud.Radar`, …) — **sub-table under Gui or own register** (INFERRED) |
| `0x007B5437` | `Atmosphere` | Compound blob @ `0x0079A570` |
| `0x007B56A4` | `Graphics` | Compound blob @ `0x0079A4D0` |
| `0x007B4A48` | `Ai` | `0x0079A938` |
| `0x007B6680` | `Weapon` | `0x00798860` |
| `0x007B4C10` | `Vehicle` | `0x00798918` |

### 3.2 Nested exposure pattern (CERTAIN)

**Not** `Mercs2.Hooks.before` style (that is **plan B/C fiction** for a future mod SDK). The retail game uses:

1. **Global namespace tables** — `Player.SetCash`, `Net.IsServer`.
2. **Marker-delimited sub-tables** — registration stub inserts `{ "Atmosphere", 0xFFFFFFFF }` … functions … `{ "Atmosphere", 0xFFFFFFFE }`; runtime builds **`Atmosphere.SetTime`**, etc.
3. **Lua-side aliases (CERTAIN)** — bootstrap @ file `0x007B4EE2`:

```lua
_G.Marker = {}
_G.Marker.AddBlip = Gui._MarkerAdd
-- etc.
```

4. **Module system (CERTAIN)** — `import()` / `inherit()` / `_G._MODULES`; game logic in WAD modules (`MrxTaskContract`, …), not in EXE tables.

5. **Event types** — `Event.TimerRelative`, `Event.Boundary`, … are **values** used with `_CreateEvent`, not separate C registration tables in the same cluster.

### 3.3 `SendEvent_*` (CONFIRMED)

**44** `SendEvent_*` C++ dispatchers (audit appendix A) are **`Net.SendEvent_*` from Lua’s perspective** in bytecode (e.g. `Net.SendEvent_AddMarkerObjective` with arity 10–12). They are **not** separate globals; they live in the **Net** table (~`0x007998D0` region).

---

## 4. Signatures (arguments / returns)

### 4.1 Methodology

| Source | Reliability |
|--------|-------------|
| `lua_call_sites_from_scripts.md` | **CERTAIN** for stack arity at CALL; types **INFERRED** |
| C binding naming (`Get*` / `Set*` / `Is*`) | **INFERRED** |
| RE disasm (Event.Create → `0x005F6660`) | **CERTAIN** for that function |
| Plan docs / mod examples | **UNKNOWN** unless cross-checked |

Lua 5.1 **`lua_CFunction`**: `(lua_State *L) -> int`; return value = **number of results pushed**. Without decompiler types, **return counts are mostly UNKNOWN**.

### 4.2 High-value bindings (call-site backed)

| Function | Args | Returns | Evidence |
|----------|------|---------|----------|
| `Event.Create` | **4** (115 sites), also 3, 0 | UNKNOWN | **CERTAIN** arity |
| `Event.CreatePersistent` | **4** (17×), 3, 2 | UNKNOWN | **CERTAIN** |
| `Event.Delete` | **1** (356×) | UNKNOWN | **CERTAIN** |
| `Event.Post` | **2** (3×) | UNKNOWN | **CONFIRMED** |
| `Pg.GetGuidByName` | **1** (1108×), 2, 5, … | UNKNOWN (likely GUID) | **CERTAIN** |
| `Object.GetPosition` | **1** (76×) | UNKNOWN (likely x,y,z) | **CERTAIN** |
| `Object.GetHealth` | **1** (16×) | UNKNOWN | **CERTAIN** |
| `Object.SetHealth` | **3** (4×) | UNKNOWN | **CONFIRMED** |
| `Player.GetCash` | **0** (2×) | UNKNOWN | **CERTAIN** |
| `Player.SetCash` | **1** (3×) | UNKNOWN | **CERTAIN** |
| `Player.SetFuel` | **1** (1×) | UNKNOWN | **CERTAIN** |
| `Net.IsServer` | **0** (58×) | UNKNOWN (boolean) | **CERTAIN** |
| `Net.IsMultiplayer` | **0** (7×) | UNKNOWN | **CERTAIN** |
| `Ai.Goal` | **1–5** | UNKNOWN | **CERTAIN** |
| `Vehicle.Enter` | **5–6** | UNKNOWN | **CONFIRMED** |
| `Sound.CueSound` | **3** (7×) | UNKNOWN | **CONFIRMED** |
| `Sys.GuidToString` | **1** (3×) | UNKNOWN (string) | **CONFIRMED** |
| `Sys.IsLoadingOrStreaming` | **0** (1×) | UNKNOWN | **CONFIRMED** |
| `Graphics.ChangeLineRegionSetting` | **2** (18×) | UNKNOWN | **CERTAIN** |
| `Marker.AddDisc` | **6** (3×) | UNKNOWN | **CONFIRMED** |
| `VO.Cue` | **3** (1×) | UNKNOWN | **CONFIRMED** |

### 4.3 Disassembly-backed (CERTAIN)

**`Event.Create` @ VA `0x005F69F0`:** `push 0`; `call 0x005F6660` (internal create, non-persistent).  
**`Event.CreatePersistent` @ `0x005F6A00`:** `push 1`; same internal.  
→ First argument to internal create is **boolean persistent**; Lua-facing arity **4** includes event type + params + callback + userdata (CONFIRMED pattern from scripts).

**`Sys.IsDemoMode` @ `0x005E5670`:** reads byte flag (audit; **CERTAIN**).

### 4.4 `_SYS` (CERTAIN from bootstrap)

| Function | Args (Lua) | Returns | Evidence |
|----------|------------|---------|----------|
| `_IMPORT` | env, module name | module | bootstrap |
| `_INHERIT` | env, module name | nil | bootstrap |
| `_DYNAMIC_IMPORT` | env, module, callback, data | handle? | bootstrap |
| `_DYNAMIC_REMOVE` | env, module | nil | bootstrap |
| `_GETFENV` | level | env table | bootstrap |
| `_MODULEINDEX` | key (via metamethod) | value | bootstrap |

### 4.5 Still UNKNOWN without more RE

- Exact **GUID** representation (likely 4-byte or 8-byte userdata).
- **`Atmosphere.SetTime`**: registered @ `0x0079A588`, **no** script hits in demo harvest (only `Sys.IsLoadingOrStreaming` in `wifvzatmosphere`).
- Return counts for essentially all **`Get*`** / **`Set*`** pairs.

---

## 5. Other `luaL_Reg` ranges

### 5.1 Outside `0x00798770`–`0x00799200` (CERTAIN)

| Region (file off) | Contents | Bindings (approx) |
|-------------------|----------|-------------------|
| `0x007923A8`–`0x00792580` | Lua **stdlib** (`string`, `table`, `math`, `coroutine`, base) | ~56 |
| `0x007932C8`–`0x00793BF8` | **Scaleform Flash** AS API (`MovieClip`, `TextField`, …) | ~200+ |
| `0x00799328`–`0x0079A930` | **Core game** (Pg, Object, Net, Gui, Ai, …) | ~660 |
| `0x0079A4D0`–`0x0079A798` | **Graphics/Atmosphere/post** compound | ~70 |

### 5.2 Is the known range incomplete? (CERTAIN: yes)

The audit window was a **useful anchor** (Event @ `0x007987F8`, early tables) but **must be extended to at least `0x0079A000`** (tool default `PRIMARY_FILE_SCAN_END`) or full `.rdata` scan.

**Recommended scan bounds for `dump_lua_bindings.py`:**

```text
PRIMARY_FILE_START = 0x00798770
PRIMARY_FILE_SCAN_END = 0x0079AB00   # includes Ai + tail
# Plus: marker-aware parser for 0x0079A4D0–0x0079A798
# Plus: optional stdlib/Flash regions for completeness
```

### 5.3 Special cases

| Item | Location | Note |
|------|----------|------|
| `IsDLC` | String only @ `0x007E2C24` | No `luaL_Reg`; hook C caller or session struct |
| `IsOnlineConnected` | Row @ `0x00799940` | In **Net** table |
| Bootstrap | `0x007B4EE2` | Lua source, not `luaL_Reg` |
| `dofile` / `loadfile` | Stdlib table | `@ `0x007924B8` region |

---

## 6. Recommended next steps

Tied to the three technical tasks from the audit:

### 6.1 Full table dump script (`tools/dump_lua_bindings.py`)

**Done (baseline).** Next increments:

1. **Marker-aware parser** — treat `{namespace, 0xFFFFFFFF}` / `0xFFFFFFFE` as sub-table boundaries; emit nested JSON (`Graphics`, `Atmosphere`, `Bloom`, …).
2. **Fix `KNOWN_TABLE_LABELS`** — `0x00799328` → **`Pg`**, `0x00798770` → **Coop** (pending RE name string), `0x00798A78` → **Sys** only.
3. **Xref report** — for each `.rdata` function name string, flag **no reg row** (like `IsDLC`).
4. **Output:** `namespace`, `file_start`, `file_end`, `entry_count`, `terminator`, `func_va` list → CSV for hook authors.

### 6.2 Lua bytecode decompile

1. Run `tools/lua_call_site_extractor.py` on **retail** `scripts_vz` (not only demo) → refresh `lua_call_sites_from_scripts.md`.
2. Optional: LuaDisAss via `LUADISASS=` per `docs/luadisass_findings.md` for readable source.
3. Merge call-site arity into `lua_bindings_dump.csv` as columns `min_args`, `max_args`, `script_hits`.

### 6.3 Runtime enumeration

1. ASI: hook **`luaL_register`** (plan A) or first **`Sys.IsDemoMode`** / **`Debug.Printf`** (CERTAIN fire on boot).
2. `lua_getglobal` + `lua_next` per namespace → JSON (ground truth for nested tables).
3. Compare runtime dump vs static dump → resolve **Hud** vs **Gui** and **Pg** vs **Sys** naming.

---

## Appendix A — Evidence file index

| Path | Role |
|------|------|
| `game-files/cracked-parts/Crack/Mercenaries2.exe` | Master binary |
| `tools/dump_lua_bindings.py` | Static table walker |
| `output/lua_bindings_dump.json` / `.csv` | Machine-readable inventory |
| `docs/lua_call_sites_from_scripts.md` | Arity / usage |
| `output/lua_call_sites.json` | Call-site database |
| `tools/dlc_enable_asi/dlc_enable.c` | `luaL_Reg` patch pattern |
| `docs/exe_analysis_agent_a.md`, `agent_b.md`, `exe_cross_validation.md` | Prior RE |

## Appendix B — Audit doc corrections

| Audit claim | Correction | Evidence |
|-------------|------------|----------|
| Registration only in `0x798770`–`0x799200` | **Incomplete**; game tables through ~`0x79A938` | §1.4, §5 |
| Net/Boundary @ `0x00799078` | **Misaligned**; inside Player table | §1.4 |
| `Sys` for `LoadLayer` / `GetGuidByName` | **`Pg` table** @ `0x00799328` for world/streaming; **`Sys`** @ `0x00798A78` | Bytecode + string @ `0x007B9030` |
| All Atmosphere/Graphics in simple tables | **Compound marker blob** @ `0x0079A4D0` | §3.2 |
| `IsDLC` in `luaL_Reg` | **No `.rdata` reg xref** | §2.3 |
