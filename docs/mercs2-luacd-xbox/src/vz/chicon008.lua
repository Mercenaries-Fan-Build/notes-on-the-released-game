local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTaskObjectiveDeliver"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxLayerManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTimer"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxAchievements"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxMusic"
L0_1(L1_1)

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Remove
  L2_2 = {}
  L3_2 = "vz_state_cumana_act1CHI"
  L2_2[1] = L3_2
  L1_2(L2_2)
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "loc_ChiCon008_ZTZ98"
  L1_2 = L1_2(L2_2)
  L2_2 = Object
  L2_2 = L2_2.GetYaw
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  L3_2 = Object
  L3_2 = L3_2.GetPosition
  L4_2 = L1_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  L6_2 = Pg
  L6_2 = L6_2.Spawn
  L7_2 = "ZTZ98"
  L8_2 = L3_2
  L9_2 = L4_2
  L10_2 = L5_2
  L11_2 = L2_2
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  chineseRaceTank = L6_2
  L6_2 = Vehicle
  L6_2 = L6_2.Usable
  L7_2 = chineseRaceTank
  L8_2 = false
  L6_2(L7_2, L8_2)
  L7_2 = A0_2
  L6_2 = A0_2._CreateEvent
  L8_2 = Event
  L8_2 = L8_2.ObjectInSeat
  L9_2 = {}
  L10_2 = Player
  L10_2 = L10_2.GetAnyCharacter
  L10_2 = L10_2()
  L11_2 = chineseRaceTank
  L12_2 = "d"
  L13_2 = "e"
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L9_2[3] = L12_2
  L9_2[4] = L13_2
  L10_2 = MrxMusic
  L10_2 = L10_2.PlaySpecialMusic
  L11_2 = {}
  L12_2 = "mu_mission_chicon008_01"
  L11_2[1] = L12_2
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  L6_2 = 60
  nTimeLimit = L6_2
  L6_2 = 15
  nTimeToAdd = L6_2
  L7_2 = A0_2
  L6_2 = A0_2.GetNumCompletions
  L6_2 = L6_2(L7_2)
  if L6_2 == 1 then
    L7_2 = 50
    nTimeLimit = L7_2
    L7_2 = 10
    nTimeToAdd = L7_2
  elseif 2 <= L6_2 then
    L7_2 = 40
    nTimeLimit = L7_2
    L7_2 = 10
    nTimeToAdd = L7_2
  end
  L7_2 = StartRace
  L8_2 = A0_2
  L9_2 = tVehicle
  L10_2 = nTimeLimit
  L11_2 = nTimeToAdd
  L7_2(L8_2, L9_2, L10_2, L11_2)
  L8_2 = A0_2
  L7_2 = A0_2._CreateEvent
  L9_2 = Event
  L9_2 = L9_2.ObjectDeath
  L10_2 = {}
  L11_2 = Pg
  L11_2 = L11_2.GetGuidByName
  L12_2 = "ChiCon008_ZTZ98"
  L11_2, L12_2, L13_2 = L11_2(L12_2)
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L11_2 = A0_2.Cancel
  L12_2 = {}
  L13_2 = A0_2
  L12_2[1] = L13_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L8_2 = RaceTutorial
  L9_2 = A0_2
  L8_2(L9_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.ShowMessage
  L2_2 = "[ChiCon008.Terms.Tutorial]"
  L1_2(L2_2)
end

RaceTutorial = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2
  L4_2 = "ChiCon008"
  L5_2 = FionaVoChiCon008
  L6_2 = A0_2
  L5_2(L6_2)
  L6_2 = A0_2
  L5_2 = A0_2.CreateChild
  L7_2 = {}
  L7_2.sName = "TankRace"
  L7_2.sModuleName = "MrxTaskObjectiveDestroy"
  L7_2.bIsDestruction = true
  L7_2.sDspBlpWldIcon = "HUD_objective_timer"
  L7_2.bDspBlpRdr = false
  L7_2.bDspBlpPda = false
  L7_2.bOptional = true
  L8_2 = nTimeToAdd
  L7_2.nAddTime = L8_2
  L7_2.bTrackOnActivate = false
  L8_2 = {}
  L9_2 = "destroy_barrel_01"
  L10_2 = "destroy_barrel_02"
  L11_2 = "destroy_barrel_03"
  L12_2 = "destroy_barrel_04"
  L13_2 = "destroy_barrel_05"
  L14_2 = "destroy_barrel_06"
  L15_2 = "destroy_barrel_07"
  L16_2 = "destroy_barrel_08"
  L17_2 = "destroy_barrel_09"
  L18_2 = "destroy_barrel_010"
  L19_2 = "destroy_barrel_011"
  L20_2 = "destroy_barrel_012"
  L21_2 = "destroy_barrel_013"
  L22_2 = "destroy_barrel_014"
  L23_2 = "destroy_barrel_015"
  L24_2 = "destroy_barrel_016"
  L25_2 = "destroy_barrel_017"
  L26_2 = "destroy_barrel_018"
  L27_2 = "destroy_barrel_019"
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
  L7_2.vTgtInclude = L8_2
  
  function L8_2()
    local L0_3, L1_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.ObjectDestroyed
    L0_3(L1_3)
  end
  
  L7_2.fOnPartComplete = L8_2
  
  function L8_2()
    local L0_3, L1_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.RaceFailed
    L0_3(L1_3)
  end
  
  L7_2.fOnCancel = L8_2
  L5_2(L6_2, L7_2)
  L6_2 = A0_2
  L5_2 = A0_2.CreateChild
  L7_2 = {}
  L7_2.sRaceMission = "ChiCon008"
  L7_2.sName = "ZTZ98 Race"
  L7_2.sModuleName = "MrxTaskRace"
  L8_2 = {}
  L8_2.nStartTime = A2_2
  L7_2.tTimerParams = L8_2
  L8_2 = chineseRaceTank
  L7_2.vTgtInclude = L8_2
  L7_2.sDspShortDesc = "[ChiCon008.Objectives.001]"
  L8_2 = {}
  L9_2 = L4_2
  L10_2 = "_Checkpoint01"
  L9_2 = L9_2 .. L10_2
  L10_2 = L4_2
  L11_2 = "_Checkpoint02"
  L10_2 = L10_2 .. L11_2
  L11_2 = L4_2
  L12_2 = "_Checkpoint002"
  L11_2 = L11_2 .. L12_2
  L12_2 = L4_2
  L13_2 = "_Checkpoint03"
  L12_2 = L12_2 .. L13_2
  L13_2 = L4_2
  L14_2 = "_Checkpoint04"
  L13_2 = L13_2 .. L14_2
  L14_2 = L4_2
  L15_2 = "_Checkpoint004"
  L14_2 = L14_2 .. L15_2
  L15_2 = L4_2
  L16_2 = "_Checkpoint05"
  L15_2 = L15_2 .. L16_2
  L16_2 = L4_2
  L17_2 = "_Checkpoint005"
  L16_2 = L16_2 .. L17_2
  L17_2 = L4_2
  L18_2 = "_Checkpoint06"
  L17_2 = L17_2 .. L18_2
  L18_2 = L4_2
  L19_2 = "_Checkpoint006"
  L18_2 = L18_2 .. L19_2
  L19_2 = L4_2
  L20_2 = "_Checkpoint07"
  L19_2 = L19_2 .. L20_2
  L20_2 = L4_2
  L21_2 = "_Checkpoint007"
  L20_2 = L20_2 .. L21_2
  L21_2 = L4_2
  L22_2 = "_Checkpoint08"
  L21_2 = L21_2 .. L22_2
  L22_2 = L4_2
  L23_2 = "_Checkpoint008"
  L22_2 = L22_2 .. L23_2
  L23_2 = L4_2
  L24_2 = "_Checkpoint09"
  L23_2 = L23_2 .. L24_2
  L24_2 = L4_2
  L25_2 = "_Checkpoint009"
  L24_2 = L24_2 .. L25_2
  L25_2 = L4_2
  L26_2 = "_Checkpoint10"
  L25_2 = L25_2 .. L26_2
  L26_2 = L4_2
  L27_2 = "_Checkpoint0010"
  L26_2 = L26_2 .. L27_2
  L27_2 = L4_2
  L28_2 = "_Checkpoint11"
  L27_2 = L27_2 .. L28_2
  L28_2 = L4_2
  L29_2 = "_Checkpoint12"
  L28_2 = L28_2 .. L29_2
  L29_2 = L4_2
  L30_2 = "_Checkpoint13"
  L29_2 = L29_2 .. L30_2
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
  L7_2.tCourseLocs = L8_2
  
  function L8_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
    L0_3 = A0_2
    L0_3 = L0_3.oTankRaceObjective
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
    L3_3 = "Fiona-In-Mission-Contract-Pmc01-10"
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
  
  L7_2.fOnComplete = L8_2
  
  function L8_2()
    local L0_3, L1_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.RaceFailed
    L0_3(L1_3)
  end
  
  L7_2.fOnCancel = L8_2
  L5_2 = L5_2(L6_2, L7_2)
  A0_2.oTankRaceObjective = L5_2
end

StartRace = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.HideMessage
  L2_2 = A0_2
  L1_2(L2_2)
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
  L7_2 = "[ChiCon008.Terms.Bonus]"
  L4_2 = L4_2 .. L5_2 .. L6_2 .. L7_2
  L3_2.sText = L4_2
  L1_2(L2_2, L3_2)
  L1_2 = A0_2.oTankRaceObjective
  if L1_2 then
    L1_2 = A0_2.oTankRaceObjective
    L1_2 = L1_2._oTimer
    L2_2 = L1_2
    L1_2 = L1_2.AddTime
    L3_2 = nTimeToAdd
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
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-MinorContract-Chi08-01"
  L2_2[1] = L3_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "ChiCon008_Checkpoint07"
  L6_2 = L6_2(L7_2)
  L7_2 = "<"
  L8_2 = 60
  L9_2 = false
  L10_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-MinorContract-Chi08-02"
    L1_3[1] = L2_3
    L0_3(L1_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "ChiCon008_Checkpoint04"
  L6_2 = L6_2(L7_2)
  L7_2 = "<"
  L8_2 = 60
  L9_2 = false
  L10_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-Chi08-04"
    L3_3 = 2
    L4_3 = {}
    L4_3.mattias = "Mattias-In-Mission-Contract-Chi08-06"
    L4_3.jennifer = "Jennifer-In-Mission-Contract-Chi08-07"
    L4_3.chris = "Chris-In-Mission-Contract-Chi08-08"
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L1_3[3] = L4_3
    L0_3(L1_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

FionaVoChiCon008 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Chi08-02"
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
  L3_2 = "[ChiCon008.Terms.Cancel01]"
  L1_2(L2_2, L3_2)
end

VehicleUnentered = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Chi08-03"
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
  L3_2 = "[ChiCon008.Terms.Cancel02]"
  L1_2(L2_2, L3_2)
end

RaceFailed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.SetSlotToText
  L3_2 = {}
  L3_2.nSlot = 1
  L3_2.sText = " "
  L1_2(L2_2, L3_2)
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.SetSlotToText
  L3_2 = {}
  L3_2.nSlot = 2
  L3_2.sText = " "
  L1_2(L2_2, L3_2)
  L1_2 = Object
  L1_2 = L1_2.Remove
  L2_2 = chineseRaceTank
  L1_2(L2_2)
  L1_2 = MrxMusic
  L1_2 = L1_2.StopSpecialMusic
  L1_2()
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Add
  L2_2 = {}
  L3_2 = "vz_state_cumana_act1CHI"
  L2_2[1] = L3_2
  L1_2(L2_2)
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
