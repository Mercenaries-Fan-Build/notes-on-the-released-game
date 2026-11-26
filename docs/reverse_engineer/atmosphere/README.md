---
status: current
evidence: proven
---

# Mercenaries 2 atmosphere: retail behaviour spec (pc-v10, cross-checked on x360-retail)

Read 2026-11-25. Grades: **PROVEN** means verified in that run from code, bytes or the live dump. **INFERRED** means reasoned from code but not checked against data. **SPECULATIVE** means a guess. **NOT DETERMINED** means not found; §8 lists what was tried.

**Where the global default ships (read after §2.3 and §8 were written, which call it not found):**
the `worldentity` carries the entity `0x900000CF`, named `Atmosphere`, with one `AtmosphereBase`
record, `default` (InterpolateTime 20, LightIntensity 1.15, LightTime 0.2, as §5's live column has
them). It also carries 21 records on two templates: 7 on `Atmosphere (interior)` (`0x80008333`) and 14
on `Will_atmospheres` (`0x80008645`). `mercs2_probe we-template --class AtmosphereBase` lists them.
Whether a region entity placed from one of those templates answers to the template's settings is not
read.

The night / default field table of §5 is also [`records_table.md`](records_table.md). The run's working files and decoding scripts were not kept; the commands in §7 and the layouts in §2 give them again. They were:

| file | contents |
|---|---|
| `schm_fields.txt` | the schema |
| `atmo_records_full.txt` | all 56 shipped records, decoded |
| `glob_decoded.txt` | the live record of the global default |
| `verify_lerp.txt` | the blend check against the dump |
| `block29.bin` | layers_static, sha256 `a69d05bc…5738` |

The live pc-v10 Ghidra bridge could not open its project (`LockException`: another JVM holds it). PC decomp therefore comes from the corpus export (`corpus_get ghidra/pc-v10/…`), and x360 decomp comes from the live x360-retail bridge.

## 0. Headline corrections to the brief

1. **`Graphics.Atmosphere.SetSky` does nothing in every retail build.** PROVEN.
   - In pc-v10-drmfree, `0x006D5640` is `return 0`, size 3. It is the shared no-op used by `print`, `Debug.Printf`, `FuelTrail.Ignite` and 70+ other entries (`corpus_get ghidra/pc-v10-drmfree/0x006d5640`).
   - The x360-retail body at `0x828280B0` is `return 0` (live decompile), and PS3 ps3-v101-eu `0x0051a358` is `return 0`.
   - In the pc-v10 dump the bytes are `e9 7b ca 5f 6f` (`jmp 0x6FCD20C0`, outside the image; `objdump` of `mercs2_unpacked.exe`). That jump is the pmc_bb `print` detour (images.tsv build_id `dump-v10-pmcbb-unpacked`), not a hidden body.
   - The docs already say this: `docs/lua_engine_bindings_audit_deep_dive.md` §4.5.
   - So "afternoon", "night" and "Maracaibo" as SetSky arguments select nothing. No record is named `afternoon` (`0x3A5FD607`) or `Maracaibo` (`0x2E673A18`) (§2.3).
2. **Named settings are ECS component records, not an exe table and not a standalone asset.** PROVEN.
   - They are the `AtmosphereBase` component (type hash `0xB8D2B506`, PC container `0x00DF8E10`, stride 740, cap 32; `docs/reverse_engineer/object_entity_core_code_map.md:1668`).
   - The records sit on the `rgn_atmo_*` LineRegion entities in the placed layer `vz_atmosphere_regions` (layer `0x7A776CC6`, vz.wad block 29 `layers_static`, sub-block 172).
   - Each region entity carries one or more records. Each record is keyed by the entity and named by a `pandemic_hash_m2` Name (`default`, `night`, `warzone`, `pmc`, …).
3. **There is no fog colour/start/end and no sky texture in the data.** The sky and fog are the analytic scatter model: Rayleigh/Mie betas, Henyey-Greenstein g, inscatter/extinction multipliers, `AtmosphereLimit/Force` and `HazeLimit/Force`. The shader maths that turns these into fog is NOT DETERMINED (§8).

## 1. The three bindings (pc-v10, with x360-retail equivalents)

Binding table (luareg, `output/_exemap_exports/pc-v10.luareg.tsv:1203-1239`): `Graphics` table `0x00B9A4D0`. The Atmosphere sub-table is `0x00B9A578` (37 cfuncs).

| # | binding | pc-v10 | x360-retail |
|---|---|---|---|
|18|Begin|0x005B16D0|0x82319248|
|19|End|0x005B16F0|0x82319288|
|20|SetTime|0x005B1750|0x82319368|
|21|SetTimeSpeed|0x005B17C0|0x823193F8|
|22|SetLightIntensity|0x005B1830|0x82319488|
|23|SetLightModifier|0x005B18A0|0x82319518|
|24|SetLightAngle|0x005B1970|0x823195E0|
|25|SetAmbientColor|0x005B19E0|0x82319648|
|26|SetAmbientCube|0x005B1A80|0x823196E0|
|27|SetRimColor|0x005B1B20|0x82319798|
|28|SetTurbinity|0x005B1B70|0x823197F8|
|29|SetInscatteringMultiplier|0x005B1BE0|0x82319888|
|30|SetExtinctionMultiplier|0x005B1C50|0x82319918|
|31|SetBetaRayMultiplier|0x005B1CC0|0x823199A8|
|32|SetBetaMieMultiplier|0x005B1D30|0x82319A38|
|33|SetHenyeyGreensteinConst|0x005B1DA0|0x82319AC8|
|34|SetAtmosphere|0x005B1E10|0x82319B58|
|35|SetHaze|0x005B1ED0|0x82319BE0|
|36|SetWindDirection|0x005B1F90|0x82319C68|
|37|SetParticlesPerSecond|0x005B25C0|0x8231A368|
|38|Change|0x005B0C50|0x82318900|
|39|ChangeLineRegionSetting|0x005B0D20|0x82318988|
|40|GetLineRegionSetting|0x005B0E10|0x82318B40|
|41|GetLineRegion|0x005B0EC0|0x82318BB0|
|42|Restore|0x005B1020|0x82318C60|
|43|GetCurrentSetting|0x005B1090|0x82318CB8|
|44|EnableImmediatelyChangeMode|0x005B1100|0x82318D28|
|45|SetRainSpeed|0x005B2610|0x8231A3C8|
|46|SetRainDensity|0x005B2660|0x8231A428|
|47|GetValue|0x005B1150|0x82318DA0|
|48|SetValue|0x005B1200|0x82318E40|
|49|GetColorValue|0x005B12A0|0x82318ED0|
|50|SetColorValue|0x005B1430|0x82318FA0|
|51|GetIntValue|0x005B1540|0x823190B0|
|52|SetIntValue|0x005B15F0|0x82319150|
|53|IsInterpolating|0x005B1690|0x823191E8|
|54|SetSky|0x006D5640 (shared no-op)|0x828280B0 (`return 0`)|

### 1.1 Atmosphere manager object. PROVEN layout, from the PC dump and both decomps.

- PC: `*(u32*)0x00ED3B08` = manager. The live value is `0x014B7E7C` (`dump-read … 0x00ED3B08 16`).
- x360: `DAT_82F0D25C`.

