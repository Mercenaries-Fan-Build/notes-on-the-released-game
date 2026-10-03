local L0_1, L1_1, L2_1, L3_1
L0_1 = inherit
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorSmoke"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorFlare"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTransit"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxState"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifPmcInterior"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)
L0_1 = "UH1 Transport (Transit)"
sDeliveryVehicle = L0_1
L0_1 = 250
nAltitude = L0_1
L0_1 = {}
L1_1 = "Ewan-None-Freeplay-Support-73"
L2_1 = "Ewan-None-Freeplay-Support-38"
L3_1 = "Ewan-None-Freeplay-Support-89"
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L1_1 = {}
L2_1 = "Ewan-None-Freeplay-Support-90"
L3_1 = "Ewan-None-Freeplay-Support-99"
L1_1[1] = L2_1
L1_1[2] = L3_1
L2_1 = false
bTransitInterfaceActive = L2_1

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = {}
  L3_2 = setmetatable
  L4_2 = L2_2
  L5_2 = A0_2
  L3_2(L4_2, L5_2)
  A0_2.__index = A0_2
  L3_2 = MrxSupportDesignatorSmoke
  L4_2 = L3_2
  L3_2 = L3_2.Create
  L3_2 = L3_2(L4_2)
  oDesignator = L3_2
  L3_2 = oDesignator
  L4_2 = L3_2
  L3_2 = L3_2.SetSmokeColor
  L5_2 = "blue"
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
  L3_2 = L2_2.SetRecruit
  L5_2 = "Copter"
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetModuleName
  L5_2 = "MrxSupportTransit"
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetPickupVehicle
  L5_2 = A0_2.sDeliveryVehicle
  L3_2(L4_2, L5_2)
  L2_2.bUnrestrictedByFuel = true
  return L2_2
end

Create = L2_1

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L3_2 = type
  L5_2 = A0_2
  L4_2 = A0_2.GetOwner
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  if "userdata" == L3_2 then
    L3_2 = Player
    L3_2 = L3_2.GetCharacter
    L5_2 = A0_2
    L4_2 = A0_2.GetOwner
    L4_2, L5_2, L6_2 = L4_2(L5_2)
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2 = L3_2
  end
  L3_2 = Human
  L3_2 = L3_2.IsSwimming
  if L3_2 and L2_2 then
    L3_2 = Human
    L3_2 = L3_2.IsSwimming
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L4_2 = A0_2
      L3_2 = A0_2.SetDesignator
      L5_2 = MrxSupportDesignatorFlare
      L6_2 = L5_2
      L5_2 = L5_2.Create
      L5_2, L6_2 = L5_2(L6_2)
      L3_2(L4_2, L5_2, L6_2)
    end
  end
  L3_2 = MrxSupport
  L3_2 = L3_2.Commence
  L4_2 = A0_2
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
end

