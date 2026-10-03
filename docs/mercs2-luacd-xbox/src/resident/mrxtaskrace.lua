local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTask"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiHudMessage"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxStatsManager"
L0_1(L1_1)
L0_1 = 0
NETEVENT_MARKLOC = L0_1
L0_1 = 1
NETEVENT_UNMARKLOC = L0_1
L0_1 = 2
NETEVENT_MARKFINISH = L0_1
L0_1 = 1
kTYPE_GATE = L0_1
L0_1 = 2
kTYPE_RING = L0_1
L0_1 = 200
_knWldBlpNearDist = L0_1
L0_1 = 300
_knWldBlpFarDist = L0_1
L0_1 = {}
tNextLocVals = L0_1
L0_1 = {}
tCurLocVals = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = NETEVENT_MARKLOC
  if A0_2 == L3_2 then
    L2_2 = A1_2[5]
    L3_2 = tCurLocVals
    L4_2 = MarkCurCourseLoc
    L5_2 = A1_2[1]
    L6_2 = A1_2[3]
    L7_2 = A1_2[4]
    L8_2 = false
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
    L3_2[L2_2] = L4_2
    L3_2 = tNextLocVals
    L4_2 = MarkNextCourseLoc
    L5_2 = A1_2[2]
    L6_2 = A1_2[3]
    L7_2 = A1_2[4]
    L4_2 = L4_2(L5_2, L6_2, L7_2)
    L3_2[L2_2] = L4_2
  else
    L3_2 = NETEVENT_UNMARKLOC
    if A0_2 == L3_2 then
      L2_2 = A1_2[1]
      L3_2 = tCurLocVals
      L3_2 = L3_2[L2_2]
      if L3_2 then
        L3_2 = UnmarkCourseLoc
        L4_2 = tCurLocVals
        L4_2 = L4_2[L2_2]
        L3_2(L4_2)
        L3_2 = tCurLocVals
        L3_2[L2_2] = nil
      end
      L3_2 = tNextLocVals
      L3_2 = L3_2[L2_2]
      if L3_2 then
        L3_2 = UnmarkCourseLoc
        L4_2 = tNextLocVals
        L4_2 = L4_2[L2_2]
        L3_2(L4_2)
        L3_2 = tNextLocVals
        L3_2[L2_2] = nil
      end
    else
      L3_2 = NETEVENT_MARKFINISH
      if A0_2 == L3_2 then
        L2_2 = A1_2[4]
        L3_2 = tCurLocVals
        L4_2 = MarkCurCourseLoc
        L5_2 = A1_2[1]
        L6_2 = A1_2[2]
        L7_2 = A1_2[3]
        L8_2 = true
        L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
        L3_2[L2_2] = L4_2
      end
    end
  end
end

NetEventCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = L1_2.fWidth
  L4_2 = 10
  L2_2 = L2_2(L3_2, L4_2)
  A0_2.fWidth = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = L1_2.bUseTripWires
  L4_2 = true
  L2_2 = L2_2(L3_2, L4_2)
  A0_2.bUseTripWires = L2_2
  L2_2 = A0_2.bUseTripWires
  if L2_2 then
    L2_2 = L1_2.sGateType
    if L2_2 == "ring" then
      L2_2 = kTYPE_RING
      A0_2.iGateType = L2_2
    else
      L2_2 = kTYPE_GATE
      A0_2.iGateType = L2_2
    end
  end
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = L1_2.vTgtInclude
  L4_2 = Player
  L4_2 = L4_2.GetAnyCharacter
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L4_2()
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  A0_2.vTgtInclude = L2_2
  L2_2 = L1_2.nAddTime
  A0_2.nAddTime = L2_2
  L2_2 = L1_2.tCourseLocs
  A0_2._tCourseLocs = L2_2
  L2_2 = L1_2.tTimerParams
  if L2_2 then
    L2_2.bTaskManualStart = true
  end
  L3_2 = MrxTask
  L3_2 = L3_2.Activated
  L4_2 = A0_2
  L3_2(L4_2)
  A0_2.iCurLoc = 0
  L3_2 = A0_2.vTgtInclude
  L4_2 = Player
  L4_2 = L4_2.GetAnyCharacter
  L4_2 = L4_2()
  if L3_2 == L4_2 then
    L4_2 = A0_2
    L3_2 = A0_2._StartRace
    L3_2(L4_2)
  else
    L3_2 = type
    L4_2 = A0_2.vTgtInclude
    L3_2 = L3_2(L4_2)
    if L3_2 == "table" then
      L3_2 = pairs
      L4_2 = A0_2.vTgtInclude
      L3_2, L4_2, L5_2 = L3_2(L4_2)
      for L6_2, L7_2 in L3_2, L4_2, L5_2 do
        L8_2 = Object
        L8_2 = L8_2.IsPlayerControlled
        L9_2 = L7_2
        L8_2 = L8_2(L9_2)
        if L8_2 then
          L9_2 = A0_2
          L8_2 = A0_2._StartRace
          L8_2(L9_2)
          return
        end
      end
    else
      L3_2 = Object
      L3_2 = L3_2.IsPlayerControlled
      L4_2 = A0_2.vTgtInclude
      L3_2 = L3_2(L4_2)
      if L3_2 then
        L4_2 = A0_2
        L3_2 = A0_2._StartRace
        L3_2(L4_2)
        return
      end
    end
    L4_2 = A0_2
    L3_2 = A0_2.CreateChild
    L5_2 = {}
    L5_2.sName = "Enter car"
    L5_2.sModuleName = "MrxTaskObjectiveEnterVehicle"
    L6_2 = A0_2.vTgtInclude
    L5_2.vTgtInclude = L6_2
    L5_2.nQuota = 1
    
    function L6_2()
      local L0_3, L1_3
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._StartRace
      L0_3(L1_3)
    end
    
    L5_2.fOnComplete = L6_2
    
    function L6_2()
      local L0_3, L1_3
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3.Cancel
      L0_3(L1_3)
    end
    
    L5_2.fOnCancel = L6_2
    L6_2 = _OnStatusChange
    L5_2.fStatusChangeCallback = L6_2
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L5_2.tStatusChangeCallbackData = L6_2
    L6_2 = L1_2.vVoSeqOnAdd
    L5_2.vVoSeqOnAdd = L6_2
    L3_2(L4_2, L5_2)
    L1_2.vVoSeqOnAdd = nil
  end
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.UnmarkLocation
  L1_2(L2_2)
  A0_2._uTgtObjFilter = nil
  L1_2 = MrxTask
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2._uWinner
  return L1_2
end

