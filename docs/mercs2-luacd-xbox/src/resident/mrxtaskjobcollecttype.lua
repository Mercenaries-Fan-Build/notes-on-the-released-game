local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskJob"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxStatsManager"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  A0_2._sLabelFilter = A1_2
end

_SetLabelFilter = L0_1

function L0_1(A0_2, A1_2)
  A0_2._nQuota = A1_2
end

_SetQuota = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = A0_2
  L1_2 = A0_2._ExcludeCompletedTargets
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._AddToPda
  L1_2(L2_2)
  L1_2 = A0_2._tSaveData
  L2_2 = 0
  L3_2 = {}
  if L1_2 then
    L4_2 = L1_2.tCollected
    if L4_2 then
      L4_2 = ipairs
      L5_2 = L1_2.tCollected
      L4_2, L5_2, L6_2 = L4_2(L5_2)
      for L7_2, L8_2 in L4_2, L5_2, L6_2 do
        L9_2 = A0_2._tCollectedItems
        L9_2[L8_2] = true
        L9_2 = _DisableCollectable
        L10_2 = L8_2
        L9_2(L10_2)
        L2_2 = L2_2 + 1
        L9_2 = table
        L9_2 = L9_2.insert
        L10_2 = L3_2
        L11_2 = L8_2
        L9_2(L10_2, L11_2)
      end
    end
  end
  L5_2 = A0_2
  L4_2 = A0_2.CreateChild
  L6_2 = {}
  L6_2.sName = "CollectType"
  L6_2.sModuleName = "MrxTaskObjectiveDestroy"
  L7_2 = A0_2._sLabelFilter
  L6_2.sTgtLabelFilter = L7_2
  L7_2 = A0_2._sDspShortDesc
  L6_2.sDspShortDesc = L7_2
  L6_2.bDspCollectible = true
  L7_2 = A0_2._bSkipInitialNotifications
  L6_2.bSkipInitialNotifications = L7_2
  L7_2 = A0_2._nQuota
  L6_2.nQuota = L7_2
  L6_2.vTgtExclude = L3_2
  
  function L7_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3
    L1_3 = MrxStatsManager
    L1_3 = L1_3.CompleteToolboxPart
    L1_3()
    L1_3 = Object
    L1_3 = L1_3.GetCashValue
    L2_3 = A0_3
    L1_3 = L1_3(L2_3)
    if L1_3 then
      L2_3 = MrxPmc
      L2_3 = L2_3.AddCashQty
      L3_3 = L1_3
      L4_3 = true
      L5_3 = "[Generic.Collectibles]"
      L2_3(L3_3, L4_3, L5_3)
    end
    L2_3 = A0_2
    L2_3 = L2_3._oObjective
    L2_3 = L2_3._tConfig
    L3_3 = Object
    L3_3 = L3_3.GetLocalizedName
    L4_3 = A0_3
    L3_3 = L3_3(L4_3)
    L2_3.sDspShortDesc = L3_3
    L2_3 = A0_2
    L3_3 = L2_3
    L2_3 = L2_3._RecordCollectedItem
    L4_3 = A0_3
    L2_3(L3_3, L4_3)
    L2_3 = A0_2
    L3_3 = L2_3
    L2_3 = L2_3._TargetComplete
    L4_3 = A0_3
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
  L6_2.nPartsCompleted = L2_2
  L4_2 = L4_2(L5_2, L6_2)
  A0_2._oObjective = L4_2
end

_Go = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Object
  L1_2 = L1_2.AddLabel
  L2_2 = A0_2
  L3_2 = "CollectableInvalidated"
  L1_2(L2_2, L3_2)
end

_DisableCollectable = L0_1

function L0_1(A0_2, A1_2)
  A0_2._sCollectName = A1_2
end

_SetCollectName = L0_1

function L0_1(A0_2, A1_2)
  local L2_2
  if A1_2 then
    L2_2 = A0_2._tCollectedItems
    L2_2[A1_2] = true
  end
end

_RecordCollectedItem = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = {}
  A0_2._tCollectedItems = L2_2
  L2_2 = MrxTaskJob
  L2_2 = L2_2.LoadAssets
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
  if A1_2 then
    L2_2 = pairs
    L3_2 = A1_2.tCollected
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2, L6_2 in L2_2, L3_2, L4_2 do
      if L6_2 then
        L7_2 = _DisableCollectable
        L8_2 = L5_2
        L7_2(L8_2)
      end
    end
  end
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = MrxTaskJob
  L1_2 = L1_2.SaveInstance
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = {}
  L1_2.tCollected = L2_2
  L2_2 = pairs
  L3_2 = A0_2._tCollectedItems
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    if L6_2 then
      L7_2 = table
      L7_2 = L7_2.insert
      L8_2 = L1_2.tCollected
      L9_2 = L5_2
      L7_2(L8_2, L9_2)
    end
  end
  return L1_2
end

SaveInstance = L0_1
