local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskMission"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxLayerManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPlayState"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxRewardData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifMissionFlow"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  if A1_2 ~= nil then
    L2_2 = A1_2._nTargetsComplete
    A0_2._nTargetsComplete = L2_2
  end
  L2_2 = type
  L3_2 = A0_2._tTargets
  L2_2 = L2_2(L3_2)
  if L2_2 == "table" then
    L2_2 = {}
    L3_2 = A0_2._GetPerTargetLayerKeys
    L3_2 = L3_2()
    L4_2 = pairs
    L5_2 = A0_2._tTargets
    L4_2, L5_2, L6_2 = L4_2(L5_2)
    for L7_2, L8_2 in L4_2, L5_2, L6_2 do
      L9_2 = type
      L10_2 = A1_2
      L9_2 = L9_2(L10_2)
      L9_2 = type
      L10_2 = A1_2.tTargets
      L9_2 = L9_2(L10_2)
      L9_2 = A1_2.tTargets
      L9_2 = L9_2 == "table" and L9_2
      if L9_2 then
        L8_2.bComplete = true
      else
        L10_2 = ipairs
        L11_2 = L3_2
        L10_2, L11_2, L12_2 = L10_2(L11_2)
        for L13_2, L14_2 in L10_2, L11_2, L12_2 do
          L15_2 = L8_2[L14_2]
          if L15_2 then
            L15_2 = table
            L15_2 = L15_2.insert
            L16_2 = L2_2
            L17_2 = L8_2[L14_2]
            L15_2(L16_2, L17_2)
          end
        end
      end
    end
    L4_2 = MrxLayerManager
    L4_2 = L4_2.Add
    L5_2 = L2_2
    L6_2 = A0_2.AssetsLoaded
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L4_2(L5_2, L6_2, L7_2)
  else
    L2_2 = MrxTaskMission
    L2_2 = L2_2.LoadAssets
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  end
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = L1_2.bTrackOnActivate
  L4_2 = false
  L2_2 = L2_2(L3_2, L4_2)
  A0_2._bTrackOnActivate = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = L1_2.bSkipInitialNotifications
  L4_2 = false
  L2_2 = L2_2(L3_2, L4_2)
  A0_2._bSkipInitialNotifications = L2_2
  L2_2 = {}
  A0_2._tTargetGuidsToNames = L2_2
  L2_2 = type
  L3_2 = A0_2._tTargets
  L2_2 = L2_2(L3_2)
  if L2_2 == "table" then
    L2_2 = pairs
    L3_2 = A0_2._tTargets
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2, L6_2 in L2_2, L3_2, L4_2 do
      L7_2 = L6_2.bComplete
      if not L7_2 then
        L7_2 = Pg
        L7_2 = L7_2.GetGuidByName
        L8_2 = L5_2
        L7_2 = L7_2(L8_2)
        if L7_2 == nil then
          L8_2 = A0_2._tTargetGuidsToNames
          L8_2[L7_2] = L5_2
        else
          L8_2 = A0_2._tTargetGuidsToNames
          L8_2[L7_2] = L5_2
        end
      end
    end
  end
  A0_2._bNearVoInProgress = false
  L2_2 = MrxTaskMission
  L2_2 = L2_2.Activated
  L3_2 = A0_2
  L2_2(L3_2)
end

Activated = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  L3_2 = A0_2._tTargets
  if not L3_2 then
    L3_2 = {}
    A0_2._tTargets = L3_2
    A0_2._nTargetsComplete = 0
  end
  L3_2 = A0_2._tTargets
  L3_2 = L3_2[A1_2]
  if L3_2 then
  end
  L3_2 = A0_2._tTargets
  L4_2 = {}
  L4_2.sTargetLayer = A2_2
  L3_2[A1_2] = L4_2
  return A1_2
end

