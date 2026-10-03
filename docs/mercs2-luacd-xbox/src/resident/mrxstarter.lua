local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTask"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxLayerManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxHqManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPlayState"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxState"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifPmcInterior"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifBriefingData"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifMissionData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUnlockFanfare"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifMissionFlow"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSoundBanks"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTransit"
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
  A1_2._tBriefings = L2_2
  L3_2 = A1_2
  L2_2 = A1_2._SetBriefingCount
  L4_2 = 0
  L2_2(L3_2, L4_2)
  return A1_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.sName
  return L1_2
end

GetName = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.GetName
  L1_2 = L1_2(L2_2)
  if L1_2 == "PmcBoss" then
    L2_2 = "Fiona"
    return L2_2
  elseif L1_2 == "HelPmcBoss" then
    L2_2 = "Ewan"
    return L2_2
  elseif L1_2 == "JetPmcBoss" then
    L2_2 = "Misha"
    return L2_2
  elseif L1_2 == "MecPmcBoss" then
    L2_2 = "Eva"
    return L2_2
  end
  return L1_2
end

GetPmcName = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.sActionDisplay
  return L1_2
end

GetActionDisplay = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.sHqName
  return L1_2
end

GetHq = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.bBoss
  return L1_2
end

IsBoss = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.bPmcStarter
  return L1_2
end

IsPmcStarter = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.bFemale
  L1_2 = not L1_2
  return L1_2
end

IsMale = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.bHintSystem
  return L1_2
end

HasHintSystem = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.bBribeSystem
  return L1_2
end

HasBribeSystem = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.bGarageSystem
  return L1_2
end

HasGarageSystem = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.bTransitSystem
  return L1_2
end

HasTransitSystem = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.sFaction
  return L1_2
end

GetFaction = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.tCardData
  return L1_2
end

GetCardData = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.sPlayerVisibleName
  return L1_2
end

GetPlayerVisibleName = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.bShop
  if not L1_2 then
    L1_2 = A0_2.bCustomVehicleShop
  end
  return L1_2
end

HasShop = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.bCustomVehicleShop
  return L1_2
end

HasCustomVehicleShop = L0_1

function L0_1(A0_2, A1_2)
  A0_2._uGuid = A1_2
end

SetActor = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2._uGuid
  return L1_2
end

GetActor = L0_1

function L0_1(A0_2, A1_2)
  A0_2._bFanfareDisplayed = A1_2
end

_SetFanfareDisplayed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2._SetFanfareDisplayed
  L3_2 = true
  L1_2(L2_2, L3_2)
end

FanfareDisplayed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxUtil
  L1_2 = L1_2.SetDefault
  L2_2 = A0_2._bFanfareDisplayed
  L3_2 = false
  return L1_2(L2_2, L3_2)
end

HasFanfareBeenDisplayed = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  A0_2._bCardDisplayed = A1_2
  L3_2 = A0_2
  L2_2 = A0_2.IsActivated
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.RefreshBriefingRoomDisplay
    L2_2(L3_2)
  end
end

_SetCardDisplayed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCardDisplayed
  L3_2 = true
  L1_2(L2_2, L3_2)
end

CardDisplayed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxUtil
  L1_2 = L1_2.SetDefault
  L2_2 = A0_2._bCardDisplayed
  L3_2 = false
  return L1_2(L2_2, L3_2)
end

HasCardBeenDisplayed = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.sFaceFxSet
  return L1_2
end

