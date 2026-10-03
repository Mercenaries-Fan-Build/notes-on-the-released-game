local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1, L18_1, L19_1, L20_1, L21_1, L22_1, L23_1, L24_1, L25_1, L26_1, L27_1, L28_1, L29_1
L0_1 = import
L1_1 = "MrxShop"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTransit"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVerifyManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxStarterManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifMissionData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxAchievements"
L0_1(L1_1)
L0_1 = 0
L1_1 = 100
L2_1 = {}
L2_1.Vza = "VZA"
L2_1.Pmc = "PMC"
L2_1.Pir = "PIR"
L2_1.Oil = "OIL"
L2_1.Gur = "GUR"
L2_1.Civ = "CIV"
L2_1.Chi = "CHI"
L2_1.All = "ALL"
L3_1 = {}
L3_1.Vza = 0
L3_1.Pmc = 0
L3_1.Pir = 0
L3_1.Oil = 0
L3_1.Gur = 0
L3_1.Civ = 0
L3_1.Chi = 0
L3_1.All = 0
L4_1 = {}
L4_1.Vza = 0
L4_1.Pmc = 0
L4_1.Pir = 11
L4_1.Oil = 13
L4_1.Gur = 13
L4_1.Civ = 0
L4_1.Chi = 8
L4_1.All = 24
L5_1 = 25
L6_1 = 10
L7_1 = 2
L8_1 = 3
L9_1 = 5
L10_1 = 1
L11_1 = 3
L12_1 = L5_1 + L6_1
L12_1 = L12_1 + L7_1
L12_1 = L12_1 + L8_1
L12_1 = L12_1 + L9_1
L12_1 = L12_1 + L10_1
L12_1 = L12_1 + L11_1
L13_1 = {}
L14_1 = 0
L15_1 = 0
L16_1 = 0
L17_1 = 0
L18_1 = 0
L19_1 = 0
L20_1 = 0
L21_1 = 0
L22_1 = 0
L23_1 = 0
L24_1 = {}
L24_1["[Generic.CopterRepair]"] = 0
L24_1["[Generic.Collateral]"] = 0
L24_1["[Generic.Bribes]"] = 0
L24_1["[Generic.Wagers]"] = 0
L24_1["[Generic.Medevacs]"] = 0
L24_1["[Generic.ShopItems]"] = 0
L24_1["[Garage.replacefionacar]"] = 0
L24_1["[Generic.SupportDesignators.Satellite]"] = 0
L25_1 = {}
L25_1["[Generic.Contracts]"] = 0
L25_1["[Generic.Wagers]"] = 0
L25_1["[Generic.Collectibles]"] = 0
L25_1["[Generic.Pickups]"] = 0
L26_1 = {}
L26_1.AllCon008 = 0
L26_1.ChiCon008 = 0
L26_1.GurCon003 = 0
L26_1.OilCon005 = 0
L26_1.PirCon001 = 0
L26_1.PmcCon015 = 0
L26_1.PmcCon016 = 0
L27_1 = {}
L28_1 = {}

function L29_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = bActivated
  if L0_2 then
    return
  end
  L0_2 = true
  bActivated = L0_2
  L0_2 = MrxFactionManager
  L0_2 = L0_2.GetFactionAbbrevs
  L0_2 = L0_2()
  L1_2 = pairs
  L2_2 = L0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L2_1
    L7_2 = MrxFactionManager
    L7_2 = L7_2.GetShortPlayerVisibleName
    L8_2 = L5_2
    L7_2 = L7_2(L8_2)
    L6_2[L5_2] = L7_2
  end
end

Activated = L29_1

function L29_1(A0_2)
  local L1_2, L2_2
  if A0_2 then
    L1_2 = A0_2.tDestroyBty
    L3_1 = L1_2
    L1_2 = A0_2.nCompletedToolboxes
    L0_1 = L1_2
    L1_2 = MrxVerifyManager
    L1_2 = L1_2.LoadSingleton
    L2_2 = A0_2.oVerifyData
    L1_2(L2_2)
    L1_2 = A0_2.tFavWeapon
    L27_1 = L1_2
    L1_2 = A0_2.tFavVehicle
    L28_1 = L1_2
    L1_2 = A0_2.nTotalCredit
    L15_1 = L1_2
    L1_2 = A0_2.tListOfCredits
    L25_1 = L1_2
    L1_2 = A0_2.nTotalDebit
    L16_1 = L1_2
    L1_2 = A0_2.tListOfDebits
    L24_1 = L1_2
    L1_2 = A0_2.nOutpostCaptured
    L14_1 = L1_2
    L1_2 = A0_2.nFuelIn
    L17_1 = L1_2
    L1_2 = A0_2.nFuelOut
    L18_1 = L1_2
    L1_2 = Pg
    L1_2 = L1_2.LoadIsRetry
    L1_2 = L1_2()
    if not L1_2 then
      L1_2 = A0_2.nDeaths
      L19_1 = L1_2
      L1_2 = A0_2.nRetries
      L21_1 = L1_2
    end
    L1_2 = A0_2.nMedevacs
    L20_1 = L1_2
    L1_2 = A0_2.nTransit
    L22_1 = L1_2
    L1_2 = A0_2.tListOfRaces
    L26_1 = L1_2
    L1_2 = A0_2.nBestRaceTime
    L23_1 = L1_2
  end
end

LoadSingleton = L29_1

function L29_1()
  local L0_2, L1_2
  L0_2 = {}
  L1_2 = L3_1
  L0_2.tDestroyBty = L1_2
  L1_2 = L0_1
  L0_2.nCompletedToolboxes = L1_2
  L1_2 = MrxVerifyManager
  L1_2 = L1_2.SaveSingleton
  L1_2 = L1_2()
  L0_2.oVerifyData = L1_2
  L1_2 = L27_1
  L0_2.tFavWeapon = L1_2
  L1_2 = L28_1
  L0_2.tFavVehicle = L1_2
  L1_2 = L15_1
  L0_2.nTotalCredit = L1_2
  L1_2 = L25_1
  L0_2.tListOfCredits = L1_2
  L1_2 = L16_1
  L0_2.nTotalDebit = L1_2
  L1_2 = L24_1
  L0_2.tListOfDebits = L1_2
  L1_2 = L14_1
  L0_2.nOutpostCaptured = L1_2
  L1_2 = L17_1
  L0_2.nFuelIn = L1_2
  L1_2 = L18_1
  L0_2.nFuelOut = L1_2
  L1_2 = L19_1
  L0_2.nDeaths = L1_2
  L1_2 = L20_1
  L0_2.nMedevacs = L1_2
  L1_2 = L21_1
  L0_2.nRetries = L1_2
  L1_2 = L22_1
  L0_2.nTransit = L1_2
  L1_2 = L26_1
  L0_2.tListOfRaces = L1_2
  L1_2 = L23_1
  L0_2.nBestRaceTime = L1_2
  return L0_2