GetWinner = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = A0_2
  L1_2 = A0_2.UnmarkLocation
  L1_2(L2_2)
  L1_2 = A0_2.iCurLoc
  L1_2 = L1_2 + 1
  A0_2.iCurLoc = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = A0_2._tCourseLocs
  L3_2 = A0_2.iCurLoc
  L2_2 = L2_2[L3_2]
  L1_2 = L1_2(L2_2)
  L2_2 = nil
  L3_2 = A0_2._tCourseLocs
  L4_2 = A0_2.iCurLoc
  L4_2 = L4_2 + 1
  L3_2 = L3_2[L4_2]
  if L3_2 then
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = A0_2._tCourseLocs
    L5_2 = A0_2.iCurLoc
    L5_2 = L5_2 + 1
    L4_2 = L4_2[L5_2]
    L3_2 = L3_2(L4_2)
    L2_2 = L3_2
  end
  L4_2 = A0_2
  L3_2 = A0_2.GetConfig
  L3_2 = L3_2(L4_2)
  L5_2 = A0_2
  L4_2 = A0_2.CreateChild
  L6_2 = {}
  L7_2 = "Loc"
  L8_2 = A0_2.iCurLoc
  L7_2 = L7_2 .. L8_2
  L6_2.sName = L7_2
  L6_2.sModuleName = "MrxTaskObjectiveDeliver"
  L7_2 = A0_2.vTgtInclude
  L6_2.vTgtInclude = L7_2
  L6_2.nQuota = 1
  L6_2.vDestLoc = L1_2
  L7_2 = _GetDspShortDesc
  L8_2 = A0_2
  L9_2 = A0_2.iCurLoc
  L7_2 = L7_2(L8_2, L9_2)
  L6_2.sDspShortDesc = L7_2
  L7_2 = A0_2.fWidth
  L6_2.fDist = L7_2
  L6_2.bDspMsg = false
  L7_2 = A0_2.bUseTripWires
  L7_2 = not L7_2 or L7_2
  L6_2.bDspBlpWld = L7_2
  L7_2 = _knWldBlpNearDist
  L6_2.nDspBlpWldNearDist = L7_2
  L7_2 = _knWldBlpFarDist
  L6_2.nDspBlpWldFarDist = L7_2
  L6_2.bStop = false
  L6_2.bXZOnly = false
  
  function L7_2(A0_3)
    local L1_3, L2_3
    L1_3 = L2_2
    if not L1_3 then
      L1_3 = Object
      L1_3 = L1_3.IsPlayerControlled
      L2_3 = A0_3
      L1_3 = L1_3(L2_3)
      if L1_3 then
        L1_3 = Vehicle
        L1_3 = L1_3.GetDriver
        L2_3 = A0_3
        L1_3 = L1_3(L2_3)
        _uDriver = L1_3
        L1_3 = _uDriver
        L2_3 = Player
        L2_3 = L2_3.GetPrimaryCharacter
        L2_3 = L2_3()
        if L1_3 == L2_3 then
          L1_3 = A0_2
          L2_3 = Player
          L2_3 = L2_3.GetPrimaryPlayer
          L2_3 = L2_3()
          L1_3._uWinner = L2_3
        else
          L1_3 = _uDriver
          L2_3 = Player
          L2_3 = L2_3.GetSecondaryCharacter
          L2_3 = L2_3()
          if L1_3 == L2_3 then
            L1_3 = A0_2
            L2_3 = Player
            L2_3 = L2_3.GetSecondaryPlayer
            L2_3 = L2_3()
            L1_3._uWinner = L2_3
          end
        end
      end
    end
  end
  
  L6_2.fOnPartComplete = L7_2
  
  function L7_2()
    local L0_3, L1_3, L2_3
    L0_3 = L2_2
    if L0_3 then
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._SetupDestination
      L0_3(L1_3)
      L0_3 = A0_2
      L0_3 = L0_3._oTimer
      if L0_3 then
        L0_3 = A0_2
        L0_3 = L0_3.nAddTime
        if L0_3 then
          L0_3 = A0_2
          L0_3 = L0_3._oTimer
          L1_3 = L0_3
          L0_3 = L0_3.AddTime
          L2_3 = A0_2
          L2_3 = L2_3.nAddTime
          L0_3(L1_3, L2_3)
        end
      end
    else
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._FinishRace
      L0_3(L1_3)
    end
    L0_3 = Sound
    L0_3 = L0_3.CueSound
    L1_3 = 0
    L2_3 = "ui_HUD_Objective_Complete"
    L0_3(L1_3, L2_3)
  end
  
  L6_2.fOnComplete = L7_2
  
  function L7_2()
    local L0_3, L1_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.Cancel
    L0_3(L1_3)
  end
  
  L6_2.fOnCancel = L7_2
  L7_2 = L3_2.vVoSeqOnAdd
  L6_2.vVoSeqOnAdd = L7_2
  L7_2 = _OnStatusChange
  L6_2.fStatusChangeCallback = L7_2
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L6_2.tStatusChangeCallbackData = L7_2
  L4_2(L5_2, L6_2)
  L3_2.vVoSeqOnAdd = nil
  if L2_2 then
    L4_2 = MarkCurCourseLoc
    L5_2 = L1_2
    L6_2 = A0_2.iGateType
    L7_2 = A0_2.fWidth
    L8_2 = false
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
    A0_2.tCurMarker = L4_2
    L4_2 = MarkNextCourseLoc
    L5_2 = L2_2
    L6_2 = A0_2.iGateType
    L7_2 = A0_2.fWidth
    L4_2 = L4_2(L5_2, L6_2, L7_2)
    A0_2.tNextMarker = L4_2
    L4_2 = Net
    L4_2 = L4_2.IsServer
    L4_2 = L4_2()
    if L4_2 then
      L4_2 = Net
      L4_2 = L4_2.SendCustomEvent
      L5_2 = "MrxTaskRace"
      L6_2 = NETEVENT_MARKLOC
      L7_2 = {}
      L8_2 = L1_2
      L9_2 = L2_2
      L10_2 = A0_2.iGateType
      L11_2 = A0_2.fWidth
      L12_2 = A0_2.iCurLoc
      L7_2[1] = L8_2
      L7_2[2] = L9_2
      L7_2[3] = L10_2
      L7_2[4] = L11_2
      L7_2[5] = L12_2
      L4_2(L5_2, L6_2, L7_2)
    end
  else
    L4_2 = MarkCurCourseLoc
    L5_2 = L1_2
    L6_2 = A0_2.iGateType
    L7_2 = A0_2.fWidth
    L8_2 = true
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
    A0_2.tCurMarker = L4_2
    L4_2 = Net
    L4_2 = L4_2.IsServer
    L4_2 = L4_2()
    if L4_2 then
      L4_2 = Net
      L4_2 = L4_2.SendCustomEvent
      L5_2 = "MrxTaskRace"
      L6_2 = NETEVENT_MARKFINISH
      L7_2 = {}
      L8_2 = L1_2
      L9_2 = A0_2.iGateType
      L10_2 = A0_2.fWidth
      L11_2 = A0_2.iCurLoc
      L7_2[1] = L8_2
      L7_2[2] = L9_2
      L7_2[3] = L10_2
      L7_2[4] = L11_2
      L4_2(L5_2, L6_2, L7_2)
    end
  end
