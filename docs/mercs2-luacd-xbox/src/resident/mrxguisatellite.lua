local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
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
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = true
_bUseMinigame = L0_1
L0_1 = 1
_nMinigameTime = L0_1
L0_1 = 1.2
_nMinigameTimeIncrease = L0_1
L0_1 = 7
_nMinigameMaxTime = L0_1
L0_1 = 5000
_nMoneyCost = L0_1
L0_1 = false
_tDefaultSectorData = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = {}
  L1_2 = {}
  L2_2 = -30
  L3_2 = 30
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L2_2 = {}
  L3_2 = 150
  L4_2 = 210
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L0_2[1] = L1_2
  L0_2[2] = L2_2
  _tDefaultSectorData = L0_2
end

Init = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _bUseMinigame
  return L0_2
end

UseMinigame = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L3_2 = A0_2
  L2_2 = A0_2.SetActivated
  L4_2 = A1_2.bActivate
  L5_2 = A1_2.bAdvanced
  L6_2 = A1_2.bMinigame
  L2_2(L3_2, L4_2, L5_2, L6_2)
end

HandleSatelliteStateChangeEvent = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.bActivated
  if L4_2 == A1_2 then
    return
  end
  L5_2 = A0_2
  L4_2 = A0_2.GetChildren
  L4_2 = L4_2(L5_2)
  if A1_2 then
    L5_2 = A0_2.CustomData
    L5_2.bMinigameOn = A3_2
    L5_2 = A0_2.CustomData
    L5_2.bTargettingSuccess = nil
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.oBackground
    L6_2 = L5_2
    L5_2 = L5_2.Show
    L7_2 = true
    L8_2 = 255
    L5_2(L6_2, L7_2, L8_2)
    L6_2 = A0_2
    L5_2 = A0_2.SetVisible
    L7_2 = true
    L5_2(L6_2, L7_2)
    L5_2 = pairs
    L6_2 = L4_2
    L5_2, L6_2, L7_2 = L5_2(L6_2)
    for L8_2, L9_2 in L5_2, L6_2, L7_2 do
      L10_2 = MrxGui
      L10_2 = L10_2.AddWidgetWithChildren
      L11_2 = L9_2
      L10_2(L11_2)
    end
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.oFound
    L6_2 = L5_2
    L5_2 = L5_2.SetVisible
    L7_2 = false
    L5_2(L6_2, L7_2)
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.oReadout
    L6_2 = L5_2
    L5_2 = L5_2.SetText
    L7_2 = " "
    L5_2(L6_2, L7_2)
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.oCompass
    L6_2 = L5_2
    L5_2 = L5_2.SetRotation
    L7_2 = Player
    L7_2 = L7_2.GetCameraXZHeading
    L9_2 = A0_2
    L8_2 = A0_2.GetOwner
    L8_2, L9_2, L10_2, L11_2 = L8_2(L9_2)
    L7_2, L8_2, L9_2, L10_2, L11_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
    L5_2 = _OpenMinigame
    L6_2 = A0_2
    L7_2 = _bUseMinigame
    L5_2(L6_2, L7_2)
    L5_2 = Sound
    L5_2 = L5_2.CueSound
    L6_2 = 0
    L7_2 = "ui_SatDes_Turn_On"
    L5_2(L6_2, L7_2)
    L5_2 = Sound
    L5_2 = L5_2.CueSound
    L6_2 = 0
    L7_2 = "ui_SatDes_BG_Loop"
    L5_2(L6_2, L7_2)
    L5_2 = Event
    L5_2 = L5_2.Post
    L6_2 = "Satellite Targetting Start"
    L7_2 = {}
    L9_2 = A0_2
    L8_2 = A0_2.GetOwner
    L8_2 = L8_2(L9_2)
    L7_2.uPlayer = L8_2
    L5_2(L6_2, L7_2)
    L5_2 = Player
    L5_2 = L5_2.SetScopeEnabled
    L7_2 = A0_2
    L6_2 = A0_2.GetOwner
    L6_2 = L6_2(L7_2)
    L7_2 = false
    L5_2(L6_2, L7_2)
    L5_2 = MrxGuiManager
    L5_2 = L5_2.ToggleHud
    L7_2 = A0_2
    L6_2 = A0_2.GetOwner
    L6_2 = L6_2(L7_2)
    L7_2 = false
    L8_2 = "satellite"
    L5_2(L6_2, L7_2, L8_2)
    L5_2 = Event
    L5_2 = L5_2.Create
    L6_2 = Event
    L6_2 = L6_2.TimerRelative
    L7_2 = {}
    L8_2 = 0.1
    L9_2 = true
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L8_2 = _ActivateStaticEffect
    L9_2 = {}
    L10_2 = A0_2
    L9_2[1] = L10_2
    L5_2(L6_2, L7_2, L8_2, L9_2)
  else
    L5_2 = Sound
    L5_2 = L5_2.CueSound
    L6_2 = 0
    L7_2 = "ui_SatDes_Turn_Off"
    L5_2(L6_2, L7_2)
    L5_2 = Sound
    L5_2 = L5_2.StopSound
    L6_2 = 0
    L7_2 = "ui_SatDes_BG_Loop"
    L5_2(L6_2, L7_2)
    L5_2 = _Cleanup
    L6_2 = A0_2
    L5_2(L6_2)
    L5_2 = Graphics
    L5_2 = L5_2.SetBoundaryEffect
    L6_2 = 0
    L5_2(L6_2)
    L5_2 = MrxGuiManager
    L5_2 = L5_2.ToggleHud
    L7_2 = A0_2
    L6_2 = A0_2.GetOwner
    L6_2 = L6_2(L7_2)
    L7_2 = true
    L8_2 = "satellite"
    L5_2(L6_2, L7_2, L8_2)
    L5_2 = Player
    L5_2 = L5_2.SetScopeEnabled
    L7_2 = A0_2
    L6_2 = A0_2.GetOwner
    L6_2 = L6_2(L7_2)
    L7_2 = true
    L5_2(L6_2, L7_2)
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.bTargettingSuccess
    if not L5_2 then
      L5_2 = Event
      L5_2 = L5_2.Post
      L6_2 = "Satellite Targetting Cancelled"
      L7_2 = {}
      L9_2 = A0_2
      L8_2 = A0_2.GetOwner
      L8_2 = L8_2(L9_2)
      L7_2.uPlayer = L8_2
      L5_2(L6_2, L7_2)
    end
  end
  L5_2 = A0_2.CustomData
  L5_2.bActivated = A1_2
end

SetActivated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bActivated
  if L1_2 then
    L1_2 = Graphics
    L1_2 = L1_2.SetBoundaryEffect
    L2_2 = 0.25
    L1_2(L2_2)
    L1_2 = MrxGui
    L1_2 = L1_2.GetWidgetByNameAndOwner
    L2_2 = "tutorial"
    L4_2 = A0_2
    L3_2 = A0_2.GetOwner
    L3_2, L4_2 = L3_2(L4_2)
    L1_2 = L1_2(L2_2, L3_2, L4_2)
    if L1_2 then
      L3_2 = L1_2
      L2_2 = L1_2.PushToFront
      L2_2(L3_2)
    end
  end
end

