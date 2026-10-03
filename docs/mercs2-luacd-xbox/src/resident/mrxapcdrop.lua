local L0_1, L1_1
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  if A1_2 == nil then
    return
  end
  L2_2 = Object
  L2_2 = L2_2.IsAlive
  L3_2 = A1_2.uVehicle
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L2_2 = {}
  L3_2 = setmetatable
  L4_2 = L2_2
  L5_2 = A0_2
  L3_2(L4_2, L5_2)
  A0_2.__index = A0_2
  L3_2 = A1_2.uVehicle
  L2_2.uVehicle = L3_2
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = L2_2.uVehicle
  L3_2 = L3_2(L4_2)
  L2_2.uDriver = L3_2
  L3_2 = _GetGuidIfString
  L4_2 = A1_2.inDest
  L3_2 = L3_2(L4_2)
  L2_2.inDest = L3_2
  L3_2 = A1_2.inDestType
  L2_2.inDestType = L3_2
  L3_2 = MrxUtil
  L3_2 = L3_2.SetDefault
  L4_2 = A1_2.inSpeed
  L5_2 = 0.8
  L3_2 = L3_2(L4_2, L5_2)
  L2_2.inSpeed = L3_2
  L3_2 = _GetGuidIfString
  L4_2 = A1_2.outDest
  L3_2 = L3_2(L4_2)
  L2_2.outDest = L3_2
  L3_2 = A1_2.outDestType
  L2_2.outDestType = L3_2
  L3_2 = MrxUtil
  L3_2 = L3_2.SetDefault
  L4_2 = A1_2.outSpeed
  L5_2 = 0.8
  L3_2 = L3_2(L4_2, L5_2)
  L2_2.outSpeed = L3_2
  L3_2 = A1_2.squadName
  L2_2.squadName = L3_2
  L3_2 = _GetGuidIfString
  L4_2 = A1_2.squadTarget
  L3_2 = L3_2(L4_2)
  L2_2.squadTarget = L3_2
  L3_2 = A1_2.squadOrder
  L2_2.squadOrder = L3_2
  L3_2 = A1_2.fDropDoneCallback
  L2_2.fDropDoneCallback = L3_2
  L3_2 = A1_2.MaintainRotorSpeed
  L2_2.MaintainRotorSpeed = L3_2
  L3_2 = L2_2.inDest
  if L3_2 then
    L3_2 = {}
    L4_2 = L2_2.uDriver
    L3_2.AIGuid = L4_2
    L3_2.Priority = "HiPri"
    L4_2 = L2_2.inDest
    L3_2.Target = L4_2
    L4_2 = L2_2._DropCallback
    L3_2.Callback = L4_2
    L4_2 = {}
    L5_2 = L2_2
    L4_2[1] = L5_2
    L3_2.CallbackData = L4_2
    L3_2.Force = true
    L4_2 = L2_2.inDestType
    if L4_2 == "path" then
      L3_2.Goal = "PathMove"
    else
      L4_2 = L2_2.inDestType
      if L4_2 == "object" then
        L3_2.Goal = "MoveTo"
      else
        L4_2 = L2_2.inDestType
        if L4_2 == "coord" then
          L3_2.Goal = "MoveToPos"
          L3_2.Target = nil
          L4_2 = L2_2.inDest
          L3_2.Location = L4_2
        else
        end
      end
    end
    L4_2 = Object
    L4_2 = L4_2.HasLabel
    L5_2 = L2_2.uVehicle
    L6_2 = "helicopter"
    L4_2 = L4_2(L5_2, L6_2)
    L2_2.bIsHeli = L4_2
    L4_2 = L2_2.bIsHeli
    if L4_2 then
      L3_2.Callback = nil
    end
    L4_2 = Ai
    L4_2 = L4_2.Goal
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      L5_2 = Ai
      L5_2 = L5_2.SetHaste
      L6_2 = L2_2.uDriver
      L7_2 = L2_2.inSpeed
      L5_2(L6_2, L7_2)
      L5_2 = L2_2.bIsHeli
      if L5_2 then
        L5_2 = Ai
        L5_2 = L5_2.Goal
        L6_2 = {}
        L7_2 = L2_2.uDriver
        L6_2.AIGuid = L7_2
        L6_2.Goal = "HeliLand"
        L6_2.Priority = "hiPri"
        L7_2 = L2_2._DropCallback
        L6_2.Callback = L7_2
        L7_2 = {}
        L8_2 = L2_2
        L7_2[1] = L8_2
        L6_2.CallbackData = L7_2
        L5_2(L6_2)
      end
    else
      L5_2 = nil
      return L5_2
    end
    L5_2 = Event
    L5_2 = L5_2.Create
    L6_2 = Event
    L6_2 = L6_2.ObjectDeath
    L7_2 = {}
    L8_2 = L2_2.uDriver
    L7_2[1] = L8_2
    L8_2 = Cancel
    L9_2 = {}
    L10_2 = L2_2
    L9_2[1] = L10_2
    L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
    L2_2.eDeath = L5_2
  else
    L4_2 = L2_2
    L3_2 = L2_2.DropCallback
    L3_2(L4_2)
  end
  return L2_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.eDeath
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.eExitDelay
  L1_2(L2_2)
