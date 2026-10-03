local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTask"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiInterface"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = 32

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = {}
  A0_2._tEvents = L1_2
  L1_2 = {}
  A0_2._tTargets = L1_2
  A0_2._nCompleted = 0
  A0_2._nCancelled = 0
  A0_2._nQuota = 0
  A0_2._nTotal = 0
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = L1_2.bTrackOnActivate
  L4_2 = true
  L2_2 = L2_2(L3_2, L4_2)
  A0_2._bDspBlpSticky = L2_2
  L4_2 = A0_2
  L3_2 = A0_2._SetDisplaySettingsFromConfig
  L3_2(L4_2)
  L3_2 = L1_2.uTgtObjFilter
  if L3_2 then
    L3_2 = L1_2.uTgtObjFilter
    A0_2._uTgtObjFilter = L3_2
  else
    L3_2 = ObjectFilter
    L3_2 = L3_2.Create
    L3_2 = L3_2()
    A0_2._uTgtObjFilter = L3_2
    L3_2 = ObjectFilter
    L3_2 = L3_2.UsePlayers
    L4_2 = A0_2._uTgtObjFilter
    L5_2 = L1_2.bTgtPlayers
    L3_2(L4_2, L5_2)
    L3_2 = type
    L4_2 = L1_2.sTgtLabelFilter
    L3_2 = L3_2(L4_2)
    if L3_2 == "string" then
      L3_2 = ObjectFilter
      L3_2 = L3_2.SetFilter
      L4_2 = A0_2._uTgtObjFilter
      L5_2 = L1_2.sTgtLabelFilter
      L3_2(L4_2, L5_2)
    end
    
    function L3_2(A0_3, A1_3)
      local L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
      L3_3 = type
      L4_3 = A0_3
      L3_3 = L3_3(L4_3)
      if L3_3 == "string" then
        L4_3 = Pg
        L4_3 = L4_3.GetGuidByName
        L5_3 = A0_3
        L4_3 = L4_3(L5_3)
        L2_3 = L4_3
      elseif L3_3 == "userdata" then
        L2_3 = A0_3
      end
      if L2_3 then
        L4_3 = A0_2
        L4_3 = L4_3._IsValidTarget
        L5_3 = L2_3
        L4_3 = L4_3(L5_3)
        if L4_3 then
          L4_3 = ObjectFilter
          L4_3 = L4_3.AddObject
          L5_3 = A0_2
          L5_3 = L5_3._uTgtObjFilter
          L6_3 = L2_3
          L7_3 = A1_3
          L4_3(L5_3, L6_3, L7_3)
        end
      end
    end
    
    function L4_2(A0_3, A1_3)
      local L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3
      L2_3 = type
      L3_3 = A0_3
      L2_3 = L2_3(L3_3)
      if L2_3 == "table" then
        L3_3 = ipairs
        L4_3 = A0_3
        L3_3, L4_3, L5_3 = L3_3(L4_3)
        for L6_3, L7_3 in L3_3, L4_3, L5_3 do
          L8_3 = L3_2
          L9_3 = L7_3
          L10_3 = A1_3
          L8_3(L9_3, L10_3)
        end
      else
        L3_3 = L3_2
        L4_3 = A0_3
        L5_3 = A1_3
        L3_3(L4_3, L5_3)
      end
    end
    
    L5_2 = L4_2
    L6_2 = L1_2.vTgtInclude
    L7_2 = false
    L5_2(L6_2, L7_2)
    L5_2 = L4_2
    L6_2 = L1_2.vTgtExclude
    L7_2 = true
    L5_2(L6_2, L7_2)
  end
  L3_2 = L1_2.nPartsCompleted
  if L3_2 then
    L3_2 = L1_2.nPartsCompleted
    A0_2._nCompleted = L3_2
  end
  L3_2 = A0_2._uTgtObjFilter
  if L3_2 then
    L4_2 = A0_2
    L3_2 = A0_2._SetupTargets
    L3_2(L4_2)
  end
  L4_2 = A0_2
  L3_2 = A0_2._UpdateMissionInPda
  L3_2(L4_2)
  L4_2 = A0_2
  L3_2 = A0_2._SetDisplaySettingsFromConfig
  L3_2(L4_2)
  L4_2 = A0_2
  L3_2 = A0_2._RefreshAllTargetDisplay
  L3_2(L4_2)
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.IsActive
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3.PulsateRadarBlips
      L2_3 = 5
      L0_3(L1_3, L2_3)
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._CreateEvent
      L2_3 = Event
      L2_3 = L2_3.TimerRelative
      L3_3 = {}
      L4_3 = 5.5
      L3_3[1] = L4_3
      L4_3 = A0_2
      L4_3 = L4_3._InitialNotesComplete
      L5_3 = {}
      L6_3 = A0_2
      L5_3[1] = L6_3
      L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
    else
    end
  end
  
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = A0_2
    L0_3._bVoSeqOnAddCompleted = true
    L0_3 = L1_2
    L0_3 = L0_3.bSkipInitialNotifications
    if L0_3 then
      return
    end
    L0_3 = L1_2
    L0_3 = L0_3.bDspBounty
    if L0_3 then
    else
      L0_3 = L1_2
      L0_3 = L0_3.bOptional
      if L0_3 then
        L0_3 = A0_2
        L1_3 = L0_3
        L0_3 = L0_3._PrintObjectiveMessage
        L2_3 = "bonus_add"
        L3_3 = L3_2
        L0_3(L1_3, L2_3, L3_3)
      else
        L0_3 = A0_2
        L1_3 = L0_3
        L0_3 = L0_3._PrintObjectiveMessage
        L2_3 = "add"
        L3_3 = L3_2
        L0_3(L1_3, L2_3, L3_3)
      end
    end
  end
  
  L5_2 = L1_2.vVoSeqOnAdd
  if L5_2 then
    L6_2 = nil
    L7_2 = type
    L8_2 = L5_2
    L7_2 = L7_2(L8_2)
    if L7_2 == "table" then
      L7_2 = MrxUtil
      L7_2 = L7_2.CopyTable
      L8_2 = L5_2
      L7_2 = L7_2(L8_2)
      L6_2 = L7_2
    else
      L7_2 = {}
      L8_2 = L5_2
      L7_2[1] = L8_2
      L6_2 = L7_2
    end
    L7_2 = table
    L7_2 = L7_2.insert
    L8_2 = L6_2
    L9_2 = L4_2
    L7_2(L8_2, L9_2)
    L7_2 = MrxVoSequence
    L7_2 = L7_2.Start
    L8_2 = L6_2
    L7_2(L8_2)
  else
    L6_2 = L4_2
    L6_2()
  end
  L6_2 = MrxTask
  L6_2 = L6_2.Activated
  L7_2 = A0_2
  L6_2(L7_2)
  L6_2 = L1_2.vTgtInclude
  if L6_2 then
    L6_2 = MrxGui
    L6_2 = L6_2.SetObjectiveInformationCallback
    L7_2 = DisplayTextInSatelliteMode
    L8_2 = A0_2
    L6_2(L7_2, L8_2)
  end
