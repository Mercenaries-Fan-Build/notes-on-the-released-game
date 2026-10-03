local L0_1, L1_1
L0_1 = import
L1_1 = "WifMissionData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifEquipmentData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxRewardData"
L0_1(L1_1)
L0_1 = {}
L0_1.Airstrike = "[airstrike] "
L0_1.Supply = "[supply] "
L0_1.Light = "[vehmlight] "
L0_1.Heavy = "[vehmheavy] "
L0_1.Civilian = "[vehcivilian] "
L0_1.Boat = "[vehboat] "
L0_1.Heli = "[vehheli] "
L1_1 = WifEquipmentData
L1_1 = L1_1.knTypeFuelTank
L0_1[L1_1] = "[fuelsilo] "
tTypeToIcon = L0_1
L0_1 = {}
_tGlobalShopList = L0_1
L0_1 = nil
_oVender = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L0_2 = MrxFactionManager
  L0_2 = L0_2.GetFactionAbbrevs
  L0_2 = L0_2()
  L1_2 = pairs
  L2_2 = L0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = _tGlobalShopList
    L7_2 = {}
    L8_2 = {}
    L8_2.nSupport = 0
    L9_2 = {}
    L8_2.tSupport = L9_2
    L8_2.nEquipment = 0
    L9_2 = {}
    L8_2.tEquipment = L9_2
    L7_2.tPurchased = L8_2
    L6_2[L5_2] = L7_2
  end
end