Commence = L2_1

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2
  L1_2 = Net
  L1_2 = L1_2.IsClient
  L1_2 = L1_2()
  if L1_2 then
    return
  end
  L1_2 = MrxTransit
  L1_2 = L1_2.IsSystemInitialized
  L1_2 = L1_2()
  if not L1_2 then
    L1_2 = MrxTransit
    L1_2 = L1_2.Reset
    L1_2()
  end
  L1_2 = MrxTransit
  L1_2 = L1_2.IsSystemEnabled
  L1_2 = L1_2()
  if not L1_2 then
    L1_2 = false
    return L1_2
  end
  L1_2 = nil
  L2_2 = type
  L4_2 = A0_2
  L3_2 = A0_2.GetOwner
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2)
  if "userdata" == L2_2 then
    L2_2 = Player
    L2_2 = L2_2.GetCharacter
    L4_2 = A0_2
    L3_2 = A0_2.GetOwner
    L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2 = L3_2(L4_2)
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2)
    L1_2 = L2_2
  end
  A0_2.bWaterPickup = false
  if L1_2 then
    L2_2 = Human
    L2_2 = L2_2.IsSwimming
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    if L2_2 then
      A0_2.bWaterPickup = true
    end
  end
  L2_2 = A0_2.oDesignator
  L3_2 = L2_2
  L2_2 = L2_2.GetTarget
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L5_2 = Pg
  L5_2 = L5_2.FindPointFromCamera
  L6_2 = -150
  L7_2 = MrxSupport
  L7_2 = L7_2.GetSpawnHeight
  L7_2 = L7_2()
  L8_2 = 30
  L9_2 = A0_2.uOwner
  L5_2, L6_2, L7_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  if L3_2 then
    L8_2 = MrxSupport
    L8_2 = L8_2.GetSpawnHeight
    L8_2 = L8_2()
    L8_2 = L3_2 + L8_2
    if L6_2 < L8_2 then
      L8_2 = MrxSupport
      L8_2 = L8_2.GetSpawnHeight
      L8_2 = L8_2()
      L6_2 = L3_2 + L8_2
    end
  end
  L8_2 = Pg
  L8_2 = L8_2.Spawn
  L9_2 = A0_2.uDeliveryVehicle
  L10_2 = L5_2
  L11_2 = L6_2
  L12_2 = L7_2
  L13_2 = 0
  L14_2 = false
  L15_2 = true
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  if not L8_2 then
    return
  end
  L9_2 = Object
  L9_2 = L9_2.GetPosition
  L10_2 = L8_2
  L9_2, L10_2, L11_2 = L9_2(L10_2)
  L12_2 = A0_2.oDesignator
  L13_2 = L12_2
  L12_2 = L12_2.GetTarget
  L12_2, L13_2, L14_2 = L12_2(L13_2)
  L15_2 = Math
  L15_2 = L15_2.GetXZHeading
  L16_2 = L12_2 - L9_2
  L17_2 = L13_2 - L10_2
  L18_2 = L14_2 - L11_2
  L15_2 = L15_2(L16_2, L17_2, L18_2)
  L16_2 = Object
  L16_2 = L16_2.SetYaw
  L17_2 = L8_2
  L18_2 = L15_2
  L16_2(L17_2, L18_2)
  L16_2 = MrxSupport
  L16_2 = L16_2.PlayRandomVOCue
  L17_2 = L0_1
  L16_2(L17_2)
  L16_2 = Event
  L16_2 = L16_2.Create
  L17_2 = Event
  L17_2 = L17_2.ObjectHibernation
  L18_2 = {}
  L19_2 = L8_2
  L20_2 = "awake"
  L18_2[1] = L19_2
  L18_2[2] = L20_2
  L19_2 = _WaitCallback
  L20_2 = {}
  L21_2 = A0_2
  L22_2 = L8_2
  L20_2[1] = L21_2
  L20_2[2] = L22_2
  L16_2(L17_2, L18_2, L19_2, L20_2)
end

DesignationCallback = L2_1

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = A0_2.oDesignator
  L3_2 = L2_2
  L2_2 = L2_2.GetTarget
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L5_2 = Vehicle
  L5_2 = L5_2.GetDriver
  L6_2 = A1_2
  L5_2 = L5_2(L6_2)
  L6_2 = MrxSupport
  L6_2 = L6_2.SetupDamageEvent
  L7_2 = A0_2
  L8_2 = A1_2
  L9_2 = false
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  A0_2.eAbort = L6_2
  L6_2 = A0_2.bWaterPickup
  if L6_2 then
    L6_2 = Ai
    L6_2 = L6_2.Goal
    L7_2 = {}
    L8_2 = Vehicle
    L8_2 = L8_2.GetDriver
    L9_2 = A1_2
    L8_2 = L8_2(L9_2)
    L7_2.AIGuid = L8_2
    L7_2.Goal = "MoveTo"
    L8_2 = {}
    L9_2 = L2_2
    L10_2 = L3_2
    L11_2 = L4_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L7_2.Location = L8_2
    L7_2.Priority = "hiPri"
    L7_2.Force = true
    L8_2 = _OpenTransitInterface
    L7_2.Callback = L8_2
    L8_2 = {}
    L9_2 = A0_2
    L10_2 = A1_2
    L11_2 = L5_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L7_2.CallbackData = L8_2
    L6_2(L7_2)
  else
    L6_2 = Ai
    L6_2 = L6_2.Goal
    L7_2 = {}
    L8_2 = Vehicle
    L8_2 = L8_2.GetDriver
    L9_2 = A1_2
    L8_2 = L8_2(L9_2)
    L7_2.AIGuid = L8_2
    L7_2.Goal = "HeliLand"
    L8_2 = {}
    L9_2 = L2_2
    L10_2 = L3_2
    L11_2 = L4_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L7_2.Location = L8_2
    L7_2.Priority = "hiPri"
    L7_2.Force = true
    L8_2 = _VehicleLanded
    L7_2.Callback = L8_2
    L8_2 = {}
    L9_2 = A0_2
    L10_2 = A1_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L7_2.CallbackData = L8_2
    L6_2(L7_2)
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
    L9_2 = _OpenTransitInterface
    L10_2 = {}
    L11_2 = A0_2
    L12_2 = A1_2
    L13_2 = L5_2
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L10_2[3] = L13_2
    L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
    A0_2.EnterEvent = L6_2
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
    L12_2 = "x"
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L8_2[4] = L12_2
    L9_2 = _PlayerExited
    L10_2 = {}
    L11_2 = A0_2
    L12_2 = A1_2
    L13_2 = L5_2
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L10_2[3] = L13_2
    L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
    A0_2.ExitEvent = L6_2
  end
  L6_2 = Event
  L6_2 = L6_2.Create
  L7_2 = Event
  L7_2 = L7_2.ObjectDeath
  L8_2 = {}
  L9_2 = A1_2
  L8_2[1] = L9_2
  L9_2 = _HandleDeath
  L10_2 = {}
  L11_2 = A0_2
  L10_2[1] = L11_2
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
  A0_2.DeathEvent = L6_2
  L6_2 = Event
  L6_2 = L6_2.Create
  L7_2 = Event
  L7_2 = L7_2.ObjectHibernation
  L8_2 = {}
  L9_2 = A1_2
  L10_2 = "hibernated"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L9_2 = _OnHibernate
  L10_2 = {}
  L11_2 = A0_2
  L12_2 = A1_2
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
  A0_2.HibernateEvent = L6_2
  L6_2 = Event
  L6_2 = L6_2.CreatePersistent
  L7_2 = Event
  L7_2 = L7_2.ScriptEvent
  L8_2 = {}
  L9_2 = "mpPlayerLeft"
  
  function L10_2(A0_3)
    local L1_3
    L1_3 = true
    return L1_3
  end
  
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L9_2 = _PlayerLeftGame
  L10_2 = {}
  L11_2 = A0_2
  L12_2 = A1_2
  L13_2 = L5_2
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
  A0_2.PlayerLeftEvent = L6_2