end

SaveSingleton = L29_1

function L29_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    L1_2 = 0
    return L1_2
  end
  L1_2 = 0
  L2_2 = pairs
  L3_2 = A0_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2 in L2_2, L3_2, L4_2 do
    L1_2 = L1_2 + 1
  end
  return L1_2
end

_GetTableSizeSlow = L29_1

function L29_1()
  local L0_2, L1_2
  L0_2 = WifMissionData
  L0_2 = L0_2.GetNumContracts
  L0_2 = L0_2()
  L0_2 = L0_2 - 1
  return L0_2
end

GetTotalNumContracts = L29_1

function L29_1()
  local L0_2, L1_2
  L0_2 = MrxVerifyManager
  L0_2 = L0_2.GetTotal
  L0_2 = L0_2()
  L0_2 = L0_2 - 1
  return L0_2
end

GetTotalNumHVTs = L29_1

function L29_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2
  L0_2 = 0
  L1_2 = pairs
  L2_2 = MrxStarterManager
  L2_2 = L2_2.GetStarters
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2 = L2_2()
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L5_2.bPmcStarter
    if L6_2 then
      L0_2 = L0_2 + 1
    end
  end
  L1_2 = MrxFactionManager
  L1_2 = L1_2.GetFactionAbbrevs
  L1_2 = L1_2()
  L2_2 = 0
  L3_2 = 0
  L4_2 = pairs
  L5_2 = L1_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = L3_1
    L9_2 = L9_2[L8_2]
    L2_2 = L2_2 + L9_2
    L9_2 = L4_1
    L9_2 = L9_2[L8_2]
    L3_2 = L3_2 + L9_2
  end
  L4_2 = MrxFactionManager
  L4_2 = L4_2.GetFactionAbbrevs
  L4_2 = L4_2()
  L5_2 = {}
  L6_2 = ipairs
  L7_2 = L4_2
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  for L9_2, L10_2 in L6_2, L7_2, L8_2 do
    L11_2 = {}
    L12_2 = MrxShop
    L12_2 = L12_2.GetNumberOfUnlockedItems
    L13_2 = L10_2
    L12_2 = L12_2(L13_2)
    L11_2.nUnlocked = L12_2
    L12_2 = MrxShop
    L12_2 = L12_2.GetTotalNumberOfItems
    L13_2 = L10_2
    L12_2 = L12_2(L13_2)
    L11_2.nTotal = L12_2
    L5_2[L10_2] = L11_2
  end
  L6_2 = 0
  L7_2 = 0
  L8_2 = pairs
  L9_2 = L5_2
  L8_2, L9_2, L10_2 = L8_2(L9_2)
  for L11_2, L12_2 in L8_2, L9_2, L10_2 do
    L13_2 = L12_2.nTotal
    if 0 < L13_2 then
      L13_2 = L12_2.nUnlocked
      L6_2 = L6_2 + L13_2
      L13_2 = L12_2.nTotal
      L7_2 = L7_2 + L13_2
    end
  end
  L8_2 = {}
  L9_2 = {}
  L10_2 = MrxVerifyManager
  L10_2 = L10_2.GetTotalFactionVZA
  L10_2 = L10_2()
  if not L10_2 then
    L10_2 = 0
  end
  L9_2.nTotal = L10_2
  L10_2 = MrxVerifyManager
  L10_2 = L10_2.GetCompletedVZA
  L10_2 = L10_2()
  L9_2.nCompleted = L10_2
  L8_2.Vza = L9_2
  L9_2 = {}
  L10_2 = MrxVerifyManager
  L10_2 = L10_2.GetTotalFactionPMC
  L10_2 = L10_2()
  if not L10_2 then
    L10_2 = 0
  end
  L9_2.nTotal = L10_2
  L10_2 = MrxVerifyManager
  L10_2 = L10_2.GetCompletedPMC
  L10_2 = L10_2()
  L9_2.nCompleted = L10_2
  L8_2.Pmc = L9_2
  L9_2 = {}
  L10_2 = MrxVerifyManager
  L10_2 = L10_2.GetTotalFactionPIR
  L10_2 = L10_2()
  if not L10_2 then
    L10_2 = 0
  end
  L9_2.nTotal = L10_2
  L10_2 = MrxVerifyManager
  L10_2 = L10_2.GetCompletedPIR
  L10_2 = L10_2()
  L9_2.nCompleted = L10_2
  L8_2.Pir = L9_2
  L9_2 = {}
  L10_2 = MrxVerifyManager
  L10_2 = L10_2.GetTotalFactionOIL
  L10_2 = L10_2()
  if not L10_2 then
    L10_2 = 0
  end
  L9_2.nTotal = L10_2
  L10_2 = MrxVerifyManager
  L10_2 = L10_2.GetCompletedOIL
  L10_2 = L10_2()
  L9_2.nCompleted = L10_2
  L8_2.Oil = L9_2
  L9_2 = {}
  L10_2 = MrxVerifyManager
  L10_2 = L10_2.GetTotalFactionGUR
  L10_2 = L10_2()
  if not L10_2 then
    L10_2 = 0
  end
  L9_2.nTotal = L10_2
  L10_2 = MrxVerifyManager
  L10_2 = L10_2.GetCompletedGUR
  L10_2 = L10_2()
  L9_2.nCompleted = L10_2
  L8_2.Gur = L9_2
  L9_2 = {}
  L10_2 = MrxVerifyManager
  L10_2 = L10_2.GetTotalFactionCIV
  L10_2 = L10_2()
  if not L10_2 then
    L10_2 = 0
  end
  L9_2.nTotal = L10_2
  L10_2 = MrxVerifyManager
  L10_2 = L10_2.GetCompletedCIV
  L10_2 = L10_2()
  L9_2.nCompleted = L10_2
  L8_2.Civ = L9_2
  L9_2 = {}
  L10_2 = MrxVerifyManager
  L10_2 = L10_2.GetTotalFactionCHI
  L10_2 = L10_2()
  if not L10_2 then
    L10_2 = 0
  end
  L9_2.nTotal = L10_2
  L10_2 = MrxVerifyManager
  L10_2 = L10_2.GetCompletedCHI
  L10_2 = L10_2()
  L9_2.nCompleted = L10_2
  L8_2.Chi = L9_2
  L9_2 = {}
  L10_2 = MrxVerifyManager
  L10_2 = L10_2.GetTotalFactionALL
  L10_2 = L10_2()
  if not L10_2 then
    L10_2 = 0
  end
  L9_2.nTotal = L10_2
  L10_2 = MrxVerifyManager
  L10_2 = L10_2.GetCompletedALL
  L10_2 = L10_2()
  L9_2.nCompleted = L10_2
  L8_2.All = L9_2
  L9_2 = L0_1
  L10_2 = "/"
  L11_2 = L1_1
  L9_2 = L9_2 .. L10_2 .. L11_2
  L10_2 = WifMissionData
  L10_2 = L10_2.GetNumCompletedContracts
  L10_2 = L10_2()
  L11_2 = GetTotalNumContracts
  L11_2 = L11_2()
  L10_2 = L10_2 / L11_2
  L11_2 = L0_2 / 4
  L12_2 = L6_2 / L7_2
  L13_2 = L2_2 / L3_2
  L14_2 = MrxVerifyManager
  L14_2 = L14_2.GetCompletedTotal
  L14_2 = L14_2()
  L15_2 = GetTotalNumHVTs
  L15_2 = L15_2()
  L14_2 = L14_2 / L15_2
  L15_2 = L0_1
  L16_2 = L1_1
  L15_2 = L15_2 / L16_2
  L16_2 = 0
  L17_2 = MrxTransit
  L17_2 = L17_2.GetUnlockedLocations
  L17_2 = L17_2()
  L18_2 = MrxTransit
  L18_2 = L18_2.GetUnlockableLocations
  L18_2 = L18_2()
  if L17_2 and L18_2 then
    L19_2 = _GetTableSizeSlow
    L20_2 = L17_2
    L19_2 = L19_2(L20_2)
    L20_2 = _GetTableSizeSlow
    L21_2 = L18_2
    L20_2 = L20_2(L21_2)
    L16_2 = L19_2 / L20_2
  end
  L19_2 = L5_1
  L19_2 = L10_2 * L19_2
  L20_2 = L6_1
  L20_2 = L11_2 * L20_2
  L19_2 = L19_2 + L20_2
  L20_2 = L7_1
  L20_2 = L12_2 * L20_2
  L19_2 = L19_2 + L20_2
  L20_2 = L8_1
  L20_2 = L13_2 * L20_2
  L19_2 = L19_2 + L20_2
  L20_2 = L9_1
  L20_2 = L14_2 * L20_2
  L19_2 = L19_2 + L20_2
  L20_2 = L10_1
  L20_2 = L15_2 * L20_2
  L19_2 = L19_2 + L20_2
  L20_2 = L11_1
  L20_2 = L16_2 * L20_2
  L19_2 = L19_2 + L20_2
  L20_2 = L12_1
  L19_2 = L19_2 / L20_2
  L20_2 = math
  L20_2 = L20_2.min
  L21_2 = L19_2
  L22_2 = 1
  return L20_2(L21_2, L22_2)
