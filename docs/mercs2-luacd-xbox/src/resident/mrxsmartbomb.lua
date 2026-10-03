local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorBeacon"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = {}
  L3_2 = setmetatable
  L4_2 = L2_2
  L5_2 = A0_2
  L3_2(L4_2, L5_2)
  A0_2.__index = A0_2
  L3_2 = MrxSupportDesignatorBeacon
  L4_2 = L3_2
  L3_2 = L3_2.Create
  L3_2 = L3_2(L4_2)
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
  L6_2 = "MrxSmartBomb"
  L4_2(L5_2, L6_2)
  L2_2.sBomb = "Laser Guided Bomb Projectile"
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "Laser Guided Bomb Projectile"
  L4_2 = L4_2(L5_2)
  L2_2.uBomb = L4_2
  return L2_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L1_2 = math
  L1_2 = L1_2.randi
  L2_2 = 360
  L1_2 = L1_2(L2_2)
  L2_2 = Pg
  L2_2 = L2_2.FindPointFromCamera
  L3_2 = 300
  L4_2 = 25
  L5_2 = -1
  L6_2 = A0_2.uOwner
  L7_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L5_2 = Pg
  L5_2 = L5_2.FindPointFromCamera
  L6_2 = 100
  L7_2 = 80
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
  L14_2 = L6_2 + 150
  L15_2 = 50
  L16_2 = DropBomb
  L17_2 = {}
  L18_2 = A0_2
  L17_2[1] = L18_2
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  A0_2.uJet = L8_2
  L8_2 = MrxSupport
  L8_2 = L8_2.PlayAirstrikeVO
  L9_2 = A0_2.uJet
  L10_2 = {}
  L11_2 = "Misha-None-Freeplay-Support-12"
  L12_2 = "Misha-None-Freeplay-Support-20"
  L13_2 = "Misha-None-Freeplay-Support-21"
  L14_2 = "Misha-None-Freeplay-Support-01"
  L15_2 = "Misha-None-Freeplay-Support-07"
  L16_2 = "Misha-None-Freeplay-Support-10"
  L17_2 = "Misha-None-Freeplay-Support-23"
  L18_2 = "Misha-None-Freeplay-Support-27"
  L19_2 = "Misha-None-Freeplay-Support-28"
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L10_2[5] = L15_2
  L10_2[6] = L16_2
  L10_2[7] = L17_2
  L10_2[8] = L18_2
  L10_2[9] = L19_2
  L8_2(L9_2, L10_2)
end

DesignationCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2
  L2_2 = A0_2
  L1_2 = A0_2.GetDesignator
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2
  L1_2 = L1_2.GetTarget
  L1_2, L2_2, L3_2, L4_2, L5_2 = L1_2(L2_2)
  L6_2 = Object
  L6_2 = L6_2.GetPosition
  L7_2 = A0_2.uJet
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  L9_2 = L1_2 - L6_2
  L10_2 = L2_2 - L7_2
  L11_2 = L3_2 - L8_2
  L12_2 = Math
  L12_2 = L12_2.Normalize
  L13_2 = L9_2
  L14_2 = L10_2
  L15_2 = L11_2
  L12_2, L13_2, L14_2 = L12_2(L13_2, L14_2, L15_2)
  L11_2 = L14_2
  L10_2 = L13_2
  L9_2 = L12_2
  L12_2 = Airstrike
  L12_2 = L12_2.SpawnTargettedOrdnance
  L13_2 = "Smart Bomb Projectile"
  L14_2 = L6_2
  L15_2 = L7_2
  L16_2 = L8_2
  L17_2 = L9_2
  L18_2 = L10_2
  L19_2 = L11_2
  L20_2 = L4_2
  L21_2 = "impact"
  L22_2 = L5_2
  L23_2 = A0_2.uOwner
  L24_2 = BombExplodes
  L25_2 = {}
  L26_2 = A0_2
  L25_2[1] = L26_2
  L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2)
  A0_2.uSpawnedBomb = L12_2
  L12_2 = BlipAircraft
  L13_2 = A0_2.uSpawnedBomb
  L14_2 = {}
  L15_2 = 255
  L16_2 = 0
  L17_2 = 0
  L14_2[1] = L15_2
  L14_2[2] = L16_2
  L14_2[3] = L17_2
  L12_2(L13_2, L14_2)
end

DropBomb = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2.GetDesignator
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2
  L1_2 = L1_2.GetTarget
  L1_2, L2_2, L3_2, L4_2, L5_2 = L1_2(L2_2)
  if L4_2 then
    L6_2 = Player
    L6_2 = L6_2.IsLocal
    L7_2 = A0_2.uOwner
    L6_2 = L6_2(L7_2)
    if L6_2 then
      L6_2 = Object
      L6_2 = L6_2.Remove
      L7_2 = L4_2
      L6_2(L7_2)
    end
  end
end

BombExplodes = L0_1
