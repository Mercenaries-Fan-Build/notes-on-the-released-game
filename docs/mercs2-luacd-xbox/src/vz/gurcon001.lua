local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "DangerousBuilding"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "Munitions"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTransit"
L0_1(L1_1)
L0_1 = nil
BeachCheckPointEventWest = L0_1
L0_1 = nil
BeachCheckPointEventEast = L0_1
L0_1 = nil
BeachCheckPointEventMid = L0_1
L0_1 = 0
BuildingsDestroyed = L0_1
L0_1 = {}
tHelosSpawned = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = {}
  L3_2 = "Vz_State_GurCon001"
  L4_2 = "Vz_State_GurCon001_staging"
  L5_2 = "vz_state_temp_staging_gurcon002"
  L6_2 = "vz_state_gurcon001_pristine"
  L7_2 = "Vz_State_GurCon001_outpost"
  L8_2 = "Vz_State_GurCon001_outpost_pristine"
  L9_2 = "VZ_State_GurCon001_TG"
  L10_2 = "vz_state_gurcon001_fortress"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L2_2[6] = L8_2
  L2_2[7] = L9_2
  L2_2[8] = L10_2
  tLayersToAdd = L2_2
  L2_2 = MrxLayerManager
  L2_2 = L2_2.Add
  L3_2 = tLayersToAdd
  L4_2 = A0_2.AssetsLoaded
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = {}
  L3_2 = "vz_state_temp_staging_gurcon002"
  L4_2 = "vz_state_gurcon001_pristine"
  L5_2 = "Vz_State_GurCon001_outpost"
  L6_2 = "Vz_State_GurCon001_outpost_pristine"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  tLayersToAdd = L2_2
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = 0
  ObjectivesDestroyed = L1_2
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
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = _SetupVO
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
  L7_2 = "LR_VZGurAttack_GC2"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = _SetupVZAttack
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "BeachReached"
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    L1_2 = AddBeachCheckpoints
    L2_2 = A0_2
    L1_2(L2_2)
  else
    L1_2 = Pg
    L1_2 = L1_2.GetGuidByName
    L2_2 = "VZ Soldier 0x00126c6f"
    L1_2 = L1_2(L2_2)
    if L1_2 then
      L1_2 = Object
      L1_2 = L1_2.Remove
      L2_2 = Pg
      L2_2 = L2_2.GetGuidByName
      L3_2 = "VZ Soldier 0x00126c6f"
      L2_2, L3_2, L4_2, L5_2, L6_2, L7_2 = L2_2(L3_2)
      L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
    end
    L1_2 = Pg
    L1_2 = L1_2.GetGuidByName
    L2_2 = "VZ Soldier 0x00126c6b"
    L1_2 = L1_2(L2_2)
    if L1_2 then
      L1_2 = Object
      L1_2 = L1_2.Remove
      L2_2 = Pg
      L2_2 = L2_2.GetGuidByName
      L3_2 = "VZ Soldier 0x00126c6b"
      L2_2, L3_2, L4_2, L5_2, L6_2, L7_2 = L2_2(L3_2)
      L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
    end
  end
  L1_2 = _SetupHeloAttacks
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = DestroyCastle
  L2_2 = A0_2
  L1_2(L2_2)
end

Start = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = 0
  MunitionsCollected = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "BlowUpCastle"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = {}
  L5_2 = "_island_bld_fortress01 0x0008a5b0"
  L4_2[1] = L5_2
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[GurCon001.objective.destroycastle]"
  L4_2 = {}
  L5_2 = "Fiona-Banter-Contract-Gur01-01"
  L6_2 = 0.4
  L7_2 = {}
  L7_2.mattias = "Mattias-Banter-Contract-Gur01-02"
  L7_2.jennifer = "jennifer-Banter-Contract-Gur01-03"
  L7_2.chris = "chris-Banter-Contract-Gur01-04"
  L8_2 = 1
  L9_2 = "Fiona-In-Mission-Contract-Gur001-25"
  L10_2 = 1
  L11_2 = "Fiona-In-Mission-Contract-Gur001-48"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L4_2[7] = L11_2
  L3_2.vVoSeqOnAdd = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = ObjectiveDestroyed
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "BlowUpTower"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = {}
  L5_2 = "_island_bld_tower01 0x0008a5b1"
  L4_2[1] = L5_2
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[GurCon001.objective.destroytower]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = ObjectiveDestroyed
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "BlowUpBridge"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = {}
  L5_2 = "_island_bld_bridge01 0x0008a5af"
  L4_2[1] = L5_2
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[GurCon001.objective.destroybridge]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = ObjectiveDestroyed
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "BonusCompleted"
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2._SetPlayer1Bonus
    L3_2 = 500000
    L1_2(L2_2, L3_2)
    L2_2 = A0_2
    L1_2 = A0_2._SetPlayer2Bonus
    L3_2 = 500000
    L1_2(L2_2, L3_2)
    L1_2 = KillBarracks
    L2_2 = A0_2
    L1_2(L2_2)
  else
    L1_2 = SetupBonusObj
    L2_2 = A0_2
    L1_2(L2_2)
  end
