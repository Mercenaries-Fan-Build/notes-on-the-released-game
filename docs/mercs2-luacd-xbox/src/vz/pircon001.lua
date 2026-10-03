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
L1_1 = "MrxMusic"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxAchievements"
L0_1(L1_1)

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = "VZ_state_PirCon001"
  vLayersMain = L1_2
  L1_2 = "VZ_state_PirCon001_staging"
  vLayersStage = L1_2
  L1_2 = {}
  L2_2 = vLayersMain
  L3_2 = vLayersStage
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L2_2 = MrxLayerManager
  L2_2 = L2_2.Add
  L3_2 = L1_2
  L4_2 = GetJetskis
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L2_2(L3_2, L4_2, L5_2)
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Player
  L1_2 = L1_2.GetAnyCharacter
  L1_2 = L1_2()
  uPlayer = L1_2
  L1_2 = "VZ_state_PirCon001_staging"
  L2_2 = {}
  L3_2 = "Fiona.Race.HurryUp01"
  L4_2 = "Fiona.Race.HurryUp02"
  L5_2 = "Fiona.Race.HurryUp03"
  L6_2 = "Fiona.Race.HurryUp04"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  tHurry = L2_2
  L2_2 = table
  L2_2 = L2_2.getn
  L3_2 = tJetskies
  L2_2 = L2_2(L3_2)
  nJetskies = L2_2
  L3_2 = A0_2
  L2_2 = A0_2.JetskiRace
  L2_2(L3_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2
  L1_2 = "PirCon001"
  L2_2 = "VZ_state_PirCon001"
  L3_2 = "VZ_state_PirCon001_staging"
  L5_2 = A0_2
  L4_2 = A0_2.CreateChild
  L6_2 = {}
  L6_2.sRaceMission = "PirCon001"
  L6_2.sName = "JetskiRace"
  L6_2.sModuleName = "MrxTaskRace"
  L7_2 = tJetskies
  L6_2.vTgtInclude = L7_2
  L7_2 = {}
  L9_2 = A0_2
  L8_2 = A0_2.GetNumCompletions
  L8_2 = L8_2(L9_2)
  if not L8_2 then
    L8_2 = 0
  end
  L8_2 = L8_2 * 2
  L8_2 = 8 - L8_2
  L7_2.nStartTime = L8_2
  L7_2.nStep = 1
  L6_2.tTimerParams = L7_2
  L8_2 = A0_2
  L7_2 = A0_2.GetNumCompletions
  L7_2 = L7_2(L8_2)
  if not L7_2 then
    L7_2 = 0
  end
  L7_2 = 8 - L7_2
  L6_2.nAddTime = L7_2
  L7_2 = {}
  L8_2 = L1_2
  L9_2 = "_checkpoint000"
  L8_2 = L8_2 .. L9_2
  L9_2 = L1_2
  L10_2 = "_checkpoint001"
  L9_2 = L9_2 .. L10_2
  L10_2 = L1_2
  L11_2 = "_checkpoint002"
  L10_2 = L10_2 .. L11_2
  L11_2 = L1_2
  L12_2 = "_checkpoint003"
  L11_2 = L11_2 .. L12_2
  L12_2 = L1_2
  L13_2 = "_checkpoint005"
  L12_2 = L12_2 .. L13_2
  L13_2 = L1_2
  L14_2 = "_checkpoint020"
  L13_2 = L13_2 .. L14_2
  L14_2 = L1_2
  L15_2 = "_checkpoint025"
  L14_2 = L14_2 .. L15_2
  L15_2 = L1_2
  L16_2 = "_checkpoint030"
  L15_2 = L15_2 .. L16_2
  L16_2 = L1_2
  L17_2 = "_checkpoint040"
  L16_2 = L16_2 .. L17_2
  L17_2 = L1_2
  L18_2 = "_checkpoint045"
  L17_2 = L17_2 .. L18_2
  L18_2 = L1_2
  L19_2 = "_checkpoint050"
  L18_2 = L18_2 .. L19_2
  L19_2 = L1_2
  L20_2 = "_checkpoint060"
  L19_2 = L19_2 .. L20_2
  L20_2 = L1_2
  L21_2 = "_checkpoint065"
  L20_2 = L20_2 .. L21_2
  L21_2 = L1_2
  L22_2 = "_checkpoint070"
  L21_2 = L21_2 .. L22_2
  L22_2 = L1_2
  L23_2 = "_checkpoint080"
  L22_2 = L22_2 .. L23_2
  L23_2 = L1_2
  L24_2 = "_checkpoint090"
  L23_2 = L23_2 .. L24_2
  L24_2 = L1_2
  L25_2 = "_checkpoint100"
  L24_2 = L24_2 .. L25_2
  L25_2 = L1_2
  L26_2 = "_checkpoint110"
  L25_2 = L25_2 .. L26_2
  L26_2 = L1_2
  L27_2 = "_checkpoint120"
  L26_2 = L26_2 .. L27_2
  L27_2 = L1_2
  L28_2 = "_checkpoint130"
  L27_2 = L27_2 .. L28_2
  L28_2 = L1_2
  L29_2 = "_checkpoint140"
  L28_2 = L28_2 .. L29_2
  L29_2 = L1_2
  L30_2 = "_checkpoint150"
  L29_2 = L29_2 .. L30_2
  L30_2 = L1_2
  L31_2 = "_checkpoint160"
  L30_2 = L30_2 .. L31_2
  L31_2 = L1_2
  L32_2 = "_checkpoint170"
  L31_2 = L31_2 .. L32_2
  L32_2 = L1_2
  L33_2 = "_checkpoint190"
  L32_2 = L32_2 .. L33_2
  L33_2 = L1_2
  L34_2 = "_checkpoint200"
  L33_2 = L33_2 .. L34_2
  L34_2 = L1_2
  L35_2 = "_checkpoint210"
  L34_2 = L34_2 .. L35_2
  L35_2 = L1_2
  L36_2 = "_checkpoint220"
  L35_2 = L35_2 .. L36_2
  L36_2 = L1_2
  L37_2 = "_checkpoint240"
  L36_2 = L36_2 .. L37_2
  L37_2 = L1_2
  L38_2 = "_checkpoint290"
  L37_2 = L37_2 .. L38_2
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
  L6_2.tCourseLocs = L7_2
  L7_2 = {}
  L8_2 = "Fiona-In-Mission-MinorContract-Pir01-01"
  L7_2[1] = L8_2
  L6_2.vVoSeqOnAdd = L7_2
  
  function L7_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = MrxLayerManager
    L0_3 = L0_3.Remove
    L1_3 = L3_2
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
  L8_2 = Player
  L8_2 = L8_2.GetAnyCharacter
  L8_2 = L8_2()
  L9_2 = oJetski01
  L10_2 = "d"
  L11_2 = "e"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L8_2 = MrxMusic
  L8_2 = L8_2.PlaySpecialMusic
  L9_2 = {}
  L10_2 = "mu_mission_pircon001_01"
  L9_2[1] = L10_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  eCueMusic = L4_2
  L5_2 = A0_2
  L4_2 = A0_2._CreateEvent
  L6_2 = Event
  L6_2 = L6_2.ObjectProximity
  L7_2 = {}
  L8_2 = uPlayer
  L9_2 = Pg
  L9_2 = L9_2.GetGuidByName
  L10_2 = "PirCon001_ConvergeTrigger_Loc"
  L9_2 = L9_2(L10_2)
  L10_2 = "<"
  L11_2 = 25
  L12_2 = false
  L13_2 = false
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L7_2[5] = L12_2
  L7_2[6] = L13_2
  
  function L8_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3
    L1_3 = ConvergeShips
    L2_3 = A0_3
    L3_3 = "Salton_Seahorse_Blocking_01"
    L4_3 = "SS_Blocking_Path_01"
    L5_3 = 0.475
    L1_3(L2_3, L3_3, L4_3, L5_3)
    L1_3 = ConvergeShips
    L2_3 = A0_3
    L3_3 = "Salton_Seahorse_Blocking_02"
    L4_3 = "SS_Blocking_Path_02"
    L5_3 = 0.65
    L1_3(L2_3, L3_3, L4_3, L5_3)
  end
  
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  eDireStraight = L4_2
end

JetskiRace = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  L4_2 = Ai
  L4_2 = L4_2.Goal
  L5_2 = {}
  L6_2 = Vehicle
  L6_2 = L6_2.GetDriver
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = A1_2
  L7_2, L8_2 = L7_2(L8_2)
  L6_2 = L6_2(L7_2, L8_2)
  L5_2.AIGuid = L6_2
  L5_2.Goal = "PathMove"
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = A2_2
  L6_2 = L6_2(L7_2)
  L5_2.Target = L6_2
  L5_2.Mode = "Oneway"
  L5_2.Reverse = false
  L5_2.Haste = A3_2
  L5_2.Priority = "hiPri"
  L4_2(L5_2)
end

ConvergeShips = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = nJetskies
  L1_2 = L1_2 - 1
  nJetskies = L1_2
  L1_2 = Player
  L1_2 = L1_2.GetAllPlayers
  L1_2 = L1_2()
  L2_2 = nJetskies
  L3_2 = #L1_2
  if L2_2 < L3_2 then
    L2_2 = A0_2.Cancel
    L3_2 = A0_2
    L2_2(L3_2)
  end
end

VehicleCheck = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L1_2 = Net
  L1_2 = L1_2.DoneReloadingLayers
  if L1_2 then
    L1_2 = Net
    L1_2 = L1_2.DoneReloadingLayers
    L1_2()
  end
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "PirCon001_SpawnJetski01"
  L1_2 = L1_2(L2_2)
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "PirCon001_SpawnJetski02"
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
    L13_2 = "Jetski (PR)"
    L14_2 = L3_2
    L15_2 = L4_2
    L16_2 = L5_2
    L17_2 = L9_2
    L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2)
    oJetski01 = L12_2
    L12_2 = Pg
    L12_2 = L12_2.Spawn
    L13_2 = "Jetski (PR)"
    L14_2 = L6_2
    L15_2 = L7_2
    L16_2 = L8_2
    L17_2 = L10_2
    L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2)
    oJetski02 = L12_2
    L12_2 = {}
    L13_2 = oJetski01
    L14_2 = oJetski02
    L12_2[1] = L13_2
    L12_2[2] = L14_2
    tJetskies = L12_2
  else
    L12_2 = Pg
    L12_2 = L12_2.Spawn
    L13_2 = "Jetski (PR)"
    L14_2 = L3_2
    L15_2 = L4_2
    L16_2 = L5_2
    L17_2 = L9_2
    L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2)
    oJetski01 = L12_2
    L12_2 = {}
    L13_2 = oJetski01
    L12_2[1] = L13_2
    tJetskies = L12_2
  end
  L12_2 = Event
  L12_2 = L12_2.Create
  L13_2 = Event
  L13_2 = L13_2.ObjectHibernation
  L14_2 = {}
  L15_2 = oJetski01
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

