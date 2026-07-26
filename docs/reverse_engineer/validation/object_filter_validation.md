# `ObjectFilter` code map — double-blind validation

- **Target under test:** `docs/reverse_engineer/object_filter_code_map.md`
- **Subject:** the `ObjectFilter` Lua namespace, `luaL_Reg` table VA `0x00B98770`, 16 cfuncs
- **Method:** Phase A written *before* the map was opened, from primary sources only
  (raw unpacked exe disassembly → Ghidra decomp → shipped Lua → binding map). Phase B compares.
- **Date:** 2026-07-26
- **Evidence tier:** `proven` for everything derived from the raw `.text` disassembly and the shipped
  Lua; `inferred` where a SecuROM-encrypted body sits between the observation and the conclusion —
  each such spot is called out inline.

Primary sources actually used:

| # | Source | Use |
|---|---|---|
| 1 | `output/_ghidra/securom_dump/mercs2_unpacked.exe` | capstone x86-32 disassembly; VA→file via the PE section table (`.text` VA `0x401000` → raw `0x1000`; `.rdata` VA `0xB05000` → raw `0x705000`; `.data` VA `0xBF6000` → raw `0x7F6000`) |
| 2 | `output/_ghidra/mercs2_unpacked.exe_decomp.txt` | cross-check + caller lists |
| 3 | `docs/mercs2-luacd/src/resident/*.lua`, `src/vz/*.lua` | argument polarity, shipped expressions |
| 4 | `mods/lua_trace_asi/reference/binding_map.json` | name→VA (verified against raw `.rdata` bytes) |
| 5 | `tools/pandemic_hash.py` | operator-token hash recomputation |
| 6 | `tools/wad_simulator/crates/mercs2_{core,script}/…` | read-only, the thing under suspicion |

---

## Phase A — independent findings (written before reading the map)

### A.1 The table and the namespace are exactly as advertised

Read straight out of `.rdata` at raw offset `0x798770` (VA `0x00B98770`), 8-byte `luaL_Reg` rows,
NULL-terminated after 16 entries:

| # | name | cfunc VA | Ghidra body? |
|---|---|---|---|
| 0 | `Create` | `0x005F6CF0` | no |
| 1 | `Copy` | `0x005F6D10` | no |
| 2 | `SetFilter` | `0x005F6D70` | **yes** (`size=187`) |
| 3 | `ClearFilter` | `0x005F6E30` | no |
| 4 | `AddObject` | `0x005F6EF0` | **yes** (`size=294`) |
| 5 | `RemoveObject` | `0x005F7020` | **yes** (`size=263`) |
| 6 | `GetObjects` | `0x005F7130` | **yes** (`size=277`) |
| 7 | `ClearObjects` | `0x005F7250` | no |
| 8 | `UsePlayers` | `0x005F72E0` | no |
| 9 | `SetAssociation` | `0x005F7390` | **yes** (`size=208`) |
| 10 | `ClearAssociation` | `0x005F7460` | no |
| 11 | `SetRelation` | `0x005F74E0` | **yes** (`size=363`) |
| 12 | `ClearRelation` | `0x005F7650` | no |
| 13 | `Eval` | `0x005F76E0` | **yes** (`size=227`) |
| 14 | `GetCoopPlayerGuid` | `0x005F77D0` | no |
| 15 | `_GC` | `0x005F6C90` | no |

**Ghidra coverage: 7 of 16.** Nine have no Ghidra body.
**I read all 16 bodies from the raw exe** — every one is ordinary, un-obfuscated `.text`. There was
no cfunc I could not disassemble.

Namespace name: the registry at `0x00DFD478` (`.data`) has a 16-byte row whose third word is
`0x00B98770` and whose fourth word is `0x00BBB6D0` → the C string `"ObjectFilter"`. Independent of
`binding_map.json`.

`_GC` census: across all **60 tables / 1,357 entries** in `binding_map.json` there is exactly one
entry literally named `_GC` — this one. (`gcinfo` at `0xB924B8` is the Lua base library, a different
name.) **Confirmed by enumeration, not by sampling.**

### A.2 What is *actually* opaque

Byte-scanning `FF 25` (indirect `jmp`) across `0x005F6C00 – 0x005F9300` finds **13** SecuROM
split-thunks, not two:

| stub VA | slot | static target | role (from call sites) |
|---|---|---|---|
| `0x005F6C00` | `0x0245EE64` | `0x024EE260` | — |
| `0x005F78A8` | `0x02455CA0` | `0x024BA600` | — |
| `0x005F7910` | `0x0245F448` | `0x024F3080` | — |
| **`0x005F7970`** | `0x02458E4C` | `0x024E6450` | **construct/get filter** (`Create`, `Copy`) |
| `0x005F8330` | `0x024599B0` | `0x024EA250` | — |
| `0x005F8350` | `0x0245DE78` | `0x028D5000` | — |
| **`0x005F8480`** | `0x0245EF98` | `0x024F3060` | **AddObject mutation primitive** |
| **`0x005F85D0`** | `0x0245F0C8` | `0x024F3030` | **RemoveObject mutation primitive** |
| **`0x005F86A0`** | `0x02458BE8` | `0x024E6430` | **object-set iterator** (`GetObjects`) |
| **`0x005F8920`** | `0x02459F60` | `0x024EA230` | **SetAssociation primitive** |
| **`0x005F8980`** | `0x0245E474` | `0x032D0000` | **label-expression COMPILER** (`SetFilter`) |
| `0x005F8A50` | `0x024586A4` | `0x024F3000` | — |
| `0x005F9210` | `0x02458770` | `0x024E6410` | — |

At least **six** primitives reachable from the 16 cfuncs are encrypted, not two. The most
consequential is `0x005F8980` — the **label-expression parser** — because the entire grammar
(precedence, associativity, tokenisation of `"Listening Post"`-style labels with embedded spaces)
lives there and is therefore *not statically knowable*.

Stub shapes differ:
- `0x024F3060`: `push 0x24F306A / call 0x01AAFF10`, then an encrypted descriptor
  (`CE 5D 4D 02 | EC 26 00 00 | 3E 54 00 00 | F2 41 00 00`).
- `0x024F3030`: **not** that shape — `push ret / push 0x402DC2 / push 0x1AC0A2C / pushfd /
  sub [esp+4],0x10B1C / popfd / ret`, i.e. it computes `0x1AC0A2C - 0x10B1C = 0x01AAFF10` and
  tail-jumps there. Same destination, different obfuscation.
- `0x01AAFF10` itself is `jmp [0x21FD554]`, and that slot holds `0x02A30000` in the static image —
  a runtime-fixed address. Statically un-followable. **These bodies are genuinely unreadable
  without a live dump.**

### A.3 The filter struct (complete field census from the destructor)