end

GetPercentCompleted = L29_1

function L29_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2
  L1_2 = "[PDA.Database.Score_Progress]"
  L2_2 = bAddedProgressCategory
  if not L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.AddStatisticCategory
    L4_2 = L1_2
    L2_2(L3_2, L4_2)
    L2_2 = Activated
    L2_2()
    L2_2 = true
    bAddedProgressCategory = L2_2
  end
  L2_2 = MrxUtil
  L2_2 = L2_2.FormatMoney
  L3_2 = MrxPmc
  L3_2 = L3_2.GetCashQty
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2 = L3_2()
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2)
  L3_2 = MrxPmc
  L3_2 = L3_2.GetFuelQty
  L3_2 = L3_2()
  L4_2 = "/"
  L5_2 = MrxPmc
  L5_2 = L5_2.GetFuelCapacity
  L5_2 = L5_2()
  L3_2 = L3_2 .. L4_2 .. L5_2
  L5_2 = A0_2
  L4_2 = A0_2.AddStatisticEntry
  L6_2 = L1_2
  L7_2 = "[Generic.Cash]"
  L8_2 = L2_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L5_2 = A0_2
  L4_2 = A0_2.AddStatisticEntry
  L6_2 = L1_2
  L7_2 = "[Generic.Fuel]"
  L8_2 = L3_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = Net
  L4_2 = L4_2.IsClient
  L4_2 = L4_2()
  if not L4_2 then
    L4_2 = WifMissionData
    L4_2 = L4_2.GetNumCompletedContracts
    L4_2 = L4_2()
    L5_2 = "/"
    L6_2 = GetTotalNumContracts
    L6_2 = L6_2()
    L4_2 = L4_2 .. L5_2 .. L6_2
    L5_2 = 0
    L6_2 = pairs
    L7_2 = MrxStarterManager
    L7_2 = L7_2.GetStarters
    L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2 = L7_2()
    L6_2, L7_2, L8_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2)
    for L9_2, L10_2 in L6_2, L7_2, L8_2 do
      L11_2 = L10_2.bPmcStarter
      if L11_2 then
        L5_2 = L5_2 + 1
      end
    end
    L6_2 = L5_2
    L7_2 = "/4"
    L6_2 = L6_2 .. L7_2
    L7_2 = MrxFactionManager
    L7_2 = L7_2.GetFactionAbbrevs
    L7_2 = L7_2()
    L8_2 = {}
    L9_2 = ipairs
    L10_2 = L7_2
    L9_2, L10_2, L11_2 = L9_2(L10_2)
    for L12_2, L13_2 in L9_2, L10_2, L11_2 do
      L14_2 = {}
      L15_2 = MrxShop
      L15_2 = L15_2.GetNumberOfUnlockedItems
      L16_2 = L13_2
      L15_2 = L15_2(L16_2)
      L14_2.nUnlocked = L15_2
      L15_2 = MrxShop
      L15_2 = L15_2.GetTotalNumberOfItems
      L16_2 = L13_2
      L15_2 = L15_2(L16_2)
      L14_2.nTotal = L15_2
      L8_2[L13_2] = L14_2
    end
    L9_2 = 0
    L10_2 = 0
    L11_2 = pairs
    L12_2 = L8_2
    L11_2, L12_2, L13_2 = L11_2(L12_2)
    for L14_2, L15_2 in L11_2, L12_2, L13_2 do
      L16_2 = L15_2.nTotal
      if 0 < L16_2 then
        L16_2 = L15_2.nUnlocked
        L9_2 = L9_2 + L16_2
        L16_2 = L15_2.nTotal
        L10_2 = L10_2 + L16_2
      end
    end
    L11_2 = {}
    L12_2 = MrxFactionManager
    L12_2 = L12_2.GetFactionAbbrevs
    L12_2 = L12_2()
    L13_2 = 0
    L14_2 = 0
    L15_2 = pairs
    L16_2 = L12_2
    L15_2, L16_2, L17_2 = L15_2(L16_2)
    for L18_2, L19_2 in L15_2, L16_2, L17_2 do
      L20_2 = L3_1
      L20_2 = L20_2[L19_2]
      L13_2 = L13_2 + L20_2
      L20_2 = L4_1
      L20_2 = L20_2[L19_2]
      L14_2 = L14_2 + L20_2
      L20_2 = L3_1
      L20_2 = L20_2[L19_2]
      L21_2 = "/"
      L22_2 = L4_1
      L22_2 = L22_2[L19_2]
      L20_2 = L20_2 .. L21_2 .. L22_2
      L11_2[L19_2] = L20_2
    end
    L15_2 = L13_2
    L16_2 = "/"
    L17_2 = L14_2
    L15_2 = L15_2 .. L16_2 .. L17_2
    L16_2 = MrxVerifyManager
    L16_2 = L16_2.GetCompletedTotal
    L16_2 = L16_2()
    L17_2 = "/"
    L18_2 = GetTotalNumHVTs
    L18_2 = L18_2()
    L16_2 = L16_2 .. L17_2 .. L18_2
    L17_2 = {}
    L18_2 = {}
    L19_2 = MrxVerifyManager
    L19_2 = L19_2.GetTotalFactionVZA
    L19_2 = L19_2()
    if not L19_2 then
      L19_2 = 0
    end
    L18_2.nTotal = L19_2
    L19_2 = MrxVerifyManager
    L19_2 = L19_2.GetCompletedVZA
    L19_2 = L19_2()
    L18_2.nCompleted = L19_2
    L17_2.Vza = L18_2
    L18_2 = {}
    L19_2 = MrxVerifyManager
    L19_2 = L19_2.GetTotalFactionPMC
    L19_2 = L19_2()
    if not L19_2 then
      L19_2 = 0
    end
    L18_2.nTotal = L19_2
    L19_2 = MrxVerifyManager
    L19_2 = L19_2.GetCompletedPMC
    L19_2 = L19_2()
    L18_2.nCompleted = L19_2
    L17_2.Pmc = L18_2
    L18_2 = {}
    L19_2 = MrxVerifyManager
    L19_2 = L19_2.GetTotalFactionPIR
    L19_2 = L19_2()
    if not L19_2 then
      L19_2 = 0
    end
    L18_2.nTotal = L19_2
    L19_2 = MrxVerifyManager
    L19_2 = L19_2.GetCompletedPIR
    L19_2 = L19_2()
    L18_2.nCompleted = L19_2
    L17_2.Pir = L18_2
    L18_2 = {}
    L19_2 = MrxVerifyManager
    L19_2 = L19_2.GetTotalFactionOIL
    L19_2 = L19_2()
    if not L19_2 then
      L19_2 = 0
    end
    L18_2.nTotal = L19_2
    L19_2 = MrxVerifyManager
    L19_2 = L19_2.GetCompletedOIL
    L19_2 = L19_2()
    L18_2.nCompleted = L19_2
    L17_2.Oil = L18_2
    L18_2 = {}
    L19_2 = MrxVerifyManager
    L19_2 = L19_2.GetTotalFactionGUR
    L19_2 = L19_2()
    if not L19_2 then
      L19_2 = 0
    end
    L18_2.nTotal = L19_2
    L19_2 = MrxVerifyManager
    L19_2 = L19_2.GetCompletedGUR
    L19_2 = L19_2()
    L18_2.nCompleted = L19_2
    L17_2.Gur = L18_2
    L18_2 = {}
    L19_2 = MrxVerifyManager
    L19_2 = L19_2.GetTotalFactionCIV
    L19_2 = L19_2()
    if not L19_2 then
      L19_2 = 0
    end
    L18_2.nTotal = L19_2
    L19_2 = MrxVerifyManager
    L19_2 = L19_2.GetCompletedCIV
    L19_2 = L19_2()
    L18_2.nCompleted = L19_2
    L17_2.Civ = L18_2
    L18_2 = {}
    L19_2 = MrxVerifyManager
    L19_2 = L19_2.GetTotalFactionCHI
    L19_2 = L19_2()
    if not L19_2 then
      L19_2 = 0
    end
    L18_2.nTotal = L19_2
    L19_2 = MrxVerifyManager
    L19_2 = L19_2.GetCompletedCHI
    L19_2 = L19_2()
    L18_2.nCompleted = L19_2
    L17_2.Chi = L18_2
    L18_2 = {}
    L19_2 = MrxVerifyManager
    L19_2 = L19_2.GetTotalFactionALL
    L19_2 = L19_2()
    if not L19_2 then
      L19_2 = 0
    end
    L18_2.nTotal = L19_2
    L19_2 = MrxVerifyManager
    L19_2 = L19_2.GetCompletedALL
    L19_2 = L19_2()
    L18_2.nCompleted = L19_2
    L17_2.All = L18_2
    L18_2 = L0_1
    L19_2 = "/"
    L20_2 = L1_1
    L18_2 = L18_2 .. L19_2 .. L20_2
    L19_2 = 0
    L20_2 = 0
    L21_2 = MrxTransit
    L21_2 = L21_2.GetUnlockedLocations
    L21_2 = L21_2()
    L22_2 = MrxTransit
    L22_2 = L22_2.GetUnlockableLocations
    L22_2 = L22_2()
    if L21_2 and L22_2 then
      L23_2 = _GetTableSizeSlow
      L24_2 = L21_2
      L23_2 = L23_2(L24_2)
      L24_2 = _GetTableSizeSlow
      L25_2 = L22_2
      L24_2 = L24_2(L25_2)
      L19_2 = L23_2 / L24_2
      L25_2 = tostring
      L26_2 = L23_2
      L25_2 = L25_2(L26_2)
      L26_2 = "/"
      L27_2 = tostring
      L28_2 = L24_2
      L27_2 = L27_2(L28_2)
      L20_2 = L25_2 .. L26_2 .. L27_2
    end
    L23_2 = WifMissionData
    L23_2 = L23_2.GetNumCompletedContracts
    L23_2 = L23_2()
    L24_2 = GetTotalNumContracts
    L24_2 = L24_2()
    L23_2 = L23_2 / L24_2
    L24_2 = L5_2 / 4
    L25_2 = L9_2 / L10_2
    L26_2 = L13_2 / L14_2
    L27_2 = MrxVerifyManager
    L27_2 = L27_2.GetCompletedTotal
    L27_2 = L27_2()
    L28_2 = GetTotalNumHVTs
    L28_2 = L28_2()
    L27_2 = L27_2 / L28_2
    L28_2 = L0_1
    L29_2 = L1_1
    L28_2 = L28_2 / L29_2
    L29_2 = L5_1
    L29_2 = L23_2 * L29_2
    L30_2 = L6_1
    L30_2 = L24_2 * L30_2
    L29_2 = L29_2 + L30_2
    L30_2 = L7_1
    L30_2 = L25_2 * L30_2
    L29_2 = L29_2 + L30_2
    L30_2 = L8_1
    L30_2 = L26_2 * L30_2
    L29_2 = L29_2 + L30_2
    L30_2 = L9_1
    L30_2 = L27_2 * L30_2
    L29_2 = L29_2 + L30_2
    L30_2 = L10_1
    L30_2 = L28_2 * L30_2
    L29_2 = L29_2 + L30_2
    L30_2 = L11_1
    L30_2 = L19_2 * L30_2
    L29_2 = L29_2 + L30_2
    L30_2 = L12_1
    L29_2 = L29_2 / L30_2
    L30_2 = math
    L30_2 = L30_2.min
    L31_2 = L29_2
    L32_2 = 1
    L30_2 = L30_2(L31_2, L32_2)
    L29_2 = L30_2
    L30_2 = string
    L30_2 = L30_2.format
    L31_2 = "%.1f"
    L32_2 = L29_2 * 100
    L30_2 = L30_2(L31_2, L32_2)
    L31_2 = "%"
    L30_2 = L30_2 .. L31_2
    L32_2 = A0_2
    L31_2 = A0_2.AddStatisticEntry
    L33_2 = L1_2
    L34_2 = "[PDA.Database.Progress.PercentComplete]"
    L35_2 = L30_2
    L31_2(L32_2, L33_2, L34_2, L35_2)
    L32_2 = A0_2
    L31_2 = A0_2.AddStatisticEntry
    L33_2 = L1_2
    L34_2 = "[PDA.Database.Progress.ContractsCompleted]"
    L35_2 = L4_2
    L31_2(L32_2, L33_2, L34_2, L35_2)
    L32_2 = A0_2
    L31_2 = A0_2.AddStatisticEntry
    L33_2 = L1_2
    L34_2 = "[PDA.Database.Progress.Recruits]"
    L35_2 = L6_2
    L31_2(L32_2, L33_2, L34_2, L35_2)
    L32_2 = A0_2
    L31_2 = A0_2.AddStatisticEntry
    L33_2 = L1_2
    L34_2 = "[PDA.Database.Progress.ShopItemsUnlocked]"
    L35_2 = L9_2
    L36_2 = "/"
    L37_2 = L10_2
    L35_2 = L35_2 .. L36_2 .. L37_2
    L31_2(L32_2, L33_2, L34_2, L35_2)
    L31_2 = pairs
    L32_2 = L8_2
    L31_2, L32_2, L33_2 = L31_2(L32_2)
    for L34_2, L35_2 in L31_2, L32_2, L33_2 do
      L36_2 = L35_2.nTotal
      if 0 < L36_2 then
        L36_2 = "\t "
        L37_2 = L2_1
        L37_2 = L37_2[L34_2]
        L36_2 = L36_2 .. L37_2
        L37_2 = L35_2.nUnlocked
        L38_2 = "/"
        L39_2 = L35_2.nTotal
        L37_2 = L37_2 .. L38_2 .. L39_2
        L39_2 = A0_2
        L38_2 = A0_2.AddStatisticEntry
        L40_2 = L1_2
        L41_2 = L36_2
        L42_2 = L37_2
        L38_2(L39_2, L40_2, L41_2, L42_2)
      end
    end
    L32_2 = A0_2
    L31_2 = A0_2.AddStatisticEntry
    L33_2 = L1_2
    L34_2 = "[PDA.Database.Progress.FactionTargetsDestroyed]"
    L35_2 = L15_2
    L31_2(L32_2, L33_2, L34_2, L35_2)
    L31_2 = pairs
    L32_2 = L4_1
    L31_2, L32_2, L33_2 = L31_2(L32_2)
    for L34_2, L35_2 in L31_2, L32_2, L33_2 do
      if L35_2 ~= 0 then
        L36_2 = "\t "
        L37_2 = L2_1
        L37_2 = L37_2[L34_2]
        L38_2 = " "
        L36_2 = L36_2 .. L37_2 .. L38_2
        L37_2 = L3_1
        L37_2 = L37_2[L34_2]
        L38_2 = "/"
        L39_2 = L35_2
        L37_2 = L37_2 .. L38_2 .. L39_2
        L39_2 = A0_2
        L38_2 = A0_2.AddStatisticEntry
        L40_2 = L1_2
        L41_2 = L36_2
        L42_2 = L37_2
        L38_2(L39_2, L40_2, L41_2, L42_2)
      end
    end
    L32_2 = A0_2
    L31_2 = A0_2.AddStatisticEntry
    L33_2 = L1_2
    L34_2 = "[PDA.Database.Progress.HVTsVerified]"
    L35_2 = L16_2
    L31_2(L32_2, L33_2, L34_2, L35_2)
    L31_2 = pairs
    L32_2 = L17_2
    L31_2, L32_2, L33_2 = L31_2(L32_2)
    for L34_2, L35_2 in L31_2, L32_2, L33_2 do
      L36_2 = L35_2.nTotal
      if L36_2 ~= 0 then
        L36_2 = "\t "
        L37_2 = L2_1
        L37_2 = L37_2[L34_2]
        L38_2 = "  "
        L36_2 = L36_2 .. L37_2 .. L38_2
        L37_2 = L35_2.nCompleted
        L38_2 = "/"
        L39_2 = L35_2.nTotal
        L37_2 = L37_2 .. L38_2 .. L39_2
        L39_2 = A0_2
        L38_2 = A0_2.AddStatisticEntry
        L40_2 = L1_2
        L41_2 = L36_2
        L42_2 = L37_2
        L38_2(L39_2, L40_2, L41_2, L42_2)
      end
    end
    L32_2 = A0_2
    L31_2 = A0_2.AddStatisticEntry
    L33_2 = L1_2
    L34_2 = "[PDA.Database.Progress.ToolboxesCollected]"
    L35_2 = L18_2
    L31_2(L32_2, L33_2, L34_2, L35_2)
    L32_2 = A0_2
    L31_2 = A0_2.AddStatisticEntry
    L33_2 = L1_2
    L34_2 = "[PDA.Database.Progress.LandingZonesUnlocked]"
    L35_2 = L20_2
    L31_2(L32_2, L33_2, L34_2, L35_2)
  end