end

_WaitCallback = L2_1

function L2_1(A0_2, A1_2)
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

SetPickupVehicle = L2_1

function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  if A3_2 == 0 then
    L4_2 = MrxSupport
    L4_2 = L4_2.DenialMessage
    L5_2 = "abortnodrop"
    L4_2(L5_2)
    L4_2 = MrxSupport
    L4_2 = L4_2.GoHome
    L5_2 = A0_2
    L6_2 = A1_2
    L7_2 = A2_2
    L4_2(L5_2, L6_2, L7_2)
    return
  end
  L4_2 = Ai
  L4_2 = L4_2.Goal
  L5_2 = {}
  L5_2.AIGuid = A2_2
  L5_2.Goal = "Idle"
  L5_2.Priority = "hiPri"
  L5_2.MaintainRotorSpeed = true
  L4_2 = L4_2(L5_2)
  A0_2.uIdleGoal = L4_2
  L4_2 = A0_2.TimeoutEvent
  if L4_2 == nil then
    L4_2 = Event
    L4_2 = L4_2.Create
    L5_2 = Event
    L5_2 = L5_2.TimerRelative
    L6_2 = {}
    L7_2 = 45
    L6_2[1] = L7_2
    L7_2 = _RemoveTimeoutEvent
    L8_2 = {}
    L9_2 = A0_2
    L10_2 = A1_2
    L11_2 = A2_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
    A0_2.TimeoutEvent = L4_2
  end
  A0_2.bVehicleLanded = true
end

_VehicleLanded = L2_1

function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  A0_2.TimeoutEvent = nil
  L3_2 = MrxSupport
  L3_2 = L3_2.GoHome
  L4_2 = A0_2
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
  A0_2.bVehicleLanded = nil
  L3_2 = Event
  L3_2 = L3_2.Delete
  L4_2 = A0_2.EnterEvent
  L3_2(L4_2)
  L3_2 = Net
  L3_2 = L3_2.SendCustomEvent
  L4_2 = "MrxSupportTransit"
  L5_2 = NETEVENT_CLEARMESSAGE
  L6_2 = {}
  L7_2 = true
  L3_2(L4_2, L5_2, L6_2, L7_2)
end

_RemoveTimeoutEvent = L2_1

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _Cleanup
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = Object
  L2_2 = L2_2.Remove
  L3_2 = A1_2
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = MrxSupportManager
  L2_2 = L2_2.GetRecruitTimes
  L3_2 = "Copter"
  L2_2 = L2_2(L3_2)
  if L2_2 ~= nil then
    L2_2 = MrxSupportManager
    L2_2 = L2_2.MakeRecruitAvailable
    L3_2 = "Copter"
    L2_2(L3_2)
  end
