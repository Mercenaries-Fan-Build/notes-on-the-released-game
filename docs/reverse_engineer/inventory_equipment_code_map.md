# Inventory / equipment — PC code map

**Scope:** the **loadout** as the engine models it in retail PC `Mercenaries2.exe` — how a weapon
becomes *carried* by a human, the **equipped vs. last-equipped** slot pairs, the primary /
secondary / vehicle slot classes, the reserve-vs-clip ammo split and where each half lives, and the
complete **`Human.Inventory` Lua binding surface** (`luaL_Reg` table **`0x00B99FA0`, 9 cfuncs**).

**`Human.Inventory` is a separate table from `Human`.** `Human` is `0x00B99EF0`, **21 cfuncs**;
`Human.Inventory` is `0x00B99FA0`, **9 cfuncs**. They are physically adjacent in `.rdata` and the
existing bindings audit reports the pair as a single **"`Human` 30"** namespace. That is a
conflation of two Lua namespaces, and §1 settles it first-hand with the sub-table marker rows that
separate them.

**Boundaries with sibling maps** (cited, not re-derived):

| Belongs to | Not here |
|---|---|
| [`weapons_combat_code_map.md`](weapons_combat_code_map.md) | weapon **stats**, firing, projectiles, homing, damage; the `RuntimeWeapon` pool `0x017BEC08`; the **`Weapon` namespace** (9 cfuncs @ `0x00B98860`) incl. `Get/SetClipAmmo`, `Get/SetReserveAmmo`, `GetMaxReserveAmmo`, `Reload`, `IsPrimary`, `IsDesignator`; the equip/visibility tick pass `FUN_0051C200` |
| [[held-weapon-model-attachment]] (memory) | the **visual** side — bone attachment, hand hardpoint, model swap on equip |
| [`human_character_controller_code_map.md`](human_character_controller_code_map.md) | the **`Human` namespace** (21 @ `0x00B99EF0`) — `DoAction`, `SetState`, locomotion, `EnableWeapons`/`DisableWeapons`/`SetFireLock`, and `Human.EquipWeapon`/`StowWeapon` (§4.7). That map reaches the same 21/9 split independently |
| [`player_code_map.md`](player_code_map.md) | the player object, possession, cash/fuel, the profile singleton |
| [`vehicle_code_map.md`](vehicle_code_map.md) | seats, `RuntimeVehicleInventory` (the 2-byte weapon-category bitmask), emplaced/manned guns |
| [`save_serialize_code_map.md`](save_serialize_code_map.md) | the `.profile`/save on-disk layout; the Lua-level loadout save is quoted here only as *evidence* (§7.3) |
| [`../mercs2-ecs/04_player_vehicle_human.md`](../mercs2-ecs/04_player_vehicle_human.md) | the component **registry** rows (hash, registrar, stride) for `Equipment`, `HumanInventory`, `RuntimeInventory` — this map fills in the *field layout* that doc explicitly says it cannot enumerate |

**Sources.** PC: the 27k-fn Ghidra decomp `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (unpacked
SecuROM image, base `0x00400000`); **three of the nine cfuncs have no Ghidra function** and were
recovered by **direct capstone disassembly of `output/_ghidra/securom_dump/mercs2_unpacked.exe`**
(§4). Binding table name→VA: `mods/lua_trace_asi/reference/binding_map.json` (live Surface-B
`.rdata` walk), plus an independent raw `.rdata` re-walk done here (§1) that also recovered the
sub-table marker rows. Xbox oracle: [`../mercs2-pdb-analysis/weapons-combat.md`](../mercs2-pdb-analysis/weapons-combat.md)
§"Equip/inventory dump". Component registry:
[`../mercs2-ecs/04_player_vehicle_human.md`](../mercs2-ecs/04_player_vehicle_human.md) and
[`../mercs2-ecs/01_combat_weapons_projectiles.md`](../mercs2-ecs/01_combat_weapons_projectiles.md).
Script traffic: `corpus_calls` census carried in
`tools/wad_simulator/crates/mercs2_script/src/bindings/inventory.rs`, cross-checked against a direct
grep of `docs/mercs2-luacd/src/` + `docs/mercs2-dlc-luacd/` (§8).

**Method / honesty model.** Same discipline as the sibling maps. Confidence: **H** = read a body
with a can't-coincide fingerprint (a constant, an offset pair, a table walk) · **M** = one strong
structural signal · **L/open** = positional → confirm-live. Every offset states the function it was
read from. Nothing here is inferred from a name. Where a cfunc has no decompiled body **and** no
disassembly was done it would be listed as *binding-only* — that case does not arise: **all 9 of 9
are bound to a real body** (6 decompiled + 3 disassembled), which is why this map can be specific.

**Reproducing anything below.** Every VA in this map maps to a file offset by `file_off = VA −
0x00400000` in `output/_ghidra/securom_dump/mercs2_unpacked.exe`; `RVA == raw` holds for **all
thirteen** sections of that image (read from the PE section table, not assumed — `.text`
`0x00401000`/`0x1000`, `.rdata` `0x00B05000`/`0x705000`, `.data` `0x00BF6000`/`0x7F6000`, `Stext`
`0x01A49000`/`0x1649000`, **`.securom` `0x023E9000`/`0x1FE9000`, vsz `0x13175F8`**). So every
"decisive bytes" note here is a `dd`/hex-editor check away.

> **SecuROM is not a blocker** ([[securom-decompiled-not-a-blocker]]). The whole
> `0x005BE9B0–0x005BF6B0` cfunc cluster sits in clean `.text`. The three missing Ghidra bodies are
> missing because a binding-table-only function has **no static caller** for auto-analysis to walk
> from — not because of VM islands.
>
> **Two genuine split-thunks appear, and both bodies are now READ** (they were listed as
> confirm-live in earlier revisions of this map): `FUN_005BE050` (the `Enable/DisableWeapons`
> native, `jmp dword ptr [0x02458448]`, the old §9.1) and `FUN_00528170` (the `DestroyAllWeapons`
> native, `jmp dword ptr [0x02459DE8]`). Both slots land on a SecuROM **VM stub**
> (`push <bytecode>; call 0x01AAFF10`), which is a dead end — but `mercs2_unpacked.exe` is a
> **memory dump with the slots already resolved**, and for both functions the **relocated plaintext
> body is still present in `.securom`** as ordinary x86 with shuffled basic blocks joined by
> `push <ret>; push <target>; ret`. A recursive-descent walk that understands that idiom recovers
> the whole function. Bodies: `FUN_005BE050` at **`0x0246BDF7–0x0246C054`** (§2), `FUN_00528170` at
> **`0x02487980`** (§4.9). The one item still VM-blocked is `FUN_004F30D0`, the destroy primitive
> (§9.2).

---

## 0. Result in one line

**A weapon is not a field on the human — it is a child entity, and the inventory is a 0x30-byte
runtime mirror of who is holding what.** Carrying is an entry in the relation container
**`RuntimeEquipmentLink` `0x00DF9510`** (human → weapon, 12-byte edge records, per-edge flag byte at
`+0x08`, bit 0 = *this edge is the equipped one*); *being a weapon slot* is an **`Equipment`
component** (`0x017BCDB8`, stride `0x20`) whose field `+0x00` is
`EquipmentTypeEnum {Primary = 0, Secondary = 1}` — the exact dword `Weapon.IsPrimary`
(`FUN_005EAC60`) tests; and the human's fast-path state is the **`RuntimeInventory` component
`0x017BF3D8`, stride `0x30`**, which is **eleven dwords plus a flags dword** and opens with a
**seven**-GUID run: `{equippedPrimary, equippedSecondary, equippedVehicleWeapon,
lastEquippedPrimary, lastEquippedSecondary, lastLastEquippedSecondary, equipmentWaitingForPickup}`
(§2 — the sixth slot was previously mis-named as the pickup slot). **"Stowed" is not a separate
storage class**: a holstered gun is still an attached child entity; the `Last*` dwords are just the
*other* slots of the chain, and equipping is a **rotation** (`FUN_00527C70`) through them — 2-deep
for primaries, **3-deep for secondaries**. Reserve and clip ammo live on the **weapon instance**,
not on the human — which is why the shipped save writes
`{Object.GetParent(w), Weapon.GetReserveAmmo(w)}` per weapon and lets `SetAllWeapons` re-create the
instances. All nine cfuncs are recovered name→VA→body, and one is a **latent** trap: **`ReloadAll`
silently no-ops unless you pass a second boolean** (§4.8) — latent, not shipped, because all three
shipped call sites pass two arguments.

---

## 0.5 Master marriage table

| Role | Xbox symbol | PC addr | Married by | Conf |
|---|---|---|---|---|
| **`Human.Inventory` `luaL_Reg` table** | — (PC `.rdata`) | **`0x00B99FA0`**, 9 entries, 0 stubs | raw `.rdata` walk done here; every slot points at a real `.text` body | H |
| **`Human` `luaL_Reg` table** | — | **`0x00B99EF0`**, **21** entries | same walk; terminated by the `Inventory` open-marker row at `0x00B99F98` | H |
| **Nested-namespace marker rows** | — | `{"Inventory", 0xFFFFFFFF}` @ `0x00B99F98`, `{"Inventory", 0xFFFFFFFE}` @ `0x00B99FE8` | 22 such sentinel rows exist in the whole game cluster = 11 sub-namespaces (`Human.Inventory` + 10 `Graphics.*`); no other value pattern occurs | H |
| **Inventory cfunc cluster** | — | **`0x005BE9B0`–`0x005BF6B0`** (contiguous) | all 9 table slots land in the range | H |
| **★ Container name master key** | — | `[container+0x00]` = vtable; **`[vtable+0x34]`** is `B8 <char* imm32> C3` (`mov eax,<name>; ret`); the **registered element size** is the `u16` at **`container+0x24`** | `FUN_005857E0` computes the element width as `movsx edx, word ptr [edi+0x0C]` with `edi = ecx+0x18`, i.e. `container+0x24`. **This names every container in this map straight out of the binary** — see the table in §2.0. It also works on *relation* containers, where the `+0x3C` name-pointer route returns nothing. ⚠ capacity lives at `+0x20` in the `0x80`-stride class and `+0x28` in the `0x50`-stride class; locate it from the `0x9E3779B9` seed | H |
| **`RuntimeInventory` component** (the holder record) | `RuntimeWeapon` *equip dump*: `iEquippedPrimaryGuid`, `iEquippedSecondaryGuid`, `iEquippedVehicleWeaponGuid`, `iLastEquippedPrimaryGuid`, `iLastEquippedSecondaryGuid`, **`iLastLastEquippedSecondaryGuid`**, `iEquipmentWaitingForPickupGuid`, `iAmmoProp`, `iWeaponInUse`, `uiCurrentEquipAction`, `eWeaponVisibility`/`bLocked`/`bEquipping`/`bSwitchingPrimary` | container **`0x017BF3D8`**, hash `0xA364FC7D`, stride **`0x30`**, registrar `FUN_00645720` | name read from `[vtable+0x34]` → `0x006457D0` = `mov eax,"RuntimeInventory"; ret`; **stride `0x30` from the registrar's static immediate** `mov word [0x017BF3FC], 0x30` @`0x00645782`, matching the live descriptor `0x00060030` — *not* from `+0x2C+4` arithmetic; the three getters read `+0x00/+0x0C`, `+0x04/+0x10`, `+0x08` in that order and the Xbox literal pool lists a matching **eleven**-field run | H |
| **`Equipment` component** (the per-weapon slot tag) | `EquipmentTypeEnum` | container **`0x017BCDB8`**, hash `0xDAB653E7`, stride `0x20`, registrar `FUN_006400F0`, schema `FUN_0065B0D0` | name read from `[vtable+0x34]` → `0x00667200`; stride `0x20` from the registrar immediate `mov word [0x017BCDDC], 0x20` @`0x0064014D`, matching the live descriptor `0x00050020` — measured, not taken from `ecs-04`; `Weapon.IsPrimary` `FUN_005EAC60` resolves in *this* container and returns `[rec+0x00] == 0` | H |
| **`EquipmentTypeEnum {Primary=0, Secondary=1}`** | `s_EquipmentTypeEnum_00BC67AC` / `s_Primary_00BC6798` | field `+0x00` of `Equipment` | **the reflection registration** at `0x0064C42C`–`0x0064C497`: two members, values `EBX=0` / `EBP=1`, count `EDI=2` — and `EBX`/`EBP`/`EDI` are each written **exactly once** in the whole enclosing initialiser `FUN_0064AC50` (§3.1). `IsPrimary`'s `sete` corroborates but proves only `Primary==0` | H |
| **Carry / attachment relation** (human ↔ weapon) | — | **`RuntimeEquipmentLink` `0x00DF9510`**, **12-byte** edge records (iterator ctor `FUN_006499F0`, next `FUN_00649A80`, find-edge `FUN_00649440`) | name read from `[vtable+0x34]` → `0x00645710` = `mov eax,"RuntimeEquipmentLink"; ret` (string `0x00BC595C`); descriptor `0x0008000C` @`0x00DF9534` ⇒ stride `0x0C`, shift 8, capacity `0x100 == 2^8` at **`+0x20`** (this is an `0x80`-class container — §2.0). `FUN_005283F0` calls `FUN_00649440(eax=0x00DF9510, ecx=weapon, arg=human)` immediately after attaching; `GetAllWeapons` iterates it rooted at the human and every yielded id resolves in the `Equipment` container | H |
| **Per-edge flag byte** | — | relation record `+0x08`: **bit 0 = equipped**, bit 1 = filtered by `GetAllWeapons` arg 2, bit 2 read by the swap | read in `GetAllWeapons` (`&1` → push first), `FUN_005283F0` (`&1`), `FUN_00527C70` (`>>2 & 1`), `FUN_00527540` (`&2`) | H (bits) / open (names) |
| **Generic handle→record resolve** | — | **`FUN_005857E0`** (`__fastcall`, ECX = container, EAX = guid) | one body, generation-checked paged lookup; every cfunc uses it with the container in ECX — that ECX value is what identifies which component is being read | H |
| **Weapons-enable native** (`bLocked`) | — | **`FUN_005BE050`** = `jmp dword ptr [0x02458448]`; slot → `0x024E6250` (VM stub); **real body `.securom 0x0246BDF7–0x0246C054`** | read (§2): `EBX = lua_State*`, `mov ecx,0x17BF3D8`, `and byte [esi+0x2C],0xF7` @`0x0246BF52` / `or byte [esi+0x2C],8` @`0x0246BFDE`, `cmp byte [ebp+0x0C],0` = `bEnable`. **Not** `0x006FC560` (a sibling native taking `EDI`, no `lua_State`) | H |
| **Equip / slot-swap core** | — | **`FUN_00527C70`**`(char, weaponOrNull)` | rotates the **3-deep secondary carousel** `RuntimeInventory +0x04 ← +0x10 ← +0x14`; gates on `+0x2C & 8` @`0x00527C91`; shared by `Human.EquipWeapon`, `Human.StowWeapon`, `Human.Inventory.EquipWeapon`, `FUN_005283F0`, and `FUN_005BE050`'s enable path | H |
| **Draw / holster the primary** | — | **`FUN_00527730`** (draw) / **`FUN_00527540`** (holster) | draw moves `+0x0C → +0x00` and sets `+0x2C \|= 4`; holster reads `+0x00`; both gate on `+0x2C & 8` | H |
| **Give a weapon to a human** | — | **`FUN_00527B50`**`(char, weapon, bEquipNow)` | `FUN_005283F0` calls it `(P0, 1)` then `(P1, 0)` | H |
| **Apply a whole loadout (≤4)** | — | **`FUN_005283F0`**`(char, P0, P1, S0, S1)` | read: 2× `FUN_00527B50`, then two attach+`FUN_00527C70` blocks; gated at `0x0052840F` | H |
| **Second loadout-apply path** | — | **`FUN_006F9260`** | gate `0x006F9606` + `cmp [edi+0x20],0` @`0x006F960C`, then `call 0x00528170` @`0x006F9613` and `call 0x006F8EF0` @`0x006F962E` — the same destroy-then-apply pair `SetAllWeapons` uses, reached from native code, not from Lua | H |
| **Prototype→instance marshal for `SetAllWeapons`** | — | **`FUN_006F8EF0`**`(char, P0, P1, S0, S1)` → `FUN_006746D0(PTR_PTR_01176108, …)` per slot | read: any negative slot value is passed through the name/prototype resolver before `FUN_005283F0` | H |
| **Drop native** | — | **`FUN_00528250`**`(char, weapon)` | read (disasm): `FUN_005280A0` veto, detach edge, `FUN_0051DFA0`, set **`SceneObject`**`[weapon] +0x1A \|= 2`, then a vtable-driven placement + upward impulse from `[0x00B92874]` | H |
| **Destroy-all native** | — | **`FUN_00528170`** = `jmp dword ptr [0x02459DE8]`; slot → `0x024ECED0` (return-trampoline → `Stext 0x01AAFF10` = VM entry); **real body `.securom 0x02487980`** | read (§4.9): snapshot-then-destroy over a `RuntimeEquipmentLink` iterator, per-weapon `FUN_005280A0` veto, deferred-destroy queue push. Also called by `SetAllWeapons` at `0x005BF391` before it applies | H |
| **Reload-all native** | — | **`FUN_0051FC40`** → `FUN_0040E3D4`, then `FUN_00527500`, `FUN_0051F830` | read; the ammo store itself is the weapons map's `RuntimeWeapon` | M |
| **Multi-value → table packer** | — | **`FUN_005A1270`**`(n, &L)` → `lua_createtable(n,0)` + `n×rawseti` | read (disasm): `0x85DBE0` create, `FUN_005A0370` insert-below, loop `0x85DD90` from `n` down to 1 | H |
| **Persisted (design-side) inventory** | — | `HumanInventory` `0x017BDE48`, stride `0x1C`, **3 ints** | ecs-04 — **not** the runtime record; recorded so the two are not confused | H |

---

## 1. The namespace split — `Human` is 21, `Human.Inventory` is 9

[`../lua_engine_bindings_audit_deep_dive.md`](../lua_engine_bindings_audit_deep_dive.md) line 41
lists **`Human` `0x00B99EF0` → 30**, and its §1.5 correction repeats "the '~1,015' under-counted by
omitting `Human` (30)". The 30 is arithmetically right and semantically wrong: **21 + 9 = 30**, and
those are **two Lua namespaces**, not one.

Raw `.rdata` walk from `0x00B99EF0` (done here, first-hand, resolving each name pointer):

```
[ 0] 0x00B99EF0  DoAction              -> 0x005BD260      ← Human, rows 0..20  (21 cfuncs)
 …
