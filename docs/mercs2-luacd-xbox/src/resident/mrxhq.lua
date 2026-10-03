local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiBootstrap"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxHqManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxLayerManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxStarterManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTransit"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPlayState"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifFreePlay"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifMissionData"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifMissionFlow"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifVzBoundary"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSound"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifHqData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxState"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)
L0_1 = {}
L1_1 = {}
L2_1 = {}
L3_1 = "player_chris_job_briefing_greeting"
L4_1 = "player_chris_job_briefing_idle"
L5_1 = "player_chris_job_briefing_no"
L6_1 = "player_chris_job_briefing_yes"
L7_1 = "player_chris_job_briefing_spiel"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L2_1[4] = L6_1
L2_1[5] = L7_1
L1_1.Chris = L2_1
L2_1 = {}
L3_1 = "player_jennifer_job_briefing_greeting"
L4_1 = "player_jennifer_job_briefing_idle"
L5_1 = "player_jennifer_job_briefing_no"
L6_1 = "player_jennifer_job_briefing_yes"
L7_1 = "player_jennifer_job_briefing_spiel"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L2_1[4] = L6_1
L2_1[5] = L7_1
L1_1.Jennifer = L2_1
L2_1 = {}
L3_1 = "player_mattias_job_briefing_greeting_fb"
L4_1 = "player_mattias_job_briefing_idle_fb"
L5_1 = "player_mattias_job_briefing_no_fb"
L6_1 = "player_mattias_job_briefing_yes_fb"
L7_1 = "player_mattias_job_briefing_spiel_fb"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L2_1[4] = L6_1
L2_1[5] = L7_1
L1_1.Mattias = L2_1
L2_1 = {}
L3_1 = "all_starter02_job_briefing_idle"
L4_1 = "all_starter02_job_briefing_greeting_neutral"
L5_1 = "all_starter02_job_briefing_greeting_happy"
L6_1 = "all_starter02_job_briefing_greeting_angry"
L7_1 = "all_starter02_job_briefing_spiel"
L8_1 = "all_starter02_job_briefing_goodbye"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L2_1[4] = L6_1
L2_1[5] = L7_1
L2_1[6] = L8_1
L1_1.MaleStarter = L2_1
L2_1 = {}
L3_1 = "all_starter03_job_briefing_idle"
L4_1 = "all_starter03_job_briefing_greeting_neutral"
L5_1 = "all_starter03_job_briefing_greeting_happy"
L6_1 = "all_starter03_job_briefing_greeting_angry"
L7_1 = "all_starter03_job_briefing_spiel"
L8_1 = "all_starter03_job_briefing_goodbye"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L2_1[4] = L6_1
L2_1[5] = L7_1
L2_1[6] = L8_1
L1_1.FemaleStarter = L2_1
L0_1.animation = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "Global_Job_Briefing_Chris"
L2_1[1] = L3_1
L1_1.Chris = L2_1
L2_1 = {}
L3_1 = "Global_Job_Briefing_Jennifer"
L2_1[1] = L3_1
L1_1.Jennifer = L2_1
L2_1 = {}
L3_1 = "Global_Job_Briefing_Mattias"
L2_1[1] = L3_1
L1_1.Mattias = L2_1
L0_1.facefxanimationset = L1_1
L1_1 = {}
L2_1 = "vo_job_heros"
L1_1[1] = L2_1
L0_1.wavebank = L1_1
L1_1 = {}
L2_1 = "vo_job_heros"
L1_1[1] = L2_1
L0_1.soundbank = L1_1
_tAssetPreload = L0_1
L0_1 = nil
_NetSafeBriefingModule = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = GlobalEnter
  L2_2 = false
  L1_2(L2_2)
  _NetSafeBriefingModule = A0_2
  L1_2 = _NetSafeBriefingModule
  L1_2 = L1_2.NetSafeLoadBriefingAssets
  L2_2 = _tAssetPreload
  L1_2(L2_2)
  L1_2 = MrxState
  L1_2 = L1_2.Exit
  L2_2 = MrxState
  L2_2 = L2_2.STATE_WAITFORGAME
  L1_2(L2_2)
end

NetSafeBriefingModuleLoaded = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = dynamic_import
  L1_2 = "MrxBriefing"
  L2_2 = NetSafeBriefingModuleLoaded
  L0_2(L1_2, L2_2)
end

NetSafeLoadAssets1 = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = MrxState
  L0_2 = L0_2.Enter
  L1_2 = MrxState
  L1_2 = L1_2.STATE_WAITFORGAME
  L2_2 = NetSafeLoadAssets1
  L0_2(L1_2, L2_2)
end

NetSafeLoadAssets = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _NetSafeBriefingModule
  if L0_2 then
    L0_2 = GlobalExit
    L1_2 = false
    L0_2(L1_2)
    L0_2 = _NetSafeBriefingModule
    L0_2 = L0_2.NetSafeUnloadBriefingAssets
    L1_2 = _tAssetPreload
    L0_2(L1_2)
    L0_2 = dynamic_remove
    L1_2 = "MrxBriefing"
    L0_2(L1_2)
    L0_2 = nil
    _NetSafeBriefingModule = L0_2
  end
end

NetSafeUnloadAssets = L0_1

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
  A1_2._bLocked = true
  A1_2._bInside = false
  A1_2._tStarter = nil
  return A1_2
end

Create = L0_1

function L0_1(A0_2, A1_2)
  A0_2._sName = A1_2
end

SetName = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2._sName
  return L1_2
end

GetName = L0_1

function L0_1(A0_2, A1_2)
  A0_2._bLocked = A1_2
end

SetLock = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2._bLocked
  return L1_2
end

IsLocked = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.sRadarIcon
  return L1_2
end

GetRadarIcon = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.sAtmosphere
  return L1_2
end

GetAtmosphere = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.nDrawDistance
  if not L1_2 then
    L1_2 = 50
  end
  return L1_2
end

GetDrawDistance = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = {}
  L2_2 = A0_2.tPortal
  L2_2 = L2_2.sStart1
  L3_2 = A0_2.tPortal
  L3_2 = L3_2.sStart2
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  return L1_2
end

GetEntryLocations = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.sBuildingName
  return L1_2
end

GetBuildingName = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2._tStarter
  if L1_2 then
    L1_2 = A0_2._tStarter
    L2_2 = L1_2
    L1_2 = L1_2.GetFaction
    return L1_2(L2_2)
  end
end

GetFaction = L0_1

function L0_1(A0_2, A1_2)
  A0_2._bRespawn = A1_2
