local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTaskRace"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = {}
  L3_2 = "vz_state_car_city_act1"
  L4_2 = "vz_state_mar_city_act1"
  L5_2 = "vz_state_staging_pirhq"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  tLayersToRemove = L2_2
  L2_2 = MrxLayerManager
  L2_2 = L2_2.Remove
  L3_2 = tLayersToRemove
  
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = {}
    L1_3 = "VZ_State_GurCon003"
    L0_3[1] = L1_3
    L1_3 = MrxLayerManager
    L1_3 = L1_3.Add
    L2_3 = L0_3
    L3_3 = A0_2
    L3_3 = L3_3.AssetsLoaded
    L4_3 = {}
    L5_3 = A0_2
    L4_3[1] = L5_3
    L1_3(L2_3, L3_3, L4_3)
  end
  
  L2_2(L3_2, L4_2)
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = {}
  tInitialVOTable = L1_2
  L1_2 = 1
  nPurLevel = L1_2
  L1_2 = 180
  nTimerLevel = L1_2
  L1_2 = false
  bClientwasIn = L1_2
  L1_2 = false
  bMusicStarted = L1_2
  L1_2 = 0
  nTutePlayed = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "GurCon003_deliv"
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
  L7_2 = "Piranha"
  L8_2 = L3_2
  L9_2 = L4_2
  L10_2 = L5_2
  L11_2 = L2_2
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  uPiranha = L6_2
  L6_2 = {}
  L7_2 = uPiranha
  L6_2[1] = L7_2
  tPiranha = L6_2
  L6_2 = Player
  L6_2 = L6_2.IsCoopMultiplayer
  L6_2 = L6_2()
  if L6_2 then
    L6_2 = SetupMPGame
    L7_2 = A0_2
    L6_2(L7_2)
  end
  L7_2 = A0_2
  L6_2 = A0_2.GetNumCompletions
  L6_2 = L6_2(L7_2)
  if 2 <= L6_2 then
    L7_2 = {}
    L8_2 = "Fiona-In-Mission-MinorContract-Gur03-20"
    L7_2[1] = L8_2
    tInitialVOTable = L7_2
    L7_2 = 3
    nPurLevel = L7_2
    L7_2 = 120
    nTimerLevel = L7_2
    L7_2 = {}
    L8_2 = "VZ_State_GurCon003_Med"
    L7_2[1] = L8_2
    L8_2 = MrxLayerManager
    L8_2 = L8_2.Add
    L9_2 = L7_2
    L8_2(L9_2)
  elseif L6_2 == 1 then
    L7_2 = {}
    L8_2 = "Fiona-In-Mission-MinorContract-Gur03-21"
    L7_2[1] = L8_2
    tInitialVOTable = L7_2
    L7_2 = {}
    L8_2 = "VZ_State_GurCon003_Med"
    L7_2[1] = L8_2
    L8_2 = MrxLayerManager
    L8_2 = L8_2.Add
    L9_2 = L7_2
    L8_2(L9_2)
    L8_2 = 2
    nPurLevel = L8_2
    L8_2 = 150
    nTimerLevel = L8_2
  else
    L7_2 = {}
    L8_2 = "Fiona-Banter-MinorContract-Gur03-01"
    L9_2 = 0.5
    L10_2 = {}
    L10_2.mattias = "mattias-Banter-MinorContract-Gur03-02"
    L10_2.jennifer = "jennifer-Banter-MinorContract-Gur03-03"
    L10_2.chris = "chris-Banter-MinorContract-Gur03-04"
    L11_2 = 0.5
    L12_2 = "Fiona-Banter-MinorContract-Gur03-05"
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L7_2[4] = L11_2
    L7_2[5] = L12_2
    tInitialVOTable = L7_2
    L7_2 = 1
    nPurLevel = L7_2
    L7_2 = 300
    nTimerLevel = L7_2
    L7_2 = CreateTutorialTrigger
    L8_2 = A0_2
    L7_2(L8_2)
  end
  L8_2 = A0_2
  L7_2 = A0_2.CreateChild
  L9_2 = {}
  L9_2.sRaceMission = "GurCon003"
  L9_2.sName = "DeliverBoat"
  L9_2.sModuleName = "MrxTaskRace"
  L9_2.sDspShortDesc = "[GurCon003.Objectives.002]"
  L10_2 = tPiranha
  L9_2.vTgtInclude = L10_2
  L10_2 = tInitialVOTable
  L9_2.vVoSeqOnAdd = L10_2
  L9_2.fWidth = 30
  L10_2 = {}
  L11_2 = nPurLevel
  L11_2 = L11_2 * 5
  L11_2 = 50 - L11_2
  L10_2.nStartTime = L11_2
  L9_2.tTimerParams = L10_2
  L10_2 = nPurLevel
  L10_2 = L10_2 * 2
  L10_2 = 17 - L10_2
  L9_2.nAddTime = L10_2
  L10_2 = {}
  L11_2 = "GurCon3_gate_02"
  L12_2 = "GurCon3_gate_05"
  L13_2 = "GurCon3_gate_10"
  L14_2 = "GurCon3_gate_12"
  L15_2 = "GurCon3_gate_15"
  L16_2 = "GurCon3_gate_20"
  L17_2 = "GurCon3_gate_28"
  L18_2 = "GurCon3_gate_30"
  L19_2 = "GurCon3_gate_35"
  L20_2 = "GurCon3_gate_37"
  L21_2 = "GurCon3_gate_40"
  L22_2 = "GurCon3_gate_49"
  L23_2 = "GurCon3_gate_51"
  L24_2 = "GurCon3_gate_54"
  L25_2 = "GurCon3_gate_55"
  L26_2 = "GurCon3_gate_56"
  L27_2 = "GurCon3_gate_57"
  L28_2 = "GurCon3_gate_60"
  L29_2 = "GurCon3_gate_63"
  L30_2 = "GurCon3_gate_65"
  L31_2 = "GurCon3_gate_70"
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L10_2[5] = L15_2
  L10_2[6] = L16_2
  L10_2[7] = L17_2
  L10_2[8] = L18_2
  L10_2[9] = L19_2
  L10_2[10] = L20_2
  L10_2[11] = L21_2
  L10_2[12] = L22_2
  L10_2[13] = L23_2
  L10_2[14] = L24_2
  L10_2[15] = L25_2
  L10_2[16] = L26_2
  L10_2[17] = L27_2
  L10_2[18] = L28_2
  L10_2[19] = L29_2
  L10_2[20] = L30_2
  L10_2[21] = L31_2
  L9_2.tCourseLocs = L10_2
  
  function L10_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = Object
    L0_3 = L0_3.GetHealth
    L1_3 = uPiranha
    L0_3 = L0_3(L1_3)
    if 50 <= L0_3 then
      L0_3 = MrxUtil
      L0_3 = L0_3.TestDistanceToAllPlayers
      L1_3 = uPiranha
      L2_3 = 60
      L3_3 = false
      L4_3 = true
      L0_3 = L0_3(L1_3, L2_3, L3_3, L4_3)
      if not L0_3 then
        L0_3 = MrxVoSequence
        L0_3 = L0_3.Start
        L1_3 = {}
        L2_3 = "ChinaSoldier-In-Mission-MinorContract-Gur03-18"
        L1_3[1] = L2_3
        L0_3(L1_3)
        L0_3 = Net
        L0_3 = L0_3.IsActive
        L0_3 = L0_3()
        if L0_3 then
          L0_3 = A0_2
          L1_3 = L0_3
          L0_3 = L0_3._SetPlayer1Bonus
          L2_3 = 500000
          L0_3(L1_3, L2_3)
          L0_3 = A0_2
          L1_3 = L0_3
          L0_3 = L0_3._SetPlayer2Bonus
          L2_3 = 500000
          L0_3(L1_3, L2_3)
        else
          L0_3 = A0_2
          L1_3 = L0_3
          L0_3 = L0_3._SetPlayer1Bonus
          L2_3 = 500000
          L0_3(L1_3, L2_3)
        end
      end
    end
    L0_3 = bClientwasIn
    if L0_3 then
      L0_3 = Object
      L0_3 = L0_3.GetHealth
      L1_3 = uPiranhaB
      L0_3 = L0_3(L1_3)
      if 50 <= L0_3 then
        L0_3 = MrxUtil
        L0_3 = L0_3.TestDistanceToAllPlayers
        L1_3 = uPiranhaB
        L2_3 = 60
        L3_3 = false
        L4_3 = true
        L0_3 = L0_3(L1_3, L2_3, L3_3, L4_3)
        if not L0_3 then
          L0_3 = MrxVoSequence
          L0_3 = L0_3.Start
          L1_3 = {}
          L2_3 = "ChinaSoldier-In-Mission-MinorContract-Gur03-18"
          L1_3[1] = L2_3
          L0_3(L1_3)
          L0_3 = Net
          L0_3 = L0_3.IsActive
          L0_3 = L0_3()
          if L0_3 then
            L0_3 = A0_2
            L1_3 = L0_3
            L0_3 = L0_3._SetPlayer1Bonus
            L2_3 = 500000
            L0_3(L1_3, L2_3)
            L0_3 = A0_2
            L1_3 = L0_3
            L0_3 = L0_3._SetPlayer2Bonus
            L2_3 = 500000
            L0_3(L1_3, L2_3)
          else
            L0_3 = A0_2
            L1_3 = L0_3
            L0_3 = L0_3._SetPlayer1Bonus
            L2_3 = 500000
            L0_3(L1_3, L2_3)
          end
        end
      end
    end
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._CreateEvent
    L2_3 = Event
    L2_3 = L2_3.TimerRelative
    L3_3 = {}
    L4_3 = 4
    L3_3[1] = L4_3
    L4_3 = A0_2
    L4_3 = L4_3.Complete
    L5_3 = {}
    L6_3 = A0_2
    L5_3[1] = L6_3
    L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
  end
  
  L9_2.fOnComplete = L10_2
  
  function L10_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._SetCancelMessage
    L2_3 = "[GurCon003.Terms.Cancel02]"
    L0_3(L1_3, L2_3)
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._CreateEvent
    L2_3 = Event
    L2_3 = L2_3.TimerRelative
    L3_3 = {}
    L4_3 = 4
    L3_3[1] = L4_3
    L4_3 = A0_2
    L4_3 = L4_3.Cancel
    L5_3 = {}
    L6_3 = A0_2
    L5_3[1] = L6_3
    L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
  end
  
  L9_2.fOnCancel = L10_2
  L7_2 = L7_2(L8_2, L9_2)
  oRaceObj = L7_2
  L7_2 = _SetupBonusObjective
  L8_2 = A0_2
  L7_2(L8_2)
  L7_2 = 1
  L8_2 = 5
  L9_2 = 1
  for L10_2 = L7_2, L8_2, L9_2 do
    L11_2 = Pg
    L11_2 = L11_2.GetGuidByName
    L12_2 = "BoatBlock_"
    L13_2 = L10_2
    L12_2 = L12_2 .. L13_2
    L11_2 = L11_2(L12_2)
    uBoatBlock = L11_2
    L11_2 = uBoatBlock
    if L11_2 then
      L12_2 = A0_2
      L11_2 = A0_2._CreateEvent
      L13_2 = Event
      L13_2 = L13_2.ObjectHibernation
      L14_2 = {}
      L15_2 = uBoatBlock
      L16_2 = "awake"
      L14_2[1] = L15_2
      L14_2[2] = L16_2
      L15_2 = RiverMovers
      L16_2 = {}
      L17_2 = A0_2
      L18_2 = L10_2
      L16_2[1] = L17_2
      L16_2[2] = L18_2
      L11_2(L12_2, L13_2, L14_2, L15_2, L16_2)
    end
  end
  L7_2 = 1
  L8_2 = 4
  L9_2 = 1
  for L10_2 = L7_2, L8_2, L9_2 do
    L12_2 = A0_2
    L11_2 = A0_2._CreateEvent
    L13_2 = Event
    L13_2 = L13_2.ObjectHibernation
    L14_2 = {}
    L15_2 = Pg
    L15_2 = L15_2.GetGuidByName
    L16_2 = "Finder_"
    L17_2 = L10_2
    L16_2 = L16_2 .. L17_2
    L15_2 = L15_2(L16_2)
    L16_2 = "awake"
    L14_2[1] = L15_2
    L14_2[2] = L16_2
    L15_2 = FinderMovers
    L16_2 = {}
    L17_2 = A0_2
    L18_2 = L10_2
    L16_2[1] = L17_2
    L16_2[2] = L18_2
    L11_2(L12_2, L13_2, L14_2, L15_2, L16_2)
  end
  L8_2 = A0_2
  L7_2 = A0_2._CreateEvent
  L9_2 = Event
  L9_2 = L9_2.ObjectProximity
  L10_2 = {}
  L11_2 = Player
  L11_2 = L11_2.GetAnyCharacter
  L11_2 = L11_2()
  L12_2 = Pg
  L12_2 = L12_2.GetGuidByName
  L13_2 = "1stmine"
  L12_2 = L12_2(L13_2)
  L13_2 = "<"
  L14_2 = 50
  L15_2 = false
  L16_2 = false
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L10_2[5] = L15_2
  L10_2[6] = L16_2
  L11_2 = MineTalk
  L12_2 = {}
  L13_2 = A0_2
  L12_2[1] = L13_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L8_2 = A0_2
  L7_2 = A0_2._CreateEvent
  L9_2 = Event
  L9_2 = L9_2.ObjectProximity
  L10_2 = {}
  L11_2 = Player
  L11_2 = L11_2.GetAnyCharacter
  L11_2 = L11_2()
  L12_2 = Pg
  L12_2 = L12_2.GetGuidByName
  L13_2 = "GurCon3_gate_40"
  L12_2 = L12_2(L13_2)
  L13_2 = "<"
  L14_2 = 15
  L15_2 = false
  L16_2 = false
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L10_2[5] = L15_2
  L10_2[6] = L16_2
  L11_2 = SetTime
  L12_2 = {}
  L13_2 = A0_2
  L12_2[1] = L13_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L7_2 = nPurLevel
  if L7_2 == 1 then
    L8_2 = A0_2
    L7_2 = A0_2._CreateEvent
    L9_2 = Event
    L9_2 = L9_2.ObjectProximity
    L10_2 = {}
    L11_2 = uPiranha
    L12_2 = Pg
    L12_2 = L12_2.GetGuidByName
    L13_2 = "GurCon3_gate_20"
    L12_2 = L12_2(L13_2)
    L13_2 = "<"
    L14_2 = 40
    L15_2 = false
    L16_2 = false
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L10_2[3] = L13_2
    L10_2[4] = L14_2
    L10_2[5] = L15_2
    L10_2[6] = L16_2
    L11_2 = SecondTute
    L12_2 = {}
    L13_2 = A0_2
    L12_2[1] = L13_2
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  end
  L8_2 = A0_2
  L7_2 = A0_2._CreateEvent
  L9_2 = Event
  L9_2 = L9_2.ObjectProximity
  L10_2 = {}
  L11_2 = uPiranha
  L12_2 = Pg
  L12_2 = L12_2.GetGuidByName
  L13_2 = "GurCon003_dest"
  L12_2 = L12_2(L13_2)
  L13_2 = "<"
  L14_2 = 400
  L15_2 = false
  L16_2 = false
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L10_2[5] = L15_2
  L10_2[6] = L16_2
  L11_2 = EndPursuit
  L12_2 = {}
  L13_2 = A0_2
  L12_2[1] = L13_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L8_2 = A0_2
  L7_2 = A0_2._CreateEvent
  L9_2 = Event
  L9_2 = L9_2.ObjectDeath
  L10_2 = {}
  L11_2 = uPiranha
  L10_2[1] = L11_2
  L11_2 = BoatDestroyed
  L12_2 = {}
  L13_2 = A0_2
  L12_2[1] = L13_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  uBoatDeath = L7_2
  L8_2 = A0_2
  L7_2 = A0_2._CreateEvent
  L9_2 = Event
  L9_2 = L9_2.ObjectDeath
  L10_2 = {}
  L11_2 = Pg
  L11_2 = L11_2.GetGuidByName
  L12_2 = "ChinaContact"
  L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2 = L11_2(L12_2)
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L10_2[5] = L15_2
  L10_2[6] = L16_2
  L10_2[7] = L17_2
  L10_2[8] = L18_2
  L10_2[9] = L19_2
  L10_2[10] = L20_2
  L10_2[11] = L21_2
  L10_2[12] = L22_2
  L10_2[13] = L23_2
  L10_2[14] = L24_2
  L10_2[15] = L25_2
  L10_2[16] = L26_2
  L10_2[17] = L27_2
  L10_2[18] = L28_2
  L10_2[19] = L29_2
  L10_2[20] = L30_2
  L10_2[21] = L31_2
  L11_2 = ContactKilled
  L12_2 = {}
  L13_2 = A0_2
  L12_2[1] = L13_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L8_2 = A0_2
  L7_2 = A0_2._CreateEvent
  L9_2 = Event
  L9_2 = L9_2.ObjectDeath
  L10_2 = {}
  L11_2 = Pg
  L11_2 = L11_2.GetGuidByName
  L12_2 = "ChinaDriver"
  L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2 = L11_2(L12_2)
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L10_2[5] = L15_2
  L10_2[6] = L16_2
  L10_2[7] = L17_2
  L10_2[8] = L18_2
  L10_2[9] = L19_2
  L10_2[10] = L20_2
  L10_2[11] = L21_2
  L10_2[12] = L22_2
  L10_2[13] = L23_2
  L10_2[14] = L24_2
  L10_2[15] = L25_2
  L10_2[16] = L26_2
  L10_2[17] = L27_2
  L10_2[18] = L28_2
  L10_2[19] = L29_2
  L10_2[20] = L30_2
  L10_2[21] = L31_2
  L11_2 = ContactKilled
  L12_2 = {}
  L13_2 = A0_2
  L12_2[1] = L13_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L7_2 = ipairs
  L8_2 = tPiranha
  L7_2, L8_2, L9_2 = L7_2(L8_2)
  for L10_2, L11_2 in L7_2, L8_2, L9_2 do
    L13_2 = A0_2
    L12_2 = A0_2._CreateEvent
    L14_2 = Event
    L14_2 = L14_2.ObjectInSeat
    L15_2 = {}
    L16_2 = Player
    L16_2 = L16_2.GetAnyCharacter
    L16_2 = L16_2()
    L17_2 = L11_2
    L18_2 = "A"
    L19_2 = "E"
    L15_2[1] = L16_2
    L15_2[2] = L17_2
    L15_2[3] = L18_2
    L15_2[4] = L19_2
    L16_2 = PlayMusic
    L17_2 = {}
    L18_2 = A0_2
    L17_2[1] = L18_2
    L12_2(L13_2, L14_2, L15_2, L16_2, L17_2)
  end
  L8_2 = A0_2
  L7_2 = A0_2._CreateEvent
  L9_2 = Event
  L9_2 = L9_2.ObjectProximity
  L10_2 = {}
  L11_2 = uPiranha
  L12_2 = Pg
  L12_2 = L12_2.GetGuidByName
  L13_2 = "loc_StartOCBoats"
  L12_2 = L12_2(L13_2)
  L13_2 = "<"
  L14_2 = 140
  L15_2 = false
  L16_2 = false
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L10_2[5] = L15_2
  L10_2[6] = L16_2
  L11_2 = StartPursuit
  L12_2 = {}
  L13_2 = A0_2
  L14_2 = nPurLevel
  L12_2[1] = L13_2
  L12_2[2] = L14_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Object
  L1_2 = L1_2.IsPlayerControlled
  L2_2 = uPiranha
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = MrxTutorialManager
    L1_2 = L1_2.BeginCustomTutorial
    L2_2 = "GurCon003"
    L1_2(L2_2)
    L1_2 = MrxTutorialManager
    L1_2 = L1_2.ShowMessage
    L2_2 = "[GurCon003.Terms.buttontray]"
    L3_2 = false
    L4_2 = "GurCon003"
    L1_2(L2_2, L3_2, L4_2)
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = 9
    L4_2[1] = L5_2
    L5_2 = TutorialCancel
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  end
end

