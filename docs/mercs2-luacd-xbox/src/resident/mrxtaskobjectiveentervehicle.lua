local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskObjective"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = MrxTaskObjective
  L2_2 = L2_2.Activated
  L3_2 = A0_2
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2.GetConfig
  L2_2 = L2_2(L3_2)
  L3_2 = MrxUtil
  L3_2 = L3_2.SetDefault
  L4_2 = L2_2.uPlayer
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L5_2()
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  L2_2.uPlayer = L3_2
  L3_2 = ObjectFilter
  L3_2 = L3_2.GetObjects
  L4_2 = A0_2._uTgtObjFilter
  L5_2 = false
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = pairs
  L5_2 = L3_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L10_2 = A0_2
    L9_2 = A0_2._SetupEvents
    L11_2 = L8_2
    L9_2(L10_2, L11_2)
  end
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
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
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = A0_2._tTargets
  L2_2 = L2_2[A1_2]
  L3_2 = {}
  L2_2.tEvents = L3_2
  L3_2 = L2_2.tEvents
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.ObjectDeath
  L6_2 = {}
  L7_2 = A1_2
  L6_2[1] = L7_2
  L7_2 = _OnStatusChange
  L8_2 = {}
  L9_2 = A0_2
  L10_2 = "destroyed"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L3_2.eDeathEvent = L4_2
  L4_2 = A0_2
  L3_2 = A0_2.GetConfig
  L3_2 = L3_2(L4_2)
  L4_2 = "d"
  L5_2 = L3_2.bUseAnySeat
  if L5_2 then
    L4_2 = "a"
  end
  L5_2 = L3_2.uPlayer
  L6_2 = Player
  L6_2 = L6_2.GetAllCharacters
  L6_2 = L6_2()
  if L5_2 == L6_2 then
    A0_2._bUseAllChars = true
    L5_2 = L2_2.tEvents
    L6_2 = Event
    L6_2 = L6_2.CreatePersistent
    L7_2 = Event
    L7_2 = L7_2.ObjectInSeat
    L8_2 = {}
    L9_2 = Player
    L9_2 = L9_2.GetAnyCharacter
    L9_2 = L9_2()
    L10_2 = A1_2
    L11_2 = "a"
    L12_2 = "e"
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L8_2[4] = L12_2
    L9_2 = _TargetEntered
    L10_2 = {}
    L11_2 = A0_2
    L10_2[1] = L11_2
    L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
    L5_2.eObjectInSeat = L6_2
  else
    L5_2 = L2_2.tEvents
    L6_2 = Event
    L6_2 = L6_2.Create
    L7_2 = Event
    L7_2 = L7_2.ObjectInSeat
    L8_2 = {}
    L9_2 = L3_2.uPlayer
    L10_2 = A1_2
    L11_2 = L4_2
    L12_2 = "ei"
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L8_2[4] = L12_2
    L9_2 = _TargetEntered
    L10_2 = {}
    L11_2 = A0_2
    L10_2[1] = L11_2
    L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
    L5_2.eObjectInSeat = L6_2
  end
end

_SetupEvents = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  if A1_2 == nil then
    return
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

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
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
  L5_2 = A0_2
  L4_2 = A0_2._CleanupTargetEvents
  L6_2 = A0_2._tTargets
  L6_2 = L6_2[A2_2]
  L4_2(L5_2, L6_2)
  L5_2 = A0_2
  L4_2 = A0_2._SetTargetStatus
  L6_2 = A2_2
  L7_2 = false
  L4_2(L5_2, L6_2, L7_2)
  L5_2 = A0_2
  L4_2 = A0_2.CancelPart
  L4_2(L5_2)
end

_OnStatusChange = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = A0_2._bUseAllChars
  if L3_2 then
    L3_2 = ipairs
    L4_2 = Player
    L4_2 = L4_2.GetAllPlayers
    L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L4_2()
    L3_2, L4_2, L5_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
    for L6_2, L7_2 in L3_2, L4_2, L5_2 do
      L8_2 = Player
      L8_2 = L8_2.GetControlledObject
      L9_2 = L7_2
      L8_2 = L8_2(L9_2)
      if L8_2 ~= A2_2 then
        L8_2 = false
        return L8_2
      end
    end
  end
  L4_2 = A0_2
  L3_2 = A0_2._CleanupTargetEvents
  L5_2 = A0_2._tTargets
  L5_2 = L5_2[A2_2]
  L3_2(L4_2, L5_2)
  L3_2 = type
  L4_2 = A2_2
  L3_2 = L3_2(L4_2)
  if L3_2 == "userdata" then
    L4_2 = A0_2
    L3_2 = A0_2.RemoveTarget
    L5_2 = A2_2
    L3_2(L4_2, L5_2)
  end
  L4_2 = A0_2
  L3_2 = A0_2.CompletePart
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
end

_TargetEntered = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = ObjectFilter
  L2_2 = L2_2.GetObjects
  L3_2 = A0_2._uTgtObjFilter
  L4_2 = false
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = L2_2[1]
  if L3_2 then
    L3_2 = Object
    L3_2 = L3_2.GetLocalizedName
    L4_2 = L2_2[1]
    L3_2 = L3_2(L4_2)
    sName = L3_2
  end
  L3_2 = sName
  if L3_2 then
    L3_2 = L2_2[1]
    if L3_2 then
      L3_2 = Object
      L3_2 = L3_2.HasLabel
      L4_2 = L2_2[1]
      L5_2 = "helicopter"
      L3_2 = L3_2(L4_2, L5_2)
      if L3_2 then
        L3_2 = "[ContextAction.PilotVehicleName:"
        L4_2 = tostring
        L5_2 = sName
        L4_2 = L4_2(L5_2)
        L5_2 = "]"
        L3_2 = L3_2 .. L4_2 .. L5_2
        return L3_2
    end
    else
      L3_2 = "[ContextAction.EnterVehicleName:"
      L4_2 = tostring
      L5_2 = sName
      L4_2 = L4_2(L5_2)
      L5_2 = "]"
      L3_2 = L3_2 .. L4_2 .. L5_2
      return L3_2
    end
  else
    L3_2 = "[Generic.ObjectiveEnterVehicle]"
    return L3_2
  end
end

_GetShortDescription = L0_1

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
