local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGuiBase"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiDialogBox"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiNumericBox"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil_Shell"
L0_1(L1_1)
L0_1 = 0
DisplayDialogBox = L0_1
L0_1 = 0
CloseDialogBox = L0_1
L0_1 = 0
DisplayNumericBox = L0_1
L0_1 = 0
LoadGuiFile = L0_1
L0_1 = 0
UnloadGuiFile = L0_1
L0_1 = 0
LoadGUIFile = L0_1
L0_1 = 0
RemoveAllWidgets = L0_1
L0_1 = 0
RemoveAllWidgetsInLayout = L0_1
L0_1 = 0
DeleteTransientWidgets = L0_1
L0_1 = 0
ReAddAllWidgets = L0_1
L0_1 = 0
HideAllWidgets = L0_1
L0_1 = 0
ShowAllWidgets = L0_1
L0_1 = 0
SetAllWidgetsSleep = L0_1
L0_1 = 0
AssignLayoutToPlayer = L0_1
L0_1 = 0
DuplicateLayout = L0_1
L0_1 = 0
PushAllTextToFront = L0_1
L0_1 = 0
AddWidget = L0_1
L0_1 = 0
AddWidgetWithChildren = L0_1
L0_1 = 0
RemoveWidget = L0_1
L0_1 = 0
RemoveWidgetWithChildren = L0_1
L0_1 = 0
RemoveEverySingleWidget = L0_1
L0_1 = 0
PushWidgetToFront = L0_1
L0_1 = 0
PushWidgetToBack = L0_1
L0_1 = 0
GetWidgetByName = L0_1
L0_1 = 0
GetAllWidgetsByName = L0_1
L0_1 = 0
GetWidgetByNameAndOwner = L0_1
L0_1 = 0
RemoveAllWidgetsInLayout = L0_1
L0_1 = 0
Widget = L0_1
L0_1 = 0
ImageWidget = L0_1
L0_1 = 0
TextWidget = L0_1
L0_1 = 0
FlashWidget = L0_1
L0_1 = 0
SpriteWidget = L0_1
L0_1 = 0
MovieWidget = L0_1
L0_1 = 0
MinimapWidget = L0_1
L0_1 = false
_fObjectiveInformationCallback = L0_1
L0_1 = false
_tObjectiveInformationCallbackData = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = _fObjectiveInformationCallback
  if not L1_2 then
    L1_2 = nil
    return L1_2
  end
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "userdata" ~= L1_2 then
    L1_2 = nil
    return L1_2
  end
  L1_2 = _fObjectiveInformationCallback
  L2_2 = _tObjectiveInformationCallbackData
  L3_2 = A0_2
  return L1_2(L2_2, L3_2)
end

GetObjectiveDescription = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "function" == L2_2 then
    _fObjectiveInformationCallback = A0_2
    L2_2 = type
    L3_2 = A1_2
    L2_2 = L2_2(L3_2)
    if "table" == L2_2 then
      L2_2 = type
      L3_2 = _tObjectiveInformationCallbackData
      L2_2 = L2_2(L3_2)
      if "table" == L2_2 then
        L2_2 = table
        L2_2 = L2_2.insert
        L3_2 = _tObjectiveInformationCallbackData
        L4_2 = A1_2
        L2_2(L3_2, L4_2)
      else
        L2_2 = {}
        L3_2 = A1_2
        L2_2[1] = L3_2
        _tObjectiveInformationCallbackData = L2_2
      end
    else
      L2_2 = false
      _tObjectiveInformationCallbackData = L2_2
    end
  end
end

SetObjectiveInformationCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = type
  L2_2 = _tObjectiveInformationCallbackData
  L1_2 = L1_2(L2_2)
  if "table" == L1_2 then
    L1_2 = pairs
    L2_2 = _tObjectiveInformationCallbackData
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    for L4_2, L5_2 in L1_2, L2_2, L3_2 do
      if L5_2 == A0_2 then
        L6_2 = table
        L6_2 = L6_2.remove
        L7_2 = _tObjectiveInformationCallbackData
        L8_2 = L4_2
        L6_2(L7_2, L8_2)
        break
      end
    end
  end
end

