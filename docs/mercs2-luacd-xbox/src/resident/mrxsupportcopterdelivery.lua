local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorSmoke"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
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
  L3_2 = A0_2.sFinalDestination
  L2_2.sFinalDestination = L3_2
  L4_2 = L2_2
  L3_2 = L2_2.SetRecruit
  L5_2 = "Copter"
  L3_2(L4_2, L5_2)
  L3_2 = MrxSupportDesignatorSmoke
  L4_2 = L3_2
  L3_2 = L3_2.Create
  L3_2 = L3_2(L4_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetAATestLevel
  L6_2 = "none"
  L4_2(L5_2, L6_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetSmokeColor
  L6_2 = "blue"
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetDesignator
  L6_2 = L3_2
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetOwner
  L6_2 = A1_2
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetModuleName
  L6_2 = "MrxSupportCopterDelivery"
  L4_2(L5_2, L6_2)
  return L2_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L1_2 = Net
  L1_2 = L1_2.IsClient
  L1_2 = L1_2()
  if L1_2 then
    return
  end
  L1_2 = A0_2.oDesignator
  L2_2 = L1_2
  L1_2 = L1_2.GetTarget
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  L4_2 = Pg
  L4_2 = L4_2.FindPointFromCamera
  L5_2 = -150
  L6_2 = MrxSupport
  L6_2 = L6_2.GetSpawnHeight
  L6_2 = L6_2()
  L7_2 = -1
  L8_2 = A0_2.uOwner
  L9_2 = math
  L9_2 = L9_2.randi
  L10_2 = 120
  L9_2 = L9_2(L10_2)
  L9_2 = 300 + L9_2
  L4_2, L5_2, L6_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
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
  L16_2 = "Ewan-None-Freeplay-Support-10"
  L17_2 = nil
  L18_2 = MrxVoSequence
  L18_2 = L18_2.knPriorityFreeplay
  L15_2(L16_2, L17_2, L18_2)
  L15_2 = Event
  L15_2 = L15_2.Create
  L16_2 = Event
  L16_2 = L16_2.ObjectHibernation
  L17_2 = {}
  L18_2 = L7_2
  L19_2 = "awake"
  L17_2[1] = L18_2
  L17_2[2] = L19_2
  L18_2 = _HeliReady
  L19_2 = {}
  L20_2 = A0_2
  L21_2 = L7_2
  L19_2[1] = L20_2
  L19_2[2] = L21_2
  L15_2(L16_2, L17_2, L18_2, L19_2)
end

DesignationCallback = L0_1

function L0_1(A0_2, A1_2)
end

_WaitCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = Object
  L2_2 = L2_2.AddToDisposer
  L3_2 = A1_2
  L4_2 = "Vehicle"
  L2_2(L3_2, L4_2)
  L2_2 = A0_2.oDesignator
  L3_2 = L2_2
  L2_2 = L2_2.GetTarget
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L5_2 = MrxSupport
  L5_2 = L5_2.SetupDamageEvent
  L6_2 = A0_2
  L7_2 = A1_2
  L8_2 = false
  L5_2 = L5_2(L6_2, L7_2, L8_2)
  A0_2.DamageEvent = L5_2
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
  L9_2 = L3_2 + 50
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
  L5_2 = L5_2(L6_2)
  A0_2.LandGoal = L5_2
end

_HeliReady = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" ~= L2_2 then
    return
  end
  A0_2.oFinalDestination = A1_2
end

SetFinalDestination = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L4_2 = Vehicle
  L4_2 = L4_2.SetCanPlayerUse
  L5_2 = A1_2
  L6_2 = "d"
  L7_2 = true
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = Event
  L4_2 = L4_2.Delete
  L5_2 = A0_2.DamageEvent
  L4_2(L5_2)
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
    L5_2 = A0_2
    L4_2 = A0_2.RefundCosts
    L4_2(L5_2)
    return
  end
  L4_2 = A0_2.DamageEvent
  if L4_2 then
    L4_2 = Event
    L4_2 = L4_2.Delete
    L5_2 = A0_2.DamageEvent
    L4_2(L5_2)
    A0_2.DamageEvent = nil
  end
  L4_2 = Vehicle
  L4_2 = L4_2.Exit
  L5_2 = A1_2
  L6_2 = A2_2
  L7_2 = false
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.ObjectInSeat
  L6_2 = {}
  L7_2 = A2_2
  L8_2 = A1_2
  L9_2 = "D"
  L10_2 = "X"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L7_2 = ExitedVehicle
  L8_2 = {}
  L9_2 = A0_2
  L10_2 = A2_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
end

_VehicleLanded = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = {}
  L3_2 = "Ewan-In-Mission-Contract-Pmc03-128"
  L4_2 = "Ewan.Misc.DeliverHeli01"
  L5_2 = "Ewan.Misc.DeliverHeli02"
  L6_2 = "Ewan.Misc.DeliverHeli03"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L3_2 = Object
  L3_2 = L3_2.GetPosition
  L4_2 = A1_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  L6_2 = Ai
  L6_2 = L6_2.Goal
  L7_2 = {}
  L7_2.AIGuid = A1_2
  L7_2.Goal = "MoveTo"
  L7_2.Haste = 0.2
  L8_2 = {}
  L9_2 = L3_2 - 10
  L10_2 = L4_2
  L11_2 = L5_2 - 10
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L7_2.Location = L8_2
  L7_2.Priority = "hiPri"
  L8_2 = Object
  L8_2 = L8_2.FadeOut
  L7_2.Callback = L8_2
  L8_2 = {}
  L9_2 = A1_2
  L10_2 = 1
  L11_2 = true
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L7_2.CallbackData = L8_2
  L7_2.Force = true
  L6_2 = L6_2(L7_2)
  uGoal = L6_2
  L6_2 = MrxUtil
  L6_2 = L6_2.GetRandomTableElement
  L7_2 = L2_2
  L6_2 = L6_2(L7_2)
  L7_2 = MrxVoSequence
  L7_2 = L7_2.Start
  L8_2 = L6_2
  L9_2 = nil
  L10_2 = MrxVoSequence
  L10_2 = L10_2.knPriorityFreeplay
  L7_2(L8_2, L9_2, L10_2)
  L7_2 = Event
  L7_2 = L7_2.Create
  L8_2 = Event
  L8_2 = L8_2.ObjectHibernation
  L9_2 = {}
  L10_2 = A1_2
  L11_2 = "Hibernated"
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L10_2 = Object
  L10_2 = L10_2.Remove
  L11_2 = {}
  L12_2 = A1_2
  L11_2[1] = L12_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
  A0_2.Hibernation = L7_2
  L7_2 = Event
  L7_2 = L7_2.Create
  L8_2 = Event
  L8_2 = L8_2.ObjectDelete
  L9_2 = {}
  L10_2 = A1_2
  L9_2[1] = L10_2
  L10_2 = MrxSupportManager
  L10_2 = L10_2.MakeRecruitAvailable
  L11_2 = {}
  L12_2 = "Copter"
  L11_2[1] = L12_2
  L7_2(L8_2, L9_2, L10_2, L11_2)
  L7_2 = Event
  L7_2 = L7_2.CreatePersistent
  L8_2 = Event
  L8_2 = L8_2.TimerRelative
  L9_2 = {}
  L10_2 = 3
  L9_2[1] = L10_2
  L10_2 = CheckEwan
  L11_2 = {}
  L12_2 = A0_2
  L13_2 = A1_2
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
  A0_2.Timer = L7_2
end

ExitedVehicle = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = Object
  L2_2 = L2_2.IsVisible
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L2_2 = Object
    L2_2 = L2_2.Remove
    L3_2 = A1_2
    L2_2(L3_2)
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = A0_2.Timer
    L2_2(L3_2)
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = A0_2.Hibernation
    L2_2(L3_2)
  end
end

CheckEwan = L0_1
