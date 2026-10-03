local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiBase"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSound"
L0_1(L1_1)
L0_1 = false
_tMovies = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = {}
  L1_2 = "attract"
  L0_2[1] = L1_2
  _tMovies = L0_2
end

Init = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2
  L1_2 = A0_2.SetUseImmortalEvents
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = _Open
  A0_2.Open = L1_2
  L1_2 = _Close
  A0_2.Close = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L1_2 = L1_2[1]
  L2_2 = L1_2
  L1_2 = L1_2.SetFullscreen
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
  L3_2 = L1_2
  L2_2 = L1_2.SetFullscreen
  L4_2 = "Letterbox"
  L2_2(L3_2, L4_2)
  L2_2 = A0_2.CustomData
  L2_2.oMovie = L1_2
  L3_2 = A0_2
  L2_2 = A0_2.SetEventHandler
  L4_2 = "GuiGameStateChange"
  L5_2 = HandleGameStateChangeEvent
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = A0_2
  L2_2 = A0_2.SetEventHandler
  L4_2 = "ControllerInput"
  L5_2 = HandleInput
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = A0_2.CustomData
  L2_2.bActive = true
  L2_2 = A0_2.CustomData
  L2_2.nMovieNum = 1
  L3_2 = A0_2
  L2_2 = A0_2.Close
  L2_2(L3_2)
end

HandleInit = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  if "Attract" == A1_2 then
    if "Enter" == A2_2 then
      L4_2 = A0_2
      L3_2 = A0_2.Open
      L3_2(L4_2)
    elseif "Exit" == A2_2 then
      L4_2 = A0_2
      L3_2 = A0_2.Close
      L3_2(L4_2)
    end
  end
end

HandleGameStateChangeEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bClosing
  if not L2_2 then
    L2_2 = Sys
    L2_2 = L2_2.RequestGameState
    L3_2 = "Shell"
    L2_2(L3_2)
    L2_2 = A0_2.CustomData
    L2_2.bClosing = true
  end
end

HandleInput = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bActive
  if L1_2 then
    return
  end
  L1_2 = A0_2.CustomData
  L1_2.bActive = true
  L2_2 = A0_2
  L1_2 = A0_2.SetVisible
  L3_2 = true
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = MrxGuiBase
    L7_2 = L7_2.AddWidgetWithChildren
    L8_2 = L6_2
    L7_2(L8_2)
  end
  L2_2 = _tMovies
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nMovieNum
  L2_2 = L2_2[L3_2]
  if not L2_2 then
    L2_2 = A0_2.CustomData
    L2_2.nMovieNum = 1
  end
  L2_2 = _tMovies
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nMovieNum
  L2_2 = L2_2[L3_2]
  L3_2 = A0_2.CustomData
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nMovieNum
  L4_2 = L4_2 + 1
  L3_2.nMovieNum = L4_2
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oMovie
  L5_2 = L3_2
  L4_2 = L3_2.SetMovie
  L6_2 = L2_2
  L4_2(L5_2, L6_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetEndCallback
  L6_2 = Sys
  L6_2 = L6_2.RequestGameState
  L7_2 = {}
  L8_2 = "shell"
  L7_2[1] = L8_2
  L4_2(L5_2, L6_2, L7_2)
  L5_2 = L3_2
  L4_2 = L3_2.Play
  L4_2(L5_2)
  L4_2 = MrxGuiBase
  L4_2 = L4_2.GetControlFocus
  L5_2 = A0_2
  L4_2(L5_2)
  L4_2 = MrxGui
  L4_2 = L4_2.FadeFromColor
  L5_2 = 0
  L4_2(L5_2)
  L4_2 = MrxSound
  L4_2 = L4_2.EnterAttractState
  L4_2()
end

_Open = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bActive
  if not L1_2 then
    return
  end
  L1_2 = A0_2.CustomData
  L1_2.bActive = false
  L1_2 = A0_2.CustomData
  L1_2.bClosing = false
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oMovie
  L3_2 = L1_2
  L2_2 = L1_2.Stop
  L2_2(L3_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetMovie
  L4_2 = nil
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2.SetVisible
  L4_2 = false
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = MrxGuiBase
    L8_2 = L8_2.RemoveWidgetWithChildren
    L9_2 = L7_2
    L8_2(L9_2)
  end
  L3_2 = MrxGuiBase
  L3_2 = L3_2.ReleaseControlFocus
  L4_2 = A0_2
  L3_2(L4_2)
  L3_2 = MrxSound
  L3_2 = L3_2.ExitAttractState
  L3_2()
end

_Close = L0_1
