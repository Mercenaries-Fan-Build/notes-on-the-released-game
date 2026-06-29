local L0_1, L1_1, L2_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxLayerManager"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxUtil"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxPmc"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxGuiInterface"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "DlcVehicleStrike"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "WifVzBoundary"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxMusic"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "DLC01_MissionHub"
L2_1 = false
L0_1(L1_1, L2_1)

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = {}
  L2_2 = "DLC01_state_DLCCon003"
  L3_2 = "DLC01_state_DLCCon003_Pathfinding"
  L4_2 = "DLC01_state_DLCCon003_Spawns"
  L5_2 = "DLC01_state_DLCCon003_AtmoFX"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L2_2 = MrxLayerManager
  L2_2 = L2_2.Add
  L3_2 = L1_2
  L4_2 = InitPlayerSpawn
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L2_2(L3_2, L4_2, L5_2)
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L1_2 = {}
  tSpawned = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "DLC_AT Rocket"
  L1_2 = L1_2(L2_2)
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "Combat Rifle"
  L2_2 = L2_2(L3_2)
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "C4"
  L3_2 = L3_2(L4_2)
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "Grenade"
  L4_2 = L4_2(L5_2)
  L5_2 = Player
  L5_2 = L5_2.GetPrimaryCharacter
  L5_2 = L5_2()
  uPlayerOne = L5_2
  L5_2 = Player
  L5_2 = L5_2.GetSecondaryCharacter
  L5_2 = L5_2()
  uPlayerTwo = L5_2
  L5_2 = Player
  L5_2 = L5_2.GetCurrentPlayers
  L5_2 = L5_2()
  if L5_2 == 2 then
    L5_2 = MrxUtil
    L5_2 = L5_2.SpawnObject
    L6_2 = "DLC_M1A3"
    L7_2 = "DLCCon003_Player01_Tank_loc"
    L5_2 = L5_2(L6_2, L7_2)
    L6_2 = Human
    L6_2 = L6_2.Inventory
    L6_2 = L6_2.SetAllWeapons
    L7_2 = uPlayerOne
    L8_2 = {}
    L9_2 = L1_2
    L10_2 = L2_2
    L11_2 = L3_2
    L12_2 = L4_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L8_2[4] = L12_2
    L6_2(L7_2, L8_2)
    L6_2 = MrxUtil
    L6_2 = L6_2.SpawnObject
    L7_2 = "DLC_M1A3"
    L8_2 = "DLCCon003_Player02_Tank_loc"
    L6_2 = L6_2(L7_2, L8_2)
    L7_2 = Human
    L7_2 = L7_2.Inventory
    L7_2 = L7_2.SetAllWeapons
    L8_2 = uPlayerTwo
    L9_2 = {}
    L10_2 = L1_2
    L11_2 = L2_2
    L12_2 = L3_2
    L13_2 = L4_2
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L9_2[4] = L13_2
    L7_2(L8_2, L9_2)
    L7_2 = table
    L7_2 = L7_2.insert
    L8_2 = tSpawned
    L9_2 = L5_2
    L7_2(L8_2, L9_2)
    L7_2 = table
    L7_2 = L7_2.insert
    L8_2 = tSpawned
    L9_2 = L6_2
    L7_2(L8_2, L9_2)
  else
    L5_2 = MrxUtil
    L5_2 = L5_2.SpawnObject
    L6_2 = "DLC_M1A3"
    L7_2 = "DLCCon003_Player01_Tank_loc"
    L5_2 = L5_2(L6_2, L7_2)
    L6_2 = Human
    L6_2 = L6_2.Inventory
    L6_2 = L6_2.SetAllWeapons
    L7_2 = uPlayerOne
    L8_2 = {}
    L9_2 = L1_2
    L10_2 = L2_2
    L11_2 = L3_2
    L12_2 = L4_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L8_2[4] = L12_2
    L6_2(L7_2, L8_2)
    L6_2 = table
    L6_2 = L6_2.insert
    L7_2 = tSpawned
    L8_2 = L5_2
    L6_2(L7_2, L8_2)
  end
  L5_2 = DlcVehicleStrike
  L5_2 = L5_2.CreateTankSupport
  L5_2()
  L5_2 = DlcVehicleStrike
  L6_2 = L5_2
  L5_2 = L5_2.Create
  L5_2 = L5_2(L6_2)
  a = L5_2
  L5_2 = a
  L6_2 = L5_2
  L5_2 = L5_2.AddStrike
  L5_2(L6_2)
  L5_2 = WifVzBoundary
  L5_2 = L5_2.SetupBoundary
  L6_2 = "DLCCon003_MissionBoundary"
  L7_2 = false
  L5_2(L6_2, L7_2)
  L5_2 = nil
  bHero1TankReady = L5_2
  L5_2 = nil
  bHero2TankReady = L5_2
  L5_2 = pairs
  L6_2 = tSpawned
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L11_2 = A0_2
    L10_2 = A0_2._CreateEvent
    L12_2 = Event
    L12_2 = L12_2.ObjectHibernation
    L13_2 = {}
    L14_2 = L9_2
    L15_2 = "awake"
    L13_2[1] = L14_2
    L13_2[2] = L15_2
    L14_2 = A0_2.EnsureTanksReady
    L15_2 = {}
    L16_2 = A0_2
    L17_2 = tSpawned
    L18_2 = L9_2
    L15_2[1] = L16_2
    L15_2[2] = L17_2
    L15_2[3] = L18_2
    L10_2(L11_2, L12_2, L13_2, L14_2, L15_2)
  end
end

InitPlayerSpawn = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = A1_2[1]
  L4_2 = A1_2[2]
  if A2_2 == L3_2 then
    L5_2 = true
    bHero1TankReady = L5_2
  elseif A2_2 == L4_2 then
    L5_2 = true
    bHero2TankReady = L5_2
  end
  L5_2 = bHero1TankReady
  if L5_2 or not L3_2 then
    L5_2 = bHero2TankReady
    if L5_2 or not L4_2 then
      L5_2 = nil
      bHero1TankReady = L5_2
      L5_2 = nil
      bHero2TankReady = L5_2
      L6_2 = A0_2
      L5_2 = A0_2.PutHeroesInTanks
      L7_2 = A1_2
      L5_2(L6_2, L7_2)
    end
  end
end

EnsureTanksReady = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = Player
  L2_2 = L2_2.GetPrimaryCharacter
  L2_2 = L2_2()
  L3_2 = Player
  L3_2 = L3_2.GetSecondaryCharacter
  L3_2 = L3_2()
  L4_2 = A1_2[1]
  L5_2 = A1_2[2]
  L6_2 = nil
  bHero1InTank = L6_2
  L6_2 = nil
  bHero2InTank = L6_2
  if L2_2 and L4_2 then
    L6_2 = Vehicle
    L6_2 = L6_2.Enter
    L7_2 = L4_2
    L8_2 = L2_2
    L9_2 = "d"
    L10_2 = true
    L11_2 = false
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
    L7_2 = A0_2
    L6_2 = A0_2._CreateEvent
    L8_2 = Event
    L8_2 = L8_2.ObjectInSeat
    L9_2 = {}
    L10_2 = L2_2
    L11_2 = L4_2
    L12_2 = "D"
    L13_2 = "E"
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L9_2[4] = L13_2
    L10_2 = A0_2.EnsureHeroesInTanks
    L11_2 = {}
    L12_2 = A0_2
    L11_2[1] = L12_2
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  end
  if L3_2 and L5_2 then
    L6_2 = Vehicle
    L6_2 = L6_2.Enter
    L7_2 = L5_2
    L8_2 = L3_2
    L9_2 = "d"
    L10_2 = true
    L11_2 = false
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
    L7_2 = A0_2
    L6_2 = A0_2._CreateEvent
    L8_2 = Event
    L8_2 = L8_2.ObjectInSeat
    L9_2 = {}
    L10_2 = L3_2
    L11_2 = L5_2
    L12_2 = "D"
    L13_2 = "E"
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L9_2[4] = L13_2
    L10_2 = A0_2.EnsureHeroesInTanks
    L11_2 = {}
    L12_2 = A0_2
    L11_2[1] = L12_2
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  end
end

PutHeroesInTanks = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = Player
  L2_2 = L2_2.GetPrimaryCharacter
  L2_2 = L2_2()
  L3_2 = Player
  L3_2 = L3_2.GetSecondaryCharacter
  L3_2 = L3_2()
  if L2_2 == A1_2 then
    L4_2 = true
    bHero1InTank = L4_2
  elseif L3_2 == A1_2 then
    L4_2 = true
    bHero2InTank = L4_2
  end
  L4_2 = bHero1InTank
  if L4_2 or not L2_2 then
    L4_2 = bHero2InTank
    if L4_2 or not L3_2 then
      L4_2 = Player
      L4_2 = L4_2.GetAllPlayers
      L4_2 = L4_2()
      L5_2 = ipairs
      L6_2 = L4_2
      L5_2, L6_2, L7_2 = L5_2(L6_2)
      for L8_2, L9_2 in L5_2, L6_2, L7_2 do
        L10_2 = Player
        L10_2 = L10_2.GetCamera
        L11_2 = L9_2
        L10_2 = L10_2(L11_2)
        if L10_2 then
          L11_2 = Camera
          L11_2 = L11_2.StopBlending
          L12_2 = L10_2
          L11_2(L12_2)
        end
      end
      L5_2 = nil
      bHero1InTank = L5_2
      L5_2 = nil
      bHero2InTank = L5_2
      L6_2 = A0_2
      L5_2 = A0_2.AssetsLoaded
      L5_2(L6_2)
    end
  end
end

