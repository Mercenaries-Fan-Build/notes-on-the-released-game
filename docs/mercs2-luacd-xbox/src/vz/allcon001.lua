local L0_1, L1_1
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = MrxLayerManager
  L2_2 = L2_2.Remove
  L3_2 = {}
  L4_2 = "vz_state_Margarita_precrash"
  L3_2[1] = L4_2
  
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = {}
    L1_3 = "Vz_State_AllCon001"
    L2_3 = "vz_State_Margarita_crash"
    L3_3 = "vz_State_AllCon001_pristine"
    L0_3[1] = L1_3
    L0_3[2] = L2_3
    L0_3[3] = L3_3
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
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = 0
  nVipSaved = L1_2
  L1_2 = 3
  nPlaneParts = L1_2
  L1_2 = 0
  uFoundVIP2 = L1_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = ObjectivePlane1
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = ObjectiveTalkToVIP1
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = ObjectiveTalkToVIP2
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "reg_MargaritaChinaFactionZone"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = TalkAboutVIP1
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
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
  L7_2 = "Civ_VIP_2"
  L6_2 = L6_2(L7_2)
  L7_2 = "<"
  L8_2 = 20
  L9_2 = false
  L10_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L5_2 = ShowVIP2
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  uVIP2Event = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "patrolBoat_west2"
  L5_2 = L5_2(L6_2)
  L6_2 = "awake"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = BoatPatrol
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = "patrolBoat_west2"
  L9_2 = "Pa_patrolBoat1"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "patrolBoat_2"
  L5_2 = L5_2(L6_2)
  L6_2 = "awake"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = BoatPatrol
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = "patrolBoat_2"
  L9_2 = "Pa_BoatPatrol2"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "patrolBoat_3"
  L5_2 = L5_2(L6_2)
  L6_2 = "awake"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = BoatPatrol
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = "patrolBoat_3"
  L9_2 = "Pa_BoatPatrol2"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "patrolBoat_4"
  L5_2 = L5_2(L6_2)
  L6_2 = "awake"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = BoatPatrol
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = "patrolBoat_4"
  L9_2 = "Pa_BoatPatrol_4"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Ai
  L1_2 = L1_2.SetRelation
  L2_2 = GetGuidByName
  L3_2 = "China"
  L2_2 = L2_2(L3_2)
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "Civ_VIP_1"
  L3_2 = L3_2(L4_2)
  L4_2 = 100
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Ai
  L1_2 = L1_2.SetRelation
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "Civ_VIP_1"
  L2_2 = L2_2(L3_2)
  L3_2 = GetGuidByName
  L4_2 = "China"
  L3_2 = L3_2(L4_2)
  L4_2 = 100
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = 1
  L2_2 = 4
  L3_2 = 1
  for L4_2 = L1_2, L2_2, L3_2 do
    L5_2 = Ai
    L5_2 = L5_2.SetRelation
    L6_2 = GetGuidByName
    L7_2 = "China"
    L6_2 = L6_2(L7_2)
    L7_2 = Pg
    L7_2 = L7_2.GetGuidByName
    L8_2 = "jail_11_"
    L9_2 = L4_2
    L8_2 = L8_2 .. L9_2
    L7_2 = L7_2(L8_2)
    L8_2 = 100
    L5_2(L6_2, L7_2, L8_2)
    L5_2 = Ai
    L5_2 = L5_2.SetRelation
    L6_2 = Pg
    L6_2 = L6_2.GetGuidByName
    L7_2 = "jail_11_"
    L8_2 = L4_2
    L7_2 = L7_2 .. L8_2
    L6_2 = L6_2(L7_2)
    L7_2 = GetGuidByName
    L8_2 = "China"
    L7_2 = L7_2(L8_2)
    L8_2 = 100
    L5_2(L6_2, L7_2, L8_2)
  end
end