end

Activated = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = MrxUtil
  L2_2 = L2_2.ProcessCallbackTable
  L3_2 = L1_2.tOnInitialNotesComplete
  L2_2(L3_2)
  L2_2 = MrxUtil
  L2_2 = L2_2.CallWithOptionalArgs
  L3_2 = L1_2.fOnInitialNotesComplete
  L2_2(L3_2)
end

_InitialNotesComplete = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2.IsCompleted
  L1_2 = L1_2(L2_2)
  if L1_2 then
    return
  end
  L2_2 = A0_2
  L1_2 = A0_2.GetMissionAncestor
  L1_2 = L1_2(L2_2)
  L3_2 = A0_2
  L2_2 = A0_2.Cleanup
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2._SetState
  L4_2 = MrxTaskState
  L4_2 = L4_2._knCompleted
  L2_2(L3_2, L4_2)
  L3_2 = L1_2
  L2_2 = L1_2.RefreshPdaDisplay
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2._IssueStateChangeCallbacks
  L2_2(L3_2)
end

Complete = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2.IsCancelled
  L1_2 = L1_2(L2_2)
  if L1_2 then
    return
  end
  L2_2 = A0_2
  L1_2 = A0_2.GetMissionAncestor
  L1_2 = L1_2(L2_2)
  L3_2 = A0_2
  L2_2 = A0_2.Cleanup
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2._SetState
  L4_2 = MrxTaskState
  L4_2 = L4_2._knCancelled
  L2_2(L3_2, L4_2)
  L3_2 = L1_2
  L2_2 = L1_2.RefreshPdaDisplay
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2._IssueStateChangeCallbacks
  L2_2(L3_2)
end

Cancel = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2.vVoSeqOnAdd
  if L2_2 then
    L2_2 = A0_2._bVoSeqOnAddCompleted
    if not L2_2 then
      L2_2 = MrxVoSequence
      L2_2 = L2_2.Stop
      L2_2()
    end
  end
  A0_2._uTgtObjFilter = nil
  L2_2 = _ClearEventTable
  L3_2 = A0_2._tEvents
  L2_2(L3_2)
  L2_2 = A0_2._uTargetOverflow
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = A0_2._uTargetOverflow
    L2_2(L3_2)
  end
  A0_2._uTargetOverflow = nil
  L3_2 = A0_2
  L2_2 = A0_2._SetAllTargetStatus
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = MrxGui
  L2_2 = L2_2.RemoveObjectiveInformation
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = MrxTask
  L2_2 = L2_2.Cleanup
  L3_2 = A0_2
  L2_2(L3_2)
end

Cleanup = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = pairs
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = type
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    if L6_2 == "table" then
      L6_2 = _ClearEventTable
      L7_2 = L5_2
      L6_2(L7_2)
    else
      L6_2 = Event
      L6_2 = L6_2.Delete
      L7_2 = L5_2
      L6_2(L7_2)
    end
  end
end

_ClearEventTable = L1_1

function L1_1(A0_2, ...)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = A0_2
  L2_2 = A0_2.GetConfig
  L2_2 = L2_2(L3_2)
  L3_2 = A0_2._nCompleted
  L3_2 = L3_2 + 1
  A0_2._nCompleted = L3_2
  L3_2 = MrxUtil
  L3_2 = L3_2.ProcessCallbackTable
  L4_2 = L2_2.tOnPartComplete
  L5_2 = arg
  L3_2(L4_2, L5_2)
  L3_2 = MrxUtil
  L3_2 = L3_2.CallWithOptionalArgs
  L4_2 = L2_2.fOnPartComplete
  L5_2 = arg
  L3_2(L4_2, L5_2)
  L3_2 = A0_2._oTimer
  if L3_2 then
    L3_2 = L2_2.nAddTime
    if L3_2 then
      L3_2 = A0_2._oTimer
      L4_2 = L3_2
      L3_2 = L3_2.AddTime
      L5_2 = L2_2.nAddTime
      L3_2(L4_2, L5_2)
    end
  end
  L3_2 = false
  L4_2 = "upd"
  L6_2 = A0_2
  L5_2 = A0_2.IsQuotaMet
  L5_2 = L5_2(L6_2)
  if L5_2 then
    L3_2 = true
    L4_2 = "cpl"
  end
  L5_2 = L2_2.bDspBounty
  if L5_2 then
    if L4_2 == "upd" then
      L4_2 = "bty_upd"
    elseif L4_2 == "cpl" then
      L4_2 = "bty_cpl"
    end
  else
    L5_2 = L2_2.bOptional
    if L5_2 then
      L5_2 = L2_2.bDspCollectible
      if L5_2 then
        if L4_2 == "upd" then
          L4_2 = "collectible_upd"
        end
      else
        L4_2 = "bonus_upd"
      end
    end
  end
  L6_2 = A0_2
  L5_2 = A0_2._PrintObjectiveMessage
  L7_2 = L4_2
  L5_2(L6_2, L7_2)
  L6_2 = A0_2
  L5_2 = A0_2._UpdateMissionInPda
  L5_2(L6_2)
  if L3_2 then
    L6_2 = A0_2
    L5_2 = A0_2.Complete
    L5_2(L6_2)
  end
