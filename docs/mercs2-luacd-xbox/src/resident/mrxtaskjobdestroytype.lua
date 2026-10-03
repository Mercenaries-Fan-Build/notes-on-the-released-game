local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskJob"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  A0_2._sLabelFilter = A1_2
end

_SetLabelFilter = L0_1

function L0_1(A0_2, A1_2)
  A0_2._nQuota = A1_2
end

_SetQuota = L0_1

function L0_1(A0_2, A1_2)
  A0_2._bDspMsg = A1_2
end

_SetMessageDisplay = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L4_2 = A0_2
  L3_2 = A0_2._ExcludeCompletedTargets
  L3_2(L4_2)
  L4_2 = A0_2
  L3_2 = A0_2._AddToPda
  L3_2(L4_2)
  L3_2 = 0
  L4_2 = A0_2._nTargetsComplete
  if L4_2 then
    L3_2 = A0_2._nTargetsComplete
  end
  L5_2 = A0_2
  L4_2 = A0_2.CreateChild
  L6_2 = {}
  L6_2.sName = "DestroyType"
  L6_2.sModuleName = "MrxTaskObjectiveDestroy"
  L7_2 = A0_2._sLabelFilter
  L6_2.sTgtLabelFilter = L7_2
  L6_2.nPartsCompleted = L3_2
  L7_2 = A0_2._bDspMsg
  L6_2.bDspMsg = L7_2
  L7_2 = A0_2._sDspShortDesc
  if not L7_2 then
    L7_2 = "[Generic.StandingBounty]"
  end
  L6_2.sDspShortDesc = L7_2
  L6_2.bDspBounty = true
  L7_2 = A0_2._bHeroOnly
  L6_2.bHeroOnly = L7_2
  L7_2 = A0_2._bSkipInitialNotifications
  L6_2.bSkipInitialNotifications = L7_2
  L7_2 = A0_2._nQuota
  L6_2.nQuota = L7_2
  L6_2.bDspMsgUpd = false
  
  function L7_2()
    local L0_3, L1_3, L2_3
    L0_3 = MrxUtil
    L0_3 = L0_3.CallWithOptionalArgs
    L1_3 = A1_2
    L2_3 = A2_2
    L0_3(L1_3, L2_3)
  end
  
  L6_2.fOnActivate = L7_2
  
  function L7_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = A0_2
    L2_3 = L1_3
    L1_3 = L1_3._TargetComplete
    L3_3 = A0_3
    L1_3(L2_3, L3_3)
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

function L0_1(A0_2, A1_2)
  A0_2._bHeroOnly = A1_2
end

_SetHeroOnly = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = false
  return L0_2
end

_GetAutosaveMode = L0_1