end

BuildStats = L29_1

function L29_1(A0_2)
  local L1_2, L2_2
  if A0_2 then
    L1_2 = L3_1
    L1_2 = L1_2[A0_2]
    if L1_2 then
      L1_2 = L3_1
      L2_2 = L3_1
      L2_2 = L2_2[A0_2]
      L2_2 = L2_2 + 1
      L1_2[A0_2] = L2_2
    else
      L1_2 = L3_1
      L1_2[A0_2] = 1
    end
  end
end

JobDestroyPart = L29_1

function L29_1()
  local L0_2, L1_2
  L0_2 = L0_1
  L0_2 = L0_2 + 1
  L0_1 = L0_2
end

CompleteToolboxPart = L29_1

function L29_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L1_2 = UpdateWeaponTime
  L1_2()
  L1_2 = UpdateVehicleTime
  L1_2()
  L1_2 = "[Generic.Statistics]"
  L2_2 = bAddedStatisticCategory
  if not L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.AddStatisticCategory
    L4_2 = L1_2
    L2_2(L3_2, L4_2)
    L2_2 = true
    bAddedStatisticCategory = L2_2
  end
  L2_2 = Net
  L2_2 = L2_2.IsActive
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = Net
    L2_2 = L2_2.IsClient
    L2_2 = L2_2()
    if L2_2 then
      L3_2 = A0_2
      L2_2 = A0_2.AddStatisticEntry
      L4_2 = L1_2
      L5_2 = "[SHELL.Misc.55]"
      L6_2 = " "
      L2_2(L3_2, L4_2, L5_2, L6_2)
    end
  end
  L2_2 = GetFavWeapon
  L2_2 = L2_2()
  if not L2_2 then
    L2_2 = " "
  end
  L4_2 = A0_2
  L3_2 = A0_2.AddStatisticEntry
  L5_2 = L1_2
  L6_2 = "[Generic.FavWeapon]"
  L7_2 = L2_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
  L3_2 = GetFavVehicle
  L3_2 = L3_2()
  if not L3_2 then
    L3_2 = " "
  end
  L5_2 = A0_2
  L4_2 = A0_2.AddStatisticEntry
  L6_2 = L1_2
  L7_2 = "[Generic.FavVehicle]"
  L8_2 = L3_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L5_2 = A0_2
  L4_2 = A0_2.AddStatisticEntry
  L6_2 = L1_2
  L7_2 = "[Generic.OutpostsCaptured]"
  L8_2 = L14_1
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = nil
  L5_2 = L15_1
  if L5_2 then
    L5_2 = MrxUtil
    L5_2 = L5_2.FormatMoney
    L6_2 = L15_1
    L5_2 = L5_2(L6_2)
    L4_2 = L5_2
  else
    L5_2 = MrxUtil
    L5_2 = L5_2.FormatMoney
    L6_2 = 0
    L5_2 = L5_2(L6_2)
    L4_2 = L5_2
  end
  L6_2 = A0_2
  L5_2 = A0_2.AddStatisticEntry
  L7_2 = L1_2
  L8_2 = "[Generic.Credits]"
  L9_2 = L4_2
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L5_2 = pairs
  L6_2 = L25_1
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    if L9_2 then
      L10_2 = MrxUtil
      L10_2 = L10_2.FormatMoney
      L11_2 = L9_2
      L10_2 = L10_2(L11_2)
      L4_2 = L10_2
    else
      L10_2 = MrxUtil
      L10_2 = L10_2.FormatMoney
      L11_2 = 0
      L10_2 = L10_2(L11_2)
      L4_2 = L10_2
    end
    if L8_2 == "[Generic.Wagers]" then
      L8_2 = "[Generic.Wagers] "
    end
    L11_2 = A0_2
    L10_2 = A0_2.AddStatisticEntry
    L12_2 = L1_2
    L13_2 = "\t "
    L14_2 = L8_2
    L13_2 = L13_2 .. L14_2
    L14_2 = L4_2
    L10_2(L11_2, L12_2, L13_2, L14_2)
  end
  L5_2 = L16_1
  if L5_2 then
    L5_2 = "-"
    L6_2 = MrxUtil
    L6_2 = L6_2.FormatMoney
    L7_2 = L16_1
    L6_2 = L6_2(L7_2)
    L4_2 = L5_2 .. L6_2
  else
    L5_2 = MrxUtil
    L5_2 = L5_2.FormatMoney
    L6_2 = 0
    L5_2 = L5_2(L6_2)
    L4_2 = L5_2
  end
  L6_2 = A0_2
  L5_2 = A0_2.AddStatisticEntry
  L7_2 = L1_2
  L8_2 = "[Generic.Debits]"
  L9_2 = L4_2
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L5_2 = pairs
  L6_2 = L24_1
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    if L9_2 then
      L10_2 = "-"
      L11_2 = MrxUtil
      L11_2 = L11_2.FormatMoney
      L12_2 = L9_2
      L11_2 = L11_2(L12_2)
      L4_2 = L10_2 .. L11_2
    else
      L10_2 = "-"
      L11_2 = MrxUtil
      L11_2 = L11_2.FormatMoney
      L12_2 = 0
      L11_2 = L11_2(L12_2)
      L4_2 = L10_2 .. L11_2
    end
    L11_2 = A0_2
    L10_2 = A0_2.AddStatisticEntry
    L12_2 = L1_2
    L13_2 = "\t "
    L14_2 = L8_2
    L13_2 = L13_2 .. L14_2
    L14_2 = L4_2
    L10_2(L11_2, L12_2, L13_2, L14_2)
  end
  L6_2 = A0_2
  L5_2 = A0_2.AddStatisticEntry
  L7_2 = L1_2
  L8_2 = "[Generic.FuelIn]"
  L9_2 = L17_1
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = A0_2
  L5_2 = A0_2.AddStatisticEntry
  L7_2 = L1_2
  L8_2 = "[Generic.FuelOut]"
  L9_2 = L18_1
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = A0_2
  L5_2 = A0_2.AddStatisticEntry
  L7_2 = L1_2
  L8_2 = "[Generic.Deaths]"
  L9_2 = L19_1
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = A0_2
  L5_2 = A0_2.AddStatisticEntry
  L7_2 = L1_2
  L8_2 = "[Generic.Medevacs]"
  L9_2 = L20_1
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = A0_2
  L5_2 = A0_2.AddStatisticEntry
  L7_2 = L1_2
  L8_2 = "[Generic.Retries]"
  L9_2 = L21_1
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = A0_2
  L5_2 = A0_2.AddStatisticEntry
  L7_2 = L1_2
  L8_2 = "[Generic.Transits]"
  L9_2 = L22_1
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = A0_2
  L5_2 = A0_2.AddStatisticEntry
  L7_2 = L1_2
  L8_2 = "[Generic.BestRaceTimes]"
  L9_2 = " "
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L5_2 = L26_1
  if L5_2 then
    L5_2 = pairs
    L6_2 = L26_1
    L5_2, L6_2, L7_2 = L5_2(L6_2)
    for L8_2, L9_2 in L5_2, L6_2, L7_2 do
      L10_2 = "\t "
      L11_2 = WifMissionData
      L11_2 = L11_2.GetMissionTitle
      L12_2 = L8_2
      L11_2 = L11_2(L12_2)
      L10_2 = L10_2 .. L11_2
      L12_2 = A0_2
      L11_2 = A0_2.AddStatisticEntry
      L13_2 = L1_2
      L14_2 = L10_2
      L15_2 = Junk
      L15_2 = L15_2.FormatTime
      L16_2 = L9_2
      L15_2, L16_2 = L15_2(L16_2)
      L11_2(L12_2, L13_2, L14_2, L15_2, L16_2)
    end
  end