end

CompletePart = L1_1

function L1_1(A0_2, ...)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L3_2 = A0_2
  L2_2 = A0_2.GetConfig
  L2_2 = L2_2(L3_2)
  L3_2 = A0_2._nCancelled
  L3_2 = L3_2 + 1
  A0_2._nCancelled = L3_2
  L3_2 = MrxUtil
  L3_2 = L3_2.ProcessCallbackTable
  L4_2 = L2_2.tOnPartCancel
  L5_2 = arg
  L3_2(L4_2, L5_2)
  L3_2 = MrxUtil
  L3_2 = L3_2.CallWithOptionalArgs
  L4_2 = L2_2.fOnPartCancel
  L5_2 = arg
  L3_2(L4_2, L5_2)
  L4_2 = A0_2
  L3_2 = A0_2._UpdateMissionInPda
  L3_2(L4_2)
  L3_2 = A0_2._nQuota
  L4_2 = A0_2._nTotal
  L5_2 = A0_2._nCancelled
  L4_2 = L4_2 - L5_2
  if L3_2 > L4_2 then
    L3_2 = "ccl"
    L4_2 = L2_2.bDspBounty
    if L4_2 then
      L3_2 = "bty_ccl"
    else
      L4_2 = L2_2.bOptional
      if L4_2 then
        L3_2 = "bonus_ccl"
      end
    end
    L5_2 = A0_2
    L4_2 = A0_2._PrintObjectiveMessage
    L6_2 = L3_2
    L4_2(L5_2, L6_2)
    L5_2 = A0_2
    L4_2 = A0_2.Cancel
    L4_2(L5_2)
  end
end

CancelPart = L1_1

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2._nCompleted
  L2_2 = A0_2._nQuota
  L1_2 = L1_2 == L2_2
  return L1_2
end

IsQuotaMet = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = {}
  L2_2.nQuota = true
  L2_2.bDsp = true
  L2_2.bDspDescPda = true
  L2_2.bDspBlp = true
  L2_2.bDspBlpRdr = true
  L2_2.bDspBlpPda = true
  L2_2.bDspBlpWld = true
  L2_2.bDspMsg = true
  L2_2.bDspMsgAdd = true
  L2_2.bDspMsgUpd = true
  L2_2.bDspMsgCpl = true
  L2_2.bDspMsgCcl = true
  L2_2.tOnPartComplete = true
  L2_2.fOnPartComplete = true
  L2_2.tOnPartCancel = true
  L2_2.fOnPartCancel = true
  L3_2 = L2_2[A1_2]
  if not L3_2 then
    L4_2 = MrxTask
    L4_2 = L4_2.IsLiveConfigureable
    L5_2 = A0_2
    L6_2 = A1_2
    L4_2 = L4_2(L5_2, L6_2)
    L3_2 = L4_2
  end
  return L3_2
end

IsLiveConfigureable = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L3_2 = A0_2
  L2_2 = A0_2._SetDisplaySettingsFromConfig
  L2_2(L3_2)
  L2_2 = ObjectFilter
  L2_2 = L2_2.GetObjects
  L3_2 = A0_2._uTgtObjFilter
  L4_2 = false
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = Player
  L3_2 = L3_2.GetAnyCharacter
  L3_2 = L3_2()
  L4_2 = Player
  L4_2 = L4_2.GetAllCharacters
  L4_2 = L4_2()
  L5_2 = ipairs
  L6_2 = L2_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    if L9_2 ~= L3_2 and L9_2 ~= L4_2 then
      L11_2 = A0_2
      L10_2 = A0_2._SetTargetStatus
      L12_2 = L9_2
      L13_2 = true
      L10_2(L11_2, L12_2, L13_2)
    end
  end
  L6_2 = A0_2
  L5_2 = A0_2._RefreshAllTargetDisplay
  L5_2(L6_2)
end

ReinterpretConfig = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = ObjectFilter
  L2_2 = L2_2.GetObjects
  L3_2 = A0_2._uTgtObjFilter
  L4_2 = false
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = ObjectFilter
  L3_2 = L3_2.GetCoopPlayerGuid
  L4_2 = A0_2._uTgtObjFilter
  L3_2 = L3_2(L4_2)
  if L3_2 then
    A0_2._nTotal = 1
  else
    L4_2 = Player
    L4_2 = L4_2.GetAnyCharacter
    L4_2 = L4_2()
    L5_2 = Player
    L5_2 = L5_2.GetAllCharacters
    L5_2 = L5_2()
    A0_2._nTotal = 0
    L6_2 = ipairs
    L7_2 = L2_2
    L6_2, L7_2, L8_2 = L6_2(L7_2)
    for L9_2, L10_2 in L6_2, L7_2, L8_2 do
      if L10_2 ~= L4_2 and L10_2 ~= L5_2 then
        L11_2 = A0_2._nTotal
        L11_2 = L11_2 + 1
        A0_2._nTotal = L11_2
        L12_2 = A0_2
        L11_2 = A0_2._SetTargetStatus
        L13_2 = L10_2
        L14_2 = true
        L11_2(L12_2, L13_2, L14_2)
      end
    end
  end
  L4_2 = A0_2._nTotal
  A0_2._nQuota = L4_2
  L4_2 = type
  L5_2 = L1_2.nQuota
  L4_2 = L4_2(L5_2)
  if L4_2 == "number" then
    L4_2 = L1_2.nQuota
    A0_2._nQuota = L4_2
  end
end

_SetupTargets = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = ObjectFilter
  L2_2 = L2_2.AddObject
  L3_2 = A0_2._uTgtObjFilter
  L4_2 = A1_2
  L5_2 = true
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = A0_2
  L2_2 = A0_2._SetTargetStatus
  L4_2 = A1_2
  L5_2 = false
  L2_2(L3_2, L4_2, L5_2)
end