_AddTarget = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  L4_2 = A0_2
  L3_2 = A0_2._GetTargetData
  L5_2 = A1_2
  L3_2 = L3_2(L4_2, L5_2)
  if L3_2 then
    L3_2.sMilestoneKey = A2_2
  end
end

_SetTargetMilestoneKey = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if L2_2 == "string" then
    L3_2 = A0_2._tTargets
    L3_2 = L3_2[A1_2]
    return L3_2
  elseif L2_2 == "userdata" then
    L3_2 = A0_2._tTargetGuidsToNames
    L3_2 = L3_2[A1_2]
    if L3_2 then
      L4_2 = A0_2._tTargets
      L4_2 = L4_2[L3_2]
      return L4_2
    end
  else
    L3_2 = A0_2._tTargets
    return L3_2
  end
end

_GetTargetData = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = {}
  L2_2 = pairs
  L3_2 = A0_2._tTargets
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = L6_2.bComplete
    L7_2 = not L7_2
    if L7_2 == true then
      L7_2 = table
      L7_2 = L7_2.insert
      L8_2 = L1_2
      L9_2 = L5_2
      L7_2(L8_2, L9_2)
    end
  end
  return L1_2
end

_GetTargetList = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = {}
  L2_2 = A0_2._tTargets
  if not L2_2 then
    L2_2 = nil
    return L2_2
  end
  L2_2 = pairs
  L3_2 = A0_2._tTargets
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = L6_2.bComplete
    if L7_2 == true then
      L7_2 = table
      L7_2 = L7_2.insert
      L8_2 = L1_2
      L9_2 = L5_2
      L7_2(L8_2, L9_2)
    end
  end
  return L1_2
end

_GetPartsCompletedList = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L2_2 = false
  L3_2 = A0_2._oObjective
  L4_2 = L3_2
  L3_2 = L3_2.IsQuotaMet
  L3_2 = L3_2(L4_2)
  L4_2 = A0_2._nTargetsComplete
  if not L4_2 then
    A0_2._nTargetsComplete = 0
  end
  L4_2 = A0_2._nTargetsComplete
  L4_2 = L4_2 + 1
  A0_2._nTargetsComplete = L4_2
  L4_2 = A0_2._GetAutosaveMode
  L4_2 = L4_2()
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = L2_2
    if L0_3 then
      L0_3 = L3_2
      L0_3 = not L0_3
    end
    if not L0_3 then
      L1_3 = L4_2
      if not L1_3 then
        return
      end
    end
    L1_3 = MrxPlayState
    L1_3 = L1_3.GetCurrentMission
    L1_3 = L1_3()
    if L1_3 then
      L2_3 = L1_3._Checkpoint
      L3_3 = nil
      L4_3 = true
      L5_3 = true
      L2_3(L3_3, L4_3, L5_3)
    end
    if L0_3 then
      L2_3 = WifMissionFlow
      L2_3 = L2_3.EnableAutosave
      L2_3()
      L2_3 = WifMissionFlow
      L2_3 = L2_3.Refresh
      L2_3()
    else
      L2_3 = WifMissionFlow
      L2_3 = L2_3.Autosave
      L2_3()
    end
  end
  
  L6_2 = MrxRewardData
  L6_2 = L6_2.GrantRewardKey
  L8_2 = A0_2
  L7_2 = A0_2.GetMissionId
  L7_2 = L7_2(L8_2)
  L8_2 = "_PerTarget"
  L7_2 = L7_2 .. L8_2
  L6_2(L7_2)
  L6_2 = type
  L7_2 = A0_2._tTargets
  L6_2 = L6_2(L7_2)
  if L6_2 == "table" then
    L7_2 = A0_2
    L6_2 = A0_2._GetTargetData
    L8_2 = A1_2
    L6_2 = L6_2(L7_2, L8_2)
    if L6_2 then
      L6_2.bComplete = true
      L7_2 = L6_2.sTargetLayer
      if L7_2 then
        L7_2 = MrxLayerManager
        L7_2 = L7_2.MarkForRemoval
        L8_2 = L6_2.sTargetLayer
        L7_2(L8_2)
      end
      L7_2 = L6_2.sMilestoneKey
      if L7_2 then
        L7_2 = WifMissionFlow
        L7_2 = L7_2.AwardKey
        L8_2 = L6_2.sMilestoneKey
        L7_2(L8_2)
        L2_2 = true
      end
    end
  end
  L7_2 = A0_2
  L6_2 = A0_2.GetConfig
  L6_2 = L6_2(L7_2)
  L7_2 = L6_2.tMilestones
  L8_2 = type
  L9_2 = L7_2
  L8_2 = L8_2(L9_2)
  if L8_2 == "table" then
    L8_2 = pairs
    L9_2 = L7_2
    L8_2, L9_2, L10_2 = L8_2(L9_2)
    for L11_2, L12_2 in L8_2, L9_2, L10_2 do
      L13_2 = type
      L14_2 = L12_2.nMilestone
      L13_2 = L13_2(L14_2)
      if L13_2 == "number" then
        L13_2 = L12_2.nMilestone
        L14_2 = A0_2._nTargetsComplete
        if L13_2 == L14_2 then
          L13_2 = WifMissionFlow
          L13_2 = L13_2.AwardKey
          L14_2 = L12_2.sKey
          L13_2(L14_2)
          L2_2 = true
        end
      end
    end
  end
  L8_2 = A0_2._tTargetCompleteVo
  if L8_2 then
    L8_2 = _PlayRandomVoSequenceFromTable
    L9_2 = A0_2._tTargetCompleteVo
    L10_2 = A0_2._nTargetsComplete
    L11_2 = L5_2
    L8_2(L9_2, L10_2, L11_2)
  else
    L8_2 = L5_2
    L8_2()
  end
