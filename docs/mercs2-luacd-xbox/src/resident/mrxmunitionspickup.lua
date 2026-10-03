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
L1_1 = "Munitions"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = "UH1 Transport (PMC) (Driver)"
sDeliveryVehicle = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
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
  L2_2.oUpdateEvent = nil
  L3_2 = MrxSupportDesignatorSmoke
  L4_2 = L3_2
  L3_2 = L3_2.Create
  L3_2 = L3_2(L4_2)
  oDesignator = L3_2
  L3_2 = oDesignator
  L4_2 = L3_2
  L3_2 = L3_2.SetValidationFunction
  L5_2 = nil
  L3_2(L4_2, L5_2)
  L3_2 = oDesignator
  L4_2 = L3_2
  L3_2 = L3_2.SetSmokeColor
  L5_2 = "green"
  L3_2(L4_2, L5_2)
  L3_2 = oDesignator
  L4_2 = L3_2
  L3_2 = L3_2.SetAATestLevel
  L5_2 = "none"
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetDesignator
  L5_2 = oDesignator
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetOwner
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetModuleName
  L5_2 = "MrxMunitionsPickup"
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetRecruit
  L5_2 = "Copter"
  L3_2(L4_2, L5_2)
  return L2_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = _DesignatorCallback
  L2_2 = A0_2
  L1_2(L2_2)
end

DesignationCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" ~= L2_2 then
    return
  end
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if "string" ~= L2_2 then
    return
  end
  A0_2.sDeliveryVehicle = A1_2
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  A0_2.uDeliveryVehicle = L2_2
end

SetDeliveryVehicle = L0_1

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

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2
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
  L4_2, L5_2, L6_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  if L2_2 then
    L7_2 = MrxSupport
    L7_2 = L7_2.GetSpawnHeight
    L7_2 = L7_2()
    L7_2 = L2_2 + L7_2
    if L5_2 < L7_2 then
      L7_2 = MrxSupport
      L7_2 = L7_2.GetSpawnHeight
      L7_2 = L7_2()
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
  L15_2 = Event
  L15_2 = L15_2.Create
  L16_2 = Event
  L16_2 = L16_2.ObjectHibernation
  L17_2 = {}
  L18_2 = L7_2
  L19_2 = "awake"
  L17_2[1] = L18_2
  L17_2[2] = L19_2
  L18_2 = _WaitCallback
  L19_2 = {}
  L20_2 = A0_2
  L21_2 = L7_2
  L22_2 = L11_2
  L23_2 = L12_2
  L24_2 = L13_2
  L19_2[1] = L20_2
  L19_2[2] = L21_2
  L19_2[3] = L22_2
  L19_2[4] = L23_2
  L19_2[5] = L24_2
  L15_2(L16_2, L17_2, L18_2, L19_2)
end

_DesignatorCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = true
  bPickupInProgress = L2_2
  L2_2 = {}
  L3_2 = "Ewan.Support.Munitions01"
  L4_2 = "Ewan.Support.Munitions02"
  L5_2 = "Ewan.Support.Munitions03"
  L6_2 = "Fiona.Support.Munitions01"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L3_2 = MrxVoSequence
  L3_2 = L3_2.Start
  L4_2 = MrxUtil
  L4_2 = L4_2.GetRandomTableElement
  L5_2 = L2_2
  L4_2 = L4_2(L5_2)
  L5_2 = nil
  L6_2 = MrxVoSequence
  L6_2 = L6_2.knPriorityFreeplay
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = MrxSupport
  L3_2 = L3_2.SetupDamageEvent
  L4_2 = A0_2
  L5_2 = A1_2
  L6_2 = false
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ScriptEvent
  L5_2 = {}
  L6_2 = "NoMunitions"
  
  function L7_2()
    local L0_3, L1_3
    L0_3 = true
    return L0_3
  end
  
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  
  function L6_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = MrxSupport
    L0_3 = L0_3.Abort
    L1_3 = A0_2
    L2_3 = A1_2
    L3_3 = "NoMunitions"
    L0_3(L1_3, L2_3, L3_3)
  end
  
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  A0_2.oNoMunitionsScriptEvent = L3_2
  L3_2 = PickMunitionsTarget
  L4_2 = A0_2
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
end

_WaitCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = Object
  L2_2 = L2_2.DetachCargoFromWinch
  L3_2 = A1_2
  L2_2(L3_2)
  L2_2 = Munitions
  L2_2 = L2_2.GetTaggedMunition
  L2_2 = L2_2()
  A0_2.pu = L2_2
  L2_2 = A0_2.pu
  if not L2_2 then
    L2_2 = MrxSupport
    L2_2 = L2_2.Abort
    L3_2 = A0_2
    L4_2 = A1_2
    L5_2 = "NoMunitions"
    L2_2(L3_2, L4_2, L5_2)
    return
  end
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = A0_2.pu
  L4_2[1] = L5_2
  L5_2 = PickMunitionsTarget
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = A1_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  A0_2.oMunitionsKilledEvent = L2_2
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = A0_2.pu
  L6_2 = "hibernated"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = PickMunitionsTarget
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = A1_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  A0_2.oMunitionsSleepEvent = L2_2
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "UntagMunitions"
  
  function L6_2(A0_3)
    local L1_3, L2_3
    L1_3 = A0_3[1]
    L2_3 = A0_2
    L2_3 = L2_3.pu
    L1_3 = L1_3 == L2_3
    return L1_3
  end
  
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = PickMunitionsTarget
    L1_3 = A0_2
    L2_3 = A1_2
    L0_3(L1_3, L2_3)
  end
  
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  A0_2.oUntagScriptEvent = L2_2
  L2_2 = Ai
  L2_2 = L2_2.Goal
  L3_2 = {}
  L4_2 = Vehicle
  L4_2 = L4_2.GetDriver
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  L3_2.AIGuid = L4_2
  L3_2.Goal = "Pickup"
  L4_2 = A0_2.pu
  L3_2.Target = L4_2
  L3_2.Priority = "hiPri"
  L4_2 = Pickup
  L3_2.Callback = L4_2
  L3_2.Force = true
  L4_2 = {}
  L5_2 = A0_2
  L6_2 = A1_2
  L7_2 = Vehicle
  L7_2 = L7_2.GetDriver
  L8_2 = A1_2
  L7_2 = L7_2(L8_2)
  L8_2 = A0_2.pu
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L3_2.CallbackData = L4_2
  L2_2(L3_2)
  L2_2 = {}
  L2_2.self = A0_2
  L2_2.uHeli = A1_2
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L2_2.AIGuid = L3_2
  L3_2 = A0_2.pu
  L2_2.Target = L3_2
  tImmediatePickupData = L2_2
end

PickMunitionsTarget = L0_1
L0_1 = false
bPickupInProgress = L0_1
L0_1 = {}
tImmediatePickupData = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = bPickupInProgress
  if L0_2 then
    L0_2 = Munitions
    L0_2 = L0_2.GetTaggedMunition
    L0_2 = L0_2()
    if L0_2 then
      goto lbl_10
    end
  end
  do return end
  ::lbl_10::
  L0_2 = Munitions
  L0_2 = L0_2.PickupAllMunitions
  L0_2()
  L0_2 = tImmediatePickupData
  L0_2 = L0_2.self
  L0_2 = L0_2.oNoMunitionsScriptEvent
  if L0_2 then
    L0_2 = Event
    L0_2 = L0_2.Delete
    L1_2 = tImmediatePickupData
    L1_2 = L1_2.self
    L1_2 = L1_2.oNoMunitionsScriptEvent
    L0_2(L1_2)
    L0_2 = tImmediatePickupData
    L0_2 = L0_2.self
    L0_2.oNoMunitionsScriptEvent = nil
  end
  L0_2 = tImmediatePickupData
  L0_2 = L0_2.self
  L0_2 = L0_2.oMunitionsKilledEvent
  if L0_2 then
    L0_2 = Event
    L0_2 = L0_2.Delete
    L1_2 = tImmediatePickupData
    L1_2 = L1_2.self
    L1_2 = L1_2.oMunitionsKilledEvent
    L0_2(L1_2)
    L0_2 = tImmediatePickupData
    L0_2 = L0_2.self
    L0_2.oMunitionsKilledEvent = nil
  end
  L0_2 = tImmediatePickupData
  L0_2 = L0_2.self
  L0_2 = L0_2.oUntagScriptEvent
  if L0_2 then
    L0_2 = Event
    L0_2 = L0_2.Delete
    L1_2 = tImmediatePickupData
    L1_2 = L1_2.self
    L1_2 = L1_2.oUntagScriptEvent
    L0_2(L1_2)
    L0_2 = tImmediatePickupData
    L0_2 = L0_2.self
    L0_2.oUntagScriptEvent = nil
  end
  L0_2 = tImmediatePickupData
  L0_2 = L0_2.self
  L0_2 = L0_2.oMunitionsSleepEvent
  if L0_2 then
    L0_2 = Event
    L0_2 = L0_2.Delete
    L1_2 = tImmediatePickupData
    L1_2 = L1_2.self
    L1_2 = L1_2.oMunitionsSleepEvent
    L0_2(L1_2)
    L0_2 = tImmediatePickupData
    L0_2 = L0_2.self
    L0_2.oMunitionsSleepEvent = nil
  end
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.ObjectHibernation
  L2_2 = {}
  L3_2 = tImmediatePickupData
  L3_2 = L3_2.uHeli
  L4_2 = "hibernated"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = Object
  L3_2 = L3_2.Remove
  L4_2 = {}
  L5_2 = tImmediatePickupData
  L5_2 = L5_2.uHeli
  L4_2[1] = L5_2
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.ObjectDelete
  L2_2 = {}
  L3_2 = tImmediatePickupData
  L3_2 = L3_2.uHeli
  L2_2[1] = L3_2
  L3_2 = MrxSupportManager
  L3_2 = L3_2.MakeRecruitAvailable
  L4_2 = {}
  L5_2 = "Copter"
  L4_2[1] = L5_2
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = Object
  L0_2 = L0_2.FadeOut
  L1_2 = tImmediatePickupData
  L1_2 = L1_2.uHeli
  L2_2 = 0.1
  L3_2 = true
  L0_2(L1_2, L2_2, L3_2)
  L0_2 = Object
  L0_2 = L0_2.IsWinched
  L1_2 = tImmediatePickupData
  L1_2 = L1_2.Target
  L0_2 = L0_2(L1_2)
  if L0_2 then
    L0_2 = Object
    L0_2 = L0_2.FadeOut
    L1_2 = tImmediatePickupData
    L1_2 = L1_2.Target
    L2_2 = 0.1
    L3_2 = true
    L0_2(L1_2, L2_2, L3_2)
  end
  L0_2 = tImmediatePickupData
  L0_2 = L0_2.self
  L0_2.bSupportComplete = true
  L0_2 = {}
  tImmediatePickupData = L0_2
  L0_2 = false
  bPickupInProgress = L0_2
