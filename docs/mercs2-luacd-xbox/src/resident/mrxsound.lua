local L0_1, L1_1
L0_1 = import
L1_1 = "MrxMusic"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSoundCategories"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSoundBanks"
L0_1(L1_1)

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = Sound
  L0_2 = L0_2.SetMasterVolume
  L1_2 = 1
  L2_2 = 0
  L0_2(L1_2, L2_2)
  L0_2 = Sound
  L0_2 = L0_2.TransitionMusic
  L1_2 = "silence"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2._LoadRequiredAssetsCommon
  L0_2()
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "ui_shell"
  L2_2 = _StartShellMusic
  L0_2(L1_2, L2_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadWaveBank
  L1_2 = "ui_shell"
  L2_2 = _StartShellMusic
  L0_2(L1_2, L2_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "ui_hud"
  L2_2 = _StartShellMusic
  L0_2(L1_2, L2_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadWaveBank
  L1_2 = "ui_hud"
  L2_2 = _StartShellMusic
  L0_2(L1_2, L2_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "music"
  L2_2 = _StartShellMusic
  L0_2(L1_2, L2_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadWaveBank
  L1_2 = "music"
  L2_2 = _StartShellMusic
  L0_2(L1_2, L2_2)
end

EnterShellState = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "ui_shell"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadWaveBank
  L1_2 = "ui_shell"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "ui_hud"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadWaveBank
  L1_2 = "ui_hud"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "music"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadWaveBank
  L1_2 = "music"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2._UnloadRequiredAssetsCommon
  L0_2()
  L0_2 = Sound
  L0_2 = L0_2.TransitionMusic
  L1_2 = "silence"
  L0_2(L1_2)
end

ExitShellState = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = Sound
  L0_2 = L0_2.TransitionMusic
  L1_2 = "shell"
  L0_2(L1_2)
end

_StartShellMusic = L0_1
L0_1 = false
_bExitingGame = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = false
  _bExitingGame = L0_2
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.GameStateChange
  L2_2 = {}
  L3_2 = "unloading"
  L4_2 = "enter"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = ExitGame
  L0_2(L1_2, L2_2, L3_2)
end

_SetupGameExit = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = Sound
  L0_2 = L0_2.SetMasterVolume
  L1_2 = 0
  L2_2 = 0.5
  L0_2(L1_2, L2_2)
  L0_2 = true
  _bExitingGame = L0_2
end

ExitGame = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _bExitingGame
  return L0_2
end

ExitingGame = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = Sound
  L0_2 = L0_2.TransitionMusic
  L1_2 = "pause"
  L0_2(L1_2)
  L0_2 = MrxMusic
  L0_2 = L0_2._DisableDynamicMusic
  L0_2()
end

EnterPauseState = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = MrxMusic
  L0_2 = L0_2._RestoreDynamicMusic
  L0_2()
  L0_2 = Sound
  L0_2 = L0_2.TransitionMusic
  L1_2 = "silence"
  L0_2(L1_2)
end

ExitPauseState = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = MrxMusic
  L0_2 = L0_2._DisableDynamicMusic
  L0_2()
end

EnterCinematicState = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = MrxMusic
  L0_2 = L0_2._RestoreDynamicMusic
  L0_2()
end

ExitCinematicState = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = MrxMusic
  L0_2 = L0_2._DisableDynamicMusic
  L0_2()
  L0_2 = Sound
  L0_2 = L0_2.SetTimerUpdateMusic
  L1_2 = false
  L0_2(L1_2)
end

EnterPDAState = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = MrxMusic
  L0_2 = L0_2._RestoreDynamicMusic
  L0_2()
  L0_2 = Sound
  L0_2 = L0_2.SetTimerUpdateMusic
  L1_2 = true
  L0_2(L1_2)
end

ExitPDAState = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = Sound
  L0_2 = L0_2.SetDynamicMusic
  L1_2 = false
  L0_2(L1_2)
end

EnterAttractState = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = Sound
  L0_2 = L0_2.SetDynamicMusic
  L1_2 = true
  L0_2(L1_2)
end

ExitAttractState = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxSoundCategories
  L1_2 = L1_2.Fade
  L2_2 = "actionhijack"
  L3_2 = true
  L1_2(L2_2, L3_2)
  if A0_2 then
    L1_2 = MrxMusic
    L1_2 = L1_2._IsPlayingSpecialMusic
    L1_2 = L1_2()
    if not L1_2 then
      L1_2 = Sound
      L1_2 = L1_2.TransitionMusic
      L2_2 = "hijack"
      L1_2(L2_2)
      L1_2 = Sound
      L1_2 = L1_2.LockActionLevelMusic
      L2_2 = true
      L1_2(L2_2)
    end
  end
end

BeginActionHijack = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  if A0_2 then
    L2_2 = MrxMusic
    L2_2 = L2_2._IsPlayingSpecialMusic
    L2_2 = L2_2()
    if not L2_2 then
      if A1_2 then
        L2_2 = Sound
        L2_2 = L2_2.TransitionMusic
        L3_2 = "hijack_success"
        L2_2(L3_2)
      else
        L2_2 = Sound
        L2_2 = L2_2.TransitionMusic
        L3_2 = "action"
        L2_2(L3_2)
      end
      L2_2 = Sound
      L2_2 = L2_2.LockActionLevelMusic
      L3_2 = false
      L2_2(L3_2)
    end
  end
  L2_2 = MrxSoundCategories
  L2_2 = L2_2.Fade
  L3_2 = "actionhijack"
  L4_2 = false
  L2_2(L3_2, L4_2)
end

EndActionHijack = L0_1
L0_1 = false
_bSurvivalModeStarted = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = Sound
  L0_2 = L0_2.SetSurvivalMode
  L1_2 = true
  L0_2(L1_2)
  L0_2 = MrxSoundCategories
  L0_2 = L0_2.Fade
  L1_2 = "survivalmode"
  L2_2 = true
  L0_2(L1_2, L2_2)
  L0_2 = Sound
  L0_2 = L0_2.CueSound
  L1_2 = 0
  L2_2 = "sfx_survival_lp"
  L0_2(L1_2, L2_2)
  L0_2 = MrxSoundCategories
  L0_2 = L0_2.Pitch
  L1_2 = "survivalmode"
  L2_2 = true
  L0_2(L1_2, L2_2)
  L0_2 = true
  _bSurvivalModeStarted = L0_2
end

BeginSurvivalMode = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = _bSurvivalModeStarted
  if L0_2 then
    L0_2 = Sound
    L0_2 = L0_2.SetSurvivalMode
    L1_2 = false
    L0_2(L1_2)
    L0_2 = MrxSoundCategories
    L0_2 = L0_2.Fade
    L1_2 = "survivalmode"
    L2_2 = false
    L0_2(L1_2, L2_2)
    L0_2 = Sound
    L0_2 = L0_2.StopSound
    L1_2 = 0
    L2_2 = "sfx_survival_lp"
    L0_2(L1_2, L2_2)
    L0_2 = MrxSoundCategories
    L0_2 = L0_2.Pitch
    L1_2 = "survivalmode"
    L2_2 = false
    L0_2(L1_2, L2_2)
  end
  L0_2 = false
  _bSurvivalModeStarted = L0_2
end

EndSurvivalMode = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = MrxMusic
  L0_2 = L0_2.Reset
  L0_2()
  L0_2 = Sound
  L0_2 = L0_2.LockActionLevelMusic
  L1_2 = true
  L0_2(L1_2)
  L0_2 = Sound
  L0_2 = L0_2.TransitionMusic
  L1_2 = "silence"
  L0_2(L1_2)
end

EnterInterior = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = Sound
  L0_2 = L0_2.LockActionLevelMusic
  L1_2 = false
  L0_2(L1_2)
  L0_2 = Sound
  L0_2 = L0_2.TransitionMusic
  L1_2 = "explore"
  L0_2(L1_2)
end

ExitInterior = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = Sound
  L0_2 = L0_2.TransitionMusic
  L1_2 = "silence"
  L0_2(L1_2)
end

BeginTransit = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = MrxMusic
  L0_2 = L0_2._IsPlayingSpecialMusic
  L0_2 = L0_2()
  if L0_2 then
    L0_2 = MrxMusic
    L0_2 = L0_2._ResumeSpecialMusic
    L0_2()
  else
    L0_2 = Sound
    L0_2 = L0_2.TransitionMusic
    L1_2 = "explore"
    L0_2(L1_2)
  end
end

EndTransit = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = MrxSoundCategories
  L0_2 = L0_2.Fade
  L1_2 = "satelliteview"
  L2_2 = true
  L0_2(L1_2, L2_2)
  L0_2 = Sound
  L0_2 = L0_2.LockListenerPosition
  L1_2 = true
  L0_2(L1_2)
end

EnterSatelliteView = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = Sound
  L0_2 = L0_2.LockListenerPosition
  L1_2 = false
  L0_2(L1_2)
  L0_2 = MrxSoundCategories
  L0_2 = L0_2.Fade
  L1_2 = "satelliteview"
  L2_2 = false
  L0_2(L1_2, L2_2)
end

ExitSatelliteView = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = Sound
  L0_2 = L0_2.LockListenerPosition
  L1_2 = true
  L0_2(L1_2)
end

EnterScopeView = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = Sound
  L0_2 = L0_2.LockListenerPosition
  L1_2 = false
  L0_2(L1_2)
end

ExitScopeView = L0_1
L0_1 = false
_bSoundSystemReady = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = true
  _bSoundSystemReady = L0_2
  L0_2 = _CheckSoundReady
  L0_2()
end

_FlagSystemReady = L0_1
L0_1 = false
_bWaitForSoundAssets = L0_1
L0_1 = nil
_funcSoundReadyCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  _bWaitForSoundAssets = A1_2
  _funcSoundReadyCallback = A0_2
  L2_2 = Sound
  L2_2 = L2_2.RegisterReadyCallback
  L3_2 = _FlagSystemReady
  L2_2(L3_2)
  L2_2 = _CheckSoundReady
  L2_2()
end

SetSoundReadyFunc = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = MrxSoundBanks
  L0_2 = L0_2._nOutstandingAssets
  L0_2 = L0_2 == 0
  L1_2 = _bWaitForSoundAssets
  L1_2 = _bWaitForSoundAssets
  L1_2 = not L1_2 or L1_2 and L1_2
  L2_2 = _funcSoundReadyCallback
  if L2_2 then
    L2_2 = _bSoundSystemReady
    if L2_2 and L1_2 then
      L2_2 = _funcSoundReadyCallback
      L2_2()
      L2_2 = nil
      _funcSoundReadyCallback = L2_2
    end
  end
end

_CheckSoundReady = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = MrxMusic
  L0_2 = L0_2._InitializeMusic
  L0_2()
  L0_2 = MrxSoundCategories
  L0_2 = L0_2._AdditionalFadeSetup
  L0_2()
  L0_2 = _SetupGameExit
  L0_2()
end

Initialize = L0_1