end

Cancel = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Vehicle
  L1_2 = L1_2.GetRiders
  L2_2 = A0_2.uVehicle
  L3_2 = "p"
  L1_2 = L1_2(L2_2, L3_2)
  A0_2.tRiders = L1_2
  L1_2 = Ai
  L1_2 = L1_2.Deploy
  L2_2 = {}
  L3_2 = A0_2.uVehicle
  L2_2.Vehicle = L3_2
  L2_2.Role = "Passenger"
  L2_2.Priority = "HiPri"
  L2_2.Force = true
  L3_2 = A0_2.MaintainRotorSpeed
  L2_2.MaintainRotorSpeed = L3_2
  L3_2 = A0_2._DropCallback2
  L2_2.Callback = L3_2
  L3_2 = {}
  L4_2 = A0_2
  L3_2[1] = L4_2
  L2_2.CallbackData = L3_2
  L1_2(L2_2)
end

_DropCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  A0_2.eExitDelay = nil
  L1_2 = A0_2.bIsHeli
  if L1_2 then
    L1_2 = Ai
    L1_2 = L1_2.Goal
    L2_2 = {}
    L3_2 = A0_2.uDriver
    L2_2.AIGuid = L3_2
    L2_2.Goal = "HeliTakeoff"
    L2_2.Priority = "hiPri"
    L1_2(L2_2)
  end
  L1_2 = A0_2.outDest
  if L1_2 then
    L1_2 = {}
    L2_2 = A0_2.uDriver
    L1_2.AIGuid = L2_2
    L1_2.Priority = "HiPri"
    L2_2 = A0_2.outDest
    L1_2.Target = L2_2
    L1_2.Force = true
    L2_2 = A0_2.outDestType
    if L2_2 == "path" then
      L1_2.Goal = "PathMove"
      L1_2.Start = "first"
    else
      L2_2 = A0_2.outDestType
      if L2_2 == "object" then
        L1_2.Goal = "MoveTo"
      else
        L2_2 = A0_2.outDestType
        if L2_2 == "coord" then
          L1_2.Goal = "MoveToPos"
          L1_2.Target = nil
          L2_2 = A0_2.outDest
          L1_2.Location = L2_2
        else
        end
      end
    end
    L2_2 = Ai
    L2_2 = L2_2.Goal
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L3_2 = Ai
      L3_2 = L3_2.SetHaste
      L4_2 = A0_2.uDriver
      L5_2 = A0_2.outSpeed
      L3_2(L4_2, L5_2)
    else
    end
  end
  L1_2 = _CommandSquad
  L2_2 = A0_2
  L1_2(L2_2)
end

_DropCallback2 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = A0_2.squadName
  if L1_2 then
    L1_2 = Ai
    L1_2 = L1_2.Squad
    L2_2 = {}
    L3_2 = A0_2.squadName
    L2_2.Squad = L3_2
    L2_2.Action = "AddUnits"
    L3_2 = A0_2.tRiders
    L2_2.Guids = L3_2
    L1_2(L2_2)
    L1_2 = Ai
    L1_2 = L1_2.Squad
    L2_2 = {}
    L3_2 = A0_2.squadName
    L2_2.Squad = L3_2
    L2_2.Action = "AddCommand"
    L2_2.Goal = "MoveWithinBoundary"
    L3_2 = {}
    L4_2 = Object
    L4_2 = L4_2.GetPosition
    L5_2 = A0_2.squadTarget
    L4_2, L5_2 = L4_2(L5_2)
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L2_2.Target = L3_2
    L2_2.Radius = 8
    L3_2 = A0_2.squadOrder
    L2_2.Style = L3_2
    L2_2.Priority = "hiPri"
    L1_2 = L1_2(L2_2)
    if L1_2 == 0 then
    end
  end
  L1_2 = A0_2.fDropDoneCallback
  if L1_2 then
    L1_2 = A0_2.fDropDoneCallback
    L2_2 = A0_2.uVehicle
    L3_2 = A0_2.tRiders
    L1_2(L2_2, L3_2)
  end
  A0_2.tRiders = nil
end

_CommandSquad = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 == "string" then
    L1_2 = Pg
    L1_2 = L1_2.GetGuidByName
    L2_2 = A0_2
    return L1_2(L2_2)
  else
    return A0_2
  end
end

_GetGuidIfString = L0_1