_ActivateStaticEffect = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L2_2 = _CleanupMinigame
  L3_2 = A0_2
  L4_2 = _bUseMinigame
  L2_2(L3_2, L4_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oBackground
  L3_2 = L2_2
  L2_2 = L2_2.Show
  L4_2 = false
  L5_2 = 255
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = A0_2
  L2_2 = A0_2.SetVisible
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = MrxGui
    L7_2 = L7_2.RemoveWidgetWithChildren
    L8_2 = L6_2
    L7_2(L8_2)
  end
end

_Cleanup = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = A1_2.ButtonPress
  L3_2 = MrxGuiBase
  L3_2 = L3_2.Joystick
  L3_2 = L3_2.BUTTON_ALT2_1
  if L2_2 ~= L3_2 then
    L2_2 = A1_2.ButtonPress
    L3_2 = MrxGuiBase
    L3_2 = L3_2.Joystick
    L3_2 = L3_2.BUTTON_PAD2_D
    if L2_2 ~= L3_2 then
      goto lbl_28
    end
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bMinigameOn
  if L2_2 then
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.bExiting
    if not L2_2 then
      L2_2 = MrxGuiBase
      L2_2 = L2_2.ReleaseControlFocus
      L3_2 = A0_2
      L2_2(L3_2)
      L2_2 = BeginMinigame
      L3_2 = A0_2
      L2_2(L3_2)
    end
  end
  ::lbl_28::
end

_HandleInput = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2[2]
  L4_2 = L2_2
  L3_2 = L2_2.SetFullscreen
  L5_2 = true
  L3_2(L4_2, L5_2)
  L3_2 = A0_2.CustomData
  L3_2.oBackground = L2_2
  L3_2 = L2_2.CustomData
  L5_2 = L2_2
  L4_2 = L2_2.GetChildren
  L4_2 = L4_2(L5_2)
  L4_2 = L4_2[1]
  L3_2.oWipe = L4_2
  L3_2 = L2_2.CustomData
  L4_2 = L2_2.CustomData
  L4_2 = L4_2.oWipe
  L5_2 = L4_2
  L4_2 = L4_2.GetTranslucency
  L4_2 = L4_2(L5_2)
  L3_2.nWipeAlpha = L4_2
  L3_2 = _ShowBackground
  L2_2.Show = L3_2
  L3_2 = L1_2[3]
  L4_2 = A0_2.CustomData
  L4_2.oReticle = L3_2
  L4_2 = L3_2.CustomData
  L6_2 = L3_2
  L5_2 = L3_2.AddAnimationPoint
  L7_2 = {}
  L7_2.TranslucencyLevel = 256
  L5_2 = L5_2(L6_2, L7_2)
  L4_2.nHighPoint = L5_2
  L4_2 = L3_2.CustomData
  L6_2 = L3_2
  L5_2 = L3_2.AddAnimationPoint
  L7_2 = {}
  L7_2.TranslucencyLevel = 64
  L5_2 = L5_2(L6_2, L7_2)
  L4_2.nLowPoint = L5_2
  L4_2 = LoopToHigh
  L5_2 = L3_2
  L6_2 = 0.75
  L4_2(L5_2, L6_2)
  L4_2 = L1_2[9]
  L5_2 = A0_2.CustomData
  L5_2.oReadout = L4_2
  L6_2 = L4_2
  L5_2 = L4_2.SetText
  L7_2 = " "
  L5_2(L6_2, L7_2)
  L5_2 = L1_2[11]
  L6_2 = L4_2.CustomData
  L6_2.oDesc = L5_2
  L6_2 = A0_2.CustomData
  L7_2 = L1_2[4]
  L6_2.oCompass = L7_2
  L6_2 = _InitializeMinigame
  L7_2 = A0_2
  L8_2 = _bUseMinigame
  L6_2(L7_2, L8_2)
  L6_2 = L1_2[12]
  L7_2 = _GuiInternal
  L7_2 = L7_2.SetWidgetUseNewRescale
  L8_2 = L6_2.BasicData
  L8_2 = L8_2.uId
  L9_2 = true
  L7_2(L8_2, L9_2)
  L7_2 = L6_2.CustomData
  L9_2 = L6_2
  L8_2 = L6_2.AddAnimationPoint
  L10_2 = {}
  L10_2.x = 20
  L10_2.y = -60
  L10_2.x2 = 620
  L10_2.y2 = 540
  L10_2.TranslucencyLevel = 32
  L8_2 = L8_2(L9_2, L10_2)
  L7_2.nBigPoint = L8_2
  L7_2 = L6_2.CustomData
  L9_2 = L6_2
  L8_2 = L6_2.AddAnimationPoint
  L10_2 = {}
  L10_2.x = 0
  L10_2.y = 0
  L10_2.x2 = 128
  L10_2.y2 = 128
  L8_2 = L8_2(L9_2, L10_2)
  L7_2.nSetPoint = L8_2
  L8_2 = L6_2
  L7_2 = L6_2.SetVisible
  L9_2 = false
  L7_2(L8_2, L9_2)
  L8_2 = L6_2
  L7_2 = L6_2.AnimateToPoint
  L9_2 = L6_2.CustomData
  L9_2 = L9_2.oBigPoint
  L10_2 = 0
  L11_2 = true
  L7_2(L8_2, L9_2, L10_2, L11_2)
  L7_2 = A0_2.CustomData
  L7_2.oFound = L6_2
  L7_2 = A0_2.CustomData
  L8_2 = L1_2[13]
  L7_2.oHelpText = L8_2
  L7_2 = SetHelpText
  A0_2.SetHelpText = L7_2
  L7_2 = A0_2.CustomData
  L7_2.bActivated = false
  L7_2 = SetActivated
  A0_2.SetActivated = L7_2
  L7_2 = _Cleanup
  L8_2 = A0_2
  L7_2(L8_2)
  L7_2 = SetSuccessCallback
  A0_2.SetSuccessCallback = L7_2
  L8_2 = A0_2
  L7_2 = A0_2.SetEventHandler
  L9_2 = "SetSatelliteBackground"
  L10_2 = HandleBackgroundMessage
  L7_2(L8_2, L9_2, L10_2)
  L8_2 = A0_2
  L7_2 = A0_2.SetEventHandler
  L9_2 = "ScanFoundGuid"
  L10_2 = HandleGuidFound
  L7_2(L8_2, L9_2, L10_2)
end

Initialize = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2
  L3_2 = A0_2.CustomData
  L3_2.fCallback = A1_2
  L3_2 = A0_2.CustomData
  L3_2.tCallbackData = A2_2
end

SetSuccessCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.Wrap
  L1_2(L2_2)
end

InitializeHelpField = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oHelpText
  L3_2 = L2_2
  L2_2 = L2_2.SetText
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

SetHelpText = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oFound
  L4_2 = L2_2
  L3_2 = L2_2.SetVisible
  L5_2 = true
  L3_2(L4_2, L5_2)
  L3_2 = Gui
  L3_2 = L3_2.FindGuiLocation
  L5_2 = A0_2
  L4_2 = A0_2.GetOwner
  L4_2 = L4_2(L5_2)
  L5_2 = A1_2.uGuid
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2, L5_2)
  if L3_2 and L4_2 and not L5_2 and not L6_2 then
    L5_2 = L3_2
    L6_2 = L4_2
  end
  L7_2 = L3_2 + L5_2
  L7_2 = L7_2 * 0.5
  L8_2 = L4_2 + L6_2
  L8_2 = L8_2 * 0.5
  L3_2 = L7_2 - 48
  L4_2 = L8_2 - 48
  L5_2 = L7_2 + 48
  L6_2 = L8_2 + 48
  L10_2 = L2_2
  L9_2 = L2_2.SetAnimationPoint
  L11_2 = L2_2.CustomData
  L11_2 = L11_2.nSetPoint
  L12_2 = {}
  L12_2.x = L3_2
  L12_2.y = L4_2
  L12_2.x2 = L5_2
  L12_2.y2 = L6_2
  L12_2.TranslucencyLevel = 255
  L9_2(L10_2, L11_2, L12_2)
  L10_2 = L2_2
  L9_2 = L2_2.AnimateToPoint
  L11_2 = L2_2.CustomData
  L11_2 = L11_2.nBigPoint
  L12_2 = 0
  L13_2 = true
  L14_2 = _FinishFoundAnimation
  L15_2 = {}
  L16_2 = A1_2.fCallback
  L17_2 = A1_2.tCallbackData
  L15_2[1] = L16_2
  L15_2[2] = L17_2
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
end

HandleGuidFound = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L4_2 = A0_2
  L3_2 = A0_2.AnimateToPoint
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nSetPoint
  L6_2 = 0.25
  L7_2 = true
  L8_2 = _FinishFoundAnimation2
  L9_2 = {}
  L10_2 = A1_2
  L11_2 = A2_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
end

_FinishFoundAnimation = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L4_2 = A0_2
  L3_2 = A0_2.AnimateToPoint
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nSetPoint
  L6_2 = 0.5
  L7_2 = true
  L8_2 = _CallFoundCallback
  L9_2 = {}
  L10_2 = A1_2
  L11_2 = A2_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
end

_FinishFoundAnimation2 = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  L4_2 = A0_2
  L3_2 = A0_2.SetVisible
  L5_2 = false
  L3_2(L4_2, L5_2)
  L3_2 = type
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if "function" == L3_2 then
    if not A2_2 then
      L3_2 = {}
      A2_2 = L3_2
    end
    L3_2 = A1_2
    L4_2 = unpack
    L5_2 = A2_2
    L4_2, L5_2 = L4_2(L5_2)
    L3_2(L4_2, L5_2)
  end
end

_CallFoundCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A1_2.sName
  if not L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.SetText
    L4_2 = " "
    L2_2(L3_2, L4_2)
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.oDesc
    L3_2 = L2_2
    L2_2 = L2_2.SetText
    L4_2 = " "
    L2_2(L3_2, L4_2)
  else
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.sDisplayString
    L3_2 = A1_2.sName
    if L2_2 ~= L3_2 then
      L3_2 = A0_2
      L2_2 = A0_2.SetText
      L4_2 = A1_2.sName
      L2_2(L3_2, L4_2)
      L2_2 = A0_2.CustomData
      L3_2 = A1_2.sName
      L2_2.sDisplayString = L3_2
      L2_2 = A1_2.uTargetGuid
      if L2_2 then
        L2_2 = MrxGui
        L2_2 = L2_2.GetObjectiveDescription
        L3_2 = A1_2.uTargetGuid
        L2_2 = L2_2(L3_2)
        L3_2 = A0_2.CustomData
        L3_2 = L3_2.oDesc
        L4_2 = L3_2
        L3_2 = L3_2.SetText
        L5_2 = L2_2 or L5_2
        if not L2_2 then
          L5_2 = " "
        end
        L3_2(L4_2, L5_2)
      end
    end
  end
end

HandleReadoutUpdate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A1_2.FactionTexture
  if not L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.SetVisible
    L4_2 = false
    L2_2(L3_2, L4_2)
  else
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.PrevTexture
    L3_2 = A1_2.FactionTexture
    if L2_2 ~= L3_2 then
      L3_2 = A0_2
      L2_2 = A0_2.SetTexture
      L4_2 = A1_2.FactionTexture
      L2_2(L3_2, L4_2)
      L3_2 = A0_2
      L2_2 = A0_2.SetVisible
      L4_2 = true
      L2_2(L3_2, L4_2)
      L2_2 = A0_2.CustomData
      L3_2 = A1_2.FactionTexture
      L2_2.sDisplayString = L3_2
    end
  end
end

HandleFactionUpdate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Pg
  L1_2 = L1_2.FindPointFromCamera
  L2_2 = 0
  L3_2 = 0
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2)
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oReadout
  L5_2 = L4_2
  L4_2 = L4_2.SetText
  L6_2 = string
  L6_2 = L6_2.format
  L7_2 = "%4.2f"
  L8_2 = L1_2
  L6_2, L7_2, L8_2, L9_2 = L6_2(L7_2, L8_2)
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  L4_2 = math
  L4_2 = L4_2.floor
  L5_2 = L1_2 / 100
  L4_2 = L4_2(L5_2)
  L4_2 = L4_2 * 100
  L1_2 = L1_2 - L4_2
  L4_2 = L1_2 / 100
  L1_2 = L4_2 * 5
  L5_2 = A0_2
  L4_2 = A0_2.SetTextureCoordinates
  L6_2 = L1_2
  L7_2 = nil
  L8_2 = L1_2 + 10
  L9_2 = nil
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
end

