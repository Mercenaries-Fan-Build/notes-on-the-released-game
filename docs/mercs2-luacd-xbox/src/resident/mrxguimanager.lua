local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil_Shell"
L0_1(L1_1)

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L1_2 = _AllRequiredModulesLoaded
  L1_2 = L1_2()
  if not L1_2 then
    L1_2 = table
    L1_2 = L1_2.insert
    L2_2 = _tPendingList
    L3_2 = A0_2
    L1_2(L2_2, L3_2)
    L1_2 = _bLoadingNow
    if not L1_2 then
      L1_2 = MrxGui
      L1_2 = L1_2.LoadGuiFile
      L2_2 = "MrxGuiHudLayout2"
      L3_2 = HudLoaded
      L4_2 = A0_2
      L1_2(L2_2, L3_2, L4_2)
      L1_2 = MrxGui
      L1_2 = L1_2.LoadGuiFile
      L2_2 = "MrxGuiBinocularsLayout"
      L3_2 = ScopeLoaded
      L4_2 = A0_2
      L1_2(L2_2, L3_2, L4_2)
      L1_2 = MrxGui
      L1_2 = L1_2.LoadGuiFile
      L2_2 = "MrxGuiSatelliteLayout"
      L3_2 = SatelliteLoaded
      L4_2 = A0_2
      L1_2(L2_2, L3_2, L4_2)
      L1_2 = MrxGui
      L1_2 = L1_2.LoadGuiFile
      L2_2 = "MrxGuiPdaLayout"
      L3_2 = PdaLoaded
      L4_2 = A0_2
      L1_2(L2_2, L3_2, L4_2)
      L1_2 = true
      _bLoadingNow = L1_2
    end
    return
  end
  L1_2 = _tPlayerGuiList
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    L1_2 = nil
    L2_2 = nil
    L3_2 = nil
    L4_2 = nil
    L5_2 = _bFirstGuiInQueue
    if L5_2 then
      L5_2 = {}
      L1_2 = L5_2
      L5_2 = {}
      L2_2 = L5_2
      L5_2 = {}
      L3_2 = L5_2
      L5_2 = {}
      L4_2 = L5_2
      L5_2 = _oMasterHud
      L5_2 = L5_2.AddedWidgetList
      L1_2.AddedWidgetList = L5_2
      L5_2 = _oMasterScope
      L5_2 = L5_2.AddedWidgetList
      L2_2.AddedWidgetList = L5_2
      L5_2 = _oMasterSatellite
      L5_2 = L5_2.AddedWidgetList
      L3_2.AddedWidgetList = L5_2
      L5_2 = _oMasterPda
      L5_2 = L5_2.AddedWidgetList
      L4_2.AddedWidgetList = L5_2
      L5_2 = _oMasterHud
      L5_2.AddedWidgetList = nil
      L5_2 = _oMasterScope
      L5_2.AddedWidgetList = nil
      L5_2 = _oMasterSatellite
      L5_2.AddedWidgetList = nil
      L5_2 = _oMasterPda
      L5_2.AddedWidgetList = nil
      L5_2 = false
      _bFirstGuiInQueue = L5_2
    else
      L5_2 = MrxGui
      L5_2 = L5_2.DuplicateLayout
      L6_2 = _oMasterHud
      L5_2 = L5_2(L6_2)
      L1_2 = L5_2
      L5_2 = MrxGui
      L5_2 = L5_2.DuplicateLayout
      L6_2 = _oMasterScope
      L5_2 = L5_2(L6_2)
      L2_2 = L5_2
      L5_2 = MrxGui
      L5_2 = L5_2.DuplicateLayout
      L6_2 = _oMasterSatellite
      L5_2 = L5_2(L6_2)
      L3_2 = L5_2
      L5_2 = MrxGui
      L5_2 = L5_2.DuplicateLayout
      L6_2 = _oMasterPda
      L5_2 = L5_2(L6_2)
      L4_2 = L5_2
    end
    L5_2 = MrxGui
    L5_2 = L5_2.AssignLayoutToPlayer
    L6_2 = L1_2
    L7_2 = A0_2
    L5_2(L6_2, L7_2)
    L5_2 = MrxGui
    L5_2 = L5_2.AssignLayoutToPlayer
    L6_2 = L2_2
    L7_2 = A0_2
    L5_2(L6_2, L7_2)
    L5_2 = MrxGui
    L5_2 = L5_2.AssignLayoutToPlayer
    L6_2 = L3_2
    L7_2 = A0_2
    L5_2(L6_2, L7_2)
    L5_2 = MrxGui
    L5_2 = L5_2.AssignLayoutToPlayer
    L6_2 = L4_2
    L7_2 = A0_2
    L5_2(L6_2, L7_2)
    L5_2 = MrxGui
    L5_2 = L5_2.PushAllTextToFront
    L6_2 = L1_2
    L5_2(L6_2)
    L5_2 = {}
    L5_2.oHud = L1_2
    L5_2.oScope = L2_2
    L5_2.oSatellite = L3_2
    L5_2.oPda = L4_2
    L5_2.nHudState = 0
    L6_2 = _tPlayerGuiList
    L6_2[A0_2] = L5_2
    L6_2 = _tHudStates
    L6_2[A0_2] = true
    L6_2 = _tPendingHudWidgets
    L6_2 = L6_2[A0_2]
    if L6_2 then
      L6_2 = pairs
      L7_2 = _tPendingHudWidgets
      L7_2 = L7_2[A0_2]
      L6_2, L7_2, L8_2 = L6_2(L7_2)
      for L9_2, L10_2 in L6_2, L7_2, L8_2 do
        L11_2 = AddWidgetToHud
        L12_2 = A0_2
        L13_2 = L9_2
        L14_2 = L10_2
        L11_2(L12_2, L13_2, L14_2)
      end
      L6_2 = _tPendingHudWidgets
      L6_2[A0_2] = nil
    end
    L6_2 = Player
    L6_2 = L6_2.GetLocalPlayer
    L6_2 = L6_2()
    if L6_2 == A0_2 then
      L6_2 = _G
      L7_2 = MrxGui
      L7_2 = L7_2.GetWidgetByName
      L8_2 = "MessageBox"
      L7_2 = L7_2(L8_2)
      L6_2.MessageBox = L7_2
      L6_2 = _G
      L7_2 = MrxGui
      L7_2 = L7_2.GetWidgetByName
      L8_2 = "Minimap"
      L7_2 = L7_2(L8_2)
      L6_2.Minimap = L7_2
      L6_2 = _G
      L7_2 = MrxGui
      L7_2 = L7_2.GetWidgetByName
      L8_2 = "Objective Tray"
      L7_2 = L7_2(L8_2)
      L6_2.ObjectiveTray = L7_2
      L6_2 = _G
      L7_2 = MrxGui
      L7_2 = L7_2.GetWidgetByName
      L8_2 = "Subtitle Buffer"
      L7_2 = L7_2(L8_2)
      L6_2.SubtitleBuffer = L7_2
      L6_2 = _G
      L7_2 = MrxGui
      L7_2 = L7_2.GetWidgetByName
      L8_2 = "Map Label"
      L7_2 = L7_2(L8_2)
      L6_2.MapLabel = L7_2
    end
  end
  L1_2 = Sys
  L1_2 = L1_2.NoHud
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = ToggleHud
    L2_2 = A0_2
    L3_2 = false
    L1_2(L2_2, L3_2)
  end
  L1_2 = MrxGui
  L1_2 = L1_2.IsE3HudModeActive
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = {}
    L1_2.EventType = "E3HudMode"
    L2_2 = MrxGui
    L2_2 = L2_2.IsE3HudModeActive
    L2_2 = L2_2()
    L1_2.bOn = L2_2
    L2_2 = MrxGui
    L2_2 = L2_2.SendEvent
    L3_2 = L1_2
    L2_2(L3_2)
  end
  L1_2 = _fLoadingDone
  if L1_2 then
    L1_2 = MrxUtil_Shell
    L1_2 = L1_2.CallWithOptionalArgs
    L2_2 = _fLoadingDone
    L3_2 = _tLoadingDoneData
    L1_2(L2_2, L3_2)
    L1_2 = nil
    _fLoadingDone = L1_2
    L1_2 = nil
    _tLoadingDoneData = L1_2
  end
