local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGuiBase"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSound"
L0_1(L1_1)
L0_1 = nil

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2)
  local L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2
  L7_2 = type
  L8_2 = A2_2
  L7_2 = L7_2(L8_2)
  if "string" ~= L7_2 then
    A2_2 = " "
  end
  L7_2 = type
  L8_2 = A1_2
  L7_2 = L7_2(L8_2)
  if "string" ~= L7_2 then
    A1_2 = " "
  end
  L7_2 = type
  L8_2 = A3_2
  L7_2 = L7_2(L8_2)
  if "number" ~= L7_2 then
    A3_2 = 0.2
  end
  L7_2 = type
  L8_2 = A4_2
  L7_2 = L7_2(L8_2)
  if "number" ~= L7_2 then
    A4_2 = 0.2
  end
  L7_2 = A0_2.CustomData
  L7_2.fCallback = A5_2
  L7_2 = A0_2.CustomData
  L7_2.tCallbackData = A6_2
  L7_2 = A0_2.CustomData
  L7_2.nFadeOutTime = A4_2
  L8_2 = A0_2
  L7_2 = A0_2.GetChildren
  L7_2 = L7_2(L8_2)
  L8_2 = L7_2[2]
  L10_2 = L8_2
  L9_2 = L8_2.SetTexture
  L11_2 = A1_2
  L9_2(L10_2, L11_2)
  L9_2 = A0_2.CustomData
  L9_2.oShowWidget = nil
  L9_2 = L7_2[3]
  L10_2 = L9_2
  L9_2 = L9_2.SetText
  L11_2 = A2_2
  L9_2(L10_2, L11_2)
  L9_2 = L7_2[3]
  L10_2 = L9_2
  L9_2 = L9_2.Wrap
  L9_2(L10_2)
  L9_2 = pairs
  L10_2 = L7_2
  L9_2, L10_2, L11_2 = L9_2(L10_2)
  for L12_2, L13_2 in L9_2, L10_2, L11_2 do
    L14_2 = MrxGuiBase
    L14_2 = L14_2.AddWidget
    L15_2 = L13_2
    L14_2(L15_2)
  end
  L9_2 = 400
  L10_2 = L7_2[3]
  L11_2 = L10_2
  L10_2 = L10_2.GetLocation
  L10_2 = L10_2(L11_2)
  L11_2 = L7_2[3]
  L12_2 = L11_2
  L11_2 = L11_2.SetLocation
  L13_2 = L10_2
  L14_2 = L7_2[3]
  L15_2 = L14_2
  L14_2 = L14_2.GetHeight
  L14_2 = L14_2(L15_2)
  L14_2 = L9_2 - L14_2
  L11_2(L12_2, L13_2, L14_2)
  L12_2 = A0_2
  L11_2 = A0_2.SetVisible
  L13_2 = true
  L11_2(L12_2, L13_2)
  L12_2 = A0_2
  L11_2 = A0_2.GetChildren
  L11_2 = L11_2(L12_2)
  L11_2 = L11_2[1]
  L13_2 = L11_2
  L12_2 = L11_2.AnimateToPoint
  L14_2 = L11_2.CustomData
  L14_2 = L14_2.nFadeInPoint
  L15_2 = A3_2
  L16_2 = true
  L17_2 = _FadeInElements
  L18_2 = {}
  L19_2 = A0_2
  L20_2 = A3_2
  L21_2 = nil
  L22_2 = 1
  L18_2[1] = L19_2
  L18_2[2] = L20_2
  L18_2[3] = L21_2
  L18_2[4] = L22_2
  L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  L13_2 = A0_2
  L12_2 = A0_2.SetEventHandler
  L14_2 = "ControllerInput"
  L15_2 = _HandleInputEvent
  L12_2(L13_2, L14_2, L15_2)
  L12_2 = MrxGuiBase
  L12_2 = L12_2.PushWidgetToFront
  L13_2 = A0_2
  L12_2(L13_2)
end

Show = L1_1

function L1_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.GetVisible
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    L1_2 = A0_2.CustomData
    L1_2 = L1_2.nFadeOutTime
  end
  return L1_2
end

IsMovieRunning = L1_1

function L1_1(A0_2)
  local L1_2
  L1_2 = A0_2.bSlowHiding
  L1_2 = L1_2 == true
  return L1_2
end

