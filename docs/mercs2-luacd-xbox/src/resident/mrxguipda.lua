local L0_1, L1_1, L2_1, L3_1
L0_1 = import
L1_1 = "MrxGuiBase"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifVzRegionNames"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiDialogBox"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSound"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPlayState"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifMissionData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiHudFactionGauge"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxStatsManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxState"
L0_1(L1_1)
L0_1 = 0
NETEVENT_SETSELECTEDMISSION = L0_1
L0_1 = 1
NETEVENT_PDAOPEN = L0_1
L0_1 = 2
NETEVENT_PDACLOSE = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = NETEVENT_SETSELECTEDMISSION
  if A0_2 == L2_2 then
    L2_2 = MrxGuiBase
    L2_2 = L2_2.GetWidgetByNameAndOwner
    L3_2 = "PDA"
    L4_2 = Player
    L4_2 = L4_2.GetLocalPlayer
    L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L4_2()
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
    if L2_2 then
      L3_2 = nil
      L4_2 = A1_2[1]
      if L4_2 then
        L4_2 = WifMissionData
        L4_2 = L4_2.GetMissionIdFromIndex
        L5_2 = A1_2[1]
        L4_2 = L4_2(L5_2)
        L3_2 = L4_2
      end
      L5_2 = L2_2
      L4_2 = L2_2.SetSelectedMission
      L6_2 = L3_2
      L7_2 = true
      L4_2(L5_2, L6_2, L7_2)
    else
      L3_2 = Event
      L3_2 = L3_2.Create
      L4_2 = Event
      L4_2 = L4_2.TimerRelative
      L5_2 = {}
      L6_2 = 1
      L5_2[1] = L6_2
      L6_2 = NetEventCallback
      L7_2 = {}
      L8_2 = A0_2
      L9_2 = A1_2
      L7_2[1] = L8_2
      L7_2[2] = L9_2
      L3_2(L4_2, L5_2, L6_2, L7_2)
    end
  else
    L2_2 = NETEVENT_PDAOPEN
    if A0_2 == L2_2 then
      L2_2 = Event
      L2_2 = L2_2.Post
      L3_2 = "PDA Open"
      L4_2 = {}
      L5_2 = Player
      L5_2 = L5_2.GetLocalPlayer
      L5_2 = L5_2()
      L4_2.uPlayer = L5_2
      L2_2(L3_2, L4_2)
    else
      L2_2 = NETEVENT_PDACLOSE
      if A0_2 == L2_2 then
        L2_2 = Event
        L2_2 = L2_2.Post
        L3_2 = "PDA Close"
        L4_2 = {}
        L2_2(L3_2, L4_2)
      end
    end
  end
end

NetEventCallback = L0_1
L0_1 = 5000
_knBlipLimit = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bActive
  if L1_2 then
    L1_2 = Sound
    L1_2 = L1_2.CueSound
    L2_2 = 0
    L3_2 = "ui_PDA_Open_01_st"
    L1_2(L2_2, L3_2)
  end
end

_PlayDelayedOpenSound = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = A0_2
  L6_2 = true
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = _PlayDelayedOpenSound
  L6_2 = {}
  L7_2 = A1_2
  L6_2[1] = L7_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
end

