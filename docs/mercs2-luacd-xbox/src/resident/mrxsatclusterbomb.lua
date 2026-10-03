local L0_1, L1_1, L2_1, L3_1
L0_1 = inherit
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorSatellite"
L0_1(L1_1)
L0_1 = {}
L1_1 = "Misha-None-Freeplay-Support-03"
L2_1 = "Misha-None-Freeplay-Support-14"
L3_1 = "Misha-None-Freeplay-Support-25"
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
tVOCues = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = {}
  L3_2 = setmetatable
  L4_2 = L2_2
  L5_2 = A0_2
  L3_2(L4_2, L5_2)
  A0_2.__index = A0_2
  L3_2 = MrxSupportDesignatorSatellite
  L4_2 = L3_2
  L3_2 = L3_2.Create
  L3_2 = L3_2(L4_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetDesignator
  L6_2 = L3_2
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
  L6_2 = "MrxSatClusterBomb"
  L4_2(L5_2, L6_2)
  L4_2 = A0_2.sDeliveryVehicle
  L2_2.sDeliveryVehicle = L4_2
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = A0_2.sDeliveryVehicle
  L4_2 = L4_2(L5_2)
  L2_2.uDeliveryVehicle = L4_2
  L5_2 = L3_2
  L4_2 = L3_2.SetMinigameSectors
  L6_2 = {}
  L7_2 = {}
  L8_2 = 45
  L9_2 = 135
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L8_2 = {}
  L9_2 = 225
  L10_2 = 315
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L4_2(L5_2, L6_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetCost
  L6_2 = 0
  L4_2(L5_2, L6_2)
  return L2_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L1_2 = Pg
  L1_2 = L1_2.FindPointFromCamera
  L2_2 = 300
  L3_2 = 200
  L4_2 = -1
  L5_2 = A0_2.uOwner
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  L4_2 = Pg
  L4_2 = L4_2.FindPointFromCamera
  L5_2 = 100
  L6_2 = 50
  L7_2 = -1
  L8_2 = A0_2.uOwner
  L4_2, L5_2, L6_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L7_2 = Airstrike
  L7_2 = L7_2.Flyby
  L8_2 = A0_2.uDeliveryVehicle
  L9_2 = L1_2
  L10_2 = L3_2
  L11_2 = L4_2
  L12_2 = L6_2
  L13_2 = L5_2
  L14_2 = 100
  L15_2 = DropBomb
  L16_2 = {}
  L17_2 = A0_2
  L18_2 = L4_2
  L19_2 = L5_2
  L20_2 = L6_2
  L16_2[1] = L17_2
  L16_2[2] = L18_2
  L16_2[3] = L19_2
  L16_2[4] = L20_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
  A0_2.uJet = L7_2
end

DesignationCallback = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2
  L4_2 = Object
  L4_2 = L4_2.GetPosition
  L5_2 = A0_2.uJet
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  L8_2 = A0_2
  L7_2 = A0_2.GetDesignator
  L7_2 = L7_2(L8_2)
  L8_2 = L7_2
  L7_2 = L7_2.GetTarget
  L7_2, L8_2, L9_2 = L7_2(L8_2)
  L10_2 = L5_2 - L8_2
  L10_2 = L10_2 - 15
  L11_2 = L7_2 - L4_2
  L12_2 = L8_2 - L5_2
  L13_2 = L9_2 - L6_2
  L14_2 = Math
  L14_2 = L14_2.Normalize
  L15_2 = L11_2
  L16_2 = L12_2
  L17_2 = L13_2
  L14_2, L15_2, L16_2 = L14_2(L15_2, L16_2, L17_2)
  L13_2 = L16_2
  L12_2 = L15_2
  L11_2 = L14_2
  L14_2 = 35
  L15_2 = Airstrike
  L15_2 = L15_2.SpawnOrdnance
  L16_2 = "Cluster Bomb Projectile"
  L17_2 = L4_2
  L18_2 = L5_2
  L19_2 = L6_2
  L20_2 = L11_2 * L14_2
  L21_2 = L12_2 * L14_2
  L22_2 = L13_2 * L14_2
  L23_2 = "distance"
  L24_2 = L10_2
  L26_2 = A0_2
  L25_2 = A0_2.GetOwner
  L25_2 = L25_2(L26_2)
  L26_2 = BombExplodes
  L27_2 = {}
  L28_2 = A0_2
  L27_2[1] = L28_2
  L15_2 = L15_2(L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2)
  A0_2.uSpawnedBomb = L15_2
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
  L21_2 = 10
  L22_2 = L9_2
  L23_2 = 4
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
  L21_2 = 15
  L22_2 = L9_2
  L23_2 = 4
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
  L23_2 = 6
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
  L21_2 = 50
  L22_2 = L9_2
  L23_2 = 6
  L13_2(L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2)
end

BombExplodes = L0_1
