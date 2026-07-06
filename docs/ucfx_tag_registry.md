# Mercenaries 2 FourCC tag registry

Auto-generated from `crates/mercs2_formats/src/tag_registry.rs` — keep in sync.
Scanned from `cmp eax,<imm32>` sites in `output/patched/Mercenaries2.exe` (base 0x00400000).
The tables in this file mirror `tag_registry.rs` (re-synced 2026-07-03); everything below the
"Curated semantics & implementation guide" marker is hand-maintained research, NOT regenerated.

- **Validated** — a simulator validator checks this chunk's invariant.
- **Registered** — recognized & benign (converter-handled), no structural validator.
- **NeedsInvestigation** — not yet validated; simulator/converter flags it.

Totals: 232 tags — UcfxAsset=70, D3dFormat=7, EntityRuntime=30, NetworkProto=100, LuaReflection=17, Misc=8
Status: Validated=42, Registered=27, NeedsInvestigation=163


## UCFX asset chunk (UcfxAsset)

| Tag | VA | Status | Notes |
|-----|-----|--------|-------|
| `AREA` | 0x0047830a | Validated | container walk @0x4a4ab0; reads 4-byte 'info' header per child; no fixed array |
| `ASTO` | 0x0067c780 | Validated | anim struct @FUN_0067c780 (decomp): reads u32 count then count*4 alloc (overflow-guarded). Validated: body >= 4 |
| `ATRB` | 0x00492b1c | Validated | effect attribute @0x492b1c: reads a 4-byte inner hash then sub-dispatches to per-attribute readers. Validated: body >= 4 |
| `BINN` | 0x0059d008 | Validated |  |
| `BNDS` | 0x004a86dc | Validated |  |
| `BODY` | 0x00750aa5 | Validated |  |
| `BSHI` | 0x00478318 | Validated | blendshape index @FUN_00478270 (decomp): reads count*2 u16 array (count from INFO param_1[0x6a]); converter swaps u16. Validated: body % 2 == 0 |
| `COLR` | 0x004930e5 | Validated | colour palette @0x4930e5: stores a fixed 0xC8 (200-byte) record into the effect palette heap. Validated: body >= 0xC8 |
| `COMP` | 0x006549ef | Validated |  |
| `DAMG` | 0x0045f558 | Validated | ECS damage ref array @0x45f558: count×4 u32 refs (count from INFO field, overflow-guarded). Validated: body % 4 == 0 |
| `DEBR` | 0x0045f9a8 | Validated | ECS debris ref array @0x45f9a8: count×4 u32 refs (overflow-guarded). Validated: body % 4 == 0 |
| `DEPS` | 0x0059d0d3 | Validated |  |
| `DICT` | 0x00491386 | Validated |  |
| `EMTR` | 0x00492402 | Validated | emitter @0x492402: reads a u16 count then count×4 alloc (overflow-guarded). Validated: body >= 2 |
| `FRCE` | 0x00491c93 | Validated | force @0x491c93: reads a 4-byte inner hash then sub-dispatches per force type. Validated: body >= 4 |
| `GEOM` | 0x0048ccbd | Validated |  |
| `IBUF` | 0x00478311 | Validated |  |
| `INFO` | 0x0045dc2b | Validated |  |
| `INST` | 0x004a4e51 | Validated | renderable consumer @0x4a4c40: count×0x18 (24B) records, count @esi+0x28 (renderable INFO); alloc overflow-guarded. Validated: body % 0x18 == 0 |
| `KEYS` | 0x004640a8 | Validated | keyframe list @0x4640a8: u32 count header then count×8 keyframe records. Validated: (body-4) % 8 == 0, body >= 4 |
| `MINF` | 0x0068e5d0 | Validated | mesh/anim info @FUN_0068e5d0 (decomp): reads [u32 hash][u16] (6 bytes) per record. Validated: body >= 6 |
| `MTRL` | 0x004a528d | Validated | tex count@106 -> fixed 10-slot array @+0xAC; >10 overruns (AV 0x84DD5B); parser FUN_00858790 |
| `NODE` | 0x004cf48b | Validated | scene node @FUN_004cf340 (decomp): u32 hash + u32 child-count (8B header), then count*0x14 child array (overflow-guarded). Validated: body >= 8 |
| `PART` | 0x0045f8e3 | Validated | ECS particle ref array @0x45f8e3: count×4 u32 refs (overflow-guarded). Validated: body % 4 == 0 |
| `PHY2` | 0x004a845f | Validated | Havok 5.5 collision packfile @0x4a845f: u32 header prefix + embedded packfile (magic SEARCHED, palindromic 57E0E057 10C0C010) + trailing wrapper. Validated by recalculation (havok::validate_phy2): locate packfile, verify length + Havok version + __classnames__ it needs to convert; magic-less PHY2 is valid legacy form |
| `POFF` | 0x004a9cf2 | Validated | effect consumer @0x4a9cf2: reads a fixed 0xC (Vec3) offset into @esi+0x30. Validated: body >= 0xC |
| `PRMG` | 0x0047817e | Validated |  |
| `PRMT` | 0x004783a5 | Validated |  |
| `PTCH` | 0x004a4cbe | Validated | renderable consumer @0x4a4c40: count×0x38 (56B) records, count @esi+0x20 (renderable INFO). (0x1d0 belongs to SCRB.) Validated: body % 0x38 == 0 |
| `PTMS` | 0x004a4e78 | Validated | renderable consumer @0x4a4c40: count×0x08 (8B) records, count @esi+0x30. Validated: body % 8 == 0 |
| `PTYP` | 0x00491ba9 | Validated | particle consumer @0x491ba9: reads a single flags byte (bit0→+0x205, bit1→+0x206). Validated: body >= 1 |
| `SOUN` | 0x0045f76d | Validated | ECS sound ref array @0x45f76d: count×4 u32 refs (overflow-guarded). Validated: body % 4 == 0 |
| `STRM` | 0x004782fd | Validated |  |
| `TEXT` | 0x00492fab | Validated | effect text/texture ref @0x492fab: reads a leading u32 (id/count) then variable data. Validated: body >= 4 |
| `TRCK` | 0x0068e7c3 | Validated | anim track @0x68e7c3: 12-byte inline header (3×u32) then count×4 parallel arrays (overflow-guarded). Validated: body >= 12 |
| `TRFM` | 0x0048cd09 | Validated | transform @FUN_0048cc30 (decomp): unrolled read of 16x4-byte floats = one 4x4 matrix. Validated: body >= 64 |
| `VALU` | 0x0067c9d7 | Validated | anim VALU @0x67c9d7: (count+1)×width value blob, u32 elements (overflow-guarded). Validated: body % 4 == 0 |
| `data` | 0x004a47d6 | Validated |  |
| `decl` | 0x004a47e2 | Validated |  |
| `flgs` | 0x00654f16 | Validated |  |
| `info` | 0x004a47ea | Validated |  |
| `schm` | 0x00654b6e | Validated |  |
| `AINF` | 0x0068c7de | Registered |  |
| `BSHP` | 0x004a4770 | Registered | blendshape data @FUN_004a4770 (decomp): container-walker that finds a child data chunk (0x61746164) and resolves its offset (NOT a count*0x18 array). Recognized/benign |
| `CEXE` | 0x004cf3d9 | Registered |  |
| `CHAR` | 0x004ac8e0 | Registered | renderable sub-chunk @FUN_004ac8e0 (decomp): dispatched alongside INFO/MTRL; reads a count and stack-allocs count*2. Recognized/benign (was mis-classified Misc) |
| `CHDR` | 0x004cf3bb | Registered |  |
| `DATA` | 0x0045f187 | Registered | ECS entity data @0x45f187: delegates body parse to template builder 0x631c90; no self-contained body invariant. Recognized/benign (distinct from lowercase data) |
| `DECL` | 0x0045dbb0 | Registered | context-dependent: ECS-template DECL @FUN_0045dbb0 is count×0x24 ([u32 id][0x20 blob]), but DECL in other asset types (material/resident) has a different layout, so no context-blind body invariant (retail block 3185 has a 10000-byte DECL) |
| `EMIT` | 0x00492703 | Registered | emitter timing @0x492703: delegates body parse to sub-reader 0x48cc30; no self-contained body invariant. Recognized/benign |
| `INDX` | 0x004719f3 | Registered |  |
| `ITEM` | 0x0067c315 | Registered |  |
| `MANM` | 0x0067a844 | Registered | anim-name @0x67a844: allocates a fixed 0x34 in-memory struct; body read is smaller (16 bytes in retail) — no confirmed body invariant. Recognized/benign |
| `MESH` | 0x00471923 | Registered | mesh dispatcher @0x471900: allocates a FIXED 0x10-byte renderable per descriptor, indexed by a u16; no body read, no count-driven array. Engine-safe; no self-contained body invariant |
| `NAME` | 0x00750a8f | Registered |  |
| `SCRB` | 0x004a4cac | Registered |  |
| `SINF` | 0x0067c30e | Registered |  |
| `SKIN` | 0x0047192a | Registered |  |
| `STAT` | 0x004cf5cf | Registered |  |
| `STRS` | 0x004640a0 | Registered |  |
| `SWIT` | 0x004cf5d7 | Registered |  |
| `TINY` | 0x00471a01 | Registered | low-LOD mesh @0x471a01: allocates a FIXED 0x18-byte renderable per descriptor, index-driven (like MESH); no body read. Engine-safe, no body invariant |
| `TREE` | 0x0045f629 | Registered | ECS tree/hierarchy @FUN_0045f3f0 (decomp): count (from INFO) variable-length records (4xu32 + u16 sub-count + sub_count xu16); 0x34 is the in-memory alloc, not an on-disk stride — no fixed body invariant |
| `TRNS` | 0x0068c7e5 | Registered |  |
| `TYPE` | 0x0067c8f9 | Registered | anim TYPE @0x67c8f9: count×2 u16 read where count is caller-passed (external, not in body) — no self-contained body invariant. Recognized/benign (separate from Stance TYPE converter arm) |
| `UNIQ` | 0x006549fb | Registered |  |
| `enum` | 0x006549dd | Registered |  |
| `flgt` | 0x00654f22 | Registered |  |
| `sequ` | 0x0067bfaa | Registered |  |
| `trns` | 0x0067e4d5 | NeedsInvestigation |  |

