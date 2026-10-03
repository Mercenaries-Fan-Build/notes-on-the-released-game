local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxLayerManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTaskState"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTimer"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  if not A1_2 then
    L2_2 = {}
    A1_2 = L2_2
  end
  L2_2 = setmetatable
  L3_2 = A1_2
  L4_2 = {}
  L4_2.__index = A0_2
  L2_2(L3_2, L4_2)
  L2_2 = {}
  A1_2._tChildren = L2_2
  L2_2 = {}
  A1_2._tConfig = L2_2
  return A1_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = A0_2
  L1_2 = A0_2.IsLatent
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    L1_2 = A0_2._bCleanedUp
    if not L1_2 then
      L2_2 = A0_2
      L1_2 = A0_2.GetParent
      L1_2 = L1_2(L2_2)
      if L1_2 then
        L3_2 = L1_2
        L2_2 = L1_2._RemoveChild
        L5_2 = A0_2
        L4_2 = A0_2.GetName
        L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L4_2(L5_2)
        L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
      end
      L2_2 = A0_2._tEvents
      if L2_2 then
        L2_2 = pairs
        L3_2 = A0_2._tEvents
        L2_2, L3_2, L4_2 = L2_2(L3_2)
        for L5_2, L6_2 in L2_2, L3_2, L4_2 do
          L7_2 = Event
          L7_2 = L7_2.Delete
          L8_2 = L6_2
          L7_2(L8_2)
        end
      end
      L2_2 = A0_2._oTimer
      if L2_2 then
        L2_2 = A0_2._oTimer
        L3_2 = L2_2
        L2_2 = L2_2.Stop
        L2_2(L3_2)
      end
      L3_2 = A0_2
      L2_2 = A0_2.GetConfig
      L2_2 = L2_2(L3_2)
      L3_2 = type
      L4_2 = L2_2.tLayers
      L3_2 = L3_2(L4_2)
      if L3_2 == "table" then
        L3_2 = ipairs
        L4_2 = L2_2.tLayers
        L3_2, L4_2, L5_2 = L3_2(L4_2)
        for L6_2, L7_2 in L3_2, L4_2, L5_2 do
          L8_2 = MrxLayerManager
          L8_2 = L8_2.MarkForRemoval
          L9_2 = L7_2
          L8_2(L9_2)
        end
      end
      L4_2 = A0_2
      L3_2 = A0_2.GetConfig
      L3_2 = L3_2(L4_2)
      L3_2 = L3_2.sModuleName
      if L3_2 then
        L4_2 = dynamic_remove
        L5_2 = L2_2.sModuleName
        L4_2(L5_2)
      end
      L4_2 = setmetatable
      L5_2 = A0_2
      L6_2 = {}
      L7_2 = _THIS
      L6_2.__index = L7_2
      L4_2(L5_2, L6_2)
      L5_2 = A0_2
      L4_2 = A0_2.GetChildren
      L4_2 = L4_2(L5_2)
      L5_2 = pairs
      L6_2 = L4_2
      L5_2, L6_2, L7_2 = L5_2(L6_2)
      for L8_2, L9_2 in L5_2, L6_2, L7_2 do
        L11_2 = L9_2
        L10_2 = L9_2.Cleanup
        L10_2(L11_2)
      end
      L5_2 = {}
      A0_2._tChildren = L5_2
      A0_2._bCleanedUp = true
    else
    end
  end
end

Cleanup = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = {}
  L2_2.tOnActivate = true
  L2_2.fOnActivate = true
  L2_2.tOnComplete = true
  L2_2.fOnComplete = true
  L2_2.tOnCancel = true
  L2_2.fOnCancel = true
  L3_2 = L2_2[A1_2]
  if L3_2 then
    L3_2 = true
    return L3_2
  end
  L3_2 = false
  return L3_2
end

IsLiveConfigureable = L0_1

function L0_1(A0_2)
  local L1_2
end

ReinterpretConfig = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = _THIS
  L3_2 = L2_2
  L2_2 = L2_2.Create
  L2_2 = L2_2(L3_2)
  L4_2 = L2_2
  L3_2 = L2_2.Configure
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.Configure
  L5_2 = {}
  L5_2.oParent = A0_2
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.Activate
  L3_2(L4_2)
  return L2_2
end

