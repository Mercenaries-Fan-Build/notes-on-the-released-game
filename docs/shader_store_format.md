# Shader store format (`shader3*.bin`, `shaderVT*.bin`, `shaderR2VB*.bin`)

**Status:** complete for the retail PC build. Every structural claim below is checked against all six
retail stores by the `mercs2_formats` tests (`shader3` + `sm3asm` modules in
`tools/wad_simulator/crates/mercs2_formats`), or against the decompiled/disassembled exe where noted.

Confidence labels: **PROVEN** = checked against bytes or code; **INFERRED** = reasoned from code but not
exercised live.

---

## 1. The files and when they load

The PC build ships six stores in the game's `data` folder. The shader registry `FUN_0084f130` loads
them into one pool (`DAT_01977a38`) through the loader `FUN_0085b3f0`, before registering any shader
names. Decoding the function's first 0x77 bytes gives the order (**PROVEN**, x86 decode of
`FUN_0084f130`; path strings at `0x00be343c`…`0x00be3488`):

| Order | Store | Condition |
|---|---|---|
| 1 | `shader3.bin` | always |
| 2 | `shader3Low.bin` | always |
| 3–4 | `shaderVT.bin`, `shaderVTLow.bin` | caps word `DAT_01176288+0x5e4` bit 2 set |
| 3–4 | `shaderR2VB.bin`, `shaderR2VBLow.bin` | bit 2 clear and bit 3 set |

So two or four stores are resident at once, and the high and Low sets are **both** loaded. The VT and
R2VB pairs are alternatives: they share one record id, and never load together.

| Store | Records | VS | PS | Bytes |
|---|---|---|---|---|
| `shader3.bin` | 556 | 151 | 405 | 2,565,008 |
| `shader3Low.bin` | 411 | 156 | 255 | 856,480 |
| `shaderVT.bin` / `shaderVTLow.bin` | 15 each | 15 | 0 | 62,272 |
| `shaderR2VB.bin` / `shaderR2VBLow.bin` | 13 each | 13 | 0 | 49,008 |

## 2. Container

All little-endian.

```text
u32 count
count × Record {
    u32 id         // see §4
    u32 blob_off   // from the start of the file
    u32 blob_size  // bytes
    u32 kind       // 1 = vertex shader (vs_3_0), 0 = pixel shader (ps_3_0)
}
blobs
```

`FUN_0085b3f0` walks the records in order. For each one it copies the blob into a scratch buffer, then
calls `IDirect3DDevice9::CreateVertexShader` (vtable `+0x16c`) for kind 1 or `CreatePixelShader`
(`+0x1a8`) for kind 0. On success it files the returned handle under `id` (`FUN_0085b810`). On failure
it logs `Error Loading Shader: %08X` and files nothing. Any other `kind` value creates nothing.

### Retail layout rules (PROVEN: all six stores rewrite byte-identically from these rules)

- The first blob starts at the first 16-byte boundary after the record table.
- Each blob starts on a 16-byte boundary; the gap before it is zero-filled.
- Blobs appear in record order, so record order = offset order.
- The file is zero-padded to a multiple of 16.
- No store repeats an id.

## 3. Blob

A blob is a complete Direct3D 9 Shader Model 3 token stream: version token, comment blocks,
instructions, end token `0x0000ffff`. The version token matches the record kind: `0xfffe0300`
(`vs_3_0`) for kind 1, `0xffff0300` (`ps_3_0`) for kind 0.

### Constant table (CTAB)

Every retail blob carries a `CTAB` comment block (1,023 of 1,023). In 1,016 it directly follows the
version token; in the other 7 a `DBUG` comment block comes first. Every CTAB was written by
`Microsoft (R) HLSL Shader Compiler 9.19.949.2111`, with header flags `0x20000110` (1,012),
`0x20000115` (7) or `0x20000130` (4). No constant has a default value. The `Reserved` field of a
`D3DXSHADER_CONSTANTINFO` is often non-zero, and a rewriter must keep it verbatim.

The engine reads the table at runtime: `FUN_0085af00` and `FUN_0085b1a0` fetch a bound shader's
bytecode (`GetFunction`) and pass it to `D3DXGetShaderConstantTable` (**PROVEN** from the decomp).

**Layout rule (PROVEN: it reproduces all 1,023 retail CTABs byte for byte):**

1. A 28-byte header (`Size` = 28, `Creator`, `Version` = the shader's version token, `Constants`,
   `ConstantInfo`, `Flags`, `Target`). `ConstantInfo` is 28, or 0 when there are no constants.