end

_OnHibernate = L2_1

function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = 0.5
  L8_2 = true
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = MrxVoSequence
  L7_2 = L7_2.Start
  L8_2 = {}
  L9_2 = MrxUtil
  L9_2 = L9_2.GetRandomTableElement
  L10_2 = {}
  L11_2 = "Ewan.Transit.Ok1"
  L12_2 = "Ewan.Transit.Go3"
  L13_2 = "Ewan.Transit.Go2"
  L14_2 = "Ewan.Transit.Go1"
  L15_2 = "Ewan-In-Mission-Contract-Oil02-134"
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L10_2[5] = L15_2
  L9_2 = L9_2(L10_2)
  L10_2 = nil
  L11_2 = MrxVoSequence
  L11_2 = L11_2.knPriorityFreeplay
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = Player
  L4_2 = L4_2.GetSecondaryCharacter
  L4_2 = L4_2()
  if A3_2 == L4_2 then
    L4_2 = Net
    L4_2 = L4_2.SendCustomEvent
    L5_2 = "MrxSupportTransit"
    L6_2 = NETEVENT_SHOWMESSAGE
    L7_2 = {}
    L4_2(L5_2, L6_2, L7_2)
  end
  L4_2 = A0_2.TimeoutEvent
  if L4_2 then
    L4_2 = Event
    L4_2 = L4_2.Delete
    L5_2 = A0_2.TimeoutEvent
    L4_2(L5_2)
    A0_2.TimeoutEvent = nil
  end
  L4_2 = A0_2.bWaterPickup
  if not L4_2 then
    L4_2 = ipairs
    L5_2 = Player
    L5_2 = L5_2.GetAllPlayers
    L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2 = L5_2()
    L4_2, L5_2, L6_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
    for L7_2, L8_2 in L4_2, L5_2, L6_2 do
      L9_2 = Player
      L9_2 = L9_2.GetControlledObject
      L10_2 = L8_2
      L9_2 = L9_2(L10_2)
      if L9_2 ~= A1_2 then
        L10_2 = false
        return L10_2
      end
    end
  end
  L4_2 = MrxTransit
  L4_2 = L4_2.OpenInterface
  L5_2 = Player
  L5_2 = L5_2.GetLocalPlayer
  L5_2 = L5_2()
  L6_2 = _TransitInterfaceCallback
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A1_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = true
  bTransitInterfaceActive = L4_2
  L4_2 = true
  return L4_2
end

_OpenTransitInterface = L2_1

function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L4_2 = Player
  L4_2 = L4_2.GetSecondaryCharacter
  L4_2 = L4_2()
  if A3_2 == L4_2 then
    L4_2 = Net
    L4_2 = L4_2.SendCustomEvent
    L5_2 = "MrxSupportTransit"
    L6_2 = NETEVENT_CLEARMESSAGE
    L7_2 = {}
    L4_2(L5_2, L6_2, L7_2)
  end
  L4_2 = A0_2.bWaterPickup
  if not L4_2 then
    L4_2 = MrxGui
    L4_2 = L4_2.GetWidgetByNameAndOwner
    L5_2 = "PDA"
    L6_2 = Player
    L6_2 = L6_2.GetLocalPlayer
    L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L6_2()
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
    if L4_2 ~= nil then
      L5_2 = bTransitInterfaceActive
      if L5_2 == true then
        L5_2 = false
        bTransitInterfaceActive = L5_2
        L6_2 = L4_2
        L5_2 = L4_2.Close
        L5_2(L6_2)
      end
    end
    L5_2 = ipairs
    L6_2 = Player
    L6_2 = L6_2.GetAllPlayers
    L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L6_2()
    L5_2, L6_2, L7_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
    for L8_2, L9_2 in L5_2, L6_2, L7_2 do
      L10_2 = Player
      L10_2 = L10_2.GetControlledObject
      L11_2 = L9_2
      L10_2 = L10_2(L11_2)
      if L10_2 == A1_2 then
        L11_2 = false
        return L11_2
      end
    end
    L5_2 = A0_2.TimeoutEvent
    if L5_2 == nil then
      L5_2 = A0_2.bVehicleLanded
      if L5_2 == true then
        L5_2 = Event
        L5_2 = L5_2.Create
        L6_2 = Event
        L6_2 = L6_2.TimerRelative
        L7_2 = {}
        L8_2 = 10
        L7_2[1] = L8_2
        L8_2 = _RemoveTimeoutEvent
        L9_2 = {}
        L10_2 = A0_2
        L11_2 = A1_2
        L12_2 = A2_2
        L9_2[1] = L10_2
        L9_2[2] = L11_2
        L9_2[3] = L12_2
        L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
        A0_2.TimeoutEvent = L5_2
      end
    end
  end
  L4_2 = true
  return L4_2
