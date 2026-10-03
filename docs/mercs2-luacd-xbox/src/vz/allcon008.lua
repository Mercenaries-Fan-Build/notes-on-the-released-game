local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTaskRace"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTaskObjectiveDeliver"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxLayerManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxAchievements"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxAchievements"
L0_1(L1_1)

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Player
  L1_2 = L1_2.GetAnyCharacter
  L1_2 = L1_2()
  uPlayer = L1_2
  L1_2 = Player
  L1_2 = L1_2.GetAllPlayers
  L1_2 = L1_2()
  tPlayers = L1_2
  L1_2 = table
  L1_2 = L1_2.getn
  L2_2 = tPlayers
  L1_2 = L1_2(L2_2)
  nPlayers = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.GetNumCompletions
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    L1_2 = 0
  end
  nComp = L1_2
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Add
  L2_2 = vLayersStage
  L1_2(L2_2)
  L1_2 = nComp
  if 1 < L1_2 then
    L1_2 = 2
    nComp = L1_2
  end
  L1_2 = ChopperRace
  L2_2 = A0_2
  L1_2(L2_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2
  L1_2 = "AllCon008"
  L2_2 = "VZ_state_AllCon008"
  L3_2 = "VZ_state_AllCon008_staging"
  L5_2 = A0_2
  L4_2 = A0_2.CreateChild
  L6_2 = {}
  L6_2.sRaceMission = "AllCon008"
  L6_2.sName = "ChopperRace"
  L6_2.sModuleName = "MrxTaskRace"
  L7_2 = tCopters
  L6_2.vTgtInclude = L7_2
  L6_2.bUseTripWires = true
  L6_2.sGateType = "ring"
  L7_2 = {}
  L8_2 = nComp
  L8_2 = L8_2 * 4
  L8_2 = 20 - L8_2
  L7_2.nStartTime = L8_2
  L7_2.nStep = 1
  L6_2.tTimerParams = L7_2
  L7_2 = nComp
  L7_2 = 9 - L7_2
  L6_2.nAddTime = L7_2
  L7_2 = {}
  L8_2 = L1_2
  L9_2 = "_checkpoint000"
  L8_2 = L8_2 .. L9_2
  L9_2 = L1_2
  L10_2 = "_checkpoint010"
  L9_2 = L9_2 .. L10_2
  L10_2 = L1_2
  L11_2 = "_checkpoint020"
  L10_2 = L10_2 .. L11_2
  L11_2 = L1_2
  L12_2 = "_checkpoint025"
  L11_2 = L11_2 .. L12_2
  L12_2 = L1_2
  L13_2 = "_checkpoint030"
  L12_2 = L12_2 .. L13_2
  L13_2 = L1_2
  L14_2 = "_checkpoint040"
  L13_2 = L13_2 .. L14_2
  L14_2 = L1_2
  L15_2 = "_checkpoint045"
  L14_2 = L14_2 .. L15_2
  L15_2 = L1_2
  L16_2 = "_checkpoint050"
  L15_2 = L15_2 .. L16_2
  L16_2 = L1_2
  L17_2 = "_checkpoint070"
  L16_2 = L16_2 .. L17_2
  L17_2 = L1_2
  L18_2 = "_checkpoint080"
  L17_2 = L17_2 .. L18_2
  L18_2 = L1_2
  L19_2 = "_checkpoint090"
  L18_2 = L18_2 .. L19_2
  L19_2 = L1_2
  L20_2 = "_checkpoint100"
  L19_2 = L19_2 .. L20_2
  L20_2 = L1_2
  L21_2 = "_checkpoint110"
  L20_2 = L20_2 .. L21_2
  L21_2 = L1_2
  L22_2 = "_checkpoint115"
  L21_2 = L21_2 .. L22_2
  L22_2 = L1_2
  L23_2 = "_checkpoint120"
  L22_2 = L22_2 .. L23_2
  L23_2 = L1_2
  L24_2 = "_checkpoint200"
  L23_2 = L23_2 .. L24_2
  L24_2 = L1_2
  L25_2 = "_checkpoint202"
  L24_2 = L24_2 .. L25_2
  L25_2 = L1_2
  L26_2 = "_checkpoint205"
  L25_2 = L25_2 .. L26_2
  L26_2 = L1_2
  L27_2 = "_checkpoint210"
  L26_2 = L26_2 .. L27_2
  L27_2 = L1_2
  L28_2 = "_checkpoint220"
  L27_2 = L27_2 .. L28_2
  L28_2 = L1_2
  L29_2 = "_checkpoint270"
  L28_2 = L28_2 .. L29_2
  L29_2 = L1_2
  L30_2 = "_checkpoint280"
  L29_2 = L29_2 .. L30_2
  L30_2 = L1_2
  L31_2 = "_checkpoint290"
  L30_2 = L30_2 .. L31_2
  L31_2 = L1_2
  L32_2 = "_checkpoint300"
  L31_2 = L31_2 .. L32_2
  L32_2 = L1_2
  L33_2 = "_checkpoint310"
  L32_2 = L32_2 .. L33_2
  L33_2 = L1_2
  L34_2 = "_checkpoint320"
  L33_2 = L33_2 .. L34_2
  L34_2 = L1_2
  L35_2 = "_checkpoint330"
  L34_2 = L34_2 .. L35_2
  L35_2 = L1_2
  L36_2 = "_checkpoint340"
  L35_2 = L35_2 .. L36_2
  L36_2 = L1_2
  L37_2 = "_checkpoint350"
  L36_2 = L36_2 .. L37_2
  L37_2 = L1_2
  L38_2 = "_checkpoint370"
  L37_2 = L37_2 .. L38_2
  L38_2 = L1_2
  L39_2 = "_checkpoint380"
  L38_2 = L38_2 .. L39_2
  L39_2 = L1_2
  L40_2 = "_checkpoint390"
  L39_2 = L39_2 .. L40_2
  L40_2 = L1_2
  L41_2 = "_checkpoint400"
  L40_2 = L40_2 .. L41_2
  L41_2 = L1_2
  L42_2 = "_checkpoint410"
  L41_2 = L41_2 .. L42_2
  L42_2 = L1_2
  L43_2 = "_checkpoint440"
  L42_2 = L42_2 .. L43_2
  L43_2 = L1_2
  L44_2 = "_checkpoint500"
  L43_2 = L43_2 .. L44_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L7_2[5] = L12_2
  L7_2[6] = L13_2
  L7_2[7] = L14_2
  L7_2[8] = L15_2
  L7_2[9] = L16_2
  L7_2[10] = L17_2
  L7_2[11] = L18_2
  L7_2[12] = L19_2
  L7_2[13] = L20_2
  L7_2[14] = L21_2
  L7_2[15] = L22_2
  L7_2[16] = L23_2
  L7_2[17] = L24_2
  L7_2[18] = L25_2
  L7_2[19] = L26_2
  L7_2[20] = L27_2
  L7_2[21] = L28_2
  L7_2[22] = L29_2
  L7_2[23] = L30_2
  L7_2[24] = L31_2
  L7_2[25] = L32_2
  L7_2[26] = L33_2
  L7_2[27] = L34_2
  L7_2[28] = L35_2
  L7_2[29] = L36_2
  L7_2[30] = L37_2
  L7_2[31] = L38_2
  L7_2[32] = L39_2
  L7_2[33] = L40_2
  L7_2[34] = L41_2
  L7_2[35] = L42_2
  L7_2[36] = L43_2
  L6_2.tCourseLocs = L7_2
  L7_2 = {}
  L8_2 = "Fiona-In-Mission-MinorContract-All08-01"
  L7_2[1] = L8_2
  L6_2.vVoSeqOnAdd = L7_2
  
  function L7_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = A0_2
    L0_3 = L0_3.oRaceObjective
    L0_3 = L0_3._uWinner
    if L0_3 then
      L1_3 = MrxAchievements
      L1_3 = L1_3.AchievementAddCount
      L2_3 = "ACHIEVEMENT_HIGHWAY_TO_HELL"
      L3_3 = 1
      L4_3 = L0_3
      L5_3 = true
      L1_3(L2_3, L3_3, L4_3, L5_3)
    end
    L1_3 = Player
    L1_3 = L1_3.GetCurrentPlayers
    L1_3 = L1_3()
    if L1_3 == 2 then
      L2_3 = A0_2
      L2_3 = L2_3.oRaceObjective
      L2_3 = L2_3._uWinner
      L3_3 = MrxAchievements
      L3_3 = L3_3.NetGrantAchievement
      L4_3 = "ACHIEVEMENT_WHEELS_OF_STEEL"
      L5_3 = L2_3
      L3_3(L4_3, L5_3)
    end
    L2_3 = MrxLayerManager
    L2_3 = L2_3.Remove
    L3_3 = L3_2
    L2_3(L3_3)
    L2_3 = A0_2
    L3_3 = L2_3
    L2_3 = L2_3.Complete
    L2_3(L3_3)
  end
  
  L6_2.fOnComplete = L7_2
  
  function L7_2()
    local L0_3, L1_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.Cancel
    L0_3(L1_3)
  end
  
  L6_2.fOnCancel = L7_2
  L4_2 = L4_2(L5_2, L6_2)
  A0_2.oRaceObjective = L4_2
  L5_2 = A0_2
  L4_2 = A0_2._CreateEvent
  L6_2 = Event
  L6_2 = L6_2.ObjectInSeat
  L7_2 = {}
  L8_2 = uPlayer
  L9_2 = oCopter01
  L10_2 = "d"
  L11_2 = "e"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L8_2 = MrxMusic
  L8_2 = L8_2.PlaySpecialMusic
  L9_2 = {}
  L10_2 = "mu_mission_allcon008_01"
  L9_2[1] = L10_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  eCueMusic = L4_2
end

ChopperRace = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = nCopters
  L1_2 = L1_2 - 1
  nCopters = L1_2
  L1_2 = nCopters
  L2_2 = nPlayers
  if L1_2 < L2_2 then
    L1_2 = A0_2.Cancel
    L2_2 = A0_2
    L1_2(L2_2)
  end
end

VehicleCheck = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = "VZ_state_AllCon008"
  vLayersMain = L1_2
  L1_2 = "VZ_state_AllCon008_staging"
  vLayersStage = L1_2
  L1_2 = {}
  L2_2 = "VZ_state_AllCon008"
  L3_2 = "VZ_state_AllCon008_staging"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L2_2 = MrxLayerManager
  L2_2 = L2_2.Add
  L3_2 = L1_2
  L4_2 = GetCopters
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L2_2(L3_2, L4_2, L5_2)
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L1_2 = Net
  L1_2 = L1_2.DoneReloadingLayers
  if L1_2 then
    L1_2 = Net
    L1_2 = L1_2.DoneReloadingLayers
    L1_2()
  end
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "AllCon008_SpawnCopter01"
  L1_2 = L1_2(L2_2)
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "AllCon008_SpawnCopter02"
  L2_2 = L2_2(L3_2)
  L3_2 = Object
  L3_2 = L3_2.GetPosition
  L4_2 = L1_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  L6_2 = Object
  L6_2 = L6_2.GetPosition
  L7_2 = L2_2
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  L9_2 = Object
  L9_2 = L9_2.GetYaw
  L10_2 = L1_2
  L9_2 = L9_2(L10_2)
  L10_2 = Object
  L10_2 = L10_2.GetYaw
  L11_2 = L2_2
  L10_2 = L10_2(L11_2)
  L11_2 = Player
  L11_2 = L11_2.GetCurrentPlayers
  L11_2 = L11_2()
  if L11_2 == 2 then
    L12_2 = Pg
    L12_2 = L12_2.Spawn
    L13_2 = "Coanda Transport"
    L14_2 = L3_2
    L15_2 = L4_2
    L16_2 = L5_2
    L17_2 = L9_2
    L18_2 = true
    L19_2 = true
    L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
    oCopter01 = L12_2
    L12_2 = Pg
    L12_2 = L12_2.Spawn
    L13_2 = "Coanda Transport"
    L14_2 = L6_2
    L15_2 = L7_2
    L16_2 = L8_2
    L17_2 = nYaw2
    L18_2 = true
    L19_2 = true
    L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
    oCopter02 = L12_2
    L12_2 = {}
    L13_2 = oCopter01
    L14_2 = oCopter02
    L12_2[1] = L13_2
    L12_2[2] = L14_2
    tCopters = L12_2
  else
    L12_2 = Pg
    L12_2 = L12_2.Spawn
    L13_2 = "Coanda Transport"
    L14_2 = L3_2
    L15_2 = L4_2
    L16_2 = L5_2
    L17_2 = L9_2
    L18_2 = true
    L19_2 = true
    L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
    oCopter01 = L12_2
    L12_2 = {}
    L13_2 = oCopter01
    L12_2[1] = L13_2
    tCopters = L12_2
  end
  L12_2 = table
  L12_2 = L12_2.getn
  L13_2 = tCopters
  L12_2 = L12_2(L13_2)
  nCopters = L12_2
  L12_2 = Event
  L12_2 = L12_2.Create
  L13_2 = Event
  L13_2 = L13_2.ObjectHibernation
  L14_2 = {}
  L15_2 = oCopter01
  L16_2 = "awake"
  L14_2[1] = L15_2
  L14_2[2] = L16_2
  L15_2 = A0_2.AssetsLoaded
  L16_2 = {}
  L17_2 = A0_2
  L16_2[1] = L17_2
  L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2)
  eCopterReady = L12_2
end

GetCopters = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = MrxMusic
  L1_2 = L1_2.StopSpecialMusic
  L1_2()
  L1_2 = MrxLayerManager
  L1_2 = L1_2.MarkForRemoval
  L2_2 = vLayersStage
  L1_2(L2_2)
  L1_2 = ipairs
  L2_2 = tCopters
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Event
    L6_2 = L6_2.Create
    L7_2 = Event
    L7_2 = L7_2.ObjectHibernation
    L8_2 = {}
    L9_2 = L5_2
    L10_2 = "hibernated"
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L9_2 = Object
    L9_2 = L9_2.Remove
    L10_2 = {}
    L11_2 = L5_2
    L10_2[1] = L11_2
    L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
    eRemoveCopter = L6_2
  end
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
