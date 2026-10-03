local L0_1, L1_1, L2_1, L3_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = import
L1_1 = "DangerousBuilding"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxChiCon001Rescue"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxMusic"
L0_1(L1_1)
L0_1 = {}
L1_1 = "_cumana_bld_hotelfourstar01 0x000b87ed"
L2_1 = "_cumana_bld_hotelfourstar01 0x000b87ee"
L0_1[1] = L1_1
L0_1[2] = L2_1
tDB_Targets = L0_1
L0_1 = {}
L1_1 = "_cumana_bld_corner32x32B 0x001385a7"
L2_1 = "_city_bld_apartment02 0x000b894b"
L3_1 = "_city_bld_apartment01 0x000b894c"
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
tBldTargets = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = {}
  L3_2 = "vz_state_chicon001"
  L4_2 = "Vz_state_ChiCon001_Pristine"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = MrxLayerManager
  L3_2 = L3_2.Add
  L4_2 = L2_2
  L5_2 = A0_2.AssetsLoaded
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L3_2(L4_2, L5_2, L6_2)
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Remove
  L2_2 = {}
  L3_2 = "vz_state_cumana_act1ALL_N"
  L2_2[1] = L3_2
  L1_2(L2_2)
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Remove
  L2_2 = {}
  L3_2 = "vz_state_cumana_act1all_staging"
  L2_2[1] = L3_2
  L1_2(L2_2)
  L1_2 = 0
  BldgDeathCount = L1_2
  L1_2 = pairs
  L2_2 = tBldTargets
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Pg
    L6_2 = L6_2.GetGuidByName
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    L8_2 = A0_2
    L7_2 = A0_2._CreateEvent
    L9_2 = Event
    L9_2 = L9_2.ObjectDeath
    L10_2 = {}
    L11_2 = L6_2
    L10_2[1] = L11_2
    
    function L11_2()
      local L0_3, L1_3
      L0_3 = BldgDeathCount
      L0_3 = L0_3 + 1
      BldgDeathCount = L0_3
      L0_3 = BonusCompleteVO
      L1_3 = A0_2
      L0_3(L1_3)
    end
    
    L7_2(L8_2, L9_2, L10_2, L11_2)
  end
  L1_2 = FionaVo
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "PartyOfficial"
  L1_2 = L1_2(L2_2)
  uTarget = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Rescue_VIP"
  L3_2.sModuleName = "MrxTaskObjectiveRelease"
  L3_2.sActionLabel = "[ContextAction.RescuePrisoner]"
  L4_2 = uTarget
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[ChiCon001.Objectives.001]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = ReleaseTarget
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = uTarget
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnPartComplete = L4_2
  
  function L4_2()
    local L0_3, L1_3
    L0_3 = PrisonerUndelivered
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L3_2.fOnCancel = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  oActionObjectve = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = uTarget
  L4_2[1] = L5_2
  
  function L5_2()
    local L0_3, L1_3
    L0_3 = PrisonerUnrescued
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectHibernation
  L5_2 = {}
  L6_2 = uTarget
  L7_2 = "awake"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = SubdueTarget
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = uTarget
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.Boundary
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAnyCharacter
  L6_2 = L6_2()
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "LineRegion_Firefights"
  L7_2 = L7_2(L8_2)
  L8_2 = "enter"
  L9_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L6_2 = SetUpFirefights
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L6_2(L7_2)
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  L2_2 = Object
  L2_2 = L2_2.GetHealth
  L3_2 = uTarget
  L2_2 = L2_2(L3_2)
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectHealthLessThan
  L5_2 = {}
  L6_2 = uTarget
  L7_2 = L2_2 / 2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  
  function L6_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-Chi01-19"
    L3_3 = 0.5
    L4_3 = {}
    L4_3.mattias = "Mattias-In-Mission-Contract-Chi01-20"
    L4_3.jennifer = "Jennifer-In-Mission-Contract-Chi01-21"
    L4_3.chris = "Chris-In-Mission-Contract-Chi01-22"
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L1_3[3] = L4_3
    L0_3(L1_3)
  end
  
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  eChiVipDamage = L3_2
  L3_2 = MrxSupportData
  L3_2 = L3_2.AddFreebie
  L4_2 = "ChiCon001_RocketArtillery"
  L3_2(L4_2)
  L3_2 = DestroyAlliedBldgSetup
  L4_2 = A0_2
  L3_2(L4_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 3
  L4_2[1] = L5_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-Banter-Contract-Chi01-01"
    L3_3 = {}
    L3_3.mattias = "Mattias-Banter-Contract-Chi01-02"
    L3_3.jennifer = "Jennifer-Banter-Contract-Chi01-03"
    L3_3.chris = "Chris-Banter-Contract-Chi01-04"
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L0_3(L1_3)
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._CreateEvent
    L2_3 = Event
    L2_3 = L2_3.TimerRelative
    L3_3 = {}
    L4_3 = 10
    L3_3[1] = L4_3
    
    function L4_3()
      local L0_4, L1_4, L2_4, L3_4, L4_4, L5_4, L6_4, L7_4, L8_4
      L0_4 = MrxMusic
      L0_4 = L0_4.PlaySpecialMusic
      L1_4 = "mu_fac_ch_threat_01"
      L0_4(L1_4)
      L0_4 = MrxVoSequence
      L0_4 = L0_4.Start
      L1_4 = {}
      L2_4 = "Fiona-In-Mission-Contract-Chi01-07"
      L3_4 = 1
      L4_4 = "Fiona-In-Mission-Contract-Chi01-08"
      L5_4 = 1
      L6_4 = "Fiona-In-Mission-Contract-Chi01-09"
      L7_4 = 1
      L8_4 = "Fiona-In-Mission-Contract-Chi01-10"
      L1_4[1] = L2_4
      L1_4[2] = L3_4
      L1_4[3] = L4_4
      L1_4[4] = L5_4
      L1_4[5] = L6_4
      L1_4[6] = L7_4
      L1_4[7] = L8_4
      L0_4(L1_4)
    end
    
    L0_3(L1_3, L2_3, L3_3, L4_3)
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
  L7_2 = "_cumana_bld_corner32x32B 0x001385a7"
  L6_2 = L6_2(L7_2)
  L7_2 = "<"
  L8_2 = 100
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
    L2_3 = "Fiona-In-Mission-Contract-Chi01-03"
    L1_3[1] = L2_3
    L0_3(L1_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

FionaVo = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Ai
  L1_2 = L1_2.Goal
  L2_2 = {}
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "ChineseSkirmish2"
  L4_2, L5_2 = L4_2(L5_2)
  L3_2 = L3_2(L4_2, L5_2)
  L2_2.AIGuid = L3_2
  L2_2.Goal = "PathMove"
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "path_firefight2"
  L3_2 = L3_2(L4_2)
  L2_2.Target = L3_2
  L2_2.Priority = "lowPri"
  L2_2.Mode = "Oneway"
  L2_2.Start = "Nearest"
  L2_2.Haste = 1
  L1_2(L2_2)
  L1_2 = Ai
  L1_2 = L1_2.Goal
  L2_2 = {}
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "ChineseSkirmish3"
  L4_2, L5_2 = L4_2(L5_2)
  L3_2 = L3_2(L4_2, L5_2)
  L2_2.AIGuid = L3_2
  L2_2.Goal = "PathMove"
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "path_firefight3"
  L3_2 = L3_2(L4_2)
  L2_2.Target = L3_2
  L2_2.Priority = "lowPri"
  L2_2.Mode = "Oneway"
  L2_2.Start = "Nearest"
  L2_2.Haste = 1
  L1_2(L2_2)
  L1_2 = Ai
  L1_2 = L1_2.Goal
  L2_2 = {}
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "ChineseSkirmish4"
  L4_2, L5_2 = L4_2(L5_2)
  L3_2 = L3_2(L4_2, L5_2)
  L2_2.AIGuid = L3_2
  L2_2.Goal = "PathMove"
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "path_firefight4"
  L3_2 = L3_2(L4_2)
  L2_2.Target = L3_2
  L2_2.Priority = "lowPri"
  L2_2.Mode = "Oneway"
  L2_2.Start = "Nearest"
  L2_2.Haste = 1
  L1_2(L2_2)
end

SetUpFirefights = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = MrxVoSequence
  L2_2 = L2_2.Start
  L3_2 = {}
  L4_2 = "Fiona-In-Mission-Contract-Chi01-02"
  L3_2[1] = L4_2
  L2_2(L3_2)
  L2_2 = MrxUtil
  L2_2 = L2_2.DisplayHealthBar
  L3_2 = A0_2
  L4_2 = A1_2
  L5_2 = 0
  L6_2 = true
  L7_2 = 0
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

SubdueTarget = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = MrxMusic
  L3_2 = L3_2.PlaySpecialMusic
  L4_2 = "mu_fac_ch_kickass_01"
  L3_2(L4_2)
  L3_2 = Object
  L3_2 = L3_2.AddLabel
  L4_2 = A1_2
  L5_2 = "Prisoner"
  L3_2(L4_2, L5_2)
  L4_2 = A0_2
  L3_2 = A0_2.CreateChild
  L5_2 = {}
  L5_2.sName = "Deliver VIP"
  L5_2.sModuleName = "MrxTaskObjectiveDeliver"
  L5_2.vTgtInclude = A1_2
  L6_2 = Player
  L6_2 = L6_2.GetLocalCharacter
  L6_2 = L6_2()
  L5_2.uStartAttachedToPlayer = L6_2
  L5_2.sDspShortDesc = "[ChiCon001.Objectives.002]"
  L5_2.vDestLoc = "ChiCon001 Dropoff"
  L5_2.bHumansFollow = true
  L5_2.fDist = 6
  
  function L6_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-Chi01-06"
    L3_3 = 3
    L4_3 = {}
    L5_3 = A0_2
    L5_3 = L5_3.Complete
    L6_3 = {}
    L7_3 = A0_2
    L6_3[1] = L7_3
    L4_3[1] = L5_3
    L4_3[2] = L6_3
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L1_3[3] = L4_3
    L0_3(L1_3)
  end
  
  L5_2.fOnComplete = L6_2
  L6_2 = {}
  L7_2 = {}
  L8_2 = PrisonerUndelivered
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L6_2[1] = L7_2
  L5_2.tOnCancel = L6_2
  L3_2(L4_2, L5_2)
end

ReleaseTarget = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = Object
  L3_2 = L3_2.GetMaxHealth
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = Object
  L4_2 = L4_2.GetHealth
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  L5_2 = math
  L5_2 = L5_2.floor
  L6_2 = L4_2 / L3_2
  L6_2 = L6_2 * 100
  L5_2 = L5_2(L6_2)
  L6_2 = "[green]"
  L7_2 = MrxUtil
  L7_2 = L7_2.DisplayHealthBar
  L8_2 = A0_2
  L9_2 = uTarget
  L10_2 = 0
  L11_2 = true
  L12_2 = 0
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
end

DisplayLifeBar = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Bonus Objective: Destroy the Allied Buildings"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = tBldTargets
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[ChiCon001.Objectives.003]"
  L3_2.bOptional = true
  L4_2 = {}
  L5_2 = {}
  L6_2 = BonusComplete
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  L1_2(L2_2, L3_2)
end

DestroyAlliedBldgSetup = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = BldgDeathCount
  if L1_2 == 1 then
    L1_2 = MrxVoSequence
    L1_2 = L1_2.Start
    L2_2 = {}
    L3_2 = "Fiona-In-Mission-Contract-Chi01-12"
    L2_2[1] = L3_2
    L1_2(L2_2)
  else
    L1_2 = BldgDeathCount
    if L1_2 == 2 then
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = "Fiona-In-Mission-Contract-Chi01-13"
      L2_2[1] = L3_2
      L1_2(L2_2)
    else
      L1_2 = BldgDeathCount
      if L1_2 == 3 then
        L1_2 = MrxVoSequence
        L1_2 = L1_2.Start
        L2_2 = {}
        L3_2 = "Fiona-In-Mission-Contract-Chi01-14"
        L2_2[1] = L3_2
        L1_2(L2_2)
      end
    end
  end
end

BonusCompleteVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Chi01-15"
  L2_2[1] = L3_2
  L1_2(L2_2)
  L1_2 = Player
  L1_2 = L1_2.GetCurrentPlayers
  L1_2 = L1_2()
  if L1_2 == 2 then
    L3_2 = A0_2
    L2_2 = A0_2._SetPlayer1Bonus
    L4_2 = 50000
    L2_2(L3_2, L4_2)
    L3_2 = A0_2
    L2_2 = A0_2._SetPlayer2Bonus
    L4_2 = 50000
    L2_2(L3_2, L4_2)
  else
    L3_2 = A0_2
    L2_2 = A0_2._SetPlayer1Bonus
    L4_2 = 50000
    L2_2(L3_2, L4_2)
  end
end

BonusComplete = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = A2_2
  L4_2 = L4_2(L5_2)
  L5_2 = Object
  L5_2 = L5_2.GetPosition
  L6_2 = L4_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L8_2 = Pg
  L8_2 = L8_2.Spawn
  L9_2 = A1_2
  L10_2 = L5_2
  L11_2 = L6_2
  L12_2 = L7_2
  L13_2 = Object
  L13_2 = L13_2.GetYaw
  L14_2 = L4_2
  L13_2 = L13_2(L14_2)
  L14_2 = false
  L15_2 = true
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  L9_2 = Event
  L9_2 = L9_2.Create
  L10_2 = Event
  L10_2 = L10_2.ObjectHibernation
  L11_2 = {}
  L12_2 = L8_2
  L13_2 = "awake"
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L12_2 = ReinforcementPatrol
  L13_2 = {}
  L14_2 = A0_2
  L15_2 = L8_2
  L16_2 = A3_2
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L13_2[3] = L16_2
  L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2)
end

SpawnPatrols = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = Ai
  L3_2 = L3_2.Goal
  L4_2 = {}
  L5_2 = Vehicle
  L5_2 = L5_2.GetDriver
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = A1_2
  L6_2, L7_2 = L6_2(L7_2)
  L5_2 = L5_2(L6_2, L7_2)
  L4_2.AIGuid = L5_2
  L4_2.Goal = "PathMove"
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = A2_2
  L5_2 = L5_2(L6_2)
  L4_2.Target = L5_2
  L4_2.Priority = "lowPri"
  L4_2.Mode = "Oneway"
  L4_2.Start = "Nearest"
  L4_2.Haste = 0.1
  L3_2(L4_2)
end

ReinforcementPatrol = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[ChiCon001.Terms.Cancel01]"
  L1_2(L2_2, L3_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Chi01-17"
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

PrisonerUnrescued = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[ChiCon001.Terms.Cancel02]"
  L1_2(L2_2, L3_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Chi01-18"
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

PrisonerUndelivered = L0_1

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
  L1_2 = MrxSupportData
  L1_2 = L1_2.RemoveFreebie
  L2_2 = "ChiCon001_RocketArtillery"
  L1_2(L2_2)
  L1_2 = MrxLayerManager
  L1_2 = L1_2.MarkForRemoval
  L2_2 = "vz_state_chicon001"
  L3_2 = "Vz_state_ChiCon001_Pristine"
  L1_2(L2_2, L3_2)
  L1_2 = MrxMusic
  L1_2 = L1_2.StopSpecialMusic
  L1_2()
  L1_2 = MrxUtil
  L1_2 = L1_2.StopHealthBar
  L2_2 = uTarget
  L1_2(L2_2)
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
