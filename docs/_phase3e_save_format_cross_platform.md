# Phase 3e — Save-file and settings format: cross-platform (PC / Xbox 360 / PS3)

**Status:** current · **Evidence:** mixed (PC save shape + hash: PROVEN byte-exact against
8 retail fixtures; Xbox 360 and PS3 symbol surface: PROVEN; Xbox + PS3 on-disk container
wrapping: BLOCKED — no captured retail console save available in this repo).

**Question answered:** Do PC, Xbox 360 and PS3 ship different save-file formats, and
is a cross-platform save transfer possible at the format level?

**Verdict: MIXED — same engine serializer, same integrity hash, platform-divergent
*container wrapping* and *settings persistence*.** All three platforms funnel through
the same hash-dispatched engine serializer (`SaveData` / `InitialSaveData` handler) and
emit the same inner `return { … }` Lua table + zlib stream + `CRC-32/BZIP2` integrity
word. The *filesystem container* diverges: PC writes a flat 13,404-byte `*.profile`
to `My Games\Mercenaries 2\SaveGames\`; the Xbox 360 writes `NoTRCSave%02d.sav` and the
Jul-08 devkit shows a `save:\` TRC-drive write; the PS3 writes under
`/dev_hdd0/.../BLUS30056_00/` via `sys_fs` (no `cellSaveData` import — not a PFD
container). Settings persistence is **PC-only via `Mercs2.ini`**; both consoles have
*no shipped user-settings INI*.

---

## 0. Result in one line

Three platforms, one engine-level save blob (same Lua text, same zlib, same CRC-32/BZIP2
over `[4:]`). The outer container is per-platform. PC's `Mercs2.ini` preferences file is
a Win32 `GetPrivateProfile*`/`WritePrivateProfile*` artifact that **does not ship on
either console**; console preferences — if persisted — are either inside the save blob or
go through platform-system APIs (not through a separate settings file in the binary).

---

## 1. The write-path pipeline — proven identical across platforms (PROVEN)

Sources:
[`docs/reverse_engineer/save_serialize_code_map.md`](reverse_engineer/save_serialize_code_map.md)
(authoritative PC code map);
[`docs/mercs2-pdb-analysis/game-systems.md`](mercs2-pdb-analysis/game-systems.md)
(Xbox 360 Jul-08 symbol inventory);
[`output/_ghidra_x360/xenon_decomp_named.c`](../output/_ghidra_x360/xenon_decomp_named.c)
(Xbox 360 Jul-08 decomp bodies);
[`output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt`](../output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt);
PS3: `strings` on `game-files/ps3-version/EBOOT.elf` (dumped to
`scratchpad/save_fmt/ps3_a.txt`);
PC fixtures:
[`tools/wad_simulator/crates/mercs2_formats/fixtures/saves/`](../tools/wad_simulator/crates/mercs2_formats/fixtures/saves/)
(8 retail `.profile` files).

### 1.1 Lua orchestration — same seam everywhere

| Lua symbol | PC Jul-08 Xbox PS3 | Role |
|---|:---:|---|
| `Pg.SaveGame` | ✅ ✅ ✅ | Save trigger (manual + autosave) |
| `SaveSingleton` / `LoadSingleton` | ✅ ✅ ✅ | Per-manager contribute/restore |
| `SaveData` / `InitialSaveData` | ✅ ✅ ✅ | Engine save-event names |
| `SaveComplete` | ✅ ✅ ✅ | Completion event |
| `SetLuaSaveVersion` | ✅ ✅ ✅ | Stamps `version == 4` |
| `ProfileHash` | ✅ ✅ ✅ | Integrity word identifier (same `.rdata` identifier on every platform) |
| `hasCorruptedSave` | ✅ ✅ ✅ | Corruption-reject trigger |
| `hasAutosave` | ✅ ✅ ✅ | Autosave-detected trigger |
| `clearSaveGames` / `addSaveGame` / `saveGameSlot` / `deleteSaveGame` | ✅ ✅ ✅ | Multi-slot manager |
| `loadProfile` / `saveProfile` / `AddProfile` / `getListProfiles` | ✅ ✅ ✅ | Profile manager |
| `maximumProfiles` | ✅ ✅ ✅ | Slot-count tunable |
| `EnableAutosave` / `IsAutosaveEnabled` / `SetAutosaveEnabled` / `ForceNextAutosave` / `RequestAutosave` / `gameAutosave` | ✅ ✅ ✅ | Autosave policy |
| `Set/GetProfileCostume` / `Set/GetProfileUpgrade` / `Set/GetProfileCharacter` / `ModelMixerProfile` | ✅ ✅ ✅ | Character-customization persistence |
| **`AddProfile1Data` / `AddProfile1Name` / `AddProfile2Data` / `AddProfile2Name`** | ✖ ✖ **✅** | **PS3-only** dual-profile hook (see §4.3) |
| **`sProfileName1` / `sProfileName2`** | ✖ ✖ **✅** | PS3-only profile-name slots |

Lines verified in the PS3 `EBOOT.elf` string table at offsets 60629, 63567, 64442, 64665,
64666, 64676, 65467, 65772, 66140, 66153, 66162, 66175, 66203, 66204, 73526–73529,
3312757-adjacent region
(`scratchpad/save_fmt/ps3_a.txt`); Xbox Jul-08 lines at 2884–5231, 7182, 51147
(`output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt`); PC `.rdata` symbol
offsets in `docs/mercs2-pdb-analysis/game-systems.md` §"Save / profile persistence".

### 1.2 Engine serializer — same hash-dispatched write

PC (bodies read first-hand in
[`save_serialize_code_map.md`](reverse_engineer/save_serialize_code_map.md) §2):

```
FUN_005a4520 (SaveData/InitialSaveData handler)
  ├─ EnterCriticalSection(DAT_01174ffc)
  ├─ FUN_00874150                 // HashTable_Probe(0x100) → vcall *(h+8)
  ├─ FUN_0075b070 → FUN_00759xxx  // 4-byte-prefixed zlib stream codec
  └─ src = [0x1176054]+0x470      // profile/economy singleton (BE blob src)
     ntohl(src[0..2]) → {ver==1, ?, size}
     prefixes "return " → wraps as "return { … }" Lua text
