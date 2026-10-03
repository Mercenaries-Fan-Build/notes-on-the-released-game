local L0_1, L1_1
L0_1 = import
L1_1 = "MrxCheatBootstrap"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxLayerManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTask"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTaskState"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPlayState"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxRewardData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxStarterManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxState"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifMissionData"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifStarterData"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifHqData"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifPmcInterior"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUnlockFanfare"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxStatsManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifMissionFlow"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifRecommendationData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxHqManager"
L0_1(L1_1)
L0_1 = true
_bEnable = L0_1
L0_1 = 0
NETEVENT_SETGRAPPLE = L0_1
L0_1 = 1
NETEVENT_AUTOSAVE = L0_1
L0_1 = 2
NETEVENT_SETVEHICLEDISGUISE = L0_1

function L0_1(A0_2)
  local L1_2
  _bEnable = A0_2
end

EnableFlow = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = {}
  _tMyFlowData = L1_2
  L1_2 = {}
  _tActiveMissions = L1_2
  L1_2 = {}
  _tCulledBindings = L1_2
  L1_2 = nil
  _sTrackedMissionName = L1_2
  L1_2 = {}
  _tMissionsToRepeat = L1_2
  L1_2 = nil
  _fRefreshCallback = L1_2
  L1_2 = nil
  _tRefreshCallbackArgs = L1_2
  L1_2 = Pda
  L1_2 = L1_2.Map
  L2_2 = L1_2
  L1_2 = L1_2.SetMissionTrackCallback
  L3_2 = {}
  L4_2 = _TrackMission
  L3_2.fCallback = L4_2
  L1_2(L2_2, L3_2)
  if A0_2 then
    L1_2 = nil
    _bCheckpointSaveMode = L1_2
    L1_2 = nil
    _bCurrentlyRefreshing = L1_2
    L1_2 = nil
    _bCurrentlyRefreshing = L1_2
    L1_2 = true
    _bEnable = L1_2
    L1_2 = nil
    _bGrappleEnabled = L1_2
    L1_2 = nil
    _bVehicleDisguiseEnabled = L1_2
    L1_2 = nil
    _bResourceCountersEnabled = L1_2
    L1_2 = nil
    _bPersistentRetry = L1_2
    L1_2 = nil
    _bSkipToMissionReached = L1_2
    L1_2 = nil
    _nBlockingSequences = L1_2
    L1_2 = nil
    _oParent = L1_2
    L1_2 = nil
    _sLastCompletedContractName = L1_2
    L1_2 = {}
    _tDeferredKeyAwards = L1_2
    L1_2 = {}
    _tFlowData = L1_2
    L1_2 = {}
    _tRetryLocations = L1_2
  end
end

Reset = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = _sTrackedMissionName
  if A0_2 == L1_2 then
    return
  end
  L1_2 = nil
  if A0_2 then
    L2_2 = DisableAllJobTracking
    L2_2()
    L1_2 = A0_2
  else
    L1_2 = _sTrackedMissionName
  end
  if L1_2 then
    L2_2 = _tActiveMissions
    L2_2 = L2_2[L1_2]
    if L2_2 then
      L3_2 = L2_2.oMission
      oMission = L3_2
      L3_2 = oMission
      if L3_2 then
        L3_2 = oMission
        L4_2 = L3_2
        L3_2 = L3_2.EnableTracking
        L5_2 = A0_2 ~= nil
        L3_2(L4_2, L5_2)
      end
    end
  end
  _sTrackedMissionName = A0_2
end

_TrackMission = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = pairs
  L1_2 = _tActiveMissions
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = L4_2.oMission
    if L5_2 then
      L5_2 = L4_2.oMission
      L6_2 = L5_2
      L5_2 = L5_2.GetParent
      L5_2 = L5_2(L6_2)
      if L5_2 then
        L7_2 = L5_2
        L6_2 = L5_2.Cleanup
        L6_2(L7_2)
      end
    end
  end
end

CleanupAllActiveMissions = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  _tFlowData = A0_2
  L1_2 = 0
  L2_2 = pairs
  L3_2 = _tFlowData
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L1_2 = L1_2 + 1
  end
end

SetFlowData = L0_1

function L0_1(A0_2)
  local L1_2
  _oParent = A0_2
end

SetMissionParent = L0_1

function L0_1(A0_2)
  local L1_2
  _fPreContractSave = A0_2
end