[20] 0x00B99F90  SetJostleEnabled      -> 0x005BE890
[21] 0x00B99F98  Inventory             -> 0xFFFFFFFF      ★ SUB-TABLE OPEN marker
[22] 0x00B99FA0  GetPrimaryWeapon      -> 0x005BE9B0      ← Human.Inventory, rows 22..30 (9 cfuncs)
 …
[30] 0x00B99FE0  DestroyAllWeapons     -> 0x005BF630
[31] 0x00B99FE8  Inventory             -> 0xFFFFFFFE      ★ SUB-TABLE CLOSE marker
[32] 0x00B99FF0  {NULL, NULL}                              terminator
```

The registrar walks one physical array and, on a row whose function pointer is the sentinel
**`0xFFFFFFFF`**, pushes a nested table under that row's *name*; on **`0xFFFFFFFE`** it pops. So the
Lua-visible result is `Human.*` (21) with a child `Human.Inventory.*` (9) — which is exactly how
every shipped script spells it, and why `binding_map.json` correctly reports the child as its own
table at `0x00B99FA0`.

**The convention is not a one-off.** Scanning the game binding cluster `0xB98700–0xB9A960` at
8-byte stride for rows whose second dword is `0xFFFFFFFF`/`0xFFFFFFFE` yields **exactly 22 rows =
11 balanced open/close pairs**, no unbalanced remainder: `Inventory` (`0x00B99F98`/`0x00B99FE8`),
plus the ten `Graphics.*` children `Camera` (`0x00B9A528`/`0x00B9A568`), `Atmosphere`
(`0x00B9A570`/`0x00B9A6A0`), `Bloom` (`0x00B9A6A8`/`0x00B9A6E8`), `MotionBlur`
(`0x00B9A6F0`/`0x00B9A700`), `Contrast` (`0x00B9A708`/`0x00B9A720`), `Monochrome`
(`0x00B9A728`/`0x00B9A738`), `Grainy` (`0x00B9A740`/`0x00B9A750`), `AA` (`0x00B9A758`/`0x00B9A768`),
`Effect` (`0x00B9A770`/`0x00B9A798`), `FuelTrail` (`0x00B9A7A0`/`0x00B9A7C0`). That also explains
the deep-dive's own note that "`Graphics` has 95 physical rows = 75 functions + 20 markers" — same
mechanism, correctly handled there and missed here. **H.**

> ⚠ **The `0xB98700–0xB9A960` bound is load-bearing, not decoration.** A *naive whole-image* scan
> for `{ptr, 0xFFFFFFFF|0xFFFFFFFE}` returns ~55 rows, ~33 of them false positives (a repeated
> `ABSOLUTE_TIME_TIMER_1` struct, Havok reflection rows `hkZero`/`hkInplaceArray`/`hkStruct`/
> `hkFlags`, stray `Sdata` hits). Scope the scan to the binding cluster, or add an
> adjacency-to-a-real-`luaL_Reg`-row filter, and the 22 is exact either way.

**Independent corroboration from the namespace registry.** The registrar's own table at
**`0x00DFD478`** (`.data`) is **12-byte** records `{const char* name; luaL_Reg* table; const char*
initLuaChunk}`, `{0,0,0}`-terminated — *not* 8-byte, and a stride-of-8 reading produces garbage
(it yields `'Ai' → 0x00B9A938` and misaligns every row after). Decoded, it contains
`0x00DFD4CC → {"Human", 0x00B99EF0, 0x00BA8B09}` — one physical table for the namespace, no second
`Human` registration anywhere (the string `"Human"` `0x00BB399C` has exactly one `.data` xref) —
and `0x00DFD508 → {"_GuiInternal", 0x00B99FF8, …}`, i.e. the array starting immediately after the
`Human` terminator at `0x00B99FF0`. **That independently fixes both ends of the array**, so the
21+9 split cannot be an artefact of where the walk was started or stopped. **H.**

> **Correction to record:** `Human` = **21**, `Human.Inventory` = **9**, 2 marker rows, 32 physical
> rows, terminator `0x00B99FF0`. Any tally that says "`Human` 30" is summing two namespaces.
> Nothing about the 1,081-binding grand total changes — only the attribution.

**The name `EquipWeapon` exists in both tables** (`Human.EquipWeapon` `0x005BE340` and
`Human.Inventory.EquipWeapon` `0x005BF4E0`) and they are **different functions with different
semantics** (§4.7). Any tooling that keys bindings by bare name will collide on this pair.

---

## 2. The holder record — `RuntimeInventory` `0x017BF3D8` (stride `0x30`)

[`../mercs2-ecs/04_player_vehicle_human.md`](../mercs2-ecs/04_player_vehicle_human.md) registers
this component (hash `0xA364FC7D`, registrar `FUN_00645720`, producer `FUN_00667210`) and states
plainly that it **"exposes no scalar schema (runtime rebuild pass only)… zeroes an inline 11-dword
struct"** — i.e. the field layout is *not* recoverable from the reflection path. It is recoverable
from three other places, and this section uses all three: the **container descriptor** for the size
(§2.0), the **Xbox debug-dump literal pool** for the field names, and the **cfunc + mutator bodies**
for the offsets (§2.1). ecs-04's "11-dword" turns out to be the exact answer — see §2.1.

Resolve idiom, present in every one of the 9 cfuncs:

```asm
mov  eax, <guid>            ; the character GUID from Lua arg 1
mov  ecx, 0x17BF3D8         ; ★ the RuntimeInventory container
call 0x5857E0               ; FUN_005857E0 — generation-checked paged handle lookup
test eax, eax               ; 0 => no inventory on this entity
```

**The ECX constant is the identity.** `0x017BF3D8` = `RuntimeInventory`; `0x017BCDB8` =
`Equipment`; `0x017BEC08` = `RuntimeWeapon` (weapons map). Reading which container a body puts in
ECX is how each offset below is attributed.

### 2.0 Containers, named from the binary — and the stride measured, not inferred

Every ECS container in this engine self-describes, on two independent axes.

**Name.** `[container+0x00]` is its vtable, and **`[vtable+0x34]`** is a two-instruction accessor
**`B8 <char* imm32> C3`** (`mov eax,<name>; ret`). The `B8 … C3` byte shape is the check — if the
target is anything else, `+0x34` is not a name accessor for that class and the answer is not a name.

**Size.** The shared lookup `FUN_005857E0` reads the container's descriptor at `container+0x18`:

```asm
005857ED  lea   edi, [ecx+0x18]        ; descriptor = container + 0x18
00585808  mov   eax, [edi+0x10]        ; capacity
0058580B  mov   cl,  [edi+0x0E]        ; shift
00585815  movsx edx, word ptr [edi+0x0C] ; STRIDE
```

So `container+0x24` is a **packed dword** — `shift` in the high 16 bits, **`stride` in the low 16**.

⚠ **The descriptor sits at a different offset in the two container classes, and getting this wrong
silently returns a plausible-looking number.** Containers live in two arrays with different strides:

| Class | Example array | capacity at | FNV seed `0x9E3779B9` at | name ptr at |
|---|---|---|---|---|
| **`0x80`-stride** | `RuntimeEquipmentLink`, `RuntimeTurret`, `RuntimeVehiclePart` | **`+0x20`** | `+0x28` | — |
| **`0x50`-stride** | `RuntimeInventory`, `Equipment`, `RuntimeWeapon`, `HumanInventory` | **`+0x28`** | `+0x2C` | `+0x3C` |

**The seed is the self-locating landmark**: find `0x9E3779B9`, and the capacity is the dword eight
bytes before it. With the right offset the identity **`capacity == 2^shift`** holds for *both*
classes, which makes the read self-checking — **a failure means you used the wrong class's offset,
not that you found an exception.**

| Container | `[vtable+0x34]` | Name | `+0x24` packed | **stride** | shift | capacity | `cap==2^shift` |
|---|---|---|---|--:|--:|--:|:-:|
| `0x017BF3D8` | `0x006457D0` | **`RuntimeInventory`** | `0x00060030` | **`0x30`** | 6 | `0x40` @`+0x28` | ✔ |
| `0x017BCDB8` | `0x00667200` | **`Equipment`** | `0x00050020` | `0x20` | 5 | `0x20` @`+0x28` | ✔ |
| `0x017BEC08` | `0x00648C50` | `RuntimeWeapon` | `0x00060034` | `0x34` | 6 | `0x40` @`+0x28` | ✔ |
| `0x017BDE48` | `0x006427E0` | `HumanInventory` | `0x0003001C` | `0x1C` | 3 | `0x8` @`+0x28` | ✔ |
| **`0x00DF9510`** | `0x00645710` | **`RuntimeEquipmentLink`** — the carry relation | `0x0008000C` | `0x0C` | 8 | `0x100` **@`+0x20`** | ✔ |
| `0x017BF928` | `0x00646530` | **`PhysicsActorRagdoll`** | — | `0x04` | — | — | — |
| `0x017C02D8` | `0x00648C10` | **`SceneObject`** | — | `0x1C` | — | — | — |
| `0x017BD1C8` | `0x0066B700` | `Ai` | — | `0x30` | — | — | — |
| `0x017BC778` | `0x00666000` | `WeaponProjectileBase` | — | `0x28` | — | — | — |

> **Correction to record.** An earlier revision of this section claimed the self-check "does not
> hold for `RuntimeEquipmentLink`, because relation containers are a different descriptor class".
> That was an **offset error, not an exception**: `0x00DF9510` is in the `0x80`-stride array, so
> `+0x28` there is the FNV **seed** `0x9E3779B9`, which got misread as a capacity. Read `+0x20` and
> it is `256 == 2^8`. ✔ Its 0x80-class neighbours `RuntimeTurret` (`64`), `RuntimeDebrisEffect`
> (`8`), `RuntimeClaimCover` (`16`) all check out the same way. There is no relation-container
> exception.

### ⚠ Capacity and shift are RUNTIME state; only the stride is static

This matters for anyone re-deriving these numbers from a different image. Comparing the live dump
against the clean on-disk `mercs2_nodrm_v3.exe`, the `.data` descriptors **do not agree** — because
in a clean image the registrars have not run yet. For the `0x50`-class containers the whole packed
dword at `+0x24` reads **`0`** on disk. So a clean image is *not* a place to read any of this.

The authoritative source is the **registrar's immediate in `.text`**, and that is genuinely static:

```asm
; FUN_00645720 — the RuntimeInventory registrar
00645782  mov word ptr [0x017BF3FC], 0x30    ; ★ STRIDE — a static immediate, written once
0064578B  mov word ptr [0x017BF3FE], 8       ;   shift  — merely SEEDED here (live dump reads 6)
00645794  mov dword ptr [0x017BF400], ecx    ;   capacity = 0x100 seeded (live dump reads 0x40)
0064579A  mov dword ptr [0x017BF404], 0x9E3779B9   ; the seed landmark, +0x2C ⇒ 0x50 class
006457B9  mov dword ptr [0x017BF414], 0x00BC5974   ; +0x3C = "RuntimeInventory"
```

`FUN_006400F0` does the same for `Equipment` (`mov word [0x017BCDDC], 0x20` @`0x0064014D`). So:

- **Stride is static and never changes** — registrar immediate, live dump, and `FUN_005857E0`'s
  multiplier all agree. Safe to state as primary evidence.
- **Capacity and shift are live, mutable state** — the container grows during a run. The registrar
  *seeds* `RuntimeInventory` at `cap 0x100 / shift 8`; the dump observes `0x40 / 6`. Both satisfy
  `cap == 2^shift`, which is exactly what makes it an invariant worth checking rather than a
  constant worth quoting. **Cite dump capacities as observations from one run, never as the
  engine's declared limit.**

Two consequences worth stating. **(1)** `RuntimeInventory`'s stride `0x30` is the **engine's own
declared element size**, backed by a static immediate at `0x00645782` *and* the live descriptor —
whereas earlier revisions of this map derived it as "largest observed offset `+0x2C` + 4", which is
circular if the layout is what you are trying to establish. §2.1's eleven-dword layout is therefore
*corroborated by* the stride, not the source of it. **(2)** The last four rows were listed
as *unknown containers* in earlier revisions (a "carry relation" with no name, and two containers
`DropWeapon` touches). They are named. The `+0x3C` name-pointer route that works on component
containers returns nothing for **relation** containers like `0x00DF9510`, which is why the name was
missed; `[vtable+0x34]` works on both. Corroboration for the two `DropWeapon` ones from the
registrars: `FUN_00646480` writes `PTR_s_PhysicsActorRagdoll_017bf964` and `FUN_00648850` writes
`PTR_s_SceneObject_017c0314`, i.e. `+0x3C` of each container; both also appear in
[`../mercs2-ecs/03_controllers_physics.md`](../mercs2-ecs/03_controllers_physics.md):85 and
[`../mercs2-ecs/06_world_terrain_roads_streaming.md`](../mercs2-ecs/06_world_terrain_roads_streaming.md):70.

### 2.1 The eleven-dword record

The Xbox debug dump's literal pool
(`output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt:3038-3047`, emitted in **reverse**)
carries the field list. Read bottom-up it is:

```
iEquippedPrimaryGuid · iEquippedSecondaryGuid · iEquippedVehicleWeaponGuid ·
iLastEquippedPrimaryGuid · iLastEquippedSecondaryGuid · iLastLastEquippedSecondaryGuid ★ ·
iEquipmentWaitingForPickupGuid · iAmmoProp ★ · iWeaponInUse · uiCurrentEquipAction ★
      … then one packed line: "bSwitchingPrimary=%s eWeaponVisibility=%s bEquipping=%s bLocked=%s"
