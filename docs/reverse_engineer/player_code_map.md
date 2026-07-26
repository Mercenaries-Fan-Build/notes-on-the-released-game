# Player — PC code map

**Scope:** the **player** as the engine models it in retail PC `Mercenaries2.exe` — the *player* object
(a controller/viewport identity: slot, camera, input gating, boundary, reticle, seat/vehicle locks,
disguise), the ≤2-slot **player container** it lives in, its binding to a **character** entity, the
**profile/economy singleton** behind cash / fuel / character / upgrade / costume, and the complete
**`Player` Lua binding surface** (`luaL_Reg` table `0x00B98FC0`, **107 cfuncs, 0 stubs** — the
2nd-highest-traffic namespace in the game). Companion JSON
[`player_code_map.json`](../data/player_code_map.json).

**This map is deliberately PC-anchored and it does *not* own the character.** The Xbox PDB carries
few `Player*`-shaped *symbols*, and the ones it does carry are peripheral
(`AddObjectiveToLocalPlayer` / `DeleteObjectiveForLocalPlayer` / `HasPlayerUnlockedCode`,
`PlayerReticleUpdate` / `GuiPlayerReceiveDamage` / `MinimapSetPlayerLocation` / `SetPlayerPDAWidget` /
`AddPlayerInfo` / `AddPdaBlipToLocalPlayer`, `PlayerPercept`) — no `PgSysPlayer` equivalent exists.
What the retail PC build gives up that the devkit build does not is the whole binding table and
**every one of the 107 cfunc bodies**, and those are the deliverable.

> **⚠ Corrected (2026-07-26).** A previous revision concluded from the above that *"there is no
> symmetric Xbox↔PC marriage to make here"*. **That is false**, and it cost this map the one
> external name source it had. Against the actual PowerPC image —
> `output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt` — **105 of the 107 binding names in §3
> appear verbatim**; the only two absent are **`IsBoundaryDeath`** and **`ClearGPS`** (reproduce:
> intersect the §3 name column with `set(open(strings).read().split())`). More usefully the
> Xbox build names a **player mode machine** the PC build leaves anonymous: `PgPlayerPDAMapMode`,
> `PgPlayerBinocularsMode`, `PgPlayerHumanMode`, `PgPlayerEnterSeatMode`, `PgPlayerSeatedMode`
> (strings file lines 7507–7533), and `PgPlayerPDAMapMode @825666a8` has a decompiled body in
> `docs/mercs2-pdb-analysis/gui-hud.md:244`. Those five classes are the live lead for the unnamed
> mode fields `player+0x66` and `player+0x1B4` (§2.2). Established by `validation/player_validation.md`
> Pass 2 #31; the 105/107 count re-derived here.

**Boundaries with sibling maps** (cited, not re-derived):

| Belongs to | Not here |
|---|---|
| [`physics_code_map.md`](physics_code_map.md) | `HumanPhysics::Activate` `FUN_004255c0`, the `hkpCharacterProxy` + 5-state on-foot machine, ragdoll |
| [`camera_code_map.md`](camera_code_map.md) | the ≤5-viewport arrays, `FUN_0070f560`, camera modes/shake — this map only covers the *player→camera* handles |
| [`save_serialize_code_map.md`](save_serialize_code_map.md) | the `.profile` on-disk layout, `ProfileHash`, `saveProfile`; it already owns `[0x1176054]` |
| [`vehicle_code_map.md`](vehicle_code_map.md) | seat/ride rings, the drive model |
| [`weapons_combat_code_map.md`](weapons_combat_code_map.md) | damage, health, weapon state |
| [`input_code_map.md`](input_code_map.md) | DirectInput8 device read + the action table |
| planned `human_character_controller_code_map.md` | the `Human` namespace (21 @`0xB99EF0`) and locomotion |

**Sources.** PC: the 42.6k-fn Ghidra decomp `output/_ghidra/mercs2_unpacked.exe_decomp.txt` and the
image it was taken from, `output/_ghidra/securom_dump/mercs2_unpacked.exe` (unpacked SecuROM image,
base `0x00400000`). Every disassembly quoted below is from that image, read through the PE section
table (`.text` VA `0x00401000` raw `0x1000`, `.rdata` VA `0x00B05000` raw `0x705000`, `.data` VA
`0x00BF6000` raw `0x7F6000` — identity-minus-`0x400000` for those three, **not** for `Stext`/`.securom`).

> **⚠ The image is a LIVE DUMP, not a linker output.** Every `.data` value quoted below (container
> headers, `DAT_017C0DD0`, the cheat bytes) is **runtime state captured at dump time**, not a static
> initialiser. Proof that this matters: `ControllerPlayer`'s registrar `FUN_00640410` writes capacity
> `0x100` to `[0x017BCF04]` (`0x00640421 mov ecx, 0x100` / `0x00640453 mov [0x17bcf04], ecx`), yet the
> dumped word reads **`0x60`**. Containers are re-parameterised after registration, through a
> register `this` an absolute-address scan cannot see. Treat every header number as *observed*, and
> re-read it live before a reimpl hardcodes it.

The binding table name→VA is re-derived here from the **namespace registry** rather than taken on
faith: `0x00DFD478` is 31 rows × 12 B `{name*, luaL_Reg*, post_register_chunk*}` terminated by the
zero row at `0x00DFD5EC`; **row 4** is `{"Player", 0x00B98FC0, 0}`. Walking `0x00B98FC0` as
`{const char*, lua_CFunction}` reaches a NULL terminator at `0x00B99318` = **107 rows, 0 stubs, no
sub-table markers**. This agrees entry-for-entry with the live Surface-B `.rdata` walk
`mods/lua_trace_asi/reference/binding_map.json` ([[lua-trace-asi-surface-b-oracle]]) and with
[`../lua_engine_bindings_audit_deep_dive.md`](../lua_engine_bindings_audit_deep_dive.md).

**Script-side traffic counts** are a call-site census `Player\.<Name>\s*\(` over
**`docs/mercs2-luacd/` (370 `.lua`) *plus* `docs/mercs2-dlc-luacd/` (75 `.lua`) = 445 files**;
restricted to the 107 table names it totals **1405**, with **26** zero-call rows and a top-ten sum of
**1054**. *Corrected 2026-07-26:* previous revisions of this line said "the 370 decompiled scripts in
`docs/mercs2-luacd/`". That is wrong by 75 files and anyone re-running it as written gets **1113**,
matching only 54 of the 107 rows — the numbers in §3 were right, the recipe for reproducing them was
not. (A *reference* count without the `(` over both corpora gives 1439 and matches 95/107, so the
census is specifically call sites over both corpora.)

Lua layer: [`../modernization/vanilla_boot_load_order.md`](../modernization/vanilla_boot_load_order.md)
(the `MrxPlayer` boot chain), `docs/mercs2-luacd/07_player_core_cheats_managers.md`.
Companion memories: [[money-fuel-datatype-and-cap]], [[lua-trace-asi-surface-b-oracle]].

**Container names are read, not guessed.** Every bare container address below is named by the master
key: `container[0]` is the vtable and `[vtable+0x34]` is a name accessor — but *only* when the target
is literally `B8 <imm32> C3` (`mov eax,<char* in .rdata>; ret`). That shape is validated before the
string is trusted (widget vtables carry a float getter in the same slot).

**Method / honesty model.** Same discipline as the sibling maps. Confidence: **H** = read body with a
can't-coincide fingerprint (constant, offset, or table walk) · **M** = one strong structural signal ·
**L/open** = positional → confirm-live. Every offset below states the **VA of the instruction** it was
read from, so any row can be re-derived with one disassembly call. Corrections are kept **visible**:
where this map used to say something else, the old wording is quoted in a marked box rather than
silently replaced — the retraction history is part of the evidence.

**Body coverage: 107 / 107.** Ghidra's export carried 50; the remaining **57 were recovered by raw
disassembly of the unpacked image this pass** (capstone, bounded by the next known function start).
There are **no binding-only rows left**. See [[binding-only-is-not-a-wall-disassemble]] — "binding-only"
never meant unrecoverable, only that Ghidra's auto-analysis had no static caller to walk from.

> **SecuROM is not a blocker** ([[securom-decompiled-not-a-blocker]]). The entire `Player` cfunc
> cluster `0x005DA7A0–0x005E0470` sits in clean `.text` and decompiles where Ghidra found an entry
> point. The 57 bodies Ghidra omitted were omitted because a binding-table-only function has **no
> static caller** to walk from — not because of VM islands — and all 57 have now simply been
> disassembled. No `Player` cfunc is behind a SecuROM island.

---

## 0. Result in one line

A **player is not a character**. The player is a **≥`0x465`-byte** controller object living in the ECS
component container at **`0x00DF9B90`**, which names itself **`Players`** (resolve:
`guid → FUN_006496B0 → key/page walk`; `record[0]` is the object pointer, misses return the shared
zero-record `DAT_00DF9C0C`), holding the **slot index `+0x2C`**, the **local viewport id `+0x30`**
(`-1` = not joined), the **remote flag `+0x58`**, its **own guid `+0x1C`** (the handle scripts pass
around), the **attached character GUID `+0x20`**, the **control-source guid `+0x24`** (a `SeatLink`
key carrying a `Controller*` component — the ridden vehicle; `GetControlledObject` falls back to
`+0x20` when it is zero), the reticle target, the boundary callback, and the seat/vehicle control
locks. The roster is **hard-capped at 2** in three compile-time places — `FUN_006CDAF0`
(`GetPlayer(i)`) returns 0 for `i > 1` and linear-scans the container matching `+0x2C`;
`FUN_006CDAC0` counts players with `+0x30 != -1`; `FUN_006CD960` rejects local slots `>= 2`.
Attaching a character (`FUN_006A4060`) writes `player+0x20` — **that field is the possession link**;
the marker-component idiom in the same body belongs to the `CheatInfiniteAmmo` cheat, not to
possession (§5). Everything **persistent** — cash `+0x2C`, fuel `+0x30`, character `+0x61`, upgrade
`+0x62`, costume `+0x63`, available costumes `+0x25E`, fuel capacity `+0x30C`, dirty flag `+0x11` —
lives on a *different* object, the profile/economy singleton `[0x01176054]` that
`save_serialize_code_map.md` already owns. The player roster ticks from the **layer-4 per-system call
list** at **`FUN_0062E810`** (`@0x004C9861`) and **`FUN_0062E7B0`** (`@0x004C9900`). And the full
**107-entry `Player` binding table is recovered name→VA with all 107 bodies read** (§3) — the single
largest thing this map hands the empty `mercs2_player` crate.

---

## 0.5 Master marriage table

| Role | Xbox symbol | PC addr | Married by | Conf |
|---|---|---|---|---|
| **`Player` `luaL_Reg` table** | — (PC `.rdata`) | **`0x00B98FC0`**, 107 entries, 0 stubs | registry `0x00DFD478` row 4 = `{"Player", 0x00B98FC0, 0}`; table NULL-terminates at `0x00B99318` (107 rows) | H |
| **Player cfunc cluster** | — | **`0x005DA7A0`–`0x005E0470`** (contiguous) | every table slot lands in the range; no cfunc shared with any of the other 30 namespaces | H |
| **Player component container = `Players`** | — | **`0x00DF9B90`** (ctor `FUN_00A7C7D0`, vtable `PTR_FUN_00BC3FB8`) | master key: `[[0x00DF9B90]+0x34]` = `FUN_00647BA0` = `B8 <ptr> C3` → **`"Players"`**; and 47 Player cfuncs resolve a handle against it | H |
| **Container resolve** (`Get(guid)`) | — | **`FUN_00423DC0`**; slot lookup **`FUN_006496B0`** | read body; `this+0x20/0x24/0x26/0x48/0x70/0x7c` matches the inlined globals 1:1 | H |
| **`GetPlayer(index)`** | — | **`FUN_006CDAF0`** | `0x006CDAF0: 83 7C 24 04 01  cmp dword [esp+4],1` / `77 6A ja 0x6cdb61`; then scan `DAT_00DF9BA8` for `obj+0x2c == i`. **241 call sites** | H |
| **`GetCurrentPlayers`** | — | **`FUN_006CDAC0`** | read: `0x006CDADF cmp esi,2 / jl`; counts `obj+0x30 != -1` | H |
| **`GetPlayerForCharacter(charGuid)`** | — | **`FUN_006CDB70`** | 4 Player cfuncs call it; Lua splits 6/6 on handle type (§2.2). Body is a genuine VM stub (`0x006CDB70 jmp [0x0245F8CC]` → `0x024E8BD0: push 0x24e8bda; call 0x1aaff10`) | M |
| **Player roster tick** | — | **`FUN_0062E810`** (`@0x004C9861`) + **`FUN_0062E7B0`** (`@0x004C9900`) | both open `A1 A8 9B DF 00  mov eax,[0x00DF9BA8]` (the `Players` live count) and iterate by dense index passing `dt`; sole caller `FUN_004C9740` each | H |
| **Per-player world probe** (*not* the tick) | — | **`FUN_0041FE20`** (`@0x004C9869`) | opens on the generic iterator `FUN_00423B70(&[0x00D8A460])`; never touches `0x00DF9BA8` | H |
| **Attach / detach character** | — | **`FUN_006A4060`**`(playerObj, charGuid)` | read: `0x006A422E mov [ebx+0x20], eax` is the attach write; `0x006A4279 mov [ebx+0x24], edi` (edi=0) clears the control source; `0x006A4314 mov [ebx+0x3a8], eax` caches the char guid. The `0x00DF9B10` add/remove in the same body is **cheat re-application**, not possession (§5) | H |
| **Profile / economy singleton** | `Set/GetProfile{Character,Upgrade,Costume}` (`0x002b00c`–`0x002b070`) | **`[0x01176054]`** | save map §; offsets read here from the six profile cfuncs | H |
| **Max-players setting** | — | **`DAT_017C0DD0`** (= 2 in the dump) | read: pushed verbatim by `GetMaximumPlayers` `FUN_005DDA60`; **nothing enforces it** (§2.3) | H |
| **`ControllerPlayer` component** | — | registrar **`FUN_00640410`**, container `0x017BCEF8`, elem `0x0C` | `s_ControllerPlayer_00BC4EF0` + `CopyFromStream` registrar shape | H |
| **`GrappleParameters` component** | — | registrar **`FUN_00643D50`**, container `0x017BE848`, elem `0x1C` | `s_GrappleParameters_00BC55D4` | H |
| **`VehicleDisguiseScale` component** | — | registrar **`FUN_006413F0`**, container `0x017BD5D8`, elem `0x0C` | `s_VehicleDisguiseScale_00BC5098` | H |
| **`GetPlayerStart`** | — | **`FUN_005DEC60`** → literal `"PlayerLocation_Start"` | read: pushes the string, nothing else | H |
| **Costume swap → stream-in** | — | **`FUN_005DF980`** (`SetOutfit`) | read: `FUN_00649180(&PTR_PTR_00DF6C08, …)` then 3 streaming calls | H |
| **`CheatInfiniteAmmo` container** (touched by the player attach **and** `Object.SetInfiniteAmmo`) | — | `0x00DF9B10` (ctor `FUN_00A7C7A0`, vtable `0x00BC3F48`) | master key: `[[0x00DF9B10]+0x34]` = `FUN_00647B90` → **`"CheatInfiniteAmmo"`**. Header in the dump: capacity `0x100`, buckets `0x80`, **element size 1 byte**, shift 7. **Not** a possession marker (§5, §9) | H |
| **`Net.IsClient` / `Net.IsServer`** | — | `DAT_00DFBD77` / `DAT_00DFBD78` | five consecutive `Net` accessors over five consecutive bytes; `0x005C67D1: 8A 1D 77 BD DF 00  mov bl, byte [0xdfbd77]` (§7) | H |
| **`PCPlayer` string** | — | `s_PCPlayer_00BE2BEC` @ `FUN_008445D0` | **online client identity**, *not* the gameplay player — recorded so it isn't misread | H |