end

PdaStatistics = L29_1

function L29_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = Event
  L0_2 = L0_2.CreatePersistent
  L1_2 = Event
  L1_2 = L1_2.WeaponEvent
  L2_2 = {}
  L3_2 = Player
  L3_2 = L3_2.GetLocalCharacter
  L3_2 = L3_2()
  L4_2 = "Stow"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = TrackWeaponTime
  L4_2 = {}
  L0_2 = L0_2(L1_2, L2_2, L3_2, L4_2)
  uStowFavWeaponTimer = L0_2
  L0_2 = Event
  L0_2 = L0_2.CreatePersistent
  L1_2 = Event
  L1_2 = L1_2.WeaponEvent
  L2_2 = {}
  L3_2 = Player
  L3_2 = L3_2.GetLocalCharacter
  L3_2 = L3_2()
  L4_2 = "Drop"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = TrackWeaponTime
  L4_2 = {}
  L0_2 = L0_2(L1_2, L2_2, L3_2, L4_2)
  uDropFavWeaponTimer = L0_2
  L0_2 = Event
  L0_2 = L0_2.CreatePersistent
  L1_2 = Event
  L1_2 = L1_2.WeaponEvent
  L2_2 = {}
  L3_2 = Player
  L3_2 = L3_2.GetLocalCharacter
  L3_2 = L3_2()
  L4_2 = "Equip"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = StartWeaponTime
  L4_2 = {}
  L0_2 = L0_2(L1_2, L2_2, L3_2, L4_2)
  uEquipFavWeaponTimer = L0_2
  L0_2 = Human
  L0_2 = L0_2.Inventory
  L0_2 = L0_2.GetPrimaryWeapon
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2, L2_2, L3_2, L4_2 = L1_2()
  L0_2 = L0_2(L1_2, L2_2, L3_2, L4_2)
  if L0_2 then
    L1_2 = StartWeaponTime
    L2_2 = Player
    L2_2 = L2_2.GetLocalCharacter
    L2_2 = L2_2()
    L3_2 = L0_2
    L1_2(L2_2, L3_2)
  end