```

★ = three fields **no doc in this repo previously recorded**, including
`weapons-combat.md`'s own summary line. Joining that run positionally against the PC evidence:

| Off | Field | Read from (PC) | Conf |
|---|---|---|---|
| **`+0x00`** | **equipped primary** weapon GUID | `GetPrimaryWeapon` `0x005BEA61`; written by `FUN_00527730`, read by `FUN_00527540` | H |
| **`+0x04`** | **equipped secondary** weapon GUID | `GetSecondaryWeapon` `0x005BEBE1`; rotated by `FUN_00527C70` | H |
| **`+0x08`** | **equipped vehicle/mounted** weapon GUID | `GetVehicleWeapon` `0x005BED4D` (`mov edi,[eax+8]` → push, no fallback) | H |
| **`+0x0C`** | **last-equipped primary** (the other primary slot) | `GetPrimaryWeapon` fallback `0x005BEA67`; `Human.EquipWeapon` writes it (`piVar3[3] = weapon`) then draws | H (offset) / M (name) |
| **`+0x10`** | **last-equipped secondary** | `GetSecondaryWeapon` fallback `0x005BEBE8`; `Human.EquipWeapon` writes `piVar3[4]`; rotated by `FUN_00527C70` | H (offset) / M (name) |
| **`+0x14`** | **last-*last*-equipped secondary** — the third rung of the secondary carousel | `FUN_00527C70` rotates `+0x04 ← +0x10 ← +0x14`; `FUN_0052A3B0` `0x0052A47E` does `[+0x14] = [+0x04]; [+0x04] = new` (a push-down, gated on carry-edge bit `0x02` at `0x0052A475`) | H (semantics) / M (name) |
| **`+0x18`** | **equipment waiting for pickup** (GUID) | `FUN_0051B1E0`: record into EBX at `0x0051B44B-55` (`mov ecx,0x17BF3D8; call 0x5857E0; mov ebx,eax`), then `mov ebx,[eax+0x18]` @`0x0051B947` used as a GUID against `0x00DF9510`, and zeroed `mov dword [edx+0x18],0` @`0x0051B972` | H (offset) / M (name) |
| **`+0x1C`** | ammo prop (`iAmmoProp`) | `FUN_0051B1E0` `0x0051B45F` (`mov eax,[ebx+0x1C]`, three instructions after the container lookup — unambiguous); also `FUN_00519540`, `FUN_0069E7A0` | H (offset) / M (name) |
| **`+0x20`** | the **mounted/emplaced weapon currently in use**; non-zero ⇒ the human is on a turret and every loadout mutator first detaches via `FUN_0051DFA0(+0x20, DAT_00DFDB5C, 0)`. `FUN_005BE050`'s enable path zeroes it | `FUN_00527950`, `FUN_00527C70`, `FUN_005283F0`, `SetAllWeapons` `0x005BF374`, `.securom 0x0246BF5A` | H (offset) / M (name) |
| **`+0x24`** | **current equip action** — a pending-action dword: set by the draw path, tested and cleared by the equip tick | written `FUN_00527730` `0x00527842` (`mov [edi+0x24],ebx`); read+cleared `FUN_0051C200` `0x0051C2B2`/`0x0051C2D4`, `FUN_0051D9D0` `0x0051DA4A`/`0x0051DA59`; gated on by `FUN_00527950` `0x005279D7`; `FUN_00529DB8` `0x00529E40` | H (offset) / M (name) |
| **`+0x28`** | **weapon visibility** (enum-valued) | `FUN_0051C140` `0x0051C1DB` — `cmp dword [edi+0x28], eax` immediately after the `bLocked` gate, with `cmp eax,2` on the next branch; also `FUN_006A1160` | H (offset) / M (name) |
| **`+0x2C`** | **flags byte.** `& 0x08` ⇒ **locked: every mutator returns false immediately**. `\| 0x04` set while a draw is in flight; `\| 0x02` set while a holster/swap is in flight; both cleared on failure (`&= 0xF9`) | 19 gate sites, §2.2 | H (bits) / M (names) |

**Eleven dwords `+0x00 … +0x28`, plus the flags dword at `+0x2C`.** The record size is **`0x30` on the engine's own
authority** — the registrar's static immediate at `0x00645782`, agreeing with the live descriptor
(§2.0) — so the layout has to close inside `0x30` and it does — **with no unaccounted offset**. That is also exactly
what `ecs-04`'s otherwise-unexplained *"zeroes an inline **11-dword** struct"*
([`04_player_vehicle_human.md`](../mercs2-ecs/04_player_vehicle_human.md):119-124) was saying. The
old `+0x2C + 4` arithmetic is demoted to corroboration; it was never evidence, because it presumed
the layout it was being used to close.

> **Correction to record.** Earlier revisions of this map named `+0x14`
> `iEquipmentWaitingForPickupGuid` (taking it as the 6th GUID of what was believed to be a six-GUID
> Xbox run) and did not list `+0x18` or `+0x1C` at all. Both are wrong. The Xbox pool has a
> **seventh** GUID, `iLastLastEquippedSecondaryGuid`, sitting between the two — and the PC side
> settles it independently: a slot that `FUN_00527C70` **rotates through on every secondary swap**
> cannot be a pickup holding-pen. The pickup slot is `+0x18`.
>
> ⚠ Honesty note: the Xbox→PC join is **positional** (M) for all of the *names*. What is **proven**
> on the PC side (H) is the `+0x14` rotation semantics, and those are flatly incompatible with the
> old name. Also retracted: a `+0x26` field. `+0x26` and `+0x32` are read inside `FUN_00527C70`,
> `FUN_005283F0` and `FUN_0052A3B0`, but on the **`RuntimeWeapon`** record (`0x017BEC08`), not this
> one; a container-scoped taint finds zero `+0x26` accesses on `RuntimeInventory`.

### 2.2 The `bLocked` gate — `FUN_005BE050`'s body, and the 19 functions it disables

**The `bLocked` bit is the whole point of `Human.DisableWeapons`.** That cfunc (`0x005BE230`, 25
base-game call sites, the highest-traffic `Human.*` binding) is `FUN_005BE050(L, 0)`;
`EnableWeapons` (`0x005BE220`) is the same body with `1`. Both stubs are 15 bytes and pass **two
stack args**:

```asm
005BE220  mov eax,[esp+4] ; push 1 ; push eax ; call 0x5BE050 ; add esp,8 ; ret   ; EnableWeapons
005BE230  mov eax,[esp+4] ; push 0 ; push eax ; call 0x5BE050 ; add esp,8 ; ret   ; DisableWeapons
```

`FUN_005BE050` has no Ghidra body: it is `jmp dword ptr [0x02458448]`, and the resolved slot
(`0x024E6250`) is a SecuROM **VM stub** (`push 0x024E625A; call 0x01AAFF10`). The **relocated
plaintext body is in `.securom` at `0x0246BDF7–0x0246C054`** — ordinary x86, blocks shuffled and
joined by the `push <ret>; push <target>; ret` idiom. It is unambiguously this cfunc:

```asm
0246BEF4  mov  ecx, 0x17BF3D8              ; ★ RuntimeInventory
0246BEF9  push 0x0246BF07 ; jmp 0x5857E0   ; == call FUN_005857E0
0246BF0F  mov  eax, 1 ; mov ecx, ebx       ; ★ EBX = lua_State*
0246BF1B  jmp  0x0085D5D0                  ; ★ FUN_0085D5D0 — this map's own "reserve" helper
0246BF3B  mov  dword [ecx+4], 0 ; add dword [ebx+8], 8   ; ★ push nil, the "*(L+8) += 8" idiom
0246BF52  and  byte [esi+0x2C], 0xF7       ; ★★ CLEAR bit 3   (enable)   bytes: 80 66 2C F7
0246BF56  cmp  byte [ebp+0x0C], 0          ; ★ the SECOND stack arg (ebp+8 = L, ebp+0xC = bEnable)
0246BF5A  mov  dword [esi+0x20], eax       ; also zeroes the in-use weapon (eax == 0)
0246BF8F  cmp  dword [esi+4], 0 ; mov edx,[esi+0x10] ; jmp 0x00527C70   ; enable: re-equip the
                                            ;   last-equipped secondary if none is equipped
