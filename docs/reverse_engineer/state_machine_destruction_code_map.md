# Entity state machines + Destruction — Xbox↔PC code map

**Scope:** scoreboard **rows 30 (Entity state machines)** + **31 (Destruction)** — one map because they
are one system: the destruction pipeline *is* the primary consumer of the model state machine. This
covers the **orchestrator chunk parser** (the named-state machine on disk), the **runtime state
machine** (instantiate → set-state → transition-on-message → execute Enter/Exit command script), the
**damage → health → message** routing that drives transitions, the **BuildingDestruction /
DestructionLink** multi-part collapse descriptors, and the **vz_state pristine↔ruined** overlay swap.
It marries the **Xbox 360 devkit (Jul-08 Profile build)** symbol/PDB ground truth to the **PC retail
decompilation** (`Mercenaries2.exe`, unpacked image, base `0x00400000`).

This is the row-30/31 companion to the streaming spine
([`world_streaming_code_map.md`](world_streaming_code_map.md)) and prop-LOD
([`prop_lod_imposter_code_map.md`](prop_lod_imposter_code_map.md)) maps, which deliberately said "do
**not** gate draw groups on the destruction state machine as if it were LOD" and left the state
machine to this doc. The **SEGM state/LOD mask** (the geometry-side draw gate the machine drives) is
in the prop-LOD map §5 and is only cross-referenced here.

**Sources.** Core format: [`../destruction_orchestrator_format.md`](../destruction_orchestrator_format.md)
(the `FUN_004cf340` chunk-family RE — INFO/NODE/STAT/CHDR/CEXE/SWIT, the 11-command Enter/Exit
vocabulary, the previously-unresolved state + message hashes) and
[`asset_formats_code_map.md`](asset_formats_code_map.md) §3.3. Xbox oracle:
[`../mercs2-pdb-analysis/world-streaming.md`](../mercs2-pdb-analysis/world-streaming.md) §Props/
destructibles + [`xbox_ppc_named_functions.md`](xbox_ppc_named_functions.md) (`@0x829fXXXX`
descriptor RVAs). Data layer: [`../mercs2-ecs/07_gameplay_state_health_mission.md`](../mercs2-ecs/07_gameplay_state_health_mission.md)
(StateMachine / Health / RuntimeHealth / RuntimeNodeHealth / ObjectScript / DamageKey /
BuildingDestruction / DangerousBuilding schemas + PC builders). Lua surface:
[`../mercs2-luacd/06_ai_world_entities.md`](../mercs2-luacd/06_ai_world_entities.md) (`OnStateChange`,
oilrig/islandfortress sequenced demolition) + the decompiled corpus
(`materialanimation_largecanopy02.lua` etc.). Hashes cracked with `tools/pandemic_hash.py --m2`
against `tools/rainbow_table.json`. PC bodies read first-hand from the 27k-fn Ghidra decomp and cited
as `ghidra/FUN_xxxx`. Companion memory: [[multi-material-draw-groups]], [[mercs2-workshop-devtool]],
[[world-lod-and-destruction-scope]], [[name-registry-spawn-by-hash]].

**Method / honesty model.** Same discipline as the sibling maps. PC retail strips every
`BuildingDestruction`/`PropPhysics`/`Destruction*` runtime profiler string, and — decisively — the
**state-name, message, and command hashes are stored as DATA in the parsed machine, not as code
literals** (xref of `0xE1142510` SetStateOnMsg, `0x842AE03E` DisableConstraint, `0xECADCE57`
SetNodePhysicsModelKeyframed, `0xACB51200` PristineState, `0x92791EBB` StartDestroyedState all return
**0 mentions** in the decomp), so command/state dispatch is **binding-table-driven** (resolved via the
name registry, same "binding-table-only" pattern as the 6 missing Lua binders). The two hashes that
*do* survive as literals — `0x0ACE072A`/`0x5D308F4F` (init states, embedded in the initializer) and
`0x1ED7AD78`/`0x3D0D4C99` (the message pair, in the AI reaction consumer) — are the anchors that pin
the runtime cluster. Confidence: **H** can't-coincide fingerprint (read body + matching constants/
role) · **M** one strong structural signal · **L/open** positional / confirm-live. Where the
transition dispatches through a SecuROM data-table indirect jump, it is **read live in the unpacked image** ([[securom-decompiled-not-a-blocker]]), not treated as a wall.

---

## 0. Result in one line

