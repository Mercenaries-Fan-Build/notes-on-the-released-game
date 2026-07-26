# ObjectFilter — PC code map

**Scope:** the engine's **ECS query / predicate object** as retail PC `Mercenaries2.exe` implements it —
the `ObjectFilter` Lua namespace (`luaL_Reg` table `0x00B98770`, **16 cfuncs**), the `0x24`-byte filter
struct those cfuncs mutate, the **four predicate channels** a filter can carry (label expression ·
explicit object set · association · relation), the **compiled label-expression** format and its
evaluator, the **`Eval` resolution order**, and the **userdata + `_GC` lifecycle** — which is genuinely
unique in this binary: `_GC` is the **only** underscore-GC entry in all 60 binding tables / 1,357
bindings.

This is the system mission Lua uses to say *"any Allied helicopter"*, *"the hero or a faction
vehicle"*, *"these five specific objects but not that one"*, and then hand the result to
`Event.ObjectProximity` / `Event.ObjectDeath` / `Event.ObjectInSeat` as the **subject**. It was
binding-only everywhere and unowned by any silo before this pass.

**Boundaries with sibling maps** (cited, not re-derived):

| Belongs to | Not here |
|---|---|
| [`object_entity_core_code_map.md`](object_entity_core_code_map.md) | the **label store** — multi-valued container `0x00DF8108`, `Object.AddLabel` `FUN_005CE900` / `RemoveLabel` `FUN_005CEBA0` / `HasLabel` `FUN_005CEE40`. This map only *reads* that container. |
| [`player_code_map.md`](player_code_map.md) | the player container `0x00DF9B90`, `GetPlayer` `FUN_006CDAF0`, `player+0x20` = attached character GUID, `DAT_017C0DD0` = max players. Consumed here, owned there. |
| [`event_bus_code_map.md`](event_bus_code_map.md) | `Event.Create` / the subscriber registry. A filter is an *argument* to an event condition; the bus is not modelled here. |
| [`vehicle_code_map.md`](vehicle_code_map.md) | the seat pool `0x00DF8188` and ride mechanics. §7 only uses it to show the occupant-expansion rule. |
| [`ai_code_map.md`](ai_code_map.md) | `Ai.SetRelation` / `GetRelation` / `ChangeRelation` (`0x00B9A938`) — the **writers and the Lua reader** for the very same `Relationship` container this map's relation channel reads. Owned there, consumed here. ⚠ An earlier revision of this map called them a "false friend"; that was wrong — see §5.3. |
| [`scripting_host_binding_code_map.md`](scripting_host_binding_code_map.md) | the cfunc calling convention, the arg-getter helpers, the push idiom. |