end

DestroyCastle = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = ObjectivesDestroyed
  L1_2 = L1_2 + 1
  ObjectivesDestroyed = L1_2
  L1_2 = ObjectivesDestroyed
  if L1_2 == 1 then
    L1_2 = MrxVoSequence
    L1_2 = L1_2.Start
    L2_2 = {}
    L3_2 = "Fiona.xfio136"
    L2_2[1] = L3_2
    L1_2(L2_2)
  else
    L1_2 = ObjectivesDestroyed
    if L1_2 == 2 then
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = "Fiona-In-Mission-Job-Oil11-16"
      L2_2[1] = L3_2
      L1_2(L2_2)
    else
      L1_2 = ObjectivesDestroyed
      if L1_2 == 3 then
        L1_2 = MrxVoSequence
        L1_2 = L1_2.Start
        L2_2 = {}
        L3_2 = "Fiona-In-Mission-Contract-Gur001-50"
        L4_2 = 0.5
        L5_2 = {}
        L5_2.mattias = "Mattias-In-Mission-Contract-Gur001-21"
        L5_2.jennifer = "jennifer-In-Mission-Contract-Gur001-22"
        L5_2.chris = "chris-In-Mission-Contract-Gur001-23"
        L6_2 = 1
        L7_2 = "Fiona-In-Mission-Contract-Gur001-24"
        L8_2 = {}
        L9_2 = A0_2.Complete
        L10_2 = {}
        L11_2 = A0_2
        L10_2[1] = L11_2
        L8_2[1] = L9_2
        L8_2[2] = L10_2
        L2_2[1] = L3_2
        L2_2[2] = L4_2
        L2_2[3] = L5_2
        L2_2[4] = L6_2
        L2_2[5] = L7_2
        L2_2[6] = L8_2
        L1_2(L2_2)
      end
    end
  end
end

ObjectiveDestroyed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Destroy Barracks"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = {}
  L5_2 = "gurcon001.barracks.01"
  L6_2 = "gurcon001.barracks.003"
  L7_2 = "gurcon001.barracks.004"
  L8_2 = "gurcon001.barracks.005"
  L9_2 = "gurcon001.barracks.006"
  L10_2 = "gurcon001.barracks.007"
  L11_2 = "gurcon001.barracks.008"
  L12_2 = "_vzoutpost_bld_barrackbunker 0x000c9a1b"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L4_2[7] = L11_2
  L4_2[8] = L12_2
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[GurCon001.objective.DestroyVzBarracks]"
  L3_2.bOptional = true
  
  function L4_2()
    local L0_3, L1_3, L2_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona.va6fio06"
    L1_3[1] = L2_3
    L0_3(L1_3)
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
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._SetFlag
    L2_3 = "BonusCompleted"
    L0_3(L1_3, L2_3)
    L0_3 = _Checkpoint
    L0_3()
    L0_3 = uBonusObj
    L0_3 = L0_3.Complete
    L1_3 = uBonusObj
    L0_3(L1_3)
  end
  
  L3_2.fOnComplete = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  uBonusObj = L1_2
end