end

_TargetComplete = L0_1

function L0_1(A0_2)
  local L1_2
  return
end

_ExcludeCompletedTargets = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if L2_2 == "table" then
    A0_2._tTargetCompleteVo = A1_2
  end
end

_SetTargetCompleteVo = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if L2_2 == "table" then
    A0_2._tTargetNearbyVo = A1_2
  end
end

_SetTargetNearbyVo = L0_1

function L0_1(A0_2, A1_2)
  A0_2._sDspShortDesc = A1_2
end

_SetShortDescription = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A0_2._oObjective
  if L2_2 then
    L2_2 = A0_2._oObjective
    L3_2 = L2_2
    L2_2 = L2_2.EnableTracking
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  end
end

EnableTracking = L0_1

function L0_1(A0_2)
  local L1_2
end

_AddToPda = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  if A1_2 then
    A1_2.bOptional = true
  end
  L2_2 = MrxTaskMission
  L2_2 = L2_2.CreateChild
  L3_2 = A0_2
  L4_2 = A1_2
  return L2_2(L3_2, L4_2)
end

CreateChild = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = MrxTaskMission
  L0_2 = L0_2._knJob
  return L0_2
end

_GetMissionType = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = true
  return L0_2
end

IsJob = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = {}
  L1_2 = "sTargetLayer"
  L0_2[1] = L1_2
  return L0_2
end

_GetPerTargetLayerKeys = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = 30
  return L0_2
end

_GetNearRadius = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = 60
  return L0_2
end

_GetFarRadius = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = true
  return L0_2
end

_GetAutosaveMode = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = false
  return L0_2
end