end

SetRespawn = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2._bRespawn
  return L1_2
end

GetRespawn = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2)
  local L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2
  L7_2 = WifHqData
  L7_2 = L7_2.GetHqIdFromIndex
  L8_2 = A0_2
  L7_2 = L7_2(L8_2)
  L8_2 = WifHqData
  L8_2 = L8_2.GetHqConfigFromId
  L9_2 = L7_2
  L8_2 = L8_2(L9_2)
  L9_2 = L7_2
  L10_2 = "::Portal"
  L9_2 = L9_2 .. L10_2
  L10_2 = Pg
  L10_2 = L10_2.GetGuidByName
  L11_2 = L8_2.tPortal
  L11_2 = L11_2.sEntrance
  L10_2 = L10_2(L11_2)
  L11_2 = ""
  if not A6_2 then
    L11_2 = L8_2.sPdaIconLocked
  else
    L11_2 = L8_2.sPdaIcon
  end
  L12_2 = MrxFactionManager
  L12_2 = L12_2.GetFactionIdFromIndex
  L13_2 = A2_2
  L12_2 = L12_2(L13_2)
  L13_2 = L8_2.nLandingZone
  L14_2 = AddHqPdaBlip
  L15_2 = L9_2
  L16_2 = L10_2
  L17_2 = L11_2
  L18_2 = A1_2
  L19_2 = L12_2
  L20_2 = A3_2
  L21_2 = A4_2
  L22_2 = A5_2
  L23_2 = L13_2
  L14_2(L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2)
end

NetSafeAddHqPdaBlip = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L1_2 = ""
  L2_2 = pairs
  L3_2 = A0_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = WifMissionData
    L7_2 = L7_2.GetMissionTitle
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    L8_2 = WifMissionData
    L8_2 = L8_2.GetMissionFaction
    L9_2 = L6_2
    L8_2 = L8_2(L9_2)
    L9_2 = ""
    if L8_2 then
      L10_2 = MrxFactionManager
      L10_2 = L10_2.GetInlineIcon
      L11_2 = L8_2
      L10_2 = L10_2(L11_2)
      L11_2 = " "
      L9_2 = L10_2 .. L11_2
    end
    L10_2 = L1_2
    L11_2 = L9_2
    L12_2 = "\""
    L13_2 = L7_2
    L14_2 = "\""
    L1_2 = L10_2 .. L11_2 .. L12_2 .. L13_2 .. L14_2
    L10_2 = WifMissionData
    L10_2 = L10_2.GetMissionRepeatable
    L11_2 = L6_2
    L10_2 = L10_2(L11_2)
    if L10_2 then
      L10_2 = WifMissionFlow
      L10_2 = L10_2.GetKeyValue
      L11_2 = L6_2
      L10_2 = L10_2(L11_2)
      L11_2 = L10_2 + 1
      L12_2 = WifMissionData
      L12_2 = L12_2.GetMissionLevels
      L13_2 = L6_2
      L12_2 = L12_2(L13_2)
      if L11_2 > L12_2 then
        L11_2 = L12_2
      end
      L13_2 = L1_2
      L14_2 = " ([Generic.Level] "
      L15_2 = L11_2
      L16_2 = ")"
      L1_2 = L13_2 .. L14_2 .. L15_2 .. L16_2
    end
    L10_2 = L1_2
    L11_2 = "\n"
    L1_2 = L10_2 .. L11_2
  end
  return L1_2
end

GetMissionDesc = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2, A9_2)
  local L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2
  L10_2 = ""
  if not A7_2 then
    L11_2 = L10_2
    L12_2 = "[cash] [Briefing.Shop]\n"
    L10_2 = L11_2 .. L12_2
  end
  if A8_2 then
    L11_2 = MrxTransit
    L11_2 = L11_2.IsLocationEnabled
    L12_2 = A8_2
    L11_2 = L11_2(L12_2)
    if L11_2 then
      L11_2 = L10_2
      L12_2 = "[vehheli] [Briefing.Transit]\n"
      L10_2 = L11_2 .. L12_2
    end
  end
  if L10_2 ~= "" then
    L11_2 = L10_2
    L12_2 = "\n"
    L10_2 = L11_2 .. L12_2
  end
  L11_2 = L10_2
  L12_2 = "[PDA.Map.WorkAvailableHeader]\n"
  L10_2 = L11_2 .. L12_2
  L11_2 = 0
  L12_2 = {}
  L13_2 = {}
  L14_2 = pairs
  L15_2 = A6_2
  L14_2, L15_2, L16_2 = L14_2(L15_2)
  for L17_2, L18_2 in L14_2, L15_2, L16_2 do
    L19_2 = WifMissionData
    L19_2 = L19_2.GetMissionIdFromIndex
    L20_2 = L18_2
    L19_2 = L19_2(L20_2)
    L20_2 = WifMissionData
    L20_2 = L20_2.IsMissionOnCriticalPath
    L21_2 = L19_2
    L20_2 = L20_2(L21_2)
    if L20_2 then
      L21_2 = table
      L21_2 = L21_2.insert
      L22_2 = L12_2
      L23_2 = L19_2
      L21_2(L22_2, L23_2)
    else
      L21_2 = table
      L21_2 = L21_2.insert
      L22_2 = L13_2
      L23_2 = L19_2
      L21_2(L22_2, L23_2)
    end
    L11_2 = L11_2 + 1
  end
  L14_2 = table
  L14_2 = L14_2.sort
  L15_2 = L12_2
  L14_2(L15_2)
  L14_2 = table
  L14_2 = L14_2.sort
  L15_2 = L13_2
  L14_2(L15_2)
  if L11_2 <= 0 then
    L14_2 = L10_2
    L15_2 = "([Generic.None])"
    L10_2 = L14_2 .. L15_2
  else
    L14_2 = table
    L14_2 = L14_2.getn
    L15_2 = L12_2
    L14_2 = L14_2(L15_2)
    if 0 < L14_2 then
      L14_2 = L10_2
      L15_2 = GetMissionDesc
      L16_2 = L12_2
      L15_2 = L15_2(L16_2)
      L10_2 = L14_2 .. L15_2
    end
    L14_2 = table
    L14_2 = L14_2.getn
    L15_2 = L13_2
    L14_2 = L14_2(L15_2)
    if 0 < L14_2 then
      L14_2 = L10_2
      L15_2 = GetMissionDesc
      L16_2 = L13_2
      L15_2 = L15_2(L16_2)
      L10_2 = L14_2 .. L15_2
    end
  end
  if A9_2 then
    L14_2 = nil
    if A9_2 == "Friendly" then
      L14_2 = "[Generic.HQ.FriendlyPDA]"
    elseif A9_2 == "Neutral" then
      L14_2 = "[Generic.HQ.NeutralPDA]"
    elseif A9_2 == "NoEntry" then
      L14_2 = "[Generic.HQ.NoEntryPDA]"
    end
    if L14_2 then
      L15_2 = L14_2
      L16_2 = [[


]]
      L17_2 = L10_2
      L10_2 = L15_2 .. L16_2 .. L17_2
    end
  end
  L14_2 = MrxFactionManager
  L14_2 = L14_2.GetPdaFactionIdFromFactionId
  L15_2 = A4_2
  L14_2 = L14_2(L15_2)
  if not L14_2 then
    L14_2 = "PMC"
  end
  L15_2 = Pda
  L15_2 = L15_2.Map
  L16_2 = L15_2
  L15_2 = L15_2.AddBlip
  L17_2 = {}
  L17_2.sName = A0_2
  L17_2.uGuid = A1_2
  L17_2.sLabel = A5_2
  L17_2.sDesc = L10_2
  L17_2.sTexture = A2_2
  L17_2.bSticky = A3_2
  L17_2.sMission = nil
  L17_2.sFaction = L14_2
  L17_2.bTodoList = false
  L17_2.nSortOrder = 4
  L17_2.bDontNetSync = true
  L15_2(L16_2, L17_2)
