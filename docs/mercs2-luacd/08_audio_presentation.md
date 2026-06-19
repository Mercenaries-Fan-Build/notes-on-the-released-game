# 08 — Audio & Presentation

Decompiled Lua reference for the **audio & presentation** subsystem of *Mercenaries 2: World in Flames*. Covers the nine `Mrx*` resident scripts that drive sound bank loading, the dynamic music engine, voice-over (VO) sequencing, subtitles, cinematic slideshows, and HUD unlock fanfares.

> All line refs are clickable into the decompiled source under `src/resident/`.

---

## 1. Overview

The audio layer is a thin Lua orchestration tier over a native `Sound` / `VO` / `Pg` (asset) C++ binding. Lua never produces samples; it loads banks, declares music state machines, wires cues, and drives ducking/fading. Modules and responsibilities:

| Module | Role |
| --- | --- |
| **MrxSoundBootstrap** | One-shot boot: reverb preset, fade/pitch categories, all faction music-cue bindings, source-music playlists, then loads every gameplay bank and calls `MrxSound.Initialize`. |
| **MrxSound** | Game-state ↔ audio glue. Shell/pause/cinematic/PDA/attract/interior/transit/satellite/scope state enter-exit handlers, survival mode, action-hijack ducking, sound-ready gating. |
| **MrxSoundBanks** | Async bank request queue (sound/wave/temp/ambience banks), stream-file opening, VO localization, required-asset (animation/material tables) load/unload. |
| **MrxSoundCategories** | Category fade & pitch ducking tables (vosequence, fanfare, survivalmode, etc.), master-volume ref-counted ducking. |
| **MrxMusic** | The dynamic music engine: per-faction/per-region state machines, cue binding, transitions, special/source music, net replication of music events. |
| **MrxVoSequence** | Priority-arbitrated, multi-stage VO sequence player with delays, callbacks, timeouts, PDA dialog logging, net replication. |
| **MrxSubtitle** | Queues subtitle messages into the HUD subtitle buffer with display/fade timing. |
| **MrxCinematic** | Placeholder slideshow sequencer (chained slide fades) for stand-in cinematics. |
| **MrxUnlockFanfare** | Builds and triggers `Hud.EventFanfare` banners for unlocked contacts/support/stockpile/etc., with net replication. |

Initialization order: `MrxSoundBootstrap.Init` → (reverb, categories, cue bindings, playlists, `LoadBanks`) → `MrxSound.Initialize` → `MrxMusic._InitializeMusic` + `MrxSoundCategories._AdditionalFadeSetup` + game-exit hook.

---

## 2. Per-module reference

### MrxSoundBootstrap — boot orchestration
`src/resident/mrxsoundbootstrap.lua`