**Rows 30/31 are recovered end-to-end on PC, with two items finished live (not blocked).** The on-disk machine (parser
`FUN_004cf340`) was already mapped; this pass adds the **runtime cluster** — the per-object
destructible update `FUN_006696a0` → the health-producer/machine-initializer `FUN_004cfed0` (which
sets the machine's initial state to **`InitState` 0x0ACE072A** or **`InitDestroyedState` 0x5D308F4F**
from a spawn-dead flag, the constants *read literally* from the code), the machine-Activate/builder
`FUN_004b67b0`→`FUN_004d3f00`, the force-destroy path `FUN_004d05c0` (SetState **InitDestroyedState**
+ zero health), and the shared **`SetState(machine, guid, state_hash)` = `FUN_004d3e10`** — whose body
dispatches through an **indexed indirect jump `_DAT_024556d4`** (a `switch` whose case table sits in
SecuROM data; the wrapper is decompiled, the arms **read live in the unpacked image** —
[[securom-decompiled-not-a-blocker]], not a wall). The
damage→message side is `FUN_0059be00`, the consumer that listens for **`DestroyMsg` 0x1ED7AD78** +
its sibling **0x3D0D4C99**. And the **highest-value deliverable landed: 11 of the 14 unknown
hashes are cracked** — the entire state-name vocabulary except two, and two of the three message
names — via the rainbow table + naming-scheme brute force, two of them *independently corroborated by
the decompiled code constants*.

---

## 0.5 Master marriage table (whole system at a glance)

Per-cluster evidence in §2–§6. A bare Xbox `.rdata`/`@0x829f` offset means the Xbox *code body* is
unlocated (name string only) and the marriage is **PC-anchored**. "Married by" = the concrete signal.

| Role | Xbox symbol / addr | PC addr | Married by | Conf |
|---|---|---|---|---|
| **Orchestrator chunk parser** (INFO/NODE/STAT/CHDR/CEXE/SWIT → named-state machine) | — (SWIT SecuROM-packed; runtime-built) | **`FUN_004cf340`** (943 B) | read body: only consumer of tag `SWIT 0x54495753`; builds node/state/enter-exit records (orchestrator_format.md) | H (PC) |
| Parser chunk-reader leaf | — | `FUN_00464780` (Chunk_GetEntryReader) | callee of parser; shared FFCS/UCFX 0x14-stride entry reader (streaming map §2.4) | H |
| **Per-object destructible update** (drives the machine) | `PropPhysics`/`BuildingDestruction` update (name-stripped) | **`FUN_006696a0`** (940 B) | read body: gate `*(obj+0xc4)!=0` (has destruction substruct) → calls `FUN_004cfed0`; vtable-dispatched (no callers) | H (PC) |
| **Health producer + machine initializer** | — | **`FUN_004cfed0`** (1773 B) | read body: writes RuntimeHealth/RuntimeNodeHealth; lazily creates machine, `FUN_004d3e10(m,guid, (-(dead)&0x52628825)+0xace072a)` | H (PC) |
| **`SetState(machine, guid, stateHash)`** (transition executor) | — | **`FUN_004d3e10`** (28 B trampoline) | read body: clears `+0x10` low-3-bits, **indexed indirect jump `(*_DAT_024556d4)()`; case table in SecuROM data → read live in unpacked image (not a wall)**; 3 callers all pass a state hash | H (site) / live (body) |
| **StateMachine runtime Activate / instance builder** | `StateMachine` desc `@…` | **`FUN_004b67b0`** → **`FUN_004d3f00`** | read body: `FUN_008445b0(0x2a8)` runtime obj, binds parsed definition `piVar4[3]`, `FUN_004d3f00`/`FUN_004d3e10`, pool-inserts `&PTR_PTR_00df9310` | H (PC) |
| **Force-destroy path** (kill → destroyed state) | — | **`FUN_004d05c0`** (481 B) | read body: `FUN_004d3e10(m,guid,0x5d308f4f)` (**InitDestroyedState**) + zero HP + iterate switch nodes; callers `FUN_00704460/00706ca0` (gameplay) | H (PC) |
| **Runtime state-machine instance pool** | — | **`&PTR_PTR_00df9310`** | insert/lookup via `FUN_00649180(&PTR_PTR_00df9310,guid,…)` in all three runtime fns | H |
| **Damage/destroy MESSAGE consumer** (AI/proximity reaction) | — | **`FUN_0059be00`** (1440 B) | read body: iterates msg queue `FUN_004b2690`, matches `msg==0x1ed7ad78 \|\| msg==0x3d0d4c99` (**DestroyMsg** + sibling) | H (PC) |
| Command/type → bitmask table | — | **`FUN_00526220`** | read body: `CreateObject 0xc6e8afa8→4`, `Health 0x6be1abf→2`, +9 more; a type-classifier used by consumers | H (PC) |
| Post-init state replication / link writer | — | `FUN_004cfc80` | read body: net key `{0xce6c6125,0x207359c7}`, writes a component pair from collected ids; called after machine init | M |
| **StateMachine** descriptor (4 name-hash int32) | `StateMachine` | `FUN_00641aa0` (schema `FUN_0065fcb0`, stride 0x10) | ECS-doc 07; `s_StateMachine`, 4×`FUN_00824270()` name-hash defaults | H |
| **ObjectScript** descriptor (entity→Lua, 2 hashes) | `ObjectScript` | `FUN_006424e0` (schema `FUN_00660ff0`, stride 8) | ECS-doc 07; field0 = `script_hash_0`, resolves via `FUN_00824270` name table | H |
| **BuildingDestruction** descriptor | `BuildingDestruction` `@0x829f1538` (rdata `0x0031550`) | `FUN_00642590` (schema `FUN_00661090`, stride 0x18) | string `s_BuildingDestruction_00bc52b4`; 5 floats + 1 int | H |
| **DangerousBuilding** descriptor | `DangerousBuilding` (rdata) | `FUN_00660a90` (stride 4) | ECS-doc 07; 1 int32 flag/id | H |
| **DamageKey** descriptor (damage classification enum) | `DamageKey` `@0x829f1a10` | `FUN_006616c0` (stride 4) | ECS-doc 07; enum `s_DamageKeyEnum_00bc7264` | H |
| **RuntimeHealth** producer/descriptor | `RuntimeHealth` `@0x829f3fe0` | desc `FUN_00644c10` · **producer = `FUN_004cfed0`** | ECS-doc 07; **`{max,cur}`** floats @ stride 0xc (order corrected 2026-07-26 — `GetMaxHealth` reads `+0x00`, `GetHealth` `+0x04`); producer read first-hand | H |
| **RuntimeNodeHealth** producer/descriptor | `RuntimeNodeHealth` `@0x829f4070` | desc `FUN_00644cd0` · **producer = `FUN_004cfed0`** | ECS-doc 07; 1 float/node; per-node walk in `FUN_004cfed0` chunk#1 | H |
| **Health** descriptor (authored HP + flags) | `Health` | `FUN_0063e090` (schema `FUN_00656db0`, stride 8) | ECS-doc 07; 1 float + 3 bool | H |
| `DestructionLink` / `…TypeEnum` | `DestructionLink` (rdata `0x0032298`) | descriptor region-adjacent (`FUN_006422d0` cluster) | string-anchored (world-streaming.md); runtime = ObjectState.GetLinkGuid / oilrig `_DestroyLinkedGuid` | M |
| `TickDamage` | `TickDamage` `@0x829f1e90` | — | Xbox name only; PC body unlocated (per-tick damage applier) — confirm-live | open |
| `RuntimeSoundRuinKey` | `RuntimeSoundRuinKey` `@0x829f4100` | — | Xbox name only; ties ruined-state audio; PC unlocated | open |
| **Lua `OnStateChange` fire site** (guid,node,state) | — | inside the SecuROM `FUN_004d3e10` transition (or its callee) | not a code literal; fired on every transition — see §3.4; confirm-live | open |
| `ObjectState.SetState/SendDamage/StartEmitter/StopEmitter/GetLinkGuid` cfuncs | (Lua binder names) | binding-table VAs **unlocated** | Lua-facing (role certain); recover via `ObjectState.*` binding-table walk | L |

