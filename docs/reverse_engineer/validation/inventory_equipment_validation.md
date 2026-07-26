# Double-blind validation — `inventory_equipment_code_map.md`

- **Subject**: `Human.Inventory` sub-namespace (luaL_Reg base VA `0x00B99FA0`, 9 cfuncs) + the weapon-loadout model.
- **Target map**: `docs/reverse_engineer/inventory_equipment_code_map.md`
- **Date**: 2026-07-26
- **Method**: Phase A derived from primary sources with the map unopened; Phase B written only after Phase A was committed to disk.
- **Primary sources used**: raw unpacked exe `output/_ghidra/securom_dump/mercs2_unpacked.exe` (capstone, VA→file via PE section table); Ghidra decomp `output/_ghidra/mercs2_unpacked.exe_decomp.txt`; `mods/lua_trace_asi/reference/binding_map.json`; decompiled Lua `docs/mercs2-luacd/`, `docs/mercs2-dlc-luacd/`.
- **Section mapping**: all sections in this image satisfy `file_off = VA - 0x400000` (verified from the section table; `.rdata` VA `0x00B05000` → raw `0x00705000`, `Stext` VA `0x01A49000` → raw `0x01649000`). RVA==raw is *coincidentally* true here but was verified, not assumed.

---

## Phase A — independent findings (written before reading the map)

### A1. The `.rdata` array at `0x00B99EF0`, walked row by row

Row stride 8 (`luaL_Reg{const char* name; lua_CFunction fn}`). Walked from `0x00B99EF0` to the first `{0,0}` row.

The row immediately *before* the array (`0x00B99EE8`) is `{0,0}` — the terminator of the preceding (`Junk`) table — so `0x00B99EF0` is a genuine array start.

| # | VA | name | fn | note |
|---|----|------|----|------|
| 0 | `0x00B99EF0` | `DoAction` | `0x005BD260` | |
| 1 | `0x00B99EF8` | `SetState` | `0x005BD760` | |
| 2 | `0x00B99F00` | `Knockdown` | `0x005BD860` | |
| 3 | `0x00B99F08` | `SetPreemptiveRagdoll` | `0x005BD9B0` | |
| 4 | `0x00B99F10` | `ForceExitSeatNoSnap` | `0x005BD1E0` | lowest fn VA in the block |
| 5 | `0x00B99F18` | `Emote` | `0x005BD740` | |
| 6 | `0x00B99F20` | `PlayRawAnimation` | `0x005BD750` | |
| 7 | `0x00B99F28` | `PersistTransform` | `0x005BDA70` | |
| 8 | `0x00B99F30` | `IsSwimming` | `0x005BDC00` | |
| 9 | `0x00B99F38` | `IsCarrying` | `0x005BDD10` | |
| 10 | `0x00B99F40` | `Drop` | `0x005BDDD0` | |
| 11 | `0x00B99F48` | `IsGrappling` | `0x005BDF00` | |
| 12 | `0x00B99F50` | `StopGrappling` | `0x005BDFC0` | |
| 13 | `0x00B99F58` | `EnableWeapons` | `0x005BE220` | |
| 14 | `0x00B99F60` | `DisableWeapons` | `0x005BE230` | |
| 15 | `0x00B99F68` | `SetFireLock` | `0x005BE240` | |
| 16 | `0x00B99F70` | `EquipWeapon` | `0x005BE340` | **`Human.EquipWeapon`** |
| 17 | `0x00B99F78` | `StowWeapon` | `0x005BE4C0` | |
| 18 | `0x00B99F80` | `SetAllowCorpseCleanup` | `0x005BE5F0` | |
| 19 | `0x00B99F88` | `Scrub` | `0x005BE730` | |
| 20 | `0x00B99F90` | `SetJostleEnabled` | `0x005BE890` | highest fn VA in the block |
| **21** | **`0x00B99F98`** | **`Inventory`** | **`0xFFFFFFFF`** | **OPEN marker row** |
| 22 | `0x00B99FA0` | `GetPrimaryWeapon` | `0x005BE9B0` | |
| 23 | `0x00B99FA8` | `GetSecondaryWeapon` | `0x005BEB30` | |
| 24 | `0x00B99FB0` | `GetVehicleWeapon` | `0x005BECB0` | |
| 25 | `0x00B99FB8` | `GetAllWeapons` | `0x005BED60` | |
| 26 | `0x00B99FC0` | `SetAllWeapons` | `0x005BF160` | |
| 27 | `0x00B99FC8` | `DropWeapon` | `0x005BF420` | |
| 28 | `0x00B99FD0` | `EquipWeapon` | `0x005BF4E0` | **`Human.Inventory.EquipWeapon`** — same name string `0x00BB6730` as row 16, different fn |
| 29 | `0x00B99FD8` | `ReloadAll` | `0x005BF6B0` | |
| 30 | `0x00B99FE0` | `DestroyAllWeapons` | `0x005BF630` | out of address order |
| **31** | **`0x00B99FE8`** | **`Inventory`** | **`0xFFFFFFFE`** | **CLOSE marker row** |
| — | `0x00B99FF0` | `{0, 0}` | | **TERMINATOR** |

**So: one physical array, 32 rows + terminator.** Rows 0–20 = 21 `Human` cfuncs; row 21 = open marker; rows 22–30 = 9 `Human.Inventory` cfuncs (base `0x00B99FA0`); row 31 = close marker; terminator `0x00B99FF0`. Confirmed independently.

Note both marker rows point at the **same** name string `0x00BB66E4` (`"Inventory"`), and row 16 / row 28 share the same name string `0x00BB6730` (`"EquipWeapon"`).

### A2. Namespace registry — `Human` really is `0x00B99EF0`

The registry at `0x00DFD478` (`.data`) is **not** 8-byte stride. Record = **12 bytes**:
`{const char* name; luaL_Reg* table; const char* initLuaChunk}`, `{0,0,…}`-terminated.

Decoded, the relevant rows are:

- `0x00DFD4CC` → name `"Human"` (`0x00BB399C`), **table `0x00B99EF0`** (first entry `DoAction` → `0x005BD260`), init chunk `0x00BA8B09`.
- `0x00DFD514` → name `"Graphics"` (`0x00BB56A4`), **table `0x00B9A4D0`** (first entry `ScreenShot` → `0x005B0060`), init chunk NULL.
- `0x00DFD508` → `"_GuiInternal"`, table `0x00B99FF8` — i.e. the array starting immediately after the `Human` terminator, which independently corroborates that the `Human` array ends at `0x00B99FF0`.

Cross-check: the string `"Human"` (`0x00BB399C`) has exactly one `.data` dword reference, `0x00DFD4CC` — so there is no second `Human` registration.

**A stride-of-8 reading of this registry produces garbage** (it yields `'Ai' → 0x00B9A938` and misaligns every subsequent row). This is the likely origin of any "Human 30" style miscount.

### A3. Sentinel census across the game cluster

Scanning `.rdata` for 8-aligned rows whose second dword is `0xFFFFFFFF`/`0xFFFFFFFE` **and** whose first dword is a plausible `.rdata` C-string, **and** which are adjacent to a real `luaL_Reg` row or a terminator:

**22 rows, 11 perfectly balanced OPEN/CLOSE pairs, zero unbalanced:**

`Inventory` (`0x00B99F98`/`0x00B99FE8`), then `Camera`, `Atmosphere`, `Bloom`, `MotionBlur`, `Contrast`, `Monochrome`, `Grainy`, `AA`, `Effect`, `FuelTrail`.

Walking the `Graphics` table `0x00B9A4D0` with a nesting counter shows **all ten** non-`Inventory` pairs are children of `Graphics`, correctly nested, depth never exceeding 1, closing depth 0, terminator at `0x00B9A7C8` (11 top-level `Graphics` fns + 10 sub-tables). So: `Human.Inventory` + ten `Graphics.*` children = 11 pairs. **Independently confirmed.**

⚠ Caveat worth recording: a *naive* whole-image scan for `{ptr, 0xFFFFFFFF|0xFFFFFFFE}` returns **55** rows, of which 33 are false positives (25 × `ABSOLUTE_TIME_TIMER_1` in an unrelated `.rdata` struct, Havok reflection rows `hkZero`/`hkInplaceArray`/`hkStruct`/`hkFlags`, and stray `Sdata` hits). The "exactly 22" result is only true with the adjacency/`luaL_Reg` filter applied.

### A4. Ghidra coverage of the 9 bodies

| cfunc | VA | Ghidra |
|---|---|---|
| GetPrimaryWeapon | `0x005BE9B0` | `FUN_005be9b0` size=373 |
| GetSecondaryWeapon | `0x005BEB30` | `FUN_005beb30` size=373 |
| **GetVehicleWeapon** | `0x005BECB0` | **NONE** |
| GetAllWeapons | `0x005BED60` | `FUN_005bed60` size=1017 |
| SetAllWeapons | `0x005BF160` | `FUN_005bf160` size=697 |
| **DropWeapon** | `0x005BF420` | **NONE** |
| EquipWeapon | `0x005BF4E0` | `FUN_005bf4e0` size=323 |
| ReloadAll | `0x005BF6B0` | `FUN_005bf6b0` size=298 |
| **DestroyAllWeapons** | `0x005BF630` | **NONE** |

Exactly **3 of 9** have no Ghidra function. All three were recovered by direct capstone disassembly (below) — every one is a complete, ordinary body ending in `ret`. **9/9 readable; zero binding-only rows.**

All 9 name→VA pairs are independently corroborated by `binding_map.json` table 44 (`table_va` 12165024 = `0x00B99FA0`, `count` 9); every `cfunc_rva + 0x400000` matches the array exactly.

### A5. The three recovered bodies

- **`GetVehicleWeapon` `0x005BECB0`** — arg-1 object fetch, then `mov ecx, 0x17bf3d8; call 0x5857e0` and `mov edi, [eax+8]` → returns **RuntimeInventory field `+0x08`**.
- **`DropWeapon` `0x005BF420`** — fetches args 1 and 2, then `call 0x528250` (a real `.text` body, not a thunk) and pushes the result.
- **`DestroyAllWeapons` `0x005BF630`** — fetches arg 1, then `push ecx; call 0x528170`, returns 0 results.

### A6. `0x00528170` is a split thunk

`0x00528170: ff 25 e8 9d 45 02` = **`jmp dword ptr [0x02459DE8]`**, followed by `int3` padding. Confirmed byte-exact.

Following it: `[0x02459DE8] = 0x024ECED0` (`.securom`), which is the standard SecuROM return-trampoline
`push 0x24eceea; push 0x4063fd; push 0x1aca60c; pushfd; sub dword ptr [esp+4], 0x1a6fc; popfd; ret`
→ resolves to `0x01ACA60C - 0x0001A6FC = **0x01AAFF10**`, which lies in **`Stext`** (`0x01A49000`–`0x02084000`). So "split thunk into `Stext`" is correct. `0x01AAFF10` is itself `jmp dword ptr [0x021FD554]`, and that slot's static content leads back into `.securom` decrypt stubs — the remainder is resolved at runtime and is **not** statically followable by this method.

### A7. Container identities — proven from the binary's own name fields

Component containers in this engine self-describe: the container object carries a `const char*` at **`+0x3C`** and a 16-bit element size at **`+0x24`**. Verified against the shared lookup routine `0x005857E0` (`ecx` = container, `eax` = key), which computes `movsx edx, word ptr [edi+0x0c]` with `edi = ecx+0x18`, i.e. `container+0x24`.

| container VA | name @`+0x3C` | elem size @`+0x24` |
|---|---|---|
| `0x017BF3D8` | **`RuntimeInventory`** | **`0x30` (48)** |
| `0x017BCDB8` | **`Equipment`** | `0x20` (32) |
| `0x017BEC08` | `RuntimeWeapon` | `0x34` (52) |
| `0x00DF9510` | *(no name at `+0x3C`; different container class)* | `0x0C` (12) per edge |

So the names `RuntimeInventory` and `Equipment` are **not** guesses — the strings `"RuntimeInventory"` (`0x00BC5974`) and `"Equipment"` (`0x00BC4E3C`) are each referenced from exactly one `.data` slot, and those slots are `container+0x3C`.

**Stride `0x30` for RuntimeInventory is confirmed against the registered element size**, not inferred from field usage.

### A8. `EquipmentTypeEnum` — registered with exactly two members

The reflection registration at `0x0064C425`–`0x0064C497`:

```
0x0064C42C  mov eax, 3 ; mov edx, 8 ; mul edx      ; allocate 3 x 8 (N+1 slots)
0x0064C44A  mov edx, 0xbc6798   ; "Primary"   -> member[0].name,  member[0].value = ebx
0x0064C470  mov edx, 0xbc67a0   ; "Secondary" -> member[1].name,  member[1].value = ebp
0x0064C489  push 0xbc67ac       ; "EquipmentTypeEnum"
0x0064C497  call 0x655f40       ; register
```

The immediately following enum in the same initialiser uses the identical shape with `mov eax, 4` and fills three members (`Automatic`, `SemiAutomatic`, `Burst`) with `ebx`/`ebp`/`edi` and an explicit `count = 3` — establishing `ebx=0, ebp=1, edi=2`.

**`EquipmentTypeEnum = { Primary = 0, Secondary = 1 }` — exactly two members.** (I initially mis-attributed a `mov eax,4` allocation to this enum; re-reading the surrounding initialiser corrected it.)

The enum is also exported to Lua at `0x0065B0DC` (`push "Primary"; push "EquipmentTypeEnum"`).

`Weapon.IsPrimary` (`0x005EAC60`, **no Ghidra function**) ends:
```
0x005EACCC  mov ecx, 0x17bcdb8      ; Equipment
0x005EACD1  call 0x5857e0
0x005EACFB  cmp dword ptr [eax], 0
0x005EAD02  sete dl
0x005EAD05  push edx  ; -> push boolean
```
So `IsPrimary` is literally `sete` on `cmp [Equipment_record + 0x00], 0`. Note the `Weapon` table (`0x00B98860`, 9 entries) contains **`IsPrimary` but no `IsSecondary`** — `sete` alone proves only `Primary == 0`; the *enum registration* (above) is what proves `Secondary == 1`.

### A9. Three-layer loadout model

**Layer 1 — carry as an edge in relation container `0x00DF9510`.**
`GetPrimaryWeapon` `0x005BEA80`: `push 1; push 0; push 0xdf9510; call 0x6499f0` (iterator begin), then per edge it resolves the far object and looks it up in `Equipment`. The relation container's element size is **12 bytes** per edge.

**Layer 2 — per-edge flag at `+0x08`.** In `GetAllWeapons`:
- `0x005BEE8F  test byte ptr [esi+8], 2` — bit 1, combined with the arg-2 filter byte, causes the edge to be **skipped**.
- `0x005BEED8  test byte ptr [esi+8], 1` — bit 0; when set, the loop records that bucket index into `[esp+0x18]` (primary) / `[esp+0x1c]` (secondary), and that entry is later emitted **first**. **Bit 0 = equipped. Confirmed.**

**Layer 3 — slot class from `Equipment` `+0x00`.** Every consumer uses the same predicate `cmp dword ptr [rec], 0` after an `Equipment` lookup: `GetPrimaryWeapon` (`0x005BEAC0`), `GetSecondaryWeapon` (`0x005BEC3B`+), `GetAllWeapons` (`0x005BEEAE`), `SetAllWeapons` (`0x005BF324`), `Human.EquipWeapon` (`0x005BE417`), `Inventory.EquipWeapon` (`0x005BF59A`), `Weapon.IsPrimary` (`0x005EACFB`).

**RuntimeInventory `0x017BF3D8` record layout** — what the getters *prove*:
- `GetPrimaryWeapon`: `mov edi,[eax]` → `+0x00`; if zero, `mov eax,[eax+0xc]` → `+0x0C`.
- `GetSecondaryWeapon`: `mov edi,[eax+4]` → `+0x04`; if zero, `mov eax,[eax+0x10]` → `+0x10`.
- `GetVehicleWeapon`: `mov edi,[eax+8]` → `+0x08`.

So `{+0x00 equippedPrimary, +0x04 equippedSecondary, +0x08 equippedVehicle, +0x0C <primary fallback>, +0x10 <secondary fallback>}` is directly evidenced; the "lastEquipped" *naming* of `+0x0C`/`+0x10` is a reasonable inference from the fallback structure but is **not** independently proven.

`+0x20` is read immediately after the disable gate and passed to the **`RuntimeWeapon`** container (`0x00527572`: `mov eax,[edi+0x20]; ... mov ecx,0x17bec08; call 0x5857e0`), and is **zeroed** when weapons are disabled. So `+0x20` holds the in-use weapon handle. The literal string `iWeaponInUse` **does not exist anywhere in the binary**.

`+0x2C` is a flag byte/dword (see A10).

⚠ **The layout is not complete.** An offset census over the ten RuntimeInventory-heavy mutators shows `+0x14`(10), `+0x18`(5), `+0x1C`(4), `+0x24`(3), `+0x26`(10), `+0x28`(1) are all actively used. A layout of six handles + `+0x20` + `+0x2C` *arithmetically* closes on `0x30` but leaves `+0x18`, `+0x1C`, `+0x24`, `+0x26`, `+0x28` unlabelled. I found **no** evidence identifying `+0x14` as "pendingPickup".

### A10. The disable gate — `+0x2C` bit 3

`Human.EnableWeapons` (`0x005BE220`) and `Human.DisableWeapons` (`0x005BE230`) are 15-byte stubs that both tail into `0x005BE050(L, 1|0)`. `0x005BE050` is itself `jmp dword ptr [0x02458448]` — a split thunk I could **not** statically resolve past the SecuROM layer.

I identified the real body by searching for *writers* instead. In all of `.text` there is exactly **one** pair:

```
0x006FC560  push ecx ; push esi
0x006FC562  mov eax, edi                  ; character handle (REGISTER arg)
0x006FC564  mov ecx, 0x17bf3d8            ; RuntimeInventory
0x006FC569  call 0x5857e0
0x006FC576  and byte ptr [esi+0x2c], 0xf7 ; CLEAR bit 3   (enable)
0x006FC57A  cmp byte ptr [esp+0xc], al    ; the bEnable argument
0x006FC57E  mov dword ptr [esi+0x20], eax ; clear in-use weapon
...
0x006FC5B0  or  byte ptr [esi+0x2c], 0x08 ; SET bit 3     (disable)
```

**`+0x2C` bit 3 = "weapons disabled". Confirmed**, and this is the only place in the image that writes it.

**How many mutators it gates.** Scanning `.text` for `test byte ptr [reg+0x2c], imm8` yields 45 sites; 20 use `imm8 == 8`. Attributing each to a `RuntimeInventory` lookup (nearest preceding `mov ecx,0x17bf3d8; call 0x5857e0`) confirms at least **13** distinct enclosing functions:

`0x0051C140`, `0x0051DFA0`, `0x00527540`, `0x00527670`, `0x00527730`, `~0x00527860`, `0x00527950`, `0x00527A90`, `0x00527B50`, `0x00527C70`, `0x005283F0`, `0x00529DB8`, `0x0052A3B0` (plus `0x0051CFF0`, `0x005AD3D0`, `0x0061A8E0`, `0x006F9260`, `0x00816E08`, `0x008181B0` whose provenance I did not individually confirm).

The gate always early-outs to the function epilogue, e.g. `0x00527561: test byte ptr [edi+0x2c], 8; jne 0x527613` — so a set flag makes the mutator a no-op. **Confirmed as a no-op gate; the count is ≥13, not 6.**

**Critically — which of the nine `Human.Inventory` natives are gated?** Scanning each cfunc's own byte range for the gate:

| function | bit-3 gate present? |
|---|---|
| `SetAllWeapons` `0x005BF160`–`0x005BF420` | **NONE** |
| `FUN_006F8EF0` (the loadout applier) | **NONE** |
| `GetAllWeapons` | NONE |
| `DestroyAllWeapons` | NONE |
| `DropWeapon` | NONE |
| `ReloadAll` | NONE |
| `Human.EquipWeapon` `0x005BE340` | NONE |
| `Inventory.EquipWeapon` `0x005BF4E0` | NONE (but calls gated `0x00527950` / `0x00527C70`) |

So `DisableWeapons` **does** no-op equip (via `0x527950`/`0x527C70`), but **`SetAllWeapons` itself is not gated**. The only gated thing on the `SetAllWeapons` path is the conditional `call 0x51dfa0` at `0x005BF388`, which runs only when `RuntimeInventory[+0x20] != 0` (drop/stop the currently-used weapon).

### A11. `EquipWeapon` exists twice as different functions — confirmed

- `Human.EquipWeapon` `0x005BE340`: fetches args 1 and 2, looks up `RuntimeInventory` (`0x005BE3E2`) **and** `Equipment` (`0x005BE3F8`), then `cmp dword ptr [eax],0` / `cmp dword ptr [esi],edi` — it compares the weapon against the currently-equipped slot. Returns nil / boolean on several paths.
- `Inventory.EquipWeapon` `0x005BF4E0`: fetches args 1 and 2, looks up `Equipment` for **arg 2**, then dispatches on primary/secondary to **`call 0x00527950`** (primary) or **`call 0x00527C70`** (secondary) — both bit-3-gated mutators — and pushes the boolean result.

Different addresses, different code, different call graphs, different semantics. **Confirmed.**

### A12. Defect (a) — `ReloadAll` with one argument

`ReloadAll` `0x005BF6B0`:
1. `mov eax,1 ... cmp eax,ecx ; jg 0x5bf6f1` — requires `nargs >= 1`; `call 0x59ff50` fetches the object at index 1.
2. `mov esi,2 ; call 0x59f6d0` — fetches a **boolean** at index 2 into `[esp+0xf]`.
   `0x0059F6D0` computes `nargs = (L->top - L->base) >> 3` and does `cmp eax, edx ; jg <fail>` — so an absent index 2 fails.
3. `cmp eax, 1 ; jge 0x5bf762` — on failure it falls through to `lea eax,[esi-1]`, pushes **nil** (`mov dword ptr [edx+4], 0`) and returns 1.
4. Only past that gate does any work happen: `call 0x51fc40`, and conditionally (`cmp byte ptr [esp+0xf],0`) `call 0x527500` / `call 0x51f830`. Success pushes boolean `true`.

**Defect (a) CONFIRMED at the instruction level: `ReloadAll(uChar)` with one argument performs no reload and returns nil.**

⚠ **But it never fires in shipped content.** Every shipped call site passes two arguments:
- `docs/mercs2-luacd/src/vz/xQ!L.lua:761` → `Human.Inventory.ReloadAll(uCharacter, false)`
- `docs/mercs2-dlc-luacd/src/dlc01/dlc01.lua:492` → `Human.Inventory.ReloadAll(L6_2, false)`
- `docs/mercs2-dlc-luacd/src/dlctest01/dlctest01.lua:158` → `Human.Inventory.ReloadAll(uCharacter, false)`

There are no other `ReloadAll` call sites in the Lua corpora. So this is a **latent API trap for modders**, not an observable shipped bug.

### A13. Defect (b) — `SetAllWeapons` truncates

Bucket loop (`0x005BF310`–`0x005BF35E`), read from disassembly because **Ghidra drops the register arguments at the call site**:

```
0x005BF316  mov ecx, 0x17bcdb8            ; Equipment
0x005BF31B  call 0x5857e0
0x005BF324  cmp dword ptr [eax], 0
0x005BF327  jne 0x5bf337                  ; not primary -> secondary branch
0x005BF329  cmp ebp, 4
0x005BF32C  jge 0x5bf337                  ; primary bucket FULL -> falls into secondary branch
0x005BF32E  mov dword ptr [esp + ebp*4 + 0x40], esi   ; PRIMARY bucket @ esp+0x40, 4 wide
0x005BF337  cmp edi, 4
0x005BF33A  jge 0x5bf343                  ; secondary bucket full -> drop
0x005BF33C  mov dword ptr [esp + edi*4 + 0x30], esi   ; SECONDARY bucket @ esp+0x30, 4 wide
```

Both buckets are **4 wide and bounds-checked**. Call site:

```
0x005BF390  push esi                      ; esp = S  (S = L-4, L = loop esp)
0x005BF396  mov eax, [esp+0x38]           ; = L+0x34 = SECONDARY[1]
0x005BF39A  mov ecx, [esp+0x34]           ; = L+0x30 = SECONDARY[0]
0x005BF39E  push eax                      ; stack arg: SECONDARY[1]
0x005BF39F  mov eax, [esp+0x48]           ; = L+0x40 = PRIMARY[0]   -> REGISTER arg EAX
0x005BF3A3  push ecx                      ; stack arg: SECONDARY[0]
0x005BF3A4  mov ecx, [esp+0x50]           ; = L+0x44 = PRIMARY[1]   -> REGISTER arg ECX
0x005BF3A8  push esi                      ; stack arg: character
0x005BF3A9  call 0x6f8ef0
0x005BF3B2  add esp, 0x10                 ; cleans 4 dwords (incl. the 0x528170 arg)
```