RemoveTarget = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2
  L4_2 = A0_2._tTargets
  L5_2 = L4_2[A1_2]
  if not L5_2 then
    L5_2 = {}
    L4_2[A1_2] = L5_2
  end
  L5_2 = L4_2[A1_2]
  L5_2.bStatus = A2_2
  if A3_2 then
    L5_2 = L4_2[A1_2]
    L5_2.sType = A3_2
  end
  L6_2 = A0_2
  L5_2 = A0_2._RefreshTargetDisplay
  L7_2 = A1_2
  L5_2(L6_2, L7_2)
end

_SetTargetStatus = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = pairs
  L3_2 = A0_2._tTargets
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L8_2 = A0_2
    L7_2 = A0_2._SetTargetStatus
    L9_2 = L5_2
    L10_2 = A1_2
    L7_2(L8_2, L9_2, L10_2)
  end
end

_SetAllTargetStatus = L1_1

function L1_1(A0_2)
  local L1_2
  L1_2 = A0_2._uTgtObjFilter
  return L1_2
end

GetTargetObjectFilter = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = L1_2.bDsp
  L4_2 = true
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    L3_2 = MrxUtil
    L3_2 = L3_2.SetDefault
    L4_2 = L1_2.bDspBlp
    L5_2 = true
    L3_2 = L3_2(L4_2, L5_2)
    L4_2 = MrxUtil
    L4_2 = L4_2.SetDefault
    L5_2 = L1_2.bDspMsg
    L6_2 = true
    L4_2 = L4_2(L5_2, L6_2)
    L5_2 = MrxUtil
    L5_2 = L5_2.SetDefault
    L6_2 = L1_2.bDspDescPda
    L7_2 = true
    L5_2 = L5_2(L6_2, L7_2)
    L7_2 = A0_2
    L6_2 = A0_2._ToggleBlipDisplay
    L8_2 = L3_2
    L6_2(L7_2, L8_2)
    L7_2 = A0_2
    L6_2 = A0_2._ToggleMsgDisplay
    L8_2 = L4_2
    L6_2(L7_2, L8_2)
    L7_2 = A0_2
    L6_2 = A0_2._SetDescPdaDisplay
    L8_2 = L5_2
    L6_2(L7_2, L8_2)
    if L3_2 then
      L7_2 = A0_2
      L6_2 = A0_2._SetBlipDisplay
      L8_2 = L1_2
      L6_2(L7_2, L8_2)
    end
    if L4_2 then
      L7_2 = A0_2
      L6_2 = A0_2._SetMsgDisplay
      L8_2 = L1_2
      L6_2(L7_2, L8_2)
    end
  else
    L4_2 = A0_2
    L3_2 = A0_2._ToggleBlipDisplay
    L5_2 = L2_2
    L3_2(L4_2, L5_2)
    L4_2 = A0_2
    L3_2 = A0_2._ToggleMsgDisplay
    L5_2 = L2_2
    L3_2(L4_2, L5_2)
    L4_2 = A0_2
    L3_2 = A0_2._SetDescPdaDisplay
    L5_2 = L2_2
    L3_2(L4_2, L5_2)
  end
end

_SetDisplaySettingsFromConfig = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = {}
  L2_2.bDspBlpRdr = A1_2
  L2_2.bDspBlpPda = A1_2
  L2_2.bDspBlpWld = A1_2
  L4_2 = A0_2
  L3_2 = A0_2._SetBlipDisplay
  L5_2 = L2_2
  L3_2(L4_2, L5_2)
end

_ToggleBlipDisplay = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = A1_2.bDspBlpRdr
  L4_2 = A0_2._bDspBlpRdr
  L2_2 = L2_2(L3_2, L4_2)
  A0_2._bDspBlpRdr = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = A1_2.bDspBlpPda
  L4_2 = A0_2._bDspBlpPda
  L2_2 = L2_2(L3_2, L4_2)
  A0_2._bDspBlpPda = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = A1_2.bDspBlpWld
  L4_2 = A0_2._bDspBlpWld
  L2_2 = L2_2(L3_2, L4_2)
  A0_2._bDspBlpWld = L2_2
end

_SetBlipDisplay = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = {}
  L2_2.bDspMsgAdd = A1_2
  L2_2.bDspMsgUpd = A1_2
  L2_2.bDspMsgCpl = A1_2
  L2_2.bDspMsgCcl = A1_2
  L4_2 = A0_2
  L3_2 = A0_2._SetMsgDisplay
  L5_2 = L2_2
  L3_2(L4_2, L5_2)
end

_ToggleMsgDisplay = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = A1_2.bDspMsgAdd
  L4_2 = A0_2._bDspMsgAdd
  L2_2 = L2_2(L3_2, L4_2)
  A0_2._bDspMsgAdd = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = A1_2.bDspMsgUpd
  L4_2 = A0_2._bDspMsgUpd
  L2_2 = L2_2(L3_2, L4_2)
  A0_2._bDspMsgUpd = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = A1_2.bDspMsgCpl
  L4_2 = A0_2._bDspMsgCpl
  L2_2 = L2_2(L3_2, L4_2)
  A0_2._bDspMsgCpl = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = A1_2.bDspMsgCcl
  L4_2 = A0_2._bDspMsgCcl
  L2_2 = L2_2(L3_2, L4_2)
  A0_2._bDspMsgCcl = L2_2
end

_SetMsgDisplay = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = A1_2
  L4_2 = A0_2._bDspDescPda
  L2_2 = L2_2(L3_2, L4_2)
  A0_2._bDspDescPda = L2_2
end

_SetDescPdaDisplay = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2
  L4_2 = A0_2._tTargets
  L5_2 = L4_2[A1_2]
  if not L5_2 then
    L5_2 = {}
    L4_2[A1_2] = L5_2
  end
  L5_2 = L4_2[A1_2]
  L6_2 = not A2_2
  L5_2.bSuppressDsp = L6_2
  L6_2 = A0_2
  L5_2 = A0_2._RefreshTargetDisplay
  L7_2 = A1_2
  L5_2(L6_2, L7_2)
  if A2_2 and A3_2 then
    L5_2 = PulsateRadarBlip
    L6_2 = A1_2
    L7_2 = 2
    L5_2(L6_2, L7_2)
  end
end