end

_PlayerExited = L2_1

function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L3_2 = A0_2.bWaterPickup
  if not L3_2 then
    L3_2 = MrxGui
    L3_2 = L3_2.GetWidgetByNameAndOwner
    L4_2 = "PDA"
    L5_2 = Player
    L5_2 = L5_2.GetLocalPlayer
    L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L5_2()
    L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
    L4_2 = true
    L5_2 = true
    L6_2 = ipairs
    L7_2 = Player
    L7_2 = L7_2.GetAllPlayers
    L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L7_2()
    L6_2, L7_2, L8_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
    for L9_2, L10_2 in L6_2, L7_2, L8_2 do
      L11_2 = Player
      L11_2 = L11_2.GetControlledObject
      L12_2 = L10_2
      L11_2 = L11_2(L12_2)
      if L11_2 == A1_2 then
        L4_2 = false
      else
        L5_2 = false
      end
    end
    if L5_2 == true and L3_2 ~= nil then
      L6_2 = bTransitInterfaceActive
      if L6_2 == false then
        L6_2 = MrxTransit
        L6_2 = L6_2.OpenInterface
        L7_2 = Player
        L7_2 = L7_2.GetLocalPlayer
        L7_2 = L7_2()
        L8_2 = _TransitInterfaceCallback
        L9_2 = {}
        L10_2 = A0_2
        L11_2 = A1_2
        L9_2[1] = L10_2
        L9_2[2] = L11_2
        L6_2(L7_2, L8_2, L9_2)
        L6_2 = true
        bTransitInterfaceActive = L6_2
      end
    end
    if L4_2 == true then
      L6_2 = A0_2.bVehicleLanded
      if L6_2 == true then
        L6_2 = A0_2.TimeoutEvent
        if L6_2 == nil then
          L6_2 = Event
          L6_2 = L6_2.Create
          L7_2 = Event
          L7_2 = L7_2.TimerRelative
          L8_2 = {}
          L9_2 = 10
          L8_2[1] = L9_2
          L9_2 = _RemoveTimeoutEvent
          L10_2 = {}
          L11_2 = A0_2
          L12_2 = A1_2
          L13_2 = A2_2
          L10_2[1] = L11_2
          L10_2[2] = L12_2
          L10_2[3] = L13_2
          L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
          A0_2.TimeoutEvent = L6_2
        end
      end
    end
  end
  L3_2 = true
  return L3_2
end

_PlayerLeftGame = L2_1

function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  L4_2 = Net
  L4_2 = L4_2.SendCustomEvent
  L5_2 = "MrxSupportTransit"
  L6_2 = NETEVENT_CLEARMESSAGE
  L7_2 = {}
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = bTransitInterfaceActive
  if L4_2 == false then
    return
  end
  L4_2 = false
  bTransitInterfaceActive = L4_2
  L4_2 = MrxTransit
  L4_2 = L4_2.GetTransitPoint
  L5_2 = A2_2
  L4_2 = L4_2(L5_2)
  if A3_2 then
    L6_2 = A0_2
    L5_2 = A0_2.TransitToPoint
    L7_2 = A1_2
    L8_2 = L4_2
    L5_2(L6_2, L7_2, L8_2)
  else
    L5_2 = AllPlayersExitVehicle
    L6_2 = true
    L5_2(L6_2)
  end
end

