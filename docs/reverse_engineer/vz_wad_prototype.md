# Prototype `vz.wad` Structure & Retail Diff

**Scope:** Survey the FFCS header + PTHS path table of the prototype `vz.wad` (read in-place from the
disc ISO, no full extraction) and diff its block inventory against the Xbox retail `vz.wad`.

**Provenance:** Mercenaries 2: World in Flames, Jul 11 2008 X360 preview prototype (Pandemic "Pangea"
engine). Prototype WAD lives inside `game-files/Mercenaries 2 World in Flames (Jul 11, 2008
prototype)/Mercenaries 2 Preview X360 (Jul 11 2008).iso`. Retail oracle = `game-files/xbox-vz.wad`
(Xbox 360 retail). Both are big-endian (`SCFF`) FFCS WADs.

Related: [`jul08_prototype_iso.md`](jul08_prototype_iso.md), [`prototype_vs_retail.md`](prototype_vs_retail.md),
[`disc_media_inventory.md`](disc_media_inventory.md). WAD format parsers reused: `tools/x360_dlc_io.py`
(`parse_be_ffcs`, `parse_be_pths`), `tools/_enum_blocks.py`.

---

## 1. Locating `vz.wad` in the ISO (no full extraction)

```
$ python tools/xdvdfs_extract.py ".../Mercenaries 2 Preview X360 (Jul 11 2008).iso" --list | grep vz.wad
2,017,591,296  @sec 1515006  vz.wad
```

XDVDFS partition base = `0x0`, sector size = 2048, so the WAD starts at:

```
1515006 * 2048 = 3,102,732,288 bytes = 0xB8EFF000
```

Reading the first 64 bytes at that ISO offset confirms it is a WAD start (big-endian, tags appear
byte-reversed):

```
$ python3  # seek ISO to 0xB8EFF000, read 64 bytes
first 64 bytes hex: 53434646 00000002 00000007 58444e49 ...
magic ascii: b'SCFF'   # FFCS
# reversed tags visible: XDNI=INDX, ATAD=DATA, MUSC=CSUM, TESA=ASET, SHTP=PTHS
```

**Method:** I did **not** extract the 2.0 GB file. I `seek`ed the ISO to `0xB8EFF000` and read the
first **64 MiB** into a buffer, then ran `parse_be_ffcs` / `parse_be_pths` against that buffer (the
PTHS table starts at WAD-relative `0xA2C78`, well inside 64 MiB). Verified by reading the FFCS chunk
table directly:

| chunk | offset (WAD-rel) | meta |
|-------|------------------|------|
| INDX  | `0x8000`         | 12086 |
| DATA  | `0x208000`       | 36 |
| CSUM  | `0x555DD5EC`     | 6946 |
| ASET  | `0x2B688`        | 30559 |
| PTHS  | `0xA2C78`        | **12086** |

FFCS `version = 2`, `chunk_count = 7`. INDX `meta` and PTHS `meta` both = **12086** = the block
count. `parse_be_pths(buf, 0xA2C78, 12086)` returned exactly **12086** path strings, all under
`blocks\vz\`, 0 duplicates.

First parsed path: `blocks\vz\vz_state_chijob005_a_staging_P000_Q3.block`
Last parsed path:  `blocks\vz\civ_veh_car_crx_racing_P003_Q0.block`

## 2. Retail Xbox `vz.wad` (oracle)

```
$ python3  # mmap game-files/xbox-vz.wad, parse_be_ffcs + parse_be_pths
magic b'SCFF'  version 2
  INDX 0x8000  meta 11087
  DATA 0x208000 meta 36
  CSUM 0x36CAEFB9 meta 6946
  ASET 0x287B4  meta 30553
  PTHS 0x9FD44  meta 11087
xbox-retail blocks = 11087
```

File sizes: prototype `vz.wad` = **2,017,591,296 B** (in ISO), retail `xbox-vz.wad` =
**2,000,486,400 B** on disk. (The PC retail `game-files/vz.wad` is 2,565,537,792 B — not used here.)

## 3. Block-count delta

| WAD | blocks (PTHS count) | file size |
|-----|---------------------|-----------|
| Prototype (in ISO) | **12,086** | 2,017,591,296 B |
| Xbox retail        | **11,087** | 2,000,486,400 B |
| **Δ (proto − retail)** | **+999** | +17,104,896 B |

The prototype carries **999 more block entries** than retail even though the two files are nearly the
same size — i.e. the prototype packs more, smaller/less-finished blocks.

Raw set diff (by full path string):

```
proto-only paths : 8778
retail-only paths: 7779
common paths     : 3308
```

That common count (3308) is misleadingly low — **most block basenames are content-hash IDs that get
renumbered every build**, so they never string-match across builds. Filtering those out tells the
real story (below).

## 4. The diff is dominated by content-hash renumbering (inference)

Block basenames come in two flavors:

* **Content-hash IDs** — `c#####` or `c#####-c#####-...` (e.g. `c30004_P000_Q3.block`,
  `c30015-c20105-c11222-c00939_...`). These are build-generated asset hashes; they are reassigned
  between the prototype and retail builds.