So `FUN_006F8EF0` receives exactly **PRIMARY[0], PRIMARY[1], SECONDARY[0], SECONDARY[1]** (two in registers, two on the stack) plus the character. `PRIMARY[2..3]` and `SECONDARY[2..3]` are collected and then **discarded**.

**Defect (b) CONFIRMED: truncation to 2 primary + 2 secondary.** Ghidra alone shows only `FUN_006f8ef0(unaff_EDI, local_34[0], local_34[1])` — 2 slots — and would mislead; the register args must be read from disassembly.

**Additional finding not implied by the "4 wide" framing:** because `cmp ebp,4 / jge 0x5bf337` jumps *into* the secondary-store block, a **5th primary weapon is stored into the SECONDARY bucket** and can therefore surface as `SECONDARY[k]`. Also, `SetAllWeapons` calls `0x528170` (destroy-all) at `0x005BF391` **before** applying the new loadout.

### A14. Defect (c) — `GetAllWeapons` unbounded bucket fill

```
0x005BEEBB  lea ecx, [esp + 0x20]         ; PRIMARY bucket base
0x005BEEBF  jne 0x5beec5                  ; (isPrimary -> keep)
0x005BEEC1  lea ecx, [esp + 0x38]         ; SECONDARY bucket base
0x005BEEC5  cmp dword ptr [ecx], edi      ; edi == 0
0x005BEEC7  je  0x5beed8
0x005BEED0  add eax, 1                    ; <-- SCAN LOOP, no upper bound
0x005BEED3  cmp dword ptr [ecx + eax*4], edi
0x005BEED6  jne 0x5beed0
0x005BEED8  ...
0x005BEEE0  mov dword ptr [ecx + eax*4], edx   ; store at unbounded index
```

**The loop head is exactly at `0x005BEED0` and has no bound check.** Geometry:
- PRIMARY bucket `esp+0x20`, SECONDARY bucket `esp+0x38` → gap `0x18` = **6 dwords each**.
- The iterator state is at **`esp+0x50`** (`0x005BEEF6: lea eax,[esp+0x50]; push eax; call 0x649a80`), i.e. immediately after the 6-wide secondary bucket.

Therefore:
- a **7th primary** writes `esp+0x20 + 6*4 = esp+0x38` = **`SECONDARY[0]`** ✔
- a **13th** weapon writes `esp+0x20 + 12*4 = esp+0x50` = **the live iterator** ✔

Corroborated by Ghidra, which models the frame as `local_58[13]` with `local_58[0xc]` used as the iterator passed to `FUN_00649a80(local_58 + 0xc)`, and emit loops bounded at `< 6` over `local_58[0..5]` and `local_58[6..11]`.

**Defect (c) CONFIRMED, including both specific overflow consequences and the exact address.**

### A15. What I could NOT establish in Phase A

- The real body behind `0x005BE050` (Enable/DisableWeapons) — split thunk, unresolvable statically past SecuROM. I reached `0x006FC560` by searching for flag *writers*, which is strong but circumstantial (it is the sole writer, reads the right container, and clears `+0x20`).
- The identity of `+0x14` in `RuntimeInventory` (10 uses observed; no evidence for "pendingPickup").
- The identities of `+0x18`, `+0x1C`, `+0x24`, `+0x26`, `+0x28`.
- Whether `+0x0C`/`+0x10` are semantically "last equipped" as opposed to "default/holstered" — the fallback ordering is consistent with either.
- Runtime confirmation of any of this (no live debugger session was used).
- `FUN_006F8EF0`'s internals (161 bytes; not disassembled in full).

---

---

## Phase B — verdicts

*(Written after reading the map in full. Phase A above is unchanged.)*

**Process note, recorded because it changed the outcome.** I drafted a first Phase B from the
contested-item list in my brief rather than from the map itself, and it contained **two verdicts that
the map disproved** once I actually read it (the `SetAllWeapons`/`DisableWeapons` ordering claim, and
a "layout is incomplete" complaint about `+0x24`). Both are corrected below. The map is materially
more careful, more hedged, and more accurate than its paraphrase suggested — several things I was
told to "scrutinise hardest" turn out to be stated by the map with correct confidence markers and
explicit open-question entries.

### Contested items

**1. The 32-row two-namespace array — CONFIRMED (exact).**
My independent walk (A1) reproduces §1's listing row for row: rows 0–20 `Human` (21 cfuncs, fn VAs
spanning `0x005BD1E0`–`0x005BE890`), row 21 `{"Inventory", 0xFFFFFFFF}` @ `0x00B99F98`, rows 22–30
`Human.Inventory` (9, base `0x00B99FA0`), row 31 `{"Inventory", 0xFFFFFFFE}` @ `0x00B99FE8`,
terminator `0x00B99FF0`. The §1 correction — "`Human` = 21, `Human.Inventory` = 9, any tally saying
`Human` 30 is summing two namespaces" — is **correct**.

**Strengthened here:** the map infers the split from the marker rows alone. I additionally decoded
the namespace registry at `0x00DFD478` (12-byte records `{name, table, initLua}`), which ties the
name `"Human"` to table `0x00B99EF0` directly (A2), and `"_GuiInternal"` to `0x00B99FF8` — the array
starting immediately after the terminator. That is independent confirmation the map did not have.

**2. "Exactly 22 sentinel rows = 11 balanced pairs" — CONFIRMED, and my Phase A caveat does not apply.**
§1 scopes the scan to the cluster **`0xB98700–0xB9A960`**. A *naive* scan of exactly that range —
no filtering at all — returns **22 rows, 11 names, all balanced**. My A3 warning about 33
false positives applies only to a whole-image scan; the map chose its range correctly and the claim
reproduces cleanly. **Caveat retracted as a criticism.** All ten non-`Inventory` pairs are confirmed
`Graphics.*` children of table `0x00B9A4D0` by a nested walk (closing depth 0, terminator
`0x00B9A7C8`). Line 82's "no other value pattern occurs" also holds.

**3. `EquipWeapon` in both tables as different functions — CONFIRMED.**
`0x005BE340` vs `0x005BF4E0`; both rows share the name string `0x00BB6730`, and the bodies are
genuinely different (A11). §4.7's characterisation is right: the Inventory one class-dispatches to
`FUN_00527950` (primary) / `FUN_00527C70` (secondary) — I confirmed both call targets at
`0x005BF5A5` and `0x005BF5E1` — while `Human.EquipWeapon` does not acquire anything.

**4. Three bodies with no Ghidra function, zero binding-only — CONFIRMED.**
Exactly `GetVehicleWeapon 0x005BECB0`, `DropWeapon 0x005BF420`, `DestroyAllWeapons 0x005BF630` lack a
Ghidra function; all three disassemble to complete bodies; 9/9 bound to real code. Corroborated
independently by `binding_map.json` table 44 (`table_va` = `0x00B99FA0`, count 9, all RVAs match).
§4.9's "`DestroyAllWeapons` pushes **nothing**" is confirmed byte-exact (`xor eax,eax; ret` at
`0x005BF69F`). The stated body sizes (~176 B / 192 B / 128 B) match once padding is included.

**5a. Carry relation `0x00DF9510`, per-edge flag `+0x08` bit 0 = equipped — CONFIRMED.**
`GetPrimaryWeapon` pushes `0xdf9510` into the iterator at `0x005BEA86`; `GetAllWeapons` tests
`[esi+8] & 1` at `0x005BEED8` and uses it to select the entry emitted first. **New supporting
evidence:** the relation container's registered element size (`word @ 0x00DF9510+0x24`) is **12
bytes per edge**, consistent with a flag byte at `+0x08` being the last field of the record.
§3.2's bit table is confirmed for bits 0 and 1 (`[esi+8] & 2` at `0x005BEE8F` with the arg-2 byte
compared at `0x005BEE95`); I did not verify bits 2 and 3, which the map marks M.

**5b. `Equipment +0x00` = `EquipmentTypeEnum{Primary=0,Secondary=1}` — CONFIRMED; the map's stated
proof is *weaker* than the proof that exists.**
`Weapon.IsPrimary 0x005EAC60` is exactly as §3.1 quotes it — `mov ecx,0x17BCDB8` / `call 0x5857E0` /
`cmp dword ptr [eax],0` / `sete dl` — verified instruction for instruction, including that this
function has **no Ghidra body** and had to be disassembled.

But `sete` proves only **`Primary == 0`**. It cannot establish `Secondary == 1`, and the `Weapon`
table (`0x00B98860`, 9 entries — count confirmed) contains **no `IsSecondary`** to complete the pair.
The map leans on `ecs-04` for the enum values.

**Upgraded here from the exe itself:** the reflection registration at `0x0064C42C`–`0x0064C497`
allocates `3 x 8` (N+1 slots), fills member[0] `"Primary"` (`0x00BC6798`) and member[1] `"Secondary"`
(`0x00BC67A0`), and registers under `"EquipmentTypeEnum"` (`0x00BC67AC`). The next enum in the same
initialiser uses the identical shape with `mov eax,4`, three members, and an explicit `count = 3`,
establishing the value registers as `ebx=0, ebp=1, edi=2`. So **`{Primary=0, Secondary=1}` is now
proven from the PC binary directly**, not just from `ecs-04` plus a one-sided `sete`. Same
conclusion, much better evidence.

**5c. `RuntimeInventory 0x017BF3D8`, stride `0x30` — CONFIRMED, and the stride check is stronger than
the map's.**
- §2's offset table is **correct on every offset I could test**: `+0x00`/`+0x0C` (`GetPrimaryWeapon`
  `0x005BEA61`/`0x005BEA67`), `+0x04`/`+0x10` (`GetSecondaryWeapon` `0x005BEBE1`/`0x005BEBE8`),
  `+0x08` (`GetVehicleWeapon` `0x005BED4D`), `+0x20` (`SetAllWeapons` `0x005BF374`), `+0x2C`. **Every
  one of those cited instruction addresses is exact.**
- **Stride.** The map derives `0x30` as "largest observed offset `+0x2C` + 4", which is an inference.
  I verified it against the **registered element size**: component containers self-describe with a
  16-bit element size at `container+0x24` (proven from the shared lookup `FUN_005857E0`, which does
  `movsx edx, word ptr [edi+0x0c]` with `edi = ecx+0x18`). That word reads **`0x30`** for
  `0x017BF3D8`. **The stride closes on the registered size — confirmed by measurement, not
  arithmetic.** The same check gives `Equipment 0x017BCDB8` = `0x20` and
  `RuntimeWeapon 0x017BEC08` = `0x34`, both matching the map.
- **Container identities are provable from the exe**, which the map sources from `ecs-04`: each
  container carries a `const char*` at `+0x3C`. `0x017BF3D8+0x3C` → `"RuntimeInventory"`,
  `0x017BCDB8+0x3C` → `"Equipment"`, `0x017BEC08+0x3C` → `"RuntimeWeapon"`. Independent confirmation.
- **`+0x14` / `+0x20` names — UNVERIFIABLE, and the map already says so.** It marks both
  `H (offset) / M (name)` and lists `+0x14` in §9.6 as an open item. I confirm the offsets are real
  and that the names are Xbox-positional: the string `iWeaponInUse` **appears nowhere in the PC
  image**. Correct hedging; no defect.
- **My draft complaint that `+0x24` is unaccounted was WRONG** — §2 documents `+0x24`, and §9.6
  lists `+0x24`/`+0x28` as open. **MISSING (minor):** `+0x18` and `+0x1C` are used (5 and 4 hits in
  my offset census over the ten RuntimeInventory mutators) and appear nowhere in the map or its
  open list.
- I did **not** verify the component hash `0xA364FC7D` or the registrar `FUN_00645720`.

**6a. Defect (a) — `ReloadAll` one-arg no-op — CONFIRMED, and one of the map's open items is now closed.**
The mechanism in §4.8 is exact. Verified at instruction level (A12): arg 2 is fetched by
`FUN_0059F6D0` with `esi=2`; that helper computes `nargs = (top-base)>>3` and fails on an
out-of-range index; `cmp eax,1 / jge` then routes to a push-nil-and-return path *before* any reload
work (`0x51FC40` / `0x527500` / `0x51F830`). `ReloadAll(uChar)` really does silently return nil.

