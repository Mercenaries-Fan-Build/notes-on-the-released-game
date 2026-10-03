local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1
L0_1 = import
L1_1 = "WifEquipmentData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUnlockFanfare"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxStatsManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifMissionFlow"
L0_1(L1_1)
L0_1 = "_pmcoutpost_bld_fueldepot"
L1_1 = "PMC Fuel Tank "
L2_1 = {}
L2_1.All = "Allied"
L2_1.Chi = "China"
L2_1.Civ = "Civilian"
L2_1.Gur = "Guerilla"
L2_1.Oil = "OC"
L2_1.Pir = "Pirate"
L2_1.Pmc = "PMC"
L2_1.Vza = "VZ"
L3_1 = {}
L3_1["[Generic.Collectibles]"] = "[Generic.Collectible]"
L3_1["[Generic.Wagers]"] = "[Generic.Wager]"
L3_1["[Generic.Contracts]"] = "[Generic.Contract]"
L3_1["[Generic.Pickups]"] = "[Generic.Pickup]"
L3_1["[Generic.ShopItems]"] = "[Generic.ShopItem]"
L3_1["[Generic.Bribes]"] = "[Generic.Bribe]"
L3_1["[Generic.Medevacs]"] = "[Generic.Medevac]"
L4_1 = {}
_tEvents = L4_1
L4_1 = {}
_tStockpile = L4_1
L4_1 = {}
_tFreebies = L4_1
L4_1 = {}
_tEquipment = L4_1
L4_1 = {}
_tStockpileThresholdInfo = L4_1
L4_1 = 0
_nLatestCount = L4_1
L4_1 = {}
_tClientSupportSpendings = L4_1
L4_1 = 300
L5_1 = 9999

function L6_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = SetFuelCapacity
  L1_2 = L4_1
  L2_2 = false
  L3_2 = true
  L0_2(L1_2, L2_2, L3_2)
  L0_2 = _CreateHiScoreEvent
  L0_2()
end

Init = L6_1

function L6_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = 1000000000
  L5_2 = math
  L5_2 = L5_2.abs
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  if L4_2 < L5_2 then
    if 0 < A0_2 then
      A0_2 = L4_2
    elseif A0_2 < 0 then
      A0_2 = -L4_2
    end
  end
  L5_2 = GetCashQty
  L5_2 = L5_2()
  L5_2 = L5_2 + A0_2
  if L4_2 < L5_2 then
    L5_2 = L4_2
  elseif L5_2 < 0 then
    L5_2 = 0
  end
  L6_2 = Player
  L6_2 = L6_2.SetCash
  L7_2 = L5_2
  L6_2(L7_2)
  L6_2 = type
  L7_2 = A3_2
  L6_2 = L6_2(L7_2)
  if L6_2 ~= "boolean" then
    A3_2 = false
  end
  if not A3_2 then
    L6_2 = DisplayCash
    L7_2 = Player
    L7_2 = L7_2.GetCash
    L7_2 = L7_2()
    L8_2 = A2_2
    L9_2 = A0_2
    L6_2(L7_2, L8_2, L9_2)
  end
  L6_2 = Event
  L6_2 = L6_2.Post
  L7_2 = "CashAdded"
  L8_2 = {}
  L8_2.nAmtAdded = A0_2
  L6_2(L7_2, L8_2)
  if 0 < A0_2 then
    L6_2 = MrxStatsManager
    L6_2 = L6_2.IncreaseCreditAmount
    L7_2 = A0_2
    L6_2(L7_2)
    if A2_2 then
      L6_2 = MrxStatsManager
      L6_2 = L6_2.ReasonsForCredits
      L7_2 = A2_2
      L8_2 = A0_2
      L6_2(L7_2, L8_2)
    end
  elseif A0_2 < 0 then
    L6_2 = MrxStatsManager
    L6_2 = L6_2.IncreaseDebitAmount
    L7_2 = A0_2
    L6_2(L7_2)
    if A2_2 then
      L6_2 = MrxStatsManager
      L6_2 = L6_2.ReasonsForDebits
      L7_2 = A2_2
      L8_2 = A0_2
      L6_2(L7_2, L8_2)
    end
  end
end

AddCashQty = L6_1

function L6_1()
  local L0_2, L1_2
  L0_2 = Player
  L0_2 = L0_2.GetCash
  return L0_2()
