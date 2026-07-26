# ECS / reflection component registry (Keystone A) — Xbox↔PC code map

**Scope:** scoreboard **row 12 — ECS / reflection registry** — the stream-deserialized
component-descriptor mechanism that backs **all ~231 native component classes**. This is *Keystone A*
of the engine (`docs/modernization/pangea_engine_alignment.md`): one registration template
instantiated once per class, wiring a shared `CopyFromStream` deserialize vtable, the golden-ratio
seed `0x9e3779b9`, a pool budget, a record stride, a shared method vtable, and a class-name string,
then calling one shared registrar. Every world-content type — terrain, regions, physics actors,
weapons, AI behaviours, cash, faction values, sound effects, runtime-render components — streams in
through this one path, so it is the engine's asset/component/serialization spine. Image base
`0x00400000` (PC retail, unpacked); Xbox base `0x82000000` (Jul-08 Profile devkit).

**Sources.** PC: the 27k-fn Ghidra decomp of the unpacked exe — **every registrar/consumer body
below was fetched from the corpus and read first-hand this pass**, not inferred. Data layer:
[`../mercs2-ecs/`](../mercs2-ecs/) (all 9 family docs = the 232-class registry with hashes/strides/
descriptor globals + field schemas; `_registry_raw.tsv`), [`../game_config/cdbsizes.ini`](../game_config/cdbsizes.ini)
(pool budgets), [`asset_formats_code_map.md`](asset_formats_code_map.md) §5 (this keystone sketched;
expanded here), [`world_streaming_code_map.md`](world_streaming_code_map.md) §4 (the descriptor rows).
Xbox oracle: [`../mercs2-pdb-analysis/world-streaming.md`](../mercs2-pdb-analysis/world-streaming.md)
§"The ECS component-descriptor mechanism". Companion memory: [[ecs-component-registry-corpus]],
[[cdbsizes-component-pool-config]], [[mercs2-core-ecs-spine]].

**Method / honesty model.** Same discipline as the sibling maps. Every PC address is decomp-verified;
each row states whether the body was **READ** first-hand this pass or cited **(ref)**. The registrar
template is proven **byte-identical** across three independently-fetched ctors (FactionMarker,
HibernationControl, RuntimeWeapon) plus two corroborating docs (camera, particle_fx). Confidence:
**H** = structural fingerprint that can't coincide (shared vtable + seed + descriptor offset layout) ·
**M** = role + one strong signal · **L/open** = positional / confirm-live. The Xbox side is the
**shared descriptor mechanism** (`FUN_824fd430`/`FUN_824fcac8`/`FUN_824fd490` + `&PTR_FUN_82030fa0` +
`0x9e3779b9`); the individual Xbox class ctors are name-anchored via the *inlined* class-name string,
so the marriage is strong even though most Xbox bodies aren't otherwise labelled.

**SecuROM note.** Two seams touch this row and **neither is a wall** ([[no-debug-probes-in-the-game-exe]]
notwithstanding, per [[securom-decompiled-not-a-blocker]]): (a) the registrar's `flags&8` branch is an
*unrecovered jumptable* (`(*_DAT_0244f738)()`), whose destination is the recovered sibling
`FUN_0064a782` (append to the second array) — a plain decomp-coverage gap, read live in the unpacked
image if needed; (b) the on-disk `schm` field-schema chunk is dispatched to `thunk_FUN_024e31f0`, a
SecuROM VM trampoline — the *field-name→offset schema handler*, again read live, not a wall.

---

## 0. Result in one line

The registry is **fully in the clear on PC and read first-hand**: one 159-byte ctor per class fills a
**0x50-byte descriptor** (base = name-string − 0x3c) with the shared `CopyFromStream` vtable @+0, a
flags word @+8, pool cap @+0xc, name-hash slot @+0x10, field/version count @+0x14, the shared method
vtable @+0x18, **record stride @+0x24**, seed `0x9e3779b9` @+0x2c, and the class name @+0x3c, then
tail-calls the shared registrar **`FUN_0064a770`**, which appends the descriptor into one of **two
global arrays** (`PTR_PTR_00edbec8` for authored classes / `PTR_PTR_00edbac8` for `Runtime*` classes,
selected by descriptor `flags & 8`) and assigns a sequential type id. A post-init pass
(`FUN_0064a7e0`) stamps each descriptor's `pandemic_hash_m2(name)` into `+0x10`; at load a WAD `COMP`
chunk's `info` type-hash resolves to the descriptor via `FUN_0064aa10`, deserializes through the
`CopyFromStream` vtable, inserts into the class's open-addressed pool via `FUN_0064a600`, and
spatially registers via `FUN_00665590`. The Xbox twin (`FUN_824fd430`/`FUN_824fcac8`/`FUN_824fd490`,
same seed, same 0x100 pool cap, **same two-array flag-bit-3 split**, `&PTR_FUN_82030fa0` wired into
**232** descriptors) is the cleanest cross-build marriage in the engine.