**Sources.** PC: the 27k-fn Ghidra decomp `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (unpacked
SecuROM image, base `0x00400000`) — every body cited below was fetched and read first-hand this pass.
Where Ghidra had **no** body (9 of the 16 cfuncs have no static caller for auto-analysis to walk from)
this pass **disassembled the bytes directly** out of `output/_ghidra/securom_dump/mercs2_unpacked.exe`
(a flat dump, `file_off == VA − 0x400000`), and **all 9 came back completely** — every one is
ordinary, un-obfuscated `.text`. So this map is *not* "mostly binding-only", which is the outcome the
brief anticipated. *(Correction: an earlier revision said "7 of those 9" and carried a `○ = still
opaque (2)` legend. There is no opaque cfunc. The two opaque things were `AddObject`/`RemoveObject`'s
**setters**, which are not cfuncs — and those are now decoded too, see §10.)*

**The DRM-free oracle.** Everything that used to sit behind a SecuROM stub is now read out of
**`output/jul08_prototype/mercs2_xenon_p.pe_full.bin`** — a July-2008 **Xbox 360** build with **no
SecuROM at all**, containing the same 16-entry `ObjectFilter` namespace *and all seven mutation
primitives* in plain PowerPC. Mapping is **VA-flat: `file_off == VA − 0x82000000`** (reading through
the section table instead yields mid-function garbage). It is a *different build*, so anything derived
only from it is labelled **cross-build proven**; §10.0 lists the twelve structural agreements that
make the correspondence a join rather than a guess. Binding name→VA is the live Surface-B
`.rdata` walk `mods/lua_trace_asi/reference/binding_map.json` ([[lua-trace-asi-surface-b-oracle]]),
corroborated by [`../lua_engine_bindings_audit_deep_dive.md`](../lua_engine_bindings_audit_deep_dive.md)
(same VA, same 16, 0 stubs). Script traffic is a census over the 370 decompiled scripts in
`docs/mercs2-luacd/src/`. Hash arithmetic via `tools/pandemic_hash.py`
([[no-arbitrary-hashes]]).

**Method / honesty model.** Same discipline as the sibling maps. Confidence: **H** = read the body
with a can't-coincide fingerprint (a constant, an offset, a hash that reproduces) · **M** = one strong
structural signal, or a join across two independently-read bodies · **L/open** = positional or
register-mangled → confirm-live. Every offset states the function it was read from.

**What changed in this revision.** Six claims were corrected against a double-blind validation, and
each correction is left **visible in place** with the old wording quoted, because a silently-fixed map
teaches nothing: the `Ai.*Relation` "false friend" (§5.3) and the relation channel's "distance"
reading (§3.4) were both **wrong**; the "seat-pool critical section" (§4.5), the `flags &= 0x82`
"preserves bit 7 and bit 1" arithmetic (§8.2), the "7 of 9 recovered / 2 opaque" count (§1) and the
"seven SecuROM stubs" count (header) were all **miscounts or crossed labels**. Two rows moved
**M → H** on new evidence (§4.4 associativity, §6.4 polarity). Everything in this map is **static** —
nothing was run and no debugger was attached; §10.8 is the single remaining open item and says so.

> **The SecuROM seam — measured, then routed around.** A `FF 25` (indirect `jmp`) byte-scan over
> `0x005F6C00–0x005F9300` finds **13** split-thunks, not seven; §10.0 tabulates all 13 with their
> slots and targets. *(An earlier revision said "seven"; that was a count of the ones this map then
> cared about.)* `.securom` holds **two distinct populations**: a *plain relocated-code* band
> (`0x031C0000`, `0x032D0000`, `0x034D0000` are ordinary x86 at rest and were read straight out of the
> dump) and a *VM-stub* band around `0x024Exxxx–0x024Fxxxx`. The stub band is genuinely virtualized —
> every slot **is** resolved in the dump, but each target is a `0x20`/`0x30`-spaced descriptor stub
> that funnels into one generic VM entry, so there is no per-function body to read. The stubs come in
> two shapes and **1144 + 1034** of them exist section-wide; the shape-2 middle `push` is a **decoy**
> (1021 distinct values, every one inside a single 32 KB window of `.text`, `0x400000–0x408000`).
> **This is no longer a gap:** the Xbox oracle above supplies all seven bodies in plain PowerPC, so
> §10 is now a *decode*, not a to-do list ([[securom-decompiled-not-a-blocker]]).
>
> Reproduce the census:
> ```python
> d = open("output/_ghidra/securom_dump/mercs2_unpacked.exe","rb").read(); B = 0x400000
> [hex(va) for va in range(0x5F6C00,0x5F9300) if d[va-B:va-B+2] == b"\xff\x25"]   # -> 13 stubs
> ```
> and the VM entry: `0x01AAFF10` is `jmp [0x21FD554]`, `[0x21FD554] = 0x02A30000`, whose first bytes
> are `EB 26` over the inline taunt string `"You Are Now Entering a Restricted Area"` followed by
> `pushal / pushfd / … lock dec byte [edx]` — a spinlock-guarded VM entry, not a function body.

---

## 0. Result in one line

An **ObjectFilter is a `0x24`-byte struct living inside a Lua full-userdata** (Xbox `Create` allocates
it with a literal `li r4, 0x24`), carrying **four independent predicate channels** — a **compiled
label boolean-expression** (an array of `pandemic_hash_m2` tokens in *prefix* order, where `&&`/`||`/`!`
are literally the hashes of their own text: `0x2817EA45` / `0x49FE8F3D` / `0x85C32EB2`, reproduced
exactly by `tools/pandemic_hash.py` **and now recovered verbatim from engine machine code**, §10.7), an
**explicit object set** of GUIDs with a per-entry include bit at `+0x04`, an **association**
compare (`+0x0C` value, `+0x20` operator), and a **relation** compare (`+0x10` other-object,
`+0x14` float operand, `+0x21` operator). `Eval` is **`FUN_005F8390`** and resolves in a fixed order:
*constant override → explicit set (an early-out that overrides everything) → nothing-configured bail →
label expr **AND** association **AND** relation*. Comparison operators are stored as the **ASCII
operator char with bit `0x80` = "or-equal"** (`FUN_005F8F90` int / `FUN_005F90B0` float) — `'<'`=`0x3C`,
`'<='`=`0xBC`, `'>'`=`0x3E`, `'>='`=`0xBE`, `'='`=`0x3D`/`0xBD`, `'!'`=`0x21`/`0xA1`. The two
**player sentinels `0xF0000000`/`0xF0000001`** (`Player.GetAnyCharacter` / `GetAllCharacters`) are
special-cased *inside* the object-set test and **force a true** regardless of the include bit;
`UsePlayers(f,true)` is literally "insert `0xF0000000` into the object set", and `GetCoopPlayerGuid`
is "scan the set for a sentinel and return which one". Lifetime is Lua-owned: **`_GC` is the only
`_GC` in the whole binding surface** and calls the destructor `FUN_005F82C0`, which frees the two
optional heap arrays; the metatable is the **Lua global `_OFMETATABLE`** (not a registry key) and its
`__index = ObjectFilter` makes a filter handle **method-callable** (`f:Eval(g)`).

Two things the map got wrong before this pass and now states flatly: the relation channel is **not a
distance** — `FUN_005880D0` is the `Relationship` scalar that `Ai.GetRelation` returns (§3.4, §5.3) —
and the object/token counts are **5-bit fields that wrap at 32 with no bounds check**, so "≤31" is a
silent-corruption boundary, not a cap (§10.3).

---

## 0.5 Master marriage table

| Role | PC addr | Married by | Conf |
|---|---|---|---|
| **`ObjectFilter` `luaL_Reg` table** | **`0x00B98770`**, 16 entries, 0 stubs | live `.rdata` walk + independent re-walk agree entry-for-entry | H |
| **Cfunc cluster** | **`0x005F6C90`–`0x005F77D0`** (contiguous, `_GC` lowest) | every table slot lands in the range | H |
| **`Eval` core** | **`FUN_005F8390`** | `Eval` `0x005F76E0` calls it at `0x005F77AD`; 12 static callers total | H |
| **Explicit-object-set test** | **`FUN_005F87F0`** | sole caller `0x005F83B6` inside `FUN_005F8390` | H |
| **Label-predicate driver** | **`FUN_005F8C90`** | sole caller `0x005F840D` inside `FUN_005F8390`; iterates label container `0x00DF8108` | H |
| **Label-expression evaluator** (recursive) | **`FUN_005F8E50`** | callers = `FUN_005F8C90` + **itself, twice** → prefix tree walk | H |
| **Label-expression compiler** (recursive) | **`FUN_005F8B00`** | self-recursive; scans `(`/`)`/`&&`/`\|\|`/`!` at paren depth 0 | H |
| **Operator token hashes** | `&&`=`0x2817EA45` · `\|\|`=`0x49FE8F3D` · `!`=`0x85C32EB2` | `pandemic_hash_m2()` **reproduces all three exactly** | H |
| **Int comparator** | **`FUN_005F8F90`** | switch on `0x21/0xA1/0x3C/0xBC/0x3D/0xBD/0x3E/0xBE` | H |
| **Float comparator** | **`FUN_005F90B0`** | identical switch, `float` params | H |
| **Destructor** | **`FUN_005F82C0`** | called from `_GC` at `0x005F6CD9` (disassembled) | H |
| **Clone (deep-copy)** | **`FUN_005F8170`** | called from `Copy` at `0x005F6D62`; memcpys both arrays | H |
| **Allocator / userdata push** | **`0x024E6450`** (via `[0x02458E4C]`) | `Create` tail-calls it; `FUN_005F8170` calls it for the clone target | H |
| **Sentinel scan (`GetCoopPlayerGuid`)** | **`FUN_005F8790`** | called from `0x005F7820` inside `GetCoopPlayerGuid` | H |
| **Object-set iterator** | **`FUN_005F86A0`** → `[0x02458BE8]` → `0x024E6430` | called twice from `GetObjects`; out-param = the per-entry flag byte. Body = Xbox **`0x8247D7E0`** (§10.3) | H |
| **"Add object" primitive** | **`0x024F3060`** | `AddObject` calls it via `thunk_FUN_024F3060`; `UsePlayers` and `FUN_005F79F0` reach the *same* pointer via `[0x0245EF98]`. Body = Xbox **`0x8247D4C0`** (§10.1) | H |
| **`SetFilter` core** (clear + parse) | **`0x032D0000`** | disassembled at rest; opens byte-for-byte identical to `ClearFilter` `0x005F6E7C` | H |
| **Namespace registry row** | **`0x00DFD52C`** (12-byte row, 31 rows, terminator `0x00DFD5EC`) | `{0x00BBB714 "ObjectFilter", 0x00B98770 luaL_Reg, 0x00BBB6D0 post-register Lua chunk}` | H |
| **Metatable** | Lua **global `_OFMETATABLE`** | the `0x00BBB6D0` chunk *is* `_OFMETATABLE = { __gc = ObjectFilter._GC, __index = ObjectFilter }`; Xbox `Create` sets it from `LUA_GLOBALSINDEX` (`li r4, -0x2712`) | H |
| **Lua-value → filter coercion** | **`FUN_005F79F0`** (plain `.text`, `size=1872`) | the event layer's "a bare GUID / the string `"players"` / a number where a filter is expected" helper; also the `+0x18`/`+0x1C` reader-writer | H |
| **Relation source** | **`FUN_005880D0`** on container `0x00DF7F08` = **`Relationship`** | the exact function `Ai.GetRelation` `FUN_005AACE0` wraps (`call 0x5880d0` at `0x005AAD87`) | H |
| **Label store read** | container **`0x00DF8108`** | `FUN_005F8C90` walks it — the container `object_entity_core_code_map.md` §4.2 pins to `AddLabel`/`HasLabel` | H |
| **Player sentinels** | `0xF0000000` / `0xF0000001` | `FUN_005DE260`/`FUN_005DE2A0` push exactly these; `FUN_005F87F0` + `FUN_005F8790` test for exactly these | H |
| **Player roster join** | `FUN_006CDAF0`, `DAT_017C0DD0`, `player+0x20` | `FUN_005F87F0` calls `GetPlayer(i)` in a `DAT_017C0DD0`-bounded loop and compares `+0x20` | H |
| **Filter-driven spatial query / occupant expansion** | **`FUN_005F3110`** (+`FUN_005F2930`/`FUN_005F2B10`/`FUN_005F2C60`) | all four call `FUN_005F8390`; `0x005F311F mov eax,[ebx+0x20]` / `0x005F3122 and byte [eax+0x22],0xC3` holds the filter at `this+0x20` and clears the player latch; body read (§7.1) | H |
| **Container identities** (master key `[[global]]+0x34` → `B8 <imm32> C3`) | `0x00DF8108`=`Label` · `0x00DF8188`=`SeatLink` · `0x00DF7F88`=`Association` · `0x00DF7F08`=`Relationship` · `0x00DF9B90`=`Players` | all five validate the `B8 imm32 C3` shape; see §12 for the 6-line reproducer | H |

---

## 1. The 16-cfunc surface — name → VA

`luaL_Reg` table **`0x00B98770`**, **0 stubs**. Cfuncs are `undefined4 f(lua_State *L)`; every one
opens with the same shape: fetch the filter with `FUN_0059FF50`, and if that fails **push `nil` and
return 1** (no error) — the namespace is uniformly tolerant of a bad handle.

**⬤ = Ghidra body (7)** · **◒ = no Ghidra body, recovered by direct disassembly this pass (9)** ·
*calls* = call sites in `docs/mercs2-luacd/src/`. **There is no opaque cfunc — 16 of 16 are read.**
(A previous revision's legend claimed "◒ (7) · ○ still opaque (2)" while the table below marked all
nine `◒` and carried no `○` row at all. The nine are `_GC`, `Create`, `Copy`, `ClearFilter`,
`ClearObjects`, `UsePlayers`, `ClearAssociation`, `ClearRelation`, `GetCoopPlayerGuid`.)

| # | Name | VA | | calls | Reaches |
|--:|---|---|:-:|--:|---|
| 15 | `_GC` | `0x005F6C90` | ◒ | 0 | `FUN_005F82C0` (destructor) |
| 0 | `Create` | `0x005F6CF0` | ◒ | 15 | `FUN_005F7970` → `[0x02458E4C]` → `0x024E6450` |
| 1 | `Copy` | `0x005F6D10` | ◒ | 2 | `FUN_005F8170` (clone) |
| 2 | `SetFilter` | `0x005F6D70` | ⬤ | 11 | `thunk_FUN_032D0000` (clear + parse) |
| 3 | `ClearFilter` | `0x005F6E30` | ◒ | 0 | inline (memset `0x009EE8D8`) |
| 4 | `AddObject` | `0x005F6EF0` | ⬤ | 7 | `thunk_FUN_024F3060` |
| 5 | `RemoveObject` | `0x005F7020` | ⬤ | 8 | `thunk_FUN_024F3030` |
| 6 | `GetObjects` | `0x005F7130` | ⬤ | 12 | `FUN_005F86A0` (iterator) |
| 7 | `ClearObjects` | `0x005F7250` | ◒ | 0 | inline |
| 8 | `UsePlayers` | `0x005F72E0` | ◒ | 1 | `FUN_005F8480` → `[0x0245EF98]` → `0x024F3060` |
| 9 | `SetAssociation` | `0x005F7390` | ⬤ | 0 | `thunk_FUN_024EA230` |
| 10 | `ClearAssociation` | `0x005F7460` | ◒ | 0 | inline |
| 11 | `SetRelation` | `0x005F74E0` | ⬤ | 0 | inline |
| 12 | `ClearRelation` | `0x005F7650` | ◒ | 0 | inline |
| 13 | `Eval` | `0x005F76E0` | ⬤ | 1 | **`FUN_005F8390`** |
| 14 | `GetCoopPlayerGuid` | `0x005F77D0` | ◒ | 2 | `FUN_005F8790` |

The cfunc wrappers are fully read. The **mutation primitives** they call (`0x024F3060` add,
`0x024F3030` remove, `0x024E6430` iterate, `0x024E6450` alloc, `0x024EA230` set-assoc, `0x024F3000`
emit-token, `0x024F3080` hash-one) are behind the encrypted stub band on PC — and **all seven are now
decoded from the Xbox oracle in §10.**

**Traffic.** 59 call sites total, and **7 of the 16 are never called by shipped content**
(`ClearFilter`, `ClearObjects`, all four `*Association`/`*Relation`, `_GC`). The whole *shipped*
usage is: `Create` a filter, `SetFilter` a label expression, optionally `UsePlayers`, push/pull
specific objects with `AddObject`/`RemoveObject`/`GetObjects`, and hand the handle to an `Event`
condition. `Eval` is called explicitly exactly **once** in the entire corpus
(`mrxtaskobjectivedestroy.lua:11`) — everything else evaluates it *inside* the engine (§7).

---

## 2. The filter object layout

Assembled from `FUN_005F82C0` (destructor — clears every field), `FUN_005F8170` (clone — copies every
field), the four inline `Clear*` cfuncs (each zeroes exactly its own channel), and `FUN_005F8390`
(reads every field). Four independent reads agreeing is why most rows are H.

| Off | Field | Read from | Conf |
|---|---|---|---|
| **`+0x00`** | **object set** — pointer to a `u32[]` of GUIDs, **or the single GUID inline** when flags bit1 | `FUN_005F87F0`, `FUN_005F8790`, `ClearObjects` | H |
| **`+0x04`** | **include bitmask** — bit *i* = the include flag of object *i* (≤31 objects, so one word) | `FUN_005F87F0` (`EDI[1] & 1<<i`), `ClearObjects` | H |
| **`+0x08`** | **label expression** — pointer to the compiled `u32` token array, **or a single label hash inline** when flags bit0 | `FUN_005F8C90`, `ClearFilter`, `SetFilter` core | H |
| **`+0x0C`** | **association value** (int / name hash) | `ClearAssociation` (`mov [eax+0xC],0`), `FUN_005F8390` (`EAX[3]`) | H |
| **`+0x10`** | **relation subject** — the *other* object handle fed to `FUN_005880D0` | `ClearRelation`, `FUN_005F8390` (`EAX[4]`) | H |
| **`+0x14`** | **relation operand** — `float` | `ClearRelation` (`movss [eax+0x14],xmm0`), `FUN_005F8390` (`EAX[5]`) | H |
| **`+0x18`** | **Lua registry anchor** — a `luaL_ref` handle; **`-2` = `LUA_NOREF`**. The destructor resets it to `-2`; **`FUN_005F79F0` is the reader/writer**: `if (*(int*)(p+0x18) == -2) { …push…; *(p+0x18) = FUN_0085FD50(0xFFFFD8F0); }` — `0xFFFFD8F0` = −10000 = `LUA_REGISTRYINDEX`. This is what keeps an engine-held filter alive against Lua GC. | `FUN_005F82C0`, **`FUN_005F79F0`** | H |
| **`+0x1C`–`+0x1D`** | **`u16` refcount** — `FUN_005F79F0` does `*(short*)(p+0x1C) += 1`; Xbox `0x8247E638` is the matching release (decrement, and at zero call the unref helper with `filter+0x18`) | `FUN_005F82C0` (zeroes it), **`FUN_005F79F0`** | H |
| **`+0x1E`** | **object set count/cap** — **low 5 bits = count**, **high 3 bits = capacity in 32-byte units**. ⚠ the count is **not bounds-checked**; it *wraps* at 32 (§10.3) | `ClearObjects` (`and [eax+0x1E],0xE0` — clears count, *keeps* capacity), `FUN_005F8170` (`(b>>5)<<5` = alloc size) | H |
| **`+0x1F`** | **token count/cap** — same split, same unchecked wrap, for the label token array | `ClearFilter` (`and [esi+0x1F],0xE0` after memsetting `(b>>5)<<5` bytes) | H |
| **`+0x20`** | **association operator** (ASCII char, `\|0x80` = or-equal) | `ClearAssociation` (`mov byte [eax+0x20],0`), `FUN_005F8390` → `FUN_005F8F90((char)EAX[8])` | H |
| **`+0x21`** | **relation operator** (same encoding) | `ClearRelation` (`mov byte [eax+0x21],0`), `SetRelation` | H |
| **`+0x22`** | **flags** — see below | five independent bodies | H |

### 2.1 The `+0x22` flag byte

| Bit | Meaning | Read from |
|---|---|---|
| **0** (`0x01`) | **label expression is inline** — `+0x08` holds one label hash directly, not an owned array. Destructor must **not** free it; `SetFilter`/`ClearFilter` just zero `+0x08`. | `FUN_005F82C0`, `ClearFilter` `0x005F6E85`, `SetFilter` core `0x032D0003` |
| **1** (`0x02`) | **object set is inline** — `+0x00` holds one GUID directly. Same ownership rule. | `FUN_005F82C0`, `ClearObjects` `0x005F72A7`, `FUN_005F87F0` (`bVar5>>1 & 1`), `FUN_005F8790` |
| **2–5** (`0x3C`) | **per-player match cache** — bit `2+i` set ⇒ player *i*'s character matched this candidate. Written by `FUN_005F87F0`'s `0xF0000001` arm; **cleared at the top of `FUN_005F3110`** (`*p &= 0xC3`), i.e. it is a *per-query* scratch field, not state. | `FUN_005F87F0`, `FUN_005F3110` |
| **6** (`0x40`) | **constant-result override present** | `FUN_005F8390` first line |
| **7** (`0x80`) | **the constant result** — when bit6 is set, `Eval` returns `flags >> 7` and evaluates nothing else | `FUN_005F8390` first line |

The **ownership bits are the reason `Copy` is not a `memcpy`.** `FUN_005F8170` copies the scalar
fields, then for each of the two arrays: if the source's inline bit is *clear* and the pointer is
non-null, it `FUN_0084AC20`-allocates `(cap>>5)<<5` bytes and `memcpy`s — otherwise it copies the
word verbatim. A reimpl that models "copy = clone the vectors" gets the same *observable* behaviour;
a reimpl that shares the pointer does not.

`FUN_005F8170` copies `+0x00,+0x04,+0x08,+0x0C,+0x10,+0x14,+0x1E,+0x1F,+0x20,+0x21,+0x22` and
**deliberately not `+0x18`/`+0x1C`** — so a `Copy` is an *unanchored, zero-refcount* filter, not a
duplicate of the original's Lua ownership.

### 2.2 The bit-split is validated, not assumed — H

The 5/3 split of `+0x1E`/`+0x1F` is the one layout claim a reader is entitled to doubt, because a
single build can be read either way. It is settled by **compiling the same C twice**: the Xbox build
reads the count as `+0x1E >> 3` (high 5 bits, `srwi r8, r11, 3` at `0x8247D52C`) and the capacity as
`(b & 7) * 8`; the PC build reads the count as `+0x1E & 0x1F` and the capacity as `b >> 5`. That is
exactly the **mirror image** MSVC produces for `unsigned char count:5; unsigned char cap:3;` on a
big-endian versus a little-endian target. The same mirroring applies to `+0x22`: PC bit0 (`0x01`,
"label inline") is Xbox `0x80`, PC bit1 (`0x02`, "object inline") is Xbox `0x40` — which is the mask
the Xbox add primitive tests at `0x8247D4DC` (`rlwinm r10, r11, 0, 25, 25`).

---

## 3. The four predicate channels

A filter is a conjunction of up to four **independent** channels, only the first two of which shipped
content ever uses.

### 3.1 Label expression (`SetFilter` / `ClearFilter`) — the one that matters

`ObjectFilter.SetFilter(f, sExpr)` where `sExpr` is a boolean expression over **object labels** —
the same labels `Object.AddLabel` writes into container `0x00DF8108`
([`object_entity_core_code_map.md`](object_entity_core_code_map.md) §4.2). Verbatim from shipped
scripts:

```lua
ObjectFilter.SetFilter(uFilter, "Hero||(" .. sFaction .. "&&Vehicle)")  -- friendlygate.lua:59
ObjectFilter.SetFilter(uExtractFilter, "Allied && Helicopter")           -- mrxtaskobjectiveextract.lua:56
ObjectFilter.SetFilter(uHumanFilter,  "human")                           -- mine.lua:6, oilcon001.lua:1110
ObjectFilter.SetFilter(uVehicleFilter,"vehicle")                         -- mine.lua:7
ObjectFilter.SetFilter(uVZFilter,     "VZ")                              -- pircon004.lua:373
ObjectFilter.SetFilter(uFilter,       "SpareParts")                      -- wiftutorialcollectibles.lua:24
ObjectFilter.SetFilter(self._uTgtObjFilter, tConfig.sTgtLabelFilter)     -- mrxtaskobjective.lua:24 (data-driven)
```

Grammar (recovered from the compiler `FUN_005F8B00`, §4): labels, `&&`, `||`, `!`, `(`…`)`, and
whitespace is trimmed. `SetFilter` **returns `true`** on success (pushes boolean `1`) and `nil` when
the handle is bad or no string was supplied.

**Labels are case-insensitive.** `pandemic_hash_m2` folds every byte with `ch | 0x20` before mixing,
so `"human"`, `"Human"` and `"HUMAN"` all hash to `0xAD431BF0`. That is why the shipped corpus can be
inconsistent (`"human"` in `mine.lua`, `"Vehicle"` in `friendlygate.lua`) without breaking. **H** —
reproduced with `tools/pandemic_hash.py`.

### 3.2 Explicit object set (`AddObject` / `RemoveObject` / `ClearObjects` / `GetObjects` / `UsePlayers`)

Up to **31** GUIDs (`+0x1E` low-5-bit count), each with an include bit in the `+0x04` word. §6 covers
the polarity, which is the single most important correctness detail in this map.

⚠ **31 is not a cap, it is a cliff.** The count field is incremented with no bounds check anywhere on
the path; the 32nd *distinct* object carries out of the 5-bit field and **wraps the count to 0**,
keeping the capacity class — the set then looks empty and subsequent adds overwrite from index 0. Same
for the token array. Proof and the exact instruction sequence: §10.3.

### 3.3 Association (`SetAssociation` / `ClearAssociation`) — 0 shipped calls

**`SetAssociation(f, sOperator, value)` — arg 2 is the operator. H.** Arg order read off the PC
disassembly: `FUN_0059FF50` (filter) → `FUN_0059FA40` (string, `0x005F73EE`) → `FUN_0059FB00`
(`0x005F7427`), then `thunk_FUN_024EA230`. The primitive is Xbox **`0x8247E888`** and is unambiguous:

```asm
8247e8a0  cmplwi cr6, r31, 0   / beq -> return 0     ; null string  -> fail
8247e8a8  lbz    r11, 0(r31)   / beq -> return 0     ; empty string -> fail
8247e8c0  stw    r3,  0xc(r30)                       ; +0x0C = convert(value)
8247e8c8  stb    r11, 0x20(r30)                      ; +0x20 = op[0]
8247e8cc  lbz    r10, 1(r31) / cmplwi r10, 0x3d      ; op[1] == '='
8247e8dc  rlwimi r11, r10(=1), 7, 0, 0x18            ;   -> set bit 0x80
8247e8e4  li     r3, 1                               ; returns TRUE
```

**identical** operator encoding to `SetRelation`, and the cfunc pushes the primitive's return as a
boolean — so **`SetAssociation` returns `false` when the operator string is empty**. Arg 3 is not a
string; it goes through a numeric converter. At `Eval` time, `thunk_FUN_034D0000` (also the body of
the engine-wide accessor `FUN_00588350`) fetches the candidate's association value out of container
`0x00DF7F88` — which the master key names **`Association`** — and `FUN_005F8F90` does the **signed
integer** compare. *(Previously rated M with "which of the two string arguments is the operator" open;
arg 3 was never a string.)*

### 3.4 Relation (`SetRelation` / `ClearRelation`) — 0 shipped calls

`SetRelation(f, uOtherGuid, sOp, nValue)` — arg order read off the disassembly: `FUN_0059FF50`
(filter) → `FUN_0059FF50` (a **second pointer**, i.e. a GUID, `0x005F7572`) → `FUN_0059FA40` (string,
`0x005F75B3`) → `FUN_0059F780` (number, `0x005F75DA`). Stores the other object at `+0x10`, the float
operand at `+0x14`, and the operator at `+0x21`. At `Eval` time, `FUN_005880D0(candidate, +0x10)`
produces a float which `FUN_005F90B0` compares against `+0x14`.

The **operator encoding is the fingerprint** and it is unmistakable in `SetRelation`'s Ghidra body:

```c
bVar2 = *unaff_EDI;                                   // op[0]
*(byte *)(unaff_ESI + 0x21) = bVar2;
if (unaff_EDI[1] == 0x3d)                             // op[1] == '='
    *(byte *)(unaff_ESI + 0x21) = bVar2 | 0x80;       //   → set the "or-equal" bit
