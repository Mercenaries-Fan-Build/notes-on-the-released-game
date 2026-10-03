local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorLaser"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = "Laser Guided Bomb Projectile"
sBomb = L0_1
L0_1 = Pg
L0_1 = L0_1.GetGuidByName
L1_1 = "Laser Guided Bomb Projectile"
L0_1 = L0_1(L1_1)
uBomb = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = {}
  L3_2 = setmetatable
  L4_2 = L2_2
  L5_2 = A0_2
  L3_2(L4_2, L5_2)
  A0_2.__index = A0_2
  L3_2 = MrxSupportDesignatorLaser
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
  L6_2 = "MrxLaserGuidedBomb"
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
  L4_2 = A0_2.tVOCues
  L2_2.tVOCues = L4_2
  return L2_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L1_2 = Pg
  L1_2 = L1_2.FindPointFromCamera
  L2_2 = -300
  L3_2 = 100
  L4_2 = -1
  L5_2 = A0_2.uOwner
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  L4_2 = Pg
  L4_2 = L4_2.FindPointFromCamera
  L5_2 = -100
  L6_2 = 80
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
  L14_2 = 120
  L15_2 = DropBomb
  L16_2 = {}
  L17_2 = A0_2
  L16_2[1] = L17_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
  A0_2.uJet = L7_2
  L8_2 = Event
  L8_2 = L8_2.Create
  L9_2 = Event
  L9_2 = L9_2.TimerRelative
  L10_2 = {}
  L11_2 = 2
  L10_2[1] = L11_2
  L11_2 = MrxSupport
  L11_2 = L11_2.PlayAirstrikeVO
  L12_2 = {}
  L13_2 = L7_2
  L14_2 = {}
  L15_2 = "Misha-None-Freeplay-Support-08"
  L16_2 = "Misha-None-Freeplay-Support-19"
  L17_2 = "Misha-None-Freeplay-Support-21"
  L18_2 = "Misha-None-Freeplay-Support-23"
  L19_2 = "Misha-None-Freeplay-Support-24"
  L20_2 = "Misha-None-Freeplay-Support-30"
  L14_2[1] = L15_2
  L14_2[2] = L16_2
  L14_2[3] = L17_2
  L14_2[4] = L18_2
  L14_2[5] = L19_2
  L14_2[6] = L20_2
  L12_2[1] = L13_2
  L12_2[2] = L14_2
  L8_2(L9_2, L10_2, L11_2, L12_2)
end

DesignationCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2
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
  L9_2 = math
  L9_2 = L9_2.randf
  L9_2 = L9_2()
  L9_2 = L9_2 * 25
  L9_2 = L4_2 + L9_2
  L10_2 = math
  L10_2 = L10_2.randf
  L10_2 = L10_2()
  L10_2 = L10_2 * 25
  L4_2 = L9_2 - L10_2
  L9_2 = math
  L9_2 = L9_2.randf
  L9_2 = L9_2()
  L9_2 = L9_2 * 25
  L9_2 = L5_2 + L9_2
  L10_2 = math
  L10_2 = L10_2.randf
  L10_2 = L10_2()
  L10_2 = L10_2 * 25
  L5_2 = L9_2 - L10_2
  L9_2 = math
  L9_2 = L9_2.randf
  L9_2 = L9_2()
  L9_2 = L9_2 * 25
  L9_2 = L6_2 + L9_2
  L10_2 = math
  L10_2 = L10_2.randf
  L10_2 = L10_2()
  L10_2 = L10_2 * 25
  L6_2 = L9_2 - L10_2
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
  L12_2 = Object
  L12_2 = L12_2.GetPosition
  L13_2 = L7_2
  L12_2, L13_2, L14_2 = L12_2(L13_2)
  L6_2 = L14_2
  L5_2 = L13_2
  L4_2 = L12_2
  A0_2.uTarget = L7_2
  L12_2 = Airstrike
  L12_2 = L12_2.SpawnTargettedOrdnance
  L13_2 = A0_2.uBomb
  L14_2 = L1_2
  L15_2 = L2_2
  L16_2 = L3_2
  L17_2 = L9_2 * 80
  L18_2 = L10_2 * 80
  L19_2 = L11_2 * 80
  L20_2 = L7_2
  L21_2 = "impact"
  L22_2 = 1
  L24_2 = A0_2
  L23_2 = A0_2.GetOwner
  L23_2 = L23_2(L24_2)
  L24_2 = A0_2.BombExplodes
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
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 1.5
  L3_2[1] = L4_2
  L4_2 = CreateDebris
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

BombExplodes = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2
  L1_2 = A0_2.GetDesignator
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2
  L1_2 = L1_2.GetTarget
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  L4_2 = Net
  L4_2 = L4_2.IsClient
  L4_2 = L4_2()
  if not L4_2 then
    L4_2 = MrxUtil
    L4_2 = L4_2.GetDistanceToObject
    L5_2 = Player
    L5_2 = L5_2.GetLocalCharacter
    L5_2 = L5_2()
    L6_2 = L1_2
    L7_2 = L2_2
    L8_2 = L3_2
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
    if not (150 < L4_2) then
      goto lbl_22
    end
  end
  do return end
  ::lbl_22::
  L4_2 = Object
  L4_2 = L4_2.GetPosition
  L5_2 = Player
  L5_2 = L5_2.GetLocalCharacter
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L5_2()
  L4_2, L5_2, L6_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  L3_2 = L6_2
  L2_2 = L5_2
  L1_2 = L4_2
  L4_2 = Graphics
  L4_2 = L4_2.Effect
  L4_2 = L4_2.Terrain
  L5_2 = "global_particle_dustfall"
  L6_2 = 20
  L7_2 = 0.005
  L8_2 = L1_2
  L9_2 = 8
  L10_2 = L3_2
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
end

CreateDebris = L0_1