* **Human-named** — geometry/audio/system names (e.g. `vz_state_*`, `*_veh_*`, `wpn_*`,
  `pmcoutpost_bld_*`, `ambience`).

Classifying every basename (`c\d+(-c\d+)*` ⇒ hash):

| WAD | hash-named blocks | human-named blocks |
|-----|-------------------|--------------------|
| Prototype | 10,213 | 1,873 |
| Retail    |  9,219 | 1,868 |

So the +999 net and the ~8.7k/7.8k "only" sets are **almost entirely hash-name churn** (8768
proto-only / 7774 retail-only are pure-hash names). This is renumbering of the same/rebuilt content,
**not** wholesale content families appearing or disappearing *(inference — based on naming
convention, not on decoding the block payloads)*.

## 5. Truly human-named family differences (the meaningful result)

After removing hash-named blocks:

```
human-named common      : 1863
human-named proto-only  :   10
human-named retail-only :    5
```

**Prototype-only human-named blocks (10)** — all `_P000_Q3` (single, highest-quality variant),
mostly shared-asset *bundle* blocks:

```
+ amb_birds_P000_Q3.block
+ amb_shared_P000_Q3.block
+ ambience_P000_Q3.block
+ building_destruct_P000_Q3.block
+ collision_shared_P000_Q3.block
+ destruction_shared_P000_Q3.block
+ fol_shared_P000_Q3.block
+ veh_shared_P000_Q3.block
+ veh_support_P000_Q3.block
+ wpn_shared_P000_Q3.block
```

**Retail-only human-named blocks (5):**

```
- pmcoutpost_bld_fueldepot_nm_P000_Q3.block
- pmcoutpost_bld_fueldepot_nm_P001_Q2.block
- pmcoutpost_bld_fueldepot_nm_P002_Q1.block
- pmcoutpost_bld_fueldepot_nm_P003_Q0.block
- sound_resident_P000_Q3.block
```

Cross-checked individually (proto vs retail membership):

```
wpn_shared     -> proto: [wpn_shared_P000_Q3.block]      | retail: []
veh_shared     -> proto: [veh_shared_P000_Q3.block]      | retail: []
ambience       -> proto: [ambience_P000_Q3.block]        | retail: []
sound_resident -> proto: []                               | retail: [sound_resident_P000_Q3.block]
```

**Reading (inference):** between this prototype and retail the engine moved from monolithic *shared*
bundle blocks (`*_shared`, `ambience`, `building_destruct`) toward per-asset / streamed packing —
the shared bundles were dissolved into individually-hashed blocks, and retail added a dedicated
`sound_resident` block plus the finished `pmcoutpost_bld_fueldepot_nm` model (4 LOD variants
`P000_Q3`…`P003_Q0`) that is absent from the prototype.

## 6. Weapon blocks (cross-link to weapon-definitions note)

The prototype has **27** `wpn_*` blocks vs retail's **26** — the only difference being the extra
`wpn_shared_P000_Q3.block`. The per-weapon stat blocks documented in the weapon-definitions memory
note are present in both, e.g.:

```
wpn_antiair, wpn_antimaterialrifle, wpn_assaultrifle, wpn_automaticrifle,
wpn_bullpuprifle, wpn_coilgun, wpn_combatrifle, wpn_covertpistol, ...
```

(All `vz_state_*` mission/staging blocks are common to both WADs — 0 proto-only and 0 retail-only —
so the mission-state inventory did not change names between this prototype and retail.)

---

## What I actually read

* `tools/xdvdfs_extract.py --list` on the prototype ISO → vz.wad sector 1515006, size 2,017,591,296.
* Direct ISO `seek` to `0xB8EFF000` + 64 MiB read → parsed FFCS chunk table + full 12,086-entry PTHS
  via `tools/x360_dlc_io.parse_be_ffcs` / `parse_be_pths`. **No full 2 GB extraction.**
* `game-files/xbox-vz.wad` mmap'd + same parsers → 11,087-entry PTHS.
* Set/family diffs computed in Python over the two path lists.

I did **not** decode block *payloads*, INDX records, ASET, or CSUM contents — this survey is the
PTHS/path-inventory layer only. All family-evolution statements in §4–§5 are marked as inferences
drawn from the naming convention, not from payload inspection.
