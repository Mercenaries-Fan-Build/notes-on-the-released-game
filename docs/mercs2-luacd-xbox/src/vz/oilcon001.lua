local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxApcDrop"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxMissionBoundary"
L0_1(L1_1)
L0_1 = import
L1_1 = "DangerousBuilding"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxCopterDrop"
L0_1(L1_1)
L0_1 = {}
L1_1 = {}
L1_1.name = "warehouse2"
L1_1.sDesc = "[OilCon001.Objectives.warehouse2]"
L1_1.office = "refinery_office02"
L1_1.dropoffPoint = "oc001.obj2.loc.dropoff"
L1_1.returnPoint = "oc001.obj2.loc.return"
L1_1.hidePoint = "oc001.obj2.loc.hide"
L1_1.boxVal = 10
L1_1.goalVal = 340
L2_1 = {}
L3_1 = "OilExec-In-Mission-Contract-Oil01-57"
L4_1 = "OilExec-In-Mission-Contract-Oil01-58"
L5_1 = "OilExec-In-Mission-Contract-Oil01-59"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tVO = L2_1
L0_1[1] = L1_1
L1_1 = {}
L1_1.name = "warehouse1"
L1_1.sDesc = "[OilCon001.Objectives.warehouse1]"
L1_1.office = "refinery_office03"
L1_1.dropoffPoint = "oc001.obj3.loc.dropoff"
L1_1.returnPoint = "oc001.obj3.loc.return"
L1_1.hidePoint = "oc001.obj3.loc.hide"
L1_1.boxVal = 10
L1_1.goalVal = 200
L2_1 = {}
L3_1 = "OilExec-In-Mission-Contract-Oil01-62"
L4_1 = "OilExec-In-Mission-Contract-Oil01-63"
L5_1 = "OilExec-In-Mission-Contract-Oil01-64"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tVO = L2_1
L0_1[2] = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = {}
  L3_2 = "vz_state_mar_industrial_act1"
  L2_2[1] = L3_2
  L3_2 = {}
  L4_2 = "vz_state_mar_industrial_pristine"
  L5_2 = "Vz_State_OilCon001"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L5_2 = A0_2
  L4_2 = A0_2._GetFlag
  L6_2 = "StartSite2"
  L4_2 = L4_2(L5_2, L6_2)
  if L4_2 == nil then
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L3_2
    L6_2 = "Vz_State_OilCon001_part1"
    L4_2(L5_2, L6_2)
  else
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L2_2
    L6_2 = "Vz_State_OilCon001_part1"
    L4_2(L5_2, L6_2)
  end
  L4_2 = DangerousBuilding
  L4_2 = L4_2.SetRarity
  L5_2 = "all"
  L6_2 = "never"
  L4_2(L5_2, L6_2)
  L4_2 = MrxLayerManager
  L4_2 = L4_2.Remove
  L5_2 = L2_2
  
  function L6_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = MrxLayerManager
    L0_3 = L0_3.Add
    L1_3 = L3_2
    L2_3 = A0_2
    L2_3 = L2_3.AssetsLoaded
    L3_3 = {}
    L4_3 = A0_2
    L3_3[1] = L4_3
    L0_3(L1_3, L2_3, L3_3)
  end
  
  L4_2(L5_2, L6_2)
end

LoadAssets = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  
  function L1_2()
    local L0_3, L1_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.Cancel
    L0_3(L1_3)
  end
  
  _MyCancel = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "oc001_exec"
  L1_2 = L1_2(L2_2)
  L3_2 = A0_2
  L2_2 = A0_2._GetFlag
  L4_2 = "StartSite2"
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    L2_2 = _DestroyGate
    L3_2 = "mar_industrial_gate_north"
    L2_2(L3_2)
    L2_2 = _DestroyGate
    L3_2 = "_ocoutpost_wallgate 0x10001d5d"
    L2_2(L3_2)
    L2_2 = _DestroyGate
    L3_2 = "_ocoutpost_wallgate 0x000dac4e"
    L2_2(L3_2)
    L2_2 = MrxFactionManager
    L2_2 = L2_2.DisableReporting
    L3_2 = true
    L2_2(L3_2)
    L2_2 = Executive
    L3_2 = L2_2
    L2_2 = L2_2.Create
    L4_2 = A0_2
    L5_2 = L1_2
    L6_2 = _MyCancel
    L7_2 = Pg
    L7_2 = L7_2.GetGuidByName
    L8_2 = L0_1
    L8_2 = L8_2[2]
    L8_2 = L8_2.returnPoint
    L7_2, L8_2 = L7_2(L8_2)
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
    A0_2.exec = L2_2
    L3_2 = A0_2
    L2_2 = A0_2.Obj_Site2_Goto
    L2_2(L3_2)
  else
    L2_2 = Executive
    L3_2 = L2_2
    L2_2 = L2_2.Create
    L4_2 = A0_2
    L5_2 = L1_2
    L6_2 = _MyCancel
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
    A0_2.exec = L2_2
    L3_2 = A0_2
    L2_2 = A0_2.FirstWarehouseDestroyedSetup
    L2_2(L3_2)
    L3_2 = A0_2
    L2_2 = A0_2.BuildingDestroyedSetup
    L4_2 = "refinery_office03"
    L2_2(L3_2, L4_2)
    L3_2 = A0_2
    L2_2 = A0_2.Obj_GotoRefinery
    L2_2(L3_2)
    L2_2 = _SetupConvoy1
    L2_2()
  end
  L3_2 = A0_2
  L2_2 = A0_2.BuildingDestroyedSetup
  L4_2 = "refinery_office02"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2.SoundRegion_Outside
  L2_2(L3_2)
end

Activated = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = A0_2.exec
  if L1_2 then
    L1_2 = Object
    L1_2 = L1_2.IsAlive
    L2_2 = A0_2.exec
    L2_2 = L2_2.guid
    L1_2 = L1_2(L2_2)
    if not L1_2 then
      L1_2 = A0_2.bCancelVoPlayed
      if not L1_2 then
        L2_2 = A0_2
        L1_2 = A0_2._SetCancelMessage
        L3_2 = "[OilCon001.Terms.Cancel01]"
        L1_2(L2_2, L3_2)
        L1_2 = {}
        L2_2 = "OilExec-In-Mission-Contract-Oil01-49"
        L3_2 = "OilExec-In-Mission-Contract-Oil01-49"
        L4_2 = "OilExec-In-Mission-Contract-Oil01-50"
        L5_2 = "OilExec-In-Mission-Contract-Oil01-50"
        L6_2 = "OilExec-In-Mission-Contract-Oil01-51"
        L1_2[1] = L2_2
        L1_2[2] = L3_2
        L1_2[3] = L4_2
        L1_2[4] = L5_2
        L1_2[5] = L6_2
        L2_2 = {}
        L3_2 = MrxUtil
        L3_2 = L3_2.GetRandomTableElement
        L4_2 = L1_2
        L3_2 = L3_2(L4_2)
        L4_2 = "Fiona-In-Mission-Contract-Oil01-16"
        L5_2 = {}
        L6_2 = MrxTaskContract
        L6_2 = L6_2.Cancel
        L7_2 = {}
        L8_2 = A0_2
        L7_2[1] = L8_2
        L5_2[1] = L6_2
        L5_2[2] = L7_2
        L2_2[1] = L3_2
        L2_2[2] = L4_2
        L2_2[3] = L5_2
        L3_2 = MrxVoSequence
        L3_2 = L3_2.Start
        L4_2 = L2_2
        L3_2(L4_2)
        A0_2.bCancelVoPlayed = true
      end
  end
  else
    L1_2 = MrxTaskContract
    L1_2 = L1_2.Cancel
    L2_2 = A0_2
    L1_2(L2_2)
  end
end

Cancel = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = A0_2.curAttack
  if L1_2 then
    L1_2 = A0_2.curAttack
    L2_2 = L1_2
    L1_2 = L1_2.Cleanup
    L1_2(L2_2)
    A0_2.curAttack = nil
  end
  L1_2 = A0_2.heliAttack
  if L1_2 then
    L1_2 = A0_2.heliAttack
    L2_2 = L1_2
    L1_2 = L1_2.Cleanup
    L1_2(L2_2)
    A0_2.heliAttack = nil
  end
  L1_2 = A0_2.exec
  if L1_2 then
    L1_2 = A0_2.exec
    L2_2 = L1_2
    L1_2 = L1_2.Cleanup
    L1_2(L2_2)
    L1_2 = Object
    L1_2 = L1_2.Remove
    L2_2 = A0_2.exec
    L2_2 = L2_2.guid
    L1_2(L2_2)
    A0_2.exec = nil
  end
  L1_2 = A0_2.missionBoundary
  if L1_2 then
    L1_2 = A0_2.missionBoundary
    L2_2 = L1_2
    L1_2 = L1_2.Cancel
    L1_2(L2_2)
    A0_2.missionBoundary = nil
  end
  L1_2 = Ai
  L1_2 = L1_2.RemoveExclusionZone
  L1_2()
  L1_2 = DangerousBuilding
  L1_2 = L1_2.SetRarity
  L2_2 = "all"
  L3_2 = "default"
  L1_2(L2_2, L3_2)
  L1_2 = MrxFactionManager
  L1_2 = L1_2.DisableReporting
  L2_2 = false
  L1_2(L2_2)
  L1_2 = {}
  L2_2 = "Vz_State_OilCon001"
  L3_2 = "Vz_State_OilCon001_part1"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = MrxLayerManager
    L7_2 = L7_2.MarkForRemoval
    L8_2 = L6_2
    L7_2(L8_2)
  end
  L2_2 = MrxSupportData
  L2_2 = L2_2.RemoveFreebie
  L3_2 = "OilCon001_Crate"
  L2_2(L3_2)
  L2_2 = MrxTaskContract
  L2_2 = L2_2.Cleanup
  L3_2 = A0_2
  L2_2(L3_2)
end

Cleanup = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "oc001 go to"
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L3_2.vDestLoc = "refinery_doc_warehouse01"
  L3_2.fDist = 120
  L3_2.bXZOnly = true
  L4_2 = Player
  L4_2 = L4_2.GetAnyCharacter
  L4_2 = L4_2()
  L3_2.vTgtInclude = L4_2
  L3_2.bStop = false
  L3_2.nQuota = 1
  L3_2.sDspShortDesc = "[OilCon001.Objectives.001]"
  
  function L4_2()
    local L0_3, L1_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.Obj_RescueExec
    L0_3(L1_3)
  end
  
  L3_2.fOnComplete = L4_2
  L4_2 = _MyCancel
  L3_2.fOnCancel = L4_2
  L4_2 = {}
  L5_2 = "Fiona-Banter-Contract-Oil01-01"
  L6_2 = {}
  L6_2.mattias = "Mattias-Banter-Contract-Oil01-02"
  L6_2.jennifer = "Jennifer-Banter-Contract-Oil01-03"
  L6_2.chris = "Chris-Banter-Contract-Oil01-04"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L3_2.vVoSeqOnAdd = L4_2
  L1_2(L2_2, L3_2)
end

Obj_GotoRefinery = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Ai
  L1_2 = L1_2.Squad
  L2_2 = {}
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "oc001.obj1.vzsquad1"
  L3_2 = L3_2(L4_2)
  L2_2.SquadGuid = L3_2
  L2_2.Action = "GetUnits"
  L1_2 = L1_2(L2_2)
  L2_2 = false
  L3_2 = pairs
  L4_2 = L1_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = Object
    L8_2 = L8_2.IsAlive
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    if L8_2 then
      L2_2 = true
      break
    end
  end
  if L2_2 then
    L4_2 = A0_2
    L3_2 = A0_2.CreateChild
    L5_2 = {}
    L5_2.sName = "oc001 rescue executive"
    L5_2.sModuleName = "MrxTaskObjectiveDestroy"
    L5_2.vTgtInclude = L1_2
    L5_2.bDspBlp = true
    L5_2.sDspShortDesc = "[OilCon001.Objectives.002]"
    L6_2 = {}
    L7_2 = {}
    L8_2 = Obj_TalkToExec
    L9_2 = {}
    L10_2 = A0_2
    L9_2[1] = L10_2
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L6_2[1] = L7_2
    L5_2.tOnComplete = L6_2
    L6_2 = _MyCancel
    L5_2.fOnCancel = L6_2
    L6_2 = {}
    L7_2 = "Fiona-In-Mission-Contract-Oil01-01"
    L6_2[1] = L7_2
    L5_2.vVoSeqOnAdd = L6_2
    L3_2 = L3_2(L4_2, L5_2)
    A0_2.curObj = L3_2
  else
    L4_2 = A0_2
    L3_2 = A0_2.Obj_TalkToExec
    L3_2(L4_2)
  end
  L4_2 = A0_2
  L3_2 = A0_2.CreateMissionBoundary
  L5_2 = {}
  L5_2.sPoint = "refinery_doc_warehouse01"
  L6_2 = {}
  L7_2 = "Fiona-In-Mission-Contract-Oil01-135"
  L8_2 = "Fiona-In-Mission-Contract-Oil01-18"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2.tExitVOs = L6_2
  L6_2 = {}
  L7_2 = "Fiona-In-Mission-Contract-Oil01-136"
  L6_2[1] = L7_2
  L5_2.tWarnVOs = L6_2
  
  function L6_2()
    local L0_3, L1_3
    L0_3 = Object
    L0_3 = L0_3.IsHibernated
    L1_3 = A0_2
    L1_3 = L1_3.exec
    L1_3 = L1_3.guid
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L0_3 = _MyCancel
      L0_3()
    else
      L0_3 = Object
      L0_3 = L0_3.Kill
      L1_3 = A0_2
      L1_3 = L1_3.exec
      L1_3 = L1_3.guid
      L0_3(L1_3)
    end
  end
  
  L5_2.fCallback = L6_2
  L3_2(L4_2, L5_2)
  L3_2 = MrxFactionManager
  L3_2 = L3_2.DisableReporting
  L4_2 = true
  L3_2(L4_2)
end

Obj_RescueExec = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = A0_2.exec
  L1_2 = L1_2.guid
  if not L1_2 then
    L2_2 = Pg
    L2_2 = L2_2.GetGuidByName
    L3_2 = "oc001_exec"
    L2_2 = L2_2(L3_2)
    L1_2 = L2_2
  end
  A0_2.curObj = nil
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "talk to exec"
  L4_2.sModuleName = "MrxTaskObjectiveAction"
  L4_2.sActionLabel = "[ContextAction.Talk]"
  L4_2.vTgtInclude = L1_2
  L4_2.bDsp = true
  L4_2.bDspMsg = true
  L4_2.sDspShortDesc = "[OilCon001.Objectives.003]"
  L5_2 = {}
  L6_2 = {}
  L7_2 = ExecutiveIntroConversation
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnPartComplete = L5_2
  L5_2 = _MyCancel
  L4_2.fOnCancel = L5_2
  L5_2 = {}
  L6_2 = "Fiona-In-Mission-Contract-Oil01-134"
  L5_2[1] = L6_2
  L4_2.vVoSeqOnAdd = L5_2
  L2_2(L3_2, L4_2)
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
  L8_2 = "oc001.rgn.warehouse01"
  L7_2 = L7_2(L8_2)
  L8_2 = "enter"
  L9_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L6_2 = _OCSavedBanter
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

Obj_TalkToExec = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L5_2 = Ai
  L5_2 = L5_2.RemoveGoal
  L6_2 = {}
  L7_2 = A0_2.exec
  L7_2 = L7_2.guid
  L6_2.AIGuid = L7_2
  L6_2.Handle = 0
  L5_2(L6_2)
  L6_2 = A0_2
  L5_2 = A0_2.CreateChild
  L7_2 = {}
  L8_2 = "Deliver exec to "
  L9_2 = A1_2.name
  L8_2 = L8_2 .. L9_2
  L7_2.sName = L8_2
  L7_2.sModuleName = "MrxTaskObjectiveDeliver"
  L8_2 = A1_2.dropoffPoint
  L7_2.vDestLoc = L8_2
  L8_2 = A1_2.fDist
  if not L8_2 then
    L8_2 = 3.5
  end
  L7_2.fDist = L8_2
  L7_2.bXZOnly = false
  L7_2.bStop = true
  L7_2.uStartAttachedToPlayer = A4_2
  L8_2 = A0_2.exec
  L8_2 = L8_2.guid
  L7_2.vTgtInclude = L8_2
  L8_2 = A1_2.sDesc
  L7_2.sDspShortDesc = L8_2
  L8_2 = {}
  L9_2 = {}
  L10_2 = A2_2
  L11_2 = {}
  L12_2 = A0_2
  L13_2 = A1_2
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L8_2[1] = L9_2
  L7_2.tOnComplete = L8_2
  L8_2 = _MyCancel
  L7_2.fOnCancel = L8_2
  L8_2 = A1_2.fAttachCallback
  L7_2.fAttachCallback = L8_2
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L7_2.tAttachCallbackData = L8_2
  L8_2 = {}
  L9_2 = "OilExec-In-Mission-Contract-Oil01-28"
  L10_2 = "OilExec-In-Mission-Contract-Oil01-29"
  L11_2 = "OilExec-In-Mission-Contract-Oil01-30"
  L12_2 = "OilExec-In-Mission-Contract-Oil01-31"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  L7_2.tStartFollowVO = L8_2
  L8_2 = {}
  L9_2 = "OilExec-In-Mission-Contract-Oil01-32"
  L10_2 = "OilExec-In-Mission-Contract-Oil01-33"
  L11_2 = "OilExec-In-Mission-Contract-Oil01-34"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L7_2.tStopFollowVO = L8_2
  L8_2 = {}
  L9_2 = "OilExec-In-Mission-Contract-Oil01-38"
  L10_2 = "OilExec-In-Mission-Contract-Oil01-37"
  L11_2 = "OilExec-In-Mission-Contract-Oil01-39"
  L12_2 = "OilExec-In-Mission-Contract-Oil01-35"
  L13_2 = "OilExec-In-Mission-Contract-Oil01-36"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  L8_2[5] = L13_2
  L7_2.tLostVO = L8_2
  L8_2 = {}
  L9_2 = "OilExec-In-Mission-Contract-Oil01-43"
  L10_2 = "OilExec-In-Mission-Contract-Oil01-42"
  L11_2 = "OilExec-In-Mission-Contract-Oil01-40"
  L12_2 = "OilExec-In-Mission-Contract-Oil01-41"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  L7_2.tFoundVO = L8_2
  L8_2 = {}
  L9_2 = "OilExec-In-Mission-Contract-Oil01-45"
  L10_2 = "OilExec-In-Mission-Contract-Oil01-48"
  L11_2 = "OilExec-In-Mission-Contract-Oil01-49"
  L12_2 = "OilExec-In-Mission-Contract-Oil01-47"
  L13_2 = "OilExec-In-Mission-Contract-Oil01-45"
  L14_2 = "OilExec-In-Mission-Contract-Oil01-48"
  L15_2 = "OilExec-In-Mission-Contract-Oil01-49"
  L16_2 = "OilExec-In-Mission-Contract-Oil01-46"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  L8_2[5] = L13_2
  L8_2[6] = L14_2
  L8_2[7] = L15_2
  L8_2[8] = L16_2
  L7_2.tHostileVO = L8_2
  L7_2.vVoSeqOnAdd = A3_2
  L5_2(L6_2, L7_2)