SetPreContractSaveFunction = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2
  L3_2 = A0_2
  L4_2 = GetCaseSensitiveMissionId
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  A0_2 = L4_2
  if not A0_2 then
    L4_2 = false
    return L4_2
  end
  L3_2 = nil
  L4_2 = _oParent
  L5_2 = L4_2
  L4_2 = L4_2.GetChild
  L6_2 = A0_2
  L4_2 = L4_2(L5_2, L6_2)
  if L4_2 then
    L4_2 = false
    return L4_2
  end
  L4_2 = _tActiveMissions
  L4_2 = L4_2[A0_2]
  if L4_2 then
    L4_2 = false
    return L4_2
  end
  L4_2 = {}
  L5_2 = WifMissionData
  L5_2 = L5_2.tMissionData
  L5_2 = L5_2[A0_2]
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
    L6_2 = L7_2
  end
  L7_2 = L6_2.sStarter
  L8_2 = nil
  if L7_2 then
    L9_2 = WifStarterData
    L8_2 = L9_2[L7_2]
  end
  L9_2 = WifMissionData
  L9_2 = L9_2.GetMissionTitle
  L10_2 = A0_2
  L9_2 = L9_2(L10_2)
  L10_2 = MrxTask
  L11_2 = L10_2
  L10_2 = L10_2.Create
  L10_2 = L10_2(L11_2)
  L11_2 = MrxTask
  L12_2 = L11_2
  L11_2 = L11_2.Create
  L11_2 = L11_2(L12_2)
  L4_2.sName = A0_2
  L4_2.sModuleName = "MrxTask"
  L12_2 = _oParent
  L4_2.oParent = L12_2
  
  function L12_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
    L0_3 = WifMissionData
    L0_3 = L0_3.IsMissionAContract
    L1_3 = A0_2
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L1_3 = MrxPlayState
      L1_3 = L1_3.Set
      L2_3 = MrxPlayState
      L2_3 = L2_3._knFree
      L1_3(L2_3)
      L1_3 = WifMissionFlow
      L1_3 = L1_3.SetRetryLocations
      L2_3 = nil
      L1_3(L2_3)
    end
    L1_3 = L6_2
    L1_3 = L1_3.sStarter
    if L1_3 then
      L1_3 = MrxStarterManager
      L1_3 = L1_3.RequestStarter
      L2_3 = L6_2
      L2_3 = L2_3.sStarter
      L1_3 = L1_3(L2_3)
      if L1_3 then
        L3_3 = L1_3
        L2_3 = L1_3.RemoveBriefing
        L4_3 = A0_2
        L2_3(L3_3, L4_3)
      end
    end
    L1_3 = AwardKey
    L2_3 = A0_2
    L1_3(L2_3)
    L1_3 = GetKeyValue
    L2_3 = A0_2
    L1_3 = L1_3(L2_3)
    L2_3 = type
    L3_3 = L6_2
    L3_3 = L3_3.tMilestones
    L2_3 = L2_3(L3_3)
    if L2_3 == "table" then
      L2_3 = WifMissionData
      L2_3 = L2_3.IsMissionAJob
      L3_3 = A0_2
      L2_3 = L2_3(L3_3)
      if L2_3 then
        L2_3 = pairs
        L3_3 = L6_2
        L3_3 = L3_3.tMilestones
        L2_3, L3_3, L4_3 = L2_3(L3_3)
        for L5_3, L6_3 in L2_3, L3_3, L4_3 do
          L7_3 = HasKey
          L8_3 = L6_3.sKey
          L7_3 = L7_3(L8_3)
          if not L7_3 then
            L7_3 = AwardKey
            L8_3 = L6_3.sKey
            L7_3(L8_3)
          end
        end
      else
        L2_3 = pairs
        L3_3 = L6_2
        L3_3 = L3_3.tMilestones
        L2_3, L3_3, L4_3 = L2_3(L3_3)
        for L5_3, L6_3 in L2_3, L3_3, L4_3 do
          L7_3 = type
          L8_3 = L6_3.nMilestone
          L7_3 = L7_3(L8_3)
          if L7_3 == "number" then
            L7_3 = L6_3.nMilestone
            if L7_3 == L1_3 then
              L7_3 = AwardKey
              L8_3 = L6_3.sKey
              L7_3(L8_3)
            end
          end
        end
      end
    end
    if L0_3 then
      L2_3 = EnableAutosave
      L2_3()
    end
    L2_3 = Refresh
    L2_3()
    L2_3 = _tActiveMissions
    L3_3 = A0_2
    L2_3[L3_3] = nil
    L2_3 = Net
    L2_3 = L2_3.IsServer
    L2_3 = L2_3()
    if L2_3 then
      L2_3 = Net
      L2_3 = L2_3.SendEvent_RemovePDAMission
      L3_3 = WifMissionData
      L3_3 = L3_3.GetMissionIndexFromId
      L4_3 = A0_2
      L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3 = L3_3(L4_3)
      L2_3(L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3)
    end
    L2_3 = Pda
    L2_3 = L2_3.Map
    L3_3 = L2_3
    L2_3 = L2_3.RemoveMission
    L4_3 = {}
    L5_3 = A0_2
    L4_3.sName = L5_3
    L2_3(L3_3, L4_3)
    L2_3 = L6_2
    L2_3 = L2_3.bRepeatable
    if L2_3 then
      L2_3 = nil
      L3_3 = _tMissionsToRepeat
      L4_3 = A0_2
      L3_3 = L3_3[L4_3]
      if L3_3 then
        L3_3 = {}
        L4_3 = MrxTaskState
        L4_3 = L4_3._knActive
        L3_3.nState = L4_3
        L2_3 = L3_3
        L3_3 = _tMissionsToRepeat
        L4_3 = A0_2
        L3_3[L4_3] = nil
        L3_3 = MrxUtil
        L3_3 = L3_3.TeleportHeroesToLocations
        L4_3 = L6_2
        L4_3 = L4_3.tStartLocations
        L5_3 = UnlockMission
        L6_3 = {}
        L7_3 = A0_2
        L8_3 = L2_3
        L9_3 = false
        L6_3[1] = L7_3
        L6_3[2] = L8_3
        L6_3[3] = L9_3
        L3_3(L4_3, L5_3, L6_3)
      else
        L3_3 = UnlockMission
        L4_3 = A0_2
        L3_3(L4_3)
      end
    end
    L2_3 = SetLastCompletedContractName
    L3_3 = A0_2
    L2_3(L3_3)
  end
  
  L13_2 = {}
  L14_2 = {}
  L15_2 = L12_2
  L14_2[1] = L15_2
  L13_2[1] = L14_2
  L4_2.tOnComplete = L13_2
  
  function L13_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = WifMissionData
    L0_3 = L0_3.IsMissionAContract
    L1_3 = A0_2
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L1_3 = MrxPlayState
      L1_3 = L1_3.Set
      L2_3 = MrxPlayState
      L2_3 = L2_3._knFree
      L1_3(L2_3)
    end
    L1_3 = _tActiveMissions
    L2_3 = A0_2
    L1_3[L2_3] = nil
    L1_3 = L6_2
    L1_3 = L1_3.sStarter
    if L1_3 then
      L1_3 = UnlockMission
      L2_3 = A0_2
      L3_3 = nil
      L4_3 = false
      L1_3(L2_3, L3_3, L4_3)
    end
  end
  
  L14_2 = {}
  L15_2 = {}
  L16_2 = L13_2
  L15_2[1] = L16_2
  L14_2[1] = L15_2
  L4_2.tOnCancel = L14_2
  L15_2 = L10_2
  L14_2 = L10_2.Configure
  L16_2 = L4_2
  L14_2(L15_2, L16_2)
  L14_2 = false
  L15_2 = nil
  if L8_2 then
    L14_2 = true
    L16_2 = type
    L17_2 = A1_2
    L16_2 = L16_2(L17_2)
    L16_2 = L16_2 == "table"
    if not L16_2 then
      L17_2 = MrxTask
      L18_2 = L17_2
      L17_2 = L17_2.Create
      L17_2 = L17_2(L18_2)
      L15_2 = L17_2
    else
    end
  end
  L16_2 = MrxCheatBootstrap
  L16_2 = L16_2.IsSkipModeEnabled
  L16_2 = L16_2()
  L17_2 = MrxCheatBootstrap
  L17_2 = L17_2.GetMissionSkipData
  L17_2, L18_2 = L17_2()
  if L17_2 then
    L19_2 = GetCaseSensitiveMissionId
    L20_2 = L17_2
    L19_2 = L19_2(L20_2)
    L17_2 = L19_2
  end
  L19_2 = A0_2
  L20_2 = "Mission"
  L19_2 = L19_2 .. L20_2
  L6_2.sName = L19_2
  L19_2 = L6_2.sModuleName
  L6_2.sModuleName = L19_2
  L6_2.oParent = L10_2
  L19_2 = L6_2.tLayers
  if not L19_2 then
    L19_2 = {}
    L20_2 = "Vz_State_"
    L21_2 = A0_2
    L20_2 = L20_2 .. L21_2
    L19_2[1] = L20_2
  end
  L6_2.tLayers = L19_2
  L19_2 = MrxRewardData
  L19_2 = L19_2.GetRewards
  L20_2 = A0_2
  L19_2 = L19_2(L20_2)
  L6_2.tRewards = L19_2
  L19_2 = GetMissionStartLocations
  L20_2 = A0_2
  L19_2 = L19_2(L20_2)
  L6_2.tStartLocations = L19_2
  if L16_2 then
    L19_2 = WifMissionData
    L19_2 = L19_2.IsMissionAJob
    L20_2 = A0_2
    L19_2 = L19_2(L20_2)
    if L19_2 and L17_2 ~= A0_2 then
      L6_2.bSkipInitialNotifications = true
    end
  end
  if L15_2 then
    L6_2.oBriefing = L15_2
  end
  
  function L19_2()
    local L0_3, L1_3
    L0_3 = MrxState
    L0_3 = L0_3.Exit
    L1_3 = MrxState
    L1_3 = L1_3.STATE_WAITFORSTREAMING
    L0_3(L1_3)
    L0_3 = MrxState
    L0_3 = L0_3.Exit
    L1_3 = MrxState
    L1_3 = L1_3.STATE_WAITFORGAME
    L0_3(L1_3)
  end
  
  L6_2.fOnAssetsLoaded = L19_2
  
  function L20_2()
    local L0_3, L1_3
    L0_3 = L10_2
    L1_3 = L0_3
    L0_3 = L0_3.Complete
    L0_3(L1_3)
  end
  
  L21_2 = L6_2.tOnComplete
  if not L21_2 then
    L21_2 = {}
  end
  L6_2.tOnComplete = L21_2
  L21_2 = table
  L21_2 = L21_2.insert
  L22_2 = L6_2.tOnComplete
  L23_2 = {}
  L24_2 = L20_2
  L23_2[1] = L24_2
  L21_2(L22_2, L23_2)
  L21_2 = false
  L22_2 = L6_2.tRewards
  if L22_2 then
    L22_2 = L6_2.tRewards
    L22_2 = L22_2.nWager
    if not L22_2 then
      L22_2 = L6_2.tRewards
      L22_2 = L22_2.nWagerPercent
      if not L22_2 then
        goto lbl_188
      end
    end
    L21_2 = true
  end
  ::lbl_188::
  if L21_2 then
    function L22_2(A0_3, A1_3)
      local L2_3, L3_3, L4_3
      
      L2_3 = WifPmcInterior
      L2_3 = L2_3.SetEntranceLock
      L3_3 = false
      L2_3(L3_3)
      L2_3 = MrxHqManager
      L2_3 = L2_3.UnlockAllHq
      L2_3()
      L2_3 = WifPmcInterior
      L2_3 = L2_3.SetWagerStatus
      L3_3 = A0_3
      L4_3 = A1_3
      L2_3(L3_3, L4_3)
      L2_3 = WifPmcInterior
      L2_3 = L2_3.Enter
      L3_3 = true
      L2_3(L3_3)
    end
    
    L23_2 = L6_2.tOnCancel
    if not L23_2 then
      L23_2 = {}
    end
    L6_2.tOnCancel = L23_2
    L23_2 = table
    L23_2 = L23_2.insert
    L24_2 = L6_2.tOnCancel
    L25_2 = {}
    L26_2 = L22_2
    L27_2 = {}
    L28_2 = A0_2
    L29_2 = false
    L27_2[1] = L28_2
    L27_2[2] = L29_2
    L25_2[1] = L26_2
    L25_2[2] = L27_2
    L23_2(L24_2, L25_2)
    L23_2 = L6_2.tOnComplete
    if not L23_2 then
      L23_2 = {}
    end
    L6_2.tOnComplete = L23_2
    L23_2 = table
    L23_2 = L23_2.insert
    L24_2 = L6_2.tOnComplete
    L25_2 = {}
    L26_2 = L22_2
    L27_2 = {}
    L28_2 = A0_2
    L29_2 = true
    L27_2[1] = L28_2
    L27_2[2] = L29_2
    L25_2[1] = L26_2
    L25_2[2] = L27_2
    L23_2(L24_2, L25_2)
  end
  L23_2 = L11_2
  L22_2 = L11_2.Configure
  L24_2 = L6_2
  L22_2(L23_2, L24_2)
  
  function L22_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = L6_2
    L0_3 = L0_3.sStarter
    if L0_3 then
      L0_3 = MrxStarterManager
      L0_3 = L0_3.RequestStarter
      L1_3 = L6_2
      L1_3 = L1_3.sStarter
      L0_3 = L0_3(L1_3)
      if L0_3 then
        L2_3 = L0_3
        L1_3 = L0_3.AddBriefing
        L3_3 = A0_2
        L4_3 = L9_2
        L1_3(L2_3, L3_3, L4_3)
      end
    end
  end
  
  function L23_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = _fPreContractSave
    if L0_3 then
      L0_3 = _fPreContractSave
      L0_3()
    end
    L0_3 = L6_2
    L0_3 = L0_3.sStarter
    if L0_3 then
      L0_3 = MrxStarterManager
      L0_3 = L0_3.RequestStarter
      L1_3 = L6_2
      L1_3 = L1_3.sStarter
      L0_3 = L0_3(L1_3)
      if L0_3 then
        L2_3 = L0_3
        L1_3 = L0_3.SetMissionAccepted
        L3_3 = A0_2
        L4_3 = true
        L1_3(L2_3, L3_3, L4_3)
        L2_3 = L0_3
        L1_3 = L0_3.RemoveBriefing
        L3_3 = A0_2
        L1_3(L2_3, L3_3)
      end
    end
    L0_3 = L21_2
    if L0_3 then
      L0_3 = WifPmcInterior
      L0_3 = L0_3.SetEntranceLock
      L1_3 = true
      L0_3(L1_3)
      L0_3 = MrxHqManager
      L0_3 = L0_3.LockAllHq
      L0_3()
    end
    L0_3 = MrxState
    L0_3 = L0_3.Enter
    L1_3 = MrxState
    L1_3 = L1_3.STATE_WAITFORSTREAMING
    L2_3 = L11_2
    L2_3 = L2_3.Activate
    L3_3 = {}
    L4_3 = L11_2
    L5_3 = A1_2
    L3_3[1] = L4_3
    L3_3[2] = L5_3
    L0_3(L1_3, L2_3, L3_3)
  end
  
  if L16_2 and L17_2 then
    L24_2 = _bSkipToMissionReached
    if not L24_2 then
      L24_2 = true
      L25_2 = WifMissionData
      L25_2 = L25_2.GetIsCompleteable
      L26_2 = A0_2
      L25_2 = L25_2(L26_2)
      if L25_2 then
        L24_2 = true
      else
        L24_2 = false
      end
      if (A0_2 == "ChiCon003" or A0_2 == "AllCon003") and L17_2 ~= "PmcCon004" then
        L24_2 = false
      end
      if A0_2 == L17_2 then
        L25_2 = true
        _bSkipToMissionReached = L25_2
        L25_2 = _AttemptSkipModeExit
        L25_2()
        L14_2 = L18_2
      elseif L24_2 then
        L25_2 = WifMissionData
        L25_2 = L25_2.IsMissionOnCriticalPath
        L26_2 = A0_2
        L25_2 = L25_2(L26_2)
        if not L25_2 then
          L25_2 = WifMissionData
          L25_2 = L25_2.IsMissionAContract
          L26_2 = A0_2
          L25_2 = L25_2(L26_2)
          if not L25_2 then
            goto lbl_296
          end
          L25_2 = WifMissionData
          L25_2 = L25_2.GetMissionFaction
          L26_2 = A0_2
          L25_2 = L25_2(L26_2)
          L26_2 = WifMissionData
          L26_2 = L26_2.GetMissionFaction
          L27_2 = L17_2
          L26_2 = L26_2(L27_2)
          if L25_2 ~= L26_2 then
            goto lbl_296
          end
        end
        L26_2 = L10_2
        L25_2 = L10_2.Complete
        L25_2(L26_2)
        L25_2 = true
        return L25_2
      end
    end
  end
  ::lbl_296::
  L25_2 = L10_2
  L24_2 = L10_2.Activate
  L24_2(L25_2)
  L24_2 = AddPdaMissionDetails
  L25_2 = A0_2
  L24_2(L25_2)
  L24_2 = MrxUtil
  L24_2 = L24_2.SetDefault
  L25_2 = A2_2
  L26_2 = true
  L24_2 = L24_2(L25_2, L26_2)
  A2_2 = L24_2
  
  function L24_2()
    local L0_3, L1_3
    L0_3 = A2_2
    if L0_3 then
      L0_3 = _EndBlockingSequence
      L0_3()
    end
  end
  
  if A2_2 then
    L25_2 = _BeginBlockingSequence
    L25_2()
  end
  if L14_2 then
    if L15_2 then
      L25_2 = {}
      L25_2.sModuleName = "MrxTask"
      L26_2 = A0_2
      L27_2 = "Briefing"
      L26_2 = L26_2 .. L27_2
      L25_2.sName = L26_2
      L25_2.oParent = L10_2
      L25_2.sMissionName = A0_2
      L26_2 = L6_2.sFactionId
      L25_2.sFactionId = L26_2
      L25_2.fOnActivate = L24_2
      L25_2.fOnComplete = L23_2
      L26_2 = L8_2.sHqName
      if not L26_2 then
        L26_2 = L8_2.tLayers
        if L26_2 then
          L27_2 = L25_2.tLayers
          if not L27_2 then
            L27_2 = {}
          end
          L25_2.tLayers = L27_2
          L27_2 = ipairs
          L28_2 = L26_2
          L27_2, L28_2, L29_2 = L27_2(L28_2)
          for L30_2, L31_2 in L27_2, L28_2, L29_2 do
            L32_2 = table
            L32_2 = L32_2.insert
            L33_2 = L25_2.tLayers
            L34_2 = L31_2
            L32_2(L33_2, L34_2)
          end
          L26_2 = nil
        end
      end
      L27_2 = L15_2
      L26_2 = L15_2.Configure
      L28_2 = L25_2
      L26_2(L27_2, L28_2)
      L27_2 = L15_2
      L26_2 = L15_2.Activate
      L26_2(L27_2)
      L26_2 = L22_2
      L26_2()
    else
      L26_2 = L11_2
      L25_2 = L11_2.Configure
      L27_2 = {}
      L27_2.fOnActivate = L24_2
      L25_2(L26_2, L27_2)
      L25_2 = L22_2
      L25_2()
      L25_2 = L23_2
      L25_2()
    end
  else
    L26_2 = L11_2
    L25_2 = L11_2.Configure
    L27_2 = {}
    L27_2.fOnActivate = L24_2
    L25_2(L26_2, L27_2)
    L25_2 = L23_2
    L25_2()
  end
  L25_2 = _tActiveMissions
  L26_2 = {}
  L26_2.oMission = L11_2
  L25_2[A0_2] = L26_2
  L25_2 = true
  return L25_2