end

CreateGui = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  L3_2 = type
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if "userdata" ~= L3_2 then
    return
  end
  L3_2 = _tPlayerGuiList
  L3_2 = L3_2[A0_2]
  if L3_2 then
    L3_2 = _tPlayerGuiList
    L3_2 = L3_2[A0_2]
    L3_2 = L3_2.oHud
    if L3_2 then
      if A1_2 then
        L3_2 = _tPlayerGuiList
        L3_2 = L3_2[A0_2]
        L4_2 = _tPlayerGuiList
        L4_2 = L4_2[A0_2]
        L4_2 = L4_2.nHudState
        L4_2 = L4_2 - 1
        L3_2.nHudState = L4_2
      else
        L3_2 = _tPlayerGuiList
        L3_2 = L3_2[A0_2]
        L4_2 = _tPlayerGuiList
        L4_2 = L4_2[A0_2]
        L4_2 = L4_2.nHudState
        L4_2 = L4_2 + 1
        L3_2.nHudState = L4_2
      end
      if A1_2 then
        L3_2 = _tPlayerGuiList
        L3_2 = L3_2[A0_2]
        L3_2 = L3_2.nHudState
        if L3_2 <= 0 then
          L3_2 = _tPlayerGuiList
          L3_2 = L3_2[A0_2]
          L3_2.nHudState = 0
          L3_2 = MrxGui
          L3_2 = L3_2.SetAllWidgetsSleep
          L4_2 = _tPlayerGuiList
          L4_2 = L4_2[A0_2]
          L4_2 = L4_2.oHud
          L5_2 = false
          L3_2(L4_2, L5_2)
          L3_2 = _tHudStates
          L3_2[A0_2] = true
        end
      else
        L3_2 = MrxGui
        L3_2 = L3_2.SetAllWidgetsSleep
        L4_2 = _tPlayerGuiList
        L4_2 = L4_2[A0_2]
        L4_2 = L4_2.oHud
        L5_2 = true
        L3_2(L4_2, L5_2)
        L3_2 = _tHudStates
        L3_2[A0_2] = false
        L3_2 = type
        L4_2 = A2_2
        L3_2 = L3_2(L4_2)
        if "string" == L3_2 then
          if "briefing" == A2_2 then
            L3_2 = _DetoggleWidgetRecursive
            L4_2 = "MessageBox"
            L5_2 = A0_2
            L3_2(L4_2, L5_2)
            L3_2 = _DetoggleWidgetRecursive
            L4_2 = "Subtitle Buffer"
            L5_2 = A0_2
            L3_2(L4_2, L5_2)
            L3_2 = _DetoggleWidget
            L4_2 = "Context Action Text"
            L5_2 = A0_2
            L3_2(L4_2, L5_2)
            L3_2 = _DetoggleWidget
            L4_2 = "Faction Display"
            L5_2 = A0_2
            L3_2(L4_2, L5_2)
            L3_2 = _DetoggleWidgetRecursive
            L4_2 = "Resource Counters"
            L5_2 = A0_2
            L3_2(L4_2, L5_2)
          elseif "hijack" == A2_2 then
            L3_2 = _DetoggleWidgetRecursive
            L4_2 = "MessageBox"
            L5_2 = A0_2
            L3_2(L4_2, L5_2)
            L3_2 = _DetoggleWidget
            L4_2 = "Action Hijack"
            L5_2 = A0_2
            L3_2(L4_2, L5_2)
            L3_2 = _DetoggleWidget
            L4_2 = "Subtitle Buffer"
            L5_2 = A0_2
            L3_2(L4_2, L5_2)
          elseif "satellite" == A2_2 then
            L3_2 = _DetoggleWidgetRecursive
            L4_2 = "MessageBox"
            L5_2 = A0_2
            L3_2(L4_2, L5_2)
            L3_2 = _DetoggleWidgetRecursive
            L4_2 = "Subtitle Buffer"
            L5_2 = A0_2
            L3_2(L4_2, L5_2)
            L3_2 = _DetoggleWidgetRecursive
            L4_2 = "tutorial"
            L5_2 = A0_2
            L3_2(L4_2, L5_2)
          elseif "scope" == A2_2 then
            L3_2 = _DetoggleWidgetRecursive
            L4_2 = "MessageBox"
            L5_2 = A0_2
            L3_2(L4_2, L5_2)
            L3_2 = _DetoggleWidgetRecursive
            L4_2 = "Subtitle Buffer"
            L5_2 = A0_2
            L3_2(L4_2, L5_2)
          end
        end
      end
    end
  end