end

GetCashQty = L6_1

function L6_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = GetFuelQty
  L1_2 = L1_2()
  L1_2 = L1_2 + A0_2
  L2_2 = GetFuelCapacity
  L2_2 = L2_2()
  if L1_2 <= L2_2 and 0 <= L1_2 then
    L2_2 = Player
    L2_2 = L2_2.AddFuel
    L3_2 = A0_2
    L2_2(L3_2)
  else
    L2_2 = _nFuelCapacity
    if L1_2 > L2_2 then
      L2_2 = Player
      L2_2 = L2_2.SetFuel
      L3_2 = _nFuelCapacity
      L2_2(L3_2)
    elseif L1_2 < 0 then
      L2_2 = Player
      L2_2 = L2_2.SetFuel
      L3_2 = 0
      L2_2(L3_2)
    end
  end
  if A0_2 < 0 and L1_2 <= 0 then
    L2_2 = MrxTutorialManager
    L2_2 = L2_2.StartTutorial
    L3_2 = "NoFuel"
    L2_2(L3_2)
  elseif A0_2 < 0 then
    L2_2 = _nFuelCapacity
    L2_2 = L1_2 / L2_2
    if L2_2 <= 0.1 then
      L2_2 = MrxTutorialManager
      L2_2 = L2_2.StartTutorial
      L3_2 = "LowFuel"
      L2_2(L3_2)
    end
  end
  L2_2 = DisplayResources
  L3_2 = nil
  L4_2 = A0_2
  L2_2(L3_2, L4_2)
  if 0 < A0_2 then
    L2_2 = MrxStatsManager
    L2_2 = L2_2.IncreaseFuelInAmount
    L3_2 = A0_2
    L2_2(L3_2)
  else
    L2_2 = MrxStatsManager
    L2_2 = L2_2.IncreaseFuelOutAmount
    L3_2 = A0_2
    L2_2(L3_2)
  end
end

AddFuelQty = L6_1

function L6_1()
  local L0_2, L1_2
  L0_2 = Player
  L0_2 = L0_2.GetFuel
  return L0_2()
end

GetFuelQty = L6_1

function L6_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  if not A1_2 then
    L3_2 = L4_1
    if not (A0_2 >= L3_2) then
      goto lbl_24
    end
    L3_2 = L5_1
    if not (A0_2 <= L3_2) then
      goto lbl_24
    end
  end
  _nFuelCapacity = A0_2
  L3_2 = Player
  L3_2 = L3_2.GetFuel
  L3_2 = L3_2()
  L4_2 = _nFuelCapacity
  if L3_2 > L4_2 and not A2_2 then
    L3_2 = Player
    L3_2 = L3_2.SetFuel
    L4_2 = _nFuelCapacity
    L3_2(L4_2)
  end
  L3_2 = true
  do return L3_2 end
  ::lbl_24::
  L3_2 = false
  return L3_2
end

SetFuelCapacity = L6_1

function L6_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = SetFuelCapacity
  L2_2 = GetFuelCapacity
  L2_2 = L2_2()
  L2_2 = L2_2 + A0_2
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    L2_2 = nil
    if 0 < A0_2 then
      L2_2 = L5_1
    elseif A0_2 < 0 then
      L2_2 = L4_1
    end
    L3_2 = SetFuelCapacity
    L4_2 = L2_2
    L3_2(L4_2)
  end
  L2_2 = DisplayResources
  L2_2()
end

AddFuelCapacity = L6_1

function L6_1()
  local L0_2, L1_2
  L0_2 = _nFuelCapacity
  return L0_2
end

GetFuelCapacity = L6_1

