local L0_1, L1_1, L2_1, L3_1, L4_1
L0_1 = inherit
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorBeacon"
L0_1(L1_1)
L0_1 = "Cruise Missile Projectile"
L1_1 = "Explosion (Cruise Missile)"
L2_1 = "Support Vehicle (Cruise Missile)"
L3_1 = Pg
L3_1 = L3_1.GetGuidByName
L4_1 = "Support Vehicle (Cruise Missile)"
L3_1 = L3_1(L4_1)

function L4_1(A0_2, A1_2)
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
  L6_2 = "Fiona"
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetModuleName
  L6_2 = "MrxCruiseMissile"
  L4_2(L5_2, L6_2)
  L4_2 = A0_2.sDeliveryVehicle
  if not L4_2 then
    L4_2 = "Fiona"
  end
  L2_2.sDeliveryVehicle = L4_2
  L4_2 = A0_2.sDeliveryVehicle
  if L4_2 then
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = A0_2.sDeliveryVehicle
    L4_2 = L4_2(L5_2)
    L2_2.uDeliveryVehicle = L4_2
  else
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "Fiona"
    L4_2 = L4_2(L5_2)
    L2_2.uDeliveryVehicle = L4_2
  end
  L4_2 = A0_2.sBomb
  L2_2.sBomb = L4_2
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = A0_2.sBomb
  L4_2 = L4_2(L5_2)
  L2_2.uBomb = L4_2
  return L2_2
end

Create = L4_1

function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2
  L1_2 = 20
  L2_2 = 100
  L3_2 = Pg
  L3_2 = L3_2.FindPointFromCamera
  L4_2 = 300
  L5_2 = 25
  L6_2 = -1
  L7_2 = A0_2.uOwner
  L8_2 = math
  L8_2 = L8_2.randi
  L9_2 = 180
  L8_2 = L8_2(L9_2)
  L8_2 = 720 + L8_2
  L3_2, L4_2, L5_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  L7_2 = A0_2
  L6_2 = A0_2.GetDesignator
  L6_2 = L6_2(L7_2)
  L7_2 = L6_2
  L6_2 = L6_2.GetTarget
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  L9_2 = L8_2 - L5_2
  L9_2 = L9_2 * -1
  L10_2 = L6_2 - L3_2
  L11_2 = Math
  L11_2 = L11_2.Normalize
  L12_2 = L9_2
  L13_2 = 0
  L14_2 = L10_2
  L11_2, L12_2, L13_2 = L11_2(L12_2, L13_2, L14_2)
  L11_2 = L11_2 * L1_2
  L13_2 = L13_2 * L1_2
  L14_2 = L3_2 - L6_2
  L15_2 = 0
  L16_2 = L5_2 - L8_2
  L17_2 = Math
  L17_2 = L17_2.Normalize
  L18_2 = L14_2
  L19_2 = 0
  L20_2 = L16_2
  L17_2, L18_2, L19_2 = L17_2(L18_2, L19_2, L20_2)
  L16_2 = L19_2
  L15_2 = L18_2
  L14_2 = L17_2
  L14_2 = L14_2 * L2_2
  L16_2 = L16_2 * L2_2
  L17_2 = Airstrike
  L17_2 = L17_2.Flyby
  L18_2 = "Support Vehicle (Cruise Missile)"
  L19_2 = L3_2
  L20_2 = L5_2
  L21_2 = L3_2 + L11_2
  L22_2 = L6_2 - L3_2
  L21_2 = L21_2 + L22_2
  L21_2 = L21_2 + L14_2
  L22_2 = L5_2 + L13_2
  L23_2 = L8_2 - L5_2
  L22_2 = L22_2 + L23_2
  L22_2 = L22_2 + L16_2
  L23_2 = L7_2 + 150
  L24_2 = 50
  L25_2 = DropBomb
  L26_2 = {}
  L27_2 = A0_2
  L26_2[1] = L27_2
  L17_2 = L17_2(L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2)
  A0_2.uJet = L17_2
  L17_2 = {}
  L18_2 = A0_2.uDeliveryVehicle
  L19_2 = Object
  L19_2 = L19_2.HasLabel
  L20_2 = L18_2
  L21_2 = "Allied"
  L19_2 = L19_2(L20_2, L21_2)
  if L19_2 then
    L19_2 = {}
    L20_2 = "AlliedSoldier01.Support.Incoming01"
    L21_2 = "AlliedSoldier01.Support.Incoming03"
    L19_2[1] = L20_2
    L19_2[2] = L21_2
    L17_2 = L19_2
  else
    L19_2 = Object
    L19_2 = L19_2.HasLabel
    L20_2 = L18_2
    L21_2 = "China"
    L19_2 = L19_2(L20_2, L21_2)
    if L19_2 then
      L19_2 = MrxUtil
      L19_2 = L19_2.GetRandomTableElement
      L20_2 = {}
      L21_2 = "ChinaSoldier01.Support.Artillery01"
      L22_2 = "ChinaSoldier01.Support.Incoming01"
      L23_2 = "ChinaSoldier01.Support.Incoming02"
      L24_2 = "ChinaSoldier01.Support.Incoming03"
      L20_2[1] = L21_2
      L20_2[2] = L22_2
      L20_2[3] = L23_2
      L20_2[4] = L24_2
      L19_2 = L19_2(L20_2)
      L17_2 = L19_2
    else
      L19_2 = {}
      L20_2 = "Fiona-In-Mission-Contract-Jet01-03"
      L19_2[1] = L20_2
      L17_2 = L19_2
    end
  end
  L19_2 = MrxVoSequence
  L19_2 = L19_2.Start
  L20_2 = L17_2
  L21_2 = nil
  L22_2 = MrxVoSequence
  L22_2 = L22_2.knPriorityFreeplay
  L23_2 = false
  L19_2(L20_2, L21_2, L22_2, L23_2)
end

DesignationCallback = L4_1

function L4_1(A0_2)
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
  L9_2 = Object
  L9_2 = L9_2.Remove
  L10_2 = A0_2.uJet
  L9_2(L10_2)
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
  L13_2 = L0_1
  L14_2 = L6_2
  L15_2 = L7_2
  L16_2 = L8_2
  L17_2 = L9_2
  L18_2 = L10_2
  L19_2 = L11_2
  L20_2 = L4_2
  L21_2 = "impact"
  L22_2 = 0
  L23_2 = A0_2.uOwner
  L24_2 = BombExplodes
  L25_2 = {}
  L26_2 = A0_2
  L25_2[1] = L26_2
  L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2)
  A0_2.uSpawnedBomb = L12_2
end

DropBomb = L4_1

function L4_1(A0_2)
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

BombExplodes = L4_1