end

ToggleHud = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = MrxGui
  L2_2 = L2_2.GetWidgetByNameAndOwner
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    L4_2 = L2_2
    L3_2 = L2_2.SetSleeping
    L5_2 = false
    L3_2(L4_2, L5_2)
  end
end

_DetoggleWidget = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = MrxGui
  L2_2 = L2_2.GetWidgetByNameAndOwner
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    L3_2 = _RecursiveWakeup
    L4_2 = L2_2
    L3_2(L4_2)
  end
end

_DetoggleWidgetRecursive = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L3_2 = A0_2
  L2_2 = A0_2.SetSleeping
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = _RecursiveWakeup
    L8_2 = L6_2
    L7_2(L8_2)
  end
end

_RecursiveWakeup = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = _tHudStates
  L1_2 = L1_2[A0_2]
  return L1_2
end

GetHudState = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  if A0_2 then
    L3_2 = _tPlayerGuiList
    L3_2 = L3_2[A0_2]
    if L3_2 then
      L3_2 = _tPlayerGuiList
      L3_2 = L3_2[A0_2]
      L3_2 = L3_2.oHud
      if L3_2 then
        L3_2 = _tPlayerGuiList
        L3_2 = L3_2[A0_2]
        L3_2 = L3_2.oHud
        L4_2 = table
        L4_2 = L4_2.insert
        L5_2 = L3_2.AddedWidgetList
        L6_2 = A1_2
        L4_2(L5_2, L6_2)
        if A2_2 then
          L5_2 = A1_2
          L4_2 = A1_2.GetChildren
          L4_2 = L4_2(L5_2)
          L5_2 = ipairs
          L6_2 = L4_2
          L5_2, L6_2, L7_2 = L5_2(L6_2)
          for L8_2, L9_2 in L5_2, L6_2, L7_2 do
            L10_2 = AddWidgetToHud
            L11_2 = A0_2
            L12_2 = L9_2
            L13_2 = true
            L10_2(L11_2, L12_2, L13_2)
          end
        end
    end
  end
  elseif A0_2 then
    L3_2 = _tPendingHudWidgets
    L3_2 = L3_2[A0_2]
    if not L3_2 then
      L3_2 = _tPendingHudWidgets
      L4_2 = {}
      L3_2[A0_2] = L4_2
    end
    L3_2 = _tPendingHudWidgets
    L3_2 = L3_2[A0_2]
    L4_2 = A2_2 or L4_2
    if not A2_2 then
      L4_2 = false
    end
    L3_2[A1_2] = L4_2
  end