end

ObjDeliverExec = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A0_2.exec
  L3_2 = L2_2
  L2_2 = L2_2.Stand
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
  L2_2 = Ai
  L2_2 = L2_2.Goal
  L3_2 = {}
  L4_2 = A0_2.exec
  L4_2 = L4_2.guid
  L3_2.AIGuid = L4_2
  L3_2.Goal = "Idle"
  L3_2.Priority = "HiPri"
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2.Obj_Site3_Goto
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._RabbitSetup
  L2_2(L3_2)
end

ExecutiveIntroConversation = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._SetFlag
  L3_2 = "StartSite2"
  L1_2(L2_2, L3_2)
  L1_2 = _Checkpoint
  L2_2 = {}
  L3_2 = "oc001.loc.restart.p1"
  L4_2 = "oc001.loc.restart.p2"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
  L1_2 = {}
  L2_2 = {}
  L3_2 = "OilExec-In-Mission-Contract-Oil01-60"
  L4_2 = A0_2.exec
  L4_2 = L4_2.guid
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2[1] = L2_2
  L3_2 = A0_2
  L2_2 = A0_2.ObjDeliverExec
  L4_2 = L0_1
  L4_2 = L4_2[1]
  L5_2 = A0_2.Obj_Site2_Defend
  L6_2 = L1_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L2_2 = _DestroyGate
  L3_2 = "mar_industrial_gate_north"
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2.CreateMissionBoundaryDelayed
  L4_2 = {}
  L5_2 = L0_1
  L5_2 = L5_2[1]
  L5_2 = L5_2.dropoffPoint
  L4_2.sPoint = L5_2
  L5_2 = {}
  L6_2 = "Fiona-In-Mission-Contract-Oil01-137"
  L7_2 = "Fiona-In-Mission-Contract-Oil01-138"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2.tExitVOs = L5_2
  L5_2 = {}
  L6_2 = "Fiona-In-Mission-Contract-Oil01-139"
  L5_2[1] = L6_2
  L4_2.tWarnVOs = L5_2
  L5_2 = DocumentsCaptured
  L4_2.fCallback = L5_2
  L2_2(L3_2, L4_2)
end

Obj_Site2_Goto = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2
  L2_2 = {}
  L2_2.office = "refinery_office02"
  L3_2 = {}
  L4_2 = {}
  L5_2 = "oc001.obj2.pth.atk1"
  L6_2 = "oc001.obj2.pth.atk2"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = {}
  L6_2 = "oc001.obj2.pth.atk3"
  L7_2 = "oc001.obj2.pth.atk4"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = {}
  L7_2 = "oc001.obj2.pth.atk5"
  L8_2 = "oc001.obj2.pth.atk6"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L2_2.atkPaths = L3_2
  L3_2 = {}
  L4_2 = "oc001.obj2.loc.atk1"
  L5_2 = "oc001.obj2.loc.atk2"
  L6_2 = "oc001.obj2.loc.atk3"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L2_2.atkPoints = L3_2
  L3_2 = {}
  L4_2 = "oc001.obj2.loc"
  L5_2 = "oc001.obj2.loc.atk4"
  L6_2 = "oc001.obj2.loc.atk5"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L2_2.defPoints = L3_2
  L3_2 = {}
  L4_2 = 185
  L5_2 = 130
  L6_2 = 150
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L2_2.atkSpawnDist = L3_2
  L3_2 = {}
  L4_2 = 90
  L5_2 = 90
  L6_2 = 70
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L2_2.atkRanges = L3_2
  L2_2.waveVal = 10
  L3_2 = {}
  L4_2 = {}
  L5_2 = "apc"
  L6_2 = "apc"
  L7_2 = 1
  L8_2 = 12
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = {}
  L6_2 = "setpath"
  L7_2 = {}
  L8_2 = 1
  L7_2[1] = L8_2
  L8_2 = {}
  L9_2 = {}
  L10_2 = "OilExec-In-Mission-Contract-Oil01-61"
  L11_2 = A0_2.exec
  L11_2 = L11_2.guid
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L10_2 = 1.5
  L11_2 = {}
  L12_2 = "Fiona-In-Mission-Contract-Oil01-94"
  L11_2[1] = L12_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L6_2 = {}
  L7_2 = "delay"
  L8_2 = 4
  L9_2 = 1
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L7_2 = {}
  L8_2 = "wave"
  L7_2[1] = L8_2
  L8_2 = {}
  L9_2 = "wave"
  L8_2[1] = L9_2
  L9_2 = {}
  L10_2 = "wave"
  L9_2[1] = L10_2
  L10_2 = {}
  L11_2 = "wave"
  L10_2[1] = L11_2
  L11_2 = {}
  L12_2 = "wave"
  L11_2[1] = L12_2
  L12_2 = {}
  L13_2 = "setpath"
  L14_2 = {}
  L15_2 = 2
  L16_2 = 3
  L14_2[1] = L15_2
  L14_2[2] = L16_2
  L15_2 = {}
  L16_2 = "Fiona-In-Mission-Contract-Oil01-97"
  L15_2[1] = L16_2
  L12_2[1] = L13_2
  L12_2[2] = L14_2
  L12_2[3] = L15_2
  L13_2 = {}
  L14_2 = "call"
  L15_2 = _PerformBanter
  L16_2 = {}
  L17_2 = A0_2
  L18_2 = "oc001.obj2.loc.atk4"
  L19_2 = "OCMerc-In-Mission-Contract-Oil01-79"
  L20_2 = nil
  L16_2[1] = L17_2
  L16_2[2] = L18_2
  L16_2[3] = L19_2
  L16_2[4] = L20_2
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L13_2[3] = L16_2
  L14_2 = {}
  L15_2 = "wave"
  L14_2[1] = L15_2
  L15_2 = {}
  L16_2 = "wave"
  L15_2[1] = L16_2
  L16_2 = {}
  L17_2 = "setpath"
  L18_2 = {}
  L19_2 = 1
  L20_2 = 2
  L21_2 = 3
  L18_2[1] = L19_2
  L18_2[2] = L20_2
  L18_2[3] = L21_2
  L19_2 = {}
  L20_2 = "Fiona-In-Mission-Contract-Oil01-100"
  L19_2[1] = L20_2
  L16_2[1] = L17_2
  L16_2[2] = L18_2
  L16_2[3] = L19_2
  L17_2 = {}
  L18_2 = "delay"
  L19_2 = 5
  L20_2 = 2
  L17_2[1] = L18_2
  L17_2[2] = L19_2
  L17_2[3] = L20_2
  L18_2 = {}
  L19_2 = "wave"
  L18_2[1] = L19_2
  L19_2 = {}
  L20_2 = "call"
  L21_2 = TowerDefenseNag
  L22_2 = {}
  L23_2 = A0_2
  L22_2[1] = L23_2
  L19_2[1] = L20_2
  L19_2[2] = L21_2
  L19_2[3] = L22_2
  L20_2 = {}
  L21_2 = "delay"
  L22_2 = 2
  L20_2[1] = L21_2
  L20_2[2] = L22_2
  L21_2 = {}
  L22_2 = "delay"
  L23_2 = 45
  L24_2 = 3
  L25_2 = {}
  L26_2 = "Fiona-In-Mission-Contract-Oil01-143"
  L25_2[1] = L26_2
  L21_2[1] = L22_2
  L21_2[2] = L23_2
  L21_2[3] = L24_2
  L21_2[4] = L25_2
  L22_2 = {}
  L23_2 = "call"
  L24_2 = TowerDefenseFreebie
  L25_2 = {}
  L26_2 = A0_2
  L25_2[1] = L26_2
  L22_2[1] = L23_2
  L22_2[2] = L24_2
  L22_2[3] = L25_2
  L23_2 = {}
  L24_2 = "delay"
  L25_2 = 14
  L23_2[1] = L24_2
  L23_2[2] = L25_2
  L24_2 = {}
  L25_2 = "call"
  L26_2 = StartHeliAttack
  L27_2 = {}
  L28_2 = A0_2
  L27_2[1] = L28_2
  L24_2[1] = L25_2
  L24_2[2] = L26_2
  L24_2[3] = L27_2
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L3_2[5] = L8_2
  L3_2[6] = L9_2
  L3_2[7] = L10_2
  L3_2[8] = L11_2
  L3_2[9] = L12_2
  L3_2[10] = L13_2
  L3_2[11] = L14_2
  L3_2[12] = L15_2
  L3_2[13] = L16_2
  L3_2[14] = L17_2
  L3_2[15] = L18_2
  L3_2[16] = L19_2
  L3_2[17] = L20_2
  L3_2[18] = L21_2
  L3_2[19] = L22_2
  L3_2[20] = L23_2
  L3_2[21] = L24_2
  L2_2.tCmdList = L3_2
  L3_2 = {}
  L4_2 = {}
  L4_2.inPath = "oc001.obj2.pth.apc_in1"
  L4_2.defensePoint = "oc001.obj2.loc"
  L4_2.squadName = "oc001.sq2-1"
  L5_2 = {}
  L5_2.inPath = "oc001.obj2.pth.apc_in2"
  L5_2.outPath = "oc001.obj2.pth.apc_out2"
  L5_2.defensePoint = "oc001.obj2.loc"
  L5_2.squadName = "oc001.sq2-1"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L2_2.tAPCInfo = L3_2
  L3_2 = AttackWaves
  L4_2 = L3_2
  L3_2 = L3_2.Create
  L5_2 = A0_2
  L6_2 = L2_2
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  A0_2.curAttack = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.Obj_Site2_Complete
    L0_3(L1_3)
  end
  
  A1_2.fOnComplete = L3_2
  L3_2 = A0_2.exec
  L4_2 = L3_2
  L3_2 = L3_2.Start
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
  L3_2 = A0_2.curAttack
  L4_2 = L3_2
  L3_2 = L3_2.Start
  L3_2(L4_2)
  L4_2 = A0_2
  L3_2 = A0_2.SetupHeliTimeout
  L3_2(L4_2)
end

Obj_Site2_Defend = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.curAttack
  L2_2 = L1_2
  L1_2 = L1_2.Cleanup
  L1_2(L2_2)
  A0_2.curAttack = nil
  L1_2 = A0_2.heliAttack
  if L1_2 then
    L1_2 = A0_2.heliAttack
    L2_2 = L1_2
    L1_2 = L1_2.Cleanup
    L1_2(L2_2)
    A0_2.heliAttack = nil
  end
  L2_2 = A0_2
  L1_2 = A0_2.BuildingDestroyedCleanup
  L3_2 = "refinery_office02"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.ObjReturnExecutive
  L1_2(L2_2)
  L1_2 = MrxMusic
  L1_2 = L1_2.StopSpecialMusic
  L2_2 = "action"
  L1_2(L2_2)
end

Obj_Site2_Complete = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[OilCon001.Terms.Cancel03]"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.Cancel
  L1_2(L2_2)
end

DocumentsCaptured = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2._tEvents
  L2_2 = L2_2.eHeliTimeout
  L1_2(L2_2)
  L1_2 = A0_2._tEvents
  L1_2.eHeliTimeout = nil
  L1_2 = HeliAttack
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L3_2 = A0_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = "oc001.pth.heli.in1"
  L7_2 = "oc001.pth.heli.in2"
  L8_2 = "oc001.pth.heli.in3"
  L9_2 = "oc001.pth.heli.in4"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L4_2.tInPaths = L5_2
  L5_2 = {}
  L6_2 = "oc001.pth.heli.loop1"
  L7_2 = "oc001.pth.heli.loop2"
  L8_2 = "oc001.pth.heli.loop3"
  L9_2 = "oc001.pth.heli.loop4"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L4_2.tLoopPaths = L5_2
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  A0_2.heliAttack = L1_2
  L1_2 = A0_2.heliAttack
  L2_2 = L1_2
  L1_2 = L1_2.Start
  L1_2(L2_2)
end

StartHeliAttack = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = A0_2._tEvents
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = L0_1
  L5_2 = L5_2[1]
  L5_2 = L5_2.goalVal
  L5_2 = L5_2 * 0.6
  L5_2 = L5_2 * 12
  L6_2 = L0_1
  L6_2 = L6_2[1]
  L6_2 = L6_2.boxVal
  L5_2 = L5_2 / L6_2
  L4_2[1] = L5_2
  L5_2 = HeliTimeout
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.eHeliTimeout = L2_2
end

SetupHeliTimeout = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.curAttack
  L1_2.curCmd = 17
  L1_2 = A0_2.curAttack
  L1_2 = L1_2.attackObj
  if L1_2 then
    L1_2 = A0_2.curAttack
    L2_2 = L1_2
    L1_2 = L1_2.BlipAttackers
    L3_2 = false
    L1_2(L2_2, L3_2)
    L1_2 = A0_2.curAttack
    L2_2 = L1_2
    L1_2 = L1_2.WaveStagnated
    L1_2(L2_2)
  end
end

HeliTimeout = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2._tEvents
  L2_2 = L2_2.eTowerDefenseNag
  L1_2(L2_2)
  L1_2 = A0_2._tEvents
  L1_2.eTowerDefenseNag = nil
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "oc001.obj2.loc.supplyDrop"
  L1_2 = L1_2(L2_2)
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L5_2 = MrxCopterDrop
  L5_2 = L5_2.Create
  L6_2 = "OC"
  L7_2 = "Supply Drop (AA)"
  L8_2 = L2_2
  L9_2 = L3_2
  L10_2 = L4_2
  L11_2 = true
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  L7_2 = A0_2
  L6_2 = A0_2._CreateEvent
  L8_2 = Event
  L8_2 = L8_2.ObjectProximity
  L9_2 = {}
  L10_2 = L5_2
  L11_2 = L1_2
  L12_2 = "<"
  L13_2 = 20
  L14_2 = false
  L15_2 = true
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L9_2[3] = L12_2
  L9_2[4] = L13_2
  L9_2[5] = L14_2
  L9_2[6] = L15_2
  L10_2 = TowerDefenseFreebieVO
  L11_2 = {}
  L12_2 = A0_2
  L11_2[1] = L12_2
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  L7_2 = A0_2
  L6_2 = A0_2._PlayVo
  L8_2 = 0
  L9_2 = "OCMerc-In-Mission-Contract-Oil01-118"
  L6_2(L7_2, L8_2, L9_2)
  L6_2 = A0_2.curAttack
  if L6_2 then
    L6_2 = A0_2.curAttack
    L7_2 = L6_2
    L6_2 = L6_2.BlipAttackers
    L8_2 = false
    L6_2(L7_2, L8_2)
  end
end

TowerDefenseFreebie = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "OCMerc-In-Mission-Contract-Oil01-119"
  L4_2 = 0
  L5_2 = {}
  L6_2 = TowerDefenseAddFreebie
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = 0.5
  L7_2 = {}
  L7_2.mattias = "Mattias-In-Mission-Contract-Oil01-117"
  L7_2.jennifer = "Jennifer-In-Mission-Contract-Oil01-116"
  L7_2.chris = "Chris-In-Mission-Contract-Oil01-92"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L1_2(L2_2)
end

TowerDefenseFreebieVO = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Player
  L1_2 = L1_2.GetSecondaryCharacter
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = MrxSupportData
    L1_2 = L1_2.AddFreebie
    L2_2 = "OilCon001_Crate"
    L3_2 = 1
    L4_2 = Player
    L4_2 = L4_2.GetPrimaryPlayer
    L4_2 = L4_2()
    L1_2(L2_2, L3_2, L4_2)
    L1_2 = MrxSupportData
    L1_2 = L1_2.AddFreebie
    L2_2 = "OilCon001_Crate"
    L3_2 = 1
    L4_2 = Player
    L4_2 = L4_2.GetSecondaryPlayer
    L4_2 = L4_2()
    L1_2(L2_2, L3_2, L4_2)
  else
    L1_2 = MrxSupportData
    L1_2 = L1_2.AddFreebie
    L2_2 = "OilCon001_Crate"
    L3_2 = 2
    L4_2 = Player
    L4_2 = L4_2.GetPrimaryPlayer
    L4_2 = L4_2()
    L1_2(L2_2, L3_2, L4_2)
  end
end

TowerDefenseAddFreebie = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2._tEvents
  L2_2 = L2_2.eHeliTimeout
  L1_2(L2_2)
  L1_2 = A0_2._tEvents
  L1_2.eHeliTimeout = nil
  L1_2 = A0_2._tEvents
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 30
  L4_2[1] = L5_2
  L5_2 = A0_2._PlayVo
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = 0
  L9_2 = "Fiona-In-Mission-Contract-Oil01-102"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.eTowerDefenseNag = L2_2
end