Init = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2
  _oVender = A0_2
  L3_2 = Player
  L3_2 = L3_2.GetLocalPlayer
  L3_2 = L3_2()
  L4_2 = Hud
  L4_2 = L4_2.Shop
  L5_2 = L4_2
  L4_2 = L4_2.Create
  L6_2 = {}
  L6_2.uPlayer = L3_2
  L4_2(L5_2, L6_2)
  L4_2 = Hud
  L4_2 = L4_2.Shop
  L5_2 = L4_2
  L4_2 = L4_2.SetCallback
  L6_2 = {}
  L6_2.uPlayer = L3_2
  L7_2 = _ShopSelection
  L6_2.fCallback = L7_2
  L7_2 = {}
  L6_2.tCallbackData = L7_2
  L4_2(L5_2, L6_2)
  L4_2 = Hud
  L4_2 = L4_2.Shop
  L5_2 = L4_2
  L4_2 = L4_2.SetCloseCallback
  L6_2 = {}
  L6_2.uPlayer = L3_2
  
  function L7_2()
    local L0_3, L1_3, L2_3
    _oVender = L0_3
    L0_3 = MrxUtil
    L0_3 = L0_3.CallWithOptionalArgs
    L1_3 = A1_2
    L2_3 = A2_2
    L0_3(L1_3, L2_3)
  end
  
  L6_2.fCallback = L7_2
  L4_2(L5_2, L6_2)
  L5_2 = A0_2
  L4_2 = A0_2.GetFaction
  L4_2 = L4_2(L5_2)
  L6_2 = A0_2
  L5_2 = A0_2.HasCustomVehicleShop
  L5_2 = L5_2(L6_2)
  L6_2 = _GetPriceScale
  L7_2 = A0_2
  L6_2 = L6_2(L7_2)
  L7_2 = _GetShopList
  L8_2 = A0_2
  L7_2 = L7_2(L8_2)
  L8_2 = 1
  L9_2 = {}
  L10_2 = {}
  L11_2 = {}
  L12_2 = {}
  L13_2 = pairs
  L14_2 = L7_2.tSupport
  L13_2, L14_2, L15_2 = L13_2(L14_2)
  for L16_2, L17_2 in L13_2, L14_2, L15_2 do
    L18_2 = MrxSupportData
    L18_2 = L18_2.tSupportData
    L18_2 = L18_2[L16_2]
    if L18_2 == nil then
    else
      L19_2 = nil
      L20_2 = Net
      L20_2 = L20_2.IsClient
      L20_2 = L20_2()
      if L20_2 then
        L20_2 = _tIndexedShopList
        L19_2 = L20_2[L8_2]
      else
        L20_2 = MrxSupportData
        L20_2 = L20_2.IsItemUnlocked
        L21_2 = L16_2
        L22_2 = L4_2
        L20_2 = L20_2(L21_2, L22_2)
        L19_2 = L20_2
      end
      L20_2 = L18_2.sName
      L21_2 = L18_2.sDescription
      L22_2 = L16_2
      L23_2 = tTypeToIcon
      L24_2 = L18_2.sType
      L23_2 = L23_2[L24_2]
      if not L19_2 and L5_2 then
        L20_2 = "[Shop.LockedItem]"
        L21_2 = "[Shop.LockedItem]"
        L22_2 = "Locked"
        L23_2 = nil
      end
      if not L23_2 then
        L23_2 = ""
      end
      L24_2 = MrxSupportData
      L24_2 = L24_2.IsItemNew
      L25_2 = L16_2
      L26_2 = L4_2
      L24_2 = L24_2(L25_2, L26_2)
      if L24_2 then
        L25_2 = MrxSupportData
        L25_2 = L25_2.SetItemViewed
        L26_2 = L16_2
        L27_2 = L4_2
        L25_2(L26_2, L27_2)
      end
      L25_2 = nil
      if L19_2 then
        L25_2 = L9_2
      else
        L25_2 = L10_2
      end
      L26_2 = table
      L26_2 = L26_2.insert
      L27_2 = L25_2
      L28_2 = {}
      L28_2.uPlayer = L3_2
      L29_2 = L23_2
      L30_2 = L20_2
      L29_2 = L29_2 .. L30_2
      L28_2.sName = L29_2
      L28_2.sId = L22_2
      L28_2.sDescription = L21_2
      L29_2 = L18_2.sIcon
      L28_2.sTexture = L29_2
      L29_2 = L18_2.nCashCost
      L29_2 = L29_2 * L6_2
      L28_2.nCashCost = L29_2
      L29_2 = MrxPmc
      L29_2 = L29_2.GetSupportQty
      L30_2 = L16_2
      L29_2 = L29_2(L30_2)
      if not L29_2 then
        L29_2 = 0
      end
      L28_2.nCurrentStock = L29_2
      L29_2 = L18_2.nMaxStock
      L28_2.nMaxStock = L29_2
      L28_2.bFuelTank = false
      L28_2.bUnlocked = L19_2
      L28_2.bMarkAsNew = L24_2
      L28_2.sRawName = L20_2
      L26_2(L27_2, L28_2)
      L8_2 = L8_2 + 1
    end
  end
  L13_2 = pairs
  L14_2 = L7_2.tEquipment
  L13_2, L14_2, L15_2 = L13_2(L14_2)
  for L16_2, L17_2 in L13_2, L14_2, L15_2 do
    L18_2 = WifEquipmentData
    L18_2 = L18_2.GetEquipmentData
    L19_2 = L16_2
    L18_2 = L18_2(L19_2)
    if L18_2 == nil then
    else
      L19_2 = nil
      L20_2 = Net
      L20_2 = L20_2.IsClient
      L20_2 = L20_2()
      if L20_2 then
        L20_2 = _tIndexedShopList
        L19_2 = L20_2[L8_2]
      else
        L20_2 = WifEquipmentData
        L20_2 = L20_2.IsItemUnlocked
        L21_2 = L16_2
        L22_2 = L4_2
        L20_2 = L20_2(L21_2, L22_2)
        L19_2 = L20_2
      end
      L20_2 = L18_2.sName
      L21_2 = L18_2.sDescription
      L22_2 = L16_2
      L23_2 = tTypeToIcon
      L24_2 = L18_2.nType
      L23_2 = L23_2[L24_2]
      if not L19_2 and L5_2 then
        L20_2 = "[Shop.LockedItem]"
        L21_2 = "[Shop.LockedItem]"
        L22_2 = "Locked"
        L23_2 = nil
      end
      L24_2 = WifEquipmentData
      L24_2 = L24_2.IsItemNew
      L25_2 = L16_2
      L26_2 = L4_2
      L24_2 = L24_2(L25_2, L26_2)
      if L24_2 then
        L25_2 = WifEquipmentData
        L25_2 = L25_2.SetItemViewed
        L26_2 = L16_2
        L27_2 = L4_2
        L25_2(L26_2, L27_2)
      end
      if not L23_2 then
        L23_2 = ""
      end
      L25_2 = 0
      L26_2 = MrxPmc
      L26_2 = L26_2.HasEquipment
      L27_2 = L16_2
      L26_2 = L26_2(L27_2)
      if L26_2 then
        L25_2 = 1
      end
      L26_2 = nil
      if L19_2 then
        L26_2 = L11_2
      else
        L26_2 = L12_2
      end
      L27_2 = L18_2.nType
      L28_2 = WifEquipmentData
      L28_2 = L28_2.knTypeFuelTank
      L27_2 = L27_2 == L28_2
      L28_2 = L18_2.nType
      L29_2 = WifEquipmentData
      L29_2 = L29_2.knTypeGrapplingHook
      L28_2 = L28_2 == L29_2
      L29_2 = L27_2 or L29_2
      L29_2 = L28_2 or L29_2
      L29_2 = not L27_2 and L28_2 and L25_2 == 0
      L30_2 = Net
      L30_2 = L30_2.IsClient
      L30_2 = L30_2()
      if L30_2 and L28_2 then
        L29_2 = false
      end
      if L29_2 then
        L30_2 = table
        L30_2 = L30_2.insert
        L31_2 = L26_2
        L32_2 = {}
        L32_2.uPlayer = L3_2
        L33_2 = L23_2
        L34_2 = L20_2
        L33_2 = L33_2 .. L34_2
        L32_2.sName = L33_2
        L32_2.sId = L22_2
        L32_2.sDescription = L21_2
        L33_2 = L18_2.sTexture
        L32_2.sTexture = L33_2
        L33_2 = L18_2.nCost
        L33_2 = L33_2 * L6_2
        L32_2.nCashCost = L33_2
        L32_2.nCurrentStock = L25_2
        L32_2.nMaxStock = 1
        L32_2.bFuelTank = L27_2
        L32_2.bUnlocked = L19_2
        L32_2.bMarkAsNew = L24_2
        L33_2 = L18_2.nFuelCapacity
        L32_2.nFuelQuantity = L33_2
        L32_2.sRawName = L20_2
        L30_2(L31_2, L32_2)
        L8_2 = L8_2 + 1
      end
    end
  end
  
  function L13_2(A0_3, A1_3)
    local L2_3, L3_3
    L2_3 = A0_3.nCashCost
    L3_3 = A1_3.nCashCost
    L2_3 = L2_3 < L3_3
    return L2_3
  end
  
  L14_2 = table
  L14_2 = L14_2.sort
  L15_2 = L9_2
  L16_2 = L13_2
  L14_2(L15_2, L16_2)
  L14_2 = table
  L14_2 = L14_2.sort
  L15_2 = L10_2
  L16_2 = L13_2
  L14_2(L15_2, L16_2)
  L14_2 = table
  L14_2 = L14_2.sort
  L15_2 = L11_2
  L16_2 = L13_2
  L14_2(L15_2, L16_2)
  L14_2 = table
  L14_2 = L14_2.sort
  L15_2 = L12_2
  L16_2 = L13_2
  L14_2(L15_2, L16_2)
  L14_2 = ipairs
  L15_2 = L9_2
  L14_2, L15_2, L16_2 = L14_2(L15_2)
  for L17_2, L18_2 in L14_2, L15_2, L16_2 do
    L19_2 = Hud
    L19_2 = L19_2.Shop
    L20_2 = L19_2
    L19_2 = L19_2.AddItemFull
    L21_2 = L18_2
    L19_2(L20_2, L21_2)
  end
  L14_2 = ipairs
  L15_2 = L11_2
  L14_2, L15_2, L16_2 = L14_2(L15_2)
  for L17_2, L18_2 in L14_2, L15_2, L16_2 do
    L19_2 = Hud
    L19_2 = L19_2.Shop
    L20_2 = L19_2
    L19_2 = L19_2.AddItemFull
    L21_2 = L18_2
    L19_2(L20_2, L21_2)
  end
  L14_2 = ipairs
  L15_2 = L10_2
  L14_2, L15_2, L16_2 = L14_2(L15_2)
  for L17_2, L18_2 in L14_2, L15_2, L16_2 do
    L19_2 = Hud
    L19_2 = L19_2.Shop
    L20_2 = L19_2
    L19_2 = L19_2.AddItemFull
    L21_2 = L18_2
    L19_2(L20_2, L21_2)
  end
  L14_2 = ipairs
  L15_2 = L12_2
  L14_2, L15_2, L16_2 = L14_2(L15_2)
  for L17_2, L18_2 in L14_2, L15_2, L16_2 do
    L19_2 = Hud
    L19_2 = L19_2.Shop
    L20_2 = L19_2
    L19_2 = L19_2.AddItemFull
    L21_2 = L18_2
    L19_2(L20_2, L21_2)
  end
  L14_2 = Hud
  L14_2 = L14_2.Shop
  L15_2 = L14_2
  L14_2 = L14_2.Commence
  L16_2 = {}
  L16_2.uPlayer = L3_2
  L14_2(L15_2, L16_2)