CreateChild = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2
  L1_2 = A0_2.IsActive
  L1_2 = L1_2(L2_2)
  if L1_2 then
    return
  end
  L2_2 = A0_2
  L1_2 = A0_2._SetState
  L3_2 = MrxTaskState
  L3_2 = L3_2._knActive
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._IssueStateChangeCallbacks
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = type
  L3_2 = L1_2.tTimerParams
  L2_2 = L2_2(L3_2)
  if L2_2 == "table" then
    L2_2 = L1_2.tTimerParams
    L3_2 = L1_2.tTimerParams
    L3_2 = L3_2.tDoneCallbacks
    if not L3_2 then
      L3_2 = {}
      L4_2 = {}
      L5_2 = A0_2.Cancel
      L6_2 = {}
      L7_2 = A0_2
      L6_2[1] = L7_2
      L4_2[1] = L5_2
      L4_2[2] = L6_2
      L3_2[1] = L4_2
    end
    L2_2.tDoneCallbacks = L3_2
    L2_2 = MrxTimer
    L3_2 = L2_2
    L2_2 = L2_2.Create
    L4_2 = L1_2.tTimerParams
    L2_2 = L2_2(L3_2, L4_2)
    A0_2._oTimer = L2_2
    L2_2 = L1_2.tTimerParams
    L2_2 = L2_2.bTaskManualStart
    if not L2_2 then
      L2_2 = A0_2._oTimer
      L3_2 = L2_2
      L2_2 = L2_2.Start
      L2_2(L3_2)
    end
  else
    L2_2 = type
    L3_2 = L1_2.nTimeLimit
    L2_2 = L2_2(L3_2)
    if L2_2 == "number" then
      L2_2 = MrxTimer
      L3_2 = L2_2
      L2_2 = L2_2.Create
      L4_2 = {}
      L5_2 = L1_2.nTimeLimit
      L4_2.nStartTime = L5_2
      L5_2 = {}
      L6_2 = {}
      L7_2 = A0_2.Cancel
      L8_2 = {}
      L9_2 = A0_2
      L8_2[1] = L9_2
      L6_2[1] = L7_2
      L6_2[2] = L8_2
      L5_2[1] = L6_2
      L4_2.tDoneCallbacks = L5_2
      L2_2 = L2_2(L3_2, L4_2)
      A0_2._oTimer = L2_2
      L2_2 = A0_2._oTimer
      L3_2 = L2_2
      L2_2 = L2_2.Start
      L2_2(L3_2)
    end
  end
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2.IsCompleted
  L1_2 = L1_2(L2_2)
  if L1_2 then
    return
  end
  L2_2 = A0_2
  L1_2 = A0_2.Cleanup
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._SetState
  L3_2 = MrxTaskState
  L3_2 = L3_2._knCompleted
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._IssueStateChangeCallbacks
  L1_2(L2_2)
end

Complete = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2.IsCancelled
  L1_2 = L1_2(L2_2)
  if L1_2 then
    return
  end
  L2_2 = A0_2
  L1_2 = A0_2.Cleanup
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._SetState
  L3_2 = MrxTaskState
  L3_2 = L3_2._knCancelled
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._IssueStateChangeCallbacks
  L1_2(L2_2)
end

Cancel = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = A0_2
  L2_2 = A0_2._GetState
  L2_2 = L2_2(L3_2)
  if L2_2 == A1_2 then
    L3_2 = false
    return L3_2
  end
  A0_2._nState = A1_2
  L4_2 = A0_2
  L3_2 = A0_2.IsCompleted
  L3_2 = L3_2(L4_2)
  L5_2 = A0_2
  L4_2 = A0_2.IsCancelled
  L4_2 = L4_2(L5_2)
  if L3_2 or L4_2 then
    L6_2 = A0_2
    L5_2 = A0_2._SetChildrenState
    L7_2 = A1_2
    L5_2(L6_2, L7_2)
  end
  L5_2 = true
  return L5_2
end

