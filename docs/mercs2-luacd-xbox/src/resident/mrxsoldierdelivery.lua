local L0_1, L1_1, L2_1, L3_1, L4_1
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
L0_1 = "UH1 Transport (GR) (Full)"
sDeliveryVehicle = L0_1
L0_1 = 50
nAltitude = L0_1
L0_1 = "MrxSoldierDelivery"
sModuleName = L0_1
L0_1 = {}
L1_1 = {}
L2_1 = "Ewan-None-Freeplay-Support-73"
L3_1 = "Ewan-None-Freeplay-Support-38"
L1_1[1] = L2_1
L1_1[2] = L3_1
L0_1.Pmc = L1_1
L1_1 = {}
L2_1 = "AlliedSoldier01.Troops.Incoming01"
L3_1 = "AlliedSoldier01.Troops.Incoming02"
L4_1 = "AlliedSoldier01.Troops.Incoming03"
L1_1[1] = L2_1
L1_1[2] = L3_1
L1_1[3] = L4_1
L0_1.Allied = L1_1
L1_1 = {}
L2_1 = "ChinaSoldier01.Troops.Incoming01"
L3_1 = "ChinaSoldier01.Troops.Incoming02"
L4_1 = "ChinaSoldier01.Troops.Incoming03"
L1_1[1] = L2_1
L1_1[2] = L3_1
L1_1[3] = L4_1
L0_1.China = L1_1
L1_1 = {}
L2_1 = "Fiona.PirateCoverage.Reinforcements02"
L1_1[1] = L2_1
L0_1.Pirate = L1_1
L1_1 = {}
L2_1 = "GurSoldier01.Troops.Incoming01"
L3_1 = "GurSoldier01.Troops.Incoming02"
L4_1 = "GurSoldier01.Troops.Incoming03"
L1_1[1] = L2_1
L1_1[2] = L3_1
L1_1[3] = L4_1
L0_1.Guerilla = L1_1
L1_1 = {}
L2_1 = "OCSoldier01.Troops.Incoming01"
L3_1 = "OCSoldier01.Troops.Incoming02"
L4_1 = "OCSoldier01.Troops.Incoming03"
L1_1[1] = L2_1
L1_1[2] = L3_1
L1_1[3] = L4_1
L0_1.OC = L1_1
tVOOnTheWay = L0_1
L0_1 = "01_pmc_hq_lz_playerone"
oFinalDestination = L0_1

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
  L3_2 = A0_2.oFinalDestination
  L2_2.oFinalDestination = L3_2
  L2_2.oUpdateEvent = nil
  L4_2 = L2_2
  L3_2 = L2_2.SetOwner
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
  L3_2 = MrxSupportDesignatorSmoke
  L4_2 = L3_2
  L3_2 = L3_2.Create
  L3_2 = L3_2(L4_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetSmokeColor
  L6_2 = "blue"
  L4_2(L5_2, L6_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetAATestLevel
  L6_2 = "none"
  L4_2(L5_2, L6_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetValidationFunction
  L6_2 = CheckForSoldiers
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetDesignator
  L6_2 = L3_2
  L4_2(L5_2, L6_2)
  L4_2 = A0_2.sModuleName
  L2_2.sModuleName = L4_2
  L5_2 = L2_2
  L4_2 = L2_2.SetRecruit
  L6_2 = "Fiona"
  L4_2(L5_2, L6_2)
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
  L1_2 = Net
  L1_2 = L1_2.IsClient
  L1_2 = L1_2()
  if not L1_2 then
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
    L15_2 = MrxSupport
    L15_2 = L15_2.SetupDamageEvent
    L16_2 = A0_2
    L17_2 = L7_2
    L18_2 = false
    L15_2(L16_2, L17_2, L18_2)
  end
end

_DesignatorCallback = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L5_2 = MrxUtil
  L5_2 = L5_2.GetFaction
  L6_2 = A1_2
  L5_2 = L5_2(L6_2)
  if L5_2 then
    L6_2 = tVOOnTheWay
    L6_2 = L6_2[L5_2]
    if L6_2 then
      L6_2 = MrxSupport
      L6_2 = L6_2.PlayRandomVOCue
      L7_2 = tVOOnTheWay
      L7_2 = L7_2[L5_2]
      L6_2(L7_2)
    else
    end
  end
  L6_2 = Vehicle
  L6_2 = L6_2.GetDriver
  L7_2 = A1_2
  L6_2 = L6_2(L7_2)
  L7_2 = Ai
  L7_2 = L7_2.Goal
  L8_2 = {}
  L9_2 = Vehicle
  L9_2 = L9_2.GetDriver
  L10_2 = A1_2
  L9_2 = L9_2(L10_2)
  L8_2.AIGuid = L9_2
  L8_2.Goal = "HeliLand"
  L9_2 = {}
  L10_2 = A2_2
  L11_2 = A3_2
  L12_2 = A4_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L9_2[3] = L12_2
  L8_2.Location = L9_2
  L8_2.Priority = "hiPri"
  L9_2 = AllOut
  L8_2.Callback = L9_2
  L9_2 = {}
  L10_2 = A0_2
  L11_2 = A1_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L8_2.CallbackData = L9_2
  L7_2 = L7_2(L8_2)
  A0_2.LandGoal = L7_2
  L7_2 = Object
  L7_2 = L7_2.AddLabel
  L8_2 = A1_2
  L9_2 = "Disposable"
  L7_2(L8_2, L9_2)
end

_WaitCallback = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  A0_2.bSupportComplete = true
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
  L4_2 = Vehicle
  L4_2 = L4_2.GetRiders
  L5_2 = A1_2
  L6_2 = "p"
  L4_2 = L4_2(L5_2, L6_2)
  L5_2 = Ai
  L5_2 = L5_2.Deploy
  L6_2 = {}
  L6_2.Vehicle = A1_2
  L6_2.Role = "Passenger"
  L6_2.Force = true
  L6_2.MaintainRotorSpeed = true
  L7_2 = FollowTheLeader
  L6_2.Callback = L7_2
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = L4_2
  L10_2 = A1_2
  L11_2 = A2_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L6_2.CallbackData = L7_2
  L5_2(L6_2)
end

AllOut = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L4_2 = ipairs
  L5_2 = A1_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = Object
    L9_2 = L9_2.IsAlive
    L10_2 = L8_2
    L9_2 = L9_2(L10_2)
    if L9_2 then
      L9_2 = Ai
      L9_2 = L9_2.Role
      L10_2 = {}
      L10_2.AIGuid = L8_2
      L10_2.Role = "Follow"
      L11_2 = Player
      L11_2 = L11_2.GetCharacter
      L12_2 = A0_2.uOwner
      L11_2 = L11_2(L12_2)
      L10_2.Target = L11_2
      L10_2.MinDistance = 10
      L10_2.MoveDistance = 12
      L10_2.MaxDistance = 50
      L10_2.Priority = "medPri"
      L9_2(L10_2)
    end
  end
  L4_2 = MrxSupport
  L4_2 = L4_2.GoHome
  L5_2 = A0_2
  L6_2 = A2_2
  L7_2 = A3_2
  L4_2(L5_2, L6_2, L7_2)
end

FollowTheLeader = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L5_2 = MrxUtil
  L5_2 = L5_2.GetFaction
  L6_2 = A4_2.uDeliveryVehicle
  L5_2 = L5_2(L6_2)
  if L5_2 then
    L6_2 = Pg
    L6_2 = L6_2.FastCollectHumans
    L7_2 = A1_2
    L8_2 = A2_2
    L9_2 = A3_2
    L10_2 = 80
    L11_2 = L5_2
    L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
    tRushers = L6_2
  end
  L6_2 = tRushers
  if not L6_2 then
    L6_2 = {}
  end
  tRushers = L6_2
  L6_2 = table
  L6_2 = L6_2.getn
  L7_2 = tRushers
  L6_2 = L6_2(L7_2)
  if L6_2 < 8 then
    L6_2 = MrxSupportDesignator
    L6_2 = L6_2.ValidateLandingZone
    L7_2 = A0_2
    L8_2 = A1_2
    L9_2 = A2_2
    L10_2 = A3_2
    L11_2 = A4_2
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  else
    L6_2 = A0_2
    L7_2 = false
    L8_2 = "toomanysoldiers"
    L9_2 = tostring
    L10_2 = L5_2
    L9_2 = L9_2(L10_2)
    L8_2 = L8_2 .. L9_2
    L6_2(L7_2, L8_2)
  end
end

CheckForSoldiers = L0_1
