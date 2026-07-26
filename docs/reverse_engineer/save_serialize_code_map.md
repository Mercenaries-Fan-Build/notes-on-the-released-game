# Save / serialize — Xbox↔PC code map

**Scope:** scoreboard row 29 (Save / serialize) — the persistence pipeline that turns live game state
into a `.profile`/`.sav` on disk and back: the Lua save-orchestration seam, the engine save-event
handler + hash-dispatched serializer, the versioning + integrity (`SetLuaSaveVersion` / `ProfileHash`
/ `hasCorruptedSave`) layer, the on-disk `.profile` field map, the multi-slot profile manager, and
autosave. This marries the **Xbox 360 devkit (Jul-08 Profile build)** save/profile symbol set to the
**PC retail decompilation** (`Mercenaries2.exe`, unpacked image, base `0x00400000`).

This is the **write-side** counterpart to the read-only `.profile` parser the engine already ships
(`mercs2_formats::save`). The Lua cfunc binding VAs for the Save namespace are *recovered* (audit
§3.15), but the on-disk `.profile` binary layout + the integrity hash are the RE meat — this map pins
what is proven and flags what stays open.

**Sources.** PC: the 27k-fn Ghidra decomp of the unpacked exe (bodies read first-hand below),
[`../lua_engine_bindings_audit.md`](../lua_engine_bindings_audit.md) §3.15 (Save/Load cfunc VAs),
[`../exe_analysis_agent_a.md`](../exe_analysis_agent_a.md) §14 + [`../exe_analysis_agent_b.md`](../exe_analysis_agent_b.md)
§Save. Xbox oracle: [`../mercs2-pdb-analysis/game-systems.md`](../mercs2-pdb-analysis/game-systems.md)
§"Save / profile persistence" (symbol inventory + PC cross-ref + the `FUN_005a4520` save-event
handler) and its Notable-strings save block. On-disk ground truth:
[`../../tools/wad_simulator/crates/mercs2_formats/src/save.rs`](../../tools/wad_simulator/crates/mercs2_formats/src/save.rs)
+ [`../../tools/wad_simulator/crates/mercs2_formats/SAVE_FORMAT.md`](../../tools/wad_simulator/crates/mercs2_formats/SAVE_FORMAT.md)
+ [`../../tools/savefile_parser.py`](../../tools/savefile_parser.py) + [`../format_reference.md`](../format_reference.md)
§1. Lua orchestration: [`../mercs2-luacd/`](../mercs2-luacd/) (`mrxpmc.lua`, `mrxplayer.lua`,
`mrxmissionflow.lua`, `mrxstate`/loading `LoadSingleton`). Companion memory:
[[shell-menu-and-save-browser]], [[money-fuel-datatype-and-cap]].

**Method / honesty model.** Same discipline as the sibling maps
([`world_streaming_code_map.md`](world_streaming_code_map.md),
[`asset_formats_code_map.md`](asset_formats_code_map.md)). Each PC address states whether the body was
**READ** first-hand this pass or cited by reference; the Xbox side is the string/symbol inventory
(this layer is `.rdata`-identifier + Lua-binding driven, **not** RTTI-class driven — game-systems.md
established every PC match here is *string-anchored*, no vtable resolution). A crucial honesty point:
**the Save-namespace cfunc VAs in audit §3.15 are registration/binding-table anchored, not decompiled
bodies** — `SaveGame 0x7B8AC4` is literally inside the "Registered Game Events `0x7B8A88–0x7B8AC4`"
block (exe_analysis_b §64), and none of `0x7B8AC4 / 0x7BC628 / 0x7BC190 / 0x5E6120 …` resolve to a
function in the Ghidra dump. They are the *Save table entry* addresses; the real work is done by the
string-anchored handlers below. Confidence: **H** structural/format fingerprint that can't coincide ·
**M** role+position, one strong signal · **L/open** positional / registration-only → confirm-live.

---

## 0. Result in one line

The save **path shape** is recovered end-to-end — Lua `Pg.SaveGame`/`SaveSingleton` → the engine
save-event handler `FUN_005a4520` (`SaveData`/`InitialSaveData`) → hash-dispatched per-object
serializer `FUN_00874150` under CS `DAT_01174ffc` → the zlib stream cluster `FUN_00759xxx`, sourced
from the **profile/economy singleton `[0x1176054]`** — and the on-disk `.profile` header is a proven
13,404-byte LE layout (`version==4`, `data_size==len-4`, zlib at `0x468`). The **two genuinely-open
items are the RE meat**: (1) the `ProfileHash` **integrity algorithm** over the blob (@0x00; *not*
crc32/fnv1a/sum/xor/adler over any obvious range) and (2) the **`saveProfile` disk-write body**
(LE-header + deflate + write to `SaveGames\*.profile`) — both are registration-anchored / absent from
the Ghidra dump and are the primary confirm-live targets. The Save-cfunc VAs are all
registration-table anchored, not decompiled bodies.

---

## 0.5 Master marriage table (the whole system at a glance)