HandleXUpdate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Pg
  L1_2 = L1_2.FindPointFromCamera
  L2_2 = 0
  L3_2 = 0
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2)
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oReadout
  L5_2 = L4_2
  L4_2 = L4_2.SetText
  L6_2 = string
  L6_2 = L6_2.format
  L7_2 = "%4.2f"
  L8_2 = L3_2
  L6_2, L7_2, L8_2, L9_2 = L6_2(L7_2, L8_2)
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  L4_2 = math
  L4_2 = L4_2.floor
  L5_2 = L3_2 / 100
  L4_2 = L4_2(L5_2)
  L4_2 = L4_2 * 100
  L3_2 = L3_2 - L4_2
  L4_2 = L3_2 / 100
  L3_2 = L4_2 * 4
  L5_2 = A0_2
  L4_2 = A0_2.SetTextureCoordinates
  L6_2 = nil
  L7_2 = L3_2
  L8_2 = nil
  L9_2 = L3_2 + 8
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
end

HandleZUpdate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L2_2 = A0_2.CustomData
  L3_2 = L1_2[1]
  L2_2.oPointer = L3_2
  L2_2 = A0_2.CustomData
  L3_2 = L1_2[2]
  L2_2.oReadout = L3_2
end

InitMeter = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  if not A1_2 then
    return
  end
  L3_2 = A0_2
  L2_2 = A0_2.GetLocation
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  if L5_2 < 0 then
    L7_2 = A0_2
    L6_2 = A0_2.SetLocation
    L8_2 = L2_2
    L9_2 = 500
    L6_2(L7_2, L8_2, L9_2)
  else
    L7_2 = A0_2
    L6_2 = A0_2.SetLocation
    L8_2 = L2_2
    L9_2 = 125 * A1_2
    L9_2 = L3_2 - L9_2
    L6_2(L7_2, L8_2, L9_2)
  end
end

WipeUpdate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = A0_2
  L2_2 = A0_2.AnimateToPoint
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nHighPoint
  L5_2 = A1_2
  L6_2 = true
  L7_2 = LoopToLow
  L8_2 = {}
  L9_2 = A1_2
  L8_2[1] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
end

LoopToHigh = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = A0_2
  L2_2 = A0_2.AnimateToPoint
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nLowPoint
  L5_2 = A1_2
  L6_2 = true
  L7_2 = LoopToHigh
  L8_2 = {}
  L9_2 = A1_2
  L8_2[1] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
end

LoopToLow = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oBackground
  L3_2 = L2_2
  L2_2 = L2_2.Show
  L4_2 = A1_2.bActivate
  L5_2 = A1_2.fAlpha
  L2_2(L3_2, L4_2, L5_2)
end

HandleBackgroundMessage = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  if not A2_2 then
    A2_2 = 255
  end
  if A1_2 then
    L3_2 = MrxGui
    L3_2 = L3_2.AddWidgetWithChildren
    L4_2 = A0_2
    L3_2(L4_2)
    L4_2 = A0_2
    L3_2 = A0_2.SetVisible
    L5_2 = true
    L3_2(L4_2, L5_2)
    L4_2 = A0_2
    L3_2 = A0_2.SetTranslucency
    L5_2 = A2_2
    L3_2(L4_2, L5_2)
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.oWipe
    L4_2 = L3_2
    L3_2 = L3_2.SetTranslucency
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.nWipeAlpha
    L6_2 = A2_2 / 255
    L5_2 = L5_2 * L6_2
    L3_2(L4_2, L5_2)
  else
    L3_2 = MrxGui
    L3_2 = L3_2.RemoveWidgetWithChildren
    L4_2 = A0_2
    L3_2(L4_2)
    L4_2 = A0_2
    L3_2 = A0_2.SetVisible
    L5_2 = false
    L3_2(L4_2, L5_2)
    L4_2 = A0_2
    L3_2 = A0_2.SetTranslucency
    L5_2 = 255
    L3_2(L4_2, L5_2)
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.oWipe
    L4_2 = L3_2
    L3_2 = L3_2.SetTranslucency
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.nWipeAlpha
    L3_2(L4_2, L5_2)
  end
end

_ShowBackground = L0_1
L0_1 = 255
nBaseBgR = L0_1
L0_1 = 255
nBaseBgG = L0_1
L0_1 = 255
nBaseBgB = L0_1
L0_1 = 172
nSliceR = L0_1
L0_1 = 172
nSliceG = L0_1
L0_1 = 172
nSliceB = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L2_2 = L2_2[1]
  L3_2 = A0_2.CustomData
  L3_2.oMinigame = L2_2
  if A1_2 then
    L4_2 = L2_2
    L3_2 = L2_2.GetChildren
    L3_2 = L3_2(L4_2)
    L4_2 = L3_2[5]
    L5_2 = L3_2[6]
    L6_2 = L3_2[7]
    L7_2 = L3_2[1]
    L9_2 = A0_2
    L8_2 = A0_2.GetChildren
    L8_2 = L8_2(L9_2)
    L8_2 = L8_2[8]
    L9_2 = L8_2
    L8_2 = L8_2.GetChildren
    L8_2 = L8_2(L9_2)
    L8_2 = L8_2[2]
    L10_2 = A0_2
    L9_2 = A0_2.GetChildren
    L9_2 = L9_2(L10_2)
    L9_2 = L9_2[7]
    L10_2 = L9_2
    L9_2 = L9_2.GetChildren
    L9_2 = L9_2(L10_2)
    L9_2 = L9_2[2]
    L10_2 = L8_2.CustomData
    L10_2.oMinigame = L2_2
    L10_2 = L9_2.CustomData
    L10_2.oMinigame = L2_2
    L10_2 = L2_2.CustomData
    L10_2.oCursor = L4_2
    L10_2 = L2_2.CustomData
    L10_2.oBg = L7_2
    L10_2 = L2_2.CustomData
    L10_2.oCost = L8_2
    L10_2 = L2_2.CustomData
    L10_2.oTime = L9_2
    L10_2 = L2_2.CustomData
    L10_2.oButton = L6_2
    L2_2.ParentWidget = A0_2
    L10_2 = L4_2.CustomData
    L12_2 = L4_2
    L11_2 = L4_2.AddAnimationPoint
    L13_2 = {}
    L13_2.nRotation = 359
    L13_2.nRotationDirection = 1
    L11_2 = L11_2(L12_2, L13_2)
    L10_2.nEndPoint = L11_2
    L10_2 = L4_2.CustomData
    L12_2 = L4_2
    L11_2 = L4_2.AddAnimationPoint
    L13_2 = {}
    L13_2.nRotation = 0
    L13_2.nRotationDirection = -1
    L11_2 = L11_2(L12_2, L13_2)
    L10_2.nStartPoint = L11_2
    L10_2 = _SetMinigameCallback
    A0_2.SetMinigameCallback = L10_2
    L10_2 = _SetMinigameSectors
    A0_2.SetMinigameSectors = L10_2
    L10_2 = _SetMinigameCost
    A0_2.SetMinigameCost = L10_2
    L10_2 = L2_2.CustomData
    L11_2 = {}
    L10_2.tSectorWidgets = L11_2
    L10_2 = L2_2.CustomData
    L10_2 = L10_2.tSectorWidgets
    L11_2 = L3_2[2]
    L10_2[1] = L11_2
    L10_2 = L2_2.CustomData
    L10_2 = L10_2.tSectorWidgets
    L11_2 = L3_2[3]
    L10_2[2] = L11_2
    L10_2 = L2_2.CustomData
    L10_2 = L10_2.tSectorWidgets
    L11_2 = L3_2[4]
    L10_2[3] = L11_2
    L10_2 = pairs
    L11_2 = L2_2.CustomData
    L11_2 = L11_2.tSectorWidgets
    L10_2, L11_2, L12_2 = L10_2(L11_2)
    for L13_2, L14_2 in L10_2, L11_2, L12_2 do
      L15_2 = L14_2.CustomData
      L17_2 = L14_2
      L16_2 = L14_2.AddAnimationPoint
      L18_2 = {}
      L19_2 = nSliceR
      L18_2.RedLevel = L19_2
      L19_2 = nSliceG
      L18_2.GreenLevel = L19_2
      L19_2 = nSliceB
      L18_2.BlueLevel = L19_2
      L16_2 = L16_2(L17_2, L18_2)
      L15_2.nBaseColor = L16_2
      L15_2 = L14_2.CustomData
      L17_2 = L14_2
      L16_2 = L14_2.AddAnimationPoint
      L18_2 = {}
      L18_2.RedLevel = 255
      L18_2.GreenLevel = 255
      L18_2.BlueLevel = 255
      L16_2 = L16_2(L17_2, L18_2)
      L15_2.nLitColor = L16_2
      L16_2 = L14_2
      L15_2 = L14_2.SetColor
      L17_2 = 0
      L18_2 = 0
      L19_2 = 255
      L15_2(L16_2, L17_2, L18_2, L19_2)
      L16_2 = L14_2
      L15_2 = L14_2.AnimateToPoint
      L17_2 = L14_2.CustomData
      L17_2 = L17_2.nBaseColor
      L18_2 = 0
      L19_2 = true
      L15_2(L16_2, L17_2, L18_2, L19_2)
      L16_2 = L14_2
      L15_2 = L14_2.SetRotation
      L17_2 = 0
      L15_2(L16_2, L17_2)
    end
    L10_2 = _InitializeDefaultSectors
    L11_2 = L2_2
    L10_2(L11_2)
    L11_2 = L7_2
    L10_2 = L7_2.GetLocation
    L10_2, L11_2, L12_2, L13_2 = L10_2(L11_2)
    L14_2 = L10_2 + L12_2
    L14_2 = L14_2 * 0.5
    L15_2 = L11_2 + L13_2
    L15_2 = L15_2 * 0.5
    L16_2 = L2_2.CustomData
    L16_2.nCenterX = L14_2
    L16_2 = L2_2.CustomData
    L16_2.nCenterY = L15_2
    L16_2 = pairs
    L17_2 = L3_2
    L16_2, L17_2, L18_2 = L16_2(L17_2)
    for L19_2, L20_2 in L16_2, L17_2, L18_2 do
      L21_2 = L20_2.CustomData
      L23_2 = L20_2
      L22_2 = L20_2.AddAnimationPoint
      L24_2 = {}
      L24_2.x1 = L10_2
      L24_2.y1 = L11_2
      L24_2.x2 = L12_2
      L24_2.y2 = L13_2
      L22_2 = L22_2(L23_2, L24_2)
      L21_2.nOpenPoint = L22_2
      L21_2 = L20_2.CustomData
      L23_2 = L20_2
      L22_2 = L20_2.AddAnimationPoint
      L24_2 = {}
      L24_2.x1 = L14_2
      L24_2.y1 = L15_2
      L24_2.x2 = L14_2
      L24_2.y2 = L15_2
      L22_2 = L22_2(L23_2, L24_2)
      L21_2.nClosePoint = L22_2
      L22_2 = L20_2
      L21_2 = L20_2.SetLocation
      L23_2 = L14_2
      L24_2 = L15_2
      L25_2 = L14_2
      L26_2 = L15_2
      L21_2(L22_2, L23_2, L24_2, L25_2, L26_2)
    end
    L16_2 = L7_2.CustomData
    L18_2 = L7_2
    L17_2 = L7_2.AddAnimationPoint
    L19_2 = {}
    L20_2 = nBaseBgR
    L19_2.RedLevel = L20_2
    L20_2 = nBaseBgG
    L19_2.GreenLevel = L20_2
    L20_2 = nBaseBgB
    L19_2.BlueLevel = L20_2
    L17_2 = L17_2(L18_2, L19_2)
    L16_2.nBaseColor = L17_2
    L16_2 = L7_2.CustomData
    L18_2 = L7_2
    L17_2 = L7_2.AddAnimationPoint
    L19_2 = {}
    L19_2.RedLevel = 200
    L19_2.GreenLevel = 0
    L19_2.BlueLevel = 0
    L17_2 = L17_2(L18_2, L19_2)
    L16_2.nRedColor = L17_2
    L16_2 = L7_2.CustomData
    L18_2 = L7_2
    L17_2 = L7_2.AddAnimationPoint
    L19_2 = {}
    L19_2.RedLevel = 0
    L19_2.GreenLevel = 255
    L19_2.BlueLevel = 0
    L17_2 = L17_2(L18_2, L19_2)
    L16_2.nGreenColor = L17_2
    L16_2 = L5_2.CustomData
    L18_2 = L5_2
    L17_2 = L5_2.AddAnimationPoint
    L19_2 = {}
    L19_2.TranslucencyLevel = 255
    L17_2 = L17_2(L18_2, L19_2)
    L16_2.nBasePoint = L17_2
    L16_2 = L5_2.CustomData
    L18_2 = L5_2
    L17_2 = L5_2.AddAnimationPoint
    L19_2 = {}
    L19_2.TranslucencyLevel = 0
    L17_2 = L17_2(L18_2, L19_2)
    L16_2.nFadePoint = L17_2
    L16_2 = L2_2.CustomData
    L16_2.oFeedback = L5_2
    L16_2 = Sys
    L16_2 = L16_2.IsConfirmOnCircle
    if L16_2 then
      L16_2 = Sys
      L16_2 = L16_2.IsConfirmOnCircle
      L16_2 = L16_2()
      if L16_2 then
        L17_2 = L6_2
        L16_2 = L6_2.SetTexture
        L18_2 = "icon_hijack_button_B"
        L16_2(L17_2, L18_2)
      end
    end
  end