`FUN_005F82C0` (`_GC`'s callee, `this` in **EDI**) writes every field, so it is an exhaustive
layout oracle. Size ≥ `0x23`, i.e. **`0x24` with alignment**.

| off | size | meaning | evidence |
|---|---|---|---|
| `+0x00` | dword | object set: heap `u32[]` when `!(flags&2)`, **inline single GUID** when `(flags&2)` | dtor frees only when `!(flags&2)`; `FUN_005F87F0` / `FUN_005F8790` branch on it |
| `+0x04` | dword | per-slot bitmask, **bit *i* SET ⇒ slot *i* MATCHES** | `FUN_005F87F0:005F890B` `test [edi+4],1<<i / setne` → the returned verdict |
| `+0x08` | dword | label tokens: heap `u32[]` when `!(flags&1)`, **inline single token hash** when `(flags&1)` | `ClearFilter:005F6E7C`; `FUN_005F8C90:005F8C9D` |
| `+0x0C` | dword | association value (signed int) | `ClearAssociation:005F74B0`; `FUN_005F8390:005F8429` |
| `+0x10` | dword | relation "other object" | `SetRelation:005F75FF`; `ClearRelation:005F76A3` |
| `+0x14` | f32 | relation threshold | `SetRelation:005F7602`; `FUN_005F8390:005F8447` |
| `+0x18` | dword | **Lua registry ref (`luaL_ref`), default `-2` = `LUA_NOREF`** | dtor `005F8317` writes `0xFFFFFFFE`; `FUN_005F79F0` tests `== -2` then stores `FUN_0085FD50(LUA_REGISTRYINDEX)` |
| `+0x1C` | i16 | **reference count** | dtor `005F830E` zeroes it; `FUN_005F79F0` does `*(short*)(p+0x1C) += 1` |
| `+0x1E` | byte | low 5 = object **count** (0–31); high 3 = capacity class | `ClearObjects:005F72A3` `and …,0xE0`; copy helper computes bytes `= (b>>5)*8*4` |
| `+0x1F` | byte | low 5 = label token **count**; high 3 = capacity class | `ClearFilter:005F6E95..005F6EB4` |
| `+0x20` | byte | **association operator** | `ClearAssociation:005F74B7`; `FUN_005F8390:005F8423` |
| `+0x21` | byte | **relation operator** | `SetRelation:005F7609`; `FUN_005F8390:005F844A` |
| `+0x22` | byte | flags — see below | everywhere |

`+0x22` bit map (all four uses observed):

| bit | meaning | evidence |
|---|---|---|
| 0 (`0x01`) | `+0x08` holds an **inline** single token (not a heap pointer) | `ClearFilter`, dtor, `FUN_005F8C90` |
| 1 (`0x02`) | `+0x00` holds an **inline** single GUID | `ClearObjects`, dtor, `FUN_005F8790` |
| 2–5 (`0x3C`) | per-player **latch** used by the `0xF0000001` "all players" sentinel | `FUN_005F87F0:005F88B4..005F88E0` |
| 6 (`0x40`) | **constant-override enable** | `FUN_005F8390:005F8399` |
| 7 (`0x80`) | constant-override **value** | `FUN_005F8390:005F839D` (`shr al,7; ret`) |

Two of these fields — **`+0x18` (registry ref) and `+0x1C` (refcount)** — are a fifth channel that
has nothing to do with predicates. Note that the **copy helper `FUN_005F8170` does not copy them**
(it copies `+0x00,+0x04,+0x08,+0x0C,+0x10,+0x14,+0x1E,+0x1F,+0x20,+0x21,+0x22` only), so a `Copy`
produces a filter with a fresh anchor and a zero refcount. That is almost certainly deliberate but
it is worth stating: a `Copy` is **not** a `memcpy`.

### A.4 The evaluator — `FUN_005F8390(EAX = filter, ESI = object guid) → AL`

Verbatim control flow from `0x005F8390`:

```
1. if (flags & 0x40)                       return flags >> 7;        // constant override
2. if ((cnt&0x1F) != 0 && ptr != 0
       && FUN_005F87F0(guid, &out))        return out;               // explicit set — BOTH ways
3. if (no labels && no association && no relation)
                                           return 0;                 // EMPTY FILTER = FALSE
4. if (labels configured && !FUN_005F8C90(filter))      return 0;
5. if (+0x0C != 0 && !FUN_005F8F90(objAssoc, +0x0C, +0x20))  return 0;
6. if (+0x10 != 0 && !FUN_005F90B0(dist, +0x14, +0x21))      return 0;
7. return 1;
```

Confirmed: the explicit set is an **override in both directions** (step 2 returns `out`, which may
be 0), the three remaining channels are **conjunctive**, and **an empty filter matches nothing**.

`Eval` (`0x005F76E0`) is a thin wrapper: read arg1 → filter, validate that arg2 exists, read arg2 →
guid, `FUN_005F8390(EAX=filter, ESI=guid)`, push the result through `FUN_004B86E0` (pushboolean).
Confirmed at `0x005F77A5..0x005F77B7`.

### A.5 The explicit-set test — `FUN_005F87F0` — and the player sentinels

1. Resolve whether the *queried* guid is a player character (global tables `0xDF9BE0` /
   `0xDF9BF4` / `0xDF9BD4`, then `FUN_006CDBF0`, then `cmp guid, [obj+0x20]`) → `DL`.
2. Walk slots from `count-1` down to `0`. Element = `[+0x00]` itself when inline, else
   `[[+0x00] + i*4]`.
3. If `DL` (queried guid is a player):
   - element `== 0xF0000000` → `*out = 1; return true`. **Forces true and never looks at the
     bitmask.** *(Confirmed.)*
   - element `== 0xF0000001` → `*out = 1`, then loop over `[0x017C0DD0]` registered players:
     latch bit `i+2` of `+0x22` for the player matching the queried guid, and clear `*out` if any
     registered player's latch bit is not set. I.e. `0xF0000001` = "**all** players", satisfied only
     once every player has been seen. This **mutates the filter** — `Eval` is not side-effect-free.
4. Exact GUID match at slot `i` → `*out = ((+0x04 >> i) & 1) != 0; return true`.
5. No match → `return false`, `*out` untouched.

So on the internal side, **`+0x04` bit set ⇒ the object matches** (an *include* bit).

`GetCoopPlayerGuid` (`0x005F77D0` → `FUN_005F8790`) scans the set for `0xF0000000`/`0xF0000001` and
returns **the sentinel itself** as a light userdata, or `nil`. It does not return a real player GUID.

### A.6 THE POLARITY QUESTION — `AddObject`'s third argument

**Settled: the third argument is `bExclude`.** Four independent lines of evidence, three of them
inside the exe.

**(i) Argument decoding in `AddObject` (`0x005F6EF0`) — the default is FALSE.**
```
005F6F79  lea eax,[esp+0x10]; push eax; lea edi,[esp+0x20]; call 0x59FF50   ; arg2 -> GUID
005F6FB5  lea edx,[esp+0xC];  push edx; add esi,1; call 0x59F6D0            ; arg3 -> bool
005F6FC6  test eax,eax; jg 0x5F6FCF
005F6FCA  mov byte ptr [esp+0xC], 0                                          ; ARG ABSENT => 0
005F6FCF  mov eax,[esp+0xC]   ; the flag
005F6FD3  mov ecx,[esp+0x10]  ; the GUID
005F6FD7  mov edi,[esp+0x14]  ; the filter (this)
005F6FDB  push eax; push ecx; call 0x5F8480                                  ; primitive(guid, flag)
```
`AddObject(f, guid)` with the flag omitted defaults to **0**. A default of "excluded" would make the
two-argument form useless; a default of "not excluded" is the natural one.

**(ii) `UsePlayers` (`0x005F72E0`) passes 0 to mean *include*.**
```
005F734E  mov edi,[esp+0x10]      ; filter
005F7352  push 0                  ; <-- flag = 0
005F7354  push 0xF0000000         ; the "any player" sentinel
005F7359  call 0x5F8480           ; the SAME AddObject primitive
```
"Use players" is unambiguously inclusive intent, and it passes **0**.
*(Caveat: `0xF0000000` is force-true in the set test, so this call alone is suggestive, not
decisive. See (iii), which is not sentinel-dependent.)*

**(iii) `FUN_005F79F0` — the generic "coerce a Lua value into a filter" helper, in plain `.text`.**
This is the decisive in-binary witness. When the event system is handed a bare object where a filter
is expected, it builds a filter and calls the **same** primitive:
```
Lua type 2 (lightuserdata / a GUID):  thunk_FUN_024F3060(guid, 0)
Lua type 4 (string):                  strnicmp(s,"players",7)==0 -> thunk_FUN_024F3060(0xF0000000, 0)
                                      otherwise                  -> thunk_FUN_032D0000(s)   // SetFilter
Lua type 3 (number):                  ... |= 0xC0                 // constant-override TRUE
```
Handing `Event.ObjectProximity` a bare GUID *must* mean "match this object". It emits flag **0**.
A `bInclude` reading would require flag `0` to mean "exclude this object", which would make the
coercion produce a filter that matches nothing.

**(iv) The shipped Lua names it.** `docs/mercs2-luacd/src/resident/mrxtaskobjective.lua`:
```lua
26:    local function _ProcessElement(vElement, bExclude)
36:        ObjectFilter.AddObject(self._uTgtObjFilter, uGuid, bExclude)
50:    _ProcessTargets(tConfig.vTgtInclude, false)
51:    _ProcessTargets(tConfig.vTgtExclude, true)
...
283:  function RemoveTarget(self, uGuid)
284:    ObjectFilter.AddObject(self._uTgtObjFilter, uGuid, true)
```
The parameter name is recovered from the shipped debug info, and the two `_ProcessTargets` calls
bind `vTgtInclude → false` and `vTgtExclude → true`. `RemoveTarget` = "add with the flag **true**".

**(v) `GetObjects` corroborates.** `GetObjects` (`0x005F7130`) reads an optional bool into `EBX`
(`-1` = absent, `0`, `1`) and per element compares `EBX` against the iterator's out-flag byte:
absent → emit **all**; `true` → emit flag≠0; `false` → emit flag==0. Four shipped call sites bind
`GetObjects(f, false)` to `tIncludedObjects` (`mrxtaskobjective.lua:248,261`, `mrxtaskjob.lua:310`,
and `tTgtInclude` in `mrxtaskobjectivedeliver.lua:345` / `mrxtaskobjectiveverify.lua:64`). So
flag `0` = included ⇒ the flag is `bExclude`.

**Reconciliation.** The Lua-visible flag is `bExclude`; the internal `+0x04` bitmask is an
*include* mask (bit set = match). The inversion therefore happens inside the encrypted setter
`0x024F3060`. **I could not read that inversion directly** — but the polarity of the *interface* is
over-determined by (i)–(v) and does not depend on reading it.

**What would settle the last 1%:** a live single-step of `0x024F3060` under x32dbg (or a memory dump
of a filter's `+0x04` immediately after `ObjectFilter.AddObject(f, g, true)`), checking whether bit 0
of `+0x04` is **clear**. Predicted: clear.

**Consequence for our Rust.** `tools/wad_simulator/crates/mercs2_script/src/bindings/object_filter.rs:64-67`:
```rust
// AddObject(f, guid, bInclude) — bInclude defaults true (an explicit include).
b.real("AddObject", lua.create_function(move |_, (f, guid, include): (i64, i64, Option<bool>)| {
    h.borrow_mut().object_filter_add(f as u64, guid as u64, include.unwrap_or(true));
```
and `mercs2_core/src/object_filter.rs:42-53` (`pub fn add(&mut self, guid: u64, include: bool)`).
Both treat arg 3 as `bInclude`. **Both are inverted.** Every shipped call site passes the argument
explicitly, so the wrong default never masks it — the inversion is total:
`vTgtInclude` objects land in `exclude`, `vTgtExclude` objects land in `include`, and
`RemoveTarget` *adds* a target. The correct form is `exclude.unwrap_or(false)`.

Two further Rust deviations found in passing (not the map's claim, but real):
- `GetObjects` ignores its second argument entirely (`_which`) and returns everything. Retail
  filters by the exclude flag; `false` must return the *included* subset.
- `UsePlayers(f, on)` uses `on.unwrap_or(true)`, which is **correct** for retail
  (`0x005F7345 jle 0x5F734E` → an absent arg still performs the add) — worth recording, because it
  is the opposite default from `AddObject` and looks like a copy-paste bug but is not.

### A.7 Comparison operators — proven end to end, writer *and* reader

**Writer**, in plain `.text`, `SetRelation` at `0x005F7607`:
```
005F7607  mov al, byte ptr [edx]        ; opString[0]
005F7609  mov byte ptr [ecx+0x21], al
005F760C  cmp byte ptr [edx+1], 0x3D    ; opString[1] == '='
005F7610  jne 0x5F7617
005F7612  or  al, 0x80                  ; <-- 0x80 == "or-equal"
005F7614  mov byte ptr [ecx+0x21], al
```

**Readers**, two jump tables decoded from the raw image:

| byte | char | association `FUN_005F8F90` (signed int) | relation `FUN_005F90B0` (f32) |
|---|---|---|---|
| `0x21` | `!` | `setne` | `ucomiss` ≠ |
| `0xA1` | `!=` | `setne` (same case) | ≠ (same case) |
| `0x3C` | `<` | `setl` | `dist < thr` |
| `0xBC` | `<=` | `setle` | `dist <= thr` |
| `0x3D` | `=` | `sete` | `==` |
| `0xBD` | `==` | `sete` (same case) | `==` (same case) |
| `0x3E` | `>` | `setg` | `dist > thr` |
| `0xBE` | `>=` | `setge` | `dist >= thr` |
| anything else | | `xor al,al` (false) | `xor al,al` (false) |

Tables: `FUN_005F8F90` index byte-table `0x005F900C`, target table `0x005F8FF0`; `FUN_005F90B0`
index byte-table `0x005F9168`, target table `0x005F914C`. Both are `op - 0x21`, range `0..0x9D`,
so the legal operator byte range is exactly `[0x21, 0xBE]`.

Note the association compare is **signed integer**; the relation compare is **single-precision
float** on a distance from `FUN_005880D0(objA, objB)`.

`SetRelation`'s Lua signature is therefore `SetRelation(f, otherObject, opString, distance)` —
matching the shipped `Event.ObjectProximity {filter, target, "<", radius}` argument shape.

### A.8 Label expressions — prefix token array, operators hashed from their own text

`FUN_005F8C90` (label channel) has two paths:
- `flags & 1` (inline single token): iterate the object's label component (pool `0x00DF8108`) and
  test equality against `[filter+0x08]`.
- otherwise: **collect at most 15** of the object's labels (`cmp edi, 0xF` at `0x005F8E01`) into a
  stack array, then call `FUN_005F8E50(objLabels, count, tokenArray, negate=0, counter=0)`.

`FUN_005F8E50` is a recursive **prefix (Polish) notation** evaluator. The three magic constants
appear as literal immediates:

| VA | immediate | recomputed | matches |
|---|---|---|---|
| `0x005F8E80` | `0x85C32EB2` | `pandemic_hash_m2("!")` = `0x85C32EB2` | ✔ |
| `0x005F8EAA` | `0x2817EA45` | `pandemic_hash_m2("&&")` = `0x2817EA45` | ✔ |
| `0x005F8EB2` | `0x49FE8F3D` | `pandemic_hash_m2("||")` = `0x49FE8F3D` | ✔ |

All three recomputed independently with `tools/pandemic_hash.py --m2`. **The operators are literally
the m2 hashes of their own source text.** (The Mercs-1 variant does *not* match — it must be `--m2`.)
Since `pandemic_hash_m2` ORs each byte with `0x20`, labels are **case-insensitive**, which is why
`"human"` and `"Hero"` coexist in the shipped scripts.

Evaluator semantics, verbatim:
- a `!` token flips the inherited `negate` flag and is consumed, then evaluation continues at the
  same node;
- a leaf consumes one token; result = `found XOR negate`;
- a binary node evaluates LEFT from `tokens+1`, measures how many tokens LEFT consumed via the
  shared counter, then evaluates RIGHT from `tokens+1+consumed`; the operator token is counted last;
- `&&` / `||` are combined **non-short-circuiting** (both operands always evaluated — required by
  the token-consumption accounting), then the node's own `negate` is applied.

**A latent double-negation defect I found (not asked about).** The `negate` flag is passed **down**
into both operands *and* re-applied at the binary node (`0x005F8F0E` pushes `ebp = negate` to both
recursive calls; `0x005F8F6A` re-tests it). So a `!` immediately preceding a binary operator
evaluates `!((!A) op (!B))` instead of `!(A op B)` — De Morgan is violated. Whether this is
reachable depends on whether the (encrypted) compiler ever emits `! && A B`; it cannot be decided
statically.

**Grammar / precedence is NOT knowable from the exe.** The evaluator is pure prefix — it imposes no
precedence at all. Precedence, associativity, parenthesis handling and the tokenisation of labels
with embedded spaces (`"Listening Post"`) all live in `0x005F8980 → 0x032D0000`, which is
SecuROM-encrypted. Any claim about how `A && B || C` parses is **unverifiable from static analysis**.

Shipped expressions (complete census of `ObjectFilter.SetFilter` call sites, 11 of them):

| file:line | expression |
|---|---|
| `friendlygate.lua:59` | `"Hero||(" .. sFaction .. "&&Vehicle)"` — **the only mixed-operator one, and it parenthesises** |
| `mrxtaskobjectiveextract.lua:56` | `"Allied && Helicopter"` — single operator, spaces around it |
| `mine.lua:6,7`, `proximitymine.lua:7`, `oilcon001.lua:1110` | `"human"`, `"vehicle"` |
| `oilcon003.lua:57`, `pircon004.lua:373` | `"VZ"` |
| `wiftutorialcollectibles.lua:24` | `"SpareParts"` |
| `mecjob.lua:143`, `mrxtaskobjective.lua:24` | data-driven (`sTgtLabelFilter`: `"China"`, `"Allied"`, `"Billboard"`, `"OC"`, `"Guerilla"`, `"VZ"`, `"vehicle"`, `"Listening Post"`, `"PMCCon031Statue"`, `"PMCCon031StatueGL"`, `"SpareParts"` — all single labels) |

So: exactly **one** shipped expression mixes `&&` and `||`, and it does parenthesise. Any grammar
ambiguity is genuinely unexercised by shipped content.

### A.9 Userdata lifecycle and `_GC`

`FUN_0059FF50(EDI = &lua_State*, ESI = arg index, [esp+4] = out)` is the shared argument reader:
```
0059FF7B  cmp eax, 0xB9228C        ; the luaO_nilobject singleton
0059FF94  cmp eax, 7               ; LUA_TUSERDATA  accepted
0059FF99  cmp eax, 2               ; LUA_TLIGHTUSERDATA accepted
0059FFAD  je -> tt==2 : *out = value            (raw pointer, no adjust)
0059FFB2  je -> tt==7 : *out = value + 0x18     (skip the Udata header)
```
`+0x18` **is** `sizeof(Udata)` in 32-bit Lua 5.1: `CommonHeader(6→8) + metatable(4) + env(4) +
len(4) = 20`, aligned up to `L_Umaxalign`(8) = `0x18`. **Confirmed.**

The same reader serves both roles: the **filter** is a *full* userdata (tag 7, hence `_GC`), while
object **GUIDs** are *light* userdata (tag 2). `GetObjects` pushes its results as tag 2
(`mov [eax+4], 2` at `0x005F7207`), and `AddObject`/`SetFilter`/… push `true` as tag 1
(`mov [eax],1 / mov [eax+4],1`). Also worth recording: this build's Lua uses an **8-byte `TValue`**
(`add [L+8], 8`, `sar edx,3`) — i.e. `lua_Number` is `float`, not `double`.

`_GC` (`0x005F6C90`): reads arg 1 as a filter, calls `FUN_005F82C0` (the destructor above),
returns **0** values. On the failure path it pushes `nil` and returns 1. It frees the two heap
buffers and resets all 13 fields; the `Udata` block itself is reclaimed by Lua.

### A.10 Vehicles expand to occupants

`FUN_005F2930` (also `FUN_005F2B10`, `FUN_005F2C60` — all three call `FUN_005F8390`):
```
005F293D  mov esi,[edi+0x10]            ; the candidate object
005F2940  mov eax,[ebp+0x20]            ; the filter
005F2943  call 0x5F8390                 ; test the object itself first
005F2948  test al,al; jne -> return true
005F2952  mov edx,[[edi]+0xE0]; call edx ; virtual "kind"
005F295C  cmp eax,2 / 3 / 4 / 0x0A      ; -> else return false
005F297A  push 0xDF8188                 ; the seat/occupant pool
          ... iterate, resolve each occupant, call 0x5F8390 again, any hit -> true
```
**Confirmed exactly:** object tested first; vtable slot `+0xE0` yields the kind; kinds
`{2, 3, 4, 10}` expand; the pool is `0x00DF8188`.

### A.11 A shipped-script defect at `mrxtaskjob.lua`

```lua
303 function _NearbyRadiusEntry(self, tGuids)
310    local tIncludedObjects = ObjectFilter.GetObjects(self._uFarTgtFilter, false)
...
318      ObjectFilter.RemoveObject(self._uFarTgtFilter, uGuid)
320      ObjectFilter.AddObject(self._uFarTgtFilter, uGuid, true)

345 function _NearbyRadiusExit(self, uGuid)
349    local tExcludedObjects = ObjectFilter.GetObjects(self._uFarTgtFilter, false)   -- <-- same call
...
357      ObjectFilter.RemoveObject(self._uFarTgtFilter, uGuid)
359      ObjectFilter.AddObject(self._uFarTgtFilter, uGuid, false)
361    ObjectFilter.AddObject(self._uFarTgtFilter, uGuid, false)   -- unconditional
```
Line 349 uses the **identical** `GetObjects(f, false)` as line 310 but binds it to
`tExcludedObjects`. Since `false` returns the *included* set, `bExcluded` at line 352 is actually
"is included". **This is a real defect**, but its runtime effect is neutralised: the unconditional
`AddObject(…, false)` at line 361 re-includes the GUID on both branches, making the whole
`if/else` at 356-360 dead code. Net behaviour: `_NearbyRadiusExit` always ends with the GUID
included — which happens to be the apparent intent.

### A.12 Things I could NOT establish

- The bodies of all six reachable SecuROM primitives (`0x024E6450`, `0x024F3060`, `0x024F3030`,
  `0x024E6430`, `0x024EA230`, `0x032D0000`). The chain terminates at
  `0x01AAFF10 → jmp [0x21FD554]`, a runtime-fixed slot. Static analysis stops there.
- Therefore: the **exact inversion site** for the exclude bit, the **grammar** of the label
  compiler, the **growth policy** of the two heap arrays, and the exact **capacity encoding**
  (I can only say `cap_bytes = (b>>5)*32`, `cap_elems = (b>>5)*8`, `class ∈ 0..7`, while the count
  field caps at 31).
- `SetAssociation`'s Lua signature. It reads arg2 with `FUN_0059FA40` (which returns a *slot count*,
  since the caller does `add eax, edi` to advance) and arg3 with `FUN_0059FB00`, then hands both to
  the encrypted `0x005F8920`. **Zero shipped Lua call sites**, so there is no corroborating
  evidence. `+0x20` (the operator) is never written in the visible `.text` — it must be written
  inside `0x005F8920`.
- What sets `+0x22` bits 6/7 in normal use. `FUN_005F79F0` sets `0xC0` for a Lua *number* argument
  under a float comparison against `0.0` that I did not fully resolve (Ghidra renders it as
  `fStack_4 == SUB_00b9b690`, and `[0x00B9B690]` is `0.0f`); I did not disassemble that predicate.
- Whether the `!`-before-binary double-negation and the parser's precedence are reachable in
  practice — both require the encrypted compiler.
- Nothing was verified **at runtime**. No x32dbg session, no live memory read. Every "proven" claim
  here is static.

---

## Phase B — verdicts

*(Written after opening `docs/reverse_engineer/object_filter_code_map.md`.)*

### B.0 Headline

**The map is unusually good.** Of 62 falsifiable claims I could test, **51 are CONFIRMED**, several by
routes the map did not use. It is right about the two things that matter most — the `bExclude`
polarity and the `(A||B)&&C` associativity trap — and it is right about a claim I had written off in
Phase A as unknowable.

**It also corrected me twice**, which is the honest headline of this validation:

1. **I was wrong that the label grammar is unreadable.** The map says `0x032D0000` (the `SetFilter`
   core) is *plain code at rest*. It is. I disassembled it at raw offset `0x02ED0000`: it opens with
   `mov al,[edi+0x22] / test al,1` — byte-for-byte the `ClearFilter` shape — scans the string for
   `& ! | ( )`, takes an **inline single-hash fast path** when none are present
   (`or byte [edi+0x22],1`, hash via `0x005F7910`), and otherwise calls **`FUN_005F8B00`** through an
   obfuscated `push 0x32D00C7 / push 0x5F8B00 / ret`. `FUN_005F8B00` is ordinary `.text` and *is* in
   the Ghidra decomp. My Phase A §A.12 and §A.8 statements that the grammar "lives in an encrypted
   body" and is "unverifiable from static analysis" are **retracted**.
2. **I was wrong that `ClearFilter` frees the token array.** `0x009EE8D8` called as
   `(ptr, 0, size)` is **`memset`**, not `free`; the destructor's `0x0084ACD0` is the free. The map
   says memset and keeps capacity. It is right; §A.3/§A.9 of my Phase A overstate.

The two corrections cut in opposite directions from the usual failure mode: the map was *less*
confident than the evidence warranted, not more. Its `M` on associativity should be `H`, and its `M`
on the polarity should be `H` for the interface.

The residual problems are: a **self-contradicting recovery count**, a **materially incomplete
SecuROM inventory**, **two open questions the map declares open that are actually answerable from
`.text`**, and a **latent compiler bug in `!(…)` that neither of us had**.

### B.1 CONFIRMED — 51 claims

Grouped; every row was re-derived from a primary source before the map was opened, except the three
marked ⟳ which the map prompted me to check and which then verified.

**Surface and addressing (10)**

| Map claim | How confirmed |
|---|---|
| `luaL_Reg` at `0x00B98770`, **16 entries, 0 stubs** | re-read the raw `.rdata` bytes at file offset `0x798770`; NULL row at index 16 |
| all 16 name→VA rows | byte-identical to my independent dump (§A.1) |
| cluster `0x005F6C90`–`0x005F77D0` contiguous, `_GC` lowest | every table VA lands in the range |
| `Eval` core = `FUN_005F8390`, called at `0x005F77AD` | disassembled `0x005F76E0`: `mov esi,[esp+0xC]; mov eax,[esp+0x10]; call 0x5F8390` |
| set test `FUN_005F87F0`, sole caller `0x005F83B6` | disasm + Ghidra caller list |
| label driver `FUN_005F8C90`, caller `0x005F840D`, container `0x00DF8108` | disasm; `push 0xDF8108` at `0x005F8CB2` |
| expression evaluator `FUN_005F8E50`, self-recursive **twice** | callers `0x005F8F1A`, `0x005F8F3A` |
| destructor `FUN_005F82C0` from `_GC` at `0x005F6CD9` | disasm |
| clone `FUN_005F8170` from `Copy` at `0x005F6D62`, memcpys both arrays | disasm; `call 0x009EE832` twice |
| sentinel scan `FUN_005F8790` from `0x005F7820` | disasm |

**Struct layout (13)** — every row of the map's §2 table and all five `+0x22` bit rows confirmed
against my independent destructor census (§A.3), including the non-obvious ones:

- `+0x1E`/`+0x1F` split **low-5 = count, high-3 = capacity in 32-byte units** ✔ (`(b>>5)<<5` is
  passed as the byte size to both `memset` and the clone's allocator);
- `+0x22` bit0 = label inline / bit1 = object inline, with the **ownership rule** the destructor
  enforces ✔;
- `+0x22` bits 2–5 = per-player latch, **cleared at the top of `FUN_005F3110`** ✔ ⟳ — verified
  directly: `005F311F mov eax,[ebx+0x20] / 005F3122 and byte ptr [eax+0x22], 0xC3`. This also
  confirms the map's §0.5/§7 "holds the filter at `this+0x20`";
- `+0x22` bit6 = override enable, bit7 = override value ✔ (`test al,0x40 / shr al,7 / ret`).

**Evaluation semantics (8)**

| Map claim | How confirmed |
|---|---|
| `Eval` order: override → set → nothing-configured bail → label ∧ assoc ∧ relation | line-for-line against `0x005F8390` disasm |
| **an empty filter matches NOTHING** | `005F83ED xor al,al` on the bail path |
| the explicit set is an **override in both directions** | `005F83BF mov al,[esp+7]` returns the out-byte verbatim, 0 or 1 |
| remaining channels are a **conjunction**, no OR | three sequential `je 0x5F83ED` |
| association compare is **integer**, relation is **float** | `FUN_005F8F90` uses `setl/setle/setg/setge`; `FUN_005F90B0` uses `comiss/ucomiss` |
| operator byte = **ASCII char with `0x80` = or-equal** | the **writer** in `SetRelation` (`005F7607..005F7614`, `or al,0x80` when `op[1]=='='`) *and* both **reader** jump tables decoded from raw bytes |
| the 8 accepted bytes `0x21/0xA1/0x3C/0xBC/0x3D/0xBD/0x3E/0xBE`, everything else **false**, `=`≡`==` | decoded `FUN_005F8F90` (index `0x005F900C`, targets `0x005F8FF0`) and `FUN_005F90B0` (index `0x005F9168`, targets `0x005F914C`) — exactly those 8, all others → the `xor al,al` case |
| `GetObjects` emits when the flag byte **equals** the caller's boolean; no arg = everything | `005F71CD..005F71E5` three-way on `ebx ∈ {-1,0,1}` |

**Label expressions (7)**

| Map claim | How confirmed |
|---|---|
| tokens are `pandemic_hash_m2` of their own literal text | recomputed all three: `"&&"`→`0x2817EA45`, `"||"`→`0x49FE8F3D`, `"!"`→`0x85C32EB2`, matching the immediates at `0x005F8EAA`, `0x005F8EB2`, `0x005F8E80` |
| labels are **case-insensitive**, `m2("human") == 0xAD431BF0` | recomputed; `"human"`/`"Human"`/`"HUMAN"` all `0xAD431BF0` |
| compiler `FUN_005F8B00` is recursive, two passes, scans `( ) && \|\| !` at depth 0, strips one paren layer | ⟳ read the body; the map's §4.2 five-step description is accurate step for step |
| whitespace is trimmed | `FUN_005F78A0`/`FUN_005F78D0` are `isspace`-driven trim-left/trim-right (the CRT `isspace` via `[0x00B05388]`) |
| the token stream is **prefix, all of a level's operators before any of its operands** | pass 1 emits every depth-0 operator; pass 2 only then recurses operands |
| evaluator uses `consumed` to find the right subtree | `005F8F1F mov ecx,[esi] / sub ecx,[esp+0x10]` then `lea edx,[edi+ecx*4+4]` |
| **`A && B || C` parses as `(A\|\|B) && C`** — §4.4 | ⟳ **now proven, not inferred.** Hand-executed compiler → `[&&, \|\|, A, B, C]`; hand-executed evaluator on that stream → `&&( \|\|(A,B), C )`. See B.4 — this should be **H**, not M |
| 15-label collection cap over a `0x38`-byte buffer | `005F8D81 push 0x38` … `005F8E01 cmp edi,0xF` |
| evaluation takes a critical section (`0x00EDBAA4` + free list `0x00EDBAC0`) | `call [0x00B05128]`/`[0x00B0512C]` around both container walks |

**Players and polarity (7)**

| Map claim | How confirmed |
|---|---|
| sentinels handled **inside** `FUN_005F87F0`; both arms **force true and ignore the include bit** | `005F8886` (`0xF0000000` → `*out=1`) and `005F8895` (`0xF0000001`) |
| `0xF0000001` requires **every** player latched | the `[0x017C0DD0]`-bounded loop clears `*out` if any player's bit 2+i is unset |
| player-object fetch is `thunk_FUN_024F1740`; roster via `FUN_006CDAF0`, `DAT_017C0DD0`, `player+0x20` | ⟳ `0x006CDBF0 = jmp [0x0245A3E4]`, and `[0x0245A3E4] = 0x024F1740` — **exactly right** |
| `FUN_005DE260`/`FUN_005DE2A0` push exactly `0xF0000000`/`0xF0000001` as tag 2 | disassembled both; `mov [eax],0xF00000xx / mov [eax+4],2` |
| `UsePlayers(f,true)` ≡ `AddObject(f,0xF0000000,<0>)` **through the same pointer** `[0x0245EF98]` | both `AddObject` and `UsePlayers` `call 0x005F8480`, which is `jmp [0x0245EF98] → 0x024F3060` |
| `UsePlayers(f,false)` does **nothing**; absent arg = ON | `005F7345 jle 0x5F734E` (absent → do it) / `005F734C je 0x5F735E` (false → skip) |
| `GetCoopPlayerGuid` scans for a sentinel and returns it or `nil`; honours the inline bit | `FUN_005F8790` both arms |
| **the third argument of `AddObject` is `bExclude`** | see B.3 — confirmed and *strengthened* |

**Lifecycle and marshalling (6)**

| Map claim | How confirmed |
|---|---|
| `FUN_0059FF50` accepts tag 2 raw and tag 7 **+`0x18` = `sizeof(Udata)`** | `0059FFAD/0059FFB2` dispatch; `0x18` = Lua 5.1 32-bit `Udata` aligned size |
| `_GC` is the **only** `_GC` in 60 tables / 1,357 bindings | enumerated every entry in `binding_map.json` — exactly one hit |
| `_GC` returns **0** results (the `__gc` signature) | `005F6CE0 xor eax,eax` on the success path |
| `Create` is 27 bytes and does nothing but reach `[0x02458E4C] → 0x024E6450`, reporting 1 result | disasm `0x005F6CF0`–`0x005F6D0A` |
| `GetObjects` pushes **tag 2 lightuserdata**; boolean cfuncs push tag 1 value 1 | `005F7207 mov [eax+4],2`; `mov [eax],1 / mov [eax+4],1` |
| `ClearFilter`/`ClearObjects` keep capacity (`and …,0xE0`), neither frees; `ClearFilter` memsets via `0x009EE8D8` | disasm — **and this corrects my Phase A**, which called it a free |

**Engine consumers (3)**

- occupant expansion in `FUN_005F2930`/`2B10`/`2C60`: object tested first, then vtable `+0xE0` kind
  ∈ `{2,3,4,10}`, then walk the seat pool `0x00DF8188` and re-`Eval` each occupant ✔ — verbatim.
- `FUN_005F3110` holds the filter at `this+0x20` ✔ ⟳.
- `FUN_005F8390` has 12+ static callers, one of which is the Lua `Eval` ✔.

**Script census (3)** — `59` call sites total, the per-cfunc counts (`Create` 15, `GetObjects` 12,
`SetFilter` 11, `RemoveObject` 8, `AddObject` 7, `GetCoopPlayerGuid` 2, `Copy` 2, `UsePlayers` 1,
`Eval` 1), and "7 of 16 never called by shipped content" — **all three match my independent census
exactly**, including the single explicit `Eval` at `mrxtaskobjectivedestroy.lua:11`.

### B.2 CONTRADICTED — 4

**C1 — the recovery count contradicts the map's own table. (Both sides stated.)**
*Map, line 31-32:* "7 of those 9 came back completely". *Map, line 111-112 legend:*
"◒ = no Ghidra body, recovered by direct disassembly this pass **(7)** · ○ = still opaque **(2, both
behind encrypted SecuROM stubs)**".
*Truth:* the map's **own §1 table marks all 9 with ◒ and carries no `○` row at all** — count them:
`_GC`, `Create`, `Copy`, `ClearFilter`, `ClearObjects`, `UsePlayers`, `ClearAssociation`,
`ClearRelation`, `GetCoopPlayerGuid`. I independently disassembled all 9 and every one is ordinary,
complete `.text`. **9 of 9, not 7 of 9.** The prose at line 134-136 shows what happened — the "2
opaque" are `AddObject`/`RemoveObject`'s *setters*, which are not cfuncs and are already marked ⬤ in
the table. The legend conflates two different populations. Cosmetic in effect, but it is the number a
reader will quote.

**C2 — `+0x18` and `+0x1C` are not open questions.**
*Map §2:* `+0x18` "reset to **-2** by the destructor; **never read by anything in this cluster**"
(conf: open); `+0x1C`–`+0x1D` "two bytes, zeroed by the destructor, **otherwise untouched here**"
(conf: open). *Map §10.5* asks for a hardware write-watchpoint to find the reader.
*Truth:* **`FUN_005F79F0`** (plain `.text`, `size=1872`, in the Ghidra decomp) reads and writes both:
```c
uVar5 = thunk_FUN_024e6450(param_1);                 // get/create the filter
if (*(int *)(uVar5 + 0x18) == -2) {                  // == LUA_NOREF
    ... push the value ...
    *(undefined4 *)(uVar5 + 0x18) = FUN_0085fd50(0xffffd8f0);   // luaL_ref(L, LUA_REGISTRYINDEX)
}
*(short *)(uVar5 + 0x1c) = *(short *)(uVar5 + 0x1c) + 1;        // refcount++
```
`+0x18` is a **Lua registry reference** (`-2` = `LUA_NOREF`) that anchors the userdata against GC
while the engine holds it; `+0x1C` is a **16-bit refcount**. §10.5 is answerable from the decomp with
no debugger. (Corollary the map also misses: `FUN_005F8170` does **not** copy either field, so a
`Copy` yields an unanchored, zero-refcount filter — deliberate, but it means `Copy` is not just a
"deep clone of the two arrays".)

**C3 — the SecuROM inventory is materially undercounted.**
*Map, line 46-47:* "**Seven** functions in this cluster are reached through `jmp [ptr]` stubs into
`.securom`."
*Truth:* a byte-scan for `FF 25` across `0x005F6C00`–`0x005F9300` finds **13** — `0x005F6C00`,
`0x005F78A8`, `0x005F7910`, `0x005F7970`, `0x005F8330`, `0x005F8350`, `0x005F8480`, `0x005F85D0`,
`0x005F86A0`, `0x005F8920`, `0x005F8980`, `0x005F8A50`, `0x005F9210` — plus `0x00588460`
(→`0x034D0000`) and `0x006CDBF0` (→`0x024F1740`) outside the range. At least **eight** are reachable
from the 16 cfuncs, including two the map never names: **`0x005F8A50` → `0x024F3000`, the
emit-token primitive `FUN_005F8B00` calls for every token**, and **`0x005F7910` → `0x024F3080`, the
single-label hash on `SetFilter`'s fast path**. Those two are precisely the routines that would
prove the tokens are `pandemic_hash_m2` rather than merely matching three known constants — a gap
the map's §4.1 "**So the compiler is uniform: every token … is emitted as `pandemic_hash_m2(text)`**"
glosses over. That sentence is an inference from three operator constants, not a read of the emitter.

**C4 — `Copy` "preserves bit 7 and bit 1" is arithmetically impossible.**
*Map §8.2:* "Note `flags &= 0x82` **preserves bit 7** and bit 1".
*Truth:* the destructor executes `and byte [edi+0x22], 0xFD` (clearing bit 1) *before* the
`and …, 0x82`, at `0x005F82D6` and `0x005F82F7` respectively. Bit 1 is already gone. Only bit 7
survives. Minor, but it is stated as a deliberate design observation.

### B.3 THE ONE THAT MATTERS — `bExclude` vs `bInclude`: the map is RIGHT, and it is more certain than it says

**Verdict: CONFIRMED, and the map's `M` rating is OVERSTATED caution — the *interface* polarity is
`H`.** The Rust is inverted and can be fixed now, without the live session §10.1 demands.

The map's §6.4 chain is sound as far as it goes: `AddObject`'s omitted-argument default is 0;
`UsePlayers(true)` passes 0; the shipped parameter is literally named `bExclude`;
`RemoveTarget` passes `true`. I reproduced every step (§A.6). But the map then rates it **M** because
"the inversion happens inside the encrypted setter `0x024F3060` … that single step is what keeps this
row at M", and §11 tells the reader to "**gate on §10.1 before flipping it**".

**That gate is unnecessary, and it is the map's most costly error** — it blocks a correct one-line
fix behind a debugger errand. Three points:

1. **The map's own evidence is already sufficient.** `_ProcessTargets(tConfig.vTgtInclude, false)`
   and `_ProcessTargets(tConfig.vTgtExclude, true)` at `mrxtaskobjective.lua:50-51` bind the
   *include* list to `false` and the *exclude* list to `true`. That is the interface contract,
   verbatim, in shipped content. Nothing inside the setter can change what the Lua argument *means*.
2. **There is a fourth witness inside the exe that the map never found.** `FUN_005F79F0` — the
   generic "coerce a Lua value where a filter is expected" helper used by the event layer — is plain
   `.text` and calls the *same* primitive:
   ```
   Lua tag 2 (a bare GUID):    thunk_FUN_024F3060(guid,       0)
   Lua tag 4, s == "players":  thunk_FUN_024F3060(0xF0000000, 0)
   Lua tag 4, otherwise:       thunk_FUN_032D0000(s)            // == SetFilter
   ```
   Handing `Event.ObjectProximity` a bare object GUID must mean *"match this object"*. It emits
   flag **0**. Under a `bInclude` reading, flag 0 would mean "exclude it", and the coercion would
   produce a filter that matches nothing — the engine's own convenience path would be broken.
   This witness does **not** depend on the `0xF0000000` sentinel, so it closes the one hole in the
   map's `UsePlayers` argument (the sentinel is force-true, so `UsePlayers`' `0` alone proves less
   than the map claims).
3. **What is genuinely `M` is narrower than the map says.** The *storage* convention — that `+0x04`
   holds `include = !bExclude` — is the inferred part, and it is inferred from a solid base:
   `FUN_005F87F0` returns `((+0x04 >> i) & 1) != 0` **as the match verdict**, so bit set = match =
   include, while the Lua flag is `bExclude`; therefore the setter inverts. That is an inference
   about an *implementation detail nobody needs*. The fix to our Rust depends only on the interface.

**Fix, stated precisely.** `tools/wad_simulator/crates/mercs2_script/src/bindings/object_filter.rs:64-67`
should read `exclude.unwrap_or(false)` and `mercs2_core::ObjectFilter::add`'s parameter should be
renamed `exclude` (or the call site should pass `!exclude`). The map's framing — "the default
therefore coincidentally agrees" — is correct and worth keeping: with the flag omitted, retail's `0`
and the Rust's `true` both mean *include*. But **every shipped call site passes the argument
explicitly** (7 `AddObject` calls: 4 with `false`, 3 with `true`), so the default never fires and the
inversion is **total**, not partial.

**If you still want the last 1%:** break once on `0x005F6EF0`, run
`ObjectFilter.AddObject(f, g, true)` on a fresh filter, and read `[filter+0x04]`. Bit 0 **clear**
confirms `bExclude`. That is the map's §10.1 recipe and it is a good one — it just is not a
prerequisite for the fix.

### B.4 The `(A||B)&&C` associativity trap — CONFIRMED, and it deserves H

The map rates §4.4 **M** ("derived by reading the compiler and the evaluator together and
hand-executing them, not by running the game") and §10.2 proposes an in-game discriminator. Both the
compiler (`FUN_005F8B00`, plain `.text`) and the evaluator (`FUN_005F8E50`, plain `.text`) are fully
readable, so hand-execution here is *proof*, not inference. I reproduced it independently:

```
source:   A && B || C
pass 1:   emits every depth-0 operator, left to right   →  [ &&, || ]
pass 2:   recurse on left operand of &&  → A            →  [ &&, ||, A ]
          begin := "B || C"; recurse on left of ||  → B →  [ &&, ||, A, B ]
          begin := "C"; loop; opCount==0 → leaf    → C   →  [ &&, ||, A, B, C ]
eval:     tok[0]=&&  → LEFT = eval([||,A,B,C]) = (A||B), consumed 3
                     → RIGHT = eval(tok+3+1) = C
          result = (A || B) && C
```
Every step is a direct read. **§4.4 is `H`.** The map's §10.2 discriminating case ("label `C` only:
standard predicts `true`, this map predicts `false`") is also correct — though its first sentence
garbles the `A`-only case before reaching the right conclusion.

The map is likewise right that **no shipped expression exercises it**: my independent census of all
11 `SetFilter` call sites plus every `sTgtLabelFilter` literal found exactly one mixed-operator
expression, `friendlygate.lua:59`'s `"Hero||(" .. sFaction .. "&&Vehicle)"`, and it parenthesises.

### B.5 MISSING — 5 material omissions

**M1 — `!` applied to a parenthesised group is silently broken. (New; neither the map nor my Phase A had it.)**
Pass 1 only counts operators at **paren depth 0**, so for `"!(A&&B)"` the `&&` sits at depth 1 and
`opCount == 0`. The loop breaks straight to the leaf path, which emits `NOT` and then **hashes the
remaining text verbatim**:
```
"!(A&&B)"  →  [ NOT, pandemic_hash_m2("(A&&B)") ]
```
No object carries a label named `(A&&B)`, so the leaf always misses, and `NOT` turns that into
**`true` unconditionally**. `!(A)` breaks the same way. `!` works correctly *only* immediately before
a label (`"!Hero && China"` → `[&&, NOT, Hero, China]`, which evaluates correctly). Zero shipped
expressions contain `!`, so this is latent — but it is a sharper trap than the associativity one,
because it fails *silently and always-true* rather than merely parsing oddly. A reimpl that
implements `unary := "!" unary | "(" expr ")"` (as our Rust does) will be **more correct than
retail** here, which is its own kind of divergence.

**M2 — the `negate`-inheritance concern is unreachable, and the map leaves it ambiguous.**
Map §4.3 notes `negate` is threaded down *and* re-applied at the node, and §11.7 says the reimpl and
retail "can disagree on `!(A&&B)`". I independently found the same double-application and initially
recorded it as a live defect (Phase A §A.8). **On reading the compiler, it is dead code**: pass 1
emits *all* of a level's operators before pass 2 can emit any `NOT`, so a `NOT` token can never be
the token immediately preceding an operator at the same node — the flag is always consumed inside a
leaf child. Retracting my own Phase A claim, and sharpening the map's: they cannot disagree by
double-negation. They disagree by **M1**.

**M3 — `FUN_005F79F0`, the Lua-value→filter coercion, is absent from the map entirely.**
It is the strongest polarity witness (B.3), it answers §10.5 (C2 above), it partially answers §10.6
(the `+0x22 |= 0xC0` constant-override is set from a Lua **number** argument), and it documents a
Lua-visible feature nothing else records: **the string `"players"`** (`0x00BBB734`, matched with
`_strnicmp(s,"players",7)`) is accepted anywhere a filter is expected and is equivalent to
`UsePlayers(f,true)`.

**M4 — the two argument defaults are opposite and the map never contrasts them.**
§6.4 correctly says `AddObject`'s flag defaults to **0**; §6.2 correctly says `UsePlayers`' flag
defaults to **on**. A reimplementer reading §6.4 alone will naturally make `UsePlayers` default
false. Worth one sentence. (Our Rust already has `on.unwrap_or(true)` for `UsePlayers`, which is
**correct** — the map's §11 divergence list does not say so, and someone "fixing" it for consistency
with item 1 would break it.)

**M5 — §11 fixes the binding but not the core.** §11 item 1 names
`include.unwrap_or(true)` in `mercs2_script/src/bindings/object_filter.rs:67`. The same inversion is
baked into `mercs2_core::ObjectFilter::add(&mut self, guid, include: bool)` and its doc comment
(`object_filter.rs:42-53`) and into three unit tests (`:306-315`). Flipping only the binding line
leaves the core API named backwards.

### B.6 OVERSTATED — 6

| # | Map | Why |
|---|---|---|
| O1 | §6.4 rated **M**; §11 says "gate on §10.1 before flipping it" | the *interface* polarity is `H` (B.3). Only the storage inversion is `M`, and no fix depends on it. This gate is the map's most expensive claim. |
| O2 | §4.4 rated **M** | both the compiler and the evaluator are readable `.text`; hand-execution is proof (B.4). Should be `H`. |
| O3 | §11 "✅ **`AddObject` moves a GUID between the two sets** rather than duplicating — behaviourally equivalent to the exe's newest-first backward scan" | the setter is encrypted. The map's own §10.1(b) lists "whether `AddObject` de-duplicates" as an **open question**. Listing it as a confirmed match in §11 contradicts §10.1. The backward scan in `FUN_005F87F0` is a *read* path and says nothing about the *write* path. |
| O4 | §4.1 "the compiler is uniform: **every** token — operator or label — is emitted as `pandemic_hash_m2(<literal text>)`" | inferred from three operator constants. The emitter (`0x005F8A50 → 0x024F3000`) is encrypted and was not read. Almost certainly true; not shown. |
| O5 | §0.5 rates the occupant-expansion / `FUN_005F3110` row **M** | the `this+0x20` filter pointer and the `&= 0xC3` latch clear are directly readable (`005F311F/005F3122`), and the `{2,3,4,10}` + `0x00DF8188` shape is verbatim in three bodies. That row is `H`; only "which spatial query is it" is open. |
| O6 | §4.5 "the **seat-pool** critical section `DAT_00EDBAA4`" | that lock guards the **label container** (`0x00DF8108`) walk, not the seat pool (`0x00DF8188`). Cross-wired label from §7. |

### B.7 UNVERIFIABLE — and exactly what would settle each

| # | Claim | Why unverifiable statically | What settles it |
|---|---|---|---|
| U1 | the six reachable primitives' bodies (`0x024E6450` alloc, `0x024F3060` add, `0x024F3030` remove, `0x024E6430` iterate, `0x024EA230` set-assoc, `0x024F3000` emit-token, `0x024F3080` hash-one) | all reduce to `0x01AAFF10 = jmp [0x21FD554]`, a slot fixed only at runtime. Two obfuscation shapes (`push/call`, and `push/push/pushfd/sub/popfd/ret` arithmetic) — both land there | one paused live dump; the map's §10.1 recipe is correct |
| U2 | the metatable identity / registry key for the filter userdata | inside `0x024E6450` | dump the pushed userdata's metatable after `Create` |
| U3 | `AddObject` de-duplication and 31-object overflow behaviour | inside `0x024F3060` | read `[f+0x00..0x04]` and `[f+0x1E]` across repeated adds |
| U4 | `FUN_005880D0` is a **distance** (map §3.4, correctly hedged) | 402 B walking `PTR_PTR_00DF7F08`; I did not read it | break with two known positions, compare XMM0 |
| U5 | `SetAssociation`'s argument roles (map §3.3, rated M) | `+0x20` is never written in visible `.text`; the write is inside `0x024EA230`. **Zero shipped call sites**, so no corroboration exists either | break `0x005F7390`, read `[f+0x0C]` and `[f+0x20]` |
| U6 | the exact `bExclude → +0x04` inversion site | inside `0x024F3060` | see B.3; not a prerequisite for anything |
| U7 | whether **M1** (`!(…)`) and **§4.4** actually misbehave in a running game | both are compiler-path claims verified by reading, not running | the map's §10.2 two-`SetFilter` test, plus one for `"!(A&&B)"` |

Everything in this validation is **static**. No x32dbg session, no live memory read, no running game.

### B.8 Summary count

| Verdict | Count |
|---|--:|
| **CONFIRMED** | **51** |
| CONTRADICTED | 4 |
| OVERSTATED | 6 |
| MISSING | 5 |
| UNVERIFIABLE (correctly flagged open by the map: U1–U5) | 5 |
| UNVERIFIABLE (newly identified here: U6–U7) | 2 |
| **Falsifiable claims examined** | **62** |
| *of which the map corrected me* | 2 |

**Where I could not check the map at all:** the four sibling-map boundary claims in the header table
(the label store's `AddLabel`/`HasLabel` addresses, the player map's `0x00DF9B90`, the event bus, the
`Ai.SetRelation` false friend) — I did not open those maps, and cross-map consistency was out of
scope. I also did not read `FUN_005880D0`, `FUN_005F3110` beyond its prologue, or the `0x005F6C00` /
`0x005F8330` / `0x005F8350` / `0x005F9210` thunks. And nothing here was confirmed at runtime, so
every "proven" verdict is *proven-static*: it establishes what the shipped bytes say, not what the
running game does.

### B.9 Recommended actions

1. **Flip the polarity now.** `exclude.unwrap_or(false)` in the binding; rename
   `mercs2_core::ObjectFilter::add`'s parameter and fix its doc comment and the three tests
   (M5). Do **not** wait for §10.1 (B.3/O1).
2. **Fix `GetObjects`' second argument** at the same time (map §11 item 2) — the two changes are
   coupled: with the polarity flipped, `GetObjects(f,false)` becomes correct for free, exactly as the
   map predicts.
3. **Amend the map**: correct the 7-vs-9 recovery count (C1), close `+0x18`/`+0x1C` and §10.5 from
   `FUN_005F79F0` (C2/M3), raise the SecuROM stub count to 13 and name the emit-token and
   single-label-hash primitives (C3), promote §4.4 and §6.4-interface to `H` (O1/O2), demote the
   `AddObject` de-dup ✅ (O3), and add the `!(…)` compiler trap (M1) plus the retraction of the
   double-negation concern (M2).
4. **`mrxtaskjob.lua:349`** — I agree with the map that it is suspicious, and I can now say more
   precisely what is wrong: `GetObjects(f,false)` genuinely returns the *included* set, so the local
   named `tExcludedObjects` and the `bExcluded` test are **misnamed**, and the unconditional
   `AddObject(f, uGuid, false)` at `:361` makes the entire `if/else` at `:356-360` **dead code** —
   both branches end with the GUID included. Net runtime behaviour is the apparent intent, so this is
   a **naming + dead-code defect, not a behavioural bug**. Worth a `bug_register.md` note at low
   priority; it does not need §10.1 either.

---

# Pass 2 — second-pass verification

- **Date:** 2026-07-26
- **Mandate:** close every item Pass 1 did not explicitly CONFIRM. Pass 1's verdicts were treated as
  untrusted claims and re-derived.
- **Headline:** **all seven "unverifiable" items U1–U7 are now closed except U7's runtime leg**, and
  the `bExclude` inversion site is **PROVEN as machine code**, not inferred. Pass 1's central premise —
  that the seven primitives "all reduce to `0x01AAFF10 = jmp [0x21FD554]`, a slot fixed only at
  runtime" — was **half right and wholly unproductive**: the slot *is* resolved in the dump, the
  bodies genuinely are virtualized, **and a plain, un-obfuscated PowerPC twin of every one of them
  exists in an artifact already in this repo.**

## P0. Open register (the checklist this pass had to close)

| # | Pass-1 item | Class |
|--:|---|---|
| 1 | C1 — "7 of 9 recovered" vs the table's 9 ◒ | CONTRADICTED |
| 2 | C2 — `+0x18`/`+0x1C` are not open questions | CONTRADICTED |
| 3 | C3 — SecuROM inventory is 13, not 7 | CONTRADICTED |
| 4 | C4 — `flags &= 0x82` cannot preserve bit 1 | CONTRADICTED |
| 5 | O1 — §6.4 rated M; §11 gates the fix on §10.1 | OVERSTATED |
| 6 | O2 — §4.4 associativity rated M | OVERSTATED |
| 7 | O3 — §11 "✅ AddObject moves rather than duplicates" vs §10.1(b) "open" | OVERSTATED |
| 8 | O4 — §4.1 "**every** token is `pandemic_hash_m2(text)`" | OVERSTATED |
| 9 | O5 — §0.5 `FUN_005F3110` row rated M | OVERSTATED |
| 10 | O6 — `DAT_00EDBAA4` called the "seat-pool" critical section | OVERSTATED |
| 11 | M1 — `!(…)` compiles to a garbage label → unconditional true | MISSING |
| 12 | M2 — the negate-inheritance defect is unreachable | MISSING |
| 13 | M3 — `FUN_005F79F0` absent from the map | MISSING |
| 14 | M4 — `AddObject` and `UsePlayers` have **opposite** defaults | MISSING |
| 15 | M5 — §11 fixes the binding but not `mercs2_core` | MISSING |
| 16 | **U1** — the seven primitives' bodies | UNVERIFIABLE |
| 17 | **U2** — metatable identity / registry key | UNVERIFIABLE |
| 18 | **U3** — `AddObject` dedup + 31-object overflow | UNVERIFIABLE |
| 19 | **U4** — is `FUN_005880D0` a distance? | UNVERIFIABLE |
| 20 | **U5** — `SetAssociation`'s argument roles | UNVERIFIABLE |
| 21 | **U6** — the `bExclude → +0x04` inversion site | UNVERIFIABLE |
| 22 | **U7** — do M1 / §4.4 actually misbehave? | UNVERIFIABLE |
| 23 | boundary claim — label store `AddLabel`/`RemoveLabel`/`HasLabel` | NOT CHECKED |
| 24 | boundary claim — player container `0x00DF9B90` | NOT CHECKED |
| 25 | boundary claim — the event bus | NOT CHECKED |
| 26 | boundary claim — `Ai.SetRelation` is a "false friend" | NOT CHECKED |
| 27 | `FUN_005F3110` beyond its prologue | NOT CHECKED |
| 28 | thunks `0x005F6C00` / `0x005F8330` / `0x005F8350` / `0x005F9210` | NOT CHECKED |

## P1. The SecuROM deref — what is actually behind `0x01AAFF10`

Done first, as instructed, before anything was written as STILL-OPEN.

`mercs2_unpacked.exe` is a flat memory dump, `file_off == VA − 0x400000` (PE section table parsed:
`.text` VA `0x00401000`, `Stext` VA `0x01A49000`, `.securom` VA `0x023E9000`, size `0x13175F8`).

**Every slot is resolved in the dump.** Read directly out of the image:

```
[0x021FD554] = 0x02A30000        [0x0245E1D8] = 0x031C0000   (the brief's worked example — confirmed)
[0x0245EF98] = 0x024F3060 add    [0x0245F0C8] = 0x024F3030 remove
[0x02458BE8] = 0x024E6430 iter   [0x02458E4C] = 0x024E6450 alloc
[0x02459F60] = 0x024EA230 assoc  [0x024586A4] = 0x024F3000 emit-token
[0x0245F448] = 0x024F3080 hash1  [0x0245E474] = 0x032D0000 SetFilter core
```

`0x01AAFF10` = `jmp [0x21FD554]` → **`0x02A30000`**, which disassembles cleanly:

```
0x02a30000  eb26           jmp 0x2a30028          ; over an inline taunt string
            "You Are Now Entering a Restricted Area"
0x02a30028  60             pushal
0x02a30029  9c             pushfd
0x02a3002a  e8 00000000    call $+5
0x02a3002f  e8 02000000    call $+7
0x02a30036  5a             pop edx
0x02a30037  f0 fe0a        lock dec byte ptr [edx]   ; spinlock acquire
0x02a3003a  79 30          jns  ...
0x02a3003c  803a00 / f390 / 7ef9 / ebf2              ; pause-loop
            "[ Masses Against the Classes"
```

That is a **generic, spinlock-guarded SecuROM VM entry**, not a per-function body. The seven targets
are `0x20`/`0x30`-spaced *descriptor stubs* in a stub band:

```
0x024e6450  push 0x24e645a ; call 0x1aaff10 ; <desc: 024D5CF6, 5E35, 0FD0, 7B7E>
0x024f3060  push 0x24f306a ; call 0x1aaff10 ; <desc: 024D5DCE, 26EC, 543E, 41F2>
0x024f3030  push 0x24f304a ; push 0x402dc2 ; push 0x1ac0a2c ; pushfd
            sub [esp+4],0x10b1c ; popfd ; ret          (0x1ac0a2c-0x10b1c == 0x1AAFF10)
0x024f3000  … push 0x40179f … sub 0x305c …            0x024f3080 … push 0x405cff … sub 0x308 …
```

Every descriptor's first dword points into `0x024D5C00–0x024D6100`, whose bytes are high-entropy
ciphertext (`1f5fb247e18bbbfa5b6870cdae159428…`). Census over the whole `.securom` section:
**1144 shape-1 stubs and 1034 shape-2 stubs.** The shape-2 middle push is a **decoy**: 1021 distinct
values, all inside a 32 KB window of `.text` (`0x400000–0x408000`), landing mid-instruction or on
`int3` padding — it is not a jump target. This matches this project's own double-blind verdict in
`docs/securom_unwrap_devirtualization.md`: *"the build runs fully virtualized and never restores
stolen bytes in place… Recovery would need a runtime oracle."*

**So: the slots are resolved, and the bodies are still not there.** Pass 1's *conclusion* was right;
its *reason* ("a slot fixed only at runtime") was wrong. But this is not where the enquiry ends —
see P2. Note also the structural finding neither pass had: **`.securom` holds two distinct
populations** — a *plain relocated-code* band (`0x031C0000`, `0x032D0000`, `0x034D0000` are ordinary
x86 at rest) and this *VM-stub* band around `0x024Exxxx–0x024Fxxxx`.

## P2. The oracle Pass 1 missed — `output/jul08_prototype/`

`output/jul08_prototype/mercs2_xenon_p.pe_full.bin` is an Xbox 360 build with **no SecuROM at all**,
and it contains the complete `ObjectFilter` namespace *including all seven primitives, in plain
PowerPC*.

- Mapping: `file_off == VA − 0x82000000` (VA-flat; the section-raw reading yields mid-function
  garbage — this cost one wrong turn and is recorded so the next reader doesn't repeat it).
- Binding table found at raw `0x2E288`, preceded by the C string `"ObjectFilter"` at `0x2E274`:
  **16 entries, same names, same order, `_GC` last in the table and lowest in address** — exactly the
  PC shape.

| # | name | Xbox cfunc | PC cfunc |
|--:|---|---|---|
| 0 | `Create` | `0x8247C790` | `0x005F6CF0` |
| 2 | `SetFilter` | `0x8247C848` | `0x005F6D70` |
| 4 | `AddObject` | `0x8247C9B0` | `0x005F6EF0` |
| 5 | `RemoveObject` | `0x8247CAB0` | `0x005F7020` |
| 6 | `GetObjects` | `0x8247CB78` | `0x005F7130` |
| 8 | `UsePlayers` | `0x8247CD88` | `0x005F72E0` |
| 9 | `SetAssociation` | `0x8247CE68` | `0x005F7390` |
| 13 | `Eval` | `0x8247D1C8` | `0x005F76E0` |
| 15 | `_GC` | `0x8247C718` | `0x005F6C90` |

**The seven encrypted PC primitives, named:**

| role | PC (encrypted) | Xbox (plain PPC) |
|---|---|---|
| allocator / userdata push | `0x024E6450` | **`0x8247E5C0`** |
| add-object | `0x024F3060` | **`0x8247D4C0`** |
| remove-object | `0x024F3030` | **`0x8247D698`** |
| object-set iterator | `0x024E6430` | **`0x8247D7E0`** |
| set-association | `0x024EA230` | **`0x8247E888`** |
| emit-token | `0x024F3000` | **`0x8247E900`** |
| hash-one-label | `0x024F3080` | **`0x8247E538`** |

### P2.1 Why the correspondence is trustworthy

The prototype is a *different build* (July 2008 vs. the shipped PC), so everything derived from it is
stated as **cross-build proven**, not PC-proven. Twelve independent structural agreements make the
correspondence a join, not a guess:

1. same 16 cfuncs, same order, `_GC` lowest;
2. `Create` allocates **exactly `0x24` bytes** (`li r4, 0x24`) — the map's "~`0x24`-byte struct";
3. object array at `+0x00`, include mask at `+0x04`, token array at `+0x08`, assoc value `+0x0C`,
   assoc op `+0x20`, flags `+0x22` — identical offsets;
4. `+0x1E` / `+0x1F` are one-byte count/capacity bitfields in both;
5. `+0x18` = Lua registry ref, `+0x1C` = `u16` refcount, in both;
6. every cfunc opens "fetch filter → on failure push `nil`, return 1";
7. `AddObject`'s third arg defaults to **0** when absent, in both;
8. `UsePlayers`' arg defaults to **on** when absent, in both;
9. `GetObjects` uses the same three-way `{absent, false, true}` selector;
10. `SetFilter` takes the same fast path (no `& ! | ( )` in the string → inline single hash);
11. the operator byte encoding `op[0] | (op[1]=='=' ? 0x80 : 0)` is byte-identical;
12. **the bitfields are exact mirror images** — PPC reads count as `+0x1E >> 3` (high 5 bits) and
    capacity as `(b & 7) * 8`; x86 reads count as `+0x1E & 0x1F` (low 5) and capacity as `b >> 5`.
    That is precisely what MSVC does with `unsigned char count:5; unsigned char cap:3;` on a
    big-endian vs. little-endian target. **The same C source compiled twice.** This is the strongest
    single item: it independently *validates* the map's PC bit-split reading rather than assuming it.

## P3. Verdicts on U1–U7

### U1 — the seven primitives' bodies → **CLOSED** (cross-build proven)

Static evidence on the PC image is exhausted (P1). All seven read in plain PPC (P2). What they do:

**`0x024F3060` / `0x8247D4C0` — add-object `(filter, guid, bExcludeByte)`**

```
if (flags & inline_object) {                            // one GUID stored in +0x00
    if (inlineGuid == guid) { idx = 0; goto SET_BIT; }   // DEDUP
} else {
    for (i = 0; i < count; i++)
        if (array[i] == guid) { idx = i; goto SET_BIT; } // DEDUP
}
if (count >= capClass*8) {                              // GROW
    capClass++;  buf = alloc(capClass*8*4);
    copy old (inline word or array);  free old;  +0x00 = buf;  clear inline flag;
}
array[count] = guid;                                    // APPEND
SET_BIT:
    mask = (flag != 0) ? (mask & ~(1<<idx))             // andc  -> EXCLUDE
                       : (mask |  (1<<idx));            // or    -> INCLUDE
    count++;  return 1;
```

**`0x024F3030` / `0x8247D698` — remove-object `(filter, guid)`**: linear scan; on hit, `count--`,
then **swap-with-last** (`array[i] = array[count]`, and copy bit `count` of the mask onto bit `i`);
if the hit *was* the last element, just null it. **Removal is an unordered swap-remove** — it
re-orders the set. No error on miss. (The immediately following routine, `0x8247D7A8`, is the
`ClearObjects` primitive: mask = 0, count = 0 keeping capacity, clear the inline flag.)

**`0x024E6430` / `0x8247D7E0` — iterator `(filter, index, out flagByte)`** → returns the GUID at
`index` or 0. Two behaviours the map does not have:

- `*out = ((mask >> index) & 1) ? 0 : 1` — computed with `cntlzw`/shift at `0x8247D920`, i.e. **the
  out-flag is the logical negation of the include bit: it is `bExclude`.**
- If the set contains a player sentinel, indices `>= count` **enumerate the live players** and yield
  each player's attached character GUID (`playerCount()`, `getPlayer(i)`, `+0x24 != -1`, return
  `+0x14`), with the out-flag forced to **0 (included)**. **`GetObjects` therefore expands
  `UsePlayers` into real character GUIDs.**

**`0x024E6450` / `0x8247E5C0` — allocator**: `lua_newuserdata(L, 0x24)`, zero `+0x00`/`+0x08`,
construct, then set the metatable from **`LUA_GLOBALSINDEX` (`li r4, -0x2712` = −10002)** with the
key string `"_OFMETATABLE"`, and return the raw struct pointer. See U2.

**`0x024EA230` / `0x8247E888` — set-association `(filter, opString, value)`**: fails (returns 0) if
the string is null/empty; otherwise `+0x0C = convert(value)`, `+0x20 = op[0]`, and
`if (op[1] == '=') +0x20 |= 0x80`. See U5.

**`0x024F3000` / `0x8247E900` — emit-token `(filter, char* text, int len)`**: calls the **same
hash-one routine** on `text[0..len)`, then grow-if-needed and `tokens[count] = hash; count++`, on
`+0x1F`/`+0x08` with identical bitfield arithmetic. See O4.

**`0x024F3080` / `0x8247E538` — hash-one `(char* begin, char* end)`**: trim both ends, clamp to 255
bytes, copy to a stack buffer, NUL-terminate, hash. The hash function is recovered verbatim:

```
h = 0x811C9DC5;  for (ch : s) h = ((ch | 0x20) ^ h) * 0x01000193;
return (h ^ 0x2A) * 0x01000193;                    // == pandemic_hash_m2
```

Reproduced: `"&&"`→`0x2817EA45`, `"||"`→`0x49FE8F3D`, `"!"`→`0x85C32EB2`, `"human"`/`"Human"`/
`"HUMAN"`→`0xAD431BF0`. The `| 0x20` fold is in the machine code, so **case-insensitivity is now read
off the engine, not inferred from a tool.**

### U2 — metatable identity → **CLOSED, and both passes had the wrong shape**

It is **not a registry key**. It is a **Lua global**. Two independent witnesses:

1. Xbox `Create` sets the metatable from `LUA_GLOBALSINDEX` with key `"_OFMETATABLE"`.
2. The PC **namespace registry** at `0x00DFD478` — **31 rows × 12 bytes**, terminator `0x00DFD5EC`,
   exactly as the master key states — has rows of the form
   `{const char* name; luaL_Reg* funcs; const char* postRegisterLuaChunk;}`. The ObjectFilter row is
   at **`0x00DFD52C`**:

   ```
   word0 = 0x00BBB714 -> "ObjectFilter"
   word1 = 0x00B98770 -> the 16-entry luaL_Reg table
   word2 = 0x00BBB6D0 -> "_OFMETATABLE = { __gc = ObjectFilter._GC, __index = ObjectFilter }"
   ```

   The registrar runs that chunk after registering the namespace. **`__index = ObjectFilter` means a
   filter handle is method-callable (`f:Eval(g)`), which nothing in the map records.**

> **Pass-1 correction.** §A.1 said the row's "third word is `0x00B98770` and… fourth word is
> `0x00BBB6D0` → the C string `"ObjectFilter"`". Rows are **12 bytes (3 words)**, not 16, and
> `0x00BBB6D0` is the metatable bootstrap chunk, not the name. The name is word **0** (`0x00BBB714`).
> Ten of the 31 namespaces ship such a chunk (`_SYS`, `Sys`, `Pg`, `Debug`, `Gui`, `_GuiInternal`,
> `ObjectFilter`, `math`, `VO`, …).

### U3 — `AddObject` dedup and 31-object overflow → **CLOSED**

- **Dedup: YES.** Both the inline and array paths scan for an equal GUID and, on a hit, jump straight
  to the bit update — no append, no count increment. `AddObject(f, g, true)` after
  `AddObject(f, g, false)` **flips the existing entry's bit in place.** (This retroactively makes the
  map's §11 "✅ moves rather than duplicates" *correct* — see O3.)
- **Overflow: silent corruption, no guard.** The count is a 5-bit field incremented by
  `(b & 0xF8) + 8` (PPC) / its x86 mirror. At count 31 the add carries out of the byte and the store
  truncates: **the count wraps to 0**, keeping the capacity class. The 32nd *distinct* object makes
  the set look empty and subsequent adds overwrite from index 0. There is no bounds check anywhere
  on the path.
- **The same 5-bit wrap applies to the token array** via `+0x1F` in emit-token. **A label expression
  compiling to more than 31 tokens silently truncates to zero.** Neither the map nor Pass 1 states a
  token cap at all.

### U4 — `FUN_005880D0` → **CLOSED. It is NOT a distance.**

Applying the master key (`[[container]] + 0x34` → `mov eax,<char*>; ret`) to every bare container in
this map:

| global | name |
|---|---|
| `0x00DF8108` | **`Label`** |
| `0x00DF8188` | **`SeatLink`** |
| `0x00DF7F88` | **`Association`** |
| `0x00DF7F08` | **`Relationship`** |
| `0x00DF9B90` | `Players` |
| `0x00DF9B10` | `CheatInfiniteAmmo` (control) |
| `0x017BEF78` | `RuntimeHealth` (control) |

`FUN_005880D0` walks **`Relationship`**. It is a memoized (two FNV-keyed caches, `0x200`- and
`0x800`-entry) read of the per-object-pair relationship scalar. And the identity is exact:

```
Ai.GetRelation    FUN_005AACE0:  FUN_0059FF50(&a); FUN_0059FF50(&b);
                                 FUN_005880D0(a, b);  push XMM0 as a Lua number (tag 3)
Ai.SetRelation    FUN_005AADD0:  ... FUN_00588270(...)        -> FUN_00649180(&PTR_PTR_00DF7F08, …)
Ai.ChangeRelation FUN_005AAEF0:  FUN_005880D0(a,b); FUN_00588270(a, b, old + delta)
```

**`ObjectFilter.SetRelation(f, uOther, sOp, nValue)` compares exactly the number
`Ai.GetRelation(candidate, uOther)` returns.** So the relation channel is a *relationship/reputation*
predicate, and `SetRelation(f, uHero, "<", 50)` reads as *"objects whose relation toward the hero is
< 50"*, **not** "within 50 m". The map's §3.4 inference toward distance is wrong, and its §10.4
confirm-live is unnecessary.

### U5 — `SetAssociation`'s argument roles → **CLOSED**

`SetAssociation(f, sOperator, value)`. Xbox `0x8247CE68` fetches arg2 with the **string** getter (the
same one `SetFilter` uses for its expression) and arg3 with a different getter, then calls
`0x8247E888(filter, str, value)`, which stores `+0x0C = convert(value)`, `+0x20 = str[0]`, and ORs
`0x80` when `str[1] == '='` — the **identical** encoding to `SetRelation`. **Arg 2 is the operator.**
The cfunc pushes the primitive's return as a **boolean**, so `SetAssociation` returns `false` when
the operator string is empty. The map's §3.3 "which of the two string arguments is the operator" is
answered: the first one, and arg 3 is not a string.

At `Eval` time the candidate's association is fetched by `thunk_FUN_034D0000`, which is also the body
of the engine-wide accessor `FUN_00588350` (30 bytes, 12+ callers) — i.e. the filter reads the
`Association` component through the same getter as everything else.

### U6 — the `bExclude → +0x04` inversion site → **PROVEN**

`0x8247D5AC`, inside the add primitive:

```asm
clrlwi  r10, r28, 0x18      ; r10 = (u8)flag              <-- the Lua bExclude byte
lwz     r9,  4(r31)         ; r9  = filter->includeMask       (+0x04)
cmplwi  cr6, r10, 0         ; flag == 0 ?
li      r10, 1
slw     r8,  r10, r11       ; r8 = 1 << slotIndex
andc    r7,  r9, r8         ; r7 = mask & ~bit            <-- flag != 0  => CLEAR  (exclude)
bne     cr6, +8             ; if flag != 0 keep the andc
or      r7,  r8, r9         ; r7 = mask |  bit            <-- flag == 0  => SET    (include)
stw     r7,  4(r31)
```

The same `andc`/`or` pair appears again in the append path at `0x8247D664`. **This is the inversion,
in one instruction pair.** The chain is now closed end-to-end with no inferred link:

```
Lua arg 3 = bExclude
   -> primitive: flag==0 ? SET : CLEAR  bit[i] of +0x04
   -> +0x04 bit set == "matches"   (FUN_005F87F0 returns it verbatim as the verdict)
   -> iterator out-flag = !bit      (cntlzw negation, 0x8247D920)
   -> GetObjects(f, X) emits where out-flag == X
   => GetObjects(f,false) returns the INCLUDED objects.
```

**O1 stands and is hardened: §6.4 is `H`, and the §11 "gate on §10.1 before flipping it" instruction
should be deleted outright — there is nothing left to gate on.**

### U7 — do M1 / §4.4 actually misbehave? → **static leg CLOSED; runtime leg STILL-OPEN**

The label-expression **compiler is plain code in both builds** (PC `FUN_005F8B00`, reached via
`0x032D0000`; Xbox `0x8247E9C8`, reached via `0x8247EC10`), and the Xbox one was read instruction by
instruction. It is structurally identical to the map's §4.2 five-step description, and it settles
both questions **by reading, not by hand-execution**:

- **Pass 1** scans `[begin,end)` tracking paren depth and, at depth 0 only, emits every `&&`/`||`
  via `emit(filter, ptr, 2)` — *all of a level's operators before any operand*. **§4.4's
  `A && B || C` → `[&&, ||, A, B, C]` → `(A||B) && C` is confirmed at the source of truth. `H`.**
- **Leaf path** (`opCount == 0`, Xbox `0x8247EBCC`):

  ```
  if (*begin == '!') { emit(begin, 1); begin = trimleft(begin + 1); }
  emit(begin, end - begin);          // hashes ALL remaining text as ONE label
  ```

  For `"!(A&&B)"` the `&&` sits at depth 1, so `opCount == 0`, so the leaf path runs and emits
  `[NOT, pandemic_hash_m2("(A&&B)")]` = `[0x85C32EB2, 0xFBD46457]`. No object carries a label
  `"(A&&B)"`, so the leaf always misses and `NOT` turns it **unconditionally true**. **M1 is
  CONFIRMED against the real compiler**, and the trap token now has a name and a value.
- **M2 confirmed**: pass 1 emits all operators before pass 2 can emit any `NOT`, so a `NOT` token can
  never immediately precede an operator at the same node — the double-negation concern is dead code.

What remains genuinely open is only *"and the running game does this too"*. **Recipe** (no debugger
needed, two lines of mission Lua): label an object `"C"` only, then
`ObjectFilter.SetFilter(f,"A&&B||C"); print(ObjectFilter.Eval(f,g))` — standard precedence predicts
`true`, this map predicts `false`; and `SetFilter(f,"!(A&&B)"); Eval(f,g)` on **any** object must
print `true`.

## P4. Verdicts on the four CONTRADICTED items

| # | Verdict |
|---|---|
| **C1** | **CONFIRMED.** The map's §1 table marks all nine bodiless cfuncs `◒` and carries no `○` row; the prose and legend say "7 of 9" / "2 still opaque". The two opaque things are `AddObject`/`RemoveObject`'s *setters*, which are not cfuncs. The legend conflates two populations. |
| **C2** | **CONFIRMED, and now doubly.** PC `FUN_005F79F0` reads `+0x18 == -2`, writes `FUN_0085FD50(0xFFFFD8F0)` (`luaL_ref(L, LUA_REGISTRYINDEX)`) into it, and does `*(short*)(p+0x1C) += 1`. Independently, Xbox `0x8247E638` is the matching **release**: decrement the `u16` at `+0x1C`, and on reaching zero call the unref helper with `filter+0x18`. So `+0x18` = registry anchor (`-2` = `LUA_NOREF`), `+0x1C` = `u16` refcount. §10.5 needs no watchpoint. Corollary confirmed by reading `FUN_005F8170`: it copies neither field, so a `Copy` is unanchored with refcount 0. |
| **C3** | **CONFIRMED exactly.** A fresh `FF 25` byte-scan over `0x005F6C00–0x005F9300` returns **13** stubs, matching Pass 1's table address-for-address and target-for-target. The map says 7. |
| **C4** | **CONFIRMED.** Disassembled: `0x005F82D6 and byte [edi+0x22], 0xFD` (unconditional — both predecessors reach it) executes *before* `0x005F82F7 and byte [edi+0x22], 0x82`. Bit 1 is already clear; only bit 7 survives. |

## P5. Verdicts on the six OVERSTATED items

| # | Verdict |
|---|---|
| **O1** | **UPHELD and hardened.** Interface polarity is `H`; the storage inversion is now `H` too (U6). Delete the gate. |
| **O2** | **UPHELD.** §4.4 is `H` — read off the compiler (U7), in two builds. |
| **O3** | **Process objection valid; substance resolves in the map's favour.** Pass 1 was right that §11 asserting dedup while §10.1(b) called it open is self-contradictory. But the claim itself is **true**: the add primitive de-duplicates and rewrites the bit in place (U3). Fix the map by closing §10.1(b), not by demoting §11. |
| **O4** | **UPHELD, and now closed.** Pass 1 was right that the map inferred it from three constants. The emitter's signature is `emit(filter, char* text, int len)` and its first act is to call the *same* hash-one routine `SetFilter`'s single-label fast path uses — so **every token, operator or label, is `pandemic_hash_m2` of its own literal text**, proven from the emitter. |
| **O5** | **UPHELD.** `0x005F311F mov eax,[ebx+0x20]` / `0x005F3122 and byte [eax+0x22],0xC3` are direct reads; the config gate is verbatim. That row is `H`. |
| **O6** | **UPHELD, but Pass 1's replacement is also too narrow.** `DAT_00EDBAA4` / `PTR_DAT_00EDBAC0` occur **901 / 904 times** across the binary and are taken around the `Relationship` walk in `FUN_005880D0` as well as the `Label` walk in `FUN_005F8C90`. It is the **global ECS container-iteration critical section + free list**, not the seat-pool lock (map) and not a label-specific lock (Pass 1). The map's *consequence* — filter evaluation is not lock-free — survives and is in fact stronger. |

## P6. Verdicts on the five MISSING items

**M1 — CONFIRMED** and upgraded from hand-execution to a direct read of the compiler's leaf path
(U7). Trap token: `pandemic_hash_m2("(A&&B)") = 0xFBD46457`.

**M2 — CONFIRMED.** Unreachable, for the reason Pass 1 gives.

**M3 — CONFIRMED.** `FUN_005F79F0` (plain `.text`, `size=1872`) is absent from the map and is
load-bearing: it is the "coerce a Lua value where a filter is expected" helper, it answers §10.5, it
partly answers §10.6, and it documents the undocumented Lua-visible string **`"players"`**
(`0x00BBB734`). Its `thunk_FUN_024EA250` call (stub `0x005F8330`) is a *second* association
primitive one `0x20`-slot above `SetAssociation`'s.

**M4 — CONFIRMED in both builds.** `AddObject`'s flag defaults to **0**; `UsePlayers`' defaults to
**on**. Xbox: `0x8247CA78 stb r11(=0), 0x50(r1)` vs `0x8247CE0C li r11,1; stb r11,0x50(r1)`. Our
Rust's `on.unwrap_or(true)` for `UsePlayers` is **correct** — do not "fix" it for consistency with
the `AddObject` change.

**M5 — CONFIRMED by reading the crate.** `mercs2_core/src/object_filter.rs:43`
`pub fn add(&mut self, guid: u64, include: bool)`, the doc comments at `:28–31` and `:42`, and the
tests at `:295–315` / `:327` are all written around `bInclude`. Flipping only
`bindings/object_filter.rs:67` leaves the core API named backwards.

## P7. The four boundary claims Pass 1 declined to check — now checked

Sibling maps were treated as claims to test, never as evidence.

| Map's boundary claim | Verdict |
|---|---|
| label store = container `0x00DF8108`, `Object.AddLabel FUN_005CE900` / `RemoveLabel FUN_005CEBA0` / `HasLabel FUN_005CEE40` | **CONFIRMED.** The `Object` `luaL_Reg` table (`0x00B99608`) has exactly those three names at exactly those VAs. `FUN_005CE900`'s body calls `FUN_00649180(&PTR_PTR_00DF8108, …)`. The master key names `0x00DF8108` **`Label`**. (`FUN_005CEE40` has no Ghidra *body*, which is why a function-header grep finds nothing — the binding entry is real.) |
| player container `0x00DF9B90`, `GetPlayer FUN_006CDAF0` | **CONFIRMED.** Master key → **`Players`**; `FUN_006CDAF0` exists (size 116, 12+ callers). |
| the event bus is a separate namespace | **CONFIRMED.** `Event` `luaL_Reg` = `0x00B987F8`, **4 entries only**: `Create 0x005F69F0`, `CreatePersistent 0x005F6A00`, `Delete 0x005F6A10`, `Post 0x005F6A90`. A filter is an argument to it; the bus is correctly out of scope. |
| §5.3 — `Ai.SetRelation`/`GetRelation`/`ChangeRelation` are a **"false friend"** with "nothing to do with `ObjectFilter.SetRelation`" | **CONTRADICTED — this is the map's worst boundary error.** They are the *same* system. `Ai.GetRelation` (`FUN_005AACE0`) *is* a two-line wrapper around `FUN_005880D0` — the exact function `FUN_005F8390` calls for the relation channel — and `Ai.SetRelation`/`ChangeRelation` write the same `Relationship` container (`0x00DF7F08`) through `FUN_00588270 → FUN_00649180`. They also take **two object handles**, not faction ids. §5.3 must be rewritten from "false friend" to "**this is the writer for our reader**". |

## P8. The remaining "not checked" items

**`FUN_005F3110` (item 27) — read.** Beyond the prologue it is a **position-seeded spatial gather**:

```c
*(filter+0x22) &= 0xC3;                               // clear the player latch
if (this+0x2C) { FUN_00665AF0(); this+0x30..0x38 = <vec3 position>; }
if (FUN_005F2D80(this, arg))  return this+0x44 != 0;  // sentinel early-out
if (<nothing configured>)                             // same gate as Eval, verbatim
     for (g = iterate(filter's own object set)) collect(g);   // thunk_FUN_024E6430
else { FUN_005F2860(); n = FUN_00404450(DAT_0117504C, &results[1]); ... }   // spatial query
```

Result buffer `aiStack_80c[257]` (the map's "256-entry") plus a parallel `auStack_408[1028]`. So it
is the **filter-driven radius/proximity gather** behind the `Event.Object*` conditions, and it has a
behaviour worth recording: **a filter with an empty predicate but a populated object set enumerates
its own set instead of running the spatial query** — via the same iterator `GetObjects` uses.

**The four thunks (item 28) — identified, and three are not ours:**

| stub | target | verdict |
|---|---|---|
| `0x005F6C00` | `0x024EE260` | **belongs to `Event.Post` (`FUN_005F6A90`)**, called right after `luaL_ref(LUA_REGISTRYINDEX)`. Not ObjectFilter — it merely sits in the address window. |
| `0x005F8330` | `0x024EA250` | called only from `FUN_005F79F0`; one `0x20`-slot above the set-association primitive, so a sibling association setter. |
| `0x005F8350` | `0x028D5000` | a **general engine helper** with call sites all over the binary. Not ObjectFilter-specific. |
| `0x005F9210` | `0x024E6410` | **zero callers.** Dead stub inside the range. |

## P9. The shipped-script question (`mrxtaskjob.lua:310/349`)

Now decidable, because dedup is proven. `GetObjects(f,false)` returns the **included** set, so at
`:349` the local `tExcludedObjects` and the flag `bExcluded` are **misnamed** — they mean "included".
Both branches of the `if/else` at `:356–360` end with the GUID included, because the unconditional
`AddObject(f, uGuid, false)` at `:361` follows, **and the add primitive de-duplicates**, so the
second add on the false branch is a no-op bit rewrite rather than a duplicate entry. Verdict:
**a naming + dead-code defect, not a behavioural bug.** Low-priority `bug_register.md` note. `:310`
is *correct* as written.

Call-site census re-run: `GetObjects` 12 sites, **all** pass `false`; `AddObject` 7 sites — 3 literal
`false`, 3 literal `true`, 1 variable (`bExclude`, `mrxtaskobjective.lua:36`). (Pass 1 said "4 false,
3 true"; the fourth "false" is that variable.)

## P10. New findings neither pass had

- **N1 — `GetObjects` expands the player sentinel** into live per-player character GUIDs, flagged as
  included. Our Rust's `GetObjects` cannot do this at all.
- **N2 — the object count and the token count both wrap at 32** with no bounds check (U3). The map
  states "≤31 objects" as a cap; it is not a cap, it is a **silent corruption boundary** — and there
  is an undocumented **≤31 token** limit on compiled expressions as well.
- **N3 — `RemoveObject` is an unordered swap-remove**, so it re-orders the set. Relevant to anyone
  reasoning about `FUN_005F87F0`'s newest-first backward scan.
- **N4 — `SetAssociation` returns a boolean** (false on an empty operator string).
- **N5 — the filter userdata is method-callable**: `__index = ObjectFilter`.
- **N6 — the namespace registry's third word is a post-registration Lua chunk**, not a name. Ten of
  the 31 namespaces ship one; ObjectFilter's *is* the metatable definition.
- **N7 — `.securom` has two populations**, a plain relocated-code band and a VM-stub band (P1).
- **N8 — `pandemic_hash_m2` is now recovered from engine machine code**, independent of
  `tools/pandemic_hash.py`, including the `| 0x20` fold and the terminal `^ 0x2A` round.

## P11. Amendments this pass adds to Pass 1's recommendation list

Pass 1's items 1–4 stand. Add:

5. **Rewrite §5.3.** `Ai.GetRelation` is not a false friend, it is the reader for the same
   `Relationship` container; `Ai.SetRelation`/`ChangeRelation` are the writers.
6. **Retract §3.4's distance inference and delete §10.4.** `FUN_005880D0` is `Ai.GetRelation`.
7. **Close §10.1, §10.3, §10.5 and most of §10.6** from `output/jul08_prototype/` — no debugger
   needed. Leave only the two-line in-game discriminator (§10.2 plus an `"!(A&&B)"` case).
8. **Record the metatable as the Lua global `_OFMETATABLE`** and the registry row at `0x00DFD52C`.
9. **Name the containers**: `0x00DF8108` = `Label`, `0x00DF8188` = `SeatLink`, `0x00DF7F88` =
   `Association`, `0x00DF7F08` = `Relationship`, `0x00DF9B90` = `Players`.
10. **Add the 32-object / 32-token wrap and the sentinel expansion in `GetObjects`.**
11. **Add `output/jul08_prototype/mercs2_xenon_p.pe_full.bin` to §12 Provenance** as the oracle for
    everything behind a SecuROM stub, with the `file_off == VA − 0x82000000` note.

## P12. Pass 2 summary count

| | |
|---|--:|
| Open register items entering Pass 2 | **28** |
| **CLOSED** | **27** |
| STILL-OPEN | **1** (U7's runtime leg only — its static leg is proven) |
| Pass-1 verdicts **upheld** | 15 (C1–C4, O1–O2, O4–O6, M1–M5) |
| Pass-1 verdicts **partly corrected** | 2 (O3 substance, O6 scope) |
| Pass-1 findings **corrected outright** | 1 (§A.1's namespace-registry row) |
| Map claims **newly contradicted** by Pass 2 | 2 (the `Ai.SetRelation` false friend; `FUN_005880D0` as a distance) |
| New findings | 8 |

Everything above is **static**. Nothing was run, no debugger was attached. Verdicts derived from the
Xbox prototype are **cross-build** and are labelled as such wherever they appear; the twelve
structural agreements in P2.1 — especially the mirror-image bitfield layout — are the evidence for
the join.