0246BFDE  or   byte [esi+0x2C], 8          ; ★★ SET bit 3     (disable)  bytes: 80 4E 2C 08
0246C008  mov  dword [eax], 1 ; mov dword [eax+4], 1        ; push boolean TRUE
```

**Reproduce in one step:** the four bytes at file offset `0x0206BF52` are `80 66 2C F7` and at
`0x0206BFDE` are `80 4E 2C 08`. Everything else follows from disassembling forward from there.

> **Correction to record.** An earlier identification of `FUN_005BE050`'s body as **`0x006FC560`**
> is wrong and must not be carried forward. That was a *uniqueness* argument (sole writer of the
> bit found by a `.text`-only scan), and it picked the wrong one of two near-clones.
> `0x006FC560` takes **`EDI` = the character handle in a register** and `[esp+0xC]` = `bEnable`,
> with **no `lua_State` and no Lua traffic at all** — it cannot be the callee of a stub that pushes
> `(L, bEnable)`. It also lacks the secondary re-equip step. It is a **sibling native**, best read
> as `SetWeaponsEnabled(EDI = char, bEnable)`: same container, same bit, same polarity, same
> `FUN_00529C00`/`FUN_00527870`/`FUN_00527670` callees, minus the Lua wrapper. Image-wide, those
> two functions are the **only** writers of this bit (`.text 0x006FC576`/`0x006FC5B0` and
> `.securom 0x0246BF52`/`0x0246BFDE`); no `or dword`/`and dword`/`xor` variant exists on this offset
> for this container.

So the claim *"`+0x2C & 8` is the bit `DisableWeapons` writes"* is now **H — read from a body**, not
confirm-live. Two behaviours the old M-level reading did not have: **`EnableWeapons` is not a pure
flag clear** — it also zeroes `+0x20` and, when `+0x04` is empty, re-equips the last-equipped
secondary through `FUN_00527C70`; **`DisableWeapons` routes through `FUN_00527670`** (holster).
Both push `true`; both push **nil** when the character has no `RuntimeInventory`.

**How many mutators the bit gates: exactly 19.** Enumerate every `test byte ptr [reg+0x2C], 8` in
the *whole image* by byte pattern `F6 <ModRM 0x40–0x47> 2C 08`, verify each is a real instruction
boundary, then attribute the tested register to a `RuntimeInventory` record. **21 raw sites, 19 on
this record, one gate per function.** Alternative encodings were ruled out by scanning for
`test byte [r+disp32],8` and `test dword [r+0x2C],8`: **zero hits each.**

| # | Gate | Function entry | Note |
|--:|---|---|---|
| 1 | `0x004EAB55` | `0x004EAB30` | no Ghidra fn; obfuscated `push ret; jmp 0x5857E0` |
| 2 | `0x0051C1D5` | `FUN_0051C140` | |
| 3 | `0x0051D91D` | **`FUN_0051CFF0`** | the weapon-system tick. **Container lookup is INLINED** — the body contains neither `mov ecx,0x17BF3D8` nor `call 0x5857E0`; it references container internals `0x017BF3FE` @`0x0051D53C` and `0x017BF410` @`0x0051D544`. Invisible to any `mov ecx,imm` scan |
| 4 | `0x0051DFE5` | `FUN_0051DFA0` | |
| 5 | `0x00527561` | `FUN_00527540` | |
| 6 | `0x00527693` | `FUN_00527670` | |
| 7 | `0x00527751` | `FUN_00527730` | |
| 8 | `0x00527891` | **`0x00527870`** | Ghidra invents an entry at `0x00527882`; the real entry is `0x00527870`, which tail-jumps to `0x0050CCDC` and returns into the `call 0x5857E0` Ghidra mistook for a function start |
| 9 | `0x00527973` | `FUN_00527950` | |
| 10 | `0x00527AB3` | `FUN_00527A90` | |
| 11 | `0x00527B6D` | `FUN_00527B50` | |
| 12 | `0x00527C91` | `FUN_00527C70` | |
| 13 | `0x0052840F` | `FUN_005283F0` | the one on the `SetAllWeapons` path |
| 14 | `0x00529DDC` | `FUN_00529DB8` | |
| 15 | `0x0052A3DB` | `FUN_0052A3B0` | |
| 16 | `0x005AD5DB` | **`0x005AD5C6`** | no Ghidra fn; entry does `mov ecx,0x17BF3D8; call 0x5857E0` @`0x005AD5CD` |
| 17 | `0x0061A918` | `0x0061A8E0` | obfuscated `push ret; push 0x5857E0; ret`; Ghidra under-reports `size=48` |
| 18 | `0x006F9606` | **`FUN_006F9260`** | a **second loadout-apply path**: also requires `+0x20 == 0`, then `call 0x528170` + `call 0x6F8EF0` |
| 19 | `0x02466BD2` | **`.securom 0x02466BA0`** | relocated body; `mov ecx,0x17BF3D8` @`0x02466BA7`. Invisible to any `.text` scan |

**Excluded (2):** `0x00816E24` (`FUN_00816E08`) and `0x008182A2` (`FUN_008181B0`). Both test
`+0x2C & 8` on a **different struct** — the surrounding code is `[r+0x1C] vs [r+0x20]`,
`[r+0x24] vs [r+0x28]`, then `shr 0xA` / `and 0x3FF` / `movss`, i.e. a paged float table.

> **Correction to record.** Earlier revisions named **six** gated mutators (`FUN_00527950`,
> `FUN_00527730`, `FUN_00527540`, `FUN_00527C70`, `FUN_00527B50`, `FUN_005283F0`). All six are
> real and re-verified above, but they are a **subset**, and the three that matter most for a
> reimpl are the three no `mov ecx,imm`-based `.text` scan can find: `FUN_0051CFF0` (inlined
> lookup), `FUN_006F9260` (the second loadout path) and `.securom 0x02466BA0`.

**A disabled human silently rejects every equip, stow, give and loadout write**, returning `false`
to Lua — the gate always early-outs to the function epilogue (e.g.
`0x00527561: test byte [edi+0x2C],8 ; jne 0x527613`). It matters because the shipped mission
pattern is `SetAllWeapons(...)` *then* `DisableWeapons(...)` (§7.2); the reverse order would no-op
the loadout, via the chain `SetAllWeapons → FUN_006F8EF0 → FUN_005283F0` (gated at `0x0052840F`).
Note `SetAllWeapons` itself carries **no** gate — the gate is one call deeper.

---

## 3. The weapon side — `Equipment` `0x017BCDB8` and the carry relation `0x00DF9510`

### 3.1 `Equipment` — the slot-class tag — H

ecs-04 gives the schema: **stride `0x20`**, ordered fields `enum EquipmentTypeEnum (default
Primary)`, 6 × int, 1 × bool/short; strings `s_EquipmentTypeEnum_00BC67AC` / `s_Primary_00BC6798`;
**`EquipmentTypeEnum { Primary = 0, Secondary = 1 }`**.

**The values are proven from the PC binary, with no dependence on ecs-04.** The reflection
registration sits inside the whole-file enum initialiser `FUN_0064AC50`:

```asm
0064AC66  mov  ebp, 1                  ; ★ the ONLY write to EBP in 0x0064AC50–0x0064C4A0
0064AC7C  mov  edi, 2                  ; ★ the ONLY write to EDI in that range
0064AC9E  xor  ebx, ebx                ; ★ the ONLY write to EBX in that range
…
0064C42C  mov  eax, 3 ; mov edx, 8 ; mul edx        ; allocate 3 × 8  (N+1 slots)
0064C44A  mov  edx, 0x00BC6798  "Primary"   → member[0].name ; member[0].value = EBX = 0
0064C454  mov  dword [0xEDC6CC], edi                ; ★ member COUNT = EDI = 2
0064C470  mov  edx, 0x00BC67A0  "Secondary" → member[1].name ; member[1].value = EBP = 1
0064C489  push 0x00BC67AC       "EquipmentTypeEnum"
0064C491  mov  dword [0xEDC6D0], edi                ; = 2
0064C497  call 0x00655F40                           ; register
```

The single-write claim is a mechanical result: a capstone sweep over `0x0064AC50–0x0064C4A0`
reports exactly one write to each of EBX/EBP/EDI, at the three addresses above. The control case is
the very next enum in the same initialiser (`0x0064C49C`, `mov eax,4`, three members
`Automatic`/`SemiAutomatic`/`Burst`) which writes its count as the **immediate 3** — confirming
that `[0xEDC6CC]`/`[0xEDC6D0]` is the member count and therefore that `EDI = 2` here.
**`EquipmentTypeEnum = { Primary = 0, Secondary = 1 }`, exactly two members. H.**

> **Correction to record.** Earlier revisions offered `Weapon.IsPrimary`'s `sete` as the proof.
> That was **insufficient**: `sete` on `cmp [rec],0` establishes only `Primary == 0`, and there is
> **no `IsSecondary`** in the `Weapon` table (`0x00B98860`, 9 entries) to complete the pair. The
> registration above is the real proof; `IsPrimary` is corroboration.

`Weapon.IsPrimary` (`FUN_005EAC60` — the `Weapon` namespace, owned by
[`weapons_combat_code_map.md`](weapons_combat_code_map.md), cited here only for the field join;
it too has no Ghidra body and was disassembled):

```asm
005EACCC  mov  ecx, 0x17BCDB8         ; ★ Equipment container
005EACD1  call 0x5857E0
005EACFB  cmp  dword ptr [eax], 0     ; ★ EquipmentTypeEnum
005EAD02  sete dl
005EAD05  push edx                    ; → FUN_004B86E0, push boolean
```

So `IsPrimary(w) ⟺ Equipment(w).type == 0`. **Five of the nine `Human.Inventory` cfuncs branch on
this same dword** — `GetPrimaryWeapon` `0x005BEAC0` matches `== 0`, `GetSecondaryWeapon`
`0x005BEC3B` matches `== 1`, `GetAllWeapons` `0x005BEEAE` partitions on `== 0`, `SetAllWeapons`
`0x005BF324` buckets on `== 0`, `EquipWeapon` `0x005BF59A` dispatches on `== 0` (and
`Human.EquipWeapon` `0x005BE417` in the sibling table). The enum *is* the loadout taxonomy.

Note the consequence: **"primary vs secondary" is a property of the item, not of the slot it went
into.** A script cannot put a Secondary-tagged item into the primary chain.

### 3.2 The carry relation — `RuntimeEquipmentLink` `0x00DF9510` — H

Weapons are **child entities**, and "who is carrying what" is a separate relation container. Its
registered name is **`RuntimeEquipmentLink`** (`[vtable+0x34]` → `0x00645710` =
`mov eax, 0x00BC595C; ret`, §2.0) and its registered element size is **12 bytes per edge**
(packed descriptor `0x0008000C` @`0x00DF9534`; it is an `0x80`-class container, so its capacity `0x100 == 2^8` reads at `+0x20`, §2.0), consistent with a record `{+0x00 obj, +0x04 obj2, +0x08 flags}`. Three entry
points, all read first-hand:

- `FUN_006499F0(&PTR_PTR_00DF9510, 0, 1)` — construct an iterator rooted at the GUID in EAX. The
  third argument selects the index: `1` → `container+0x34`, `0` → `container+0x50`. Both
  `GetPrimaryWeapon`/`GetSecondaryWeapon`/`GetAllWeapons` pass `1`, i.e. **iterate by parent**;
  the `+0x50` index is the reverse (by-child) direction. (Bidirectional-relation shape: **M**.)
- `FUN_00649A80(&it)` — advance; on exhausting a node it follows `record+0x14` to continue up a
  chain, so nesting is walked.
- `FUN_00649440(eax = 0x00DF9510, ecx = weapon, arg = human)` — find the single edge record for a
  (human, weapon) pair. `FUN_005283F0` calls exactly this immediately after attaching a weapon, and
  branches on the result being null vs. existing — which is what pins the container's meaning.

**Per-edge flag byte at `record+0x08`:**

| Bit | Observed use | Read from | Conf |
|---|---|---|---|
| `0x01` | **this edge is the equipped one** — `GetAllWeapons` pushes it *first*; `FUN_005283F0` uses it to decide equip-vs-stow for an already-attached weapon | `GetAllWeapons` `0x005BEED8` (`test byte ptr [esi+8], 1`), `FUN_005283F0` `0x005284E3`/`0x00528540` | H |
| `0x02` | entries with this bit are **excluded** when `GetAllWeapons`' 2nd arg is true; short-circuits the holster path to `FUN_00527670`; gates `FUN_0052A3B0`'s secondary push-down | `GetAllWeapons` `0x005BEE8F` (`test byte ptr [esi+8], 2`; `0x005BEE95` compares the arg-2 byte), `FUN_00527540` `0x005275E2`, `FUN_0052A3B0` `0x0052A475` | H (behaviour) / **open** (meaning) |
| `0x04` | read by the swap before rotating (`bVar6 = rec[8] >> 2 & 1`) | `FUN_00527C70` | M |
| `0x08` | set by `FUN_0051DFA0` on the detach path | `FUN_0051DFA0` | M |

**Who writes the bits.** `FUN_006FC280` (87 B, single caller `0x0069D1CB`) is the **only** function
that writes bit `0x02`: `or byte [edi+8],2` @`0x006FC2A5` when a second object accessor returns
non-null, and `and byte [edi+8],0xFD` @`0x006FC2C0` when it returns null — in which case it instead
writes `[edi+4] = *FUN_006D3A10()`. It also derives bit 0 from `[obj+0x2C] & 1`, bit 2 from
`[obj2+0x2C] << 2`, and stamps `[edi] = 3`. **So bit `0x02` tracks the presence of the edge's
`+0x04` second object.** Bit 0 is additionally written by `FUN_0052A3B0` (`|1` @`0x0052A4E0`,
`&0xFE` @`0x0052A46E`/`0x0052A4B3`) and `FUN_00667210` (`&0xFE` @`0x00667366` — the
`RuntimeInventory` rebuild pass clears it). Bits `0x04`/`0x08` have **no writer** in the image other
than `FUN_006FC280`'s derived bit 2 and `FUN_0051DFA0`'s detach path, i.e. they are read-only in
practice — which is why they stay at M.

The only shipped caller that passes `true` for arg 2 is the **save** path (`mrxplayer.lua:666`,
`:702`); `hero.lua`, `soldier.lua` and all mission scripts pass nothing. So bit `0x02` marks weapons
a save is meant to *skip*. **What `+0x04` actually is** — a mount point, an attachment socket, or a
second participant entity — is the residual **open** item (§9.1); the writer is located, the
meaning of the thing it tracks is not.

---

## 4. The nine cfuncs

All addresses verified present in the image. **⬤ = Ghidra body read · ◐ = no Ghidra function,
disassembled here from `mercs2_unpacked.exe`.** `calls` = `corpus_calls` (base + DLC Lua), §8.

| # | Name | VA | | calls | One line |
|--:|---|---|:-:|--:|---|
| 0 | `GetPrimaryWeapon` | `0x005BE9B0` | ⬤ | 11 | `+0x00` ?: `+0x0C` ?: first attached `Equipment.type==0` |
| 1 | `GetSecondaryWeapon` | `0x005BEB30` | ⬤ | 6 | `+0x04` ?: `+0x10` ?: first attached `Equipment.type==1` |
| 2 | `GetVehicleWeapon` | `0x005BECB0` | ◐ | 0 | `+0x08`, no fallback |
| 3 | `GetAllWeapons` | `0x005BED60` | ⬤ | 32 | one **table**, equipped-first, ≤6 per class |
| 4 | `SetAllWeapons` | `0x005BF160` | ⬤ | 34 | destroy-all, then apply **≤2 primary + ≤2 secondary**; accepts a table **or** bare GUIDs (§4.5) |
| 5 | `DropWeapon` | `0x005BF420` | ◐ | 17 | `FUN_00528250(char, weapon)` → boolean |
| 6 | `EquipWeapon` | `0x005BF4E0` | ⬤ | 4 | class-dispatch → `FUN_00527950` / `FUN_00527C70` |
| 7 | `ReloadAll` | `0x005BF6B0` | ⬤ | 3 | **requires 2 args**; `FUN_0051FC40` |
| 8 | `DestroyAllWeapons` | `0x005BF630` | ◐ | 0 | `FUN_00528170` (split thunk; body recovered in `.securom`, §4.9); **returns 0 values** |

Shared cfunc mechanics (identical to the `Player` cluster): args via `FUN_0059FF50` (GUID /
lightuserdata, tag 2 — also accepts tag 7 and adds `+0x18`) and `FUN_0059F6D0` (boolean, accepts
nil); results via `FUN_0085D5D0` (reserve) + the `*(L+8) += 8` push idiom; `FUN_004B1270` pushes a
GUID-or-nil; `FUN_004B86E0` pushes a boolean; `FUN_004B2A50` raises.

### 4.1 `GetPrimaryWeapon(uChar)` — `0x005BE9B0`, 373 B — H

```c
h = RuntimeInventory[uChar];        if (!h) return nil;
if (h[0x00]) push(h[0x00]);                       // equipped primary
else if (h[0x0C]) push(h[0x0C]);                  // last-equipped primary
else { for (w : carried(uChar)) if (Equipment[w].type == 0) { push(w); return; }  push(nil); }
```

The third arm is a full walk of the carry relation. **Returns 1 value: a GUID or nil.**

### 4.2 `GetSecondaryWeapon(uChar)` — `0x005BEB30`, 373 B — H

Byte-for-byte the same shape reading `+0x04` / `+0x10`, and the scan matches
`Equipment[w].type == 1`. That the two functions differ only in `{+0x00,+0x0C, ==0}` vs
`{+0x04,+0x10, ==1}` is the can't-coincide evidence for both the field pairing and the enum values.

### 4.3 `GetVehicleWeapon(uChar)` — `0x005BECB0`, ~176 B — ◐ H

Recovered by disassembly (no Ghidra function). Full body: arg check → `FUN_0059FF50` →
`FUN_005857E0(ecx=0x17BF3D8)` → `mov edi, [eax+8]` → `FUN_004B1270` (push GUID or nil). **No
last-equipped fallback and no relation scan** — a mounted weapon has no "other slot". **Zero shipped
call sites** in either script corpus.

### 4.4 `GetAllWeapons(uChar [, bExcludeFlagged])` — `0x005BED60`, 1017 B — H

The richest body in the namespace, and the one every save/restore and "take the player's guns away"
mission depends on.

```c
if (!arg1 guid) { push nil; return 1; }
bExclude = arg2 (boolean, defaults to false if absent — FUN_0059F6D0 result < 1 ⇒ '\0')
int prim[6] = {0}, sec[6] = {0};  int iPrimEquipped = -1, iSecEquipped = -1;
for (w, edge : carried(uChar)) {                  // iterator over 0x00DF9510, by-parent index
    if ((edge[8] & 2) && bExclude) continue;      // ★ the filter
    e = Equipment[w]; if (!e) continue;
    bucket = (e.type == 0) ? prim : sec;          // ★ EquipmentTypeEnum
    k = 0; while (bucket[k] != 0) k++;            // ⚠ NO UPPER BOUND — see below
    bucket[k] = w;
    if (edge[8] & 1) <bucket>Equipped = k;        // ★ remember the equipped one
}
push(prim[iPrimEquipped]); clear it;   for (i<6) if (prim[i]) push(prim[i]);
push(sec[iSecEquipped]);   clear it;   for (i<6) if (sec[i])  push(sec[i]);
FUN_005A1270(nPushed, &L);                        // ★ pack the N values into ONE table
return 1;
```

Four things worth stating explicitly, all read first-hand:

1. **It returns exactly one Lua value — an array table.** The function pushes N loose values and
   then calls `FUN_005A1270(N, &L)`, whose body is `lua_createtable(L, N, 0)`, `FUN_005A0370`
   (insert the new table below the N values), then `N` × `rawseti` counting **down** from `N` to
   `1`. Push order is therefore preserved as array order, and `return 1` (`mov eax,1` at
   `0x005BF14E`) is the literal epilogue. This is why `for i, w in pairs(tWeapons)` works.
2. **Ordering is meaningful: the equipped weapon of each class is index 1 / index k+1.** A reimpl
   that returns an unordered set will silently change `SaveSingleton`/`LoadSingleton` round-trips,
   which index the result positionally (§7.3).
3. **6 slots per class ⇒ ≤12 returned — and the fill loop is unbounded.** ⚠ The frame geometry is
   read from the **prologue's zero-run**, not inferred from the `lea`s: before the three pushes that
   set up the iterator call, `0x005BEE0B`–`0x005BEE37` zeroes exactly **twelve** consecutive dwords
   (`[esp+0x2C]` … `[esp+0x58]`) and `0x005BEE07` does `lea esi,[esp+0x5C]` — the iterator struct,
   four bytes past the end of the twelve. In loop-frame terms (`FUN_006499F0` pops its 3 args) that
   is: **primary bucket `esp+0x20`, secondary bucket `esp+0x38`, six dwords each, iterator
   `esp+0x50`**, with the two equipped-indices at `esp+0x18`/`esp+0x1C` (initialised to `-1` by
   `or eax,0xFFFFFFFF` @`0x005BEDF0`, stored `0x005BEDF6`/`0x005BEDFA`). The free-slot search at
   `0x005BEED0`–`0x005BEED6` is `add eax,1 / cmp [ecx+eax*4],edi / jne` — `while (bucket[k] != 0)
   k++;` with **no bound check** — and the store at `0x005BEEE0` is `mov [ecx + eax*4], edx`. So a
   **7th primary writes `esp+0x20 + 6*4 = esp+0x38` = `sec[0]`**, and a **13th carried weapon writes
   `esp+0x20 + 12*4 = esp+0x50` = the live iterator** — a stack smash inside the loop that is
   walking it. Corroborated by Ghidra's own frame model (`local_58[13]`, with `local_58[0xC]` passed
   to `FUN_00649A80`, and emit loops bounded at `< 6`). Retail can never reach this (the writer
   caps at 4, §4.5) but nothing in the *reader* enforces it: a mod that attaches weapons by another
   route can corrupt this call. Recorded as a latent bug, not a reproduced one (**H** on the code
   shape, **untested** as a crash — §9.3 item 4).
4. The 2nd argument defaults to **false** here — unlike `ReloadAll` (§4.8), which does *not*
   default. The filter is a **conjunction**: `test byte [esi+8],2` @`0x005BEE8F` **and**
   `cmp byte [esp+0xE],0` @`0x005BEE95` — bit set *and* arg 2 true ⇒ skip.

### 4.5 `SetAllWeapons(uChar, …)` — `0x005BF160`, 697 B — H

The only loadout **writer**, and the highest-traffic binding in the namespace (34 sites).

**Its argument shape is not `(char, table)` — it is four optional scalars followed by an optional
table.** Read at `0x005BF164`–`0x005BF305`; the four bucket slots are pre-filled positionally before
the table is even looked for. Writing `F` for the frame after the prologue's four register pushes:

```
idx 1  FUN_0059FF50(esi=1)  → character GUID → [F+0x14]   ; absent ⇒ push nil, return 1
idx 2  FUN_0059FF50(esi=2)  → GUID → [F+0x40] = P[0]      ; else P[0] = 0     (0x005BF205)
idx n  FUN_005A0100         → GUID → [F+0x44] = P[1]      ; else P[1] = 0     (0x005BF22F)
idx n  FUN_0059FF50         → GUID → [F+0x30] = S[0]      ; else S[0] = 0     (0x005BF27F)
idx n  FUN_005A0100         → GUID → [F+0x34] = S[1]      ; else S[1] = 0     (0x005BF2A9)
idx n  FUN_005A01F0         → TABLE?  (0x005BF2C5)
         present ⇒ xor ebp,ebp / edi = 0  ★ both bucket counters RESET, so the table refills
                    P[]/S[] from index 0 and overwrites whatever the scalars put there
         absent  ⇒ jmp 0x005BF360 — apply the four scalars as-is
