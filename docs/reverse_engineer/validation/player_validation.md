---
title: Double-blind validation — Player code map
subject: "`Player` Lua namespace (luaL_Reg @ 0x00B98FC0) and the player object behind it"
target: docs/reverse_engineer/player_code_map.md
date: 2026-07-26
status: current
evidence: proven
method: >
  Phase A derived blind from primary sources only (raw disassembly of
  output/_ghidra/securom_dump/mercs2_unpacked.exe via capstone, VA->file mapped through the PE
  section table; Ghidra decomp used only as a cross-check). Phase B compares against the map.
---

# Double-blind validation — `docs/reverse_engineer/player_code_map.md`

## Method / harness

All addresses below were read out of `output/_ghidra/securom_dump/mercs2_unpacked.exe`.

PE section table (VA->raw is **not** identity in general; for `.text`/`.rdata`/`.data` it happens to
be `VA - 0x400000`, but the `S*`/`.securom` sections diverge, so the mapping was done properly):

```
.text      VA=0x00401000 VS=0x704000 raw=0x1000
.rdata     VA=0x00b05000 VS=0x0f1000 raw=0x705000
.data      VA=0x00bf6000 VS=0xe04000 raw=0x7f6000
Stext      VA=0x01a49000 ...   .securom VA=0x023e9000 ...
```

Two derived indexes are the basis for every "N callers" / "N refs" number here:

* **Linear disassembly index** — every Ghidra function start (42 573) plus the 107 Player cfunc
  entry points, disassembled linearly to the next start. Yields a call graph (14 622 targets) and an
  absolute-memory-reference index (35 920 addresses). This deliberately replaces naive byte
  scanning: searching for the 4-byte LE pattern `77 bd df 00` and back-tracking produces phantom
  `cmp eax, 0xdfbd77` decodes, because `3d 77 bd df 00` is itself a legal 5-byte instruction. Every
  reference count in this document comes from real instruction boundaries.

---

## Phase A — independent findings (written before reading the map)

> **Phase-A errata**, added during Phase B verification and left visible rather than silently
> corrected, because the integrity of the blind phase depends on showing what I got wrong:
> two rows of the §A4 table below (`+0x4F5`, `+0x4F7`) came from a regex-based offset extractor and
> are **wrong** — see [E1]. One further claim I drafted (`+0x610` on the player object) was dropped
> for the same reason. The extractor was a convenience over the disassembly, not the disassembly;
> every offset I re-read by hand held up.

### A1. The table is really `Player`, and it really has 107 entries

The authoritative namespace registry at `0x00DFD478` is 31 rows x 12 B
`{name*, luaL_Reg*, post_register_chunk*}`, terminated by the zero row at `0x00DFD5EC`:

```
0x00dfd4a8 row 4  name=0x00bb9890 -> "Player"   reg=0x00b98fc0   post=0x00000000
```

So `0x00B98FC0` **is** the `Player` namespace table, and it has no post-register Lua chunk.

Walking `0x00B98FC0` as `{const char*, lua_CFunction}` pairs gives **107 rows**, NULL-terminated at
`0x00B99318`. There are **no marker rows** — no `{name, 0xFFFFFFFF}` open / `{name, 0xFFFFFFFE}`
close pairs — so `Player` is a **flat namespace with no sub-tables**. All 107 function pointers lie
in one contiguous `.text` span, `0x005DA7A0 .. 0x005E0470`.

Cross-checking all 31 namespace tables: **zero** Player cfuncs are shared with any other namespace.

### A2. How many bodies are readable — 107 of 107

* Present in `mercs2_unpacked.exe_decomp.txt` (by `@0xADDR` header match): **50**.
* Absent: **57** — including `GetCharacter`, `GetControlledObject`, `GetSeat`, `GetName`,
  `GetPlayer`, `GetPlayerId`, `IsLocal`, `IsJoined`, `IsRemote`, `GetCash`, `AddCash`, `GetFuel`,
  `AddFuel`, `GetFuelCapacity`, `SetFuelCapacity`, `GetAvailableCostumes`, `SetAvailableCostumes`,
  `SetInPmc`, `SetAimMode`, `CreatePlayer`, `DestroyPlayer`, ...
* All 57 disassemble cleanly from raw bytes and terminate in `ret` + `int3` padding.

**Readable count: 107/107. Binding-only count: 0.** The 50/57 split is a property of Ghidra's
static-caller reachability, not of the binary.

### A3. The container the cfuncs resolve against is `0x00DF9B90`