end

UnlockMission = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = _tActiveMissions
  L1_2[A0_2] = nil
  L1_2 = Pda
  L1_2 = L1_2.Map
  L2_2 = L1_2
  L1_2 = L1_2.RemoveMission
  L3_2 = {}
  L3_2.sName = A0_2
  L1_2(L2_2, L3_2)
  L1_2 = Net
  L1_2 = L1_2.IsServer
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = Net
    L1_2 = L1_2.SendEvent_RemovePDAMission
    L2_2 = WifMissionData
    L2_2 = L2_2.GetMissionIndexFromId
    L3_2 = A0_2
    L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
    L1_2(L2_2, L3_2, L4_2, L5_2)
  end
  L1_2 = WifMissionData
  L1_2 = L1_2.GetMissionStarter
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L2_2 = MrxStarterManager
    L2_2 = L2_2.RequestStarter
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L4_2 = L2_2
      L3_2 = L2_2.RemoveBriefing
      L5_2 = A0_2
      L3_2(L4_2, L5_2)
    end
  end
end

DestroyMission = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = GetCaseSensitiveMissionId
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  A0_2 = L1_2
  L1_2 = WifMissionData
  L1_2 = L1_2.tMissionData
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    L2_2 = nil
    return L2_2
  end
  L2_2 = L1_2.tStartLocations
  if L2_2 then
    L2_2 = L1_2.tStartLocations
    return L2_2
  end
  L2_2 = GetBriefingStartLocations
  L3_2 = A0_2
  return L2_2(L3_2)