SetupBonusObj = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = {}
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "gurcon001.barracks.01"
  L2_2 = L2_2(L3_2)
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "gurcon001.barracks.003"
  L3_2 = L3_2(L4_2)
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "gurcon001.barracks.004"
  L4_2 = L4_2(L5_2)
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "gurcon001.barracks.005"
  L5_2 = L5_2(L6_2)
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "gurcon001.barracks.006"
  L6_2 = L6_2(L7_2)
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "gurcon001.barracks.007"
  L7_2 = L7_2(L8_2)
  L8_2 = Pg
  L8_2 = L8_2.GetGuidByName
  L9_2 = "gurcon001.barracks.008"
  L8_2 = L8_2(L9_2)
  L9_2 = Pg
  L9_2 = L9_2.GetGuidByName
  L10_2 = "_vzoutpost_bld_barrackbunker 0x000c9a1b"
  L9_2, L10_2, L11_2, L12_2 = L9_2(L10_2)
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L1_2[7] = L8_2
  L1_2[8] = L9_2
  L1_2[9] = L10_2
  L1_2[10] = L11_2
  L1_2[11] = L12_2
  tBarracks = L1_2
  L1_2 = ipairs
  L2_2 = tBarracks
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L7_2 = A0_2
    L6_2 = A0_2._CreateEvent
    L8_2 = Event
    L8_2 = L8_2.ObjectHibernation
    L9_2 = {}
    L10_2 = L5_2
    L11_2 = "awake"
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L10_2 = Object
    L10_2 = L10_2.Kill
    L11_2 = {}
    L12_2 = L5_2
    L11_2[1] = L12_2
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  end
end

KillBarracks = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "GurCon001_MasterMunitions"
  L3_2.sModuleName = "MrxTaskObjective"
  L3_2.sDspShortDesc = "[GurCon001.objective.munition]"
  L3_2.nQuota = 3
  L3_2.bOptional = true
  L1_2 = L1_2(L2_2, L3_2)
  oMunitions = L1_2
  L1_2 = {}
  L2_2 = "Munitions (Rocket Artillery) 0x0010565d"
  L3_2 = "Munitions (Rocket Artillery) 0x0010565e"
  L4_2 = "Munitions (Rocket Artillery) 0x00105661"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L2_2 = {}
  uSubMunitions = L2_2
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = Debug
    L7_2 = L7_2.Printf
    L8_2 = "Adding "
    L9_2 = L6_2
    L10_2 = " subObjective"
    L8_2 = L8_2 .. L9_2 .. L10_2
    L7_2(L8_2)
    L7_2 = Pg
    L7_2 = L7_2.GetGuidByName
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    if L7_2 then
      L8_2 = Munitions
      L8_2 = L8_2.ClearStatus
      L9_2 = L7_2
      L8_2(L9_2)
      L8_2 = uSubMunitions
      L10_2 = A0_2
      L9_2 = A0_2.CreateChild
      L11_2 = {}
      L12_2 = "GurCon001_SubMunitions"
      L13_2 = L5_2
      L12_2 = L12_2 .. L13_2
      L11_2.sName = L12_2
      L11_2.sModuleName = "MrxTaskObjectiveProtect"
      L11_2.sDspShortDesc = "[GurCon001.objective.munitions]"
      L11_2.vDestLoc = L7_2
      L11_2.vTgtInclude = L7_2
      L11_2.bOptional = true
      L11_2.sDspBlpRdrIcon = "objective_action"
      L11_2.sDspBlpWldIcon = "HUD_objective_action"
      L11_2.sDspBlpPdaIcon = "icon_action_2_mc"
      L12_2 = {}
      L13_2 = {}
      L14_2 = _DestroyedMunitions
      L15_2 = {}
      L16_2 = A0_2
      L17_2 = uGuid
      L15_2[1] = L16_2
      L15_2[2] = L17_2
      L13_2[1] = L14_2
      L13_2[2] = L15_2
      L12_2[1] = L13_2
      L11_2.tOnCancel = L12_2
      L9_2 = L9_2(L10_2, L11_2)
      L8_2[L7_2] = L9_2
    end
  end
  L3_2 = A0_2
  L2_2 = A0_2._CreatePersistentEvent
  L4_2 = Event
  L4_2 = L4_2.ScriptEvent
  L5_2 = {}
  L6_2 = "MunitionsPickup"
  
  function L7_2(A0_3)
    local L1_3, L2_3
    L1_3 = Pg
    L1_3 = L1_3.GetGuidByName
    L2_3 = "Munitions (Rocket Artillery) 0x00105661"
    L1_3 = L1_3(L2_3)
    L2_3 = A0_3[2]
    L1_3 = L1_3 == L2_3
    return L1_3
  end
  
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = _CompletedMunitions
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

