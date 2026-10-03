local L0_1, L1_1
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
L1_1 = "MrxLayerManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTimer"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxMusic"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxclusterbomb"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxfuelairbomb"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxcratedelivery"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxtankbuster"
L0_1(L1_1)
L0_1 = false
DEMO = L0_1
L0_1 = nil
oCivCasualtyObjective = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = {}
  L3_2 = "vz_state_gurcon002"
  L4_2 = "vz_state_gurcon002_pristine"
  L5_2 = "Vz_state_temp_staging_GurCon002"
  L6_2 = "vz_state_merida_act1"
  L7_2 = "vz_state_gurcon002_traffic"
  L8_2 = "vz_State_GurCon002_TG"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L2_2[6] = L8_2
  L3_2 = MrxLayerManager
  L3_2 = L3_2.Remove
  L4_2 = {}
  L5_2 = "vz_state_merida_act1_helo"
  L4_2[1] = L5_2
  L3_2(L4_2)
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
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetLocalCharacter
  L5_2 = L5_2()
  L6_2 = "awake"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = Start
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = SetupDangerousBuildings
  L1_2()
  L1_2 = {}
  tTankObjs = L1_2
  L1_2 = 1
  TankNum = L1_2
  L1_2 = 1
  DamageOnHibernate = L1_2
  L1_2 = 0
  ChurchLifeVO50 = L1_2
  L1_2 = 0
  ChurchLifeVO15 = L1_2
  L1_2 = 0
  BuildingsDestroyed = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "_merida_bld_plazachurch 0"
  L1_2 = L1_2(L2_2)
  uChurchGuid = L1_2
  L1_2 = nil
  uBonusEvent = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "ChurchDefended"
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.KillCaptain
    L1_2(L2_2)
  else
    L2_2 = A0_2
    L1_2 = A0_2._GetFlag
    L3_2 = "AllBuildingsDestroyed"
    L1_2 = L1_2(L2_2, L3_2)
    if L1_2 then
      L2_2 = A0_2
      L1_2 = A0_2.MoveToChurch
      L1_2(L2_2)
    else
      L1_2 = 0
      BuildingsDestroyed = L1_2
      L1_2 = _SetupVO
      L2_2 = A0_2
      L1_2(L2_2)
      L1_2 = SetupDestroyObjective
      L2_2 = A0_2
      L1_2(L2_2)
    end
  end
end