RelationSetup = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = A1_2
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L4_2(L5_2)
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = A2_2
  L4_2 = L4_2(L5_2)
  if L3_2 then
    L5_2 = {}
    L5_2.AIGuid = L3_2
    L5_2.Goal = "PathMove"
    L5_2.Target = L4_2
    L5_2.Start = "Nearest"
    L5_2.Priority = "medPri"
    L5_2.Mode = "Bounce"
    L7_2 = A0_2
    L6_2 = A0_2._CreateEvent
    L8_2 = Event
    L8_2 = L8_2.TimerRelative
    L9_2 = {}
    L10_2 = 1
    L9_2[1] = L10_2
    L10_2 = Ai
    L10_2 = L10_2.Goal
    L11_2 = {}
    L12_2 = L5_2
    L11_2[1] = L12_2
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  end
end

BoatPatrol = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = {}
  L2_2 = "Fiona-In-Mission-Contract-All02-42"
  L3_2 = {}
  L3_2.mattias = "Mattias-In-Mission-Contract-All02-43"
  L3_2.jennifer = "Jennifer-In-Mission-Contract-All02-44"
  L3_2.chris = "Chris-In-Mission-Contract-All02-45"
  L4_2 = "Fiona-In-Mission-Contract-All01-40"
  L5_2 = "Fiona-In-Mission-Contract-All01-45"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  tInitialVOTable = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Destroy the plane's nose"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = tInitialVOTable
  L3_2.vVoSeqOnAdd = L4_2
  L4_2 = {}
  L5_2 = "ruinsplane_front_AllCon1"
  L6_2 = "ruinsplane_mid_AllCon1"
  L7_2 = "ruinsplane_back_AllCon1"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[AllCon001.Objectives.001]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = PartDestroyed
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnPartComplete = L4_2
  
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = nVipSaved
    if 0 < L0_3 then
      L0_3 = nVipSaved
      L0_3 = L0_3 * 3000000
      L1_3 = Net
      L1_3 = L1_3.IsActive
      L1_3 = L1_3()
      if L1_3 then
        L1_3 = A0_2
        L2_3 = L1_3
        L1_3 = L1_3._SetPlayer1Bonus
        L3_3 = L0_3
        L1_3(L2_3, L3_3)
        L1_3 = A0_2
        L2_3 = L1_3
        L1_3 = L1_3._SetPlayer2Bonus
        L3_3 = L0_3
        L1_3(L2_3, L3_3)
      else
        L1_3 = A0_2
        L2_3 = L1_3
        L1_3 = L1_3._SetPlayer1Bonus
        L3_3 = L0_3
        L1_3(L2_3, L3_3)
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
  
  L3_2.fOnComplete = L4_2
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
  oPlaneNose = L1_2
end

ObjectivePlane1 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = nPlaneParts
  L1_2 = L1_2 - 1
  nPlaneParts = L1_2
  L1_2 = nPlaneParts
  if L1_2 == 2 then
    L1_2 = MrxVoSequence
    L1_2 = L1_2.Start
    L2_2 = {}
    L3_2 = "Fiona-In-Mission-Contract-All01-22"
    L4_2 = "Fiona-In-Mission-Contract-All01-23"
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L1_2(L2_2)
  else
    L1_2 = nPlaneParts
    if L1_2 == 1 then
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = "Fiona-In-Mission-Contract-All01-24"
      L4_2 = "Fiona-In-Mission-Contract-All01-25"
      L2_2[1] = L3_2
      L2_2[2] = L4_2
      L1_2(L2_2)
    else
      L1_2 = nPlaneParts
      if L1_2 == 0 then
        L1_2 = MrxVoSequence
        L1_2 = L1_2.Start
        L2_2 = {}
        L3_2 = "Fiona-In-Mission-Contract-All01-29"
        L4_2 = "Fiona-In-Mission-Contract-All01-27"
        L2_2[1] = L3_2
        L2_2[2] = L4_2
        L1_2(L2_2)
      end
    end
  end
end