SecondTute = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = bClientwasIn
  if L1_2 then
    L1_2 = 2
    nBonusMP = L1_2
  else
    L1_2 = 1
    nBonusMP = L1_2
  end
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Piranha bonus"
  L3_2.sModuleName = "MrxTaskObjective"
  L3_2.bOptional = true
  L3_2.bDspMsg = false
  L3_2.bDspDescPda = true
  L3_2.bDspBlp = false
  L3_2.sDspShortDesc = "[GurCon003.Objectives.003]"
  L1_2 = L1_2(L2_2, L3_2)
  oBoatHealthBonus = L1_2
  L1_2 = ipairs
  L2_2 = tPiranha
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L7_2 = A0_2
    L6_2 = A0_2._CreateEvent
    L8_2 = Event
    L8_2 = L8_2.ObjectHealthLessThan
    L9_2 = {}
    L10_2 = L5_2
    L11_2 = 49
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L10_2 = CheckBoats
    L11_2 = {}
    L12_2 = A0_2
    L11_2[1] = L12_2
    L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
    uBonusEvent = L6_2
  end
end

_SetupBonusObjective = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = nBonusMP
  L1_2 = L1_2 - 1
  nBonusMP = L1_2
  L1_2 = nBonusMP
  if L1_2 == 0 then
    L1_2 = MrxVoSequence
    L1_2 = L1_2.Start
    L2_2 = {}
    L3_2 = "Fiona-In-Mission-MinorContract-Gur03-19"
    L2_2[1] = L3_2
    L1_2(L2_2)
    L1_2 = oBoatHealthBonus
    L2_2 = L1_2
    L1_2 = L1_2.Cancel
    L1_2(L2_2)
  end