EnsureHeroesInTanks = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2, L47_2, L48_2, L49_2, L50_2, L51_2, L52_2, L53_2, L54_2, L55_2
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2 = L1_2()
  L2_2 = Player
  L2_2 = L2_2.GetPrimaryPlayer
  L2_2 = L2_2()
  L3_2 = Player
  L3_2 = L3_2.GetSecondaryPlayer
  L3_2 = L3_2()
  L4_2 = Player
  L4_2 = L4_2.GetCurrentPlayers
  L4_2 = L4_2()
  L5_2 = ObjectFilter
  L5_2 = L5_2.Create
  L5_2 = L5_2()
  uChiVehFilter = L5_2
  L5_2 = ObjectFilter
  L5_2 = L5_2.SetFilter
  L6_2 = uChiVehFilter
  L7_2 = "China && Tank"
  L5_2(L6_2, L7_2)
  L5_2 = 0
  nPlayerTanks = L5_2
  L5_2 = 0
  nBonusKills = L5_2
  L5_2 = 0
  nGiveTB = L5_2
  L5_2 = 0
  nSpawn = L5_2
  L5_2 = 0
  nLive = L5_2
  L5_2 = 0
  nGoal = L5_2
  L5_2 = 0
  nTankDeath = L5_2
  L5_2 = 0
  nPlyrLoc = L5_2
  L5_2 = 0
  nCurTankHealth = L5_2
  L5_2 = true
  bFirstPickup = L5_2
  L5_2 = 1
  nRound = L5_2
  L5_2 = 10
  nFailCon = L5_2
  L5_2 = 3
  nTankHealth = L5_2
  L5_2 = 60
  nVicCon = L5_2
  L5_2 = 45
  nSpwnTime = L5_2
  L5_2 = 0.5
  nAdv = L5_2
  L5_2 = 21
  nRoundValue = L5_2
  L5_2 = 10
  nTime = L5_2
  L5_2 = 5
  nTBSpwnBase = L5_2
  L5_2 = {}
  nEscPen = L5_2
  L5_2 = nEscPen
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "PLZ45 (DLC) (LongHib) (Prototype)"
  L6_2 = L6_2(L7_2)
  L5_2[L6_2] = 100000
  L5_2 = nEscPen
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "ZTZ63a (DLC) (LongHib) (Prototype)"
  L6_2 = L6_2(L7_2)
  L5_2[L6_2] = 200000
  L5_2 = nEscPen
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "ZTZ98 (DLC) (LongHib) (Prototype)"
  L6_2 = L6_2(L7_2)
  L5_2[L6_2] = 500000
  L5_2 = 20
  nEscPenTime = L5_2
  L5_2 = {}
  nKillBonus = L5_2
  L5_2 = nKillBonus
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "PLZ45 (DLC) (LongHib) (Prototype)"
  L6_2 = L6_2(L7_2)
  L5_2[L6_2] = 100000
  L5_2 = nKillBonus
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "ZTZ63a (DLC) (LongHib) (Prototype)"
  L6_2 = L6_2(L7_2)
  L5_2[L6_2] = 200000
  L5_2 = nKillBonus
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "ZTZ98 (DLC) (LongHib) (Prototype)"
  L6_2 = L6_2(L7_2)
  L5_2[L6_2] = 500000
  L5_2 = 1000000
  knHeliBonus = L5_2
  A0_2.nTankMoney = 0
  A0_2.nEscapeMoney = 0
  L5_2 = 0
  nRepairMoney = L5_2
  A0_2.nHeliBonusMoney = 0
  L5_2 = {}
  A0_2.tVehicleEvents = L5_2
  L5_2 = {}
  A0_2.tExitRegionCounters = L5_2
  L5_2 = nTBSpwnBase
  nTBSpawn = L5_2
  L5_2 = {}
  L6_2 = 1
  L7_2 = 3
  L8_2 = 5
  L9_2 = 7
  L10_2 = 9
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  tTracerTime = L5_2
  L5_2 = {}
  L6_2 = "DLCCon003_ExitLoc_01"
  L7_2 = "DLCCon003_ExitLoc_02"
  L8_2 = "DLCCon003_ExitLoc_03"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  tExitLocs = L5_2
  L5_2 = {}
  tExitLocMarkers = L5_2
  L5_2 = {}
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "DLCCon003_overpass_a"
  L6_2 = L6_2(L7_2)
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "DLCCon003_overpass_b"
  L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2, L47_2, L48_2, L49_2, L50_2, L51_2, L52_2, L53_2, L54_2, L55_2 = L7_2(L8_2)
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L5_2[7] = L12_2
  L5_2[8] = L13_2
  L5_2[9] = L14_2
  L5_2[10] = L15_2
  L5_2[11] = L16_2
  L5_2[12] = L17_2
  L5_2[13] = L18_2
  L5_2[14] = L19_2
  L5_2[15] = L20_2
  L5_2[16] = L21_2
  L5_2[17] = L22_2
  L5_2[18] = L23_2
  L5_2[19] = L24_2
  L5_2[20] = L25_2
  L5_2[21] = L26_2
  L5_2[22] = L27_2
  L5_2[23] = L28_2
  L5_2[24] = L29_2
  L5_2[25] = L30_2
  L5_2[26] = L31_2
  L5_2[27] = L32_2
  L5_2[28] = L33_2
  L5_2[29] = L34_2
  L5_2[30] = L35_2
  L5_2[31] = L36_2
  L5_2[32] = L37_2
  L5_2[33] = L38_2
  L5_2[34] = L39_2
  L5_2[35] = L40_2
  L5_2[36] = L41_2
  L5_2[37] = L42_2
  L5_2[38] = L43_2
  L5_2[39] = L44_2
  L5_2[40] = L45_2
  L5_2[41] = L46_2
  L5_2[42] = L47_2
  L5_2[43] = L48_2
  L5_2[44] = L49_2
  L5_2[45] = L50_2
  L5_2[46] = L51_2
  L5_2[47] = L52_2
  L5_2[48] = L53_2
  L5_2[49] = L54_2
  L5_2[50] = L55_2
  tOverpasses = L5_2
  L5_2 = {}
  L6_2 = "DLCCon003_bridge01a"
  L7_2 = "DLCCon003_bridge01b"
  L8_2 = "DLCCon003_bridge01c"
  L9_2 = "DLCCon003_bridge01d"
  L10_2 = "DLCCon003_bridge01e"
  L11_2 = "DLCCon003_bridge01f"
  L12_2 = "DLCCon003_bridge01g"
  L13_2 = "DLCCon003_bridge02a"
  L14_2 = "DLCCon003_bridge02b"
  L15_2 = "DLCCon003_bridge02c"
  L16_2 = "DLCCon003_bridge02d"
  L17_2 = "DLCCon003_bridge02e"
  L18_2 = "DLCCon003_bridge02f"
  L19_2 = "DLCCon003_bridge02g"
  L20_2 = "DLCCon003_bridge03a"
  L21_2 = "DLCCon003_bridge03b"
  L22_2 = "DLCCon003_bridge03c"
  L23_2 = "DLCCon003_bridge03d"
  L24_2 = "DLCCon003_bridge03e"
  L25_2 = "DLCCon003_bridge03f"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L5_2[7] = L12_2
  L5_2[8] = L13_2
  L5_2[9] = L14_2
  L5_2[10] = L15_2
  L5_2[11] = L16_2
  L5_2[12] = L17_2
  L5_2[13] = L18_2
  L5_2[14] = L19_2
  L5_2[15] = L20_2
  L5_2[16] = L21_2
  L5_2[17] = L22_2
  L5_2[18] = L23_2
  L5_2[19] = L24_2
  L5_2[20] = L25_2
  tBridges = L5_2
  L5_2 = {}
  L6_2 = "Path_x01_B07"
  L5_2[1] = L6_2
  tX01 = L5_2
  L5_2 = {}
  L6_2 = "Path_x02_B07"
  L5_2[1] = L6_2
  tX02 = L5_2
  L5_2 = {}
  L6_2 = "Path_x03_B04"
  L5_2[1] = L6_2
  tX03 = L5_2
  L5_2 = {}
  L6_2 = "Path_x04_B03"
  L5_2[1] = L6_2
  tX04 = L5_2
  L5_2 = {}
  L6_2 = "Path_x05_D06"
  L5_2[1] = L6_2
  tX05 = L5_2
  L5_2 = {}
  L6_2 = "Path_x06_E05"
  L5_2[1] = L6_2
  tX06 = L5_2
  L5_2 = {}
  L6_2 = "Path_x07_D04"
  L5_2[1] = L6_2
  tX07 = L5_2
  L5_2 = {}
  L6_2 = "Path_x08_D04"
  L5_2[1] = L6_2
  tX08 = L5_2
  L5_2 = {}
  L6_2 = "Path_x09_E05"
  L5_2[1] = L6_2
  tX09 = L5_2
  L5_2 = {}
  L6_2 = "Path_x10_G07"
  L5_2[1] = L6_2
  tX10 = L5_2
  L5_2 = {}
  L6_2 = "Path_x11_G07"
  L5_2[1] = L6_2
  tX11 = L5_2
  L5_2 = {}
  L6_2 = "Path_x12_G07"
  L5_2[1] = L6_2
  tX12 = L5_2
  L5_2 = {}
  L6_2 = "Path_x13_G05"
  L5_2[1] = L6_2
  tX13 = L5_2
  L5_2 = {}
  L6_2 = "Path_x14_G05"
  L5_2[1] = L6_2
  tX14 = L5_2
  L5_2 = {}
  L6_2 = "Path_B01_D01"
  L7_2 = "Path_B01_A05"
  L8_2 = "Path_B01_B02"
  L9_2 = "Path_B01_B02"
  L10_2 = "Path_B01_B02"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  tB01 = L5_2
  L5_2 = {}
  L6_2 = "Path_D01_B01"
  L7_2 = "Path_D01_D02"
  L8_2 = "Path_D01_D02"
  L9_2 = "Path_D01_D02"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  tD01 = L5_2
  L5_2 = {}
  L6_2 = "Path_E01_F01"
  L7_2 = "Path_E01_E02"
  L8_2 = "Path_E01_E02"
  L9_2 = "Path_E01_E02"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  tE01 = L5_2
  L5_2 = {}
  L6_2 = "Path_F01_G02"
  L7_2 = "Path_F01_E01"
  L8_2 = "Path_F01_F02"
  L9_2 = "Path_F01_F02"
  L10_2 = "Path_F01_F02"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  tF01 = L5_2
  L5_2 = {}
  L6_2 = "Path_B02_D02"
  L7_2 = "Path_B02_B03"
  L8_2 = "Path_B02_B03"
  L9_2 = "Path_B02_B03"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  tB02 = L5_2
  L5_2 = {}
  L6_2 = "Path_D02_E02"
  L7_2 = "Path_D02_B02"
  L8_2 = "Path_D02_D04"
  L9_2 = "Path_D02_D04"
  L10_2 = "Path_D02_D04"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  tD02 = L5_2
  L5_2 = {}
  L6_2 = "Path_E02_F02"
  L7_2 = "Path_E02_D02"
  L8_2 = "Path_E01_E02"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  tE02 = L5_2
  L5_2 = {}
  L6_2 = "Path_F02_G02"
  L7_2 = "Path_F02_E02"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  tF02 = L5_2
  L5_2 = {}
  L6_2 = "Path_G02_F02"
  L7_2 = "Path_G02_G03"
  L8_2 = "Path_G02_G03"
  L9_2 = "Path_G02_G03"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  tG02 = L5_2
  L5_2 = {}
  L6_2 = "Path_B03_A05"
  L7_2 = "Path_B03_B04"
  L8_2 = "Path_B03_B04"
  L9_2 = "Path_B03_B04"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  tB03 = L5_2
  L5_2 = {}
  L6_2 = "Path_G03_H05"
  L7_2 = "Path_G03_G05"
  L8_2 = "Path_G03_G05"
  L9_2 = "Path_G03_G05"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  tG03 = L5_2
  L5_2 = {}
  L6_2 = "Path_B04_D04"
  L7_2 = "Path_B04_B06"
  L8_2 = "Path_B04_B06"
  L9_2 = "Path_B04_B06"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  tB04 = L5_2
  L5_2 = {}
  L6_2 = "Path_D04_B04"
  L7_2 = "Path_D04_D05"
  L8_2 = "Path_D04_D05"
  L9_2 = "Path_D04_D05"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  tD04 = L5_2
  L5_2 = {}
  L6_2 = "Path_A05_B07"
  L5_2[1] = L6_2
  tA05 = L5_2
  L5_2 = {}
  L6_2 = "Path_D05_E05"
  L7_2 = "Path_D05_D06"
  L8_2 = "Path_D05_D06"
  L9_2 = "Path_D05_D06"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  tD05 = L5_2
  L5_2 = {}
  L6_2 = "Path_E05_D05"
  L7_2 = "Path_E05_E08"
  L8_2 = "Path_E05_E08"
  L9_2 = "Path_E05_E08"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  tE05 = L5_2
  L5_2 = {}
  L6_2 = "Path_G05_G07"
  L7_2 = "Path_G05_G07"
  L8_2 = "Path_G05_G07"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  tG05 = L5_2
  L5_2 = {}
  L6_2 = "Path_H05_G05"
  L7_2 = "Path_H05_G07"
  L8_2 = "Path_H05_G07"
  L9_2 = "Path_H05_G07"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  tH05 = L5_2
  L5_2 = {}
  L6_2 = "Path_B06_D06"
  L7_2 = "Path_B06_B07"
  L8_2 = "Path_B06_B07"
  L9_2 = "Path_B06_B07"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  tB06 = L5_2
  L5_2 = {}
  L6_2 = "Path_D06_B06"
  L7_2 = "Path_D06_D08"
  L8_2 = "Path_D06_D08"
  L9_2 = "Path_D06_D08"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  tD06 = L5_2
  L5_2 = {}
  L6_2 = "Path_B07_B08"
  L7_2 = "Path_B07_B08"
  L8_2 = "Path_B07_B08"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  tB07 = L5_2
  L5_2 = {}
  L6_2 = "Path_G07_G08"
  L7_2 = "Path_G07_G08"
  L8_2 = "Path_G07_G08"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  tG07 = L5_2
  L5_2 = {}
  L6_2 = "Path_B08_C08"
  L7_2 = "Path_B08_B09"
  L8_2 = "Path_B08_B09"
  L9_2 = "Path_B08_B09"
  L10_2 = "Path_B08_B09"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  tB08 = L5_2
  L5_2 = {}
  L6_2 = "Path_C08_D08"
  L7_2 = "Path_C08_B08"
  L8_2 = "Path_C08_C09"
  L9_2 = "Path_C08_C09"
  L10_2 = "Path_C08_C09"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  tC08 = L5_2
  L5_2 = {}
  L6_2 = "Path_D08_E08"
  L7_2 = "Path_D08_C08"
  L8_2 = "Path_D08_D09"
  L9_2 = "Path_D08_D09"
  L10_2 = "Path_D08_D09"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  tD08 = L5_2
  L5_2 = {}
  L6_2 = "Path_E08_F08"
  L7_2 = "Path_E08_D08"
  L8_2 = "Path_E08_E09"
  L9_2 = "Path_E08_E09"
  L10_2 = "Path_E08_E09"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  tE08 = L5_2
  L5_2 = {}
  L6_2 = "Path_F08_G08"
  L7_2 = "Path_F08_E08"
  L8_2 = "Path_F08_F10"
  L9_2 = "Path_F08_F10"
  L10_2 = "Path_F08_F10"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  tF08 = L5_2
  L5_2 = {}
  L6_2 = "Path_G08_F08"
  L7_2 = "Path_G08_G10"
  L8_2 = "Path_G08_G10"
  L9_2 = "Path_G08_G10"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  tG08 = L5_2
  L5_2 = {}
  L6_2 = "Path_B09_C09"
  L7_2 = "Path_B09_B10"
  L8_2 = "Path_B09_B10"
  L9_2 = "Path_B09_B10"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  tB09 = L5_2
  L5_2 = {}
  L6_2 = "Path_C09_D09"
  L7_2 = "Path_C09_B09"
  L8_2 = "Path_C09_C10"
  L9_2 = "Path_C09_C10"
  L10_2 = "Path_C09_C10"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  tC09 = L5_2
  L5_2 = {}
  L6_2 = "Path_D09_E09"
  L7_2 = "Path_D09_C09"
  L8_2 = "Path_D09_D10"
  L9_2 = "Path_D09_D10"
  L10_2 = "Path_D09_D10"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  tD09 = L5_2
  L5_2 = {}
  L6_2 = "Path_E09_D09"
  L7_2 = "Path_E09_E10"
  L8_2 = "Path_E09_E10"
  L9_2 = "Path_E09_E10"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  tE09 = L5_2
  L5_2 = {}
  L6_2 = "Path_B10_C10"
  L7_2 = "Path_B10_EX1"
  L8_2 = "Path_B10_EX1"
  L9_2 = "Path_B10_EX1"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  tB10 = L5_2
  L5_2 = {}
  L6_2 = "Path_C10_D10"
  L7_2 = "Path_C10_B10"
  L8_2 = "Path_C10_E11"
  L9_2 = "Path_C10_E11"
  L10_2 = "Path_C10_E11"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  tC10 = L5_2
  L5_2 = {}
  L6_2 = "Path_D10_E10"
  L7_2 = "Path_D10_C10"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  tD10 = L5_2
  L5_2 = {}
  L6_2 = "Path_E10_F10"
  L7_2 = "Path_E10_D10"
  L8_2 = "Path_E10_E11"
  L9_2 = "Path_E10_E11"
  L10_2 = "Path_E10_E11"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  tE10 = L5_2
  L5_2 = {}
  L6_2 = "Path_F10_G10"
  L7_2 = "Path_F10_E10"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  tF10 = L5_2
  L5_2 = {}
  L6_2 = "Path_G10_F10"
  L7_2 = "Path_G10_G11"
  L8_2 = "Path_G10_G11"
  L9_2 = "Path_G10_G11"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  tG10 = L5_2
  L5_2 = {}
  L6_2 = "Path_E11_G11"
  L7_2 = "Path_E11_EX2"
  L8_2 = "Path_E11_EX2"
  L9_2 = "Path_E11_EX2"
  L10_2 = "Path_E11_EX2"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  tE11 = L5_2
  L5_2 = {}
  L6_2 = "Path_G11_E10"
  L7_2 = "Path_G11_EX3"
  L8_2 = "Path_G11_EX3"
  L9_2 = "Path_G11_EX3"
  L10_2 = "Path_G11_EX3"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  tG11 = L5_2
  L5_2 = {}
  L6_2 = "Intersection_x01"
  L7_2 = "Intersection_x02"
  L8_2 = "Intersection_x03"
  L9_2 = "Intersection_x04"
  L10_2 = "Intersection_x05"
  L11_2 = "Intersection_x06"
  L12_2 = "Intersection_x07"
  L13_2 = "Intersection_x08"
  L14_2 = "Intersection_x09"
  L15_2 = "Intersection_x10"
  L16_2 = "Intersection_x11"
  L17_2 = "Intersection_x12"
  L18_2 = "Intersection_x13"
  L19_2 = "Intersection_x14"
  L20_2 = "Intersection_B01"
  L21_2 = "Intersection_D01"
  L22_2 = "Intersection_E01"
  L23_2 = "Intersection_F01"
  L24_2 = "Intersection_B02"
  L25_2 = "Intersection_D02"
  L26_2 = "Intersection_E02"
  L27_2 = "Intersection_F02"
  L28_2 = "Intersection_G02"
  L29_2 = "Intersection_B03"
  L30_2 = "Intersection_G03"
  L31_2 = "Intersection_B04"
  L32_2 = "Intersection_D04"
  L33_2 = "Intersection_A05"
  L34_2 = "Intersection_D05"
  L35_2 = "Intersection_E05"
  L36_2 = "Intersection_G05"
  L37_2 = "Intersection_H05"
  L38_2 = "Intersection_B06"
  L39_2 = "Intersection_D06"
  L40_2 = "Intersection_B07"
  L41_2 = "Intersection_G07"
  L42_2 = "Intersection_B08"
  L43_2 = "Intersection_C08"
  L44_2 = "Intersection_D08"
  L45_2 = "Intersection_E08"
  L46_2 = "Intersection_F08"
  L47_2 = "Intersection_G08"
  L48_2 = "Intersection_B09"
  L49_2 = "Intersection_C09"
  L50_2 = "Intersection_D09"
  L51_2 = "Intersection_E09"
  L52_2 = "Intersection_B10"
  L53_2 = "Intersection_C10"
  L54_2 = "Intersection_D10"
  L55_2 = "Intersection_E10"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L5_2[7] = L12_2
  L5_2[8] = L13_2
  L5_2[9] = L14_2
  L5_2[10] = L15_2
  L5_2[11] = L16_2
  L5_2[12] = L17_2
  L5_2[13] = L18_2
  L5_2[14] = L19_2
  L5_2[15] = L20_2
  L5_2[16] = L21_2
  L5_2[17] = L22_2
  L5_2[18] = L23_2
  L5_2[19] = L24_2
  L5_2[20] = L25_2
  L5_2[21] = L26_2
  L5_2[22] = L27_2
  L5_2[23] = L28_2
  L5_2[24] = L29_2
  L5_2[25] = L30_2
  L5_2[26] = L31_2
  L5_2[27] = L32_2
  L5_2[28] = L33_2
  L5_2[29] = L34_2
  L5_2[30] = L35_2
  L5_2[31] = L36_2
  L5_2[32] = L37_2
  L5_2[33] = L38_2
  L5_2[34] = L39_2
  L5_2[35] = L40_2
  L5_2[36] = L41_2
  L5_2[37] = L42_2
  L5_2[38] = L43_2
  L5_2[39] = L44_2
  L5_2[40] = L45_2
  L5_2[41] = L46_2
  L5_2[42] = L47_2
  L5_2[43] = L48_2
  L5_2[44] = L49_2
  L5_2[45] = L50_2
  L5_2[46] = L51_2
  L5_2[47] = L52_2
  L5_2[48] = L53_2
  L5_2[49] = L54_2
  L5_2[50] = L55_2
  L6_2 = "Intersection_F10"
  L7_2 = "Intersection_G10"
  L8_2 = "Intersection_E11"
  L9_2 = "Intersection_G11"
  L5_2[51] = L6_2
  L5_2[52] = L7_2
  L5_2[53] = L8_2
  L5_2[54] = L9_2
  tIntersection = L5_2
  L5_2 = {}
  L6_2 = "Intersection_B04"
  L7_2 = "Intersection_D04"
  L8_2 = "Intersection_D05"
  L9_2 = "Intersection_E05"
  L10_2 = "Intersection_G05"
  L11_2 = "Intersection_B06"
  L12_2 = "Intersection_D06"
  L13_2 = "Intersection_B07"
  L14_2 = "Intersection_G07"
  L15_2 = "Intersection_B08"
  L16_2 = "Intersection_C08"
  L17_2 = "Intersection_D08"
  L18_2 = "Intersection_E08"
  L19_2 = "Intersection_F08"
  L20_2 = "Intersection_G08"
  L21_2 = "Intersection_C09"
  L22_2 = "Intersection_D09"
  L23_2 = "Intersection_E09"
  L24_2 = "Intersection_C10"
  L25_2 = "Intersection_D10"
  L26_2 = "Intersection_E10"
  L27_2 = "Intersection_F10"
  L28_2 = "Intersection_G10"
  L29_2 = "Intersection_E11"
  L30_2 = "Intersection_G11"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L5_2[7] = L12_2
  L5_2[8] = L13_2
  L5_2[9] = L14_2
  L5_2[10] = L15_2
  L5_2[11] = L16_2
  L5_2[12] = L17_2
  L5_2[13] = L18_2
  L5_2[14] = L19_2
  L5_2[15] = L20_2
  L5_2[16] = L21_2
  L5_2[17] = L22_2
  L5_2[18] = L23_2
  L5_2[19] = L24_2
  L5_2[20] = L25_2
  L5_2[21] = L26_2
  L5_2[22] = L27_2
  L5_2[23] = L28_2
  L5_2[24] = L29_2
  L5_2[25] = L30_2
  tPlayerNodes = L5_2
  L5_2 = {}
  L6_2 = tX01
  L7_2 = tX02
  L8_2 = tX03
  L9_2 = tX04
  L10_2 = tX05
  L11_2 = tX06
  L12_2 = tX07
  L13_2 = tX08
  L14_2 = tX09
  L15_2 = tX10
  L16_2 = tX11
  L17_2 = tX12
  L18_2 = tX13
  L19_2 = tX14
  L20_2 = tB01
  L21_2 = tD01
  L22_2 = tE01
  L23_2 = tF01
  L24_2 = tB02
  L25_2 = tD02
  L26_2 = tE02
  L27_2 = tF02
  L28_2 = tG02
  L29_2 = tB03
  L30_2 = tG03
  L31_2 = tB04
  L32_2 = tD04
  L33_2 = tA05
  L34_2 = tD05
  L35_2 = tE05
  L36_2 = tG05
  L37_2 = tH05
  L38_2 = tB06
  L39_2 = tD06
  L40_2 = tB07
  L41_2 = tG07
  L42_2 = tB08
  L43_2 = tC08
  L44_2 = tD08
  L45_2 = tE08
  L46_2 = tF08
  L47_2 = tG08
  L48_2 = tB09
  L49_2 = tC09
  L50_2 = tD09
  L51_2 = tE09
  L52_2 = tB10
  L53_2 = tC10
  L54_2 = tD10
  L55_2 = tE10
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L5_2[7] = L12_2
  L5_2[8] = L13_2
  L5_2[9] = L14_2
  L5_2[10] = L15_2
  L5_2[11] = L16_2
  L5_2[12] = L17_2
  L5_2[13] = L18_2
  L5_2[14] = L19_2
  L5_2[15] = L20_2
  L5_2[16] = L21_2
  L5_2[17] = L22_2
  L5_2[18] = L23_2
  L5_2[19] = L24_2
  L5_2[20] = L25_2
  L5_2[21] = L26_2
  L5_2[22] = L27_2
  L5_2[23] = L28_2
  L5_2[24] = L29_2
  L5_2[25] = L30_2
  L5_2[26] = L31_2
  L5_2[27] = L32_2
  L5_2[28] = L33_2
  L5_2[29] = L34_2
  L5_2[30] = L35_2
  L5_2[31] = L36_2
  L5_2[32] = L37_2
  L5_2[33] = L38_2
  L5_2[34] = L39_2
  L5_2[35] = L40_2
  L5_2[36] = L41_2
  L5_2[37] = L42_2
  L5_2[38] = L43_2
  L5_2[39] = L44_2
  L5_2[40] = L45_2
  L5_2[41] = L46_2
  L5_2[42] = L47_2
  L5_2[43] = L48_2
  L5_2[44] = L49_2
  L5_2[45] = L50_2
  L5_2[46] = L51_2
  L5_2[47] = L52_2
  L5_2[48] = L53_2
  L5_2[49] = L54_2
  L5_2[50] = L55_2
  L6_2 = tF10
  L7_2 = tG10
  L8_2 = tE11
  L9_2 = tG11
  L5_2[51] = L6_2
  L5_2[52] = L7_2
  L5_2[53] = L8_2
  L5_2[54] = L9_2
  tNodes = L5_2
  L7_2 = "_CreateEvent"
  L6_2 = A0_2
  L5_2 = A0_2[L7_2]
  L7_2 = Event
  L8_2 = "ObjectDeath"
  L7_2 = L7_2[L8_2]
  L8_2 = {}
  L9_2 = Pg
  L9_2 = L9_2.GetGuidByName
  L10_2 = "DLCCon003_overpass_a"
  L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2, L47_2, L48_2, L49_2, L50_2, L51_2, L52_2, L53_2, L54_2, L55_2 = L9_2(L10_2)
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  L8_2[5] = L13_2
  L8_2[6] = L14_2
  L8_2[7] = L15_2
  L8_2[8] = L16_2
  L8_2[9] = L17_2
  L8_2[10] = L18_2
  L8_2[11] = L19_2
  L8_2[12] = L20_2
  L8_2[13] = L21_2
  L8_2[14] = L22_2
  L8_2[15] = L23_2
  L8_2[16] = L24_2
  L8_2[17] = L25_2
  L8_2[18] = L26_2
  L8_2[19] = L27_2
  L8_2[20] = L28_2
  L8_2[21] = L29_2
  L8_2[22] = L30_2
  L8_2[23] = L31_2
  L8_2[24] = L32_2
  L8_2[25] = L33_2
  L8_2[26] = L34_2
  L8_2[27] = L35_2
  L8_2[28] = L36_2
  L8_2[29] = L37_2
  L8_2[30] = L38_2
  L8_2[31] = L39_2
  L8_2[32] = L40_2
  L8_2[33] = L41_2
  L8_2[34] = L42_2
  L8_2[35] = L43_2
  L8_2[36] = L44_2
  L8_2[37] = L45_2
  L8_2[38] = L46_2
  L8_2[39] = L47_2
  L8_2[40] = L48_2
  L8_2[41] = L49_2
  L8_2[42] = L50_2
  L8_2[43] = L51_2
  L8_2[44] = L52_2
  L8_2[45] = L53_2
  L8_2[46] = L54_2
  L8_2[47] = L55_2
  
  function L9_2(A0_3)
    local L1_3, L2_3
    L1_3 = {}
    L2_3 = "Path_D06_B06"
    L1_3[1] = L2_3
    tD06 = L1_3
  end
  
  L10_2 = {}
  L11_2 = A0_2
  L10_2[1] = L11_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  eOverpassA = L5_2
  L7_2 = "_CreateEvent"
  L6_2 = A0_2
  L5_2 = A0_2[L7_2]
  L7_2 = Event
  L8_2 = "ObjectDeath"
  L7_2 = L7_2[L8_2]
  L8_2 = {}
  L9_2 = Pg
  L9_2 = L9_2.GetGuidByName
  L10_2 = "DLCCon003_overpass_b"
  L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2, L47_2, L48_2, L49_2, L50_2, L51_2, L52_2, L53_2, L54_2, L55_2 = L9_2(L10_2)
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  L8_2[5] = L13_2
  L8_2[6] = L14_2
  L8_2[7] = L15_2
  L8_2[8] = L16_2
  L8_2[9] = L17_2
  L8_2[10] = L18_2
  L8_2[11] = L19_2
  L8_2[12] = L20_2
  L8_2[13] = L21_2
  L8_2[14] = L22_2
  L8_2[15] = L23_2
  L8_2[16] = L24_2
  L8_2[17] = L25_2
  L8_2[18] = L26_2
  L8_2[19] = L27_2
  L8_2[20] = L28_2
  L8_2[21] = L29_2
  L8_2[22] = L30_2
  L8_2[23] = L31_2
  L8_2[24] = L32_2
  L8_2[25] = L33_2
  L8_2[26] = L34_2
  L8_2[27] = L35_2
  L8_2[28] = L36_2
  L8_2[29] = L37_2
  L8_2[30] = L38_2
  L8_2[31] = L39_2
  L8_2[32] = L40_2
  L8_2[33] = L41_2
  L8_2[34] = L42_2
  L8_2[35] = L43_2
  L8_2[36] = L44_2
  L8_2[37] = L45_2
  L8_2[38] = L46_2
  L8_2[39] = L47_2
  L8_2[40] = L48_2
  L8_2[41] = L49_2
  L8_2[42] = L50_2
  L8_2[43] = L51_2
  L8_2[44] = L52_2
  L8_2[45] = L53_2
  L8_2[46] = L54_2
  L8_2[47] = L55_2
  
  function L9_2(A0_3)
    local L1_3, L2_3
    L1_3 = {}
    L2_3 = "Path_E05_D05"
    L1_3[1] = L2_3
    tE05 = L1_3
  end
  
  L10_2 = {}
  L11_2 = A0_2
  L10_2[1] = L11_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  eOverpassB = L5_2
  L5_2 = nRound
  L6_2 = 1
  if L5_2 == L6_2 then
    L5_2 = {}
    L6_2 = "PLZ45 (DLC) (LongHib) (Prototype)"
    L7_2 = "ZTZ63a (DLC) (LongHib) (Prototype)"
    L8_2 = "ZTZ98 (DLC) (LongHib) (Prototype)"
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    tSpawnType = L5_2
  else
    L5_2 = nRound
    L6_2 = 2
    if L5_2 == L6_2 then
      L5_2 = {}
      L6_2 = "ZTZ63a (DLC) (LongHib) (Prototype)"
      L7_2 = "ZTZ63a (DLC) (LongHib) (Prototype)"
      L8_2 = "ZTZ98 (DLC) (LongHib) (Prototype)"
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      L5_2[3] = L8_2
      tSpawnType = L5_2
    else
      L5_2 = nRound
      L6_2 = 3
      if L5_2 == L6_2 then
        L5_2 = {}
        L6_2 = "ZTZ63a (DLC) (LongHib) (Prototype)"
        L7_2 = "ZTZ98 (DLC) (LongHib) (Prototype)"
        L8_2 = "ZTZ98 (DLC) (LongHib) (Prototype)"
        L5_2[1] = L6_2
        L5_2[2] = L7_2
        L5_2[3] = L8_2
        tSpawnType = L5_2
      end
    end
  end
  L5_2 = 2
  nPlyrLoc = L5_2
  L5_2 = MrxTaskContract
  L6_2 = "Activated"
  L5_2 = L5_2[L6_2]
  L6_2 = A0_2
  L5_2(L6_2)
  L7_2 = "_SetCancelMessage"
  L6_2 = A0_2
  L5_2 = A0_2[L7_2]
  L7_2 = ""
  L5_2(L6_2, L7_2)
  L5_2 = Hud
  L6_2 = "ResourceCounter"
  L5_2 = L5_2[L6_2]
  L7_2 = "SetSuppressed"
  L6_2 = L5_2
  L5_2 = L5_2[L7_2]
  L7_2 = {}
  L8_2 = "bSuppressCash"
  L9_2 = true
  L7_2[L8_2] = L9_2
  L8_2 = "bSuppressFuel"
  L9_2 = true
  L7_2[L8_2] = L9_2
  L5_2(L6_2, L7_2)
  L5_2 = MrxPmc
  L6_2 = "AddCashQty"
  L5_2 = L5_2[L6_2]
  L6_2 = MrxPmc
  L7_2 = "GetCashQty"
  L6_2 = L6_2[L7_2]
  L6_2 = L6_2()
  L6_2 = -L6_2
  L7_2 = nil
  L8_2 = nil
  L9_2 = false
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L5_2 = Player
  L6_2 = "SetFuel"
  L5_2 = L5_2[L6_2]
  L6_2 = 0
  L5_2(L6_2)
  L5_2 = Hud
  L6_2 = "ResourceCounter"
  L5_2 = L5_2[L6_2]
  L7_2 = "SetSuppressed"
  L6_2 = L5_2
  L5_2 = L5_2[L7_2]
  L7_2 = {}
  L8_2 = "bSuppressCash"
  L9_2 = false
  L7_2[L8_2] = L9_2
  L8_2 = "bSuppressFuel"
  L9_2 = false
  L7_2[L8_2] = L9_2
  L5_2(L6_2, L7_2)
  L5_2 = Ai
  L6_2 = "SetRelation"
  L5_2 = L5_2[L6_2]
  L6_2 = GetGuidByName
  L7_2 = "China"
  L6_2 = L6_2(L7_2)
  L7_2 = GetGuidByName
  L8_2 = "PMC"
  L7_2 = L7_2(L8_2)
  L8_2 = -100
  L5_2(L6_2, L7_2, L8_2)
  L5_2 = Ai
  L6_2 = "SetRelation"
  L5_2 = L5_2[L6_2]
  L6_2 = GetGuidByName
  L7_2 = "Allied"
  L6_2 = L6_2(L7_2)
  L7_2 = GetGuidByName
  L8_2 = "PMC"
  L7_2 = L7_2(L8_2)
  L8_2 = 100
  L5_2(L6_2, L7_2, L8_2)
  L5_2 = Player
  L6_2 = "SetVehicleDisguise"
  L5_2 = L5_2[L6_2]
  L6_2 = false
  L5_2(L6_2)
  L5_2 = Hud
  L6_2 = "ObjectiveTray"
  L5_2 = L5_2[L6_2]
  L7_2 = "SetSlotToText"
  L6_2 = L5_2
  L5_2 = L5_2[L7_2]
  L7_2 = {}
  L8_2 = "nSlot"
  L9_2 = 1
  L7_2[L8_2] = L9_2
  L8_2 = "sText"
  L9_2 = "[DLCCon003.Display.escapedTanks] "
  L10_2 = nGoal
  L11_2 = "/"
  L12_2 = nFailCon
  L9_2 = L9_2 .. L10_2 .. L11_2 .. L12_2
  L7_2[L8_2] = L9_2
  L5_2(L6_2, L7_2)
  L5_2 = Hud
  L6_2 = "ResourceCounter"
  L5_2 = L5_2[L6_2]
  L7_2 = "Show"
  L6_2 = L5_2
  L5_2 = L5_2[L7_2]
  L7_2 = {}
  L8_2 = "nDuration"
  L9_2 = -1
  L7_2[L8_2] = L9_2
  L5_2(L6_2, L7_2)
  L5_2 = Hud
  L6_2 = "ResourceCounter"
  L5_2 = L5_2[L6_2]
  L7_2 = "SetSuppressed"
  L6_2 = L5_2
  L5_2 = L5_2[L7_2]
  L7_2 = {}
  L8_2 = "bSuppressCash"
  L9_2 = false
  L7_2[L8_2] = L9_2
  L8_2 = "bSuppressFuel"
  L9_2 = true
  L7_2[L8_2] = L9_2
  L5_2(L6_2, L7_2)
  L5_2 = 2
  if L4_2 == L5_2 then
    L7_2 = "MultiplayerOn"
    L6_2 = A0_2
    L5_2 = A0_2[L7_2]
    L7_2 = true
    L5_2(L6_2, L7_2)
  else
    L7_2 = "MultiplayerOff"
    L6_2 = A0_2
    L5_2 = A0_2[L7_2]
    L5_2(L6_2)
  end
  L5_2 = Vehicle
  L6_2 = "GetFromRider"
  L5_2 = L5_2[L6_2]
  L6_2 = Player
  L7_2 = "GetPrimaryCharacter"
  L6_2 = L6_2[L7_2]
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2, L47_2, L48_2, L49_2, L50_2, L51_2, L52_2, L53_2, L54_2, L55_2 = L6_2()
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2, L47_2, L48_2, L49_2, L50_2, L51_2, L52_2, L53_2, L54_2, L55_2)
  uPlayerOneTank = L5_2
  L5_2 = uPlayerOneTank
  if L5_2 then
    L7_2 = "SetupPlayerTank"
    L6_2 = A0_2
    L5_2 = A0_2[L7_2]
    L7_2 = uPlayerOneTank
    L5_2(L6_2, L7_2)
    L7_2 = "TankLife"
    L6_2 = A0_2
    L5_2 = A0_2[L7_2]
    L7_2 = L2_2
    L5_2(L6_2, L7_2)
  end
  L5_2 = Vehicle
  L6_2 = "GetFromRider"
  L5_2 = L5_2[L6_2]
  L6_2 = Player
  L7_2 = "GetSecondaryCharacter"
  L6_2 = L6_2[L7_2]
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2, L47_2, L48_2, L49_2, L50_2, L51_2, L52_2, L53_2, L54_2, L55_2 = L6_2()
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2, L47_2, L48_2, L49_2, L50_2, L51_2, L52_2, L53_2, L54_2, L55_2)
  uPlayerTwoTank = L5_2
  L5_2 = uPlayerTwoTank
  if L5_2 then
    L7_2 = "SetupPlayerTank"
    L6_2 = A0_2
    L5_2 = A0_2[L7_2]
    L7_2 = uPlayerTwoTank
    L5_2(L6_2, L7_2)
    L7_2 = "TankLife"
    L6_2 = A0_2
    L5_2 = A0_2[L7_2]
    L7_2 = L3_2
    L5_2(L6_2, L7_2)
  end
  L7_2 = "_CreateEvent"
  L6_2 = A0_2
  L5_2 = A0_2[L7_2]
  L7_2 = Event
  L8_2 = "TimerRelative"
  L7_2 = L7_2[L8_2]
  L8_2 = {}
  L9_2 = 10
  L8_2[1] = L9_2
  
  function L9_2(A0_3)
    local L1_3, L2_3
    L2_3 = A0_3
    L1_3 = A0_3.TestSpawn
    L1_3(L2_3)
  end
  
  L10_2 = {}
  L11_2 = A0_2
  L10_2[1] = L11_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  eSpawnInit = L5_2
  L5_2 = ipairs
  L6_2 = tExitLocs
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = Pg
    L10_2 = L10_2.GetGuidByName
    L11_2 = L9_2
    L10_2 = L10_2(L11_2)
    L11_2 = "Blip_"
    L12_2 = tostring
    L13_2 = L9_2
    L12_2 = L12_2(L13_2)
    L11_2 = L11_2 .. L12_2
    L12_2 = "PDA_Blip_"
    L13_2 = tostring
    L14_2 = L9_2
    L13_2 = L13_2(L14_2)
    L12_2 = L12_2 .. L13_2
    L13_2 = Minimap
    L15_2 = "AddObjectiveWithGuid"
    L14_2 = L13_2
    L13_2 = L13_2[L15_2]
    L15_2 = L11_2
    L16_2 = L10_2
    L17_2 = 0
    L18_2 = 0
    L19_2 = 0
    L20_2 = 255
    L21_2 = 200
    L22_2 = 0
    L23_2 = 10
    L24_2 = 10
    L25_2 = "HUD_objective_defend"
    L26_2 = true
    L27_2 = nil
    L28_2 = nil
    L29_2 = 5
    L13_2(L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2)
    L13_2 = Marker
    L14_2 = "AddBlip"
    L13_2 = L13_2[L14_2]
    L14_2 = L10_2
    L15_2 = "HUD_objective_defend"
    L16_2 = 32
    L17_2 = 255
    L18_2 = 200
    L19_2 = 0
    L20_2 = 255
    L21_2 = 3.5
    L13_2 = L13_2(L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
    L14_2 = table
    L15_2 = "insert"
    L14_2 = L14_2[L15_2]
    L15_2 = tExitLocMarkers
    L16_2 = L13_2
    L14_2(L15_2, L16_2)
    L14_2 = Marker
    L15_2 = "AddDisc"
    L14_2 = L14_2[L15_2]
    L15_2 = L10_2
    L16_2 = 10
    L17_2 = 255
    L18_2 = 200
    L19_2 = 0
    L20_2 = 0
    L14_2 = L14_2(L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
    L15_2 = table
    L16_2 = "insert"
    L15_2 = L15_2[L16_2]
    L16_2 = tExitLocMarkers
    L17_2 = L14_2
    L15_2(L16_2, L17_2)
    L15_2 = Pda
    L16_2 = "Map"
    L15_2 = L15_2[L16_2]
    L17_2 = "AddBlip"
    L16_2 = L15_2
    L15_2 = L15_2[L17_2]
    L17_2 = {}
    L18_2 = "sName"
    L17_2[L18_2] = L12_2
    L18_2 = "uGuid"
    L17_2[L18_2] = L10_2
    L18_2 = "sTexture"
    L19_2 = "icon_defend_1_mc"
    L17_2[L18_2] = L19_2
    L18_2 = "nSortOrder"
    L19_2 = 5
    L17_2[L18_2] = L19_2
    L18_2 = "sLabel"
    L19_2 = "[DLCCon003.Objectives.003]"
    L17_2[L18_2] = L19_2
    L18_2 = "sMission"
    L19_2 = "DlcCon003"
    L17_2[L18_2] = L19_2
    L15_2(L16_2, L17_2)
  end
  L5_2 = ipairs
  L6_2 = tBridges
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L12_2 = "_CreateEvent"
    L11_2 = A0_2
    L10_2 = A0_2[L12_2]
    L12_2 = Event
    L13_2 = "ObjectDeath"
    L12_2 = L12_2[L13_2]
    L13_2 = {}
    L14_2 = L9_2
    L13_2[1] = L14_2
    L14_2 = BridgeDeath
    L15_2 = {}
    L16_2 = A0_2
    L15_2[1] = L16_2
    L10_2(L11_2, L12_2, L13_2, L14_2, L15_2)
  end
  L7_2 = "InitalizeObj"
  L6_2 = A0_2
  L5_2 = A0_2[L7_2]
  L5_2(L6_2)
  L7_2 = "TracerFireWakeUpA"
  L6_2 = A0_2
  L5_2 = A0_2[L7_2]
  L5_2(L6_2)
  L7_2 = "TracerFireWakeUpB"
  L6_2 = A0_2
  L5_2 = A0_2[L7_2]
  L5_2(L6_2)
  L7_2 = "TracerFireExpA"
  L6_2 = A0_2
  L5_2 = A0_2[L7_2]
  L5_2(L6_2)
  L7_2 = "TracerFireExpB"
  L6_2 = A0_2
  L5_2 = A0_2[L7_2]
  L5_2(L6_2)
  L7_2 = "DistExplosion"
  L6_2 = A0_2
  L5_2 = A0_2[L7_2]
  L5_2(L6_2)
  L7_2 = "SetupMusic"
  L6_2 = A0_2
  L5_2 = A0_2[L7_2]
  L5_2(L6_2)
end

Activated = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = MrxMusic
  L0_2 = L0_2.PlaySpecialMusic
  L1_2 = "Dlc_mu_tankbattle"
  L0_2(L1_2)
end

SetupMusic = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 2
  L4_2[1] = L5_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-Dlc03-01"
    L3_3 = 2
    L4_3 = "Fiona-In-Mission-Contract-Dlc03-02"
    L5_3 = 3
    L6_3 = "Fiona-In-Mission-Contract-Dlc03-03"
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L1_3[3] = L4_3
    L1_3[4] = L5_3
    L1_3[5] = L6_3
    L0_3(L1_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

MissionStartVO = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = "[DLCCon003.Display.replacementTanks]"
  L3_2 = {}
  L4_2 = "Fiona-In-Mission-Contract-Dlc03-17"
  L5_2 = "Fiona-In-Mission-Contract-Dlc03-18"
  L6_2 = "Fiona-In-Mission-Contract-Dlc03-19"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L4_2 = 1
  L5_2 = nTankHealth
  L6_2 = nCurTankHealth
  L5_2 = L5_2 - L6_2
  L6_2 = 1
  for L7_2 = L4_2, L5_2, L6_2 do
    L8_2 = L2_2
    L9_2 = " [green]X"
    L2_2 = L8_2 .. L9_2
  end
  L4_2 = 1
  L5_2 = nCurTankHealth
  L6_2 = 1
  for L7_2 = L4_2, L5_2, L6_2 do
    L8_2 = L2_2
    L9_2 = " [red]X"
    L2_2 = L8_2 .. L9_2
  end
  L4_2 = Hud
  L4_2 = L4_2.ObjectiveTray
  L5_2 = L4_2
  L4_2 = L4_2.SetSlotToText
  L6_2 = {}
  L6_2.vPlayer = A1_2
  L6_2.nSlot = 2
  L6_2.sText = L2_2
  L6_2.bDontNetSync = true
  L4_2(L5_2, L6_2)
  L4_2 = nPlayerTanks
  if L4_2 < 3 then
    L4_2 = nPlayerTanks
    if 0 < L4_2 then
      L4_2 = MrxVoSequence
      L4_2 = L4_2.Start
      L5_2 = {}
      L6_2 = nPlayerTanks
      L6_2 = L3_2[L6_2]
      L5_2[1] = L6_2
      L4_2(L5_2)
    end
  end
  L4_2 = nPlayerTanks
  L4_2 = L4_2 + 1
  nPlayerTanks = L4_2
end

TankLife = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = {}
  L2_2 = 1
  L3_2 = 2
  L4_2 = 3
  L5_2 = 4
  L6_2 = 5
  L7_2 = 6
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  tShellTime = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = MrxUtil
  L5_2 = L5_2.GetRandomTableElement
  L6_2 = tShellTime
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = RandomShellingCall
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = MrxUtil
  L5_2 = L5_2.GetRandomTableElement
  L6_2 = tShellTime
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = RandomShellingCall
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = MrxUtil
  L5_2 = L5_2.GetRandomTableElement
  L6_2 = tShellTime
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = RandomShellingCall
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

RandomShellingWakeUp = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = {}
  L2_2 = nPlyrLoc
  if L2_2 == 1 then
    L2_2 = {}
    L3_2 = "loc_shell_a1"
    L4_2 = "loc_shell_a2"
    L5_2 = "loc_shell_a3"
    L6_2 = "loc_shell_a4"
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
    L2_2[4] = L6_2
    L1_2 = L2_2
  else
    L2_2 = nPlyrLoc
    if L2_2 == 2 then
      L2_2 = {}
      L3_2 = "loc_shell_b1"
      L4_2 = "loc_shell_b2"
      L5_2 = "loc_shell_b3"
      L6_2 = "loc_shell_b4"
      L2_2[1] = L3_2
      L2_2[2] = L4_2
      L2_2[3] = L5_2
      L2_2[4] = L6_2
      L1_2 = L2_2
    else
      L2_2 = nPlyrLoc
      if L2_2 == 3 then
        L2_2 = {}
        L3_2 = "loc_shell_c1"
        L4_2 = "loc_shell_c2"
        L5_2 = "loc_shell_c3"
        L6_2 = "loc_shell_c4"
        L2_2[1] = L3_2
        L2_2[2] = L4_2
        L2_2[3] = L5_2
        L2_2[4] = L6_2
        L1_2 = L2_2
      else
        L2_2 = nPlyrLoc
        if L2_2 == 4 then
          L2_2 = {}
          L3_2 = "loc_shell_d1"
          L4_2 = "loc_shell_d2"
          L5_2 = "loc_shell_d3"
          L6_2 = "loc_shell_d4"
          L2_2[1] = L3_2
          L2_2[2] = L4_2
          L2_2[3] = L5_2
          L2_2[4] = L6_2
          L1_2 = L2_2
        else
          L2_2 = nPlyrLoc
          if L2_2 == 5 then
            L2_2 = {}
            L3_2 = "loc_shell_e1"
            L4_2 = "loc_shell_e2"
            L5_2 = "loc_shell_e3"
            L6_2 = "loc_shell_e4"
            L2_2[1] = L3_2
            L2_2[2] = L4_2
            L2_2[3] = L5_2
            L2_2[4] = L6_2
            L1_2 = L2_2
          else
            L2_2 = nPlyrLoc
            if L2_2 == 6 then
              L2_2 = {}
              L3_2 = "loc_shell_f1"
              L4_2 = "loc_shell_f2"
              L5_2 = "loc_shell_f3"
              L6_2 = "loc_shell_f4"
              L2_2[1] = L3_2
              L2_2[2] = L4_2
              L2_2[3] = L5_2
              L2_2[4] = L6_2
              L1_2 = L2_2
            else
              L2_2 = nPlyrLoc
              if L2_2 == 7 then
                L2_2 = {}
                L3_2 = "loc_shell_d1"
                L4_2 = "loc_shell_d2"
                L5_2 = "loc_shell_d3"
                L6_2 = "loc_shell_d4"
                L2_2[1] = L3_2
                L2_2[2] = L4_2
                L2_2[3] = L5_2
                L2_2[4] = L6_2
                L1_2 = L2_2
              else
                L2_2 = nPlyrLoc
                if L2_2 == 8 then
                  L2_2 = {}
                  L3_2 = "loc_shell_e1"
                  L4_2 = "loc_shell_e2"
                  L5_2 = "loc_shell_e3"
                  L6_2 = "loc_shell_e4"
                  L2_2[1] = L3_2
                  L2_2[2] = L4_2
                  L2_2[3] = L5_2
                  L2_2[4] = L6_2
                  L1_2 = L2_2
                else
                  L2_2 = nPlyrLoc
                  if L2_2 == 9 then
                    L2_2 = {}
                    L3_2 = "loc_shell_f1"
                    L4_2 = "loc_shell_f2"
                    L5_2 = "loc_shell_f3"
                    L6_2 = "loc_shell_f4"
                    L2_2[1] = L3_2
                    L2_2[2] = L4_2
                    L2_2[3] = L5_2
                    L2_2[4] = L6_2
                    L1_2 = L2_2
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  L2_2 = MrxUtil
  L2_2 = L2_2.GetRandomTableElement
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  sRandomShell = L2_2
  L2_2 = RandomShelling
  L3_2 = A0_2
  L4_2 = sRandomShell
  L2_2(L3_2, L4_2)
end

RandomShellingCall = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2
  L2_2 = "Rocket Artillery Projectile"
  L3_2 = 0
  L4_2 = 1
  L5_2 = 1
  L6_2 = 15
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = A1_2
  L7_2 = L7_2(L8_2)
  L8_2 = Object
  L8_2 = L8_2.GetPosition
  L9_2 = L7_2
  L8_2, L9_2, L10_2 = L8_2(L9_2)
  L11_2 = Object
  L11_2 = L11_2.GetPosition
  L12_2 = Player
  L12_2 = L12_2.GetPrimaryCharacter
  L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2 = L12_2()
  L11_2, L12_2, L13_2 = L11_2(L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2)
  L14_2 = math
  L14_2 = L14_2.randf
  L14_2 = L14_2()
  L14_2 = L14_2 * 10
  L15_2 = math
  L15_2 = L15_2.randf
  L15_2 = L15_2()
  L15_2 = L15_2 * 10
  L14_2 = L14_2 - L15_2
  L14_2 = L8_2 - L14_2
  L15_2 = L14_2 - L11_2
  L16_2 = L9_2 - L12_2
  L17_2 = L10_2 - L13_2
  L18_2 = Math
  L18_2 = L18_2.Normalize
  L19_2 = L15_2
  L20_2 = L16_2
  L21_2 = L17_2
  L18_2, L19_2, L20_2 = L18_2(L19_2, L20_2, L21_2)
  L17_2 = L20_2
  L16_2 = L19_2
  L15_2 = L18_2
  L18_2 = L10_2 - L13_2
  L18_2 = -L18_2
  L19_2 = 0
  L20_2 = L14_2 - L11_2
  L21_2 = Math
  L21_2 = L21_2.Normalize
  L22_2 = L18_2
  L23_2 = L19_2
  L24_2 = L20_2
  L21_2, L22_2, L23_2 = L21_2(L22_2, L23_2, L24_2)
  L20_2 = L23_2
  L19_2 = L22_2
  L18_2 = L21_2
  L21_2 = 1
  L22_2 = L5_2
  L23_2 = 1
  for L24_2 = L21_2, L22_2, L23_2 do
    L25_2 = L3_2
    L26_2 = L4_2
    L27_2 = math
    L27_2 = L27_2.randf
    L27_2 = L27_2()
    L27_2 = L27_2 * L25_2
    L28_2 = math
    L28_2 = L28_2.randf
    L28_2 = L28_2()
    L28_2 = L28_2 * L25_2
    L27_2 = L27_2 - L28_2
    L28_2 = 2.5 - L24_2
    L28_2 = L28_2 * L25_2
    L27_2 = L27_2 + L28_2
    L27_2 = -L27_2
    L28_2 = math
    L28_2 = L28_2.randf
    L28_2 = L28_2()
    L28_2 = L28_2 * L26_2
    L29_2 = math
    L29_2 = L29_2.randf
    L29_2 = L29_2()
    L29_2 = L29_2 * L26_2
    L28_2 = L28_2 - L29_2
    L28_2 = -L28_2
    L29_2 = {}
    L29_2.sAmmo = L2_2
    L30_2 = L18_2 * L27_2
    L30_2 = L14_2 + L30_2
    L31_2 = L15_2 * L28_2
    L30_2 = L30_2 + L31_2
    L29_2.nTargetX = L30_2
    L30_2 = L9_2 + 250
    L29_2.nTargetY = L30_2
    L30_2 = L20_2 * L27_2
    L30_2 = L10_2 + L30_2
    L31_2 = L17_2 * L28_2
    L30_2 = L30_2 + L31_2
    L29_2.nTargetZ = L30_2
    L30_2 = uStrikeLoc
    if L30_2 then
      L30_2 = Pg
      L30_2 = L30_2.GetGuidByName
      L31_2 = "loc_Rockets_"
      L32_2 = uEncounter
      L33_2 = "_"
      L34_2 = L24_2
      L31_2 = L31_2 .. L32_2 .. L33_2 .. L34_2
      L30_2 = L30_2(L31_2)
      if L30_2 then
        L31_2 = Object
        L31_2 = L31_2.GetPosition
        L32_2 = L30_2
        L31_2, L32_2, L33_2 = L31_2(L32_2)
        L34_2 = {}
        L34_2.sAmmo = L2_2
        L34_2.nTargetX = L31_2
        L35_2 = L32_2 + 250
        L34_2.nTargetY = L35_2
        L34_2.nTargetZ = L33_2
      else
        L29_2 = nil
      end
    end
    L30_2 = Pg
    L30_2 = L30_2.GetGuidByName
    L31_2 = "China"
    L30_2 = L30_2(L31_2)
    if L29_2 then
      L32_2 = A0_2
      L31_2 = A0_2._CreateEvent
      L33_2 = Event
      L33_2 = L33_2.TimerRelative
      L34_2 = {}
      L35_2 = L6_2 / 22
      L35_2 = L24_2 * L35_2
      L35_2 = 2 + L35_2
      L34_2[1] = L35_2
      L35_2 = TriggerFallingMissile
      L36_2 = {}
      L37_2 = L29_2
      L38_2 = L30_2
      L36_2[1] = L37_2
      L36_2[2] = L38_2
      L31_2(L32_2, L33_2, L34_2, L35_2, L36_2)
    end
  end
end

RandomShelling = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = Airstrike
  L2_2 = L2_2.SpawnOrdnance
  L3_2 = A0_2.sAmmo
  L4_2 = A0_2.nTargetX
  L5_2 = A0_2.nTargetY
  L6_2 = A0_2.nTargetZ
  L7_2 = 0
  L8_2 = -100
  L9_2 = 0
  L10_2 = "impact"
  L11_2 = 1
  L12_2 = A1_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
end

TriggerFallingMissile = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = _OutsideBoundary
  L2_2 = A0_2
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "rgn_checkspawn_a"
  L3_2 = L3_2(L4_2)
  L4_2 = 1
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = _OutsideBoundary
  L2_2 = A0_2
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "rgn_checkspawn_b"
  L3_2 = L3_2(L4_2)
  L4_2 = 2
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = _OutsideBoundary
  L2_2 = A0_2
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "rgn_checkspawn_c"
  L3_2 = L3_2(L4_2)
  L4_2 = 3
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = _OutsideBoundary
  L2_2 = A0_2
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "rgn_checkspawn_d"
  L3_2 = L3_2(L4_2)
  L4_2 = 4
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = _OutsideBoundary
  L2_2 = A0_2
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "rgn_checkspawn_e"
  L3_2 = L3_2(L4_2)
  L4_2 = 5
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = _OutsideBoundary
  L2_2 = A0_2
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "rgn_checkspawn_f"
  L3_2 = L3_2(L4_2)
  L4_2 = 6
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = _OutsideBoundary
  L2_2 = A0_2
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "rgn_checkspawn_g"
  L3_2 = L3_2(L4_2)
  L4_2 = 7
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = _OutsideBoundary
  L2_2 = A0_2
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "rgn_checkspawn_h"
  L3_2 = L3_2(L4_2)
  L4_2 = 8
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = _OutsideBoundary
  L2_2 = A0_2
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "rgn_checkspawn_i"
  L3_2 = L3_2(L4_2)
  L4_2 = 9
  L1_2(L2_2, L3_2, L4_2)
end

BoundaryTriggers = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  nPlyrLoc = A2_2
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.Boundary
  L6_2 = {}
  L7_2 = Player
  L7_2 = L7_2.GetAnyCharacter
  L7_2 = L7_2()
  L8_2 = A1_2
  L9_2 = "exit"
  L10_2 = false
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L7_2 = _OutsideBoundary
  L8_2 = {}
  L9_2 = A0_2
  L10_2 = A1_2
  L11_2 = A2_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
end

_InsideBoundary = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.Boundary
  L6_2 = {}
  L7_2 = Player
  L7_2 = L7_2.GetAnyCharacter
  L7_2 = L7_2()
  L8_2 = A1_2
  L9_2 = "enter"
  L10_2 = false
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L7_2 = _InsideBoundary
  L8_2 = {}
  L9_2 = A0_2
  L10_2 = A1_2
  L11_2 = A2_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
end

_OutsideBoundary = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L1_2 = {}
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "rgn_checkspawn_a"
  L2_2 = L2_2(L3_2)
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "rgn_checkspawn_b"
  L3_2 = L3_2(L4_2)
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "rgn_checkspawn_c"
  L4_2 = L4_2(L5_2)
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "rgn_checkspawn_d"
  L5_2 = L5_2(L6_2)
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "rgn_checkspawn_e"
  L6_2 = L6_2(L7_2)
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "rgn_checkspawn_f"
  L7_2 = L7_2(L8_2)
  L8_2 = Pg
  L8_2 = L8_2.GetGuidByName
  L9_2 = "rgn_checkspawn_g"
  L8_2 = L8_2(L9_2)
  L9_2 = Pg
  L9_2 = L9_2.GetGuidByName
  L10_2 = "rgn_checkspawn_h"
  L9_2 = L9_2(L10_2)
  L10_2 = Pg
  L10_2 = L10_2.GetGuidByName
  L11_2 = "rgn_checkspawn_i"
  L10_2, L11_2, L12_2, L13_2, L14_2, L15_2 = L10_2(L11_2)
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L1_2[7] = L8_2
  L1_2[8] = L9_2
  L1_2[9] = L10_2
  L1_2[10] = L11_2
  L1_2[11] = L12_2
  L1_2[12] = L13_2
  L1_2[13] = L14_2
  L1_2[14] = L15_2
  L2_2 = {}
  L3_2 = 1
  L4_2 = 2
  L5_2 = 3
  L6_2 = 4
  L7_2 = 5
  L8_2 = 6
  L9_2 = 7
  L10_2 = 8
  L11_2 = 9
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L2_2[6] = L8_2
  L2_2[7] = L9_2
  L2_2[8] = L10_2
  L2_2[9] = L11_2
  L3_2 = Object
  L3_2 = L3_2.GetPosition
  L4_2 = uPlayerOne
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  L6_2 = ipairs
  L7_2 = L1_2
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  for L9_2, L10_2 in L6_2, L7_2, L8_2 do
    L11_2 = Pg
    L11_2 = L11_2.IsPointInBoundary
    L12_2 = L3_2
    L13_2 = L4_2
    L14_2 = L5_2
    L15_2 = L10_2
    L11_2 = L11_2(L12_2, L13_2, L14_2, L15_2)
    bLocated = L11_2
    L11_2 = bLocated
    if L11_2 then
      L11_2 = L2_2[L9_2]
      return L11_2
    end
  end
end

PlayerLocation = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L3_2 = A0_2
  L2_2 = A0_2.PlayerLocation
  L2_2 = L2_2(L3_2)
  nPlyrLoc = L2_2
  L2_2 = nSpawn
  if L2_2 < 16 then
    L2_2 = tSpawnType
    L2_2 = L2_2[1]
    sSpawnType = L2_2
  else
    L2_2 = nSpawn
    if L2_2 < 36 then
      L2_2 = nSpawn
      if 15 < L2_2 then
        L2_2 = tSpawnType
        L2_2 = L2_2[2]
        sSpawnType = L2_2
    end
    else
      L2_2 = nSpawn
      if 35 < L2_2 then
        L2_2 = tSpawnType
        L2_2 = L2_2[3]
        sSpawnType = L2_2
      end
    end
  end
  L2_2 = nPlyrLoc
  if L2_2 == 1 then
    L2_2 = {}
    L3_2 = "spawna_1"
    L4_2 = "spawna_2"
    L5_2 = "spawna_3"
    L6_2 = "spawna_4"
    L7_2 = "spawnb_1"
    L8_2 = "spawnb_2"
    L9_2 = "spawnb_3"
    L10_2 = "spawnb_4"
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
    L2_2[4] = L6_2
    L2_2[5] = L7_2
    L2_2[6] = L8_2
    L2_2[7] = L9_2
    L2_2[8] = L10_2
    tSpawners = L2_2
  else
    L2_2 = nPlyrLoc
    if L2_2 == 2 then
      L2_2 = {}
      L3_2 = "spawna_1"
      L4_2 = "spawna_2"
      L5_2 = "spawna_3"
      L6_2 = "spawna_4"
      L7_2 = "spawnc_1"
      L8_2 = "spawnc_2"
      L9_2 = "spawnc_3"
      L10_2 = "spawnc_4"
      L2_2[1] = L3_2
      L2_2[2] = L4_2
      L2_2[3] = L5_2
      L2_2[4] = L6_2
      L2_2[5] = L7_2
      L2_2[6] = L8_2
      L2_2[7] = L9_2
      L2_2[8] = L10_2
      tSpawners = L2_2
    else
      L2_2 = nPlyrLoc
      if L2_2 == 3 then
        L2_2 = {}
        L3_2 = "spawnb_1"
        L4_2 = "spawnb_2"
        L5_2 = "spawnb_3"
        L6_2 = "spawnb_4"
        L7_2 = "spawnc_1"
        L8_2 = "spawnc_2"
        L9_2 = "spawnc_3"
        L10_2 = "spawnc_4"
        L2_2[1] = L3_2
        L2_2[2] = L4_2
        L2_2[3] = L5_2
        L2_2[4] = L6_2
        L2_2[5] = L7_2
        L2_2[6] = L8_2
        L2_2[7] = L9_2
        L2_2[8] = L10_2
        tSpawners = L2_2
      else
        L2_2 = nPlyrLoc
        if L2_2 == 4 then
          L2_2 = {}
          L3_2 = "spawnd_1"
          L4_2 = "spawnd_2"
          L5_2 = "spawnd_3"
          L6_2 = "spawnd_4"
          L7_2 = "spawne_1"
          L8_2 = "spawne_2"
          L9_2 = "spawne_3"
          L10_2 = "spawne_4"
          L2_2[1] = L3_2
          L2_2[2] = L4_2
          L2_2[3] = L5_2
          L2_2[4] = L6_2
          L2_2[5] = L7_2
          L2_2[6] = L8_2
          L2_2[7] = L9_2
          L2_2[8] = L10_2
          tSpawners = L2_2
        else
          L2_2 = nPlyrLoc
          if L2_2 == 5 then
            L2_2 = {}
            L3_2 = "spawnd_1"
            L4_2 = "spawnd_2"
            L5_2 = "spawnd_3"
            L6_2 = "spawnd_4"
            L7_2 = "spawnf_1"
            L8_2 = "spawnf_2"
            L9_2 = "spawnf_3"
            L10_2 = "spawnf_4"
            L2_2[1] = L3_2
            L2_2[2] = L4_2
            L2_2[3] = L5_2
            L2_2[4] = L6_2
            L2_2[5] = L7_2
            L2_2[6] = L8_2
            L2_2[7] = L9_2
            L2_2[8] = L10_2
            tSpawners = L2_2
          else
            L2_2 = nPlyrLoc
            if L2_2 == 6 then
              L2_2 = {}
              L3_2 = "spawne_1"
              L4_2 = "spawne_2"
              L5_2 = "spawne_3"
              L6_2 = "spawne_4"
              L7_2 = "spawnf_1"
              L8_2 = "spawnf_2"
              L9_2 = "spawnf_3"
              L10_2 = "spawnf_4"
              L2_2[1] = L3_2
              L2_2[2] = L4_2
              L2_2[3] = L5_2
              L2_2[4] = L6_2
              L2_2[5] = L7_2
              L2_2[6] = L8_2
              L2_2[7] = L9_2
              L2_2[8] = L10_2
              tSpawners = L2_2
            else
              L2_2 = nPlyrLoc
              if L2_2 == 7 then
                L2_2 = {}
                L3_2 = "spawna_1"
                L4_2 = "spawna_2"
                L5_2 = "spawna_3"
                L6_2 = "spawna_4"
                L7_2 = "spawnb_1"
                L8_2 = "spawnb_2"
                L9_2 = "spawnb_3"
                L10_2 = "spawnb_4"
                L2_2[1] = L3_2
                L2_2[2] = L4_2
                L2_2[3] = L5_2
                L2_2[4] = L6_2
                L2_2[5] = L7_2
                L2_2[6] = L8_2
                L2_2[7] = L9_2
                L2_2[8] = L10_2
                tSpawners = L2_2
              else
                L2_2 = nPlyrLoc
                if L2_2 == 8 then
                  L2_2 = {}
                  L3_2 = "spawna_1"
                  L4_2 = "spawna_2"
                  L5_2 = "spawna_3"
                  L6_2 = "spawna_4"
                  L7_2 = "spawnc_1"
                  L8_2 = "spawnc_2"
                  L9_2 = "spawnc_3"
                  L10_2 = "spawnc_4"
                  L2_2[1] = L3_2
                  L2_2[2] = L4_2
                  L2_2[3] = L5_2
                  L2_2[4] = L6_2
                  L2_2[5] = L7_2
                  L2_2[6] = L8_2
                  L2_2[7] = L9_2
                  L2_2[8] = L10_2
                  tSpawners = L2_2
                else
                  L2_2 = nPlyrLoc
                  if L2_2 == 9 then
                    L2_2 = {}
                    L3_2 = "spawnb_1"
                    L4_2 = "spawnb_2"
                    L5_2 = "spawnb_3"
                    L6_2 = "spawnb_4"
                    L7_2 = "spawnc_1"
                    L8_2 = "spawnc_2"
                    L9_2 = "spawnc_3"
                    L10_2 = "spawnc_4"
                    L2_2[1] = L3_2
                    L2_2[2] = L4_2
                    L2_2[3] = L5_2
                    L2_2[4] = L6_2
                    L2_2[5] = L7_2
                    L2_2[6] = L8_2
                    L2_2[7] = L9_2
                    L2_2[8] = L10_2
                    tSpawners = L2_2
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  L2_2 = ipairs
  L3_2 = tSpawners
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = nLive
    if L7_2 < 13 then
      L7_2 = Pg
      L7_2 = L7_2.GetGuidByName
      L8_2 = L6_2
      L7_2 = L7_2(L8_2)
      L8_2 = math
      L8_2 = L8_2.randi
      L9_2 = 11
      L8_2 = L8_2(L9_2)
      L8_2 = L8_2 - 1
      L10_2 = A0_2
      L9_2 = A0_2._CreateEvent
      L11_2 = Event
      L11_2 = L11_2.TimerRelative
      L12_2 = {}
      L13_2 = L8_2
      L12_2[1] = L13_2
      L13_2 = SpawnEnemyTank
      L14_2 = {}
      L15_2 = A0_2
      L16_2 = sSpawnType
      L17_2 = L7_2
      L14_2[1] = L15_2
      L14_2[2] = L16_2
      L14_2[3] = L17_2
      L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
    end
  end
end

TestSpawn = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = MrxUtil
  L3_2 = L3_2.SpawnObject
  L4_2 = A1_2
  L5_2 = A2_2
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = nLive
  L4_2 = L4_2 + 1
  nLive = L4_2
  L4_2 = nSpawn
  L4_2 = L4_2 + 1
  nSpawn = L4_2
  L4_2 = {}
  L5_2 = {}
  L4_2.tExitGoals = L5_2
  L5_2 = A0_2.tVehicleEvents
  L5_2[L3_2] = L4_2
  L6_2 = A0_2
  L5_2 = A0_2._CreateEvent
  L7_2 = Event
  L7_2 = L7_2.ObjectHibernation
  L8_2 = {}
  L9_2 = L3_2
  L10_2 = "awake"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L9_2 = SetupEnemyTank
  L10_2 = {}
  L11_2 = A0_2
  L12_2 = L3_2
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L4_2.eHibernate = L5_2
  L5_2 = table
  L5_2 = L5_2.insert
  L6_2 = tSpawned
  L7_2 = L3_2
  L5_2(L6_2, L7_2)
end

SpawnEnemyTank = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L2_2 = A0_2.tVehicleEvents
  L2_2 = L2_2[A1_2]
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.ObjectDeath
  L6_2 = {}
  L7_2 = A1_2
  L6_2[1] = L7_2
  L7_2 = OnEnemyTankKilled
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  L2_2.eDeath = L3_2
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L5_2 = A0_2
  L4_2 = A0_2._CreateEvent
  L6_2 = Event
  L6_2 = L6_2.ObjectInSeat
  L7_2 = {}
  L8_2 = L3_2
  L9_2 = A1_2
  L10_2 = "d"
  L11_2 = "x"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L8_2 = OnEnemyTankKilled
  L9_2 = {}
  L10_2 = A0_2
  L11_2 = A1_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  L2_2.eHijack = L4_2
  L4_2 = {}
  L2_2.tRegions = L4_2
  L4_2 = ipairs
  L5_2 = tExitLocs
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = Pg
    L9_2 = L9_2.GetGuidByName
    L10_2 = L8_2
    L9_2 = L9_2(L10_2)
    L11_2 = A0_2
    L10_2 = A0_2.OnEnemyTankOutsideExitRegion
    L12_2 = A1_2
    L13_2 = L8_2
    L10_2(L11_2, L12_2, L13_2)
    L10_2 = L2_2.tExitGoals
    L12_2 = A0_2
    L11_2 = A0_2._CreateEvent
    L13_2 = Event
    L13_2 = L13_2.ObjectProximity
    L14_2 = {}
    L15_2 = A1_2
    L16_2 = L9_2
    L17_2 = "<"
    L18_2 = 20
    L19_2 = false
    L20_2 = false
    L14_2[1] = L15_2
    L14_2[2] = L16_2
    L14_2[3] = L17_2
    L14_2[4] = L18_2
    L14_2[5] = L19_2
    L14_2[6] = L20_2
    L15_2 = OnEnemyTankEscaping
    L16_2 = {}
    L17_2 = A0_2
    L18_2 = A1_2
    L16_2[1] = L17_2
    L16_2[2] = L18_2
    L11_2 = L11_2(L12_2, L13_2, L14_2, L15_2, L16_2)
    L10_2[L9_2] = L11_2
  end
  L4_2 = {}
  L5_2 = 7
  L6_2 = 7
  L7_2 = 7
  L8_2 = 8.5
  L9_2 = 10
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L6_2 = A0_2
  L5_2 = A0_2.ChoosePath
  L7_2 = L3_2
  L8_2 = nil
  L9_2 = 0
  L10_2 = MrxUtil
  L10_2 = L10_2.GetRandomTableElement
  L11_2 = L4_2
  L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2 = L10_2(L11_2)
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
end

SetupEnemyTank = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = Object
  L2_2 = L2_2.IsPlayerControlled
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L2_2 = Object
    L2_2 = L2_2.FadeOut
    L3_2 = A1_2
    L4_2 = 10
    L5_2 = true
    L2_2(L3_2, L4_2, L5_2)
  end
  L2_2 = nTankDeath
  L2_2 = L2_2 + 1
  nTankDeath = L2_2
  L2_2 = "Alert_"
  L3_2 = tostring
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L2_2 = L2_2 .. L3_2
  if L2_2 then
    L2_2 = Minimap
    L3_2 = L2_2
    L2_2 = L2_2.DeleteObjective
    L4_2 = "Alert_"
    L5_2 = tostring
    L6_2 = A1_2
    L5_2 = L5_2(L6_2)
    L4_2 = L4_2 .. L5_2
    L2_2(L3_2, L4_2)
  end
  L2_2 = nLive
  L2_2 = L2_2 - 1
  nLive = L2_2
  L2_2 = nLive
  if L2_2 < 0 then
    L2_2 = 0
    nLive = L2_2
  end
  L2_2 = nLive
  if L2_2 < 3 then
    L3_2 = A0_2
    L2_2 = A0_2.TestSpawn
    L2_2(L3_2)
  end
  L2_2 = nLive
  if L2_2 < 5 then
    L3_2 = A0_2
    L2_2 = A0_2.RandomShellingWakeUp
    L2_2(L3_2)
  end
  L2_2 = Object
  L2_2 = L2_2.GetParent
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  L3_2 = nKillBonus
  L3_2 = L3_2[L2_2]
  if L3_2 then
    L4_2 = A0_2.nTankMoney
    L4_2 = L4_2 + L3_2
    A0_2.nTankMoney = L4_2
    L4_2 = MrxPmc
    L4_2 = L4_2.AddCashQty
    L5_2 = L3_2
    L6_2 = nil
    L4_2(L5_2, L6_2)
    L4_2 = Hud
    L4_2 = L4_2.ResourceCounter
    L5_2 = L4_2
    L4_2 = L4_2.Show
    L6_2 = {}
    L6_2.nDuration = -1
    L4_2(L5_2, L6_2)
    L4_2 = Hud
    L4_2 = L4_2.ResourceCounter
    L5_2 = L4_2
    L4_2 = L4_2.SetSuppressed
    L6_2 = {}
    L6_2.bSuppressCash = false
    L6_2.bSuppressFuel = true
    L4_2(L5_2, L6_2)
  else
  end
  L4_2 = nTankDeath
  L5_2 = nTBSpawn
  if L4_2 == L5_2 then
    L5_2 = A0_2
    L4_2 = A0_2.TankBusterSpawn
    L4_2(L5_2)
    L4_2 = nTBSpawn
    L4_2 = L4_2 + 25
    nTBSpawn = L4_2
  end
  L4_2 = nTankDeath
  L5_2 = nRoundValue
  if L4_2 == L5_2 then
    L4_2 = nRound
    L4_2 = L4_2 + 1
    nRound = L4_2
    L4_2 = nRoundValue
    L4_2 = L4_2 + 20
    nRoundValue = L4_2
  end
  L5_2 = A0_2
  L4_2 = A0_2.RemoveEnemyTankFromRegionCounters
  L6_2 = A1_2
  L4_2(L5_2, L6_2)
  L5_2 = A0_2
  L4_2 = A0_2.CleanupEnemyTank
  L6_2 = A1_2
  L4_2(L5_2, L6_2)
end

OnEnemyTankKilled = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = A0_2.tVehicleEvents
  L2_2 = L2_2[A1_2]
  L3_2 = pairs
  L4_2 = tExitLocs
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = Pg
    L8_2 = L8_2.GetGuidByName
    L9_2 = L7_2
    L10_2 = "_alert"
    L9_2 = L9_2 .. L10_2
    L8_2 = L8_2(L9_2)
    L9_2 = L2_2.tRegions
    L9_2 = L9_2[L8_2]
    if L9_2 then
      L9_2 = A0_2.tExitRegionCounters
      L10_2 = A0_2.tExitRegionCounters
      L10_2 = L10_2[L8_2]
      L10_2 = L10_2 - 1
      L9_2[L8_2] = L10_2
      L10_2 = A0_2
      L9_2 = A0_2.UpdateExitRegion
      L11_2 = L7_2
      L9_2(L10_2, L11_2)
    end
  end
end

RemoveEnemyTankFromRegionCounters = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L3_2 = A0_2.tVehicleEvents
  L3_2 = L3_2[A1_2]
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = A2_2
  L6_2 = "_alert"
  L5_2 = L5_2 .. L6_2
  L4_2 = L4_2(L5_2)
  L5_2 = Event
  L5_2 = L5_2.Delete
  L6_2 = L3_2.tExitGoals
  L6_2 = L6_2[L4_2]
  L5_2(L6_2)
  L5_2 = L3_2.tExitGoals
  L7_2 = A0_2
  L6_2 = A0_2._CreateEvent
  L8_2 = Event
  L8_2 = L8_2.Boundary
  L9_2 = {}
  L10_2 = A1_2
  L11_2 = L4_2
  L12_2 = "enter"
  L13_2 = false
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L9_2[3] = L12_2
  L9_2[4] = L13_2
  L10_2 = OnEnemyTankTankInsideExitRegion
  L11_2 = {}
  L12_2 = A0_2
  L13_2 = A1_2
  L14_2 = A2_2
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L11_2[3] = L14_2
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  L5_2[L4_2] = L6_2
  L5_2 = L3_2.tRegions
  L5_2[L4_2] = nil
  L5_2 = A0_2.tExitRegionCounters
  L5_2 = L5_2[L4_2]
  if L5_2 then
    L5_2 = A0_2.tExitRegionCounters
    L5_2 = L5_2[L4_2]
    if 0 < L5_2 then
      L5_2 = A0_2.tExitRegionCounters
      L6_2 = A0_2.tExitRegionCounters
      L6_2 = L6_2[L4_2]
      L6_2 = L6_2 - 1
      L5_2[L4_2] = L6_2
      L6_2 = A0_2
      L5_2 = A0_2.UpdateExitRegion
      L7_2 = A2_2
      L5_2(L6_2, L7_2)
    end
  else
    L5_2 = A0_2.tExitRegionCounters
    L5_2[L4_2] = 0
  end
end

OnEnemyTankOutsideExitRegion = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L3_2 = A0_2.tVehicleEvents
  L3_2 = L3_2[A1_2]
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = A2_2
  L6_2 = "_alert"
  L5_2 = L5_2 .. L6_2
  L4_2 = L4_2(L5_2)
  L5_2 = Event
  L5_2 = L5_2.Delete
  L6_2 = L3_2.tExitGoals
  L6_2 = L6_2[L4_2]
  L5_2(L6_2)
  L5_2 = L3_2.tExitGoals
  L7_2 = A0_2
  L6_2 = A0_2._CreateEvent
  L8_2 = Event
  L8_2 = L8_2.Boundary
  L9_2 = {}
  L10_2 = A1_2
  L11_2 = L4_2
  L12_2 = "exit"
  L13_2 = false
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L9_2[3] = L12_2
  L9_2[4] = L13_2
  L10_2 = OnEnemyTankOutsideExitRegion
  L11_2 = {}
  L12_2 = A0_2
  L13_2 = A1_2
  L14_2 = A2_2
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L11_2[3] = L14_2
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  L5_2[L4_2] = L6_2
  L5_2 = L3_2.tRegions
  L5_2[L4_2] = true
  L5_2 = A0_2.tExitRegionCounters
  L6_2 = A0_2.tExitRegionCounters
  L6_2 = L6_2[L4_2]
  L6_2 = L6_2 + 1
  L5_2[L4_2] = L6_2
  L6_2 = A0_2
  L5_2 = A0_2.UpdateExitRegion
  L7_2 = A2_2
  L8_2 = A1_2
  L5_2(L6_2, L7_2, L8_2)
end

OnEnemyTankTankInsideExitRegion = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = A1_2
  L5_2 = "_alert"
  L4_2 = L4_2 .. L5_2
  L3_2 = L3_2(L4_2)
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  L5_2 = "Blip_"
  L6_2 = A1_2
  L5_2 = L5_2 .. L6_2
  L6_2 = A0_2.tExitRegionCounters
  L6_2 = L6_2[L3_2]
  if 0 < L6_2 then
    L6_2 = Hud
    L6_2 = L6_2.MessageBox
    L7_2 = L6_2
    L6_2 = L6_2.AddMessage
    L8_2 = {}
    L8_2.sMessage = "[DLCCon003.Terms.alert01]"
    L6_2(L7_2, L8_2)
    L6_2 = Hud
    L6_2 = L6_2.Radar
    L7_2 = L6_2
    L6_2 = L6_2.AnimateObjectiveAlpha
    L8_2 = {}
    L8_2.sName = L5_2
    L8_2.nDuration = 0
    L8_2.nMinAlpha = 0.1
    L8_2.nMaxAlpha = 0.8
    L8_2.nSpeed = 3
    L6_2(L7_2, L8_2)
    L6_2 = 75
    L7_2 = nil
    L8_2 = Object
    L8_2 = L8_2.GetPosition
    L9_2 = L4_2
    L8_2, L9_2, L10_2 = L8_2(L9_2)
    L11_2 = Pg
    L11_2 = L11_2.FastCollectTanks
    L12_2 = L8_2
    L13_2 = L9_2
    L14_2 = L10_2
    L15_2 = L6_2
    L11_2 = L11_2(L12_2, L13_2, L14_2, L15_2)
    L12_2 = pairs
    L13_2 = L11_2
    L12_2, L13_2, L14_2 = L12_2(L13_2)
    for L15_2, L16_2 in L12_2, L13_2, L14_2 do
      L17_2 = Object
      L17_2 = L17_2.HasLabel
      L18_2 = L16_2
      L19_2 = "china"
      L17_2 = L17_2(L18_2, L19_2)
      if L17_2 then
        L17_2 = Object
        L17_2 = L17_2.IsPlayerControlled
        L18_2 = L16_2
        L17_2 = L17_2(L18_2)
        if not L17_2 then
          L7_2 = true
          break
        end
      end
    end
    if L7_2 then
      L12_2 = Marker
      L12_2 = L12_2.Pulse
      L13_2 = L4_2
      L14_2 = 255
      L15_2 = 0
      L16_2 = 0
      L12_2(L13_2, L14_2, L15_2, L16_2)
    elseif A2_2 then
      L12_2 = Marker
      L12_2 = L12_2.Pulse
      L13_2 = L4_2
      L14_2 = 255
      L15_2 = 200
      L16_2 = 0
      L12_2(L13_2, L14_2, L15_2, L16_2)
      L13_2 = A0_2
      L12_2 = A0_2._CreateEvent
      L14_2 = Event
      L14_2 = L14_2.ObjectProximity
      L15_2 = {}
      L16_2 = A2_2
      L17_2 = L4_2
      L18_2 = "<"
      L19_2 = L6_2
      L20_2 = false
      L21_2 = false
      L15_2[1] = L16_2
      L15_2[2] = L17_2
      L15_2[3] = L18_2
      L15_2[4] = L19_2
      L15_2[5] = L20_2
      L15_2[6] = L21_2
      L16_2 = Marker
      L16_2 = L16_2.Pulse
      L17_2 = {}
      L18_2 = L4_2
      L19_2 = 255
      L20_2 = 0
      L21_2 = 0
      L17_2[1] = L18_2
      L17_2[2] = L19_2
      L17_2[3] = L20_2
      L17_2[4] = L21_2
      L12_2(L13_2, L14_2, L15_2, L16_2, L17_2)
    else
      L12_2 = Marker
      L12_2 = L12_2.Pulse
      L13_2 = L4_2
      L14_2 = 255
      L15_2 = 200
      L16_2 = 0
      L12_2(L13_2, L14_2, L15_2, L16_2)
    end
  else
    L6_2 = Hud
    L6_2 = L6_2.Radar
    L7_2 = L6_2
    L6_2 = L6_2.UnanimateObjective
    L8_2 = {}
    L8_2.sName = L5_2
    L6_2(L7_2, L8_2)
    L6_2 = Marker
    L6_2 = L6_2.HaltPulse
    L7_2 = L4_2
    L6_2(L7_2)
  end
end

UpdateExitRegion = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = A0_2.tVehicleEvents
  L2_2 = L2_2[A1_2]
  L3_2 = Object
  L3_2 = L3_2.GetParent
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = nEscPen
  L4_2 = L4_2[L3_2]
  if not L4_2 then
    L4_2 = 1000000
  end
  L5_2 = Object
  L5_2 = L5_2.FadeOut
  L6_2 = A1_2
  L7_2 = 1.5
  L8_2 = true
  L5_2(L6_2, L7_2, L8_2)
  L6_2 = A0_2
  L5_2 = A0_2._CreateEvent
  L7_2 = Event
  L7_2 = L7_2.ObjectDelete
  L8_2 = {}
  L9_2 = A1_2
  L8_2[1] = L9_2
  L9_2 = OnEnemyTankEscaped
  L10_2 = {}
  L11_2 = A0_2
  L12_2 = A1_2
  L13_2 = L4_2
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L2_2.eEscaping = L5_2
end

OnEnemyTankEscaping = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = Minimap
  L4_2 = L3_2
  L3_2 = L3_2.DeleteObjective
  L5_2 = "Alert_"
  L6_2 = tostring
  L7_2 = A1_2
  L6_2 = L6_2(L7_2)
  L5_2 = L5_2 .. L6_2
  L3_2(L4_2, L5_2)
  L3_2 = nGoal
  L3_2 = L3_2 + 1
  nGoal = L3_2
  L3_2 = Hud
  L3_2 = L3_2.ObjectiveTray
  L4_2 = L3_2
  L3_2 = L3_2.SetSlotToText
  L5_2 = {}
  L5_2.nSlot = 1
  L6_2 = "[DLCCon003.Display.escapedTanks]"
  L7_2 = nGoal
  L8_2 = "/"
  L9_2 = nFailCon
  L6_2 = L6_2 .. L7_2 .. L8_2 .. L9_2
  L5_2.sText = L6_2
  L3_2(L4_2, L5_2)
  L3_2 = MrxPmc
  L3_2 = L3_2.AddCashQty
  L4_2 = -A2_2
  L5_2 = nil
  L6_2 = "[DLCCon003.Display.scoreEscaped]"
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = A0_2.nEscapeMoney
  L3_2 = L3_2 + A2_2
  A0_2.nEscapeMoney = L3_2
  L3_2 = Hud
  L3_2 = L3_2.ResourceCounter
  L4_2 = L3_2
  L3_2 = L3_2.Show
  L5_2 = {}
  L5_2.nDuration = -1
  L3_2(L4_2, L5_2)
  L3_2 = Hud
  L3_2 = L3_2.ResourceCounter
  L4_2 = L3_2
  L3_2 = L3_2.SetSuppressed
  L5_2 = {}
  L5_2.bSuppressCash = false
  L5_2.bSuppressFuel = true
  L3_2(L4_2, L5_2)
  L3_2 = Hud
  L3_2 = L3_2.MessageBox
  L4_2 = L3_2
  L3_2 = L3_2.AddMessage
  L5_2 = {}
  L5_2.sMessage = "[DLCCon003.Terms.escaped]"
  L3_2(L4_2, L5_2)
  L3_2 = nGoal
  L4_2 = nFailCon
  L4_2 = L4_2 - 1
  if L3_2 < L4_2 then
    L3_2 = {}
    L4_2 = "Fiona-In-Mission-Contract-Dlc03-34"
    L5_2 = "Fiona-In-Mission-Contract-Dlc03-35"
    L6_2 = "Fiona-In-Mission-Contract-Dlc03-36"
    L7_2 = "Fiona-In-Mission-Contract-Dlc03-37"
    L8_2 = "Fiona-In-Mission-Contract-Dlc03-38"
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L3_2[4] = L7_2
    L3_2[5] = L8_2
    L5_2 = A0_2
    L4_2 = A0_2.NotifyPlayerVO
    L6_2 = L3_2
    L7_2 = 0.5
    L4_2(L5_2, L6_2, L7_2)
  else
    L3_2 = nGoal
    L4_2 = nFailCon
    L4_2 = L4_2 - 1
    if L3_2 == L4_2 then
      L3_2 = {}
      L4_2 = "Fiona-In-Mission-Contract-Dlc03-38"
      L3_2[1] = L4_2
      L5_2 = A0_2
      L4_2 = A0_2.NotifyPlayerVO
      L6_2 = L3_2
      L7_2 = 0.5
      L4_2(L5_2, L6_2, L7_2)
    else
      L4_2 = A0_2
      L3_2 = A0_2.TanksEscaped
      L3_2(L4_2)
      return
    end
  end
  L3_2 = nLive
  L3_2 = L3_2 - 1
  nLive = L3_2
  L3_2 = nLive
  if L3_2 < 0 then
    L3_2 = 0
    nLive = L3_2
  end
  L3_2 = nLive
  if L3_2 < 3 then
    L4_2 = A0_2
    L3_2 = A0_2.TestSpawn
    L3_2(L4_2)
  end
  L4_2 = A0_2
  L3_2 = A0_2.RemoveEnemyTankFromRegionCounters
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
  L4_2 = A0_2
  L3_2 = A0_2.CleanupEnemyTank
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
end

OnEnemyTankEscaped = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2.tVehicleEvents
  L2_2 = L2_2[A1_2]
  L2_2.tRegions = nil
  L3_2 = pairs
  L4_2 = L2_2.tExitGoals
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = Event
    L8_2 = L8_2.Delete
    L9_2 = L7_2
    L8_2(L9_2)
  end
  L2_2.tExitGoals = nil
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = Event
    L8_2 = L8_2.Delete
    L9_2 = L7_2
    L8_2(L9_2)
  end
  L3_2 = A0_2.tVehicleEvents
  L3_2[A1_2] = nil
end

CleanupEnemyTank = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L5_2 = A3_2 or nil
  if not A3_2 then
    L5_2 = 0
  end
  L6_2 = A0_2.FindIntersection
  if not L6_2 then
    return
  end
  L7_2 = A0_2
  L6_2 = A0_2.FindIntersection
  L8_2 = A1_2
  L9_2 = 20 + L5_2
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if not L6_2 then
    L7_2 = ChoosePath
    L8_2 = A0_2
    L9_2 = A1_2
    L10_2 = sPath
    L11_2 = L5_2 + 10
    L12_2 = A4_2
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  else
  end
  L7_2 = table
  L7_2 = L7_2.getn
  L8_2 = tCurNode
  L7_2 = L7_2(L8_2)
  L8_2 = math
  L8_2 = L8_2.randi
  L9_2 = L7_2
  L8_2 = L8_2(L9_2)
  L9_2 = tCurNode
  L9_2 = L9_2[L8_2]
  if L9_2 == A2_2 then
    L10_2 = ChoosePath
    L11_2 = A0_2
    L12_2 = A1_2
    L13_2 = L9_2
    L14_2 = L5_2 + 5
    L15_2 = A4_2
    L10_2(L11_2, L12_2, L13_2, L14_2, L15_2)
  else
    L10_2 = Pg
    L10_2 = L10_2.GetGuidByName
    L11_2 = tCurNode
    L11_2 = L11_2[L8_2]
    L10_2 = L10_2(L11_2)
    L11_2 = Ai
    L11_2 = L11_2.Goal
    L12_2 = {}
    L12_2.AIGuid = A1_2
    L12_2.Goal = "PathMove"
    L12_2.Target = L10_2
    L13_2 = nAdv
    L12_2.Haste = L13_2
    L12_2.Start = "First"
    L12_2.Mode = "Oneway"
    L12_2.Priority = 8.75
    L13_2 = ChoosePath
    L12_2.Callback = L13_2
    L13_2 = {}
    L14_2 = A0_2
    L15_2 = A1_2
    L16_2 = L9_2
    L17_2 = 0
    L18_2 = A4_2
    L13_2[1] = L14_2
    L13_2[2] = L15_2
    L13_2[3] = L16_2
    L13_2[4] = L17_2
    L13_2[5] = L18_2
    L12_2.CallbackData = L13_2
    L11_2(L12_2)
  end
end

ChoosePath = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L4_2 = {}
  if A3_2 then
    L5_2 = tPlayerNodes
    tPotential = L5_2
  else
    L5_2 = tIntersection
    tPotential = L5_2
  end
  L5_2 = ipairs
  L6_2 = tPotential
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = Pg
    L10_2 = L10_2.GetGuidByName
    L11_2 = L9_2
    L10_2 = L10_2(L11_2)
    L11_2 = MrxUtil
    L11_2 = L11_2.GetDistanceBetween
    L12_2 = A1_2
    L13_2 = L10_2
    L14_2 = true
    L11_2 = L11_2(L12_2, L13_2, L14_2)
    if A2_2 > L11_2 then
      L12_2 = tNodes
      L12_2 = L12_2[L8_2]
      tCurNode = L12_2
      return L9_2
    end
  end
end

FindIntersection = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = Hud
  L2_2 = L2_2.MessageBox
  L3_2 = L2_2
  L2_2 = L2_2.AddMessage
  L4_2 = {}
  L4_2.sMessage = "[DLCCon003.Terms.newPlayerTank_alt]"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2.FindIntersection
  L4_2 = A1_2
  L5_2 = 80
  L6_2 = true
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L3_2 = nil
  if L2_2 then
    L4_2 = Object
    L4_2 = L4_2.GetPosition
    L5_2 = Pg
    L5_2 = L5_2.GetGuidByName
    L6_2 = L2_2
    L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L5_2(L6_2)
    L4_2, L5_2, L6_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
    pZ = L6_2
    pY = L5_2
    pX = L4_2
  else
    L4_2 = Object
    L4_2 = L4_2.GetPosition
    L5_2 = Pg
    L5_2 = L5_2.GetGuidByName
    L6_2 = "DLCCon003_Player01_Tank_loc"
    L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L5_2(L6_2)
    L4_2, L5_2, L6_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
    pZ = L6_2
    pY = L5_2
    pX = L4_2
  end
  L4_2 = Object
  L4_2 = L4_2.FadeOut
  L5_2 = A1_2
  L6_2 = 3
  L7_2 = true
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = Pg
  L4_2 = L4_2.Spawn
  L5_2 = "DLC_M1A3"
  L6_2 = pX
  L7_2 = pY
  L8_2 = pZ
  L9_2 = 180
  L10_2 = false
  L11_2 = true
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  L5_2 = table
  L5_2 = L5_2.insert
  L6_2 = tSpawned
  L7_2 = L4_2
  L5_2(L6_2, L7_2)
  L6_2 = A0_2
  L5_2 = A0_2.SetupPlayerTank
  L7_2 = L4_2
  L5_2(L6_2, L7_2)
end

SpawnPlayerTank = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2._tEvents
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.ObjectDeath
  L6_2 = {}
  L7_2 = A1_2
  L6_2[1] = L7_2
  L7_2 = OnPlayerTankDeath
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  L2_2.ePlayerTankDeath = L3_2
  L2_2 = A0_2._tEvents
  L4_2 = A0_2
  L3_2 = A0_2._CreatePersistentEvent
  L5_2 = Event
  L5_2 = L5_2.ScriptEvent
  L6_2 = {}
  L7_2 = "RepairBayUsed"
  
  function L8_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = nRepairMoney
    L2_3 = A0_3[3]
    L1_3 = L1_3 + L2_3
    nRepairMoney = L1_3
    L1_3 = Object
    L1_3 = L1_3.HasLabel
    L2_3 = A0_3[1]
    L3_3 = "Allied"
    L1_3 = L1_3(L2_3, L3_3)
    if L1_3 then
      L1_3 = Object
      L1_3 = L1_3.HasLabel
      L2_3 = A0_3[1]
      L3_3 = "Tank"
      L1_3 = L1_3(L2_3, L3_3)
    end
    return L1_3
  end
  
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = OnPlayerTankRepair
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  L2_2.ePlayerTankRepaired = L3_2
  L2_2 = Object
  L2_2 = L2_2.IsPlayerControlled
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.OnPlayerEnterVehicle
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  else
    L3_2 = A0_2
    L2_2 = A0_2.OnPlayerExitVehicle
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  end
end

SetupPlayerTank = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = MrxTutorialManager
  L2_2 = L2_2.ShowMessage
  L3_2 = "[DLCCon003.UI.TDestroyed]"
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2.CleanupPlayerTankEvents
  L2_2(L3_2)
  L2_2 = nCurTankHealth
  L2_2 = L2_2 + 1
  nCurTankHealth = L2_2
  L3_2 = A0_2
  L2_2 = A0_2.TankLife
  L4_2 = uPlayer
  L2_2(L3_2, L4_2)
  L2_2 = nCurTankHealth
  if L2_2 <= 3 then
    L3_2 = A0_2
    L2_2 = A0_2.SpawnPlayerTank
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  else
    L3_2 = A0_2
    L2_2 = A0_2.NoReplacement
    L2_2(L3_2)
  end
end

OnPlayerTankDeath = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L3_2 = A0_2
  L2_2 = A0_2.CleanupPlayerTankEvents
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2.SetupPlayerTank
  L4_2 = A1_2[1]
  L2_2(L3_2, L4_2)
end

OnPlayerTankRepair = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2._tEvents
  L2_2 = L2_2.ePlayerTankDeath
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2._tEvents
  L2_2 = L2_2.ePlayerTankRepaired
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2._tEvents
  L2_2 = L2_2.eEnterUberVeh
  L1_2(L2_2)
end

CleanupPlayerTankEvents = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "Enter car"
  L4_2.sModuleName = "MrxTaskObjectiveEnterVehicle"
  L4_2.sDspShortDesc = "[MecCon001.Objectives.enterVehicle]"
  L4_2.vTgtInclude = A1_2
  L4_2.nQuota = 1
  L4_2.bDspBlp = true
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.OnPlayerEnterVehicle
    L2_3 = A1_2
    L0_3(L1_3, L2_3)
  end
  
  L4_2.fOnComplete = L5_2
  L2_2 = L2_2(L3_2, L4_2)
end

OnPlayerExitVehicle = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2._tEvents
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.ObjectInSeat
  L6_2 = {}
  L7_2 = Player
  L7_2 = L7_2.GetAnyCharacter
  L7_2 = L7_2()
  L8_2 = A1_2
  L9_2 = "a"
  L10_2 = "x"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L7_2 = OnPlayerExitVehicle
  L8_2 = {}
  L9_2 = A0_2
  L10_2 = A1_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  L2_2.eEnterUberVeh = L3_2
end

OnPlayerEnterVehicle = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2
  L2_2 = A0_2
  L1_2 = A0_2.FindIntersection
  L3_2 = Player
  L3_2 = L3_2.GetPrimaryCharacter
  L3_2 = L3_2()
  L4_2 = 135
  L5_2 = true
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = L1_2
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2 = L3_2(L4_2)
  L2_2, L3_2, L4_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2)
  L5_2 = math
  L5_2 = L5_2.randi
  L6_2 = 10
  L5_2 = L5_2(L6_2)
  L5_2 = L5_2 - 5
  L6_2 = math
  L6_2 = L6_2.randi
  L7_2 = 10
  L6_2 = L6_2(L7_2)
  L6_2 = L6_2 - 5
  L7_2 = Pg
  L7_2 = L7_2.Spawn
  L8_2 = "TankBuster_Instant"
  L9_2 = L2_2 + L5_2
  L10_2 = L3_2
  L11_2 = L4_2 + L6_2
  L12_2 = 0
  L13_2 = false
  L14_2 = true
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L8_2 = {}
  L9_2 = "Fiona-In-Mission-Contract-Dlc03-04"
  L10_2 = "Fiona-In-Mission-Contract-Dlc03-05"
  L11_2 = "Fiona-In-Mission-Contract-Dlc03-06"
  L12_2 = "Fiona-In-Mission-Contract-Dlc03-07"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  L9_2 = {}
  L10_2 = "Fiona-In-Mission-Contract-Dlc03-13"
  L11_2 = "Fiona-In-Mission-Contract-Dlc03-14"
  L12_2 = "Fiona-In-Mission-Contract-Dlc03-15"
  L13_2 = "Fiona-In-Mission-Contract-Dlc03-16"
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L9_2[3] = L12_2
  L9_2[4] = L13_2
  tTBPickupVO = L9_2
  L9_2 = table
  L9_2 = L9_2.insert
  L10_2 = tSpawned
  L11_2 = L7_2
  L9_2(L10_2, L11_2)
  L9_2 = Minimap
  L10_2 = L9_2
  L9_2 = L9_2.AddObjectiveWithGuid
  L11_2 = "TankBuster_"
  L12_2 = tostring
  L13_2 = L7_2
  L12_2 = L12_2(L13_2)
  L11_2 = L11_2 .. L12_2
  L12_2 = L7_2
  L13_2 = 0
  L14_2 = 0
  L15_2 = 0
  L16_2 = 51
  L17_2 = 204
  L18_2 = 153
  L19_2 = 8
  L20_2 = 8
  L21_2 = "radar_Munition"
  L22_2 = true
  L23_2 = false
  L24_2 = false
  L25_2 = 2
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2)
  L9_2 = Hud
  L9_2 = L9_2.Radar
  L10_2 = L9_2
  L9_2 = L9_2.AnimateObjectiveSize
  L11_2 = {}
  L12_2 = "TankBuster_"
  L13_2 = tostring
  L14_2 = L7_2
  L13_2 = L13_2(L14_2)
  L12_2 = L12_2 .. L13_2
  L11_2.sName = L12_2
  L11_2.nDuration = 5
  L11_2.nMaxWidth = 12
  L11_2.nMaxHeight = 12
  L11_2.nSpeedWidth = 45
  L11_2.nSpeedHeight = 45
  L9_2(L10_2, L11_2)
  L9_2 = Hud
  L9_2 = L9_2.MessageBox
  L10_2 = L9_2
  L9_2 = L9_2.AddMessage
  L11_2 = {}
  L11_2.sMessage = "[DLCCon003.Terms.tankBuster]"
  L9_2(L10_2, L11_2)
  L10_2 = A0_2
  L9_2 = A0_2._CreateEvent
  L11_2 = Event
  L11_2 = L11_2.ObjectDelete
  L12_2 = {}
  L13_2 = L7_2
  L12_2[1] = L13_2
  
  function L13_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3
    L1_3 = Minimap
    L2_3 = L1_3
    L1_3 = L1_3.DeleteObjective
    L3_3 = "TankBuster_"
    L4_3 = tostring
    L5_3 = L7_2
    L4_3 = L4_3(L5_3)
    L3_3 = L3_3 .. L4_3
    L1_3(L2_3, L3_3)
  end
  
  L14_2 = {}
  L15_2 = A0_2
  L14_2[1] = L15_2
  L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
  eRemoveTBBlinky = L9_2
  L9_2 = nGiveTB
  L9_2 = L9_2 + 1
  nGiveTB = L9_2
  L10_2 = A0_2
  L9_2 = A0_2.NotifyPlayerVO
  L11_2 = L8_2
  L12_2 = 1
  L9_2(L10_2, L11_2, L12_2)
  L10_2 = A0_2
  L9_2 = A0_2._CreateEvent
  L11_2 = Event
  L11_2 = L11_2.ObjectProximity
  L12_2 = {}
  L13_2 = Player
  L13_2 = L13_2.GetAnyCharacter
  L13_2 = L13_2()
  L14_2 = L7_2
  L15_2 = "<"
  L16_2 = 8
  L17_2 = false
  L18_2 = false
  L12_2[1] = L13_2
  L12_2[2] = L14_2
  L12_2[3] = L15_2
  L12_2[4] = L16_2
  L12_2[5] = L17_2
  L12_2[6] = L18_2
  L13_2 = NotifyPlayerVO
  L14_2 = {}
  L15_2 = A0_2
  L16_2 = tTBPickupVO
  L17_2 = 1
  L14_2[1] = L15_2
  L14_2[2] = L16_2
  L14_2[3] = L17_2
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
end

TankBusterSpawn = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = MrxUtil
  L3_2 = L3_2.GetRandomTableElement
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = bFirstPickup
  if L4_2 then
    L4_2 = tTBPickupVO
    if A1_2 == L4_2 then
      L4_2 = false
      bFirstPickup = L4_2
      L5_2 = A0_2
      L4_2 = A0_2._CreateEvent
      L6_2 = Event
      L6_2 = L6_2.TimerRelative
      L7_2 = {}
      L8_2 = A2_2
      L7_2[1] = L8_2
      
      function L8_2()
        local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
        L0_3 = MrxVoSequence
        L0_3 = L0_3.Start
        L1_3 = {}
        L2_3 = L3_2
        L3_3 = {}
        L4_3 = A0_2
        L4_3 = L4_3.ShowAirstrikeTutorial
        L5_3 = {}
        L6_3 = A0_2
        L5_3[1] = L6_3
        L3_3[1] = L4_3
        L3_3[2] = L5_3
        L1_3[1] = L2_3
        L1_3[2] = L3_3
        L0_3(L1_3)
      end
      
      L4_2(L5_2, L6_2, L7_2, L8_2)
      return
    end
  end
  L5_2 = A0_2
  L4_2 = A0_2._CreateEvent
  L6_2 = Event
  L6_2 = L6_2.TimerRelative
  L7_2 = {}
  L8_2 = A2_2
  L7_2[1] = L8_2
  
  function L8_2()
    local L0_3, L1_3, L2_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = L3_2
    L1_3[1] = L2_3
    L0_3(L1_3)
  end
  
  L4_2(L5_2, L6_2, L7_2, L8_2)
end

NotifyPlayerVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.ShowMessage
  L2_2 = "[Tutorial.DlcCon003_Airstrike]"
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 10
  L4_2[1] = L5_2
  L5_2 = MrxTutorialManager
  L5_2 = L5_2.HideMessage
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

ShowAirstrikeTutorial = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = {}
  L2_2 = "Fiona-In-Mission-Contract-Dlc03-32"
  L3_2 = "Fiona-In-Mission-Contract-Dlc03-33"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L2_2 = ObjectFilter
  L2_2 = L2_2.Create
  L2_2 = L2_2()
  L3_2 = ObjectFilter
  L3_2 = L3_2.SetFilter
  L4_2 = L2_2
  L5_2 = "China && FlyingVehicle"
  L3_2(L4_2, L5_2)
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.ObjectDeath
  L6_2 = {}
  L7_2 = L2_2
  L6_2[1] = L7_2
  
  function L7_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3
    L1_3 = nBonusKills
    L1_3 = L1_3 + 1
    nBonusKills = L1_3
    L1_3 = A0_3.nHeliBonusMoney
    L2_3 = knHeliBonus
    L1_3 = L1_3 + L2_3
    A0_3.nHeliBonusMoney = L1_3
    L1_3 = MrxPmc
    L1_3 = L1_3.AddCashQty
    L2_3 = knHeliBonus
    L3_3 = nil
    L4_3 = "[DLCCon003.Display.scoreBonus]"
    L1_3(L2_3, L3_3, L4_3)
    L2_3 = A0_3
    L1_3 = A0_3.NotifyPlayerVO
    L3_3 = L1_2
    L4_3 = 0.5
    L1_3(L2_3, L3_3, L4_3)
    L2_3 = A0_3
    L1_3 = A0_3.BonusTarget
    L1_3(L2_3)
  end
  
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  uBonusEvent = L3_2
end

BonusTarget = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  if A1_2 == false then
    L2_2 = Player
    L2_2 = L2_2.GetSecondaryPlayer
    L2_2 = L2_2()
    L4_2 = A0_2
    L3_2 = A0_2.FindIntersection
    L5_2 = uSpwnTnk
    L6_2 = 80
    L7_2 = true
    L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
    L4_2 = Object
    L4_2 = L4_2.GetPosition
    L5_2 = Pg
    L5_2 = L5_2.GetGuidByName
    L6_2 = L3_2
    L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2 = L5_2(L6_2)
    L4_2, L5_2, L6_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
    L7_2 = Pg
    L7_2 = L7_2.Spawn
    L8_2 = "DLC_M1A3"
    L9_2 = L4_2
    L10_2 = L5_2
    L11_2 = L6_2
    L12_2 = nTankFace02
    L13_2 = false
    L14_2 = true
    L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
    L9_2 = A0_2
    L8_2 = A0_2.TankRespawn
    L10_2 = L7_2
    L8_2(L9_2, L10_2)
    L9_2 = A0_2
    L8_2 = A0_2.TankLife
    L10_2 = L2_2
    L8_2(L9_2, L10_2)
  end
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ScriptEvent
  L5_2 = {}
  L6_2 = "mpPlayerLeft"
  
  function L7_2(A0_3)
    local L1_3, L2_3
    L1_3 = Net
    L1_3 = L1_3.IsServer
    L1_3 = L1_3()
    if L1_3 then
      L1_3 = Player
      L1_3 = L1_3.IsLocal
      L2_3 = A0_3[1]
      L1_3 = L1_3(L2_3)
      L1_3 = not L1_3
    end
    return L1_3
  end
  
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = MultiplayerOff
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  eClientLeft = L2_2
end

MultiplayerOn = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "mpPlayerJoin"
  
  function L6_2(A0_3)
    local L1_3, L2_3
    L1_3 = Net
    L1_3 = L1_3.IsServer
    L1_3 = L1_3()
    if L1_3 then
      L1_3 = Player
      L1_3 = L1_3.IsLocal
      L2_3 = A0_3[1]
      L1_3 = L1_3(L2_3)
      L1_3 = not L1_3
    end
    return L1_3
  end
  
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = MultiplayerOn
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = false
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  eClientJoined = L1_2
end

MultiplayerOff = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "DLCCon003_InitialObj"
  L3_2.sModuleName = "MrxTaskObjective"
  L3_2.sDspShortDesc = "[DLCCon003.Objectives.003]"
  L3_2.bDsp = true
  L4_2 = {}
  L5_2 = {}
  L6_2 = GlitteringPrizes
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.Cancel
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnCancel = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  oInitialObj = L1_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Dlc03-01"
  L4_2 = 1
  L5_2 = "Fiona-In-Mission-Contract-Dlc03-02"
  L6_2 = {}
  L7_2 = A0_2.ShowAirstrikeTutorial
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = 5
  L8_2 = "Fiona-In-Mission-Contract-Dlc03-03"
  L9_2 = {}
  L10_2 = A0_2.ShowAmmoRepairTutorial
  L11_2 = {}
  L12_2 = A0_2
  L11_2[1] = L12_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L2_2[6] = L8_2
  L2_2[7] = L9_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.StartTimer
  L3_2 = nTime
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.BonusTarget
  L1_2(L2_2)
end

InitalizeObj = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.ShowMessage
  L2_2 = "[buildings.ammoBay.tutorial]"
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 10
  L4_2[1] = L5_2
  L5_2 = MrxTutorialManager
  L5_2 = L5_2.ShowMessage
  L6_2 = {}
  L7_2 = "[DLCCon003.UI.TLowHealth]"
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 20
  L4_2[1] = L5_2
  L5_2 = MrxTutorialManager
  L5_2 = L5_2.HideMessage
  L6_2 = {}
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

ShowAmmoRepairTutorial = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = oMissionTimer
  if L2_2 then
  else
    L2_2 = MrxTimer
    L3_2 = L2_2
    L2_2 = L2_2.Create
    L4_2 = {}
    L5_2 = A1_2 * 60
    L4_2.nStartTime = L5_2
    L4_2.iTray = 3
    L5_2 = {}
    L6_2 = {}
    L7_2 = oInitialObj
    L7_2 = L7_2.Complete
    L8_2 = {}
    L9_2 = oInitialObj
    L8_2[1] = L9_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L5_2[1] = L6_2
    L4_2.tDoneCallbacks = L5_2
    L2_2 = L2_2(L3_2, L4_2)
    oMissionTimer = L2_2
    L2_2 = oMissionTimer
    L3_2 = L2_2
    L2_2 = L2_2.Start
    L2_2(L3_2)
  end
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = A1_2 * 60
  L6_2 = L6_2 - 120
  L5_2[1] = L6_2
  
  function L6_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = MrxVoSequence
    L1_3 = L1_3.Start
    L2_3 = {}
    L3_3 = "Fiona-In-Mission-Contract-Dlc03-40"
    L2_3[1] = L3_3
    L1_3(L2_3)
  end
  
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  eTwoMinuteWarning = L2_2
end

StartTimer = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = oMissionTimer
  if L1_2 then
    L1_2 = oMissionTimer
    L2_2 = L1_2
    L1_2 = L1_2.Stop
    L1_2(L2_2)
    L1_2 = nil
    oMissionTimer = L1_2
  end
end

ClearTimer = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2.EarlyCleanup
  L1_2(L2_2)
  L1_2 = nGoal
  if 7 < L1_2 then
    L1_2 = "Fiona-In-Mission-Contract-Dlc03-44"
    sFinalVO = L1_2
  else
    L1_2 = "Fiona-In-Mission-Contract-Dlc03-43"
    sFinalVO = L1_2
  end
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = sFinalVO
  L4_2 = {}
  L5_2 = A0_2.DisplayResults
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
end

GlitteringPrizes = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L1_2 = A0_2.nTankMoney
  L2_2 = A0_2.nEscapeMoney
  L1_2 = L1_2 - L2_2
  L2_2 = nRepairMoney
  L1_2 = L1_2 - L2_2
  L2_2 = A0_2.nHeliBonusMoney
  L1_2 = L1_2 + L2_2
  L2_2 = MrxPmc
  L2_2 = L2_2.GetCashQty
  L2_2 = L2_2()
  L2_2 = L2_2 - L1_2
  L3_2 = ""
  if L2_2 < 0 then
    L3_2 = "-"
  end
  L4_2 = ""
  L5_2 = A0_2.nEscapeMoney
  if 0 < L5_2 then
    L4_2 = "-"
  end
  L5_2 = ""
  L6_2 = nRepairMoney
  if 0 < L6_2 then
    L5_2 = "-"
  end
  L6_2 = "[Scoring.DestroyedTanks] "
  L7_2 = MrxUtil
  L7_2 = L7_2.FormatMoney
  L8_2 = A0_2.nTankMoney
  L7_2 = L7_2(L8_2)
  L8_2 = "[n][Scoring.EscapedTanks] "
  L9_2 = L4_2
  L10_2 = MrxUtil
  L10_2 = L10_2.FormatMoney
  L11_2 = A0_2.nEscapeMoney
  L10_2 = L10_2(L11_2)
  L11_2 = "[n][Scoring.RepairCosts] "
  L12_2 = L5_2
  L13_2 = MrxUtil
  L13_2 = L13_2.FormatMoney
  L14_2 = nRepairMoney
  L13_2 = L13_2(L14_2)
  L14_2 = "[n][Scoring.Bonus] "
  L15_2 = MrxUtil
  L15_2 = L15_2.FormatMoney
  L16_2 = A0_2.nHeliBonusMoney
  L15_2 = L15_2(L16_2)
  L16_2 = "[n][Scoring.Misc]: "
  L17_2 = L3_2
  L18_2 = MrxUtil
  L18_2 = L18_2.FormatMoney
  L19_2 = math
  L19_2 = L19_2.abs
  L20_2 = L2_2
  L19_2, L20_2, L21_2 = L19_2(L20_2)
  L18_2 = L18_2(L19_2, L20_2, L21_2)
  L19_2 = "[n][green][Scoring.Total]: "
  L20_2 = MrxUtil
  L20_2 = L20_2.FormatMoney
  L21_2 = MrxPmc
  L21_2 = L21_2.GetCashQty
  L21_2 = L21_2()
  L20_2 = L20_2(L21_2)
  L21_2 = "[n]"
  L6_2 = L6_2 .. L7_2 .. L8_2 .. L9_2 .. L10_2 .. L11_2 .. L12_2 .. L13_2 .. L14_2 .. L15_2 .. L16_2 .. L17_2 .. L18_2 .. L19_2 .. L20_2 .. L21_2
  L7_2 = MrxGui
  L7_2 = L7_2.DisplayDialogBox
  L8_2 = Player
  L8_2 = L8_2.GetPrimaryPlayer
  L8_2 = L8_2()
  L9_2 = L6_2
  L10_2 = {}
  L11_2 = nil
  L12_2 = A0_2.Complete
  L13_2 = {}
  L14_2 = A0_2
  L13_2[1] = L14_2
  L14_2 = nil
  L15_2 = nil
  L16_2 = "center"
  L17_2 = "center"
  L18_2 = true
  L19_2 = nil
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
  A0_2.oScoreBoard = L7_2
  L7_2 = Net
  L7_2 = L7_2.LeaderboardPushScore
  L8_2 = "DlcCon003"
  L9_2 = MrxPmc
  L9_2 = L9_2.GetCashQty
  L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L9_2()
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
  L7_2 = DLC01_MissionHub
  L7_2 = L7_2.SetPrevBest
  L8_2 = "DlcCon003"
  L9_2 = MrxPmc
  L9_2 = L9_2.GetCashQty
  L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L9_2()
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
end

DisplayResults = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2.EarlyCleanup
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[DLCCon003.Cancel.tooMany]"
  L1_2(L2_2, L3_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Dlc03-41"
  L4_2 = {}
  L5_2 = A0_2.Cancel
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
end

TanksEscaped = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2.EarlyCleanup
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[DLCCon003.Cancel.noReplacements]"
  L1_2(L2_2, L3_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Dlc03-42"
  L4_2 = {}
  L5_2 = A0_2.Cancel
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
end

NoReplacement = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[DLCCon003.Cancel.bridgeDestroyed]"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.Cancel
  L1_2(L2_2)
end

BridgeDeath = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = 0
  nTracerCountA = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = MrxUtil
  L5_2 = L5_2.GetRandomTableElement
  L6_2 = tTracerTime
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = TracerFireOnA
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = MrxUtil
  L5_2 = L5_2.GetRandomTableElement
  L6_2 = tTracerTime
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = TracerFireOnA
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = MrxUtil
  L5_2 = L5_2.GetRandomTableElement
  L6_2 = tTracerTime
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = TracerFireOnA
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = MrxUtil
  L5_2 = L5_2.GetRandomTableElement
  L6_2 = tTracerTime
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = TracerFireOnA
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = MrxUtil
  L5_2 = L5_2.GetRandomTableElement
  L6_2 = tTracerTime
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = TracerFireOnA
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

TracerFireWakeUpA = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = 0
  nTracerCountB = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = MrxUtil
  L5_2 = L5_2.GetRandomTableElement
  L6_2 = tTracerTime
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = TracerFireOnB
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = MrxUtil
  L5_2 = L5_2.GetRandomTableElement
  L6_2 = tTracerTime
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = TracerFireOnB
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = MrxUtil
  L5_2 = L5_2.GetRandomTableElement
  L6_2 = tTracerTime
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = TracerFireOnB
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = MrxUtil
  L5_2 = L5_2.GetRandomTableElement
  L6_2 = tTracerTime
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = TracerFireOnB
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

TracerFireWakeUpB = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = 0
  nExpCountA = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = MrxUtil
  L5_2 = L5_2.GetRandomTableElement
  L6_2 = tTracerTime
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = TracerExplosionOnA
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = MrxUtil
  L5_2 = L5_2.GetRandomTableElement
  L6_2 = tTracerTime
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = TracerExplosionOnA
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = MrxUtil
  L5_2 = L5_2.GetRandomTableElement
  L6_2 = tTracerTime
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = TracerExplosionOnA
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = MrxUtil
  L5_2 = L5_2.GetRandomTableElement
  L6_2 = tTracerTime
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = TracerExplosionOnA
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

TracerFireExpA = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = 0
  nExpCountB = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = MrxUtil
  L5_2 = L5_2.GetRandomTableElement
  L6_2 = tTracerTime
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = TracerExplosionOnB
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = MrxUtil
  L5_2 = L5_2.GetRandomTableElement
  L6_2 = tTracerTime
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = TracerExplosionOnB
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = MrxUtil
  L5_2 = L5_2.GetRandomTableElement
  L6_2 = tTracerTime
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = TracerExplosionOnB
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = MrxUtil
  L5_2 = L5_2.GetRandomTableElement
  L6_2 = tTracerTime
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = TracerExplosionOnB
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

TracerFireExpB = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = 0
  nDExpCount = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = MrxUtil
  L5_2 = L5_2.GetRandomTableElement
  L6_2 = tTracerTime
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = DistExplosionOn
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = MrxUtil
  L5_2 = L5_2.GetRandomTableElement
  L6_2 = tTracerTime
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = DistExplosionOn
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

DistExplosion = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = nTracerCountA
  L1_2 = L1_2 + 1
  nTracerCountA = L1_2
  L1_2 = {}
  L2_2 = "loc_tracerfire_a"
  L3_2 = "loc_tracerfire_b"
  L4_2 = "loc_tracerfire_c"
  L5_2 = "loc_tracerfire_d"
  L6_2 = "loc_tracerfire_e"
  L7_2 = "loc_tracerfire_f"
  L8_2 = "loc_tracerfire_g"
  L9_2 = "loc_tracerfire_h"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L1_2[7] = L8_2
  L1_2[8] = L9_2
  L2_2 = MrxUtil
  L2_2 = L2_2.GetRandomTableElement
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  sRandomTracerA = L2_2
  L2_2 = TracerFireCommit
  L3_2 = A0_2
  L4_2 = sRandomTracerA
  L2_2(L3_2, L4_2)
end

TracerFireOnA = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = nTracerCountB
  L1_2 = L1_2 + 1
  nTracerCountB = L1_2
  L1_2 = {}
  L2_2 = "loc_tracerfire_j"
  L3_2 = "loc_tracerfire_k"
  L4_2 = "loc_tracerfire_l"
  L5_2 = "loc_tracerfire_m"
  L6_2 = "loc_tracerfire_n"
  L7_2 = "loc_tracerfire_o"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L2_2 = MrxUtil
  L2_2 = L2_2.GetRandomTableElement
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  sRandomTracerB = L2_2
  L2_2 = TracerFireCommit
  L3_2 = A0_2
  L4_2 = sRandomTracerB
  L2_2(L3_2, L4_2)
end

TracerFireOnB = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = nExpCountA
  L1_2 = L1_2 + 1
  nExpCountA = L1_2
  L1_2 = {}
  L2_2 = "loc_tracerexplosions_a"
  L3_2 = "loc_tracerexplosions_b"
  L4_2 = "loc_tracerexplosions_c"
  L5_2 = "loc_tracerexplosions_d"
  L6_2 = "loc_tracerexplosions_e"
  L7_2 = "loc_tracerexplosions_f"
  L8_2 = "loc_tracerexplosions_g"
  L9_2 = "loc_tracerexplosions_h"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L1_2[7] = L8_2
  L1_2[8] = L9_2
  L2_2 = MrxUtil
  L2_2 = L2_2.GetRandomTableElement
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  sRandomExplosionA = L2_2
  L3_2 = A0_2
  L2_2 = A0_2.TracerExplosionExec
  L4_2 = sRandomExplosionA
  L2_2(L3_2, L4_2)
end

TracerExplosionOnA = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = nExpCountB
  L1_2 = L1_2 + 1
  nExpCountB = L1_2
  L1_2 = {}
  L2_2 = "loc_tracerexplosions_i"
  L3_2 = "loc_tracerexplosions_j"
  L4_2 = "loc_tracerexplosions_k"
  L5_2 = "loc_tracerexplosions_l"
  L6_2 = "loc_tracerexplosions_m"
  L7_2 = "loc_tracerexplosions_n"
  L8_2 = "loc_tracerexplosions_o"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L1_2[7] = L8_2
  L2_2 = MrxUtil
  L2_2 = L2_2.GetRandomTableElement
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  sRandomExplosionB = L2_2
  L3_2 = A0_2
  L2_2 = A0_2.TracerExplosionExec
  L4_2 = sRandomExplosionB
  L2_2(L3_2, L4_2)
end

TracerExplosionOnB = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = nDExpCount
  L1_2 = L1_2 + 1
  nDExpCount = L1_2
  L1_2 = {}
  L2_2 = "loc_distexplosion_a"
  L3_2 = "loc_distexplosion_b"
  L4_2 = "loc_distexplosion_c"
  L5_2 = "loc_distexplosion_d"
  L6_2 = "loc_distexplosion_e"
  L7_2 = "loc_distexplosion_f"
  L8_2 = "loc_distexplosion_g"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L1_2[7] = L8_2
  L2_2 = MrxUtil
  L2_2 = L2_2.GetRandomTableElement
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  sRandomExp = L2_2
  L3_2 = A0_2
  L2_2 = A0_2.DistExplosionExec
  L4_2 = sRandomExp
  L2_2(L3_2, L4_2)
end

DistExplosionOn = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "dlc_global_particle_tracer_AA"
  L2_2 = L2_2(L3_2)
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = Object
  L4_2 = L4_2.GetPosition
  L5_2 = L3_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  L7_2 = Object
  L7_2 = L7_2.GetYaw
  L8_2 = L3_2
  L7_2 = L7_2(L8_2)
  L9_2 = A0_2
  L8_2 = A0_2._CreateEvent
  L10_2 = Event
  L10_2 = L10_2.TimerRelative
  L11_2 = {}
  L12_2 = 1
  L11_2[1] = L12_2
  
  function L12_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
    L1_3 = Pg
    L1_3 = L1_3.Spawn
    L2_3 = L2_2
    L3_3 = L4_2
    L4_3 = L5_2
    L5_3 = L6_2
    L6_3 = L7_2
    L7_3 = false
    L8_3 = true
    L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3)
  end
  
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
  eTracerFire = L8_2
  L8_2 = nTracerCountA
  if L8_2 == 5 then
    L9_2 = A0_2
    L8_2 = A0_2._CreateEvent
    L10_2 = Event
    L10_2 = L10_2.TimerRelative
    L11_2 = {}
    L12_2 = 4
    L11_2[1] = L12_2
    
    function L12_2(A0_3)
      local L1_3, L2_3, L3_3
      L1_3 = Sound
      L1_3 = L1_3.CueSound
      L2_3 = 0
      L3_3 = "Dlc_distCannons"
      L1_3(L2_3, L3_3)
    end
    
    L8_2(L9_2, L10_2, L11_2, L12_2)
    L9_2 = A0_2
    L8_2 = A0_2._CreateEvent
    L10_2 = Event
    L10_2 = L10_2.TimerRelative
    L11_2 = {}
    L12_2 = 4
    L11_2[1] = L12_2
    L12_2 = TracerFireWakeUpA
    L13_2 = {}
    L14_2 = A0_2
    L13_2[1] = L14_2
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  end
  L8_2 = nTracerCountB
  if L8_2 == 4 then
    L9_2 = A0_2
    L8_2 = A0_2._CreateEvent
    L10_2 = Event
    L10_2 = L10_2.TimerRelative
    L11_2 = {}
    L12_2 = 4
    L11_2[1] = L12_2
    L12_2 = TracerFireWakeUpB
    L13_2 = {}
    L14_2 = A0_2
    L13_2[1] = L14_2
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  end
end

TracerFireCommit = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "dlc_global_particle_airstrike_distance"
  L2_2 = L2_2(L3_2)
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = Object
  L4_2 = L4_2.GetPosition
  L5_2 = L3_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  L7_2 = Object
  L7_2 = L7_2.GetYaw
  L8_2 = L3_2
  L7_2 = L7_2(L8_2)
  L9_2 = A0_2
  L8_2 = A0_2._CreateEvent
  L10_2 = Event
  L10_2 = L10_2.TimerRelative
  L11_2 = {}
  L12_2 = 1
  L11_2[1] = L12_2
  
  function L12_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
    L1_3 = Pg
    L1_3 = L1_3.Spawn
    L2_3 = L2_2
    L3_3 = L4_2
    L4_3 = L5_2
    L5_3 = L6_2
    L6_3 = L7_2
    L7_3 = false
    L8_3 = true
    L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3)
  end
  
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
  eTracerExp = L8_2
  L8_2 = nExpCountA
  if L8_2 == 4 then
    L9_2 = A0_2
    L8_2 = A0_2._CreateEvent
    L10_2 = Event
    L10_2 = L10_2.TimerRelative
    L11_2 = {}
    L12_2 = 6
    L11_2[1] = L12_2
    L12_2 = TracerFireExpA
    L13_2 = {}
    L14_2 = A0_2
    L13_2[1] = L14_2
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  end
  L8_2 = nExpCountB
  if L8_2 == 4 then
    L9_2 = A0_2
    L8_2 = A0_2._CreateEvent
    L10_2 = Event
    L10_2 = L10_2.TimerRelative
    L11_2 = {}
    L12_2 = 6
    L11_2[1] = L12_2
    L12_2 = TracerFireExpB
    L13_2 = {}
    L14_2 = A0_2
    L13_2[1] = L14_2
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  end
end

TracerExplosionExec = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "DLC_Explosion (Daisy Cutter)"
  L2_2 = L2_2(L3_2)
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = Object
  L4_2 = L4_2.GetPosition
  L5_2 = L3_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  L7_2 = Object
  L7_2 = L7_2.GetYaw
  L8_2 = L3_2
  L7_2 = L7_2(L8_2)
  L9_2 = A0_2
  L8_2 = A0_2._CreateEvent
  L10_2 = Event
  L10_2 = L10_2.TimerRelative
  L11_2 = {}
  L12_2 = 1
  L11_2[1] = L12_2
  
  function L12_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
    L1_3 = Pg
    L1_3 = L1_3.Spawn
    L2_3 = L2_2
    L3_3 = L4_2
    L4_3 = L5_2
    L5_3 = L6_2
    L6_3 = L7_2
    L7_3 = false
    L8_3 = true
    L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3)
    L2_3 = nDExpCount
    if L2_3 == 2 then
      L3_3 = A0_3
      L2_3 = A0_3._CreateEvent
      L4_3 = Event
      L4_3 = L4_3.TimerRelative
      L5_3 = {}
      L6_3 = 30
      L5_3[1] = L6_3
      L6_3 = DistExplosion
      L7_3 = {}
      L8_3 = A0_3
      L7_3[1] = L8_3
      L2_3(L3_3, L4_3, L5_3, L6_3, L7_3)
    end
  end
  
  L13_2 = {}
  L14_2 = A0_2
  L13_2[1] = L14_2
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  eTracerExp = L8_2
end