end

AddWidgetToHud = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  if A0_2 then
    L3_2 = _tPlayerGuiList
    L3_2 = L3_2[A0_2]
    if L3_2 then
      L3_2 = _tPlayerGuiList
      L3_2 = L3_2[A0_2]
      L3_2 = L3_2.oHud
      if L3_2 then
        L3_2 = _tPlayerGuiList
        L3_2 = L3_2[A0_2]
        L3_2 = L3_2.oHud
        L3_2 = L3_2.AddedWidgetList
        L4_2 = nil
        L5_2 = 1
        while true do
          L6_2 = L3_2[L5_2]
          if not L6_2 or L4_2 then
            break
          end
          L6_2 = L3_2[L5_2]
          if L6_2 == A1_2 then
            L4_2 = L5_2
          end
          L5_2 = L5_2 + 1
        end
        if L4_2 then
          L6_2 = table
          L6_2 = L6_2.remove
          L7_2 = L3_2
          L8_2 = L4_2
          L6_2(L7_2, L8_2)
        end
        if A2_2 then
          L7_2 = A1_2
          L6_2 = A1_2.GetChildren
          L6_2 = L6_2(L7_2)
          L7_2 = ipairs
          L8_2 = L6_2
          L7_2, L8_2, L9_2 = L7_2(L8_2)
          for L10_2, L11_2 in L7_2, L8_2, L9_2 do
            L12_2 = RemoveWidgetFromHud
            L13_2 = A0_2
            L14_2 = L11_2
            L15_2 = true
            L12_2(L13_2, L14_2, L15_2)
          end
        end
    end
  end
  else
    L3_2 = _tPendingHudWidgets
    L3_2 = L3_2[A0_2]
    if L3_2 then
      L3_2 = _tPendingHudWidgets
      L3_2 = L3_2[A0_2]
      L3_2 = L3_2[A1_2]
      if L3_2 then
        L3_2 = _tPendingHudWidgets
        L3_2 = L3_2[A0_2]
        L3_2[A1_2] = nil
      end
    end
  end