function L6_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2
  if not A0_2 then
    return
  end
  L4_2 = _tStockpile
  L4_2 = L4_2[A0_2]
  if L4_2 then
    L4_2 = _tStockpile
    L4_2 = L4_2[A0_2]
    L5_2 = _tStockpile
    L5_2 = L5_2[A0_2]
    L5_2 = L5_2.nAmt
    L5_2 = L5_2 + A1_2
    L4_2.nAmt = L5_2
  else
    L4_2 = _tStockpile
    L5_2 = {}
    L5_2.nAmt = A1_2
    L5_2.bNew = true
    L4_2[A0_2] = L5_2
  end
  L4_2 = Net
  L4_2 = L4_2.IsClient
  L4_2 = L4_2()
  if L4_2 and A3_2 then
    L4_2 = _tClientSupportSpendings
    L4_2 = L4_2[A0_2]
    if not L4_2 then
      L4_2 = _tClientSupportSpendings
      L5_2 = {}
      L5_2.nUnits = 0
      L5_2.nSpent = 0
      L4_2[A0_2] = L5_2
    end
    L4_2 = _tClientSupportSpendings
    L4_2 = L4_2[A0_2]
    L5_2 = _tClientSupportSpendings
    L5_2 = L5_2[A0_2]
    L5_2 = L5_2.nUnits
    L5_2 = L5_2 + A1_2
    L4_2.nUnits = L5_2
    L4_2 = _tClientSupportSpendings
    L4_2 = L4_2[A0_2]
    L5_2 = _tClientSupportSpendings
    L5_2 = L5_2[A0_2]
    L5_2 = L5_2.nSpent
    L5_2 = L5_2 + A3_2
    L4_2.nSpent = L5_2
  end
  L4_2 = Net
  L4_2 = L4_2.IsServer
  L4_2 = L4_2()
  if L4_2 and A2_2 then
    L4_2 = MrxUnlockFanfare
    L4_2 = L4_2.AddUnlockedItem
    L5_2 = {}
    L5_2.sType = "stockpile"
    L5_2.sSupportId = A0_2
    L5_2.nQty = A1_2
    L4_2(L5_2)
  end
  L4_2 = CheckSupportThreshold
  L5_2 = A0_2
  L4_2(L5_2)
  L4_2 = WifMissionFlow
  L4_2 = L4_2.RefreshAllPdaMissionDetails
  L4_2()
end

AddSupportQty = L6_1

function L6_1(A0_2, A1_2)
  local L2_2, L3_2
  if not A0_2 then
    return
  end
  L2_2 = _tStockpile
  L3_2 = _tStockpile
  L3_2 = L3_2[A0_2]
  if not L3_2 then
    L3_2 = {}
  end
  L2_2[A0_2] = L3_2
  L2_2 = _tStockpile
  L2_2 = L2_2[A0_2]
  L2_2.nAmt = A1_2
  L2_2 = CheckSupportThreshold
  L3_2 = A0_2
  L2_2(L3_2)
end

SetSupportQty = L6_1

function L6_1(A0_2)
  local L1_2
  if A0_2 then
    L1_2 = _tStockpile
    L1_2 = L1_2[A0_2]
    if L1_2 then
      L1_2 = _tStockpile
      L1_2 = L1_2[A0_2]
      L1_2 = L1_2.nAmt
      return L1_2
    end
  end
end

GetSupportQty = L6_1

function L6_1(A0_2, A1_2)
  local L2_2
  L2_2 = _tStockpile
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L2_2.bNew = A1_2
  end
end

SetSupportNew = L6_1

function L6_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = pairs
  L1_2 = _tStockpile
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L4_2.bNew = false
  end
end

SetAllSupportViewed = L6_1

function L6_1(A0_2)
  local L1_2, L2_2
  L1_2 = _tStockpile
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L2_2 = L1_2.bNew
    return L2_2
  end
end

IsSupportNew = L6_1

function L6_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = _tStockpileThresholdInfo
  if not L1_2 then
    return
  end
  L1_2 = false
  L2_2 = pairs
  L3_2 = _tStockpileThresholdInfo
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = L6_2[2]
    if L7_2 == A0_2 then
      L8_2 = L6_2[3]
      L9_2 = L6_2[4]
      L10_2 = 0
      L11_2 = _tStockpile
      L11_2 = L11_2[A0_2]
      if L11_2 then
        L11_2 = _tStockpile
        L11_2 = L11_2[A0_2]
        L10_2 = L11_2.nAmt
      end
      if L8_2 == "<" and L9_2 > L10_2 or L8_2 == "<=" and L9_2 >= L10_2 or L8_2 == ">" and L9_2 < L10_2 or L8_2 == ">=" and L9_2 <= L10_2 or L8_2 == "==" and L10_2 == L9_2 then
        L11_2 = L6_2[5]
        if L11_2 == nil then
        end
        L11_2 = MrxUtil
        L11_2 = L11_2.CallWithOptionalArgs
        L12_2 = L6_2[5]
        L13_2 = L6_2[6]
        L11_2(L12_2, L13_2)
        L6_2.bDone = "done"
        L1_2 = true
      end
    end
  end
  if L1_2 == true then
    L2_2 = _tStockpileThresholdInfo
    L2_2 = #L2_2
    while 0 < L2_2 do
      L3_2 = _tStockpileThresholdInfo
      L3_2 = L3_2[L2_2]
      L3_2 = L3_2.bDone
      if L3_2 == "done" then
        L3_2 = table
        L3_2 = L3_2.remove
        L4_2 = _tStockpileThresholdInfo
        L5_2 = L2_2
        L3_2(L4_2, L5_2)
      end
      L2_2 = L2_2 - 1
    end
  end
