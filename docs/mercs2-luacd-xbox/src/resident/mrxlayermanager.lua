local L0_1, L1_1
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = {}
_tRequests = L0_1
L0_1 = {}
_tOpQueue = L0_1
L0_1 = {}
_tLoadedLayers = L0_1
L0_1 = {}
_tLayersToBeAdded = L0_1
L0_1 = 1
_knRequestTypeAdd = L0_1
L0_1 = 2
_knRequestTypeRemove = L0_1
L0_1 = 1
_knLayerStatusUnloaded = L0_1
L0_1 = 2
_knLayerStatusPending = L0_1
L0_1 = 3
_knLayerStatusLoaded = L0_1
L0_1 = 0
_nLayersBeingProcessed = L0_1
L0_1 = 10

function L1_1()
  local L0_2, L1_2
  L0_2 = Sys
  L0_2 = L0_2.GetAssetRequestMax
  L0_2 = L0_2()
  _knOrigAssetRequestMax = L0_2
end

Init = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L6_2 = _AddRequest
  L7_2 = _knRequestTypeAdd
  L8_2 = A0_2
  L9_2 = A1_2
  L10_2 = A2_2
  L11_2 = A3_2
  L12_2 = A4_2
  L13_2 = A5_2
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
end

Add = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = _AddRequest
  L5_2 = _knRequestTypeRemove
  L6_2 = A0_2
  L7_2 = A1_2
  L8_2 = A2_2
  L9_2 = A3_2
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
end

Remove = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = {}
  L3_2 = pairs
  L4_2 = _tLoadedLayers
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = table
    L8_2 = L8_2.insert
    L9_2 = L2_2
    L10_2 = L6_2
    L8_2(L9_2, L10_2)
  end
  L3_2 = Remove
  L4_2 = L2_2
  L5_2 = A0_2
  L6_2 = A1_2
  L3_2(L4_2, L5_2, L6_2)
end

RemoveDynamicLayers = L1_1

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = A0_2
  L4_2 = pairs
  L5_2 = _tLoadedLayers
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = table
    L9_2 = L9_2.insert
    L10_2 = L3_2
    L11_2 = L7_2
    L9_2(L10_2, L11_2)
  end
  L4_2 = Remove
  L5_2 = L3_2
  L6_2 = A1_2
  L7_2 = A2_2
  L4_2(L5_2, L6_2, L7_2)
end

RemoveAllLayers = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 == "string" then
    L1_2 = {}
    L2_2 = A0_2
    L1_2[1] = L2_2
    tLayers = L1_2
  else
    L1_2 = type
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    if L1_2 == "table" then
      tLayers = A0_2
    end
  end
  L1_2 = ipairs
  L2_2 = tLayers
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = string
    L6_2 = L6_2.lower
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    L5_2 = L6_2
    L6_2 = _tLoadedLayers
    L6_2 = L6_2[L5_2]
    if L6_2 ~= nil then
      L6_2 = _tLoadedLayers
      L6_2[L5_2] = true
    end
    L6_2 = _tLayersToBeAdded
    L6_2[L5_2] = nil
  end
end

MarkForRemoval = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 == "string" then
    L1_2 = {}
    L2_2 = A0_2
    L1_2[1] = L2_2
    tLayers = L1_2
  else
    L1_2 = type
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    if L1_2 == "table" then
      tLayers = A0_2
    end
  end
  L1_2 = ipairs
  L2_2 = tLayers
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = string
    L6_2 = L6_2.lower
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    L5_2 = L6_2
    L6_2 = _tLayersToBeAdded
    L6_2[L5_2] = true
    L6_2 = _tLoadedLayers
    L6_2 = L6_2[L5_2]
    if L6_2 == true then
      L6_2 = _tLoadedLayers
      L6_2[L5_2] = false
    end
  end
end

MarkForAddition = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = {}
  L3_2 = pairs
  L4_2 = _tLoadedLayers
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    if L7_2 then
      L8_2 = table
      L8_2 = L8_2.insert
      L9_2 = L2_2
      L10_2 = L6_2
      L8_2(L9_2, L10_2)
    end
  end
  L3_2 = Remove
  L4_2 = L2_2
  L5_2 = A0_2
  L6_2 = A1_2
  L3_2(L4_2, L5_2, L6_2)
end