end

AddHqPdaBlip = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = WifHqData
  L1_2 = L1_2.GetHqIdFromIndex
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2
  L3_2 = "::Portal"
  L2_2 = L2_2 .. L3_2
  L3_2 = RemoveHqPdaBlip
  L4_2 = L2_2
  L3_2(L4_2)
end

NetSafeRemoveHqPdaBlip = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Pda
  L1_2 = L1_2.Map
  L2_2 = L1_2
  L1_2 = L1_2.RemoveBlip
  L3_2 = {}
  L3_2.sName = A0_2
  L3_2.bDontNetSync = true
  L1_2(L2_2, L3_2)
end

RemoveHqPdaBlip = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2
  L1_2 = Net
  L1_2 = L1_2.IsClient
  L1_2 = L1_2()
  if L1_2 then
    return
  end
  L1_2 = false
  L2_2 = MrxPlayState
  L2_2 = L2_2.IsFree
  L2_2 = L2_2()
  L3_2 = A0_2._bInside
  L4_2 = nil
  L5_2 = nil
  L6_2 = nil
  L7_2 = A0_2.sRadarIcon
  L9_2 = A0_2
  L8_2 = A0_2.GetFaction
  L8_2 = L8_2(L9_2)
  L9_2 = true
  L10_2 = true
  L11_2 = nil
  L12_2 = A0_2._tStarter
  if L12_2 then
    L12_2 = A0_2._tStarter
    L13_2 = L12_2
    L12_2 = L12_2._GetBriefingCount
    L12_2 = L12_2(L13_2)
    L4_2 = 0 < L12_2
    L12_2 = A0_2._tStarter
    L13_2 = L12_2
    L12_2 = L12_2.IsBoss
    L12_2 = L12_2(L13_2)
    L5_2 = L12_2
    L12_2 = A0_2._tStarter
    L13_2 = L12_2
    L12_2 = L12_2.HasCriticalPathBriefings
    L12_2 = L12_2(L13_2)
    L6_2 = L12_2
    L12_2 = MrxFactionManager
    L12_2 = L12_2.IsAttitudeMutable
    L13_2 = L8_2
    L12_2 = L12_2(L13_2)
    if L12_2 then
      L12_2 = "Neutral"
      if L5_2 then
        L12_2 = "Friendly"
      end
      L13_2 = MrxFactionManager
      L13_2 = L13_2.TestAttitude
      L14_2 = L8_2
      L15_2 = "Pmc"
      L16_2 = ">="
      L17_2 = L12_2
      L13_2 = L13_2(L14_2, L15_2, L16_2, L17_2)
      L9_2 = L13_2
      if L10_2 then
        L10_2 = L9_2
      end
    end
    L12_2 = A0_2._tStarter
    L13_2 = L12_2
    L12_2 = L12_2.HasShop
    L12_2 = L12_2(L13_2)
    L1_2 = not L3_2
    L13_2 = A0_2._tStarter
    L14_2 = L13_2
    L13_2 = L13_2.GetActionDisplay
    L13_2 = L13_2(L14_2)
    L11_2 = L13_2
    if L5_2 then
      L10_2 = L4_2 or L10_2
      if L10_2 and L4_2 then
        L10_2 = L2_2
      end
    else
      L10_2 = L4_2 or L10_2
      if L10_2 and not L4_2 then
        L10_2 = L12_2
      end
    end
  else
  end
  if L1_2 then
    L13_2 = A0_2
    L12_2 = A0_2.IsLocked
    L12_2 = L12_2(L13_2)
    L1_2 = not L12_2
  end
  if not L10_2 then
    if L5_2 then
      if not L2_2 then
        A0_2.sLockStatusMessage = "NoEntry"
      elseif not L4_2 then
        A0_2.sLockStatusMessage = "NoContract"
      else
        A0_2.sLockStatusMessage = "Friendly"
      end
    else
      A0_2.sLockStatusMessage = "Neutral"
    end
  else
    A0_2.sLockStatusMessage = nil
  end
  L13_2 = A0_2
  L12_2 = A0_2.SetPortal
  L14_2 = L1_2
  L15_2 = L11_2
  L12_2(L13_2, L14_2, L15_2)
  L13_2 = A0_2
  L12_2 = A0_2.GetName
  L12_2 = L12_2(L13_2)
  L13_2 = "::Portal"
  L12_2 = L12_2 .. L13_2
  L13_2 = WifHqData
  L13_2 = L13_2.GetHqIndexFromId
  L15_2 = A0_2
  L14_2 = A0_2.GetName
  L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2 = L14_2(L15_2)
  L13_2 = L13_2(L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2)
  if L1_2 then
    if not L10_2 then
      L14_2 = A0_2.sRadarIconLocked
      if L14_2 then
        L7_2 = A0_2.sRadarIconLocked
      end
    end
    if L5_2 then
      L14_2 = 8
      if L14_2 then
        goto lbl_129
      end
    end
    L14_2 = 6
    ::lbl_129::
    L15_2 = L2_2 or L15_2
    L15_2 = L4_2 or L15_2
    if L2_2 and L4_2 then
      L15_2 = L6_2
    end
    L16_2 = Pg
    L16_2 = L16_2.GetGuidByName
    L17_2 = A0_2.tPortal
    L17_2 = L17_2.sEntrance
    L16_2 = L16_2(L17_2)
    L17_2 = Hud
    L17_2 = L17_2.Radar
    L18_2 = L17_2
    L17_2 = L17_2.AddObjective
    L19_2 = {}
    L19_2.sName = L12_2
    L19_2.uGuid = L16_2
    L19_2.nR = 255
    L19_2.nG = 255
    L19_2.nB = 255
    L19_2.nWidth = L14_2
    L19_2.nHeight = L14_2
    L19_2.sTexture = L7_2
    L19_2.bSticky = L15_2
    if L5_2 then
      L20_2 = 5
      if L20_2 then
        goto lbl_158
      end
    end
    L20_2 = 6
    ::lbl_158::
    L19_2.nSortOrder = L20_2
    L17_2(L18_2, L19_2)
    L17_2 = {}
    L18_2 = 0
    L19_2 = A0_2._tStarter
    L20_2 = L19_2
    L19_2 = L19_2.GetOfferedBriefings
    L19_2 = L19_2(L20_2)
    L20_2 = pairs
    L21_2 = L19_2
    L20_2, L21_2, L22_2 = L20_2(L21_2)
    for L23_2, L24_2 in L20_2, L21_2, L22_2 do
      L18_2 = L18_2 + 1
      L25_2 = WifMissionData
      L25_2 = L25_2.GetMissionIndexFromId
      L26_2 = L23_2
      L25_2 = L25_2(L26_2)
      L17_2[L18_2] = L25_2
    end
    L20_2 = 0
    if L15_2 ~= nil then
      if L15_2 == true then
        L20_2 = 1
      else
        L20_2 = 2
      end
    end
    L21_2 = A0_2.sPdaIcon
    if not L10_2 then
      L22_2 = A0_2.sPdaIconLocked
      if L22_2 then
        L21_2 = A0_2.sPdaIconLocked
      end
    end
    L23_2 = A0_2
    L22_2 = A0_2.GetFaction
    L22_2 = L22_2(L23_2)
    L23_2 = MrxFactionManager
    L23_2 = L23_2.GetIndexFromFactionId
    L24_2 = L22_2
    L23_2 = L23_2(L24_2)
    L24_2 = "UNNAMED"
    L25_2 = A0_2.sBlipLabel
    if L25_2 then
      L24_2 = A0_2.sBlipLabel
    elseif not L5_2 then
      L25_2 = A0_2.nLandingZone
      if L25_2 then
        L25_2 = MrxTransit
        L25_2 = L25_2.GetName
        L26_2 = A0_2.nLandingZone
        L25_2 = L25_2(L26_2)
        L24_2 = L25_2
      end
    end
    L25_2 = Net
    L25_2 = L25_2.SendEvent_AddHqPdaBlip
    L26_2 = L13_2
    L27_2 = L20_2
    L28_2 = L23_2
    L29_2 = L24_2
    L30_2 = L17_2
    L31_2 = L5_2
    L32_2 = L10_2
    L25_2(L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2)
    L25_2 = AddHqPdaBlip
    L26_2 = L12_2
    L27_2 = L16_2
    L28_2 = L21_2
    L29_2 = L15_2
    L30_2 = L22_2
    L31_2 = L24_2
    L32_2 = L17_2
    L33_2 = L5_2
    L34_2 = A0_2.nLandingZone
    L35_2 = A0_2.sLockStatusMessage
    L25_2(L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2)
  else
    L14_2 = Hud
    L14_2 = L14_2.Radar
    L15_2 = L14_2
    L14_2 = L14_2.RemoveObjective
    L16_2 = {}
    L16_2.sName = L12_2
    L14_2(L15_2, L16_2)
    L14_2 = Net
    L14_2 = L14_2.SendEvent_RemoveHqPdaBlip
    L15_2 = L13_2
    L14_2(L15_2)
    L14_2 = RemoveHqPdaBlip
    L15_2 = L12_2
    L14_2(L15_2)
  end