GetJetskis = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 0.5
  L4_2[1] = L5_2
  
  function L5_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L1_3 = MrxVoSequence
    L1_3 = L1_3.Start
    L2_3 = {}
    L3_3 = "PirThug-In-Mission-MinorContract-Pir01-02"
    L2_3[1] = L3_3
    L1_3(L2_3)
    L2_3 = A0_3
    L1_3 = A0_3._CreateEvent
    L3_3 = Event
    L3_3 = L3_3.TimerRelative
    L4_3 = {}
    L5_3 = 1
    L4_3[1] = L5_3
    
    function L5_3(A0_4)
      local L1_4, L2_4, L3_4, L4_4, L5_4, L6_4, L7_4
      L1_4 = MrxVoSequence
      L1_4 = L1_4.Start
      L2_4 = {}
      L3_4 = "PirThug-In-Mission-MinorContract-Pir01-03"
      L2_4[1] = L3_4
      L1_4(L2_4)
      L2_4 = A0_4
      L1_4 = A0_4._CreateEvent
      L3_4 = Event
      L3_4 = L3_4.TimerRelative
      L4_4 = {}
      L5_4 = 1
      L4_4[1] = L5_4
      
      function L5_4(A0_5)
        local L1_5, L2_5, L3_5, L4_5, L5_5, L6_5, L7_5
        L1_5 = MrxVoSequence
        L1_5 = L1_5.Start
        L2_5 = {}
        L3_5 = "PirThug-In-Mission-MinorContract-Pir01-04"
        L2_5[1] = L3_5
        L1_5(L2_5)
        L2_5 = A0_5
        L1_5 = A0_5._CreateEvent
        L3_5 = Event
        L3_5 = L3_5.TimerRelative
        L4_5 = {}
        L5_5 = 1
        L4_5[1] = L5_5
        
        function L5_5(A0_6)
          local L1_6, L2_6, L3_6
          L1_6 = MrxVoSequence
          L1_6 = L1_6.Start
          L2_6 = {}
          L3_6 = "PirThug-In-Mission-MinorContract-Pir01-05"
          L2_6[1] = L3_6
          L1_6(L2_6)
        end
        
        L6_5 = {}
        L7_5 = A0_5
        L6_5[1] = L7_5
        L1_5(L2_5, L3_5, L4_5, L5_5, L6_5)
      end
      
      L6_4 = {}
      L7_4 = A0_4
      L6_4[1] = L7_4
      L1_4(L2_4, L3_4, L4_4, L5_4, L6_4)
    end
    
    L6_3 = {}
    L7_3 = A0_3
    L6_3[1] = L7_3
    L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
  end
  
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

CrowdNoise = L0_1

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
  L2_2 = tJetskies
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
    eRemoveJetski = L6_2
  end
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
