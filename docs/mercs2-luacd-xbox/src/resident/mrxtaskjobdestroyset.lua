local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskJob"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxStatsManager"
L0_1(L1_1)

function L0_1(A0_2, ...)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = type
  L3_2 = arg[1]
  L2_2 = L2_2(L3_2)
  if L2_2 == "table" then
    L3_2 = arg[1]
    L4_2 = MrxTaskJob
    L4_2 = L4_2._AddTarget
    L5_2 = A0_2
    L6_2 = L3_2.sTarget
    L4_2(L5_2, L6_2)
    L5_2 = A0_2
    L4_2 = A0_2._GetTargetData
    L6_2 = L3_2.sTarget
    L4_2 = L4_2(L5_2, L6_2)
    if L4_2 then
      L5_2 = L3_2.sStagingLayer
      L4_2.sStagingLayer = L5_2
      L5_2 = L3_2.sDefenseLayer
      L4_2.sDefenseLayer = L5_2
      L5_2 = L3_2.sPristineLayer
      L4_2.sPristineLayer = L5_2
      L5_2 = L3_2.sDestroyedLayer
      L4_2.sDestroyedLayer = L5_2
    end
    L6_2 = A0_2
    L5_2 = A0_2._SetTargetMilestoneKey
    L7_2 = L3_2.sTarget
    L8_2 = L3_2.sMilestoneKey
    L5_2(L6_2, L7_2, L8_2)
  else
    L3_2 = MrxTaskJob
    L3_2 = L3_2._AddTarget
    L4_2 = A0_2
    L5_2 = unpack
    L6_2 = arg
    L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  end
end

_AddTarget = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L4_2 = A0_2
  L3_2 = A0_2._ExcludeCompletedTargets
  L3_2(L4_2)
  L4_2 = A0_2
  L3_2 = A0_2._AddToPda
  L3_2(L4_2)
  L3_2 = 0
  L5_2 = A0_2
  L4_2 = A0_2._GetPartsCompletedList
  L4_2 = L4_2(L5_2)
  if L4_2 then
    L5_2 = A0_2
    L4_2 = A0_2._GetPartsCompletedList
    L4_2 = L4_2(L5_2)
    L3_2 = #L4_2
  end
  L5_2 = A0_2
  L4_2 = A0_2.CreateChild
  L6_2 = {}
  L6_2.sName = "DestroySet"
  L6_2.sModuleName = "MrxTaskObjectiveDestroy"
  L8_2 = A0_2
  L7_2 = A0_2._GetTargetList
  L7_2 = L7_2(L8_2)
  L6_2.vTgtInclude = L7_2
  L8_2 = A0_2
  L7_2 = A0_2._GetPartsCompletedList
  L7_2 = L7_2(L8_2)
  L6_2.vTgtExclude = L7_2
  L6_2.nPartsCompleted = L3_2
  L8_2 = A0_2
  L7_2 = A0_2._GetTargetList
  L7_2 = L7_2(L8_2)
  L7_2 = #L7_2
  L7_2 = L7_2 + L3_2
  L6_2.nQuota = L7_2
  L7_2 = A0_2._sDspShortDesc
  if not L7_2 then
    L7_2 = "[Generic.ObjectiveDestroy]"
  end
  L6_2.sDspShortDesc = L7_2
  L6_2.bDspBounty = true
  L6_2.sDspBlpPdaIcon = "icon_destroy_3_mc"
  L7_2 = A0_2._bTrackOnActivate
  L6_2.bTrackOnActivate = L7_2
  L7_2 = A0_2._bSkipInitialNotifications
  L6_2.bSkipInitialNotifications = L7_2
  
  function L7_2()
    local L0_3, L1_3, L2_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._CreateNearbyEvent
    L0_3(L1_3)
    L0_3 = MrxUtil
    L0_3 = L0_3.CallWithOptionalArgs
    L1_3 = A1_2
    L2_3 = A2_2
    L0_3(L1_3, L2_3)
  end
  
  L6_2.fOnActivate = L7_2
  
  function L7_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3
    L1_3 = A0_2
    L2_3 = L1_3
    L1_3 = L1_3._GetTargetData
    L3_3 = A0_3
    L1_3 = L1_3(L2_3, L3_3)
    if L1_3 then
      L2_3 = L1_3.sPristineLayer
      if L2_3 then
        L2_3 = MrxLayerManager
        L2_3 = L2_3.MarkForRemoval
        L3_3 = L1_3.sPristineLayer
        L2_3(L3_3)
      end
      L2_3 = L1_3.sStagingLayer
      if L2_3 then
        L2_3 = MrxLayerManager
        L2_3 = L2_3.MarkForRemoval
        L3_3 = L1_3.sStagingLayer
        L2_3(L3_3)
      end
      L2_3 = L1_3.sDefenseLayer
      if L2_3 then
        L2_3 = MrxLayerManager
        L2_3 = L2_3.MarkForRemoval
        L3_3 = L1_3.sDefenseLayer
        L2_3(L3_3)
      end
      L2_3 = L1_3.sDestroyedLayer
      if L2_3 then
        L2_3 = MrxLayerManager
        L2_3 = L2_3.MarkForAddition
        L3_3 = L1_3.sDestroyedLayer
        L2_3(L3_3)
      end
    end
    L2_3 = A0_2
    L3_3 = L2_3
    L2_3 = L2_3._TargetComplete
    L4_3 = A0_3
    L2_3(L3_3, L4_3)
    L2_3 = MrxStatsManager
    L2_3 = L2_3.JobDestroyPart
    L3_3 = A0_2
    L4_3 = L3_3
    L3_3 = L3_3.GetFactionId
    L3_3, L4_3 = L3_3(L4_3)
    L2_3(L3_3, L4_3)
  end
  
  L6_2.fOnPartComplete = L7_2
  
  function L7_2()
    local L0_3, L1_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.Complete
    L0_3(L1_3)
  end
  
  L6_2.fOnComplete = L7_2
  
  function L7_2()
    local L0_3, L1_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.Cancel
    L0_3(L1_3)
  end
  
  L6_2.fOnCancel = L7_2
  L4_2 = L4_2(L5_2, L6_2)
  A0_2._oObjective = L4_2
end

_Go = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = {}
  L1_2 = "sTargetLayer"
  L2_2 = "sPristineLayer"
  L3_2 = "sStagingLayer"
  L4_2 = "sDefenseLayer"
  L0_2[1] = L1_2
  L0_2[2] = L2_2
  L0_2[3] = L3_2
  L0_2[4] = L4_2
  return L0_2
end

_GetPerTargetLayerKeys = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = 150
  return L0_2
end

_GetNearRadius = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = 200
  return L0_2
end

_GetFarRadius = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = Object
  L2_2 = L2_2.IsAlive
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2._GetTargetData
    L4_2 = A1_2
    L2_2 = L2_2(L3_2, L4_2)
    if L2_2 then
      L3_2 = L2_2.vNearVoSequence
      if L3_2 then
        L3_2 = MrxVoSequence
        L3_2 = L3_2.Start
        L4_2 = L2_2.vNearVoSequence
        L5_2 = false
        L6_2 = MrxVoSequence
        L6_2 = L6_2.knPriorityBounties
        L3_2(L4_2, L5_2, L6_2)
    end
    else
      L3_2 = MrxTaskJob
      L3_2 = L3_2._TargetNearby
      L4_2 = A0_2
      L5_2 = A1_2
      L3_2(L4_2, L5_2)
    end
  end
end

_TargetNearby = L0_1