## D3DFORMAT pixel code (D3dFormat)

| Tag | VA | Status | Notes |
|-----|-----|--------|-------|
| `DXT1` | 0x0074d450 | NeedsInvestigation | D3DFORMAT pixel code, not a UCFX descriptor; texture-decode dispatch |
| `DXT2` | 0x0074d57a | NeedsInvestigation | D3DFORMAT pixel code, not a UCFX descriptor; texture-decode dispatch |
| `DXT3` | 0x0074d588 | NeedsInvestigation | D3DFORMAT pixel code, not a UCFX descriptor; texture-decode dispatch |
| `DXT4` | 0x0074d571 | NeedsInvestigation | D3DFORMAT pixel code, not a UCFX descriptor; texture-decode dispatch |
| `DXT5` | 0x0074d5a7 | NeedsInvestigation | D3DFORMAT pixel code, not a UCFX descriptor; texture-decode dispatch |
| `UYVY` | 0x0074d5ae | NeedsInvestigation | D3DFORMAT pixel code, not a UCFX descriptor; texture-decode dispatch |
| `YUY2` | 0x0074d581 | NeedsInvestigation | D3DFORMAT pixel code, not a UCFX descriptor; texture-decode dispatch |

## Runtime entity-type dispatcher (EntityRuntime)

| Tag | VA | Status | Notes |
|-----|-----|--------|-------|
| `ALPU` | 0x009ab6b4 | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `ARBU` | 0x009ab656 | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `CSID` | 0x009ab400 | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `EDGU` | 0x009ab642 | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `GMOH` | 0x009ab552 | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `GNIP` | 0x009ab600 | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `KCAH` | 0x009ab4d5 | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `LNCE` | 0x009ab448 | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `MAGC` | 0x009ab418 | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `MAGE` | 0x009ab44f | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `MAGH` | 0x009ab4dc | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `MAGR` | 0x009ab596 | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `MAGU` | 0x009ab65d | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `NNOC` | 0x009ab41f | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `PEEK` | 0x009ab5b0 | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `QRMH` | 0x009ab54b | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `RESU` | 0x009ab6bb | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `RFXH` | 0x009ab3de | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `SRGE` | 0x009ab456 | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `SRTH` | 0x009ab559 | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `SUBA` | 0x009ab40d | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `TADG` | 0x009ab3ef | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `TNCP` | 0x009ab5c2 | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `TNEP` | 0x009ab5a7 | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `TSLG` | 0x009ab4ce | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `TSLH` | 0x009ab4c5 | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `TSLL` | 0x009ab5bb | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `TSLR` | 0x009ab64b | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `TVLP` | 0x009ab607 | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |
| `VSER` | 0x009ab60e | NeedsInvestigation | runtime entity-type dispatcher @0x9ab; NOT a WAD chunk - requires deeper investigation |

