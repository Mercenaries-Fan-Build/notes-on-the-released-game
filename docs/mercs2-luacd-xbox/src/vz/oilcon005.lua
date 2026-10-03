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

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = "VZ_state_OilCon005"
  vLayersMain = L1_2
  L1_2 = "VZ_state_OilCon005_staging"
  vLayersStage = L1_2
  L1_2 = "VZ_state_OilCon005_Bonus"
  vLayersBonus = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.GetNumCompletions
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    L1_2 = 0
  end
  nComp = L1_2
  L1_2 = nComp
  if 1 < L1_2 then
    L1_2 = 2
    nComp = L1_2
  end
  L1_2 = {}
  L2_2 = vLayersMain
  L3_2 = vLayersStage
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L2_2 = MrxLayerManager
  L2_2 = L2_2.Add
  L3_2 = L1_2
  L4_2 = GetSportsCars
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L2_2(L3_2, L4_2, L5_2)
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.CarRace
  L3_2 = tCars
  L1_2(L2_2, L3_2)
end

Activated = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2, L47_2, L48_2, L49_2
  L2_2 = "OilCon005"
  L4_2 = A0_2
  L3_2 = A0_2.CreateChild
  L5_2 = {}
  L5_2.sRaceMission = "OilCon005"
  L5_2.sName = "CarRace"
  L5_2.sModuleName = "MrxTaskRace"
  L6_2 = {}
  L7_2 = nComp
  L7_2 = L7_2 * 2
  L7_2 = 8 - L7_2
  L6_2.nStartTime = L7_2
  L5_2.tTimerParams = L6_2
  L5_2.vTgtInclude = A1_2
  L6_2 = nComp
  L6_2 = 7 - L6_2
  L5_2.nAddTime = L6_2
  L6_2 = {}
  L7_2 = L2_2
  L8_2 = "_checkpoint010"
  L7_2 = L7_2 .. L8_2
  L8_2 = L2_2
  L9_2 = "_checkpoint020"
  L8_2 = L8_2 .. L9_2
  L9_2 = L2_2
  L10_2 = "_checkpoint030"
  L9_2 = L9_2 .. L10_2
  L10_2 = L2_2
  L11_2 = "_checkpoint040"
  L10_2 = L10_2 .. L11_2
  L11_2 = L2_2
  L12_2 = "_checkpoint050"
  L11_2 = L11_2 .. L12_2
  L12_2 = L2_2
  L13_2 = "_checkpoint060"
  L12_2 = L12_2 .. L13_2
  L13_2 = L2_2
  L14_2 = "_checkpoint070"
  L13_2 = L13_2 .. L14_2
  L14_2 = L2_2
  L15_2 = "_checkpoint080"
  L14_2 = L14_2 .. L15_2
  L15_2 = L2_2
  L16_2 = "_checkpoint090"
  L15_2 = L15_2 .. L16_2
  L16_2 = L2_2
  L17_2 = "_checkpoint100"
  L16_2 = L16_2 .. L17_2
  L17_2 = L2_2
  L18_2 = "_checkpoint110"
  L17_2 = L17_2 .. L18_2
  L18_2 = L2_2
  L19_2 = "_checkpoint120"
  L18_2 = L18_2 .. L19_2
  L19_2 = L2_2
  L20_2 = "_checkpoint130"
  L19_2 = L19_2 .. L20_2
  L20_2 = L2_2
  L21_2 = "_checkpoint140"
  L20_2 = L20_2 .. L21_2
  L21_2 = L2_2
  L22_2 = "_checkpoint150"
  L21_2 = L21_2 .. L22_2
  L22_2 = L2_2
  L23_2 = "_checkpoint160"
  L22_2 = L22_2 .. L23_2
  L23_2 = L2_2
  L24_2 = "_checkpoint170"
  L23_2 = L23_2 .. L24_2
  L24_2 = L2_2
  L25_2 = "_checkpoint180"
  L24_2 = L24_2 .. L25_2
  L25_2 = L2_2
  L26_2 = "_checkpoint190"
  L25_2 = L25_2 .. L26_2
  L26_2 = L2_2
  L27_2 = "_checkpoint200"
  L26_2 = L26_2 .. L27_2
  L27_2 = L2_2
  L28_2 = "_checkpoint210"
  L27_2 = L27_2 .. L28_2
  L28_2 = L2_2
  L29_2 = "_checkpoint220"
  L28_2 = L28_2 .. L29_2
  L29_2 = L2_2
  L30_2 = "_checkpoint230"
  L29_2 = L29_2 .. L30_2
  L30_2 = L2_2
  L31_2 = "_checkpoint520"
  L30_2 = L30_2 .. L31_2
  L31_2 = L2_2
  L32_2 = "_checkpoint530"
  L31_2 = L31_2 .. L32_2
  L32_2 = L2_2
  L33_2 = "_checkpoint540"
  L32_2 = L32_2 .. L33_2
  L33_2 = L2_2
  L34_2 = "_checkpoint550"
  L33_2 = L33_2 .. L34_2
  L34_2 = L2_2
  L35_2 = "_checkpoint560"
  L34_2 = L34_2 .. L35_2
  L35_2 = L2_2
  L36_2 = "_checkpoint570"
  L35_2 = L35_2 .. L36_2
  L36_2 = L2_2
  L37_2 = "_checkpoint580"
  L36_2 = L36_2 .. L37_2
  L37_2 = L2_2
  L38_2 = "_checkpoint600"
  L37_2 = L37_2 .. L38_2
  L38_2 = L2_2
  L39_2 = "_checkpoint610"
  L38_2 = L38_2 .. L39_2
  L39_2 = L2_2
  L40_2 = "_checkpoint620"
  L39_2 = L39_2 .. L40_2
  L40_2 = L2_2
  L41_2 = "_checkpoint630"
  L40_2 = L40_2 .. L41_2
  L41_2 = L2_2
  L42_2 = "_checkpoint640"
  L41_2 = L41_2 .. L42_2
  L42_2 = L2_2
  L43_2 = "_checkpoint650"
  L42_2 = L42_2 .. L43_2
  L43_2 = L2_2
  L44_2 = "_checkpoint660"
  L43_2 = L43_2 .. L44_2
  L44_2 = L2_2
  L45_2 = "_checkpoint670"
  L44_2 = L44_2 .. L45_2
  L45_2 = L2_2
  L46_2 = "_checkpoint680"
  L45_2 = L45_2 .. L46_2
  L46_2 = L2_2
  L47_2 = "_checkpoint690"
  L46_2 = L46_2 .. L47_2
  L47_2 = L2_2
  L48_2 = "_checkpoint700"
  L47_2 = L47_2 .. L48_2
  L48_2 = L2_2
  L49_2 = "_checkpoint710"
  L48_2 = L48_2 .. L49_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L6_2[5] = L11_2
  L6_2[6] = L12_2
  L6_2[7] = L13_2
  L6_2[8] = L14_2
  L6_2[9] = L15_2
  L6_2[10] = L16_2
  L6_2[11] = L17_2
  L6_2[12] = L18_2
  L6_2[13] = L19_2
  L6_2[14] = L20_2
  L6_2[15] = L21_2
  L6_2[16] = L22_2
  L6_2[17] = L23_2
  L6_2[18] = L24_2
  L6_2[19] = L25_2
  L6_2[20] = L26_2
  L6_2[21] = L27_2
  L6_2[22] = L28_2
  L6_2[23] = L29_2
  L6_2[24] = L30_2
  L6_2[25] = L31_2
  L6_2[26] = L32_2
  L6_2[27] = L33_2
  L6_2[28] = L34_2
  L6_2[29] = L35_2
  L6_2[30] = L36_2
  L6_2[31] = L37_2
  L6_2[32] = L38_2
  L6_2[33] = L39_2
  L6_2[34] = L40_2
  L6_2[35] = L41_2
  L6_2[36] = L42_2
  L6_2[37] = L43_2
  L6_2[38] = L44_2
  L6_2[39] = L45_2
  L6_2[40] = L46_2
  L6_2[41] = L47_2
  L6_2[42] = L48_2
  L5_2.tCourseLocs = L6_2
  
  function L6_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = MrxLayerManager
    L0_3 = L0_3.Remove
    L1_3 = vLayersStage
    L0_3(L1_3)
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
    L2_3 = A0_2
    L3_3 = L2_3
    L2_3 = L2_3.Complete
    L2_3(L3_3)
  end
  
  L5_2.fOnComplete = L6_2
  
  function L6_2()
    local L0_3, L1_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.Cancel
    L0_3(L1_3)
  end
  
  L5_2.fOnCancel = L6_2
  
  function L6_2()
    local L0_3, L1_3, L2_3
    L0_3 = A1_2
    L0_3 = #L0_3
    if 1 < L0_3 then
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._SetCancelMessage
      L2_3 = "[OilCon005.Terms.Cancel01]"
      L0_3(L1_3, L2_3)
    else
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._SetCancelMessage
      L2_3 = "[OilCon005.Terms.Cancel02]"
      L0_3(L1_3, L2_3)
    end
  end
  
  L5_2.fVehiclesDestroyedCallback = L6_2
  L6_2 = {}
  L7_2 = "Fiona-In-Mission-MinorContract-Oil05-01"
  L6_2[1] = L7_2
  L5_2.vVoSeqOnAdd = L6_2
  L3_2 = L3_2(L4_2, L5_2)
  A0_2.oRaceObjective = L3_2
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.ObjectInSeat
  L6_2 = {}
  L7_2 = Player
  L7_2 = L7_2.GetAnyCharacter
  L7_2 = L7_2()
  L8_2 = oCar01
  L9_2 = "d"
  L10_2 = "e"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L7_2 = MrxMusic
  L7_2 = L7_2.PlaySpecialMusic
  L8_2 = {}
  L9_2 = "mu_mission_oilcon005_01"
  L8_2[1] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  eCueMusic = L3_2
