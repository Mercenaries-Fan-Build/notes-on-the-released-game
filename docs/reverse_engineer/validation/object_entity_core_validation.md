---
title: Double-blind validation — object_entity_core_code_map.md
subject: Object Lua namespace (luaL_Reg @ 0x00B99608) + entity/component model
method: Phase A blind derivation from raw binary, then Phase B comparison
evidence: proven
status: current
date: 2026-07-26
primary_source: output/_ghidra/securom_dump/mercs2_unpacked.exe (raw disassembly, capstone, VA→file via PE section table)
---

# Double-blind validation: `object_entity_core_code_map.md`

Phase A was written from raw disassembly of the unpacked exe **before** the target map was
opened. Ghidra decomp was used only to measure *its own* coverage, never as a fact source.

Reproduction harness: `capstone` + `pefile`, VA→file offset via the PE section table
(`.text` VA 0x00401000–0x00B05000 → raw 0x1000; `.rdata` VA 0x00B05000 → raw 0x705000;
`.data` VA 0x00BF6000 → raw 0x7F6000). `RVA == raw` does **not** hold for this image.

---

## Phase A — independent findings (written before reading the map)

### A1. The table is real, it is `Object`, and it has exactly 87 entries

Walking `luaL_Reg` pairs from `0x00B99608` yields 87 `{name, fn}` rows terminated by a
`{NULL,NULL}` at `0x00B998C0`. There are **no** `0xFFFFFFFF` / `0xFFFFFFFE` sub-table marker
rows — the Object table is flat.

Namespace ownership confirmed from the registry at `0x00DFD478`. The record stride is **0x0C**,
not 0x08; each record is `{const char *name, luaL_Reg *table, const char *extraLuaChunk}`.
The record at `0x00DFD49C` is:

```
0x00DFD49C : name  -> 0x00BB8724 = "Object"
0x00DFD4A0 : table -> 0x00B99608          <-- the subject table
0x00DFD4A4 : extra -> NULL
```

Neighbours decode sensibly (`_SYS`, `Sys`, `Object`, `Player`, `Event`, `Ai`, `Human`, `Debug`,
`Vehicle`, `Airstrike`, `Gui`, `_GuiInternal`, `Graphics`, `Sound`, `ObjectFilter`, `Net`,
`Camera`, `math`, `Junk`, …), which cross-validates the 0x0C stride.

### A2. How many of the 87 bodies can actually be read: **87 of 87**

Every one of the 87 function pointers lands in `.text` and every one disassembles to a real,
terminated body (each ends in `ret` followed by `int3` padding). Sizes range from **16 bytes**
(`EnablePhysics`, `DisablePhysics` — 5-instruction thunks) to **1136 bytes** (`GetPhysicsType`,
407 instructions).

Separately, I measured what **Ghidra** recovered from `output/_ghidra/mercs2_unpacked.exe_decomp.txt`
by searching for a *definition* line (not merely a call site) of `FUN_<va>`:

- Ghidra has a decompiled body for **63**.
- Ghidra has **no** body for **24**.

The 24 Ghidra-missing ones are:
`DetachCargoFromWinch, DisablePhysics, EnablePhysics, GetCashValue, GetHealth, GetMass,
GetMaxHealth, GetModelName, GetName, GetPhysicsType, HasLabel, HasWinch, InSeat, InVehicle,
IsAlive, IsDisguised, IsHibernated, IsTemplate, IsValid, IsWinching, RemoveQualityRef,
RevertHibernationDistance, Revive, StopAllAnimation`.

**All 24 disassemble cleanly.** I read `GetHealth`, `GetMaxHealth`, `IsTemplate`, `IsHibernated`,
`RevertHibernationDistance`, `EnablePhysics`, `DisablePhysics`, `IsValid` and `IsAlive` in full
during this pass. "Binding-only" here means *Ghidra found no static caller*, not *the body is
unavailable*. Recovery ceiling is 87/87, not 63/87.

### A3. Storage model: per-component containers keyed by GUID — and there are **TWO** arrays

There is no entity object that `Object.*` indexes into. Every cfunc that needs state resolves a
**GUID** against a **per-component-type container**, and each container is a C++ object whose
`+0x00` is a vtable and whose `+0x04` is `{u16 0xFFFF, u16 componentTypeId}`.

Scanning `.data` for that header signature finds **two distinct, regular arrays**:

| | Array **B** | Array **A** |
|---|---|---|
| base | `0x00DF6B88` | `0x017BBF58` |
| last element | `0x00DF9E10` | `0x017C0788` |
| count | **102** | **232** |
| stride | **0x80**, with exactly **one 0x88 step** (`0x00DF8408 → 0x00DF8490`) | uniform **0x50**, no irregular step |
| type ids | `0x001 … 0x14C`, strictly ascending, 102 unique | `0x005 … 0x14E`, strictly ascending, 232 unique |
| vtables | `0x00BC0008 … 0x00BC4698` | `0x00BB…–0x00BC…`, distinct set |
| resolve | `FUN_00649C60` / inline, built on probe `FUN_00648D80` | `FUN_005857E0` (fast) / `FUN_00649C00` (slow), probe `FUN_0064A090` |

Array B's geometry checks out exactly: span `0x00DF9E10 − 0x00DF6B88 = 0x3288`, and
`101 steps × 0x80 + 8 = 0x3288`. Walking arithmetically (0x80 everywhere, 0x88 at `0x00DF8408`)
lands precisely on `0x00DF9E10` after **102** slots, with **0 invalid headers**.

Which array each Object cfunc uses (by direct global reference in its body):

- **Array A (`0x017Bxxxx`) — 32 cfuncs**: all health (`GetHealth`, `SetHealth`, `GetMaxHealth`,
  `GetNodeHealth`), all velocity, all winch, all animation, `IsAlive`, `IsVisible`,
  `GetPhysicsType`, `GetInvincible`, all hibernation, `SetYaw`, `FadeOut`, `GetCashValue`,
  `GetLocalizedName`, `Revive`.
- **Array B (`0x00DFxxxx`) — 23 cfuncs**: `AddLabel`/`RemoveLabel`/`HasLabel`,
  `AddToDisposer`/`RemoveFromDisposer`, `SetInfiniteAmmo`, `GetName`/`SetName`,
  `GetModelName`/`SetModelName`, `Attach`/`Detach`/`IsAttached`/`GetAttachedObjects`,
  `InSeat`/`InVehicle`/`IsPlayerControlled`, `IsDisguised`, `OpenGate`/`CloseGate`,
  `AddQualityRef`, `SetPositionToObject`, `SetTransformToObject`.
- **Neither, directly — 32 cfuncs**: they take a GUID and call a worker (e.g. `SetPosition`,
  `Kill`, `Remove`, `SetVisible`, `GetMass`, all `Apply*Impulse`, all `GetHardpoint*`), or touch
  no engine state at all (`AreEqual`, `IsTemplate`, `IsValid`).

So the "flat array of 102" is a true and precisely-measured description of **one** of the two
arrays — and it is *not* the one the health functions use.

### A4. The resolve idiom

**Probe `FUN_00648D80`** is an open-addressed, linearly-probed hash table (`this` in `ESI`,
key on the stack, `ret 4`):

```
if ([esi] == 0)                      return -1          ; table empty
if (key_hint < 0) bucket = ([esi+0x0C] * guid) % [esi+0x08]
slotTab = [esi+0x14]; slot = slotTab[bucket]
while (slot != -1) {
    if ([esi+0x10][slot] == guid)    return bucket      ; <-- returns the BUCKET index
    bucket++; bucket &= ((bucket - [esi+0x08]) >> 31)   ; branchless wrap
    slot = slotTab[bucket]
}
return -1
```

**Address math `FUN_00649C60`** (this is the one `Object.SetVisible` uses; container is
`0x00DF9C90`, i.e. Array B id `0x13C`):

```
idx = FUN_00648D80(guid)
if (idx < 0) return 0
key   = [0x00DF9CD8][idx]          ; container + 0x48   <-- PACKED KEY ARRAY
cap   = [0x00DF9CB0]               ; container + 0x20
shift =  [0x00DF9CB6]              ; container + 0x26
strd  = (s16)[0x00DF9CB4]          ; container + 0x24
rec   = ((cap-1) & key) * strd + [0x00DF9D00][key >> shift]   ; container + 0x70 = page table
if (rec == 0) return 0
return [rec + 0x34]                ; <-- NOTE: dereferences an embedded pointer
```

So the shape `guid → FUN_00648D80 probe → packed key at +0x48 → (mask & key)*stride +
pageTable[key>>shift]` is **exactly right**, including the `+0x48`.

Two refinements worth recording:

1. `FUN_00649C60` does **not** return the record — it returns `[record + 0x34]`, a pointer to a
   further object. `SetVisible`'s `word [eax+0x10]` is a field of *that* object.
2. The **miss** behaviour is path-dependent:
   - `FUN_00649C60` (Array B, SetVisible path): miss → **NULL**.
   - `FUN_005857E0` fast path (Array A): miss → **NULL**, guarded additionally by
     `cmp [slotTab + idx*4], -1`.
   - `FUN_005857E0` slow path → `FUN_00649C00`: miss → `ebx = 0`, then
     `if (FUN_006654B0(guid)) return FUN_0064A5C0()`. A **fallback record is returned on miss
     when the guid is otherwise valid**. `FUN_0064A5C0` is a SecuROM split-thunk
     (`jmp dword ptr [0x02458A98]` → `0x024EFA10`, inside `.securom`) and is *not* statically
     resolvable in this dump, nor present in the Ghidra decomp. The mechanism is proven; the
     returned record's identity is not.

Array A's container field offsets differ from Array B's: `FUN_005857E0` takes `edi = this+0x18`
and then uses `[edi+0x0C]` stride, `[edi+0x0E]` shift, `[edi+0x10]` capacity, `[edi+0x1C]` slot
table, `[edi+0x20]` page table — i.e. the hash-map is a **sub-object at `this+0x18`**, whereas
Array B containers carry those fields inline at `+0x20/+0x24/+0x26/+0x48/+0x70`.

### A5. Health component memory layout — SETTLED FROM BYTES

Container for all of these is **`0x017BEF78`** (Array A). Raw disassembly:

`Object.GetMaxHealth` @ `0x005CC030`:
```
005CC09E  mov ecx, 0x17bef78
005CC0A3  call 0x5857e0          ; rec = resolve(guid)
005CC0AC  movss xmm0, dword ptr [eax]        ; <-- reads +0x00
```

`Object.GetHealth` @ `0x005CBDB0`:
```
005CBE1F  mov ecx, 0x17bef78
005CBE24  call 0x5857e0
005CBE2D  movss xmm0, dword ptr [eax + 4]    ; <-- reads +0x04
```

`Object.SetHealth` @ `0x005CBEE0` — the decisive clamp:
```
005CBF8F  mov ecx, 0x17bef78
005CBF94  call 0x5857e0
005CBF99  mov esi, eax
005CBF9F  movss xmm0, dword ptr [esi]        ; A = +0x00
005CBFA3  movss xmm1, dword ptr [esi + 4]    ; B = +0x04
005CBFA8  ucomiss xmm0, xmm1                 ; "is A == B" (at-full-health test)
005CBFAB  movss xmm0, [esp + 0xc]            ; newValue
005CBFB1  lahf / test ah,0x44 / jp  ...      ; skip notify unless A == B
005CBFB7  comiss xmm1, xmm0 / jbe ...        ; and unless B > newValue (taking damage)
005CBFBE  call 0x665be0                      ; first-damage notify
005CBFC9  xorps xmm2, xmm2
005CBFCC  comiss xmm2, xmm0 / jbe            ; clamp low:  newValue < 0   -> 0
005CBFCF  movss xmm1, dword ptr [esi]        ; reload A = +0x00
005CBFDA  comiss xmm0, xmm1 / jbe            ; clamp high: newValue > A   -> A
005CBFE9  movss dword ptr [esi + 4], xmm0    ; <-- STORES to +0x04
```

`+0x00` is the value the write is clamped **against** and is never written. `+0x04` is the value
that is written, and the value `GetHealth` returns.

> **VERDICT: the health record is `{ +0x00: f32 max, +0x04: f32 current }`.**
> The field order is **`{max, current}`**. `docs/modernization/object_assembly_model.md`'s
> `RuntimeHealth {cur, max}` has the two fields **swapped** and needs fixing.

This is settled by three mutually-corroborating readings (Get reads +4, GetMax reads +0, Set
clamps to +0 and writes +4), not by inference from one of them.

`Object.GetNodeHealth` @ `0x005CC120` uses a **different** container, `0x017BEFC8`, and:
```
005CC1D8  mov ecx, 0x17befc8
005CC1E3  call 0x5857e0
005CC1EC  mov edi, dword ptr [eax]       ; embedded pointer
005CC1F6  call 0x435140                  ; lookup node by name arg
005CC1FF  movzx eax, word ptr [eax + 6]  ; <-- u16 at +0x06
005CC203  cvtsi2ss xmm0, eax             ; integer -> float
```
**Node health is a `u16` at `+0x06`**, widened to float via `cvtsi2ss` (an integer conversion —
this cannot be a float reinterpretation). Defaults to `0.0` if any step fails. Any doc calling
this a float field is wrong about the storage.

### A6. `Object.Kill` — bounded, silently lossy

`Kill` @ `0x005CDEC0` builds a 16-byte record on the stack (`guid, 0, 0, 0, 0`), points `esi` at
it, calls `FUN_0042BE60`, then `xor eax,eax; ret` → **returns 0 Lua values**.

`FUN_0042BE60`:
```
0042BE60  cmp byte ptr [0x11BA1A8], 0 / jne ret     ; global disable flag
0042BE83  call [0xB05128]                           ; EnterCriticalSection(0x11BA1B0)
0042BE89  mov eax, [0x11B5120]                      ; count
0042BE8E  cmp eax, 0x400
0042BE93  jge 0x42BEE4                              ; <-- FULL: jump straight to Leave
0042BE95  movq/movq  -> [0x11B51A8 + count*0x10]    ; 16-byte element
0042BEB4  [0x11B91A8 + count*4] = [0x11B5124]       ; parallel array
0042BEC6  [0x11B5120] += 1
0042BEE4  push 0x11BA1B0 / call [0xB0512C]          ; LeaveCriticalSection
0042BEEF  ret
```

Bound of **0x400** entries: confirmed. Element size 0x10: confirmed. On overflow it takes no
action whatsoever — no error, no flag, no return value — so the kill is **silently dropped**:
confirmed.

One terminology correction: this is **not a ring**. There is no modulo and no wrap; the index
only ever increments and the full buffer **drops the newest** entry. A ring buffer would
overwrite the oldest. (A near-identical sibling queue at `0x0042BEF0` uses a bound of `0x80`.)

### A7. `AddToDisposer` and the "disposable" hash

Recomputed independently with `tools/pandemic_hash.py`:
```
pandemic_hash_m2("disposable") = 0xF956736B      <-- matches
pandemic_hash   ("disposable") = 0x6A344DE3      (the other, non-M2 variant)
```

`AddToDisposer` @ `0x005D2900` contains the literal:
```
005D29B9  push 0xf956736b
005D29C1  push 0xdf8108              ; the label container (Array B)
005D29CE  call 0x649180              ; container insert
005D29D3  mov ecx, [esp+0x10]        ; guid
005D29D7  mov eax, [0xed3b0c]
005D29DD  call 0x4f3d30              ; <-- EXTRA call AddLabel does not make
005D29E2  xor eax, eax / ret         ; returns 0 Lua values
```

`AddLabel` @ `0x005CE900` uses the **same** container `0x00DF8108` and the **same** helper
`FUN_00649180` with the same 5-argument shape `(container, guid, 0, labelHash, &out)`, but:

- `AddLabel` is **variadic** — it loops over the argument list adding one label per argument
  (loop at `0x005CEAC4`–`0x005CEB04`, re-entering `0x0059FF50` per arg).
- `AddLabel` **returns a boolean** (`mov [eax],1; mov [eax+4],1` = a Lua boolean push).
  `AddToDisposer` returns **nothing**.
- `AddToDisposer` makes the extra `FUN_004F3D30` call against the global at `0x00ED3B0C`.

So: *"`AddToDisposer` applies the label `disposable`, hash `0xF956736B`"* is exactly right.
*"`AddToDisposer` **is exactly** `AddLabel(guid, "disposable")`"* is not — the return arity
differs and there is an extra engine call.

### A8. `SetVisible` is inverted; `IsVisible` is not its inverse

`SetVisible` @ `0x005D03B0`:
```
005D0448  call 0x649c60                      ; resolve -> [rec+0x34]
005D0478  cmp byte ptr [esp + 0x1c], 0       ; the Lua bool argument
005D047D  je  0x5d0487
005D047F  and word ptr [eax + 0x10], 0xfffe  ; visible = TRUE  -> CLEAR bit 0
005D0485  jmp 0x5d048b
005D0487  or  word ptr [eax + 0x10], bx      ; visible = FALSE -> SET   bit 0   (bx == 1)
```
**Inverted: the set bit means hidden.** Field is bit 0 of a **u16 at `+0x10`**.