end

ImmediatePickup = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2
  if A4_2 == 0 then
    L5_2 = Object
    L5_2 = L5_2.DetachCargoFromWinch
    L6_2 = A1_2
    L5_2(L6_2)
    L5_2 = MrxSupport
    L5_2 = L5_2.GoHome
    L6_2 = A0_2
    L7_2 = A1_2
    L5_2(L6_2, L7_2)
  end
  L5_2 = A0_2.oNoMunitionsScriptEvent
  if L5_2 then
    L5_2 = Event
    L5_2 = L5_2.Delete
    L6_2 = A0_2.oNoMunitionsScriptEvent
    L5_2(L6_2)
    A0_2.oNoMunitionsScriptEvent = nil
  end
  L5_2 = A0_2.oUntagScriptEvent
  if L5_2 then
    L5_2 = Event
    L5_2 = L5_2.Delete
    L6_2 = A0_2.oUntagScriptEvent
    L5_2(L6_2)
    A0_2.oUntagScriptEvent = nil
  end
  L5_2 = A0_2.oMunitionsKilledEvent
  if L5_2 then
    L5_2 = Event
    L5_2 = L5_2.Delete
    L6_2 = A0_2.oMunitionsKilledEvent
    L5_2(L6_2)
    A0_2.oMunitionsKilledEvent = nil
  end
  L5_2 = A0_2.oMunitionsSleepEvent
  if L5_2 then
    L5_2 = Event
    L5_2 = L5_2.Delete
    L6_2 = A0_2.oMunitionsSleepEvent
    L5_2(L6_2)
    A0_2.oMunitionsSleepEvent = nil
  end
  L5_2 = nil
  L6_2 = MrxUtil
  L6_2 = L6_2.GetFaction
  L7_2 = A3_2
  L6_2 = L6_2(L7_2)
  if L6_2 then
    L6_2 = Pg
    L6_2 = L6_2.GetGuidByName
    L7_2 = MrxUtil
    L7_2 = L7_2.GetFaction
    L8_2 = A3_2
    L7_2, L8_2, L9_2 = L7_2(L8_2)
    L6_2 = L6_2(L7_2, L8_2, L9_2)
    L5_2 = L6_2
  end
  if L5_2 then
    L6_2 = Ai
    L6_2 = L6_2.AddInfraction
    L7_2 = Player
    L7_2 = L7_2.GetPrimaryCharacter
    L7_2 = L7_2()
    L8_2 = L5_2
    L9_2 = 5
    L6_2(L7_2, L8_2, L9_2)
    L6_2 = Player
    L6_2 = L6_2.GetSecondaryCharacter
    L6_2 = L6_2()
    if L6_2 then
      L6_2 = Ai
      L6_2 = L6_2.AddInfraction
      L7_2 = Player
      L7_2 = L7_2.GetSecondaryCharacter
      L7_2 = L7_2()
      L8_2 = L5_2
      L9_2 = 5
      L6_2(L7_2, L8_2, L9_2)
    else
    end
  end
  L6_2 = Munitions
  L6_2 = L6_2.PickupAllMunitions
  L6_2()
  L6_2 = {}
  tImmediatePickupData = L6_2
  L6_2 = false
  bPickupInProgress = L6_2
  L6_2 = MrxSupport
  L6_2 = L6_2.GoHome
  L7_2 = A0_2
  L8_2 = A1_2
  L9_2 = A3_2
  L6_2(L7_2, L8_2, L9_2)
end

Pickup = L0_1
