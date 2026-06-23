# audio-pal

Audio subsystem of Mercenaries 2: World in Flames — the "Pal" (Pandemic Audio Library) sound/cue/voice engine plus the Pangea (`Pg*`) sound database, music marker/transition logic, sound streaming I/O, and Bink movie audio.

Provenance: all symbols/strings below are recovered from the Jul 11 2008 preview Xbox 360 "Profile" devkit executable `Mercs2_Xenon_P.exe` (PowerPC), decompressed PE at `output/jul08_prototype/mercs2_xenon_p.pe_full.bin`. This is symbol/string evidence, NOT a real `.pdb`. Build source tree was `d:\projects\ReleaseLine\Mercs2\`. Offsets are PE-relative as they appear in the inventory.

## Overview

This subsystem is the game's runtime audio stack. The evidence shows two cooperating layers:

- A low-level **Pal** ("Pandemic Audio Library", read from the `Pal*` prefix and source dir `Pal\src\`) engine that owns the actual mixing, voice management, wave instances, listeners, and the Xenon (Xbox 360 XAudio) backend. This is grounded in the `PalSoundEngineXenon`, `PalSoundXenonVoiceManager`, `PalSoundMixerXenon`, and `PalSoundWaveXenon` symbol families and the `XAudioCreateSourceVoice` import string.
- A higher-level **Pangea** (`Pg*`) audio layer covering the sound database (`PgSoundDb`), music marker/transition state machines (`PgMusicMarkers`, `PgMusicTransitions`), sound stream I/O (`PgSoundStreamIO`), and the Xenon movie player (`PgMoviePlayerXenon`) which drives Bink video/audio.

Above both sits a script/command surface (`CueSound`, `StopSound`, `LoadSoundBank`, `BindMusicCue`, `SetCategoryVolume`, etc.) and an ECS-style runtime component set (`RuntimeSoundEffect`, `RuntimeSoundAmbience`, `RuntimeSoundRuinKey`) that places and updates sounds in the world. Ambient soundscapes are defined by `AmbientEffect*` / `AmbientCube*` parameter blocks.

The update pipeline is named explicitly in the debug-marker strings: `SoundPlayer.Update` → `GroupManager::Update` → message processing (`MsgFilter.ProcessMessages`, `MsgHandler.Update`, `SoundMsgTranslator::Update`) → `SoundAmbience.Update` → `BankMan.Update` → `MusicManager.Update`, with a real-time collection sub-pass (`RtSoundUpdate`, `RtSoundCollect`, `RtSoundEffect`, `RtSoundAmbience`).

## Source files

From `mercs2_xenon_p.source_paths.txt`, verbatim, belonging to this system:

```
d:\projects\ReleaseLine\Mercs2\Pal\src\PalEngine.cpp
d:\projects\ReleaseLine\Mercs2\Pal\src\PalGlobalTable.cpp
d:\projects\ReleaseLine\Mercs2\Pal\src\PalInstanceAllocator.cpp
d:\projects\ReleaseLine\Mercs2\Pal\src\PalLookupTable.cpp
d:\projects\ReleaseLine\Mercs2\Pal\src\PalSoundEventManager.cpp
d:\projects\ReleaseLine\Mercs2\Pal\src\low-level\PalSoundEngine.cpp
d:\projects\ReleaseLine\Mercs2\Pal\src\low-level\PalSoundEngineXenon.cpp
d:\projects\ReleaseLine\Mercs2\Pal\src\low-level\PalSoundXenonVoiceManager.cpp
d:\projects\ReleaseLine\Mercs2\Pangea\Src\PgMusicMarkers.cpp
d:\projects\ReleaseLine\Mercs2\Pangea\Src\PgMusicTransitions.cpp
d:\projects\ReleaseLine\Mercs2\Pangea\Src\PgSoundDb.cpp
d:\projects\ReleaseLine\Mercs2\Pangea\Src\PgSoundStreamIO.cpp
d:\projects\ReleaseLine\Mercs2\Pangea\Src\Xenon\PgMoviePlayerXenon.cpp
```

Two additional Pal headers appear only in the string pool (not in the 48-path source list), referenced by `__FILE__`-style strings:

```
d:\projects\releaseline\mercs2\pal\src\PalQueue.h
d:\projects\releaseline\mercs2\pal\src\PalSoundBank.h
```

## Key classes

None. The RTTI class list (`mercs2_xenon_p.rtti_classes.txt`) contains **no** `Pal*` / `PgSound*` / `PgMusic*` audio classes — the only `Wave`-matching entry is `.?AVhkaWaveletSkeletalAnimation@@` (Havok animation, unrelated). The Pal/Pg audio classes are present as plain `Class::Method` name strings (e.g. `PalSoundInstance::Update`), not as `.?AV` RTTI descriptors, so the runtime did not emit RTTI for them in this build. Class identities below are therefore drawn from those method-name strings rather than RTTI.

Method-name strings imply these C++ classes (from the `Class::Method` form; the class grouping is inferred):
- `PalEngine`, `PalSoundEngine`, `PalSoundEngineXenon`
- `PalGlobalTable`
- `PalSoundInstance`
- `PalSoundMixerXenon`
- `PalSoundWave`, `PalSoundWaveXenon` (one symbol prefixed `rpPalSoundWaveXenon`)
- `PalSoundSource`
- `PalSoundXenonVoiceManager`

## Symbols by area

### Pal low-level engine / mixer / Xenon backend (`.rdata`)
Core audio engine: bank updates, listener selection, and source mixing, with a Xenon-specific (Xbox 360 XAudio) override path.

| Offset | Section | Symbol |
|---|---|---|
| 0x00bf0f4 | .rdata | PalEngine::BankUpdate |
| 0x00bf244 | .rdata | PalSoundEngine::GetClosestListener |
| 0x00bf2f8 | .rdata | PalSoundEngine::MixSources |
| 0x00bf44c | .rdata | PalSoundEngineXenon::MixSources |
| 0x00bf46c | .rdata | PalSoundEngineXenon::UpdateSources |
| 0x00bf490 | .rdata | PalSoundEngineXenon::UpdateListeners |
| 0x00bf760 | .rdata | PalSoundMixerXenon::PrepareMix |
| 0x00bf780 | .rdata | PalSoundMixerXenon::MixWave |

`GetClosestListener` + `UpdateListeners` indicate 3D positional audio with multiple/selectable listeners, relating to `LockListenerPosition` and `_listeners`.

### Cue lookup / global table
| Offset | Section | Symbol |
|---|---|---|
| 0x00bf4c4 | .rdata | PalGlobalTable::FindCue |

Backed by `PalGlobalTable.cpp` and `PalLookupTable.cpp`. Resolves cue identifiers to playable data.

### Sound instances — priority, stealing, lifecycle (`.rdata`)
The per-playing-instance state machine: priority/volume scaling, voice stealing under contention, distance culling, and per-frame update.

| Offset | Section | Symbol |
|---|---|---|
| 0x00bf56a | .rdata | UUUUUUPalSoundInstance::GetWaveVolumeScale |
| 0x00bf598 | .rdata | PalSoundInstance::GetWavePriority |
| 0x00bf5bc | .rdata | PalSoundInstance::StealWave |
| 0x00bf5d8 | .rdata | PalSoundInstance::GetLowestPrioritySound |
| 0x00bf608 | .rdata | PalSoundInstance::CheckFinished |
| 0x00bf628 | .rdata | PalSoundInstance::WaveSubmitValues |
| 0x00bf64c | .rdata | PalSoundInstance::StopCheck |
| 0x00bf668 | .rdata | PalSoundInstance::MaxDistCheck |
| 0x00bf688 | .rdata | PalSoundInstance::CreateWave |
| 0x00bf6a8 | .rdata | PalSoundInstance::WaveUpdate |
| 0x00bf6c8 | .rdata | PalSoundInstance::CalcSubmitValues |
| 0x00bf6ec | .rdata | PalSoundInstance::Update |

(The leading `UUUUUU` on `GetWaveVolumeScale` is a string-extraction artifact / padding in the binary, not part of the C++ name.)

### Wave objects & mix volumes
| Offset | Section | Symbol |
|---|---|---|
| 0x00bf97e | .rdata | rpPalSoundWaveXenon::CalculateVolume |
| 0x00bf9a4 | .rdata | PalSoundWaveXenon::CreateVoice |
| 0x00bf9d8 | .rdata | PalSoundWaveXenon::Update |
| 0x00bfeb0 | .rdata | PalSoundWave::UpdateMixVolumes |
| 0x00bfed0 | .rdata | PalSoundWave::GetMixVolume |

### Sound sources (emitters)
| Offset | Section | Symbol |
|---|---|---|
| 0x00bfa2c | .rdata | PalSoundSource::MixWavesToOutput |
| 0x00bfa50 | .rdata | PalSoundSource::UpdateWaves |
| 0x00bfa6c | .rdata | PalSoundSource::Update |

### Xenon voice manager (XAudio voice pool)
Allocates/recycles hardware voices; `KillOldVoice` implements voice stealing at the backend.

| Offset | Section | Symbol |
|---|---|---|
| 0x00bfd18 | .rdata | PalSoundXenonVoiceManager::CreateVoice |
| 0x00bfd40 | .rdata | PalSoundXenonVoiceManager::DeleteVoice |
| 0x00bfd68 | .rdata | PalSoundXenonVoiceManager::KillOldVoice |
| 0x00bfd90 | .rdata | PalSoundXenonVoiceManager::CreateNewVoice |
| 0x00bfdbc | .rdata | PalSoundXenonVoiceManager::FindExistingVoice |

Confirmed backend = Xbox 360 XAudio via the import string `XAudioCreateSourceVoice` (strings line 15042).

### Script / command surface (`.rdata` constant names)
Names that look like Lua-bindable commands and message-handler tags driving the audio system.

| Offset | Section | Symbol |
|---|---|---|
| 0x002bb54 | .rdata | StopAndFlushAllSounds |
| 0x002bd88 | .rdata | CueAmbience |
| 0x002be30 | .rdata | UnloadSoundBank |
| 0x002be50 | .rdata | LoadSoundBank |
| 0x002c16c | .rdata | PauseSound |
| 0x002c178 | .rdata | StopSound |
| 0x002c184 | .rdata | CueSound |
| 0x002c190 | .rdata | TestPauseSound |
| 0x002c1a0 | .rdata | TestStopSound |
| 0x002c1b0 | .rdata | TestCueSound |
| 0x002d0c0 | .rdata | CueWithoutSubtitles |
| 0x002e3c0 | .rdata | SoundEngine |
| 0x002e3cc | .rdata | SoundCDB |
| 0x002e3e8 | .rdata | PgSoundMessageFilter |
| 0x002e404 | .rdata | PgSoundMessageHandler |
| 0x002e420 | .rdata | PgSoundMessageTranslator |
| 0x00b041c | .rdata | loadSound |
| 0x00b043c | .rdata | attachSound |

`CueWithoutSubtitles` ties cueing to the subtitle/VO system (relates to `SubtitlesEnabled`). The three `Pg*Message*` names indicate a message-bus design (filter → handler → translator) bridging gameplay events to Pal cues.

### Update-pipeline / profiler markers (`.rdata`)
| Offset | Section | Symbol |
|---|---|---|
| 0x002f0e8 | .rdata | SoundPlayer.Update |
| 0x002f174 | .rdata | SoundMsgTranslator::Update |
| 0x002f1bc | .rdata | SoundAmbience.Update |
| 0x002f1d4 | .rdata | RuntimeSoundUpdates |
| 0x002f218 | .rdata | MusicManager.Update |
| 0x002f240 | .rdata | RtSoundUpdate |
| 0x002f250 | .rdata | RtSoundCollect |
| 0x002f260 | .rdata | RtSoundEffect |
| 0x002f298 | .rdata | RtSoundAmbience |

### World/ECS runtime sound components
Enum/type tags and runtime component names for placed sounds.

| Offset | Section | Symbol |
|---|---|---|
| 0x0013b48 | .rdata | SoundResult |
| 0x0013b54 | .rdata | SoundCue |
| 0x0013b60 | .rdata | SoundEvent |
| 0x0031594 | .rdata | SoundRuinKey |
| 0x00315bc | .rdata | SoundEffect |
| 0x00315c8 | .rdata | SoundAmbience |
| 0x00315d8 | .rdata | SoundInterior |
| 0x00315e8 | .rdata | MusicSource |
| 0x00315f4 | .rdata | MusicRegion |
| 0x00318c8 | .rdata | RuntimeSoundRuinKey |
| 0x00318dc | .rdata | RuntimeSoundEffect |
| 0x00318f0 | .rdata | RuntimeSoundAmbience |
| 0x0032570 | .rdata | SoundKey |
| 0x003a2a8 | .rdata | SoundKeyEnum |
| 0x003c4f4 | .rdata | AmbientSound |
| 0x003f6a4 | .rdata | SoundSet |
| 0x003f704 | .rdata | MusicCue |

### Ambient soundscape parameter blocks (`.rdata`)
Indexed parameter fields for up to 5 ambient effects and 6 ambient cubes — clearly a fixed-size designer-tunable block.

| Offset | Section | Symbol |
|---|---|---|
| 0x0026ae0 | .rdata | AmbientSides |
| 0x0026af0 | .rdata | AmbientTop |
| 0x0039e3c | .rdata | AmbientEffectType |
| 0x003bd5c…0x003bf78 | .rdata | AmbientEffect0..4 {Type,Name,Radius,Height,Variance} |
| 0x003c9a8…0x003cab0 | .rdata | AmbientCube0..5, AmbientCube0..5Multiplier, AmbientColor, AmbientColorMultiplier |

(Representative endpoints: `AmbientEffect4Variance` 0x003bd5c, `AmbientEffect0Type` 0x003bf78, `AmbientCube5Multiplier` 0x003c9a8, `AmbientColor` 0x003cab0.)

### Bank / music data section (`.data`)
Named data records / asset-type tags.

| Offset | Section | Symbol |
|---|---|---|
| 0x0b8a564 | .data | SoundBank |
| 0x0b8a570 | .data | WaveBank |
| 0x0b8a57c | .data | SoundDb |
| 0x0b8a584 | .data | MusicMarkers |
| 0x0b8a594 | .data | MusicTransitions |

### Misc
| Offset | Section | Symbol |
|---|---|---|
| 0x002af1c | .rdata | WaveDelay |
| 0x1eb56e6 | .reloc | VoRKj |

`VoRKj` is in `.reloc` and is almost certainly a relocation-table artifact / non-meaningful fragment, not a real audio symbol.

## Notable strings

Bank / music command vocabulary (strings region ~4586–4636), literal text:
`RequestAmbienceBank`, `UnloadBankWithCallback`, `LoadBankWithCallback`, `UnloadTempBank`, `LoadTempBank`, `UnloadWaveBank`, `UnloadSoundBank`, `LoadWaveBank`, `LoadSoundBank`, `UnloadBank`, `LoadBank`, `AddCueToMusicSourcePlaylist`, `RemoveMusicSourcePlaylist`, `ClearMusicSourcePlaylist`, `AddMusicSourcePlaylist`, `AddMusicTransition`, `AddMusicState`, `ActivateFactionRegionMusic`, `SetHijackMusic`, `SetRootFactionRegionMusic`, `SetActionThresholdsMusic`, `SetSourceEnterMusic`, `SetSourceExitMusic`, `SetSourceMusicTransition`, `SetHostilityDecayRateMusic`, `IsActionLevelLockedMusic`, `LockActionLevelMusic`, `SetActionLevelsMusic`, `LockFactionMusic`, `SetFactionMusic`, `AddFactionMusic`, `SetTimerUpdateMusic`, `IsDynamicMusic`, `SetDynamicMusic`, `TransitionMusic`, `ClearMusicCues`, `BindMusicCue`, `LockListenerPosition`, `SetCategoryPitch`, `SetCategoryVolume`.

These show a **dynamic / faction- and action-level-driven music system** (action thresholds, hostility decay, faction/region locking, hijack music) layered on cue playlists and transitions.

Music debug dump (PgMusicMarkers/Transitions region, strings ~5000–5052), literal text:
```
Music Debug:
State timer: %f
Action timer: %f
Min Timer: %f
Current state: %s
Dynamic: %d
PlaybackExecuted: %d
PlaybackBegun: %d
```

PgSoundDb diagnostic dump (strings ~5011–5053), literal text includes:
```
Guid %x - Num sounds: %d
Sound Groups (%d):
Guid %x - Sounds: %x (%s) - [%d]
NumFreeSounds: %d, Max: %d, Avg: %d
NumFreeGroups: %d, Max: %d, Avg: %d
UsedVRAMBuffers: %d
FreeMSStreams: %d
ActiveMSStreams: %d
IdleSubmixVoices: %d
MusicSourceVoices: %d / %d
SourceVoices: %d / %d
Waves: %d, Max: %d, Avg: %d
StreamBlocks: %d, Max: %d, Avg: %d
TrackControllerInstances: %d, Max: %d, Avg: %d
SoundSources: %d, Max: %d, Avg: %d
SoundInstances: %d, Max: %d, Avg: %d
TrackInstances: %d, Max: %d, Avg: %d
CueInstances: %d, Max: %d, Avg: %d
Playing Pal Cues - %d:
Cue handle: %d - %s (%x)
State: %s, Bank: %x
Track %d - State: %s, Sounds: %d, ChildCue: %d
Sound %d - ID: %x, Has Wave: %d
Wave State: %s, Volume: %f, Pitch: %f
Volume Category: %s
Pitch Category: %s
MasterVolume: %f
```

This dump enumerates the runtime object pools (Waves, StreamBlocks, SoundSources, SoundInstances, TrackInstances, CueInstances, submix/source voices) and a category-based volume/pitch mixer with a master volume.

Instance/cue **state-name enum** (strings 14989–15004), almost certainly the `%s` "State:" values printed above:
`FADING_UP`, `FADING_DOWN`, `PREFADEOUT`, `PREFADEIN`, `FADEOUT`, `FADEIN`, `PAUSE`, `LOOPING`, `SYNCING`, `PREPARING`, `STOPPED`, `WAITING`, `STOPPING`, `FINISHED`, `PLAYING`, `READY`.

Volume-category fade states (strings 5043–5046): `FADEDOWN`, `FADEUP`, `DUCKED` — indicating audio ducking support.

Sub-pass / update markers (strings ~5055–5080), literal text: `SubmitToGroups`, `UpdatePause`, `UpdateLoads`, `UpdateStreamBlocks`, `SoundPlayer.Update`, `GroupManager::Update`, `MsgFilter.ProcessMessages`, `ProcessingCueMessages`, `ProcessingEventMessages`, `MsgHandler.Update`, `SoundMsgTranslator::Update`, `MsgTranslator.Update`, `UpdateGlobalParams`, `SoundAmbience.Update`, `RuntimeSoundUpdates`, `BankMan.Update`, `CacheCharacters`, `UpdateListeners`, `MusicManager.Update`, `CollisionHandling`, `RtSoundUpdate`, `RtSoundCollect`, `RtSoundEffect`, `RtAmbienceUpdate`, `RtAmbienceCollect`, `RtSoundAmbience`.

Pal source `__FILE__` strings and one assert/placeholder: `PalSoundEngine::MixSources` is immediately followed by the literal `Implement me, please` (strings 15013–15014) — a stub in the platform-independent `PalSoundEngine.cpp` whose real work lives in `PalSoundEngineXenon::MixSources`. The `PalSoundWaveXenon::CreateVoice` line is followed by `.\src\PalQueue.h` (a queue-header `__FILE__` reference).

Bink movie audio (PgMoviePlayerXenon, strings ~12928–12938), literal text:
```
ERROR!! You are passing a write combined memory address to Bink!
Playback will be *extremely* slow!  You must pass in read-write
cached memory for the Bink texture pointers - see BinkTextures.cpp
The file has a corrupt header.
Error reading Bink header.
Not a Bink file.
```

Asset-type / ECS pool tunables (sizes literal):
- `wavebank` and `scaleformgfx`/`terrainmesh`/`animation` asset-type tags (strings ~2459).
- ECS runtime pool sizing strings: ` RuntimeSoundEffect 1024 ` (string 1843), ` RuntimeSoundAmbience 128 64 ` (string 1842), ` RuntimeSoundRuinKey 16 16 ` (string 1844) — pool counts/alignments for the runtime sound components, read from the surrounding `Runtime* N N` table.
- Asset-name tags near `SoundBank`: `ChatterSet` (string 51122) — a VO/voice "chatter" set, alongside `SoundBank`, `WaveBank`, `SoundDb`, `MusicMarkers`, `MusicTransitions`, `GuidMap`.

## PC decompilation cross-reference

These map this system's Xbox symbols to functions in the PC retail decomp (`output/_ghidra/all_functions_decomp.txt`), resolved via `output/jul08_prototype/pairing/resolved_audio-pal.txt`. The Xbox build had **no RTTI for the audio classes**, so the vtable bridge produced nothing here — every match below is **string-anchored**. Crucially, the anchoring strings are not data labels: the Pal/Pg methods embed their own `Class::Method` name as a **profiler-scope string** and push it through the profiler vtable (`DAT_01176404`) on entry/exit. That makes these unusually strong string matches — the function literally announces its own name — so the named Pal methods are rated **high** despite being on the string bridge. The ECS component-descriptor initializers are rated **medium** (one distinctive type-name string each).

| Symbol / class | PC function | Bridge | Role |
|---|---|---|---|
| `PalEngine::BankUpdate` | `FUN_0082ee60` | string (self-named profiler scope) | bank update pass; walks bank list, frees finished entries into a ring buffer |
| `PalGlobalTable::FindCue` | `FUN_00835a70` | string (self-named profiler scope) | cue lookup; walks the global table resolving a cue id to its data record |
| `PalSoundEngine::MixSources` | `FUN_00836610` | string (self-named profiler scope) | source mix pass; iterates the source list calling the per-source mixer |
| `PalSoundInstance::Update` (+ CheckFinished / CreateWave / MaxDistCheck / StopCheck / WaveUpdate) | `FUN_00836c70` | string | per-instance state machine (the 6 method strings all anchor to this one 3 KB function) |
| `PalSoundInstance::StealWave` | `FUN_00837c50` | string | voice-stealing helper (called by `FUN_00836c70`) |
| `PalSoundSource::Update` / `UpdateWaves` | `FUN_00838380` | string | per-source update / wave-submit pass |
| `PalSoundWave::UpdateMixVolumes` | `FUN_0083e1d0` | string | recomputes per-wave mix volumes |
| `PalSoundWave::GetMixVolume` | `FUN_0083e430` | string | mix-volume accessor |
| `attachSound` | `FUN_007aa750` | string | command/registry handler; iterates the `attachSound` binding table |
| `MusicSource` | `FUN_00642cf0` | string | ECS component-descriptor init (sets type-name = `MusicSource`) |
| `MusicRegion` | `FUN_00642d90` | string | ECS component-descriptor init (sets type-name = `MusicRegion`) |
| `SoundRuinKey` | `FUN_006428e0` | string | ECS component-descriptor init |
| `SoundEffect` | `FUN_00642b00` | string | ECS component-descriptor init |
| `SoundAmbience` | `FUN_00642ba0` | string | ECS component-descriptor init |
| `SoundInterior` | `FUN_00642c40` | string | ECS component-descriptor init |
| `RuntimeSoundRuinKey` | `FUN_00644d90` | string | runtime sound-component descriptor init |
| `RuntimeSoundEffect` | `FUN_00644e50` | string | runtime sound-component descriptor init |
| `RuntimeSoundAmbience` | `FUN_00644f20` | string | runtime sound-component descriptor init |
| `AmbientEffectType` / `SoundKeyEnum` | `FUN_0064ac50` | string | enum/type registry (16 KB; references both enum-name strings) — registrar, not a 1:1 method (low) |

Confidence: the self-naming Pal methods (`FUN_0082ee60`, `FUN_00835a70`, `FUN_00836610`, `FUN_00836c70`, `FUN_00838380`, `FUN_0083e1d0`, `FUN_0083e430`, `FUN_00837c50`) are **high**. The component-descriptor inits are **medium**. `FUN_0064ac50` referencing many enum strings is a registrar, so the per-symbol mapping is **low** — treat it as "the function that builds the `AmbientEffectType`/`SoundKeyEnum` enum tables", not as either method.

### Annotated excerpts

`FUN_00835a70` = `PalGlobalTable::FindCue` — the entry/exit profiler push proves the identity, and the body is the cue table walk:

```c
DAT_019c65c4 = (**(code **)(*DAT_01176404 + 0xc))(s_PalGlobalTable__FindCue_00be1e7c);   // register profiler scope by name
(**(code **)(*DAT_01176404 + 4))(s_PalGlobalTable__FindCue_00be1e7c,DAT_019c65c4);       // enter scope
piVar1 = *(int **)(param_1 + 0x18);     // table head
...
while (iVar2 != 0) {                     // walk linked records
  iVar4 = *(int *)(iVar2 + 4);
  if (*(ushort *)(iVar4 + 8) < 0x401) { iVar4 = FUN_0083c610(iVar4); ... }   // small-id direct resolve
  else { puVar3 = (ushort *)FUN_0083c760(iVar2 + 0x14);                       // large-id hashed resolve
         if (*puVar3 != 0xffff) iVar4 = *(int*)(iVar4+0x10) + (uint)*puVar3*0xc + 4 + iVar4; }
```

This shows the two cue-resolution paths (a direct path for ids `< 0x401` and a `0xffff`-sentinel hashed path), confirming `FindCue` resolves a cue id to a data record.

`FUN_00642cf0` = `MusicSource` component-descriptor init. The whole family (`SoundEffect`/`SoundAmbience`/`SoundInterior`/`SoundRuinKey`/`MusicRegion`/`Runtime*`) is byte-for-byte the same shape, differing only in the trailing type-name string and a few pool constants:

```c
_DAT_017be0c8 = &PTR_CopyFromStream_00bc0c58;   // stream-deserialize vtable for this component
_DAT_017be0dc = 3;                              // element/stride count
_DAT_017be0f4 = 0x9e3779b9;                     // golden-ratio hash seed (FNV/Knuth) for the type id
FUN_0064a770();                                 // register the descriptor
_DAT_017be104 = s_MusicSource_00bc538c;         // type-name = "MusicSource"
```

The terminal assignment of the `MusicSource` type-name string is what anchors the match; the shared `0x9e3779b9` seed and `CopyFromStream` vtable identify these as ECS component descriptors built from a stream.

`FUN_007aa750` = `attachSound` handler. It walks the `attachSound` binding table (`PTR_s_attachSound_00b93708`), allocating a 0x34-byte node per entry (tagged `0x56471e89` / `&DAT_9fe1234a`) and calling `FUN_007837d0` to bind each sound — a registry/attach pass rather than a single method.

## How it works (decompiled)

VAs below are from the **Xbox 360** decompilation `output/_ghidra_x360/xenon_decomp_named.c` (base 0x82000000; RVA = VA − 0x82000000). Grep-confirmed. Important up-front correction to the existing doc: the "PC decompilation cross-reference" section's claim that the Pal methods "embed their own `Class::Method` name as a profiler-scope string" is **a PC-build property that does NOT hold in the Xbox build** — Ghidra recovered essentially no inline name strings here, and the Pal method RVAs (0xbf0f4 `BankUpdate`, 0xbf2f8 `MixSources`, 0xbf4c4 `FindCue`, 0xbf6ec `Update`, …) are **not referenced anywhere** in the Xbox decomp bodies. So the named Pal *methods* are not directly locatable in this build; what I *can* ground is the source-file-marked Pal functions, the message-bus, the update-pipeline marker table, and the ECS sound-component descriptors.

### The audio update pipeline is a profiler-marker table — order confirmed in code

`SubmitToGroups @0x82496b00` registers the entire audio update pipeline's per-pass timers, one `(hash, name)` pair per pass:

```c
void SubmitToGroups(void) {
  uVar1 = FUN_8290ba80(0xffffffff8202f298); FUN_82902f90(uVar1,0xffffffff8202f298); // RtSoundAmbience
  uVar1 = FUN_8290ba80(0xffffffff8202f284); FUN_82902f90(uVar1,0xffffffff8202f284); // RtAmbienceCollect
  uVar1 = FUN_8290ba80(0xffffffff8202f270); FUN_82902f90(uVar1,0xffffffff8202f270); // RtAmbienceUpdate
  ...
  uVar1 = FUN_8290ba80(0xffffffff8202f0e8); FUN_82902f90(uVar1,0xffffffff8202f0e8); // SoundPlayer.Update
  uVar1 = FUN_8290ba80(0xffffffff8202f0d4); FUN_82902f90(uVar1,0xffffffff8202f0d4); // UpdateStreamBlocks
  uVar1 = FUN_8290ba80(0xffffffff8202f0c8); FUN_82902f90(uVar1,0xffffffff8202f0c8); // UpdateLoads
}
```

I resolved the marker RVAs against the inventory; they map **exactly** to the documented pipeline names (0x2f298 `RtSoundAmbience`, 0x2f284 `RtAmbienceCollect`, 0x2f270 `RtAmbienceUpdate`, 0x2f260 `RtSoundEffect`, 0x2f250 `RtSoundCollect`, 0x2f240 `RtSoundUpdate`, 0x2f218 `MusicManager.Update`, 0x2f1bc `SoundAmbience.Update`, 0x2f174 `SoundMsgTranslator::Update`, 0x2f0e8 `SoundPlayer.Update`, 0x2f0d4 `UpdateStreamBlocks`, 0x2f0c8 `UpdateLoads`). So the "Update-pipeline / profiler markers" in the existing doc is **a real, ordered pass list**, registered here. Note `FUN_8290ba80 @0x8290ba80` is an **FNV-1a hash** (seed `0x811c9dc5`, prime `0x1000193`, `| 0x20` lowercase-fold, `^ 0x2a`), not a profiler-enter — these passes are keyed by name-hash. `UpdateStreamBlocks` (0x2f0d4) is firmly inside this **audio** table, confirming world-streaming.md's caution that it is sound-stream, not world-content, streaming.

### The message bus is concrete: a translator with a fixed 14-slot handler array

`PgSoundMessageTranslator @0x82485428` lazily constructs a fixed array of message handlers, each tagged with the owner RVA `0x2e420` (= `PgSoundMessageTranslator`):

```c
if (*param_1 == 0)      { iVar1 = FUN_822073b8(0xffffffff831b1370,0xffffffff8202e420); *param_1 = iVar1; }
if (param_1[1] == 0)    { iVar1 = FUN_822073b8(0xffffffff83187008,0xffffffff8202e420); param_1[1] = iVar1; }
if (param_1[2] == 0)    { iVar1 = FUN_8246cf08(0xffffffff83151308,0xffffffff8202e420); param_1[2] = iVar1; }
... (slots 0..13, two factory fns FUN_822073b8 / FUN_8246cf08 by handler type) ...
```

`PgSoundMessageHandler @0x82484e48` is the same shape with 2 slots tagged `0x2e404` (= `PgSoundMessageHandler`), and `PgMusicStateMachine @0x824897c8` lazily builds one handler tagged `0x2e648` (= `PgMusicStateMachine`, confirmed in the pangea-engine-core inventory). So the "filter → handler → translator" message-bus design is real: each level is an array of typed handler objects, lazily allocated, and the cleanup paths (`FUN_82485298`, `FUN_82404c48`) tear them down slot-by-slot.

### Pal Xenon engine construction (source-file-anchored)

The two functions Ghidra tagged with Pal source files are genuine Pal code. `FUN_828d2360` (`/* source: PalSoundEngineXenon.cpp */`) is the engine factory:

```c
uVar1 = thunk_FUN_824e7d58(0xa0,0xa9,0xffffffff820bf400);  // alloc 0xA0-byte engine, file/line/tag
if ((uVar1 & 0xffffffff) != 0) { uVar2 = FUN_828d9268(uVar1,0); return uVar2; }   // construct
```

and `FUN_828d9268 @0x828d9268` is the `PalSoundEngineXenon` constructor: sets vtable `&PTR_LAB_820bf9fc`, a version/flag word `0xc001`, builds a self-referential linked list (`param_1[5]=param_1[6]=param_1+5`), and initializes ~25 float fields to `DAT_82111270` (a shared default float — volumes/gains/positions). `FUN_828ce9b8` (`/* source: PalEngine.cpp */`) shows the cue/bank node format: when a record's first byte is the tag `'\x1d'`, it allocates a 0x28-byte node, links it into a list (`FUN_828cdd50(node, this+0x30)`), and returns the record's `+0xC` field. These confirm Pal owns the actual voice/wave object pools, allocated with file/line/tag-stamped allocations (`thunk_FUN_824e7d58(size, line, tag)`).

### Sound ECS components — exact element sizes

The runtime/placed sound components register through the shared ECS descriptor mechanism (see world-streaming.md for the decompiled `FUN_824fd430`/`FUN_824fcac8`/`FUN_824fd490` helpers). Code-grounded element sizes (the `FUN_824fcac8` arg) and inlined name strings:

| Component (VA) | element size | name string in body |
|---|---|---|
| `SoundEffect @0x829f1b30` | 0x1c | `"SoundEffect"` |
| `SoundAmbience @0x829f1bc0` | 0x14 | `"SoundAmbience"` |
| `SoundInterior @0x829f1c50` | 0xc | `"SoundInterior"` |
| `MusicSource @0x829f1ce0` | 8 | `"MusicSource"` |
| `MusicRegion @0x829f1d70` | 4 | `"MusicRegion"` |
| `RuntimeSoundEffect @0x829f4190` | 0x1c | `"RuntimeSoundEffect"` |
| `RuntimeSoundAmbience @0x829f4220` | 1 | `"RuntimeSoundAmbience"` |
| `RuntimeMusicRegion @0x829f42b0` | 1 | `"RuntimeMusicRegion"` |

Each wires `&PTR_FUN_82030fa0` (the shared stream-deserialize vtable) — so placed sounds are stream-loaded from the WAD just like terrain/render components.

## Corrections & open questions

- **CORRECTION (significant):** the existing "PC decompilation cross-reference" says the Pal methods "embed their own `Class::Method` name as a profiler-scope string … the function literally announces its own name." That is **true only of the PC retail build**. In the **Xbox** build the symbol-name strings are not propagated into bodies and the Pal-method RVAs are unreferenced, so I could **not** locate `PalEngine::BankUpdate`/`PalGlobalTable::FindCue`/`PalSoundInstance::Update`/`PalSoundEngine::MixSources`/etc. by name. The `FUN_0082ee60`/`FUN_00835a70`/`FUN_00836610`/… VAs in that table are **PC addresses**; they should be labelled PC-build, and the Xbox decomp does not corroborate those specific method bodies.
- **CONFIRMED (was the doc's pipeline inference):** the `SoundPlayer.Update → … → MusicManager.Update / Rt*` ordered pipeline is registered as a real marker table in `SubmitToGroups @0x82496b00`, with every RVA resolving to the named pass.
- **CONFIRMED (was inferred):** the "filter → handler → translator" message bus — `PgSoundMessageTranslator @0x82485428` builds a 14-slot typed-handler array, `PgSoundMessageHandler @0x82484e48` a 2-slot one, all tagged with their owner symbol RVA.
- **CONFIRMED (was inferred):** Pal owns real object pools; the engine object is `0xA0` bytes (`FUN_828d2360`), built by `FUN_828d9268 @0x828d9268`; cue/bank nodes use a `'\x1d'` tag byte and 0x28-byte node (`FUN_828ce9b8`, PalEngine.cpp).
- **CORRECTION:** the `RuntimeSoundEffect 1024` / `RuntimeSoundAmbience 128 64` / `RuntimeSoundRuinKey 16 16` rows are **pool count + alignment**, not `sizeof`. The real element sizes are 0x1c / 1 / (RuinKey not shown) per `FUN_824fcac8`. Same caveat as world-streaming.md.
- **UNVERIFIED in Xbox build:** `XAudioCreateSourceVoice` — the string is in the import table per the doc, but **does not appear** in any decompiled body in `xenon_decomp_named.c` (the voice-manager call sites weren't recovered), so the XAudio backend wiring is asserted from the import string only, not from a read call site. The `PalSoundXenonVoiceManager::*`, `MixSources`, `GetClosestListener` bodies are likewise not in the named set.
- **OPEN:** `PalGlobalTable::FindCue`'s two-path (id `< 0x401` direct vs `0xffff`-hashed) resolution described in the doc is from the **PC** function `FUN_00835a70`; I could not find/confirm it in the Xbox build. The music state-machine `State:`/timer dump logic is also unconfirmed at the body level (only the `PgMusicStateMachine` handler-init is readable).
- **Vector-math gap (expected):** the actual mixing/3D-pan/distance-attenuation math is VMX128 and does not decode; `MixSources`/`MixWavesToOutput`/`CalculateVolume` numeric behavior is not recoverable from this dump even where the bodies exist.

## Cross-references

- `docs/mercs2-pdb-analysis/world-streaming.md` — `PgSoundStreamIO`, `WaveBank`/`SoundBank` loading, `UpdateStreamBlocks`, `FreeMSStreams`/`ActiveMSStreams` overlap with the asset/streaming subsystem (`wavebank` is a streamed asset type).
- `docs/mercs2-pdb-analysis/pangea-engine-core.md` — `Pg*` message bus (`PgSoundMessageFilter/Handler/Translator`) and `PgGameSystem` integration of the audio update pass.
- `docs/mercs2-pdb-analysis/rendering-shaders.md` — `PgMoviePlayerXenon` / Bink shares the movie/texture path; Bink also carries movie audio.
- Existing project docs that overlap:
  - Memory note `support-store-system-map.md` and `decompiled-lua-corpus.md` — the `CueSound`/`StopSound`/`LoadSoundBank` script command surface is reachable from Lua.
  - Memory note `session-2026-06-10-validator-and-audio-port.md` and `docs/session_2026-06-10_validator_trust_and_audio_port.md` — the WAD-side audio wavebank/XMA converter work; `WaveBank`/`SoundBank` here are the runtime consumers of those assets.

## Evidence & confidence

- **Symbol count:** 127 lines in `inventory/audio-pal.txt` (offsets/sections), spanning sections `.rdata` (majority), `.data` (5 records at 0x0b8a564–0x0b8a594), and one `.reloc` fragment (`VoRKj`, discounted).
- **Sections:** `.rdata` (constant name strings + Pal/Pg method-name strings), `.data` (bank/music data records), `.reloc` (artifact).
- **Verified** (symbol/string exists, copy-exact and grep-verified): every offset/symbol in the tables above; the 13 source-file paths; the two extra Pal header `__FILE__` strings; the `XAudioCreateSourceVoice` import; the music/bank command vocabulary; the PgSoundDb and Music debug dump format strings; the state-name enum; the Bink error strings; the `Runtime*` pool-size strings.
- **Interpretations** (marked inline above): the Pal = "Pandemic Audio Library" expansion; class groupings (no RTTI exists for these — they are method-name strings only); the mapping of the `FADING_UP…READY` enum to the printed `State: %s`; that `Implement me, please` marks the generic `MixSources` stub; that `ChatterSet` is VO; that `VoRKj`/`UUUUUU` are extraction artifacts; the dynamic/faction-driven music architecture from command names; pool-size interpretation of the `Runtime* N N` strings.
- **Notable gap:** no `.?AV`/`.?AU` RTTI descriptors exist for any audio class, and there are no `.text` function-address symbols in this inventory (all evidence is name/string and `.data` records), so call graphs and struct layouts are not directly recoverable from these files alone.
