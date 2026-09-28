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
| `FUN_00835a70` | `PalGlobalTable::FindCue` | cue resolve over the loaded sounddbs, first loaded first (§11.2); per table, by its cue count `[body+0x08]` (`0x00835AE3` `cmp word [esi+8], 0x400` / `jbe`): ≤ 0x400 entries → binary search `FUN_0083c610`, more → the hash index `FUN_0083c760` (0xffff-sentinel), which the parser builds only for a table of more than 0x400 entries (`FUN_0083c670`) |
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
  [channels + 2·format]); kernels `FUN_00839f20/fd0`, `FUN_0083a200/510/790`. `FUN_0083ade0` is the
  source mix object's prepare (vtable `0x00BE23CC` slot `+0x08`): it zeroes the source scratch
  `DAT_00FC34B0` (frames × 0x18 bytes, six int32 per frame) and sets the source's six channel gains —
  1.0 for a 2D source, `FUN_0083d090` for an emitter source (§11.9, *The mix path*).

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
| `CueSound` | `FUN_005e0ff0` | posts `{0, object, 4, 0, f32 DAT_00DFDB5C, cue hash, 0}` → `0x00446340` (game message queue) | handler reaches the cue start through the object's emitter record (§11.9, *Cues on objects*) |
| `TestCueSound` | `FUN_005e0db0` | same message as `CueSound` | one argument (the cue name); the object is the local player's attached character (`FUN_006cd960(0)` → `FUN_006cdaf0` → `+0x20`), nothing posted without one (§11.9, *Cues on objects*) |
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
3. **SecuROM-thunked hot paths** — confirm-live: `LoadBank`
   `*_DAT_0244fb2c`, `OpenStreamFile` `thunk_FUN_035f0000`, `VO.Cue` `thunk_FUN_028da000`, ambience
   update `thunk_FUN_024f2850`, audio-enabled gate `thunk_FUN_024e67b0`.
4. **8 uncracked m2 hashes** (§7) — add to the rainbow table (candidates: interior, underwater,
   danger, camera-distance).
5. Wave-object construction/format-bind site (candidates `FUN_0083ab00/ab60/ac00/ac40`, unread) and
   the `DAT_0198db60` kernel table's format axis (PCM8/PCM16/ADPCM?).
