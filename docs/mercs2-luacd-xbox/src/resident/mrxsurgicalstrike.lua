local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorSatellite"
L0_1(L1_1)
L0_1 = "Smart Bomb Projectile"
sBomb = L0_1
L0_1 = Pg
L0_1 = L0_1.GetGuidByName
L1_1 = "Smart Bomb Projectile"
L0_1 = L0_1(L1_1)
uBomb = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
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
  L5_2 = L3_2
  L4_2 = L3_2.SetCost
  L6_2 = 0
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetDesignator
  L6_2 = L3_2
  L4_2(L5_2, L6_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetMinigameSectors
  L6_2 = {}
  L7_2 = {}
  L8_2 = 45
  L9_2 = 90
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L8_2 = {}
  L9_2 = 152
  L10_2 = 203
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L9_2 = {}
  L10_2 = 270
  L11_2 = 315
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
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
  L6_2 = "MrxSatelliteGuidedBomb"
  L4_2(L5_2, L6_2)
  L4_2 = A0_2.sDeliveryVehicle
  L2_2.sDeliveryVehicle = L4_2
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = A0_2.sDeliveryVehicle
  L4_2 = L4_2(L5_2)
  L2_2.uDeliveryVehicle = L4_2
  L4_2 = A0_2.sBomb
  L2_2.sBomb = L4_2
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = A0_2.sBomb
  L4_2 = L4_2(L5_2)
  L2_2.uBomb = L4_2
  return L2_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L1_2 = Pg
  L1_2 = L1_2.FindPointFromCamera
  L2_2 = -300
  L3_2 = 8
  L4_2 = -1
  L5_2 = A0_2.uOwner
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  L4_2 = Pg
  L4_2 = L4_2.FindPointFromCamera
  L5_2 = -100
  L6_2 = 80
  L4_2, L5_2, L6_2 = L4_2(L5_2, L6_2)
  L8_2 = A0_2
  L7_2 = A0_2.GetDesignator
  L7_2 = L7_2(L8_2)
  L8_2 = L7_2
  L7_2 = L7_2.GetTarget
  L7_2, L8_2, L9_2 = L7_2(L8_2)
  L10_2 = Airstrike
  L10_2 = L10_2.Flyby
  L11_2 = A0_2.uDeliveryVehicle
  L12_2 = L1_2
  L13_2 = L3_2
  L14_2 = L4_2
  L15_2 = L6_2
  L16_2 = L5_2
  L17_2 = 200
  L18_2 = DropBomb
  L19_2 = {}
  L20_2 = A0_2
  L19_2[1] = L20_2
  L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
  A0_2.uJet = L10_2
  L11_2 = MrxSupport
  L11_2 = L11_2.PlayAirstrikeVO
  L12_2 = L10_2
  L13_2 = {}
  L14_2 = "Misha-None-Freeplay-Support-01"
  L15_2 = "Misha-None-Freeplay-Support-10"
  L16_2 = "Misha-None-Freeplay-Support-21"
  L17_2 = "Misha-None-Freeplay-Support-24"
  L18_2 = "Misha-None-Freeplay-Support-28"
  L19_2 = "Misha-None-Freeplay-Support-32"
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L13_2[3] = L16_2
  L13_2[4] = L17_2
  L13_2[5] = L18_2
  L13_2[6] = L19_2
  L11_2(L12_2, L13_2)
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
  L7_2 = L4_2 - L1_2
  L8_2 = L5_2 - L2_2
  L9_2 = L6_2 - L3_2
  L10_2 = Math
  L10_2 = L10_2.Normalize
  L11_2 = L7_2
  L12_2 = L8_2
  L13_2 = L9_2
  L10_2, L11_2, L12_2 = L10_2(L11_2, L12_2, L13_2)
  L9_2 = L12_2
  L8_2 = L11_2
  L7_2 = L10_2
  L10_2 = uGuid
  A0_2.uTarget = L10_2
  L10_2 = {}
  A0_2.tBombs = L10_2
  L10_2 = A0_2.tBombs
  L11_2 = Airstrike
  L11_2 = L11_2.SpawnOrdnance
  L12_2 = A0_2.uBomb
  L13_2 = L1_2
  L14_2 = L2_2
  L15_2 = L3_2
  L16_2 = L7_2 * 110
  L17_2 = L8_2 * 110
  L18_2 = L9_2 * 110
  L19_2 = "impact"
  L20_2 = 2
  L22_2 = A0_2
  L21_2 = A0_2.GetOwner
  L21_2 = L21_2(L22_2)
  L22_2 = BombExplodes
  L23_2 = {}
  L24_2 = A0_2
  L25_2 = 1
  L23_2[1] = L24_2
  L23_2[2] = L25_2
  L11_2 = L11_2(L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2)
  L10_2[1] = L11_2
end

DropBomb = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = A0_2.tBombs
  L3_2 = L3_2[A1_2]
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  if L2_2 and L3_2 and L4_2 then
    L5_2 = Pg
    L5_2 = L5_2.Spawn
    L6_2 = "Explosion (Grenade)"
    L7_2 = L2_2
    L8_2 = L3_2
    L9_2 = L4_2
    L5_2(L6_2, L7_2, L8_2, L9_2)
  end
end

BombExplodes = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = A0_2.uSpawnedBomb
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  L4_2 = Pg
  L4_2 = L4_2.Spawn
  L5_2 = "Explosion (C4)"
  L6_2 = L1_2
  L7_2 = L2_2
  L8_2 = L3_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
end

FinalExplosion = L0_1