## Network protocol key (NetworkProto)

| Tag | VA | Status | Notes |
|-----|-----|--------|-------|
| `OHCE` | 0x009917ee | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `arbb` | 0x0098ef95 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `atad` | 0x009ce50a | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `bcds` | 0x009d0345 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `cesb` | 0x0098ef8b | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `crsr` | 0x009c2c7c | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `csds` | 0x009d692d | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `csed` | 0x009d666f | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `csid` | 0x009ce3ab | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `csim` | 0x0098efcc | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `daeh` | 0x009ce56d | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `ddav` | 0x009d0371 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `dilc` | 0x009d1854 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `dlot` | 0x0098f031 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `dnab` | 0x0098ef3c | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `dnbb` | 0x009cce52 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `dnib` | 0x009cfd06 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `dnpa` | 0x009ce384 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `dosb` | 0x009c2c6d | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `edoc` | 0x009ce52f | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `edom` | 0x009d18d7 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `edrb` | 0x009c4f84 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `eldi` | 0x009d6435 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `emit` | 0x009ce440 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `enod` | 0x009ce4e8 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `etad` | 0x009ce583 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `etar` | 0x009d18ec | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `euqs` | 0x009ce464 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `gnol` | 0x0098efde | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `hslf` | 0x009d1869 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `hsup` | 0x009d0240 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `htua` | 0x0098ef6d | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `kclb` | 0x009ca789 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `kcos` | 0x009d1800 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `ledv` | 0x009d03c0 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `lfbl` | 0x0098efd6 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `lfmg` | 0x009a5c37 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `llop` | 0x009d0081 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `lluf` | 0x009c99d9 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `lrtc` | 0x009d63bb | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `magn` | 0x0098eff8 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `mand` | 0x009d63e7 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `manx` | 0x009cfdbf | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `maps` | 0x009ce428 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `mgni` | 0x0098efb1 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `morn` | 0x0098f014 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `nedj` | 0x0098ef2e | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `nepo` | 0x009cce1a | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `nftn` | 0x0098f020 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `nlno` | 0x009cceaf | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `nnoc` | 0x009cce59 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `nrud` | 0x009d640e | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `pamx` | 0x009cfd88 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `pdda` | 0x009d65d4 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `peek` | 0x009ce3fe | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `potv` | 0x009d1825 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `ptni` | 0x009d6533 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `ptxe` | 0x009d6503 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `pxam` | 0x009cfd71 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `rapb` | 0x0098ef9d | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `ravg` | 0x009d68ef | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `rcam` | 0x009d644c | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `rdag` | 0x009d6831 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `rdal` | 0x009cffca | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `rdam` | 0x009cffef | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `rdar` | 0x009d031d | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `rdda` | 0x009c5a53 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `reep` | 0x009cfe8a | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `resu` | 0x009c2c9d | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `revh` | 0x009ce3e5 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `rudl` | 0x009d654b | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `sdns` | 0x009d17b5 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `sndx` | 0x009d042f | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `sohn` | 0x0098efc2 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `ssap` | 0x009c2c8c | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `sses` | 0x009c2c96 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `ssim` | 0x009c2c44 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `svcr` | 0x009d1773 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `tats` | 0x009cfeac | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `torp` | 0x0098f006 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `tpgg` | 0x009d685d | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `trba` | 0x009d64e4 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `trop` | 0x009d6563 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `trpa` | 0x009d66bd | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `trpd` | 0x009d67cb | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `trpg` | 0x009d68a0 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `trpl` | 0x009d1764 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `tset` | 0x009d65e7 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `tsmg` | 0x009a5c3e | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `tsoh` | 0x009ce49a | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `tsxe` | 0x009c99d1 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `txth` | 0x009ce58e | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `txtr` | 0x009ce4c1 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `ueuq` | 0x0099dada | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `wten` | 0x009c2c85 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `xamr` | 0x009ce413 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `xcam` | 0x009cce7a | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `ydbr` | 0x009d6489 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `ydob` | 0x009ce578 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |
| `yldn` | 0x009d0031 | NeedsInvestigation | network protocol message key; NOT a WAD chunk - requires deeper investigation |

## Lua property accessor (LuaReflection)

| Tag | VA | Status | Notes |
|-----|-----|--------|-------|
| `alpf` | 0x00976527 | NeedsInvestigation | Lua/object property accessor key; NOT a WAD chunk - requires deeper investigation |
| `bolb` | 0x0097657a | NeedsInvestigation | Lua/object property accessor key; NOT a WAD chunk - requires deeper investigation |
| `bulc` | 0x00976599 | NeedsInvestigation | Lua/object property accessor key; NOT a WAD chunk - requires deeper investigation |
| `gsmx` | 0x0097665c | NeedsInvestigation | Lua/object property accessor key; NOT a WAD chunk - requires deeper investigation |
| `ihca` | 0x00976551 | NeedsInvestigation | Lua/object property accessor key; NOT a WAD chunk - requires deeper investigation |
| `kbdf` | 0x009765a0 | NeedsInvestigation | Lua/object property accessor key; NOT a WAD chunk - requires deeper investigation |
| `knar` | 0x009765e6 | NeedsInvestigation | Lua/object property accessor key; NOT a WAD chunk - requires deeper investigation |
| `knhc` | 0x00976538 | NeedsInvestigation | Lua/object property accessor key; NOT a WAD chunk - requires deeper investigation |
| `musg` | 0x009765ff | NeedsInvestigation | Lua/object property accessor key; NOT a WAD chunk - requires deeper investigation |
| `ossa` | 0x00976541 | NeedsInvestigation | Lua/object property accessor key; NOT a WAD chunk - requires deeper investigation |
| `pcer` | 0x0097664e | NeedsInvestigation | Lua/object property accessor key; NOT a WAD chunk - requires deeper investigation |
| `sbus` | 0x00976655 | NeedsInvestigation | Lua/object property accessor key; NOT a WAD chunk - requires deeper investigation |
| `serp` | 0x0097662d | NeedsInvestigation | Lua/object property accessor key; NOT a WAD chunk - requires deeper investigation |
| `sysf` | 0x009765f8 | NeedsInvestigation | Lua/object property accessor key; NOT a WAD chunk - requires deeper investigation |
| `tcca` | 0x0097654a | NeedsInvestigation | Lua/object property accessor key; NOT a WAD chunk - requires deeper investigation |
| `tlif` | 0x009765a7 | NeedsInvestigation | Lua/object property accessor key; NOT a WAD chunk - requires deeper investigation |
| `wonp` | 0x009765ef | NeedsInvestigation | Lua/object property accessor key; NOT a WAD chunk - requires deeper investigation |