RemoveObjectiveInformation = L0_1
L0_1 = 0
SendEvent = L0_1
L0_1 = 0
_nGlobalFadeCountNew = L0_1
L0_1 = false
_oFadeFlash = L0_1
L0_1 = false
_tFadeCallbacks = L0_1
L0_1 = false
_bCurrentlyFadingIn = L0_1
L0_1 = false
_bCurrentlyFadedIn = L0_1
L0_1 = nil
_oTimerEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = _nGlobalFadeCountNew
  if 0 < L2_2 then
    L2_2 = _bCurrentlyFadingIn
    if not L2_2 then
      L2_2 = _nGlobalFadeCountNew
      L2_2 = L2_2 + 1
      _nGlobalFadeCountNew = L2_2
      L2_2 = MrxUtil_Shell
      L2_2 = L2_2.CallWithOptionalArgs
      L3_2 = A0_2
      L4_2 = A1_2
      L2_2(L3_2, L4_2)
      return
    end
  end
  L2_2 = _tFadeCallbacks
  if not L2_2 then
    L2_2 = {}
    _tFadeCallbacks = L2_2
  end
  if A0_2 then
    L2_2 = table
    L2_2 = L2_2.insert
    L3_2 = _tFadeCallbacks
    L4_2 = {}
    L5_2 = A0_2
    L6_2 = A1_2
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L2_2(L3_2, L4_2)
  end
  L2_2 = _nGlobalFadeCountNew
  L2_2 = L2_2 + 1
  _nGlobalFadeCountNew = L2_2
  L2_2 = _oFadeFlash
  L2_2 = L2_2.CustomData
  L2_2 = L2_2.bLoaded
  if not L2_2 then
    L2_2 = _oFadeFlash
    L2_2 = L2_2.CustomData
    L2_2.bQueuedFade = true
    L2_2 = _oFadeFlash
    L2_2 = L2_2.CustomData
    L2_2 = L2_2.bLoading
    if not L2_2 then
      L2_2 = _oFadeFlash
      L2_2 = L2_2.CustomData
      L2_2.bLoading = true
      L2_2 = _oFadeFlash
      L3_2 = L2_2
      L2_2 = L2_2.SetSwfFile
      L4_2 = "loadingscreen_standalone"
      L5_2 = _CompleteFadeFlashLoad
      L6_2 = {}
      L7_2 = 0
      L6_2[1] = L7_2
      L2_2(L3_2, L4_2, L5_2, L6_2)
    end
  else
    L2_2 = _bCurrentlyFadingIn
    if not L2_2 then
      L2_2 = _nGlobalFadeCountNew
      if L2_2 == 1 then
        L2_2 = _oFadeFlash
        L3_2 = L2_2
        L2_2 = L2_2.Restart
        L2_2(L3_2)
        L2_2 = _oFadeFlash
        L3_2 = L2_2
        L2_2 = L2_2.Play
        L2_2(L3_2)
        L2_2 = _oFadeFlash
        L3_2 = L2_2
        L2_2 = L2_2.SetVisible
        L4_2 = true
        L2_2(L3_2, L4_2)
        L2_2 = true
        _bCurrentlyFadingIn = L2_2
    end
    else
      L2_2 = _bCurrentlyFadedIn
      if L2_2 then
        L2_2 = MrxUtil_Shell
        L2_2 = L2_2.ProcessCallbackTable
        L3_2 = _tFadeCallbacks
        L2_2(L3_2)
        L2_2 = {}
        _tFadeCallbacks = L2_2
      end
    end
  end
end