_GetNearbyVoPlaybackMode = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = MrxTaskMission
  L1_2 = L1_2.SaveInstance
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = type
  L3_2 = A0_2._tTargets
  L2_2 = L2_2(L3_2)
  if L2_2 == "table" then
    L2_2 = pairs
    L3_2 = A0_2._tTargets
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2, L6_2 in L2_2, L3_2, L4_2 do
      L7_2 = type
      L8_2 = L6_2
      L7_2 = L7_2(L8_2)
      if "table" == L7_2 then
        L7_2 = L6_2.bComplete
        if L7_2 then
          L7_2 = L1_2.tTargets
          if not L7_2 then
            L7_2 = {}
            L1_2.tTargets = L7_2
          end
          L7_2 = L1_2.tTargets
          L7_2[L5_2] = true
        end
      end
    end
  end
  L2_2 = A0_2._nTargetsComplete
  L1_2._nTargetsComplete = L2_2
  return L1_2
end

SaveInstance = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = A0_2.uSecondaryProximity
  if L1_2 then
    L1_2 = ipairs
    L2_2 = A0_2._tEvents
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    for L4_2, L5_2 in L1_2, L2_2, L3_2 do
      L6_2 = A0_2.uSecondaryProximity
      if L5_2 == L6_2 then
        L6_2 = Event
        L6_2 = L6_2.Delete
        L7_2 = L5_2
        L6_2(L7_2)
        L6_2 = table
        L6_2 = L6_2.remove
        L7_2 = A0_2._tEvents
        L8_2 = L4_2
        L6_2(L7_2, L8_2)
        break
      end
    end
    A0_2.uSecondaryProximity = nil
  end
end