SetUpMunitionsObjective = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = {}
  L3_2.mattias = "Mattias-In-Mission-Contract-Gur001-21"
  L3_2.jennifer = "jennifer-In-Mission-Contract-Gur001-22"
  L3_2.chris = "chris-In-Mission-Contract-Gur001-23"
  L4_2 = 1
  L5_2 = "Fiona-In-Mission-Contract-Gur001-24"
  L6_2 = {}
  L7_2 = A0_2.Complete
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L1_2(L2_2)
end

_MissionComplete = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = {}
  L1_2 = Vehicle
  L1_2 = L1_2.GetDriver
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "M151 .50Cal (VZ) (Full) 0x000dc48d"
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  L0_2.AIGuid = L1_2
  L0_2.Goal = "PathMove"
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "Path_VZGurAttackJeep2_GC2"
  L1_2 = L1_2(L2_2)
  L0_2.Target = L1_2
  L0_2.Priority = "hiPri"
  L0_2.Haste = 1
  tGoalParamsJeep1 = L0_2
  L0_2 = Ai
  L0_2 = L0_2.Goal
  L1_2 = tGoalParamsJeep1
  L0_2(L1_2)
  L0_2 = {}
  L1_2 = Vehicle
  L1_2 = L1_2.GetDriver
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "M151 .50Cal (VZ) (Full) 0x000dc48e"
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  L0_2.AIGuid = L1_2
  L0_2.Goal = "PathMove"
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "Path_VZGurAttackJeep1_GC2"
  L1_2 = L1_2(L2_2)
  L0_2.Target = L1_2
  L0_2.Priority = "hiPri"
  L0_2.Haste = 1
  tGoalParamsJeep2 = L0_2
  L0_2 = Ai
  L0_2 = L0_2.Goal
  L1_2 = tGoalParamsJeep2
  L0_2(L1_2)
  L0_2 = {}
  L1_2 = Vehicle
  L1_2 = L1_2.GetDriver
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "M35 (Cargo) (VZ) (Full) 0x000dc48c"
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  L0_2.AIGuid = L1_2
  L0_2.Goal = "PathMove"
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "Path_VZGurAttackTruck_GC2"
  L1_2 = L1_2(L2_2)
  L0_2.Target = L1_2
  L0_2.Priority = "hiPri"
  L0_2.Haste = 1
  L1_2 = Ai
  L1_2 = L1_2.Deploy
  L0_2.Callback = L1_2
  L1_2 = {}
  L2_2 = {}
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "M35 (Cargo) (VZ) (Full) 0x000dc48c"
  L3_2 = L3_2(L4_2)
  L2_2.Vehicle = L3_2
  L2_2.Priority = "hiPri"
  L1_2[1] = L2_2
  L0_2.CallbackData = L1_2
  tGoalParamsTruck = L0_2
  L0_2 = Ai
  L0_2 = L0_2.Goal
  L1_2 = tGoalParamsTruck
  L0_2(L1_2)
end

_SetupVZAttack = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L4_2 = MrxUtil
  L4_2 = L4_2.FindSpawnPointOutOfView
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = A1_2
  L5_2 = L5_2(L6_2)
  L6_2 = 290
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
    L5_2 = A2_2
    L6_2 = x
    L7_2 = y
    L8_2 = z
    L9_2 = nFacing
    L10_2 = false
    L11_2 = true
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
    SPAWN = L4_2
    L5_2 = A0_2
    L4_2 = A0_2._CreateEvent
    L6_2 = Event
    L6_2 = L6_2.ObjectHibernation
    L7_2 = {}
    L8_2 = Vehicle
    L8_2 = L8_2.GetDriver
    L9_2 = SPAWN
    L8_2 = L8_2(L9_2)
    L9_2 = "awake"
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    
    function L8_2()
      local L0_3, L1_3, L2_3, L3_3
      L0_3 = Ai
      L0_3 = L0_3.Goal
      L1_3 = {}
      L2_3 = Vehicle
      L2_3 = L2_3.GetDriver
      L3_3 = SPAWN
      L2_3 = L2_3(L3_3)
      L1_3.AIGuid = L2_3
      L1_3.Goal = "PathMove"
      L2_3 = Pg
      L2_3 = L2_3.GetGuidByName
      L3_3 = A1_2
      L2_3 = L2_3(L3_3)
      L1_3.Target = L2_3
      L1_3.Priority = "loPri"
      L1_3.Start = "Nearest"
      L2_3 = A3_2
      L1_3.Mode = L2_3
      L0_3(L1_3)
    end
    
    L4_2(L5_2, L6_2, L7_2, L8_2)
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = tHelosSpawned
    L6_2 = SPAWN
    L4_2(L5_2, L6_2)
  else
  end