end

Open = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = {}
  L2_2.nSupport = 0
  L3_2 = {}
  L2_2.tSupport = L3_2
  L2_2.nEquipment = 0
  L3_2 = {}
  L2_2.tEquipment = L3_2
  if A0_2 and not A1_2 then
    L4_2 = A0_2
    L3_2 = A0_2.GetFaction
    L3_2 = L3_2(L4_2)
    A1_2 = L3_2
  end
  L3_2 = nil
  L4_2 = nil
  if A1_2 then
    L5_2 = MrxRewardData
    L5_2 = L5_2.GetAllPotentialShopItems
    L6_2 = A1_2
    L5_2, L6_2 = L5_2(L6_2)
    L4_2 = L6_2
    L3_2 = L5_2
  end
  if L3_2 then
    L5_2 = ipairs
    L6_2 = L3_2
    L5_2, L6_2, L7_2 = L5_2(L6_2)
    for L8_2, L9_2 in L5_2, L6_2, L7_2 do
      L10_2 = L2_2.tSupport
      L10_2 = L10_2[L9_2]
      if not L10_2 then
        L10_2 = L2_2.tSupport
        L10_2[L9_2] = true
        L10_2 = L2_2.nSupport
        L10_2 = L10_2 + 1
        L2_2.nSupport = L10_2
      end
    end
  end
  if L4_2 then
    L5_2 = ipairs
    L6_2 = L4_2
    L5_2, L6_2, L7_2 = L5_2(L6_2)
    for L8_2, L9_2 in L5_2, L6_2, L7_2 do
      L10_2 = L2_2.tEquipment
      L10_2 = L10_2[L9_2]
      if not L10_2 then
        L10_2 = L2_2.tEquipment
        L10_2[L9_2] = true
        L10_2 = L2_2.nEquipment
        L10_2 = L10_2 + 1
        L2_2.nEquipment = L10_2
      end
    end
  end
  return L2_2