DistExplosionExec = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  A0_2.oScoreBoard = nil
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Complete
  L2_2 = A0_2
  L1_2(L2_2)
end

Complete = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.EarlyCleanup
  L1_2(L2_2)
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cancel
  L2_2 = A0_2
  L1_2(L2_2)
end

Cancel = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = oMissionTimer
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.ClearTimer
    L1_2(L2_2)
    L1_2 = nil
    oMissionTimer = L1_2
  end
  L1_2 = eTwoMinuteWarning
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eTwoMinuteWarning
    L1_2(L2_2)
    L1_2 = nil
    eTwoMinuteWarning = L1_2
  end
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 1
  L1_2(L2_2, L3_2)
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 2
  L1_2(L2_2, L3_2)
  L1_2 = ipairs
  L2_2 = tExitLocs
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = "Blip_"
    L7_2 = L5_2
    L6_2 = L6_2 .. L7_2
    L7_2 = Hud
    L7_2 = L7_2.Radar
    L8_2 = L7_2
    L7_2 = L7_2.UnanimateObjective
    L9_2 = {}
    L9_2.sName = L6_2
    L7_2(L8_2, L9_2)
    L7_2 = Marker
    L7_2 = L7_2.HaltPulse
    L8_2 = Pg
    L8_2 = L8_2.GetGuidByName
    L9_2 = L5_2
    L8_2, L9_2, L10_2, L11_2, L12_2 = L8_2(L9_2)
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
    L7_2 = Minimap
    L8_2 = L7_2
    L7_2 = L7_2.DeleteObjective
    L9_2 = L6_2
    L7_2(L8_2, L9_2)
    L7_2 = Pda
    L7_2 = L7_2.Map
    L8_2 = L7_2
    L7_2 = L7_2.RemoveBlip
    L9_2 = {}
    L10_2 = "PDA_Blip_"
    L11_2 = tostring
    L12_2 = L5_2
    L11_2 = L11_2(L12_2)
    L10_2 = L10_2 .. L11_2
    L9_2.sName = L10_2
    L7_2(L8_2, L9_2)
  end
  L1_2 = tExitLocMarkers
  if L1_2 then
    L1_2 = ipairs
    L2_2 = tExitLocMarkers
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    for L4_2, L5_2 in L1_2, L2_2, L3_2 do
      L6_2 = Marker
      L6_2 = L6_2.Remove
      L7_2 = L5_2
      L6_2(L7_2)
    end
    L1_2 = nil
    tExitLocMarkers = L1_2
  end
  L1_2 = a
  if L1_2 then
    L1_2 = a
    L2_2 = L1_2
    L1_2 = L1_2.Cleanup
    L1_2(L2_2)
    L1_2 = nil
    a = L1_2
  end
  L1_2 = pairs
  L2_2 = A0_2.tVehicleEvents
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L7_2 = A0_2
    L6_2 = A0_2.CleanupEnemyTank
    L8_2 = L4_2
    L6_2(L7_2, L8_2)
  end
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.HideMessage
  L1_2()
  L1_2 = A0_2._tEvents
  if L1_2 then
    L1_2 = pairs
    L2_2 = A0_2._tEvents
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    for L4_2, L5_2 in L1_2, L2_2, L3_2 do
      L6_2 = Event
      L6_2 = L6_2.Delete
      L7_2 = L5_2
      L6_2(L7_2)
    end
  end