---

## 0.5 Master marriage table (the mechanism at a glance)

Confidence: **H** can't-coincide fingerprint · **M** one strong signal · **L/open** positional /
confirm-live. Xbox column = the `world-streaming.md` symbol; every PC body was **READ** this pass.

| Mechanism function | Xbox | PC addr | Married by | Conf |
|---|---|---|---|---|
| **descriptor record init** (id slots 0xffff, vtable, cap 0x100, count 3) | `FUN_824fd430` | *inline in each ctor* (`FUN_0063/64xxxx`) | READ: 0x50-byte descriptor, id `0xffff/0xffff`, cap `0x100`, count `3` — matches Xbox field-for-field | H |
| **field/reflection-hash table init** (seed `0x9e3779b9`, size→u16) | `FUN_824fcac8(desc, elem_size)` | *inline* (`desc+0x24`=stride, `desc+0x2c`=`0x9e3779b9`) | READ: seed + stride the size arg = on-disk record stride | H |
| **shared registrar** (assign type id, append to registry) | `FUN_824fd490` | **`FUN_0064a770`** (+ twin `FUN_0064a782`) | READ: appends `PTR_PTR_00edbec8[count]`, id = `count+1 + secondary_count` → `desc+6` | H |
| **the two registry arrays** (flag bit 3 split) | `&DAT_83808ae0` / `&DAT_83808ee0` | `PTR_PTR_00edbec8` (authored) / `PTR_PTR_00edbac8` (Runtime*) | READ: `flags&8` selects; RuntimeWeapon flags=8, FactionMarker/Hibernation flags=0 | H |
| **type-id counters** | `DAT_838096e0` / `DAT_838096e4` | `DAT_01176058` (primary) / `DAT_0117605c` (secondary) | READ: interleaved sequential id across both arrays | H |
| **shared deserialize vtable** (`CopyFromStream`) | `&PTR_FUN_82030fa0` (×232) | `&PTR_CopyFromStream_*` (per class) | cross-build: same seed + shared vtable both builds | H |
| **shared method vtable** (Activate/Deactivate/get-name @+0x34) | `&PTR_FUN_82036db8`-family | `&PTR_LAB_00bc5ff8` | READ: `desc+0x18`, shared by every class | H |
| **name-hash finalize pass** (FNV-1a = `pandemic_hash_m2`) | (n/a — inlined name) | **`FUN_0064a7e0`** | READ: FNV-1a `0x811c9dc5`×`0x1000193`, `\|0x20`, `^0x2a`; writes `desc+0x10` | H |
| **registry sort** (both arrays, `qsort`) | — | **`FUN_0064a8f0`** | READ: `qsort` both arrays by `LAB_0064a8c0` | H |
| **type-hash → descriptor lookup** | — | **`FUN_0064aa10`** | READ: linear scan both arrays for `desc+0x10 == hash`; called from `FUN_00654940` | H |
| **pool-alloc pass** (per-class, presize) | — | **`FUN_00672e40`** (`FUN_00672ee0` guard) | READ: for each desc call method vtable `+0x20`; gated `DAT_01176058._3_1_` | H |
| **pool teardown pass** | — | **`FUN_00672ef0`** | READ: per-desc method vtable `+0x48` | H |
| **component pool insert** (open-addressed) | — | **`FUN_0064a600`** | READ: `memcpy` record of stride `+0xc` into hashed slot; grows pool via `thunk_FUN_02e90000` | H |
| **object→component instance resolver** | (Del::* family) | **`FUN_005857e0`** (`__fastcall`) | READ: pool lookup, stride `+0x24`, idx table `+0x34`, bucket `+0x38` | H |
| **spatial register** (256-region bitmask) | — | **`FUN_00665590`** | READ: `param_2>>6` region, sets bitmask in `PTR_PTR_00df6d08` cell | H |
| **COMP consumer / schm dispatcher** | `&PTR_FUN_82030fa0` | **`FUN_00654940`** | READ: `COMP`→`data`/`schm`(→`024e31f0`)/`info`(type-hash resolve) | H |
| **authored field-schema builders** (int/float/enum/rgb/ref) | — | `FUN_00656210` / `FUN_00656320` / `FUN_00656720` / `FUN_00656610` / `FUN_00656890` → `FUN_0064a600` | READ (via `FUN_0065ca70` WeaponProjectileBase): ordered field push = byte layout, args = defaults | H |
| **enum-table builder** (65 enums) | — | `FUN_0064ac50` (from bootstrap `FUN_0064aa70`) | (ref) `{namehash,ordinal}` pairs registered by name | M |