end

GetMissionStartLocations = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = GetCaseSensitiveMissionId
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  A0_2 = L2_2
  L2_2 = WifMissionData
  L2_2 = L2_2.tMissionData
  L2_2 = L2_2[A0_2]
  if not L2_2 then
    return
  end
  L3_2 = L2_2.sStarter
  if not L3_2 then
    return
  end
  L4_2 = WifStarterData
  L4_2 = L4_2[L3_2]
  L5_2 = type
  L6_2 = L4_2
  L5_2 = L5_2(L6_2)
  if L5_2 ~= "table" then
    return
  end
  L5_2 = L4_2.sHqName
  if L5_2 then
    L5_2 = WifHqData
    L5_2 = L5_2.GetHqConfigFromId
    L6_2 = L4_2.sHqName
    L5_2 = L5_2(L6_2)
    if L5_2 then
      L6_2 = L5_2.tPortal
      if L6_2 then
        if A1_2 then
          L6_2 = L5_2.tPortal
          L6_2 = L6_2.sEntrance
          return L6_2
        else
          L6_2 = {}
          L7_2 = L5_2.tPortal
          L7_2 = L7_2.sStart1
          if not L7_2 then
            L7_2 = L5_2.tPortal
            L7_2 = L7_2.sStart
          end
          L8_2 = L5_2.tPortal
          L8_2 = L8_2.sStart2
          if not L8_2 then
            L8_2 = L5_2.tPortal
            L8_2 = L8_2.sStart
          end
          L6_2[1] = L7_2
          L6_2[2] = L8_2
          return L6_2
        end
      end
    end
  else
    L5_2 = L4_2.bPmcStarter
    if L5_2 then
      if A1_2 then
        L5_2 = "Starter_Pmc_Entrance"
        return L5_2
      else
        L5_2 = {}
        L6_2 = "Starter_Pmc_Start1"
        L7_2 = "Starter_Pmc_Start2"
        L5_2[1] = L6_2
        L5_2[2] = L7_2
        return L5_2
      end
    end
  end
end

GetBriefingStartLocations = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = WifMissionData
  L1_2 = L1_2.tMissionData
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L2_2 = L1_2.sStarter
    if L2_2 then
      L3_2 = WifStarterData
      L3_2 = L3_2[L2_2]
      if L3_2 then
        L4_2 = true
        return L4_2
      end
    end
  end
  L2_2 = false
  return L2_2
end

DoesMissionHaveABriefing = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = _bCurrentlyRefreshing
  if L2_2 then
    L2_2 = _tDeferredKeyAwards
    if not L2_2 then
      L2_2 = {}
    end
    _tDeferredKeyAwards = L2_2
    L2_2 = table
    L2_2 = L2_2.insert
    L3_2 = _tDeferredKeyAwards
    L4_2 = {}
    L5_2 = A0_2
    L6_2 = A1_2
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L2_2(L3_2, L4_2)
    return
  end
  if A1_2 == nil then
    L2_2 = type
    L3_2 = _tMyFlowData
    L3_2 = L3_2[A0_2]
    L2_2 = L2_2(L3_2)
    if L2_2 == "number" then
      L2_2 = _tMyFlowData
      L2_2 = L2_2[A0_2]
      A1_2 = L2_2 + 1
    else
      A1_2 = 1
    end
  end
  L2_2 = _tMyFlowData
  L2_2[A0_2] = A1_2
  L2_2 = MrxRewardData
  L2_2 = L2_2.GrantRewardKey
  L3_2 = A0_2
  L2_2(L3_2)
end

AwardKey = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = _tMyFlowData
  if L1_2 then
    L1_2 = _tMyFlowData
    L1_2[A0_2] = nil
  end
end

RemoveKey = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = _tMyFlowData
  if L1_2 then
    L1_2 = _tMyFlowData
    L1_2 = L1_2[A0_2]
    L1_2 = L1_2 ~= nil
    return L1_2
  end
  L1_2 = false
  return L1_2
end

HasKey = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = _tMyFlowData
  if L1_2 then
    L1_2 = _tMyFlowData
    L1_2 = L1_2[A0_2]
    if not L1_2 then
      L1_2 = 0
    end
    return L1_2
  end
  L1_2 = 0
  return L1_2
end

GetKeyValue = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L2_2 = _bEnable
  if L2_2 then
    L2_2 = _tFlowData
    if L2_2 then
      L2_2 = _bCurrentlyRefreshing
      if not L2_2 then
        goto lbl_11
      end
    end
  end
  do return end
  ::lbl_11::
  L2_2 = true
  _bCurrentlyRefreshing = L2_2
  if A0_2 then
    _fRefreshCallback = A0_2
    _tRefreshCallbackArgs = A1_2
  end
  L2_2 = _BeginBlockingSequence
  L2_2()
  L2_2 = 0
  L3_2 = pairs
  L4_2 = _tFlowData
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L2_2 = L2_2 + 1
  end
  L3_2 = false
  L4_2 = {}
  L5_2 = pairs
  L6_2 = _tFlowData
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = type
    L11_2 = L9_2.fPrereq
    L10_2 = L10_2(L11_2)
    if L10_2 == "function" then
      L10_2 = type
      L11_2 = L9_2.fConseq
      L10_2 = L10_2(L11_2)
      if L10_2 == "function" then
        L10_2 = L9_2.fPrereq
        L10_2 = L10_2()
        if L10_2 then
          L10_2 = L9_2.fConseq
          L10_2()
          L3_2 = true
          L10_2 = L9_2.bRecurring
          if not L10_2 then
            L10_2 = table
            L10_2 = L10_2.insert
            L11_2 = _tCulledBindings
            L12_2 = L8_2
            L10_2(L11_2, L12_2)
          else
            L4_2[L8_2] = L9_2
          end
      end
    end
    else
      L4_2[L8_2] = L9_2
    end
  end
  _tFlowData = L4_2
  L5_2 = nil
  _bCurrentlyRefreshing = L5_2
  L5_2 = _tDeferredKeyAwards
  if L5_2 then
    L5_2 = ipairs
    L6_2 = _tDeferredKeyAwards
    L5_2, L6_2, L7_2 = L5_2(L6_2)
    for L8_2, L9_2 in L5_2, L6_2, L7_2 do
      L10_2 = L9_2[1]
      L11_2 = L9_2[2]
      L12_2 = AwardKey
      L13_2 = L10_2
      L14_2 = L11_2
      L12_2(L13_2, L14_2)
    end
    L5_2 = nil
    _tDeferredKeyAwards = L5_2
  end
  if L3_2 then
    L5_2 = Refresh
    L5_2()
  else
  end
  L5_2 = _EndBlockingSequence
  L5_2()