end

_SetupDestination = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if L2_2 ~= "number" then
  end
  L2_2 = A1_2 + 1
  L3_2 = A0_2._tCourseLocs
  L3_2 = L3_2[L2_2]
  if L3_2 then
    L3_2 = "[Objective.Race.Checkpoint]"
    L4_2 = " ("
    L5_2 = A1_2 - 1
    L6_2 = "/"
    L7_2 = tostring
    L8_2 = table
    L8_2 = L8_2.getn
    L9_2 = A0_2._tCourseLocs
    L8_2, L9_2 = L8_2(L9_2)
    L7_2 = L7_2(L8_2, L9_2)
    L8_2 = ")"
    L3_2 = L3_2 .. L4_2 .. L5_2 .. L6_2 .. L7_2 .. L8_2
    return L3_2
  else
    L3_2 = "[Objective.Race.Finish]"
    return L3_2
  end
end

_GetDspShortDesc = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = A0_2.tCurMarker
  if L1_2 then
    L1_2 = UnmarkCourseLoc
    L2_2 = A0_2.tCurMarker
    L1_2(L2_2)
    A0_2.tCurMarker = nil
  end
  L1_2 = A0_2.tNextMarker
  if L1_2 then
    L1_2 = UnmarkCourseLoc
    L2_2 = A0_2.tNextMarker
    L1_2(L2_2)
    A0_2.tNextMarker = nil
  end
  L1_2 = Net
  L1_2 = L1_2.IsServer
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = Net
    L1_2 = L1_2.SendCustomEvent
    L2_2 = "MrxTaskRace"
    L3_2 = NETEVENT_UNMARKLOC
    L4_2 = {}
    L5_2 = A0_2.iCurLoc
    L4_2[1] = L5_2
    L1_2(L2_2, L3_2, L4_2)
  end
end

UnmarkLocation = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  if not A1_2 then
    return
  end
  L4_2 = MrxUtil
  L4_2 = L4_2.GetPrimaryObjectiveRgb
  L4_2, L5_2, L6_2 = L4_2()
  L7_2 = kTYPE_GATE
  if A1_2 == L7_2 then
    L7_2 = _DrawTripWire
    L8_2 = A0_2
    L9_2 = A2_2
    L10_2 = L4_2
    L11_2 = L5_2
    L12_2 = L6_2
    L13_2 = A3_2
    L7_2, L8_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
    retFinish = L8_2
    retGate = L7_2
  else
    L7_2 = kTYPE_RING
    if A1_2 == L7_2 then
      L7_2 = _DrawRing
      L8_2 = A0_2
      L9_2 = A2_2
      L10_2 = L4_2
      L11_2 = L5_2
      L12_2 = L6_2
      L13_2 = A3_2
      L7_2, L8_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
      retFinish = L8_2
      retGate = L7_2
    end
  end
  L7_2 = {}
  L8_2 = retGate
  L7_2.uGate = L8_2
  L8_2 = retFinish
  L7_2.uFinish = L8_2
  return L7_2