end

CheckSupportThreshold = L6_1

function L6_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L5_2 = _nLatestCount
  L5_2 = L5_2 + 1
  _nLatestCount = L5_2
  L5_2 = _tStockpileThresholdInfo
  if L5_2 then
    L5_2 = table
    L5_2 = L5_2.insert
    L6_2 = _tStockpileThresholdInfo
    L7_2 = {}
    L8_2 = _nLatestCount
    L9_2 = A0_2
    L10_2 = A1_2
    L11_2 = A2_2
    L12_2 = A3_2
    L13_2 = A4_2
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L7_2[4] = L11_2
    L7_2[5] = L12_2
    L7_2[6] = L13_2
    L5_2(L6_2, L7_2)
  else
    L5_2 = {}
    L6_2 = {}
    L7_2 = _nLatestCount
    L8_2 = A0_2
    L9_2 = A1_2
    L10_2 = A2_2
    L11_2 = A3_2
    L12_2 = A4_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L6_2[4] = L10_2
    L6_2[5] = L11_2
    L6_2[6] = L12_2
    L5_2[1] = L6_2
    _tStockpileThresholdInfo = L5_2
  end
  L5_2 = _nLatestCount
  return L5_2
end

SetStockpileChangeCallback = L6_1

function L6_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = pairs
  L2_2 = _tStockpileThresholdInfo
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L5_2[1]
    if L6_2 == A0_2 then
      L6_2 = table
      L6_2 = L6_2.remove
      L7_2 = _tStockpileThresholdInfo
      L8_2 = L4_2
      L6_2(L7_2, L8_2)
      return
    end
  end
end

DeleteStockpileChangeCallback = L6_1

function L6_1(A0_2, A1_2)
  local L2_2, L3_2
  if not A0_2 then
    return
  end
  L2_2 = _tFreebies
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L2_2 = _tFreebies
    L3_2 = _tFreebies
    L3_2 = L3_2[A0_2]
    L3_2 = L3_2 + A1_2
    L2_2[A0_2] = L3_2
  else
    L2_2 = _tFreebies
    L2_2[A0_2] = A1_2
  end
end

AddFreebieQty = L6_1

function L6_1(A0_2, A1_2)
  local L2_2
  if not A0_2 then
    return
  end
  L2_2 = _tFreebies
  L2_2[A0_2] = A1_2
end

SetFreebieQty = L6_1

function L6_1(A0_2)
  local L1_2
  L1_2 = A0_2 or nil
  if A0_2 then
    L1_2 = _tFreebies
    L1_2 = L1_2[A0_2]
  end
  return L1_2
end

GetFreebieQty = L6_1

function L6_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = WifEquipmentData
  L2_2 = L2_2.GetEquipmentData
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L3_2 = HasEquipment
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    return
  end
  L3_2 = L2_2.nType
  L4_2 = WifEquipmentData
  L4_2 = L4_2.knTypeFuelTank
  if L3_2 == L4_2 then
    if A1_2 then
      L3_2 = AddFuelTank
      L4_2 = A0_2
      L5_2 = false
      L3_2(L4_2, L5_2)
    else
      L3_2 = AddFuelTank
      L4_2 = A0_2
      L5_2 = true
      L3_2(L4_2, L5_2)
    end
    L3_2 = DisplayResources
    L3_2()
  else
    L3_2 = L2_2.nType
    L4_2 = WifEquipmentData
    L4_2 = L4_2.knTypeGrapplingHook
    if L3_2 == L4_2 then
      L3_2 = WifMissionFlow
      L3_2 = L3_2.SetGrappleEnabled
      L4_2 = true
      L3_2(L4_2)
      L3_2 = _tEquipment
      L3_2[A0_2] = true
    else
      L3_2 = _tEquipment
      L3_2[A0_2] = true
    end
  end