GlobalFadeToBlack = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = _nGlobalFadeCountNew
  L0_2 = L0_2 - 1
  _nGlobalFadeCountNew = L0_2
  L0_2 = _nGlobalFadeCountNew
  if L0_2 <= 0 then
    L0_2 = _oFadeFlash
    L0_2 = L0_2.CustomData
    L0_2 = L0_2.bLoaded
    if not L0_2 then
      L0_2 = {}
      _tFadeCallbacks = L0_2
      L0_2 = _oFadeFlash
      L0_2 = L0_2.CustomData
      L0_2.bQueuedFade = nil
    else
      L0_2 = _oTimerEvent
      if L0_2 then
        L0_2 = Event
        L0_2 = L0_2.Delete
        L1_2 = _oTimerEvent
        L0_2(L1_2)
        L0_2 = nil
        _oTimerEvent = L0_2
      end
      L0_2 = _oFadeFlash
      L1_2 = L0_2
      L0_2 = L0_2.CallActionScriptCallback
      L2_2 = "fadeOut"
      L3_2 = {}
      L0_2(L1_2, L2_2, L3_2)
      L0_2 = false
      _bCurrentlyFadedIn = L0_2
      L0_2 = false
      _bCurrentlyFadingIn = L0_2
      L0_2 = Gui
      L0_2 = L0_2.ShowLoadingHints
      if L0_2 then
        L0_2 = Gui
        L0_2 = L0_2.ShowLoadingHints
        L1_2 = false
        L0_2(L1_2)
      end
    end
    L0_2 = 0
    _nGlobalFadeCountNew = L0_2
  end
end

GlobalFadeFromBlack = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bLoaded
  if L2_2 then
    L2_2 = A1_2.sAction
    if L2_2 then
      L3_2 = A0_2
      L2_2 = A0_2.CallActionScriptCallback
      L4_2 = "textDisplay"
      L5_2 = {}
      L6_2 = "["
      L7_2 = A1_2.sAction
      L8_2 = "]"
      L6_2 = L6_2 .. L7_2 .. L8_2
      L7_2 = "["
      L8_2 = A1_2.sHint
      L9_2 = "]"
      L7_2 = L7_2 .. L8_2 .. L9_2
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      L2_2(L3_2, L4_2, L5_2)
    else
      L3_2 = A0_2
      L2_2 = A0_2.CallActionScriptCallback
      L4_2 = "textDisplay"
      L5_2 = {}
      L6_2 = " "
      L7_2 = " "
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      L2_2(L3_2, L4_2, L5_2)
    end
  end
end

HandleLoadingHint = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2
  L1_2 = A0_2.SetEventHandler
  L3_2 = "GuiUpdate"
  L4_2 = _FadeUpdate
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = false
  _bCurrentlyFadingIn = L1_2
  L1_2 = true
  _bCurrentlyFadedIn = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.CallActionScriptCallback
  L3_2 = "skullSpin"
  L4_2 = {}
  L5_2 = true
  L4_2[1] = L5_2
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Gui
  L1_2 = L1_2.ShowLoadingHints
  if L1_2 then
    L1_2 = Gui
    L1_2 = L1_2.ShowLoadingHints
    L2_2 = true
    L1_2(L2_2)
  end
end

_FinishFadeToBlack = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2.Pause
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.SetVisible
  L3_2 = false
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.SetSwfFile
  L3_2 = nil
  L1_2(L2_2, L3_2)
  L1_2 = A0_2.CustomData
  L1_2.bLoaded = false
  L1_2 = A0_2.CustomData
  L1_2.bLoading = false
end

_FinishFadeFromBlack = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = FlashWidget
  L1_2 = L0_2
  L0_2 = L0_2.new
  L0_2 = L0_2(L1_2)
  _oFadeFlash = L0_2
  L0_2 = _oFadeFlash
  L1_2 = L0_2
  L0_2 = L0_2.SetName
  L2_2 = "FlashFade"
  L0_2(L1_2, L2_2)
  L0_2 = _oFadeFlash
  L1_2 = L0_2
  L0_2 = L0_2.SetFullscreen
  L2_2 = true
  L0_2(L1_2, L2_2)
  L0_2 = _oFadeFlash
  L1_2 = L0_2
  L0_2 = L0_2.SetTransient
  L2_2 = false
  L0_2(L1_2, L2_2)
  L0_2 = _oFadeFlash
  L1_2 = L0_2
  L0_2 = L0_2.SetIgnoresPause
  L2_2 = true
  L0_2(L1_2, L2_2)
  L0_2 = _oFadeFlash
  L1_2 = L0_2
  L0_2 = L0_2.SetVisible
  L2_2 = false
  L0_2(L1_2, L2_2)
  L0_2 = _oFadeFlash
  L0_2 = L0_2.CustomData
  L0_2.bLoaded = false
  L0_2 = _oFadeFlash
  L0_2 = L0_2.CustomData
  L0_2.bLoading = false
  L0_2 = _oFadeFlash
  L1_2 = L0_2
  L0_2 = L0_2.SetEventHandler
  L2_2 = "UpdateLoadingHint"
  L3_2 = HandleLoadingHint
  L0_2(L1_2, L2_2, L3_2)
  L0_2 = AddWidget
  L1_2 = _oFadeFlash
  L0_2(L1_2)