`IsVisible` @ `0x005D04C0` does **not** read that bit:
```
005D0574  call 0x665af0                      ; fetch world position; false -> return true
005D05B1  mov dx, word ptr [ecx + 0x18]      ; a DIFFERENT field, +0x18
005D05B5  and dx, 0x3000
005D05BA  cmp dx, 0x2000
005D05BF  jne -> return TRUE                 ; not in the tested class -> unconditionally visible
005D05DA  call 0x70f640 / call 0x665bb0      ; camera + world query
005D0616  call 0x424770
005D061B  comiss xmm0, dword ptr [0xbeb528]  ; compare against a threshold constant
005D0622  jb  -> return FALSE / else TRUE
```
A camera-relative spatial query against a threshold, on a different struct field
(`+0x18`, 2-bit mask `0x3000`) from the one `SetVisible` writes (`+0x10`, bit 0).
**They are not inverses of each other**: confirmed.

### A9. `SetPosition` commits, then fires two vtable hooks behind a gate

`SetPosition` @ `0x005CCF10` only marshals arguments and tail-calls worker `FUN_005CCE00`:
```
005CCFD7  call 0x5cce00                      ; (L, guid, &vec)
```

`FUN_005CCE00`:
```
005CCE16  call 0x665af0                      ; validate/fetch; false -> push nil, return
005CCE83  call 0x6658b0                      ; <-- THE COMMIT (writes the position)
005CCE8D  mov ecx, 0x17bf888                 ; Array A container
005CCE92  call 0x5857e0                      ; rec = resolve(guid)
005CCE97  test eax, eax / je  skip
005CCE9B  mov esi, dword ptr [eax]           ; embedded world object pointer
005CCE9D  test esi, esi / je  skip
005CCEA1  mov edx, [esi]                     ; vtable
005CCEA3  mov eax, [edx + 0xE0]
005CCEAB  call eax                           ; <-- VIRTUAL CALL at vtable +0xE0
005CCEAD  cmp eax, 1
005CCEB0  jne skip                           ; <-- GATE: only if it RETURNS 1
005CCEB4  mov edx, [[esi] + 0x84]; push -1; push &vec; call edx    ; hook 1
005CCEC5  mov edx, [[esi] + 0x88]; push ebx;           call edx    ; hook 2
```
Confirmed: not a field write; a commit call followed by **two vtable hooks at `+0x84` and
`+0x88`**, gated on `+0xE0`. **Refinement:** `+0xE0` is a **virtual method whose return value is
compared to 1** — it is not a memory field compared against 1. Describing it as `+0xE0 == 1`
is only correct if `+0xE0` is understood as a vtable slot.

### A10. `AreEqual` touches no engine state

`AreEqual` @ `0x005CE320`, 432 bytes / 148 instructions. Its **complete** call set is:
```
0x0059FF50   (Lua argument fetch)
0x0085D5D0   (Lua stack space check / push)
```
No engine calls, no container references, no global `.data` touches outside the Lua state. It
reads Lua type tags directly (`cmp [eax+4], 7` / `cmp [eax+4], 2`) and falls back to a shared
constant TValue at `0x00B9228C` for out-of-range stack indices. **Confirmed: pure.** Its size is
explained by an inlined variadic loop, not by engine work.

### A11. `Object.Remove` branches on GUID type tags

`Remove` @ `0x005CDC00`:
```
005CDC92  test edi, edi
005CDC94  jl  0x5CDCED                    ; <-- bit 31 set  -> template path
005CDC96  je  0x5CDCAB                    ; guid == 0
005CDC98  test edi, 0xc0000000            ; <-- 0xC0000000 mask
005CDC9E  jne 0x5CDCAB
005CDCA0  call 0x6b2ec0 ...
005CDCAB  cmp byte ptr [0xdfbd77], 0 / je ...
005CDCB4  mov edx, edi
005CDCB6  and edx, 0xf0000000
005CDCBC  cmp edx, 0x40000000             ; <-- 0x40000000 top-nibble tag
005CDCC2  jne ...
005CDCCA  call 0x6b2e80 / cmp eax, -1 ...
```
All three claimed discriminants confirmed: sign bit (31), the `0xC0000000` two-bit mask, and the
`0xF0000000 → 0x40000000` top-nibble tag.

**Bit 31 = template** is independently corroborated by `Object.IsTemplate` @ `0x005CBD20`, whose
entire payload is:
```
005CBD8F  xor ecx, ecx
005CBD91  cmp dword ptr [esp + 8], ecx
005CBD98  setl cl                         ; result = (guid < 0)
005CBD9B  mov dword ptr [eax], ecx        ; push as Lua boolean
```
`IsTemplate(guid)` is literally `guid < 0`, i.e. bit 31.

### A12. The hibernation pair have real bodies

- `IsHibernated` @ `0x005CF240` — **192 bytes, 70 instructions**. Calls `0x0059FF50` (args),
  `0x005857E0` (resolve, container `0x017C02D8`), `0x004B86E0` (push bool), `0x0085D5D0`.
- `RevertHibernationDistance` @ `0x005CF600` — **400 bytes, 80 instructions**. Calls
  `0x0050CCB0`, `0x005174E0`, `0x0059FF50`, `0x0085D5D0`; references container `0x017BD178`
  (shared with `Get`/`SetHibernationDistance`).

Both are in Ghidra's missing-24 and both are fully readable. Neither is "VA-known only".

### A13. Container `0x00DF9B10` — the infinite-ammo marker set

`0x00DF9B10` is Array B slot with component type id **`0x137` (311)**, vtable `0x00BC3F48`.

It has **20** code references in `.text`, not two:
`0x4C5382, 0x4C538D, 0x51A2D1, 0x51AF0B, 0x51DD4B, 0x51E237, 0x51F580, 0x51F60D, 0x52D8D5,
0x585878, 0x5CE89E, 0x5CE8B8, 0x5CE8C1, 0x66B768, 0x6A4083, 0x6A408B, 0x6A416E, 0xA7C7A1,
0xA7C7B8, 0xB03211`.

`Object.SetInfiniteAmmo` @ `0x005CE7E0`:
```
005CE87C  call 0x6cdaf0 (0)          ; get player
005CE888  mov eax, [eax + 0x20]      ; player's controlled guid
005CE88B  cmp esi, eax / je force-insert    ; target IS the player -> always insert
005CE88F  test bl, bl / je remove
   insert: push &local; push 0; push 0; push guid; push 0xdf9b10
           mov byte ptr [esp+0x30], 1       ; <-- element payload byte = 1
           call 0x649180
           push guid; call 0x51fc40
   remove: mov eax, [0xdf9b10]; mov edx, [eax+0x64]; ecx = 0xdf9b10; call edx   ; virtual erase
```

The player-side writer `FUN_006A4060`:
```
006A406D  mov eax, [ebx + 0x20]      ; previously-controlled guid
006A407F  cmp [ebp+0xc], eax / je skip
006A4082  mov eax, [0xdf9b10]; mov edx,[eax+0x64]; ecx = 0xdf9b10; call edx   ; virtual ERASE
006A409A  mov ecx, 0x17c0238 / call 0x5857e0        ; then touches the invincible container
```

Findings:
- The element payload is **not** fully undecoded — byte 0 is a flag written as `1`. The full
  stride is runtime-initialised (the static image has zeroes in the capacity/stride/page-table
  fields) and is not statically recoverable.
- The two writers do **not** write conflicting payloads. The conflict is different and real:
  the player-attach path performs a **virtual erase** (vtable slot `+0x64`) of the marker for the
  previously-controlled object. A script-installed `SetInfiniteAmmo` marker on an object the
  player subsequently attaches to and leaves **can be silently removed by the player path**.
  So "do both writers clobber each other?" resolves to: *not by overwrite, but yes by erase, in
  one direction (player path erases script state)*.
- `SetInfiniteAmmo` special-cases the player: if the target guid equals the player's controlled
  guid, it inserts regardless of the boolean argument.

### A14. Things I could not establish in Phase A

- The identity of the miss-path fallback record (`FUN_0064A5C0`) — SecuROM split-thunk into
  `.securom`, unresolved in this dump and absent from Ghidra. **Would be settled by**: an x32dbg
  read of `[0x02458A98]` once the loader has resolved it, then disassembling the target.
- Runtime element **stride** for any container — the `+0x24`/`+0x0C` stride words are zero in the
  static image and are filled by the constructors. **Would be settled by**: a live read of the
  container header, or by locating and reading each container's constructor.
- Whether the two arrays share one component-type-id space or are two independent numberings.
  Their id ranges overlap (`0x001–0x14C` vs `0x005–0x14E`) which is suggestive but not decisive.
- Semantics of most Array A component types (I decoded only health, node-health, hibernation,
  invincible, winch, position/transform, velocity).

---

## Phase A addendum — corrections found while cross-checking in Phase B

Two Phase A items were **my** error, not the map's. Recorded here rather than quietly fixed,
because they are exactly what a double-blind pass is supposed to surface.

**A4-bis. The shared zero-record on miss is REAL — I looked at the wrong function.**
In Phase A I checked `FUN_00649C60` and `FUN_00649C00` and concluded "miss → NULL". The
non-inlined resolver is **`FUN_00423DC0`**, and it is unambiguous:

```
00423DC3  call 0x6496b0                        ; probe (+alias)
00423DCA  jl   0x423df2                        ; probe miss  -----.
00423DCC  mov  ecx, [esi + 0x48]               ; packed key array |
00423DD2  mov  eax, [esi + 0x20]               ; capacity/mask    |
00423DD5  mov  cl,  [esi + 0x26]               ; page shift       |
00423DE0  movsx edx, word ptr [esi + 0x24]     ; element stride   |
00423DE9  mov  ecx, [esi + 0x70]               ; page table       |
00423DEC  add  eax, [ecx + edi*4]              ; record           |
00423DF0  jne  0x423df5                        ; null record  ----+
00423DF2  lea  eax, [esi + 0x7c]               ; <-- SHARED ZERO RECORD
00423DF5  ret
```

`this+0x7C` is returned on **both** the probe-miss and the null-record path. This confirms the
map's `+0x7C` row *and* its `+0x20/+0x24/+0x26/+0x48/+0x70` layout, field for field, in one
function.

**A4-ter. The alias fallback is real and recursive.** `FUN_006496B0`:

```
006496BA  lea  esi, [edi + 0x34]     ; hash sub-object at container+0x34
006496C0  call 0x648d80              ; plain probe
006496C7  jl   done                  ; guid < 0 (template) -> no alias attempt
006496CF  test cl, 1                 ; flag bit 3 set -> suppress alias
006496D4  cmp  eax, -1 / jne done    ; only on miss
006496DA  call 0x6654b0              ; guid -> alias/source guid
006496E4  je   return -1
006496F2  call 0x6496b0              ; *** RECURSES on the alias ***
```

Exactly as the map describes it. Note the alias step is skipped for negative (template) GUIDs.

**A13-bis. `0x00DF9B10` — the player path INSERTS too, not only erases.** Phase A saw only the
erase at `0x006A4083`. A third site at `0x006A4161`, gated on `[0x01175F59]`, performs the same
insert `SetInfiniteAmmo` does:

```
006A4166  push 0 / push 0 / push edi(guid) / push 0xdf9b10
006A4172  mov byte ptr [esp + 0x23], 1        ; identical 1-byte payload
006A4177  call 0x649180
```

So both features write **the same value with the same keys** (`key2 = subKey = 0`, payload byte
`1`) — see the revised §6.9 verdict below.

---

---

## Phase B — verdicts

The map was opened only after everything above was written.

**Headline assessment.** This map is substantially more careful than the brief implied. It labels
confidence per row, marks unread functions `binding-only` and explicitly claims nothing about them,
retracts an earlier draft's over-naming of `0x00DF9B10` in the open rather than editing it away, and
flags its conflict with `object_assembly_model.md` instead of silently picking a side. Its
container-layout table and resolve idiom are correct field-for-field against raw bytes. The defects
found are of two kinds: **one wrong scope claim**, and a set of **open questions that are open only
because Ghidra was used where a disassembler was needed**.

### B1. The headline

| Component | Verdict | Evidence |
|---|---|---|
| `luaL_Reg` at `0x00B99608`, 87 cfuncs, 0 stubs | **CONFIRMED** | `{NULL,NULL}` terminator at `0x00B998C0`; table belongs to `Object` per registry record `0x00DFD49C` |
| cfunc cluster `0x005CBC50–0x005D29F0` contiguous | **CONFIRMED** | all 87 targets land in range |
| Array base `0x00DF6B88`, end `0x00DF9E10` | **CONFIRMED** | valid container headers at both ends |
| Count **102** | **CONFIRMED** | 102 slots walked, 0 invalid, 102 unique ascending type ids |
| Uniform `0x80` stride, **single** `0x88` step at `0x00DF8408` | **CONFIRMED — exactly** | the only irregular step in the array; `101×0x80 + 8 = 0x3288` = measured span. Right to the byte |
| Each container has a distinct vtable | **CONFIRMED** | 102 distinct vtables |
| "`Object.*` does not talk to an entity object at all" | **CONFIRMED in substance** | no entity struct is ever indexed; every lookup is `guid → per-type container`. Caveat below |
| "**the** container array that **every one** of those cfuncs reads and writes" (§0) | **CONTRADICTED** | see B2 |

**Caveat on "no entity object".** The *lookup* claim is right and is the map's real insight. But
several cfuncs then pull an embedded pointer out of the resolved record and make **virtual calls**
on a real polymorphic object: `FUN_00649C60` returns `[rec+0x34]` (`SetVisible` writes
`word[+0x10]` on it); `FUN_005CCE00` takes `[rec+0x00]` and calls vtable `+0xE0`, `+0x84`, `+0x88`.
The map does show these call sites, so this is a wording issue in §0, not a missed fact.

### B2. The one substantive error: there is a **second container array**, and it is bigger

§0 says the 102-container array is what "every one of those cfuncs actually reads and writes". Not
so. A second regular array exists at **`0x017BBF58 … 0x017C0788`** — **232 containers, uniform
`0x50` stride**, same `{vtable, 0xFFFF, typeId}` header shape, ids `0x005…0x14E` strictly ascending
— and **30 `Object` cfuncs resolve against it**, including all four health functions.

The map does not miss this so much as mis-scope it. It knows `FUN_005857E0` is a different resolver
(citing `ecs_reflection_registry_code_map.md`), marks every such row `CMP`, caps them at confidence
**M**, and makes resolving them confirm-live item **§8.2** — calling it *"the highest structural
value in this list — one breakpoint settles ~20 rows at once."*

**That item does not need a breakpoint.** The container arrives in `ECX`; Ghidra drops it (the known
register-argument trap), but it is a plain `mov ecx, imm32` two instructions above every call site
in the raw disassembly. Statically resolving all of them:

| cfunc | container | type id | array-A index |
|---|---|---|---|
| `GetHealth`, `SetHealth`, `GetMaxHealth`, `IsAlive`, `Revive` | **`0x017BEF78`** | `0x0EA` | A#154 |
| `GetHealth`, `GetMaxHealth`, `IsAlive` (fallback) | `0x017BBF58` | `0x005` | A#0 |
| `GetNodeHealth` | `0x017BEFC8` | `0x0EB` | A#155 |
| `IsAwake`, `IsHibernated`, `IsVisible`, `Revive`, `GetHealth`, `IsAlive` | `0x017C02D8` | `0x13A` | A#216 |
| `GetHibernationDistance`, `SetHibernationDistance` | `0x017BD178` | `0x062` | A#58 |
| `GetVelocity`, `GetVelocitySquared`, `GetVelocityVector` | `0x017BCB38` | `0x041` | A#38 |
| `SetYaw`, and `SetPosition`'s worker `FUN_005CCE00` | `0x017BF888` | `0x10F` | A#183 |
| `SetYaw` (second) | `0x017BF9C8` | `0x113` | A#187 |
| all six winch cfuncs | `0x017BF8D8` | `0x110` | A#184 |
| all four animation cfuncs | `0x017C00F8` | `0x131` | A#210 |
| `GetInvincible` | `0x017C0238` | `0x136` | A#214 |
| `GetLocalizedName` | `0x017BD768` | `0x07A` | A#77 |
| `GetCashValue` | `0x017BD718` | `0x079` | A#76 |
| `FadeOut` | `0x017BFD38` | `0x11F` | A#198 |
| `GetPhysicsType` | `0x017BC1D8/228/278/2C8/318` | `0x01B,0x01C,0x01D,0x01F,0x020` | A#8–12 |

**§8.2 is closed.** 30 cfuncs, 19 distinct containers, each with its reflection type id ready to
join to `docs/ecs_components.md`. The map's "~20 rows" estimate was conservative.

Consequence for §7.1 reimpl guidance: "102 paged containers, `0x80` stride" understates the model.
There are **two** container classes with **different layouts** — array B keeps its hash sub-object
inline (`+0x20/+0x24/+0x26/+0x48/+0x70`), array A keeps it at `this+0x18` (per `FUN_005857E0`) or
`this+0x34` (per `FUN_006496B0`). A reimpl told "one templated container type instantiated 102
times" (§1.1) will model the wrong thing.

### B3. The health dispute — SETTLED IN THE MAP'S FAVOUR

§5.1 concludes the record is **`{max, current}`** from `SetHealth`'s clamp alone, and flags
`object_assembly_model.md`'s `RuntimeHealth {cur, max}` as the likely error without overwriting it.
It reached the right answer with one function; it could not read `GetHealth` or `GetMaxHealth`
because both are in its binding-only 24.

Both now read, and both agree:

| function | container | offset touched | meaning |
|---|---|---|---|
| `GetMaxHealth` `0x005CC030` | `0x017BEF78` | `movss xmm0, [eax]` — **+0x00** | returns **max** |
| `GetHealth` `0x005CBDB0` | `0x017BEF78` | `movss xmm0, [eax+4]` — **+0x04** | returns **current** |
| `SetHealth` `0x005CBEE0` | `0x017BEF78` | clamps to `[esi]`, stores `[esi+4]` | ceiling **+0x00**, written **+0x04** |