```

`FUN_0059FF50` accepts **only** Lua type tags 2 (lightuserdata) and 7 (userdata) — it checks the
tag at `0x0059FF82` (`cmp dword [eax+4], 2`) and `0x0059FF94`/`0x0059FF99` (`cmp eax,7` / `cmp
eax,2`) and returns 0 for anything else **without raising**. So a *table*
in slot 2 falls cleanly through all four scalar parses (leaving them zero) into the
`FUN_005A01F0` table path, which is the ordinary `SetAllWeapons(char, tWeapons)` call. **Both
spellings are supported by design, not by accident.**

> **This closes what earlier revisions filed as "the optional second GUID argument, purpose
> unknown".** `SetAllWeapons(uChar, uWeaponGuid)` puts that one GUID straight into the **primary**
> slot `P[0]` and hands `{P0, 0, 0, 0}` to the applier — i.e. "strip this character and give them
> exactly this weapon". Five shipped call sites use it, and they are the reason it exists:
> `pmccon032.lua:540,562` (`Pg.GetGuidByName("Grenade Launcher")`), `pmccon033.lua:541,562`
> (`"Pistol (silver)"`), `pmccon034.lua:197,231` (`"Anti-Material Rifle"`). ⚠ Note the scalar path
> **bypasses the `Equipment.type` bucketing entirely** — a Secondary-tagged GUID passed this way
> would still land in the primary slot. H on the code path; the behavioural consequence is untested
> because every shipped use passes a primary.
>
> ⚠ `FUN_005A0100` itself is only partly readable — its head (`0x005A0100`) contains
> `jmp dword ptr [0x0244FB68]`, a SecuROM split. Its **caller-side contract** is unambiguous and
> that is what is documented: index in EAX, out-pointer on the stack, `ret 8`, returns the number
> of stack slots consumed (added to the running index); ≤ 0 ⇒ the caller zeroes the slot.

Then the table path proper:

```c
iterate the Lua table (FUN_005A01F0 open @0x005BF2C5, FUN_0059F160 next @0x005BF2FE):
    w = element;
    e = Equipment[w];  if (!e) skip;                       // 0x005BF316
    if (e.type == 0 && nP < 4) P[nP++] = w;    // primary bucket, 4 wide, [esp+0x40]
    else if (nS < 4)           S[nS++] = w;    // secondary bucket, 4 wide, [esp+0x30]
h = RuntimeInventory[uChar];
if (h && h[0x20]) FUN_0051DFA0(h[0x20], DAT_00DFDB5C, 0);   // ★ dismount any turret first
FUN_00528170(uChar);                                         // ★ DESTROY every current weapon
FUN_006F8EF0(uChar, P[0], P[1], S[0], S[1]);                 // ★ only 2 per class are forwarded
FUN_00527E70(uChar);
push(boolean result of FUN_006F8EF0);
```

**⚠ Shipped truncation: indices 2 and 3 of each bucket are collected and then discarded.**

```asm
005BF324  cmp  dword ptr [eax], 0                  ; Equipment.type
005BF327  jne  0x005BF337                          ; → secondary store
005BF329  cmp  ebp, 4
005BF32C  jge  0x005BF337                          ; ★ primary bucket FULL → falls INTO the
005BF32E  mov  dword [esp+ebp*4+0x40], esi         ;    secondary store block
005BF337  cmp  edi, 4
005BF33A  jge  0x005BF343                          ; secondary full → dropped
005BF33C  mov  dword [esp+edi*4+0x30], esi
```

and the call site, **with the register arguments Ghidra drops** (`L` = the loop frame's `esp`):

```asm
005BF390  push esi ; call 0x00528170     ; destroy-all first   (esp = L−4 hereafter)
005BF396  mov  eax, [esp+0x38]   ; = L+0x34 = S[1]
005BF39A  mov  ecx, [esp+0x34]   ; = L+0x30 = S[0]
005BF39E  push eax
005BF39F  mov  eax, [esp+0x48]   ; = L+0x40 = P[0]   → ★ REGISTER arg EAX
005BF3A3  push ecx
005BF3A4  mov  ecx, [esp+0x50]   ; = L+0x44 = P[1]   → ★ REGISTER arg ECX
005BF3A8  push esi                                    ; the character
005BF3A9  call 0x006F8EF0
005BF3AE  mov  byte [esp+0x64], al                    ; the boolean the cfunc pushes
```

Ghidra alone renders this as `FUN_006f8ef0(unaff_EDI, local_34[0], local_34[1])` — **two** slots —
and misleads anyone who trusts it. So: **a table with 3 primaries or 3 secondaries silently loses
the third**, and the maximum loadout `SetAllWeapons` can express is **2 primary + 2 secondary = 4
weapons.** The shipped `ResetWeapons` (`{primary, Grenade, C4}`) is 1 + 2 and fits.

**⚠ And it is not merely truncation — it changes slot class.** Because `cmp ebp,4 / jge 0x005BF337`
jumps *into* the secondary-store block rather than past it, **the 5th–8th primaries are written into
the SECONDARY bucket** and can surface as `S[0]`/`S[1]`. §4.5's pseudocode implicitly encodes this
in its `else if (nS < 4)`, but it is worth saying out loud: an over-long primary list does not just
drop weapons, it can hand a primary to the applier as a secondary.

**It takes prototype GUIDs, and negative ids are SPAWNED.** `FUN_006F8EF0` takes
`{EAX, ECX, [ebp+0xC], [ebp+0x10]}` = `{P0, P1, S0, S1}`, loops all four (`cmp esi,0x10`) and for
each: `0` → `0`; **non-negative → passed through unchanged**; **negative → `FUN_006746D0([0x01176108],
v, &out, &local, 1, 0)`**; then `FUN_005283F0(EAX=char, out[0..3])`. ⚠ `FUN_006746D0` is **not** a
"name resolver" — it is a general **entity instantiation** routine (482 B, 30+ callers spanning
`0x0042B94C`…`0x0062E982` across unrelated modules; it bumps `[param_1+0x10]`, calls `FUN_00673070`,
patches `[rec+0x1B]`/`[rec+0x1A]` visibility bits). Negative ids are *spawned*, which is precisely
why `LoadSingleton` must re-read `GetAllWeapons` afterwards (§7.3). The shipped Lua proves the
intent from the other side: `ResetWeapons` passes `Pg.GetGuidByName(…)`, and `LoadSingleton` passes
`Object.GetParent(uEquipment)` — the *parent/archetype* of each saved instance, not the instance.

**`FUN_005283F0(char, P0, P1, S0, S1)`** is the applier (read first-hand at `0x005283F0`):

```
gate: RuntimeInventory[char] exists && !(+0x2C & 8)
if (+0x20) detach from the mounted weapon first (FUN_0051DFA0)
P0 → FUN_00527B50(char, P0, 1)        ★ give AND equip
P1 → FUN_00527B50(char, P1, 0)        ★ give, leave holstered
S0 → if no carry edge: attach (FUN_00527450 + FUN_00527030) then FUN_00527C70(char, S0)   ★ equip
     else if edge[8] & 1 already set: nothing
S1 → if no carry edge: attach, done (left holstered)
     else if edge[8] & 1: FUN_00527C70(char, 0)                                    ★ rotate away