Every handle-taking Player cfunc funnels through one of two helpers, both with the container as a
**register** `this` (which Ghidra drops — trap #1):

| helper | `this` reg | returns |
|---|---|---|
| `FUN_006496B0` | `ECX` | dense index, or `< 0` if absent |
| `FUN_00423DC0` | `ESI` | **pointer to the slot**, or `esi+0x7C` (sentinel) if absent |

`FUN_00423DC0` disassembles to a paged-array lookup that names the container's field layout:

```
0x00423dc0  push eax
0x00423dc1  mov  ecx, esi                 ; this = container
0x00423dc3  call 0x6496b0                 ; -> dense index in eax
0x00423dca  jl   0x423df2
0x00423dcc  mov  ecx, [esi + 0x48]        ; index -> packed key array
0x00423dcf  mov  edx, [ecx + eax*4]
0x00423dd2  mov  eax, [esi + 0x20]        ; bucket count
0x00423dd5  mov  cl,  [esi + 0x26]        ; page shift
0x00423dd8  sub  eax, 1
0x00423ddc  and  eax, edx                 ; page-local index
0x00423de0  movsx edx, word [esi + 0x24]  ; element stride
0x00423de4  imul eax, edx
0x00423de7  sar  edi, cl                  ; page number
0x00423de9  mov  ecx, [esi + 0x70]        ; page table
0x00423dec  add  eax, [ecx + edi*4]
0x00423df0  jne  0x423df5
0x00423df2  lea  eax, [esi + 0x7c]        ; sentinel slot
0x00423df5  ret
```

Many cfuncs inline this same sequence with the container folded into absolute addresses —
`[0xDF9BD8]`, `[0xDF9BB0]`, `[0xDF9BB4]`, `[0xDF9BB6]`, `[0xDF9C00]`, `0xDF9C0C` — which are exactly
`0xDF9B90 + {0x48, 0x20, 0x24, 0x26, 0x70, 0x7C}`. That arithmetic is the proof of the base.

The container is statically initialised in `.data`, so its parameters are readable without running
the game:

```
0x00df9b90  b8 3f bc 00 | ff ff 38 01 | 0b 00 00 00 | 08 00 00 00
0x00df9ba0  00 00 00 00 | 03 00 00 00 | 00 00 00 00 | 00 00 00 00
0x00df9bb0  08 00 00 00 | 04 00 | 03 00 | b9 79 37 9e | ...
```

| off | VA | value | meaning |
|---|---|---|---|
| +0x00 | 0xDF9B90 | `0x00BC3FB8` | vtable |
| +0x04 | 0xDF9B94 | `0x0138FFFF` | class/type id |
| +0x0C | 0xDF9B9C | **8** | **capacity** |
| +0x18 | 0xDF9BA8 | (runtime) | live record count |
| +0x20 | 0xDF9BB0 | **8** | bucket count (used as `n-1` mask) |
| +0x24 | 0xDF9BB4 | **4** | element stride (a pointer) |
| +0x26 | 0xDF9BB6 | **3** | page shift -> 8 elements/page |
| +0x48 | 0xDF9BD8 | (runtime) | dense-index -> packed-key array |
| +0x70 | 0xDF9C00 | (runtime) | page table |
| +0x7C | 0xDF9C0C | 0 | null sentinel slot |

`0x00DF9B10` is a **different object of the same class**: vtable `0x00BC3F48`, type id `0x0137FFFF`,
capacity **256**, stride **1 byte**, page shift **7**. My index finds **20** references to it, none
of them inside the Player cfunc span; `0x00DF9B90` has **132**, mostly inside it.

### A4. Player-object field layout (with the function each offset came from)

The Lua-visible "player" is a **lightuserdata handle**; the object is `*lookup(0xDF9B90, handle)`.

| offset | meaning | derived from |
|---|---|---|
| +0x1C | **the handle itself** (what Lua receives) | `GetPrimaryPlayer` `mov edi,[eax+0x1c]`; same in `GetSecondaryPlayer`, `GetPlayer`, `GetAllPlayers`, `GetLocalPlayer` |
| +0x20 | attached **character** | `GetCharacter` `mov edi,[eax+0x20]`; `GetPrimaryCharacter`; `GetControlledObject` fallback |
| +0x24 | **seat handle** (a key, not a pointer) | `GetSeat` returns it raw; `GetControlledObject` feeds it to container `0xDF81D8` via `FUN_00648D80` |
| +0x28 | local id | `GetLocalId` |
| +0x2C | player id / local index | `GetPlayerId`, `IsLocal`, `FUN_006CDAF0`'s match predicate |
| +0x30 | join/viewport id, **-1 = not joined/not local** | `IsJoined`, `IsRemote`, `GetAllPlayers`, `FUN_006CDAC0` |
| +0x58 | remote flag (nonzero = remote) | `IsLocal`, `IsRemote` |
| +0x158 | grapple enabled (byte) | `SetGrappleEnabled` |
| +0x188/+0x18C | out-boundary pair | `GetOutBoundary` |
| +0x199 | health clamp (byte) | `SetHealthClamp` |
| +0x244/+0x245 | input enabled | `SetInputEnabled` |
| +0x380/+0x384 | boundary callback pair | `SetBoundaryCallback` |
| +0x3A8 | vehicle-disguise sub-struct | `GetVehicleDisguiseState` `lea edi,[eax+0x3a8]` |
| +0x430/+0x434/+0x438 | vehicle-disguise fields | `VehicleDisguise` |
| +0x45D/+0x45E/+0x45F | seat movement locks | `SetSeatMovementLocks` |
| +0x460 | vehicle controls lock | `SetVehicleControlsLock` |
| +0x461 | wait-for-in-game | `SetWaitForInGame` `mov byte [eax+0x461], 1` |
| +0x463 | in-PMC | `SetInPmc` `mov byte [eax+0x463], cl` |
| +0x464 | aim mode | `SetAimMode` `mov byte [eax+0x464], cl` |
| ~~+0x4F5/+0x4F7~~ | **[E1] WRONG — retracted in Phase B** | these are on the object at **`player+0x08`**: `IsInWarningZone` does `mov eax,[eax+8]` *before* `cmp byte [eax+0x4f5], 0` / `[eax+0x4f7]`. My extractor did not model the extra indirection. |

**`+0x158` and `+0x199` are on the player object — verified byte-exact.** The raw bytes at both
disputed sites decode as claimed:

```
SetGrappleEnabled  0x005dfc5d  8b442410     mov  eax, [esp + 0x10]        ; the handle
                   0x005dfc61  be909bdf00   mov  esi, 0xdf9b90            ; <-- container
                   0x005dfc66  e85541e4ff   call 0x423dc0                 ; -> slot*
                   0x005dfc6b  8b00         mov  eax, [eax]               ; -> PLAYER OBJECT
                   0x005dfc85  888858010000 mov  byte [eax + 0x158], cl   ; <-- on the object

SetHealthClamp     0x005dc5a1  be909bdf00   mov  esi, 0xdf9b90
                   0x005dc5a6  e81578e4ff   call 0x423dc0
                   0x005dc5ab  8b00         mov  eax, [eax]
                   0x005dc5c5  888899010000 mov  byte [eax + 0x199], cl
```

**`+0x3A8` is on the player object, by triangulation.** `GetVehicleDisguiseState` reaches its base
via `call 0x6CDB70`, which is a SecuROM split-thunk (`jmp dword [0x245F8CC]` -> `0x024E8BD0`, an
obfuscated push/call trampoline) and is not statically resolvable from the unpacked image. But the
objects returned by `FUN_006CDB70` are accessed at `+0x30` (compared against `-1`), `+0x58`, and
`+0x461` — all independently derived as player-object fields from the `0xDF9B90` path.

**Not on the player object:** `SetVehicleDisguise`/`GetVehicleDisguise` read and write the **global
byte `[0x01176106]`**, not any per-player field.

### A5. How the roster size is bounded — four separate limits, and two are hardcoded

1. **Container capacity = 8** — `0xDF9B9C` static initialiser (§A3).
2. **`GetMaximumPlayers`** returns `[0x017C0DD0]`, statically initialised to **2**. The same global
   bounds the loops in `GetAllPlayers` and `TeleportCamera`.
3. **`FUN_006CDAF0(localIdx)`** opens with `cmp dword [esp+4], 1 / ja fail`, i.e. **only indices 0
   and 1**, then linear-scans the container over `[0xDF9BA8]` entries for `[obj+0x2C] == localIdx`.
4. **`FUN_006CDAC0`** hardcodes `cmp esi, 2` and counts entries with `[obj+0x30] != -1`.

Two of the exposed getters are **constant stubs, not queries**:

```
GetMaximumLocalPlayers  0x005ddfaa  movss xmm0, [0xb92874]   ; = 2.0f  (.rdata constant)
GetCurrentLocalPlayers  0x005ddfea  movss xmm0, [0xb9b664]   ; = 1.0f  (.rdata constant)
```

`GetCurrentLocalPlayers` therefore **always returns 1.0**, regardless of actual state.

### A6. Economy / profile state — singleton `[0x01176054]`

| offset | field | getter / setter | sets dirty flag? |
|---|---|---|---|
| +0x11 | **dirty flag** (OR-ed byte) | — | — |
| +0x2C | cash | `GetCash` / `SetCash` / `AddCash` | `SetCash` **NO**; `AddCash` yes |
| +0x30 | fuel | `GetFuel` / `SetFuel` / `AddFuel` | yes / yes |
| +0x30C | fuel capacity | `GetFuelCapacity` / `SetFuelCapacity` | **NO** |
| +0x61 | profile character | `GetProfileCharacter` / `SetProfileCharacter` | **NO** |
| +0x62 | profile upgrade | `GetProfileUpgrade` / `SetProfileUpgrade` | yes |
| +0x63 | profile costume | `GetProfileCostume` / `SetProfileCostume` | **NO** |
| +0x25E | available costumes | `GetAvailableCostumes` / `SetAvailableCostumes` | **NO** |

The dirtying setters use compare-then-`setne`, so they dirty **only on actual change**:

```
SetFuel            0x005df64e  cmp   [eax + 0x30], ecx
                   0x005df651  mov   [eax + 0x30], ecx
                   0x005df654  setne dl
                   0x005df657  or    [eax + 0x11], dl
SetProfileUpgrade  0x005df8c3  movzx edx, byte [eax + 0x62]
                   0x005df8cb  cmp   edx, ecx
                   0x005df8cd  setne dl
                   0x005df8d0  or    [eax + 0x11], dl
                   0x005df8d3  mov   byte [eax + 0x62], cl
AddCash            0x005df567  test  ecx, ecx          ; NB: on the DELTA, not old-vs-new
                   0x005df569  setne dl
                   0x005df56c  or    [eax + 0x11], dl
```

The non-dirtying setters just store:

```
SetCash              0x005df4f9  mov eax, [0x1176054] ; 0x005df4fe  mov [eax + 0x2c],  edx
SetFuelCapacity      0x005df772  mov ecx, [0x1176054] ; 0x005df778  mov [ecx + 0x30c], eax
SetProfileCharacter  0x005df822  mov ecx, [0x1176054] ; 0x005df828  mov [ecx + 0x61],  al
SetProfileCostume    0x005df972  mov ecx, [0x1176054] ; 0x005df978  mov [ecx + 0x63],  al
SetAvailableCostumes 0x005dfb92  mov ecx, [0x1176054] ; 0x005dfb98  mov [ecx + 0x25e], al
```

**Five** setters fail to dirty the profile, not three.

Also: `AddCash` clamps at zero (`0x005DF571-83`), and both `SetCash` and `SetFuel` accept an
**optional second boolean which, when true, skips the write entirely**
(`cmp byte [esp+0x10], 0 / jne <return>` at `0x005DF4EE` and `0x005DF63E`).

### A7. Two constant-returning stubs

```
GetAnyCharacter  0x005de27a  c700000000f0  mov dword [eax],     0xf0000000
                 0x005de280  c7400402...   mov dword [eax + 4], 2          ; lightuserdata
GetPlayerStart   0x005dec77  68908ad200    push 0xd28a90                    ; "PlayerLocation_Start"
                 0x005dec7c  e86fed2700    call 0x85d9f0
```

### A8. Where the player is ticked — I walked it myself

**The per-frame path does not run through `FUN_004C13A0`.** The main loop in `FUN_00631670`:

```
0x00631938  e8b3f5ffff   call 0x630ef0        ; <-- THE PER-FRAME FUNCTION
   ... telemetry ring-buffer push ...
0x00631a93  381dff5f1701 cmp  byte [0x1175fff], bl
0x00631a99  0f8499feffff je   0x631938         ; <-- loop back
0x00631a9f  a128b2ed00   mov  eax, [0xedb228]
0x00631aa9  ff159851b000 call [ReleaseMutex]
0x00631aaf  e8ecf8e8ff   call 0x4c13a0         ; <-- ONCE, AFTER THE LOOP = SHUTDOWN
0x00631abf  c3           ret
```

And `FUN_004C13A0` forces the state to 3 (shutdown) *before* calling `FUN_004C09C0`:

```
0x004c13ba  cmp  dword [0xd6c24c], 2
0x004c13c3  mov  dword [0xd6c24c], 3      ; state := 3 (SHUTDOWN)
0x004c13cd  fldz                          ; dt = 0.0
0x004c13d0  mov  ecx, 0xd6c244            ; this  (Ghidra renders this as "FUN_004c09c0(0)")
0x004c13d8  call 0x4c09c0
```

`FUN_004C09C0` is a state machine on `[this+8]` (= `0x00D6C24C`): case 1 = init, **case 2 = run**
(the only branch that calls `FUN_004C0EC0`), case 3 = teardown. On the `FUN_004C13A0` path the state
is 3, so **`FUN_004C0EC0` is never reached from `FUN_004C13A0`**.

The real per-frame entry into the same code is **virtual**, which is why a static-caller walk misses
it. `0x00D6C244` holds vtable pointer `0x00BB0460`:

```
0x00bb0460 = 0x004be650      0x00bb0464 = 0x004be070
0x00bb0468 = 0x004be090      0x00bb046c = 0x004C09C0   <-- vtable slot +0x0C
```

and `FUN_004C15E0` — the master update — walks a layer array at `0x17BBCCC` calling `[vtbl+0x0C](dt)`
on each entry (`0x004c1633 mov edx,[eax+0xc]` / `0x004c163c call edx`).

`FUN_004C1170` builds that array, and the index is unambiguous:

```
0x004c11f9  mov dword [eax*4 + 0x17bbccc], 0xd6c22c   ; eax = 0 -> layer 0
0x004c1211  mov dword [eax*4 + 0x17bbccc], 0x14538b8  ; layer 1
0x004c1229  mov dword [eax*4 + 0x17bbccc], 0x149fda0  ; layer 2
0x004c1241  mov dword [eax*4 + 0x17bbccc], 0xd6c238   ; layer 3
0x004c1259  mov dword [eax*4 + 0x17bbccc], 0xd6c244   ; layer 4   <-- the game-state object
0x004c1274  mov dword [0x17bbcfc], eax                ; pivot = 4 ; count [0x17bbcf4] = 5
```

**So the game-state pump is layer 4 (the last) of the master update.** Full chain:

```
FUN_00631B10                      (entry; 0 static callers)
 |- FUN_00631670                  main loop
     |- FUN_00630EF0              per-frame  [loop body @0x631938]
         |- FUN_004C14F0          dt bookkeeping
             |- FUN_004C15E0      master update: walks layers 0..4 @0x17BBCCC
                 |- (virtual [0x00BB0460 + 0x0C])
                     |- FUN_004C09C0   this = 0x00D6C244  = LAYER 4, state==2
                         |- FUN_004C0EC0
                             |- FUN_004C9740   per-system call list (108 callees)
                                 |- FUN_0041FE20   reads the player container
                                 |- FUN_0062E7B0 / FUN_0062E810   iterate it
```

`FUN_0062E7B0` iterates the `0xDF9B90` container by dense index and calls `FUN_006A1880` per player
with the object in **EAX** (another dropped register arg):

```
0x0062e7b1  mov  eax, [0xdf9ba8]        ; live count
0x0062e7c1  mov  cl,  [0xdf9bb6]        ; the 0xDF9B90 container, inlined
0x0062e7f0  mov  eax, [eax]             ; -> player object
0x0062e7f6  call 0x6a1880               ; per-player update, this in EAX
0x0062e805  jl   0x62e7c1               ; next player
```

`FUN_004C15E0` contains **zero** call references to `FUN_004C0EC0` — true, but expected and
non-probative, because `FUN_004C15E0` dispatches **through a vtable**.

### A9. `DAT_00DFBD77`

Instruction-accurate reference counts for the byte cluster at `0x00DFBD74`:

| addr | refs | dominant form |
|---|---|---|
| 0xDFBD74 | 113 | `cmp byte [0xdfbd74], 0` |
| 0xDFBD75 | 55 | `cmp byte [0xdfbd75], 0` |
| 0xDFBD77 | **135** | `cmp byte [0xdfbd77], 0` (114x) |
| 0xDFBD78 | **164** | `cmp byte [0xdfbd78], 0` (127x) |

They are read all over the engine and **never written individually**. They are published as a block,
once per frame, by `FUN_006CECF0`, which builds an 0x18-byte struct on the stack and stores it with
three `movq` (`0x006CEEBA`, `0x006CEEC8`, `0x006CEED6`). The bytes are derived from the local
player's controlled-object state enum `[ctrl + 0x0C]`:

```
0x006cedc4  mov  eax, [edx + 0xc]
0x006cedc7  cmp  eax, 4 ; sete cl  -> [esp+0x16] -> 0xDFBD76
0x006cedcd  cmp  eax, 1 ; sete dl  -> [esp+0x17] -> 0xDFBD77
0x006cedda  cmp  eax, 2 ; sete al  -> [esp+0x18] -> 0xDFBD78
```

So `DAT_00DFBD77` is a **per-frame cached predicate "local player's controlled-object state == 1"**,
one of a mutually-exclusive trio (states 1/2/4) at `0xDFBD76/77/78`. Static initialiser `0x00`. Its
publisher sits on a **different branch of the same frame** from the layer driver:
`FUN_00630EF0 -> FUN_004C16E0 -> FUN_004F5530 -> FUN_006CECF0`, called at `0x630F30`, i.e. **before**
`FUN_004C14F0`.

Inside the Player cfunc span it is read at exactly three sites — `AddBoundary` `0x005DC903`,
`RemoveBoundary` `0x005DCA33`, `RemoveAllBoundary` `0x005DCB31` — each an early-out at the top of the
function. `DAT_00DFBD78` is read **zero** times in that span.

---

## Phase B — verdicts

### Summary counts

| verdict | count |
|---|---|
| CONFIRMED | 26 |
| CONTRADICTED | 6 |
| OVERSTATED | 5 |
| UNVERIFIABLE | 2 |
| MISSING (found by me, absent from map) | 10 |
| **total falsifiable claims assessed** | **49** |

Plus 4 internal-consistency defects (below), which are not falsifiable claims but are reader-facing
errors.

The map is substantially better than its provenance warning implied. Its binding table is
**perfect** — see C2/C3, which are the strongest mechanical checks in this document. The failures
cluster almost entirely in **one place: §1, the frame chain**, where a mid-session "correction"
over-corrected and has already been propagated to five sibling maps.

### CONFIRMED (26)

| # | Claim | How I reproduced it |
|---|---|---|
| C1 | Table `0x00B98FC0` is `Player`, 107 entries, 0 stubs | Registry `0x00DFD478` row 4 -> `"Player"` / `0x00B98FC0`; table walks to a NULL terminator at 107 |
| C2 | **All 107 name -> VA -> index rows in §3** | Mechanical diff of the map's §3 table against my own `.rdata` walk: **0 mismatches** on name, VA and index across all 107 rows |
| C3 | **The 50 / 57 body-coverage split, per row** | Diffed the map's per-row `⬤`/`▨` glyph against Ghidra decomp presence: 50 / 57, **0 mismatches** across all 107 rows |
| C4 | Cfunc cluster is contiguous `0x005DA7A0`–`0x005E0470` | All 107 pointers fall in that span; no cross-namespace sharing |
| C5 | No binding-only rows remain; all 107 disassemble | All 57 Ghidra-absent bodies disassemble to `ret` + `int3` |
| C6 | Player container = `0x00DF9B90`, vtable `PTR_FUN_00BC3FB8` | `mov dword [0xdf9b90], 0xbc3fb8` in the ctor; 132 refs |
| C7 | `FUN_00423DC0` is the non-inlined resolve, `this` in **ESI**, using `this+0x20/0x24/0x26/0x48/0x70`, returning `this+0x7c` on miss | Read the body verbatim (§A3) — matches the map's pseudocode line for line |
| C8 | `FUN_006496B0` is the guid -> dense-slot lookup, `-1` on miss | Read body; `jl` on the return in every caller |
| C9 | `DAT_00DF9C0C` is the shared zero-record | It is `container+0x7C`; appears inlined as the literal `0xdf9c0c` in 23 cfuncs |
| C10 | `DAT_00DF9BA8` is the live record count | `container+0x18`; bounds the scans in `FUN_006CDAF0` and `FUN_0062E7B0` |
| C11 | `FUN_006CDAF0`: `if (1 < i) return 0`, then scan matching `+0x2C` | `cmp dword [esp+4], 1 / ja` then the paged walk and `cmp [ecx+0x2c], ebp` |
| C12 | `FUN_006CDAC0`: loop `i < 2`, count `+0x30 != -1` | `cmp esi, 2` and `cmp dword [eax+0x30], -1` |
| C13 | `+0x1C` = the player's own guid, the handle scripts pass | `GetPrimaryPlayer`/`GetSecondaryPlayer`/`GetPlayer`/`GetAllPlayers`/`GetLocalPlayer` all push `[obj+0x1c]` |
| C14 | `+0x20` = attached character guid | `GetCharacter`, `GetPrimaryCharacter`, `GetControlledObject` fallback |
| C15 | `+0x2C` = player index, the roster key | `GetPlayerId`, `IsLocal`, `FUN_006CDAF0` |
| C16 | `+0x30` with `-1` sentinel | `IsJoined`, `IsRemote`, `GetAllPlayers`, `FUN_006CDAC0` |
| C17 | `+0x158` grapple / `+0x199` health clamp are **player** fields | Byte-exact disasm; `call 0x423DC0` then `mov eax,[eax]` then the store (§A4) |
| C18 | The raw bytes `BE 90 9B DF 00` at `0x005DFC61` and `0x005DC5A1` | Read from the file at both VAs; both decode `mov esi, 0xdf9b90` |
| C19 | **`0x00DF9B10` is SHARED, not player-specific** (§9.5) | `FUN_006A4060` (player attach) refs it at `0x6A4082/408A/416D`; `Object.SetInfiniteAmmo` `FUN_005CE7E0` refs it at `0x5CE89D/8B7/8C0`. **My own blind draft got this backwards; the map is right.** |
| C20 | `FUN_004C9740` is a per-system call list, and `FUN_0041FE20` is in it with sole caller `FUN_004C9740` | My call index: `FUN_004C9740` has **108** callees; `callers(0x41FE20) == {0x4C9740}` |
| C21 | `FUN_0041FE20` reads the player container | It appears in my reference index for `0xDF9B90`, `0xDF9BB0`, `0xDF9C00` |
| C22 | `FUN_004C15E0` contains zero refs to `FUN_004C0EC0` | My call index (see O1 for why this is not evidence for the conclusion drawn from it) |
| C23 | `GetAnyCharacter` returns the constant lightuserdata `0xF0000000`, no lookup | `mov dword [eax], 0xf0000000` / `mov dword [eax+4], 2`; body is 0x32 bytes |
| C24 | `GetPlayerStart` pushes the literal `"PlayerLocation_Start"` | `push 0xd28a90; call 0x85d9f0`; `cstr(0xD28A90)` = that string |
| C25 | Profile `[0x01176054]`: `+0x11` dirty, `+0x2C` cash, `+0x30` fuel, `+0x30C` fuel capacity, `+0x61/62/63` | The 17 profile/economy cfunc bodies |
| C26 | `SetCash`, `SetProfileCharacter`, `SetProfileCostume` do **not** set the dirty flag | Their stores are bare `mov`; no `or [.. + 0x11]` anywhere in those bodies |

Also confirmed in passing: `+0x45D/E/F` and `+0x460` (`SetSeatMovementLocks`, `SetVehicleControlsLock`),
`+0x380/+0x384` (`SetBoundaryCallback`), `+0x11C` (`GetTargetUnderReticle`), `SetOutfit`'s three
streaming calls, `GetMaximumPlayers` pushing `DAT_017C0DD0` verbatim, and `RemoveBoundary`'s
`DAT_00DFBD77` early-out (`0x005DCA33`).

### CONTRADICTED (6)

**X1 — §1: "The per-system pump hangs off the **game-state pump**, a *sibling* of the master update
under the app loop", drawn as `@0x00631AAF -> FUN_004C13A0 -> FUN_004C09C0 -> ...`.**
The map correctly identified the call site `0x00631AAF`, but not what it is: that call sits **after
the main loop has exited** (loop body `0x00631938`, loop-back `0x00631A99 je 0x631938`) and after
`ReleaseMutex`. `FUN_004C13A0` then sets `[0xD6C24C] = 3` at `0x004C13C3` *before* calling
`FUN_004C09C0` with `dt = 0.0`, and `FUN_004C0EC0` is only reached from the `state == 2` branch. So
on the route the map draws, **the chain below `FUN_004C09C0` cannot execute at all**. `FUN_004C13A0`
is the shutdown/teardown entry.

**X2 — §1: "That link does not exist ... drew the per-system call list as *layer 4 of the 5-layer
master update* ... **`FUN_004C15E0` contains zero references to `FUN_004C0EC0`**".**
It **is** layer 4, and the original draft the map retracted was right. `FUN_004C1170` writes the
layer array in order — `0xD6C22C`(0), `0x014538B8`(1), `0x0149FDA0`(2), `0xD6C238`(3), **`0xD6C244`(4)** —
then sets count `[0x17BBCF4] = 5` and pivot `[0x17BBCFC] = 4`. `0x00D6C244` is the game-state object;
its vtable is `0x00BB0460`; `0x00BB046C` (slot `+0x0C`) holds `FUN_004C09C0`; and `FUN_004C15E0`
calls exactly `[vtbl+0x0C]` at `0x004C163C`. The "zero references" observation is what a **virtual
dispatch** looks like from a static call graph. **This is the single most consequential error in the
map**, and §1 explicitly propagates it: *"Sibling maps that describe a 'layer-4 per-system list'
(camera, world-streaming, input, population, vehicle) inherit the same error in the route."* They do
not; the retraction should itself be retracted across all six documents.

**X3 — §2.1: "Eight `Player` cfuncs **inline** the identical lookup ... The eight inliners are
exactly the `Player` cfuncs that take a **player GUID**."**
**23** cfuncs inline the walk (`mov ecx, 0xDF9B90`), and a further **24** reach the container through
`FUN_00423DC0` (`mov esi, 0xDF9B90`) — **47 of 107** take a player handle, not 8. The map's list of
eight is a subset. Full inliner list: `ClearGPS, ClearPlayerDB, GetAllBoundaryGuid, GetCamera,
GetCameraXZHeading, GetCharacter, GetControlBindingType, GetControlledObject, GetOutBoundary,
GetPlayerId, GetRetryPosition, GetSeat, GetTargetUnderReticle, GetViewport, GetViewportId,
InCinematicMode, IsInWarningZone, IsPositionOutBoundary, RequestPDAMapModeCancel, SetCinematicMode,
SetSeatMovementLocks, SetSwimmingSearchRadius, SetVehicleControlsLock`.

**X4 — §9.8: "largest observed offset is `+0x460`" / §2.2: "Minimum size `0x461`".**
Three larger fields are written straight off the post-deref object pointer: `+0x461`
(`SetWaitForInGame` `0x005DF1C4`), `+0x463` (`SetInPmc` `0x005DFD95`), `+0x464` (`SetAimMode`
`0x005DFEA5`). Minimum size is **`0x465`**, and §0's "~`0x464`-byte" is the figure the rest of the map
should have used. None of these three offsets appears in the §2.2 table.

**X5 — §2.2: `GetControlledObject` "resolves it through the seat/ride container family at
`0x00DF8188`".**
`GetControlledObject` uses `0x00DF81D8` (`0x005DAB0E mov esi, 0xdf81d8`). `0x00DF8188` is
**`ClaimSeat`'s** container (`0x005DEE19 push 0xdf8188`). Two different globals, 0x50 apart; the map
attributes one function's container to another.

**X6 — §7: `DAT_00DFBD77` "has **97 references** binary-wide (its sibling `DAT_00DFBD78` has 122)".**
Instruction-accurate counts are **135** and **164**. The map's numbers are Ghidra xref counts, which
under-report for the same reason Ghidra missed 57 of the 107 bodies. The argument the counts support
(that the global is not boundary-specific) survives; the numbers do not.

### OVERSTATED (5)

**O1 — §1 offers "`FUN_004C15E0` contains zero references to `FUN_004C0EC0`" as proof the pump is not
on the master update.** The fact is true (C22) and I reproduced it, but it cannot distinguish "not on
this path" from "reached virtually", and here it is the latter (X2). A "zero direct references" test
against a function whose whole job is `call [vtbl+0x0C]` is not evidence. The map states the
conclusion at full confidence ("**That link does not exist**") and acts on it across six documents.

**O2 — §2.2 presents `mov esi, 0x00DF9B90` at `0x005DFC61`/`0x005DC5A1` as what settles `+0x158` and
`+0x199`** ("**That was wrong, and the raw bytes settle it**"). The conclusion is right (C17), but
this instruction establishes the **container**, not the object: `ESI` still holds `0xDF9B90` at the
moment of the store, and the store is `mov byte [eax + 0x158], cl`. What settles it is
`call 0x423DC0` (returns *slot) followed by `mov eax, [eax]`. Right answer, wrong load-bearing
evidence — and the same `mov esi, <global>` pattern would read as proof of a *container* field in any
function that stores off `ESI`.

**O3 — §2.2 `+0x24` = "**currently-controlled object** — the ridden vehicle, else 0", confidence H.**
`+0x24` holds a **seat handle**, not an object. `GetSeat` (`0x005DA940`) returns it to Lua verbatim as
lightuserdata; `GetControlledObject` does not dereference it but uses it as a **key** into container
`0x00DF81D8` via `FUN_00648D80`, then indexes `[0xDF81EC]` and `[0xDF81CC]` to obtain the object.
"Resolves to the ridden vehicle" is right; "is the currently-controlled object" at confidence H is
not. The map never mentions `GetSeat`, which is the accessor that names the field.

**O4 — §4: the dirty flag described as "`p[0x11] |= (old != new)` on fuel and upgrade writes".**
Correct for `SetFuel` and `SetProfileUpgrade`, but `AddCash` ORs on **`delta != 0`**, not
`old != new` (`0x005DF567 test ecx,ecx / setne dl`) — so `AddCash(0)` does not dirty, while
`AddCash(n)` dirties even when the clamp makes it a no-op. And the "applied inconsistently" list is
incomplete (M4).

**O5 — §0/§2.3: "The roster is **hard-capped at 2**".** True of the accessors, and the map is careful
to say the cap is compile-time in three places rather than a read of `DAT_017C0DD0`. But the
*container* is capacity **8** (`0xDF9B9C`, static), which the map never states — so a reader planning
co-op/MP-restore work (§9.6 asks exactly this) is told the roster is 2 without being told where the
other constraint actually lives.

### UNVERIFIABLE (2)

**U1 — §7/§9: `DAT_00DFBD77` as "**an engine-wide authority/replication gate, name open**", with the
recurring shape `DAT_00DFBD77 != 0 && (guid & 0xF0000000) == 0x40000000`.**
I can confirm the shape claim's premise (135 refs, overwhelmingly `cmp byte [...], 0`, never written
individually, spread across subsystems) and I found the map's evidence for the boundary early-out.
I could **not** find the `(guid & 0xF0000000) == 0x40000000` conjunction at any of the three sites in
the Player span (`AddBoundary` `0x005DC903`, `RemoveBoundary` `0x005DCA33`, `RemoveAllBoundary`
`0x005DCB31`) — each is a bare `cmp byte [0xdfbd77], 0` followed by an immediate return; the guid
mask may hold elsewhere but is not part of this map's cited sites. Against the "authority/
replication" gloss I have a positive counter-lead the map does not have: the publisher (M7), which
computes it as a **local-player control-state predicate**. That is suggestive, not decisive, because
I cannot name the enum.
**What would settle it:** break on `0x006CEDC4` with the game in four known states (on foot / driving
/ turret / cutscene) and read `[edx+0x0C]`. Note this is a hot per-frame function — per
[[x32dbg-mcp-pitfalls]] use a one-shot or HW breakpoint and let the user drive.