RemoveMarkedLayers = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  
  function L2_2()
    local L0_3, L1_3, L2_3
    _tLayersToBeAdded = L0_3
    L0_3 = {}
    _tLayersToBeAdded = L0_3
    L0_3 = MrxUtil
    L0_3 = L0_3.CallWithOptionalArgs
    L1_3 = A0_2
    L2_3 = A1_2
    L0_3(L1_3, L2_3)
  end
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
    L0_3 = {}
    L1_3 = pairs
    L2_3 = _tLayersToBeAdded
    L1_3, L2_3, L3_3 = L1_3(L2_3)
    for L4_3, L5_3 in L1_3, L2_3, L3_3 do
      L6_3 = table
      L6_3 = L6_3.insert
      L7_3 = L0_3
      L8_3 = L4_3
      L6_3(L7_3, L8_3)
    end
    L1_3 = Add
    L2_3 = L0_3
    L3_3 = L2_2
    L1_3(L2_3, L3_3)
  end
  
  L4_2 = RemoveMarkedLayers
  L5_2 = L3_2
  L4_2(L5_2)
end

ProcessMarkedLayers = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2)
  local L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L8_2 = type
  L9_2 = A1_2
  L8_2 = L8_2(L9_2)
  if L8_2 == "string" then
    L8_2 = {}
    L9_2 = A1_2
    L8_2[1] = L9_2
    L7_2 = L8_2
  else
    L8_2 = type
    L9_2 = A1_2
    L8_2 = L8_2(L9_2)
    if L8_2 == "table" then
      L7_2 = A1_2
    end
  end
  L8_2 = {}
  L9_2 = ipairs
  L10_2 = L7_2
  L9_2, L10_2, L11_2 = L9_2(L10_2)
  for L12_2, L13_2 in L9_2, L10_2, L11_2 do
    L14_2 = string
    L14_2 = L14_2.lower
    L15_2 = L13_2
    L14_2 = L14_2(L15_2)
    L13_2 = L14_2
    L14_2 = false
    L15_2 = Sys
    L15_2 = L15_2.GetIgnoreLayers
    if L15_2 then
      L15_2 = Sys
      L15_2 = L15_2.GetIgnoreLayers
      L15_2 = L15_2()
      tIgnoreLayers = L15_2
      L15_2 = ipairs
      L16_2 = tIgnoreLayers
      L15_2, L16_2, L17_2 = L15_2(L16_2)
      for L18_2, L19_2 in L15_2, L16_2, L17_2 do
        L20_2 = string
        L20_2 = L20_2.lower
        L21_2 = L19_2
        L20_2 = L20_2(L21_2)
        if L13_2 == L20_2 then
          L14_2 = true
          break
        end
      end
    end
    if not L14_2 then
      L15_2 = Pg
      L15_2 = L15_2.AssetExists
      L16_2 = L13_2
      L17_2 = "layer"
      L15_2 = L15_2(L16_2, L17_2)
      L16_2 = false
      L17_2 = false
      L18_2 = _knRequestTypeRemove
      if A0_2 == L18_2 then
        L18_2 = _tLoadedLayers
        L18_2 = L18_2[L13_2]
        if L18_2 == nil then
          L18_2 = Pg
          L18_2 = L18_2.IsStaticLayer
          L19_2 = L13_2
          L18_2 = L18_2(L19_2)
          if not L18_2 then
            L18_2 = Pg
            L18_2 = L18_2.GetUnloadingStaticLayers
            L18_2 = L18_2()
            if not L18_2 then
              L17_2 = true
            end
          end
        end
      end
      if A4_2 then
        L18_2 = _knRequestTypeAdd
        if A0_2 == L18_2 then
          L18_2 = _tLoadedLayers
          L18_2 = L18_2[L13_2]
          if not L18_2 then
            L18_2 = Pg
            L18_2 = L18_2.IsStaticLayer
            L19_2 = L13_2
            L18_2 = L18_2(L19_2)
            if not L18_2 then
              goto lbl_94
            end
          end
          L16_2 = true
        end
      end
      ::lbl_94::
      if not L15_2 then
      end
      if L16_2 then
      end
      if L17_2 then
      end
      if L15_2 and not L16_2 and not L17_2 then
        L18_2 = table
        L18_2 = L18_2.insert
        L19_2 = L8_2
        L20_2 = L13_2
        L18_2(L19_2, L20_2)
      end
    end
  end
  L7_2 = L8_2
  L9_2 = table
  L9_2 = L9_2.getn
  L10_2 = L7_2
  L9_2 = L9_2(L10_2)
  if L9_2 == 0 then
    L10_2 = MrxUtil
    L10_2 = L10_2.CallWithOptionalArgs
    L11_2 = A2_2
    L12_2 = A3_2
    L10_2(L11_2, L12_2)
    return
  end
  L10_2 = {}
  L10_2.nDone = 0
  L10_2.nQuota = L9_2
  L10_2.fCallback = A2_2
  L10_2.tCallbackArgs = A3_2
  L11_2 = table
  L11_2 = L11_2.insert
  L12_2 = _tRequests
  L13_2 = L10_2
  L11_2(L12_2, L13_2)
  L11_2 = table
  L11_2 = L11_2.getn
  L12_2 = _tRequests
  L11_2 = L11_2(L12_2)
  L10_2.nId = L11_2
  L11_2 = "adding"
  L12_2 = _knRequestTypeRemove
  if A0_2 == L12_2 then
    L11_2 = "removing"
  end
  L12_2 = ipairs
  L13_2 = L7_2
  L12_2, L13_2, L14_2 = L12_2(L13_2)
  for L15_2, L16_2 in L12_2, L13_2, L14_2 do
    L17_2 = _tOpQueue
    L17_2 = L17_2[L16_2]
    if not L17_2 then
      L17_2 = _tOpQueue
      L18_2 = {}
      L18_2.nOperationType = A0_2
      L19_2 = {}
      L20_2 = L10_2
      L19_2[1] = L20_2
      L18_2.tRequests = L19_2
      L18_2.bStatic = A5_2
      L18_2.bClientNeedsLoadingScreen = A6_2
      L17_2[L16_2] = L18_2
    else
      L17_2 = table
      L17_2 = L17_2.insert
      L18_2 = _tOpQueue
      L18_2 = L18_2[L16_2]
      L18_2 = L18_2.tRequests
      L19_2 = L10_2
      L17_2(L18_2, L19_2)
    end
  end
  L12_2 = _ProcessOpQueue
  L12_2()