_TransitInterfaceCallback = L2_1

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  if A1_2 == 1 then
    return
  end
  L2_2 = true
  bTransitInterfaceActive = L2_2
  L2_2 = Player
  L2_2 = L2_2.GetPrimaryCharacter
  L2_2 = L2_2()
  L4_2 = A0_2
  L3_2 = A0_2.Create
  L5_2 = L2_2
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = Object
  L4_2 = L4_2.GetPosition
  L5_2 = L2_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  L7_2 = Object
  L7_2 = L7_2.GetYaw
  L8_2 = L2_2
  L7_2 = L7_2(L8_2)
  L8_2 = Pg
  L8_2 = L8_2.Spawn
  L9_2 = L3_2.uDeliveryVehicle
  L10_2 = L4_2
  L11_2 = L5_2 + 20
  L12_2 = L6_2
  L13_2 = L7_2
  L14_2 = false
  L15_2 = true
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  L9_2 = Event
  L9_2 = L9_2.Create
  L10_2 = Event
  L10_2 = L10_2.ObjectHibernation
  L11_2 = {}
  L12_2 = L8_2
  L13_2 = "awake"
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L12_2 = _WaitCallbackBriefing
  L13_2 = {}
  L14_2 = A0_2
  L15_2 = L3_2
  L16_2 = L8_2
  L17_2 = L2_2
  L18_2 = A1_2
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L13_2[3] = L16_2
  L13_2[4] = L17_2
  L13_2[5] = L18_2
  L9_2(L10_2, L11_2, L12_2, L13_2)
end

TransitInterfaceCallbackBriefing = L2_1

function L2_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L5_2 = Vehicle
  L5_2 = L5_2.Enter
  L6_2 = A2_2
  L7_2 = A3_2
  L8_2 = "p"
  L9_2 = true
  L10_2 = false
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L5_2 = WifPmcInterior
  L5_2 = L5_2.IsInside
  L5_2 = L5_2()
  if L5_2 then
    L5_2 = WifPmcInterior
    L5_2 = L5_2.IsEntering
    L5_2 = L5_2()
    if not L5_2 then
      L5_2 = WifPmcInterior
      L5_2 = L5_2.Exit
      L6_2 = -1
      L7_2 = false
      L5_2(L6_2, L7_2)
    end
  end
  L6_2 = A1_2
  L5_2 = A1_2._TransitInterfaceCallback
  L7_2 = A2_2
  L8_2 = A4_2
  L9_2 = true
  L5_2(L6_2, L7_2, L8_2, L9_2)
end

_WaitCallbackBriefing = L2_1

function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  if A2_2 then
    L3_2 = MrxUtil
    L3_2 = L3_2.GetDistanceBetween
    L4_2 = A2_2
    L5_2 = A1_2
    L6_2 = false
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    if 15 < L3_2 then
      L3_2 = A0_2.bWaterPickup
      if L3_2 then
        L3_2 = Vehicle
        L3_2 = L3_2.Enter
        L4_2 = A1_2
        L5_2 = Player
        L5_2 = L5_2.GetPrimaryCharacter
        L5_2 = L5_2()
        L6_2 = "p"
        L7_2 = true
        L8_2 = false
        L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
      end
      L3_2 = Net
      L3_2 = L3_2.SendCustomEvent
      L4_2 = "MrxSupportTransit"
      L5_2 = NETEVENT_ENTERVEHICLE
      L6_2 = {}
      L7_2 = A1_2
      L6_2[1] = L7_2
      L7_2 = true
      L3_2(L4_2, L5_2, L6_2, L7_2)
      L3_2 = Event
      L3_2 = L3_2.Post
      L4_2 = "transitStart"
      L5_2 = {}
      L6_2 = A1_2
      L5_2[1] = L6_2
      L3_2(L4_2, L5_2)
      L3_2 = MrxTransit
      L3_2 = L3_2.StartTransit
      L4_2 = _StartTransit
      L5_2 = _FinishTransit
      L6_2 = {}
      L7_2 = A0_2
      L8_2 = A1_2
      L9_2 = A2_2
      L6_2[1] = L7_2
      L6_2[2] = L8_2
      L6_2[3] = L9_2
      L3_2(L4_2, L5_2, L6_2)
    end
  end
end

TransitToPoint = L2_1

