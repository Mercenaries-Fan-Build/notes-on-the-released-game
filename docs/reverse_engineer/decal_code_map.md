# Scoreboard #6 — projected decals: PC code map

**Scope:** the PC-side projected-decal system in `Mercenaries2.exe` (unpacked image, base 0x400000).
Scoreboard row 6 (was ❌ none). Binds the Xbox PDB names
([rendering-shaders.md](../mercs2-pdb-analysis/rendering-shaders.md) §Decals) to PC addresses.
Companion JSON `docs/data/sky_decal_water_code_map.json`.

## 0. Boundary

The **setup** half is statically recovered: the `decaltable` ASET loader, the decal shader
registration, and the two ECS decal-toggle components. The **create/project/render/GC** half has its
profiler-marker strings stripped from the retail PC build (`CreateDecals`, `DecalJob`, `DamageShadow`
are Xbox-PDB-only) and is data/vtable-driven → confirm-live with the exact break points below.

## 1. Decal definition table (`decaltable` ASET, type `0x3B0AABF8`)

Registered as a **resident singleton** type-class inside the big ASET registrar `FUN_004bef00`
(2336 B). Its `GetTypeHash` vfn is **`FUN_004cb1b0`** (`return 0x3b0aabf8`, called at 0x004bf4f1).
Its instance resolver is **`FUN_004cb1f0`**: matches the incoming type, allocates via
`FUN_008242b0(0x400)`, stamps the resident flag `|0x4000` at `obj+0x16`. That resident block **is**
`PgDecalTable` (@0x9288b8 in .data) — the array of decal-material definitions (bullet holes / blood /
scorch / tire tracks; per-type texture handle / size / lifetime / super flag). The table is accessed
via computed offsets inside stripped functions, never by name → **confirm-live** (bp `FUN_004cb1f0`,
read the resident block).

## 2. Decal shaders + permutations

- **`FUN_02475bc0`** (SecuROM 0x024 island) = the decal shader register: body is
  `FUN_0085ac90(PgDecalVP, PgDecalVP.sho, 0)`. `callers=[]` because it is invoked through the
  **duplicate `.sho` descriptor table @0x0103xxxx** — the same data-driven mechanism as PgFX, not a
  direct call. `FUN_0085ac90` is the shared per-shader register helper into pool `DAT_01977a38`.
- **`PgDecal2FP` + `_pl`/`_sl`/`_pl_sl`/`_li`** light permutations (Xbox 0x166f8..0x16684) appear only
  as `.sho` descriptor-table rows on PC, selected the same way as the mesh per-pixel-light shaders
  (the `DAT_00dfc345` gate). Material params `decalNormal` (0xbac5d4) / `decalParam` (0xbac5f0) are
  data-only bind slots (normal + param map). `_super` = the `EnableSuperDecal` higher-coverage variant
  (matches the `global_decal_super_concrete` MTRL seen in the PMC hall).

## 3. ECS decal-toggle components (fully mapped)

| component | m2 hash | registrar | deserializer | role |
|---|---|---|---|---|
| **DisableDecals** | 0xff4533e5 | `FUN_00643bd0` (CopyFromStream `PTR_00bc18d8`, stride 4) | `FUN_0063d060` (`Read(buf,4,0)`) | 4-B tag suppressing decal render on the entity |
| **Disable3DDecals** | 0x69a0e0e4 | `FUN_00643c80` (CopyFromStream `PTR_00bc1928`, stride 4) | `FUN_0063d0d0` | 4-B tag disabling the projected/"3D" decal pass |

(Note: `0xff4533e5` is *also* a config token via `FUN_00826820(0xff4533e5,0)` → global bool
`DAT_01175c37`, a parallel command-line switch — low confidence.)

## 4. Create / project / render / DamageShadow — stripped (confirm-live)

| Xbox PDB (RVA) | role | PC status |
|---|---|---|
| CreateDecals / RecreateDecals (0x21778 / 0x1e40c) | spawn-at-hit-point + rebuild | strings stripped, data/vtable-driven |
| EnableSuperDecal (0x1e41c) | higher-coverage super variant | stripped |
| DecalJob (0x16620) | parallel decal build/render (a pimp Jobtype) | **not among the recovered pimp Jobtypes** — registered from a relocated site or a render vtable |
| DecalsUpdate / DecalUnlock (0x16610 / 0x16604) | per-frame aging/GC | stripped |
| DamageShadow / ProcessDamageShadowCast (0x21400 / 0x21410) | **a projected decal** (scorch/damage darkening), grouped in the decal `.rdata` cluster — NOT a shadow-map pass | stripped |

## 5. Xbox → PC bindings

| Xbox PDB | PC |
|---|---|
| decaltable GetTypeHash (0x3B0AABF8) | `FUN_004cb1b0` |
| decaltable resolver / resident alloc | `FUN_004cb1f0` (via `FUN_004bef00`) |
| PgDecalVP register | `FUN_02475bc0` → `FUN_0085ac90` |
| PgDecalTable (.data @0x9288b8) | resident block from `FUN_004cb1f0` (data-only) |
| DisableDecals / Disable3DDecals | `FUN_00643bd0`+`FUN_0063d060` / `FUN_00643c80`+`FUN_0063d0d0` |
| CreateDecals / DecalJob / DamageShadow / … | **unbound** (stripped) |

## 6. Confirm-live inventory

1. `PgDecalTable` structure — bp `FUN_004cb1f0`, read the resident block: array of decal-material
   defs (texture / size / lifetime / super flag per type).
2. `DecalJob` handler — bp the pimp dispatch (`&PTR_LAB_019f904c` handler table, see
   [pimp_job_system_code_map.md](pimp_job_system_code_map.md) §2) and catch the decal Jobtype hash.
3. `CreateDecals` / `DamageShadow` / `EnableSuperDecal` spawn callers (weapon impact / explosion /
   tire) — trace live from a bullet-hole impact.
4. The `_pl`/`_sl`/`_pl_sl`/`_li` permutation-select for `PgDecal2FP` — verify it reuses the mesh
   `DAT_00dfc345` per-pixel-light gate against a live decal draw.

Corpus already carried the two components ([docs/mercs2-ecs/08_misc_uncategorized.md](../mercs2-ecs/08_misc_uncategorized.md)),
the type hash ([type_hash_registry.md](../type_hash_registry.md) §0x3B0AABF8), and the shader table;
[rendering_fx_lighting_gap.md](../modernization/rendering_fx_lighting_gap.md) §G is the reimpl target
(a projected-decal pass + the decaltable-driven material set).