end

_InitializeMinigame = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oMinigame
  if A1_2 then
    L3_2 = A0_2.CustomData
    L3_2.bExiting = false
    L4_2 = L2_2
    L3_2 = L2_2.SetColor
    L5_2 = 255
    L6_2 = 255
    L7_2 = 255
    L8_2 = 255
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
    L3_2 = L2_2.CustomData
    L3_2 = L3_2.oBg
    L5_2 = L3_2
    L4_2 = L3_2.AnimateToPoint
    L6_2 = L3_2.CustomData
    L6_2 = L6_2.nBaseColor
    L7_2 = 0
    L8_2 = true
    L4_2(L5_2, L6_2, L7_2, L8_2)
    L5_2 = L3_2
    L4_2 = L3_2.SetColor
    L6_2 = nBaseBgR
    L7_2 = nBaseBgG
    L8_2 = nBaseBgB
    L9_2 = 255
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
    L4_2 = L2_2.CustomData
    L4_2 = L4_2.oCursor
    L6_2 = L4_2
    L5_2 = L4_2.SetColor
    L7_2 = 255
    L8_2 = 255
    L9_2 = 255
    L10_2 = 255
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
    L6_2 = A0_2
    L5_2 = A0_2.SetEventHandler
    L7_2 = "ControllerInput"
    L8_2 = _HandleInput
    L5_2(L6_2, L7_2, L8_2)
    L5_2 = MrxGuiBase
    L5_2 = L5_2.GetControlFocus
    L6_2 = A0_2
    L7_2 = false
    L5_2(L6_2, L7_2)
    L5_2 = L2_2.CustomData
    L5_2.nCost = 0
    L5_2 = L2_2.CustomData
    L6_2 = L2_2.CustomData
    L6_2 = L6_2.nCashPerSecond
    if not L6_2 then
      L6_2 = _nMoneyCost
    end
    L5_2.nCashPerSecond = L6_2
    L5_2 = L2_2.CustomData
    L5_2 = L5_2.oCost
    L6_2 = L5_2
    L5_2 = L5_2.SetText
    L7_2 = MrxUtil
    L7_2 = L7_2.FormatMoney
    L8_2 = L2_2.CustomData
    L8_2 = L8_2.nCost
    L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2 = L7_2(L8_2)
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
    L5_2 = L2_2.CustomData
    L5_2.nTime = 0
    L5_2 = L2_2.CustomData
    L5_2 = L5_2.oTime
    L6_2 = L5_2
    L5_2 = L5_2.SetText
    L7_2 = "00:00:00"
    L5_2(L6_2, L7_2)
    L5_2 = L2_2.CustomData
    L5_2 = L5_2.oCost
    L6_2 = L5_2
    L5_2 = L5_2.SetEventHandler
    L7_2 = "GuiUpdate"
    L8_2 = _CostUpdate
    L5_2(L6_2, L7_2, L8_2)
    L5_2 = L2_2.CustomData
    L5_2 = L5_2.oCost
    L6_2 = L5_2
    L5_2 = L5_2.SetVisible
    L7_2 = true
    L5_2(L6_2, L7_2)
    L5_2 = L2_2.CustomData
    L5_2 = L5_2.oTime
    L6_2 = L5_2
    L5_2 = L5_2.SetEventHandler
    L7_2 = "GuiUpdate"
    L8_2 = _TimeUpdate
    L5_2(L6_2, L7_2, L8_2)
    L5_2 = L2_2.CustomData
    L5_2 = L5_2.oTime
    L6_2 = L5_2
    L5_2 = L5_2.SetVisible
    L7_2 = true
    L5_2(L6_2, L7_2)
    L5_2 = _CreateWidgetsFromSectorData
    L6_2 = L2_2
    L5_2(L6_2)
    L6_2 = L2_2
    L5_2 = L2_2.SetVisible
    L7_2 = false
    L5_2(L6_2, L7_2)
    L6_2 = L2_2
    L5_2 = L2_2.GetChildren
    L5_2 = L5_2(L6_2)
    L6_2 = pairs
    L7_2 = L5_2
    L6_2, L7_2, L8_2 = L6_2(L7_2)
    for L9_2, L10_2 in L6_2, L7_2, L8_2 do
      L12_2 = L10_2
      L11_2 = L10_2.AnimateToPoint
      L13_2 = L10_2.CustomData
      L13_2 = L13_2.nClosePoint
      L14_2 = 0
      L15_2 = true
      L11_2(L12_2, L13_2, L14_2, L15_2)
    end
  else
    L4_2 = L2_2
    L3_2 = L2_2.SetVisible
    L5_2 = false
    L3_2(L4_2, L5_2)
  end
end

_OpenMinigame = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oMinigame
  L3_2 = L2_2.CustomData
  L4_2 = L2_2.CustomData
  L4_2 = L4_2.nCost
  L5_2 = L2_2.CustomData
  L5_2 = L5_2.nCashPerSecond
  L5_2 = L5_2 * A1_2
  L4_2 = L4_2 + L5_2
  L3_2.nCost = L4_2
  L4_2 = A0_2
  L3_2 = A0_2.SetText
  L5_2 = MrxUtil
  L5_2 = L5_2.FormatMoney
  L6_2 = L2_2.CustomData
  L6_2 = L6_2.nCost
  L5_2, L6_2 = L5_2(L6_2)
  L3_2(L4_2, L5_2, L6_2)
end