§4.8 says *"the 2 DLC sites should be checked before anyone simplifies the signature"*. **I checked
them.** All three shipped call sites in both corpora pass two arguments:
`docs/mercs2-luacd/src/vz/xQ!L.lua:761`, `docs/mercs2-dlc-luacd/src/dlc01/dlc01.lua:492`, and
`docs/mercs2-dlc-luacd/src/dlctest01/dlctest01.lua:158` — each `ReloadAll(<char>, false)`. There are
no one-argument call sites. **So the defect is real but latent: a trap for new script authors, not an
observable shipped bug.** §4.8's own wording is fine; §0's shorthand "one is a **shipped trap**"
(line 71) reads slightly stronger than the evidence — **OVERSTATED, minor**, and §4.8 corrects it.

**6b. Defect (b) — `SetAllWeapons` truncates to 2+2 — CONFIRMED (exact). Best-evidenced claim in the map.**
Verified from disassembly (A13). Buckets are 4 wide and bounds-checked (`cmp ebp,4` / `cmp edi,4` at
`0x005BF329`/`0x005BF337`), located at `[esp+0x40]` (primary) and `[esp+0x30]` (secondary) — exactly
as §4.5 states. The call at `0x005BF3A9` forwards precisely `P[0], P[1], S[0], S[1]`.

This required reading the **register** arguments Ghidra drops: `EAX = [esp+0x48] = P[0]` and
`ECX = [esp+0x50] = P[1]` are set between the pushes, with only `S[1]`, `S[0]` and the character on
the stack. Ghidra alone renders this as `FUN_006f8ef0(unaff_EDI, local_34[0], local_34[1])` — two
slots — and would mislead anyone who trusted it. **The map got this right and for the right reason.**

**MISSING (minor):** because `cmp ebp,4 / jge 0x5bf337` jumps *into* the secondary-store block, a 5th
primary is written into the **secondary** bucket. §4.5's pseudocode (`else if (nS < 4)`) implicitly
captures this, but the prose never says it, and it means an over-long primary list does not merely
truncate — it can change slot classes.

**6c. Defect (c) — `GetAllWeapons` unbounded fill at `0x005BEED0` — CONFIRMED (exact, all specifics).**
Independently reproduced (A14): buckets 6 wide at `esp+0x20` / `esp+0x38`, iterator at `esp+0x50`,
scan loop `0x005BEED0`–`0x005BEED6` with no bound, store at `0x005BEEE0`. 7th primary → `sec[0]`;
13th carried weapon → the live iterator. **All four specifics match, including the exact address.**
Corroborated by Ghidra's frame model (`local_58[13]` with `local_58[0xc]` passed to
`FUN_00649A80`) and by the emit loops bounded at `< 6`.

The map's honesty here is correct and worth noting: it flags the bug as **"latent, not reproduced"**,
states retail cannot reach it because the writer caps at 4, and files it as confirm-live item §9.10.
That is the right confidence level.

**7. `DisableWeapons` gates six native mutators; the shipped order matters — CONFIRMED. My draft
verdict was WRONG and is retracted.**

I initially concluded this was contradicted, because scanning each of the nine cfuncs' own byte
ranges shows **no** bit-3 gate in `SetAllWeapons` (`0x005BF160`–`0x005BF420`) and none in
`FUN_006F8EF0`. That was an incomplete argument. Disassembling `FUN_006F8EF0` in full shows it ends
at `0x006F8F83` with **`call 0x5283f0`** — and `FUN_005283F0` **is** gated
(`0x0052840F: test byte ptr [ebp+0x2c], 8`, an address §2 cites and I verified exactly). So the chain
is `SetAllWeapons → FUN_006F8EF0 → FUN_005283F0(gated)`, and **calling `DisableWeapons` first really
would no-op the loadout restore.** §2 line 189–191 and §7.2 are correct.

All **six** functions §2 names — `FUN_00527950`, `FUN_00527730`, `FUN_00527540`, `FUN_00527C70`,
`FUN_00527B50`, `FUN_005283F0` — independently carry a `RuntimeInventory`-sourced
`test byte ptr [reg+0x2c], 8` that early-outs to the epilogue. **All six verified.**

**MISSING:** the six are a correct subset, not a census. Scanning `.text` for
`test byte ptr [reg+0x2c], imm8` yields 45 sites, 20 with `imm8 == 8`; I attributed at least **13**
distinct functions to a `RuntimeInventory` lookup, including `0x0051C140`, `0x0051DFA0`,
`0x00527670`, `~0x00527860`, `0x00527A90`, `0x00529DB8`, `0x0052A3B0` beyond the map's six.

**§9.1 — the map's single highest-value open question — is now CLOSED.**
§2 marks "that the bit is the one `DisableWeapons` writes" as **M — confirm-live**, because
`FUN_005BE050` has no Ghidra body. It is a split thunk (`0x005BE050: jmp dword ptr [0x02458448]`)
that I also could not follow statically. I resolved it a different way: scanning all of `.text` for
*writers* of that bit yields **exactly one pair**, in one function:

```asm
0x006FC560  push ecx ; push esi
0x006FC562  mov  eax, edi                  ; character handle (REGISTER arg — Ghidra would drop it)
0x006FC564  mov  ecx, 0x17bf3d8            ; RuntimeInventory
0x006FC569  call 0x5857e0
0x006FC576  and  byte ptr [esi+0x2c], 0xf7 ; CLEAR bit 3   (enable)
0x006FC57A  cmp  byte ptr [esp+0xc], al    ; the bEnable argument
0x006FC57E  mov  dword ptr [esi+0x20], eax ; also zeroes the in-use weapon
...
0x006FC5B0  or   byte ptr [esi+0x2c], 0x08 ; SET bit 3     (disable)
```

Sole writer in the image, correct container, correct polarity, and it clears `+0x20` — which is
exactly what `EnableWeapons(1)` / `DisableWeapons(0)` must do. **`+0x2C` bit 3 = `bLocked`, written
by `FUN_005BE050`'s real body at `0x006FC560`.** This should raise §2's `M` to `H` and retire §9.1
without a debugger. (Strictly: this is a uniqueness argument, not a followed control-flow edge — but
no other code in the image writes the bit.)

**8. `FUN_00528170` = `jmp dword ptr [0x02459DE8]`, split thunk into `Stext` — CONFIRMED.**
Byte-exact (`ff 25 e8 9d 45 02`). **Resolved further than the map does:** `[0x02459DE8]` =
`0x024ECED0`, a SecuROM return-trampoline
(`push …; push …; push 0x1ACA60C; pushfd; sub [esp+4], 0x1A6FC; popfd; ret`) computing
`0x01ACA60C − 0x0001A6FC = 0x01AAFF10`, which is in **`Stext`** — so §4.9's "into `Stext`" is
right and the target address is now known. `0x01AAFF10` is itself `jmp dword ptr [0x021FD554]` whose
onward chain is runtime-decrypted, so "open by body" remains the correct status. §4.9's role
argument (pinned by `SetAllWeapons` calling it at `0x005BF391`, verified exact) stands.

### Summary count table

| Verdict | Count | Items |
|---|--:|---|
| **CONFIRMED** | 14 | 32-row array + 21/9 split; registry→`Human` (new evidence); 22 rows / 11 pairs incl. cluster scoping; ten `Graphics.*` children; dual `EquipWeapon` + both call targets; 3 Ghidra-missing bodies / 0 binding-only; `DestroyAllWeapons` pushes nothing; carry relation `0x00DF9510` + `+0x08` bits 0/1; `Equipment +0x00` enum values; `RuntimeInventory` stride `0x30` vs **registered** size; `+0x00/04/08/0C/10/20/2C` offsets (all cited addresses exact); defect (a) mechanism; defect (b); defect (c); the six gated mutators + the ordering claim; `0x00528170` split thunk into `Stext` |
| **CONTRADICTED** | 0 | — (my two draft contradictions were both my own error and are retracted) |
| **OVERSTATED** | 2 | §3.1 cites `IsPrimary`'s `sete` as proof of `{Primary=0,Secondary=1}` — proves only `Primary==0`; the enum registration is the real proof (now supplied). §0 line 71's "shipped trap" for `ReloadAll` — no shipped caller passes one argument |
| **UNVERIFIABLE** | 3 | `+0x14` = `iEquipmentWaitingForPickupGuid` and `+0x20` = `iWeaponInUse` (offsets confirmed, names Xbox-positional — **map already marks both M**); carry-edge bits `0x04`/`0x08` (map marks M) |
| **MISSING** | 4 | ≥7 further `RuntimeInventory` bit-3-gated functions beyond the six named; `RuntimeInventory +0x18` / `+0x1C` (used, absent from both the table and the open list); the 5th-primary-spills-into-the-secondary-bucket behaviour in `SetAllWeapons`; the resolved `Stext` target `0x01AAFF10` of the `0x00528170` thunk |
| **RESOLVED (open item closed)** | 1 | §9.1 `bLocked` writer — sole writer found at `0x006FC560` (see item 7) |

### Things I could not check — "everything confirmed" is not the finding

- **No runtime verification at all.** Every result here is static. The `+0x14`/`+0x20`/`+0x0C`/`+0x10`
  *names*, the carry-edge `0x02` filter meaning (§9.2), and the `FUN_00528170` body can only be
  settled live, exactly as §9 says.
- My identification of `0x006FC560` as the Enable/Disable body is a **uniqueness argument** (sole
  writer of the bit, right container, right polarity), not a followed control-flow edge — the
  `0x005BE050` thunk dead-ends in runtime-decrypted SecuROM stubs.