```

which lands exactly on the two comparator switches:

| Stored byte | Source text | `FUN_005F8F90` (int) | `FUN_005F90B0` (float) |
|---|---|---|---|
| `0x3C` | `<`  | `a < b`  | `a < b` |
| `0xBC` | `<=` | `a <= b` | `a <= b` |
| `0x3E` | `>`  | `a > b`  | `a > b` |
| `0xBE` | `>=` | `a >= b` | `a >= b` |
| `0x3D` / `0xBD` | `=` / `==` | `a == b` | `a == b` |
| `0x21` / `0xA1` | `!` / `!=` | `a != b` | `a != b` |
| anything else | — | **false** | **false** |

Both comparators default to **false** on an unrecognised operator, and both treat `=` and `==`
identically. **H.**

#### The relation channel is **relationship**, not distance — H *(retracts a previous claim)*

> **Retracted.** An earlier revision wrote: *"`FUN_005880D0` … returning a float given
> `(candidate, otherObject)` is strongly suggestive of a **distance** query, and would make
> `SetRelation(f, uHero, "<", 50)` read as 'within 50 m of the hero'."* **That inference is wrong**,
> and the §10.4 confirm-live it asked for is unnecessary.

`FUN_005880D0` (402 B, 12+ callers) walks container `PTR_PTR_00DF7F08`, and the master key names that
container **`Relationship`** — validate the shape yourself:

```python
d = open("output/_ghidra/securom_dump/mercs2_unpacked.exe","rb").read(); B = 0x400000
u32 = lambda va: int.from_bytes(d[va-B:va-B+4],"little")
fn  = u32(u32(0x00DF7F08) + 0x34)          # [[global]] + 0x34
assert d[fn-B] == 0xB8 and d[fn-B+5] == 0xC3        # the B8 <imm32> C3 shape
# -> b'Relationship'   (0x00DF8108 -> Label, 0x00DF8188 -> SeatLink, 0x00DF7F88 -> Association)
```

and the identity with the `Ai` namespace is exact, not merely adjacent:

```
Ai.GetRelation  FUN_005AACE0:  FUN_0059FF50(&a) ; FUN_0059FF50(&b)
                005AAD87       call 0x5880d0                    ; <-- the SAME function
                005AADA9       movss [eax], xmm0 ; [eax+4] = 3   ; push as a Lua number
ObjectFilter    FUN_005F8390:  FUN_005880d0(candidate, f->+0x10) ; FUN_005F90B0(xmm0, f->+0x14)
```

So **`ObjectFilter.SetRelation(f, uOther, sOp, nValue)` compares exactly the number
`Ai.GetRelation(candidate, uOther)` returns.** `SetRelation(f, uHero, "<", 50)` means *"objects whose
relation toward the hero is < 50"*. This is a reputation predicate, and there is no built-in
proximity predicate on the filter — proximity is the `Event.ObjectProximity` path (§7).

---

## 4. The compiled label expression

### 4.1 Tokens are `pandemic_hash_m2` of their own text — H

`FUN_005F8E50` compares tokens against exactly three constants, and all three reproduce:

```
pandemic_hash_m2("&&") == 0x2817EA45   ✓
pandemic_hash_m2("||") == 0x49FE8F3D   ✓
pandemic_hash_m2("!")  == 0x85C32EB2   ✓
```

So the compiler is uniform: **every token — operator or label — is emitted as
`pandemic_hash_m2(<the literal token text>)`.** There is no separate opcode space. (Which also means
a label literally named `"&&"` would be indistinguishable from the operator. Nothing ships one.)

**This is now read off the emitter, not inferred from three constants.** The compiler's only output
call is `thunk_FUN_024F3000` (stub `0x005F8A50`, four call sites, all inside `FUN_005F8B00`:
`0x005F8BB3`, `0x005F8C33`, `0x005F8C61`, `0x005F8C7E`), and the Xbox twin `0x8247E900` is
`emit(filter, char* text, int len)` whose **first act** is `bl 0x8247E538` — the same hash-one routine
`SetFilter`'s single-label fast path calls through stub `0x005F7910`. And that routine's hash is
`pandemic_hash_m2` **verbatim in machine code** (Xbox `0x8290BA80`):

```asm
lis r9,0x811C / ori r9,r9,0x9dc5      ; h    = 0x811C9DC5
lis r10,0x100 / ori r10,r10,0x193     ; PRIME= 0x01000193
loop:  ori r11,r11,0x20                ; ch |= 0x20   <-- the case fold, in the engine
       xor r9,r11,r9 / mullw r9,r9,r10 ; h = (ch^h) * PRIME
       …
       xori r11,r9,0x2a / mullw r3,r11,r10   ; return (h ^ 0x2A) * PRIME