end

CheckBoats = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.GetNumCompletions
  L1_2 = L1_2(L2_2)
  if L1_2 == 0 then
    L2_2 = oRaceObj
    L2_2.nAddTime = 12
    L2_2 = oRaceObj
    L2_2.fWidth = 18
  elseif L1_2 == 1 then
    L2_2 = oRaceObj
    L2_2.nAddTime = 9
    L2_2 = oRaceObj
    L2_2.fWidth = 14
  elseif 2 <= L1_2 then
    L2_2 = oRaceObj
    L2_2.nAddTime = 8
    L2_2 = oRaceObj
    L2_2.fWidth = 10
  end
end

SetTime = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = bMusicStarted
  if L1_2 == false then
    L1_2 = MrxMusic
    L1_2 = L1_2.PlaySpecialMusic
    L2_2 = "mu_fac_gr_kickass_01"
    L1_2(L2_2)
    L1_2 = true
    bMusicStarted = L1_2
  end
end

PlayMusic = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "GurCon003_deliv_2"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L2_2(L3_2)
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L4_2 = Object
  L4_2 = L4_2.GetYaw
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "GurCon003_deliv_2"
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L5_2(L6_2)
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L5_2 = Pg
  L5_2 = L5_2.Spawn
  L6_2 = "Piranha"
  L7_2 = L1_2
  L8_2 = L2_2
  L9_2 = L3_2
  L10_2 = L4_2
  L11_2 = true
  L12_2 = true
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  uPiranhaB = L5_2
  L5_2 = table
  L5_2 = L5_2.insert
  L6_2 = tPiranha
  L7_2 = uPiranhaB
  L5_2(L6_2, L7_2)
  L5_2 = true
  bClientwasIn = L5_2