end

AddWeaponTimer = L29_1

function L29_1()
  local L0_2, L1_2
  L0_2 = uStowFavWeaponTimer
  if L0_2 then
    L0_2 = Event
    L0_2 = L0_2.Delete
    L1_2 = uStowFavWeaponTimer
    L0_2(L1_2)
    L0_2 = nil
    uStowFavWeaponTimer = L0_2
  end
  L0_2 = uDropFavWeaponTimer
  if L0_2 then
    L0_2 = Event
    L0_2 = L0_2.Delete
    L1_2 = uDropFavWeaponTimer
    L0_2(L1_2)
    L0_2 = nil
    uDropFavWeaponTimer = L0_2
  end
  L0_2 = uEquipFavWeaponTimer
  if L0_2 then
    L0_2 = Event
    L0_2 = L0_2.Delete
    L1_2 = uEquipFavWeaponTimer
    L0_2(L1_2)
    L0_2 = nil
    uEquipFavWeaponTimer = L0_2
  end
end

DeleteWeaponTimer = L29_1

function L29_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = L13_1
  L2_2 = L2_2[A1_2]
  if L2_2 then
    L2_2 = Sys
    L2_2 = L2_2.TimeStampGetElapsed
    L3_2 = L13_1
    L3_2 = L3_2[A1_2]
    L2_2 = L2_2(L3_2)
    if A1_2 then
      L3_2 = Object
      L3_2 = L3_2.HasLabel
      L4_2 = A1_2
      L5_2 = "weapon"
      L3_2 = L3_2(L4_2, L5_2)
      if L3_2 and L2_2 then
        L3_2 = SetFavWeaponTime
        L4_2 = A1_2
        L5_2 = L2_2
        L3_2(L4_2, L5_2)
      end
    end
  end