| off | type | meaning | evidence | live value (New-Game capture) |
|---|---|---|---|---|
| +0x00 | ptr | vtable (PC `0x00BB13FC`) | dump | `fc 13 bb 00` |
| +0x10 | f32 | blend duration in seconds | x360 `FUN_8224CD48` writes it | 20.0 |
| +0x14 | f32 | blend elapsed in seconds | `FUN_8224D1B8` adds `dt` | 19.53459 |
| +0x18 | u8 | interpolating (`IsInterpolating` returns it, `0x823191E8`) | | 1 |
| +0x19 | u8 | set by `End()` (Lua batch, `0x82319288`) | | 0 |
| +0x1A | u8 | immediate-change mode | | 0 |
| +0x1C | u32 | current region entity key | | `0x000CC5DC` (`rgn_atmo_carmonaislandrain`) |
| +0x20 | u32 | current setting name hash | | `0xBB74C311` (`night`) |

Region tables. PROVEN (PC `FUN_006A4480` decomp; values from the dump):

| PC | x360 | contents |
|---|---|---|
| `0x00ED3A00[64]` | `DAT_82F0D158` | region keys |
| `0x00ED3900[64]` | `DAT_82F0D058` | each region's current setting hash |
| `0x00ED3B00` | `DAT_82F0D054` | count of dynamically added regions |
| `0x00ED3B04` | `DAT_82F0D258` | count of regions found at load |

- The live counts are 0 and 40. Forty is the 41 layer entities minus `rgn_atmo_GR Cave`, which has no AtmosphereBase.
- Slot 26 is `0x000CC5DC` and holds `0xBB74C311` (night). All other slots hold `0xBA71C11C` (default).

### 1.2 `EnableImmediatelyChangeMode(bool)`: PC `0x005B1100`. PROVEN.

- It reads the boolean through `FUN_0059F6D0`.
- It writes `manager+0x1A` = the value, or 0 if the argument is missing or not a boolean (x360 `0x82318D28` does the same).
- Effect, from x360 `FUN_8224CD48`: when +0x1A is nonzero, the next `Change` sets duration = 0.0 (`DAT_820BAF14`) instead of the target record's `InterpolateTime`. The per-frame tick then snaps: with `elapsed (0) >= duration (0)`, it copies to→from and applies t = 1.0 (§3.3).
- The scripts set it true at load and false when the load ends (`resident/mrxstate.lua:98/139`).

### 1.3 `ChangeLineRegionSetting(guid, "name")`: PC `0x005B0D20`, x360 `0x82318988`.

Arguments (x360 readers; `crates/mercs2_exemap/data/lua_readers.tsv`): PROVEN.
- arg1 is a handle (`0x82308A80`).
- arg2 is a string hashed with pandemic_hash_m2 (`0x82308518`).
- On PC: `FUN_0059FF50` (handle) and `FUN_0059FB00` (name).