2. The `ConstantInfo` array, 20 bytes per constant.
3. For each constant, in order: its name, then its type. A type is written as follows. For a struct,
   first each member's name and type (recursively), then the member array (`{name, type}` × n). The
   type's own 16-byte `TypeInfo` comes last.
4. The target string (`vs_3_0` / `ps_3_0`), then the creator string.
5. Every string is written once; a repeat reuses the first offset. Every 16-byte `TypeInfo` is written
   once in the same way. Each array (a member array or a `TypeInfo`) is aligned to 4 bytes with `0xab`
   filler. The table ends on a 4-byte boundary with `0xab` filler.

## 4. Record ids

```text
id = pandemic_hash_m2(stem + "_3.sho")    // shader3.bin, shaderVT.bin, shaderR2VB.bin
id = pandemic_hash_m2(stem + "_3l.sho")   // shader3Low.bin, shaderVTLow.bin, shaderR2VBLow.bin
```

`stem` is the `.sho` file name a shader is registered with, minus `.sho`. `pandemic_hash_m2` is the
Mercenaries 2 FNV-1a variant (case-folded; `mercs2_formats::hash`).

The mechanism is **PROVEN** from `FUN_0085b6f0`, the lookup that `FUN_0085af00` and `FUN_0085b1a0` use.
It copies the registered `.sho` name and cuts its last four characters. If the global flag
`DAT_00dfc345` is 0 it appends `DAT_00be87e8` = `"_3l.sho"`, otherwise `DAT_00be87f0` = `"_3.sho"`.
It then hashes the result with `FUN_00824270`, whose body `FUN_0082427f` is `pandemic_hash_m2`. It
probes a 0x1200-slot table with `FUN_008242b0`, and a miss returns a null handle.

Examples:

| Registered `.sho` | `shader3.bin` id | `shader3Low.bin` id |
|---|---|---|
| `PgMeshVP.sho` | `0x2af7398f` (record 415, VS) | `0x9b0d5961` (record 290, VS) |
| `PgSkyFP.sho` | `0xc91c0187` (record 481, PS) | `0xa759fdb9` (record 353, PS) |
| `PgBlurHFP.sho` | `0xf7e57a75` (record 18, PS) | `0x5e6ec3e3` (record 18, PS) |

**Coverage (PROVEN):** hashing the 543 distinct `*.sho` strings in the exe names 515/556 `shader3.bin`
ids, 372/411 `shader3Low.bin`, 13/15 of each VT store and 13/13 of each R2VB store. No id matches with
the other store's suffix. The unmatched records have no `.sho` string in the exe.

The logical name and the file stem differ in places. For example, `PgMeshNoTangentVP` is registered
with `PgMeshVPNoTangent.sho`. Materials use the logical name (§6); stores use the file stem.

## 5. Loader limits

| Limit | Value | Source | Effect of exceeding it |
|---|---|---|---|
| Blob size | ≤ 0x8000 bytes | `FUN_0085b3f0` `memcpy`s every blob into one 0x8000-byte buffer with no size check | heap overflow |
| Records resident at once | < 0x1200 across every loaded store | `FUN_0085b810`: `id % 0x1200`, linear probe, no give-up | a full table never finds a free slot, so the insert never returns |
| Duplicate id | first loaded wins | `FUN_008242b0` probes from `id % 0x1200`, returns the first match and stops at an empty slot; an earlier-loaded record sits earlier on the probe path | the later record is dead |
| Version token | must match `kind` | the D3D create call for the kind | the create fails, is logged and nothing is filed |

Blob size and table behaviour are **PROVEN** from the decomp. The consequences in the last column are
**INFERRED** from the code; none was triggered live.

A replacement therefore goes in place: swap the blob of the existing record, and keep its id and
position. A new shader is appended under an id that no resident store holds.

## 6. How materials bind pixel shaders

A `MTRL` record (`Mtrl_Parse` = `FUN_00858790`; layout also in
`reverse_engineer/valid_model_structure_map.md`):

```text
+0      104 B    preamble (26 × u32 of colour/emissive/specular parameters)
+104    u16      flags
+106    u16      tex_count (1..=10)
+108    u32 × tex_count   texture hashes
...     u32      pixel-shader key
...     u32      (stored at material +0x7c)
```

- **The first preamble word is not a shader.** `Mtrl_Parse` copies it to material `+0x64` and looks
  nothing up with it. In the model-build templates that word is `0x0a164785` (static) or `0x406b230e`
  (skinned); neither selects a shader. (**PROVEN** from the decomp.)
- **The pixel shader is the word after the texture hashes.** `Mtrl_Parse` looks it up with
  `FUN_008242b0(0x800)` in the pool's name registry. It stores the found entry's u16 at `+8` into
  material `+0x182`.
