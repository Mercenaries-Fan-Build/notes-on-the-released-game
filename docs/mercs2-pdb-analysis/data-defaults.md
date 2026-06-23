# Mercenaries 2 — `.data` Default-Value / Config-Table Mining

**Scope:** What can be recovered about *authored default values* and reflection tables from the
**`.data` section (RVA `0xb40000`, VSize 19 MB)** of the recovered Jul 11 2008 X360 preview game
PE. **Provenance:** all numbers below come from running extraction scripts over
`output/jul08_prototype/mercs2_xenon_p.pe_full.bin` (devkit "Profile" build of
`Mercs2_Xenon_P.exe`, PowerPC/Xenon, **big-endian**, Pandemic "Pangea" engine, Havok physics).
Values quoted are *the prototype's compiled-in defaults*. Cross-links:
[vehicles.md](vehicles.md), [havok-physics.md](havok-physics.md),
[../reverse_engineer/jul08_prototype_iso.md](../reverse_engineer/jul08_prototype_iso.md).

---

## 0. Critical layout correction (read first)

The task brief said "file-offset == RVA" for this image. That is **true for `.rdata`/`.text`
but NOT for `.data`.** Parsed from the PE header (`<I` little-endian header fields):

```
image_base = 0x82000000
.data   VA(RVA)=0xb40000  VSize=0x12ddc9c (19 MB)  Raw=0xb2ce00  RawSize=0x232a00 (2.29 MB)
```

So:

* A `.data` **RVA→file-offset** map is `file = rva - 0xb40000 + 0xb2ce00`, and a `.data`
  **RVA→virtual-address** is `va = rva + 0x82000000` (e.g. RVA `0xb40000` → VA `0x82b40000`).
* **Only the first `0x232a00` (2.29 MB) of `.data` is initialized in the file.** The remaining
  ~17 MB of the 19 MB VSize is **BSS** (zero-filled at load, runtime state — *not* defaults).
  All mining below is restricted to that 2.29 MB initialized window
  (file `0xb2ce00 .. 0xd5f800`).
* This image is **big-endian**: every multi-byte value in `.data` is decoded as `>I` / `>f`.

Statistical census of the 576,128 initialized 4-byte words (BE):

| class | count | % |
|---|---|---|
| zero | 423,322 | 73.5% |
| pointer-like (`0x82xxxxxx`) | 56,830 | 9.9% |
| plausible float (1e-6 … 1e6) | 22,255 | 3.9% |
| other int | 73,725 | 12.8% |

Of the 56,830 pointers, **43,208 point into `.rdata`** and **40,598 of those land exactly on a
string start** (preceding byte `\0`, first byte printable). That density is the signature of a
**reflection name-table system living in `.data`**, which is what the rest of this doc decodes.

---

## 1. The big result: `.data` holds the **Havok reflection database**, not Pandemic tuning defaults

### 1.1 What the name-pointers form

Measuring the gap (in words) between consecutive string-pointer words across all of initialized
`.data` gives one overwhelmingly dominant period:

```
stride 6: 37,513   stride 1: 880   stride 2: 547   stride 7: 535   stride 8: 337 ...
```

A **stride of 6 words = a 24-byte record**. Decoding those 24-byte records against the standard
**`hkClassMember`** layout (Havok 4.x/5.x reflection) resolves cleanly:

```
+0  const char*  name      (-> .rdata string)
+4  hkClass*     class      (struct members)
+8  hkClassEnum* enum
+12 hkUint8      type        <- valid 0..34
+13 hkUint8      subtype
+14 hkInt16      cArraySize
+16 hkUint16     flags
+18 hkUint16     offset
+20 (attributes ptr / 0)
```

Validating "word0 is a string-pointer AND byte `+12` ≤ 34" yields **39,274 `hkClassMember`
records**, and the type byte decodes to a sane Havok type histogram:

| type | count | | type | count |
|---|---|---|---|---|
| `REAL` (11) | 8,430 | | `STRUCT` (25) | 2,670 |
| `VECTOR4` (12) | 4,125 | | `BOOL` (1) | 2,026 |
| `ARRAY` (22) | 3,378 | | `SIMPLEARRAY` (26) | 1,662 |
| `POINTER` (20) | 3,253 | | `UINT32` (8) | 1,524 |
| `INT32` (7) | 2,994 | | `CSTRING` (29) | 1,222 |

Grouping the records into contiguous member-arrays gives **1,287 distinct `hkClass` member
tables / 38,907 member records / 2,232 distinct field-name strings.** This is **Havok reflection**;
the version **cannot be pinned to 5.0.0** from the binary. Re-deriving the version markers
(`re.compile(rb'Havok-\d+\.\d+\.\d+-[a-z]\d+')` over the whole PE) finds **25 distinct version
strings spanning the full range `Havok-3.3.0-a2` … `Havok-5.5.0-r1`** — families
`3.3 / 4.0 / 4.1 / 4.5 / 4.6 / 5.0 / 5.1 / 5.5` — and **every one is referenced as a literal
big-endian VA from `.data`** (the `0x3.3.x` markers included). That is the signature of Havok's
**serialization version-compatibility / patch table** (the runtime needs every historical version
tag to load older serialized data), **not** evidence that the engine "is Havok 5.0.0." Singling out
`5.0.0` was cherry-picking; the most that can be said is the corpus includes markers up to
`5.5.0-r1`.

### 1.2 Concrete decoded schema — `hkpVehicle*` (vehicle physics)

The largest member table is at **RVA `0xc72820` (VA `0x82c72820`), 502 records** — the
concatenated Havok vehicle classes (`hkpVehicleData`, `hkpVehicleDefaultEngine/Transmission`,
`hkpVehicleAerodynamics`, `hkpVehicleWheelCollide`, …). Decoded head (name / type):

```
localToDisplay   TRANSFORM     friction        REAL      gravity          VECTOR4
transforms       ARRAY         viscosityFriction REAL    numWheels        INT8
radius           REAL          maxFriction     REAL      chassisOrientation ROTATION
mass             REAL          slipAngle       REAL      torqueRollFactor REAL
width            REAL          ...                       ...
```
…continuing through `airDensity`, `frontalArea`, `dragCoefficient`, `liftCoefficient`,
`maxBreakingTorque`, `engine`/`transmission`/`brake`/`suspension`/`aerodynamics` (all `POINTER`),
`currentGear` (`INT8`), `rpm`/`torque` (`REAL`), etc.

A second clean example (rigid-body / motion state material, RVA `0xc6dee8`, 24 records) decodes
`friction`/`restitution`/`maxImpulse`/`maxLinearVelocity`/`maxAngularVelocity` as `UINT8`,
`linearDamping`/`angularDamping`/`objectRadius` as `REAL`, `transform` as `TRANSFORM`.

### 1.3 The honest limitation — **these schema records carry NO default value**

Two facts establish this:

1. **Every `hkClassMember.offset` field is `0x0000`** across all sampled tables (vehicle, rigid
   body, etc.). This Profile build emitted the reflection schema with member offsets **zeroed**
   (they are filled in at class-registration time on the device), so the records describe *type
   and name only* — there is no inline default slot.
2. In Havok, per-field defaults live in a separate **`hkClass::m_defaults`** object, reached by
   chaining `hkClass → defaults*`. Attempting that chain **statically from this dump fails**: of
   the 1,287 member-array start addresses, only **3** appear anywhere in the file as a literal
   big-endian `hkClass.declaredMembers` pointer. The remaining member-array pointers (and hence
   the `hkClass` records and their `defaults*` pointers) are **not recoverable as literal VAs**
   from this static image — they are produced/patched by the registration code path, so
   `name → default` cannot be chained reflectively here. **This is the inherent difficulty the
   task anticipated, and it is a real wall for the in-`.data` reflection system.**

