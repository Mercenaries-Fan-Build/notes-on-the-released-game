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
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiShellBootstrap"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiInterface"
L0_1(L1_1)

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.LoadGUIFile
  L1_2 = "MrxGuiPauseLayout"
  L2_2 = _PauseScreenLoaded
  L0_2(L1_2, L2_2)
  L0_2 = MrxGuiShellBootstrap
  L0_2 = L0_2.SetExitMultiplayerCallback
  L1_2 = ExitMultiplayer
  L2_2 = {}
  L0_2(L1_2, L2_2)
end

Init = L0_1

function L0_1()
  local L0_2, L1_2
end

Deinit = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2.MrxGuiPauseScreen
  L1_2 = L1_2.ClosePauseScreen
  L2_2 = A0_2.AddedWidgetList
  L2_2 = L2_2[1]
  L1_2(L2_2)
  oPauseModule = A0_2
end

_PauseScreenLoaded = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = MrxGuiManager
  L3_2 = L3_2.ToggleHud
  L4_2 = A0_2
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
end

ToggleHud = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxGuiManager
  L1_2 = L1_2.CreateGui
  L2_2 = A0_2
  L1_2(L2_2)
end

CreatePlayerHud = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxGuiManager
  L1_2 = L1_2.DeleteGui
  L2_2 = A0_2
  L1_2(L2_2)
end

DeleteHud = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = MrxGuiManager
  L0_2 = L0_2.DeleteAddGuis
  L0_2()
end

DeleteAllHuds = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = MrxGuiShellBootstrap
  L0_2 = L0_2.nPlayersSelected
  return L0_2
end

GetNumberOfPlayersFromShellSelection = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = MrxGuiManager
  L3_2 = L3_2.ToggleSatellite
  L4_2 = A0_2
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
end

SetSatelliteOverlay = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = MrxGuiManager
  L2_2 = L2_2.SetLoadingCompleteCallback
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

SetOnGuiLoadedFunc = L0_1
