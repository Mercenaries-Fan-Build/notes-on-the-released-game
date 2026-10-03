# Mercenaries 2 — Cross-Platform Image Manifest (Phase 1 of the EXE Atlas)

**Status:** Authoritative index of every engine binary and asset container this project
references — PC, Xbox 360, PS3. Every `FUN_XXXXXXXX` address in any Mercs2 RE doc is
implicitly keyed to *one* of these images. Machine-readable ground truth lives in
[`docs/data/exe_images.json`](../data/exe_images.json); this doc is the narrative.

**Generated:** 2026-09-06 from live sha256 pass of the working tree.

**Purpose:** unblock Phase 2 (uniform decomp) and Phase 3 (cross-image atlas) of the
cross-EXE atlas project. Also lets any existing or future RE doc state *which image*
an address belongs to instead of the current implicit "probably v10_dump."

---

## The four hard rules

1. **SHA-256 is the primary identity.** Filenames drift; hashes don't. This tree has 15
   filenames that collapse to just 4 distinct PC binaries by SHA-256 — see `aliases[]`
   on each JSON row.
2. **Never key by size alone.** `mercs2_nodrm_v2.exe`, `mercs2_nodrm_v3.exe`, and the
   runnable `v11_cracked` are all **53,482,288 B** with three completely different
   SHA-256s and three different provenances. Size looks-alike is a trap.
3. **The corpus's `ghidra` source currently indexes ONLY `v10_dump`.** Every
   `FUN_XXX` returned by `corpus_search` / `corpus_xref` is a v10_dump address unless a
   doc says otherwise. Phase 2 unblocks the rest.
4. **Devkit ≠ retail.** The Jul 11 2008 Xenon Profile/Final builds ship ~6-8 weeks
   pre-crunch. Use them as RTTI/string *name* anchors, not as byte-level address parity
   references. Real drift.

---

## Engine images at a glance

### PC (x86 LE)

| image_id | size B | crypto | runnable | decomp state |
|---|---:|---|:---:|---|
| `v10_retail_packed` | 17,122,568 | SecuROM-packed | ✅ | none (encrypted at rest) |
| `v10_community_a237` | 16,846,848 | unknown | ? | none |
| `v10_dump` | 53,485,568 | unpacked-from-dump | ❌ | **complete, corpus-indexed** |
| `v10_nodrm_v1` | 53,485,568 | drm-stripped (from dump, deprecated) | ✅ | none |
| `v10_nodrm_v2` | 53,482,288 | drm-stripped (from on-disk decrypt) | ✅ | none |
| `v10_nodrm_v3` | 53,482,288 | drm-stripped (v2 successor, preferred) | ✅ | none |
| `v11_uncracked` | 53,944,080 | SecuROM-packed | ❌ | **backup present** |
| `v11_cracked` | 53,482,288 | cracked (pmc_bb/cruise.dll) | ✅ | none (runnable target) |

### Xbox 360 (PPC BE-32, Xenon)

| image_id | size B | provenance | decomp state |
|---|---:|---|---|
| `xenon_devkit_profile_raw` | 32,374,784 | Jul 11 2008 devkit Profile, all-zero KEK | **complete** — 38,581 fns, 863 named, 324 RTTI classes |
| `xenon_devkit_profile_ghidra` | 32,374,784 | same, PointerToRawData fixed for Ghidra 12 loader | shared with raw |
| `xenon_devkit_final` | 26,476,544 | Jul 11 2008 devkit Final (boot exe) | **none** — no project yet |
| `xenon_retail_jtag_pe` | 26,607,616 | retail JTAG default.xex unpacked | **none — HIGHEST-VALUE Phase 2 target** |
| `xenon_retail_jtag_xex` | (packed) | JTAG rip default.xex as shipped | container |

### PS3 (PPC BE-64, PPU)

| image_id | size B | provenance | decomp state |
|---|---:|---|---|
| `ps3_engine_elf` | 18,205,720 | BLUS30056 EBOOT decrypted via `ps3_dlc_crypt unself` | **partial** — ~904 fns; needs full re-run |
| `ps3_engine_self` | 18,208,152 | disc EBOOT.BIN encrypted APP SELF | container |

---

## Asset WADs at a glance