end

RemoveWidgetFromHud = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2
  if A1_2 then
    L4_2 = Player
    L4_2 = L4_2.SetPDAMapModeCallback
    L5_2 = A0_2
    L6_2 = false
    L7_2 = ApplySatelliteUpdateEvent
    L4_2(L5_2, L6_2, L7_2)
  else
    L4_2 = Player
    L4_2 = L4_2.SetPDAMapModeCallback
    L5_2 = A0_2
    L6_2 = false
    L7_2 = DoNothing
    L4_2(L5_2, L6_2, L7_2)
  end
  L4_2 = {}
  L4_2.EventType = "SatelliteStateChange"
  L4_2.uPlayerGuid = A0_2
  L4_2.bActivate = A1_2
  L5_2 = "advanced" == A2_2
  L4_2.bAdvanced = L5_2
  L5_2 = not A3_2
  L4_2.bMinigame = L5_2
  L5_2 = MrxGui
  L5_2 = L5_2.SendEvent
  L6_2 = L4_2
  L5_2(L6_2)
  L5_2 = {}
  L5_2.EventType = "SatelliteProgressUpdate"
  L5_2.uPlayerGuid = A0_2
  L5_2.nX = nil
  L5_2.nY = nil
  L5_2.nZ = nil
  L5_2.nPercent = 0
  L4_2 = L5_2
  L5_2 = MrxGui
  L5_2 = L5_2.SendEvent
  L6_2 = L4_2
  L5_2(L6_2)
end

ToggleSatellite = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2
  L5_2 = {}
  L5_2.EventType = "SatelliteProgressUpdate"
  L5_2.uPlayerGuid = A0_2
  L5_2.nX = A1_2
  L5_2.nY = A2_2
  L5_2.nZ = A3_2
  L5_2.nPercent = A4_2
  L6_2 = MrxGui
  L6_2 = L6_2.SendEvent
  L7_2 = L5_2
  L6_2(L7_2)
