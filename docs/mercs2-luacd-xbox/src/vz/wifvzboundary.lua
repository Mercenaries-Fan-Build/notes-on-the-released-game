local L0_1, L1_1
L0_1 = import
L1_1 = "MrxCheatBootstrap"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = false
_bMapBoundariesDrawn = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = SetupBoundary
  L1_2 = "BoundaryIntro"
  L2_2 = false
  L0_2(L1_2, L2_2)
end

SetupBoundaryIntro = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = SetupBoundary
  L1_2 = "Boundary00"
  L2_2 = false
  L0_2(L1_2, L2_2)
end

SetupBoundary00 = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = SetupBoundary
  L1_2 = "INTRO_OIL"
  L2_2 = false
  L0_2(L1_2, L2_2)
end

SetupBoundaryINTRO_OIL = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = SetupBoundary
  L1_2 = "POST_OIL"
  L2_2 = false
  L0_2(L1_2, L2_2)
end

SetupBoundaryPOST_OIL = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = _sBoundaryName
  if L0_2 ~= "Boundary02" then
    L0_2 = SetupBoundary
    L1_2 = "POST_EVA_PRE_PIR"
    L2_2 = false
    L0_2(L1_2, L2_2)
  end
end

SetupBoundaryPOST_EVA_PRE_PIR = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = _sBoundaryName
  if L0_2 ~= "Boundary02" then
    L0_2 = SetupBoundary
    L1_2 = "POST_EVA_POST_PIR"
    L2_2 = false
    L0_2(L1_2, L2_2)
  end
end

SetupBoundaryPOST_EVA_POST_PIR = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = _sBoundaryName
  if L0_2 ~= "Boundary02" then
    L0_2 = SetupBoundary
    L1_2 = "BoundaryPMCCON003"
    L2_2 = false
    L0_2(L1_2, L2_2)
  end
end

SetupBoundaryPMCCON003 = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = SetupBoundary
  L1_2 = "Boundary02"
  L2_2 = true
  L0_2(L1_2, L2_2)
end

SetupBoundary02 = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = Net
  L2_2 = L2_2.IsClient
  L2_2 = L2_2()
  if L2_2 then
    return
  end
  L2_2 = RemoveWorldBoundary
  L2_2()
  _sBoundaryName = A0_2
  L2_2 = _AddBoundaryToPlayers
  L3_2 = true
  L2_2(L3_2)
  L2_2 = _DrawWorldBoundaryOnMap
  L3_2 = true
  L2_2(L3_2)
  if A1_2 then
    L2_2 = MrxCheatBootstrap
    L2_2 = L2_2.IsSkipModeEnabled
    L2_2 = L2_2()
    A1_2 = not L2_2
  end
  if A1_2 then
    L2_2 = Hud
    L2_2 = L2_2.MessageBox
    L3_2 = L2_2
    L2_2 = L2_2.AddMessage
    L4_2 = {}
    L4_2.sMessage = "[Fanfare.BoundaryExpanded]"
    L4_2.bAllowsAppends = false
    L4_2.nDuration = 3
    L4_2.nFadeTime = 0.25
    L2_2(L3_2, L4_2)
  end
end

SetupBoundary = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  if A1_2 == "out" and A2_2 == "enter" then
    L3_2 = bVoDelay
    if not L3_2 then
      L3_2 = MrxVoSequence
      L3_2 = L3_2.Start
      L4_2 = {}
      L5_2 = "Fiona-None-Freeplay-None-01"
      L4_2[1] = L5_2
      L3_2(L4_2)
      L3_2 = true
      bVoDelay = L3_2
      L3_2 = Event
      L3_2 = L3_2.Create
      L4_2 = Event
      L4_2 = L4_2.TimerRelative
      L5_2 = {}
      L6_2 = 10
      L5_2[1] = L6_2
      
      function L6_2()
        local L0_3, L1_3
        bVoDelay = L0_3
      end
      
      L7_2 = {}
      L3_2(L4_2, L5_2, L6_2, L7_2)
    end
  end
  if A1_2 == "out" and A2_2 == "exit" then
    L3_2 = math
    L3_2 = L3_2.randi
    L4_2 = 0
    L5_2 = 3
    L3_2 = L3_2(L4_2, L5_2)
    L3_2 = 5 + L3_2
    nVoIndex = L3_2
    L3_2 = nVoIndex
    if L3_2 == 6 then
      L3_2 = math
      L3_2 = L3_2.randi
      L4_2 = 1
      L5_2 = 2
      L3_2 = L3_2(L4_2, L5_2)
      L3_2 = 6 + L3_2
      nVoIndex = L3_2
    end
    L3_2 = MrxVoSequence
    L3_2 = L3_2.Start
    L4_2 = {}
    L5_2 = "Fiona.fio_g0"
    L6_2 = nVoIndex
    L5_2 = L5_2 .. L6_2
    L4_2[1] = L5_2
    L3_2(L4_2)
    L3_2 = Event
    L3_2 = L3_2.Create
    L4_2 = Event
    L4_2 = L4_2.TimerRelative
    L5_2 = {}
    L6_2 = 10
    L5_2[1] = L6_2
    
    function L6_2()
      local L0_3, L1_3
      bVoDelay = L0_3
    end
    
    L7_2 = {}
    L3_2(L4_2, L5_2, L6_2, L7_2)
  end
  if A1_2 == "out" then
    if A2_2 == "enter" then
      L3_2 = Sound
      L3_2 = L3_2.CueSound
      L4_2 = 0
      L5_2 = "ui_static"
      L3_2(L4_2, L5_2)
    else
      L3_2 = Sound
      L3_2 = L3_2.StopSound
      L4_2 = 0
      L5_2 = "ui_static"
      L3_2(L4_2, L5_2)
    end
  end