end

EarlyCleanup = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = WifVzBoundary
  L1_2 = L1_2.RemoveWorldBoundary
  L1_2()
  L1_2 = Player
  L1_2 = L1_2.SetVehicleDisguise
  L2_2 = true
  L1_2(L2_2)
  L1_2 = ipairs
  L2_2 = tSpawned
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Object
    L6_2 = L6_2.HasLabel
    L7_2 = L5_2
    L8_2 = "Vehicle"
    L6_2 = L6_2(L7_2, L8_2)
    if not L6_2 then
      L7_2 = Minimap
      L8_2 = L7_2
      L7_2 = L7_2.DeleteObjective
      L9_2 = "New Tank"
      L10_2 = tostring
      L11_2 = L5_2
      L10_2 = L10_2(L11_2)
      L9_2 = L9_2 .. L10_2
      L7_2(L8_2, L9_2)
      L7_2 = Minimap
      L8_2 = L7_2
      L7_2 = L7_2.DeleteObjective
      L9_2 = "Alert_"
      L10_2 = tostring
      L11_2 = L5_2
      L10_2 = L10_2(L11_2)
      L9_2 = L9_2 .. L10_2
      L7_2(L8_2, L9_2)
      L7_2 = Minimap
      L8_2 = L7_2
      L7_2 = L7_2.DeleteObjective
      L9_2 = "TankBuster_"
      L10_2 = tostring
      L11_2 = L5_2
      L10_2 = L10_2(L11_2)
      L9_2 = L9_2 .. L10_2
      L7_2(L8_2, L9_2)
    else
      L7_2 = Vehicle
      L7_2 = L7_2.GetDriver
      L8_2 = L5_2
      L7_2 = L7_2(L8_2)
      L8_2 = Object
      L8_2 = L8_2.IsPlayerControlled
      L9_2 = L5_2
      L8_2 = L8_2(L9_2)
      if not L8_2 then
        L9_2 = Ai
        L9_2 = L9_2.RemoveGoal
        L10_2 = {}
        L10_2.AIGuid = L7_2
        L10_2.Handle = 0
        L9_2(L10_2)
        L9_2 = Minimap
        L10_2 = L9_2
        L9_2 = L9_2.DeleteObjective
        L11_2 = "New Tank"
        L12_2 = tostring
        L13_2 = L5_2
        L12_2 = L12_2(L13_2)
        L11_2 = L11_2 .. L12_2
        L9_2(L10_2, L11_2)
        L9_2 = Minimap
        L10_2 = L9_2
        L9_2 = L9_2.DeleteObjective
        L11_2 = "Alert_"
        L12_2 = tostring
        L13_2 = L5_2
        L12_2 = L12_2(L13_2)
        L11_2 = L11_2 .. L12_2
        L9_2(L10_2, L11_2)
        L9_2 = Minimap
        L10_2 = L9_2
        L9_2 = L9_2.DeleteObjective
        L11_2 = "TankBuster_"
        L12_2 = tostring
        L13_2 = L5_2
        L12_2 = L12_2(L13_2)
        L11_2 = L11_2 .. L12_2
        L9_2(L10_2, L11_2)
      else
        L9_2 = Vehicle
        L9_2 = L9_2.Exit
        L10_2 = L5_2
        L11_2 = L7_2
        L12_2 = true
        L9_2(L10_2, L11_2, L12_2)
      end
    end
    L7_2 = Object
    L7_2 = L7_2.FadeOut
    L8_2 = L5_2
    L9_2 = 3
    L10_2 = true
    L7_2(L8_2, L9_2, L10_2)
  end
  L1_2 = A0_2.oScoreBoard
  if L1_2 then
    L1_2 = A0_2.oScoreBoard
    L2_2 = L1_2
    L1_2 = L1_2.Close
    L1_2(L2_2)
    A0_2.oScoreBoard = nil
  end
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