end

_AddRequest = L1_1

function L1_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L0_2 = {}
  L1_2 = 0
  L2_2 = pairs
  L3_2 = _tOpQueue
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = L6_2.bMarkedForDeletion
    if not L7_2 then
      L0_2[L5_2] = L6_2
      L1_2 = L1_2 + 1
    else
    end
  end
  _tOpQueue = L0_2
  if L1_2 <= 0 then
    L2_2 = Sys
    L2_2 = L2_2.SetAssetRequestMax
    L3_2 = _knOrigAssetRequestMax
    L2_2(L3_2)
    return
  else
    L2_2 = Sys
    L2_2 = L2_2.GetAssetRequestMax
    L2_2 = L2_2()
    if L1_2 > L2_2 then
      L2_2 = Sys
      L2_2 = L2_2.SetAssetRequestMax
      L3_2 = L1_2
      L2_2(L3_2)
    end
  end
  L2_2 = {}
  L3_2 = "Load"
  L2_2[1] = L3_2
  L3_2 = {}
  L4_2 = "Reload"
  L3_2[1] = L4_2
  L4_2 = {}
  L5_2 = "Unload"
  L4_2[1] = L5_2
  L5_2 = pairs
  L6_2 = _tOpQueue
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = _nLayersBeingProcessed
    L11_2 = L0_1
    if L10_2 >= L11_2 then
      return
    end
    L10_2 = L9_2.bProcessed
    if not L10_2 then
      L10_2 = L9_2.nOperationType
      L11_2 = _knRequestTypeAdd
      if L10_2 == L11_2 then
        L10_2 = L9_2.bStatic
        L11_2 = L9_2.bClientNeedsLoadingScreen
        if L10_2 == nil then
          L10_2 = false
        end
        if L11_2 == nil then
          L11_2 = false
        end
        L12_2 = nil
        L13_2 = _tLoadedLayers
        L13_2 = L13_2[L8_2]
        if L13_2 == nil then
          L13_2 = Pg
          L13_2 = L13_2.IsStaticLayer
          L14_2 = L8_2
          L13_2 = L13_2(L14_2)
          if not L13_2 then
            L13_2 = Pg
            L13_2 = L13_2.LoadLayer
            L14_2 = L8_2
            L15_2 = not L10_2
            L16_2 = _LayerStatusChange
            L17_2 = L2_2
            L18_2 = L11_2
            L13_2 = L13_2(L14_2, L15_2, L16_2, L17_2, L18_2)
            L12_2 = L13_2
            L13_2 = _nLayersBeingProcessed
            L13_2 = L13_2 + 1
            _nLayersBeingProcessed = L13_2
            L9_2.bProcessed = true
        end
        elseif not L10_2 then
          L13_2 = Pg
          L13_2 = L13_2.ReloadLayer
          L14_2 = L8_2
          L15_2 = _LayerStatusChange
          L16_2 = L3_2
          L17_2 = L11_2
          L13_2 = L13_2(L14_2, L15_2, L16_2, L17_2)
          L12_2 = L13_2
          L13_2 = _nLayersBeingProcessed
          L13_2 = L13_2 + 1
          _nLayersBeingProcessed = L13_2
          L9_2.bProcessed = true
        end
      else
        L10_2 = L9_2.nOperationType
        L11_2 = _knRequestTypeRemove
        if L10_2 == L11_2 then
          L10_2 = Pg
          L10_2 = L10_2.UnloadLayer
          L11_2 = L8_2
          L12_2 = _LayerStatusChange
          L13_2 = L4_2
          L14_2 = bClientNeedsLoadingScreen
          L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2)
          L11_2 = _nLayersBeingProcessed
          L11_2 = L11_2 + 1
          _nLayersBeingProcessed = L11_2
          L9_2.bProcessed = true
        end
      end
    end
  end