## Unclassified (Misc)

| Tag | VA | Status | Notes |
|-----|-----|--------|-------|
| `GGGG` | 0x0057e9d5 | NeedsInvestigation | unclassified FourCC immediate - requires deeper investigation |
| `HHlP` | 0x004eea8a | NeedsInvestigation | unclassified FourCC immediate - requires deeper investigation |
| `INVD` | 0x0059cffc | NeedsInvestigation | unclassified FourCC immediate - requires deeper investigation |
| `Mxm ` | 0x00713eb3 | NeedsInvestigation | unclassified FourCC immediate - requires deeper investigation |
| `fVZD` | 0x005f40b8 | NeedsInvestigation | unclassified FourCC immediate - requires deeper investigation |
| `kVAR` | 0x0041d612 | NeedsInvestigation | unclassified FourCC immediate - requires deeper investigation |
| `uZmI` | 0x004f1ab2 | NeedsInvestigation | unclassified FourCC immediate - requires deeper investigation |
| `udn8` | 0x004f19d8 | NeedsInvestigation | unclassified FourCC immediate - requires deeper investigation |

---

# Curated semantics & implementation guide (hand-maintained)

Everything below this marker is hand-curated and is NOT regenerated from `tag_registry.rs`.
Compiled 2026-07-03 from three independent passes that were then reconciled:
(1) the Ghidra decomp (`output/_ghidra/all_functions_decomp.txt`) + our converter/engine code,
(2) blind external research on the Pandemic Studios format lineage,
(3) blind external research on industry FourCC/chunk conventions.
Confidence is flagged where the sources disagree or the claim is inference.

## 1. Where UCFX comes from (external lineage)

- Pandemic used 4-char-tag chunk formats on both ends of its pipeline since SWBF (2004):
  source `.msh` (HEDR/MSH2/SINF/NAME/MODL/GEOM/SEGM/MATL/ATRB/BBOX/FLGS/TRAN…) → offline
  **"munge"** compile → runtime **`ucfb`** containers in `.lvl` files (inline tag+size tree;
  lowercase *class* chunks `modl/segm/skel/tex_/scr_/inst`, uppercase *leaf* chunks
  `NAME/INFO/BODY/MTRL/IBUF/XFRM`). UCFX keeps that vocabulary (GEOM, SEGM, MTRL, NAME, INFO,
  BODY, IBUF, SINF, ATRB, INST, TYPE, TREE, NODE, SKIN, PTCH…) but replaces ucfb's inline tree
  with an **indexed container** (20-byte header + 20-byte descriptor rows + data area + CSUM
  trailer) — structurally closer to the FFCS WAD header (rows of tag/offset/count) than to ucfb.
- "ucfb" expansion is publicly unconfirmed ("probably 'UCF binary'"); "UCFX = UCF eXtended" is
  plausible but pure speculation — do not cite as fact.
- **`sges` segmented-zlib compression is shared verbatim with The Saboteur** (PredatorCZ/
  SaboteurToolset `compressed.hpp` parses the identical header) — a direct engine-lineage link.
  Saboteur otherwise diverged (MSHA meshpacks; no UCFX/FFCS in its toolset).
- Public RE state of the art (XeNTaX t=3172, 2008–2010; aluigi's `mercs2.bms` v0.1.1) documents
  FFCS/INDX/PTHS/sges and the *existence* of UCFX, but models the container as
  `u32 count + 16-byte entries` — under-modeled. **Our 20-byte descriptor-row layout is ahead of
  all public documentation.** External corroboration: aluigi's `offset *= 0x8000` matches our
  `page_count<<15` buffer-sizing finding.
- ucfb-attested meanings that carry over (swbf-unmunge / LibSWBF2 / natanalt): `INFO` =
  per-class metadata header preceding payloads (modl INFO = bboxes + face count; tex INFO =
  format/dims/mips); `BODY` = raw payload bits, **one per texture mip** (`LVL_`); `NAME` = name
  string; `MTRL` = material record; `segm` = one material's draw batch (INFO/MTRL/IBUF/VBUF
  children); `TREE` (in `coll`) = collision bounding tree; `inst` = placed instance
  (TYPE/NAME/XFRM/SIZE + PROP hash/value pairs).

## 2. Container conventions (verified against retail + industry)

- Root: `"UCFX"` + `u32 data_off` + 2×u32 + `u32 n_desc`; then n_desc × 20-byte rows
  `{tag, u0, size, x2, x3}`. `u0 == 0xFFFFFFFF` ⇒ **marker/container row** (x2 = reverse
  ordinal, x3 = subtree descendant count); otherwise payload at `data_off + u0`. Marker rows are
  the "-1 sentinel" convention — never do pointer arithmetic on them. See
  `docs/format_reference.md` and `tools/wad_simulator/docs/modernization/accessory_bone_binding_A.md`.
- `CSUM` = 8-byte trailer (`CSUM` + u32 CRC-32, init=0, no final XOR) over the container body.
  **Recompute on every rewrite** — the engine rejects stale checksums.
- Lowercase vs uppercase: same rule as ucfb / the RIFF registry — lowercase tags are **private
  leaves meaningful only under their parent** (`data`/`decl`/`info` under STRM|IBUF;
  `schm`/`enum`/`flgs`/`flgt` under COMP/layer; `sequ`/`trns` under anim). Dispatch on
  *(parent context, tag)*, never on tag alone (`DATA` ≠ `data`, `DECL` ≠ `decl`).