end

_GetShopList = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2.HasCustomVehicleShop
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = 1
    return L1_2
  end
  L2_2 = A0_2
  L1_2 = A0_2.GetFaction
  L1_2 = L1_2(L2_2)
  L2_2 = MrxFactionManager
  L2_2 = L2_2.GetPriceScale
  L3_2 = L1_2
  L4_2 = "Pmc"
  return L2_2(L3_2, L4_2)
end

_GetPriceScale = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  if A0_2 == "Locked" then
    L2_2 = false
    return L2_2
  end
  L2_2 = _GetPriceScale
  L3_2 = _oVender
  L2_2 = L2_2(L3_2)
  L3_2 = MrxSupportData
  L3_2 = L3_2.tSupportData
  L3_2 = L3_2[A0_2]
  L4_2 = WifEquipmentData
  L4_2 = L4_2.GetEquipmentData
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if L3_2 then
    L5_2 = L3_2.nCashCost
    L5_2 = L5_2 * L2_2
    L5_2 = L5_2 * A1_2
    L6_2 = MrxPmc
    L6_2 = L6_2.GetCashQty
    L6_2 = L6_2()
    if L5_2 <= L6_2 then
      L6_2 = MrxPmc
      L6_2 = L6_2.AddSupportQty
      L7_2 = A0_2
      L8_2 = A1_2
      L9_2 = false
      L10_2 = L5_2
      L6_2(L7_2, L8_2, L9_2, L10_2)
      L6_2 = MrxPmc
      L6_2 = L6_2.AddCashQty
      L7_2 = -L5_2
      L8_2 = nil
      L9_2 = "[Generic.ShopItems]"
      L6_2(L7_2, L8_2, L9_2)
      L6_2 = _AddPurchasedSupportItem
      L7_2 = A0_2
      L6_2(L7_2)
      L6_2 = true
      return L6_2
    end
  elseif L4_2 then
    L5_2 = L4_2.nCost
    L5_2 = L5_2 * L2_2
    L5_2 = L5_2 * A1_2
    L6_2 = MrxPmc
    L6_2 = L6_2.GetCashQty
    L6_2 = L6_2()
    if L5_2 <= L6_2 then
      L6_2 = MrxPmc
      L6_2 = L6_2.AddEquipment
      L7_2 = A0_2
      L6_2(L7_2)
      L6_2 = MrxPmc
      L6_2 = L6_2.AddCashQty
      L7_2 = -L5_2
      L8_2 = nil
      L9_2 = "[Generic.ShopItems]"
      L6_2(L7_2, L8_2, L9_2)
      L6_2 = _AddPurchasedEquipmentItem
      L7_2 = A0_2
      L6_2(L7_2)
      L6_2 = true
      return L6_2
    end
  end
  L5_2 = false
  return L5_2