| wad_id | size B | endian | format | notes |
|---|---:|---|---|---|
| `pc_retail_vz` | 2,565,537,792 | LE | FFCS | 11,370 blocks, 30,645 ASET |
| `pc_retail_english` | 483,426,304 | LE | FFCS | English localization |
| `pc_retail_french` | 413,990,912 | LE | FFCS | French localization |
| `pc_retail_german` | 503,775,232 | LE | FFCS | German localization |
| `pc_retail_italian` | 474,972,160 | LE | FFCS | Italian localization |
| `pc_retail_spanish` | 476,807,168 | LE | FFCS | Spanish localization |
| `pc_retail_shell` | 29,622,272 | LE | FFCS | frontend menu |
| `pc_retail_loading` | 2,490,368 | LE | FFCS | boot loading screen |
| `xbox360_retail_vz` | 2,000,486,400 | BE | SCFF | 11,087 blocks, 30,553 ASET (283 fewer than PC) |
| `xbox360_retail_english` | 79,233,024 | BE | SCFF | English localization |
| `xbox360_retail_french` | 67,469,312 | BE | SCFF | French localization |
| `xbox360_retail_loading` | 2,490,368 | BE | SCFF | same size as PC but different SHA-256 |
| `xbox360_retail_shell` | 11,894,784 | BE | SCFF | frontend menu |
| `ps3_retail_vz` | 2,201,354,240 | BE | segs | concatenation of 3 ISO fragments (`VZ.WAD` + `VZ~01.WAD` + `VZ~02.WAD`) |
| `ps3_retail_english` | 69,042,176 | BE | segs | English localization |
| `ps3_retail_french` | 60,293,120 | BE | segs | French localization |
| `ps3_retail_german` | 73,924,608 | BE | segs | German localization |
| `ps3_retail_italian` | 67,665,920 | BE | segs | Italian localization |
| `ps3_retail_russian` | 69,599,232 | BE | segs | Russian localization — PS3-only |
| `ps3_retail_spanish` | 66,519,040 | BE | segs | Spanish localization |
| `ps3_retail_loading` | 2,490,368 | BE | segs | boot loading screen |
| `ps3_retail_shell` | 18,579,456 | BE | segs | frontend menu |

---

## The interesting deduplication finds

### 15 PC filenames → 4 distinct binaries

The `game-files/` directory carries a lot of aliases. By SHA-256:

- **`a1532b4c…`** (17,122,568 B, v1.0 retail packed): `Mercenaries2.exe`, `Mercenaries2-signed.exe`, `Mercenaries2.signed.personal.exe`
- **`ada55455…`** (16,846,848 B, community A237): `Mercenaries2(1).exe`, `Mercenaries2.A237.exe`, `Mercenaries2.community-member-original.exe`, `Mercenaries2.random-unsigned.exe`, `Mercenaries2.unpatched.uncracked.exe`, `Mercenaries2.updated-com-mem-modded.exe` — **six copies of the same file**
- **`7a348847…`** (53,944,080 B, v1.1 uncracked): `output/mercs2_v1.1_uncracked.exe`, `Mercenaries2(2).exe`, `Mercenaries2(3).exe`, `Mercenaries2.patched.uncracked.exe`
- **`23fe7f38…`** (53,482,288 B, v1.1 patched cracked): the runnable game, `Mercenaries2 (1).exe`, `Mercenaries2.community-member-modded.exe`, `Mercenaries2.patched.cracked.crusedll.exe`

Two useful surprises:

1. `Mercenaries2.community-member-modded.exe` **has the same SHA-256 as the runnable game**. Whatever the community modded, it wasn't this exe — likely at the WAD/asset level.
2. The `v10_community_a237` at 16,846,848 B is **275,720 bytes smaller** than v1.0 retail packed. It's not a bit-for-bit copy of retail v1.0; provenance is unclear and it needs investigation before being treated as authoritative. The `A237` name also appears in the FESL b-version builder memory as a specific build identifier — cross-check.

### `v10_nodrm` variants: three sizes, three provenances

- `nodrm_v1` (53,485,568 B) — built **from the memory dump**; inherits three pmc_bb.dll hot-patch splices. Deprecated.
- `nodrm_v2` (53,482,288 B) — built from the **on-disk decrypted** exe. Byte-clean.
- `nodrm_v3` (53,482,288 B) — successor to v2 with fixes. **Preferred** byte-clean v1.0 reference.

