local L0_1, L1_1, L2_1
L0_1 = inherit
L1_1 = "MrxMissionFlow"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxCinematic"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxGui"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxGuiBase"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxLayerManager"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxPlayState"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxStarterManager"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxState"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxSupportData"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxUtil"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxTransit"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "Munitions"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxAchievements"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxVerifyManager"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "WifHints"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxSoundBootstrap"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "WifBios"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxSoundCategories"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxMusic"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "WifMissionData"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxGuiDialogBox"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "DLC01_MissionHub"
L2_1 = true
L0_1(L1_1, L2_1)

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = MrxUtil
  L0_2 = L0_2.GetCharacterIdentity
  L1_2 = Player
  L1_2 = L1_2.GetPrimaryCharacter
  L1_2, L2_2, L3_2, L4_2, L5_2 = L1_2()
  L0_2 = L0_2(L1_2, L2_2, L3_2, L4_2, L5_2)
  if L0_2 then
    L1_2 = string
    L1_2 = L1_2.upper
    L2_2 = string
    L2_2 = L2_2.sub
    L3_2 = L0_2
    L4_2 = 1
    L5_2 = 1
    L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2, L4_2, L5_2)
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
    L0_2 = L1_2
  end
  if L0_2 ~= "M" and L0_2 ~= "J" and L0_2 ~= "C" then
    L0_2 = "M"
  end
  L1_2 = {}
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = true
    return L0_3
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = _BeginBlockingSequence
    L0_3()
    
    function L0_3()
      local L0_4, L1_4, L2_4
      L0_4 = SetGrappleEnabled
      L1_4 = true
      L0_4(L1_4)
      L0_4 = SetVehicleDisguiseEnabled
      L1_4 = true
      L0_4(L1_4)
      L0_4 = EnableResourceCounters
      L1_4 = true
      L0_4(L1_4)
      L0_4 = MrxSupportData
      L0_4 = L0_4.SetHeliPilotRecruited
      L1_4 = true
      L0_4(L1_4)
      L0_4 = MrxSupportData
      L0_4 = L0_4.SetMechanicRecruited
      L1_4 = true
      L0_4(L1_4)
      L0_4 = MrxSupportData
      L0_4 = L0_4.SetJetPilotRecruited
      L1_4 = true
      L0_4(L1_4)
      L0_4 = UnlockMission
      L1_4 = "DlcCon001"
      L0_4(L1_4)
      L0_4 = UnlockMission
      L1_4 = "DlcCon002"
      L0_4(L1_4)
      L0_4 = UnlockMission
      L1_4 = "DlcCon003"
      L0_4(L1_4)
      L0_4 = UnlockMission
      L1_4 = "DlcCon004"
      L0_4(L1_4)
      L0_4 = MrxCheatBootstrap
      L0_4 = L0_4.IsSkipModeEnabled
      L0_4 = L0_4()
      if not L0_4 then
        L0_4 = MrxState
        L0_4 = L0_4.Exit
        L1_4 = MrxState
        L1_4 = L1_4.STATE_WAITFORGAME
        L2_4 = _EndBlockingSequence
        L0_4(L1_4, L2_4)
      else
        L0_4 = _EndBlockingSequence
        L0_4()
      end
    end
    
    L1_3 = MrxCheatBootstrap
    L1_3 = L1_3.IsSkipModeEnabled
    L1_3 = L1_3()
    if not L1_3 then
      L1_3 = MrxState
      L1_3 = L1_3.Enter
      L2_3 = MrxState
      L2_3 = L2_3.STATE_WAITFORGAME
      L3_3 = L0_3
      L1_3(L2_3, L3_3)
    else
      L1_3 = L0_3
      L1_3()
    end
  end
  
  L2_2.fConseq = L3_2
  L1_2.Start = L2_2
  return L1_2
end

GetOriginalFlowData = L0_1

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
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
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
      L3_3, L4_3, L5_3, L6_3, L7_3, L8_3 = L3_3(L4_3)
      L2_3(L3_3, L4_3, L5_3, L6_3, L7_3, L8_3)
    end
    L2_3 = Pda
    L2_3 = L2_3.Map
    L3_3 = L2_3
    L2_3 = L2_3.RemoveMission
    L4_3 = {}
    L5_3 = A0_2
    L4_3.sName = L5_3
    L2_3(L3_3, L4_3)
    L2_3 = UnlockMission
    L3_3 = A0_2
    L2_3(L3_3)
    L2_3 = Refresh
    L2_3()
    L2_3 = SetLastCompletedContractName
    L3_3 = A0_2
    L2_3(L3_3)
    L2_3 = DLC01_MissionHub
    L2_3 = L2_3.Enter
    L3_3 = true
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
    L1_3 = DLC01_MissionHub
    L1_3 = L1_3.Enter
    L2_3 = true
    L1_3(L2_3)
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
  local L1_2, L2_2
  L1_2 = MrxMissionFlow
  L1_2 = L1_2.Reset
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = SetFlowData
  L2_2 = GetOriginalFlowData
  L2_2 = L2_2()
  L1_2(L2_2)
end

Reset = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = MrxCheatBootstrap
  L2_2 = L2_2.IsSkipModeEnabled
  L2_2 = L2_2()
  if not L2_2 then
    L2_2 = MrxUtil
    L2_2 = L2_2.CallWithOptionalArgs
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  else
    L2_2 = MrxLayerManager
    L2_2 = L2_2.ProcessMarkedLayers
    L3_2 = MrxUtil
    L3_2 = L3_2.CallWithOptionalArgs
    L4_2 = {}
    L5_2 = A0_2
    L6_2 = A1_2
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L2_2(L3_2, L4_2)
  end
end

_ChangeOutpostStaging = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2.SetSwfFile
  L3_2 = nil
  L1_2(L2_2, L3_2)
  L1_2 = MrxGui
  L1_2 = L1_2.RemoveWidget
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.delete
  L1_2(L2_2)
  L1_2 = MrxGui
  L1_2 = L1_2.FadeFromColor
  L1_2()
  L1_2 = Sys
  L1_2 = L1_2.RequestGameState
  L2_2 = "unloading"
  L1_2(L2_2)
  L1_2 = Net
  L1_2 = L1_2.QuitGame
  L1_2()
end

_ClientQuitToShell = L0_1