TowerDefenseNag = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L3_2 = A0_2
  L2_2 = A0_2._StagingSetup
  L2_2(L3_2)
  L2_2 = _DestroyGate
  L3_2 = "_ocoutpost_wallgate 0x000dac4e"
  L2_2(L3_2)
  L2_2 = "OilExec-In-Mission-Contract-Oil01-19"
  L3_2 = Player
  L3_2 = L3_2.GetCurrentPlayers
  L3_2 = L3_2()
  if 1 < L3_2 then
    L2_2 = "OilExec-In-Mission-Contract-Oil01-85"
  end
  L3_2 = {}
  L3_2.nBaseDelay = 0
  L4_2 = {}
  L5_2 = Human
  L5_2 = L5_2.DoAction
  L6_2 = {}
  L7_2 = A0_2.exec
  L7_2 = L7_2.guid
  L8_2 = "SpeakGestureUB"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = {}
  L6_2 = L2_2
  L7_2 = A0_2.exec
  L7_2 = L7_2.guid
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = {}
  L7_2 = Human
  L7_2 = L7_2.DoAction
  L8_2 = {}
  L9_2 = A0_2.exec
  L9_2 = L9_2.guid
  L10_2 = "ExitAction"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = {}
  L7_2.mattias = "Mattias-In-Mission-Contract-Oil01-20"
  L7_2.jennifer = "Jennifer-In-Mission-Contract-Oil01-21"
  L7_2.chris = "Chris-In-Mission-Contract-Oil01-22"
  L8_2 = {}
  L9_2 = Human
  L9_2 = L9_2.DoAction
  L10_2 = {}
  L11_2 = A0_2.exec
  L11_2 = L11_2.guid
  L12_2 = "SpeakGestureUB"
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L9_2 = {}
  L10_2 = "OilExec-In-Mission-Contract-Oil01-23"
  L11_2 = A0_2.exec
  L11_2 = L11_2.guid
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L10_2 = {}
  L11_2 = Human
  L11_2 = L11_2.DoAction
  L12_2 = {}
  L13_2 = A0_2.exec
  L13_2 = L13_2.guid
  L14_2 = "ExitAction"
  L12_2[1] = L13_2
  L12_2[2] = L14_2
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L3_2[5] = L8_2
  L3_2[6] = L9_2
  L3_2[7] = L10_2
  L5_2 = A0_2
  L4_2 = A0_2.ObjDeliverExec
  L6_2 = L0_1
  L6_2 = L6_2[2]
  L7_2 = A0_2.Obj_Site3_Defend
  L8_2 = L3_2
  L9_2 = A1_2
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  L5_2 = A0_2
  L4_2 = A0_2._CreateEvent
  L6_2 = Event
  L6_2 = L6_2.ObjectProximity
  L7_2 = {}
  L8_2 = A0_2.exec
  L8_2 = L8_2.guid
  L9_2 = Pg
  L9_2 = L9_2.GetGuidByName
  L10_2 = "refinery_office03"
  L9_2 = L9_2(L10_2)
  L10_2 = "<"
  L11_2 = 50
  L12_2 = false
  L13_2 = false
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L7_2[5] = L12_2
  L7_2[6] = L13_2
  
  function L8_2()
    local L0_3, L1_3, L2_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = {}
    L2_3.mattias = "Mattias-In-Mission-Contract-Oil01-76"
    L2_3.jennifer = "Jennifer-In-Mission-Contract-Oil01-77"
    L2_3.chris = "Chris-In-Mission-Contract-Oil01-78"
    L1_3[1] = L2_3
    L0_3(L1_3)
  end
  
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L5_2 = _MoveOCSquad
  L6_2 = "oc001.obj1.ocsquad1"
  L7_2 = "oc001.obj2.loc"
  L5_2(L6_2, L7_2)
  L6_2 = A0_2
  L5_2 = A0_2.CreateMissionBoundaryDelayed
  L7_2 = {}
  L8_2 = L0_1
  L8_2 = L8_2[2]
  L8_2 = L8_2.dropoffPoint
  L7_2.sPoint = L8_2
  L8_2 = {}
  L9_2 = "Fiona-In-Mission-Contract-Oil01-137"
  L10_2 = "Fiona-In-Mission-Contract-Oil01-138"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L7_2.tExitVOs = L8_2
  L8_2 = {}
  L9_2 = "Fiona-In-Mission-Contract-Oil01-139"
  L8_2[1] = L9_2
  L7_2.tWarnVOs = L8_2
  L8_2 = DocumentsCaptured
  L7_2.fCallback = L8_2
  L5_2(L6_2, L7_2)
end

Obj_Site3_Goto = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2
  
  function L2_2()
    local L0_3, L1_3, L2_3
    L0_3 = A0_2
    L0_3 = L0_3.curAttack
    L1_3 = L0_3
    L0_3 = L0_3.Cleanup
    L0_3(L1_3)
    L0_3 = A0_2
    L0_3.curAttack = nil
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.BuildingDestroyedCleanup
    L2_3 = "refinery_office03"
    L0_3(L1_3, L2_3)
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.Obj_Site2_Goto
    L0_3(L1_3)
    L0_3 = MrxMusic
    L0_3 = L0_3.StopSpecialMusic
    L0_3()
  end
  
  A1_2.fOnComplete = L2_2
  L2_2 = A0_2.exec
  L3_2 = L2_2
  L2_2 = L2_2.Start
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
  L2_2 = Math
  L2_2 = L2_2.randf
  L3_2 = 150
  L4_2 = 180
  L2_2 = L2_2(L3_2, L4_2)
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = L2_2
  L6_2[1] = L7_2
  L7_2 = SpawnPipeRunners
  L3_2(L4_2, L5_2, L6_2, L7_2)
  L3_2 = {}
  L3_2.office = "refinery_office03"
  L4_2 = {}
  L5_2 = {}
  L6_2 = "oc001.obj3.pth.atk01"
  L7_2 = "oc001.obj3.pth.atk02"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = {}
  L7_2 = "oc001.obj3.pth.atk21"
  L8_2 = "oc001.obj3.pth.atk22"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L3_2.atkPaths = L4_2
  L4_2 = {}
  L5_2 = "oc001.obj3.loc.vz1"
  L6_2 = "oc001.obj3.loc.vz2"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L3_2.atkPoints = L4_2
  L4_2 = {}
  L5_2 = "oc001.obj3.loc.atk1"
  L6_2 = "oc001.obj3.loc.atk2"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L3_2.defPoints = L4_2
  L4_2 = {}
  L5_2 = 180
  L6_2 = 150
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L3_2.atkSpawnDist = L4_2
  L4_2 = {}
  L5_2 = 80
  L6_2 = 70
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L3_2.atkRanges = L4_2
  L3_2.waveVal = 5
  L4_2 = {}
  L5_2 = {}
  L6_2 = "apc"
  L7_2 = "truck"
  L8_2 = 1
  L9_2 = 10
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L6_2 = {}
  L7_2 = "setpath"
  L8_2 = {}
  L9_2 = 1
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = {}
  L8_2 = "delay"
  L9_2 = 20
  L10_2 = 1
  L11_2 = {}
  L12_2 = "Fiona-In-Mission-Contract-Oil01-93"
  L11_2[1] = L12_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L8_2 = {}
  L9_2 = "wave"
  L8_2[1] = L9_2
  L9_2 = {}
  L10_2 = "wave"
  L9_2[1] = L10_2
  L10_2 = {}
  L11_2 = "wave"
  L10_2[1] = L11_2
  L11_2 = {}
  L12_2 = "setpath"
  L13_2 = {}
  L14_2 = 2
  L13_2[1] = L14_2
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L12_2 = {}
  L13_2 = "apc"
  L14_2 = "truck"
  L15_2 = 2
  L16_2 = 5
  L12_2[1] = L13_2
  L12_2[2] = L14_2
  L12_2[3] = L15_2
  L12_2[4] = L16_2
  L13_2 = {}
  L14_2 = "call"
  L15_2 = _MoveOCSquad
  L16_2 = {}
  L17_2 = "oc001.obj1.ocsquad2"
  L18_2 = "oc001.obj3.loc.vz2"
  L16_2[1] = L17_2
  L16_2[2] = L18_2
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L13_2[3] = L16_2
  L14_2 = {}
  L15_2 = "call"
  L16_2 = _MoveOCBoatSoldier
  L17_2 = {}
  L18_2 = false
  L17_2[1] = L18_2
  L14_2[1] = L15_2
  L14_2[2] = L16_2
  L14_2[3] = L17_2
  L15_2 = {}
  L16_2 = "delay"
  L17_2 = 60
  L18_2 = 2
  L19_2 = {}
  L20_2 = "Fiona-In-Mission-Contract-Oil01-95"
  L19_2[1] = L20_2
  L15_2[1] = L16_2
  L15_2[2] = L17_2
  L15_2[3] = L18_2
  L15_2[4] = L19_2
  L16_2 = {}
  L17_2 = "wave"
  L16_2[1] = L17_2
  L17_2 = {}
  L18_2 = "wave"
  L17_2[1] = L18_2
  L18_2 = {}
  L19_2 = "wave"
  L18_2[1] = L19_2
  L19_2 = {}
  L20_2 = "wave"
  L19_2[1] = L20_2
  L20_2 = {}
  L21_2 = "setpath"
  L22_2 = {}
  L23_2 = 1
  L22_2[1] = L23_2
  L20_2[1] = L21_2
  L20_2[2] = L22_2
  L21_2 = {}
  L22_2 = "apc"
  L23_2 = "truck"
  L24_2 = 1
  L25_2 = 5
  L21_2[1] = L22_2
  L21_2[2] = L23_2
  L21_2[3] = L24_2
  L21_2[4] = L25_2
  L22_2 = {}
  L23_2 = "call"
  L24_2 = _MoveOCSquad
  L25_2 = {}
  L26_2 = "oc001.obj1.ocsquad2"
  L27_2 = "oc001.obj3.loc.vz1"
  L25_2[1] = L26_2
  L25_2[2] = L27_2
  L22_2[1] = L23_2
  L22_2[2] = L24_2
  L22_2[3] = L25_2
  L23_2 = {}
  L24_2 = "call"
  L25_2 = _MoveOCBoatSoldier
  L26_2 = {}
  L27_2 = true
  L26_2[1] = L27_2
  L23_2[1] = L24_2
  L23_2[2] = L25_2
  L23_2[3] = L26_2
  L24_2 = {}
  L25_2 = "delay"
  L26_2 = 12
  L27_2 = 1
  L28_2 = {}
  L29_2 = "Fiona-In-Mission-Contract-Oil01-96"
  L28_2[1] = L29_2
  L24_2[1] = L25_2
  L24_2[2] = L26_2
  L24_2[3] = L27_2
  L24_2[4] = L28_2
  L25_2 = {}
  L26_2 = "wave"
  L25_2[1] = L26_2
  L26_2 = {}
  L27_2 = "wave"
  L26_2[1] = L27_2
  L27_2 = {}
  L28_2 = "wave"
  L27_2[1] = L28_2
  L28_2 = {}
  L29_2 = "wave"
  L28_2[1] = L29_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L4_2[7] = L11_2
  L4_2[8] = L12_2
  L4_2[9] = L13_2
  L4_2[10] = L14_2
  L4_2[11] = L15_2
  L4_2[12] = L16_2
  L4_2[13] = L17_2
  L4_2[14] = L18_2
  L4_2[15] = L19_2
  L4_2[16] = L20_2
  L4_2[17] = L21_2
  L4_2[18] = L22_2
  L4_2[19] = L23_2
  L4_2[20] = L24_2
  L4_2[21] = L25_2
  L4_2[22] = L26_2
  L4_2[23] = L27_2
  L4_2[24] = L28_2
  L3_2.tCmdList = L4_2
  L4_2 = {}
  L5_2 = {}
  L5_2.inPath = "oc001.obj3.pth.apc_in1"
  L5_2.outPath = "oc001.obj3.pth.apc_out1"
  L5_2.defensePoint = "oc001.obj3.loc.vz1"
  L5_2.squadName = "oc001.sq1-1"
  L6_2 = {}
  L6_2.inPath = "oc001.obj3.pth.apc_in2"
  L6_2.outPath = "oc001.obj3.pth.apc_out2"
  L6_2.defensePoint = "oc001.obj3.loc.vz2"
  L6_2.squadName = "oc001.sq1-2"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L3_2.tAPCInfo = L4_2
  L4_2 = AttackWaves
  L5_2 = L4_2
  L4_2 = L4_2.Create
  L6_2 = A0_2
  L7_2 = L3_2
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  A0_2.curAttack = L4_2
  L4_2 = MrxVoSequence
  L4_2 = L4_2.Start
  L5_2 = {}
  L6_2 = {}
  L7_2 = "OilExec-In-Mission-Contract-Oil01-56"
  L8_2 = A0_2.exec
  L8_2 = L8_2.guid
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = {}
  L8_2 = A0_2.curAttack
  L8_2 = L8_2.Start
  L9_2 = {}
  L10_2 = A0_2.curAttack
  L9_2[1] = L10_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2(L5_2)
end

Obj_Site3_Defend = L1_1

function L1_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = Pg
  L0_2 = L0_2.GetGuidByName
  L1_2 = "_industrial_att_pipelargeshort 0x000eef58"
  L0_2 = L0_2(L1_2)
  L1_2 = Object
  L1_2 = L1_2.IsAlive
  L2_2 = L0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = Pg
    L1_2 = L1_2.GetGuidByName
    L2_2 = "oc001.obj3.pth.pipe1"
    L1_2 = L1_2(L2_2)
    
    function L2_2(A0_3, A1_3, A2_3)
      local L3_3, L4_3
      L3_3 = Ai
      L3_3 = L3_3.Goal
      L4_3 = {}
      L4_3.AIGuid = A0_3
      L4_3.Goal = "PathMove"
      L4_3.Target = A1_3
      L4_3.Haste = A2_3
      L4_3.Mode = "OneWay"
      L4_3.Priority = "HiPri"
      L3_3 = L3_3(L4_3)
    end
    
    SoldierRun = L2_2
    
    function L2_2(A0_3, A1_3, A2_3)
      local L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3
      L3_3 = Pg
      L3_3 = L3_3.GetGuidByName
      L4_3 = A0_3
      L3_3 = L3_3(L4_3)
      L4_3 = Object
      L4_3 = L4_3.GetPosition
      L5_3 = L3_3
      L4_3, L5_3, L6_3 = L4_3(L5_3)
      L7_3 = Pg
      L7_3 = L7_3.Spawn
      L8_3 = "VZ Soldier"
      L9_3 = L4_3
      L10_3 = L5_3
      L11_3 = L6_3
      L12_3 = Object
      L12_3 = L12_3.GetYaw
      L13_3 = L3_3
      L12_3 = L12_3(L13_3)
      L13_3 = false
      L14_3 = true
      L7_3 = L7_3(L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3)
      L8_3 = Event
      L8_3 = L8_3.Create
      L9_3 = Event
      L9_3 = L9_3.ObjectHibernation
      L10_3 = {}
      L11_3 = L7_3
      L12_3 = "awake"
      L10_3[1] = L11_3
      L10_3[2] = L12_3
      L11_3 = SoldierRun
      L12_3 = {}
      L13_3 = L7_3
      L14_3 = A1_3
      L15_3 = A2_3
      L12_3[1] = L13_3
      L12_3[2] = L14_3
      L12_3[3] = L15_3
      L8_3 = L8_3(L9_3, L10_3, L11_3, L12_3)
    end
    
    SoldierSpawn = L2_2
    L2_2 = SoldierSpawn
    L3_2 = "oc001.obj3.loc.pipespawn1"
    L4_2 = L1_2
    L5_2 = 0.5
    L2_2(L3_2, L4_2, L5_2)
    L2_2 = SoldierSpawn
    L3_2 = "oc001.obj3.loc.pipespawn2"
    L4_2 = L1_2
    L5_2 = 0.45
    L2_2(L3_2, L4_2, L5_2)
  end
end

SpawnPipeRunners = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = {}
  L1_2.name = "UP HQ"
  L1_2.fDist = 6
  L1_2.sDesc = "[OilCon001.Objectives.004]"
  L1_2.dropoffPoint = "oc001.loc.finish"
  L2_2 = SetupReturnDriveBanter
  L1_2.fAttachCallback = L2_2
  L3_2 = A0_2
  L2_2 = A0_2.ObjDeliverExec
  L4_2 = L1_2
  L5_2 = ObjReturnExecutiveComplete
  L6_2 = {}
  L7_2 = {}
  L8_2 = "OilExec-In-Mission-Contract-Oil01-65"
  L9_2 = A0_2.exec
  L9_2 = L9_2.guid
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L6_2[1] = L7_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L2_2 = MrxFactionManager
  L2_2 = L2_2.DisableReporting
  L3_2 = false
  L2_2(L3_2)
  L2_2 = A0_2.missionBoundary
  L3_2 = L2_2
  L2_2 = L2_2.Cancel
  L2_2(L3_2)
  A0_2.missionBoundary = nil
  L2_2 = Event
  L2_2 = L2_2.Delete
  L3_2 = A0_2._tEvents
  L3_2 = L3_2.eMissionBoundary
  L2_2(L3_2)
  L2_2 = A0_2._tEvents
  L2_2.eMissionBoundary = nil
end