_CostUpdate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oMinigame
  L2_2 = L2_2.CustomData
  L2_2 = L2_2.nTime
  L2_2 = L2_2 + A1_2
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oMinigame
  L3_2 = L3_2.CustomData
  L3_2.nTime = L2_2
  L3_2 = Math
  L3_2 = L3_2.floor
  L4_2 = L2_2 / 60
  L3_2 = L3_2(L4_2)
  L4_2 = Math
  L4_2 = L4_2.floor
  L5_2 = L3_2 * 60
  L5_2 = L2_2 - L5_2
  L4_2 = L4_2(L5_2)
  L5_2 = Math
  L5_2 = L5_2.floor
  L6_2 = Math
  L6_2 = L6_2.floor
  L7_2 = L2_2
  L6_2 = L6_2(L7_2)
  L6_2 = L2_2 - L6_2
  L6_2 = L6_2 * 100
  L5_2 = L5_2(L6_2)
  if L3_2 < 10 then
    L6_2 = "0"
    L7_2 = L3_2
    L3_2 = L6_2 .. L7_2
  end
  if L4_2 < 10 then
    L6_2 = "0"
    L7_2 = L4_2
    L4_2 = L6_2 .. L7_2
  end
  if L5_2 < 10 then
    L6_2 = "0"
    L7_2 = L5_2
    L5_2 = L6_2 .. L7_2
  end
  L7_2 = A0_2
  L6_2 = A0_2.SetText
  L8_2 = L3_2
  L9_2 = ":"
  L10_2 = L4_2
  L11_2 = ":"
  L12_2 = L5_2
  L8_2 = L8_2 .. L9_2 .. L10_2 .. L11_2 .. L12_2
  L6_2(L7_2, L8_2)
end

_TimeUpdate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  if A1_2 then
    L2_2 = MrxGuiBase
    L2_2 = L2_2.ReleaseControlFocus
    L3_2 = A0_2
    L2_2(L3_2)
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.oMinigame
    L3_2 = MrxGuiBase
    L3_2 = L3_2.ReleaseControlFocus
    L4_2 = L2_2
    L3_2(L4_2)
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.oReticle
    L4_2 = L3_2
    L3_2 = L3_2.SetVisible
    L5_2 = true
    L3_2(L4_2, L5_2)
    L3_2 = type
    L4_2 = L2_2.CustomData
    L4_2 = L4_2.nCost
    L3_2 = L3_2(L4_2)
    if "number" == L3_2 then
      L3_2 = MrxPmc
      L3_2 = L3_2.AddCashQty
      L4_2 = L2_2.CustomData
      L4_2 = L4_2.nCost
      L4_2 = L4_2 * -1
      L5_2 = nil
      L6_2 = "[Generic.SupportDesignators.Satellite]"
      L3_2(L4_2, L5_2, L6_2)
    end
    L3_2 = L2_2.CustomData
    L3_2 = L3_2.oCursor
    L5_2 = L3_2
    L4_2 = L3_2.AnimateToPoint
    L6_2 = L3_2.CustomData
    L6_2 = L6_2.nStartPoint
    L7_2 = 0
    L8_2 = true
    L4_2(L5_2, L6_2, L7_2, L8_2)
    L4_2 = L2_2.CustomData
    L4_2 = L4_2.oBg
    L6_2 = L4_2
    L5_2 = L4_2.AnimateToPoint
    L7_2 = L4_2.CustomData
    L7_2 = L7_2.nBaseColor
    L8_2 = 0
    L9_2 = true
    L5_2(L6_2, L7_2, L8_2, L9_2)
    L5_2 = pairs
    L6_2 = L2_2.CustomData
    L6_2 = L6_2.tSectorData
    L5_2, L6_2, L7_2 = L5_2(L6_2)
    for L8_2, L9_2 in L5_2, L6_2, L7_2 do
      L10_2 = L2_2.CustomData
      L10_2 = L10_2.tSectorWidgets
      L10_2 = L10_2[L8_2]
      L12_2 = L10_2
      L11_2 = L10_2.AnimateToPoint
      L13_2 = L10_2.CustomData
      L13_2 = L13_2.nBaseColor
      L14_2 = 0
      L15_2 = true
      L11_2(L12_2, L13_2, L14_2, L15_2)
    end
    L6_2 = L2_2
    L5_2 = L2_2.SetVisible
    L7_2 = false
    L5_2(L6_2, L7_2)
    L6_2 = L2_2
    L5_2 = L2_2.SetEventHandler
    L7_2 = "GuiUpdate"
    L8_2 = nil
    L5_2(L6_2, L7_2, L8_2)
    L5_2 = L2_2.CustomData
    L5_2 = L5_2.oCost
    L6_2 = L5_2
    L5_2 = L5_2.SetEventHandler
    L7_2 = "GuiUpdate"
    L8_2 = nil
    L5_2(L6_2, L7_2, L8_2)
    L5_2 = L2_2.CustomData
    L5_2 = L5_2.oTime
    L6_2 = L5_2
    L5_2 = L5_2.SetEventHandler
    L7_2 = "GuiUpdate"
    L8_2 = nil
    L5_2(L6_2, L7_2, L8_2)
    L5_2 = L2_2.CustomData
    L5_2.nCashPerSecond = nil
    L5_2 = L2_2.CustomData
    L5_2 = L5_2.BeginEvent
    if L5_2 then
      L5_2 = Event
      L5_2 = L5_2.Delete
      L6_2 = L2_2.CustomData
      L6_2 = L6_2.BeginEvent
      L5_2(L6_2)
      L5_2 = L2_2.CustomData
      L5_2.BeginEvent = nil
    end
    L5_2 = _InitializeDefaultSectors
    L6_2 = L2_2
    L5_2(L6_2)
  end
end

_CleanupMinigame = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = _ResetSectors
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = pairs
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L2_2(L3_2)
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L7_2 = L5_2
    L6_2 = L5_2.SetVisible
    L8_2 = true
    L6_2(L7_2, L8_2)
  end
end

_ResetMinigame = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oMinigame
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bExiting
  if L2_2 then
    return
  end
  L3_2 = L1_2
  L2_2 = L1_2.SetVisible
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oReticle
  L3_2 = L2_2
  L2_2 = L2_2.SetVisible
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = L1_2.CustomData
  L2_2 = L2_2.oFeedback
  L3_2 = L2_2
  L2_2 = L2_2.SetVisible
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = L1_2.CustomData
  L2_2 = L2_2.oFeedback
  L3_2 = L2_2
  L2_2 = L2_2.SetTexture
  L4_2 = "icon_success"
  L2_2(L3_2, L4_2)
  L2_2 = L1_2.CustomData
  L2_2 = L2_2.oButton
  L3_2 = L2_2
  L2_2 = L2_2.SetVisible
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = L1_2.CustomData
  L2_2 = L2_2.oButton
  L3_2 = L2_2
  L2_2 = L2_2.SetTranslucency
  L4_2 = 0
  L2_2(L3_2, L4_2)
  L2_2 = L1_2.CustomData
  L2_2 = L2_2.oCursor
  L4_2 = L2_2
  L3_2 = L2_2.SetRotation
  L5_2 = 0
  L3_2(L4_2, L5_2)
  L4_2 = L1_2
  L3_2 = L1_2.GetChildren
  L3_2 = L3_2(L4_2)
  L4_2 = 0.5
  L5_2 = pairs
  L6_2 = L3_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L11_2 = L9_2
    L10_2 = L9_2.AnimateToPoint
    L12_2 = L9_2.CustomData
    L12_2 = L12_2.nClosePoint
    L13_2 = 0
    L14_2 = true
    L10_2(L11_2, L12_2, L13_2, L14_2)
    L11_2 = L9_2
    L10_2 = L9_2.AnimateToPoint
    L12_2 = L9_2.CustomData
    L12_2 = L12_2.nOpenPoint
    L13_2 = L4_2
    L14_2 = false
    L10_2(L11_2, L12_2, L13_2, L14_2)
  end
  L5_2 = _ResetSectors
  L6_2 = L1_2
  L5_2(L6_2)
  L5_2 = pairs
  L6_2 = L1_2.CustomData
  L6_2 = L6_2.tSectorWidgets
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = L9_2.CustomData
    L10_2 = L10_2.bInUse
    if L10_2 then
      L10_2 = MrxGuiBase
      L10_2 = L10_2.PushWidgetToBack
      L11_2 = L9_2
      L10_2(L11_2)
    end
  end
  L5_2 = MrxGui
  L5_2 = L5_2.PushWidgetToBack
  L6_2 = L1_2.CustomData
  L6_2 = L6_2.oBg
  L5_2(L6_2)
  L5_2 = MrxGui
  L5_2 = L5_2.PushWidgetToFront
  L6_2 = L1_2.CustomData
  L6_2 = L6_2.oFeedback
  L5_2(L6_2)
  L5_2 = L1_2.CustomData
  L6_2 = Event
  L6_2 = L6_2.Create
  L7_2 = Event
  L7_2 = L7_2.TimerRelative
  L8_2 = {}
  L9_2 = L4_2
  L8_2[1] = L9_2
  L9_2 = _FinishBeginMinigame
  L10_2 = {}
  L11_2 = L1_2
  L10_2[1] = L11_2
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
  L5_2.BeginEvent = L6_2
  L5_2 = Sound
  L5_2 = L5_2.CueSound
  L6_2 = 0
  L7_2 = "ui_SatDes_Circular_PopUp"
  L5_2(L6_2, L7_2)
end