end

_ProcessOpQueue = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L4_2 = _tOpQueue
  L4_2 = L4_2[A1_2]
  L5_2 = _nLayersBeingProcessed
  L5_2 = L5_2 - 1
  _nLayersBeingProcessed = L5_2
  if A3_2 then
    if A0_2 == "Load" or A0_2 == "Reload" then
      L5_2 = _tLoadedLayers
      L5_2 = L5_2[A1_2]
      if L5_2 == nil then
        L5_2 = L4_2.bStatic
        if not L5_2 then
          L5_2 = _tLoadedLayers
          L5_2[A1_2] = false
        end
      end
    else
      if A0_2 == "Unload" then
        L5_2 = _tLoadedLayers
        L5_2[A1_2] = nil
        L5_2 = Debug
        L5_2 = L5_2.Printf
        L6_2 = "Request fulfilled: "
        L7_2 = A0_2
        L8_2 = " layer "
        L9_2 = A1_2
        L6_2 = L6_2 .. L7_2 .. L8_2 .. L9_2
        L5_2(L6_2)
      else
      end
    end
  end
  L5_2 = {}
  if L4_2 then
    L4_2.bMarkedForDeletion = true
    L6_2 = ipairs
    L7_2 = L4_2.tRequests
    L6_2, L7_2, L8_2 = L6_2(L7_2)
    for L9_2, L10_2 in L6_2, L7_2, L8_2 do
      L11_2 = L10_2.nDone
      L11_2 = L11_2 + 1
      L10_2.nDone = L11_2
      L11_2 = L10_2.nDone
      L12_2 = L10_2.nQuota
      if L11_2 == L12_2 then
        L10_2.bFulfilled = true
      end
    end
    L6_2 = {}
    L7_2 = ipairs
    L8_2 = _tRequests
    L7_2, L8_2, L9_2 = L7_2(L8_2)
    for L10_2, L11_2 in L7_2, L8_2, L9_2 do
      L12_2 = L11_2.bFulfilled
      if L12_2 then
        L12_2 = table
        L12_2 = L12_2.insert
        L13_2 = L5_2
        L14_2 = {}
        L15_2 = L11_2.fCallback
        L16_2 = L11_2.tCallbackArgs
        L14_2[1] = L15_2
        L14_2[2] = L16_2
        L12_2(L13_2, L14_2)
      else
        L12_2 = table
        L12_2 = L12_2.insert
        L13_2 = L6_2
        L14_2 = L11_2
        L12_2(L13_2, L14_2)
      end
    end
    _tRequests = L6_2
  end
  L6_2 = _ProcessOpQueue
  L6_2()
  L6_2 = ipairs
  L7_2 = L5_2
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  for L9_2, L10_2 in L6_2, L7_2, L8_2 do
    L11_2 = MrxUtil
    L11_2 = L11_2.CallWithOptionalArgs
    L12_2 = L10_2[1]
    L13_2 = L10_2[2]
    L11_2(L12_2, L13_2)
  end