**U2 — `FUN_006CDB70`'s identity** (which the map does not name either, but relies on implicitly via
`SetWaitForInGame`/`IsBoundaryDeath`/`VehicleDisguise`). Reached only through a SecuROM split-thunk
(`jmp dword [0x245F8CC]` -> `0x024E8BD0`; the pointer is identical in `mercs2_nodrm_v1/v2/v3.exe`, so
the no-DRM builds do not resolve it either). I inferred its return type by field-offset triangulation
(§A4), which is strong but is inference.
**What would settle it:** run it through the SecuROM recovery pipeline
([[securom-full-decrypt-recovery-removal]]), or break at `0x005E0522` and compare `EAX` against a
known player pointer.

### MISSING (10) — found by me, absent from the map

**M1 — the container's static parameters are readable without running the game.** `0x00DF9B90` is
fully initialised in `.data`: capacity **8** (`+0x0C`), bucket count **8** (`+0x20`), element stride
**4** (`+0x24`), page shift **3** (`+0x26`), sentinel at `+0x7C` (= the `0xDF9C0C` literal the map
already quotes). §9.8 asks for the object size and §9.6 for the roster bound; half of each answer is
sitting in the file. The map describes the walk but never reads its parameters.

**M2 — `GetCurrentLocalPlayers` is a hardcoded stub returning `1.0f`** (`movss xmm0, [0xB9B664]`), and
`GetMaximumLocalPlayers` returns constant `2.0f` (`[0xB92874]`). Neither queries anything. §3.1 lists
"three cfuncs whose body is not what the name suggests" — these are the fourth and fifth, and
`GetCurrentLocalPlayers` is the more dangerous one, because a reimpl that implements it honestly will
diverge from retail.