BeginMinigame = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L8_2 = L6_2
    L7_2 = L6_2.AnimateToPoint
    L9_2 = L6_2.CustomData
    L9_2 = L9_2.nOpenPoint
    L10_2 = 0
    L11_2 = true
    L7_2(L8_2, L9_2, L10_2, L11_2)
  end
  L2_2 = A0_2.CustomData
  L2_2.BeginEvent = nil
  L3_2 = A0_2
  L2_2 = A0_2.SetVisible
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oFeedback
  L3_2 = L2_2
  L2_2 = L2_2.SetVisible
  L4_2 = false
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2.SetEventHandler
  L4_2 = "ControllerInput"
  L5_2 = _HandleMinigameInput
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = MrxGuiBase
  L2_2 = L2_2.GetControlFocus
  L3_2 = A0_2
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oCursor
  L4_2 = L2_2
  L3_2 = L2_2.SetRotation
  L5_2 = 0
  L3_2(L4_2, L5_2)
  L3_2 = A0_2.CustomData
  L4_2 = _nMinigameTime
  L4_2 = 360 / L4_2
  L4_2 = L4_2 * 0.1
  L3_2.nTolerance = L4_2
  L4_2 = L2_2
  L3_2 = L2_2.AnimateToPoint
  L5_2 = L2_2.CustomData
  L5_2 = L5_2.nEndPoint
  L6_2 = _nMinigameTime
  L7_2 = false
  L8_2 = _MinigameCycleEnd
  L9_2 = {}
  L10_2 = A0_2
  L11_2 = _nMinigameTime
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  L3_2 = Player
  L3_2 = L3_2.GetTargetUnderReticle
  L5_2 = A0_2
  L4_2 = A0_2.GetOwner
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L4_2(L5_2)
  L3_2, L4_2, L5_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  L6_2 = A0_2.CustomData
  L6_2.nStartX = L3_2
  L6_2 = A0_2.CustomData
  L6_2.nStartZ = L5_2
  L7_2 = A0_2
  L6_2 = A0_2.SetEventHandler
  L8_2 = "GuiUpdate"
  L9_2 = _HandleMinigameUpdate
  L6_2(L7_2, L8_2, L9_2)
  L6_2 = Event
  L6_2 = L6_2.Post
  L7_2 = "Satellite Minigame Start"
  L8_2 = {}
  L10_2 = A0_2
  L9_2 = A0_2.GetOwner
  L9_2 = L9_2(L10_2)
  L8_2.uPlayer = L9_2
  L6_2(L7_2, L8_2)
end

_FinishBeginMinigame = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = A1_2.CustomData
  L3_2 = L3_2.oCursor
  L4_2 = L3_2
  L3_2 = L3_2.SetRotation
  L5_2 = 0
  L3_2(L4_2, L5_2)
  L3_2 = math
  L3_2 = L3_2.min
  L4_2 = _nMinigameTimeIncrease
  L4_2 = A2_2 * L4_2
  L5_2 = _nMinigameMaxTime
  L3_2 = L3_2(L4_2, L5_2)
  A2_2 = L3_2
  L3_2 = A1_2.CustomData
  L4_2 = 360 / A2_2
  L4_2 = L4_2 * 0.1
  L3_2.nTolerance = L4_2
  L4_2 = A0_2
  L3_2 = A0_2.AnimateToPoint
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nEndPoint
  L6_2 = A2_2
  L7_2 = true
  L8_2 = _MinigameCycleEnd
  L9_2 = {}
  L10_2 = A1_2
  L11_2 = A2_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
end

_MinigameCycleEnd = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oCursor
  L3_2 = L2_2
  L2_2 = L2_2.GetRotation
  L2_2 = L2_2(L3_2)
  L3_2 = 0.2
  L4_2 = _CollideWithSectors
  L5_2 = A0_2
  L6_2 = L2_2
  L7_2 = 0
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  if not L4_2 then
    L4_2 = -1
  end
  L5_2 = A0_2.CustomData
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.nPreviousSectorId
  if not L6_2 then
    L6_2 = -1
  end
  L5_2.nPreviousSectorId = L6_2
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nPreviousSectorId
  if L5_2 ~= L4_2 and 0 < L4_2 then
    L6_2 = Sound
    L6_2 = L6_2.CueSound
    L7_2 = 0
    L8_2 = "ui_SatDes_Circular_Beep"
    L6_2(L7_2, L8_2)
  end
  L6_2 = A0_2.CustomData
  L6_2.nPreviousSectorId = L4_2
  L6_2 = pairs
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.tSectorWidgets
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  for L9_2, L10_2 in L6_2, L7_2, L8_2 do
    if L4_2 == L9_2 then
      L12_2 = L10_2
      L11_2 = L10_2.SetColor
      L13_2 = 255
      L14_2 = 255
      L15_2 = 255
      L11_2(L12_2, L13_2, L14_2, L15_2)
    else
      L12_2 = L10_2
      L11_2 = L10_2.SetColor
      L13_2 = nSliceR
      L14_2 = nSliceG
      L15_2 = nSliceB
      L11_2(L12_2, L13_2, L14_2, L15_2)
    end
  end
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.oButton
  L7_2 = nil
  L8_2 = nil
  if 0 < L4_2 then
    L9_2 = A0_2.CustomData
    L9_2 = L9_2.tSectorData
    L9_2 = L9_2[L4_2]
    L10_2 = L9_2[1]
    L11_2 = L9_2[2]
    L10_2 = L10_2 + L11_2
    L7_2 = L10_2 / 2
    L8_2 = 80
  end
  L9_2 = Math
  L9_2 = L9_2.PolarToRect
  if L9_2 and L7_2 and L8_2 then
    L9_2 = Math
    L9_2 = L9_2.PolarToRect
    L10_2 = -L7_2
    L10_2 = L10_2 + 90
    L11_2 = L8_2
    L9_2, L10_2 = L9_2(L10_2, L11_2)
    L11_2 = A0_2.CustomData
    L11_2 = L11_2.nCenterX
    L9_2 = L9_2 + L11_2
    L11_2 = -L10_2
    L12_2 = A0_2.CustomData
    L12_2 = L12_2.nCenterY
    L10_2 = L11_2 + L12_2
    L12_2 = L6_2
    L11_2 = L6_2.SetLocation
    L13_2 = L9_2 - 16
    L14_2 = L10_2 - 16
    L15_2 = L9_2 + 16
    L16_2 = L10_2 + 16
    L11_2(L12_2, L13_2, L14_2, L15_2, L16_2)
    L12_2 = L6_2
    L11_2 = L6_2.SetVisible
    L13_2 = true
    L11_2(L12_2, L13_2)
    L12_2 = L6_2
    L11_2 = L6_2.SetTranslucency
    L13_2 = 255
    L11_2(L12_2, L13_2)
  else
    L10_2 = L6_2
    L9_2 = L6_2.SetVisible
    L11_2 = false
    L9_2(L10_2, L11_2)
    L10_2 = L6_2
    L9_2 = L6_2.SetTranslucency
    L11_2 = 0
    L9_2(L10_2, L11_2)
  end
  L9_2 = Player
  L9_2 = L9_2.GetTargetUnderReticle
  L11_2 = A0_2
  L10_2 = A0_2.GetOwner
  L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2 = L10_2(L11_2)
  L9_2, L10_2, L11_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2)
  L12_2 = A0_2.CustomData
  L12_2 = L12_2.nStartX
  L13_2 = A0_2.CustomData
  L13_2 = L13_2.nStartZ
  L14_2 = L9_2 - L12_2
  L15_2 = L9_2 - L12_2
  L14_2 = L14_2 * L15_2
  L15_2 = L11_2 - L13_2
  L16_2 = L11_2 - L13_2
  L15_2 = L15_2 * L16_2
  L14_2 = L14_2 + L15_2
  if 25 < L14_2 then
    L14_2 = MrxGuiBase
    L14_2 = L14_2.ReleaseControlFocus
    L15_2 = A0_2
    L14_2(L15_2)
    L14_2 = A0_2.CustomData
    L14_2 = L14_2.oCursor
    L16_2 = L14_2
    L15_2 = L14_2.SetRotation
    L17_2 = 0
    L15_2(L16_2, L17_2)
    L15_2 = A0_2.CustomData
    L15_2 = L15_2.oBg
    L17_2 = L15_2
    L16_2 = L15_2.SetColor
    L18_2 = nBaseBgR
    L19_2 = nBaseBgG
    L20_2 = nBaseBgB
    L16_2(L17_2, L18_2, L19_2, L20_2)
    L16_2 = _ResetSectors
    L17_2 = A0_2
    L16_2(L17_2)
    L17_2 = A0_2
    L16_2 = A0_2.SetVisible
    L18_2 = false
    L16_2(L17_2, L18_2)
    L17_2 = A0_2
    L16_2 = A0_2.SetEventHandler
    L18_2 = "GuiUpdate"
    L19_2 = nil
    L16_2(L17_2, L18_2, L19_2)
    L17_2 = A0_2
    L16_2 = A0_2.GetChildren
    L16_2 = L16_2(L17_2)
    L17_2 = pairs
    L18_2 = L16_2
    L17_2, L18_2, L19_2 = L17_2(L18_2)
    for L20_2, L21_2 in L17_2, L18_2, L19_2 do
      L23_2 = L21_2
      L22_2 = L21_2.AnimateToPoint
      L24_2 = L21_2.CustomData
      L24_2 = L24_2.nClosePoint
      L25_2 = 0
      L26_2 = true
      L22_2(L23_2, L24_2, L25_2, L26_2)
    end
    L17_2 = A0_2.ParentWidget
    L19_2 = L17_2
    L18_2 = L17_2.SetEventHandler
    L20_2 = "ControllerInput"
    L21_2 = _HandleInput
    L18_2(L19_2, L20_2, L21_2)
    L18_2 = MrxGuiBase
    L18_2 = L18_2.GetControlFocus
    L19_2 = L17_2
    L20_2 = false
    L18_2(L19_2, L20_2)
    L18_2 = L17_2.CustomData
    L18_2 = L18_2.oReticle
    L19_2 = L18_2
    L18_2 = L18_2.SetVisible
    L20_2 = true
    L18_2(L19_2, L20_2)
  end
end

_HandleMinigameUpdate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L2_2 = 0.2
  L3_2 = L1_2[1]
  L4_2 = L3_2
  L3_2 = L3_2.AnimateToPoint
  L5_2 = L1_2[1]
  L5_2 = L5_2.CustomData
  L5_2 = L5_2.nClosePoint
  L6_2 = L2_2
  L7_2 = true
  L8_2 = _FinishCompleteMinigame
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oCursor
  L5_2 = L3_2
  L4_2 = L3_2.SetVisible
  L6_2 = false
  L4_2(L5_2, L6_2)
  L5_2 = L3_2
  L4_2 = L3_2.AnimateToPoint
  L6_2 = L3_2.CustomData
  L6_2 = L6_2.nStartPoint
  L7_2 = 0
  L8_2 = true
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = A0_2.ParentWidget
  L4_2 = L4_2.CustomData
  L4_2.bExiting = true
  L4_2 = Event
  L4_2 = L4_2.Post
  L5_2 = "Satellite Targetting Success"
  L6_2 = {}
  L8_2 = A0_2
  L7_2 = A0_2.GetOwner
  L7_2 = L7_2(L8_2)
  L6_2.uPlayer = L7_2
  L4_2(L5_2, L6_2)
  L4_2 = A0_2.ParentWidget
  L4_2 = L4_2.CustomData
  L4_2.bTargettingSuccess = true