end

Refresh = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = _tMissionsToRepeat
  L1_2[A0_2] = true
end

SetMissionToRepeat = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = DisableAllJobTracking
  L2_2()
  L2_2 = nil
  L3_2 = ipairs
  L4_2 = A0_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = WifMissionData
    L8_2 = L8_2.IsMissionAContract
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    if L8_2 then
      L2_2 = L7_2
    end
  end
  L3_2 = MrxPlayState
  L3_2 = L3_2.IsFree
  L3_2 = L3_2()
  if L3_2 then
    L3_2 = L2_2 or L3_2
    if not L2_2 then
      L3_2 = A1_2
    end
    if L3_2 then
      _sTrackedMissionName = L3_2
    end
  end
  L3_2 = ipairs
  L4_2 = A0_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = _oParent
    L9_2 = L8_2
    L8_2 = L8_2.GetChild
    L10_2 = L7_2
    L8_2 = L8_2(L9_2, L10_2)
    L10_2 = L8_2
    L9_2 = L8_2.GetChild
    L11_2 = L7_2
    L12_2 = "Briefing"
    L11_2 = L11_2 .. L12_2
    L9_2 = L9_2(L10_2, L11_2)
    L11_2 = L9_2
    L10_2 = L9_2.Complete
    L10_2(L11_2)
  end
end

AcceptMissions = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = pairs
  L1_2 = _tActiveMissions
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = L4_2.oMission
    if L5_2 then
      L7_2 = L5_2
      L6_2 = L5_2.IsActive
      L6_2 = L6_2(L7_2)
      if L6_2 then
        L6_2 = L5_2.IsJob
        L6_2 = L6_2()
        if L6_2 then
          L7_2 = L5_2
          L6_2 = L5_2.EnableTracking
          L8_2 = false
          L6_2(L7_2, L8_2)
        end
      end
    end
  end
end

DisableAllJobTracking = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = {}
  L1_2 = pairs
  L2_2 = _tActiveMissions
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L5_2.oMission
    L7_2 = L6_2
    L6_2 = L6_2.SaveInstance
    L6_2 = L6_2(L7_2)
    L0_2[L4_2] = L6_2
  end
  L1_2 = {}
  L2_2 = _tMyFlowData
  L1_2.tMyFlowData = L2_2
  L1_2.tActiveMissions = L0_2
  L2_2 = _tCulledBindings
  L1_2.tCulledBindings = L2_2
  return L1_2
end

SaveSingleton = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 == "table" then
    L1_2 = A0_2.tMyFlowData
    _tMyFlowData = L1_2
    L1_2 = 0
    L2_2 = pairs
    L3_2 = A0_2.tCulledBindings
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2, L6_2 in L2_2, L3_2, L4_2 do
      L7_2 = _tFlowData
      L7_2 = L7_2[L6_2]
      if L7_2 then
        L7_2 = _tFlowData
        L7_2 = L7_2[L6_2]
        L7_2.bToBeCulled = true
        L1_2 = L1_2 + 1
      end
    end
    if 0 < L1_2 then
      L2_2 = {}
      L3_2 = pairs
      L4_2 = _tFlowData
      L3_2, L4_2, L5_2 = L3_2(L4_2)
      for L6_2, L7_2 in L3_2, L4_2, L5_2 do
        L8_2 = L7_2.bToBeCulled
        if not L8_2 then
          L2_2[L6_2] = L7_2
        else
          L8_2 = table
          L8_2 = L8_2.insert
          L9_2 = _tCulledBindings
          L10_2 = L6_2
          L8_2(L9_2, L10_2)
        end
      end
      _tFlowData = L2_2
    end
    L2_2 = pairs
    L3_2 = A0_2.tActiveMissions
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2, L6_2 in L2_2, L3_2, L4_2 do
      L7_2 = UnlockMission
      L8_2 = L5_2
      L9_2 = L6_2
      L10_2 = false
      L7_2(L8_2, L9_2, L10_2)
    end
  end
end

LoadSingleton = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = pairs
  L2_2 = WifMissionData
  L2_2 = L2_2.tMissionData
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2 in L1_2, L2_2, L3_2 do
    L5_2 = string
    L5_2 = L5_2.lower
    L6_2 = A0_2
    L5_2 = L5_2(L6_2)
    L6_2 = string
    L6_2 = L6_2.lower
    L7_2 = L4_2
    L6_2 = L6_2(L7_2)
    if L5_2 == L6_2 then
      return L4_2
    end
  end
end

GetCaseSensitiveMissionId = L0_1

function L0_1(A0_2)
  local L1_2
  _sLastCompletedContractName = A0_2
end

SetLastCompletedContractName = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _sLastCompletedContractName
  return L0_2
end

GetLastCompletedContractName = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = true
  _bDoMissionAutosave = L0_2
end

EnableAutosave = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _bCheckpointSaveMode
  return L0_2
end

IsCheckpointSaveModeEnabled = L0_1

function L0_1(A0_2)
  local L1_2
  _bCheckpointSaveMode = A0_2
end

EnableCheckpointSaveMode = L0_1

function L0_1(A0_2)
  local L1_2
  _tRetryLocations = A0_2
end

SetRetryLocations = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _tRetryLocations
  return L0_2
end

GetRetryLocations = L0_1

function L0_1(A0_2)
  local L1_2
  _tPersistentRetryLocations = A0_2
end

SetPersistentRetryLocations = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _tPersistentRetryLocations
  return L0_2
end

GetPersistentRetryLocations = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Net
  L1_2 = L1_2.IsServer
  L1_2 = L1_2()
  if L1_2 then
    if A0_2 == false then
      L1_2 = 0
      SetGrapple = L1_2
    elseif A0_2 == true then
      L1_2 = 1
      SetGrapple = L1_2
    end
    L1_2 = Net
    L1_2 = L1_2.SendCustomEvent
    L2_2 = "MrxMissionFlow"
    L3_2 = NETEVENT_SETGRAPPLE
    L4_2 = {}
    L5_2 = SetGrapple
    L4_2[1] = L5_2
    L5_2 = true
    L1_2(L2_2, L3_2, L4_2, L5_2)
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = _evSetGrapple
    L1_2(L2_2)
    L1_2 = nil
    _evSetGrapple = L1_2
    L1_2 = Event
    L1_2 = L1_2.CreatePersistent
    L2_2 = Event
    L2_2 = L2_2.ScriptEvent
    L3_2 = {}
    L4_2 = "mpPlayerJoin"
    
    function L5_2(A0_3)
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
    
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L4_2 = Net
    L4_2 = L4_2.SendCustomEvent
    L5_2 = {}
    L6_2 = "MrxMissionFlow"
    L7_2 = NETEVENT_SETGRAPPLE
    L8_2 = {}
    L9_2 = SetGrapple
    L8_2[1] = L9_2
    L9_2 = true
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L5_2[4] = L9_2
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
    _evSetGrapple = L1_2
  end
  L1_2 = Player
  L1_2 = L1_2.GetAllPlayers
  L1_2 = L1_2()
  L2_2 = ipairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = Player
    L7_2 = L7_2.SetGrappleEnabled
    L8_2 = L6_2
    L9_2 = A0_2
    L7_2(L8_2, L9_2)
  end
  _bGrappleEnabled = A0_2