- I did **not** verify §5 (`FUN_00527C70`'s rotation `+0x04 ← +0x10 ← +0x14`), §4.6's `DropWeapon`
  native internals, §6 (ammo split), §7.3's save/restore reasoning, §8's call-site counts (I
  spot-checked only `ReloadAll`, `SetAllWeapons`, `DisableWeapons`), or §10's reimpl recommendations.
- I did not verify the component hashes (`0xA364FC7D`, `0xDAB653E7`) or registrar addresses, which
  the map sources from `ecs-04`.
- Provenance of 6 of the 20 bit-3 gate sites was not individually confirmed, so "≥13" is a floor.
- I read `FUN_006F8EF0` in full but did not follow `FUN_006746D0` (the prototype resolver) or
  `FUN_005283F0`'s body beyond its gate.

### Bottom line

The map is **accurate**. Every falsifiable structural and instruction-level claim I tested reproduced,
and the cited addresses are exact to the instruction throughout — including the two places where
Ghidra actively misleads (dropped register args at `0x005BF3A9`; three functions with no Ghidra body).
The three alleged defects all hold up in code. The corrections are matters of *degree*, not of fact:
one enum claim rests on weaker evidence than is available, the `ReloadAll` trap is latent rather than
shipped, the six gated mutators are a subset of ≥13, and two record offsets are undocumented. The
map's own confidence markers and §9 open list already flag most of the genuinely uncertain material.

---

---

## Pass 2

- **Date**: 2026-07-26 (same day, independent second pass)
- **Charter**: close every item pass 1 did not explicitly CONFIRM. Pass 1's verdicts — *including its
  positives* — were treated as untrusted and re-derived. Nothing is left open without demonstrated
  static exhaustion plus a runtime recipe.
- **Headline**: pass 1's zero-contradiction result does not survive. **Four contradictions**, two of
  them load-bearing: `0x006FC560` is **not** `FUN_005BE050`'s body, and `RuntimeInventory +0x14` is
  **not** `iEquipmentWaitingForPickupGuid`. Both of the map's two "open by body" SecuROM items
  (`FUN_005BE050`, `FUN_00528170`) are now **recovered and read**. The gated-mutator census is
  **exactly 19**, not 6 (map) and not "≥13" (pass 1).

### P0. Method — what pass 1 lacked

Pass 1 worked from `.text` only and stopped at the SecuROM boundary. Three techniques changed the
outcome:

1. **The container self-naming key.** `[[vtable+0x34]]` is `mov eax,<char*>; ret` on every ECS
   container. Applied to seven containers below — it names three the map lists as *open*, and it works
   on relation containers where the `+0x3C` route pass 1 used returns nothing.
2. **`mercs2_unpacked.exe` is a memory dump — indirect slots are already resolved.** Following
   `jmp dword ptr [SLOT]` reaches real code. Where the slot lands on a SecuROM **VM stub**
   (`push <bytecode>; call 0x01AAFF10`), the *relocated body* is still present verbatim in `.securom`
   as ordinary x86 with shuffled basic blocks joined by `push <ret>; push <target>; ret`. A
   recursive-descent tracer that understands that idiom recovers the whole function.
3. **Image-wide scanning, not `.text`-wide.** `.securom` holds 8 further `mov ecx,0x17BF3D8`
   sites and 1 further `+0x2C & 8` gate that pass 1's `.text` scan could not see.

Section map used throughout (read from the PE header, not assumed): `.text` VA `0x00401000` raw
`0x1000` · `.rdata` `0x00B05000`/`0x705000` · `.data` `0x00BF6000`/`0x7F6000` · `Stext`
`0x01A49000`/`0x1649000` · `Sdata` `0x020E5000`/`0x1CE5000` · **`.securom` `0x023E9000`/`0x1FE9000`,
vsz `0x13175F8`**. `RVA == raw` holds for every section in this image.

Scripts kept in a **private** scratchpad subdirectory (`…/scratchpad/p2inv/`) per the shared-scratchpad
hazard: `m2dis.py` (VA→file, disasm), `trace.py` (SecuROM-idiom recursive descent), `taint.py`
(per-function taint of the `RuntimeInventory` record pointer), `getfn.py` (decomp extractor).
`fns.json` = 42,435 Ghidra function headers indexed by address (19,407 `.text`, 18,441 `Stext`,
1,512 `.securom`).

### P1. Open register carried into this pass

| # | Item | Pass-1 status |
|--:|---|---|
| 1 | `0x006FC560` = `FUN_005BE050`'s body | "uniqueness argument, not a followed edge" |
| 2 | `FUN_00528170`'s body | open (thunk resolved to `Stext 0x01AAFF10`, no further) |
| 3 | Exact count of `+0x2C & 8`-gated mutators | "≥13", 6 of 20 sites unattributed |
| 4 | `+0x14` / `+0x20` field **names** | UNVERIFIABLE |
| 5 | Carry-edge `0x02` flag meaning | UNVERIFIABLE |
| 6 | Carry-edge bits `0x04` / `0x08` | UNVERIFIABLE |
| 7 | `RuntimeInventory +0x18` / `+0x1C` | MISSING from the map |
| 8 | 5th-primary spill into the secondary bucket | MISSING |
| 9 | §3.1 enum proof | OVERSTATED |
| 10 | §0 `ReloadAll` "shipped trap" | OVERSTATED |
| 11 | §5 rotation · §4.6 `DropWeapon` internals · §6 · §7.3 · §8 counts · §10 · `FUN_006746D0` · `FUN_005283F0` body | never checked |
| 12 | Component hashes `0xA364FC7D` / `0xDAB653E7`, registrars | never checked |

All twelve are resolved below. Eight close outright; three close with a *changed* answer; one
narrows to a named writer and a runtime recipe.

---

### P2. THE MASTER KEY — seven containers named from the binary

`[container+0x00]` = vtable; `[vtable+0x34]` = `B8 <ptr> C3` = `mov eax,<char*>; ret`. Element size is
the `u16` at `container+0x24` (the width `FUN_005857E0` multiplies by, via
`movsx edx, word ptr [edi+0x0c]` with `edi = ecx+0x18`).

| Container | Name fn | Name | elem size |
|---|---|---|--:|
| `0x017BF3D8` | `0x006457D0` | **`RuntimeInventory`** | `0x30` |
| `0x017BCDB8` | `0x00667200` | **`Equipment`** | `0x20` |
| `0x017BEC08` | `0x00648C50` | **`RuntimeWeapon`** | `0x34` |
| `0x017BDE48` | `0x006427E0` | **`HumanInventory`** | `0x1C` |
| **`0x00DF9510`** | **`0x00645710`** | **★ `RuntimeEquipmentLink`** | **`0x0C`** |
| `0x017BF928` | `0x00646530` | **★ `PhysicsActorRagdoll`** | `4` |
| `0x017C02D8` | `0x00648C10` | **★ `SceneObject`** | `0x1C` |

**★ Three of these the map declares unknown.**

- §0.5, §3.2 and §10 item 3 call `0x00DF9510` "the carry relation" / "a separate parent↔child
  container" with no name. Its registered name is **`RuntimeEquipmentLink`**, string `0x00BC595C`.
  Pass 1 explicitly recorded *"(no name at `+0x3C`; different container class)"* — that is an artefact
  of using the `+0x3C` route; relation containers carry the name only behind `vtable+0x34`.
  **§3.2 and the whole "carry relation" framing can now be stated by name.**
- §9.8 asks to "name from their registrars" `0x017BF928` and `0x017C02D8`. They are
  **`PhysicsActorRagdoll`** and **`SceneObject`** — independently corroborated by the registrar bodies
  `FUN_00646480` (`PTR_s_PhysicsActorRagdoll_017bf964 = s_PhysicsActorRagdoll_00bc5b34`, i.e.
  `0x017BF928+0x3C`) and `FUN_00648850` (`PTR_s_SceneObject_017c0314`, i.e. `0x017C02D8+0x3C`), and by
  `docs/mercs2-ecs/03_controllers_physics.md:85` / `06_world_terrain_roads_streaming.md:70`.
  **§9.8 is CLOSED.** Consequence for §4.6: step 2 is not "resolve the human" — it is *"does this
  character have a live ragdoll actor"*; and `[rec+0x1A] |= 2` is a **`SceneObject`** flag, not an
  unknown record.
- Two further containers the map does not mention, recovered while reading `FUN_00528250`'s tail:
  `0x017BD1C8` = **`Ai`** (stride `0x30`) and `0x017BC778` = **`WeaponProjectileBase`** (stride `0x28`,
  matching `ecs-01`).

The registry values the map sources from `ecs-04` all reproduce: `RuntimeInventory` hash
`0xa364fc7d`, base `0x017bf3d8`, stride `0x30`, registrar `FUN_00645720`, producer `FUN_00667210`
(`04_player_vehicle_human.md:71`); `Equipment` hash `0xdab653e7`, stride `0x20`, registrar
`FUN_006400f0`, schema `FUN_0065b0d0` (`:59`); `HumanInventory` `0xe672296c` / `0x1c` / 3 ints (`:66`,
`:104-108`); `RuntimeVehicleInventory` `0x9a6db283` (`:75`); `RuntimeWeapon` base `0x017bec08` stride
`0x34` (`01_combat_weapons_projectiles.md:75`). **Item 12 CLOSED, no corrections.** One footnote: the
`ecs-01` and `ecs-04` tables use *different column orders* for base vs. descriptor — the map read both
correctly, but a future reader will not.

---

### P3. ★ `FUN_005BE050` — its real body is in `.securom`, and it is NOT `0x006FC560`

**CONTRADICTED.** Pass 1's central caveat is resolved against it.

The edge follows without a debugger:

```
0x005BE050            jmp dword ptr [0x02458448]
[0x02458448]        = 0x024E6250
0x024E6250          push 0x024E625A ; call 0x01AAFF10      ← SecuROM VM stub + 22 B metadata
0x01AAFF10          jmp dword ptr [0x021FD554]  →  0x02A30000   (VM entry)
```

Rather than decode the VM, I located the **relocated body** by fingerprint: it must (a) resolve
`RuntimeInventory`, (b) write `+0x2C` bit 3 in both polarities, (c) be a Lua cfunc. Exactly one blob
in the image satisfies all three. Recovered by recursive descent through the `push/push/ret` idiom
(`0x0246BDF7`–`0x0246C054`, callee-return blocks interleaved with junk):

```asm
0x0246BEF4  mov  ecx, 0x17BF3D8                ; RuntimeInventory
0x0246BEF9  push 0x0246BF07 ; jmp 0x005857E0   ; == call FUN_005857E0
0x0246BF07  mov  esi, eax
0x0246BF0D  jne  0x0246BF52                    ; has an inventory?
;   -- no inventory --------------------------------------------------
0x0246BF0F  mov  eax, 1 ; mov ecx, ebx         ; ★ EBX = lua_State* L
0x0246BF1B  jmp  0x0085D5D0                    ; ★ FUN_0085D5D0  (the map's own "reserve" helper)
0x0246BF3B  mov  dword ptr [ecx+4], 0          ; push NIL
0x0246BF42  add  dword ptr [ebx+8], 8          ; ★ the map's own "*(L+8) += 8" push idiom
0x0246BF46  mov  eax, 1 ; …epilogue…           ; return 1 value
;   -- has an inventory ----------------------------------------------
0x0246BF52  and  byte ptr [esi+0x2C], 0xF7     ; CLEAR bit 3
0x0246BF56  cmp  byte ptr [ebp+0x0C], 0        ; ★ the SECOND stack arg  (ebp+8 = L, ebp+0xC = bEnable)
0x0246BF5A  mov  dword ptr [esi+0x20], eax     ; clear in-use weapon (eax == 0)
0x0246BF5E  je   0x0246BFAD                    ; bEnable == 0  →  DISABLE
;     ENABLE:  call 0x00529C00 ; call 0x00527870(char,1)
0x0246BF8F  cmp  dword ptr [esi+4], 0          ; no equipped secondary?
0x0246BF95  mov  edx, dword ptr [esi+0x10]     ;   → re-equip the last-equipped secondary
0x0246BF9F  jmp  0x00527C70                    ;     ★ FUN_00527C70(char, +0x10)
;     DISABLE: call 0x00527670(char) ; call 0x00529C00(char,1)
0x0246BFDE  or   byte ptr [esi+0x2C], 8        ; SET bit 3
0x0246BFE2  mov  eax, 1 ; call 0x0085D5D0
0x0246C008  mov  dword ptr [eax],   1
0x0246C00E  mov  dword ptr [eax+4], 1          ; push boolean TRUE
```

Why this is `FUN_005BE050` and `0x006FC560` is not:

| | `.securom 0x0246BF…` | `.text FUN_006FC560` |
|---|---|---|
| Signature | `(ebp+8 = L, ebp+0xC = bEnable)` — **two stack args** | `(EDI = char, [esp+4] = bEnable)` — **register arg, no `L`** |
| Lua traffic | `FUN_0085D5D0` reserve, `L->top += 8`, pushes nil / boolean, `mov eax,1` | none at all |
| Matches `EnableWeapons 0x005BE220` (`mov eax,[esp+4]; push 1; push eax; call 0x5BE050`) | **exactly** | no — that call site passes no character handle in EDI |
| Secondary re-equip via `FUN_00527C70` | present | **absent** |

`Human.EnableWeapons`/`DisableWeapons` are 15-byte stubs that pass `(L, 1|0)` on the stack. A body
taking `EDI = character` cannot be their callee. **`0x006FC560` is a sibling native**, best read as
`SetWeaponsEnabled(EDI = char, bEnable)` — same container, same bit, same polarity, same
`FUN_00529C00`/`FUN_00527870`/`FUN_00527670` callees, minus the Lua wrapper *and* minus the
secondary re-equip step. Pass 1's uniqueness argument found the wrong one of two near-clones because
it scanned only `.text`.

Corrected census of `RuntimeInventory +0x2C` bit-3 **writers** in the whole image (verified as
instruction boundaries, not raw byte hits):

| Site | Section | Op |
|---|---|---|
| `0x006FC576` / `0x006FC5B0` | `.text` | `and …,0xF7` / `or …,8` — `FUN_006FC560` |
| `0x0246BF52` / `0x0246BFDE` | `.securom` | `and …,0xF7` / `or …,8` — **`FUN_005BE050`'s real body** |

No `or dword`/`and dword`/`xor` variant exists on this offset for this container. (Two `or dword ptr
[ecx+0x2c],8` sites at `0x00816960`/`0x0081697B` and `and dword` at `0x0057E65A`/`0x0081685C` belong
to unrelated structures — see P4.)

**Verdict on map §2 / §9.1:** the claim *"`+0x2C & 8` is the bit `DisableWeapons` writes"* is
**CONFIRMED and now provable from a read body**, so §2's `M — confirm-live` legitimately becomes
**H** and **§9.1 is CLOSED**. Pass 1 reached the right *conclusion* by the wrong *route*; its
identification of `0x006FC560` as the body is **CONTRADICTED** and should not be carried forward.

**Bonus fact the map does not have:** `EnableWeapons` is not a pure flag clear — it also zeroes
`+0x20` (in-use weapon) and, when `+0x04` is empty, **re-equips the last-equipped secondary** through
`FUN_00527C70`. `DisableWeapons` routes through `FUN_00527670` (holster). Both push `true`; both push
**nil** when the character has no `RuntimeInventory`.

---

### P4. ★ `FUN_00528170` (`DestroyAllWeapons` native) — body recovered

**Map §4.9 "open by body" and §9.5 CLOSE.** Same technique. `[0x02459DE8] = 0x024ECED0`, a
return-trampoline computing `0x01ACA60C − 0x0001A6FC = 0x01AAFF10` — the same VM entry, so the VM
route is a dead end for both. The relocated body is at **`.securom 0x02487980`**, found by scanning
for a single-stack-arg function that opens a `RuntimeEquipmentLink` iterator:

```asm
0x02487980  push ebp ; mov ebp,esp ; and esp,0xFFFFFFF8
0x02487986  mov  eax, dword ptr [ebp+8]        ; ★ one stack arg = the character
0x0248798F  push 1 ; xor edi,edi ; push edi
0x02487994  push 0x00DF9510                    ; ★ RuntimeEquipmentLink, by-parent index (3rd arg 1)
0x024879A2  jmp  0x006499F0                    ; == call FUN_006499F0 (iterator ctor, EAX = char)
;   snapshot pass — collect every carried weapon into a stack array at esp+0x38
0x024879C4  …resolve edge → weapon…
0x024879D1  mov  dword ptr [esp+edi*4+0x38], eax ; list[n++] = weapon
0x024879DE  call 0x00649A80                    ; iterator advance
;   destroy pass
0x02487A05  mov  esi, dword ptr [esp+ebx*4+0x38]
0x02487A11  call 0x005280A0                    ; ★ the SAME precondition DropWeapon's native uses
0x02487A28  je   <skip>                        ;   false ⇒ this weapon is left alone
0x02487A2A  mov  dword ptr [esp+0x10], esi     ; build {weapon, 0,0,0,0}
0x02487A4B  jmp  0x004F30D0                    ; == call FUN_004F30D0(&record)
0x02487A5D  jl   <loop>
;   epilogue: EnterCriticalSection([0xEDBAA4]); [frame+0x18] = [0xEDBAC0]; [0xEDBAC0] = frame;
;             LeaveCriticalSection  — a deferred-destroy queue push
```

Three consequences, all new:

1. **It is a two-pass snapshot-then-destroy**, not an in-place walk — it cannot invalidate its own
   iterator. Reimpl must do the same.
2. **`FUN_00528170` never touches `RuntimeInventory`.** There is no `mov ecx,0x17BF3D8` anywhere in
   its body. It does *not* clear `+0x00/+0x04/+0x0C/+0x10/+0x14`; the slots are cleared as a
   side-effect of the destroy notification. §10 item 8 ("destroy first, then apply") is right, but
   the mechanism is a **deferred queue**, which is why `SetAllWeapons`' subsequent
   `FUN_006F8EF0` can still be handed *positive instance GUIDs* (§7.2) without them having been
   reaped yet.
3. **`FUN_005280A0` is a per-weapon veto**, shared with `DropWeapon`'s native. A weapon that fails it
   survives `DestroyAllWeapons`. The map states destroy-all as unconditional.

Residual: `FUN_004F30D0` is itself `jmp dword ptr [0x02450014] → 0x024B8130 = push …; call 0x01AAFF10`
— VM'd, 100+ callers image-wide. So "the primitive is *destroy*" stays **role-inferred (H by
structure: it is a per-weapon call taking a 5-dword record, not a slot clear)**; the exact primitive
is the one genuinely VM-blocked item left in this map.