_RemoveSecondaryNearbyEvent = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = A0_2.uSecondaryProximity
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2._RemoveSecondaryNearbyEvent
    L1_2(L2_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2._CreatePersistentEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = A0_2._uFarTgtFilter
  L6_2 = Player
  L6_2 = L6_2.GetSecondaryCharacter
  L6_2 = L6_2()
  L7_2 = "<"
  L8_2 = A0_2._GetNearRadius
  L8_2 = L8_2()
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = A0_2._NearbyRadiusEntry
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  A0_2.uSecondaryProximity = L1_2
end

_CreateSecondaryNearbyEvent = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = Player
  L1_2 = L1_2.GetSecondaryCharacter
  L1_2 = L1_2()
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2._CreateSecondaryNearbyEvent
    L1_2(L2_2)
  else
    L2_2 = A0_2
    L1_2 = A0_2._RemoveSecondaryNearbyEvent
    L1_2(L2_2)
  end
end

_PlayerJoin = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = ObjectFilter
  L1_2 = L1_2.Copy
  L2_2 = A0_2._oObjective
  L3_2 = L2_2
  L2_2 = L2_2.GetTargetObjectFilter
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  A0_2._uFarTgtFilter = L1_2
  L1_2 = ObjectFilter
  L1_2 = L1_2.RemoveObject
  L2_2 = A0_2._uFarTgtFilter
  L3_2 = Player
  L3_2 = L3_2.GetAnyCharacter
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L3_2()
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  L1_2 = ObjectFilter
  L1_2 = L1_2.RemoveObject
  L2_2 = A0_2._uFarTgtFilter
  L3_2 = Player
  L3_2 = L3_2.GetAllCharacters
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L3_2()
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreatePersistentEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = A0_2._uFarTgtFilter
  L6_2 = Player
  L6_2 = L6_2.GetLocalCharacter
  L6_2 = L6_2()
  L7_2 = "<"
  L8_2 = A0_2._GetNearRadius
  L8_2 = L8_2()
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = A0_2._NearbyRadiusEntry
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = Player
  L2_2 = L2_2.GetSecondaryCharacter
  L2_2 = L2_2()
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2._CreateSecondaryNearbyEvent
    L2_2(L3_2)
  end
  L3_2 = A0_2
  L2_2 = A0_2._CreatePersistentEvent
  L4_2 = Event
  L4_2 = L4_2.ScriptEvent
  L5_2 = {}
  L6_2 = "mpPlayerJoin"
  
  function L7_2(A0_3)
    local L1_3, L2_3
    L1_3 = Net
    L1_3 = L1_3.IsServer
    L1_3 = L1_3()
    if L1_3 then
      L1_3 = Player
      L1_3 = L1_3.IsLocal
      L2_3 = A0_3[1]
      L1_3 = L1_3(L2_3)
      L1_3 = not L1_3
    end
    return L1_3
  end
  
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = A0_2._PlayerJoin
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

_CreateNearbyEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L2_2 = ipairs
  L3_2 = A1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L8_2 = A0_2
    L7_2 = A0_2._TargetNearby
    L9_2 = L6_2
    L7_2(L8_2, L9_2)
    L7_2 = false
    L8_2 = ObjectFilter
    L8_2 = L8_2.GetObjects
    L9_2 = A0_2._uFarTgtFilter
    L10_2 = false
    L8_2 = L8_2(L9_2, L10_2)
    L9_2 = ipairs
    L10_2 = L8_2
    L9_2, L10_2, L11_2 = L9_2(L10_2)
    for L12_2, L13_2 in L9_2, L10_2, L11_2 do
      if L6_2 == L13_2 then
        L7_2 = true
        break
      end
    end
    if L7_2 then
      L9_2 = ObjectFilter
      L9_2 = L9_2.RemoveObject
      L10_2 = A0_2._uFarTgtFilter
      L11_2 = L6_2
      L9_2(L10_2, L11_2)
    else
      L9_2 = ObjectFilter
      L9_2 = L9_2.AddObject
      L10_2 = A0_2._uFarTgtFilter
      L11_2 = L6_2
      L12_2 = true
      L9_2(L10_2, L11_2, L12_2)
    end
    L10_2 = A0_2
    L9_2 = A0_2._CreateFarawayEvent
    L11_2 = L6_2
    L9_2(L10_2, L11_2)
  end
end

_NearbyRadiusEntry = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = true
  L3_2 = MrxPlayState
  L3_2 = L3_2.IsFree
  L3_2 = L3_2()
  if not L3_2 then
    L3_2 = A0_2._GetNearbyVoPlaybackMode
    L3_2 = L3_2()
    L2_2 = L3_2
  end
  if L2_2 then
    L3_2 = A0_2._bNearVoInProgress
    if L3_2 == false then
      A0_2._bNearVoInProgress = true
      L3_2 = _PlayRandomVoSequenceFromTable
      L4_2 = A0_2._tTargetNearbyVo
      L5_2 = nil
      L6_2 = A0_2._NearVoComplete
      L7_2 = {}
      L8_2 = A0_2
      L7_2[1] = L8_2
      L3_2(L4_2, L5_2, L6_2, L7_2)
    end
  end
end

_TargetNearby = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAllCharacters
  L6_2 = L6_2()
  L7_2 = A1_2
  L8_2 = ">"
  L9_2 = A0_2._GetFarRadius
  L9_2 = L9_2()
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L6_2 = A0_2._NearbyRadiusExit
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A1_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

_CreateFarawayEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = A0_2
  L2_2 = A0_2._TargetFaraway
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
  L2_2 = false
  L3_2 = ObjectFilter
  L3_2 = L3_2.GetObjects
  L4_2 = A0_2._uFarTgtFilter
  L5_2 = false
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = ipairs
  L5_2 = L3_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    if A1_2 == L8_2 then
      L2_2 = true
      break
    end
  end
  if L2_2 then
    L4_2 = ObjectFilter
    L4_2 = L4_2.RemoveObject
    L5_2 = A0_2._uFarTgtFilter
    L6_2 = A1_2
    L4_2(L5_2, L6_2)
  else
    L4_2 = ObjectFilter
    L4_2 = L4_2.AddObject
    L5_2 = A0_2._uFarTgtFilter
    L6_2 = A1_2
    L7_2 = false
    L4_2(L5_2, L6_2, L7_2)
  end
  L4_2 = ObjectFilter
  L4_2 = L4_2.AddObject
  L5_2 = A0_2._uFarTgtFilter
  L6_2 = A1_2
  L7_2 = false
  L4_2(L5_2, L6_2, L7_2)
end

_NearbyRadiusExit = L0_1

function L0_1(A0_2, A1_2)
end

_TargetFaraway = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L4_2 = type
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if L4_2 ~= "table" then
    return
  end
  L4_2 = {}
  L5_2 = ipairs
  L6_2 = A0_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = true
    L11_2 = L9_2.tRange
    if L11_2 and A1_2 ~= nil then
      L12_2 = nil
      L13_2 = nil
      L14_2 = nil
      L15_2 = nil
      L16_2 = #L11_2
      if L16_2 == 4 then
        L12_2 = L11_2[2]
        L17_2 = L11_2[1]
        L13_2 = L17_2 == "["
        L14_2 = L11_2[3]
        L17_2 = L11_2[4]
        L15_2 = L17_2 == "]"
      elseif L16_2 == 2 then
        L17_2 = type
        L18_2 = L11_2[1]
        L17_2 = L17_2(L18_2)
        if L17_2 == "number" then
          L14_2 = L11_2[1]
          L17_2 = L11_2[2]
          L15_2 = L17_2 == "]"
        else
          L12_2 = L11_2[2]
          L17_2 = L11_2[1]
          L13_2 = L17_2 == "["
        end
      elseif L16_2 == 1 then
        L12_2 = L11_2[1]
        L13_2 = true
        L14_2 = L11_2[1]
        L15_2 = true
      end
      L17_2 = true
      if L12_2 then
        L17_2 = A1_2 > L12_2
        if L13_2 then
          L17_2 = A1_2 >= L12_2
        end
      end
      L18_2 = true
      if L14_2 then
        L18_2 = A1_2 < L14_2
        if L15_2 then
          L18_2 = A1_2 <= L14_2
        end
      end
      L10_2 = L17_2 or L10_2
      if L17_2 then
        L10_2 = L18_2
      end
    end
    if L10_2 then
      L12_2 = L9_2.nWeight
      if not L12_2 then
        L12_2 = 1
      end
      L13_2 = 1
      L14_2 = L12_2
      L15_2 = 1
      for L16_2 = L13_2, L14_2, L15_2 do
        L17_2 = table
        L17_2 = L17_2.insert
        L18_2 = L4_2
        L19_2 = L8_2
        L17_2(L18_2, L19_2)
      end
    end
  end
  L5_2 = table
  L5_2 = L5_2.getn
  L6_2 = L4_2
  L5_2 = L5_2(L6_2)
  if L5_2 <= 0 then
    return
  end
  L5_2 = MrxUtil
  L5_2 = L5_2.GetRandomTableElement
  L6_2 = L4_2
  L5_2 = L5_2(L6_2)
  L6_2 = A0_2[L5_2]
  L6_2 = L6_2.vSequence
  if L6_2 then
    if A2_2 then
      L7_2 = type
      L8_2 = L6_2
      L7_2 = L7_2(L8_2)
      if L7_2 ~= "table" then
        L7_2 = {}
        L8_2 = L6_2
        L7_2[1] = L8_2
        L6_2 = L7_2
      end
      L7_2 = table
      L7_2 = L7_2.insert
      L8_2 = L6_2
      L9_2 = {}
      L10_2 = A2_2
      L11_2 = A3_2
      L9_2[1] = L10_2
      L9_2[2] = L11_2
      L7_2(L8_2, L9_2)
    end
    L7_2 = MrxVoSequence
    L7_2 = L7_2.Start
    L8_2 = L6_2
    L9_2 = false
    L10_2 = MrxVoSequence
    L10_2 = L10_2.knPriorityBounties
    L7_2(L8_2, L9_2, L10_2)
  end
end

_PlayRandomVoSequenceFromTable = L0_1

function L0_1(A0_2)
  local L1_2
  A0_2._bNearVoInProgress = false
end

_NearVoComplete = L0_1