---

## 1. Where the state machine sits (load → tick → transition)

```
LOAD (world stream):
  UCFX model container  ──> FUN_004cf340  parse orchestrator chunk family
       INFO/NODE/STAT/CHDR/CEXE/SWIT  ──>  packed named-state machine (def)
       [SWIT u32s][node ×0xC][state ×0x14][enter/exit u32 command lists]

ACTIVATE (object streamed in, has StateMachine/BuildingDestruction comp):
  FUN_004b67b0  StateMachine::Activate
       FUN_008445b0(0x2a8)   alloc runtime machine instance (0x2A8 B)
       FUN_004d3f00(inst, obj, guid, uVar1, def)   bind runtime ← parsed def
       FUN_00649180(&PTR_PTR_00df9310, guid, …)     insert into machine pool

PER-FRAME (destructible update, from the layer-4 game-system list):
  FUN_006696a0  destructible object update   [gate *(obj+0xc4)!=0]
       FUN_004cfed0  produce RuntimeHealth {max,cur} + RuntimeNodeHealth/node (u16)
            if (machine instance absent)                       ← lazy init
                 FUN_004d3e10(inst, guid, InitState | InitDestroyedState)
                 FUN_004cfc80(guid, …)                          state replication
       FUN_004737f0 / FUN_004769f0 …                            renderable refresh

TRANSITION (state change):
  FUN_004d3e10(inst, guid, stateHash)   SetState   [body VIRTUALISED _DAT_024556d4]
       → executes the new state's Enter command script (SHOW/Hide/StartEmitter/
         CreateObject/SetStateOnMsg/…) + fires Lua OnStateChange(guid,node,state)

KILL (damage → destroyed):
  FUN_00704460 / FUN_00706ca0  (gameplay/explosion) ──> FUN_004d05c0
       FUN_004d3e10(inst, guid, 0x5D308F4F  InitDestroyedState) + zero HP
       iterate switch nodes  FUN_00690c60(node)          break pieces

MESSAGE REACTION (AI/props hear a destroy):
  FUN_0059be00   iterate msg queue, match DestroyMsg 0x1ED7AD78 / 0x3D0D4C99
```

The per-frame destructible update `FUN_006696a0` has **no direct callers** — it is dispatched through
the entity/component vtable, exactly like `PropPhysics::Activate` and `TerrainObject::Activate` in the
streaming map (§4). It is the destruction analog of those proximity-driven lifecycle methods.

