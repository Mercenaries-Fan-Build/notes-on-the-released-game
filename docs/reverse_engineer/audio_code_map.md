# Mercenaries 2 — Audio subsystem (Pal + Pangea): PC code map

**Scope:** the complete PC-side audio stack in `Mercenaries2.exe`, reversed from the unpacked
SecuROM image (`output/_ghidra/securom_dump/mercs2_unpacked.exe` / `image.bin`, base 0x400000) and
the 27,077-function decomp (`output/_ghidra/all_functions_decomp.txt`) via a multi-agent fan-out.
Machine-readable table: **`docs/data/audio_code_map.json`**.

This binds the Xbox devkit symbol inventory in
[../mercs2-pdb-analysis/audio-pal.md](../mercs2-pdb-analysis/audio-pal.md) to **PC addresses**, and
completes the "marry the Xbox PDB to the decompiled bodies" task. Companions:
[event_bus_code_map.md](event_bus_code_map.md), [scheduler_tick_code_map.md](scheduler_tick_code_map.md),
[particle_fx_code_map.md](particle_fx_code_map.md). Script-side consumer:
[../mercs2-luacd/08_audio_presentation.md](../mercs2-luacd/08_audio_presentation.md).

## 0. The honest boundary (read this first)

The audio stack is **two cooperating layers** with very different anchor quality on PC:

1. **Pal (Pandemic Audio Library)** — the low-level engine (`Pal\src\`, `Pal\src\low-level\`). On PC
   the Pal methods **self-announce**: each pushes its own `Class::Method` name string through the
   profiler vtable `DAT_01176404` on entry/exit. That makes **24 Pal methods high-confidence string
   anchors** — the function literally names itself. This is the opposite of PgFX (which stripped all
   its markers). The Xbox `*Xenon` backend classes become **`*DX8`** on PC (source file
   `Pal\src\low-level\PalSoundWaveDX8.cpp`, string confirmed in `image.bin`).
2. **Pangea (`Pg*`)** — the high-level layer (message bus, sound DB, music state machine, banks,
   ambience, stream I/O). The PC retail build **stripped every `Pg*` profiler-marker string**
   (`SoundPlayer.Update`, `BankMan.Update`, `MsgFilter`, `SoundMsgTranslator`, `MusicManager.Update`,
   `RtSound*`, `CacheCharacters`, `PgSoundMessage{Filter,Handler,Translator}` — **zero** hits as
   literals or `s_` symbols). This layer was recovered **structurally**: by walking the master tick,
   matching the Xbox ordered pipeline pass-for-pass, and cracking the m2 asset/param name-hashes.

Two things anchor the whole map and are **independently cross-verified** against the Xbox build:
- The sounddb parser `FUN_00835b80` tests `*param_1 == '\x1d'` — the same **`'\x1d'` node tag** the
  Xbox analysis found in `PalEngine.cpp` (`FUN_828ce9b8`). Version byte matches across builds.
- The audio update pipeline order inside `FUN_005fa950`/`FUN_006073c0` reproduces the Xbox
  `SubmitToGroups` marker table pass-for-pass (§4).

Where a body is missing from the Ghidra export (SecuROM-split prologue), it was disassembled from
`image.bin` with capstone and is marked **(gap)** — same treatment the GFx/PgFX maps used. Bodies
behind SecuROM-morphed call thunks (`thunk_FUN_02xxxxxx`) are marked **confirm-live (x32dbg)**.

## 1. Architecture at a glance

```
Lua  ─ Sound.* (88 fns @0xB98C98) ─┐   VO.* (11 fns @0xB988B0)
                                   │
  MrxSound* scripts                ▼
                         ┌───────────────────────────────────────────┐
  Pangea (Pg*)          │ FUN_005fa950  PgSound::Update (hi-level)    │  master tick
  — retail-stripped     │ FUN_00515300  VO/dialog update             │  FUN_004c9740
    markers, recovered  │ FUN_006073c0  PgSoundPlayer::Update        │  (three call sites)
    structurally        └───────────────────────────────────────────┘
                                   │ msg bus / cue dispatch / bank mgr
                                   ▼
  Pal (self-naming)     ┌───────────────────────────────────────────┐
  — 24 string anchors   │ PalEngine / PalGlobalTable / PalSound*     │
                        │ Instance · Source · Wave(DX8) · Mixer      │
                        └───────────────────────────────────────────┘
                                   │
  DX8 backend           DirectSound8 + EAX + software mixer thread (45 ms)
                        FUN_00831ee0 (thread) → FUN_00836610 MixSources
```

Key difference from Xbox: **PC has no hardware voice pool.** The entire
`PalSoundXenonVoiceManager::{CreateVoice,DeleteVoice,KillOldVoice,CreateNewVoice,FindExistingVoice}`
family **has no PC counterpart** — waves are software-mixed into **one streaming DirectSound
secondary buffer**, and contention is handled purely in shared code via
`PalSoundInstance::StealWave`/`GetLowestPrioritySound`.

## 2. Where audio sits in the master tick

`FUN_00631670` (WinMain loop) → `FUN_00630ef0` (RunFrame) → `FUN_004c14f0`/`FUN_004c15e0` (5-layer
stack) → `FUN_004c0ec0` → **`FUN_004c9740`** (the ~40-subsystem master frame tick). Audio has
**three call sites** there, in order (verified in body):

| Call site | Function | Role |
|---|---|---|
| `0x4c99ae` | `FUN_00515300()` | VO/dialog system update (feeds cues onto the event bus) |
| `0x4c9b78` | `FUN_005fa950(dt)` | **PgSound::Update** — hi-level umbrella (msg bus, listeners, runtime comps, banks, ambience, groups) |
| `0x4c9c0a` | `if (thunk_FUN_024e67b0()) FUN_006073c0(DAT_01175fac, …)` | **PgSoundPlayer::Update** — lo-level umbrella over the Pal engine, gated by audio-enabled thunk |

**MixSources does NOT run in the tick.** It runs on a **dedicated mixer thread** `FUN_00831ee0`
(`callers=[]`): `WaitForSingleObject(engine+0x43c, 5ms)` → `EnterCriticalSection(engine+0x1c0)` →
`FUN_00836610` (MixSources) → leave CS → `Sleep(0x2d)` (45 ms cadence), exits on `DAT_01175fff`.

## 3. Pal (Pandemic Audio Library) — low-level engine

### 3.1 Self-naming method anchors (high confidence — 24 profiler-scope strings)

| PC FUN_ | Xbox symbol | Role |
|---|---|---|
| `FUN_0082ee60` | `PalEngine::BankUpdate` | BankMan pass: walk cue list @engine+0x50 (`FUN_00835060`), recycle finished into ring `DAT_01176400`, timer list @+0x30, then `(*vtbl+8)(dt)` = engine Update |
| `FUN_00835a70` | `PalGlobalTable::FindCue` | cue resolve: `FUN_0083c610` (id<0x401 direct) / `FUN_0083c760` (0xffff-sentinel hashed) |
| `FUN_00836280` | `PalSoundEngine::GetClosestListener` | 4 listeners, pos = engine+0x50+i·0x60 (matrix translation), returns index |
| `FUN_00836610` | `PalSoundEngine::MixSources` | mixer→PrepareMix, per-source MixWavesToOutput, mixer→MixWave (runs on mixer thread) |
| `FUN_00836c70` | `PalSoundInstance::Update` (+CalcSubmitValues / CreateWave / WaveUpdate / MaxDistCheck / StopCheck / WaveSubmitValues / CheckFinished, all inlined) | 3 KB per-instance state machine; all 8 scope strings verified in-body |
| `FUN_00837830` | `PalSoundInstance::GetLowestPrioritySound` | voice-steal victim selection |
| `FUN_00837c50` | `PalSoundInstance::StealWave` | wave→Stop(1), state→3/2, `FUN_008387b0` detach |
| `FUN_00837f00` | `PalSoundInstance::GetWaveVolumeScale` | calls GetClosestListener |
| `~0x00837e30` (gap) | `PalSoundInstance::GetWavePriority` | string 0xbe2120 ref'd at 0x837e43/61/b9/d6 |
| `FUN_00838380` | `PalSoundSource::Update` / `UpdateWaves` | per-source update / wave-submit |
| `0x00838860` (gap; thunk `FUN_00838850` via `_DAT_02455da8`) | `PalSoundSource::MixWavesToOutput` | self-announces string 0xbe21a0 |
| `FUN_0083e1d0` | `PalSoundWave::UpdateMixVolumes` | recompute per-wave mix volumes |
| `FUN_0083e430` | `PalSoundWave::GetMixVolume` | mix-volume accessor |
| `FUN_00836400` (gap) | `PalSoundEngine::UpdateSources` (vtbl+0x5c) | announces string 0xbe1f38; master fade @+0x1dc + source list walk |

### 3.2 Engine object & DX8 vtable

- **`FUN_00830640`** = `PalSoundEnginePC` singleton lazy-ctor → **`DAT_019c6170`** (~0x450 bytes),
  vtable **0xbe1d48** (PC); base ctor `FUN_00835ee0`, base vtable **0xbe1f78**.
- Vtable slots (24): `+0x00` Initialize (`FUN_00830790` PC / `FUN_00835fd0` base), `+0x04` Shutdown
  (`FUN_00830820`/`FUN_00836090`), `+0x08` **Update** (`FUN_00830940` PC), `+0x0c` PopPendingSource
  (`FUN_00836530`), `+0x10` RemoveSource (`FUN_008365a0`), `+0x14` SetListener (`FUN_00836230`),
  `+0x18` SetListenerEnvironment (`FUN_008363b0`/`FUN_00830840` gap), `+0x1c` GetListenerEnvInfo
  (`FUN_00830920` gap), `+0x20` IsUsable (`FUN_008305b0` gap), `+0x4c`/`+0x50` StartMasterFade /
  GetMasterFadeVolume (`FUN_00830430`/`FUN_00830450` gap), `+0x54` dtor (`FUN_00835fa0`), `+0x58`
  UpdateListeners / EAX-env (`FUN_008309b0` gap; base = ret), `+0x5c` UpdateSources (`FUN_00836400`).
- `FUN_00830940` **PalSoundEnginePC::Update** (per frame from BankUpdate): under CS, vcall+0x58 then
  vcall+0x5c(dt), then `IDirectSound3DListener::CommitDeferredSettings` on +0x378, `SleepEx(0,1)`.

### 3.3 DirectSound8 + EAX backend init

| PC FUN_ | Role |
|---|---|
| `FUN_00831b10` | `PalSoundEnginePC::CreateDevice`: `DirectSoundCreate8`→+0x370; `SetCooperativeLevel(hwnd@+0x21c, DSSCL_PRIORITY)`; `GetSpeakerConfig`→mode @+0x1a0; `CreateSoundBuffer(PRIMARYBUFFER)`→+0x374; `SetFormat` (1/2/4/6 ch, 16-bit, `WAVE_FORMAT_EXTENSIBLE` if >2ch); `Play(LOOPING)`; +0x200=1 |
| `FUN_008305d0` | `GetOutputSampleRate`: 44100 if EAX/enabled/override else 22050 |
| `FUN_00832030` | EAX support probe: CTRL3D probe buffer +0x37c, QI `IDirectSoundBuffer8`/3D/`IKsPropertySet` (+0x380/384/388), QuerySupport EAX2→EAX5 GUIDs, sets EAX level @+0x204 |
| `FUN_00832470`/`8325a0`/`832710`/`832a80` | EAX2 / EAX3 / EAX4 / EAX5 initial property setup (dispatched on +0x204) |
| `FUN_00831db0` | release DSound: 3DListener/primary/device |
| `FUN_00831e20`/`00831ee0`/`00831e70` | mixer thread create (prio 1) / **thread proc (45 ms loop)** / kill |

### 3.4 Software mixer (replaces XAudio hardware voices)

- **PalSoundMixer PC singleton `DAT_01995d70`**, vtable **0xbe2440** (base pures @0xbe242c):
  `{dtor FUN_0083c860, Init FUN_0083c880, Release FUN_0083c9b0, PrepareMix FUN_0083c9c0,
  MixWave FUN_0083cbf0}`.
- `FUN_0083c880` Init: ~200 ms stream buffer sizing; `CreateSoundBuffer(GETCURRENTPOSITION2 |
  GLOBALFOCUS)`→+4, QI `IDirectSoundBuffer8`→+8.
- `FUN_0083c9c0` PrepareMix: QPC write-cursor advance, resync every ≥500 ms, `Lock` (Restore+retry on
  `DSERR_BUFFERLOST 0x88780096`), zero into 0x30000-byte int32 accumulator @+0x68.
- `FUN_0083cbf0` MixWave/Commit: int32 accumulator → `packssdw` saturate → int16 → Unlock/Play.
- Per-wave: `FUN_00839ae0` PalSoundWaveDX8 mix (dispatches format kernel table `DAT_0198db60`
  [channels + 2·format]); kernels `FUN_00839f20/fd0`, `FUN_0083a200/510/790`; `FUN_0083ade0`
  volume/3D calc (Doppler pitch, per-listener channel-gain `DAT_00fc34b0`).

### 3.5 Sources, instances, pools, cues

| PC FUN_ | Role |
|---|---|
| `FUN_00838110`/`8381e0` | PalSoundSource ctor (0xA0 bytes, vtable 0xbe21c4, type→+0x98) / Reset |
| `FUN_00838670` | Source::UpdateWaves reap loop (alive-check → stop → unlink → free) |
| `FUN_00838710` | Source::AddWave (link into source list +0x14/+0x18, count +0x20) |
| `FUN_008369e0` | PalSoundInstance::Start/Init — **start delay = distance-to-closest-listener × inv-speed-of-sound** (@+0x70); state@+0x88=0 |
| `FUN_00836be0` | PalSoundInstance::Reset/Stop (wave→Stop, state=2) |
| `FUN_00834660`/`8346e0` | instance pool alloc (ring @pool+0xb8) / free |
| `FUN_00833e80`/`00834850` | PalInstanceAllocator pool init (0xA0 pool objects) |
| `FUN_00835b80` | PalGlobalTable **sounddb parser** — version byte `'\x1d'`, u16 counts @+0xA/+0xC, 8-byte GUID entries @+0x14, binary search `FUN_0083c570`, 0x10-stride cue map |
| `FUN_0082f5e0` | alloc **0x28-byte cue/bank node** (PalEngine.cpp:0x4bd) = the Xbox `'\x1d'` node |
| `FUN_0082e310` | delayed-cue/wave timer list update ("WaveDelay") |

## 4. Pangea (Pg*) high-level layer

### 4.1 Ordered pipeline (PC) — matches Xbox `SubmitToGroups` pass-for-pass

Inside **`FUN_005fa950`** (PgSound::Update): queue-flip/MsgHandler (`FUN_00608110`) → volume params
(`FUN_005fa500`) → **UpdateListeners** (`FUN_00608aa0`) → **RuntimeSoundUpdates / Rt*Collect**
(`FUN_005fa720`, skipped when paused) → **UpdateLoads** (`FUN_00601dd0`) → **CacheCharacters**
(`FUN_00600240`) → stream-binding (`FUN_00608800`) → **MsgFilter / SoundMsgTranslator::Update**
(`FUN_005fda10`) → **CollisionHandling** (`FUN_005fd5f0`) → **SoundAmbience.Update?**
(`thunk_FUN_024f2850`, confirm-live) → **UpdateGlobalParams** (`FUN_005fa690`) → **GroupManager::Update**
(`FUN_00607700`).

Then inside **`FUN_006073c0`** (PgSoundPlayer::Update): engine-start (`FUN_006080a0`) → bank attach +
music-asset delivery (`FUN_00607c50`) → listeners (`FUN_006066a0`) → global-params commit
(`FUN_00607890`) → **UpdatePause** (`FUN_006079c0`) → **ProcessingCueMessages** (`FUN_00607610`) →
**SoundPlayer.Update** (`FUN_006034b0` → `FUN_006036c0` per instance) → conditional stop-all →
**MusicManager.Update** (`FUN_00600450`) → **BankMan.Update** (`FUN_0082ee60`, into Pal).

Every Xbox marker is accounted for **except `UpdateStreamBlocks`** — on PC bank/stream loads go
through the WAD streaming manager (`FUN_00872f80`/`FUN_00873140`/`FUN_00874150`), so the `.pws`-style
stream-block pump is merged into UpdateLoads (`FUN_00601dd0`, owns stream-state object `DAT_01175fa8`).

### 4.2 Message bus (Xbox filter→handler→translator on PC)

- **`FUN_005fda10`** = the 14-slot `PgSoundMessageTranslator::Update`: drains ~14 typed queues
  (queue array `DAT_015386b0`, ctx `DAT_015386d0`), each `while(pop(q_i)) handler_i(...)`. Handlers:
  `FUN_005fef40`, `FUN_005fc950/ca00`, `FUN_005fe210`, `FUN_005fce10/cf80/cc00`, `FUN_005fe880/e340`,
  `FUN_005fed10`, `FUN_00604d30`, `FUN_005feea0`.
- **Event-bus tie-in:** one slot pops via `FUN_005ed590` (Keystone-B subscriber registry range
  0x5edxxx), so sound messages are partly fed from the event bus; VO (`FUN_00515c10`) publishes back
  onto bus frame `PTR_PTR_01175f30+0x18` via `FUN_0059dd70`.
- **Not located statically:** the `DAT_015386xx` singleton **constructors** (only zeroed by teardown
  `FUN_005f9c10`); the lazy 14-slot factory fill is in SecuROM-relocated code — **confirm-live** by
  breaking on first write to `DAT_015386b0`.

### 4.3 Sound database, banks, music, movie audio

| PC FUN_ | Role |
|---|---|
| `FUN_006025d0` | Pg asset attach dispatch (sounddb 0xE5273C14 / sound+wavebank / musicmarkers 0xe8df4d87 / musictransitions 0xc122545a) |
| `FUN_00607c50` | bank attach/detach processor + **MusicMarkers/MusicTransitions delivery** into music mgr `DAT_011763f8` |
| `FUN_00601dd0` | UpdateLoads — 65-slot (0x41×0x1c) bank-load state machine on bank mgr `DAT_01175f9c` |
| `FUN_00602880` | bank-slot release/unload; on soundbank (0x9F8BCA10) re-requests sounddb block |
| `FUN_00603110` | soundbank/wavebank async load completion (`FUN_00464780` Chunk_GetEntryReader → `FUN_0084ac20` Chunk_Alloc → `FUN_00605f90` fixups) |
| `FUN_00600450` | MusicManager::Update (Pg wrapper) — pause sync + music-index change → `FUN_0082d920/d7a0/d6e0` |
| `FUN_0082d7a0` | **MusicStateMachine::Transition** — dual-deck (this / this+0x28; active = +0xc==1); states 5/4/2 |
| `FUN_0082d970` | transition resolve: `FUN_0082df90` MusicMarkers eval, `FUN_0082e140` MusicTransitions record, `FUN_0082de20` match (from,to) |
| `FUN_005fab20` | audio world-reset — stop all, re-stamp bank mgr with `mercs2globals` (0x37750257), reset stream state |
| `FUN_007098a0` | **PgMoviePlayer init**: `BinkSetSoundSystem(BinkOpenDirectSound, DAT_019c64e0)`; binds movie slots (stride 0x190, 3 slots) to streamed **texture** nodes (0xF011157A) |
| `FUN_0070a230` | PgMoviePlayer frame pump: `BinkWait → BinkDoFrame → BinkCopyToBuffer → BinkNextFrame`; `BinkSetSoundTrack(4,…)` = 4 audio tracks |
| `FUN_00621ab0`/`00621bc0` | movie pause/unpause (`BinkPause`) from UI screen driver |

**sounddb chain:** Lua `Sound.AddPgAsset("Mercs2Globals","sounddb")` → `FUN_006025d0` (0xE5273C14) →
cmd ring → `FUN_00607c50` → parser `FUN_00835b80` (into PalGlobalTable `DAT_011763fc`) → runtime
lookup `FUN_00835a70` FindCue ← wrapper `FUN_005faca0` ← VO path `FUN_00515c10` (cue name literally
`sprintf("_0x%x", guid)`).

## 5. Lua script surface

Master module registry `.data 0x00DFD478` (31 modules). **`Sound`** table @**0x00B98C98** (88 entries),
**`VO`** table @**0x00B988B0** (11 entries), registrar `FUN_005a2c40`. `Sound._GetLibVersion`
(`FUN_005e4300`) returns **12.0** (`DAT_00dfdb4c`) — all script version branches (≥10/11/12) active.
`VO.PRIORITY_*` constants come from a postamble Lua chunk @0xBBA910 (not C functions).

Selected high-value bindings (full 88+11 table in `docs/data/audio_code_map.json`):

| Lua name | shim | impl | notes |
|---|---|---|---|
| `CueSound` | `FUN_005e0ff0` | builds 0x38-byte event → `thunk_FUN_024b65e0` | queue-post SecuROM-morphed → PalSound dispatcher |
| `StopSound`/`PauseSound` | `FUN_005e10f0`/`11f0` | `thunk_FUN_024b65e0` | same event, opcode differs |
| `SetCategoryVolume`/`Pitch` | `FUN_005e12f0`/`1390` | `FUN_00607960` | double-buffered pending list (max 10/frame) |
| `TransitionMusic` | `FUN_005e1600` | musicSM+0x115C write | SM = soundsys+0x48 + regionIdx·0x119C; optional net bcast |
| `AddMusicState` | `FUN_005e1fa0` | `FUN_005fb460`→`FUN_00600d30` | 0x128-byte state record + re-index |
| `AddMusicTransition` | `FUN_005e2110` | `FUN_005fb4b0`→`FUN_00600df0` | links from→to state |
| `BindMusicCue` | `FUN_005e14a0` | `FUN_00600eb0` | append cue to faction-region record |
| `LoadSoundBank`/`LoadWaveBank` | `FUN_005e2630`/`26b0` | `FUN_006026c0` | (`LoadWaveBank` is 0x5E26B0, **not** 0x5E26D0) |
| `SetMasterVolume` | `FUN_005e4240` | `FUN_0082f590` → vcall `(DAT_019c6170+0x4C)` | lazy-registers device callback |
| `OpenStreamFile`/`CloseStreamFile` | `FUN_005e4020`/`40d0` | `thunk_FUN_035f0000` / `FUN_00606c00` | **corrects** old 0x7B9A10/00 (were string VAs) |
| `VO.Cue` | `FUN_005e9de0` | `thunk_FUN_028da000(speaker,cue,priority,…)` | confirm-live |
| `VO.Cancel` | `FUN_005ea0a0` | `FUN_005150d0` | scans VO queue `DAT_01175dbc`, fires cancel callback, net-replicates |

**9 of 88 Sound bindings are `return 0` stubs** (`FUN_006d5640`): the `SetSourceEnter/Exit/Transition`
music family (replaced by lib-v12 entry-states), `AddFadeCategory`, `ClearPitchCategories`,
`AddPitchCategory`, `SetCinematicMode`, `_SummonEd`. The Scaleform AS2 `Sound` class
(`attachSound`/`loadSound`… @0xB93708, `FUN_007aa750`) is **registered but fully stubbed** on PC —
Flash UI sound routes through the game cue system instead.

## 6. Voice chat (separate module — NOT Pal)

`FUN_00847170` "GVStartup" voice-chat init (`OutputDebugString "GVStartup: Checking for devices…"`)
waits `FUN_008495c0` (`DirectSoundEnumerateA`) then per device `FUN_00849f80` (`DirectSoundCreate` +
`DirectSoundCaptureCreate`). This is the multiplayer voice path, unrelated to the game audio engine.

## 7. Name-hashes (m2)

**Cracked this session:** `mercs2globals`=0x37750257, `sfx`=0x767495e2, `music`=0x4111ecda,
`vo`=0xd221dbe8, `action_level`=0xbc67d784. **Known asset types:** sounddb 0xE5273C14, soundbank
0x9F8BCA10, wavebank 0xF753F6D0, musicmarkers 0xe8df4d87, musictransitions 0xc122545a, movie-texture
0xF011157A. **Uncracked (rainbow-table candidates):** global params 0x6c2c113d, 0xd11adef6,
0xd913464b, 0x75a993a; message sub-types 0x78b68f3b, 0xBFBD4CAB, 0x8602E37D, 0x12ebca98.

## 8. Key structs & globals

- **`DAT_019c6170`** PalSoundEnginePC (~0x450 B): +0x18 listener count, +0x1c[4] active flags, 4
  listeners stride 0x60 (matrix @+0x20+i·0x60, translation=+0x50→`DAT_019c61c0`, velocity +0x60),
  +0x1a0 speaker mode, +0x1c0 CS, +0x1dc master fade, +0x200 device-ok, +0x204 EAX level, +0x21c
  HWND, +0x220/+0x290/+0x300 EAX prop blocks, +0x370 IDirectSound8, +0x374 primary, +0x378
  3DListener, +0x388 IKsPropertySet, +0x43c/+0x440 mixer thread event/handle.
- **`DAT_011763fc`** PalEngine (0x14c B): +0x14/+0x18 hash param table (8-B entries), +0x30 timer
  list, +0x50 cue-instance list. **`DAT_01176400`** = the "PalQueue" cross-thread ring block.
  **`DAT_011763f4`** = sound-stream IO mgr. **`DAT_01176404`** = profiler vtable. **`DAT_01175fff`**
  = mixer shutdown flag.
- **PalSoundInstance** node: +0x2c source, +0x30 wave, +0x34 record, +0x70 distance start-delay,
  **+0x88 state (0 starting / 1 playing / 2 finished / 3 steal-pending)**.
- Music state machine: soundsys `DAT_01175f7c` +0x48 + regionIdx·**0x119C**; state records 0x128 B.
- Reverb env table: **26 envs** (`DAT_01176408`=0x1a), stride 0xb0 @0xcf1370.
- Vtables (from `image.bin`): engine base 0xbe1f78 / PC 0xbe1d48; source 0xbe21c4; wave base 0xbe24d0
  / DX8 0xbe2240; mixer base 0xbe242c / PC 0xbe2440.

## 9. Corrections to prior docs

- **audio-pal.md** "PC cross-reference" listed only 22 string-anchored fns and missed the DX8 backend
  entirely. This map adds: the `*DX8` PC backend (`PalSoundWaveDX8.cpp`), 4 more self-named anchors
  (`GetClosestListener` `FUN_00836280`, `GetLowestPrioritySound` `FUN_00837830`, `GetWaveVolumeScale`
  `FUN_00837f00`, `UpdateSources` `FUN_00836400`), the mixer thread, EAX init, full vtables, and the
  entire Pg pipeline + music state machine. The **`'\x1d'` node tag is now cross-verified on PC**
  (`FUN_00835b80` / `FUN_0082f5e0`).
- **lua_engine_bindings_audit.md §3.9**: `OpenStreamFile`/`CloseStreamFile` were listed as
  `0x007B9A10`/`0x007B9A00` — those are **name-string VAs** (0xBB9A10/00) with a dropped nibble; real
  shims are `FUN_005e4020`/`FUN_005e40d0`. `LoadWaveBank` is `0x005E26B0`, not `0x005E26D0`. The
  "SetSourceMusic family CONFIRMED" row is wrong — four are `return 0` stubs on PC.
- **audio_crash_analysis.md**: calls vtable 0xbe2440 "PalSoundWave static vtable" — it is the 5-slot
  **mixer** vtable; the PalSoundWave vtables are 0xbe2240 (DX8) / 0xbe24d0 (base).

## 10. Open questions & confirm-live targets

1. **Ghidra-gap bodies** — `0x00838860` (MixWavesToOutput), `~0x00837e30` (GetWavePriority),
   `FUN_008309b0`/`FUN_00836400`/`FUN_00830840`/`FUN_00830920`/`FUN_008305b0`/`FUN_00830430`/
   `FUN_00830450` (engine vtable slots), and the Lua shims for the 45 bindings missing from the
   export (Sound `0x5e1430`… + VO `0x5ea1c0`…). **Recover by disassembling the VA.**

   > **Corrected 2026-07-26.** Previously filed as *"exist only in `image.bin`, worth a targeted
   > re-export / `DecompileProfileAccessors.java`-style pass"*. The two Lua-shim heads named here
   > were checked directly: `0x5E1430` (`51 53 8b 5c 24 0c …`, 27 insns to `ret`) and `0x5EA1C0`
   > (`53 56 8b 35 bc 5d …`, 14 insns to `ret`) are ordinary `.text`. Absence from the export means
   > Ghidra had no static caller to walk from — not that the body is missing. This is an
   > afternoon's disassembly, not a blocked item. See `ghidra_knowledge_inventory.md` Part F.4.
   > (The eight `0x0083xxxx` engine-vtable entries were not individually re-checked.)
2. **Message-bus & singleton constructors** (`DAT_015386xx`, 14-slot factory fill) are in
   SecuROM-relocated code — break on first write to `DAT_015386b0` to catch construction live.
3. **SecuROM-thunked hot paths** — confirm-live: cue dispatch `thunk_FUN_024b65e0`, `LoadBank`
   `*_DAT_0244fb2c`, `OpenStreamFile` `thunk_FUN_035f0000`, `VO.Cue` `thunk_FUN_028da000`, ambience
   update `thunk_FUN_024f2850`, audio-enabled gate `thunk_FUN_024e67b0`.
4. **8 uncracked m2 hashes** (§7) — add to the rainbow table (candidates: interior, underwater,
   danger, camera-distance).
5. Wave-object construction/format-bind site (candidates `FUN_0083ab00/ab60/ac00/ac40`, unread) and
   the `DAT_0198db60` kernel table's format axis (PCM8/PCM16/ADPCM?).

## Provenance

All addresses PC retail, base 0x400000. Anchors are (a) Pal self-named profiler-scope strings —
high; (b) master-tick call-site position + Xbox pipeline order match — high for the umbrellas; (c)
m2 name-hash constants in-body — high; (d) `image.bin` vtable/disasm reads for gap bodies — marked
per-row. Xbox oracle: [../mercs2-pdb-analysis/audio-pal.md](../mercs2-pdb-analysis/audio-pal.md).
