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

**On-disk tables:** the byte layouts of `sounddb`, `soundbank` and `wavebank`, and how a cue name
resolves through them to a wave, are specified in §11.

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
6. **Bank-table unknowns (§11).** The fields marked *unknown* in §11.4 and §11.7 and the streamed
   wave record's `+0x1C` have no established meaning. Automation kinds 4, 7, 8, 9 and 10 are read
   (§11.9) but what consumes kind 4's channels 2–7 and kind 9/10's track fields `+0x68`/`+0x6C`/`+0x74`
   is not traced; kind 10 is handled by `FUN_0083b4a0` but no retail cue carries one, so its size is
   unmeasured. Nor is the reader of the sound instance's `+0x80` byte (the multi-wave group's loop
   count, §11.4) traced, so how a looping group repeats its wave is open. The §3.5 row for
   `FUN_00835b80` ("u16 counts @+0xA/+0xC, 8-byte GUID entries @+0x14") describes the parser's reads
   of the *global* sounddb (category count at `+0x0A`, parameter count at `+0x0C`, category table
   offset at `+0x14`), not the per-bank cue table of §11.3.
7. **Sound generator seed (§11.8), confirm-live.** Pal init stores the low 32 bits of the tick
   callback `0x0040B360` (a `jmp [0x0245E984]` import thunk SecuROM resolves at run time) as the
   generator seed. Which Windows function that slot resolves to is not visible statically. Live step
   (Windows, the Ess live harness running the retail exe under x32dbg): break at `0x0082E774`
   (`call [0x00CF130C]`), step over it, and record `EAX` and `EDX`; follow `[0x0245E984]` in the dump
   and name the export it lands on (x32dbg's symbol column); confirm the value just stored at
   `[0x00DFCD1C]` equals the recorded `EAX`. Then break on the next execution of `0x00834A80` and
   check the state it reads is still that seed (nothing else writes `0x00DFCD1C` before the first
   draw, per the decomp's cross-references).

## 11. Sound bank tables — format specification

This section specifies the three on-disk tables a sound bank is made of — `wavebank`, `soundbank`
and `sounddb` — well enough to read any retail bank and to write new ones. It is written as an open
specification: every rule below was measured on the retail PC data and is enforced by a reference
implementation (`mercs2_audio` in the `wad_simulator` workspace: `wave.rs`, `soundbank.rs`,
`multitrack.rs`, `sounddb.rs`, `select.rs`, `duration.rs`, `automation.rs`, `playback.rs`,
`encode.rs`) whose test re-encodes **every** audio table in
retail `vz.wad` (95 wavebanks, 76 soundbanks, 77 sounddbs, multi-track cues included) byte-identically
from its parsed fields (`crates/mercs2_audio/tests/retail_banks.rs`). The engine behaviour it states —
how a cue's tracks fire their sounds, how groups and entries are picked, and how a playing cue's
volume and pitch are computed — is read from the decompiled PC exe, with the generator, the
automation evaluator and the instance-start draws also disassembled from the unpacked image; the functions are
named where each rule is given. The same layout holds, measured with a separate
checker, for every audio table in `English.wad` and `shell.wad`.

The key words **MUST** and **MUST NOT** are normative: a table that breaks one was not produced by the
retail toolchain, and the reference reader rejects it. Field names marked *unknown* are fields whose
meaning is not established; a writer carries them as given (e.g. copied from a retail bank), it does
not invent them. Names marked *(inferred)* are read off the values the field holds, not off engine
code.

### 11.1 Conventions and packaging

- All integers are little-endian; `f32` is IEEE-754 single precision, little-endian. `u8x4` is four
  single bytes.
- `m2(s)` is `pandemic_hash_m2`: FNV-1a over the bytes of `s` with each byte OR'd with `0x20`, then
  one more round on `0x2A`.
- Every table begins with the `u32` **table version `0x1D`** followed by the `u32` **bank hash**.
- A table is the body of the single `data` descriptor of a UCFX container. The container MUST be
  exactly `UCFX | data_area_off = 40 | 0 | 0 | 1 descriptor {"data", 0, len, 0, 0} | body | "CSUM" |
  crc` (the shape `mercs2_formats::ucfx::build_wrapped_block` produces); every retail audio container
  is this shape byte for byte.
- A bank named `N` ships its three tables as three entries of **one block**, each with name hash
  `m2(N)` and type hash `0x9F8BCA10` (soundbank, ASET type 21), `0xE5273C14` (sounddb, ASET type 13)
  and `0xF753F6D0` (wavebank, ASET type 6); the block-entry `+0x08` word is 0. In `vz.wad` every
  soundbank has its sounddb beside it; one soundbank (`0xDCCF8AFA`, in `sound_resident`) plays waves
  from other blocks' wavebanks and has no wavebank of its own; 19 blocks hold a lone wavebank and one
  (`mercs2globals`) the lone global sounddb. The bank hash inside each table is `m2(N)`. In
  `English.wad` the block-entry name hash differs from the table's bank hash — e.g. the `vo_mattias`
  entries are named `m2("vo_mattias.english")` while their tables carry `m2("vo_mattias")`.

### 11.2 Resolving a cue

`Sound.CueSound(name)` resolves as follows (instance start `FUN_00834ad0`; FindCue `FUN_00835a70`;
cue lookup `FUN_0082e820`; group lookup `FUN_0082e7d0`):

1. **sounddb** — binary-search the entry whose guid is `m2(name)`; it names a soundbank hash and a
   **cue index in that soundbank**.
2. **soundbank cue** — `cue = bank + [bank+0x18] + [bank + [bank+0x1C] + 4·index]`; its guid MUST
   equal the entry's.
3. **sounds** — a single-track cue plays its one group at once. A multi-track cue (§11.7) starts every
   track; each track fires each of its sounds once the track's elapsed time reaches the sound's start
   time, and each fired sound picks one of its weighted entries `{soundbank, u16 group index}`
   (§11.8).
4. **group** — `group = bank + [bank+0x10] + [bank + [bank+0x14] + 4·index]`; the sound instance picks
   one of its waves (§11.8): `{wavebank hash, u16 wave index}`.
5. **wavebank** — the record at the wave index holds the samples.

Over the 1,198 per-bank sounddb entries of `vz.wad`, following every track, every entry and every
wave, with every `vz.wad` bank resident: **1,012** cues resolve to embedded PCM on every path (628 of
them multi-track; 843 reach a multi-wave group). **177** reach a wave streamed from `music.pws` or
`ambience.pws`. **9** reach a wavebank `vz.wad` does not hold — `0x0843A8DC` (7 cues) and
`0x421680B7` = `m2("vo_stream")` (2 cues), both in `English.wad`; with its wavebanks resident the 7
resolve and the 2 reach `vo_stream.pws`, for 1,019 resolved. No entry fails on a bad index, a guid
mismatch, an empty choice list or an unknown selection mode.

### 11.3 sounddb

```
offset  type  field
0x00    u32   version = 0x1D
0x04    u32   bank hash
0x08    u16   C = cue entry count
0x0A    u16   K = category entry count
0x0C    u32   P = parameter count
0x10    u32   cue table offset       = 0x1C
0x14    u32   category table offset  = 0x1C + 12·C
0x18    u32   parameter table offset = 0x1C + 12·C + 8·K
0x1C          cue table:       C × { u32 cue guid, u32 soundbank hash, u32 soundbank cue index }
              category table:  K × { u32 category hash, u32 parent category hash (0 = root) }
              parameter table: P × u32 parameter-name hash
```

- The body length MUST be `0x1C + 12·C + 8·K + 4·P`; the three offsets MUST be the values above.
- Cue entries MUST be strictly ascending by guid (the engine binary-searches them, `FUN_0083c570`).
  Category entries are strictly ascending by hash in the one table that has them.
- The third cue-entry field is an index into the **soundbank's cue table**, not into a wavebank.
- A **per-bank** sounddb (76 in `vz.wad`) has `K = P = 0` and exactly one entry per cue of the
  same-named soundbank: `C` equals the soundbank's cue count, each cue index appears once, and each
  entry's guid equals the guid of the soundbank cue it indexes.
- `FUN_00835b80` loads the global table: `+0x0A` category count, categories at `[+0x14]` (8 bytes
  each), `+0x0C` parameter count.
- The **global** sounddb (`m2("mercs2globals")` = `0x37750257`, 188 bytes) has `C = 0`, the 19-entry
  category tree (`K = 19`) and `P = 2` (`0xD11ADEF6`, `0xD913464B`, the two uncracked global
  parameters of §7). The tree, as `category → parent`, with names where the hash is cracked:
  `0x6413FB86` (root, uncracked) ← `sfx`, `music`, `vo`; `sfx` ← `ui`, `non_ui`; `non_ui` ←
  `Non_Action_Hijack`, `0xD40AD42A`; `Non_Action_Hijack` ← `explosion`, `vehicle`, `collision`,
  `foley`, `ambience`, `weapon`, `0x888456AD`, `0xA2007430`; `music` ← `source`, `0x9FE0DCAD`;
  `vo` ← `chatter`.

### 11.4 soundbank

```
offset  type  field
0x00    u32   version = 0x1D
0x04    u32   bank hash
0x08    u16   G = group count
0x0A    u16   Q = cue count
0x0C    u32   bank hash (repeated)
0x10    u32   group section start = 0x20
0x14    u32   group-offset table position
0x18    u32   cue section start
0x1C    u32   cue-offset table position
0x20          group section: the G groups, back to back
              group-offset table: G × u32, each group's offset relative to 0x20
              cue section: the Q cues, back to back
              cue-offset table: Q × u32, each cue's offset relative to the cue section start
```

- The sections MUST be contiguous with no padding: the group-offset table starts where the last group
  ends, the cue section where that table ends, the cue-offset table where the last cue ends, and the
  body ends at the end of the cue-offset table. Group offsets start at 0 and each is the previous one
  plus the previous group's size; likewise for cues. A cue's size is the distance to the next cue
  (the last cue's, to the cue-offset table).
- `G ≥ 1` and `Q ≥ 1` in every retail bank; the layout of an empty bank is not measured.

**Group** — every group starts with this head:

```
0x00  u32  sound id (unknown; equals the guid of the cue that plays it in some banks, not others)
0x04  u32  category hash = m2(category name), one of the global category tree's (§11.3)
0x08  u32  0
0x0C  u32  form: 0 = single-wave, 1 = multi-wave
0x10  f32  unknown
0x14  u32  unknown, 0 or 1
0x18  f32  minimum distance (inferred)
0x1C  f32  maximum distance (inferred)
0x20  f32  unknown (1.0 in all but one retail group)
0x24  f32  pitch (inferred)
0x28  f32  unknown
```

Single-wave form (form 0, 64 bytes; 344 in `vz.wad`):

```
0x2C  f32  base volume of the sound instance (FUN_0083d770)
0x30  f32  base pitch of the sound instance, semitones (FUN_0083d700)
0x34  wave { u32 wavebank hash, u32 wave index, f32 weight = 1.0 }
```

Multi-wave form (form 1, `0x68 + 12·W` bytes; 1,432 in `vz.wad`):

```
0x2C  u8   loop count, copied to the sound instance at +0x80 (FUN_008369e0); retail's cue lengths
           are −1 exactly where it is non-zero (§11.4, cue length)
0x2D  u8   W = wave count
0x2E  u8   selection mode (§11.8): 0 sequential, 1 weighted random, 2 weighted random, no repeat
0x2F  u8   unknown
0x30  f32  unknown          0x34  f32  unknown
0x38  u32  0x2C — the engine reads wave i at group + [group+0x38] + 0x3C + 12·i
0x3C  f32  start delay a    0x40  f32  start delay b: the instance's start delay is drawn in
           [max(a − b, 0), b + a] (FUN_0083d7e0)
0x44  u32  0 — when its low byte is set, FUN_008369e0 delays the start by the listener distance
0x48  u32  unknown flag bytes
0x4C  f32  unknown
0x50  f32  base volume low   0x54  f32  base volume high: drawn in [low, high] (FUN_0083d770)
0x58  f32  unknown
0x5C  f32  base pitch low    0x60  f32  base pitch high, semitones: drawn in [low, high] (FUN_0083d700)
0x64  f32  unknown
0x68  W × wave { u32 wavebank hash, u16 wave index, u16 0, f32 weight }
```

A group's waves may live in another bank's wavebank. `FUN_008369e0` refuses (plays nothing for) the
groups whose sound id is `0xEA1343AA`, `0xC05D8686` or `0xBB8AE67D` unless the Pal global at `+0x78`
holds `0xB6A13123`, the value `FUN_006067b0` sets in its default case (the switch reads
`*DAT_01176018`; its other cases set `0x8AAAF243`, `0x8A8C7573`, `0xE687CC7D`, `0xC2197ABB`).

**Cue** — every cue starts with this head:

```
0x00  u32   cue guid = m2(cue name)
0x04  u8x4  [0, form, limit, 0]; form 0 = single-track, 1 = multi-track. FUN_00834ad0 starts the
            cue only while a u16 counter in the cue's runtime record (+4) is below `limit`, or when
            `limit` is 0 (that the counter counts live instances is inferred)
0x08  f32   gain (FUN_00835060 multiplies the cue's volume by it each frame)
0x0C  f32   length in seconds, or −1 when the cue loops
```

Single-track form (form 0, exactly 24 bytes; 505 in `vz.wad`):

```
0x10  u32  soundbank hash (the cue's own bank in every retail cue)
0x14  u16  group index
0x16  u16  unknown (0 in most cues; in others it holds values shaped like the high half of an f32)
```

Multi-track form (form 1; 693 in `vz.wad`, 800 across the three archives): specified in §11.7.

**Cue length.** The engine never computes `+0x0C`; it reads it in one place, `FUN_005faca0` (FindCue,
then `movss xmm0, [cue+0x0C]`; 0 when the cue is missing), whose two callers are the
`Sound.GetMaxDuration` binding (`0x005E3860`, returns it to Lua) and the VO line start `FUN_00515c10`
(`0x00515C50`, where a length ≤ 0 is replaced by 5.0 s, `DAT_00B9B700`). Nothing in the mixer, the
instance update or the bank loader reads it. It is authored data, and the retail banks carry it by
this rule, measured over every cue of `vz.wad` and `English.wad`:

- **−1.0** when anything the cue plays loops: a multi-wave group it can reach with a non-zero `+0x2C`
  loop count, a track with a non-zero `+0x00` loop count, or a multi-track cue `+0x10` loop count
  (§11.7).
- otherwise the latest end among the cue's sounds — `start + the longest wave any of its groups can
  pick`, computed in double precision — and its ramps and LFOs (automation kinds 0–3,
  `start + duration` in single precision), rounded to `f32`.

A wave's length is `frames / rate` for an embedded record and `+0x10 / (rate × channels × 2)` for a
streamed one, whose `+0x10` counts decoded PCM16 bytes rather than frames (§11.5). The rule gives
14,818 of the 14,834 lengths bit for bit. The 16 it does not, all in `vz.wad`, as (soundbank, cue
index): `0x0873D14E` 55, `0x08E43A91` 2, `0x5EE5CB98` 4, `0x766467E0` 0, `0x874E66BC` 5,
`0xAF27F8D2` 10, `0xB796AE64` 22 / 25 / 65 / 66, `0xDCCF8AFA` 6 / 7 / 45, `0xEB61D6E1` 8 / 9,
`0xF2175845` 59 — nine far from any end of the cue (hand-set or stale), six one unit in the last place
off, and one −1 on a cue with nothing looping. A writer SHOULD compute the length by the rule; the
reference encoder does, and takes no length as input.

### 11.5 wavebank

```
offset  type  field
0x00    u32   version = 0x1D (not a record count)
0x04    u32   bank hash
0x08    u16   R = record count (≥ 1 in every retail bank)
0x0A    u16   bank kind: 0 = embedded, 1 = streamed
0x0C    u32   bank hash (repeated)
0x10    u32   record table offset: 24 (embedded) or 40 (streamed)
0x14    u32   0
0x18    16 B  streamed banks only: the .pws file name, ASCII, NUL-padded (≥ 1 NUL)
              record table: R × 36-byte records
              embedded banks only: the blob area
```

Record (36 bytes):

```
0x00  u32   clip hash
0x04  u8x4  [0, channels (1 or 2), format, 0]; format = 2 (bytes per sample, PCM16) when
            embedded, 4 when streamed
0x08  u32   sample rate
0x0C  u32   data size in bytes
0x10  u32   frame count (samples per channel)
0x14  8 B   0
0x1C  u32   0 when embedded; unknown when streamed (non-zero in some records)
0x20  u32   data offset: when embedded, RELATIVE TO THIS RECORD'S OWN START; when streamed, the
            byte offset in the .pws file
```

Embedded banks (93 in `vz.wad`, 2,043 clips):

- The payload is interleaved little-endian PCM16: `size = frames × channels × 2` MUST hold.
- Blobs MUST follow the record table in record order. Each blob starts at the first 16-byte boundary
  (of the body) at or after the end of the previous blob — for the first, at or after the end of the
  record table. The body MUST end at the first 16-byte boundary at or after the end of the last
  blob. All bytes between and after blobs MUST be zero. This is why 54 of the 93 embedded banks end
  2–14 bytes past their last blob.
- Reading the offset relative to the body start instead lands every offset inside the record table;
  relative to the record, all 2,043 blobs land exactly where the alignment rule puts them.

Streamed banks (2 in `vz.wad`: `music` → `music.pws`, `ambience` → `ambience.pws`; `English.wad`'s
`vo_stream` → `vo_stream.pws`) carry no blob area: the body ends at the end of the record table, and
each record's `(offset, size)` addresses the `.pws` file.

### 11.6 Writing a bank

A writer producing a new bank of single-track, single-wave cues (the reference encoder's shape; the
shape of retail `ui_PDA_Open_01_st`, cue 57 → group 70 of `ui_hud`):

1. For cue `i` with name `n`, PCM16 audio `(channels, rate, samples)` and category `c`: write wave
   record `i` (embedded, format 2, `frames = samples / channels`), group `i` (single-wave, category
   `m2(c)`, its wave `{m2(N), i, weight}`), and cue `i` (single-track, guid `m2(n)`,
   `{m2(N), group i}`, length per §11.4).
2. Write one sounddb entry `{m2(n), m2(N), i}` per cue, sorted ascending by guid; reject two cue
   names that hash alike.
3. Lay out each table exactly as §11.3–§11.5 require, and wrap each per §11.1.
4. Fields marked *unknown* or *(inferred)* are inputs. `ui_PDA_Open_01_st`'s values, for a UI sound
   configured like the game's own: group `+0x10` 0.95 (`0x3F733333`), `+0x14` 0, distances 10 / 1000,
   `+0x20` 1.0, pitch 1.0, `+0x28` 1.0, gain `0x3F21866C` (≈ 0.631), `+0x30` 0.0, weight 1.0; cue
   `+0x06` 0, gain `0x3F004DCE` (≈ 0.501), `+0x16` 0; sound id and clip hash both `m2(cue name)`.

A writer MAY also author multi-wave groups (the multi-wave form, a selection mode 0–2, at least one
wave) and multi-track cues (§11.7: every sound's slot below the cue's slot count, at least one entry,
a selection mode 0–2). Every cue's length follows §11.4's rule, which needs the waves each group can
pick, so the reference encoder requires a cue's groups and their waves to be in the bank it writes.

### 11.7 Multi-track cue body

Every offset is relative to the cue's start; the engine reads the structure in place
(`FUN_0083bf70`, `FUN_0083fc40`, `FUN_0083fee0`, `FUN_0083b310`).

```
0x10  u8   loop count (copied to the instance at +0x15D; see §11.9)
0x11  u8   A = event record count
0x12  u8   T = track count
0x13  u8   P = parameter hash count
0x14  u8   C = cue curve record count
0x15  u8   S = selection-state slots (FUN_0082e370 allocates S u32s per cue, set to 0xFFFFFFFF)
0x16  u16  0
0x18  f32  play probability: FUN_008354e0 draws r once (§11.8) and plays the cue only if this ≥ r
0x1C  f32  loop start       0x20  f32  loop end (§11.9)
0x24  f32  unknown (FUN_00834ad0 loads it into the cue's runtime timer on each start)
0x28  u32  event records (= 0x44)          0x2C  u32  event offset table
0x30  u32  track records                   0x34  u32  track offset table
0x38  u32  parameter hashes
0x3C  u32  cue curve records               0x40  u32  cue curve offset table
0x44       event records | event offsets | curve records | curve offsets | tracks | track offsets
           | parameter hashes — contiguous, in that order; the cue ends after the hashes
```

Each "records + offset table" pair holds its records back to back; the table gives each record's
offset relative to the first record.

**Track** (offsets relative to the track):

```
0x00  u8   loop count (copied to the track instance at +0xD5; see §11.9)
0x01  u8   automation record count      0x02  u8  sound count      0x03  u8  0
0x04  f32  loop start                    0x08  f32 loop end
0x0C  u32  automation records (= 0x1C)   0x10  u32 automation offset table
0x14  u32  sound records                 0x18  u32 sound offset table; the track ends after it
```

**Sound:**

```
0x00  u8   selection-state slot (< S)
0x01  u8   unknown      0x02  u8  unknown
0x03  u8   selection mode (§11.8); FUN_0083fee0 picks nothing for a value other than 0, 1, 2
0x04  u8   entry count  0x05  3 × u8 0
0x08  f32  start time: FUN_0083fee0 fires the sound once the track's elapsed time reaches it
0x0C  u32  entry list offset (= 0x10)
0x10       entries: { u32 soundbank hash, u16 group index, u16 0, f32 weight }
```

**Automation records** (event, cue-curve and track tables alike; interpreted by the track update
`FUN_0083b4a0`): a `u32` kind, then —

```
kind 0 / 1  volume / pitch ramp:  f32 start, u32 mode, u32 unknown, f32 duration, f32 from, f32 to
            (mode 0 applies to the running value — volume multiplied, pitch added; non-zero
            overrides the sound instances' base value)
kind 2 / 3  volume / pitch LFO:   f32 start, u32 mode, u32 unknown, f32 duration, f32 period, f32 depth
            (low byte of mode 0 = oscillate)
kind 5 / 6  volume / pitch curve over a parameter, and kind 8 (the cue curve table's only kind):
            u32 unknown, u32 point count n, u32 parameter hash, u32 points offset (= 0x14),
            n × { f32 x, f32 y }
kind 4      17 × u32: six multipliers for the instance parameter channels 2–7, clamped and
            optionally jittered with the generator (FUN_0083f8e0)
kind 7      u32 unknown, u32 cue hash: the child cue the track starts when it finishes
            (FUN_0083c070 → FUN_0082e930)
kind 9      u32 unknown, u32 parameter hash or 0xFFFFFFFF, u32 parameter hash or 0xFFFFFFFF:
            evaluates kind 8 curves into the track fields +0x68 / +0x6C / +0x74 (kind 10 likewise)
```

How each kind is evaluated is in §11.9.

A reader MUST reject any other kind, or a record whose size its kind does not admit.

### 11.8 Picking a wave or an entry

A multi-wave group picks its wave with its `+0x2E` mode (`FUN_0083d410`); a multi-track sound picks
its entry with its `+0x03` mode (`FUN_0083fee0`). Both keep one `u32` of state — per group per loaded
soundbank, and per slot per multi-track cue — initialised to `0xFFFFFFFF`:

- **0 — sequential** (`FUN_0083d540`, `FUN_00840480`): let `b` be the state's low byte; if `b` equals
  the choice count or `0xFF`, set the state to 0 and `b` to 0; add one to the state; pick `b`.
- **1 — weighted random** (`FUN_0083d450`, `FUN_0084039a`): draw `r`; keeping a single-precision sum,
  add each choice's weight in order and pick the first choice whose sum reaches `r` (`r <= sum`); store
  its index in the state. If none does, nothing plays.
- **2 — weighted random, no immediate repeat** (`FUN_0083d5c0`, `FUN_008404f0`): if the state holds a
  previous pick and there is more than one choice, draw `r` and, skipping the previous choice, add
  `(weight + sum) + weight[previous] / (count - 1)` per step, picking the first whose sum reaches `r`;
  otherwise behave as mode 1.

**The generator** (`FUN_00834a80`, disassembled; the same sequence is inlined in the functions above):
one global `u32` state `DAT_00DFCD1C`. A draw advances it twice with `x ← x·0x0019660D + 0x3C6EF35F`;
with `u` the first new state and `x` the second, the draw is
`bits_to_f32((((x & 0xFFFF01FF) | (u >> 16)) >> 9) | 0x3F800000) − 1.0`, a value in `[0, 1)`
(`DAT_00B9B664` = 1.0). Pal init (`FUN_0082e6c0`) seeds the state once from a tick callback (§10 item
7), so picks differ between runs; an implementation that wants reproducible picks takes the seed as
an input.

The order of draws follows the order sounds fire: each fired sound draws for its entry (modes 1 and 2)
and then, as its instance starts, for its group's wave.

### 11.9 Playing a cue

How a started cue turns into sound-instance volumes and pitches, read from the cue update
`FUN_00835060`, the track update `FUN_0083c070`, sound firing `FUN_0083fee0`, the automation evaluator
`FUN_0083b4a0` (with `FUN_0083f7e0` for curves and `FUN_0083f860` for oscillators) and instance start
`FUN_008369e0`. All arithmetic is single precision, in the order given. The reference implementation is
`automation.rs` and `playback.rs`; `tests/retail_banks.rs` plays every resolvable retail cue through it.

**Instance start.** A fired sound picks its entry, then its group's wave (§11.8), then draws, in this
order: base pitch (`FUN_0083d700`: a multi-wave group draws `r·(hi − lo) + lo` over `+0x5C`/`+0x60`,
a single-wave group takes `+0x30`), base volume (`FUN_0083d770`: `+0x50`/`+0x54`, or `+0x2C`), start
delay (`FUN_0083d7e0`: always draws; a multi-wave group's range is `[max(+0x3C − +0x40, 0),
+0x40 + +0x3C]`, a single-wave group's is 0).

**Per frame** (elapsed `dt`), for a multi-track cue:

1. The cue's volume is `clamp01(cue +0x08 gain × V)` and its pitch `P`, where `V`, `P` are the
   cue-automation outputs of the **previous** frame (the update reads them before evaluating), 1.0 and
   0.0 at start.
2. The cue time advances by `dt`. While the cue's loop count is non-zero and its time reaches the loop
   end `+0x20`, the time wraps to `+0x1C + overshoot` and the count drops by one unless it is `0xFF`.
   The cue's event table is evaluated at the cue time.
3. Each track in order: its time advances by `dt`, wrapping at `+0x08` to `+0x04 + overshoot` by the
   same loop-count rule; its automation is evaluated at the track time; its volume parameter is
   `track volume × cue volume` and its pitch parameter `track pitch + cue pitch`; every sound from the
   next unfired one whose start time is ≤ the track time fires; every live instance of the track then
   takes the parameters.
4. A sound instance plays at volume `base volume × volume parameter` and pitch `base pitch + pitch
   parameter` semitones. While a ramp with a non-zero mode is active, its override value replaces the
   base volume or pitch; the cue's override wins over the track's.

A single-track cue starts its one instance on its first frame, with volume parameter
`clamp01(cue gain)` and pitch parameter 0.

**Automation evaluation** (one record list — a track's automation table or the cue's event table —
against that list's time `t`): start from volume 1.0 and pitch 0.0, then

1. apply every **active** record in activation order. A ramp adds
   `(to − from) / ((duration + start) − start) × (t − start) + from` to the pitch or multiplies it into
   the volume, and stays active for ever (it extrapolates past both ends); after a volume ramp the
   volume is clamped to `[0, 1]`. An LFO yields `sine[trunc((t − start) × (1/period) × (8192/2π) × 2π
   + 0.5) & 0x1FFF] × depth + 1.0` (1.0 when the low byte of its mode is non-zero), multiplied into the
   volume or added to the pitch, and leaves the list once `t ≥ duration + start`. A curve applies its
   value at the parameter's current value;
2. **activate** records from the first not yet activated to the end of the list, each whose start
   (its `+0x04` word) is below `t`, applying each at once (a volume curve then clamps the volume); the
   next activation resumes after the last one activated, so an earlier record still waiting is passed
   over for good.

A curve yields `y₀` for `x ≤ x₀`, otherwise interpolates on the first segment with `xᵢ < x ≤ xᵢ₊₁`;
past the last point `FUN_0083f7e0` reads the word after the record's points, outside the curve. Its
parameter is the cue's own (the `P` hashes at `+0x38`) or, if not one of them, the Pal global
parameter table, whose missing entries read −1.0 (`DAT_00DFDB5C`).

The sine table `DAT_00CE8F08` holds 8,192 `f32`: entry `i` is `sin(x / 8192)` with `x` the
single-precision product `f32(2π) × i`, the division and sine in double precision, rounded to `f32` —
except entry 4096, which holds `0xB3BBBD4D` (the
single-precision `sin(π)`); its FNV-1a-64 over the little-endian bytes is `0x63421FAD6B050CCA`.

**Pitch to rate.** A voice at pitch `p` semitones plays its wave at `trunc(2^(q / 4096) × rate)` with
`q = (i16) trunc(p × (1/24) × 8192)` clamped to `±0x2000` (a quarter or four times the rate at the
clamps).

**What the reference implementation refuses.** It plays kinds 0–3, 5 and 6 as above. A cue that
carries kind 4, 7, 8 (reached through 9 / 10) or 9, that loops (any loop count non-zero), whose curve
parameter has no value, or whose parameter lies past a curve's last point is refused when it is
started. Over the 1,198 `vz.wad` cues with every `vz.wad` bank resident: 707 play; 2 are refused for
kind 4, 1 for kind 9, 278 for a group loop count, 22 for a track loop count, 2 for a cue loop count;
the other 186 do not resolve (§11.2).

## Provenance

All addresses PC retail, base 0x400000. Anchors are (a) Pal self-named profiler-scope strings —
high; (b) master-tick call-site position + Xbox pipeline order match — high for the umbrellas; (c)
m2 name-hash constants in-body — high; (d) `image.bin` vtable/disasm reads for gap bodies — marked
per-row. Xbox oracle: [../mercs2-pdb-analysis/audio-pal.md](../mercs2-pdb-analysis/audio-pal.md).
