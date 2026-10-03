local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorBeacon"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
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
  L6_2 = "Fiona"
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
  L5_2 = L2_2
  L4_2 = L2_2.SetModuleName
  L6_2 = "MrxArtillery"
  L4_2(L5_2, L6_2)
  return L2_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L1_2 = Player
  L1_2 = L1_2.GetCharacter
  L2_2 = A0_2.uOwner
  L1_2 = L1_2(L2_2)
  A0_2.sAmmo = "Artillery Shell"
  A0_2.nWidth = 25
  L2_2 = 12
  L3_2 = 8
  L5_2 = A0_2
  L4_2 = A0_2.GetDesignator
  L4_2 = L4_2(L5_2)
  L5_2 = L4_2
  L4_2 = L4_2.GetTarget
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  L8_2 = 1
  L9_2 = L2_2
  L10_2 = 1
  for L11_2 = L8_2, L9_2, L10_2 do
    L12_2 = Event
    L12_2 = L12_2.Create
    L13_2 = Event
    L13_2 = L13_2.TimerRelative
    L14_2 = {}
    L15_2 = L3_2 / L2_2
    L15_2 = L11_2 * L15_2
    L15_2 = 3 + L15_2
    L14_2[1] = L15_2
    L15_2 = TriggerFallingMissile
    L16_2 = {}
    L17_2 = A0_2
    L16_2[1] = L17_2
    L12_2(L13_2, L14_2, L15_2, L16_2)
    if L7_2 then
      L12_2 = Player
      L12_2 = L12_2.IsLocal
      L13_2 = A0_2.uOwner
      L12_2 = L12_2(L13_2)
      if L12_2 then
        L12_2 = Event
        L12_2 = L12_2.Create
        L13_2 = Event
        L13_2 = L13_2.TimerRelative
        L14_2 = {}
        L15_2 = 3.5 + L3_2
        L14_2[1] = L15_2
        L15_2 = Object
        L15_2 = L15_2.Remove
        L16_2 = {}
        L17_2 = L7_2
        L16_2[1] = L17_2
        L12_2(L13_2, L14_2, L15_2, L16_2)
      end
    end
  end
  L8_2 = {}
  L9_2 = A0_2.uDeliveryVehicle
  L10_2 = Object
  L10_2 = L10_2.HasLabel
  L11_2 = L9_2
  L12_2 = "Allied"
  L10_2 = L10_2(L11_2, L12_2)
  if L10_2 then
    L10_2 = {}
    L11_2 = "AlliedSoldier01.Support.Incoming01"
    L12_2 = "AlliedSoldier01.Support.Incoming02"
    L13_2 = "AlliedSoldier01.Support.Incoming03"
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L10_2[3] = L13_2
    L8_2 = L10_2
  else
    L10_2 = Object
    L10_2 = L10_2.HasLabel
    L11_2 = L9_2
    L12_2 = "China"
    L10_2 = L10_2(L11_2, L12_2)
    if L10_2 then
      L10_2 = MrxUtil
      L10_2 = L10_2.GetRandomTableElement
      L11_2 = {}
      L12_2 = "ChinaSoldier01.Support.Artillery01"
      L13_2 = "ChinaSoldier01.Support.Artillery02"
      L14_2 = "ChinaSoldier01.Support.Incoming01"
      L15_2 = "ChinaSoldier01.Support.Incoming02"
      L16_2 = "ChinaSoldier01.Support.Incoming03"
      L11_2[1] = L12_2
      L11_2[2] = L13_2
      L11_2[3] = L14_2
      L11_2[4] = L15_2
      L11_2[5] = L16_2
      L10_2 = L10_2(L11_2)
      L8_2 = L10_2
    else
      L10_2 = Object
      L10_2 = L10_2.HasLabel
      L11_2 = L9_2
      L12_2 = "Guerilla"
      L10_2 = L10_2(L11_2, L12_2)
      if L10_2 then
        L10_2 = MrxUtil
        L10_2 = L10_2.GetRandomTableElement
        L11_2 = {}
        L12_2 = "GurSoldier01.Support.Artillery01"
        L13_2 = "GurSoldier01.Support.Artillery02"
        L11_2[1] = L12_2
        L11_2[2] = L13_2
        L10_2 = L10_2(L11_2)
        L8_2 = L10_2
      else
        L10_2 = {}
        L11_2 = "Fiona-In-Mission-Contract-Jet01-03"
        L10_2[1] = L11_2
        L8_2 = L10_2
      end
    end
  end
  L10_2 = MrxVoSequence
  L10_2 = L10_2.Start
  L11_2 = L8_2
  L12_2 = nil
  L13_2 = MrxVoSequence
  L13_2 = L13_2.knPriorityFreeplay
  L14_2 = false
  L10_2(L11_2, L12_2, L13_2, L14_2)
end

DesignationCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L2_2 = A0_2
  L1_2 = A0_2.GetDesignator
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2
  L1_2 = L1_2.GetTarget
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  if L4_2 then
    L5_2 = Object
    L5_2 = L5_2.GetPosition
    L6_2 = L4_2
    L5_2, L6_2, L7_2 = L5_2(L6_2)
    L3_2 = L7_2
    L2_2 = L6_2
    L1_2 = L5_2
  end
  if not L1_2 then
    return
  end
  L5_2 = math
  L5_2 = L5_2.randf
  L5_2 = L5_2()
  L6_2 = A0_2.nWidth
  L5_2 = L5_2 * L6_2
  L5_2 = L1_2 + L5_2
  L6_2 = math
  L6_2 = L6_2.randf
  L6_2 = L6_2()
  L7_2 = A0_2.nWidth
  L6_2 = L6_2 * L7_2
  L1_2 = L5_2 - L6_2
  L5_2 = math
  L5_2 = L5_2.randf
  L5_2 = L5_2()
  L6_2 = A0_2.nWidth
  L5_2 = L5_2 * L6_2
  L5_2 = L3_2 + L5_2
  L6_2 = math
  L6_2 = L6_2.randf
  L6_2 = L6_2()
  L7_2 = A0_2.nWidth
  L6_2 = L6_2 * L7_2
  L3_2 = L5_2 - L6_2
  L5_2 = Airstrike
  L5_2 = L5_2.SpawnOrdnance
  L6_2 = A0_2.sAmmo
  L7_2 = L1_2
  L8_2 = L2_2 + 200
  L9_2 = L3_2
  L10_2 = 0
  L11_2 = -100
  L12_2 = 0
  L13_2 = "impact"
  L14_2 = 1
  L15_2 = A0_2.uOwner
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
end

TriggerFallingMissile = L0_1