- The key is `pandemic_hash_m2(<logical PS name>)`, as registered by
  `FUN_0085ac90(logical_name, name.sho, variant)`. Two examples: `0xCAEFE1FE` =
  `PgDiffSpecNormFP` (the static template) and `0x322FCD56` = `PgDiffSpecReflNormAmbOccRimFP` (the
  skinned template). (**PROVEN**: hash equality with the words in the templates.)

The chain from a material to bytecode (the link between the registry and the store table is
**INFERRED** from the shared 0x1200 modulus):

```text
material PS key ──FUN_008242b0(0x800)──► registry entry (logical name, name.sho, variant)
name.sho ──FUN_0085b6f0──► pandemic_hash_m2(stem + "_3.sho" | "_3l.sho") ──► store record ──► D3D handle
```

## 7. The `0x00858DB8` crash

When a material's pixel-shader key was never registered, the `FUN_008242b0(0x800)` lookup misses.
`Mtrl_Parse` then falls back to the pool slot `DAT_01977a3c`, which holds null, and reads the entry's
u16 at `+8`. That read is `mov cx,[eax+0x08]` with `eax = 0` at `0x00858DB8`. The instruction and
register state are from the live crash in `patch_wad_globalenter_livelock_analysis.md` §9. The source
line is `*(u16 *)(*piVar17 + 8)` after the lookup in `FUN_00858790`.

Ways to get an unregistered key:

- a key made up or copied from something other than a registered logical name;
- a `tex_count` that disagrees with the number of hashes written. The parser then takes a texture hash
  or a float from the key slot.

A missing store record does not cause this crash. It makes `FUN_0085b6f0` return a null handle, which
`FUN_0085af00` / `FUN_0085b1a0` skip.

## 8. Writing a store

A conforming writer:

- lays out blobs as in §2, so an unmodified store rewrites byte-identically;
- refuses a blob over 0x8000 bytes;
- refuses a blob whose version token does not match its `kind`;
- replaces in place, and refuses a replace whose id is not in the store;
- refuses a new or replaced id that any store resident at the same time already holds. The resident
  sets are {`shader3.bin`, `shader3Low.bin`} plus either the VT pair or the R2VB pair;
- keeps the records of all resident stores together below 0x1200.

`mercs2_formats::shader3::StoreBuilder` implements this list. `mercs2_formats::sm3asm` assembles SM3
text into blobs, including a CTAB laid out as in §3. It also disassembles every retail record to text
that reassembles byte-identically. `shaderforge asm` and `shaderforge store-id` are the CLI entry
points.

## 9. Registration

The store records become shaders the engine draws with only through the **registry**: a name the
engine keys the shader by, bound to a `.sho` stem. `FUN_0084f130` (called once, from the renderer
constructor `FUN_007492d0` at `0x0074957a`) loads the stores and then makes every registration.

### The call

Each registration is (**PROVEN**, x86 decode of `FUN_0084f130` and `FUN_0085ac90`):

```text
push class; push sho; push name; mov ecx, <record>; call FUN_0085ac90
FUN_0085ac90(this = record, name, sho, class)       // __thiscall, ret 0xc
    record+0x04 = pandemic_hash_m2(name)             // the registry key
    record+0x8c = class                              // the light class
    strcpy(record+0x0b, sho)
    record->vtbl[+8](record+0x0b, 0)                 // load: resolve the store record, assign the index
```

`record` is a **static object**, one per registration, built by a CRT static initializer: the base
constructor (`FUN_0085ace0` for a pixel shader, `this` in `ECX`; `FUN_0085ade0` for a vertex shader,
`this` in `EAX`) sets the index word `+8` to `0xffff` and zeroes the record, and the initializer then
stores the family vtable. Emulating every initializer that builds a record the registry names
reproduces the vtables the runtime image holds for all 374 of them (**PROVEN**).

Several registrations sit in SecuROM islands that the decompiler renders as empty (`FUN_02475bc0`,
`FUN_005726e0`, `FUN_006188b0`, `FUN_02485980`, reached from `FUN_0084f130` through `jmp [stub]`
thunks); they call `FUN_0085ac90` through `push <continuation>; push FUN_0085ac90; ret`. The committed
table `crates/mercs2_quartermaster/data/registered_shaders.tsv` is written by executing the registry
under each configuration (`tools/extract_shader_registry.py`): 411 registrations, of which each
configuration makes 227 (ShaderLevel off) or 371 (ShaderLevel on). The ShaderLevel-on count, 242
pixel and 129 vertex names, is the live count of the registry in a runtime image of the game.

### Families

