local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorSmoke"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
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
  L5_2 = L2_2
  L4_2 = L2_2.SetDesignator
  L6_2 = L3_2
  L4_2(L5_2, L6_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetSmokeColor
  L6_2 = "red"
  L4_2(L5_2, L6_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetAATestLevel
  L6_2 = "basic"
  L4_2(L5_2, L6_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetValidationFunction
  L6_2 = _NoValidation
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetOwner
  L6_2 = A1_2
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetRecruit
  L6_2 = "Pilot"
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetDesignator
  L6_2 = L3_2
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetModuleName
  L6_2 = "MrxClusterBomb"
  L4_2(L5_2, L6_2)
  L4_2 = A0_2.sDeliveryVehicle
  L2_2.sDeliveryVehicle = L4_2
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = A0_2.sDeliveryVehicle
  L4_2 = L4_2(L5_2)
  L2_2.uDeliveryVehicle = L4_2
  return L2_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L1_2 = MrxSupportDesignatorSmoke
  L2_2 = L1_2
  L1_2 = L1_2.DesignationCompleteCallback
  L1_2(L2_2)
  L1_2 = math
  L1_2 = L1_2.randi
  L2_2 = 120
  L1_2 = L1_2(L2_2)
  L1_2 = 300 + L1_2
  L2_2 = Pg
  L2_2 = L2_2.FindPointFromCamera
  L3_2 = 300
  L4_2 = 200
  L5_2 = -1
  L6_2 = A0_2.uOwner
  L7_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L5_2 = Pg
  L5_2 = L5_2.FindPointFromCamera
  L6_2 = 100
  L7_2 = 50
  L8_2 = -1
  L9_2 = A0_2.uOwner
  L10_2 = L1_2
  L5_2, L6_2, L7_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L8_2 = Airstrike
  L8_2 = L8_2.Flyby
  L9_2 = A0_2.uDeliveryVehicle
  L10_2 = L2_2
  L11_2 = L4_2
  L12_2 = L5_2
  L13_2 = L7_2
  L14_2 = L6_2
  L15_2 = 100
  L16_2 = DropBomb
  L17_2 = {}
  L18_2 = A0_2
  L17_2[1] = L18_2
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  A0_2.uJet = L8_2
  L9_2 = Event
  L9_2 = L9_2.Create
  L10_2 = Event
  L10_2 = L10_2.TimerRelative
  L11_2 = {}
  L12_2 = 2
  L11_2[1] = L12_2
  L12_2 = MrxSupport
  L12_2 = L12_2.PlayAirstrikeVO
  L13_2 = {}
  L14_2 = L8_2
  L15_2 = {}
  L16_2 = "Misha-None-Freeplay-Support-03"
  L17_2 = "Misha-None-Freeplay-Support-14"
  L18_2 = "Misha-None-Freeplay-Support-25"
  L15_2[1] = L16_2
  L15_2[2] = L17_2
  L15_2[3] = L18_2
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L9_2(L10_2, L11_2, L12_2, L13_2)
end

DesignationCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = A0_2.uJet
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  L5_2 = A0_2
  L4_2 = A0_2.GetDesignator
  L4_2 = L4_2(L5_2)
  L5_2 = L4_2
  L4_2 = L4_2.GetTarget
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  L7_2 = L2_2 - L5_2
  L7_2 = L7_2 - 15
  L8_2 = L4_2 - L1_2
  L9_2 = L5_2 - L2_2
  L10_2 = L6_2 - L3_2
  L11_2 = Math
  L11_2 = L11_2.Normalize
  L12_2 = L8_2
  L13_2 = L9_2
  L14_2 = L10_2
  L11_2, L12_2, L13_2 = L11_2(L12_2, L13_2, L14_2)
  L10_2 = L13_2
  L9_2 = L12_2
  L8_2 = L11_2
  L11_2 = 35
  L12_2 = Airstrike
  L12_2 = L12_2.SpawnOrdnance
  L13_2 = "Cluster Bomb Projectile"
  L14_2 = L1_2
  L15_2 = L2_2
  L16_2 = L3_2
  L17_2 = L8_2 * L11_2
  L18_2 = L9_2 * L11_2
  L19_2 = L10_2 * L11_2
  L20_2 = "obstructed"
  L21_2 = 30
  L23_2 = A0_2
  L22_2 = A0_2.GetOwner
  L22_2 = L22_2(L23_2)
  L23_2 = BombExplodes
  L24_2 = {}
  L25_2 = A0_2
  L24_2[1] = L25_2
  L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2)
  A0_2.uSpawnedBomb = L12_2
end

DropBomb = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = A0_2.uSpawnedBomb
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  L5_2 = A0_2
  L4_2 = A0_2.GetDesignator
  L4_2 = L4_2(L5_2)
  L5_2 = L4_2
  L4_2 = L4_2.GetTarget
  L4_2, L5_2, L6_2, L7_2, L8_2 = L4_2(L5_2)
  L9_2 = 20
  L10_2 = L4_2 - L1_2
  L11_2 = L5_2 - L2_2
  L12_2 = L6_2 - L3_2
  L13_2 = Math
  L13_2 = L13_2.Normalize
  L14_2 = L10_2
  L15_2 = L11_2
  L16_2 = L12_2
  L13_2, L14_2, L15_2 = L13_2(L14_2, L15_2, L16_2)
  L12_2 = L15_2
  L11_2 = L14_2
  L10_2 = L13_2
  L13_2 = Airstrike
  L13_2 = L13_2.ConeSpawn
  L14_2 = "Cluster Bomblet Projectile"
  L15_2 = L1_2
  L16_2 = L2_2
  L17_2 = L3_2
  L18_2 = L10_2
  L19_2 = L11_2
  L20_2 = L12_2
  L21_2 = 15
  L22_2 = L9_2
  L23_2 = 10
  L13_2(L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2)
  L13_2 = Airstrike
  L13_2 = L13_2.ConeSpawn
  L14_2 = "Cluster Bomblet Projectile"
  L15_2 = L1_2
  L16_2 = L2_2
  L17_2 = L3_2
  L18_2 = L10_2
  L19_2 = L11_2
  L20_2 = L12_2
  L21_2 = 30
  L22_2 = L9_2
  L23_2 = 20
  L13_2(L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2)
end

BombExplodes = L0_1