x360 body: PROVEN by decompile.
1. Call `FUN_823DA3C8(AtmosphereBase container 0x836558F8, region, setting)`. This looks up the record whose key is `region` and whose Name is `setting` (multi-valued container: it iterates the key's slots and compares the per-slot Name).
2. If found:
   - If region == 0, use the current region (`manager+0x1C`).
   - Store the setting into `regionSetting[i]` for that region's slot (searching 64 slots).
   - If the region is the current one and the setting differs, call `Change(manager, region, setting)` immediately.
3. Then clear the region's "inside last frame" bit (object `FUN_82467AB0()`, bitset at +0x248). The tick therefore sees a fresh enter next frame and re-applies the region's new setting if the viewer is inside.

PC body: INFERRED equivalent. The structure is the same: `FUN_004EC850` and `FUN_006CD960`/`FUN_006CDAF0`, then `FUN_006A4420(region)`. Part of the PC body is a SecuROM split stub (`thunk_FUN_02DA0000`).

What it writes: `regionSetting[]`, optionally the manager (+0x10..+0x20, the from/to buffers), and the tick's inside bitset.

### 1.4 `Change(guid, "name")`, the core: x360 `FUN_8224CD48`; PC `FUN_004EBF90` (SecuROM split stub). PROVEN on x360.

The PC stub is a 22-byte forwarder whose moved body references the from-buffer at `0x004EBFD8`/`0x004EC024`: `dump-find 0x00DCD420`.

1. `old = lookup(manager+0x1C, manager+0x20)`, `new = lookup(region, setting)`. If neither exists, return.
2. If the from-buffer has never been filled (`from.Name == 0`): `from := old ? old : new` (via `FUN_8224DD98`).
   Otherwise, if interpolating: `from := lerp(from, to, elapsed/duration)` (`FUN_8224EB80`; t = 0 when duration ≤ 1e-5). Mid-blend changes therefore continue from the current look.
3. `to := new ? new : old`.
4. Set `duration = immediate ? 0.0 : to.InterpolateTime` (the to-buffer's +0x14 field, i.e. record +0x04).
5. Set `elapsed = 0`, `interpolating = 1`.
6. `FUN_8224D650`: (re)spawn the up-to-five AmbientEffect particle systems from the to-record (type 0 → `FUN_821DA518(radius,height)`, type 1 → `FUN_821DA768(radius,height,variance)`).
7. Post two region enter/exit events when the event flag is set.
8. Set `manager+0x1C = region`, `+0x20 = setting`.

`Restore([t])` (`0x82318C60` → `FUN_8224D150`): forces the from-buffer reload (`from.Name := 1`), re-runs `Change(current)`, and if `t >= 0` overrides duration = t. The default t is −1.0 (`DAT_82DE896C`).

`GetCurrentSetting()` returns `(guid at manager+0x1C, hash at +0x20)` (`0x82318CB8`).

### 1.5 Typed setters and the KVP setters (cross-check)

The typed setters write the live params struct `L = *(*(u32*)0x00E7ADFC + 0x104)` directly when no `Begin()` batch is open. Otherwise they store to staging. The rows below were PROVEN on x360 decomps this run. The PC offsets are identical (PC SetTime writes `L+0x10`; pc-v11 SetLightAngle writes `L+0x18`).

| setter | writes |
|---|---|
| SetTime | L+0x10 |
| SetLightIntensity | L+0xE0 |
| SetLightAngle | L+0x18 (in the capture: −150.0) |
| SetLightModifier | L+0x50..0x5C (vector3 + 1.0), which is LightMultiplier |
| SetWindDirection(x,y,force) | L+0x17C/+0x180 = normalised (x,y), L+0x184 = force |
| SetAmbientColor / SetRimColor | staging only on x360 (`DAT_83650430`/`0x836504B0`) |

- **Correction to `sky_post_hdr_code_map.md` §1:** it lists LightModifier at +0x124. The capture shows LightMultiplier at +0x50 and ScatterTurbinity at +0x124 (§3.2).
- `Begin()` (`0x82319248`) snapshots the current look into the staging buffer `0x82DE32D0` and sets the in-batch flag `DAT_831342BD`.
- `SetValue`/`SetColorValue`/`SetIntValue` write staging fields by name.
- `End(t)` copies staging into the to-buffer, sets duration = t (staging +0x14), and starts a blend (`0x82319288`).
- `SetColorValue(key, a1, a2, a3, a4)` packs `a1 | a2<<8 | a3<<16 | a4<<24` (`0x82318FA0`). The colour reader `0x82308818` packs `r | g<<8 | b<<16 | 0xFF<<24`.

**Colour channel order: byte 0 = R.** PROVEN by code and by the dump: the night AmbientColor `0xFFC4A29D` arrives in the to-buffer as (0.61569, 0.63529, 0.76863, 1) = (157, 162, 196, 255)/255.

## 2. Where the settings live and the record layout

### 2.1 Location. PROVEN.

`vz.wad` → block 29 (`layers_static`) → sub-block 172 → `COMP` with `info` "AtmosphereBase":
- `schm` at block offset 7917450: u32 field count 185, u32 stride 740, then 185 × `{u32 type, u32 name_hash, u32 0, u32 offset}`.
- `data` at 7920418, size 41664 = 56 × (u32 entity key + 740-byte payload).
- Commands: `mercs2_probe comp-dump AtmosphereBase`, `mercs2_probe dump-block 29 block29.bin`, then `scripts/find_schm.py` and `scripts/schm_names.py`.

Each entity's region polygon is its `LineRegion` component (stride 4): a `lineregion` asset hash (type `0x6310807F`, `u16 kind(2), u16 n, u32 0, n×{f32 x, f32 z}`; `crates/mercs2_formats/src/be_to_le/convert.rs:2834`). `rgn_atmo_carmonaislandrain` → lineregion `0xB32EACF8` (`mercs2_probe layer vz_atmosphere_regions`).

### 2.2 Schema: all 185 fields named

The field names were resolved by `pandemic_hash_m2` of the exe's own strings. 184 matched verbatim. `ScreenEffectNType` matched when built by pattern (`ScreenEffect0Type` → `0x2977A43E`).

Type codes: 5 = i32, 6 = u32 (a name hash or a packed RGBA with byte0 = R), 7 = f32, 9 = enum. All fields are 4 bytes.

The record offset below is the payload offset, after the u32 key. In the from/to buffers, the record sits at buffer+0x10.

| rec off | field | type | live destination / use (§3) |
|---|---|---|---|
|0x000|Name|6|the setting name hash|
|0x004|InterpolateTime|7|blend duration when this record is the target|
|0x008-0x014|LightMultiplier_X/Y/Z/W|7|L+0x50..0x5C (lerped)|
|0x018|LightIntensity|7|L+0xE0|
|0x01C|LightTime|7|L+0x10 Time (only while L.TimeSpeed == 0)|
|0x020|LightTimeSpeed|7|not seen consumed. NOT DETERMINED|
|0x024-0x030|SunEmissiveColor_X/Y/Z/W|7|L+0x60..0x6C|
|0x034 / 0x038|AmbientColor / AmbientColorMultiplier|6/7|buf+0x300 float4 = rgba/255 × mult → L+0x70|
|0x03C..0x068|AmbientCube0..5 / …Multiplier (pairs)|6/7|buf+0x310..0x36C → L+0x80..0xDC (6 × float4)|
|0x06C / 0x070|RimColor / RimColorMultiplier|6/7|buf+0x370 → L+0x110..0x11C (alpha × mult too)|
|0x074|ScatterHGg|7|L+0x120|
|0x078|ScatterTurbinity|7|L+0x124|
|0x07C|ScatterInscatteringMultiplier|7|L+0x128|
|0x080|ScatterExtinctionMultiplier|7|L+0x12C|
|0x084|ScatterBetaRayMultiplier|7|L+0x130|
|0x088|ScatterBetaMieMultiplier|7|L+0x134|
|0x08C|AtmosphereLimit|7|L+0x138|
|0x090|AtmosphereForce|7|L+0x13C|
|0x094|HazeLimit|7|L+0x140|
|0x098|HazeForce|7|L+0x144|
|0x09C..0x0C8|Water0..2_{Index1,Index2,Color1,Color2}|5/6|baked into a 256-entry LUT at buf+0x780 (`FUN_8224BF40`), lerped by `FUN_821F6BA8(t, from+0x780, to+0x780)`. INFERRED water colour ramp|
|0x0CC..0x118|Gradient0..4_{Index1,Index2,Color1,Color2}|5/6|LUT at buf+0x380, lerped into the post object at L+0x190 (+0x39). INFERRED colour-grade ramp: the index pairs 0/128 and 128/255 mirror `Graphics.Monochrome.SetGradient(0,128,…)/(128,255,…)` (`resident/mrxbootstrap.lua:94-95`). Not fog, not sky|
|0x11C-0x150|BloomBlurRadius, BloomThreshold, BloomMultiplier, BloomAmount, BloomTargetLuminance, BloomAdaptiveLuminancePercent/Scale/Min/Max/MinKeyScale/MaxKeyScale, BloomContastLimit, BloomContastMultiplier, BloomGrainyOpacity|7|post object at L+0x190: +0x04 ← BlurRadius, +0x08..+0x2C ← BloomAmount..ContastMultiplier (`FUN_8224C398`). Threshold, Multiplier and GrainyOpacity were not seen in that function|
|0x154|AshParticlesPerSecond|7|L+0x188|
|0x158|AmbientSound|6|sound hash. Consumer NOT DETERMINED|
|0x15C/0x160|WindDirection_X/Y|7|L+0x17C/0x180, normalised after the lerp|
|0x164|WindForce|7|L+0x184|
|0x168..0x228|ScreenEffect0..6 {Speed, Density, DirX, DirY, Texture(hash), Color, Type}|7/6/9|only slot 0 is applied, to the screen-effect object at L+0x194: +0x250 Speed, +0x258 Density, +0x200 DirX, +0x204 DirY, +0x20C Type, +0x208 Color (per-byte lerp); the texture switches from→to when t > `DAT_820D9EDC`|
|0x22C..0x27C|Coverage, Thickness, Shape, PhaseK, PhaseScale, DarknessK, ShadowK, Tone_R/G/B, LightBlend, OpacitySrcMin/Max, OpacityDstMin/Max, Scroll_U/V, Layer1..4_Scale|7|clouds: copied from the to-record, not lerped (`FUN_8224C060` reads `0x82DBAF20+0x23C..`) → cloud object `[L+4]+0x740` +0x530 (`FUN_8224D1B8`)|
|0x280..0x2E0|AmbientEffect0..4 {Type, Name(hash), Radius, Height, Variance}|9/6/7|particle emitters spawned by `FUN_8224D650` on each Change|

Rows that are PROVEN against the dump are marked in §3.2. The rest are INFERRED from `FUN_8224C398` and `FUN_8224DD98` only.

### 2.3 The shipped records (56)

From `atmo_records_summary.txt`:
- 40 entities have a `default` record.
- Extra records:

| entity | extra settings |
|---|---|
| `rgn_atmo_interior` (0x000C73BB) | chi, oil, pir, gur, all, oiljob, pmc, mec, small |
| `rgn_atmo_caracas` | warzone |
| `rgn_atmo_PMCinterior` | warzone |
| `rgn_atmo_Angelfalls` | WarzoneSolano |
| `rgn_atmo_Maracaibo` | warzonemar |
| `rgn_atmo_carmonaislandrain` (0x000CC5DC) | **night** |
| `rgn_atmo_Merida`, `rgn_atmo_Meridastadium` | one each of hash `0x9D92A2D5` (unresolved) |

- No record is named `afternoon` or `Maracaibo`.
- The out-of-all-regions setting is entity `0x900000CF`, record `default` (§3.1). It is not in block 29 (§8).

## 3. Line regions: selection and blending

### 3.1 Selection, per frame. PROVEN.

PC tick `FUN_006A4480` (x360 `FUN_8243D0C8`):
- Skipped when the owner's +0x58 flag is set or its +0x30 handle < 0.
- The test point comes from `FUN_00665AF0`. On x360 it is the position of the entity whose handle sits at owner+0x14 (`FUN_823F8370`/`FUN_8225E998`), with fallback `DAT_82E806A0`. Which entity that is (camera or player): NOT DETERMINED.

For each registered region i:
1. `prev[i] = cur[i]`.
2. `cur[i] = inside(i)`, where inside means:
   - the region's `LineRegion` asset is kind 2 or 4,
   - and `FUN_0045EBB0` (x360 `FUN_821AEE90`) passes: an XZ bounding-box reject (asset +0x3C minX, +0x34 maxX, +0x40 minZ, +0x38 maxZ), then an even-odd crossing-number polygon test over the (x,z) points (+0x1C count, +0x20 points).
   - There is no border width and no distance blend.

Then:
- **Enter** (`!prev && cur`): `Change(region, regionSetting[region])`.
- **Exit** (`prev && !cur`): `Change` is called for every region that is still inside, in table order, so the last one wins. If none is inside: `Change(0x900000CF, "default" 0xBA71C11C)`. The constant `-0x6FFFFF31` is in the PC decomp.
- The region list is built at load by `FUN_8224D320`: every distinct key in the AtmosphereBase container that has a kind-2/4 LineRegion, up to 64, each starting with setting `default`. Regions added later go through `FUN_8224D4B8`.
- Load reset (x360 `FUN_8220E950`): `Change(0x900000CF, default)`, then rebuild the region list.

### 3.2 Blend. PROVEN against the PC capture: 54/54 fields match (`verify_lerp.txt`).

The per-frame apply is x360 `FUN_8224D1B8`, called from the frame function `FUN_8221E340`:

```
if interpolating:
    if elapsed < duration:
        if duration > 0:
            t = immediate ? 1 : (duration > 1e-5 ? elapsed/duration : 0)
            apply(t)                           # FUN_8224C398: L = lerp(from, to, t), linear per float
    else:
        interpolating = 0
        from := to
        apply(1.0)
        if to.restoreTime >= 0:                # buf+0xB80
            Restore(to.restoreTime)
    elapsed += dt
clouds := to.clouds                            # no blend
```

- The time of day then advances in `FUN_8221E340`: if `L.TimeSpeed (+0x14) > 0`, `L.Time += TimeSpeed·dt`, wrapping to 0 above 1.0 and to 1.0 below 0.
- Constants on x360: `DAT_820BAF14` = 0.0 and `DAT_820BAEE8` = 1.0 (read at `0x820BAEE8`, 48 bytes); eps `DAT_820F8BB8` = 1e-5 (`0x3727C5AC`); 1/255 = `DAT_820CB628` (`0x3B808081`). These were read with `ghidra_read_bytes`. A tool hook flagged the responses as "short body", so treat the raw reads as INFERRED. The 1/255 value and t semantics agree with the dump.
- Capture check: from `0x00DCD420` and to `0x00DCDFB0` give live `L = 0x21739F30` at t = 0.9759. That equals (elapsed − one frame)/duration: elapsed 19.5346, duration 20, so the dump was taken after `elapsed += dt`.
- The from-buffer is a mid-blend snapshot (LightMultiplier 0.99987/0.9249/0.85013), not record 41. This is consistent with §1.4 step 2.

### 3.3 Immediate mode and durations

- Immediate mode only replaces the duration with 0, which gives a one-frame snap.
- Otherwise the duration is the target record's `InterpolateTime`. Every record in `rgn_atmo_carmonaislandrain` (night and default) and the global default use 20.0 s.
- Lua `End(n)` uses n seconds; `SetDefaultAtmosphere` in mrxbootstrap uses 8.

### 3.4 The rgn_atmo_carmonaislandrain entity. PROVEN.

Key `0x000CC5DC`, position (−1381.65, −75.15, 2165.56):
- Components: AtmosphereBase ×2, HibernationControl, Label, LineRegion → `0xB32EACF8`.
- At load its setting is `default`. In the opening mission `vzacon001.lua:25/218` sets it to `night`.
- In the capture it is current (manager +0x1C) and slot 26 holds `night`.

## 4. What reaches rendering: the live params struct L. PROVEN offsets from the dump.

`L = *( *(u32*)0x00E7ADFC + 0x104 )`. In the capture it is `0x21739F30` (`dump-chain … 0x00E7ADFC 0x104 0x0`).

| L off | contents | capture value (night, t = 0.976) |
|---|---|---|
| +0x10 | Time (0..1) ← record LightTime when TimeSpeed = 0 | 0.1 |
| +0x14 | TimeSpeed | 0 |
| +0x18 | LightAngle (SetLightAngle) | −150.0 |
| +0x20/+0x30/+0x40 | float3 colours, derived. Producer NOT DETERMINED; the cloud pass `FUN_0047E7F0` reads them (`sky_post_hdr_code_map.md` §3) | (0.824, 0.309, 0.475) / (0.731, 0.536, 0.422) / (0.521, 0.458, 0.454) |
| +0x50 | LightMultiplier xyzw (sun light colour tint) | (0.8536, 0.8030, 0.9964, 1) |
| +0x60 | SunEmissiveColor xyzw | (0.1081, 0.1136, 0.1122, 1) |
| +0x70 | AmbientColor rgba (× multiplier) | (0.6130, 0.6319, 0.7655, 1) |
| +0x80..+0xDC | AmbientCube 0..5, rgba each | see verify_lerp.txt |
| +0xE0 | LightIntensity | 0.55482 |
| +0xF0 | sun direction, unit float3 | (−0.46399, 0.84439, −0.26782) |
| +0x110 | RimColor rgba × mult | (0.1994, 0.3269, 0.4078, 1.1200) |
| +0x120..+0x144 | HG g, Turbinity, Inscatter, Extinction, BetaRay, BetaMie, AtmosphereLimit, AtmosphereForce, HazeLimit, HazeForce | 0.512, 0, 5, 1, 0.04467, 0.01, 1000.13, 2, 85, 0.5 |
| +0x148..+0x174 | small derived coefficients (≈1e-4..1e-6). Producer NOT DETERMINED (likely the computed Rayleigh/Mie betas) | see dump |
| +0x17C/+0x180/+0x184 | wind direction (normalised) / WindForce | 0.95783, 0.28735, 0.00588 |
| +0x188 | AshParticlesPerSecond | 0 |
| +0x190 | ptr → post/bloom + colour-grade object | 0x2173C370 |
| +0x194 | ptr → screen-effect (rain) object | 0x1FEB76C0 |

Sun direction:
- The capture's horizontal part is exactly azimuth LightAngle: (cos −150°, sin −150°) × 0.5358 = (−0.464, −0.268) in (x, z). PROVEN numerically for this capture only.
- The elevation (y = 0.844 at Time 0.1) and the Time→elevation formula are NOT DETERMINED; no fit was attempted.

Fog: the inputs are L+0x120..+0x144. The shader formula is NOT DETERMINED. A separate camera/env-block fog-far path, `FUN_007140B0` (`env+0x44` from camera +0x5E4 or ViewDistance), was not tied to any AtmosphereBase field.

Sky dome: there is no sky texture or sky asset in the setting. SetSky is a no-op, so the sky is the analytic scatter sky (PgSkyVP/PgSkyFP + PgAtmosphereVP) driven by L, plus clouds from the to-record's cloud block.

## 5. Decoded values

These are the full 185 fields of night, carmonaislandrain's default, and the global default.
- Columns 1–2 come from the shipped vz.wad block 29.
- Column 3 comes from the live dump, `dump-entity … 0x900000CF` (`0x21660AC4`).
- Colours are shown as rgba bytes with r = byte0. Multiply by 1/255 and by the matching Multiplier.
- The other 53 records are in `atmo_records_full.txt`.

There are no "afternoon" or "Maracaibo" records to decode (§0).

What the engine shows for "night" once the blend completes: L takes the night column (LightIntensity 0.55, Time 0.1, AmbientColor (0.616, 0.635, 0.769) and so on). The capture is 97.6% of the way there.

| rec off | field | type | night (rgn_atmo_carmonaislandrain) | default (rgn_atmo_carmonaislandrain) | default (0x900000CF, live dump) |
|---|---|---|---|---|---|
| +0x000 | Name | u32 | 0xBB74C311 rgba(17,195,116,187) ['night'] | 0xBA71C11C rgba(28,193,113,186) default | 0xBA71C11C rgba(28,193,113,186) |
| +0x004 | InterpolateTime | f32 | 20 | 20 | 20 |
| +0x008 | LightMultiplier_X | f32 | 0.85 | 1 | 1 |
| +0x00c | LightMultiplier_Y | f32 | 0.8 | 0.925 | 1 |
| +0x010 | LightMultiplier_Z | f32 | 1 | 0.85 | 1 |
| +0x014 | LightMultiplier_W | f32 | 1 | 1 | 1 |
| +0x018 | LightIntensity | f32 | 0.55 | 0.75 | 1.15 |
| +0x01c | LightTime | f32 | 0.1 | 0.1 | 0.2 |
| +0x020 | LightTimeSpeed | f32 | 0 | 0 | 0 |
| +0x024 | SunEmissiveColor_X | f32 | 0.10674 | 0.16489 | 0.06 |
| +0x028 | SunEmissiveColor_Y | f32 | 0.11236 | 0.16489 | 0.06 |
| +0x02c | SunEmissiveColor_Z | f32 | 0.11236 | 0.10638 | 0.06 |
| +0x030 | SunEmissiveColor_W | f32 | 1 | 1 | 1 |
| +0x034 | AmbientColor | u32 | 0xFFC4A29D rgba(157,162,196,255) | 0xFFA37E81 rgba(129,126,163,255) | 0xFFA99583 rgba(131,149,169,255) |
| +0x038 | AmbientColorMultiplier | f32 | 1 | 1 | 1 |
| +0x03c | AmbientCube0 | u32 | 0x80969696 rgba(150,150,150,128) | 0x80756D68 rgba(104,109,117,128) | 0x8076625F rgba(95,98,118,128) |
| +0x040 | AmbientCube0Multiplier | f32 | 1 | 1 | 1 |
| +0x044 | AmbientCube1 | u32 | 0x80757575 rgba(117,117,117,128) | 0x8098816D rgba(109,129,152,128) | 0x8070675F rgba(95,103,112,128) |
| +0x048 | AmbientCube1Multiplier | f32 | 1 | 1 | 1 |
| +0x04c | AmbientCube2 | u32 | 0x80909090 rgba(144,144,144,128) | 0x80928583 rgba(131,133,146,128) | 0x80B0ACA4 rgba(164,172,176,128) |
| +0x050 | AmbientCube2Multiplier | f32 | 1 | 1 | 1 |
| +0x054 | AmbientCube3 | u32 | 0x804D4D4D rgba(77,77,77,128) | 0x804D4137 rgba(55,65,77,128) | 0x8049423A rgba(58,66,73,128) |
| +0x058 | AmbientCube3Multiplier | f32 | 1 | 1 | 1 |
| +0x05c | AmbientCube4 | u32 | 0x806A6A6A rgba(106,106,106,128) | 0x80756960 rgba(96,105,117,128) | 0x80747063 rgba(99,112,116,128) |
| +0x060 | AmbientCube4Multiplier | f32 | 1 | 1 | 1 |
| +0x064 | AmbientCube5 | u32 | 0x806B6B6B rgba(107,107,107,128) | 0x80877361 rgba(97,115,135,128) | 0x80837A67 rgba(103,122,131,128) |
| +0x068 | AmbientCube5Multiplier | f32 | 1 | 1 | 1 |
| +0x06c | RimColor | u32 | 0xFF5E4B2D rgba(45,75,94,255) | 0xFF2E333D rgba(61,51,46,255) | 0xFF464E53 rgba(83,78,70,255) |
| +0x070 | RimColorMultiplier | f32 | 1.12 | 1.1212 | 1.1212 |
| +0x074 | ScatterHGg | f32 | 0.50725 | 0.70513 | 0.80503 |
| +0x078 | ScatterTurbinity | f32 | 0 | 0 | 0 |
| +0x07c | ScatterInscatteringMultiplier | f32 | 5 | 5 | 15 |
| +0x080 | ScatterExtinctionMultiplier | f32 | 1 | 1 | 1 |
| +0x084 | ScatterBetaRayMultiplier | f32 | 0.0438 | 0.08 | 0.08319 |
| +0x088 | ScatterBetaMieMultiplier | f32 | 0.01 | 0.01 | 0.01 |
| +0x08c | AtmosphereLimit | f32 | 1000 | 1005.59 | 1083.33 |
| +0x090 | AtmosphereForce | f32 | 2 | 2 | 1 |
| +0x094 | HazeLimit | f32 | 85 | 85 | 85 |
| +0x098 | HazeForce | f32 | 0.5 | 0.5 | 0.5 |
| +0x09c | Water0_Index1 | i32 | 0 | 0 | 0 |
| +0x0a0 | Water0_Index2 | i32 | 85 | 85 | 85 |
| +0x0a4 | Water0_Color1 | u32 | 0x00333224 rgba(36,50,51,0) | 0x000F0F0F rgba(15,15,15,0) | 0x00000000 rgba(0,0,0,0) |
| +0x0a8 | Water0_Color2 | u32 | 0x5543372E rgba(46,55,67,85) | 0x55374031 rgba(49,64,55,85) | 0x55344130 rgba(48,65,52,85) |
| +0x0ac | Water1_Index1 | i32 | 85 | 85 | 85 |
| +0x0b0 | Water1_Index2 | i32 | 170 | 170 | 170 |
| +0x0b4 | Water1_Color1 | u32 | 0x5543372E rgba(46,55,67,85) | 0x55374031 rgba(49,64,55,85) | 0x55344130 rgba(48,65,52,85) |
| +0x0b8 | Water1_Color2 | u32 | 0xAA3E322F rgba(47,50,62,170) | 0xAA2C3425 rgba(37,52,44,170) | 0xAA253427 rgba(39,52,37,170) |
| +0x0bc | Water2_Index1 | i32 | 170 | 170 | 170 |
| +0x0c0 | Water2_Index2 | i32 | 255 | 255 | 255 |
| +0x0c4 | Water2_Color1 | u32 | 0xAA3E322F rgba(47,50,62,170) | 0xAA2C3425 rgba(37,52,44,170) | 0xAA253427 rgba(39,52,37,170) |
| +0x0c8 | Water2_Color2 | u32 | 0xFF62473E rgba(62,71,98,255) | 0xFF1B1E15 rgba(21,30,27,255) | 0xFF161D17 rgba(23,29,22,255) |
| +0x0cc | Gradient0_Index1 | i32 | 0 | 0 | 0 |
| +0x0d0 | Gradient0_Index2 | i32 | 128 | 128 | 128 |
| +0x0d4 | Gradient0_Color1 | u32 | 0x5C000000 rgba(0,0,0,92) | 0x4E000000 rgba(0,0,0,78) | 0x40000000 rgba(0,0,0,64) |
| +0x0d8 | Gradient0_Color2 | u32 | 0x5CC76038 rgba(56,96,199,92) | 0x4E72778D rgba(141,119,114,78) | 0x40798086 rgba(134,128,121,64) |
| +0x0dc | Gradient1_Index1 | i32 | 128 | 128 | 128 |
| +0x0e0 | Gradient1_Index2 | i32 | 255 | 255 | 255 |
| +0x0e4 | Gradient1_Color1 | u32 | 0x5CC76038 rgba(56,96,199,92) | 0x4E72778D rgba(141,119,114,78) | 0x40798086 rgba(134,128,121,64) |
| +0x0e8 | Gradient1_Color2 | u32 | 0x5CFFFFFF rgba(255,255,255,92) | 0x4EFFFFFF rgba(255,255,255,78) | 0x40FFFFFF rgba(255,255,255,64) |
| +0x0ec | Gradient2_Index1 | i32 | 0 | 0 | 0 |
| +0x0f0 | Gradient2_Index2 | i32 | 0 | 0 | 0 |
| +0x0f4 | Gradient2_Color1 | u32 | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) |
| +0x0f8 | Gradient2_Color2 | u32 | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) |
| +0x0fc | Gradient3_Index1 | i32 | 0 | 0 | 0 |
| +0x100 | Gradient3_Index2 | i32 | 0 | 0 | 0 |
| +0x104 | Gradient3_Color1 | u32 | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) |
| +0x108 | Gradient3_Color2 | u32 | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) |
| +0x10c | Gradient4_Index1 | i32 | 0 | 0 | 0 |
| +0x110 | Gradient4_Index2 | i32 | 0 | 0 | 0 |
| +0x114 | Gradient4_Color1 | u32 | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) |
| +0x118 | Gradient4_Color2 | u32 | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) |
| +0x11c | BloomBlurRadius | f32 | 0.55 | 0.55 | 0.556 |
| +0x120 | BloomThreshold | f32 | 1 | 1 | 1 |
| +0x124 | BloomMultiplier | f32 | 1 | 1 | 1 |
| +0x128 | BloomAmount | f32 | 0.25 | 0.25 | 0.25 |
| +0x12c | BloomTargetLuminance | f32 | 0.35 | 0.35 | 0.4 |
| +0x130 | BloomAdaptiveLuminancePercent | f32 | 0.98 | 0.98 | 0.98 |
| +0x134 | BloomAdaptiveLuminanceScale | f32 | 30 | 30.3704 | 30.3704 |
| +0x138 | BloomAdaptiveLuminanceMin | f32 | 0.01 | 0.01 | 0.01 |
| +0x13c | BloomAdaptiveLuminanceMax | f32 | 0.8 | 0.6 | 0.8 |
| +0x140 | BloomAdaptiveLuminanceMinKeyScale | f32 | 2.5 | 2.5 | 2.5 |
| +0x144 | BloomAdaptiveLuminanceMaxKeyScale | f32 | 0.45 | 0.45 | 0.85 |
| +0x148 | BloomContastLimit | f32 | 0.15 | 0.14 | 0.145 |
| +0x14c | BloomContastMultiplier | f32 | 2 | 1.9 | 1.95 |
| +0x150 | BloomGrainyOpacity | f32 | 0.5 | 0.5 | 0.5 |
| +0x154 | AshParticlesPerSecond | f32 | 0 | 0 | 0 |
| +0x158 | AmbientSound | u32 | 0x00000000 rgba(0,0,0,0) | 0x00000000 rgba(0,0,0,0) | 0x00000000 rgba(0,0,0,0) |
| +0x15c | WindDirection_X | f32 | 1 | 1 | 1 |
| +0x160 | WindDirection_Y | f32 | 0.3 | 0.3 | 0.3 |
| +0x164 | WindForce | f32 | 0.006 | 0.001 | 0.003 |
| +0x168 | ScreenEffect0Speed | f32 | 0.15 | 0.075 | 0.075 |
| +0x16c | ScreenEffect0Density | f32 | 0.9 | 0.9 | 0.9 |
| +0x170 | ScreenEffect0DirX | f32 | 0.1 | 0.1 | 0.1 |
| +0x174 | ScreenEffect0DirY | f32 | 0 | 0 | 0 |
| +0x178 | ScreenEffect0Texture | u32 | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) |
| +0x17c | ScreenEffect0Color | u32 | 0x8091826F rgba(111,130,145,128) | 0x5C727A8D rgba(141,122,114,92) | 0x80808080 rgba(128,128,128,128) |
| +0x180 | ScreenEffect0Type | enum | 0 | 0 | 0 |
| +0x184 | ScreenEffect1Speed | f32 | 2 | 2 | 2 |
| +0x188 | ScreenEffect1Density | f32 | 0 | 0 | 0 |
| +0x18c | ScreenEffect1DirX | f32 | 0.1 | 0.1 | 0.1 |
| +0x190 | ScreenEffect1DirY | f32 | -1 | -1 | -1 |
| +0x194 | ScreenEffect1Texture | u32 | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) |
| +0x198 | ScreenEffect1Color | u32 | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) |
| +0x19c | ScreenEffect1Type | enum | 0 | 0 | 0 |
| +0x1a0 | ScreenEffect2Speed | f32 | 2 | 2 | 2 |
| +0x1a4 | ScreenEffect2Density | f32 | 0 | 0 | 0 |
| +0x1a8 | ScreenEffect2DirX | f32 | 0.1 | 0.1 | 0.1 |
| +0x1ac | ScreenEffect2DirY | f32 | -1 | -1 | -1 |
| +0x1b0 | ScreenEffect2Texture | u32 | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) |
| +0x1b4 | ScreenEffect2Color | u32 | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) |
| +0x1b8 | ScreenEffect2Type | enum | 0 | 0 | 0 |
| +0x1bc | ScreenEffect3Speed | f32 | 2 | 2 | 2 |
| +0x1c0 | ScreenEffect3Density | f32 | 0 | 0 | 0 |
| +0x1c4 | ScreenEffect3DirX | f32 | 0.1 | 0.1 | 0.1 |
| +0x1c8 | ScreenEffect3DirY | f32 | -1 | -1 | -1 |
| +0x1cc | ScreenEffect3Texture | u32 | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) |
| +0x1d0 | ScreenEffect3Color | u32 | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) |
| +0x1d4 | ScreenEffect3Type | enum | 0 | 0 | 0 |
| +0x1d8 | ScreenEffect4Speed | f32 | 2 | 2 | 2 |
| +0x1dc | ScreenEffect4Density | f32 | 0 | 0 | 0 |
| +0x1e0 | ScreenEffect4DirX | f32 | 0.1 | 0.1 | 0.1 |
| +0x1e4 | ScreenEffect4DirY | f32 | -1 | -1 | -1 |
| +0x1e8 | ScreenEffect4Texture | u32 | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) |
| +0x1ec | ScreenEffect4Color | u32 | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) |
| +0x1f0 | ScreenEffect4Type | enum | 0 | 0 | 0 |
| +0x1f4 | ScreenEffect5Speed | f32 | 2 | 2 | 2 |
| +0x1f8 | ScreenEffect5Density | f32 | 0 | 0 | 0 |
| +0x1fc | ScreenEffect5DirX | f32 | 0.1 | 0.1 | 0.1 |
| +0x200 | ScreenEffect5DirY | f32 | -1 | -1 | -1 |
| +0x204 | ScreenEffect5Texture | u32 | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) |
| +0x208 | ScreenEffect5Color | u32 | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) |
| +0x20c | ScreenEffect5Type | enum | 0 | 0 | 0 |
| +0x210 | ScreenEffect6Speed | f32 | 2 | 2 | 2 |
| +0x214 | ScreenEffect6Density | f32 | 0 | 0 | 0 |
| +0x218 | ScreenEffect6DirX | f32 | 0.1 | 0.1 | 0.1 |
| +0x21c | ScreenEffect6DirY | f32 | -1 | -1 | -1 |
| +0x220 | ScreenEffect6Texture | u32 | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) |
| +0x224 | ScreenEffect6Color | u32 | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) |
| +0x228 | ScreenEffect6Type | enum | 0 | 0 | 0 |
| +0x22c | Coverage | f32 | 1 | 0.64744 | 0.46622 |
| +0x230 | Thickness | f32 | 125 | 75 | 50 |
| +0x234 | Shape | f32 | 0.63043 | 1 | 1 |
| +0x238 | PhaseK | f32 | 0.64234 | 0.80128 | 0.40541 |
| +0x23c | PhaseScale | f32 | 0.43796 | 0.35897 | 0.17568 |
| +0x240 | DarknessK | f32 | 30 | 300 | 10 |
| +0x244 | ShadowK | f32 | 0 | 0.67391 | 0.2037 |
| +0x248 | Tone_R | f32 | 0.75 | 1.15 | 1 |
| +0x24c | Tone_G | f32 | 0.75 | 1 | 1 |
| +0x250 | Tone_B | f32 | 1 | 0.85 | 1 |
| +0x254 | LightBlend | f32 | 0.68116 | 0 | 0 |
| +0x258 | OpacitySrcMin | f32 | 0 | 0 | 0 |
| +0x25c | OpacitySrcMax | f32 | 0.25281 | 0.1859 | 1 |
| +0x260 | OpacityDstMin | f32 | 0 | 0 | 0 |
| +0x264 | OpacityDstMax | f32 | 1 | 0.64744 | 1 |
| +0x268 | Scroll_U | f32 | 0.025 | 0.008 | 0.00491 |
| +0x26c | Scroll_V | f32 | 0.025 | 0.008 | 0.00491 |
| +0x270 | Layer1_Scale | f32 | 10 | 10 | 8 |
| +0x274 | Layer2_Scale | f32 | 1 | 1 | 1 |
| +0x278 | Layer3_Scale | f32 | 4 | 4 | 2 |
| +0x27c | Layer4_Scale | f32 | 2 | 2 | 1 |
| +0x280 | AmbientEffect0Type | enum | 1 | 1 | 1 |
| +0x284 | AmbientEffect0Name | u32 | 0x00000000 rgba(0,0,0,0) | 0x00A97CEF rgba(239,124,169,0) | 0x647189BE rgba(190,137,113,100) |
| +0x288 | AmbientEffect0Radius | f32 | 35 | 25 | 25 |
| +0x28c | AmbientEffect0Height | f32 | -0.05 | 3 | 3 |
| +0x290 | AmbientEffect0Variance | f32 | 0 | 0 | 0 |
| +0x294 | AmbientEffect1Type | enum | 1 | 1 | 0 |
| +0x298 | AmbientEffect1Name | u32 | 0x00000000 rgba(0,0,0,0) | 0x00000000 rgba(0,0,0,0) | 0x00000000 rgba(0,0,0,0) |
| +0x29c | AmbientEffect1Radius | f32 | 0 | 50.7042 | 0 |
| +0x2a0 | AmbientEffect1Height | f32 | 0 | -0.5 | 0 |
| +0x2a4 | AmbientEffect1Variance | f32 | 0 | 0 | 0 |
| +0x2a8 | AmbientEffect2Type | enum | 0 | 1 | 0 |
| +0x2ac | AmbientEffect2Name | u32 | 0x00000000 rgba(0,0,0,0) | 0x00000000 rgba(0,0,0,0) | 0x00000000 rgba(0,0,0,0) |
| +0x2b0 | AmbientEffect2Radius | f32 | 0 | 25 | 0 |
| +0x2b4 | AmbientEffect2Height | f32 | 0 | 5 | 0 |
| +0x2b8 | AmbientEffect2Variance | f32 | 0 | 0 | 0 |
| +0x2bc | AmbientEffect3Type | enum | 0 | 0 | 0 |
| +0x2c0 | AmbientEffect3Name | u32 | 0x00000000 rgba(0,0,0,0) | 0x00000000 rgba(0,0,0,0) | 0x00000000 rgba(0,0,0,0) |
| +0x2c4 | AmbientEffect3Radius | f32 | 0 | 0 | 0 |
| +0x2c8 | AmbientEffect3Height | f32 | 0 | 0 | 0 |
| +0x2cc | AmbientEffect3Variance | f32 | 0 | 0 | 0 |
| +0x2d0 | AmbientEffect4Type | enum | 0 | 0 | 0 |
| +0x2d4 | AmbientEffect4Name | u32 | 0x00000000 rgba(0,0,0,0) | 0x00000000 rgba(0,0,0,0) | 0x00000000 rgba(0,0,0,0) |
| +0x2d8 | AmbientEffect4Radius | f32 | 0 | 0 | 0 |
| +0x2dc | AmbientEffect4Height | f32 | 0 | 0 | 0 |
| +0x2e0 | AmbientEffect4Variance | f32 | 0 | 0 | 0 |