end

RefreshUiDisplay = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2
  if A1_2 then
  else
  end
  L3_2 = A0_2.tPortal
  L4_2 = L3_2.sEntrance
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = L4_2
  L5_2 = L5_2(L6_2)
  L6_2 = true
  if A1_2 then
    L7_2 = true
    L9_2 = A0_2
    L8_2 = A0_2.GetFaction
    L8_2 = L8_2(L9_2)
    L9_2 = A0_2._tStarter
    L10_2 = L9_2
    L9_2 = L9_2.IsBoss
    L9_2 = L9_2(L10_2)
    L10_2 = MrxFactionManager
    L10_2 = L10_2.IsAttitudeMutable
    L11_2 = L8_2
    L10_2 = L10_2(L11_2)
    if L10_2 then
      L10_2 = "Neutral"
      if L9_2 then
        L10_2 = "Friendly"
      end
      L11_2 = MrxFactionManager
      L11_2 = L11_2.TestAttitude
      L12_2 = L8_2
      L13_2 = "Pmc"
      L14_2 = ">="
      L15_2 = L10_2
      L11_2 = L11_2(L12_2, L13_2, L14_2, L15_2)
      L7_2 = L11_2
      if L6_2 then
        L6_2 = L7_2
      end
    end
    L10_2 = Pg
    L10_2 = L10_2.RemoveContextAction
    L11_2 = L5_2
    L10_2(L11_2)
    L10_2 = A0_2._uEvent
    if L10_2 then
      L10_2 = Event
      L10_2 = L10_2.Delete
      L11_2 = A0_2._uEvent
      L10_2(L11_2)
      A0_2._uEvent = nil
    end
    L10_2 = HideTutorialMessage
    L11_2 = A0_2
    L10_2(L11_2)
    L10_2 = A0_2._uMarker
    if L10_2 then
      L10_2 = Marker
      L10_2 = L10_2.Remove
      L11_2 = A0_2._uMarker
      L10_2(L11_2)
      L10_2 = Net
      L10_2 = L10_2.IsServer
      L10_2 = L10_2()
      if L10_2 then
        L10_2 = Net
        L10_2 = L10_2.SendEvent_RemoveMarkerObjective
        L11_2 = A0_2._uMarker
        L10_2(L11_2)
      end
      A0_2._uMarker = nil
    end
    L10_2 = A0_2._tStarter
    L11_2 = L10_2
    L10_2 = L10_2._GetBriefingCount
    L10_2 = L10_2(L11_2)
    L10_2 = 0 < L10_2
    L11_2 = MrxPlayState
    L11_2 = L11_2.IsFree
    L11_2 = L11_2()
    L12_2 = A0_2._tStarter
    L13_2 = L12_2
    L12_2 = L12_2.HasShop
    L12_2 = L12_2(L13_2)
    if L9_2 then
      L6_2 = L10_2 or L6_2
      if L6_2 and L10_2 then
        L6_2 = L11_2
      end
    else
      L6_2 = L10_2 or L6_2
      if L6_2 and not L10_2 then
        L6_2 = L12_2
      end
    end
    L13_2 = "[ContextAction.Enter]"
    if A2_2 then
      L13_2 = A2_2
    end
    L14_2 = A0_2._OnEnter
    if not L6_2 then
      L15_2 = "[neut]"
      L16_2 = L13_2
      L13_2 = L15_2 .. L16_2
      L14_2 = A0_2._LockedOnEnter
    end
    L15_2 = Pg
    L15_2 = L15_2.AddContextAction
    L16_2 = L5_2
    L17_2 = L13_2
    L18_2 = 2
    L19_2 = 0
    L20_2 = 0
    L21_2 = 255
    L22_2 = 2
    L23_2 = false
    L15_2(L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2)
    L15_2 = Event
    L15_2 = L15_2.CreatePersistent
    L16_2 = Event
    L16_2 = L16_2.ContextAction
    L17_2 = {}
    L18_2 = 0
    L19_2 = L5_2
    L17_2[1] = L18_2
    L17_2[2] = L19_2
    L18_2 = L14_2
    L19_2 = {}
    L20_2 = A0_2
    L19_2[1] = L20_2
    L15_2 = L15_2(L16_2, L17_2, L18_2, L19_2)
    A0_2._uEvent = L15_2
    L15_2 = nil
    L16_2 = nil
    L17_2 = nil
    L18_2 = nil
    L19_2 = nil
    L20_2 = nil
    L21_2 = nil
    if L8_2 == "Pmc" then
      L22_2 = {}
      L22_2.Pmc = "HUD_objective_action"
      L15_2 = L22_2
      L22_2 = MrxUtil
      L22_2 = L22_2.GetPrimaryObjectiveRgb
      L22_2, L23_2, L24_2 = L22_2()
      L18_2 = L24_2
      L17_2 = L23_2
      L16_2 = L22_2
      L22_2 = MrxUtil
      L22_2 = L22_2.GetPrimaryObjectiveRgb
      L22_2, L23_2, L24_2 = L22_2()
      L21_2 = L24_2
      L20_2 = L23_2
      L19_2 = L22_2
    elseif L9_2 then
      if L6_2 then
        L22_2 = {}
        L22_2.All = "HUD_HQ_AN"
        L22_2.Chi = "HUD_HQ_CH"
        L22_2.Gur = "HUD_HQ_GR"
        L22_2.Oil = "HUD_HQ_OC"
        L15_2 = L22_2
      else
        L22_2 = {}
        L22_2.All = "HUD_HQ_AN_locked"
        L22_2.Chi = "HUD_HQ_CH_locked"
        L22_2.Gur = "HUD_HQ_GR_locked"
        L22_2.Oil = "HUD_HQ_OC_locked"
        L15_2 = L22_2
      end
      L22_2 = 255
      L23_2 = 255
      L18_2 = 255
      L17_2 = L23_2
      L16_2 = L22_2
      L22_2 = MrxUtil
      L22_2 = L22_2.GetPrimaryObjectiveRgb
      L22_2, L23_2, L24_2 = L22_2()
      L21_2 = L24_2
      L20_2 = L23_2
      L19_2 = L22_2
    else
      if L6_2 then
        L22_2 = {}
        L22_2.All = "HUD_Outpost_AN"
        L22_2.Chi = "HUD_Outpost_CH"
        L22_2.Gur = "HUD_Outpost_GR"
        L22_2.Oil = "HUD_Outpost_OC"
        L22_2.Pir = "HUD_Outpost_PR"
        L15_2 = L22_2
      else
        L22_2 = {}
        L22_2.All = "HUD_Outpost_AN_locked"
        L22_2.Chi = "HUD_Outpost_CH_locked"
        L22_2.Gur = "HUD_Outpost_GR_locked"
        L22_2.Oil = "HUD_Outpost_OC_locked"
        L22_2.Pir = "HUD_Outpost_PR_locked"
        L15_2 = L22_2
      end
      L22_2 = 255
      L23_2 = 255
      L18_2 = 255
      L17_2 = L23_2
      L16_2 = L22_2
      L22_2 = MrxUtil
      L22_2 = L22_2.GetSecondaryObjectiveRgb
      L22_2, L23_2, L24_2 = L22_2()
      L21_2 = L24_2
      L20_2 = L23_2
      L19_2 = L22_2
    end
    L22_2 = L15_2[L8_2]
    L23_2 = A0_2.sWorldIcon
    if L23_2 then
      L22_2 = A0_2.sWorldIcon
    end
    L23_2 = Marker
    L23_2 = L23_2.AddBlip
    L24_2 = L5_2
    L25_2 = L22_2
    L26_2 = 32
    L27_2 = L16_2
    L28_2 = L17_2
    L29_2 = L18_2
    L30_2 = 255
    L31_2 = 1.25
    L32_2 = 5
    L33_2 = 175
    L23_2 = L23_2(L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2)
    A0_2._uMarker = L23_2
    L23_2 = Net
    L23_2 = L23_2.IsServer
    L23_2 = L23_2()
    if L23_2 then
      L23_2 = Net
      L23_2 = L23_2.SendEvent_AddMarkerObjective
      L24_2 = L5_2
      L25_2 = A0_2._uMarker
      L26_2 = L16_2
      L27_2 = L17_2
      L28_2 = L18_2
      L29_2 = 1.25
      L30_2 = MrxUtil
      L30_2 = L30_2.MarkerGetIndexByName_World
      L31_2 = L22_2 or L31_2
      if not L22_2 then
        L31_2 = ""
      end
      L30_2 = L30_2(L31_2)
      L31_2 = 1
      L32_2 = 16
      L33_2 = false
      L34_2 = 5
      L35_2 = 175
      L23_2(L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2)
    end
    L23_2 = A0_2._uDisc
    if not L23_2 then
      L23_2 = Marker
      L23_2 = L23_2.AddDisc
      L24_2 = L5_2
      L25_2 = 0.5
      L26_2 = L19_2
      L27_2 = L20_2
      L28_2 = L21_2
      L29_2 = 0.025
      L23_2 = L23_2(L24_2, L25_2, L26_2, L27_2, L28_2, L29_2)
      A0_2._uDisc = L23_2
      L23_2 = Net
      L23_2 = L23_2.IsServer
      L23_2 = L23_2()
      if L23_2 then
        L23_2 = Net
        L23_2 = L23_2.SendEvent_AddMarkerObjective
        L24_2 = L5_2
        L25_2 = A0_2._uDisc
        L26_2 = L19_2
        L27_2 = L20_2
        L28_2 = L21_2
        L29_2 = 0.025
        L30_2 = 0
        L31_2 = 0.5
        L32_2 = 0
        L33_2 = true
        L23_2(L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2)
      end
    end
  else
    L7_2 = Pg
    L7_2 = L7_2.RemoveContextAction
    L8_2 = L5_2
    L7_2(L8_2)
    L7_2 = A0_2._uEvent
    if L7_2 then
      L7_2 = Event
      L7_2 = L7_2.Delete
      L8_2 = A0_2._uEvent
      L7_2(L8_2)
      A0_2._uEvent = nil
    end
    L7_2 = HideTutorialMessage
    L8_2 = A0_2
    L7_2(L8_2)
    L7_2 = A0_2._uMarker
    if L7_2 then
      L7_2 = Marker
      L7_2 = L7_2.Remove
      L8_2 = A0_2._uMarker
      L7_2(L8_2)
      L7_2 = Net
      L7_2 = L7_2.IsServer
      L7_2 = L7_2()
      if L7_2 then
        L7_2 = Net
        L7_2 = L7_2.SendEvent_RemoveMarkerObjective
        L8_2 = A0_2._uMarker
        L7_2(L8_2)
      end
      A0_2._uMarker = nil
    end
    L7_2 = A0_2._uDisc
    if L7_2 then
      L7_2 = Marker
      L7_2 = L7_2.Remove
      L8_2 = A0_2._uDisc
      L7_2(L8_2)
      L7_2 = Net
      L7_2 = L7_2.IsServer
      L7_2 = L7_2()
      if L7_2 then
        L7_2 = Net
        L7_2 = L7_2.SendEvent_RemoveMarkerObjective
        L8_2 = A0_2._uDisc
        L7_2(L8_2)
      end
      A0_2._uDisc = nil
    end
  end