So: `.data` gives a **complete Havok reflection *schema*** (1,287 classes, 2,232 field names,
fully typed) but **not** the per-field defaults via that mechanism.

### 1.4 Why the *game's* tuning fields aren't here

The Pandemic vehicle-tuning fields named in [vehicles.md](vehicles.md) — `EngineTorque`,
`SpringStrength`, `MaxSpeed`, `WheelRadius`, `Friction` (space-padded reflection strings in
`.rdata`) — were searched for as `.data` reflection name-pointers:

```
EngineTorque  VA 0x8203d5ac  -> 0 pointer-occurrences in .data (and 0 in .rdata, 0 file-wide)
SpringStrength, MaxSpeed, WheelRadius, Friction -> likewise 0
```

These names exist **only** as `.rdata` strings loaded by `.text` via PowerPC split immediates
(`lis`/`addi`) — i.e. they belong to **Pandemic's own hand-rolled tuning loader**, separate from
the Havok reflection-in-`.data` system. Consistent with project memory, the editable *weapon*
stats and the game-side vehicle tuning **defaults live in WAD reflection blocks**
(`wpn_*` / `wif*` blocks), not in this PE's `.data`. Confirming this from the schema side:
searching all 2,232 reflection field names for weapon/combat terms returns essentially nothing
game-relevant — `Clip` only matches Havok's `normalClippingAngle`/`relativeToEndOfClip`;
`ammo`/`damage`/`recoil`/`reload`/`health` → **no hits**. The `.data` reflection corpus is
**purely Havok** (physics / animation / cloth / constraints).

---

## 2. What default *values* ARE in `.data` — compiled-in C++ global tuning blocks

Defaults that *are* recoverable from `.data` are the **initialized C++ global structs/arrays**,
not reflection-tagged. Scanning for contiguous runs of plausible-float words surfaces two kinds.

### 2.1 Precomputed math lookup tables (not authored tuning)

The four largest float runs are **~4096-entry trig tables**, e.g. RVA `0xd59e64` (4095 entries):
`val(n)` rises 0→1.0 at n≈2048 then back to 0 at n≈4096 (a `sin`/`asin` quarter-wave table; its
±0.0008-step siblings at `0xd5de64`/`0xd65a24`/`0xd69a24` are the signed/derivative variants).
These are engine math tables, flagged here so they aren't mistaken for game defaults.

### 2.2 Authored game-tuning constant blocks (the real defaults)

A dense band of mixed int/float globals sits around **RVA `0xb99908`–`0xb9a06c`** (VA
`0x82b99908+`). It is unmistakably hand-authored tuning — it is full of angle constants:

* `6.2832` = **2π**, `1.5708` = **π/2**, `0.017453` = **π/180** (degrees→radians),

interleaved with gameplay magnitudes. Verbatim decoded run starting at RVA `0xb99908`:

```
6.2832  1.5708  2000.0  6.2832  1.5708  0.017453  0.5  5.0  20.0  -95.0  0.1  2000.0
0.3     2.0     0.1     1.0     5.0     100.0      2.0  ...   20.0  0.1   ...
```
…and the adjacent blocks (RVA `0xb9998c`, `0xb99a84`, `0xb99b24`, `0xb99b94`, `0xb99c3c`):

```
12.0 0.2 -0.5 0.3 6.2832 0.75 18.0 900.0 200.0 100.0 300.0 1050.0
200.0 30.0 100.0 375.0 1050.0 60.0 20.0 -16.0 900.0 300.0 200.0 75.0
61.0138 6.2832 0.0175 0.01 -1.0 3.5 20000.0 0.2 1.1 2.0 3.0 6.0
0.0167(=1/60) 0.5 0.2 0.5 0.1 0.5 10.0 4.0 4.0 20.0 2.0 6.2832
```