```

So the **first** primary and the **first** secondary end up in `+0x00` / `+0x04`; the seconds land
in `+0x0C` / `+0x10`. That is the mechanical definition of "equipped vs. stowed" in this engine.

### 4.6 `DropWeapon(uChar, uWeapon)` — `0x005BF420`, 192 B — ◐ H

Recovered by disassembly. Reads two GUID args, calls **`FUN_00528250(uChar, uWeapon)`**, pushes the
result as a boolean via `FUN_004B86E0`. The native (read):

1. `FUN_005280A0(EAX = weapon, stack = char)` — a precondition veto, read at `0x00528262`–`0x0052826F`
   (`push esi` = char, `mov eax,ebx` = weapon, `call 0x5280A0`, `test al,al`); false ⇒ return false,
   nothing happens. **This is the same veto `DestroyAllWeapons`' native applies per weapon** (§4.9).
2. resolve the character in **`PhysicsActorRagdoll`** (`0x017BF928`, §2.0) and, if `[rec+0x00]`,
   `FUN_004336D0`. **This is not "resolve the human"** — the guard is *"does this character have a
   live ragdoll actor"*.
3. `FUN_00432740(weapon)` → an object with a vtable; if present, call `vt+0x84(&xform, -1)`,
   `vt+0x1C()`, then `vt+0x90(&vel)` with the vector `(0, [0x00B92874], 0)` — **the dropped weapon
   is re-enabled as a physics body and given a vertical impulse.**
4. `FUN_0051DFA0(weapon, DAT_00DFDB5C, 0)` — the detach/notify path that clears the carry edge.
5. resolve in **`SceneObject`** (`0x017C02D8`, §2.0) → `[rec+0x1A] |= 2`; resolve in `Equipment`
   `0x017BCDB8` and, if `type == 0`, set a global bit in `[0x0198E180]` (a "player has dropped a
   primary" latch — role **open**, §9.3 item 3). The same primary branch also calls `FUN_00649C60(weapon)`
   and clears `word [rec+0x10] &= 0xFFFE`.
6. a final block resolves `RuntimeWeapon[weapon]`, `Ai[char]` (`0x017BD1C8`) and
   `WeaponProjectileBase[weapon]` (`0x017BC778`), computes
   `round(−(WeaponProjectileBase.word[+0x1E] × DAT_00DFDCA4))` and stores it as a `u16` at
   `RuntimeWeapon +0x24` — a drop-time reload/recoil timer.

The shipped `mrxshootinggallery.lua` pattern is the cleanest behavioural proof of the slot model
(§8.3): it calls `GetPrimaryWeapon` → `DropWeapon` → `GetPrimaryWeapon` again and gets a **second,
different** weapon, i.e. `+0x0C` promoted into `+0x00`.

### 4.7 `EquipWeapon(uChar, uWeapon)` — `0x005BF4E0`, 323 B — H

```c
e = Equipment[uWeapon];  if (!e) error(FUN_004B2A50);
if (e.type == 0)  ok = FUN_00527950(uChar, uWeapon);   // primary path
else              ok = FUN_00527C70(uChar, uWeapon);   // secondary swap
if (ok) push(true);
else    push(FUN_00529300(uChar, uWeapon, 1));         // fallback → boolean
```

`FUN_00527950` is the *acquire-and-draw* primary path: it can **create** a weapon instance
(`thunk_FUN_024F1190(0,0,…)`) when `+0x0C` is empty, sets `+0x2C |= 4` (equipping) and finishes
through `FUN_00527730` (draw) or `FUN_00527540` (holster the current one first). `FUN_00527C70` is
the pure slot rotation.

**Contrast `Human.EquipWeapon` (`0x005BE340`, the *other* table).** It takes the same two GUIDs but
does not acquire anything: it writes the weapon into the **last-equipped** slot of its class
(`+0x0C` for primary, `+0x10` for secondary) and then runs the draw/swap, restoring the old value if
that fails. It is "make this weapon I am already carrying the active one". `Human.StowWeapon`
(`0x005BE4C0`) is the inverse. **Neither has a shipped call site**; the 4 shipped equip calls are all
`Human.Inventory.EquipWeapon`. Those two are owned by
[`human_character_controller_code_map.md`](human_character_controller_code_map.md) (§6.1 there,
which reads the same `+0x0C`/`+0x10` slots and the same `FUN_00527730`/`FUN_00527C70` callees —
independent corroboration of §2 and §5); they are described here only because the duplicate name is
a real trap.

### 4.8 `ReloadAll(uChar, bSomething)` — `0x005BF6B0`, 298 B — H  ⚠

```c
if (!arg1 guid)              { push nil; return 1; }
if (FUN_0059F6D0(&b) < 1)    { push nil; return 1; }   // ★ ARG 2 IS MANDATORY
if (!RuntimeInventory[uChar]) error(FUN_004B2A50);
FUN_0051FC40(uChar);                                    // → FUN_0040E3D4, the reload-all native
if (b) { h = thunk_FUN_024E8DF0(); thunk_FUN_024E8ED0(h, 0); }
FUN_00527500(); FUN_0051F830();
push(true);
```

**`ReloadAll(uChar)` with one argument is a silent no-op that returns `nil`.** Read at instruction
level: arg 2 is fetched by `FUN_0059F6D0` with `ESI = 2` (`0x005BF729`/`0x005BF732`); that helper
computes `nargs = (L->top − L->base) >> 3` (`0x0059F6E9`–`0x0059F6F2`) and returns 0 on an
out-of-range index; then `cmp eax,1 / jge 0x005BF762` @`0x005BF737` routes to a **push-nil,
return-1** path (`lea eax,[esi-1]`, `mov dword [edx+4],0`, `add dword [ebx+8],8`,
`0x005BF73C`–`0x005BF761`) **before** any reload work — `FUN_0051FC40` is at `0x005BF7xx`, past the
gate. Unlike `GetAllWeapons`, which explicitly defaults the missing boolean to false, `ReloadAll`
bails. What the boolean selects is a first-person/held-weapon handle refresh
(`thunk_FUN_024E8DF0` is the same accessor `Human.StowWeapon` uses to read the currently-held
weapon) — **M**.

> **⚠ Latent, not shipped.** Earlier revisions of §0 called this "a shipped trap". It is not: a
> `grep -rn ReloadAll` over both corpora finds **exactly three** call sites and **all three pass two
> arguments** — `docs/mercs2-luacd/src/vz/xQ!L.lua:761`,
> `docs/mercs2-dlc-luacd/src/dlc01/dlc01.lua:492`,
> `docs/mercs2-dlc-luacd/src/dlctest01/dlctest01.lua:158`, each `ReloadAll(<char>, false)`. There is
> no one-argument call in shipped content. So this is an **API trap for new script authors**, not an
> observable retail bug. (This also closes the older note that "the 2 DLC sites should be checked".)

### 4.9 `DestroyAllWeapons(uChar)` — `0x005BF630`, 128 B — ◐ H

Recovered by disassembly. Arg check, then `FUN_00528170(uChar)`, then **`xor eax, eax; ret`** — it
pushes **nothing**; only the bad-argument path pushes `nil` and returns 1. A Lua caller therefore
gets *no* value, not `nil`.

`FUN_00528170` is a **split thunk** — `jmp dword ptr [0x02459DE8]`, bytes `FF 25 E8 9D 45 02`. The
slot resolves to `0x024ECED0`, a SecuROM return-trampoline
(`push 0x024ECEEA; push 0x004063FD; push 0x01ACA60C; pushfd; sub dword [esp+4],0x1A6FC; popfd; ret`)
computing `0x01ACA60C − 0x0001A6FC = 0x01AAFF10` in `Stext` — which is itself
`jmp dword ptr [0x021FD554]`, the **VM entry**. That route is a dead end. But **the relocated
plaintext body is in `.securom` at `0x02487980`** and reads cleanly:

```asm
02487980  push ebp ; mov ebp,esp ; and esp,0xFFFFFFF8
02487986  mov  eax, [ebp+8]                  ; ★ one stack arg = the character
0248798F  push 1 ; xor edi,edi ; push edi
02487994  push 0x00DF9510                    ; ★ RuntimeEquipmentLink, by-parent index (3rd arg = 1)
024879A2  jmp  0x006499F0                    ; == call FUN_006499F0 (iterator ctor, EAX = char)
;   ── SNAPSHOT pass: collect every carried weapon into a stack array at esp+0x38
024879D1  mov  [esp+edi*4+0x38], eax         ; list[n++] = weapon
024879DE  call 0x00649A80                    ; iterator advance
;   ── DESTROY pass
02487A05  mov  esi, [esp+ebx*4+0x38]
02487A11  call 0x005280A0                    ; ★ the SAME per-weapon veto DropWeapon's native uses
02487A28  je   0x02487A58                    ;   false ⇒ this weapon is LEFT ALONE
02487A2A  mov  [esp+0x10], esi               ; build {weapon, 0,0,0,0}  (dword + four zero bytes)
02487A4B  jmp  0x004F30D0                    ; == call FUN_004F30D0(&record)
;   epilogue: EnterCriticalSection([0x00EDBAA4]) ; [frame+0x18] = [0x00EDBAC0] ;
;             [0x00EDBAC0] = frame ; LeaveCriticalSection   — a DEFERRED-DESTROY QUEUE push
```

Three consequences, none of which the "open by body" placeholder could give:

1. **It is a two-pass snapshot-then-destroy**, not an in-place walk — it cannot invalidate its own
   iterator. A reimpl must do the same.
2. **It never touches `RuntimeInventory`.** There is no `mov ecx,0x17BF3D8` and no `0x017BF3D8`
   literal anywhere in `0x02487980`–`0x02487AE0`. It does **not** clear
   `+0x00/+0x04/+0x0C/+0x10/+0x14`; the slots are cleared as a side-effect of the destroy
   notification, and the destroy itself is a **deferred queue push** — which is why
   `SetAllWeapons`' immediately-following `FUN_006F8EF0` can still be handed *positive instance
   GUIDs* (§7.2) without them having been reaped yet.
3. **`FUN_005280A0` is a per-weapon veto.** A weapon that fails it **survives** `DestroyAllWeapons`.
   Earlier revisions described destroy-all as unconditional.

Residual: `FUN_004F30D0` is 7 bytes, `jmp dword ptr [0x02450014]`; `[0x02450014] = 0x024B8130` =
`push 0x024B813A; call 0x01AAFF10` — the *same* VM dispatcher, and here **no relocated plaintext
body exists** (see §9.2). So "the primitive is *destroy*" remains **H by structure** — it is a
per-weapon call on a freshly built record, not a slot clear on the human — with the exact primitive
open.

Zero shipped call sites — `SetAllWeapons` (and, natively, `FUN_006F9260`) is how the game reaches it.

---

## 5. Equipped vs. stowed — the swap, read from `FUN_00527C70`

There is no "stowed container". A holstered weapon is still a child entity with a live carry edge;
the only difference is which dword of `RuntimeInventory` holds its GUID.

`FUN_00527C70(char, weaponOrNull)` (392 B, read first-hand) is the single rotation primitive:

```c
h = RuntimeInventory[char];
if (!h || (h[0x2C] & 8)) return false;                 // ★ bLocked
if (h[0x20]) { detach from the mounted weapon (FUN_0051DFA0) or bail }
if (h[0x04] == weapon) return …;                       // already equipped, nothing to do
edge = FUN_00649440(char, h[0x04]);  bWasHeld = edge ? (edge[8] >> 2) & 1 : 0;
old   = thunk_FUN_024F1170(...) ? h[0x04] : 0;
if (weapon == 0) {                                     // ── "stow / cycle away" ──
    if (!bWasHeld) h[0x10] = h[0x10] ? h[0x10] : create(1, 0, h[0x04]);
    else if (!FUN_00649440(h[0x10])) swap(h[0x10], h[0x14]);
} else {                                               // ── "equip this one" ──
    if (h[0x10] != weapon) swap(h[0x10], h[0x14]);
    if (h[0x10] == 0)      h[0x10] = weapon;
}
if (h[0x10] == 0) { restore; return false; }
h[0x04] = h[0x10];                                     // ★ promote
h[0x10] = h[0x14] ? h[0x14] : old;                     // ★ demote
if (h[0x14]) h[0x14] = old;
…
```

**That is a 3-deep carousel, and now it has a reason.** `+0x14` is
`iLastLastEquippedSecondaryGuid` (§2.1) — `equipped → last → last-last` — which is exactly what a
weapon-cycle button needs, and it is what `FUN_0052A3B0`'s push-down
(`[+0x14] = [+0x04]; [+0x04] = new`, `0x0052A47E`) is doing. Earlier revisions called `+0x14`
"a third secondary-chain slot" and named it `iEquipmentWaitingForPickupGuid`; the rotation
semantics rule that name out.

The primary chain is the same idea with a shorter carousel: **`FUN_00527730`** draws (`+0x0C` →
`+0x00`, sets `+0x2C |= 4`, writes the pending action into `+0x24` @`0x00527842`, creating the
instance via `thunk_FUN_024F1190(0,0,+0x00)` if `+0x0C` is empty) and **`FUN_00527540`** holsters
(reads `+0x00`, sets `+0x2C |= 4`, then either the simple path `FUN_00527670` when the carry edge
has bit `0x02` (`0x005275E2`), or a first-person-aware path through `FUN_00526C70` +
`thunk_FUN_024E7C50`).

One compression to flag: the "detach or bail" line above is really a three-way test on the
**`RuntimeWeapon`** record — `+0x26 & 3`, `+0x32 & 1`, `+0x26 & 0x10` are read before
`FUN_0051DFA0`, and `+0x32 & 0x10` is cleared after. Those offsets belong to `0x017BEC08`, **not**
to `RuntimeInventory`.

Practical consequences for anyone modelling this:

- **Two things are "equipped" at once** — a primary *and* a secondary — plus possibly a vehicle
  weapon. There is no single "equipped index".
- **The swap is failable and it rolls back.** Every path restores the previous slot values and
  returns `false` if the underlying draw/holster fails. The Lua bindings surface that boolean.
- **`+0x2C & 8` short-circuits everything.** A locked human accepts no loadout change at all.

---

## 6. Reserve vs. clip ammo — where each half lives

Owned by [`weapons_combat_code_map.md`](weapons_combat_code_map.md); stated here only as the join,
because "the inventory holds the ammo" is the obvious wrong model.

- **Neither clip nor reserve is on the human.** `RuntimeInventory` (`0x30`) is **seven GUIDs plus
  four state dwords** (§2.1) — every offset is now named, and **none of the eleven is a magazine or
  a capacity**; `HumanInventory` — the *persisted* design-side component (`0x017BDE48`, stride
  `0x1C`) — is **3 unlabeled ints** (ecs-04); `Equipment` is a type tag plus 6 unlabeled ints.
  ⚠ Hedge kept honest: for `HumanInventory` and `Equipment` this is *"no labeled field, and the
  unlabeled ints are unexamined"*, which is what ecs-04:113-118 itself says. Only for
  `RuntimeInventory` is the "no such field" claim complete.
- **Both live on the weapon instance.** The Xbox debug dump prints `iReserveAmmo` on the **base**
  `RuntimeWeapon` and `iClipAmmo` in the **`RuntimeWeapon::Projectile`** sub-state (pdb
  weapons-combat.md §"RuntimeWeapon dump") — two different structs, not one. The PC `RuntimeWeapon`
  pool is `0x017BEC08` (stride `0x34`, ecs-01). The `Weapon` namespace (`0x00B98860`, 9 cfuncs) is the
  script view of exactly that pool: `SetClipAmmo` `0x005EA520`, `GetClipAmmo` `0x005EA5F0`,
  `GetMaxClipAmmo` `0x005EA6B0`, `SetReserveAmmo` `0x005EA790`, `GetReserveAmmo` `0x005EA860`,
  `GetMaxReserveAmmo` `0x005EA930`, `Reload` `0x005EAA80`, `IsDesignator` `0x005EAB70`, `IsPrimary`
  `0x005EAC60`.
- **Capacity is design data on the definition, not the instance.** `iClipSize`, `MaxAmmoReserve`,
  `iRoundsPerReload`, `iBulletsPerShot` are `WeaponProjectileBase` reflection fields (schema
  `FUN_0065CA70`), consistent with [[ecs-component-registry-corpus]]'s "clip=30/reserve=60 default
  lives in `WeaponProjectileBase`, **not** inventory components" and with
  [[weapon-definitions-wpn-blocks]] (`wpn_*` blocks).
- **The join is `Object.GetParent`.** A carried weapon GUID is an *instance*; its parent is the
  named definition (`Pg.GetGuidByName("Pistol")`). §7.3 is the shipped proof.

So: **definition → capacity; instance → current clip + reserve; `RuntimeInventory` → which instance
is in which slot; the carry relation → who owns it.** Four layers, and every shipped script that
touches ammo crosses at least two of them.

---

## 7. The three shipped usage patterns

### 7.1 Give a fixed loadout — `mrxplayer.lua:528 ResetWeapons`

```lua
function ResetWeapons(uCharGuid, sNewWeapon)          -- :528
  local sPrimary = sNewWeapon or "Pistol"             -- ★ the primary is a PARAMETER, defaulted
  …
  Human.Inventory.SetAllWeapons(uCharGuid, { uPrimary, uGrenade, uC4 })   -- :535