IsMovieHiding = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2)
  local L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2
  L9_2 = A0_2
  L8_2 = A0_2.GetVisible
  L8_2 = L8_2(L9_2)
  if not L8_2 then
    L8_2 = A0_2.CustomData
    L8_2 = L8_2.nFadeOutTime
    if not L8_2 then
      goto lbl_32
    end
  end
  L8_2 = true
  L0_1 = L8_2
  L8_2 = Event
  L8_2 = L8_2.Create
  L9_2 = Event
  L9_2 = L9_2.TimerRelative
  L10_2 = {}
  L11_2 = 0.05
  L10_2[1] = L11_2
  L11_2 = ShowMovie
  L12_2 = {}
  L13_2 = A0_2
  L14_2 = A1_2
  L15_2 = A2_2
  L16_2 = A3_2
  L17_2 = A4_2
  L18_2 = A5_2
  L19_2 = A6_2
  L20_2 = A7_2
  L12_2[1] = L13_2
  L12_2[2] = L14_2
  L12_2[3] = L15_2
  L12_2[4] = L16_2
  L12_2[5] = L17_2
  L12_2[6] = L18_2
  L12_2[7] = L19_2
  L12_2[8] = L20_2
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
  A0_2.retryEvent = L8_2
  do return end
  ::lbl_32::
  if A6_2 and not A7_2 then
    L8_2 = "Subtitles_"
    L9_2 = A1_2
    L8_2 = L8_2 .. L9_2
    if A1_2 == "01_VIK_01" then
      L8_2 = "TECHNOV"
    end
    A0_2.bSubtitlesLoading = true
    L9_2 = dynamic_import
    L10_2 = L8_2
    L11_2 = SubtitleImportCallback
    L12_2 = {}
    L13_2 = {}
    L14_2 = A0_2
    L15_2 = A1_2
    L16_2 = A2_2
    L17_2 = A3_2
    L18_2 = A4_2
    L19_2 = A5_2
    L20_2 = A6_2
    L13_2[1] = L14_2
    L13_2[2] = L15_2
    L13_2[3] = L16_2
    L13_2[4] = L17_2
    L13_2[5] = L18_2
    L13_2[6] = L19_2
    L13_2[7] = L20_2
    L12_2[1] = L13_2
    L9_2(L10_2, L11_2, L12_2)
    return
  end
  L8_2 = Net
  L8_2 = L8_2.IsClient
  L8_2 = L8_2()
  if L8_2 and A6_2 then
    L8_2 = A0_2.bSubtitlesLoading
    if not L8_2 then
      return
    end
  end
  L8_2 = Net
  L8_2 = L8_2.IsClient
  L8_2 = L8_2()
  if L8_2 then
    L8_2 = L0_1
    if not L8_2 then
      L8_2 = MrxGui
      L8_2 = L8_2.FadeToColor
      L9_2 = 0
      L10_2 = nil
      L11_2 = 0
      L12_2 = 0
      L13_2 = 0
      L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
    end
  end
  L8_2 = nil
  L0_1 = L8_2
  L8_2 = A7_2
  L9_2 = " "
  L10_2 = type
  L11_2 = sTexture
  L10_2 = L10_2(L11_2)
  if "string" ~= L10_2 then
    L10_2 = " "
    sTexture = L10_2
  end
  L10_2 = type
  L11_2 = A2_2
  L10_2 = L10_2(L11_2)
  if "number" ~= L10_2 then
    A2_2 = 0.2
  end
  L10_2 = type
  L11_2 = A3_2
  L10_2 = L10_2(L11_2)
  if "number" ~= L10_2 then
    A3_2 = 0.2
  end
  L10_2 = A0_2.CustomData
  L10_2.fCallback = A4_2
  L10_2 = A0_2.CustomData
  L10_2.tCallbackData = A5_2
  L10_2 = A0_2.CustomData
  L10_2.nFadeOutTime = A3_2
  L10_2 = A0_2.CustomData
  L10_2 = L10_2.oMovieWidget
  L12_2 = L10_2
  L11_2 = L10_2.SetMovie
  L13_2 = A1_2
  L11_2(L12_2, L13_2)
  L11_2 = A0_2.CustomData
  L11_2.oShowWidget = L10_2
  L11_2 = A0_2.CustomData
  L11_2 = L11_2.oPlaceholderText
  L13_2 = L11_2
  L12_2 = L11_2.SetText
  L14_2 = L9_2
  L12_2(L13_2, L14_2)
  L13_2 = L11_2
  L12_2 = L11_2.Wrap
  L12_2(L13_2)
  L12_2 = pairs
  L13_2 = A0_2.CustomData
  L13_2 = L13_2.tAddOrder
  L12_2, L13_2, L14_2 = L12_2(L13_2)
  for L15_2, L16_2 in L12_2, L13_2, L14_2 do
    L17_2 = MrxGuiBase
    L17_2 = L17_2.AddWidget
    L18_2 = L16_2
    L17_2(L18_2)
  end
  L12_2 = 400
  L14_2 = L11_2
  L13_2 = L11_2.GetLocation
  L13_2 = L13_2(L14_2)
  L15_2 = L11_2
  L14_2 = L11_2.SetLocation
  L16_2 = L13_2
  L18_2 = L11_2
  L17_2 = L11_2.GetHeight
  L17_2 = L17_2(L18_2)
  L17_2 = L12_2 - L17_2
  L14_2(L15_2, L16_2, L17_2)
  L15_2 = A0_2
  L14_2 = A0_2.SetVisible
  L16_2 = true
  L14_2(L15_2, L16_2)
  L14_2 = A0_2.CustomData
  L14_2 = L14_2.oPicture
  L15_2 = L14_2
  L14_2 = L14_2.SetVisible
  L16_2 = false
  L14_2(L15_2, L16_2)
  L14_2 = A0_2.CustomData
  L14_2 = L14_2.oBackWidget
  L16_2 = L14_2
  L15_2 = L14_2.AnimateToPoint
  L17_2 = L14_2.CustomData
  L17_2 = L17_2.nFadeInPoint
  L18_2 = A2_2
  L19_2 = true
  L20_2 = _FadeInElements
  L21_2 = {}
  L22_2 = A0_2
  L23_2 = A2_2
  L24_2 = L8_2
  L25_2 = 1
  L21_2[1] = L22_2
  L21_2[2] = L23_2
  L21_2[3] = L24_2
  L21_2[4] = L25_2
  L15_2(L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
  L16_2 = A0_2
  L15_2 = A0_2.SetEventHandler
  L17_2 = "ControllerInput"
  L18_2 = _HandleInputEvent
  L15_2(L16_2, L17_2, L18_2)
  L15_2 = Net
  L15_2 = L15_2.IsClient
  L15_2 = L15_2()
  if not L15_2 then
    L16_2 = L10_2
    L15_2 = L10_2.SetEndCallback
    L17_2 = HideSlow
    L18_2 = {}
    L19_2 = A0_2
    L18_2[1] = L19_2
    L15_2(L16_2, L17_2, L18_2)
  end
  L15_2 = Net
  L15_2 = L15_2.IsServer
  L15_2 = L15_2()
  if L15_2 then
    L15_2 = Net
    L15_2 = L15_2.SendEvent_ShowMovie
    L16_2 = A1_2
    L17_2 = A2_2
    L18_2 = A3_2
    L19_2 = A6_2
    L15_2(L16_2, L17_2, L18_2, L19_2)
  end
end

ShowMovie = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  if A1_2 then
    L2_2 = A1_2.SubtitleData
    L3_2 = type
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    if "table" ~= L3_2 then
      L2_2 = nil
    end
    L3_2 = dynamic_remove
    L4_2 = A1_2
    L3_2(L4_2)
  end
  L3_2 = ShowMovie
  L4_2 = A0_2[1]
  L5_2 = A0_2[2]
  L6_2 = A0_2[3]
  L7_2 = A0_2[4]
  L8_2 = A0_2[5]
  L9_2 = A0_2[6]
  L10_2 = A0_2[7]
  L11_2 = L2_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
end

SubtitleImportCallback = L1_1

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oShowWidget
  if L1_2 then
    L1_2 = A0_2.CustomData
    L1_2 = L1_2.oShowWidget
    L2_2 = L1_2
    L1_2 = L1_2.Play
    L1_2(L2_2)
  end
end

PlayMovie = L1_1

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oShowWidget
  if L1_2 then
    L1_2 = A0_2.CustomData
    L1_2 = L1_2.oShowWidget
    L2_2 = L1_2
    L1_2 = L1_2.Pause
    L1_2(L2_2)
  end
end

PauseMovie = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Net
  L1_2 = L1_2.IsClient
  L1_2 = L1_2()
  if L1_2 then
    A0_2.bSubtitlesLoading = nil
  end
  A0_2.bSlowHiding = nil
  L1_2 = A0_2.retryEvent
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2.retryEvent
    L1_2(L2_2)
    A0_2.retryEvent = nil
  end
  L1_2 = Net
  L1_2 = L1_2.IsServer
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = Net
    L1_2 = L1_2.SendEvent_HideMovie
    L1_2()
  end
  L1_2 = Net
  L1_2 = L1_2.IsClient
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = MrxGui
    L1_2 = L1_2.FadeFromColor
    L1_2()
  end
  L2_2 = A0_2
  L1_2 = A0_2.SetVisible
  L3_2 = false
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.SetTranslucency
  L3_2 = 0
  L1_2(L2_2, L3_2)
  L1_2 = MrxGuiBase
  L1_2 = L1_2.ReleaseControlFocus
  L2_2 = A0_2
  L3_2 = nil
  L4_2 = bWasGlobal
  L1_2(L2_2, L3_2, L4_2)
  L2_2 = A0_2
  L1_2 = A0_2.SetEventHandler
  L3_2 = "ControllerInput"
  L4_2 = nil
  L1_2(L2_2, L3_2, L4_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = MrxGuiBase
    L7_2 = L7_2.RemoveWidget
    L8_2 = L6_2
    L7_2(L8_2)
  end
  L2_2 = A0_2.CustomData
  L2_2.nFadeOutTime = nil
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L2_2 = L2_2[2]
  L4_2 = L2_2
  L3_2 = L2_2.SetTexture
  L5_2 = nil
  L3_2(L4_2, L5_2)
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oShowWidget
  if L3_2 then
    L3_2 = MrxGui
    L3_2 = L3_2.SetFadeEnabled
    L4_2 = true
    L3_2(L4_2)
    L3_2 = pairs
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.tHudStates
    L3_2, L4_2, L5_2 = L3_2(L4_2)
    for L6_2, L7_2 in L3_2, L4_2, L5_2 do
      if L7_2 then
        L8_2 = MrxGuiManager
        L8_2 = L8_2.ToggleHud
        L9_2 = L6_2
        L10_2 = true
        L8_2(L9_2, L10_2)
        L8_2 = A0_2.CustomData
        L8_2 = L8_2.tHudStates
        L8_2[L6_2] = nil
      end
    end
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.oShowWidget
    L4_2 = L3_2
    L3_2 = L3_2.Stop
    L3_2(L4_2)
    L3_2 = A0_2.CustomData
    L3_2.oShowWidget = nil
  end
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oSubtitle
  L3_2 = L3_2.StopSubtitles
  if L3_2 then
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.oSubtitle
    L4_2 = L3_2
    L3_2 = L3_2.StopSubtitles
    L3_2(L4_2)
  end
  L3_2 = MrxGui
  L3_2 = L3_2.SetGlobalFadeVisible
  L4_2 = true
  L3_2(L4_2)
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.fCallback
  if L3_2 then
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.fCallback
    L4_2 = nil
    L5_2 = type
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.tCallbackData
    L5_2 = L5_2(L6_2)
    if "table" == L5_2 then
      L5_2 = A0_2.CustomData
      L4_2 = L5_2.tCallbackData
    else
      L5_2 = {}
      L4_2 = L5_2
    end
    L5_2 = A0_2.CustomData
    L5_2.fCallback = nil
    L5_2 = A0_2.CustomData
    L5_2.tCallbackData = nil
    L5_2 = L3_2
    L6_2 = unpack
    L7_2 = L4_2
    L6_2, L7_2, L8_2, L9_2, L10_2 = L6_2(L7_2)
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  end
end

_Hide = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = Sys
  L1_2 = L1_2.RequestGameState
  L2_2 = "ingame"
  L1_2(L2_2)
  L1_2 = MrxSound
  L1_2 = L1_2.ExitCinematicState
  L1_2()
  L1_2 = Net
  L1_2 = L1_2.IsClient
  L1_2 = L1_2()
  if L1_2 then
    A0_2.bSubtitlesLoading = nil
  end
  L1_2 = MrxGuiBase
  L1_2 = L1_2.ReleaseControlFocus
  L2_2 = A0_2
  L3_2 = nil
  L4_2 = true
  L1_2(L2_2, L3_2, L4_2)
  L2_2 = A0_2
  L1_2 = A0_2.SetEventHandler
  L3_2 = "ControllerInput"
  L4_2 = nil
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.nFadeOutTime
  if not L1_2 then
    L1_2 = 0.2
  end
  if L1_2 <= 0 then
    L3_2 = A0_2
    L2_2 = A0_2._Hide
    L2_2(L3_2)
    return
  end
  L2_2 = A0_2.bSlowHiding
  if L2_2 then
    L2_2 = Net
    L2_2 = L2_2.IsClient
    L2_2 = L2_2()
    if L2_2 then
      L2_2 = MrxGui
      L2_2 = L2_2.FadeFromColor
      L2_2()
    end
  end
  A0_2.bSlowHiding = true
  L3_2 = A0_2
  L2_2 = A0_2.AnimateToPoint
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nFadeOutPoint
  L5_2 = L1_2 + 0.1
  L6_2 = true
  L7_2 = _Hide
  L8_2 = {}
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.AnimateToPoint
    L10_2 = L7_2.CustomData
    L10_2 = L10_2.nFadeOutPoint
    L11_2 = L1_2
    L12_2 = true
    L8_2(L9_2, L10_2, L11_2, L12_2)
  end
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oShowWidget
  if L3_2 then
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.oShowWidget
    L4_2 = L3_2
    L3_2 = L3_2.Stop
    L3_2(L4_2)
    L3_2 = A0_2.CustomData
    L3_2.oShowWidget = nil
    L3_2 = MrxGui
    L3_2 = L3_2.SetFadeEnabled
    L4_2 = true
    L3_2(L4_2)
    L3_2 = pairs
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.tHudStates
    L3_2, L4_2, L5_2 = L3_2(L4_2)
    for L6_2, L7_2 in L3_2, L4_2, L5_2 do
      if L7_2 then
        L8_2 = MrxGuiManager
        L8_2 = L8_2.ToggleHud
        L9_2 = L6_2
        L10_2 = true
        L8_2(L9_2, L10_2)
        L8_2 = A0_2.CustomData
        L8_2 = L8_2.tHudStates
        L8_2[L6_2] = nil
      end
    end
  end
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oSubtitle
  L3_2 = L3_2.StopSubtitles
  if L3_2 then
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.oSubtitle
    L4_2 = L3_2
    L3_2 = L3_2.StopSubtitles
    L3_2(L4_2)
  end
  L3_2 = MrxGui
  L3_2 = L3_2.SetGlobalFadeVisible
  L4_2 = true
  L3_2(L4_2)
end

HideSlow = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = A0_2
  L1_2 = A0_2.SetUseImmortalEvents
  L3_2 = true
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.SetFullscreen
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = MrxGuiBase
  L1_2 = L1_2.MovieWidget
  L2_2 = L1_2
  L1_2 = L1_2.new
  L1_2 = L1_2(L2_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetTransient
  L4_2 = false
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2.AddChild
  L4_2 = L1_2
  L2_2(L3_2, L4_2)
  L2_2 = A0_2.CustomData
  L2_2.oMovieWidget = L1_2
  L3_2 = L1_2
  L2_2 = L1_2.SetAnchoring
  L4_2 = "center"
  L5_2 = "center"
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetFullscreen
  L4_2 = "Letterbox"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L3_2 = L2_2[1]
  L4_2 = L3_2
  L3_2 = L3_2.SetFullscreen
  L5_2 = true
  L3_2(L4_2, L5_2)
  L3_2 = Show
  A0_2.Show = L3_2
  L3_2 = _Hide
  A0_2._Hide = L3_2
  L3_2 = HideSlow
  A0_2.Hide = L3_2
  L3_2 = HideSlow
  A0_2.HideSlow = L3_2
  L3_2 = ShowMovie
  A0_2.ShowMovie = L3_2
  L3_2 = PlayMovie
  A0_2.Play = L3_2
  L3_2 = PauseMovie
  A0_2.Pause = L3_2
  L3_2 = IsMovieRunning
  A0_2.IsMovieRunning = L3_2
  L3_2 = IsMovieHiding
  A0_2.IsMovieHiding = L3_2
  L3_2 = L2_2[2]
  L4_2 = L3_2
  L3_2 = L3_2.SetFullscreen
  L5_2 = "Letterbox"
  L3_2(L4_2, L5_2)
  L3_2 = A0_2.CustomData
  L4_2 = L2_2[2]
  L3_2.oPicture = L4_2
  L3_2 = A0_2.CustomData
  L5_2 = A0_2
  L4_2 = A0_2.AddAnimationPoint
  L6_2 = {}
  L6_2.TranslucencyLevel = 0
  L4_2 = L4_2(L5_2, L6_2)
  L3_2.nFadeOutPoint = L4_2
  L3_2 = A0_2.CustomData
  L5_2 = A0_2
  L4_2 = A0_2.AddAnimationPoint
  L6_2 = {}
  L6_2.TranslucencyLevel = 255
  L4_2 = L4_2(L5_2, L6_2)
  L3_2.nFadeInPoint = L4_2
  L3_2 = A0_2.CustomData
  L4_2 = L2_2[5]
  L3_2.oSubtitle = L4_2
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oSubtitle
  L3_2 = L3_2.CustomData
  L3_2.oMovie = L1_2
  L3_2 = A0_2.CustomData
  L4_2 = L2_2[6]
  L3_2.oSuperSubtitle = L4_2
  L3_2 = A0_2.CustomData
  L4_2 = L2_2[3]
  L3_2.oPlaceholderText = L4_2
  L3_2 = A0_2.CustomData
  L4_2 = L2_2[1]
  L3_2.oBackWidget = L4_2
  L3_2 = A0_2.CustomData
  L4_2 = {}
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.oBackWidget
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.oPicture
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.oPlaceholderText
  L8_2 = L2_2[4]
  L9_2 = A0_2.CustomData
  L9_2 = L9_2.oMovieWidget
  L10_2 = A0_2.CustomData
  L10_2 = L10_2.oSubtitle
  L11_2 = A0_2.CustomData
  L11_2 = L11_2.oSuperSubtitle
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L4_2[7] = L11_2
  L3_2.tAddOrder = L4_2
  L3_2 = A0_2.CustomData
  L4_2 = {}
  L3_2.tHudStates = L4_2
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = L7_2.CustomData
    L10_2 = L7_2
    L9_2 = L7_2.AddAnimationPoint
    L11_2 = {}
    L11_2.TranslucencyLevel = 0
    L9_2 = L9_2(L10_2, L11_2)
    L8_2.nFadeOutPoint = L9_2
    L8_2 = L7_2.CustomData
    L10_2 = L7_2
    L9_2 = L7_2.AddAnimationPoint
    L11_2 = {}
    L11_2.TranslucencyLevel = 255
    L9_2 = L9_2(L10_2, L11_2)
    L8_2.nFadeInPoint = L9_2
    L9_2 = L7_2
    L8_2 = L7_2.SetIgnoresPause
    L10_2 = true
    L8_2(L9_2, L10_2)
  end
  L4_2 = A0_2
  L3_2 = A0_2._Hide
  L3_2(L4_2)
  L3_2 = _GuiInternal
  L3_2 = L3_2.SetImageTextureTransience
  if L3_2 then
    L3_2 = _GuiInternal
    L3_2 = L3_2.SetImageTextureTransience
    L4_2 = L2_2[2]
    L4_2 = L4_2.BasicData
    L4_2 = L4_2.uId
    L5_2 = true
    L3_2(L4_2, L5_2)
  end
end

_HandleInitializationEvent = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = Net
  L2_2 = L2_2.IsMultiplayer
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = Net
    L2_2 = L2_2.IsServer
    L2_2 = L2_2()
    if not L2_2 then
      goto lbl_19
    end
  end
  L2_2 = MrxGuiBase
  L2_2 = L2_2.Joystick
  L2_2 = L2_2.BUTTON_PAD2_D
  L3_2 = A1_2.ButtonPress
  if L2_2 == L3_2 then
    L3_2 = A0_2
    L2_2 = A0_2.HideSlow
    L2_2(L3_2)
  end
  ::lbl_19::
end

_HandleInputEvent = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L6_2 = A1_2
  L5_2 = A1_2.GetChildren
  L5_2 = L5_2(L6_2)
  if not A2_2 then
    A2_2 = 0.2
  end
  L6_2 = A1_2.CustomData
  L6_2 = L6_2.oSubtitle
  L7_2 = pairs
  L8_2 = L5_2
  L7_2, L8_2, L9_2 = L7_2(L8_2)
  for L10_2, L11_2 in L7_2, L8_2, L9_2 do
    if L11_2 == L6_2 then
      L13_2 = L11_2
      L12_2 = L11_2.AnimateToPoint
      L14_2 = A1_2.CustomData
      L14_2 = L14_2.nFadeInPoint
      L15_2 = A2_2
      L16_2 = true
      L17_2 = _ActivateCinematicState
      L18_2 = {}
      L19_2 = A1_2
      L20_2 = A3_2
      L21_2 = 1
      L18_2[1] = L19_2
      L18_2[2] = L20_2
      L18_2[3] = L21_2
      L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
    elseif 1 < L10_2 then
      L12_2 = #L5_2
      if L10_2 < L12_2 then
        L13_2 = L11_2
        L12_2 = L11_2.AnimateToPoint
        L14_2 = A1_2.CustomData
        L14_2 = L14_2.nFadeInPoint
        L15_2 = A2_2
        L16_2 = true
        L12_2(L13_2, L14_2, L15_2, L16_2)
      end
    end
  end
end

_FadeInElements = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L4_2 = MrxGuiBase
  L4_2 = L4_2.GetControlFocus
  L5_2 = A1_2
  L6_2 = true
  L7_2 = true
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = Sys
  L4_2 = L4_2.RequestGameState
  L5_2 = "cinematic"
  L4_2(L5_2)
  L4_2 = MrxSound
  L4_2 = L4_2.EnterCinematicState
  L4_2()
  L4_2 = A1_2.CustomData
  L4_2 = L4_2.oShowWidget
  if L4_2 then
    L4_2 = MrxGui
    L4_2 = L4_2.SetFadeEnabled
    L5_2 = false
    L4_2(L5_2)
    L4_2 = Player
    L4_2 = L4_2.GetAllPlayers
    L4_2 = L4_2()
    L5_2 = pairs
    L6_2 = L4_2
    L5_2, L6_2, L7_2 = L5_2(L6_2)
    for L8_2, L9_2 in L5_2, L6_2, L7_2 do
      L10_2 = MrxGuiManager
      L10_2 = L10_2.GetHudState
      L11_2 = L9_2
      L10_2 = L10_2(L11_2)
      if L10_2 then
        L10_2 = MrxGuiManager
        L10_2 = L10_2.ToggleHud
        L11_2 = L9_2
        L12_2 = false
        L10_2(L11_2, L12_2)
        L10_2 = A1_2.CustomData
        L10_2 = L10_2.tHudStates
        L10_2[L9_2] = true
      end
    end
    L6_2 = A1_2
    L5_2 = A1_2.SetVisible
    L7_2 = false
    L5_2(L6_2, L7_2)
    L5_2 = A1_2.CustomData
    L5_2 = L5_2.oShowWidget
    L6_2 = L5_2
    L5_2 = L5_2.SetVisible
    L7_2 = true
    L5_2(L6_2, L7_2)
    L5_2 = A1_2.CustomData
    L5_2 = L5_2.oSubtitle
    L6_2 = L5_2
    L5_2 = L5_2.SetVisible
    L7_2 = true
    L5_2(L6_2, L7_2)
    L5_2 = A1_2.CustomData
    L5_2 = L5_2.oSuperSubtitle
    L6_2 = L5_2
    L5_2 = L5_2.SetVisible
    L7_2 = true
    L5_2(L6_2, L7_2)
    L6_2 = A1_2
    L5_2 = A1_2.SetTranslucency
    L7_2 = 255
    L5_2(L6_2, L7_2)
    L5_2 = A1_2.CustomData
    L5_2 = L5_2.oShowWidget
    L6_2 = L5_2
    L5_2 = L5_2.Play
    L5_2(L6_2)
    L5_2 = type
    L6_2 = A2_2
    L5_2 = L5_2(L6_2)
    if "table" == L5_2 then
      L5_2 = A1_2.CustomData
      L5_2 = L5_2.oSubtitle
      L6_2 = L5_2
      L5_2 = L5_2.BeginSubtitles
      L7_2 = A2_2
      L5_2(L6_2, L7_2)
    end
    L5_2 = MrxGui
    L5_2 = L5_2.SetGlobalFadeVisible
    L6_2 = false
    L5_2(L6_2)
  end
end

_ActivateCinematicState = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
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
    L7_2 = L7_2.RemoveWidget
    L8_2 = L6_2
    L7_2(L8_2)
  end
end

_EndHideAnimation = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2
  L1_2 = A0_2.Wrap
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetLocation
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  L5_2 = A0_2.CustomData
  L5_2.nY2 = L4_2
  L5_2 = BeginSubtitles
  A0_2.BeginSubtitles = L5_2
  L5_2 = StopSubtitles
  A0_2.StopSubtitles = L5_2
  L5_2 = A0_2.ParentWidget
  L6_2 = L5_2
  L5_2 = L5_2.GetChildren
  L5_2 = L5_2(L6_2)
  L5_2 = L5_2[6]
  L6_2 = A0_2.CustomData
  L6_2.oSuperSubtitle = L5_2
end

_InitializeSubtitleBuffer = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = Sys
  L3_2 = L3_2.SubtitlesEnabled
  if L3_2 then
    L3_2 = Sys
    L3_2 = L3_2.SubtitlesEnabled
    L3_2 = L3_2()
    if L3_2 then
      L2_2 = A1_2
  end
  else
    L3_2 = {}
    L2_2 = L3_2
    L3_2 = pairs
    L4_2 = A1_2
    L3_2, L4_2, L5_2 = L3_2(L4_2)
    for L6_2, L7_2 in L3_2, L4_2, L5_2 do
      L8_2 = L7_2[4]
      if L8_2 then
        L8_2 = table
        L8_2 = L8_2.insert
        L9_2 = L2_2
        L10_2 = L7_2
        L8_2(L9_2, L10_2)
      end
    end
  end
  L3_2 = #L2_2
  if 0 < L3_2 then
    L3_2 = table
    L3_2 = L3_2.sort
    L4_2 = L2_2
    L5_2 = _TimeLessThan
    L3_2(L4_2, L5_2)
    L3_2 = A0_2.CustomData
    L3_2.tSubtitleData = L2_2
    L4_2 = L2_2[1]
    L4_2 = L4_2[1]
    L3_2.nNextTime = L4_2
    L3_2.nNextIndex = 1
    L3_2.nDisplayTime = 0
    L3_2.sCurrentDisplay = nil
    L3_2.nCurrentTime = 0
    L3_2.sCurrentSuperDisplay = nil
    L3_2.sSuperDisplayTime = 0
    L5_2 = A0_2
    L4_2 = A0_2.SetEventHandler
    L6_2 = "GuiUpdate"
    L7_2 = HandleSubtitleUpdate
    L4_2(L5_2, L6_2, L7_2)
  end
end

BeginSubtitles = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = A0_2[1]
  L3_2 = A1_2[1]
  L2_2 = L2_2 < L3_2
  return L2_2
end

_TimeLessThan = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = A0_2.CustomData
  L1_2.tSubtitleData = nil
  L1_2.nNextTime = -1
  L1_2.nNextIndex = 1
  L1_2.nDisplayTime = 0
  L1_2.sCurrentDisplay = nil
  L1_2.nCurrentTime = 0
  L1_2.sCurrentSuperDisplay = nil
  L1_2.sSuperDisplayTime = 0
  L3_2 = A0_2
  L2_2 = A0_2.SetEventHandler
  L4_2 = "GuiUpdate"
  L5_2 = nil
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = A0_2
  L2_2 = A0_2.SetText
  L4_2 = " "
  L2_2(L3_2, L4_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oSuperSubtitle
  L3_2 = L2_2
  L2_2 = L2_2.SetText
  L4_2 = " "
  L2_2(L3_2, L4_2)
end

StopSubtitles = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = A0_2.CustomData
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oSuperSubtitle
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oMovie
  L5_2 = L4_2
  L4_2 = L4_2.GetCurrentFrame
  L4_2 = L4_2(L5_2)
  L4_2 = 0.033333335 * L4_2
  L2_2.nCurrentTime = L4_2
  L4_2 = L2_2.sCurrentDisplay
  if L4_2 then
    L4_2 = L2_2.nDisplayTime
    L4_2 = L4_2 - A1_2
    L2_2.nDisplayTime = L4_2
    L4_2 = L2_2.nDisplayTime
    if L4_2 <= 0 then
      L2_2.sCurrentDisplay = nil
      L2_2.nDisplayTime = 0
      L5_2 = A0_2
      L4_2 = A0_2.SetText
      L6_2 = " "
      L4_2(L5_2, L6_2)
    end
  end
  L4_2 = L2_2.sCurrentSuperDisplay
  if L4_2 then
    L4_2 = L2_2.sSuperDisplayTime
    L4_2 = L4_2 - A1_2
    L2_2.sSuperDisplayTime = L4_2
    L4_2 = L2_2.sSuperDisplayTime
    if L4_2 <= 0 then
      L2_2.sCurrentSuperDisplay = nil
      L2_2.sSuperDisplayTime = 0
      L5_2 = L3_2
      L4_2 = L3_2.SetText
      L6_2 = " "
      L4_2(L5_2, L6_2)
    end
  end
  L4_2 = nil
  L5_2 = nil
  L6_2 = L2_2.nNextTime
  if 0 < L6_2 then
    while true do
      L6_2 = L2_2.nNextTime
      L7_2 = L2_2.nCurrentTime
      if not (L6_2 <= L7_2) then
        break
      end
      L6_2 = L2_2.nNextTime
      if not (0 < L6_2) then
        break
      end
      L6_2 = L2_2.tSubtitleData
      L7_2 = L2_2.nNextIndex
      L6_2 = L6_2[L7_2]
      if L6_2 then
        L7_2 = L6_2[4]
        if L7_2 then
          if not L5_2 then
            L5_2 = L6_2[2]
          else
            L7_2 = L5_2
            L8_2 = "[n][n]"
            L9_2 = L6_2[2]
            L5_2 = L7_2 .. L8_2 .. L9_2
          end
          L7_2 = L6_2[3]
          if not L7_2 then
            L7_2 = 3
          end
          L2_2.sSuperDisplayTime = L7_2
        else
          if not L4_2 then
            L4_2 = L6_2[2]
          else
            L7_2 = L4_2
            L8_2 = "[n][n]"
            L9_2 = L6_2[2]
            L4_2 = L7_2 .. L8_2 .. L9_2
          end
          L7_2 = L6_2[3]
          if not L7_2 then
            L7_2 = 3
          end
          L2_2.nDisplayTime = L7_2
        end
        L7_2 = L2_2.nNextIndex
        L7_2 = L7_2 + 1
        L2_2.nNextIndex = L7_2
        L7_2 = L2_2.tSubtitleData
        L8_2 = L2_2.nNextIndex
        L7_2 = L7_2[L8_2]
        if L7_2 then
          L8_2 = L7_2[1]
          L2_2.nNextTime = L8_2
        else
          L2_2.nNextTime = -1
        end
      else
        L2_2.nNextTime = -1
      end
      if L4_2 then
        L2_2.sCurrentDisplay = L4_2
        L8_2 = A0_2
        L7_2 = A0_2.SetText
        L9_2 = L4_2
        L7_2(L8_2, L9_2)
        L8_2 = A0_2
        L7_2 = A0_2.Wrap
        L7_2(L8_2)
        L8_2 = A0_2
        L7_2 = A0_2.SetLocation
        L9_2 = nil
        L10_2 = A0_2.CustomData
        L10_2 = L10_2.nY2
        L12_2 = A0_2
        L11_2 = A0_2.GetHeight
        L11_2 = L11_2(L12_2)
        L10_2 = L10_2 - L11_2
        L11_2 = nil
        L12_2 = A0_2.CustomData
        L12_2 = L12_2.nY2
        L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
      end
      if L5_2 then
        L2_2.sCurrentSuperDisplay = L5_2
        L8_2 = L3_2
        L7_2 = L3_2.SetText
        L9_2 = L5_2
        L7_2(L8_2, L9_2)
        L8_2 = L3_2
        L7_2 = L3_2.Wrap
        L7_2(L8_2)
      end
    end
  end
end

HandleSubtitleUpdate = L1_1