GetGlobalFaceFxSet = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = A0_2._tBriefings
  L3_2 = L3_2[A1_2]
  if L3_2 then
    return
  end
  L3_2 = nil
  L4_2 = WifMissionData
  L4_2 = L4_2.GetMissionRepeatable
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  if L4_2 then
    L4_2 = WifMissionFlow
    L4_2 = L4_2.GetKeyValue
    L5_2 = A1_2
    L4_2 = L4_2(L5_2)
    L4_2 = L4_2 + 1
    L5_2 = WifMissionData
    L5_2 = L5_2.GetMissionLevels
    L6_2 = A1_2
    L5_2 = L5_2(L6_2)
    if L4_2 > L5_2 then
      L5_2 = WifMissionData
      L5_2 = L5_2.GetMissionLevels
      L6_2 = A1_2
      L5_2 = L5_2(L6_2)
      L4_2 = L5_2
    end
    L5_2 = "([Generic.Level] "
    L6_2 = L4_2
    L7_2 = ")"
    L3_2 = L5_2 .. L6_2 .. L7_2
  end
  L4_2 = A0_2._tBriefings
  L5_2 = {}
  L5_2.sTitle = A2_2
  L5_2.sLevel = L3_2
  L4_2[A1_2] = L5_2
  L5_2 = A0_2
  L4_2 = A0_2._GetBriefingCount
  L4_2 = L4_2(L5_2)
  L6_2 = A0_2
  L5_2 = A0_2._SetBriefingCount
  L7_2 = L4_2 + 1
  L5_2(L6_2, L7_2)
  L6_2 = A0_2
  L5_2 = A0_2.IsActivated
  L5_2 = L5_2(L6_2)
  if not L5_2 then
    L6_2 = A0_2
    L5_2 = A0_2.Activate
    L5_2(L6_2)
  else
    L6_2 = A0_2
    L5_2 = A0_2.RefreshBriefingRoomDisplay
    L5_2(L6_2)
  end
end

AddBriefing = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2._tBriefings
  L2_2 = L2_2[A1_2]
  if not L2_2 then
    return
  end
  L2_2 = A0_2._tBriefings
  L2_2[A1_2] = nil
  L3_2 = A0_2
  L2_2 = A0_2._GetBriefingCount
  L2_2 = L2_2(L3_2)
  L4_2 = A0_2
  L3_2 = A0_2._SetBriefingCount
  L5_2 = L2_2 - 1
  L3_2(L4_2, L5_2)
  L4_2 = A0_2
  L3_2 = A0_2.RefreshBriefingRoomDisplay
  L3_2(L4_2)
end

RemoveBriefing = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2._tBriefings
  return L1_2
end

GetOfferedBriefings = L0_1

function L0_1(A0_2, A1_2)
  A0_2._nBriefingCount = A1_2
end

_SetBriefingCount = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2._nBriefingCount
  return L1_2
end

_GetBriefingCount = L0_1

function L0_1(A0_2, A1_2)
  local L2_2
  L2_2 = A0_2._tOldBriefings
  if not L2_2 then
    L2_2 = {}
    A0_2._tOldBriefings = L2_2
  end
  L2_2 = A0_2._tOldBriefings
  L2_2[A1_2] = true
end

SetBriefingOld = L0_1

function L0_1(A0_2, A1_2)
  local L2_2
  L2_2 = A0_2._tOldBriefings
  if not L2_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = A0_2._tOldBriefings
  L2_2 = L2_2[A1_2]
  L2_2 = L2_2 == true
  return L2_2
end

IsBriefingOld = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2._tOldBriefings
  return L1_2
end

GetOldBriefings = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = A0_2._tIntros
  if L2_2 then
    L2_2 = A0_2._tIntros
    L2_2 = L2_2[A1_2]
    if L2_2 ~= nil then
      return
    end
  end
  L2_2 = A0_2._tIntros
  if not L2_2 then
    L2_2 = {}
    A0_2._tIntros = L2_2
  end
  L2_2 = A0_2._tIntros
  L2_2[A1_2] = false
  L3_2 = A0_2
  L2_2 = A0_2.IsActivated
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.RefreshBriefingRoomDisplay
    L2_2(L3_2)
  end
end

AddIntro = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = A0_2._tIntros
  if not L2_2 then
    return
  end
  L2_2 = A0_2._tIntros
  L2_2[A1_2] = nil
  L3_2 = A0_2
  L2_2 = A0_2.IsActivated
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.RefreshBriefingRoomDisplay
    L2_2(L3_2)
  end
end

RemoveIntro = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2
  L4_2 = A0_2._tIntros
  if L4_2 then
    L4_2 = A0_2._tIntros
    L4_2 = L4_2[A1_2]
    if L4_2 ~= nil then
      goto lbl_10
    end
  end
  L4_2 = false
  do return L4_2 end
  ::lbl_10::
  L4_2 = A0_2._tIntros
  L4_2[A1_2] = A2_2
  if A2_2 then
    L4_2 = WifMissionFlow
    L4_2 = L4_2.HasKey
    L5_2 = A1_2
    L6_2 = "Intro"
    L5_2 = L5_2 .. L6_2
    L4_2 = L4_2(L5_2)
    if not L4_2 then
      L4_2 = WifMissionFlow
      L4_2 = L4_2.AwardKey
      L5_2 = A1_2
      L6_2 = "Intro"
      L5_2 = L5_2 .. L6_2
      L4_2(L5_2)
      if A3_2 then
        L4_2 = WifMissionFlow
        L4_2 = L4_2.EnableAutosave
        L4_2()
        L4_2 = WifMissionFlow
        L4_2 = L4_2.Refresh
        L4_2()
      end
    end
  end
  L5_2 = A0_2
  L4_2 = A0_2.IsActivated
  L4_2 = L4_2(L5_2)
  if L4_2 then
    L5_2 = A0_2
    L4_2 = A0_2.RefreshBriefingRoomDisplay
    L4_2(L5_2)
  end