function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = Object
  L3_2 = L3_2.GetPosition
  L4_2 = A2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  L6_2 = Object
  L6_2 = L6_2.GetYaw
  L7_2 = A2_2
  L6_2 = L6_2(L7_2)
  L7_2 = 8
  L8_2 = Object
  L8_2 = L8_2.SetYaw
  L9_2 = A1_2
  L10_2 = L6_2
  L8_2(L9_2, L10_2)
  L8_2 = Object
  L8_2 = L8_2.SetPosition
  L9_2 = A1_2
  L10_2 = L3_2
  L11_2 = L4_2 + L7_2
  L12_2 = L5_2
  L8_2(L9_2, L10_2, L11_2, L12_2)
  L8_2 = A0_2.HibernateEvent
  if L8_2 then
    L8_2 = Event
    L8_2 = L8_2.Delete
    L9_2 = A0_2.HibernateEvent
    L8_2(L9_2)
  end
  L8_2 = Vehicle
  L8_2 = L8_2.SetCanPlayerUse
  L9_2 = A1_2
  L10_2 = "a"
  L11_2 = false
  L8_2(L9_2, L10_2, L11_2)
  L8_2 = Object
  L8_2 = L8_2.GetPosition
  L9_2 = A1_2
  L8_2, L9_2, L10_2 = L8_2(L9_2)
  L5_2 = L10_2
  L4_2 = L9_2
  L3_2 = L8_2
  L8_2 = MrxUtil
  L8_2 = L8_2.ClearVehiclesNearPoint
  L9_2 = A2_2
  L10_2 = A1_2
  L8_2(L9_2, L10_2)
end

_StartTransit = L2_1

function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = Object
  L3_2 = L3_2.GetPosition
  L4_2 = A2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  L6_2 = Vehicle
  L6_2 = L6_2.GetDriver
  L7_2 = A1_2
  L6_2 = L6_2(L7_2)
  L7_2 = A0_2.eAbort
  if L7_2 then
    L7_2 = Event
    L7_2 = L7_2.Delete
    L8_2 = A0_2.eAbort
    L7_2(L8_2)
    A0_2.eAbort = nil
  end
  L7_2 = A0_2.uIdleGoal
  if L7_2 then
    L7_2 = Ai
    L7_2 = L7_2.RemoveGoal
    L8_2 = {}
    L8_2.AIGuid = L6_2
    L9_2 = A0_2.uIdleGoal
    L8_2.Handle = L9_2
    L7_2(L8_2)
    A0_2.uIdleGoal = nil
  end
  L7_2 = Ai
  L7_2 = L7_2.Goal
  L8_2 = {}
  L8_2.AIGuid = L6_2
  L8_2.Goal = "HeliLand"
  L9_2 = {}
  L10_2 = L3_2
  L11_2 = L4_2
  L12_2 = L5_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L9_2[3] = L12_2
  L8_2.Location = L9_2
  L8_2.Priority = "hiPri"
  L8_2.Force = true
  L9_2 = _FinishTransit2
  L8_2.Callback = L9_2
  L9_2 = {}
  L10_2 = A0_2
  L11_2 = A1_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L8_2.CallbackData = L9_2
  L7_2 = L7_2(L8_2)
  L8_2 = Object
  L8_2 = L8_2.GetPosition
  L9_2 = A1_2
  L8_2, L9_2, L10_2 = L8_2(L9_2)
  L5_2 = L10_2
  L4_2 = L9_2
  L3_2 = L8_2
  L8_2 = _Cleanup
  L9_2 = A0_2
  L8_2(L9_2)
end

_FinishTransit = L2_1

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = AllPlayersExitVehicle
  L3_2 = true
  L2_2(L3_2)
  L2_2 = Event
  L2_2 = L2_2.Post
  L3_2 = "transitEnd"
  L4_2 = {}
  L5_2 = A1_2
  L4_2[1] = L5_2
  L2_2(L3_2, L4_2)
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 1.5
  L4_2[1] = L5_2
  L5_2 = MrxSupport
  L5_2 = L5_2.GoHome
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = A1_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = A1_2
  L6_2 = "hibernated"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = _OnHibernate
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = A1_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  A0_2.HibernateEvent = L2_2
end