end

_InitFadeFlash = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = _oFadeFlash
  if L0_2 then
    L0_2 = _oFadeFlash
    L1_2 = L0_2
    L0_2 = L0_2.SetSwfFile
    L2_2 = nil
    L0_2(L1_2, L2_2)
    L0_2 = _oFadeFlash
    L1_2 = L0_2
    L0_2 = L0_2.Delete
    L0_2(L1_2)
  end
end

CleanupFadeFlash = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = _oFadeFlash
  L0_2 = L0_2.CustomData
  L0_2.bLoaded = true
  L0_2 = _oFadeFlash
  L0_2 = L0_2.CustomData
  L0_2.bLoading = false
  L0_2 = _oFadeFlash
  L1_2 = L0_2
  L0_2 = L0_2.SetFlashEventHandler
  L2_2 = "wipeComplete"
  L3_2 = _FinishFadeToBlack
  L0_2(L1_2, L2_2, L3_2)
  L0_2 = _oFadeFlash
  L1_2 = L0_2
  L0_2 = L0_2.SetFlashEventHandler
  L2_2 = "close"
  L3_2 = _FinishFadeFromBlack
  L0_2(L1_2, L2_2, L3_2)
  L0_2 = _oFadeFlash
  L0_2 = L0_2.CustomData
  L0_2 = L0_2.bQueuedFade
  if L0_2 then
    L0_2 = _oFadeFlash
    L1_2 = L0_2
    L0_2 = L0_2.SetVisible
    L2_2 = true
    L0_2(L1_2, L2_2)
    L0_2 = _oFadeFlash
    L1_2 = L0_2
    L0_2 = L0_2.Restart
    L0_2(L1_2)
    L0_2 = _oFadeFlash
    L1_2 = L0_2
    L0_2 = L0_2.Play
    L0_2(L1_2)
    L0_2 = true
    _bCurrentlyFadingIn = L0_2
  else
    L0_2 = _oFadeFlash
    L1_2 = L0_2
    L0_2 = L0_2.Pause
    L0_2(L1_2)
    L0_2 = _oFadeFlash
    L1_2 = L0_2
    L0_2 = L0_2.SetVisible
    L2_2 = false
    L0_2(L1_2, L2_2)
  end
  L0_2 = _oFadeFlash
  L0_2 = L0_2.CustomData
  L0_2.bQueuedFade = nil
end

_CompleteFadeFlashLoad = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2.SetEventHandler
  L3_2 = "GuiUpdate"
  L4_2 = nil
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = MrxUtil_Shell
  L1_2 = L1_2.ProcessCallbackTable
  L2_2 = _tFadeCallbacks
  L1_2(L2_2)
  L1_2 = {}
  _tFadeCallbacks = L1_2
end

_FadeUpdate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = _oFadeFlash
  L2_2 = L1_2
  L1_2 = L1_2.SetVisible
  L3_2 = A0_2
  L1_2(L2_2, L3_2)
end