end

SetViewedIntro = L0_1

function L0_1(A0_2, A1_2)
  local L2_2
  L2_2 = A0_2._tIntros
  if not L2_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = A0_2._tIntros
  L2_2 = L2_2[A1_2]
  return L2_2
end

HasViewedIntro = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2._tIntros
  return L1_2
end

GetIntros = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2._tIntros
  L1_2 = L1_2 ~= nil
  return L1_2
end

HasIntros = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  L3_2 = A0_2._tBriefings
  L3_2 = L3_2[A1_2]
  if not L3_2 then
    return
  end
  L3_2 = A0_2._tBriefings
  L3_2 = L3_2[A1_2]
  L3_2.bAccepted = A2_2
  L4_2 = A0_2
  L3_2 = A0_2.SetBriefingOld
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
end

SetMissionAccepted = L0_1

function L0_1(A0_2, A1_2)
  local L2_2
  L2_2 = A0_2._tBriefings
  L2_2 = L2_2[A1_2]
  if not L2_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = A0_2._tBriefings
  L2_2 = L2_2[A1_2]
  L2_2 = L2_2.bAccepted
  return L2_2
end

IsMissionAccepted = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2._tMissionsToBeAccepted
  L2_2 = A0_2._sLastAcceptedMission
  return L1_2, L2_2
end

GetMissionsToBeAccepted = L0_1

function L0_1(A0_2, A1_2)
  A0_2._sPendingContractId = A1_2
end

SetPendingContract = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2._sPendingContractId
  return L1_2
end

GetPendingContract = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2._sPendingContractId
  L1_2 = L1_2 ~= nil
  return L1_2
end

IsContractPending = L0_1

function L0_1(A0_2)
  local L1_2
  A0_2._tMissionsToBeAccepted = nil
  A0_2._sLastAcceptedMission = nil
  A0_2._sPendingContractId = nil
end

ResetIntraSessionData = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = pairs
  L2_2 = A0_2._tBriefings
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = WifMissionData
    L6_2 = L6_2.IsMissionOnCriticalPath
    L7_2 = L4_2
    L6_2 = L6_2(L7_2)
    if L6_2 then
      L6_2 = WifMissionFlow
      L6_2 = L6_2.HasKey
      L7_2 = L4_2
      L6_2 = L6_2(L7_2)
      if not L6_2 then
        L6_2 = true
        return L6_2
      end
    end
  end
  L1_2 = false
  return L1_2
end

HasCriticalPathBriefings = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2.GetHq
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L2_2 = MrxHqManager
    L2_2 = L2_2.AddStarter
    L3_2 = L1_2
    L4_2 = A0_2
    L2_2(L3_2, L4_2)
  end
  L3_2 = A0_2
  L2_2 = A0_2.HasFanfareBeenDisplayed
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.FanfareDisplayed
    L2_2(L3_2)
    L3_2 = A0_2
    L2_2 = A0_2.IsBoss
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L3_2 = A0_2
      L2_2 = A0_2.GetFaction
      L2_2 = L2_2(L3_2)
      if L2_2 ~= "Pmc" then
    end
    else
      L3_2 = A0_2
      L2_2 = A0_2.GetCardData
      L2_2 = L2_2(L3_2)
      if L2_2 then
      end
    end
  end
  A0_2._bActive = true
  L3_2 = A0_2
  L2_2 = A0_2.RefreshBriefingRoomDisplay
  L2_2(L3_2)
end

Activate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2.GetHq
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L2_2 = MrxHqManager
    L2_2 = L2_2.RemoveStarter
    L3_2 = L1_2
    L4_2 = A0_2
    L2_2(L3_2, L4_2)
  end
  L3_2 = A0_2
  L2_2 = A0_2.Unload
  L2_2(L3_2)
  A0_2._bActive = nil