```

so **case-insensitivity (§3.1) is engine behaviour read off the instruction stream**, no longer an
inference from `tools/pandemic_hash.py`. *(Previously flagged as an over-reach: "the compiler is
uniform" was asserted from the three operator constants alone.)*

### 4.2 The compiler `FUN_005F8B00`

Recursive, two passes per level, operating on a `[begin,end)` substring:

1. Trim; if the whole substring is wrapped in `(` … `)`, strip one layer.
2. **Pass 1** — scan tracking paren depth; at depth 0, for each `&&` or `||`, **emit the operator
   token** and count it. If the count is 0, fall through to the leaf case.
3. **Pass 2** — scan again; at each depth-0 operator, **recurse on the left operand**, then continue
   after the operator. A leading `!` at depth 0 emits the NOT token and rebases.
4. The trailing (rightmost) operand tail-loops back to step 1.
5. **Leaf**: a leading `!` emits the NOT token; then emit the label hash.

Net: the token stream is **prefix (Polish) order, with all of a level's operators emitted before any
of that level's operands.**

`FUN_005F8B00` is plain `.text` and *is* in the Ghidra decomp (`size=396`, self-recursive at
`0x005F8C17`); it is reached from the `SetFilter` core `0x032D0000` through an obfuscated
`push 0x32D00C7 / push 0x5F8B00 / ret` at `0x032D00B4`. The `0x032D0000` side is also readable at
rest and is where the **inline single-label fast path** lives: scan the string for
`& ! | ( )` (`cmp al,0x26/0x21/0x7C/0x28/0x29` at `0x032D007F`–`0x032D0091`); if none are present,
`or byte [edi+0x22],1` and hash the whole string through `0x005F7910`, storing it at `+0x08`.

### 4.2.1 ⚠ A latent compiler bug: `!` before a parenthesis is silently broken — H

Pass 1 counts operators **only at paren depth 0** (`local_14 == 0` in the decompiled body). For
`"!(A&&B)"` the leading `!` is not an operator, the `(` pushes depth to 1, so the `&&` is never
counted — `opCount == 0` and the loop breaks straight to the **leaf** path. The leaf path is:

```c
if (*begin == '!') { emit(begin, 1); begin = trimleft(begin + 1); }
emit(begin, end - begin);        // hashes ALL the remaining text as ONE label
```

(PC `FUN_005F8B00` tail; Xbox `0x8247EBCC`, where the two `emit` lengths are literal.) So:

```
"!(A&&B)"  ->  [ 0x85C32EB2 , pandemic_hash_m2("(A&&B)") = 0xFBD46457 ]
```

No object carries a label named `(A&&B)`, so the leaf **always misses**, and `NOT` turns that miss
into a match. **`SetFilter(f, "!(A&&B)")` matches every object unconditionally.** `"!(A)"` breaks
identically. `!` works correctly *only* immediately before a bare label — `"!Hero && China"` compiles
to `[&&, NOT, Hero, China]` and evaluates correctly.

Zero shipped expressions contain `!`, so this is latent. It is a sharper trap than §4.4 because it
fails **silently and always-true** rather than merely parsing oddly. Reproduce the trap token with
`python tools/pandemic_hash.py --m2 "(A&&B)"` → `0xfbd46457`.

A reimpl that implements `unary := "!" unary | "(" expr ")"` — as ours does — is **more correct than
retail** here, which is its own kind of divergence (§11.7).

### 4.3 The evaluator `FUN_005F8E50` — a prefix tree walk

```c
bool FUN_005f8e50(int *labels, int nLabels, int *tok, char negate, int *consumed) {
  if (nLabels < 1) return false;
  if (*tok == 0x85C32EB2) { negate = !negate; tok++; (*consumed)++; }        // '!'
  if (*tok != 0x2817EA45 && *tok != 0x49FE8F3D) {                            // leaf: a label hash
      (*consumed)++;
      for (i = 0; i < nLabels; i++) if (labels[i] == *tok) return !negate;
      return negate;
  }
  base = *consumed;
  l = FUN_005f8e50(labels, nLabels, tok + 1, negate, consumed);              // left  subtree
  r = FUN_005f8e50(labels, nLabels, tok + (*consumed - base) + 1, negate, consumed);  // right subtree
  (*consumed)++;
  v = (*tok == 0x2817EA45) ? (l && r) : (l || r);
  return negate ? !v : v;
}
```

`consumed` is how the walk finds the right subtree without a length prefix — the left subtree
self-reports its token count. Both operands are **always evaluated** (no short-circuit) — required by
the token-consumption accounting.

`negate` is threaded *down* into both children **and** applied again to the node result, which looks
like a De Morgan violation waiting to happen: a `NOT` token sitting immediately before a binary
operator would evaluate `!((!A) op (!B))`.

> **That concern is unreachable — retracted.** An earlier revision (and §11.7) warned that retail and
> the reimpl "can disagree on `!(A&&B)`" *by double negation*. They cannot. The compiler's **pass 1
> emits every one of a level's operators before pass 2 can emit any `NOT`** (§4.2 steps 2–3), so a
> `NOT` token can never immediately precede an operator at the same node — the flag is always consumed
> inside a leaf child. The double-application is dead code. Retail and the reimpl *do* disagree on
> `!(A&&B)`, but for the completely different reason in **§4.2.1**.

### 4.4 Associativity: `A && B || C` parses as `(A||B) && C` — H

Because the operators of one level are all emitted **before** its operands, and the evaluator makes
`tok[0]` the root, a level with *n* operators nests **first-operator-outermost**:

```
source:  A && B || C
tokens:  [ &&, ||, A, B, C ]
tree:    &&( ||(A,B), C )      →  (A || B) && C
```

This is not standard precedence, and it is not left-to-right either. **No shipped expression exercises
it** — every multi-operator expression in the corpus parenthesises explicitly
(`"Hero||(Allied&&Vehicle)"` has exactly one top-level operator and parses correctly). So this is a
latent trap rather than an observed bug.

Rated **H**, upgraded from M. Both halves are plain, readable `.text` — the compiler `FUN_005F8B00`
(and its Xbox twin `0x8247E9C8`) and the evaluator `FUN_005F8E50` — so tracing the stream is a
**read**, not a hand-executed inference. The decisive line is pass 1's guard: it emits on
`local_14 == 0 && ((cVar1=='&' && cVar2=='&') || (cVar1=='|' && cVar2=='|'))`, with **no precedence
test of any kind**. There is nowhere in either build for precedence to be applied.

What is *not* proven is that a running game does this too; §10.8 has the two-line in-game
discriminator.

### 4.5 The label-predicate driver `FUN_005F8C90` — H

Two paths, selected by flags bit0:

- **bit0 set (inline single hash):** iterate the candidate's entries in the label container
  `0x00DF8108` and return true on the first entry equal to `+0x08`. No expression machinery at all —
  a fast path for the overwhelmingly common `SetFilter(f, "human")` case.
- **bit0 clear (compiled array):** collect the candidate's label hashes into a **15-slot** stack array
  (`iVar5 < 0xf`, over a `0x38`-byte buffer), then call `FUN_005F8E50` with `+0x08` as the token
  stream.

**An object's 16th and later labels are invisible to a compiled expression.** That cap is real and a
reimpl should either match it or document the deviation.

Both paths take/return `DAT_00EDBAA4` + free list `PTR_DAT_00EDBAC0` around the container iterator —
i.e. **filter evaluation is not lock-free**, which is a constraint for any threaded reimpl.

> **Correction.** An earlier revision called `DAT_00EDBAA4` "the **seat-pool** critical section" — a
> label cross-wired from §7. It is neither the seat-pool lock nor a label-specific lock: it is the
> **global ECS container-iteration critical section + free list**. `DAT_00EDBAA4` appears **901** times
> and `PTR_DAT_00EDBAC0` **1025** times across the decomp, and it is taken around the `Relationship`
> walk in `FUN_005880D0` just as it is around the `Label` walk in `FUN_005F8C90`. The *consequence* is
> unchanged and in fact stronger: every channel of `Eval` that touches a container takes one global
> lock.

---

## 5. `Eval` — the resolution order

`ObjectFilter.Eval(f, uGuid)` (`0x005F76E0`) validates both args and tail-calls **`FUN_005F8390`**
(filter in `EAX`, candidate in `ESI`), pushing the boolean result via `FUN_004B86E0`.

```c
byte FUN_005f8390(void) {   // EAX = filter, ESI = candidate GUID
  // 1. CONSTANT OVERRIDE — nothing else runs
  if (flags & 0x40) return flags >> 7;

  // 2. EXPLICIT OBJECT SET — an early-out that OVERRIDES every predicate, in both directions
  if ((f->objCount & 0x1f) != 0 && f->objects != 0 && FUN_005f87f0(candidate, &out))
      return out;

  // 3. NOTHING CONFIGURED → false  (an empty filter matches NOTHING)
  if ( ((f->tokCount & 0x1f)==0 || !f->expr) && (!(flags & 1) || !f->expr)
       && !f->relation && !f->association ) return 0;

  // 4..6 the remaining channels are AND-ed
  if (has_label_expr && !FUN_005f8c90(f))                       return 0;   // label expression
  if (f->association) { thunk_FUN_034d0000(...);
                        if (!FUN_005f8f90((char)f->assocOp))    return 0; } // int compare
  if (f->relation)    { FUN_005880d0(candidate, f->relation);
                        if (!FUN_005f90b0(xmm0, f->relOperand)) return 0; } // float compare
  return 1;
}
```

Three consequences worth stating flatly:

1. **An empty filter matches nothing**, not everything. (Step 3.)
2. **The explicit object set is not a modifier, it is an override.** A GUID in the set short-circuits
   the whole evaluation and returns its include bit — so an explicitly-excluded object is rejected
   *even if the label expression would have passed*, and an explicitly-included object is accepted
   *even if it carries none of the labels*.
3. **The remaining channels are a conjunction.** There is no way to express "label OR relation" in one
   filter.

### 5.1 Where `Eval` is called from

`FUN_005F8390` has 12 static callers. One is the Lua `Eval` cfunc; the rest are engine-side (§7).
That ratio is the headline: **the filter is an engine query object that Lua configures, not a Lua
utility that the engine ignores.**

### 5.2 Result marshalling

`GetObjects` pushes GUIDs as **tag 2 = lightuserdata** (`piVar1[1] = 2`), matching the project-wide
GUID convention; the boolean-returning cfuncs push tag `1` with value `1`. Consistent with
`player_code_map.md` §3.

### 5.3 `Ai.*Relation` is **not** a false friend — it is the writer for our reader — H

> **Contradicted and rewritten.** The previous text read: *"`Ai.SetRelation` / `Ai.GetRelation` /
> `Ai.ChangeRelation` … are **faction reputation** … They have **nothing to do with**
> `ObjectFilter.SetRelation`. Recorded so the next reader doesn't join them."* Exactly backwards —
> they are the **same system**, and the next reader *should* join them.

`Ai.GetRelation` (`FUN_005AACE0`) is a thin wrapper around **`FUN_005880D0`** — the very function
`FUN_005F8390` calls for the relation channel. Disassemble it and the join is one instruction:

```
005AAD74  call 0x59ff50            ; arg2 -> a second OBJECT handle (not a faction id)
005AAD87  call 0x5880d0            ; <-- FUN_005880D0(a, b)
005AADA9  movss [eax], xmm0
005AADAD  mov dword [eax+4], 3     ; push XMM0 as a Lua NUMBER
```

`Ai.SetRelation` (`FUN_005AADD0`) and `Ai.ChangeRelation` (`FUN_005AAEF0`) write the same container
through `FUN_00588270 → FUN_00649180(&PTR_PTR_00DF7F08, …)`; `ChangeRelation` reads with
`FUN_005880D0` first and writes `old + delta`. Both take **two object handles**, not faction ids.

So: `Ai.*` owns the `Relationship` store (see
[`faction_reputation_code_map.md`](faction_reputation_code_map.md)), and `ObjectFilter`'s relation
channel is a **predicate over it**. `SetRelation(f, uOther, "<", 50)` filters on the number
`Ai.GetRelation(candidate, uOther)` would return.

---

## 6. The player sentinels, `UsePlayers`, and the include/exclude polarity

### 6.1 The sentinels are handled *inside* the object-set test — H

`FUN_005F87F0` opens by deciding whether the candidate **is a player-controlled character**: resolve
its slot (`FUN_00648D80`), fetch the player object (`thunk_FUN_024F1740`), and compare
`candidate == player->attachedCharacter` — i.e. **`player+0x20`**, exactly the field
[`player_code_map.md`](player_code_map.md) §2.2 pins. It then scans the object set **backwards**
(newest entry first) and, for a player-controlled candidate:

- **`0xF0000000`** (`Player.GetAnyCharacter`) → **result = true**, return.
- **`0xF0000001`** (`Player.GetAllCharacters`) → loop `i < DAT_017C0DD0` calling `FUN_006CDAF0(i)`
  (`GetPlayer(i)`), set cache bit `2+i` in `+0x22` where that player's `+0x20` matches, and yield true
  only if **every** player bit is set.
- otherwise → match on GUID equality, result = the `+0x04` include bit.

**Both sentinel arms hardcode the result to true and ignore the include bit entirely.** That is the
key to §6.2.

`FUN_005DE260` pushes `0xF0000000` and `FUN_005DE2A0` pushes `0xF0000001` — both read this pass, both
tag 2, no lookup. The marriage is exact.

### 6.2 `UsePlayers(f, bOn)` is sugar for "add the any-character sentinel" — H

Disassembled at `0x005F72E0`:

```
call 0x59f6d0                ; optional boolean arg
test eax,eax / jle 0x5f734e  ; arg ABSENT   → do the add (default is ON)
cmp byte [esp+0x18],0
je  0x5f735e                 ; arg == false → do NOTHING (no removal!)
0x5f734e:
  mov edi,[esp+0x10]         ; the filter
  push 0
  push 0xF0000000            ; ★ Player.GetAnyCharacter
  call 0x5f8480              ; → [0x0245EF98] → 0x024F3060 == AddObject's primitive
```

Three facts fall out:

1. `UsePlayers(f, true)` ≡ `AddObject(f, Player.GetAnyCharacter(), <flag 0>)`.
2. **`UsePlayers(f, false)` does nothing at all** — it is not a toggle, it cannot un-set what a
   previous `UsePlayers(f, true)` did.
3. Turning it off is done by `RemoveObject`. Which is *exactly* what shipped Lua does:

```lua
-- mrxtaskjob.lua:_CreateNearbyEvent
self._uFarTgtFilter = ObjectFilter.Copy(self._oObjective:GetTargetObjectFilter())
ObjectFilter.RemoveObject(self._uFarTgtFilter, Player.GetAnyCharacter())
ObjectFilter.RemoveObject(self._uFarTgtFilter, Player.GetAllCharacters())
```

Two sentinel removals, in the order the engine stores them. That is a can't-coincide confirmation of
the whole sentinel model.

### 6.3 `GetCoopPlayerGuid(f)` — H

`0x005F77D0` → `FUN_005F8790(filter)`: walk the object set for the first entry equal to `0xF0000000`
or `0xF0000001` and return it (honouring the inline-object flag bit1); return 0 if neither is present.
The cfunc then pushes it as lightuserdata, or **`nil`**.

So the binding answers *"is this filter player-targeted, and in the any-or-all sense?"*, which is
precisely how `mrxtaskobjective.lua:262` uses it:

```lua
local coopGuid = ObjectFilter.GetCoopPlayerGuid(self._uTgtObjFilter)
if coopGuid then self._nTotal = 1 else ... count the non-sentinel targets ... end
```

### 6.4 The third argument of `AddObject` is **`bExclude`**, not `bInclude` — **H (proven)**

This is the correctness detail most likely to be got backwards. It was rated **M** here for one
reason — the include/exclude inversion happens inside a SecuROM-encrypted setter that could not be
read — and §11 used to tell the reader to *"gate on §10.1 before flipping it"*. **That gate is gone.
The inversion is now proven as machine code**, and the fix has shipped (§11).

**The decisive instruction pair.** Xbox `0x8247D5AC`, inside the add primitive `0x8247D4C0`, raw bytes
`578A063E 813F0004 2B0A0000 39400001 7D485830 7D274078 409A0008 7D074B78 90FF0004`:

```asm
8247d5ac  clrlwi  r10, r28, 0x18   ; r10 = (u8) the Lua flag byte  <-- bExclude
8247d5b0  lwz     r9,  4(r31)      ; r9  = filter->includeMask  (+0x04)
8247d5b4  cmplwi  cr6, r10, 0      ; flag == 0 ?
8247d5b8  li      r10, 1
8247d5bc  slw     r8,  r10, r11    ; r8 = 1 << slotIndex
8247d5c0  andc    r7,  r9, r8      ; mask & ~bit   <-- flag != 0  => CLEAR the include bit = EXCLUDE
8247d5c4  bne     cr6, 0x8247d5cc  ; flag != 0 -> keep the andc
8247d5c8  or      r7,  r8, r9      ; mask |  bit   <-- flag == 0  => SET   the include bit = INCLUDE
8247d5cc  stw     r7,  4(r31)
```

The same `andc`/`or` pair appears again in the append path at `0x8247D664`. And the iterator
(`0x8247D920`) computes its out-flag as the **logical negation** of that bit —
`li r11,1 / slw r9,r11,r4 / and r8,r9,r10 / cntlzw r7,r8 / rlwinm r6,r7,0x1b,0x1f,0x1f / stb r6,0(r29)`,
i.e. `out = (cntlzw(mask & bit) >> 5) & 1` = `1` exactly when the include bit is **clear**. So the
out-flag *is* `bExclude`, which is what `GetObjects` compares its argument against.

Reproduce (capstone, `CS_ARCH_PPC | CS_MODE_32 | CS_MODE_BIG_ENDIAN`, `file_off = VA − 0x82000000`):

```python
d = open("output/jul08_prototype/mercs2_xenon_p.pe_full.bin","rb").read()
md.disasm(d[0x8247D5AC-0x82000000 : 0x8247D5D0-0x82000000], 0x8247D5AC)
```

The chain is now closed end-to-end with **no inferred link**:

```
Lua arg 3 = bExclude
  -> add primitive: flag==0 ? SET : CLEAR  bit[i] of +0x04        (0x8247D5AC)
  -> +0x04 bit set == "matches"   (FUN_005F87F0 returns it verbatim as the verdict)
  -> iterator out-flag = !bit                                     (0x8247D920)
  -> GetObjects(f, X) emits where out-flag == X
  => GetObjects(f,false) returns the INCLUDED objects.
```

**PC corroboration (four independent witnesses, all in plain `.text`):**
- `AddObject` (`0x005F6EF0`) fetches the flag with `FUN_0059F6D0` and, **when the argument is
  omitted, forces it to 0** (`local_c &= 0xFFFFFF00`). So the default is 0.
- `UsePlayers(f, true)` — whose *intent* is unambiguously "include players" — passes **0**
  (`0x005F7352 push 0`). ⇒ **0 means include.** *(On its own this is suggestive rather than decisive,
  because `0xF0000000` is force-true in the set test regardless of the bit — hence the next witness.)*
- **`FUN_005F79F0`**, the engine's generic "coerce a Lua value where a filter is expected" helper
  (plain `.text`, `size=1872`), is the decisive in-binary witness and is **not** sentinel-dependent:
  ```
  Lua tag 2 (a bare GUID):    thunk_FUN_024f3060(guid,       0)
  Lua tag 4, s == "players":  thunk_FUN_024f3060(0xF0000000, 0)     ; _strnicmp(s,"players",7)
  Lua tag 4, otherwise:       thunk_FUN_032d0000(s)                 ; == the SetFilter core
  Lua tag 3 (a number):       *(p+0x22) |= 0xC0                     ; constant-override TRUE
  ```
  Handing `Event.ObjectProximity` a bare object GUID **must** mean *"match this object"*, and it emits
  flag **0**. Under a `bInclude` reading, flag 0 would mean "exclude it" and the engine's own
  convenience path would produce a filter matching nothing.
- `GetObjects` (`0x005F7130`) emits an entry when the iterator's flag byte **equals** the caller's
  boolean; with no boolean it emits everything (`ebx` stays `-1`, `jl → EMIT`).

**From shipped Lua (proven):**
- `mrxtaskobjective.lua:27/36` — the parameter is literally named **`bExclude`**:
  `local function _ProcessElement(vElement, bExclude)` …
  `ObjectFilter.AddObject(self._uTgtObjFilter, uGuid, bExclude)`.
- `mrxtaskobjective.lua:51-52` — and the two call sites bind it by name:
  `_ProcessTargets(tConfig.vTgtInclude, false)` / `_ProcessTargets(tConfig.vTgtExclude, true)`.
  The *include* list is passed `false`. That is the interface contract, verbatim, in shipped content.
- `mrxtaskobjective.lua:283` — `RemoveTarget(self, uGuid)` calls `AddObject(f, uGuid, **true**)` and
  then `_SetTargetStatus(uGuid, false)`. Passing `true` **un-targets** the object.
- Every one of the 12 `GetObjects` call sites passes **`false`** and treats the result as the
  objective's **target list** (`tIncludedObjects`, `tTargets`, `tVehicles`, `tTgtInclude`).

**Conclusion (H):** the Lua-facing flag is **`bExclude`** (default `false` = include), and
`GetObjects(f, bExclude)` selects by that same convention — `GetObjects(f, false)` returns the
**included/target** objects, `GetObjects(f, true)` the excluded ones, and `GetObjects(f)` returns
everything. The `+0x04` bitmask stores the **inverse** (`include = !bExclude`), because `Eval` returns
that bit *as* the result; the inversion is the `andc`/`or` pair above.

**⚠ The two argument defaults are opposite.** `AddObject`'s flag defaults to **0** when omitted
(`0x005F6FCA mov byte [esp+0xC],0`; Xbox `0x8247CA78 li r11,0`), but `UsePlayers`' defaults to **on**
(`0x005F7345 jle → do the add`; Xbox `0x8247CE0C li r11,1`). A reimplementer reading only the
`AddObject` rule will make `UsePlayers` default `false` and be wrong. Both builds agree.

**Census.** 7 `AddObject` call sites: 3 literal `false` (`mrxtaskjob.lua:359,361`,
`mrxtaskobjectiverelease.lua:85`), 3 literal `true` (`mrxtaskjob.lua:320`, `mrxtaskobjective.lua:283`,
`mrxtaskobjectivedeliver.lua:270`), 1 variable (`bExclude`, `mrxtaskobjective.lua:36`). All 12
`GetObjects` call sites pass `false`. **Every shipped call passes the argument explicitly**, so the
coincidentally-agreeing default never masked the inversion in our reimpl — it was total.

**The suspected shipped script bug — settled: it is a naming + dead-code defect, not a behavioural
bug.** `mrxtaskjob.lua:310` binds `GetObjects(f,false)` to `tIncludedObjects` (correct as written);
`:349` binds the **identical call** to `tExcludedObjects`, so the local and the `bExcluded` test at
`:352` actually mean *"is included"* — misnamed. The runtime effect is then neutralised: the
unconditional `AddObject(f, uGuid, false)` at `:361` follows both branches, and because the add
primitive **de-duplicates** (§10.1) the second add on the false branch is an in-place bit rewrite, not
a duplicate entry. Both branches of the `if/else` at `:356–360` end with the GUID included, making
that block dead code. Net behaviour = the apparent intent. Low-priority
`docs/fixpack/bug_register.md` note; no longer blocked on anything.

---

## 7. Engine-side consumers, and the occupant-expansion rule

Nine of `FUN_005F8390`'s twelve callers are engine code. The cluster around **`FUN_005F3110`**
(1564 B, called indirectly, holds the filter at `this+0x20` and a 256-entry result buffer at
`aiStack_80c`) is the filter-driven object gather that backs the `Event.Object*` conditions — which is
why shipped Lua hands filter handles straight to `Event.Create`:

```lua
self:_CreateEvent(Event.ObjectProximity, { uExtractFilter, uHeliGuid, "<", nRadius }, ...)
Event.CreatePersistent(Event.ObjectDeath, { uHumanFilter }, t.HumanDied, {t})
self:_CreateEvent(Event.ObjectInSeat,    { oFilter, Player.GetAnyCharacter(), ... })
```

`FUN_005F3110` re-implements `Eval`'s "is anything configured" gate verbatim against `this+0x20`
(`+0x1F & 0x1F`, `+0x08`, `+0x22 & 1`, `+0x10`, `+0x22 & 0x40`) — an independent confirmation of the
struct layout in §2 — and clears the `+0x22` player-cache bits (`&= 0xC3`) at entry.

### 7.1 `FUN_005F3110` is the position-seeded radius gather — H (was M)

Read past the prologue, its shape is unambiguous:

```c
*(filter+0x22) &= 0xC3;                                  // 005F311F/005F3122, the player latch
if (this+0x2C) { FUN_00665AF0(); this+0x30..0x38 = <vec3 position>; }   // seed the query point
if (FUN_005F2D80(this, arg)) return this+0x44 != 0;      // sentinel early-out
if (<nothing configured>)                                // the SAME gate as Eval, verbatim
     while ((g = thunk_FUN_024E6430(...))) collect(g);   // enumerate the filter's OWN object set
else { FUN_005F2860(); n = FUN_00404450(DAT_0117504C, &results[1]); … }  // the spatial query
// then per hit: vtable[0x3C]() -> position; dx²+dy²+dz² against this+0x30/34/38
```

Result buffer `aiStack_80c[257]` plus a parallel `auStack_408[1028]`. Two things follow that a reimpl
needs: it is the **filter-driven radius gather behind the `Event.Object*` conditions**, and **a filter
with an empty predicate but a populated object set enumerates its own set instead of running the
spatial query** — through the very same iterator `GetObjects` uses. The `{2,3,4,10}` occupant kinds
below are joined by a `1` (with `[+0x414] == 6`) and a `12` in this gather's own kind filter.

**The occupant-expansion rule (M).** `FUN_005F2930` / `FUN_005F2B10` / `FUN_005F2C60` all share one
shape:

```c
if (FUN_005f8390())                       return hit;     // the object itself matches
kind = obj->vtable[0xE0]();
if (kind == 2 || kind == 3 || kind == 4 || kind == 10) {  // vehicle-like
    for (seat in container PTR_PTR_00DF8188)              // the seat pool (vehicle_code_map)
        if (occupant resolves && FUN_005f8390())          // ← test each OCCUPANT against the filter
            return hit;
}
```

So **a filter applied to a vehicle also matches when any of its occupants matches.** `"Allied &&
Helicopter"` proximity therefore fires for an Allied *pilot* in a helicopter that itself lacks the
`Allied` label. This is engine behaviour a reimpl will not stumble into by accident, and it is not
modelled anywhere in our Rust today.

---

## 8. Lifecycle — the userdata and `_GC`

### 8.1 The handle is a Lua **full userdata** whose payload *is* the struct — M (strong)

Four independent signals:

1. **`FUN_0059FF50`**, the getter every one of the 16 cfuncs uses for the filter argument, accepts
   **two** Lua tags and normalises them:
   ```c
   if (v->tt == 2) *out = v->value;          // lightuserdata → the pointer itself
   if (v->tt == 7) *out = v->value + 0x18;   // full userdata → skip the Udata header
   ```
   `0x18` is exactly `sizeof(Udata)` on 32-bit Lua 5.1 (next/tt/marked/metatable/env/len, aligned to
   8). A binding surface only writes that branch if some of its objects are full userdata.
2. **`Create` is 27 bytes** (`0x005F6CF0`–`0x005F6D0A`) and does nothing but `jmp` through
   `[0x02458E4C]` → `0x024E6450`, then report **1 Lua result**. There is no room for anything but
   "allocate + push".
3. **`FUN_005F8170` (`Copy`'s clone) calls that same `0x024E6450`** and uses the **returned pointer**
   as the destination struct. One routine that both pushes a Lua value and returns a raw struct
   pointer is `lua_newuserdata` + `setmetatable`.
4. **`_GC` is the only `_GC` in the entire binding surface** — 60 tables, 1,357 entries, one hit.
   `0x005F6C90` fetches the pointer, calls the destructor `FUN_005F82C0`, and **returns 0 Lua
   results**, which is the `__gc` metamethod signature.

### 8.1.1 The metatable is the Lua **global** `_OFMETATABLE` — H

> **Both the map and its validator initially had the wrong shape here**, assuming a *registry key*.
> It is a **global**.

Two independent witnesses:

1. **PC, no debugger needed.** The namespace registry at `0x00DFD478` is **31 rows × 12 bytes**
   (terminator `0x00DFD5EC`) of the form
   `{const char* name; luaL_Reg* funcs; const char* postRegisterLuaChunk;}`. The `ObjectFilter` row is
   at **`0x00DFD52C`** = `{0x00BBB714 → "ObjectFilter", 0x00B98770 → the 16-entry table,
   0x00BBB6D0 → …}`, and that third word is the C string:
   ```
   _OFMETATABLE = { __gc = ObjectFilter._GC, __index = ObjectFilter }
   ```
   The registrar runs that chunk **after** registering the namespace. *(A prior reading called the row
   16 bytes and `0x00BBB6D0` "the name string"; rows are 12 bytes and the name is word **0**. Ten of
   the 31 namespaces ship such a chunk — `_SYS`, `Sys`, `Pg`, `Debug`, `Gui`, `_GuiInternal`,
   `ObjectFilter`, `math`, `VO`, …)*
2. **Xbox `Create` (`0x8247E5C0`) sets it from `LUA_GLOBALSINDEX`:** `lua_newuserdata(L, 0x24)`
   (`li r4,0x24`), zero `+0x00`/`+0x08`, construct, then `li r4, -0x2712` (= −10002 =
   `LUA_GLOBALSINDEX`) with `r5` → the string `"_OFMETATABLE"`, and `li r4,-2 / lua_setmetatable`.
   It returns the raw struct pointer, which is why `FUN_005F8170` can use it as a clone destination.

**`__index = ObjectFilter` means a filter handle is method-callable** — `f:Eval(g)` is legal Lua and
nothing in the shipped corpus uses it, but a reimpl that only exposes the free functions is missing a
Lua-visible affordance.

### 8.2 The destructor `FUN_005F82C0` — H

```c
if (!(flags & 2) && f->objects) FUN_0084ACD0();     // free the object array iff it is owned
flags &= 0xFD;  f->objects = 0;  f->objCount = 0;  f->includeMask = 0;
if (!(flags & 1) && f->expr)    FUN_0084ACD0();     // free the token array iff it is owned
flags &= 0x82;  f->expr = 0;    f->tokCount = 0;
f->association = 0;  f->assocOp = 0;
f->relation = 0;     f->relOp = 0;   f->relOperand = 0;
*(u16*)(f + 0x1C) = 0;
*(u32*)(f + 0x18) = -2;
```

Note `flags &= 0x82` **preserves only bit 7** (the constant result) — a destructor that deliberately
keeps a bit is a destructor that doubles as a reset. *(Correction: an earlier revision said it
"preserves bit 7 **and bit 1**". Arithmetically impossible — `0x005F82D6 and byte [edi+0x22],0xFD`
runs unconditionally **before** `0x005F82F7 and byte [edi+0x22],0x82`, so bit 1 is already clear.)*

Also note it never nulls `+0x18` to 0: writing `-2` is writing **`LUA_NOREF`**, i.e. "this filter no
longer holds a registry anchor", which is precisely what `FUN_005F79F0` tests before minting a new
one (§2).

### 8.3 `ClearFilter` and `ClearObjects` keep capacity — H

Both zero their count nibble with `and <field>, 0xE0`, keeping the high-3-bit capacity, and neither
frees. `ClearFilter` additionally **`memset`s** the token array — `0x009EE8D8` called as
`(ptr, 0, size)` is `memset`, **not** `free`; the free is the destructor's `0x0084ACD0`. Visible at
rest in the `SetFilter` core, where the call is made by an obfuscated push/ret pair:

```asm
032d0028  shr eax,5 / shl eax,5     ; size = (cap>>5)<<5
032d002e  push eax / push [0x245fcec] / push ecx        ; (ptr, fill, size)
032d0036  push 0x32d0049 / push 0x9ee8d8 / ret          ; == call 0x009EE8D8, return to 0x32D0049
032d004c  and byte [edi+0x1f], 0xe0                     ; clear the count, KEEP the capacity
```

So
repeated `SetFilter` on one filter does not churn the allocator — which matters for
`mrxtaskobjective`, which reconfigures its filter on every `ReinterpretConfig`.

---

## 9. What shipped Lua actually does with all this

The whole objective/target system is built on one filter per objective:

```
MrxTaskObjective:Activated()
  self._uTgtObjFilter = ObjectFilter.Create()
  ObjectFilter.UsePlayers(f, tConfig.bTgtPlayers)                 -- inserts 0xF0000000
  ObjectFilter.SetFilter (f, tConfig.sTgtLabelFilter)             -- data-driven label expression
  _ProcessTargets(tConfig.vTgtInclude, false)  -- :51  -> AddObject(f, guid, bExclude=false)
  _ProcessTargets(tConfig.vTgtExclude, true)   -- :52  -> AddObject(f, guid, bExclude=true)
  → GetObjects(f, false)  = the target list  → quota, blips, PDA markers
  → GetCoopPlayerGuid(f)  = "player-targeted?" → quota is 1
  → the handle is passed to Event.ObjectProximity / ObjectDeath / ObjectInSeat

MrxTaskJob:_CreateNearbyEvent()
  self._uFarTgtFilter = ObjectFilter.Copy(objective:GetTargetObjectFilter())
  ObjectFilter.RemoveObject(f, Player.GetAnyCharacter())
  ObjectFilter.RemoveObject(f, Player.GetAllCharacters())
```

`Copy` exists so a task can derive a variant filter from the objective's without disturbing it —
which is precisely why `Copy` must deep-copy the arrays (§2.1).

---

## 10. The seven primitives, decoded — and the one remaining open item

This section used to be a nine-item confirm-live to-do list. **Eight of the nine are closed**, none of
them with a debugger. What closed them was the Xbox oracle (see the header): the seven bodies that PC
SecuROM virtualizes exist in plain PowerPC in a build with no DRM.

### 10.0 The join, and the stub inventory

The 13 `FF 25` split-thunks in `0x005F6C00–0x005F9300`, byte-scanned out of the dump — each row is
`stub → slot → target`, and **every slot is resolved in the static image**:

| stub | slot | target | role |
|---|---|---|---|
| `0x005F6C00` | `0x0245EE64` | `0x024EE260` | **not ours** — called from `0x005F6BA0`, inside `Event.Post` `FUN_005F6A90` (`0x005F6A90`+359) |
| `0x005F78A8` | `0x02455CA0` | `0x024BA600` | — |
| **`0x005F7910`** | `0x0245F448` | **`0x024F3080`** | **hash-one-label**, `SetFilter`'s single-label fast path. No `E8` caller — reached by the `push/push/ret` at `0x032D00D8` |
| **`0x005F7970`** | `0x02458E4C` | **`0x024E6450`** | **allocator / userdata push** (`Create`, `Copy`) |
| `0x005F8330` | `0x024599B0` | `0x024EA250` | called only from `FUN_005F79F0`; one `0x20`-slot above the set-association primitive |
| `0x005F8350` | `0x0245DE78` | `0x028D5000` | a general engine helper, call sites all over the binary |
| **`0x005F8480`** | `0x0245EF98` | **`0x024F3060`** | **add-object** (`AddObject`, `UsePlayers`, `FUN_005F79F0`) |
| **`0x005F85D0`** | `0x0245F0C8` | **`0x024F3030`** | **remove-object** |
| **`0x005F86A0`** | `0x02458BE8` | **`0x024E6430`** | **object-set iterator** (`GetObjects`, `FUN_005F3110`) |
| **`0x005F8920`** | `0x02459F60` | **`0x024EA230`** | **set-association** |
| **`0x005F8980`** | `0x0245E474` | **`0x032D0000`** | the `SetFilter` core — **plain code at rest**, read directly |
| **`0x005F8A50`** | `0x024586A4` | **`0x024F3000`** | **emit-token**, 4 call sites, all inside the compiler `FUN_005F8B00` |
| `0x005F9210` | `0x02458770` | `0x024E6410` | one caller, `0x005F9D0A`, in an unrelated 0xB0-byte constructor. Not ObjectFilter |

Plus `0x00588460` (→`0x034D0000`) and `0x006CDBF0` (→`0x024F1740`) outside the range.

**Why the Xbox correspondence is trustworthy.** The prototype is a *different build* (July 2008), so
everything from it is **cross-build proven**, not PC-proven. Twelve structural agreements make it a
join rather than a guess: same 16 cfuncs in the same order with `_GC` lowest; `Create` allocates
exactly `0x24` bytes; identical offsets for `+0x00/+0x04/+0x08/+0x0C/+0x20/+0x22`; `+0x1E`/`+0x1F` are
count/capacity bitfields in both; `+0x18` registry ref and `+0x1C` `u16` refcount in both; every cfunc
opens "fetch filter → on failure push `nil`, return 1"; `AddObject`'s third arg defaults to 0 in both;
`UsePlayers`' defaults to on in both; `GetObjects` uses the same three-way `{absent,false,true}`
selector; `SetFilter` takes the same no-`& ! | ( )` fast path; the `op[0] | (op[1]=='=' ? 0x80 : 0)`
encoding is byte-identical; and — the strongest single item — **the bitfields are exact mirror
images** (§2.2), which is what one C source compiled for two endiannesses looks like.

| role | PC (virtualized) | Xbox (plain PPC) |
|---|---|---|
| allocator / userdata push | `0x024E6450` | **`0x8247E5C0`** |
| add-object | `0x024F3060` | **`0x8247D4C0`** |
| remove-object | `0x024F3030` | **`0x8247D698`** |
| object-set iterator | `0x024E6430` | **`0x8247D7E0`** |
| set-association | `0x024EA230` | **`0x8247E888`** |
| emit-token | `0x024F3000` | **`0x8247E900`** |
| hash-one-label | `0x024F3080` | **`0x8247E538`** |

The Xbox binding table is at raw `0x2E288`, preceded by the C string `"ObjectFilter"` at `0x2E274`;
`"_OFMETATABLE"` is at `0x2E230` (as the bootstrap chunk) and `0x2E314` (as the bare key string), and
the two player sentinels live in globals `0x8202B698` = `0xF0000000` / `0x8202B69C` = `0xF0000001`.

### 10.1 add-object `0x8247D4C0` — de-duplicates, then sets or clears the bit

```c
if (flags & inline_object) {                             // one GUID stored in +0x00
    if (inlineGuid == guid) { idx = 0; goto SET_BIT; }    // DEDUP
} else {
    for (i = 0; i < count; i++)
        if (array[i] == guid) { idx = i; goto SET_BIT; }  // DEDUP
}
if (count >= capClass*8) {                               // GROW: capClass++, alloc(cap*4), copy, free
    …
}
array[count] = guid;                                     // APPEND
SET_BIT:  mask = flag ? (mask & ~(1<<idx))               // andc  -> EXCLUDE   (0x8247D5AC / 0x8247D664)
                      : (mask |  (1<<idx));              // or    -> INCLUDE
          count++;  return 1;
```

So **`AddObject(f, g, true)` after `AddObject(f, g, false)` flips the existing entry's bit in place** —
it does not append a second entry. (This is what makes the map's §11 "`AddObject` moves a GUID between
the two sets rather than duplicating" a *confirmed* match rather than the open question the old §10.1
called it — the two statements used to contradict each other.)

### 10.2 remove-object `0x8247D698` — an unordered **swap-remove**

Linear scan; on a hit, `count--`, then either null the slot (if the hit *was* the last element) or
`array[i] = array[count]` **and copy bit `count` of the mask onto bit `i`** (`0x8247D758`–`0x8247D7A4`,
the `or`/`andc` pair again). No error on a miss. **Removal re-orders the set** — which matters to
anyone reasoning about `FUN_005F87F0`'s newest-first backward scan. The routine immediately after,
`0x8247D7A8`, is the `ClearObjects` primitive: mask = 0, count = 0 keeping capacity, clear the inline
flag.

### 10.3 iterator `0x8247D7E0` — and the 32-entry wrap

`iterate(filter, index, out flagByte)` → the GUID at `index`, or 0.

- `*out = ((mask >> index) & 1) ? 0 : 1` — the `cntlzw` negation at `0x8247D920` (§6.4). **The
  out-flag is `bExclude`.**
- If the set contains a player sentinel, indices **`>= count` enumerate the live players** and yield
  each player's attached character GUID (`playerCount()`, `getPlayer(i)`, `+0x24 != -1`, return
  `+0x14`), with the out-flag forced to **0 = included**. So **`GetObjects` expands `UsePlayers` into
  real per-player character GUIDs** — a Lua-visible behaviour nothing else in this map records.

**The count is 5 bits and there is no bounds check.** The increment is
`b = (b & 0xF8) + 8` re-merged with the capacity nibble and stored with `stb` (`0x8247D67C`–
`0x8247D68C`; the x86 mirror is `& 0x1F` / `+1`). At count 31 the add carries out of the byte and the
store truncates: **the count wraps to 0**, keeping the capacity class. The 32nd *distinct* object makes
the set look **empty**, and subsequent adds overwrite from index 0. The same arithmetic on `+0x1F` in
emit-token means **a label expression compiling to more than 31 tokens silently truncates to zero**.
"≤31" is therefore a silent-corruption boundary, not a cap.

### 10.4 allocator `0x8247E5C0`, 10.5 set-association `0x8247E888`

Written up where they belong: the metatable and `lua_newuserdata(L, 0x24)` in **§8.1.1**, the
`SetAssociation(f, sOperator, value)` signature and its boolean return in **§3.3**.

### 10.6 emit-token `0x8247E900` / 10.7 hash-one `0x8247E538`

`emit(filter, char* text, int len)` hashes `text[0..len)` with the same hash-one routine
`SetFilter`'s fast path uses, then grow-if-needed and `tokens[count] = hash; count++`. `hash-one`
trims both ends, clamps to 255 bytes, copies to a stack buffer, NUL-terminates, and hashes with
`pandemic_hash_m2` recovered verbatim (§4.1) — including the `| 0x20` case fold and the terminal
`^ 0x2A` round. It returns 0 for an empty string.

### 10.8 STILL OPEN — the one item: *does the running game behave the way the shipped bytes say?*

Everything above is **static**. Nothing was run; no debugger was attached. The two compiler traps
(§4.2.1 and §4.4) are proven **as compiled code in two independent builds**, and the only thing that
would add information is watching them fire. That needs **no debugger** — two lines of mission Lua:

```lua
-- 1. associativity.  Label an object "C" ONLY (not "A", not "B"):
ObjectFilter.SetFilter(f, "A&&B||C");  print(ObjectFilter.Eval(f, g))
--    standard precedence predicts TRUE ( (A&&B) || C ).  This map predicts FALSE ( (A||B)&&C ).
--    "C only" is the discriminating case; "A only" predicts false under BOTH readings.

-- 2. the "!(…)" trap.  On ANY object, whatever its labels:
ObjectFilter.SetFilter(f, "!(A&&B)"); print(ObjectFilter.Eval(f, g))
--    this map predicts TRUE, unconditionally, for every object.
```

**Ruled out as needing live work** (all closed statically, listed so nobody re-opens them): the
include-bit polarity and its inversion site (§6.4); `AddObject` de-duplication and the 31-object
overflow (§10.1, §10.3); the metatable identity (§8.1.1); `SetAssociation`'s argument roles (§3.3);
`FUN_005880D0`'s semantics (§3.4, §5.3); `+0x18`/`+0x1C` (§2); `FUN_005F3110`'s identity (§7.1); and
whether `mrxtaskjob.lua:310/349` is a bug (§6.4 — it is a naming/dead-code defect).

**Genuinely still unrecorded** (small, and nobody is blocked on them): which engine path sets the
constant-override bits `0x40`/`0x80` in normal use — `FUN_005F79F0` sets `0xC0` for a Lua **number**
argument, which is one producer but probably not the only one; and whether the 15-label collection cap
(§4.5) is observable on a real object carrying >15 labels.

If a live session does happen, the old recipe still stands and is a good one: break once on
`0x005F6EF0` with a filter in hand, run `ObjectFilter.AddObject(f, g, true)`, read `[filter+0x04]` —
bit 0 **clear** confirms `bExclude`. Read-only while **PAUSED**; the USER drives execution
([[x32dbg-mcp-no-resume]]); never put a conditional breakpoint on a hot per-frame function
([[x32dbg-mcp-pitfalls]]).

---

## 11. Reconciliation with `mercs2_core::object_filter`

`tools/wad_simulator/crates/mercs2_core/src/object_filter.rs` already implements `ObjectFilter`,
`ObjectFilterRegistry` and `eval_label_expr`, wired up by
`crates/mercs2_script/src/bindings/object_filter.rs`. It is a good-faith reconstruction from the
shipped Lua alone, and on the *shipped* call patterns it is mostly right. Against the exe:

> ### ✅ LANDED — the `bExclude` polarity fix has shipped
>
> Divergence 1 below was the one that silently corrupted mission logic. **It is fixed.**
> `mercs2_core::ObjectFilter::add(&mut self, guid: u64, exclude: bool)` now takes `exclude`, the host
> trait and the engine impl follow, and the binding reads
> `exclude.unwrap_or(false)` — the retail default. A **regression guard test**
> `add_objects_third_arg_is_exclude_not_include` pins it, citing Xbox `0x8247D5AC`, and asserts both
> directions (`true` must land in `exclude`; a later `false` must move it back).
>
> Do **not** "fix" `UsePlayers`' `on.unwrap_or(true)` for consistency — that default is **correct**
> for retail and is the *opposite* of `AddObject`'s (§6.4).

### What matches

| | |
|---|---|
| ✅ | **An empty filter matches nothing.** `matches()` returns `false` on an empty expression; the exe's step-3 bail does the same. |
| ✅ | **The explicit set overrides the predicate in both directions** — exclude beats a passing predicate, include beats a failing one. Same as the exe's step-2 early-out. |
| ✅ | **The grammar's token set** — labels, `&&`, `\|\|`, `!`, `(`…`)`, whitespace-tolerant. Exactly what `FUN_005F8B00` scans for. |
| ✅ | **`Create`/`Copy`/`_GC` mint and free independent handles**, and `copy` is a deep clone (`.cloned()`), matching `FUN_005F8170`. |
| ✅ | **`ClearObjects` keeps the predicate**, matching `0x005F7250`. |
| ✅ | **`AddObject` moves a GUID between the two sets** rather than duplicating. Now *proven* equivalent, not merely plausible: the add primitive de-duplicates on both the inline and array paths and rewrites the existing entry's bit in place (§10.1). |

### What diverges — in descending order of how much it will bite

1. ~~**`AddObject`'s third argument polarity is inverted (§6.4).**~~ **FIXED — see the box above.**
   The binding used to do `include.unwrap_or(true)` and treat the argument as `bInclude`; retail
   treats it as **`bExclude`** (default `false`). The *default* coincidentally agreed, but every
   shipped call site passes the argument explicitly, so the inversion was **total**:
   `MrxTaskObjective:RemoveTarget` *added* a target and `_ProcessTargets(vTgtExclude, true)` included
   the exclusions. Kept in this list, struck through, because the old text told the reader to *"gate
   on §10.1 before flipping it"* — **there is nothing left to gate on** (§6.4). Flipping it also made
   `GetObjects(f,false)` correct for free, exactly as predicted.
2. **`GetObjects` ignores its second argument.** The binding drops `_which` and always returns the
   include set. Retail: no arg = **all** entries, `false` = entries with flag 0, `true` = entries with
   flag 1. All 12 shipped call sites pass `false`, so this is currently invisible — but it is wrong for
   `GetObjects(f)` and for `GetObjects(f, true)`. **And it is now wrong in a second way:** retail's
   iterator *expands the player sentinel* — indices past the stored count enumerate the live players
   and yield each one's attached character GUID, flagged included (§10.3). Our `GetObjects` cannot do
   this at all, so `GetObjects` on a `UsePlayers` filter returns the sentinel (or nothing) where retail
   returns real characters.
3. **Labels are case-insensitive in retail, case-sensitive in the reimpl.** `pandemic_hash_m2` folds
   with `| 0x20`, so `"human"` == `"Human"`. The module doc-comment *claims* case-insensitive; the
   `has_label` closure does exact `HashSet<String>` matching. The shipped corpus mixes cases
   (`"human"` vs `"Vehicle"`), so this **will** bite as soon as the label store and the filter
   disagree on case. Cheapest fix: hash both sides with `pandemic_hash_m2` and compare `u32`s — which
   is also what the engine does, so it removes the question permanently.
4. **The player sentinels are not modelled.** `0xF0000000` / `0xF0000001` are ordinary GUIDs to the
   reimpl. Retail special-cases them inside the object-set test and **forces true** for a
   player-controlled candidate (`0xF0000001` requiring *all* players). `use_players` is stored on the
   struct but `matches()` never reads it — so `UsePlayers` is currently a no-op. Correct model:
   `UsePlayers(f, true)` → `add(0xF0000000)`; `UsePlayers(f, false)` → **nothing**; and
   `matches()` checks the sentinels against "is this GUID some player's attached character".
5. **`GetCoopPlayerGuid` always returns `None`.** Real semantics is a two-line scan of the object set
   for either sentinel (§6.3). `mrxtaskobjective._SetupTargets` branches on it to set the objective
   quota to 1 — so a wrong `None` silently changes mission quotas.
6. **Multi-operator associativity (§4.4).** The reimpl uses standard precedence (`||` below `&&`);
   the exe nests first-operator-outermost. Now **H, not pending** — read off the compiler in two
   builds. Unobservable on shipped content; worth a comment and a test rather than a rewrite.
7. **`!` applied to a parenthesised group (§4.2.1).** *(Rewritten — the old entry blamed the wrong
   mechanism.)* The old text said the exe's threaded-`negate` and the reimpl's `!` "can disagree on
   `!(A&&B)`". They do disagree, but **not** by double negation — that path is unreachable (§4.3).
   They disagree because retail's compiler is **broken** for `!` before `(`: it emits
   `[NOT, m2("(A&&B)")]`, no label ever matches, and the expression evaluates **unconditionally true**.
   Our recursive-descent `unary := "!" unary | "(" expr ")"` is *more correct than retail*. Nothing
   ships a `!`, so this is a documentation item, not a bug to introduce — but a trace-equivalence
   harness fed a synthetic `"!(…)"` will disagree, and this is why.
8. **Association and relation are entirely absent.** The four cfuncs are routed to `record_all` as
   no-op command records. Retail has real semantics: a **signed int** compare and a **float** compare,
   both with the ASCII operator encoding (§3.3, §3.4), and both signatures are now fully known —
   `SetAssociation(f, sOperator, value) -> bool` and `SetRelation(f, uOther, sOp, nValue)` over the
   `Relationship` scalar. Zero shipped call sites, so this stays deprioritised. *(It is **not** the
   engine's proximity predicate — that inference is retracted, §3.4.)*
9. **Structural caps — and they are not caps.** Retail: **32-entry wrap** on the object set *and* on
   the compiled token array (5-bit counts, **no bounds check** — §10.3), **≤15 labels** collected per
   candidate, GUIDs are **32-bit**. The reimpl uses unbounded `Vec<u64>`. A filter that would silently
   corrupt itself in retail just works in the reimpl. If the harness ever needs bug-compatibility,
   this is the one place retail *destroys* data rather than truncating it.
9b. **`RemoveObject` is an unordered swap-remove in retail** (§10.2); our `retain()` preserves order.
   Invisible through `Eval`, visible through `GetObjects` ordering.
9c. **The filter userdata is method-callable** in retail (`__index = ObjectFilter`, §8.1.1); our
   handles are plain integers, so `f:Eval(g)` would fail. Nothing ships it.
10. **The occupant-expansion rule (§7) is not modelled** anywhere. A vehicle matches if any occupant
    matches. This lives above `ObjectFilter` (in the event/query layer), so it belongs to whichever
    silo owns `Event.ObjectProximity` — but it must land somewhere, or "Allied helicopter" proximity
    will under-trigger.

### Suggested order of work

(1) is **done**. Next: (2) → (4)+(5) as one change (they share the sentinel model, and (2)'s sentinel
expansion is part of the same model) → (3) → (10) → (6)/(7)/(9b)/(9c) as tests and comments → (8)/(9)
last. **None of the remaining items needs new RE** — every fact they depend on is in §10.

---

## 12. Provenance

- **PC decomp:** `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (unpacked SecuROM image, base
  `0x00400000`). Bodies read first-hand this pass: the 7 decompiled cfuncs (`SetFilter` `0x005F6D70`,
  `AddObject` `0x005F6EF0`, `RemoveObject` `0x005F7020`, `GetObjects` `0x005F7130`, `SetAssociation`
  `0x005F7390`, `SetRelation` `0x005F74E0`, `Eval` `0x005F76E0`); the evaluator `FUN_005F8390`; its
  four sub-evaluators `FUN_005F87F0` / `FUN_005F8C90` / `FUN_005F8F90` / `FUN_005F90B0`; the
  expression compiler `FUN_005F8B00` and evaluator `FUN_005F8E50`; the clone `FUN_005F8170`; the
  destructor `FUN_005F82C0`; the sentinel scan `FUN_005F8790`; the arg getters `FUN_0059FF50` /
  `FUN_0059FA40` / `FUN_0059F6D0` / `FUN_0059FB00`; the player sentinels `FUN_005DE260` /
  `FUN_005DE2A0`; the engine consumers `FUN_005F2930` / `FUN_005F2B10` / `FUN_005F2C60` /
  `FUN_005F3110`; the relation fetch `FUN_005880D0`.
- **Direct disassembly** (for the 9 cfuncs Ghidra had no body for):
  `output/_ghidra/securom_dump/mercs2_unpacked.exe` — a flat dump, **`file_off == VA − 0x400000`**,
  capstone `CS_ARCH_X86 | CS_MODE_32`. Recovered `_GC`, `Create`, `Copy`, `ClearFilter`,
  `ClearObjects`, `UsePlayers`, `ClearAssociation`, `ClearRelation`, `GetCoopPlayerGuid` — **all 9,
  none opaque** — plus the `GetObjects` selector branch, the `SetRelation` / `SetAssociation` argument
  order, and the plain-at-rest `.securom` bodies `0x032D0000` / `0x034D0000`.
- **★ Xbox 360 DRM-free oracle:** `output/jul08_prototype/mercs2_xenon_p.pe_full.bin`, a July-2008
  build with **no SecuROM**. Mapping is **VA-flat: `file_off == VA − 0x82000000`** (going through the
  section table yields mid-function garbage — recorded so the next reader does not repeat it).
  Disassembled with capstone `CS_ARCH_PPC | CS_MODE_32 | CS_MODE_BIG_ENDIAN`. This is the source for
  all seven primitives (§10), for the metatable (§8.1.1), and for the polarity proof (§6.4). Read
  first-hand this pass: `0x8247D4C0` add, `0x8247D698` remove, `0x8247D7E0` iterate, `0x8247E5C0`
  alloc, `0x8247E888` set-assoc, `0x8247E900` emit-token, `0x8247E538` hash-one, `0x8290BA80` the hash
  itself, `0x8247CA60`/`0x8247CDF4` the two argument defaults, and the 16-row binding table at raw
  `0x2E288`. Everything from it is labelled **cross-build proven** (§10.0 gives the twelve agreements).
- **Master key** (container self-naming, `[[global]] + 0x34` → `B8 <imm32> C3`) — used to name
  `0x00DF8108` `Label`, `0x00DF8188` `SeatLink`, `0x00DF7F88` `Association`, `0x00DF7F08`
  `Relationship`, `0x00DF9B90` `Players`. **The `B8 imm32 C3` shape was validated for each**, not
  assumed; the 6-line reproducer is in §3.4.
- **Namespace registry:** `0x00DFD478`, **31 rows × 12 bytes**, terminator `0x00DFD5EC`, walked
  first-hand; `ObjectFilter` at `0x00DFD52C`.
- **SecuROM census:** `FF 25` byte-scan over `0x005F6C00–0x005F9300` → 13 stubs (§10.0); shape-1
  (`push imm32 ; call 0x01AAFF10`) **1144** section-wide and shape-2
  (`push/push/push/pushfd/sub [esp+4],imm32/popfd/ret`) **1034**, all 1034 arithmetically landing on
  `0x01AAFF10`, whose 1021 distinct middle-`push` values all sit inside `0x400000–0x408000` — a decoy,
  not a return address. `0x01AAFF10` = `jmp [0x21FD554]` → `0x02A30000`, a spinlock-guarded VM entry
  carrying the inline taunt string `"You Are Now Entering a Restricted Area"`.
- **Binding table:** `mods/lua_trace_asi/reference/binding_map.json` (live `.rdata` walk,
  [[lua-trace-asi-surface-b-oracle]]) — 16/16, corroborated by
  [`../lua_engine_bindings_audit_deep_dive.md`](../lua_engine_bindings_audit_deep_dive.md).
- **Hash arithmetic:** `tools/pandemic_hash.py --m2` reproduces `0x2817EA45`, `0x49FE8F3D`,
  `0x85C32EB2` from `"&&"`, `"||"`, `"!"`, `0xAD431BF0` from `"human"`/`"Human"`/`"HUMAN"`, and
  `0xFBD46457` from `"(A&&B)"` (the §4.2.1 trap token) — exactly ([[no-arbitrary-hashes]]). The
  function itself is now also recovered from engine machine code at Xbox `0x8290BA80`, so the tool and
  the engine are independent witnesses rather than one source cited twice.
- **Script traffic + usage patterns:** `docs/mercs2-luacd/src/` (370 scripts) —
  `mrxtaskobjective.lua`, `mrxtaskjob.lua`, `mrxtaskobjectivedestroy.lua`,
  `mrxtaskobjectiveextract.lua`, `friendlygate.lua`, `mine.lua`, `oilcon001.lua`, `oilcon003.lua`,
  `pircon004.lua`, `wiftutorialcollectibles.lua`.
- **Reimpl compared:** `tools/wad_simulator/crates/mercs2_core/src/object_filter.rs` and
  `crates/mercs2_script/src/bindings/object_filter.rs` (read-only).
- **Cross-refs:** [`object_entity_core_code_map.md`](object_entity_core_code_map.md) (label store
  `0x00DF8108`), [`player_code_map.md`](player_code_map.md) (`player+0x20`, `FUN_006CDAF0`,
  `DAT_017C0DD0`, the `0xF0000000` sentinel), [`event_bus_code_map.md`](event_bus_code_map.md)
  (`Event` `luaL_Reg` = `0x00B987F8`, **4 entries**: `Create 0x005F69F0`,
  `CreatePersistent 0x005F6A00`, `Delete 0x005F6A10`, `Post 0x005F6A90` — a filter is an argument to
  it), [`vehicle_code_map.md`](vehicle_code_map.md) (seat pool `0x00DF8188` = `SeatLink`),
  [`faction_reputation_code_map.md`](faction_reputation_code_map.md) (the `Relationship` **writers**
  for this map's reader — §5.3, no longer a "false friend"),
  [`scripting_host_binding_code_map.md`](scripting_host_binding_code_map.md).
- Confidence stated per row. **The five documented gaps of the previous revision — the include-bit
  polarity, the metatable identity, `SetAssociation`'s argument order, `FUN_005880D0`'s semantics, and
  the `+0x18` sentinel — are all closed** (§6.4, §8.1.1, §3.3, §3.4, §2), none of them with a
  debugger. What is *not* closed is the runtime leg: everything here is **static**, nothing was run,
  and the two compiler traps have never been watched firing (§10.8).