---

## 1. The mechanism in three layers

```
 STATIC INIT (CRT ctor table @0x00a79xxx / 0x00a7bxxx)
   ├─ ~232× one-shot class ctor  FUN_0063xxxx / FUN_0064xxxx        §3
   │     fills a 0x50-byte descriptor {CopyFromStream vtable, flags, pool cap,
   │       name-hash slot, field count, method vtable, STRIDE, 0x9e3779b9, name}
   │     └─ tail-call SHARED REGISTRAR  FUN_0064a770                 §2
   │            flags&8 ? → PTR_PTR_00edbac8 (Runtime*)  : PTR_PTR_00edbec8 (authored)
   │            assign sequential type id → desc+6
   └─ FIRST BLOCK DISPATCH  FUN_004646b0
          ├─ FUN_0064a7e0  name-hash finalize  (pandemic_hash_m2(name) → desc+0x10)   §2.2
          └─ FUN_0064a8f0  qsort both arrays

 POOL PRESIZE (level transition FUN_004c0730)
   ├─ FUN_00672ee0 → FUN_00672e40   for each desc: method-vtable+0x20 allocates the pool
   │                                (capacity from cdbsizes.ini)                       §4.3
   └─ FUN_00672ef0                  teardown: method-vtable+0x48

 STREAM LOAD (per WAD COMP chunk)   FUN_00654940  CHDR dispatcher                      §4.1
   COMP subtree:
     info  → read type-hash → FUN_0064aa10  scan both arrays for desc+0x10==hash → descriptor
     schm  → thunk_FUN_024e31f0   field-name→offset schema  (SecuROM, live)            §5
     data  → CopyFromStream(desc) deserialize record  →  FUN_0064a600 pool insert      §4.2
                                                      →  FUN_00665590 spatial register §4.4

 RUNTIME ACCESS
   FUN_005857e0(object)  →  component instance ptr  (pool lookup by entity hash)       §4.5
```

---

## 2. The shared registrar — read first-hand (H)

### 2.1 `FUN_0064a770` = the registry tail every class calls

64 bytes, `in_EAX` = the descriptor base. Body read verbatim:

```c
void FUN_0064a770(void) {                       // in_EAX = &descriptor
  undefined *in_EAX; short sVar1;
  if ((*(uint *)(in_EAX + 8) >> 3 & 1) != 0) {  // flags bit 3 set → Runtime* class
    (*_DAT_0244f738)();                          // unrecovered jumptable → second-array append
    return;                                      //   (= FUN_0064a782 semantics; read live)
  }
  sVar1 = (short)DAT_01176058 + 1;
  (&PTR_PTR_00edbec8)[(short)DAT_01176058] = in_EAX;      // append to PRIMARY (authored) array
  DAT_01176058 = CONCAT22(DAT_01176058._2_2_, sVar1);     // bump primary count
  *(short *)(in_EAX + 6) = sVar1 + (short)DAT_0117605c;   // assign type id (offset by 2nd count)
}
```

The recovered twin **`FUN_0064a782`** is exactly the `flags&8` branch destination — it appends into
the **second** array `PTR_PTR_00edbac8` and bumps `DAT_0117605c`:

```c
void __fastcall FUN_0064a782(short param_1) {    // in_EAX = &descriptor
  DAT_0117605c = param_1 + 1;
  (&PTR_PTR_00edbac8)[param_1] = in_EAX;          // append to SECONDARY (Runtime*) array
  *(short *)(in_EAX + 6) = (short)DAT_01176058 + (short)DAT_0117605c;  // interleaved id
}
```

**The two-array split.** `flags` (descriptor `+0x8`) bit 3 partitions classes: **authored/static**
classes (`flags == 0`) → `PTR_PTR_00edbec8` (count `DAT_01176058`); **`Runtime*`/`Rt*` instance**
classes (`flags == 8`) → `PTR_PTR_00edbac8` (count `DAT_0117605c`). This is the exact PC realization
of the Xbox `FUN_824fd490`'s "one of two global arrays (`&DAT_83808ae0` if flag bit 3 set, else
`&DAT_83808ee0`)". Proven below: `RuntimeWeapon` ctor writes `flags = 8`; `FactionMarker` and
`HibernationControl` write `flags = 0`.

