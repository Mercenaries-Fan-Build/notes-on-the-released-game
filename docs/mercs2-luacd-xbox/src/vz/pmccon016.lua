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
L1_1 = "MrxSubtitle"
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
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = MrxLayerManager
  L2_2 = L2_2.Add
  L3_2 = "vz_state_PmcCon016_a"
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
  L2_2 = A0_2
  L1_2 = A0_2.GetVehicles
  L1_2(L2_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-MinorContract-Pmc16-01"
  L2_2[1] = L3_2
  L1_2(L2_2)
  L1_2 = 75
  nTimeLimit = L1_2
  L1_2 = 15
  nTimeToAdd = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.GetNumCompletions
  L1_2 = L1_2(L2_2)
  if L1_2 == 1 then
    L2_2 = 60
    nTimeLimit = L2_2
    L2_2 = 10
    nTimeToAdd = L2_2
  elseif 2 <= L1_2 then
    L2_2 = 55
    nTimeLimit = L2_2
    L2_2 = 10
    nTimeToAdd = L2_2
  end
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectHibernation
  L5_2 = {}
  L6_2 = tVehicle
  L7_2 = "awake"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = Vehicle
  L6_2 = L6_2.Usable
  L7_2 = {}
  L8_2 = uVehicle
  L9_2 = false
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L2_2 = StartRace
  L3_2 = A0_2
  L4_2 = tVehicle
  L5_2 = nTimeLimit
  L6_2 = nTimeToAdd
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectDeath
  L5_2 = {}
  L6_2 = tVehicle
  L5_2[1] = L6_2
  L6_2 = A0_2.VehicleDeath
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = MrxMusic
  L3_2 = L3_2.PlaySpecialMusic
  L4_2 = "mu_PmcCon016_01"
  L3_2(L4_2)
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.ObjectProximity
  L6_2 = {}
  L7_2 = Player
  L7_2 = L7_2.GetAnyCharacter
  L7_2 = L7_2()
  L8_2 = Pg
  L8_2 = L8_2.GetGuidByName
  L9_2 = "loc_pmccon016_005"
  L8_2 = L8_2(L9_2)
  L9_2 = "<"
  L10_2 = 5
  L11_2 = false
  L12_2 = false
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L6_2[5] = L11_2
  L6_2[6] = L12_2
  L7_2 = FionaProximityVO
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  L3_2 = RaceTutoral
  L4_2 = A0_2
  L3_2(L4_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.ShowMessage
  L2_2 = "[PmcCon016.Terms.Tutorial]"
  L1_2(L2_2)
end

RaceTutoral = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Player
  L1_2 = L1_2.GetCurrentPlayers
  L1_2 = L1_2()
  if L1_2 == 1 then
    L2_2 = MrxUtil
    L2_2 = L2_2.SpawnObject
    L3_2 = "Panhard (Assault)"
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "loc_PmcCon016_Racer"
    L4_2, L5_2 = L4_2(L5_2)
    L2_2 = L2_2(L3_2, L4_2, L5_2)
    tVehicle = L2_2
  elseif L1_2 == 2 then
    L2_2 = MrxUtil
    L2_2 = L2_2.SpawnObject
    L3_2 = "Buggy (Hellfire)"
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "loc_PmcCon016_Racer"
    L4_2, L5_2 = L4_2(L5_2)
    L2_2 = L2_2(L3_2, L4_2, L5_2)
    tVehicle = L2_2
  end
end

GetVehicles = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2
  L5_2 = A0_2
  L4_2 = A0_2.CreateChild
  L6_2 = {}
  L6_2.sRaceMission = "PmcCon016"
  L6_2.sName = "PmcCon016Race"
  L6_2.sModuleName = "MrxTaskRace"
  L6_2.sDspShortDesc = "[PmcCon016.Objectives.002]"
  L6_2.vTgtInclude = A1_2
  L7_2 = {}
  L7_2.nStartTime = A2_2
  L6_2.tTimerParams = L7_2
  L7_2 = {}
  L8_2 = "loc_pmccon016_001"
  L9_2 = "loc_pmccon016_002"
  L10_2 = "loc_pmccon016_003"
  L11_2 = "loc_pmccon016_004"
  L12_2 = "loc_pmccon016_005"
  L13_2 = "loc_pmccon016_006"
  L14_2 = "loc_pmccon016_1"
  L15_2 = "loc_pmccon016_2"
  L16_2 = "loc_pmccon016_3"
  L17_2 = "loc_pmccon016_4"
  L18_2 = "loc_pmccon016_5"
  L19_2 = "loc_pmccon016_6"
  L20_2 = "loc_pmccon016_7"
  L21_2 = "loc_pmccon016_8"
  L22_2 = "loc_pmccon016_9"
  L23_2 = "loc_pmccon016_10"
  L24_2 = "loc_pmccon016_11"
  L25_2 = "loc_pmccon016_12"
  L26_2 = "loc_pmccon016_13"
  L27_2 = "loc_pmccon016_14"
  L28_2 = "loc_pmccon016_15"
  L29_2 = "loc_pmccon016_16"
  L30_2 = "loc_pmccon016_17"
  L31_2 = "loc_pmccon016_18"
  L32_2 = "loc_pmccon016_19"
  L33_2 = "loc_pmccon016_20"
  L34_2 = "loc_pmccon016_21"
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
  L6_2.tCourseLocs = L7_2
  
  function L7_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
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
    L1_3 = MrxVoSequence
    L1_3 = L1_3.Start
    L2_3 = {}
    L3_3 = "Fiona-In-Mission-MinorContract-Pmc16-03"
    L4_3 = 3
    L5_3 = {}
    L6_3 = A0_2
    L6_3 = L6_3.Complete
    L7_3 = {}
    L8_3 = A0_2
    L7_3[1] = L8_3
    L5_3[1] = L6_3
    L5_3[2] = L7_3
    L2_3[1] = L3_3
    L2_3[2] = L4_3
    L2_3[3] = L5_3
    L1_3(L2_3)
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
  L5_2 = A0_2
  L4_2 = A0_2.CreateChild
  L6_2 = {}
  L6_2.sName = "DestructionTargets"
  L6_2.sModuleName = "MrxTaskObjectiveDestroy"
  L6_2.sDspShortDesc = "[PmcCon016.Objectives.005]"
  L6_2.bIsDestruction = true
  L6_2.sDspBlpWldIcon = "HUD_objective_timer"
  L6_2.bDspBlpRdr = false
  L6_2.bDspBlpPda = false
  L6_2.nAddTime = A3_2
  L6_2.bTrackOnActivate = false
  L7_2 = {}
  L8_2 = "PmcCon016_Target1"
  L9_2 = "PmcCon016_Target2"
  L10_2 = "PmcCon016_Target3"
  L11_2 = "PmcCon016_Target4"
  L12_2 = "PmcCon016_Target5"
  L13_2 = "PmcCon016_Target6"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L7_2[5] = L12_2
  L7_2[6] = L13_2
  L6_2.vTgtInclude = L7_2
  
  function L7_2()
    local L0_3, L1_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.ObjectDestroyed
    L0_3(L1_3)
  end
  
  L6_2.fOnPartComplete = L7_2
  
  function L7_2()
    local L0_3, L1_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.CourseUnfinished
    L0_3(L1_3)
  end
  
  L6_2.fOnCancel = L7_2
  L4_2(L5_2, L6_2)
end

StartRace = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.HideMessage
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = A0_2.oRaceObjective
  if L1_2 then
    L1_2 = A0_2.oRaceObjective
    L1_2 = L1_2._oTimer
    L2_2 = L1_2
    L1_2 = L1_2.AddTime
    L3_2 = nTimeToAdd
    L1_2(L2_2, L3_2)
    L1_2 = Hud
    L1_2 = L1_2.ObjectiveTray
    L2_2 = L1_2
    L1_2 = L1_2.SetSlotToText
    L3_2 = {}
    L3_2.nSlot = 2
    L4_2 = "[green]"
    L5_2 = tostring
    L6_2 = nTimeToAdd
    L5_2 = L5_2(L6_2)
    L6_2 = " "
    L7_2 = "[PmcCon016.Terms.Bonus]"
    L4_2 = L4_2 .. L5_2 .. L6_2 .. L7_2
    L3_2.sText = L4_2
    L1_2(L2_2, L3_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 2
  L4_2[1] = L5_2
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = Hud
    L0_3 = L0_3.ObjectiveTray
    L1_3 = L0_3
    L0_3 = L0_3.SetSlotToText
    L2_3 = {}
    L2_3.nSlot = 2
    L2_3.sText = " "
    L0_3(L1_3, L2_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

ObjectDestroyed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-MinorContract-Pmc16-02"
  L2_2[1] = L3_2
  L1_2(L2_2)
end

FionaProximityVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
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
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[PmcCon016.Terms.Cancel03]"
  L1_2(L2_2, L3_2)
end

VehicleDeath = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[PmcCon016.Terms.Cancel01]"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.Cancel
  L1_2(L2_2)
end

VehicleUnentered = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
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
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[PmcCon016.Terms.Cancel02]"
  L1_2(L2_2, L3_2)
end

CourseUnfinished = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxMusic
  L1_2 = L1_2.StopSpecialMusic
  L1_2()
  L1_2 = MrxLayerManager
  L1_2 = L1_2.MarkForRemoval
  L2_2 = "vz_state_PmcCon016_a"
  L1_2(L2_2)
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Object
  L1_2 = L1_2.Remove
  L2_2 = tVehicle
  L1_2(L2_2)
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
end

Cleanup = L0_1