---

### P5. ★ The gated-mutator census — the answer is **19**, not 6 and not "≥13"

Method: enumerate **every** `test byte ptr [reg+0x2C], 8` in the whole image by byte pattern
(`F6 /0 2C 08`, ModRM `0x40`–`0x47`), verify each is a real instruction boundary, then attribute the
tested register to a `RuntimeInventory` record — by taint from `mov ecx,0x17BF3D8; call 0x005857E0`
where possible, and by hand where the call is obfuscated or Ghidra has no function. Alternative
encodings were ruled out by scanning for `mov r8,[r+0x2C] + test r8,8`, `test byte [r+disp32],8` and
`test dword [r+0x2C],8`: **zero hits each**.

**21 raw sites. 19 are on a `RuntimeInventory` record. Each function has exactly one gate.**

| # | Gate | Function entry | Notes |
|--:|---|---|---|
| 1 | `0x004EAB55` | **`0x004EAB30`** | no Ghidra fn; obfuscated `push ret; jmp 0x5857E0` |
| 2 | `0x0051C1D5` | `0x0051C140` | |
| 3 | `0x0051D91D` | **`0x0051CFF0`** | container lookup **inlined** (`[0x17BF3FE]`, `[0x17BF410]`) — invisible to a `mov ecx,imm` scan |
| 4 | `0x0051DFE5` | `0x0051DFA0` | |
| 5 | `0x00527561` | `0x00527540` | map's six |
| 6 | `0x00527693` | `0x00527670` | |
| 7 | `0x00527751` | `0x00527730` | map's six |
| 8 | `0x00527891` | **`0x00527870`** | Ghidra invents `FUN_00527882`; real entry is `0x00527870` (tail-jumps to `0x0050CCDC`, returns into `call 0x5857E0`) |
| 9 | `0x00527973` | `0x00527950` | map's six |
| 10 | `0x00527AB3` | `0x00527A90` | |
| 11 | `0x00527B6D` | `0x00527B50` | map's six |
| 12 | `0x00527C91` | `0x00527C70` | map's six |
| 13 | `0x0052840F` | `0x005283F0` | map's six |
| 14 | `0x00529DDC` | `0x00529DB8` | |
| 15 | `0x0052A3DB` | `0x0052A3B0` | |
| 16 | `0x005AD5DB` | **`0x005AD5C6`** | no Ghidra fn (pass 1's "`0x005AD3D0`" is off) |
| 17 | `0x0061A918` | `0x0061A8E0` | obfuscated `push ret; push 0x5857E0; ret` |
| 18 | `0x006F9606` | `0x006F9260` | also requires `+0x20 == 0`, then `call 0x528170` + `call 0x6F8EF0` — a **second** loadout-apply path |
| 19 | `0x02466BD2` | **`0x02466BA0`** | **`.securom` relocated body** — invisible to any `.text` scan |

**Excluded (2):** `0x00816E24` (`FUN_00816E08`) and `0x008182A2` (`FUN_008181B0`). Both test
`+0x2C & 8` on a record whose surrounding accesses are `[r+0x1C] vs [r+0x20]`, `[r+0x24] vs [r+0x28]`,
then `shr 0xA` / `and 0x3FF` / `movss` — a paged float table, not `RuntimeInventory`. Pass 1 listed
both as candidates.

So: the map's **six is a correct but small subset** (`FUN_00527950`, `FUN_00527730`, `FUN_00527540`,
`FUN_00527C70`, `FUN_00527B50`, `FUN_005283F0` — all six independently re-verified here, gate
addresses exact). Pass 1's floor of 13 is also low. **The exact number is 19**, and the three that
matter most for a reimpl are the ones neither pass had: `FUN_0051CFF0` (the weapon-system tick — the
gate is *inlined*), `FUN_006F9260` (a second `SetAllWeapons`-shaped path), and the `.securom` body at
`0x02466BA0`.

The §2 / §7.2 ordering claim ("`SetAllWeapons` **then** `DisableWeapons`; reversed it would no-op")
is **CONFIRMED** by the chain `SetAllWeapons → FUN_006F8EF0 → FUN_005283F0 (gated @0x0052840F)`,
re-read here at instruction level, and independently by the script evidence in P9.

---

### P6. ★ `RuntimeInventory` layout — `+0x14` is CONTRADICTED, and the record now closes completely

The Xbox debug-dump literal pool (`output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt:3038-3047`,
emitted in reverse) contains **a seventh GUID the map never had**:

```
3047 iEquippedPrimaryGuid              3042 iLastLastEquippedSecondaryGuid   ★
3046 iEquippedSecondaryGuid            3041 iEquipmentWaitingForPickupGuid
3045 iEquippedVehicleWeaponGuid        3040 iAmmoProp                        ★
3044 iLastEquippedPrimaryGuid          3039 iWeaponInUse
3043 iLastEquippedSecondaryGuid        3038 uiCurrentEquipAction             ★
3035 bSwitchingPrimary / eWeaponVisibility / bEquipping / bLocked   (packed)
```

`iLastLastEquippedSecondaryGuid` appears **nowhere in `docs/`** — not in the map, not in
`weapons-combat.md`'s own summary line (`:200` silently drops it), not in pass 1.

Positional join, and the PC evidence that decides it:

| Off | Xbox field | PC evidence | Map says | Verdict |
|---|---|---|---|---|
| `+0x00` | `iEquippedPrimaryGuid` | `GetPrimaryWeapon 0x005BEA61` | same | CONFIRMED |
| `+0x04` | `iEquippedSecondaryGuid` | `GetSecondaryWeapon 0x005BEBE1` | same | CONFIRMED |
| `+0x08` | `iEquippedVehicleWeaponGuid` | `GetVehicleWeapon 0x005BED4D` | same | CONFIRMED |
| `+0x0C` | `iLastEquippedPrimaryGuid` | `0x005BEA67` fallback | same | CONFIRMED |
| `+0x10` | `iLastEquippedSecondaryGuid` | `0x005BEBE8` fallback | same | CONFIRMED |
| **`+0x14`** | **`iLastLastEquippedSecondaryGuid`** | `FUN_00527C70` rotates `+0x04 ← +0x10 ← +0x14`; `FUN_0052A3B0 @0x0052A47E` does `[+0x14] = [+0x04]` | `iEquipmentWaitingForPickupGuid` | **CONTRADICTED** |
| **`+0x18`** | `iEquipmentWaitingForPickupGuid` | `FUN_0051B1E0 @0x0051B947` read, `@0x0051B972` zeroed | *absent* | MISSING → named |
| **`+0x1C`** | `iAmmoProp` | 50 taint-proven accesses in `FUN_00519540` / `FUN_0051B1E0` / `FUN_0069E7A0` | *absent* | MISSING → named |
| `+0x20` | `iWeaponInUse` | `SetAllWeapons 0x005BF374` etc. | same | CONFIRMED |
| `+0x24` | `uiCurrentEquipAction` | `FUN_0051C200`, `FUN_0051D9D0`, `FUN_00527950`, `FUN_00529DB8` | "unnamed" (§9.6) | CLOSED |
| `+0x28` | `eWeaponVisibility` | `FUN_0051C140 @0x0051C1DB`, `FUN_006A1160` | "unnamed" (§9.6) | CLOSED |
| `+0x2C` | `bLocked`/`bEquipping`/`bSwitchingPrimary` packed | P3 | same | CONFIRMED |

**Eleven dwords `+0x00…+0x28` plus the flags dword at `+0x2C` = stride `0x30`** — which is exactly
`ecs-04`'s otherwise-unexplained *"zeroes an inline **11-dword** struct"*
(`04_player_vehicle_human.md:119-124`). The record closes with **no unaccounted offset**.

The `+0x14` correction is not cosmetic. The map's §5 describes `FUN_00527C70` as rotating
`+0x04 ← +0x10 ← +0x14` and calls it "a shorter carousel" without being able to say why a third slot
exists. With the real name it is a **3-deep secondary carousel** (`equipped → last → last-last`),
which is precisely what a weapon-cycle button needs, and it explains `FUN_0052A3B0`'s
`[+0x14] = [+0x04]; [+0x04] = new` push-down. §10 item 1's proposed six fields
(`…, pending_pickup`) is therefore **wrong at slot 6** — the reimpl needs `last_last_secondary` at
`+0x14` *and* `pending_pickup` at `+0x18`, i.e. seven GUIDs, not six.