end

AddEquipment = L6_1

function L6_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = WifEquipmentData
  L1_2 = L1_2.GetEquipmentData
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L2_2 = _tEquipment
    L2_2 = L2_2[A0_2]
    if L2_2 then
      goto lbl_12
    end
  end
  do return end
  ::lbl_12::
  L2_2 = L1_2.nType
  L3_2 = WifEquipmentData
  L3_2 = L3_2.knTypeFuelTank
  if L2_2 == L3_2 then
    L2_2 = RemoveFuelTank
    L3_2 = A0_2
    L2_2(L3_2)
    L2_2 = DisplayResources
    L2_2()
  else
    L2_2 = _tEquipment
    L2_2[A0_2] = nil
  end
end

RemoveEquipment = L6_1

function L6_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = WifEquipmentData
  L1_2 = L1_2.GetEquipmentData
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = _tEquipment
  L2_2 = L2_2[A0_2]
  if not L2_2 then
    L3_2 = false
    return L3_2
  end
  L3_2 = L1_2.nType
  L4_2 = WifEquipmentData
  L4_2 = L4_2.knTypeFuelTank
  if L3_2 == L4_2 then
    L3_2 = L2_2.bPristine
    return L3_2
  end
  L3_2 = true
  return L3_2
end

HasEquipment = L6_1

function L6_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = MapPluralReasonToSingular
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L3_2 = A1_2
  end
  L4_2 = Hud
  L4_2 = L4_2.ResourceCounter
  L5_2 = L4_2
  L4_2 = L4_2.SetCash
  L6_2 = {}
  L7_2 = A0_2 or L7_2
  if not A0_2 then
    L7_2 = 0
  end
  L6_2.nValue = L7_2
  L6_2.sReason = L3_2
  L6_2.nIncrement = A2_2
  L4_2(L5_2, L6_2)
end

DisplayCash = L6_1

function L6_1(A0_2)
  local L1_2
  if A0_2 then
    L1_2 = L3_1
    L1_2 = L1_2[A0_2]
    return L1_2
  end
end

MapPluralReasonToSingular = L6_1

function L6_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = Hud
  L2_2 = L2_2.ResourceCounter
  L3_2 = L2_2
  L2_2 = L2_2.SetCash
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetCash
  L5_2 = L5_2()
  if not L5_2 then
    L5_2 = 0
  end
  L4_2.nValue = L5_2
  L4_2.nIncrement = A0_2
  L2_2(L3_2, L4_2)
  L2_2 = Hud
  L2_2 = L2_2.ResourceCounter
  L3_2 = L2_2
  L2_2 = L2_2.SetFuel
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetFuel
  L5_2 = L5_2()
  if not L5_2 then
    L5_2 = 0
  end
  L4_2.nValue = L5_2
  L5_2 = GetFuelCapacity
  L5_2 = L5_2()
  L4_2.nMax = L5_2
  L4_2.nIncrement = A1_2
  L2_2(L3_2, L4_2)
end

DisplayResources = L6_1

function L6_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = WifEquipmentData
  L2_2 = L2_2.GetEquipmentData
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  if A1_2 then
    L3_2 = AddFuelCapacity
    L4_2 = L2_2.nFuelCapacity
    L3_2(L4_2)
  end
  L3_2 = _tEquipment
  L3_2 = L3_2[A0_2]
  if not L3_2 then
    L3_2 = {}
  end
  L4_2 = L3_2.uGuid
  if L4_2 then
    L4_2 = L3_2.bPristine
    if L4_2 then
      return
    else
      L4_2 = Object
      L4_2 = L4_2.Remove
      L5_2 = L3_2.uGuid
      L4_2(L5_2)
    end
  end
  L4_2 = MrxUtil
  L4_2 = L4_2.SpawnObject
  L5_2 = L0_1
  L6_2 = L1_1
  L7_2 = L2_2.nFuelTankId
  L6_2 = L6_2 .. L7_2
  L4_2 = L4_2(L5_2, L6_2)
  L3_2.uGuid = L4_2
  L3_2.bPristine = true
  L5_2 = _tEquipment
  L5_2[A0_2] = L3_2
  L5_2 = _nFuelTanks
  if not L5_2 then
    L5_2 = Event
    L5_2 = L5_2.CreatePersistent
    L6_2 = Event
    L6_2 = L6_2.ObjectDeath
    L7_2 = {}
    L8_2 = "FuelTank"
    L7_2[1] = L8_2
    L8_2 = _OnFuelTankDeath
    L5_2 = L5_2(L6_2, L7_2, L8_2)
    _uFuelTankDeath = L5_2
    L5_2 = 0
    _nFuelTanks = L5_2
  end
  L5_2 = _nFuelTanks
  L5_2 = L5_2 + 1
  _nFuelTanks = L5_2