end

SetPortal = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2._tStarter
  if L2_2 then
    return
  end
  A0_2._tStarter = A1_2
  L2_2 = A0_2.nLandingZone
  L3_2 = A0_2.sLzUnlockStyle
  if L2_2 and L3_2 == "auto" then
    L4_2 = MrxTransit
    L4_2 = L4_2.SetLocationEnabled
    L5_2 = L2_2
    L7_2 = A0_2
    L6_2 = A0_2.GetFaction
    L6_2, L7_2 = L6_2(L7_2)
    L4_2(L5_2, L6_2, L7_2)
    L5_2 = A0_2
    L4_2 = A0_2.RefreshUiDisplay
    L4_2(L5_2)
  end
end

AddStarter = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = A0_2._tStarter
  if L2_2 ~= A1_2 then
    return
  end
  A0_2._tStarter = nil
  L3_2 = A0_2
  L2_2 = A0_2.RefreshUiDisplay
  L2_2(L3_2)
end

RemoveStarter = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2._tStarter
  return L1_2
end

GetStarter = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = MrxFactionManager
  L1_2 = L1_2.DisableReporting
  L2_2 = true
  L1_2(L2_2)
  L1_2 = WifVzBoundary
  L1_2 = L1_2.SetInteriorMode
  L2_2 = true
  L1_2(L2_2)
  L1_2 = _ToggleHuds
  L2_2 = false
  L1_2(L2_2)
  L1_2 = MrxUtil
  L1_2 = L1_2.EnableHeroWeapons
  L2_2 = false
  L1_2(L2_2)
  L1_2 = MrxSound
  L1_2 = L1_2.EnterInterior
  L1_2()
  L1_2 = MrxLayerManager
  L1_2 = L1_2.ProcessMarkedLayers
  L1_2()
  L1_2 = Player
  L1_2 = L1_2.GetAllPlayers
  L1_2 = L1_2()
  L2_2 = ipairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = Player
    L7_2 = L7_2.GetCharacter
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    L8_2 = Object
    L8_2 = L8_2.SetInvincible
    L9_2 = L7_2
    L10_2 = true
    L11_2 = "HQ"
    L8_2(L9_2, L10_2, L11_2)
  end