---

## 1. Where the player sits in the frame

> **⚠ RETRACTED CORRECTION — the sibling maps were right all along (2026-07-26).**
>
> A previous revision of this section claimed the per-system call list is **not** reached from layer 4
> of the master update, and re-rooted it under `FUN_004C13A0`. **Both halves of that claim were
> wrong**, and this map was the source of the error, not the fix. It is recorded rather than quietly
> reverted because the *reasoning* failure is the reusable lesson.
>
> - The evidence offered was "`FUN_004C15E0` contains **zero** references to `FUN_004C0EC0`". That is
>   true, and it means nothing: **the call is virtual.** Reproduce, four reads:
>
>   ```
>   0x004C1633  8B 50 0C        mov edx, [eax + 0xc]     ; vtable slot +0x0C
>   0x004C163C  FF D2           call edx                 ; the master update's dispatch
>   [0x017BBCCC + 4*4] = 0x00D6C244   ; FUN_004C1170 @0x004C1259:
>                                     ;   C7 04 85 CC BC 7B 01 44 C2 D6 00
>                                     ;   mov dword [eax*4 + 0x17bbccc], 0xd6c244   (eax == 4)
>                                     ; then [0x17BBCF4] = 5 (count), [0x17BBCFC] = 4 (pivot)
>   [0x00D6C244] = 0x00BB0460         ; the layer-4 object's vtable
>   [0x00BB046C] = 0x004C09C0         ; slot +0x0C = the game-state pump
>   ```
>
>   *A missing static edge is what virtual dispatch looks like; it is not evidence of absence.*
> - `FUN_004C13A0`'s static call site `0x00631AAF` is the **shutdown** path, not the frame path: it
>   sits after the main loop's back-edge (`0x00631A99 0F 84 99 FE FF FF  je 0x631938`) and after the
>   `ReleaseMutex` at `0x00631AA9`, and it forces `[0x00D6C24C] = 3` (`0x004C13C3`) before calling the
>   pump with `fldz`. `FUN_004C09C0` dispatches on `[ecx+8]` (`0x004C09F0 mov eax,[ecx+8]`, then three
>   `sub eax,1`) and the **only** `call 0x4c0ec0` in it is at `0x004C0B6A`, inside the `state == 2`
>   arm — so on the `FUN_004C13A0` route the chain below cannot execute at all.
>
> So `camera_code_map.md`, `world_streaming_code_map.md`, `input_code_map.md`,
> `population_spawner_code_map.md` and `vehicle_code_map.md` never inherited an error, and the
> retraction that was flagged against them is itself withdrawn. Established by the blind validation
> pass (`validation/player_validation.md`).

```
FUN_00631670  app / main loop
  └─ @0x00631938 → FUN_00630EF0  RunFrame
         └─ FUN_004C14F0  MASTER UPDATE → FUN_004C15E0   (5 layers, 0→4)
              └─ layer 4 object (registered by FUN_004C1170, array 0x017BBCCC)
                   └─ VIRTUAL call [vtbl 0x00BB0460 + 0x0C] @0x004C163C
                        └─ FUN_004C09C0   ★ GAME-STATE PUMP  (state table PTR_PTR_01175C80,
                             │             current state DAT_01175C7C)
                             └─ FUN_004C0EC0
                                  └─ FUN_004C9740   per-system call list
                                       ├─ FUN_00872D30  world streaming  (world_streaming_code_map §2)
                                       ├─ FUN_00502510  population
                                       ├─ FUN_00532F80  vehicle-control pump  (vehicle_code_map)
                                       ├─ FUN_00675E50  Rt* / LOD proxies
                                       ├─ FUN_0062E810  ★ PLAYER ROSTER TICK A  (@0x004C9861)
                                       ├─ FUN_0041FE20  per-player world probe  (@0x004C9869)
                                       └─ FUN_0062E7B0  ★ PLAYER ROSTER TICK B  (@0x004C9900)

FUN_004C13A0  (shutdown only — @0x00631AAF, past the loop's back-edge)
```

**Consequence — RESOLVED (2026-07-26), and it is not what this map first said.** The per-system list
is reached *through* the game-state pump, but **"which game state am I in" does NOT gate the
simulation.** Read the two branches:

```
0x004C0B03  BE 01 00 00 00        mov esi, 1                     ; esi := 1 from here on
0x004C0B08  39 35 94 5A 17 01     cmp dword [0x01175a94], esi     ; ★ THE REAL GATE
0x004C0B0E  0F 84 A4 00 00 00     je  0x4C0BB8                    ;   == 1  -> skip everything
0x004C0B14  8B 0D 7C 5C 17 01     mov ecx, [0x01175c7c]           ; current game state
0x004C0B1A  3B CB                 cmp ecx, ebx                    ; ebx == 0 (xor ebx,ebx @0x4C09CA)
0x004C0B1C  74 3D                 je  0x4C0B5B                    ;   NULL -> skip ONLY the state's Update
0x004C0B42  FF D2                 call edx                        ;   the state's own Update (virtual)
0x004C0B5B  39 35 94 5A 17 01     cmp dword [0x01175a94], esi     ; re-tested
0x004C0B61  74 1A                 je  0x4C0B7D
0x004C0B6A  E8 51 03 00 00        call 0x4C0EC0                   ; -> FUN_004C9740 -> the player ticks
```

`je 0x4C0B5B` skips only the state's own `Update` virtual call and then falls through to
`FUN_004C0EC0` regardless — **a stateless frame still ticks the world.** The gate that *does* exist is
**`[0x01175A94] != 1`**, checked twice (`0x004C0B08` and again at `0x004C0B5B`); the other gates are
the app-stack phase `== 2` and the foreground / `Sleep(100)` predicate. So "does not tick in
shell/loading/pause" — flagged plausible-but-unproven in a previous revision — is **withdrawn**;
`[0x01175A94]` is a level-transition handshake, not a pause flag. Established by
`mission_contract_flow_code_map.md`'s pass-2 validation; the branch bytes re-read here.

**`FUN_0041FE20`** (1145 B, sole caller `0x004C9869` inside `FUN_004C9740`) is an iterator loop —
`FUN_00423B70(&cursor)` yields `(key, value, kind)` until exhausted — with two arms:

- **kind 0**: builds a world-space segment and issues a **Havok cast** (`thunk_FUN_024E6190`,
  filter constant `0x223F6FDA`; the arm is gated on `FUN_006886A0(0x892CF579)`), then on a hit calls
  `FUN_004202A0(playerObj + 0xBC, …)`. Shape = a per-player world probe (line-of-sight / ground /
  grapple candidate). The *semantic* is inferred from geometry — **confirm-live**.
- **kind 1**: resolves a record out of the player container (the same key/page walk as §2), takes
  `obj = *record`, calls `FUN_004209F0`, and then — **only if `obj+0x30 != -1` and `obj+0x58 == 0`**
  and `FUN_006CDAC0() > 1` — calls `FUN_006C1E70`. That last guard is *literally* "more than one
  player is present", i.e. the **split-screen/co-op-only** branch.

Both arms bail unless `FUN_005857E0()` resolves the world object and its vtable `+0xE0` query
returns 1 (the world-present gate the camera and vehicle maps also use).

> **⚠ Corrected (2026-07-26).** An earlier revision labelled `FUN_0041FE20` "★ THE PLAYER SYSTEM
> TICK". It is not; it is *a* layer-4 entry that consumes player records. The functions that actually
> walk the roster are **`FUN_0062E810`** and **`FUN_0062E7B0`**. Reproduce — the three call sites are
> 15 bytes apart inside `FUN_004C9740`, each preceded by an `fstp [esp]` pushing `dt`:
>
> ```
> 0x004C9861  E8 AA 4F 16 00   call 0x0062E810      ; ★ roster tick A
> 0x004C9869  E8 B2 65 F5 FF   call 0x0041FE20      ;   per-player world probe
> 0x004C9900  E8 AB 4E 16 00   call 0x0062E7B0      ; ★ roster tick B
> ```
>
> and the two roster ticks open on the live count while the probe does not:
>
> ```
> 0x0062E811  A1 A8 9B DF 00   mov eax, [0x00DF9BA8]    ; Players live count
> 0x0062E7B1  A1 A8 9B DF 00   mov eax, [0x00DF9BA8]
> 0x0041FE34  A1 60 A4 D8 00   mov eax, [0x00D8A460]    ; a generic iterator handle, not Players
> ```
>
> `FUN_0062E7B0` calls **`FUN_006A1880`** per player (`0x0062E7F6`) and `FUN_0062E810` calls
> **`FUN_006A0770`** (`0x0062E856`), both with the player object in **EAX** (a register arg Ghidra
> drops). `FUN_006A1880` opens `mov eax,[edi+0x20]` / `cmp byte [edi+0x66],4` and queries the
> character's `RuntimeHealth` container `0x017BEF78` — unmistakably a per-player roster pass. The
> original caveat — that `FUN_0041FE20` lives in the `0x0042xxxx` cluster with `HumanPhysics::Activate`
> and might not be a player-manager pass — was the right instinct; this is the answer. Found by the
> blind validation pass (`validation/player_validation.md`); every byte above re-read here.

---

## 2. The player container and the Player object

### 2.1 The container (`0x00DF9B90` = `Players`) — H

Registered by the static ctor `FUN_00A7C7D0` (vtable `PTR_FUN_00BC3FB8`). It **names itself**:
`[0x00DF9B90] = 0x00BC3FB8`, `[0x00BC3FB8 + 0x34] = 0x00647BA0`, and `FUN_00647BA0` is literally
`B8 <ptr> C3` → the string **`"Players"`**. Twenty-three `Player` cfuncs **inline** the identical
lookup, which is the second, independent reason the container belongs to this namespace:

```c
slot = FUN_006496B0(guid);                                  // guid → dense slot, -1 on miss
if (slot < 0) goto miss;
key    = *(u32*)(DAT_00DF9BD8 + slot*4);                    // container +0x48  key array
record = (DAT_00DF9BB0 - 1 & key) * (short)DAT_00DF9BB4     // +0x20 mask, +0x24 elem stride
       + *(int*)(DAT_00DF9C00 + (key >> (DAT_00DF9BB6 & 0x1f)) * 4);   // +0x70 page table, +0x26 shift
if (!record) miss: record = &DAT_00DF9C0C;                  // +0x7c shared ZERO record
obj = *record;                                              // record[0] = the Player object
if (!obj) return nil;                                       // every cfunc checks this
```

The non-inlined form is **`FUN_00423DC0`** (`this` in ESI), byte-for-byte the same walk with
`this+0x20/+0x24/+0x26/+0x48/+0x70`, returning `this+0x7c` on miss. `DAT_00DF9BA8` is the **live
record count** (`FUN_006CDAF0` bounds its scan by it).

**Resolve-path census — 47 of 107, not 8.**

> **⚠ Corrected (2026-07-26).** A previous revision said *"Eight `Player` cfuncs inline the identical
> lookup … the eight inliners are exactly the cfuncs that take a player GUID"*, and named
> `GetCameraXZHeading`, `GetViewport`, `SetCinematicMode`, `IsPositionOutBoundary`,
> `SetSeatMovementLocks`, `SetVehicleControlsLock`, `GetTargetUnderReticle`,
> `SetSwimmingSearchRadius`. Those eight are real but they are a **strict subset**; the "exactly"
> was an artefact of only having Ghidra's 50 bodies. With all 107 disassembled the real figure is
> **47**. Found by `validation/player_validation.md`; re-derived here.