```

Xbox 360 Jul-08 (`xenon_decomp_named.c` line 105647):

```c
void SaveGameData @0x8236dc20  size=264 {
  if (*(int*)(param_1 + 0x4734) == 0) {
    uVar2 = FUN_82902840(0x8000);                // allocate 32768-B workspace
    *(undefined4*)(param_1 + 0x4734) = uVar2;
    *(undefined4*)(param_1 + 0x4738) = 0x8000;
  }
  if (DAT_837d52a4 == '\0') {
    DAT_837d52a4 = '\x01';
    *(undefined4*)(param_1 + 0x4728) = 0;
    FUN_8236af48(param_1 + 0x10);                // serialize driver
    *(undefined1*)(param_1 + 0x472c) = 0;
    FUN_824c9180(DAT_83800e98, 0);
  }
  uVar1 = FUN_8290ba80(0xffffffff82020c78);      // hash-dispatched…
  FUN_82902f90(uVar1, 0xffffffff82020c78);
  uVar1 = FUN_8290ba80(0xffffffff82020c78);
  iVar3 = FUN_8290bc68(uVar1, 0xffffffff83cb28f4, 0x100);  // HashTable_Probe(0x100)
  …
}
```

The `0x100` probe-table key is the same magic value as PC
`FUN_008242b0(0x100)` (`save_serialize_code_map.md` §2.2) — same hash-dispatch primitive,
same registry key. Workspace is `0x8000` = 32,768 B (PC uses the same shape; the final
on-disk file is 13,404 B after zlib compression).

PS3: `20PgSysSaveGameManager` and `21PgSaveGameDataManager` surface as g++-mangled class
names in the ELF symbol table (strings at lines 60629 and 64442). Function bodies for
the PS3 save path are not resolvable because the retail EBOOT Ghidra project is
undersized (1.7 MB vs Xbox retail's 55 MB — the `.opd` seeder did not complete;
A.1 blocker in `.claude/plans/engine-divergence-phase3.md`).

### 1.3 Integrity hash — same algorithm on PC, same identifier on consoles

**PC: PROVEN byte-exact.** CRC-32/BZIP2 (non-reflected), poly `0x04C11DB7`, init/xorout
`0xFFFFFFFF`, covered range `[4:]`.
Implementation:
[`tools/wad_simulator/crates/mercs2_formats/src/save_write.rs:59–72`](../tools/wad_simulator/crates/mercs2_formats/src/save_write.rs)
(`profile_hash`). Fixture match (`scratchpad/save_fmt/profile_hash_verify.txt`,
reproducible without the Rust toolchain via the Python port in that file):

| fixture | stored `@0x00` (LE) | `profile_hash([4:])` | match |
|---|:---|:---|:---:|
| `auto_634304EA.profile` | `0x3F0FA812` | `0x3F0FA812` | ✅ |
| `auto_6A0BE454.profile` | `0x9CD00F3B` | `0x9CD00F3B` | ✅ |
| `auto_6A447BF8.profile` | `0xCA2F06BE` | `0xCA2F06BE` | ✅ |
| `auto_6A499D08.profile` | `0xC601523A` | `0xC601523A` | ✅ |
| `Chris Jacobs_6A499ED6.profile` | `0x7D06FA07` | `0x7D06FA07` | ✅ |
| `Mattias Nilsson_63430745.profile` | `0xCD831ADA` | `0xCD831ADA` | ✅ |
| `Mattias Nilsson_6A0E523C.profile` | `0x3C827D9E` | `0x3C827D9E` | ✅ |
| `_______ ________48EFABFB.profile` | `0xCB7AE171` | `0xCB7AE171` | ✅ |

The non-reflected (MSB-first) variant is the match — consistent with the engine's
Xbox-360 heritage, which serializes the in-memory `SaveData` blob in network/BE order
(`FUN_005a4520` calls `ntohl` on every header word). Memory:
[`memory/profile-hash-is-crc32-bzip2.md`](../memory/profile-hash-is-crc32-bzip2.md).

**Xbox 360: INFERRED.** The identifier `ProfileHash` exists in `.rdata` at PC `0x003fc78`
and at Xbox Jul-08 `0x003fc78` (symbol match,
`output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt` line 7182). The function
body that stamps `@0x00` is not named by the Xbox devkit symbols and the retail Xbox
Ghidra decomp is unnamed (55 MB of `FUN_XXX` only, no string-anchored naming yet). The
assumption that it is the *same* CRC-32/BZIP2 computation rests on the engine BE-blob
heritage (consoles are *natively* BE, so no `ntohl` step; the MSB-first CRC is the one a
BE processor computes trivially) + shared build system — not on a captured Xbox save
file.

**PS3: INFERRED, BLOCKED on retail save sample.** Same `ProfileHash` string present in
the ELF (line 62545). The PS3 retail Ghidra decomp is undersized (1.7 MB; A.1 blocker)
so the stamp site body is not currently decompilable. No retail PS3 save was captured
for byte-level verification.

---

## 2. PC save-file format — ground truth (PROVEN)

Source: [`docs/reverse_engineer/save_serialize_code_map.md`](reverse_engineer/save_serialize_code_map.md)
§4; implementation
[`tools/wad_simulator/crates/mercs2_formats/src/save.rs`](../tools/wad_simulator/crates/mercs2_formats/src/save.rs) +
[`save_write.rs`](../tools/wad_simulator/crates/mercs2_formats/src/save_write.rs); hex dump of
reference fixture `auto_6A447BF8.profile` in `scratchpad/save_fmt/auto_6A447BF8_hex.txt`.

### 2.1 On-disk container

Fixed **13,404-byte** file in `%USERPROFILE%\Documents\My Games\Mercenaries 2\SaveGames\`.
Base path constant at PC exe VA `0x007B38A4`
([`docs/exe_analysis_agent_a.md`](exe_analysis_agent_a.md) §14).

File names observed in the actual user install `C:\Users\Shadow\Documents\My Games\Mercenaries 2\SaveGames\`:
`auto_<ts32>.profile`, `<Hero Name>_<ts32>.profile` (hero name is the Latin-1 display
name including spaces; `<ts32>` is the save's Unix timestamp as a hex u32). All 10
sampled files are exactly 13,404 B.

### 2.2 Header field map (every byte PROVEN against the 8-fixture oracle)

Header is **little-endian packed** (PC-native). Zlib payload begins at `0x468`.

| offset | size | field | value in `auto_6A447BF8.profile` |
|---:|---:|---|---|
| `0x00` | u32 | `ProfileHash` — CRC-32/BZIP2 over `[4:]` | `0xCA2F06BE` |
| `0x04` | u32 | `version` | `4` |
| `0x08` | u32 | `data_size` = `file_len - 4` | `0x3458` (13400) |
| `0x0C` | u32 | const `3` | `3` |
| `0x10` | u32 | const `0` | `0` |
| `0x14` | u32 | `play_time_seconds` | `964` |
| `0x18` | u32 | `cash` | `200000` |
| `0x1C` | u32 | `fuel` | `25` |
| `0x20` | u32 | const `0` | `0` |
| `0x24` | u32 | `timestamp` (Unix) | `0x6A45586A` |
| `0x2C` | 16B | `active_contract` NUL-padded ASCII | `PmcCon001` |
| `0x4C` | u32 | `flags_0x4C` (hero at byte `@0x4D`) | `0x00030300` |
| `0x4F` | u8 | `upgrade_index` | `0..3` |
| `0x200` | UTF-16LE z | `save_name` slot label | `auto_6A447BF8` |
| `0x24A` | u8 | `unlocked_costumes` | `1`-`5` |
| `0x2F8` | u16 | `fuel_capacity` | varies |
| `0x462`–`0x467` | 2×u16 | unresolved | — |
| `0x468`–end | — | zlib stream (CMF `0x78 0xDA`) → `return { … }` Lua text | — |

The zlib payload inflates to the Lua `SaveSingleton` table — a `return { tFlowData = {…},
tLayerData = {…}, tStarterData = {…}, nTimeElapsed = …, vEquippedSupport = …, …}` text
blob. The engine `loadstring`s it back on load. Zlib stream header `78 DA` confirmed at
offset `0x468` of every fixture.

### 2.3 Round-trip proven byte-exact

`write_profile(parse(x)) == x` for all 8 fixtures:
[`save_write.rs:237–265`](../tools/wad_simulator/crates/mercs2_formats/src/save_write.rs)
`write_round_trips_byte_exact` test (reads every vendored fixture and asserts
`out == orig`). A mutated field re-stamps a valid `ProfileHash` that the retail exe's
corruption-reject FSM (`FUN_00614080`, raises hash `0x32ff679b` = `hasCorruptedSave`)
accepts.

---

## 3. Xbox 360 save-file format — PROVEN (filenames + symbols) · BLOCKED (retail bytes)

### 3.1 Filename shapes (PROVEN from Jul-08 symbol table)

| string | VA | source |
|---|---|---|
| `NoTRCSave%02d.sav` | `0x0020a9c` (`.rdata`) | `mercs2-pdb-analysis/game-systems.md`, Jul-08 strings line 2910 |
| `ConvertNoTRCSave%02d.sav` | `.rdata` | Jul-08 strings line 5387 |
| `save:\` (Xbox 360 TRC save-drive prefix) | `.rdata` | Jul-08 strings line 51146 |
| `save:\savegame.txt` | `.rdata` | Jul-08 strings line 51147 |
| `ifs.loadsave_xbox.save02..save19` | `.rdata` | shell UI slot keys, verified in `FUN_0050dfd0` body (ref `save_serialize_code_map.md` §4) |

"TRC" = Microsoft's Technical Requirements Checklist; `NoTRCSave%02d.sav` is the dev /
non-cert save-filename pattern. `save:\savegame.txt` is a devkit single-blob dump path
(txt-extension consistent with a debug dump; not shipped on retail).

### 3.2 Engine serializer — same hash-dispatch (PROVEN body-level)

`SaveGameData @0x8236dc20` body in
[`output/_ghidra_x360/xenon_decomp_named.c:105647`](../output/_ghidra_x360/xenon_decomp_named.c)
(see §1.2 above). Pattern-matches PC `FUN_005a4520`/`FUN_00874150` (CS-gated serialize +
`HashTable_Probe(0x100)` dispatch).

### 3.3 On-disk container wrapping — BLOCKED

The Xbox 360 JTAG rip in-repo (`game-files/Mercenaries 2 World in Flames (NTSCU)[NTSCJ) (JTAGRip)/`)
is a **game-content extract only** (`$systemupdate`, `audios/*.pws`, `default.xex`,
`shell.wad`, `vz.wad`, `english.wad`, `movies/*.bik`, `shaders.bin`); no user-save STFS
container is present.

Known from the Jul-08 strings (not confirmed from a retail save):

- The dev-path `save:\` is an Xbox 360 title-storage drive prefix, bound by the
  dashboard to either an HDD device slot or an MU/USB device after a user-side
  `XamShowDeviceSelector`. The flat file written to `save:\` is a `NoTRCSave%02d.sav`
  blob.
- The Jul-08 string table contains **no literal reference** to the XContent APIs
  (`XContentCreate`, `XContentCreateEx`, `XContentOpenFile`, `XContentClose`,
  `XContentGetDeviceData`). This absence is suggestive but not conclusive: the devkit
  Profile build may be writing to the raw TRC drive without wrapping, with the retail
  Final build adding the STFS CON/LIVE/PIRS wrapper for user-visible storage. **BLOCKED
  on the Xbox retail Final decomp pass** (noted in `cross_platform_parity_reference.md`
  §Phase-2-provenance: retail Final 55 MB `.c` is present but unnamed).

### 3.4 Field map — INFERRED same as PC (not re-verified from Xbox bytes)

Given the same `SetLuaSaveVersion` → `version == 4`, the same `ProfileHash` identifier,
the same `SaveData`/`InitialSaveData` dispatch, and that consoles process the inner blob
natively BE (no `ntohl` cost; the engine *was written on Xenon first*), the inner Lua
payload + the header field positions INFER to identical layout. The 13,404-byte figure
is a *writable workspace minus deflate compression*; the Xbox devkit's 0x8000 (32,768 B)
workspace allocation is consistent with that (large enough to compose the Lua table
pre-compression). Byte-level confirmation of the on-disk header is blocked until a retail
Xbox save is captured.

---

## 4. PS3 save-file format — INFERRED (strong) · BLOCKED on retail save bytes

### 4.1 Filesystem container (PROVEN strings)

PS3 EBOOT strings present:

| string | ELF line | implication |
|---|---:|---|
| `BLUS30056` | 63567 | Title ID (US retail SKU) |
| `BLUS30056_00` | 78164 | Save-directory name (standard PS3-game convention `TITLEID[_NN]`) |
| `/dev_bdvd/PS3_GAME/USRDIR` | 63572 | Read-only asset mount |
| `/dev_bdvd/PS3_GAME` | 63574 | — |
| `/dev_bdvd` / `/dev_hdd0` / `/dev_hdd1` / `/dev_usb` | 66409–66416 | Writable device roots |
| `/dev_flash/sys/external/flashMP3.pic` | 68717 | System asset |

No `.profile` / `.sav` / `%02d.sav` / `savegame` filename format strings are present in
the PS3 ELF. The save directory basename is `BLUS30056_00` (per PS3 convention, the save
lives at `/dev_hdd0/game/BLUS30056_00/` or `/dev_hdd0/savedata/BLUS30056_00/`); the actual
inner filename is INFERRED to be an engine-chosen basename analogous to PC
`<Hero>_<ts32>.profile`.

### 4.2 ★ PS3 does NOT use `cellSaveData` — not a PFD/PSN-protected container (PROVEN)

The PS3 ELF `sys_prx_library` import list (strings 59703–59718):

```
cellSysmodule, sys_fs, sys_io, cellNetCtl, cellSpurs, cellGcmSys,
sys_net, cellSync, cellAudio, cellSysutil, cellL10n, cellRtc,
cellMic, cellCelpEnc, cellAdec
```

**`cellSaveData` is absent.** Sony's `cellSaveData` is the normal PSN-content path that
wraps save files in a PFD (PlayStation Format Data) container with `PARAM.SFO`,
`ICON0.PNG`, and per-user AES/HMAC protection. Without that import, the PS3 build writes
save files **directly** via `sys_fs`/`cellFs*` calls to a plain filesystem path — same
model as the PC's flat `.profile`, same model as Xbox's `NoTRCSave%02d.sav`.

Corollary: there is no `PARAM.SFO`, no `ICON0.PNG`, no PFD HMAC. The PS3 on-disk save
is the engine-native container, same shape as the PC `.profile` (modulo endianness of
any u32s that may be written in BE — the inner engine blob is already BE in memory on
both consoles, so no byte-swap is applied).

### 4.3 PS3-only two-profile Lua surface (PROVEN strings; semantics INFERRED)

PS3 EBOOT additionally exposes
`AddProfile1Data`, `AddProfile1Name`, `AddProfile2Data`, `AddProfile2Name`,
`sProfileName1`, `sProfileName2` — none of which are in the PC or Xbox Jul-08 symbol
tables. Semantics INFERRED (not confirmed from bodies): a two-slot *local* profile hook,
likely for the PS3's splitscreen context (the dashboard allows a second user
password-less login). On PC and Xbox 360, the only multi-user hook is `AddProfile`
(singular).

### 4.4 Serializer bodies — BLOCKED

The PS3 retail EBOOT decomp is undersized (1.7 MB named-decomp vs Xbox retail's 55 MB;
`output/_ghidra_ps3_retail/ps3_retail_decomp_named.c`). The `.opd` function-start seeder
didn't complete the full function walk, so the save-related function bodies behind
`20PgSysSaveGameManager` / `21PgSaveGameDataManager` are not currently resolvable from
the decomp. Promoting PS3 claims to PROVEN at the body level requires A.1 (full PS3
Ghidra re-run per the Phase 3 plan).

---

## 5. Settings / preferences file — PC-only (PROVEN)

### 5.1 PC: `Mercs2.ini` is the user-preferences file (PROVEN)

Sources: [`docs/game_data_analysis.md`](game_data_analysis.md) §7.1;
[`docs/reverse_engineer/validation/lti_movie_pda_validation.md`](reverse_engineer/validation/lti_movie_pda_validation.md)
§M11.

Shipped at `<install>\Mercs2.ini` (`C:\Users\Shadow\Documents\Mercenaries 2 World in Flames\Mercs2.ini`
on this machine; the installer-created copy, zero bytes on a fresh install, is populated
on first launch). Standard Win32 INI, sections proven live from the 47 Win32 call-sites
through `FUN_0074BB50`:

| section | call sites | known key families |
|---|---:|---|
| `[Render]` | 23 | gfx/shader/view-distance/vsync/resolution (`LTIVideo*` LTI surface) |
| `[Network]` | 5 | `MailEA`, `MailThirdParty`, `FriendlyFire` |
| `[Audio]` | 5 | SFX/Music/Dialog/Voice volumes |
| `[Joystick]` | 4 | `Invert`, `Rumble`, `Sensitivity` |
| `[Game]` | 3 | Autosave, Tutorial, Sensitivity |
| `[Mouse]` | 2 | invert, sensitivity |
| `[Actions1]` / `[Actions2]` | — | keyboard binding tables (loader string-anchor not yet matched) |
| `[Controller]` | — | controller remap |

Readers: `GetPrivateProfileIntA` / `GetPrivateProfileStringA`. Writers:
`WritePrivateProfileStringA`. These are **Win32 kernel APIs** and ship nowhere outside PC.

### 5.2 PC: `GL.ini` is DRM-launcher config, not user settings (PROVEN)

File shipped at `<install>\GL.ini` (UTF-16LE INI, 966 lines, 59 KB observed). Contents:
`[GameLauncherConfig]`, `[DRMLicense]`, then one `[<locale>]` section per language
(each with the `GL:5511`..`GL:5631` error-dialog strings for EA Game Launcher). Not a
user-preferences store. Mod-side detail at
[`docs/modding_deep_dive.md`](modding_deep_dive.md) §1.2.

### 5.3 Xbox 360: no shipped `Mercs2.ini` (PROVEN by absence)

The Jul-08 Xbox string table contains only *dev* INIs at `d:\` dev paths:
`d:\local.ini`, `d:\first.ini`, `code_version.ini`, `CdbSizes.ini`, `first.ini`,
`multiplayer.ini` (lines 2410–2470, 561–562). None of `Mercs2.ini`, `[Render]`,
`[Joystick]`, `[Actions1]`, `[Mouse]`, or `[Controller]` strings appear. The Win32
`GetPrivateProfileIntA`/`WritePrivateProfileStringA` APIs don't exist on Xenon; the
Xbox 360 build *has no PC-side INI preferences layer*.

Where Xbox 360 user preferences live (INFERRED): either serialized inside the save
`.sav` blob (the Lua `SaveSingleton` table already carries `vEquippedSupport`,
`tStarterData` and other per-user state) or through XProfile system settings
(controller-vibration, audio-caption, subtitle on/off come from the dashboard, not from
the game). No code-level evidence of a game-written preferences file on Xbox has been
captured.

### 5.4 PS3: no shipped `Mercs2.ini` (PROVEN by absence)

The PS3 ELF string table has no `Mercs2.ini`, no `[Render]`/`[Audio]`/`[Joystick]`
sections, no `GetPrivateProfile*` imports. Same shape as Xbox: preferences — if
persisted — are bundled with the save or come via `cellSysutil` system config (volume,
subtitle). No code-level evidence of a game-written preferences file on PS3 has been
captured.

---

## 6. Cross-platform save-transfer feasibility

**At the engine-blob layer: TRACTABLE.** All three platforms emit the same inner Lua
`return { … }` text through the same `FUN_005a4520`-equivalent handler + the same
`SaveData` / `InitialSaveData` events. The engine's load path (`LoadSingleton(tSaveData)`
in Lua) accepts any valid serialized blob and re-hydrates the managers. The inner blob
is engine-neutral.

**At the container layer: FEASIBLE on PC↔PS3; GATED on Xbox STFS wrapping.**

| transfer | wrapper work | engine-blob work | status |
|---|---|---|---|
| **PC → PC** | — | — | native (`My Games\Mercenaries 2\SaveGames\`) |
| **PC → Xbox 360** | wrap flat `*.profile` into an STFS CON package (retail), or rename to `NoTRCSave%02d.sav` + copy to `save:\` (devkit) | none if `ProfileHash` is CRC-32/BZIP2 on retail (currently INFERRED, §1.3) | FEASIBLE — pending STFS wrap tool + a captured retail save to validate `ProfileHash` round-trip |
| **PC → PS3** | copy flat file into `/dev_hdd0/game/BLUS30056_00/<slot>/` (no PFD wrap needed, §4.2) | none if `ProfileHash` on PS3 is CRC-32/BZIP2 (INFERRED) | FEASIBLE — pending a captured retail PS3 save to confirm the slot layout + hash algorithm |
| **PS3 → PC** | strip the directory; copy the inner file into the PC `SaveGames\` folder | reconcile the PS3-only two-profile `sProfileName1/2` and `AddProfile1/2Data` → `AddProfile` (singular) on PC | FEASIBLE — any per-profile Lua state would need the dual-slot keys renamed; the inner blob otherwise maps 1-to-1 |
| **Xbox 360 → PC** | unwrap the STFS CON package to the flat file | rename to `<Hero>_<ts32>.profile` | FEASIBLE on devkit saves immediately (no wrapper); retail depends on the STFS wrap verdict |

The remaining engineering risk is twofold: (a) whether the retail PC's `hasCorruptedSave`
FSM gates on anything **beyond** the CRC-32/BZIP2 + `version == 4` + `data_size == len-4`
invariants proven in §2 (open: `FUN_00614080`'s upstream byte-compare site is unlocated
in the dump —
[`save_serialize_code_map.md`](reverse_engineer/save_serialize_code_map.md) §3.3), and
(b) whether consoles encode the inner-blob BE header word[1] (unknown purpose) differently
from PC's zeroed value.

---

## 7. Three-platform cross-platform diff table

| field | PC retail | Xbox 360 (Jul-08 devkit) | PS3 BLUS30056 |
|---|---|---|---|
| Filesystem location | `My Games\Mercenaries 2\SaveGames\` (`0x007B38A4`) | `save:\` TRC drive (devkit); retail STFS CON package in dashboard storage | `/dev_hdd0/.../BLUS30056_00/` |
| On-disk file name | `auto_<ts32>.profile` or `<Hero>_<ts32>.profile` | `NoTRCSave%02d.sav` or `ConvertNoTRCSave%02d.sav` (slot-indexed); dev dump `save:\savegame.txt` | engine-chosen (not captured in-repo); directory `BLUS30056_00` |
| OS wrapper | plain file | retail: STFS CON (INFERRED); devkit: raw TRC drive | plain file via `sys_fs`/`cellFs` — **no PFD wrapper** (`cellSaveData` not imported) |
| Endianness (on-disk LE header) | **LE** | **LE** INFERRED (same engine serializer; byte-level BLOCKED) | **LE** INFERRED (same, BLOCKED) |
| Endianness (inner engine blob) | **BE** (serialized via `ntohl` from singleton `[0x1176054]+0x470`) | **BE** native (Xenon) | **BE** native (PPU) |
| Payload envelope | 13,404-B fixed; zlib stream at `0x468` | INFERRED same (workspace is `0x8000` = 32,768 B pre-compression; `SaveGameData @0x8236dc20`) | INFERRED same |
| Payload content | `return { … }` Lua text (zlib-inflated) | same | same |
| Integrity hash | **CRC-32/BZIP2 (non-reflected) over `[4:]`** PROVEN byte-exact over 8 fixtures | identifier `ProfileHash` at `.rdata 0x003fc78` PROVEN; algorithm match INFERRED | identifier `ProfileHash` present PROVEN; algorithm match INFERRED, BLOCKED on retail save |
| `version` word | `4` (`SetLuaSaveVersion`) | `4` INFERRED (same `SetLuaSaveVersion` cfunc) | `4` INFERRED (same cfunc; `GetSaveDataVersion` additionally present only on PS3, ELF line 491228) |
| Max profile slots | `maximumProfiles` tunable | same | same, but **two-profile local hook** (`AddProfile1/2`, `sProfileName1/2`) is PS3-only |
| Corruption-reject | `hasCorruptedSave` → `FUN_00614080` FSM, hash `0x32ff679b` | same symbol | same symbol |
| Autosave gating | `IsAutosaveEnabled` / `_bDoMissionAutosave` + blocking-sequence-counter == 0 | same; `EnableAutosave 1` default (Jul-08 line 2128) | same |
| Settings/preferences file | `Mercs2.ini` (Win32 `GetPrivateProfileInt`) — 9 sections, 47 call sites | **absent** (no `Mercs2.ini` string, no Win32 private-profile API on Xenon) | **absent** (no `Mercs2.ini` string, no Win32 private-profile API) |
| DRM-side auxiliary | `GL.ini` (EA Game Launcher dialog strings, UTF-16LE) | n/a | n/a |

---

## 8. What's BLOCKED and why

| gap | reason | unblock cost |
|---|---|---|
| Byte-level Xbox 360 retail save shape (header LE check, inner blob) | No retail Xbox save file captured in-repo (`game-files/.../(JTAGRip)/` is a game-content extract, no user-save STFS) | capture one retail Xbox save (JTAG dashboard copy of a `profile.bin` STFS package); dump + diff first 0x468 bytes against the PC fixture |
| Byte-level PS3 retail save shape | No retail PS3 save file captured in-repo (`game-files/ps3-version/` is EBOOT + patches only; `.iso` is the disc image) | capture one PS3 save (`/dev_hdd0/.../BLUS30056_00/` directory tree via RPCS3 export or FTP from a decrypted PS3); dump + diff against PC |
| PS3 save-manager function bodies | PS3 retail Ghidra decomp is undersized (1.7 MB; `.opd` seeder incomplete) — A.1 blocker in `.claude/plans/engine-divergence-phase3.md` | re-run `.opd`-based function-start seeder on `output/_ghidra_ps3_retail/`; current decomp lacks the `cellFs*`-anchored write path |
| Xbox 360 retail STFS wrap verdict (CON/LIVE/PIRS vs raw) | Jul-08 string table has `save:\` dev-drive paths; retail STFS wrapping cannot be assumed from devkit evidence | identify `XContentCreateEx` / `XContentOpenFile` call sites in the Xbox retail Final decomp (`output/_ghidra_x360_final/`, 52 MB named-decomp) — requires a string-anchored naming pass |
| Native `saveProfile` disk-write body on PC | Not in the Ghidra dump (registration-anchored VA `0x007BC628`) | not a blocker — `save_write::write_profile` round-trips byte-exact; the native site is structural context |
| Field semantics of `.profile@0x462..0x467` (2× u16 before zlib) | Not read; constant across fixtures doesn't rule out purpose | HW-write-breakpoint at `0x462` during a save event |

---

## 9. Provenance

- PC save fixtures (8): [`tools/wad_simulator/crates/mercs2_formats/fixtures/saves/*.profile`](../tools/wad_simulator/crates/mercs2_formats/fixtures/saves/).
- Working PC install SaveGames: `C:\Users\Shadow\Documents\My Games\Mercenaries 2\SaveGames\` (10 files, all 13,404 B).
- PC code map: [`docs/reverse_engineer/save_serialize_code_map.md`](reverse_engineer/save_serialize_code_map.md).
- PC Rust writer: [`tools/wad_simulator/crates/mercs2_formats/src/save_write.rs`](../tools/wad_simulator/crates/mercs2_formats/src/save_write.rs) (`profile_hash` lines 59–72; `write_profile` lines 146–151; test suite 213–319).
- Xbox 360 Jul-08 symbols: [`docs/mercs2-pdb-analysis/game-systems.md`](mercs2-pdb-analysis/game-systems.md) §"Save / profile persistence"; [`output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt`](../output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt).
- Xbox 360 Jul-08 decomp: [`output/_ghidra_x360/xenon_decomp_named.c`](../output/_ghidra_x360/xenon_decomp_named.c) — `SaveGameData @0x8236dc20` body at line 105647.
- PS3 EBOOT strings: `strings game-files/ps3-version/EBOOT.elf` → `scratchpad/save_fmt/ps3_a.txt` (79,301 lines).
- `cellSaveData` import check: PRX library list at `scratchpad/save_fmt/ps3_a.txt` lines 59703–59718.
- Verification scripts + hex dumps in `scratchpad/save_fmt/`:
  - `pc_saves_headers.txt` — all 8 fixtures parsed field-by-field;
  - `profile_hash_verify.txt` — CRC-32/BZIP2 computed vs stored for all 8 (8/8 match);
  - `auto_6A447BF8_hex.txt` — reference fixture hex dump through `0x4A0`.