end

AddFuelTank = L6_1

function L6_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = WifEquipmentData
  L1_2 = L1_2.GetEquipmentData
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    return
  end
  L2_2 = AddFuelCapacity
  L3_2 = L1_2.nFuelCapacity
  L3_2 = -L3_2
  L2_2(L3_2)
  L2_2 = _tEquipment
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L2_2 = Object
    L2_2 = L2_2.Remove
    L3_2 = _tEquipment
    L3_2 = L3_2.uGuid
    L2_2(L3_2)
  end
  L2_2 = _tEquipment
  L2_2[A0_2] = nil
  L2_2 = _nFuelTanks
  L2_2 = L2_2 - 1
  _nFuelTanks = L2_2
  L2_2 = _nFuelTanks
  if L2_2 == 0 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = _uFuelTankDeath
    L2_2(L3_2)
    L2_2 = nil
    _nFuelTanks = L2_2
  end
end

RemoveFuelTank = L6_1

function L6_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = pairs
  L2_2 = _tEquipment
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    if L5_2 then
      L6_2 = L5_2.uGuid
      if L6_2 == A0_2 then
        L6_2 = WifEquipmentData
        L6_2 = L6_2.GetEquipmentData
        L7_2 = L4_2
        L6_2 = L6_2(L7_2)
        if not L6_2 then
          return
        end
        L7_2 = AddFuelCapacity
        L8_2 = L6_2.nFuelCapacity
        L8_2 = -L8_2
        L7_2(L8_2)
        L5_2.bPristine = nil
        L7_2 = _nFuelTanks
        L7_2 = L7_2 - 1
        _nFuelTanks = L7_2
        L7_2 = _nFuelTanks
        if L7_2 == 0 then
          L7_2 = Event
          L7_2 = L7_2.Delete
          L8_2 = _uFuelTankDeath
          L7_2(L8_2)
          L7_2 = nil
          _nFuelTanks = L7_2
        end
        return
      end
    end
  end
end

_OnFuelTankDeath = L6_1

function L6_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L0_2 = 0
  L1_2 = _tStockpile
  if not L1_2 then
    L1_2 = 0
    return L1_2
  end
  L1_2 = Net
  L1_2 = L1_2.IsClient
  L1_2 = L1_2()
  if not L1_2 then
    L1_2 = 0
    return L1_2
  end
  L1_2 = pairs
  L2_2 = _tClientSupportSpendings
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = 0
    L7_2 = _tStockpile
    L7_2 = L7_2[L4_2]
    if L7_2 then
      L7_2 = _tStockpile
      L7_2 = L7_2[L4_2]
      L6_2 = L7_2.nAmt
    end
    L7_2 = L5_2.nUnits
    if 0 < L7_2 and 0 < L6_2 then
      L7_2 = 0
      L8_2 = L5_2.nUnits
      if L6_2 >= L8_2 then
        L7_2 = L5_2.nSpent
      else
        L8_2 = L5_2.nSpent
        L9_2 = L5_2.nUnits
        L8_2 = L8_2 / L9_2
        L7_2 = L6_2 * L8_2
      end
      L0_2 = L0_2 + L7_2
    end
  end
  return L0_2
end

GetClientReimburseAmount = L6_1

function L6_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = GetClientReimburseAmount
  L0_2 = L0_2()
  if 0 < L0_2 then
    L1_2 = Player
    L1_2 = L1_2.AddCash
    L2_2 = L0_2
    L1_2(L2_2)
    L1_2 = MrxGui
    L1_2 = L1_2.AddMessage
    L2_2 = {}
    L3_2 = "[green]Stockpile Reimbursement: +$"
    L4_2 = tostring
    L5_2 = L0_2
    L4_2 = L4_2(L5_2)
    L3_2 = L3_2 .. L4_2
    L2_2.sText = L3_2
    L2_2.nDuration = 4
    L1_2(L2_2)
  end