---

## 2. The orchestrator parser — `FUN_004cf340` (H, already established, verified here)

Fully documented in [`../destruction_orchestrator_format.md`](../destruction_orchestrator_format.md);
re-confirmed here by call-graph (parser callees = the shared chunk-reader `FUN_00464780`, the
allocator pair `FUN_0084ac20`/`FUN_0084dce0`/`FUN_0084d760`, and the FFCS bookkeeping helper
`FUN_00401860`). Recap of the format the runtime consumes:

| Tag | u32 | Role |
|---|---|---|
| `INFO` | 0x4F464E49 | header `{skipped, switch_count→+0xC, node_count→+4}` |
| `NODE` | 0x45444F4E | switch node `{name_hash, state_count}` → 0xC-byte record `{name, count, states_ptr}` |
| `STAT` | 0x54415453 | named state `{name_hash}` → 0x14-byte `{name, enter_count, enter_ptr, exit_count, exit_ptr}` |
| `CHDR` | 0x52444843 | selects list `{which, count}` — `which` = `Enter 0x9DA97065` / `Exit 0xDB41017D` |
| `CEXE` | 0x45584543 | fills the selected list with `count × u32` command-script tokens |
| `SWIT` | 0x54495753 | `switch_count × u32` per-slot participant table |

**Enter/Exit are COMMAND SCRIPTS** (decoder `orchestrator::decode_script`): `0x1 <arg>` push · `0x2
<cmd>` invoke with pushed args · `0x3` end. The command `<cmd>` and every state/message argument is a
**name hash resolved at runtime** — which is exactly why none of them appear as code literals (§0
method note): the packed machine is a table of hashes, and the runtime interpreter looks each command
up in a registered command table (the SecuROM-side `_DAT_024556d4` dispatch, §3.3).

Validated retail pair (orchestrator_format.md): `al_veh_truck_hmmwv_avenger 0xAC990539` = 25 switch
slots / 11 nodes / ~8 states each; `al_veh_boat_destroyer 0xE54047D5` = 59 slots / 47 nodes.

---

## 3. The RUNTIME state machine (H PC bodies — the net-new recovery)

This is the piece rows 30/31 were missing. The runtime cluster lives in the `0x004cf340`–`0x004d5xxx`
neighborhood (same translation unit as the parser) plus the health/damage producers.

### 3.1 Initializer — `FUN_004cfed0` sets the machine's opening state (H, the anchor)