_SetupDelayedOpenSound = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bActive
  if L1_2 then
    return
  end
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bHaveFlash
  if not L1_2 then
    return
  end
  L1_2 = Net
  L1_2 = L1_2.IsClient
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = SetMissionChangeAllowed
    L2_2 = A0_2
    L3_2 = false
    L1_2(L2_2, L3_2)
  end
  L1_2 = MrxGuiDialogBox
  L1_2 = L1_2.oSystemDialogBoxFlash
  if L1_2 then
    return
  end
  L1_2 = MrxState
  L1_2 = L1_2.IsLocked
  L1_2 = L1_2()
  if L1_2 then
    return
  end
  L1_2 = MrxGuiBase
  L1_2 = L1_2.GetWidgetByNameAndOwner
  L2_2 = "Support Menu"
  L4_2 = A0_2
  L3_2 = A0_2.GetOwner
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L3_2(L4_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  if L1_2 then
    L2_2 = L1_2.CustomData
    L2_2 = L2_2.bEnabled
    if L2_2 then
      L3_2 = L1_2
      L2_2 = L1_2.Close
      L2_2(L3_2)
    end
  end
  L2_2 = MrxGuiBase
  L2_2 = L2_2.GetCurrentControlHolder
  L4_2 = A0_2
  L3_2 = A0_2.GetOwner
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  if L2_2 then
    return
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nSuppressedCount
  if 0.5 < L2_2 then
    return
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nCooldownFrames
  if 0 < L2_2 then
    return
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oMapFlash
  L3_2 = L2_2
  L2_2 = L2_2.Restart
  L2_2(L3_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oMapFlash
  L3_2 = L2_2
  L2_2 = L2_2.Play
  L2_2(L3_2)
  L2_2 = A0_2.CustomData
  L2_2.bActive = true
  A0_2.nAnalogInputHeld = 0
  L2_2 = MrxGuiBase
  L2_2 = L2_2.GetControlFocus
  L3_2 = A0_2
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oMapFlash
  L2_2 = L2_2.BasicData
  L2_2 = L2_2.uId
  if L2_2 then
    L2_2 = _GuiInternal
    L2_2 = L2_2.RegisterForPdaUpdate
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.oMapFlash
    L3_2 = L3_2.BasicData
    L3_2 = L3_2.uId
    L4_2 = true
    L2_2(L3_2, L4_2)
  end
  L2_2 = _PopulateMapDisplay
  L3_2 = A0_2
  L4_2 = nil
  L5_2 = nil
  L6_2 = _knBlipLimit
  L7_2 = false
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L2_2 = _PopulateSupportDisplay
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = MrxStatsManager
  L2_2 = L2_2.BuildStats
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = MrxStatsManager
  L2_2 = L2_2.PdaStatistics
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = _PopulateDatabaseDisplay
  L3_2 = A0_2
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2.SetVisible
  L4_2 = true
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.SetOwner
    L11_2 = A0_2
    L10_2 = A0_2.GetOwner
    L10_2, L11_2 = L10_2(L11_2)
    L8_2(L9_2, L10_2, L11_2)
    L8_2 = MrxGuiBase
    L8_2 = L8_2.AddWidgetWithChildren
    L9_2 = L7_2
    L8_2(L9_2)
  end
  L3_2 = MrxGuiManager
  L3_2 = L3_2.GetHudState
  L5_2 = A0_2
  L4_2 = A0_2.GetOwner
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L4_2(L5_2)
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  L4_2 = A0_2.CustomData
  L4_2.bHudState = L3_2
  if L3_2 then
    L4_2 = MrxGuiManager
    L4_2 = L4_2.ToggleHud
    L6_2 = A0_2
    L5_2 = A0_2.GetOwner
    L5_2 = L5_2(L6_2)
    L6_2 = false
    L4_2(L5_2, L6_2)
  end
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nFakePlayerX
  if not L4_2 then
    L4_2 = _GuiInternal
    L4_2 = L4_2.SetPlayerPDAWidget
    L6_2 = A0_2
    L5_2 = A0_2.GetOwner
    L5_2 = L5_2(L6_2)
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.oMapFlash
    L6_2 = L6_2.BasicData
    L6_2 = L6_2.uId
    L4_2(L5_2, L6_2)
  else
    L4_2 = _GuiInternal
    L4_2 = L4_2.SetPlayerPDAWidget
    L6_2 = A0_2
    L5_2 = A0_2.GetOwner
    L5_2 = L5_2(L6_2)
    L6_2 = 0
    L4_2(L5_2, L6_2)
    L4_2 = Sys
    L4_2 = L4_2.RequestGameState
    L5_2 = "PDA"
    L4_2(L5_2)
  end
  L5_2 = A0_2
  L4_2 = A0_2.SetEventHandler
  L6_2 = "GuiUpdate"
  L7_2 = _HandlePDAUpdateEvent
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = _SetupDelayedOpenSound
  L5_2 = 0.5
  L6_2 = A0_2
  L4_2(L5_2, L6_2)
  L4_2 = MrxSound
  L4_2 = L4_2.EnterPDAState
  L4_2()
  L4_2 = Sys
  L4_2 = L4_2.GetPlatform
  if L4_2 then
    L4_2 = Sys
    L4_2 = L4_2.GetPlatform
    L4_2 = L4_2()
    if 1 == L4_2 then
      L5_2 = A0_2.CustomData
      L5_2 = L5_2.oMapFlash
      L6_2 = L5_2
      L5_2 = L5_2.CallActionScriptCallback
      L7_2 = "setPlatform"
      L8_2 = {}
      L9_2 = "PS3"
      L8_2[1] = L9_2
      L5_2(L6_2, L7_2, L8_2)
    elseif 2 == L4_2 then
      L5_2 = A0_2.CustomData
      L5_2 = L5_2.oMapFlash
      L6_2 = L5_2
      L5_2 = L5_2.CallActionScriptCallback
      L7_2 = "setPlatform"
      L8_2 = {}
      L9_2 = "360"
      L8_2[1] = L9_2
      L5_2(L6_2, L7_2, L8_2)
    end
  end
  L4_2 = Event
  L4_2 = L4_2.Post
  L5_2 = "PDA Open"
  L6_2 = {}
  L8_2 = A0_2
  L7_2 = A0_2.GetOwner
  L7_2 = L7_2(L8_2)
  L6_2.uPlayer = L7_2
  L4_2(L5_2, L6_2)
  L4_2 = Net
  L4_2 = L4_2.IsClient
  L4_2 = L4_2()
  if L4_2 then
    L4_2 = Net
    L4_2 = L4_2.SendCustomEvent
    L5_2 = "MrxGuiPda"
    L6_2 = NETEVENT_PDAOPEN
    L7_2 = {}
    L4_2(L5_2, L6_2, L7_2)
  end
end

Open = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oMapFlash
  L1_2 = L1_2.BasicData
  L1_2 = L1_2.uId
  if L1_2 then
    L1_2 = _GuiInternal
    L1_2 = L1_2.RegisterForPdaUpdate
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.oMapFlash
    L2_2 = L2_2.BasicData
    L2_2 = L2_2.uId
    L3_2 = false
    L1_2(L2_2, L3_2)
  end
  L1_2 = A0_2.CustomData
  L1_2.bActive = false
  L1_2 = MrxGuiBase
  L1_2 = L1_2.ReleaseControlFocus
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bHaveFlash
  if L1_2 then
    L1_2 = A0_2.CustomData
    L1_2 = L1_2.oMapFlash
    L2_2 = L1_2
    L1_2 = L1_2.CallActionScriptCallback
    L3_2 = "requestClose"
    L4_2 = {}
    L5_2 = true
    L4_2[1] = L5_2
    L1_2(L2_2, L3_2, L4_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2.SetVisible
  L3_2 = false
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = MrxGuiBase
    L7_2 = L7_2.RemoveWidgetWithChildren
    L8_2 = L6_2
    L7_2(L8_2)
  end
  L2_2 = _GuiInternal
  L2_2 = L2_2.SetPlayerPDAWidget
  if L2_2 then
    L2_2 = _GuiInternal
    L2_2 = L2_2.SetPlayerPDAWidget
    L4_2 = A0_2
    L3_2 = A0_2.GetOwner
    L3_2 = L3_2(L4_2)
    L4_2 = 0
    L2_2(L3_2, L4_2)
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bHudState
  if L2_2 then
    L2_2 = MrxGuiManager
    L2_2 = L2_2.ToggleHud
    L4_2 = A0_2
    L3_2 = A0_2.GetOwner
    L3_2 = L3_2(L4_2)
    L4_2 = true
    L2_2(L3_2, L4_2)
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oSubtitle
  L3_2 = L2_2
  L2_2 = L2_2.ClearMessages
  L2_2(L3_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bMapMode
  if L2_2 then
    L2_2 = A0_2.CustomData
    L2_2.nFramesWithoutInput = -1
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.oMapFlash
    L4_2 = L2_2
    L3_2 = L2_2.HandleLeftAnalogInput
    L5_2 = 0
    L6_2 = 0
    L3_2(L4_2, L5_2, L6_2)
    L4_2 = L2_2
    L3_2 = L2_2.HandleRightAnalogInput
    L5_2 = 0
    L6_2 = 0
    L3_2(L4_2, L5_2, L6_2)
  end
  L2_2 = A0_2.CustomData
  L2_2.nCooldownFrames = 20
  L3_2 = A0_2
  L2_2 = A0_2.SetEventHandler
  L4_2 = "GuiUpdate"
  L5_2 = _PdaCooldown
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oTransit
  if L2_2 then
    L2_2 = _RemoveTransitInterface
    L3_2 = A0_2
    L2_2(L3_2)
  end
  L2_2 = Sound
  L2_2 = L2_2.CueSound
  L3_2 = 0
  L4_2 = "ui_PDA_Close_01_st"
  L2_2(L3_2, L4_2)
  L2_2 = MrxSound
  L2_2 = L2_2.ExitPDAState
  L2_2()
  L2_2 = Event
  L2_2 = L2_2.Post
  L3_2 = "PDA Close"
  L4_2 = {}
  L6_2 = A0_2
  L5_2 = A0_2.GetOwner
  L5_2 = L5_2(L6_2)
  L4_2.uPlayer = L5_2
  L2_2(L3_2, L4_2)
  L2_2 = Net
  L2_2 = L2_2.IsClient
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = Net
    L2_2 = L2_2.SendCustomEvent
    L3_2 = "MrxGuiPda"
    L4_2 = NETEVENT_PDACLOSE
    L5_2 = {}
    L2_2(L3_2, L4_2, L5_2)
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oMapFlash
  L4_2 = L2_2
  L3_2 = L2_2.SetSwfFile
  L5_2 = nil
  L3_2(L4_2, L5_2)
  L3_2 = A0_2.CustomData
  L3_2.bHaveFlash = false
  L3_2 = MrxGuiBase
  L3_2 = L3_2.AddWidget
  L4_2 = L2_2
  L3_2(L4_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetSwfFile
  L5_2 = L2_2.CustomData
  L5_2 = L5_2.sFile
  L6_2 = _FinishPdaReload
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
  A0_2.nAnalogInputHeld = 0
  L3_2 = MrxPmc
  L3_2 = L3_2.SetAllSupportViewed
  L3_2()
end

Close = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = _FinishLoad
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = MrxGuiBase
  L1_2 = L1_2.RemoveWidget
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oMapFlash
  L1_2(L2_2)
end

_FinishPdaReload = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = A0_2.CustomData
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nCooldownFrames
  L2_2 = L2_2 - 1
  L1_2.nCooldownFrames = L2_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.nCooldownFrames
  if L1_2 <= 0 then
    L1_2 = A0_2.CustomData
    L1_2.nCooldownFrames = 0
    L2_2 = A0_2
    L1_2 = A0_2.SetEventHandler
    L3_2 = "GuiUpdate"
    L4_2 = nil
    L1_2(L2_2, L3_2, L4_2)
  end
end

_PdaCooldown = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  if A1_2 then
    L2_2 = A0_2.CustomData
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.nSuppressedCount
    L3_2 = L3_2 + 1
    L2_2.nSuppressedCount = L3_2
  else
    L2_2 = A0_2.CustomData
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.nSuppressedCount
    L3_2 = L3_2 - 1
    L2_2.nSuppressedCount = L3_2
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bActive
  if L2_2 and A1_2 then
    L3_2 = A0_2
    L2_2 = A0_2.Close
    L2_2(L3_2)
  end
end

SetSuppressed = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2, A9_2, A10_2, A11_2, A12_2, A13_2)
  local L14_2, L15_2
  L14_2 = {}
  L14_2.sName = A1_2
  L15_2 = A2_2 or L15_2
  if not A2_2 then
    L15_2 = 0
  end
  L14_2.nX = L15_2
  L15_2 = A3_2 or L15_2
  if not A3_2 then
    L15_2 = 0
  end
  L14_2.nY = L15_2
  L14_2.sLabel = A4_2
  L14_2.sDesc = A5_2
  L14_2.uGuid = A6_2
  L14_2.sTexture = A7_2
  L14_2.sMission = A8_2
  L14_2.nMeter = A9_2
  L14_2.bSticky = A10_2
  L14_2.bTodoList = A11_2
  L14_2.sFaction = A12_2
  L14_2.nSortOrder = A13_2
  L15_2 = A0_2.CustomData
  L15_2 = L15_2.tMapBlips
  L15_2[A1_2] = L14_2
end

AddMapBlip = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.tMapBlips
  L2_2[A1_2] = nil
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bActive
  if L2_2 then
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.oMapFlash
    if L2_2 then
      L2_2 = _GuiInternal
      L2_2 = L2_2.RemovePdaBlip
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.oMapFlash
      L3_2 = L3_2.BasicData
      L3_2 = L3_2.uId
      L4_2 = A1_2
      L2_2(L3_2, L4_2)
    end
  end
end

RemoveMapBlip = L0_1
L0_1 = 1
_nMissionCount = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2, A9_2)
  local L10_2, L11_2, L12_2, L13_2, L14_2
  L10_2 = A0_2.CustomData
  L10_2 = L10_2.tMissions
  L11_2 = type
  L12_2 = A1_2
  L11_2 = L11_2(L12_2)
  if "string" ~= L11_2 then
    L11_2 = false
    return L11_2
  end
  L11_2 = nil
  L12_2 = L10_2[A1_2]
  if L12_2 then
    L11_2 = L10_2[A1_2]
    L12_2 = A2_2 or L12_2
    if not A2_2 then
      L12_2 = L11_2.sLabel
    end
    L11_2.sLabel = L12_2
    L12_2 = A3_2 or L12_2
    if not A3_2 then
      L12_2 = L11_2.sDesc
    end
    L11_2.sDesc = L12_2
    L12_2 = A4_2 or L12_2
    if not A4_2 then
      L12_2 = L11_2.sFaction
    end
    L11_2.sFaction = L12_2
    L12_2 = A5_2 or L12_2
    if not A5_2 then
      L12_2 = L11_2.sDefaultBlipTexture
    end
    L11_2.sDefaultBlipTexture = L12_2
    L12_2 = A6_2 or L12_2
    if not A6_2 then
      L12_2 = L11_2.sDefaultBlipLabel
    end
    L11_2.sDefaultBlipLabel = L12_2
    L12_2 = A7_2 or L12_2
    if not A7_2 then
      L12_2 = L11_2.bSuppress
    end
    L11_2.bSuppress = L12_2
    L12_2 = A9_2 or L12_2
    if not A9_2 then
      L12_2 = L11_2.nSortOrder
    end
    L11_2.nSortOrder = L12_2
    if A7_2 then
      A8_2 = false
    elseif nil == A8_2 then
      A8_2 = L11_2.bTrackable
    end
    L12_2 = A8_2 or L12_2
    if not A8_2 then
      L12_2 = false
    end
    L11_2.bTrackable = L12_2
    if A7_2 then
      L11_2.sFaction = " "
    end
  else
    if not A7_2 then
      L12_2 = type
      L13_2 = A2_2
      L12_2 = L12_2(L13_2)
      if "string" == L12_2 then
        L12_2 = type
        L13_2 = A3_2
        L12_2 = L12_2(L13_2)
        if "string" == L12_2 then
          L12_2 = type
          L13_2 = A4_2
          L12_2 = L12_2(L13_2)
          if "string" == L12_2 then
            goto lbl_77
          end
        end
      end
      L12_2 = false
      return L12_2
    end
    ::lbl_77::
    if A7_2 then
      A8_2 = false
    elseif nil == A8_2 then
      A8_2 = true
    end
    L12_2 = tostring
    L13_2 = _nMissionCount
    L12_2 = L12_2(L13_2)
    L13_2 = _nMissionCount
    L13_2 = L13_2 + 1
    _nMissionCount = L13_2
    L13_2 = {}
    L14_2 = A2_2 or L14_2
    if not A2_2 then
      L14_2 = " "
    end
    L13_2.sLabel = L14_2
    L14_2 = A3_2 or L14_2
    if not A3_2 then
      L14_2 = " "
    end
    L13_2.sDesc = L14_2
    L13_2.sFaction = A4_2
    L14_2 = A5_2 or L14_2
    if not A5_2 then
      L14_2 = "icon_yellow_mc"
    end
    L13_2.sDefaultBlipTexture = L14_2
    L14_2 = A6_2 or L14_2
    if not A6_2 then
      L14_2 = "DESIGNER ERROR"
    end
    L13_2.sDefaultBlipLabel = L14_2
    L14_2 = A7_2 or L14_2
    if not A7_2 then
      L14_2 = false
    end
    L13_2.bSuppress = L14_2
    L14_2 = A8_2 or L14_2
    if not A8_2 then
      L14_2 = false
    end
    L13_2.bTrackable = L14_2
    L13_2.sId = L12_2
    L13_2.nSortOrder = A9_2
    L11_2 = L13_2
    if A7_2 then
      L11_2.sFaction = " "
    end
    L10_2[A1_2] = L11_2
    L13_2 = A0_2.CustomData
    L13_2 = L13_2.tMissionIds
    L13_2[L12_2] = A1_2
  end
  L12_2 = true
  return L12_2
end

AddMapMission = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.tMissions
  L3_2 = type
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if "string" ~= L3_2 then
    return
  end
  L3_2 = L2_2[A1_2]
  if L3_2 then
    L4_2 = L3_2.sId
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.tMissionIds
    L5_2[L4_2] = nil
    L3_2 = nil
  end
  L2_2[A1_2] = nil
  L4_2 = {}
  L5_2 = pairs
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.tMapBlips
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = L9_2.sMission
    if A1_2 == L10_2 then
      L10_2 = table
      L10_2 = L10_2.insert
      L11_2 = L4_2
      L12_2 = L8_2
      L10_2(L11_2, L12_2)
    end
  end
  L5_2 = pairs
  L6_2 = L4_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L11_2 = A0_2
    L10_2 = A0_2.RemoveMapBlip
    L12_2 = L9_2
    L10_2(L11_2, L12_2)
  end
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.sSelectedMission
  if L5_2 == A1_2 then
    L5_2 = SetSelectedMission
    L6_2 = A0_2
    L7_2 = nil
    L8_2 = true
    L5_2(L6_2, L7_2, L8_2)
  end
end

RemoveMapMission = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2)
  local L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L9_2 = AddMapMission
  L10_2 = A0_2
  L11_2 = A1_2
  L12_2 = A2_2
  L13_2 = A3_2
  L14_2 = A4_2
  L15_2 = A5_2
  L16_2 = A6_2
  L17_2 = A7_2
  L18_2 = bTrackable
  L19_2 = A8_2
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
end

UpdateMapMission = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.tMissions
  L3_2 = L3_2[A1_2]
  if L3_2 then
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.tMissions
    L3_2 = L3_2[A1_2]
    L4_2 = L3_2.bSuppress
    if L4_2 then
      A2_2 = false
    end
    L4_2 = A2_2 or L4_2
    if not A2_2 then
      L4_2 = false
    end
    L3_2.bTrackable = L4_2
  end
end

SetMissionTrackable = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2)
  local L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  if A1_2 then
    L7_2 = A0_2.CustomData
    L7_2 = L7_2.tRegions
    L7_2 = L7_2[A1_2]
    if not L7_2 then
      L7_2 = {}
    end
    L8_2 = A2_2
    L9_2 = A3_2
    L10_2 = A4_2
    L11_2 = A5_2
    L12_2 = _Clamp
    L13_2 = L8_2
    L14_2 = 0
    L15_2 = 255
    L12_2 = L12_2(L13_2, L14_2, L15_2)
    L8_2 = L12_2
    L12_2 = _Clamp
    L13_2 = L9_2
    L14_2 = 0
    L15_2 = 255
    L12_2 = L12_2(L13_2, L14_2, L15_2)
    L9_2 = L12_2
    L12_2 = _Clamp
    L13_2 = L10_2
    L14_2 = 0
    L15_2 = 255
    L12_2 = L12_2(L13_2, L14_2, L15_2)
    L10_2 = L12_2
    L12_2 = _Clamp
    L13_2 = L11_2
    L14_2 = 0
    L15_2 = 255
    L12_2 = L12_2(L13_2, L14_2, L15_2)
    L11_2 = L12_2
    if not L8_2 then
      L8_2 = 64
    end
    if not L9_2 then
      L9_2 = 64
    end
    if not L10_2 then
      L10_2 = 160
    end
    if not L11_2 then
      L11_2 = 128
    end
    L12_2 = L11_2 / 255
    L11_2 = L12_2 * 100
    L12_2 = "0x"
    L13_2 = string
    L13_2 = L13_2.format
    L14_2 = "%02X"
    L15_2 = L8_2
    L13_2 = L13_2(L14_2, L15_2)
    L14_2 = string
    L14_2 = L14_2.format
    L15_2 = "%02X"
    L16_2 = L9_2
    L14_2 = L14_2(L15_2, L16_2)
    L15_2 = string
    L15_2 = L15_2.format
    L16_2 = "%02X"
    L17_2 = L10_2
    L15_2 = L15_2(L16_2, L17_2)
    L12_2 = L12_2 .. L13_2 .. L14_2 .. L15_2
    L7_2.sColor = L12_2
    L7_2.nAlpha = L11_2
    L7_2.bInvert = A6_2
    L12_2 = A0_2.CustomData
    L12_2 = L12_2.tRegions
    L12_2[A1_2] = L7_2
  end
end

AddLineRegion = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  if A0_2 then
    L3_2 = type
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
    if "number" == L3_2 then
      goto lbl_9
    end
  end
  do return end
  ::lbl_9::
  if A2_2 < A0_2 then
    return A2_2
  end
  if A0_2 < A1_2 then
    return A1_2
  end
  return A0_2
end

_Clamp = L0_1

function L0_1(A0_2, A1_2)
  local L2_2
  if A1_2 then
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.tRegions
    L2_2[A1_2] = nil
  end
end

RemoveLineRegion = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = Net
  L3_2 = L3_2.IsClient
  L3_2 = L3_2()
  if L3_2 and A2_2 ~= true then
    return
  end
  if A1_2 then
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.tMissions
    L3_2 = L3_2[A1_2]
    if L3_2 then
      L3_2 = A0_2.CustomData
      L3_2.sSelectedMission = A1_2
  end
  else
    L3_2 = A0_2.CustomData
    L3_2.sSelectedMission = nil
  end
  L3_2 = Net
  L3_2 = L3_2.IsServer
  L3_2 = L3_2()
  if L3_2 then
    L3_2 = Net
    L3_2 = L3_2.SendCustomEvent
    L4_2 = "MrxGuiPda"
    L5_2 = NETEVENT_SETSELECTEDMISSION
    L6_2 = {}
    L7_2 = WifMissionData
    L7_2 = L7_2.GetMissionIndexFromId
    L8_2 = A0_2.CustomData
    L8_2 = L8_2.sSelectedMission
    L7_2, L8_2 = L7_2(L8_2)
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L3_2(L4_2, L5_2, L6_2)
  end
end

SetSelectedMission = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.sSelectedMission
  return L1_2
end

GetSelectedMission = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  L3_2 = type
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if "function" == L3_2 or nil == A1_2 then
    L3_2 = A0_2.CustomData
    L3_2.fMissionChangeCallback = A1_2
    L3_2 = A0_2.CustomData
    L3_2.tMissionChangeData = A2_2
  end
end

SetMissionTrackCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2
  L2_2 = Net
  L2_2 = L2_2.IsClient
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = A0_2.CustomData
    L2_2.bAllowTrackingChange = false
  else
    L2_2 = A0_2.CustomData
    L2_2.bAllowTrackingChange = A1_2
  end
end

SetMissionChangeAllowed = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2
  if nil == A1_2 then
    L4_2 = A0_2.CustomData
    L4_2.nFakePlayerX = nil
    L4_2 = A0_2.CustomData
    L4_2.nFakePlayerY = nil
    L4_2 = A0_2.CustomData
    L4_2.nFakePlayerZ = nil
    return
  end
  L4_2 = type
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  if "number" == L4_2 then
    L4_2 = type
    L5_2 = A2_2
    L4_2 = L4_2(L5_2)
    if "number" == L4_2 then
      L4_2 = type
      L5_2 = A3_2
      L4_2 = L4_2(L5_2)
      if "number" == L4_2 then
        L4_2 = A0_2.CustomData
        L4_2.nFakePlayerX = A1_2
        L4_2 = A0_2.CustomData
        L4_2.nFakePlayerY = A2_2
        L4_2 = A0_2.CustomData
        L4_2.nFakePlayerZ = A3_2
      end
    end
  end
end

SetFakePlayerLocation = L0_1

function L0_1(A0_2, A1_2)
  local L2_2
  L2_2 = A0_2.CustomData
  L2_2.bBeaconTutorialMode = A1_2
end

SetBeaconTutorialMode = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2, L47_2, L48_2, L49_2, L50_2, L51_2
  if nil == A2_2 then
    A2_2 = true
  end
  L5_2 = 0
  L6_2 = Player
  L6_2 = L6_2.GetCamera
  L8_2 = A0_2
  L7_2 = A0_2.GetOwner
  L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2, L47_2, L48_2, L49_2, L50_2, L51_2 = L7_2(L8_2)
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2, L47_2, L48_2, L49_2, L50_2, L51_2)
  if L6_2 then
    L7_2 = Camera
    L7_2 = L7_2.GetYaw
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    L5_2 = L7_2
  end
  if not A3_2 then
    L7_2 = _knBlipLimit
    A3_2 = L7_2 * 0.5
  end
  if A3_2 < 0 then
    L7_2 = _knBlipLimit
    A3_2 = L7_2 * 0.5
  end
  L7_2 = 35
  L8_2 = 40
  L9_2 = 1
  L10_2 = nil
  L11_2 = nil
  L12_2 = " "
  L13_2 = A0_2.CustomData
  L13_2 = L13_2.sSelectedMission
  if L13_2 then
    L13_2 = A0_2.CustomData
    L13_2 = L13_2.tMissions
    L14_2 = A0_2.CustomData
    L14_2 = L14_2.sSelectedMission
    L10_2 = L13_2[L14_2]
    if L10_2 then
      L13_2 = L10_2.bSuppress
      if not L13_2 then
        L11_2 = L10_2.sDesc
        L12_2 = "[PDA.Map.CurrentMission]"
      end
    end
  end
  L14_2 = A0_2
  L13_2 = A0_2.GetOwner
  L13_2 = L13_2(L14_2)
  L14_2 = A0_2.CustomData
  L14_2 = L14_2.oMapFlash
  L14_2 = L14_2.BasicData
  L14_2 = L14_2.uId
  L15_2 = Player
  L15_2 = L15_2.GetCharacter
  L16_2 = L13_2
  L15_2 = L15_2(L16_2)
  L13_2 = L15_2
  L15_2 = nil
  L16_2 = nil
  L17_2 = nil
  L18_2 = A0_2.CustomData
  L18_2 = L18_2.nFakePlayerX
  if L18_2 then
    L18_2 = A0_2.CustomData
    L15_2 = L18_2.nFakePlayerX
    L18_2 = A0_2.CustomData
    L16_2 = L18_2.nFakePlayerY
    L18_2 = A0_2.CustomData
    L17_2 = L18_2.nFakePlayerZ
  else
    L18_2 = Object
    L18_2 = L18_2.GetPosition
    L19_2 = L13_2
    L18_2, L19_2, L20_2 = L18_2(L19_2)
    L17_2 = L20_2
    L16_2 = L19_2
    L15_2 = L18_2
  end
  if not A1_2 then
    L18_2 = A0_2.CustomData
    A1_2 = L18_2.oMapFlash
  end
  L18_2 = {}
  L19_2 = nil
  L20_2 = string
  L20_2 = L20_2.format
  L21_2 = "[PDA.Map.Player:%d]"
  L22_2 = 1
  L20_2 = L20_2(L21_2, L22_2)
  L21_2 = {}
  L22_2 = "player1_mc"
  L23_2 = "player1_mc"
  L24_2 = L15_2 + L7_2
  L25_2 = L17_2 + L8_2
  L26_2 = math
  L26_2 = L26_2.rad
  L27_2 = L5_2
  L26_2 = L26_2(L27_2)
  L27_2 = L20_2
  L28_2 = L11_2 or L28_2
  if not L11_2 then
    L28_2 = L20_2
  end
  L29_2 = " "
  L30_2 = " "
  L31_2 = false
  L32_2 = "  "
  L33_2 = L12_2
  L34_2 = true
  L35_2 = false
  L36_2 = false
  L21_2[1] = L22_2
  L21_2[2] = L23_2
  L21_2[3] = L24_2
  L21_2[4] = L25_2
  L21_2[5] = L26_2
  L21_2[6] = L27_2
  L21_2[7] = L28_2
  L21_2[8] = L29_2
  L21_2[9] = L30_2
  L21_2[10] = L31_2
  L21_2[11] = L32_2
  L21_2[12] = L33_2
  L21_2[13] = L34_2
  L21_2[14] = L35_2
  L21_2[15] = L36_2
  L19_2 = L21_2
  L21_2 = table
  L21_2 = L21_2.insert
  L22_2 = L18_2
  L23_2 = L19_2
  L21_2(L22_2, L23_2)
  L21_2 = {}
  L21_2.bNoMission = true
  L21_2.sId = ""
  L21_2.sLabel = ""
  L22_2 = {}
  L22_2.bNoMission = true
  L22_2.sId = "m"
  L23_2 = false
  L24_2 = false
  L25_2 = nil
  L26_2 = {}
  L27_2 = pairs
  L28_2 = A0_2.CustomData
  L28_2 = L28_2.tMissions
  L27_2, L28_2, L29_2 = L27_2(L28_2)
  for L30_2, L31_2 in L27_2, L28_2, L29_2 do
    L32_2 = L31_2.bSuppress
    if not L32_2 then
      L32_2 = table
      L32_2 = L32_2.insert
      L33_2 = L26_2
      L34_2 = L31_2
      L32_2(L33_2, L34_2)
    end
  end
  L27_2 = table
  L27_2 = L27_2.sort
  L28_2 = L26_2
  L29_2 = _MissionSortLessThan
  L27_2(L28_2, L29_2)
  L27_2 = pairs
  L28_2 = L26_2
  L27_2, L28_2, L29_2 = L27_2(L28_2)
  for L30_2, L31_2 in L27_2, L28_2, L29_2 do
    L32_2 = _tFactionNameLookup
    L33_2 = L31_2.sFaction
    L25_2 = L32_2[L33_2]
    L32_2 = {}
    L33_2 = L31_2.sLabel
    L34_2 = L31_2.sDefaultBlipTexture
    L35_2 = 10000
    L36_2 = 10000
    L37_2 = 0
    L38_2 = L31_2.sLabel
    L39_2 = L31_2.sDesc
    L40_2 = L31_2.sFaction
    L41_2 = L25_2
    L42_2 = true
    L43_2 = L31_2.sId
    L44_2 = L31_2.sLabel
    L45_2 = false
    L46_2 = false
    L32_2[1] = L33_2
    L32_2[2] = L34_2
    L32_2[3] = L35_2
    L32_2[4] = L36_2
    L32_2[5] = L37_2
    L32_2[6] = L38_2
    L32_2[7] = L39_2
    L32_2[8] = L40_2
    L32_2[9] = L41_2
    L32_2[10] = L42_2
    L32_2[11] = L43_2
    L32_2[12] = L44_2
    L32_2[13] = L45_2
    L32_2[14] = L46_2
    L19_2 = L32_2
    if not A4_2 then
      L32_2 = table
      L32_2 = L32_2.insert
      L33_2 = L18_2
      L34_2 = L19_2
      L32_2(L33_2, L34_2)
    end
  end
  L27_2 = false
  L28_2 = 5
  L29_2 = 1
  L30_2 = {}
  L31_2 = L28_2
  L32_2 = L29_2
  L33_2 = -1
  for L34_2 = L31_2, L32_2, L33_2 do
    L35_2 = {}
    L30_2[L34_2] = L35_2
  end
  L31_2 = pairs
  L32_2 = A0_2.CustomData
  L32_2 = L32_2.tMapBlips
  L31_2, L32_2, L33_2 = L31_2(L32_2)
  for L34_2, L35_2 in L31_2, L32_2, L33_2 do
    L36_2 = L35_2.nSortOrder
    if L36_2 then
      L36_2 = L35_2.nSortOrder
      L36_2 = L30_2[L36_2]
      if L36_2 then
        L36_2 = table
        L36_2 = L36_2.insert
        L37_2 = L35_2.nSortOrder
        L37_2 = L30_2[L37_2]
        L38_2 = L35_2
        L36_2(L37_2, L38_2)
    end
    else
      L36_2 = table
      L36_2 = L36_2.insert
      L37_2 = L30_2[L28_2]
      L38_2 = L35_2
      L36_2(L37_2, L38_2)
    end
  end
  L31_2 = {}
  L32_2 = L28_2
  L33_2 = L29_2
  L34_2 = -1
  for L35_2 = L32_2, L33_2, L34_2 do
    L36_2 = pairs
    L37_2 = L30_2[L35_2]
    L36_2, L37_2, L38_2 = L36_2(L37_2)
    for L39_2, L40_2 in L36_2, L37_2, L38_2 do
      L41_2 = table
      L41_2 = L41_2.insert
      L42_2 = L31_2
      L43_2 = L40_2
      L41_2(L42_2, L43_2)
    end
  end
  L32_2 = 0
  L33_2 = 1
  L34_2 = #L31_2
  if A3_2 < L34_2 then
    L34_2 = #L31_2
    L35_2 = A3_2 + 1
    L33_2 = L34_2 - L35_2
  end
  while true do
    L34_2 = L31_2[L33_2]
    if not L34_2 then
      break
    end
    L34_2 = L31_2[L33_2]
    L21_2.sFaction = nil
    L25_2 = nil
    L35_2 = L34_2.uGuid
    if L35_2 then
      L35_2 = Object
      L35_2 = L35_2.GetPosition
      L36_2 = L34_2.uGuid
      L35_2, L36_2, L37_2 = L35_2(L36_2)
      if L35_2 and L37_2 then
        L34_2.nX = L35_2
        L34_2.nY = L37_2
      end
    end
    L35_2 = nil
    L36_2 = L34_2.bSticky
    L23_2 = L36_2 or L23_2
    if not L36_2 then
      L23_2 = false
    end
    L24_2 = false
    L36_2 = L34_2.sMission
    if L36_2 then
      L36_2 = A0_2.CustomData
      L36_2 = L36_2.tMissions
      L37_2 = L34_2.sMission
      L36_2 = L36_2[L37_2]
      L35_2 = L36_2 or L35_2
      if not L36_2 then
        L35_2 = L21_2
      end
      L36_2 = L34_2.bSticky
      if nil ~= L36_2 then
        L23_2 = L34_2.bSticky
      else
        L36_2 = A0_2.CustomData
        L36_2 = L36_2.sSelectedMission
        if L36_2 then
          L36_2 = A0_2.CustomData
          L36_2 = L36_2.sSelectedMission
          L37_2 = L34_2.sMission
          if L36_2 == L37_2 then
            L23_2 = true
          end
        end
      end
      L36_2 = A0_2.CustomData
      L36_2 = L36_2.bAllowTrackingChange
      if L36_2 then
        L24_2 = L35_2.bTrackable
      end
      L36_2 = L35_2.bSuppress
      if L36_2 then
        L35_2 = L21_2
      end
    else
      L36_2 = L34_2.bTodoList
      if L36_2 then
        L35_2 = L22_2
        L36_2 = L34_2.sFaction
        L22_2.sFaction = L36_2
        L36_2 = L34_2.sName
        L22_2.sId = L36_2
        L36_2 = L34_2.sLabel
        L22_2.sLabel = L36_2
      else
        L35_2 = L21_2
      end
    end
    L36_2 = L35_2.sFaction
    if L36_2 then
      L36_2 = _tFactionNameLookup
      L37_2 = L35_2.sFaction
      L25_2 = L36_2[L37_2]
    else
      L36_2 = L34_2.sFaction
      if L36_2 then
        L36_2 = _tFactionNameLookup
        L37_2 = L34_2.sFaction
        L25_2 = L36_2[L37_2]
      end
    end
    L27_2 = false
    L36_2 = L35_2.bNoMission
    if not L36_2 then
      L36_2 = L35_2.bTrackable
      if L36_2 then
        L27_2 = true
      end
    end
    L36_2 = {}
    L37_2 = L34_2.sName
    L38_2 = L34_2.sTexture
    if not L38_2 then
      L38_2 = L35_2.sDefaultBlipTexture
      if not L38_2 then
        L38_2 = "icon_yellow_mc"
      end
    end
    L39_2 = L34_2.nX
    L39_2 = L39_2 + L7_2
    L40_2 = L34_2.nY
    L40_2 = L40_2 + L8_2
    L41_2 = 0
    L42_2 = L34_2.sLabel
    if not L42_2 then
      L42_2 = L35_2.sDefaultBlipLabel
    end
    L43_2 = L34_2.sDesc
    if not L43_2 then
      L43_2 = L35_2.sDesc
    end
    L44_2 = L35_2.sFaction
    if not L44_2 then
      L44_2 = L34_2.sFaction
    end
    L45_2 = L25_2
    L46_2 = L27_2
    L47_2 = L35_2.sId
    L48_2 = L35_2.sLabel
    L49_2 = L23_2
    L50_2 = L24_2
    L51_2 = L23_2
    L36_2[1] = L37_2
    L36_2[2] = L38_2
    L36_2[3] = L39_2
    L36_2[4] = L40_2
    L36_2[5] = L41_2
    L36_2[6] = L42_2
    L36_2[7] = L43_2
    L36_2[8] = L44_2
    L36_2[9] = L45_2
    L36_2[10] = L46_2
    L36_2[11] = L47_2
    L36_2[12] = L48_2
    L36_2[13] = L49_2
    L36_2[14] = L50_2
    L36_2[15] = L51_2
    L19_2 = L36_2
    L36_2 = L19_2[2]
    if A4_2 then
      if "icon_action_3_mc" ~= L36_2 and "icon_outpost_3_mc" ~= L36_2 and "icon_defend_3_mc" ~= L36_2 and "icon_destroy_3_mc" ~= L36_2 and "icon_verify_3_mc" ~= L36_2 and "icon_deliverable_3_mc" ~= L36_2 then
        L37_2 = table
        L37_2 = L37_2.insert
        L38_2 = L18_2
        L39_2 = L19_2
        L37_2(L38_2, L39_2)
      end
    else
      L37_2 = table
      L37_2 = L37_2.insert
      L38_2 = L18_2
      L39_2 = L19_2
      L37_2(L38_2, L39_2)
    end
    L33_2 = L33_2 + 1
  end
  L34_2 = {}
  L35_2 = "marker_mc"
  L36_2 = "marker_mc"
  L37_2 = A0_2.CustomData
  L37_2 = L37_2.nMarkerX
  if not L37_2 then
    L37_2 = L15_2
  end
  L38_2 = A0_2.CustomData
  L38_2 = L38_2.nMarkerZ
  if not L38_2 then
    L38_2 = L17_2
  end
  L39_2 = 0
  L40_2 = "MARKER"
  L41_2 = "Destination Marker"
  L42_2 = "  "
  L43_2 = "  "
  L44_2 = false
  L45_2 = "  "
  L46_2 = "  "
  L47_2 = true
  L48_2 = false
  L49_2 = false
  L34_2[1] = L35_2
  L34_2[2] = L36_2
  L34_2[3] = L37_2
  L34_2[4] = L38_2
  L34_2[5] = L39_2
  L34_2[6] = L40_2
  L34_2[7] = L41_2
  L34_2[8] = L42_2
  L34_2[9] = L43_2
  L34_2[10] = L44_2
  L34_2[11] = L45_2
  L34_2[12] = L46_2
  L34_2[13] = L47_2
  L34_2[14] = L48_2
  L34_2[15] = L49_2
  L19_2 = L34_2
  L34_2 = table
  L34_2 = L34_2.insert
  L35_2 = L18_2
  L36_2 = L19_2
  L34_2(L35_2, L36_2)
  L34_2 = _GuiInternal
  L34_2 = L34_2.AddPdaMapBlips
  L35_2 = A1_2.BasicData
  L35_2 = L35_2.uId
  L36_2 = L18_2
  L34_2(L35_2, L36_2)
  L34_2 = AddPDATargetMarkers
  L35_2 = A0_2
  L34_2(L35_2)
  L34_2 = A0_2.CustomData
  L34_2 = L34_2.nMarkerX
  if L34_2 then
    L34_2 = A0_2.CustomData
    L34_2 = L34_2.nMarkerZ
    if L34_2 then
      L35_2 = A1_2
      L34_2 = A1_2.CallActionScriptCallback
      L36_2 = "SetMarker"
      L37_2 = {}
      L38_2 = true
      L37_2[1] = L38_2
      L34_2(L35_2, L36_2, L37_2)
  end
  else
    L35_2 = A1_2
    L34_2 = A1_2.CallActionScriptCallback
    L36_2 = "SetMarker"
    L37_2 = {}
    L38_2 = false
    L37_2[1] = L38_2
    L34_2(L35_2, L36_2, L37_2)
  end
  L34_2 = UpdateAllPlayerMarkers
  L35_2 = A0_2
  L34_2(L35_2)
  L34_2 = _DisplayRegions
  L35_2 = A0_2
  L36_2 = L7_2
  L37_2 = L8_2
  L34_2(L35_2, L36_2, L37_2)
  L34_2 = nil
  L35_2 = A0_2.CustomData
  L35_2 = L35_2.sSelectedMission
  if L35_2 then
    L35_2 = A0_2.CustomData
    L35_2 = L35_2.bAllowTrackingChange
    if not L35_2 then
      L35_2 = A0_2.CustomData
      L35_2 = L35_2.tMissions
      L36_2 = A0_2.CustomData
      L36_2 = L36_2.sSelectedMission
      L35_2 = L35_2[L36_2]
      if L35_2 then
        L34_2 = L35_2.sId
      end
    end
  end
  L36_2 = A1_2
  L35_2 = A1_2.SetFlashEventHandler
  L37_2 = "beaconCheck"
  L38_2 = HandleBeaconCheck
  L39_2 = {}
  L40_2 = A1_2
  L39_2[1] = L40_2
  L35_2(L36_2, L37_2, L38_2, L39_2)
  L35_2 = A0_2.CustomData
  L35_2 = L35_2.bBeaconTutorialMode
  if L35_2 then
    L36_2 = A1_2
    L35_2 = A1_2.CallActionScriptCallback
    L37_2 = "beaconTutorial"
    L38_2 = {}
    L35_2(L36_2, L37_2, L38_2)
  end
  if A2_2 then
    L36_2 = A1_2
    L35_2 = A1_2.CallActionScriptCallback
    L37_2 = "LandingZone"
    L38_2 = {}
    L39_2 = false
    L38_2[1] = L39_2
    L35_2(L36_2, L37_2, L38_2)
    if L34_2 then
      L36_2 = A1_2
      L35_2 = A1_2.CallActionScriptCallback
      L37_2 = "activeContract"
      L38_2 = {}
      L39_2 = L34_2
      L38_2[1] = L39_2
      L35_2(L36_2, L37_2, L38_2)
    end
    L36_2 = A1_2
    L35_2 = A1_2.CallActionScriptCallback
    L37_2 = "AddBlipFinish"
    L38_2 = {}
    L35_2(L36_2, L37_2, L38_2)
  end