### 2.2 Registry lifecycle passes (all READ, from `FUN_004646b0` / `FUN_004c0730`)

- **`FUN_0064a7e0`** — name-hash finalize: walks **both** arrays, calls each descriptor's method
  vtable `+0x34` (get class-name string), computes **FNV-1a `= pandemic_hash_m2`** (seed `0x811c9dc5`,
  mul `0x1000193`, lowercase `|0x20`, finalize `(h ^ 0x2a) * 0x1000193`) and stores it into
  `descriptor+0x10`. **This is where each class's type-hash is materialized** — the field
  `FUN_0064aa10` later keys on.
- **`FUN_0064a8f0`** — `qsort(&PTR_PTR_00edbec8, DAT_01176058, 4, LAB_0064a8c0)` then the same for
  the second array (sort both class arrays).
- **`FUN_0064aa10`** — **type-hash → descriptor** resolver (called from the COMP consumer
  `FUN_00654940` @0x00654fbd): linear-scans the primary array then the secondary for
  `*(desc+0x10) == key`, returns the descriptor (or 0). The sort is for other consumers; this lookup
  is a linear scan by design.
- **`FUN_00672e40`** (guarded by `FUN_00672ee0`, gate `DAT_01176058._3_1_`) — the **pool-alloc pass**:
  for each descriptor in both arrays, if method-vtable `+0x3c` returns > 0, calls method-vtable `+0x20`
  to allocate that class's pool. This is where `cdbsizes.ini` capacities take effect (§6).
- **`FUN_00672ef0`** — teardown: per-descriptor method-vtable `+0x48`, clears the gate.

---

## 3. The registrar ctor template — byte-identical across classes (H)

Each ctor is ~159 B, runs once from the CRT static-init table, zero-inits the descriptor, writes the
template fields, calls `FUN_0064a770`, then stamps the name pointer last. **Descriptor base =
name-string field − 0x3c.** Three ctors fetched independently prove the layout; the only per-class
variation is `{CopyFromStream vtable, flags, stride, name}`:

| Descriptor offset | Field | FactionMarker `FUN_00641340` | HibernationControl `FUN_00640a40` | RuntimeWeapon `FUN_0063dcf0` |
|---|---|---|---|---|
| `+0x00` | **CopyFromStream vtable** | `&…_00bbf928` | `&…_00bbf430` | `&…_00bc20f8` |
| `+0x04` | id-lo u16 (seed `0xffff`) | `0xffff` | `0xffff` | `0xffff` |
| `+0x06` | **id-hi u16 → type id** (written by registrar) | `0xffff`→id | `0xffff`→id | `0xffff`→id |
| `+0x08` | **flags** (bit3 = Runtime* / 2nd array) | `0` | `0` | **`8`** |
| `+0x0c` | pool cap u32 | `0x100` | `0x100` | `0x100` |
| `+0x10` | **name-hash slot** (written by `FUN_0064a7e0`) | `0` | `0` | `0` |
| `+0x14` | field/version count | `3` | `3` | `3` |
| `+0x18` | **shared method vtable** | `&PTR_LAB_00bc5ff8` | `&PTR_LAB_00bc5ff8` | `&PTR_LAB_00bc5ff8` |
| `+0x24` | **record STRIDE** (u16) | `4` | `6` | `0x34` |
| `+0x26` | shift/bucket param (u16) | `8` | `8` | `8` |
| `+0x28` | pool cap u32 | `0x100` | `0x100` | `0x100` |
| `+0x2c` | **seed** | `0x9e3779b9` | `0x9e3779b9` | `0x9e3779b9` |
| `+0x3c` | **class-name string** | `s_FactionMarker` | `s_HibernationControl` | `s_RuntimeWeapon` |
| `+0x40` | u32 | `0x100` | `0x100` | `0x100` |

FactionMarker `FUN_00641340`, read verbatim (representative):

```c
void FUN_00641340(void) {
  DAT_017bd58c = 0xffff; _DAT_017bd58e = 0xffff;         // +0x04/+0x06 id slots
  DAT_017bd590 = 0;                                       // +0x08 flags = 0 (authored → array 1)
  _DAT_017bd594 = 0x100;                                  // +0x0c pool cap
  _DAT_017bd598 = 0;                                      // +0x10 name-hash slot (filled later)
  _DAT_017bd59c = 3;                                      // +0x14 field count
  PTR_PTR_017bd588 = &PTR_CopyFromStream_00bbf928;        // +0x00 deserialize vtable
  DAT_017bd5ac = 4;                                       // +0x24 STRIDE = 4 bytes
  _DAT_017bd5ae = 8;                                      // +0x26
  DAT_017bd5b0 = 0x100;                                   // +0x28 pool cap
  DAT_017bd5b4 = 0x9e3779b9;                              // +0x2c seed
  _DAT_017bd5c8 = 0x100;                                  // +0x40
  PTR_PTR_017bd5a0 = &PTR_LAB_00bc5ff8;                   // +0x18 method vtable
  FUN_0064a770();                                         // register (assign id, append array)
  PTR_s_FactionMarker_017bd5c4 = s_FactionMarker_00bc5078;// +0x3c name (stamped last)
}
```

