local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskObjective"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFollow"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = MrxTaskObjective
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = type
  L3_2 = L1_2.vDestLoc
  L2_2 = L2_2(L3_2)
  if L2_2 == "string" then
    L2_2 = Pg
    L2_2 = L2_2.GetGuidByName
    L3_2 = L1_2.vDestLoc
    L2_2 = L2_2(L3_2)
    L1_2.vDestLoc = L2_2
  end
  L2_2 = type
  L3_2 = L1_2.vDestRegion
  L2_2 = L2_2(L3_2)
  if L2_2 == "string" then
    L2_2 = Pg
    L2_2 = L2_2.GetGuidByName
    L3_2 = L1_2.vDestRegion
    L2_2 = L2_2(L3_2)
    L1_2.vDestRegion = L2_2
  end
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = L1_2.fDist
  L4_2 = 5
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.fDist = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = L1_2.bStop
  L4_2 = true
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.bStop = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = L1_2.bDetach
  L4_2 = L1_2.bStop
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.bDetach = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = L1_2.bXZOnly
  L4_2 = false
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.bXZOnly = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = L1_2.bUseDestRing
  L4_2 = L1_2.bStop
  if L4_2 then
    L4_2 = L1_2.vDestLoc
    L4_2 = L4_2 ~= nil
  end
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.bUseDestRing = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = L1_2.bHumansFollow
  L4_2 = true
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.bHumansFollow = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = L1_2.bDisplayHelpText
  L4_2 = true
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.bDisplayHelpText = L2_2
  L2_2 = ObjectFilter
  L2_2 = L2_2.GetCoopPlayerGuid
  L3_2 = A0_2._uTgtObjFilter
  L2_2 = L2_2(L3_2)
  L3_2 = ObjectFilter
  L3_2 = L3_2.GetObjects
  L4_2 = A0_2._uTgtObjFilter
  L5_2 = false
  L3_2 = L3_2(L4_2, L5_2)
  if not L2_2 then
    L2_2 = L3_2[1]
  end
  L4_2 = Player
  L4_2 = L4_2.GetAnyCharacter
  L4_2 = L4_2()
  if L2_2 == L4_2 then
    L4_2 = A0_2._tEvents
    L6_2 = A0_2
    L5_2 = A0_2._PlayerDeliveryCreate
    L7_2 = L2_2
    L5_2 = L5_2(L6_2, L7_2)
    L4_2.uProxEvent = L5_2
    L4_2 = A0_2._tEvents
    L5_2 = Event
    L5_2 = L5_2.CreatePersistent
    L6_2 = Event
    L6_2 = L6_2.ObjectDeath
    L7_2 = {}
    L8_2 = Player
    L8_2 = L8_2.GetAnyCharacter
    L8_2, L9_2, L10_2, L11_2 = L8_2()
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L7_2[4] = L11_2
    
    function L8_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
      L0_3 = false
      L1_3 = Player
      L1_3 = L1_3.GetAllPlayers
      L1_3 = L1_3()
      L2_3 = ipairs
      L3_3 = L1_3
      L2_3, L3_3, L4_3 = L2_3(L3_3)
      for L5_3, L6_3 in L2_3, L3_3, L4_3 do
        L7_3 = Player
        L7_3 = L7_3.GetCharacter
        L8_3 = L6_3
        L7_3 = L7_3(L8_3)
        if L7_3 then
          L8_3 = Object
          L8_3 = L8_3.IsAlive
          L9_3 = L7_3
          L8_3 = L8_3(L9_3)
          if L8_3 then
            L0_3 = true
          end
        end
      end
      if not L0_3 then
        L2_3 = _OnStatusChange
        L3_3 = A0_2
        L4_3 = "destroyed"
        L2_3(L3_3, L4_3)
      end
    end
    
    L5_2 = L5_2(L6_2, L7_2, L8_2)
    L4_2.uDeathEvent = L5_2
  else
    L4_2 = Player
    L4_2 = L4_2.GetAllCharacters
    L4_2 = L4_2()
    if L2_2 == L4_2 then
      L4_2 = A0_2._tEvents
      L6_2 = A0_2
      L5_2 = A0_2._PlayerDeliveryCreate
      L7_2 = L2_2
      L5_2 = L5_2(L6_2, L7_2)
      L4_2.uProxEvent = L5_2
      L4_2 = A0_2._tEvents
      L5_2 = Event
      L5_2 = L5_2.CreatePersistent
      L6_2 = Event
      L6_2 = L6_2.ObjectDeath
      L7_2 = {}
      L8_2 = Player
      L8_2 = L8_2.GetAnyCharacter
      L8_2, L9_2, L10_2, L11_2 = L8_2()
      L7_2[1] = L8_2
      L7_2[2] = L9_2
      L7_2[3] = L10_2
      L7_2[4] = L11_2
      L8_2 = _OnStatusChange
      L9_2 = {}
      L10_2 = A0_2
      L11_2 = "destroyed"
      L9_2[1] = L10_2
      L9_2[2] = L11_2
      L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
      L4_2.uDeathEvent = L5_2
    else
      L4_2 = table
      L4_2 = L4_2.getn
      L5_2 = L3_2
      L4_2 = L4_2(L5_2)
      if L4_2 == 0 then
        L4_2 = A0_2._tEvents
        L6_2 = A0_2
        L5_2 = A0_2.LabelFilterDeliveryCreate
        L7_2 = L1_2
        L5_2 = L5_2(L6_2, L7_2)
        L4_2.uProxEvent = L5_2
      else
        A0_2._iNumAttached = 0
        L4_2 = pairs
        L5_2 = L3_2
        L4_2, L5_2, L6_2 = L4_2(L5_2)
        for L7_2, L8_2 in L4_2, L5_2, L6_2 do
          L9_2 = Object
          L9_2 = L9_2.HasLabel
          L10_2 = L8_2
          L11_2 = "human"
          L9_2 = L9_2(L10_2, L11_2)
          if L9_2 then
            L9_2 = Object
            L9_2 = L9_2.IsPlayerControlled
            L10_2 = L8_2
            L9_2 = L9_2(L10_2)
            if not L9_2 then
              L10_2 = A0_2
              L9_2 = A0_2._HumanDeliveryCreate
              L11_2 = L8_2
              L9_2(L10_2, L11_2)
            end
          else
            L9_2 = Object
            L9_2 = L9_2.HasLabel
            L10_2 = L8_2
            L11_2 = "vehicle"
            L9_2 = L9_2(L10_2, L11_2)
            if L9_2 then
              L10_2 = A0_2
              L9_2 = A0_2._VehicleDeliveryCreate
              L11_2 = L8_2
              L9_2(L10_2, L11_2)
            else
              L10_2 = A0_2
              L9_2 = A0_2._ObjectDeliveryCreate
              L11_2 = L8_2
              L9_2(L10_2, L11_2)
            end
          end
        end
        L4_2 = A0_2._tEvents
        L5_2 = Event
        L5_2 = L5_2.CreatePersistent
        L6_2 = Event
        L6_2 = L6_2.ObjectDeath
        L7_2 = {}
        L8_2 = A0_2._uTgtObjFilter
        L7_2[1] = L8_2
        L8_2 = _OnStatusChange
        L9_2 = {}
        L10_2 = A0_2
        L11_2 = "destroyed"
        L9_2[1] = L10_2
        L9_2[2] = L11_2
        L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
        L4_2.uDeathEvent = L5_2
      end
    end
  end
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = A0_2.uRing
  if L1_2 then
    L1_2 = Marker
    L1_2 = L1_2.Remove
    L2_2 = A0_2.uRing
    L1_2(L2_2)
    L1_2 = Net
    L1_2 = L1_2.IsServer
    L1_2 = L1_2()
    if L1_2 then
      L1_2 = Net
      L1_2 = L1_2.SendEvent_RemoveMarkerObjective
      L2_2 = A0_2.uRing
      L1_2(L2_2)
    end
    A0_2.uRing = nil
  end
  L1_2 = pairs
  L2_2 = A0_2._tTargets
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L7_2 = A0_2
    L6_2 = A0_2._CleanupTargetEvents
    L8_2 = L5_2
    L6_2(L7_2, L8_2)
  end
  L1_2 = MrxTaskObjective
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  if A1_2 == nil then
    return
  end
  L2_2 = A1_2.oFollower
  if L2_2 then
    L2_2 = A1_2.oFollower
    L3_2 = L2_2
    L2_2 = L2_2.Activate
    L4_2 = false
    L2_2(L3_2, L4_2)
    A1_2.oFollower = nil
  end
  L2_2 = type
  L3_2 = A1_2.tEvents
  L2_2 = L2_2(L3_2)
  if L2_2 == "table" then
    L2_2 = pairs
    L3_2 = A1_2.tEvents
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2, L6_2 in L2_2, L3_2, L4_2 do
      L7_2 = Event
      L7_2 = L7_2.Delete
      L8_2 = L6_2
      L7_2(L8_2)
    end
  end
  A1_2.tEvents = nil