`nodrm_v2/v3` are the same size as `v11_cracked` but have completely different SHA-256s and totally different lineages. Rely on hash, not size.

---

## Provenance highlights per image

### `v10_dump` — the current corpus reference

`output/_ghidra/securom_dump/mercs2_unpacked.exe`, 53,485,568 B, sha256 `8c179a99…`.

Live memory dump of a running v1.0 process post-OEP, reconstructed to a flat PE (all 13
sections: RVA == raw pointer). PE timestamp `0x48a370c7` = Aug 13 2008. Ghidra project
`output/_ghidra/proj/mercs2.rep`. Decomp `output/_ghidra/mercs2_unpacked.exe_decomp.txt`,
27,104 fns. **This is the image every existing FUN_XXX reference points at.**

Trap: **three pmc_bb.dll hot-patch splices** at `0x005E9DE0`, `0x005E9F40`, `0x006D5640`
— the dump captured runtime patches at those bytes, not retail bytes. For byte-clean
v1.0 code at those addresses, use `v10_nodrm_v3`.

### `v11_uncracked` — the v1.1 static reference

`output/mercs2_v1.1_uncracked.exe`, 53,944,080 B, sha256 `7a348847…`, MD5
`5b9976f162e050f4adcc51bb997ba97f`, PE timestamp `0x48cae190`. Built by applying
`tools/patches/mercs2_v1.0_to_v1.1_update.bspatch` to v10_retail_packed. Will not
launch (SecuROM still installed) — static-analysis only.

Decomp backup at `output/_ghidra/decomp_backups/2026-07-06/v1.1_genuine_patched_decomp.txt`
(sha256 `16b143ab…`); fn-mnemonic sigs at `fnsig_v1.1.json` (sha256 `4b300bd6…`).
Ghidra project is a second program inside `output/_ghidra/proj_unpacked`.

### `xenon_devkit_profile_raw` — the primary name oracle

`output/jul08_prototype/mercs2_xenon_p.pe.bin` (`pe_full.bin` is identical),
32,374,784 B, sha256 `d6f68a60…`. Unpacked from the Jul 11 2008 preview XEX with the
all-zero devkit KEK. PE link timestamp 2008-07-12 01:37:13 UTC — ~2 months pre-ship.

**Retains 324 RTTI class names, 48 source paths, PDB path.** This is the payoff row for
the atlas — string + RTTI anchoring points on this image cross into PC/PS3 retail by
name. Decomp at `output/_ghidra_x360/xenon_decomp_named.c`, 38,581 fns of which 863 are
already named (458 via string anchoring, 325 via RTTI ctor recognition).

Caveat: devkit **is not retail**. Use for names, not addresses.

### `xenon_retail_jtag_pe` — the biggest Phase 2 target