end

MarkCurCourseLoc = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L6_2 = MrxUtil
  L6_2 = L6_2.GetSecondaryObjectiveRgb
  L6_2, L7_2, L8_2 = L6_2()
  L9_2 = kTYPE_GATE
  if A1_2 == L9_2 then
    L9_2 = _DrawTripWire
    L10_2 = A0_2
    L11_2 = A2_2
    L12_2 = L6_2
    L13_2 = L7_2
    L14_2 = L8_2
    L15_2 = false
    L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
    L3_2 = L9_2
  else
    L9_2 = kTYPE_RING
    if A1_2 == L9_2 then
      L9_2 = _DrawRing
      L10_2 = A0_2
      L11_2 = A2_2
      L12_2 = L6_2
      L13_2 = L7_2
      L14_2 = L8_2
      L15_2 = false
      L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
      L3_2 = L9_2
    end
  end
  L9_2 = Marker
  L9_2 = L9_2.AddBlip
  L10_2 = A0_2
  L11_2 = "HUD_objective_deliverable"
  L12_2 = 32
  L13_2 = L6_2
  L14_2 = L7_2
  L15_2 = L8_2
  L16_2 = 255
  L17_2 = 1
  L18_2 = _knWldBlpNearDist
  L19_2 = _knWldBlpFarDist
  L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
  L4_2 = L9_2
  L5_2 = "NextMarker"
  L9_2 = Hud
  L9_2 = L9_2.Radar
  L10_2 = L9_2
  L9_2 = L9_2.AddObjective
  L11_2 = {}
  L11_2.sName = L5_2
  L11_2.nR = L6_2
  L11_2.nG = L7_2
  L11_2.nB = L8_2
  L11_2.nWidth = 8
  L11_2.nHeight = 8
  L11_2.sTexture = "objective_deliverable"
  L11_2.uGuid = A0_2
  L11_2.bSticky = true
  L11_2.nSortOrder = 5
  L9_2(L10_2, L11_2)
  L9_2 = {}
  L9_2.uGate = L3_2
  L9_2.uWldBlip = L4_2
  L9_2.sMarkerName = L5_2
  return L9_2
end

MarkNextCourseLoc = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = A0_2.uGate
  if L1_2 then
    L1_2 = Marker
    L1_2 = L1_2.Remove
    L2_2 = A0_2.uGate
    L1_2(L2_2)
    L1_2 = A0_2.uFinish
    if L1_2 then
      L1_2 = Marker
      L1_2 = L1_2.Remove
      L2_2 = A0_2.uFinish
      L1_2(L2_2)
    end
  end
  L1_2 = A0_2.uWldBlip
  if L1_2 then
    L1_2 = Marker
    L1_2 = L1_2.Remove
    L2_2 = A0_2.uWldBlip
    L1_2(L2_2)
  end
  L1_2 = A0_2.sMarkerName
  if L1_2 then
    L1_2 = Hud
    L1_2 = L1_2.Radar
    L2_2 = L1_2
    L1_2 = L1_2.RemoveObjective
    L3_2 = {}
    L4_2 = A0_2.sMarkerName
    L3_2.sName = L4_2
    L1_2(L2_2, L3_2)
  end
end

UnmarkCourseLoc = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = type
  L3_2 = L1_2.tTimerParams
  L2_2 = L2_2(L3_2)
  if L2_2 == "table" then
    L2_2 = MrxTimer
    L3_2 = L2_2
    L2_2 = L2_2.Create
    L4_2 = L1_2.tTimerParams
    L2_2 = L2_2(L3_2, L4_2)
    A0_2._oTimer = L2_2
    L2_2 = A0_2._oTimer
    L3_2 = L2_2
    L2_2 = L2_2.Start
    L2_2(L3_2)
    L2_2 = Sys
    L2_2 = L2_2.MainTimeStamp
    L2_2 = L2_2()
    A0_2._uTimeStamp = L2_2
    L2_2 = Sys
    L2_2 = L2_2.TimeStampMark
    L3_2 = A0_2._uTimeStamp
    L2_2(L3_2)
  end
  L3_2 = A0_2
  L2_2 = A0_2._SetupDestination
  L2_2(L3_2)