_SetState = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L2_2 = A0_2
  L1_2 = A0_2.IsLatent
  L1_2 = L1_2(L2_2)
  L3_2 = A0_2
  L2_2 = A0_2.IsActive
  L2_2 = L2_2(L3_2)
  L4_2 = A0_2
  L3_2 = A0_2.IsCompleted
  L3_2 = L3_2(L4_2)
  L5_2 = A0_2
  L4_2 = A0_2.IsCancelled
  L4_2 = L4_2(L5_2)
  if not L1_2 then
    L6_2 = A0_2
    L5_2 = A0_2.GetConfig
    L5_2 = L5_2(L6_2)
    L6_2 = nil
    if L2_2 then
      L6_2 = L5_2.tOnActivate
    elseif L3_2 then
      L6_2 = L5_2.tOnComplete
    elseif L4_2 then
      L6_2 = L5_2.tOnCancel
    end
    if L6_2 then
      L7_2 = ipairs
      L8_2 = L6_2
      L7_2, L8_2, L9_2 = L7_2(L8_2)
      for L10_2, L11_2 in L7_2, L8_2, L9_2 do
        L12_2 = MrxUtil
        L12_2 = L12_2.CallWithOptionalArgs
        L13_2 = L11_2[1]
        L14_2 = L11_2[2]
        L12_2(L13_2, L14_2)
      end
    end
    L7_2 = nil
    if L2_2 then
      L7_2 = L5_2.fOnActivate
    elseif L3_2 then
      L7_2 = L5_2.fOnComplete
    elseif L4_2 then
      L7_2 = L5_2.fOnCancel
    end
    if L7_2 then
      L8_2 = L7_2
      L8_2()
    end
  end
end

_IssueStateChangeCallbacks = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2._SetState
    L10_2 = A1_2
    L8_2(L9_2, L10_2)
  end
end

_SetChildrenState = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2._SetState
  L3_2 = MrxTaskState
  L3_2 = L3_2._knLatent
  L1_2(L2_2, L3_2)
end

_ResetState = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2._GetState
  L1_2 = L1_2(L2_2)
  L2_2 = MrxTaskState
  L2_2 = L2_2._knLatent
  L1_2 = L1_2 == L2_2
  return L1_2
end

IsLatent = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2._GetState
  L1_2 = L1_2(L2_2)
  L2_2 = MrxTaskState
  L2_2 = L2_2._knActive
  L1_2 = L1_2 == L2_2
  return L1_2
end

IsActive = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2._GetState
  L1_2 = L1_2(L2_2)
  L2_2 = MrxTaskState
  L2_2 = L2_2._knCompleted
  L1_2 = L1_2 == L2_2
  return L1_2
end

IsCompleted = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2._GetState
  L1_2 = L1_2(L2_2)
  L2_2 = MrxTaskState
  L2_2 = L2_2._knCancelled
  L1_2 = L1_2 == L2_2
  return L1_2
end

IsCancelled = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2._nState
  if L2_2 then
    L1_2 = A0_2._nState
  else
    L2_2 = MrxTaskState
    L1_2 = L2_2._knLatent
  end
  return L1_2
end

_GetState = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if L2_2 ~= "table" then
    L2_2 = false
    return L2_2
  end
  L3_2 = A0_2
  L2_2 = A0_2.IsLatent
  L2_2 = L2_2(L3_2)
  L4_2 = A0_2
  L3_2 = A0_2.IsActive
  L3_2 = L3_2(L4_2)
  if L2_2 then
    L4_2 = pairs
    L5_2 = A1_2
    L4_2, L5_2, L6_2 = L4_2(L5_2)
    for L7_2, L8_2 in L4_2, L5_2, L6_2 do
      L9_2 = A0_2._tConfig
      L9_2[L7_2] = L8_2
    end
    L4_2 = A1_2.oParent
    if L4_2 then
      L4_2 = A1_2.oParent
      L5_2 = L4_2
      L4_2 = L4_2._AddChild
      L6_2 = A0_2
      L4_2(L5_2, L6_2)
    end
    L4_2 = true
    return L4_2
  elseif L3_2 then
    L4_2 = pairs
    L5_2 = A1_2
    L4_2, L5_2, L6_2 = L4_2(L5_2)
    for L7_2, L8_2 in L4_2, L5_2, L6_2 do
      L10_2 = A0_2
      L9_2 = A0_2.IsLiveConfigureable
      L11_2 = L7_2
      L9_2 = L9_2(L10_2, L11_2)
      if L9_2 then
        L9_2 = A0_2._tConfig
        L9_2[L7_2] = L8_2
      else
      end
    end
    L5_2 = A0_2
    L4_2 = A0_2.ReinterpretConfig
    L4_2(L5_2)
    L4_2 = true
    return L4_2
  end
end

Configure = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2._tConfig
  return L1_2
end