- `INFO` is context-polymorphic (≥8 distinct layouts in `ucfx_byteswap/convert.rs`, keyed on the
  container `type_hash`: texture / model / script / CFX / stance / anim / ECS / mesh-60B). A
  loader must carry "current INFO" context; counts for sibling arrays (PRMT, BSHI, SWIT, ITEM,
  TYPE…) frequently come from INFO fields, **not** from the sibling body.

## 3. Model/geometry path (engine-critical)

Retail loads a model as a two-level walk: `FUN_00478120` (GEOM container walker: on child INFO
reads u32 group count → allocates count × 0x1C4 drawing-group records) → `FUN_00478270` per PRMG
group (STRM/PRMT/IBUF/BSHI/BSHP/AREA/INFO) → leaf readers `FUN_004a4770` (STRM data/decl/info),
`FUN_004a48f0` (IBUF), `FUN_004a4ab0` (AREA), `FUN_004a8690` (BNDS + collision-mesh arms).

| Tag | Meaning | Retail ground truth | Our implementation |
|-----|---------|---------------------|--------------------|
| `GEOM` | geometry root container (attested verbatim in Pandemic `.msh`) | marker row enclosing INFO/PRMG/BNDS/… subtree, walked by FUN_00478120. **Caveat:** registry VA 0x48ccbd is a *different* GEOM arm inside FUN_0048cc30 (effect-side leaf reading 2×u16 table indices) | `model_cubeize.rs` GEOM walk; engine `mesh.rs::build_indexed_state` |
| `PRMG` | primitive/render group = one drawable batch (ucfb `segm` analog) | each PRMG fills one 0x1C4 drawing-group record | one `DrawGroup` per PRMG |
| `PRMT` | primitive records, 16-byte stride | **unresolved conflict** — see caveat below | `convert.rs::PRMT_WALKER` |
| `STRM` | vertex stream container | children `data`/`decl`/`info`; the group INFO(60B) drives strides: `[0x6d]`,`[0x6f]` counts → two 16B-stride streams, `[0x6a]` = blendshape count | `strm_info/decl/data` in model_cubeize; `apply_strm_vertex_fix` |
| `decl` | literal `D3DVERTEXELEMENT9[]` (8B elements, 0xFF-stream terminator) | created via FUN_00752b30 | authoritative for vertex layout — never infer from stride. Xbox uses 12B elements → `apply_decl_translate`. DEC3N = 10-10-10-2 (see dec3n tangent RCA) |
| `data` | raw buffer bytes (context: vertex bytes under STRM, index bytes under IBUF, Havok anim blob under anim type) | bound via FUN_00752890 | meaning = (parent, INFO) context |
| `info` | 12B (3×u32) buffer descriptor | under STRM: 2nd u32 = vertex count/stride (FUN_007524a0); under IBUF: u32 index count | model_cubeize |
| `IBUF` | index buffer | `info` u32 count + `data` raw u16 indices | models draw as **strips with degenerate stitching** — emit strips, not lists |
| `INDX` | rigid-mesh → skeleton binding | N×u16; entry *i* = HIER node index for MESH group *i* | `parse_indx_chunk`; u16 swap |
| `BNDS` | bounds, 40 bytes | `{vec3 sphere center, f32 radius}` → +0x4c and `{vec3 aabb min, vec3 max}` → +0x34 (FUN_004a8690). Sphere+box combo matches Pandemic BBOX convention | culling/streaming input; no validator yet |
| `AREA` | sub-mesh region container | container walk, 4B `info` header per child (FUN_004a4ab0); rigid MESH sub-objects carry AREA | mesh sub-area container |
| `MTRL` | material (ucfb MTRL analog) | tex count @+0x106 → fixed 10-slot `{hash, 0xF011157A("texture"), 0}` array @+0xAC; parser FUN_00858790 (`__stdcall`); >10 slots overruns → AV 0x84DD5B | `texture.rs::parse_mtrl`; converter per-field swap (blanket u32 swap caused the world-load crash) |
| `MESH` | rigid-mesh renderable marker | fixed 0x10 renderable per descriptor, u16-indexed; **no body read** | pair with INDX for bone binding |
| `SKIN` | skinned-mesh marker | selects skinned path; BLENDINDICES are **per-group palette-relative** (group INFO range-table concat), NOT global HIER — spec §1.4 "GLOBAL" is wrong | see `blendindices` docs; wavelet anim decode |
| `TINY` | low-LOD / imposter mesh | fixed 0x18 renderable, index-driven like MESH | LOD selection is distance-driven |
| `SEGM` | **missing from registry** — draw-group→bone palette binding | 4B records `[u16 bone-remap (BE)][u8 seg][u8 group]` | `convert.rs` SEGM arm; `segm_group_bone_binding.md` |
| `HIER` | **missing from registry** — skeleton | 0xB0 (176B)-stride node array `{u32 name-hash, u16 index@+4, u16 parent@+6 (0xFFFF=root), f32 matrix+bbox @+8}` | `convert_hier_inplace` (u16-swapping the f32 region → NaN bbox hazard); `skeleton.rs` |
| `INST` | instance records (ucfb `inst` analog) | count×0x18, count from renderable INFO @esi+0x28 (FUN_004a4c40) | resolve model hash against library; keep instances as handles |
| `CHAR` | renderable sub-chunk | FUN_004ac8e0: count + stack-alloc count×2 | reclassified from Misc 2026-07 |
| `SCRB` | "scrub" shader-resource binary | ASET type 12 = SCRB+MTRL+STRM+INFO; owns the 0x1d0 record size | — |
| `BSHP`/`BSHI` | blendshapes (sparse morph = indices + deltas) | BSHP = container-walker resolving a child `data` chunk (NOT count×0x18); BSHI = count×2 u16 sparse vertex indices, count from mesh INFO `[0x6a]` | apply deltas in bind-pose space before skinning; validate max(BSHI) < vertex count |

