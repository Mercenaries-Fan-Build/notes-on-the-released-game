---
title: Double-blind validation — mission / contract flow code map
subject: docs/reverse_engineer/mission_contract_flow_code_map.md
date: 2026-07-26
status: current
evidence: proven
method: Phase A derived blind from primary sources; Phase B compared afterwards.
---

# Double-blind validation: `mission_contract_flow_code_map.md`

**Protocol.** Phase A below was written *before* the target map was opened, from primary
sources only: raw disassembly of `output/_ghidra/securom_dump/mercs2_unpacked.exe`
(capstone, VA→file via the PE section table), cross-checks against
`mercs2_nodrm_v3.exe` / `image.bin` / `genuine_patched_unpacked.exe`, the decompiled Lua
corpus `docs/mercs2-luacd/`, and `tools/pandemic_hash.py`. Phase B was written after.

**PE section table** (used for every VA→offset conversion; RVA≠raw here):

| section | VA start | vsize | raw ptr | raw size |
|---|---|---|---|---|
| `.text`   | `0x00401000` | `0x00704000` | `0x00001000` | `0x00704000` |
| `.rdata`  | `0x00B05000` | `0x000F1000` | `0x00705000` | `0x000F1000` |
| `.data`   | `0x00BF6000` | `0x00E04000` | `0x007F6000` | `0x00E04000` |
| `.rsrc`   | `0x019FC000` | `0x0004D000` | `0x015FC000` | `0x0004D000` |
| `Stext`…`.securom` | `0x01A49000`+ | — | — | SecuROM regions |

Image base `0x00400000`.

---

## Phase A — independent findings (written before reading the map)

### A1. The namespace registry at `0x00DFD478`

`0x00DFD478` lies in **`.data`** (`0x00BF6000`–`0x019FA000`), *not* `.rdata`.

Row layout is **3 dwords, stride `0xC`**, proven from the walker's own index arithmetic
(`lea esi,[esi+esi*2]; add esi,esi; add esi,esi` = `i*3*2*2` = `i*0xC`) at `0x005A2DE4`:

```
{ const char *name;                    // col 0, .rdata
  const luaL_Reg *reg;                  // col 1, .rdata
  const char *post_register_lua_chunk;  // col 2, .rdata, may be NULL or "" }
```

Column 2 is confirmed as a **Lua source chunk**, not a name: the walker strlen's it
(`0x005A2D75` byte loop), then calls `0x00860240` (load-buffer) and `0x0085DF50` /
`0x0085D680` (protected call). Sampled contents:

- `_SYS` → defines `_G.import`, `dynamic_import`, `inherit`, `dynamic_remove`
- `Pg` → `GetGuidByName = Pg.GetGuidByName; … Controller = { LPad_Up = 1, … }`
- `math` → `Math = math`
- `Debug` → `ASSERT = Debug.Assert; print = Debug.Printf`
- `VO` → `VO.PRIORITY_CINEMATIC = 0; …`