SetGlobalFadeVisible = L0_1
L0_1 = "Fullscreen Fade Effect Widget"
_sFadeWidgetName = L0_1
L0_1 = false
_oGlobalScreenFadeWidget = L0_1
L0_1 = 0
_nGlobalFadeCount = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L6_2 = type
  L7_2 = A0_2
  L6_2 = L6_2(L7_2)
  if "number" ~= L6_2 then
    A0_2 = 1
  end
  L6_2 = type
  L7_2 = A1_2
  L6_2 = L6_2(L7_2)
  if "userdata" ~= L6_2 then
    A1_2 = nil
  end
  L6_2 = type
  L7_2 = A2_2
  L6_2 = L6_2(L7_2)
  if "number" ~= L6_2 then
    A2_2 = 0
  end
  L6_2 = type
  L7_2 = A3_2
  L6_2 = L6_2(L7_2)
  if "number" ~= L6_2 then
    A3_2 = 0
  end
  L6_2 = type
  L7_2 = A4_2
  L6_2 = L6_2(L7_2)
  if "number" ~= L6_2 then
    A4_2 = 0
  end
  L6_2 = type
  L7_2 = A5_2
  L6_2 = L6_2(L7_2)
  if "number" ~= L6_2 then
    A5_2 = 255
  end
  L6_2 = nil
  if A1_2 then
    L7_2 = GetWidgetByNameAndOwner
    L8_2 = _sFadeWidgetName
    L9_2 = A1_2
    L7_2 = L7_2(L8_2, L9_2)
    L6_2 = L7_2
  else
    L6_2 = _oGlobalScreenFadeWidget
  end
  if not L6_2 then
    L7_2 = ImageWidget
    L8_2 = L7_2
    L7_2 = L7_2.new
    L7_2 = L7_2(L8_2)
    L6_2 = L7_2
    L8_2 = L6_2
    L7_2 = L6_2.SetLocation
    L9_2 = 0
    L10_2 = 0
    L11_2 = 640
    L12_2 = 480
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
    L8_2 = L6_2
    L7_2 = L6_2.SetName
    L9_2 = _sFadeWidgetName
    L7_2(L8_2, L9_2)
    L8_2 = L6_2
    L7_2 = L6_2.SetFullscreen
    L9_2 = true
    L7_2(L8_2, L9_2)
    L8_2 = L6_2
    L7_2 = L6_2.SetTransient
    L9_2 = false
    L7_2(L8_2, L9_2)
    L7_2 = L6_2.CustomData
    L9_2 = L6_2
    L8_2 = L6_2.AddAnimationPoint
    L10_2 = {}
    L10_2.TranslucencyLevel = 0
    L8_2 = L8_2(L9_2, L10_2)
    L7_2.nFadeToTransparentPoint = L8_2
    L7_2 = L6_2.CustomData
    L9_2 = L6_2
    L8_2 = L6_2.AddAnimationPoint
    L10_2 = {}
    L10_2.TranslucencyLevel = A5_2
    L8_2 = L8_2(L9_2, L10_2)
    L7_2.nFadeFromTransparentPoint = L8_2
    if not A1_2 then
      _oGlobalScreenFadeWidget = L6_2
    else
      L8_2 = L6_2
      L7_2 = L6_2.SetOwner
      L9_2 = A1_2
      L7_2(L8_2, L9_2)
    end
    L7_2 = AddWidget
    L8_2 = L6_2
    L7_2(L8_2)
  end
  if not A1_2 then
    L7_2 = _nGlobalFadeCount
    if 0 ~= L7_2 then
      goto lbl_137
    end
  end
  L8_2 = L6_2
  L7_2 = L6_2.SetColor
  L9_2 = A2_2
  L10_2 = A3_2
  L11_2 = A4_2
  L7_2(L8_2, L9_2, L10_2, L11_2)
  L8_2 = L6_2
  L7_2 = L6_2.SetTranslucency
  L9_2 = 0
  L7_2(L8_2, L9_2)
  L8_2 = L6_2
  L7_2 = L6_2.SetVisible
  L9_2 = true
  L7_2(L8_2, L9_2)
  if 0 < A0_2 then
    L8_2 = L6_2
    L7_2 = L6_2.SetAnimationPoint
    L9_2 = L6_2.CustomData
    L9_2 = L9_2.nFadeFromTransparentPoint
    L10_2 = {}
    L10_2.TranslucencyLevel = A5_2
    L7_2(L8_2, L9_2, L10_2)
    L8_2 = L6_2
    L7_2 = L6_2.AnimateToPoint
    L9_2 = L6_2.CustomData
    L9_2 = L9_2.nFadeFromTransparentPoint
    L10_2 = A0_2
    L11_2 = true
    L12_2 = nil
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  else
    L8_2 = L6_2
    L7_2 = L6_2.SetTranslucency
    L9_2 = A5_2
    L7_2(L8_2, L9_2)
    L8_2 = L6_2
    L7_2 = L6_2.SetAnimationPoint
    L9_2 = L6_2.CustomData
    L9_2 = L9_2.nFadeFromTransparentPoint
    L10_2 = {}
    L10_2.TranslucencyLevel = A5_2
    L7_2(L8_2, L9_2, L10_2)
    L8_2 = L6_2
    L7_2 = L6_2.AnimateToPoint
    L9_2 = L6_2.CustomData
    L9_2 = L9_2.nFadeFromTransparentPoint
    L10_2 = 0
    L11_2 = true
    L7_2(L8_2, L9_2, L10_2, L11_2)
  end
  ::lbl_137::
  if not A1_2 then
    L7_2 = _nGlobalFadeCount
    L7_2 = L7_2 + 1
    _nGlobalFadeCount = L7_2
  end