end
```

Prototype GUIDs in, instances **spawned** by `FUN_006746D0` inside `FUN_006F8EF0` (§4.5). Pistol is
`type == 0` so it becomes the equipped primary; Grenade and C4 fill `S[0]`/`S[1]`, i.e. equipped
secondary + last-equipped secondary. A fourth item of either class would still fit; a fifth would
not (§4.5).

### 7.2 Take the guns away and give them back — the PMC contract missions

`pmccon018/031/032/033/034` all do:

```lua
tP1Weapons = Human.Inventory.GetAllWeapons(uCharacter)     -- snapshot (instances)
… mission …
Human.Inventory.SetAllWeapons(uCharacter, tP1Weapons)      -- restore
Human.DisableWeapons(uCharacter)
```

Note the order: `SetAllWeapons` **then** `DisableWeapons`. Reversed, the `+0x2C & 8` gate would make
the restore a no-op — the gate is one call deeper, on the chain
`SetAllWeapons → FUN_006F8EF0 → FUN_005283F0 (gated @0x0052840F)`, §2.2. The order holds in **all
five missions, on both branches**: `pmccon018` 611→612 / 623→624; `031` 896→897 / 909→910; `032`
707→708 / 720→721; `033` 705→706 / 718→719; `034` 644→645 / 657→658. No exceptions.

Note also that the snapshot holds *instance* GUIDs while `SetAllWeapons` is documented above as a
prototype consumer — `FUN_006F8EF0` only spawns for **negative** slot values, so positive instance
GUIDs pass straight through to `FUN_005283F0`, which re-attaches them. This is not undefined
behaviour: `FUN_00528170`'s destroy is a **deferred queue push** (§4.9), so the old instances are
still live when `FUN_006F8EF0` runs. Both spellings work; they take different paths. (**M** on the
end-to-end behaviour — confirm-live §9.3 item 2.)

`pmccon032/033/034` additionally use the **bare-GUID** form mid-mission
(`SetAllWeapons(uCharacter, Pg.GetGuidByName("Grenade Launcher"))` etc., six sites) — a shape §4.5
now describes: the GUID goes into `P[0]` and the character ends up with exactly that one weapon.

### 7.3 Save / restore across a hero swap — `mrxplayer.lua:661-724` (the decisive evidence)

`SaveSingleton` at `:661`, `LoadSingleton` at `:683`, `_RestoreEquipment` at `:695`. Exact lines
cited so a reader can open the file at the right place:

```lua
-- SaveSingleton, :666
local tEquipment = Human.Inventory.GetAllWeapons(uCharGuid, true)   -- ★ arg2 = true
for i, uEquipment in pairs(tEquipment) do
  tSavedEquipment[i] = { Object.GetParent(uEquipment),              -- ★ the DEFINITION
                         Weapon.GetReserveAmmo(uEquipment) }        -- ★ reserve on the INSTANCE
end
…
-- _RestoreEquipment, :695 builds a FRESH tEquipment from the saved Object.GetParent values
Human.Inventory.SetAllWeapons(uGuid, tEquipment)                    -- :701 definitions back in
local tNewEquipment = Human.Inventory.GetAllWeapons(uGuid, true)    -- :702 re-read NEW instances
for i, uEquipment in pairs(tNewEquipment) do
  Event.Create(Event.ObjectHibernation, {uEquipment, "a"},
               Weapon.SetReserveAmmo, { uEquipment, tSavedEquipment[i][2] })
end
```

⚠ Reading trap: there are **two same-named locals in different scopes**. `SaveSingleton:666`'s
`tEquipment` holds *instances* and is never passed to `SetAllWeapons`; `_RestoreEquipment:695`
builds a **fresh** `tEquipment` of *definitions*. The snippet above is not self-inconsistent.

This one function proves five separate claims made above, from the game's own code:

1. `GetAllWeapons` returns a **table**, indexable by `pairs`.
2. Its entries are **instances** — `Object.GetParent` is needed to get the definition.
3. `SetAllWeapons` **destroys and re-creates**: the script must re-read `GetAllWeapons` afterwards
   because the old instance GUIDs are gone.
4. **Reserve ammo is on the instance and is not carried by the loadout write** — it must be
   re-applied by hand, and only once the new instance is live (hence the `ObjectHibernation` defer).
5. **Clip ammo is not saved at all** — a Mercs 2 hero swap silently refills the magazine. That is
   shipped behaviour, and a `bug_register` candidate rather than a reimpl requirement.

The script's own `@@@@@@@@@@ … did not have a corresponding equipment item in the save data!`
warning (`:711`, built by concatenation) shows the developers knew the index correspondence between
the two `GetAllWeapons` calls is positional — which is why §4.4's ordering guarantee matters.

---

## 8. Script traffic

`corpus_calls` (`bindings/inventory.rs`) reconciles exactly against a direct grep here
(base `docs/mercs2-luacd/src/` + `docs/mercs2-dlc-luacd/`):

| Name | base | DLC | total |
|---|--:|--:|--:|
| `SetAllWeapons` | 25 | 9 | **34** |
| `GetAllWeapons` | 27 | 5 | **32** |
| `DropWeapon` | 17 | 0 | **17** |
| `GetPrimaryWeapon` | 9 | 2 | **11** |
| `GetSecondaryWeapon` | 2 | 4 | **6** |
| `EquipWeapon` | 4 | 0 | **4** |
| `ReloadAll` | 1 | 2 | **3** |
| `GetVehicleWeapon` | 0 | 0 | **0** |
| `DestroyAllWeapons` | 0 | 0 | **0** |
| | | | **107** |

Reproduce with `grep -rho "Human\.Inventory\.<name>"` over `docs/mercs2-luacd/src/` and
`docs/mercs2-dlc-luacd/src/`. Zero aliased locals, zero comment/string false positives, zero
non-`Human.Inventory.` spellings of `EquipWeapon`/`DropWeapon`.

**15** base-game scripts use the namespace (`grep -rl`): `hero`, `soldier`, `livingworldprop`,
`mrxplayer`, `mrxshootinggallery`, `mrxstatsmanager`, `pmccon001/018/031/032/033/034`, `vzacon001`,
`wiftutorialc4`, `xQ!L`. *(Earlier revisions said 16 while listing 15 — the list was right, the
count was not.)*

For comparison the sibling `Human` table's top entries are `DisableWeapons` **27**, `SetState`
**24**, `DoAction` **19** over both trees (base-only: 25 / 21 / 17 — earlier revisions quoted the
base-only figures alongside a base+DLC total of 107, which is not comparable).

**§8.3 — the behavioural proof of the two-deep chains.** `mrxshootinggallery.lua:4 RemoveWeapons`
calls `GetPrimaryWeapon` → `DropWeapon` → `GetPrimaryWeapon` → `DropWeapon`, then the same for
`GetSecondaryWeapon`, storing them as `Primary1/Primary2/Secondary1/Secondary2`, and restores them
later with four `EquipWeapon` calls **in reverse order** (Secondary1 `:64`, Secondary2 `:68`,
Primary2 `:71`, Primary1 `:75`) so the intended weapon ends up equipped. `ReturnWeapons` *first*
does an extra `GetPrimaryWeapon` + `DropWeapon` at `:55`/`:57` to shed the gallery's own weapon
before the restore. That script only makes sense against the `{equipped, lastEquipped}` pair model
of §2, and it is the strongest confirm-live-free evidence that a human carries **two primaries and
two secondaries**.

---

## 9. Open questions / confirm-live inventory

Read-only while **PAUSED**; the USER drives execution ([[x32dbg-mcp-no-resume]]), and a conditional
breakpoint on a per-frame function will kill the session ([[x32dbg-mcp-pitfalls]]) — prefer
**one-shot** breakpoints and HW-write watchpoints.

> **Closed since the last revision, listed so nobody re-opens them:** the `bLocked` writer (body
> read, §2.2 — and the previous answer `0x006FC560` was *wrong*); `FUN_00528170`'s body (read,
> §4.9); the names of `+0x14`/`+0x18`/`+0x1C`/`+0x24`/`+0x28` (§2.1); the containers `0x00DF9510`,
> `0x017BF928`, `0x017C02D8` (§2.0); `SetAllWeapons`' optional second GUID argument (§4.5); the
> `ReloadAll` DLC call sites (§4.8). Six confirm-live items retired **without a debugger**.

### 9.1 Carry-edge flag bit `0x02` — what the edge's `+0x04` object *is* — OPEN

The only thing `GetAllWeapons(uChar, true)` filters out, and the only difference between the save
path and every other caller.

*Static exhaustion already performed* (so do not redo it): the edge record is 12 bytes,
`{+0x00 obj, +0x04 obj2, +0x08 flags}` (registered element size, §2.0). Every `or`/`and byte
[reg+8], imm` in the image was enumerated and every reader filtered to functions that also touch
`0x00DF9510`. **The writer is `FUN_006FC280`** and bit `0x02` mechanically tracks *"the edge's
`+0x04` second object is non-null"* (§3.2). Six consumers are known. What remains unknown is
**what that second object is** — a mount point, an attachment socket, or a second participant
entity — and that needs a live record.

*Runtime recipe.* With the player carrying a primary and a secondary and standing at an emplaced
gun: **one-shot** breakpoint at `0x005BEE8F` (`GetAllWeapons`' filter — reached only from script,
never per-frame) and dump `[esi+0x00]`, `[esi+0x04]`, `[esi+0x08]` for each iteration; repeat while
mounted. Resolve each `+0x00`/`+0x04` through `FUN_005857E0(ecx=0x017BCDB8)` to see which are
`Equipment`-tagged. Cross-check from console: compare
`Human.Inventory.GetAllWeapons(uChar, true)` against the unfiltered call.
⚠ **Do NOT breakpoint `FUN_00527540` or `FUN_0052A3B0`** — both run on the equip tick.

### 9.2 The destroy primitive `FUN_004F30D0` — OPEN (genuinely VM-blocked)

*Static exhaustion already performed:* `FUN_004F30D0` is 7 bytes, `jmp dword ptr [0x02450014]`;
`[0x02450014] = 0x024B8130` = `push 0x024B813A; call 0x01AAFF10` — the **same** VM dispatcher
(`0x01AAFF10 → [0x021FD554] → 0x02A30000`) that guards `FUN_005BE050` and `FUN_00528170`. Unlike
those two, **no relocated plaintext body exists**: an image-wide scan for a `.securom`/`Stext` blob
fingerprinting a small-record entity operation with 100+ call sites found no candidate, and the
function has no distinguishing constant to fingerprint on. All four images (`mercs2_unpacked`,
`mercs2_nodrm_v1/v2/v3`) carry byte-identical thunks and slot values, so no sibling build resolves
it. **This is the one item in this map that a static route cannot reach.**

*What is nonetheless settled:* `FUN_00528170` calls it **per weapon**, after a `FUN_005280A0` veto,
with a freshly built `{weapon, 0,0,0,0}` record — so it is an operation *on a weapon entity*, not a
slot clear on the human.

*Runtime recipe.* One-shot breakpoint at `.securom 0x02487A4B`, step into the resolved target, and
watch whether the weapon's `SceneObject`/`RuntimeWeapon` records are freed or merely flagged.
Equivalently, from script: `local t = Human.Inventory.GetAllWeapons(u)` →
`Human.Inventory.DestroyAllWeapons(u)` → `Object.IsAlive(t[1])`. If the old GUIDs are dead,
"destroy" is literal and `SetAllWeapons` does not leak weapon entities.

### 9.3 Lower-priority confirm-live

1. **The Xbox→PC *name* join is positional for all eleven fields** (§2.1). The offsets are proven;
   the labels are a positional read of the debug-dump literal pool. `+0x14` and `+0x28` have strong
   independent PC-side semantics (a 3-deep rotation; an enum compared against 2); `+0x0C`/`+0x10`
   are consistent with "last equipped" *or* "default/holstered". Dump the record live on a player
   holding four weapons and cycle secondaries to settle the rest.
2. **Instance vs. prototype GUIDs into `SetAllWeapons`** (§7.2). The deferred-destroy queue (§4.9)
   explains *why* the snapshot-restore pattern works; confirm end-to-end that a positive instance
   GUID survives to `FUN_005283F0`. One-shot bp at `0x005BF3A9`, read EAX/ECX/stack.
3. **The `[0x0198E180]` bit** set by `DropWeapon` when a primary is dropped (§4.6) — find its
   reader.
4. **The `GetAllWeapons` unbounded fill loop** (§4.4 item 3). Attach 7+ primaries to a human by a
   non-`SetAllWeapons` route (`FUN_00527B50` / a pickup) and call `GetAllWeapons` under a HW-write
   watchpoint on `esp+0x38`/`esp+0x50` to confirm the overwrite. If it reproduces, it is a
   `bug_register` entry and a hard constraint on any mod that hands a character many weapons.
5. **Do AI humans use the same path?** `soldier.lua` reads `GetAllWeapons` on the *hero*, not on
   itself, and no shipped script gives an NPC a loadout through this namespace. `FUN_006F9260`
   (§2.2 row 18) is a second native loadout-apply path and is the obvious candidate; whether
   population spawners route through it is unestablished.

---

## 10. Reconciliation with `mercs2_combat`

**Ownership — settled.** `Human.Inventory` belongs to **`mercs2_combat`**, not `mercs2_player`. The
engine agrees on every axis this map examined: the state lives on the *character* entity
(`RuntimeInventory` is a component of the human, and `RuntimeVehicleInventory` of the vehicle) —
never on the player object, which `player_code_map.md` §2.2 shows carries no weapon field at all;
the taxonomy is `EquipmentTypeEnum` on the *item*; the slot machinery (`FUN_00527C70`,
`FUN_00527730`, `FUN_005283F0`) sits in the same `0x0051–0x0052` module as the weapon-system driver
`FUN_0051CFF0`, not near the player cluster; and NPCs are eligible for the same components. It is
weapon state carried on a human. `mercs2_player` should own possession and the profile, and reach
weapons through the character GUID.

**What exists today.** `mercs2_combat::components::Inventory` is already defined
(`crates/mercs2_combat/src/components.rs:183`), and `mercs2_script::bindings::inventory` installs
all 9 names with real bodies. The binding table has since been corrected to match §1: `GLOBAL` is
now **`"Human.Inventory"`** and the table installs as a **child of `Human`** via `install_child`,
replacing an earlier mirror-onto-a-bare-`Inventory`-global hack — the game calls
`Human.Inventory.*` 70+ times and bare `Inventory.*` **zero** times. So this is a *correction*
list, not a greenfield spec:

```rust
pub struct Inventory {
    pub weapons: Vec<crate::stats::WeaponStats>,   // ← by value
    pub equipped: usize,                           // ← ONE index
}
```

1. **`equipped: usize` cannot represent retail.** A human has an equipped **primary and** an
   equipped **secondary and** possibly a vehicle weapon simultaneously (§2). A single index makes
   `GetPrimaryWeapon`/`GetSecondaryWeapon` mutually exclusive, which they are not. Model **seven**
   GUID slots, not six: `equipped_primary`, `equipped_secondary`, `equipped_vehicle`,
   `last_primary`, `last_secondary`, **`last_last_secondary`** (`+0x14`), `pending_pickup`
   (`+0x18`) — plus `ammo_prop` (`+0x1C`), `weapon_in_use` (`+0x20`), `current_equip_action`
   (`+0x24`), `weapon_visibility` (`+0x28`) and the flags dword. ⚠ **A reimpl written to the old
   six-field list gives the secondary carousel the wrong third rung and omits two live fields**
   (§2.1) — the secondary cycle is 3-deep, not 2-deep, and `FUN_00527C70`'s rotation depends on it.
2. **Store entity handles, not `WeaponStats` by value.** Shipped Lua calls `Object.GetParent(w)`,
   `Weapon.GetReserveAmmo(w)`, `Object.DisablePhysics(w)`, `Object.SetPosition(w, …)` and
   `Object.HasLabel(w, "Grenade")` on the values `GetAllWeapons` returns. They must be real entities
   in the ECS world ([[ecs-world-source-of-truth-deshadow]]), and their ammo must live on the weapon
   entity — not copied into the human's component.
3. **Carrying is a relation, not a `Vec` field.** Retail keeps a separate parent↔child container
   (`0x00DF9510`) with a **per-edge flag**, and both `GetAllWeapons` and `FUN_005283F0` consult that
   flag rather than the human's record. A flat `Vec` on the human loses the "which edge is equipped"
   bit that the fallback scan depends on.
4. **Slot class comes from the item.** Add an `EquipmentType {Primary = 0, Secondary = 1}` component
   on the weapon and bucket by it. `Weapon.IsPrimary` must read that same field, or the two
   namespaces will disagree.
5. **Return shapes are wrong in four of the nine bindings.** Retail `SetAllWeapons`, `EquipWeapon`
   and `DropWeapon` all push a **boolean**; the current bindings return nothing. `ReloadAll` pushes
   `true` (and `nil` when arg 2 is missing). `DestroyAllWeapons` pushes **nothing at all**. Scripts
   branch on these.
6. **`GetAllWeapons` needs its second argument and its ordering.** Ignoring arg 2 is survivable;
   ignoring the equipped-first ordering is not, because `mrxplayer`'s save/restore pairs the two
   result tables **positionally** (§7.3). Cap at 6 per class — and **do** cap, unlike retail
   (§4.4 item 3).
7. **`ReloadAll` must require arg 2.** Faithfully reproducing the retail bail (`nil`, no reload) is
   the safer choice — the DLC scripts that call it (2 sites) were written against that behaviour.
8. **`SetAllWeapons` must destroy first, then apply at most 2+2.** The destroy pass is a distinct
   observable: the old instance GUIDs become invalid. Do not "merge" the new loadout into the old.
   ⚠ Two mechanics the naive reading misses: the destroy is a **deferred queue push**, not a
   synchronous reap (§4.9) — which is what makes the shipped snapshot-restore pattern legal — and
   `FUN_005280A0` can **veto** individual weapons, so destroy-all is not unconditional. Also accept
   the **bare-GUID** arg-2 shape (§4.5); six shipped mission sites use it and a table-only
   implementation crashes on them.
9. **`GetVehicleWeapon` returning `nil`** is currently a deliberate stub and is *correct enough*
   until the vehicle↔weapon link exists — retail also returns nil when `+0x08` is 0, and the binding
   has **zero shipped call sites**. Lowest priority of the nine.
10. **`bLocked` is not optional, and it gates nineteen functions, not six** (§2.2).
    `Human.DisableWeapons` has 27 shipped call sites and the missions in §7.2 depend on it gating
    loadout writes. A reimpl that gates only the six obvious equip/give/apply functions will behave
    differently on the weapon-system tick (`FUN_0051CFF0`) and on the second loadout path
    (`FUN_006F9260`). Note also that `EnableWeapons` is not a pure flag clear: it zeroes
    `weapon_in_use` and re-equips the last-equipped secondary when none is equipped (§2.2).

Build order by traffic: `SetAllWeapons` (34) and `GetAllWeapons` (32) carry 62 of the 107 call
sites; `DropWeapon` (17) and `GetPrimaryWeapon` (11) take it to 84 (79 %).

---

## 11. Provenance

- **PC decomp:** `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (unpacked SecuROM image, base
  `0x00400000`). Bodies read first-hand this pass: the 6 decompiled `Human.Inventory` cfuncs
  (`FUN_005BE9B0`, `FUN_005BEB30`, `FUN_005BED60`, `FUN_005BF160`, `FUN_005BF4E0`, `FUN_005BF6B0`);
  the natives `FUN_005283F0`, `FUN_00527950`, `FUN_00527C70`, `FUN_00527730`, `FUN_00527540`,
  `FUN_00527B50`, `FUN_00528250`, `FUN_0051DFA0`, `FUN_006F8EF0`, `FUN_0051FC40`; the relation
  primitives `FUN_006499F0`, `FUN_00649A80`, `FUN_00649440`; the handle resolve `FUN_005857E0`; the
  arg/result helpers `FUN_0059FF50`, `FUN_0059F6D0`, `FUN_004B1270`, `FUN_004B86E0`,
  `FUN_005A1270`; and the sibling `Human` cfuncs `FUN_005BE340` / `FUN_005BE4C0`.