end

GlobalEnter = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L0_2 = MrxFactionManager
  L0_2 = L0_2.DisableReporting
  L1_2 = false
  L0_2(L1_2)
  L0_2 = WifVzBoundary
  L0_2 = L0_2.SetInteriorMode
  L1_2 = false
  L0_2(L1_2)
  L0_2 = _ToggleHuds
  L1_2 = true
  L0_2(L1_2)
  L0_2 = MrxUtil
  L0_2 = L0_2.EnableHeroWeapons
  L1_2 = true
  L0_2(L1_2)
  L0_2 = MrxSound
  L0_2 = L0_2.ExitInterior
  L0_2()
  L0_2 = Graphics
  L0_2 = L0_2.Camera
  L0_2 = L0_2.RestoreNearFar
  L1_2 = 0
  L0_2(L1_2)
  L0_2 = Player
  L0_2 = L0_2.GetAllPlayers
  L0_2 = L0_2()
  L1_2 = ipairs
  L2_2 = L0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Player
    L6_2 = L6_2.GetCharacter
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    L7_2 = Object
    L7_2 = L7_2.SetInvincible
    L8_2 = L6_2
    L9_2 = false
    L10_2 = "HQ"
    L7_2(L8_2, L9_2, L10_2)
  end
end

GlobalExit = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = A0_2._bInside
  if L1_2 then
    return
  end
  L1_2 = MrxFactionManager
  L1_2 = L1_2.DisableReporting
  L2_2 = true
  L1_2(L2_2)
  A0_2._bInside = true
  L1_2 = Net
  L1_2 = L1_2.IsServer
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = Net
    L1_2 = L1_2.SetLoadingScreen
    L2_2 = true
    L1_2(L2_2)
    L1_2 = Net
    L1_2 = L1_2.SetBriefingInterior
    L2_2 = "MrxHq"
    L1_2(L2_2)
  end
  L1_2 = MrxState
  L1_2 = L1_2.Enter
  L2_2 = MrxState
  L2_2 = L2_2.STATE_WAITFORGAME
  L3_2 = _CompleteOnEnter
  L4_2 = {}
  L5_2 = A0_2
  L4_2[1] = L5_2
  L1_2(L2_2, L3_2, L4_2)