Disassemble all 107 bodies bounded by the next table entry point, and classify by how each one turns
a Lua handle into an object:

| resolve path | count |
|---|---:|
| inlines the walk (`B9 90 9B DF 00  mov ecx, 0x00DF9B90`) | **23** |
| calls `FUN_00423DC0` (`BE 90 9B DF 00  mov esi, 0x00DF9B90`) | **24** |
| — **union: takes a player handle through `Players`** | **47** |
| calls `FUN_006CDB70` — takes a **character** handle | **4** |
| by index (`FUN_006CDAF0` 21 / `FUN_006CD960` 3 / `FUN_006CDAC0` 1) | 25 |
| touches the profile singleton `[0x01176054]` | 16 |
| no resolve at all (constants, callbacks, the `ClaimSeat` family, `SetOutfit`, `Set/GetVehicleDisguise`) | 18 |

The 23 inliners: `ClearGPS, ClearPlayerDB, GetAllBoundaryGuid, GetCamera, GetCameraXZHeading,
GetCharacter, GetControlBindingType, GetControlledObject, GetOutBoundary, GetPlayerId,
GetRetryPosition, GetSeat, GetTargetUnderReticle, GetViewport, GetViewportId, InCinematicMode,
IsInWarningZone, IsPositionOutBoundary, RequestPDAMapModeCancel, SetCinematicMode,
SetSeatMovementLocks, SetSwimmingSearchRadius, SetVehicleControlsLock`.
The 24 via `FUN_00423DC0`: `AddBoundary, AddSatelliteScanTarget, CheckSpawnPos, IsLocal,
RemoveAllBoundary, RemoveBoundary, RequestPDAMapModeExit, SetAimMode, SetBoundaryCallback,
SetGrappleEnabled, SetHealthClamp, SetInPmc, SetInputEnabled, SetOutBoundary, SetPDAMapMode,
SetPDAMapModeCallback, SetPDAMapModeCancelCallback, SetSatelliteScanCallbacks, SetSatelliteScanMode,
SetSatelliteScanPaused, SetScopeEnabled, SetSurvivalMode, SetSurvivalModeCallback,
SetupSatelliteScan`.

*Reproduce:* count `mov ecx, 0xdf9b90` / `mov esi, 0xdf9b90` sites inside each body, bounding each
body by the **next entry point in the `0x00B98FC0` table** (sorted). Bounding instead by "first `ret`
followed by `int3`" over-runs: `SetSwimmingSearchRadius` `0x005E0170` then swallows `VehicleDisguise`
`0x005E02A0` and appears to call `FUN_006CDB70`, which it does not.

**Container header, as observed in the dump** (see the live-dump caveat in Sources): `+0x0C`
capacity **8**, `+0x18` live count (runtime), `+0x20` buckets **8**, `+0x24` element stride **4** (a
pointer), `+0x26` page shift **3**, `+0x2C` seed `0x9E3779B9`, `+0x48` key array, `+0x70` page table,
`+0x7C` null sentinel (= the `0xDF9C0C` literal that 22 `Player` cfuncs inline). Note **`0x00DF9B9C` (`+0x0C`,
"capacity") has zero references binary-wide** — nothing reads it, it bounds nothing. The only
enforced roster bound is the three compile-time `2`s in §2.3.

### 2.2 The Player object layout

Read first-hand; every row states the **VA of the instruction** it came from, so each is a one-line
re-read. **Minimum size `0x465`** — the largest field written straight off the resolved object is
`+0x464` (`0x005DFEA5: 88 88 64 04 00 00  mov byte [eax+0x464], cl`).

> **⚠ Corrected (2026-07-26) — the size was stated three different ways.** §0 said "~`0x464`-byte",
> this section said "minimum size `0x461`", and §9 said "largest observed offset is `+0x460`". All
> three predate the recovery of `SetWaitForInGame` / `SetInPmc` / `SetAimMode`, whose stores land at
> `+0x461`, `+0x463`, `+0x464`. **The answer is ≥ `0x465`** and every section now says so.

> **⚠ THE TRAP IN THIS TABLE.** Several bodies dereference **again** before applying an offset —
> `mov eax,[eax+8]` and *then* `[eax+0x4F5]`. An offset read after an unnoticed extra load belongs to
> a *different* object. `player+0x08` is a pointer to a boundary sub-object, and `+0x4F5` / `+0x4F7`
> live on **that**, not on the player. This mis-read cost the blind validation pass two rows of its
> own table. Before trusting any offset here, confirm the base was reached by
> `call 0x423DC0 ; mov eax,[eax]` (or the inlined walk) and nothing further.

| Off | Field | Read from (VA) | Conf |
|---|---|---|---|
| `+0x04` | list head (walked `while (p) p = *(p+8)`) | `FUN_006A4060` `0x006A417E` | L |
| **`+0x08`** | **pointer to the boundary sub-object** (`+0x4F5` out-of-boundary, `+0x4F7` warning zone live on it) | `GetOutBoundary` `0x005DC7D6 mov eax,[eax+8]` → `0x005DC7DD mov al,[eax+0x4f5]`; same in `IsInWarningZone` `0x005DC8CD/8D6`, `IsBoundaryDeath` `0x005DD0D2` | H |
| **`+0x1C`** | **the player's OWN guid** — the handle every script passes to `Player.*`/`Object.*` | `GetPrimaryPlayer` `0x005DD8A0`, `GetSecondaryPlayer` `0x005DD900`, `GetLocalPlayer` `0x005DE0B0`, `GetAllPlayers`, `DestroyPlayer`, `TeleportCamera` all return exactly this field | H |
| **`+0x20`** | **attached character GUID — the possession link** | attach write `0x006A422E: 89 43 20  mov [ebx+0x20], eax`; read by `GetCharacter` `0x005DA870`, `GetPrimaryCharacter` `0x005DD960`, `GetSecondaryCharacter` `0x005DD9E0`, `GetLocalCharacter`, and both roster ticks (`FUN_006A1880` `0x006A188B`) | H |
| **`+0x24`** | **control-source guid** — a **`SeatLink`** key whose entity carries a `Controller*` component; the ridden vehicle, else 0 | `0x006A4279 mov [ebx+0x24], edi` (edi = 0) **clears it on attach**; `GetSeat` `0x005DA940` returns it to Lua **raw**; `GetControlledObject` `0x005DAA20` uses it as a key (below); `GetControlBindingType` `0x005DD430` probes six `Controller*` containers with it; `Object.IsPlayerControlled` `FUN_005CDFF0` tests the queried guid against it | H |
| `+0x28` | local id | `GetLocalId` `0x005DE06C mov edi,[eax+0x28]` | H |
| **`+0x2C`** | **player index (0..1)** — the roster key | `FUN_006CDAF0` (`cmp [ecx+0x2c], ebp`), `GetPlayerId` `0x005DDD02`, `IsLocal` | H |
| **`+0x30`** | **join / viewport id; `-1` = not joined** | `FUN_006CDAC0` `0x006CDAD3 cmp dword [eax+0x30], -1`; `IsJoined`, `IsRemote`, `GetViewport(Id)`, `FUN_00714230` | H |
| **`+0x58`** | **remote flag** — 0 = local, ≠0 = remote | `IsLocal` `0x005DDE9E cmp byte [eax+0x58], bl`; `IsRemote` `0x005DDF41 cmp byte [eax+0x58], 0`. `IsLocal` = `+0x30 != -1` **and** `+0x58 == 0`; `IsRemote` = `+0x30 != -1` **and** `+0x58 != 0` | H |
| `+0x66` | mode/state byte, compared `== 4` | `IsBoundaryDeath` `0x005DD0C3 cmp byte [esi+0x66], 4`; roster tick `FUN_006A1880` `0x006A1896` (same compare). Candidate name source: the Xbox `PgPlayer*Mode` classes (see Scope) | M |
| `+0xBC` | per-player probe block passed to `FUN_004202A0` | `FUN_0041FE20` | L |
| `+0x11C` | **target-under-reticle GUID** | `FUN_005DD6B0` | H |
| `+0x124` / `+0x12C` | reticle hit payload (pushed as 2 values) / third word | `GetTargetUnderReticle` `0x005DD771 mov ecx,[eax+0x12c]` | M |
| `+0x148` | retry position | `GetRetryPosition` `0x005DF2B7 lea edi,[eax+0x148]` | M |
| `+0x158` | grapple-enabled byte | `SetGrappleEnabled` `0x005DFC85 mov byte [eax+0x158], cl` | H |
| `+0x180` / `+0x198` | survival-mode pair | `SetSurvivalMode` → `FUN_006A2340` | L |
| `+0x199` | health-clamp byte | `SetHealthClamp` `0x005DC5C5 mov byte [eax+0x199], cl` | H |
| `+0x19C` / `+0x1B8` | scope **refcount** (+1 enable / −1 disable) / scope sub-object (`[+0x1B8]->[+0x10] = 1`) | `SetScopeEnabled` → `FUN_006A21E0` | M |
| `+0x1A8` → SUB | PDA-map-mode sub-object (`+0x30/34/38/3C/40/44/48/49` live on **it**) | `SetPDAMapModeCallback`, `RequestPDAMapModeCancel` `0x005DB658` | M |
| `+0x1AC` → SUB | satellite-scan sub-object (`+0x0C/14/28/2C/34` live on **it**) | `AddSatelliteScanTarget`, `SetSatelliteScanPaused` | M |
| `+0x1B4` | cinematic-mode counter | `InCinematicMode` `0x005DC146 cmp dword [eax+0x1b4], 0` | H |
| `+0x1BC` | attachment/child count | `FUN_006A4060` `0x006A41F7`, `0x006A42F8` | L |
| `+0x244` / `+0x245` | input-enabled pair | `SetInputEnabled` `0x005DC364 mov byte [eax+0x244], dl` / `0x005DC36A mov byte [eax+0x245], bl` | H |
| `+0x380` | **boundary callback ref** | `FUN_005DCD60` `0x005DCE44` | H |
| `+0x384` | boundary callback context | `FUN_005DCD60` `0x005DCE4A` | H |
| `+0x390` | **this player's PDA widget id** | `FUN_005BA500` `0x005BA5E1 mov [ecx+0x390], eax` (`_GuiInternal.SetPlayerPDAWidget`) | H |
| `+0x398` | GPS slot (cleared by `ClearGPS` → `FUN_006A0FB0`) | `FUN_005BA500` `0x005BA613 cmp dword [ebx+0x398], esi` | M |
| `+0x3A8` | **first word of the vehicle-disguise sub-struct**, initialised with the attached character guid | write `0x006A4314: 89 83 A8 03 00 00  mov [ebx+0x3a8], eax` where `eax = [ebx+0x20]`; used as a *base* by `GetVehicleDisguiseState` `0x005E052B lea edi,[eax+0x3a8]` → `FUN_006ABC30`/`FUN_006ABC50` | H |
| `+0x430`/`+0x434` | vehicle-disguise fields | `VehicleDisguise` `FUN_005E02A0` | M |
| `+0x438` | vehicle-disguise flag, **bit 3** (`^= (v<<3 ^ cur) & 8`) | `FUN_005E02A0` | M |
| **`+0x450`** | **widget-type hash**, compared against `0xFA62754E` | `0x005BA646: 81 B9 50 04 00 00 4E 75 62 FA  cmp dword [ecx+0x450], 0xfa62754e`, and `pandemic_hash_m2("PDA") == 0xFA62754E` (`python tools/pandemic_hash.py` / `ph.pandemic_hash_m2("PDA")`). **Was "role unknown, L/open"** | H |
| `+0x454` | target-marker field | `GetAllTargetMarkerPos` `0x005DF320 mov edi,[eax+0x454]` | M |
| `+0x45C` | tick gate (byte) | roster tick `FUN_006A1880` `0x006A18C2`/`0x006A18CF` | M |
| `+0x45D`/`+0x45E`/`+0x45F` | **seat movement locks ×3** (default 1 each) | `SetSeatMovementLocks` `0x005DD295`–`0x005DD2A1` | H |
| `+0x460` | **vehicle controls lock** | `SetVehicleControlsLock` `0x005DD3F2` | H |
| **`+0x461`** | **wait-for-in-game latch** (set to 1 only, never cleared here) | `SetWaitForInGame` `0x005DF1C4: C6 80 61 04 00 00 01  mov byte [eax+0x461], 1` | H |
| **`+0x463`** | in-PMC flag | `SetInPmc` `0x005DFD95: 88 88 63 04 00 00  mov byte [eax+0x463], cl` | H |
| **`+0x464`** | aim mode | `SetAimMode` `0x005DFEA5: 88 88 64 04 00 00  mov byte [eax+0x464], cl` | H |

**`+0x24` resolves to the ridden vehicle through `SeatLink`, and the container is `0x00DF8188`.**
`GetControlledObject` does `0x005DAB0E BE D8 81 DF 00  mov esi, 0xdf81d8` then `call 0x648D80`, and
indexes `[0xDF81EC]` / `[0xDF81CC]`. `0xDF81D8` is *not* a container base — the generic form
`FUN_0042BF80` shows the idiom is `lea esi,[edi+0x50]` with `edi` the base, `[edi+0x64]` and
`[edi+0x44]` the two tables:

```
0x0042BF82  8D 77 50   lea esi, [edi + 0x50]   ; edi = CONTAINER BASE
0x0042BF88  E8 …       call 0x00648D80         ; guid -> index, this = base+0x50
0x0042BF95  8B 4F 64   mov ecx, [edi + 0x64]
0x0042BF9B  8B 47 44   mov eax, [edi + 0x44]
```