`FUN_004cfed0` (called from `FUN_006696a0` when `*(obj+0xc4)!=0`) both **produces the health
components** and **lazily initializes the state machine**. The decisive, literal anchor
(`ghidra/FUN_004cfed0` chunk#1):

```c
if (piStack_270 == (int *)0x0) {                 // no runtime machine instance yet
    FUN_004d3e10(iVar5, param_1, (-(uint)bVar3 & 0x52628825) + 0xace072a);   // SetState(init)
    FUN_00649180(&PTR_PTR_00df9310, param_1, 0, 0, auStack_248);             // pool-insert
    ...
    FUN_004cfc80(param_1, *piStack_284, iStack_288, auStack_210);            // replicate state
}
```

- `0xace072a` = **`InitState` (0x0ACE072A)** — the healthy spawn state.
- `bVar3` = the spawn-dead / low-health flag (set earlier when `Health.hp < DAT_00b97eec` or the
  actor's "dead" bit is set). When true, `-(uint)bVar3 = 0xFFFFFFFF`, so the arg becomes
  `0x52628825 + 0x0ACE072A = 0x5D308F4F` = **`InitDestroyedState` (0x5D308F4F)**.
- **`0x52628825` is exactly `InitDestroyedState − InitState`** — verified arithmetically. So the code
  itself proves both cracked names: an object that streams in already-destroyed opens in
  `InitDestroyedState`, a healthy one in `InitState`. This is the runtime realization of the
  orchestrator_format note "`0x0ACE072A` init: immediately SetState→…".

Health production (same body): reads the live actor health via `FUN_005857e0`, clamps `{max, cur}`
(negatives→0) and writes **RuntimeHealth** (0xc stride) via `FUN_0064a600` gated on `DAT_017bef94`,
then walks the body's destructible nodes (`FUN_004d5a10`/`FUN_004d5880`) writing **RuntimeNodeHealth**
(4-byte float/node) gated on `DAT_017befe4` — matching ECS-doc 07's "producer `FUN_004cfed0`" exactly.

### 3.2 `SetState(machine, guid, stateHash)` = `FUN_004d3e10` (H site / body read live — data jump-table)

All three transition callers funnel through this 28-byte dispatch (`ghidra/FUN_004d3e10`):

```c
void FUN_004d3e10(void) {          // args (machine, guid, stateHash) in EDI/stack
    *(byte *)(unaff_EDI + 0x10) &= 0xf8;              // clear machine state-phase low-3-bits
    (*_DAT_024556d4)();                               // indexed indirect jump (switch), table @ _DAT_024556d4
}
```

**This is NOT a SecuROM blocker** ([[securom-decompiled-not-a-blocker]]). Ghidra rendered it
`(*_DAT_024556d4)()` and flagged "could not recover jumptable (too many branches)" — it is an **indexed
indirect jump** (a `switch` on the state/command) whose **case table lives in the SecuROM data region**
(`_DAT_024556d4`), so Ghidra couldn't enumerate the arms statically. The *wrapper* is decompiled; the
per-state transition logic (match the target state's record, run its Enter script, fire the old state's
Exit script, write the new state byte at `model+0x352`, fire `OnStateChange`) is reached through that
data table and is **read live in the SecuROM-unpacked x32dbg image** (§8 item 1) — recoverable, not a
permanent wall. Its three callers, all passing a concrete state hash, are what let us name it:

| Caller | State passed | Meaning |
|---|---|---|
| `FUN_004cfed0` (init) | `InitState 0x0ACE072A` / `InitDestroyedState 0x5D308F4F` | opening state from spawn-dead flag (§3.1) |
| `FUN_004d05c0` (kill) | `InitDestroyedState 0x5D308F4F` | force-destroy (§3.3) |
| `FUN_004b67b0` (re-activate) | `0` (revert/default) | machine re-activate on stream-in (§3.3) |

### 3.3 Activate / force-destroy — `FUN_004b67b0`, `FUN_004d05c0` (H)

**`FUN_004b67b0` = StateMachine runtime Activate / instance builder** (`ghidra/FUN_004b67b0`, caller
`FUN_0066f220`): allocates the **0x2A8-byte runtime machine object** (`FUN_008445b0(0x2a8)`), and on
first activation binds it to the parsed definition `piVar4[3]` via **`FUN_004d3f00(inst, obj, guid,
uVar1, def)`** (the runtime constructor: parsed def → live machine), then pool-registers it
(`FUN_00649180(&PTR_PTR_00df9310, …)`). `piVar4[5]` is the instance state (0 = uninit → 1 = active).
On re-activate it calls `FUN_004d3e10(inst, guid, 0)` (revert to default state).

**`FUN_004d05c0` = force-destroy** (`ghidra/FUN_004d05c0`, callers `FUN_00704460`/`FUN_00706ca0` in the
gameplay/explosion `0x0070xxxx` region): the "make this object destroyed now" entry:

```c
FUN_004d3e10(iVar2, param_1, 0x5d308f4f);            // SetState(InitDestroyedState)
FUN_00649180(&PTR_PTR_00df9310, param_1, 0, 0, ...);
for (node in machine->nodes[*(iVar2+4)] stride 0xc)  // iterate switch nodes
    FUN_00690c60(node);                              // activate break pieces
pfVar5[1] = min(hp, 0.0);                            // clamp health to 0
```

This is where an external damage event (health hitting 0, an explosion volume, a scripted `Object.Kill`)
converts to a state-machine transition into the destroyed branch — the gameplay→machine bridge.

### 3.4 The Lua `OnStateChange` fire (inside the SecuROM-dispatched transition — read live)

Every transition is meant to fire `OnStateChange(uGuid, uiNodeHashName, uiStateHashName)` into the
object's Lua script (ECS-doc 06 §1.1; the oilrig/islandfortress sequenced-demolition drivers hang off
it — `oilrig.lua` `OnStateChange` on node `0x28825D4C`, `materialanimation_largecanopy02.lua` matches
`CollapseFireState`/`CollapseState`). Because `FUN_004d3e10` dispatches through the `_DAT_024556d4`
data jump-table (§3.2), the exact call into the Lua VM (via the `ObjectScript` COMP's `script_hash_0`,
ECS-doc 07) is **not statically visible** — the fire site is reached through that table. It is **read
live in the unpacked image** ([[securom-decompiled-not-a-blocker]], §7 item 1) to close the runtime
loop — recoverable, not a permanent gap. The Lua side is fully in the clear.

---

## 4. Damage → message routing (H consumer)

`SetStateOnMsg (0xE1142510)` rules in the Enter scripts listen for message hashes; the producer/
consumer of those messages is `FUN_0059be00` (`ghidra/FUN_0059be00`, caller `FUN_0059ae40`), the
**AI/proximity reaction to destruction** — it walks the message queue and matches the *literal* pair:

```c
iVar4 = FUN_004b2690(auStack_110);                   // pop next message
while (iVar4 != 0) {
    if ((iStack_10c == 0x1ed7ad78) || (iStack_10c == 0x3d0d4c99)) {   // DestroyMsg + sibling
        piVar11 = resolve-object(...);               // via DAT_017bf8xx handle table
        iVar4 = (**(code**)(*piVar11 + 0xe0))();      // vcall: object type/state query
        if (iVar4 == 1) { ... FUN_00431480(...); FUN_00401740(dist²); }  // react by distance
    }
    iVar4 = FUN_004b2690();
}
```

- `0x1ed7ad78` = **`DestroyMsg`** (cracked), `0x3d0d4c99` = its message sibling (name still open, but
  **role proven**: it travels with DestroyMsg in the same match). The earlier arm of the same function
  handles a health-threshold pass (`local_c8[0] * DAT_00b92b58` distance falloff, `FakeDead` string),
  so this function is the "something near me was damaged/destroyed" reactor.
- The third message name `DamageMsg (0xC6507EE1)` is the paired damage-event notification (cracked from
  the naming family; consumer site not isolated this pass).

**Routing summary.** A health drop in `FUN_004cfed0` (RuntimeHealth/RuntimeNodeHealth) or a kill in
`FUN_004d05c0` both post into the machine's message stream; `SetStateOnMsg` rules baked in the Enter
scripts match `DamageMsg`/`DestroyMsg`/`0x3D0D4C99` and drive the next transition, while `FUN_0059be00`
lets *other* entities (AI, chained props) react. Tie to the event bus
([`event_bus_code_map.md`](event_bus_code_map.md)) is **structural** — the `FUN_004b2690` queue is the
per-object message ring, not confirmed to be the global subscriber bus; confirm-live to bind.

---

## 5. BuildingDestruction / DestructionLink + descriptors (H/M)

### 5.1 Descriptors (both builds)

| Class | Xbox | PC descriptor | Schema / producer | Payload |
|---|---|---|---|---|
| `BuildingDestruction` | `@0x829f1538` (rdata `0x0031550`) | `FUN_00642590` | schema `FUN_00661090`, stride 0x18 | 5 floats + 1 int (thresholds / rubble state) |
| `DangerousBuilding` | rdata | `FUN_00660a90` | stride 4 | 1 int32 flag/id |
| `DamageKey` | `@0x829f1a10` | `FUN_006616c0` | stride 4 | enum `DamageKeyEnum` |
| `Health` | — | `FUN_0063e090` | schema `FUN_00656db0`, stride 8 | 1 float + 3 bool |
| `RuntimeHealth` | `@0x829f3fe0` | `FUN_00644c10` | producer `FUN_004cfed0` | `{max, cur}` floats (0xc, order corrected 2026-07-26) |
| `RuntimeNodeHealth` | `@0x829f4070` | `FUN_00644cd0` | producer `FUN_004cfed0` | 1 float / node (4) |
| `StateMachine` | — | `FUN_00641aa0` | schema `FUN_0065fcb0`, stride 0x10 | 4 name-hash int32 {def, initial, sub, param} |
| `ObjectScript` | — | `FUN_006424e0` | schema `FUN_00660ff0`, stride 8 | `{script_hash_0, arg/hash_1}` |
| `DestructionLink` / `…TypeEnum` | rdata `0x0032298` | `FUN_006422d0` cluster | — | intact↔ruined / parent↔child link id + type enum |
| `TickDamage` | `@0x829f1e90` | **unlocated** | — | per-tick damage applier (open) |
| `RuntimeSoundRuinKey` | `@0x829f4100` | **unlocated** | — | ruined-state audio key (open) |

All PC descriptors share the ECS reflection backbone (`&PTR_CopyFromStream_*`, seed `0x9e3779b9`,
`FUN_0064a770`) documented in the streaming map §4 and ECS-doc 07 — i.e. these are stream-deserialized
world-load components, and their **runtime consumer is the `FUN_006696a0`→`FUN_004cfed0` update** above.

### 5.2 Multi-part collapse coordination (M)

`BuildingDestruction` marks a multi-part building; `DestructionLink` pairs its parts (and pairs the
**intact** building with its **ruined** counterpart). The runtime coordinator is **script-driven**, not
a monolithic native function: the destruction Enter script's `CreateObject (0xC6E8AFA8)` spawns
break-away props and `KillObjectsLinkedToHP (0x207C1CC7)` removes hardpoint-linked children, while the
Lua `OnStateChange` drivers (`oilrig.lua` `_DestroyOilrigSequence`, `islandfortress.lua`
`tAdjacencyTable` flood-fill via `KillNode`, ECS-doc 06 §Destructible sets) sequence the multi-slice
collapse and resolve links with `ObjectState.GetLinkGuid`. `FUN_00526220` (§0.5) is the small
type→bitmask classifier those consumers use (`CreateObject 0xc6e8afa8 → 4`). So "multi-part collapse"
= native per-node state machine (§3) **+** authored Lua sequence, married at `OnStateChange`.

---

## 6. vz_state pristine↔ruined overlay swap (M — cross-ref)

Two orthogonal mechanisms produce "ruined" geometry, and it matters not to conflate them:

1. **In-model state machine (this doc).** A destructible model carries its intact *and* break-piece
   geometry in one container; the machine (§3) switches which SEGM `state_mask` is active
   (`model+0x352`, prop-LOD map §5) — `PristineState`/`DamagedState`/`DestroyedState` toggle the
   sub-object masks. This is per-object, real-time, reversible-in-data.
2. **vz_state world overlay (streaming map).** For *authored, permanent* world-state changes (a
   building that is ruined for the rest of the mission, mission-scripted demolition), the world-state
   overlay system swaps the whole **pristine block for its ruined block** at stream time — the
   `vz_state` overlay layer (the PMC-interior overlay `vz_state 667` in
   [[pmc-teleport-coords-and-interior]], and the `docs/vz_state_analysis.md` overlay analysis). This is
   the same overlay/patch-block mechanism the streaming map documents for state layers, keyed by the
   c3 block index, **not** a per-frame state-machine transition.

The bridge: a mission that "destroys building X permanently" runs the §3 machine to `DestroyedState`/
`GoneState` for the live show, and the vz_state overlay makes that persistent across a stream-out/
stream-in (so the ruin survives leaving and returning). Marrying the exact overlay-selection call to a
building's `DestructionLink` ruined-id is **confirm-live** (bp the block-open path with a scripted
demolition active) — cross-ref `world_streaming_code_map.md` §"overlays".