6. **Bank-table unknowns (§11).** The fields marked *unknown* in §11.4 and §11.7 (the multi-wave
   group's `+0x2F`, `+0x30`, `+0x34`, `+0x48`, `+0x4C`, `+0x58`, `+0x64`; a multi-track sound's
   `+0x01`, `+0x02`; the `u32` marked *unknown* in automation kinds 0–3, 5, 6 and 8) and the streamed wave record's `+0x1C` have no established meaning. The group
   `+0x20`, the single-track cue `+0x16` and the wave record `+0x00` are marked *no reader known*:
   no engine code in a bounded search range reads them (§11.4, §11.5). Kind 10 is handled by `FUN_0083b4a0` but no
   retail cue carries one, so its size is unmeasured. The §3.5 row for `FUN_00835b80` ("u16 counts
   @+0xA/+0xC, 8-byte GUID entries @+0x14") describes the parser's reads of the *global* sounddb
   (category count at `+0x0A`, parameter count at `+0x0C`, category table offset at `+0x14`), not the
   per-bank cue table of §11.3.

   **SecuROM splices, resolved statically.** A splice replaces an instruction or two of a `.text`
   function with `jmp [slot]` into a stub that enters the protection's VM (`0x01AAFF10` →
   `[0x021FD554]` = `0x02A30000`); the VM runs the stolen instructions — through `.text` gadgets —
   and returns to the next `.text` address, where the function carries on in plain code. Emulating
   the runtime memory dump (`mercenaries-one-source/_ghidra/_ghidra/securom_dump/image.bin`,
   `file offset = VA − 0x400000`, which holds the VM decrypted) with Unicorn from the spliced
   instruction to its return address, with sentinel values in registers and memory, shows what the
   stolen instructions did:

   | Splice | Stolen instruction(s) | What follows in `.text` |
   | --- | --- | --- |
   | `0x00839E96` (`FUN_00839e90`, wave data end) via `0x0244F65C` | `mov edx, [eax+0x110]` — the wave's `GetLoopCount` slot (`0x0099C6C0`: `mov eax, [ecx+0xBC]`) | the loop (§11.9, *Looping waves*) |
   | `0x00838856` (`MixWavesToOutput`) via `0x02455DA8` | `mov ecx, [0x01176404]` (the profiler) | the source mix (§11.9, *The cue filter*) |
   | `0x0082E960` (`thunk_FUN_024b9220`, the Pal cue start) via `0x0244F728` | `mov ecx, [0x01176400]` (the instance pool) | allocation, `FUN_00834ad0`, list append |
   | `0x0040B360` (the Pal-init tick callback) via `0x0245E984` | relocated code at `0x00415A20` that calls `[0x00B05124]` = `KERNEL32!QueryPerformanceCounter` and returns the 64-bit count in `EDX:EAX` | — |
   | `0x00446340` (the game message post, `thunk_FUN_024b65e0`) via `0x024552AC` | `cmp byte [0x0122DDA0], 0` | the queue append at `0x00446347` (§11.9, *Cues on objects*) |
   | `0x006035F0` (`thunk_FUN_024e6ae0`) via `0x0245DE9C` | none: registers and stack unchanged | the emitter record find/create at `0x0047ADC0` |
   | `0x00603EF0` via `0x0245EEB8` | none: registers and stack unchanged | the object-sound start at `0x00593BA0` |
   | `0x00603D3B` (in `FUN_00603d20`) via `0x0244FDD4` | an obfuscated load of `ebp` (`0x00582736`), which the body uses as the Pal engine (`[ebp+0x50]`, the cue-instance list) | the record's cue walk at `0x00603D41` |

   **`Sound.CueSound`'s start, resolved.** Its message is handled by `FUN_005fd760` case 0, which
   queues a cue command that `PgSoundPlayer::Update` runs through the object's emitter record to
   `0x00593BA0` (§11.9, *Cues on objects*). `0x00593BA0` passes `(its argument 2 == 5)` for the
   instance flag `+0x83` (the start's 8th argument) and 0 for `+0x82`; its argument 2 is the command's
   `+0x0C`, the message's `+0x08`, which the `CueSound` shim sets to 4 (`0x005E10B5`). So
   `Sound.CueSound` starts its cue with `+0x82` = `+0x83` = 0, as children and the music decks do.
   (`+0x83` matters only on a stereo or surround device for a group whose `+0x14` byte is 0: it then
   replaces the instance's output-channel multipliers with 0.7 / 0.7 / 0 / 0 / 0 / 0, `FUN_00836c70`,
   from `0x0083741D`.)
7. **Sound generator seed (§11.8).** Pal init stores the low 32 bits of the tick callback
   `0x0040B360`, which is `QueryPerformanceCounter` (item 6), as the generator seed.
8. **Object emitters (§11.9, *Cues on objects*).** Which objects the sound object table
   `DAT_01175FAC` (`+0x10` entries of `0x94` bytes, `+0x14` count, entry `+0x88` position) holds is
   not pinned down: `FUN_006036c0` moves a record's emitter only while its object is in it, and no
   writer of the table was found statically. The reference implementation moves every emitter whose
   object is live in the world, and treats an object that is not as one gone from the table. What
   happens to a gone object's cues is traced and modelled (§11.9, *A vanished object*).

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
meaning is not established; fields marked *no reader known* are fields no engine code in a bounded
search range reads, and the range is named beside each. A writer carries both as its author gives
them. Names marked *(inferred)* are read off the values the
field holds, not off engine code. The retail counts quoted for the fields an author declares are
asserted by the census tests of `crates/mercs2_audio/tests/retail_fields.rs` (`retail` feature),
named where each count is given.

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

1. **sounddb** — find the entry whose guid is `m2(name)` in the loaded sounddbs, in the order below;
   it names a soundbank hash and a **cue index in that soundbank**.
2. **soundbank cue** — `cue = bank + [bank+0x18] + [bank + [bank+0x1C] + 4·index]`; its guid MUST
   equal the entry's.
3. **sounds** — a single-track cue plays its one group at once. A multi-track cue (§11.7) starts every
   track; each track fires each of its sounds once the track's elapsed time reaches the sound's start
   time, and each fired sound picks one of its weighted entries `{soundbank, u16 group index}`
   (§11.8).
4. **group** — `group = bank + [bank+0x10] + [bank + [bank+0x14] + 4·index]`; the sound instance picks
   one of its waves (§11.8): `{wavebank hash, u16 wave index}`.
5. **wavebank** — the record at the wave index holds the samples.

**Routing order (PROVEN).** The loaded sounddbs are one list on the Pal global table
`E = [0x011763FC]`: the parser `FUN_00835b80` is called at `0x00607DB8` with `EDI = E + 8`
(`8B 3D FC 63 17 01` at `0x00607D18`, `83 C7 08` at `0x00607DB5`), and FindCue receives the same
`E + 8` at all three call sites (`0x005FACB7`, `0x00593BAA`, and `FUN_00834ad0`, decomp 627028).

- **Load appends at the tail.** The parser links the new table's node after the current tail (decomp
  627793–627800: `next` = the list sentinel `E+8+0x18`, `prev` = the old tail `[E+8+0x1C]`; the old
  tail's `next` and `[E+8+0x1C]` become the new node; the count at `+0x24` goes up by one). Neither
  it nor `FUN_0083c670` checks for a guid another table already has. Unload (`FUN_00835da0`) removes
  a node by its table pointer.
- **FindCue walks from the head.** `FUN_00835a70` (decomp 627666–627685) starts at `*(E+8+0x18)`,
  follows `next`, and stops at the first table whose search hits. The search is chosen per table by
  its cue count `[body+0x08]` (`0x00835AE3`, `66 81 7E 08 00 04` `cmp word [esi+8], 0x400`, then
  `jbe`): a table of at most 0x400 entries is binary-searched (`FUN_0083c610`), a larger one is
  looked up in the hash index `FUN_0083c670` built for it at load (`FUN_0083c760`). The guid, in
  `EDI`, is compared only with table entries.
- So **for a guid two loaded tables both route, the table loaded first answers**; the later one's
  cue never plays.
- The soundbank list at `E + 0x30` (`FUN_0082e820`, `FUN_0082e7d0`, `FUN_0082f960`) and the wavebank
  list at `E + 0x40` (`FUN_0082e870`) are searched the same way, first match wins; the soundbank
  loader `FUN_0082f5e0` → `FUN_0082e370` appends at the tail with no duplicate check (decomp
  622196–622202).

A bank is loaded through the Pg bank manager `[0x01175F9C]` (65 slots). `LoadSoundBank(name)`
requests exactly `(name, 0x9F8BCA10)` and `(name, 0xE5273C14)` — the soundbank and the sounddb of
the same name (`0x00602768`–`0x006027A1`, PROVEN); `LoadWaveBank(name)` requests only the wavebank.
The sounddb reaches FindCue through its type handler (`FUN_00602ff0` → `0x006024E0`, relocated to
`0x005FE100`), which appends it to `[0x01175FAC]+0x190`, the list `FUN_00607c50` passes to
`FUN_00835b80`. Loading a bank that is loaded (slot state 3, flag 1) only registers the callback:
no second request, no second Pal node, no error; the callback fires on the next update (PROVEN by
emulating `0x006026C0`), with no success flag. A name no mounted WAD holds leaves its slot in state
1 until a 20.0 timeout releases it; the callback then fires with no failure indication, and nothing
is logged (PROVEN at the Pg layer; the timeout's unit is not resolved).

Census (`cue_guids_across_sounddbs`): cue guids are unique within each archive's per-bank sounddbs
(`vz.wad` 1,198, `English.wad` 13,636, `shell.wad` 270). All 270 `shell.wad` guids are also in
`vz.wad`, from the three banks both carry (`music` 158, `ui_hud` 88, `ui_shell` 24), and all 10
`shell.wad` audio tables are byte-identical to `vz.wad`'s.

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
0x00  u32  sound id: the language gate below reads it (FUN_008369e0); no other reader known
0x04  u32  category hash = m2(category name), one of the global category tree's (§11.3)
0x08  u32  0
0x0C  u32  form: 0 = single-wave, 1 = multi-wave
0x10  f32  priority: voice stealing (below)
0x14  u32  0 or 1: 1 = positional — with an emitter its instances play from the emitter's own source,
           otherwise from the shared 2D source (FUN_00837830, 0x008378A9). The sounddb record has no
           such flag (§11.3)
0x18  f32  minimum distance: full volume up to it (FUN_0083d3a0)
0x1C  f32  maximum distance: silent from it (FUN_0083d3a0)
0x20  f32  no reader known (below); 1.0 in all but one retail group
0x24  f32  distance fall-off exponent (FUN_0083d3a0)
0x28  f32  Doppler scale (FUN_0083b120)
```

`+0x14`..`+0x2B` are the wave's 3D parameters: for an instance whose emitter source is 3D (holder
`+0x98` = 2), `FUN_00837830` (`0x00837C08`) passes `group + 0x14` to the wave's vtable `+0x60`
(`0x00838F70`), which copies the 24 bytes to wave `+0x5C`; otherwise it passes 24 zero bytes (§11.9,
*Emitter sources*).

**`+0x00` sound id.** The one known reader is `FUN_008369e0` at `0x00836A27`–`0x00836A45`
(`8B 00`, then `cmp eax` with `0xEA1343AA`, `0xC05D8686`, `0xBB8AE67D`, then
`cmp [edi+0x78], 0xB6A13123`): for a group with one of those three ids it clears the instance's
group pointer — nothing plays — unless the Pal language hash at `+0x78` is `m2("english")` (the
language gate, PROVEN; the hash is set by `FUN_006067b0`, below). No other reader: every `+0x34`
dereference in the Pal code `0x0082A000`–`0x00842000` reads the group at `+0x0C`, `+0x10`, `+0x14`,
`+0x2C` or above, never `+0x00` (INFERRED, bounded search). Census
(`group_sound_id_against_the_playing_cue_guids`) — the id equals the guid of a cue that plays the
group / differs from every such guid / no cue of the bank plays the group: `vz.wad` 411 / 1,278 /
87, `English.wad` 12,893 / 740 / 3, `shell.wad` 131 / 145 / 14. The gated ids sit at
(`language_gated_sound_ids`): `0xEA1343AA` in `vz.wad` bank `0xB796AE64` group 17 (played by cue
`0xEA1343AA`); `0xC05D8686` in `vz.wad` `0xEB61D6E1` group 13 (cue `0xD051A52F`) and `English.wad`
`0x50787BFF` group 142 (cue `0x23DCD31E`); `0xBB8AE67D` in `ui_hud` (`0xDD4573C5`) group 100, in
`vz.wad` and `shell.wad`, played by no cue.

**`+0x10` priority (PROVEN).** `PalSoundInstance::GetWavePriority` (`FUN_00837e10`, named by its
profiler string) returns it times the wave's distance volume (`0x00837EDC` `8B 46 34`,
`0x00837EDF` `F3 0F 10 40 10` `movss xmm0, [eax+0x10]`, then `mulss` by `FUN_00837f00` for a 3D
source, 1.0 otherwise), and 0.0 for an instance with no group. `FUN_00837830` computes a new
instance's priority the same way (`0x00837950`); when the wave pool (`[0x01176400]+0x4C`) is
exhausted it finds the lowest-priority playing instance (`FUN_0082f990`, "GetLowestPrioritySound")
and steals its voice (`FUN_00837c50`, "StealWave") only if the new priority is higher
(`0x00837A0C` `comiss` / `jbe 0x00837B15`); otherwise no wave is created. The value is also passed
to the wave's vtable `+0x15C` (decomp 629141). Census (`group_priority_values`): `vz.wad` 15 values
(0.0 ×2, 0.3 ×281, 0.4 ×141, 0.5 ×84, 0.6 ×108, 0.75 ×12, 0.828 ×1, 0.85 ×545, 0.9 ×40, 0.95 ×176,
0.955 ×56, 0.96 ×140, 0.97 ×37, 0.98 ×1, 1.0 ×152); `English.wad` 0.0 ×11, 0.2 ×3, 0.7 ×7,532,
0.9 ×2, 0.98 ×6,088; `shell.wad` 0.9 ×36, 0.95 ×102, 1.0 ×152.

**`+0x20`: no reader known (INFERRED, bounded to the Pal region).** `FUN_00837830` copies group
`+0x14`..`+0x2B` into the wave (vtable `+0x60`, `0x00838F70`), which puts `+0x20` at wave `+0x68`.
The only reader of wave `+0x68` is the getter `0x00838F30` (`D9 41 68` `fld [ecx+0x68]`) at vtable
slot `+0x44` of both wave vtables (`0x00BE2240`, `0x00BE24D0`); nothing references the getter but
the vtables, and there is no `call [reg+0x44]` in `0x00828000`–`0x00842000`. Census
(`group_word_20_values`): 1.0 in every group but `vz.wad` bank `0xF2175845` group 105, which holds
`0x3FFFFCB9` (≈ 1.9999).

**The language hash.** `FUN_006067b0` (decomp 266015–266030) sets the Pal language hash from
`*DAT_01176018`: 0 → english `0xB6A13123`, 1 → spanish `0x8AAAF243`, 2 → italian `0x8A8C7573`,
3 → french `0xE687CC7D`, 4 → german `0xC2197ABB`, any other index → english.

Single-wave form (form 0, 64 bytes; 344 in `vz.wad`):

```
0x2C  f32  base volume of the sound instance (FUN_0083d770)
0x30  f32  base pitch of the sound instance, semitones (FUN_0083d700)
0x34  wave { u32 wavebank hash, u32 wave index, f32 weight = 1.0, not read on the pick path (below) }
```

Multi-wave form (form 1, `0x68 + 12·W` bytes; 1,432 in `vz.wad`):

```
0x2C  u8   wave loop count, copied to the sound instance at +0x80 (FUN_008369e0) and on to the
           wave at +0xBC (FUN_00837830): the wave plays 1 + count times (§11.9). Retail's cue
           lengths are −1 exactly where it is non-zero (§11.4, cue length)
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
holds `0xB6A13123` (`m2("english")`), the value `FUN_006067b0` sets for index 0 and in its default
case (*The language hash*, above).

A single-wave group's weight (`+0x3C`) is not read when its wave is picked: for form 0
`FUN_0083d410` returns the wave at `+0x34` directly (decomp 633049–633051), and only the multi-wave
pickers `FUN_0083d450` / `FUN_0083d5c0`, reached for form 1, read weights; `FUN_008369e0` copies
only the wave's `[ref]` and `u16 [ref+4]` (`0x00836A68`, `0x00836A6D`) (PROVEN on the pick path;
that nothing else reads it is INFERRED). It is 1.0 in every retail single-wave group
(`single_wave_group_weight_is_one`: `vz.wad` 344, `English.wad` 12,181, `shell.wad` 161).

**Cue** — every cue starts with this head:

```
0x00  u32   cue guid = m2(cue name)
0x04  u8x4  [0, form, limit, 0]; form 0 = single-track, 1 = multi-track. +0x06 `limit` is the
            start limit: the cue starts only while fewer than `limit` instances of it are playing,
            or when `limit` is 0 (below)
0x08  f32   gain (FUN_00835060 multiplies the cue's volume by it each frame)
0x0C  f32   length in seconds, or −1 when the cue loops
```

Single-track form (form 0, exactly 24 bytes; 505 in `vz.wad`):

```
0x10  u32  soundbank hash (the cue's own bank in every retail cue)
0x14  u16  group index
0x16  u16  no reader known (below); 0 in most cues, otherwise one value per bank shaped like the
           high half of an f32
```

**Cue `+0x06`, the start limit (PROVEN).** `FUN_00834ad0` (decomp 627053–627066) takes the cue's
runtime record — `soundbank node[8] + cue index × 0x18` on the first loaded node with the bank's hash
(`FUN_0082f960`) — and starts the cue only if the record's `f32` timer (`record[0]`) is ≤ 0 and
either the limit is 0 or the `u16` counter at `record + 4` is below it. The counter counts live
playing instances: `FUN_008354e0` adds one when an instance plays (decomp 627406, 627456) and
`FUN_00835850` takes one away when it finishes (decomp 627565). When the play-probability draw
drops a multi-track cue (§11.7 `+0x18`), `FUN_008354e0` calls `FUN_00835850`, which takes one away
with no matching add (decomp 627426–627430). The timer is set at start from the multi-track cue's
`+0x24` (§11.7); a single-track cue sets it from a zeroed default (`DAT_0198DAEC`). Census
(`cue_start_limit_values`): `vz.wad` 0 ×920, 1 ×9, 2 ×47, 3 ×30, 4 ×30, 5 ×125, 7 ×4, 10 ×23,
15 ×2, 20 ×8; `English.wad` 0 ×13,634, 1 ×2; `shell.wad` 0 ×265, 1 ×3, 2 ×2.

**Single-track `+0x16`: no reader known (INFERRED).** `FUN_0083be80` returns `cue + 0x10` (the
`{bank, u16 group, u16 +0x16}` reference); `FUN_008369e0` stores it at instance `+0x28`
(`0x00836A05`) and passes it to `FUN_0082e7d0` / `FUN_0083d410`, which read only `[ref+0]` and the
`u16 [ref+4]`. The only accesses to instance `+0x28` outside the vtables are that write and a clear
at `0x00836BEE`. Census (`single_track_cue_word_16_values`): within a bank the non-zero value is one
value (37 banks in `vz.wad`, 41 in `English.wad`); `vz.wad` 0 ×378 and `0x3D75`, `0x3DA3`,
`0x3DB8`, `0x3DCC`, `0x3E99`, `0x3EB6`, `0x3ECC`, `0x3F19`, `0x3F33`, `0x3F80`, `0x3F81`;
`English.wad` 0 ×11,985, `0x036E` ×1,627; `shell.wad` 0 ×187.

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
0x00  u32   clip hash: no reader known (below)
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

**Record `+0x00`: no reader known (INFERRED).** `FUN_0082e790` computes a record's address (stride
0x24) after matching the bank hash at wavebank `+0x04` (`FUN_0082e870`); `FUN_00837830` reads the
record at `+0x05`, `+0x06`, `+0x08`, `+0x0C`, `+0x14`, `+0x18`, `+0x1C` and `+0x20`, not `+0x00`
(`0x00837883`–`0x0083789F`, `0x00837AB7`–`0x00837AF4`); the wave init at `0x0083DAE0` stores the
record pointer at wave `+0x14`, and no wave method reads it as data. Census
(`wave_clip_hash_against_sound_id_and_cue_guid`, single-wave groups whose wavebank is in the same
archive) — clip = the group's sound id / ≠ / clip = the guid of a cue that plays the group / ≠ /
wavebanks repeating a clip hash: `vz.wad` 142 / 198 / 47 / 273 / 0, `English.wad` 11,472 / 709 /
12,174 / 7 / 0, `shell.wad` 75 / 86 / 33 / 119 / 0.

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
each record's `(offset, size)` addresses the `.pws` file. `FUN_0082e8f0` returns the `+0x18` name
and `FUN_00837830` passes it to the stream interface `[0x011763F4]` (`0x00837A8B`–`0x00837AAF`); a
null result fails the wave's creation. The name is the alias `Sound.OpenStreamFile(path, alias)`
registers (INFERRED): retail Lua opens `<audio dir>\vo_stream.<language>.pws` under the alias
`vo_stream.pws` (`_OpenFile`, `mrxsoundbanks.lua:96-107`). Census (`streamed_wavebank_names`):
`vz.wad` `music` → `music.pws`, `ambience` → `ambience.pws`; `English.wad` `vo_stream` →
`vo_stream.pws`; `shell.wad` `music` → `music.pws`.

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
4. Every other field is an input the author declares, with no default: group `+0x00` sound id,
   `+0x10` priority, `+0x14` positional, `+0x18` / `+0x1C` distances, `+0x20` (no reader known),
   `+0x24` exponent, `+0x28` Doppler scale, `+0x2C` base volume, `+0x30` base pitch; cue `+0x06`
   start limit, `+0x08` gain, single-track `+0x16` (no reader known); wave record `+0x00` clip hash
   (no reader known). The derived fields are the category hash (`m2(c)`), group `+0x08` = 0, the
   forms, the wave reference (weight 1.0, which the engine does not read for a single-wave group),
   the cue's `{bank, group}`, the cue length, the record's audio fields and the sounddb.

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
0x24  f32  retrigger cooldown: FUN_00834ad0 loads it into the cue's runtime timer on each start,
           FUN_0082e310 (from the cue walk FUN_0082ee60, decomp 622094–622108) subtracts the frame
           time each frame, and the cue cannot start again while the timer is above 0 (§11.4,
           start limit; PROVEN from the decomp, seconds INFERRED)
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
kind 4      f32 start, 6 × u8 jitter flags (+0x08..+0x0D), u16 0, 6 × f32 jitter offsets
            (+0x10..+0x24), 2 × u32 not read by the engine (+0x28, +0x2C), 6 × f32 base multipliers
            (+0x30..+0x44): the six output-channel multipliers (FUN_0083f8e0, §11.9)