end

_ShopSelection = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = _tGlobalShopList
  L2_2 = _oVender
  L3_2 = L2_2
  L2_2 = L2_2.GetFaction
  L2_2 = L2_2(L3_2)
  L1_2 = L1_2[L2_2]
  if not L1_2 then
    return
  end
  L2_2 = L1_2.tPurchased
  L2_2 = L2_2.tSupport
  L2_2 = L2_2[A0_2]
  if L2_2 then
    return
  end
  L2_2 = L1_2.tPurchased
  L3_2 = L1_2.tPurchased
  L3_2 = L3_2.nSupport
  L3_2 = L3_2 + 1
  L2_2.nSupport = L3_2
  L2_2 = L1_2.tPurchased
  L2_2 = L2_2.tSupport
  L2_2[A0_2] = true
end

_AddPurchasedSupportItem = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = _tGlobalShopList
  L2_2 = _oVender
  L3_2 = L2_2
  L2_2 = L2_2.GetFaction
  L2_2 = L2_2(L3_2)
  L1_2 = L1_2[L2_2]
  if not L1_2 then
    return
  end
  L2_2 = L1_2.tPurchased
  L2_2 = L2_2.tEquipment
  L2_2 = L2_2[A0_2]
  if L2_2 then
    return
  end
  L2_2 = L1_2.tPurchased
  L3_2 = L1_2.tPurchased
  L3_2 = L3_2.nEquipment
  L3_2 = L3_2 + 1
  L2_2.nEquipment = L3_2
  L2_2 = L1_2.tPurchased
  L2_2 = L2_2.tEquipment
  L2_2[A0_2] = true
