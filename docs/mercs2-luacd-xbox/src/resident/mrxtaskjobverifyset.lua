local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskJob"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
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
    L7_2 = L3_2.sDefenseLayer
    L4_2(L5_2, L6_2, L7_2)
    L5_2 = A0_2
    L4_2 = A0_2._GetTargetData
    L6_2 = L3_2.sTarget
    L4_2 = L4_2(L5_2, L6_2)
    if L4_2 then
      L5_2 = L3_2.vNearVoSequence
      L4_2.vNearVoSequence = L5_2
      L5_2 = L3_2.sStagingLayer
      L4_2.sStagingLayer = L5_2
      L5_2 = L3_2.sDefenseLayer
      L4_2.sDefenseLayer = L5_2
      L5_2 = L3_2.sPristineLayer
      L4_2.sPristineLayer = L5_2
      L5_2 = L3_2.sVerifiedLayer
      L4_2.sVerifiedLayer = L5_2
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
  L6_2.sName = "VerifySet"
  L6_2.sModuleName = "MrxTaskObjectiveVerify"
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
    L7_2 = "[GurJob002.Objectives.001]"
  end
  L6_2.sDspShortDesc = L7_2
  L6_2.bDspBounty = true
  L6_2.bDspMsgUpd = false
  L6_2.bDspMsgCpl = false
  L6_2.sDspBlpPdaIcon = "icon_verify_3_mc"
  L7_2 = A0_2._bTrackOnActivate
  L6_2.bTrackOnActivate = L7_2
  L7_2 = A0_2._bSkipInitialNotifications
  L6_2.bSkipInitialNotifications = L7_2
  L7_2 = A0_2._sFactionId
  L6_2.sFactionId = L7_2
  
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
  
  function L7_2(A0_3, A1_3)
    local L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3
    L2_3 = A0_2
    L3_3 = L2_3
    L2_3 = L2_3._GetTargetData
    L4_3 = A0_3
    L2_3 = L2_3(L3_3, L4_3)
    if L2_3 then
      L3_3 = L2_3.sStagingLayer
      if L3_3 then
        L3_3 = MrxLayerManager
        L3_3 = L3_3.MarkForRemoval
        L4_3 = L2_3.sStagingLayer
        L3_3(L4_3)
      end
      L3_3 = L2_3.sVerifiedLayer
      if L3_3 then
        L3_3 = MrxLayerManager
        L3_3 = L3_3.MarkForAddition
        L4_3 = L2_3.sVerifiedLayer
        L3_3(L4_3)
      end
    end
    L3_3 = "hvtcapture"
    if A1_3 then
      L3_3 = "hvtkill"
    end
    L4_3 = MrxFactionManager
    L4_3 = L4_3.GetInlineIcon
    L5_3 = A0_2
    L6_3 = L5_3
    L5_3 = L5_3.GetFactionId
    L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3 = L5_3(L6_3)
    L4_3 = L4_3(L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3)
    L5_3 = " "
    L6_3 = A0_2
    L6_3 = L6_3._oObjective
    L7_3 = L6_3
    L6_3 = L6_3.GetDescription
    L8_3 = true
    L6_3 = L6_3(L7_3, L8_3)
    L4_3 = L4_3 .. L5_3 .. L6_3
    L5_3 = Hud
    L5_3 = L5_3.EventFanfare
    L6_3 = L5_3
    L5_3 = L5_3.Commence
    L7_3 = {}
    L7_3.sType = L3_3
    L7_3.vText = L4_3
    L5_3(L6_3, L7_3)
    L5_3 = Net
    L5_3 = L5_3.IsServer
    L5_3 = L5_3()
    if L5_3 then
      L5_3 = 1
      if A1_3 then
        L5_3 = 2
      end
      L6_3 = A0_2
      L7_3 = L6_3
      L6_3 = L6_3.GetFactionId
      L6_3 = L6_3(L7_3)
      L7_3 = A0_2
      L7_3 = L7_3._oObjective
      L8_3 = L7_3
      L7_3 = L7_3.GetShortDescription
      L7_3 = L7_3(L8_3)
      L8_3 = MrxUtil
      L8_3 = L8_3.GetInlineIconIndexByName
      L9_3 = A0_2
      L9_3 = L9_3._oObjective
      L10_3 = L9_3
      L9_3 = L9_3.GetInlineIcon
      L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3 = L9_3(L10_3)
      L8_3 = L8_3(L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3)
      L9_3 = A0_2
      L9_3 = L9_3._oObjective
      L10_3 = L9_3
      L9_3 = L9_3.GetProgressCompleted
      L9_3 = L9_3(L10_3)
      L10_3 = A0_2
      L10_3 = L10_3._oObjective
      L11_3 = L10_3
      L10_3 = L10_3.GetProgressQuota
      L10_3 = L10_3(L11_3)
      L11_3 = Net
      L11_3 = L11_3.SendEvent_HVTFanfare
      L12_3 = L5_3
      L13_3 = L6_3
      L14_3 = L7_3
      L15_3 = L8_3
      L16_3 = L9_3
      L17_3 = L10_3
      L11_3(L12_3, L13_3, L14_3, L15_3, L16_3, L17_3)
    end
    if A1_3 then
      L5_3 = MrxRewardData
      L5_3 = L5_3.EnableCashRewardHalving
      L6_3 = true
      L5_3(L6_3)
    end
    L5_3 = A0_2
    L6_3 = L5_3
    L5_3 = L5_3._TargetComplete
    L7_3 = A0_3
    L5_3(L6_3, L7_3)
    L5_3 = MrxRewardData
    L5_3 = L5_3.EnableCashRewardHalving
    L6_3 = false
    L5_3(L6_3)
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
  A0_2._sFactionId = A1_2