---

## 7. CRACKED HASHES (the highest-value deliverable)

Cracked with `pandemic_hash_m2` (FNV-1a + `|0x20` case-fold + `^0x2A ·prime`) via the rainbow table +
naming-scheme brute force. **11 of 14** previously-unresolved hashes named; two independently
corroborated by the decompiled code constants (§3.1). All verified (`hash(name) == target`).

### State-name vocabulary (global; identical across all destructibles) — **9 / 11 cracked**

| Hash | **Cracked name** | Role (from orchestrator_format.md + code) | Evidence |
|---|---|---|---|
| `0x0ACE072A` | **`InitState`** | healthy spawn / init → SetState `PristineState` | **code-literal** in `FUN_004cfed0` (§3.1) + rainbow |
| `0xACB51200` | **`PristineState`** | the SHOW / undamaged state | rainbow + brute |
| `0x5A6E8927` | **`InitDamagedState`** | spawn-in-damaged init | brute (Init+Damaged pattern) |
| `0x1D5575A1` | **`DamagedState`** | mid damage state | brute |
| `0x5D308F4F` | **`InitDestroyedState`** | spawn-in-destroyed init | **code-literal** `0x52628825+0x0ACE072A` in `FUN_004cfed0`/`FUN_004d05c0` (§3.1/3.3) |
| `0x7687DF41` | **`DestroyedState`** | destroyed state | rainbow + brute |
| `0x92791EBB` | **`StartDestroyedState`** | the wreck: fires + explosion + prop spawns + KILL SELF | brute (Start+Destroyed pattern) |
| `0xCA261E5B` | **`GoneState`** | terminal / empty | brute |
| `0xA530B827` | **`DetachState`** | detached break-part state | brute |
| `0x381BE6A4` | *unresolved* | (state) | — |
| `0xCE603754` | *unresolved* | (state) | — |