`HibernationControl`'s stride `= 6` is the decisive external check: it equals the 6-byte on-disk
payload `placement.rs::parse_hibernation_records` parses (`{dist0:u16, dist1:u8, dist2:u8, dist3:u8,
flag:u8}`) after the u32 key ([[cdbsizes-component-pool-config]], world_streaming §4). `RuntimeWeapon`
proves the `flags=8` Runtime* routing.

**Xbox marriage (H).** The identical template on Xbox (`TerrainGuidMappingHighResToLowRes @0x829f6ba8`,
read in world-streaming.md): `FUN_824fd430(desc,8)` stamps the record (id slots `0xffff`, cap `0x100`,
count `3`); `FUN_824fcac8(desc, 4)` seeds `0x9e3779b9` and stores element-size `4` as u16 @+0xc;
`DAT_…6c = &PTR_FUN_82030fa0` (the shared deserialize vtable, ×232); `FUN_824fd490(desc)` appends +
assigns the id. Field-for-field the same descriptor, same seed, same 0x100 cap, same two-array
flag-3 split — the strongest cross-build marriage in the codebase.

---

## 4. The consumer / resolver path — read first-hand

### 4.1 COMP consumer `FUN_00654940` (H, READ) — where a chunk becomes a component

The CHDR dispatcher's `COMP` arm (`0x504d4f43`, from [`asset_formats_code_map.md`](asset_formats_code_map.md)
§3.2) walks the component subtree and routes the three sub-tags:

- **`info`** (`0x6f666e69`) — reads the field-name/type-hash keys, probing the reflection-name table
  `FUN_008242b0(DAT_017c0b80)` (the open-addressing probe `HashTable_Probe`); resolves the component
  **type-hash → descriptor via `FUN_0064aa10`** (@0x00654fbd).
- **`schm`** (`0x6d686373`) — the field-name→offset **schema**; `FUN_00464780` reads the chunk then
  hands to `thunk_FUN_024e31f0` (SecuROM VM trampoline; §5).
- **`data`** (`0x61746164`) — `FUN_00464780` reads the payload, deserialized through the descriptor's
  `CopyFromStream` vtable into a fresh record.

The body enters under CS `&DAT_00edc6e4`, lazy-runs the pool-alloc pass (`if (DAT_01176058._3_1_==0)
FUN_00672e40()`), and its tail per-record calls `thunk_FUN_024ecab0` — the same SecuROM worker the
`SetHibernationDistance` cfunc uses (world_streaming §4), tying placement load to the hibernation
install.

### 4.2 Pool insert `FUN_0064a600` (H, READ) — the open-addressed component pool

264 B; `unaff_EDI` = the class pool object, `param_1` = entity key, `param_2` = source record.
`FUN_0064a090()` computes the hashed slot; on a free/matching slot it `memcpy`s **stride** (`pool+0xc`,
the same u16 the descriptor set at `desc+0x24`) bytes into
`slot = (mask & hash)*stride + bucket_table[hash >> shift]`, writes the entity key into the index
table `pool+0x1c`, and returns the record ptr. When load-factor `pool+4 == count*_DAT_00beb510` it
grows the backing store (`thunk_FUN_02e90000`) and re-hashes. This is the primitive every authored
field-schema template ends with (§4.6) and every raw-copy `Runtime*` deserializer uses. 12+ callers,
incl. `FUN_00654940` (COMP), `FUN_004a88a0` (terrain GUID map), region/spawn builders.

### 4.3 Pool presizing (cdbsizes.ini → `FUN_00672e40`)

The per-class **pool capacity** is not the descriptor's inline `0x100` in shipping — `FUN_00672e40`'s
method-vtable `+0x20` call reads the class's budget from the parsed `data/cdbsizes.ini`
([[cdbsizes-component-pool-config]]); e.g. `HibernationControl 14080`, `SceneObject 161280`,
`Flags 14848`. The `0x100` in the ctor is the default/fallback. §6 lists the full budget table.

### 4.4 Spatial register `FUN_00665590` (H, READ)