end

_PopulateMapDisplay = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = A0_2.nSortOrder
  if not L2_2 then
    L2_2 = false
    return L2_2
  else
    L2_2 = A1_2.nSortOrder
    if not L2_2 then
      L2_2 = true
      return L2_2
    end
  end
  L2_2 = A0_2.nSortOrder
  L3_2 = A1_2.nSortOrder
  L2_2 = L2_2 < L3_2
  return L2_2
end

_MissionSortLessThan = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L4_2 = {}
  L5_2 = 1
  L6_2 = string
  L6_2 = L6_2.gmatch
  L7_2 = A1_2
  L8_2 = "-*%d+"
  L6_2, L7_2, L8_2 = L6_2(L7_2, L8_2)
  for L9_2 in L6_2, L7_2, L8_2 do
    L10_2 = tonumber
    L11_2 = L9_2
    L10_2 = L10_2(L11_2)
    L4_2[L5_2] = L10_2
    L5_2 = L5_2 + 1
  end
  L6_2 = L4_2[1]
  if L6_2 then
    L6_2 = L4_2[2]
    if L6_2 then
      L6_2 = L4_2[1]
      L2_2 = L6_2 * 2
      L6_2 = L4_2[2]
      L3_2 = L6_2 * 2
    end
  end
  L6_2 = type
  L7_2 = L2_2
  L6_2 = L6_2(L7_2)
  if "number" == L6_2 then
    L6_2 = type
    L7_2 = L3_2
    L6_2 = L6_2(L7_2)
    if "number" == L6_2 then
      L6_2 = Player
      L6_2 = L6_2.IsPositionOutBoundary
      if L6_2 then
        L6_2 = 35
        L7_2 = 40
        L8_2 = Player
        L8_2 = L8_2.IsPositionOutBoundary
        L9_2 = Player
        L9_2 = L9_2.GetLocalPlayer
        L9_2 = L9_2()
        L10_2 = L2_2 * 0.5
        L10_2 = L10_2 - L6_2
        L11_2 = 0
        L12_2 = L3_2 * 0.5
        L12_2 = L12_2 - L7_2
        L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
        if not L8_2 then
          L9_2 = A0_2
          L8_2 = A0_2.CallActionScriptCallback
          L10_2 = "beaconCheckReturn"
          L11_2 = {}
          L12_2 = true
          L11_2[1] = L12_2
          L8_2(L9_2, L10_2, L11_2)
          return
        end
      end
    end
  end
  L7_2 = A0_2
  L6_2 = A0_2.CallActionScriptCallback
  L8_2 = "beaconCheckReturn"
  L9_2 = {}
  L10_2 = false
  L9_2[1] = L10_2
  L6_2(L7_2, L8_2, L9_2)
end

HandleBeaconCheck = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  if not A1_2 then
    A1_2 = 0
  end
  if not A2_2 then
    A2_2 = 0
  end
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oMapFlash
  L4_2 = 1
  L5_2 = pairs
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.tRegions
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = _DisplayRegion
    L11_2 = L3_2
    L12_2 = L8_2
    L13_2 = L4_2
    L14_2 = L9_2.sColor
    L15_2 = L9_2.nAlpha
    L16_2 = A1_2
    L17_2 = A2_2
    L18_2 = L9_2.bInvert
    L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
    L4_2 = L4_2 + 1
  end
end