_SetTargetDisplay = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = A0_2._tTargets
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = _SetTargetDisplay
    L9_2 = A0_2
    L10_2 = L6_2
    L11_2 = A1_2
    L8_2(L9_2, L10_2, L11_2)
  end
end

_SetAllTargetsDisplay = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2
  L2_2 = A0_2._tTargets
  L2_2 = L2_2[A1_2]
  if not L2_2 then
    L3_2 = false
    return L3_2
  end
  L3_2 = Sys
  L3_2 = L3_2.GuidToString
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = L2_2.bStatus
  if L4_2 then
    L4_2 = L2_2.bSuppressDsp
    L4_2 = L2_2.bLimitedDsp
    L4_2 = not L4_2 and L4_2
  end
  L5_2 = A0_2._bDspBlpRdr
  if not L5_2 then
    L5_2 = A0_2._bDspBlpPda
    if not L5_2 then
      L5_2 = A0_2._bDspBlpWld
    end
  end
  L6_2 = L2_2.bDisplay
  if not L6_2 and L4_2 and L5_2 then
    L7_2 = A0_2
    L6_2 = A0_2.GetConfig
    L6_2 = L6_2(L7_2)
    L7_2 = {}
    L8_2 = A0_2._bDspBlpRdr
    if L8_2 then
      L9_2 = A0_2
      L8_2 = A0_2._BuildRadarBlipConfig
      L10_2 = A1_2
      L8_2 = L8_2(L9_2, L10_2)
      L7_2 = L8_2
      L8_2 = Hud
      L8_2 = L8_2.Radar
      L9_2 = L8_2
      L8_2 = L8_2.AddObjective
      L10_2 = L7_2
      L8_2(L9_2, L10_2)
    end
    L8_2 = {}
    L9_2 = A0_2._bDspBlpWld
    if L9_2 then
      L9_2 = A0_2._GetTargetBlipColor
      L10_2 = L6_2.bOptional
      L9_2, L10_2, L11_2 = L9_2(L10_2)
      L12_2 = 0
      L13_2 = Object
      L13_2 = L13_2.HasLabel
      L14_2 = A1_2
      L15_2 = "Human"
      L13_2 = L13_2(L14_2, L15_2)
      if not L13_2 then
        L13_2 = Object
        L13_2 = L13_2.GetParent
        L14_2 = A1_2
        L13_2 = L13_2(L14_2)
        L14_2 = Pg
        L14_2 = L14_2.GetGuidByName
        L15_2 = "location"
        L14_2 = L14_2(L15_2)
        if L13_2 ~= L14_2 then
          goto lbl_77
        end
      end
      L12_2 = 2
      ::lbl_77::
      L13_2 = A0_2._GetTargetGameSpaceIcon
      L13_2 = L13_2()
      if not L13_2 then
        L13_2 = "HUD_objective_action"
      end
      L14_2 = L2_2.sType
      if L14_2 == "destination" then
        L14_2 = A0_2._GetDestinationGameSpaceIcon
        L14_2 = L14_2()
        L13_2 = L14_2
      else
        L14_2 = L6_2.sDspBlpWldIcon
        if L14_2 then
          L13_2 = L6_2.sDspBlpWldIcon
        end
      end
      L14_2 = nil
      L15_2 = 0
      L17_2 = A0_2
      L16_2 = A0_2.GetMissionAncestor
      L16_2 = L16_2(L17_2)
      if L16_2 then
        L18_2 = L16_2
        L17_2 = L16_2.IsContract
        L17_2 = L17_2(L18_2)
        if L17_2 then
          L18_2 = L16_2
          L17_2 = L16_2.GetMissionId
          L17_2 = L17_2(L18_2)
          L14_2 = L17_2
          if L14_2 then
            L17_2 = String
            L17_2 = L17_2.GetHash
            L18_2 = L14_2
            L17_2 = L17_2(L18_2)
            L15_2 = L17_2
          end
        end
      end
      L17_2 = A0_2._GetJust2DCheckNeeded
      L17_2 = L17_2()
      L18_2 = L6_2.nDspBlpWldNearDist
      if not L18_2 then
        L18_2 = 5
      end
      L19_2 = L6_2.nDspBlpWldFarDist
      if not L19_2 then
        L19_2 = 175
      end
      L20_2 = Marker
      L20_2 = L20_2.AddBlip
      L21_2 = A1_2
      L22_2 = L13_2
      L23_2 = 32
      L24_2 = L9_2
      L25_2 = L10_2
      L26_2 = L11_2
      L27_2 = 255
      L28_2 = L12_2
      L29_2 = L18_2
      L30_2 = L19_2
      L31_2 = L0_1
      L32_2 = L14_2
      L33_2 = L17_2
      L20_2 = L20_2(L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2)
      L2_2.uMarkerGuid = L20_2
      L20_2 = Net
      L20_2 = L20_2.IsServer
      L20_2 = L20_2()
      if L20_2 then
        L20_2 = Net
        L20_2 = L20_2.SendEvent_AddMarkerObjective
        L21_2 = A1_2
        L22_2 = L2_2.uMarkerGuid
        L23_2 = L9_2
        L24_2 = L10_2
        L25_2 = L11_2
        L26_2 = L12_2
        L27_2 = MrxUtil
        L27_2 = L27_2.MarkerGetIndexByName_World
        L28_2 = L13_2 or L28_2
        if not L13_2 then
          L28_2 = ""
        end
        L27_2 = L27_2(L28_2)
        L28_2 = 1
        L29_2 = 16
        L30_2 = false
        L31_2 = L18_2
        L32_2 = L19_2
        L33_2 = L15_2
        L20_2(L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2)
      end
      L20_2 = L2_2.uMarkerGuid
      L8_2.uMarkerGuid = L20_2
      L8_2.nR = L9_2
      L8_2.nG = L10_2
      L8_2.nB = L11_2
      L8_2.nVerticalOffset = L12_2
      L8_2.sDspBlpWldIcon = L13_2
    end
    L9_2 = {}
    L10_2 = A0_2._bDspBlpPda
    if L10_2 then
      L10_2 = L2_2.bLimitedDsp
      if not L10_2 then
        L11_2 = A0_2
        L10_2 = A0_2._BuildPdaBlipConfig
        L12_2 = A1_2
        L10_2 = L10_2(L11_2, L12_2)
        L9_2 = L10_2
        L10_2 = Pda
        L10_2 = L10_2.Map
        L11_2 = L10_2
        L10_2 = L10_2.AddBlip
        L12_2 = L9_2
        L10_2(L11_2, L12_2)
      end
    end
    L2_2.bDisplay = true
    L10_2 = true
    return L10_2
  else
    L6_2 = L2_2.bDisplay
    if L6_2 and L4_2 and L5_2 then
      L6_2 = A0_2._bDspBlpRdr
      if L6_2 then
        L7_2 = A0_2
        L6_2 = A0_2._BuildRadarBlipConfig
        L8_2 = A1_2
        L6_2 = L6_2(L7_2, L8_2)
        L7_2 = Hud
        L7_2 = L7_2.Radar
        L8_2 = L7_2
        L7_2 = L7_2.UpdateObjective
        L9_2 = L6_2
        L7_2(L8_2, L9_2)
      end
      L6_2 = A0_2._bDspBlpPda
      if L6_2 then
        L7_2 = A0_2
        L6_2 = A0_2._BuildPdaBlipConfig
        L8_2 = A1_2
        L6_2 = L6_2(L7_2, L8_2)
        L7_2 = Pda
        L7_2 = L7_2.Map
        L8_2 = L7_2
        L7_2 = L7_2.AddBlip
        L9_2 = L6_2
        L7_2(L8_2, L9_2)
      end
      L6_2 = true
      return L6_2
    else
      L6_2 = L2_2.bDisplay
      if L6_2 then
        if L4_2 then
          L6_2 = A0_2._bDspBlpWld
          if L6_2 then
            goto lbl_269
          end
        end
        L6_2 = Hud
        L6_2 = L6_2.Radar
        L7_2 = L6_2
        L6_2 = L6_2.RemoveObjective
        L8_2 = {}
        L8_2.sName = L3_2
        L6_2(L7_2, L8_2)
        L6_2 = type
        L7_2 = L2_2.uMarkerGuid
        L6_2 = L6_2(L7_2)
        if L6_2 == "userdata" then
          L6_2 = Marker
          L6_2 = L6_2.Remove
          L7_2 = L2_2.uMarkerGuid
          L6_2(L7_2)
          L6_2 = Net
          L6_2 = L6_2.IsServer
          L6_2 = L6_2()
          if L6_2 then
            L6_2 = Net
            L6_2 = L6_2.SendEvent_RemoveMarkerObjective
            L7_2 = L2_2.uMarkerGuid
            L6_2(L7_2)
          end
        end
        L6_2 = L2_2.bLimitedDsp
        if not L6_2 then
          L6_2 = Pda
          L6_2 = L6_2.Map
          L7_2 = L6_2
          L6_2 = L6_2.RemoveBlip
          L8_2 = {}
          L8_2.sName = L3_2
          L6_2(L7_2, L8_2)
        end
        L2_2.bDisplay = false
        L6_2 = true
        return L6_2
      end
    end
  end
  ::lbl_269::
  L6_2 = false
  return L6_2