end

SetGrappleEnabled = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Net
  L1_2 = L1_2.IsServer
  L1_2 = L1_2()
  if L1_2 then
    if A0_2 == false then
      L1_2 = 0
      SetVehicleDisguise = L1_2
    elseif A0_2 == true then
      L1_2 = 1
      SetVehicleDisguise = L1_2
    end
    L1_2 = Net
    L1_2 = L1_2.SendCustomEvent
    L2_2 = "MrxMissionFlow"
    L3_2 = NETEVENT_SETVEHICLEDISGUISE
    L4_2 = {}
    L5_2 = SetVehicleDisguise
    L4_2[1] = L5_2
    L5_2 = true
    L1_2(L2_2, L3_2, L4_2, L5_2)
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = _evSetVehicleDisguise
    L1_2(L2_2)
    L1_2 = nil
    _evSetVehicleDisguise = L1_2
    L1_2 = Event
    L1_2 = L1_2.CreatePersistent
    L2_2 = Event
    L2_2 = L2_2.ScriptEvent
    L3_2 = {}
    L4_2 = "mpPlayerJoin"
    
    function L5_2(A0_3)
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
    
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L4_2 = Net
    L4_2 = L4_2.SendCustomEvent
    L5_2 = {}
    L6_2 = "MrxMissionFlow"
    L7_2 = NETEVENT_SETVEHICLEDISGUISE
    L8_2 = {}
    L9_2 = SetVehicleDisguise
    L8_2[1] = L9_2
    L9_2 = true
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L5_2[4] = L9_2
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
    _evSetVehicleDisguise = L1_2
  end
  L1_2 = Player
  L1_2 = L1_2.SetVehicleDisguise
  L2_2 = A0_2
  L1_2(L2_2)
  _bVehicleDisguiseEnabled = A0_2
end

SetVehicleDisguiseEnabled = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = NETEVENT_SETGRAPPLE
  if A0_2 == L2_2 then
    L2_2 = A1_2[1]
    if L2_2 == 0 then
      L2_2 = SetGrappleEnabled
      L3_2 = false
      L2_2(L3_2)
  end
  else
    L2_2 = NETEVENT_SETGRAPPLE
    if A0_2 == L2_2 then
      L2_2 = A1_2[1]
      if L2_2 == 1 then
        L2_2 = SetGrappleEnabled
        L3_2 = true
        L2_2(L3_2)
    end
    else
      L2_2 = NETEVENT_AUTOSAVE
      if A0_2 == L2_2 then
        L2_2 = Autosave
        L2_2()
      else
        L2_2 = NETEVENT_SETVEHICLEDISGUISE
        if A0_2 == L2_2 then
          L2_2 = A1_2[1]
          if L2_2 == 0 then
            L2_2 = SetVehicleDisguiseEnabled
            L3_2 = false
            L2_2(L3_2)
        end
        else
          L2_2 = NETEVENT_SETVEHICLEDISGUISE
          if A0_2 == L2_2 then
            L2_2 = A1_2[1]
            if L2_2 == 1 then
              L2_2 = SetVehicleDisguiseEnabled
              L3_2 = true
              L2_2(L3_2)
            end
          end
        end
      end
    end
  end
end

NetEventCallback = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = MrxPlayState
  L0_2 = L0_2.Get
  L0_2 = L0_2()
  L1_2 = MrxPlayState
  L1_2 = L1_2._knMission
  L0_2 = L0_2 == L1_2
  L1_2 = WifMissionFlow
  L1_2 = L1_2.GetLastCompletedContractName
  L1_2 = L1_2()
  if not L1_2 then
    L1_2 = "none"
  end
  L2_2 = MrxPlayState
  L2_2 = L2_2.GetTotalTimeElapsed
  L2_2 = L2_2()
  L3_2 = MrxPlayState
  L3_2 = L3_2.GetCurrentMission
  L3_2 = L3_2()
  if L3_2 then
    L5_2 = L3_2
    L4_2 = L3_2.IsActive
    L4_2 = L4_2(L5_2)
    if L4_2 then
      L5_2 = L3_2
      L4_2 = L3_2.GetMissionId
      L4_2 = L4_2(L5_2)
      if L4_2 then
        L5_2 = MrxRewardData
        L5_2 = L5_2.GetRewards
        L6_2 = L4_2
        L5_2 = L5_2(L6_2)
        if L5_2 then
          L6_2 = MrxRewardData
          L6_2 = L6_2.GetWagerData
          L7_2 = L5_2
          L6_2 = L6_2(L7_2)
          if L6_2 then
            return
          end
        end
      end
    end
  end
  L4_2 = Sys
  L4_2 = L4_2.RequestAutosave
  L5_2 = L0_2
  L6_2 = L1_2
  L7_2 = L2_2
  L8_2 = MrxStatsManager
  L8_2 = L8_2.GetPercentCompleted
  L8_2 = L8_2()
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = Pg
  L4_2 = L4_2.SaveGame
  L5_2 = "autosave"
  L4_2(L5_2)
end

Autosave = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _bGrappleEnabled
  return L0_2
end

IsGrappleEnabled = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _bVehicleDisguiseEnabled
  return L0_2
end

IsVehicleDisguiseEnabled = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Hud
  L1_2 = L1_2.ResourceCounter
  L2_2 = L1_2
  L1_2 = L1_2.SetSuppressed
  L3_2 = {}
  L4_2 = not A0_2
  L3_2.bSuppressCash = L4_2
  L4_2 = not A0_2
  L3_2.bSuppressFuel = L4_2
  L1_2(L2_2, L3_2)
  _bResourceCountersEnabled = A0_2
end

EnableResourceCounters = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _bResourceCountersEnabled
  return L0_2
end

AreResourceCountersEnabled = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L0_2 = {}
  L1_2 = 1
  L2_2 = pairs
  L3_2 = WifMissionData
  L3_2 = L3_2.tMissionData
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = "incomplete"
    L8_2 = HasKey
    L9_2 = L5_2
    L8_2 = L8_2(L9_2)
    if L8_2 then
      L7_2 = "complete"
    end
    L8_2 = {}
    L9_2 = L5_2
    L10_2 = L7_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L0_2[L1_2] = L8_2
    L1_2 = L1_2 + 1
  end
  L2_2 = MrxPlayState
  L2_2 = L2_2.GetCurrentMission
  L2_2 = L2_2()
  if L2_2 then
    L4_2 = L2_2
    L3_2 = L2_2.IsActive
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L4_2 = L2_2
      L3_2 = L2_2.GetMissionId
      L3_2 = L3_2(L4_2)
      L4_2 = {}
      L5_2 = L3_2
      L6_2 = "active"
      L4_2[1] = L5_2
      L4_2[2] = L6_2
      L0_2[L1_2] = L4_2
      L1_2 = L1_2 + 1
    end
  end
  return L0_2
end

GetMissionStates = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _nBlockingSequences
  if not L0_2 then
    L0_2 = 0
  end
  _nBlockingSequences = L0_2
  L0_2 = _nBlockingSequences
  L0_2 = L0_2 + 1
  _nBlockingSequences = L0_2
end

_BeginBlockingSequence = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = type
  L1_2 = _nBlockingSequences
  L0_2 = L0_2(L1_2)
  if L0_2 == "number" then
    L0_2 = _nBlockingSequences
    if 1 <= L0_2 then
      L0_2 = _nBlockingSequences
      L0_2 = L0_2 - 1
      _nBlockingSequences = L0_2
      L0_2 = _nBlockingSequences
      if L0_2 == 0 then
        L0_2 = MrxCheatBootstrap
        L0_2 = L0_2.IsSkipModeEnabled
        L0_2 = L0_2()
        if L0_2 then
          L0_2 = _AttemptSkipModeExit
          L0_2()
        else
          L0_2 = Sys
          L0_2 = L0_2.RequestAutosave
          if L0_2 then
            L0_2 = _bDoMissionAutosave
            if L0_2 then
              L0_2 = nil
              _bDoMissionAutosave = L0_2
              L0_2 = Autosave
              L0_2()
              L0_2 = Net
              L0_2 = L0_2.SendCustomEvent
              L1_2 = "MrxMissionFlow"
              L2_2 = NETEVENT_AUTOSAVE
              L3_2 = {}
              L0_2(L1_2, L2_2, L3_2)
            end
          end
          L0_2 = _RefreshComplete
          L0_2()
        end
      end
    end
  end