_DisplayRegions = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2)
  local L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2
  L8_2 = Pg
  L8_2 = L8_2.GetLineRegionPoints
  L9_2 = A1_2
  L10_2 = A7_2
  L8_2, L9_2 = L8_2(L9_2, L10_2)
  L10_2 = nil
  L11_2 = true
  L12_2 = ipairs
  L13_2 = L8_2
  L12_2, L13_2, L14_2 = L12_2(L13_2)
  for L15_2, L16_2 in L12_2, L13_2, L14_2 do
    L10_2 = L9_2[L15_2]
    if L11_2 then
      L18_2 = A0_2
      L17_2 = A0_2.CallActionScriptCallback
      L19_2 = "AddZone"
      L20_2 = {}
      L21_2 = A2_2
      L22_2 = true
      L23_2 = false
      L24_2 = L16_2 + A5_2
      L25_2 = L10_2 + A6_2
      L26_2 = A3_2
      L27_2 = A4_2
      L20_2[1] = L21_2
      L20_2[2] = L22_2
      L20_2[3] = L23_2
      L20_2[4] = L24_2
      L20_2[5] = L25_2
      L20_2[6] = L26_2
      L20_2[7] = L27_2
      L17_2(L18_2, L19_2, L20_2)
      L11_2 = false
    else
      L18_2 = A0_2
      L17_2 = A0_2.CallActionScriptCallback
      L19_2 = "AddZone"
      L20_2 = {}
      L21_2 = A2_2
      L22_2 = false
      L23_2 = false
      L24_2 = L16_2 + A5_2
      L25_2 = L10_2 + A6_2
      L20_2[1] = L21_2
      L20_2[2] = L22_2
      L20_2[3] = L23_2
      L20_2[4] = L24_2
      L20_2[5] = L25_2
      L17_2(L18_2, L19_2, L20_2)
    end
  end
  L13_2 = A0_2
  L12_2 = A0_2.CallActionScriptCallback
  L14_2 = "AddZone"
  L15_2 = {}
  L16_2 = A2_2
  L17_2 = false
  L18_2 = true
  L15_2[1] = L16_2
  L15_2[2] = L17_2
  L15_2[3] = L18_2
  L12_2(L13_2, L14_2, L15_2)
end

_DisplayRegion = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2.oParentWidget
  L3_2 = L2_2.CustomData
  L3_2 = L3_2.tMissionIds
  L3_2 = L3_2[A1_2]
  L5_2 = L2_2
  L4_2 = L2_2.SetSelectedMission
  L6_2 = L3_2
  L4_2(L5_2, L6_2)
  L4_2 = L2_2.CustomData
  L4_2 = L4_2.fMissionChangeCallback
  if L4_2 then
    L4_2 = {}
    L5_2 = L2_2.CustomData
    L5_2 = L5_2.tMissionChangeData
    if L5_2 then
      L5_2 = ipairs
      L6_2 = L2_2.CustomData
      L6_2 = L6_2.tMissionChangeData
      L5_2, L6_2, L7_2 = L5_2(L6_2)
      for L8_2, L9_2 in L5_2, L6_2, L7_2 do
        L4_2[L8_2] = L9_2
      end
    end
    L5_2 = table
    L5_2 = L5_2.insert
    L6_2 = L4_2
    L7_2 = L3_2
    L5_2(L6_2, L7_2)
    L5_2 = L2_2.CustomData
    L5_2 = L5_2.fMissionChangeCallback
    L6_2 = unpack
    L7_2 = L4_2
    L6_2, L7_2, L8_2, L9_2, L10_2 = L6_2(L7_2)
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  end
end

_HandleTrackEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2.oParentWidget
  L4_2 = L2_2
  L3_2 = L2_2.SetSelectedMission
  L5_2 = nil
  L3_2(L4_2, L5_2)
  L3_2 = L2_2.CustomData
  L3_2 = L3_2.fMissionChangeCallback
  if L3_2 then
    L3_2 = L2_2.CustomData
    L3_2 = L3_2.tMissionChangeData
    if not L3_2 then
      L3_2 = {}
    end
    L4_2 = L2_2.CustomData
    L4_2 = L4_2.fMissionChangeCallback
    L5_2 = unpack
    L6_2 = L3_2
    L5_2, L6_2 = L5_2(L6_2)
    L4_2(L5_2, L6_2)
  end
end

_HandleUntrackEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = MrxPlayState
  L2_2 = L2_2.GetCurrentMission
  L2_2 = L2_2()
  if L2_2 then
    L4_2 = L2_2
    L3_2 = L2_2.Cancel
    L3_2(L4_2)
  end
end

_HandleMissionCancel = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2.CustomData
  L3_2 = A1_2.PosX
  L2_2.nMarkerX = L3_2
  L2_2 = A0_2.CustomData
  L3_2 = A1_2.PosZ
  L2_2.nMarkerZ = L3_2
  L2_2 = Event
  L2_2 = L2_2.Post
  L3_2 = "GPS Beacon Set"
  L4_2 = {}
  L5_2 = A1_2.PosX
  L4_2.nX = L5_2
  L5_2 = A1_2.PosZ
  L4_2.nY = L5_2
  L2_2(L3_2, L4_2)
end

HandleMarkerUpdate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2.CustomData
  L2_2.nMarkerX = nil
  L2_2 = A0_2.CustomData
  L2_2.nMarkerZ = nil
  L2_2 = Event
  L2_2 = L2_2.Post
  L3_2 = "GPS Beacon Cleared"
  L4_2 = {}
  L5_2 = A1_2.PosX
  L4_2.nX = L5_2
  L5_2 = A1_2.PosZ
  L4_2.nY = L5_2
  L2_2(L3_2, L4_2)
end

HandleMarkerClear = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.bActive
  if L4_2 then
    return
  end
  L4_2 = A0_2.CustomData
  L4_2.bActive = true
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oMapFlash
  L5_2 = L4_2
  L4_2 = L4_2.GetLocation
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  L8_2 = A0_2.CustomData
  L8_2 = L8_2.oTransit
  if not L8_2 then
    L9_2 = MrxGuiBase
    L9_2 = L9_2.FlashWidget
    L10_2 = L9_2
    L9_2 = L9_2.new
    L9_2 = L9_2(L10_2)
    L8_2 = L9_2
    L10_2 = L8_2
    L9_2 = L8_2.SetLocation
    L11_2 = L4_2
    L12_2 = L5_2
    L13_2 = L6_2
    L14_2 = L7_2
    L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
    L10_2 = L8_2
    L9_2 = L8_2.SetOwner
    L12_2 = A0_2
    L11_2 = A0_2.GetOwner
    L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L11_2(L12_2)
    L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
    L9_2 = A0_2.CustomData
    L9_2.oTransit = L8_2
    L10_2 = A0_2
    L9_2 = A0_2.AddChild
    L11_2 = L8_2
    L9_2(L10_2, L11_2)
    L8_2.oParentWidget = A0_2
  end
  L9_2 = L8_2.CustomData
  L9_2.fCallback = A2_2
  L9_2 = L8_2.CustomData
  L9_2.tCallbackData = A3_2
  L10_2 = L8_2
  L9_2 = L8_2.SetSwfFile
  L11_2 = "landingzones"
  L12_2 = _FinishTransitInterfaceLoad
  L13_2 = {}
  L14_2 = L8_2
  L15_2 = A0_2
  L16_2 = A1_2
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L13_2[3] = L16_2
  L9_2(L10_2, L11_2, L12_2, L13_2)
  L9_2 = _SetupDelayedOpenSound
  L10_2 = 0.6
  L11_2 = A0_2
  L9_2(L10_2, L11_2)
  L9_2 = MrxSound
  L9_2 = L9_2.EnterPDAState
  L9_2()
  L9_2 = Event
  L9_2 = L9_2.Post
  L10_2 = "Transit Interface Open"
  L11_2 = {}
  L13_2 = A0_2
  L12_2 = A0_2.GetOwner
  L12_2 = L12_2(L13_2)
  L11_2.uPlayer = L12_2
  L9_2(L10_2, L11_2)
  L9_2 = Sys
  L9_2 = L9_2.RequestGameState
  L10_2 = "PDA"
  L9_2(L10_2)
end

OpenTransitInterface = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2
  L3_2 = MrxGuiBase
  L3_2 = L3_2.GetControlFocus
  L4_2 = A1_2
  L5_2 = true
  L3_2(L4_2, L5_2)
  L4_2 = A0_2
  L3_2 = A0_2.Restart
  L3_2(L4_2)
  L4_2 = A0_2
  L3_2 = A0_2.Play
  L3_2(L4_2)
  L3_2 = _PopulateMapDisplay
  L4_2 = A1_2
  L5_2 = A0_2
  L6_2 = false
  L7_2 = _knBlipLimit
  L8_2 = #A2_2
  L7_2 = L7_2 - L8_2
  L8_2 = true
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  L3_2 = 35
  L4_2 = 40
  L5_2 = A0_2
  L7_2 = L5_2
  L6_2 = L5_2.CallActionScriptCallback
  L8_2 = "LandingZone"
  L9_2 = {}
  L10_2 = 1
  L9_2[1] = L10_2
  L6_2(L7_2, L8_2, L9_2)
  L7_2 = L5_2
  L6_2 = L5_2.SetFlashEventHandler
  L8_2 = "LandingZone"
  L9_2 = _InvokeCallbackSuccess
  L10_2 = {}
  L6_2(L7_2, L8_2, L9_2, L10_2)
  L7_2 = L5_2
  L6_2 = L5_2.SetFlashEventHandler
  L8_2 = "closeMap"
  L9_2 = _HandleCloseEvent
  L10_2 = {}
  L6_2(L7_2, L8_2, L9_2, L10_2)
  L6_2 = {}
  L7_2 = pairs
  L8_2 = A2_2
  L7_2, L8_2, L9_2 = L7_2(L8_2)
  for L10_2, L11_2 in L7_2, L8_2, L9_2 do
    L11_2.nId = L10_2
    L12_2 = table
    L12_2 = L12_2.insert
    L13_2 = L6_2
    L14_2 = L11_2
    L12_2(L13_2, L14_2)
  end
  L7_2 = table
  L7_2 = L7_2.sort
  L8_2 = L6_2
  L9_2 = _LandingZoneLessThan
  L7_2(L8_2, L9_2)
  L7_2 = pairs
  L8_2 = L6_2
  L7_2, L8_2, L9_2 = L7_2(L8_2)
  for L10_2, L11_2 in L7_2, L8_2, L9_2 do
    L13_2 = L5_2
    L12_2 = L5_2.CallActionScriptCallback
    L14_2 = "AddBlip"
    L15_2 = {}
    L16_2 = tostring
    L17_2 = L11_2.nId
    L16_2 = L16_2(L17_2)
    L17_2 = "icon_lz_mc"
    L18_2 = L11_2.nX
    L18_2 = L18_2 + L3_2
    L19_2 = L11_2.nY
    L19_2 = L19_2 + L4_2
    L20_2 = 0
    L21_2 = L11_2.sName
    if not L21_2 then
      L21_2 = "Needs localized name"
    end
    L22_2 = "Landing Zone"
    L23_2 = " "
    L24_2 = " "
    L25_2 = false
    L26_2 = " "
    L27_2 = " "
    L15_2[1] = L16_2
    L15_2[2] = L17_2
    L15_2[3] = L18_2
    L15_2[4] = L19_2
    L15_2[5] = L20_2
    L15_2[6] = L21_2
    L15_2[7] = L22_2
    L15_2[8] = L23_2
    L15_2[9] = L24_2
    L15_2[10] = L25_2
    L15_2[11] = L26_2
    L15_2[12] = L27_2
    L12_2(L13_2, L14_2, L15_2)
  end
  L8_2 = A1_2
  L7_2 = A1_2.SetVisible
  L9_2 = true
  L7_2(L8_2, L9_2)
  L8_2 = A1_2
  L7_2 = A1_2.GetChildren
  L7_2 = L7_2(L8_2)
  L8_2 = ipairs
  L9_2 = L7_2
  L8_2, L9_2, L10_2 = L8_2(L9_2)
  for L11_2, L12_2 in L8_2, L9_2, L10_2 do
    L13_2 = A1_2.CustomData
    L13_2 = L13_2.oMapFlash
    if L12_2 ~= L13_2 then
      L14_2 = L12_2
      L13_2 = L12_2.SetOwner
      L16_2 = A1_2
      L15_2 = A1_2.GetOwner
      L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2 = L15_2(L16_2)
      L13_2(L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2)
      L13_2 = MrxGuiBase
      L13_2 = L13_2.AddWidgetWithChildren
      L14_2 = L12_2
      L13_2(L14_2)
    else
      L13_2 = MrxGuiBase
      L13_2 = L13_2.RemoveWidgetWithChildren
      L14_2 = L12_2
      L13_2(L14_2)
    end
  end
  L8_2 = MrxGuiManager
  L8_2 = L8_2.GetHudState
  L10_2 = A1_2
  L9_2 = A1_2.GetOwner
  L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2 = L9_2(L10_2)
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2)
  L9_2 = A1_2.CustomData
  L9_2.bHudState = L8_2
  if L8_2 then
    L9_2 = MrxGuiManager
    L9_2 = L9_2.ToggleHud
    L11_2 = A1_2
    L10_2 = A1_2.GetOwner
    L10_2 = L10_2(L11_2)
    L11_2 = false
    L9_2(L10_2, L11_2)
  end
  L10_2 = L5_2
  L9_2 = L5_2.CallActionScriptCallback
  L11_2 = "AddBlipFinish"
  L12_2 = {}
  L9_2(L10_2, L11_2, L12_2)
end

_FinishTransitInterfaceLoad = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = A0_2.nSortOrder
  if not L2_2 then
    L2_2 = false
    return L2_2
  else
    L2_2 = A1_2.nSortOrder
    if not L2_2 then
      L2_2 = true
      return L2_2
    end
  end
  L2_2 = A0_2.nSortOrder
  L3_2 = A1_2.nSortOrder
  L2_2 = L2_2 < L3_2
  return L2_2
end

_LandingZoneLessThan = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oTransit
  L2_2 = Sys
  L2_2 = L2_2.RequestGameState
  L3_2 = "ingame"
  L2_2(L3_2)
  if L1_2 then
    L3_2 = L1_2
    L2_2 = L1_2.CallActionScriptCallback
    L4_2 = "requestClose"
    L5_2 = {}
    L6_2 = true
    L5_2[1] = L6_2
    L2_2(L3_2, L4_2, L5_2)
    L3_2 = A0_2
    L2_2 = A0_2.RemoveChild
    L4_2 = L1_2
    L2_2(L3_2, L4_2)
    L2_2 = A0_2.CustomData
    L2_2.oTransit = nil
    L2_2 = Event
    L2_2 = L2_2.Create
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = 0.1
    L6_2 = true
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L5_2 = _RemoveTransitInterfaceDelayed
    L6_2 = {}
    L7_2 = L1_2
    L6_2[1] = L7_2
    L2_2(L3_2, L4_2, L5_2, L6_2)
    L2_2 = L1_2.CustomData
    L2_2 = L2_2.fCallback
    if L2_2 then
      L2_2 = _InvokeCallback
      L3_2 = L1_2
      L4_2 = "0"
      L5_2 = false
      L2_2(L3_2, L4_2, L5_2)
    end
  end
end

_RemoveTransitInterface = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2.SetSwfFile
  L3_2 = nil
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.delete
  L1_2(L2_2)
end

_RemoveTransitInterfaceDelayed = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = Event
  L2_2 = L2_2.Post
  L3_2 = "Transit Interface Success"
  L4_2 = {}
  L6_2 = A0_2
  L5_2 = A0_2.GetOwner
  L5_2 = L5_2(L6_2)
  L4_2.uPlayer = L5_2
  L2_2(L3_2, L4_2)
  L2_2 = _InvokeCallback
  L3_2 = A0_2
  L4_2 = A1_2
  L5_2 = true
  L2_2(L3_2, L4_2, L5_2)
end

_InvokeCallbackSuccess = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.fCallback
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.tCallbackData
  L5_2 = A0_2.CustomData
  L5_2.fCallback = nil
  L5_2 = A0_2.CustomData
  L5_2.tCallbackData = nil
  if L3_2 then
    if not L4_2 then
      L5_2 = {}
      L4_2 = L5_2
    end
    L5_2 = table
    L5_2 = L5_2.insert
    L6_2 = L4_2
    L7_2 = 1
    L8_2 = A2_2
    L5_2(L6_2, L7_2, L8_2)
    L5_2 = table
    L5_2 = L5_2.insert
    L6_2 = L4_2
    L7_2 = 1
    L8_2 = tonumber
    L9_2 = A1_2
    L8_2, L9_2 = L8_2(L9_2)
    L5_2(L6_2, L7_2, L8_2, L9_2)
    L5_2 = L3_2
    L6_2 = unpack
    L7_2 = L4_2
    L6_2, L7_2, L8_2, L9_2 = L6_2(L7_2)
    L5_2(L6_2, L7_2, L8_2, L9_2)
  end
end