**31 populated rows (index 0–30)**, terminated by an all-zero row at **`0x00DFD5EC`**
(the walker's loop condition is `cmp dword ptr [esi+0xDFD478], ebx(0); jne`). Row 31 is the
terminator; rows beyond it are float constants, i.e. unrelated `.data`.

The walker is **`FUN_005A2C40`** — the only function in `.text` referencing `0x00DFD478`
(refs at `0x005A2D3A`, `0x005A2D49`, `0x005A2DED`, `0x005A2DF3`, plus `0x00DFD47C` at
`0x005A2D55`).

**The 31 namespaces, in registry order:**

| # | name | reg table | # cfuncs | # stubbed |
|---|---|---|---|---|
| 0 | `_SYS` | `0x00B9A854` | 6 | 0 |
| 1 | `Sys` | `0x00B98A78` | 64 | 1 |
| 2 | **`Pg`** | **`0x00B99328`** | **80** | 2 |
| 3 | `Object` | `0x00B99608` | 87 | 0 |
| 4 | `Player` | `0x00B98FC0` | 107 | 0 |
| 5 | `Event` | `0x00B987F8` | 4 | 0 |
| 6 | `Ai` | `0x00B9A938` | 66 | 18 |
| 7 | `Human` | `0x00B99EF0` | 32 | 0 |
| 8 | `Debug` | `0x00B98828` | 6 | 6 |
| 9 | `Vehicle` | `0x00B98918` | 40 | 0 |
| 10 | `Airstrike` | `0x00B9A8C8` | 12 | 0 |
| 11 | `Gui` | `0x00B9A398` | 38 | 1 |
| 12 | `_GuiInternal` | `0x00B99FF8` | 114 | 0 |
| 13 | `Graphics` | `0x00B9A4D0` | 95 | 3 |
| 14 | `Sound` | `0x00B98C98` | 88 | 9 |
| 15 | `ObjectFilter` | `0x00B98770` | 16 | 0 |
| 16 | `Net` | `0x00B998D0` | 92 | 2 |
| 17 | `math` | `0x00B99BE8` | 17 | 0 |
| 18 | `Camera` | `0x00B9A7D8` | 14 | 0 |
| 19 | **`Junk`** | **`0x00B99E28`** | **24** | 15 |
| 20 | `ObjectState` | `0x00B995B0` | 9 | 2 |
| 21 | `Movie` | `0x00B99BBC` | 4 | 0 |
| 22 | `Animation` | `0x00B9A88C` | 6 | 0 |
| 23 | `VO` | `0x00B988B0` | 11 | 0 |
| 24 | `Weapon` | `0x00B98860` | 9 | 0 |
| 25 | `String` | `0x00B98C88` | 1 | 0 |
| 26 | `Table` | `0x00B98A60` | 2 | 0 |
| 27 | `Report` | `0x00B98F64` | 5 | 0 |
| 28 | `Disguise` | `0x00B98F94` | 1 | 0 |
| 29 | `FactionZone` | `0x00B98FA4` | 1 | 0 |
| 30 | `LTILibName` | `0x00B99C78` | 52 | 2 |

Totals: **1103 cfunc rows, 61 of them pointing at the shared no-op stub.**

**Verdict on the contested naming.** `0x00B99328` is row 2 → **`Pg`**. `0x00B99E28` is
row 19 → **`Junk`**. There is **no `World` namespace and no `PgWorld`**: the byte string
`PgWorld\0` does not occur anywhere in the image, no registry row is named `World`, and the
decompiled Lua corpus contains **zero** `World.` call sites. Likewise there is **no
`Objective` namespace**.

I found **no second registry** — `0x00DFD478` is the only namespace table.

Both cfunc tables are plain `luaL_Reg[]` terminated by `{NULL,NULL}` (`Pg` at `0x00B995A8`,
`Junk` at `0x00B99EE8`). Neither contains `{name,0xFFFFFFFF}` / `{name,0xFFFFFFFE}` marker
rows — that sub-table convention exists elsewhere in this engine but **not** in these two.

### A2. The shared no-op stub `0x006D5640` — and a trap in the "highest authority" source

In `mercs2_unpacked.exe` (and `image.bin`) the bytes at `0x006D5640` are
`E9 7B CA 5F 6F` = `jmp 0x6FCD20C0`, a target **outside the image**. That is a
runtime hot-patch artifact captured in the memory dump — Ghidra never decompiled it
(`FUN_006D5640` does not appear in the decomp at all).

The true static body is visible in `mercs2_nodrm_v3.exe` at the same VA:

```
006D5640  33 c0    xor eax, eax
006D5642  c3       ret
```

i.e. a `lua_CFunction` that pushes nothing and returns 0 results — **a no-op stub**, used by
61 bindings. *This is a case where the nominally highest-authority artifact is corrupt at the
address of interest and a sibling image is authoritative.*

### A3. Contracts — `Pg.ContractActivated` / `Cancelled` / `Completed`

From the `Pg` table walk:

| index | name | address |
|---|---|---|
| 51 | `ContractActivated` | `0x005D7DB0` |
| 52 | `ContractCancelled` | `0x005D7E40` |
| 53 | `ContractCompleted` | `0x005D7E40` |

**`ContractCancelled` and `ContractCompleted` are the identical function pointer.** The two
table rows hold the same address; there is no thunk, no dispatch on a hidden argument.

`ContractActivated` (`0x005D7DB0`), verbatim on the argument path:

```
005D7DF7  mov edx, dword ptr [esp + 8]        ; the string argument
005D7DFB  mov eax, dword ptr [0x1176170]      ; global game/session struct
005D7E00  push 0x3f
005D7E02  push edx
005D7E03  add eax, 0xf149
005D7E08  push eax
005D7E09  call dword ptr [0xb052ec]           ; strncpy(dst, src, 0x3F)
005D7E0F  xor cl, cl
005D7E14  cmp byte ptr [0xdfbd78], cl
005D7E1A  je 0x5d7e2d
005D7E1C  mov eax, dword ptr [0x1176164]
005D7E21  mov byte ptr [eax + 0x5550], cl     ; extra side effect
005D7E27  mov byte ptr [eax + 0x5552], cl     ; extra side effect
```

So: `strncpy([0x01176170] + 0xF149, arg, 0x3F)`. **Confirmed exactly**, including both
constants. Note the two additional byte-clears at `[0x01176164]+0x5550/+0x5552`, gated on
`[0x00DFBD78]` — a side effect beyond the strncpy.

`ContractCancelled` == `ContractCompleted` (`0x005D7E40`), in full:

```
005D7E40  mov eax, dword ptr [0x1176170]
005D7E45  test eax, eax
005D7E47  je 0x5d7e5f
005D7E49  push 0x3f
005D7E4B  add eax, 0xf149
005D7E50  push 0xba8b09                       ; "" (verified empty C string)
005D7E55  push eax
005D7E56  call dword ptr [0xb052ec]           ; strncpy(dst, "", 0x3F)
005D7E5C  add esp, 0xc
005D7E5F  mov eax, 1
005D7E64  ret
```

Writes the empty string. **The engine therefore cannot distinguish a completed contract from
a cancelled one** — same code, same write, same value.

#### The "no reader" claim — my own scan

I disassembled all of `.text` (seeded from every `E8` call target, then linear-filled) and
enumerated every instruction whose decoded operand mentions displacement `0xF149`.
**Exactly three sites exist, image-wide:**

| site | fn | instruction | kind |
|---|---|---|---|
| `0x005D7E03` | `ContractActivated` | `add eax, 0xf149` | **write** (strncpy dst) |
| `0x005D7E4B` | `ContractCancelled`/`Completed` | `add eax, 0xf149` | **write** (strncpy dst) |
| `0x006C8B28` | `FUN_006C8A20` | `lea eax, [esi + 0xf149]` | **write** (`memset(...,0,0x40)`) |

The third is inside a large struct initializer that memsets field after field
(`push 0x40; push ebx(=0); push <ptr>; call 0x009EE8D8` repeatedly). It zero-fills the
buffer; it does not read it. The buffer is therefore **0x40 bytes** and `0x3F` is the
deliberate leave-room-for-NUL length.

**There is no reader.** Nothing formats it, compares it, copies it out, or exposes it. The
`Pg` table contains no `GetContract*` getter (all 80 rows enumerated above).

**Contrast that strengthens the finding:** the *sibling* breadcrumb at `+0xF0E5` in the same
struct (also `0x40` bytes, memset at `0x006C8BCD`) **is** read — at `0x006C3FF2`:

```
mov eax,[0x1176170]; add eax,0xF0E5; push eax
push 0xBCF438           ; "[0x6ad9b549:%s]"
push 0x7F; push <buf>; call [0xB05304]   ; _snprintf
```

and at `0x006C26B7` it is strncpy'd into the crash-report global `0x00EDB1D8`. So the engine
*does* consume breadcrumbs of exactly this shape for crash reporting — `+0xF149` is simply
never wired to anything.

*Caveat I cannot fully exclude:* a reader that first computes an intermediate base (e.g.
`esi = struct + 0xF100`) and then uses a small displacement would evade a displacement scan,
as would a wholesale `memcpy` of the struct into a savegame or minidump. I saw no evidence of
either, and the confirmed reader of the sibling field uses the direct-displacement form.

#### Where contract state actually lives

Lua-side, not engine-side. `docs/mercs2-luacd/src/resident/mrxtaskcontract.lua`:

- `:99  Pg.ContractActivated(sMissionName)` — return value unused
- `:120 Pg.ContractCompleted()` — no arguments
- `:275 Pg.ContractCancelled()` — no arguments
- `:27/29 self._tContractState = tSaveData.tContractState or {}` — the real state table
- `:406-414` per-flag get/set on `_tContractState`
- `:441/443 tSaveData.tContractState = …` — persisted through the Lua save table

So the authoritative contract state is a Lua table serialised into the save; the engine call
is a fire-and-forget breadcrumb.

### A4. The game-state machine

**Table: `0x01175C80`.** Referenced from only three places in `.text`: `0x0040A08F`,
`0x004C0F23` (inside the enter function) and `0x004C1010` (inside the register function).

**Capacity is 23 slots**, proven twice by the bound in the scan loops — `cmp eax, 0x17; jl`
at `0x004C0F33` and at `0x004C1008`. **20 slots are populated**; indices 20, 21, 22 are NULL.

Each slot holds a pointer to a state object whose common prefix is
`{ void **vtable; u32 name_hash; … }`. Objects are variably sized (8 to 0x34 bytes), so they
are distinct subclasses. The vtables carry **no RTTI** (the dword before each vtable is a code
address, not a `RTTICompleteObjectLocator`), so class names are unrecoverable that way.

Vtable shape, inferred from the state family and the call sites:
`+0x00` common/dtor · `+0x04` **Enter** · `+0x08` **Exit** · `+0x0C` init-with-args ·
`+0x10` **Update(dt)**.

**Current-state global: `0x01175C7C`** (41 references in `.text`). It holds the *state object
pointer*, not an index or a hash — readers dereference `[0x01175C7C]+4` to get the hash.

**Enter = `FUN_004C0F10`.** Scans the 23 slots for `[obj+4] == requested_hash`, stores the
object into `0x01175C7C`, calls vtable `+0x0C` then `+0x04`, then fires an event carrying
hash `0x9DA97065`.

**Exit = `FUN_004C0FA0`.** Calls vtable `+0x08` on the current state, fires an event carrying
hash `0xDB41017D`, then clears `0x01175C7C` to 0.

The two event hashes crack cleanly: `pandemic_hash_m2("enter") == 0x9DA97065` and
`pandemic_hash_m2("exit") == 0xDB41017D`.

**Register = `FUN_004C0FF0`** (entered via a SecuROM split thunk; body resumes at
`0x004C0FF8`) — scans the same 23 slots and stores the state object.

**Pump = `FUN_004C09C0`.** A phase machine on `[this+8]`:

- phase 1 → `0x004C0BC2`: bumps refcounts on a list at `0x00D28668`, then sets phase = 2
- phase 2 → `0x004C0A5A`: drains a pending-request queue (`0x004C9CF0`); for each request,
  if it differs from the current state's hash it calls the state's Exit vtable slot, fires
  the `exit` event, clears `0x01175C7C`, then calls **`FUN_004C0F10`** (enter)
- phase 3 → `0x004C0A0A`: calls **`FUN_004C0FA0`** (exit), tears down, sets phase = 4
- run phase → `0x004C0B14`…: calls the current state's `Update` (vtable `+0x10`) with dt;
  if the current state hash is `0x57B5E35A` it also calls `FUN_004C0C70`; then, gated on
  `[0x01175A94] != 1`, calls **`FUN_004C0EC0`** and `FUN_004C0CC0`

`FUN_004C0F10` and `FUN_004C0FA0` each have **exactly one** caller — both inside
`FUN_004C09C0`. The pump itself is called from `0x004C13D8` in `FUN_004C13A0`, and also
appears once as a vtable slot at `0x00BB046C`.

#### State-name hashes

I cracked **19 of 20** by hashing (a) every ASCII string in the image, (b) every identifier
and quoted literal in `docs/mercs2-luacd/`, and (c) generated compounds, with
`pandemic_hash_m2`:

| slot | hash | name | corroboration |
|---|---|---|---|
| 0 | `0xC8192FE5` | `pause` | `mrxguishell.lua:226` `RequestGameState("Pause")` |
| 1 | `0x96FB0F27` | `loading` | `levelbootstrap.lua:16` `RequestGameState("Loading")` |
| 2 | `0x7D0B162C` | `unloading` | `mrxguipausescreen.lua:403` |
| 3 | `0x20BC86EA` | `unloadshell` | generated compound; semantic fit (see gate 1 below) |
| 4 | `0x05CE7A0C` | `waitforplayer` | generated compound |
| 5 | `0x7E289119` | `waitforstreaming` | `mrxstate.lua:28` |
| 6 | `0x9B7AD367` | `waitfortether` | `mrxstate.lua:45`, `mrxutil.lua:113` |
| 7 | `0x53056C27` | **UNCRACKED** | — |
| 8 | `0x51BFF7B1` | `shell` | `mrxguishell.lua:633` |
| 9 | `0xFDC8B95E` | `reset` | exe string |
| 10 | `0x6D19FA15` | `flush` | exe string |
| 11 | `0x38929BF7` | `connecting` | exe string |
| 12 | `0x9AC591FB` | `lobby` | exe string |
| 13 | `0x72558BE0` | `online` | exe string |
| 14 | `0x57B5E35A` | `ingame` | `mrxguicinematic.lua:230` |
| 15 | `0xB8CB300C` | `cinematic` | `mrxguicinematic.lua:347` |
| 16 | `0xEE0915FC` | `attract` | `mrxguishell.lua:346` |
| 17 | `0xCE7E5A43` | `exiting` | `mrxguishell.lua:758` |
| 18 | `0xED87E746` | `lti_precache` | `mrxguishellbootstrap.lua:38` |
| 19 | `0xFA62754E` | `pda` | `mrxguipda.lua:112` |

Ten of these are corroborated by an actual `Sys.RequestGameState("…")` call site in the Lua
corpus, which is independent of the hash arithmetic. The hash is case-insensitive for letters
(each byte is OR'd with `0x20`), which is why the Lua mixes `"Shell"`/`"shell"` and
`"WaitForTether"`/`"waitfortether"` freely.

Slot 7 (`0x53056C27`) resisted ~230k candidates. Its vtable is `0x00BB0144`, sitting between
`waitforstreaming` and `waitfortether` in `.rdata` order, and its Update (`0x004BA7D0`) counts
frames (`[this+8] += 1`) and accumulated time (`[this+0xC] += dt`), then requests `ingame`
(`0x57B5E35A`) once the count exceeds 10 **or** the timer exceeds a threshold. It is a short
transitional wait that ends in `ingame`. Notably `"waitforgame"` does **not** hash to it, even
though `docs/mercs2-luacd` references a `STATE_WAITFORGAME` constant.

### A5. `Sys.RequestGameState` (`0x005E4AF0`)

Address independently obtained from the `Sys` registry row, not from any map.

**The Lua-visible argument is a STRING.** The function fetches argument 1 via `0x0059FB00`,
which calls `0x0059F990` (a SecuROM split thunk) to obtain a `char*` and then hashes it with
`0x00824270`. `0x00824270` is literally `pandemic_hash_m2`, verified instruction by
instruction:

```
00824280  movsx ecx, cl
00824283  or   ecx, 0x20          ; case suppression
00824286  xor  eax, ecx
0082428B  imul eax, eax, 0x1000193 ; FNV prime
…
00824298  xor  eax, 0x2a          ; M2 post-process
0082429B  imul eax, eax, 0x1000193
008242A1  ret
```

Every call site in the Lua corpus passes a quoted string
(`Sys.RequestGameState("WaitForStreaming")`, `("ingame")`, `("shell")`, …). So the argument
is a **name string that the engine immediately hashes**; the hash is the *internal*
representation, not the API surface.

A second, optional argument is read via a second `0x0059FB00` call and defaults to 0.

**Two gates swallow the request while still returning `true`:**

```
005E4B64  mov eax, dword ptr [0x1175c7c]    ; current state object
005E4B69  test eax, eax
005E4B6B  je 0x5e4bc2                        ; no current state -> real request
005E4B71  mov eax, dword ptr [eax + 4]       ; current state hash
; ---- gate 1 ----
005E4B74  cmp eax, 0x20bc86ea                ; current == "unloadshell"
005E4B79  jne 0x5e4ba5
005E4B7B  cmp esi, 0x51bff7b1                ; requested == "shell"
005E4B81  jne 0x5e4ba5
005E4B90  mov dword ptr [eax], edi           ; push boolean true
005E4B95  mov dword ptr [eax + 4], edi
005E4B9C  mov eax, edi
005E4BA4  ret                                ; -> returns true, request dropped
; ---- gate 2 ----
005E4BA5  cmp eax, 0x7d0b162c                ; current == "unloading"
005E4BAA  jne 0x5e4bc2
005E4BB0  …                                  ; -> also returns true, request dropped
```

Gate 1 is conditional on **both** the current state being `unloadshell` **and** the request
being `shell`. Gate 2 fires whenever the current state is `unloading`, regardless of what was
requested. Only the fall-through at `0x005E4BC2` reaches the real dispatcher
**`FUN_004BDD10`** (called at `0x005E4C0F`), after which it also returns `true`.

Consequence: a script cannot distinguish "state change accepted" from "state change silently
dropped" — the return value is `true` in all three paths.

`FUN_004BDD10` is the engine-wide request entry point: **36 direct callers**, from
`Sys.RequestGameState`, from the state classes themselves (`0x004B8A90`, `0x004BA070`,
`0x004BA3F0`, `0x004BB170`, `0x004BC530`, `0x004BCB90`), and from shutdown / networking /
crash paths (`0x00615A10` requests `0x7D0B162C` = `unloading`, etc.).

### A6. The frame chain — is the sim tick state-gated?

Walked every caller myself, both direct branches (`E8`/`E9` rel32 with the destination
computed) and **every occurrence of the literal address anywhere in the image** (to catch
vtable slots and function-pointer tables):

| function | direct branches to it | literal-address occurrences image-wide |
|---|---|---|
| `FUN_004C9740` | **1** — `call` at `0x004C0ED6`, inside `FUN_004C0EC0` | **0** |
| `FUN_004C0EC0` | **1** — `call` at `0x004C0B6A`, inside `FUN_004C09C0` | **0** |
| `FUN_004C09C0` (pump) | 1 — `call` at `0x004C13D8` in `FUN_004C13A0` | 1 (vtable slot `0x00BB046C`) |
| `FUN_004C15E0` | 1 — `call` at `0x004C153B` in `FUN_004C14F0` | 0 |

Because `FUN_004C0EC0` and `FUN_004C9740` have **zero** literal-address occurrences anywhere
in the image, they cannot be reached indirectly. Their single static caller is their *only*
caller. The chain is therefore exactly:

```
FUN_004C13A0
  └─ FUN_004C09C0        (state pump)
       └─ run phase, gated on [0x01175A94] != 1
            └─ FUN_004C0EC0   @0x004C0B6A
                 └─ FUN_004C9740   @0x004C0ED6   (the simulation tick)
```

`FUN_004C9740` is indeed the big per-frame subsystem tick — a long run of
`call 0x0046AB90 / 0x004FB270 / 0x004FC0C0 / 0x004FD850 / 0x005179F0 / 0x004B77A0 /
0x0058E660 / 0x00516020 / 0x006C4C40 …`.

**`FUN_004C15E0` is a different chain and does not reach it.** Its body is a generic
staged-task driver over an array at `0x017BBCCC` with a cursor at `0x017BBCF8`, a count at
`0x017BBCF4` and a stage boundary at `0x017BBCFC`, invoking vtable `+0x04` and `+0x0C` on each
element. It contains **no** call to `FUN_004C9740`, and `FUN_004C9740` has no caller other
than `FUN_004C0EC0`. `FUN_004C15E0` is reached from `FUN_004C14F0` ← `FUN_00630EF0`, whereas
the pump is reached from `FUN_004C13A0` ← `FUN_00631670`.

So: **the simulation tick is state-machine-gated**, not a layer of `FUN_004C15E0`. It runs
only when the pump reaches its run phase and `[0x01175A94] != 1`. I could not statically
determine the *value* of `[0x01175A94]` (set at runtime; likely a pause/minimise flag) — that
would need a live capture.

### A7. Objectives

`Gui.AddObjective` → **`0x006D5640`**, the shared no-op stub (§A2). It is the only stub among
`Gui`'s 38 entries. There is **no `Objective` namespace** in the registry.

But "objectives are not in the engine" needs qualification. Objective *presentation* is very
much in the engine:

- `_GuiInternal` (all real code): `MinimapAddObjective` `0x005B96E0`,
  `MinimapAnimateObjectiveSize` `0x005B9A10`, `MinimapAnimateObjectiveAlpha` `0x005B9C80`,
  `MinimapAnimateObjectiveSonar` `0x005B9E90`, `MinimapUnanimateObjective` `0x005BA1E0`,
  `MinimapRemoveObjective` `0x005BA360`
- `Net` (real): `SendEvent_AddRadarObjective` `0x005C7150`,
  `SendEvent_AddMarkerObjective` `0x005C74B0`, `SendEvent_AddPdaObjective` `0x005C77E0`,
  `SendEvent_ObjectiveMessage` `0x005C8530`, `SendEvent_SetObjectiveTraySlotText` `0x005C8A90`,
  and their removal counterparts
- `Net` (stubbed): `SendEvent_AddObjective`, `SendEvent_RemoveObjective` → `0x006D5640`

So what is absent is a **generic objective data model** (`Gui.AddObjective`, the abstract
add/remove pair). Radar, marker, PDA and tray objectives are all implemented natively.

### A8. Layers

`pandemic_hash_m2("layer") == 0xE6B81A54` — **confirmed**, and used as the asset *type* at
`0x005D4EF8` (`mov dword ptr [esp+0x1c], 0xe6b81a54`) in the lookup `FUN_0045E440`.

**Flag byte at `rec+0x18`:**

- `Pg.IsStaticLayer` (`0x005D4BF0`) tests **bit 2**: `test byte ptr [eax+0x18], 4` at
  `0x005D4C56`; sets the boolean result from that. So **bit 2 = static**. ✔
- `Pg.UnloadLayer` (`0x005D4E40`) tests **bit 0**: `test byte ptr [eax+0x18], 1` at
  `0x005D4F40`. ✔ (bit 0 read as "dynamic / unloadable")

**`Pg.UnloadLayer` does NOT raise a Lua error.** The actual control flow after the layer
record is found:

```
005D4F37  cmp byte ptr [0x1175f58], 0
005D4F3E  jne 0x5d4f56          ; global set -> delegate
005D4F40  test byte ptr [eax + 0x18], 1
005D4F44  jne 0x5d4f56          ; bit 0 set -> delegate
005D4F46  lea esi, [esp + 0x10]
005D4F4A  call 0x4b2a50          ; push NIL, return 1  -> refusal
005D4F55  ret
005D4F56  push 0xbb9034          ; the string "layer"
005D4F6D  call 0x85d9f0          ; lua_pushstring
005D4F79  call 0x5a0330          ; arg shuffle (3 callers, all layer fns)
005D4F7F  call 0x5d5500          ; Pg.UnloadAsset
```

`0x004B2A50` is the "push nil and return 1" helper (`mov dword ptr [ecx+4], 0`; bump top;
`mov eax,1`) — the same idiom used by every other cfunc's missing-argument path. So a layer
that is *not* flagged bit 0, with `[0x01175F58]` clear, is **silently refused with `nil`** —
no error, no message.

The `push "layer"; call 0x0085D9F0; call 0x005A0330` sequence is **not** an error raise: the
identical three-instruction sequence appears in `Pg.LoadLayer` at `0x005D4DB1` and in
`Pg.ReloadLayer` at `0x005D5077`, in each case immediately followed by the real work
(`call 0x005D50C0` / `0x005D5500` / `0x005D5540`). `0x005A0330` has exactly **3 callers,
all three of them these layer functions** — an error raiser would be called from everywhere.
The functions push the literal type name `"layer"` and delegate to the generic
`LoadAsset` / `UnloadAsset` / `ReloadAsset` path.

`Pg.UnloadLayer` also has an early gate: if `[0x00DFBD77] != 0` **and** the current game state
is not `unloading` (`0x7D0B162C`), it returns 0 results immediately (`0x005D4E53`–`0x005D4E6B`).

### A9. What I could NOT establish in Phase A

- **State slot 7 (`0x53056C27`)** — uncracked after ~230k candidates. Behaviourally a short
  frame/time-bounded wait that transitions to `ingame`.
- **The identity of the struct at `[0x01176170]`** — a large (>0xF200 byte) global game/session
  object. I did not enumerate its layout beyond the fields relevant here.
- **`[0x01175A94]`, `[0x01175F58]`, `[0x00DFBD77]`, `[0x00DFBD78]`** — runtime flags gating the
  sim tick, layer unloading and contract side effects. Their values need a live capture; I only
  established where they are tested.
- **`0x0059F990`, `0x005A0330`, `0x004C0FF0` entry** — SecuROM split thunks whose targets are
  runtime-resolved (`jmp dword ptr [0x0245F0E4]` → an obfuscated `push/push/pushfd/ret`
  dispatcher). I inferred their roles from call-site context, not from their bodies.
- **Whether the `+0xF149` buffer is swept up by a bulk `memcpy`** (savegame blob, minidump).
  My scan proves no *displacement-addressed* reader; it cannot prove no bulk copy.
- I did **not** run the game or attach a debugger; everything above is static.

> **Self-correction, made during Phase B.** In §A4 I listed the pump's phase 2 (request drain)
> and its "run phase" (state tick → `FUN_004C0EC0`) as separate bullets. That is imprecise: the
> tick block at `0x004C0AD6` is reached **only** by falling out of phase 2's drain loop
> (`jle 0x4C0AD6` at `0x004C0A69`), so the tick is the *tail of phase 2*, not a fifth phase.
> The target map draws this correctly. The chain conclusion is unaffected.

---

## Phase B — verdicts

Read the target map only after everything above was written.

**First impression, stated plainly:** the map is materially more careful than its reputation.
It states confidence per row, marks four state hashes as uncracked rather than guessing them,
flags its own two SecuROM split-thunk gaps, keeps a ten-item confirm-live inventory, and — on
the frame-chain question — explicitly refuses to call the sibling maps wrong, offering a
reconciliation hypothesis instead. Most of what I derived blind, it already had.

### Summary count

| verdict | count |
|---|---|
| CONFIRMED | 24 |
| CONTRADICTED | 2 |
| OVERSTATED | 3 |
| UNVERIFIABLE (map already flags most as open) | 3 |
| MISSING — facts I established that the map lacks | 5 |

### CONFIRMED

| # | Claim (map §) | How I confirmed it independently |
|--:|---|---|
| 1 | `0x00B99328` is **`Pg`**, and `World` is not a namespace in this engine (§0, §1) | Registry row 2. Plus: no row named `World`, no `PgWorld\0` byte string anywhere in the image, zero `World.` call sites in the Lua corpus |
| 2 | `0x00B99E28` is **`Junk`**, not `PgWorld` (§1) | Registry row 19 |
| 3 | Registry is at `0x00DFD478` **in `.data`, not `.rdata`** (§1) | Section table: `.data` = `0x00BF6000`–`0x019FA000` |
| 4 | 31 rows × 12 B, zero row at `0x00DFD5EC` (§0.5, §1) | Walked it; stride proven from the walker's own `lea esi,[esi+esi*2]; add esi,esi; add esi,esi` at `0x005A2DE4` |
| 5 | Row layout `{name, luaL_Reg*, post_register_lua}` (§1) | Col 2 is strlen'd, `luaL_loadbuffer`'d (`0x00860240`) and pcall'd (`0x0085DF50`) by the walker |
| 6 | Walked by **`FUN_005A2C40`** (§0.5) | The only function in `.text` referencing `0x00DFD478` |
| 7 | The full 31-row name→table inventory (§1 table) | **All 31 rows match mine exactly**, name and VA |
| 8 | `Pg` = 80 entries, 2 stubs (§0.5, §2) | Table walk; terminator at `0x00B995A8` |
| 9 | `Junk` = 24 entries, **15** stubs (§0.5, §2.1) | Table walk; terminator at `0x00B99EE8` |
| 10 | `FastCollectGroundVehiclesExceptTanks` aliases `FastCollectCars` at `0x005D3F10` (§2, §8) | Both rows hold `0x005D3F10` |
| 11 | `ContractActivated` `0x005D7DB0` = `strncpy([0x01176170]+0xF149, arg, 0x3F)` (§4.1) | Read instruction-by-instruction; both constants exact |
| 12 | …**and** the two net-flag clears at `[0x01176164]+0x5550/+0x5552` gated on `[0x00DFBD78]` (§4.1) | Present at `0x005D7E1C`–`0x005D7E27`. The map has this; I had drafted it as a gap and was wrong |
| 13 | `ContractCompleted` **is literally** `ContractCancelled`, `0x005D7E40`, writing `""` @ `0x00BA8B09` (§0, §4.2, §8) | Same pointer in both table rows; `0x00BA8B09` verified to be an empty C string |
| 14 | The engine has no representation of success vs failure (§0, §4.2) | Direct consequence of #13 |
| 15 | The field is `0x40` B, zeroed by ctor `FUN_006C8A20`, **exactly 3 refs in all of `.text`, all writes** (§0.5, §4.3) | My own full-`.text` operand scan found exactly 3. The map cites `0x005D7E04`/`0x005D7E4C`, I cite `0x005D7E03`/`0x005D7E4B` — the map points at the immediate's byte offset, I at the instruction start. **Same three sites.** Third is `memset(this+0xF149, 0, 0x40)` at `0x006C8B28` |
| 16 | **There is no reader** (§0, §4.3) | Confirmed by the same scan |
| 17 | State table `PTR_PTR_01175C80`, **23 slots, 20 filled**, each `{vtable, u32 nameHash, …}` (§0.5, §3.1) | Walked it; slots 20–22 NULL. Capacity proven twice by `cmp eax,0x17` at `0x004C0F33` and `0x004C1008` |
| 18 | Current state **`DAT_01175C7C`**, `+4` = name hash (§0.5) | 41 refs in `.text`; every reader dereferences `[cur+4]` |
| 19 | Enter **`FUN_004C0F10`**: scan, then vtable `+0xC`, then `+4`, then broadcast (§0.5, §3.2) | Read in full |
| 20 | Exit **`FUN_004C0FA0`**: vtable `+8`, broadcast, null the pointer (§0.5, §3.2) | Read in full |
| 21 | **An unrecognised state hash silently leaves `DAT_01175C7C == NULL`** (§3.2) | `0x004C0F38`: `xor eax,eax; test eax,eax; mov [0x1175C7C],eax; je <end>`. Found path at `0x004C0F8F` is `mov eax,ecx; jmp 0x4C0F3A`. Exactly as drawn — a subtle and correct catch |
| 22 | Pump **`FUN_004C09C0`** ← `FUN_004C13A0` ← `FUN_00631670` (§0.5, §3.5) | Walked the callers |
| 23 | `Sys.RequestGameState` = `0x005E4AF0`; **two swallow gates, both push `true`** (§3.4) | Gate 1 `0x005E4B74` (`unloadshell` + requested `shell`), gate 2 `0x005E4BA5` (`unloading`, any request). Both push boolean `true`, `mov eax,1`, ret |
| 24 | `m2` case-folding is why the Lua corpus mixes `"Shell"`/`"shell"` (§3.4, §10.2) | Verified the hasher ORs each byte with `0x20` at `0x00824283` |

Two more deserve their own lines, being the map's headline structural claims:

**CONFIRMED — the frame chain (§0, §3.5).** `FUN_004C9740` has exactly one static caller,
`FUN_004C0EC0`; `FUN_004C0EC0` has exactly one static caller, `FUN_004C09C0`, in its run
phase. I strengthened this beyond what the map claims: **both functions have zero occurrences
of their literal address anywhere in the entire image** (all sections, not just `.text`), so
no vtable slot or function-pointer table can reach them either. The single static call is
provably the only call, and the simulation tick is state-gated. See M1 — I also settled the
map's own open question about how the two drawings reconcile, and the answer vindicates
*both* this map and the siblings it was said to contradict.

**CONFIRMED — layers (§5.1, §5.2).** `pandemic_hash_m2("layer") == 0xE6B81A54`, used as the
asset type at `0x005D4EF8`. `rec+0x18` bit 0 = dynamic, bit 2 = static: `Pg.IsStaticLayer`
tests `& 4` at `0x005D4C56`, `Pg.UnloadLayer` tests `& 1` at `0x005D4F40`. The map's guard
*condition* `if (!DAT_01175F58 && !(rec[0x18] & 1))` matches my disassembly exactly. Also
confirmed: `Pg.IsStaticLayer` returns **0 values** (not `false`) when `DAT_01175F58` is set
(`0x005D4C3A`–`0x005D4C48`), a fiddly detail the map gets right.

### CONTRADICTED

**C1 — `FUN_004B2A50` is *not* `luaL_error`. It pushes `nil` and returns 1.**

- *Map:* §0.5 "read: `luaL_error FUN_004B2A50` unless `DAT_01175F58` or `rec+0x18 & 1`";
  §5.2 `return luaL_error(L); // ★ FUN_004B2A50 — cannot unload a STATIC layer`;
  §6.2 "`Pg.AddContextAction` raises a Lua error (`FUN_004B2A50`) when it returns false";
  §10.6 "`UnloadLayer` on a static layer is a **Lua error** … Missing this turns a
  mission-cleanup bug into a silent world corruption instead of the loud error retail gives."
- *Mine:* the entire body of `0x004B2A50` is

```
004B2A50  mov ecx, dword ptr [esi]        ; L
004B2A52  mov eax, 1
004B2A57  call 0x85d5d0                   ; checkstack(L, 1)
004B2A5C  test eax, eax
004B2A5E  jne 0x4b2a61
004B2A60  ret                             ; eax = 0  -> 0 results
004B2A61  mov eax, dword ptr [esi]
004B2A63  mov ecx, dword ptr [eax + 8]    ; L->top
004B2A66  mov dword ptr [ecx + 4], 0      ; type tag 0 = LUA_TNIL
004B2A6D  add dword ptr [eax + 8], 8      ; top++
004B2A71  mov eax, 1                      ; 1 result
004B2A76  ret
```

  This is the out-of-line form of the *exact* idiom every cfunc in this binary uses for its
  missing-argument path — including `Pg.ContractActivated` (`0x005D7DE3`) and
  `Sys.RequestGameState` (`0x005E4B30`), both of which I read in Phase A. `luaL_error` takes a
  format string and never returns; this takes none and returns a result count.

- **Why it matters.** §5.2's own comment on the *other* branch reads "unknown layer: nil, not
  an error" — but both branches produce **the same outcome, `nil`**. The map's §10.6
  instruction to reimplementers inverts the shipped behaviour: retail does **not** give a
  "loud error" on a static-layer unload, it fails **silently**. A reimpl built to §10.6 would
  raise where retail returns `nil`, and Lua doing `if not Pg.UnloadLayer(x) then` would take a
  different branch. The advice's stated purpose — "instead of the silent world corruption" —
  is exactly backwards: the silent path *is* retail. The same correction applies to §6.2's
  `Pg.AddContextAction` claim.

**C2 — the objective `SendEvent_*` surface is *not* devkit-only; most of it ships in retail
PC and is exposed to script.**

- *Map* §6.1: "The Xbox PDB's rich objective inventory (`SendEvent_AddObjective`,
  `SendEvent_AddPdaObjective`, `SendEvent_AddMarkerObjective`, `SendEvent_AddRadarObjective`,
  `SendEvent_*ObjectiveTraySlot*`, …) is a **devkit-build surface that retail PC does not
  expose to script**."
- *Mine:* I walked the retail `Net` table (`0x00B998D0`, 92 entries). Of the names the map
  lists, **five have real bodies and are bound to Lua right now**:

| binding | retail PC VA | status |
|---|---|---|
| `Net.SendEvent_AddRadarObjective` | `0x005C7150` | **real** |
| `Net.SendEvent_AddMarkerObjective` | `0x005C74B0` | **real** |
| `Net.SendEvent_AddPdaObjective` | `0x005C77E0` | **real** |
| `Net.SendEvent_ObjectiveMessage` | `0x005C8530` | **real** |
| `Net.SendEvent_SetObjectiveTraySlotText` | `0x005C8A90` | **real** |
| `Net.SendEvent_AddObjective` | `0x006D5640` | stub |
| `Net.SendEvent_RemoveObjective` | `0x006D5640` | stub |

  plus the real `RemoveRadar/Marker/Pda` counterparts, `SetObjectiveTraySlotImage`
  `0x005C8C20` and `ClearObjectiveTraySlot` `0x005C8DF0`.

- Only the two **generic** `Add/RemoveObjective` entries are stubbed. The map's own §6.1 table
  immediately below the claim documents the `_GuiInternal.Minimap*Objective` family correctly,
  so the surrounding analysis is sound — but the sentence overshoots into "retail does not
  expose", which the binding table falsifies. The accurate statement: **the *abstract*
  objective was cut; the concrete radar / marker / PDA / tray objective replication survived,
  including its co-op event senders.** That last part is load-bearing for co-op mission sync
  work, which §9.10 already flags as a suspected desync area.

### OVERSTATED

**O1 — §3.4 fact 1, "The argument is a hash, not a string."** The Lua-visible argument is a
**string**; `FUN_0059FB00` fetches a `char*` and hashes it with `0x00824270`, which I verified
is literally `pandemic_hash_m2` (`or ecx,0x20` / `imul 0x1000193` / `xor 0x2A` /
`imul 0x1000193` at `0x00824283`–`0x0082429B`). All ~28 corpus call sites pass a quoted
string. In fairness the map calls `FUN_0059FB00` "the hashed-**string** arg fetcher" in the
same sentence, annotates the pseudocode `→ m2 hash`, and draws the correct case-insensitivity
conclusion — so the mechanism is understood and §10.2's advice is right. Only the bolded
headline is wrong, and it is the kind of headline that gets quoted without its paragraph.

**O2 — §9.1 / §3.1, "four uncracked game-state hashes."** Two crack cleanly against strings
already present in the executable, and the third reproduces independently:

| slot | hash | map | mine |
|--:|---|---|---|
| 4 | `0x05CE7A0C` | `waitforplayer`? — **L**, hash-only | independently derived the same name; its Update (`0x004B9E40`) polls a count via `0x006CDAC0` then requests `waitforstreaming` — behaviourally a wait-for-player gate. Promotes to **M**, still not proven |
| 7 | `0x53056C27` | uncracked | **still uncracked** after ~230k candidates. Update `0x004BA7D0` counts frames and time, then requests `ingame` |
| 10 | `0x6D19FA15` | uncracked | **`flush`** — `m2("flush") = 0x6D19FA15`; vtable `0x00BB017C` sits between `waitfortether` and `reset` |
| 11 | `0x38929BF7` | uncracked | **`connecting`** — `m2("connecting") = 0x38929BF7`; vtable `0x00BB01EC` sits immediately before `lobby` (`0x00BB0208`) and `online` (`0x00BB02B8`), i.e. the multiplayer family in `connecting → lobby → online` order |

The `connecting`/`lobby`/`online` vtable adjacency is precisely the positional corroboration
the map's own §3.1 honest-note demands before promoting a bare hash match. So "17 of 20"
should read **19 of 20**, and §9.1 has one item left, not four.

**O3 — §4.3's speculation about the consumer.** "The plausible consumer is an out-of-`.text`
one: a crash/telemetry dump of the singleton, or the SecuROM-virtualised region." Presented
beside proven facts and unsupported — and unnecessary. See M4: the map's own §4.4 already
records that the *sibling* field `+0xF0E5` is "printed by the debug overlay as
`[0x6ad9b549:%s]`", and that is an ordinary in-`.text` read at `0x006C3FF2`. The two
observations were never connected, and connecting them is stronger evidence for the map's own
conclusion than the speculation is.

### UNVERIFIABLE — I could not settle these either

**U1 — `DAT_00DFBD77` / `DAT_00DFBD78` (§5.1 note, §9.10).** The map proposes `77` =
remote/client role, `78` = session is networked, explicitly marks the *names* **M** while
marking the *structure* **H**, and notes `player_code_map.md` reads `77` differently. I
confirmed every test site statically (`0x005D4E49`, `0x005D4ED4`, `0x005D7E14`, `0x006C26D2`,
`0x004BC992`, …) but no runtime value. **Settles by:** a HW-write watchpoint on both bytes
across a solo boot and a co-op join.

**U2 — the unwritten second dword of the 16-byte request payload (§3.4 fact 3).** I read the
publish call `FUN_004BDD10` and enumerated its 36 callers but did not decode the ring's slot
layout, so I can neither confirm nor deny the uninitialised read. **Settles by:** the map's
own §9.6 recipe.

**U3 — the identity of `[0x01176170]` (§4.4, §9.3).** The map records it as open; I got no
further. No RTTI is available (the dword before each vtable in this binary is a code address,
not an `RTTICompleteObjectLocator`), and the ctor `FUN_006C8A20` names nothing. I did confirm
the shape the map describes — `+0x158`, `+0xF0E5`, `+0xF148`, `+0xF149`, and the `0x100` ×
`0xD8` record array at `+0x208` with three `0x40`-byte name buffers each
(`0x006C8B51`–`0x006C8BB7`).

I also did **not** check: `Junk.IsInstallable` / `Sys.NoHud` sharing `0x005C0340` (§8), the
`Pg.AddContextAction` → `FUN_004B2C60` body and its `m2("default") = 0xBA71C11C` (§6.2), the
`Report.*` ruling-out (§6.3), the `Sys.SetSkipMission` unbounded `strcpy` (§3.6), the two
event rings (§3.3), or any `corpus_calls` count in §2. Those are unexamined, not endorsed.

### MISSING — facts I established that the map does not carry

**M1 — §9.7 is SETTLED, and it vindicates both this map and the siblings.**

The map's item 7 asks "Which app-stack slot ticks `FUN_004C09C0`? Break `FUN_004C15E0` and
dump `PTR_PTR_017BBCCC[i]->vt[0xC]` for each of the 5 layers." That needs no live run — the
array is **statically initialised** in `.data`:

```
0x017BBCCC[0] = 0x00D6C22C  vtable 0x00BB0420  +0xC tick = 0x004BEEA0
0x017BBCCC[1] = 0x014538B8  vtable 0x00BB0430  +0xC tick = 0x004BEED0
0x017BBCCC[2] = 0x0149FDA0  vtable 0x00BB0440  +0xC tick = 0x004BFAF0
0x017BBCCC[3] = 0x00D6C238  vtable 0x00BB0450  +0xC tick = 0x004C00E0   (the singleton install fn)
0x017BBCCC[4] = 0x00D6C244  vtable 0x00BB0460  +0xC tick = 0x004C09C0   ★ THE STATE PUMP
count @0x017BBCF4 = 5
```

So **app-stack layer 4 — index 4 of 5 — ticks the game-state pump.** The full chain:

```
FUN_00630EF0 RunFrame
  └─ FUN_004C14F0  master update
       └─ FUN_004C15E0  5-layer app-stack stepper over PTR_PTR_017BBCCC[]
            └─ layer 4 (0x00D6C244), vtable 0x00BB0460, +0xC
                 └─ FUN_004C09C0   state pump
                      └─ FUN_004C0EC0   (gated: [0x01175A94] != 1)
                           └─ FUN_004C9740   per-system tick
    plus a second, direct entry: FUN_00631670 → FUN_004C13A0 → FUN_004C09C0
```

This is the most valuable correction available to the map, and it is a *promotion*. The §3.5
hypothesis — "`FUN_004C15E0` … can reach `FUN_004C09C0` **indirectly** through an app-layer
object's `+0xC` tick slot — which would make both drawings true" — is **proven correct**.
Better still, the sibling maps' phrase "layer 4 of the master update" turns out to be
*literally* accurate: it is app-stack index 4. The framing that this map "contradicts ~8 other
maps" is wrong — it reconciles them, and the reconciliation is now fact rather than
hypothesis. The state-gating conclusion is untouched: the pump still sits between the stepper
and the tick. §3.5 and §9.7 can both be rewritten as **H**, and `0x00BB0460` / `0x00D6C244`
pinned in §0.5.

**M2 — §9.2 is SETTLED: the broadcast tag cracks.** `0x9DA97065 == pandemic_hash_m2("enter")`,
and the exit tag `0xDB41017D == pandemic_hash_m2("exit")`. The map has the enter tag as
uncracked and does not record the exit tag at all (`FUN_004C0FA0` passes it at `0x004C0FC9`).
This closes §9.2 statically and confirms the map's guess that it is the `Event.GameStateChange`
type id — the pair *is* the `{stateName, "enter"|"exit"}` payload `mrxstate.lua` waits on.

**M3 — two of the four open state hashes crack.** See O2: slot 10 = `flush`, slot 11 =
`connecting`, both with vtable-adjacency corroboration.

**M4 — the sibling breadcrumb `+0xF0E5` IS read in `.text`, and it is the positive control the
write-only argument wants.** At `0x006C3FF2`:
`_snprintf(buf, 0x7F, "[0x6ad9b549:%s]", [0x01176170]+0xF0E5)`; and at `0x006C26B7` it is
`strncpy`'d into the crash-report global `0x00EDB1D8`. Same struct, same `0x40` size (memset at
`0x006C8BCD`), same breadcrumb shape — **but that one is wired and `+0xF149` is not.** The map
argues its strongest conclusion (§4.3) purely from absence; this turns it into a contrast. It
also disposes of §4.3's own speculation (O3) and materially de-risks §9.9.