end

SetupMPGame = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = eSteppedOut
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eSteppedOut
    L1_2(L2_2)
  end
  L1_2 = eTutorialExit
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eTutorialExit
    L1_2(L2_2)
  end
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.EndCustomTutorial
  L2_2 = "GurCon003"
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectInSeat
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = uPiranha
  L7_2 = "d"
  L8_2 = "ei"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = StartTutorial
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

CreateTutorialTrigger = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = SetupJumpTutorial
  L4_2 = A0_2
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = 0.5
  L6_2[1] = L7_2
  L7_2 = SetupTutorialTray
  L8_2 = {}
  L9_2 = A0_2
  L10_2 = A1_2
  L11_2 = A2_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  L3_2 = nTutePlayed
  if L3_2 == 0 then
    L3_2 = MrxVoSequence
    L3_2 = L3_2.Start
    L4_2 = {}
    L5_2 = "Fiona-In-Mission-Contract-Gur03-02"
    L4_2[1] = L5_2
    L3_2(L4_2)
    L3_2 = 1
    nTutePlayed = L3_2
  end
end

StartTutorial = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = A2_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L4_2 = Object
    L4_2 = L4_2.IsPlayerControlled
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    L6_2 = A0_2
    L5_2 = A0_2._CreateEvent
    L7_2 = Event
    L7_2 = L7_2.Button
    L8_2 = {}
    L9_2 = L4_2
    L10_2 = "lbutton"
    L11_2 = "press"
    L12_2 = true
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L8_2[4] = L12_2
    L9_2 = TutorialCancel
    L10_2 = {}
    L11_2 = A0_2
    L10_2[1] = L11_2
    L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
    eTutorialEnd = L5_2
    L6_2 = A0_2
    L5_2 = A0_2._CreateEvent
    L7_2 = Event
    L7_2 = L7_2.ObjectInSeat
    L8_2 = {}
    L9_2 = L3_2
    L10_2 = A2_2
    L11_2 = "d"
    L12_2 = "xo"
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L8_2[4] = L12_2
    L9_2 = CreateTutorialTrigger
    L10_2 = {}
    L11_2 = A0_2
    L10_2[1] = L11_2
    L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
    eTutorialExit = L5_2
  else
    L4_2 = Event
    L4_2 = L4_2.Delete
    L5_2 = eTutorialEnd
    L4_2(L5_2)
    L5_2 = A0_2
    L4_2 = A0_2._CreateEvent
    L6_2 = Event
    L6_2 = L6_2.ObjectInSeat
    L7_2 = {}
    L8_2 = Player
    L8_2 = L8_2.GetAnyCharacter
    L8_2 = L8_2()
    L9_2 = A2_2
    L10_2 = "d"
    L11_2 = "ei"
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L7_2[4] = L11_2
    L8_2 = SetupJumpTutorial
    L9_2 = {}
    L10_2 = A0_2
    L11_2 = true
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
    eSteppedOut = L4_2
  end