_InvokeCallback = L0_1
L0_1 = 1
nSupportId = L0_1
L0_1 = {}
L0_1.Airstrike = "AddSupportAirstrike"
L0_1.Civilian = "AddSupportCivilian"
L0_1.Light = "AddSupportLight"
L0_1.Heavy = "AddSupportHeavy"
L0_1.Heli = "AddSupportHelicopters"
L0_1.Boat = "AddSupportBoats"
L0_1.Supply = "AddSupportSupplies"

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.tSupport
  L4_2 = sName
  L3_2 = L3_2[L4_2]
  if L3_2 then
    L3_2 = UpdateSupport
    L4_2 = A0_2
    L5_2 = A1_2
    return L3_2(L4_2, L5_2)
  end
  L3_2 = {}
  L4_2 = pairs
  L5_2 = A1_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L3_2[L7_2] = L8_2
  end
  L4_2 = "s"
  L5_2 = nSupportId
  L4_2 = L4_2 .. L5_2
  L3_2.sId = L4_2
  L3_2.sKey = A2_2
  L4_2 = nSupportId
  L4_2 = L4_2 + 1
  nSupportId = L4_2
  L4_2 = L0_1
  L5_2 = L3_2.sType
  L4_2 = L4_2[L5_2]
  L3_2.sAddFunc = L4_2
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.tSupport
  L5_2 = A1_2.sName
  L4_2[L5_2] = L3_2
  L4_2 = table
  L4_2 = L4_2.insert
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.tSupportOrdered
  L6_2 = A1_2.sName
  L4_2(L5_2, L6_2)
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.tSupportIdIndex
  L5_2 = L3_2.sId
  L6_2 = A1_2.sName
  L4_2[L5_2] = L6_2
end

AddSupport = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.tSupport
  L2_2 = L2_2[A1_2]
  if L2_2 then
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.tSupport
    L2_2 = L2_2[A1_2]
    L2_2 = L2_2.sId
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.tSupportIdIndex
    L3_2[L2_2] = nil
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.tSupport
  L2_2[A1_2] = nil
  L2_2 = 1
  while true do
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.tSupportOrdered
    L3_2 = L3_2[L2_2]
    if not L3_2 then
      break
    end
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.tSupportOrdered
    L3_2 = L3_2[L2_2]
    if L3_2 == A1_2 then
      break
    end
    L2_2 = L2_2 + 1
  end
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.tSupportOrdered
  L3_2[L2_2] = nil
  L3_2 = pairs
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.tEquippedSupport
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    if A1_2 == L7_2 then
      L8_2 = A0_2.CustomData
      L8_2 = L8_2.tEquippedSupport
      L8_2[L6_2] = nil
      L8_2 = A0_2.CustomData
      L8_2 = L8_2.tEquippedSupportIcons
      L8_2[L6_2] = nil
      L8_2 = MrxGuiBase
      L8_2 = L8_2.GetWidgetByNameAndOwner
      L9_2 = "Support Menu"
      L11_2 = A0_2
      L10_2 = A0_2.GetOwner
      L10_2, L11_2 = L10_2(L11_2)
      L8_2 = L8_2(L9_2, L10_2, L11_2)
      if L8_2 then
        L10_2 = L8_2
        L9_2 = L8_2.RemoveItem
        L11_2 = A1_2
        L9_2(L10_2, L11_2)
      end
    end
  end
end

RemoveSupport = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.tSupport
  L3_2 = A1_2.sName
  L2_2 = L2_2[L3_2]
  if not L2_2 then
    L3_2 = false
    return L3_2
  end
  L3_2 = pairs
  L4_2 = A1_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = L7_2 or L8_2
    if not L7_2 then
      L8_2 = L2_2[L6_2]
    end
    L2_2[L6_2] = L8_2
  end
  L3_2 = L0_1
  L4_2 = L2_2.sType
  L3_2 = L3_2[L4_2]
  L2_2.sAddFunc = L3_2
  L3_2 = true
  return L3_2
end

UpdateSupport = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = MrxPmc
  L2_2 = L2_2.GetSupportQty
  L3_2 = A1_2
  return L2_2(L3_2)
end

GetStockpile = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oMapFlash
  L2_2 = {}
  L2_2.Airstrike = "[airstrike] "
  L2_2.Civilian = "[vehcivilian] "
  L2_2.Light = "[vehmlight] "
  L2_2.Heavy = "[vehmheavy] "
  L2_2.Heli = "[vehheli] "
  L2_2.Boat = "[vehboat] "
  L2_2.Supply = "[supply] "
  L4_2 = L1_2
  L3_2 = L1_2.CallActionScriptCallback
  L5_2 = "AddStockpile"
  L6_2 = {}
  L7_2 = MrxPmc
  L7_2 = L7_2.GetCashQty
  L7_2 = L7_2()
  L8_2 = MrxPmc
  L8_2 = L8_2.GetFuelQty
  L8_2 = L8_2()
  L9_2 = MrxPmc
  L9_2 = L9_2.GetFuelCapacity
  L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2 = L9_2()
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L6_2[5] = L11_2
  L6_2[6] = L12_2
  L6_2[7] = L13_2
  L6_2[8] = L14_2
  L6_2[9] = L15_2
  L6_2[10] = L16_2
  L6_2[11] = L17_2
  L6_2[12] = L18_2
  L6_2[13] = L19_2
  L6_2[14] = L20_2
  L6_2[15] = L21_2
  L6_2[16] = L22_2
  L6_2[17] = L23_2
  L6_2[18] = L24_2
  L6_2[19] = L25_2
  L6_2[20] = L26_2
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = _UpdateSupportData
  L4_2 = A0_2
  L3_2(L4_2)
  L3_2 = nil
  L4_2 = nil
  L5_2 = nil
  L6_2 = nil
  L7_2 = pairs
  L8_2 = A0_2.CustomData
  L8_2 = L8_2.tSupportOrdered
  L7_2, L8_2, L9_2 = L7_2(L8_2)
  for L10_2, L11_2 in L7_2, L8_2, L9_2 do
    L12_2 = A0_2.CustomData
    L12_2 = L12_2.tSupport
    L3_2 = L12_2[L11_2]
    L12_2 = MrxPmc
    L12_2 = L12_2.GetSupportQty
    L13_2 = L3_2.oSupport
    L14_2 = L13_2
    L13_2 = L13_2.GetSupportName
    L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2 = L13_2(L14_2)
    L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2)
    L4_2 = L12_2
    L6_2 = " "
    L12_2 = L3_2.oSupport
    L13_2 = L12_2
    L12_2 = L12_2.GetDesignator
    L12_2 = L12_2(L13_2)
    if L12_2 then
      L12_2 = L3_2.oSupport
      L13_2 = L12_2
      L12_2 = L12_2.GetDesignator
      L12_2 = L12_2(L13_2)
      L13_2 = L12_2
      L12_2 = L12_2.GetType
      L12_2 = L12_2(L13_2)
      if "smoke" == L12_2 then
        L6_2 = "[Generic.SupportDesignators.Smoke]"
      elseif "satellite" == L12_2 then
        L6_2 = "[Generic.SupportDesignators.Satellite]"
      elseif "advanced satellite" == L12_2 then
        L6_2 = "[Generic.SupportDesignators.AdvSatellite]"
      elseif "beacon" == L12_2 then
        L6_2 = "[Generic.SupportDesignators.Beacon]"
      elseif "laser" == L12_2 then
        L6_2 = "[Generic.SupportDesignators.Laser]"
      elseif "flare" == L12_2 then
        L6_2 = "[Generic.SupportDesignators.Flare]"
      end
    end
    L12_2 = MrxSupportData
    L12_2 = L12_2.IsSupportEquippable
    L13_2 = L3_2.sKey
    L12_2 = L12_2(L13_2)
    L5_2 = L12_2
    L12_2 = L3_2.sAddFunc
    if L12_2 and L4_2 and 0 < L4_2 then
      L12_2 = MrxPmc
      L12_2 = L12_2.IsSupportNew
      L13_2 = L3_2.sKey
      L12_2 = L12_2(L13_2)
      L14_2 = L1_2
      L13_2 = L1_2.CallActionScriptCallback
      L15_2 = L3_2.sAddFunc
      L16_2 = {}
      L17_2 = L3_2.sId
      L18_2 = L3_2.sType
      L18_2 = L2_2[L18_2]
      if not L18_2 then
        L18_2 = ""
      end
      L19_2 = L3_2.sName
      L18_2 = L18_2 .. L19_2
      L19_2 = L3_2.sDescription
      L20_2 = L3_2.sIcon
      L21_2 = L4_2
      L22_2 = L3_2.nMaxStock
      L23_2 = L3_2.nFuelCost
      L24_2 = L12_2
      L25_2 = L5_2
      L26_2 = L6_2
      L16_2[1] = L17_2
      L16_2[2] = L18_2
      L16_2[3] = L19_2
      L16_2[4] = L20_2
      L16_2[5] = L21_2
      L16_2[6] = L22_2
      L16_2[7] = L23_2
      L16_2[8] = L24_2
      L16_2[9] = L25_2
      L16_2[10] = L26_2
      L13_2(L14_2, L15_2, L16_2)
    end
  end
  L7_2 = pairs
  L8_2 = A0_2.CustomData
  L8_2 = L8_2.tEquippedSupport
  L7_2, L8_2, L9_2 = L7_2(L8_2)
  for L10_2, L11_2 in L7_2, L8_2, L9_2 do
    L12_2 = A0_2.CustomData
    L12_2 = L12_2.tSupport
    L12_2 = L12_2[L11_2]
    if L12_2 then
      L13_2 = L12_2.sId
      if L13_2 then
        L14_2 = L1_2
        L13_2 = L1_2.CallActionScriptCallback
        L15_2 = "AddSupportEquipped"
        L16_2 = {}
        L17_2 = L10_2
        L18_2 = L12_2.sId
        L19_2 = L12_2.sName
        L20_2 = L12_2.sIcon
        L16_2[1] = L17_2
        L16_2[2] = L18_2
        L16_2[3] = L19_2
        L16_2[4] = L20_2
        L13_2(L14_2, L15_2, L16_2)
      end
    end
  end
  L8_2 = L1_2
  L7_2 = L1_2.SetFlashEventHandler
  L9_2 = "equipFailed"
  L10_2 = _ShowUnusableSupportMessage
  L11_2 = {}
  L7_2(L8_2, L9_2, L10_2, L11_2)
end

_PopulateSupportDisplay = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = pairs
  L2_2 = MrxSupportData
  L2_2 = L2_2.tSupportData
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = MrxPmc
    L6_2 = L6_2.GetSupportQty
    L7_2 = L4_2
    L6_2 = L6_2(L7_2)
    if L6_2 then
      L8_2 = A0_2
      L7_2 = A0_2.UpdateSupport
      L9_2 = L5_2
      L7_2 = L7_2(L8_2, L9_2)
      if not L7_2 then
        L8_2 = A0_2
        L7_2 = A0_2.AddSupport
        L9_2 = L5_2
        L7_2(L8_2, L9_2)
      end
    end
  end
end

_UpdateSupportData = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L2_2 = A0_2.oParentWidget
  L3_2 = "ERROR: No support denial condition specified."
  L4_2 = L2_2.CustomData
  L4_2 = L4_2.tSupportIdIndex
  L4_2 = L4_2[A1_2]
  L5_2 = nil
  if L4_2 then
    L6_2 = L2_2.CustomData
    L6_2 = L6_2.tSupport
    L5_2 = L6_2[L4_2]
  end
  if L5_2 then
    L6_2 = L5_2.sKey
    if L6_2 then
      L6_2 = MrxSupportData
      L6_2 = L6_2.IsSupportEquippable
      L7_2 = L5_2.sKey
      L6_2, L7_2 = L6_2(L7_2)
      L3_2 = L7_2 or L3_2
      if not L7_2 then
      end
    end
  end
  L7_2 = A0_2
  L6_2 = A0_2.CallActionScriptCallback
  L8_2 = "onlineMessage"
  L9_2 = {}
  L10_2 = "[PDA.Support.EquipFail.Unavailable]"
  L11_2 = L3_2
  L12_2 = 0
  L13_2 = "[Generic.Ok]"
  L14_2 = "[Generic.Ok]"
  L15_2 = nil
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L9_2[3] = L12_2
  L9_2[4] = L13_2
  L9_2[5] = L14_2
  L9_2[6] = L15_2
  L6_2(L7_2, L8_2, L9_2)
end

_ShowUnusableSupportMessage = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L2_2 = A0_2.oParentWidget
  L3_2 = _ParseString
  L4_2 = A1_2
  L3_2, L4_2 = L3_2(L4_2)
  L5_2 = MrxGuiBase
  L5_2 = L5_2.GetWidgetByNameAndOwner
  L6_2 = "Support Menu"
  L8_2 = L2_2
  L7_2 = L2_2.GetOwner
  L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2 = L7_2(L8_2)
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  if L5_2 then
    L6_2 = type
    L7_2 = L3_2
    L6_2 = L6_2(L7_2)
    if "number" == L6_2 then
      L6_2 = type
      L7_2 = L4_2
      L6_2 = L6_2(L7_2)
      if "string" == L6_2 then
        L6_2 = L2_2.CustomData
        L6_2 = L6_2.tSupportIdIndex
        L6_2 = L6_2[L4_2]
        L7_2 = nil
        if L6_2 then
          L8_2 = L2_2.CustomData
          L8_2 = L8_2.tSupport
          L7_2 = L8_2[L6_2]
        end
        if L7_2 then
          L8_2 = L2_2.CustomData
          L8_2 = L8_2.tEquippedSupport
          L8_2 = L8_2[L3_2]
          if L8_2 then
            L8_2 = L7_2.sName
            L9_2 = L2_2.CustomData
            L9_2 = L9_2.tEquippedSupport
            L9_2 = L9_2[L3_2]
            if L8_2 == L9_2 then
              return
            end
          end
        end
        L8_2 = L2_2.CustomData
        L8_2 = L8_2.tEquippedSupport
        L8_2 = L8_2[L3_2]
        if L8_2 then
          L9_2 = L5_2
          L8_2 = L5_2.RemoveItem
          L10_2 = L2_2.CustomData
          L10_2 = L10_2.tEquippedSupport
          L10_2 = L10_2[L3_2]
          L8_2(L9_2, L10_2)
        end
        L8_2 = L2_2.CustomData
        L8_2 = L8_2.tEquippedSupport
        L8_2[L3_2] = nil
        L8_2 = L2_2.CustomData
        L8_2 = L8_2.tEquippedSupportIcons
        L8_2[L3_2] = nil
        if L6_2 and L7_2 then
          L8_2 = {}
          L9_2 = pairs
          L10_2 = L7_2
          L9_2, L10_2, L11_2 = L9_2(L10_2)
          for L12_2, L13_2 in L9_2, L10_2, L11_2 do
            L8_2[L12_2] = L13_2
          end
          L8_2.bAnimate = true
          L8_2.bDontNetSync = true
          L9_2 = L2_2.CustomData
          L9_2 = L9_2.tEquippedSupport
          L10_2 = L7_2.sName
          L9_2[L3_2] = L10_2
          L9_2 = L2_2.CustomData
          L9_2 = L9_2.tEquippedSupportIcons
          L10_2 = L7_2.sIcon
          L9_2[L3_2] = L10_2
          L10_2 = L5_2
          L9_2 = L5_2.AddItem
          L11_2 = L8_2
          L9_2(L10_2, L11_2)
          L9_2 = L2_2.CustomData
          L9_2.bOpenSupportMenuOnExit = true
        end
      end
    end
  end
end

_HandleEquipEvent = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = string
  L3_2 = L3_2.gmatch
  L4_2 = A0_2
  L5_2 = "(%d+)([, ]*)(%w+)"
  L3_2, L4_2, L5_2 = L3_2(L4_2, L5_2)
  for L6_2, L7_2, L8_2 in L3_2, L4_2, L5_2 do
    L9_2 = tonumber
    L10_2 = L6_2
    L9_2 = L9_2(L10_2)
    L1_2 = L9_2
    L2_2 = L8_2
  end
  L3_2 = type
  L4_2 = L1_2
  L3_2 = L3_2(L4_2)
  if "number" == L3_2 then
    L3_2 = type
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    if "string" == L3_2 then
      L3_2 = L1_2
      L4_2 = L2_2
      return L3_2, L4_2
    end
  end
  L3_2 = nil
  return L3_2
end

_ParseString = L1_1

function L1_1(A0_2, A1_2)
end

_HandleUnequipEvent = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2
  if not A1_2 then
    L2_2 = nil
    return L2_2
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.tEquippedSupport
  L2_2 = L2_2[A1_2]
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.tEquippedSupportIcons
  L3_2 = L3_2[A1_2]
  return L2_2, L3_2
end

_GetEquippedSupport = L1_1

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = type
  L4_2 = A2_2
  L3_2 = L3_2(L4_2)
  if "number" ~= L3_2 then
    return
  end
  if A1_2 then
    L4_2 = A0_2
    L3_2 = A0_2.GetEquippedSupport
    L5_2 = A2_2
    L3_2 = L3_2(L4_2, L5_2)
    if L3_2 == A1_2 then
      return
    end
  end
  L3_2 = MrxGuiBase
  L3_2 = L3_2.GetWidgetByNameAndOwner
  L4_2 = "Support Menu"
  L6_2 = A0_2
  L5_2 = A0_2.GetOwner
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L5_2(L6_2)
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  if L3_2 then
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.tEquippedSupport
    L4_2 = L4_2[A2_2]
    if L4_2 then
      L5_2 = L3_2
      L4_2 = L3_2.RemoveItem
      L6_2 = A0_2.CustomData
      L6_2 = L6_2.tEquippedSupport
      L6_2 = L6_2[A2_2]
      L4_2(L5_2, L6_2)
    end
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.tEquippedSupport
    L4_2[A2_2] = nil
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.tEquippedSupportIcons
    L4_2[A2_2] = nil
    if A1_2 then
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.tSupport
      L4_2 = L4_2[A1_2]
      if L4_2 then
        L5_2 = {}
        L6_2 = pairs
        L7_2 = L4_2
        L6_2, L7_2, L8_2 = L6_2(L7_2)
        for L9_2, L10_2 in L6_2, L7_2, L8_2 do
          L5_2[L9_2] = L10_2
        end
        L5_2.bDontNetSync = true
        L6_2 = A0_2.CustomData
        L6_2 = L6_2.tEquippedSupport
        L7_2 = L4_2.sName
        L6_2[A2_2] = L7_2
        L6_2 = A0_2.CustomData
        L6_2 = L6_2.tEquippedSupportIcons
        L7_2 = L4_2.sIcon
        L6_2[A2_2] = L7_2
        L6_2 = A0_2.CustomData
        L6_2.bSupportNeedsEquipping = false
        L7_2 = L3_2
        L6_2 = L3_2.AddItem
        L8_2 = L5_2
        L6_2(L7_2, L8_2)
      end
    end
  end
