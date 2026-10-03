local L0_1, L1_1
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxRewardData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxShop"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = {}
L1_1 = {}
L1_1.c4 = 3
L0_1.OilJob008 = L1_1
L1_1 = {}
L1_1.gl = 1
L1_1.extgl = 1
L1_1.upcombatairpatrol = 2
L0_1.OilCon001 = L1_1
L1_1 = {}
L1_1.c4 = 1
L0_1.OilCon051 = L1_1
L1_1 = {}
L1_1.extgl = 1
L0_1.OilCon003 = L1_1
L1_1 = {}
L1_1.uptankbuster = 1
L1_1.artillery = 3
L1_1.stingrayii = 1
L0_1.OilCon052 = L1_1
L1_1 = {}
L1_1.artillery = 3
L0_1.GurJob020 = L1_1
L1_1 = {}
L1_1.uptankbuster = 3
L1_1.c4 = 2
L1_1.upcombatairpatrol = 1
L0_1.GurCon002 = L1_1
L1_1 = {}
L1_1.artillery = 4
L1_1.piranha = 2
L1_1.upcombatairpatrol = 2
L1_1.c4 = 3
L0_1.GurCon001 = L1_1
L1_1 = {}
L1_1.uptankbuster = 1
L1_1.c4 = 1
L0_1.GurCon050 = L1_1
L1_1 = {}
L1_1.sniperch = 1
L1_1.coandaattack = 1
L0_1.GurCon005 = L1_1
L1_1 = {}
L1_1.daisycutter = 1
L1_1.endriagoattack = 1
L0_1.GurCon052 = L1_1
L1_1 = {}
L1_1.artillery = 3
L1_1.patrolboatvz = 1
L1_1.alouette3transportvz = 1
L1_1.sniperru = 2
L1_1.c4 = 2
L1_1.pr = 1
L0_1.PmcCon002 = L1_1
L1_1 = {}
L1_1.gl = 1
L1_1.daisycutter = 1
L0_1.PirCon051 = L1_1
L1_1 = {}
L1_1.artillery = 1
L1_1.patrolboatvz = 1
L1_1.c4 = 1
L1_1.strategicmissile = 1
L0_1.PirCon052 = L1_1
L1_1 = {}
L1_1.mi35 = 2
L1_1.patrolboatvz = 2
L1_1.artillery = 2
L0_1.JetCon001 = L1_1
L1_1 = {}
L1_1.alouette3superiority = 2
L1_1.combatairpatrol = 2
L1_1.tankbuster = 2
L0_1.PmcCon003 = L1_1
L1_1 = {}
L1_1.surgicalstrike = 3
L0_1.AllJob020 = L1_1
L1_1 = {}
L1_1.smartbomb = 3
L1_1.laserguidedbomb = 3
L1_1.laviiimgs = 1
L0_1.AllCon002 = L1_1
L1_1 = {}
L1_1.laserguidedbomb = 3
L1_1.carpetbomb = 1
L1_1.wz10 = 2
L1_1.atal = 2
L1_1.dinghy = 2
L0_1.AllCon001 = L1_1
L1_1 = {}
L1_1.moab = 1
L1_1.tankbuster = 2
L1_1.laserguidedbomb = 2
L1_1.surgicalstrike = 3
L0_1.AllCon003 = L1_1
L1_1 = {}
L1_1.fuelairbomb = 3
L0_1.ChiJob020 = L1_1
L1_1 = {}
L1_1.rocketartillery = 3
L1_1.mh53j = 1
L1_1.cruisemissile = 3
L1_1.atch = 2
L0_1.ChiCon001 = L1_1
L1_1 = {}
L1_1.carpetbomb = 2
L1_1.strategicmissile = 3
L1_1.fuelairbomb = 5
L1_1.cruisemissile = 3
L1_1.atch = 3
L0_1.ChiCon002 = L1_1
L1_1 = {}
L1_1.fuelairbomb = 3
L1_1.smartbomb = 3
L0_1.ChiCon003 = L1_1
_tRecommendations = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = _tRecommendations
  L1_2 = L1_2[A0_2]
  L1_2 = L1_2 ~= nil
  return L1_2
end

HasRecommendations = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = _tRecommendations
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    return
  end
  L2_2 = ""
  L3_2 = true
  L4_2 = pairs
  L5_2 = L1_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = _FormatLineItem
    L10_2 = L7_2
    L11_2 = L8_2
    L9_2, L10_2 = L9_2(L10_2, L11_2)
    if L10_2 ~= nil and L3_2 then
      L3_2 = L10_2
    end
    if L9_2 then
      L11_2 = L2_2
      L12_2 = L9_2
      L13_2 = "\n"
      L2_2 = L11_2 .. L12_2 .. L13_2
    end
  end
  L4_2 = L2_2
  L5_2 = L3_2
  return L4_2, L5_2