The record's vtable is its **family**. There are 45: 19 load as vertex shaders (vtable `+8` =
`FUN_0085af00`) and 26 as pixel shaders (`+8` = `FUN_0085b1a0`). Each vtable has six slots: the
destructor, `FUN_0085ac90`, the load, the reload (clear the handle, load again: the device-reset
path), the constant binder, and the set call (`SetVertexShader` / `SetPixelShader`). The families,
their record sizes and their binders' constants are `crates/mercs2_quartermaster/data/shader_families.tsv`.

| record field | pixel | vertex |
|---|---|---|
| `+0x04` key, `+0x08` u16 index, `+0x0b` sho, `+0x8c` class | both | both |
| `CTAB` interface | `+0xf4` | `+0x10c` |
| D3D shader handle | `+0xf8` | `+0x110` |
| base size | 0xfc | 0x114 |

### The registries

Both registries live in the pool `DAT_01977a38` (**PROVEN**, `FUN_0085ab00` / `FUN_0085ab70` /
`FUN_0085abd0`):

| | pixel | vertex |
|---|---|---|
| count | `0x01977a38` | `0x0197da40` |
| key table (probe) | `0x01979a40`, 0x800 slots | `0x0197de48`, 0x100 slots |
| index → record | `0x0197ba40`, 0x800 entries | `0x0197e248`, 0x100 entries |
| assign | `FUN_0085ab70` | `FUN_0085abd0` |
| insert | `FUN_0085b7c0` (`& 0x7ff`) | `FUN_00632250` (`& 0xff`) |

The load handler assigns the index when the record's index is `0xffff`: a key already present
returns its index, otherwise the index is the count, the record goes into the index table, and the
insert increments the count. So registrations of new keys made back to back get **consecutive**
indices. Neither insert gives up on a full table: the registries hold 0x800 pixel and 0x100 vertex
names, and one more hangs.

### Light classes

The draw (`FUN_00855420`) selects a material's pixel shader as
`index_table[material+0x182 + light]`, where `light` is the draw's light class (`item_light+0x2a0`)
and is forced to 0 when the ShaderLevel byte `DAT_00dfc345` is 0. So a lit pixel shader is four
registrations in a row — base, `_pl` (1), `_sl` (2), `_pl_sl` (3) — and the registry makes classes
1–3 only when `DAT_00dfc345 != 0`.

A registration of a `_li` `.sho` follows some `_pl`/`_sl`/`_pl_sl` registrations:
`if (record+0xf8 == 0) FUN_0085ac90(record_li, name, name_li.sho, class)`. It runs only when the
plain record has no D3D handle — its stem has no store record — and it has the same name, so it gets
the plain registration's index. In retail every plain `_pl`/`_sl`/`_pl_sl` stem has a record, so no
`_li` registration is made.

`DAT_00dfc345` is written by the settings load (`FUN_00753280`, `[Render] ShaderLevel`, default 1)
and by the settings apply `FUN_0074c7ac`, which copies the whole settings block `0x00dfc320` and
forces it to 0 when caps word `+0x5e4` bit `0x40` is clear. A change after registration is not
followed by a new registration; a device reset reloads each record's handle with the current store
suffix (**PROVEN** statically; the effect in game is not observed).

### Adding registrations

The m2-sdk's `shader-registry` capability calls `FUN_0085ac90` for an author's shaders right after
`FUN_0084f130`'s own registrations, on process-lifetime records it builds the same way as the static
ones, which is what `add_shader` targets (see
[`modding/manifest_format.md`](modding/manifest_format.md#add_shader)).

## 10. Constant binding

The load handler reads the shader's constant table (`GetFunction`, then
`D3DXGetShaderConstantTable`) and calls the family's binder (vtable `+0x10`). The binder resolves a
fixed list of names, each through `FUN_0085ac40` (`EAX` = name, `ESI` = the constant table, `EDI` =
the output): `GetConstantByName`, then `GetConstantDesc`, storing the handle and the register index
in the record (**PROVEN**). The draw sets constants through those fields; a `CTAB` constant that is
not in its family's list is set only by code that addresses its register directly. Of the 772 retail
records a registration loads, 766 declare only their family's constants; the other six are three
shaders in both stores: `PgColorFPConst` (`color`), `PgLtiDebugZPassFP` (`depthRange`) and
`PgLtiTerrainShadowVP` (`PositionOffset`) (**PROVEN**, each record's `CTAB` against its family's
list). The base vertex binder is `FUN_0085aff0` (15 names:
`objectData`, `LocalToWorld`, `viewContextData.ViewProj`, …); the base pixel binder is
`FUN_0085b290` (12 names: `materialData`, `globalLightData`, `pointLights`, …). Every family's list
is in `shader_families.tsv`. Samplers are bound by texture stage, not by this list.