end

_EndBlockingSequence = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _bSkipToMissionReached
  if L0_2 then
    L0_2 = _nBlockingSequences
    if L0_2 == 0 then
      L0_2 = MrxCheatBootstrap
      L0_2 = L0_2.EnableSkipMode
      L1_2 = false
      L0_2(L1_2)
      L0_2 = nil
      _bSkipToMissionReached = L0_2
      L0_2 = MrxLayerManager
      L0_2 = L0_2.ProcessMarkedLayers
      L1_2 = _RefreshComplete
      L0_2(L1_2)
    end
  end
end

_AttemptSkipModeExit = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = _fRefreshCallback
  if L0_2 then
    L0_2 = MrxUtil
    L0_2 = L0_2.CallWithOptionalArgs
    L1_2 = _fRefreshCallback
    L2_2 = _tRefreshCallbackArgs
    L0_2(L1_2, L2_2)
    L0_2 = nil
    _fRefreshCallback = L0_2
    L0_2 = nil
    _tRefreshCallbackArgs = L0_2
  else
  end
end

_RefreshComplete = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L4_2 = type
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if L4_2 ~= "string" then
    L4_2 = WifMissionData
    L4_2 = L4_2.GetMissionIdFromIndex
    L5_2 = A0_2
    L4_2 = L4_2(L5_2)
    A0_2 = L4_2
  end
  L4_2 = WifMissionData
  L4_2 = L4_2.IsMissionSuppressedInPda
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if L4_2 then
    return
  end
  L4_2 = Net
  L4_2 = L4_2.IsClient
  L4_2 = L4_2()
  if L4_2 and A3_2 then
    L4_2 = _tMyFlowData
    if not L4_2 then
      L4_2 = {}
      _tMyFlowData = L4_2
    end
    L4_2 = _tMyFlowData
    L4_2[A0_2] = A3_2
  end
  L4_2 = BuildMissionHeader
  L5_2 = A0_2
  L6_2 = A1_2
  L4_2 = L4_2(L5_2, L6_2)
  L5_2 = BuildMissionDescription
  L6_2 = A0_2
  L7_2 = false
  L8_2 = true
  L9_2 = A1_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = WifMissionData
  L6_2 = L6_2.GetMissionFaction
  L7_2 = A0_2
  L6_2 = L6_2(L7_2)
  L7_2 = MrxFactionManager
  L7_2 = L7_2.GetPdaFactionIdFromFactionId
  L8_2 = L6_2
  L7_2 = L7_2(L8_2)
  if not L7_2 then
    L7_2 = "VZ"
  end
  L8_2 = WifMissionData
  L8_2 = L8_2.GetMissionPdaTexture
  L9_2 = A0_2
  L8_2 = L8_2(L9_2)
  if not L8_2 then
    L9_2 = {}
    L9_2.Pmc = "icon_pmc_mc"
    L9_2.All = "icon_an_mc"
    L9_2.Chi = "icon_ch_mc"
    L9_2.Gur = "icon_gr_mc"
    L9_2.Oil = "icon_oc_mc"
    L9_2.Pir = "icon_pr_mc"
    L9_2.Vza = "icon_vz_mc"
    L8_2 = L9_2[L6_2]
  end
  L9_2 = WifMissionData
  L9_2 = L9_2.IsMissionAContract
  L10_2 = A0_2
  L9_2 = L9_2(L10_2)
  L10_2 = Net
  L10_2 = L10_2.IsServer
  L10_2 = L10_2()
  if L10_2 then
    L10_2 = Pda
    L10_2 = L10_2.Map
    L11_2 = L10_2
    L10_2 = L10_2.GetSelectedMission
    L10_2 = L10_2(L11_2)
    A2_2 = L10_2 == A0_2
  end
  L10_2 = WifMissionData
  L10_2 = L10_2.GetPdaSortOrder
  L11_2 = A0_2
  L10_2 = L10_2(L11_2)
  if not L10_2 and L9_2 then
    L11_2 = WifMissionData
    L11_2 = L11_2.IsMissionOnCriticalPath
    L12_2 = A0_2
    L11_2 = L11_2(L12_2)
    if A2_2 then
      L12_2 = WifMissionData
      L10_2 = L12_2.knPdaSortOrderActiveContract
    elseif L11_2 then
      L12_2 = WifMissionData
      L10_2 = L12_2.knPdaSortOrderCritPathContract
    else
      L12_2 = WifMissionData
      L10_2 = L12_2.knPdaSortOrderContract
    end
  end
  L11_2 = Pda
  L11_2 = L11_2.Map
  L12_2 = L11_2
  L11_2 = L11_2.AddMission
  L13_2 = {}
  L13_2.sName = A0_2
  L13_2.sLabel = L4_2
  L13_2.sDesc = L5_2
  L13_2.sFaction = L7_2
  L13_2.sDefaultBlipTexture = L8_2
  L13_2.sDefaultBlipLabel = "Default Mission Blip description"
  L13_2.bTrackable = false
  L13_2.nSortOrder = L10_2
  L11_2(L12_2, L13_2)
  if L9_2 then
    L11_2 = nil
    L12_2 = GetBriefingStartLocations
    L13_2 = A0_2
    L14_2 = true
    L12_2 = L12_2(L13_2, L14_2)
    if L12_2 then
      L13_2 = Pg
      L13_2 = L13_2.GetGuidByName
      L14_2 = L12_2
      L13_2 = L13_2(L14_2)
      L11_2 = L13_2
    end
    if L11_2 and not A2_2 then
      L13_2 = Pda
      L13_2 = L13_2.Map
      L14_2 = L13_2
      L13_2 = L13_2.AddBlip
      L15_2 = {}
      L15_2.sMission = A0_2
      L16_2 = A0_2
      L17_2 = "_PreMission"
      L16_2 = L16_2 .. L17_2
      L15_2.sName = L16_2
      L15_2.uGuid = L11_2
      L15_2.sTexture = ""
      L15_2.nSortOrder = 5
      L13_2(L14_2, L15_2)
    else
      L13_2 = Pda
      L13_2 = L13_2.Map
      L14_2 = L13_2
      L13_2 = L13_2.RemoveBlip
      L15_2 = {}
      L16_2 = A0_2
      L17_2 = "_PreMission"
      L16_2 = L16_2 .. L17_2
      L15_2.sName = L16_2
      L13_2(L14_2, L15_2)
    end
  end
  L11_2 = Net
  L11_2 = L11_2.IsServer
  L11_2 = L11_2()
  if L11_2 then
    if not A1_2 then
      L11_2 = {}
      A1_2 = L11_2
    end
    L11_2 = WifMissionData
    L11_2 = L11_2.GetMissionRepeatable
    L12_2 = A0_2
    L11_2 = L11_2(L12_2)
    if L11_2 then
      L11_2 = GetKeyValue
      L12_2 = A0_2
      L11_2 = L11_2(L12_2)
      L12_2 = Net
      L12_2 = L12_2.SendEvent_AddPDAMission
      L13_2 = WifMissionData
      L13_2 = L13_2.GetMissionIndexFromId
      L14_2 = A0_2
      L13_2 = L13_2(L14_2)
      L14_2 = A1_2
      L15_2 = A2_2
      L16_2 = L11_2
      L12_2(L13_2, L14_2, L15_2, L16_2)
    else
      L11_2 = Net
      L11_2 = L11_2.SendEvent_AddPDAMission
      L12_2 = WifMissionData
      L12_2 = L12_2.GetMissionIndexFromId
      L13_2 = A0_2
      L12_2 = L12_2(L13_2)
      L13_2 = A1_2
      L14_2 = A2_2
      L11_2(L12_2, L13_2, L14_2)
    end
  end
  L11_2 = Net
  L11_2 = L11_2.IsClient
  L11_2 = L11_2()
  if L11_2 and A2_2 then
    L11_2 = Pda
    L11_2 = L11_2.Map
    L12_2 = L11_2
    L11_2 = L11_2.SetSelectedMission
    L13_2 = {}
    L13_2.sName = A0_2
    L11_2(L12_2, L13_2)
  end