> **VERDICT: `{ +0x00: f32 max, +0x04: f32 current }`.** The map is **CONFIRMED**.
> `docs/modernization/object_assembly_model.md` §2 `RuntimeHealth {cur, max}` has the fields
> **swapped and should be corrected**. Confirm-live item **§8.6 is closed** — three independent
> readings, no breakpoint required. The component is type id **`0x0EA`** at `0x017BEF78`.

`GetNodeHealth`: **u16 at node+0x06**, `movzx` → `cvtsi2ss`. An *integer* widening, so this cannot
be a float field. §5.2 is **CONFIRMED**, and `RuntimeNodeHealth` "one float per node" is also wrong.
Node health uses a **different** container, `0x017BEFC8` (id `0x0EB`), which the map did not name.

### B4. Contested items, one by one

| # | Claim | Verdict | Detail |
|---|---|---|---|
| 1 | Resolve idiom: probe `FUN_00648D80` → key at `+0x48` → `(mask&key)*stride + pageTable[key>>shift]` | **CONFIRMED verbatim** | verified in `FUN_00649C60` and `FUN_00423DC0`; `+0x20/+0x24/+0x26/+0x48/+0x70` all exact |
| 2 | Shared **zero record at `+0x7C`** returned on miss | **CONFIRMED** | `FUN_00423DC0` returns `lea eax,[esi+0x7c]` on probe-miss *and* null-record. My Phase A doubt was my error |
| 3 | `FUN_006496B0` = `FUN_00648D80` + alias step, recurses via `FUN_006654B0`, suppressed by flag bit 3 | **CONFIRMED verbatim** | plus a detail the map omits: the alias step is skipped for **negative (template) GUIDs** |
| 4 | The map's correction of `player_code_map.md` — `FUN_006496B0` returns the **bucket**, not a dense slot | **CONFIRMED** | `FUN_00648D80` returns the bucket index; `+0x48` maps bucket → packed key. The correction of its sibling is right |
| 5 | Container layout `+0x20` mask · `+0x24` stride (i16) · `+0x26` shift · `+0x48` key array · `+0x70` page table · `+0x7C` zero record | **CONFIRMED, all six** | one function (`FUN_00423DC0`) exhibits all of them |
| 6 | Health `{max, current}` | **CONFIRMED** | see B3 |
| 7 | `GetNodeHealth` reads a **u16** | **CONFIRMED** | `movzx eax, word ptr [eax+6]` → `cvtsi2ss` |
| 8 | `SetHealth` on a missing component is a **Lua error**, not nil | **CONFIRMED** | `0x005CC01B: call 0x4b2a50` on the null-record path |
| 9 | `SetHealth` full→damaged edge notify | **CONFIRMED** | `ucomiss max,cur` + `comiss cur,new` gate a call. Map names it `thunk_FUN_028D1000`; the direct target is **`FUN_00665BE0`** |
| 10 | `Kill` posts to `FUN_0042BE60`, returns nothing, bounded `0x400`, silently lossy | **CONFIRMED** | bound `0x400` ✓, 16-byte elements at `0x011B51A8` ✓, critsec `0x011BA1B0` ✓, gate `0x011BA1A8` ✓, popcount table `0x011B5128` ✓, overflow jumps straight to `LeaveCriticalSection` ✓, `xor eax,eax` = 0 results ✓ |
| 10a | …described as a **ring** | **TERMINOLOGY WRONG** | no modulo, no wrap. The index only increments; a full buffer **drops the newest**, where a ring overwrites the oldest. The map's own prose ("no else branch") is correct — only the word "ring" is not |
| 10b | Kill's message is `{guid, guid, 0, 0, 0, 0}` | **CONTRADICTED (minor)** | the second dword is **0**, not a repeat: `[esp+0xc]=guid`, `[esp+0x10]=0`, `[esp+0x14]=0`, `[esp+0x18]=0`, `[esp+0x19]=0` |
| 11 | `AddToDisposer` writes label `0xF956736B` into `0x00DF8108`; `pandemic_hash_m2("disposable") == 0xF956736B` | **CONFIRMED** | recomputed independently → `0xF956736B`; literal `push 0xf956736b` at `0x005D29B9`, and the *value* local set to the same hash at `0x005D29C6` — matching the map's `(…, 0xF956736B, &0xF956736B)` exactly |
| 11a | `AddToDisposer` also calls `FUN_004F3D30` | **CONFIRMED** | the map notes this in §4.3 |
| 11b | §7.5's shorthand "**`AddToDisposer` == `AddLabel(guid,"disposable")`**" | **OVERSTATED (in §7 only)** | §4.3 is precise; the §7 reimpl bullet is not. `AddLabel` is variadic and **returns a boolean**; `AddToDisposer` takes one guid and **returns nothing**. A reimpl following §7.5 literally gets the return arity wrong. This difference appears nowhere in the map |
| 12 | `SetVisible` bit is **inverted** (set = hidden), bit 0 of `u16` at `rec+0x10`, one-shot latch `DAT_0198E180` | **CONFIRMED, all three** | `and word[eax+0x10],0xfffe` on visible=true, `or` on false; latch at `0x0198E180` present |
| 13 | `IsVisible` is a frustum/occlusion query, **not** `SetVisible`'s inverse | **CONFIRMED** | different field (`word[+0x18] & 0x3000 == 0x2000`), then `FUN_0070F640` (camera) + `FUN_00665BB0` + `FUN_00424770`, compared to threshold `0x00BEB528`. "Frustum/occlusion" is plausible; the test inside `FUN_00424770` is unread |
| 14 | `SetPosition` = commit then two world vtable hooks `+0x84`/`+0x88` behind the `+0xE0 == 1` gate | **CONFIRMED** | the map's pseudocode `(*(code**)(*w + 0xE0))() == 1` correctly shows this as a **virtual call whose return is compared to 1**. Commit is `FUN_006658B0`; container is **`0x017BF888`** (id `0x10F`), which the map could not name |
| 15 | `AreEqual` touches no engine state | **CONFIRMED** | complete call set is `{0x0059FF50, 0x0085D5D0}` — Lua arg fetch and stack push only. Tag checks `7` and `2` present as described |
| 16 | `Remove` branches on bit 31, `0xC0000000`, `0xF0000000 == 0x40000000` | **CONFIRMED, all three** | at `0x005CDC94`, `0x005CDC98`, `0x005CDCB6/BC`; guard `DAT_00DFBD77` at `0x005CDCAB` ✓ |
| 16a | bit 31 = template | **CONFIRMED independently** | `IsTemplate` `0x005CBD20` is literally `setl` on `guid < 0` — its entire payload |
| 17 | `IsHibernated` / `RevertHibernationDistance` are "binding-only, **VA-known only**" | **CONTRADICTED** | both have full bodies: 192 B / 70 instrs and 400 B / 80 instrs. `IsHibernated` resolves `0x017C02D8`; `RevertHibernationDistance` resolves `0x017BD178`. The map's demotion of these two is wrong, and it demoted *previously-recovered* knowledge to do it |
| 18 | `0x00DF9B10` is a **shared** marker container, not the "infinite ammo container" | **CONFIRMED** | the retraction of the earlier over-naming is correct and well-made |
| 18a | "Those are the container's **only** non-ctor users" (3 writers) | **CONTRADICTED** | **20** `.text` references, including sites Ghidra never symbolised: `0x4C5382, 0x4C538D, 0x51A2D1, 0x51AF0B, 0x51DD4B, 0x51E237, 0x51F580, 0x51F60D, 0x52D8D5, 0x585878, 0x66B768, 0x6A416E, 0xA7C7A1, 0xA7C7B8, 0xB03211`. The `PTR_PTR_` symbol sweep under-counts |
| 18b | element layout **undecoded**; "if the element is one byte they clobber each other" | **PARTLY DECODED — hypothesis now testable** | both writers pre-fill the payload local with **byte `1`** and pass `key2 = subKey = 0`, so they write **the same value into the same row**. See B5 |
| 19 | Recovery score **63 of 87 (72 %), 24 binding-only** | **CONFIRMED as a Ghidra statistic** | reproduced **exactly** — 63 definitions present, 24 absent, same 24 names |
| 19a | The 24 need "the forcing-script pass" (§8.8) to recover | **UNDER-CLAIMS — no forcing pass needed** | all 24 disassemble immediately with capstone on the same unpacked exe. §8.8 is the map's #8 priority and costs ~nothing. See B6 |

### B5. `0x00DF9B10` — sharpening the map's own open question

§6.9's worry is: *"Both writers pass `0, 0` for `key2`/`subKey`. If the element is a single byte,
the two features would clobber each other… That would be a shipped bug."*

What the bytes show:

- `Object.SetInfiniteAmmo` `0x005CE7E0` — inserts `payload byte = 1`, `key2 = subKey = 0`. If the
  target guid equals the **player's controlled guid** (`FUN_006CDAF0(0)`, then `+0x20`), it inserts
  **regardless of the boolean argument**. With the boolean false it instead calls the container's
  **vtable `+0x64` erase**.
- The player path `0x006A4161` — inserts the **identical** `payload byte = 1`, `key2 = subKey = 0`,
  gated on `[0x01175F59]`.
- The player path `0x006A4083` — calls the same **vtable `+0x64` erase** for the
  *previously*-controlled guid.

So the two features do **not** corrupt each other's payload; they write the same byte. The hazard is
the **erase**: the row is shared and unkeyed, so whichever feature erases first revokes the other.
Concretely, the map's predicted direction is backwards — *granting* infinite ammo does not drop
player control (both write `1`), but the **player-attach path's erase can silently revoke a
script-installed `SetInfiniteAmmo`** when control moves off the object.

That makes the map's proposed behavioural test the wrong way round. The test that would settle it:
`Object.SetInfiniteAmmo(obj, true)` on a vehicle, then enter and leave it, and check whether
infinite ammo survives. §8.11 also asks to identify the third writer `FUN_0066B710` — there are
considerably more than three (B4 #18a).

### B6. The 24 "binding-only" bodies — the most expensive avoidable gap

The map is scrupulous here: it states plainly that 27 % of `Object` traffic sits on unread
functions, refuses to infer them, and makes recovery item §8.8. That honesty is right. The problem
is the **remedy**: §8.8 proposes a forcing-script pass, and the preamble explains the bodies are
missing "because a binding-table-only function has no static caller for Ghidra's auto-analysis to
walk from".

The diagnosis is exactly right; the conclusion drawn from it is too pessimistic. **The bodies are
plainly there.** All 24 disassemble from the same unpacked exe the map already uses, with a ~20-line
capstone script and the PE section table. Sizes range from 16 B (`EnablePhysics`, `DisablePhysics`)
to 1136 B (`GetPhysicsType`).

This pass read 9 of the 24 in full and, from them, closed two of the map's flagged open items (§8.6
health ordering; §8.2 for the health/hibernation rows). The remaining 15 are the same work.
Concretely recovered here:

- `EnablePhysics` `0x005D0740` / `DisablePhysics` `0x005D0750` — **5-instruction thunks** to a
  shared worker `FUN_005D0650` with `1` / `0`. §6.1's hypothesis ("their adjacency says they are
  one-liners over the same handle") is **CONFIRMED** — 43 call sites' worth of traffic settled by
  reading 32 bytes.
- `IsTemplate` `0x005CBD20` — `setl` on `guid < 0`; nothing else.
- `GetHealth` / `GetMaxHealth` — see B3.
- `IsHibernated` / `RevertHibernationDistance` — see B4 #17.

### B7. Summary counts