end

Deactivate = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2._bActive
  return L1_2
end

IsActivated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2._mBriefingModule
  L2_2 = L1_2.SetStarter
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = L1_2.SetBriefingWrapper
  L3_2 = A0_2.tBriefingWrapper
  L2_2(L3_2)
  L2_2 = L1_2.Start
  L2_2()
end

Start = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.tBriefingWrapper
  return L1_2
end

GetBriefingWrapper = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  A0_2._tMissionsToBeAccepted = A1_2
  A0_2._sLastAcceptedMission = A2_2
  L4_2 = A0_2
  L3_2 = A0_2.GetHq
  L3_2 = L3_2(L4_2)
  L5_2 = A0_2
  L4_2 = A0_2.IsPmcStarter
  L4_2 = L4_2(L5_2)
  if L3_2 then
    L5_2 = MrxHqManager
    L5_2 = L5_2.GetHq
    L6_2 = L3_2
    L5_2 = L5_2(L6_2)
    if L5_2 then
      L7_2 = A0_2
      L6_2 = A0_2._CompleteHqExit
      L8_2 = L5_2
      L6_2(L7_2, L8_2)
    end
  elseif L4_2 then
    L5_2 = A2_2 ~= nil
    L6_2 = WifPmcInterior
    L6_2 = L6_2.BriefingComplete
    L7_2 = L5_2
    L6_2(L7_2)
    if A2_2 then
      L6_2 = WifPmcInterior
      L6_2 = L6_2.Exit
      L7_2 = 1
      L8_2 = false
      L6_2(L7_2, L8_2)
    else
      L6_2 = MrxTransit
      L6_2 = L6_2.IsInTransit
      L6_2 = L6_2()
      if not L6_2 then
        L6_2 = MrxState
        L6_2 = L6_2.Exit
        L7_2 = MrxState
        L7_2 = L7_2.STATE_WAITFORGAME
        L6_2(L7_2)
      end
    end
  end
end

End = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = A1_2
  L2_2 = A1_2.ExitBegin
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2.GetPendingContract
  L2_2 = L2_2(L3_2)
  L3_2 = nil
  if L2_2 then
    L4_2 = WifMissionFlow
    L4_2 = L4_2.GetMissionStartLocations
    L5_2 = L2_2
    L4_2 = L4_2(L5_2)
    L3_2 = L4_2
  else
    L5_2 = A1_2
    L4_2 = A1_2.GetEntryLocations
    L4_2 = L4_2(L5_2)
    L3_2 = L4_2
  end
  L4_2 = MrxUtil
  L4_2 = L4_2.TeleportHeroesToLocations
  L5_2 = L3_2
  L6_2 = A1_2.ExitEnd
  L7_2 = {}
  L8_2 = A1_2
  L7_2[1] = L8_2
  L4_2(L5_2, L6_2, L7_2)
end

