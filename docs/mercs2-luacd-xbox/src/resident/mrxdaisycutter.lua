local L0_1, L1_1, L2_1, L3_1
L0_1 = inherit
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorSmoke"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = "Daisy Cutter Projectile"
L1_1 = "Explosion (Daisy Cutter)"
L2_1 = "Support Vehicle (C130)"

function L3_1(A0_2, A1_2)
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
  L4_2 = L3_2.SetValidationFunction
  L6_2 = _NoValidation
  L4_2(L5_2, L6_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetAATestLevel
  L6_2 = "basic"
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
  L6_2 = "Fiona"
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetModuleName
  L6_2 = "MrxDaisyCutter"
  L4_2(L5_2, L6_2)
  L4_2 = L2_1
  L2_2.sDeliveryVehicle = L4_2
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = L2_1
  L4_2 = L4_2(L5_2)
  L2_2.uDeliveryVehicle = L4_2
  L4_2 = L0_1
  L2_2.sBomb = L4_2
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = L0_1
  L4_2 = L4_2(L5_2)
  L2_2.uBomb = L4_2
  return L2_2
end

Create = L3_1

function L3_1(A0_2)
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
  L14_2 = 80
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
  L11_2 = ""
  L10_2[1] = L11_2
  L8_2(L9_2, L10_2)
end

DesignationCallback = L3_1

function L3_1(A0_2)
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
  L12_2 = 20
  L13_2 = Airstrike
  L13_2 = L13_2.SpawnOrdnance
  L14_2 = A0_2.uBomb
  L15_2 = L1_2
  L16_2 = L2_2
  L17_2 = L3_2
  L18_2 = L9_2
  L19_2 = L10_2
  L20_2 = L11_2
  L21_2 = L8_2
  L22_2 = "impact"
  L23_2 = A0_2.uOwner
  L24_2 = BombExplodes
  L25_2 = {}
  L26_2 = A0_2
  L25_2[1] = L26_2
  L13_2 = L13_2(L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2)
  A0_2.uSpawnedBomb = L13_2
end

DropBomb = L3_1

function L3_1(A0_2)
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

BombExplodes = L3_1

function L3_1(A0_2)
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

CreateDebris = L3_1