PartDestroyed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = nPlaneParts
  if 1 < L1_2 then
    L1_2 = PlayThreatMusic
    L2_2 = A0_2
    L3_2 = 50
    L1_2(L2_2, L3_2)
  else
    L1_2 = nPlaneParts
    if L1_2 == 1 then
      L1_2 = MrxMusic
      L1_2 = L1_2.PlaySpecialMusic
      L2_2 = "mu_fac_an_kickass_01"
      L1_2(L2_2)
      L2_2 = A0_2
      L1_2 = A0_2._CreateEvent
      L3_2 = Event
      L3_2 = L3_2.TimerRelative
      L4_2 = {}
      L5_2 = 50
      L4_2[1] = L5_2
      L5_2 = MrxMusic
      L5_2 = L5_2.StopSpecialMusic
      L6_2 = {}
      L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
      L2_2 = A0_2
      L1_2 = A0_2._CreateEvent
      L3_2 = Event
      L3_2 = L3_2.TimerRelative
      L4_2 = {}
      L5_2 = 50.3
      L4_2[1] = L5_2
      L5_2 = PlayThreatMusic
      L6_2 = {}
      L7_2 = A0_2
      L8_2 = 20
      L6_2[1] = L7_2
      L6_2[2] = L8_2
      L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
    end
  end
end

PlayObjectiveMusic = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "MargaritaReached"
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2._SetFlag
    L3_2 = "MargaritaReached"
    L1_2(L2_2, L3_2)
    L1_2 = _Checkpoint
    L2_2 = {}
    L3_2 = "LocAll001ckpt1_p1"
    L4_2 = "LocAll001ckpt1_p2"
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L1_2(L2_2)
  end
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-All01-21"
  L4_2 = "Fiona-In-Mission-Contract-All01-48"
  L5_2 = {}
  L5_2.mattias = "mattias-In-Mission-Contract-All01-52"
  L5_2.jennifer = "jennifer-In-Mission-Contract-All01-53"
  L5_2.chris = "chris-In-Mission-Contract-All01-54"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L1_2(L2_2)
end

TalkAboutVIP1 = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = Sound
  L2_2 = L2_2.SetActionLevelsMusic
  L3_2 = 3
  L4_2 = 0
  L5_2 = 0
  L6_2 = 0
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L2_2 = Sound
  L2_2 = L2_2.LockActionLevelMusic
  L3_2 = true
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = A1_2
  L5_2[1] = L6_2
  L6_2 = Sound
  L6_2 = L6_2.LockActionLevelMusic
  L7_2 = {}
  L8_2 = false
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

PlayThreatMusic = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = oVIP1talk
  L2_2 = L1_2
  L1_2 = L1_2.Configure
  L3_2 = {}
  L3_2.bDsp = true
  L1_2(L2_2, L3_2)
end

ShowVIP1 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "TalktoVIP1"
  L3_2.sModuleName = "MrxTaskObjectiveRelease"
  L3_2.sActionLabel = "[ContextAction.ReleasePrisoner]"
  L3_2.vTgtInclude = "Civ_VIP_1"
  L3_2.bOptional = true
  L3_2.sDspShortDesc = "[AllCon001.Objectives.004]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = ObjectiveVIP1
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnPartComplete = L4_2
  
  function L4_2()
    local L0_3, L1_3, L2_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-All01-42"
    L1_3[1] = L2_3
    L0_3(L1_3)
  end
  
  L3_2.fOnCancel = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  oVIP1talk = L1_2
  L1_2 = 11
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAnyCharacter
  L6_2 = L6_2()
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "Civ_VIP_1"
  L7_2 = L7_2(L8_2)
  L8_2 = "<"
  L9_2 = 10
  L10_2 = false
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = MoveCivs
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = L1_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

ObjectiveTalkToVIP1 = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "Extract VIP 1"
  L4_2.sModuleName = "MrxTaskObjectiveExtract"
  L4_2.vTgtInclude = "Civ_VIP_1"
  L4_2.bOptional = true
  L4_2.sDspShortDesc = "[AllCon001.Objectives.007]"
  L4_2.uStartAttachedToPlayer = A1_2
  L4_2.bStop = false
  L4_2.bXZOnly = false
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = nVipSaved
    L0_3 = L0_3 + 1
    nVipSaved = L0_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-All01-37"
    L1_3[1] = L2_3
    L0_3(L1_3)
  end
  
  L4_2.fOnComplete = L5_2
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-All01-41"
    L1_3[1] = L2_3
    L0_3(L1_3)
  end
  
  L4_2.fOnCancel = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  oVIP1extract = L2_2
  L2_2 = VIP1givesInfo
  L3_2 = A0_2
  L2_2(L3_2)