ObjReturnExecutive = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L1_3.nBaseDelay = 0.4
    L2_3 = {}
    L3_3 = "OilExec-In-Mission-Contract-Oil01-126"
    L4_3 = A0_2
    L4_3 = L4_3.exec
    L4_3 = L4_3.guid
    L2_3[1] = L3_3
    L2_3[2] = L4_3
    L3_3 = {}
    L3_3.mattias = "Mattias-In-Mission-Contract-Oil01-104"
    L3_3.jennifer = "Jennifer-In-Mission-Contract-Oil01-105"
    L3_3.chris = "Chris-In-Mission-Contract-Oil01-106"
    L4_3 = {}
    L5_3 = "OilExec-In-Mission-Contract-Oil01-127"
    L6_3 = A0_2
    L6_3 = L6_3.exec
    L6_3 = L6_3.guid
    L4_3[1] = L5_3
    L4_3[2] = L6_3
    L5_3 = {}
    L5_3.mattias = "Mattias-In-Mission-Contract-Oil01-107"
    L5_3.jennifer = "Jennifer-In-Mission-Contract-Oil01-108"
    L5_3.chris = "Chris-In-Mission-Contract-Oil01-109"
    L6_3 = {}
    L7_3 = "OilExec-In-Mission-Contract-Oil01-130"
    L8_3 = A0_2
    L8_3 = L8_3.exec
    L8_3 = L8_3.guid
    L6_3[1] = L7_3
    L6_3[2] = L8_3
    L7_3 = {}
    L7_3.mattias = "Mattias-In-Mission-Contract-Oil01-110"
    L7_3.jennifer = "Jennifer-In-Mission-Contract-Oil01-111"
    L7_3.chris = "Chris-In-Mission-Contract-Oil01-112"
    L8_3 = 0
    L9_3 = {}
    L10_3 = "OilExec-In-Mission-Contract-Oil01-131"
    L11_3 = A0_2
    L11_3 = L11_3.exec
    L11_3 = L11_3.guid
    L9_3[1] = L10_3
    L9_3[2] = L11_3
    L10_3 = 0
    L11_3 = {}
    L12_3 = "OilExec-In-Mission-Contract-Oil01-132"
    L13_3 = A0_2
    L13_3 = L13_3.exec
    L13_3 = L13_3.guid
    L11_3[1] = L12_3
    L11_3[2] = L13_3
    L12_3 = {}
    L12_3.mattias = "Mattias-In-Mission-Contract-Oil01-113"
    L12_3.jennifer = "Jennifer-In-Mission-Contract-Oil01-114"
    L12_3.chris = "Chris-In-Mission-Contract-Oil01-115"
    L13_3 = 0
    L14_3 = {}
    L15_3 = "OilExec-In-Mission-Contract-Oil01-133"
    L16_3 = A0_2
    L16_3 = L16_3.exec
    L16_3 = L16_3.guid
    L14_3[1] = L15_3
    L14_3[2] = L16_3
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L1_3[3] = L4_3
    L1_3[4] = L5_3
    L1_3[5] = L6_3
    L1_3[6] = L7_3
    L1_3[7] = L8_3
    L1_3[8] = L9_3
    L1_3[9] = L10_3
    L1_3[10] = L11_3
    L1_3[11] = L12_3
    L1_3[12] = L13_3
    L1_3[13] = L14_3
    L0_3(L1_3)
  end
  
  L5_2 = A0_2._tEvents
  L5_2 = L5_2.eReturnDriveBanter
  if not L5_2 and A3_2 then
    L5_2 = MrxVoSequence
    L5_2 = L5_2.Start
    L6_2 = {}
    L7_2 = {}
    L7_2.mattias = "Mattias-In-Mission-Contract-Oil01-68"
    L7_2.jennifer = "Jennifer-In-Mission-Contract-Oil01-69"
    L7_2.chris = "Chris-In-Mission-Contract-Oil01-70"
    L8_2 = 0
    L9_2 = {}
    L10_2 = Human
    L10_2 = L10_2.DoAction
    L11_2 = {}
    L12_2 = A0_2.exec
    L12_2 = L12_2.guid
    L13_2 = "SpeakGestureUB"
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L10_2 = {}
    L11_2 = "OilExec-In-Mission-Contract-Oil01-71"
    L12_2 = A0_2.exec
    L12_2 = L12_2.guid
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L11_2 = {}
    L12_2 = Human
    L12_2 = L12_2.DoAction
    L13_2 = {}
    L14_2 = A0_2.exec
    L14_2 = L14_2.guid
    L15_2 = "ExitAction"
    L13_2[1] = L14_2
    L13_2[2] = L15_2
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L12_2 = 0.5
    L13_2 = {}
    L13_2.mattias = "Mattias-In-Mission-Contract-Oil01-86"
    L13_2.jennifer = "Jennifer-In-Mission-Contract-Oil01-87"
    L13_2.chris = "Chris-In-Mission-Contract-Oil01-74"
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L6_2[4] = L10_2
    L6_2[5] = L11_2
    L6_2[6] = L12_2
    L6_2[7] = L13_2
    L5_2(L6_2)
    L5_2 = A0_2._tEvents
    L6_2 = Event
    L6_2 = L6_2.Create
    L7_2 = Event
    L7_2 = L7_2.ObjectProximity
    L8_2 = {}
    L9_2 = A0_2.exec
    L9_2 = L9_2.guid
    L10_2 = Pg
    L10_2 = L10_2.GetGuidByName
    L11_2 = "oc001.loc.finish"
    L10_2 = L10_2(L11_2)
    L11_2 = "<"
    L12_2 = 1050
    L13_2 = false
    L14_2 = true
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L8_2[4] = L12_2
    L8_2[5] = L13_2
    L8_2[6] = L14_2
    L9_2 = L4_2
    L6_2 = L6_2(L7_2, L8_2, L9_2)
    L5_2.eReturnDriveBanter = L6_2
  end
end

SetupReturnDriveBanter = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = Object
  L1_2 = L1_2.InSeat
  L2_2 = A0_2.exec
  L2_2 = L2_2.guid
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L2_2 = Vehicle
    L2_2 = L2_2.Exit
    L3_2 = L1_2
    L4_2 = A0_2.exec
    L4_2 = L4_2.guid
    L2_2(L3_2, L4_2)
  end
  
  function L2_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3
    L1_3 = Ai
    L1_3 = L1_3.Goal
    L2_3 = {}
    L3_3 = A0_3.exec
    L3_3 = L3_3.guid
    L2_3.AIGuid = L3_3
    L2_3.Goal = "MoveTo"
    L3_3 = Pg
    L3_3 = L3_3.GetGuidByName
    L4_3 = "Starter_Oil0_Start1"
    L3_3 = L3_3(L4_3)
    L2_3.Target = L3_3
    L2_3.Haste = 0.65
    L2_3.Priority = "HiPri"
    L3_3 = MissionComplete
    L2_3.Callback = L3_3
    L3_3 = {}
    L4_3 = A0_3
    L3_3[1] = L4_3
    L2_3.CallbackData = L3_3
    L1_3 = L1_3(L2_3)
  end
  
  L3_2 = MrxVoSequence
  L3_2 = L3_2.Start
  L4_2 = {}
  L5_2 = {}
  L6_2 = Human
  L6_2 = L6_2.DoAction
  L7_2 = {}
  L8_2 = A0_2.exec
  L8_2 = L8_2.guid
  L9_2 = "SpeakGestureUB"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = {}
  L7_2 = "OilExec-In-Mission-Contract-Oil01-66"
  L8_2 = A0_2.exec
  L8_2 = L8_2.guid
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = {}
  L8_2 = Human
  L8_2 = L8_2.DoAction
  L9_2 = {}
  L10_2 = A0_2.exec
  L10_2 = L10_2.guid
  L11_2 = "ExitAction"
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L8_2 = {}
  L9_2 = L2_2
  L10_2 = {}
  L11_2 = A0_2
  L10_2[1] = L11_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L3_2(L4_2)
end

ObjReturnExecutiveComplete = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Object
  L1_2 = L1_2.FadeOut
  L2_2 = A0_2.exec
  L2_2 = L2_2.guid
  L3_2 = 1
  L4_2 = true
  L1_2(L2_2, L3_2, L4_2)
  L2_2 = A0_2
  L1_2 = A0_2.Complete
  L1_2(L2_2)
end

MissionComplete = L1_1
L1_1 = {}
L2_1 = {}
L2_1.template = "M151 .50Cal (VZ) (DriverGunner)"
L2_1.speed = 0.5
L2_1.threat = 5
L1_1.jeep = L2_1
L2_1 = {}
L2_1.template = "M35 (Guntruck) (VZ) (Full)"
L2_1.speed = 0.45
L2_1.threat = 10
L1_1.guntruck = L2_1
L2_1 = {}
L2_1.template = "M35 (Cargo) (VZ) (Full RPG)"
L2_1.speed = 0.5
L2_1.threat = 5
L1_1.truck = L2_1
L2_1 = {}
L2_1.template = "M113 (VZ) (Full RPG)"
L2_1.speed = 1
L2_1.threat = 12
L1_1.apc = L2_1
L2_1 = {}
L2_1.template = "Scorpion90 (Driver)"
L2_1.speed = 0.9
L2_1.threat = 0
L1_1.tank = L2_1
L2_1 = {}
L2_1.template = "Alouette3 Attack (VZ) (Full)"
L2_1.speed = 1
L2_1.threat = 0
L2_1.loopspeed = 0.6
L1_1.heli = L2_1
vehInfo = L1_1
L1_1 = {}
AttackWaves = L1_1
L1_1 = AttackWaves

function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  if not A2_2 then
    return
  end
  L3_2 = setmetatable
  L4_2 = A2_2
  L5_2 = A0_2
  L3_2(L4_2, L5_2)
  A0_2.__index = A0_2
  A2_2.parent = A1_2
  L3_2 = A2_2.kMaxThreat
  if not L3_2 then
    L3_2 = 200
  end
  A2_2.kMaxThreat = L3_2
  A2_2.curCmd = 0
  A2_2.curThreat = 0
  L3_2 = {}
  A2_2.tVehicleEvents = L3_2
  A1_2.curWaveBonus = 0
  L3_2 = ObjectFilter
  L3_2 = L3_2.Create
  L3_2 = L3_2()
  L4_2 = ObjectFilter
  L4_2 = L4_2.SetFilter
  L5_2 = L3_2
  L6_2 = "human"
  L4_2(L5_2, L6_2)
  L4_2 = Event
  L4_2 = L4_2.CreatePersistent
  L5_2 = Event
  L5_2 = L5_2.ObjectDeath
  L6_2 = {}
  L7_2 = L3_2
  L6_2[1] = L7_2
  L7_2 = A2_2.HumanDied
  L8_2 = {}
  L9_2 = A2_2
  L8_2[1] = L9_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  A2_2.eHumanThreat = L4_2
  return A2_2
end

L1_1.Create = L2_1
L1_1 = AttackWaves

function L2_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxMusic
  L1_2 = L1_2.PlaySpecialMusic
  L2_2 = "mu_fac_oc_threat_01"
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.ProcessNextCmd
  L1_2(L2_2)
end

L1_1.Start = L2_1
L1_1 = AttackWaves

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.eHumanThreat
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.eSpawnNextWave
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.eDelayTimer
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.eStagnateTimer
  L1_2(L2_2)
  L1_2 = A0_2.oDelayProx
  if L1_2 then
    L1_2 = A0_2.oDelayProx
    L2_2 = L1_2
    L1_2 = L1_2.Complete
    L1_2(L2_2)
    A0_2.oDelayProx = nil
  end
  L1_2 = pairs
  L2_2 = A0_2.tVehicleEvents
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L5_2.moveGoal
    if L6_2 then
      L5_2.moveGoal = nil
    end
    L6_2 = pairs
    L7_2 = L5_2
    L6_2, L7_2, L8_2 = L6_2(L7_2)
    for L9_2, L10_2 in L6_2, L7_2, L8_2 do
      L11_2 = Event
      L11_2 = L11_2.Delete
      L12_2 = L10_2
      L11_2(L12_2)
    end
  end
  L1_2 = A0_2.attackObj
  if L1_2 then
    L1_2 = A0_2.attackObj
    L2_2 = L1_2
    L1_2 = L1_2.Cancel
    L1_2(L2_2)
    A0_2.attackObj = nil
  end
  L1_2 = A0_2.curApc
  if L1_2 then
    L1_2 = A0_2.curApc
    L2_2 = L1_2
    L1_2 = L1_2.Cleanup
    L1_2(L2_2)
    A0_2.curApc = nil
  end
end

L1_1.Cleanup = L2_1
L1_1 = AttackWaves

function L2_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = A0_2.curThreat
  L2_2 = L2_2 + A1_2
  A0_2.curThreat = L2_2
  L2_2 = A0_2.curThreat
  L3_2 = A0_2.kMaxThreat
  if L2_2 > L3_2 then
    L2_2 = A0_2.kMaxThreat
    A0_2.curThreat = L2_2
  else
    L2_2 = A0_2.curThreat
    if L2_2 < 0 then
      A0_2.curThreat = 0
    end
  end
end

L1_1.UpdateThreat = L2_1
L1_1 = AttackWaves

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = gbDebug
  if L1_2 then
    L1_2 = Hud
    L1_2 = L1_2.ObjectiveTray
    L2_2 = L1_2
    L1_2 = L1_2.SetSlotToText
    L3_2 = {}
    L3_2.nSlot = 3
    L4_2 = "[yellow]Threat: "
    L5_2 = A0_2.curThreat
    L4_2 = L4_2 .. L5_2
    L3_2.sText = L4_2
    L1_2(L2_2, L3_2)
  end
end

L1_1.UpdateDisplay = L2_1
L1_1 = AttackWaves

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  if A1_2 then
    L2_2 = A0_2.bBlipAttackers
    if not L2_2 then
      L2_2 = A0_2.attackObj
      if L2_2 then
        L2_2 = A0_2.attackObj
        L3_2 = L2_2
        L2_2 = L2_2.Configure
        L4_2 = {}
        L4_2.bDspBlp = true
        L2_2(L3_2, L4_2)
        A0_2.bBlipAttackers = A1_2
      end
    end
  end
end

L1_1.BlipAttackers = L2_1
L1_1 = AttackWaves

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = A0_2.curCmd
  L1_2 = L1_2 + 1
  A0_2.curCmd = L1_2
  L1_2 = A0_2.tCmdList
  L2_2 = A0_2.curCmd
  L1_2 = L1_2[L2_2]
  if not L1_2 then
    return
  end
  L2_2 = L1_2[1]
  if L2_2 == "wave" then
    L3_2 = A0_2
    L2_2 = A0_2.SpawnNextWave
    L2_2(L3_2)
  else
    L2_2 = L1_2[1]
    if L2_2 == "setpath" then
      L3_2 = A0_2
      L2_2 = A0_2.SetPaths
      L4_2 = L1_2[2]
      L5_2 = L1_2[3]
      L2_2(L3_2, L4_2, L5_2)
    else
      L2_2 = L1_2[1]
      if L2_2 == "delay" then
        L3_2 = A0_2
        L2_2 = A0_2.DelayCmd
        L4_2 = L1_2[2]
        L5_2 = L1_2[3]
        L6_2 = L1_2[4]
        L2_2(L3_2, L4_2, L5_2, L6_2)
      else
        L2_2 = L1_2[1]
        if L2_2 == "apc" then
          L3_2 = A0_2
          L2_2 = A0_2.SpawnApc
          L4_2 = L1_2[2]
          L5_2 = L1_2[3]
          L6_2 = L1_2[4]
          L2_2(L3_2, L4_2, L5_2, L6_2)
        else
          L2_2 = L1_2[1]
          if L2_2 == "call" then
            L2_2 = MrxUtil
            L2_2 = L2_2.CallWithOptionalArgs
            L3_2 = L1_2[2]
            L4_2 = L1_2[3]
            L2_2(L3_2, L4_2)
            L3_2 = A0_2
            L2_2 = A0_2.ProcessNextCmd
            L2_2(L3_2)
          else
          end
        end
      end
    end
  end
end

L1_1.ProcessNextCmd = L2_1
L1_1 = AttackWaves

function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = #A1_2
  if L3_2 == 1 then
    L3_2 = A1_2[1]
    A0_2.curPoints = L3_2
    L3_2 = A0_2.SpawnOneSquad
    A0_2.spawnFn = L3_2
  else
    A0_2.curPoints = A1_2
    L3_2 = A0_2.SpawnManySquads
    A0_2.spawnFn = L3_2
  end
  if A2_2 then
    L3_2 = table
    L3_2 = L3_2.insert
    L4_2 = A2_2
    L5_2 = {}
    L6_2 = A0_2.ProcessNextCmd
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L3_2(L4_2, L5_2)
    L3_2 = MrxVoSequence
    L3_2 = L3_2.Start
    L4_2 = A2_2
    L3_2(L4_2)
  else
    L4_2 = A0_2
    L3_2 = A0_2.ProcessNextCmd
    L3_2(L4_2)
  end
end

L1_1.SetPaths = L2_1
L1_1 = AttackWaves

function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = Event
  L4_2 = L4_2.Delete
  L5_2 = A0_2.eDelayTimer
  L4_2(L5_2)
  L4_2 = A0_2.oDelayProx
  if L4_2 then
    L4_2 = A0_2.oDelayProx
    L5_2 = L4_2
    L4_2 = L4_2.Complete
    L4_2(L5_2)
  end
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = A1_2
  L6_2[1] = L7_2
  L7_2 = A0_2._DelayCmdComplete
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  A0_2.eDelayTimer = L4_2
  if A2_2 then
    L4_2 = A0_2.parent
    L5_2 = L4_2
    L4_2 = L4_2.CreateChild
    L6_2 = {}
    L6_2.sName = "oc001 defend point"
    L6_2.sModuleName = "MrxTaskObjectiveDeliver"
    L7_2 = A0_2.defPoints
    L7_2 = L7_2[A2_2]
    L6_2.vDestLoc = L7_2
    L6_2.fDist = 12
    L6_2.bXZOnly = false
    L7_2 = Player
    L7_2 = L7_2.GetAnyCharacter
    L7_2 = L7_2()
    L6_2.vTgtInclude = L7_2
    L6_2.bStop = false
    L6_2.sDspShortDesc = "[OilCon001.Objectives.goto]"
    L6_2.bDspMsg = false
    L6_2.vVoSeqOnAdd = A3_2
    
    function L7_2()
      local L0_3, L1_3
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._DelayCmdComplete
      L0_3(L1_3)
    end
    
    L6_2.fOnComplete = L7_2
    L4_2 = L4_2(L5_2, L6_2)
    A0_2.oDelayProx = L4_2
  end
end

L1_1.DelayCmd = L2_1
L1_1 = AttackWaves

function L2_1(A0_2)
  local L1_2, L2_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.eDelayTimer
  L1_2(L2_2)
  L1_2 = A0_2.oDelayProx
  if L1_2 then
    L1_2 = A0_2.oDelayProx
    L2_2 = L1_2
    L1_2 = L1_2.Cancel
    L1_2(L2_2)
    A0_2.oDelayProx = nil
  end
  L2_2 = A0_2
  L1_2 = A0_2.ProcessNextCmd
  L1_2(L2_2)
end

L1_1._DelayCmdComplete = L2_1
L1_1 = AttackWaves

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = math
  L1_2 = L1_2.randf
  L2_2 = 0.8
  L3_2 = 1.5
  L1_2 = L1_2(L2_2, L3_2)
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = L1_2
  L4_2[1] = L5_2
  L5_2 = AttackWaves
  L5_2 = L5_2.SetupObjective
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  A0_2.eSpawnNextWave = L2_2
end

L1_1.SpawnNextWave = L2_1
L1_1 = AttackWaves

function L2_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.parent
  L2_2 = A0_2.parent
  L2_2 = L2_2.curWaveBonus
  L3_2 = A0_2.waveVal
  L2_2 = L2_2 + L3_2
  L1_2.curWaveBonus = L2_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.eStagnateTimer
  L1_2(L2_2)
  A0_2.eStagnateTimer = nil
end

L1_1.WaveCompleted = L2_1
L1_1 = AttackWaves

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  A0_2.eStagnateTimer = nil
  L1_2 = pairs
  L2_2 = A0_2.tAttackers
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = A0_2.tVehicleEvents
    L6_2 = L6_2[L5_2]
    if L6_2 then
      L7_2 = pairs
      L8_2 = L6_2
      L7_2, L8_2, L9_2 = L7_2(L8_2)
      for L10_2, L11_2 in L7_2, L8_2, L9_2 do
        L12_2 = Event
        L12_2 = L12_2.Delete
        L13_2 = L11_2
        L12_2(L13_2)
      end
      L7_2 = A0_2.tVehicleEvents
      L7_2[L5_2] = nil
    end
  end
  L1_2 = A0_2.attackObj
  L2_2 = L1_2
  L1_2 = L1_2.Complete
  L1_2(L2_2)
end