kind 7      f32 start, u32 child cue guid: the cue the track (or, in the event table, the cue) starts
            when it finishes or is stopped (FUN_0083c070, FUN_00835060, FUN_0083c470 → FUN_0082e930)
kind 9      f32 start, u32 curve index, u32 curve index (each the low byte of an index into the cue
            curve table, or 0xFFFFFFFF for none): evaluates those kind-8 curves into +0x68 / +0x6C of
            the automation state — for the event table, cue +0x84 / +0x88 (kind 10: one index, into
            +0x74 / cue +0x90)
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
(`DAT_00B9B664` = 1.0). Pal init (`FUN_0082e6c0`) seeds the state once with the low 32 bits of
`QueryPerformanceCounter` (§10 item 7), so picks differ between runs; an implementation that wants
reproducible picks takes the seed as an input.

The rest of the game runs the same generator, inlined, over a different state: **`DAT_00DFCBAC`**, the
game's global random state (176 stores in the runtime dump; the emitter jitter of §11.9 is one of its
users). No store that seeds it was found. Its value before the game draws is `0x94153A94`: the dumps
taken before runtime init (`mercs2_nodrm_v2.exe`, `mercs2_nodrm_v3.exe`, whose `DAT_011763FC` is
still 0) hold it there, and `image.bin` holds it in `DAT_00DFCD1C` and `DAT_00DFCBB8`; `image.bin`'s
`DAT_00DFCBAC`, `0xD36E7EE6`, is it stepped 514 times (257 draws).

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