end

_CleanupTargetEvents = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = A0_2
  L2_2 = A0_2.GetConfig
  L2_2 = L2_2(L3_2)
  L3_2 = L2_2.fEvaluateTarget
  if L3_2 then
    L3_2 = L2_2.fEvaluateTarget
    L4_2 = A1_2
    L3_2 = L3_2(L4_2)
    if not L3_2 then
      L3_2 = false
      return L3_2
    end
  end
  L3_2 = L2_2.bStop
  if L3_2 then
    L3_2 = L2_2.bDetach
    if L3_2 then
      L3_2 = nil
      L4_2 = Object
      L4_2 = L4_2.HasLabel
      L5_2 = A1_2
      L6_2 = "human"
      L4_2 = L4_2(L5_2, L6_2)
      if L4_2 then
        L5_2 = A0_2
        L4_2 = A0_2._HumanDeliveryCheck
        L6_2 = A1_2
        L7_2 = L2_2.bStop
        L4_2 = L4_2(L5_2, L6_2, L7_2)
        L3_2 = L4_2
      else
        L4_2 = Object
        L4_2 = L4_2.HasLabel
        L5_2 = A1_2
        L6_2 = "vehicle"
        L4_2 = L4_2(L5_2, L6_2)
        if L4_2 then
          L5_2 = A0_2
          L4_2 = A0_2._VehicleDeliveryCheck
          L6_2 = A1_2
          L7_2 = L2_2.bStop
          L4_2 = L4_2(L5_2, L6_2, L7_2)
          L3_2 = L4_2
        else
          L5_2 = A0_2
          L4_2 = A0_2._ObjectDeliveryCheck
          L6_2 = A1_2
          L7_2 = L2_2.bStop
          L4_2 = L4_2(L5_2, L6_2, L7_2)
          L3_2 = L4_2
        end
      end
      if L3_2 then
        L5_2 = A0_2
        L4_2 = A0_2._TargetDelivered
        L6_2 = A1_2
        L4_2(L5_2, L6_2)
        L5_2 = A0_2
        L4_2 = A0_2.GetConfig
        L4_2 = L4_2(L5_2)
        L4_2 = L4_2.bDisplayHelpText
        if L4_2 then
          L4_2 = MrxTutorialManager
          L4_2 = L4_2.HideMessage
          L4_2()
          L4_2 = Net
          L4_2 = L4_2.SendCustomEvent
          L5_2 = "MrxTaskObjectiveDeliver"
          L6_2 = NETEVENT_CLEARTUTORIAL
          L7_2 = {}
          L4_2(L5_2, L6_2, L7_2)
        end
      end
      return L3_2
  end
  else
    L4_2 = A0_2
    L3_2 = A0_2._TargetDelivered
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
    L3_2 = true
    return L3_2
  end
end

_DeliveryCheck = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L3_2 = A0_2
  L2_2 = A0_2._CleanupTargetEvents
  L4_2 = A0_2._tTargets
  L4_2 = L4_2[A1_2]
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2.RemoveTarget
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2.CompletePart
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