end

AddPdaMissionDetails = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = WifMissionData
  L3_2 = L3_2.IsMissionAContract
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L3_2 = "\""
    L4_2 = WifMissionData
    L4_2 = L4_2.GetMissionTitle
    L5_2 = A0_2
    L4_2 = L4_2(L5_2)
    L5_2 = "\""
    L2_2 = L3_2 .. L4_2 .. L5_2
    L3_2 = WifMissionData
    L3_2 = L3_2.GetMissionRepeatable
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L3_2 = GetKeyValue
      L4_2 = A0_2
      L3_2 = L3_2(L4_2)
      L3_2 = L3_2 + 1
      L4_2 = WifMissionData
      L4_2 = L4_2.GetMissionLevels
      L5_2 = A0_2
      L4_2 = L4_2(L5_2)
      if L3_2 > L4_2 then
        L3_2 = L4_2
      end
      L5_2 = L2_2
      L6_2 = " ([Generic.Level] "
      L7_2 = L3_2
      L8_2 = ")"
      L2_2 = L5_2 .. L6_2 .. L7_2 .. L8_2
    end
  else
    if A1_2 then
      L3_2 = #A1_2
      if L3_2 ~= 0 then
        L3_2 = A1_2[1]
        L2_2 = L3_2[1]
    end
    else
      L3_2 = "\""
      L4_2 = WifMissionData
      L4_2 = L4_2.GetMissionTitle
      L5_2 = A0_2
      L4_2 = L4_2(L5_2)
      L5_2 = "\""
      L2_2 = L3_2 .. L4_2 .. L5_2
    end
  end
  return L2_2
end

BuildMissionHeader = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L4_2 = ""
  if A1_2 then
    L5_2 = L4_2
    L6_2 = BuildMissionHeader
    L7_2 = A0_2
    L6_2 = L6_2(L7_2)
    L7_2 = [[


]]
    L4_2 = L5_2 .. L6_2 .. L7_2
  end
  L5_2 = WifMissionData
  L5_2 = L5_2.GetMissionFaction
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  L6_2 = MrxFactionManager
  L6_2 = L6_2.GetShortPlayerVisibleName
  L7_2 = L5_2
  L6_2 = L6_2(L7_2)
  L7_2 = MrxFactionManager
  L7_2 = L7_2.GetInlineIcon
  L8_2 = L5_2
  L7_2 = L7_2(L8_2)
  if L6_2 and L7_2 then
    L8_2 = L4_2
    L9_2 = "[Briefing.Faction]: "
    L10_2 = L7_2
    L11_2 = " "
    L12_2 = L6_2
    L13_2 = [[


]]
    L4_2 = L8_2 .. L9_2 .. L10_2 .. L11_2 .. L12_2 .. L13_2
  end
  L8_2 = L4_2
  L9_2 = "["
  L10_2 = A0_2
  L11_2 = ".Terms.Summary]\n"
  L4_2 = L8_2 .. L9_2 .. L10_2 .. L11_2
  if A3_2 then
    L8_2 = #A3_2
    if 0 < L8_2 then
      L8_2 = WifMissionData
      L8_2 = L8_2.IsMissionAContract
      L9_2 = A0_2
      L8_2 = L8_2(L9_2)
      if L8_2 then
        L8_2 = L4_2
        L9_2 = [[

[PDA.Map.ObjectiveListHeader]
]]
        L4_2 = L8_2 .. L9_2
        L8_2 = pairs
        L9_2 = A3_2
        L8_2, L9_2, L10_2 = L8_2(L9_2)
        for L11_2, L12_2 in L8_2, L9_2, L10_2 do
          L13_2 = L12_2[1]
          L14_2 = L12_2[2]
          if not L14_2 then
            L14_2 = ""
          end
          L15_2 = Net
          L15_2 = L15_2.IsClient
          L15_2 = L15_2()
          if L15_2 then
            L15_2 = type
            L16_2 = L12_2[2]
            L15_2 = L15_2(L16_2)
            if L15_2 ~= "string" then
              L15_2 = MrxUtil
              L15_2 = L15_2.GetInlineIconNameByIndex
              L16_2 = L12_2[2]
              L15_2 = L15_2(L16_2)
              L14_2 = L15_2
            end
          end
          L15_2 = L4_2
          L16_2 = L14_2
          L17_2 = " "
          L18_2 = L13_2
          L19_2 = "\n"
          L4_2 = L15_2 .. L16_2 .. L17_2 .. L18_2 .. L19_2
        end
      end
    end
  end
  if A2_2 then
    L8_2 = WifRecommendationData
    L8_2 = L8_2.GenerateRecommendationString
    L9_2 = A0_2
    L8_2 = L8_2(L9_2)
    if L8_2 then
      L9_2 = L4_2
      L10_2 = [[

[PDA.Map.RecommendationsHeader]
]]
      L11_2 = L8_2
      L4_2 = L9_2 .. L10_2 .. L11_2
    end
  end
  L8_2 = MrxRewardData
  L8_2 = L8_2.GetRewards
  L9_2 = A0_2
  L8_2 = L8_2(L9_2)
  if L8_2 then
    L9_2 = MrxRewardData
    L9_2 = L9_2.GetWagerData
    L10_2 = L8_2
    L9_2 = L9_2(L10_2)
    if L9_2 then
      L10_2 = MrxUtil
      L10_2 = L10_2.FormatMoney
      L11_2 = L8_2.nWagered
      if not L11_2 then
        L11_2 = L9_2.nDefaultWager
      end
      L10_2 = L10_2(L11_2)
      L11_2 = L4_2
      L12_2 = [[

[Briefing.WagerPrefix] ]]
      L13_2 = L10_2
      L14_2 = "\n"
      L4_2 = L11_2 .. L12_2 .. L13_2 .. L14_2
    end
  end
  L9_2 = MrxRewardData
  L9_2 = L9_2.GenerateRewardString
  L10_2 = A0_2
  L9_2 = L9_2(L10_2)
  if L9_2 then
    L10_2 = L4_2
    L11_2 = [[

[Generic.Rewards]:
]]
    L12_2 = L9_2
    L4_2 = L10_2 .. L11_2 .. L12_2
  end
  return L4_2
end

BuildMissionDescription = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = Net
  L0_2 = L0_2.IsClient
  L0_2 = L0_2()
  if L0_2 then
    return
  end
  L0_2 = pairs
  L1_2 = _tActiveMissions
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = L4_2.oMission
    L7_2 = L5_2
    L6_2 = L5_2.IsActive
    L6_2 = L6_2(L7_2)
    if L6_2 then
      L6_2 = L5_2.RefreshPdaDisplay
      if not L6_2 then
      else
        L7_2 = L5_2
        L6_2 = L5_2.RefreshPdaDisplay
        L6_2(L7_2)
      end
    else
      L6_2 = AddPdaMissionDetails
      L7_2 = L3_2
      L6_2(L7_2)
    end
  end
end

RefreshAllPdaMissionDetails = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 ~= "string" then
    L1_2 = WifMissionData
    L1_2 = L1_2.GetMissionIdFromIndex
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    A0_2 = L1_2
  end
  L1_2 = Pda
  L1_2 = L1_2.Map
  L2_2 = L1_2
  L1_2 = L1_2.RemoveMission
  L3_2 = {}
  L3_2.sName = A0_2
  L1_2(L2_2, L3_2)
end

RemovePDAMission = L0_1