**Blocks.** A cue passes its tracks, and a track its instances, a block of eight floats: a volume, a
pitch in semitones and six output-channel multipliers.

**Per frame** (elapsed `dt`), for a multi-track cue (`FUN_00835060`):

1. The cue block is `{clamp01(cue +0x08 gain × V), P, C}`, where `V`, `P`, `C` are the cue
   automation's outputs of the **previous** frame (the update reads them before evaluating), 1.0,
   0.0 and 1.0 at start.
2. If the cue's loop count (`+0x15D`, from `+0x10`) is non-zero and `time + dt ≥` its loop end
   (`+0x20`): the event table's automation rewinds to the loop start (`+0x1C`); every track runs a
   **loop restart** against the cue's loop points with the cue's raw previous-frame automation block
   (no gain, no clamp) and `loop end − time`; the time becomes `loop start + ((time + dt) − loop end)`,
   which is also the `dt` the tracks advance by this frame; the count drops by one unless it is `0xFF`.
   Otherwise the time advances by `dt`.
3. The event table is evaluated at the cue time.
4. Each track advances (below). When every track is done, a cue whose loop count was non-zero at the
   start of the frame waits for its loop; otherwise it starts the child cue a kind-7 event named and
   waits for it (state 3), or is done.

**A track** (`FUN_0083c070`), with the cue block and the cue's override: if its loop count (`+0xD5`,
from track `+0x00`) is non-zero and `time + dt ≥` its loop end (`+0x08`), it runs a loop restart
against its own loop points with `{cue volume × previous track volume, cue pitch + previous track
pitch, cue channels}` and `loop end − time`, then takes `loop start + ((dt + time) − loop end)` as its
time and its `dt`, and drops the count unless it is `0xFF`; otherwise its time advances by `dt`. Its
automation is evaluated at the track time, and its sounds fire and update with
`{track volume × cue volume, track pitch + cue pitch, track channels × cue channels}`. When its
sounds are done and its loop count was 0 at the start of the frame, it starts the child cue a kind-7
record named and waits for it (state 3), or is done. The update runs for every track that has been
played, done ones included (a done track keeps its time and automation running).

**A loop restart** (`FUN_0083c3c0`): the track's sounds fire up to the loop end and its instances
update with the given block and time; its automation rewinds to the loop start (`FUN_0083bdb0`:
the active list empties and activation resumes at the first record whose start is at or after the
loop start — unchanged if there is none); its sounds rewind (`FUN_00840230`: firing resumes at the
first sound whose start is at or after the loop start, **except that a match on sound 0 does not end
the search** — when sound 1 matches too, firing resumes at sound 1 and sound 0 does not fire again);
the track is playing again.