L1_1.WaveStagnated = L2_1
L1_1 = AttackWaves

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  A0_2.tAttackers = nil
  L1_2 = {}
  A0_2.tAttackers = L1_2
  L1_2 = A0_2.spawnFn
  if not L1_2 then
    return
  end
  L1_2 = A0_2.spawnFn
  L2_2 = A0_2
  L3_2 = A0_2.curPoints
  L1_2(L2_2, L3_2)
  L1_2 = A0_2.attackObj
  if L1_2 then
    L1_2 = A0_2.attackObj
    L2_2 = L1_2
    L1_2 = L1_2.Cancel
    L1_2(L2_2)
  end
  A0_2.bBlipAttackers = false
  L1_2 = A0_2.parent
  L2_2 = L1_2
  L1_2 = L1_2.CreateChild
  L3_2 = {}
  L3_2.sName = "INTERNAL OBJ: wave death"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L3_2.bDspMsg = false
  L3_2.bDspDescPda = false
  L3_2.bDspBlp = false
  L3_2.bDspBlpWld = false
  L3_2.bDspBlpPda = false
  L4_2 = A0_2.tAttackers
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[OilCon001.Objectives.attackwaves]"
  
  function L4_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
    L1_3 = A0_2
    L1_3 = L1_3.tVehicleEvents
    L1_3 = L1_3[A0_3]
    L2_3 = L1_3.moveGoal
    if L2_3 then
      L1_3.moveGoal = nil
    end
    L2_3 = pairs
    L3_3 = L1_3
    L2_3, L3_3, L4_3 = L2_3(L3_3)
    for L5_3, L6_3 in L2_3, L3_3, L4_3 do
      L7_3 = Event
      L7_3 = L7_3.Delete
      L8_3 = L6_3
      L7_3(L8_3)
    end
    L2_3 = A0_2
    L2_3 = L2_3.tVehicleEvents
    L2_3[A0_3] = nil
    L2_3 = A0_2
    L2_3 = L2_3.tAttackers
    L2_3 = #L2_3
    if 1 < L2_3 then
      L3_3 = A0_2
      L3_3 = L3_3.attackObj
      L4_3 = L3_3
      L3_3 = L3_3.GetProgressCompleted
      L3_3 = L3_3(L4_3)
      L3_3 = L2_3 - L3_3
      if L3_3 == 1 then
        L3_3 = A0_2
        L3_3 = L3_3.eStagnateTimer
        if L3_3 then
          L3_3 = Event
          L3_3 = L3_3.Delete
          L4_3 = A0_2
          L4_3 = L4_3.eStagnateTimer
          L3_3(L4_3)
        end
        L3_3 = A0_2
        L4_3 = Event
        L4_3 = L4_3.Create
        L5_3 = Event
        L5_3 = L5_3.TimerRelative
        L6_3 = {}
        L7_3 = 18
        L6_3[1] = L7_3
        L7_3 = AttackWaves
        L7_3 = L7_3.WaveStagnated
        L8_3 = {}
        L9_3 = A0_2
        L8_3[1] = L9_3
        L4_3 = L4_3(L5_3, L6_3, L7_3, L8_3)
        L3_3.eStagnateTimer = L4_3
      end
    end
  end
  
  L3_2.fOnPartComplete = L4_2
  
  function L4_2()
    local L0_3, L1_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.WaveCompleted
    L0_3(L1_3)
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.ProcessNextCmd
    L0_3(L1_3)
  end
  
  L3_2.fOnComplete = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  A0_2.attackObj = L1_2
end

L1_1.SetupObjective = L2_1
L1_1 = AttackWaves

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = ipairs
  L3_2 = A1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L8_2 = A0_2
    L7_2 = A0_2.UpdateThreat
    L9_2 = A0_2.kMaxThreat
    L9_2 = -0.1 * L9_2
    L7_2(L8_2, L9_2)
    L8_2 = A0_2
    L7_2 = A0_2.SpawnOneSquad
    L9_2 = L6_2
    L7_2(L8_2, L9_2)
  end
end

L1_1.SpawnManySquads = L2_1
L1_1 = AttackWaves

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L2_2 = A0_2.atkPaths
  L2_2 = L2_2[A1_2]
  L3_2 = A0_2.atkSpawnDist
  L3_2 = L3_2[A1_2]
  L4_2 = A0_2.atkRanges
  L4_2 = L4_2[A1_2]
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = A0_2.atkPoints
  L6_2 = L6_2[A1_2]
  L5_2 = L5_2(L6_2)
  L6_2 = A0_2.curThreat
  L7_2 = math
  L7_2 = L7_2.randi
  L8_2 = 1
  L9_2 = table
  L9_2 = L9_2.getn
  L10_2 = L2_2
  L9_2, L10_2, L11_2, L12_2, L13_2, L14_2 = L9_2(L10_2)
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L8_2 = A0_2.kMaxThreat
  L8_2 = 0.1 * L8_2
  if L6_2 < L8_2 then
    L9_2 = A0_2
    L8_2 = A0_2.SpawnVehicle
    L10_2 = vehInfo
    L10_2 = L10_2.jeep
    L11_2 = L2_2[L7_2]
    L12_2 = L3_2
    L13_2 = L5_2
    L14_2 = L4_2
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  else
    L8_2 = A0_2.kMaxThreat
    L8_2 = 0.25 * L8_2
    if L6_2 < L8_2 then
      L9_2 = A0_2
      L8_2 = A0_2.SpawnVehicle
      L10_2 = vehInfo
      L10_2 = L10_2.jeep
      L11_2 = L2_2[L7_2]
      L12_2 = L3_2
      L13_2 = L5_2
      L14_2 = L4_2
      L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
      L8_2 = math
      L8_2 = L8_2.randi
      L9_2 = 1
      L10_2 = table
      L10_2 = L10_2.getn
      L11_2 = L2_2
      L10_2, L11_2, L12_2, L13_2, L14_2 = L10_2(L11_2)
      L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
      L7_2 = L8_2
      L9_2 = A0_2
      L8_2 = A0_2.SpawnVehicle
      L10_2 = vehInfo
      L10_2 = L10_2.jeep
      L11_2 = L2_2[L7_2]
      L12_2 = L3_2 - 10
      L13_2 = L5_2
      L14_2 = L4_2
      L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
    else
      L8_2 = A0_2.kMaxThreat
      L8_2 = 0.45 * L8_2
      if L6_2 < L8_2 then
        L9_2 = A0_2
        L8_2 = A0_2.SpawnVehicle
        L10_2 = vehInfo
        L10_2 = L10_2.jeep
        L11_2 = L2_2[1]
        L12_2 = L3_2
        L13_2 = L5_2
        L14_2 = L4_2
        L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
        L9_2 = A0_2
        L8_2 = A0_2.SpawnVehicle
        L10_2 = vehInfo
        L10_2 = L10_2.jeep
        L11_2 = L2_2[2]
        L12_2 = L3_2
        L13_2 = L5_2
        L14_2 = L4_2
        L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
      else
        L8_2 = A0_2.kMaxThreat
        L8_2 = 0.65 * L8_2
        if L6_2 < L8_2 then
          L9_2 = A0_2
          L8_2 = A0_2.SpawnVehicle
          L10_2 = vehInfo
          L10_2 = L10_2.guntruck
          L11_2 = L2_2[L7_2]
          L12_2 = L3_2 + 10
          L13_2 = L5_2
          L14_2 = L4_2
          L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
        else
          L8_2 = A0_2.kMaxThreat
          L8_2 = 0.8 * L8_2
          if L6_2 < L8_2 then
            L9_2 = A0_2
            L8_2 = A0_2.SpawnVehicle
            L10_2 = vehInfo
            L10_2 = L10_2.jeep
            L11_2 = L2_2[L7_2]
            L12_2 = L3_2
            L13_2 = L5_2
            L14_2 = L4_2
            L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
            L8_2 = math
            L8_2 = L8_2.randi
            L9_2 = 1
            L10_2 = table
            L10_2 = L10_2.getn
            L11_2 = L2_2
            L10_2, L11_2, L12_2, L13_2, L14_2 = L10_2(L11_2)
            L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
            L7_2 = L8_2
            L9_2 = A0_2
            L8_2 = A0_2.SpawnVehicle
            L10_2 = vehInfo
            L10_2 = L10_2.guntruck
            L11_2 = L2_2[L7_2]
            L12_2 = L3_2 + 15
            L13_2 = L5_2
            L14_2 = L4_2
            L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
          else
            L8_2 = A0_2.kMaxThreat
            L8_2 = 0.9 * L8_2
            if L6_2 < L8_2 then
              L9_2 = A0_2
              L8_2 = A0_2.SpawnVehicle
              L10_2 = vehInfo
              L10_2 = L10_2.jeep
              L11_2 = L2_2[1]
              L12_2 = L3_2
              L13_2 = L5_2
              L14_2 = L4_2
              L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
              L9_2 = A0_2
              L8_2 = A0_2.SpawnVehicle
              L10_2 = vehInfo
              L10_2 = L10_2.jeep
              L11_2 = L2_2[2]
              L12_2 = L3_2
              L13_2 = L5_2
              L14_2 = L4_2
              L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
              L9_2 = A0_2
              L8_2 = A0_2.SpawnVehicle
              L10_2 = vehInfo
              L10_2 = L10_2.jeep
              L11_2 = L2_2[L7_2]
              L12_2 = L3_2 - 15
              L13_2 = L5_2
              L14_2 = L4_2
              L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
            else
              L9_2 = A0_2
              L8_2 = A0_2.SpawnVehicle
              L10_2 = vehInfo
              L10_2 = L10_2.guntruck
              L11_2 = L2_2[L7_2]
              L12_2 = L3_2 + 10
              L13_2 = L5_2
              L14_2 = L4_2
              L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
              L8_2 = math
              L8_2 = L8_2.randi
              L9_2 = 1
              L10_2 = table
              L10_2 = L10_2.getn
              L11_2 = L2_2
              L10_2, L11_2, L12_2, L13_2, L14_2 = L10_2(L11_2)
              L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
              L7_2 = L8_2
              L9_2 = A0_2
              L8_2 = A0_2.SpawnVehicle
              L10_2 = vehInfo
              L10_2 = L10_2.guntruck
              L11_2 = L2_2[L7_2]
              L12_2 = L3_2 + 20
              L13_2 = L5_2
              L14_2 = L4_2
              L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
            end
          end
        end
      end
    end
  end
end

L1_1.SpawnOneSquad = L2_1
L1_1 = AttackWaves

function L2_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = A2_2
  L6_2 = L6_2(L7_2)
  L7_2 = MrxUtil
  L7_2 = L7_2.FindSpawnPointOutOfView
  L8_2 = L6_2
  L9_2 = A3_2
  L7_2, L8_2, L9_2, L10_2, L11_2 = L7_2(L8_2, L9_2)
  if not L7_2 then
    L12_2 = Pg
    L12_2 = L12_2.GetDistantSpawnPointOnPath
    L13_2 = L6_2
    L14_2 = A4_2
    L15_2 = 0
    L16_2 = A3_2
    L12_2, L13_2, L14_2, L15_2, L16_2 = L12_2(L13_2, L14_2, L15_2, L16_2)
    L11_2 = L16_2
    L10_2 = L15_2
    L9_2 = L14_2
    L8_2 = L13_2
    L7_2 = L12_2
  end
  L12_2 = Pg
  L12_2 = L12_2.Spawn
  L13_2 = A1_2.template
  L14_2 = L8_2
  L15_2 = L9_2
  L16_2 = L10_2
  L17_2 = L11_2
  L18_2 = false
  L19_2 = true
  L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
  L13_2 = Vehicle
  L13_2 = L13_2.GetDriver
  L14_2 = L12_2
  L13_2 = L13_2(L14_2)
  L14_2 = {}
  L15_2 = Event
  L15_2 = L15_2.Create
  L16_2 = Event
  L16_2 = L16_2.ObjectHibernation
  L17_2 = {}
  L18_2 = L12_2
  L19_2 = "awake"
  L17_2[1] = L18_2
  L17_2[2] = L19_2
  L18_2 = A0_2.SetupSpawnedVehicle
  L19_2 = {}
  L20_2 = A0_2
  L21_2 = L12_2
  L22_2 = A1_2
  L23_2 = L6_2
  L24_2 = A4_2
  L25_2 = A5_2
  L19_2[1] = L20_2
  L19_2[2] = L21_2
  L19_2[3] = L22_2
  L19_2[4] = L23_2
  L19_2[5] = L24_2
  L19_2[6] = L25_2
  L15_2 = L15_2(L16_2, L17_2, L18_2, L19_2)
  L14_2.spawnDelay = L15_2
  L15_2 = A0_2.tVehicleEvents
  L15_2[L12_2] = L14_2
  L15_2 = table
  L15_2 = L15_2.insert
  L16_2 = A0_2.tAttackers
  L17_2 = L12_2
  L15_2(L16_2, L17_2)
end

L1_1.SpawnVehicle = L2_1
L1_1 = AttackWaves

function L2_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L6_2 = Vehicle
  L6_2 = L6_2.GetDriver
  L7_2 = A1_2
  L6_2 = L6_2(L7_2)
  L7_2 = A0_2.tVehicleEvents
  L7_2 = L7_2[A1_2]
  L8_2 = Event
  L8_2 = L8_2.Create
  L9_2 = Event
  L9_2 = L9_2.ObjectDeath
  L10_2 = {}
  L11_2 = L6_2
  L10_2[1] = L11_2
  L11_2 = A0_2.VehicleDestroyed
  L12_2 = {}
  L13_2 = A0_2
  L14_2 = A1_2
  L12_2[1] = L13_2
  L12_2[2] = L14_2
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
  L7_2.driverDeath = L8_2
  L8_2 = Event
  L8_2 = L8_2.Create
  L9_2 = Event
  L9_2 = L9_2.ObjectInSeat
  L10_2 = {}
  L11_2 = L6_2
  L12_2 = A1_2
  L13_2 = "d"
  L14_2 = "x"
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L11_2 = A0_2.VehicleDestroyed
  L12_2 = {}
  L13_2 = A0_2
  L14_2 = A1_2
  L12_2[1] = L13_2
  L12_2[2] = L14_2
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
  L7_2.driverJacked = L8_2
  L8_2 = Ai
  L8_2 = L8_2.Goal
  L9_2 = {}
  L9_2.AIGuid = L6_2
  L9_2.Goal = "PathMove"
  L9_2.Target = A3_2
  L10_2 = A2_2.speed
  L9_2.Haste = L10_2
  L9_2.Priority = "HiPri"
  L10_2 = A0_2.VehicleAtDest
  L9_2.Callback = L10_2
  L10_2 = {}
  L11_2 = A0_2
  L12_2 = A1_2
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L9_2.CallbackData = L10_2
  L8_2 = L8_2(L9_2)
  L7_2.moveGoal = L8_2
  L8_2 = Event
  L8_2 = L8_2.Create
  L9_2 = Event
  L9_2 = L9_2.TimerRelative
  L10_2 = {}
  L11_2 = 15
  L10_2[1] = L11_2
  L11_2 = A0_2.VehicleTimedOut
  L12_2 = {}
  L13_2 = A0_2
  L14_2 = A1_2
  L12_2[1] = L13_2
  L12_2[2] = L14_2
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
  L7_2.eTimeout = L8_2
  L8_2 = Event
  L8_2 = L8_2.Create
  L9_2 = Event
  L9_2 = L9_2.ObjectProximity
  L10_2 = {}
  L11_2 = A1_2
  L12_2 = A4_2
  L13_2 = "<"
  L14_2 = A5_2
  L15_2 = false
  L16_2 = false
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L10_2[5] = L15_2
  L10_2[6] = L16_2
  L11_2 = A0_2.VehicleAtGoalPoint
  L12_2 = {}
  L13_2 = A0_2
  L14_2 = A1_2
  L15_2 = A2_2.speed
  L12_2[1] = L13_2
  L12_2[2] = L14_2
  L12_2[3] = L15_2
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
  L7_2.eProx = L8_2
  L8_2 = Event
  L8_2 = L8_2.Create
  L9_2 = Event
  L9_2 = L9_2.ObjectDeath
  L10_2 = {}
  L11_2 = A1_2
  L10_2[1] = L11_2
  L11_2 = A0_2.UpdateThreat
  L12_2 = {}
  L13_2 = A0_2
  L14_2 = A2_2.threat
  L12_2[1] = L13_2
  L12_2[2] = L14_2
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
  L7_2.vehDeath = L8_2
end

L1_1.SetupSpawnedVehicle = L2_1
L1_1 = AttackWaves

function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2
  if 0 < A3_2 then
    L4_2 = Ai
    L4_2 = L4_2.Goal
    L5_2 = {}
    L5_2.AIGuid = A2_2
    L5_2.Goal = "Attack"
    L6_2 = Pg
    L6_2 = L6_2.GetGuidByName
    L7_2 = A0_2.office
    L6_2 = L6_2(L7_2)
    L5_2.Target = L6_2
    L5_2.Priority = "MedPri"
    L4_2(L5_2)
  else
    L4_2 = Object
    L4_2 = L4_2.Kill
    L5_2 = A1_2
    L4_2(L5_2)
  end
end

L1_1.VehicleAtDest = L2_1
L1_1 = AttackWaves

function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  L3_2 = Object
  L3_2 = L3_2.GetHealth
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if 0 < L3_2 then
    L3_2 = A0_2.attackObj
    L4_2 = L3_2
    L3_2 = L3_2._TargetDestroyed
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
  end
end

L1_1.VehicleDestroyed = L2_1
L1_1 = AttackWaves

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = Object
  L2_2 = L2_2.HasLabel
  L3_2 = A1_2
  L4_2 = "vz"
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.UpdateThreat
    L4_2 = 3
    L2_2(L3_2, L4_2)
  else
    L2_2 = Object
    L2_2 = L2_2.HasLabel
    L3_2 = A1_2
    L4_2 = "oc"
    L2_2 = L2_2(L3_2, L4_2)
    if L2_2 then
      L3_2 = A0_2
      L2_2 = A0_2.UpdateThreat
      L4_2 = -6
      L2_2(L3_2, L4_2)
    end
  end
end

L1_1.HumanDied = L2_1
L1_1 = AttackWaves

function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = A0_2.tVehicleEvents
  L3_2 = L3_2[A1_2]
  L4_2 = Event
  L4_2 = L4_2.Delete
  L5_2 = L3_2.eTimeout
  L4_2(L5_2)
  L3_2.eProx = nil
  L3_2.eTimeout = nil
  L4_2 = Vehicle
  L4_2 = L4_2.GetDriver
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  L5_2 = Ai
  L5_2 = L5_2.SetHaste
  L6_2 = L4_2
  L7_2 = A2_2 * 0.5
  L5_2(L6_2, L7_2)
  L6_2 = A0_2
  L5_2 = A0_2.BlipAttackers
  L7_2 = true
  L5_2(L6_2, L7_2)