**M5 — a trap in the designated highest-authority source.** In `mercs2_unpacked.exe` (and in
`image.bin`) the bytes at `0x006D5640` are `E9 7B CA 5F 6F` = `jmp 0x6FCD20C0`, a target
outside the image — a runtime hot-patch captured in the memory dump. Ghidra never decompiled
it; `FUN_006D5640` appears nowhere in the 27k-fn decomp. The true body is in
`mercs2_nodrm_v3.exe`: `33 C0 C3` = `xor eax,eax; ret`. The map's *characterisation* ("the
shared `return-0` stub") is right — inherited from `scripting_host_binding_code_map.md` — but
the body is unreadable in the image both maps cite as their source. Worth a provenance note
wherever `0x006D5640` is described.

---

## Bottom line

**The user's distrust is not borne out on the substance.** All four contested headline claims
— `Pg`/`Junk` with no `World` namespace; the write-only contract breadcrumb with no reader;
the 23-slot/20-filled state machine with its enter/exit/pump triple; and the state-gated frame
chain — survived independent derivation, the last under a stronger test than the map itself
applied (zero literal-address occurrences image-wide, so no indirect caller can exist). The
31-row registry inventory matched **row for row**. The contract-field scan found the **same
three sites**. Where the map said "uncracked" it had genuinely not guessed; where it said "M"
or "L" it was genuinely uncertain.

