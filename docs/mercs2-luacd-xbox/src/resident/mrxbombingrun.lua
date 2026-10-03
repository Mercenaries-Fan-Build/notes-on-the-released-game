local L0_1, L1_1, L2_1
L0_1 = inherit
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorSmoke"
L0_1(L1_1)
L0_1 = "Bomb"
L1_1 = "Explosion (Bombing Run)"

function L2_1(A0_2, A1_2)
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
  L5_2 = L3_2
  L4_2 = L3_2.SetAATestLevel
  L6_2 = "basic"
  L4_2(L5_2, L6_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetValidationFunction
  L6_2 = _NoValidation
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
  L4_2 = L2_2.SetRecruit
  L6_2 = "Pilot"
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetModuleName
  L6_2 = "MrxBombingRun"
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

Create = L2_1

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L1_2 = Pg
  L1_2 = L1_2.FindPointFromCamera
  L2_2 = -300
  L3_2 = 100
  L4_2 = -1
  L5_2 = A0_2.uOwner
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  L4_2 = Pg
  L4_2 = L4_2.FindPointFromCamera
  L5_2 = 0
  L6_2 = 100
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
  L14_2 = 200
  L15_2 = DropBomb
  L16_2 = {}
  L17_2 = A0_2
  L16_2[1] = L17_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
  A0_2.uJet = L7_2
  L8_2 = MrxSupport
  L8_2 = L8_2.PlayAirstrikeVO
  L9_2 = L7_2
  L10_2 = {}
  L11_2 = "Misha-None-Freeplay-Support-01"
  L12_2 = "Misha-None-Freeplay-Support-19"
  L13_2 = "Misha-None-Freeplay-Support-23"
  L14_2 = "Misha-None-Freeplay-Support-32"
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L8_2(L9_2, L10_2)
end

DesignationCallback = L2_1

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = A0_2.uJet
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  L5_2 = A0_2
  L4_2 = A0_2.GetDesignator
  L4_2 = L4_2(L5_2)
  L5_2 = L4_2
  L4_2 = L4_2.GetTarget
  L4_2, L5_2, L6_2, L7_2, L8_2 = L4_2(L5_2)
  L9_2 = L4_2 - L1_2
  L10_2 = L5_2 - L2_2
  L11_2 = L6_2 - L3_2
  L12_2 = Math
  L12_2 = L12_2.Normalize
  L13_2 = L9_2
  L14_2 = L10_2
  L15_2 = L11_2
  L12_2, L13_2, L14_2 = L12_2(L13_2, L14_2, L15_2)
  L11_2 = L14_2
  L10_2 = L13_2
  L9_2 = L12_2
  L12_2 = 33
  L13_2 = Airstrike
  L13_2 = L13_2.SpawnOrdnance
  L14_2 = L0_1
  L15_2 = L1_2
  L16_2 = L2_2
  L17_2 = L3_2
  L18_2 = L9_2 * L12_2
  L19_2 = L10_2 * L12_2
  L20_2 = L11_2 * L12_2
  L21_2 = L8_2
  L22_2 = "impact"
  L23_2 = nil
  L25_2 = A0_2
  L24_2 = A0_2.GetOwner
  L24_2 = L24_2(L25_2)
  L25_2 = BombExplodes
  L26_2 = {}
  L27_2 = A0_2
  L26_2[1] = L27_2
  L13_2 = L13_2(L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2)
  A0_2.uSpawnedBomb = L13_2
  L13_2 = Airstrike
  L13_2 = L13_2.SpawnOrdnance
  L14_2 = L0_1
  L15_2 = L1_2 + 3
  L16_2 = L2_2 + 4
  L17_2 = L3_2 + 3
  L18_2 = L9_2 * L12_2
  L18_2 = L18_2 - 2
  L19_2 = L10_2 * L12_2
  L19_2 = L19_2 - 2
  L20_2 = L11_2 * L12_2
  L20_2 = L20_2 - 2
  L21_2 = L8_2
  L22_2 = "impact"
  L23_2 = nil
  L25_2 = A0_2
  L24_2 = A0_2.GetOwner
  L24_2 = L24_2(L25_2)
  L25_2 = BombExplodes
  L26_2 = {}
  L27_2 = A0_2
  L26_2[1] = L27_2
  L13_2 = L13_2(L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2)
  A0_2.uSpawnedBomb = L13_2
end

DropBomb = L2_1

function L2_1(A0_2, A1_2)
end

BombExplodes = L2_1