**M3 — profile field `+0x25E` = available costumes**, via `GetAvailableCostumes` (`0x005DFB0B`) and
`SetAvailableCostumes` (`0x005DFB98`). §4's table stops at `+0x63`, and §3 lists both bodies as
recovered without stating what they touch. Directly relevant to the wardrobe/costume work the map
cites in §6.

**M4 — `SetFuelCapacity` and `SetAvailableCostumes` also skip the dirty flag.** §4.1 names three
offenders; there are **five**. Since §9.4 proposes this as a fix-pack candidate, an incomplete
enumeration will produce an incomplete fix.

**M5 — `SetCash` and `SetFuel` take an undocumented optional second boolean that suppresses the
write** (`0x005DF4EE`, `0x005DF63E`: `cmp byte [esp+0x10], 0 / jne <return>`), and **`AddCash` clamps
at zero** (`0x005DF571-83`) while `SetCash` does not. A cheat/fix-pack path calling `SetCash` with a
truthy second argument silently no-ops.

**M6 — `SetVehicleDisguise`/`GetVehicleDisguise` are not per-player.** They write/read the global byte
`[0x01176106]` (`0x005E0100`, `0x005E0131`) with no container lookup, unlike `VehicleDisguise` and
`GetVehicleDisguiseState` which do resolve a player. §7's Disguise bullet discusses only the latter
two, so four similarly-named cfuncs are presented as one mechanism when they are two.

**M7 — `DAT_00DFBD77`'s publisher.** `FUN_006CECF0` writes the whole `0xDFBD74..0xDFBD8B` block once
per frame via three `movq`, deriving `0xDFBD76/77/78` as `state == 4 / 1 / 2` off the local player's
controlled object (`0x006CEDC4-DE`). Reached by `FUN_00630EF0 -> FUN_004C16E0 -> FUN_004F5530`. §9
lists the naming as open without a lead; this is the lead.

**M8 — `FUN_0062E7B0` / `FUN_0062E810`.** §1's tree lists five entries under `FUN_004C9740`; these two
are also there and also iterate the player container, calling `FUN_006A1880` per player with the
object in EAX. §9.3 asks whether `FUN_0041FE20` is "the player system tick" or "a human pass that
reads player records" — the existence of a second, unambiguous container iterator in the same list
is material to that question.

**M9 — three player fields and one accessor.** `+0x461` (`SetWaitForInGame`), `+0x463` (`SetInPmc`),
`+0x464` (`SetAimMode`) — see X4 — plus `+0x28` = local id (`GetLocalId` `0x005DE06C`). Also `+0x58`
is read by `IsLocal`/`IsRemote` as the **remote flag**, which the map's §2.2 row (confidence M, "byte
gate on the viewport-id resolve") does not cite and §9.7 asks about.

**M10 — the `player+0x08` indirection.** `IsInWarningZone` does `mov eax, [eax+8]` before reading
`[+0x4F5]`/`[+0x4F7]`, i.e. the player object holds a pointer to a boundary sub-object at `+0x08`.
The map's §2.2 lists `+0x04` as a "list head" at confidence L but not `+0x08`. This is the same trap
that produced [E1] in my own Phase A — an offset read after an unnoticed extra dereference belongs to
a different object.

### Internal-consistency defects (4)

These are not falsifiable claims about the binary, but they are errors a reader will trip on:

1. **§0 contradicts §1.** §0 line 74: *"The player system ticks from the **layer-4 per-system call
   list** at `FUN_0041FE20`"*. §1 retracts exactly that: *"drew the per-system call list as layer 4 of
   the 5-layer master update. **That link does not exist.**"* One paragraph asserts what the next
   withdraws. (Per X2, §0 is the correct one.)
2. **§7 contradicts §3 and the header.** §7 calls `IsBoundaryDeath` and `SetInputEnabled`
   "binding-only", while the header and §3 assert *"There are no binding-only rows left: 107/107
   bodies are read"* and mark both `▨`. Stale wording from before the recovery pass.
3. **§9.5 contains a truncated sentence**: *"Remaining static users:"* followed by a line break and
   the orphan *"ctor `FUN_00A7C7A0`)."* — an unclosed parenthesis and a lost list. For the record, the
   remaining static users of `0x00DF9B10` are `FUN_004C4920, FUN_0051A260, FUN_0051A740, FUN_0051DD07,
   FUN_0051E1A7, FUN_0051F520, FUN_0051F5C0, FUN_0052D7F0, FUN_00585840, FUN_0066B710, FUN_006A4060,
   FUN_00A7C7A0, FUN_00B00C70` plus `FUN_005CE7E0` (`SetInfiniteAmmo`).
4. **Size stated three ways.** §0 "~`0x464`-byte", §2.2 "Minimum size `0x461`", §9.8 "largest observed
   offset is `+0x460`". Correct answer: at least `0x465` (X4).

---

## What I could not check, and why

* **No live/dynamic verification.** Everything is static. I did not attach x32dbg (the standing rule
  is that the *user* drives execution, and this was an unattended run), so every claim about
  *runtime* values — the live count at `0xDF9BA8`, the page table at `0xDF9C00`, the resolved value
  of `[0x01176054]` — is a claim about the **static initialiser or the code that reads it**. The
  capacity/stride/shift numbers could in principle be re-parameterised at construction time; I saw no
  such write but did not exhaustively prove its absence. This means the map's entire §9 confirm-live
  inventory is **untouched by this validation** — items 1, 2, 3, 4, 6, 7 and 8 remain open exactly as
  the map leaves them.
* **`FUN_006CDB70` (U2)** and the `0x00DF81D8` seat container were not chased to their bodies. I
  established `0xDF81D8`'s *role* from `GetControlledObject`'s use of it, not from its class.
* **The `[ctrl + 0x0C]` enum (U1)** is not named.
* **I did not read the DLC/`luacd` corpora or the Xbox PDB**, so I did not check the map's script
  call-site counts (the `calls` column in §3, the "1054 of 1405" traffic claim in §10.4), its Xbox
  symbol claims (§0.5, §11), or its Lua-layer boot chain (§8). Those are ~120 further numbers this
  document does not cover.
* **§6's ECS component registrars** (`FUN_00640410`, `FUN_006413F0`, `FUN_00643D50`) and §5's
  `FUN_006A4060` attach body were verified only to the extent of the `0x00DF9B10` reference (C19);
  I did not re-derive the registrar shape, the element sizes, or the attach sequence.
* **Roughly 60 of the 107 bodies** (the PDA-map, satellite-scan and boundary families) I
  characterised only by their field offsets and callee addresses, not by full behavioural analysis.
* **`vz.wad` / `mercs2_probe` were not exercised** — the subject is exe-resident state.

## Reproduction

```
python <scratch>/pv/pe.py          # harness: v2f(), rd(), u32(), cstr(), disraw()
python <scratch>/pv/idx.py         # linear-disasm call graph + memref index (idx.pkl)
python <scratch>/pv/scan.py 0xDF9B90 0xDF9B10
```

| question | check |
|---|---|
| is the pump layer 4? | `disraw(0x4C1170, 0x120)` — read the five `mov [eax*4+0x17bbccc]` stores |
| is `0x4C13A0` the frame path? | `disraw(0x631A50, 0xA0)` — the `call 0x4c13a0` sits after the loop-back `je` |
| how many inliners? | count `mov ecx, 0xdf9b90` / `mov esi, 0xdf9b90` sites within `0x5DA7A0..0x5E0490` |
| is `+0x158` on the object? | `disraw(0x5DFC5D, 0x30)` — `call 0x423dc0`, `mov eax,[eax]`, then the store |
| object minimum size? | `disraw(0x5DFEA1, 0x10)` — `mov byte [eax + 0x464], cl` |
| dirty-flag set? | grep each setter body for `or byte ptr [e?? + 0x11]` |
| binding table intact? | parse §3's 107 rows and diff against a `.rdata` walk of `0x00B98FC0` |

---

# Pass 2 — closing the register

**Date:** 2026-07-26 · **Scope:** every item Pass 1 did not close as a plain CONFIRMED, plus its
"What I could not check" list. **Method:** Pass 1's verdicts and reasoning were treated as
*untrusted* and every item re-derived from primary sources. Where the map and Pass 1 disagreed,
neither was adopted — both were re-derived.

