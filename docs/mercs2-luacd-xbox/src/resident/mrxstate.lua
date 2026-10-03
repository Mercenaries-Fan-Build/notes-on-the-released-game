local L0_1, L1_1, L2_1, L3_1
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSoundCategories"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxMunitionsPickup"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiInterface"
L0_1(L1_1)
L0_1 = 0
STATE_NONE = L0_1
L0_1 = 1
STATE_CINEMATIC = L0_1
L0_1 = 2
STATE_WAITFORSTREAMING = L0_1
L0_1 = 3
STATE_WAITFORTETHER = L0_1
L0_1 = 4
STATE_WAITFORGAME = L0_1
L0_1 = {}
L1_1 = STATE_CINEMATIC
L2_1 = {}

function L3_1()
  local L0_2, L1_2
  L0_2 = _StateComplete
  L1_2 = STATE_CINEMATIC
  L0_2(L1_2)
end

L2_1.Enter = L3_1

function L3_1()
  local L0_2, L1_2
end

L2_1.Exit = L3_1
L2_1.nRefCount = 0
L3_1 = {}
L2_1.tEnterCompleteCallbacks = L3_1
L3_1 = {}
L2_1.tReadyToExitCallbacks = L3_1
L2_1.sName = "STATE_CINEMATIC"
L2_1.safeEnterCount = 0
L2_1.forceExitCount = 0
L0_1[L1_1] = L2_1
L1_1 = STATE_WAITFORSTREAMING
L2_1 = {}

function L3_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = Sys
  L0_2 = L0_2.RequestGameState
  L1_2 = "WaitForStreaming"
  L0_2(L1_2)
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.GameStateChange
  L2_2 = {}
  L3_2 = "WaitForStreaming"
  L4_2 = "exit"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = _StateComplete
  L4_2 = {}
  L5_2 = STATE_WAITFORSTREAMING
  L4_2[1] = L5_2
  L0_2(L1_2, L2_2, L3_2, L4_2)
end

L2_1.Enter = L3_1

function L3_1()
  local L0_2, L1_2
end

L2_1.Exit = L3_1
L2_1.nRefCount = 0
L3_1 = {}
L2_1.tEnterCompleteCallbacks = L3_1
L3_1 = {}
L2_1.tReadyToExitCallbacks = L3_1
L2_1.sName = "STATE_WAITFORSTREAMING"
L2_1.safeEnterCount = 0
L2_1.forceExitCount = 0
L0_1[L1_1] = L2_1
L1_1 = STATE_WAITFORTETHER
L2_1 = {}

function L3_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = Sys
  L0_2 = L0_2.RequestGameState
  L1_2 = "WaitForTether"
  L0_2(L1_2)
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.GameStateChange
  L2_2 = {}
  L3_2 = "WaitForTether"
  L4_2 = "exit"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = _StateComplete
  L4_2 = {}
  L5_2 = STATE_WAITFORTETHER
  L4_2[1] = L5_2
  L0_2(L1_2, L2_2, L3_2, L4_2)
end

L2_1.Enter = L3_1

function L3_1()
  local L0_2, L1_2
end

L2_1.Exit = L3_1
L2_1.nRefCount = 0
L3_1 = {}
L2_1.tEnterCompleteCallbacks = L3_1
L3_1 = {}
L2_1.tReadyToExitCallbacks = L3_1
L2_1.sName = "STATE_WAITFORTETHER"
L2_1.safeEnterCount = 0
L2_1.forceExitCount = 0
L0_1[L1_1] = L2_1
L1_1 = STATE_WAITFORGAME
L2_1 = {}

function L3_1()
  local L0_2, L1_2
  L0_2 = _StateComplete
  L1_2 = STATE_WAITFORGAME
  L0_2(L1_2)
end

L2_1.Enter = L3_1

function L3_1()
  local L0_2, L1_2
end