end

CarRace = L0_1

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
  L2_2 = "OilCon005_SpawnSportscar01"
  L1_2 = L1_2(L2_2)
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "OilCon005_SpawnSportscar02"
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
    L13_2 = "Veyron"
    L14_2 = L3_2
    L15_2 = L4_2
    L16_2 = L5_2
    L17_2 = L9_2
    L18_2 = true
    L19_2 = true
    L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
    oCar01 = L12_2
    L12_2 = Pg
    L12_2 = L12_2.Spawn
    L13_2 = "Veyron"
    L14_2 = L6_2
    L15_2 = L7_2
    L16_2 = L8_2
    L17_2 = L10_2
    L18_2 = true
    L19_2 = true
    L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
    oCar02 = L12_2
    L12_2 = {}
    L13_2 = oCar01
    L14_2 = oCar02
    L12_2[1] = L13_2
    L12_2[2] = L14_2
    tCars = L12_2
  else
    L12_2 = Pg
    L12_2 = L12_2.Spawn
    L13_2 = "Veyron"
    L14_2 = L3_2
    L15_2 = L4_2
    L16_2 = L5_2
    L17_2 = L9_2
    L18_2 = true
    L19_2 = true
    L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
    oCar01 = L12_2
    L12_2 = {}
    L13_2 = oCar01
    L12_2[1] = L13_2
    tCars = L12_2
  end
  L12_2 = Event
  L12_2 = L12_2.Create
  L13_2 = Event
  L13_2 = L13_2.ObjectHibernation
  L14_2 = {}
  L15_2 = oCar01
  L16_2 = "awake"
  L14_2[1] = L15_2
  L14_2[2] = L16_2
  L15_2 = AssetsLoaded
  L16_2 = {}
  L17_2 = A0_2
  L16_2[1] = L17_2
  L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2)
  eAssetsReady = L12_2
end

GetSportsCars = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = MrxMusic
  L1_2 = L1_2.StopSpecialMusic
  L1_2()
  L1_2 = MrxLayerManager
  L1_2 = L1_2.MarkForRemoval
  L2_2 = vLayersStage
  L1_2(L2_2)
  L1_2 = MrxLayerManager
  L1_2 = L1_2.MarkForRemoval
  L2_2 = vLayersBonus
  L1_2(L2_2)
  L1_2 = ipairs
  L2_2 = tCars
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
    eRemoveSportsCar = L6_2
  end
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
