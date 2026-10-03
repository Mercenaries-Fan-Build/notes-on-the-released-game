local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskMission"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxHqManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPlayer"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPlayState"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifPmcInterior"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSoundCategories"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxActionHijack"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxMusic"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxState"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxStatsManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxParkingLotManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiInterface"
L0_1(L1_1)

function L0_1(A0_2, A1_2, A2_2, A3_2)
end

OnPlayerJoined = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
end

OnPlayerLeft = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2._GetSaveData
  L1_2 = L1_2(L2_2)
  L2_2 = type
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if L2_2 == "table" then
    L2_2 = L1_2.tContractState
    if not L2_2 then
      L2_2 = {}
    end
    A0_2._tContractState = L2_2
  else
    L2_2 = {}
    A0_2._tContractState = L2_2
  end
end

PreLoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Net
  L1_2 = L1_2.DoneReloadingLayers
  if L1_2 then
    L1_2 = Net
    L1_2 = L1_2.DoneReloadingLayers
    L1_2()
  end
  L1_2 = MrxState
  L1_2 = L1_2.AddGlobalExitCallback
  L2_2 = A0_2.Activated
  L3_2 = {}
  L4_2 = A0_2
  L3_2[1] = L4_2
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._IssueAssetsLoadedCallbacks
  L1_2(L2_2)
end