**Sounds** (`FUN_0083fee0`): while the list is firing, every sound from the next unfired one whose
start is at or before the time fires (entry pick, then `FUN_00840280` → instance start). Then every
instance that finished on an earlier update is dropped, and every other one takes the override block
if there is one and is updated. The list is *fired* once everything has fired and no instance is
left, and *done* on the next update that finds no instance.

**An instance** (`FUN_00836c70`) multiplies its six channel multipliers (`+0x48`..`+0x5C`, 1.0 at
start) by the block's — the product is stored, so a multiplier persists — and plays at volume
`base volume × block volume` and pitch `base pitch + block pitch`. Its multipliers go to the wave's
output channels 0–5 (wave vtable `+0x10C`, `FUN_008391d0`), which the mix kernels
(`FUN_0083e970`, …) apply to the interleaved output channels in order; on a stereo buffer channel 0
is left and 1 is right. An override block — a ramp with a non-zero mode, the cue's if active, else the
track's — replaces the base volume and pitch and resets the multipliers to 1.0 (the override block's
channel slots are never written). An instance is finished once its wave is (`CheckFinished`), or when
no wave can be created for it.

A single-track cue (`FUN_0083bec0`) starts its one instance on its first frame and updates it with
`{clamp01(cue gain), 0, 1.0 × 6}`; it is done on the update after its instance finishes.

**Child cues** (kind 7). A child start (`FUN_0082e930`) that fails — the cue is not in the sound
database, or its soundbank is not loaded — or whose play-probability draw drops it runs the parent's
completion callback at once (a track: done, child −1, `LAB_0083c550`; a cue: done, `LAB_008359a0`,
after which `FUN_00835060` still sets it to wait for the child). A child that plays calls the callback
when it finishes. A cue started during the cue-list walk (`FUN_0082ee60`) is appended and advances in
the same frame.

**Stopping** (`FUN_00835720`): every track's loop count becomes 0, its instances stop with a fade and
its sounds stop firing, and it starts the child cue its kind-7 record named (or stops the running
one); the cue does the same with its own child; the cue then waits (state 3) until its tracks and
children are done.

**Kind 4** (`FUN_0083f8e0`), when it activates, sets the automation's six output-channel multipliers
for that step only (every step starts them at 1.0; kind 4 never joins the active list). Record
channel `k` (flag byte `+0x08 + k`, offset `+0x10 + 4k`, base `+0x30 + 4k`) goes to output channel
0, 1, 4, 2, 3, 5 for `k` = 0…5, and the engine fills the outputs in order 0–5, drawing once for each
record channel whose flag is 1: `((r − 0.5) × 2 + offset) + base`, else `base`; each is clamped to
`[0, 1]`. **Kind 7**, when it activates, stores its child cue guid (`+0x7C`), which a rewind keeps.

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

**Looping waves** (`FUN_00839e90`, reached from the mix kernels when the read position reaches the
end of the data). It reads the wave's loop count (`+0xBC`, from the group's `+0x2C` via instance
`+0x80`). If it is 0, an embedded wave (whose `+0x18`, read by vtable `+0x128`, is 0) stops
(`+0x120` = 0, `+0x124` = the length, vtable `+0x24`); otherwise the integer read position `+0x124`
drops by the data length — playback resumes at the start with the overshoot kept — vtable `+0xB4` is
called with 4, and, the count being positive, it is set to count − 1
(vtable `+0x114`, `0x00839230`). The count is the byte zero-extended, so `0xFF` is 255 and plays 256
times. For a retail embedded wave the length is the whole clip (wave `+0xC4` stays −1 because the
record's `+0x18` is 0, so `FUN_00838e10` returns `+0x48`, the data size). An instance whose wave
cannot be created stays alive to try again when its group's count is `0xFF`, and finishes otherwise
(`FUN_00836c70`).

**The final volume** of an instance — base volume × block volume × the engine's master fade ×
its category's volume — is clamped to `[0, 1]` (`0x008373AA`..`0x008373D5`) before the wave's
`SetVolume` (vtable `+0x104`, `0x008373E4`).

**The mix path** (`MixSources`, `FUN_00836610`). `PrepareMix` zeroes the int32 accumulator; the
emitter sources (engine `+0x1B0` list) mix, then the 2D source for waves of up to two channels
(`+0x1AC`), then the 2D source for wider ones (`+0x1A8`); `FUN_0083cbf0` saturates the accumulator
to int16. The stream buffer is always six-channel 16-bit PCM, channel mask `0x3F` (`FUN_0083f760`);
a source is created with channel byte `+0x39` = 6 and its rate at `+0x3C` (`0x0083AD40`). Per
source (mix object vtable `0x00BE23CC`): `FUN_0083ade0` prepares (above); `MixWavesToOutput`
(`FUN_00838850`) calls slot `+0x14`, `FUN_0083b120`, for each wave in the order the source holds them,
which calls the wave's mix (`FUN_00839ae0`, wave vtable `+0x58`) with the frame count, the scratch,
the channel byte and the rate; slot `+0x10`, `FUN_0083afc0`, then commits:
`acc = trunc((f32) scratch × gain[c] + (f32) acc)`. In the wave mix, `FUN_0083e1d0` sets
`m = d × ((w[+0xAC] × w[+0xA4]) × w[+0xA0])` (doubled when byte `+0xF5` is set),
`master = clamp(m, 0, 2)` and `gain[c] = clamp(ch[c] × m, 0, 2)`, `d` the volume the instance set and
`ch` its output-channel multipliers. `+0xA4` and `+0xA0` are 1.0 and `+0xF5` is 0 for every retail
wave (the setters at wave slots `+0xCC` / `+0xD4` are not called from the audio code — INFERRED from
the call sites, not observed live); `+0xAC` is the distance volume, which only a positional wave
changes from 1.0 (*Emitter sources*, below). The kernels take `trunc(g × 32768)`. A
wave whose integer master is 19 or less only advances (`FUN_0083a440`: position += step × frames,
then the loop wrap). Otherwise the kernel steps a 32.32 read position by
`step = (freq << 32) / rate` (integer division; `freq` = `trunc((f32) frequency × w[+0xA8])`, the
frequency getter `FUN_0083e170` on the x87 stack with the rounding control set to chop; `+0xA8` is
the Doppler factor, 1.0 in 2D), mixes chunks of `min(((len << 32) − pos) / step, frames left)` (at least 1)
frames of the sample at the integer position — no interpolation — and at `pos ≥ len` calls
`FUN_00839e90` (looping waves, above). A mono wave adds `(s × g[c]) >> 15` to all six channels
(`FUN_0083e970`); a stereo wave (`FUN_0083eb00`) adds left to channels 0/2/4 and right to 1/3/5,
with two shortcuts: both of the first two gains ≥ `0xFFEC` add `s × 2` to channels 0 and 1 only, both
≥ `0x14` add `(s × g) >> 15` to channels 0 and 1 only.

**Emitter sources.** An emitter's source holder carries its position (`+0x2C`) and velocity
(`+0x5C`). `MixWavesToOutput` computes its distance to listener 0 as
`sqrt((dz² + dy²) + dx²)` (`d` = listener − emitter) and passes it, per wave, to `FUN_0083b120`;
before that, the source's prepare `FUN_0083ade0` (slot `+0x08`) does two things for a 3D source
(`+0x18` = 2):

- **Speaker gains** (`FUN_0083d090`, `edi` = source `+0x1C`): with `dx`, `dz` the horizontal offset
  from listener 0, `dist = sqrt(dz² + dx²)`, `u = (dx/dist, 0 × (1/dist), dz/dist)` (zero at
  `dist == 0`) and `prox = 1 − dist / R` when `R > dist` (else 0), each of five speaker directions
  — `(0.7, 0, 0.7)`, `(−0.7, 0, 0.7)`, `(0.7, 0, −0.7)`, `(−0.7, 0, −0.7)`, `(−0, 0, 1)`
  (`0x019C67A0`, from `DAT_00DFDDD8` / `DAT_00BEB45C` / `DAT_00BEAA2C`) — goes through
  `D3DXVec3TransformNormal` with listener 0's matrix (`d3dx9_36.dll`; its SSE2 path, `0x0074F5FE`,
  computes `(y·row1 + x·row0) + z·row2` in single precision) to `t`, and its gain is
  `clamp01(clamp01((t.z·u.z + t.x·u.x) + u.y·t.y) + prox)`. `R` is engine `+0x1D8` (`0x019C6348`),
  copied at init (`FUN_00835fd0`) from the descriptor `FUN_006067b0` builds with `DAT_00DF6804` —
  1.0 in the shipped image; a command-line option (hash `0x21C3DCBE`, `FUN_004c2c20`) can replace
  it. The commit applies `+0x1C`, `+0x20`, `+0x2C`, `+0x30`, `+0x24`, `+0x28` to channels 0–5, so the
  five gains feed front left, front right, back left, back right and centre (channels 0, 1, 4, 5, 2);
  LFE (`+0x30`) keeps the source constructor's 0.0 (`0x00834471`; only the 2D prepare writes 1.0).