The real defects are narrower than the framing suggested, and two of the three are in the
*advice* rather than the *analysis*:

1. **`FUN_004B2A50` is `push nil; return 1`, not `luaL_error`** — which inverts §10.6's
   instruction to reimplementers. Retail fails **silently** on a static-layer unload; the map
   tells you to make it loud "instead of the silent world corruption". This is the one finding
   here that would change shipped behaviour if acted on.
2. **The objective `SendEvent_*` family is not devkit-only** — five of the named entries have
   real bodies in the retail PC `Net` table; only the two generic ones are stubbed.
3. **"The argument is a hash, not a string"** is a misleading headline over a correct paragraph.

And the map's own biggest open question answers itself from static data: **app-stack layer 4
ticks the state pump**, so the "contradiction" with ~8 sibling maps was never a contradiction
— those maps' "layer 4" is literally app-stack index 4, and this map's state-gating sits one
level below it. That should be promoted from §9 hypothesis to §0.5 fact.

---

## Pass 2 — closing the open register

**Date:** 2026-07-26 · **Scope:** every item Pass 1 did not explicitly CONFIRM — 2 CONTRADICTED,
3 OVERSTATED, 3 UNVERIFIABLE (U1–U3), 5 MISSING — plus the six bullets of §A9 "What I could NOT
establish", plus the four areas Pass 1 declared "unexamined, not endorsed", plus the target map's
own §9 confirm-live inventory, plus the sibling-map boundary claims (now treated as claims to test,
never as evidence). Pass 1's verdicts were treated as **untrusted** and re-derived.

**Method.** All binary claims re-derived first-hand from
`output/_ghidra/securom_dump/mercs2_unpacked.exe` (the live-memory dump) **and** cross-checked
against `output/_ghidra/securom_dump/mercs2_nodrm_v3.exe` (the on-disk-shaped image) with capstone,
via a **full recursive-descent + linear-fill disassembly of the whole `.text` section**
(2,130,088 instructions decoded; seeds = every `E8`/`E9` rel32 target plus every `.rdata`/`.data`
dword pointing into `.text`, so vtable slots and function-pointer tables are covered). Absolute-
address xrefs are queried against that index, not against a byte-pattern scan — a displacement scan
cannot distinguish `cmp byte ptr [0xdfbd77], 0` from a mis-synced `cmp eax, 0xdfbd77` one byte
later, and cannot see instructions that were never decoded. Hashes with `pandemic_hash_m2`, verified
against `m2("layer") == 0xE6B81A54` before use.

**Headline results:** U1 and U2 are **CLOSED statically**. U3 is **narrowed with a hard negative on
the master key** and its layout corrected. The frame-chain finding is **confirmed and its provenance
corrected**. **State-gating does not survive in the form the map states it.** Two new
shipped-behaviour defects were found in the three cfuncs the map is named after. One sibling map is
provably wrong about the app-stack array.

---

### P0. Open register (mechanical)

| id | item | Pass-1 verdict | Pass-2 verdict |
|---|---|---|---|
| C1 | `FUN_004B2A50` is `push nil; return 1`, not `luaL_error` | CONTRADICTED | **CONFIRMED** (P1) |
| C2 | objective `SendEvent_*` family is not devkit-only | CONTRADICTED | **CONFIRMED** (P6) |
| O1 | "the argument is a hash, not a string" | OVERSTATED | **CONFIRMED overstated** (P7) |
| O2 | "four uncracked state hashes" | OVERSTATED | **CONFIRMED — it is 19 of 20** (P7) |
| O3 | §4.3's speculation about the `+0xF149` consumer | OVERSTATED | **CONFIRMED, and disposed of by evidence** (P8) |
| U1 | `DAT_00DFBD77` / `DAT_00DFBD78` | UNVERIFIABLE | **✅ CLOSED — named by the engine itself** (P2) |
| U2 | the unwritten second dword of the 16-byte payload | UNVERIFIABLE | **✅ CLOSED — never read** (P3) |
| U3 | identity of `[0x01176170]` | UNVERIFIABLE | **✅ CLOSED on role — the online/multiplayer services game system (Xbox `PgSysNetOnline`)**; layout corrected (P4) |
| M1 | app-stack layer 4 ticks the state pump | MISSING | **CONFIRMED + provenance corrected + `FUN_004C13A0`'s role corrected** (P5) |
| M2 | `m2("enter")` / `m2("exit")` broadcast tags | MISSING | **CONFIRMED** (P8) |
| M3 | slot 10 = `flush`, slot 11 = `connecting` | MISSING | **CONFIRMED** (P7) |
| M4 | `+0xF0E5` is read in `.text` | MISSING | **CONFIRMED — five readers, not two** (P8) |
| M5 | `0x006D5640` is hot-patched in the dump | MISSING | **CONFIRMED — exactly 3 patches image-wide** (P8) |
| §A9.1 | state slot 7 `0x53056C27` | not established | **STILL OPEN** (S1) |
| §A9.2 | `[0x01176170]` identity | not established | see U3 / **S2** |
| §A9.3 | `[0x01175A94]`, `[0x01175F58]`, `[0x00DFBD77/78]` runtime values | not established | **`77`/`78` closed; `0x01175F58` and `0x01175A94` decoded statically** (P2, P5) |
| §A9.4 | `0x0059F990`, `0x005A0330`, `0x004C0FF0` split thunks | not established | **STILL OPEN — deref demonstrated, destination is a VM stub** (S3) |
| §A9.5 | bulk `memcpy` of the `+0xF149` buffer | not established | **STILL OPEN** (S4) |
| §9.4 | `FUN_0045E440` / `FUN_0045E3F0` | map open item | **STILL OPEN — deref demonstrated** (S3) |
| §9.5 | `FUN_006B3560` | map open item | **STILL OPEN — deref demonstrated** (S3) |
| §9.8 | `Pg.RemoveContextAction` `0x005D7820` | map open item | **partially closed — return shape read** (P9) |
| §2 | `corpus_calls` census | unexamined | **numbers CONFIRMED; provenance CONTRADICTED** (P9) |
| §6.2 | `Pg.AddContextAction` body | unexamined | **CONTRADICTED** (P1) |
| §6.3 | `Report` ruling-out | unexamined | **CONFIRMED, both sides** (P9) |
| §3.3 | the two event rings | unexamined | **CONFIRMED; a THIRD ring found** (P9) |
| §8 | `Junk.IsInstallable` / `Sys.NoHud` alias | unexamined | **CONFIRMED — and the body is `push false`** (P9) |
| §3.6 | `Sys.SetSkipMission` unbounded `strcpy` | unexamined | **CONFIRMED** (P9) |
| — | sibling-map boundary claims | out of scope | **now tested — 3 are wrong** (P10) |

---

### P1. The headline correction, re-derived — and its full consequence sweep

`FUN_004B2A50`, byte-for-byte identical in `mercs2_unpacked.exe` **and** `mercs2_nodrm_v3.exe`:

```
004B2A50  8b0e            mov  ecx, [esi]          ; ecx = L
004B2A52  b801000000      mov  eax, 1
004B2A57  e874ab3a00      call 0x85d5d0            ; lua_checkstack(L, 1)
004B2A5C  85c0            test eax, eax
004B2A5E  7501            jne  0x4b2a61
004B2A60  c3              ret                      ; eax = 0  -> 0 results
004B2A61  8b06            mov  eax, [esi]
004B2A63  8b4808          mov  ecx, [eax + 8]      ; L->top
004B2A66  c741040000...   mov  dword [ecx + 4], 0  ; tt = LUA_TNIL
004B2A6D  83400808        add  dword [eax + 8], 8  ; top++
004B2A71  b801000000      mov  eax, 1              ; 1 result
004B2A76  c3              ret
```

`0x0085D5D0` verified as `lua_checkstack`: it computes `((L->top - L->base) >> 3) + n`, refuses above
`0x800`, and grows via `0x00868160`. It takes no format string and it returns.

**The volume test is decisive.** `FUN_004B2A50` has **288 direct callers** in `.text` (plus one
SecuROM VM trampoline at `.securom:0x0246CECE`, `push 0x0246CEE0; push 0x004B2A50; ret`). `luaL_error`
is not called 288 times from cfunc argument-check paths; the shared "no argument ⇒ return nil" helper
is. Independent corroboration: the compiler **inlined** the identical idiom in several cfuncs, so the
same instruction sequence is visible verbatim at `Sys.SetSkipMission 0x005E5543`,
`Pg.ContractActivated 0x005D7DE3`, `Pg.LoadLayer 0x005D4CBB`, `Pg.IsStaticLayer 0x005D4C23`, and
`Sys.RequestGameState 0x005E4B30`.

**Consequence sweep — all four map sites, plus one Pass 1 never checked:**

| map site | assertion | truth |
|---|---|---|
| §0.5 row `Pg.UnloadLayer` | "`luaL_error FUN_004B2A50` unless …" | **wrong** — it pushes `nil` |
| §5.2 pseudocode | `return luaL_error(L); // ★ cannot unload a STATIC layer` | **wrong.** Verified at `0x005D4F37`–`0x005D4F55`: `cmp [0x1175f58],0; jne ok; test [eax+0x18],1; jne ok; lea esi,[esp+0x10]; call 0x4b2a50; ret` → `nil` |
| §6.2 | "`Pg.AddContextAction` raises a Lua error (`FUN_004B2A50`) when it returns false" | **wrong, and Pass 1 never read this body.** `0x005D77CB`–`0x005D780E`: `call 0x4b2c60; test al,al; jne 0x5d77e5` — failure → `call 0x4b2a50` = **`nil`**; success (`0x005D77E5`) → `lua_checkstack`, then `mov [top],1; mov [top+4],1; add [L+8],8` = **boolean `true`**. The real contract is **`true` / `nil`**, never an error |
| §10.6 | "…a **Lua error** … Missing this turns a mission-cleanup bug into a silent world corruption instead of the loud error retail gives" | **inverted.** Retail *is* the silent path. A reimpl built to §10.6 raises where retail returns `nil`, and every `if not Pg.UnloadLayer(x)` / `if Pg.AddContextAction(…)` in the corpus takes a different branch |
| §5.2 comment | "unknown layer: `nil`, not an error" | correct — but so is the static-layer branch. **Both branches produce `nil`;** the comment implies a contrast that does not exist |

**C1 CONFIRMED.** It remains the one finding in either pass that changes shipped behaviour if acted on.

---

### P2. ✅ U1 CLOSED — `DAT_00DFBD77` / `DAT_00DFBD78`, settled statically

Three maps gave three readings. None is right. The engine names both bytes itself.

**Step 1 — enumerate WRITERS, not readers.** Against the full `.text` index:

| global | refs in `.text` | **writes** |
|---|--:|--:|
| `DAT_00DFBD77` | 139 | **0** |
| `DAT_00DFBD78` | 167 | **0** |

Then a raw byte-pattern search across **every section of both images** (`.text`, `.rdata`, `.data`,
`Stext`, `Sitext`, `Srdata`, `Sdata`, `Sidata`, **`.securom`**, `.rsrc`) for every store encoding —
`C6 05` (`mov m8,imm8`), all eight `88 xx` (`mov m8,reg8`), `80 0D/25/35` (`or/and/xor m8,imm8`),
`FE 05/0D` (`inc/dec m8`), and all sixteen `0F 9x 05` (`setcc m8`) — returns **zero hits** for either
address. Every one of the 306 references image-wide, in both images, is `80 3D` / `38 xx` (`cmp`) or
`8A xx` (`mov reg8, m8`). **Neither byte is ever written through its own address.**

**Step 2 — find the real writer.** The two bytes sit in a run of adjacent globals
(`0x00DFBD74`, `75`, `76`, `77`, `78`, `79`) that all share that property. The only writer of the run
is a **24-byte bulk publish** in `FUN_006CECF0`:

```
006CED55  mov  byte [esp+0x14 .. esp+0x19], bl      ; default: all six flags = 0
006CEDA8  mov  byte [esp+0x14], 1                   ; a session object exists
006CEDAF  call 0x6cff90                             ; (SecuROM split thunk)
006CEDB6  [esp+0x15] = 1   /  006CEDBD: [esp+0x15] = 0
006CEDC4  mov  eax, [edx+0x0c]                      ; ★ THE SESSION-MODE ENUM
006CEDC7  cmp eax,4 ; sete cl -> [esp+0x16]
006CEDCD  cmp eax,1 ; sete dl -> [esp+0x17]         ; ★ becomes DAT_00DFBD77
006CEDDA  cmp eax,2 ; sete al -> [esp+0x18]         ; ★ becomes DAT_00DFBD78
006CEDEB  mov  byte [esp+0x19], cl                  ; = [session+8]
006CEE87  cmp  dword [[0x1175c7c]+4], 0x57b5e35a    ; == m2("ingame") -> [esp+0x2a]
006CEEB4  movq xmm0,[esp+0x14] ; movq [0xdfbd74], xmm0    <- publish bytes 0..7
006CEEC2  movq xmm0,[esp+0x1c] ; movq [0xdfbd7c], xmm0
006CEED0  movq xmm0,[esp+0x24] ; movq [0xdfbd84], xmm0
```

So `0x00DFBD74`–`0x00DFBD8B` is a **24-byte snapshot struct republished every tick**, and
`DFBD76/77/78` are three **one-hot decodes of one session-mode enum** `[session+0x0C]`. They are
mutually exclusive by construction — a fact no reading in any map captures.

**Step 3 — the names, from the engine's own binding table.** The `Net` `luaL_Reg` table
(`0x00B998D0`, 92 entries) contains one-line predicates that each return exactly one of these bytes:

| VA | binding | body | derivation |
|---|---|---|---|
| `0x005C6710` | **`Net.IsEnabled`** | `mov bl, byte [0xdfbd74]` | a session object exists |
| `0x005C6750` | **`Net.IsActive`** | `mov bl, byte [0xdfbd75]` | `[S+8] && FUN_006CFF90()` |
| `0x005C6790` | **`Net.IsLobby`** | `mov bl, byte [0xdfbd76]` | `sessionMode == 4` |
| `0x005C67D0` | **`Net.IsClient`** | `mov bl, byte [0xdfbd77]` | **`sessionMode == 1`** |
| `0x005C6810` | **`Net.IsServer`** | `mov bl, byte [0xdfbd78]` | **`sessionMode == 2`** |

(`Net.IsMultiplayer` `0x005C66C0` = `IsEnabled == 1 && IsActive != 0`, composed from the same two.)

**Step 4 — a second, fully independent confirmation, with a string-literal fingerprint.** At
`0x005C3A92`–`0x005C3B18` the engine pushes two Flash/Scaleform variables whose *names are in
`.rdata`*:

```
005C3A98  cmp byte [ecx + 0x158], 0     ; ecx = [0x01176170]  (session valid)
005C3AA1  cmp byte [0xdfbd78], 0        ; ★
005C3AAA  al = 1                        ; -> Flash var  edi = 0x00BB72F0 = "multiplayerHost"
005C3ADD  cmp byte [eax + 0x158], 0
005C3AE6  cmp byte [0xdfbd77], 0        ; ★
005C3AEF  al = 1                        ; -> Flash var  edi = 0x00BB7300 = "multiplayerClient"
```

Verified: `0x00BB72F0 = "multiplayerHost"`, `0x00BB7300 = "multiplayerClient"`. **The engine labels
`DAT_00DFBD78` "host" and `DAT_00DFBD77` "client" in its own UI variable names**, independently of
the `Net.*` binding table. Two orthogonal can't-coincide fingerprints agreeing.

> ### Verdict: **`DAT_00DFBD77` = `Net.IsClient`. `DAT_00DFBD78` = `Net.IsServer` (host).**
> Not "remote/client-ish role" + "a session is networked"; not a "shutdown/teardown guard".
> `Net.IsEnabled` (`0x00DFBD74`) is the flag that means "a session exists" — the meaning the map
> assigned to `78`. **Confidence H, static, no live capture required**, on two independent lines of
> evidence. §9.10's live item is closed.

**Every gate in the map re-reads correctly and more sharply:**

- `Pg.LoadLayer` `0x005D4CF7`: `if (IsClient && bDynamic) return 0 values;` — **a client refuses to
  load a dynamic layer locally**; it waits for the server's replication.
- `Pg.LoadLayer` step 4 (`if IsServer && bDynamic → FUN_006C7390`) — **the server replicates the load.**
- `Pg.UnloadLayer` `0x005D4E49`: `if (IsClient && cur_state != m2("unloading")) return 0 values;` —
  **a client may only unload during teardown.**
- `Pg.ContractActivated` `0x005D7E14`: the two byte-clears at `[0x01176164]+0x5550/+0x5552` fire
  **only on the server**.
- **All eleven `Net.SendEvent_*Objective*` senders** gate on `IsEnabled && IsServer` — see P6.

**N2 — latent NULL-deref found while reading the gate.** `Pg.UnloadLayer` at `0x005D4E55` does
`mov eax,[0x1175c7c]; cmp dword [eax+4], 0x7d0b162c` with **no null check on `eax`**. Because §3.2
proves an unrecognised `Sys.RequestGameState` string leaves `DAT_01175C7C == NULL`, a co-op **client**
calling `Pg.UnloadLayer` while no game state is current **dereferences NULL+4**. Reachable, not
theoretical; belongs in `docs/fixpack/bug_register.md`.

---

### P3. ✅ U2 CLOSED — the unwritten second dword is never read

**Producer** (`Sys.RequestGameState` `0x005E4AF0`, publish path):

```
005E4BF7  mov  eax, [esp+0x10]      ; the optional 2nd hashed arg (defaulted to 0 at 0x005E4B5C)
005E4BFB  mov  [esp+0x18], esi      ; word 0 = the state-name hash
005E4BFF  lea  esi, [esp+0x18]      ; &msg
005E4C03  mov  [esp+0x20], eax      ; word 2 = the 2nd arg
005E4C07  mov  dword [esp+0x24], 0  ; word 3 = 0
005E4C0F  call 0x4bdd10             ; publish 16 bytes from [esi]
```

`[esp+0x1C]` — **word 1** — is never written. Confirmed.

**Ring** (`FUN_004BDD10`): 20 slots (`cmp eax, 0x14`), stride `0x10` (`shl eax,4; add eax,0x0120F510`),
count `0x0120F4E8`, per-slot subscriber mask `byte [i + 0x0120F650] = [0x0120F4EC]`, per-subscriber
counters `0x0120F4F0[]`, `EnterCriticalSection(0x0120F66C)` with the owner TID stashed at `0x0120F668`,
disabled by `[0x0120F664] != 0`. The publish copies the **full 16 bytes** verbatim (two `movq`), so
word 1's stack residue *does* reach the ring.

**Consumer** (`FUN_004C09C0`, phase 2). The drained message lands at `[esp+0x20]`. Every
`esp`-relative access in the whole function body (`0x004C09C0`–`0x004C0C20`), enumerated from the index:

```
004C0A5D  lea edx, [esp+0x20]     ; &msg for the drain
004C0A7D  cmp eax, [esp+0x20]     ; word 0 vs current state hash
004C0AAE  mov eax, [esp+0x2c]     ; word 3  -> stack arg 2
004C0AB2  mov ecx, [esp+0x28]     ; word 2  -> stack arg 1
004C0AB6  mov edx, [esp+0x20]     ; word 0  -> REGISTER arg (edx)
004C0AC8  lea edx, [esp+0x20]     ; &msg for the next drain
```

**`[esp+0x24]` does not occur.** `FUN_004C0F10` confirms the signature: `cmp [ecx+4], edx` at
`0x004C0F2B` — the hash arrives in **`edx`**, exactly the register argument Ghidra drops (trap 1) —
and `ret 8` (two stack args).

**A second, independent producer confirms it.** `Sys.RequestGameState` is not the only publisher —
`FUN_004BDD10` has 36 callers, and the state classes publish directly. State slot 7's `Update`
(`0x004BA7D0`) builds its request at `[esp+0x10]`:

```
004BA802  mov dword [esp+0x10], 0x57b5e35a   ; word 0 = m2("ingame")
                                             ; word 1 ([esp+0x14]) -- NEVER WRITTEN
004BA80A  mov dword [esp+0x18], ebx (=0)     ; word 2
004BA80E  mov dword [esp+0x1c], ebx (=0)     ; word 3
004BA812  call 0x4bdd10
```

So **leaving word 1 unwritten is the engine-wide convention, not a slip in one cfunc** — the field is
simply unused in this message type. That settles §3.4 fact 3 beyond the single call site.

> ### Verdict: the uninitialised dword is **word 1**, and **no consumer reads it**.
> There is **no shipped uninitialised-read** — the field is unused by convention across producers.
> §3.4 fact 3 and §9.6 close **statically**. The map's guess ("harmless if the consumer only reads
> words 0 and 2") is right about harmlessness but wrong about the shape — the consumer reads words
> **0, 2 and 3**.

---

### P4. ✅ U3 CLOSED on role — `[0x01176170]` is the online/multiplayer services game system

`[0x01176170] == 0x014CF228` (a **static** object in `.data`, installed by `FUN_004C00E0`). Vtable
`0x00BCFE84`, **74 slots** (`+0x00`..`+0x124`, NULL at `+0x128`), bodies in `0x006C8210`–`0x006CAD90`.

**The master key was applied and returns a hard negative.** Positive controls first — for the three
verified ECS containers it works exactly as documented:

| container object | vtable | `[vtable+0x34]` | body | name |
|---|---|---|---|---|
| `0x00DF9B90` | `0x00BC3FB8` | `0x00647BA0` | `mov eax, 0xBC5DAC; ret` | `Players` |
| `0x017BEF78` | `0x00BC24D8` | `0x00644CC0` | `mov eax, 0xBC57E4; ret` | `RuntimeHealth` |
| `0x00DF8188` | `0x00BBFD10` | `0x006418E0` | `mov eax, 0xBC5108; ret` | `SeatLink` |

For `[0x01176170]`: **`[0x00BCFE84 + 0x34] = 0x00848E30`, whose entire body is `C2 04 00 = ret 4`** —
the class's shared do-nothing slot (it also fills `+0x30`, `+0x40`, `+0x48`, `+0x4C`, `+0x50`, `+0x94`,
`+0x98`, `+0xA8`..`+0xB4`, `+0xBC`, `+0xC0`, `+0xDC`..`+0x104`). A sweep of **all 74 slots** finds
**no `mov eax,<char*>; ret` name-getter anywhere in the vtable.**

> **This object is not an ECS container.** The master key is genuinely inapplicable, not merely
> untried. Pass 1's RTTI attempt is also confirmed dead: `[vtable-4] = 0x005D7325`, a `.text` address,
> not an `RTTICompleteObjectLocator`.

**N3 — layout corrected. The record array's base is `+0x1C8`, not `+0x208`.** From the ctor:

```
006C8B51  lea edi, [esi + 0x208]
006C8B57  mov ebp, 0x100                       ; 256 iterations
006C8B60  memset(edi - 0x40, 0, 0x40)          ; name A   <- the record base is edi-0x40
006C8B6C  memset(edi      , 0, 0x40)           ; name B
006C8B75  memset(edi + 0x40, 0, 0x40)          ; name C
006C8B81  [edi+0x80]=[edi+0x84]=0 (dwords); [edi+0x88]=[edi+0x89]=0 (bytes);
          [edi+0x8c]=[edi+0x90]=[edi+0x94]=0 (dwords)
006C8BAE  edi += 0xD8 ; ebp-- ; loop
006C8BE0  add esi, 0xd9c8                      ; = 0x1C8 + 0x100*0xD8   <- proves the base
```

Confirmed continuation: `+0xDA65` a `0x1680`-byte block ending exactly at `+0xF0E5`; `+0xF0E5` a
`0x40`-byte name; `+0xF148` / `+0xF149`; `+0xF18A` a byte set to 1. So **`+0x1C8` = `0x100` records of
`0xD8` (three `0x40`-B names + `0x18` of scalars), ending at `+0xD9C8`.** The map's and Pass 1's
`+0x208` is the *second* name buffer of record 0 — both are off by `-0x40`; the count and stride are right.

**The identity, established by five converging lines.**

1. **It is a `PgSys*` game system.** Vtable slot `+0x0C` (`0x006C8CD0`) is `Init`: it calls
   `FUN_006C8A20` (a *reset*, not a ctor — it is also called from static-init `0x006C8CA0` and from
   `Shutdown` `0x006C8DD1`), then stores `[this+0x14C] = FUN_0060CF90()`. `docs/data/keystone_code_map.json:202`
   already identifies `FUN_0060CF90` as the **"PgSys 32-slot ID allocator"**, corroborated against
   Xbox `PgSysVehicle`. Slot `+0x10` (`0x006C8D80`) is `Shutdown` and releases it via `FUN_0060CFC0`.
   `output/jul08_prototype/pairing/source_paths.txt` names `Pangea\Src\PgGameSystem.cpp` as the host TU.
2. **It owns the EA online/FESL client.** `Init` allocates a **0x7450-byte** SDK object into
   `[this+0x144]`, computes the FESL B-version (`[0x017C0DF8]` / `[0x01175C68] ^ 0x6B3C35EB`, default
   `0xECE78C8C` → `mercs2-pc_ver_-320369524`), and installs `this+0x1C` as the SDK's callback listener
   (`[sdk+0x34] = this+0x1C`). `networking_code_map.md:153` already calls `FUN_006C8CD0` "FESL version
   compute" without realising it is this object's `Init`.
3. **Its translation unit is entirely online/lobby.** The `.rdata` string pool at
   `0x00BCFCC4`–`0x00BCFE78`, immediately preceding the vtable: `OpenShell`, `connectingToGame`,
   `hostingDialog`, `LTIstopConnectingDisplay`, `quickMatchNotAvailableInLan`,
   `optiMatchNotAvailableInLan`, `optiMatchNotSignedInToLive`, `removeLeaderboardEntries`,
   `addLeaderboardEntry`, `connectingDisplay`, `onlineLobbyNotSignedInToLive`,
   `serverCreationErrorPlayOffline`, `optimatch`, `ViewEATerms`, `LTIUnlockableResult`.
4. **The Xbox pairing puts those strings inside this vtable's slots.**
   `output/jul08_prototype/pairing/string_func_map.json`: `hostingDialog` → `FUN_006C98B0` (slot
   `+0x3C`), `optiMatchNot*` → `FUN_006C9F50` (`+0xA0`), `onlineLobbyNotSignedInToLive` →
   `FUN_006CADD0`, `serverCreationErrorPlayOffline` → `FUN_006CB3C0`.
5. **`PgSysNetOnline` exists as an Xbox profiler label.** `mercs2_xenon_p.pe_full_strings.txt` carries
   16 `PgSysNet*` labels; fifteen are replication categories that map 1:1 onto the PC category
   vocabulary at `0x00BD0590+`. The sixteenth, **`PgSysNetOnline`**, is the only online-services one
   and is unmatched in that category list — exactly as a services (not replication) system would be.

> ### Verdict: `[0x01176170]` is the **online / multiplayer-services Pangea game system**, Xbox label
> **`PgSysNetOnline`**. The **role is proven**; the exact label string is strongly supported but not
> closed, because the PC release build strips all `PgSys*` labels. Residual alternative:
> `PgSysNetworking` — argued against because the transport/peer-mesh layer lives at `0x009Cxxxx` /
> `0x0084xxxx` and Xbox `PgSysNetworking` registers in a different family mask.

**Field map, now nailed** (each verified first-hand where marked ✓):