end

ApplySatelliteUpdateEvent = L0_1

function L0_1()
  local L0_2, L1_2
end

DoNothing = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = MrxGui
  L3_2 = L3_2.GetWidgetByNameAndOwner
  L4_2 = "Satellite overlay"
  L5_2 = A0_2
  L3_2 = L3_2(L4_2, L5_2)
  if L3_2 then
    L5_2 = L3_2
    L4_2 = L3_2.SetMinigameCallback
    L6_2 = A1_2
    L7_2 = A2_2
    L4_2(L5_2, L6_2, L7_2)
  else
  end
end

SetSatelliteSuccessCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = MrxGui
  L2_2 = L2_2.GetWidgetByNameAndOwner
  L3_2 = "Satellite overlay"
  L4_2 = A0_2
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    L3_2 = L2_2.SetMinigameSectors
    if L3_2 then
      L4_2 = L2_2
      L3_2 = L2_2.SetMinigameSectors
      L5_2 = A1_2
      L3_2(L4_2, L5_2)
    end
  end
end

SetSatelliteMinigameData = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = MrxGui
  L2_2 = L2_2.GetWidgetByNameAndOwner
  L3_2 = "Satellite overlay"
  L4_2 = A0_2
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    L3_2 = L2_2.SetMinigameCost
    if L3_2 then
      L4_2 = L2_2
      L3_2 = L2_2.SetMinigameCost
      L5_2 = A1_2
      L3_2(L4_2, L5_2)
    end
  end
end

SetSatelliteCost = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "userdata" == L1_2 then
    L1_2 = _tPlayerGuiList
    L1_2 = L1_2[A0_2]
    if L1_2 then
      L1_2 = _RemoveAndDeleteWidgets
      L2_2 = _tPlayerGuiList
      L2_2 = L2_2[A0_2]
      L2_2 = L2_2.oHud
      L1_2(L2_2)
      L1_2 = _RemoveAndDeleteWidgets
      L2_2 = _tPlayerGuiList
      L2_2 = L2_2[A0_2]
      L2_2 = L2_2.oScope
      L1_2(L2_2)
      L1_2 = _RemoveAndDeleteWidgets
      L2_2 = _tPlayerGuiList
      L2_2 = L2_2[A0_2]
      L2_2 = L2_2.oSatellite
      L1_2(L2_2)
      L1_2 = _RemoveAndDeleteWidgets
      L2_2 = _tPlayerGuiList
      L2_2 = L2_2[A0_2]
      L2_2 = L2_2.oPda
      L1_2(L2_2)
      L1_2 = _tPlayerGuiList
      L1_2[A0_2] = nil
      L1_2 = _tHudStates
      L1_2[A0_2] = nil
      L1_2 = MrxGui
      L1_2 = L1_2.DeleteTransientWidgets
      L2_2 = A0_2
      L1_2(L2_2)
    end
  end
end

DeleteGui = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = pairs
  L1_2 = _tPlayerGuiList
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2 in L0_2, L1_2, L2_2 do
    L4_2 = DeleteGui
    L5_2 = L3_2
    L4_2(L5_2)
  end
end

DeleteAllGuis = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = 0
  L3_2 = pairs
  L4_2 = _tPlayerGuiList
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L2_2 = L2_2 + 1
  end
  if 0 < L2_2 then
    L3_2 = MrxUtil_Shell
    L3_2 = L3_2.CallWithOptionalArgs
    L4_2 = A0_2
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
  else
    _fLoadingDone = A0_2
    _tLoadingDoneData = A1_2
  end
end

SetLoadingCompleteCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = _SetupMasterLayouts
  L2_2 = A0_2
  L3_2 = nil
  L4_2 = nil
  L5_2 = nil
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

HudLoaded = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = _SetupMasterLayouts
  L2_2 = nil
  L3_2 = nil
  L4_2 = A0_2
  L5_2 = nil
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