end

_RefreshTargetDisplay = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L3_2 = A0_2
  L2_2 = A0_2.GetConfig
  L2_2 = L2_2(L3_2)
  L3_2 = A0_2._GetTargetBlipColor
  L4_2 = L2_2.bOptional
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  L6_2 = A0_2._tTargets
  L6_2 = L6_2[A1_2]
  if not L6_2 then
    return
  end
  L7_2 = A0_2._GetTargetRadarIcon
  L7_2 = L7_2()
  L8_2 = L6_2.sType
  if L8_2 == "destination" then
    L8_2 = A0_2._GetDestinationRadarIcon
    L8_2 = L8_2()
    L7_2 = L8_2
  end
  L8_2 = L2_2.sDspBlpRdrIcon
  if L8_2 then
    L7_2 = L2_2.sDspBlpRdrIcon
  end
  L8_2 = nil
  L9_2 = nil
  L10_2 = nil
  if L7_2 then
    L8_2 = L7_2
    L9_2 = 10.666667
    L10_2 = 10.666667
  else
    L8_2 = "objective_action"
    L9_2 = 8
    L10_2 = 8
  end
  L11_2 = 5
  L12_2 = L2_2.nSortOrder
  if L12_2 then
    L11_2 = L2_2.nSortOrder
  else
    L12_2 = L2_2.bOptional
    if L12_2 then
      L11_2 = 6
    end
  end
  L12_2 = {}
  L13_2 = Sys
  L13_2 = L13_2.GuidToString
  L14_2 = A1_2
  L13_2 = L13_2(L14_2)
  L12_2.sName = L13_2
  L12_2.uGuid = A1_2
  L12_2.sTexture = L8_2
  L12_2.nR = L3_2
  L12_2.nG = L4_2
  L12_2.nB = L5_2
  L12_2.nWidth = L9_2
  L12_2.nHeight = L10_2
  L13_2 = A0_2._bDspBlpSticky
  L12_2.bSticky = L13_2
  L12_2.nSortOrder = L11_2
  return L12_2
end