L2_1.Exit = L3_1
L2_1.nRefCount = 0
L3_1 = {}
L2_1.tEnterCompleteCallbacks = L3_1
L3_1 = {}
L2_1.tReadyToExitCallbacks = L3_1
L2_1.sName = "STATE_WAITFORGAME"
L2_1.safeEnterCount = 0
L2_1.forceExitCount = 0
L0_1[L1_1] = L2_1
_States = L0_1
L0_1 = true
_bEnableFade = L0_1
L0_1 = false
_bUseQuickFade = L0_1
L0_1 = 0.1
_nQuickFadeOutTime = L0_1
L0_1 = 0.5
_nQuickFadeInTime = L0_1
L0_1 = 1.1
_nLongFadeOutTime = L0_1
L0_1 = 1.1
_nLongFadeInTime = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = _bUseQuickFade
  if L2_2 then
    L2_2 = _bEnableFade
    if L2_2 then
      L2_2 = MrxGui
      L2_2 = L2_2.FadeToColor
      L3_2 = _nQuickFadeOutTime
      L2_2(L3_2)
    end
    L2_2 = Event
    L2_2 = L2_2.Create
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = _nQuickFadeOutTime
    L6_2 = true
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L5_2 = A0_2
    L6_2 = A1_2
    L2_2(L3_2, L4_2, L5_2, L6_2)
  else
    L2_2 = _bEnableFade
    if L2_2 then
      L2_2 = MrxGui
      L2_2 = L2_2.GlobalFadeToBlack
      L3_2 = A0_2
      L4_2 = A1_2
      L2_2(L3_2, L4_2)
    else
      L2_2 = Event
      L2_2 = L2_2.Create
      L3_2 = Event
      L3_2 = L3_2.TimerRelative
      L4_2 = {}
      L5_2 = _nLongFadeOutTime
      L6_2 = true
      L4_2[1] = L5_2
      L4_2[2] = L6_2
      L5_2 = A0_2
      L6_2 = A1_2
      L2_2(L3_2, L4_2, L5_2, L6_2)
    end
  end
  L2_2 = _bUseQuickFade
  _bQuickFaded = L2_2
  L2_2 = MrxVoSequence
  L2_2 = L2_2.Stop
  L3_2 = true
  L2_2(L3_2)
  L2_2 = MrxSoundCategories
  L2_2 = L2_2.DuckMasterVolume
  L3_2 = 0.5
  L2_2(L3_2)
  L2_2 = Graphics
  L2_2 = L2_2.Atmosphere
  L2_2 = L2_2.EnableImmediatelyChangeMode
  L3_2 = true
  L2_2(L3_2)
  L2_2 = MrxMunitionsPickup
  L2_2 = L2_2.ImmediatePickup
  L2_2()
  L2_2 = Player
  L2_2 = L2_2.GetAllPlayers
  L2_2 = L2_2()
  if L2_2 then
    L3_2 = ipairs
    L4_2 = L2_2
    L3_2, L4_2, L5_2 = L3_2(L4_2)
    for L6_2, L7_2 in L3_2, L4_2, L5_2 do
      L8_2 = Player
      L8_2 = L8_2.GetCharacter
      L9_2 = L7_2
      L8_2 = L8_2(L9_2)
      L9_2 = Player
      L9_2 = L9_2.SetScopeEnabled
      L10_2 = L7_2
      L11_2 = false
      L9_2(L10_2, L11_2)
      L9_2 = Player
      L9_2 = L9_2.SetInputEnabled
      L10_2 = L7_2
      L11_2 = false
      L9_2(L10_2, L11_2)
      if L8_2 then
        L9_2 = Object
        L9_2 = L9_2.SetInvincible
        L10_2 = L8_2
        L11_2 = true
        L12_2 = "MrxState"
        L9_2(L10_2, L11_2, L12_2)
      end
    end
  end
  L3_2 = Pda
  L4_2 = L3_2
  L3_2 = L3_2.SetSuppressed
  L5_2 = {}
  L5_2.vPlayer = nil
  L5_2.bSuppress = true
  L3_2(L4_2, L5_2)
  L3_2 = Hud
  L3_2 = L3_2.ResourceCounter
  L4_2 = L3_2
  L3_2 = L3_2.SetSuppressed
  L5_2 = {}
  L5_2.bSuppressCash = true
  L5_2.bSuppressFuel = true
  L3_2(L4_2, L5_2)
  L3_2 = MrxGuiInterface
  L3_2 = L3_2.HudInterface
  L3_2 = L3_2.FanfareQueue
  L3_2 = L3_2.Pause
  L4_2 = true
  L3_2(L4_2)
end