end

L1_1.VehicleAtGoalPoint = L2_1
L1_1 = AttackWaves

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A0_2.tVehicleEvents
  L2_2 = L2_2[A1_2]
  L3_2 = Event
  L3_2 = L3_2.Delete
  L4_2 = L2_2.eProx
  L3_2(L4_2)
  L2_2.eProx = nil
  L2_2.eTimeout = nil
  L3_2 = Object
  L3_2 = L3_2.Kill
  L4_2 = A1_2
  L3_2(L4_2)
end

L1_1.VehicleTimedOut = L2_1
L1_1 = {}
HeliAttack = L1_1
L1_1 = HeliAttack

function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  if not A2_2 then
    return
  end
  L3_2 = setmetatable
  L4_2 = A2_2
  L5_2 = A0_2
  L3_2(L4_2, L5_2)
  A0_2.__index = A0_2
  A2_2.parent = A1_2
  L3_2 = {}
  A2_2.tVehicleEvents = L3_2
  L3_2 = {}
  A2_2.tOrbiters = L3_2
  A2_2.nCount = 0
  return A2_2
end

L1_1.Create = L2_1
L1_1 = HeliAttack

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2
  L1_2 = A0_2._Spawn
  L3_2 = vehInfo
  L3_2 = L3_2.heli
  L4_2 = 270
  L5_2 = HeliAttack
  L5_2 = L5_2._StartStrafe
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L2_2 = A0_2
  L1_2 = A0_2._Spawn
  L3_2 = vehInfo
  L3_2 = L3_2.heli
  L4_2 = 290
  L5_2 = HeliAttack
  L5_2 = L5_2._StartOrbit
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Oil01-82"
  L2_2[1] = L3_2
  L1_2(L2_2)
  L1_2 = MrxMusic
  L1_2 = L1_2.PlaySpecialMusic
  L2_2 = "mu_fac_oc_kickass_01"
  L1_2(L2_2)
end

L1_1.Start = L2_1
L1_1 = HeliAttack

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = pairs
  L2_2 = A0_2.tVehicleEvents
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L7_2 = A0_2
    L6_2 = A0_2._CleanupOne
    L8_2 = L5_2
    L6_2(L7_2, L8_2)
    L6_2 = A0_2.tVehicleEvents
    L6_2[L4_2] = nil
  end
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.eStrafeTimer
  L1_2(L2_2)
  A0_2.eStrafeTimer = nil
end

L1_1.Cleanup = L2_1
L1_1 = HeliAttack

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A1_2.aiGoal
  if L2_2 then
    A1_2.aiGoal = nil
  end
  L2_2 = pairs
  L3_2 = A1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = Event
    L7_2 = L7_2.Delete
    L8_2 = L6_2
    L7_2(L8_2)
  end
end

L1_1._CleanupOne = L2_1
L1_1 = HeliAttack

function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L4_2 = Math
  L4_2 = L4_2.randi
  L5_2 = 1
  L6_2 = A0_2.tInPaths
  L6_2 = #L6_2
  L4_2 = L4_2(L5_2, L6_2)
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = A0_2.tInPaths
  L6_2 = L6_2[L4_2]
  L5_2 = L5_2(L6_2)
  L6_2 = MrxUtil
  L6_2 = L6_2.FindSpawnPointOutOfView
  L7_2 = L5_2
  L8_2 = A2_2
  L6_2, L7_2, L8_2, L9_2, L10_2 = L6_2(L7_2, L8_2)
  if not L6_2 then
    L11_2 = Pg
    L11_2 = L11_2.GetDistantSpawnPointOnPath
    L12_2 = L5_2
    L13_2 = Pg
    L13_2 = L13_2.GetGuidByName
    L14_2 = "refinery_office02"
    L13_2 = L13_2(L14_2)
    L14_2 = 0
    L15_2 = A2_2
    L11_2, L12_2, L13_2, L14_2, L15_2 = L11_2(L12_2, L13_2, L14_2, L15_2)
    L10_2 = L15_2
    L9_2 = L14_2
    L8_2 = L13_2
    L7_2 = L12_2
    L6_2 = L11_2
  end
  L11_2 = Pg
  L11_2 = L11_2.Spawn
  L12_2 = A1_2.template
  L13_2 = L7_2
  L14_2 = L8_2
  L15_2 = L9_2
  L16_2 = L10_2
  L17_2 = false
  L18_2 = true
  L11_2 = L11_2(L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  L12_2 = {}
  L13_2 = Event
  L13_2 = L13_2.Create
  L14_2 = Event
  L14_2 = L14_2.ObjectHibernation
  L15_2 = {}
  L16_2 = L11_2
  L17_2 = "awake"
  L15_2[1] = L16_2
  L15_2[2] = L17_2
  L16_2 = A0_2._HeliReady
  L17_2 = {}
  L18_2 = A0_2
  L19_2 = L11_2
  L20_2 = A1_2
  L21_2 = A3_2
  L17_2[1] = L18_2
  L17_2[2] = L19_2
  L17_2[3] = L20_2
  L17_2[4] = L21_2
  L13_2 = L13_2(L14_2, L15_2, L16_2, L17_2)
  L12_2.spawnDelay = L13_2
  L13_2 = A0_2.tVehicleEvents
  L13_2[L11_2] = L12_2
  return L11_2
end

L1_1._Spawn = L2_1
L1_1 = HeliAttack

function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L4_2 = Vehicle
  L4_2 = L4_2.GetDriver
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  L5_2 = A0_2.tVehicleEvents
  L5_2 = L5_2[A1_2]
  L6_2 = Event
  L6_2 = L6_2.Create
  L7_2 = Event
  L7_2 = L7_2.ObjectDeath
  L8_2 = {}
  L9_2 = L4_2
  L8_2[1] = L9_2
  L9_2 = A0_2._VehicleDestroyed
  L10_2 = {}
  L11_2 = A0_2
  L12_2 = A1_2
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
  L5_2.driverDeath = L6_2
  L6_2 = Event
  L6_2 = L6_2.Create
  L7_2 = Event
  L7_2 = L7_2.ObjectInSeat
  L8_2 = {}
  L9_2 = L4_2
  L10_2 = A1_2
  L11_2 = "d"
  L12_2 = "x"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  L9_2 = A0_2._VehicleDestroyed
  L10_2 = {}
  L11_2 = A0_2
  L12_2 = A1_2
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
  L5_2.driverJacked = L6_2
  L6_2 = A3_2
  L7_2 = A0_2
  L8_2 = A1_2
  L6_2(L7_2, L8_2)
end

L1_1._HeliReady = L2_1
L1_1 = HeliAttack

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = Vehicle
  L2_2 = L2_2.GetDriver
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  L3_2 = math
  L3_2 = L3_2.randi
  L4_2 = 1
  L5_2 = table
  L5_2 = L5_2.getn
  L6_2 = A0_2.tLoopPaths
  L5_2, L6_2, L7_2, L8_2, L9_2 = L5_2(L6_2)
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = A0_2.tLoopPaths
  L5_2 = L5_2[L3_2]
  L4_2 = L4_2(L5_2)
  L5_2 = math
  L5_2 = L5_2.randf
  L6_2 = 0.6
  L7_2 = 0.8
  L5_2 = L5_2(L6_2, L7_2)
  L6_2 = A0_2.tVehicleEvents
  L6_2 = L6_2[A1_2]
  L7_2 = L6_2.aiGoal
  if L7_2 then
    L7_2 = Ai
    L7_2 = L7_2.RemoveGoal
    L8_2 = {}
    L8_2.AIGuid = L2_2
    L9_2 = L6_2.aiGoal
    L8_2.Handle = L9_2
    L7_2(L8_2)
  end
  L7_2 = Ai
  L7_2 = L7_2.Goal
  L8_2 = {}
  L8_2.AIGuid = L2_2
  L8_2.Goal = "PathMove"
  L8_2.Target = L4_2
  L8_2.Haste = L5_2
  L8_2.Start = "Nearest"
  L8_2.Mode = "Loop"
  L8_2.Priority = "HiPri"
  L7_2 = L7_2(L8_2)
  L6_2.aiGoal = L7_2
  L7_2 = table
  L7_2 = L7_2.insert
  L8_2 = A0_2.tOrbiters
  L9_2 = A1_2
  L7_2(L8_2, L9_2)
end

L1_1._StartOrbit = L2_1
L1_1 = HeliAttack

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = Vehicle
  L2_2 = L2_2.GetDriver
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  L3_2 = Player
  L3_2 = L3_2.GetAllPlayers
  L3_2 = L3_2()
  L4_2 = Math
  L4_2 = L4_2.randi
  L5_2 = 1
  L6_2 = #L3_2
  L4_2 = L4_2(L5_2, L6_2)
  L5_2 = A0_2.tVehicleEvents
  L5_2 = L5_2[A1_2]
  L6_2 = L5_2.aiGoal
  if L6_2 then
    L6_2 = Ai
    L6_2 = L6_2.RemoveGoal
    L7_2 = {}
    L7_2.AIGuid = L2_2
    L8_2 = L5_2.aiGoal
    L7_2.Handle = L8_2
    L6_2(L7_2)
  end
  L6_2 = Ai
  L6_2 = L6_2.Goal
  L7_2 = {}
  L7_2.AIGuid = L2_2
  L7_2.Goal = "Attack"
  L8_2 = Player
  L8_2 = L8_2.GetCharacter
  L9_2 = L3_2[L4_2]
  L8_2 = L8_2(L9_2)
  L7_2.Target = L8_2
  L6_2 = L6_2(L7_2)
  L5_2.aiGoal = L6_2
  A0_2.uAttacker = A1_2
  L6_2 = Math
  L6_2 = L6_2.randf
  L7_2 = 13
  L8_2 = 15
  L6_2 = L6_2(L7_2, L8_2)
  L7_2 = Event
  L7_2 = L7_2.Delete
  L8_2 = A0_2.eStrafeTimer
  L7_2(L8_2)
  L7_2 = Event
  L7_2 = L7_2.Create
  L8_2 = Event
  L8_2 = L8_2.TimerRelative
  L9_2 = {}
  L10_2 = L6_2
  L9_2[1] = L10_2
  L10_2 = A0_2._ReturnAttackerToOrbit
  L11_2 = {}
  L12_2 = A0_2
  L11_2[1] = L12_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
  A0_2.eStrafeTimer = L7_2
end

L1_1._StartStrafe = L2_1
L1_1 = HeliAttack

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = A0_2
  L2_2 = A0_2._CleanupOne
  L4_2 = A0_2.tVehicleEvents
  L4_2 = L4_2[A1_2]
  L2_2(L3_2, L4_2)
  L2_2 = A0_2.tVehicleEvents
  L2_2[A1_2] = nil
  L2_2 = A0_2.uAttacker
  if L2_2 == A1_2 then
    A0_2.uAttacker = nil
    L3_2 = A0_2
    L2_2 = A0_2._DelayStrafe
    L4_2 = 2
    L5_2 = 3
    L2_2(L3_2, L4_2, L5_2)
  else
    L2_2 = nil
    L3_2 = ipairs
    L4_2 = A0_2.tOrbiters
    L3_2, L4_2, L5_2 = L3_2(L4_2)
    for L6_2, L7_2 in L3_2, L4_2, L5_2 do
      if L7_2 == A1_2 then
        L2_2 = L6_2
        break
      end
    end
    L3_2 = table
    L3_2 = L3_2.remove
    L4_2 = A0_2.tOrbiters
    L5_2 = L2_2
    L3_2(L4_2, L5_2)
  end
  L3_2 = A0_2
  L2_2 = A0_2._Spawn
  L4_2 = vehInfo
  L4_2 = L4_2.heli
  L5_2 = 290
  L6_2 = HeliAttack
  L6_2 = L6_2._StartOrbit
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2.nCount
  L2_2 = L2_2 + 1
  A0_2.nCount = L2_2
  L2_2 = A0_2.nCount
  if L2_2 == 6 then
    L3_2 = A0_2
    L2_2 = A0_2._Spawn
    L4_2 = vehInfo
    L4_2 = L4_2.heli
    L5_2 = 270
    L6_2 = HeliAttack
    L6_2 = L6_2._StartOrbit
    L2_2(L3_2, L4_2, L5_2, L6_2)
  end
  L2_2 = A0_2.parent
  L3_2 = A0_2.parent
  L3_2 = L3_2.curWaveBonus
  L3_2 = L3_2 + 10
  L2_2.curWaveBonus = L3_2
end

L1_1._VehicleDestroyed = L2_1
L1_1 = HeliAttack

function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = Math
  L3_2 = L3_2.randf
  L4_2 = A1_2
  L5_2 = A2_2
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = Event
  L4_2 = L4_2.Delete
  L5_2 = A0_2.eStrafeTimer
  L4_2(L5_2)
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = L3_2
  L6_2[1] = L7_2
  
  function L7_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = table
    L0_3 = L0_3.remove
    L1_3 = A0_2
    L1_3 = L1_3.tOrbiters
    L2_3 = 1
    L0_3 = L0_3(L1_3, L2_3)
    L1_3 = A0_2
    L2_3 = L1_3
    L1_3 = L1_3._StartStrafe
    L3_3 = L0_3
    L1_3(L2_3, L3_3)
  end
  
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  A0_2.eStrafeTimer = L4_2
end

L1_1._DelayStrafe = L2_1
L1_1 = HeliAttack

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = A0_2.uAttacker
  A0_2.uAttacker = nil
  L3_2 = A0_2
  L2_2 = A0_2._StartOrbit
  L4_2 = L1_2
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._DelayStrafe
  L4_2 = 15
  L5_2 = 17
  L2_2(L3_2, L4_2, L5_2)
end

L1_1._ReturnAttackerToOrbit = L2_1
L1_1 = AttackWaves

function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = A0_2.curApc
  if L4_2 then
    L4_2 = A0_2.curApc
    L5_2 = L4_2
    L4_2 = L4_2.Cleanup
    L4_2(L5_2)
    A0_2.curApc = nil
  end
  L4_2 = A0_2.tAPCInfo
  L4_2 = L4_2[A2_2]
  L5_2 = vehInfo
  L5_2 = L5_2[A1_2]
  L4_2.veh = L5_2
  L5_2 = APCWave
  L6_2 = L5_2
  L5_2 = L5_2.Create
  L7_2 = A0_2.parent
  L8_2 = L4_2
  L9_2 = A3_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  A0_2.curApc = L5_2
  L6_2 = A0_2
  L5_2 = A0_2.ProcessNextCmd
  L5_2(L6_2)
end

L1_1.SpawnApc = L2_1
L1_1 = {}
APCWave = L1_1
L1_1 = APCWave

function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  if not A2_2 then
    return
  end
  L4_2 = {}
  L5_2 = setmetatable
  L6_2 = L4_2
  L7_2 = A0_2
  L5_2(L6_2, L7_2)
  A0_2.__index = A0_2
  L4_2.parent = A1_2
  L4_2.tConfig = A2_2
  L5_2 = {}
  L4_2.tEvents = L5_2
  L6_2 = L4_2
  L5_2 = L4_2.DelayedSpawn
  L7_2 = nil
  L8_2 = A3_2
  L5_2(L6_2, L7_2, L8_2)
  return L4_2
end

L1_1.Create = L2_1
L1_1 = APCWave

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = A0_2.squadDeathObj
  if L1_2 then
    L1_2 = A0_2.squadDeathObj
    L2_2 = L1_2
    L1_2 = L1_2.Cancel
    L1_2(L2_2)
    A0_2.squadDeathObj = nil
  end
  L1_2 = pairs
  L2_2 = A0_2.tEvents
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Event
    L6_2 = L6_2.Delete
    L7_2 = L5_2
    L6_2(L7_2)
  end
  A0_2.tEvents = nil
  A0_2.tPaths = nil
end

L1_1.Cleanup = L2_1
L1_1 = APCWave

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L1_2 = A0_2.squadDeathObj
  if L1_2 then
    L1_2 = A0_2.squadDeathObj
    L2_2 = L1_2
    L1_2 = L1_2.Cancel
    L1_2(L2_2)
    A0_2.squadDeathObj = nil
  end
  L1_2 = A0_2.tConfig
  L2_2 = MrxUtil
  L2_2 = L2_2.FindSpawnPointOutOfView
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = L1_2.inPath
  L3_2 = L3_2(L4_2)
  L4_2 = 230
  L2_2, L3_2, L4_2, L5_2, L6_2 = L2_2(L3_2, L4_2)
  if not L2_2 then
    L8_2 = A0_2
    L7_2 = A0_2.DelayedSpawn
    L9_2 = nil
    L10_2 = 10
    L7_2(L8_2, L9_2, L10_2)
    return
  end
  L7_2 = Pg
  L7_2 = L7_2.Spawn
  L8_2 = L1_2.veh
  L8_2 = L8_2.template
  L9_2 = L3_2
  L10_2 = L4_2
  L11_2 = L5_2
  L12_2 = L6_2
  L13_2 = false
  L14_2 = true
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L8_2 = {}
  L8_2.uVehicle = L7_2
  L9_2 = L1_2.inPath
  L8_2.inDest = L9_2
  L8_2.inDestType = "path"
  L9_2 = L1_2.veh
  L9_2 = L9_2.speed
  L9_2 = L9_2 * 0.8
  L8_2.inSpeed = L9_2
  L9_2 = L1_2.outPath
  L8_2.outDest = L9_2
  L8_2.outDestType = "path"
  L9_2 = L1_2.veh
  L9_2 = L9_2.speed
  L8_2.outSpeed = L9_2
  L9_2 = L1_2.squadName
  L8_2.squadName = L9_2
  L9_2 = L1_2.defensePoint
  L8_2.squadTarget = L9_2
  L8_2.squadOrder = "attack"
  
  function L9_2(A0_3, A1_3)
    local L2_3, L3_3, L4_3, L5_3
    L2_3 = APCWave
    L2_3 = L2_3.DropDone
    L3_3 = A0_2
    L4_3 = A0_3
    L5_3 = A1_3
    L2_3(L3_3, L4_3, L5_3)
  end
  
  L8_2.fDropDoneCallback = L9_2
  L9_2 = Event
  L9_2 = L9_2.Create
  L10_2 = Event
  L10_2 = L10_2.ObjectHibernation
  L11_2 = {}
  L12_2 = L7_2
  L13_2 = "awake"
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  
  function L12_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = MrxApcDrop
    L2_3 = L1_3
    L1_3 = L1_3.Create
    L3_3 = A0_3
    L1_3(L2_3, L3_3)
  end
  
  L13_2 = {}
  L14_2 = L8_2
  L13_2[1] = L14_2
  L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2)
  L10_2 = A0_2.tEvents
  L11_2 = Event
  L11_2 = L11_2.Create
  L12_2 = Event
  L12_2 = L12_2.ObjectDeath
  L13_2 = {}
  L14_2 = L7_2
  L13_2[1] = L14_2
  L14_2 = APCWave
  L14_2 = L14_2.DelayedAPCSpawn
  L15_2 = {}
  L16_2 = A0_2
  L15_2[1] = L16_2
  L11_2 = L11_2(L12_2, L13_2, L14_2, L15_2)
  L10_2[L7_2] = L11_2