GetConfig = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  if not A1_2 or not A2_2 then
    L4_2 = false
    return L4_2
  end
  L4_2 = type
  L5_2 = A3_2
  L4_2 = L4_2(L5_2)
  if "table" ~= L4_2 then
    L4_2 = {}
    A3_2 = L4_2
  end
  L5_2 = A0_2
  L4_2 = A0_2.IsLatent
  L4_2 = L4_2(L5_2)
  L6_2 = A0_2
  L5_2 = A0_2.IsActive
  L5_2 = L5_2(L6_2)
  if L5_2 and not L4_2 then
    L7_2 = A0_2
    L6_2 = A0_2.IsLiveConfigureable
    L8_2 = A1_2
    L6_2 = L6_2(L7_2, L8_2)
    if not L6_2 then
      L6_2 = false
      return L6_2
    end
  end
  L7_2 = A0_2
  L6_2 = A0_2.GetConfig
  L6_2 = L6_2(L7_2)
  L7_2 = type
  L8_2 = L6_2[A1_2]
  L7_2 = L7_2(L8_2)
  if "table" ~= L7_2 then
    L7_2 = L6_2[A1_2]
    if nil == L7_2 then
      L7_2 = {}
      L6_2[A1_2] = L7_2
    else
      L7_2 = false
      return L7_2
    end
  end
  L7_2 = table
  L7_2 = L7_2.insert
  L8_2 = L6_2[A1_2]
  L9_2 = {}
  L10_2 = A2_2
  L11_2 = A3_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L7_2(L8_2, L9_2)
  L7_2 = true
  return L7_2
end

AddCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = A0_2
  L2_2 = A0_2._ResetState
  L2_2(L3_2)
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if L2_2 == "table" then
    L3_2 = A0_2
    L2_2 = A0_2._SetSaveData
    L4_2 = MrxUtil
    L4_2 = L4_2.CopyTable
    L5_2 = A1_2
    L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  end
  L3_2 = A0_2
  L2_2 = A0_2.GetConfig
  L2_2 = L2_2(L3_2)
  L3_2 = L2_2.sModuleName
  if L3_2 then
    L3_2 = dynamic_import
    L4_2 = L2_2.sModuleName
    L5_2 = A0_2._ModuleLoaded
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L3_2(L4_2, L5_2, L6_2)
  else
    L4_2 = A0_2
    L3_2 = A0_2.LoadAssets
    L6_2 = A0_2
    L5_2 = A0_2._GetSaveData
    L5_2, L6_2, L7_2 = L5_2(L6_2)
    L3_2(L4_2, L5_2, L6_2, L7_2)
  end
end

Activate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L3_2 = A0_2
  L2_2 = A0_2.GetConfig
  L2_2 = L2_2(L3_2)
  L3_2 = L2_2.sModuleName
  if L3_2 then
  end
  L3_2 = setmetatable
  L4_2 = A0_2
  L5_2 = {}
  L5_2.__index = A1_2
  L3_2(L4_2, L5_2)
  L3_2 = {}
  A0_2._tEvents = L3_2
  L4_2 = A0_2
  L3_2 = A0_2.PreLoadAssets
  L3_2(L4_2)
  L4_2 = A0_2
  L3_2 = A0_2.LoadAssets
  L6_2 = A0_2
  L5_2 = A0_2._GetSaveData
  L5_2, L6_2 = L5_2(L6_2)
  L3_2(L4_2, L5_2, L6_2)
end

_ModuleLoaded = L0_1

function L0_1(A0_2)
  local L1_2
end

PreLoadAssets = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = A0_2
  L2_2 = A0_2.GetConfig
  L2_2 = L2_2(L3_2)
  L3_2 = type
  L4_2 = L2_2.tLayers
  L3_2 = L3_2(L4_2)
  if L3_2 == "table" then
    L3_2 = Pg
    L3_2 = L3_2.GetLoadingStaticLayers
    L3_2 = L3_2()
    L4_2 = Pg
    L4_2 = L4_2.LoadingStaticLayers
    L5_2 = false
    L4_2(L5_2)
    L4_2 = MrxLayerManager
    L4_2 = L4_2.Add
    L5_2 = L2_2.tLayers
    L6_2 = A0_2.AssetsLoaded
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L4_2(L5_2, L6_2, L7_2)
    L4_2 = Pg
    L4_2 = L4_2.LoadingStaticLayers
    L5_2 = L3_2
    L4_2(L5_2)
  else
    L4_2 = A0_2
    L3_2 = A0_2.AssetsLoaded
    L3_2(L4_2)
  end
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2._IssueAssetsLoadedCallbacks
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.Activated
  L1_2(L2_2)