- **Direct disassembly** (capstone, `output/_ghidra/securom_dump/mercs2_unpacked.exe`; `RVA == raw`
  for all 13 sections, so `file_off = VA − 0x00400000` everywhere) for the three cfuncs Ghidra never
  created a function for — `GetVehicleWeapon` `0x005BECB0`, `DropWeapon` `0x005BF420`,
  `DestroyAllWeapons` `0x005BF630` — plus the ECX-register container constants in all nine, the
  `SetAllWeapons` argument prologue `0x005BF164`–`0x005BF305` and register-arg call site
  `0x005BF390`–`0x005BF3AE`, the `GetAllWeapons` frame zero-run `0x005BEDF0`–`0x005BEE3B`, the
  `FUN_005283F0` argument slots, the `FUN_005A1270` table-pack loop, `Weapon.IsPrimary`
  `0x005EAC60`, the `EquipmentTypeEnum` registration `0x0064AC50`/`0x0064C42C`, the container
  vtable-name accessors, the **container registrars** `FUN_00645720` / `FUN_006400F0` (the static
  stride immediates, §2.0), and the image-wide `F6 /0 [reg+0x2C],8` gate census (21 raw sites).
- **⚠ Container descriptors are partly runtime state.** Capacity and shift are live and mutable;
  only the **stride** is static, and its authoritative source is the registrar's immediate in
  `.text`, not the `.data` slot. A clean on-disk image (`mercs2_nodrm_v3.exe`) has **zeroed**
  `0x50`-class descriptors because the registrars have not run — do not re-derive these numbers
  there. Capacities quoted anywhere in this map are observations from **one run** of the live dump,
  never the engine's declared limit (§2.0).
- **`.securom` relocated bodies** — the route that recovered both functions this map previously
  listed as "open by body". `mercs2_unpacked.exe` is a **memory dump with import/indirect slots
  already resolved**, so `jmp dword ptr [SLOT]` can be followed statically; where the slot lands on
  a SecuROM **VM stub**, the relocated plaintext body is nonetheless present in `.securom`
  (`0x023E9000`, raw `0x1FE9000`, vsz `0x13175F8`) as ordinary x86 with shuffled basic blocks joined
  by `push <ret>; push <target>; ret`. Recovered here: **`FUN_005BE050`** at
  `0x0246BDF7`–`0x0246C054` (§2.2) and **`FUN_00528170`** at `0x02487980` (§4.9), plus the 19th
  `bLocked` gate at `0x02466BA0`. ⚠ `output/_ghidra/securom_dump/genuine_patched_unpacked.exe` is a
  **different build** — do not cross-check against it; `mercs2_nodrm_v2/v3.exe` are clean.
- **Xbox literal pool:** `output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt:3038-3047` (the
  DRM-free PowerPC oracle, `file_off == VA − 0x82000000`) — the `RuntimeInventory` debug-dump field
  list, emitted in reverse, including the three fields no doc in this repo previously recorded
  (`iLastLastEquippedSecondaryGuid`, `iAmmoProp`, `uiCurrentEquipAction`).
- **Binding tables:** `mods/lua_trace_asi/reference/binding_map.json` (live `.rdata` walk), plus a
  raw `.rdata` re-walk performed here over `0x00B98700–0x00B9A960` which recovered the 22
  nested-namespace marker rows (§1). Corrects
  [`../lua_engine_bindings_audit_deep_dive.md`](../lua_engine_bindings_audit_deep_dive.md)'s
  "`Human` 30".
- **Xbox side:** [`../mercs2-pdb-analysis/weapons-combat.md`](../mercs2-pdb-analysis/weapons-combat.md)
  — the `RuntimeWeapon` equip/inventory dump field list (`iEquipped*Guid`, `iLastEquipped*Guid`,
  `iLastLastEquippedSecondaryGuid`, `iEquipmentWaitingForPickupGuid`, `iAmmoProp`, `iWeaponInUse`,
  `uiCurrentEquipAction`, `bLocked`, `bEquipping`, `bSwitchingPrimary`, `eWeaponVisibility`) and the
  `iClipAmmo`/`iReserveAmmo` runtime dump. ⚠ that doc's own summary line silently drops
  `iLastLastEquippedSecondaryGuid`; read the literal pool, not the summary.
- **Component registry:** [`../mercs2-ecs/04_player_vehicle_human.md`](../mercs2-ecs/04_player_vehicle_human.md)
  (`Equipment` `0xDAB653E7`, `HumanInventory` `0xE672296C`, `RuntimeInventory` `0xA364FC7D`,
  `RuntimeVehicleInventory` `0x9A6DB283`) and
  [`../mercs2-ecs/01_combat_weapons_projectiles.md`](../mercs2-ecs/01_combat_weapons_projectiles.md)
  (`RuntimeWeapon` `0x017BEC08`).
- **Script traffic:** direct grep of `docs/mercs2-luacd/src/` and `docs/mercs2-dlc-luacd/`,
  reconciling exactly with the `corpus_calls` census in
  `tools/wad_simulator/crates/mercs2_script/src/bindings/inventory.rs` (107 total).
- **Cross-refs:** [`weapons_combat_code_map.md`](weapons_combat_code_map.md) (weapon stats, firing,
  `RuntimeWeapon`, the `Weapon` namespace, the equip/visibility tick `FUN_0051C200`),
  [`human_character_controller_code_map.md`](human_character_controller_code_map.md) (the sibling
  `Human` 21 — reaches the same table split and the same `+0x0C`/`+0x10` slot pair independently),
  [`player_code_map.md`](player_code_map.md), [`vehicle_code_map.md`](vehicle_code_map.md),
  [`save_serialize_code_map.md`](save_serialize_code_map.md),
  [`scripting_host_binding_code_map.md`](scripting_host_binding_code_map.md), memories
  [[held-weapon-model-attachment]], [[weapon-definitions-wpn-blocks]],
  [[ecs-component-registry-corpus]], [[securom-decompiled-not-a-blocker]].
- **Reimpl state cross-checked this pass:** `mercs2_combat::components::Inventory`
  (`crates/mercs2_combat/src/components.rs:183`) is still `{ weapons: Vec<WeaponStats>, equipped:
  usize }`, i.e. §10 items 1–4 are outstanding.
  `crates/mercs2_script/src/bindings/inventory.rs` now declares `GLOBAL = "Human.Inventory"` and
  `install_child("Human", "Inventory")`, and its `REQUIRED` census matches §8 per-binding (107).
  Ownership recorded as `mercs2_combat`.
- Confidence stated per row. **Two** documented gaps remain (§9): the meaning of the carry-edge
  `0x02` bit's `+0x04` object, and the destroy primitive `FUN_004F30D0` — the only genuinely
  VM-blocked item in this map. Everything the previous revision listed as confirm-live has been
  closed statically, one of them (`FUN_005BE050`'s body) with a **different answer** than the first
  attempt produced.