end

_OnEnter = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = A0_2._bInside
  if L1_2 then
    return
  end
  L1_2 = A0_2.sLockStatusMessage
  if L1_2 then
    L1_2 = nil
    L2_2 = A0_2.sLockStatusMessage
    if L2_2 == "Friendly" then
      L1_2 = "[Generic.HQ.Friendly]"
    else
      L2_2 = A0_2.sLockStatusMessage
      if L2_2 == "Neutral" then
        L1_2 = "[Generic.HQ.Neutral]"
      else
        L2_2 = A0_2.sLockStatusMessage
        if L2_2 == "NoEntry" then
          L1_2 = "[Generic.HQ.NoEntry]"
        else
          L2_2 = A0_2.sLockStatusMessage
          if L2_2 == "NoContract" then
            L1_2 = "[Generic.HQ.NoContract]"
          end
        end
      end
    end
    L2_2 = MrxTutorialManager
    L2_2 = L2_2.ShowMessage
    L3_2 = L1_2
    L4_2 = true
    L2_2(L3_2, L4_2)
  end
  L1_2 = A0_2._uHideMessage
  if not L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Create
    L2_2 = Event
    L2_2 = L2_2.TimerRelative
    L3_2 = {}
    L4_2 = 5
    L3_2[1] = L4_2
    L4_2 = HideTutorialMessage
    L5_2 = {}
    L6_2 = A0_2
    L5_2[1] = L6_2
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
    A0_2._uHideMessage = L1_2
  end
end

_LockedOnEnter = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2._uHideMessage
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2._uHideMessage
    L1_2(L2_2)
    A0_2._uHideMessage = nil
  end
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.HideMessage
  L2_2 = true
  L1_2(L2_2)
end

HideTutorialMessage = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = GlobalEnter
  L2_2 = false
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.RefreshUiDisplay
  L1_2(L2_2)
  A0_2._bInside = true
  L1_2 = MrxHqManager
  L1_2 = L1_2.SetInside
  L2_2 = true
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.RefreshUiDisplay
  L1_2(L2_2)
  L1_2 = WifFreePlay
  L1_2 = L1_2.StopNag
  L1_2()
  L1_2 = Sound
  L1_2 = L1_2.StopAndFlushAllSounds
  if L1_2 then
    L1_2 = Sound
    L1_2 = L1_2.StopAndFlushAllSounds
    L1_2()
  end
  L2_2 = A0_2
  L1_2 = A0_2._LoadInterior
  L1_2(L2_2)
  L1_2 = dynamic_import
  L2_2 = "MrxBriefing"
  L3_2 = A0_2._BriefingModuleLoaded
  L4_2 = {}
  L5_2 = A0_2
  L4_2[1] = L5_2
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Graphics
  L1_2 = L1_2.Camera
  L1_2 = L1_2.SetNearFar
  L2_2 = 0
  L3_2 = 0.3
  L5_2 = A0_2
  L4_2 = A0_2.GetDrawDistance
  L4_2 = L4_2(L5_2)
  L5_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

_CompleteOnEnter = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = A0_2.tLayers
  if L1_2 then
    L1_2 = MrxLayerManager
    L1_2 = L1_2.Add
    L2_2 = A0_2.tLayers
    L3_2 = nil
    L4_2 = nil
    L5_2 = nil
    L6_2 = nil
    L7_2 = true
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  end
  L1_2 = {}
  L2_2 = 3750
  L3_2 = 450
  L4_2 = -3840
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SpawnActor
  L3_2 = A0_2.tInterior
  L3_2 = L3_2.sTemplate
  L4_2 = "HqInterior"
  L5_2 = L1_2
  L6_2 = A0_2.tInterior
  L6_2 = L6_2.sAnchorHardpoint
  L7_2 = A0_2.nRotation
  L8_2 = false
  L9_2 = false
  L10_2 = A0_2._OnInteriorLoad
  L11_2 = {}
  L12_2 = A0_2
  L11_2[1] = L12_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
end