_TargetDelivered = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L5_2 = A0_2
  L4_2 = A0_2.GetConfig
  L4_2 = L4_2(L5_2)
  if A3_2 then
    L5_2 = A0_2._iNumAttached
    L5_2 = L5_2 + 1
    A0_2._iNumAttached = L5_2
  else
    L5_2 = A0_2._iNumAttached
    L5_2 = L5_2 - 1
    A0_2._iNumAttached = L5_2
  end
  L5_2 = A0_2._iNumAttached
  if L5_2 == 1 then
    L6_2 = A0_2
    L5_2 = A0_2.EnableDestinationBlip
    L7_2 = true
    L5_2(L6_2, L7_2)
  else
    L5_2 = A0_2._iNumAttached
    if L5_2 == 0 then
      L6_2 = A0_2
      L5_2 = A0_2.EnableDestinationBlip
      L7_2 = false
      L5_2(L6_2, L7_2)
    end
  end
  L6_2 = A0_2
  L5_2 = A0_2._SetTargetStatus
  L7_2 = A2_2
  L8_2 = not A3_2
  L5_2(L6_2, L7_2, L8_2)
  L5_2 = L4_2.fAttachCallback
  if L5_2 then
    L5_2 = type
    L6_2 = L4_2.tAttachCallbackData
    L5_2 = L5_2(L6_2)
    if L5_2 == "table" then
      L5_2 = L4_2.fAttachCallback
      L6_2 = unpack
      L7_2 = L4_2.tAttachCallbackData
      L6_2 = L6_2(L7_2)
      L7_2 = A2_2
      L8_2 = A1_2
      L9_2 = A3_2
      L5_2(L6_2, L7_2, L8_2, L9_2)
    else
      L5_2 = L4_2.fAttachCallback
      L6_2 = A2_2
      L7_2 = A1_2
      L8_2 = A3_2
      L5_2(L6_2, L7_2, L8_2)
    end
  end
end

_OnAttachment = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L4_2 = A0_2
  L3_2 = A0_2.GetConfig
  L3_2 = L3_2(L4_2)
  L4_2 = L3_2.fStatusChangeCallback
  if L4_2 then
    L4_2 = type
    L5_2 = L3_2.tStatusChangeCallbackData
    L4_2 = L4_2(L5_2)
    if L4_2 == "table" then
      L4_2 = L3_2.fStatusChangeCallback
      L5_2 = unpack
      L6_2 = L3_2.tStatusChangeCallbackData
      L5_2 = L5_2(L6_2)
      L6_2 = A2_2
      L7_2 = A1_2
      L4_2(L5_2, L6_2, L7_2)
    else
      L4_2 = L3_2.fStatusChangeCallback
      L5_2 = A2_2
      L6_2 = A1_2
      L4_2(L5_2, L6_2)
    end
  end
  if A2_2 then
    L4_2 = A0_2._tTargets
    L5_2 = L4_2[A2_2]
    if L5_2 and A1_2 == "destroyed" then
      L5_2 = L4_2[A2_2]
      L5_2 = L5_2.bStatus
      if L5_2 == false then
        L5_2 = A0_2._iNumAttached
        L5_2 = L5_2 - 1
        A0_2._iNumAttached = L5_2
        L5_2 = A0_2._iNumAttached
        if L5_2 == 0 then
          L6_2 = A0_2
          L5_2 = A0_2.EnableDestinationBlip
          L7_2 = false
          L5_2(L6_2, L7_2)
        end
      end
      L6_2 = A0_2
      L5_2 = A0_2._CleanupTargetEvents
      L7_2 = L4_2[A2_2]
      L5_2(L6_2, L7_2)
      L6_2 = A0_2
      L5_2 = A0_2.RemoveTarget
      L7_2 = A2_2
      L5_2(L6_2, L7_2)
    end
    L6_2 = A0_2
    L5_2 = A0_2._SetTargetStatus
    L7_2 = A2_2
    L8_2 = false
    L5_2(L6_2, L7_2, L8_2)
  end
  L5_2 = A0_2
  L4_2 = A0_2.CancelPart
  L4_2(L5_2)
end

_OnStatusChange = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L3_2 = A0_2
  L2_2 = A0_2.GetConfig
  L2_2 = L2_2(L3_2)
  L3_2 = A0_2._tTargets
  L3_2 = L3_2[A1_2]
  L3_2.bAtDestination = false
  L4_2 = nil
  L5_2 = nil
  L6_2 = L2_2.vDestRegion
  if L6_2 then
    L6_2 = Event
    L4_2 = L6_2.Boundary
    L6_2 = {}
    L7_2 = A1_2
    L8_2 = L2_2.vDestRegion
    L9_2 = "enter"
    L10_2 = L2_2.bStop
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L6_2[4] = L10_2
    L5_2 = L6_2
  else
    L6_2 = L2_2.vDestLoc
    if L6_2 then
      L6_2 = Event
      L4_2 = L6_2.ObjectProximity
      L6_2 = {}
      L7_2 = A1_2
      L8_2 = L2_2.vDestLoc
      L9_2 = "<"
      L10_2 = L2_2.fDist
      L11_2 = L2_2.bStop
      L12_2 = L2_2.bXZOnly
      L6_2[1] = L7_2
      L6_2[2] = L8_2
      L6_2[3] = L9_2
      L6_2[4] = L10_2
      L6_2[5] = L11_2
      L6_2[6] = L12_2
      L5_2 = L6_2
    end
  end
  L6_2 = L3_2.tEvents
  L7_2 = Event
  L7_2 = L7_2.Create
  L8_2 = L4_2
  L9_2 = L5_2
  L10_2 = _TargetAtDestination
  L11_2 = {}
  L12_2 = A0_2
  L13_2 = A1_2
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
  L6_2.eDeliver = L7_2
  L6_2 = L2_2.bDisplayHelpText
  if L6_2 then
    L6_2 = MrxTutorialManager
    L6_2 = L6_2.HideMessage
    L6_2()
    L6_2 = Net
    L6_2 = L6_2.SendCustomEvent
    L7_2 = "MrxTaskObjectiveDeliver"
    L8_2 = NETEVENT_CLEARTUTORIAL
    L9_2 = {}
    L6_2(L7_2, L8_2, L9_2)
  end
end