end

_CompleteMinigame = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = MrxGuiBase
  L2_2 = L2_2.ReleaseControlFocus
  L3_2 = A1_2
  L2_2(L3_2)
  L2_2 = MrxGuiBase
  L2_2 = L2_2.ReleaseControlFocus
  L3_2 = A1_2.ParentWidget
  L2_2(L3_2)
  L2_2 = Player
  L2_2 = L2_2.RequestPDAMapModeExit
  L4_2 = A1_2
  L3_2 = A1_2.GetOwner
  L3_2 = L3_2(L4_2)
  L4_2 = _RemoveSatelliteTargettingMode
  L5_2 = {}
  L6_2 = A1_2
  L5_2[1] = L6_2
  L2_2(L3_2, L4_2, L5_2)
end

_FinishCompleteMinigame = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.fCallback
  if L1_2 then
    L1_2 = A0_2.CustomData
    L1_2 = L1_2.tData
    if L1_2 then
      L1_2 = Player
      L1_2 = L1_2.GetTargetUnderReticle
      L3_2 = A0_2
      L2_2 = A0_2.GetOwner
      L2_2, L3_2, L4_2, L5_2, L6_2, L7_2 = L2_2(L3_2)
      L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
      L5_2 = table
      L5_2 = L5_2.insert
      L6_2 = A0_2.CustomData
      L6_2 = L6_2.tData
      L7_2 = L4_2
      L5_2(L6_2, L7_2)
      L5_2 = table
      L5_2 = L5_2.insert
      L6_2 = A0_2.CustomData
      L6_2 = L6_2.tData
      L7_2 = L1_2
      L5_2(L6_2, L7_2)
      L5_2 = table
      L5_2 = L5_2.insert
      L6_2 = A0_2.CustomData
      L6_2 = L6_2.tData
      L7_2 = L2_2
      L5_2(L6_2, L7_2)
      L5_2 = table
      L5_2 = L5_2.insert
      L6_2 = A0_2.CustomData
      L6_2 = L6_2.tData
      L7_2 = L3_2
      L5_2(L6_2, L7_2)
      L5_2 = table
      L5_2 = L5_2.insert
      L6_2 = A0_2.CustomData
      L6_2 = L6_2.tData
      L7_2 = 1
      L5_2(L6_2, L7_2)
      L5_2 = table
      L5_2 = L5_2.insert
      L6_2 = A0_2.CustomData
      L6_2 = L6_2.tData
      L7_2 = L4_2
      L5_2(L6_2, L7_2)
      L5_2 = A0_2.CustomData
      L5_2 = L5_2.fCallback
      L6_2 = unpack
      L7_2 = A0_2.CustomData
      L7_2 = L7_2.tData
      L6_2, L7_2 = L6_2(L7_2)
      L5_2(L6_2, L7_2)
      L5_2 = A0_2.CustomData
      L5_2.fCallback = nil
      L5_2 = A0_2.CustomData
      L5_2.tData = nil
    end
  end
end

_RemoveSatelliteTargettingMode = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L2_2 = A0_2.ParentWidget
  L2_2 = L2_2.CustomData
  L2_2 = L2_2.bExiting
  if L2_2 then
    return
  end
  L2_2 = A1_2.ButtonPress
  L3_2 = MrxGuiBase
  L3_2 = L3_2.Joystick
  L3_2 = L3_2.BUTTON_ALT2_1
  if L2_2 ~= L3_2 then
    L2_2 = A1_2.ButtonPress
    L3_2 = MrxGuiBase
    L3_2 = L3_2.Joystick
    L3_2 = L3_2.BUTTON_PAD2_D
    if L2_2 ~= L3_2 then
      goto lbl_183
    end
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oCursor
  L4_2 = L2_2
  L3_2 = L2_2.GetRotation
  L3_2 = L3_2(L4_2)
  L4_2 = _CollideWithSectors
  L5_2 = A0_2
  L6_2 = L3_2
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.nTolerance
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  if L4_2 then
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.tSectorData
    L5_2 = L5_2[L4_2]
    L5_2.bHit = true
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.tSectorWidgets
    L5_2 = L5_2[L4_2]
    L6_2 = L5_2
    L5_2 = L5_2.SetVisible
    L7_2 = false
    L5_2(L6_2, L7_2)
    L5_2 = Sound
    L5_2 = L5_2.CueSound
    L6_2 = 0
    L7_2 = "ui_SatDes_Circular_Timing_Correct"
    L5_2(L6_2, L7_2)
    L5_2 = Event
    L5_2 = L5_2.Post
    L6_2 = "Satellite Minigame Sector Hit"
    L7_2 = {}
    L9_2 = A0_2
    L8_2 = A0_2.GetOwner
    L8_2 = L8_2(L9_2)
    L7_2.uPlayer = L8_2
    L5_2(L6_2, L7_2)
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.oBg
    L7_2 = L5_2
    L6_2 = L5_2.AnimateToPoint
    L8_2 = L5_2.CustomData
    L8_2 = L8_2.nGreenColor
    L9_2 = 0
    L10_2 = true
    L6_2(L7_2, L8_2, L9_2, L10_2)
    L7_2 = L5_2
    L6_2 = L5_2.AnimateToPoint
    L8_2 = L5_2.CustomData
    L8_2 = L8_2.nBaseColor
    L9_2 = 0.2
    L10_2 = false
    L6_2(L7_2, L8_2, L9_2, L10_2)
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.oFeedback
    L8_2 = L6_2
    L7_2 = L6_2.SetTexture
    L9_2 = "icon_success"
    L7_2(L8_2, L9_2)
    L8_2 = L6_2
    L7_2 = L6_2.SetLocation
    L9_2 = A0_2.CustomData
    L9_2 = L9_2.nCenterX
    L9_2 = L9_2 - 64
    L10_2 = A0_2.CustomData
    L10_2 = L10_2.nCenterY
    L10_2 = L10_2 - 64
    L11_2 = A0_2.CustomData
    L11_2 = L11_2.nCenterX
    L11_2 = L11_2 + 64
    L12_2 = A0_2.CustomData
    L12_2 = L12_2.nCenterY
    L12_2 = L12_2 + 64
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
    L8_2 = L6_2
    L7_2 = L6_2.SetVisible
    L9_2 = true
    L7_2(L8_2, L9_2)
    L8_2 = L6_2
    L7_2 = L6_2.AnimateToPoint
    L9_2 = L6_2.CustomData
    L9_2 = L9_2.nBasePoint
    L10_2 = 0
    L11_2 = true
    L7_2(L8_2, L9_2, L10_2, L11_2)
    L8_2 = L6_2
    L7_2 = L6_2.AnimateToPoint
    L9_2 = L6_2.CustomData
    L9_2 = L9_2.nFadePoint
    L10_2 = 0.5
    L11_2 = false
    L12_2 = L6_2.SetVisible
    L13_2 = {}
    L14_2 = false
    L13_2[1] = L14_2
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  else
    L5_2 = _ResetMinigame
    L6_2 = A0_2
    L5_2(L6_2)
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.oBg
    L7_2 = L5_2
    L6_2 = L5_2.AnimateToPoint
    L8_2 = L5_2.CustomData
    L8_2 = L8_2.nRedColor
    L9_2 = 0
    L10_2 = true
    L6_2(L7_2, L8_2, L9_2, L10_2)
    L7_2 = L5_2
    L6_2 = L5_2.AnimateToPoint
    L8_2 = L5_2.CustomData
    L8_2 = L8_2.nBaseColor
    L9_2 = 0.2
    L10_2 = false
    L6_2(L7_2, L8_2, L9_2, L10_2)
    L6_2 = Sound
    L6_2 = L6_2.CueSound
    L7_2 = 0
    L8_2 = "ui_SatDes_Circular_Timing_Fail"
    L6_2(L7_2, L8_2)
    L6_2 = Event
    L6_2 = L6_2.Post
    L7_2 = "Satellite Minigame Sector Miss"
    L8_2 = {}
    L10_2 = A0_2
    L9_2 = A0_2.GetOwner
    L9_2 = L9_2(L10_2)
    L8_2.uPlayer = L9_2
    L6_2(L7_2, L8_2)
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.oFeedback
    L8_2 = L6_2
    L7_2 = L6_2.SetTexture
    L9_2 = "icon_fail"
    L7_2(L8_2, L9_2)
    L8_2 = L6_2
    L7_2 = L6_2.SetLocation
    L9_2 = A0_2.CustomData
    L9_2 = L9_2.nCenterX
    L9_2 = L9_2 - 64
    L10_2 = A0_2.CustomData
    L10_2 = L10_2.nCenterY
    L10_2 = L10_2 - 64
    L11_2 = A0_2.CustomData
    L11_2 = L11_2.nCenterX
    L11_2 = L11_2 + 64
    L12_2 = A0_2.CustomData
    L12_2 = L12_2.nCenterY
    L12_2 = L12_2 + 64
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
    L8_2 = L6_2
    L7_2 = L6_2.SetVisible
    L9_2 = true
    L7_2(L8_2, L9_2)
    L8_2 = L6_2
    L7_2 = L6_2.AnimateToPoint
    L9_2 = L6_2.CustomData
    L9_2 = L9_2.nBasePoint
    L10_2 = 0
    L11_2 = true
    L7_2(L8_2, L9_2, L10_2, L11_2)
    L8_2 = L6_2
    L7_2 = L6_2.AnimateToPoint
    L9_2 = L6_2.CustomData
    L9_2 = L9_2.nFadePoint
    L10_2 = 0.5
    L11_2 = false
    L12_2 = L6_2.SetVisible
    L13_2 = {}
    L14_2 = false
    L13_2[1] = L14_2
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  end
  L5_2 = _HaveAllSectorsBeenHit
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  if L5_2 then
    L5_2 = _CompleteMinigame
    L6_2 = A0_2
    L5_2(L6_2)
  end
  ::lbl_183::