end

BoundaryCallback = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = Net
  L0_2 = L0_2.IsClient
  L0_2 = L0_2()
  if L0_2 then
    return
  end
  L0_2 = _sBoundaryName
  if L0_2 then
    L0_2 = _AddBoundaryToPlayers
    L1_2 = false
    L0_2(L1_2)
    L0_2 = _DrawWorldBoundaryOnMap
    L1_2 = false
    L0_2(L1_2)
    L0_2 = nil
    _sBoundaryName = L0_2
  end
end

RemoveWorldBoundary = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = Net
  L2_2 = L2_2.IsClient
  L2_2 = L2_2()
  if L2_2 then
    return
  end
  L2_2 = _tExclusionBoundaries
  if not L2_2 then
    L2_2 = {}
  end
  _tExclusionBoundaries = L2_2
  if A1_2 then
    L2_2 = _tExclusionBoundaries
    L2_2[A0_2] = true
  else
    L2_2 = _tExclusionBoundaries
    L2_2[A0_2] = false
  end
  L2_2 = Player
  L2_2 = L2_2.GetAllPlayers
  L2_2 = L2_2()
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  L4_2 = ipairs
  L5_2 = L2_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    if A1_2 then
      L9_2 = Player
      L9_2 = L9_2.AddBoundary
      L10_2 = L8_2
      L11_2 = L3_2
      L9_2(L10_2, L11_2)
    else
      L9_2 = Player
      L9_2 = L9_2.RemoveBoundary
      L10_2 = L8_2
      L11_2 = L3_2
      L9_2(L10_2, L11_2)
    end
  end
end

EnableExclusionBoundary = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = Net
  L0_2 = L0_2.IsClient
  L0_2 = L0_2()
  if L0_2 then
    return
  end
  L0_2 = _tExclusionBoundaries
  if not L0_2 then
    return
  end
  L0_2 = pairs
  L1_2 = _tExclusionBoundaries
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = EnableExclusionBoundary
    L6_2 = L3_2
    L7_2 = false
    L5_2(L6_2, L7_2)
  end
  L0_2 = nil
  _tExclusionBoundaries = L0_2
end

RemoveExclusionBoundaries = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Net
  L1_2 = L1_2.IsClient
  L1_2 = L1_2()
  if L1_2 then
    return
  end
  L1_2 = _AddBoundaryToPlayers
  L2_2 = not A0_2
  L1_2(L2_2)
  L1_2 = _tExclusionBoundaries
  if L1_2 then
    L1_2 = pairs
    L2_2 = _tExclusionBoundaries
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    for L4_2 in L1_2, L2_2, L3_2 do
      L5_2 = EnableExclusionBoundary
      L6_2 = L4_2
      L7_2 = not A0_2
      L5_2(L6_2, L7_2)
    end
  end
  if A0_2 then
    L1_2 = Player
    L1_2 = L1_2.GetAllPlayers
    L1_2 = L1_2()
    L2_2 = ipairs
    L3_2 = L1_2
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2, L6_2 in L2_2, L3_2, L4_2 do
      L7_2 = Player
      L7_2 = L7_2.SetOutBoundary
      L8_2 = L6_2
      L9_2 = false
      L7_2(L8_2, L9_2)
    end
  end
end

SetInteriorMode = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Player
  L1_2 = L1_2.GetAllPlayers
  L1_2 = L1_2()
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = _sBoundaryName
  L2_2 = L2_2(L3_2)
  L3_2 = ipairs
  L4_2 = L1_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    if A0_2 then
      L8_2 = Player
      L8_2 = L8_2.AddBoundary
      L9_2 = L7_2
      L10_2 = L2_2
      L8_2(L9_2, L10_2)
      L8_2 = Player
      L8_2 = L8_2.SetBoundaryCallback
      L9_2 = L7_2
      L10_2 = BoundaryCallback
      L8_2(L9_2, L10_2)
    else
      L8_2 = Player
      L8_2 = L8_2.RemoveAllBoundary
      L9_2 = L7_2
      L8_2(L9_2)
    end
  end