_TargetLeftDestination = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L3_2 = A0_2
  L2_2 = A0_2.GetConfig
  L2_2 = L2_2(L3_2)
  L3_2 = A0_2._tTargets
  L3_2 = L3_2[A1_2]
  L3_2.bAtDestination = true
  L4_2 = nil
  L5_2 = nil
  L6_2 = L2_2.vDestRegion
  if L6_2 then
    L6_2 = Event
    L4_2 = L6_2.Boundary
    L6_2 = {}
    L7_2 = A1_2
    L8_2 = L2_2.vDestRegion
    L9_2 = "exit"
    L10_2 = false
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L6_2[4] = L10_2
    L5_2 = L6_2
  else
    L6_2 = L2_2.vDestLoc
    if L6_2 then
      L6_2 = Event
      L4_2 = L6_2.ObjectProximity
      L6_2 = {}
      L7_2 = A1_2
      L8_2 = L2_2.vDestLoc
      L9_2 = ">"
      L10_2 = L2_2.fDist
      L11_2 = false
      L12_2 = L2_2.bXZOnly
      L6_2[1] = L7_2
      L6_2[2] = L8_2
      L6_2[3] = L9_2
      L6_2[4] = L10_2
      L6_2[5] = L11_2
      L6_2[6] = L12_2
      L5_2 = L6_2
    end
  end
  L6_2 = L3_2.tEvents
  L7_2 = Event
  L7_2 = L7_2.Create
  L8_2 = L4_2
  L9_2 = L5_2
  L10_2 = _TargetLeftDestination
  L11_2 = {}
  L12_2 = A0_2
  L13_2 = A1_2
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
  L6_2.eDeliver = L7_2
  L7_2 = A0_2
  L6_2 = A0_2._DeliveryCheck
  L8_2 = A1_2
  L6_2(L7_2, L8_2)
end

_TargetAtDestination = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = A0_2
  L2_2 = A0_2.EnableDestinationBlip
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = nil
  L3_2 = nil
  L4_2 = A1_2.vDestRegion
  if L4_2 then
    L4_2 = A1_2.vDestLoc
    if not L4_2 then
      return
    end
  end
  L4_2 = Event
  L4_2 = L4_2.CreatePersistent
  L5_2 = Event
  L5_2 = L5_2.ObjectProximity
  L6_2 = {}
  L7_2 = A0_2._uTgtObjFilter
  L8_2 = A1_2.vDestLoc
  L9_2 = "<"
  L10_2 = A1_2.fDist
  L11_2 = A1_2.bStop
  L12_2 = A1_2.bXZOnly
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L6_2[5] = L11_2
  L6_2[6] = L12_2
  
  function L7_2(A0_3, A1_3)
    local L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
    L2_3 = type
    L3_3 = A1_3
    L2_3 = L2_3(L3_3)
    if L2_3 == "table" then
      L2_3 = pairs
      L3_3 = A1_3
      L2_3, L3_3, L4_3 = L2_3(L3_3)
      for L5_3, L6_3 in L2_3, L3_3, L4_3 do
        L8_3 = A0_3
        L7_3 = A0_3._FilterTargetAtDestination
        L9_3 = L6_3
        L7_3(L8_3, L9_3)
        L7_3 = A0_3._nCompleted
        L8_3 = A0_3._nQuota
        if L7_3 == L8_3 then
          break
        end
      end
    else
      L3_3 = A0_3
      L2_3 = A0_3._FilterTargetAtDestination
      L4_3 = A1_3
      L2_3(L3_3, L4_3)
    end
  end
  
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  return L4_2(L5_2, L6_2, L7_2, L8_2)
end

LabelFilterDeliveryCreate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = ObjectFilter
  L2_2 = L2_2.AddObject
  L3_2 = A0_2._uTgtObjFilter
  L4_2 = A1_2
  L5_2 = true
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = {}
  L3_2 = A0_2._tTargets
  L3_2[A1_2] = L2_2
  L3_2 = {}
  L2_2.tEvents = L3_2
  L2_2.bIsLabelFilter = true
  L3_2 = Object
  L3_2 = L3_2.HasLabel
  L4_2 = A1_2
  L5_2 = "human"
  L3_2 = L3_2(L4_2, L5_2)
  if not L3_2 then
    L3_2 = Object
    L3_2 = L3_2.IsWinched
    L4_2 = A1_2
    L3_2 = L3_2(L4_2)
    L3_2 = L3_2 ~= nil
    L2_2.bWinched = L3_2
    L3_2 = L2_2.tEvents
    L4_2 = Event
    L4_2 = L4_2.CreatePersistent
    L5_2 = Event
    L5_2 = L5_2.ObjectWinched
    L6_2 = {}
    L7_2 = A1_2
    L8_2 = 0
    L9_2 = "any"
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L7_2 = A0_2._OnObjectWinched
    L8_2 = {}
    L9_2 = A0_2
    L8_2[1] = L9_2
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
    L3_2.eWinch = L4_2
  end
  L3_2 = Object
  L3_2 = L3_2.HasLabel
  L4_2 = A1_2
  L5_2 = "vehicle"
  L3_2 = L3_2(L4_2, L5_2)
  if L3_2 then
    L4_2 = A0_2
    L3_2 = A0_2._OnPlayerInVehicle
    L5_2 = nil
    L6_2 = A1_2
    L7_2 = nil
    L8_2 = nil
    L9_2 = "exit"
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  end
  L2_2.bAtDestination = true
  L4_2 = A0_2
  L3_2 = A0_2._DeliveryCheck
  L5_2 = A1_2
  L3_2 = L3_2(L4_2, L5_2)
  if not L3_2 then
    L4_2 = A0_2
    L3_2 = A0_2.GetConfig
    L3_2 = L3_2(L4_2)
    L4_2 = L2_2.tEvents
    L5_2 = Event
    L5_2 = L5_2.Create
    L6_2 = Event
    L6_2 = L6_2.ObjectProximity
    L7_2 = {}
    L8_2 = A1_2
    L9_2 = L3_2.vDestLoc
    L10_2 = ">"
    L11_2 = L3_2.fDist
    L12_2 = false
    L13_2 = L3_2.bXZOnly
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L7_2[4] = L11_2
    L7_2[5] = L12_2
    L7_2[6] = L13_2
    L8_2 = _FilterTargetLeftDestination
    L9_2 = {}
    L10_2 = A0_2
    L11_2 = A1_2
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
    L4_2.eDeliver = L5_2
  end
end