After insert, world-content components are registered into a **256-region occupancy bitmask**:
`region = param_2 >> 6`; it OR-sets the region's bit in the cell resolved from `PTR_PTR_00df6d08`
(via `FUN_00649180`). This is the coarse spatial index streaming/proximity queries walk. Same 12+
caller set as `FUN_0064a600` (they run as a pair: insert then register).

### 4.5 Object→component instance resolver `FUN_005857e0` (H, READ)

84 B, `__fastcall`, `param_1` = the object/entity. Bit 3 of `param_1+8` (the same authored/Runtime
flag) selects fast vs slow (`FUN_00649c00`) path; the fast path hashes (`FUN_0064a090`) and returns
the embedded pool slot using the pool sub-header at `+0x18` (stride `+0x24`, shift `+0x26`, mask
`+0x28`, index table `+0x34`, bucket table `+0x38`):

```c
int __fastcall FUN_005857e0(int param_1) {
  if ((*(uint*)(param_1+8) >> 3 & 1) == 0) return FUN_00649c00();     // slow path
  uVar1 = FUN_0064a090();
  if (-1 < (int)uVar1 && *(int*)(*(int*)(param_1+0x34) + uVar1*4) != -1)
    return (*(int*)(param_1+0x28) - 1U & uVar1) * (int)*(short*)(param_1+0x24) +
           *(int*)(*(int*)(param_1+0x38) + ((int)uVar1 >> (*(byte*)(param_1+0x26) & 0x1f))*4);
  return 0;
}
```

This is the getter behind e.g. `Object.GetHibernationDistance` (`FUN_005CF420` reads `*puVar6` =
dist0 after resolving the instance here — world_streaming §4). The per-entity component table is the
`{ptr,type}` layout the type-confusion notes track ([[ecs-texture-component-typeconfusion]]: entity
stride `0x190`, component table at entity+0xA0).

### 4.6 Authored field-schema deserializer (H, READ via `FUN_0065ca70`)

Authored classes' `CopyFromStream` target is a template that pushes fields **in stream order** through
shared primitives, then inserts. `WeaponProjectileBase` `FUN_0065ca70`:

```c
FUN_00656720(s_WeaponProjectileTypeEnum, s_Automatic);      // enum field (default Automatic)
FUN_00656720(s_WeaponProjectileSpecialCaseTypeEnum, …);     // enum
FUN_00656210(0); FUN_00656210(0); FUN_00656210(1);
FUN_00656210(0x1e);   // int = 30   → iClipSize
FUN_00656210(0x3c);   // int = 60   → MaxAmmoReserve
FUN_00656210(0); FUN_00656210(1); FUN_00656210(-1);
FUN_00656320(DAT_00b9851c);                                  // float
FUN_00656720(s_BoolEnum, s_False);                           // enum
FUN_00656210(-1); FUN_00656210(0); FUN_00656210(1);
FUN_00656320(0); FUN_00656320(DAT_00b977cc);
FUN_0064a600(param_1, &record);                              // POOL INSERT
if (added) FUN_00665590(param_1, region);                    // SPATIAL REGISTER
```

The primitives: `FUN_00656210(intDefault)`, `FUN_00656320(floatDefault)`, `FUN_00656720(enumTable,
default)`, `FUN_00656610(rgb)`, `FUN_00656890(hash)`. **Push order = the byte layout in the stream;
the literal args are the defaults when a field is absent** — this is where editable authored defaults
live. `0x1e`/`0x3c` = clip 30 / reserve 60 confirm `mercs2-ecs/01`.

---

## 5. The `schm` field-schema mechanism (honest: static vs live)

The `schm` sub-chunk carries the **field-name → offset schema** for a component class (which named
field lands at which record offset, so a save/level authored with a different field order still
deserializes). On PC the CHDR dispatcher (`FUN_00654940`, §4.1) routes `schm` to
`thunk_FUN_024e31f0` — a **SecuROM VM trampoline** (`thunk → FUN_02a30028`). Per
[[securom-decompiled-not-a-blocker]] this is **not a wall**: the trampoline is a plain indirection into
the self-decrypting overlay; the field-schema handler body is *readable live in the unpacked image*
(break `thunk_FUN_024e31f0` during a COMP load and step into the resolved target). Statically, only
the dispatch site is recovered; the handler body is **unlocated by static decomp** (a coverage gap,
distinct from the wired `data`/`info` arms which are fully in the clear).

On the Xbox side the equivalent binding is the field-hash table built by `FUN_824fcac8` (seed
`0x9e3779b9`); the authored field *names* come from the exe rodata property-name table (`mercs2-ecs`
README caveat). **What is static:** the descriptor mechanism, the `data`/`info` arms, the authored
field builders (§4.6) with their default values and order. **What is live-only:** the `schm`
handler that maps an *arbitrary on-disk field-name order* to record offsets — the one piece not
statically resolved and (§10) not implemented in `mercs2_engine`.