end

_SetEquippedSupport = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = {}
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.tEquippedSupport
  L2_2 = L2_2[1]
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.tEquippedSupport
  L3_2 = L3_2[2]
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.tEquippedSupport
  L4_2 = L4_2[3]
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  return L1_2
end

ReadEquippedSupport = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = _EquipItemSilent
  L3_2 = A0_2
  L4_2 = 1
  L5_2 = A1_2[1]
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = _EquipItemSilent
  L3_2 = A0_2
  L4_2 = 2
  L5_2 = A1_2[2]
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = _EquipItemSilent
  L3_2 = A0_2
  L4_2 = 3
  L5_2 = A1_2[3]
  L2_2(L3_2, L4_2, L5_2)
end

RestoreEquippedSupport = L1_1

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  if not A2_2 then
    return
  end
  L3_2 = MrxGuiBase
  L3_2 = L3_2.GetWidgetByNameAndOwner
  L4_2 = "Support Menu"
  L6_2 = A0_2
  L5_2 = A0_2.GetOwner
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L5_2(L6_2)
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  if L3_2 then
    L4_2 = type
    L5_2 = A1_2
    L4_2 = L4_2(L5_2)
    if "number" == L4_2 then
      L4_2 = type
      L5_2 = A2_2
      L4_2 = L4_2(L5_2)
      if "string" == L4_2 then
        L4_2 = A0_2.CustomData
        L4_2 = L4_2.tSupport
        L4_2 = L4_2[A2_2]
        if L4_2 then
          L5_2 = A0_2.CustomData
          L5_2 = L5_2.tEquippedSupport
          L5_2 = L5_2[A1_2]
          if L5_2 then
            L5_2 = L4_2.sName
            L6_2 = A0_2.CustomData
            L6_2 = L6_2.tEquippedSupport
            L6_2 = L6_2[A1_2]
            if L5_2 == L6_2 then
              return
            end
          end
        end
        L5_2 = A0_2.CustomData
        L5_2 = L5_2.tEquippedSupport
        L5_2 = L5_2[A1_2]
        if L5_2 then
          L6_2 = L3_2
          L5_2 = L3_2.RemoveItem
          L7_2 = A0_2.CustomData
          L7_2 = L7_2.tEquippedSupport
          L7_2 = L7_2[A1_2]
          L5_2(L6_2, L7_2)
        end
        L5_2 = A0_2.CustomData
        L5_2 = L5_2.tEquippedSupport
        L5_2[A1_2] = nil
        L5_2 = A0_2.CustomData
        L5_2 = L5_2.tEquippedSupportIcons
        L5_2[A1_2] = nil
        if A2_2 and L4_2 then
          L5_2 = {}
          L6_2 = pairs
          L7_2 = L4_2
          L6_2, L7_2, L8_2 = L6_2(L7_2)
          for L9_2, L10_2 in L6_2, L7_2, L8_2 do
            L5_2[L9_2] = L10_2
          end
          L5_2.bDontNetSync = true
          L6_2 = A0_2.CustomData
          L6_2 = L6_2.tEquippedSupport
          L7_2 = L4_2.sName
          L6_2[A1_2] = L7_2
          L6_2 = A0_2.CustomData
          L6_2 = L6_2.tEquippedSupportIcons
          L7_2 = L4_2.sIcon
          L6_2[A1_2] = L7_2
          L7_2 = L3_2
          L6_2 = L3_2.AddItem
          L8_2 = L5_2
          L6_2(L7_2, L8_2)
        end
      end
    end
  end
end

_EquipItemSilent = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2
  L4_2 = type
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  if "string" == L4_2 then
    L4_2 = type
    L5_2 = A2_2
    L4_2 = L4_2(L5_2)
    if "string" == L4_2 then
      L4_2 = type
      L5_2 = A3_2
      L4_2 = L4_2(L5_2)
      if "number" == L4_2 then
        if A3_2 < 0 then
          L4_2 = A0_2.CustomData
          L4_2 = L4_2.tFactionAttitudes
          L4_2[A1_2] = nil
          L4_2 = true
          return L4_2
        end
        L4_2 = Math
        L4_2 = L4_2.max
        L5_2 = Math
        L5_2 = L5_2.min
        L6_2 = A3_2
        L7_2 = 100
        L5_2 = L5_2(L6_2, L7_2)
        L6_2 = 0
        L4_2 = L4_2(L5_2, L6_2)
        A3_2 = L4_2
        L4_2 = A0_2.CustomData
        L4_2 = L4_2.tFactionAttitudes
        L4_2 = L4_2[A1_2]
        if not L4_2 then
          L4_2 = A0_2.CustomData
          L4_2 = L4_2.tFactionAttitudes
          L5_2 = {}
          L6_2 = A2_2
          L7_2 = A3_2
          L5_2[1] = L6_2
          L5_2[2] = L7_2
          L4_2[A1_2] = L5_2
        else
          L4_2 = A0_2.CustomData
          L4_2 = L4_2.tFactionAttitudes
          L4_2 = L4_2[A1_2]
          L4_2[1] = A2_2
          L4_2 = A0_2.CustomData
          L4_2 = L4_2.tFactionAttitudes
          L4_2 = L4_2[A1_2]
          L4_2[2] = A3_2
        end
        L4_2 = true
        return L4_2
      end
    end
  end
  L4_2 = false
  return L4_2
end

SetFactionAttitude = L1_1
L1_1 = 100
nLogSize = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2
  L5_2 = type
  L6_2 = A1_2
  L5_2 = L5_2(L6_2)
  if "string" ~= L5_2 then
    L5_2 = type
    L6_2 = A2_2
    L5_2 = L5_2(L6_2)
    if "string" ~= L5_2 then
      L5_2 = type
      L6_2 = A3_2
      L5_2 = L5_2(L6_2)
      if "string" ~= L5_2 then
        return
      end
    end
  end
  if "dialog" ~= A1_2 and "objective" ~= A1_2 and "event" ~= A1_2 then
    return
  end
  L5_2 = {}
  L5_2.sType = A1_2
  L5_2.sName = A2_2
  L5_2.sMessage = A3_2
  L6_2 = A4_2 or L6_2
  if not A4_2 then
    L6_2 = "FFFFFF"
  end
  L5_2.sColor = L6_2
  L6_2 = table
  L6_2 = L6_2.insert
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.tLogEntries
  L8_2 = 1
  L9_2 = L5_2
  L6_2(L7_2, L8_2, L9_2)
  while true do
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.tLogEntries
    L6_2 = #L6_2
    L7_2 = nLogSize
    if not (L6_2 > L7_2) then
      break
    end
    L6_2 = table
    L6_2 = L6_2.remove
    L7_2 = A0_2.CustomData
    L7_2 = L7_2.tLogEntries
    L6_2(L7_2)
  end
end

AddLogEntry = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2
  if not A1_2 then
    return
  end
  L4_2 = nil
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.tDataDossiersIndex
  L5_2 = L5_2[A1_2]
  if L5_2 then
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.tDataDossiersIndex
    L4_2 = L5_2[A1_2]
  else
    L5_2 = {}
    L4_2 = L5_2
    L5_2 = table
    L5_2 = L5_2.insert
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.tDataDossiers
    L7_2 = L4_2
    L5_2(L6_2, L7_2)
  end
  L4_2.sTitle = A1_2
  L4_2.sText = A2_2
  L4_2.sIcon = A3_2
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.tDataDossiersIndex
  L5_2[A1_2] = L4_2
end

AddDossierEntry = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2
  if not A1_2 then
    return
  end
  L4_2 = nil
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.tDataHelpIndex
  L5_2 = L5_2[A1_2]
  if L5_2 then
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.tDataHelpIndex
    L4_2 = L5_2[A1_2]
  else
    L5_2 = {}
    L4_2 = L5_2
    L5_2 = table
    L5_2 = L5_2.insert
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.tDataHelp
    L7_2 = L4_2
    L5_2(L6_2, L7_2)
  end
  L4_2.sTitle = A1_2
  L4_2.sText = A2_2
  L4_2.sIcon = A3_2
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.tDataHelpIndex
  L5_2[A1_2] = L4_2
end

AddHelpEntry = L1_1

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = {}
  L3_2.sCategoryName = A1_2
  L3_2.sIcon = A2_2
  L4_2 = table
  L4_2 = L4_2.insert
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.tStatCategories
  L6_2 = L3_2
  L4_2(L5_2, L6_2)
end

AddStatisticCategory = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.tDataStats
  L4_2 = L4_2[A2_2]
  if L4_2 then
    L4_2 = _UpdateStatisticEntry
    L5_2 = A0_2
    L6_2 = A2_2
    L7_2 = A3_2
    L4_2(L5_2, L6_2, L7_2)
    return
  end
  L4_2 = {}
  L4_2.sCategoryName = A1_2
  L4_2.sText = A2_2
  L4_2.sData = A3_2
  L5_2 = table
  L5_2 = L5_2.insert
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.tDataStatsOrdered
  L7_2 = L4_2
  L5_2(L6_2, L7_2)
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.tDataStats
  L5_2[A2_2] = L4_2
end

AddStatisticEntry = L1_1

function L1_1(A0_2, A1_2, A2_2)
  local L3_2
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.tDataStats
  L3_2 = L3_2[A1_2]
  if L3_2 then
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.tDataStats
    L3_2 = L3_2[A1_2]
    L3_2.sData = A2_2
  end
end

_UpdateStatisticEntry = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oMapFlash
  L3_2 = L1_2
  L2_2 = L1_2.CallActionScriptCallback
  L4_2 = "checkOnline"
  L5_2 = {}
  L6_2 = Net
  L6_2 = L6_2.IsConnectedToInternet
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2 = L6_2()
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L5_2[7] = L12_2
  L5_2[8] = L13_2
  L5_2[9] = L14_2
  L5_2[10] = L15_2
  L5_2[11] = L16_2
  L5_2[12] = L17_2
  L5_2[13] = L18_2
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = L1_2
  L2_2 = L1_2.CallActionScriptCallback
  L4_2 = "multiplayerHost"
  L5_2 = {}
  L6_2 = Net
  L6_2 = L6_2.IsServer
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2 = L6_2()
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L5_2[7] = L12_2
  L5_2[8] = L13_2
  L5_2[9] = L14_2
  L5_2[10] = L15_2
  L5_2[11] = L16_2
  L5_2[12] = L17_2
  L5_2[13] = L18_2
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = L1_2
  L2_2 = L1_2.CallActionScriptCallback
  L4_2 = "multiplayerClient"
  L5_2 = {}
  L6_2 = Net
  L6_2 = L6_2.IsClient
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2 = L6_2()
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L5_2[7] = L12_2
  L5_2[8] = L13_2
  L5_2[9] = L14_2
  L5_2[10] = L15_2
  L5_2[11] = L16_2
  L5_2[12] = L17_2
  L5_2[13] = L18_2
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = Sys
  L2_2 = L2_2.HaveActiveProfile
  if L2_2 then
    L3_2 = L1_2
    L2_2 = L1_2.CallActionScriptCallback
    L4_2 = "profileActive"
    L5_2 = {}
    L6_2 = Sys
    L6_2 = L6_2.HaveActiveProfile
    L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2 = L6_2()
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L5_2[4] = L9_2
    L5_2[5] = L10_2
    L5_2[6] = L11_2
    L5_2[7] = L12_2
    L5_2[8] = L13_2
    L5_2[9] = L14_2
    L5_2[10] = L15_2
    L5_2[11] = L16_2
    L5_2[12] = L17_2
    L5_2[13] = L18_2
    L2_2(L3_2, L4_2, L5_2)
  end
  L2_2 = pairs
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.tFactionAttitudes
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = MrxGuiHudFactionGauge
    L7_2 = L7_2.GetBarValueAndName
    L8_2 = L6_2[2]
    L7_2, L8_2 = L7_2(L8_2)
    L10_2 = L1_2
    L9_2 = L1_2.CallActionScriptCallback
    L11_2 = "AddFactionAttitude"
    L12_2 = {}
    L13_2 = L5_2
    L14_2 = L6_2[1]
    L15_2 = L8_2
    L16_2 = L7_2
    L17_2 = false
    L12_2[1] = L13_2
    L12_2[2] = L14_2
    L12_2[3] = L15_2
    L12_2[4] = L16_2
    L12_2[5] = L17_2
    L9_2(L10_2, L11_2, L12_2)
  end
  L3_2 = L1_2
  L2_2 = L1_2.CallActionScriptCallback
  L4_2 = "AddDatabaseItem"
  L5_2 = {}
  L6_2 = 2
  L7_2 = 0
  L8_2 = "[PDA.Database.Log_All]"
  L9_2 = "Display all Log Events"
  L10_2 = "icon_categories_log"
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = L1_2
  L2_2 = L1_2.CallActionScriptCallback
  L4_2 = "AddDatabaseItem"
  L5_2 = {}
  L6_2 = 2
  L7_2 = 0
  L8_2 = "[PDA.Database.Log_Events]"
  L9_2 = "Filter Message Log by Events"
  L10_2 = "icon_categories_events"
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = L1_2
  L2_2 = L1_2.CallActionScriptCallback
  L4_2 = "AddDatabaseItem"
  L5_2 = {}
  L6_2 = 2
  L7_2 = 0
  L8_2 = "[PDA.Database.Log_Objectives]"
  L9_2 = "Filter Message Log by Objectives"
  L10_2 = "icon_categories_objectives"
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = L1_2
  L2_2 = L1_2.CallActionScriptCallback
  L4_2 = "AddDatabaseItem"
  L5_2 = {}
  L6_2 = 2
  L7_2 = 0
  L8_2 = "[PDA.Database.Log_Dialogue]"
  L9_2 = "Filter Message Log by Dialogue"
  L10_2 = "icon_categories_dialog"
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.tLogEntries
  L2_2 = #L2_2
  while 0 < L2_2 do
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.tLogEntries
    L3_2 = L3_2[L2_2]
    L5_2 = L1_2
    L4_2 = L1_2.CallActionScriptCallback
    L6_2 = "addMessageLog"
    L7_2 = {}
    L8_2 = L3_2.sType
    L9_2 = L3_2.sColor
    L10_2 = L3_2.sName
    L11_2 = L3_2.sMessage
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L7_2[4] = L11_2
    L4_2(L5_2, L6_2, L7_2)
    L2_2 = L2_2 - 1
  end
  L3_2 = ipairs
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.tDataDossiers
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L1_2
    L8_2 = L1_2.CallActionScriptCallback
    L10_2 = "AddDatabaseItem"
    L11_2 = {}
    L12_2 = 3
    L13_2 = 0
    L14_2 = L7_2.sTitle
    L15_2 = L7_2.sText
    L16_2 = L7_2.sIcon
    L17_2 = false
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L11_2[3] = L14_2
    L11_2[4] = L15_2
    L11_2[5] = L16_2
    L11_2[6] = L17_2
    L8_2(L9_2, L10_2, L11_2)
  end
  L3_2 = {}
  L4_2 = ipairs
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.tStatCategories
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = L8_2.sCategoryName
    L10_2 = L7_2 + 2
    L3_2[L9_2] = L10_2
    L10_2 = L1_2
    L9_2 = L1_2.CallActionScriptCallback
    L11_2 = "AddDatabaseItem"
    L12_2 = {}
    L13_2 = 4
    L14_2 = 0
    L15_2 = L8_2.sCategoryName
    L16_2 = L8_2.sCategoryName
    L17_2 = L8_2.sIcon
    L18_2 = false
    L12_2[1] = L13_2
    L12_2[2] = L14_2
    L12_2[3] = L15_2
    L12_2[4] = L16_2
    L12_2[5] = L17_2
    L12_2[6] = L18_2
    L9_2(L10_2, L11_2, L12_2)
  end
  L4_2 = nil
  L5_2 = ipairs
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.tDataStatsOrdered
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = L9_2.sCategoryName
    L4_2 = L3_2[L10_2]
    L11_2 = L1_2
    L10_2 = L1_2.CallActionScriptCallback
    L12_2 = "addStats"
    L13_2 = {}
    L14_2 = L4_2
    L15_2 = L9_2.sText
    L16_2 = L9_2.sData
    L13_2[1] = L14_2
    L13_2[2] = L15_2
    L13_2[3] = L16_2
    L10_2(L11_2, L12_2, L13_2)
  end