_FilterTargetAtDestination = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L3_2 = A0_2
  L2_2 = A0_2._CleanupTargetEvents
  L4_2 = A0_2._tTargets
  L4_2 = L4_2[A1_2]
  L2_2(L3_2, L4_2)
  L2_2 = A0_2._tTargets
  L2_2[A1_2] = nil
  L2_2 = ObjectFilter
  L2_2 = L2_2.RemoveObject
  L3_2 = A0_2._uTgtObjFilter
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2.GetConfig
  L2_2 = L2_2(L3_2)
  L2_2 = L2_2.bDisplayHelpText
  if L2_2 then
    L2_2 = MrxTutorialManager
    L2_2 = L2_2.HideMessage
    L2_2()
    L2_2 = Net
    L2_2 = L2_2.SendCustomEvent
    L3_2 = "MrxTaskObjectiveDeliver"
    L4_2 = NETEVENT_CLEARTUTORIAL
    L5_2 = {}
    L2_2(L3_2, L4_2, L5_2)
  end
end

_FilterTargetLeftDestination = L0_1
L0_1 = 1
sGlobalDiscCount = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L3_2 = A0_2
  L2_2 = A0_2.GetConfig
  L2_2 = L2_2(L3_2)
  L4_2 = A0_2
  L3_2 = A0_2._SetTargetStatus
  L5_2 = L2_2.vDestLoc
  if not L5_2 then
    L5_2 = L2_2.vDestRegion
  end
  L6_2 = A1_2
  L7_2 = "destination"
  L3_2(L4_2, L5_2, L6_2, L7_2)
  L3_2 = L2_2.bUseDestRing
  if L3_2 then
    if A1_2 then
      L3_2 = A0_2.uRing
      if not L3_2 then
        L3_2 = nil
        L4_2 = nil
        L5_2 = nil
        L6_2 = L2_2.bOptional
        if L6_2 then
          L6_2 = MrxUtil
          L6_2 = L6_2.GetSecondaryObjectiveRgb
          L6_2, L7_2, L8_2 = L6_2()
          L5_2 = L8_2
          L4_2 = L7_2
          L3_2 = L6_2
        else
          L6_2 = MrxUtil
          L6_2 = L6_2.GetPrimaryObjectiveRgb
          L6_2, L7_2, L8_2 = L6_2()
          L5_2 = L8_2
          L4_2 = L7_2
          L3_2 = L6_2
        end
        L6_2 = Marker
        L6_2 = L6_2.AddDisc
        L7_2 = L2_2.vDestLoc
        L8_2 = L2_2.fDist
        L9_2 = L3_2
        L10_2 = L4_2
        L11_2 = L5_2
        L12_2 = 0.02
        L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
        A0_2.uRing = L6_2
        L6_2 = Net
        L6_2 = L6_2.IsServer
        L6_2 = L6_2()
        if L6_2 then
          L6_2 = Net
          L6_2 = L6_2.SendEvent_AddMarkerObjective
          L7_2 = L2_2.vDestLoc
          L8_2 = A0_2.uRing
          L9_2 = L3_2
          L10_2 = L4_2
          L11_2 = L5_2
          L12_2 = 0.02
          L13_2 = 0
          L14_2 = L2_2.fDist
          L15_2 = 0
          L16_2 = true
          L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
        end
        L6_2 = sGlobalDiscCount
        if 8192 <= L6_2 then
          L6_2 = 0
          sGlobalDiscCount = L6_2
        end
        L6_2 = sGlobalDiscCount
        A0_2.discCount = L6_2
        L6_2 = sGlobalDiscCount
        L6_2 = L6_2 + 1
        sGlobalDiscCount = L6_2
      end
    else
      L3_2 = A0_2.uRing
      if L3_2 then
        L3_2 = Marker
        L3_2 = L3_2.Remove
        L4_2 = A0_2.uRing
        L3_2(L4_2)
        L3_2 = Net
        L3_2 = L3_2.IsServer
        L3_2 = L3_2()
        if L3_2 then
          L3_2 = Net
          L3_2 = L3_2.SendEvent_RemoveMarkerObjective
          L4_2 = A0_2.uRing
          L3_2(L4_2)
        end
        A0_2.uRing = nil
      end
    end
  end
end

EnableDestinationBlip = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = ObjectFilter
  L2_2 = L2_2.GetObjects
  L3_2 = A0_2._uTgtObjFilter
  L4_2 = false
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = A0_2
    L8_2 = A0_2._SetTargetStatus
    L10_2 = L7_2
    L11_2 = A1_2
    L8_2(L9_2, L10_2, L11_2)
  end
end

EnableTargetBlips = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = A0_2
  L2_2 = A0_2.GetConfig
  L2_2 = L2_2(L3_2)
  L3_2 = nil
  L4_2 = nil
  L5_2 = L2_2.vDestRegion
  if L5_2 then
    L5_2 = Event
    L3_2 = L5_2.Boundary
    L5_2 = {}
    L6_2 = A1_2
    L7_2 = L2_2.vDestRegion
    L8_2 = "enter"
    L9_2 = L2_2.bStop
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L5_2[4] = L9_2
    L4_2 = L5_2
  else
    L5_2 = L2_2.vDestLoc
    if L5_2 then
      L5_2 = Event
      L3_2 = L5_2.ObjectProximity
      L5_2 = {}
      L6_2 = A1_2
      L7_2 = L2_2.vDestLoc
      L8_2 = "<"
      L9_2 = L2_2.fDist
      L10_2 = L2_2.bStop
      L11_2 = L2_2.bXZOnly
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      L5_2[3] = L8_2
      L5_2[4] = L9_2
      L5_2[5] = L10_2
      L5_2[6] = L11_2
      L4_2 = L5_2
    end
  end
  L6_2 = A0_2
  L5_2 = A0_2.EnableDestinationBlip
  L7_2 = true
  L5_2(L6_2, L7_2)
  L5_2 = Event
  L5_2 = L5_2.Create
  L6_2 = L3_2
  L7_2 = L4_2
  L8_2 = _TargetDelivered
  L9_2 = {}
  L10_2 = A0_2
  L11_2 = A1_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  return L5_2(L6_2, L7_2, L8_2, L9_2)
end