| offset | meaning | evidence |
|---|---|---|
| `+0x00 / +0x14 / +0x18 / +0x1C` | **four vtables**, not one: `0x00BCFE84` (74) / `0x00BCFEB0` (63) / `0x00BCFFB0` (36) / `0x00BD0040` (48) | ✓ `FUN_006C8C60` writes all four at `0x006C8C78`–`0x006C8C96`. The `+0x1C` sub-object is the **EA SDK listener** (its tail slots are the SDK base class's own methods) |
| `+0x144` / `+0x148` / `+0x14C` | EA online SDK object / registrar handle / **PgSys slot id** | `Init 0x006C8CD0` |
| `+0x154` | gate for "play offline" level start | `Net.DialogBoxPlayOffline` `0x005CAD90` |
| **`+0x158`** | **multiplayer session valid** | ✓ `0x005C3A98` / `0x005C3ADD` — with `Net.IsServer` → Flash `multiplayerHost`; with `Net.IsClient` → Flash `multiplayerClient` |
| **`+0x1C8`** | `0x100` × `0xD8` **game / server-browser list** (3 × `0x40` names + 6 scalars) | ✓ ctor; matches the `LobbyServerAdded` payload `sName`/`sMap`/`sContract`/`nStatus`/`bFriendlyFire` built at `0x0060A49D` |
| `+0xD9C8` | `0x98`-byte session descriptor | matches the `AddOptimatchResult` emitter `0x006CB930` (str / 3 ints / str / 3 ints = `0x98`) |
| `+0xDA64` | bool forcing event publication | `0x004BA349`, `0x004BA986`, `0x004BD677` |
| **`+0xF0E5`** | **`player2Name` — the co-op partner's name** | ✓ `0x005C3A5E` pushes it as a type-4 (string) arg for Flash var `0x00BB72E4 = "player2Name"` |
| `+0xF149` | `sContract` | as established |
| size | **`0xF190`** (fields to `0xF18C`) | ✓ the next static singleton `[0x01176140] = 0x014DE3B8` is **exactly `0xF190`** above `0x014CF228` |

**Two corrections to my own P8/M4 reading, made on this evidence.** `+0xF0E5` is **not** a
"session-advertised level/mission name" — it is the **co-op partner's player name**. And the debug tag
is not a class name: the *generic* format `"[0x%08x:%s]"` sits at `0x00BCFE78` (✓ verified), so
`"[0x6ad9b549:%s]"` at `0x00BCF438` is a constant-folded `[tag:value]` debug line whose `%s` is
`player2Name`. That is why `0x6AD9B549` resisted cracking — and why it never mattered.

**This makes the write-only finding sharper, not weaker.** `sContract` lives inside the *online
services* system, in the same struct as the server-browser list whose records carry an `sContract`
field. `Pg.ContractActivated` writing a name there, on a struct whose neighbouring fields are all
published to peers and to the crash reporter, reads as **a lobby/server-browser advertisement that was
never wired up on PC** — which is exactly consistent with `ContractCompleted == ContractCancelled` and
with there being no reader.

*To close the label string live:* break `0x006C8CD0` and read `[this+0x14C]`'s allocated slot index,
or HW-write-watch the `+0x1C8` array during a lobby refresh and confirm the three names are
session / map / contract.

---

### P5. M1 — CONFIRMED, provenance corrected, and **state-gating does NOT survive as stated**

**The linkage is confirmed by a stronger test than either pass applied.** Against the full index,
counting *both* direct branches *and* every occurrence of the literal address in **every section**:

| function | direct branches | literal-address occurrences image-wide |
|---|--:|---|
| `FUN_004C9740` (per-system pump) | **1** — `call` at `0x004C0ED6` | **0** |
| `FUN_004C0EC0` | **1** — `call` at `0x004C0B6A` | **0** |
| `FUN_004C09C0` (state pump) | **1** — `call` at `0x004C13D8` | **1** — `.rdata:0x00BB046C` |
| `FUN_004C15E0` | 1 — `call` at `0x004C153B` | 0 |
| `FUN_004C14F0` | **2** — `0x00630FAC`, `0x00630FC2` (both in `FUN_00630EF0`) | 0 |
| `FUN_004C0F10` / `FUN_004C0FA0` | 1 each, both inside `FUN_004C09C0` | 0 |

`0x00BB046C` is `vtable 0x00BB0460 + 0x0C` — app-stack layer 4's tick slot; `FUN_004C15E0` reaches it
at `0x004C163C` (`mov edx,[eax+0xC]; call edx`). **Confirmed: app-stack index 4 ticks the state pump,
and "layer 4 of the master update" is literally app-stack index 4. Both drawings were right.**

**N5 — provenance correction: the array is NOT statically initialised.** Pass 1's M1 says "the array
is **statically initialised** in `.data`". It is not. `FUN_004C1170` zero-fills
`0x017BBCCC`..`0x017BBCF3` (`pxor xmm0,xmm0` + five `movq`) and then **populates it at runtime**:

```
004C11F9  [0x017BBCCC + 0*4] = 0x00D6C22C ; count -> 1
004C1211  [           + 1*4] = 0x014538B8 ; count -> 2
004C1229  [           + 2*4] = 0x0149FDA0 ; count -> 3
004C1241  [           + 3*4] = 0x00D6C238 ; count -> 4
004C1259  [           + 4*4] = 0x00D6C244 ; count -> 5     * the state pump's owner
004C1274  [0x017BBCFC] = count - 1 = 4                     ; the stage target
```

Proof: in `mercs2_nodrm_v3.exe` all seven slots and the count read **`0x00000000`**. The values exist
in the dump **only because the artifact is a live memory image**. The conclusion is unaffected; the
method claim is false and would mislead anyone re-deriving from a clean exe. (All five layers share
`vt+0x04 = 0x004BE070` and `vt+0x08 = 0x004BE090` — the enter/exit slots are a shared base-class
no-op; only `vt+0x0C` differs.)

**Bonus — the whole app stack, resolved, and one more virtual-call correction.** The five ticks are:

| idx | object | vtable | `vt+0x0C` (tick) | what it is |
|--:|---|---|---|---|
| 0 | `0x00D6C22C` | `0x00BB0420` | `0x004BEEA0` | — |
| 1 | `0x014538B8` | `0x00BB0430` | `0x004BEED0` | — |
| 2 | `0x0149FDA0` | `0x00BB0440` | `0x004BFAF0` | — |
| **3** | `0x00D6C238` | `0x00BB0450` | **`0x004C00E0`** | **the singleton install table** |
| **4** | `0x00D6C244` | `0x00BB0460` | **`0x004C09C0`** | **the game-state pump** |

`FUN_004C00E0` has **zero direct callers** in `.text` and **exactly one** literal-address occurrence
image-wide — `.rdata:0x00BB045C`, which is `vtable 0x00BB0450 + 0x0C`. So §0.5's and §4.4's "called
three times from `FUN_004C15E0`" describes the *effect* (the stepper re-ticks a layer while its phase
climbs) but not the *mechanism*: it is **app-stack layer 3's `Update`**, reached by the same virtual
call as the state pump. This is the map's own trap 3 landing twice in the same stepper. Net picture:
**layer 3 installs the singletons, layer 4 pumps the game states.**

**N4 — role correction: `FUN_004C13A0` is the SHUTDOWN driver, not a second per-frame entry.** Both
the map's §3.5 diagram (`FUN_00631670 → FUN_004C13A0 → FUN_004C09C0 ★ GAME-STATE MACHINE PUMP`) and
Pass 1's §A6 ("the pump is reached from `FUN_004C13A0` ← `FUN_00631670`, whereas `FUN_004C15E0` … does
not reach it") have the two paths the wrong way round:

```
004C13BA  cmp  dword [0xd6c24c], 2      ; = layer-4 object (0xD6C244) + 8 = its PHASE
004C13C1  jne  skip
004C13C3  mov  dword [0xd6c24c], 3      ; force phase 2 -> 3  (= SHUTDOWN)
004C13CD  fldz                          ; dt = 0.0
004C13D0  mov  ecx, 0xd6c244            ; this = app-stack layer 4 -- THE SAME OBJECT
004C13D8  call 0x4c09c0                 ; pump it once so it takes its phase-3 branch
```

and its **only** caller is `0x00631AAF`, three instructions before the enclosing function's `ret`,
immediately after tearing down `[0x00EDB228]`. `FUN_004C14F0` (the master update) is called **twice**
from `FUN_00630EF0` (RunFrame) and is the sole per-frame path.

> **Corrected chain:** `FUN_00631670 WinMain → FUN_00630EF0 RunFrame → FUN_004C14F0 → FUN_004C15E0
> (app-stack stepper) → app-stack[4] = 0x00D6C244, vtable 0x00BB0460, +0x0C → FUN_004C09C0 (state
> pump) → FUN_004C0EC0 → FUN_004C9740 (per-system tick)`, with `FUN_004C13A0` a **one-shot shutdown
> pump** (`dt = 0.0`, phase forced to 3) on the same object at process exit.

**Does state-gating survive? Read `FUN_004C09C0`'s dispatch.** Phase is `[this+8]`; 1 → init
(`0x004C0BC2`), 2 → drain + run (`0x004C0A5A`), 3 → exit (`0x004C0A0A`), anything else → return.
The run block, in order:

```
004C0AD6  ecx=[0x1175cdc]; if ((([ecx+0x40]>>3) & 1)
              && GetForegroundWindow() != [0x117601c]   ; USER32!GetForegroundWindow, IAT 0x00B054BC
              && [[0x1175fb0]+0x20] != 0)       goto Sleep(100)  ; KERNEL32!Sleep, IAT 0x00B0518C
004C0B08  if ([0x1175a94] == 1)                 goto Sleep(100)
004C0B14  cur = [0x1175c7c]
          if (cur) { [0x1175a78] += [0xd26394];
                     (*cur->vt[0x10])(dt);                ; tick the current state
                     if ([0x1175c7c] && [cur+4] == m2("ingame")) FUN_004C0C70(); }
004C0B5B  if ([0x1175a94] != 1) { FUN_004C0EC0(dt);       ; * -> FUN_004C9740, the SIM TICK
                                  FUN_004C0CC0(); }
          else                  { if (FUN_0074CC80()) { [0xdfc2f8] vt+4, vt+0xC, vt+8 }
                                  FUN_004C0CC0(); }
```

**Two corrections fall out.**

1. **Which game state you are in does NOT gate the simulation.** At `0x004C0B14` a NULL current state
   (`je 0x4c0b5b`) skips only the **state's own `Update`**; control falls straight to `0x004C0B5B`,
   which still calls `FUN_004C0EC0` → `FUN_004C9740`. So the map's §0 headline — *"the whole per-frame
   system pump `FUN_004C9740` is reached **only** through the game-state machine's RUN phase, so
   **'which game state am I in' gates the simulation itself**"* — is **half right**: the first clause
   is proven (one caller, zero literal occurrences image-wide), the second is **false**. The
   simulation runs with no current state at all. §3.2's "a null current state makes … the pump skip
   its tick" is true of the *state* tick and false of the *system* pump.
   The accurate statement: **the per-system pump is gated on the app-stack layer's own phase being 2,
   and on the two `Sleep` predicates — not on the game state.**
2. **`[0x01175A94]` is not a pause/minimise flag.** Pass 1 guessed "likely a pause/minimise flag;
   needs a live capture". It decodes statically as a **handshake between a game state and RunFrame**:
   a state writes `1` (`0x004BBD84`, inside a `0x004BBxxx` state body, then returns immediately);
   `FUN_00630EF0` sees `1` at `0x00630F02`, runs `FUN_004C0730`, clears bit 2 of
   `[[0x1175cdc]+0x40]`, resets `[+0x3C]`, and writes **`2`** at `0x00630F26`; the state polls for `2`
   at `0x004BBDA0` / `0x004BC909`. It is a **level-transition / device-reset handshake**, and the
   simulation is suspended (`Sleep(100)`) for its duration. Twelve refs total, eight of them writes,
   all in `FUN_00630EF0` and the loading/unloading state bodies. **The foreground check is a separate,
   third predicate** — the map's §3.5 conflates the two into one "background throttle".

`DAT_01175F58` also decodes fully and confirms the map: **exactly 4 refs** — `push 0x1175f58` at
`0x005D4B57` (`Pg.UnloadingStaticLayers` passes its address to `FUN_0059F6D0`), `mov bl,[…]` at
`0x005D4BA1` (the getter), and the two gate reads at `0x005D4C3A` (`IsStaticLayer`) and `0x005D4F37`
(`UnloadLayer`). Nothing else touches it.

---

### P6. C2 — CONFIRMED, and the co-op implication settled

Own walk of the `Net` `luaL_Reg` table (`0x00B998D0`, 92 entries, 2 stubs):

| slot | binding | VA | |
|--:|---|---|---|
| 29 | `SendEvent_AddObjective` | `0x006D5640` | **STUB** |
| 30 | `SendEvent_RemoveObjective` | `0x006D5640` | **STUB** |
| 31 | `SendEvent_AddRadarObjective` | `0x005C7150` | real |
| 32 | `SendEvent_RemoveRadarObjective` | `0x005C79F0` | real |
| 33 | `SendEvent_AddMarkerObjective` | `0x005C74B0` | real |
| 34 | `SendEvent_RemoveMarkerObjective` | `0x005C7BA0` | real |
| 35 | `SendEvent_AddPdaObjective` | `0x005C77E0` | real |
| 36 | `SendEvent_RemovePdaObjective` | `0x005C7AC0` | real |
| 42 | `SendEvent_ObjectiveMessage` | `0x005C8530` | real |
| 49 | `SendEvent_SetObjectiveTraySlotText` | `0x005C8A90` | real |
| 50 | `SendEvent_SetObjectiveTraySlotImage` | `0x005C8C20` | real |
| 51 | `SendEvent_ClearObjectiveTraySlot` | `0x005C8DF0` | real |

**Ten real, two stubbed** — exactly the two *generic* ones. Pass 1's C2 CONFIRMED (it named five;
there are ten).

**The co-op desync implication, settled.** `SendEvent_AddMarkerObjective` `0x005C74B0` opens with:

```
005C74B3  cmp byte [0xdfbd74], 0   ; Net.IsEnabled
005C74C3  je  0x5c779e             ;   -> early out, do nothing
005C74C9  cmp byte [0xdfbd78], 0   ; Net.IsServer
005C74D0  je  0x5c779e             ;   -> early out, do nothing
```

All eleven senders carry the same pair. Combined with P2:

> **Objective replication is server-authoritative and shares its gate with layer replication.**
> On a **client** (`Net.IsClient`), `Pg.LoadLayer(name, true, …)` is refused outright *and* every
> `Net.SendEvent_*Objective*` is a silent no-op. A co-op client receives its mission layers and its
> objective markers **only** by replication from the server. §9.10's suspicion ("a candidate root
> cause for co-op mission desync") is **structurally correct and now named**: the single point of
> failure is `Net.IsServer`. If the wrong peer runs mission Lua it loads no layers and emits no
> objective events, and **nothing errors** — both refusals are silent (`return 0 values` / early
> `ret`), consistent with P1.

The map's §6.1 sentence — "a devkit-build surface that retail PC does not expose to script" — is
falsified by its own binding table. Accurate statement: **the *abstract* objective was cut
(`Gui.AddObjective` and the two generic `Net.SendEvent_*Objective` rows are the shared `return-0`
stub); the concrete radar / marker / PDA / tray objective replication survives in full, including its
co-op senders, gated on `Net.IsServer`.**

---

### P7. O1 / O2 / O3

**O1 — CONFIRMED overstated.** `FUN_0059FB00` fetches a `char*` and hashes it; the Lua-visible
argument is a **string**. The bolded §3.4 headline "The argument is a hash, not a string" is wrong;
the paragraph under it is right and §10.2's advice is right.

**O2 / M3 — CONFIRMED. It is 19 of 20, not 17.** Independent walk of the state table, reading each
object's `+4` and reproducing every name with `m2` myself:

| slot | hash | name | `m2` ok | vtable | Update |
|--:|---|---|:-:|---|---|
| 0 | `C8192FE5` | `pause` | yes | `00BB00D4` | `004B9510` |
| 1 | `96FB0F27` | `loading` | yes | `00BB00F0` | `004B9AF0` |
| 2 | `7D0B162C` | `unloading` | yes | `00BB01B4` | `004BB230` |
| 3 | `20BC86EA` | `unloadshell` | yes | `00BB01D0` | `004BC6D0` |
| 4 | `05CE7A0C` | **`waitforplayer`** | yes | `00BB010C` | `004B9E40` |
| 5 | `7E289119` | `waitforstreaming` | yes | `00BB0128` | `004BA200` |
| 6 | `9B7AD367` | `waitfortether` | yes | `00BB0160` | `004BA960` |
| **7** | **`53056C27`** | **UNCRACKED** | — | `00BB0144` | `004BA7D0` |
| 8 | `51BFF7B1` | `shell` | yes | `00BB00B8` | `004B8D60` |
| 9 | `FDC8B95E` | `reset` | yes | `00BB0198` | `004BCC90` |
| 10 | `6D19FA15` | **`flush`** | yes | `00BB017C` | `004BAD90` |
| 11 | `38929BF7` | **`connecting`** | yes | `00BB01EC` | **`00848E30` (no-op)** |
| 12 | `9AC591FB` | `lobby` | yes | `00BB0208` | `004BD160` |
| 13 | `72558BE0` | `online` | yes | `00BB02B8` | `004BD420` |
| 14 | `57B5E35A` | `ingame` | yes | `00BB0368` | `004BD500` |
| 15 | `B8CB300C` | `cinematic` | yes | `00BB0384` | `004BD670` |
| 16 | `EE0915FC` | `attract` | yes | `00BB03BC` | `004BD9A0` |
| 17 | `CE7E5A43` | `exiting` | yes | `00BB03D8` | **`00848E30` (no-op)** |
| 18 | `ED87E746` | `lti_precache` | yes | `00BB03F4` | `004BDB00` |
| 19 | `FA62754E` | `pda` | yes | `00BB03A0` | `004BD810` |

§9.1 has **one** item left, not four. Two additions of my own:

- **The state objects are static; the state TABLE is not.** `0x01175C80[0..22]` is **all zeros** in
  `mercs2_nodrm_v3.exe` and is populated at runtime by `FUN_004C0FF0` (`mov [eax*4 + 0x1175c80], edx`
  at `0x004C100D`, first-free-slot scan bounded by `cmp eax, 0x17`). The *objects* at `0x00DCBAFC`…
  `0x00DCBC28` **are** static (identical dump vs disk, vtable and hash both). §3.1's "statically
  initialised in `.data`" is true of the objects and false of the array. (Same class of error as N5.)
- **Two of the twenty states have a no-op `Update`** (`connecting`, `exiting` → `0x00848E30`,
  `ret 4`). Worth a line in §10 for a reimpl.

**O3 — CONFIRMED overstated, and disposed of by evidence.** See M4 in P8: `+0xF0E5` has **five**
in-`.text` readers. §4.3's guess ("the plausible consumer is an out-of-`.text` one: a crash/telemetry
dump, or the SecuROM-virtualised region") is both unsupported and unnecessary.

---

### P8. M2 / M4 / M5

**M2 — CONFIRMED.** `m2("enter") == 0x9DA97065`, `m2("exit") == 0xDB41017D`, reproduced. Structure
read first-hand: `FUN_004C0F10` at `0x004C0F6F`–`0x004C0F83` builds `{0, cur->nameHash, 0x9DA97065}`
and calls `FUN_004C9E70`; the pump's exit path at `0x004C0A97`–`0x004C0AA3` builds
`{0, cur->nameHash, 0xDB41017D}` (edi loaded at `0x004C0A6B`) into the same function. The map has the
enter tag as uncracked and never records the exit tag. §9.2 closes statically.

**M4 — CONFIRMED, and materially stronger than Pass 1 reported.** A recursive-descent scan of `.text`
for displacement `0xF0E5` returns **seven** sites, not the two or three Pass 1 cites:

| site | role |
|---|---|
| `0x005C3A6F` | **NEW** — `FUN_005C37E0` (8,064 B, the `Net` state publisher) packs it as a type-4 (string) arg to the Flash variable **`player2Name`** (`0x00BB72E4`), immediately before setting `multiplayerHost` / `multiplayerClient` from `+0x158 && Net.IsServer` / `Net.IsClient` |
| `0x00616F4F` | **NEW** — a second packer of the same shape |
| `0x006C26A3` | crash-report path (guard) |
| `0x006C2704` | **NEW** — a second crash-report use |
| `0x006C3FF2` | debug overlay `_snprintf(buf, 0x7F, "[0x6ad9b549:%s]", …)` (format at `0x00BCF438`) |
| `0x006C8BCD` | ctor `memset(…, 0, 0x40)` |
| `0x006C8EC3` | **NEW** |

and `0x006C26B7` `strncpy`s it into the crash-report global `0x00EDB1D8` (terminator cleared at
`0x00EDB217`, so a `0x40`-byte field). **Same struct, same `0x40` size, same breadcrumb shape — five
readers.** By contrast the same scan for `0xF149` returns **exactly three sites, all writes**
(`0x005D7E03`, `0x005D7E4B`, `0x006C8B28`), reproducing the map's and Pass 1's count with a stronger
method. The write-only conclusion is now a **contrast against a positive control**, not an argument
from absence.

**M5 — CONFIRMED and bounded.** A byte-for-byte diff of `.text` between `mercs2_unpacked.exe` and
`mercs2_nodrm_v3.exe` finds **exactly three differing runs, all 5 bytes, all `E9` (jmp) to
`0x6Fxxxxxx` (outside the image):**

| VA | dump | nodrm_v3 | what it is |
|---|---|---|---|
| `0x005E9DE0` | `E9 1B 7C 6A 6F` | `55 8B EC 83 E4 F8 …` | **`VO.Cue`** |
| `0x005E9F40` | `E9 7B 7A 6A 6F` | `55 8B EC 83 E4 F8 …` | **`VO.CueWithoutSubtitles`** |
| `0x006D5640` | `E9 7B CA 5F 6F` | `33 C0 C3` | the shared `return-0` stub |

**There are no other hooks in `.text`.** The two extras are `pmc_bb.dll`'s VO logging and are
irrelevant to this map; `0x006D5640` **is** in this map's slice (`Gui.AddObjective`,
`Pg.LoadingStaticLayers`, `Pg.GetLoadingStaticLayers`), its true body is `xor eax,eax; ret`, and it is
used by **61** table rows across all 31 namespaces. M5's provenance warning stands and is quantified.

---

### P9. The areas Pass 1 declared "unexamined, not endorsed"

**§2 `corpus_calls` — the numbers are right; the stated PROVENANCE is wrong.** The census key
reproduces exactly as *occurrences of `Pg.<Name>(` over `docs/mercs2-luacd/**` **plus**
`docs/mercs2-dlc-luacd/src/**`* — **80 of 80** values in
`tools/wad_simulator/crates/mercs2_script/src/bindings/pg.rs` reproduce under that key, versus
**56 of 80** under `luacd`-only. Proof by counterexample: `RemoveContextAction` is 26 in `luacd` alone
but the crate records 32; the missing 6 are all in `docs/mercs2-dlc-luacd/src/`. Same for
`UnloadingStaticLayers` (2→6), `ResetSingletonDone` (2→5), `LoadIsRetry` (6→10), `AddContextAction`
(20→27), `SpawnFromCamera` (6→13), `GetGuidByName` (1103→1240). The map's §Sources line ("370 scripts
of `docs/mercs2-luacd/`") and `pg.rs:5` are both wrong; the true scope is **370 + 39 = 409 scripts**.

Two counting hazards neither the map nor the crate flags: (a) `docs/mercs2-dlc-luacd/raw/**` is the
register-form decompile (`L0_1 = Pg; L0_1.GetGuidByName`) and contributes **zero** `Pg.` matches —
excluded by naming accident, not design; (b) `docs/mercs2-luacd/src/` contains **22 byte-identical
duplicate basenames** across `shell/` and `resident/` (verified by sha256 on `mrxguishell.lua`), so
every count touching them is doubled relative to "distinct scripts".

Notable for contract flow specifically: **DLC missions call `Pg.Contract*` zero times**, but **4 of
the 6** `Pg.UnloadingStaticLayers` calls are DLC — the DLC leans on the static-layer teardown path far
harder than the base game.

**§6.2 the context-action body — CONTRADICTED.** See P1. Argument order and the
`m2("default") = 0xBA71C11C` default reproduce; the return contract is **`true` / `nil`**, not "raises
a Lua error".

**§6.3 the `Report` ruling-out — CONFIRMED, both sides.**
*Binary:* `Report` (`0x00B98F64`) = 5 cfuncs (`Init 0x005E05D0`, `GetInfractions 0x005E0720`,
`Completed 0x005E0A10`, `Failed 0x005E0AB0`, `SetDelay 0x005E0920`). `GetInfractions` pushes exactly
seven literals — `DamagePerson 0xBB3D48`, `DestroyPerson 0xBB3D68`, `DamageObject 0xBB3D58`,
`DestroyObject 0xBB3D78`, `Hijack 0xBB3D88`, `Trespassing 0xBB9940`, `SpecialEvent 0xBB994C` — and its
singleton is `[0x01175E54]` (read at `0x005E0670`, `0x005E0793`), **not** `[0x01176170]`.
*Lua:* **8** `Report.` sites across both corpora, **all in `mrxfactionmanager.lua`**
(`:351, :360, :1162, :1188, :1206, :1224, :1262, :1337`); `docs/mercs2-dlc-luacd/` has zero.
`faction_reputation_code_map.md:66-67, :86` independently lists the identical seven-key set.

**§3.3 the event rings — CONFIRMED, and a THIRD ring found.** Three structurally identical
`EventQueue<T>` instances, all CS-guarded with the owner TID stashed and a `!= 0` disable flag:

| publisher | slots | stride | storage | count | mask array | subscriber mask | per-sub counters |
|---|--:|--:|---|---|---|---|---|
| `FUN_004BDD10` (state requests) | 20 | `0x10` | `0x0120F510` | `0x0120F4E8` | `0x0120F650` | `0x0120F4EC` | `0x0120F4F0` |
| `FUN_004BDE40` (level boot) | 256 | `0xD0` | `0x0125D3E0` | `0x0125D3B8` | `0x0126A3E0` | `0x0125D3BC` | `0x0125D3C0` |
| **`FUN_004BDDA0`** — **not in the map** | 256 | `0x120` | `0x0124AF98` | `0x0124AF10` | — | `0x0124AF14` | — |

The map's 16-B and 208-B rings are both exactly right. Two wording nits:
"`DAT_0120F510`/`DAT_0120F518` **interleaved**" describes a plain 16-byte-stride array (`0x0120F518`
is slot 0's second half); and the drain `FUN_004C9CF0` takes the subscriber index **complemented**
(`not eax; ebp = eax`), which is why the pump stores `~idx` at `[this+0x0C]` (`lea edi,[ecx+0xc]` at
`0x004C0A42`).

**§8 `Junk.IsInstallable` / `Sys.NoHud` — CONFIRMED, and the body is new information (N6).** Both are
`0x005C0340`, and that body is not a mystery — it is the *boolean* twin of `FUN_004B2A50`:

```
005C0340  mov eax,[esp+4]; mov ecx,[eax+8]
005C0347  mov dword [ecx], 0        ; value = 0
005C034D  mov dword [ecx+4], 1      ; tt = 1 = LUA_TBOOLEAN
005C0354  add dword [eax+8], 8      ; top++
005C0358  mov eax, 1                ; 1 result
```

**`Junk.IsInstallable()` and `Sys.NoHud()` return a constant `false`.** So
`mrxguishell.lua:322 if Junk.IsInstallable and Junk.IsInstallable() then` is **permanently dead code**
on PC and the install-to-HDD UI branch can never be reached. Only these two rows use `0x005C0340`
across all 1,103 cfuncs — a genuine two-name alias, not a shared stub family.

**§3.6 `Sys.SetSkipMission` — CONFIRMED.** `0x005E5557`–`0x005E556C` is a hand-rolled byte-copy loop
into `DAT_01175B38` with **no length check**, followed by `DAT_00D002B9 = (buf[0] == 0)` at
`0x005E5588`. One addition: it also **pushes `nil`** (`0x005E5577`) and returns 1 — the map says
nothing about its return.

**§9.8 `Pg.RemoveContextAction` `0x005D7820` — partially closed.** Still binding-only for its
internals, but its shape is read: 2 Lua pushes, three `ret` sites all with `eax = esi`, i.e. the same
`true`/`nil` contract as `AddContextAction`, and it does **not** raise.

**§1's arbiter — re-verified verbatim.** Registry `0x00DFD478`, 31 rows × 12 B, terminator at
`0x00DFD5EC`, **1,103 cfuncs, 61 stubs**. Row 0 = `_SYS`/`0x00B9A854`/the `_G._MODULES = {}` chunk;
**row 2 = `{"Pg", 0x00B99328, "GetGuidByName = Pg.GetGuidByName; GetAllGuidsByName = Pg.GetAllGuidsByName; Controller = { LPad_Up = 1, … }"}`**;
row 19 = `Junk`/`0x00B99E28` with a **NULL** post-register chunk. `Pg` = 80 entries / 2 stubs
(terminator `0x00B995A8`); `Junk` = 24 / 15 (terminator `0x00B99EE8`); exactly three duplicate VAs in
`Pg` (`0x006D5640`, `0x005D3F10`, `0x005D7E40`). Corroboration (b) holds: `"Pg"` at `0x00BB9030` is
immediately followed by `"layer"` at `0x00BB9034`. Pass 1's A1 claim that neither table carries
`{name, 0xFFFFFFFF}` / `{name, 0xFFFFFFFE}` sub-table markers is **confirmed** — those exist, 11 of
each, but only in `Human` and `Graphics`.

---

### P10. Sibling-map boundary claims — now tested as claims, and three are wrong

The map's boundary table (lines 15–27) was cited, never checked.

| sibling | claim | verdict |
|---|---|---|
| `scheduler_tick_code_map.md` | owns the frame chain | **CONTRADICTED on a fact.** `:41` names the app-stack "array `@0xd6c22c`, count `DAT_017bbcf4`". `0x00D6C22C` is **element 0**, not the array; the array is `0x017BBCCC` (proven by `FUN_004C1170`'s `[eax*4 + 0x17bbccc]` writes and `FUN_004C15E0`'s `mov esi,[eax*4 + 0x17bbccc]`). **The mission map is right and the sibling is wrong.** Its `FUN_004C0EC0 → FUN_004C9740` edge (`:117`) independently confirms this map. Neither it nor `input_code_map.md` mentions `FUN_004C09C0`, so §3.5 is an *answer* to their open item, not a conflict |
| `input_code_map.md` | ditto | consistent; `:93-98` draws `FUN_004C15E0 → layer 4 → FUN_004C9740`, which P5 proves correct |
| `player_code_map.md` | reads `DAT_00DFBD77` as a shutdown/teardown guard | **The disagreement no longer exists.** `player_code_map.md:483-491` explicitly **withdraws** that gloss and now cites *this* map. §5.1's note and §9.10 describe a draft that is gone — and both are superseded by P2 anyway. It also **disclaims** ownership of `[0x01176054]` (`:71-73`), pointing at `save_serialize_code_map.md`; so the mission map's boundary row is a three-way mis-attribution |
| `save_serialize_code_map.md` | owns `[0x01175F30]` | **CONTRADICTED.** That file contains **zero** mentions of `0x01175F30`; it owns `[0x1176054]`. Separately §6.4's "`+0xC3D` (the retry flag) is **new here**" is **wrong** — `save_serialize_code_map.md:142-144` already prints the **writer** (`_stricmp(param_2, "retry" @0x00BB4604); *(bool*)(param_1+0xc3d) = …`), strictly stronger than this map's reader-side read. Bonus: that writer is `FUN_005a4520`, the same body this map ascribes to `Pg.LoadGame`, so `param_1 == [0x01175F30]` is a testable bridge neither map has drawn |
| `faction_reputation_code_map.md` | owns `Report` + `Pg.*Pursuit*` | **PARTIAL.** Owns them behaviourally, but records the pursuit cfunc VAs as "**unlocated**" (`:101-102`) and never pins the `Report` table VA or `[0x01175E54]`. **This map supersedes it** and satisfies its own `:327` open item |
| `event_bus_code_map.md` | owns the general bus | **PARTIAL / no corroboration.** Zero hits for `DAT_0120F510`, `FUN_004BDD10`, `FUN_004C9CF0`, `FUN_004BDE40`. It documents an 18-bucket hash subscriber registry with `Event.Post = FUN_005F6A90`. **Whether that registry and these three rings are one bus or two is an open question neither map addresses** |
| `scripting_host_binding_code_map.md` | labels `0x00B99328` "World"; owns the `0x006D5640` stub | **CONFIRMED** (`:212`, `:338-341`). **Bonus defect:** the same row `:212` also lists `CreateRegion 0x5BFB00` as a `Pg` member — it is slot 1 of the **`Junk`** table. A second, independent error in the row §1 corrects |
| `world_streaming_code_map.md` | link target | CONFIRMED — the file exists; only the display text (`world_streaming_pc_code_map`) is off |
| `docs/mercs2-luacd/02_…`, `03_…` | own the Lua framework | **CONFIRMED with a gap.** 52 `*con###.lua`, 114 files in `src/vz/`, no `mrxcontract*`/`mrxmission*` beyond the two named, and the three `wif*data` files all check out. But "~30 `MrxTask*` modules" is **23**, and §7 ignores the DLC contract corpus entirely (9 more `dlccon*` scripts plus a **second** mission-flow module, `dlc01missionflow.lua`) — while §2's traffic numbers **do** include it. §2 and §7 are computed over different corpora |
| `engine_support_inventory.md` §K1 | four ⛔ rows | **CONFIRMED** — all four quotes verbatim at `:347`, `:350`, `:371`, `:372`; gate K1 verbatim at `:310`; the 🟡 `Pg` row at `:156`. (K1 tags 6 rows in total, 4 of them mission-related.) `pg_world.rs` is **still unfixed**: `NAMESPACE = "PgWorld"` (`:23`), `GLOBAL = "Pg"` (`:25`), all 24 `corpus_calls: 0`, and `rg 'Junk'` over the crate returns **zero** hits — so today those 24 cfuncs install as `Pg.*` and `Junk` is left nil, exactly the fault §1 predicts. Note §10.7's "re-census with 12" is itself inconsistent with the crate's call-form key, which gives **9** |

---

### P11. New defects found in Pass 2

**N1 — `Pg.ContractCompleted` / `Pg.ContractCancelled` declare one return value and never push it.**

```
005D7E40  mov eax,[0x1176170]; test eax,eax; je 0x5d7e5f
005D7E49  strncpy(eax + 0xF149, "" @0x00BA8B09, 0x3F)
005D7E5F  mov eax, 1        ; <- nresults = 1
005D7E64  ret               ; <- nothing was ever pushed onto the Lua stack
```

A scan of every `Pg` cfunc in this map's slice for Lua-push idioms confirms `0x005D7E40` performs
**zero** pushes on any path. The map reads `mov eax, 1` as "`; return true`" in **both** §4.1 and
§4.2 — a misread. `eax` is the C-function **result count**; the boolean-`true` idiom elsewhere in this
same binary is explicitly `mov [top],1; mov [top+4],1; add [L+8],8` *then* `mov eax,1` (see
`Sys.RequestGameState 0x005E4C24`, `Pg.AddContextAction 0x005D77FD`). Returning 1 without pushing
makes Lua lift whatever sits at `L->top - 1`.

The same defect is on `Pg.ContractActivated`'s **success** path (`0x005D7E2D`: `mov eax, edi` with
edi = 1, no push — the one push in that function is on the *failure* path) and on
`Pg.ResetSingletonDone` `0x005D4BE0` (`mov eax,1; mov [0x1175a7d],al; mov [0x1175a7e],al; ret`, zero
pushes — the map says "no args, no return"). Retail never bit because every corpus call site discards
the result (`mrxtaskcontract.lua:99, :120, :275`). **But §10.4 tells reimplementers to model these as
returning `true`, which diverges from retail.** For contrast, `Sys.ForceNextAutosave` `0x005E6670`
correctly does `xor eax,eax; ret` — 0 results.