_CompleteHqExit = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2
  L3_2 = A0_2._bLoaded
  if L3_2 then
    L3_2 = MrxUtil
    L3_2 = L3_2.CallWithOptionalArgs
    L4_2 = A1_2
    L5_2 = A2_2
    L3_2(L4_2, L5_2)
    return
  end
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.GetActor
    L0_3 = L0_3(L1_3)
    if not L0_3 then
      L1_3 = Pg
      L1_3 = L1_3.GetGuidByName
      L2_3 = "Starter"
      L1_3 = L1_3(L2_3)
      L0_3 = L1_3
    end
    if L0_3 then
      L1_3 = A0_2
      L2_3 = L1_3
      L1_3 = L1_3.SetActor
      L3_3 = L0_3
      L1_3(L2_3, L3_3)
      L1_3 = A0_2
      L1_3 = L1_3.sFaceFxSet
      if L1_3 then
        L1_3 = Animation
        L1_3 = L1_3.BindFaceAnimSet
        L2_3 = L0_3
        L3_3 = A0_2
        L3_3 = L3_3.sFaceFxSet
        L1_3 = L1_3(L2_3, L3_3)
      end
    end
    L1_3 = MrxUtil
    L1_3 = L1_3.CallWithOptionalArgs
    L2_3 = A1_2
    L3_3 = A2_2
    L1_3(L2_3, L3_3)
  end
  
  L4_2 = MrxUtil
  L4_2 = L4_2.SetupLoadingCallback
  L5_2 = A0_2
  L6_2 = L3_2
  L4_2(L5_2, L6_2)
  L4_2 = {}
  L5_2 = A0_2
  L4_2[1] = L5_2
  L5_2 = _tAssetLoadTimers
  if not L5_2 then
    L5_2 = {}
  end
  _tAssetLoadTimers = L5_2
  
  function L5_2(A0_3, A1_3, A2_3)
    local L3_3, L4_3, L5_3, L6_3
    L3_3 = _tAssetLoadTimers
    L3_3 = L3_3[A1_3]
    L3_3 = L3_3[A0_3]
    if L3_3 then
      L4_3 = Event
      L4_3 = L4_3.Delete
      L5_3 = L3_3
      L4_3(L5_3)
      L4_3 = _tAssetLoadTimers
      L4_3 = L4_3[A1_3]
      L4_3[A0_3] = nil
      if A2_3 then
      else
      end
      L4_3 = MrxUtil
      L4_3 = L4_3.CallWithOptionalArgs
      L5_3 = MrxUtil
      L5_3 = L5_3.LoadingCallback
      L6_3 = L4_2
      L4_3(L5_3, L6_3)
    else
    end
  end
  
  L6_2 = Net
  L6_2 = L6_2.IsClient
  L6_2 = L6_2()
  if not L6_2 then
    L6_2 = A0_2.tLayers
    if L6_2 then
      L6_2 = A0_2._nLoadPending
      L6_2 = L6_2 + 1
      A0_2._nLoadPending = L6_2
      L6_2 = MrxLayerManager
      L6_2 = L6_2.Add
      L7_2 = A0_2.tLayers
      L8_2 = MrxUtil
      L8_2 = L8_2.LoadingCallback
      L9_2 = L4_2
      L10_2 = true
      L11_2 = true
      L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
    end
    L7_2 = A0_2
    L6_2 = A0_2.IsBoss
    L6_2 = L6_2(L7_2)
    if L6_2 then
      L7_2 = A0_2
      L6_2 = A0_2.GetOfferedBriefings
      L6_2 = L6_2(L7_2)
      L7_2 = {}
      L8_2 = pairs
      L9_2 = L6_2
      L8_2, L9_2, L10_2 = L8_2(L9_2)
      for L11_2, L12_2 in L8_2, L9_2, L10_2 do
        L13_2 = table
        L13_2 = L13_2.insert
        L14_2 = L7_2
        L15_2 = L11_2
        L13_2(L14_2, L15_2)
      end
      L8_2 = L7_2[1]
      L9_2 = WifBriefingData
      L9_2 = L9_2[L8_2]
      if L9_2 then
        L10_2 = L9_2.tActors
        if L10_2 then
          L10_2 = A0_2.tActors
          if not L10_2 then
            L10_2 = {}
          end
          A0_2.tActors = L10_2
          L10_2 = pairs
          L11_2 = L9_2.tActors
          L10_2, L11_2, L12_2 = L10_2(L11_2)
          for L13_2, L14_2 in L10_2, L11_2, L12_2 do
            L15_2 = A0_2.tActors
            L15_2[L13_2] = L14_2
          end
        end
      end
    end
    L6_2 = A0_2.tActors
    if L6_2 then
      L6_2 = {}
      A0_2._tQualityRefs = L6_2
      L6_2 = pairs
      L7_2 = A0_2.tActors
      L6_2, L7_2, L8_2 = L6_2(L7_2)
      for L9_2, L10_2 in L6_2, L7_2, L8_2 do
        L11_2 = L10_2.sUnlockKey
        if L11_2 then
          L11_2 = WifMissionFlow
          L11_2 = L11_2.HasKey
          L12_2 = L10_2.sUnlockKey
          L11_2 = L11_2(L12_2)
          if not L11_2 then
            goto lbl_129
          end
        end
        L11_2 = A0_2._nLoadPending
        L11_2 = L11_2 + 1
        A0_2._nLoadPending = L11_2
        L11_2 = MrxUtil
        L11_2 = L11_2.SpawnActor
        L12_2 = L10_2.sTemplate
        L13_2 = L9_2
        L14_2 = "HqInterior"
        L15_2 = L10_2.sPosition
        L16_2 = nil
        L17_2 = false
        L18_2 = true
        L19_2 = MrxUtil
        L19_2 = L19_2.LoadingCallback
        L20_2 = L4_2
        L11_2 = L11_2(L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
        L12_2 = A0_2._tQualityRefs
        L13_2 = Object
        L13_2 = L13_2.AddQualityRef
        L14_2 = L11_2
        L15_2 = 1
        L13_2 = L13_2(L14_2, L15_2)
        L12_2[L11_2] = L13_2
        ::lbl_129::
      end
    end
  end
  L6_2 = A0_2.tAssetPreload
  if L6_2 then
    L6_2 = pairs
    L7_2 = A0_2.tAssetPreload
    L6_2, L7_2, L8_2 = L6_2(L7_2)
    for L9_2, L10_2 in L6_2, L7_2, L8_2 do
      L11_2 = ipairs
      L12_2 = L10_2
      L11_2, L12_2, L13_2 = L11_2(L12_2)
      for L14_2, L15_2 in L11_2, L12_2, L13_2 do
        L16_2 = A0_2._nLoadPending
        L16_2 = L16_2 + 1
        A0_2._nLoadPending = L16_2
        if L9_2 == "soundbank" or L9_2 == "wavebank" then
          L16_2 = MrxSoundBanks
          L16_2 = L16_2.LoadTempBank
          L17_2 = L15_2
          L18_2 = L9_2
          L19_2 = L5_2
          L20_2 = {}
          L21_2 = L15_2
          L22_2 = L9_2
          L23_2 = false
          L20_2[1] = L21_2
          L20_2[2] = L22_2
          L20_2[3] = L23_2
          L16_2(L17_2, L18_2, L19_2, L20_2)
        else
          L16_2 = Pg
          L16_2 = L16_2.LoadAsset
          L17_2 = L15_2
          L18_2 = L9_2
          L19_2 = L5_2
          L20_2 = {}
          L21_2 = L15_2
          L22_2 = L9_2
          L23_2 = false
          L20_2[1] = L21_2
          L20_2[2] = L22_2
          L20_2[3] = L23_2
          L16_2(L17_2, L18_2, L19_2, L20_2)
        end
        L16_2 = _tAssetLoadTimers
        L17_2 = _tAssetLoadTimers
        L17_2 = L17_2[L9_2]
        if not L17_2 then
          L17_2 = {}
        end
        L16_2[L9_2] = L17_2
        L16_2 = _tAssetLoadTimers
        L16_2 = L16_2[L9_2]
        L17_2 = Event
        L17_2 = L17_2.Create
        L18_2 = Event
        L18_2 = L18_2.TimerRelative
        L19_2 = {}
        L20_2 = 15
        L21_2 = false
        L19_2[1] = L20_2
        L19_2[2] = L21_2
        L20_2 = L5_2
        L21_2 = {}
        L22_2 = L15_2
        L23_2 = L9_2
        L24_2 = true
        L21_2[1] = L22_2
        L21_2[2] = L23_2
        L21_2[3] = L24_2
        L17_2 = L17_2(L18_2, L19_2, L20_2, L21_2)
        L16_2[L15_2] = L17_2
      end
    end
  end
  L6_2 = A0_2.sFaceFxSet
  if L6_2 then
    L6_2 = A0_2._nLoadPending
    L6_2 = L6_2 + 1
    A0_2._nLoadPending = L6_2
    L6_2 = Pg
    L6_2 = L6_2.LoadAsset
    L7_2 = A0_2.sFaceFxSet
    L8_2 = "facefxanimationset"
    L9_2 = MrxUtil
    L9_2 = L9_2.LoadingCallback
    L10_2 = L4_2
    L6_2(L7_2, L8_2, L9_2, L10_2)
  end
  A0_2._bLoaded = true
  L6_2 = A0_2._nLoadPending
  if L6_2 == 0 then
    L6_2 = MrxUtil
    L6_2 = L6_2.CleanupLoadingCallback
    L7_2 = A0_2
    L6_2(L7_2)
    L6_2 = MrxUtil
    L6_2 = L6_2.CallWithOptionalArgs
    L7_2 = A1_2
    L8_2 = A2_2
    L6_2(L7_2, L8_2)
  end
end

Load = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = A0_2._bLoaded
  if not L1_2 then
    return
  end
  L1_2 = Net
  L1_2 = L1_2.IsClient
  L1_2 = L1_2()
  if not L1_2 then
    L1_2 = A0_2.tLayers
    if L1_2 then
      L1_2 = MrxLayerManager
      L1_2 = L1_2.Remove
      L2_2 = A0_2.tLayers
      L3_2 = nil
      L4_2 = nil
      L5_2 = true
      L1_2(L2_2, L3_2, L4_2, L5_2)
    end
    L1_2 = A0_2.tActors
    if L1_2 then
      L1_2 = pairs
      L2_2 = A0_2.tActors
      L1_2, L2_2, L3_2 = L1_2(L2_2)
      for L4_2, L5_2 in L1_2, L2_2, L3_2 do
        L6_2 = Pg
        L6_2 = L6_2.GetGuidByName
        L7_2 = L4_2
        L6_2 = L6_2(L7_2)
        if L6_2 then
          L7_2 = Object
          L7_2 = L7_2.Remove
          L8_2 = L6_2
          L7_2(L8_2)
        end
      end
      L1_2 = A0_2._tQualityRefs
      if L1_2 then
        L1_2 = pairs
        L2_2 = A0_2._tQualityRefs
        L1_2, L2_2, L3_2 = L1_2(L2_2)
        for L4_2, L5_2 in L1_2, L2_2, L3_2 do
          L6_2 = Object
          L6_2 = L6_2.RemoveQualityRef
          L7_2 = L5_2
          L6_2(L7_2)
        end
        A0_2._tQualityRefs = nil
      end
    end
  end
  L1_2 = A0_2.tAssetPreload
  if L1_2 then
    L1_2 = pairs
    L2_2 = A0_2.tAssetPreload
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    for L4_2, L5_2 in L1_2, L2_2, L3_2 do
      L6_2 = ipairs
      L7_2 = L5_2
      L6_2, L7_2, L8_2 = L6_2(L7_2)
      for L9_2, L10_2 in L6_2, L7_2, L8_2 do
        if L4_2 == "soundbank" or L4_2 == "wavebank" then
          L11_2 = MrxSoundBanks
          L11_2 = L11_2.UnloadTempBank
          L12_2 = L10_2
          L13_2 = L4_2
          L11_2(L12_2, L13_2)
        else
          L11_2 = Pg
          L11_2 = L11_2.UnloadAsset
          L12_2 = L10_2
          L13_2 = L4_2
          L11_2(L12_2, L13_2)
        end
      end
    end
  end
  L1_2 = A0_2.sFaceFxSet
  if L1_2 then
    L1_2 = Pg
    L1_2 = L1_2.UnloadAsset
    L2_2 = A0_2.sFaceFxSet
    L3_2 = "facefxanimationset"
    L1_2(L2_2, L3_2)
    L1_2 = Pg
    L1_2 = L1_2.GetGuidByName
    L2_2 = "Starter"
    L1_2 = L1_2(L2_2)
    if L1_2 then
      L2_2 = Animation
      L2_2 = L2_2.UnbindFaceAnimSet
      L3_2 = L1_2
      L4_2 = A0_2.sFaceFxSet
      L2_2 = L2_2(L3_2, L4_2)
    end
  end
  L2_2 = A0_2
  L1_2 = A0_2.SetActor
  L3_2 = nil
  L1_2(L2_2, L3_2)
  A0_2._bLoaded = nil
end

Unload = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2
  L1_2 = A0_2.GetHq
  L1_2 = L1_2(L2_2)
  L3_2 = A0_2
  L2_2 = A0_2.IsPmcStarter
  L2_2 = L2_2(L3_2)
  if L1_2 then
    L3_2 = MrxHqManager
    L3_2 = L3_2.GetHq
    L4_2 = L1_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L5_2 = L3_2
      L4_2 = L3_2.RefreshUiDisplay
      L4_2(L5_2)
    end
  elseif L2_2 then
    L3_2 = WifPmcInterior
    L3_2 = L3_2.RefreshUiDisplay
    L3_2()
  end
end

RefreshBriefingRoomDisplay = L0_1

function L0_1(A0_2, A1_2)
  A0_2._mBriefingModule = A1_2
end

SetBriefingModule = L0_1

function L0_1(A0_2, A1_2)
  A0_2._sSpecialCaseGreeting = A1_2
end

SetSpecialCaseGreeting = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2._sSpecialCaseGreeting
  return L1_2
end

GetSpecialCaseGreeting = L0_1