## 6. Recipe: reading this from vz.wad

1. Open vz.wad and decompress block 29 (`layers_static`): `mercs2_probe dump-block 29 out.bin`.
2. Walk the sub-blocks' UCFX CHDR and find the `COMP` whose `info` is `AtmosphereBase`. Use `mercs2_formats::placement::comp_inventory`, which gives `data_off`/`data_size` and the `schm` stride. Its `schm` child is `[u32 n=185][u32 stride=740][n × {u32 type, u32 name_hash, u32 0, u32 offset}]`.
3. The data is `[u32 entity_key][740-byte payload]` repeated. Index by (key, payload+0 Name). Several records may share a key.
4. Each key's `LineRegion` component (4-byte record) names its `lineregion` polygon asset (type `0x6310807F`). `crates/mercs2_probe/src/layer.rs:42` `line_regions` and `crates/mercs2_workshop/src/live_overlay.rs` already read these.
5. Unpack colours as `r = byte0, g = byte1, b = byte2, a = byte3` (u32 LE), multiply by 1/255 and the Multiplier, then lerp per float.

Existing Rust: no reader decodes AtmosphereBase. `crates/mercs2_formats/src/atmosphere.rs:4-9` states the sky is "NOT a WAD chunk" and only parses Lua SetValue streams; that statement is wrong for the region presets. `crates/mercs2_script/src/bindings/atmosphere.rs:165-171` lists Change/LineRegion/Restore/EnableImmediatelyChangeMode as unbacked. These files were not edited.