end

NetClientReimburse = L6_1
L6_1 = nil
_oDummyWidget = L6_1

function L6_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = _oDummyWidget
  if L0_2 then
    return
  end
  L0_2 = MrxGui
  L0_2 = L0_2.Widget
  L1_2 = L0_2
  L0_2 = L0_2.new
  L0_2 = L0_2(L1_2)
  _oDummyWidget = L0_2
  L0_2 = MrxGui
  L0_2 = L0_2.AddWidget
  L1_2 = _oDummyWidget
  L0_2(L1_2)
  L0_2 = _oDummyWidget
  L1_2 = L0_2
  L0_2 = L0_2.SetEventHandler
  L2_2 = "UpdateLeaderboard"
  L3_2 = _HiScoreUpdated
  L0_2(L1_2, L2_2, L3_2)
end

_CreateHiScoreEvent = L6_1

function L6_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = Hud
  L2_2 = L2_2.EventFanfare
  L3_2 = L2_2
  L2_2 = L2_2.Commence
  L4_2 = {}
  L4_2.sType = "highscore"
  L5_2 = MrxUtil
  L5_2 = L5_2.FormatMoney
  L6_2 = A1_2.Cash
  L5_2 = L5_2(L6_2)
  L4_2.sText = L5_2
  L2_2(L3_2, L4_2)
end

_HiScoreUpdated = L6_1

function L6_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L0_2 = Player
  L0_2 = L0_2.GetCash
  L0_2 = L0_2()
  L1_2 = Player
  L1_2 = L1_2.GetFuel
  L1_2 = L1_2()
  L2_2 = Player
  L2_2 = L2_2.SetFuelCapacity
  L3_2 = GetFuelCapacity
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L3_2()
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  L2_2 = {}
  L3_2 = pairs
  L4_2 = _tEquipment
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = nil
    L9_2 = type
    L10_2 = L7_2
    L9_2 = L9_2(L10_2)
    if L9_2 ~= "table" then
      L8_2 = L7_2
    else
      L8_2 = L7_2.bPristine
    end
    if L8_2 == true then
      L2_2[L6_2] = true
    end
  end
  L3_2 = {}
  L3_2.tEquipment = L2_2
  L3_2.nCash = L0_2
  L3_2.nFuel = L1_2
  L4_2 = _tStockpile
  L3_2.tStockpile = L4_2
  L4_2 = _tFreebies
  L3_2.tFreebies = L4_2
  return L3_2
end

SaveSingleton = L6_1

function L6_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  if not A0_2 then
    return
  end
  L1_2 = SetFuelCapacity
  L2_2 = Player
  L2_2 = L2_2.GetFuelCapacity
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L2_2()
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  L1_2 = A0_2.tEquipment
  if L1_2 then
    L1_2 = {}
    _tEquipment = L1_2
    L1_2 = pairs
    L2_2 = A0_2.tEquipment
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    for L4_2, L5_2 in L1_2, L2_2, L3_2 do
      L6_2 = AddEquipment
      L7_2 = L4_2
      L8_2 = true
      L6_2(L7_2, L8_2)
    end
  end
  L1_2 = Pg
  L1_2 = L1_2.LoadIsRetry
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = A0_2.nCash
    if L1_2 then
      L1_2 = Player
      L1_2 = L1_2.SetCash
      L2_2 = A0_2.nCash
      L1_2(L2_2)
    end
    L1_2 = A0_2.nFuel
    if L1_2 then
      L1_2 = Player
      L1_2 = L1_2.SetFuel
      L2_2 = A0_2.nFuel
      L1_2(L2_2)
    end
  end
  L1_2 = A0_2.tStockpile
  if L1_2 then
    L1_2 = A0_2.tStockpile
    _tStockpile = L1_2
  end
  L1_2 = A0_2.tFreebies
  if L1_2 then
    L1_2 = A0_2.tFreebies
    _tFreebies = L1_2
  end
  L1_2 = DisplayResources
  L1_2()
end

LoadSingleton = L6_1