Start = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = SetupDangerousObjBuildings
  L1_2()
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "DestroyBuildings"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = {}
  L5_2 = "CommercialBuildingGurcon002"
  L6_2 = "ResidentialBuildingGurcon002"
  L7_2 = "ProjectsBuildingGurcon002"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[GurCon002.Objectives.001]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.CheckCompletion
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = BuildingDestroyedVO
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnPartComplete = L4_2
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
  L4_2 = {}
  L5_2 = "Fiona-Banter-Contract-Gur002-01"
  L6_2 = 1
  L7_2 = {}
  L7_2.mattias = "Mattias-Banter-Contract-Gur002-02"
  L7_2.jennifer = "Jennifer-Banter-Contract-Gur002-03"
  L7_2.chris = "Chris-Banter-Contract-Gur002-04"
  L8_2 = 1
  L9_2 = "Fiona-In-Mission-Contract-Gur002-11"
  L10_2 = 1
  L11_2 = "Fiona-In-Mission-Contract-Gur002-12"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L4_2[7] = L11_2
  L3_2.vVoSeqOnAdd = L4_2
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "BonusFailed"
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2._SetPlayer1Bonus
    L3_2 = 0
    L1_2(L2_2, L3_2)
    L2_2 = A0_2
    L1_2 = A0_2._SetPlayer2Bonus
    L3_2 = 0
    L1_2(L2_2, L3_2)
  else
    L2_2 = A0_2
    L1_2 = A0_2._SetPlayer1Bonus
    L3_2 = 500000
    L1_2(L2_2, L3_2)
    L2_2 = A0_2
    L1_2 = A0_2._SetPlayer2Bonus
    L3_2 = 500000
    L1_2(L2_2, L3_2)
    L1_2 = _SetupBonusObjective
    L2_2 = A0_2
    L1_2(L2_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 45
  L4_2[1] = L5_2
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = {}
  L7_2 = {}
  L8_2 = "Fiona-In-Mission-Contract-Gur002-53"
  L7_2[1] = L8_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Object
  L1_2 = L1_2.GetHealth
  L2_2 = uChurchGuid
  L1_2 = L1_2(L2_2)
  nHealth = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectHealth
  L4_2 = {}
  L5_2 = uChurchGuid
  L6_2 = "<"
  L7_2 = nHealth
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.CreateChild
    L2_3 = {}
    L2_3.sName = "DontHurtChurch"
    L2_3.sModuleName = "MrxTaskObjective"
    L2_3.sDspShortDesc = "[GurCon002.Objectives.008]"
    L3_3 = {}
    L4_3 = "Fiona-In-Mission-Contract-Gur002-43"
    L3_3[1] = L4_3
    L2_3.vVoSeqOnAdd = L3_3
    L0_3 = L0_3(L1_3, L2_3)
    oDontHurtChurch = L0_3
  end
  
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  uChurchHealthEvent = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = uChurchGuid
  L4_2[1] = L5_2
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._SetCancelMessage
    L2_3 = "[GurCon002.Terms.CancelChurchDead]"
    L0_3(L1_3, L2_3)
    L0_3 = A0_2
    L0_3 = L0_3.Cancel
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  uChurchDeath = L1_2
end

SetupDestroyObjective = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 60
  L4_2[1] = L5_2
  L5_2 = MoveToChurch
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

SetupChurchObjective = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._SetFlag
  L3_2 = "AllBuildingsDestroyed"
  L1_2(L2_2, L3_2)
  L1_2 = _Checkpoint
  L1_2()
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Gur002-35"
  L4_2 = {}
  L5_2 = A0_2.MoveToChurch
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
end

CheckCompletion = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "MoveToChurch"
  L3_2.sDspShortDesc = "[GurCon002.Objectives.009]"
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2 = Player
  L4_2 = L4_2.GetAnyCharacter
  L4_2 = L4_2()
  L3_2.vTgtInclude = L4_2
  L3_2.bDspBlp = true
  L3_2.vDestLoc = "Church_GurCon002"
  L3_2.vDestRegion = "LineRegion_Church"
  L3_2.fDist = 5
  L3_2.bStop = false
  L3_2.bXZOnly = false
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.DefendChurch
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
  L4_2 = {}
  L5_2 = "Fiona-In-Mission-Contract-Gur002-36"
  L4_2[1] = L5_2
  L3_2.vVoSeqOnAdd = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  oChurchFound = L1_2
end

MoveToChurch = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = uChurchHealthEvent
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uChurchHealthEvent
    L1_2(L2_2)
  end
  L1_2 = uChurchDeath
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uChurchDeath
    L1_2(L2_2)
  end
  L1_2 = _RemoveTanks
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = _ChurchHibernationCancel
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = uChurchGuid
  L6_2 = "asleep"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  
  function L5_2()
    local L0_3, L1_3
  end
  
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  uHibernationCancelEvent = L1_2
  L1_2 = Ai
  L1_2 = L1_2.SetInfractionMultiplier
  L2_2 = GetGuidByName
  L3_2 = "Guerilla"
  L2_2 = L2_2(L3_2)
  L3_2 = 0
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "DefendChurch"
  L3_2.sModuleName = "MrxTaskObjectiveProtect"
  L4_2 = uChurchGuid
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[GurCon002.Objectives.006]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.KillCaptain
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = TracingVO1
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = TracingVO1
      L0_3(L1_3)
    end
    L0_3 = TracingVO2
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = TracingVO2
      L0_3(L1_3)
    end
    L0_3 = TracingVO3
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = TracingVO3
      L0_3(L1_3)
    end
    L0_3 = DirectionVO1
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = DirectionVO1
      L0_3(L1_3)
    end
    L0_3 = DirectionVO2
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = DirectionVO2
      L0_3(L1_3)
    end
    L0_3 = DirectionVO3
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = DirectionVO3
      L0_3(L1_3)
    end
    L0_3 = DirectionVO4
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = DirectionVO4
      L0_3(L1_3)
    end
    L0_3 = DirectionVO5
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = DirectionVO5
      L0_3(L1_3)
    end
    L0_3 = CountDownEvent
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = CountDownEvent
      L0_3(L1_3)
    end
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._SetCancelMessage
    L2_3 = "[GurCon002.Terms.CancelChurchUndefended]"
    L0_3(L1_3, L2_3)
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-Gur002-50"
    L3_3 = {}
    L4_3 = A0_2
    L4_3 = L4_3.Cancel
    L5_3 = {}
    L6_3 = A0_2
    L5_3[1] = L6_3
    L3_3[1] = L4_3
    L3_3[2] = L5_3
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L0_3(L1_3)
  end
  
  L3_2.fOnCancel = L4_2
  L4_2 = {}
  L5_2 = {}
  L5_2.mattias = "Mattias-In-Mission-Contract-Gur002-21"
  L5_2.jennifer = "Jennifer-In-Mission-Contract-Gur002-22"
  L5_2.chris = "Chris-In-Mission-Contract-Gur002-23"
  L6_2 = 1
  L7_2 = "Fiona-In-Mission-Contract-Gur002-15"
  L8_2 = 0
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L3_2.vVoSeqOnAdd = L4_2
  
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = MrxUtil
    L0_3 = L0_3.DisplayHealthBar
    L1_3 = A0_2
    L2_3 = uChurchGuid
    L3_3 = 0
    L4_3 = true
    L5_3 = 1
    L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
    L0_3 = DisplayCountdownBar
    L1_3 = A0_2
    L2_3 = 0
    L0_3(L1_3, L2_3)
  end
  
  L3_2.fOnInitialNotesComplete = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  oDefendChurchObj = L1_2
  L1_2 = MrxMusic
  L1_2 = L1_2.PlaySpecialMusic
  L2_2 = "mu_fac_gr_kickass_01"
  L1_2(L2_2)
  L1_2 = SetupChurchHealthVO
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 20
  L4_2[1] = L5_2
  L5_2 = _SpawnTankOutOfView
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = "Path_ChurchAttack_CommSouth"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 20
  L4_2[1] = L5_2
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = {}
  L7_2 = "Fiona-In-Mission-Contract-Gur002-52"
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 35
  L4_2[1] = L5_2
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = {}
  L7_2 = "Fiona-In-Mission-Contract-Pmc03-66"
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  DirectionVO1 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 40
  L4_2[1] = L5_2
  L5_2 = _SpawnTankOutOfView
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = "Path_ChurchAttack_CommNorth"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 50
  L4_2[1] = L5_2
  L5_2 = _SpawnTankOutOfView
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = "Path_ChurchAttack_South"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 85
  L4_2[1] = L5_2
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = {}
  L7_2 = "Fiona-In-Mission-Contract-Oil01-89"
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  DirectionVO2 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 80
  L4_2[1] = L5_2
  L5_2 = _SpawnTankOutOfView
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = "Path_ChurchAttack_SoccerMiddle_Tank"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 90
  L4_2[1] = L5_2
  L5_2 = _SpawnTankOutOfView
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = "Path_ChurchAttack_SoccerNorth_Tank"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 110
  L4_2[1] = L5_2
  L5_2 = _SpawnTankOutOfView
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = "Path_ChurchAttack_SouthStairs"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 137
  L4_2[1] = L5_2
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = {}
  L7_2 = "Fiona.vg2fio14"
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  ReinforcementVO1 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 135
  L4_2[1] = L5_2
  L5_2 = _GurHeloDrop
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = Pg
  L8_2 = L8_2.GetGuidByName
  L9_2 = "GurCon001HeloDropPoint1"
  L8_2 = L8_2(L9_2)
  L9_2 = Pg
  L9_2 = L9_2.GetGuidByName
  L10_2 = "GurCon002HeloPath1"
  L9_2 = L9_2(L10_2)
  L10_2 = Pg
  L10_2 = L10_2.GetGuidByName
  L11_2 = "GurCon001_ChurchHoverPath1"
  L10_2, L11_2 = L10_2(L11_2)
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L6_2[5] = L11_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 160
  L4_2[1] = L5_2
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = {}
  L7_2 = "Fiona-In-Mission-Contract-Oil01-97"
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  DirectionVO3 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 150
  L4_2[1] = L5_2
  L5_2 = _SpawnTankOutOfView
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = "Path_ChurchAttack_SoccerSouth_Tank"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 150
  L4_2[1] = L5_2
  L5_2 = _SpawnTankOutOfView
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = "Path_ChurchAttack_CommNorth_APC"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 170
  L4_2[1] = L5_2
  L5_2 = _SpawnTankOutOfView
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = "Path_ChurchAttack_Outpost"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 193
  L4_2[1] = L5_2
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = {}
  L7_2 = "Fiona-In-Mission-MinorContract-Gur04-04"
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  ReinforcementVO2 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 190
  L4_2[1] = L5_2
  L5_2 = _GurHeloDrop
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = Pg
  L8_2 = L8_2.GetGuidByName
  L9_2 = "GurCon001HeloDropPoint2"
  L8_2 = L8_2(L9_2)
  L9_2 = Pg
  L9_2 = L9_2.GetGuidByName
  L10_2 = "GurCon002HeloPath1"
  L9_2 = L9_2(L10_2)
  L10_2 = Pg
  L10_2 = L10_2.GetGuidByName
  L11_2 = "GurCon001_ChurchHoverPath2"
  L10_2, L11_2 = L10_2(L11_2)
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L6_2[5] = L11_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 220
  L4_2[1] = L5_2
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = {}
  L7_2 = "Fiona.Alex07"
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  DirectionVO4 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 210
  L4_2[1] = L5_2
  L5_2 = _SpawnTankOutOfView
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = "Path_ChurchAttack_CommSouthStairs"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 210
  L4_2[1] = L5_2
  L5_2 = _SpawnTankOutOfView
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = "Path_ChurchAttack_SouthStairs"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 268
  L4_2[1] = L5_2
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = {}
  L7_2 = "Fiona-In-Mission-Contract-Gur002-17"
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  TracingVO1 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 255
  L4_2[1] = L5_2
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = {}
  L7_2 = "Fiona-In-Mission-Contract-Pmc03-67"
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  DirectionVO5 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 250
  L4_2[1] = L5_2
  L5_2 = _SpawnTankOutOfView
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = "Path_ChurchAttack_SoccerMiddle_Tank"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 250
  L4_2[1] = L5_2
  L5_2 = _SpawnTankOutOfView
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = "Path_ChurchAttack_SoccerSouth_Tank"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 288
  L4_2[1] = L5_2
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = {}
  L7_2 = "Fiona-In-Mission-Contract-Gur002-18"
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  TracingVO2 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 300
  L4_2[1] = L5_2
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = {}
  L7_2 = "Fiona-In-Mission-Contract-Gur002-19"
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  TracingVO3 = L1_2
end

DefendChurch = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxUtil
  L1_2 = L1_2.StopHealthBar
  L2_2 = uChurchGuid
  L1_2(L2_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Gur002-24"
  L2_2[1] = L3_2
  L1_2(L2_2)
end

_ChurchDead = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2
  L1_2 = A0_2._SetFlag
  L3_2 = "ChurchDefended"
  L1_2(L2_2, L3_2)
  L1_2 = _Checkpoint
  L1_2()
  L1_2 = MrxMusic
  L1_2 = L1_2.StopSpecialMusic
  L2_2 = "none"
  L1_2(L2_2)
  L1_2 = uAbandonCancelEvent
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uAbandonCancelEvent
    L1_2(L2_2)
  end
  L1_2 = Ai
  L1_2 = L1_2.SetInfractionMultiplier
  L2_2 = GetGuidByName
  L3_2 = "Guerilla"
  L2_2 = L2_2(L3_2)
  L3_2 = 1
  L1_2(L2_2, L3_2)
  L1_2 = oDontHurtChurch
  if L1_2 then
    L1_2 = oDontHurtChurch
    L2_2 = L1_2
    L1_2 = L1_2.Complete
    L1_2(L2_2)
  end
  L1_2 = uChurchVOHealthEvent1
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uChurchVOHealthEvent1
    L1_2(L2_2)
  end
  L1_2 = uChurchVOHealthEvent2
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uChurchVOHealthEvent2
    L1_2(L2_2)
  end
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 1
  L1_2(L2_2, L3_2)
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
  L7_2 = "GurCon002_Soccer_Music_Border"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = _SetupSoccerMusic
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = uChurchDeath
  L1_2(L2_2)
  L1_2 = MrxUtil
  L1_2 = L1_2.StopHealthBar
  L2_2 = uChurchGuid
  L1_2(L2_2)
  L1_2 = Pg
  L1_2 = L1_2.Spawn
  L2_2 = "VZ Deathsquad B HVT"
  L3_2 = 2674.283
  L4_2 = -29.048033
  L5_2 = -1654.2429
  L6_2 = 0
  L7_2 = false
  L8_2 = true
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  Mendez_Spawn = L1_2
  L1_2 = Object
  L1_2 = L1_2.SetName
  L2_2 = Mendez_Spawn
  L3_2 = "Mendez"
  L1_2 = L1_2(L2_2, L3_2)
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "VerifyMendez"
  L4_2.sModuleName = "MrxTaskObjectiveVerify"
  L5_2 = Mendez_Spawn
  L4_2.vTgtInclude = L5_2
  L4_2.sDspShortDesc = "[GurCon002.Objectives.007]"
  L4_2.sFactionId = "Gur"
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = {}
    L3_3 = "Fiona-In-Mission-Contract-Gur002-20"
    L2_3[1] = L3_3
    L3_3 = {}
    L4_3 = A0_2
    L4_3 = L4_3.Complete
    L5_3 = {}
    L6_3 = A0_2
    L5_3[1] = L6_3
    L3_3[1] = L4_3
    L3_3[2] = L5_3
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L0_3(L1_3)
  end
  
  L4_2.fOnComplete = L5_2
  L5_2 = {}
  L6_2 = {}
  L7_2 = A0_2.Cancel
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnCancel = L5_2
  L5_2 = {}
  L6_2 = "Fiona-In-Mission-Contract-Gur002-39"
  L7_2 = "Fiona-In-Mission-Contract-Gur002-40"
  L8_2 = "Fiona-In-Mission-Contract-Gur002-41"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L4_2.vVoSeqOnAdd = L5_2
  L2_2(L3_2, L4_2)
end

KillCaptain = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxMusic
  L1_2 = L1_2.PlaySpecialMusic
  L2_2 = "mu_fac_gr_threat_01"
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
  L7_2 = "GurCon002_Soccer_Music_Border"
  L6_2 = L6_2(L7_2)
  L7_2 = "exit"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = MrxMusic
    L0_3 = L0_3.StopSpecialMusic
    L1_3 = "none"
    L0_3(L1_3)
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._CreateEvent
    L2_3 = Event
    L2_3 = L2_3.Boundary
    L3_3 = {}
    L4_3 = Player
    L4_3 = L4_3.GetAnyCharacter
    L4_3 = L4_3()
    L5_3 = Pg
    L5_3 = L5_3.GetGuidByName
    L6_3 = "GurCon002_Soccer_Music_Border"
    L5_3 = L5_3(L6_3)
    L6_3 = "Enter"
    L3_3[1] = L4_3
    L3_3[2] = L5_3
    L3_3[3] = L6_3
    
    function L4_3()
      local L0_4, L1_4
      L0_4 = MrxMusic
      L0_4 = L0_4.PlaySpecialMusic
      L1_4 = "mu_fac_gr_threat_01"
      L0_4(L1_4)
      L0_4 = _SetupSoccerMusic
      L1_4 = A0_2
      L0_4(L1_4)
    end
    
    L0_3(L1_3, L2_3, L3_3, L4_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

_SetupSoccerMusic = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Civ Death Bonus"
  L3_2.sModuleName = "MrxTaskObjective"
  L3_2.bOptional = true
  L3_2.bDspMsg = true
  L3_2.bDspDescPda = true
  L3_2.bDspBlp = false
  L3_2.sDspShortDesc = "[GurCon002.Objectives.Bonus]"
  L1_2 = L1_2(L2_2, L3_2)
  oCivCasualtyObjective = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "CollateralDamage"
  
  function L6_2()
    local L0_3, L1_3
    L0_3 = true
    return L0_3
  end
  
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._SetPlayer1Bonus
    L2_3 = 0
    L0_3(L1_3, L2_3)
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._SetPlayer2Bonus
    L2_3 = 0
    L0_3(L1_3, L2_3)
    L0_3 = oCivCasualtyObjective
    L1_3 = L0_3
    L0_3 = L0_3.Cancel
    L0_3(L1_3)
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-Gur002-54"
    L1_3[1] = L2_3
    L0_3(L1_3)
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._SetFlag
    L2_3 = "BonusFailed"
    L0_3(L1_3, L2_3)
    L0_3 = _Checkpoint
    L0_3()
  end
  
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  uBonusEvent = L1_2
end

_SetupBonusObjective = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Pg
  L1_2 = L1_2.FastCollectGroundVehicles
  L2_2 = 2113
  L3_2 = -7
  L4_2 = -1547
  L5_2 = 250
  L6_2 = "amx30"
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = ipairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = Vehicle
    L7_2 = L7_2.GetDriver
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    L8_2 = MrxUtil
    L8_2 = L8_2.GetFaction
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    if L8_2 == "VZ" then
      L9_2 = Object
      L9_2 = L9_2.IsVisible
      L10_2 = L6_2
      L9_2 = L9_2(L10_2)
      if not L9_2 then
        L9_2 = Object
        L9_2 = L9_2.Remove
        L10_2 = L6_2
        L9_2(L10_2)
      end
    end
  end
end

_RemoveTanks = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Ai
  L1_2 = L1_2.RemoveExclusionZone
  L1_2()
  L1_2 = DangerousBuilding
  L1_2 = L1_2.SetRarity
  L2_2 = "all"
  L3_2 = "default"
  L1_2(L2_2, L3_2)
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
  L1_2 = Ai
  L1_2 = L1_2.SetInfractionMultiplier
  L2_2 = GetGuidByName
  L3_2 = "Guerilla"
  L2_2 = L2_2(L3_2)
  L3_2 = 1
  L1_2(L2_2, L3_2)
  L1_2 = uAbandonCancelEvent
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uAbandonCancelEvent
    L1_2(L2_2)
  end
  L1_2 = MrxMusic
  L1_2 = L1_2.StopSpecialMusic
  L2_2 = "none"
  L1_2(L2_2)
  L1_2 = uBonusEvent
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uBonusEvent
    L1_2(L2_2)
  end
  L1_2 = DangerousBuilding
  L1_2 = L1_2.RemoveDB
  L2_2 = tMySpawners
  L1_2(L2_2)
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Remove
  L2_2 = "vz_state_gurcon002_traffic"
  L1_2(L2_2)
  L1_2 = MrxUtil
  L1_2 = L1_2.StopHealthBar
  L2_2 = uGuid
  L1_2(L2_2)
  L1_2 = oTimer
  if L1_2 then
    L1_2 = oTimer
    L2_2 = L1_2
    L1_2 = L1_2.Stop
    L1_2(L2_2)
  end
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = DangerousBuilding
  L0_2 = L0_2.SetRarity
  L1_2 = "default"
  L2_2 = "never"
  L0_2(L1_2, L2_2)
  L0_2 = 20
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "CommercialBuildingGurcon002"
  L1_2 = L1_2(L2_2)
  TallCommBuild = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "_merida_bld_plazachurch 0"
  L1_2 = L1_2(L2_2)
  Church = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "ResidentialBuildingGurcon002"
  L1_2 = L1_2(L2_2)
  ResidentialBuild = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "ProjectsBuildingGurcon002"
  L1_2 = L1_2(L2_2)
  NEBuild = L1_2
  L1_2 = DangerousBuilding
  L1_2 = L1_2.TurnOn
  L2_2 = TallCommBuild
  L3_2 = false
  L4_2 = true
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawnersInGroup
  L2_2 = TallCommBuild
  L3_2 = "Ground"
  L4_2 = {}
  L4_2.SpawnList = "Spawnlist (VZ Ground)"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawnersInGroup
  L2_2 = TallCommBuild
  L3_2 = "Balcony"
  L4_2 = {}
  L4_2.SpawnList = "Spawnlist (VZ Ground)"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawnersInGroup
  L2_2 = TallCommBuild
  L3_2 = "Rooftop"
  L4_2 = {}
  L4_2.SpawnList = "Spawnlist (VZ AA)"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawners
  L2_2 = TallCommBuild
  L3_2 = {}
  L3_2.SpawnerState = "on"
  L1_2(L2_2, L3_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawners
  L2_2 = TallCommBuild
  L3_2 = {}
  L3_2.SecondsPerCycle = L0_2
  L1_2(L2_2, L3_2)
  L1_2 = DangerousBuilding
  L1_2 = L1_2.TurnOn
  L2_2 = ResidentialBuild
  L3_2 = false
  L4_2 = true
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawners
  L2_2 = ResidentialBuild
  L3_2 = {}
  L3_2.SpawnerState = "on"
  L1_2(L2_2, L3_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawnersInGroup
  L2_2 = ResidentialBuild
  L3_2 = "Ground"
  L4_2 = {}
  L4_2.SpawnList = "Spawnlist (VZ Ground)"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawnersInGroup
  L2_2 = ResidentialBuild
  L3_2 = "Balcony"
  L4_2 = {}
  L4_2.SpawnList = "Spawnlist (VZ AA)"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawnersInGroup
  L2_2 = ResidentialBuild
  L3_2 = "Rooftop"
  L4_2 = {}
  L4_2.SpawnList = "Spawnlist (VZ AA)"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawners
  L2_2 = ResidentialBuild
  L3_2 = {}
  L3_2.SecondsPerCycle = L0_2
  L1_2(L2_2, L3_2)
  L1_2 = DangerousBuilding
  L1_2 = L1_2.TurnOn
  L2_2 = NEBuild
  L3_2 = false
  L4_2 = true
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawners
  L2_2 = NEBuild
  L3_2 = {}
  L3_2.SpawnerState = "on"
  L1_2(L2_2, L3_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawnersInGroup
  L2_2 = NEBuild
  L3_2 = "Balcony"
  L4_2 = {}
  L4_2.SpawnList = "Spawnlist (VZ AA)"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawnersInGroup
  L2_2 = NEBuild
  L3_2 = "Rooftop"
  L4_2 = {}
  L4_2.SpawnList = "Spawnlist (VZ AA)"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawnersInGroup
  L2_2 = NEBuild
  L3_2 = "Ground"
  L4_2 = {}
  L4_2.SpawnList = "Spawnlist (VZ Ground)"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = DangerousBuilding
  L1_2 = L1_2.SetProperties
  L2_2 = ResidentialBuild
  L3_2 = {}
  L3_2.Density = 40
  L1_2(L2_2, L3_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawners
  L2_2 = NEBuild
  L3_2 = {}
  L3_2.SecondsPerCycle = L0_2
  L1_2(L2_2, L3_2)
  L1_2 = {}
  L2_2 = ResidentialBuild
  L1_2[1] = L2_2
  tMySpawners = L1_2
  L1_2 = DangerousBuilding
  L1_2 = L1_2.SetProperties
  L2_2 = ResidentialBuild
  L3_2 = {}
  L3_2.Group = "Rooftop"
  L3_2.Density = 0
  L1_2(L2_2, L3_2)
  L1_2 = DangerousBuilding
  L1_2 = L1_2.SetProperties
  L2_2 = ResidentialBuild
  L3_2 = {}
  L3_2.Group = "Balcony"
  L3_2.Density = 0
  L1_2(L2_2, L3_2)
end

SetupDangerousObjBuildings = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = 60
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "_merida_bld_lockerroom 0"
  L1_2 = L1_2(L2_2)
  LockerWest = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "_merida_bld_lockerroom 0x000b0952"
  L1_2 = L1_2(L2_2)
  LockerEast = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "_merida_bld_mediabooth 0x000b0a4d"
  L1_2 = L1_2(L2_2)
  MediaNE = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "_merida_bld_mediabooth 0x000b0a4f"
  L1_2 = L1_2(L2_2)
  MediaSW = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "_vzoutpost_bld_barracktent 0x000b1ce8"
  L1_2 = L1_2(L2_2)
  BarracksEast = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "_vzoutpost_bld_barracktent 0x000b1ce9"
  L1_2 = L1_2(L2_2)
  BarracksWest = L1_2
  L1_2 = DangerousBuilding
  L1_2 = L1_2.TurnOn
  L2_2 = MediaNE
  L3_2 = false
  L4_2 = true
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawners
  L2_2 = MediaNE
  L3_2 = {}
  L3_2.SpawnerState = "on"
  L1_2(L2_2, L3_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawners
  L2_2 = MediaNE
  L3_2 = {}
  L3_2.SpawnList = "Spawnlist (VZ AA)"
  L1_2(L2_2, L3_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawners
  L2_2 = MediaNE
  L3_2 = {}
  L3_2.SecondsPerCycle = L0_2
  L1_2(L2_2, L3_2)
  L1_2 = DangerousBuilding
  L1_2 = L1_2.TurnOn
  L2_2 = MediaSW
  L3_2 = false
  L4_2 = true
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawners
  L2_2 = MediaSW
  L3_2 = {}
  L3_2.SpawnerState = "on"
  L1_2(L2_2, L3_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawners
  L2_2 = MediaSW
  L3_2 = {}
  L3_2.SpawnList = "Spawnlist (VZ AA)"
  L1_2(L2_2, L3_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawners
  L2_2 = MediaSW
  L3_2 = {}
  L3_2.SecondsPerCycle = L0_2
  L1_2(L2_2, L3_2)
  L1_2 = DangerousBuilding
  L1_2 = L1_2.TurnOn
  L2_2 = LockerEast
  L3_2 = true
  L4_2 = true
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawners
  L2_2 = LockerEast
  L3_2 = {}
  L3_2.SpawnList = "Spawnlist (VZ Elite)"
  L1_2(L2_2, L3_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawners
  L2_2 = LockerEast
  L3_2 = {}
  L3_2.SpawnerState = "on"
  L1_2(L2_2, L3_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawners
  L2_2 = LockerEast
  L3_2 = {}
  L3_2.SecondsPerCycle = L0_2
  L1_2(L2_2, L3_2)
  L1_2 = DangerousBuilding
  L1_2 = L1_2.TurnOn
  L2_2 = BarracksEast
  L3_2 = true
  L4_2 = true
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawners
  L2_2 = BarracksEast
  L3_2 = {}
  L3_2.SpawnList = "Spawnlist (VZ Elite)"
  L1_2(L2_2, L3_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawners
  L2_2 = BarracksEast
  L3_2 = {}
  L3_2.SpawnerState = "on"
  L1_2(L2_2, L3_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawners
  L2_2 = BarracksEast
  L3_2 = {}
  L3_2.SecondsPerCycle = L0_2
  L1_2(L2_2, L3_2)
  L1_2 = DangerousBuilding
  L1_2 = L1_2.TurnOn
  L2_2 = BarracksWest
  L3_2 = true
  L4_2 = true
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawners
  L2_2 = BarracksWest
  L3_2 = {}
  L3_2.SpawnList = "Spawnlist (VZ Elite)"
  L1_2(L2_2, L3_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawners
  L2_2 = BarracksWest
  L3_2 = {}
  L3_2.SpawnerState = "on"
  L1_2(L2_2, L3_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawners
  L2_2 = BarracksWest
  L3_2 = {}
  L3_2.SecondsPerCycle = L0_2
  L1_2(L2_2, L3_2)
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "_merida_bld_universitydorm 0"
  L1_2 = L1_2(L2_2)
  ProtestSE = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "_merida_bld_universitylibrary 1"
  L1_2 = L1_2(L2_2)
  ProtestNE = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "_merida_bld_universitycampus 0x000e3dbf"
  L1_2 = L1_2(L2_2)
  ProtestSW = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "_merida_bld_universitydorm 0x000e3833"
  L1_2 = L1_2(L2_2)
  ProtestNW = L1_2
  L1_2 = DangerousBuilding
  L1_2 = L1_2.TurnOn
  L2_2 = uChurchGuid
  L3_2 = true
  L4_2 = true
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawners
  L2_2 = uChurchGuid
  L3_2 = {}
  L3_2.SpawnList = "Spawnlist (Guerilla Ground)"
  L1_2(L2_2, L3_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawners
  L2_2 = uChurchGuid
  L3_2 = {}
  L3_2.SpawnerState = "on"
  L1_2(L2_2, L3_2)
  L1_2 = Ai
  L1_2 = L1_2.TweakAttachedSpawners
  L2_2 = uChurchGuid
  L3_2 = {}
  L3_2.SecondsPerCycle = 20
  L1_2(L2_2, L3_2)
end

SetupDangerousBuildings = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L4_2 = MrxUtil
  L4_2 = L4_2.FindSpawnPointOutOfView
  L5_2 = A2_2
  L6_2 = 200
  L4_2, L5_2, L6_2, L7_2, L8_2 = L4_2(L5_2, L6_2)
  nFacing = L8_2
  z = L7_2
  y = L6_2
  x = L5_2
  bSuccess = L4_2
  L4_2 = bSuccess
  if L4_2 == true then
    L4_2 = Pg
    L4_2 = L4_2.Spawn
    L5_2 = "UH1 Transport (GR) (Full) (RPG)"
    L6_2 = x
    L7_2 = y
    L8_2 = z
    L9_2 = nFacing
    L10_2 = false
    L11_2 = true
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
    SPAWN = L4_2
    L4_2 = Vehicle
    L4_2 = L4_2.GetDriver
    L5_2 = SPAWN
    L4_2 = L4_2(L5_2)
    L5_2 = {}
    L5_2.AIGuid = L4_2
    L5_2.Goal = "HeliLand"
    L5_2.Target = A1_2
    L5_2.Priority = "HiPri"
    L5_2.Haste = 0.75
    L5_2.Force = true
    L6_2 = BailOut
    L5_2.Callback = L6_2
    L6_2 = {}
    L7_2 = A0_2
    L8_2 = SPAWN
    L9_2 = L4_2
    L10_2 = A3_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L6_2[4] = L10_2
    L5_2.CallbackData = L6_2
    tLandGoalParams = L5_2
    L6_2 = A0_2
    L5_2 = A0_2._CreateEvent
    L7_2 = Event
    L7_2 = L7_2.ObjectHibernation
    L8_2 = {}
    L9_2 = SPAWN
    L10_2 = "awake"
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L9_2 = Ai
    L9_2 = L9_2.Goal
    L10_2 = {}
    L11_2 = tLandGoalParams
    L10_2[1] = L11_2
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  end
end

_GurHeloDrop = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L4_2 = Vehicle
  L4_2 = L4_2.GetRiders
  L5_2 = A1_2
  L6_2 = "p"
  L4_2 = L4_2(L5_2, L6_2)
  L5_2 = Ai
  L5_2 = L5_2.Deploy
  L6_2 = {}
  L6_2.Vehicle = A1_2
  L6_2.Role = "Passenger"
  L6_2.Force = true
  L6_2.MaintainRotorSpeed = true
  L7_2 = PatrolChurch
  L6_2.Callback = L7_2
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A1_2
  L10_2 = A2_2
  L11_2 = A3_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L6_2.CallbackData = L7_2
  L5_2(L6_2)
end

BailOut = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2
  L4_2 = Ai
  L4_2 = L4_2.Goal
  L5_2 = {}
  L5_2.AIGuid = A2_2
  L5_2.Goal = "PathMove"
  L5_2.Target = A3_2
  L5_2.Start = "Nearest"
  L5_2.Mode = "Loop"
  L5_2.Haste = 0.2
  L4_2(L5_2)
end

PatrolChurch = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = MrxUtil
  L2_2 = L2_2.FindSpawnPointOutOfView
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = 200
  L2_2, L3_2, L4_2, L5_2, L6_2 = L2_2(L3_2, L4_2)
  nFacing = L6_2
  z = L5_2
  y = L4_2
  x = L3_2
  bSuccess = L2_2
  L2_2 = bSuccess
  if L2_2 == true then
    L2_2 = Math
    L2_2 = L2_2.randi
    L3_2 = 0
    L4_2 = 1
    L2_2 = L2_2(L3_2, L4_2)
    CoinToss = L2_2
    L2_2 = Pg
    L2_2 = L2_2.Spawn
    L3_2 = "Amx30 (Full)"
    L4_2 = x
    L5_2 = y
    L6_2 = z
    L7_2 = nFacing
    L8_2 = false
    L9_2 = true
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
    SPAWN = L2_2
    L2_2 = _AttackChurch
    L3_2 = A0_2
    L4_2 = SPAWN
    L5_2 = Pg
    L5_2 = L5_2.GetGuidByName
    L6_2 = A1_2
    L5_2, L6_2, L7_2, L8_2, L9_2 = L5_2(L6_2)
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  end
end

_SpawnTankOutOfView = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = {}
  L4_2.AIGuid = L3_2
  L4_2.Goal = "PathMove"
  L4_2.Target = A2_2
  L4_2.Start = "Nearest"
  L4_2.Priority = "hipri"
  L4_2.Mode = "Oneway"
  L4_2.Haste = 0.75
  L5_2 = _FireOnChurch
  L4_2.Callback = L5_2
  L5_2 = {}
  L6_2 = A0_2
  L7_2 = L3_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2.CallbackData = L5_2
  tMoveGoalParams = L4_2
  L5_2 = A0_2
  L4_2 = A0_2._CreateEvent
  L6_2 = Event
  L6_2 = L6_2.ObjectHibernation
  L7_2 = {}
  L8_2 = A1_2
  L9_2 = "awake"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L8_2 = Ai
  L8_2 = L8_2.Goal
  L9_2 = {}
  L10_2 = tMoveGoalParams
  L9_2[1] = L10_2
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
end

_AttackChurch = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = Math
  L2_2 = L2_2.randi
  L3_2 = 0
  L4_2 = 1
  L2_2 = L2_2(L3_2, L4_2)
  CoinToss = L2_2
  L2_2 = CoinToss
  if L2_2 == 0 then
    L2_2 = "HiPri"
  else
    L2_2 = "MedPri"
  end
  L2_2 = {}
  L2_2.AIGuid = A1_2
  L2_2.Goal = "Attack"
  L3_2 = uChurchGuid
  L2_2.Target = L3_2
  L3_2 = sPriority
  L2_2.Priority = L3_2
  tGoalParams = L2_2
  L2_2 = Ai
  L2_2 = L2_2.Goal
  L3_2 = tGoalParams
  L2_2(L3_2)
end

_FireOnChurch = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = MrxUtil
  L2_2 = L2_2.FindSpawnPointOutOfView
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = 200
  L2_2, L3_2, L4_2, L5_2, L6_2 = L2_2(L3_2, L4_2)
  nFacing = L6_2
  z = L5_2
  y = L4_2
  x = L3_2
  bSuccess = L2_2
  L2_2 = bSuccess
  if L2_2 == true then
    L2_2 = Pg
    L2_2 = L2_2.Spawn
    L3_2 = "M113 (VZ) (Full)"
    L4_2 = x
    L5_2 = y
    L6_2 = z
    L7_2 = nFacing
    L8_2 = false
    L9_2 = true
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
    SPAWN = L2_2
    L2_2 = _APCMoveToChurch
    L3_2 = A0_2
    L4_2 = SPAWN
    L5_2 = Pg
    L5_2 = L5_2.GetGuidByName
    L6_2 = A1_2
    L5_2, L6_2, L7_2, L8_2, L9_2 = L5_2(L6_2)
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  end
end

_SpawnAPCOutOfView = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = {}
  L4_2.AIGuid = L3_2
  L4_2.Goal = "PathMove"
  L4_2.Target = A2_2
  L4_2.Start = "Nearest"
  L4_2.Priority = "hipri"
  L4_2.Mode = "Oneway"
  L4_2.Haste = 0.75
  L5_2 = BailOutAPC
  L4_2.Callback = L5_2
  L5_2 = {}
  L6_2 = A0_2
  L7_2 = A1_2
  L8_2 = L3_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L4_2.CallbackData = L5_2
  tMoveGoalParams = L4_2
  L5_2 = A0_2
  L4_2 = A0_2._CreateEvent
  L6_2 = Event
  L6_2 = L6_2.ObjectHibernation
  L7_2 = {}
  L8_2 = A1_2
  L9_2 = "awake"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L8_2 = Ai
  L8_2 = L8_2.Goal
  L9_2 = {}
  L10_2 = tMoveGoalParams
  L9_2[1] = L10_2
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
end

_APCMoveToChurch = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  L3_2 = Vehicle
  L3_2 = L3_2.GetRiders
  L4_2 = A1_2
  L5_2 = "p"
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = Ai
  L4_2 = L4_2.Deploy
  L5_2 = {}
  L5_2.Vehicle = A1_2
  L5_2.Role = "Passenger"
  L5_2.Force = true
  L4_2(L5_2)
end

BailOutAPC = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = Hud
  L2_2 = L2_2.ObjectiveTray
  L3_2 = L2_2
  L2_2 = L2_2.SetSlotToText
  L4_2 = {}
  L4_2.nSlot = 1
  L5_2 = "[GurCon002.Objectives.010][yellow][bar"
  L6_2 = A1_2
  L7_2 = "]"
  L5_2 = L5_2 .. L6_2 .. L7_2
  L4_2.sText = L5_2
  L2_2(L3_2, L4_2)
  A1_2 = A1_2 + 5
  if A1_2 == 100 then
    L2_2 = oDefendChurchObj
    L3_2 = L2_2
    L2_2 = L2_2.Complete
    L2_2(L3_2)
  else
    L3_2 = A0_2
    L2_2 = A0_2._CreateEvent
    L4_2 = Event
    L4_2 = L4_2.TimerRelative
    L5_2 = {}
    L6_2 = 15
    L5_2[1] = L6_2
    L6_2 = DisplayCountdownBar
    L7_2 = {}
    L8_2 = A0_2
    L9_2 = A1_2
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
    CountDownEvent = L2_2
  end
end

DisplayCountdownBar = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
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
  L7_2 = "LR_Church_Abandon"
  L6_2 = L6_2(L7_2)
  L7_2 = "Exit"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._SetCancelMessage
    L2_3 = "[GurCon002.Objectives.006]"
    L0_3(L1_3, L2_3)
    L0_3 = A0_2
    L0_3 = L0_3.Cancel
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  uAbandonCancelEvent = L1_2
end

_ChurchHibernationCancel = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = uChurchGuid
  L6_2 = "hibernated"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = _ChurchDamageTimer
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  oChurchHibernateEvent = L1_2
end

_DamageOnHibernate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 5
  L4_2[1] = L5_2
  L5_2 = _HurtChurch
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  oChurchTimer = L1_2
end

_ChurchDamageTimer = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = nChurchLife
  L1_2 = L1_2 - 250
  nChurchLife = L1_2
  L1_2 = nChurchLife
  if L1_2 <= 0 then
    L1_2 = Object
    L1_2 = L1_2.Kill
    L2_2 = uChurchGuid
    L1_2(L2_2)
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = oChurchTimer
    L1_2(L2_2)
  end
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = oChurchAwakeEvent
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = uChurchGuid
  L6_2 = "awake"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = _SetChurchHealth
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = nChurchLife
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  oChurchAwakeEvent2 = L1_2
  L1_2 = _ChurchDamageTimer
  L2_2 = A0_2
  L3_2 = nChurchLife
  L1_2(L2_2, L3_2)
end

_HurtChurch = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Object
  L1_2 = L1_2.GetHealth
  L2_2 = uChurchGuid
  L1_2 = L1_2(L2_2)
  L2_2 = nChurchLife
  L1_2 = L1_2 - L2_2
  nChurchDamage = L1_2
  L1_2 = Object
  L1_2 = L1_2.SetHealth
  L2_2 = uChurchGuid
  L3_2 = nChurchLife
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = uChurchGuid
  L6_2 = "hibernated"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = _ChurchDamageTimer
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = Object
  L8_2 = L8_2.GetHealth
  L9_2 = uChurchGuid
  L8_2, L9_2 = L8_2(L9_2)
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  oChurchHibernateEvent2 = L1_2
end

_SetChurchHealth = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Object
  L1_2 = L1_2.GetHealth
  L2_2 = uChurchGuid
  L1_2 = L1_2(L2_2)
  nHealth = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectHealth
  L4_2 = {}
  L5_2 = uChurchGuid
  L6_2 = "<"
  L7_2 = nHealth
  L7_2 = L7_2 / 2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-Gur002-48"
    L1_3[1] = L2_3
    L0_3(L1_3)
  end
  
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  uChurchVOHealthEvent1 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectHealth
  L4_2 = {}
  L5_2 = uChurchGuid
  L6_2 = "<"
  L7_2 = nHealth
  L7_2 = L7_2 / 10
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-Gur002-49"
    L1_3[1] = L2_3
    L0_3(L1_3)
  end
  
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  uChurchVOHealthEvent2 = L1_2
end

SetupChurchHealthVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
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
  L7_2 = "rgn_sfx_GurCon002"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = {}
  L7_2 = {}
  L8_2 = "Fiona-In-Mission-Contract-Gur002-31"
  L7_2[1] = L8_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

_SetupVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = BuildingsDestroyed
  if L1_2 == 0 then
    L1_2 = MrxVoSequence
    L1_2 = L1_2.Start
    L2_2 = {}
    L3_2 = "Fiona-In-Mission-Contract-Gur002-33"
    L2_2[1] = L3_2
    L1_2(L2_2)
  else
    L1_2 = BuildingsDestroyed
    if L1_2 == 1 then
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = "Fiona-In-Mission-Contract-Gur002-34"
      L2_2[1] = L3_2
      L1_2(L2_2)
    end
  end
  L1_2 = BuildingsDestroyed
  L1_2 = L1_2 + 1
  BuildingsDestroyed = L1_2
end

BuildingDestroyedVO = L0_1
