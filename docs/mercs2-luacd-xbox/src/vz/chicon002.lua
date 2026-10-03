local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "DangerousBuilding"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxHQManager"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = {}
  L3_2 = "vz_state_staging_oildepot"
  L4_2 = "vz_state_staging_oilhq"
  L5_2 = "vz_state_mar_city_pristine"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L3_2 = {}
  L4_2 = "vz_State_mar_city_ruined"
  L5_2 = "Vz_State_ChiCon002"
  L6_2 = "vz_state_Chicon002_Traffic"
  L7_2 = "vz_state_OC_Depot"
  L8_2 = "vz_state_OC_Depot_pristine"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L3_2[5] = L8_2
  L5_2 = A0_2
  L4_2 = A0_2._GetFlag
  L6_2 = "DepotDestroyed_New"
  L4_2 = L4_2(L5_2, L6_2)
  if L4_2 then
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L3_2
    L6_2 = "vz_state_ChiCon002_Depot_Destroyed"
    L4_2(L5_2, L6_2)
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L2_2
    L6_2 = "vz_state_ChiCon002_Depot_Pristine"
    L4_2(L5_2, L6_2)
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L2_2
    L6_2 = "vz_state_ChiCon002_Depot_Hostiles"
    L4_2(L5_2, L6_2)
  else
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L3_2
    L6_2 = "vz_state_ChiCon002_Depot_Pristine"
    L4_2(L5_2, L6_2)
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L3_2
    L6_2 = "vz_state_ChiCon002_Depot_Hostiles"
    L4_2(L5_2, L6_2)
  end
  L5_2 = A0_2
  L4_2 = A0_2._GetFlag
  L6_2 = "HQDestroyed_New"
  L4_2 = L4_2(L5_2, L6_2)
  if L4_2 then
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L3_2
    L6_2 = "vz_state_ChiCon002_HQ_Destroyed"
    L4_2(L5_2, L6_2)
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L2_2
    L6_2 = "vz_state_ChiCon002_HQ_Pristine"
    L4_2(L5_2, L6_2)
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L2_2
    L6_2 = "vz_state_ChiCon002_HQ_Hostiles"
    L4_2(L5_2, L6_2)
  else
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L3_2
    L6_2 = "vz_state_ChiCon002_HQ_Pristine"
    L4_2(L5_2, L6_2)
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L3_2
    L6_2 = "vz_state_ChiCon002_HQ_Hostiles"
    L4_2(L5_2, L6_2)
  end
  L5_2 = A0_2
  L4_2 = A0_2._GetFlag
  L6_2 = "BridgeDestroyed_New"
  L4_2 = L4_2(L5_2, L6_2)
  if L4_2 then
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L3_2
    L6_2 = "vz_state_ChiCon002_Bridge_Destroyed"
    L4_2(L5_2, L6_2)
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L2_2
    L6_2 = "vz_state_ChiCon002_Bridge_Pristine"
    L4_2(L5_2, L6_2)
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L2_2
    L6_2 = "vz_state_ChiCon002_Bridge_Hostiles"
    L4_2(L5_2, L6_2)
  else
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L3_2
    L6_2 = "vz_state_ChiCon002_Bridge_Pristine"
    L4_2(L5_2, L6_2)
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L3_2
    L6_2 = "vz_state_ChiCon002_Bridge_Hostiles"
    L4_2(L5_2, L6_2)
  end
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

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "DepotDestroyed_New"
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2._GetFlag
    L3_2 = "HQDestroyed_New"
    L1_2 = L1_2(L2_2, L3_2)
    if L1_2 then
      L2_2 = A0_2
      L1_2 = A0_2._GetFlag
      L3_2 = "BridgeDestroyed_New"
      L1_2 = L1_2(L2_2, L3_2)
      if L1_2 then
        L2_2 = A0_2
        L1_2 = A0_2.Complete
        L1_2(L2_2)
        return
      end
    end
  end
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.ChangeLineRegionSetting
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "rgn_atmo_Maracaibo"
  L2_2 = L2_2(L3_2)
  L3_2 = "warzonemar"
  L1_2(L2_2, L3_2)
  L1_2 = MrxHqManager
  L1_2 = L1_2.SetHqRespawn
  L2_2 = "OilHq"
  L3_2 = false
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "HQDestroyed_New"
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    L1_2 = _HQHealthBar
    L2_2 = A0_2
    L1_2(L2_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "DepotDestroyed_New"
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2._GetFlag
    L3_2 = "HQDestroyed_New"
    L1_2 = L1_2(L2_2, L3_2)
    if not L1_2 then
      L2_2 = A0_2
      L1_2 = A0_2._GetFlag
      L3_2 = "BridgeDestroyed_New"
      L1_2 = L1_2(L2_2, L3_2)
      if not L1_2 then
        goto lbl_63
      end
    end
  end
  L1_2 = {}
  tInitialVOTable = L1_2
  goto lbl_74
  ::lbl_63::
  L1_2 = {}
  L2_2 = "Fiona-In-Mission-Contract-Chi02-15"
  L3_2 = 0.5
  L4_2 = "Fiona-Banter-Contract-Chi02-01"
  L5_2 = 0.5
  L6_2 = {}
  L6_2.mattias = "mattias-Banter-Contract-Chi02-02"
  L6_2.jennifer = "jennifer-Banter-Contract-Chi02-03"
  L6_2.chris = "chris-Banter-Contract-Chi02-04"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  tInitialVOTable = L1_2
  ::lbl_74::
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "HQDestroyed_New"
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.CreateChild
    L3_2 = {}
    L3_2.sName = "Destroy OC Base"
    L3_2.sModuleName = "MrxTaskObjectiveDestroy"
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "_ocoutpost_bld_hq 0x000d3f3c"
    L4_2 = L4_2(L5_2)
    L3_2.vTgtInclude = L4_2
    L3_2.sDspShortDesc = "[ChiCon002.Objectives.001]"
    L4_2 = {}
    L5_2 = {}
    L6_2 = _HQDestroyedVO
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L6_2 = {}
    L7_2 = _CheckObjectiveCompletion
    L8_2 = {}
    L9_2 = A0_2
    L8_2[1] = L9_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L4_2[1] = L5_2
    L4_2[2] = L6_2
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
    L1_2(L2_2, L3_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "DepotDestroyed_New"
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.CreateChild
    L3_2 = {}
    L3_2.sName = "Destroy OC Depot"
    L3_2.sModuleName = "MrxTaskObjectiveDestroy"
    L4_2 = {}
    L5_2 = "_industrial_bld_hangar01 0x000f8044"
    L6_2 = "_port_crane01 0x000f80bb"
    L7_2 = "_merida_bld_oilwellland 0x0010a85b"
    L8_2 = "_merida_bld_oilwellland 0x0010a85c"
    L9_2 = "_industrial_bld_warehousesmall01 0x000f5fe5"
    L10_2 = "_industrial_bld_warehousesmall01 0x000f807d"
    L11_2 = "_industrial_bld_warehousesmall02 0x000fec29"
    L12_2 = "_industrial_bld_warehousesmall01 0x000fec2a"
    L13_2 = "_industrial_bld_warehousesmall01 0x000f5fe4"
    L14_2 = "_industrial_bld_warehousesmall01 0x000f5fe3"
    L15_2 = "_industrial_bld_warehousesmall02 0x000d6dcb"
    L16_2 = "_industrial_bld_warehousesmall02 0x000eb0fc"
    L17_2 = "_industrial_bld_warehousesmall01 0x000f80df"
    L18_2 = "_industrial_bld_warehousesmall01 0x000f80e0"
    L19_2 = "_industrial_bld_warehousesmall02 0x000d6cdf"
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
    L3_2.vTgtInclude = L4_2
    L3_2.sDspShortDesc = "[ChiCon002.Objectives.002]"
    
    function L4_2()
      local L0_3, L1_3, L2_3
      L0_3 = uDepotMissedEvent
      if L0_3 then
        L0_3 = Event
        L0_3 = L0_3.Delete
        L1_3 = uDepotMissedEvent
        L0_3(L1_3)
      end
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._DepotDestroyedVO
      L2_3 = A0_2
      L0_3(L1_3, L2_3)
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._CheckObjectiveCompletion
      L2_3 = A0_2
      L0_3(L1_3, L2_3)
    end
    
    L3_2.fOnComplete = L4_2
    
    function L4_2(A0_3)
      local L1_3, L2_3
      L1_3 = A0_2
      L2_3 = L1_3
      L1_3 = L1_3._DepotMissedVO
      L1_3(L2_3)
    end
    
    L3_2.fOnPartComplete = L4_2
    
    function L4_2()
      local L0_3, L1_3
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3.Cancel
      L0_3(L1_3)
    end
    
    L3_2.fOnCancel = L4_2
    L1_2(L2_2, L3_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "BridgeDestroyed_New"
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.CreateChild
    L3_2 = {}
    L3_2.sName = "Destroy Bridge"
    L3_2.sModuleName = "MrxTaskObjectiveDestroy"
    L4_2 = {}
    L5_2 = "_maracaibo_bridge_segmenta 0x0008b073"
    L6_2 = "_maracaibo_bridge_segmenta 0x00091fcc"
    L7_2 = "_maracaibo_bridge_segmenta 0x0008ab9b"
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L4_2[3] = L7_2
    L3_2.vTgtInclude = L4_2
    L3_2.sDspShortDesc = "[ChiCon002.Objectives.003]"
    
    function L4_2()
      local L0_3, L1_3, L2_3
      L0_3 = uBridgetMissedEvent
      if L0_3 then
        L0_3 = Event
        L0_3 = L0_3.Delete
        L1_3 = uBridgeMissedEvent
        L0_3(L1_3)
      end
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._BridgeDestroyedVO
      L2_3 = A0_2
      L0_3(L1_3, L2_3)
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._CheckObjectiveCompletion
      L2_3 = A0_2
      L0_3(L1_3, L2_3)
    end
    
    L3_2.fOnComplete = L4_2
    
    function L4_2(A0_3)
      local L1_3, L2_3
      L1_3 = A0_2
      L2_3 = L1_3
      L1_3 = L1_3._BridgeMissedVO
      L1_3(L2_3)
    end
    
    L3_2.fOnPartComplete = L4_2
    
    function L4_2()
      local L0_3, L1_3
      L0_3 = A0_2
      L0_3 = L0_3.Cancel
      L1_3 = A0_2
      L0_3(L1_3)
    end
    
    L3_2.fOnCancel = L4_2
    L4_2 = tInitialVOTable
    L3_2.vVoSeqOnAdd = L4_2
    L1_2(L2_2, L3_2)
  end
  L1_2 = _BridgeSpottedBoundary
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = _HQSpottedBoundary
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = _DepotSpottedBoundary
  L2_2 = A0_2
  L1_2(L2_2)
end

Activated = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L5_2 = A0_2
  L4_2 = A0_2._CreateEvent
  L6_2 = Event
  L6_2 = L6_2.ObjectHibernation
  L7_2 = {}
  L8_2 = Vehicle
  L8_2 = L8_2.GetDriver
  L9_2 = Pg
  L9_2 = L9_2.GetGuidByName
  L10_2 = A1_2
  L9_2, L10_2, L11_2, L12_2, L13_2 = L9_2(L10_2)
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  L9_2 = "awake"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L8_2 = _StartPatrol
  L9_2 = {}
  L10_2 = A0_2
  L11_2 = Vehicle
  L11_2 = L11_2.GetDriver
  L12_2 = Pg
  L12_2 = L12_2.GetGuidByName
  L13_2 = A1_2
  L12_2, L13_2 = L12_2(L13_2)
  L11_2 = L11_2(L12_2, L13_2)
  L12_2 = Pg
  L12_2 = L12_2.GetGuidByName
  L13_2 = A2_2
  L12_2 = L12_2(L13_2)
  L13_2 = A3_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L9_2[3] = L12_2
  L9_2[4] = L13_2
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
end

_SetupVehiclePatrol = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L4_2 = {}
  L4_2.AIGuid = A1_2
  L4_2.Goal = "PathMove"
  L4_2.Target = A2_2
  L4_2.Priority = "medPri"
  tGoalParams = L4_2
  L5_2 = A0_2
  L4_2 = A0_2._CreateEvent
  L6_2 = Event
  L6_2 = L6_2.TimerRelative
  L7_2 = {}
  L8_2 = 1
  L7_2[1] = L8_2
  L8_2 = Ai
  L8_2 = L8_2.Goal
  L9_2 = {}
  L10_2 = tGoalParams
  L9_2[1] = L10_2
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
end

_StartPatrol = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "DepotDestroyed_New"
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2._GetFlag
    L3_2 = "HQDestroyed_New"
    L1_2 = L1_2(L2_2, L3_2)
    if L1_2 then
      L2_2 = A0_2
      L1_2 = A0_2._GetFlag
      L3_2 = "BridgeDestroyed_New"
      L1_2 = L1_2(L2_2, L3_2)
      if L1_2 then
        L1_2 = {}
        L2_2 = "Fiona-In-Mission-Contract-Chi02-26"
        L3_2 = {}
        L4_2 = A0_2.Complete
        L5_2 = {}
        L6_2 = A0_2
        L5_2[1] = L6_2
        L3_2[1] = L4_2
        L3_2[2] = L5_2
        L1_2[1] = L2_2
        L1_2[2] = L3_2
        L2_2 = MrxVoSequence
        L2_2 = L2_2.Start
        L3_2 = L1_2
        L2_2(L3_2)
      end
    end
  end
end

_CheckObjectiveCompletion = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "_ocoutpost_bld_hq 0x000d3f3c"
  L1_2 = L1_2(L2_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.Boundary
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAnyCharacter
  L6_2 = L6_2()
  L7_2 = GetGuidByName
  L8_2 = "LR_OC_HQ_Traffic_ChiCon002 0x000f3246"
  L7_2 = L7_2(L8_2)
  L8_2 = "enter"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  
  function L6_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = MrxUtil
    L0_3 = L0_3.DisplayHealthBar
    L1_3 = A0_2
    L2_3 = L1_2
    L3_3 = 0
    L4_3 = true
    L5_3 = 0
    L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._CreateEvent
    L2_3 = Event
    L2_3 = L2_3.Boundary
    L3_3 = {}
    L4_3 = Player
    L4_3 = L4_3.GetAnyCharacter
    L4_3 = L4_3()
    L5_3 = GetGuidByName
    L6_3 = "LR_ChiCon2_HeloAttackHQ"
    L5_3 = L5_3(L6_3)
    L6_3 = "exit"
    L3_3[1] = L4_3
    L3_3[2] = L5_3
    L3_3[3] = L6_3
    
    function L4_3()
      local L0_4, L1_4
      L0_4 = MrxUtil
      L0_4 = L0_4.StopHealthBar
      L1_4 = L1_2
      L0_4(L1_4)
      L0_4 = _HQHealthBar
      L1_4 = A0_2
      L0_4(L1_4)
    end
    
    L0_3(L1_3, L2_3, L3_3, L4_3)
  end
  
  L2_2(L3_2, L4_2, L5_2, L6_2)
end

_HQHealthBar = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetPrimaryCharacter
  L5_2 = L5_2()
  L6_2 = GetGuidByName
  L7_2 = "LR_Gurcon001_BridgeView"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = _BridgeSpottedVO
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

_BridgeSpottedBoundary = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "BridgeDestroyed_New"
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    L1_2 = Object
    L1_2 = L1_2.IsVisible
    L2_2 = Pg
    L2_2 = L2_2.GetGuidByName
    L3_2 = "_maracaibo_bridge_segmenta 0x00091fcc"
    L2_2, L3_2, L4_2, L5_2, L6_2, L7_2 = L2_2(L3_2)
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
    if not L1_2 then
      L1_2 = Object
      L1_2 = L1_2.IsVisible
      L2_2 = Pg
      L2_2 = L2_2.GetGuidByName
      L3_2 = "_maracaibo_bridge_segmentb 0x0008b074"
      L2_2, L3_2, L4_2, L5_2, L6_2, L7_2 = L2_2(L3_2)
      L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
      if not L1_2 then
        L1_2 = Object
        L1_2 = L1_2.IsVisible
        L2_2 = Pg
        L2_2 = L2_2.GetGuidByName
        L3_2 = "_maracaibo_bridge_segmentb 0x0008ab9c"
        L2_2, L3_2, L4_2, L5_2, L6_2, L7_2 = L2_2(L3_2)
        L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
        if not L1_2 then
          goto lbl_47
        end
      end
    end
    L1_2 = MrxVoSequence
    L1_2 = L1_2.Start
    L2_2 = {}
    L3_2 = "Fiona-In-Mission-Contract-Chi02-27"
    L2_2[1] = L3_2
    L1_2(L2_2)
    L1_2 = Sound
    L1_2 = L1_2.SetActionLevelsMusic
    L2_2 = 15
    L3_2 = 0
    L4_2 = 0
    L5_2 = 0
    L1_2(L2_2, L3_2, L4_2, L5_2)
    goto lbl_58
    ::lbl_47::
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = 1
    L4_2[1] = L5_2
    L5_2 = _BridgeSpottedVO
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  end
  ::lbl_58::
end

_BridgeSpottedVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = uBridgeMissedEvent
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uBridgeMissedEvent
    L1_2(L2_2)
  end
  L1_2 = {}
  L2_2 = "Fiona-In-Mission-Contract-Chi02-32"
  L3_2 = "Fiona-In-Mission-Contract-Chi02-37"
  L4_2 = "Fiona-In-Mission-Contract-Chi02-38"
  L5_2 = "Fiona-In-Mission-Contract-Chi02-39"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L2_2 = MrxUtil
  L2_2 = L2_2.GetRandomTableElement
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = 45
  L6_2[1] = L7_2
  L7_2 = MrxVoSequence
  L7_2 = L7_2.Start
  L8_2 = {}
  L9_2 = L2_2
  L8_2[1] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  uBridgeMissedEvent = L3_2
end

_BridgeMissedVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Pg
  L1_2 = L1_2.EnableIntersection
  L2_2 = false
  L3_2 = StringToGuid
  L4_2 = "_maracaibo_bridge_segmentb 0x0008ab9c"
  L3_2, L4_2 = L3_2(L4_2)
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Pg
  L1_2 = L1_2.EnableIntersection
  L2_2 = false
  L3_2 = StringToGuid
  L4_2 = "_maracaibo_bridge_segmentb 0x0008b074"
  L3_2, L4_2 = L3_2(L4_2)
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = uBridgeMissedEvent
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uBridgeMissedEvent
    L1_2(L2_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2._SetFlag
  L3_2 = "BridgeDestroyed_New"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "DepotDestroyed_New"
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2._GetFlag
    L3_2 = "HQDestroyed_New"
    L1_2 = L1_2(L2_2, L3_2)
    if L1_2 then
  end
  else
    L2_2 = A0_2
    L1_2 = A0_2._GetFlag
    L3_2 = "DepotDestroyed_New"
    L1_2 = L1_2(L2_2, L3_2)
    if L1_2 then
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = "Fiona-In-Mission-Contract-Chi02-19"
      L2_2[1] = L3_2
      L1_2(L2_2)
    else
      L2_2 = A0_2
      L1_2 = A0_2._GetFlag
      L3_2 = "HQDestroyed_New"
      L1_2 = L1_2(L2_2, L3_2)
      if L1_2 then
        L1_2 = MrxVoSequence
        L1_2 = L1_2.Start
        L2_2 = {}
        L3_2 = "Fiona-In-Mission-Contract-Chi02-18"
        L2_2[1] = L3_2
        L1_2(L2_2)
      else
        L1_2 = MrxVoSequence
        L1_2 = L1_2.Start
        L2_2 = {}
        L3_2 = "Fiona-In-Mission-Contract-Chi02-17"
        L2_2[1] = L3_2
        L1_2(L2_2)
      end
    end
  end
  L1_2 = _Checkpoint
  L2_2 = {}
  L3_2 = "CP_Bridge_P1"
  L4_2 = "CP_Bridge_P2"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
end

_BridgeDestroyedVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetPrimaryCharacter
  L5_2 = L5_2()
  L6_2 = GetGuidByName
  L7_2 = "LR_ChiCon2_HeloAttackHQ"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = _HQSpottedVO
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

_HQSpottedBoundary = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "HQDestroyed_New"
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    L1_2 = Object
    L1_2 = L1_2.IsVisible
    L2_2 = Pg
    L2_2 = L2_2.GetGuidByName
    L3_2 = "_ocoutpost_bld_hq 0x000d3f3c"
    L2_2, L3_2, L4_2, L5_2, L6_2, L7_2 = L2_2(L3_2)
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
    if L1_2 then
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = "Fiona-In-Mission-Contract-Chi02-28"
      L2_2[1] = L3_2
      L1_2(L2_2)
      L1_2 = Sound
      L1_2 = L1_2.SetActionLevelsMusic
      L2_2 = 15
      L3_2 = 0
      L4_2 = 0
      L5_2 = 0
      L1_2(L2_2, L3_2, L4_2, L5_2)
    else
      L2_2 = A0_2
      L1_2 = A0_2._CreateEvent
      L3_2 = Event
      L3_2 = L3_2.TimerRelative
      L4_2 = {}
      L5_2 = 1
      L4_2[1] = L5_2
      L5_2 = _HQSpottedVO
      L6_2 = {}
      L7_2 = A0_2
      L6_2[1] = L7_2
      L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
    end
  end
end

_HQSpottedVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "_ocoutpost_bld_hq 0x000d3f3c"
  L1_2 = L1_2(L2_2)
  L2_2 = MrxUtil
  L2_2 = L2_2.StopHealthBar
  L3_2 = L1_2
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2._SetFlag
  L4_2 = "HQDestroyed_New"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._GetFlag
  L4_2 = "DepotDestroyed_New"
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2._GetFlag
    L4_2 = "BridgeDestroyed_New"
    L2_2 = L2_2(L3_2, L4_2)
    if L2_2 then
  end
  else
    L3_2 = A0_2
    L2_2 = A0_2._GetFlag
    L4_2 = "DepotDestroyed_New"
    L2_2 = L2_2(L3_2, L4_2)
    if L2_2 then
      L2_2 = MrxVoSequence
      L2_2 = L2_2.Start
      L3_2 = {}
      L4_2 = "Fiona-In-Mission-Contract-Chi02-25"
      L3_2[1] = L4_2
      L2_2(L3_2)
    else
      L3_2 = A0_2
      L2_2 = A0_2._GetFlag
      L4_2 = "BridgeDestroyed_New"
      L2_2 = L2_2(L3_2, L4_2)
      if L2_2 then
        L2_2 = MrxVoSequence
        L2_2 = L2_2.Start
        L3_2 = {}
        L4_2 = "Fiona-In-Mission-Contract-Chi02-24"
        L3_2[1] = L4_2
        L2_2(L3_2)
      else
        L2_2 = MrxVoSequence
        L2_2 = L2_2.Start
        L3_2 = {}
        L4_2 = "Fiona-In-Mission-Contract-Chi02-23"
        L3_2[1] = L4_2
        L2_2(L3_2)
      end
    end
  end
  L2_2 = _Checkpoint
  L3_2 = {}
  L4_2 = "CP_HQ_P1"
  L5_2 = "CP_HQ_P2"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L2_2(L3_2)
end

_HQDestroyedVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetPrimaryCharacter
  L5_2 = L5_2()
  L6_2 = GetGuidByName
  L7_2 = "LR_Gurcon001_DepotView"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = _DepotSpottedVO
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

_DepotSpottedBoundary = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "DepotDestroyed_New"
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    L1_2 = Object
    L1_2 = L1_2.IsVisible
    L2_2 = Pg
    L2_2 = L2_2.GetGuidByName
    L3_2 = "_port_crane01 0x000f80bb"
    L2_2, L3_2, L4_2, L5_2, L6_2, L7_2 = L2_2(L3_2)
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
    if not L1_2 then
      L1_2 = Object
      L1_2 = L1_2.IsVisible
      L2_2 = Pg
      L2_2 = L2_2.GetGuidByName
      L3_2 = "_ocoutpost_wallgate 0x000f9a63"
      L2_2, L3_2, L4_2, L5_2, L6_2, L7_2 = L2_2(L3_2)
      L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
      if not L1_2 then
        L1_2 = Object
        L1_2 = L1_2.IsVisible
        L2_2 = Pg
        L2_2 = L2_2.GetGuidByName
        L3_2 = "_merida_bld_oilwellland 0x0010a85c"
        L2_2, L3_2, L4_2, L5_2, L6_2, L7_2 = L2_2(L3_2)
        L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
        if not L1_2 then
          goto lbl_47
        end
      end
    end
    L1_2 = MrxVoSequence
    L1_2 = L1_2.Start
    L2_2 = {}
    L3_2 = "Fiona-In-Mission-Contract-Chi02-29"
    L2_2[1] = L3_2
    L1_2(L2_2)
    L1_2 = Sound
    L1_2 = L1_2.SetActionLevelsMusic
    L2_2 = 15
    L3_2 = 0
    L4_2 = 0
    L5_2 = 0
    L1_2(L2_2, L3_2, L4_2, L5_2)
    goto lbl_58
    ::lbl_47::
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = 1
    L4_2[1] = L5_2
    L5_2 = _DepotSpottedVO
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  end
  ::lbl_58::
end

_DepotSpottedVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = uDepotMissedEvent
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uDepotMissedEvent
    L1_2(L2_2)
  end
  L1_2 = {}
  L2_2 = "Fiona-In-Mission-Contract-Chi02-30"
  L3_2 = "Fiona-In-Mission-Contract-Chi02-36"
  L4_2 = "Fiona-In-Mission-Contract-Chi02-41"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L2_2 = MrxUtil
  L2_2 = L2_2.GetRandomTableElement
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = 45
  L6_2[1] = L7_2
  L7_2 = MrxVoSequence
  L7_2 = L7_2.Start
  L8_2 = {}
  L9_2 = L2_2
  L8_2[1] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  uDepotMissedEvent = L3_2
end

_DepotMissedVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = uDepotMissedEvent
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uDepotMissedEvent
    L1_2(L2_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2._SetFlag
  L3_2 = "DepotDestroyed_New"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "HQDestroyed_New"
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2._GetFlag
    L3_2 = "BridgeDestroyed_New"
    L1_2 = L1_2(L2_2, L3_2)
    if L1_2 then
  end
  else
    L2_2 = A0_2
    L1_2 = A0_2._GetFlag
    L3_2 = "HQDestroyed_New"
    L1_2 = L1_2(L2_2, L3_2)
    if L1_2 then
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = "Fiona-In-Mission-Contract-Chi02-25"
      L2_2[1] = L3_2
      L1_2(L2_2)
    else
      L2_2 = A0_2
      L1_2 = A0_2._GetFlag
      L3_2 = "BridgeDestroyed_New"
      L1_2 = L1_2(L2_2, L3_2)
      if L1_2 then
        L1_2 = MrxVoSequence
        L1_2 = L1_2.Start
        L2_2 = {}
        L3_2 = "Fiona-In-Mission-Contract-Chi02-21"
        L2_2[1] = L3_2
        L1_2(L2_2)
      else
        L1_2 = MrxVoSequence
        L1_2 = L1_2.Start
        L2_2 = {}
        L3_2 = "Fiona-In-Mission-Contract-Chi02-20"
        L2_2[1] = L3_2
        L1_2(L2_2)
      end
    end
  end
  L1_2 = _Checkpoint
  L2_2 = {}
  L3_2 = "CP_Depot_P1"
  L4_2 = "CP_Depot_P2"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
end

_DepotDestroyedVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "_ocoutpost_bld_hq 0x000d3f3c"
  L1_2 = L1_2(L2_2)
  L2_2 = MrxUtil
  L2_2 = L2_2.StopHealthBar
  L3_2 = L1_2
  L2_2(L3_2)
  L2_2 = MrxLayerManager
  L2_2 = L2_2.MarkForRemoval
  L3_2 = "vz_state_Chicon002_Traffic"
  L2_2(L3_2)
  L2_2 = MrxLayerManager
  L2_2 = L2_2.MarkForRemoval
  L3_2 = "Vz_State_ChiCon002"
  L2_2(L3_2)
  L2_2 = MrxLayerManager
  L2_2 = L2_2.MarkForRemoval
  L3_2 = "vz_state_ChiCon002_Depot_Hostiles"
  L2_2(L3_2)
  L2_2 = MrxLayerManager
  L2_2 = L2_2.MarkForRemoval
  L3_2 = "vz_state_ChiCon002_HQ_Hostiles"
  L2_2(L3_2)
  L2_2 = MrxLayerManager
  L2_2 = L2_2.MarkForRemoval
  L3_2 = "vz_state_ChiCon002_Bridge_Hostiles"
  L2_2(L3_2)
  L2_2 = MrxTaskContract
  L2_2 = L2_2.Cleanup
  L3_2 = A0_2
  L2_2(L3_2)
end

Cleanup = L0_1