`0xDF81D8 − 0x50 = 0xDF81EC − 0x64 = 0xDF81CC − 0x44 = ` **`0x00DF8188`**, which names itself
**`SeatLink`** (`[[0x00DF8188]+0x34] = FUN_006418E0 = B8 <"SeatLink"> C3`). When `+0x24` is zero,
`0x005DAB3B mov edi,[eax+0x20]` falls back to the character. *(Pass 1 of the validation read `ESI` as
the base and filed the map's `0x00DF8188` as CONTRADICTED; Pass 2 retracted that, and the arithmetic
above is why. **The map was right.**)*

**Four cfuncs take a CHARACTER handle, not a player handle.** `IsBoundaryDeath` `0x005DD0AC`,
`SetWaitForInGame` `0x005DF1BB`, `VehicleDisguise` `0x005E0362` and `GetVehicleDisguiseState`
`0x005E0522` all reach the player object through **`FUN_006CDB70`** rather than the `Players`
container. `FUN_006CDB70` is a genuine SecuROM VM stub (`jmp [0x0245F8CC]` → `0x024E8BD0:
push 0x24e8bda; call 0x1aaff10`), so it is named by behaviour: every call site passes one register
argument in EAX with no stack cleanup, the returned object is written at `+0x461`/read at
`+0x30`/`+0x58`/`+0x66`/`+0x08` — all independently-established **player** fields — and the Lua splits
**6/6** on handle type:

| cfunc | resolve | Lua call site |
|---|---|---|
| `SetAimMode` / `SetHealthClamp` / `SetGrappleEnabled` | `Players` | `Player.SetHealthClamp(uPlayer, true)` `hero.lua:195` |
| `IsBoundaryDeath` | **`FUN_006CDB70`** | `Player.IsBoundaryDeath(uChar)` `mrxplayer.lua:342,349` |
| `SetWaitForInGame` | **`FUN_006CDB70`** | `Player.SetWaitForInGame(uHero)` `mrxutil.lua:194` |
| `VehicleDisguise` / `GetVehicleDisguiseState` | **`FUN_006CDB70`** | `local uRider = Player.GetLocalCharacter()` … `Player.VehicleDisguise({Player = uRider, …})` `wiftutorialvehicledisguise.lua:16-18,35` |

So **`FUN_006CDB70` = `GetPlayerForCharacter(charGuid) -> Player*`** (confidence **M** — behavioural,
because the body is VM-executed; raising it to H needs the SecuROM recovery pipeline or a live
`EAX` compare at `0x005E0527`). The practical consequence: the `Player = …` key in
`VehicleDisguise`/`GetVehicleDisguiseState`'s Lua argument table holds a **character** guid. A reimpl
that models these four bindings as taking a player handle will silently fail.

**A note on what settles a "player field", because this map got the reasoning wrong once.** An earlier
draft speculated `+0x158` and `+0x199` might be on the *human* object, since `FUN_00423DC0` shares the
`0x0042xxxx` module with `HumanPhysics`, then presented `mov esi, 0x00DF9B90` as the fix. The
conclusion was right but **the cited evidence was not load-bearing**: `mov esi, <global>` establishes
the *container*, and ESI still holds it at the moment of the store. What actually settles it is the
pair of instructions after the call:

```
SetGrappleEnabled  0x005DFC61  BE 90 9B DF 00   mov  esi, 0x00DF9B90   ; the container
                   0x005DFC66  E8 55 41 E4 FF   call 0x00423DC0        ; -> *slot
                   0x005DFC6B  8B 00            mov  eax, [eax]        ; ★ -> the PLAYER OBJECT
                   0x005DFC85  88 88 58 01 00 00  mov byte [eax+0x158], cl
SetHealthClamp     0x005DC5A1  BE 90 9B DF 00   mov  esi, 0x00DF9B90
                   0x005DC5A6  E8 15 78 E4 FF   call 0x00423DC0
                   0x005DC5AB  8B 00            mov  eax, [eax]        ; ★
                   0x005DC5C5  88 88 99 01 00 00  mov byte [eax+0x199], cl
```

They are **player** fields. Two lessons worth keeping: *module adjacency is not ownership*; and when
the decompiler drops a register argument, the disassembly still has it — but the deref chain, not the
`mov esi`, is what proves which object you landed on.

### 2.3 The roster is 2, and it is a scan not an array — H

```c
int FUN_006CDAF0(uint i) {              // Player.GetPlayer(i) / the internal by-index accessor
  if (1 < i) return 0;                  // ★ HARD CAP: two players
  for (slot = 0; slot < DAT_00DF9BA8; slot++) {
     rec = <page walk>;                 // same walk as §2.1
     if (rec && (obj = *rec) && *(uint*)(obj + 0x2c) == i) return obj;
  }
  return 0;
}
int FUN_006CDAC0(void) {                // Player.GetCurrentPlayers
  for (n = 0, i = 0; i < 2; i++)        // ★ same cap, independently
     if ((o = FUN_006CDAF0(i)) && *(int*)(o + 0x30) != -1) n++;
  return n;
}
```

The three caps are compile-time immediates; read them:

```
FUN_006CDAF0  0x006CDAF0  83 7C 24 04 01   cmp dword [esp + 4], 1
              0x006CDAF5  77 6A            ja  0x006CDB61          ; i > 1 -> return 0
FUN_006CDAC0  0x006CDADF  83 FE 02         cmp esi, 2
              0x006CDAE2  7C E2            jl  0x006CDAC6          ; loop i < 2
FUN_006CD960  0x006CD961  83 7C 24 08 02   cmp dword [esp + 8], 2
              0x006CD966  7C 05            jl  0x006CD96D          ; local slot >= 2 -> return -1
```

`FUN_006CD960` is the local-slot → player-index mapper used by `GetLocalPlayer` /
`GetLocalCharacter`; it then scans `DAT_00DF9BA8` like the other two.

`FUN_006CDAF0` has **241 call sites** across the binary (instruction-accurate: linear-disassemble
every one of the 43 027 known entry points and count `call 0x6cdaf0`) — it is the canonical "give me
player N" accessor. *Corrected 2026-07-26: a previous revision said "60+ call sites" and "the cap is
a compile-time constant in two places"; the count was a Ghidra xref floor and the cap is in three
places.* The cap is **not** a read of `DAT_017C0DD0`; `DAT_017C0DD0` (= 2 in the dump) is only what
`Player.GetMaximumPlayers` (`FUN_005DDA60`) reports to script. A mod that raises the reported maximum
therefore does **not** widen the roster.

Two further limits exist and neither binds. The `Players` container header carries capacity 8 at
`0x00DF9B9C` — but that address has **zero references binary-wide**; nothing reads it. And
`GetMaximumLocalPlayers` / `GetCurrentLocalPlayers` do not query anything at all (§3.1).

---

## 3. The `Player` binding surface — all 107, name → VA

`luaL_Reg` table **`0x00B98FC0`**, **0 stubs** (every slot points at a real body — contrast `Ai`
18/66 stubbed, `Debug` 6/6). Cfuncs are `undefined4 f(lua_State *L)`; args via
`FUN_0059FF50`/`FUN_0059F6D0`/`FUN_0059F780`/`FUN_0059F820`/`FUN_0059FB00`, results via
`FUN_0085D5D0` (reserve) + the `*(L+8) += 8` push idiom.
**Lua value tags observed:** `2` = lightuserdata (**GUIDs**), `3` = number, `1` = boolean, `0` = nil —
`lua_Number` is a **32-bit float**, so a pushed number appears in the decomp as raw bits
(`4.2039e-45` == `3`). Consistent with [[money-fuel-datatype-and-cap]].

> **⚠ Corrected (2026-07-26): `FUN_004B2A50` is `push nil; return 1`, not an error path.** Previous
> revisions of this line said "errors via `FUN_004B2A50`", and that gloss quietly turned every
> not-found branch in this map into a failure. The whole body is nine instructions:
>
> ```
> 0x004B2A50  8B 0E              mov ecx, [esi]          ; esi -> lua_State*
> 0x004B2A52  B8 01 00 00 00     mov eax, 1              ; reserve 1 slot
> 0x004B2A57  E8 74 AB 3A 00     call 0x0085D5D0
> 0x004B2A5E  75 01              jne 0x004B2A61
> 0x004B2A60  C3                 ret                     ; reserve failed -> return 0
> 0x004B2A61  8B 06              mov eax, [esi]
> 0x004B2A63  8B 48 08           mov ecx, [eax + 8]      ; stack top
> 0x004B2A66  C7 41 04 00 00 00 00  mov dword [ecx+4], 0 ; ★ TAG = 0 = LUA_TNIL
> 0x004B2A6D  83 40 08 08        add dword [eax + 8], 8  ; push
> 0x004B2A76  C3                 ret                     ; return 1
> ```
>
> The same idiom appears inlined all over the cfunc cluster (e.g. `SetVehicleDisguise`
> `0x005E00ED mov dword [ecx+4], 0`). **Consequence, swept through this map:** a `Player.*` call whose
> handle does not resolve returns **`nil` with no error raised** — Lua sees a value, not a `pcall`
> failure, and idioms like `if Player.GetCharacter(u) then` are the intended contract. Any reimpl that
> raises a Lua error on a bad handle diverges from retail.

**⬤ = body in the Ghidra export (50)** · **▨ = recovered by raw disassembly this pass (57)** · *calls* = script call sites. **There are no binding-only rows left: 107 / 107 bodies are read.**