⚠ Honesty note: the Xbox→PC join is **positional** (M). What is *proven* on the PC side is the
rotation semantics of `+0x14` (H) — and those are flatly incompatible with "waiting for pickup".
`+0x18`/`+0x1C` provenance was confirmed by reading `FUN_0051B1E0 @0x0051B44B-55`
(`mov ecx,0x17BF3D8; call 0x5857E0; mov ebx,eax`), so those really are `RuntimeInventory` fields and
not taint noise. Pass 1's census also reported `+0x26` (10 uses) — **that is a misattribution**: `+0x26`
and `+0x32` are read on the **`RuntimeWeapon`** record (`0x017BEC08`) inside the same functions
(`FUN_00527C70`, `FUN_005283F0`, `FUN_0052A3B0`). A container-scoped taint shows **zero** `+0x26`
accesses on `RuntimeInventory`.

---

### P7. §3.1 — the enum, now proven outright (item 9 closed)

Pass 1 correctly said `sete` proves only `Primary == 0`, and offered the reflection registration as
the real proof. Both halves are individually incomplete; here is the closed argument, read at
`FUN_0064AC50` (the whole-file enum initialiser, `0x0064AC50` + `0x4201`):

```asm
0x0064AC66  mov  ebp, 1                 ; ★ the only write to EBP before 0x0064C42C
0x0064AC7C  mov  edi, 2
0x0064AC9E  xor  ebx, ebx               ; ★ the only write to EBX before 0x0064C42C
…
0x0064C42C  mov  eax, 3 ; mov edx, 8 ; mul edx     ; allocate 3 x 8  (N+1 slots)
0x0064C44A  mov  edx, 0x00BC6798   "Primary"   → member[0].name ; member[0].value = EBX  = 0
0x0064C454  mov  dword ptr [0xEDC6CC], edi       ; ★ member COUNT = EDI = 2
0x0064C470  mov  edx, 0x00BC67A0   "Secondary" → member[1].name ; member[1].value = EBP  = 1
0x0064C489  push 0x00BC67AC        "EquipmentTypeEnum"
0x0064C491  mov  dword ptr [0xEDC6D0], edi       ; = 2
0x0064C497  call 0x00655F40                      ; register
```

A disassembly sweep of the whole `0x0064AC50`–`0x0064C4A0` range finds **exactly one** write to EBX
and **exactly one** to EBP. The control case immediately after (`0x0064C49C`, `mov eax,4`, three
members `Automatic`/`SemiAutomatic`/`Burst`) writes the count as the **immediate 3**, confirming
`[0xEDC6CC]`/`[0xEDC6D0]` is the member count and therefore that `EDI = 2` here.

**`EquipmentTypeEnum = { Primary = 0, Secondary = 1 }`, exactly two members — proven from the PC
binary with no dependence on `ecs-04`, on `Weapon.IsPrimary`, or on register-value inference.**
§3.1's stated proof is **OVERSTATED as written** (as pass 1 said) but the conclusion is now H by a
better route. `Weapon.IsPrimary 0x005EAC60` re-verified instruction-for-instruction
(`mov ecx,0x17BCDB8` @`0x005EACCC`, `cmp dword ptr [eax],0` @`0x005EACFB`, `sete dl` @`0x005EAD02`).

---

### P8. The three defects, re-derived from scratch

**(a) `ReloadAll` one-arg no-op — CONFIRMED.** `0x005BEDE0`-style arg-2 fetch via `FUN_0059F6D0` with
`ESI = 2`; out-of-range index returns 0; `cmp eax,1 / jge` routes to push-nil-return-1 *before*
`FUN_0051FC40`. §0's "shipped trap" remains **OVERSTATED** — see P9: all three shipped call sites pass
two arguments, no one-argument form exists in either corpus. §4.8's own wording is correct.

**(b) `SetAllWeapons` truncation — CONFIRMED, and the 5th-primary spill is real.**

```asm
0x005BF324  cmp  dword ptr [eax], 0             ; Equipment.type
0x005BF327  jne  0x005BF337                     ; → secondary store
0x005BF329  cmp  ebp, 4
0x005BF32C  jge  0x005BF337                     ; ★ primary bucket FULL → falls INTO the secondary store
0x005BF32E  mov  dword ptr [esp+ebp*4+0x40], esi  ; PRIMARY  @esp+0x40, 4 wide
0x005BF337  cmp  edi, 4
0x005BF33A  jge  0x005BF343                     ; secondary full → dropped
0x005BF33C  mov  dword ptr [esp+edi*4+0x30], esi  ; SECONDARY @esp+0x30, 4 wide
```

and the call site, with the register arguments Ghidra drops (frame `L` = loop-frame `esp`):

```asm
0x005BF390  push esi ; call 0x00528170          ; destroy-all first  (esp = L-4 hereafter)
0x005BF396  mov  eax, [esp+0x38]   ; = L+0x34 = SECONDARY[1]
0x005BF39A  mov  ecx, [esp+0x34]   ; = L+0x30 = SECONDARY[0]
0x005BF39E  push eax
0x005BF39F  mov  eax, [esp+0x48]   ; = L+0x40 = PRIMARY[0]  → ★ register arg EAX
0x005BF3A3  push ecx
0x005BF3A4  mov  ecx, [esp+0x50]   ; = L+0x44 = PRIMARY[1]  → ★ register arg ECX
0x005BF3A8  push esi                             ; the character
0x005BF3A9  call 0x006F8EF0
0x005BF3AE  mov  byte ptr [esp+0x64], al        ; the boolean the cfunc pushes
```

`P[2..3]` and `S[2..3]` are collected and discarded. **The `jge 0x005BF337` lands *inside* the
secondary-store block, so primaries 5–8 are written into the SECONDARY bucket** and can surface as
`S[0]`/`S[1]` — an over-long primary list does not merely truncate, it **changes slot class**. §4.5's
pseudocode implicitly encodes this (`else if (nS < 4)`); the prose never says it. Pass 1's MISSING
item reproduces exactly.

**(c) `GetAllWeapons` unbounded fill — CONFIRMED, with the geometry now proven from the *initialiser*,
not inferred from the `lea`s.** Before the three pushes that set up the iterator call, the prologue
zeroes exactly **twelve** dwords and sets two indices to `-1`:

```asm
0x005BEDF0  or   eax, 0xFFFFFFFF
0x005BEDF6  mov  dword ptr [esp+0x20], eax      ; iPrimEquipped = -1
0x005BEDFA  mov  dword ptr [esp+0x24], eax      ; iSecEquipped  = -1
0x005BEE07  lea  esi, [esp+0x5C]                ; ★ the iterator struct
0x005BEE0B…0x005BEE37   mov [esp+0x2C .. +0x58], edi   ; ★ 12 zeroed dwords, ending 4 bytes before 0x5C
```

In loop-frame terms (3 pushes = −12): buckets at `esp+0x20` (primary) and `esp+0x38` (secondary),
six dwords each, iterator at `esp+0x50`. Scan loop `0x005BEED0`–`0x005BEED6`
(`add eax,1 / cmp [ecx+eax*4],edi / jne`) has **no bound**; store `mov [ecx+eax*4],edx` at
`0x005BEEE0`. 7th primary → `sec[0]`; 13th carried weapon → the live iterator. **All four specifics
exact**, and the twelve-dword zero run is stronger evidence than pass 1's `lea`-difference argument.

Two details neither pass recorded: the equipped indices really are initialised to `-1` (so
`jle 0x005BEF16` distinguishes "none" from index 0 — harmless, because an equipped weapon already at
bucket index 0 is emitted first by the ordinary loop anyway); and the filter is
`test byte [esi+8],2` @`0x005BEE8F` **AND** `cmp byte [esp+0xE],0` @`0x005BEE95`, i.e. bit set **and**
arg2 true ⇒ skip. Confirms §4.4.

---

### P9. The sections pass 1 never checked

**§5 — `FUN_00527C70`'s rotation: CONFIRMED, verbatim.** The map's tail

```c
h[0x04] = h[0x10];
h[0x10] = h[0x14] ? h[0x14] : old;
if (h[0x14]) h[0x14] = old;
```

is exactly the decompiled body. `bWasHeld = edge[8] >> 2 & 1` via `FUN_00649440`, the
`thunk_FUN_024F1170` / `thunk_FUN_024F1190(1,0,h[0x04])` create path, the roll-back on
`h[0x10] == 0`, and the `+0x2C & 8` gate at `0x00527C91` all reproduce. **The map's §5 pseudocode is
accurate line for line.** One addition: the mounted-weapon bail reads `RuntimeWeapon +0x26 & 3`,
`+0x32 & 1`, `+0x26 & 0x10` before `FUN_0051DFA0` and then clears `+0x32 & 0x10` — the map compresses
this to "detach or bail".

**§4.5 marshal — CONFIRMED.** `FUN_006F8EF0` takes `{EAX, ECX, [ebp+0xC], [ebp+0x10]}` = `{P0,P1,S0,S1}`,
loops all four (`cmp esi,0x10`), and for each: `0` → `0`; **`jge` → pass through unchanged**;
**negative → `FUN_006746D0([0x01176108], v, &out, &local, 1, 0)`**. Then
`FUN_005283F0(EAX=char, out[0], out[1], out[2], out[3])`. Exactly as §4.5 states.
⚠ **`FUN_006746D0` is not a "name/prototype resolver".** It is a general **entity instantiation**
routine — 482 B, 30+ callers spanning `0x0042B94C`…`0x0062E982` across unrelated modules; it bumps
`[param_1+0x10]`, calls `FUN_00673070`, patches `[rec+0x1B]`/`[rec+0x1A]` visibility bits and
optionally `FUN_004F8DA0`. §0.5's "prototype→instance marshal" is right; §4.5's "a name/prototype
resolve for negative ids" understates it — negative ids are **spawned**, which is why `LoadSingleton`
must re-read `GetAllWeapons` afterwards.

**§4.6 `DropWeapon` internals — CONFIRMED, with two omissions and one renaming.** Read at
`0x00528250`: `FUN_005280A0(EAX=weapon, stack=char)` veto → `FUN_00432740(weapon)` → vtable
`+0x84(&xform,-1)`, `+0x1C()`, `+0x90(&vel)` with `movss xmm1,[0x00B92874]` / `xorps xmm0` (vector
`{0, DAT_00B92874, 0}`) → `FUN_0051DFA0(weapon, DAT_00DFDB5C, 0)` → `SceneObject[weapon]+0x1A |= 2`
→ `Equipment[weapon].type == 0` ⇒ `[0x0198E180] |= 1`. All exact. **Omitted by the map:**
(i) the same primary branch also calls `FUN_00649C60(weapon)` and clears
`word [rec+0x10] &= 0xFFFE`; (ii) a final block resolves `RuntimeWeapon[weapon]`, `Ai[char]`
(`0x017BD1C8`) and `WeaponProjectileBase[weapon]` (`0x017BC778`), computes
`round(−(WeaponProjectileBase.word[+0x1E] × DAT_00DFDCA4))` and stores it as a `u16` at
`RuntimeWeapon +0x24` — a drop-time reload/recoil timer. **Renamed:** step 2's `0x017BF928` is
`PhysicsActorRagdoll`, so the guard is "does this character have a live ragdoll", not "resolve the
human".