_PlayerDeliveryCreate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = A0_2
  L2_2 = A0_2.GetConfig
  L2_2 = L2_2(L3_2)
  L3_2 = A0_2._tTargets
  L3_2 = L3_2[A1_2]
  L4_2 = {}
  L5_2 = L2_2.bHumansFollow
  if L5_2 then
    L5_2 = L2_2.uStartAttachedToPlayer
    if not L5_2 then
      L5_2 = A0_2._iNumAttached
      L5_2 = L5_2 + 1
      A0_2._iNumAttached = L5_2
    end
    L5_2 = {}
    L5_2._vActor = A1_2
    L6_2 = L2_2.uStartAttachedToPlayer
    L5_2._vObjectToFollow = L6_2
    L6_2 = _OnAttachment
    L5_2._fCallback = L6_2
    L6_2 = {}
    L7_2 = A0_2
    L8_2 = "follow"
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L5_2._tCallbackData = L6_2
    L6_2 = L2_2.tStartFollowVO
    L5_2.tStartFollowVO = L6_2
    L6_2 = L2_2.tStopFollowVO
    L5_2.tStopFollowVO = L6_2
    L6_2 = L2_2.tLostVO
    L5_2.tLostVO = L6_2
    L6_2 = L2_2.tFoundVO
    L5_2.tFoundVO = L6_2
    L6_2 = L2_2.tHostileVO
    L5_2.tHostileVO = L6_2
    L6_2 = L2_2.tHostileRecoveredVO
    L5_2.tHostileRecoveredVO = L6_2
    L6_2 = MrxFollow
    L7_2 = L6_2
    L6_2 = L6_2.Create
    L8_2 = L5_2
    L6_2 = L6_2(L7_2, L8_2)
    L8_2 = L6_2
    L7_2 = L6_2.Activate
    L9_2 = true
    L10_2 = L2_2.uStartAttachedToPlayer
    L10_2 = L10_2 ~= nil
    L7_2(L8_2, L9_2, L10_2)
    L3_2.oFollower = L6_2
  end
  L5_2 = Event
  L5_2 = L5_2.Create
  L6_2 = Event
  L6_2 = L6_2.HumanStateTransition
  L7_2 = {}
  L8_2 = A1_2
  L9_2 = "*"
  L10_2 = "subdued.idle"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L8_2 = _OnStatusChange
  L9_2 = {}
  L10_2 = A0_2
  L11_2 = "subdued"
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L4_2.eSubdue = L5_2
  L3_2.tEvents = L4_2
  L6_2 = A0_2
  L5_2 = A0_2._TargetLeftDestination
  L7_2 = A1_2
  L5_2(L6_2, L7_2)
end

_HumanDeliveryCreate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = Object
  L2_2 = L2_2.InSeat
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = Object
    L2_2 = L2_2.IsPlayerControlled
    L3_2 = A1_2
    L2_2 = L2_2(L3_2)
    if not L2_2 then
      L2_2 = Vehicle
      L2_2 = L2_2.GetFromRider
      L3_2 = A1_2
      L2_2 = L2_2(L3_2)
      L3_2 = Vehicle
      L3_2 = L3_2.Exit
      L4_2 = L2_2
      L5_2 = A1_2
      L3_2(L4_2, L5_2)
    end
  end
  L2_2 = A0_2._tTargets
  L2_2 = L2_2[A1_2]
  if L2_2 then
    L3_2 = Object
    L3_2 = L3_2.IsPlayerControlled
    L4_2 = A1_2
    L3_2 = L3_2(L4_2)
    if not L3_2 then
      L3_2 = L2_2.bAtDestination
      return L3_2
  end
  else
    L3_2 = true
    return L3_2
  end
end

_HumanDeliveryCheck = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  L5_2 = A0_2
  L4_2 = A0_2._OnAttachment
  L6_2 = A1_2
  L7_2 = A2_2
  L8_2 = A3_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L5_2 = A0_2
  L4_2 = A0_2._MarkAttachedHuman
  L6_2 = A2_2
  L7_2 = A3_2
  L4_2(L5_2, L6_2, L7_2)
end

_HumanOnAttachment = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L3_2 = A0_2._tTargets
  L3_2 = L3_2[A1_2]
  if not L3_2 then
    return
  end
  if A2_2 then
    L4_2 = 255
    L5_2 = 255
    L6_2 = 0
    L7_2 = Marker
    L7_2 = L7_2.Add
    L8_2 = 0
    L9_2 = 2
    L10_2 = 0
    L11_2 = A1_2
    L12_2 = L4_2
    L13_2 = L5_2
    L14_2 = L6_2
    L15_2 = 0.05
    L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
    L3_2.uMarker = L7_2
    L7_2 = Net
    L7_2 = L7_2.IsServer
    L7_2 = L7_2()
    if L7_2 then
      L7_2 = Net
      L7_2 = L7_2.SendEvent_AddMarkerObjective
      L8_2 = A1_2
      L9_2 = L3_2.uMarker
      L10_2 = L4_2
      L11_2 = L5_2
      L12_2 = L6_2
      L13_2 = 2
      L14_2 = ""
      L15_2 = 0.05
      L16_2 = 0
      L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
    end
    L7_2 = Hud
    L7_2 = L7_2.Radar
    L8_2 = L7_2
    L7_2 = L7_2.AddObjective
    L9_2 = {}
    L10_2 = tostring
    L11_2 = A1_2
    L10_2 = L10_2(L11_2)
    L9_2.sName = L10_2
    L9_2.nR = L4_2
    L9_2.nG = L5_2
    L9_2.nB = L6_2
    L9_2.nWidth = 2
    L9_2.nHeight = 2
    L9_2.uGuid = A1_2
    L9_2.bSticky = true
    L7_2(L8_2, L9_2)
    L7_2 = Net
    L7_2 = L7_2.SendEvent_AddRadarObjective
    L8_2 = tostring
    L9_2 = A1_2
    L8_2 = L8_2(L9_2)
    L9_2 = 0
    L10_2 = 2
    L11_2 = 0
    L12_2 = L4_2
    L13_2 = L5_2
    L14_2 = L6_2
    L15_2 = 2
    L16_2 = 2
    L17_2 = ""
    L18_2 = A1_2
    L19_2 = true
    L20_2 = false
    L21_2 = 0
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
  else
    L4_2 = L3_2.uMarker
    if L4_2 ~= nil then
      L4_2 = Marker
      L4_2 = L4_2.Remove
      L5_2 = L3_2.uMarker
      L4_2(L5_2)
      L4_2 = Hud
      L4_2 = L4_2.Radar
      L5_2 = L4_2
      L4_2 = L4_2.RemoveObjective
      L6_2 = {}
      L7_2 = tostring
      L8_2 = A1_2
      L7_2 = L7_2(L8_2)
      L6_2.sName = L7_2
      L4_2(L5_2, L6_2)
      L4_2 = Net
      L4_2 = L4_2.IsServer
      L4_2 = L4_2()
      if L4_2 then
        L4_2 = Net
        L4_2 = L4_2.SendEvent_RemoveMarkerObjective
        L5_2 = L3_2.uMarker
        L4_2(L5_2)
        L4_2 = Net
        L4_2 = L4_2.SendEvent_RemoveRadarObjective
        L5_2 = tostring
        L6_2 = A1_2
        L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L5_2(L6_2)
        L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
      end
    end
  end