---

## 6. The 231-class census + cdbsizes pool budgets

`_registry_raw.tsv` = **232 registrations** (`{ClassName, descriptor global, method-vtable ptr}`);
`mercs2-ecs` partitions them into **220 gameplay + 12 render/pipeline** (family 09 = D3D9 precache
resource types + phase strings, *not* gameplay ECS). Invariants shared by **all** classes: seed
`0x9e3779b9` @desc+0x2c, shared `CopyFromStream` deserialize vtable @+0, shared method vtable
`&PTR_LAB_00bc5ff8` @+0x18, default cap `0x100`, name-hash `pandemic_hash_m2(name)` @+0x10.

### 6.1 Family census (from `mercs2-ecs/README.md`)

| Family doc | Count | Dialect notes |
|---|---|---|
| 01 combat / weapons / projectiles | 34 | authored schemas (`WeaponProjectileBase` clip 30/reserve 60/RoF 120) |
| 02 AI / perception / population | 25 | authored enums (Patrol/Priority/Traffic); AiSkill 10, Squad 50 |
| 03 controllers / physics | 31 | **opaque C++ blocks — no reflected fields**; Controllers = 4-byte handles |
| 04 player / vehicle / human | 23 | `HumanInventory` = 3 ints; `RuntimeVehicleInventory` = 2-byte bitmask |
| 05 presentation / audio / fx | 34 | `SoundEffect`/`LightObject`/`BlobShadow` (FX = ordinary reflection classes) |
| 06 world / terrain / roads / streaming | 30 | Road graph, `RtGenericLOD`, `Model`=`0x5b724250`; schema-vs-computed split |
| 07 gameplay / state / health / mission | 35 | `Health`=1f+3b, `RuntimeHealth`={max,cur} (corrected 2026-07-26), `ObjectScript`=2 int32 hashes |
| 08 misc | 7 | raw-blob (`Disable*Decals`, `TickDamage`, `TriggerOnTimer`) |
| 09 render / asset pipeline | 12 | **not gameplay ECS** — 8 D3D9 precache types + phase strings |
| **Total** | **231** (+1 phase-string dup = 232 raw) | |

**Three dialects** (README): **(1) authored/schema** classes — ordered `FUN_00656xxx` field list,
editable defaults (§4.6); **(2) `Runtime*`/`Rt*` instance** classes — no schema, raw-copy or
world-load-computed record (flags bit 3 set → second array); **(3) Controller/Physics** — opaque
fixed block decoded in C++ (`CopyFromStream` target), no reflected field names.

### 6.2 cdbsizes.ini pool budgets (the presize inputs, §4.3)

`data/cdbsizes.ini` `[presize]` gives `<Class> <count> [<align>]` for the pool-alloc pass. Largest
budgets (the streaming-critical pools): `SceneObject 161280`, `RuntimePhysicalLink 22784`,
`RuntimeLayerId 20224`, `Flags 14848`, `HibernationControl 14080`, `SeatLink 13312`,
`EntranceLink 13312`, `NodeHealth 11264`, `Name 6912`, `ModifierKey 6656`, `Label 6400`,
`ParticleKey 6144`, `SoundKey 5632`, `RuntimeEquipmentLink 5120`, `ModelName 4608`, `Road 4608`,
`LocalizedName 4352`, `VehiclePart 4096`. Smallest are `8 8` (e.g. `Model`, `Carryable`,
`ParticleEmitter`) or `4 4` (`RuntimeAirstrikeAirplane`, `RuntimeLaserDesignator`). These are **pool
counts, not element sizes** — the element size is the descriptor stride (§3); do not conflate
(world-streaming.md Corrections).

### 6.3 Type-hash anchors (build-invariant `pandemic_hash_m2`)

The component name-hash (`desc+0x10`) is `pandemic_hash_m2(ClassName)` and **build-invariant**
(same Xbox↔PC). `Model = 0x5b724250` (matches the MESH container asset hash — the component and its
backing asset share the name/hash). Note the **asset-handle** registry (`FUN_00873f20` /
`FUN_00874150` / `FUN_008731f0`, hash-probe `FUN_008242b0(0x100)`, references streaming-mgr field
`+0x4c360`) is a **distinct** registry from the reflection-component array — it resolves streamed
*asset/handle* classes (e.g. the Model *container*), not the ECS descriptor. Keep them separate: the
row-12 registry is `PTR_PTR_00edbec8`/`PTR_PTR_00edbac8` (via `FUN_0064aa10`).