## 7. Evidence commands (all run this session)

- `mercs2_probe layer vz_atmosphere_regions` (41 entities and their LineRegion assets)
- `mercs2_probe comp-dump AtmosphereBase` (sub-block 172, 41664 bytes, stride 740)
- `mercs2_probe dump-block 29 block29.bin`; then `scripts/find_schm.py`, `schm_names.py` and `decode_atmo.py`
- `python3 tools/pandemic_hash.py --m2 night|default|afternoon|Maracaibo|ScreenEffect0Type`
- `mercs2_probe dump-read <cap> 0x00ED3B08 / 0x014B7E7C / 0x00ED3900 / 0x00ED3A00 / 0x00ED3B00 / 0x00DCD420 / 0x00DCDFB0 / 0x21739F30`
- `mercs2_probe dump-chain <cap> 0x00E7ADFC 0x104 0x0`
- `mercs2_probe dump-entity <cap> 0x900000CF / 0x000CC5DC`
- `scripts/verify_lerp.py` (54/54 OK)
- `objdump -d --start-address=0x6d5630 … mercs2_unpacked.exe`
- x360 decompiles: `0x82318988, 0x82318900, 0x82318D28, 0x8224CD48, 0x823DA3C8, 0x8224DD98, 0x8224D650, 0x8243D0C8, 0x8243CFF0, 0x821AEE90, 0x8224D320, 0x8224D4B8, 0x8224D5F0, 0x8224CF08, 0x8224E440, 0x8224D1B8, 0x8224C398, 0x8224C060, 0x8221E340, 0x82319288, 0x82308818, 0x82318FA0, 0x823195E0`
- PC corpus rows: `0x005B0D20, 0x005B1100, 0x005B0C50, 0x004EBF90, 0x006A4480, 0x007140B0, 0x006D5640` (and pc-v10-drmfree `0x006D5640`)