end

_AddBoundaryToPlayers = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = _bMapBoundariesDrawn
  if A0_2 == L1_2 then
    return
  end
  L1_2 = _sBoundaryName
  if not L1_2 then
    return
  end
  L1_2 = _DrawBoundaryOnMap
  L2_2 = _sBoundaryName
  L3_2 = A0_2
  L4_2 = true
  L1_2(L2_2, L3_2, L4_2)
  _bMapBoundariesDrawn = A0_2
end

_DrawWorldBoundaryOnMap = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if A1_2 then
    L4_2 = Hud
    L4_2 = L4_2.Radar
    L5_2 = L4_2
    L4_2 = L4_2.AddLineRegion
    L6_2 = {}
    L6_2.uGuid = L3_2
    L6_2.bInvert = A2_2
    L6_2.nRed = 0
    L6_2.nGreen = 0
    L6_2.nBlue = 0
    L6_2.nAlpha = 160
    L4_2(L5_2, L6_2)
    L4_2 = Pda
    L4_2 = L4_2.Map
    L5_2 = L4_2
    L4_2 = L4_2.AddLineRegion
    L6_2 = {}
    L6_2.uGuid = L3_2
    L6_2.bInvert = A2_2
    L6_2.nRed = 0
    L6_2.nGreen = 0
    L6_2.nBlue = 0
    L6_2.nAlpha = 160
    L4_2(L5_2, L6_2)
  else
    L4_2 = Hud
    L4_2 = L4_2.Radar
    L5_2 = L4_2
    L4_2 = L4_2.RemoveLineRegion
    L6_2 = {}
    L6_2.uGuid = L3_2
    L4_2(L5_2, L6_2)
    L4_2 = Pda
    L4_2 = L4_2.Map
    L5_2 = L4_2
    L4_2 = L4_2.RemoveLineRegion
    L6_2 = {}
    L6_2.uGuid = L3_2
    L4_2(L5_2, L6_2)
  end
end

_DrawBoundaryOnMap = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = _DrawBoundaryOnMap
  L3_2 = A0_2
  L4_2 = A1_2
  L5_2 = false
  L2_2(L3_2, L4_2, L5_2)
end

DrawExclusionBoundaryOnMap = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = {}
  L1_2 = _sBoundaryName
  if L1_2 then
    L1_2 = _sBoundaryName
    L0_2.sBoundaryName = L1_2
  end
  L1_2 = _tExclusionBoundaries
  if L1_2 then
    L1_2 = _tExclusionBoundaries
    L0_2.tExclusionBoundaries = L1_2
  end
  return L0_2
end

SaveSingleton = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = RemoveWorldBoundary
  L2_2()
  L2_2 = RemoveExclusionBoundaries
  L2_2()
  if not A0_2 then
    return
  end
  if not A1_2 then
    L2_2 = A0_2.sBoundaryName
    if L2_2 then
      L2_2 = SetupBoundary
      L3_2 = A0_2.sBoundaryName
      L2_2(L3_2)
    end
    L2_2 = A0_2.tExclusionBoundaries
    if L2_2 then
      L2_2 = pairs
      L3_2 = A0_2.tExclusionBoundaries
      L2_2, L3_2, L4_2 = L2_2(L3_2)
      for L5_2, L6_2 in L2_2, L3_2, L4_2 do
        L7_2 = EnableExclusionBoundary
        L8_2 = L5_2
        L9_2 = L6_2
        L7_2(L8_2, L9_2)
        L7_2 = DrawExclusionBoundaryOnMap
        L8_2 = L5_2
        L9_2 = L6_2
        L7_2(L8_2, L9_2)
      end
    end
  else
    L2_2 = A0_2.sBoundaryName
    if L2_2 then
      L2_2 = A0_2.sBoundaryName
      _sBoundaryName = L2_2
      L2_2 = _DrawWorldBoundaryOnMap
      L3_2 = true
      L2_2(L3_2)
    end
    L2_2 = A0_2.tExclusionBoundaries
    if L2_2 then
      L2_2 = A0_2.tExclusionBoundaries
      _tExclusionBoundaries = L2_2
      L2_2 = pairs
      L3_2 = A0_2.tExclusionBoundaries
      L2_2, L3_2, L4_2 = L2_2(L3_2)
      for L5_2, L6_2 in L2_2, L3_2, L4_2 do
        L7_2 = DrawExclusionBoundaryOnMap
        L8_2 = L5_2
        L9_2 = L6_2
        L7_2(L8_2, L9_2)
      end
    end
  end
end

LoadSingleton = L0_1