---

## 7. Confirm-live inventory (x32dbg, read-only while PAUSED — [[x32dbg-mcp-no-resume]])

1. **Registrar type-id assignment** — break `FUN_0064a770`; read `DAT_01176058`/`DAT_0117605c` and a
   descriptor's `+6` after append to confirm the interleaved id; hit `FUN_0064a782` with a `Runtime*`
   class to confirm the second-array path (resolves the `flags&8` jumptable).
2. **Name-hash finalize** — break `FUN_0064a7e0`; confirm `desc+0x10 == pandemic_hash_m2(name)` for
   `Model` (`0x5b724250`) and `HibernationControl`.
3. **`schm` handler (the row-12 gap)** — break `thunk_FUN_024e31f0` during a COMP-heavy world load,
   step into the SecuROM-resolved target, and read the field-name→offset schema layout it produces —
   the one mechanism not statically recovered (§5).
4. **Type-hash resolve** — break `FUN_0064aa10` (called from `FUN_00654940` @0x654fbd); read the
   incoming key vs `desc+0x10` to confirm WAD `info` type-hash → descriptor.
5. **Pool insert/grow** — break `FUN_0064a600`; read `pool+0xc` (stride) vs the descriptor stride and
   catch the `thunk_FUN_02e90000` grow at load-factor.
6. **cdbsizes presize** — break the pool-alloc pass `FUN_00672e40` method-vtable `+0x20` call for
   `SceneObject`/`HibernationControl` and confirm the capacity comes from the parsed ini, not `0x100`.
7. **Xbox binding** — if the Jul-08 devkit is driven, break `FUN_824fd490` to confirm the two-array
   split and read `DAT_838096e0/e4`.

---

## 8. Open / unlocated (honest)

- **`schm` field-schema handler body** — statically unlocated (SecuROM `thunk_FUN_024e31f0` dispatch,
  §5); the arbitrary field-name→offset mapping is live-only. This is the concrete row-12 gap.
- **`flags&8` jumptable** in `FUN_0064a770` — Ghidra couldn't recover the branch target; the recovered
  twin `FUN_0064a782` performs the second-array append, so behaviour is known, but the exact dispatch
  is confirm-live.
- **Controller/Physics opaque blocks** (family 03, 31 classes) — no reflected field names; each
  `CopyFromStream` target must be disassembled per class to recover its byte layout (README caveat).
- **Authored field *names*** — positions are matched to names by their defaults where recoverable;
  a handful are flagged uncertain in the family docs (some decompiled "float" defaults are Ghidra
  rodata-pointer artifacts).
- **Xbox individual class ctors** — name-anchored by the *inlined* class-name string but otherwise
  unlabelled; the marriage rests on the shared `FUN_824fd430`/`FUN_824fcac8`/`FUN_824fd490` +
  `&PTR_FUN_82030fa0` + seed, not per-class bodies.

---

## 9. Reconciliation with `mercs2_engine` (scoreboard row 12 = 🟡)

The engine has the **spine but not the schema deserializer**:

- ✅ **Descriptor table + budgets exist.** `mercs2_core`'s ECS spine ([[mercs2-core-ecs-spine]]) is a
  `hecs` World with typed component storage; the `cdbsizes.ini` budgets (§6.2) and the class census
  (§6.1) are ingested as the presize/registry reference. The Xbox↔PC descriptor mechanism (§3) is the
  authoritative model those pools mirror.
- 🟡 **Only 4 native ECS components vs 231 registry classes** ([[engine-support-inventory]]). The
  engine implements a handful (Transform/Name/Model/HibernationControl-class) natively; the other
  ~227 are not yet reflected component types.
- ❌ **Field-schema (`schm`) deserialization NOT implemented** (§5). The engine does not consume the
  on-disk field-name→offset schema; it hard-codes the few components it supports. Faithful row-12
  parity requires (a) a data-driven descriptor table keyed by `pandemic_hash_m2(name)` mirroring
  `FUN_0064aa10`, (b) the authored field-order/default schemas (§4.6, extractable statically from the
  `FUN_00656xxx` templates), and (c) the live `schm` handler (§8) for arbitrary field orders — the
  one piece needing a confirm-live capture before it can be reimplemented.

Net: this document is the **mechanism authority** for row 12 — it pins the one shared registrar, the
byte-identical ctor template, the two-array split, the consumer/resolver/pool/spatial chain, and the
231-class census + budgets, and isolates the single genuinely-live gap (`schm`) that keeps the row at
🟡.