end

L1_1.Spawn = L2_1
L1_1 = APCWave

function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = A0_2.tEvents
  if L3_2 then
    L3_2 = Event
    L3_2 = L3_2.Delete
    L4_2 = A0_2.tEvents
    L4_2 = L4_2[A1_2]
    L3_2(L4_2)
    L3_2 = A0_2.tEvents
    L3_2[A1_2] = nil
    L3_2 = A0_2.squadDeathObj
    if L3_2 == nil then
      L3_2 = A0_2.parent
      L4_2 = L3_2
      L3_2 = L3_2.CreateChild
      L5_2 = {}
      L5_2.sName = "INTERNAL OBJ: apc passenger death"
      L5_2.sModuleName = "MrxTaskObjectiveDestroy"
      L5_2.vTgtInclude = A2_2
      L6_2 = table
      L6_2 = L6_2.getn
      L7_2 = A2_2
      L6_2 = L6_2(L7_2)
      L6_2 = L6_2 - 1
      L5_2.nQuota = L6_2
      L5_2.bDspDescPda = false
      L5_2.bDspBlp = false
      L5_2.bDspMsg = false
      L5_2.sDspShortDesc = "APC Drop"
      
      function L6_2()
        local L0_3, L1_3, L2_3
        L0_3 = Ai
        L0_3 = L0_3.Squad
        L1_3 = {}
        L1_3.Squad = "oc001.vzapcsquad"
        L1_3.Action = "GetUnits"
        L0_3 = L0_3(L1_3)
        L1_3 = Ai
        L1_3 = L1_3.Squad
        L2_3 = {}
        L2_3.Squad = "oc001.vzapcsquad"
        L2_3.Action = "RemoveSquad"
        L1_3(L2_3)
        L1_3 = A0_2
        L2_3 = L1_3
        L1_3 = L1_3.DelayedSpawn
        L1_3(L2_3)
      end
      
      L5_2.fOnComplete = L6_2
      L3_2 = L3_2(L4_2, L5_2)
      A0_2.squadDeathObj = L3_2
    end
  end
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectHibernation
  L5_2 = {}
  L6_2 = A1_2
  L7_2 = "hibernated"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = Object
  L6_2 = L6_2.Remove
  L7_2 = {}
  L8_2 = A1_2
  L7_2[1] = L8_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
end

L1_1.DropDone = L2_1
L1_1 = APCWave

function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  if A1_2 then
    L3_2 = A0_2.tEvents
    L3_2[A1_2] = nil
  end
  if not A2_2 then
    L3_2 = Math
    L3_2 = L3_2.randi
    L4_2 = 7
    L5_2 = 9
    L3_2 = L3_2(L4_2, L5_2)
    A2_2 = L3_2
  end
  L3_2 = A0_2.tEvents
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = A2_2
  L6_2[1] = L7_2
  L7_2 = A0_2.Spawn
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L3_2.eAPCSpawnTimer = L4_2
end

L1_1.DelayedSpawn = L2_1
L1_1 = {}
Executive = L1_1
L1_1 = Executive

function L2_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2
  L5_2 = {}
  L6_2 = setmetatable
  L7_2 = L5_2
  L8_2 = A0_2
  L6_2(L7_2, L8_2)
  A0_2.__index = A0_2
  L5_2.parent = A1_2
  L5_2.guid = A2_2
  L6_2 = Event
  L6_2 = L6_2.Create
  L7_2 = Event
  L7_2 = L7_2.ObjectDeath
  L8_2 = {}
  L9_2 = A2_2
  L8_2[1] = L9_2
  L9_2 = A3_2
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  A0_2.eDeath = L6_2
  if A4_2 then
    L6_2 = Object
    L6_2 = L6_2.SetTransformToObject
    L7_2 = A2_2
    L8_2 = A4_2
    L6_2(L7_2, L8_2)
    
    function L6_2(A0_3)
      local L1_3, L2_3, L3_3
      L2_3 = A0_3
      L1_3 = A0_3.Stand
      L1_3(L2_3)
      L1_3 = Ai
      L1_3 = L1_3.SetState
      L2_3 = {}
      L3_3 = A0_3.guid
      L2_3.AIGuid = L3_3
      L2_3.State = "Pacifist"
      L2_3.Value = true
      L1_3(L2_3)
      A0_3.fDehibernateAction = nil
    end
    
    L5_2.fDehibernateAction = L6_2
  else
    function L6_2(A0_3)
      local L1_3, L2_3, L3_3
      
      L2_3 = A0_3
      L1_3 = A0_3.Cower
      L1_3(L2_3)
      L1_3 = Ai
      L1_3 = L1_3.SetState
      L2_3 = {}
      L3_3 = A0_3.guid
      L2_3.AIGuid = L3_3
      L2_3.State = "Pacifist"
      L2_3.Value = true
      L1_3(L2_3)
      A0_3.fDehibernateAction = nil
    end
    
    L5_2.fDehibernateAction = L6_2
  end
  L7_2 = L5_2
  L6_2 = L5_2.OnHibernate
  L6_2(L7_2)
  return L5_2
end

L1_1.Create = L2_1
L1_1 = Executive

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  A0_2._tConfig = A1_2
  A0_2.curProgress = 0
  A0_2.thirdVO = nil
  A0_2.twothirdVO = nil
  A0_2.onemoreVO = nil
  L2_2 = Ai
  L2_2 = L2_2.Goal
  L3_2 = {}
  L4_2 = A0_2.guid
  L3_2.AIGuid = L4_2
  L3_2.Goal = "MoveTo"
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = A0_2._tConfig
  L5_2 = L5_2.returnPoint
  L4_2 = L4_2(L5_2)
  L3_2.Target = L4_2
  L3_2.Haste = 0.6
  L3_2.Priority = "hiPri"
  L4_2 = A0_2.EnterBuilding
  L3_2.Callback = L4_2
  L4_2 = {}
  L5_2 = A0_2
  L4_2[1] = L5_2
  L3_2.CallbackData = L4_2
  L2_2 = L2_2(L3_2)
  A0_2.hAiCurGoal = L2_2
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 10
  L4_2[1] = L5_2
  L5_2 = A0_2.EnterBuilding
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  A0_2.eTimeout = L2_2
end

L1_1.Start = L2_1
L1_1 = Executive

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.eTimeout
  L1_2(L2_2)
  L1_2 = Ai
  L1_2 = L1_2.RemoveGoal
  L2_2 = {}
  L3_2 = A0_2.guid
  L2_2.AIGuid = L3_2
  L3_2 = A0_2.hAiCurGoal
  L2_2.Handle = L3_2
  L1_2(L2_2)
  L1_2 = Object
  L1_2 = L1_2.SetTransformToObject
  L2_2 = A0_2.guid
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = A0_2._tConfig
  L4_2 = L4_2.hidePoint
  L3_2, L4_2, L5_2, L6_2, L7_2 = L3_2(L4_2)
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = A0_2._tConfig
  L2_2 = L2_2.office
  L1_2 = L1_2(L2_2)
  L2_2 = A0_2.parent
  L3_2 = L2_2
  L2_2 = L2_2.CreateChild
  L4_2 = {}
  L4_2.sName = "oc001 defend office"
  L4_2.sModuleName = "MrxTaskObjectiveProtect"
  L4_2.vTgtInclude = L1_2
  L4_2.bDspBlp = true
  L4_2.nSortOrder = 3
  L4_2.sDspShortDesc = "[OilCon001.Objectives.defend]"
  
  function L5_2()
    local L0_3, L1_3
    L0_3 = A0_2
    L0_3 = L0_3._tConfig
    L0_3 = L0_3.fOnComplete
    L1_3 = A0_2
    L1_3 = L1_3.parent
    L0_3(L1_3)
  end
  
  L4_2.fOnComplete = L5_2
  
  function L5_2()
    local L0_3, L1_3
    L0_3 = Object
    L0_3 = L0_3.Kill
    L1_3 = A0_2
    L1_3 = L1_3.guid
    L0_3(L1_3)
  end
  
  L4_2.fOnCancel = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  A0_2.defendObj = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.DisplayHealthBar
  L3_2 = A0_2.parent
  L4_2 = L1_2
  L5_2 = Object
  L5_2 = L5_2.GetHealth
  L6_2 = L1_2
  L5_2 = L5_2(L6_2)
  L6_2 = false
  L7_2 = false
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = A0_2
  L2_2 = A0_2.BurnBox
  L2_2(L3_2)
end

L1_1.EnterBuilding = L2_1
L1_1 = Executive

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = A0_2.defendObj
  L2_2 = L1_2
  L1_2 = L1_2.Complete
  L1_2(L2_2)
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = A0_2._tConfig
  L2_2 = L2_2.dropoffPoint
  L1_2 = L1_2(L2_2)
  L3_2 = A0_2
  L2_2 = A0_2.FaceTarget
  L4_2 = L1_2
  L2_2(L3_2, L4_2)
  L2_2 = Object
  L2_2 = L2_2.SetTransformToObject
  L3_2 = A0_2.guid
  L4_2 = L1_2
  L2_2(L3_2, L4_2)
end

L1_1.ExitBuilding = L2_1
L1_1 = Executive

function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  A0_2._curAction = "BurnBox"
  A0_2._curActionState = A2_2
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 12
  L5_2[1] = L6_2
  L6_2 = A0_2.EvaluateProgress
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  A0_2.eTimeout = L3_2
end

L1_1.BurnBox = L2_1
L1_1 = Executive

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  A0_2._curAction = "EvaluateProgress"
  A0_2._curActionState = nil
  L2_2 = A0_2
  L1_2 = A0_2.BoxCompleted
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    L3_2 = A0_2
    L2_2 = A0_2.BurnBox
    L2_2(L3_2)
  else
    L2_2 = MrxUtil
    L2_2 = L2_2.StopHealthBar
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = A0_2._tConfig
    L4_2 = L4_2.office
    L3_2, L4_2 = L3_2(L4_2)
    L2_2(L3_2, L4_2)
    L3_2 = A0_2
    L2_2 = A0_2.ExitBuilding
    L2_2(L3_2)
  end
end

L1_1.EvaluateProgress = L2_1
L1_1 = Executive

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = A0_2.parent
  L2_2 = A0_2.curProgress
  L3_2 = A0_2._tConfig
  L3_2 = L3_2.boxVal
  L2_2 = L2_2 + L3_2
  L3_2 = L1_2.curWaveBonus
  L2_2 = L2_2 + L3_2
  A0_2.curProgress = L2_2
  L1_2.curWaveBonus = 0
  L2_2 = false
  L3_2 = A0_2.curProgress
  L4_2 = A0_2._tConfig
  L4_2 = L4_2.goalVal
  if L3_2 >= L4_2 then
    L3_2 = A0_2._tConfig
    L3_2 = L3_2.goalVal
    A0_2.curProgres = L3_2
    L2_2 = true
  else
    L3_2 = A0_2.curProgress
    L4_2 = A0_2._tConfig
    L4_2 = L4_2.goalVal
    L4_2 = 0.33 * L4_2
    if L3_2 > L4_2 then
      L3_2 = A0_2.thirdVO
      if not L3_2 then
        A0_2.thirdVO = true
        L4_2 = L1_2
        L3_2 = L1_2._PlayVo
        L5_2 = A0_2.guid
        L6_2 = A0_2._tConfig
        L6_2 = L6_2.tVO
        L6_2 = L6_2[1]
        L3_2(L4_2, L5_2, L6_2)
    end
    else
      L3_2 = A0_2.curProgress
      L4_2 = A0_2._tConfig
      L4_2 = L4_2.goalVal
      L4_2 = 0.66 * L4_2
      if L3_2 > L4_2 then
        L3_2 = A0_2.twothirdVO
        if not L3_2 then
          A0_2.twothirdVO = true
          L4_2 = L1_2
          L3_2 = L1_2._PlayVo
          L5_2 = A0_2.guid
          L6_2 = A0_2._tConfig
          L6_2 = L6_2.tVO
          L6_2 = L6_2[2]
          L3_2(L4_2, L5_2, L6_2)
      end
      else
        L3_2 = A0_2.curProgress
        L4_2 = A0_2._tConfig
        L4_2 = L4_2.goalVal
        L5_2 = A0_2._tConfig
        L5_2 = L5_2.boxVal
        L4_2 = L4_2 - L5_2
        if L3_2 >= L4_2 then
          L3_2 = A0_2.onemoreVO
          if not L3_2 then
            A0_2.onemoreVO = true
            L4_2 = L1_2
            L3_2 = L1_2._PlayVo
            L5_2 = A0_2.guid
            L6_2 = A0_2._tConfig
            L6_2 = L6_2.tVO
            L6_2 = L6_2[3]
            L3_2(L4_2, L5_2, L6_2)
          end
        end
      end
    end
  end
  return L2_2
end

L1_1.BoxCompleted = L2_1
L1_1 = Executive

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = math
  L1_2 = L1_2.floor
  L2_2 = A0_2.curProgress
  L2_2 = 100 * L2_2
  L3_2 = A0_2._tConfig
  L3_2 = L3_2.goalVal
  L2_2 = L2_2 / L3_2
  L1_2 = L1_2(L2_2)
  L2_2 = Hud
  L2_2 = L2_2.ObjectiveTray
  L3_2 = L2_2
  L2_2 = L2_2.SetSlotToText
  L4_2 = {}
  L4_2.nSlot = 1
  L5_2 = "[OilCon001.Objectives.filesBurned][objt][yellow][bar"
  L6_2 = L1_2
  L7_2 = "]"
  L5_2 = L5_2 .. L6_2 .. L7_2
  L4_2.sText = L5_2
  L2_2(L3_2, L4_2)
end

L1_1.UpdateDisplay = L2_1
L1_1 = Executive

function L2_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 1
  L1_2(L2_2, L3_2)
end

L1_1.CleanupDisplay = L2_1
L1_1 = Executive

function L2_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2
  if A4_2 ~= 1 then
  end
  L5_2 = Ai
  L5_2 = L5_2.Goal
  L6_2 = {}
  L7_2 = A0_2.guid
  L6_2.AIGuid = L7_2
  L6_2.Goal = "Face"
  L7_2 = {}
  L8_2 = Object
  L8_2 = L8_2.GetPosition
  L9_2 = A1_2
  L8_2, L9_2 = L8_2(L9_2)
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L6_2.Target = L7_2
  L6_2.Position = true
  L6_2.Priority = "hiPri"
  L6_2.Callback = A2_2
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L6_2.CallbackData = L7_2
  L5_2 = L5_2(L6_2)
  A0_2.hAiCurGoal = L5_2
end

L1_1.FaceTarget = L2_1
L1_1 = Executive

function L2_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Human
  L1_2 = L1_2.DoAction
  L2_2 = A0_2.guid
  L3_2 = "Cower"
  L1_2(L2_2, L3_2)
  L1_2 = Ai
  L1_2 = L1_2.Anchor
  L2_2 = {}
  L3_2 = A0_2.guid
  L2_2.AIGuid = L3_2
  L2_2.AnchorRadius = 0
  L1_2(L2_2)
  L1_2 = Ai
  L1_2 = L1_2.Goal
  L2_2 = {}
  L3_2 = A0_2.guid
  L2_2.AIGuid = L3_2
  L2_2.Goal = "Idle"
  L2_2.Priority = "HiPri"
  L1_2(L2_2)
end

L1_1.Cower = L2_1
L1_1 = Executive

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = Human
  L2_2 = L2_2.DoAction
  L3_2 = A0_2.guid
  L4_2 = "Stand"
  L2_2(L3_2, L4_2)
  L2_2 = Ai
  L2_2 = L2_2.Anchor
  L3_2 = {}
  L4_2 = A0_2.guid
  L3_2.AIGuid = L4_2
  L3_2.AnchorRadius = 501
  L2_2(L3_2)
  if A1_2 then
    L2_2 = Event
    L2_2 = L2_2.Create
    L3_2 = Event
    L3_2 = L3_2.HumanActionComplete
    L4_2 = {}
    L5_2 = A0_2.guid
    L4_2[1] = L5_2
    L5_2 = A0_2.FaceTarget
    L6_2 = {}
    L7_2 = A0_2
    L8_2 = A1_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L2_2(L3_2, L4_2, L5_2, L6_2)
  end
end

L1_1.Stand = L2_1
L1_1 = Executive

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Ai
  L1_2 = L1_2.RemoveGoal
  L2_2 = {}
  L3_2 = A0_2.guid
  L2_2.AIGuid = L3_2
  L3_2 = A0_2.hAiCurGoal
  L2_2.Handle = L3_2
  L1_2 = L1_2(L2_2)
  L2_2 = A0_2._tConfig
  if L2_2 then
    L2_2 = A0_2._tConfig
    L2_2 = L2_2.office
    if L2_2 then
      L2_2 = MrxUtil
      L2_2 = L2_2.StopHealthBar
      L3_2 = Pg
      L3_2 = L3_2.GetGuidByName
      L4_2 = A0_2._tConfig
      L4_2 = L4_2.office
      L3_2, L4_2 = L3_2(L4_2)
      L2_2(L3_2, L4_2)
    end
  end
  A0_2.hAiCurGoal = nil
  L2_2 = Event
  L2_2 = L2_2.Delete
  L3_2 = A0_2.eHibernation
  L2_2(L3_2)
  L2_2 = Event
  L2_2 = L2_2.Delete
  L3_2 = A0_2.eTimeout
  L2_2(L3_2)
  L2_2 = Event
  L2_2 = L2_2.Delete
  L3_2 = A0_2.eDeath
  L2_2(L3_2)
end

L1_1.Cleanup = L2_1
L1_1 = Executive

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.ObjectHibernation
  L3_2 = {}
  L4_2 = A0_2.guid
  L5_2 = "awake"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L4_2 = A0_2.OnDehibernate
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  A0_2.eHibernation = L1_2
end