end

_SpawnVehicleOutOfView = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A1_2[2]
  L3_2 = oMunitions
  L4_2 = L3_2
  L3_2 = L3_2.CompletePart
  L3_2(L4_2)
  L3_2 = uSubMunitions
  L3_2 = L3_2[L2_2]
  if L3_2 then
    L3_2 = uSubMunitions
    L3_2 = L3_2[L2_2]
    L4_2 = L3_2
    L3_2 = L3_2.Complete
    L3_2(L4_2)
  end
end

_CompletedMunitions = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = nQuota
  if not L2_2 then
    L2_2 = 3
  end
  nQuota = L2_2
  L2_2 = nQuota
  L2_2 = L2_2 - 1
  nQuota = L2_2
  L2_2 = nQuota
  if L2_2 < 1 then
    L2_2 = oMunitions
    L3_2 = L2_2
    L2_2 = L2_2.Cancel
    L2_2(L3_2)
  else
    L2_2 = oMunitions
    L2_2 = L2_2.Configure
    L3_2 = {}
    L4_2 = nQuota
    L3_2.nQuota = L4_2
    L2_2(L3_2)
  end
end

_DestroyedMunitions = L0_1

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
  L7_2 = "LRGurcon001Shore"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-Gur001-29"
    L1_3[1] = L2_3
    L0_3(L1_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 45
  L4_2[1] = L5_2
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-Gur001-41"
    L1_3[1] = L2_3
    L0_3(L1_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
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
  L7_2 = "LR_CastleGR2"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = {}
  L7_2 = {}
  L8_2 = "Fiona-In-Mission-Contract-Gur001-32"
  L7_2[1] = L8_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = GetGuidByName
  L6_2 = "M113 Jammer (VZ) (Driver) 0x000f3005"
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = {}
  L7_2 = {}
  L8_2 = "Fiona-In-Mission-Contract-Gur01-08"
  L7_2[1] = L8_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

_SetupVO = L0_1

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
  L7_2 = "GurCon001_Checkpoint"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._SetFlag
    L2_3 = "BeachReached"
    L0_3(L1_3, L2_3)
    L0_3 = _Checkpoint
    L1_3 = {}
    L2_3 = "Loc_CheckPoint_WestBeachP1"
    L3_3 = "Loc_CheckPoint_WestBeachP2"
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L0_3(L1_3)
  end
  
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  BeachCheckPointEventWest = L1_2
end

AddBeachCheckpoints = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = GetGuidByName
  L6_2 = "M113 Jammer (VZ) (Driver) 0x00126caa"
  L5_2, L6_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = _SpawnVehicleOutOfView
    L1_3 = A0_2
    L2_3 = "Path 0x00126cb6"
    L3_3 = "Alouette3 Attack (VZ) (Driver)"
    L4_3 = "Oneway"
    L0_3(L1_3, L2_3, L3_3, L4_3)
    L0_3 = oCallHeloJammer2
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = oCallHeloJammer2
      L0_3(L1_3)
    end
  end
  
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  oCallHeloJammer1 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = GetGuidByName
  L6_2 = "M113 Jammer (VZ) (Driver) 0x00126ca9"
  L5_2, L6_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = _SpawnVehicleOutOfView
    L1_3 = A0_2
    L2_3 = "Path 0x00126cb6"
    L3_3 = "Alouette3 Attack (VZ) (Driver)"
    L4_3 = "Oneway"
    L0_3(L1_3, L2_3, L3_3, L4_3)
    L0_3 = oCallHeloJammer1
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = oCallHeloJammer1
      L0_3(L1_3)
    end
  end
  
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  oCallHeloJammer2 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = GetGuidByName
  L6_2 = "_island_bld_fortress01 0x0008a5b0"
  L5_2, L6_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = _SpawnVehicleOutOfView
    L1_3 = A0_2
    L2_3 = "Path 0x00126c94"
    L3_3 = "Alouette3 Attack (VZ) (Driver)"
    L4_3 = "Oneway"
    L0_3(L1_3, L2_3, L3_3, L4_3)
    L0_3 = oCallHeloCastle2
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = oCallHeloCastle2
      L0_3(L1_3)
    end
    L0_3 = oCallHeloCastle3
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = oCallHeloCastle3
      L0_3(L1_3)
    end
  end
  
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  oCallHeloCastle1 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = GetGuidByName
  L6_2 = "_island_bld_bridge01 0x0008a5af"
  L5_2, L6_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = _SpawnVehicleOutOfView
    L1_3 = A0_2
    L2_3 = "Path 0x00126c94"
    L3_3 = "Alouette3 Attack (VZ) (Driver)"
    L4_3 = "Bounce"
    L0_3(L1_3, L2_3, L3_3, L4_3)
    L0_3 = oCallHeloJammer1
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = oCallHeloCastle1
      L0_3(L1_3)
    end
    L0_3 = oCallHeloCastle3
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = oCallHeloCastle3
      L0_3(L1_3)
    end
  end
  
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  oCallHeloCastle2 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = GetGuidByName
  L6_2 = "_island_bld_tower01 0x0008a5b1"
  L5_2, L6_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = Pg
    L0_3 = L0_3.GetGuidByName
    L1_3 = "M113 Jammer (VZ) (Driver) 0x00126ca9"
    L0_3 = L0_3(L1_3)
    uJammer = L0_3
    L0_3 = Object
    L0_3 = L0_3.GetPosition
    L1_3 = uJammer
    L0_3, L1_3, L2_3 = L0_3(L1_3)
    nZ = L2_3
    nY = L1_3
    nX = L0_3
    L0_3 = Pg
    L0_3 = L0_3.IsPointInBoundary
    L1_3 = nX
    L2_3 = nY
    L3_3 = nZ
    L4_3 = Pg
    L4_3 = L4_3.GetGuidByName
    L5_3 = "LR_TowerBase"
    L4_3, L5_3 = L4_3(L5_3)
    L0_3 = L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
    if L0_3 then
      L0_3 = Object
      L0_3 = L0_3.Kill
      L1_3 = uJammer
      L0_3(L1_3)
    end
    L0_3 = _SpawnVehicleOutOfView
    L1_3 = A0_2
    L2_3 = "Path 0x00126c94"
    L3_3 = "Alouette3 Attack (VZ) (Driver)"
    L4_3 = "Bounce"
    L0_3(L1_3, L2_3, L3_3, L4_3)
    L0_3 = oCallHeloCastle1
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = oCallHeloCastle1
      L0_3(L1_3)
    end
    L0_3 = oCallHeloCastle2
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = oCallHeloCastle2
      L0_3(L1_3)
    end
  end
  
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  oCallHeloCastle3 = L1_2
end

_SetupHeloAttacks = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Sound
  L1_2 = L1_2.SetDynamicMusic
  L2_2 = true
  L1_2(L2_2)
  L1_2 = oCastleMusicOff
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = oCastleMusicOff
    L1_2(L2_2)
  end
  L1_2 = oCastleMusicOn
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = oCastleMusicOn
    L1_2(L2_2)
  end
  L1_2 = ipairs
  L2_2 = tLayersToAdd
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = MrxLayerManager
    L6_2 = L6_2.MarkForRemoval
    L7_2 = L5_2
    L6_2(L7_2)
  end
  L1_2 = ipairs
  L2_2 = tHelosSpawned
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    if L5_2 then
      L6_2 = Vehicle
      L6_2 = L6_2.GetFromRider
      L7_2 = Player
      L7_2 = L7_2.GetPrimaryCharacter
      L7_2, L8_2, L9_2 = L7_2()
      L6_2 = L6_2(L7_2, L8_2, L9_2)
      L7_2 = Vehicle
      L7_2 = L7_2.GetFromRider
      L8_2 = Player
      L8_2 = L8_2.GetSecondaryCharacter
      L8_2, L9_2 = L8_2()
      L7_2 = L7_2(L8_2, L9_2)
      if L6_2 ~= L5_2 and L7_2 ~= L5_2 then
        L8_2 = Object
        L8_2 = L8_2.Remove
        L9_2 = L5_2
        L8_2(L9_2)
      end
    end
  end
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