Per-cluster tables + evidence are in §2–§7. "Xbox" is the game-systems.md `.rdata` symbol (a bare
`0x00xxxxx` offset = the Xbox *name-string* offset; the Xbox save *code* bodies are unlocated by name,
as everywhere in this build). "PC addr" is the retail VA; **audit** = registration/binding-table VA
(body not in dump); **READ** = decomp body read first-hand this pass.

| Role / section | Xbox symbol | PC addr | Married by | Conf |
|---|---|---|---|---|
| `Pg.SaveGame` cfunc (save trigger) | `SaveGame` (`0x0020c78`) | `0x007B8AC4` (audit; = Save-table entry, **body unlocated**) | audit §3.15 CERTAIN, but VA sits in the `0x7B8A88–0x7B8AC4` event-registration block | M(VA)/open(body) |
| `SaveComplete` event | `SaveComplete` (`0x0024d90`) | `0x007B44FC` (audit) | audit §3.15; event-name registration | M(VA) |
| **`SaveData` / `InitialSaveData` handler** (serialize driver) | `SaveData`(`0x0024ca4`)/`InitialSaveData`(`0x0024cb0`) | **`FUN_005a4520`** | READ: `_stricmp` on `retry`/`InitialSaveData`/`SaveData`; CS `DAT_01174ffc`→`FUN_00874150`; `ntohl` BE blob; `"return "` Lua wrapper; src `[0x1176054]+0x470` | H |
| **hash-dispatched per-object serializer** (the "run the save") | — | **`FUN_00874150`** | READ: `HashTable_Probe(0x100)` → handler slot → vcall `(*(h+8))(buf)`; the reflection/serialize dispatch | H |
| zlib stream (de)serialize used by SaveData | — | **`FUN_0075b070`** → `FUN_007597e0`/`FUN_00759970` | READ: called from `FUN_005a4520@0x5a4708`; 4-byte-prefixed inflate stream (the `FUN_00759xxx` codec cluster) | H |
| section-offset-table binary save (structural analog) | — | `FUN_00759020` (`PrecacheManager::Save`) | READ: `fopen`→16B header→N×0x20 offset table→per-section `ftell` fixups→rewrite table; the engine's own "dir + sections" disk idiom | H (analog) |
| `SetLuaSaveVersion` cfunc (version stamp) | `SetLuaSaveVersion` (`0x002c5a4`) | `0x005E6120` (audit; body unlocated) | audit §3.15 CERTAIN | M(VA) |
| **`ProfileHash`** integrity | `ProfileHash` (`0x003fc78`) | — (no body in dump; `.profile@0x00`) | Xbox symbol + on-disk field; **algorithm unreversed** | open |
| **`hasCorruptedSave`** reject FSM | `hasCorruptedSave`(`0x002fe14`) + `File corrupted!` | **`FUN_00614080`** | READ: save-dialog FSM fires `hasCorruptedSave`(hash `0x32ff679b`) / `hasAutosave`(`0x13edde28`) triggers | H (FSM), open (the byte-compare) |
| `Autosave`/`RequestAutosave` cfunc | `autoSave`(`0x002fee4`)/`gameAutoSave`(`0x002f9d8`) | `0x005E61F0` (audit) | audit §3.15 | M(VA) |
| autosave dispatch (game-state) | `autoSave` | in `FUN_00614540` (case `0x5a06a0a6` → `s_autoSave`) | READ: `_stricmp(...,s_autoSave)`→SecuROM worker `thunk_FUN_024ef560` | M |
| `IsAutosaveEnabled`/`SetAutosaveEnabled`/`ForceNextAutosave` | (verbs in inventory) | `0x005E65E0`/`0x005E6610`/`0x005E6670` (audit) | audit §3.15 CERTAIN | M(VA) |
| **`saveProfile`** (write `.profile` to disk) | `saveProfile` (`0x002fd08`) | `0x007BC628` (audit; **body unlocated**) | audit §3.15 CERTAIN | M(VA)/open(body) |
| `saveGameSlot`/`addSaveGame`/`clearSaveGames`/`deleteSaveGame` | `0x002f978`/`0x002fc64`/`0x002fd34` | `0x007BC190`/`0x007BC1A0`/`0x007BC6C4` (audit) | audit §3.15; multi-slot manager | M(VA) |
| `loadProfile`/`AddProfile`/`getListProfiles`/`maximumProfiles` | `0x002fb64`/`0x002faf0`/`0x002fb2c`/`0x002f958` | (registered; unlocated) | Xbox inventory; multi-slot profile layer | M |
| save-slot UI (`ifs.loadsave_xbox.save02..19`) | `NoTRCSave%02d.sav` slot keys | **`FUN_0050dfd0`** | READ: `s_ifs_loadsave_xbox_save08/19`, `common_ok` dialog | H |
| `ModelMixerProfile` (costume/upgrade persist) | `ModelMixerProfile`(`0x00316fc`) | `FUN_00643a40` (ECS descriptor registrar) | game-systems.md PC xref (string-anchored) | H |
| profile character/upgrade/costume accessors | `Set/GetProfileCharacter/Upgrade/Costume` (`0x002b00c`–`0x002b070`) | `0x005DF790/7D0`, `…830/870`, … (shell-menu memory) | [[shell-menu-and-save-browser]]: runtime profile obj `+0x61/0x62/0x63` | H |
| Lua string-hash (event/handler keys) | — | `Hash_String FUN_00824270` / `HashTable_Probe FUN_008242b0` | asset map §6 (FNV seed `0x811c9dc5`); used by `FUN_005a4520`/`FUN_00874150`/`FUN_00614540` | H |

