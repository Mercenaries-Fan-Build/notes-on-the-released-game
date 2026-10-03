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
L1_1 = "MrxTaskObjectiveDestroy"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxLayerManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxMusic"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxAchievements"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = MrxLayerManager
  L2_2 = L2_2.Add
  L3_2 = "vz_state_PmcCon015_a"
  L4_2 = A0_2.AssetsLoaded
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L2_2(L3_2, L4_2, L5_2)
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Player
  L1_2 = L1_2.GetCurrentPlayers
  L1_2 = L1_2()
  if L1_2 == 2 then
    L2_2 = MrxUtil
    L2_2 = L2_2.SpawnObject
    L3_2 = "Phoenix (racing)"
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "loc_PmcCon015_RaceCar_MP"
    L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L4_2(L5_2)
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
    mpVehicle = L2_2
    L2_2 = MrxUtil
    L2_2 = L2_2.SpawnObject
    L3_2 = "Phoenix (racing)"
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "loc_PmcCon015_RaceCar_SP"
    L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L4_2(L5_2)
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
    spVehicle = L2_2
    L2_2 = {}
    L3_2 = spVehicle
    L4_2 = mpVehicle
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    tVehicle = L2_2
  else
    L2_2 = MrxUtil
    L2_2 = L2_2.SpawnObject
    L3_2 = "Phoenix (racing)"
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "loc_PmcCon015_RaceCar_SP"
    L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L4_2(L5_2)
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
    spVehicle = L2_2
    L2_2 = {}
    L3_2 = spVehicle
    L2_2[1] = L3_2
    tVehicle = L2_2
  end
  L2_2 = 45
  L3_2 = 10
  L5_2 = A0_2
  L4_2 = A0_2.GetNumCompletions
  L4_2 = L4_2(L5_2)
  if L4_2 == 1 then
    L2_2 = 30
    L3_2 = 5
  elseif 2 <= L4_2 then
    L2_2 = 25
    L3_2 = 5
  end
  L5_2 = StartRace
  L6_2 = A0_2
  L7_2 = tVehicle
  L8_2 = L2_2
  L9_2 = L3_2
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = A0_2
  L5_2 = A0_2._CreateEvent
  L7_2 = Event
  L7_2 = L7_2.ObjectInSeat
  L8_2 = {}
  L9_2 = Player
  L9_2 = L9_2.GetAnyCharacter
  L9_2 = L9_2()
  L10_2 = tVehicle
  L11_2 = "d"
  L12_2 = "e"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  L9_2 = MrxMusic
  L9_2 = L9_2.PlaySpecialMusic
  L10_2 = {}
  L11_2 = "mercs_mu_score_recruit_01"
  L10_2[1] = L11_2
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L6_2 = A0_2
  L5_2 = A0_2._CreateEvent
  L7_2 = Event
  L7_2 = L7_2.ObjectDeath
  L8_2 = {}
  L9_2 = Pg
  L9_2 = L9_2.GetGuidByName
  L10_2 = "PmcCon015_RaceCar"
  L9_2, L10_2, L11_2, L12_2 = L9_2(L10_2)
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  L9_2 = A0_2.VehicleDeath
  L10_2 = {}
  L11_2 = A0_2
  L10_2[1] = L11_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
end

Activated = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2
  L5_2 = A0_2
  L4_2 = A0_2.CreateChild
  L6_2 = {}
  L6_2.sRaceMission = "PmcCon015"
  L6_2.sName = "PmcCon015Race"
  L6_2.sModuleName = "MrxTaskRace"
  L6_2.vTgtInclude = A1_2
  L6_2.sDspShortDesc = "[PmcCon015.Objectives.003]"
  L7_2 = {}
  L7_2.nStartTime = A2_2
  L6_2.tTimerParams = L7_2
  L6_2.nAddTime = A3_2
  L7_2 = {}
  L8_2 = "loc_pmccon015_checkpoint_1"
  L9_2 = "loc_pmccon015_checkpoint_2"
  L10_2 = "loc_pmccon015_checkpoint_3"
  L11_2 = "loc_pmccon015_checkpoint_4"
  L12_2 = "loc_pmccon015_checkpoint_5"
  L13_2 = "loc_pmccon015_checkpoint_6"
  L14_2 = "loc_pmccon015_checkpoint_7"
  L15_2 = "loc_pmccon015_checkpoint_9"
  L16_2 = "loc_pmccon015_checkpoint_10"
  L17_2 = "loc_pmccon015_checkpoint_11"
  L18_2 = "loc_pmccon015_checkpoint_12"
  L19_2 = "loc_pmccon015_checkpoint_13"
  L20_2 = "loc_pmccon015_checkpoint_14"
  L21_2 = "loc_pmccon015_checkpoint_15"
  L22_2 = "loc_pmccon015_checkpoint_16"
  L23_2 = "loc_pmccon015_checkpoint_17"
  L24_2 = "loc_pmccon015_checkpoint_18"
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
  L6_2.tCourseLocs = L7_2
  
  function L7_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
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
    L2_3 = MrxVoSequence
    L2_3 = L2_3.Start
    L3_3 = {}
    L4_3 = "Fiona-In-Mission-MinorContract-Pmc16-03"
    L5_3 = 3
    L6_3 = {}
    L7_3 = A0_2
    L7_3 = L7_3.Complete
    L8_3 = {}
    L9_3 = A0_2
    L8_3[1] = L9_3
    L6_3[1] = L7_3
    L6_3[2] = L8_3
    L3_3[1] = L4_3
    L3_3[2] = L5_3
    L3_3[3] = L6_3
    L2_3(L3_3)
  end
  
  L6_2.fOnComplete = L7_2
  
  function L7_2()
    local L0_3, L1_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.CourseUnfinished
    L0_3(L1_3)
  end
  
  L6_2.fOnCancel = L7_2
  L4_2 = L4_2(L5_2, L6_2)
  A0_2.oRaceObjective = L4_2
end

StartRace = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[PmcCon015.Terms.Cancel03]"
  L1_2(L2_2, L3_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-MinorContract-Pmc16-04"
  L4_2 = 3
  L5_2 = {}
  L6_2 = A0_2.Cancel
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L1_2(L2_2)
end

VehicleDeath = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[PmcCon015.Terms.Cancel04]"
  L1_2(L2_2, L3_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-MinorContract-Pmc16-05"
  L4_2 = 3
  L5_2 = {}
  L6_2 = A0_2.Cancel
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L1_2(L2_2)
end

CourseUnfinished = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxMusic
  L1_2 = L1_2.StopSpecialMusic
  L1_2()
  L1_2 = MrxLayerManager
  L1_2 = L1_2.MarkForRemoval
  L2_2 = "vz_state_PmcCon015_a"
  L1_2(L2_2)
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = isMultiplayer
  if L1_2 == 2 then
    L1_2 = Object
    L1_2 = L1_2.Remove
    L2_2 = mpVehicle
    L1_2(L2_2)
    L1_2 = Object
    L1_2 = L1_2.Remove
    L2_2 = spVehicle
    L1_2(L2_2)
  else
    L1_2 = Object
    L1_2 = L1_2.Remove
    L2_2 = spVehicle
    L1_2(L2_2)
  end
end

Cleanup = L0_1