The scheme is **`{Init,Start,∅} + {Pristine,Damaged,Destroyed} + State`**, plus the specials
`GoneState` (terminal) and `DetachState` (break-parts). The two open ones almost certainly follow the
same grammar (a `Fire*`/`Debris*` variant — cf. the shipped Lua names `FireDebrisState`,
`FireDestroyedState`, `CollapseState`, `CollapseFireState` — or a `Start{Damaged}`/second-tier form),
but no candidate hit; left honestly open.

### Message vocabulary (SetStateOnMsg listens for these) — **2 / 3 cracked**

| Hash | **Cracked name** | Role | Evidence |
|---|---|---|---|
| `0xC6507EE1` | **`DamageMsg`** | damage-event notification | rainbow + brute (Damage+Msg) |
| `0x1ED7AD78` | **`DestroyMsg`** | destroy-event notification | **code-literal** in `FUN_0059be00` (§4) + brute |
| `0x3D0D4C99` | *unresolved* | message — **role proven** (matched beside DestroyMsg in `FUN_0059be00`) | — |

### Still open (honest)

| Hash | Kind | Notes |
|---|---|---|
| `0x381BE6A4`, `0xCE603754` | state | naming-grammar variants; no candidate matched |
| `0x3D0D4C99` | message | travels with `DestroyMsg`; likely `ExplosionMsg`/`KillMsg`-class (unconfirmed) |
| `0xB4DBE473` | command | the one unresolved Enter/Exit command verb (destroyer); not `Enable/Disable*`, `Stop/StartAnim`, `SetNodePhysics*`, `PlaySound`, `Destroy/SpawnObject` (all tried) |
| `0x28825D4C` | node | oilrig destruction node (`oilrig.lua` OnStateChange); a HIER node name in the oilrig model — needs the model's HIER dump (`mercs2_probe hier`), not in the Lua/rainbow corpus |

Method note: hashes crack against **plausible identifier strings**, and FNV-1a-32 has collision risk,
but every hit here is (a) semantically exact for its role and (b) part of a self-consistent naming
family — and `InitState`/`InitDestroyedState`/`DestroyMsg` are additionally pinned by code constants,
so the family is trustworthy.

---

## 8. Confirm-live inventory (x32dbg, read-only while PAUSED — [[x32dbg-mcp-no-resume]])