end

FadeToColor = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = type
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if "userdata" == L3_2 then
    L3_2 = GetWidgetByNameAndOwner
    L4_2 = _sFadeWidgetName
    L5_2 = A1_2
    L3_2 = L3_2(L4_2, L5_2)
    L2_2 = L3_2
  else
    L2_2 = _oGlobalScreenFadeWidget
    L3_2 = _nGlobalFadeCount
    if 0 < L3_2 then
      L3_2 = _nGlobalFadeCount
      L3_2 = L3_2 - 1
      _nGlobalFadeCount = L3_2
    end
  end
  if not L2_2 then
    return
  end
  L3_2 = type
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if "number" ~= L3_2 then
    A0_2 = 1
  end
  if not A1_2 then
    L3_2 = _nGlobalFadeCount
    if 0 ~= L3_2 then
      goto lbl_55
    end
  end
  if 0 < A0_2 then
    L4_2 = L2_2
    L3_2 = L2_2.AnimateToPoint
    L5_2 = L2_2.CustomData
    L5_2 = L5_2.nFadeToTransparentPoint
    L6_2 = A0_2
    L7_2 = false
    L8_2 = _HideWhenDone
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  else
    L4_2 = L2_2
    L3_2 = L2_2.AnimateToPoint
    L5_2 = L2_2.CustomData
    L5_2 = L5_2.nFadeToTransparentPoint
    L6_2 = A0_2
    L7_2 = 0
    L3_2(L4_2, L5_2, L6_2, L7_2)
    L4_2 = L2_2
    L3_2 = L2_2.SetTranslucency
    L5_2 = 0
    L3_2(L4_2, L5_2)
    L4_2 = L2_2
    L3_2 = L2_2.SetVisible
    L5_2 = false
    L3_2(L4_2, L5_2)
  end
  ::lbl_55::
end

FadeFromColor = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = _oGlobalScreenFadeWidget
  if L1_2 then
    L1_2 = _oGlobalScreenFadeWidget
    L1_2 = L1_2.BasicData
    L1_2 = L1_2.bEnabled
    if A0_2 ~= L1_2 then
      if not A0_2 then
        L1_2 = MrxGuiBase
        L1_2 = L1_2.RemoveWidget
        L2_2 = _oGlobalScreenFadeWidget
        L1_2(L2_2)
      else
        L1_2 = MrxGuiBase
        L1_2 = L1_2.AddWidget
        L2_2 = _oGlobalScreenFadeWidget
        L1_2(L2_2)
      end
    end
  end
end

SetFadeEnabled = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2.SetVisible
  L3_2 = false
  L1_2(L2_2, L3_2)
end

_HideWhenDone = L0_1
L0_1 = 0
Joystick = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L1_2 = A0_2.sText
  if not L1_2 then
    L1_2 = " "
  end
  L2_2 = A0_2.iPriority
  if not L2_2 then
    L2_2 = 5
  end
  L3_2 = A0_2.nDuration
  if not L3_2 then
    L3_2 = 2
  end
  L4_2 = A0_2.nFadeTime
  if not L4_2 then
    L4_2 = 0.5
  end
  L5_2 = A0_2.bClear
  if not L5_2 then
    L5_2 = nil
  end
  L6_2 = nil
  L7_2 = A0_2.sType
  if not L7_2 then
    L7_2 = "sText"
  end
  L8_2 = A0_2.bExclusive
  if L8_2 then
    L6_2 = false
  else
    L6_2 = true
  end
  L8_2 = MessageBox
  L9_2 = L8_2
  L8_2 = L8_2.AddMessage
  L10_2 = A0_2.sText
  L11_2 = A0_2.iPriority
  L12_2 = A0_2.nDuration
  L13_2 = A0_2.nFadeTime
  L14_2 = A0_2.bClear
  L15_2 = A0_2.bExclusive
  L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