_BuildRadarBlipConfig = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2._tTargets
  L2_2 = L2_2[A1_2]
  if not L2_2 then
    return
  end
  L4_2 = A0_2
  L3_2 = A0_2.GetConfig
  L3_2 = L3_2(L4_2)
  L4_2 = L3_2.sDspBlpPdaIcon
  if not L4_2 then
    L4_2 = A0_2._GetTargetPdaIcon
    L5_2 = L3_2.bOptional
    L4_2 = L4_2(L5_2)
    if not L4_2 then
      L4_2 = "icon_yellow_mc"
    end
  end
  L5_2 = L3_2.sDspBlpPdaIcon
  if L5_2 then
    L4_2 = L3_2.sDspBlpPdaIcon
  end
  L5_2 = L2_2.sType
  if L5_2 == "destination" then
    L5_2 = A0_2._GetDestinationPdaIcon
    L6_2 = L3_2.bOptional
    L5_2 = L5_2(L6_2)
    L4_2 = L5_2
  end
  L6_2 = A0_2
  L5_2 = A0_2.GetMissionAncestor
  L5_2 = L5_2(L6_2)
  L6_2 = nil
  if L5_2 then
    L8_2 = L5_2
    L7_2 = L5_2.GetMissionId
    L7_2 = L7_2(L8_2)
    L6_2 = L7_2
  end
  L7_2 = 2
  L8_2 = L3_2.bOptional
  if L8_2 then
    L7_2 = 3
  end
  L8_2 = {}
  L8_2.sMission = L6_2
  L9_2 = Sys
  L9_2 = L9_2.GuidToString
  L10_2 = A1_2
  L9_2 = L9_2(L10_2)
  L8_2.sName = L9_2
  L10_2 = A0_2
  L9_2 = A0_2.GetDescription
  L9_2 = L9_2(L10_2)
  L8_2.sLabel = L9_2
  L8_2.uGuid = A1_2
  L8_2.sTexture = L4_2
  L8_2.nSortOrder = L7_2
  return L8_2
end

_BuildPdaBlipConfig = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = A0_2[2]
  L3_2 = A1_2[2]
  L2_2 = L2_2 < L3_2
  return L2_2
end

_compare = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = A0_2._uTargetOverflow
  if not L1_2 then
    L1_2 = pairs
    L2_2 = A0_2._tTargets
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    for L4_2, L5_2 in L1_2, L2_2, L3_2 do
      L7_2 = A0_2
      L6_2 = A0_2._RefreshTargetDisplay
      L8_2 = L4_2
      L6_2(L7_2, L8_2)
    end
  else
  end
end

_RefreshAllTargetDisplay = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = A0_2._bDspBlpPda
  if L1_2 then
    L1_2 = pairs
    L2_2 = A0_2._tTargets
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    for L4_2, L5_2 in L1_2, L2_2, L3_2 do
      L6_2 = L5_2.bDisplay
      if L6_2 then
        L6_2 = L5_2.bStatus
        if L6_2 then
          L6_2 = L5_2.bSuppressDsp
          if not L6_2 then
            L7_2 = A0_2
            L6_2 = A0_2._BuildPdaBlipConfig
            L8_2 = L4_2
            L6_2 = L6_2(L7_2, L8_2)
            L7_2 = Pda
            L7_2 = L7_2.Map
            L8_2 = L7_2
            L7_2 = L7_2.AddBlip
            L9_2 = L6_2
            L7_2(L8_2, L9_2)
          end
        end
      end
    end
  end
end

RefreshPdaDisplay = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = pairs
  L3_2 = A0_2._tTargets
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = PulsateRadarBlip
    L8_2 = L5_2
    L9_2 = A1_2
    L7_2(L8_2, L9_2)
  end
end

PulsateRadarBlips = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = Sys
  L2_2 = L2_2.GuidToString
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = Hud
  L3_2 = L3_2.Radar
  L4_2 = L3_2
  L3_2 = L3_2.AnimateObjectiveSize
  L5_2 = {}
  L5_2.sName = L2_2
  L5_2.nMaxWidth = 12
  L5_2.nMaxHeight = 12
  L5_2.nSpeedWidth = 20
  L5_2.nSpeedHeight = 20
  L5_2.nDuration = A1_2
  L3_2(L4_2, L5_2)
end

PulsateRadarBlip = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  A0_2._bDspBlpSticky = A1_2
  L3_2 = A0_2
  L2_2 = A0_2._RefreshAllTargetDisplay
  L2_2(L3_2)
  if A1_2 then
    L3_2 = A0_2
    L2_2 = A0_2.PulsateRadarBlips
    L2_2(L3_2)
    L2_2 = "add"
    L4_2 = A0_2
    L3_2 = A0_2.GetConfig
    L3_2 = L3_2(L4_2)
    L4_2 = L3_2.bDspBounty
    if L4_2 then
      L2_2 = "bty_add"
    else
      L4_2 = L3_2.bOptional
      if L4_2 then
        L2_2 = "bonus_add"
      end
    end
    L5_2 = A0_2
    L4_2 = A0_2._PrintObjectiveMessage
    L6_2 = L2_2
    L4_2(L5_2, L6_2)
  end
end

EnableTracking = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L5_2 = GetObjectiveDescription
  L7_2 = A0_2
  L6_2 = A0_2.GetShortDescription
  L6_2 = L6_2(L7_2)
  L8_2 = A0_2
  L7_2 = A0_2.GetProgressCompleted
  L7_2 = L7_2(L8_2)
  L9_2 = A0_2
  L8_2 = A0_2.GetProgressQuota
  L8_2 = L8_2(L9_2)
  L9_2 = A1_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  if A1_2 == "add" or A1_2 == "bonus_add" or A1_2 == "bty_add" then
    L4_2 = A0_2._bDspMsgAdd
  elseif A1_2 == "upd" or A1_2 == "bonus_upd" or A1_2 == "bty_upd" or A1_2 == "collectible_upd" then
    L4_2 = A0_2._bDspMsgUpd
  elseif A1_2 == "cpl" or A1_2 == "bonus_cpl" or A1_2 == "bty_cpl" then
    L4_2 = A0_2._bDspMsgCpl
  elseif A1_2 == "ccl" or A1_2 == "bonus_ccl" or A1_2 == "bty_ccl" then
    L4_2 = A0_2._bDspMsgCcl
    L7_2 = A0_2
    L6_2 = A0_2.GetShortDescription
    L6_2 = L6_2(L7_2)
    L5_2 = L6_2
  end
  L6_2 = ""
  L8_2 = A0_2
  L7_2 = A0_2.GetMissionAncestor
  L7_2 = L7_2(L8_2)
  if L7_2 then
    L9_2 = L7_2
    L8_2 = L7_2.GetMissionId
    L8_2 = L8_2(L9_2)
    sMissionId = L8_2
  end
  L8_2 = sMissionId
  if L8_2 then
    L8_2 = L6_2
    L9_2 = sMissionId
    L6_2 = L8_2 .. L9_2
  end
  L9_2 = A0_2
  L8_2 = A0_2.GetName
  L8_2 = L8_2(L9_2)
  if L8_2 then
    L9_2 = L6_2
    L10_2 = L8_2
    L6_2 = L9_2 .. L10_2
  end
  L9_2 = MrxGuiInterface
  L9_2 = L9_2.DisplayObjectiveMessage
  L10_2 = L4_2
  L12_2 = A0_2
  L11_2 = A0_2.GetInlineIcon
  L11_2 = L11_2(L12_2)
  L12_2 = A1_2
  L13_2 = L5_2
  L14_2 = L6_2
  L15_2 = A2_2
  L16_2 = A3_2
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
end