---

## 1. Where save sits (Lua-orchestrated, engine-serialized)

The save system is **assembled in game Lua and executed in the engine** — the charter split. The Lua
side decides *what* goes into the blob (per-manager `SaveSingleton`/`LoadSingleton` methods); the
engine side (`FUN_005a4520` + `FUN_00874150`) walks the registered objects, (de)serializes them, and
(via `saveProfile`) commits the `.profile` to disk.

```
game Lua                                        engine (native)
────────                                        ───────────────
Pg.SaveGame("autosave"|slot)  ───────────────►  Save-namespace cfunc (0x7B8AC4 area, registration)
  MrxMissionFlow autosave (mrxmissionflow.lua:817,                │  fires event "SaveData"/"InitialSaveData"
    Pg.SaveGame only at blocking-seq==0 & _bDoMissionAutosave)    ▼
  each manager :SaveSingleton() contributes:            FUN_005a4520  SaveData/InitialSaveData handler  §2
    MrxPmc     (mrxpmc.lua:500)  cash/fuel/capacity/            ├─ EnterCriticalSection(DAT_01174ffc)
                                 equipment/stockpile/freebies   ├─ FUN_00874150  hash-dispatched serialize
    MrxPlayer  (mrxplayer.lua:661) per-hero health + weapons    ├─ FUN_0075b070  zlib stream (FUN_00759xxx)
    MrxLayerManager  tLayerData (vz_state_* world overlays)     └─ src = [0x1176054]+0x470 (profile/economy singleton)
    MrxMissionFlow   tFlowData / tActiveMissions / tMyFlowData          │
    MrxStarterManager tStarterData (unlocked recruits)                  ▼
  serialized as a `return { … }` Lua table (text)         saveProfile 0x7BC628 (unlocated)
                                                            wraps LE header (checksum/ver=4/size) + zlib
                                                            → My Games\Mercenaries 2\SaveGames\*.profile
load: Pg.LoadGame → LoadSingleton(tSaveData)  ◄───────────  loadProfile / hasCorruptedSave FSM (FUN_00614080)
  (xQ!L.lua LoadSingleton: sets spawn/retry locations,
   then MrxState.STATE_WAITFORSTREAMING → _LoadLayers →
   MrxLayerManager.LoadSingleton(tSaveState.tLayerData))
```

**The autosave trigger is data-gated in Lua** (`mrxmissionflow.lua:817`): `Refresh` runs the flow
fixpoint inside `_BeginBlockingSequence`/`_EndBlockingSequence`; `Pg.SaveGame("autosave")` fires
**only** when the blocking-sequence counter returns to 0 *and* `_bDoMissionAutosave` is set. Key
awards during the refresh are deferred (`_tDeferredKeyAwards`) and replayed after, so the autosave
snapshots a consistent flow state.