end

AddMessage = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = MessageBox
  L1_2 = L0_2
  L0_2 = L0_2.ClearMessages
  L0_2(L1_2)
end

ClearMessages = L0_1
L0_1 = false
_bE3HudModeOn = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = {}
  L1_2.EventType = "E3HudMode"
  L1_2.bOn = A0_2
  L2_2 = SendEvent
  L3_2 = L1_2
  L2_2(L3_2)
  _bE3HudModeOn = A0_2
end

SetE3HudMode = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _bE3HudModeOn
  return L0_2
end

IsE3HudModeActive = L0_1
L0_1 = 0
_PushAllTextToFront = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = GetWidgetByName
  L1_2 = "Shell"
  L0_2 = L0_2(L1_2)
  if L0_2 then
    L1_2 = L0_2.CustomData
    L1_2 = L1_2.oFlash
    if L1_2 then
      L1_2 = L0_2.CustomData
      L1_2 = L1_2.oFlash
      L1_2 = L1_2.BasicData
      L1_2 = L1_2.uId
      return L1_2
    end
  end
  L1_2 = nil
  return L1_2
end

FindShellWidget = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = GetWidgetByName
  L2_2 = "reticle image"
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L3_2 = L1_2
    L2_2 = L1_2.GetLocation
    L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
    L6_2 = L4_2 - L2_2
    return L6_2
  end
  L2_2 = 48
  return L2_2
end

GetReticleSize = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = MrxGuiDialogBox
  L0_2 = L0_2.DisplayDialogBox
  DisplayDialogBox = L0_2
  L0_2 = MrxGuiDialogBox
  L0_2 = L0_2.Close
  CloseDialogBox = L0_2
  L0_2 = MrxGuiNumericBox
  L0_2 = L0_2.DisplayNumericBox
  DisplayNumericBox = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.LoadGUIFile
  LoadGuiFile = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.UnloadGUIFile
  UnloadGuiFile = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.LoadGUIFile
  LoadGUIFile = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.RemoveAllWidgetsInLayout
  RemoveAllWidgets = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.RemoveAllWidgetsInLayout
  RemoveAllWidgetsInLayout = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.DeleteTransientWidgets
  DeleteTransientWidgets = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.ReAddAllWidgets
  ReAddAllWidgets = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.HideAllWidgets
  HideAllWidgets = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.ShowAllWidgets
  ShowAllWidgets = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.SetAllWidgetsSleep
  SetAllWidgetsSleep = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.AssignLayoutToPlayer
  AssignLayoutToPlayer = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.DuplicateLayout
  DuplicateLayout = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.PushAllTextToFront
  PushAllTextToFront = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.AddWidget
  AddWidget = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.AddWidgetWithChildren
  AddWidgetWithChildren = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.RemoveWidget
  RemoveWidget = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.RemoveWidgetWithChildren
  RemoveWidgetWithChildren = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.WidgetManager
  L0_2 = L0_2.RemoveAll
  RemoveEverySingleWidget = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.PushWidgetToFront
  PushWidgetToFront = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.PushWidgetToBack
  PushWidgetToBack = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.GetWidgetByName
  GetWidgetByName = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.GetAllWidgetsByName
  GetAllWidgetsByName = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.GetWidgetByNameAndOwner
  GetWidgetByNameAndOwner = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.Widget
  Widget = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.ImageWidget
  ImageWidget = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.TextWidget
  TextWidget = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.FlashWidget
  FlashWidget = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.SpriteWidget
  SpriteWidget = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.MovieWidget
  MovieWidget = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.MinimapWidget
  MinimapWidget = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.SentEvent
  SendEvent = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.Joystick
  Joystick = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.PushAllTextToFront
  _PushAllTextToFront = L0_2
  L0_2 = Sys
  L0_2 = L0_2.IsDemoMode
  if L0_2 then
    L0_2 = Sys
    L0_2 = L0_2.IsDemoMode
    L0_2 = L0_2()
    if L0_2 then
      L0_2 = SetE3HudMode
      L1_2 = true
      L0_2(L1_2)
    end
  end
end

Init = L0_1