end

TrackWeaponTime = L29_1

function L29_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = L13_1
  L2_2 = L2_2[A1_2]
  if L2_2 then
    L2_2 = Sys
    L2_2 = L2_2.TimeStampMark
    L3_2 = L13_1
    L3_2 = L3_2[A1_2]
    L2_2(L3_2)
  else
    L2_2 = L13_1
    L3_2 = Sys
    L3_2 = L3_2.MainTimeStamp
    L3_2 = L3_2()
    L2_2[A1_2] = L3_2
  end
end

StartWeaponTime = L29_1

function L29_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = Human
  L0_2 = L0_2.Inventory
  L0_2 = L0_2.GetPrimaryWeapon
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2, L2_2, L3_2 = L1_2()
  L0_2 = L0_2(L1_2, L2_2, L3_2)
  if L0_2 then
    L1_2 = TrackWeaponTime
    L2_2 = Player
    L2_2 = L2_2.GetLocalCharacter
    L2_2 = L2_2()
    L3_2 = L0_2
    L1_2(L2_2, L3_2)
    L1_2 = StartWeaponTime
    L2_2 = Player
    L2_2 = L2_2.GetLocalCharacter
    L2_2 = L2_2()
    L3_2 = L0_2
    L1_2(L2_2, L3_2)
  end
end

UpdateWeaponTime = L29_1

function L29_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = Object
  L2_2 = L2_2.GetLocalizedName
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = L27_1
  L3_2 = L3_2[L2_2]
  if L3_2 then
    L3_2 = L27_1
    L4_2 = L27_1
    L4_2 = L4_2[L2_2]
    L4_2 = L4_2 + A1_2
    L3_2[L2_2] = L4_2
  else
    L3_2 = L27_1
    L3_2[L2_2] = A1_2
  end
end

SetFavWeaponTime = L29_1

function L29_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = 0
  L2_2 = pairs
  L3_2 = L27_1
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    if L6_2 > L1_2 then
      L1_2 = L6_2
      L0_2 = L5_2
    end
  end
  return L0_2
end

GetFavWeapon = L29_1

function L29_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = Event
  L0_2 = L0_2.CreatePersistent
  L1_2 = Event
  L1_2 = L1_2.ObjectInSeat
  L2_2 = {}
  L3_2 = Player
  L3_2 = L3_2.GetLocalCharacter
  L3_2 = L3_2()
  L4_2 = "Vehicle"
  L5_2 = "d"
  L6_2 = "x"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L3_2 = TrackVehicleTime
  L4_2 = {}
  L0_2 = L0_2(L1_2, L2_2, L3_2, L4_2)
  uExitFavVehicleTimer = L0_2
  L0_2 = Event
  L0_2 = L0_2.CreatePersistent
  L1_2 = Event
  L1_2 = L1_2.ObjectInSeat
  L2_2 = {}
  L3_2 = Player
  L3_2 = L3_2.GetLocalCharacter
  L3_2 = L3_2()
  L4_2 = "Vehicle"
  L5_2 = "d"
  L6_2 = "e"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L3_2 = StartVehicleTime
  L4_2 = {}
  L0_2 = L0_2(L1_2, L2_2, L3_2, L4_2)
  uEnterFavVehicleTimer = L0_2
  L0_2 = Vehicle
  L0_2 = L0_2.GetFromRider
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2, L2_2, L3_2, L4_2, L5_2, L6_2 = L1_2()
  L0_2 = L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2)
  if L0_2 then
    L1_2 = StartVehicleTime
    L2_2 = Player
    L2_2 = L2_2.GetLocalCharacter
    L2_2 = L2_2()
    L3_2 = L0_2
    L1_2(L2_2, L3_2)
  end