_GlobalEnter = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = Net
  L0_2 = L0_2.IsServer
  L0_2 = L0_2()
  if L0_2 then
    L0_2 = Net
    L0_2 = L0_2.SetLoadingScreen
    L1_2 = false
    L0_2(L1_2)
  end
  L0_2 = Gui
  L0_2 = L0_2.OnGlobalExit
  L0_2()
  L0_2 = nil
  L1_2 = _bQuickFaded
  if L1_2 then
    L1_2 = _bEnableFade
    if L1_2 then
      L1_2 = MrxGui
      L1_2 = L1_2.FadeFromColor
      L2_2 = _nQuickFadeInTime
      L1_2(L2_2)
    end
    L0_2 = _nQuickFadeInTime
  else
    L1_2 = _bEnableFade
    if L1_2 then
      L1_2 = MrxGui
      L1_2 = L1_2.GlobalFadeFromBlack
      L1_2()
    end
    L0_2 = _nLongFadeInTime
  end
  L1_2 = nil
  _bQuickFaded = L1_2
  L1_2 = EnableFade
  L2_2 = true
  L1_2(L2_2)
  L1_2 = MrxSoundCategories
  L1_2 = L1_2.UnduckMasterVolume
  L2_2 = 0.5
  L1_2(L2_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.EnableImmediatelyChangeMode
  L2_2 = false
  L1_2(L2_2)
  L1_2 = Pda
  L2_2 = L1_2
  L1_2 = L1_2.SetSuppressed
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.bSuppress = false
  L1_2(L2_2, L3_2)
  L1_2 = Hud
  L1_2 = L1_2.ResourceCounter
  L2_2 = L1_2
  L1_2 = L1_2.SetSuppressed
  L3_2 = {}
  L3_2.bSuppressCash = false
  L3_2.bSuppressFuel = false
  L1_2(L2_2, L3_2)
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = L0_2
  L5_2 = true
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3
    L0_3 = Player
    L0_3 = L0_3.GetAllPlayers
    L0_3 = L0_3()
    if L0_3 then
      L1_3 = ipairs
      L2_3 = L0_3
      L1_3, L2_3, L3_3 = L1_3(L2_3)
      for L4_3, L5_3 in L1_3, L2_3, L3_3 do
        L6_3 = Player
        L6_3 = L6_3.GetCharacter
        L7_3 = L5_3
        L6_3 = L6_3(L7_3)
        L7_3 = Player
        L7_3 = L7_3.SetScopeEnabled
        L8_3 = L5_3
        L9_3 = true
        L7_3(L8_3, L9_3)
        L7_3 = Player
        L7_3 = L7_3.SetInputEnabled
        L8_3 = L5_3
        L9_3 = true
        L7_3(L8_3, L9_3)
        if L6_3 then
          L7_3 = Object
          L7_3 = L7_3.SetInvincible
          L8_3 = L6_3
          L9_3 = false
          L10_3 = "MrxState"
          L7_3(L8_3, L9_3, L10_3)
        end
      end
    end
    L1_3 = _tGlobalExitCallbacks
    L2_3 = {}
    _tGlobalExitCallbacks = L2_3
    L2_3 = MrxUtil
    L2_3 = L2_3.ProcessCallbackTable
    L3_3 = L1_3
    L2_3(L3_3)
    L2_3 = MrxGuiInterface
    L2_3 = L2_3.HudInterface
    L2_3 = L2_3.FanfareQueue
    L2_3 = L2_3.Pause
    L3_3 = false
    L2_3(L3_3)
  end
  
  L1_2(L2_2, L3_2, L4_2)
end

_GlobalExit = L0_1
L0_1 = true
_bStateComplete = L0_1
L0_1 = nil
_fReadyToExitCallback = L0_1
L0_1 = nil
_tReadyToExitCallbackData = L0_1
L0_1 = {}
_tGlobalExitCallbacks = L0_1
L0_1 = {}
_tGlobalEnterCallbacks = L0_1

function L0_1()
  local L0_2, L1_2
  _bGloballyLocked = L0_2
  L0_2 = nil
  _bGloballyFading = L0_2
  L0_2 = true
  _bStateComplete = L0_2
  L0_2 = nil
  _fReadyToExitCallback = L0_2
  L0_2 = {}
  _tGlobalExitCallbacks = L0_2
  L0_2 = nil
  _tReadyToExitCallbackData = L0_2
  L0_2 = {}
  _tGlobalEnterCallbacks = L0_2
end

Reset = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = _States
  L1_2 = L1_2[A0_2]
  L1_2.bLocked = false
  L2_2 = STATE_WAITFORTETHER
  if A0_2 == L2_2 then
    L1_2.nRefCount = 0
  end
  L2_2 = L1_2.tReadyToExitCallbacks
  L3_2 = {}
  L1_2.tReadyToExitCallbacks = L3_2
  L3_2 = MrxUtil
  L3_2 = L3_2.ProcessCallbackTable
  L4_2 = L2_2
  L3_2(L4_2)
  L3_2 = _AttemptGlobalExit
  L3_2()
end

_StateComplete = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L5_2 = _States
  L5_2 = L5_2[A0_2]
  if not L5_2 then
    L6_2 = false
    return L6_2
  end
  if A1_2 == "nil" then
    A1_2 = nil
  end
  if A2_2 == "nil" then
    A2_2 = nil
  end
  if A3_2 == "nil" then
    A3_2 = nil
  end
  if A4_2 == "nil" then
    A4_2 = nil
  end
  L6_2 = _bGloballyFading
  if L6_2 then
    L6_2 = table
    L6_2 = L6_2.insert
    L7_2 = _tGlobalEnterCallbacks
    L8_2 = {}
    L9_2 = Enter
    L10_2 = {}
    L11_2 = A0_2
    L12_2 = A1_2 or L12_2
    if not A1_2 then
      L12_2 = "nil"
    end
    L13_2 = A2_2 or L13_2
    if not A2_2 then
      L13_2 = "nil"
    end
    L14_2 = A3_2 or L14_2
    if not A3_2 then
      L14_2 = "nil"
    end
    L15_2 = A4_2 or L15_2
    if not A4_2 then
      L15_2 = "nil"
    end
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L10_2[3] = L13_2
    L10_2[4] = L14_2
    L10_2[5] = L15_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L6_2(L7_2, L8_2)
    L6_2 = false
    return L6_2
  end
  L6_2 = L5_2.nRefCount
  L6_2 = L6_2 + 1
  L5_2.nRefCount = L6_2
  L6_2 = table
  L6_2 = L6_2.insert
  L7_2 = L5_2.tEnterCompleteCallbacks
  L8_2 = {}
  L9_2 = A1_2
  L10_2 = A2_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L6_2(L7_2, L8_2)
  L6_2 = table
  L6_2 = L6_2.insert
  L7_2 = L5_2.tReadyToExitCallbacks
  L8_2 = {}
  L9_2 = A3_2
  L10_2 = A4_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L6_2(L7_2, L8_2)
  L6_2 = _bGloballyLocked
  if not L6_2 then
    L6_2 = _bGloballyFading
    if not L6_2 then
      L6_2 = true
      _bGloballyLocked = L6_2
      L6_2 = true
      _bGloballyFading = L6_2
      L6_2 = _GlobalEnter
      L7_2 = _CompleteEnter
      L8_2 = {}
      L9_2 = L5_2
      L8_2[1] = L9_2
      L6_2(L7_2, L8_2)
      L6_2 = true
      return L6_2
    end
  end
  L6_2 = _bGloballyFading
  if not L6_2 then
    L6_2 = _CompleteEnter
    L7_2 = L5_2
    L6_2(L7_2)
  end
  L6_2 = true
  return L6_2
end

Enter = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  _bGloballyFading = L1_2
  L1_2 = A0_2.tEnterCompleteCallbacks
  L2_2 = {}
  A0_2.tEnterCompleteCallbacks = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.ProcessCallbackTable
  L3_2 = L1_2
  L2_2(L3_2)
  L2_2 = A0_2.bLocked
  if not L2_2 then
    A0_2.bLocked = true
    L2_2 = A0_2.Enter
    L2_2()
  end
  L2_2 = _tGlobalEnterCallbacks
  L3_2 = {}
  _tGlobalEnterCallbacks = L3_2
  L3_2 = MrxUtil
  L3_2 = L3_2.ProcessCallbackTable
  L4_2 = L2_2
  L3_2(L4_2)
end

_CompleteEnter = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = _States
  L3_2 = L3_2[A0_2]
  if not L3_2 then
    L4_2 = false
    return L4_2
  end
  L4_2 = L3_2.nRefCount
  if L4_2 <= 0 then
    L4_2 = MrxUtil
    L4_2 = L4_2.CallWithOptionalArgs
    L5_2 = A1_2
    L6_2 = A2_2
    L4_2(L5_2, L6_2)
    L4_2 = false
    return L4_2
  end
  L4_2 = _bGloballyFading
  if L4_2 then
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = _tGlobalEnterCallbacks
    L6_2 = {}
    L7_2 = Exit
    L8_2 = {}
    L9_2 = A0_2
    L10_2 = A1_2
    L11_2 = A2_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L4_2(L5_2, L6_2)
    return
  end
  L4_2 = table
  L4_2 = L4_2.insert
  L5_2 = _tGlobalExitCallbacks
  L6_2 = {}
  L7_2 = A1_2
  L8_2 = A2_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L4_2(L5_2, L6_2)
  L4_2 = L3_2.nRefCount
  L4_2 = L4_2 - 1
  L3_2.nRefCount = L4_2
  L4_2 = L3_2.nRefCount
  if L4_2 == 0 then
    L4_2 = L3_2.Exit
    if L4_2 then
      L4_2 = L3_2.Exit
      L4_2()
    end
  end
  L4_2 = _AttemptGlobalExit
  L4_2()
  L4_2 = true
  return L4_2
end

Exit = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = _bGloballyLocked
  if not L0_2 then
    return
  end
  L0_2 = true
  L1_2 = ipairs
  L2_2 = _States
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L5_2.nRefCount
    if not (0 < L6_2) then
      L6_2 = L5_2.bLocked
      if not L6_2 then
        goto lbl_18
      end
    end
    L0_2 = false
    do break end
    ::lbl_18::
  end
  if L0_2 then
    L1_2 = _GlobalExit
    L1_2()
    L1_2 = nil
    _bGloballyLocked = L1_2
  end
end

_AttemptGlobalExit = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = 0
  L1_2 = ipairs
  L2_2 = _States
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L5_2.nRefCount
    L0_2 = L0_2 + L6_2
  end
  return L0_2
end

_GetTotalRefCount = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _bGloballyLocked
  return L0_2
end

IsLocked = L0_1

function L0_1(A0_2)
  local L1_2
  _bUseQuickFade = A0_2
end

SetQuickFade = L0_1

function L0_1(A0_2)
  local L1_2
  _bEnableFade = A0_2
end

EnableFade = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = false
  L1_2 = ipairs
  L2_2 = _States
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L5_2.nRefCount
    if not (0 < L6_2) then
      L6_2 = L5_2.bLocked
      if not L6_2 then
        goto lbl_13
      end
    end
    L0_2 = true
    ::lbl_13::
  end
  if not L0_2 then
  end
end

PrintStatus = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = _States
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = _States
    L1_2 = L1_2[A0_2]
    L1_2 = L1_2.sName
    return L1_2
  end
end

GetStateName = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = _States
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = L1_2.safeEnterCount
  L2_2 = L2_2 + 1
  L1_2.safeEnterCount = L2_2
  L2_2 = L1_2.forceExitCount
  L3_2 = L1_2.safeEnterCount
  if L2_2 <= L3_2 then
    L2_2 = 1
    L3_2 = L1_2.forceExitCount
    L4_2 = 1
    for L5_2 = L2_2, L3_2, L4_2 do
      L6_2 = L1_2.safeEnterCount
      L6_2 = L6_2 - 1
      L1_2.safeEnterCount = L6_2
      L6_2 = Exit
      L7_2 = A0_2
      L6_2(L7_2)
    end
    L1_2.forceExitCount = 0
  end
end

SafeEnterCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = _States
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = Enter
  L3_2 = A0_2
  L4_2 = SafeEnterCallback
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L2_2(L3_2, L4_2, L5_2)
end

SafeEnter = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = _States
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = L1_2.safeEnterCount
  if 0 < L2_2 then
    L2_2 = L1_2.safeEnterCount
    L2_2 = L2_2 - 1
    L1_2.safeEnterCount = L2_2
    L2_2 = Exit
    L3_2 = A0_2
    L2_2(L3_2)
  else
    L2_2 = L1_2.forceExitCount
    L2_2 = L2_2 + 1
    L1_2.forceExitCount = L2_2
  end
end

SafeExit = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = _bGloballyLocked
  if L2_2 then
    L2_2 = table
    L2_2 = L2_2.insert
    L3_2 = _tGlobalExitCallbacks
    L4_2 = {}
    L5_2 = A0_2
    L6_2 = A1_2
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L2_2(L3_2, L4_2)
  else
    L2_2 = MrxUtil
    L2_2 = L2_2.CallWithOptionalArgs
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  end
end

AddGlobalExitCallback = L0_1