_PrintObjectiveMessage = L1_1

function L1_1(A0_2)
  local L1_2
  L1_2 = A0_2._bDspDescPda
  return L1_2
end

GetDisplayDescription = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = GetObjectiveDescription
  L4_2 = A0_2
  L3_2 = A0_2.GetShortDescription
  L3_2 = L3_2(L4_2)
  L4_2 = A0_2._nCompleted
  L5_2 = A0_2._nQuota
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  if A1_2 then
    L4_2 = A0_2
    L3_2 = A0_2.GetInlineIcon
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L4_2 = L3_2
      L5_2 = " "
      L6_2 = L2_2
      L2_2 = L4_2 .. L5_2 .. L6_2
    end
  end
  return L2_2
end

GetDescription = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L4_2 = A0_2
  if not A1_2 then
    A1_2 = 0
  end
  if not A2_2 then
    A2_2 = 0
  end
  L5_2 = nil
  if A2_2 <= 0 and 1 <= A1_2 then
    L6_2 = "("
    L7_2 = A1_2
    L8_2 = ")"
    L5_2 = L6_2 .. L7_2 .. L8_2
  elseif 1 < A2_2 then
    L6_2 = "("
    L7_2 = A1_2
    L8_2 = "/"
    L9_2 = A2_2
    L10_2 = ")"
    L5_2 = L6_2 .. L7_2 .. L8_2 .. L9_2 .. L10_2
  end
  if A0_2 and L5_2 then
    if A3_2 == "collectible_upd" then
      L6_2 = L5_2
      L7_2 = ": "
      L8_2 = A0_2
      L4_2 = L6_2 .. L7_2 .. L8_2
    else
      L6_2 = A0_2
      L7_2 = " "
      L8_2 = L5_2
      L4_2 = L6_2 .. L7_2 .. L8_2
    end
  end
  return L4_2
end

GetObjectiveDescription = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = L1_2.sDspShortDesc
  L5_2 = A0_2
  L4_2 = A0_2._GetShortDescription
  L4_2, L5_2 = L4_2(L5_2)
  return L2_2(L3_2, L4_2, L5_2)
end

GetShortDescription = L1_1

function L1_1(A0_2)
  local L1_2
  L1_2 = A0_2._nQuota
  return L1_2
end

GetProgressQuota = L1_1

function L1_1(A0_2)
  local L1_2
  L1_2 = A0_2._nCompleted
  return L1_2
end

GetProgressCompleted = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2
  while true do
    L3_2 = L1_2
    L2_2 = L1_2.GetParent
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L3_2 = L2_2.GetMissionId
      if L3_2 then
        return L2_2
      end
      L1_2 = L2_2
    else
      break
    end
  end
end

GetMissionAncestor = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2.GetMissionAncestor
  L1_2 = L1_2(L2_2)
  L3_2 = L1_2
  L2_2 = L1_2.RefreshPdaDisplay
  L2_2(L3_2)
end

_UpdateMissionInPda = L1_1

function L1_1()
  local L0_2, L1_2
  L0_2 = "NULL"
  return L0_2
end

_GetShortDescription = L1_1

function L1_1(A0_2)
  local L1_2
  if A0_2 then
    L1_2 = MrxUtil
    L1_2 = L1_2.GetSecondaryObjectiveRgb
    return L1_2()
  else
    L1_2 = MrxUtil
    L1_2 = L1_2.GetPrimaryObjectiveRgb
    return L1_2()
  end
end

_GetTargetBlipColor = L1_1

function L1_1()
  local L0_2, L1_2
  L0_2 = false
  return L0_2
end

_GetJust2DCheckNeeded = L1_1

function L1_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2.bOptional
  if L2_2 then
    L2_2 = "[objaction2]"
    return L2_2
  else
    L2_2 = "[objaction]"
    return L2_2
  end
end

GetInlineIcon = L1_1

function L1_1()
  local L0_2, L1_2
  return L0_2
end

_GetTargetRadarIcon = L1_1

function L1_1(A0_2)
  local L1_2
  if A0_2 then
    L1_2 = "icon_action_2_mc"
    return L1_2
  else
    L1_2 = "icon_action_1_mc"
    return L1_2
  end
end

_GetTargetPdaIcon = L1_1

function L1_1()
  local L0_2, L1_2
  return L0_2
end

_GetTargetGameSpaceIcon = L1_1

function L1_1(A0_2)
  local L1_2
  L1_2 = true
  return L1_2
end

_IsValidTarget = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  if not A1_2 then
    return
  end
  L2_2 = pairs
  L3_2 = A0_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = L6_2._tTargets
    if L7_2 then
      L7_2 = L6_2._tTargets
      L7_2 = L7_2[A1_2]
      if L7_2 then
        L8_2 = L6_2
        L7_2 = L6_2.GetConfig
        L7_2 = L7_2(L8_2)
        L8_2 = L7_2.bOptional
        if L8_2 then
          L8_2 = "[2ndobjt]"
          L10_2 = L6_2
          L9_2 = L6_2.GetDescription
          L11_2 = true
          L9_2 = L9_2(L10_2, L11_2)
          L8_2 = L8_2 .. L9_2
          return L8_2
        else
          L8_2 = "[objt]"
          L10_2 = L6_2
          L9_2 = L6_2.GetDescription
          L11_2 = true
          L9_2 = L9_2(L10_2, L11_2)
          L8_2 = L8_2 .. L9_2
          return L8_2
        end
      end
    end
  end
end

DisplayTextInSatelliteMode = L1_1