end

GenerateRecommendationString = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L2_2 = MrxSupportData
  L2_2 = L2_2.GetPlayerVisibleName
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L3_2 = MrxSupportData
  L3_2 = L3_2.tSupportData
  L3_2 = L3_2[A0_2]
  if not L3_2 then
    return
  end
  L4_2 = false
  L5_2 = L3_2.sType
  if L5_2 then
    L5_2 = {}
    L5_2.Airstrike = "[airstrike]"
    L5_2.Supply = "[supply]"
    L5_2.Light = "[vehmlight]"
    L5_2.Heavy = "[vehmheavy]"
    L5_2.Civilian = "[vehcivilian]"
    L5_2.Boat = "[vehboat]"
    L5_2.Heli = "[vehheli]"
    L6_2 = L3_2.sType
    L6_2 = L5_2[L6_2]
    if L6_2 then
      L7_2 = L6_2
      L8_2 = " "
      L9_2 = L2_2
      L2_2 = L7_2 .. L8_2 .. L9_2
      L4_2 = true
    end
  end
  L5_2 = {}
  L6_2 = {}
  L7_2 = "Pmc"
  L8_2 = "Oil"
  L9_2 = "Gur"
  L10_2 = "Pir"
  L11_2 = "All"
  L12_2 = "Chi"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L6_2[5] = L11_2
  L6_2[6] = L12_2
  L7_2 = ipairs
  L8_2 = L6_2
  L7_2, L8_2, L9_2 = L7_2(L8_2)
  for L10_2, L11_2 in L7_2, L8_2, L9_2 do
    L12_2 = MrxShop
    L12_2 = L12_2.GetNumberOfUnlockedItems
    L13_2 = L11_2
    L12_2 = L12_2(L13_2)
    if 0 < L12_2 then
      L12_2 = MrxRewardData
      L12_2 = L12_2.GetAllPotentialShopItems
      L13_2 = L11_2
      L12_2, L13_2 = L12_2(L13_2)
      L14_2 = ipairs
      L15_2 = L12_2
      L14_2, L15_2, L16_2 = L14_2(L15_2)
      for L17_2, L18_2 in L14_2, L15_2, L16_2 do
        if L18_2 == A0_2 then
          L19_2 = table
          L19_2 = L19_2.insert
          L20_2 = L5_2
          L21_2 = L11_2
          L19_2(L20_2, L21_2)
          break
        end
      end
    end
  end
  L7_2 = #L5_2
  if 0 < L7_2 then
    L7_2 = L2_2
    L8_2 = [[

[indent] [PDA.Map.RecommendationsSoldBy] ]]
    L2_2 = L7_2 .. L8_2
    L7_2 = ipairs
    L8_2 = L5_2
    L7_2, L8_2, L9_2 = L7_2(L8_2)
    for L10_2, L11_2 in L7_2, L8_2, L9_2 do
      L12_2 = MrxFactionManager
      L12_2 = L12_2.GetInlineIcon
      L13_2 = L11_2
      L12_2 = L12_2(L13_2)
      L13_2 = L2_2
      L14_2 = L12_2
      L2_2 = L13_2 .. L14_2
    end
  end
  L7_2 = nil
  if A1_2 then
    L8_2 = MrxPmc
    L8_2 = L8_2.GetSupportQty
    L9_2 = A0_2
    L8_2 = L8_2(L9_2)
    if not L8_2 then
      L8_2 = 0
    end
    L9_2 = "[check0]"
    L7_2 = false
    if A1_2 <= L8_2 then
      L9_2 = "[check1]"
      L7_2 = true
    end
    L10_2 = L9_2
    L11_2 = " "
    L12_2 = A1_2
    L13_2 = " x "
    L10_2 = L10_2 .. L11_2 .. L12_2 .. L13_2
    if not L4_2 then
      L11_2 = L10_2
      L12_2 = " "
      L10_2 = L11_2 .. L12_2
    end
    L11_2 = L10_2
    L12_2 = L2_2
    L2_2 = L11_2 .. L12_2
  end
  L8_2 = L2_2
  L9_2 = L7_2
  return L8_2, L9_2
end

_FormatLineItem = L0_1