end

_MarkAttachedHuman = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = {}
  L3_2 = Event
  L3_2 = L3_2.CreatePersistent
  L4_2 = Event
  L4_2 = L4_2.ObjectWinched
  L5_2 = {}
  L6_2 = A1_2
  L7_2 = 0
  L8_2 = "any"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L6_2 = A0_2._OnObjectWinched
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2.eWinch = L3_2
  L3_2 = A0_2._tTargets
  L3_2 = L3_2[A1_2]
  L3_2.tEvents = L2_2
  L3_2.bWinched = false
  L4_2 = Object
  L4_2 = L4_2.IsWinched
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  if L4_2 then
    L6_2 = A0_2
    L5_2 = A0_2._OnObjectWinched
    L7_2 = A1_2
    L8_2 = L4_2
    L9_2 = "attach"
    L5_2(L6_2, L7_2, L8_2, L9_2)
  end
  L6_2 = A0_2
  L5_2 = A0_2._TargetLeftDestination
  L7_2 = A1_2
  L5_2(L6_2, L7_2)
end

_ObjectDeliveryCreate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = A0_2._tTargets
  L3_2 = L3_2[A1_2]
  L4_2 = L3_2.bWinched
  if L4_2 then
    L5_2 = A0_2
    L4_2 = A0_2.GetConfig
    L4_2 = L4_2(L5_2)
    L4_2 = L4_2.bDisplayHelpText
    if L4_2 then
      L4_2 = MrxTutorialManager
      L4_2 = L4_2.ShowMessage
      L5_2 = "[objective.Deliver.winch]"
      L4_2(L5_2)
      L4_2 = Net
      L4_2 = L4_2.SendCustomEvent
      L5_2 = "MrxTaskObjectiveDeliver"
      L6_2 = NETEVENT_UNWINCH
      L7_2 = {}
      L4_2(L5_2, L6_2, L7_2)
    end
    L4_2 = false
    return L4_2
  else
    L4_2 = true
    return L4_2
  end
end

_ObjectDeliveryCheck = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = A0_2
  L2_2 = A0_2._ObjectDeliveryCreate
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
  L2_2 = A0_2._tTargets
  L2_2 = L2_2[A1_2]
  L2_2.bPlayerInVehicle = false
  L4_2 = A0_2
  L3_2 = A0_2._OnPlayerInVehicle
  L5_2 = nil
  L6_2 = A1_2
  L7_2 = nil
  L8_2 = nil
  L9_2 = "exit"
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
end

_VehicleDeliveryCreate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = A0_2._tTargets
  L3_2 = L3_2[A1_2]
  L4_2 = L3_2.bPlayerInVehicle
  if L4_2 then
    L5_2 = A0_2
    L4_2 = A0_2.GetConfig
    L4_2 = L4_2(L5_2)
    L4_2 = L4_2.bDisplayHelpText
    if L4_2 then
      L4_2 = Net
      L4_2 = L4_2.IsServer
      L4_2 = L4_2()
      if L4_2 then
        L4_2 = MrxTutorialManager
        L4_2 = L4_2.ShowMessage
        L5_2 = "[objective.Deliver.vehicleExit]"
        L4_2(L5_2)
        L4_2 = Net
        L4_2 = L4_2.SendCustomEvent
        L5_2 = "MrxTaskObjectiveDeliver"
        L6_2 = NETEVENT_EXITVEHICLE
        L7_2 = {}
        L4_2(L5_2, L6_2, L7_2)
      end
    end
    L4_2 = false
    return L4_2
  else
    L5_2 = A0_2
    L4_2 = A0_2._ObjectDeliveryCheck
    L6_2 = A1_2
    return L4_2(L5_2, L6_2)
  end
end

_VehicleDeliveryCheck = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L4_2 = A0_2._tTargets
  L4_2 = L4_2[A1_2]
  L5_2 = A3_2 == "attach"
  L6_2 = L4_2.bWinched
  if L6_2 ~= L5_2 then
    L4_2.bWinched = L5_2
    L6_2 = L4_2.bPlayerInVehicle
    if not L6_2 then
      L6_2 = L4_2.bIsLabelFilter
      if not L6_2 then
        L7_2 = A0_2
        L6_2 = A0_2._OnAttachment
        L8_2 = "winched"
        L9_2 = A1_2
        L10_2 = L4_2.bWinched
        L6_2(L7_2, L8_2, L9_2, L10_2)
      end
    end
  end
  L6_2 = L4_2.bAtDestination
  if L6_2 then
    L7_2 = A0_2
    L6_2 = A0_2._DeliveryCheck
    L8_2 = A1_2
    L6_2(L7_2, L8_2)
  end
end