end

_HandleMinigameInput = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oMinigame
  L4_2 = L3_2.CustomData
  L4_2.fCallback = A1_2
  L4_2 = L3_2.CustomData
  L4_2.tData = A2_2
end

_SetMinigameCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = SetSectorData
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oMinigame
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

_SetMinigameSectors = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oMinigame
  L2_2 = L2_2.CustomData
  L3_2 = A1_2 or L3_2
  if not A1_2 then
    L3_2 = _nMoneyCost
  end
  L2_2.nCashPerSecond = L3_2
end

_SetMinigameCost = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = pairs
  L3_2 = A1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = type
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    if "table" == L7_2 then
      L7_2 = type
      L8_2 = L6_2[1]
      L7_2 = L7_2(L8_2)
      if "number" == L7_2 then
        L7_2 = type
        L8_2 = L6_2[2]
        L7_2 = L7_2(L8_2)
        if "number" == L7_2 then
          L7_2 = type
          L8_2 = L5_2
          L7_2 = L7_2(L8_2)
          if "number" == L7_2 then
            goto lbl_29
          end
        end
      end
    end
    L7_2 = _InitializeDefaultSectors
    L8_2 = A0_2
    L7_2(L8_2)
    do return end
    ::lbl_29::
  end
  L2_2 = {}
  L3_2 = ipairs
  L4_2 = A1_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = {}
    L2_2[L6_2] = L8_2
    L8_2 = L2_2[L6_2]
    L9_2 = L7_2[1]
    L8_2[1] = L9_2
    L8_2 = L2_2[L6_2]
    L9_2 = L7_2[2]
    L8_2[2] = L9_2
  end
  L3_2 = A0_2.CustomData
  L3_2.tSectorData = L2_2
end

SetSectorData = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = _tDefaultSectorData
  L2_2 = A0_2.CustomData
  L2_2.tSectorData = L1_2
  L2_2 = _CreateWidgetsFromSectorData
  L3_2 = A0_2
  L2_2(L3_2)
end

_InitializeDefaultSectors = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.tSectorData
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.tSectorWidgets
  L3_2 = ipairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = L7_2.CustomData
    L8_2.bInUse = nil
    L8_2 = MrxGui
    L8_2 = L8_2.RemoveWidget
    L9_2 = L7_2
    L8_2(L9_2)
  end
  L3_2 = ipairs
  L4_2 = L1_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = L2_2[L6_2]
    if L8_2 then
      L8_2 = L2_2[L6_2]
      L9_2 = L8_2
      L8_2 = L8_2.SetPieSliceRender
      L10_2 = L1_2[L6_2]
      L10_2 = L10_2[1]
      L11_2 = L1_2[L6_2]
      L11_2 = L11_2[2]
      L8_2(L9_2, L10_2, L11_2)
      L8_2 = L2_2[L6_2]
      L8_2 = L8_2.CustomData
      L8_2 = L8_2.bInUse
      if not L8_2 then
        L8_2 = L2_2[L6_2]
        L8_2 = L8_2.CustomData
        L8_2.bInUse = true
        L8_2 = MrxGuiBase
        L8_2 = L8_2.AddWidget
        L9_2 = L2_2[L6_2]
        L8_2(L9_2)
      end
    else
      L8_2 = MrxGuiBase
      L8_2 = L8_2.ImageWidget
      L9_2 = L8_2
      L8_2 = L8_2.new
      L8_2 = L8_2(L9_2)
      L9_2 = L2_2[1]
      L11_2 = L8_2
      L10_2 = L8_2.SetLocation
      L13_2 = L9_2
      L12_2 = L9_2.GetLocation
      L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L12_2(L13_2)
      L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
      L11_2 = L8_2
      L10_2 = L8_2.SetColor
      L13_2 = L9_2
      L12_2 = L9_2.GetColor
      L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L12_2(L13_2)
      L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
      L11_2 = L8_2
      L10_2 = L8_2.SetOwner
      L13_2 = L9_2
      L12_2 = L9_2.GetOwner
      L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L12_2(L13_2)
      L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
      L11_2 = L8_2
      L10_2 = L8_2.SetTexture
      L13_2 = L9_2
      L12_2 = L9_2.GetTexture
      L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L12_2(L13_2)
      L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
      L11_2 = L8_2
      L10_2 = L8_2.SetTextureCoordinates
      L13_2 = L9_2
      L12_2 = L9_2.GetTextureCoordinates
      L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L12_2(L13_2)
      L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
      L10_2 = L9_2.AnimationPoints
      L11_2 = L9_2.CustomData
      L11_2 = L11_2.nOpenPoint
      L10_2 = L10_2[L11_2]
      L11_2 = L10_2.nX1
      L12_2 = L10_2.nY1
      L13_2 = L10_2.nX2
      L14_2 = L10_2.nY2
      L15_2 = L11_2 + L13_2
      L15_2 = L15_2 * 0.5
      L16_2 = L12_2 + L14_2
      L16_2 = L16_2 * 0.5
      L17_2 = L8_2.CustomData
      L19_2 = L8_2
      L18_2 = L8_2.AddAnimationPoint
      L20_2 = {}
      L20_2.x1 = L11_2
      L20_2.y1 = L12_2
      L20_2.x2 = L13_2
      L20_2.y2 = L14_2
      L18_2 = L18_2(L19_2, L20_2)
      L17_2.nOpenPoint = L18_2
      L17_2 = L8_2.CustomData
      L19_2 = L8_2
      L18_2 = L8_2.AddAnimationPoint
      L20_2 = {}
      L20_2.x1 = L15_2
      L20_2.y1 = L16_2
      L20_2.x2 = L15_2
      L20_2.y2 = L16_2
      L18_2 = L18_2(L19_2, L20_2)
      L17_2.nClosePoint = L18_2
      L17_2 = L8_2.CustomData
      L19_2 = L8_2
      L18_2 = L8_2.AddAnimationPoint
      L20_2 = {}
      L21_2 = nSliceR
      L20_2.RedLevel = L21_2
      L21_2 = nSliceG
      L20_2.GreenLevel = L21_2
      L21_2 = nSliceB
      L20_2.BlueLevel = L21_2
      L18_2 = L18_2(L19_2, L20_2)
      L17_2.nBaseColor = L18_2
      L17_2 = L8_2.CustomData
      L19_2 = L8_2
      L18_2 = L8_2.AddAnimationPoint
      L20_2 = {}
      L20_2.RedLevel = 255
      L20_2.GreenLevel = 255
      L20_2.BlueLevel = 255
      L18_2 = L18_2(L19_2, L20_2)
      L17_2.nLitColor = L18_2
      L18_2 = L8_2
      L17_2 = L8_2.SetPieSliceRender
      L19_2 = L1_2[L6_2]
      L19_2 = L19_2[1]
      L20_2 = L1_2[L6_2]
      L20_2 = L20_2[2]
      L17_2(L18_2, L19_2, L20_2)
      L17_2 = L8_2.CustomData
      L17_2.bInUse = true
      L17_2 = L8_2.CustomData
      L17_2.bNewSector = true
      L2_2[L6_2] = L8_2
      L18_2 = A0_2
      L17_2 = A0_2.AddChild
      L19_2 = L8_2
      L17_2(L18_2, L19_2)
      L17_2 = MrxGuiBase
      L17_2 = L17_2.AddWidget
      L18_2 = L8_2
      L17_2(L18_2)
    end
  end
end

_CreateWidgetsFromSectorData = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  if not A2_2 then
    A2_2 = 0
  end
  L3_2 = ipairs
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.tSectorData
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = L7_2.bHit
    if not L8_2 then
      L8_2 = _DetectCollision
      L9_2 = A1_2
      L10_2 = L7_2[1]
      L11_2 = L7_2[2]
      L11_2 = L11_2 + A2_2
      L8_2 = L8_2(L9_2, L10_2, L11_2)
      if L8_2 then
        return L6_2
      end
    end
  end
  L3_2 = nil
  return L3_2
end

_CollideWithSectors = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2
  if A2_2 < 0 then
    A2_2 = A2_2 + 360
    if A1_2 < 0 then
      A1_2 = A1_2 + 360
    end
  end
  if A1_2 < 0 and 0 <= A2_2 then
    L3_2 = A0_2 <= A2_2
    return L3_2
  else
    L3_2 = A0_2 >= A1_2 and A0_2 <= A2_2
    return L3_2
  end
end

_DetectCollision = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = ipairs
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.tSectorData
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L5_2.bHit = nil
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.tSectorWidgets
    L6_2 = L6_2[L4_2]
    L8_2 = L6_2
    L7_2 = L6_2.SetColor
    L9_2 = 192
    L10_2 = 192
    L11_2 = 192
    L7_2(L8_2, L9_2, L10_2, L11_2)
    L8_2 = L6_2
    L7_2 = L6_2.SetVisible
    L9_2 = true
    L7_2(L8_2, L9_2)
  end
end

_ResetSectors = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = ipairs
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.tSectorData
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L5_2.bHit
    if not L6_2 then
      L6_2 = false
      return L6_2
    end
  end
  L1_2 = true
  return L1_2
end

_HaveAllSectorsBeenHit = L0_1