- **Doppler** (source `+0x34`): with `u` the unit vector from listener 0 to the emitter
  (`dist = sqrt((dx² + dz²) + dy²)`), `1 − ((Δv.x·u.x + Δv.y·u.y) + Δv.z·u.z) × DAT_00BEB460`
  (`0x3B3FA030`, ≈ 1/342), `Δv` = emitter velocity − listener 0's velocity (`0x019C61D0`).

The mix reads listener slot 0 directly (`0x019C61C0` position, `0x019C61D0` velocity, the matrix at
`0x019C6190`), not the closest listener. `FUN_0083b120` hands each wave `1 + (D − 1) × w[+0x70]` when
the wave's Doppler scale `+0x70` (group `+0x28`) is positive, else 1.0 — computed on the x87 stack —
and `FUN_00839ae0` clamps it to `[0.1, 2.0]` (`DAT_00B92B58`, `DAT_00B92874`) into `+0xA8` (vtable
`+0xE4`). A wave whose `+0x5C` is set first takes its distance volume from `FUN_0083d3a0`: 1.0 while
`dist ≤ +0x60`, 0.0 once `dist ≥ +0x64`, else `1 − (f32) pow((f64) ((dist − min) / (max − min)),
(f64) +0x6C)`, stored at `+0xAC` (vtable `+0xEC`, `0x00839120`, which also flags a change larger than
`DAT_00B92958`). 2D sources pass Doppler 1.0 and their waves' `+0x5C` is 0.