_OnObjectWinched = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L6_2 = A5_2 == "enter"
  if not L6_2 then
    L7_2 = Vehicle
    L7_2 = L7_2.GetRiders
    L8_2 = A2_2
    L7_2 = L7_2(L8_2)
    L8_2 = pairs
    L9_2 = L7_2
    L8_2, L9_2, L10_2 = L8_2(L9_2)
    for L11_2, L12_2 in L8_2, L9_2, L10_2 do
      L13_2 = Object
      L13_2 = L13_2.IsPlayerControlled
      L14_2 = L12_2
      L13_2 = L13_2(L14_2)
      if L13_2 then
        L6_2 = true
        A1_2 = L12_2
      end
    end
  end
  L7_2 = A0_2._tTargets
  L7_2 = L7_2[A2_2]
  L8_2 = L7_2.bPlayerInVehicle
  if L8_2 ~= L6_2 then
    L7_2.bPlayerInVehicle = L6_2
    L8_2 = L7_2.bWinched
    if not L8_2 then
      L8_2 = L7_2.bIsLabelFilter
      if not L8_2 then
        L9_2 = A0_2
        L8_2 = A0_2._OnAttachment
        L10_2 = "in_target_veh"
        L11_2 = A2_2
        L12_2 = L6_2
        L8_2(L9_2, L10_2, L11_2, L12_2)
      end
    end
  end
  L8_2 = Event
  L8_2 = L8_2.Delete
  L9_2 = L7_2.tEvents
  L9_2 = L9_2.eVehicleSeat
  L8_2(L9_2)
  L8_2 = Event
  L8_2 = L8_2.Delete
  L9_2 = L7_2.tEvents
  L9_2 = L9_2.eMPDrop
  L8_2(L9_2)
  if L6_2 then
    L8_2 = L7_2.tEvents
    L9_2 = Event
    L9_2 = L9_2.Create
    L10_2 = Event
    L10_2 = L10_2.ObjectInSeat
    L11_2 = {}
    L12_2 = Player
    L12_2 = L12_2.GetAnyCharacter
    L12_2 = L12_2()
    L13_2 = A2_2
    L14_2 = "a"
    L15_2 = "x"
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L11_2[3] = L14_2
    L11_2[4] = L15_2
    L12_2 = _OnPlayerInVehicle
    L13_2 = {}
    L14_2 = A0_2
    L13_2[1] = L14_2
    L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2)
    L8_2.eVehicleSeat = L9_2
    L8_2 = Object
    L8_2 = L8_2.IsPlayerControlled
    L9_2 = A1_2
    L8_2 = L8_2(L9_2)
    L9_2 = Player
    L9_2 = L9_2.IsLocal
    L10_2 = L8_2
    L9_2 = L9_2(L10_2)
    if not L9_2 then
      L9_2 = L7_2.tEvents
      L10_2 = Event
      L10_2 = L10_2.Create
      L11_2 = Event
      L11_2 = L11_2.ScriptEvent
      L12_2 = {}
      L13_2 = "mpPlayerLeft"
      
      function L14_2(A0_3)
        local L1_3, L2_3
        L1_3 = A1_2
        L2_3 = A0_3[2]
        L1_3 = L1_3 == L2_3
        return L1_3
      end
      
      L12_2[1] = L13_2
      L12_2[2] = L14_2
      L13_2 = _OnPlayerInVehicle
      L14_2 = {}
      L15_2 = A0_2
      L16_2 = A1_2
      L17_2 = A2_2
      L18_2 = "any"
      L19_2 = A2_2
      L20_2 = "exit"
      L14_2[1] = L15_2
      L14_2[2] = L16_2
      L14_2[3] = L17_2
      L14_2[4] = L18_2
      L14_2[5] = L19_2
      L14_2[6] = L20_2
      L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2)
      L9_2.eMPDrop = L10_2
    end
  else
    L8_2 = L7_2.tEvents
    L9_2 = Event
    L9_2 = L9_2.Create
    L10_2 = Event
    L10_2 = L10_2.ObjectInSeat
    L11_2 = {}
    L12_2 = Player
    L12_2 = L12_2.GetAnyCharacter
    L12_2 = L12_2()
    L13_2 = A2_2
    L14_2 = "a"
    L15_2 = "e"
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L11_2[3] = L14_2
    L11_2[4] = L15_2
    L12_2 = _OnPlayerInVehicle
    L13_2 = {}
    L14_2 = A0_2
    L13_2[1] = L14_2
    L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2)
    L8_2.eVehicleSeat = L9_2
  end
  L8_2 = L7_2.bAtDestination
  if L8_2 then
    L9_2 = A0_2
    L8_2 = A0_2._DeliveryCheck
    L10_2 = A2_2
    L8_2(L9_2, L10_2)
  end
end

_OnPlayerInVehicle = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = "[Generic.ObjectiveDeliver]"
  return L0_2
end

_GetShortDescription = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2.bOptional
  if L2_2 then
    L2_2 = "[objdeliver2]"
    return L2_2
  else
    L2_2 = "[objdeliver]"
    return L2_2
  end
end

GetInlineIcon = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = "objective_action"
  return L0_2
end

_GetTargetRadarIcon = L0_1

function L0_1(A0_2)
  local L1_2
  if A0_2 then
    L1_2 = "icon_action_2_mc"
    return L1_2
  else
    L1_2 = "icon_action_1_mc"
    return L1_2
  end
end

_GetTargetPdaIcon = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = "HUD_objective_action"
  return L0_2
end

_GetTargetGameSpaceIcon = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = "objective_deliverable"
  return L0_2
end

_GetDestinationRadarIcon = L0_1

function L0_1(A0_2)
  local L1_2
  if A0_2 then
    L1_2 = "icon_deliverable_2_mc"
    return L1_2
  else
    L1_2 = "icon_deliverable_1_mc"
    return L1_2
  end
end

_GetDestinationPdaIcon = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = "HUD_objective_deliverable"
  return L0_2
end

_GetDestinationGameSpaceIcon = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Player
  L1_2 = L1_2.GetAnyCharacter
  L1_2 = L1_2()
  L2_2 = Player
  L2_2 = L2_2.GetAllCharacters
  L2_2 = L2_2()
  if L1_2 == A0_2 then
    L3_2 = true
    return L3_2
  end
  if L2_2 == A0_2 then
    L3_2 = true
    return L3_2
  end
  L3_2 = Object
  L3_2 = L3_2.IsAlive
  L4_2 = A0_2
  return L3_2(L4_2)
end

_IsValidTarget = L0_1
L0_1 = 0
NETEVENT_EXITVEHICLE = L0_1
L0_1 = 1
NETEVENT_UNWINCH = L0_1
L0_1 = 5
NETEVENT_CLEARTUTORIAL = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = NETEVENT_EXITVEHICLE
  if A0_2 == L2_2 then
    L2_2 = MrxTutorialManager
    L2_2 = L2_2.ShowMessage
    L3_2 = "[objective.Deliver.vehicleExit]"
    L2_2(L3_2)
  else
    L2_2 = NETEVENT_UNWINCH
    if A0_2 == L2_2 then
      L2_2 = MrxTutorialManager
      L2_2 = L2_2.ShowMessage
      L3_2 = "[objective.Deliver.winch]"
      L2_2(L3_2)
    else
      L2_2 = NETEVENT_CLEARTUTORIAL
      if A0_2 == L2_2 then
        L2_2 = MrxTutorialManager
        L2_2 = L2_2.HideMessage
        L2_2()
      end
    end
  end
end

NetEventCallback = L0_1