- `Init()` [mrxsoundbootstrap.lua:6](src/resident/mrxsoundbootstrap.lua#L6) — defines reverb preset `CITY_KG_LIGHT_REFLECTIONS` (id 1), sets pitch/fade categories, binds **all** faction/freeplay music cues (lines 29–106), enables duck-on-global-table-load, calls `LoadBanks`, registers every source-music playlist, then `MrxSound.Initialize()`.
- `ExitGame()` [mrxsoundbootstrap.lua:188](src/resident/mrxsoundbootstrap.lua#L188) — `UnloadBanks()`.
- `LoadBanks()` [mrxsoundbootstrap.lua:192](src/resident/mrxsoundbootstrap.lua#L192) — loads required assets + all gameplay/ambience/VO banks.
- `UnloadBanks()` [mrxsoundbootstrap.lua:248](src/resident/mrxsoundbootstrap.lua#L248) — symmetric unload.
- `SetPmcRadio(sInsertedCue)` [mrxsoundbootstrap.lua:304](src/resident/mrxsoundbootstrap.lua#L304) — rebuilds the `mu_src_radio` PMC HQ radio playlist, optionally appending a cue.

### MrxSound — state ↔ audio glue
`src/resident/mrxsound.lua`

- `EnterShellState()` / `ExitShellState()` [mrxsound.lua:5](src/resident/mrxsound.lua#L5) / [mrxsound.lua:17](src/resident/mrxsound.lua#L17) — loads/unloads `ui_shell`, `ui_hud`, `music` banks; `_StartShellMusic` transitions to `"shell"`.
- `_StartShellMusic()` [mrxsound.lua:29](src/resident/mrxsound.lua#L29).
- `_SetupGameExit()` / `ExitGame()` / `ExitingGame()` [mrxsound.lua:36](src/resident/mrxsound.lua#L36) — fades master to 0 over 0.5s on `unloading` state enter.
- `EnterPauseState/ExitPauseState` [mrxsound.lua:50](src/resident/mrxsound.lua#L50); `EnterCinematicState/Exit` [mrxsound.lua:60](src/resident/mrxsound.lua#L60); `EnterPDAState/Exit` [mrxsound.lua:68](src/resident/mrxsound.lua#L68); `EnterAttractState/Exit` [mrxsound.lua:78](src/resident/mrxsound.lua#L78) — toggle dynamic/timer music.
- `BeginActionHijack(bUseHijackMusic)` / `EndActionHijack(bUseHijackMusic, bSuccess)` [mrxsound.lua:86](src/resident/mrxsound.lua#L86) / [mrxsound.lua:94](src/resident/mrxsound.lua#L94) — fade `actionhijack` category, transition `hijack`→`hijack_success`/`action`, lock action level.
- `BeginSurvivalMode()` / `EndSurvivalMode()` [mrxsound.lua:108](src/resident/mrxsound.lua#L108) / [mrxsound.lua:116](src/resident/mrxsound.lua#L116) — `Sound.SetSurvivalMode`, fade + pitch `survivalmode`, loop `sfx_survival_lp`.
- `EnterInterior/ExitInterior` [mrxsound.lua:126](src/resident/mrxsound.lua#L126); `BeginTransit/EndTransit` [mrxsound.lua:137](src/resident/mrxsound.lua#L137); `EnterSatelliteView/Exit` [mrxsound.lua:149](src/resident/mrxsound.lua#L149); `EnterScopeView/Exit` [mrxsound.lua:159](src/resident/mrxsound.lua#L159) — lock listener position, fade `satelliteview`.
- `_FlagSystemReady()` [mrxsound.lua:169](src/resident/mrxsound.lua#L169), `SetSoundReadyFunc(funcSoundReady, bWaitForSoundAssets)` [mrxsound.lua:177](src/resident/mrxsound.lua#L177), `_CheckSoundReady()` [mrxsound.lua:184](src/resident/mrxsound.lua#L184) — gates a ready callback on sound-system-ready AND zero outstanding bank assets.
- `Initialize()` [mrxsound.lua:193](src/resident/mrxsound.lua#L193).

### MrxSoundBanks — async bank loader
`src/resident/mrxsoundbanks.lua`

- `LoadSoundBank/UnloadSoundBank/LoadWaveBank/UnloadWaveBank(sBank, funcBatchComplete)` [mrxsoundbanks.lua:10](src/resident/mrxsoundbanks.lua#L10)–[mrxsoundbanks.lua:36](src/resident/mrxsoundbanks.lua#L36) — enqueue via `_AddAssetRequest`.
- `LoadTempBank/UnloadTempBank` [mrxsoundbanks.lua:38](src/resident/mrxsoundbanks.lua#L38); `RequestAmbienceBank(sBank)` [mrxsoundbanks.lua:46](src/resident/mrxsoundbanks.lua#L46) (lib ≥ 12).
- `_SubmitAssetRequest()` [mrxsoundbanks.lua:52](src/resident/mrxsoundbanks.lua#L52) — throttles to `MAX_SUBMITTED` (64) in-flight; calls `Sound.LoadBankWithCallback` / `UnloadBankWithCallback`.
- `_AddAssetRequest(sBank, sType, bLoad)` [mrxsoundbanks.lua:68](src/resident/mrxsoundbanks.lua#L68) — pushes `{bank,type,load}`, bumps `_nOutstandingAssets`.
- `_GetLocalizedName(sAssetName)` [mrxsoundbanks.lua:80](src/resident/mrxsoundbanks.lua#L80) — appends `.<language>` to `vo_`-prefixed assets.
- `_OpenStreamFiles()` [mrxsoundbanks.lua:89](src/resident/mrxsoundbanks.lua#L89) — opens `vo_stream.pws`, `music.pws`, `ambience.pws` from `Sound.GetAudioDir()`.
- `_LoadRequiredAssetsCommon/_UnloadRequiredAssetsCommon` [mrxsoundbanks.lua:110](src/resident/mrxsoundbanks.lua#L110) / [mrxsoundbanks.lua:117](src/resident/mrxsoundbanks.lua#L117) — `sounddb`/`musicmarkers`/`musictransitions`.
- `_LoadRequiredAssets/_UnloadRequiredAssets` [mrxsoundbanks.lua:123](src/resident/mrxsoundbanks.lua#L123) / [mrxsoundbanks.lua:132](src/resident/mrxsoundbanks.lua#L132) — + animation/material key tables.
- `_FlagAssetOpComplete()` [mrxsoundbanks.lua:141](src/resident/mrxsoundbanks.lua#L141) — decrements counters, fires `_funcBatchComplete` + `MrxSound._CheckSoundReady` at zero.

### MrxSoundCategories — ducking/fade/pitch
`src/resident/mrxsoundcategories.lua`

- `SetFadeCategory(sMode, sCategory, fLevel, fEnterLength, fExitLength)` [mrxsoundcategories.lua:10](src/resident/mrxsoundcategories.lua#L10); `Fade(sMode, bDown)` [mrxsoundcategories.lua:18](src/resident/mrxsoundcategories.lua#L18) — applies `Sound.FadeCategoryDown/Up` per category.
- `_AdditionalFadeSetup()` [mrxsoundcategories.lua:31](src/resident/mrxsoundcategories.lua#L31) — adds `credits` fades for `sfx`/`vo`.
- `SetPitchCategory` [mrxsoundcategories.lua:40](src/resident/mrxsoundcategories.lua#L40); `Pitch(sMode, bDown)` [mrxsoundcategories.lua:48](src/resident/mrxsoundcategories.lua#L48).
- `SetDuckOnGlobalTableLoad(bDuck)` [mrxsoundcategories.lua:63](src/resident/mrxsoundcategories.lua#L63); `_DuckGlobalTable()` [mrxsoundcategories.lua:67](src/resident/mrxsoundcategories.lua#L67) — ducks master to 0 over 0.3s while the sound DB loads.
- `DuckMasterVolume(fLength)/UnduckMasterVolume(fLength)` [mrxsoundcategories.lua:75](src/resident/mrxsoundcategories.lua#L75) / [mrxsoundcategories.lua:82](src/resident/mrxsoundcategories.lua#L82) — ref-counted master ducking.

### MrxMusic — dynamic music engine
`src/resident/mrxmusic.lua`

- `_DisableDynamicMusic/_RestoreDynamicMusic` [mrxmusic.lua:7](src/resident/mrxmusic.lua#L7) / [mrxmusic.lua:12](src/resident/mrxmusic.lua#L12).
- `SetMusicActionInterval(fActionInterval)` [mrxmusic.lua:263](src/resident/mrxmusic.lua#L263).
- `BindMusicCue(sFaction, sState, iCueIndex, sCue)` [mrxmusic.lua:271](src/resident/mrxmusic.lua#L271) — validates index ∈ (0,4); writes into `_tMusicCues`.
- `_InitializeMusic()` [mrxmusic.lua:294](src/resident/mrxmusic.lua#L294) — builds every faction/freeplay state machine, sets root region/source music, hijack music, server client-join replication.
- `SendPlayerJoinEvents()` [mrxmusic.lua:327](src/resident/mrxmusic.lua#L327) — replicates current music to newly joined clients.
- `_InitializeFaction(sFaction)` [mrxmusic.lua:343](src/resident/mrxmusic.lua#L343) / `_InitializeFreeplay(sFreeplay)` [mrxmusic.lua:376](src/resident/mrxmusic.lua#L376) — `Sound.AddMusicState` + `AddMusicTransition` declarations.
- `_BindMusicStateCues(sFaction, tCues)` [mrxmusic.lua:417](src/resident/mrxmusic.lua#L417).
- `Reset()` [mrxmusic.lua:426](src/resident/mrxmusic.lua#L426).
- `EnterFreeplayMusic()` [mrxmusic.lua:436](src/resident/mrxmusic.lua#L436) / `EnterContractMusic(sFaction)` [mrxmusic.lua:447](src/resident/mrxmusic.lua#L447) — lock/transition + net replicate.
- `PlayFanfare(bMissionSuccess)` [mrxmusic.lua:458](src/resident/mrxmusic.lua#L458) — transition `mission_success`/`mission_failure`.
- `PlaySpecialMusic(sMusicCue)` [mrxmusic.lua:471](src/resident/mrxmusic.lua#L471), `_SetMiscMusicIndex` [mrxmusic.lua:488](src/resident/mrxmusic.lua#L488), `_ResumeSpecialMusic` [mrxmusic.lua:496](src/resident/mrxmusic.lua#L496), `_IsPlayingSpecialMusic` [mrxmusic.lua:502](src/resident/mrxmusic.lua#L502), `StopSpecialMusic(sNewState)` [mrxmusic.lua:506](src/resident/mrxmusic.lua#L506), `_CleanupSpecialMusic` [mrxmusic.lua:526](src/resident/mrxmusic.lua#L526) — ping-pongs between `misc1`/`misc2` states for special/source music.
- `AddMusicPlaylist/BindPlaylistCue/ClearMusicPlaylist` [mrxmusic.lua:541](src/resident/mrxmusic.lua#L541)–[mrxmusic.lua:551](src/resident/mrxmusic.lua#L551).
- `GetFactionByStringHash/GetStateByStringHash` [mrxmusic.lua:553](src/resident/mrxmusic.lua#L553) / [mrxmusic.lua:564](src/resident/mrxmusic.lua#L564) — reverse string-hash lookup for net events (state defaults to `"silence"`).
- `NetEventCallback(nEventType, tArgs)` [mrxmusic.lua:577](src/resident/mrxmusic.lua#L577) — dispatches the 4 `NETEVENT_*` codes.

### MrxVoSequence — VO sequence player
`src/resident/mrxvosequence.lua`

- `Start(vSequence, bCinematic, nPriority, bSendNetEvent)` [mrxvosequence.lua:9](src/resident/mrxvosequence.lua#L9) — normalizes a sequence (cue/speaker, delay, callback stages), arbitrates by priority (higher pre-empts; equal/lower is rejected), fades `vosequence`, registers speakers, runs stage 1. Returns bool.
- `_ExecuteStage(nStage)` [mrxvosequence.lua:112](src/resident/mrxvosequence.lua#L112) — plays cue via `VO.Cue`, logs to PDA dialog, sets timeout; inner `_NextStage(sVoState)` [mrxvosequence.lua:123](src/resident/mrxvosequence.lua#L123) accumulates delays, adds +5s on `"cancel"`, schedules next stage via `Event.TimerRelative`.
- `Stop(bFadeSound, bIssueDanglingCallbacks, nPriorityFilter)` [mrxvosequence.lua:196](src/resident/mrxvosequence.lua#L196) — cancels all cues, optionally fires dangling callbacks.
- `Cleanup(bFadeSound)` [mrxvosequence.lua:225](src/resident/mrxvosequence.lua#L225); `Reset()` [mrxvosequence.lua:241](src/resident/mrxvosequence.lua#L241).
- `_CallSequenceCallbacks(tFormattedSequence)` [mrxvosequence.lua:253](src/resident/mrxvosequence.lua#L253) — fires uncalled, non-`bIgnoreOnSkip` callbacks on skip.
- `IsSequenceInProgress()` [mrxvosequence.lua:263](src/resident/mrxvosequence.lua#L263).

### MrxSubtitle — subtitle queue
`src/resident/mrxsubtitle.lua`

- `Add(vMsgs, fCallback, tCallbackArgs)` [mrxsubtitle.lua:5](src/resident/mrxsubtitle.lua#L5) — accepts a string or table of messages; pushes each to `Hud.SubtitleBuffer:AddMessage` with `_knDisplayDuration`/`_knFadeDuration`; attaches callback to the final message.
- `ClearPending()` [mrxsubtitle.lua:35](src/resident/mrxsubtitle.lua#L35) — removes pending messages from the buffer.

### MrxCinematic — placeholder slideshow
`src/resident/mrxcinematic.lua`

- `PlaceholderSequence(tSlides, fCallback, tCallbackArgs)` [mrxcinematic.lua:3](src/resident/mrxcinematic.lua#L3) — chains slides so each `_DisplaySlide`s the next; last slide carries the final callback; zeroes fade times.
- `_DisplaySlide(tSlideData)` [mrxcinematic.lua:21](src/resident/mrxcinematic.lua#L21) — defaults texture to `"temp_placeholder"`, calls `Hud.CinematicPlaceholder:Show`.

### MrxUnlockFanfare — HUD unlock banners
`src/resident/mrxunlockfanfare.lua`

- `AddUnlockedItem(tItemData)` [mrxunlockfanfare.lua:10](src/resident/mrxunlockfanfare.lua#L10) — builds a message and `Hud.EventFanfare:Commence{sType, vText}`; server replicates via `Net.SendEvent_UnlockFanfare` (skips `outfit`).
- `AddUnlockedItems(sType, tItems)` [mrxunlockfanfare.lua:33](src/resident/mrxunlockfanfare.lua#L33) — batched variant via `Net.SendEvent_BatchUnlockFanfare`.
- `_BuildMessage(sType, tItemData)` [mrxunlockfanfare.lua:59](src/resident/mrxunlockfanfare.lua#L59) — per-type message formatting (faction icon + name/qty).
- `SetClientFanfareData(...)` [mrxunlockfanfare.lua:107](src/resident/mrxunlockfanfare.lua#L107); `SetClientBatchFanfareData(...)` [mrxunlockfanfare.lua:122](src/resident/mrxunlockfanfare.lua#L122) — client-side handlers for replicated fanfares.
- `ClientHVTFanfare(iFanfareType, sFactionId, sDesc, iInlineIcon, nCompleted, nQuota)` [mrxunlockfanfare.lua:145](src/resident/mrxunlockfanfare.lua#L145) — HVT capture/kill banners.

---

## 3. Defaults & tunables

### Constants / module-level state

| Constant | Value | Where |
| --- | --- | --- |
| `NETEVENT_ENTERFREEPLAY / ENTERCONTRACT / PLAYSPECIALMUSIC / STOPSPECIALMUSIC` | 0 / 1 / 2 / 3 | [mrxmusic.lua:1](src/resident/mrxmusic.lua#L1) |
| `_bPrevDynamic` | `true` | [mrxmusic.lua:5](src/resident/mrxmusic.lua#L5) |
| `_sRootFactionRegion` | `"freeplay_city"` | [mrxmusic.lua:250](src/resident/mrxmusic.lua#L250) |
| `_sSourceMusicState` | `"source"` | [mrxmusic.lua:251](src/resident/mrxmusic.lua#L251) |
| `_sHijackSuccessMusicState` | `"hijack_success"` | [mrxmusic.lua:257](src/resident/mrxmusic.lua#L257) |
| `_sHijackResumeMusicState` | `"hijack_success_resume"` | [mrxmusic.lua:258](src/resident/mrxmusic.lua#L258) |
| `_fNonActionInterval` | `5` | [mrxmusic.lua:259](src/resident/mrxmusic.lua#L259) |
| `_fActionInterval` | `15` | [mrxmusic.lua:260](src/resident/mrxmusic.lua#L260) |
| `_tMiscMusicStates` | `{"misc1","misc2"}` | [mrxmusic.lua:261](src/resident/mrxmusic.lua#L261) |
| `_tSourceMusicTransitions` | `none/none, silence/silence, explore/explore` | [mrxmusic.lua:252](src/resident/mrxmusic.lua#L252) |
| `MAX_SUBMITTED` (in-flight bank requests) | `64` | [mrxsoundbanks.lua:5](src/resident/mrxsoundbanks.lua#L5) |
| `_knDisplayDuration` (subtitle) | `5` (s) | [mrxsubtitle.lua:2](src/resident/mrxsubtitle.lua#L2) |
| `_knFadeDuration` (subtitle) | `0.5` (s) | [mrxsubtitle.lua:3](src/resident/mrxsubtitle.lua#L3) |
| `_nBaseDelay` (VO inter-stage) | `0.25` (s, overridable per-sequence) | [mrxvosequence.lua:92](src/resident/mrxvosequence.lua#L92) |
| VO cancel-state extra delay | `+5` (s) | [mrxvosequence.lua:157](src/resident/mrxvosequence.lua#L157) |
| Reverb preset id / name | `1` / `CITY_KG_LIGHT_REFLECTIONS` | [mrxsoundbootstrap.lua:8](src/resident/mrxsoundbootstrap.lua#L8) |
| Master fade on game exit | `0` over `0.5`s | [mrxsound.lua:42](src/resident/mrxsound.lua#L42) |

### VO priorities (from native `VO.PRIORITY_*`)

| Lua name | Native | Ref |
| --- | --- | --- |
| `knPriorityCinematic` | `VO.PRIORITY_CINEMATIC` | [mrxvosequence.lua:3](src/resident/mrxvosequence.lua#L3) |
| `knPriorityBriefing` | `VO.PRIORITY_SCRIPTED_BRIEFING` | [mrxvosequence.lua:4](src/resident/mrxvosequence.lua#L4) |
| `knPriorityContract` (default) | `VO.PRIORITY_SCRIPTED_CONTRACT` | [mrxvosequence.lua:5](src/resident/mrxvosequence.lua#L5) |
| `knPriorityBounties` | `VO.PRIORITY_SCRIPTED_BOUNTIES` | [mrxvosequence.lua:6](src/resident/mrxvosequence.lua#L6) |
| `knPriorityFreeplay` | `VO.PRIORITY_SCRIPTED_FREEPLAY` | [mrxvosequence.lua:7](src/resident/mrxvosequence.lua#L7) |

### Music states — `Sound.AddMusicState(name, p2, p3, p4, p5, p6)`

Faction state machine [mrxmusic.lua:345](src/resident/mrxmusic.lua#L345)–[mrxmusic.lua:358](src/resident/mrxmusic.lua#L358); freeplay variant [mrxmusic.lua:378](src/resident/mrxmusic.lua#L378)–[mrxmusic.lua:392](src/resident/mrxmusic.lua#L392) (adds `high_action`, lower `action` level). Parameters are positional native args; tabulated verbatim:

| State | args (p2..p6) | notes |
| --- | --- | --- |
| `none` | 15, 0, 0, `_fNonActionInterval`(5), 0 | thresholds set 2,0 |
| `explore` | 30, 0, 0, 5, 0 | thresholds set 2,0 |
| `action` | 0, 3*(faction) / 1(freeplay), 0, `_fActionInterval`(15), 0 | |
| `high_action` | 0, 2, 0, 15, 0 | freeplay only |
| `mission_success` | 0, -1, 0, 0, 5 | |
| `mission_failure` | 0, -1, 0, 0, 5 | |
| `hijack` | 0, -1, 0, 0, 4 | |
| `hijack_success` | 120, 3, 0, 10, 8 | |
| `hijack_success_resume` | 0, -1, 0, 0, 8 | |
| `source` | 0, 0, 0, 5, 4 | |
| `shell` | 0, -1, 0, 0, 4 | |
| `misc1` / `misc2` | 0, -1, 0, 0, 4 | special-music ping-pong |
| `pause` | 0, -1, 0.25, 0, 2 | |
| `silence` | 0, -1, 0, 0, 4 | |

### Fade categories — `SetFadeCategory(mode, category, level, enter, exit)`
Configured in `MrxSoundBootstrap.Init` [mrxsoundbootstrap.lua:17](src/resident/mrxsoundbootstrap.lua#L17)–[mrxsoundbootstrap.lua:28](src/resident/mrxsoundbootstrap.lua#L28) and `_AdditionalFadeSetup` [mrxsoundcategories.lua:31](src/resident/mrxsoundcategories.lua#L31).

| Mode | Category → (level, enter, exit) |
| --- | --- |
| `vosequence` | non_ui 0.3 / chatter 0.3 / music 0.4 (all 0.5,0.5) |
| `actionhijack` | Non_Action_Hijack 0.4 / chatter 0.3 |
| `survivalmode` (fade) | non_ui 0.4 / chatter 0.3 / music 0.5 |
| `survivalmode` (pitch) | non_ui 0.5,0.5,0.5 / chatter 0.75,0.5,0.5 |
| `fanfare` | non_ui 0.1 / vo 0.1 |
| `satelliteview` | non_ui 0.1 / chatter 0.1 |
| `credits` | sfx 0 / vo 0 |

Master-volume ducks: duck-on-global-load → 0 over **0.3s** [mrxsoundcategories.lua:69](src/resident/mrxsoundcategories.lua#L69).

### Fanfare types (`sType` in `Hud.EventFanfare:Commence` / `_BuildMessage`)
`contact`, `support`, `stockpile`, `landingzone`, `bounty`, `outfit` [mrxunlockfanfare.lua:76](src/resident/mrxunlockfanfare.lua#L76)–[mrxunlockfanfare.lua:103](src/resident/mrxunlockfanfare.lua#L103), plus dynamically-set HVT types `hvtcapture` / `hvtkill` [mrxunlockfanfare.lua:149](src/resident/mrxunlockfanfare.lua#L149). `stockpile` message form: `"<support> (x <qty>)"`.

---

## 4. Sound / bank registry

### Sound banks (loaded by `MrxSoundBootstrap.LoadBanks`)
Gameplay/shared — each typically loaded as both wave + sound bank:
`ambience`, `amb_birds`, `amb_shared` (wave only), `collision_shared`, `destruction_shared`, `fol_shared`, `veh_shared`, `wpn_shared`, `building_destruct` (+ wave `bulding_destruct` — note the typo in the data), `veh_support`, `music`, `ui_hud`. [mrxsoundbootstrap.lua:195](src/resident/mrxsoundbootstrap.lua#L195)–[mrxsoundbootstrap.lua:217](src/resident/mrxsoundbootstrap.lua#L217)

Shell-state banks (`MrxSound.EnterShellState`): `ui_shell`, `ui_hud`, `music` [mrxsound.lua:9](src/resident/mrxsound.lua#L9).

VO sound banks (loaded as soundbanks; `vo_stream` also as wavebank): `vo_stream`, `vo_mattias`, `vo_Chris`, `vo_carmona`, `vo_Jen`, `vo_Fiona`, `vo_Ewan`, `vo_Misha`, `vo_Misc`, `vo_alliedSoldier_01/02`, `vo_alliedSoldier_black_03`, `vo_chinSoldier_01/02`, `vo_oc_merc_01/02`, `vo_vzCiv_01/02`, `vo_vzCiv_female_01/02`, `vo_vzGurSoldier_01/02`, `vo_vzGurSoldier_female_01`, `vo_vzSoldier_01/02`, `vo_pirate_01/02`, `vo_pirate_female_01`. [mrxsoundbootstrap.lua:218](src/resident/mrxsoundbootstrap.lua#L218)–[mrxsoundbootstrap.lua:245](src/resident/mrxsoundbootstrap.lua#L245)

### Stream files (`.pws`) and Pg assets
- Stream files opened: `vo_stream.pws`, `music.pws`, `ambience.pws` (from `Sound.GetAudioDir()`) [mrxsoundbanks.lua:105](src/resident/mrxsoundbanks.lua#L105).
- Pg assets (common): `Mercs2Globals`/`sounddb`, `MusicMarkers`/`musicmarkers`, `MusicTransitions`/`musictransitions` [mrxsoundbanks.lua:112](src/resident/mrxsoundbanks.lua#L112).
- Pg assets (gameplay): `VehicleEngines`, `Sounds`, `SoundsAppendix`, `SoundMatch` (animationtable), `SoundKey` (materialkeytable) [mrxsoundbanks.lua:125](src/resident/mrxsoundbanks.lua#L125).

### Music cue registry (`_tMusicCues`, [mrxmusic.lua:16](src/resident/mrxmusic.lua#L16))
Two categories: **factions** (`an`, `oc`, `gr`, `ch`, `pmc`) and **freeplay** (`freeplay_city`, `freeplay_jungle`, `freeplay_water`).

State → cue naming convention: `mu_fac_<faction>_<role>_NN` (factions) / `mu_nomission_<region>_<role>_NN` (freeplay). Roles: `explore`, `action`, `high_action` (freeplay only), `mission_success`, `mission_failure`, `hijack` (1–3 variants), `hijack_success`, `shell`/`pause` (both → `mu_shell_01`). Notable cross-borrows: `pmc` and all freeplay regions reuse `oc` hijack cues and `pmc` win/kickass; freeplay `mission_success` reuses `mu_fac_pmc_win_01`.

### Source-music playlists (`mu_src_*`, registered in `Init`)
PMC HQ radio (`mu_src_radio`, rebuilt by `SetPmcRadio`), `mu_src_civ`, `mu_src_gr_01`, `mu_src_plav_op_01`, `mu_src_pmc_hq_01`, `mu_src_pr_hq_01`, `mu_src_up_hq_01`, `mu_src_up_op_01`, `mu_src_al_hq_01`, `mu_src_al_op_01`, `mu_src_ch_hq_01`, `mu_src_ch_op_01`, `mu_src_oc_hq_01`, plus `*_contact` combat variants (`mu_src_al_op_01_contact`, `mu_src_ch_op_01_contact`, `mu_src_plav_op_01_contact`, `mu_src_oc_hq_01_contact`, `mu_src_oc_op_01_contact`) and mission-specific `mu_mission_pircon002_02`. [mrxsoundbootstrap.lua:109](src/resident/mrxsoundbootstrap.lua#L109)–[mrxsoundbootstrap.lua:184](src/resident/mrxsoundbootstrap.lua#L184)

### One-shot SFX
`sfx_survival_lp` — looped during survival mode (`Sound.CueSound(0,...)` / `Sound.StopSound(0,...)`) [mrxsound.lua:111](src/resident/mrxsound.lua#L111).

---

## 5. Logic

### VO sequence scheduling (`MrxVoSequence`)
A sequence is a list of stages, each normalized into one of: a **cue** `{vSpeaker, sCue}` (speaker resolved via `Pg.GetGuidByName` or 0), a **delay** `{nDelay}`, or a **callback** `{fCallback, tCallbackArgs, bIgnoreOnSkip}`. A bare-table stage with no `[1]` resolves the cue by the primary character's identity (J/M/C) [mrxvosequence.lua:63](src/resident/mrxvosequence.lua#L63). Arbitration: a new sequence with **higher** priority pre-empts the running one (`Stop` without fade); equal-or-lower priority is rejected but its callbacks still fire [mrxvosequence.lua:79](src/resident/mrxvosequence.lua#L79). Stages run via `VO.Cue` with a `_NextStage` continuation; consecutive `nDelay` stages accumulate, callbacks run with zero delay, normal cues use `_nBaseDelay` (0.25s). A `"cancel"` VO state adds +5s. An optional `_knTimeout` schedules `VO.Cancel`. Each cue is mirrored into the PDA dialog log (`Pda.Database:AddLogEntry`, `sType="dialog"`) [mrxvosequence.lua:174](src/resident/mrxvosequence.lua#L174).

### Music state transitions (`MrxMusic`)
States and transitions are declared per faction/region at init via native `Sound.AddMusicState`/`AddMusicTransition`. Gameplay drives them with `Sound.TransitionMusic(state)`:
- Freeplay enter → `Reset` + `ActivateFactionRegionMusic` + `explore` [mrxmusic.lua:436](src/resident/mrxmusic.lua#L436).
- Contract enter → lock faction music + `explore` [mrxmusic.lua:447](src/resident/mrxmusic.lua#L447).
- Mission end → `PlayFanfare(bSuccess)` → `mission_success`/`mission_failure` [mrxmusic.lua:458](src/resident/mrxmusic.lua#L458).
- Hijack (driven from `MrxSound`): `hijack` on begin, `hijack_success`/`action` on end, action level locked during [mrxsound.lua:86](src/resident/mrxsound.lua#L86).
- Special/source music ping-pongs between `misc1`/`misc2` so a new cue can cross-fade from the old, while remembering and restoring the prior faction-lock [mrxmusic.lua:471](src/resident/mrxmusic.lua#L471).
- All of the above replicate over the network as `NETEVENT_*` custom events on channel `"MrxMusic"`, re-applied by `NetEventCallback` (faction/state recovered from string hashes) [mrxmusic.lua:577](src/resident/mrxmusic.lua#L577).

### Fanfare triggers (`MrxUnlockFanfare`)
`AddUnlockedItem`/`AddUnlockedItems` build a banner string via `_BuildMessage(sType, …)` and call `Hud.EventFanfare:Commence{sType, vText}`. The `sType` selects the format (e.g. `stockpile` → `"<support> (x <qty>)"`). Server authoritatively replicates with `Net.SendEvent_UnlockFanfare` / `Net.SendEvent_BatchUnlockFanfare`; clients reconstruct via `SetClientFanfareData`/`SetClientBatchFanfareData`. `outfit` unlocks are not replicated. HVT capture/kill fanfares come through `ClientHVTFanfare` (client-only). Skip-mode (`MrxCheatBootstrap.IsSkipModeEnabled`) suppresses all fanfares [mrxunlockfanfare.lua:11](src/resident/mrxunlockfanfare.lua#L11).

---

## 6. Logging & debug markers (`Debug.Printf`)

| String (pattern) | Location |
| --- | --- |
| `Submitted request for <bank>, <type> with N submitted, …` | [mrxsoundbanks.lua:64](src/resident/mrxsoundbanks.lua#L64) |
| `Added request <bank>, <type>, <bLoad>` | [mrxsoundbanks.lua:69](src/resident/mrxsoundbanks.lua#L69) |
| `Opening filename <stream> with alias <name>` | [mrxsoundbanks.lua:101](src/resident/mrxsoundbanks.lua#L101) |
| `AssetOpComplete: N submitted, N oustanding, N last added` (sic) | [mrxsoundbanks.lua:142](src/resident/mrxsoundbanks.lua#L142) |
| `AssetOp Batch Complete` | [mrxsoundbanks.lua:147](src/resident/mrxsoundbanks.lua#L147) |
| `MrxSoundBootstrap.Init` | [mrxsoundbootstrap.lua:7](src/resident/mrxsoundbootstrap.lua#L7) |
| `Loading sound assets` / `Unloading sound assets` | [mrxsoundbootstrap.lua:193](src/resident/mrxsoundbootstrap.lua#L193) / [mrxsoundbootstrap.lua:249](src/resident/mrxsoundbootstrap.lua#L249) |
| `Shell music started.` / `Shell exited` | [mrxsound.lua:30](src/resident/mrxsound.lua#L30) / [mrxsound.lua:26](src/resident/mrxsound.lua#L26) |
| `Invalid music action interval. Using default …` | [mrxmusic.lua:265](src/resident/mrxmusic.lua#L265) |
| `!!! MUSIC WARNING - Bad cue binding for: …` | [mrxmusic.lua:287](src/resident/mrxmusic.lua#L287) |
| `!!! MUSIC WARNING - Cue index out of range for: …` | [mrxmusic.lua:290](src/resident/mrxmusic.lua#L290) |
| `MRXMUSIC ------------ EnterFreeplayMusic()` | [mrxmusic.lua:437](src/resident/mrxmusic.lua#L437) |
| `MRXMUSIC ------------ EnterContractMusic(<f>)` | [mrxmusic.lua:448](src/resident/mrxmusic.lua#L448) |
| `MRXMUSIC ------------ PlaySpecialMusic(<cue>)` | [mrxmusic.lua:472](src/resident/mrxmusic.lua#L472) |
| `MRXMUSIC ------------ StopSpecialMusic(<state>)` | [mrxmusic.lua:508](src/resident/mrxmusic.lua#L508) |
| `@@@@@@@@@@ MrxVoSequence.Start: sequence format is unusable! …` | [mrxvosequence.lua:16](src/resident/mrxvosequence.lua#L16) |
| `MrxVoSequence: Stage N: Playing cue <cue>` / `Playback … FAILED!` | [mrxvosequence.lua:169](src/resident/mrxvosequence.lua#L169) / [mrxvosequence.lua:172](src/resident/mrxvosequence.lua#L172) |
| `MrxVoSequence._NextStage: sVoState=…` / `Delaying Ns` / `End of sequence` | [mrxvosequence.lua:124](src/resident/mrxvosequence.lua#L124), [mrxvosequence.lua:160](src/resident/mrxvosequence.lua#L160), [mrxvosequence.lua:140](src/resident/mrxvosequence.lua#L140) |
| `ERROR: primary player character is not J / M / C` | [mrxvosequence.lua:71](src/resident/mrxvosequence.lua#L71) |
| (HVT fanfare text echoed) | [mrxunlockfanfare.lua:156](src/resident/mrxunlockfanfare.lua#L156) |

---

## 7. Cross-references & future-dev notes

### Native bindings consumed
- **`Sound.*`** — master volume, dynamic-music toggle, reverb, master/category fade, pitch, bank load/unload (`Load/UnloadBankWithCallback`, temp/ambience banks), stream files, music state machine (`AddMusicState`, `AddMusicTransition`, `BindMusicCue`, `TransitionMusic`, faction/region/source/hijack music), playlists, survival/listener flags. Versioned via `Sound._GetLibVersion()` (branches at ≥10 reverb-by-name, ≥11 source-music entry states, ≥12 ambience-bank requests).
- **`VO.*`** — `PRIORITY_*` constants, `AddSequence`/`RemoveSequence`, `Cue`, `Cancel`.
- **`Pg.*`** — asset load/unload + GUID-by-name resolution for speakers.
- **`Hud.*`** — `SubtitleBuffer:AddMessage/RemovePendingMessage`, `CinematicPlaceholder:Show`, `EventFanfare:Commence`.
- **`Pda.Database:AddLogEntry`** — VO dialog logging.
- **`Net.*`** — `SendCustomEvent` (music), `SendEvent_UnlockFanfare`/`SendEvent_BatchUnlockFanfare`, `IsServer`/`IsClient`.

### How gameplay triggers sound
Gameplay/mission scripts call the public `Mrx*` functions (e.g. `MrxVoSequence.Start`, `MrxMusic.PlaySpecialMusic`, `MrxUnlockFanfare.AddUnlockedItem`, `MrxSound.Begin*`/`Enter*`). Music/state transitions are largely driven by game-state-change events and the action-level system inside the native music engine; Lua only declares the state machine and issues `TransitionMusic`. Subtitles and VO are coupled (a VO cue and a `MrxSubtitle.Add` are usually issued together by dialog scripts; this module pair is the seam).

### Cross-module dependencies
- `MrxSoundBootstrap` → `MrxSound`, `MrxMusic`, `MrxSoundCategories`, `MrxSoundBanks`.
- `MrxSound` → `MrxMusic`, `MrxSoundCategories`, `MrxSoundBanks` (also the central state-machine hub).
- `MrxVoSequence` → `MrxSoundCategories` (vosequence fade), `MrxUtil`.
- `MrxUnlockFanfare` → `MrxGui`, `MrxFactionManager`, `MrxSupportData`, `WifStarterData`, `MrxStarterManager`, `WifEquipmentData`, `MrxCheatBootstrap`, `MrxUtil`.

### Extension points & gotchas
- **Bank-request throttle** (`MAX_SUBMITTED = 64`) and `_nOutstandingAssets` gate `MrxSound._CheckSoundReady`; any new bank must flow through `_AddAssetRequest` or the ready-callback may never fire.
- **VO localization** is keyed purely on the `vo_` prefix in `_GetLocalizedName`; new localized assets must use that prefix or won't get the `.<language>` suffix.
- **Data typo**: wavebank `bulding_destruct` (missing the second "i") is loaded/unloaded as-is [mrxsoundbootstrap.lua:211](src/resident/mrxsoundbootstrap.lua#L211); the corresponding soundbank is `building_destruct`. If the real bank is correctly spelled, this wavebank load silently fails — worth verifying against the WAD.
- **`mu_src_oc_hq_01` is registered twice** [mrxsoundbootstrap.lua:159](src/resident/mrxsoundbootstrap.lua#L159) (likely a copy-paste leftover for an intended `mu_src_oc_op_01`).
- **`MrxCinematic`** is explicitly a *placeholder* path (`temp_placeholder`, zeroed fades) — a likely seam for real cinematic playback in any restoration work.
- DLC/port note: this group is the canonical source for the audio bank manifest the converter must satisfy (wavebank/soundbank names + `.pws` streams + `sounddb`/`musicmarkers`/`musictransitions` Pg assets). VO banks are language-suffixed at runtime, not at build time.
