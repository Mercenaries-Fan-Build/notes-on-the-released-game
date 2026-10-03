local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiBase"
L0_1(L1_1)
L0_1 = "loadingscreen"
_gLoadFlashFile = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2
  L1_2 = A0_2.SetUseImmortalEvents
  L3_2 = true
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.SetFullscreen
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = A0_2.CustomData
  L1_2.bActive = false
  L1_2 = A0_2.CustomData
  L1_2.bFlashLoaded = false
  L1_2 = _SetActive
  A0_2.SetActive = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2[1]
  L3_2 = L2_2
  L2_2 = L2_2.SetFullscreen
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = MrxGui
  L2_2 = L2_2.FlashWidget
  L3_2 = L2_2
  L2_2 = L2_2.new
  L2_2 = L2_2(L3_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetTransient
  L5_2 = false
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetFullscreen
  L5_2 = true
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetIgnoresPause
  L5_2 = true
  L3_2(L4_2, L5_2)
  L3_2 = A0_2.CustomData
  L3_2.oFlash = L2_2
  L4_2 = A0_2
  L3_2 = A0_2.AddChild
  L5_2 = L2_2
  L3_2(L4_2, L5_2)
  L3_2 = MrxGui
  L3_2 = L3_2.AddWidget
  L4_2 = L2_2
  L3_2(L4_2)
  A0_2.nAnalogInputHeld = 0
  L4_2 = A0_2
  L3_2 = A0_2.SetEventHandler
  L5_2 = "ControllerInput"
  L6_2 = HandleInput
  L3_2(L4_2, L5_2, L6_2)
  L4_2 = A0_2
  L3_2 = A0_2.SetVisible
  L5_2 = false
  L3_2(L4_2, L5_2)
  L3_2 = InitSaveIcon
  L3_2()
end

HandleInit = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L3_2 = A0_2
  L2_2 = A0_2.SetActive
  L4_2 = A1_2.bLoading
  L2_2(L3_2, L4_2)
end

HandleStateChangeEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  if not A1_2 then
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.bActive
    if L2_2 then
      L2_2 = A0_2.CustomData
      L2_2 = L2_2.bFlashLoaded
      if L2_2 then
        L2_2 = A0_2.CustomData
        L2_2 = L2_2.oFlash
        L3_2 = L2_2
        L2_2 = L2_2.CallActionScriptCallback
        L4_2 = "closeLoadingScreen"
        L5_2 = {}
        L2_2(L3_2, L4_2, L5_2)
      end
      L2_2 = A0_2.CustomData
      L2_2.bActive = false
      L3_2 = A0_2
      L2_2 = A0_2.SetVisible
      L4_2 = false
      L2_2(L3_2, L4_2)
      L2_2 = A0_2.CustomData
      L2_2 = L2_2.oFlash
      L3_2 = L2_2
      L2_2 = L2_2.SetSwfFile
      L4_2 = nil
      L2_2(L3_2, L4_2)
      L2_2 = A0_2.CustomData
      L2_2.bFlashLoaded = false
      L2_2 = A0_2.CustomData
      L2_2.bFlashLoading = false
      L2_2 = MrxGuiBase
      L2_2 = L2_2.ReleaseControlFocus
      L3_2 = A0_2
      L2_2(L3_2)
  end
  elseif A1_2 then
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.bActive
    if not L2_2 then
      L2_2 = A0_2.CustomData
      L2_2.bActive = true
      L3_2 = A0_2
      L2_2 = A0_2.SetVisible
      L4_2 = true
      L2_2(L3_2, L4_2)
      L2_2 = A0_2.CustomData
      L2_2 = L2_2.bFlashLoaded
      if not L2_2 then
        L2_2 = A0_2.CustomData
        L2_2 = L2_2.bFlashLoading
        if not L2_2 then
          L2_2 = A0_2.CustomData
          L2_2 = L2_2.oFlash
          L3_2 = L2_2
          L2_2 = L2_2.SetSwfFile
          L4_2 = _gLoadFlashFile
          L5_2 = _CompleteFlashLoad
          L6_2 = {}
          L7_2 = A0_2
          L6_2[1] = L7_2
          L2_2(L3_2, L4_2, L5_2, L6_2)
          L2_2 = A0_2.CustomData
          L2_2.bFlashLoading = true
        end
      end
    end
  end
end

_SetActive = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bActive
  if not L1_2 then
    L1_2 = A0_2.CustomData
    L1_2 = L1_2.oFlash
    L2_2 = L1_2
    L1_2 = L1_2.SetSwfFile
    L3_2 = nil
    L1_2(L2_2, L3_2)
    L1_2 = A0_2.CustomData
    L1_2.bFlashLoaded = false
  else
    L1_2 = A0_2.CustomData
    L1_2.bFlashLoaded = true
    L1_2 = MrxGuiBase
    L1_2 = L1_2.GetControlFocus
    L2_2 = A0_2
    L1_2(L2_2)
  end
  L1_2 = A0_2.CustomData
  L1_2.bFlashLoading = false
end

_CompleteFlashLoad = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oFlash
  L3_2 = A0_2.nAnalogInputHeld
  L3_2 = 0 == L3_2
  L4_2 = pairs
  L5_2 = A1_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = IsAnalog
    L10_2 = tonumber
    L11_2 = L8_2
    L10_2, L11_2 = L10_2(L11_2)
    L9_2 = L9_2(L10_2, L11_2)
    if L9_2 then
      L9_2 = string
      L9_2 = L9_2.find
      L10_2 = L7_2
      L11_2 = "ButtonPress"
      L9_2 = L9_2(L10_2, L11_2)
      if L9_2 then
        L9_2 = A0_2.nAnalogInputHeld
        L9_2 = L9_2 + 1
        A0_2.nAnalogInputHeld = L9_2
      else
        L9_2 = string
        L9_2 = L9_2.find
        L10_2 = L7_2
        L11_2 = "ButtonReleased"
        L9_2 = L9_2(L10_2, L11_2)
        if L9_2 then
          L9_2 = A0_2.nAnalogInputHeld
          L9_2 = L9_2 - 1
          A0_2.nAnalogInputHeld = L9_2
        end
      end
    end
  end
  L4_2 = A0_2.nAnalogInputHeld
  L4_2 = 0 == L4_2
  if L3_2 ~= L4_2 and L4_2 then
    L6_2 = L2_2
    L5_2 = L2_2.CallActionScriptCallback
    L7_2 = "leftAnalog"
    L8_2 = {}
    L9_2 = 0
    L10_2 = 0
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L5_2(L6_2, L7_2, L8_2)
  end
  L5_2 = A0_2.nAnalogInputHeld
  if L5_2 < 0 then
    A0_2.nAnalogInputHeld = 0
  end
  L5_2 = L2_2.EventHandlers
  L5_2 = L5_2.ControllerInput
  L6_2 = L2_2
  L7_2 = A1_2
  L5_2(L6_2, L7_2)
  L5_2 = A1_2.LeftAnalogX
  if not L5_2 then
    L5_2 = A1_2.LeftAnalogY
    if not L5_2 then
      goto lbl_87
    end
  end
  L6_2 = L2_2
  L5_2 = L2_2.CallActionScriptCallback
  L7_2 = "leftAnalog"
  L8_2 = {}
  L9_2 = A1_2.LeftAnalogX
  if not L9_2 then
    L9_2 = 0
  end
  L10_2 = A1_2.LeftAnalogY
  if not L10_2 then
    L10_2 = 0
  end
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L5_2(L6_2, L7_2, L8_2)
  goto lbl_94
  ::lbl_87::
  L6_2 = L2_2
  L5_2 = L2_2.CallActionScriptCallback
  L7_2 = "leftAnalog"
  L8_2 = {}
  L9_2 = 0
  L10_2 = 0
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L5_2(L6_2, L7_2, L8_2)
  ::lbl_94::
end

HandleInput = L0_1

function L0_1(A0_2)
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

IsAnalog = L0_1
L0_1 = 64
_knSaveIconSize = L0_1
L0_1 = 0.5
_knSaveIconTime = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L0_2 = MrxGui
  L0_2 = L0_2.Widget
  L1_2 = L0_2
  L0_2 = L0_2.new
  L0_2 = L0_2(L1_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetLocation
  L3_2 = 64
  L4_2 = 48
  L5_2 = 264
  L6_2 = _knSaveIconSize
  L6_2 = 48 + L6_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetIgnoresPause
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = MrxGui
  L1_2 = L1_2.ImageWidget
  L2_2 = L1_2
  L1_2 = L1_2.new
  L1_2 = L1_2(L2_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetLocation
  L4_2 = 64
  L5_2 = 48
  L6_2 = _knSaveIconSize
  L6_2 = 64 + L6_2
  L7_2 = _knSaveIconSize
  L7_2 = 48 + L7_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = L1_2
  L2_2 = L1_2.GetLocation
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  L6_2 = L2_2 + L4_2
  L6_2 = L6_2 * 0.5
  L7_2 = L1_2.CustomData
  L9_2 = L1_2
  L8_2 = L1_2.AddAnimationPoint
  L10_2 = {}
  L10_2.x = L2_2
  L10_2.x2 = L4_2
  L8_2 = L8_2(L9_2, L10_2)
  L7_2.nOpenPoint = L8_2
  L7_2 = L1_2.CustomData
  L9_2 = L1_2
  L8_2 = L1_2.AddAnimationPoint
  L10_2 = {}
  L10_2.x = L6_2
  L10_2.x2 = L6_2
  L8_2 = L8_2(L9_2, L10_2)
  L7_2.nClosePoint = L8_2
  L7_2 = L1_2.CustomData
  L7_2.bReversed = false
  L8_2 = L1_2
  L7_2 = L1_2.SetTexture
  L9_2 = "global_loading_skull"
  L7_2(L8_2, L9_2)
  L8_2 = L1_2
  L7_2 = L1_2.SetIgnoresPause
  L9_2 = true
  L7_2(L8_2, L9_2)
  L8_2 = L0_2
  L7_2 = L0_2.AddChild
  L9_2 = L1_2
  L7_2(L8_2, L9_2)
  L7_2 = MrxGui
  L7_2 = L7_2.TextWidget
  L8_2 = L7_2
  L7_2 = L7_2.new
  L7_2 = L7_2(L8_2)
  L9_2 = L7_2
  L8_2 = L7_2.SetLocation
  L10_2 = _knSaveIconSize
  L10_2 = 64 + L10_2
  L10_2 = L10_2 + 0
  L11_2 = 68
  L8_2(L9_2, L10_2, L11_2)
  L9_2 = L7_2
  L8_2 = L7_2.SetFont
  L10_2 = "english_18"
  L8_2(L9_2, L10_2)
  L9_2 = L7_2
  L8_2 = L7_2.SetText
  L10_2 = "[SHELL.LoadSave.Saving]"
  L8_2(L9_2, L10_2)
  L9_2 = L0_2
  L8_2 = L0_2.AddChild
  L10_2 = L7_2
  L8_2(L9_2, L10_2)
  L9_2 = L0_2
  L8_2 = L0_2.SetEventHandler
  L10_2 = "ShowSaveIcon"
  L11_2 = HandleSaveIconShow
  L8_2(L9_2, L10_2, L11_2)
  L9_2 = L0_2
  L8_2 = L0_2.SetEventHandler
  L10_2 = "HideSaveIcon"
  L11_2 = HandleSaveIconHide
  L8_2(L9_2, L10_2, L11_2)
  L9_2 = L0_2
  L8_2 = L0_2.SetVisible
  L10_2 = false
  L8_2(L9_2, L10_2)
  L8_2 = L0_2.CustomData
  L8_2.oIcon = L1_2
  L8_2 = L0_2.CustomData
  L8_2.oText = L7_2
  L8_2 = MrxGui
  L8_2 = L8_2.AddWidget
  L9_2 = L0_2
  L8_2(L9_2)
  L8_2 = MrxGui
  L8_2 = L8_2.AddWidget
  L9_2 = L1_2
  L8_2(L9_2)
  L8_2 = MrxGui
  L8_2 = L8_2.AddWidget
  L9_2 = L7_2
  L8_2(L9_2)
end

InitSaveIcon = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bReversed
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.SetTextureCoordinates
    L3_2 = 0
    L4_2 = 0
    L5_2 = 1
    L6_2 = 1
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  else
    L2_2 = A0_2
    L1_2 = A0_2.SetTextureCoordinates
    L3_2 = 1
    L4_2 = 0
    L5_2 = 0
    L6_2 = 1
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  end
  L1_2 = A0_2.CustomData
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bReversed
  L2_2 = not L2_2
  L1_2.bReversed = L2_2
  L2_2 = A0_2
  L1_2 = A0_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nOpenPoint
  L4_2 = _knSaveIconTime
  L5_2 = true
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L2_2 = A0_2
  L1_2 = A0_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nClosePoint
  L4_2 = _knSaveIconTime
  L5_2 = false
  L6_2 = _SaveIconAnimationComplete
  L7_2 = {}
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
end

_SaveIconAnimationComplete = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = A0_2
  L2_2 = A0_2.SetVisible
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oIcon
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oText
  L4_2 = MrxGui
  L4_2 = L4_2.PushWidgetToFront
  L5_2 = L2_2
  L4_2(L5_2)
  L4_2 = MrxGui
  L4_2 = L4_2.PushWidgetToFront
  L5_2 = L3_2
  L4_2(L5_2)
  L5_2 = L2_2
  L4_2 = L2_2.AnimateToPoint
  L6_2 = L2_2.CustomData
  L6_2 = L6_2.nClosePoint
  L7_2 = _knSaveIconTime
  L8_2 = true
  L9_2 = _SaveIconAnimationComplete
  L10_2 = {}
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
end

HandleSaveIconShow = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = A0_2
  L2_2 = A0_2.SetVisible
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oIcon
  L4_2 = L2_2
  L3_2 = L2_2.AnimateToPoint
  L5_2 = L2_2.CustomData
  L5_2 = L5_2.nOpenPoint
  L6_2 = 0
  L7_2 = true
  L3_2(L4_2, L5_2, L6_2, L7_2)
  L3_2 = L2_2.CustomData
  L3_2.bReversed = false
  L4_2 = L2_2
  L3_2 = L2_2.SetTextureCoordinates
  L5_2 = 0
  L6_2 = 0
  L7_2 = 1
  L8_2 = 1
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
end

HandleSaveIconHide = L0_1