**PRMT caveat (unresolved):** `convert.rs` models PRMT as 16B *draw-call* records
`[u32 matidx][u32 start_index][u16 count][u16 base_vertex][u16 max_vtx][u16 span]`; the mesh
decomp (FUN_00478270) shows PRMT filling two INFO-sized 16B-stride streams; the collision-mesh
PRMT arm (FUN_004a8690) reads `u32 matidx + 2×u32 + 4×u16`. All are 16-byte stride so current
byteswaps are safe, but resolve the field semantics before writing any PRMT-authoring feature.

## 4. Texture path (`FUN_00750a30`)

- `INFO`: dims/mips/format header — `u16 w,h`, mip count, `u32 D3DFORMAT fourcc`, `u32 total
  size` (+ per-level u16s). Offsets per `docs/format_reference.md §4.3`; converter
  `convert_texture_info`.
- `BODY`: raw DXT mip chain (X360 sources are GPU-tiled → `apply_texture_untile`). **Streamed
  high mips are lone BODY chunks in the finer c3-cell LOD blocks of the texture's own subtree**;
  assemble by size-descending concat (`wad::extract_texture_hires`, `--tex-audit/--tex-locate`).
- `NAME`: asset name string into a 256B buffer (FUN_00825dc0); never byte-swapped.
- `DXT1/3/5`, `UYVY`, `YUY2`: literal `D3DFORMAT` codes (same values DDS uses), not chunk tags.
  Modern mapping: DXT1→BC1, DXT3→BC2, DXT5→BC3; UYVY/YUY2 (video surfaces) need a conversion
  pass on wgpu — no native support.

## 5. Script container (`FUN_0059cf90`, type_hash 0x42498680 "script")

- container `INFO`: `[u8][u16 name_len][name…][u16][u8]` framing.
- `BINN`: raw compiled LuaQ, body size from the descriptor row (ucfb `scr_` is the exact
  analog). Converter: unluac disassemble → flip endianness → reassemble
  (`apply_binn_transcode`); the pre-LuaQ framing (name + dep hashes) is per-field swapped.
  Preserve the 80B header verbatim on chunk replace (see ucfx-script-replace bug memory).
- `DEPS`: `[u8 count][count×u32 asset-hash]` — drives load order and refcounts; swap only the
  hash array, preserve the count byte.
- `INVD`: **identified 2026-07-03** — abort/invalid sentinel (`return 0`) in the same script
  loader, not an unclassified tag. Should move Misc→UcfxAsset(script) in the registry.

## 6. ECS / reflection / placement clusters

Component cluster (`FUN_00654940`, "layer"): 

- `COMP`: component definition; children `info` = `{u32 name_hash, u32 type_hash, u32 count, …}`
  (type resolved via registry lookup FUN_008242b0), `schm`, `data`. **Parse `schm` first and
  drive all `data` decoding from the schema** (220 schemas documented in `docs/mercs2-ecs/`);
  never hard-code offsets.
- `schm` = schema-string parser (VM stub); `enum` = enum string tables; `UNIQ` =
  `[u32 count][count×u32]`; `flgs` = `[u32 count][count×0x20 records]`; `flgt` = flag-table
  variant. In `layers_static`, COMP child offsets are relative to the end of the descriptor
  table (`placement_data_format.md §2.3`).
- `DATA` (uppercase): delegates to template builder 0x631c90 — treat as opaque; `DECL`
  (uppercase): context-dependent (ECS-template = count×0x24 `[u32 id][0x20 blob]`).
- `DAMG`/`DEBR`/`PART`/`SOUN`: count×4 u32 asset-hash ref arrays on entity templates — the
  destruction/VFX/audio hookup (damage state → debris model + particle + sound). Resolve lazily,
  preserve order (index-aligned with states/events).
- `TREE`: variable-length hierarchy records `(4×u32 + u16 sub-count + sub×u16)`; 0x34 is the
  in-memory alloc, not a disk stride.

Behavior/placement graph cluster (`FUN_004cf340`, ECS_PlacementParse):

- `NODE`: `u32 hash + u32 child-count` + count×0x14 children (graph node).
- `CHDR`: `{u32 property_hash, u32 count}` slot header — **dual layout**: model-context CHDR is
  full-u32 rows, placement-context is `{u16,u16,u32}` (type-aware swap; see chdr-dual-layout).
- `CEXE`: count×u32 expression/bytecode stream, count from the preceding CHDR.
- `STAT`: one u32 state hash per record (placement variant states, e.g. pristine/ruined).
- `SWIT`: count×u32 switch targets, count from container INFO+0xc.

## 7. FX cluster (fxdict `FUN_00491320`; effect loader 0x492AF0)