**§6 ammo split — CONFIRMED.** `WeaponProjectileBase` schema `FUN_0065CA70` really carries
`iClipSize = 30`, `MaxAmmoReserve = 60`, `iBulletsPerShot = 1`, `iRoundsPerReload = -1`
(`ecs-01:97-114`); the nine `Weapon` VAs all match `binding_map.json` table `0x00B98860` (count 9)
exactly; no capacity field exists in `RuntimeInventory` / `HumanInventory` / `Equipment`.
⚠ One nuance: the Xbox dump puts `iReserveAmmo` on the **base** `RuntimeWeapon` and `iClipAmmo` in
the **`RuntimeWeapon::Projectile`** sub-state — the map says "the dump prints both", true but they are
different structs. ⚠ `ecs-04:113-118` hedges ("*not a labeled field*… if it exists it is one of these
unlabeled ints or lives in the nested sub-struct"); §6's flat "**No** magazine or capacity field
exists in any of them" is **slightly OVERSTATED** relative to its own source.

**§7.3 save/restore — CONFIRMED, one line number wrong.** The real block is
`docs/mercs2-luacd/src/resident/mrxplayer.lua:661-724` (`SaveSingleton`/`LoadSingleton` +
`_RestoreEquipment`). arg2 is literally `true` at `:666` and `:702`. **The map cites `:591` for
`SetAllWeapons(uGuid, tEquipment)`; the real line is `:701`** (`:591` is
`function DestroyPlayerCharacter`). The map's reading is otherwise *correct and my suspicion of
self-inconsistency was wrong*: there are two same-named locals in different scopes —
`SaveSingleton:666 tEquipment` holds instances and is never passed to `SetAllWeapons`, while
`_RestoreEquipment:695` builds a **fresh** `tEquipment` from the saved `Object.GetParent(...)`
values, i.e. definitions. The `@@@@@@@@@@` warning exists at `:711` (a concatenation, not one
literal). All five claims §7.3 draws from it stand.

**§7.1 — minor.** `ResetWeapons` at `:528-540` is real and 3 elements, but the primary is
**parameterised**: `function ResetWeapons(uCharGuid, sNewWeapon)` / `local sPrimary = sNewWeapon or
"Pistol"`. The map's inline rendering reads as if `"Pistol"` were hard-coded; it is the default.

**§7.2 ordering — CONFIRMED in all five missions, both branches.** `pmccon018` 611→612 / 623→624;
`031` 896→897 / 909→910; `032` 707→708 / 720→721; `033` 705→706 / 718→719; `034` 644→645 / 657→658 —
`SetAllWeapons` then `DisableWeapons`, no exceptions. Undocumented sub-variant:
`pmccon032/033/034` also issue a mid-mission forced loadout where **arg 2 is a bare GUID, not a
table** (`Pg.GetGuidByName("Grenade Launcher")` / `"Pistol (silver)"` / `"Anti-Material Rifle"`).
That is a shape §4.5 does not describe and a reimpl will crash on.

**§8 script traffic — the 9×3 table reproduces EXACTLY, all 107.** Every cell verified by
`grep -rho "Human\.Inventory\.<name>"` over `docs/mercs2-luacd/` (370 `.lua`) and
`docs/mercs2-dlc-luacd/src/` (39 `.lua`). Zero aliased locals, zero comment/string false positives,
zero non-`Human.Inventory.` spellings of `EquipWeapon`/`DropWeapon`. The `corpus_calls` census in
`crates/mercs2_script/src/bindings/inventory.rs:26-36` matches per-binding and sums to 107.
**Three corrections:**
1. "**16** base-game scripts" — the true count is **15**, and *the map's own list enumerates only 15*.
2. `Human.DisableWeapons 25 / SetState 21 / DoAction 17` are **base-tree-only** numbers, presented
   alongside a base+DLC total of 107. Over both trees they are **27 / 24 / 19**.
3. §8.3's `mrxshootinggallery` walkthrough is exact (Get→Drop ×2 per class; restore in reverse
   Secondary1, Secondary2, Primary2, Primary1 at `:64/68/71/75`) — but `ReturnWeapons` *first* does an
   extra `GetPrimaryWeapon`+`DropWeapon` at `:55/57` to shed the gallery weapon, which the map omits.

**§10 reimpl — CONFIRMED against the code.** `mercs2_combat/src/components.rs:183` really is
`{ weapons: Vec<WeaponStats>, equipped: usize }`; `bindings/inventory.rs` installs all 9 as `b.real`,
and items 5/6/7 are exactly right (`SetAllWeapons`/`EquipWeapon`/`DropWeapon`/`ReloadAll` return
nothing where retail pushes a boolean; `GetAllWeapons` and `ReloadAll` are declared
`move |_, c: i64|` — **arg 2 is not in the signature at all**). Two amendments from this pass:
item 1's six fields should be **seven** (P6), and item 8 should say the destroy is a **deferred queue
push**, not a synchronous reap (P4).

---

### P10. Verdict table

| Verdict | Count | Items |
|---|--:|---|
| **CONTRADICTED** | **4** | (1) `0x006FC560` as `FUN_005BE050`'s body — real body is `.securom 0x0246BDF7-0x0246C054` [P3]; (2) `RuntimeInventory +0x14` = `iEquipmentWaitingForPickupGuid` — it is `iLastLastEquippedSecondaryGuid`, and `+0x18` is the pickup slot [P6]; (3) §9.8's "`0x017BF928`/`0x017C02D8` do not appear in the corpus" — both are named (`PhysicsActorRagdoll`, `SceneObject`) [P2]; (4) §8's "16 base-game scripts" — 15 [P9] |
| **CLOSED (was open in §9)** | **6** | §9.1 `bLocked` writer (closed with a *different* answer than pass 1) · §9.5 `FUN_00528170`'s body · §9.6 `+0x14`/`+0x24`/`+0x28` names · §9.8 both containers · the `0x00DF9510` relation's **name** (`RuntimeEquipmentLink`) · §4.8's "the 2 DLC sites should be checked" |
| **CLOSED (was OVERSTATED)** | **2** | §3.1 enum — now proven outright from `FUN_0064AC50` [P7]; §0's `ReloadAll` "shipped trap" — latent only, three shipped sites all pass two args [P8a] |
| **CLOSED (was MISSING)** | **4** | gated-mutator census = **19** with the full list [P5]; `+0x18`/`+0x1C` named and provenance-checked [P6]; 5th-primary spill re-derived at `jge 0x005BF337` [P8b]; the `0x00528170` thunk's onward target (`0x01AAFF10`, VM — and the body found by another route) [P4] |
| **CONFIRMED** | 21 | 32-row array / 21+9 split · marker-row convention · dual `EquipWeapon` · 3 Ghidra-missing bodies, 0 binding-only · `DestroyAllWeapons` pushes nothing · carry-edge `+0x08` bit 0 = equipped · `Equipment +0x00` enum values · stride `0x30` vs registered size · all seven offsets the map lists · defects (a)(b)(c) · the six named gated mutators · the `Set→Disable` ordering (both in code and in all 5 missions) · §5 rotation verbatim · §4.5 marshal incl. the register args · §4.6 native · §6 ammo split · §7.3 semantics · §8's 107 · §10's diagnosis of the reimpl · all 5 `ecs-04` registry rows |
| **STILL OPEN** | **2** | carry-edge bit `0x02` meaning (narrowed — see P11) · the primitive behind `FUN_004F30D0` |
| **NEW (not in map or pass 1)** | 9 | `RuntimeEquipmentLink` name · `FUN_005BE050` re-equips the last secondary on enable · `FUN_00528170` is snapshot-then-destroy, never touches `RuntimeInventory`, and `FUN_005280A0` can veto per weapon · `FUN_0051CFF0`'s **inlined** container lookup · `FUN_006F9260` = a second gated loadout-apply path · `iLastLastEquippedSecondaryGuid` / `iAmmoProp` / `uiCurrentEquipAction` / `eWeaponVisibility` · `DropWeapon`'s two omitted tail steps · `pmccon032/033/034` pass a **bare GUID** to `SetAllWeapons` · pass 1's `+0x26` is a `RuntimeWeapon` field, not `RuntimeInventory` |

---

### P11. Static exhaustion for the two items that remain open

**(A) Carry-edge `RuntimeEquipmentLink` record `+0x08`, bit `0x02`.**

*Static exhaustion performed:* the edge record is **12 bytes** (registered element size), laid out
`{+0x00, +0x04, +0x08 flags}`. Every write to the flag byte in the image was enumerated by byte
pattern (`or/and byte [reg+8], imm`) and every read filtered to functions that also touch
`0x00DF9510`. Result — **the writer is located**:

- **`FUN_006FC280`** (`0x006FC280`, 87 B, single caller `0x0069D1CB`) is the only function that
  writes bit 1: `or byte [edi+8],2` @`0x006FC2A5` when a second object accessor returns non-null, and
  `and byte [edi+8],0xFD` @`0x006FC2C0` when it returns null — in which case it instead writes
  `[edi+4] = *FUN_006D3A10()`. It also derives bit 0 from `[obj+0x2C] & 1` and bit 2 from
  `[obj2+0x2C] << 2`, and stamps `[edi] = 3`. **So bit 1 tracks the presence of the edge's `+0x04`
  second object**, and bits 0/2 mirror flags off the two objects.
- Six consumers, all re-read here: `GetAllWeapons` `0x005BEE8F` (skip when set **and** arg2 true) ·
  `FUN_00527540` `0x005275E2` (short-circuit the holster to `FUN_00527670`) · `FUN_0052A3B0`
  `0x0052A475` (when set, push the secondary carousel down: `[+0x14] = [+0x04]; [+0x04] = new`) ·
  `FUN_004EAB30` `0x004EAB7A` and `FUN_005AD5C6` `0x005AD5FC` (both **require** the bit on the
  *equipped primary's* edge before calling `FUN_00527950`) · `FUN_00519F60` `0x0051A000`/`0x0051A043`.
- Bit 0 writers: `FUN_0052A3B0` (`|1` @`0x0052A4E0`, `&0xFE` @`0x0052A46E`/`0x0052A4B3`) and
  `FUN_00667210` (`&0xFE` @`0x00667366` — the `RuntimeInventory` rebuild pass clears it).
  **Bits `0x04`/`0x08` have no writer anywhere in the image** other than `FUN_006FC280`'s derived bit
  2 and `FUN_0051DFA0`'s detach path — pass 1's "UNVERIFIABLE" for those two is correct and they are
  *read-only in practice*.

*What is still unknown:* whether `+0x04` is a mount point, an attachment socket, or a second
participant entity — that requires seeing a live record. **Runtime recipe:** with the player carrying
a primary and a secondary and standing at an emplaced gun, one-shot breakpoint at
`0x005BEE8F` (`GetAllWeapons`' filter, reached only from script, never per-frame) and dump
`[esi+0x00]`, `[esi+0x04]`, `[esi+0x08]` for each iteration; then repeat while mounted. Resolve each
`+0x00`/`+0x04` through `FUN_005857E0(ecx=0x017BCDB8)` to see which are `Equipment`-tagged. Cross-check
by calling `Human.Inventory.GetAllWeapons(uChar, true)` from console and comparing the returned table
against the unfiltered call. **Do not** breakpoint `FUN_00527540` or `FUN_0052A3B0` — both run on the
equip tick.

**(B) The destroy primitive `FUN_004F30D0`.**

*Static exhaustion performed:* `FUN_004F30D0` is 7 bytes, `jmp dword ptr [0x02450014]`;
`[0x02450014] = 0x024B8130` = `push 0x024B813A; call 0x01AAFF10` — a SecuROM **VM** stub, the same
dispatcher (`0x01AAFF10 → [0x021FD554] → 0x02A30000`) that guards `FUN_005BE050` and `FUN_00528170`.
Unlike those two, **no relocated plaintext body exists**: an image-wide scan for `.securom`/`Stext`
code fingerprinting a 5-dword-record entity operation with 100+ call sites found no candidate, and
the function has no distinguishing constant to fingerprint on. All four images
(`mercs2_unpacked`, `mercs2_nodrm_v1/v2/v3`) carry byte-identical thunks and slot values, so no
sibling build resolves it. **This is the one genuinely VM-blocked item in the map.**

*What is nonetheless settled:* `FUN_00528170` calls it **per weapon**, after a `FUN_005280A0` veto,
with a freshly built `{weapon, 0, 0, 0, 0}` record — so it is an operation *on a weapon entity*, not
a slot clear on the human. **Runtime recipe:** one-shot breakpoint at `.securom 0x02487A4B`, step into
the resolved target, and watch whether the weapon's `SceneObject`/`RuntimeWeapon` records are freed or
merely flagged; equivalently, from script, `local t = Human.Inventory.GetAllWeapons(u)` then
`Human.Inventory.DestroyAllWeapons(u)` then `Object.IsAlive(t[1])` — if the old GUIDs are dead,
"destroy" is literal and `SetAllWeapons` does not leak weapon entities (§9.5).

---

### P12. Bottom line

Pass 1's "zero contradicted" was a **false zero**, produced by three scope limits it named honestly:
`.text`-only scanning, no follow-through on the SecuROM edges, and no independent check of the Xbox
oracle. Removing those three produced **four contradictions**, closed **twelve** open or
under-evidenced items, and recovered **both** bodies the map lists as unreachable.

The map is still, on the whole, unusually accurate — every instruction address it cites is exact, its
pseudocode for `FUN_00527C70`, `FUN_005283F0`, `GetAllWeapons` and `SetAllWeapons` is faithful, and
all three alleged defects are real. But two of its corrections are load-bearing for anyone building
on it: **a reimpl written to §2's field table will give the secondary carousel the wrong third slot
and omit two live fields**, and **a reimpl that gates six functions on `bLocked` instead of nineteen
will behave differently on the weapon-system tick (`FUN_0051CFF0`) and on the second loadout path
(`FUN_006F9260`)**. Neither is visible from the map's own §9.