These are concrete prototype default values (timers like `1/60`, magnitudes `900/300/200/100`,
angle limits in radians). **What they cannot be given here is *field names*:** this block is
referenced by `.text` through a TOC/anchor base+displacement, not a direct `lis/addi` to
`0x82b99908` (the targeted scan found 0 direct references), so labeling each slot needs either
the real PDB or `.text` dataflow analysis — out of reach for pure `.data` mining. They are
therefore **values without resolvable names** (the inverse of the §1 schema, which has names
without values).

---

## 3. Bonus — enum string tables in `.data`

The stride-1 string-pointer runs are **reflection/enum value-name arrays** (these *are* fully
self-describing). Largest examples found:

| RVA | len | first entries |
|---|---|---|
| `0xd720f0` | 73 | `FMT_1_reverse, FMT_1, FMT_8, FMT_1_5_5_5, FMT_5_6_5, FMT_6_5_5` (texture formats) |
| `0xd589dc` | 87 | `undefined, null, true, false, string, number` (script value-type enum) |
| `0xd71d30` | 50 | `add, add_prev, mul, mul_prev, mul_prev2, max` (blend/curve op enum) |
| `0xc60150` | 46 | `none, aquire, follow, kill, face, flee_from_pos` (AI behavior enum) |
| `0xd6de70` | 42 | `Sun, Mon, Tue, Wed, …` (calendar) |

The AI behavior enum (`aquire`[sic], `follow`, `kill`, `face`, `flee_from_pos`, …) is a useful
cross-reference for [ai.md](ai.md).

---

## 4. Summary of what `.data` mining establishes

| Artifact | Recoverable from `.data`? | Evidence |
|---|---|---|
| Layout: initialized window = 2.29 MB of 19 MB; rest BSS | **Yes** | PE header parse; 73.5% words zero |
| Havok reflection **schema** (names+types) | **Yes, complete** | 1,287 classes, 38,907 `hkClassMember` (stride-6/24B), 2,232 names |
| Per-field **defaults via reflection** (name→value) | **No** | offsets all `0x0000`; `hkClass.defaults*` chain not present as literal VAs (3/1287) |
| Authored C++ global **tuning default *values*** | **Yes (values only)** | float blocks @ `0xb99908+` (2π, π/180, timers, magnitudes) |
| **Pandemic** game-tuning defaults (weapons, vehicle stats) | **No (not in this PE)** | `EngineTorque`/`MaxSpeed`/etc. = 0 occurrences in `.data`; in WAD blocks instead |
| Enum value-name tables | **Yes** | texture-format / AI-behavior / script-type string arrays |

**Bottom line:** `.data` is the engine's **Havok reflection schema store + precomputed math
tables + a handful of compiled-in global tuning constant blocks**. It cleanly answers *"what
fields does class X have, and of what type"* for 1,287 Havok classes, and it does contain real
authored numeric defaults — but the schema half has the names without inline values, and the
tuning-block half has the values without resolvable names, and the actual *gameplay* tuning
defaults (weapons, vehicle handling) live in the WAD reflection blocks, not this binary.

---

### Reproduction

All figures were produced by reading `output/jul08_prototype/mercs2_xenon_p.pe_full.bin` in
Python with the `.data` window `file[0xb2ce00 : 0xb2ce00+0x232a00]`, decoding words big-endian
(`struct.unpack('>I'/'>f', …)`), and resolving `.rdata` string-pointers via
`va - 0x82000600` into `file[0x600 : 0x600+0x117ddc]`. Key steps: (a) word census by class;
(b) consecutive string-pointer gap histogram → stride 6; (c) 24-byte `hkClassMember` decode +
type-byte histogram; (d) `EngineTorque`/`MaxSpeed`/… absence test; (e) contiguous plausible-float
run scan for §2; (f) stride-1 string-pointer runs for §3; (g) Havok version markers via
`re.compile(rb'Havok-\d+\.\d+\.\d+-[a-z]\d+').finditer(file)` (25 distinct, families 3.3–5.5),
cross-checked against the set of BE words present in the `.data` window to confirm each is
referenced as a literal VA.