end

SetupJumpTutorial = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = A2_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L4_2 = Object
    L4_2 = L4_2.IsPlayerControlled
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    L5_2 = MrxTutorialManager
    L5_2 = L5_2.BeginCustomTutorial
    L6_2 = "GurCon003"
    L5_2(L6_2)
    L5_2 = MrxTutorialManager
    L5_2 = L5_2.ShowMessage
    L6_2 = "[GurCon003.Terms.buttontray]"
    L7_2 = false
    L8_2 = "GurCon003"
    L5_2(L6_2, L7_2, L8_2)
  end
end

SetupTutorialTray = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.EndCustomTutorial
  L2_2 = "GurCon003"
  L1_2(L2_2)
  L1_2 = eSteppedOut
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eSteppedOut
    L1_2(L2_2)
  end
  L1_2 = eTutorialExit
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eTutorialExit
    L1_2(L2_2)
  end
end

TutorialCancel = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[GurCon003.Terms.Cancel01]"
  L1_2(L2_2, L3_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-MinorContract-Gur03-12"
  L2_2[1] = L3_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 3
  L4_2[1] = L5_2
  L5_2 = A0_2.Cancel
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

BoatDestroyed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[GurCon003.Terms.Cancel03]"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.Cancel
  L1_2(L2_2)
end

ContactKilled = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  if A1_2 == 1 then
    L2_2 = {}
    L3_2 = {}
    L4_2 = "Driving"
    L5_2 = {}
    L6_2 = {}
    L7_2 = "Car"
    L8_2 = "EXT (GL) (DriverGunner)"
    L9_2 = 1
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L5_2[1] = L6_2
    L6_2 = {}
    L7_2 = {}
    L8_2 = "Car"
    L9_2 = 3
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L6_2[1] = L7_2
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L4_2 = {}
    L5_2 = "Stopped"
    L6_2 = {}
    L7_2 = {}
    L8_2 = "Car"
    L9_2 = "EXT (GL) (DriverGunner)"
    L10_2 = 1
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L6_2[1] = L7_2
    L7_2 = {}
    L8_2 = {}
    L9_2 = "Car"
    L10_2 = 3
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L7_2[1] = L8_2
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L4_2[3] = L7_2
    L5_2 = {}
    L6_2 = "Offroad"
    L7_2 = {}
    L8_2 = {}
    L9_2 = "Car"
    L10_2 = "EXT (GL) (DriverGunner)"
    L11_2 = 1
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L7_2[1] = L8_2
    L8_2 = {}
    L9_2 = {}
    L10_2 = "Car"
    L11_2 = 2
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L8_2[1] = L9_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L6_2 = {}
    L7_2 = "Boat"
    L8_2 = {}
    L9_2 = {}
    L10_2 = "Boat"
    L11_2 = "Omen (OC) (DriverGunner)"
    L12_2 = 1
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L10_2 = {}
    L11_2 = "Boat"
    L12_2 = "Turbosquid (OC) (Full)"
    L13_2 = 2
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L10_2[3] = L13_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L9_2 = {}
    L10_2 = {}
    L11_2 = "Boat"
    L12_2 = 5
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L9_2[1] = L10_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
    L2_2[4] = L6_2
    L3_2 = MrxFactionManager
    L3_2 = L3_2.SetCustomPursuit
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "OC"
    L4_2 = L4_2(L5_2)
    L5_2 = -1
    L6_2 = L2_2
    L3_2(L4_2, L5_2, L6_2)
  elseif A1_2 == 2 then
    L2_2 = {}
    L3_2 = {}
    L4_2 = "Driving"
    L5_2 = {}
    L6_2 = {}
    L7_2 = "Car"
    L8_2 = "EXT (GL) (DriverGunner)"
    L9_2 = 1
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L5_2[1] = L6_2
    L6_2 = {}
    L7_2 = {}
    L8_2 = "Car"
    L9_2 = 3
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L6_2[1] = L7_2
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L4_2 = {}
    L5_2 = "Stopped"
    L6_2 = {}
    L7_2 = {}
    L8_2 = "Car"
    L9_2 = "EXT (GL) (DriverGunner)"
    L10_2 = 1
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L6_2[1] = L7_2
    L7_2 = {}
    L8_2 = {}
    L9_2 = "Car"
    L10_2 = 3
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L7_2[1] = L8_2
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L4_2[3] = L7_2
    L5_2 = {}
    L6_2 = "Offroad"
    L7_2 = {}
    L8_2 = {}
    L9_2 = "Car"
    L10_2 = "EXT (GL) (DriverGunner)"
    L11_2 = 1
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L7_2[1] = L8_2
    L8_2 = {}
    L9_2 = {}
    L10_2 = "Car"
    L11_2 = 2
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L8_2[1] = L9_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L6_2 = {}
    L7_2 = "Boat"
    L8_2 = {}
    L9_2 = {}
    L10_2 = "Boat"
    L11_2 = "Omen (OC) (DriverGunner)"
    L12_2 = 1
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L10_2 = {}
    L11_2 = "Boat"
    L12_2 = "Turbosquid (OC) (Full)"
    L13_2 = 1
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L10_2[3] = L13_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L9_2 = {}
    L10_2 = {}
    L11_2 = "Boat"
    L12_2 = 6
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L9_2[1] = L10_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
    L2_2[4] = L6_2
    L3_2 = MrxFactionManager
    L3_2 = L3_2.SetCustomPursuit
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "OC"
    L4_2 = L4_2(L5_2)
    L5_2 = -1
    L6_2 = L2_2
    L3_2(L4_2, L5_2, L6_2)
  elseif A1_2 == 3 then
    L2_2 = {}
    L3_2 = {}
    L4_2 = "Driving"
    L5_2 = {}
    L6_2 = {}
    L7_2 = "Car"
    L8_2 = "EXT (GL) (DriverGunner)"
    L9_2 = 1
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L5_2[1] = L6_2
    L6_2 = {}
    L7_2 = {}
    L8_2 = "Car"
    L9_2 = 1
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L6_2[1] = L7_2
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L4_2 = {}
    L5_2 = "Stopped"
    L6_2 = {}
    L7_2 = {}
    L8_2 = "Car"
    L9_2 = "EXT (GL) (DriverGunner)"
    L10_2 = 1
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L6_2[1] = L7_2
    L7_2 = {}
    L8_2 = {}
    L9_2 = "Car"
    L10_2 = 1
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L7_2[1] = L8_2
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L4_2[3] = L7_2
    L5_2 = {}
    L6_2 = "Offroad"
    L7_2 = {}
    L8_2 = {}
    L9_2 = "Car"
    L10_2 = "EXT (GL) (DriverGunner)"
    L11_2 = 1
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L7_2[1] = L8_2
    L8_2 = {}
    L9_2 = {}
    L10_2 = "Car"
    L11_2 = 1
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L8_2[1] = L9_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L6_2 = {}
    L7_2 = "Boat"
    L8_2 = {}
    L9_2 = {}
    L10_2 = "Heli"
    L11_2 = "Coanda Gunship (Driver)"
    L12_2 = 1
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L8_2[1] = L9_2
    L9_2 = {}
    L10_2 = {}
    L11_2 = "Heli"
    L12_2 = 2
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L9_2[1] = L10_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L7_2 = {}
    L8_2 = "Boat"
    L9_2 = {}
    L10_2 = {}
    L11_2 = "Boat"
    L12_2 = "Omen (OC) (DriverGunner)"
    L13_2 = 1
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L10_2[3] = L13_2
    L11_2 = {}
    L12_2 = "Boat"
    L13_2 = "Turbosquid (OC) (Full)"
    L14_2 = 1
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L11_2[3] = L14_2
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L10_2 = {}
    L11_2 = {}
    L12_2 = "Boat"
    L13_2 = 6
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L10_2[1] = L11_2
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
    L2_2[4] = L6_2
    L2_2[5] = L7_2
    L3_2 = MrxFactionManager
    L3_2 = L3_2.SetCustomPursuit
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "OC"
    L4_2 = L4_2(L5_2)
    L5_2 = -1
    L6_2 = L2_2
    L3_2(L4_2, L5_2, L6_2)
  end
end

StartPursuit = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = MrxFactionManager
  L1_2 = L1_2.ClearCustomPursuit
  L1_2()
end

EndPursuit = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-MinorContract-Gur03-17"
  L4_2 = "Fiona-In-Mission-MinorContract-Gur03-16"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
end

MineTalk = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "BoatBlock_"
  L4_2 = A1_2
  L3_2 = L3_2 .. L4_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = Vehicle
    L3_2 = L3_2.GetDriver
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    L4_2 = Object
    L4_2 = L4_2.IsAlive
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      L4_2 = Ai
      L4_2 = L4_2.Goal
      L5_2 = {}
      L5_2.AIGuid = L3_2
      L5_2.Goal = "PathMove"
      L6_2 = Pg
      L6_2 = L6_2.GetGuidByName
      L7_2 = "Pa_BoatBlock_3"
      L6_2 = L6_2(L7_2)
      L5_2.Target = L6_2
      L5_2.Start = "Nearest"
      L5_2.Priority = "hiPri"
      L5_2.Mode = "Bounce"
      L6_2 = RiverMovers
      L5_2.Callback = L6_2
      L6_2 = {}
      L7_2 = A0_2
      L8_2 = A1_2
      L6_2[1] = L7_2
      L6_2[2] = L8_2
      L5_2.CallbackData = L6_2
      L4_2(L5_2)
    end
  end
end

RiverMovers = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = Vehicle
  L2_2 = L2_2.GetDriver
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "Finder_"
  L5_2 = A1_2
  L4_2 = L4_2 .. L5_2
  L3_2, L4_2, L5_2, L6_2, L7_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = Object
  L3_2 = L3_2.IsAlive
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    if A1_2 == 4 then
      A1_2 = 1
    end
    L3_2 = Ai
    L3_2 = L3_2.Goal
    L4_2 = {}
    L4_2.AIGuid = L2_2
    L4_2.Goal = "PathMove"
    L5_2 = Pg
    L5_2 = L5_2.GetGuidByName
    L6_2 = "Pa_Finder_"
    L7_2 = A1_2
    L6_2 = L6_2 .. L7_2
    L5_2 = L5_2(L6_2)
    L4_2.Target = L5_2
    L4_2.Start = "Nearest"
    L4_2.Priority = "hiPri"
    L5_2 = FinderMovers
    L4_2.Callback = L5_2
    L5_2 = {}
    L6_2 = A0_2
    L7_2 = A1_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L4_2.CallbackData = L5_2
    L3_2(L4_2)
    L3_2 = Ai
    L3_2 = L3_2.SetHaste
    L4_2 = L2_2
    L5_2 = 1
    L3_2(L4_2, L5_2)
  end
end

FinderMovers = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Object
  L1_2 = L1_2.Remove
  L2_2 = uPiranha
  L1_2(L2_2)
  L1_2 = bClientwasIn
  if L1_2 then
    L1_2 = Object
    L1_2 = L1_2.Remove
    L2_2 = uPiranhaB
    L1_2(L2_2)
  end
  L1_2 = MrxMusic
  L1_2 = L1_2.StopSpecialMusic
  L2_2 = "none"
  L1_2(L2_2)
  L1_2 = {}
  L2_2 = "vz_state_car_city_act1"
  L3_2 = "vz_state_mar_city_act1"
  L4_2 = "vz_state_staging_pirhq"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  tLayersForAddition = L1_2
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Add
  L2_2 = tLayersForAddition
  L1_2(L2_2)
  L1_2 = MrxFactionManager
  L1_2 = L1_2.ClearCustomPursuit
  L1_2()
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