end

_PopulateDatabaseDisplay = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = A0_2.CustomData
  L1_2.bActive = true
  L1_2 = A0_2.CustomData
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L2_2 = L2_2[1]
  L1_2.oSubtitle = L2_2
  L1_2 = A0_2.CustomData
  L1_2.nCooldownFrames = 0
  L1_2 = MrxGuiBase
  L1_2 = L1_2.ImageWidget
  L2_2 = L1_2
  L1_2 = L1_2.new
  L1_2 = L1_2(L2_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetFullscreen
  L4_2 = true
  L2_2(L3_2, L4_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetColor
  L4_2 = 0
  L5_2 = 0
  L6_2 = 0
  L7_2 = 192
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetOwner
  L5_2 = A0_2
  L4_2 = A0_2.GetOwner
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L4_2(L5_2)
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L3_2 = A0_2
  L2_2 = A0_2.AddChild
  L4_2 = L1_2
  L2_2(L3_2, L4_2)
  L1_2.oParentWidget = A0_2
  L2_2 = MrxGuiBase
  L2_2 = L2_2.FlashWidget
  L3_2 = L2_2
  L2_2 = L2_2.new
  L2_2 = L2_2(L3_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetAnchoring
  L5_2 = "center"
  L6_2 = "center"
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = 283.33334
  L5_2 = L2_2
  L4_2 = L2_2.SetLocation
  L6_2 = 320 - L3_2
  L7_2 = 0
  L8_2 = 320 + L3_2
  L9_2 = 480
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetOwner
  L7_2 = A0_2
  L6_2 = A0_2.GetOwner
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L6_2(L7_2)
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L5_2 = A0_2
  L4_2 = A0_2.AddChild
  L6_2 = L2_2
  L4_2(L5_2, L6_2)
  L4_2 = A0_2.CustomData
  L4_2.oMapFlash = L2_2
  L4_2 = L2_2.CustomData
  L4_2.sFile = "topbar"
  L2_2.oParentWidget = A0_2
  L4_2 = Open
  A0_2.Open = L4_2
  L4_2 = Close
  A0_2.Close = L4_2
  L4_2 = SetSuppressed
  A0_2.SetSuppressed = L4_2
  L4_2 = A0_2.CustomData
  L4_2.nSuppressedCount = 0
  L5_2 = A0_2
  L4_2 = A0_2.SetEventHandler
  L6_2 = "ControllerInput"
  L7_2 = _HandleInput
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = A0_2.CustomData
  L5_2 = {}
  L4_2.tMapBlips = L5_2
  L4_2 = A0_2.CustomData
  L5_2 = {}
  L4_2.tMissions = L5_2
  L4_2 = A0_2.CustomData
  L5_2 = {}
  L4_2.tMissionIds = L5_2
  L4_2 = A0_2.CustomData
  L5_2 = {}
  L4_2.tRegions = L5_2
  L4_2 = A0_2.CustomData
  L4_2.bMapMode = false
  L4_2 = A0_2.CustomData
  L4_2.bAllowTrackingChange = true
  L4_2 = A0_2.CustomData
  L4_2.nFramesWithoutInput = -1
  L4_2 = A0_2.CustomData
  L4_2.bHudState = true
  L4_2 = AddMapBlip
  A0_2.AddMapBlip = L4_2
  L4_2 = RemoveMapBlip
  A0_2.RemoveMapBlip = L4_2
  L4_2 = AddMapMission
  A0_2.AddMapMission = L4_2
  L4_2 = RemoveMapMission
  A0_2.RemoveMapMission = L4_2
  L4_2 = UpdateMapMission
  A0_2.UpdateMapMission = L4_2
  L4_2 = SetMissionSticky
  A0_2.SetMissionSticky = L4_2
  L4_2 = SetSelectedMission
  A0_2.SetSelectedMission = L4_2
  L4_2 = GetSelectedMission
  A0_2.GetSelectedMission = L4_2
  L4_2 = SetMarker
  A0_2.SetMarker = L4_2
  L4_2 = AddLineRegion
  A0_2.AddLineRegion = L4_2
  L4_2 = RemoveLineRegion
  A0_2.RemoveLineRegion = L4_2
  L4_2 = SetMissionTrackable
  A0_2.SetMissionTrackable = L4_2
  L4_2 = SetMissionTrackCallback
  A0_2.SetMissionTrackCallback = L4_2
  L4_2 = SetMissionChangeAllowed
  A0_2.SetMissionChangeAllowed = L4_2
  L4_2 = SetFakePlayerLocation
  A0_2.SetFakePlayerLocation = L4_2
  L4_2 = SetBeaconTutorialMode
  A0_2.SetBeaconTutorialMode = L4_2
  L4_2 = A0_2.CustomData
  L5_2 = {}
  L4_2.tSupport = L5_2
  L4_2 = A0_2.CustomData
  L5_2 = {}
  L4_2.tSupportOrdered = L5_2
  L4_2 = A0_2.CustomData
  L5_2 = {}
  L4_2.tSupportIdIndex = L5_2
  L4_2 = A0_2.CustomData
  L5_2 = {}
  L4_2.tEquippedSupport = L5_2
  L4_2 = A0_2.CustomData
  L5_2 = {}
  L4_2.tEquippedSupportIcons = L5_2
  L4_2 = AddSupport
  A0_2.AddSupport = L4_2
  L4_2 = RemoveSupport
  A0_2.RemoveSupport = L4_2
  L4_2 = UpdateSupport
  A0_2.UpdateSupport = L4_2
  L4_2 = GetStockpile
  A0_2.GetStockpile = L4_2
  L4_2 = OpenTransitInterface
  A0_2.OpenTransitInterface = L4_2
  L4_2 = _GetEquippedSupport
  A0_2.GetEquippedSupport = L4_2
  L4_2 = _SetEquippedSupport
  A0_2.SetEquippedSupport = L4_2
  L4_2 = ReadEquippedSupport
  A0_2.ReadEquippedSupport = L4_2
  L4_2 = RestoreEquippedSupport
  A0_2.RestoreEquippedSupport = L4_2
  L4_2 = pairs
  L5_2 = MrxSupportData
  L5_2 = L5_2.tSupportData
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L10_2 = A0_2
    L9_2 = A0_2.AddSupport
    L11_2 = L8_2
    L12_2 = L7_2
    L9_2(L10_2, L11_2, L12_2)
  end
  L4_2 = A0_2.CustomData
  L5_2 = {}
  L4_2.tFactionAttitudes = L5_2
  L4_2 = A0_2.CustomData
  L5_2 = {}
  L4_2.tLogEntries = L5_2
  L4_2 = A0_2.CustomData
  L5_2 = {}
  L4_2.tDataDossiers = L5_2
  L4_2 = A0_2.CustomData
  L5_2 = {}
  L4_2.tDataDossiersIndex = L5_2
  L4_2 = A0_2.CustomData
  L5_2 = {}
  L4_2.tDataHelp = L5_2
  L4_2 = A0_2.CustomData
  L5_2 = {}
  L4_2.tDataHelpIndex = L5_2
  L4_2 = A0_2.CustomData
  L5_2 = {}
  L4_2.tStatCategories = L5_2
  L4_2 = A0_2.CustomData
  L5_2 = {}
  L4_2.tDataStatsOrdered = L5_2
  L4_2 = A0_2.CustomData
  L5_2 = {}
  L4_2.tDataStats = L5_2
  L4_2 = SetFactionAttitude
  A0_2.SetFactionAttitude = L4_2
  L4_2 = AddLogEntry
  A0_2.AddLogEntry = L4_2
  L4_2 = AddDossierEntry
  A0_2.AddDossierEntry = L4_2
  L4_2 = AddHelpEntry
  A0_2.AddHelpEntry = L4_2
  L4_2 = AddStatisticCategory
  A0_2.AddStatisticCategory = L4_2
  L4_2 = AddStatisticEntry
  A0_2.AddStatisticEntry = L4_2
  L4_2 = UpdateStatisticEntry
  A0_2.UpdateStatisticEntry = L4_2
  A0_2.nAnalogInputHeld = 0
  L4_2 = MrxGuiBase
  L4_2 = L4_2.AddWidget
  L5_2 = L2_2
  L4_2(L5_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetSwfFile
  L6_2 = L2_2.CustomData
  L6_2 = L6_2.sFile
  L7_2 = _FinishLoadAndClose
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = Event
  L4_2 = L4_2.CreatePersistent
  L5_2 = Event
  L5_2 = L5_2.ScriptEvent
  L6_2 = {}
  L7_2 = "mpPlayerJoin"
  
  function L8_2(A0_3)
    local L1_3, L2_3
    L1_3 = Net
    L1_3 = L1_3.IsServer
    L1_3 = L1_3()
    if L1_3 then
      L1_3 = Player
      L1_3 = L1_3.IsLocal
      L2_3 = A0_3[1]
      L1_3 = L1_3(L2_3)
      L1_3 = not L1_3
    end
    return L1_3
  end
  
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = SendPlayerJoinEvents
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  _evPlayerJoin = L4_2
  L4_2 = Pg
  L4_2 = L4_2.LoadAsset
  L5_2 = "pda_titles"
  L6_2 = "texture"
  L4_2(L5_2, L6_2)
end

_Initialize = L1_1

function L1_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = Net
  L0_2 = L0_2.IsServer
  L0_2 = L0_2()
  if not L0_2 then
    return
  end
  L0_2 = MrxGuiBase
  L0_2 = L0_2.GetWidgetByNameAndOwner
  L1_2 = "PDA"
  L2_2 = Player
  L2_2 = L2_2.GetLocalPlayer
  L2_2, L3_2, L4_2, L5_2, L6_2 = L2_2()
  L0_2 = L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2)
  if L0_2 then
    L1_2 = L0_2.CustomData
    if L1_2 then
      L1_2 = Net
      L1_2 = L1_2.SendCustomEvent
      L2_2 = "MrxGuiPda"
      L3_2 = NETEVENT_SETSELECTEDMISSION
      L4_2 = {}
      L5_2 = WifMissionData
      L5_2 = L5_2.GetMissionIndexFromId
      L6_2 = L0_2.CustomData
      L6_2 = L6_2.sSelectedMission
      L5_2, L6_2 = L5_2(L6_2)
      L4_2[1] = L5_2
      L4_2[2] = L6_2
      L5_2 = true
      L1_2(L2_2, L3_2, L4_2, L5_2)
    end
  end
end

SendPlayerJoinEvents = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = A0_2.CustomData
  L1_2.bHaveFlash = true
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oMapFlash
  L2_2 = L1_2
  L1_2 = L1_2.Pause
  L1_2(L2_2)
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oMapFlash
  L2_2 = L1_2
  L1_2 = L1_2.SetFlashEventHandler
  L3_2 = "TrackBlip"
  L4_2 = _HandleTrackEvent
  L5_2 = {}
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oMapFlash
  L2_2 = L1_2
  L1_2 = L1_2.SetFlashEventHandler
  L3_2 = "UntrackBlip"
  L4_2 = _HandleUntrackEvent
  L5_2 = {}
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oMapFlash
  L2_2 = L1_2
  L1_2 = L1_2.SetFlashEventHandler
  L3_2 = "cancelContract"
  L4_2 = _HandleMissionCancel
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oMapFlash
  L2_2 = L1_2
  L1_2 = L1_2.SetFlashEventHandler
  L3_2 = "equip"
  L4_2 = _HandleEquipEvent
  L5_2 = {}
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oMapFlash
  L2_2 = L1_2
  L1_2 = L1_2.SetFlashEventHandler
  L3_2 = "unequip"
  L4_2 = _HandleUnequipEvent
  L5_2 = {}
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oMapFlash
  L2_2 = L1_2
  L1_2 = L1_2.SetFlashEventHandler
  L3_2 = "closePDA"
  L4_2 = _HandleCloseEvent
  L5_2 = {}
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oMapFlash
  L2_2 = L1_2
  L1_2 = L1_2.SetFlashEventHandler
  L3_2 = "currentPage"
  L4_2 = _HandlePageChangeEvent
  L5_2 = {}
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

_FinishLoad = L1_1

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _FinishLoad
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.Close
  L1_2(L2_2)
end

_FinishLoadAndClose = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2
  L1_2 = 35
  L2_2 = 40
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oMapFlash
  L4_2 = {}
  L5_2 = nil
  L6_2 = Player
  L6_2 = L6_2.GetAllTargetMarkerPos
  L6_2 = L6_2()
  L7_2 = ipairs
  L8_2 = L6_2
  L7_2, L8_2, L9_2 = L7_2(L8_2)
  for L10_2, L11_2 in L7_2, L8_2, L9_2 do
    L12_2 = L11_2[1]
    if L12_2 then
      L12_2 = nil
      L13_2 = string
      L13_2 = L13_2.format
      L14_2 = "[PDA.Map.Player:%d]"
      L15_2 = L10_2
      L13_2 = L13_2(L14_2, L15_2)
      if L10_2 == 1 then
        L12_2 = "target1_mc"
      else
        L12_2 = "target2_mc"
      end
      L14_2 = {}
      L15_2 = L13_2
      L16_2 = L12_2
      L17_2 = L11_2[2]
      L17_2 = L17_2 + L1_2
      L18_2 = L11_2[3]
      L18_2 = L18_2 + L2_2
      L19_2 = 0
      L20_2 = L13_2
      L21_2 = L13_2
      L22_2 = " "
      L23_2 = " "
      L24_2 = false
      L25_2 = " "
      L26_2 = " "
      L27_2 = true
      L28_2 = true
      L14_2[1] = L15_2
      L14_2[2] = L16_2
      L14_2[3] = L17_2
      L14_2[4] = L18_2
      L14_2[5] = L19_2
      L14_2[6] = L20_2
      L14_2[7] = L21_2
      L14_2[8] = L22_2
      L14_2[9] = L23_2
      L14_2[10] = L24_2
      L14_2[11] = L25_2
      L14_2[12] = L26_2
      L14_2[13] = L27_2
      L14_2[14] = L28_2
      L5_2 = L14_2
      L14_2 = table
      L14_2 = L14_2.insert
      L15_2 = L4_2
      L16_2 = L5_2
      L14_2(L15_2, L16_2)
    end
  end
  L7_2 = _GuiInternal
  L7_2 = L7_2.AddPdaMapBlips
  L8_2 = L3_2.BasicData
  L8_2 = L8_2.uId
  L9_2 = L4_2
  L7_2(L8_2, L9_2)
end

AddPDATargetMarkers = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2
  L1_2 = 35
  L2_2 = 40
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oMapFlash
  L4_2 = Player
  L4_2 = L4_2.GetAllTargetMarkerPos
  L4_2 = L4_2()
  L5_2 = ipairs
  L6_2 = L4_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = string
    L10_2 = L10_2.format
    L11_2 = "[PDA.Map.Player:%d]"
    L12_2 = L8_2
    L10_2 = L10_2(L11_2, L12_2)
    L11_2 = L9_2[1]
    if L11_2 then
      L11_2 = nil
      if L8_2 == 1 then
        L11_2 = "target1_mc"
      else
        L11_2 = "target2_mc"
      end
      L12_2 = _GuiInternal
      L12_2 = L12_2.UpdatePdaBlip
      L13_2 = L3_2.BasicData
      L13_2 = L13_2.uId
      L14_2 = {}
      L15_2 = L10_2
      L16_2 = L11_2
      L17_2 = L9_2[2]
      L17_2 = L17_2 + L1_2
      L18_2 = L9_2[3]
      L18_2 = L18_2 + L2_2
      L19_2 = 0
      L20_2 = L10_2
      L21_2 = L10_2
      L22_2 = " "
      L23_2 = " "
      L24_2 = false
      L25_2 = " "
      L26_2 = " "
      L27_2 = true
      L28_2 = false
      L29_2 = true
      L14_2[1] = L15_2
      L14_2[2] = L16_2
      L14_2[3] = L17_2
      L14_2[4] = L18_2
      L14_2[5] = L19_2
      L14_2[6] = L20_2
      L14_2[7] = L21_2
      L14_2[8] = L22_2
      L14_2[9] = L23_2
      L14_2[10] = L24_2
      L14_2[11] = L25_2
      L14_2[12] = L26_2
      L14_2[13] = L27_2
      L14_2[14] = L28_2
      L14_2[15] = L29_2
      L12_2(L13_2, L14_2)
    else
      L11_2 = _GuiInternal
      L11_2 = L11_2.RemovePdaBlip
      L12_2 = L3_2.BasicData
      L12_2 = L12_2.uId
      L13_2 = L10_2
      L11_2(L12_2, L13_2)
    end
  end
end

UpdatePDATargetMarkers = L1_1

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oMapFlash
  L4_2 = 35
  L5_2 = 40
  L6_2 = nil
  if A2_2 == 1 then
    L6_2 = "player1_mc"
  else
    L6_2 = "player2_mc"
  end
  L7_2 = 0
  L8_2 = Player
  L8_2 = L8_2.GetCamera
  L9_2 = A1_2
  L8_2 = L8_2(L9_2)
  if L8_2 then
    L9_2 = Camera
    L9_2 = L9_2.GetYaw
    L10_2 = L8_2
    L9_2 = L9_2(L10_2)
    L7_2 = L9_2
  end
  L9_2 = string
  L9_2 = L9_2.format
  L10_2 = "[PDA.Map.Player:%d]"
  L11_2 = A2_2
  L9_2 = L9_2(L10_2, L11_2)
  L10_2 = L6_2
  L11_2 = " "
  L12_2 = A0_2.CustomData
  L12_2 = L12_2.sSelectedMission
  if L12_2 then
    L12_2 = A0_2.CustomData
    L12_2 = L12_2.tMissions
    L13_2 = A0_2.CustomData
    L13_2 = L13_2.sSelectedMission
    L12_2 = L12_2[L13_2]
    tCurMission = L12_2
    L12_2 = tCurMission
    if L12_2 then
      L12_2 = tCurMission
      L12_2 = L12_2.bSuppress
      if not L12_2 then
        L12_2 = tCurMission
        L10_2 = L12_2.sDesc
        L11_2 = "[PDA.Map.CurrentMission]"
      end
    end
  end
  L12_2 = Player
  L12_2 = L12_2.GetCharacter
  L13_2 = A1_2
  L12_2 = L12_2(L13_2)
  L13_2 = nil
  L14_2 = nil
  L15_2 = nil
  L16_2 = A0_2.CustomData
  L16_2 = L16_2.nFakePlayerX
  if L16_2 then
    L16_2 = A0_2.CustomData
    L13_2 = L16_2.nFakePlayerX
    L16_2 = A0_2.CustomData
    L14_2 = L16_2.nFakePlayerY
    L16_2 = A0_2.CustomData
    L15_2 = L16_2.nFakePlayerZ
  else
    L16_2 = Object
    L16_2 = L16_2.GetPosition
    L17_2 = L12_2
    L16_2, L17_2, L18_2 = L16_2(L17_2)
    L15_2 = L18_2
    L14_2 = L17_2
    L13_2 = L16_2
  end
  L16_2 = _GuiInternal
  L16_2 = L16_2.UpdatePdaBlip
  L17_2 = L3_2.BasicData
  L17_2 = L17_2.uId
  L18_2 = {}
  L19_2 = L6_2
  L20_2 = L6_2
  L21_2 = L13_2 + L4_2
  L22_2 = L15_2 + L5_2
  L23_2 = -L7_2
  L24_2 = L9_2
  L25_2 = L10_2
  L26_2 = " "
  L27_2 = " "
  L28_2 = false
  L29_2 = " "
  L30_2 = L11_2
  L31_2 = true
  L32_2 = false
  L33_2 = false
  L18_2[1] = L19_2
  L18_2[2] = L20_2
  L18_2[3] = L21_2
  L18_2[4] = L22_2
  L18_2[5] = L23_2
  L18_2[6] = L24_2
  L18_2[7] = L25_2
  L18_2[8] = L26_2
  L18_2[9] = L27_2
  L18_2[10] = L28_2
  L18_2[11] = L29_2
  L18_2[12] = L30_2
  L18_2[13] = L31_2
  L18_2[14] = L32_2
  L18_2[15] = L33_2
  L16_2(L17_2, L18_2)
end

UpdatePlayerMarkers = L1_1
L1_1 = 0

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oMapFlash
  L3_2 = A0_2
  L2_2 = A0_2.GetOwner
  L2_2 = L2_2(L3_2)
  L3_2 = Player
  L3_2 = L3_2.GetAllPlayers
  L3_2 = L3_2()
  L4_2 = ipairs
  L5_2 = L3_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    if L8_2 == L2_2 then
      L9_2 = UpdatePlayerMarkers
      L10_2 = A0_2
      L11_2 = L8_2
      L12_2 = L7_2
      L9_2(L10_2, L11_2, L12_2)
      break
    end
  end
  L4_2 = 0
  L5_2 = ipairs
  L6_2 = L3_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    if L9_2 ~= L2_2 then
      L10_2 = UpdatePlayerMarkers
      L11_2 = A0_2
      L12_2 = L9_2
      L13_2 = L8_2
      L10_2(L11_2, L12_2, L13_2)
      L4_2 = L8_2
    end
  end
  L5_2 = L1_1
  if L4_2 < L5_2 then
    L5_2 = "player"
    L6_2 = L1_1
    L7_2 = "_mc"
    L5_2 = L5_2 .. L6_2 .. L7_2
    L6_2 = _GuiInternal
    L6_2 = L6_2.RemovePdaBlip
    L7_2 = L1_2.BasicData
    L7_2 = L7_2.uId
    L8_2 = L5_2
    L6_2(L7_2, L8_2)
  end
  L1_1 = L4_2
end

UpdateAllPlayerMarkers = L2_1
L2_1 = 0

function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = L2_1
  L2_2 = L2_2 + A1_2
  L2_1 = L2_2
  L2_2 = L2_1
  if 1 < L2_2 then
    L2_2 = 0
    L2_1 = L2_2
    L2_2 = UpdatePDATargetMarkers
    L3_2 = A0_2
    L2_2(L3_2)
    L2_2 = UpdateAllPlayerMarkers
    L3_2 = A0_2
    L2_2(L3_2)
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nFramesWithoutInput
  if 0 <= L2_2 then
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.bMapMode
    if L2_2 then
      L2_2 = A0_2.CustomData
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.nFramesWithoutInput
      L3_2 = L3_2 + 1
      L2_2.nFramesWithoutInput = L3_2
      L2_2 = A0_2.CustomData
      L2_2 = L2_2.nFramesWithoutInput
      if 2 < L2_2 then
        L2_2 = A0_2.CustomData
        L2_2.nFramesWithoutInput = -1
        L2_2 = A0_2.CustomData
        L2_2 = L2_2.oMapFlash
        L4_2 = L2_2
        L3_2 = L2_2.HandleLeftAnalogInput
        L5_2 = 0
        L6_2 = 0
        L3_2(L4_2, L5_2, L6_2)
        L4_2 = L2_2
        L3_2 = L2_2.HandleRightAnalogInput
        L5_2 = 0
        L6_2 = 0
        L3_2(L4_2, L5_2, L6_2)
      end
    end
  end
end

_HandlePDAUpdateEvent = L3_1

function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bActive
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.Close
    L2_2(L3_2)
  else
    L2_2 = MrxGuiBase
    L2_2 = L2_2.GetCurrentControlHolder
    L4_2 = A0_2
    L3_2 = A0_2.GetOwner
    L3_2, L4_2 = L3_2(L4_2)
    L2_2 = L2_2(L3_2, L4_2)
    if L2_2 then
      L4_2 = L2_2
      L3_2 = L2_2.GetName
      L3_2 = L3_2(L4_2)
      if "Support Menu" ~= L3_2 then
        goto lbl_21
      end
    end
    L4_2 = A0_2
    L3_2 = A0_2.Open
    L3_2(L4_2)
  end
  ::lbl_21::
end

_HandleToggleEvent = L3_1

function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oMapFlash
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oTransit
  if L3_2 then
    L3_2 = A0_2.CustomData
    L2_2 = L3_2.oTransit
  end
  L3_2 = bExitOnLeft
  if L3_2 then
    L3_2 = MrxGuiBase
    L3_2 = L3_2.Joystick
    L3_2 = L3_2.BUTTON_PAD1_L
    L4_2 = A1_2.ButtonPress
    if L3_2 == L4_2 then
      L4_2 = A0_2
      L3_2 = A0_2.Close
      L3_2(L4_2)
    end
  end
  L3_2 = A0_2.nAnalogInputHeld
  L3_2 = 0 == L3_2
  A0_2.nAnalogInputHeld = 0
  L4_2 = 1.0E-5
  L5_2 = A1_2.LeftAnalogX
  if L5_2 then
    L5_2 = math
    L5_2 = L5_2.abs
    L6_2 = A1_2.LeftAnalogX
    L5_2 = L5_2(L6_2)
    if L4_2 < L5_2 then
      L5_2 = A0_2.nAnalogInputHeld
      L5_2 = L5_2 + 1
      A0_2.nAnalogInputHeld = L5_2
    end
  end
  L5_2 = A1_2.LeftAnalogY
  if L5_2 then
    L5_2 = math
    L5_2 = L5_2.abs
    L6_2 = A1_2.LeftAnalogY
    L5_2 = L5_2(L6_2)
    if L4_2 < L5_2 then
      L5_2 = A0_2.nAnalogInputHeld
      L5_2 = L5_2 + 1
      A0_2.nAnalogInputHeld = L5_2
    end
  end
  L5_2 = A1_2.RightAnalogX
  if L5_2 then
    L5_2 = math
    L5_2 = L5_2.abs
    L6_2 = A1_2.RightAnalogX
    L5_2 = L5_2(L6_2)
    if L4_2 < L5_2 then
      L5_2 = A0_2.nAnalogInputHeld
      L5_2 = L5_2 + 1
      A0_2.nAnalogInputHeld = L5_2
    end
  end
  L5_2 = A1_2.RightAnalogY
  if L5_2 then
    L5_2 = math
    L5_2 = L5_2.abs
    L6_2 = A1_2.RightAnalogY
    L5_2 = L5_2(L6_2)
    if L4_2 < L5_2 then
      L5_2 = A0_2.nAnalogInputHeld
      L5_2 = L5_2 + 1
      A0_2.nAnalogInputHeld = L5_2
    end
  end
  L5_2 = A0_2.nAnalogInputHeld
  L5_2 = 0 == L5_2
  if L3_2 ~= L5_2 then
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.bMapMode
    if L6_2 then
      L7_2 = L2_2
      L6_2 = L2_2.SetTesselationAllowed
      L8_2 = L5_2
      L6_2(L7_2, L8_2)
      if L5_2 then
        L7_2 = L2_2
        L6_2 = L2_2.HandleLeftAnalogInput
        L8_2 = 0
        L9_2 = 0
        L6_2(L7_2, L8_2, L9_2)
      else
        L7_2 = L2_2
        L6_2 = L2_2.CallActionScriptCallback
        L8_2 = "currentPOI"
        L9_2 = {}
        L10_2 = " "
        L9_2[1] = L10_2
        L6_2(L7_2, L8_2, L9_2)
      end
    end
  end
  L6_2 = A0_2.nAnalogInputHeld
  if L6_2 < 0 then
    A0_2.nAnalogInputHeld = 0
  end
  L6_2 = L2_2.EventHandlers
  L6_2 = L6_2.ControllerInput
  L7_2 = L2_2
  L8_2 = A1_2
  L6_2(L7_2, L8_2)
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.bMapMode
  if not L6_2 then
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.oTransit
    if not L6_2 then
      goto lbl_163
    end
  end
  L6_2 = A0_2.CustomData
  L6_2.nFramesWithoutInput = 0
  L6_2 = A1_2.LeftAnalogX
  if not L6_2 then
    L6_2 = A1_2.LeftAnalogY
    if not L6_2 then
      goto lbl_138
    end
  end
  L7_2 = L2_2
  L6_2 = L2_2.HandleLeftAnalogInput
  L8_2 = A1_2.LeftAnalogX
  if not L8_2 then
    L8_2 = 0
  end
  L9_2 = A1_2.LeftAnalogY
  if not L9_2 then
    L9_2 = 0
  end
  L6_2(L7_2, L8_2, L9_2)
  goto lbl_142
  ::lbl_138::
  L7_2 = L2_2
  L6_2 = L2_2.HandleLeftAnalogInput
  L8_2 = 0
  L9_2 = 0
  L6_2(L7_2, L8_2, L9_2)
  ::lbl_142::
  L6_2 = A1_2.RightAnalogX
  if not L6_2 then
    L6_2 = A1_2.RightAnalogY
    if not L6_2 then
      goto lbl_159
    end
  end
  L7_2 = L2_2
  L6_2 = L2_2.HandleRightAnalogInput
  L8_2 = A1_2.RightAnalogX
  if not L8_2 then
    L8_2 = 0
  end
  L9_2 = A1_2.RightAnalogY
  if not L9_2 then
    L9_2 = 0
  end
  L6_2(L7_2, L8_2, L9_2)
  goto lbl_163
  ::lbl_159::
  L7_2 = L2_2
  L6_2 = L2_2.HandleRightAnalogInput
  L8_2 = 0
  L9_2 = 0
  L6_2(L7_2, L8_2, L9_2)
  ::lbl_163::
end

_HandleInput = L3_1

function L3_1(A0_2)
  local L1_2
  if not A0_2 then
    L1_2 = false
    return L1_2
  end
  L1_2 = MrxGuiBase
  L1_2 = L1_2.Joystick
  L1_2 = L1_2.BUTTON_L_STICK_L
  if A0_2 >= L1_2 then
    L1_2 = MrxGuiBase
    L1_2 = L1_2.Joystick
    L1_2 = L1_2.BUTTON_R_STICK_D
    if A0_2 <= L1_2 then
      L1_2 = true
      return L1_2
    end
  end
  L1_2 = false
  return L1_2
end

IsAnalog = L3_1

function L3_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.oParentWidget
  L3_2 = L1_2
  L2_2 = L1_2.Close
  L2_2(L3_2)
end

_HandleCloseEvent = L3_1

function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2.oParentWidget
  if "Map" == A1_2 then
    L3_2 = L2_2.CustomData
    L3_2.bMapMode = true
  else
    L3_2 = L2_2.CustomData
    L3_2 = L3_2.bMapMode
    if L3_2 then
      L3_2 = L2_2.CustomData
      L3_2.nFramesWithoutInput = -1
      L3_2 = L2_2.CustomData
      L3_2 = L3_2.oMapFlash
      L5_2 = L3_2
      L4_2 = L3_2.HandleLeftAnalogInput
      L6_2 = 0
      L7_2 = 0
      L4_2(L5_2, L6_2, L7_2)
      L5_2 = L3_2
      L4_2 = L3_2.HandleLeftAnalogInput
      L6_2 = 0
      L7_2 = 0
      L4_2(L5_2, L6_2, L7_2)
    end
    L3_2 = L2_2.CustomData
    L3_2.bMapMode = false
  end
end

_HandlePageChangeEvent = L3_1

function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L2_2 = {}
  L3_2 = 1
  L4_2 = string
  L4_2 = L4_2.gmatch
  L5_2 = A1_2
  L6_2 = "-*%d+"
  L4_2, L5_2, L6_2 = L4_2(L5_2, L6_2)
  for L7_2 in L4_2, L5_2, L6_2 do
    L8_2 = tonumber
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    L2_2[L3_2] = L8_2
    L3_2 = L3_2 + 1
  end
  L4_2 = L2_2[1]
  if L4_2 then
    L4_2 = L2_2[2]
    if L4_2 then
      L4_2 = L2_2[1]
      L4_2 = L4_2 * 2
      L5_2 = 0
      L6_2 = L2_2[2]
      L6_2 = L6_2 * 2
      L7_2 = Pg
      L7_2 = L7_2.IsPointInBoundary
      if L7_2 then
        L7_2 = pairs
        L8_2 = WifVzRegionNames
        L8_2 = L8_2.tBoundaryList
        L7_2, L8_2, L9_2 = L7_2(L8_2)
        for L10_2, L11_2 in L7_2, L8_2, L9_2 do
          L12_2 = Pg
          L12_2 = L12_2.GetGuidByName
          L13_2 = L10_2
          L12_2 = L12_2(L13_2)
          if L12_2 then
            L13_2 = Pg
            L13_2 = L13_2.IsPointInBoundary
            L14_2 = L4_2
            L15_2 = L5_2
            L16_2 = L6_2
            L17_2 = L12_2
            L13_2 = L13_2(L14_2, L15_2, L16_2, L17_2)
            if L13_2 then
              L14_2 = A0_2
              L13_2 = A0_2.CallActionScriptCallback
              L15_2 = "currentPOI"
              L16_2 = {}
              L17_2 = L11_2
              L16_2[1] = L17_2
              L13_2(L14_2, L15_2, L16_2)
              return
            end
          end
        end
      end
    end
  end
  L5_2 = A0_2
  L4_2 = A0_2.CallActionScriptCallback
  L6_2 = "currentPOI"
  L7_2 = {}
  L8_2 = "Venezuela"
  L7_2[1] = L8_2
  L4_2(L5_2, L6_2, L7_2)
end

_HandleMapLocationEvent = L3_1
L3_1 = false
_tFactionNameLookup = L3_1

function L3_1()
  local L0_2, L1_2
  L0_2 = true
  bExitOnLeft = L0_2
  L0_2 = Gui
  L0_2 = L0_2.IsPdaOnSelect
  if L0_2 then
    L0_2 = Gui
    L0_2 = L0_2.IsPdaOnSelect
    L0_2 = L0_2()
    if L0_2 then
      L0_2 = false
      bExitOnLeft = L0_2
    end
  end
  L0_2 = {}
  L0_2.AN = "[0x8c648d92]"
  L0_2.PR = "[0x151ea816]"
  L0_2.OC = "[0x0375c825]"
  L0_2.GR = "[0xec76433f]"
  L0_2.CH = "[0x0b54aa0b]"
  L0_2.VZ = "[0xa7953946]"
  L0_2.PMC = "[0xeb4191d9]"
  _tFactionNameLookup = L0_2
end

Init = L3_1