ScopeLoaded = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = _SetupMasterLayouts
  L2_2 = nil
  L3_2 = A0_2
  L4_2 = nil
  L5_2 = nil
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

SatelliteLoaded = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = _SetupMasterLayouts
  L2_2 = nil
  L3_2 = nil
  L4_2 = nil
  L5_2 = A0_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

PdaLoaded = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  if A0_2 then
    _oMasterHud = A0_2
  end
  if A1_2 then
    _oMasterSatellite = A1_2
  end
  if A2_2 then
    _oMasterScope = A2_2
  end
  if A3_2 then
    _oMasterPda = A3_2
  end
  L4_2 = _AllRequiredModulesLoaded
  L4_2 = L4_2()
  if L4_2 then
    L4_2 = pairs
    L5_2 = _tPendingList
    L4_2, L5_2, L6_2 = L4_2(L5_2)
    for L7_2, L8_2 in L4_2, L5_2, L6_2 do
      L9_2 = CreateGui
      L10_2 = L8_2
      L9_2(L10_2)
    end
    L4_2 = {}
    _tPendingList = L4_2
    L4_2 = false
    _bLoadingNow = L4_2
    L4_2 = true
    _bFirstGuiInQueue = L4_2
    L4_2 = MrxGui
    L4_2 = L4_2.UnloadGuiFile
    L5_2 = _oMasterHud
    L5_2 = L5_2[1]
    L4_2(L5_2)
    L4_2 = MrxGui
    L4_2 = L4_2.UnloadGuiFile
    L5_2 = _oMasterSatellite
    L5_2 = L5_2[1]
    L4_2(L5_2)
    L4_2 = MrxGui
    L4_2 = L4_2.UnloadGuiFile
    L5_2 = _oMasterScope
    L5_2 = L5_2[1]
    L4_2(L5_2)
    L4_2 = MrxGui
    L4_2 = L4_2.UnloadGuiFile
    L5_2 = _oMasterPda
    L5_2 = L5_2[1]
    L4_2(L5_2)
    L4_2 = false
    _oMasterHud = L4_2
    L4_2 = false
    _oMasterSatellite = L4_2
    L4_2 = false
    _oMasterScope = L4_2
    L4_2 = false
    _oMasterPda = L4_2
  end
end

_SetupMasterLayouts = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _oMasterHud
  if L0_2 then
    L0_2 = _oMasterSatellite
    if L0_2 then
      L0_2 = _oMasterScope
      if L0_2 then
        L0_2 = _oMasterPda
      end
    end
  end
  return L0_2
end

_AllRequiredModulesLoaded = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxGui
  L1_2 = L1_2.RemoveAllWidgetsInLayout
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = pairs
  L2_2 = A0_2.AddedWidgetList
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L7_2 = L5_2
    L6_2 = L5_2.delete
    L6_2(L7_2)
  end
end

_RemoveAndDeleteWidgets = L0_1
L0_1 = false
_tPlayerGuiList = L0_1
L0_1 = false
_oMasterHud = L0_1
L0_1 = false
_oMasterSatellite = L0_1
L0_1 = false
_oMasterScope = L0_1
L0_1 = false
_oMasterPda = L0_1
L0_1 = false
_tPendingList = L0_1
L0_1 = false
_fLoadingDone = L0_1
L0_1 = false
_tLoadingDoneData = L0_1
L0_1 = false
_tHudStates = L0_1
L0_1 = false
_tPendingHudWidgets = L0_1
L0_1 = false
_bLoadingNow = L0_1
L0_1 = true
_bFirstGuiInQueue = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = {}
  _tPlayerGuiList = L0_2
  L0_2 = {}
  _tPendingList = L0_2
  L0_2 = {}
  _tHudStates = L0_2
  L0_2 = {}
  _tPendingHudWidgets = L0_2
end

Init = L0_1