AssetsLoaded = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2.tRewards
  if L2_2 then
    L2_2 = L1_2.tRewards
    L2_2 = L2_2.nWager
    if not L2_2 then
      L2_2 = L1_2.tRewards
      L2_2 = L2_2.nWagerPercent
      if not L2_2 then
        goto lbl_23
      end
    end
    L2_2 = MrxGui
    L2_2 = L2_2.GetWidgetByName
    L3_2 = "Pause Layout"
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L4_2 = L2_2
      L3_2 = L2_2.SetUserSaveEnabled
      L5_2 = false
      L3_2(L4_2, L5_2)
    end
  end
  ::lbl_23::
  L2_2 = MrxPlayState
  L2_2 = L2_2.Set
  L3_2 = MrxPlayState
  L3_2 = L3_2._knMission
  L2_2(L3_2)
  L2_2 = MrxPlayState
  L2_2 = L2_2.SetCurrentMission
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = L1_2.bSuppressPdaDisplay
  if not L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.GetMissionId
    L2_2 = L2_2(L3_2)
    L3_2 = Pda
    L3_2 = L3_2.Map
    L4_2 = L3_2
    L3_2 = L3_2.SetSelectedMission
    L5_2 = {}
    L5_2.sName = L2_2
    L3_2(L4_2, L5_2)
  end
  L2_2 = WifMissionFlow
  L2_2 = L2_2.GetRetryLocations
  L2_2 = L2_2()
  if not L2_2 then
    L3_2 = WifMissionFlow
    L3_2 = L3_2.SetRetryLocations
    L5_2 = A0_2
    L4_2 = A0_2.GetStartLocations
    L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2 = L4_2(L5_2)
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  end
  L3_2 = MrxTaskMission
  L3_2 = L3_2.Activated
  L4_2 = A0_2
  L3_2(L4_2)
  L4_2 = A0_2
  L3_2 = A0_2.GetConfig
  L3_2 = L3_2(L4_2)
  L4_2 = {}
  L4_2.All = "an"
  L4_2.Chi = "ch"
  L4_2.Gur = "gr"
  L4_2.Oil = "oc"
  L4_2.Pmc = "pmc"
  L4_2.Vza = "pmc"
  L5_2 = L3_2.sFactionId
  L5_2 = L4_2[L5_2]
  if L5_2 then
    L6_2 = MrxMusic
    L6_2 = L6_2.EnterContractMusic
    L7_2 = L5_2
    L6_2(L7_2)
  end
  L6_2 = Player
  L6_2 = L6_2.GetLocalCharacter
  L6_2 = L6_2()
  if L6_2 then
    L7_2 = Object
    L7_2 = L7_2.SetHealth
    L8_2 = L6_2
    L9_2 = Object
    L9_2 = L9_2.GetMaxHealth
    L10_2 = L6_2
    L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2 = L9_2(L10_2)
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  end
  L7_2 = _Checkpoint
  L8_2 = nil
  L9_2 = true
  L10_2 = true
  L7_2(L8_2, L9_2, L10_2)
  L7_2 = Player
  L7_2 = L7_2.GetAllPlayers
  L7_2 = L7_2()
  L8_2 = ipairs
  L9_2 = L7_2
  L8_2, L9_2, L10_2 = L8_2(L9_2)
  for L11_2, L12_2 in L8_2, L9_2, L10_2 do
    L13_2 = Player
    L13_2 = L13_2.GetCharacter
    L14_2 = L12_2
    L13_2 = L13_2(L14_2)
    if L13_2 then
      L14_2 = Player
      L14_2 = L14_2.IsRemote
      L15_2 = L11_2
      L14_2 = L14_2(L15_2)
      if L14_2 then
        L15_2 = A0_2
        L14_2 = A0_2.OnPlayerJoined
        L16_2 = L11_2
        L17_2 = L12_2
        L18_2 = L13_2
        L14_2(L15_2, L16_2, L17_2, L18_2)
      end
    end
  end
  L8_2 = MrxFactionManager
  L8_2 = L8_2.IsAttitudeMutable
  L9_2 = L3_2.sFactionId
  L8_2 = L8_2(L9_2)
  if L8_2 then
    L8_2 = MrxFactionManager
    L8_2 = L8_2.CreateAttitudeChangeEvent
    L9_2 = {}
    L10_2 = L3_2.sFactionId
    L11_2 = "Pmc"
    L12_2 = nil
    L13_2 = "Hostile"
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L9_2[4] = L13_2
    
    function L10_2()
      local L0_3, L1_3, L2_3
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._SetCancelMessage
      L2_3 = "[Fanfare.Cancel.FactionHostile]"
      L0_3(L1_3, L2_3)
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3.Cancel
      L0_3(L1_3)
    end
    
    L8_2 = L8_2(L9_2, L10_2)
    A0_2._uFactionAttitudeChanged = L8_2
  end
  L8_2 = MrxFactionManager
  L8_2 = L8_2.GetFactionTemplateName
  L9_2 = L3_2.sFactionId
  L8_2 = L8_2(L9_2)
  L9_2 = Ai
  L9_2 = L9_2.SetInfractionMultiplier
  L10_2 = Pg
  L10_2 = L10_2.GetGuidByName
  L11_2 = L8_2
  L10_2 = L10_2(L11_2)
  L11_2 = 0.2
  L9_2(L10_2, L11_2)
  L10_2 = A0_2
  L9_2 = A0_2.GetMissionId
  L9_2 = L9_2(L10_2)
  L10_2 = Pg
  L10_2 = L10_2.ContractActivated
  L11_2 = L9_2
  L10_2(L11_2)
  L10_2 = MrxParkingLotManager
  L10_2 = L10_2.MarkLastVehicle
  L10_2()
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = A0_2._bEndSequenceInProgress
  if L1_2 then
    return
  end
  A0_2._bEndSequenceInProgress = true
  L1_2 = Player
  L1_2 = L1_2.GetLocalPlayer
  L1_2 = L1_2()
  if L1_2 then
    L2_2 = Player
    L2_2 = L2_2.SetSeatMovementLocks
    L3_2 = L1_2
    L4_2 = false
    L2_2(L3_2, L4_2)
  end
  L2_2 = MrxActionHijack
  L2_2 = L2_2.IsInHijack
  L2_2 = L2_2()
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.GetMissionId
    L2_2 = L2_2(L3_2)
    if L2_2 ~= "PmcCon004" then
      L2_2 = MrxActionHijack
      L2_2 = L2_2.SetUnloadCallback
      L3_2 = A0_2.Complete1
      L4_2 = {}
      L5_2 = A0_2
      L4_2[1] = L5_2
      L2_2(L3_2, L4_2)
  end
  else
    L3_2 = A0_2
    L2_2 = A0_2.Complete1
    L2_2(L3_2)
  end
  L2_2 = Pg
  L2_2 = L2_2.ContractCompleted
  L2_2()