**Harness** (`<scratch>/p2/`, independent of Pass 1's):

```
pe.py      PE reader + capstone over output/_ghidra/securom_dump/mercs2_unpacked.exe
           (VA->file through the section table; adds thunk() = jmp [SLOT] -> deref -> disasm)
gpe.py     same, over genuine_patched_unpacked.exe — used ONLY for anchor-matched
           cross-build corroboration, never for byte substitution
idx.py     linear-disasm index: 42 573 Ghidra starts + the 107 Player cfuncs + every cfunc of
           all 31 namespace tables = 43 027 starts -> 85 690 call edges, 438 905 referenced addrs
bodies.py  all 107 Player cfunc bodies, classified by resolve path
taint.py   register-taint over each body: separates PLAYER+off from SUB(off)+off
count_calls*.py  script call-site census over docs/mercs2-luacd/ + docs/mercs2-dlc-luacd/
names.py   the container master key: container[0] = vtable, [vtable+0x34] = `mov eax,<char*>; ret`
```

Independently reproduced before anything else: registry `0x00DFD478` = 31 rows x 12 B terminating
at `0x00DFD5EC`; row 4 = `"Player"` -> `0x00B98FC0`; that table walks to a NULL terminator at
`0x00B99318` = **107 rows**.

---

## Phase 0 — the open register

48 items, mechanically extracted from Pass 1's CONTRADICTED / OVERSTATED / UNVERIFIABLE / MISSING /
internal-defect / errata sections and its "What I could not check" list, plus the items named in the
Pass-2 brief.

| # | Item (source) | Pass-2 verdict |
|--:|---|---|
| 1 | X1 `FUN_004C13A0` is the shutdown path, not the frame path | CONFIRMED |
| 2 | X2 the pump **is** layer 4, reached by virtual dispatch | CONFIRMED |
| 3 | X3 "eight inliners" -> real count | CONFIRMED (47) |
| 4 | X4 `+0x461`/`+0x463`/`+0x464`; min size `0x465` | CONFIRMED |
| 5 | X5 `GetControlledObject`'s container: `0x00DF81D8` (P1) vs `0x00DF8188` (map) | **P1 CONTRADICTED — the map is right** |
| 6 | X6 `DAT_00DFBD77`/`78` reference counts | CONFIRMED map undercounts; new counts 137 / 171 |
| 7 | O1 "zero static refs" cannot disprove a virtual edge | CONFIRMED |
| 8 | O2 `mov esi, <global>` establishes the container, not the object | CONFIRMED |
| 9 | O3 `+0x24` "currently-controlled object" at conf H | **P1 PARTLY CONTRADICTED** |
| 10 | O4 `AddCash` dirties on delta, not old!=new | CONFIRMED **+ P1 incomplete** (`AddFuel` too) |
| 11 | O5 container capacity 8 unstated by the map | CONFIRMED value, **framing CONTRADICTED** |
| 12 | U1 `DAT_00DFBD77`'s identity | **CLOSED — `Net.IsClient`** |
| 13 | U2 `FUN_006CDB70`'s identity | **CLOSED — `GetPlayerForCharacter`** |
| 14 | M1 container static parameters | CONFIRMED values, **framing CONTRADICTED** |
| 15 | M2 `GetCurrentLocalPlayers` = const `1.0f`, `GetMaximumLocalPlayers` = const `2.0f` | CONFIRMED |
| 16 | M3 profile `+0x25E` = available costumes | CONFIRMED |
| 17 | M4 five setters skip the dirty flag | CONFIRMED |
| 18 | M5 `SetCash`/`SetFuel` optional 2nd boolean suppresses the write | CONFIRMED (+ new: no shipped caller) |
| 19 | M6 `Set/GetVehicleDisguise` are a global byte, not per-player | CONFIRMED (+ new: `Object.IsDisguised` shares it) |
| 20 | M7 the `0xDFBD74` block publisher | publisher CONFIRMED, **its semantics CONTRADICTED** |
| 21 | M8 `FUN_0062E7B0` / `FUN_0062E810` in the layer-4 list | CONFIRMED (and they are the real player tick) |
| 22 | M9 `+0x28` local id, `+0x58` remote flag, `+0x461/3/4` | CONFIRMED |
| 23 | M10 the `player+0x08` indirection | CONFIRMED |
| 24 | D1 §0 contradicts §1 | RESOLVED in the current map revision |
| 25 | D2 §7 still calls `IsBoundaryDeath`/`SetInputEnabled` "binding-only" | DEFECT STILL PRESENT |
| 26 | D3 §9.5 truncated sentence | DEFECT STILL PRESENT |
| 27 | D4 object size stated three ways | DEFECT STILL PRESENT; answer >= `0x465` |
| 28 | E1 `+0x4F5`/`+0x4F7` sit on `player+0x08` | CONFIRMED **+ a second P1 extractor error found** |
| 29 | W4a the 107 script call-site counts in §3 | **CONFIRMED 107/107 exactly**; corpus provenance wrong |
| 30 | W4b §10.4 "1054 of 1405", 26 zeros, the top ten | CONFIRMED exactly |
| 31 | W5 Xbox claims §0.5 / §7 / §11 | 4 CONFIRMED, the Scope claim CONTRADICTED |
| 32 | W6 the §8 Lua boot chain | one hard error + two omissions |
| 33 | W7a §6 ECS registrars | CONFIRMED + `ModelMixerProfile` completed |
| 34 | W7b §5 `FUN_006A4060` attach body | CONFIRMED + cheat gate named by hash |
| 35 | W8 "~60 bodies characterised but not read" | CLOSED — all 107 disassembled and classified |
| 36 | W9 `vz.wad` / `mercs2_probe` not exercised | N/A — subject is exe-resident (agreed) |
| 37 | §9.1 semantics of the four flagged cfuncs | CLOSED |
| 38 | §9.2 the write that populates `player+0x24` | **STILL-OPEN (S1)** |
| 39 | §9.3 `FUN_0041FE20`'s identity | CLOSED — it is *not* the player tick |
| 40 | §9.4 the profile dirty-flag reader | CLOSED — it gates **autosave** |
| 41 | §9.5 `0x00DF9B10`'s element layout | CLOSED — 1 byte; premise of the question was wrong |
| 42 | §9.6 the 2-player cap | CLOSED |
| 43 | §9.7 `player+0x58` | semantic CLOSED; **writer STILL-OPEN (S2)** |
| 44 | §9.8 player object total size | CLOSED — >= `0x465` |
| 45 | §10 "`player.rs` holds 107 names with `install` unfilled" | CONTRADICTED |
| 46 | every bare container address in the map, named via `vtable+0x34` | CLOSED — 15 named |
| 47 | `player+0x450`'s hash constant `0xFA62754E` | CLOSED — `hash_m2("PDA")` |
| 48 | the hash constants `0x892CF579` / `0x223F6FDA` / `0x57B5E35A` | **STILL-OPEN (S3)** |

**Closed: 45 · Still-open: 3.**

---

## The headline results

### P2-1 · `DAT_00DFBD77` is `Net.IsClient`. The whole byte block is the network-session snapshot.

Three maps gave three readings; the answer was one table away. The `Net` namespace
(`luaL_Reg` `0x00B998D0`, 92 rows) exposes five consecutive accessors, each a five-instruction
template `mov bl, byte [ADDR]` -> push boolean, over five consecutive bytes:

| addr | Net cfunc | VA | body |
|---|---|---|---|
| `0xDFBD74` | **`Net.IsEnabled`** | `0x005C6710` | `0x005C6711 mov bl, byte [0xdfbd74]` |
| `0xDFBD75` | **`Net.IsActive`** | `0x005C6750` | `0x005C6751 mov bl, byte [0xdfbd75]` |
| `0xDFBD76` | **`Net.IsLobby`** | `0x005C6790` | `0x005C6791 mov bl, byte [0xdfbd76]` |
| **`0xDFBD77`** | **`Net.IsClient`** | `0x005C67D0` | `0x005C67D1 mov bl, byte [0xdfbd77]` |
| **`0xDFBD78`** | **`Net.IsServer`** | `0x005C6810` | `0x005C6811 mov bl, byte [0xdfbd78]` |

`Net.IsMultiplayer` (`0x005C66C0`) is the conjunction: `cmp byte [0xdfbd74],1` / `cmp byte [0xdfbd75],bl`.
Five consecutive bytes, five consecutive table rows, five byte-identical templates — this cannot coincide.

The publisher `FUN_006CECF0` (Pass 1's M7) is confirmed but **misread**. `edi+0x24` is the
**net-session object**, not the local player's controlled object, and `[obj+0x0C]` is the session
**role enum**:

```
0x006cedc1  mov  edx, [edi + 0x24]        ; the net-session object
0x006cedc4  mov  eax, [edx + 0xc]         ; role enum
0x006cedc7  cmp  eax, 4 ; sete cl  -> [esp+0x16] -> 0xDFBD76  IsLobby
0x006cedcd  cmp  eax, 1 ; sete dl  -> [esp+0x17] -> 0xDFBD77  IsClient
0x006cedda  cmp  eax, 2 ; sete al  -> [esp+0x18] -> 0xDFBD78  IsServer
0x006ceeb4  movq xmm0, [esp+0x14] ; 0x006ceeba movq [0xdfbd74], xmm0   (+ two more movq @EEC8/EED6)
```

`FUN_006CFF40` reads the same `[edx+0x0C]` and branches `1` -> client object `[eax+0x28]`,
`2`/`3` -> server object `[eax+0x24]`. **So the `[ctrl+0x0C]` enum (Pass 1's U1) is a net-session
role: 1 = client, 2 = server/host, 3 = (server variant), 4 = lobby.** No breakpoint needed.

The map's §7 gloss "an engine-wide authority/replication gate, name open" was *directionally right
and is now named*: `DAT_00DFBD77` = "this machine is a network **client**", `DAT_00DFBD78` = "this
machine is the **server**". `AddBoundary` / `RemoveBoundary` / `RemoveAllBoundary` early-out on
`IsClient` because boundary state is server-authoritative. Pass 1's counter-hypothesis
("local player's controlled-object state == 1") is **CONTRADICTED**.

Instruction-accurate reference counts (43 027-start linear index): `0xDFBD74` **115**, `75` **57**,
`76` **1**, `77` **137**, `78` **171**, `79` **1**. None of the six is ever written individually
anywhere in the image — 0 stores across `0xDFBD70..0xDFBD90`. The map's 97 / 122 are Ghidra xrefs
and undercount; Pass 1's 135 / 164 undercount slightly less (its index carried ~450 fewer starts).

### P2-2 · `FUN_006CDB70` = `GetPlayerForCharacter(charGuid) -> Player*`

Pass 1 filed this UNVERIFIABLE. It is closable statically, four independent ways.

**Slot deref, as required.** `0x006CDB70: jmp dword ptr [0x245F8CC]` -> `[0x0245F8CC] = 0x024E8BD0`
-> `0x024E8BD0: push 0x24e8bda ; call 0x1aaff10` — a VM stub, and the decomp confirms it
(`FUN_024e8bd0 @0x024e8bd0 size=10 -> thunk_FUN_02a30028(...)`). The body is genuinely
VM-executed, so it was identified by behaviour instead:

1. **Call convention.** Every one of its 33 call sites does `mov eax, <guid>` then `call 0x6cdb70`
   with no stack argument and no `add esp` — one register argument, returns `0` or a pointer.
2. **The returned object is a `Players` record.** `SetWaitForInGame` (`0x005DF1C4`) writes
   `[ret+0x461]`; `SetInPmc` (`0x005DFD95`) and `SetAimMode` (`0x005DFEA5`) write `[obj+0x463]` and
   `[obj+0x464]` on an object reached by `mov esi,0xDF9B90 ; call 0x423DC0 ; mov eax,[eax]`.
   Three adjacent bytes on the same struct.
3. **Field idioms agree.** `IsBoundaryDeath` reads `[ret+0x30] == -1`, `[ret+0x58]`, `[ret+0x66]`,
   `[ret+8]->[+0x4F5]`; `IsJoined`/`IsLocal`/`IsRemote` and `FUN_006A0770` read exactly the same
   `+0x30`/`+0x58` pair off container-resolved records.
4. **The Lua side splits cleanly, 6/6.** Every cfunc on the `Players`-container path is passed a
   **player** guid; every cfunc on the `FUN_006CDB70` path is passed a **character** guid:

| cfunc | resolve | Lua call site |
|---|---|---|
| `SetAimMode` | container | `Player.SetAimMode(Player.GetLocalPlayer(), true)` `mrxutil.lua:671` |
| `SetHealthClamp` | container | `Player.SetHealthClamp(uPlayer, true)` `hero.lua:195` |
| `SetGrappleEnabled` | container | `for _,uGuid in ipairs(Player.GetAllPlayers())` `mrxmissionflow.lua:706` |
| `IsBoundaryDeath` | **6CDB70** | `Player.IsBoundaryDeath(uChar)` `mrxplayer.lua:342` |
| `SetWaitForInGame` | **6CDB70** | `Player.SetWaitForInGame(uHero)` `mrxutil.lua:194` |
| `VehicleDisguise` / `GetVehicleDisguiseState` | **6CDB70** | `{Player = uRider}` where `uRider = Player.GetLocalCharacter()` `wiftutorialvehicledisguise.lua:16,35` |

**Cross-build corroboration** (not substitution): the genuine build's `Player` table sits at the same
`.rdata` VA `0x00B98FC0`; its `IsBoundaryDeath` (`0x005DD030`) is instruction-for-instruction
identical to retail's and calls `0x006CDD10` — which is *also* a SecuROM thunk there
(`jmp dword ptr [0x24D5F98]`). Both builds VM the same function; the genuine image gives no shortcut.

**Consequence for the map:** the `Player = ...` key in `VehicleDisguise`/`GetVehicleDisguiseState`'s
Lua argument table is a **character** guid, not a player guid. A reimpl that models these four
bindings as taking a player handle will silently fail.

### P2-3 · X5 re-derived — the map is right and Pass 1 is wrong

`GetControlledObject` does `0x005DAB0E mov esi, 0xdf81d8 ; call 0x648d80`, then indexes `[0xDF81EC]`
and `[0xDF81CC]`. Pass 1 read `ESI` as the container base and declared the map wrong. It is not the base.
The generic form is `FUN_0042BF80`:

```
0x0042bf82  lea  esi, [edi + 0x50]      ; edi = CONTAINER BASE
0x0042bf88  call 0x648d80               ; FUN_00648D80(this = base+0x50, key)
0x0042bf95  mov  ecx, [edi + 0x64]
0x0042bf9b  mov  eax, [edi + 0x44]
```

`0xDF81D8 = 0xDF8188 + 0x50`, `0xDF81EC = 0xDF8188 + 0x64`, `0xDF81CC = 0xDF8188 + 0x44` — all three
line up on base **`0x00DF8188`**, which names itself **`SeatLink`** (`[[0x00DF8188]+0x34]` =
`FUN_006418E0` = `mov eax,"SeatLink"; ret`). `FUN_00648D80` is the open-addressing guid->index probe
whose `this` is the embedded hash table at `base+0x50` — the same idiom `FUN_006496B0` performs for
`Players` with `this` = the base itself. **Pass 1's X5 is retracted; the map's §2.2 wording stands.**

### P2-4 · The 107 script call-site counts are exactly right — the *provenance* is not

`Player\.<Name>\s*\(` over **`docs/mercs2-luacd/src` (370) + `docs/mercs2-dlc-luacd` (75)**:
**107 / 107 rows match the map's `calls` column exactly**, total **1405**, **26** zero-call rows,
top-ten sum **1054** (75.0 %), remaining 97 = 351. Every §3 and §10.4 traffic number is CONFIRMED.

Ruled out by construction: the same regex over luacd alone gives 1113 and matches only 54/107; a
*reference* count (no `(`) over both corpora gives 1439 and matches 95/107. So the census is
**call sites over both corpora**. The map's Sources block says "the 370 decompiled scripts in
`docs/mercs2-luacd/`" — that is wrong by 75 files, and anyone re-running it as written will get 1113.

### P2-5 · `FUN_0041FE20` is *not* the player system tick

`FUN_0062E7B0` and `FUN_0062E810` are both in `FUN_004C9740`'s list, both have `FUN_004C9740` as
their **sole** caller, and both walk the `Players` container by dense index passing `dt`:

```
0x0062e7b1  mov eax, [0xdf9ba8]          ; live count
0x0062e7c1  mov cl,  [0xdf9bb6]          ; the container walk, inlined
0x0062e7f0  mov eax, [eax]               ; -> player object
0x0062e7f6  call 0x6a1880                ; per-player update, this in EAX   (0x62E856 -> 0x6a0770)
```

Both callees take the player object in **EAX** and open on player fields — `FUN_006A1880` reads
`+0x20`, `+0x66`, `+0x45C` and queries the character's `RuntimeHealth` (`0x017BEF78`);
`FUN_006A0770` reads `+0x20`, `+0x30`, `+0x58`, `+0x2C`. These are the roster tick.
`FUN_0041FE20` reaches player records through a **generic iterator** (`FUN_00423B70`) and never
touches `0xDF9BA8`. §0's "The player system ticks from the layer-4 per-system call list at
**`FUN_0041FE20`**" names the wrong function; §9.3's question is answered without a breakpoint.

### P2-6 · The profile dirty flag gates **autosave** — the missing ORs are a shipped bug

§9.4 asked whether `+0x11` gates anything. It does. `FUN_00614540` — the function that carries the
string literals `"autoSave"` (`0x00BBC4E8`) and `"mustBeSignedInToLive"` — reads it and, only if set,
calls the save:

```
0x0061488c  mov eax, [0x1176054]
0x00614891  cmp byte [eax + 0x11], 0     ; dirty?
0x00614895  je  0x6148ce                 ; ... no -> skip
0x00614897  cmp byte [eax + 0x25f], 0
0x006148a0  push 0xbbc4e8 ("autoSave") ; push 0xedb070 ; call [0xb052d8]
0x006148b7  mov ecx, [0x1176054] ; mov eax, -2 ; call 0x634460   ; <-- the save
```

A second reader is `0x00635D95` (`cmp byte [ebx+0x11], 0`) in `FUN_00635CF0`, likewise on a save path.
So the **five** setters that never OR the flag — `SetCash`, `SetFuelCapacity`, `SetProfileCharacter`,
`SetProfileCostume`, `SetAvailableCostumes` — can leave a real change unsaved. §9.4's fix-pack
candidate is promoted from *hypothesis* to *proven*.

### P2-7 · §9.5's premise is wrong: `0x00DF9B10` is not shared by two unrelated features

Container header at `0x00DF9B10`: `+0x0C` capacity `0x100`, `+0x20` buckets `0x80`,
**`+0x24` element size = 1 byte**, `+0x26` shift 7, `+0x28` seed `0x9E3779B9`. The element is a
single byte — there is no sub-struct and the two `0` arguments to `FUN_00649180` do not select a
field. And the two writers are the **same feature**: the container names itself
**`CheatInfiniteAmmo`**, `Object.SetInfiniteAmmo` sets the cheat, and `FUN_006A4060` re-applies that
same cheat to a new body. There is no clobber bug and the container is not a "per-entity marker
container that at least two unrelated features write".

**The attach-path cheat gate, named by hash** (`tools/pandemic_hash.py`, `pandemic_hash_m2`,
matched against real candidates — never invented). `FUN_004C2C20` is a config lookup by name hash
(`push <hash32>; call 0x826820`):

| global | hash pushed | name | evidence |
|---|---|---|---|
| `DAT_01175F59` | `0x949A9B14` | **`"demo"`** | also read by `Sys.IsDemoMode` `0x005E5679` |
| `DAT_01175F5A` | `0x40B39AC0` | **`"godmode"`** | Xbox `debug-cheat-menu.md` "God Mode" |
| `DAT_01175F5B` | `0x4299D698` | **`"unkillable"`** | Xbox "Demigod Mode" |
| `DAT_01175F5C` | `0xF2E44D84` | **`"infammo"`** | gates `Object.SetInfiniteAmmo` `0x005CE86D` |
| `DAT_01175F5D` | `0xE79B0021` | **`"showgodmode"`** | Xbox "Show God Mode Et Al" |

So §5's gate reads `infammo || demo`, and the sibling call `FUN_005262D0` is gated on
`godmode || demo` plus `unkillable`. The map's gloss "cheat toggles, not mode bytes" is right for
`0x1175F5C` and **wrong for `0x1175F59`**, which is the demo-mode flag.

Also named in that body: `0x017C0238` = **`RtDamageFlags`** (the "two world flag words" the map
leaves anonymous), and the seat probe `esi = 0xDF9160` resolves on base `0x00DF9110` =
**`RuntimePhysicalLink`** (`[0xDF9174]`/`[0xDF9154]` are its `+0x64`/`+0x44`).

---

## The container master key — every bare address in the map, named

`container[0]` = vtable; `[vtable+0x34]` = `mov eax,<char*>; ret`.

| address | vtable | name fn | **name** |
|---|---|---|---|
| `0x00DF9B90` | `0x00BC3FB8` | `0x00647BA0` | **`Players`** |
| `0x00DF9B10` | `0x00BC3F48` | `0x00647B90` | **`CheatInfiniteAmmo`** |
| `0x00DF8188` | `0x00BBFD10` | `0x006418E0` | **`SeatLink`** (`0x00DF81D8` = `+0x50`, not a container) |
| `0x00DF8208` | `0x00BBFDD8` | `0x006419A0` | `EntranceLink` |
| `0x00DF6C08` | `0x00BC4870` | `0x0063E060` | `ModelName` (`SetOutfit`) |
| `0x00DF9110` | `0x00BC1F90` | `0x00644680` | `RuntimePhysicalLink` |
| `0x00DF9190` | `0x00BC2008` | `0x00644690` | `RuntimeConstraintLink` |
| `0x017C0238` | `0x00BC3EF8` | `0x00647B80` | `RtDamageFlags` |
| `0x017BCEF8` | `0x00BBEFD0` | `0x006404B0` | `ControllerPlayer` |
| `0x017BD5D8` | `0x00BBF9F0` | `0x00641490` | `VehicleDisguiseScale` |
| `0x017BE848` | `0x00BC1A68` | `0x00643DF0` | `GrappleParameters` |
| `0x017BE708` | `0x00BC1748` | `0x00643AE0` | **`ModelMixerProfile`** (§6 leaves this row "—") |
| `0x017BCF98` / `0x017BCFE8` / `0x017BD038` / `0x017BD088` / `0x017BD0D8` / `0x017BD128` | — | — | `ControllerCar` / `ControllerBoat` / `ControllerTank` / `ControllerLW` / `ControllerHelicopter` / `ControllerLadder` |
| `0x017BEF78` | `0x00BC24D8` | `0x00644CC0` | `RuntimeHealth` |
| `0x017BD808` / `0x017BF888` | — | — | `SeatParameters` / `PhysicsActor` |

---

## Resolve-path census — the real inliner count (X3)

All 107 bodies disassembled, bounded by the next known function start, and classified:

| path | count |
|---|---|
| inlines the walk (`mov ecx, 0xDF9B90`) | **23** |
| calls `FUN_00423DC0` (`mov esi, 0xDF9B90`) | **24** |
| — **union taking a player handle through `Players`** | **47** |
| calls `FUN_006CDB70` (takes a **character** handle) | **4** |
| by index: `FUN_006CDAF0` / `FUN_006CD960` / `FUN_006CDAC0` | 24 / 3 / 1 |
| profile singleton `[0x01176054]` only | 16 |
| no resolve (constants, callbacks, `ClaimSeat` family, `SetOutfit`) | 20 |

The 23 inliners: `ClearGPS, ClearPlayerDB, GetAllBoundaryGuid, GetCamera, GetCameraXZHeading,
GetCharacter, GetControlBindingType, GetControlledObject, GetOutBoundary, GetPlayerId,
GetRetryPosition, GetSeat, GetTargetUnderReticle, GetViewport, GetViewportId, InCinematicMode,
IsInWarningZone, IsPositionOutBoundary, RequestPDAMapModeCancel, SetCinematicMode,
SetSeatMovementLocks, SetSwimmingSearchRadius, SetVehicleControlsLock`.
The map's list of eight is a strict subset of these. **X3 CONFIRMED at 47, not 8.**

---

## Player-object layout — consolidated, with the indirection separated

Offsets read **directly off the resolved player object**. The `SUB` rows are the trap that produced
Pass 1's [E1]: the value is loaded from the player and then dereferenced again.

| off | field | read from | note vs. map |
|---|---|---|---|
| `+0x04` | list head | `FUN_006A4060` | map has it (L) |
| **`+0x08`** | **pointer to the boundary sub-object** | `GetOutBoundary` `0x005DC7D6`, `IsInWarningZone`, `IsBoundaryDeath` `0x005DD0D2` | **missing from the map** |
| `+0x1C` | own guid (the Lua handle) | `GetPrimaryPlayer`/`GetSecondaryPlayer`/`GetPlayer`/`GetAllPlayers`/`GetLocalPlayer`/`DestroyPlayer`/`TeleportCamera` | ok |
| `+0x20` | attached character guid | `GetCharacter`, `GetLocalCharacter`, `DetachFromCharacter`, `FUN_006A1880`, `FUN_006A0770` | ok |
| `+0x24` | controlled-entity guid — a **`SeatLink`** key | `GetSeat` (returns raw), `GetControlBindingType`, `GetControlledObject` | ok (see O3 below) |
| `+0x28` | local id | `GetLocalId` `0x005DE06C` | **missing** |
| `+0x2C` | player index (roster key) | `GetPlayerId` `0x005DDD02`, `IsLocal`, `FUN_006CDAF0` | ok |
| `+0x30` | join/viewport id, `-1` = not joined | `IsJoined`, `IsLocal`, `IsRemote`, `GetViewport(Id)`, `IsCoopMultiplayer`, `GetAllTargetMarkerPos` | ok |
| **`+0x58`** | **remote flag** (0 = local, !=0 = remote) | `IsLocal` `0x005DDE9E`, `IsRemote` `0x005DDF41` | map says "byte gate", conf M — **it is the remote flag, conf H** |
| **`+0x66`** | state byte, compared `== 4` | `IsBoundaryDeath` `0x005DD0C3`, `FUN_006A1880` `0x006A1896` | **missing** |
| `+0xBC` | probe block | `FUN_0041FE20` | ok |
| `+0x11C` / `+0x124` / **`+0x12C`** | reticle guid / payload / third word | `GetTargetUnderReticle` | `+0x12C` missing |
| **`+0x148`** | retry position | `GetRetryPosition` | **missing** |
| `+0x158` | grapple enabled (byte) | `SetGrappleEnabled` `0x005DFC85` | ok |
| **`+0x180` / `+0x198`** | survival mode | `FUN_006A2340` | **missing** |
| `+0x199` | health clamp (byte) | `SetHealthClamp` `0x005DC5C5` | ok |
| **`+0x19C` / `+0x1B8`** | scope refcount / scope sub-object | `FUN_006A21E0` (`SetScopeEnabled`) | **missing** |
| `+0x1BC` | attachment count | `FUN_006A4060` | ok |
| **`+0x1A8` -> SUB** | PDA-map-mode sub-object (`+0x30/34/38/3C/40/44/48/49` live on it) | `SetPDAMapModeCallback`, `RequestPDAMapModeCancel` `0x005DB658` | **missing** |
| **`+0x1AC` -> SUB** | satellite-scan sub-object (`+0x0C/14/28/2C/34`) | `AddSatelliteScanTarget`, `SetSatelliteScanPaused` | **missing** |
| **`+0x1B4`** | cinematic-mode counter | `InCinematicMode` `0x005DC146` | **missing** |
| `+0x244` / `+0x245` | input enabled | `SetInputEnabled` `0x005DC364/36A` | **missing** |
| `+0x380` / `+0x384` | boundary callback + ctx | `SetBoundaryCallback` `0x005DCE44/4A` | ok |
| `+0x390` / **`+0x398`** | PDA widget id / GPS slot | `FUN_005BA500`, `FUN_006A0FB0` (`ClearGPS`) | `+0x398` missing |
| `+0x3A8` | vehicle-disguise sub-struct | `GetVehicleDisguiseState` | ok |
| `+0x430` / `+0x434` / `+0x438` | vehicle-disguise fields | `VehicleDisguise` | ok |
| **`+0x450`** | **widget-type hash, compared to `pandemic_hash_m2("PDA")` = `0xFA62754E`** | `FUN_005BA500` | map: "role unknown, L/open" — **CLOSED** |
| **`+0x454`** | target-marker field | `GetAllTargetMarkerPos` | **missing** |
| `+0x45C` | tick gate (byte) | `FUN_006A1880` `0x006A18CF/190C` | **missing** |
| `+0x45D`/`E`/`F` | seat movement locks | `SetSeatMovementLocks` `0x005DD295-A1` | ok |
| `+0x460` | vehicle controls lock | `SetVehicleControlsLock` `0x005DD3F2` | ok |
| **`+0x461`** | wait-for-in-game latch (set to 1 only) | `SetWaitForInGame` `0x005DF1C4` | **missing** |
| **`+0x463`** | in-PMC | `SetInPmc` `0x005DFD95` | **missing** |
| **`+0x464`** | aim mode | `SetAimMode` `0x005DFEA5` | **missing** |

On the `+0x08` sub-object: `+0x4F5` (out-of-boundary), `+0x4F7` (warning zone).

**Minimum player-object size = `0x465`.** §0's "~`0x464`-byte" is closest; §2.2's "`0x461`" and
§9.8's "largest observed offset is `+0x460`" are both wrong (D4).

---

## Verdicts on the remaining register items

**#1–#2 (X1, X2) — frame chain, re-derived from scratch and CONFIRMED.**
`FUN_004C1170` writes five layers into `0x017BBCCC`: `0xD6C22C`(0), `0x014538B8`(1), `0x0149FDA0`(2),
`0xD6C238`(3), **`0xD6C244`(4)**, count `[0x17BBCF4]=5`, pivot `[0x17BBCFC]=4`. `[0x00D6C244] =
0x00BB0460`; `[0x00BB046C] = 0x004C09C0`. `FUN_004C15E0` dispatches `mov edx,[eax+0xC] ; mov ecx,esi ;
call edx` at `0x004C1633/163C` — `this` in ECX, dropped by Ghidra. The main loop body is
`call 0x630EF0` @`0x00631938`, back-edge `je 0x631938` @`0x00631A99`; `call 0x4C13A0` @`0x00631AAF`
sits after it **and** after `call [0xB05198]` (`ReleaseMutex`). `FUN_004C13A0` forces
`[0xD6C24C] = 3` at `0x004C13C3` before calling the pump with `fldz`. `FUN_004C09C0` dispatches on
`[ecx+8]`: 1 -> `0x4C0BC2`, 2 -> `0x4C0A5A`, 3 -> teardown (sets state 4); the **only** `call 0x4c0ec0`
is at `0x004C0B6A`, inside the state-2 arm. Static callers: `4C09C0<-{4C13A0}`, `4C0EC0<-{4C09C0}`,
`4C9740<-{4C0EC0}`, `41FE20<-{4C9740}`. The map's §1 (as currently written) is correct.

**#9 (O3) — `+0x24`, both prior readings refined.** `GetControlBindingType` (`0x005DD430`, the
largest of the recovered bodies) takes `[player+0x24]` and probes six controller components in order,
returning a string:

| container | component | returns |
|---|---|---|
| `0x017BCF98` | `ControllerCar` | `"car"` |
| `0x017BD038` | `ControllerTank` | `"tank"` |
| `0x017BD0D8` | `ControllerHelicopter` | `"helicopter"` |
| `0x017BD088` | `ControllerLW` | `"livingworld"` |
| `0x017BCFE8` | `ControllerBoat` | `"boat"` |
| `0x017BD128` | `ControllerLadder` | `"ladder"` |

So `+0x24` is the guid of **the entity currently supplying the player's control bindings** — a
`SeatLink` key that `GetControlledObject` resolves to the ridden vehicle, and that `GetSeat` returns
raw. The map's "currently-controlled object" is defensible; Pass 1's "a seat handle, **not** an
object" over-corrected. Both should say: *a guid that is a `SeatLink` key and carries a `Controller*`
component*. Pass 1's point that the map never mentions `GetSeat` stands.

**#10 (O4) — and Pass 1 is itself incomplete.** `AddCash` `0x005DF567 test ecx,ecx / setne dl /
or [eax+0x11],dl` — dirties on **delta != 0**; then clamps (`if ecx<0 && -ecx > cash: cash=0, ecx=0`).
`AddFuel` `0x005DF6D3` does the **same** — `test ecx,ecx / setne cl / or [eax+0x11],cl` — and
**also clamps at zero** (`add [eax+0x30],ecx ; jns ; mov [eax+0x30],0` at `0x005DF6C7-D3`). Pass 1
attributed the clamp to `AddCash` alone.

**#11 / #14 (O5, M1) — values right, framing wrong.** `Players` at `0x00DF9B90`: `+0x0C` = 8,
`+0x20` = 8 buckets, `+0x24` = 4-byte element (a pointer), `+0x26` = shift 3, `+0x28` seed
`0x9E3779B9`. Two corrections to Pass 1's M1:

* **`0x00DF9B9C` (`+0x0C`, "capacity") has ZERO references binary-wide.** Nothing reads it. It
  bounds nothing. The only enforced bounds are the three compile-time `2`s
  (`FUN_006CDAF0` `cmp [esp+4],1 / ja`; `FUN_006CDAC0` `cmp esi,2`; `FUN_006CD960` `cmp [esp+8],2 / jl`)
  and `DAT_017C0DD0` = 2, which is only *reported* by `GetMaximumPlayers`. §2.3 and §9.6 are correct.
* **Containers ARE re-parameterised at runtime.** `FUN_00640410` registers `ControllerPlayer` with
  capacity `0x100`, shift `8`, buckets `0x100`; the dumped container at `0x017BCEF8` reads capacity
  `0x60`, shift `5`, buckets `0x20`. So Pass 1's caveat ("could in principle be re-parameterised...
  I saw no such write") resolves to **yes, this happens**, and the `Players` numbers are
  "as observed in this dump", not immutable initialisers. The re-parameteriser takes the container in
  a register, so an absolute-address scan cannot see it — that is why there are 0 static writes to
  `0xDF9B9C`/`0xDF9BB0`/`0xDF9BB4`/`0xDF9BB6`.

**#15–#19, #22–#23 (M2, M3, M5, M6, M9, M10) — all CONFIRMED byte-exact**, with two additions:

* M5: `SetCash` `0x005DF4EE cmp byte [esp+0x10],0 / jne 0x5df501` jumps **past** the write;
  `SetFuel` `0x005DF63E / jne 0x5df65a` skips write *and* dirty. The slot is the out-parameter of a
  second-argument parse (`FUN_0059F6D0`), pre-initialised to 0 — a genuine optional Lua boolean.
  **New:** no shipped script passes it (every `SetCash` / `SetFuel` call site in both corpora is
  one-argument), so this cannot break an existing path — only a new caller.
* M6: `[0x01176106]` is also read by **`Object.IsDisguised`** (`0x005CEF20`), and the Lua guards
  `if not Player.GetVehicleDisguise() then return end`. It is a **global feature gate**, which is a
  stronger statement than "not per-player".

**#28 (E1) — confirmed, plus a second Pass-1 extractor error.** `GetOutBoundary` `0x005DC7D6
mov eax,[eax+8] ; 0x005DC7DD mov al,[eax+0x4f5]`. Pass 1's own §A4 table lists
"`+0x188/+0x18C` out-boundary pair <- `GetOutBoundary`" — those offsets belong to
**`SetSurvivalModeCallback`**, and `GetOutBoundary` touches neither.

**#31 (Xbox).** §0.5's profile row (`Set/GetProfile{Character,Upgrade,Costume}`,
`0x002b00c`–`0x002b070`), §7's four `gui-hud.md` names, and §7's two `ai.md` disguise strings all
verify exactly. The **Scope paragraph is CONTRADICTED**: seven files in
`docs/mercs2-pdb-analysis/` carry `Player*` symbols, not three (it misses `AddPlayerInfo`,
`SetPlayerPDAWidget`, `AddPdaBlipToLocalPlayer`/`DeletePdaBlipForLocalPlayer`, the *decompiled*
`PgPlayerPDAMapMode @825666a8`, and all of `world-streaming.md` / `networking.md` /
`weapons-combat.md`). Worse, against the actual binary —
`output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt` — the Xbox build carries ~22 of the 107
binding names verbatim plus five engine mode classes (`PgPlayerPDAMapMode`,
`PgPlayerBinocularsMode`, `PgPlayerHumanMode`, `PgPlayerEnterSeatMode`, `PgPlayerSeatedMode`) with
named bodies in `output/_ghidra_x360/xenon_decomp_named.c`. So "there is no symmetric Xbox<->PC
marriage to make here" is false, and those five classes are a live lead for the `+0x66` / `+0x1B4`
mode fields. (`PgSysPlayer` really is absent — but `PgSysNetPlayer @825902d8` has a decompiled body.)

**#32 (§8 boot chain).** Source: `docs/mercs2-luacd/src/resident/mrxplayer.lua`.
`Start()` (`:130`) registers **two** callbacks (`:132` joined, `:133` left);
`OnPlayerJoined(iPlayerId, sPlayerName, tCharacterConfig, bLocalPlayer, iLocalId)` (`:176`);
`local vSpawnLocation = Player.GetPlayerStart()` (`:184`); `CreatePlayerCharacter(...)` (`:188`) —
all CONFIRMED. Three defects:

* **`CreatePlayerCharacter` does not call `Player.CreatePlayer`.** That call is in `Init()`
  (`:115-118`, `for i = 0, Player.GetMaximumPlayers()-1 do ... Player.CreatePlayer(i) end`) — a
  different lifecycle phase that runs *before* `Start()`. `CreatePlayerCharacter` (`:562-590`) calls
  `Player.AttachToCharacter(iPlayerId, uCharacterGuid)` at `:587`.
* **The actual entity creator is missing from the diagram**: `:586 Pg.Spawn(sCharacterName, x,y,z,yaw, ...)`.
* **`GetPlayerStart` is the fallback, not the authority**: `:185-187` immediately overrides it with
  `_tSpawnLocations[iPlayerId+1]` when set. §10.5's reimpl guidance inherits this.

`MrxUtil._TeleportHero` -> `Object.SetPosition` verifies (`mrxutil.lua:308,328`) but is reached via
`Event.Create(...)` from `_TeleportHeroes`, not from `OnPlayerJoined` — adjacency, not a call edge.
The four cheat entry points in `07_player_core_cheats_managers.md` and the 1e9 clamp in
`mrxpmc.lua:45-60` both verify; the clamp is scoped to `MrxPmc.AddCashQty` and is bypassed by
`mrxpmc.lua:474 Player.AddCash(...)` and `:538 Player.SetCash(tSaveData.nCash)`.
`Pg.GetGuidByName` really is the resolver (`mrxplayer.lua:572-578`).
Finally, §8's annotation `FUN_006A4060 (player+0x20, **marker component**)` and §10 item 3
("Possession is a component add/remove") still carry the wording §5's own retraction box withdrew.

**#33–#34 (§6 registrars, §5 attach).** All four registrars read; all set `+0x0C` capacity,
`+0x24` element size, `+0x26` shift, `+0x28` buckets, `+0x2C` seed `0x9E3779B9`, `+0x3C` type-name
pointer, then `call 0x0064A770`. Element sizes: `ControllerPlayer` `0x0C`, `VehicleDisguiseScale`
`0x0C`, `GrappleParameters` `0x1C` — all match the map. **`ModelMixerProfile` completed**: registrar
`FUN_00643A40`, container **`0x017BE708`**, element **`4`**, type-name `0x00BC5548`.

**#37 (§9.1 semantics).** `SetWaitForInGame` = a set-only latch, `[player+0x461] = 1`, resolved from a
**character** guid. `GetControlBindingType` = the six-component probe above. `ClearGPS` ->
`FUN_006A0FB0(player)`, reads `[player+0x390]` (the PDA widget id) and clears `[player+0x398]`.
`SetScopeEnabled` -> `FUN_006A21E0(player, bool)` — `[player+0x1B8]->[+0x10] = 1` and a
**refcount** at `[player+0x19C]` (`+1` on enable, `-1` on disable). None needs a breakpoint.

**#45 (§10).** `tools/wad_simulator/crates/mercs2_script/src/bindings/player.rs` really does hold
**107** `Required { name, corpus_calls }` rows — but `install` is **not** unfilled: 67 direct
`b.real(...)`, 14 loop-installed mode gates, 3 loop-installed scalar setters, 24 via
`super::record_all(...)`, and **zero** real stubs. The map appears to have read the file's stale
header comment. (`docs/modernization/wave0_seam_review.md:40` Seam G -> `mercs2_player`, and that
crate really is an empty scaffold — both CONFIRMED.)

---

## STILL-OPEN (3)

**S1 — the write that populates `player+0x24`** (map §9.2).
*Static evidence exhausted:* I enumerated every function that (a) calls `FUN_00423DC0`/`FUN_006496B0`/
`FUN_006CDAF0`/`FUN_006CD960`/`FUN_006CDB70` or (b) references any `Players` or `SeatLink` container
global — 537 + 120 functions — and disassembled each looking for `mov dword ptr [reg+0x24], ...` on a
non-`esp` base. Every hit is a local argument struct (the `0x005EDE00`/`0x005EFF60` family are Lua
table parsers that store `[playerObj+0x20]` into their own `[ebx+0x24]`), a generic list-insert
(`FUN_005366B8`), or an unrelated constructor (`FUN_00683D70`, vtable `0xDF9C90`). The per-player
ticks `FUN_006A1880` / `FUN_006A0770` / `FUN_0041FE20` contain no `+0x24` store either.
*What is now known:* `+0x24` is a **`SeatLink` guid** whose entity carries a `Controller*` component,
so the writer is in the seat/ride subsystem and stores a **key**, not a pointer.
*Runtime recipe:* HW **write** watchpoint on `<playerObj>+0x24`, where
`playerObj = *FUN_00423DC0(0x00DF9B90, Player.GetLocalPlayer())` — read it once from a one-shot
breakpoint at `0x005DA9F7` (`GetSeat`'s `mov eax,[eax+0x24]`, cold). Then walk into a vehicle. Per
[[x32dbg-mcp-no-resume]] the USER drives; per [[x32dbg-mcp-pitfalls]] use a HW watchpoint, never a
conditional bp on a per-frame function.

**S2 — the write that sets `player+0x58`** (map §9.7).
*Semantic is CLOSED*: `IsJoined` = `p+0x30 != -1`; `IsLocal` = that **and** `p+0x58 == 0`;
`IsRemote` = that **and** `p+0x58 != 0`. So `+0x58` is the remote flag at confidence H.
*Static evidence exhausted:* the only cfuncs that could set it are `BindToLocal` / `BindToRemote` /
`Unbind`, which delegate to `FUN_006A0400` / `FUN_006A04B0` / `FUN_006A0520`. All three are SecuROM
split thunks and **all three resolve to VM stubs** — slots dereffed as required:
`[0x0245F5A0] = 0x024EBC20 -> push 0x24ebc2a; call 0x1aaff10`;
`[0x02458FB4] = 0x024F0270 -> push 0x24f027a; call 0x1aaff10`;
`[0x0245A1D4] = 0x024E3B40 -> push 0x24e3b4a; call 0x1aaff10`.
No `mov [reg+0x58]` store in any `Players`-touching `.text` function corresponds to a player object.
*Runtime recipe:* HW write watchpoint on `<playerObj>+0x58` (same address recipe as S1), then join a
second player / start a co-op session. Alternatively one-shot bp at `0x005DE7A4`
(`BindToRemote`'s `call 0x6a04b0`) and diff `+0x58` across it.

**S3 — three unnamed hash constants.** `0x892CF579` (the `FUN_0041FE20` feature gate,
`FUN_006886A0(0x892CF579)`), `0x223F6FDA` (its Havok filter constant), and `0x57B5E35A`
(the game-state id compared at `0x004C0B4D` and `0x006CEE90`).
*Exhausted:* hashed every `[A-Za-z][A-Za-z0-9_.]{2,40}` token from both
`output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt` (26 931 tokens) and every printable run
in `mercs2_unpacked.exe` itself (60 613 tokens) under both `pandemic_hash` and `pandemic_hash_m2` —
no match. The same sweep **did** resolve `0xFA62754E` -> `"PDA"` and `0xDB41017D` -> `"Exit"`, so the
method is sound; these three names simply are not strings in either image. No hash was invented.
*Next step:* harvest candidate names from `vz.wad` string tables (`mercs2_probe`) rather than the exe.

---

## What changes the map's headline claims

1. **§7 / §9 — `DAT_00DFBD77` is named.** It is `Net.IsClient`; `DAT_00DFBD78` is `Net.IsServer`;
   `0xDFBD74/75/76` are `Net.IsEnabled`/`IsActive`/`IsLobby`. The "authority/replication gate,
   name open" wording, and the three divergent readings across sibling maps, can all be replaced by a
   fact. The boundary cfuncs early-out on `IsClient` because boundaries are server-authoritative.
2. **§0 / §1 / §9.3 — `FUN_0041FE20` is not the player system tick.** `FUN_0062E7B0` and
   `FUN_0062E810` are, and both are already in the same layer-4 list.
3. **§2.2 — four cfuncs take a *character* handle, not a player handle.** `IsBoundaryDeath`,
   `SetWaitForInGame`, `VehicleDisguise`, `GetVehicleDisguiseState` all route through
   `FUN_006CDB70` = `GetPlayerForCharacter`. The `Player = ...` key in the latter two's Lua argument
   table is a character guid.
4. **§2.2 / §9.8 — the object is at least `0x465` bytes**, and ~16 further offsets are missing from
   the table (see the layout section). `+0x450` is `hash_m2("PDA")`, not "role unknown".
5. **§2.1 — 47 cfuncs resolve a handle through `Players`, not 8.**
6. **§4 / §9.4 — the dirty flag gates `autoSave`.** The five missing ORs are a proven shipped bug,
   not a hypothesis.
7. **§9.5 / §0.5 — `0x00DF9B10` is `CheatInfiniteAmmo` with a 1-byte element**, written by one
   feature in two places. There is no shared-container clobber risk to decode.
8. **§6 — `ModelMixerProfile` is `0x017BE708`, element 4**, and ECS containers are
   **re-parameterised at runtime** (registrar constants != live values), which bears on any reimpl
   that hardcodes the registrar's capacity/shift.
9. **Sources block — the script census covers `docs/mercs2-luacd/` *and* `docs/mercs2-dlc-luacd/`**
   (445 files). Re-running it as documented (370 files) reproduces 1113, not 1405.
10. **Scope paragraph — the Xbox side is not empty.** ~22 binding names marry verbatim and the five
    `PgPlayer*Mode` classes are the missing name for the player mode machine.
11. **§8 — `Player.CreatePlayer` is in `MrxPlayer.Init()`, not `CreatePlayerCharacter`**; `Pg.Spawn`
    is the actual entity creator; `_tSpawnLocations` overrides `GetPlayerStart`.
12. **§10 — `player.rs`'s `install` is implemented** (108 names bound, 0 stubs); the map is quoting a
    stale header comment.
13. **§5 — the cheat gate is `infammo || demo`**, and `DAT_01175F59` is the **demo-mode** flag
    (`Sys.IsDemoMode`), not a cheat. All five flags are now named by hash.
14. **Three reader-facing defects survive** (D2 §7's stale "binding-only"; D3 §9.5's truncated
    sentence; D4 the size stated three ways).

## Reproduction

```
python <scratch>/p2/idx.py                 # build the 43 027-start index (idx.pkl)
python <scratch>/p2/names.py 0xDF9B90 ...  # container master key
python <scratch>/p2/bodies.py              # 107-body resolve-path census  -> 23 / 24 / 4
python <scratch>/p2/offs.py > tails.txt    # every body from its resolve to its ret
python <scratch>/p2/count_calls3.py        # call-site census: call( over luacd+dlc = 107/107
python -c "from q import *; refs(0xDFBD77)"        # 137 refs, 0 writes
python -c "from pe import *; thunk(0x006CDB70)"    # slot deref -> 0x024E8BD0 (VM stub)
```

| question | check |
|---|---|
| what is `DAT_00DFBD77`? | walk `Net`'s table at `0x00B998D0`; `disfn(0x005C67D0)` |
| what is `[ctrl+0x0C]`? | `disfn(0x006CFF40)` — cases 1/2/3 select client vs server objects |
| what does `FUN_006CDB70` take? | grep the Lua for the four cfuncs that call it — all pass characters |
| whose container is `0x00DF81D8`? | `disfn(0x0042BF80)` — `lea esi,[edi+0x50]`; `0xDF81D8 - 0x50 = 0xDF8188` |
| is the pump layer 4? | `disraw(0x004C1170,0x140)`; `u32(0x00BB046C) == 0x004C09C0` |
| does `+0x11` gate anything? | `disraw(0x0061488C,0x40)` — `"autoSave"` at `0x00BBC4E8` |
| object minimum size? | `disraw(0x005DFEA1,0x10)` — `mov byte [eax+0x464], cl` |