**The load side is in `xQ!L.lua` `LoadSingleton(tSaveData)`** (mrxstate/loading): it stashes
`_tSaveState = tSaveData`, resolves start/retry locations (`Pg.LoadIsRetry()` →
`WifMissionFlow.GetRetryLocations()`; else the save's `tRetryLocations`; else `Pmc_Entry1/2`), then
`MrxState.Enter(STATE_WAITFORSTREAMING, _LoadLayers, …)` and `_LoadLayers` calls
`MrxLayerManager.LoadSingleton(_tSaveState.tLayerData, …)` to restore the `vz_state_*` overlays.
This is the seam that consumes exactly the `SaveState` the Rust parser decodes (§4).

---

## 2. The save-write / serialize driver (H — read first-hand)

### 2.1 `FUN_005a4520` = the `SaveData` / `InitialSaveData` event handler (H, READ)

Both `SaveData` and `InitialSaveData` anchor here (game-systems.md #23; two distinct string anchors
converge). It is the (de)serialize driver for the singleton blob. Read verbatim, the load-bearing
structure:

```c
uint FUN_005a4520(int param_1, char *param_2) {          // param_2 = event name
  iVar5 = _stricmp(param_2, s_retry_00bb4604);           // "retry"  → +0xc3d flag
  *(bool*)(param_1+0xc3d) = iVar5 == 0;
  ... _stricmp(param_2, s_InitialSaveData_00bb4630) ...   // "InitialSaveData"
  ... _stricmp(param_2, s_SaveData_00bb4640) ...          // "SaveData"
  // --- the actual (de)serialize, under a global critical section ---
  FUN_00824270();                                         // Hash_String (seed the key)
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_01174ffc);
  iVar5 = FUN_00874150();                                 // hash-dispatched per-object serialize  §2.2
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_01174ffc);
  // result buffer object: +0x14 = u16 tag (2 or 4), +0x18 = data ptr, +0x1c = size
  uVar1 = *(ushort*)(iVar5+0x14); if (uVar1 != 2 && uVar1 != 4) bail;
  memcpy(dst, *(iVar5+0x18), *(iVar5+0x1c));              // pull the serialized bytes out
  ...
  _Src = (u_long*)(PTR_PTR_01176054 + 0x470);            // <-- SOURCE = profile/economy singleton +0x470
  uVar7 = ntohl(*_Src); ntohl(_Src[1]); ntohl(_Src[2]);  // <-- BIG-ENDIAN blob header {ver==1, ?, size}
  if (uVar7 != 1) bail;                                   // blob "version" field == 1
  pcVar9 = FUN_0084ac20();                                // Chunk_Alloc
  *(u32*)pcVar9      = s_return_00bb464c._0_4_;           // "retu"  ┐  the payload is a
  *(u32*)(pcVar9+4)  = s_return_00bb464c._4_4_;           // "rn "   ┘  `return { … }` Lua chunk
  iVar5 = FUN_0075b070();                                 // zlib stream body  §2.3
  puVar8 = thunk_FUN_02fe0000();                          // SecuROM worker (finalize/commit)
  ... FUN_0085df50() / FUN_0085d680() ...                 // finalize
}
```

Four load-bearing facts fall out of this body:

1. **Source of truth = the profile/economy singleton `[0x1176054]`** (`PTR_PTR_01176054 + 0x470`).
   This is the *same* singleton the economy money/fuel live on ([[money-fuel-datatype-and-cap]]:
   cash/fuel signed int32 on `0x1176054`) and the profile character/upgrade/costume bytes hang off
   (`+0x61/0x62/0x63`, [[shell-menu-and-save-browser]]). The save blob is a serialization of this
   object's `+0x470` region.
2. **The in-memory blob is big-endian** (`ntohl` on every header word) — an Xbox-360 heritage
   artifact: the singleton is serialized in network/BE order even on PC. Header `{u32 ver==1, u32 ?,
   u32 size}`. This is the **engine SaveData blob**, distinct from the little-endian on-disk
   `.profile` header written by `saveProfile` (§4) — there are two serialization layers.
3. **The payload is Lua source, not bytecode** — it is prefixed literally `"return "`
   (`s_return_00bb464c`), so the deserialized text is `return { … }`, exactly what
   `save.rs::decompress_lua()` yields (24.8K–54K of readable Lua `SaveSingleton` text). The engine
   `loadstring`s it back on load.
4. **It runs under one global critical section** `DAT_01174ffc` — the save is atomic w.r.t. the sim.
   Callers: `0x00635455`, `0x005d7d7a` (the event-dispatch sites behind `SaveData`/`SaveComplete`).

### 2.2 `FUN_00874150` = the hash-dispatched per-object serializer (H, READ)

The "run the save under CS" call. It is a **hash-table dispatch** into the reflection/serialize
registry — not a monolithic writer:

```c
undefined4 FUN_00874150(undefined4 param_1) {            // param_1 = stream/context
  iVar1 = FUN_008242b0(0x100);                            // HashTable_Probe (open-addressing, key 0x100)
  piVar2 = (iVar1 < 0) ? (EDI+4) : (EDI + 8 + iVar1*4);   // resolve handler slot
  if (*piVar2 != 0) return (**(code**)(*(int*)*piVar2 + 8))(param_1);  // vcall serializer +8
  return 0;
}
```

`FUN_008242b0` = **`HashTable_Probe`** and the sibling `FUN_00824270` = **`Hash_String`** (asset map
§6: FNV-1a seed `0x811c9dc5`, the `pandemic_hash_m2` family). So the save "writes" by looking up the
registered serializer for the current object-class hash and vcalling its `+8` (serialize) slot — the
mirror of the `CopyFromStream` *load* vtable the asset/streaming maps documented. This is why there
is no single "SaveGame" function body: the write is a hash-driven walk over the same reflection
descriptors that drive load. `FUN_00874150` has ~12+ callers across the streaming/serialize clusters
(`0x872f95`, `0x873f30`, `0x874000`, `0x84e720`, …) — it is the shared serialize-one-object primitive.

### 2.3 The zlib stream codec — `FUN_0075b070` → `FUN_00759xxx` (H, READ)

`FUN_005a4520` calls `FUN_0075b070` (`@0x5a4708`) to (de)serialize the compressed body:

```c
int FUN_0075b070(undefined4 param_1) {
  local_30 = *unaff_EDI; local_34 = param_1;
  iVar1 = FUN_007597e0();                                 // open/init zlib stream
  if (iVar1 == 0) {
    iVar1 = FUN_00759970(local_40, 4);                    // read/consume 4-byte-prefixed chunk
    if (iVar1 != 1) { FUN_0075af90(); ...; return -3; }    // stream error paths
    *unaff_EDI = local_2c; iVar1 = FUN_0075af90();         // finalize
  }
  return iVar1;
}
```

This is the `FUN_00759xxx` codec cluster — the same neighbourhood as **`FUN_00759020`
= `PrecacheManager::Save`**, a fully-read binary-save function that shows the engine's canonical
"directory + sections" disk idiom (a strong *structural analog* for `saveProfile`'s unseen body):

```c
// FUN_00759020 PrecacheManager::Save — the section-offset-table disk format
_File = fopen(name, "wb");
fwrite((void*)(param_1+8), 0x10, 1, _File);               // 16-byte header
_Dst = Chunk_Alloc(count << 5);                            // N × 0x20 section-descriptor table
fwrite(_Dst, 0x20, count, _File);                          // reserve table
for (each section) { lVar4 = ftell(_File); desc.offset = lVar4;
                     (*(vtbl+8))(_File);  desc.size = ftell(_File) - offset; }  // write body, record extent
fseek(_File, 0x10, 0); fwrite(_Dst, 0x20, count, _File);  // rewrite table with real offsets
fflush; fclose;
```

The profile writer (`saveProfile`) is expected to follow this same fixup pattern for its
header+zlib+hash — write header, write compressed body, seek back, stamp `data_size` and
`ProfileHash` — but its body is **not in the dump** (§9).

---

## 3. Versioning + integrity (the RE meat)

### 3.1 `SetLuaSaveVersion` = the version stamp (M — VA, audit)

`SetLuaSaveVersion 0x005E6120` (audit §3.15 CERTAIN; Xbox `0x002c5a4`) writes the save-format version
the on-disk header carries. Retail stamps **`version == 4`** at `.profile@0x04` (proven across all six
retail saves; `save.rs::VERSION = 4`). Body not in the dump → the VA is registration-anchored;
confirm-live to read the store site and the `GetINILoadLastSave 0x002c6ec` companion (which selects
the last-save path).

### 3.2 `ProfileHash` = the integrity hash — **OPEN** (the key unknown)

`.profile@0x00` is a u32 that **varies every save** — it is not a magic; it is the per-file
`ProfileHash` (Xbox symbol `0x003fc78`). The on-disk sentinels that make the file self-describing are
`version==4 @0x04` and `data_size == file_len-4 == 0x3458 @0x08` — i.e. **the hash covers `[4:]`**
(the 13,400 bytes after the 4-byte hash). But the **algorithm is unreversed**: `save.rs` /
`SAVE_FORMAT.md` exhaustively ruled out crc32, fnv1a, sum, xor, and adler over `[4:]`, `[8:]`,
`[4:0x468]`, and `[0x468:]`. It is stored, **not** validated, by the Rust reader. The FNV
`Hash_String 0x824270` family (used for *class-name* keys in §2.2) is a plausible relative but does
not match over the obvious ranges. **This is the single most important confirm-live item** (§8): break
the `saveProfile 0x7BC628` write path and watch the `@0x00` word get computed to recover the algorithm
and the exact covered range.

### 3.3 `hasCorruptedSave` reject FSM — `FUN_00614080` (H FSM, open compare)

`hasCorruptedSave` (Xbox `0x002fe14`, + the `File corrupted!` string) anchors the save-dialog state
machine `FUN_00614080` (game-systems.md maps `hasCorruptedSave → FUN_00614080`, medium). Read
first-hand, it is a rolling event-queue FSM (`DAT_00edb118[]` ring, count `DAT_01175fec`) that, per
queued state, fires a UI trigger via `FUN_00615680`:

```c
case 2: thunk_FUN_024eac90(0x26, 0xc87c625c, 0x13edde28, 1, ..., s_hasAutosave_00bbc434, 1);      // "hasAutosave"
case 3: FUN_00615680(0xc87c625c, 0x32ff679b, 1, ..., s_hasCorruptedSave_00bbc440, 1, 0, 0);        // "hasCorruptedSave"
...     s_loadpreopnomu / s_loadsavedialog / s_signInToLiveError ...                                // sibling save dialogs
```

So `FUN_00614080` is the **corruption-rejection *dispatcher*** (it raises `hasCorruptedSave` as a Lua
trigger, hash `0x32ff679b`, that the shell UI shows as the "File corrupted!" dialog). The actual
byte-level "is this save corrupt" *compare* (hash mismatch / version mismatch) lives on the
`loadProfile`/`ProfileHash` side, which is unlocated — reached only after the hash algo (§3.2) is
recovered. Its sibling `s_hasAutosave` trigger (hash `0x13edde28`) is how the shell offers "resume
autosave".

---

## 4. On-disk `.profile` / `.sav` field map (consolidated ground truth)

**Naming.** PC retail writes `My Games\Mercenaries 2\SaveGames\*.profile` (save path constant at
`0x007B38A4`, exe_analysis_a §14); the file *base name* is the slot label (`auto_<hex>`,
`<Hero Name>_<hex>`). The Xbox uses the TRC filename pattern `NoTRCSave%02d.sav` /
`ConvertNoTRCSave%02d.sav` ("TRC" = Technical Requirements Checklist; the non-cert/dev save path), and
the shell slot UI keys are `ifs.loadsave_xbox.save02..save19` (proven live in `FUN_0050dfd0`:
`s_ifs_loadsave_xbox_save08` / `save19`). **Same logical format, platform-specific container/name.**

**Structure.** A `.profile` is a fixed **13,404-byte** file: a little-endian packed header, then a
**zlib** stream at `0x468` that inflates to the `return { … }` Lua `SaveSingleton` text (§2.1). Diff of
the six retail saves: `const=4363 / vary=9041` bytes.

| Offset | Size | Field | Status | Notes |
|---|---|---|---|---|
| `0x00` | u32 | `ProfileHash` (checksum) | FACT (opaque) | **Not a magic** — varies every save. Integrity hash over `[4:]`. **Algorithm unreversed** (§3.2). Stored, not validated. |
| `0x04` | u32 | `version` | FACT | Always `4` (`SetLuaSaveVersion`, §3.1). Validated. |
| `0x08` | u32 | `data_size` | FACT | `= file_len - 4 = 0x3458` (13400) — the range the hash covers. Validated. |
| `0x0C` | u32 | `unknown_0x0C` | FACT (const) | Constant `3` across all saves. |
| `0x10` | u32 | `unknown_0x10` | FACT (const) | Constant `0`. |
| `0x14` | u32 | `play_time_seconds` | INFERRED | Monotonic seconds; matches Lua `nTimeElapsed`. |
| `0x18` | u32 | `cash` | INFERRED | 50000…~342M, within the 1B economy cap ([[money-fuel-datatype-and-cap]]). |
| `0x1C` | u32 | `fuel` | INFERRED | 0…5485; tracks `fuel_capacity`. |
| `0x20` | u32 | `unknown_0x20` | FACT (const) | Constant `0`. |
| `0x24` | u32 | `timestamp` | FACT | Unix timestamp (2008 devsave `0x48F2C77C` … 2026 `0x6A45586A`). |
| `0x2C` | 16B | `active_contract` | FACT | NUL-padded ASCII mission id (`PmcCon001`, `OilCon003`, `PmcJob001`). |
| `0x4C` | u32 | `flags_0x4C` | FACT | Raw dword; **byte `@0x4D` = hero** (1 Mattias / 2 Chris / 3 Jen = `Get/SetProfileCharacter`, runtime obj `+0x61`). |
| `0x4F` | u8 | `upgrade_index` | INFERRED (strong) | Hero UPGRADE tier 0..3 (`Get/SetProfileUpgrade`, runtime obj `+0x62`) — drives the spawn template / the LOOK. 0 fresh, 3 endgame. |
| `0x20A` | UTF-16z | `save_name` | FACT | Slot label (`auto_634304EA`), NOT the display name. |
| `0x24A` | u8 | `unlocked_costumes` | FACT | Unlocked-costume count (1 fresh, 5 = all base outfits); feeds `Player.GetAvailableCostumes`. Runtime obj `+0x63` = `Get/SetProfileCostume`. |
| `0x2F8` | u16 | `fuel_capacity` | INFERRED | Max fuel; tracks/exceeds `fuel`. |
| `0x462`–`0x467` | 2×u16 | pre-zlib unknown | open | Not lengths; meaning unresolved. |
| `0x468` | — | zlib stream | FACT | CMF `0x78`; inflates to the `return { … }` Lua `SaveSingleton` text. |

**The inflated Lua `SaveSingleton` blob** (`save.rs::SaveState`, verified on `auto_6A447BF8.profile`):
`tFlowData.tCulledBindings` (ordered mission-flow chain), `tFlowData.tActiveMissions`
(`nState`/`_nTargetsComplete`/`tCollected` GUIDs), `tFlowData.tMyFlowData` (completed-flow flags),
`tLayerData` (~200–300 `vz_state_*` world overlays — the streamer's restore set), `nTimeElapsed`,
`vEquippedSupport`, `tStarterData` (unlocked recruits). Each per-manager `SaveSingleton` (MrxPmc
economy, MrxPlayer per-hero health+weapons, MrxLayerManager overlays, MrxMissionFlow, MrxStarterManager)
contributes its own sub-table (§1). Two crash-relevant invariants the reader enforces: `version==4`
and `data_size==len-4`.

---

## 5. Multi-slot profile manager (M)

The `Profile*`/`SaveGame*` verbs form a multi-slot profile manager (game-systems.md; Xbox inventory):
`loadProfile`/`saveProfile`/`AddProfile`/`getListProfiles`/`loadDefaultProfile`/`noDefaultProfile`
manage the *profile* objects; `addSaveGame`/`deleteSaveGame`/`clearSaveGames`/`saveGameSlot` manage the
*save slots* within a profile; `maximumProfiles` (Xbox `0x002f958`) is the slot-count tunable;
`HaveActiveProfile`/`ProfilesComplete` gate readiness; `disableManageSaves`/`disableSave`/
`EnableUsingFakeProfile` are the dev/TRC toggles. PC cfunc VAs (audit §3.15, registration-anchored):
`saveGameSlot 0x7BC190`, `addSaveGame 0x7BC1A0`, `clearSaveGames 0x7BC6C4`, `saveProfile 0x7BC628`.
The `0x7BC1xx`/`0x7BC6xx` clustering (a contiguous Save-table block) corroborates these being one
registration table; the individual bodies are not in the dump → confirm-live to bind the slot-array
layout. `SaveComplete`/`ProfilesComplete` are the completion events the shell save-browser waits on.

---

## 6. Autosave (M)

Autosave is **Lua-triggered, engine-gated**. Lua: `MrxMissionFlow` calls `Pg.SaveGame("autosave")`
only at blocking-sequence quiescence with `_bDoMissionAutosave` set (mrxmissionflow.lua:817, §1).
Engine: the game-state dispatcher `FUN_00614540` (a big string-hash switch keyed by
`Hash_String FUN_00824270`) routes the `autoSave` state — case `0x5a06a0a6`:

```c
if (PTR_PTR_01176054[0x11] && PTR_PTR_01176054[0x25f] &&
    _stricmp(&DAT_00edb070, s_autoSave_00bbc4e8) == 0) {
    thunk_FUN_024ef560();          // SecuROM-thunked autosave worker
    return;
}
FUN_006159a0();                     // else: normal save-preop path
```

so autosave is gated on two profile-singleton flags (`[0x1176054]+0x11`, `+0x25f`) before dispatching
to the native worker `thunk_FUN_024ef560`. The Lua-facing enable/force cfuncs are registration-anchored
(audit §3.15): `IsAutosaveEnabled 0x5E65E0`, `SetAutosaveEnabled 0x5E6610`, `ForceNextAutosave
0x5E6670`, `RequestAutosave 0x5E61F0`; `gameAutoSave`/`autoSave` are the Xbox names. The
`hasAutosave` trigger (hash `0x13edde28`, §3.3) is how the shell offers "resume autosave" on boot.

---

## 7. Lua orchestration — what goes into the blob (H, corpus-read)

The blob content is defined by each manager's `SaveSingleton`/`LoadSingleton` pair (decompiled Lua
corpus [[decompiled-lua-corpus]]):

| Manager | `SaveSingleton` writes | Source |
|---|---|---|
| `MrxPmc` (economy) | cash, fuel, capacity, equipment, stockpile, freebies | `mrxpmc.lua:500` |
| `MrxPlayer` | per-hero health + weapon inventory (parent + reserve ammo) | `mrxplayer.lua:661` |
| `MrxLayerManager` | `tLayerData` = active `vz_state_*` world overlays | (LoadSingleton restores via `MrxLayerManager.LoadSingleton`) |
| `MrxMissionFlow` | `tFlowData` = `tCulledBindings` / `tActiveMissions` / `tMyFlowData` | `mrxmissionflow.lua` |
| `MrxStarterManager` | `tStarterData` = unlocked recruits (`PmcBoss`, `HelPmcBoss`, …) | writes only *unlocked* starters |
| mission-flow FSM | `nTimeElapsed`, `vEquippedSupport` | serialized once each, top-level |

`InitialSaveData` seeds a fresh blob (new game); `SaveData` snapshots the running singleton;
`ResetSingleton` clears it. On load, `LoadSingleton(tSaveData)` (xQ!L.lua) re-hydrates the managers
and hands `tLayerData` to the streamer (§1). The `SaveData`/`InitialSaveData` *event* names are exactly
the strings `FUN_005a4520` dispatches on (`s_SaveData_00bb4640` / `s_InitialSaveData_00bb4630`), which
is the Lua↔engine bridge.

---

## 8. Confirm-live inventory (x32dbg, read-only while PAUSED — [[x32dbg-mcp-no-resume]])

**The two RE-meat items (highest priority):**
1. **`ProfileHash` algorithm + covered range** — HW-write bp on `.profile@0x00` during a save; watch
   the `@0x00` word get computed and single-step the hash loop to recover the algo and confirm it
   covers `[4:]` (13,400 B). Cross-check against `Hash_String 0x824270` (FNV) with the correct
   seed/range. **Still open.**
2. **The profile disk-write body** — confirm the header+zlib+hash fixup follows the
   `PrecacheManager::Save` idiom (§2.3): write LE header, deflate the `return{}` blob to `0x468`,
   seek-back and stamp `data_size@0x08` + `ProfileHash@0x00`. **Still open — but not via the recipe
   below.**

> **⚠ Recipe retracted 2026-07-26 — `0x7BC628` is not a function.** Both items above used to say
> *"break `saveProfile 0x7BC628`"*, item 1 adding *"via a `DecompileProfileAccessors.java`-style
> forcing script, since the body is not in the dump"*. Three compounding errors:
>
> 1. **Transcription slip.** There is no `saveProfile` at `0x7BC628`. The **string** `"saveProfile"`
>    lives at **`0x00BBC628`** — a dropped `B`. Disassembling `0x007BC628` lands mid-instruction
>    (`0c 8b` → `or al,0x8b`) in unrelated float code, so a breakpoint there is meaningless.
> 2. **Wrong kind of thing.** `saveProfile` is not a native function at all — it is an
>    **ActionScript callback name invoked into a Flash movie**. Its single `.text` reference is
>    `0x0061686B: bf 28 c6 bb 00  mov edi, 0xbbc628`, immediately followed by
>    `0x0061687F: call 0x0061C550` — the LTI Invoke funnel, which takes the AS name in **EDI**.
>    Enclosing function `FUN_00616760`. There is no `saveProfile` body to force out of Ghidra.
> 3. **The premise was wrong anyway.** "The body is not in the dump" would not have justified a
>    forcing script even if the address were real — see `ghidra_knowledge_inventory.md` Part F.4.
>
> Related, from the LTI audit: `"loadProfile"` (string `0x00BBC36C`) has **zero** `.text`
> references and is defined in **no shipped `.gfx`** — a dead callback at both ends. So the Flash
> route is not the way in to the hash. The two questions above stay open; find the writer from the
> **`.profile` write side** (HW-write bp, or the `PrecacheManager::Save` idiom in §2.3) instead.

**Serialize driver:**
3. Break `FUN_005a4520` entry with a `Pg.SaveGame("autosave")`; read `[0x1176054]+0x470` (the BE blob
   source) and the `FUN_00874150` result object (`+0x14` tag / `+0x18` ptr / `+0x1c` size). Confirm the
   `ntohl` header `{ver==1, ?, size}` and the `"return "` prefix live.
4. Break `FUN_00874150`; dump the `HashTable_Probe(0x100)` handler slot to enumerate which object
   classes register a serializer (the write-side mirror of the `CopyFromStream` load registry).

**Version / corruption / slots:**
5. `SetLuaSaveVersion 0x5E6120` — read the version store site + `GetINILoadLastSave 0x2c6ec`.
6. `FUN_00614080` — confirm the `hasCorruptedSave` (`0x32ff679b`) / `hasAutosave` (`0x13edde28`) trigger
   hashes fire the shell dialogs; then find the *upstream* load-side compare that decides "corrupt"
   (post-hash-algo).
7. `saveGameSlot 0x7BC190` / `addSaveGame 0x7BC1A0` / `clearSaveGames 0x7BC6C4` — read the slot-array
   layout inside the profile object to bind the multi-slot manager.

**Autosave:**
8. `FUN_00614540` case `0x5a06a0a6` — confirm the `[0x1176054]+0x11 / +0x25f` gate flags and the
   `thunk_FUN_024ef560` autosave worker; read `IsAutosaveEnabled 0x5E65E0` state.

---

## 9. Open / unlocated (honest)

- **`ProfileHash` algorithm** — the on-disk integrity hash (@0x00 over `[4:]`) is **unreversed**; ruled
  out crc32/fnv1a/sum/xor/adler over every obvious range (save.rs / SAVE_FORMAT.md). Primary open item.
- **`saveProfile 0x7BC628` disk-write body** — not in the Ghidra dump (registration-anchored VA). The
  actual LE-header + deflate + write-to-`SaveGames\*.profile` code (and where the hash is stamped) is
  the missing write side; `PrecacheManager::Save FUN_00759020` is only a *structural* analog.
- **All Save-namespace cfunc VAs in audit §3.15** (`0x7B8AC4`, `0x7B44FC`, `0x5E6120`, `0x5E61F0/E0/10/70`,
  `0x7BC190/1A0/6C4/628`) are **registration/binding-table anchored, not decompiled bodies** — treat as
  "where the table entry lives", confirm-live for the real prologue. (Consistent with [[shell-menu-and-save-browser]]:
  binders missing from the ghidra export are binding-table-only refs.)
- **`.profile@0x462–0x467`** (two u16 immediately before the zlib) — not lengths; meaning unresolved.
- **The BE `SaveData` blob header word[1]** (between `ver==1` and `size`) — purpose unread.
- **The load-side corruption compare** — `hasCorruptedSave` is *raised* by `FUN_00614080`, but the
  byte-level check that sets it (hash/version mismatch in `loadProfile`) is unlocated until §3.2 lands.
- **Xbox save code bodies** — as everywhere in the Jul-08 build, the `saveProfile`/`loadProfile`/…
  *functions* are unlocated by name; only the `.rdata` symbol strings are Xbox ground truth.

---

## 10. Reconciliation with `mercs2_engine` (row 29 = 🟡 read ✅ / write ❌)

The engine is **read-only** on saves today: `mercs2_formats::save` parses the `.profile` header + the
inflated Lua `SaveState` (validated on all six retail saves) and the shell save-browser boots a picked
save ([[shell-menu-and-save-browser]]). This map is the **write-side reimpl target**:

- **The serialize contract** (§2): the write side must emit a `return { … }` Lua text blob assembled
  from the per-manager `SaveSingleton` outputs (§7), sourced from the profile/economy singleton — i.e.
  the engine's `SaveState` → Lua-table serializer, the inverse of the current parser.
- **The container** (§4): fixed 13,404-byte file, LE header (`version=4`, `data_size=len-4`), zlib at
  `0x468`, then the two-layer note — the *inner* engine blob is BE (`ntohl`) with a `{ver=1,…}` header,
  the *outer* file header is LE. A faithful writer reproduces both.
- **The integrity hash** (§3.2) is a **hard blocker** for producing loadable saves: until the
  `ProfileHash` algorithm is recovered (confirm-live #1), the engine can *read* but cannot *write* a
  save the retail exe will accept — a modern reimpl either recovers the algo or (if it owns both ends)
  substitutes its own. This is the single most valuable open item in row 29.
- **Autosave gating** (§6) and the **corruption-reject trigger** (§3.3) are the shell/UX behaviors to
  mirror once the write path exists.

Net: row 29's *shape* is fully mapped (Lua seam → `FUN_005a4520`/`FUN_00874150` → zlib → singleton
`[0x1176054]`), the on-disk header is proven, and the two write-side unknowns — the `ProfileHash`
algorithm and the `saveProfile` disk-write body — are isolated and confirm-live-ready.