end

AddVehicleTimer = L29_1

function L29_1()
  local L0_2, L1_2
  L0_2 = uExitFavVehicleTimer
  if L0_2 then
    L0_2 = Event
    L0_2 = L0_2.Delete
    L1_2 = uExitFavVehicleTimer
    L0_2(L1_2)
  end
  L0_2 = uEnterFavVehicleTimer
  if L0_2 then
    L0_2 = Event
    L0_2 = L0_2.Delete
    L1_2 = uEnterFavVehicleTimer
    L0_2(L1_2)
  end
end

DeleteVehicleTimer = L29_1

function L29_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = L13_1
  L2_2 = L2_2[A1_2]
  if L2_2 then
    L2_2 = Sys
    L2_2 = L2_2.TimeStampGetElapsed
    L3_2 = L13_1
    L3_2 = L3_2[A1_2]
    L2_2 = L2_2(L3_2)
    if A1_2 then
      L3_2 = Object
      L3_2 = L3_2.HasLabel
      L4_2 = A1_2
      L5_2 = "Vehicle"
      L3_2 = L3_2(L4_2, L5_2)
      if L3_2 and L2_2 then
        L3_2 = SetFavVehicleTime
        L4_2 = A1_2
        L5_2 = L2_2
        L3_2(L4_2, L5_2)
      end
    end
  end
end

TrackVehicleTime = L29_1

function L29_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = L13_1
  L2_2 = L2_2[A1_2]
  if L2_2 then
    L2_2 = Sys
    L2_2 = L2_2.TimeStampMark
    L3_2 = L13_1
    L3_2 = L3_2[A1_2]
    L2_2(L3_2)
  else
    L2_2 = L13_1
    L3_2 = Sys
    L3_2 = L3_2.MainTimeStamp
    L3_2 = L3_2()
    L2_2[A1_2] = L3_2
  end
end

StartVehicleTime = L29_1

function L29_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = Vehicle
  L0_2 = L0_2.GetFromRider
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2, L2_2, L3_2 = L1_2()
  L0_2 = L0_2(L1_2, L2_2, L3_2)
  if L0_2 then
    L1_2 = TrackVehicleTime
    L2_2 = Player
    L2_2 = L2_2.GetLocalCharacter
    L2_2 = L2_2()
    L3_2 = L0_2
    L1_2(L2_2, L3_2)
    L1_2 = StartVehicleTime
    L2_2 = Player
    L2_2 = L2_2.GetLocalCharacter
    L2_2 = L2_2()
    L3_2 = L0_2
    L1_2(L2_2, L3_2)
  end
end

UpdateVehicleTime = L29_1

function L29_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = Object
  L2_2 = L2_2.GetLocalizedName
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = L28_1
  L3_2 = L3_2[L2_2]
  if L3_2 then
    L3_2 = L28_1
    L4_2 = L28_1
    L4_2 = L4_2[L2_2]
    L4_2 = L4_2 + A1_2
    L3_2[L2_2] = L4_2
  else
    L3_2 = L28_1
    L3_2[L2_2] = A1_2
  end
end

SetFavVehicleTime = L29_1

function L29_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = 0
  L2_2 = pairs
  L3_2 = L28_1
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    if L6_2 > L1_2 then
      L1_2 = L6_2
      L0_2 = L5_2
    end
  end
  return L0_2
end

GetFavVehicle = L29_1

function L29_1()
  local L0_2, L1_2
  L0_2 = L14_1
  L0_2 = L0_2 + 1
  L14_1 = L0_2
end

IncreaseOutpostCapturedCounter = L29_1

function L29_1(A0_2)
  local L1_2
  L1_2 = L15_1
  L1_2 = L1_2 + A0_2
  L15_1 = L1_2
end

IncreaseCreditAmount = L29_1

function L29_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = L25_1
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L2_2 = L25_1
    L3_2 = L25_1
    L3_2 = L3_2[A0_2]
    L3_2 = L3_2 + A1_2
    L2_2[A0_2] = L3_2
  else
    L2_2 = L25_1
    L2_2[A0_2] = A1_2
  end
end

ReasonsForCredits = L29_1

function L29_1(A0_2)
  local L1_2
  L1_2 = L16_1
  L1_2 = L1_2 - A0_2
  L16_1 = L1_2
end

IncreaseDebitAmount = L29_1

function L29_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = L24_1
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L2_2 = L24_1
    L3_2 = L24_1
    L3_2 = L3_2[A0_2]
    L3_2 = L3_2 - A1_2
    L2_2[A0_2] = L3_2
  else
    L2_2 = L24_1
    L3_2 = -A1_2
    L2_2[A0_2] = L3_2
  end
end

ReasonsForDebits = L29_1

function L29_1(A0_2)
  local L1_2
  L1_2 = L17_1
  L1_2 = L1_2 + A0_2
  L17_1 = L1_2
end

IncreaseFuelInAmount = L29_1

function L29_1(A0_2)
  local L1_2
  L1_2 = L18_1
  L1_2 = L1_2 + A0_2
  L18_1 = L1_2
end

IncreaseFuelOutAmount = L29_1

function L29_1()
  local L0_2, L1_2
  L0_2 = L19_1
  L0_2 = L0_2 + 1
  L19_1 = L0_2
end

IncreaseDeathCounter = L29_1

function L29_1()
  local L0_2, L1_2
  L0_2 = L20_1
  L0_2 = L0_2 + 1
  L20_1 = L0_2
end

IncreaseMedevacCounter = L29_1

function L29_1()
  local L0_2, L1_2
  L0_2 = L21_1
  L0_2 = L0_2 + 1
  L21_1 = L0_2
end

IncreaseRetriesCounter = L29_1

function L29_1()
  local L0_2, L1_2
  L0_2 = L22_1
  L0_2 = L0_2 + 1
  L22_1 = L0_2
end

IncreaseTransitCounter = L29_1

function L29_1(A0_2, A1_2)
  local L2_2
  L2_2 = L26_1
  L2_2 = L2_2[A0_2]
  if L2_2 == 0 then
    L2_2 = L26_1
    L2_2[A0_2] = A1_2
  else
    L2_2 = L26_1
    L2_2 = L2_2[A0_2]
    if A1_2 < L2_2 then
      L2_2 = L26_1
      L2_2[A0_2] = A1_2
    end
  end
end

RecordBestTime = L29_1