**Cues on objects.** `Sound.CueSound(object, cue)` (shim `FUN_005e0ff0`) posts a 0x1C-byte message
`{0, object, 4, 0, f32 DAT_00DFDB5C, cue hash, 0}` to the game message queue (`0x00446340`: up to
0x80 records at `0x0122CF20` with a subscriber bitmask per record at `0x0122DD20`). `PgSound`'s
`CollisionHandling` (`FUN_005fd5f0`) drains it (`FUN_0058c7c0`) into `FUN_005fd760`, whose case 0
drops the cue hash `0xBA71C11C` and whatever `FUN_005fd5b0` refuses, then queues a 0x28-byte cue command
in `DAT_01175FAC`'s list (`FUN_00607510`, mode 0) that carries the object's position: the vector is
zeroed (`0x00607530`..`0x0060756F`) and, for a non-zero object not already marked in the table's
`+0x08` list, filled by `FUN_00665af0` (the object's position; left zero when the lookup fails).
`PgSoundPlayer::Update` runs the command (`FUN_00607610` case 0 → `FUN_006033c0`):

1. **Find or create the object's emitter record** (`FUN_006035f0` → `0x0047ADC0`) in the player's
   record list (`PgSoundPlayer::Update`'s second argument; `FUN_006034b0` walks the same list). A new
   record comes from the free list at `DAT_01175FA4 +0x14` and is appended; for a non-zero object,
   `FUN_00603b30` asks the Pal engine (`DAT_019C6170`) for a source holder (vtable `+0x0C`) at record `+0x14`
   and sets its position to the command's (`+0x14`, `0x00838310`) and its velocity to
   `DAT_011766F0`..`DAT_011766F8` (zero; `+0x10`, `0x00838330`).
2. **Start the cue on it** (`FUN_00603c10` → `FUN_00603ef0` → `0x00593BA0`): find the cue
   (`FUN_00835a70`) and start it (`FUN_0082e960`) with the emitter `record[0] ? record[+0x14] : 0`
   — object 0 plays 2D — then link the cue into the record's cue list (record `+0x04`, count `+0x10`).

`Sound.TestCueSound(cue)` (shim `FUN_005e0db0`) takes one argument, the cue name (`FUN_0059fa40`,
hashed by `FUN_00824270` at `0x005E0DFB`), and finds the object itself: `FUN_006cd960(0)`
(`0x005E0E04`) gives the player index `+0x2C` of the first joined (`+0x30` ≠ −1), local (`+0x58` = 0)
player record, `FUN_006cdaf0` (`0x005E0E0A`) that player, and its `+0x20` (`0x005E0E16`) is the
attached character guid (`player_code_map.md`) — the lookup `Player.GetLocalCharacter()` makes with
no argument (`0x005DE1F2`..`0x005DE21F`). With no player or no character (`0x005E0E14` /
`0x005E0E1B`) nothing is posted; otherwise the same message as `CueSound` goes out for the
character (`0x005E0E29`..`0x005E0E54`). It returns no value (`xor eax, eax`, `0x005E0E5A`).

**Emitter motion.** Each frame, after the cue commands and before the Pal update
(`FUN_0082ee60`), `FUN_006034b0` calls `FUN_006036c0` for every record in list order, with the frame
time `dt` (`PgSoundPlayer +0x1A8`). It drops the record's cues whose instance is gone or finished
(state 2), then — when the record has an object and a holder and the object is in the sound object
table `DAT_01175FAC` (§10 item 8) — moves the holder:

1. three draws from the game's global random state `DAT_00DFCBAC` (§11.8), `a`, `b`, `c` in draw
   order, make the direction `(c, b, a)` (`0x006038A6`..`0x00603998`), normalised by `FUN_00401630`:
   `len = sqrt((x·x + y·y) + z·z)` (`fsqrt` of the single sum, stored single), `(0, 0, 0)` when
   `len == 0`, else each component × `1 / len`;
2. a fourth draw `d` picks the jitter `s`: `DAT_00BEB524` (`0x3951B717`, +0.0002) when
   `0.5 > d` (`DAT_00BBB99C`), else `DAT_00BEB520` (`0xB951B717`, −0.0002);
3. the new position is the object's table position (entry `+0x88`..`+0x90`) + direction × `s`;
4. the velocity is `(new position − holder +0x2C) × (1 / dt)` in single precision
   (`0x00603A8C`..`0x00603ABD`), or `DAT_011766F0`..`DAT_011766F8` (zero) when `dt` equals
   `DAT_00B9B690` (0.0; an unordered compare computes the difference);
5. `SetPosition` (holder vtable `0x00BE21C4` `+0x14`), then `SetVelocity` (`+0x10`)
   (`0x00603AC3`..`0x00603ADF`).

Every such update takes four draws — eight steps of `DAT_00DFCBAC` — per record, however many cues
the record holds. The engine never reads a physics or object velocity: the holder's finite
difference is the velocity the Doppler factor sees. After the update, `FUN_006034b0` frees a record
whose cue count is 0: the holder goes back to the Pal engine (`DAT_019C6170` vtable `+0x10`) and the
record to the free list.

**A vanished object.** When the record has an object that is not in the table, and its cue list was
not empty before the drop, `FUN_006036c0` ends with `FUN_00603d20(0, 0, 1)` (`0x00603B18`); the
holder is not moved and no draws are taken. `FUN_00603d20(hash, all, forever)` (`ret 0xC`, record in
`eax`) returns at once when the record's count `+0x10` or its first link is 0. A SecuROM splice
follows (`0x00603D3B` via `0x0244FDD4`); emulating it returns to `0x00582736`, which computes
`[0x0245AF28] + [0x01E6CA2C]` = `0x011763FC` and loads `ebp = [0x011763FC]`, the Pal engine, then
jumps to `0x00603D41`. From there it walks the record's cue links in order — a link's `+0x00` is the
cue hash it was started with (`0x00593C39`: `mov [esi], edi`, `edi` the hash `FUN_00835a70` looked
up), `+0x08` the cue instance — and for each:

1. if `forever`, it finds the instance in the Pal cue list (`[ebp+0x50]`, instance `+0x14C` = link
   `+0x08`) and asks `FUN_00835910` (`0x00603DC3`) whether it loops for ever; otherwise, or when not
   found, the answer is no;
2. the link matches when its hash equals `hash` (`0x00603D88`);
3. if `all` is set, the answer is yes or the link matches, it finds the instance again and, when its state
   (`+0x164`) is 0 or 1 (`0x00603DD0`), clears link `+0x05` and stops it with `FUN_00835720(0)`
   (`0x00603E06`, *Stopping* above; `ebp` is reloaded from `[0x011763FC]` after); a matching link then
   ends the walk (`0x00603E11`). A cue not found, or in state 2 or 3, is passed over.

`FUN_00835910` (`ecx` = the cue instance): for a multi-track cue (`+0x15E` bit 2, which
`FUN_00834ad0` sets from the soundbank cue's form byte `+0x05`) it is true when the cue's loop count
`+0x15D` is `0xFF`, or when any of its `+0x15C` tracks (`+0x11C`) has loop count `+0xD5` = `0xFF` or an
instance in its sound list (track `+0x88`, instance list at list `+0x20`, i.e. track `+0xA8`) whose
group loop count `+0x80` is `0xFF`. For a single-track cue it is true only when its instance (`+0x10`)
exists and has `+0x80` = `0xFF` (`0x00835982`; the `+0x15D` result is overwritten). So with
`(0, 0, 1)` a gone object's for-ever-looping cues are stopped — they release, fade and finish — and a
link whose hash is 0 is stopped and ends the walk; every other cue plays on to its end. The links stay
in the record: a stopped cue is dropped by the update that finds it in state 2, and the record is
freed once its last cue has gone.

**The cue filter** (kind 9). A wave whose cue has a kind-9 event carries a biquad low-pass filter
(`FUN_00839db0` → `FUN_0083f2d0`, vtable `0x00BE2678`; cutoff `+0x08` starts at 22,050, resonance
term `+0x0C` at 1.4142, rate `+0x10` at 44,100). `FUN_00839db0` looks for the kind-9 record among
the cue's first *C* events, *C* being the cue's curve count — a cue with more curves than events would
read past its event table. The cue parameter object's two outputs start at 1.0 (`0x008334C0`). On every instance update the wave copies the cue
parameter object at `+0x7C` (vtable `0x00BE1E60`: slot `+0x04` returns `+0x08` / `+0x0C`, i.e. cue
`+0x84` / `+0x88`, the kind-9 outputs) into the filter (`FUN_0083e5c0` → `SetParam`, `0x0083F670`):
cutoff = `nyquist + (100 − nyquist) × −1 × (v − 1)`, resonance term =
`2 + (0.70710677 − 2) × −1 × (v − 1)`. `Process` (`FUN_0083f430`) recomputes, when a value changed,
`k = (f32) tan(cutoff / rate × π)`, `kk = (f32) pow(k, 2)`, `d = (q·k + kk) + 1`, `n = 1/d`,
`b0 = b2 = n·kk`, `b1 = 2·b0`, `a1 = (kk − 1)·n·2`, `a2 = (d − 2·q·k)·n`, and filters int32 samples in
place: `y = trunc((((x₂·b2 + x₁·b1) + x·b0) − y₁·a1) − y₂·a2)`, one history per wave channel,
channel `c` covering `count` samples from `buffer + c·count`. The mix passes it the buffer and count
of the wave's *source*: `MixWavesToOutput` (`FUN_00838850`) hands each wave to its source object,
whose `FUN_0083b120` mixes the wave into the source's int32 scratch `DAT_00FC34B0` (six ints per
frame, zeroed per source by `FUN_0083ade0`) with `count` = frames × the source's channel byte
`+0x39`, and the wave mix then runs the filter over that buffer, before `FUN_0083afc0` adds the
scratch into the accumulator with the source's six channel gains. 2D instances share one source per
channel class (`FUN_0082f110` / `FUN_0082f140`), so the filter runs over every 2D wave mixed before
it in the pass.

**Global parameters.** Every parameter the global catalog declares gets an entry at 0.0 when the
catalog loads (`FUN_00835b80`, entry constructor `0x008335A0`); an undeclared one reads −1.0
(`FUN_0082f170`).

**What the reference implementation plays and refuses.** It plays kinds 0–9 as above through the
mix path above (per-source scratch, the wave kernel, each wave's filter over its source's scratch,
the commit), track and cue loops, and looping waves. It refuses, when the cue is started: a curve
parameter with no value or past a curve's last point, a kind-9 curve index past the curve table, a
cue with more curves than events (the filter scan), and a kind-7 child that would itself be refused.
Its mixer hands the six-channel mix to a device with six or more channels, channels 0 and 1 to a
stereo device and channel 0 to a mono one — a stand-in for DirectSound's fold-down, which is not
modelled — and refuses 3–5 channels. Emitter sources mix as above (speaker gains, distance volume,
Doppler). `Sound.CueSound(object, cue)` plays through the object's emitter record as above, and once
a frame, before its tick, the host moves every record's emitter with its object's world position —
the jitter drawn from one game-wide `DAT_00DFCBAC` state seeded `0x94153A94`, the velocity the finite
difference — so a moving object's cues are Doppler-shifted; an object that is no longer live is
taken as gone from the table (§10 item 8), and its record's cues run through `FUN_00603d20(0, 0, 1)`
as above (the link's `+0x05` byte is not carried). `Sound.TestCueSound(cue)` takes the cue name
alone and plays it on the local player's attached character (*Cues on objects*), starting nothing
when there is none, and returns no value. Over the 1,198 `vz.wad` cues with every `vz.wad` bank resident,
1,012 resolve and **all 1,012 play** (66 loop a track or the cue, 278 reach a looping wave, 4 start a
child cue); the two that carry kind 9 (`0xD8CE1427`, `0xF23B9836`) play with their waves' filters
attached and mix audibly — asserted in `tests/retail_banks.rs` — and the other 186 do not resolve
(§11.2). With `English.wad`'s wavebanks also resident, all 1,019 play.

### 11.10 Where banks are loaded

A bank's tables are read only once Lua loads the bank, and each level WAD runs its own Lua VM, so
where a bank is loaded is a property of the level and the session. The call sites below are the
decompiled corpus's (`crates/mercs2_script/corpus/mercs2-luacd/src`); the corpus scan and the
carrier census are tests in `mercs2_quartermaster` (`the_sound_load_sites_are_the_corpus_calls`,
`the_carried_soundbanks_against_the_retail_load_sites`).

**The front end (`shell.wad`) — PROVEN.** `MrxSound.EnterShellState` (`shell/mrxsound.lua:5-15`)
loads `ui_shell`, `ui_hud` and `music` (soundbank and wavebank each, with one batch callback,
`_StartShellMusic`) after `_LoadRequiredAssetsCommon`. `ExitShellState` (`:17-27`) unloads them.
`EnterShellState` is called from `MrxGuiShell._OpenShell` (`shell/mrxguishell.lua:505`), which runs
when the `Shell` game state is entered (`HandleGameStateChangeEvent`, `:211-221`), requested by
`MrxGuiShellBootstrap.ShellScreenLoaded` (`shell/mrxguishellbootstrap.lua:67-70`). `ExitShellState`
is called from `_CloseShell` (`shell/mrxguishell.lua:589`) and from
`MrxSoundShellBootstrap.ExitShell` (`shell/mrxsoundshellbootstrap.lua:98-100`), which `ShellBootstrap`
runs on the way out of the shell (`shell/shellbootstrap.lua:111-121`). These are the only bank-load
calls among the shell's 28 scripts, and `shell.wad` carries exactly these three soundbanks.

**Gameplay (`vz.wad`) — PROVEN for the call sites.** `MrxSoundBootstrap.LoadBanks`
(`resident/mrxsoundbootstrap.lua:192-246`, from `Init`, `:108`) loads 11 soundbanks by name —
`ambience`, `amb_birds`, `collision_shared`, `destruction_shared`, `fol_shared`, `veh_shared`,
`wpn_shared`, `building_destruct`, `veh_support`, `music`, `ui_hud` — the wavebanks (`amb_shared`
and `vo_stream` wavebank-only; the `building_destruct` soundbank's wavebank is spelled
`bulding_destruct`), and the `vo_*` soundbanks, localized. `ExitGame` (`:188-190`) calls
`UnloadBanks` (`:248-302`); `vz`'s `ResetSingleton` calls `MrxSoundBootstrap.ExitGame()` on the way
out of the game (`vz/xQ!L.lua:612`). Briefings and starters load their `vo_*` banks by name from
data tables through `LoadTempBank` (`resident/mrxbriefing.lua:510`, `resident/mrxstarter.lua:452`;
the tables in `vz/wifbriefingdata.lua`, `vz/wifstarterdata.lua`, `resident/mrxhq.lua:69-76`,
`vz/wifpmcinterior.lua:95`). `vz.wad` carries 76 soundbanks: the 11 above, `ui_shell`, and 64 that no
Lua in the corpus names in a load call. How those 64 are loaded is not traced (UNPROVEN).

**`ui_shell` in `vz.wad` — the call site PROVEN, its reach INFERRED.** `vz.wad` carries `ui_shell`
(`vz.wad#3525`, byte-identical to `shell.wad#35`, [`wad_duplicate_inventory.md`](../fixpack/wad_duplicate_inventory.md))
and, in its resident block, the same `mrxsound.lua` and `mrxguishell.lua` as the shell. Across the
corpus, `EnterShellState` has exactly two callers, `resident/mrxguishell.lua:505` and
`shell/mrxguishell.lua:505`. In `vz`, the `Shell` widget exists only once
`MrxGuiShellBootstrap.EnterShell` / `LoadShell` (`resident/mrxguishellbootstrap.lua:55-83`) loads
its layout; their callers are `GameBootstrap.Start` (`resident/gamebootstrap.lua:58-75`) and
`ClosePrecacheOnLoad` (reached from `LoadPrecache`, which no `vz` or resident script calls).
`GameBootstrap.Init` returns before `Start` when `Sys.FinishedShell()` is true
(`resident/gamebootstrap.lua:43-46`); `Sys.FinishedShell` (`0x005E54C0`) returns
`DAT_01175A72 != 0`, which `FUN_004BC6D0` sets to 1 in its state 1 (decomp 96533) and to 0 in state 8
when `DAT_01175A84 == 1` (decomp 96642); no static write to `DAT_01175A84` is in the decomp. A
vanilla menu-to-game run logs `##@ GameBootstrap - bailing because finished shell`
([`dlc_pc_activation_checklist.md`](../dlc_pc_activation_checklist.md)). No gameplay path calls
`EnterShellState`: the pause menu's quit is `Sys.RequestGameState("unloading")` then
`Net.QuitGame()` (`resident/mrxguipausescreen.lua:403-404`), and the return to the menu is a level
swap to `shell` (`FUN_004C1280`). So `ui_shell` is loaded in the front end; the `vz` level reaches
its own copy of `EnterShellState` only on a boot that enters `vz` with `Sys.FinishedShell()` false
(INFERRED; whether a retail boot does is UNPROVEN).

**The swap.** Only one of `shell.wad` and `vz.wad` is mounted at a time
([`wad_duplicate_inventory.md` §B.5](../fixpack/wad_duplicate_inventory.md)). The script host is
created and closed by the subsystem toggle `FUN_004C0730`
([`scripting_host_binding_code_map.md` §1.5](scripting_host_binding_code_map.md#15-vm-lifetime)),
so each level's Lua state, and any table a loader keeps in it, starts fresh (INFERRED). Whether the
Pg bank manager's slots (`[0x01175F9C]`, 65 slots) survive `FUN_005FAB20` / `FUN_004BF8C0` across
the swap is UNPROVEN. A load of a bank that is loaded only registers the callback (§11.2), so a
loader that loads again after a swap costs nothing.

**No failure report.** `MrxSoundBanks` keeps one batch callback (`_funcBatchComplete`,
`mrxsoundbanks.lua:10-36`): a load or unload given a callback replaces the caller's. Its completion
handler `_FlagAssetOpComplete` takes no argument (`:141-152`), `Sound.LoadBankWithCallback`
(`FUN_005E2BF0`) hands the request to `FUN_006026C0`, and the callback fires with no success flag,
also after the 20.0 timeout of a name no mounted WAD holds (§11.2). Lua cannot tell a failed load
from a loaded one, and no `Sound` binding reports whether a bank is loaded (the 88 entries of the
table at `0x00B98C98`).

## Provenance

All addresses PC retail, base 0x400000. Anchors are (a) Pal self-named profiler-scope strings —
high; (b) master-tick call-site position + Xbox pipeline order match — high for the umbrellas; (c)
m2 name-hash constants in-body — high; (d) `image.bin` vtable/disasm reads for gap bodies — marked
per-row. Xbox oracle: [../mercs2-pdb-analysis/audio-pal.md](../mercs2-pdb-analysis/audio-pal.md).