| Verdict | Count |
|---|---|
| CONFIRMED (5 of them verbatim against raw bytes) | 27 |
| CONFIRMED, with a detail the map omits | 5 |
| CONTRADICTED | 4 (#10b Kill message shape · #17 hibernation pair · #18a writer count · §0 "every cfunc") |
| OVERSTATED | 1 (#11b, §7.5 only) |
| TERMINOLOGY WRONG | 1 (#10a "ring") |
| UNDER-CLAIMED by the map | 2 (#19a recovery ceiling · §8.2 solvable statically) |
| MISSING | 1 (the 232-container array A) |

Open items this pass **closes**: **§8.2** (30 cfuncs → 19 named containers with type ids), **§8.6**
(health ordering, and node health u16), and **§6.1**'s physics-stub hypothesis. Open items
**sharpened**: §8.11 (`0x00DF9B10`), §8.8 (recovery is cheap).

### B8. What I could not check

- Anything needing **runtime** state. Every container's capacity, stride, page table and live count
  are **zero in the static image** — written by the ctors at init. So §8.11's "read `container+0x24`
  live" is still the right instruction; I confirmed the *field* is the stride but not its value.
- `FUN_0064A5C0` — a SecuROM split-thunk (`jmp dword ptr [0x02458A98]` → `0x024EFA10`, inside
  `.securom`), absent from the Ghidra export. Not needed for any verdict once `FUN_00423DC0` was
  found.
- Whether `FUN_00424770` (inside `IsVisible`) is specifically a **frustum** test or another
  camera-relative metric. The map's "frustum/occlusion" is plausible and unfalsified, not proven.
- The semantics of the **great majority** of the 102 + 232 component type ids. I named 19 of array A
  and ~9 of array B — all ones the `Object` namespace happens to touch. §8.1 ("name the other 93")
  remains open and is now larger than it looked: **~334 containers total**, not 102.
- Whether arrays A and B share one type-id space. Their ranges overlap (`0x001–0x14C` vs
  `0x005–0x14E`), suggestive but not decisive.
- **Script call-site counts** (1272 total, `GetPosition` 201, etc.) — these come from the Lua corpus,
  not the binary, and were outside this pass's evidence base. Unverified either way.
- The map's Transform-record reading (8 dwords, dword 3 a change serial, `[4..7]` a quaternion),
  §1.4's `FUN_00649180` internals, §1.5's cursor pool, §6.8's `IsPlayerControlled` three-container
  join, and the `player+0x24` history — not re-derived. Not in the contested set; no claim made.
- All non-falsifiable prose (design rationale, reimpl advice, naming) was not classified.

---

## Pass 2

**Method.** Everything below was re-derived from raw bytes of
`output/_ghidra/securom_dump/mercs2_unpacked.exe` with `capstone` + `pefile`, VA→file offset via
the PE section table. Pass 1's verdicts were treated as untrusted claims to re-test, never as
evidence. Section map for this image — `.text` VA `0x00401000` raw `0x1000`; `.rdata` VA
`0x00B05000` raw `0x705000`; `.data` VA `0x00BF6000` raw `0x7F6000` (size `0xE04000`, so **all of
`0x017Bxxxx` lies inside `.data`**); `Stext` VA `0x01A49000` raw `0x1649000`; `.securom` VA
`0x023E9000` raw `0x1FE9000`.

### P0. Open register

The items pass 1 did not explicitly CONFIRM, plus its whole "B8. What I could not check", and
their pass-2 disposition.

| # | Item | Pass-1 state | Pass-2 |
|--:|---|---|---|
| 1 | `Kill` message shape `{guid,guid,0,0,0,0}` | CONTRADICTED | **upheld** (P5.7) |
| 2 | `IsHibernated`/`RevertHibernationDistance` "VA-known only" | CONTRADICTED | **upheld** (P4) |
| 3 | `0x00DF9B10` "only 3 non-ctor users" | CONTRADICTED | **upheld** (P5.6) |
| 4 | §0 "**the** container array **every** cfunc reads" | CONTRADICTED | **upheld** (P1) |
| 5 | §7.5 `AddToDisposer == AddLabel(…)` | OVERSTATED | **upheld** (P5.8) |
| 6 | §8.8 recovery ceiling 63/87 | UNDER-CLAIMS | **CLOSED — ceiling is 87/87, all 24 read** (P4) |
| 7 | §8.2 solvable statically | UNDER-CLAIMS | **CLOSED — 55/87 cfuncs, 33 containers, all named** (P1.4) |
| 8 | The 232-container array A | MISSING from map | **CLOSED — full census of both arrays** (P1) |
| 9 | Container capacity / stride / page-shift | "all zero statically" | **CONTRADICTED — present for all 334** (P3) |
| 10 | Do arrays A and B share one type-id space? | open | **SETTLED — one space, proven two ways** (P2) |
| 11 | `FUN_00424770` frustum test or not? | open | **CLOSED — not a frustum test** (P5.1) |
| 12 | `FUN_0064A5C0` | "not statically resolvable" | **CONTRADICTED — resolved** (P5.2) |
| 13 | Transform record, dword-3 serial, `[4..7]` quaternion | not re-derived | **CONFIRMED; quaternion now PROVEN** (P5.3) |
| 14 | `FUN_00649180`, cursor pool, `IsPlayerControlled` join | not re-derived | **CONFIRMED, with refinements** (P5.4–P5.5) |
| 15 | Script call-site counts (1272, `GetPosition` 201, …) | "outside evidence base" | **CONFIRMED exactly** (P6) |
| 16 | Semantics of the 102 + 232 component type ids | open | **CLOSED — all 334 named** (P1, P8) |
| 17 | `player+0x24` non-zero setter | open | **STILL-OPEN, narrowed to one instruction** (P7.1) |

---

### P1. The master key works, and it names all 334 containers

**The key.** `container[0]` is the vtable; `[vtable+0x34]` is a two-instruction accessor
`mov eax, <char*>; ret`. Verified against all 12 seed containers, then applied blind.

This is not a pattern imposed from outside — **the engine itself uses it.** `FUN_0064A7E0` walks
the registry and does exactly this to compute each component's name hash:

```
0064A7F4  mov   esi, [edi*4 + 0xedbec8]   ; registry[i]
0064A7FB  mov   edx, [esi]                ; vtable
0064A7FD  mov   eax, [edx + 0x34]         ; <-- the name accessor
0064A802  call  eax
0064A80E  mov   ecx, 0x811c9dc5           ; FNV-1a offset basis
0064A813  movsx edx, dl / or edx, 0x20    ; case-suppress
0064A819  xor   ecx, edx
0064A81E  imul  ecx, ecx, 0x1000193       ; FNV prime
0064A82B  xor   ecx, 0x2a                 ; the M2 tail
0064A82E  imul  ecx, ecx, 0x1000193
0064A834  mov   [esi + 0x10], ecx         ; container+0x10 = name hash
```

That is `pandemic_hash_m2` verbatim. So the string at `[vtable+0x34]` **is** the component's
shipped identity, and `container+0x10` holds its hash at runtime. No name and no hash below was
invented; every one is read from, or recomputed over, the shipped name string
([[no-arbitrary-hashes]]).

**The sweep.** Scanning all of `.data` for `{vtable in .rdata, u16@+0x04 == 0xFFFF, [vtable+0x34]
decodes to mov/ret, target is an ASCII identifier}` returns **exactly 334 hits, in exactly two
contiguous runs, and nothing else**:

| | Array **B** | Array **A** |
|---|---|---|
| span | `0x00DF6B88 … 0x00DF9E10` | `0x017BBF58 … 0x017C0788` |
| count | **102** | **232** |
| stride | `0x80`, with one `0x88` step at `0x00DF8408` | uniform `0x50` |
| type ids | `0x001 … 0x14C` | `0x005 … 0x14E` |

Pass 1's geometry for **both** arrays is CONFIRMED to the byte, including the lone `0x88` step.

**Independent validation of the census.** `docs/modernization/object_assembly_model.md` records two
component hashes from an entirely different derivation. This method reproduces both from the name
string alone:

| component | doc's hash | `pandemic_hash_m2(name)` via `[vtable+0x34]` | |
|---|---|---|---|
| `RuntimeHealth` | `0xF9B9B2A5` | `0xF9B9B2A5` | ✅ |
| `RuntimeNodeHealth` | `0x76927BF5` | `0x76927BF5` | ✅ |

Two exact 32-bit matches against a document that never saw this method. Per
[[aset-name-export]] a bare hash match is not evidence — but here the *name*, the *hash*, the
*container address* and the *cfunc that uses it* all agree, which is a four-way join.

#### P1.1 §8.1 is closed outright

§8.1 asks to "name the other 93" and proposes a **breakpoint at static-init**. No breakpoint is
needed — all 334 names are in the static image. Corrections that fall straight out:

- **`0x00DF9C90` is `RuntimeSceneObject`, not "the Transform container"** (id `0x13C`, stride 56).
  The map calls it "Transform" throughout; the engine does not.
- **`0x00DF9B90` is `Players`** (id `0x138`, stride 4, **capacity 8**).
- **`0x00DF9B10` is `CheatInfiniteAmmo`** (id `0x137`, stride **1**) — see P3.2 and P5.6.
- `0x00DF6B88` = `Name` · `0x00DF6C08` = `ModelName` · `0x00DF8108` = `Label` ·
  `0x00DF8188` = `SeatLink` · `0x00DF9110` = `RuntimePhysicalLink` · `0x00DF9890` = `RtPoweredGate`.
- `0x017C02D8` = `SceneObject` (id `0x13A`) · `0x017BEF78` = `RuntimeHealth` ·
  `0x017BEFC8` = `RuntimeNodeHealth` · `0x017BBF58` = `Health` (id `0x005`) ·
  `0x017BF888` = `PhysicsActor` · `0x017BF8D8` = `PhysicsActorWinch` ·
  `0x017C00F8` = `BoneControllerRuntime` · `0x017C0238` = `RtDamageFlags` ·
  `0x017BD178` = `HibernationControl` · `0x017BD718` = `CashValue` ·
  `0x017BD768` = `LocalizedName` · `0x017BCB38` = `ControllerVelocity`.

Every container pass 1 identified by address is confirmed at that address, and now carries its
shipped name.

#### P1.2 `GetInvincible`'s container is `RtDamageFlags`

Pass 1 labelled `0x017C0238` by address only. It is **`RtDamageFlags`** (id `0x136`, stride 4) —
which independently supports the map's §5.4 reading that "invincible" and "unkillable" are
**separate bits in one damage-flags word** rather than two components. §5.4 is **CONFIRMED** and
now has a named home.

#### P1.3 The `0x88` anomaly, and a real structural refinement

`RiderLink` (`0x00DF8408`, id `0x83`) is the one container with a `0x88` step. Dumped against its
neighbour `Rider` (`0x00DF8388`, `0x80`) it is byte-identical in structure through `+0x7F`; the
extra 8 bytes at `+0x80` are zero padding, not a field. **The map's "single exception" is real but
carries no meaning.**

The meaningful finding is elsewhere: **every array-B container carries two hash-index sub-objects,
at `+0x34` and `+0x50`**, each shaped
`{…, mult@+0x0C = 0x9E3779B9, keys@+0x10, slots@+0x14, owner-backptr@+0x18}`. That collapses four
of the map's §1.2 rows into one repeated structure:

| map's §1.2 row | actually |
|---|---|
| `+0x44` "dense owner-GUID array" | key array of **index 1** (`+0x34` + `0x10`) |
| `+0x48` "bucket → packed record key" | slot table of **index 1** (`+0x34` + `0x14`) |
| `+0x60` "dense secondary-key array" | key array of **index 2** (`+0x50` + `0x10`) |
| `+0x64` "hash bucket table" | slot table of **index 2** (`+0x50` + `0x14`) |

Every offset the map states is correct; the *structure* is two instances of one index type, not six
ad-hoc arrays. `0x9E3779B9` is the golden-ratio multiplier `FUN_00648D80` uses.

Three independent confirmations that the second index is real and load-bearing:
`FUN_006499F0`'s third argument selects between them (`lea eax,[ebp+0x34]` / `jne` →
`lea eax,[ebp+0x50]`); `Object.InSeat` probes `0x00DF8458` = **`RiderLink+0x50`** (the reverse
index); and `Object.GetName` probes `0x00DF6BBC` = **`Name+0x34`** (the forward one).

#### P1.4 §8.2 closed: every `Object` cfunc's container, by name

**55 of 87** cfuncs carry a direct container reference — pass 1 measured 32 (array A) + 23 (array
B) = 55, **exact agreement** — touching **33 distinct containers**. Ghidra hid all of these because
the container arrives as `mov ecx, imm32` (trap 1). The map's §8.2 estimate of "~20 rows" was
conservative by a factor of nearly three, and no breakpoint is required for any of them.

| cfunc | container(s) |
|---|---|
| `AddLabel` | `Label` |
| `AddQualityRef` | `ModelName` |
| `AddToDisposer` | `Label` |
| `Attach` | `RuntimePhysicalLink` |
| `AttachCargoToWinch` | `PhysicsActorWinch` |
| `CloseGate` | `RtPoweredGate` |
| `Detach` | `RuntimePhysicalLink` |
| `DetachCargoFromWinch` | `PhysicsActorWinch` |
| `FadeOut` | `RtAlphaAnimation` |
| `GetAttachedObjects` | `RuntimePhysicalLink` |
| `GetCashValue` | `CashValue` |
| `GetHealth` | `RuntimeHealth`, `Health`, `SceneObject` |
| `GetHibernationDistance` | `HibernationControl` |
| `GetInvincible` | `RtDamageFlags` |
| `GetLocalizedName` | `LocalizedName` |
| `GetMaxHealth` | `RuntimeHealth`, `Health` |
| `GetModelName` | `ModelName` |
| `GetName` | `Name` |
| `GetNodeHealth` | `RuntimeNodeHealth` |
| `GetPhysicsType` | `_CarPhysicsV2`, `_TankPhysics`, `_HelicopterPhysics`, `_BoatPhysics`, `_HumanPhysics` |
| `GetVelocity` | `ControllerVelocity` |
| `GetVelocitySquared` | `ControllerVelocity` |
| `GetVelocityVector` | `ControllerVelocity` |
| `GetWinchState` | `PhysicsActorWinch` |
| `HasLabel` | `Label` |
| `HasWinch` | `PhysicsActorWinch` |
| `InSeat` | `RiderLink` |
| `InVehicle` | `RiderLink`, `SeatLink` |
| `IsAlive` | `RuntimeHealth`, `Health`, `SceneObject` |
| `IsAttached` | `RuntimePhysicalLink` |
| `IsAwake` | `SceneObject`, `ModelName` |
| `IsDisguised` | `Players` |
| `IsHibernated` | `SceneObject` |
| `IsPlayerControlled` | `Players`, `SeatLink` |
| `IsVisible` | `SceneObject` |
| `IsWinched` | `PhysicsActorWinch` |
| `IsWinching` | `PhysicsActorWinch` |
| `OpenGate` | `RtPoweredGate` |
| `PlayAnimation` | `BoneControllerRuntime` |
| `RemoveFromDisposer` | `Label`, `RuntimeModelState`, `RuntimePhysicalLink`, `Name` |
| `RemoveLabel` | `Label` |
| `RevertHibernationDistance` | `HibernationControl`, `SphereRegion`, `CircleRegion`, `LineRegion` |
| `Revive` | `RuntimeHealth`, `SceneObject`, `HumanStateMachine` |
| `SetHealth` | `RuntimeHealth` |
| `SetHibernationDistance` | `HibernationControl` |
| `SetInfiniteAmmo` | `CheatInfiniteAmmo` |
| `SetModelName` | `ModelName`, `PhysicsActor` |
| `SetName` | `Name` |
| `SetPositionToObject` | `Name` |
| `SetTransformToObject` | `Name` |
| `SetWinchState` | `PhysicsActorWinch` |
| `SetYaw` | `PhysicsActor`, `RTHuman` |
| `StopAllAnimation` | `BoneControllerRuntime` |
| `StopAnimation` | `BoneControllerRuntime` |
| `StopAnimationChannel` | `BoneControllerRuntime` |

### P2. Arrays A and B share ONE type-id space — SETTLED, two independent ways

Pass 1 left this as "suggestive but not decisive". It is decisive.

**(a) Arithmetic.** The union of the 334 type ids is **exactly `0x001 … 0x14E`, contiguous, with
zero gaps and zero collisions**:

```
A: 232 ids, 0x005..0x14E, all unique
B: 102 ids, 0x001..0x14C, all unique
A ∩ B = ∅          (overlap count = 0)
A ∪ B = 334 ids = exactly range(1, 335)   — 0 gaps
0x14E = 334 = the total container count
```

Two independent numberings would have to collide 100 times over a shared 334-wide range to produce
this. They never collide once, and together they tile the range perfectly. **One space.**

**(b) Mechanism.** `FUN_0064A770` is the self-registration every container ctor tail-calls, and the
id is a **running total of both counters**:

```
0064A770  mov  ecx, [eax + 8]        ; container flags
0064A773  shr  ecx, 3
0064A776  test cl, 1                 ; flags bit 3 selects the registry
0064A779  je   0x64a7aa
0064A77B  jmp  dword ptr [0x244f738] ; -> 0x004CC62C: mov cx,[0x117605c]; jmp 0x64a782
;--- bit-3 SET path (registry 0x00EDBAC8, counter [0x0117605C])
0064A782  movsx edx, cx / add cx, 1
0064A789  mov  word ptr [0x117605c], cx
0064A790  mov  ecx, [0x1176058]              ; <-- the OTHER counter
0064A796  mov  [edx*4 + 0xedbac8], eax
0064A79D  mov  edx, [0x117605c]
0064A7A3  add  ecx, edx                      ; <-- id = countA + countB
0064A7A5  mov  word ptr [eax + 6], cx        ; container+0x06 = type id
;--- bit-3 CLEAR path (registry 0x00EDBEC8, counter [0x01176058])
0064A7AA  mov  cx, word ptr [0x1176058]
0064A7B4  add  cx, 1
0064A7B8  mov  [edx*4 + 0xedbec8], eax
0064A7BF  mov  edx, [0x117605c]              ; <-- the OTHER counter
0064A7C5  mov  word ptr [0x1176058], cx
0064A7CC  mov  ecx, [0x1176058]
0064A7D2  add  ecx, edx                      ; <-- id = countA + countB
0064A7D4  mov  word ptr [eax + 6], cx
```

Both paths write `container+0x06 = countA + countB` — **the total number of containers registered so
far, across both registries**. That is a single monotone counter by construction, which is exactly
why the ids tile `1…334` with no gaps. Note also that **the type id lives at `+0x06`**, not `+0x04`;
`+0x04` is a constant `0xFFFF` sentinel.

**⚠ A boundary claim in a sibling map is wrong.** `ecs_reflection_registry_code_map.md` §0.5 and
§2.1 describe the `flags & 8` split (`PTR_PTR_00edbec8` "authored" vs `PTR_PTR_00edbac8`
"`Runtime*`") — that part is correct, and that map already has `FUN_0064A770`, `FUN_0064A782`,
`FUN_0064A7E0`, both counters, and the `[vtable+0x34]` name accessor decompiled. But it treats that
as *the* class taxonomy. Measured over all 334:

| split | partition |
|---|---|
| registry (`flags & 8`) | **116** → `0x00EDBAC8` · **218** → `0x00EDBEC8` |
| container array (storage) | **232** array A (`0x50`) · **102** array B (`0x80`) |

**These are orthogonal.** Array A holds 89 bit-3-set and 143 bit-3-clear containers; array B holds
27 and 75. Neither array is "the Runtime array". (The `Runtime*` naming heuristic is a good but
imperfect proxy for the *registry* bit: all 116 `Runtime*`/`Rt*`-named containers have bit 3 set,
but so do 25 others.) That map's **231-class census is an undercount of array A only** — it has no
concept of the `0x80`-stride array, and `docs/mercs2-ecs/` covers **zero** of array B's 102.

### P3. Container capacity / stride / page-shift are STATIC — pass 1 CONTRADICTED

Pass 1's B8 opens with: *"Every container's capacity, stride, page table and live count are **zero
in the static image** — written by the ctors at init. So §8.11's 'read `container+0x24` live' is
still the right instruction."* Pass 1 also sent this to x32dbg in A14.

**That is wrong, and it sent a static question to a debugger.** The values are in the image. The
ctor (`FUN_00A7C880` for `RuntimeSceneObject`) only writes the vtable and zeroes `+0x74`; the
descriptor fields are **initialized data**, not ctor-written:

```
RuntimeSceneObject @ 0x00DF9C90:
  +0x00 vtable 0x00BC4138   +0x04 0xFFFF   +0x06 id 0x013C   +0x08 flags 0x08
  +0x20 = 0x00000100  page mask / records-per-page = 256
  +0x24 = 0x0038      element stride = 56
  +0x26 = 0x0008      page shift = 8
  +0x28 = 0x9E3779B9  hash multiplier
```

**Self-validating check.** For all 334 containers, `capacity == 2 ** page_shift` holds **without a
single exception** (A: 4↔2, 8↔3, 16↔4, 32↔5, 64↔6, 128↔7, 256↔8; B likewise). Two independently
read fields agreeing arithmetically 334 times out of 334 is proof the right offsets were read.
(Array A keeps these at `+0x24`/`+0x26`/`+0x28` — its hash sub-object is at `+0x18`, so
`[edi+0x0C]`/`[edi+0x0E]`/`[edi+0x10]`; array B keeps mask inline at `+0x20`. Pass 1's A4 reading of
both layouts is otherwise CONFIRMED.)

Strides are not uniform and not trivial: array A spans 1…396 bytes, array B spans 1…740.

#### P3.1 `docs/game_config/cdbsizes.ini` is a third, independent corroboration

`cdbsizes.ini` budgets `CheatInfiniteAmmo 256 128` — and the static descriptor says **cap = 128**.
The shipped config file and the shipped binary agree. That is a data-side cross-check of the whole
extraction that touches neither Ghidra nor the disassembler.

#### P3.2 §8.11 / §6.9 CLOSED statically: the element **is** one byte

The map's §6.9 says the `0x00DF9B10` element layout is "undecoded" and reasons:

> **Both writers pass `0, 0` for `key2`/`subKey`.** If the element is a single byte, the two features
> would **clobber each other** … More likely the element is a small struct and the two zero
> arguments select a field or slot within it — but **the element layout is undecoded**.

**`CheatInfiniteAmmo` (id `0x137`) has stride `1` and capacity `128`.** The element is exactly one
byte. The map's "more likely a small struct" is **CONTRADICTED**; its first branch is the true one.
§8.11's instruction "read `container+0x24` (stride) live" is answered from the static image: it is 1.

This does **not** make it a shipped bug, because pass 1's B5 already showed both writers store the
same value (`byte = 1`, `key2 = subKey = 0`). The real hazard is the **erase**, and that reading
stands. See P5.6 for the cheat gating, which changes the framing again.

### P4. The 24 "binding-only" bodies — read, and the ceiling is 87/87

Pass 1 asserted all 24 disassemble and read 9. **All 24 read in full this pass**, and all 87 table
targets terminate cleanly (`ret` + `int3` padding, bounded by the next binding VA).

**Recovery ceiling: 87/87. CONFIRMED.** The map's §8.8 "forcing-script pass" is unnecessary; its
§3 legend "○ = binding-only, no static caller" is accurate as a *Ghidra* statistic and misleading as
an availability statement. The map's own §7.8 — *"Do not implement the 24 binding-only cfuncs from
their names"* — was the right call for the wrong reason: the bodies were always readable.

| cfunc | size | container(s) — **now named** | what it actually does |
|---|--:|---|---|
| `IsAlive` (139 calls) | 297 B | `RuntimeHealth`, `Health`, `SceneObject` | `cur > 0.01` **and** a bit on `SceneObject+0x1A` |
| `HasLabel` (117) | 218 B | `Label` | `FUN_00649440(guid, hash)` multi-key probe → bool |
| `GetHealth` (48) | 298 B | `RuntimeHealth`, `Health`, `SceneObject` | reads `[rec+4]` = **current** |
| `DisablePhysics` (29) | **16 B** | — | `FUN_005D0650(guid, 0)` |
| `GetName` (13) | 228 B | `Name` (probes `Name+0x34`) | forward index probe |
| `GetMaxHealth` (12) | 234 B | `RuntimeHealth`, `Health` | reads `[rec+0]` = **max** |
| `Revive` (12) | 427 B | `RuntimeHealth`, `SceneObject`, `HumanStateMachine` | writes `[rec+4]`, **clears `SceneObject+0x1A` bit 0** |
| `EnablePhysics` (11) | **16 B** | — | `FUN_005D0650(guid, 1)` |
| `InSeat` (6) | 210 B | `RiderLink` (probes `RiderLink+0x50`) | **reverse** index probe |
| `IsHibernated` (5) | 186 B | `SceneObject` | `setne` on a field |
| `GetMass` (5) | 218 B | — | physics-body vtable only |
| `GetPhysicsType` (3) | 1128 B | `_BoatPhysics`, `_HumanPhysics`, `_CarPhysicsV2`, `_TankPhysics`, `_HelicopterPhysics` | switch over 5 physics pools |
| `StopAllAnimation` (3) | 142 B | `BoneControllerRuntime` | |
| `InVehicle` (2) | 299 B | `RiderLink` | |
| `IsValid` (2) | 132 B | **none** | pure Lua tag check (see below) |
| `DetachCargoFromWinch` (7) | 137 B | `PhysicsActorWinch` | |
| `HasWinch` (0) | 165 B | `PhysicsActorWinch` | `setne` |
| `IsWinching` (0) | 183 B | `PhysicsActorWinch` | |
| `IsTemplate` (1) | 135 B | none | `setl` on `guid < 0` |
| `IsDisguised` (1) | 259 B | `Players` | `[player+0x438] & 2` |
| `GetCashValue` (1) | 171 B | `CashValue` | |
| `RemoveQualityRef` (1) | 181 B | none | resource-quality refcount |
| `GetModelName` (0) | 220 B | `ModelName` | |
| `RevertHibernationDistance` (0) | 390 B | `HibernationControl`, `SphereRegion`, `CircleRegion`, `LineRegion` | region-shape dispatch |

Two findings worth promoting out of that table:

- **`SceneObject+0x1A` bit 0 is the DEAD flag.** `GetHealth` tests `byte[rec+0x1A] & 1`, `IsAlive`
  reads the same byte, and `Revive` does `and byte ptr [rec+0x1A], 0xFE` — clearing it. So "alive"
  is *not* purely `health > 0`; there is an explicit death latch, and `Object.Revive` clears it.
  The health threshold constant is `[0x00B97EEC] = 0.01f`, not zero.
- **`Object.IsValid` is a Lua type check, not an engine liveness query.** Its complete engine
  footprint is nil: it accepts tag 2 (lightuserdata) or tag 7 (table) and pushes a boolean. A reimpl
  that makes `IsValid` ask "does this entity exist?" diverges from retail. The map claims nothing
  about it (correctly), but §7's build guidance does not warn about it either.

### P5. The remaining specific items

#### P5.1 `FUN_00424770` is **not** a frustum test — CLOSED

The map calls `IsVisible` a "frustum/occlusion query"; pass 1 rated that "plausible and unfalsified,
not proven". Read in full it is neither a frustum nor a plane test:

```
00424770  xorps xmm0, xmm0                  ; acc = 0.0
00424780  cmp  [ebp], esi / jle done        ; n = list count
00424790  lea  edi, [ebp + 0x10]            ; items
00424793  mov  eax, [ebx] / mov edx, [eax+4]; virtual method at vtable +0x04
00424799  fstp dword ptr [esp]              ; push acc as an argument
0042479F  call edx
004247A1  fst  dword ptr [esp + 0x18]       ; acc = returned float
004247A8  add  edi, 0x50                    ; next item (0x50 stride)
004247AB  cmp  esi, [ebp] / jl loop
```

It is an **accumulator fold**: `acc = 0; for each of n items (0x50 stride): acc = obj->vf04(item,
acc); return acc`. `IsVisible` then compares the result against `[0x00BEB528] = 0.0005f` and
returns false if below. A frustum test returns a boolean or a signed plane distance; it does not
fold a float across a list and threshold at 5·10⁻⁴.

**Verdict: a fractional coverage / occlusion-accumulation metric, thresholded at 0.05 %.** The map's
"occlusion" half is right; its "frustum" half is **CONTRADICTED**. `IsVisible` is best described as
*"is at least 0.05 % of this object visible?"* — which also explains its `word[+0x18] & 0x3000 ==
0x2000` pre-gate returning **true** for objects outside the tested class.

#### P5.2 `FUN_0064A5C0` resolved — SecuROM is not a blocker

Pass 1: *"`FUN_0064A5C0` is a SecuROM split-thunk (`jmp dword ptr [0x02458A98]` → `0x024EFA10`,
inside `.securom`) and is **not statically resolvable in this dump**."* It is resolvable, in three
derefs, exactly as [[securom-decompiled-not-a-blocker]] says:

```
0064A5C0  jmp dword ptr [0x2458a98]        ; slot already resolved in this memory dump
[0x02458A98] = 0x024EFA10
024EFA10  push 0x24efa2a                   ; outer return
024EFA15  push 0x406967                    ; inner return
024EFA1A  push 0x1ab7ff8
024EFA1F  pushfd
024EFA20  sub  dword ptr [esp + 4], 0x80e8 ; 0x1AB7FF8 - 0x80E8 = 0x01AAFF10
024EFA28  popfd
024EFA29  ret                              ; -> transfers to 0x01AAFF10
```

That is SecuROM's arithmetic-return obfuscation, not encryption. **The real target is
`0x01AAFF10`**, inside `Stext` (VA `0x01A49000`–`0x02084000`) — a section the export already
covers. It chains once more through `jmp dword ptr [0x21FD554]`, and the adjacent stub
`mov dword ptr [eax+0xc], 0x50` is visible in clear.

I did **not** fully decode the final body, so I am not claiming what the fallback record *is*. But
pass 1's stated reason for stopping — "not statically resolvable in this dump" — is **CONTRADICTED**;
the correct status is "resolvable, not yet walked to the end". That distinction matters because it
was pass 1's justification for a runtime item.

#### P5.3 Transform record CONFIRMED — and the quaternion is now PROVEN

`FUN_00665AF0`, read in full, matches the map **verbatim**:

```
00665AF6  mov  ecx, 0xdf9c90               ; RuntimeSceneObject
00665AFD  call 0x6496b0                    ; probe + alias
00665B06  [0xdf9cd8]=+0x48  [0xdf9cb0]=+0x20  [0xdf9cb6]=+0x26  [0xdf9cb4]=+0x24  [0xdf9d00]=+0x70
00665B38  fld [eax] / fstp [esi]           ; dword 0
00665B3F  fld [eax+4] / fstp [esi+4]       ; dword 1
00665B45  fld [eax+8] / fstp [esi+8]       ; dword 2
00665B4B  movq [eax+0x10] -> [esi+0x10]    ; dwords 4,5
00665B55  movq [eax+0x18] -> [esi+0x18]    ; dwords 6,7
00665B5F  eax=[eax+0x0c]; ecx=[esi+0x0c]; if(ecx>eax) eax=ecx; eax+=1; [esi+0x0c]=eax   ; ★ serial
```

- **8 dwords, dword `[3]` skipped by the copy and instead max-merged + incremented** — the map's
  `out[3] = max(rec[3], out[3]) + 1` is right to the operator. **CONFIRMED.**
- All five container offsets the map cites are exact. **CONFIRMED.**
- **The quaternion is no longer an inference.** `Object.GetYaw` calls `FUN_00823BC0` on
  `out + 0x10` — precisely dwords `[4..7]` — and that function is the textbook quaternion→yaw:

```
00823BC6  load q = { x=[+0], y=[+4], z=[+8], w=[+0xC] }
00823BD9  xmm5 = x²+y²+z²+w²                       ; squared norm
00823C01  xmm4 = 2.0 / xmm5                        ; [0x00B92874] = 2.0f   -> s = 2/‖q‖²
00823C1B  xmm2 = 2(xz + yw)/‖q‖²
00823C2E  xmm0 = 2(z² + w²)/‖q‖² − 1.0
          -> atan2(xmm2, xmm0)
```

`2(z²+w²) − 1 ≡ 1 − 2(x²+y²)` for a unit quaternion, so this is exactly
`yaw = atan2(2(xz + yw), 1 − 2(x² + y²))` — rotation about **Y**. `GetYaw` then scales by
`[0x00BEAB1C] = 57.29583` = 180/π, confirming the map's radians↔degrees claim to 7 significant
figures.

> **VERDICT: dwords `[4..7]` are a quaternion `(x, y, z, w)` with `w` last.** The map's **M** is
> promoted to **proven**. A `2/‖q‖²` normalization factor and the exact Shoemake yaw terms cannot
> coincide with four arbitrary floats.

Two refinements the map does not have:
1. The `RuntimeSceneObject` record is **56 bytes**, not 32. `FUN_00665AF0` copies 32 of them;
   `+0x20…+0x37` is untouched by the transform read.
2. The map says the slow path produces a transform "from the world object". It is
   `mov ecx, 0x17c02d8` → the **`SceneObject` component** (id `0x13A`, stride 28) → `FUN_00434F80`.
   Named, not a world singleton.

#### P5.4 `FUN_00649180` and the cursor pool — CONFIRMED

`FUN_00649180`: `[ebx+0x1c]` capacity vs `[ebx+0x18]` live count, grow via `FUN_00649060`, vtable
`+0x50` page alloc, `+0x54` copy-construct, `+0x58` on-add, `[ebx+0x18] += 1`,
`cmp byte ptr [0xcfb58a], 0` gating `call 0x665590` — **every element of the map's §1.4 confirmed**,
including the `DAT_00CFB58A` cross-registration hook. The two index inserts go through
`FUN_00648CB0` twice, once per hash index (`+0x34`, then `lea esi,[ebx+0x50]`) — consistent with
P1.3.

`FUN_006499F0` (cursor init): critical section `0xEDBAA4` ✓, free-list head `0xEDBAC0` ✓, pop via
`[edi+0x18]`, refcount `[edi] += 1`. **The map's §1.5 is confirmed field-for-field**, and the third
argument is now explained: it selects **which hash index** to iterate (`+0x34` vs `+0x50`).

#### P5.5 `IsPlayerControlled` — CONFIRMED, with two corrections

Every global the map cites resolves: `[0xDF9BA8]` = `Players+0x18` (live count), `[0xDF9BB0]` =
`+0x20` (mask), `[0xDF9BB4]` = `+0x24` (stride, read `movsx word` — an i16, as the map says),
`[0xDF9BB6]` = `+0x26` (shift), `[0xDF9C00]` = `+0x70` (page table); `[0xDF81CC]` = `SeatLink+0x44`,
`[0xDF81EC]` = `SeatLink+0x64`. `mov eax, [eax + 0x24]` reads `player+0x24`. **All CONFIRMED.**

Corrections:
1. **It joins two containers, not three** — `Players` (id `0x138`) and `SeatLink` (id `0x7C`). The
   map's "three" counts three *probes* (an initial `Players` probe, the `Players` scan, then
   `SeatLink`), not three containers.
2. Both probes target the **second** hash index: `esi = 0xDF9BE0` = `Players+0x50` and
   `esi = 0xDF81D8` = `SeatLink+0x50`. The map does not distinguish the indexes.

#### P5.6 `CheatInfiniteAmmo` — the map's framing is wrong, and so is pass 1's

The container is named `CheatInfiniteAmmo`. That alone retires the map's §6.9 conclusion that it is
"a per-entity flag/marker container that at least two unrelated features share" and that naming it
after `SetInfiniteAmmo` was "overreach". **The engine's own name is the cheat.** The map retracted a
correct name for the wrong reason.

The writes are **cheat-gated**, which neither the map nor pass 1 records:

```
Object.SetInfiniteAmmo  0x005CE7E0:
  005CE86D  cmp byte ptr [0x1175f5c], 0     ; <-- cheat flag
  005CE87C  call 0x6cdaf0 / mov eax,[eax+0x20]   ; player's character guid
  005CE89D  push 0xdf9b10 / call 0x649180        ; insert byte 1
  005CE8B7  vtable +0x64 erase                    ; on false

player attach     0x006A4060:
  006A414F  cmp byte ptr [0x1175f5c], 0
  006A4156  jne 0x6a4161                    ; \  DAT_01175F5C || DAT_01175F59
  006A4158  cmp byte ptr [0x1175f59], 0     ; /
  006A415F  je  0x6a417c                    ; skip the insert entirely
  006A4172  mov byte ptr [esp+0x23], 1
  006A4177  call 0x649180
```

So the player-attach insert is gated on **`DAT_01175F5C || DAT_01175F59`** — a bank of cheat toggles
at `0x01175F59..0x01175F5C` (the attach path also tests `0x1175F5A` and `0x1175F5B` nearby). This
reframes pass 1's B5 hazard: the "player path silently revokes a script-installed
`SetInfiniteAmmo`" scenario requires the cheat flags to be live in the first place. It is a
**cheat-system interaction, not a general entity-marker collision**.

`docs/reverse_engineer/player_code_map.md` already names this container `CheatInfiniteAmmo` by the
same `[vtable+0x34]` method. The core map's §6.9 and §8.11 are **stale relative to its own sibling**.

#### P5.7 `Kill` message shape — pass 1's contradiction upheld

`0x005CDEC0` writes `[esp+0xc] = guid`, `[esp+0x10] = 0`, `[esp+0x14] = 0`, `[esp+0x18] = 0`,
`[esp+0x19] = 0`. The map's `{guid, guid, 0, 0, 0, 0}` has the second field wrong. Ring vs
drop-newest: also upheld — `cmp eax, 0x400 / jge` jumps straight to `LeaveCriticalSection`, no
modulo anywhere.

#### P5.8 `AddToDisposer` — pass 1's "OVERSTATED" upheld

`AddLabel` `0x005CE900` is variadic and pushes a boolean; `AddToDisposer` `0x005D2900` takes one
GUID, returns 0 values, and makes an extra `FUN_004F3D30` call. §4.3 is precise; §7.5's
`AddToDisposer == AddLabel(guid,"disposable")` is not. Confirmed.

### P6. Script call-site counts — CONFIRMED exactly

Pass 1 marked these "outside this pass's evidence base. Unverified either way." A full regex census
over the Lua corpora (word-boundary-correct, so `GetVelocity` does not absorb
`GetVelocitySquared`/`GetVelocityVector`) reproduces the map's numbers **exactly**:

| | claimed | measured |
|---|--:|--:|
| total across 87 names | 1272 | **1272** ✅ |
| names with 0 call sites | 18 | **18** ✅ |
| `GetPosition` | 201 | **201** ✅ |
| `IsAlive` · `HasLabel` · `Remove` · `IsPlayerControlled` | 139 · 117 · 83 · 74 | **all exact** ✅ |
| `GetYaw` · `GetHealth` · `SetInvincible` · `Kill` · `DisablePhysics` | 50 · 48 · 35 · 29 · 29 | **all exact** ✅ |
| `SetInfiniteAmmo` · `SetTransformToObject` · `GetLocalizedName` · `SetPosition` · `FadeOut` | 28 · 28 · 25 · 23 · 21 | **all exact** ✅ |
| `IsAwake` · `GetParent` · `CloseGate` · `GetModelName` · `AreEqual` | 17 · 17 · 15 · 0 · 0 | **all exact** ✅ |

All 20 spot-checks and the total verify. **The map's traffic table is sound**, and so is §3's
"805 of 1272 (63 %)" top-ten figure.

One provenance correction: the corpus that yields 1272 is `docs/mercs2-luacd/src/` (**1056**) **plus**
`docs/mercs2-dlc-luacd/src/` (**216**). The map's §9 says "`corpus_calls` over `docs/mercs2-luacd/`
(370 scripts)" — that directory alone gives 1056. `object.rs`'s header comment carries the same
error. The numbers are right; the stated source is incomplete.

**New finding — an 88th name that is not in the table.** Three `Object.<X>(` names appear in script
that are **not** among the 87: `GetInfiniteAmmo` (2 sites), `GetPos` (1), `Delete` (1). The first is
live logic in the DLC PDA (`docs/mercs2-dlc-luacd/src/dlc01/dlc01_mrxguipda.lua`), and it is
**feature-guarded**:

```lua
132    L0_2 = Object.GetInfiniteAmmo
133    if not L0_2 then return end          -- bails when the binding is absent
510    L2_2 = Object.GetInfiniteAmmo
511    if L2_2 then L2_2 = Object.GetInfiniteAmmo(L0_2) end
```

The retail PC table at `0x00B99608` has no such entry (87 confirmed twice, terminator at
`0x00B998C0`), and no document in the corpus records a DLC-extended `Object` table. The guard means
the DLC was authored against a build that had the getter and degrades silently on retail PC. Its
container is now pinned: `CheatInfiniteAmmo`, stride 1, cap 128 — exactly the shape a `Get`/`Set`
pair wants. **This is a fix-pack candidate** (a PDA cheat toggle that cannot read its own state).


### P7. Health layout — adjudicated, with a third field neither document has

Re-derived independently this pass from `0x017BEF78` = **`RuntimeHealth`** (id `0x0EA`, hash
`0xF9B9B2A5`):

| cfunc | instruction | reads/writes |
|---|---|---|
| `GetMaxHealth` `0x005CC030` | `movss xmm0, dword ptr [eax]` | **`+0x00`** |
| `GetHealth` `0x005CBDB0` | `movss xmm0, dword ptr [eax + 4]` | **`+0x04`** |
| `SetHealth` `0x005CBEE0` | `comiss xmm0, [esi]` … `movss [esi + 4], xmm0` | clamps to `+0x00`, writes `+0x04` |

> **VERDICT: `{ +0x00: f32 max, +0x04: f32 current }`.**
> `object_entity_core_code_map.md` §5.1 is **CONFIRMED**.
> `docs/modernization/object_assembly_model.md` §2's `RuntimeHealth (0xf9b9b2a5, {cur,max})` has the
> two fields **swapped and should be corrected**. Three mutually-corroborating readings, no
> breakpoint. The map's §8.6 is **closed**.

**But both documents are incomplete.** The container's descriptor stride is **12 bytes**, not 8.
`{max, current}` accounts for `+0x00`–`+0x07`; **`+0x08` is a third field that neither document
records and that this pass did not identify.** I am not guessing at it — 73 `.text` sites reference
`0x017BEF78` and a proper sweep of them is its own task. Recording it as a new open item rather than
letting a two-field layout stand as complete.

`GetNodeHealth`: `mov ecx, 0x17befc8` → **`RuntimeNodeHealth`** (id `0x0EB`, hash `0x76927BF5`,
stride **4**) → `mov edi, [eax]` (an embedded pointer) → `FUN_00435140(nameHash)` →
`movzx eax, word ptr [eax + 6]` → `cvtsi2ss`. An **integer** widening, so the node field cannot be a
float reinterpretation. §5.2 **CONFIRMED**; `object_assembly_model.md`'s "one **float** per
destructible node" is wrong on storage. Note the container stride of 4 is consistent: the container
holds a 4-byte handle per entity, and the per-node `u16`s live in the pointed-to node table — so
"one value per destructible node" is right about *cardinality* and wrong about *type and location*.

### P8. The documentation join

**`docs/mercs2-ecs/` — 152/152 hash agreement, and zero coverage of array B.**

- The 9 family `.md` files carry 153 name→hash pairs. 152 join to this census and **every one agrees
  on the hash exactly**. The single non-joiner (`Status 0x09CD8B1F`) is one of the bogus rows the
  README itself already flags as "a script object, not a component". Strides agree everywhere
  sampled. This is a very strong independent validation of the extraction — and, symmetrically, of
  `docs/mercs2-ecs/`.
- `_registry_raw.tsv` covers **array A only**. Its 232 rows are **218 real array-A entries** (217
  correct + `TerrainGuidMappingHighResToLowRe`, merely **truncated** to 31 chars, not bogus) plus
  **14 bogus rows** pointing outside array A entirely — `Status`, `Update`, `WpMeshShape`, the eight
  D3D9 precache globals (`vertex vshader pshader display surface texture vertdecl index`), and
  `failresolve`/`finalize`/`potential`, which are **three rows sharing one address**
  (`0x01175E30`, the phase-string global). It **misses 14 real array-A names**: `Ai`, `Road`,
  `Rope`, and all eleven underscore-prefixed `_*Physics` classes.
  *(Correction to my own earlier count of 15/15 — the truncated row is recoverable, so it is 14/14.)*
- **Coverage of array B is exactly zero.** Word-grepping all 102 array-B names across every file
  under `docs/mercs2-ecs/` yields three hits, all English-word coincidences (`Name` in a table
  header, `Flags` as a verb, `Rider` in a prose heading). `_manifests/*.tsv` is a pure partition of
  `_registry_raw.tsv`, so also array A only.
- README states "**~220 component classes**" and "232 raw registrations". **The true total is 334.**
  No file under `docs/mercs2-ecs/` states a total near 334 or describes the two-array split.
- Telling detail: `docs/game_config/cdbsizes.ini` **already budgets array-B components by name**
  (`SceneObject`, `RuntimePhysicalLink`, `Flags`, `SeatLink`, `EntranceLink`, `NodeHealth`, `Name`,
  `ModifierKey`, `Label`, `ModelName`, `CheatInfiniteAmmo`…). The budgets file had them all along;
  the registry extractor simply never walked their array.

**`docs/ecs_components.md`** — a *serialized-record* doc, not a registry doc. 23 of its 26 names are
in the census; 12 strides agree exactly under its `payload = stride` convention. Three disagreements
worth adjudicating: `DestructionLink` (doc payload 16 vs stride **12**), `PhysicalLink` (44 vs
**40**), `LandingZone` (272 vs **8**, cap 32 — a 34× gap, most likely an 8-byte handle into a
separately-allocated zone struct). Three of its names are **not** containers — `Transform`,
`VehicleWeakPoint`, `TreeLeaves` — consistent with the doc's own statement that the latter two come
from `vz_state` COMP *definitions*. Its one hashed component, `PointLocation 0x60B7ABE0`, **agrees
exactly**, and three of its "unknown component" hashes are now resolved: `0x4E2B6C54` =
`AnimationResponse`, `0x69567E62` = `BoneCtrlTentacle`, `0x2E2659F0` = `PhysicsDefaultActivator`.
Its open item *"RuntimeLayerId — not found as an explicit ASCII string"* is resolved: id 255,
`0x017BF478`, hash `0x2284FE19`, stride 4.

**`docs/modernization/object_assembly_model.md`** — all four of its component hashes verify exactly
(`Health 0x06BE1ABF`, `RuntimeHealth 0xF9B9B2A5`, `RuntimeNodeHealth 0x76927BF5`,
`Model 0x5B724250`, the last with its "4-byte handle" claim confirmed by stride 4). Its "**~231
component types**, each = a 0x50-byte descriptor" is an undercount and a wrong universal: **334
types, of which 102 are 0x80-byte**. Its "name registry `@0xDF6B88`" is really component **#1
`Name`**, which also happens to be the base of array B — the `0x9E3779B9` bucket function it
describes is the generic probe all 334 containers share, not a bespoke registry.

**Sibling-map boundary claims tested (as claims, not evidence):**

| claim | source | verdict |
|---|---|---|
| `0x00DF9C90` is "the Transform container" | core map §0, §0.5 | **CONTRADICTED** — it is `RuntimeSceneObject`; no `Transform` container exists in either array |
| `0x00DF9B10` is an unnamed shared marker | core map §6.9 | **CONTRADICTED** — `CheatInfiniteAmmo`; `player_code_map.md` already had this |
| `~231`-class registry | `ecs_reflection_registry_code_map.md` §6 | **CONTRADICTED** — 334; it censused array A only |
| `flags & 8` = the class taxonomy | `ecs_reflection_registry_code_map.md` §0.5 | **partially wrong** — it is the *registry* split (116/218) and is **orthogonal** to the A/B container split (232/102) |
| `FUN_005857E0(param_1)`, `param_1` = "the object/entity" | `ecs_reflection_registry_code_map.md` §4.5 | **CONTRADICTED** — `param_1` is the **container**; `+0x24` is the container's record stride |
| `FUN_0064A770`, `FUN_0064A7E0`, both registry arrays, both counters, `[vtable+0x34]` name accessor | `ecs_reflection_registry_code_map.md` §0.5, §2.1, §2.2 | **CONFIRMED, all of it** — that map already had the master key; it simply never applied it to array B |
| `player_code_map.md` §2.1 `FUN_006496B0` "guid → dense slot" | corrected by core map §1.3 | core map's correction **CONFIRMED** |

### P9. STILL-OPEN — with proof of static exhaustion and a runtime recipe

Four items, each with what was actually tried.

**P9.1 — Does anything set `player+0x24` to NON-ZERO?**
*Static work done.* Byte-scanned all of `.text` for `mov [reg+disp8=0x24], reg` (976 sites), filtered
to those whose ±0x300 window carries the player-struct fingerprint (`0x00DF9B90` or offset `0x3A8`)
→ **25 candidates**, all read. Results: `0x006A4279` (`FUN_006A4060`) writes `edi`, which is provably
**0** — `xor edi, edi` at `0x006A417C` with no non-zero reload on the path — so the map's
"clear-on-attach" is CONFIRMED. `0x0069FEA7` is the player-struct **constructor** zeroing it. The
one genuine candidate is:

```
006AA7C0  ; __thiscall, esi = [esp+0x34] (arg), resolves EntranceParameters (id 0x7F)
006AA805  cmp eax, dword ptr [esi + 0x20]     ; compares against +0x20 — the player-struct pair
006AA893  mov dword ptr [esi + 0x24], ecx     ; ecx = [esp+0x28], a NON-ZERO argument
```

The `+0x20`/`+0x24` pairing and the `EntranceParameters` resolve make this the vehicle/seat-entry
setter on shape. **Why it cannot be closed statically:** `FUN_006AA7C0` has **zero static callers**
— a byte-scan for `call rel32` targeting it returns nothing, because it is a **virtual method**
(trap 3). Whether its `esi` is the player struct is decided at the indirect call site.
*Runtime recipe:* HW-write watchpoint on `player+0x24` (player base via `FUN_006CDAF0(0)`), then
drive into a vehicle; when it fires, walk the call stack — expect `0x006AA893`. Read-only while
PAUSED; the USER drives execution ([[x32dbg-mcp-no-resume]]).

**P9.2 — `FUN_0064A5C0`'s final body / the miss-path fallback record.**
Pass 1's "not statically resolvable" is **CONTRADICTED** (P5.2): the chain
`0x0064A5C0 → [0x02458A98] = 0x024EFA10 → arithmetic-return → 0x01AAFF10` is fully walkable, and
`0x01AAFF10` is in `Stext`, which the export covers. I stopped at one further indirection
(`jmp dword ptr [0x21FD554]`). This is **unfinished, not blocked** — the honest status. Not needed
for any verdict here, since `FUN_00423DC0` already establishes the `+0x7C` shared zero record.

**P9.3 — `RuntimeHealth+0x08`.** The record is 12 bytes; `+0x00` and `+0x04` are settled, `+0x08` is
unidentified. 73 `.text` sites reference the container. Static, tractable, not attempted here.

**P9.4 — Record *contents*.** Capacity, stride, shift and page-mask are static (P3) and are now all
extracted. What remains genuinely runtime-only is the **allocated page memory** — live record counts
(`+0x18`), page-table pointers (`+0x70`) and the records themselves are zero in the image because
pages are heap-allocated on first insert. Claims about *record payloads* (e.g.
`object_assembly_model.md`'s "value bit-31 = template handle" for `Name` records) remain runtime
questions. This is the residue of pass 1's B8 item 1 that survives — a much smaller residue than
pass 1 claimed.

### P10. Verdict deltas against Pass 1

| Pass-1 verdict | Pass-2 |
|---|---|
| 4 CONTRADICTED (#10b, #17, #18a, §0) | **all 4 upheld** |
| 1 OVERSTATED (#11b) | **upheld** |
| 1 TERMINOLOGY WRONG (#10a "ring") | **upheld** |
| 2 UNDER-CLAIMS (#19a, §8.2) | **both closed** — ceiling 87/87 (24 bodies read); 55 cfuncs → 33 named containers |
| 1 MISSING (array A) | **closed** — both arrays fully enumerated and named |
| B8: "capacity/stride/page table all zero statically" | **CONTRADICTED** — statically present for all 334; `cap == 2^shift` verifies 334/334 |
| B8: `FUN_0064A5C0` unresolvable | **CONTRADICTED** — resolved to `0x01AAFF10` |
| B8: `FUN_00424770` frustum "plausible" | **CLOSED** — not a frustum test; a coverage fold thresholded at 5e-4 |
| B8: type-id space shared? | **SETTLED** — one space, by arithmetic **and** by mechanism |
| B8: "named 19 of A and ~9 of B; §8.1 remains open" | **CLOSED** — all 334 named |
| B8: script call counts unverified | **CONFIRMED exactly** (1272 / 18 zeros / all 20 spot-checks) |
| B8: Transform record, `FUN_00649180`, cursor pool, `IsPlayerControlled`, `player+0x24` | **all re-derived**; Transform CONFIRMED + quaternion **proven**; `IsPlayerControlled` joins **two** containers, not three; `player+0x24` narrowed to one instruction |

**New defects found in the map that pass 1 did not report:** the `Transform` container misnaming
(§0, §0.5); the `CheatInfiniteAmmo` retraction being itself wrong (§6.9) and stale relative to
`player_code_map.md`; the `IsVisible`/"frustum" mischaracterization (§6.4); "three containers" in
§6.8; the §9 provenance omitting `docs/mercs2-dlc-luacd/`; and `Object.IsValid` being a pure Lua tag
check with no warning in §7.

### P11. Complete container census — all 334, joined

`arr` A = `0x017BBF58` + n·`0x50` · B = `0x00DF6B88` + n·`0x80`. `id` is the engine type id at
`container+0x06`. `name` is `[vtable+0x34]`. `hash` is `pandemic_hash_m2(name)`, matching the
engine's own `FUN_0064A7E0`. `stride`/`cap` are the static descriptor fields (`cap == 2^shift`
verified for every row).

| id | arr | VA | name | name-hash | stride | cap |
|--:|:-:|---|---|---|--:|--:|
| 1 | B | `0x00DF6B88` | `Name` | `0x1DE5C824` | 4 | 256 |
| 2 | B | `0x00DF6C08` | `ModelName` | `0x5CF81991` | 4 | 256 |
| 3 | B | `0x00DF6C88` | `Path` | `0xBCFE6314` | 4 | 256 |
| 4 | B | `0x00DF6D08` | `Flags` | `0x3CE51772` | 32 | 256 |
| 5 | A | `0x017BBF58` | `Health` | `0x06BE1ABF` | 8 | 256 |
| 6 | B | `0x00DF6D88` | `PhysicalLink` | `0x7FBCE14E` | 40 | 256 |
| 7 | B | `0x00DF6E08` | `DestructionLink` | `0xBCE6FAD7` | 12 | 256 |
| 8 | B | `0x00DF6E88` | `Rotor` | `0x045CF1FB` | 28 | 128 |
| 9 | B | `0x00DF6F08` | `BoneCtrlLookAt` | `0xD7AA0796` | 16 | 256 |
| 10 | B | `0x00DF6F88` | `BoneCtrlRotationCopy` | `0x530F1DF9` | 28 | 64 |
| 11 | B | `0x00DF7008` | `BoneCtrlFakeWheel` | `0x31F592F4` | 24 | 256 |
| 12 | B | `0x00DF7088` | `MaterialCtrlTankTread` | `0xDCB942BF` | 24 | 64 |
| 13 | B | `0x00DF7108` | `BoneCtrlLocalRotation` | `0xA2B8C2AF` | 36 | 64 |
| 14 | B | `0x00DF7188` | `BoneCtrlLocalTranslation` | `0x99BA2DF2` | 40 | 16 |
| 15 | B | `0x00DF7208` | `BoneCtrlTentacle` | `0x69567E62` | 56 | 64 |
| 16 | B | `0x00DF7288` | `BoneCtrlStrapOn` | `0x64E7D6F9` | 140 | 256 |
| 17 | B | `0x00DF7308` | `BoneCtrlJostle` | `0xF328AA09` | 68 | 8 |
| 18 | B | `0x00DF7388` | `BoneCtrlWind` | `0x5A24921A` | 48 | 32 |
| 19 | A | `0x017BBFA8` | `BoneCtrlPhysicsActor` | `0x1AFAED2A` | 4 | 256 |
| 20 | A | `0x017BBFF8` | `InitialVelocity` | `0x6537A65A` | 48 | 256 |
| 21 | B | `0x00DF7408` | `PhysicsPropertyCrashable` | `0x367708CC` | 12 | 256 |
| 22 | A | `0x017BC048` | `PhysicsPropertyFakeContinuous` | `0x639F9491` | 4 | 32 |
| 23 | A | `0x017BC098` | `PhysicsPropertyUncrushable` | `0xA61BD97B` | 4 | 16 |
| 24 | A | `0x017BC0E8` | `PhysicsPropertyGravityScaler` | `0x841BA027` | 4 | 32 |
| 25 | A | `0x017BC138` | `_PropPhysics` | `0xB03943A2` | 16 | 256 |
| 26 | A | `0x017BC188` | `_DebrisPhysics` | `0x3E1EF7C4` | 12 | 256 |
| 27 | A | `0x017BC1D8` | `_BoatPhysics` | `0xD05CF17D` | 276 | 32 |
| 28 | A | `0x017BC228` | `_HumanPhysics` | `0x73790892` | 132 | 128 |
| 29 | A | `0x017BC278` | `_CarPhysicsV2` | `0xD1DE7E4D` | 396 | 256 |
| 30 | B | `0x00DF7488` | `_CarWheel` | `0x2A98060F` | 20 | 256 |
| 31 | A | `0x017BC2C8` | `_TankPhysics` | `0x537E1C8F` | 120 | 64 |
| 32 | A | `0x017BC318` | `_HelicopterPhysics` | `0x493E1D4E` | 88 | 32 |
| 33 | A | `0x017BC368` | `_HelicopterPhysicsAi` | `0x95C0E57C` | 84 | 32 |
| 34 | A | `0x017BC3B8` | `_JetPhysics` | `0xC0AEF1E0` | 4 | 8 |
| 35 | A | `0x017BC408` | `_BuildingPhysics` | `0x75C70083` | 8 | 256 |
| 36 | A | `0x017BC458` | `TinyGeometryObject` | `0x06468E56` | 4 | 32 |
| 37 | A | `0x017BC4A8` | `_CollapsePhysics` | `0x2119DCE4` | 4 | 8 |
| 38 | A | `0x017BC4F8` | `PhysicsDefaultActivator` | `0x2E2659F0` | 1 | 64 |
| 39 | A | `0x017BC548` | `Winch` | `0x9C6B3368` | 44 | 32 |
| 40 | B | `0x00DF7508` | `Turret` | `0x01212327` | 68 | 256 |
| 41 | B | `0x00DF7588` | `Door` | `0x78CF19B9` | 40 | 256 |
| 42 | B | `0x00DF7608` | `DoorCoupling` | `0x64745818` | 16 | 256 |
| 43 | B | `0x00DF7688` | `PoweredGate` | `0x997A8E5E` | 12 | 32 |
| 44 | B | `0x00DF7708` | `ConnectPoint` | `0xFFF58A2D` | 8 | 256 |
| 45 | A | `0x017BC598` | `Rope` | `0x330B1105` | 28 | 8 |
| 46 | A | `0x017BC5E8` | `Buoyancy` | `0xB9659F7B` | 20 | 256 |
| 47 | A | `0x017BC638` | `ExplosionFudge` | `0x5AEABC23` | 4 | 64 |
| 48 | A | `0x017BC688` | `WeaponEffects` | `0xF24D2021` | 16 | 128 |
| 49 | A | `0x017BC6D8` | `WeaponRecoilVehicle` | `0x557E4B99` | 8 | 64 |
| 50 | A | `0x017BC728` | `WeaponBarrel` | `0x180E2B95` | 4 | 256 |
| 51 | A | `0x017BC778` | `WeaponProjectileBase` | `0xEB505C8B` | 40 | 128 |
| 52 | A | `0x017BC7C8` | `WeaponScatter` | `0xE7234615` | 28 | 256 |
| 53 | A | `0x017BC818` | `AiSkill` | `0xEBA09B1A` | 4 | 128 |
| 54 | A | `0x017BC868` | `AiPatrol` | `0xB0CA290D` | 24 | 256 |
| 55 | A | `0x017BC8B8` | `AiHelicopter` | `0x78EB1ADC` | 36 | 128 |
| 56 | A | `0x017BC908` | `AiDriving` | `0x67AB955C` | 8 | 256 |
| 57 | A | `0x017BC958` | `Squad` | `0x9788C501` | 4 | 16 |
| 58 | B | `0x00DF7788` | `SquadUnitLink` | `0x383DBB5F` | 4 | 16 |
| 59 | B | `0x00DF7808` | `SquadSource` | `0x0C641B52` | 4 | 16 |
| 60 | A | `0x017BC9A8` | `WeaponThrown` | `0x24870CFF` | 52 | 16 |
| 61 | A | `0x017BC9F8` | `WeaponTrigger` | `0xC526A637` | 8 | 16 |
| 62 | A | `0x017BCA48` | `WeaponUI` | `0xE5D5E31F` | 24 | 128 |
| 63 | A | `0x017BCA98` | `WeaponScope` | `0x27CA777F` | 20 | 16 |
| 64 | A | `0x017BCAE8` | `Explosive` | `0xF74044BA` | 36 | 32 |
| 65 | A | `0x017BCB38` | `ControllerVelocity` | `0xD61C71B4` | 24 | 64 |
| 66 | A | `0x017BCB88` | `ProjectilePhysics` | `0x11E6C283` | 40 | 128 |
| 67 | A | `0x017BCBD8` | `FlightNoise` | `0x10ED85AF` | 24 | 32 |
| 68 | A | `0x017BCC28` | `TriggerOnTimer` | `0xFB35CD6F` | 8 | 64 |
| 69 | B | `0x00DF7888` | `SpawnOnDeath` | `0x7D8A24A9` | 16 | 128 |
| 70 | A | `0x017BCC78` | `TimerResponse` | `0xC122D3ED` | 12 | 32 |
| 71 | B | `0x00DF7908` | `Pickup` | `0x8602E37D` | 28 | 256 |
| 72 | A | `0x017BCCC8` | `HumanAnimationSystem` | `0x27A3C8A9` | 52 | 128 |
| 73 | A | `0x017BCD18` | `HumanAnimationSet` | `0xE8F41716` | 8 | 128 |
| 74 | A | `0x017BCD68` | `VehicleAnimationSet` | `0x35E09A35` | 8 | 256 |
| 75 | A | `0x017BCDB8` | `Equipment` | `0xDAB653E7` | 32 | 32 |
| 76 | B | `0x00DF7988` | `EquipmentDock` | `0x95513516` | 28 | 256 |
| 77 | B | `0x00DF7A08` | `EquipmentLink` | `0x094E7D13` | 12 | 256 |
| 78 | B | `0x00DF7A88` | `AnimationResponse` | `0x4E2B6C54` | 20 | 64 |
| 79 | A | `0x017BCE08` | `CameraCarPreset` | `0x5D1F87EF` | 80 | 32 |
| 80 | B | `0x00DF7B08` | `CameraCarPresetLink` | `0x773B1B9B` | 8 | 256 |
| 81 | B | `0x00DF7B88` | `CameraHelicopter` | `0x9479F2E3` | 80 | 32 |
| 82 | B | `0x00DF7C08` | `CameraTurret` | `0xBC68F146` | 96 | 256 |
| 83 | B | `0x00DF7C88` | `CameraTank` | `0xCB5AC0E4` | 64 | 32 |
| 84 | A | `0x017BCE58` | `CameraShake` | `0x412D1576` | 16 | 128 |
| 85 | A | `0x017BCEA8` | `HumanCameraModifier` | `0x212FFCB2` | 56 | 64 |
| 86 | A | `0x017BCEF8` | `ControllerPlayer` | `0x6CA511B2` | 12 | 32 |
| 87 | A | `0x017BCF48` | `ControllerVehicle` | `0xBFB1AECB` | 4 | 16 |
| 88 | A | `0x017BCF98` | `ControllerCar` | `0xEEEA744D` | 4 | 64 |
| 89 | A | `0x017BCFE8` | `ControllerBoat` | `0x4F89A7C7` | 4 | 64 |
| 90 | A | `0x017BD038` | `ControllerTank` | `0x55BC62BD` | 4 | 32 |
| 91 | A | `0x017BD088` | `ControllerLW` | `0x1BB0A5BE` | 4 | 16 |
| 92 | B | `0x00DF7D08` | `ControllerTurret` | `0x25A79C5B` | 8 | 256 |
| 93 | B | `0x00DF7D88` | `ControllerWeapon` | `0x0CAE3C35` | 12 | 256 |
| 94 | B | `0x00DF7E08` | `WeaponCoupling` | `0x87F3C810` | 12 | 256 |
| 95 | B | `0x00DF7E88` | `TurretCoupling` | `0xD28FEA46` | 12 | 256 |
| 96 | A | `0x017BD0D8` | `ControllerHelicopter` | `0x495A0CEA` | 4 | 64 |
| 97 | A | `0x017BD128` | `ControllerLadder` | `0x964E010D` | 4 | 32 |
| 98 | A | `0x017BD178` | `HibernationControl` | `0xE18AFD65` | 6 | 256 |
| 99 | A | `0x017BD1C8` | `Ai` | `0xFB31F1EF` | 48 | 256 |
| 100 | A | `0x017BD218` | `AiBehavior` | `0xDECD8889` | 48 | 256 |
| 101 | A | `0x017BD268` | `Anchor` | `0xFA55F6BA` | 16 | 128 |
| 102 | A | `0x017BD2B8` | `Perception` | `0x3F6AB8F0` | 20 | 256 |
| 103 | A | `0x017BD308` | `Stimulus` | `0x06408D71` | 12 | 256 |
| 104 | A | `0x017BD358` | `StimulusModifier` | `0xB9388F0A` | 24 | 256 |
| 105 | A | `0x017BD3A8` | `Target` | `0xAFF6B246` | 4 | 64 |
| 106 | A | `0x017BD3F8` | `Alarm` | `0xBE65FDD0` | 4 | 32 |
| 107 | A | `0x017BD448` | `SocialUse` | `0x7E6BF93D` | 16 | 32 |
| 108 | A | `0x017BD498` | `ChatterSet` | `0x949A1E44` | 4 | 256 |
| 109 | A | `0x017BD4E8` | `SkirmishZone` | `0xFC5923AF` | 8 | 16 |
| 110 | A | `0x017BD538` | `SkirmishSpawnList` | `0xAFBA5846` | 24 | 16 |
| 111 | B | `0x00DF7F08` | `Relationship` | `0x321FEDC3` | 4 | 32 |
| 112 | B | `0x00DF7F88` | `Association` | `0x3B3CF882` | 4 | 256 |
| 113 | A | `0x017BD588` | `FactionMarker` | `0x9B98CB09` | 4 | 256 |
| 114 | B | `0x00DF8008` | `CoverHintOffset` | `0xE7375904` | 64 | 256 |
| 115 | A | `0x017BD5D8` | `VehicleDisguiseScale` | `0x8B3A2B88` | 12 | 256 |
| 116 | B | `0x00DF8088` | `AiHintNode` | `0xBE4DDF50` | 12 | 64 |
| 117 | A | `0x017BD628` | `FactionZone` | `0x67267CC1` | 4 | 16 |
| 118 | A | `0x017BD678` | `AiWaterZone` | `0xDF6533DE` | 4 | 16 |
| 119 | B | `0x00DF8108` | `Label` | `0x06DA8775` | 4 | 256 |
| 120 | A | `0x017BD6C8` | `LandingZone` | `0x2A20B640` | 8 | 32 |
| 121 | A | `0x017BD718` | `CashValue` | `0x564990C3` | 4 | 256 |
| 122 | A | `0x017BD768` | `LocalizedName` | `0xA49AFEC1` | 4 | 256 |
| 123 | A | `0x017BD7B8` | `FactionValue` | `0x8BFC69D6` | 4 | 64 |
| 124 | B | `0x00DF8188` | `SeatLink` | `0xECC4A256` | 8 | 256 |
| 125 | A | `0x017BD808` | `SeatParameters` | `0xA2D3AE72` | 20 | 256 |
| 126 | B | `0x00DF8208` | `EntranceLink` | `0x619FEE87` | 8 | 256 |
| 127 | A | `0x017BD858` | `EntranceParameters` | `0x70D05913` | 28 | 64 |
| 128 | B | `0x00DF8288` | `EntranceToSeat` | `0xF7E8B25B` | 12 | 256 |
| 129 | B | `0x00DF8308` | `SeatToSeat` | `0x574C208A` | 8 | 256 |
| 130 | B | `0x00DF8388` | `Rider` | `0x03F7D697` | 8 | 256 |
| 131 | B | `0x00DF8408` | `RiderLink` | `0x8C8A5803` | 12 | 256 |
| 132 | A | `0x017BD8A8` | `StateMachine` | `0x98A3661F` | 16 | 256 |
| 133 | A | `0x017BD8F8` | `Road` | `0xEA0F3AA3` | 40 | 256 |
| 134 | B | `0x00DF8490` | `RoadIntersectionHint` | `0xCBA80A4B` | 28 | 32 |
| 135 | A | `0x017BD948` | `IntersectionToIntersection` | `0xEB6DE962` | 8 | 256 |
| 136 | A | `0x017BD998` | `LaneData` | `0x6A08E327` | 64 | 128 |
| 137 | A | `0x017BD9E8` | `LaneZeroDirection` | `0x7CF73564` | 4 | 256 |
| 138 | A | `0x017BDA38` | `SphereRegion` | `0x4CA3FD52` | 4 | 32 |
| 139 | A | `0x017BDA88` | `PointLocation` | `0x60B7ABE0` | 36 | 64 |
| 140 | A | `0x017BDAD8` | `PopulationDensity` | `0x6FA2F9D4` | 28 | 64 |
| 141 | A | `0x017BDB28` | `DangerousBuilding` | `0x543977F7` | 4 | 256 |
| 142 | B | `0x00DF8510` | `PopulationSimpleSpawner` | `0x00891D0A` | 112 | 256 |
| 143 | A | `0x017BDB78` | `PopulationDynamicRoad` | `0xFFC5BAA5` | 12 | 32 |
| 144 | B | `0x00DF8590` | `PopulationList` | `0x0699BE8C` | 8 | 256 |
| 145 | A | `0x017BDBC8` | `PopulationFlow` | `0x322750EC` | 12 | 64 |
| 146 | A | `0x017BDC18` | `CircleRegion` | `0x6691B221` | 4 | 8 |
| 147 | A | `0x017BDC68` | `LineRegion` | `0x6310807F` | 4 | 128 |
| 148 | A | `0x017BDCB8` | `BoundaryData` | `0x5A59763F` | 4 | 256 |
| 149 | A | `0x017BDD08` | `PathData` | `0xAEF6F7B4` | 4 | 8 |
| 150 | A | `0x017BDD58` | `ObjectScript` | `0xD81512A1` | 8 | 256 |
| 151 | A | `0x017BDDA8` | `BuildingDestruction` | `0x17A5555B` | 24 | 32 |
| 152 | A | `0x017BDDF8` | `ParticleEmitter` | `0xE595AB2F` | 16 | 8 |
| 153 | A | `0x017BDE48` | `HumanInventory` | `0xE672296C` | 28 | 8 |
| 154 | A | `0x017BDE98` | `ObjectMaterial` | `0xC1F1F72F` | 4 | 32 |
| 155 | B | `0x00DF8610` | `MaterialMapping` | `0x49F0D0EC` | 8 | 256 |
| 156 | B | `0x00DF8690` | `ModifierKey` | `0x99C2B81F` | 8 | 256 |
| 157 | B | `0x00DF8710` | `ParticleKey` | `0x35EF2B84` | 8 | 256 |
| 158 | B | `0x00DF8790` | `SoundKey` | `0xAA54B95B` | 8 | 256 |
| 159 | A | `0x017BDEE8` | `SoundRuinKey` | `0xBC1F685D` | 4 | 8 |
| 160 | B | `0x00DF8810` | `DrivingKey` | `0x6BBE8E8F` | 8 | 8 |
| 161 | A | `0x017BDF38` | `DamageKey` | `0xEF41976F` | 4 | 256 |
| 162 | A | `0x017BDF88` | `TerrainKey` | `0x0868B0CD` | 4 | 256 |
| 163 | A | `0x017BDFD8` | `SoundEffect` | `0xB40954F5` | 28 | 256 |
| 164 | A | `0x017BE028` | `SoundAmbience` | `0x514CAD3A` | 20 | 32 |
| 165 | A | `0x017BE078` | `SoundInterior` | `0x05D1D9BA` | 12 | 8 |
| 166 | A | `0x017BE0C8` | `MusicSource` | `0xB52A3A81` | 8 | 32 |
| 167 | A | `0x017BE118` | `MusicRegion` | `0x79DCBE56` | 4 | 64 |
| 168 | A | `0x017BE168` | `MeleeCombatant` | `0xBF438E92` | 40 | 128 |
| 169 | A | `0x017BE1B8` | `TickDamage` | `0x8DEF82AD` | 16 | 256 |
| 170 | B | `0x00DF8890` | `NodeHealth` | `0xFEA92137` | 24 | 256 |
| 171 | A | `0x017BE208` | `BlobShadow` | `0x40349618` | 36 | 256 |
| 172 | B | `0x00DF8910` | `DebrisEffect` | `0x4EC11797` | 48 | 256 |
| 173 | B | `0x00DF8990` | `TreeFoliage` | `0x2A8A1456` | 32 | 32 |
| 174 | A | `0x017BE258` | `Flammable` | `0xD930020E` | 4 | 256 |
| 175 | A | `0x017BE2A8` | `Ignitor` | `0x37C12455` | 12 | 32 |
| 176 | A | `0x017BE2F8` | `ObjectHint` | `0x2A390A27` | 12 | 256 |
| 177 | A | `0x017BE348` | `WeaponHint` | `0xD390834A` | 52 | 128 |
| 178 | A | `0x017BE398` | `RedEffectComponent` | `0x60A13E3E` | 56 | 256 |
| 179 | A | `0x017BE3E8` | `EffectTemplate` | `0xABAA1F3C` | 4 | 256 |
| 180 | B | `0x00DF8A10` | `RedEffectTweak` | `0xAFABFD0F` | 8 | 32 |
| 181 | A | `0x017BE438` | `EffectAiOccluder` | `0x20E89C9D` | 4 | 64 |
| 182 | B | `0x00DF8A90` | `EffectModel` | `0x52DFAE51` | 12 | 64 |
| 183 | A | `0x017BE488` | `LightAnimation` | `0xBD5349F7` | 44 | 64 |
| 184 | A | `0x017BE4D8` | `FlareObject` | `0x9F3EBFBA` | 64 | 16 |
| 185 | A | `0x017BE528` | `ColorAnimation` | `0x2C9FB394` | 12 | 8 |
| 186 | A | `0x017BE578` | `ScaleAnimation` | `0x60E3D029` | 16 | 16 |
| 187 | A | `0x017BE5C8` | `Sticky` | `0x97870D10` | 4 | 16 |
| 188 | B | `0x00DF8B10` | `OSMParameter` | `0xE60A85D9` | 8 | 256 |
| 189 | B | `0x00DF8B90` | `OSMStateParameter` | `0x06613270` | 8 | 256 |
| 190 | B | `0x00DF8C10` | `ConstraintLink` | `0x5C694EE8` | 12 | 32 |
| 191 | B | `0x00DF8C90` | `DamageChunks` | `0x73839D40` | 40 | 32 |
| 192 | A | `0x017BE618` | `HomingWeapon` | `0x1A4DB6ED` | 24 | 64 |
| 193 | A | `0x017BE668` | `HomingProjectile` | `0xE81B2874` | 12 | 64 |
| 194 | A | `0x017BE6B8` | `HomingTarget` | `0xB9EA3B32` | 16 | 256 |
| 195 | B | `0x00DF8D10` | `BuildingCollapseAnim` | `0x57F0BC07` | 24 | 256 |
| 196 | A | `0x017BE708` | `ModelMixerProfile` | `0x1611C502` | 4 | 256 |
| 197 | A | `0x017BE758` | `Carryable` | `0x712AF756` | 4 | 8 |
| 198 | B | `0x00DF8D90` | `MaterialEmitter` | `0x8B80E30C` | 8 | 256 |
| 199 | B | `0x00DF8E10` | `AtmosphereBase` | `0xB8D2B506` | 740 | 32 |
| 200 | A | `0x017BE7A8` | `DisableDecals` | `0xFF4533E5` | 4 | 256 |
| 201 | A | `0x017BE7F8` | `Disable3DDecals` | `0x69A0E0E4` | 4 | 256 |
| 202 | B | `0x00DF8E90` | `DisableMaterialEffect` | `0x5A6DB5B7` | 20 | 8 |
| 203 | B | `0x00DF8F10` | `DisableDamageEffect` | `0x9FC02FAF` | 20 | 256 |
| 204 | A | `0x017BE848` | `GrappleParameters` | `0x6AC5EE26` | 28 | 64 |
| 205 | A | `0x017BE898` | `Ribbon` | `0x059B95B9` | 44 | 32 |
| 206 | A | `0x017BE8E8` | `SpeedLimit` | `0x9ADD960B` | 12 | 16 |
| 207 | B | `0x00DF8F90` | `EffectVelocityControl` | `0x96D18CFE` | 24 | 256 |
| 208 | A | `0x017BE938` | `MassiveComponent` | `0xF482C286` | 4 | 32 |
| 209 | A | `0x017BE988` | `Crusher` | `0x24463D8B` | 4 | 32 |
| 210 | B | `0x00DF9010` | `VehiclePart` | `0xC163F6F8` | 16 | 256 |
| 211 | B | `0x00DF9090` | `GenericLOD` | `0x7E5F1839` | 16 | 64 |
| 212 | A | `0x017BE9D8` | `RoadIntersection` | `0x6FD048F4` | 124 | 256 |
| 213 | A | `0x017BEA28` | `ScrubObject` | `0xAB92C697` | 4 | 256 |
| 214 | A | `0x017BEA78` | `TerrainObject` | `0x6C82EBE5` | 4 | 256 |
| 215 | A | `0x017BEAC8` | `TerrainFade` | `0x26AE8736` | 20 | 32 |
| 216 | A | `0x017BEB18` | `LightObject` | `0x97E8EE92` | 52 | 256 |
| 217 | A | `0x017BEB68` | `LowResTerrainObject` | `0x2D8D2435` | 8 | 256 |
| 218 | A | `0x017BEBB8` | `NetCategoryInfo` | `0x99CDCA52` | 2 | 256 |
| 219 | B | `0x00DF9110` | `RuntimePhysicalLink` | `0xFE770464` | 40 | 256 |
| 220 | B | `0x00DF9190` | `RuntimeConstraintLink` | `0x197EF056` | 296 | 32 |
| 221 | B | `0x00DF9210` | `RuntimeEntranceLink` | `0x63FF60AD` | 8 | 256 |
| 222 | A | `0x017BEC08` | `RuntimeWeapon` | `0xEC62E3A3` | 52 | 64 |
| 223 | A | `0x017BEC58` | `RuntimeWeaponProjectile` | `0x7A303AD6` | 108 | 32 |
| 224 | A | `0x017BECA8` | `RuntimeAlternatingFire` | `0x9BB55CF2` | 16 | 8 |
| 225 | B | `0x00DF9290` | `RuntimeTriggerable` | `0x547F025D` | 4 | 8 |
| 226 | A | `0x017BECF8` | `RuntimeVelocity` | `0xE493BF82` | 8 | 16 |
| 227 | A | `0x017BED48` | `RuntimeProjectile` | `0x9D2AB1A6` | 160 | 128 |
| 228 | A | `0x017BED98` | `RuntimeFakeProjectile` | `0x750BC641` | 68 | 8 |
| 229 | A | `0x017BEDE8` | `RuntimeFlightNoise` | `0xEBF6D595` | 32 | 8 |
| 230 | A | `0x017BEE38` | `RuntimeProjectileThrown` | `0xF394DE30` | 4 | 16 |
| 231 | A | `0x017BEE88` | `RuntimeTimer` | `0x38437A4E` | 16 | 16 |
| 232 | A | `0x017BEED8` | `RuntimeAssetRef` | `0xD2435030` | 4 | 256 |
| 233 | A | `0x017BEF28` | `RuntimeExplosion` | `0x5529DD38` | 64 | 8 |
| 234 | A | `0x017BEF78` | `RuntimeHealth` | `0xF9B9B2A5` | 12 | 256 |
| 235 | A | `0x017BEFC8` | `RuntimeNodeHealth` | `0x76927BF5` | 4 | 256 |
| 236 | A | `0x017BF018` | `RuntimeSoundRuinKey` | `0x25E2DEF3` | 4 | 16 |
| 237 | A | `0x017BF068` | `RuntimeSoundEffect` | `0x0E83BCB7` | 28 | 256 |
| 238 | A | `0x017BF0B8` | `RuntimeSoundAmbience` | `0x5FE773CC` | 1 | 64 |
| 239 | A | `0x017BF108` | `RuntimeMusicRegion` | `0xAA6964E8` | 1 | 64 |
| 240 | A | `0x017BF158` | `RuntimeOwnerGuid` | `0xAFF006A7` | 4 | 32 |
| 241 | A | `0x017BF1A8` | `RuntimeAirstrikeProjectile` | `0xF67A894A` | 40 | 8 |
| 242 | A | `0x017BF1F8` | `RuntimeAirstrikeAirplane` | `0x23D5DE91` | 176 | 4 |
| 243 | A | `0x017BF248` | `RuntimeObjectiveMarker` | `0x2A77B292` | 112 | 32 |
| 244 | A | `0x017BF298` | `RuntimeScriptCallback` | `0x3B105827` | 8 | 8 |
| 245 | A | `0x017BF2E8` | `RuntimeScrub` | `0x7DA4BD48` | 8 | 256 |
| 246 | B | `0x00DF9310` | `RuntimeModelState` | `0xFC97DD05` | 56 | 256 |
| 247 | B | `0x00DF9390` | `RuntimeFacialExpression` | `0x921EFC0D` | 48 | 32 |
| 248 | A | `0x017BF338` | `RuntimeHeadLookAt` | `0x6B1666DF` | 44 | 64 |
| 249 | B | `0x00DF9410` | `RuntimeDebrisEffect` | `0xD255212D` | 88 | 8 |
| 250 | B | `0x00DF9490` | `RuntimeTurret` | `0x937EA0CD` | 4 | 64 |
| 251 | A | `0x017BF388` | `RuntimeIgnitor` | `0x1CA3ABD7` | 28 | 8 |
| 252 | B | `0x00DF9510` | `RuntimeEquipmentLink` | `0x77C00AA9` | 12 | 256 |
| 253 | A | `0x017BF3D8` | `RuntimeInventory` | `0xA364FC7D` | 48 | 64 |
| 254 | A | `0x017BF428` | `RuntimeAnimationParams` | `0x9606E589` | 40 | 8 |
| 255 | A | `0x017BF478` | `RuntimeLayerId` | `0x2284FE19` | 4 | 256 |
| 256 | A | `0x017BF4C8` | `RuntimeRiderDiveEnter` | `0x8A15415F` | 68 | 256 |
| 257 | A | `0x017BF518` | `RuntimeRiderCrawlExit` | `0xA7D4D8CA` | 52 | 8 |
| 258 | A | `0x017BF568` | `RuntimeVehicleCrawlExits` | `0x1FA43615` | 108 | 8 |
| 259 | A | `0x017BF5B8` | `RuntimeClaim` | `0x5D5CB7BD` | 12 | 16 |
| 260 | B | `0x00DF9590` | `RuntimeClaimCover` | `0x340C811E` | 24 | 16 |
| 261 | A | `0x017BF608` | `RuntimeLastDamageApplied` | `0x9CBD437B` | 28 | 32 |
| 262 | A | `0x017BF658` | `RuntimeTravelGroup` | `0x5F187FA4` | 8 | 8 |
| 263 | A | `0x017BF6A8` | `RuntimeHomingWeapon` | `0xC09ADB1B` | 84 | 8 |
| 264 | A | `0x017BF6F8` | `RuntimeHomingProjectile` | `0xC45D369E` | 88 | 8 |
| 265 | A | `0x017BF748` | `RuntimeHomingTarget` | `0x14F6DE44` | 48 | 64 |
| 266 | A | `0x017BF798` | `RuntimeLaserDesignator` | `0x735B0EAA` | 16 | 4 |
| 267 | A | `0x017BF7E8` | `RuntimeVehicleInventory` | `0x9A6DB283` | 2 | 32 |
| 268 | B | `0x00DF9610` | `RuntimeVehiclePart` | `0x31202C8E` | 16 | 64 |
| 269 | B | `0x00DF9690` | `RtRisingRuinPhysicsAnimation` | `0x22968ABC` | 4 | 8 |
| 270 | A | `0x017BF838` | `RuntimeMassiveSubscriber` | `0x4172E975` | 4 | 256 |
| 271 | A | `0x017BF888` | `PhysicsActor` | `0xFE9497DB` | 4 | 256 |
| 272 | A | `0x017BF8D8` | `PhysicsActorWinch` | `0x025B7AB6` | 4 | 16 |
| 273 | A | `0x017BF928` | `PhysicsActorRagdoll` | `0xF365E0EC` | 4 | 64 |
| 274 | A | `0x017BF978` | `RtDebris` | `0x964BEBAA` | 28 | 64 |
| 275 | A | `0x017BF9C8` | `RTHuman` | `0x2C6E46B6` | 72 | 64 |
| 276 | A | `0x017BFA18` | `RtPopHint` | `0x036DC9CB` | 1 | 128 |
| 277 | A | `0x017BFA68` | `RtPopMembership` | `0x8C8E5490` | 20 | 32 |
| 278 | B | `0x00DF9710` | `RtExhaustionCounter` | `0x6F49F3A9` | 12 | 8 |
| 279 | A | `0x017BFAB8` | `RtDriverData` | `0xE2636501` | 16 | 64 |
| 280 | A | `0x017BFB08` | `RtJunction` | `0x643B62AF` | 16 | 8 |
| 281 | A | `0x017BFB58` | `RtRedEffect` | `0x9B2DAF6F` | 32 | 8 |
| 282 | A | `0x017BFBA8` | `RtVFX` | `0x757B2069` | 16 | 256 |
| 283 | A | `0x017BFBF8` | `RtTickDamage` | `0x27E19BF7` | 16 | 16 |
| 284 | A | `0x017BFC48` | `RtLightAnimation` | `0x8AA117BD` | 44 | 32 |
| 285 | A | `0x017BFC98` | `RtColorAnimation` | `0x52DA71DE` | 16 | 8 |
| 286 | A | `0x017BFCE8` | `RtScaleAnimation` | `0xC1EDC09B` | 20 | 8 |
| 287 | A | `0x017BFD38` | `RtAlphaAnimation` | `0xA7B2F925` | 20 | 8 |
| 288 | B | `0x00DF9790` | `RtAttachedFlowControl` | `0x56F7F6B2` | 4 | 256 |
| 289 | A | `0x017BFD88` | `RtFlowControl` | `0xB6CB89DE` | 92 | 64 |
| 290 | A | `0x017BFDD8` | `RtFlowCycleTimer` | `0xD4CA71DA` | 68 | 32 |
| 291 | A | `0x017BFE28` | `RtRoadIntersection` | `0x5E137672` | 196 | 64 |
| 292 | B | `0x00DF9810` | `RtPathMember` | `0x99C8FCE4` | 4 | 32 |
| 293 | A | `0x017BFE78` | `RtLivingWorld` | `0x115B2B5C` | 16 | 16 |
| 294 | B | `0x00DF9890` | `RtPoweredGate` | `0x3E74EBD8` | 48 | 32 |
| 295 | A | `0x017BFEC8` | `RuntimeTerrainBound` | `0x745C6D6A` | 28 | 32 |
| 296 | A | `0x017BFF18` | `ContextAction` | `0xF957A94C` | 160 | 16 |
| 297 | A | `0x017BFF68` | `Model` | `0x5B724250` | 4 | 8 |
| 298 | A | `0x017BFFB8` | `CenterOfMassInWorld` | `0xE5276B5C` | 12 | 8 |
| 299 | A | `0x017C0008` | `RuntimeRope` | `0xA9C2A15B` | 4 | 8 |
| 300 | B | `0x00DF9910` | `RuntimeFakeWheel` | `0xC9E072D1` | 4 | 8 |
| 301 | B | `0x00DF9990` | `HumanStateMachine` | `0x07B5A5C2` | 4 | 128 |
| 302 | B | `0x00DF9A10` | `HumanAnimationControllerNEW` | `0xECB746CC` | 4 | 64 |
| 303 | A | `0x017C0058` | `AnimationController` | `0xF1D5ADD9` | 4 | 16 |
| 304 | A | `0x017C00A8` | `ControlBinding` | `0x3486768B` | 4 | 16 |
| 305 | A | `0x017C00F8` | `BoneControllerRuntime` | `0x09A0962D` | 4 | 256 |
| 306 | B | `0x00DF9A90` | `MaterialControllerRuntime` | `0xA5FAE422` | 4 | 256 |
| 307 | A | `0x017C0148` | `RtCoverHint` | `0x4350B887` | 1 | 256 |
| 308 | A | `0x017C0198` | `RtAlarm` | `0x7A3425CE` | 1 | 32 |
| 309 | A | `0x017C01E8` | `Usable` | `0xB3AF2A59` | 8 | 128 |
| 310 | A | `0x017C0238` | `RtDamageFlags` | `0x93621235` | 4 | 256 |
| 311 | B | `0x00DF9B10` | `CheatInfiniteAmmo` | `0x989C4290` | 1 | 128 |
| 312 | B | `0x00DF9B90` | `Players` | `0x451C2119` | 4 | 8 |
| 313 | A | `0x017C0288` | `SpawnerAdjust` | `0x1003413E` | 96 | 16 |
| 314 | A | `0x017C02D8` | `SceneObject` | `0xB6185886` | 28 | 256 |
| 315 | B | `0x00DF9C10` | `PendingSceneObject` | `0xD25A84AB` | 8 | 256 |
| 316 | B | `0x00DF9C90` | `RuntimeSceneObject` | `0x72D1A144` | 56 | 256 |
| 317 | A | `0x017C0328` | `TerrainGuidMappingHighResToLowRes` | `0x23B3D1E4` | 4 | 256 |
| 318 | A | `0x017C0378` | `SysPathRoadIndex` | `0x805AD569` | 4 | 256 |
| 319 | A | `0x017C03C8` | `SysPathIntersectionIndex` | `0x2EEF9DD2` | 4 | 256 |
| 320 | B | `0x00DF9D10` | `RuntimePickup` | `0x9579AF7B` | 4 | 64 |
| 321 | B | `0x00DF9D90` | `RuntimeEntranceUsable` | `0xEAEB68D5` | 4 | 256 |
| 322 | A | `0x017C0418` | `RuntimeEntrance` | `0x55D8D2B1` | 1 | 128 |
| 323 | A | `0x017C0468` | `RuntimeHijackState` | `0xD5F2B17A` | 20 | 8 |
| 324 | A | `0x017C04B8` | `RuntimeSeatPlayerUsable` | `0xE5FB2B37` | 1 | 256 |
| 325 | A | `0x017C0508` | `RagdollController` | `0x34EA185E` | 4 | 64 |
| 326 | A | `0x017C0558` | `AiUnUsable` | `0x4A548962` | 1 | 8 |
| 327 | A | `0x017C05A8` | `Suspect` | `0x1AFC276C` | 32 | 32 |
| 328 | A | `0x017C05F8` | `RtFactionZone` | `0xA67114C7` | 28 | 16 |
| 329 | A | `0x017C0648` | `RtRibbon` | `0x9AB86EB3` | 32 | 16 |
| 330 | A | `0x017C0698` | `RtSpeedLimit` | `0xFF142695` | 28 | 8 |
| 331 | A | `0x017C06E8` | `RtTerrainChildren` | `0x0FF1C703` | 64 | 32 |
| 332 | B | `0x00DF9E10` | `RtEffectVelocityControl` | `0x9EBF9F5C` | 28 | 256 |
| 333 | A | `0x017C0738` | `RtGenericLOD` | `0x0C51B633` | 68 | 32 |
| 334 | A | `0x017C0788` | `RtGenericLODProxy` | `0xCE91973D` | 4 | 32 |