end

_LayerStatusChange = L1_1

function L1_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = {}
  L1_2 = pairs
  L2_2 = _tLoadedLayers
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    if not L5_2 then
      L6_2 = table
      L6_2 = L6_2.insert
      L7_2 = L0_2
      L8_2 = L4_2
      L6_2(L7_2, L8_2)
    end
  end
  L1_2 = pairs
  L2_2 = _tLayersToBeAdded
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = _tLoadedLayers
    L6_2 = L6_2[L4_2]
    if not L6_2 then
      L6_2 = table
      L6_2 = L6_2.insert
      L7_2 = L0_2
      L8_2 = L4_2
      L6_2(L7_2, L8_2)
    end
  end
  return L0_2
end

SaveSingleton = L1_1

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = {}
  L4_2 = pairs
  L5_2 = _tLoadedLayers
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = table
    L9_2 = L9_2.insert
    L10_2 = L3_2
    L11_2 = L7_2
    L9_2(L10_2, L11_2)
  end
  L4_2 = FindLayerIntersection
  L5_2 = L3_2
  L6_2 = A0_2
  L4_2, L5_2 = L4_2(L5_2, L6_2)
  L6_2 = Remove
  L7_2 = L4_2
  
  function L8_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = Add
    L1_3 = L5_2
    L2_3 = A1_2
    L3_3 = A2_2
    L0_3(L1_3, L2_3, L3_3)
  end
  
  L6_2(L7_2, L8_2)
end

LoadSingleton = L1_1

function L1_1()
  local L0_2, L1_2
  L0_2 = {}
  _tRequests = L0_2
  L0_2 = {}
  _tOpQueue = L0_2
  L0_2 = {}
  _tLoadedLayers = L0_2
  L0_2 = {}
  _tLayersToBeAdded = L0_2
end

ResetState = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = table
  L2_2 = L2_2.sort
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = table
  L2_2 = L2_2.sort
  L3_2 = A1_2
  L2_2(L3_2)
  L2_2 = {}
  L3_2 = {}
  L4_2 = 1
  L5_2 = 1
  while true do
    L6_2 = A0_2[L4_2]
    if L6_2 == nil then
      break
    end
    L6_2 = A1_2[L5_2]
    if not L6_2 then
      break
    end
    L6_2 = A0_2[L4_2]
    L7_2 = A1_2[L5_2]
    if L6_2 == L7_2 then
      L6_2 = table
      L6_2 = L6_2.insert
      L7_2 = L3_2
      L8_2 = A0_2[L4_2]
      L6_2(L7_2, L8_2)
      L4_2 = L4_2 + 1
      L5_2 = L5_2 + 1
    else
      L6_2 = A0_2[L4_2]
      L7_2 = A1_2[L5_2]
      if L6_2 < L7_2 then
        L6_2 = table
        L6_2 = L6_2.insert
        L7_2 = L2_2
        L8_2 = A0_2[L4_2]
        L6_2(L7_2, L8_2)
        L4_2 = L4_2 + 1
      else
        L6_2 = table
        L6_2 = L6_2.insert
        L7_2 = L3_2
        L8_2 = A1_2[L5_2]
        L6_2(L7_2, L8_2)
        L5_2 = L5_2 + 1
      end
    end
  end
  L6_2 = A0_2[L4_2]
  if L6_2 ~= nil then
    while true do
      L6_2 = #A0_2
      if not (L4_2 <= L6_2) then
        break
      end
      L6_2 = table
      L6_2 = L6_2.insert
      L7_2 = L2_2
      L8_2 = A0_2[L4_2]
      L6_2(L7_2, L8_2)
      L4_2 = L4_2 + 1
    end
  else
    L6_2 = A1_2[L5_2]
    if L6_2 ~= nil then
      while true do
        L6_2 = #A1_2
        if not (L5_2 <= L6_2) then
          break
        end
        L6_2 = table
        L6_2 = L6_2.insert
        L7_2 = L3_2
        L8_2 = A1_2[L5_2]
        L6_2(L7_2, L8_2)
        L5_2 = L5_2 + 1
      end
    end
  end
  L6_2 = L2_2
  L7_2 = L3_2
  return L6_2, L7_2
end

FindLayerIntersection = L1_1