end

_StartRace = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2.sRaceMission
  if L2_2 then
    L2_2 = Sys
    L2_2 = L2_2.TimeStampGetElapsed
    L3_2 = A0_2._uTimeStamp
    L2_2 = L2_2(L3_2)
    L3_2 = MrxStatsManager
    L3_2 = L3_2.RecordBestTime
    L4_2 = L1_2.sRaceMission
    L5_2 = L2_2
    L3_2(L4_2, L5_2)
  end
  A0_2._uTimeStamp = nil
  L3_2 = A0_2
  L2_2 = A0_2.Complete
  L2_2(L3_2)
end

_FinishRace = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = type
  L4_2 = A0_2.vTgtInclude
  L3_2 = L3_2(L4_2)
  if L3_2 == "table" then
    L3_2 = A0_2.vTgtInclude
    L3_2 = #L3_2
    if 1 < L3_2 then
      L3_2 = pairs
      L4_2 = A0_2.vTgtInclude
      L3_2, L4_2, L5_2 = L3_2(L4_2)
      for L6_2, L7_2 in L3_2, L4_2, L5_2 do
        if L7_2 == A1_2 then
          L8_2 = table
          L8_2 = L8_2.remove
          L9_2 = A0_2.vTgtInclude
          L10_2 = L6_2
          L8_2(L9_2, L10_2)
          break
        end
      end
  end
  else
    L4_2 = A0_2
    L3_2 = A0_2.GetConfig
    L3_2 = L3_2(L4_2)
    L4_2 = L3_2.fVehiclesDestroyedCallback
    if L4_2 then
      L4_2 = type
      L5_2 = L3_2.tVehiclesDestroyedCallbackData
      L4_2 = L4_2(L5_2)
      if L4_2 == "table" then
        L4_2 = L3_2.fVehiclesDestroyedCallback
        L5_2 = unpack
        L6_2 = L3_2.tVehiclesDestroyedCallbackData
        L5_2 = L5_2(L6_2)
        L6_2 = iGuid
        L7_2 = sStatusType
        L4_2(L5_2, L6_2, L7_2)
      else
        L4_2 = L3_2.fVehiclesDestroyedCallback
        L5_2 = iGuid
        L6_2 = sStatusType
        L4_2(L5_2, L6_2)
      end
    end
  end
end

_OnStatusChange = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L6_2 = Object
  L6_2 = L6_2.GetPosition
  L7_2 = A0_2
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  L9_2 = Object
  L9_2 = L9_2.GetYaw
  L10_2 = A0_2
  L9_2 = L9_2(L10_2)
  L10_2 = nil
  L11_2 = nil
  if L6_2 then
    L12_2 = Marker
    L12_2 = L12_2.AddTripwire
    L13_2 = L6_2
    L14_2 = L7_2
    L15_2 = L8_2
    L16_2 = A1_2
    L17_2 = L9_2
    L18_2 = A2_2
    L19_2 = A3_2
    L20_2 = A4_2
    L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
    L10_2 = L12_2
    if A5_2 then
      L12_2 = Marker
      L12_2 = L12_2.Add3D
      L13_2 = A0_2
      L14_2 = "global_tripwirefinish"
      L15_2 = A2_2
      L16_2 = A3_2
      L17_2 = A4_2
      L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2)
      L11_2 = L12_2
    end
  end
  L12_2 = L10_2
  L13_2 = L11_2
  return L12_2, L13_2
end

_DrawTripWire = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L8_2 = Marker
  L8_2 = L8_2.Add3D
  L9_2 = A0_2
  L10_2 = "global_airring"
  L11_2 = A2_2
  L12_2 = A3_2
  L13_2 = A4_2
  L14_2 = A1_2
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L6_2 = L8_2
  if A5_2 then
    L8_2 = Marker
    L8_2 = L8_2.Add3D
    L9_2 = A0_2
    L10_2 = "global_tripwirefinish"
    L11_2 = A2_2
    L12_2 = A3_2
    L13_2 = A4_2
    L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
    L7_2 = L8_2
  end
  L8_2 = L6_2
  L9_2 = L7_2
  return L8_2, L9_2
end

_DrawRing = L0_1