L1_1.OnHibernate = L2_1
L1_1 = Executive

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Human
  L1_2 = L1_2.DisableWeapons
  L2_2 = A0_2.guid
  L1_2(L2_2)
  L1_2 = A0_2.fDehibernateAction
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.fDehibernateAction
    L1_2(L2_2)
  end
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.ObjectHibernation
  L3_2 = {}
  L4_2 = A0_2.guid
  L5_2 = "hibernated"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L4_2 = A0_2.OnHibernate
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  A0_2.eHibernation = L1_2
end

L1_1.OnDehibernate = L2_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = Ai
  L4_2 = L4_2.Squad
  L5_2 = {}
  L5_2.SquadGuid = L2_2
  L5_2.Action = "GetUnits"
  L4_2 = L4_2(L5_2)
  L5_2 = pairs
  L6_2 = L4_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = Object
    L10_2 = L10_2.IsAlive
    L11_2 = L9_2
    L10_2 = L10_2(L11_2)
    if L10_2 then
      L10_2 = Ai
      L10_2 = L10_2.Anchor
      L11_2 = {}
      L11_2.AIGuid = L9_2
      L11_2.AnchorGuid = L3_2
      L11_2.AnchorRadius = 30
      L10_2(L11_2)
    end
  end
  L5_2 = Ai
  L5_2 = L5_2.Squad
  L6_2 = {}
  L6_2.SquadGuid = L2_2
  L6_2.Action = "AddCommand"
  L6_2.Goal = "MoveWithinBoundary"
  L7_2 = {}
  L8_2 = Object
  L8_2 = L8_2.GetPosition
  L9_2 = L3_2
  L8_2, L9_2, L10_2, L11_2 = L8_2(L9_2)
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L6_2.Target = L7_2
  L6_2.Radius = 10
  L6_2.Style = "defend"
  L6_2.Priority = "HiPri"
  L5_2 = L5_2(L6_2)
end

_MoveOCSquad = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "oc001.oc.boatrunner"
  L1_2 = L1_2(L2_2)
  L2_2 = Object
  L2_2 = L2_2.InVehicle
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = Vehicle
    L3_2 = L3_2.Exit
    L4_2 = L2_2
    L5_2 = L1_2
    L3_2(L4_2, L5_2)
  end
  L3_2 = Ai
  L3_2 = L3_2.Goal
  L4_2 = {}
  L4_2.AIGuid = L1_2
  L4_2.Goal = "PathMove"
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "oc001.pth.ship_patrol"
  L5_2 = L5_2(L6_2)
  L4_2.Target = L5_2
  L4_2.Haste = 0.9
  L4_2.Reverse = A0_2
  L4_2.Priority = "HiPri"
  L4_2.Force = true
  L3_2 = L3_2(L4_2)
end

_MoveOCBoatSoldier = L1_1

function L1_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = Ai
  L0_2 = L0_2.Squad
  L1_2 = {}
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "oc001.obj1.ocsquad2"
  L2_2 = L2_2(L3_2)
  L1_2.SquadGuid = L2_2
  L1_2.Action = "AddCommand"
  L1_2.Goal = "MoveWithinBoundary"
  L2_2 = {}
  L3_2 = Object
  L3_2 = L3_2.GetPosition
  L4_2 = uDefensePoint
  L3_2, L4_2 = L3_2(L4_2)
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2.Target = L2_2
  L1_2.Radius = 10
  L1_2.Style = "defend"
  L1_2.Priority = "HiPri"
  
  function L2_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = Ai
    L1_3 = L1_3.Anchor
    L2_3 = {}
    L2_3.AIGuid = A0_3
    L2_3.AnchorRadius = 30
    L3_3 = uDefensePoint
    L2_3.AnchorGuid = L3_3
    L1_3 = L1_3(L2_3)
  end
  
  L1_2.Callback = L2_2
  L0_2 = L0_2(L1_2)
end

_MoveSite3OCSquad = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  
  function L1_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3
    L1_3 = A0_2
    L2_3 = L1_3
    L1_3 = L1_3._PerformBanter
    L3_3 = "oc001.obj1.ocsquad1"
    L4_3 = "OCMerc-Briefing-Contract-Oil01-68"
    L5_3 = A0_3
    L1_3(L2_3, L3_3, L4_3, L5_3)
  end
  
  L3_2 = A0_2
  L2_2 = A0_2._PerformBanter
  L4_2 = "oc001.obj1.ocsquad1"
  L5_2 = "OCMerc-Briefing-Contract-Oil01-66"
  L6_2 = nil
  L7_2 = L1_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

_OCSavedBanter = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L5_2 = Ai
  L5_2 = L5_2.Squad
  L6_2 = {}
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = A1_2
  L7_2 = L7_2(L8_2)
  L6_2.SquadGuid = L7_2
  L6_2.Action = "GetUnits"
  L5_2 = L5_2(L6_2)
  L6_2 = pairs
  L7_2 = L5_2
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  for L9_2, L10_2 in L6_2, L7_2, L8_2 do
    if L10_2 ~= A3_2 then
      L11_2 = Object
      L11_2 = L11_2.IsAlive
      L12_2 = L10_2
      L11_2 = L11_2(L12_2)
      if L11_2 then
        L12_2 = A0_2
        L11_2 = A0_2._PlayVo
        L13_2 = L10_2
        L14_2 = A2_2
        L15_2 = A4_2
        L16_2 = {}
        L17_2 = L10_2
        L16_2[1] = L17_2
        L11_2(L12_2, L13_2, L14_2, L15_2, L16_2)
        return
      end
    end
  end
end

_PerformBanter = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = L1_2
  L6_2 = "awake"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
    L0_3 = Object
    L0_3 = L0_3.Kill
    L1_3 = L1_2
    L0_3(L1_3)
    L0_3 = Object
    L0_3 = L0_3.GetPosition
    L1_3 = L1_2
    L0_3, L1_3, L2_3 = L0_3(L1_3)
    L3_3 = Pg
    L3_3 = L3_3.Spawn
    L4_3 = "fx_Explosion_Huge"
    L5_3 = L0_3
    L6_3 = L1_3
    L7_3 = L2_3
    L8_3 = false
    L9_3 = false
    L3_3(L4_3, L5_3, L6_3, L7_3, L8_3, L9_3)
  end
  
  L2_2(L3_2, L4_2, L5_2)
end

_DestroyGate = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = _DestroyGate
  L2_2 = "_ocoutpost_wallgate 0x10001d5d"
  L1_2(L2_2)
  L1_2 = _StagingSpawnVehicle
  L2_2 = "M151 .50Cal (VZ) (DriverGunner)"
  L3_2 = "oc001.loc.staging.spawn1"
  L4_2 = "oc001.pth.staging.in1"
  L5_2 = 0.7
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  L2_2 = Object
  L2_2 = L2_2.SetHealth
  L3_2 = L1_2
  L4_2 = 8
  L2_2(L3_2, L4_2)
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "oc001.loc.stagedEnc"
  L2_2 = L2_2(L3_2)
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.ObjectProximity
  L6_2 = {}
  L7_2 = Player
  L7_2 = L7_2.GetAnyCharacter
  L7_2 = L7_2()
  L8_2 = L2_2
  L9_2 = "<"
  L10_2 = 150
  L11_2 = false
  L12_2 = false
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L6_2[5] = L11_2
  L6_2[6] = L12_2
  L7_2 = _StagingBeginSequence
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
end

_StagingSetup = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = _StagingSpawnVehicle
  L2_2 = "M151 .50Cal (VZ) (DriverGunner)"
  L3_2 = "oc001.loc.staging.spawn2"
  L4_2 = "oc001.pth.staging.in2"
  L5_2 = 0.8
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  L2_2 = Object
  L2_2 = L2_2.SetHealth
  L3_2 = L1_2
  L4_2 = 8
  L2_2(L3_2, L4_2)
  L2_2 = _StagingSpawnVehicle
  L3_2 = "EXT (DriverGunner)"
  L4_2 = "oc001.loc.staging.spawn3"
  L5_2 = "oc001.pth.staging.in3"
  L6_2 = 0.6
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L3_2 = Object
  L3_2 = L3_2.SetHealth
  L4_2 = L2_2
  L5_2 = 12
  L3_2(L4_2, L5_2)
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "oc001.loc.stagedEnc"
  L3_2 = L3_2(L4_2)
  L5_2 = A0_2
  L4_2 = A0_2._CreateEvent
  L6_2 = Event
  L6_2 = L6_2.ObjectProximity
  L7_2 = {}
  L8_2 = Player
  L8_2 = L8_2.GetAnyCharacter
  L8_2 = L8_2()
  L9_2 = L3_2
  L10_2 = "<"
  L11_2 = 15
  L12_2 = false
  L13_2 = false
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L7_2[5] = L12_2
  L7_2[6] = L13_2
  
  function L8_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = Pg
    L0_3 = L0_3.GetGuidByName
    L1_3 = "oc001.loc.stagedExp"
    L0_3 = L0_3(L1_3)
    L1_3 = MrxUtil
    L1_3 = L1_3.SpawnObject
    L2_3 = "fx_Explosion_Large"
    L3_3 = L0_3
    L1_3(L2_3, L3_3)
  end
  
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
end

_StagingBeginSequence = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L4_2 = MrxUtil
  L4_2 = L4_2.SpawnObject
  L5_2 = A0_2
  L6_2 = A1_2
  L4_2 = L4_2(L5_2, L6_2)
  L5_2 = Event
  L5_2 = L5_2.Create
  L6_2 = Event
  L6_2 = L6_2.ObjectHibernation
  L7_2 = {}
  L8_2 = L4_2
  L9_2 = "awake"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L8_2 = _StagingStartVehicle
  L9_2 = {}
  L10_2 = L4_2
  L11_2 = Pg
  L11_2 = L11_2.GetGuidByName
  L12_2 = A2_2
  L11_2 = L11_2(L12_2)
  L12_2 = A3_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L9_2[3] = L12_2
  L5_2(L6_2, L7_2, L8_2, L9_2)
  return L4_2
end

_StagingSpawnVehicle = L1_1

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  L4_2 = Ai
  L4_2 = L4_2.Goal
  L5_2 = {}
  L5_2.AIGuid = L3_2
  L5_2.Goal = "PathMove"
  L5_2.Target = A1_2
  L5_2.Haste = A2_2
  L5_2.Priority = "HiPri"
  L4_2 = L4_2(L5_2)
end

_StagingStartVehicle = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = A0_2.exec
  L5_2 = L5_2.guid
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "oc001.rgn.warehouse01"
  L6_2 = L6_2(L7_2)
  L7_2 = "exit"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = _RabbitSpawn
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
end

_RabbitSetup = L1_1

function L1_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = MrxUtil
  L0_2 = L0_2.SpawnObject
  L1_2 = "EXT (DriverGunner)"
  L2_2 = "oc001.rabbitcar"
  L0_2 = L0_2(L1_2, L2_2)
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.ObjectHibernation
  L3_2 = {}
  L4_2 = L0_2
  L5_2 = "awake"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L4_2 = _RabbitStart
  L5_2 = {}
  L6_2 = L0_2
  L5_2[1] = L6_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

_RabbitSpawn = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Vehicle
  L1_2 = L1_2.GetDriver
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L2_2 = Object
    L2_2 = L2_2.IsPlayerControlled
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    if not L2_2 then
      L2_2 = Ai
      L2_2 = L2_2.Goal
      L3_2 = {}
      L3_2.AIGuid = L1_2
      L3_2.Goal = "PathMove"
      L4_2 = Pg
      L4_2 = L4_2.GetGuidByName
      L5_2 = "oc001.pth.rabbit"
      L4_2 = L4_2(L5_2)
      L3_2.Target = L4_2
      L3_2.Haste = 0.4
      L3_2.Priority = "HiPri"
      L2_2 = L2_2(L3_2)
    end
  end
end

_RabbitStart = L1_1

function L1_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L0_2 = {}
  L1_2 = "EXT (DriverGunner) 0x000f032e"
  L2_2 = "Guntruck (OC) 0x000f032d"
  L3_2 = "Guntruck (OC) 0x000f032c"
  L4_2 = "Guntruck (OC) 0x000f032b"
  L0_2[1] = L1_2
  L0_2[2] = L2_2
  L0_2[3] = L3_2
  L0_2[4] = L4_2
  L1_2 = pairs
  L2_2 = L0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Pg
    L6_2 = L6_2.GetGuidByName
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    L7_2 = Event
    L7_2 = L7_2.Create
    L8_2 = Event
    L8_2 = L8_2.ObjectHibernation
    L9_2 = {}
    L10_2 = L6_2
    L11_2 = "awake"
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L10_2 = _SetupConvoy2
    L11_2 = {}
    L12_2 = L6_2
    L11_2[1] = L12_2
    L7_2(L8_2, L9_2, L10_2, L11_2)
  end
end

_SetupConvoy1 = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.ObjectHibernation
  L3_2 = {}
  L4_2 = A0_2
  L5_2 = "hibernated"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L4_2 = Object
  L4_2 = L4_2.Remove
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
end

_SetupConvoy2 = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2.missionBoundary
  if L2_2 then
    L2_2 = A0_2.missionBoundary
    L3_2 = L2_2
    L2_2 = L2_2.Cancel
    L2_2(L3_2)
    A0_2.missionBoundary = nil
  end
  L2_2 = Event
  L2_2 = L2_2.Delete
  L3_2 = A0_2._tEvents
  L3_2 = L3_2.eMissionBoundary
  L2_2(L3_2)
  L2_2 = A0_2._tEvents
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 75
  L5_2[1] = L6_2
  L6_2 = CreateMissionBoundary
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A1_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2.eMissionBoundary = L3_2
end

CreateMissionBoundaryDelayed = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  A1_2.fRadius = 190
  A1_2.sLabel = "[yellow][OilCon001.Objectives.timer]"
  A1_2.fWarnTime = 15
  A1_2.fFailTime = 30
  A1_2.iTray = 2
  L2_2 = A1_2.fCallback
  A1_2.fMyCallback = L2_2
  L2_2 = UpdateMissionBoundaryStatus
  A1_2.fCallback = L2_2
  L2_2 = {}
  L3_2 = A0_2
  L2_2[1] = L3_2
  A1_2.tCallbackData = L2_2
  L2_2 = MrxMissionBoundary
  L3_2 = L2_2
  L2_2 = L2_2.Create
  L4_2 = A1_2
  L2_2 = L2_2(L3_2, L4_2)
  A0_2.missionBoundary = L2_2
end

CreateMissionBoundary = L1_1

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  if A1_2 == "fail" then
    L3_2 = A0_2._tConfig
    L3_2 = L3_2.fMyCallback
    if L3_2 then
      L3_2 = A0_2._tConfig
      L3_2 = L3_2.fMyCallback
      L4_2 = A2_2
      L3_2(L4_2)
  end
  elseif A1_2 == "warning" then
    L3_2 = A2_2._tConfig
    L3_2 = L3_2.sLayer
    if L3_2 then
      L3_2 = MrxLayerManager
      L3_2 = L3_2.Add
      L4_2 = A2_2._tConfig
      L4_2 = L4_2.sLayer
      L3_2(L4_2)
    end
  end
end

UpdateMissionBoundaryStatus = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  L3_2 = A0_2._tEvents
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.ObjectDeath
  L6_2 = {}
  L7_2 = L2_2
  L6_2[1] = L7_2
  L7_2 = BuildingDestroyedWarning
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L3_2[L2_2] = L4_2
end

BuildingDestroyedSetup = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = A1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L5_2 = Object
  L5_2 = L5_2.GetPosition
  L6_2 = A0_2.exec
  L6_2 = L6_2.guid
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L8_2 = Math
  L8_2 = L8_2.Length
  L9_2 = L2_2 - L5_2
  L10_2 = 0
  L11_2 = L4_2 - L7_2
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  if L8_2 < 20 then
    L9_2 = Object
    L9_2 = L9_2.Kill
    L10_2 = A0_2.exec
    L10_2 = L10_2.guid
    L9_2(L10_2)
  else
    L9_2 = MrxVoSequence
    L9_2 = L9_2.Start
    L10_2 = {}
    L11_2 = {}
    L12_2 = "OilExec-In-Mission-Contract-Oil01-24"
    L13_2 = A0_2.exec
    L13_2 = L13_2.guid
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L12_2 = {}
    L12_2.mattias = "Mattias-In-Mission-Contract-Oil01-25"
    L12_2.jennifer = "Jennifer-In-Mission-Contract-Oil01-26"
    L12_2.chris = "Chris-In-Mission-Contract-Oil01-27"
    L13_2 = 0.5
    L14_2 = {}
    L15_2 = _MyCancel
    L14_2[1] = L15_2
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L10_2[3] = L13_2
    L10_2[4] = L14_2
    L9_2(L10_2)
  end
end

BuildingDestroyedWarning = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  L3_2 = Event
  L3_2 = L3_2.Delete
  L4_2 = A0_2._tEvents
  L4_2 = L4_2[L2_2]
  L3_2(L4_2)
  L3_2 = A0_2._tEvents
  L3_2[L2_2] = nil
end

BuildingDestroyedCleanup = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "refinery_doc_warehouse01"
  L1_2 = L1_2(L2_2)
  L2_2 = A0_2._tEvents
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectDeath
  L5_2 = {}
  L6_2 = L1_2
  L5_2[1] = L6_2
  L6_2 = FirstWarehouseDestroyed
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2[L1_2] = L3_2
end

FirstWarehouseDestroyedSetup = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Object
  L1_2 = L1_2.InsideBoundary
  L2_2 = A0_2.exec
  L2_2 = L2_2.guid
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "oc001.rgn.warehouse01"
  L3_2 = L3_2(L4_2)
  L4_2 = true
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  if L1_2 then
    L1_2 = Object
    L1_2 = L1_2.Kill
    L2_2 = A0_2.exec
    L2_2 = L2_2.guid
    L1_2(L2_2)
  end
end

FirstWarehouseDestroyed = L1_1
L1_1 = "emt_distant_battle_01"
ksMissionAmbience = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = A0_2._tEvents
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetPrimaryCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "oc001.rgn.boundary"
  L6_2 = L6_2(L7_2)
  L7_2 = "exit"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = SoundRegion_Outside
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.eSoundRgn = L2_2
  L1_2 = Sound
  L1_2 = L1_2.CueAmbience
  L2_2 = ksMissionAmbience
  L1_2(L2_2)
end

SoundRegion_Inside = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = A0_2._tEvents
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetPrimaryCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "oc001.rgn.boundary"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = SoundRegion_Inside
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.eSoundRgn = L2_2
  L1_2 = Sound
  L1_2 = L1_2.StopAmbience
  L2_2 = ksMissionAmbience
  L1_2(L2_2)
end

SoundRegion_Outside = L1_1

function L1_1(A0_2, A1_2)
end

NetEventCallback = L1_1
