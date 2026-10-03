local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiBase"
L0_1(L1_1)
L0_1 = nil
oShellModule = L0_1
L0_1 = 1
nPlayersSelected = L0_1
L0_1 = false
bNeedsReloading = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.LoadGUIFile
  L1_2 = "MrxGuiLoadLayout"
  L2_2 = LoadMovieLayouts
  L3_2 = {}
  L0_2(L1_2, L2_2, L3_2)
end

Init = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = MrxGui
  L0_2 = L0_2._InitFadeFlash
  L0_2()
  L0_2 = MrxGuiBase
  L0_2 = L0_2.LoadGUIFile
  L1_2 = "MrxGuiAttractLayout"
  L0_2(L1_2)
  L0_2 = MrxGuiBase
  L0_2 = L0_2.LoadGUIFile
  L1_2 = "MrxGuiCinematicLayout"
  L0_2(L1_2)
end

LoadMovieLayouts = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = oShellModule
  if L0_2 then
    L0_2 = MrxGuiBase
    L0_2 = L0_2.RemoveAllWidgetsInLayout
    L1_2 = oShellModule
    L0_2(L1_2)
    L0_2 = nil
    oShellModule = L0_2
  end
  L0_2 = MrxGui
  L1_2 = L0_2
  L0_2 = L0_2.CleanupFadeFlash
  L0_2(L1_2)
end

Reset = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.LoadGUIFile
  L1_2 = "MrxGuiShellLayout"
  L2_2 = ShellScreenLoaded
  L0_2(L1_2, L2_2)
end

EnterShell = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = oShellModule
  if L0_2 then
    L0_2 = oShellModule
    L1_2 = L0_2
    L0_2 = L0_2.Close
    L0_2(L1_2)
    L0_2 = nil
    oShellModule = L0_2
  end
  L0_2 = MrxGui
  L1_2 = L0_2
  L0_2 = L0_2.CleanupFadeFlash
  L0_2(L1_2)
end

ExitShell = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = Sys
  L1_2 = L1_2.RequestGameState
  L2_2 = "Shell"
  L1_2(L2_2)
  oShellModule = A0_2
end

ShellScreenLoaded = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.LoadGUIFile
  L1_2 = "MrxGuiShellLayout"
  L2_2 = CloseShellOnLoad
  L0_2(L1_2, L2_2)
end

LoadShell = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  oShellModule = A0_2
  L1_2 = MrxGuiBase
  L1_2 = L1_2.GetWidgetByName
  L2_2 = "Shell"
  L1_2 = L1_2(L2_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetVisible
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = pairs
  L4_2 = L1_2
  L3_2 = L1_2.GetChildren
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L3_2(L4_2)
  L2_2, L3_2, L4_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  for L5_2 in L2_2, L3_2, L4_2 do
    L7_2 = L1_2
    L6_2 = L1_2.GetChildren
    L6_2 = L6_2(L7_2)
    L6_2 = L6_2[L5_2]
    L7_2 = L6_2
    L6_2 = L6_2.SetEnabled
    L8_2 = false
    L6_2(L7_2, L8_2)
  end
end

CloseShellOnLoad = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = type
  L1_2 = fEnterSingleplayerCallbackFunction
  L0_2 = L0_2(L1_2)
  if "function" == L0_2 then
    L0_2 = fEnterSingleplayerCallbackFunction
    L1_2 = unpack
    L2_2 = tEnterSingleplayerCallbackArguments
    L1_2, L2_2 = L1_2(L2_2)
    L0_2(L1_2, L2_2)
  end
end

SetUpSingleplayer = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = type
  L1_2 = fEnterMultiplayerCallbackFunction
  L0_2 = L0_2(L1_2)
  if "function" == L0_2 then
    L0_2 = fEnterMultiplayerCallbackFunction
    L1_2 = unpack
    L2_2 = tEnterMultiplayerCallbackArguments
    L1_2, L2_2 = L1_2(L2_2)
    L0_2(L1_2, L2_2)
  end
end

SetUpMultiplayer = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = type
  L1_2 = fExitMultiplayerCallbackFunction
  L0_2 = L0_2(L1_2)
  if "function" == L0_2 then
    L0_2 = fExitMultiplayerCallbackFunction
    L1_2 = unpack
    L2_2 = tExitMultiplayerCallbackArguments
    L1_2, L2_2 = L1_2(L2_2)
    L0_2(L1_2, L2_2)
  end
end

ExitMultiplayer = L0_1
L0_1 = false
_sSelectedCharacter = L0_1

function L0_1(A0_2)
  local L1_2
  _sSelectedCharacter = A0_2
end

SetSelectedCharacter = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _sSelectedCharacter
  if not L0_2 then
    L0_2 = nil
  end
  return L0_2
end

GetSelectedCharacter = L0_1

function L0_1(A0_2, A1_2)
  fEnterSingleplayerCallbackFunction = A0_2
  tEnterSingleplayerCallbackArguments = A1_2
end

SetEnterSingleplayerCallback = L0_1

function L0_1(A0_2, A1_2)
  fExitSingleplayerCallbackFunction = A0_2
  tExitSingleplayerCallbackArguments = A1_2
end

SetExitSingleplayerCallback = L0_1

function L0_1(A0_2, A1_2)
  fEnterMultiplayerCallbackFunction = A0_2
  tEnterMultiplayerCallbackArguments = A1_2
end

SetEnterMultiplayerCallback = L0_1

function L0_1(A0_2, A1_2)
  fExitMultiplayerCallbackFunction = A0_2
  tExitMultiplayerCallbackArguments = A1_2
end

SetExitMultiplayerCallback = L0_1
L0_1 = nil
fEnterSingleplayerCallbackFunction = L0_1
L0_1 = {}
tEnterSingleplayerCallbackArguments = L0_1
L0_1 = nil
fExitSingleplayerCallbackFunction = L0_1
L0_1 = {}
tExitSingleplayerCallbackArguments = L0_1
L0_1 = nil
fEnterMultiplayerCallbackFunction = L0_1
L0_1 = {}
tEnterMultiplayerCallbackArguments = L0_1
L0_1 = nil
fExitMultiplayerCallbackFunction = L0_1
L0_1 = {}
tExitMultiplayerCallbackArguments = L0_1