end

_AddPurchasedEquipmentItem = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = Player
  L0_2 = L0_2.GetLocalPlayer
  L0_2 = L0_2()
  L1_2 = Hud
  L1_2 = L1_2.Shop
  L2_2 = L1_2
  L1_2 = L1_2.Close
  L3_2 = {}
  L3_2.uPlayer = L0_2
  L1_2(L2_2, L3_2)
end

Close = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = _GetShopList
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = {}
  L3_2 = 1
  L5_2 = A0_2
  L4_2 = A0_2.GetFaction
  L4_2 = L4_2(L5_2)
  L5_2 = pairs
  L6_2 = L1_2.tSupport
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = MrxSupportData
    L10_2 = L10_2.IsItemUnlocked
    L11_2 = L8_2
    L12_2 = L4_2
    L10_2 = L10_2(L11_2, L12_2)
    L2_2[L3_2] = L10_2
    L3_2 = L3_2 + 1
  end
  L5_2 = pairs
  L6_2 = L1_2.tEquipment
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = WifEquipmentData
    L10_2 = L10_2.IsItemUnlocked
    L11_2 = L8_2
    L12_2 = L4_2
    L10_2 = L10_2(L11_2, L12_2)
    L2_2[L3_2] = L10_2
    L3_2 = L3_2 + 1
  end
  return L2_2
end

GetIndexedShopList = L0_1

function L0_1(A0_2)
  local L1_2
  _tIndexedShopList = A0_2
end

SetIndexedShopList = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = _tGlobalShopList
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    L2_2 = -1
    return L2_2
  end
  L2_2 = L1_2.nTotalItems
  if not L2_2 then
    L2_2 = _GetShopList
    L3_2 = nil
    L4_2 = A0_2
    L2_2 = L2_2(L3_2, L4_2)
    L3_2 = L2_2.nSupport
    L4_2 = L2_2.nEquipment
    L3_2 = L3_2 + L4_2
    L1_2.nTotalItems = L3_2
  end
  L2_2 = L1_2.nTotalItems
  return L2_2
end

GetTotalNumberOfItems = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = _tGlobalShopList
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    L2_2 = -1
    return L2_2
  end
  L2_2 = L1_2.tPurchased
  L2_2 = L2_2.nSupport
  L3_2 = L1_2.tPurchased
  L3_2 = L3_2.nEquipment
  L2_2 = L2_2 + L3_2
  return L2_2
end

GetNumberOfPurchasedItems = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = _GetShopList
  L2_2 = nil
  L3_2 = A0_2
  L1_2 = L1_2(L2_2, L3_2)
  L2_2 = 0
  L3_2 = pairs
  L4_2 = L1_2.tSupport
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = MrxSupportData
    L8_2 = L8_2.IsItemUnlocked
    L9_2 = L6_2
    L10_2 = A0_2
    L8_2 = L8_2(L9_2, L10_2)
    if L8_2 then
      L2_2 = L2_2 + 1
    end
  end
  L3_2 = pairs
  L4_2 = L1_2.tEquipment
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = WifEquipmentData
    L8_2 = L8_2.IsItemUnlocked
    L9_2 = L6_2
    L10_2 = A0_2
    L8_2 = L8_2(L9_2, L10_2)
    if L8_2 then
      L2_2 = L2_2 + 1
    end
  end
  return L2_2
end

GetNumberOfUnlockedItems = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _tGlobalShopList
  return L0_2
end

SaveSingleton = L0_1

function L0_1(A0_2)
  local L1_2
  _tGlobalShopList = A0_2
end

LoadSingleton = L0_1
