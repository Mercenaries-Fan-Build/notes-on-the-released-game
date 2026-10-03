local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxSupportPickup"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxChiCon001Rescue"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = {}
  L3_2 = setmetatable
  L4_2 = L2_2
  L5_2 = A0_2
  L3_2(L4_2, L5_2)
  A0_2.__index = A0_2
  L3_2 = A0_2.oTarget
  L2_2.oTarget = L3_2
  L3_2 = A0_2.sDeliveryVehicle
  L2_2.sDeliveryVehicle = L3_2
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = A0_2.sDeliveryVehicle
  L3_2 = L3_2(L4_2)
  L2_2.uDeliveryVehicle = L3_2
  L4_2 = L2_2
  L3_2 = L2_2.SetDesignator
  L5_2 = MrxSupportDesignatorSmoke
  L6_2 = L5_2
  L5_2 = L5_2.Create
  L5_2, L6_2 = L5_2(L6_2)
  L3_2(L4_2, L5_2, L6_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetOwner
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.GetDesignator
  L3_2 = L3_2(L4_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetValidationFunction
  L6_2 = MrxSupportDesignator
  L6_2 = L6_2.ValidateLandingZone
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetModuleName
  L6_2 = "MrxChiCon001Rescue"
  L4_2(L5_2, L6_2)
  return L2_2
end

Create = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L0_2 = pairs
  L1_2 = Player
  L1_2 = L1_2.GetAllPlayers
  L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L1_2()
  L0_2, L1_2, L2_2 = L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = MrxGui
    L5_2 = L5_2.GetWidgetByNameAndOwner
    L6_2 = "Support Menu"
    L7_2 = L4_2
    L5_2 = L5_2(L6_2, L7_2)
    if L5_2 then
      L7_2 = L5_2
      L6_2 = L5_2.AddItem
      L8_2 = {}
      L8_2.sName = "Rescue Copter"
      L8_2.sIcon = "vehicles_helir_uh1"
      L9_2 = MrxChiCon001Rescue
      L10_2 = L9_2
      L9_2 = L9_2.Create
      L11_2 = L4_2
      L9_2 = L9_2(L10_2, L11_2)
      L8_2.oSupport = L9_2
      L6_2(L7_2, L8_2)
    end
  end
end

AddSupport = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = ipairs
  L1_2 = Player
  L1_2 = L1_2.GetAllPlayers
  L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L1_2()
  L0_2, L1_2, L2_2 = L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = MrxGui
    L5_2 = L5_2.GetWidgetByNameAndOwner
    L6_2 = "Support Menu"
    L7_2 = L4_2
    L5_2 = L5_2(L6_2, L7_2)
    if L5_2 then
      L7_2 = L5_2
      L6_2 = L5_2.RemoveItem
      L8_2 = "Rescue Copter"
      L6_2(L7_2, L8_2)
    end
  end
end

RemoveSupport = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L1_2 = A0_2.oDesignator
  L2_2 = L1_2
  L1_2 = L1_2.GetTarget
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  L4_2 = Pg
  L4_2 = L4_2.FindPointFromCamera
  L5_2 = -150
  L6_2 = nAltitude
  L7_2 = -1
  L8_2 = A0_2.uOwner
  L4_2, L5_2, L6_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  if L2_2 then
    L7_2 = nAltitude
    L7_2 = L2_2 + L7_2
    if L5_2 < L7_2 then
      L7_2 = nAltitude
      L5_2 = L2_2 + L7_2
    end
  end
  L7_2 = Pg
  L7_2 = L7_2.Spawn
  L8_2 = A0_2.uDeliveryVehicle
  L9_2 = L4_2
  L10_2 = L5_2
  L11_2 = L6_2
  L12_2 = 0
  L13_2 = false
  L14_2 = true
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  if not L7_2 then
    return
  end
  L8_2 = Object
  L8_2 = L8_2.GetPosition
  L9_2 = L7_2
  L8_2, L9_2, L10_2 = L8_2(L9_2)
  L11_2 = A0_2.oDesignator
  L12_2 = L11_2
  L11_2 = L11_2.GetTarget
  L11_2, L12_2, L13_2 = L11_2(L12_2)
  L14_2 = Math
  L14_2 = L14_2.GetXZHeading
  L15_2 = L11_2 - L8_2
  L16_2 = L12_2 - L9_2
  L17_2 = L13_2 - L10_2
  L14_2 = L14_2(L15_2, L16_2, L17_2)
  L15_2 = Object
  L15_2 = L15_2.SetYaw
  L16_2 = L7_2
  L17_2 = L14_2
  L15_2(L16_2, L17_2)
  L15_2 = MrxVoSequence
  L15_2 = L15_2.Start
  L16_2 = "Ewan-None-Freeplay-Support-28"
  L17_2 = nil
  L18_2 = MrxVoSequence
  L18_2 = L18_2.knPriorityFreeplay
  L15_2(L16_2, L17_2, L18_2)
  L15_2 = Event
  L15_2 = L15_2.Create
  L16_2 = Event
  L16_2 = L16_2.TimerRelative
  L17_2 = {}
  L18_2 = 2
  L17_2[1] = L18_2
  L18_2 = _WaitCallback
  L19_2 = {}
  L20_2 = A0_2
  L21_2 = L7_2
  L19_2[1] = L20_2
  L19_2[2] = L21_2
  L15_2(L16_2, L17_2, L18_2, L19_2)
end

DesignationCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2.oDesignator
  L3_2 = L2_2
  L2_2 = L2_2.GetTarget
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L5_2 = Ai
  L5_2 = L5_2.Goal
  L6_2 = {}
  L7_2 = Vehicle
  L7_2 = L7_2.GetDriver
  L8_2 = A1_2
  L7_2 = L7_2(L8_2)
  L6_2.AIGuid = L7_2
  L6_2.Goal = "HeliLand"
  L7_2 = {}
  L8_2 = L2_2
  L9_2 = L3_2
  L10_2 = L4_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L6_2.Location = L7_2
  L6_2.Priority = "hiPri"
  L6_2.Force = true
  L7_2 = _VehicleLanded
  L6_2.Callback = L7_2
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A1_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L6_2.CallbackData = L7_2
  L5_2(L6_2)
end

_WaitCallback = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  if A3_2 == 0 then
    L4_2 = MrxSupport
    L4_2 = L4_2.DenialMessage
    L5_2 = "abortnodrop"
    L4_2(L5_2)
    L4_2 = GoHome
    L5_2 = A0_2
    L6_2 = A1_2
    L7_2 = A2_2
    L4_2(L5_2, L6_2, L7_2)
    return
  end
  L4_2 = Ai
  L4_2 = L4_2.Role
  L5_2 = {}
  L5_2.AIGuid = A2_2
  L5_2.Role = "Idle"
  L5_2.Priority = "hiPri"
  L4_2(L5_2)
  L4_2 = Object
  L4_2 = L4_2.GetPosition
  L5_2 = A1_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  L7_2 = Pg
  L7_2 = L7_2.FastCollectHumans
  L8_2 = L4_2
  L9_2 = L5_2
  L10_2 = L6_2
  L11_2 = 60
  L12_2 = "Prisoner"
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L8_2 = table
  L8_2 = L8_2.getn
  L9_2 = L7_2
  L8_2 = L8_2(L9_2)
  if L8_2 and 1 <= L8_2 then
    L9_2 = ipairs
    L10_2 = L7_2
    L9_2, L10_2, L11_2 = L9_2(L10_2)
    for L12_2, L13_2 in L9_2, L10_2, L11_2 do
      L14_2 = Ai
      L14_2 = L14_2.Role
      L15_2 = {}
      L15_2.AIGuid = L13_2
      L15_2.Role = "Idle"
      L15_2.Priority = "loPri"
      L14_2(L15_2)
      L14_2 = Ai
      L14_2 = L14_2.Goal
      L15_2 = {}
      L15_2.AIGuid = L13_2
      L15_2.Goal = "Enter"
      L15_2.Target = A1_2
      L15_2.Role = "Passenger"
      L15_2.Priority = "hiPri"
      L14_2 = L14_2(L15_2)
      a = L14_2
    end
  end
  L9_2 = Event
  L9_2 = L9_2.Create
  L10_2 = Event
  L10_2 = L10_2.ObjectInSeat
  L11_2 = {}
  L12_2 = "Prisoner"
  L13_2 = A1_2
  L14_2 = "Any"
  L15_2 = "Enter"
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L11_2[3] = L14_2
  L11_2[4] = L15_2
  L12_2 = GoHome
  L13_2 = {}
  L14_2 = A0_2
  L15_2 = A1_2
  L16_2 = A2_2
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L13_2[3] = L16_2
  L9_2(L10_2, L11_2, L12_2, L13_2)
end

_VehicleLanded = L0_1