`output/_scratch/x360_retail/default.pe.bin`, 26,607,616 B, sha256 `51564f30…`.
Unpacked from the JTAG rip default.xex. **No Ghidra project yet.** This is the highest-
value new decomp target — the shipped Xbox retail engine, same-arch same-era as the
devkit Profile (so mnemsig cross-match works), same ship-window as PC v1.1 retail (so
it's a genuine parity oracle for PC).

Pipeline is entirely reusable — same steps as devkit Profile decomp, needs a
`scripts/ghidra_analyze_x360_retail.sh` added to parallel `ghidra-ps3-eboot`.

### `ps3_engine_elf` — third independent engine implementation

`output/analysis/cross_platform/ps3_eboot/EBOOT.elf`, 18,205,720 B, sha256 `dfb5b1c5…`.
Decrypted from BLUS30056 EBOOT.BIN via `ps3_dlc_crypt unself`. AltiVec (no VMX128).

**Two Ghidra projects exist** — the atlas has to pick one:

1. `output/_ghidra_ps3/proj/mercs2cell.rep` — smaller, ~904 fns decompiled, stale.
2. `output/analysis/cross_platform/ghidra_projects/Mercenaries2_PS3_EBOOT.rep` —
   more advanced (~38 KB projectState); VZ.WAD RE targets identified. **Preferred.**

Known static anchors in `ps3_engine_elf` from May 2026 work:

| Anchor | VA | Note |
|---|---|---|
| `VZ.WAD` string | `0x00DDAB78` | referenced indirectly via TOC |
| Filename pointer table | `0x00FC6380` | TOC-style data; VZ.WAD slot at `0x00FC63B4` |
| `FxArchiveStoreFile` vtable | `0x00FB4D60` | first vmethod at `0x00DB2A30` |
| `FxArchiveStoreFile` typeinfo (Itanium RTTI) | `0x00DF06A8` | class name accessor |
| `IsDLC` string | `0x00DF0530` | DLC path exists in PS3 engine |
| `SetMasterScriptName` string | `0x00DE16F8` | same API family as PC/Xbox |

### `ps3_retail_vz` — partially cracked, blocked at stream cipher

`output/analysis/cross_platform/wads/ps3/VZ.WAD`, 1,073,739,776 B, sha256 `e8406d64…`.

Structure: **0x80800-byte encrypted envelope** + **5,462 big-endian `segs` blocks**
(same family as Xbox 360 SCFF). First 4 bytes `9fed8bc6`. As of 2026-05-21: recovered
an **18-byte keystream prefix** (`ccaecd80 e9a11ebc 3f18a221`) against an SCFF template.
**Blocked**: header keystream ≠ INDX@0x8000 keystream → it's a stream cipher, not a
single-key XOR. Extending the prefix by concatenation doesn't work.

Unlock path is via `ps3_engine_elf`: follow `FxArchiveStoreFile::vmethod0` at
`0x00DB2A30`, find `cellFsOpen`, lift the stream-cipher key derivation loop. Rust
successor crate should live alongside `ps3_dlc_crypt`. Cracking it unblocks byte-level
PS3-vs-Xbox asset comparison.

---

## What the manifest does NOT track (by design)

- **`vz-patch.wad`** — the DLC port build output. Its SHA-256 changes per rebuild; it's
  a mod artifact, not a manifest image. Deployed vz-patch hashes belong to the deploy
  audit trail (per the `verify-artifacts-by-hash` mandate) — not here.
- **PC Demo WAD** — analysis referenced a 4,204-block PC Demo WAD
  (1,015,414,784 B, sha256 `82ad1bedb04e5ede…`) but the extracted file is **not
  present** in this working tree; the `data/` dir at
  `output/analysis/cross_platform/wads/pc_demo/Mercenaries 2 World in Flames DEMO/` is
  empty. See `known_gaps.pc_demo_wad_missing_on_disk` in the JSON — re-extraction unblocks.
- **SPU code** — no `.spe.elf` files free-standing in the tree. If PS3 Havok physics
  ships SPU offload, it's embedded inside `ps3_engine_self` and needs a Phase 6 extract
  pass. Deferred.

---

## Vintage / correction notes for future readers

The May-June 2026 `output/analysis/cross_platform/` tree is the origin of much of the
PS3-side data in this manifest, and it's **older** than several corpus findings:

- The **DLC hang bisect** in `pc_bisect_results.md` predates the streaming-livelock
  work (June 2026+) and the `DLC01=level` architecture (`dlc-level-boot-and-replacement-architecture.md`).
  Where they conflict, later corpus work wins.
- The **`vz` masterscript naming** was clarified there: literal BINN string `vz` is
  absent on all platforms; every platform ships it under an obfuscated name (`xQ!L`
  PC/Demo, `#mO` Xbox), all hashing to `pandemic_hash("vz") = 0xB4420059`. That
  correction is durable.
- The **PS3 EBOOT string anchors** and **FxArchiveStoreFile vtable RE** in
  `ps3_eboot_re_targets.md` are still current — Phase 2 builds on them, doesn't
  supersede.

---

## What lands next

1. **This manifest** (Phase 1). Landed.
2. **Phase 2 — sequential Ghidra decomp runs**, one at a time (user flagged memory
   pressure risk):
   1. `xenon_retail_jtag_pe` (highest new-value)
   2. `ps3_engine_elf` full re-run against the `analysis/` project
   3. `xenon_devkit_final`
3. **Corpus indexer extension** — index all decomps under `ghidra` source with an
   `image_id` metadata field.
4. **`atlas` crate** (Phase 3) — cross-match algorithm across images. String + RTTI +
   callgraph tiers.
5. **The `asset_lifetime_monitor` ASI** — hook-points doc lands with canonical names +
   image-tagged addresses; scaffold proceeds with `v10_dump` RVAs and atlas-lookup
   as a TODO.