## 8. NOT DETERMINED

1. **Source asset of the global default `0x900000CF`.** Things tried:
   - `entity-find` reports no Transform and no ModelName.
   - `scan-hash 0x900000CF` finds 0 hits in blocks 3121 and 29.
   - `layer 0x900000CF` finds no layer in Loading, vz, vz-patch or English.
   - The live record does not equal any block-29 record (the best match differs in 14 words).
   - Next steps: `we-template 0x900000CF` / `we-template --class AtmosphereBase` (not run), and a key scan of the other WADs.
2. **Sun elevation as a function of Time (L+0x10) and the producer of L+0xF0, +0x20..+0x4C and +0x148..+0x174.** Next step: x360 xrefs to the L+0xF0 store, or a write watch in the capture's code. The task forbade launching or attaching anything, so a live watch was not attempted.
3. **The fog/haze shader maths** (how AtmosphereLimit/Force, HazeLimit/Force and the betas become fog colour and density). Next step: `mercs2_probe shaderforge disasm` on PgAtmosphereVP/PgSkyFP and the per-frame constant upload.
4. **Which entity's position drives the region test** (handle at owner+0x14; the PC owner object for `FUN_006A4480` comes from `FUN_006A0770`).
5. **Unconsumed or unseen fields:** LightTimeSpeed, BloomThreshold, BloomMultiplier, BloomGrainyOpacity, AmbientSound, ScreenEffect1..6, and the meaning of buf+0xB80/+0xB84 (the restore time).
6. **The name of the setting hash `0x9D92A2D5`** (Merida and Meridastadium). It did not resolve against exe strings, Lua strings or the rainbow table.
7. **A line-by-line PC body for Change/ChangeLineRegionSetting.** They are SecuROM split stubs (`FUN_004EBF90` → `0x00581A7C`; `thunk_FUN_02DA0000`). The x360 bodies and the PC dump state are the evidence instead.
8. **Whether typed setters called inside Begin/End (SetTime, SetAmbientCube, …, as in mrxbootstrap's SetDefaultAtmosphere) reach the to-buffer.** On x360 they store to separate globals (`DAT_83650410…`), and the path into the staging buffer `0x82DE32D0` was not traced.

## 9. The light block, and what L+0x20 and L+0x40 are (read 2026-11-25, pc-v10)

This settles part of §8 item 2 and corrects two rows of §4's table.

**The per-frame light block.** PROVEN. `FUN_00465630` is called from the scene driver `FUN_00466d40`
with `LEA ECX,[ESI+0x10]` (`0x00466df3`), so its argument is `L+0x10`. It fills a 0x1b0-byte block at
`DAT_018c1fe0`; the nine rows at `0x018C2190` are, in every capture read (`dump-read <cap> 0x018C2190 144`):

| row | contents |
|---|---|
| 0 | `−(L+0x20)`, a unit vector (the negation is `−0 − x` with `DAT_00beaa2c` = `0x80000000`) |
| 1 | `L+0x40` |
| 2 | `L+0x110`, the rim colour with its multiplier in w |
| 3..8 | `(L+0x80+16i) × (L+0x70)` per component: ambient cube face i × ambient colour |

The scene driver puts the block's pointer into every per-view record (`PTR_DAT_018c5644` slots). That
the mesh pixel shaders read it is INFERRED: the draw-time upload to a named shader constant was not
traced.

**`L+0x20` is the unit direction toward the sun.** PROVEN: the sun billboard is drawn at camera +
`(L+0x20) × 16` (`FUN_0047f7c0`, `DAT_00b9ba6c` = 16.0) and the HDR flare at `(L+0x20) × 800000`
(`FUN_0074edd0`, `DAT_00beafa8` = 800000.0); the light block's row 0 is its negation, the direction
the light travels. §4's table calls +0x20 a colour and +0xF0 the sun direction; +0xF0 is a unit vector
perpendicular to +0x30 with no reader found.

**`L+0x40` is the directional light's colour**, light intensity already in it (light block row 1; the
cloud pass uses `lerp(1, L+0x40, k)`). It is not `LightMultiplier × LightIntensity`: the ratio is
(1.05, 1.01, 0.90) at Time 0.2 and (1.10, 1.03, 0.82) at Time 0.1, reddening as the sun gets lower.
Its producer is not found.