| # | Name | VA | | calls | | # | Name | VA | | calls |
|--:|---|---|:-:|--:|---|--:|---|---|:-:|--:|
| 0 | `GetCharacter` | `0x005DA870` | ▨ | 93 | | 54 | `GetLocalPlayerId` | `0x005DE150` | ▨ | 3 |
| 1 | `GetControlledObject` | `0x005DAA20` | ▨ | 13 | | 55 | `GetLocalCharacter` | `0x005DE1D0` | ▨ | 165 |
| 2 | `GetSeat` | `0x005DA940` | ▨ | 0 | | 56 | `GetAnyCharacter` | `0x005DE260` | ⬤ | 223 |
| 3 | `GetName` | `0x005DA7A0` | ▨ | 0 | | 57 | `GetAllCharacters` | `0x005DE2A0` | ⬤ | 26 |
| 4 | `GetCameraXZHeading` | `0x005DAB50` | ⬤ | 3 | | 58 | `CreatePlayer` | `0x005DE2E0` | ▨ | 2 |
| 5 | `GetViewport` | `0x005DACC0` | ⬤ | 0 | | 59 | `DestroyPlayer` | `0x005DE440` | ▨ | 2 |
| 6 | `GetViewportId` | `0x005DAF10` | ▨ | 4 | | 60 | `ClearPlayerDB` | `0x005DE3C0` | ▨ | 2 |
| 7 | `GetCamera` | `0x005DAFF0` | ▨ | 25 | | 61 | `AttachToCharacter` | `0x005DE4E0` | ⬤ | 4 |
| 8 | `TeleportCamera` | `0x005DB0D0` | ⬤ | 3 | | 62 | `DetachFromCharacter` | `0x005DE5D0` | ▨ | 4 |
| 9 | `CheckSpawnPos` | `0x005DB6A0` | ⬤ | 0 | | 63 | `BindToLocal` | `0x005DE690` | ⬤ | 2 |
| 10 | `SetPDAMapMode` | `0x005DB780` | ⬤ | 3 | | 64 | `BindToRemote` | `0x005DE740` | ▨ | 2 |
| 11 | `SetPDAMapModeCallback` | `0x005DB1E0` | ⬤ | 7 | | 65 | `Unbind` | `0x005DE7D0` | ▨ | 2 |
| 12 | `SetPDAMapModeCancelCallback` | `0x005DB340` | ⬤ | 1 | | 66 | `SetPlayerJoinedCallback` | `0x005DE860` | ⬤ | 2 |
| 13 | `RequestPDAMapModeExit` | `0x005DB470` | ⬤ | 1 | | 67 | `SetPlayerLeftCallback` | `0x005DEA10` | ⬤ | 2 |
| 14 | `RequestPDAMapModeCancel` | `0x005DB5A0` | ▨ | 1 | | 68 | `RemovePlayerJoinedCallback` | `0x005DEBC0` | ▨ | 2 |
| 15 | `GetTargetUnderReticle` | `0x005DD6B0` | ⬤ | 4 | | 69 | `RemovePlayerLeftCallback` | `0x005DEC10` | ▨ | 2 |
| 16 | `SetSatelliteScanMode` | `0x005DB980` | ⬤ | 1 | | 70 | `GetPlayerStart` | `0x005DEC60` | ⬤ | 4 |
| 17 | `SetupSatelliteScan` | `0x005DBA80` | ⬤ | 0 | | 71 | `SetPlayerStart` | `0x005DEC90` | ▨ | 0 |
| 18 | `SetSatelliteScanCallbacks` | `0x005DBBE0` | ⬤ | 0 | | 72 | `ClaimSeat` | `0x005DED20` | ⬤ | 0 |
| 19 | `AddSatelliteScanTarget` | `0x005DBCF0` | ⬤ | 0 | | 73 | `UnClaimSeat` | `0x005DEF80` | ⬤ | 0 |
| 20 | `SetSatelliteScanPaused` | `0x005DBDE0` | ⬤ | 0 | | 74 | `GetRetryPosition` | `0x005DF200` | ▨ | 0 |
| 21 | `SetCinematicMode` | `0x005DBEE0` | ⬤ | 9 | | 75 | `SetWaitForInGame` | `0x005DF150` | ▨ | 3 |
| 22 | `InCinematicMode` | `0x005DC090` | ▨ | 2 | | 76 | `GetAllTargetMarkerPos` | `0x005DF2D0` | ⬤ | 4 |
| 23 | `SetOutBoundary` | `0x005DC160` | ⬤ | 5 | | 77 | `SetSeatMovementLocks` | `0x005DD140` | ⬤ | 7 |
| 24 | `GetOutBoundary` | `0x005DC720` | ▨ | 0 | | 78 | `SetVehicleControlsLock` | `0x005DD2E0` | ⬤ | 0 |
| 25 | `IsInWarningZone` | `0x005DC810` | ▨ | 0 | | 79 | `GetControlBindingType` | `0x005DD430` | ▨ | 2 |
| 26 | `AddBoundary` | `0x005DC900` | ▨ | 2 | | 80 | `ClearGPS` | `0x005DFEE0` | ▨ | 5 |
| 27 | `RemoveBoundary` | `0x005DCA30` | ⬤ | 1 | | 81 | `SetScopeEnabled` | `0x005DFFA0` | ▨ | 6 |
| 28 | `RemoveAllBoundary` | `0x005DCB30` | ▨ | 1 | | 82 | `GetCash` | `0x005DF440` | ▨ | 8 |
| 29 | `GetAllBoundaryGuid` | `0x005DCC20` | ▨ | 0 | | 83 | `SetCash` | `0x005DF480` | ⬤ | 8 |
| 30 | `SetBoundaryCallback` | `0x005DCD60` | ⬤ | 1 | | 84 | `AddCash` | `0x005DF510` | ▨ | 1 |
| 31 | `IsPositionOutBoundary` | `0x005DCE90` | ⬤ | 2 | | 85 | `GetFuel` | `0x005DF590` | ▨ | 7 |
| 32 | `IsBoundaryDeath` | `0x005DD040` | ▨ | 5 | | 86 | `SetFuel` | `0x005DF5D0` | ⬤ | 12 |
| 33 | `SetInputEnabled` | `0x005DC270` | ▨ | 5 | | 87 | `AddFuel` | `0x005DF670` | ▨ | 1 |
| 34 | `SetSurvivalMode` | `0x005DC3B0` | ⬤ | 4 | | 88 | `GetFuelCapacity` | `0x005DF6E0` | ▨ | 7 |
| 35 | `SetHealthClamp` | `0x005DC4F0` | ⬤ | 4 | | 89 | `SetFuelCapacity` | `0x005DF720` | ▨ | 1 |
| 36 | `SetSurvivalModeCallback` | `0x005DC600` | ⬤ | 0 | | 90 | `GetProfileCharacter` | `0x005DF790` | ⬤ | 0 |
| 37 | `IsCoopMultiplayer` | `0x005DD830` | ▨ | 5 | | 91 | `SetProfileCharacter` | `0x005DF7D0` | ⬤ | 0 |
| 38 | `GetPrimaryPlayer` | `0x005DD8A0` | ▨ | 64 | | 92 | `GetProfileUpgrade` | `0x005DF830` | ⬤ | 0 |
| 39 | `GetSecondaryPlayer` | `0x005DD900` | ▨ | 27 | | 93 | `SetProfileUpgrade` | `0x005DF870` | ⬤ | 0 |
| 40 | `GetPrimaryCharacter` | `0x005DD960` | ▨ | 96 | | 94 | `GetProfileCostume` | `0x005DF8E0` | ⬤ | 5 |
| 41 | `GetSecondaryCharacter` | `0x005DD9E0` | ▨ | 143 | | 95 | `SetProfileCostume` | `0x005DF920` | ⬤ | 4 |
| 42 | `GetMaximumPlayers` | `0x005DDA60` | ⬤ | 4 | | 96 | `GetAvailableCostumes` | `0x005DFB00` | ▨ | 2 |
| 43 | `GetCurrentPlayers` | `0x005DDAA0` | ▨ | 18 | | 97 | `SetAvailableCostumes` | `0x005DFB40` | ▨ | 3 |
| 44 | `GetPlayer` | `0x005DDAE0` | ▨ | 13 | | 98 | `SetOutfit` | `0x005DF980` | ⬤ | 8 |
| 45 | `GetAllPlayers` | `0x005DDB90` | ▨ | 83 | | 99 | `SetGrappleEnabled` | `0x005DFBB0` | ⬤ | 1 |
| 46 | `GetPlayerId` | `0x005DDC30` | ▨ | 3 | | 100 | `SetInPmc` | `0x005DFCC0` | ▨ | 6 |
| 47 | `IsJoined` | `0x005DDD40` | ▨ | 0 | | 101 | `SetAimMode` | `0x005DFDD0` | ▨ | 17 |
| 48 | `IsLocal` | `0x005DDDE0` | ▨ | 53 | | 102 | `SetVehicleDisguise` | `0x005E00B0` | ▨ | 6 |
| 49 | `IsRemote` | `0x005DDEE0` | ▨ | 6 | | 103 | `GetVehicleDisguise` | `0x005E0130` | ▨ | 6 |
| 50 | `GetLocalId` | `0x005DE010` | ▨ | 0 | | 104 | `VehicleDisguise` | `0x005E02A0` | ⬤ | 2 |
| 51 | `GetMaximumLocalPlayers` | `0x005DDF90` | ⬤ | 0 | | 105 | `GetVehicleDisguiseState` | `0x005E0470` | ⬤ | 2 |
| 52 | `GetCurrentLocalPlayers` | `0x005DDFD0` | ⬤ | 0 | | 106 | `SetSwimmingSearchRadius` | `0x005E0170` | ⬤ | 0 |
| 53 | `GetLocalPlayer` | `0x005DE0B0` | ▨ | 107 | | | | | | |