_FinishTransit2 = L2_1
L2_1 = 0
NETEVENT_ENTERVEHICLE = L2_1
L2_1 = 1
NETEVENT_EXITVEHICLE = L2_1
L2_1 = 2
NETEVENT_SHOWMESSAGE = L2_1
L2_1 = 3
NETEVENT_CLEARMESSAGE = L2_1

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = NETEVENT_ENTERVEHICLE
  if A0_2 == L2_2 then
    L2_2 = Vehicle
    L2_2 = L2_2.Enter
    L3_2 = A1_2[1]
    L4_2 = Player
    L4_2 = L4_2.GetSecondaryCharacter
    L4_2 = L4_2()
    L5_2 = "p"
    L6_2 = true
    L7_2 = false
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
    L2_2 = Player
    L2_2 = L2_2.SetCinematicMode
    L3_2 = Player
    L3_2 = L3_2.GetSecondaryPlayer
    L3_2 = L3_2()
    L4_2 = false
    L2_2(L3_2, L4_2)
    L2_2 = MrxState
    L2_2 = L2_2.SetQuickFade
    L3_2 = false
    L2_2(L3_2)
  else
    L2_2 = NETEVENT_EXITVEHICLE
    if A0_2 == L2_2 then
      L2_2 = AllPlayersExitVehicle
      L2_2()
    else
      L2_2 = NETEVENT_SHOWMESSAGE
      if A0_2 == L2_2 then
        L2_2 = MrxTutorialManager
        L2_2 = L2_2.ShowMessage
        L3_2 = "[Tutorial.ClientTransit]"
        L4_2 = true
        L5_2 = "TransitTutorial"
        L2_2(L3_2, L4_2, L5_2)
      else
        L2_2 = NETEVENT_CLEARMESSAGE
        if A0_2 == L2_2 then
          L2_2 = MrxTutorialManager
          L2_2 = L2_2.HideMessage
          L3_2 = true
          L4_2 = "TransitTutorial"
          L2_2(L3_2, L4_2)
        end
      end
    end
  end
end

NetEventCallback = L2_1

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  if A0_2 then
    L1_2 = Net
    L1_2 = L1_2.SendCustomEvent
    L2_2 = "MrxSupportTransit"
    L3_2 = NETEVENT_EXITVEHICLE
    L4_2 = {}
    L5_2 = true
    L1_2(L2_2, L3_2, L4_2, L5_2)
  end
  L1_2 = Player
  L1_2 = L1_2.GetPrimaryCharacter
  L1_2 = L1_2()
  if L1_2 then
    L2_2 = Player
    L2_2 = L2_2.GetControlledObject
    L3_2 = Player
    L3_2 = L3_2.GetPrimaryPlayer
    L3_2, L4_2, L5_2, L6_2, L7_2 = L3_2()
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
    if L2_2 then
      L3_2 = Vehicle
      L3_2 = L3_2.Exit
      L4_2 = L2_2
      L5_2 = L1_2
      L6_2 = false
      L3_2(L4_2, L5_2, L6_2)
    end
  end
  L2_2 = Player
  L2_2 = L2_2.GetSecondaryCharacter
  L2_2 = L2_2()
  if L2_2 then
    L3_2 = Player
    L3_2 = L3_2.GetControlledObject
    L4_2 = Player
    L4_2 = L4_2.GetSecondaryPlayer
    L4_2, L5_2, L6_2, L7_2 = L4_2()
    L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
    if L3_2 then
      L4_2 = Vehicle
      L4_2 = L4_2.Exit
      L5_2 = L3_2
      L6_2 = L2_2
      L7_2 = true
      L4_2(L5_2, L6_2, L7_2)
    end
  end
  L3_2 = Net
  L3_2 = L3_2.SendCustomEvent
  L4_2 = "MrxSupportTransit"
  L5_2 = NETEVENT_CLEARMESSAGE
  L6_2 = {}
  L7_2 = true
  L3_2(L4_2, L5_2, L6_2, L7_2)
end

AllPlayersExitVehicle = L2_1

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = A0_2.EnterEvent
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2.EnterEvent
    L1_2(L2_2)
    A0_2.EnterEvent = nil
  end
  L1_2 = A0_2.ExitEvent
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2.ExitEvent
    L1_2(L2_2)
    A0_2.ExitEvent = nil
  end
  L1_2 = A0_2.PlayerLeftEvent
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2.PlayerLeftEvent
    L1_2(L2_2)
    A0_2.PlayerLeftEvent = nil
  end
  L1_2 = A0_2.TimeoutEvent
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2.TimeoutEvent
    L1_2(L2_2)
    A0_2.TimeoutEvent = nil
  end
  L1_2 = A0_2.DeathEvent
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2.DeathEvent
    L1_2(L2_2)
    A0_2.DeathEvent = nil
  end
  L1_2 = A0_2.eAbort
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2.eAbort
    L1_2(L2_2)
    A0_2.eAbort = nil
  end
  L1_2 = false
  bTransitInterfaceActive = L1_2
  L1_2 = Net
  L1_2 = L1_2.SendCustomEvent
  L2_2 = "MrxSupportTransit"
  L3_2 = NETEVENT_CLEARMESSAGE
  L4_2 = {}
  L5_2 = true
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

_Cleanup = L2_1

function L2_1(A0_2)
  local L1_2, L2_2
  A0_2.DeathEvent = nil
  L1_2 = _Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

_HandleDeath = L2_1