end

_SetFactionId = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = {}
  L1_2 = "sPristineLayer"
  L2_2 = "sStagingLayer"
  L3_2 = "sDefenseLayer"
  L0_2[1] = L1_2
  L0_2[2] = L2_2
  L0_2[3] = L3_2
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

function L0_1()
  local L0_2, L1_2
  L0_2 = true
  return L0_2
end

_GetNearbyVoPlaybackMode = L0_1
L0_1 = false
_bPlayedVerificationVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = _bPlayedVerificationVO
  if not L1_2 then
    L1_2 = MrxVoSequence
    L1_2 = L1_2.Start
    L2_2 = {}
    L3_2 = "Fiona.Misc.Verification01"
    L4_2 = 0.5
    L5_2 = "Fiona.Misc.Verification02"
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
    L3_2 = nil
    L4_2 = MrxVoSequence
    L4_2 = L4_2.knPriorityBounties
    L1_2(L2_2, L3_2, L4_2)
    L1_2 = true
    _bPlayedVerificationVO = L1_2
  end
end

_PlayVerificationVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  A0_2._bNearVoInProgress = false
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 1
  L3_2[1] = L4_2
  L4_2 = _PlayVerificationVO
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

_NearVoComplete = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L3_2 = A0_2
  L2_2 = A0_2._GetTargetData
  L4_2 = A1_2
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    L3_2 = L2_2.vNearVoSequence
    if L3_2 then
      L3_2 = A0_2._bPlayedNearVO
      if not L3_2 then
        L3_2 = MrxVoSequence
        L3_2 = L3_2.Start
        L4_2 = L2_2.vNearVoSequence
        L5_2 = false
        L6_2 = MrxVoSequence
        L6_2 = L6_2.knPriorityBounties
        L3_2(L4_2, L5_2, L6_2)
        A0_2._bPlayedNearVO = true
      end
  end
  else
    L3_2 = MrxTaskJob
    L3_2 = L3_2._TargetNearby
    L4_2 = A0_2
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
  end
end

_TargetNearby = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  if A1_2 then
    L2_2 = A1_2.bPlayedVerificationVO
    if L2_2 then
      L2_2 = A1_2.bPlayedVerificationVO
      _bPlayedVerificationVO = L2_2
    end
  end
  L2_2 = MrxTaskJob
  L2_2 = L2_2.LoadAssets
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxTaskJob
  L1_2 = L1_2.SaveInstance
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = _bPlayedVerificationVO
  L1_2.bPlayedVerificationVO = L2_2
  return L1_2
end

SaveInstance = L0_1