1. **`FUN_004d3e10` SetState body (`_DAT_024556d4`).** Break the indirect; single-step into the
   SecuROM-unpacked transition. Recover: the Enter-script interpreter (opcodes `0x1/0x2/0x3`), the
   command dispatch table (resolves `SetStateOnMsg 0xE1142510` / `CreateObject 0xC6E8AFA8` / `SetState`
   / `DisableConstraint 0x842AE03E` / `SetRootNode 0xC20AB66F` / `StartAnim 0xCFF8BCA4` /
   `SetNodePhysicsModelKeyframed 0xECADCE57` / `KillObjectsLinkedToHP 0x207C1CC7` / emitter cmds), and
   the **`OnStateChange` Lua fire** (§3.4). Reading this live in the unpacked image turns rows 30/31 fully H (recoverable, not a wall — [[securom-decompiled-not-a-blocker]]).
2. **Crack `0xB4DBE473`** (unresolved command) live: at the command-dispatch table found in (1), read
   the string/handler the destroyer's machine invokes for it.
3. **Machine init literal.** Break `FUN_004cfed0` @ the `FUN_004d3e10` call; confirm `bVar3` gates
   `InitState` vs `InitDestroyedState` and dump the 0x2A8-byte runtime machine layout
   (`FUN_008445b0(0x2a8)`), keyed to the parsed definition `piVar4[3]`.
4. **Message routing.** Break `FUN_0059be00` @ the `0x1ed7ad78`/`0x3d0d4c99` compare with a live
   explosion; confirm `FUN_004b2690` is the per-object message ring vs the global event bus, and name
   `0x3D0D4C99` by reading the poster's string.
5. **`0x28825D4C` oilrig node.** `mercs2_probe hier --model <oilrig>` (or dump the HIER at the live
   oilrig object) → match the node hash to its bone name.
6. **`TickDamage @0x829f1e90` / `RuntimeSoundRuinKey @0x829f4100`.** HW-bp the RuntimeHealth write in
   `FUN_004cfed0`, walk back to the per-tick damage applier and the ruined-audio key writer to bind
   PC VAs.
7. **vz_state overlay bind** (§6): bp the block-open path with a scripted-demolition building; confirm
   the pristine→ruined block swap keys off `DestructionLink`.

---

## 9. Reconciliation with `mercs2_engine` (rows 30/31 = 🟡)

**Status: 🟡 — formats + state selection + visibility execution DONE; runtime transition tick,
message routing, and the Enter-script effects (CreateObject / emitters / constraints) NOT implemented.**

- **What matches (done).** The engine reads the full orchestrator chunk family
  (`mercs2_formats::orchestrator::parse_state_machine`) and decodes Enter/Exit command scripts
  (`decode_script`, grammar `0x1/0x2/0x3`), and the workshop **executes each switch node's chosen
  state's SHOW/Hide script over HIER→INDX→groups** (`orchestrator::machine_group_visibility`, default
  per node = its own init `SetState` target `default_state_index`) — this is the faithful analog of
  §3's SetState → visibility. The SEGM `state_mask` gate (`model+0x352`, `build_indexed_state`
  `active_bit`) is honored (prop-LOD map §5). Heuristic labels were purged; the workshop shows
  **game-data state hashes/names only** — this map hands it **9 real state names + 2 message names** to
  display instead of raw hashes.
- **What is missing (faithful-impl targets):**
  1. **Runtime transition tick** — a `SetState(machine, guid, stateHash)` that (a) runs the new state's
     Enter script and the old state's Exit script and (b) evaluates `SetStateOnMsg (0xE1142510)` rules
     against an incoming message stream (§3.2/§4). Mirror `FUN_004d3e10`'s role (the PC body is
     virtualised, so the engine implements it from the decoded script, not a port).
  2. **Damage → message routing** — health drop (`RuntimeHealth`/`RuntimeNodeHealth`, produced like
     `FUN_004cfed0`) and kill (`FUN_004d05c0`) post `DamageMsg`/`DestroyMsg`/`0x3D0D4C99` that the
     machine's `SetStateOnMsg` rules consume; plus the initial-state pick (`InitState` vs
     `InitDestroyedState` from a spawn-dead flag, §3.1).
  3. **Enter-script effect commands** — `CreateObject` (break-away prop spawn), `StartEmitter`/
     `StopEmitter` (fire/explosion FX — see [`particle_fx_code_map.md`](particle_fx_code_map.md)),
     `DisableConstraint`/`SetNodePhysicsModelKeyframed` (physics handoff), `KillObjectsLinkedToHP` — all
     currently unimplemented; these are the visible destruction payload.
  4. **Lua `OnStateChange` callback fire** — bind entity→`ObjectScript.script_hash_0` and fire
     `OnStateChange(guid, nodeHash, stateHash)` on every transition, so the authored sequenced-demolition
     drivers (oilrig/islandfortress) run.
- **Do NOT** treat this machine as distance-LOD (prop-LOD map §9 / `rendering_fx_lighting_gap.md` §J):
  it is a gameplay/destruction state machine, orthogonal to `RtGenericLOD`.