end

ObjectiveVIP1 = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = 1
  L3_2 = 4
  L4_2 = 1
  for L5_2 = L2_2, L3_2, L4_2 do
    L6_2 = Pg
    L6_2 = L6_2.GetGuidByName
    L7_2 = "jail_"
    L8_2 = A1_2
    L9_2 = "_"
    L10_2 = L5_2
    L7_2 = L7_2 .. L8_2 .. L9_2 .. L10_2
    L6_2 = L6_2(L7_2)
    if L6_2 then
      L7_2 = Human
      L7_2 = L7_2.SetState
      L8_2 = L6_2
      L9_2 = "Cower"
      L10_2 = "Idle"
      L7_2(L8_2, L9_2, L10_2)
    end
  end
end

MoveCivs = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = uFoundVIP2
  if L1_2 == 0 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uVIP2Event
    L1_2(L2_2)
    L1_2 = MrxVoSequence
    L1_2 = L1_2.Start
    L2_2 = {}
    L3_2 = "AlliedSoldier-In-Mission-Contract-All01-08"
    L4_2 = 5
    L5_2 = "AlliedSoldier-In-Mission-Contract-All01-09"
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
    L1_2(L2_2)
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = 10
    L4_2[1] = L5_2
    L5_2 = ShowVIP2
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  end
end

VIP1givesInfo = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = 1
  uFoundVIP2 = L1_2
  L1_2 = oVIP2talk
  L2_2 = L1_2
  L1_2 = L1_2.Configure
  L3_2 = {}
  L3_2.bDsp = true
  L1_2(L2_2, L3_2)
end

ShowVIP2 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "TalktoVIP2"
  L3_2.sModuleName = "MrxTaskObjectiveRelease"
  L3_2.bOptional = true
  L3_2.sActionLabel = "[ContextAction.ReleasePrisoner]"
  L3_2.vTgtInclude = "Civ_VIP_2"
  L3_2.sDspShortDesc = "[AllCon001.Objectives.005]"
  L3_2.bDsp = false
  L4_2 = {}
  L5_2 = {}
  L6_2 = ObjectiveVIP2
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnPartComplete = L4_2
  
  function L4_2()
    local L0_3, L1_3, L2_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-All01-17"
    L1_3[1] = L2_3
    L0_3(L1_3)
  end
  
  L3_2.fOnCancel = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  oVIP2talk = L1_2
  L1_2 = 22
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAnyCharacter
  L6_2 = L6_2()
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "Civ_VIP_2"
  L7_2 = L7_2(L8_2)
  L8_2 = "<"
  L9_2 = 10
  L10_2 = false
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = MoveCivs
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = L1_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

ObjectiveTalkToVIP2 = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = MrxVoSequence
  L2_2 = L2_2.Start
  L3_2 = {}
  L4_2 = "AlliedSoldier-In-Mission-Contract-All01-11"
  L5_2 = "AlliedSoldier-In-Mission-Contract-All01-31"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "Extract VIP 2"
  L4_2.sModuleName = "MrxTaskObjectiveExtract"
  L4_2.vTgtInclude = "Civ_VIP_2"
  L4_2.sDspShortDesc = "[AllCon001.Objectives.006]"
  L4_2.uStartAttachedToPlayer = A1_2
  L4_2.bOptional = true
  L4_2.bStop = false
  L4_2.bXZOnly = false
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = nVipSaved
    L0_3 = L0_3 + 1
    nVipSaved = L0_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-All01-26"
    L1_3[1] = L2_3
    L0_3(L1_3)
  end
  
  L4_2.fOnComplete = L5_2
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-All01-17"
    L1_3[1] = L2_3
    L0_3(L1_3)
  end
  
  L4_2.fOnCancel = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  oVIP2extract = L2_2
end

ObjectiveVIP2 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