end

Complete = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = MrxHqManager
  L1_2 = L1_2.IsInside
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = MrxHqManager
    L1_2 = L1_2.SetUnloadCallback
    L2_2 = A0_2.Complete2
    L3_2 = {}
    L4_2 = A0_2
    L3_2[1] = L4_2
    L1_2(L2_2, L3_2)
  else
    L1_2 = WifPmcInterior
    L1_2 = L1_2.IsInside
    L1_2 = L1_2()
    if L1_2 then
      L1_2 = WifPmcInterior
      L1_2 = L1_2.SetUnloadCallback
      L2_2 = A0_2.Complete2
      L3_2 = {}
      L4_2 = A0_2
      L3_2[1] = L4_2
      L1_2(L2_2, L3_2)
    else
      L2_2 = A0_2
      L1_2 = A0_2.Complete2
      L1_2(L2_2)
    end
  end
end

Complete1 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L2_2 = A0_2
  L1_2 = A0_2.IsCompleted
  L1_2 = L1_2(L2_2)
  if L1_2 then
    return
  end
  L2_2 = A0_2
  L1_2 = A0_2.GetMissionId
  L1_2 = L1_2(L2_2)
  if L1_2 == "OilCon002" then
    L1_2 = Net
    L1_2 = L1_2.SendCustomEvent
    L2_2 = "MrxTaskContract"
    L3_2 = NETEVENT_CLIENTPAUSE
    L4_2 = {}
    L1_2(L2_2, L3_2, L4_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2._SetState
  L3_2 = MrxTaskState
  L3_2 = L3_2._knCompleted
  L1_2(L2_2, L3_2)
  L1_2 = WifMissionFlow
  L1_2 = L1_2.SetRetryLocations
  L2_2 = nil
  L1_2(L2_2)
  L1_2 = MrxMusic
  L1_2 = L1_2.PlayFanfare
  L2_2 = true
  L1_2(L2_2)
  L1_2 = Object
  L1_2 = L1_2.GetLocalizedName
  L2_2 = Player
  L2_2 = L2_2.GetPrimaryCharacter
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2 = L2_2()
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  L2_2 = nil
  L3_2 = Player
  L3_2 = L3_2.GetSecondaryCharacter
  L3_2 = L3_2()
  if L3_2 then
    L4_2 = Object
    L4_2 = L4_2.GetLocalizedName
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    L2_2 = L4_2
  end
  L4_2 = _SetPlayersInvincible
  L5_2 = true
  L4_2(L5_2)
  L5_2 = A0_2
  L4_2 = A0_2.GetConfig
  L4_2 = L4_2(L5_2)
  L5_2 = nil
  L6_2 = L4_2.bPlayerVisibleMission
  if L6_2 then
    L5_2 = "mission"
  else
    L6_2 = L4_2.tRewards
    if L6_2 then
      L6_2 = L4_2.tRewards
      L6_2 = L6_2.nWager
      if not L6_2 then
        L6_2 = L4_2.tRewards
        L6_2 = L6_2.nWagerPercent
        if not L6_2 then
          goto lbl_69
        end
      end
      L5_2 = "wager"
    else
      ::lbl_69::
      L5_2 = "contract"
    end
  end
  L6_2 = 1
  L7_2 = Hud
  L7_2 = L7_2.Fanfare
  L8_2 = L7_2
  L7_2 = L7_2.Create
  L9_2 = {}
  L9_2.sType = L5_2
  L9_2.sProfileName1 = L1_2
  L9_2.sProfileName2 = L2_2
  
  function L10_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = L6_2
    if 1 < L1_3 then
      return
    end
    L1_3 = L6_2
    L1_3 = L1_3 + 1
    L6_2 = L1_3
    L1_3 = MrxSoundCategories
    L1_3 = L1_3.Fade
    L2_3 = "fanfare"
    L3_3 = false
    L1_3(L2_3, L3_3)
    L1_3 = _SetPlayersInvincible
    L2_3 = false
    L1_3(L2_3)
    L1_3 = A0_2
    L2_3 = L1_3
    L1_3 = L1_3.Cleanup
    L1_3(L2_3)
    L1_3 = A0_2
    L2_3 = L1_3
    L1_3 = L1_3._IssueStateChangeCallbacks
    L1_3(L2_3)
  end
  
  L9_2.fCallback = L10_2
  L7_2(L8_2, L9_2)
  if L5_2 == "contract" then
    L7_2 = 0
    L8_2 = A0_2._nContractReward
    if L8_2 then
      L7_2 = A0_2._nContractReward
    else
      L8_2 = L4_2.tRewards
      if L8_2 then
        L8_2 = L4_2.tRewards
        L8_2 = L8_2.nCash
        if L8_2 then
          L8_2 = L4_2.tRewards
          L7_2 = L8_2.nCash
        end
      end
    end
    L8_2 = 0
    L9_2 = 0
    L10_2 = A0_2._nBonus1
    if L10_2 then
      L8_2 = A0_2._nBonus1
    end
    L10_2 = A0_2._nBonus2
    if L10_2 then
      L9_2 = A0_2._nBonus2
    end
    L10_2 = {}
    L11_2 = {}
    L11_2.sDescription = "[Fanfare.Completion.ContractFee]"
    L11_2.sValueType = "$"
    L11_2.nValue = L7_2
    L12_2 = {}
    L12_2.sDescription = "[Fanfare.Completion.Bonus]"
    L12_2.sValueType = "$"
    L12_2.nValue = L8_2
    L13_2 = {}
    L13_2.sDescription = "[Fanfare.Completion.Total]"
    L13_2.sValueType = "$"
    L14_2 = L7_2 + L8_2
    L13_2.nValue = L14_2
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L10_2[3] = L13_2
    L11_2 = ipairs
    L12_2 = L10_2
    L11_2, L12_2, L13_2 = L11_2(L12_2)
    for L14_2, L15_2 in L11_2, L12_2, L13_2 do
      L15_2.nPlayer = 1
      L16_2 = Hud
      L16_2 = L16_2.Fanfare
      L17_2 = L16_2
      L16_2 = L16_2.AddItem
      L18_2 = L15_2
      L16_2(L17_2, L18_2)
    end
    if L3_2 then
      L11_2 = L10_2[2]
      L11_2.nValue = L9_2
      L11_2 = L10_2[3]
      L12_2 = L7_2 + L9_2
      L11_2.nValue = L12_2
      L11_2 = ipairs
      L12_2 = L10_2
      L11_2, L12_2, L13_2 = L11_2(L12_2)
      for L14_2, L15_2 in L11_2, L12_2, L13_2 do
        L15_2.nPlayer = 2
        L16_2 = Hud
        L16_2 = L16_2.Fanfare
        L17_2 = L16_2
        L16_2 = L16_2.AddItem
        L18_2 = L15_2
        L16_2(L17_2, L18_2)
      end
    end
    L11_2 = L4_2.tRewards
    if not L11_2 then
      L11_2 = {}
      L4_2.tRewards = L11_2
    end
    L11_2 = L4_2.tRewards
    L12_2 = L7_2 + L8_2
    L11_2.nCashOverride = L12_2
    if L3_2 then
      L11_2 = L4_2.tRewards
      L12_2 = L7_2 + L9_2
      L11_2.nCashOverride2 = L12_2
    end
  elseif L5_2 == "wager" then
    L7_2 = 0
    L8_2 = L4_2.tRewards
    if L8_2 then
      L8_2 = L4_2.tRewards
      L8_2 = L8_2.nWagered
      if L8_2 then
        L8_2 = L4_2.tRewards
        L8_2 = L8_2.nWagered
        L7_2 = L7_2 + L8_2
      end
    end
    L8_2 = {}
    L8_2.nPlayer = 1
    L8_2.sDescription = "[Fanfare.Wager.Winnings]"
    L8_2.sValueType = "$"
    L8_2.nValue = L7_2
    L9_2 = Hud
    L9_2 = L9_2.Fanfare
    L10_2 = L9_2
    L9_2 = L9_2.AddItem
    L11_2 = L8_2
    L9_2(L10_2, L11_2)
    if L3_2 then
      L8_2.nPlayer = 2
      L8_2.nValue = 0
      L9_2 = Hud
      L9_2 = L9_2.Fanfare
      L10_2 = L9_2
      L9_2 = L9_2.AddItem
      L11_2 = L8_2
      L9_2(L10_2, L11_2)
    end
  end
  L7_2 = MrxSoundCategories
  L7_2 = L7_2.Fade
  L8_2 = "fanfare"
  L9_2 = true
  L7_2(L8_2, L9_2)
  L7_2 = Hud
  L7_2 = L7_2.Fanfare
  L8_2 = L7_2
  L7_2 = L7_2.Commence
  L9_2 = {}
  L7_2(L8_2, L9_2)
end

Complete2 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = A0_2._bEndSequenceInProgress
  if L1_2 then
    return
  end
  A0_2._bEndSequenceInProgress = true
  L1_2 = Player
  L1_2 = L1_2.GetLocalPlayer
  L1_2 = L1_2()
  if L1_2 then
    L2_2 = Player
    L2_2 = L2_2.SetSeatMovementLocks
    L3_2 = L1_2
    L4_2 = false
    L2_2(L3_2, L4_2)
  end
  L2_2 = MrxHqManager
  L2_2 = L2_2.IsInside
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = MrxHqManager
    L2_2 = L2_2.SetUnloadCallback
    L3_2 = A0_2.Cancel2
    L4_2 = {}
    L5_2 = A0_2
    L4_2[1] = L5_2
    L2_2(L3_2, L4_2)
  else
    L2_2 = WifPmcInterior
    L2_2 = L2_2.IsInside
    L2_2 = L2_2()
    if L2_2 then
      L2_2 = WifPmcInterior
      L2_2 = L2_2.SetUnloadCallback
      L3_2 = A0_2.Cancel2
      L4_2 = {}
      L5_2 = A0_2
      L4_2[1] = L5_2
      L2_2(L3_2, L4_2)
    else
      L3_2 = A0_2
      L2_2 = A0_2.Cancel2
      L2_2(L3_2)
    end
  end
  L2_2 = Player
  L2_2 = L2_2.ClearGPS
  if L2_2 then
    L2_2 = Player
    L2_2 = L2_2.GetLocalPlayer
    L2_2 = L2_2()
    if L2_2 then
      L3_2 = Player
      L3_2 = L3_2.ClearGPS
      L4_2 = L2_2
      L3_2(L4_2)
    end
  end
  L2_2 = Pg
  L2_2 = L2_2.ContractCancelled
  L2_2()
end

Cancel = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2
  L1_2 = A0_2.IsCancelled
  L1_2 = L1_2(L2_2)
  if L1_2 then
    return
  end
  L2_2 = A0_2
  L1_2 = A0_2._SetState
  L3_2 = MrxTaskState
  L3_2 = L3_2._knCancelled
  L1_2(L2_2, L3_2)
  L1_2 = MrxMusic
  L1_2 = L1_2.PlayFanfare
  L2_2 = false
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = nil
  L3_2 = L1_2.bPlayerVisibleMission
  if L3_2 then
    L2_2 = "mission"
  else
    L3_2 = L1_2.tRewards
    if L3_2 then
      L3_2 = L1_2.tRewards
      L3_2 = L3_2.nWager
      if not L3_2 then
        L3_2 = L1_2.tRewards
        L3_2 = L3_2.nWagerPercent
        if not L3_2 then
          goto lbl_35
        end
      end
      L2_2 = "wager"
    else
      ::lbl_35::
      L2_2 = "contract"
    end
  end
  L3_2 = L2_2 ~= "wager" and L3_2
  L4_2 = 1
  L5_2 = A0_2._sCancelMsg
  if not L5_2 then
    L5_2 = {}
    L6_2 = "[Generic.Failures.002]"
    L7_2 = "[Generic.Failures.003]"
    L8_2 = "[Generic.Failures.005]"
    L9_2 = "[Generic.Failures.009]"
    L10_2 = "[Generic.Failures.011]"
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L5_2[4] = L9_2
    L5_2[5] = L10_2
    L6_2 = MrxUtil
    L6_2 = L6_2.GetRandomTableElement
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    A0_2._sCancelMsg = L6_2
  end
  L5_2 = Hud
  L5_2 = L5_2.Fanfare
  L6_2 = L5_2
  L5_2 = L5_2.Create
  L7_2 = {}
  L7_2.sType = L2_2
  L7_2.sProfileName1 = "unused"
  L7_2.bAllowRetry = L3_2
  L8_2 = A0_2._sCancelMsg
  L7_2.sCancelMsg = L8_2
  
  function L8_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = L4_2
    if 1 < L1_3 then
      return
    end
    L1_3 = L4_2
    L1_3 = L1_3 + 1
    L4_2 = L1_3
    L1_3 = MrxSoundCategories
    L1_3 = L1_3.Fade
    L2_3 = "fanfare"
    L3_3 = false
    L1_3(L2_3, L3_3)
    L1_3 = _SetPlayersInvincible
    L2_3 = false
    L1_3(L2_3)
    if A0_3 ~= nil then
      A0_3 = not A0_3
      L1_3 = L3_2
      A0_3 = L1_3 or A0_3
      if L1_3 then
      end
    end
    L1_3 = L1_2
    L1_3 = L1_3.sStarter
    if not L1_3 then
      A0_3 = true
    end
    L1_3 = A0_2
    L2_3 = L1_3
    L1_3 = L1_3._DialogBoxDismissed
    L3_3 = A0_3
    L1_3(L2_3, L3_3)
  end
  
  L7_2.fCallback = L8_2
  L5_2(L6_2, L7_2)
  L5_2 = MrxSoundCategories
  L5_2 = L5_2.Fade
  L6_2 = "fanfare"
  L7_2 = true
  L5_2(L6_2, L7_2)
  L5_2 = _SetPlayersInvincible
  L6_2 = true
  L5_2(L6_2)
  L5_2 = Hud
  L5_2 = L5_2.Fanfare
  L6_2 = L5_2
  L5_2 = L5_2.Commence
  L7_2 = {}
  L5_2(L6_2, L7_2)
end

Cancel2 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  A0_2._bEndSequenceInProgress = nil
  L1_2 = Player
  L1_2 = L1_2.GetLocalPlayer
  L1_2 = L1_2()
  if L1_2 then
    L2_2 = Player
    L2_2 = L2_2.SetSeatMovementLocks
    L3_2 = L1_2
    L4_2 = true
    L2_2(L3_2, L4_2)
  end
  L2_2 = A0_2._uFactionAttitudeChanged
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = A0_2._uFactionAttitudeChanged
    L2_2(L3_2)
    A0_2._uFactionAttitudeChanged = nil
  end
  L2_2 = MrxVoSequence
  L2_2 = L2_2.Stop
  L3_2 = nil
  L4_2 = false
  L5_2 = MrxVoSequence
  L5_2 = L5_2.knPriorityContract
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = A0_2
  L2_2 = A0_2.GetConfig
  L2_2 = L2_2(L3_2)
  L3_2 = MrxFactionManager
  L3_2 = L3_2.GetFactionTemplateName
  L4_2 = L2_2.sFactionId
  L3_2 = L3_2(L4_2)
  L4_2 = Ai
  L4_2 = L4_2.SetInfractionMultiplier
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = L3_2
  L5_2 = L5_2(L6_2)
  L6_2 = 1
  L4_2(L5_2, L6_2)
  L4_2 = L2_2.bSuppressPdaDisplay
  if not L4_2 then
    L4_2 = Pda
    L4_2 = L4_2.Map
    L5_2 = L4_2
    L4_2 = L4_2.SetSelectedMission
    L6_2 = {}
    L6_2.sName = nil
    L4_2(L5_2, L6_2)
  end
  L4_2 = Hud
  L4_2 = L4_2.MessageBox
  L5_2 = L4_2
  L4_2 = L4_2.Clear
  L6_2 = {}
  L4_2(L5_2, L6_2)
  L4_2 = MrxTaskMission
  L4_2 = L4_2.Cleanup
  L5_2 = A0_2
  L4_2(L5_2)
  L4_2 = L2_2.tRewards
  if L4_2 then
    L4_2 = L2_2.tRewards
    L4_2 = L4_2.nWager
    if not L4_2 then
      L4_2 = L2_2.tRewards
      L4_2 = L4_2.nWagerPercent
      if not L4_2 then
        goto lbl_79
      end
    end
    L4_2 = MrxGui
    L4_2 = L4_2.GetWidgetByName
    L5_2 = "Pause Layout"
    L4_2 = L4_2(L5_2)
    if L4_2 then
      L6_2 = L4_2
      L5_2 = L4_2.SetUserSaveEnabled
      L7_2 = true
      L5_2(L6_2, L7_2)
    end
  end
  ::lbl_79::
end

Cleanup = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  A0_2.bRetry = A1_2
  L3_2 = A0_2
  L2_2 = A0_2.Cleanup
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2._IssueStateChangeCallbacks
  L2_2(L3_2)
  if A1_2 then
    L2_2 = MrxStatsManager
    L2_2 = L2_2.IncreaseRetriesCounter
    L2_2()
    L2_2 = MrxLayerManager
    L2_2 = L2_2.ProcessMarkedLayers
    L3_2 = Pg
    L3_2 = L3_2.LoadGame
    L4_2 = {}
    L5_2 = "retry"
    L4_2[1] = L5_2
    L2_2(L3_2, L4_2)
  else
    L3_2 = A0_2
    L2_2 = A0_2.GetParent
    L2_2 = L2_2(L3_2)
    L3_2 = L2_2
    L2_2 = L2_2.Cancel
    L2_2(L3_2)
    L3_2 = A0_2
    L2_2 = A0_2.GetConfig
    L2_2 = L2_2(L3_2)
    L3_2 = L2_2.tRewards
    if L3_2 then
      L3_2 = L2_2.tRewards
      L3_2 = L3_2.nWager
      if L3_2 then
        goto lbl_74
      end
      L3_2 = L2_2.tRewards
      L3_2 = L3_2.nWagerPercent
      if L3_2 then
        goto lbl_74
      end
    end
    L3_2 = WifPmcInterior
    L3_2 = L3_2.IsUnlocked
    L3_2 = L3_2()
    if L3_2 then
      L3_2 = MrxPlayer
      L3_2 = L3_2.AreAnyHeroesAlive
      L3_2 = L3_2()
      if not L3_2 then
        L3_2 = MrxPlayer
        L3_2 = L3_2.MoveToSickbay
        L3_2()
      else
        L3_2 = Net
        L3_2 = L3_2.IsClient
        L3_2 = L3_2()
        if not L3_2 then
          L3_2 = Player
          L3_2 = L3_2.GetLocalCharacter
          L3_2 = L3_2()
          L4_2 = Object
          L4_2 = L4_2.IsAlive
          L5_2 = L3_2
          L4_2 = L4_2(L5_2)
          if not L4_2 then
            L4_2 = Player
            L4_2 = L4_2.IsBoundaryDeath
            L5_2 = L3_2
            L4_2 = L4_2(L5_2)
            if L4_2 then
              L4_2 = MrxPlayer
              L4_2 = L4_2.MoveToSickbay
              L4_2()
            end
          end
        end
      end
    end
    ::lbl_74::
    L3_2 = A0_2._bCancelByMedEvac
    if L3_2 then
      L3_2 = MrxPlayer
      L3_2 = L3_2.MoveToSickbay
      L3_2()
    end
    L3_2 = WifMissionFlow
    L3_2 = L3_2.SetRetryLocations
    L4_2 = nil
    L3_2(L4_2)
  end
  A0_2.bRetry = nil
end

_DialogBoxDismissed = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = MrxTaskMission
  L0_2 = L0_2._knContract
  return L0_2
end

_GetMissionType = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = true
  return L0_2
end

IsContract = L0_1

function L0_1(A0_2, A1_2)
  A0_2._bCancelByMedEvac = A1_2
end

SetCancelByMedEvac = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  L3_2 = type
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if L3_2 == "string" then
    if not A2_2 then
      A2_2 = 1
    end
    L3_2 = A0_2._tContractState
    if L3_2 then
      L3_2 = A0_2._tContractState
      L3_2[A1_2] = A2_2
    end
  end
end

_SetFlag = L0_1

function L0_1(A0_2, A1_2)
  local L2_2
  L2_2 = A0_2._tContractState
  if L2_2 then
    L2_2 = A0_2._tContractState
    L2_2 = L2_2[A1_2]
    return L2_2
  end
end

_GetFlag = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = WifMissionFlow
  L3_2 = L3_2.EnableCheckpointSaveMode
  L4_2 = true
  L3_2(L4_2)
  if A0_2 then
    L3_2 = WifMissionFlow
    L3_2 = L3_2.SetRetryLocations
    L4_2 = A0_2
    L3_2(L4_2)
  end
  L3_2 = Pg
  L3_2 = L3_2.SaveGame
  L4_2 = "retry"
  L3_2(L4_2)
  L3_2 = WifMissionFlow
  L3_2 = L3_2.EnableCheckpointSaveMode
  L4_2 = false
  L3_2(L4_2)
  if not A1_2 then
    L3_2 = WifMissionFlow
    L3_2 = L3_2.Autosave
    L3_2()
  end
  if not A2_2 then
    L3_2 = Hud
    L3_2 = L3_2.MessageBox
    L4_2 = L3_2
    L3_2 = L3_2.AddMessage
    L5_2 = {}
    L5_2.sMessage = "[Generic.CheckpointReached]"
    L3_2(L4_2, L5_2)
    L3_2 = Net
    L3_2 = L3_2.IsServer
    L3_2 = L3_2()
    if L3_2 then
      L3_2 = Net
      L3_2 = L3_2.SendEvent_ObjectiveMessage
      L4_2 = 99
      L5_2 = ""
      L6_2 = ""
      L3_2(L4_2, L5_2, L6_2)
    end
  end
end

_Checkpoint = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = MrxTaskMission
  L2_2 = L2_2.SaveInstance
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if A1_2 then
    L2_2.tContractState = nil
  else
    L3_2 = A0_2._tContractState
    L2_2.tContractState = L3_2
  end
  return L2_2
end

SaveInstance = L0_1

function L0_1(A0_2, A1_2)
  A0_2._sCancelMsg = A1_2
end

_SetCancelMessage = L0_1

function L0_1(A0_2, A1_2)
  A0_2._nContractReward = A1_2
end

_SetContractReward = L0_1

function L0_1(A0_2, A1_2)
  A0_2._nBonus1 = A1_2
end

_SetPlayer1Bonus = L0_1

function L0_1(A0_2, A1_2)
  A0_2._nBonus2 = A1_2
end

_SetPlayer2Bonus = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Player
  L1_2 = L1_2.GetPrimaryCharacter
  L1_2 = L1_2()
  if L1_2 then
    L2_2 = Object
    L2_2 = L2_2.SetInvincible
    L3_2 = L1_2
    L4_2 = A0_2
    L5_2 = "Fanfare"
    L2_2(L3_2, L4_2, L5_2)
  end
  L2_2 = Player
  L2_2 = L2_2.GetSecondaryCharacter
  L2_2 = L2_2()
  if L2_2 then
    L3_2 = Object
    L3_2 = L3_2.SetInvincible
    L4_2 = L2_2
    L5_2 = A0_2
    L6_2 = "Fanfare"
    L3_2(L4_2, L5_2, L6_2)
  end
end

_SetPlayersInvincible = L0_1
L0_1 = 0
NETEVENT_CLIENTPAUSE = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = NETEVENT_CLIENTPAUSE
  if A0_2 == L1_2 then
    L1_2 = MrxGuiInterface
    L1_2 = L1_2.HudInterface
    L1_2 = L1_2.FanfareQueue
    L1_2 = L1_2.ClientPause
    L2_2 = true
    L1_2(L2_2)
    L1_2 = MrxGuiInterface
    L1_2 = L1_2.HudInterface
    L1_2 = L1_2.FanfareQueue
    L1_2 = L1_2.ClientSetPending
    L2_2 = false
    L1_2(L2_2)
  end
end

NetEventCallback = L0_1