_LoadInterior = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = A0_2._tStarter
  L2_2 = L1_2
  L1_2 = L1_2.Load
  L3_2 = _KickoffStarter
  L4_2 = {}
  L5_2 = A0_2
  L6_2 = 1
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = MrxUtil
  L1_2 = L1_2.EnableHeroWeapons
  L2_2 = false
  L1_2(L2_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.ChangeLineRegionSetting
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "rgn_atmo_interior"
  L2_2 = L2_2(L3_2)
  L4_2 = A0_2
  L3_2 = A0_2.GetAtmosphere
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = MrxUtil
  L1_2 = L1_2.TeleportHeroesToHardpoints
  L2_2 = {}
  L3_2 = {}
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "HqInterior"
  L4_2 = L4_2(L5_2)
  L3_2.vObject = L4_2
  L3_2.sHardpoint = "hp_playerA_enter"
  L2_2[1] = L3_2
  L3_2 = _KickoffStarter
  L4_2 = {}
  L5_2 = A0_2
  L6_2 = 2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L1_2(L2_2, L3_2, L4_2)
end

_OnInteriorLoad = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  _mBriefingModule = A1_2
  L3_2 = A0_2
  L2_2 = A0_2.GetStarter
  L2_2 = L2_2(L3_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetBriefingModule
  L5_2 = _mBriefingModule
  L3_2(L4_2, L5_2)
  L3_2 = _mBriefingModule
  L3_2 = L3_2.LoadTableOfAssets
  L4_2 = _tAssetPreload
  L5_2 = _KickoffStarter
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = 3
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L3_2(L4_2, L5_2, L6_2)
end

_BriefingModuleLoaded = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  if A1_2 == 1 then
    L2_2 = true
    _bStarterLoaded = L2_2
  elseif A1_2 == 2 then
    L2_2 = true
    _bHeroTeleportComplete = L2_2
  elseif A1_2 == 3 then
    L2_2 = true
    _bGenericAssetsLoaded = L2_2
  end
  L2_2 = _bStarterLoaded
  if L2_2 then
    L2_2 = _bHeroTeleportComplete
    if L2_2 then
      L2_2 = _bGenericAssetsLoaded
      if L2_2 then
        goto lbl_25
      end
    end
  end
  do return end
  ::lbl_25::
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 1
  L4_2[1] = L5_2
  
  function L5_2()
    local L0_3, L1_3
    _bStarterLoaded = L0_3
    L0_3 = nil
    _bHeroTeleportComplete = L0_3
    L0_3 = nil
    _bGenericAssetsLoaded = L0_3
    L0_3 = A0_2
    L0_3 = L0_3._tStarter
    L1_3 = L0_3
    L0_3 = L0_3.Start
    L0_3(L1_3)
  end
  
  L2_2(L3_2, L4_2, L5_2)
end

_KickoffStarter = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2._bInside
  if not L1_2 then
    return
  end
  L1_2 = GlobalExit
  L1_2()
  L2_2 = A0_2
  L1_2 = A0_2.Unload
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetStarter
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L3_2 = L1_2
    L2_2 = L1_2.CardDisplayed
    L2_2(L3_2)
  end
  A0_2._bInside = false
  L2_2 = MrxHqManager
  L2_2 = L2_2.SetInside
  L3_2 = false
  L2_2(L3_2)
  L2_2 = _mBriefingModule
  L2_2 = L2_2.UnloadTableOfAssets
  L3_2 = _tAssetPreload
  L2_2(L3_2)
  L2_2 = Net
  L2_2 = L2_2.IsServer
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = Net
    L2_2 = L2_2.SetBriefingInterior
    L2_2()
  end
  L2_2 = nil
  _mBriefingModule = L2_2
  L2_2 = dynamic_remove
  L3_2 = "MrxBriefing"
  L2_2(L3_2)
end

ExitBegin = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 2
  L3_2[1] = L4_2
  
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3
    L0_3 = A0_2
    L0_3 = L0_3.nLandingZone
    L1_3 = A0_2
    L1_3 = L1_3.sLzUnlockStyle
    if L0_3 and L1_3 == "visit" then
      L2_3 = MrxTransit
      L2_3 = L2_3.SetLocationEnabled
      L3_3 = L0_3
      L4_3 = A0_2
      L5_3 = L4_3
      L4_3 = L4_3.GetFaction
      L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3 = L4_3(L5_3)
      L2_3(L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3)
    end
    L2_3 = A0_2
    L2_3 = L2_3._tStarter
    L3_3 = L2_3
    L2_3 = L2_3.GetMissionsToBeAccepted
    L2_3, L3_3 = L2_3(L3_3)
    L4_3 = type
    L5_3 = L2_3
    L4_3 = L4_3(L5_3)
    if L4_3 == "table" then
      L4_3 = table
      L4_3 = L4_3.getn
      L5_3 = L2_3
      L4_3 = L4_3(L5_3)
      if 0 < L4_3 then
        L4_3 = WifMissionFlow
        L4_3 = L4_3.AcceptMissions
        L5_3 = L2_3
        L6_3 = L3_3
        L4_3(L5_3, L6_3)
        L4_3 = Pg
        L4_3 = L4_3.GetGuidByName
        L5_3 = A0_2
        L5_3 = L5_3.sParkingLot
        L4_3 = L4_3(L5_3)
        L5_3 = nil
        L6_3 = A0_2
        L6_3 = L6_3.nLandingZone
        if L6_3 then
          L6_3 = MrxTransit
          L6_3 = L6_3.GetTransitPoint
          L7_3 = A0_2
          L7_3 = L7_3.nLandingZone
          L6_3 = L6_3(L7_3)
          L5_3 = L6_3
        else
          L6_3 = A0_2
          L6_3 = L6_3.nAltLandingZone
          if L6_3 then
            L6_3 = MrxTransit
            L6_3 = L6_3.GetTransitPoint
            L7_3 = A0_2
            L7_3 = L7_3.nAltLandingZone
            L6_3 = L6_3(L7_3)
            L5_3 = L6_3
          else
            L5_3 = L4_3
          end
        end
        L6_3 = Event
        L6_3 = L6_3.Post
        L7_3 = "parkingLotStart"
        L8_3 = {}
        L9_3 = Pg
        L9_3 = L9_3.GetGuidByName
        L10_3 = A0_2
        L10_3 = L10_3.tPortal
        L10_3 = L10_3.sEntrance
        L9_3 = L9_3(L10_3)
        L10_3 = L4_3
        L11_3 = L5_3
        L8_3[1] = L9_3
        L8_3[2] = L10_3
        L8_3[3] = L11_3
        L6_3(L7_3, L8_3)
      end
    end
    L4_3 = A0_2
    L4_3 = L4_3._tStarter
    L5_3 = L4_3
    L4_3 = L4_3.ResetIntraSessionData
    L4_3(L5_3)
    L4_3 = MrxState
    L4_3 = L4_3.Exit
    L5_3 = MrxState
    L5_3 = L5_3.STATE_WAITFORGAME
    L4_3(L5_3)
    L4_3 = MrxHqManager
    L4_3 = L4_3.GetUnloadCallback
    L4_3, L5_3 = L4_3()
    L6_3 = MrxUtil
    L6_3 = L6_3.CallWithOptionalArgs
    L7_3 = L4_3
    L8_3 = L5_3
    L6_3(L7_3, L8_3)
    L6_3 = MrxHqManager
    L6_3 = L6_3.SetUnloadCallback
    L7_3 = nil
    L8_3 = nil
    L6_3(L7_3, L8_3)
    L6_3 = A0_2
    L7_3 = L6_3
    L6_3 = L6_3.RefreshUiDisplay
    L6_3(L7_3)
    L6_3 = WifFreePlay
    L6_3 = L6_3.StartNag
    L6_3()
  end
  
  L1_2(L2_2, L3_2, L4_2)
end

ExitEnd = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Player
  L1_2 = L1_2.GetAllPlayers
  L1_2 = L1_2()
  L2_2 = ipairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = MrxGuiBootstrap
    L7_2 = L7_2.ToggleHud
    L8_2 = L6_2
    L9_2 = A0_2
    L10_2 = "briefing"
    L7_2(L8_2, L9_2, L10_2)
  end
end

_ToggleHuds = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
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
  L1_2 = A0_2.tInterior
  if L1_2 then
    L1_2 = Pg
    L1_2 = L1_2.GetGuidByName
    L2_2 = "HqInterior"
    L1_2 = L1_2(L2_2)
    L2_2 = Object
    L2_2 = L2_2.Remove
    L3_2 = L1_2
    L2_2(L3_2)
  end
  L1_2 = A0_2._tStarter
  if L1_2 then
    L1_2 = A0_2._tStarter
    L2_2 = L1_2
    L1_2 = L1_2.Unload
    L1_2(L2_2)
  end
end

Unload = L0_1