- `DICT` (fxdict, resident singleton): container INFO = u32 count; DICT body = count ×
  **20-byte on-disk records** `{u32 name_hash, f32 default, f32, f32, u32 flags}` (630×20 =
  12600B, zero slack — empirically verified), loaded into count×0x20 **in-memory** records (the
  decomp's 0x20 is the alloc stride, not the disk stride). Hash namespace is shared with effect
  `TEXT` chunks.
- `EFCT` (**missing from registry**): u16-packed effect header — magic 0x0226 @ +2,
  sub-component count @ +14. Words pack two u16 halves; must byteswap as u32 or the count zeroes
  → NULL-deref @ 0x493102 (`spatial_hash_crash_analysis.md`).
- `EMTR`: u16 count + count×4 module refs; `EMIT`: emitter timing, delegates to FUN_0048cc30.
- `ATRB` / `FRCE`: 4-byte inner hash → per-attribute / per-force-type sub-readers
  (gravity/drag/vortex taxonomy). Implement as hash→typed-reader dispatch; **skip unknown hashes
  by size, don't abort** — attribute sets grow across versions.
- `COLR`: fixed 0xC8 (200-byte) gradient/palette record into the effect palette heap (sampled by
  particle age). The older "16-byte-stride color keys" reading in `fxdict_format.md §4.2` was a
  low-confidence hypothesis — the fixed-0xC8 handler read supersedes it.
- `TEXT`: leading u32 + u32 hash list (texture/param refs — not ASCII text).
- `PTYP`: 1 flags byte (bit0→+0x205, bit1→+0x206); `POFF`: vec3 emitter offset;
  `TRFM`: 16×f32 4×4 matrix (row-major, D3D convention); effect-arm `GEOM`: 2×u16 table indices.
- `PTCH` count×0x38 / `PTMS` count×8: renderable-consumer records (FUN_004a4c40 family), counts
  from the renderable INFO. Likely attachment/patch descriptors — check first u32 of each PTCH
  record for bone hashes to confirm (unverified).
- `AKEY` / `ANIM` listed in `fxdict_format.md §4` **do not exist** as dispatched FourCCs — no
  hits in registry, tags.rs, convert.rs, or the binary scan. Stale doc; the anim path uses
  TRCK/VALU/KEYS/MANM/TRNS/MINF/ASTO, and Havok anim payloads ride in `data` chunks under
  type_hash 0x18166555.

## 8. Animation cluster

- `sequ` → `SINF`/`ITEM` (FUN_0067c2b0, caller FUN_0067bf40): SINF reads a name and hashes it
  with an **inline Pandemic FNV-1a** (seed 0x811c9dc5, `|0x20` case-fold, `^0x2a`, ×0x1000193 —
  confirms the pandemic_hash algorithm in-engine), then u16 item count → count×0xC records;
  ITEM = per-item VM-stub reader (count from SINF).
- `KEYS`: u32 count + count×8 `{time,payload}` keys; `VALU`: (count+1)×width endpoint values —
  the +1 is the interval-evaluation fencepost (N intervals need N+1 endpoints); keep KEYS/VALU
  as parallel arrays. `TRCK`: 12B header (3×u32: target hash/type/count) + count×4 parallel
  arrays. `MINF`: `[u32 hash][u16]` 6B records binding meshes↔clips. `ASTO`/`TYPE`: directory /
  u16-type tables (counts external). `MANM`: name→clip registry record (0x34 in-memory).
- `AINF`/`TRNS` (uppercase): handler VAs fall in an un-extracted decomp gap (0x68c300–0x68ce85)
  and their FourCC constants never appear as LE immediates → BE-compared or jump-table
  dispatched. Converter ground truth: `TRNS` = NUL-terminated ASCII state-name strings, **never
  swapped** (rosetta-oracle verified). `trns` (lowercase, FUN_0067e470) still unidentified.
- Stringdb `KEYS`/`STRS` twins (`SYEK`/`SRTS` in tags.rs) are **natively big-endian on all
  platforms** — never swap (`format_reference.md §4.1`).

## 9. Non-WAD tag groups decoded: reversed-ASCII protocol keywords

The scanner rendered `cmp` immediates in **memory byte order**, so C-style multichar constants
(`cmp eax, 'CONN'`) appear mirrored (`NNOC`). Verified in decomp: FUN_009ab370 compares
0x44495343="DISC", 0x434f4e4e="CONN", 0x50494e47="PING", 0x4b454550="KEEP", 0x4841434b="HACK",
0x55534552="USER"…; FUN_009917b0 compares 0x4543484f="ECHO" (registry `OHCE`).
**Decode rule: reverse the registry tag string.**

### 9.1 "EntityRuntime" group = MP session/matchmaking dispatcher (FUN_009ab370)

The registry label "runtime entity-type dispatcher" is wrong — FUN_009ab370 is a session-layer
message dispatcher (each arm constructs a handler and falls back to a vcall when a
lock/guard byte is set). All 30 keywords, decoded (expansion guesses marked `?`):

| Registry | Keyword | Reading | Registry | Keyword | Reading |
|----------|---------|---------|----------|---------|---------|
| `ALPU` | UPLA | update player? | `QRMH` | HMRQ | host-migration request? |
| `ARBU` | UBRA | ? | `RESU` | USER | user |
| `CSID` | DISC | disconnect | `RFXH` | HXFR | host transfer? |
| `EDGU` | UGDE | update? | `SRGE` | EGRS | egress? |
| `GMOH` | HOMG | host migration? | `SRTH` | HTRS | host transition? |
| `GNIP` | PING | ping | `SUBA` | ABUS | abuse report? |
| `KCAH` | HACK | anti-cheat/hack | `TADG` | GDAT | game data |
| `LNCE` | ECNL | cancel? | `TNCP` | PCNT | player count |
| `MAGC` | CGAM | create game | `TNEP` | PENT | player entered? |
| `MAGE` | EGAM | end game | `TSLG` | GLST | game list |
| `MAGH` | HGAM | host game | `TSLH` | HLST | host list |
| `MAGR` | RGAM | register game? | `TSLL` | LLST | lobby list |
| `MAGU` | UGAM | update game | `TSLR` | RLST | ?-list |
| `NNOC` | CONN | connect | `TVLP` | PLVT | ? |
| `PEEK` | KEEP | keepalive | `VSER` | RESV | reserve slot? |

### 9.2 NetworkProto group = key/value message field keys

Same decode rule; the vocabulary is a classic GameSpy-era session protocol (auth, addresses,
ports, lists, latency). Keyword families: ports `aprt/dprt/gprt/lprt`, addresses
`gadr/ladr/madr/radr/addr`, timing `time/date/rate/ldur/durn?/ndly`. Full decode
(`?` = reversal doesn't form an obvious word):

| Tag→Key | Tag→Key | Tag→Key | Tag→Key | Tag→Key |
|---------|---------|---------|---------|---------|
| OHCE→ECHO | dnpa→apnd | llop→poll | rdag→gadr | tset→test |
| arbb→bbra? | dosb→bsod? | lluf→full | rdal→ladr | tsmg→gmst |
| atad→data | edoc→code | lrtc→ctrl | rdam→madr | tsoh→host |
| bcds→sdcb? | edom→mode | magn→ngam? | rdar→radr | tsxe→exst |
| cesb→bsec? | edrb→brde? | mand→dnam? | rdda→addr | txth→htxt |
| crsr→rsrc | eldi→idle | manx→xnam? | reep→peer | txtr→rtxt |
| csds→sdsc? | emit→time | maps→spam | resu→user | ueuq→queu |
| csed→desc | enod→done | mgni→ingm | revh→hver | wten→netw |
| csid→disc | etad→date | morn→norm | rudl→ldur | xamr→rmax |
| csim→misc | etar→rate | nedj→jden? | sdns→snds? | xcam→macx? |
| daeh→head | euqs→sque? | nepo→open | sndx→xdns? | ydbr→rbdy |
| ddav→vadd? | gnol→long | nftn→ntfn | sohn→nhos? | ydob→body |
| dilc→clid | hslf→flsh | nlno→onln | ssap→pass | yldn→ndly |
| dlot→told | hsup→push | nnoc→conn | sses→sess | |
| dnab→band | htua→auth | nrud→durn? | ssim→miss | |
| dnbb→bbnd? | kclb→blck | pamx→xmap? | svcr→rcvs? | |
| dnib→bind | kcos→sock | pdda→addp? | tats→stat | |
| — | ledv→vdel? | peek→keep | torp→prot | |
| — | lfbl→lbfl? | potv→vtop? | tpgg→ggpt? | |
| — | lfmg→gmfl? | ptni→intp? | trba→abrt | |
| — | — | ptxe→extp? | trop→port | |
| — | — | pxam→maxp | trpa→aprt | |
| — | — | rapb→bpar? | trpd→dprt | |
| — | — | ravg→gvar | trpg→gprt | |
| — | — | rcam→macr? | trpl→lprt | |

### 9.3 LuaReflection group = profile/social property keys

Decoded: `alpf`→FPLA?, `bolb`→BLOB, `bulc`→CLUB, `gsmx`→XMSG, `ihca`→ACHI(evement),
`kbdf`→FDBK (feedback), `knar`→RANK, `knhc`→CHNK, `musg`→GSUM (game summary?), `ossa`→ASSO,
`pcer`→RECP?, `sbus`→SUBS, `serp`→PRES(ence), `sysf`→FSYS?, `tcca`→ACCT, `tlif`→FILT(er),
`wonp`→PNOW (play now). Reads as an online profile/social key set (rank, account, presence,
clubs, achievements) — medium confidence, individual arms not yet decompiled.

### 9.4 Misc leftovers

`INVD` identified (script-loader sentinel, §5); `CHAR` reclassified into UcfxAsset. The rest
(`GGGG`, `HHlP`, `Mxm `, `fVZD`, `kVAR`, `uZmI`, `udn8`) don't decode by reversal and are likely
ASCII-looking immediates rather than FourCCs — still unclassified.

## 10. Registry gaps / follow-ups

1. **Add `SEGM`, `HIER`, `EFCT` to `TAG_REGISTRY`** — real UCFX chunks, converter-handled, but
   absent because their engine dispatch is not a LE `cmp eax,imm32` (BE-compared or jump-table),
   so the scan missed them. Handler hunt = follow-up. Same for converter-known `evnt`
   (`[u32 count][u32 ts + 2 NUL strings]`), `trnm` (`[u16 count][u16 pad][u32 hashes]`), `watr`
   (watermap), `CERP` (precache), `SYEK`/`SRTS` (native-BE stringdb).
2. **Registry label fix:** `Subsystem::EntityRuntime` → "MP session message dispatcher" (§9.1);
   per-tag decoded notes for all three non-WAD groups.
3. **`INVD`** Misc→UcfxAsset (script sentinel); **`trns`** (lowercase) still needs its handler
   (FUN_0067e470) read.
4. **PRMT field-semantics conflict** (§3 caveat) — resolve before any PRMT-authoring feature.
5. **GEOM registry VA** points at the effect-arm leaf, not the geometry walker — consider
   recording both sites (0x478120 walker; 0x48cc30 effect arm) in the registry note.
6. `AINF`/`TRNS` retail handlers live in an un-extracted decomp gap — re-run Ghidra export over
   0x68c300–0x68ce85.
7. This file's tables were re-synced from `tag_registry.rs` by hand on 2026-07-03. There is no
   generator script; if the registry changes again, either re-sync by hand or write the small
   Rust emitter (`mercs2_formats` example) and keep this curated half below the marker.

## 11. `mercs2_engine` coverage snapshot (2026-07-03)

Consumed by the Rust engine today: geometry via `model_cubeize` (GEOM/PRMG/STRM/`decl`/`data`/
`info`/IBUF/PRMT/POFF) in `game_world.rs::load_one_c3_cell` / `load_terrainmesh_tile` +
`mesh.rs::build_indexed_state`; materials via `texture.rs::parse_mtrl`; skeleton via
`skeleton.rs` (HIER/SEGM); textures via `wad::extract_texture[_hires]` (INFO/BODY); terrain per
`format_reference.md §13`. **Converted/validated but not yet engine-loaded:** TRCK/VALU/KEYS
(anim clips — `LoadedModel.clips` is empty), PHY2 (collision), the FX cluster, and the
ECS/placement clusters (streaming runtime consumes placements upstream). Validators live in
`wad_simulator/chunk_invariants.rs`, `mercs2_formats/chunk_validate.rs`, `aset_validate.rs`;
byteswap in `ucfx_byteswap/convert.rs`.

## External sources

- natanalt — SWBF2 `.lvl`/ucfb format notes: <https://gist.github.com/natanalt/2ef697e53e56d6abfb42a644f6317d68>
- schlechtwetterfront — Pandemic `.msh` spec: <https://schlechtwetterfront.github.io/ze_filetypes/msh.html>
- PrismaticFlower/swbf-unmunge (modl/segm/MTRL/skel handlers): <https://github.com/PrismaticFlower/swbf-unmunge>
- Ben1138/LibSWBF2 (ucfb chunk headers incl. coll TREE.NODE, tern PTCH.IBUF): <https://github.com/Ben1138/LibSWBF2>
- XeNTaX t=3172 "Mercenaries 2 .WAD file" (grimdoomer FFCS layout; aluigi UCFX/sges notes): <https://web.archive.org/web/20231019071717/https://forum.xentax.com/viewtopic.php?t=3172>
- XeNTaX t=8930 (2012 state of the art; "nobody has written a model extractor"): <https://web.archive.org/web/20210725194428/https://forum.xentax.com/viewtopic.php?f=10&t=8930>
- aluigi `mercs2.bms` QuickBMS script: <http://aluigi.altervista.org/bms/mercs2.bms>
- PredatorCZ/SaboteurToolset (`sges` twin in `compressed.hpp`): <https://github.com/PredatorCZ/SaboteurToolset>
- Microsoft — `D3DVERTEXELEMENT9` / vertex declarations: <https://learn.microsoft.com/en-us/windows/win32/direct3d9/d3dvertexelement9>
- RIFF case conventions: <https://en.wikipedia.org/wiki/Resource_Interchange_File_Format>