end

AssetsLoaded = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2.tOnAssetsLoaded
  if L2_2 then
    L2_2 = MrxUtil
    L2_2 = L2_2.ProcessCallbackTable
    L3_2 = L1_2.tOnAssetsLoaded
    L2_2(L3_2)
  end
  L2_2 = L1_2.fOnAssetsLoaded
  if L2_2 then
    L2_2 = MrxUtil
    L2_2 = L2_2.CallWithOptionalArgs
    L3_2 = L1_2.fOnAssetsLoaded
    L2_2(L3_2)
  end
end

_IssueAssetsLoadedCallbacks = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L4_2 = A1_2
  L3_2 = A1_2.GetName
  L3_2 = L3_2(L4_2)
  L2_2[L3_2] = A1_2
end

_AddChild = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L2_2[A1_2] = nil
end

_RemoveChild = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L3_2 = L2_2[A1_2]
  return L3_2
end

GetChild = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = ipairs
  L3_2 = A1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L8_2 = A0_2
    L7_2 = A0_2._AddChild
    L9_2 = L6_2
    L7_2(L8_2, L9_2)
  end
end

_AddChildren = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2._tChildren
  return L1_2
end

GetChildren = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L1_2 = L1_2.sName
  return L1_2
end

GetName = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L1_2 = L1_2.sTitle
  return L1_2
end

GetTitle = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L1_2 = L1_2.oParent
  return L1_2
end

GetParent = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = A0_2
  L3_2 = L1_2
  L2_2 = L1_2.GetParent
  L2_2 = L2_2(L3_2)
  L4_2 = L1_2
  L3_2 = L1_2.GetName
  L3_2 = L3_2(L4_2)
  while L2_2 do
    L5_2 = L2_2
    L4_2 = L2_2.GetName
    L4_2 = L4_2(L5_2)
    L5_2 = "."
    L6_2 = L3_2
    L3_2 = L4_2 .. L5_2 .. L6_2
    L1_2 = L2_2
    L5_2 = L1_2
    L4_2 = L1_2.GetParent
    L4_2 = L4_2(L5_2)
    L2_2 = L4_2
  end
  return L3_2
end

GetLineage = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L3_2 = A0_2
  L2_2 = A0_2._GetSaveData
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = MrxUtil
    L3_2 = L3_2.CopyTable
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    L1_2 = L3_2
  else
    L3_2 = {}
    L1_2 = L3_2
  end
  L4_2 = A0_2
  L3_2 = A0_2._GetState
  L3_2 = L3_2(L4_2)
  L1_2.nState = L3_2
  return L1_2
end

SaveInstance = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2._tSaveData
  return L1_2
end

_GetSaveData = L0_1

function L0_1(A0_2, A1_2)
  A0_2._tSaveData = A1_2
end

_SetSaveData = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = {}
  L1_2.nCash = 0
  L1_2.nFuel = 0
  return L1_2
end

_GetRewards = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = true
  return L0_2
end

_CanCompleteViaCheatMenu = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2
  L5_2 = Event
  L5_2 = L5_2.Create
  L6_2 = A1_2
  L7_2 = A2_2
  L8_2 = A3_2
  L9_2 = A4_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = table
  L6_2 = L6_2.insert
  L7_2 = A0_2._tEvents
  L8_2 = L5_2
  L6_2(L7_2, L8_2)
  return L5_2
end

_CreateEvent = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2
  L5_2 = Event
  L5_2 = L5_2.CreatePersistent
  L6_2 = A1_2
  L7_2 = A2_2
  L8_2 = A3_2
  L9_2 = A4_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = table
  L6_2 = L6_2.insert
  L7_2 = A0_2._tEvents
  L8_2 = L5_2
  L6_2(L7_2, L8_2)
  return L5_2
end

_CreatePersistentEvent = L0_1

function L0_1(A0_2)
  local L1_2
  return A0_2
end

GetStub = L0_1

function L0_1(A0_2, A1_2)
  A0_2._oTask = A1_2
end

_SetTask = L0_1

function L0_1(A0_2)
  local L1_2
  return A0_2
end

GetTask = L0_1
