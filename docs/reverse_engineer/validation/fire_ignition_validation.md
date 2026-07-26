# Double-blind validation — `docs/reverse_engineer/fire_ignition_code_map.md`

- **Subject**: the 3-entry `luaL_Reg` table at VA `0x00B9A7A8`, and the wider fire / ignition / burn system.
- **Date**: 2026-07-26
- **Method**: Phase A written from primary sources *before* the map was opened. Phase B added afterwards.
- **Primary sources used**
  1. `output/_ghidra/securom_dump/mercs2_unpacked.exe` — raw disassembly (capstone, VA→file via the PE section table).
     Section table used: `.text` VA `0x00401000` raw `0x1000`; `.rdata` VA `0x00B05000` raw `0x705000`;
     `.data` VA `0x00BF6000` raw `0x7F6000`. Image base `0x00400000`.
  2. `output/_ghidra/securom_dump/mercs2_nodrm_v3.exe` — the project's DRM-free rebuild, used **only** to read
     through SecuROM split thunks. Verified byte-identical to the primary at `0x004B7BB0` and `0x004B82D0`
     before being trusted for anything.
  3. `output/_ghidra/mercs2_unpacked.exe_decomp.txt` — Ghidra, consulted for its *claims* (sizes, signatures,
     caller lists), which are treated as assertions to be checked, not as evidence.
  4. Shipped game data: `vz.wad`, `shell.wad`, `English.wad`, `English-patch.wad`, `Loading.wad`, `vz-patch.wad`
     via `cargo run -p mercs2_probe --bin block_content_grep` (decompresses every block).
  5. `tools/pandemic_hash.py` (`pandemic_hash_m2`).

---

## Phase A — independent findings (written before reading the map)

### A1. `0x00B9A7A8` is not a namespace; it is inside a `FuelTrail` sub-table of `Graphics`

**The registry.** The namespace registry begins at `0x00DFD478` (`.data`) with **stride `0x0C`**:
`{const char* name, luaL_Reg* table, const char* post_script}`. It runs 31 entries and terminates at
`0x00DFD5EC` with a null name. Full list, in order:

```
_SYS  Sys  Pg  Object  Player  Event  Ai  Human  Debug  Vehicle  Airstrike  Gui  _GuiInternal
Graphics  Sound  ObjectFilter  Net  math  Camera  Junk  ObjectState  Movie  Animation  VO
Weapon  String  Table  Report  Disguise  FactionZone  LTILibName
```

There is **no `Fire` namespace**. Entry 13 is `0x00DFD514: {"Graphics" @0x00BB56A4, 0x00B9A4D0, NULL}`.
The string `"Graphics"` exists exactly once (`0x00BB56A4`) and is pointed to from exactly two places,
one of which is that registry row. The table pointer `0x00B9A4D0` is referenced from **exactly one**
address in the whole image: `0x00DFD518`, the registry row's table field.

**The marker-row walk.** Reading `0x00B9A4D0 → 0x00B9A7C8` as 8-byte `luaL_Reg` rows:

| metric | value |
|---|---|
| rows | **95** |
| callable rows (func in `.text`) | **75** |
| marker rows | **20** (10 open `0xFFFFFFFF` + 10 close `0xFFFFFFFE`) |
| nesting depth at end | **0** (balanced, every open matched by a same-name close) |
| rows pointing at the shared stub `0x006D5640` | **3** |

The 10 sub-tables, in order: `Camera`, `Atmosphere`, `Bloom`, `MotionBlur`, `Contrast`, `Monochrome`,
`Grainy`, `AA`, `Effect`, **`FuelTrail`**. All are depth-1; there is no deeper nesting.

**The bytes in question** (verbatim from the walk):

```
00B9A798: } CLOSE "Effect"          {0x00BB51F0, 0xFFFFFFFE}
00B9A7A0: { OPEN  "FuelTrail"       {0x00BB51BC, 0xFFFFFFFF}
00B9A7A8:     "Ignite"      -> 006D5640
00B9A7B0:     "Extinguish"  -> 006D5640
00B9A7B8:     "Put"         -> 005B2A50
00B9A7C0: } CLOSE "FuelTrail"       {0x00BB51BC, 0xFFFFFFFE}
00B9A7C8: {0,0}   <- table terminator
```

So the Lua path is **`Graphics.FuelTrail.{Ignite, Extinguish, Put}`**. The string `"Ignite"` occurs
exactly once in the entire image (`0x00BB51B4`), so there is no second binding of that name anywhere.

### A2. What the three cfuncs do

**`Ignite` and `Extinguish` → `0x006D5640`, the engine-wide no-op stub.**
In the SecuROM dump this VA holds 5 bytes, `E9 7B CA 5F 6F` = `jmp 0x6FCD20C0`, a target outside the
image — a SecuROM hook, not a body. Reading the same VA in `mercs2_nodrm_v3.exe` (verified byte-identical
to the primary at `0x004B7BB0` and `0x004B82D0` first) gives `33 C0 C3` = **`xor eax, eax; ret`** — a Lua
C function that returns 0 results and does nothing.

This is not a fire-specific fact: **693 `.rdata` slots in the image point at `0x006D5640`**. Among the
named `luaL_Reg` rows that use it are `print`, `Debug.Printf`, `Debug.Assert`, `Debug.LogError`,
`Debug.LogWarning`, `Debug.GetCallstack`, `Graphics.Atmosphere.SetSky`, `ObjectState.PrintStateMachine`,
`ObjectState.DebugStateMachine`, and most of the `Ai.Plan*` family. It is the retail-stripped stub.

**`Put` → `0x005B2A50` (`0x005B2A50–0x005B2B19`, 202 B) does nothing on success.**
The body parses up to four argument groups through `0x0059F780`, accumulating a running Lua stack index
in `edi`. Every parse-failure branch reaches `0x004B2A50`, whose whole body is

```
004B2A50  mov ecx, [esi] ; mov eax, 1 ; call 0x85D5D0 ; test eax, eax ; jne … ; ret
```

— the raise-an-argument-error helper. The path where all arguments parse falls through to

```
004B2B14  xor eax, eax
004B2B17  pop esi ; pop ecx ; ret
```

There is **no work call on any path**. The contrast that settles it: `ObjectState.StartEmitter`
(`0x005D2FA0`) uses the identical arg-parsing idiom and identical `xor eax,eax; ret` tail, but its
success path first does `push/push/push; call 0x004D28C0`. `Put` has had that call removed.

### A3. Script call sites: zero

Raw substring scanning of the shipped `.wad` files is **invalid** — payloads are compressed. My first
attempt returned 0 hits for *every* needle including `Graphics` and `ObjectState`, which certainly do
appear in scripts. Recorded here because the null result looks like evidence and is not.

The valid test is `mercs2_probe --bin block_content_grep`, which decompresses each block
(`ok=11370 failed=0` on every run, so no silent decompression failures):

| needle | blocks in `vz.wad` |
|---|---|
| `FuelTrail` | **0** |
| `Ignite` | **0** |
| `Extinguish` | **0** |
| `Graphics` | 2 (positive control) |
| `ObjectState` | 1 (positive control) |
| `StartEmitter` | 1 (positive control) |
| `SendDamage` | 1 (positive control) |
| `SetState` | 5 (positive control) |
| `Atmosphere` | 6 (positive control) |
| `Ignitor` | 1 |
| `Flammable` | 1 |

Lua bytecode stores field names as plain string constants — proven by the positive controls. `FuelTrail`
appearing in **zero** blocks means no script can even index the sub-table, so `Ignite`, `Extinguish` and
`Put` are all unreachable from script. **Zero call sites, confirmed.**

### A4. The real ignition system

**Authoring components** (descriptor layout derived from the registrar code, not from the `.data`
initialisers — those globals are written at runtime, so the raw file values are meaningless):

| component | descriptor | size | budget | registrar |
|---|---|---|---|---|
| `Flammable` | `0x017BE258` | **4 B** | `0x100` = 256 | `0x00643070–0x0064310E` |
| `Ignitor` | `0x017BE2A8` | **0x0C = 12 B (3 floats)** | `0x100` = 256 | `0x00643120–0x006431BE` |
| `TickDamage` | `0x017BE1B8` | **0x10 = 16 B** | — | `0x00642EF0–0x00642F95` |
| `RuntimeIgnitor` | `0x017BF388` | **0x1C = 28 B** | `0x100` = 256 | `0x00645650–0x006456F2` |
| `RtTickDamage` | `0x017BFBF8` | **0x10 = 16 B** | — | **`0x00646AA0`**–`0x00646B43` |