**The sun's direction from Time and LightAngle.** INFERRED: a fit, with no code found, that holds in
five captures to within 3e-4 (Times 0.1, 0.2, 0.51, 0.51, 0.85; LightAngle −150 in all, so its sign
convention is not pinned). With θ = π · Time and A = LightAngle:

```text
L+0x20 = (−cos θ · cos A,  sin θ,  −cos θ · sin A)        game axes, Y up
L+0x30 = the same arc at θ' = 90° + 0.8 (θ − 90°)
L+0xF0 = ± the arc at θ' − 90°, the sign that makes Y ≥ 0
```

So Time 0 to 1 is sunrise to sunset, and Time 0.5 has the sun overhead.

**The live fields are filled by `FUN_004eb2c0`** (argument `L+0x10`, via `FUN_004eb250`), which lerps
the from-buffer `0x00DCD420` toward the to-buffer `0x00DCDFB0`; it does not write +0x20, +0x30, +0x40
or +0xF0. Their writer is not found: every decompiled reader of `0x00E7ADFC` was read, and 49 SecuROM
thunks in the sky and atmosphere code were resolved from the capture, none touching `L`.

**Captured values.** Time, `L+0x20`, the light block's rows, and `L+0x120` at four moments are in the
wad repo's `crates/mercs2_ue/data/atmosphere_captures.tsv`, with each row's capture file.

**A settled capture is a shipped record.** PROVEN (`mercs2_ue`'s retail test). The `23fe7f38/pmc`
capture's light block is the record `pmc` (`0x30E4A26F`) of `rgn_atmo_interior` (`0x000C73BB`): rows
3..8 equal that record's `AmbientCube<i> × AmbientColor`, each with its multiplier, and row 2 its
`RimColor × RimColorMultiplier`, within 2e-5; `L+0x120` equals its `ScatterHGg`; `L+0x20` equals the
fit above at its `LightTime` 0.51. Row 1 over the record's `LightMultiplier × LightIntensity` is
(1.030, 1.009, 0.940), the tint. The template `Atmosphere (interior)` (`0x80008333`) carries the same
record.