**Traffic (the reimpl's build order).** The top ten by script call sites are all
identity/possession, not gameplay: `GetAnyCharacter` 223 · `GetLocalCharacter` 165 ·
`GetSecondaryCharacter` 143 · `GetLocalPlayer` 107 · `GetPrimaryCharacter` 96 · `GetCharacter` 93 ·
`GetAllPlayers` 83 · `GetPrimaryPlayer` 64 · `IsLocal` 53 · `GetSecondaryPlayer` 27. **26 of the 107
have zero call sites.** Every number in the `calls` column was re-derived this pass and all 107 match;
the *corpus* is `docs/mercs2-luacd/` **+ `docs/mercs2-dlc-luacd/`** (445 `.lua`), not luacd alone —
see the corrected recipe in Sources.

### 3.1 Five cfuncs whose body is not what the name suggests

- **`GetAnyCharacter` `0x005DE260`** — pushes the **constant lightuserdata `0xF0000000`**, tag 2:
  `0x005DE27A: C7 00 00 00 00 F0  mov dword [eax], 0xf0000000` / `0x005DE280: C7 40 04 02 00 00 00
  mov dword [eax+4], 2`. It performs *no lookup at all*: it is a **sentinel GUID** meaning "whichever
  character", which downstream `Object.*`/`Human.*` calls resolve. With 223 call sites this is the
  single most-used `Player` binding in the game, and any reimpl that models it as a real query is
  wrong.
- **`GetPlayerStart` `0x005DEC60`** (43 B) — `0x005DEC77 push 0x00D28A90` = the string literal
  **`"PlayerLocation_Start"`**, then `call 0x0085D9F0` and return. The engine does not resolve the
  spawn point; Lua does, via `Pg.GetGuidByName`. This is the `★ HERO SPAWN LOCATION` step in
  [`vanilla_boot_load_order.md`](../modernization/vanilla_boot_load_order.md) — now pinned to a body.
  **But it is the fallback, not the authority** — see §8.
- **`GetMaximumPlayers` `0x005DDA60`** — pushes `DAT_017C0DD0` verbatim, and nothing enforces it
  (§2.3).
- **`GetMaximumLocalPlayers` `0x005DDF90`** — pushes an `.rdata` **constant**:
  `0x005DDFAA: F3 0F 10 05 74 28 B9 00  movss xmm0, [0x00B92874]`, and `[0x00B92874] = 2.0f`.
  No query.
- **`GetCurrentLocalPlayers` `0x005DDFD0`** — likewise `0x005DDFEA movss xmm0, [0x00B9B664]`, and
  `[0x00B9B664] = 1.0f`. **It always returns 1.0, regardless of actual state.** This is the dangerous
  one: a reimpl that implements it honestly (counting local players) diverges from retail on the
  split-screen path. *Added 2026-07-26; both were previously listed only as recovered bodies.*

---

## 4. Persistent state: the profile / economy singleton `[0x01176054]`

**Owned by [`save_serialize_code_map.md`](save_serialize_code_map.md)** (which pins `+0x470` as the
save-serialize source, and the `.profile` disk layout). Offsets recovered *here*, from the six
profile/economy cfunc bodies:

| Off | Field | Read from (VA) | Dirties `+0x11`? |
|---|---|---|---|
| `+0x11` | **dirty flag** (OR-ed byte) — gates `autoSave`, see below | `FUN_00614540` `0x00614891` | — |
| `+0x2C` | cash, signed int32 | `SetCash` `0x005DF4FE`, `AddCash` `0x005DF585` | `SetCash` **NO** / `AddCash` yes |
| `+0x30` | fuel, signed int32 | `SetFuel` `0x005DF651`, `AddFuel` `0x005DF6C7` | yes / yes |
| `+0x25E` | **available costumes (byte)** | `GetAvailableCostumes` `0x005DFB0B movzx edi, byte [eax+0x25e]`, `SetAvailableCostumes` `0x005DFB98 mov byte [ecx+0x25e], al` | **NO** |
| **`+0x30C`** | **fuel capacity** | `GetFuelCapacity` `0x005DF6E0`, `SetFuelCapacity` `0x005DF778 mov [ecx+0x30c], eax` | **NO** |
| `+0x61` | profile character (byte) | `SetProfileCharacter` `0x005DF828` | **NO** |
| `+0x62` | profile upgrade (byte) | `SetProfileUpgrade` `0x005DF8D3` | yes |
| `+0x63` | profile costume (byte) | `SetProfileCostume` `0x005DF978` | **NO** |
| `+0x25F` | a **second** gate on the autosave — must be non-zero for the save to run. Role inferred from position only (conf **L**) | `FUN_00614540` `0x00614897 cmp byte [eax+0x25f], 0 / je` | — |
| `+0x470` | save-serialize source | save map | — |

Four things worth flagging:

1. **The dirty flag gates `autoSave`, and FIVE setters fail to set it. This is a shipped bug, and it
   is proven, not conjectured.** Previous revisions listed three offenders and filed the consequence
   as open (old §9.4: *"if it gates an autosave, this is a shipped bug"*). Both halves are now closed.
   The reader is `FUN_00614540`, the function carrying the string literals `"autoSave"`
   (`0x00BBC4E8`) and `"mustBeSignedInToLive"`:

   ```
   0x0061488C  A1 54 60 17 01     mov eax, [0x01176054]
   0x00614891  80 78 11 00        cmp byte [eax + 0x11], 0     ; dirty?
   0x00614895  74 37              je  0x006148CE               ;   not dirty -> skip the save
   0x00614897  80 B8 5F 02 00 00 00  cmp byte [eax + 0x25f], 0 ; autosave enabled?
   0x006148A0  68 E8 C4 BB 00     push 0x00BBC4E8              ; "autoSave"
   0x006148B7  8B 0D 54 60 17 01  mov ecx, [0x01176054]
   0x006148C2  E8 99 FB 01 00     call 0x00634460              ; ★ THE SAVE
   ```

   The dirtying setters use compare-then-`setne`, so they dirty only on an actual change:
   `SetFuel` `0x005DF64E cmp [eax+0x30],ecx / 0x005DF654 setne dl / 0x005DF657 or [eax+0x11],dl`;
   `SetProfileUpgrade` `0x005DF8C3-D0` the same. **The five that never `or [.. + 0x11]` at all** are
   `SetCash` (`0x005DF4FE` is a bare `mov`), `SetFuelCapacity` (`0x005DF778`), `SetProfileCharacter`
   (`0x005DF828`), `SetProfileCostume` (`0x005DF978`) and `SetAvailableCostumes` (`0x005DFB98`).
   *Reproduce:* disassemble each setter body and grep for `or byte ptr [e?? + 0x11]`. So changing
   cash, fuel capacity, character, costume or the costume roster **alone** leaves the profile
   un-autosaved. Fix-pack candidate; an incomplete enumeration produces an incomplete fix.
2. **`AddCash` / `AddFuel` dirty on the *delta*, not on old-vs-new**, and both clamp at zero.
   `AddCash` `0x005DF567 test ecx,ecx / setne dl / or [eax+0x11],dl` then
   `0x005DF577-85` clamps; `AddFuel` `0x005DF6D3` is the identical shape with the clamp at
   `0x005DF6C7-D3`. So `AddCash(0)` does not dirty, while `AddCash(n)` dirties even when the clamp
   makes it a no-op.
3. **`SetCash` and `SetFuel` take an undocumented optional second boolean that suppresses the write
   entirely.** `SetCash` `0x005DF4EE: 80 7C 24 10 00  cmp byte [esp+0x10], 0` / `75 0C jne 0x005DF501`
   jumps *past* the store; `SetFuel` `0x005DF63E / 75 15 jne 0x005DF65A` skips the store **and** the
   dirty OR. The slot is the out-parameter of a second-argument parse (`FUN_0059F6D0`) pre-initialised
   to 0, so it is a genuine optional Lua boolean. No shipped script passes it — every `SetCash` /
   `SetFuel` call site in both corpora is one-argument — so this cannot break an existing path, only a
   new caller (a fix-pack or cheat path calling `SetCash(n, true)` silently no-ops).
4. **This is a single global, not per-player.** Cash and fuel are shared across the co-op pair —
   consistent with the game's design, and a constraint for the reimpl.

**The Lua wallet cap is not here.** The native ceiling is int32; the 1-billion limit is a Lua
soft-clamp in `mrxpmc.lua` ([[money-fuel-datatype-and-cap]]).

---

## 5. Player ↔ character binding

`Player.AttachToCharacter(idx, charGuid)` (`FUN_005DE4E0`) →
`obj = FUN_006CDAF0(idx)` → **`FUN_006A4060(obj, charGuid)`**:

```c
void FUN_006A4060(playerObj, charGuid) {              // ebx = playerObj
  old = *(int*)(playerObj + 0x20);                    // 0x006A406D
  if (old && charGuid != old) {
      (**(code**)(PTR_PTR_00DF9B10 + 0x64))(old);     // 0x006A4082-8F  drop CheatInfiniteAmmo from OLD body
      … clear two RtDamageFlags words via FUN_005857E0(ecx=0x017C0238); FUN_005E0580(0x017C0238)
      … FUN_00526510(<entity via RuntimePhysicalLink 0x00DF9110: esi=0xDF9160, [0xDF9174]/[0xDF9154]>)
  }
  if (charGuid) {
      FUN_005262D0(godmode||demo, unkillable);        // 0x006A4107-47
      if (DAT_01175F5C || DAT_01175F59)               // 0x006A414F / 0x006A4158 — infammo || demo
          FUN_00649180(0x00DF9B10, charGuid, 0, 0, &flag=1);  // 0x006A4177 re-apply CheatInfiniteAmmo
  }
  *(int*)(playerObj + 0x20)  = charGuid;              // 0x006A422E  ★ THE POSSESSION WRITE
  *(int*)(playerObj + 0x24)  = 0;                     // 0x006A4279  clear the control source
  *(int*)(playerObj + 0x3a8) = *(int*)(playerObj+0x20); // 0x006A4314 seed the disguise sub-struct
  for (p = *(int*)(playerObj + 4); p; p = *(int*)(p + 8)) FUN_006A4370();   // 0x006A4185-9B
  …  // then a pass bounded by *(int*)(playerObj + 0x1BC)
}
```

> **⚠ RETRACTED (2026-07-26): "possession is a component".** A previous revision of this section
> concluded that attaching a player to a character *adds a control-marker component* via container
> `0x00DF9B10`, and detaching removes it — and that claim was repeated in §0, §0.5, §8 and §10.
> **It is wrong.** Container `0x00DF9B10` names itself **`CheatInfiniteAmmo`** — reproduce:
> `[0x00DF9B10] = 0x00BC3F48`, `[0x00BC3F48 + 0x34] = 0x00647B90`, and `FUN_00647B90` is
> `B8 <ptr> C3` → that string. Its element is **one byte** (`[0x00DF9B10 + 0x24] = 1`), capacity
> `0x100`, shift 7 — there is no sub-struct and the two `0` arguments to `FUN_00649180` do not select
> a field. The attach path touches it only to **re-apply an active cheat to the new body**; with
> cheats off the branch never runs, so it cannot be what marks possession.
>
> What survives: **`player+0x20` is the possession link**, written directly at `0x006A422E`. How the
> *engine* tells a character it is player-driven — if it does so at all beyond that field — is
> **STILL-OPEN (§9)**. Found by the blind validation pass
> (`validation/human_character_controller_validation.md`), which also established the `vtable+0x34`
> naming mechanism; re-verified here by reading the vtable chain, the element size and the cheat gate.

**The cheat gate, named by hash — and one of the five flags is not a cheat.** `FUN_004C2C20` is a
config lookup by name hash (`push <hash32>; call 0x00826820`) and it publishes the five bytes the
attach path reads. Each hash was matched against a *real* candidate name with
`tools/pandemic_hash.py`; none was invented:

| global | hash pushed at | hash | `pandemic_hash_m2` of | corroboration |
|---|---|---|---|---|
| `DAT_01175F59` | `0x004C2D27` → store `0x004C2D43` | `0x949A9B14` | **`"demo"`** | also read by `Sys.IsDemoMode` `0x005E5679` |
| `DAT_01175F5A` | `0x004C2C51` → `0x004C2C6D` | `0x40B39AC0` | **`"godmode"`** | Xbox `debug-cheat-menu.md` "God Mode" |
| `DAT_01175F5B` | `0x004C2C74` → `0x004C2C90` | `0x4299D698` | **`"unkillable"`** | Xbox "Demigod Mode" |
| `DAT_01175F5C` | `0x004C2C98` → `0x004C2CB4` | `0xF2E44D84` | **`"infammo"`** | gates `Object.SetInfiniteAmmo` `0x005CE86D` |
| `DAT_01175F5D` | `0x004C2CBC` → `0x004C2CD8` | `0xE79B0021` | **`"showgodmode"`** | Xbox "Show God Mode Et Al" |

So the attach gate reads **`infammo || demo`**, and the sibling `FUN_005262D0` call is gated on
`godmode || demo` plus `unkillable`. *Corrected 2026-07-26:* the previous gloss "cheat toggles, not
mode bytes" is right for `0x1175F5C` and **wrong for `0x1175F59`**, which is the **demo-mode** flag.
Two more globals in the same body are named the same way: `0x017C0238` = **`RtDamageFlags`** (the
"two world flag words" this map used to leave anonymous) and `esi = 0x00DF9160` resolves on base
`0x00DF9110` = **`RuntimePhysicalLink`** (`[0xDF9174]` / `[0xDF9154]` are its `+0x64` / `+0x44`, the
same `base+0x50` probe idiom as §2.2).

`BindToLocal` (`FUN_005DE690`) resolves the player the same way and calls `thunk_FUN_024EBC20`.

The **character side** — locomotion, the `hkpCharacterProxy` + `hkpCharacterContext` 5-state
machine, `HumanPhysics::Activate` `FUN_004255C0` with its 7 capsules + phantom + proxy, ragdoll —
is **already fully mapped in [`physics_code_map.md`](physics_code_map.md)** and is not repeated here.
The planned `human_character_controller_code_map.md` (audit row 6) should own the `Human` namespace
(21 cfuncs @ `0xB99EF0`) and join to `player+0x20` as its entry point.

---

## 6. Player-related ECS components

Registrars follow the standard `CopyFromStream` descriptor shape (identical to the camera map's
`FUN_006401B0`): zero the container, install the `CopyFromStream` vtable, set capacity `0x100`,
element size at `+0x24`, page shift `8` at `+0x26`, hash seed `0x9E3779B9` at `+0x2C`, publish the
type-name pointer, then `call 0x0064A770`. Each container name below is read via the `vtable+0x34`
master key, not inferred from the registrar.

| Component | Registrar | Container | Elem | Note |
|---|---|---|---|---|
| `ControllerPlayer` | `FUN_00640410` | `0x017BCEF8` | `0x0C` | the input→control binding block |
| `VehicleDisguiseScale` | `FUN_006413F0` | `0x017BD5D8` | `0x0C` | disguise falloff tuning |
| `GrappleParameters` | `FUN_00643D50` | `0x017BE848` | `0x1C` | grapple/winch tunables (cf. `player…+0x158`) |
| `ModelMixerProfile` | `FUN_00643A40` | **`0x017BE708`** | **`4`** | costume/upgrade persistence (already bound in save map). *Container + element were "—" until 2026-07-26; `[[0x017BE708]+0x34] = FUN_00643AE0` names it, and the registrar writes `0x017BE708`'s vtable at `0x00643A93`* |

Six more containers are named the same way and are the ones `GetControlBindingType` `0x005DD430`
probes, in order, to turn `player+0x24` into a string: `0x017BCF98` `ControllerCar` → `"car"`,
`0x017BD038` `ControllerTank` → `"tank"`, `0x017BD0D8` `ControllerHelicopter` → `"helicopter"`,
`0x017BD088` `ControllerLW` → `"livingworld"`, `0x017BCFE8` `ControllerBoat` → `"boat"`,
`0x017BD128` `ControllerLadder` → `"ladder"`.

> **⚠ ECS containers are RE-PARAMETERISED at runtime — do not hardcode a registrar constant.**
> `FUN_00640410` registers `ControllerPlayer` with capacity `0x100` (`0x00640421 mov ecx, 0x100` /
> `0x00640453 mov [0x017BCF04], ecx`), yet the same word in the dumped image reads **`0x60`**, with
> shift 5 instead of 8. The re-parameteriser takes the container in a register, so an absolute-address
> scan cannot find it — which is also why there are zero static writes to the `Players` header words.
> Registrar constants are *initial* values; the dump shows *observed* values; neither is a contract.

**`s_PCPlayer_00BE2BEC` is a false friend** — `FUN_008445D0` writes it into an online-session
identity struct alongside `"mercs2_pc ver %d"`. It is the **network client name**, not a gameplay
player component. Recorded so the next reader doesn't chase it.

**Costume swap is a streaming operation.** `SetOutfit` (`FUN_005DF980`) does
`FUN_00649180(&PTR_PTR_00DF6C08, charGuid, 0, 0, outfitName)` — adds/sets an outfit component — then,
if the world is live (`FUN_005857E0`), drives **three streaming calls `FUN_00874300` / `FUN_00874320`
/ `FUN_00874290`** and finally `FUN_004F8DA0(0,0,1)`. That is the engine-side confirmation of the
wardrobe residency problem recorded in [[dlc-skin-swap-via-pmc-wardrobe]]: a costume that is not
already resident goes through this on-demand path.

---

## 7. The player sub-systems, by cfunc cluster

> **⚠ Corrected (2026-07-26): "binding-only" no longer appears in this section.** A previous revision
> still called `IsBoundaryDeath` and `SetInputEnabled` "binding-only" while the header and §3 assert
> **107/107 bodies read** and mark both `▨`. That was stale wording from before the recovery pass, and
> a reader could reasonably have concluded the map contradicted itself. Both bodies are read and their
> offsets are in §2.2.

- **Boundary (10 cfuncs, `0x005DC160`–`0x005DD040`).** The play-area fence. `SetBoundaryCallback`
  stores `{fn, ctx}` at `player+0x380/+0x384`. `SetOutBoundary`/`IsPositionOutBoundary`/
  `RemoveBoundary` all delegate into the `thunk_FUN_024E****` SecuROM-adjacent boundary module
  (`024E3AB0` set, `024E3A20` point-test, `024E8030` remove) — the *storage* is behind that seam,
  the *player-facing state* is the callback pair. The out-of-boundary and warning-zone bits live on
  the sub-object at `player+0x08` (`+0x4F5` / `+0x4F7`), **not** on the player (§2.2).
  `IsBoundaryDeath` resolves its argument as a **character** through `FUN_006CDB70` (§2.2).

  **`DAT_00DFBD77` = `Net.IsClient`, `DAT_00DFBD78` = `Net.IsServer` — NAMED (2026-07-26).** The
  engine names them itself, and the evidence cannot coincide: the `Net` namespace (`luaL_Reg`
  `0x00B998D0`, 92 rows) exposes **five consecutive accessors over five consecutive bytes**, each a
  byte-identical five-instruction template:

  | byte | `Net` cfunc | VA | opening instruction |
  |---|---|---|---|
  | `0xDFBD74` | `Net.IsEnabled` | `0x005C6710` | `0x005C6711: 8A 1D 74 BD DF 00  mov bl, byte [0xdfbd74]` |
  | `0xDFBD75` | `Net.IsActive` | `0x005C6750` | `0x005C6751: 8A 1D 75 BD DF 00` |
  | `0xDFBD76` | `Net.IsLobby` | `0x005C6790` | `0x005C6791: 8A 1D 76 BD DF 00` |
  | **`0xDFBD77`** | **`Net.IsClient`** | `0x005C67D0` | `0x005C67D1: 8A 1D 77 BD DF 00` |
  | **`0xDFBD78`** | **`Net.IsServer`** | `0x005C6810` | `0x005C6811: 8A 1D 78 BD DF 00` |

  The publisher `FUN_006CECF0` writes the whole block once per frame from **one net-session role
  enum**, `[[edi+0x24] + 0x0C]`:

  ```
  0x006CEDC1  8B 57 24     mov edx, [edi + 0x24]      ; the net-session object
  0x006CEDC4  8B 42 0C     mov eax, [edx + 0xc]       ; role enum
  0x006CEDC7  83 F8 04     cmp eax, 4 ; sete cl  -> [esp+0x16] -> 0xDFBD76  IsLobby
  0x006CEDCD  83 F8 01     cmp eax, 1 ; sete dl  -> [esp+0x17] -> 0xDFBD77  IsClient
  0x006CEDDA  83 F8 02     cmp eax, 2 ; sete al  -> [esp+0x18] -> 0xDFBD78  IsServer
  0x006CEEBA  66 0F D6 05 74 BD DF 00   movq [0xdfbd74], xmm0   (+ 0x006CEEC8, 0x006CEED6)
  ```

  `FUN_006CFF40` reads the same `[edx+0x0C]` and branches 1 → the client object `[eax+0x28]`,
  2/3 → the server object `[eax+0x24]`, which is what pins the enum as a **session role** rather than
  a player state.

  So the boundary cfuncs early-out **on the client** — the operation is server-authoritative. Read
  `RemoveBoundary`: `0x005DCA33 cmp byte [0xdfbd77], 0` / `0x005DCA48 je 0x005DCA78`; the `je` (i.e.
  *not* a client) jumps to the real work at `0x005DCA78`, while falling through on a client reaches
  `0x005DCA5A mov [eax],0 / mov [eax+4],1` — push boolean **false** and return. Same shape in
  `AddBoundary` `0x005DC903` and `RemoveAllBoundary` `0x005DCB31`.

  **Three earlier glosses in this map are withdrawn**: "a shutdown/teardown guard" (a guess), its
  replacement "an engine-wide authority/replication gate, name open" (right in shape, needlessly
  vague), and — new this pass — the claim that *"the companion `(guid & 0xF0000000) == 0x40000000`
  test is a networked-object GUID tag"* **as if it appeared at these sites. It does not.** All three
  boundary sites are a bare `cmp byte [0xdfbd77], 0` with no guid mask. The conjunction is real
  elsewhere — e.g. `0x0046928B cmp byte [0xdfbd77],bl` / `0x00469295 and eax,0xf0000000` /
  `0x0046929A cmp eax,0x40000000` — at **10 of the 135** read sites, but it is not part of the
  boundary story and should not be cited as if it were.

  *Reference counts, instruction-accurate* (linear-disassemble all 43 027 known entry points; a naïve
  4-byte LE scan for `77 bd df 00` invents phantom hits, because `3D 77 BD DF 00` is itself a legal
  `cmp eax, 0xdfbd77`): `0xDFBD74` **113**, `75` **55**, `76` **1**, `77` **135**, `78` **164**.
  **Zero individual writes** to any of them — the only store touching the range is the publisher's
  three `movq`. *Corrected: previous revisions said 97 / 122, which were Ghidra xrefs and undercount
  for the same reason Ghidra missed 57 of the 107 bodies.*
  `human_character_controller_code_map.md`'s local-apply/replicate reading was correct.
- **PDA map mode (5) + satellite scan (5), `0x005DB1E0`–`0x005DBDE0`.** Callback-driven modal UI.
  Marries to the Xbox `gui-hud.md` PDA inventory (`SetPDAMapMode`, `RequestPDAMapModeExit`, …) —
  the widget half belongs to the planned `hud_widget_code_map.md` (audit row 2).
- **Reticle.** `GetTargetUnderReticle` `FUN_005DD6B0` reads `player+0x11C` (GUID), `+0x124`
  (payload) and `+0x12C`; Xbox counterpart `PlayerReticleUpdate` / `GetReticlePosition`
  (`gui-hud.md`).
- **Input / survival / health / scope.** `SetInputEnabled` writes `player+0x244`/`+0x245`
  (`0x005DC364`/`0x005DC36A`); `SetSurvivalMode` (`FUN_005DC3B0` → `FUN_006A2340`, `+0x180`/`+0x198`)
  and `SetHealthClamp` (`+0x199`) reach the player object through `FUN_00423DC0` rather than the
  inlined walk (§2.2); `SetScopeEnabled` → `FUN_006A21E0` sets `[player+0x1B8]->[+0x10] = 1` and keeps
  a **refcount** at `player+0x19C` (+1 enable / −1 disable). *None of these four is "binding-only" —
  see the note at the head of this section.*
- **Seats & control locks.** `SetSeatMovementLocks` writes three bytes `+0x45D/E/F`, each defaulting
  to **1** when the Lua arg is absent; `SetVehicleControlsLock` writes `+0x460`. `ClaimSeat`
  (`FUN_005DED20`) works a different container (`PTR_PTR_00DF8188` — the **seat pool**); ride
  mechanics belong to [`vehicle_code_map.md`](vehicle_code_map.md). `0x00DF8188` names itself
  **`SeatLink`** (§2.2). The critical section `DAT_00EDBAA4` + free-list `PTR_DAT_00EDBAC0` it takes
  are **not** seat-specific — an earlier draft of this map called them "the seat-reservation pool",
  which is wrong: `DAT_00EDBAA4` has **1021 references binary-wide** (instruction-accurate; the "901"
  a previous revision quoted was a Ghidra xref count), and `Human.Scrub` `FUN_005BE730` takes the same
  pair. It is the general scratch-block allocator lock. Correction owed to
  `human_character_controller_code_map.md`.
- **Disguise — this is TWO mechanisms wearing four similar names.** `VehicleDisguise`
  (`FUN_005E02A0`) and `GetVehicleDisguiseState` (`FUN_005E0470`) resolve a **character** through
  `FUN_006CDB70` (§2.2) and work per-player state: `VehicleDisguise` writes `+0x430/+0x434/+0x438`;
  `GetVehicleDisguiseState` sums two sub-queries off `player+0x3A8` (`0x005E052B lea edi,[eax+0x3a8]`
  → `FUN_006ABC30`/`FUN_006ABC50` → `FUN_004B86E0`/`FUN_004B29C0`) into an integer state.
  **`SetVehicleDisguise` / `GetVehicleDisguise` are neither** — they do no lookup at all and read/write
  a single **global byte `[0x01176106]`** (`0x005E0100 mov byte [0x1176106], dl`; `0x005E0131 mov bl,
  byte [0x1176106]`). That byte is also read by `Object.IsDisguised` (`FUN_005CEF20`), and the Lua
  guards on it (`if not Player.GetVehicleDisguise() then return end`,
  `wiftutorialvehicledisguise.lua:26`): it is a **global feature gate for the whole disguise system**,
  not a per-player setting. *Added 2026-07-26; a previous revision discussed only the first two and
  left all four reading as one mechanism.* Ties to the AI detectability model ("Breaking Disguise" /
  "Show Player Awareness", `ai.md`).
- **Join/leave callbacks.** `SetPlayerJoinedCallback` (`FUN_005DE860`) installs the same handle into
  **three** singletons — `PTR_PTR_01176174+0x24`, `PTR_PTR_01175DB0+0x14`, `PTR_PTR_01176158+0x2C` —
  i.e. three subsystems each keep their own copy. Fires the `MrxPlayer.OnPlayerJoined` chain.

---

## 8. The Lua layer above it (cited, not re-derived)

[`vanilla_boot_load_order.md`](../modernization/vanilla_boot_load_order.md) already pins the boot
chain; the engine anchors this map adds are marked ★. Source, re-read line by line this pass:
`docs/mercs2-luacd/src/resident/mrxplayer.lua`.

```
MrxPlayer.Init()                                    :114
    for i = 0, Player.GetMaximumPlayers()-1 do
        Player.CreatePlayer(i)                      :117   ← ★ FUN_005DE2E0  (a DIFFERENT phase)
MrxPlayer.Start()                                   :130
    Player.SetPlayerJoinedCallback(OnPlayerJoined)  :132   ← ★ FUN_005DE860
    Player.SetPlayerLeftCallback(OnPlayerLeft)      :133   ← ★ FUN_005DEA10
MrxPlayer.OnPlayerJoined(iPlayerId, sPlayerName, tCharacterConfig, bLocalPlayer, iLocalId)   :176
    vSpawnLocation = Player.GetPlayerStart()        :184   ← ★ FUN_005DEC60 = literal "PlayerLocation_Start"
    if _tSpawnLocations then
        vSpawnLocation = _tSpawnLocations[iPlayerId+1]     :185-187  ★ OVERRIDES the engine default
    CreatePlayerCharacter(bLocal, id, sTemplateName, vSpawnLocation)   :188
        Pg.GetGuidByName(vLocation) → Object.GetPosition/GetYaw        :572-578  (string form)
        uCharacterGuid = Pg.Spawn(sCharacterName, x,y,z,yaw, …)        :586  ★ THE ENTITY CREATOR
        Player.AttachToCharacter(iPlayerId, uCharacterGuid)            :587  ← ★ FUN_006A4060 (writes player+0x20)
    Player.BindToLocal(id, iLocalId) / Player.BindToRemote(id)         :195+
MrxUtil._TeleportHero → Object.SetPosition(uHero, …)   mrxutil.lua:308,328
    (reached via Event.Create from _TeleportHeroes — adjacency, not a call edge from OnPlayerJoined)
```

> **⚠ Corrected (2026-07-26) — three errors in the previous diagram.**
> 1. It put **`Player.CreatePlayer` inside `CreatePlayerCharacter`**. It is not there; it is in
>    `MrxPlayer.Init()` (`:114-118`), a *different lifecycle phase* that runs before `Start()`.
>    `CreatePlayerCharacter` (`:562-590`) calls `Player.AttachToCharacter` at `:587`.
> 2. It **omitted `Pg.Spawn`** (`:586`), which is the call that actually creates the entity. The
>    diagram made `AttachToCharacter` look like the creation step.
> 3. It presented **`GetPlayerStart` as the authority**. `:185-187` immediately overrides it with
>    `_tSpawnLocations[iPlayerId+1]` when that table is set, so the engine literal is a *fallback*.
>    §10.5's reimpl guidance inherits this.
>
> Also fixed: the annotation `FUN_006A4060 (player+0x20, **marker component**)` carried wording that
> §5's own retraction box had already withdrawn.

`docs/mercs2-luacd/07_player_core_cheats_managers.md` lists the script-side cheat entry points
(`Player.SetCash`, `Player.AddFuel`, `Object.SetInfiniteAmmo`, `Human.Inventory.SetAllWeapons`) —
all of which now have VAs in §3. The 1e9 wallet clamp is scoped to `MrxPmc.AddCashQty`
(`mrxpmc.lua:45-60`) and is **bypassed** by `mrxpmc.lua:474 Player.AddCash(...)` and `:538
Player.SetCash(tSaveData.nCash)` — so it is not a system-wide ceiling.

---

## 9. Open questions / confirm-live inventory

Read-only while **PAUSED**; the USER drives execution ([[x32dbg-mcp-no-resume]]), and a conditional
breakpoint on a per-frame function will kill the session ([[x32dbg-mcp-pitfalls]]) — so prefer
**one-shot** breakpoints and HW-write watchpoints on the offsets below.

**Three items remain open.** Items 1, 3, 4, 5, 6 and 8 of the previous inventory are **closed**, and
they were closed *statically*, not at a breakpoint — recorded below with what closed them, because
"we already tried a debugger session for this" is exactly the kind of thing that gets re-attempted.

### 9.1 STILL-OPEN (3)

**S1 — the write that populates `player+0x24`.** `FUN_006A4060` only ever *clears* it
(`0x006A4279`); the write that sets it to a ridden vehicle is not reachable statically.
*Ruled out — do not redo:* every function that (a) calls `FUN_00423DC0` / `FUN_006496B0` /
`FUN_006CDAF0` / `FUN_006CD960` / `FUN_006CDB70` or (b) references any `Players` or `SeatLink`
container global was disassembled looking for `mov dword [reg+0x24], …` on a non-`esp` base. Every
hit is a local argument struct (the `0x005EDE00` / `0x005EFF60` Lua table parsers store
`[playerObj+0x20]` into their *own* `[ebx+0x24]`), a generic list-insert (`FUN_005366B8`), or an
unrelated ctor (`FUN_00683D70`, vtable `0xDF9C90`). The three per-player passes `FUN_006A1880` /
`FUN_006A0770` / `FUN_0041FE20` contain no `+0x24` store either.
*What is now known:* `+0x24` is a **`SeatLink` guid** whose entity carries a `Controller*` component
(§2.2), so the writer is in the seat/ride subsystem and stores a **key**, not a pointer.
*Runtime recipe:* HW **write** watchpoint on `<playerObj>+0x24`, where
`playerObj = *FUN_00423DC0(0x00DF9B90, Player.GetLocalPlayer())`. Get `playerObj` once from a one-shot
breakpoint at **`0x005DA9F7`** (`GetSeat`'s `mov eax,[eax+0x24]` — cold, safe), then walk into a
vehicle.

**S2 — the write that sets `player+0x58`.** *Semantic is CLOSED* (§2.2): `IsJoined` = `+0x30 != -1`;
`IsLocal` = that **and** `+0x58 == 0`; `IsRemote` = that **and** `+0x58 != 0`. So it is the remote
flag at confidence **H**, and the old §2.2 gloss "byte gate on the viewport-id resolve (conf M)" is
withdrawn.
*Ruled out:* the only cfuncs that could set it are `BindToLocal` / `BindToRemote` / `Unbind`, which
delegate to `FUN_006A0400` / `FUN_006A04B0` / `FUN_006A0520` — **all three are SecuROM split thunks
whose slots deref to VM stubs**: `[0x0245F5A0] = 0x024EBC20 → push 0x24ebc2a; call 0x1aaff10`;
`[0x02458FB4] = 0x024F0270`; `[0x0245A1D4] = 0x024E3B40`. No `mov [reg+0x58]` anywhere in a
`Players`-touching `.text` function corresponds to a player object.
*Runtime recipe:* HW write watchpoint on `<playerObj>+0x58` (same address recipe as S1), then join a
second player. Or one-shot bp at `0x005DE7A4` (`BindToRemote`'s `call 0x6a04b0`) and diff `+0x58`
across it.

**S3 — three unnamed hash constants.** `0x892CF579` — the `FUN_0041FE20` feature gate,
`0x00420013 push 0x892cf579` / `0x00420023 call 0x006886A0`; `0x223F6FDA` — its Havok filter constant,
`0x00420095` and `0x00420131`; and `0x57B5E35A` — a game-state id, compared at `0x004C0B4D
cmp dword [eax+4], 0x57b5e35a` and stored at `0x005BA65E`.
*Exhausted:* every `[A-Za-z][A-Za-z0-9_.]{2,40}` token from `mercs2_unpacked.exe` and from
`output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt` was hashed under both `pandemic_hash` and
`pandemic_hash_m2` — no match. The same sweep **did** resolve `0xFA62754E → "PDA"` and
`0xDB41017D → "Exit"` (the latter visible at `0x004C0A6B mov edi, 0xdb41017d`), so the method works;
these three names are simply not strings in either image. **No hash was invented**
([[no-arbitrary-hashes]]).
*Next step:* harvest candidate names from `vz.wad` string tables via `mercs2_probe`, not from the exe.

### 9.2 CLOSED — with what closed them (do not re-open without new evidence)

| was | verdict | closed by |
|---|---|---|
| The 57 binding-only bodies | **CLOSED** | all 107 disassembled; 0 binding-only rows remain |
| `SetWaitForInGame` / `GetControlBindingType` / `ClearGPS` / `SetScopeEnabled` "worth a live check" | **CLOSED, no breakpoint needed** | `SetWaitForInGame` = set-only latch `[player+0x461] = 1` from a **character** handle; `GetControlBindingType` = the six-`Controller*` probe returning a string (§6); `ClearGPS` → `FUN_006A0FB0` reads `+0x390` and clears `+0x398`; `SetScopeEnabled` → `FUN_006A21E0` sets `[+0x1B8]->[+0x10]` and refcounts `+0x19C` |
| `FUN_0041FE20`'s identity — "player system tick"? | **CLOSED: NO** | it never touches `0x00DF9BA8`; `FUN_0062E810` / `FUN_0062E7B0` do (§1) |
| The profile dirty flag `+0x11` — does it gate anything? | **CLOSED: YES, `autoSave`** | `FUN_00614540` `0x00614891 cmp byte [eax+0x11],0 / je 0x6148ce` guards the save at `0x006148C2`. It is the **only** absolute-addressed reader: sweep every reference to `0x01176054` and exactly one is followed by a `[+0x11]` test. (A second `cmp byte [ebx+0x11],0` at `0x00635D95` in `FUN_00635CF0` sits on a save path and its `ebx` carries the same `+0xA86x` field signature as the profile singleton — corroborating, but the base arrives as an argument and is not proven here.) The missing ORs are now a **proven** shipped bug, and there are **five**, not three (§4) |
| Container `0x00DF9B10`'s element layout / clobber risk | **CLOSED — the question's premise was wrong** | it is `CheatInfiniteAmmo` with a **1-byte** element (`[0x00DF9B10+0x24] = 1`); the two writers are the *same feature* (`Object.SetInfiniteAmmo` sets the cheat, `FUN_006A4060` re-applies it to a new body). No sub-struct, no field selector, no clobber. *(The previous revision's sentence here was also truncated mid-list — for the record the static users of `0x00DF9B10` are `FUN_004C4920, FUN_0051A260, FUN_0051A740, FUN_0051DD07, FUN_0051E1A7, FUN_0051F520, FUN_0051F5C0, FUN_0052D7F0, FUN_00585840, FUN_0066B710, FUN_006A4060, FUN_00A7C7A0, FUN_00B00C70` plus `FUN_005CE7E0`.)* |
| The 2-player cap | **CLOSED** | three compile-time immediates (§2.3); `DAT_017C0DD0` is only *reported*; the container's capacity word `0x00DF9B9C` has **zero** references. Raising the reported maximum does nothing |
| Player object total size | **CLOSED: ≥ `0x465`** | `0x005DFEA5 mov byte [eax+0x464], cl` off the resolved object |
| `DAT_00DFBD77`'s name | **CLOSED: `Net.IsClient`** | five consecutive `Net` accessors over five consecutive bytes (§7) |
| `FUN_006CDB70`'s identity | **CLOSED to M: `GetPlayerForCharacter`** | behavioural — 1 register arg, returns a `Players` record, Lua splits 6/6 on handle type (§2.2). Raising M→H needs the SecuROM recovery pipeline or a live `EAX` compare at `0x005E0527` |
| `player+0x450`'s constant | **CLOSED: `pandemic_hash_m2("PDA")`** | `0x005BA646 cmp dword [ecx+0x450], 0xfa62754e` |
| `player+0x58`'s *meaning* | **CLOSED: remote flag** | see S2 — only the *writer* is still open |

---

## 10. Reconciliation with `mercs2_player` (silo 17 — currently an empty scaffold)

`docs/modernization/wave0_seam_review.md:40` Seam G assigns the `Player` namespace (107, 2nd-highest
traffic) to its own crate, **decided but unbuilt** — `crates/mercs2_player/src/lib.rs` really is an
empty 34-line scaffold. This map is the reference for filling it.

> **⚠ Corrected (2026-07-26).** A previous revision added *"…`bindings/player.rs` holds the 107
> `Required` names with `install` unfilled"*. **`install` is not unfilled.** The file has **70 direct
> `b.real(...)` calls** plus two loop-installed groups (mode gates and scalar setters) and a
> `super::record_all(...)` tail, and **zero `b.stub(...)` calls** — the only occurrence of `b.stub` in
> the file is in a doc comment at line 9. The map was quoting the file's stale header comment rather
> than its code. *Reproduce:* `grep -c 'b\.real(' crates/mercs2_script/src/bindings/player.rs` = 70;
> `grep -n 'b\.stub(' …` = line 9 only. What is genuinely empty is the **`mercs2_player` crate**, not
> the binding surface.

What the retail engine says the crate must model:

1. **Two objects, not one.** A **runtime player** (slot, viewport, camera handle, character GUID,
   locks, reticle, boundary callback) and a **persistent profile** (cash, fuel, character, upgrade,
   costume). The reimpl must not merge them — the profile is one global shared by both co-op
   players, the player object is per-slot.
2. **The roster is a container scan capped at 2**, keyed on `player+0x2C`, with `+0x30 == -1`
   meaning "not local". `GetCurrentPlayers` ≠ `GetMaximumPlayers` ≠ roster capacity — all three are
   independent in retail (§2.3). Model the cap as a constant, not as the reported maximum.
3. **Possession is a FIELD, `player+0x20`, not a component add/remove.** *This item previously read
   "Possession is a component add/remove on the character entity, not a pointer" — that is **wrong**
   and §5's retraction box explains why (the container in question is `CheatInfiniteAmmo`).* The
   attach write is `0x006A422E mov [ebx+0x20], eax`. Whether the engine also *marks* the character as
   player-driven is STILL-OPEN (§9.1). For the ECS-world-as-source-of-truth invariant
   ([[ecs-world-source-of-truth-deshadow]]) model it as a link field on the player, and do not invent
   a possession component.
4. **Implement the identity cluster first.** Ten bindings carry **1054 of the 1405** call sites (75 %);
   the remaining 97 are long-tail, and 26 are never called at all. And `GetAnyCharacter` must return the **constant sentinel
   `0xF0000000`** (§3.1), not a lookup — getting this wrong silently breaks 223 call sites.
5. **`GetPlayerStart` returns a name string**, not a transform — the reimpl's hardcoded spawn
   (`engine_support_inventory.md` §6.4 "Save → player spawn transform") should resolve
   `"PlayerLocation_Start"` through the name registry, exactly as the boot chain does. **But it is a
   fallback**: `mrxplayer.lua:185-187` overrides it with `_tSpawnLocations[iPlayerId+1]` whenever that
   table is set, so the reimpl must model the override, not just the literal (§8).
6. **`SetOutfit` is a streaming request** (§6), which is why an on-demand costume wedges
   `STATE_WAITFORGAME` ([[dlc-skin-swap-via-pmc-wardrobe]]). The binding is not a field write.
7. **Lua numbers are 32-bit floats** (tag 3); GUIDs are lightuserdata (tag 2). Cash beyond 2^24 is
   not integer-exact — a constraint inherited from the host, not a bug to fix.
8. **A failed handle lookup returns `nil`; it does not raise.** `FUN_004B2A50` is `push nil; return 1`
   (§3). Retail scripts rely on `if Player.X(u) then`, so a reimpl that errors on a bad handle breaks
   working Lua.
9. **Four bindings take a CHARACTER handle** — `IsBoundaryDeath`, `SetWaitForInGame`,
   `VehicleDisguise`, `GetVehicleDisguiseState` (§2.2). The `Player = …` key in the latter two's
   argument table is a character guid. Typing them as player handles fails silently.
10. **`GetCurrentLocalPlayers` must return the constant `1.0`** and `GetMaximumLocalPlayers` the
    constant `2.0` (§3.1). Implementing them honestly diverges from retail.
11. **Do not hardcode a container's capacity/stride/shift from its registrar** — retail
    re-parameterises containers at runtime (§6).

---

## 11. Provenance

- **PC image:** `output/_ghidra/securom_dump/mercs2_unpacked.exe` (unpacked SecuROM image, base
  `0x00400000`, **live dump** — see the caveat in Sources) and its Ghidra export
  `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (42 601 functions). Bodies read first-hand:
  all 107 `Player` cfuncs, the two roster ticks `FUN_0062E810`/`FUN_0062E7B0` and their callees
  `FUN_006A0770`/`FUN_006A1880`, the world probe `FUN_0041FE20`, the frame chain
  `FUN_004C1170`/`FUN_004C15E0`/`FUN_004C09C0`/`FUN_004C13A0`, container resolve `FUN_00423DC0` +
  slot lookup `FUN_006496B0` + the generic `base+0x50` probe `FUN_0042BF80`, roster
  `FUN_006CDAF0`/`FUN_006CDAC0`/`FUN_006CD960`, attach `FUN_006A4060`, the cheat-config publisher
  `FUN_004C2C20`, the `Net` block publisher `FUN_006CECF0`, the autosave gate `FUN_00614540`,
  the sub-handlers `FUN_006A0FB0`/`FUN_006A21E0`, component registrars
  `FUN_00640410`/`FUN_006413F0`/`FUN_00643D50`/`FUN_00643A40`, container ctors
  `FUN_00A7C7A0`/`FUN_00A7C7D0`, and the online-identity false friend `FUN_008445D0`.
- **Reproduction harness.** Everything above is a PE read plus capstone; no Ghidra required:

  | question | check |
  |---|---|
  | is the table really `Player`, really 107? | walk `0x00DFD478` (31×12 B) → row 4; walk `0x00B98FC0` to NULL |
  | what is container `X`? | `[[X] + 0x34]` must be `B8 <imm32> C3`; the imm32 is the name string |
  | is the pump layer 4? | `disraw(0x004C1170, 0x140)`; `u32(0x00BB046C) == 0x004C09C0` |
  | what gates the tick? | `disraw(0x004C0B03, 0x70)` — `mov esi,1` then two `cmp [0x1175a94], esi` |
  | which cfunc is the roster tick? | `disraw(0x004C9855, 0x20)` and `disraw(0x0062E7B0, 0x60)` |
  | how many inliners? | count `mov ecx/esi, 0xdf9b90` per body, bounded by the **next table entry** |
  | object minimum size? | `disraw(0x005DFEA1, 0x10)` — `mov byte [eax+0x464], cl` |
  | is `+0x158` on the object? | `disraw(0x005DFC5D, 0x30)` — `call 0x423dc0`, `mov eax,[eax]`, store |
  | does `+0x11` gate anything? | `disraw(0x0061488C, 0x40)` — `"autoSave"` at `0x00BBC4E8` |
  | which setters skip the dirty flag? | grep each setter body for `or byte ptr [e?? + 0x11]` |
  | what is `DAT_00DFBD77`? | walk `Net`'s table at `0x00B998D0`; `disfn(0x005C67D0)` |
  | what does `FUN_006CDB70` take? | grep the Lua for its four callers — all pass characters |
  | whose container is `0x00DF81D8`? | `disfn(0x0042BF80)` — `lea esi,[edi+0x50]`; `0xDF81D8 − 0x50` |
  | any hash constant | `tools/pandemic_hash.py` → `pandemic_hash_m2(<real name>)`; never invent one |

- **Binding table:** re-derived from the namespace registry this pass (see Sources), and corroborated
  by `mods/lua_trace_asi/reference/binding_map.json` (live `.rdata` walk,
  [[lua-trace-asi-surface-b-oracle]]) and
  [`../lua_engine_bindings_audit_deep_dive.md`](../lua_engine_bindings_audit_deep_dive.md)'s offline
  re-walk (same VA, same count, 0 stubs).
- **Script traffic:** call-site census over `docs/mercs2-luacd/` **+ `docs/mercs2-dlc-luacd/`**
  (445 `.lua`), carried in `mercs2_script/src/bindings/player.rs`. *The "370 scripts" figure in
  earlier revisions was wrong — see Sources.*
- **Xbox side:** `docs/mercs2-pdb-analysis/*.md` (ten files carry `Player*`-shaped symbols, not
  three) and the PowerPC oracle `output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt`, which
  carries **105 of the 107 binding names verbatim** plus the five `PgPlayer*Mode` classes. No
  `PgSysPlayer` symbol exists in the devkit build, but `PgSysNetPlayer @825902d8` does.
- **Cross-refs:** [`physics_code_map.md`](physics_code_map.md) (character controller),
  [`save_serialize_code_map.md`](save_serialize_code_map.md) (`[0x1176054]`, `.profile`),
  [`camera_code_map.md`](camera_code_map.md), [`vehicle_code_map.md`](vehicle_code_map.md),
  [`scripting_host_binding_code_map.md`](scripting_host_binding_code_map.md),
  [`../modernization/vanilla_boot_load_order.md`](../modernization/vanilla_boot_load_order.md),
  [`../modernization/wave0_seam_review.md`](../modernization/wave0_seam_review.md) Seam G.
- **Validation history:** `validation/player_validation.md` (Pass 1 blind + Pass 2 register-closing).
  Every finding folded in here was **re-derived from the image before being written**, and one Pass-1
  finding was **refused** on that basis: its X5 (`GetControlledObject` uses container `0x00DF81D8`,
  not `0x00DF8188`) does not reproduce — the arithmetic in §2.2 shows `0xDF81D8` is `SeatLink + 0x50`
  and the map's original wording was correct.
- Confidence stated per row. The three remaining gaps are §9.1's **S1** (`player+0x24`'s writer),
  **S2** (`player+0x58`'s writer) and **S3** (three unnamed hash constants); `FUN_006CDB70`'s identity
  is at **M** pending a SecuROM-recovered body.