**Ignitor → RuntimeIgnitor.** `Ignitor` is the only one of the two that gets a class handler. At
`0x00670FC7` a 12-byte handler object is built: `{vtable = 0x00BCD0B4, hash(name), Ignitor type id}`.
Vtable `0x00BCD0B4` slot **`+0x18` = `0x0066E650`** — confirmed by direct read of the vtable.
(Caveat: `0x0066E650` is *not* Ignitor-specific — it is also `ColorAnimation`'s slot `+0x3C`.)

`FUN_0066E650` (`0x0066E650–0x0066E7B9`, 362 B): fetches the Ignitor payload with
`mov ecx, 0x17BE2A8; call 0x005857E0`; reads the object transform (`0x00665AF0`); builds an AABB of
`pos ± f[0]`; queries `0x004058B0`; copies `f[0..2]` into a temp; and then, with
`mov edi, 0x17BF3A0` (RuntimeIgnitor descriptor `+0x18`), calls `0x0064A600` — **producing a
`RuntimeIgnitor`**. Chain confirmed.

**The tick.** `FUN_00675E50` (`0x00675E50–0x0067725C`, 5132 B) is a per-frame pass over **23** component
descriptors, essentially all of them `Rt*`/`Runtime*`: `RtAlphaAnimation`, `RtColorAnimation`,
`RtFlowControl`, `RtFlowCycleTimer`, `RtGenericLOD`, `RtLightAnimation`, `RtRedEffect`, `RtRibbon`,
`RtScaleAnimation`, `RtSpeedLimit`, **`RtTickDamage`**, `RtVFX`, `RTHuman`, `RuntimeAirstrikeAirplane`,
`RuntimeAirstrikeProjectile`, `RuntimeAlternatingFire`, `RuntimeHomingProjectile`, **`RuntimeIgnitor`**,
`RuntimeObjectiveMarker`, `RuntimeTimer`, `RuntimeVelocity`, `LightAnimation`. At `0x00677219`, inside the
loop that walks the `RuntimeIgnitor` pool (using that descriptor's `+0x24/+0x26/+0x28/+0x38` fields), it
calls **`0x004B82D0`**, with `dt` in `xmm0` (`movss xmm0, [ebp+8]` at `0x006771F1`).

**`FUN_004B82D0`** (`0x004B82D0–0x004B85B4`, 741 B): bails if `dt <= 0`; scales `f[0]` and `f[1]` by `dt`;
gathers candidate entities via `0x004B7B00`; for each candidate calls **`FUN_004B7B50`** as a filter and
skips on false; otherwise calls `FUN_004B7BB0` with (radius `= f[2]`, `f[0]*dt`, `f[1]*dt`, …).

### A5. `FUN_004B7B50` **is** the `Flammable` reader

This is the most consequential thing I found. `FUN_004B7B50` gets the candidate's class code from
`call [vtable+0xE0]`, then dispatches through a jump table:

```
004B7B66  movzx eax, byte ptr [eax + 0x4B7B9C]     ; index table, 11 bytes, for code-5 in 0..0xA
004B7B6D  jmp   dword ptr [eax*4 + 0x4B7B90]       ; 3 targets
```

Decoding both tables from the raw bytes:

| target | meaning | class codes |
|---|---|---|
| `0x004B7B74` `xor al,al; ret` | never burns | 5, 7, 9, 11, 12, 13, 15 |
| `0x004B7B8C` `mov al,1; ret` | always burns | 8, 10, 14, and the `default` (any code outside 5..15) |
| `0x004B7B77` | **`Flammable` test** | **6** |

and the `0x004B7B77` arm is:

```
004B7B77  mov  eax, [esp+4]          ; entity
004B7B7B  mov  ecx, 0x17BE258        ; <-- the Flammable component descriptor
004B7B80  call 0x005857E0            ; component fetch
004B7B85  neg eax ; sbb eax,eax ; neg eax   ; -> bool(component present)
004B7B8B  ret
```

So for one entity class, retail *does* gate ignition damage on the presence of a `Flammable` component.

**Why this is easy to miss.** Ghidra reproduces the switch but **drops the `ecx` register argument**,
emitting `iVar2 = FUN_005857e0();` with no operand — the `0x17BE258` descriptor, and therefore the whole
`Flammable` link, is simply absent from the decompilation. Ghidra also reports `size=63` for this function
(the real extent including its two jump tables is `0x004B7B50–0x004B7BAF`, 96 B).

Corroboration from the reference side: `.text` references to the `Flammable` descriptor base `0x017BE258`
are `0x004B7B7C` (this reader), `0x006430AF`/`0x006430C5` (its own registrar), and nothing else;
its type-id field `0x017BE25C` is read only from the registrar and the two generic reflection handlers
(`0x0063C690`, `0x00662720`) that every component gets. So `0x004B7B7C` is the *only* gameplay reader —
but it exists.

### A6. `FUN_004B7BB0` — Ghidra is wrong about it, and the damage math

Ghidra: `==== FUN_004b7bb0 @0x004b7bb0 size=664 …` and `void FUN_004b7bb0(undefined4, undefined4, float*)`.
Raw disassembly: the body runs `0x004B7BB0 → 0x004B82C3` and is **1811 bytes** (`0x713`), ending in a
`ret` with `0x004B82D0` starting after `int3` padding. The single call site passes **eight** arguments.
Both the size and the signature are wrong.

Frame layout recovered from the call site in `FUN_004B82D0`:
`[ebp+0x14]` = radius `r`, `[ebp+0x18]` = centre rate × dt, `[ebp+0x1C]` = rim rate × dt.

**Clamped-OBB distance** (`0x004B7DB0–0x004B7E48`): the point is taken into box space (`0x0096BC76`), each
component is `andps`-ed with `0x7FFFFFFF` (absolute value) and the corresponding half-extent subtracted;
only components that come out **positive** (i.e. outside the box) are squared and accumulated; `0x00401740`
takes the square root. That is exactly the distance from a point to the surface of a clamped box.

**Radius reject**: `fld [ebp+0x14]; fcompi` — if `d > r`, return 0 immediately.

**Linear falloff** (`0x004B7E63–0x004B7E86`):

```
xmm1 = [ebp+0x1C]            ; rim
xmm0 = [ebp+0x18] - xmm1     ; centre - rim
xmm0 = xmm0 / [ebp+0x14]     ; / r
xmm0 = xmm0 * d
xmm0 = xmm0 + xmm1           ; rate = rim + (centre-rim) * d/r
```

i.e. `lerp(centreRate, rimRate, d/r)`, with `dt` already folded into both endpoints by the caller.
`rate <= 0` → return 0.

**Scale by the `Fire` DamageKey, then post twice.** `pandemic_hash_m2("Fire") == 0x8A552089` (recomputed).
It appears as a code literal at exactly two places inside this function — `0x004B7F0D` and `0x004B8212`
(both `push 0x8a552089; call 0x00632360; mov eax,[eax]`, the key's scale float). Each is followed by
`mulss` with the rate, a `comiss` against `[0x00B9B690]`, and then

```
call 0x00407B20
call 0x00406170
```

**twice**, and the two sites differ exactly as a primary/per-node split:

- site 1 (`0x004B7F4B`) writes `word 0xFFFF, word 0xFFFF, byte 0` as the target node — the no-node
  sentinel, i.e. the whole-entity health hit;
- site 2 (`0x004B8256`) writes `ebx` (a node handle) and `dx` (a node index word) — a specific node.

Both sites are additionally gated on two non-zero global counters at `0x017BBD30` and `0x017BBD34`; if
either is zero the key scale stays `0.0`, the `comiss` fails, and nothing is posted at all.

### A7. `ObjectState`, emitters, and the destruction states

**`ObjectState` table `0x00B995B0`** — 9 callable rows, then a `{"None", 0}` terminator (followed by a
stray `{"None", 0x40490FDB}` word, `0x40490FDB` being `float pi`):

```
SendMessage 005D2AE0   SendDamage 005D2BE0   SetState 005D2CE0   GetLinkGuid 005D2DE0
StartEmitter 005D2FA0  StopEmitter 005D3090   GetStringHash 005D3180
PrintStateMachine 006D5640 (stub)            DebugStateMachine 006D5640 (stub)
```

So 9 rows, but 2 of the 9 are the no-op stub — only 7 do anything.

**`StartEmitter`.** The *binding* is `0x005D2FA0`; after parsing three arguments it calls
**`0x004D28C0`** (`0x004D28C0–0x004D2AC3`, 516 B), which calls `0x00688970` at `0x004D2934`.
`0x00688970` is itself a SecuROM split thunk (`jmp dword ptr [0x02459260]`) with the real body at
`0x00688980`, which walks an indexed node array (`[esi+0x50]` count, `[esi+0x4C][idx]`, then `[eax+0x4C]`
→ `[ecx+0x20]`). That shape is consistent with resolving a named node/hardpoint transform, but I could
**not** prove the "hardpoint" identification from the binary.

**`FUN_004D4680` is not statically readable.** In *both* the SecuROM dump and the DRM-free rebuild it is
`jmp dword ptr [0x0245A004]` — a split thunk whose body SecuROM has taken. Ghidra has no function there.
What can be established is behavioural: at `0x00683C83`, `0x00683C8F`, `0x00683D0B` and `0x00683D17` its
return value is compared against destruction-state hashes, so it returns a state-name hash.

**The destruction-state compares.** Inside `FUN_00683C40` (Ghidra: `size=301`, `callers=[]`):

```
00683C83  call 0x004D4680 ; cmp eax, 0x381BE6A4 ; je …
00683C8F  call 0x004D4680 ; cmp eax, 0xCA261E5B ; je …     ; GoneState
00683D0B  call 0x004D4680 ; cmp eax, 0x381BE6A4 ; je …
00683D17  call 0x004D4680 ; cmp eax, 0xCA261E5B ; je …     ; GoneState
```

`pandemic_hash_m2("GoneState") == 0xCA261E5B` ✓. `0x381BE6A4` occurs **twice**, always immediately
paired with a `GoneState` compare on the same value — and those are its only two occurrences in the image.

**Hash results.**

| hash | name | status |
|---|---|---|
| `0x8A552089` | `Fire` | recomputed ✓; **3** code literals: `0x004B7F0D`, `0x004B8212`, `0x00693DEC` |
| `0xCA261E5B` | `GoneState` | recomputed ✓; 2 literals, both in `FUN_00683C40` |
| `0x787C0871` | **`Weapon`** | **cracked here**; paired with `Fire` at `0x00693DEC` |
| `0x381BE6A4` | — | **not cracked** (see below) |
| `0xCE603754` | `FalloffState` | arithmetic ✓, but the value occurs **nowhere** in the image |
| `0x28825D4C` | `PauseState` | arithmetic ✓, value occurs nowhere in the image |
| `0x694683EB` | `CollapseState` | arithmetic ✓, value occurs nowhere in the image |

`0x381BE6A4` survived a serious attack: I harvested all **164,070** distinct printable tokens from every
section of the image and hashed each against 180 prefix/suffix combinations (`State`, `Node`, `Event`,
`Anim`, `Phase`, `Mode`, `Damage`, `Key`, and `Fire*`/`Debris*`/`Destruction*`/`Building*` prefixes).
No match. The `Fire*`/`Debris*` family is disproved to that extent.

For `FalloffState` / `PauseState` / `CollapseState` the name→hash arithmetic is trivially correct and
proves nothing on its own. `0x28825D4C` and `0x694683EB` do appear in the project's uncracked-hash
harvest (`docs/data/bone_name_candidates.txt`), so those two values at least exist somewhere in game
data. `0xCE603754` does not appear there either — I found no anchor for it anywhere.

### A8. A third `Fire` literal the search turned up

`0x8A552089` occurs a **third** time, at `0x00693DEC` inside `FUN_00693D80` (306 B, Ghidra
`callers=[]`, `void FUN_00693d80(void)`):

```
00693DE3  cmp dword ptr [eax+4], 0x787C0871    ; "Weapon"
00693DEA  jne skip
00693DEC  cmp dword ptr [eax+8], 0x8A552089    ; "Fire"
00693DF3  jne skip
00693DF5  push eax ; mov eax,[edi] ; push eax ; call 0x00693BB0
```

So there is a `(Weapon, Fire)`-keyed path outside `FUN_004B7BB0`. (`FUN_00693BB0`: Ghidra says `size=24`;
real extent `0x00693BB0–0x00693CBB`, 268 B — another mis-size.)

### A9. What I could not check

- **`FUN_004D4680`'s body** — SecuROM-stolen in both available dumps. `= GetState(node)` is supported
  behaviourally (it returns a value compared against state hashes) but the body is unreadable statically.
  Settling it needs a live debugger breakpoint on `0x004D4680` and a read of the return value against a
  known model's destruction states.
- **`0x00688970` = a *hardpoint* resolver** — the body shape fits a node lookup; the "hardpoint" name is
  not established from the binary.
- **The `Ignitor` field semantics** — I infer `f[0]` = radius-ish (it builds the AABB and is `[ebx+8]`
  → `r` at the tick), `f[0]`/`f[1]` = the two rates. The exact authored field names are not in the exe.
- **The entity class code `6`** in `FUN_004B7B50` — I did not identify which entity class that is, so I
  cannot say *which* objects the `Flammable` gate applies to.
- **Whether any shipped object actually carries a `Flammable` component** — `Flammable` appears in 1
  `vz.wad` block, which is consistent with the ECS schema/reflection block alone. I did not enumerate
  placements.
- **`0x381BE6A4`** — uncracked.
- **Runtime behaviour of the two gates `[0x017BBD30]`/`[0x017BBD34]`** — if they are zero in a retail
  session, ignition damage is silently zero. Not checked live.

---

## Phase B — verdicts

*(written after opening `docs/reverse_engineer/fire_ignition_code_map.md`)*

### Summary

| verdict | count |
|---|---:|
| **CONFIRMED** | 34 |
| **CONTRADICTED** | 3 |
| **MISSING** | 3 |
| **UNVERIFIABLE** (this pass) | 7 |
| **OVERSTATED** | 3 |
| **total falsifiable claims classified** | **50** |

**The premise holds.** There is no `Fire` Lua namespace; `0x00B9A7A8` is a nested `FuelTrail`
sub-table of `Graphics`, and all three cfuncs are dead. I walked those bytes independently before
reading the map and got the same answer, down to the marker addresses and the 95/75/3 counts.

This is an unusually accurate document. The three contradictions matter, though, and one of them
inverts a piece of reimpl guidance.

---

### CONTRADICTED

#### C1 — `Flammable` **does** have a statically visible reader, and it is in the fire path

> **Map** (§0.5 row, §2.4, §7.1, §8 item 1): "**`Flammable` consumer** — **none statically visible**…
> full-corpus scan: only the registrar, the schema and the stream-add helper `FUN_0063C690` touch
> `0x017BE258`". And §2.4: "`FUN_004B7B50` (the filter) is a **type filter, not a `Flammable`
> lookup** … That is the single most surprising finding in this section." And §0.5: "kind 6 requires
> a live world".

**This is wrong.** `FUN_004B7B50` is a type filter *whose kind-6 arm is exactly a `Flammable`
lookup*. The function dispatches through a jump table at `0x004B7B90` (targets) / `0x004B7B9C`
(index bytes); kind 6 lands on `0x004B7B77`:

```
004B7B77  mov  eax, [esp+4]          ; entity
004B7B7B  mov  ecx, 0x17BE258        ; <-- the Flammable component descriptor
004B7B80  call 0x005857E0            ; component fetch
004B7B85  neg eax ; sbb eax,eax ; neg eax   ; -> bool(component present)
004B7B8B  ret
```

So `0x017BE258` **is** referenced from `.text` at `0x004B7B7C`, a fourth site the map's scan missed.
Full decode of both tables:

| target | meaning | kinds |
|---|---|---|
| `0x004B7B74` | never burns | 5, 7, 9, 11, 12, 13, 15 |
| `0x004B7B8C` | always burns | 8, 10, 14, and `default` |
| `0x004B7B77` | **`Flammable` component test** | **6** |

**Root cause of the error**: Ghidra drops the `ecx` register argument and emits
`iVar2 = FUN_005857e0();` with no operand — the descriptor, and with it the entire `Flammable`
link, is absent from the decompiled text. This is trap #1, and it is the one the map's own §7.4
warns about for `FUN_004B7BB0` while missing it here. (Ghidra also under-sizes this function:
`size=63` against a real extent of `0x004B7B50–0x004B7BAF`, 96 B including its two tables.)

**Consequences.**
- §7.1's reimpl warning is **inverted**: "a reimpl that models 'fire spreads to things tagged
  `Flammable`' may be modelling something retail does not do" — retail *does* do exactly that, for
  one entity class. A reimpl that drops `Flammable` will over-burn that class.
- §8 item 1 ("Does anything read `Flammable`? HW-read watchpoint on `0x017BE258`") is **answered
  statically** and no longer needs a live session.
- §0.5's confidence for that row should go from **open** to **H**, and the `FUN_004B7B50` row's
  "kind 6 requires a live world" should read "kind 6 requires a `Flammable` component".
- §8 item 3 (name the kind constants) remains the right experiment — neither of us identified which
  entity class code 6 is.

#### C2 — there is no "cap of 8 live ignitors" on PC; every pool here is budgeted 256

> **Map** (§2.1): "**`RuntimeIgnitor 8 8`** — i.e. the world may hold hundreds of burnable things but
> only **eight** live ignition volumes at a time. That single number is the most useful capacity fact
> in this map." Repeated as reimpl guidance in §9: "cap **8 live** (Xbox pool budget)".

Read straight out of the PC registrars — the descriptor count fields `+0x0C`, `+0x28` and `+0x40`,
all set from `mov ecx, 0x100`:

| component | registrar | size | `+0x0C` | `+0x28` | `+0x40` |
|---|---|---:|---:|---:|---:|
| `Flammable` | `0x00643070` | 4 | **256** | **256** | **256** |
| `Ignitor` | `0x00643120` | 12 | **256** | **256** | **256** |
| `RuntimeIgnitor` | `0x00645650` | 28 | **256** | **256** | **256** |
| `TickDamage` | `0x00642EF0` | 16 | **256** | **256** | **256** |
| `RtTickDamage` | `0x00646AA0` | 16 | **256** | **256** | **256** |

The PC binary budgets `RuntimeIgnitor` at **256**, not 8. The `8` in `RuntimeIgnitor`'s registrar is
`mov edx, 8` written to `+0x08` and to the alignment word `+0x26` — the same `8` that appears as the
alignment of `Flammable`, `Ignitor`, `TickDamage` and `RtTickDamage`. So the Xbox line
`RuntimeIgnitor 8 8` most likely records size/alignment-class, not a live cap, and the map's reading
of it does not survive contact with the PC descriptors.

This matters because it is stated as the map's single most useful capacity fact and is handed
straight to a reimpl silo as a hard cap. A reimpl capped at 8 concurrent ignition volumes will
diverge from retail as soon as a ninth fire starts.

#### C3 — the first `Fire` literal is at `0x004B7F0D`, not `0x004B7F12`

> **Map** (§0.5 and §6.1): "code literal at `0x004B7F12` and `0x004B8212`".

`0x004B8212` is exact. `0x004B7F12` is not — the bytes there are `8B F0` (`mov esi, eax`). The
`push 0x8a552089` is at **`0x004B7F0D`**:

```
004B7F0D  68 89 20 55 8a     push  0x8a552089
004B7F12  8b f0              mov   esi, eax
004B7F14  e8 47 a4 17 00     call  0x632360
```

The map is internally inconsistent: §2.5 step 4 lists `0x004B7F0D push 0x8A552089` correctly, while
§0.5 and §6.1 both say `0x004B7F12`. The same ~+5/+6 slippage affects the two corroborating DamageKey
sites — §6.1 cites `ExplosionLarge` at `0x00630677` (the dword is at `0x00630671`) and `MeleeBash` at
`0x004CE301` (dword at `0x004CE2FB`). All three hashes and all three sites are **real**; only the
addresses are off by an instruction, which will cost time for anyone re-deriving them.

---

### MISSING

#### M1 — a **third** `Fire` code literal, and a hash the map could have cracked

`0x8A552089` occurs **three** times in `.text`, not two. The third is at `0x00693DEC`, inside
`FUN_00693D80` (306 B; Ghidra `callers=[]`, `void FUN_00693d80(void)`):

```
00693DE3  cmp dword ptr [eax+4], 0x787C0871    ; <- pandemic_hash_m2("Weapon")
00693DEA  jne skip
00693DEC  cmp dword ptr [eax+8], 0x8A552089    ; <- pandemic_hash_m2("Fire")
00693DF3  jne skip
00693DF5  push eax ; mov eax,[edi] ; push eax ; call 0x00693BB0
```

**`0x787C0871 = pandemic_hash_m2("Weapon")`**, cracked here by hashing all 164,070 printable tokens
harvested from the image. So there is a `(Weapon, Fire)`-keyed path outside the ignition applier that
the map does not account for. Given §10's argument that fire is filed under combat, a
`Weapon`/`Fire` keyed lookup is directly on-thesis and worth a section.

(`FUN_00693BB0`, the callee, is another Ghidra mis-size: `size=24` against a real
`0x00693BB0–0x00693CBB`, 268 B.)

#### M2 — the `0x006D5640` stub is **not readable** in the image the map cites

The map states the stub body as `xor eax,eax; ret` (§0.5, §1) and lists
`output/_ghidra/securom_dump/mercs2_unpacked.exe` as the raw-disassembly source for `0x006D5640`
(§11). In that file the VA holds five bytes:

```
006D5640  e9 7b ca 5f 6f     jmp 0x6FCD20C0     ; target outside the image — a SecuROM hook
```

The `xor eax,eax; ret` body is real, but it is only visible in the DRM-free rebuild
(`mercs2_nodrm_v3.exe`, `33 C0 C3` at the same VA — I verified byte-identity at `0x004B7BB0` and
`0x004B82D0` before trusting it). The map's conclusion is right; the provenance is not, and anyone
re-checking in the cited file will find a `jmp` and think the map is wrong. Worth one line.

Also unstated and useful: `0x006D5640` is not a fire-specific stub — **693 `.rdata` slots** point at
it, including `print`, `Debug.Printf`, `Debug.Assert`, `Debug.LogError`, `Atmosphere.SetSky`,
`ObjectState.PrintStateMachine`/`DebugStateMachine` and most of `Ai.Plan*`.

#### M3 — the zero-script-traffic claim can be made much stronger

§1 rests on a `corpus_calls` census over the **370 decompiled scripts** in `docs/mercs2-luacd/`.
That is a subset. Running `mercs2_probe --bin block_content_grep` over the shipped `vz.wad`
(decompresses all 11,370 blocks; `ok=11370 failed=0`) gives **0 blocks** containing `FuelTrail`,
`Ignite`, or `Extinguish`, against positive controls `Graphics` 2, `ObjectState` 1, `StartEmitter` 1,
`SendDamage` 1, `SetState` 5, `Atmosphere` 6, `Ignitor` 1, `Flammable` 1. Since Lua bytecode stores
field names as plain string constants, zero occurrences of `FuelTrail` means no script can even index
the sub-table. That upgrades "no decompiled script calls them" to "nothing in the shipped data can
reach them".

(Method warning worth recording: raw substring scanning of the `.wad` files is **invalid** — payloads
are compressed, and my first attempt returned 0 hits for every needle including `Graphics`.)

---

### OVERSTATED

#### O1 — `FUN_0066E650` is a *shared* producer, not an `Ignitor`-specific one

> **Map** (§0.5): "slot `+0x18` is the RuntimeIgnitor producer … it is not inferred from adjacency".

The vtable slot is genuinely `0x00BCD0B4 +0x18 = 0x0066E650` — confirmed by direct read, and the
marriage-by-slot reasoning is sound. But `0x0066E650` is *also* `ColorAnimation`'s handler slot
`+0x3C` (vtable `0x00BCD090`). It is a generic producer reused across classes, so the function
identity carries less information than the row implies. The claim should be about the **slot**, which
is what actually pins it.

#### O2 — §2.3 cites the wrong instruction for the one-shot byte

> **Map** (§2.3): "`+0x14` **one-shot 'already ignited something' byte** — `0x004B83E2` sets it after
> the first successful hit".

`0x004B83E2` is `mov byte ptr [esp+0x1b], 1` — a **stack** local, the `hitSomething` accumulator that
the map's own §2.4 pseudocode names correctly. The actual `ig->oneshot` member is read at
`0x004B8403` (`cmp byte ptr [ebx+0x14], 0; jne skip`). The field identification is right; the cited
address is not.

#### O3 — "the only code literal in the whole 27k-function decomp" is ambiguous

> **Map** (§6.2, on `0x381BE6A4`): "It is a **code literal** — the only one in the whole 27k-function
> decomp (`FUN_00683C40`, twice)".

Read as "the only occurrences of `0x381BE6A4` are these two", it is **correct** (I found exactly two
image-wide). Read as "the only destruction-state hash that appears as a code literal", it is wrong —
`GoneState` `0xCA261E5B` is a code literal in the very same four instructions, and is also the
comparand the sentence goes on to describe. Worth disambiguating since the whole argument in §6.2
turns on this being distinctive.

---

### CONFIRMED (34)

Grouped; every row was derived in Phase A before the map was opened.

**The premise and the table walk (7)**

1. **No `Fire` namespace.** Registry `0x00DFD478`, **31 rows**, **12-byte stride**, terminator
   `0x00DFD5EC` — all three numbers exact. No `Fire` entry among the 31.
2. `Graphics` is registry row `0x00DFD514` → table `0x00B9A4D0`; that pointer has exactly **one**
   referrer image-wide (the registry field itself).
3. `0x00B9A7A8` is inside a sub-table opened by `{"FuelTrail", 0xFFFFFFFF}` at **`0x00B9A7A0`** and
   closed by `{"FuelTrail", 0xFFFFFFFE}` at **`0x00B9A7C0`** — read from the bytes.
4. The blob runs to a zero terminator at **`0x00B9A7C8`**.
5. **95 rows / 75 callable / 3 stubs** — exact (I also counted 20 marker rows / 10 sub-tables, and
   the nesting balances to depth 0).
6. §1's per-sub-table breakdown is exact **entry for entry**: 11 top-level, Camera 7, Atmosphere 37,
   Bloom 7, MotionBlur 1, Contrast 2, Monochrome 1, Grainy 1, AA 1, Effect 4, FuelTrail 3 = 75.
7. The correct Lua path is `Graphics.FuelTrail.{Ignite, Extinguish, Put}`.

**The three dead cfuncs (5)**

8. `Ignite` → `0x006D5640`; `Extinguish` → `0x006D5640`.
9. That body is `xor eax, eax; ret` — a cfunc returning 0 results (verified in the DRM-free rebuild;
   see M2 for the provenance caveat).
10. Exactly **3** of the 75 `Graphics` rows use the stub: `Atmosphere.SetSky`, `FuelTrail.Ignite`,
    `FuelTrail.Extinguish`.
11. `Put` → `0x005B2A50`, **202 B**, and the success path at `0x005B2B14` is `xor eax,eax; ret` with
    **no engine call on any path**. §1's characterisation — validation prologue kept, body removed —
    is right, and the contrast with `ObjectState.StartEmitter` (`0x005D2FA0`, identical arg-parsing
    idiom and identical tail, but `call 0x004D28C0` on success) proves it was a deliberate strip.
12. `FUN_004B2A50` is the raise-helper (`mov ecx,[esi]; mov eax,1; call 0x85D5D0`), reached only from
    `Put`'s failure branches.

**Zero script traffic (1)**

13. Zero call sites — independently reconfirmed by a stronger method (M3).

**Components and the producer chain (7)**

14. `Ignitor`: container `0x017BE2A8`, stride **`0x0C`** (3 floats), registrar **`FUN_00643120`**.
15. `Flammable`: container `0x017BE258`, stride **`0x04`**, registrar **`FUN_00643070`**.
16. `RuntimeIgnitor`: container `0x017BF388`, stride **`0x1C`**, registrar **`FUN_00645650`**.
17. The class handler is minted at **`0x00670FC7`** with vtable **`0x00BCD0B4`** — §2.2's four-line
    disassembly excerpt matches my independent read instruction for instruction.
18. Vtable `0x00BCD0B4` slot **`+0x18` = `0x0066E650`** (direct vtable read).
19. `FUN_0066E650` reads the Ignitor payload (`mov ecx, 0x17BE2A8; call 0x005857E0`), builds a
    `centre ± r` AABB, calls `0x004058B0`, `0x006654B0`, `0x008DC7A0(0x2005, 1, 0)`, and inserts into
    container `0x017BF388` — every call in §0.5's row present and in order.
20. `RuntimeIgnitor` field map (§2.3) is correct including the easily-inverted part: `+0x00` = **rim**
    rate → `[ebp+0x18]`, `+0x04` = **centre** rate → `[ebp+0x1C]`, `+0x08` = radius → `[ebp+0x14]`,
    `+0x0C` = owner key, `+0x18` = broad-phase proxy. I reconstructed the callee frame from the push
    order independently and the falloff makes `[ebp+0x1C]` the `d = 0` value, which is what the map says.

**The tick and the damage math (8)**

21. `FUN_004B82D0` is dispatched from **`FUN_00675E50`** at **`0x00677219`**, walking the
    `RuntimeIgnitor` pool, with `dt` in `xmm0` (a register arg Ghidra drops).
22. `FUN_00675E50` really is a layer-4 `Rt*` pass: I counted **23** `Rt*`/`Runtime*` descriptors
    referenced inside `0x00675E50–0x0067725C`, including `RuntimeIgnitor` and `RtTickDamage`.
23. `FUN_004B82D0` bails on `dt <= 0`, scales both rate floats by `dt`, skips candidates matching the
    owner key, and calls `FUN_004B7B00` (proxy + result array) then `FUN_004B7B50` then `FUN_004B7BB0`.
24. **Ghidra is wrong about `FUN_004B7BB0` exactly as §7.4 says**: `size=664`, `void` return, and
    three recovered parameters against **eight** actual stack arguments at the single call site.
25. Real extent **`0x004B7BB0–0x004B82C2`**, **1811 B** — the map's figure is exact.
26. **Clamped-OBB distance**: point taken into box space, `andps` with `0x7FFFFFFF` (abs), half-extents
    subtracted, only positive (outside) components squared and accumulated, `FUN_00401740` = sqrt.
27. **Range gate** `if (d > r) return false` at `0x004B7E4F`–`0x004B7E58`.
28. **Linear falloff** — §2.5's formula `v = (rimRate − centreRate) / radius * dist + centreRate` is
    an exact transcription of `0x004B7E63`–`0x004B7E7C`, and equals `lerp(centreRate, rimRate, d/r)`
    with `dt` already folded into both endpoints by the caller.

**The DamageKey and the double post (4)**

29. `pandemic_hash_m2("Fire") == 0x8A552089` — recomputed. Literal at `0x004B8212` exact (see C3 for
    the other address).
30. The scale path `push hash; call 0x00632360; mov eax,[eax]; mulss; comiss [0x00B9B690]`, gated on
    `DAT_017BBD34 > 0 && DAT_017BBD30 > 0` — exact, including the observation that if the tunable
    table is not loaded the scale stays `0.0` and nothing is posted.
31. **Posted twice** via `FUN_00407B20` → `FUN_00406170`. My independent evidence for the
    primary/per-node split is the target descriptor: site 1 (`0x004B7F4B`) writes the
    `word 0xFFFF, word 0xFFFF, byte 0` no-node sentinel; site 2 (`0x004B8256`) writes a real node
    handle plus a node index word. §2.5 steps 5–6 are right.
32. **All 20 hash claims in the map verify exactly** against `pandemic_hash_m2` — `Ignitor`,
    `Flammable`, `RuntimeIgnitor`, `TickDamage`, `RtTickDamage`, `Fire`, `ExplosionLarge`,
    `MeleeBash`, `GoneState`, `FalloffState`, `PauseState`, `CollapseState`, `DetachState`,
    `DestroyedState`, `StartDestroyedState`, `DamagedState`, and the four disproof candidates
    `FireDebrisState`, `FireDestroyedState`, `CollapseFireState`, `DebrisState`. **Zero invented
    hashes** — the document's §Method pledge holds.

**Destruction, timers, emitters (2)**

33. `0x381BE6A4`: exactly **two** occurrences image-wide, both in `FUN_00683C40`
    (`0x00683C89`, `0x00683D11`), each immediately paired with a `GoneState` `0xCA261E5B` compare on
    the same value — §6.2's structural argument is sound. **Not cracked** by me either: I hashed all
    164,070 printable tokens from every section × 180 prefix/suffix combinations, no hit. The
    `Fire*`/`Debris*` disproof stands.
34. `TickDamage` stride **`0x10`** (registrar `FUN_00642EF0`); `RtTickDamage` stride **`0x10`**,
    registrar **`FUN_00646AA0`** writing `s_RtTickDamage_00BC5BBC`. `ObjectState` table `0x00B995B0`,
    **9 rows, 2 stubs**, all seven real addresses exact (`0x005D2AE0`, `0x005D2BE0`, `0x005D2CE0`,
    `0x005D2DE0`, `0x005D2FA0`, `0x005D3090`, `0x005D3180`). `StartEmitter` `0x005D2FA0` →
    `FUN_004D28C0`, whose call sequence in §4.2 (`0x00649440`, `0x00672F60`, `0x00688970`,
    `0x008231D0`, `0x006746D0`, `0x00649180`, `0x0048B470`) matches my disassembly **exactly and in
    order**. `FUN_004D4680` is a split thunk `jmp dword ptr [0x0245A004]` as stated. All 16 cited
    `.rdata` string addresses (§5, §7.2, §6.1's `Falloff` counter-argument) resolve to exactly the
    strings claimed.

---

### UNVERIFIABLE this pass (7) — and what would settle each

| # | Claim | Why not settled | What would settle it |
|---|---|---|---|
| U1 | Every **Xbox-oracle** row: `UpdateIgnitor @0x0041234`, `Flammable 256`, `Ignitor 96 32`, `RuntimeIgnitor 8 8`, `RtTickDamage 16 16`, `TickDamage @0x829f1e90`, `ApplyDamageToPrimaryHealth/NodeHealth` | I did not open the Jul-08 dumps or the PDB analysis — deliberately, to keep the PC derivation independent | Read `output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt` and `docs/mercs2-pdb-analysis/weapons-combat.md`. **Note C2**: whatever the Xbox line says, the PC descriptors say 256 |
| U2 | `FUN_00688970` resolves a **hardpoint** transform | Its entry is a SecuROM thunk (`jmp dword ptr [0x02459260]`); the real body at `0x00688980` walks an indexed node array (`[esi+0x50]` count, `[esi+0x4C][i]`, `[eax+0x4C]` → `[ecx+0x20]`) — consistent with a node lookup, but the *hardpoint* naming is not in the binary | One-shot bp at `0x00688980` with a known `hp_fx_exhaust_a` hash in arg 2; read the returned transform |
| U3 | `FUN_004D4680` = `RtStateMachine::GetState(node)` | Body stolen by SecuROM in **both** available dumps. The *role* is confirmed (its result is compared against state hashes); the identity is not | The map's §8 item 4: one-shot bp, single-step through `[0x0245A004]` |
| U4 | `0x28825D4C = PauseState` is a **state**, not a node | Rests on `oilrig.lua` comparing `Sys.GuidToString(uiStateHashName)`. No greppable Lua corpus on disk — I could not read it. Hash arithmetic ✓ | Re-extract `oilrig.lua` and read the `OnStateChange` comparison. Weak corroboration: `0x28825D4C` and `0x694683EB` both appear in `docs/data/bone_name_candidates.txt`, so both values exist somewhere in game data |
| U5 | `0xCE603754 = FalloffState` (rated **M**) | **The M rating is if anything generous.** The value occurs **nowhere** — not in the exe, and not in the project's uncracked-hash harvest. There is no known occurrence for the crack to explain. The map's own counter-argument (the retail `Falloff` tokens sit in a shader/material cluster) is corroborated: `Falloff` @`0x00BCA4C0` and `state_falloff` @`0x00BCA4B0` both verified exact | The map's own §8 item 5 is the right test: `--states` on a real model and read what the state hashing to `0xCE603754` does. Until then this should arguably be **L**, not M |
| U6 | §3's `RtTickDamage` tick body at `0x00676881`–`0x00676950` and its `{key, interval, acc, u32}` layout | I confirmed `RtTickDamage` is one of the 23 pools driven by `FUN_00675E50` but did not read that specific range | Disassemble `0x00676881`–`0x00676950` |
| U7 | §4.3 `FUN_004F4340` drain · §5 `DebrisEffect` schema internals · §9's four claims about `mercs2_script/src/bindings/fire.rs` and `graphics.rs` | Out of scope for this pass | Read those bodies / that source tree |

---

### The silo recommendation (§10)

**Sound, and finding C1 strengthens it.** Of the eight evidence lines, I verified 1–4 directly:

- **line 1** — `FUN_004B82D0` contains no particle call. Its callees are `0x00648D80`, `0x00665AF0`,
  `0x004B7B00`, `0x004B7B50`, `0x004B7BB0`, `0x00505420`, `0x004B7A60` — an overlap query, a filter,
  a damage applier, and a one-shot cue. Correct.
- **line 2** — `FUN_00407B20` → `FUN_00406170` are the post pair, and both also appear in
  `FUN_00675E50`'s own call set, consistent with a shared damage bus. Correct.
- **line 3** — `Fire` is resolved by the same `FUN_00632360` that takes `ExplosionLarge` and
  `MeleeBash`; both corroborating hashes verified and both literal sites exist. Correct.
- **line 4** — the double post really is primary-health + per-node (the `0xFFFF` sentinel vs a real
  node handle). Correct.

Lines 5, 6 and 8 rest on the Xbox oracle and sibling maps (U1) and I did not check them; they are
supporting, not load-bearing. **C1 adds a ninth line**: `Flammable`, a gameplay component, is read
inside the ignition filter — one more reason the system belongs to combat rather than FX.

The §10 conclusion stands.

---

### What I could not check at all

Beyond U1–U7: the identity of entity-class code **6** in `FUN_004B7B50` (so I cannot say *which*
objects the `Flammable` gate covers); whether any shipped object actually carries a `Flammable`
component (`Flammable` appears in exactly 1 `vz.wad` block, consistent with the ECS schema block
alone — I did not enumerate placements); the authored field names behind `Ignitor`'s three floats;
`0x381BE6A4`'s name; and the runtime values of the two gates `[0x017BBD30]` / `[0x017BBD34]` — if
those are zero in a retail session, ignition damage is silently zero and everything in §2.5 step 4
onward never fires. That last one is not in the map's confirm-live list and probably should be.


---

# Pass 2

- **Date**: 2026-07-26
- **Charter**: close every item Pass 1 did not explicitly CONFIRM — 3 CONTRADICTED, 3 OVERSTATED,
  7 UNVERIFIABLE (U1–U7), 3 MISSING — plus its "What I could not check at all". Pass 1's verdicts
  are treated as **untrusted claims**, re-derived from primary sources, exactly like the map's.
- **Two of Pass 1's blockers were false and are lifted**: the Lua corpus *is* on disk
  (`docs/mercs2-luacd/`, 370 files incl. `src/resident/oilrig.lua`), and the Jul-08 / PDB dumps were
  read this pass.
- **Primary sources added over Pass 1**: the `.securom` and `Stext` sections of
  `output/_ghidra/securom_dump/mercs2_unpacked.exe` (a **live memory dump**, so indirect slots are
  already resolved and the ECS descriptor tables are already populated);
  `output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt`; `docs/mercs2-luacd/`;
  `docs/destruction_orchestrator_format.md`; `cargo run -p mercs2_workshop -- --states` against the
  real `vz.wad`; `tools/pandemic_hash.py --m2`.

## P2.0 — Scoreboard

| Pass-1 item | Pass-2 verdict |
|---|---|
| C1 `Flammable` reader exists | **CONFIRMED** (Pass 1 right, map wrong) |
| C2 "no cap of 8; all pools budgeted 256" | **BOTH WRONG** — see P2.1, the biggest single correction this pass |
| C3 `0x004B7F0D` not `0x004B7F12` | **CONFIRMED** (Pass 1 right) |
| O1 `FUN_0066E650` is a *shared* producer | **CONTRADICTED** (Pass 1 wrong, map right) |
| O2 `0x004B83E2` is a stack local | **CONFIRMED** (Pass 1 right) |
| O3 "only code literal" ambiguous | **MOOT** — superseded, `0x381BE6A4` is now cracked |
| M1 third `Fire` literal + `Weapon` | **CONFIRMED**, and now **explained** (P2.3) |
| M2 stub unreadable in the cited image | **CONFIRMED** |
| M3 stronger zero-traffic proof | **CONFIRMED**, and strengthened again from the Lua side |
| U1 Xbox-oracle rows | **CLOSED** — and their *provenance* is wrong in the map (P2.1) |
| U2 `FUN_00688970` "hardpoint" | **CLOSED** — "Hardpoint" **is** in the binary (P2.5) |
| U3 `FUN_004D4680` = `GetState` | **STILL-OPEN**, with static exhaustion demonstrated (P2.6) |
| U4 `0x28825D4C` is a state | **CLOSED** — state, not node (P2.7) |
| U5 `0xCE603754 = FalloffState` → L or withdrawn? | **NEITHER** — keep **M**, upgraded by shipped data (P2.8) |
| U6 `RtTickDamage` tick body | **CLOSED**, with one correction (P2.9) |
| U7 `FUN_004F4340` / `DebrisEffect` / reimpl source | **CLOSED** (P2.10) |
| entity class **6** | **CLOSED** — buildings (P2.4) |
| `Ignitor`'s authored field names | **CLOSED** — `{Radius, MinDamage, MaxDamage}` (P2.2) |
| `0x381BE6A4` | **CRACKED — `DanglingState`** (P2.8) |
| writers of `[0x017BBD30]`/`[0x017BBD34]` | **CLOSED** statically (P2.3) |
| `Flammable` placements in `vz.wad` | **CLOSED — zero placements** (P2.14) |

Net: **22 of 22 open items closed** (see P2.14); one (U3) is STILL-OPEN with proof that no static
route exists, and one sub-item (the *live* values of `[0x017BBD30]`/`[0x017BBD34]`) is live-only.

---

## P2.1 — C2 / U1: the pool numbers are a **`[presize]` config section**, present in the PC retail image

Both the map and Pass 1 are wrong, for the same underlying reason: neither looked at where the
numbers come from.

**The map** reads `RuntimeIgnitor 8 8` as a hard cap ("only **eight** live ignition volumes at a
time … the most useful capacity fact in this map", §2.1, repeated as reimpl guidance in §9).

**Pass 1 (C2)** replies that "the PC binary budgets `RuntimeIgnitor` at **256**", read from the
registrars' `+0x0C`/`+0x28`/`+0x40` fields, all `mov ecx, 0x100`.

Both fail:

**(a) `0x100` is a universal constant, not a budget.** I found all **334** call sites of the shared
registrar tail `FUN_0064A770`, walked back to each function's `or eax, 0xffffffff` prologue, and
extracted the `mov ecx, imm32`. **All 232 parsed registrars — 220 of them name-resolvable — write
`0x100`, with zero exceptions.** That includes components the config gives wildly different numbers:
`Health` (3328), `RuntimeHealth` (1280), `DamageKey` (1280), `RtVFX` (768 256). A field that is
`0x100` for every component in the game is a default, and Pass 1's C2 inference does not survive it.

**(b) The numbers are a config INI, and the PC image carries it verbatim.** The Xbox "pool-budget
table" is not a symbol dump — it is the section **`[presize]`** of the game's embedded config file,
sitting between `[framerate]`/`[massive]`/`[achievements]` and **`[pcwin_Memory]`** (`MainHeap 247M`,
`SmallBlockPage 32K`, …). The same block is in retail PC `mercs2_unpacked.exe` at file offset
`0x7AD499`, and the fire rows are **byte-identical**:

```
[presize]      (PC retail image, .rdata @ ~0x00BAD499)
 Flammable 256            Ignitor 96 32           RuntimeIgnitor 8 8
 TickDamage 1024          RtTickDamage 16 16      DebrisEffect 4608
 RuntimeDebrisEffect 8 8  Health 3328             DamageKey 1280
```

**Consequences.**
- The map's §11 provenance ("Xbox oracle … the `Flammable 256` / `Ignitor 96 32` / … pool-budget
  lines") is **wrong**: these are not an Xbox-only artefact. They are PC retail config. Every one of
  U1's Xbox-oracle rows is therefore CLOSED, and *stronger* than the map claimed.
- The map's reading of `8` as a **cap** is unsupported: `[presize]` is a **presize/grow hint** to a
  paged pool allocator (the registrar writes a default `0x100` element page size; the config
  pre-reserves). The two-number form is `<presize> <grow>`; the one-number form omits the grow.
  Nothing in either the config or the registrars establishes a maximum.
- **The reimpl guidance in §9 — "cap 8 live (Xbox pool budget)" — should be deleted, not merely
  re-numbered to 256.** A reimpl should not cap ignitors at all; 8 is a reservation hint.

Also confirmed this pass from the Xbox dump: `UpdateIgnitor` (line 7281), `ApplyDamageToNodeHealth`
(3015), `ApplyDamageToPrimaryHealth` (3017), and `TickDamage 1024` — note the map cites `TickDamage`
only via the PDB (`@0x829f1e90`, 16 B) and never mentions its presize row.

---

## P2.2 — The master key, applied twice: **334 containers named, and the authored field names recovered**

**Key 1 — container names (`[vtable+0x34]`).** The mechanism is not just a convention, it is in the
engine's own code: `0x0064A7E0` iterates the descriptor tables at `0x00EDBEC8` (218 entries) and
`0x00EDBAC8` (116) and calls `[[desc]+0x34]` on each to get a `char*`. Because the image is a live
memory dump those tables are **already populated**, so all **334** containers can be named in one
pass. (The same function then FNV-1a-hashes the name with `or 0x20` + `xor 0x2A` + prime — the engine's
own `pandemic_hash_m2`, in situ — and stores it at `desc+0x10`.)

**Four names the map states wrongly or leaves bare:**

| VA | map says | **actually (master key)** |
|---|---|---|
| `0x00DF9110` | "the per-object live-emitter component" (§4.2) | **`RuntimePhysicalLink`** |
| `0x00DF9310` | "the destruction map's runtime state-machine POOL" (§4.4) | **`RuntimeModelState`** |
| `0x00DF8B10` | "per-object FX scale component" (§4.2) | **`OSMParameter`** |
| `0x00DF8690` | not mentioned | **`ModifierKey`** — the missing half of the damage lookup (P2.3) |

`0x00DF9310` is a *naming* correction rather than a refutation: `state_machine_destruction_code_map.md:84`
does describe `&PTR_PTR_00df9310` as the "Runtime state-machine instance pool" (so the fire map cites
its sibling accurately), but neither map knew the engine's own name for it. `RuntimeModelState` in
fact **strengthens** the `GetState` reading — the shipped state machines do nothing but `Show`/`Hide`
HIER meshes per state (P2.8), which is precisely a *model state*.

Confirmed unchanged: `0x017BE258` = `Flammable`, `0x017BE2A8` = `Ignitor`, `0x017BF388` =
`RuntimeIgnitor`, `0x017BE1B8` = `TickDamage`, `0x017BFBF8` = `RtTickDamage`, `0x00DF8910` =
`DebrisEffect`. `0x00DF9160` (the `FUN_004B82D0` owner-key lookup) is **not** a container base — it
is `RuntimePhysicalLink + 0x50`, an interior field.

**Key 2 — authored field names (`mov edx, <char*>` in the schema functions).** This is Ghidra trap #1
again: the schema readers `FUN_00656210` (int) / `FUN_00656320` (float) / `FUN_00656720` (enum) take
the **field name in `edx`**, which Ghidra drops entirely. Reading it back:

```
Ignitor      FUN_006627A0 : float Radius ; float MinDamage ; float MaxDamage
Flammable    FUN_00662720 : (no fields — pure marker)          [map correct]
TickDamage   FUN_00661CB0 : int DamageThresh=0 ; float Damage ; float TickLength ;
                            int NodeName = 0x765CD254
DebrisEffect FUN_006625E0 : int Name, EffectName, Hardpoint, Template, MinChunks=1, MaxChunks=1 ;
                            float MinChunkVel=1, MaxChunkVel=1, MinChunkVel=1, MaxChunkVel=1 ;
                            enum Trail(ChunkTrailEnum) ; enum Type(DebrisTypeEnum)
```

This closes "the authored field names behind `Ignitor`'s three floats" — an item both passes listed
as unreachable — **and it corrects the map**:

- **`Ignitor` is `{Radius, MinDamage, MaxDamage}`, in that order.** The runtime `RuntimeIgnitor` is
  `{rim@+0x00, centre@+0x04, radius@+0x08}`. So §2.3's "the producer copies them straight through"
  is **wrong — the producer rotates the fields**. Verified in `FUN_0066E650`: `movss xmm0,[ebx]`
  reads authored **field 0** and uses it as the AABB half-extent, i.e. field 0 is the radius, while
  at runtime the radius lives at `+0x08`. The *meanings* the map assigns are right (rim = `MinDamage`,
  centre = `MaxDamage`, which is exactly what a `lerp(centre, rim, d/r)` falloff should be); the
  "straight through" claim is not.
- `TickDamage`'s two floats are `Damage` and `TickLength` — the map's parenthetical guess
  *"(amount, interval)"* is **right**, but its main sentence ("the damage magnitude is carried in the
  descriptor, not the timer") is **wrong**; see P2.9.
- §5's `DebrisEffect` count — "6 ints, 4 floats, then two enums" — is **exactly right**. Minor: the
  two enum *fields* are named `Trail` and `Type`; `ChunkTrail`/`DebrisType` are the enum *type* names.

---

## P2.3 — `FUN_00632360` recovered in full: it is a **2-D `ModifierKey` × `DamageKey` matrix**

SecuROM is not a blocker. `FUN_00632360` = `jmp [0x0245DE08]`; `[0x0245DE08] = 0x02FB0000`, and that
target is **clean x86**, 127 bytes, fully readable:

```c
float* FUN_00632360(u32 modifierKey /*ESI — a register arg Ghidra drops*/,
                    u32 damageKey   /*stack, ret 4*/)
{
    nRows = [0x017BBD30];                         // ModifierKey axis length
    row = 0; for (i<nRows) if (rowKeys[i]==modifierKey) { row=i; break; }
    nCols = [0x017BBD34];                         // DamageKey axis length
    col = 0; for (i<nCols) if (colKeys[i]==damageKey)  { col=i; break; }
    return &((float*)[0x017BBD48])[ nCols*row + col ];
}
```

The record at `0x017BBD30` is `{ u32 nRows@+00, u32 nCols@+04, u32* rowKeys@+08, u32* colKeys@+10,
float* matrix@+18 }`, and its initialiser is `0x006322A0` (zeroes the struct, installs vtable
`0x00BBD06C` at `0x017BBD2C`); the accessors are `0x00632420`–`0x00632717`. **That closes "find the
writers of `[0x017BBD30]`/`[0x017BBD34]` statically".** (`rowKeys` is reached through a SecuROM
split-constant: `[0x0245A5C8] + [0x0074405F] = 0xA7EF9739 + 0x598C25FF = 0x1_017BBD38`, truncating to
`0x017BBD38`.)

**The row axis is `ModifierKey`.** At every DamageKey call site the pattern is byte-identical —
verified at the `Fire` site `0x004B7EDD` and the `ExplosionLarge` site `0x00630640`:

```asm
mov  eax, 0xdf8690        ; ModifierKey container
call 0x649440             ; component fetch on the TARGET
mov  esi, [eax+4]         ; row key   (0 if the target has no ModifierKey)
push 0x8a552089           ; column key = pandemic_hash_m2("Fire")
call 0x632360
```

So fire damage is scaled by a **`ModifierKey` × `DamageKey` matrix** — a damage-type × target-class
multiplier table — not by a one-dimensional "DamageKey tunable" as §0.5/§2.5 describe. This is a
material addition for a reimpl: the scale depends on *what is being burned*, not only on the fact
that it is fire.

**Both the map and Pass 1 A6 are right that the call sites gate on the counts**, and I confirm the
mechanism precisely: `xorps xmm0,xmm0; movss [esp+0x10],xmm0` runs *before* the branch, so when
either count is zero the scale stays `0.0`, the `comiss` against `[0x00B9B690]` fails, and nothing is
posted. **Runtime values**: in this dump `[0x017BBD30] = [0x017BBD34] = [0x017BBD48] = 0` — but the
dump was taken before the tunables loaded, so this is *not* evidence about a live session. That one
sub-item remains genuinely live-only, and Pass 1 is right that it belongs in the map's §8.

**M1 in this light.** `0x00693DEC`'s `cmp [eax+4], 0x787C0871 ("Weapon"); cmp [eax+8], 0x8A552089
("Fire")` is a scan over two-key records. Given that the engine keys damage on *pairs*, a
`(Weapon, Fire)` record is on-thesis, and Pass 1's crack of `0x787C0871 = Weapon` is confirmed
(`pandemic_hash_m2` recomputed). I did **not** establish that `FUN_00693D80` reads the same table as
`FUN_00632360`, and I do not claim it.

---

## P2.4 — Entity class **6** is a **building**

`FUN_004B7B50` re-derived independently from the raw bytes; Pass 1's C1 decode is exact:

```
jump targets @0x004B7B90 : 004B7B74 (never) | 004B7B77 (Flammable test) | 004B7B8C (always)
index bytes  @0x004B7B9C : [0,1,0,2,0,2,0,0,0,2,0]   for kind-5 .. kind-15
never  : 5, 7, 9, 11, 12, 13, 15        always : 8, 10, 14, default(<5 or >15)
Flammable-gated : 6 only
```

To identify the kinds I found every `mov eax,<k>; ret` stub, located the `.rdata` slots pointing at
them, treated `slot − 0xE0` as the vtable base (the object-kind vcall is `[vtable+0xE0]`), and read
the ECS descriptors each vtable's constructor touches, naming them with the master key:

| kind | ignition | component the ctor reads | reading |
|---:|---|---|---|
| 3 | always (default) | `PhysicsActor` | generic physics object |
| 4 | always (default) | `ModelName` | plain model object |
| **6** | **`Flammable` gate** | **`_BuildingPhysics`** | **building** |
| 8 | always | `_JetPhysics`, `ModelName` | aircraft |
| 10 | always | `_BoatPhysics` | boat |
| 14 | always | `_DebrisPhysics` | debris chunk |
| 15 | never | `LowResTerrainObject`, `PhysicsActor` | terrain — sanity anchor |

**So the `Flammable` gate covers buildings, and only buildings.** Everything else that burns burns
unconditionally; terrain never burns. Kinds 5, 7, 9, 11, 12, 13 have kind-stub vtables but no
descriptor reference in their constructors, so they stay unnamed — an honest partial. (The game
compiles without RTTI for its own classes — only Havok/ATL/std type descriptors exist — so there is
no name to read.)

This is exactly the shape a designer would ship: a burning car is always a burning car, but a
building burns only if the artist tagged it. It also sharpens C1's reimpl consequence: a reimpl that
drops `Flammable` will over-burn **buildings** specifically.

---

## P2.5 — U2 CLOSED: "Hardpoint" **is** in the binary, and the two routes reconcile

Pass 1: *"the 'hardpoint' name is not established from the binary."* It is. The string
**`"Hardpoint"` lives at `0x00BC7760`** and is the authored name of `DebrisEffect`'s third field
(P2.2), sitting directly beside `EffectName` and `Template` — the same (hardpoint, effect) pair that
`FUN_004D28C0` takes. The engine's own vocabulary calls it a hardpoint.

**Reconciling the two routes.** The map says `FUN_00688970` is a split thunk; Pass 1 says the real
body is at `0x00688980`. **The map is right and Pass 1 is wrong.** `0x00688970` is a *thunk block*:

```
00688970  ff 25 60 92 45 02   jmp [0x02459260]      <- FUN_00688970's thunk (6 B)
00688976  e9 40 91 d7 ff      jmp 0x401abb          <- a different function's thunk (5 B)
0068897B  e9 d9 e6 d7 ff      jmp 0x407059          <- another (5 B)
00688980  53 8b 5c 24 08 …    push ebx; …           <- the NEXT function, not a body
```

Three consecutive thunks, `int3`-padded before, ending exactly at `0x00688980`. Following the map's
slot: `[0x02459260] = 0x024EFE00`, whose body is a SecuROM trampoline
(`push ret; push 0x404AEA; push 0x1ABB574; pushfd; sub [esp+4],0xB664; popfd; ret`) that computes
`0x1ABB574 − 0xB664 = 0x01AAFF10` — the VM entry. So `FUN_00688970` is genuinely virtualized.

The call site nevertheless pins the signature, including the two register args Ghidra drops:

```asm
004D292A  mov ecx,[ebp+0xc]   ; hardpoint/node hash -> the one stack arg
004D292E  mov eax, esi        ; guid                -> EAX
004D2930  lea edi,[esp+0x74]  ; &out transform      -> EDI
004D2934  call 0x688970       ; -> bool
```

**Verdict: the map's semantic claim (resolve a hardpoint hash to a world transform) is CONFIRMED**;
its 3-arg cdecl notation is cosmetic shorthand for `(EAX=guid, EDI=&xform, stack=hash)`.

One real refinement, from the Lua corpus: the parameter is a **HIER node-name hash in general**, of
which `hp_*` is the FX-authoring convention. `moonpatrol.lua` passes
`String.GetHash("hp_fx_exhaust_a")`, but `fueltank.lua:6,17` passes the destruction machine's
`uiNodeHashName` straight through, and `mrxsupportdesignatorsmoke.lua:61` passes a bare
`StringToGuid("0x16516bb1")`. The shipped destruction data confirms the same slot resolves both:
the HMMWV's `StartDestroyedState` script contains `StopEmitter(0x06A262B1, HIER:hp_fx_exhaust_a)`.

(Also worth noting: the map cites `moonpatrol.lua` **and** `spyhunter.lua` for `hp_fx_exhaust_a/_b`.
`moonpatrol.lua:79-93` is verbatim correct; `spyhunter.lua` uses **`hp_fx_jetexhaust`** exclusively
at all 12 of its sites. And `StartEmitter` has **24** call sites in the Lua corpus, not 14 — the 14
counts only syntactic calls and drops the 10 `fn = ObjectState.StartEmitter` deferred dispatches in
`oilrig.lua`. `StopEmitter` = 14 is exact.)

---

## P2.6 — U3 STILL-OPEN, with static exhaustion demonstrated

`FUN_004D4680` is the one item this pass could not close, and the chain is followed to the end:

```
FUN_004D4680 = jmp [0x0245A004]
[0x0245A004]  = 0x024E2F00        -> push 0x24E2F0A ; call 0x01AAFF10     (VM stub)
0x01AAFF10    = jmp [0x021FD554]
[0x021FD554]  = 0x02A30000        -> pushal; pushfd; call/call; lock dec …
```

`0x02A30000` is the SecuROM VM interpreter, and it announces itself: the bytes at `0x02A30002`
read **`"You Are Now Entering a Restricted Area"`**. The body is **virtualized**, not merely
relocated — dereferencing recovers a bytecode dispatcher, not x86. (Contrast the two functions that
*did* deref to clean code this pass: `FUN_00632360` → `0x02FB0000`, and the prompt's worked example
`FUN_0068CC00` → `0x031C0000`.) `mercs2_nodrm_v1/v2/v3.exe` do not restore it either.

**Role, restated more precisely than either document.** `FUN_004D4680` has exactly **4** call sites
image-wide, all in `FUN_00683C40` (`0x00683C83/8F/D0B/D17`), all against the pool `0x00DF9310` =
**`RuntimeModelState`**, all comparing the result to state-name hashes. So it returns a state hash
out of the runtime model-state machine. The shipped state machines (P2.8) do nothing but `Show`/`Hide`
HIER meshes per state, which is exactly a *model state* — so `RuntimeModelState::GetState(node)` is
better supported than the map's `RtStateMachine::GetState(node)`, and rests on a real container name
rather than on a sibling map's prose.

**Runtime recipe** (unchanged from the map's §8 item 4, and still correct): one-shot bp at
`0x004D4680`, single-step through `[0x0245A004]`; read `EAX` on return against a model whose states
are known from `--states`. Read-only while PAUSED; the USER drives execution.

---

## P2.7 — U4 CLOSED: `0x28825D4C` is compared against the **state** argument

`docs/mercs2-luacd/src/resident/oilrig.lua:32-45`, verbatim:

```lua
function OnStateChange(uiGuid, uiNodeHashName, uiStateHashName)
  local sStateHashName = Sys.GuidToString(uiStateHashName)
  if sStateHashName == "0x28825D4C" then
    local sLayer = tTGLayers[Sys.GuidToString(uiGuid)]
    MrxLayerManager.Remove(sLayer .. "_tg")
    Sound.CueSound(uiGuid, "seq_oilrig_destruction")
    Camera.Shake(StringToGuid("0x1"), "ShakeCameraConstantlyRandom", uiGuid, 0.5, 2000)
    local e = Event.Create(Event.TimerRelative, {2.5}, _DestroyOilrigSequence, {uiGuid, uiNodeHashName})
  elseif sStateHashName == "0x694683EB" then
    Sound.CueSound(uiGuid, "sfx_amb_oilrig_destruction")
    Camera.Shake(StringToGuid("0x1"), "ShakeCameraConstantlyRandom", uiGuid, 1.2, 2000)
  end
end
```

**The map is right and `state_machine_destruction_code_map.md:406` ("`0x28825D4C` | node | oilrig
destruction node … needs the model's HIER dump") is wrong.** It is stringified from
`uiStateHashName`; `uiNodeHashName` is never compared in this file, only forwarded. The map's
description of the handler (cue `seq_oilrig_destruction`, camera shake, `_DestroyOilrigSequence`
at +2.5 s) is accurate.

Two additions the map misses: the branch also does a layer swap
`MrxLayerManager.Remove(sLayer .. "_tg")` keyed by the rig's own GUID; and `0x694683EB` is **not**
oilrig-specific — `islandfortress.lua:54` matches the same state gated on node `0xCF37044A`.
`pandemic_hash_m2("CollapseState") == 0x694683EB` is corroborated in the same file family by
`oilrig.lua:314` calling `String.GetHash("CollapseState")`.

**What is *not* closed**: that the name is `PauseState`. The Lua pins the **role** (a state) to **H**;
the name is still pure hash arithmetic with no occurrence of the string `PauseState` as an object
state anywhere in the exe or the 370-script corpus (the corpus hits are `MrxSound.EnterPauseState()`
audio calls — unrelated). **M is the right rating for the name; H for the role.**

---

## P2.8 — U5 verdict, and **`0x381BE6A4` is cracked: `DanglingState`**

**Pass 1's premise for downgrading `FalloffState` to L is false.** Pass 1 wrote: *"The value occurs
nowhere — not in the exe, and not in the project's uncracked-hash harvest. There is no known
occurrence for the crack to explain."* It occurs in **shipped game data**:
`docs/destruction_orchestrator_format.md:81` lists `0xCE603754` among the destruction state-name
hashes, and I dumped it out of the real `vz.wad`. Pass 1 searched the exe and one harvest file and
generalised.

I ran the map's own settling test (§8 item 5):
`cargo run -p mercs2_workshop -- --states 0xAC990539` against
`MERCS2_VZ_WAD=…/Mercenaries 2 World in Flames/data/vz.wad` →
`al_veh_truck_hmmwv_avenger`, 90 HIER nodes, 25 switch slots, 11 nodes.

First, the command vocabulary cracked cleanly (all `pandemic_hash_m2`, verified with
`tools/pandemic_hash.py --m2`, none invented):

| hash | name | hash | name |
|---|---|---|---|
| `0x9B31491A` | `SetState` | `0xE1142510` | `SetStateOnMsg` |
| `0x9228E8A2` | `Show` | `0x07EAD185` | `Hide` |
| `0x3347914F` | **`StartEmitter`** | `0x687C78C5` | **`StopEmitter`** |
| `0xC6E8AFA8` | `CreateObject` | `0x6A5C2678` | `PropTemplate` |
| `0x842AE03E` | `DisableConstraint` | `0xC20AB66F` | `SetRootNode` |
| `0x28B83DF1` | `PushLink` | `0x6FDAC686` | `BreakLink` |
| `0xEA0AB8C9` | `Kill` | `0x1ED7AD78` | `DestroyMsg` |
| `0xC6507EE1` | `DamageMsg` | `0x0ACE072A` | `InitState` |
| `0xACB51200` | `PristineState` | | |

`StartEmitter`/`StopEmitter` are a can't-coincide anchor: `DamagedState`'s **enter** starts emitter
`0xC6666A25` on three nodes and its **exit** stops *the same* emitter on *the same* three nodes.

Now the decisive part. The HMMWV has two parallel state vocabularies — a **named** one on the body
node `0x765CD254`, and an **unnamed** one on the three panel nodes (`0x2CE53661`, `0x3DF5A3EF`,
`0x962C4871`). Aligned, with identical `SetStateOnMsg` wiring:

| body node (named) | panel node (unnamed) | role |
|---|---|---|
| `0xACB51200` `PristineState` | `0xACB51200` `PristineState` | shared |
| `0x1D5575A1` `DamagedState` | **`0x381BE6A4`** | on `DamageMsg` — shows the damaged mesh, still attached |
| `0x92791EBB` `StartDestroyedState` | **`0xCE603754`** | on `DestroyMsg` — the transition that spawns the piece |
| `0x7687DF41` `DestroyedState` | `0xCA261E5B` `GoneState` | terminal |

The panel scripts, decoded:

```
state 0x381BE6A4  enter: Show(HIER:0x2FD85212); SetStateOnMsg(0, DamageMsg, node)
                  exit : Hide(HIER:0x2FD85212); DisableConstraint(node)
state 0xCE603754  enter: SetStateOnMsg(0, DestroyMsg, node); SetStateOnMsg(0, 0x3D0D4C99, node);
                         CreateObject(1, HIER:0x2FD85212, PropTemplate, DetachState, node);
                         SetState(GoneState, node)
state 0xA530B827  DetachState  enter: SetRootNode(node); Show(HIER:0x2FD85212)
```

`0xCE603754`'s entire job is to **spawn the panel as a detached physics prop and then vanish** — a
panel that falls off. It is entered from `0x381BE6A4`, whose exit releases the constraint. The
sibling state is literally `DetachState`.

**Cracking `0x381BE6A4`.** With the semantic slot now known (the damaged-but-still-attached state of
a detachable panel), a targeted 121 986-candidate sweep over `{prefix} × {damage/attachment cores} ×
{State, Msg, Command, …}` returns **exactly one** hit:

> **`pandemic_hash_m2("DanglingState") == 0x381BE6A4`** — verified with `tools/pandemic_hash.py --m2`.

The vocabulary reads **`Pristine → Dangling → Falloff → Detach → Gone`**. A panel takes damage and
**dangles**; it then **falls off**, spawning itself as a prop that enters **`DetachState`**; the
original node goes **`Gone`**. Expected false positives across the sweep ≈ 122 000 / 2³² ≈ 3 × 10⁻⁵,
and the hit lands in precisely the slot the data demands.

**Verdicts.**
- **`0x381BE6A4` = `DanglingState` — H.** It is cracked, and it also **contradicts the map's §6.2
  semantic reading**: the map argues it is "a post-destruction terminal sibling of `GoneState`",
  meaning "this object is finished". It is nothing of the sort — it is a **mid-life damaged** state.
  (The map's *disproof* of `FireDebrisState`/`FireDestroyedState`/`CollapseFireState`/`DebrisState`
  stands, and O3's ambiguity is now moot.)
- **`0xCE603754` = `FalloffState`: keep M — neither L nor withdrawn.** Pass 1's downgrade rests on a
  false "occurs nowhere". The state's *role* is now demonstrated from shipped data rather than
  guessed from grammar, and `DanglingState` cracking in the adjacent slot of the same 5-state
  machine is independent mutual support. It stays **M** only because there is still no code literal
  and no string — but the map's semantic argument is now **vindicated**, and its counter-argument
  about the shader `Falloff` cluster can be retired.
- The map's proposed test ("if `0xCE603754`'s script does `DisableConstraint` + `SetRootNode` +
  physics-keyframe-off") was aimed at the right machine but the wrong state: those two commands are
  in `DanglingState`'s **exit** and `DetachState`'s **enter**.

**Still uncracked, honestly**: `0x765CD254` (`TickDamage.NodeName` default — and, notably, the
HMMWV's own body node, so it is a **HIER node name**), `0x3D0D4C99`, `0xB4DBE473`, `0x5D308F4F`,
`0x5A6E8927`, `0xC6666A25`, `0x06A262B1`, `0x82794606`, `0x780EC3C8`. Tried this pass: ~280 000
further candidates over body/node/part vocabularies, verb×noun command compounds, and
`hp_`/`fx_`/`global_particle_`/`node_`/`bone_` prefixed forms. No hits. Not invented.

---

## P2.9 — U6 CLOSED, with a correction: the tick carries its own damage amount

`0x00676881`–`0x00676959` disassembled. The pool walk uses page table `[0x017BFC30]`, shift
`[0x017BFC1E]`, element size word `[0x017BFC1C]` = `0x10`, live count `[0x017BFC18]`, id array
`[0x017BFC2C]`. The map's control flow is exact:

```c
acc = dt + inst[+0x08];  interval = inst[+0x04];
if (acc < interval)  inst[+0x08] = acc;
else { inst[+0x08] = acc - interval;                 // consume exactly one tick
       FUN_00407B20(...guid...); FUN_00406170(&desc); }
```

**Two corrections.**
1. At `0x006768F8`, `movss xmm0, [eax]` loads **`inst[+0x00]` as a float** and passes it to
   `FUN_00407B20` in `xmm0` — another register arg Ghidra drops. So `RtTickDamage` is
   `{ float Damage@+0x00, float TickLength@+0x04, float accumulator@+0x08, ?@+0x0C }`, matching the
   authored `TickDamage.Damage` / `TickDamage.TickLength` (P2.2). **§3's "the damage magnitude is
   carried in the descriptor, not the timer" is wrong** — it is in the timer, at `+0x00`.
2. The map writes the post as `FUN_00407B20(...)` then `thunk_FUN_024B9B50(...)`, as though the
   second were something else. `FUN_00406170` **is** `jmp [0x0244FEA8] → 0x024B9B50`. It is
   literally the same `FUN_00407B20 → FUN_00406170` pair as the ignition path. This *strengthens*
   §10's evidence line 2 (one shared damage bus) rather than weakening it.

---

## P2.10 — U7 CLOSED

**`FUN_004F4340` (§4.3).** Confirmed as a request drain: `FUN_004F4840(&out, [0x00D6CC18])` in a
loop. But its component fetch is `FUN_00649440(0x00DF8710 /* = ParticleKey */, guid)`, and it gates
on a **second** 2-D matrix — `[0x017BBD54]` / `[0x017BBD58]`, the same descriptor shape as the
DamageKey matrix at `0x017BBD30`. So the drain is `ParticleKey`-keyed, which the map does not
mention; §4.3's "drains a request queue and calls `FUN_004D28C0` per request" is right as far as it
goes.

**`DebrisEffect` (§5).** Schema `FUN_006625E0` read in full: **6 ints, 4 floats, 2 enums — exactly as
the map says**, now with all 12 authored names (P2.2). `ChunkTrailEnum` = `Fire` / `FireNoLight`
confirmed at `0x00BC72D4`; `DebrisTypeEnum` at `0x00BC732C`. The one nit: the enum *fields* are
`Trail` and `Type`.

**§9's reimpl claims**, checked against the read-only source tree:
- "declares `NAMESPACE = "Fire"`, `GLOBAL = "Fire"`, `b.install_global("Fire")`" — **CONFIRMED**
  (`fire.rs:18,20,44`). The builder has no nesting mechanism at all (`bindings/mod.rs:186`), so
  `Graphics.FuelTrail` is currently inexpressible.
- "`Ignite`/`Extinguish` are `b.real` and should be `b.stub`; the file's own doc-comment says so" —
  **CONFIRMED** (`fire.rs:30-31` says "faithful no-ops"; `:38,40` are `b.real`).
- "`Put` is modelled as `Extinguish`" — **CONFIRMED** (`fire.rs:42`, identical body, single `i64`
  arg, no 4-arg type-check).
- "`Graphics` is missing 84 of its 95 rows" — **PARTIAL**. The 11-row count and the flattening are
  right, but **69 of the 75 callable rows do exist** with real bodies at the wrong Lua paths; only
  `MotionBlur`/`Contrast`/`Monochrome`/`Grainy`/`AA` (6 rows) are absent. The map also names
  `camera_fx.rs`, which is **not** a `Graphics` child — its `TABLE_VA 0x00b9a7d8` is past the blob
  terminator `0x00B9A7C8` the map itself establishes in §1; the file it should have named is
  `fade.rs` (= `Graphics.Effect`).
- `engine_support_inventory.md` §3 line 161 is quoted **exactly** by the map — but that row is now
  **stale**: `object_state.rs:81,86` install both as `b.real` (bookkeeping only; they never reach
  `Scene::fx_start`). `Scene::fx_start`/`fx_stop` do exist (`scene.rs:1221-1232`).
- `particles::start_emitter(name_hash: u32, origin: Vec3)` exists and indeed **lacks the hardpoint
  resolve** — the map's characterisation is right.
- No `Ignitor`/`RuntimeIgnitor`/`Flammable`/`TickDamage` component and no `update_ignitors` exists
  anywhere in `tools/wad_simulator`; `mercs2_combat::DamageKey` has **no `Fire` variant**.
- **`corpus_calls` is not a tool.** The map cites it as one (§1, §11). It is a `Required` struct
  field (`bindings/mod.rs:114-118`), hand-maintained. The cited value (0/0/0) is correct; the
  provenance is not reproducible as written.

---

## P2.11 — Items where the honest answer is a partial

- **Does any shipped object carry `Flammable`?** Still not enumerated to a placement count. What is
  now established is the consumer side (P2.4: buildings, kind 6) and that `[presize]` reserves 256
  of them in retail PC config — which is evidence of *design intent*, not of placements. This stays
  open; the right instrument is a prototype/placement dump, not a block-string count.
- **Runtime values of `[0x017BBD30]`/`[0x017BBD34]`** — structure and writers closed statically
  (P2.3); the live values are zero *in this dump* only because it predates tunable load. Genuinely
  live-only. Pass 1 is right that it belongs in the map's §8 confirm-live list.
- **Entity kinds 5, 7, 9, 11, 12, 13** — unnamed; no RTTI for the game's own classes.

---

## P2.12 — Effect on the silo recommendation (§10)

**Unchanged, and now better supported.** Three of this pass's findings bear on it, all in the same
direction:

1. **P2.3** — fire is scaled by a **`ModifierKey` × `DamageKey`** matrix shared with
   `ExplosionLarge` and `MeleeBash`, resolved by identical code at every site. §10's evidence line 3
   ("the designers filed fire in the damage-type table") is stronger than stated: fire is a *column*
   of the combat damage matrix.
2. **P2.9** — `RtTickDamage` posts through the *same* `FUN_00407B20 → FUN_00406170` pair, not a
   parallel `thunk_FUN_024B9B50`. §10's evidence line 2 gains a third producer on one bus.
3. **P2.4** — `Flammable` is read inside the ignition filter and gates **buildings**. Pass 1's
   "ninth line" stands and is now specific.

The one thing that *should* change in §9's silo hand-off is **P2.1**: delete the "cap 8 live"
instruction entirely. And add `Ignitor = {Radius, MinDamage, MaxDamage}` with the note that the
runtime **rotates** the fields, so a reimpl that mirrors the authored order into the runtime struct
will silently swap radius and rim-damage.

---

## P2.13 — Method notes for the next pass

- **The ECS master key generalises to schemas.** `[vtable+0x34]` names containers; `mov edx, <char*>`
  before `FUN_00656210/320/720` names **fields**. Both are register/indirect forms Ghidra discards.
  Any map that lists a component as "N ints, M floats" can be upgraded to authored names for free.
- **`mercs2_unpacked.exe` is a memory dump**: `0x00EDBEC8` (218) and `0x00EDBAC8` (116) are already
  populated, so the whole component registry is readable without running the game. But global
  *state* (`0x017BBD30`, …) reflects **pre-tunable-load**, so a zero there is not a runtime fact.
- **Deref before declaring SecuROM a wall.** Two of three thunks chased this pass landed on clean
  x86 (`FUN_00632360` → `0x02FB0000`). Only `FUN_004D4680` reached the VM at `0x02A30000` — and it
  says so out loud.
- **Search shipped data, not only the exe.** `0xCE603754` "occurs nowhere" only if you never open
  `vz.wad`. `--states` on one vehicle produced 17 verified hash cracks and one new one.
- **Trap #1 (Ghidra drops register args) is the single highest-yield defect in this map's area.** It
  hid the `Flammable` reader (`ecx`), the `ModifierKey` row key (`esi`), the `dt` and damage floats
  (`xmm0`), the hardpoint out-pointer (`edi`), and every authored field name (`edx`).

---

## P2.14 — Addendum: the `Flammable` placement count, and a second independent derivation of the field names

Two results landed after P2.11 was written. **P2.11's first bullet is superseded: the placement
question is now closed**, and the field names of P2.2 have been re-derived from a completely
different source and agree exactly.

### (a) `Flammable` placements in `vz.wad`: **zero**

`block_content_grep` over all 11 370 decompressed blocks (`ok=11370 failed=0`) puts `Flammable`,
`Ignitor`, `TickDamage` and `DebrisEffect` in **exactly one** block —
`block=3185 blocks\VZ\resident_P000_Q3.block` — and `RuntimeIgnitor` / `RtTickDamage` in **none**.
Dumping block 3185 (26.8 MB) shows each name occurs exactly twice there, and both occurrences are
reflection metadata: once in a **schema record** (`<name>\0 <hash> … <nfields> <stride>` followed by
`nfields × {type, name_hash, default, offset}`) and once in an alphabetical **hash→name registry**.
Block 3185 holds **160** such schema records — the whole component catalogue, one row per *type*.

The negative is decisive rather than a tooling artefact, on three grounds:

1. **Format**: a component instance is declared by a `COMP` chunk whose `info` child is the
   NUL-terminated ASCII class name (`crates/mercs2_formats/src/placement.rs:159-175`). Any block
   declaring a `Flammable` *must* contain the literal bytes.
2. **Positive control**: `Health` appears in **754** blocks (751 of them `vz_state_*` /
   `layers_static`). The fire components appear in 1 — the reflection block.
3. **COMP inventory**: `layers_static` carries **722 COMPs across 43 types** (`Ai`, `ModelName`,
   `ModifierKey`, `StateMachine`, `_BuildingPhysics`, …). **No fire/ignition component among them.**

A raw little-endian scan for the five component hashes returns 0 blocks for
`Flammable 0xD930020E`, `Ignitor 0x37C12455`, `RuntimeIgnitor 0x1CA3ABD7`, `RtTickDamage 0x27E19BF7`
and `DebrisEffect 0x4EC11797`; the single hit for `TickDamage 0x8DEF82AD` is at an unaligned offset
inside a 1 MB `UCFX` geometry payload with no `COMP`/`info`/`schm` tag and no `TickDamage` string —
a 4-byte collision (≈1.4 expected across ~10⁹ positions × 6 hashes). Caveats: the raw-hash pass
skips blocks > 6 MB (the string pass does not), and this covers **`vz.wad` only**.

**Reading.** `Ignitor` / `Flammable` / `TickDamage` / `DebrisEffect` are fully registered types with
authored schemas and **no static authored instances anywhere in the world data**. They must be
attached at runtime — by script, weapon effect, or the destruction code — or they are vestigial.
This is a materially different claim from the map's §7.1 ("`Flammable` … budgeted for 256
instances"), and it sharpens C1: retail *can* gate building ignition on `Flammable`, but **nothing
in the shipped world is authored with one**. A reimpl should implement the gate (the code path is
real) while expecting it never to fire from authored data.

### (b) The authored field names, re-derived from shipped data — exact agreement

The vz.wad schema records carry a **name hash per field**, which is an entirely independent route to
the same answer as P2.2's `mov edx, <char*>` disassembly. Every name agrees, verified with
`tools/pandemic_hash.py --m2`:

| component | field | name hash | name | P2.2 (exe) | shipped record |
|---|---|---|---|:-:|:-:|
| `Ignitor` (3 fields, `0x0C`) | 0 `0x00` float | `0x354694DB` | **`Radius`** | ✓ | ✓ |
| | 1 `0x04` float | `0x1AB984F4` | **`MinDamage`** | ✓ | ✓ |
| | 2 `0x08` float | `0xCBDCD01A` | **`MaxDamage`** | ✓ | ✓ |
| `TickDamage` (4, `0x10`) | 0 int | `0x9A6663A4` | **`DamageThresh`** | ✓ | ✓ |
| | 1 float | `0xF4434ADE` | **`Damage`** | ✓ | ✓ |
| | 2 float | `0x7409DF66` | **`TickLength`** | ✓ | ✓ |
| | 3 **name** | `0x9AE0FEAC` | **`NodeName`** | ✓ | ✓ |
| `DebrisEffect` (12, `0x30`) | 0–3 **name** | `0x1DE5C824` / `0xDAFC82FF` / `0xC780F3A8` / `0xE189D1F3` | **`Name`, `EffectName`, `Hardpoint`, `Template`** | ✓ | ✓ |
| | 6–7 float | `0xB5D861C7` / `0xCF25E331` | **`MinChunkVel`, `MaxChunkVel`** | ✓ | ✓ |
| | 10–11 enum | `0xB174F04B` / `0x28E10525` | **`Trail`, `Type`** | ✓ | ✓ |

Three refinements this adds over P2.2:

1. **Type codes.** `1=bool, 5=int, 6=name/string-hash, 7=float, 9=enum, 10=Vector3` (calibrated
   against components the ECS docs already describe). So `TickDamage.NodeName` and `DebrisEffect`'s
   first four fields are **name references**, not plain ints. **§5's "6 ints" is loose**: fields 0–3
   are type-6 name hashes and only 4–5 are plain ints. A reimpl treating all six as integers will
   mis-handle four name references.
2. **`DebrisEffect` stride is `0x30` (48 B)** — which reconciles exactly with the `[presize]` row
   `DebrisEffect 4608` = 96 × 48 (P2.1), an independent cross-check on both numbers.
3. **A shipped bug in the retail exe.** The authored record gives fields 8/9 the distinct hashes
   `0x83BA82B5` / `0x51D7BD57` = **`MinChunkTime`** / **`MaxChunkTime`**. But the exe's schema
   function `FUN_006625E0` passes the *same string pointers* for fields 8/9 as for 6/7
   (`edx = 0x00BCAE9C "MinChunkVel"`, `0x00BCAEA8 "MaxChunkVel"` — and the `.rdata` layout confirms
   `"Trail"` follows immediately at `0x00BCAEB4`, so no `MinChunkTime` string exists in the image).
   **Retail registers the two chunk-lifetime fields under the chunk-velocity names** — a
   copy-paste defect in the shipped binary, invisible to either source alone.

`RuntimeIgnitor` and `RtTickDamage` have **no schema record** in the shipped data, confirming they
are runtime-only pools with no authored fields.

**Still uncracked**: `Flammable`'s single field `0x8B50DC56`, and `DebrisEffect` fields 4/5
(`0xC5528D68`, `0xB4CB8AD2`). Note that the shipped record gives `Flammable` **1 int field at
`+0x00`**, whereas the exe's `FUN_00662720` emits **no** stream reads — so the map's "reads **zero**
stream fields" is right about the *binary* and incomplete about the *authored* schema. Attack used
for the three: every identifier token in the PC exe, the Xbox devkit dump, block 3185 and the whole
`docs/` tree, plus ~278 k generated compounds. No match; these names appear nowhere in any shipped
binary and likely existed only in the authoring tool. **Not invented.**

### (c) A gap in the ECS corpus

`fire_ignition_code_map.md:22` cites `../mercs2-ecs/05_presentation_audio_fx.md` as the source for
`DebrisEffect`'s reflected schema. **That file contains no `DebrisEffect` row** — the string does not
occur in it, nor anywhere in `docs/mercs2-ecs/` including `_registry_raw.tsv` and `_manifests/`. The
nearest row is `RtDebris` (`03_controllers_physics.md:93`). The map's §5 content is sound — it was
derived from the schema function, not from that citation — but the **citation is to a row that does
not exist**, and `docs/mercs2-ecs/` has a real gap that the table above now fills.