**N2 — a reachable NULL-deref in `Pg.UnloadLayer` on a co-op client.** See P2.

**N3 — the record-array base is `+0x1C8`, not `+0x208`.** See P4.

**N4 — `FUN_004C13A0` is the shutdown pump, not a per-frame entry.** See P5.

**N5 — two runtime-populated tables are described as statically initialised** (`0x017BBCCC[]`,
`0x01175C80[]`). See P5 and P7. This matters beyond pedantry: anyone re-deriving from a clean
`Mercenaries2.exe` rather than the memory dump will find both empty and conclude the maps are wrong.

**N6 — `Junk.IsInstallable` / `Sys.NoHud` return constant `false`.** See P9.

---

### P12. STILL OPEN — with proof of static exhaustion and a runtime recipe

Four items, honestly stated. A false zero is worse than an honest four.

**S1 — state slot 7, `0x53056C27`.** *Exhaustion:* its `Update` `0x004BA7D0` is now read in full:

```c
[this+8]  += 1;                          // frame counter
[this+0xC] += [0x00D26394];              // accumulated frame dt
if ([this+8]  >  0xA)          publish { m2("ingame"), _, 0, 0 };   // 0x004BA7FC
if ([this+0xC] > [0x00D28B90]) publish { m2("ingame"), _, 0, 0 };   // 0x004BA823
```

— a **short transitional wait bounded by BOTH 10 frames and a float timeout, ending in `ingame`**
(the two arms are not exclusive; on the frame where both cross it publishes twice, which the pump
absorbs via its `cur[1] != msg.hash` check). Its vtable `0x00BB0144` has `+04` enter `0x004BA660`,
`+08` exit `0x004BA710`, `+0C` init-with-args `0x009AB820`, `+10` update `0x004BA7D0`, and sits
between `waitforstreaming` and `waitfortether` in `.rdata` order. Cracking attempted over every ASCII string in both images, every identifier and
quoted literal in `docs/mercs2-luacd/` + `docs/mercs2-dlc-luacd/`, the `docs/data/` hash harvests, the
Xbox PDB material in `docs/mercs2-pdb-analysis/`, and generated 2- and 3-word compounds from a ~60-word
state vocabulary with `_`, `-` and bare separators — **4,102,110 distinct generated candidates in the
focused sweep alone**, on top of the string- and corpus-derived sets. **No hit.** `"waitforgame"` is
explicitly excluded despite the `STATE_WAITFORGAME` constant in the Lua corpus. Note the hash is
case-folding (`c | 0x20`), so case variants are already covered and cannot be the gap; the name is
therefore either a non-English/abbreviated token or contains a character class outside the vocabulary
tried. *Recipe:* HW-write watchpoint (4 bytes) on
`DAT_01175C7C`, boot to a level, read `[cur+4]` at each stop — the state is entered immediately before
`ingame`, so it is the last hit before `0x57B5E35A`. Alternative: one-shot bp on its enter slot
`[0x00BB0144 + 4]` and read the caller's literals.

**S2 — the exact LABEL STRING for `[0x01176170]` (role is closed; see P4).** *Exhaustion:* the role is
established on five converging lines and the field map is nailed, so what remains is only the literal
symbol. Master key negative; RTTI absent on both platforms (`mercs2_xenon_p.rtti_classes.txt` is 324
entries, **all Havok** — there is no Pangea RTTI on Xbox either); `func_class_map.csv` has no entry;
`tools/rainbow_table.json` (733k hashes) has no match for `0x6AD9B549`, nor did a 1,726,099-candidate
crack over both exes' full string sets plus `docs/data`, `docs/mercs2-luacd`, `docs/mercs2-pdb-analysis`
and `docs/mercs2-ecs` under both `pandemic_hash_m2` and the no-finalisation variant — **and that hash
turns out to be irrelevant anyway** (P4: it is a folded `[tag:value]` debug line, not a class name).
The PC release build strips all `PgSys*` labels; the Xbox string table has `PgSysNetOnline` but no
binding from label to vtable. *Recipe:* break `0x006C8CD0` (`Init`) and read the slot index returned
by `FUN_0060CF90` into `[this+0x14C]`, then match it against the PgSys registry's label array; or
HW-write-watch `+0x1C8` during a lobby refresh and confirm the three `0x40`-B names are
session / map / contract.

**S3 — the SecuROM split-thunk bodies** (`FUN_0045E440`, `FUN_0045E3F0`, `FUN_006B3560`,
`0x0059F990`, `0x005A0330`, `FUN_004C0FF0`'s entry, `FUN_006CFF90`). *Exhaustion — deref shown, as
required:*

```
FUN_0045E440 = push esi; mov esi,eax; jmp dword ptr [0x02455100]
               [0x02455100] = 0x024B98E0  ->  push 0x024B98EA; call 0x01AAFF10
FUN_006B3560 = push ebx;              jmp dword ptr [0x0244F500]
               [0x0244F500] = 0x024B5600  ->  push 0x024B560A; call 0x01AAFF10
FUN_006CFF90 =                        jmp dword ptr [0x0245976C]
               [0x0245976C] = 0x024ECBD0  ->  push/push/push; pushfd; sub [esp+4],imm; popfd; ret
FUN_004C0FF0 = xor eax,eax;           jmp dword ptr [0x02455B44]   (body resumes at 0x004C0FF8)
```

**The slots ARE resolved in the dump and the deref works — but the destination is the SecuROM VM
entry, not clean x86.** These bodies were *virtualised*, not merely relocated: `0x01AAFF10` is the
interpreter and the bytes after the `push` are its bytecode. The 42,601-function export agrees —
`FUN_0045e440 @0x0045e440 size=19` and `FUN_006b3560 @0x006b3560 size=7` are the thunks themselves,
with no recovered body. *Recipe:* lift with the existing VM disassembly, or trace-and-dump: one-shot
bp on `0x0045E440`, hardware bp on the return, and record the observed effect on `eax` for a known
`(typeHash, nameHash)` pair. What the **call sites** prove is already in the map and is confirmed here
(`FUN_006B3560(&DAT_01175AB8, &DAT_01175B78, 2, 1)` at `0x005E4CFD` from `Sys.StartSingleplayer`, and
`2,1` / `2,0` from the shutdown path `FUN_00615A10`; `FUN_0045E440`'s three callers are exactly
`Pg.LoadLayer 0x005D4E13`, `Pg.UnloadLayer 0x005D4F00`, `Pg.ReloadLayer 0x005D5043`, each preceded by
`mov [esp+0x1c], 0xE6B81A54`).

**S4 — whether a bulk `memcpy` sweeps `+0xF149` into a savegame or minidump.** *Exhaustion:* the
displacement scan is now a full recursive-descent scan and still returns exactly three sites, all
writes; and the sibling field `+0xF0E5` **is** read by direct displacement at five sites, so the
engine's idiom for consuming fields of this shape is the direct form. A structure-wide `memcpy`
remains unprovable by any static scan. *Recipe:* HW-read watchpoint (4 bytes) on
`[0x01176170]+0xF149`, then activate and complete a contract and save. If it never trips, §9.9 closes.

---

### Pass 2 ledger

| | count |
|---|--:|
| Pass-1 items **CLOSED** this pass | **18** — C1, C2, O1, O2, O3, U1, U2, **U3 (role)**, M1, M2, M3, M4, M5, §2, §6.2, §6.3, §3.3, §8 |
| Map §9 / §A9 items closed | **7** — §9.1 (3 of the 4 hashes), §9.2, §9.3 (role), §9.6, §9.7, §9.10, plus `[0x01175A94]` / `[0x01175F58]` decoded |
| **STILL OPEN** with demonstrated exhaustion + recipe | **4** — S1 (slot-7 hash), S2 (the *label string* only), S3 (VM-virtualised thunk bodies), S4 (bulk-copy question) |
| New defects found in Pass 2 | **6** — N1…N6 |
| Sibling-map claims tested | **10**, of which **3 are wrong** (`scheduler_tick` array base; `save_serialize` `[0x01175F30]` + `+0xC3D`; `player_code_map` profile-singleton attribution) and **1 carries a bonus defect** (`scripting_host_binding` `CreateRegion`) |

**Answers to the four questions posed.**

1. **`DAT_00DFBD77` verdict:** **`Net.IsClient`** (`sessionMode == 1`). Its sibling `DAT_00DFBD78` is
   **`Net.IsServer` / host** (`sessionMode == 2`). Both are read-only one-hot decodes republished every
   tick by `FUN_006CECF0`; neither is ever written through its own address anywhere in any section of
   any image. Settled **statically**, on two independent can't-coincide lines: the engine's own
   `Net.IsClient` / `Net.IsServer` binding bodies, and the Flash variable names
   **`multiplayerClient`** / **`multiplayerHost`** those bytes drive at `0x005C3ADD` / `0x005C3A98`.
   All three prior readings were wrong; `Net.IsEnabled` (`0x00DFBD74`) carries the "a session exists"
   meaning the map assigned to `78`.
2. **`[0x01176170]`'s identity:** **CLOSED on role — it is the online / multiplayer-services Pangea
   game system (Xbox label `PgSysNetOnline`)**, not a layer manager and not an ECS container (master
   key applied, hard negative: `[vtable+0x34] = 0x00848E30 = ret 4`, no name-getter in 74 slots, no
   RTTI on either platform). It has **four** vtables, size `0xF190`, and its fields are now named:
   `+0x158` session-valid, `+0x1C8` the `0x100`-entry server-browser list (**not `+0x208`**), `+0xF0E5`
   the co-op partner name `player2Name`, `+0xF149` `sContract`. Only the literal label *string* is
   unclosed (S2) — the PC build strips `PgSys*` labels. This also **strengthens** §4.3: `sContract`
   sits in the online-services struct next to a server-browser record type that itself carries an
   `sContract` field, so the write-only breadcrumb reads as **a lobby advertisement never wired up on
   PC** — consistent with `ContractCompleted == ContractCancelled` and with there being no reader.
3. **Does state-gating survive?** **Partially — and not in the form the map states.** The *linkage*
   survives a stronger test than either pass applied: `FUN_004C9740` and `FUN_004C0EC0` each have one
   direct caller and **zero** literal-address occurrences in any section, so no indirect caller can
   exist, and the pump sits between the app-stack stepper and the tick. But `FUN_004C09C0`'s dispatch
   shows the per-system pump is called at `0x004C0B6A` on a path that a **NULL current state does not
   block** (`0x004C0B14`'s `je 0x4c0b5b` skips only the state's own `Update`). The real gates are the
   app-stack layer's phase (`== 2`), the foreground/`Sleep(100)` predicate, and `[0x01175A94] != 1`
   (a level-transition handshake, not a pause flag). **"Which game state am I in" does not gate the
   simulation** — §0's headline and §10.9's advice both need narrowing.
4. **Items closed vs still open:** **18 closed, 4 still open** (S1 the slot-7 hash, S2 the label
   string only, S3 the VM-virtualised thunk bodies, S4 the bulk-copy question), each of the four with
   demonstrated static exhaustion and a runtime recipe.

**Net effect on the target map.** Substance holds: `Pg`/`Junk` with no `World` namespace; the
write-only contract breadcrumb with no reader; the 23-slot / 20-filled state machine; and the
frame-chain linkage all survive re-derivation, the last two under stronger tests than either pass
applied. The defects are concentrated in three places — **the return contracts** (§0.5, §5.2, §6.2,
§10.4, §10.6 all describe `nil`/no-push as `luaL_error`/`true`), **the state-gating headline** (§0,
§3.2, §10.9 overstate what the pump gates), and **provenance** (§3.1 and Pass 1's M1 call
runtime-populated tables static; §Sources understates the census scope; three boundary rows
mis-attribute to siblings).
