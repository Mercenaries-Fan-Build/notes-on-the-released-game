local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxAchievements"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifMissionFlow"
L0_1(L1_1)
L0_1 = 0
_knAttitudeMeterMin = L0_1
L0_1 = 100
_knAttitudeMeterMax = L0_1
L0_1 = -100
_knRelationMin = L0_1
L0_1 = 100
_knRelationMax = L0_1
L0_1 = {}
_tEvents = L0_1
L0_1 = {}
_tInvestigatorBlips = L0_1
L0_1 = {}
L1_1 = "Fiona.FactionZone.Generic01"
L2_1 = "Fiona.FactionZone.Generic02"
L0_1[1] = L1_1
L0_1[2] = L2_1
_tTressPassGeneric = L0_1
L0_1 = {}
L1_1 = {}
L1_1.sLabel = "Hostile"
L2_1 = {}
L3_1 = "["
L4_1 = -100
L5_1 = -33
L6_1 = ")"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L2_1[4] = L6_1
L1_1.tRange = L2_1
L1_1.nPrices = nil
L2_1 = {}
L3_1 = 255
L4_1 = 0
L5_1 = 0
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tRgbColor = L2_1
L2_1 = {}
L2_1.sLabel = "Neutral"
L3_1 = {}
L4_1 = "["
L5_1 = -33
L6_1 = 33
L7_1 = ")"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L3_1[4] = L7_1
L2_1.tRange = L3_1
L2_1.nPrices = 1.5
L3_1 = {}
L4_1 = 200
L5_1 = 200
L6_1 = 200
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L2_1.tRgbColor = L3_1
L3_1 = {}
L3_1.sLabel = "Friendly"
L4_1 = {}
L5_1 = "["
L6_1 = 33
L7_1 = 100
L8_1 = "]"
L4_1[1] = L5_1
L4_1[2] = L6_1
L4_1[3] = L7_1
L4_1[4] = L8_1
L3_1.tRange = L4_1
L3_1.nPrices = 1
L4_1 = {}
L5_1 = 0
L6_1 = 127
L7_1 = 255
L4_1[1] = L5_1
L4_1[2] = L6_1
L4_1[3] = L7_1
L3_1.tRgbColor = L4_1
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
_tAttitudes = L0_1
L0_1 = {}
L1_1 = {}
L1_1.bDynamic = true
L1_1.sFactionTemplate = "Allied"
L1_1.sMarkerTexture = "HUD_faction_AN"
L1_1.sPdaIcon = "icon_an_mc"
L1_1.sInlineIcon = "[flagallies]"

function L2_1()
  local L0_2, L1_2, L2_2
  L0_2 = GetRelation
  L1_2 = "Oil"
  L2_2 = "Pmc"
  return L0_2(L1_2, L2_2)
end

L1_1.fGetInitialRelation = L2_1
L1_1.sMaxRelationAchievement = "ACHIEVEMENT_STAND_UP_AND_SHOUT"
L2_1 = {}
L3_1 = "Fiona.Cam.28"
L4_1 = "Fiona.Cam.29"
L5_1 = "Fiona.Cam.30"
L6_1 = "Fiona.Cam.40"
L7_1 = "Fiona.Cam.41"
L8_1 = "Fiona.Cam.42"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L2_1[4] = L6_1
L2_1[5] = L7_1
L2_1[6] = L8_1
L1_1.tPursuitVO = L2_1
L2_1 = {}
L3_1 = "AlliedSoldier01.Reporting.CallIn01"
L4_1 = "AlliedSoldier01.Reporting.CallIn02"
L5_1 = "AlliedSoldier01.Reporting.CallIn03"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tIntentVO = L2_1
L2_1 = {}
L3_1 = "AlliedSoldier01.Reporting.LongReport01"
L4_1 = "AlliedSoldier01.Reporting.LongReport02"
L5_1 = "AlliedSoldier01.Reporting.LongReport03"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tReportVO = L2_1
L2_1 = {}
L3_1 = "Fiona.fio_g50"
L4_1 = "Fiona.fio_g51"
L5_1 = "Fiona.xfio122"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tReportedVO = L2_1
L2_1 = {}
L3_1 = "AlliedSoldier01.Reporting.Jammed01"
L4_1 = "AlliedSoldier01.Reporting.Jammed02"
L2_1[1] = L3_1
L2_1[2] = L4_1
L1_1.tJammedVO = L2_1
L2_1 = {}
L3_1 = "Fiona.FactionZone.Allies01"
L4_1 = "Fiona.FactionZone.Allies02"
L2_1[1] = L3_1
L2_1[2] = L4_1
L1_1.tTresspassVO = L2_1
L1_1.nReportThreshold = 1
L1_1.nReportFrequency = 15
L1_1.sPdaFactionId = "AN"
L1_1.bCanReport = true
L0_1.All = L1_1
L1_1 = {}
L1_1.bDynamic = true
L1_1.sFactionTemplate = "China"
L1_1.sMarkerTexture = "HUD_faction_CH"
L1_1.sPdaIcon = "icon_ch_mc"
L1_1.sInlineIcon = "[flagchina]"

function L2_1()
  local L0_2, L1_2, L2_2
  L0_2 = GetRelation
  L1_2 = "Gur"
  L2_2 = "Pmc"
  return L0_2(L1_2, L2_2)
end

L1_1.fGetInitialRelation = L2_1
L1_1.sMaxRelationAchievement = "ACHIEVEMENT_LONGING_FOR_FIRE"
L2_1 = {}
L3_1 = "Fiona.Cam.28"
L4_1 = "Fiona.Cam.29"
L5_1 = "Fiona.Cam.30"
L6_1 = "Fiona.Cam.43"
L7_1 = "Fiona.Cam.44"
L8_1 = "Fiona.Cam.45"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L2_1[4] = L6_1
L2_1[5] = L7_1
L2_1[6] = L8_1
L1_1.tPursuitVO = L2_1
L2_1 = {}
L3_1 = "ChinaSoldier01.Reporting.CallIn02"
L4_1 = "ChinaSoldier01.Reporting.CallIn01"
L2_1[1] = L3_1
L2_1[2] = L4_1
L1_1.tIntentVO = L2_1
L2_1 = {}
L3_1 = "ChinaSoldier01.Reporting.LongReport01"
L4_1 = "ChinaSoldier01.Reporting.LongReport02"
L5_1 = "ChinaSoldier01.Reporting.LongReport03"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tReportVO = L2_1
L2_1 = {}
L3_1 = "Fiona.fio_g38"
L4_1 = "Fiona.xfio123"
L5_1 = "Fiona.fio_g39"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tReportedVO = L2_1
L2_1 = {}
L3_1 = "ChinaSoldier01.Reporting.Jammed01"
L4_1 = "ChinaSoldier01.Reporting.Jammed02"
L2_1[1] = L3_1
L2_1[2] = L4_1
L1_1.tJammedVO = L2_1
L2_1 = {}
L3_1 = "Fiona.FactionZone.China01"
L4_1 = "Fiona.FactionZone.China02"
L2_1[1] = L3_1
L2_1[2] = L4_1
L1_1.tTresspassVO = L2_1
L1_1.nReportThreshold = 1
L1_1.nReportFrequency = 15
L1_1.sPdaFactionId = "CH"
L1_1.bCanReport = true
L0_1.Chi = L1_1
L1_1 = {}
L1_1.bDynamic = false
L1_1.sFactionTemplate = "Civ"
L1_1.sMarkerTexture = "HUD_faction_CV"
L1_1.sInlineIcon = "[flagcivilian]"
L0_1.Civ = L1_1
L1_1 = {}
L1_1.bDynamic = true
L1_1.sFactionTemplate = "Guerilla"
L1_1.sMarkerTexture = "HUD_faction_GR"
L1_1.sPdaIcon = "icon_gr_mc"
L1_1.sInlineIcon = "[flagguerillas]"

function L2_1()
  local L0_2, L1_2
  L0_2 = GetAttitudeMedianValue
  L1_2 = "Friendly"
  return L0_2(L1_2)
end

L1_1.fGetInitialRelation = L2_1
L1_1.sMaxRelationAchievement = "ACHIEVEMENT_FOREVER_FREE"
L2_1 = {}
L3_1 = "Fiona.Cam.28"
L4_1 = "Fiona.Cam.29"
L5_1 = "Fiona.Cam.30"
L6_1 = "Fiona.Cam.34"
L7_1 = "Fiona.Cam.35"
L8_1 = "Fiona.Cam.36"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L2_1[4] = L6_1
L2_1[5] = L7_1
L2_1[6] = L8_1
L1_1.tPursuitVO = L2_1
L2_1 = {}
L3_1 = "GurSoldier01.Reporting.CallIn01"
L4_1 = "GurSoldier01.Reporting.CallIn02"
L5_1 = "GurSoldier01.Reporting.CallIn03"
L6_1 = "GuerillaSoldier_David01_Guerilla Soldier_AI Report_x_Merc(Generic)_x_x_x_03"
L7_1 = "GuerillaSoldier_David01_Guerilla Soldier_AI Report_x_Merc(Generic)_x_x_x_04"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L2_1[4] = L6_1
L2_1[5] = L7_1
L1_1.tIntentVO = L2_1
L2_1 = {}
L3_1 = "GurSoldier01.Reporting.LongReport01"
L4_1 = "GurSoldier01.Reporting.LongReport02"
L5_1 = "GurSoldier01.Reporting.LongReport03"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tReportVO = L2_1
L2_1 = {}
L3_1 = "Fiona.fio_g84"
L4_1 = "Fiona.fio_g83"
L5_1 = "Fiona.xfio124"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tReportedVO = L2_1
L2_1 = {}
L3_1 = "GurSoldier01.Reporting.Jammed01"
L4_1 = "Gur01.Reporting.Jammed02"
L2_1[1] = L3_1
L2_1[2] = L4_1
L1_1.tJammedVO = L2_1
L2_1 = {}
L3_1 = "Fiona.FactionZone.Gur01"
L4_1 = "Fiona.FactionZone.Gur02"
L2_1[1] = L3_1
L2_1[2] = L4_1
L1_1.tTresspassVO = L2_1
L1_1.nReportThreshold = 1
L1_1.nReportFrequency = 15
L1_1.sPdaFactionId = "GR"
L1_1.bCanReport = true
L0_1.Gur = L1_1
L1_1 = {}
L1_1.bDynamic = true
L1_1.sFactionTemplate = "OC"
L1_1.sMarkerTexture = "HUD_faction_OC"
L1_1.sPdaIcon = "icon_oc_mc"
L1_1.sInlineIcon = "[flagoil]"

function L2_1()
  local L0_2, L1_2
  L0_2 = GetAttitudeMedianValue
  L1_2 = "Friendly"
  return L0_2(L1_2)
end

L1_1.fGetInitialRelation = L2_1
L1_1.sMaxRelationAchievement = "ACHIEVEMENT_DIRTY_DEEDS"
L2_1 = {}
L3_1 = "Fiona.Cam.28"
L4_1 = "Fiona.Cam.29"
L5_1 = "Fiona.Cam.30"
L6_1 = "Fiona.Cam.37"
L7_1 = "Fiona.Cam.38"
L8_1 = "Fiona.Cam.39"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L2_1[4] = L6_1
L2_1[5] = L7_1
L2_1[6] = L8_1
L1_1.tPursuitVO = L2_1
L2_1 = {}
L3_1 = "OCSoldier01.Reporting.CallIn01"
L4_1 = "OCSoldier01.Reporting.CallIn02"
L5_1 = "OCSoldier01.Reporting.CallIn03"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tIntentVO = L2_1
L2_1 = {}
L3_1 = "OCSoldier01.Reporting.LongReport01"
L4_1 = "OCSoldier01.Reporting.LongReport02"
L5_1 = "Generic OC Soldier_Keith01_OC Soldier_AI Report_x_Merc(Generic)_x_x_x_04"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tReportVO = L2_1
L2_1 = {}
L3_1 = "Fiona.fio_g71"
L4_1 = "Fiona.fio_g72"
L5_1 = "Fiona.fio_g73"
L6_1 = "Fiona.xfio125"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L2_1[4] = L6_1
L1_1.tReportedVO = L2_1
L2_1 = {}
L3_1 = "OCSoldier01.Reporting.Jammed01"
L4_1 = "OCSoldier01.Reporting.Jammed02"
L2_1[1] = L3_1
L2_1[2] = L4_1
L1_1.tJammedVO = L2_1
L2_1 = {}
L3_1 = "Fiona.FactionZone.OC01"
L4_1 = "Fiona.FactionZone.OC02"
L5_1 = "Fiona.FactionZone.OC03"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tTresspassVO = L2_1
L1_1.nReportThreshold = 1
L1_1.nReportFrequency = 15
L1_1.sPdaFactionId = "OC"
L1_1.bCanReport = true
L0_1.Oil = L1_1
L1_1 = {}
L1_1.bDynamic = true
L1_1.sFactionTemplate = "Pirate"
L1_1.sMarkerTexture = "HUD_faction_PR"
L1_1.sPdaIcon = "icon_pr_mc"
L1_1.sInlineIcon = "[flagpirates]"

function L2_1()
  local L0_2, L1_2
  L0_2 = GetAttitudeMedianValue
  L1_2 = "Neutral"
  return L0_2(L1_2)
end

L1_1.fGetInitialRelation = L2_1
L1_1.sMaxRelationAchievement = "ACHIEVEMENT_ISLAND_DOMINATION"
L2_1 = {}
L3_1 = "Fiona.fio_g52"
L4_1 = "Fiona.fio_g54"
L2_1[1] = L3_1
L2_1[2] = L4_1
L1_1.tPursuitVO = L2_1
L2_1 = {}
L3_1 = "Fiona.fio_g60"
L4_1 = "Fiona.fio_g61"
L5_1 = "Fiona.fio_g62"
L6_1 = "Fiona.xfio126"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L2_1[4] = L6_1
L1_1.tReportedVO = L2_1
L2_1 = {}
L3_1 = "Fiona.FactionZone.Pirates01"
L4_1 = "Fiona.FactionZone.Pirates02"
L2_1[1] = L3_1
L2_1[2] = L4_1
L1_1.tTresspassVO = L2_1
L1_1.nReportThreshold = 1
L1_1.nReportFrequency = 15
L1_1.sPdaFactionId = "PR"
L1_1.bCanReport = true
L0_1.Pir = L1_1
L1_1 = {}
L1_1.bDynamic = false
L1_1.sFactionTemplate = "PMC"
L1_1.sMarkerTexture = "HUD_faction_CV"
L1_1.sInlineIcon = "[flagpmc]"
L1_1.sPdaFactionId = "PMC"
L0_1.Pmc = L1_1
L1_1 = {}
L1_1.bDynamic = false
L1_1.sFactionTemplate = "VZ"
L1_1.sMarkerTexture = "HUD_faction_VZ"
L1_1.sInlineIcon = "[flagvz]"
L2_1 = {}
L3_1 = "Fiona.Cam.28"
L4_1 = "Fiona.Cam.29"
L5_1 = "Fiona.Cam.30"
L6_1 = "Fiona.Cam.31"
L7_1 = "Fiona.Cam.32"
L8_1 = "Fiona.Cam.33"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L2_1[4] = L6_1
L2_1[5] = L7_1
L2_1[6] = L8_1
L1_1.tPursuitVO = L2_1
L2_1 = {}
L3_1 = "VZSoldier01.Reporting.CallIn01"
L4_1 = "VZSoldier01.Reporting.CallIn02"
L5_1 = "VZSoldier01.Reporting.CallIn03"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tIntentVO = L2_1
L2_1 = {}
L3_1 = "VZSoldier01.Reporting.LongReport01"
L4_1 = "VZSoldier01.Reporting.LongReport02"
L5_1 = "VZSoldier01.Reporting.LongReport03"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tReportVO = L2_1
L2_1 = {}
L3_1 = "VZSoldier01.Reporting.Jammed01"
L4_1 = "VZSoldier01.Reporting.Jammed02"
L2_1[1] = L3_1
L2_1[2] = L4_1
L1_1.tJammedVO = L2_1
L2_1 = {}
L3_1 = "Fiona.FactionZone.VZ01"
L4_1 = "Fiona.FactionZone.VZ02"
L5_1 = "Fiona.FactionZone.VZ03"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tTresspassVO = L2_1
L1_1.nReportThreshold = 1
L1_1.nReportFrequency = 20
L1_1.sPdaFactionId = "VZ"
L0_1.Vza = L1_1
_tFactions = L0_1
L0_1 = nil
_bSetupComplete = L0_1
L0_1 = false
_bVoPlayed = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = {}
  _tAttitudeLevelsToLabels = L0_2
  L0_2 = {}
  _tAttitudeLabelsToLevels = L0_2
  L0_2 = ipairs
  L1_2 = _tAttitudes
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = _tAttitudeLevelsToLabels
    L6_2 = L4_2.sLabel
    L5_2[L3_2] = L6_2
    L5_2 = _tAttitudeLabelsToLevels
    L6_2 = L4_2.sLabel
    L5_2[L6_2] = L3_2
  end
  L0_2 = {}
  _tFactionTemplateToAbbrev = L0_2
  L0_2 = pairs
  L1_2 = _tFactions
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = Pg
    L5_2 = L5_2.GetGuidByName
    L6_2 = L4_2.sFactionTemplate
    L5_2 = L5_2(L6_2)
    L4_2.uGuid = L5_2
    L5_2 = _tFactionTemplateToAbbrev
    L6_2 = L4_2.sFactionTemplate
    L5_2[L6_2] = L3_2
  end
end

Init = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = Report
  L0_2 = L0_2.Init
  L1_2 = {}
  L1_2.Callback = 0
  L1_2.SimultaneousReporters = 1
  L1_2.LossThreshold = 1
  L1_2.GoalPriority = 10
  L0_2(L1_2)
end

Reset = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L0_2 = Report
  L0_2 = L0_2.Init
  L1_2 = {}
  L2_2 = HandleReporter
  L1_2.Callback = L2_2
  L1_2.SimultaneousReporters = 1
  L1_2.LossThreshold = 1
  L1_2.GoalPriority = 10
  L0_2(L1_2)
  L0_2 = tDisabledReporters
  if not L0_2 then
    L0_2 = {}
  end
  tDisabledReporters = L0_2
  L0_2 = Pg
  L0_2 = L0_2.SetPursuitLevelTimes
  L1_2 = 120
  L2_2 = 300
  L0_2(L1_2, L2_2)
  L0_2 = SetupNextFlyby
  L0_2()
  L0_2 = MrxAchievements
  L0_2 = L0_2.FactionMoodAchievements
  L0_2()
  L0_2 = Disguise
  L0_2 = L0_2.Init
  L1_2 = {}
  L2_2 = HandleInvestigator
  L1_2.InvestigatorCallback = L2_2
  L0_2(L1_2)
  L0_2 = FactionZone
  L0_2 = L0_2.Init
  L1_2 = {}
  L2_2 = HandleTressPasser
  L1_2.TresspasserCallback = L2_2
  L0_2(L1_2)
  L0_2 = {}
  L1_2 = {}
  L2_2 = ipairs
  L3_2 = _tAttitudes
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = L6_2.tRange
    L7_2 = L7_2[2]
    L8_2 = ConvertRelationToMeterValue
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    L0_2[L5_2] = L8_2
    L8_2 = "[Generic.Attitudes."
    L9_2 = L6_2.sLabel
    L10_2 = "]"
    L8_2 = L8_2 .. L9_2 .. L10_2
    L1_2[L5_2] = L8_2
  end
  L2_2 = Hud
  L2_2 = L2_2.FactionDisplay
  L3_2 = L2_2
  L2_2 = L2_2.ConfigureThresholds
  L4_2 = {}
  L4_2.tLevelThresholds = L0_2
  L4_2.tLevelNames = L1_2
  L2_2(L3_2, L4_2)
  L2_2 = pairs
  L3_2 = _tFactions
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = SetRelation
    L8_2 = L5_2
    L9_2 = L5_2
    L10_2 = _knRelationMax
    L11_2 = true
    L7_2(L8_2, L9_2, L10_2, L11_2)
  end
  L2_2 = CivCasualtySetup
  L2_2()
  L2_2 = _tEvents
  L2_2 = L2_2.eJoin
  if not L2_2 then
    L2_2 = _tEvents
    L3_2 = Event
    L3_2 = L3_2.CreatePersistent
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
    L6_2 = SendPlayerJoinEvents
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.eJoin = L3_2
  end
  L2_2 = true
  _bSetupComplete = L2_2
end

Setup = L0_1
L0_1 = 0
NETEVENT_SETMUTABLE = L0_1
L0_1 = 1
NETEVENT_CIVKILLINIT = L0_1
L0_1 = 2
NETEVENT_CIVKILL = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L0_2 = Net
  L0_2 = L0_2.IsServer
  L0_2 = L0_2()
  if not L0_2 then
    return
  end
  L0_2 = {}
  L1_2 = 1
  L2_2 = pairs
  L3_2 = _tFactions
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = CanAttitudeBeMutable
    L8_2 = L5_2
    L7_2 = L7_2(L8_2)
    if L7_2 then
      L7_2 = IsAttitudeMutable
      L8_2 = L5_2
      L7_2 = L7_2(L8_2)
      if L7_2 then
        L0_2[L1_2] = L5_2
        L1_2 = L1_2 + 1
        if L1_2 == 5 then
          L7_2 = Net
          L7_2 = L7_2.SendCustomEvent
          L8_2 = "MrxFactionManager"
          L9_2 = NETEVENT_SETMUTABLE
          L10_2 = L0_2
          L11_2 = true
          L7_2(L8_2, L9_2, L10_2, L11_2)
          L1_2 = 1
          L7_2 = {}
          L0_2 = L7_2
        end
      end
    end
  end
  if 1 < L1_2 then
    L2_2 = Net
    L2_2 = L2_2.SendCustomEvent
    L3_2 = "MrxFactionManager"
    L4_2 = NETEVENT_SETMUTABLE
    L5_2 = L0_2
    L6_2 = true
    L2_2(L3_2, L4_2, L5_2, L6_2)
  end
  L2_2 = Net
  L2_2 = L2_2.SendCustomEvent
  L3_2 = "MrxFactionManager"
  L4_2 = NETEVENT_CIVKILLINIT
  L5_2 = {}
  L6_2 = nCivilianCasualties
  L7_2 = nCivilianPenalty
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = true
  L2_2(L3_2, L4_2, L5_2, L6_2)
end

SendPlayerJoinEvents = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = pairs
  L2_2 = _tFactions
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = String
    L6_2 = L6_2.GetHash
    L7_2 = L4_2
    L6_2 = L6_2(L7_2)
    if L6_2 == A0_2 then
      return L4_2
    end
  end
  L1_2 = "NO NAME"
  return L1_2
end

GetFactionStringIndex = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = true
  _bWaitingOnMutable = L2_2
  L2_2 = _bSetupComplete
  if not L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Create
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = 1
    L4_2[1] = L5_2
    L5_2 = NetEventCallback
    L6_2 = {}
    L7_2 = A0_2
    L8_2 = A1_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L2_2(L3_2, L4_2, L5_2, L6_2)
    return
  end
  L2_2 = NETEVENT_SETMUTABLE
  if A0_2 == L2_2 then
    L2_2 = pairs
    L3_2 = A1_2
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2, L6_2 in L2_2, L3_2, L4_2 do
      L7_2 = SetAttitudeMutable
      L8_2 = GetFactionStringIndex
      L9_2 = L6_2
      L8_2, L9_2 = L8_2(L9_2)
      L7_2(L8_2, L9_2)
    end
  else
    L2_2 = NETEVENT_CIVKILLINIT
    if A0_2 == L2_2 then
      L2_2 = A1_2[1]
      nCivilianCasualties = L2_2
      L2_2 = A1_2[2]
      nCivilianPenalty = L2_2
    else
      L2_2 = NETEVENT_CIVKILL
      if A0_2 == L2_2 then
        L2_2 = Player
        L2_2 = L2_2.GetCharacter
        L3_2 = Player
        L3_2 = L3_2.GetPlayer
        L4_2 = A1_2[1]
        L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L3_2(L4_2)
        L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
        L3_2 = ChargeCivCasualty
        L4_2 = L2_2
        L3_2(L4_2)
      end
    end
  end
  L2_2 = nil
  _bWaitingOnMutable = L2_2
end

NetEventCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L1_2 = Net
  L1_2 = L1_2.IsClient
  L1_2 = L1_2()
  if not L1_2 then
    return
  end
  L1_2 = _evTimerEvent
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = _evTimerEvent
    L1_2(L2_2)
  end
  L1_2 = 1
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "number" == L2_2 then
    L1_2 = A0_2
  end
  L2_2 = _bSetupComplete
  if L2_2 then
    L2_2 = _bWaitingOnMutable
    if not L2_2 then
      goto lbl_41
    end
  end
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 0.5
  L4_2[1] = L5_2
  L5_2 = NetInitializeClientFactionRelations
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  _evTimerEvent = L2_2
  do return end
  ::lbl_41::
  L2_2 = 1
  L3_2 = pairs
  L4_2 = _tFactions
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    if L2_2 == L1_2 then
      L8_2 = pairs
      L9_2 = _tFactions
      L8_2, L9_2, L10_2 = L8_2(L9_2)
      for L11_2, L12_2 in L8_2, L9_2, L10_2 do
        L13_2 = SetRelation
        L14_2 = L6_2
        L15_2 = L11_2
        L16_2 = GetRelation
        L17_2 = L6_2
        L18_2 = L11_2
        L16_2 = L16_2(L17_2, L18_2)
        L17_2 = true
        L13_2(L14_2, L15_2, L16_2, L17_2)
      end
      L8_2 = Event
      L8_2 = L8_2.Create
      L9_2 = Event
      L9_2 = L9_2.TimerRelative
      L10_2 = {}
      L11_2 = 0.5
      L10_2[1] = L11_2
      L11_2 = NetInitializeClientFactionRelations
      L12_2 = {}
      L13_2 = L2_2 + 1
      L12_2[1] = L13_2
      L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
      _evTimerEvent = L8_2
      return
    end
    L2_2 = L2_2 + 1
  end
end

NetInitializeClientFactionRelations = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = _tFactions
  L2_2 = L2_2[A0_2]
  L3_2 = CanAttitudeBeMutable
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L2_2.bAttitudeMutable = true
    L3_2 = Hud
    L3_2 = L3_2.FactionDisplay
    L4_2 = L3_2
    L3_2 = L3_2.AddMeter
    L5_2 = {}
    L5_2.sFaction = A0_2
    L6_2 = L2_2.sMarkerTexture
    L5_2.sTexture = L6_2
    L3_2(L4_2, L5_2)
    if not A1_2 then
      L3_2 = L2_2.nInitialRelation
      L4_2 = L2_2.fGetInitialRelation
      if L4_2 then
        L4_2 = L2_2.fGetInitialRelation
        L4_2 = L4_2()
        L3_2 = L4_2
      end
      L4_2 = SetRelation
      L5_2 = A0_2
      L6_2 = "Pmc"
      L7_2 = L3_2
      L8_2 = true
      L4_2(L5_2, L6_2, L7_2, L8_2)
      L4_2 = SetRelation
      L5_2 = A0_2
      L6_2 = A0_2
      L7_2 = _knRelationMax
      L8_2 = true
      L4_2(L5_2, L6_2, L7_2, L8_2)
    end
    L3_2 = Net
    L3_2 = L3_2.IsServer
    L3_2 = L3_2()
    if L3_2 then
      L3_2 = Net
      L3_2 = L3_2.SendCustomEvent
      L4_2 = "MrxFactionManager"
      L5_2 = NETEVENT_SETMUTABLE
      L6_2 = {}
      L7_2 = A0_2
      L6_2[1] = L7_2
      L3_2(L4_2, L5_2, L6_2)
    end
  end
end

SetAttitudeMutable = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = _tFactions
  L1_2 = L1_2[A0_2]
  L1_2 = L1_2.bAttitudeMutable
  L1_2 = L1_2 == true
  return L1_2
end

IsAttitudeMutable = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = _tFactions
  L1_2 = L1_2[A0_2]
  L1_2 = L1_2.bDynamic
  L1_2 = L1_2 == true
  return L1_2
end

CanAttitudeBeMutable = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = Ai
  L2_2 = L2_2.GetRelation
  L3_2 = _tFactions
  L3_2 = L3_2[A0_2]
  L3_2 = L3_2.uGuid
  L4_2 = _tFactions
  L4_2 = L4_2[A1_2]
  L4_2 = L4_2.uGuid
  return L2_2(L3_2, L4_2)
end

GetRelation = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2
  L4_2 = GetAttitudeLevel
  L5_2 = A0_2
  L6_2 = A1_2
  L4_2 = L4_2(L5_2, L6_2)
  L5_2 = _tAttitudeLabelsToLevels
  L5_2 = L5_2[A3_2]
  if A2_2 == "==" then
    L6_2 = L4_2 == L5_2
    return L6_2
  elseif A2_2 == "<" then
    L6_2 = L4_2 < L5_2
    return L6_2
  elseif A2_2 == "<=" then
    L6_2 = L4_2 <= L5_2
    return L6_2
  elseif A2_2 == ">" then
    L6_2 = L4_2 > L5_2
    return L6_2
  elseif A2_2 == ">=" then
    L6_2 = L4_2 >= L5_2
    return L6_2
  end
end

TestAttitude = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = ConvertRelationToAttitudeLevel
  L3_2 = GetRelation
  L4_2 = A0_2
  L5_2 = A1_2
  L3_2, L4_2, L5_2 = L3_2(L4_2, L5_2)
  return L2_2(L3_2, L4_2, L5_2)
end

GetAttitudeLevel = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = GetAttitudeFromLevel
  L3_2 = GetAttitudeLevel
  L4_2 = A0_2
  L5_2 = A1_2
  L3_2, L4_2, L5_2 = L3_2(L4_2, L5_2)
  return L2_2(L3_2, L4_2, L5_2)
end

GetAttitudeLabel = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = ConvertRelationToMeterValue
  L3_2 = GetRelation
  L4_2 = A0_2
  L5_2 = A1_2
  L3_2, L4_2, L5_2 = L3_2(L4_2, L5_2)
  return L2_2(L3_2, L4_2, L5_2)
end

GetMeterValue = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = GetAttitudeLevel
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = _tAttitudes
  L3_2 = L3_2[L2_2]
  L3_2 = L3_2.nPrices
  return L3_2
end

GetPriceScale = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  if A1_2 == "Pmc" then
    L4_2 = IsAttitudeMutable
    L5_2 = A0_2
    L4_2 = L4_2(L5_2)
    if not L4_2 then
      return
    end
  end
  L4_2 = GetRelation
  L5_2 = A0_2
  L6_2 = A1_2
  L4_2 = L4_2(L5_2, L6_2)
  L5_2 = ConvertRelationToAttitudeLevel
  L6_2 = L4_2
  L5_2 = L5_2(L6_2)
  L6_2 = Ai
  L6_2 = L6_2.SetRelation
  L7_2 = _tFactions
  L7_2 = L7_2[A0_2]
  L7_2 = L7_2.uGuid
  L8_2 = _tFactions
  L8_2 = L8_2[A1_2]
  L8_2 = L8_2.uGuid
  L9_2 = A2_2
  L6_2(L7_2, L8_2, L9_2)
  L6_2 = GetRelation
  L7_2 = A0_2
  L8_2 = A1_2
  L6_2 = L6_2(L7_2, L8_2)
  L7_2 = ConvertRelationToAttitudeLevel
  L8_2 = L6_2
  L7_2 = L7_2(L8_2)
  if A1_2 == "Pmc" then
    L8_2 = Hud
    L8_2 = L8_2.FactionDisplay
    L9_2 = L8_2
    L8_2 = L8_2.SetValue
    L10_2 = {}
    L10_2.sFaction = A0_2
    L11_2 = ConvertRelationToMeterValue
    L12_2 = GetRelation
    L13_2 = A0_2
    L14_2 = A1_2
    L12_2, L13_2, L14_2, L15_2, L16_2 = L12_2(L13_2, L14_2)
    L11_2 = L11_2(L12_2, L13_2, L14_2, L15_2, L16_2)
    L10_2.nValue = L11_2
    L10_2.bInitialize = A3_2
    L8_2(L9_2, L10_2)
    L8_2 = GetPlayerVisibleName
    L9_2 = A0_2
    L8_2 = L8_2(L9_2)
    if L8_2 then
      L9_2 = _tFactions
      L9_2 = L9_2[A0_2]
      L9_2 = L9_2.sPdaIcon
      L10_2 = Pda
      L10_2 = L10_2.Database
      L11_2 = L10_2
      L10_2 = L10_2.SetFactionAttitude
      L12_2 = {}
      L12_2.sName = L8_2
      L12_2.sTexture = L9_2
      L13_2 = ConvertRelationToMeterValue
      L14_2 = GetRelation
      L15_2 = A0_2
      L16_2 = A1_2
      L14_2, L15_2, L16_2 = L14_2(L15_2, L16_2)
      L13_2 = L13_2(L14_2, L15_2, L16_2)
      L12_2.nAttitude = L13_2
      L10_2(L11_2, L12_2)
    end
    L9_2 = _knRelationMax
    if L6_2 >= L9_2 then
      L9_2 = _tFactions
      L9_2 = L9_2[A0_2]
      L9_2 = L9_2.sMaxRelationAchievement
      if L9_2 then
        L10_2 = MrxAchievements
        L10_2 = L10_2.NetGrantAchievement
        L11_2 = L9_2
        L10_2(L11_2)
      end
    end
  end
  if L5_2 ~= L7_2 or A3_2 then
    L8_2 = Event
    L8_2 = L8_2.Post
    L9_2 = "Attitude"
    L10_2 = {}
    L11_2 = A0_2
    L12_2 = A1_2
    L13_2 = GetAttitudeFromLevel
    L14_2 = L5_2
    L13_2 = L13_2(L14_2)
    L14_2 = GetAttitudeFromLevel
    L15_2 = L7_2
    L14_2, L15_2, L16_2 = L14_2(L15_2)
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L10_2[3] = L13_2
    L10_2[4] = L14_2
    L10_2[5] = L15_2
    L10_2[6] = L16_2
    L8_2(L9_2, L10_2)
  end
end

SetRelation = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = GetRelation
  L4_2 = A0_2
  L5_2 = A1_2
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = SetRelation
  L5_2 = A0_2
  L6_2 = A1_2
  L7_2 = L3_2 + A2_2
  L4_2(L5_2, L6_2, L7_2)
end

ChangeRelation = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = _CreateAttitudeChangeEvent
  L4_2 = false
  L5_2 = A0_2
  L6_2 = A1_2
  L7_2 = A2_2
  return L3_2(L4_2, L5_2, L6_2, L7_2)
end

CreateAttitudeChangeEvent = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = _CreateAttitudeChangeEvent
  L4_2 = true
  L5_2 = A0_2
  L6_2 = A1_2
  L7_2 = A2_2
  return L3_2(L4_2, L5_2, L6_2, L7_2)
end

CreatePersistentAttitudeChangeEvent = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  if A1_2 then
    L4_2 = A1_2[2]
    if L4_2 ~= "Pmc" then
      return
    end
  end
  L4_2 = Event
  L4_2 = L4_2.Create
  if A0_2 then
    L5_2 = Event
    L4_2 = L5_2.CreatePersistent
  end
  L5_2 = L4_2
  L6_2 = Event
  L6_2 = L6_2.ScriptEvent
  L7_2 = {}
  L8_2 = "Attitude"
  
  function L9_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L1_3 = A1_2
    if L1_3 then
      L1_3 = 1
      L2_3 = 4
      L3_3 = 1
      for L4_3 = L1_3, L2_3, L3_3 do
        L5_3 = A1_2
        L5_3 = L5_3[L4_3]
        if L5_3 then
          L5_3 = A1_2
          L5_3 = L5_3[L4_3]
          L6_3 = A0_3[L4_3]
          if L5_3 ~= L6_3 then
            L5_3 = false
            return L5_3
          end
        end
      end
    end
    L1_3 = true
    return L1_3
  end
  
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L8_2 = A2_2
  L9_2 = A3_2
  return L5_2(L6_2, L7_2, L8_2, L9_2)
end

_CreateAttitudeChangeEvent = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = _knRelationMin
  L1_2 = A0_2 - L1_2
  L2_2 = _knRelationMax
  L3_2 = _knRelationMin
  L2_2 = L2_2 - L3_2
  L1_2 = L1_2 / L2_2
  L2_2 = _knAttitudeMeterMax
  L3_2 = _knAttitudeMeterMin
  L2_2 = L2_2 - L3_2
  L2_2 = L2_2 * L1_2
  L3_2 = _knAttitudeMeterMin
  L2_2 = L2_2 + L3_2
  return L2_2
end

ConvertRelationToMeterValue = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = ipairs
  L2_2 = _tAttitudes
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L5_2.tRange
    L6_2 = L6_2[2]
    L7_2 = L5_2.tRange
    L7_2 = L7_2[1]
    L7_2 = L7_2 == "["
    L8_2 = L5_2.tRange
    L8_2 = L8_2[3]
    L9_2 = L5_2.tRange
    L9_2 = L9_2[4]
    L9_2 = L9_2 == "]"
    L10_2 = A0_2 > L6_2
    if L7_2 then
      L10_2 = A0_2 >= L6_2
    end
    L11_2 = A0_2 < L8_2
    if L9_2 then
      L11_2 = A0_2 <= L8_2
    end
    if L10_2 and L11_2 then
      return L4_2
    end
  end
end

ConvertRelationToAttitudeLevel = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = _tAttitudeLevelsToLabels
  L1_2 = L1_2[A0_2]
  return L1_2
end

GetAttitudeFromLevel = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = {}
  L1_2 = pairs
  L2_2 = _tFactions
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = table
    L6_2 = L6_2.insert
    L7_2 = L0_2
    L8_2 = L4_2
    L6_2(L7_2, L8_2)
  end
  L1_2 = table
  L1_2 = L1_2.sort
  L2_2 = L0_2
  L1_2(L2_2)
  return L0_2
end

GetFactionAbbrevs = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = _tFactionTemplateToAbbrev
  L1_2 = L1_2[A0_2]
  return L1_2
end

GetFactionAbbrev = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = pairs
  L2_2 = _tFactions
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L5_2.uGuid
    if L6_2 == A0_2 then
      return L4_2
    end
  end
  L1_2 = nil
  return L1_2
end

GetFactionAbbrevFromFactionGuid = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = _tFactions
  L1_2 = L1_2[A0_2]
  L1_2 = L1_2.sFactionTemplate
  return L1_2
end

GetFactionTemplateName = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L0_2 = {}
  L1_2 = pairs
  L2_2 = _tFactions
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = IsAttitudeMutable
    L7_2 = L4_2
    L6_2 = L6_2(L7_2)
    if L6_2 then
      L6_2 = TestAttitude
      L7_2 = L4_2
      L8_2 = "Pmc"
      L9_2 = "<"
      L10_2 = "Friendly"
      L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
      if L6_2 then
        L6_2 = table
        L6_2 = L6_2.insert
        L7_2 = L0_2
        L8_2 = L4_2
        L6_2(L7_2, L8_2)
      end
    end
  end
  return L0_2
end

GetBribableFactions = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = {}
  L1_2 = ipairs
  L2_2 = _tAttitudes
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L5_2.sLabel
    L7_2 = GetAttitudeMedianValue
    L8_2 = L5_2.sLabel
    L7_2 = L7_2(L8_2)
    L0_2[L6_2] = L7_2
  end
  return L0_2
end

GetAttitudes = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = _tAttitudeLabelsToLevels
  L1_2 = L1_2[A0_2]
  L2_2 = _tAttitudes
  L2_2 = L2_2[L1_2]
  L3_2 = L2_2.tRange
  L3_2 = L3_2[2]
  L4_2 = L2_2.tRange
  L4_2 = L4_2[3]
  L5_2 = L4_2 - L3_2
  L5_2 = L5_2 / 2
  L5_2 = L5_2 + L3_2
  return L5_2
end

GetAttitudeMedianValue = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = GetAttitudeLevel
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = _tAttitudes
  L3_2 = L3_2[L2_2]
  L3_2 = L3_2.tRgbColor
  return L3_2
end

GetRgbColor = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L0_2 = {}
  L1_2 = {}
  L2_2 = pairs
  L3_2 = _tFactions
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = {}
    L0_2[L5_2] = L7_2
    L7_2 = pairs
    L8_2 = _tFactions
    L7_2, L8_2, L9_2 = L7_2(L8_2)
    for L10_2, L11_2 in L7_2, L8_2, L9_2 do
      if L5_2 ~= L10_2 then
        L12_2 = L0_2[L5_2]
        L13_2 = GetRelation
        L14_2 = L5_2
        L15_2 = L10_2
        L13_2 = L13_2(L14_2, L15_2)
        L12_2[L10_2] = L13_2
      end
    end
    L7_2 = IsAttitudeMutable
    L8_2 = L5_2
    L7_2 = L7_2(L8_2)
    if L7_2 then
      L7_2 = table
      L7_2 = L7_2.insert
      L8_2 = L1_2
      L9_2 = L5_2
      L7_2(L8_2, L9_2)
    end
  end
  L2_2 = {}
  L2_2.tRelations = L0_2
  L2_2.tMutableFactions = L1_2
  L3_2 = nCivilianCasualties
  L2_2.nCivilianCasualties = L3_2
  L3_2 = nCivilianPenalty
  L2_2.nCivilianPenalty = L3_2
  return L2_2
end

SaveSingleton = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  if not A0_2 then
    return
  end
  L1_2 = A0_2.tMutableFactions
  if L1_2 then
    L2_2 = ipairs
    L3_2 = L1_2
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2, L6_2 in L2_2, L3_2, L4_2 do
      L7_2 = SetAttitudeMutable
      L8_2 = L6_2
      L9_2 = true
      L7_2(L8_2, L9_2)
    end
  end
  L2_2 = A0_2.tRelations
  if not L2_2 then
    return
  end
  L3_2 = pairs
  L4_2 = _tFactions
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = pairs
    L9_2 = _tFactions
    L8_2, L9_2, L10_2 = L8_2(L9_2)
    for L11_2, L12_2 in L8_2, L9_2, L10_2 do
      L13_2 = L2_2[L6_2]
      if L13_2 and L6_2 ~= L11_2 then
        L13_2 = L2_2[L6_2]
        L13_2 = L13_2[L11_2]
        if L13_2 then
          L14_2 = SetRelation
          L15_2 = L6_2
          L16_2 = L11_2
          L17_2 = L13_2
          L18_2 = true
          L14_2(L15_2, L16_2, L17_2, L18_2)
        end
      end
    end
  end
  L3_2 = A0_2.nCivilianCasualties
  nCivilianCasualties = L3_2
  L3_2 = A0_2.nCivilianPenalty
  nCivilianPenalty = L3_2
end

LoadSingleton = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = "[Generic.Factions."
  L2_2 = A0_2
  L3_2 = ".Long]"
  L1_2 = L1_2 .. L2_2 .. L3_2
  return L1_2
end

GetPlayerVisibleName = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = "[Generic.Factions."
  L2_2 = A0_2
  L3_2 = ".Short]"
  L1_2 = L1_2 .. L2_2 .. L3_2
  return L1_2
end

GetShortPlayerVisibleName = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = "[Generic.Factions."
  L2_2 = A0_2
  L3_2 = ".Adjectival]"
  L1_2 = L1_2 .. L2_2 .. L3_2
  return L1_2
end

GetAdjective = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = _tFactions
  L1_2 = L1_2[A0_2]
  L1_2 = L1_2.sInlineIcon
  return L1_2
end

GetInlineIcon = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = _tFactions
  L1_2 = L1_2[A0_2]
  L1_2 = L1_2.sMarkerTexture
  return L1_2
end

GetMarkerTexture = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = Event
  L0_2 = L0_2.CreatePersistent
  L1_2 = Event
  L1_2 = L1_2.ObjectDeath
  L2_2 = {}
  L3_2 = "civ && human"
  L2_2[1] = L3_2
  L3_2 = ResolveCivCasualty
  L0_2 = L0_2(L1_2, L2_2, L3_2)
  uEvent = L0_2
end

CivCasualtySetup = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = false
  bKilledByPlayer = L3_2
  if A2_2 then
    L3_2 = Player
    L3_2 = L3_2.GetPrimaryCharacter
    L3_2 = L3_2()
    L3_2 = A2_2 == L3_2
    bKilledByPlayer = L3_2
  end
  L3_2 = bKilledByPlayer
  if L3_2 then
    L3_2 = Net
    L3_2 = L3_2.IsActive
    L3_2 = L3_2()
    if L3_2 then
      L3_2 = Player
      L3_2 = L3_2.GetPrimaryCharacter
      L3_2 = L3_2()
      if A2_2 == L3_2 then
        L3_2 = Net
        L3_2 = L3_2.SendCustomEvent
        L4_2 = "MrxFactionManager"
        L5_2 = NETEVENT_CIVKILL
        L6_2 = {}
        L7_2 = 0
        L6_2[1] = L7_2
        L3_2(L4_2, L5_2, L6_2)
      else
        L3_2 = Player
        L3_2 = L3_2.GetSecondaryCharacter
        L3_2 = L3_2()
        if A2_2 == L3_2 then
          L3_2 = Net
          L3_2 = L3_2.SendCustomEvent
          L4_2 = "MrxFactionManager"
          L5_2 = NETEVENT_CIVKILL
          L6_2 = {}
          L7_2 = 1
          L6_2[1] = L7_2
          L3_2(L4_2, L5_2, L6_2)
        end
      end
    end
    L3_2 = ChargeCivCasualty
    L4_2 = A2_2
    L3_2(L4_2)
  end
end

ResolveCivCasualty = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L1_2 = nCivilianPenalty
  if not L1_2 then
    L1_2 = -5000
  end
  nCivilianPenalty = L1_2
  L1_2 = nCivilianCasualties
  if not L1_2 then
    L1_2 = 0
  end
  nCivilianCasualties = L1_2
  L1_2 = nCivilianCasualties
  if L1_2 == 0 then
  end
  L1_2 = nCivilianCasualties
  L1_2 = L1_2 + 1
  nCivilianCasualties = L1_2
  L1_2 = nCivilianCasualties
  if 19 < L1_2 then
    L1_2 = 1
    nCivilianCasualties = L1_2
    L1_2 = nCivilianPenalty
    L1_2 = L1_2 * 2
    nCivilianPenalty = L1_2
    L1_2 = math
    L1_2 = L1_2.max
    L2_2 = nCivilianPenalty
    L3_2 = -1000000
    L1_2 = L1_2(L2_2, L3_2)
    nCivilianPenalty = L1_2
  end
  L1_2 = Event
  L1_2 = L1_2.Post
  L2_2 = "CollateralDamage"
  L3_2 = {}
  L4_2 = A0_2
  L3_2[1] = L4_2
  L1_2(L2_2, L3_2)
  L1_2 = MrxPmc
  L1_2 = L1_2.AddCashQty
  L2_2 = nCivilianPenalty
  L3_2 = true
  L4_2 = "[Generic.Collateral]"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.StartTutorial
  L2_2 = "CollateralDamage"
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = {}
  L2_2 = {}
  L3_2 = "Fiona.CollateralDamage.Generic02"
  L2_2[1] = L3_2
  L1_2[1] = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.GetCharacterIdentity
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 == "mattias" then
    L2_2 = {}
    L3_2 = {}
    L4_2 = "Fiona.CollateralDamage.Generic01"
    L3_2[1] = L4_2
    L4_2 = 0.2
    L5_2 = {}
    L5_2.mattias = "Mattias.CollateralDamage.Generic01"
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
    L1_2[5] = L2_2
  else
    L2_2 = {}
    L3_2 = "Fiona.CollateralDamage.Generic01"
    L2_2[1] = L3_2
    L1_2[5] = L2_2
  end
  L2_2 = {}
  L3_2 = "Fiona.CollateralDamage.Generic03"
  L2_2[1] = L3_2
  L1_2[10] = L2_2
  L2_2 = {}
  L3_2 = "Fiona.CollateralDamage.Generic04"
  L2_2[1] = L3_2
  L1_2[15] = L2_2
  L2_2 = nCivilianCasualties
  L2_2 = L1_2[L2_2]
  if L2_2 then
    L2_2 = MrxVoSequence
    L2_2 = L2_2.Start
    L3_2 = nCivilianCasualties
    L3_2 = L1_2[L3_2]
    L4_2 = false
    L5_2 = MrxVoSequence
    L5_2 = L5_2.knPriorityFreeplay
    L2_2(L3_2, L4_2, L5_2)
  else
    L2_2 = math
    L2_2 = L2_2.randf
    L2_2 = L2_2()
    if L2_2 < 0.4 then
      L2_2 = {}
      L3_2 = {}
      L4_2 = MrxUtil
      L4_2 = L4_2.GetRandomTableElement
      L5_2 = {}
      L6_2 = "Chris.Reporting.Sorry.01"
      L7_2 = "Chris.Reporting.Sorry.02"
      L8_2 = "Chris_Phil01_Chris_Destroy_Civilians_Self_Vehicle_x_x_02"
      L9_2 = "Chris_Phil01_Chris_Destroy_Civilians_Self_Vehicle_x_x_03"
      L10_2 = "Chris_Phil01_Chris_Destroy_Civilians_Self_Vehicle_x_x_06"
      L11_2 = "Chris_Phil01_Chris_Destroy_Civilians_Self_x_x_x_01"
      L12_2 = "Chris_Phil01_Chris_Destroy_Civilians_Self_x_x_x_03"
      L13_2 = "Chris_Phil01_Chris_Destroy_Civilians_Self_x_x_x_04"
      L14_2 = "Chris_Phil01_Chris_Destroy_Civilians_Self_x_x_x_05"
      L15_2 = "Chris_Phil01_Chris_Destroy_Civilians_Self_x_x_x_06"
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      L5_2[3] = L8_2
      L5_2[4] = L9_2
      L5_2[5] = L10_2
      L5_2[6] = L11_2
      L5_2[7] = L12_2
      L5_2[8] = L13_2
      L5_2[9] = L14_2
      L5_2[10] = L15_2
      L4_2 = L4_2(L5_2)
      L3_2.chris = L4_2
      L4_2 = MrxUtil
      L4_2 = L4_2.GetRandomTableElement
      L5_2 = {}
      L6_2 = "Jen.Reporting.Sorry.01"
      L7_2 = "Jen.Reporting.Sorry.02"
      L8_2 = "Jen_Jen01_Jen_Destroy_Civilians_Jen_Vehicle_x_x_02"
      L9_2 = "Jen_Jen01_Jen_Destroy_Civilians_Jen_Vehicle_x_x_03"
      L10_2 = "Jen_Jen01_Jen_Destroy_Civilians_Jen_Vehicle_x_x_05"
      L11_2 = "Jen_Jen01_Jen_Destroy_Civilians_Jen_Vehicle_x_x_06"
      L12_2 = "Jen_Jen01_Jen_Destroy_Civilians_Jen_x_x_x_01"
      L13_2 = "Jen_Jen01_Jen_Destroy_Civilians_Jen_x_x_x_02"
      L14_2 = "Jen_Jen01_Jen_Destroy_Civilians_Jen_x_x_x_03"
      L15_2 = "Jen_Jen01_Jen_Destroy_Civilians_Jen_x_x_x_04"
      L16_2 = "Jen_Jen01_Jen_Destroy_Civilians_Jen_x_x_x_05"
      L17_2 = "Jen_Jen01_Jen_Destroy_Civilians_Jen_x_x_x_06"
      L18_2 = "Jen_Jen01_Jen_Destroy_Civilians_Jen_x_x_x_07"
      L19_2 = "Jen_Jen01_Jen_Destroy_Civilians_Jen_x_x_x_08"
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      L5_2[3] = L8_2
      L5_2[4] = L9_2
      L5_2[5] = L10_2
      L5_2[6] = L11_2
      L5_2[7] = L12_2
      L5_2[8] = L13_2
      L5_2[9] = L14_2
      L5_2[10] = L15_2
      L5_2[11] = L16_2
      L5_2[12] = L17_2
      L5_2[13] = L18_2
      L5_2[14] = L19_2
      L4_2 = L4_2(L5_2)
      L3_2.jennifer = L4_2
      L4_2 = MrxUtil
      L4_2 = L4_2.GetRandomTableElement
      L5_2 = {}
      L6_2 = "Mattias.Reporting.Sorry.01"
      L7_2 = "Mattias.Reporting.Sorry.02"
      L8_2 = "Mattias_Peter01_Mattias_Destroy_Civilians_Mattias_Vehicle_x_x_02"
      L9_2 = "Mattias_Peter01_Mattias_Destroy_Civilians_Mattias_Vehicle_x_x_03"
      L10_2 = "Mattias_Peter01_Mattias_Destroy_Civilians_Mattias_x_x_x_01"
      L11_2 = "Mattias_Peter01_Mattias_Destroy_Civilians_Mattias_x_x_x_02"
      L12_2 = "Mattias_Peter01_Mattias_Destroy_Civilians_Mattias_x_x_x_03"
      L13_2 = "Mattias_Peter01_Mattias_Destroy_Civilians_Mattias_x_x_x_04"
      L14_2 = "Mattias_Peter01_Mattias_Destroy_Civilians_Mattias_x_x_x_05"
      L15_2 = "Mattias_Peter01_Mattias_Destroy_Civilians_Mattias_x_x_x_06"
      L16_2 = "Mattias_Peter01_Mattias_Destroy_Civilians_Mattias_x_x_x_07"
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      L5_2[3] = L8_2
      L5_2[4] = L9_2
      L5_2[5] = L10_2
      L5_2[6] = L11_2
      L5_2[7] = L12_2
      L5_2[8] = L13_2
      L5_2[9] = L14_2
      L5_2[10] = L15_2
      L5_2[11] = L16_2
      L4_2 = L4_2(L5_2)
      L3_2.mattias = L4_2
      L2_2[1] = L3_2
      L1_2 = L2_2
      L2_2 = MrxVoSequence
      L2_2 = L2_2.Start
      L3_2 = L1_2
      L4_2 = false
      L5_2 = MrxVoSequence
      L5_2 = L5_2.knPriorityFreeplay
      L2_2(L3_2, L4_2, L5_2)
    end
  end
end

ChargeCivCasualty = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  if A1_2 then
    L2_2 = pairs
    L3_2 = _tFactions
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2, L6_2 in L2_2, L3_2, L4_2 do
      L7_2 = String
      L7_2 = L7_2.GetHash
      L8_2 = L5_2
      L7_2 = L7_2(L8_2)
      if L7_2 == A1_2 then
        return L5_2
      end
    end
  else
    L2_2 = GetFactionAbbrev
    L3_2 = GetFaction
    L4_2 = A0_2
    L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L3_2(L4_2)
    return L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  end
  L2_2 = "NO NAME"
  return L2_2
end

GetFactionStringAbbrev = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = GetFactionStringAbbrev
  L4_2 = A0_2
  L5_2 = A1_2
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = RemoveReportingDisplay
  L5_2 = A0_2
  L6_2 = L3_2
  L7_2 = A2_2
  L4_2(L5_2, L6_2, L7_2)
end

NetSafeRemoveReportingDisplay = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = GetFactionStringAbbrev
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = HandleReporter0
  L4_2 = A0_2
  L5_2 = L2_2
  L3_2(L4_2, L5_2)
end

NetSafeHandleReporter0 = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = GetFactionStringAbbrev
  L4_2 = A0_2
  L5_2 = A1_2
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = HandleReporter1
  L5_2 = A0_2
  L6_2 = L3_2
  L7_2 = A2_2
  L4_2(L5_2, L6_2, L7_2)
end

NetSafeHandleReporter1 = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = GetFactionStringAbbrev
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = HandleReporter2
  L4_2 = A0_2
  L5_2 = L2_2
  L3_2(L4_2, L5_2)
end

NetSafeHandleReporter2 = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = GetFactionStringAbbrev
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = FinishedReporting
  L4_2 = A0_2
  L5_2 = L2_2
  L3_2(L4_2, L5_2)
end

NetSafeFinishedReporting = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  L3_2 = uMarker
  if L3_2 then
    L3_2 = Marker
    L3_2 = L3_2.Remove
    L4_2 = uMarker
    L3_2(L4_2)
    L3_2 = nil
    uMarker = L3_2
  end
  L3_2 = uMarkerBeam
  if L3_2 then
    L3_2 = Marker
    L3_2 = L3_2.Remove
    L4_2 = uMarkerBeam
    L3_2(L4_2)
    L3_2 = nil
    uMarkerBeam = L3_2
  end
  L3_2 = Marker
  L3_2 = L3_2.HaltPulse
  L4_2 = A0_2
  L3_2(L4_2)
  L3_2 = _G
  L3_2 = L3_2.Minimap
  L4_2 = L3_2
  L3_2 = L3_2.DeleteObjective
  L5_2 = "Reporter"
  L3_2(L4_2, L5_2)
  if A2_2 == true then
    L3_2 = bActiveReporter
    if L3_2 then
      L3_2 = false
      bActiveReporter = L3_2
      L3_2 = VO
      L3_2 = L3_2.Cancel
      L4_2 = A0_2
      L5_2 = false
      L3_2(L4_2, L5_2)
      L3_2 = Hud
      L3_2 = L3_2.FactionDisplay
      L4_2 = L3_2
      L3_2 = L3_2.HideMeter
      L5_2 = {}
      L5_2.sFaction = A1_2
      L3_2(L4_2, L5_2)
    end
  end
end

RemoveReportingDisplay = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L3_2 = _tFactions
  L3_2 = L3_2[A1_2]
  L4_2 = uMarker
  if not L4_2 then
    L4_2 = Marker
    L4_2 = L4_2.AddBlip
    L5_2 = A0_2
    L6_2 = L3_2.sMarkerTexture
    L7_2 = 32
    L8_2 = 255
    L9_2 = 255
    L10_2 = 255
    L11_2 = 255
    L12_2 = 2
    L13_2 = nil
    L14_2 = nil
    L15_2 = 32
    L16_2 = nil
    L17_2 = true
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
    uMarker = L4_2
  end
  L4_2 = 255
  L5_2 = 0
  L6_2 = 0
  L7_2 = Marker
  L7_2 = L7_2.Pulse
  L8_2 = A0_2
  L9_2 = L4_2
  L10_2 = L5_2
  L11_2 = L6_2
  L7_2(L8_2, L9_2, L10_2, L11_2)
  L7_2 = {}
  L7_2.Pmc = "MiniMap_Icon_Faction_PMC"
  L7_2.Gur = "MiniMap_Icon_Faction_GR"
  L7_2.Oil = "MiniMap_Icon_Faction_OC"
  L7_2.Pir = "MiniMap_Icon_Faction_PR"
  L7_2.All = "MiniMap_Icon_Faction_AN"
  L7_2.Chi = "MiniMap_Icon_Faction_CH"
  L7_2.Vza = "MiniMap_Icon_Faction_VZ"
  L8_2 = L7_2[A1_2]
  L9_2 = Hud
  L9_2 = L9_2.Radar
  L10_2 = L9_2
  L9_2 = L9_2.AddObjective
  L11_2 = {}
  L11_2.sName = "Reporter"
  L11_2.uGuid = A0_2
  L11_2.nX = 0
  L11_2.nY = 250
  L11_2.nZ = 0
  L11_2.nR = 255
  L11_2.nG = 255
  L11_2.nB = 255
  L11_2.nWidth = 6
  L11_2.nHeight = 6
  L11_2.sTexture = L8_2
  L11_2.bSticky = true
  L11_2.nSortOrder = 2
  L9_2(L10_2, L11_2)
  L9_2 = Hud
  L9_2 = L9_2.Radar
  L10_2 = L9_2
  L9_2 = L9_2.AnimateObjectiveSonar
  L11_2 = {}
  L11_2.sName = "Reporter"
  L11_2.nDuration = 0
  L11_2.sTexture = "temp_radar_pulse"
  L11_2.nTotalBlips = 999999
  L11_2.nVisibleBlips = 8
  L11_2.nMinWidth = 4
  L11_2.nMaxWidth = 32
  L11_2.nBlipDelay = 0.5
  L11_2.nAlphaAtMin = 1
  L11_2.nAlphaAtMax = 1
  L11_2.nGrowSpeed = 32
  L11_2.nRed = L4_2
  L11_2.nGreen = L5_2
  L11_2.nBlue = L6_2
  L9_2(L10_2, L11_2)
  L9_2 = L3_2.tIntentVO
  if L9_2 then
    L9_2 = {}
    L10_2 = {}
    L11_2 = MrxUtil
    L11_2 = L11_2.GetRandomTableElement
    L12_2 = L3_2.tIntentVO
    L11_2 = L11_2(L12_2)
    L12_2 = A0_2
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L9_2[1] = L10_2
    if L9_2 then
      L10_2 = MrxVoSequence
      L10_2 = L10_2.Start
      L11_2 = L9_2
      L12_2 = nil
      L13_2 = MrxVoSequence
      L13_2 = L13_2.knPriorityFreeplay
      L10_2(L11_2, L12_2, L13_2)
    end
  end
  L9_2 = Net
  L9_2 = L9_2.IsServer
  L9_2 = L9_2()
  if L9_2 and not A2_2 then
    L9_2 = Net
    L9_2 = L9_2.SetPursuitReportingState
    L10_2 = A0_2
    L11_2 = 0
    L12_2 = A1_2
    L9_2(L10_2, L11_2, L12_2)
  end
end

HandleReporter0 = L0_1

function L0_1(A0_2, A1_2, A2_2)
end

HandleInvestigator = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = GetFactionAbbrevFromFactionGuid
  L4_2 = A2_2
  L3_2 = L3_2(L4_2)
  L4_2 = _tFactions
  L4_2 = L4_2[L3_2]
  L5_2 = L4_2.tTresspassVO
  if not L5_2 then
    L5_2 = _tTressPassGeneric
  end
  L6_2 = _bVoPlayed
  if L6_2 == false then
    L6_2 = true
    _bVoPlayed = L6_2
    if A1_2 then
      L6_2 = MrxUtil
      L6_2 = L6_2.GetRandomTableElement
      L7_2 = L5_2
      L6_2 = L6_2(L7_2)
      L7_2 = {}
      L8_2 = {}
      L9_2 = L6_2
      L10_2 = A0_2
      L8_2[1] = L9_2
      L8_2[2] = L10_2
      L7_2[1] = L8_2
      L8_2 = MrxVoSequence
      L8_2 = L8_2.Start
      L9_2 = L7_2
      L10_2 = nil
      L11_2 = MrxVoSequence
      L11_2 = L11_2.knPriorityContract
      L8_2(L9_2, L10_2, L11_2)
      L8_2 = Event
      L8_2 = L8_2.Create
      L9_2 = Event
      L9_2 = L9_2.TimerRelative
      L10_2 = {}
      L11_2 = 60
      L10_2[1] = L11_2
      
      function L11_2()
        local L0_3, L1_3
        L0_3 = false
        _bVoPlayed = L0_3
      end
      
      L8_2(L9_2, L10_2, L11_2)
    else
    end
  else
  end
end

HandleTressPasser = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = _tFactions
  L3_2 = L3_2[A1_2]
  L4_2 = AmIBeingJammed
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if L4_2 then
    L4_2 = L3_2.tJammedVO
    if L4_2 then
      L4_2 = MrxUtil
      L4_2 = L4_2.GetRandomTableElement
      L5_2 = L3_2.tJammedVO
      L4_2 = L4_2(L5_2)
      L5_2 = {}
      L6_2 = {}
      L7_2 = L4_2
      L8_2 = A0_2
      L6_2[1] = L7_2
      L6_2[2] = L8_2
      L7_2 = {}
      L8_2 = HandleReporter2
      L9_2 = {}
      L10_2 = A0_2
      L11_2 = A1_2
      L9_2[1] = L10_2
      L9_2[2] = L11_2
      L7_2[1] = L8_2
      L7_2[2] = L9_2
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      L6_2 = MrxVoSequence
      L6_2 = L6_2.Start
      L7_2 = L5_2
      L8_2 = nil
      L9_2 = MrxVoSequence
      L9_2 = L9_2.knPriorityFreeplay
      L6_2(L7_2, L8_2, L9_2)
    elseif A1_2 == "Pir" then
      L4_2 = MrxVoSequence
      L4_2 = L4_2.Start
      L5_2 = "Fiona.PirateCoverage.Reporting02"
      L6_2 = nil
      L7_2 = MrxVoSequence
      L7_2 = L7_2.knPriorityFreeplay
      L4_2(L5_2, L6_2, L7_2)
      L4_2 = HandleReporter2
      L5_2 = A0_2
      L6_2 = A1_2
      L4_2(L5_2, L6_2)
    else
      L4_2 = HandleReporter2
      L5_2 = A0_2
      L6_2 = A1_2
      L4_2(L5_2, L6_2)
    end
  else
    L4_2 = Net
    L4_2 = L4_2.IsClient
    L4_2 = L4_2()
    if L4_2 then
      if A2_2 == true then
        L4_2 = Hud
        L4_2 = L4_2.FactionDisplay
        L5_2 = L4_2
        L4_2 = L4_2.StartTimer
        L6_2 = {}
        L6_2.nDuration = 10
        L6_2.sFaction = A1_2
        L4_2(L5_2, L6_2)
      end
    else
      L4_2 = Hud
      L4_2 = L4_2.FactionDisplay
      L5_2 = L4_2
      L4_2 = L4_2.StartTimer
      L6_2 = {}
      L6_2.nDuration = 10
      L6_2.sFaction = A1_2
      L7_2 = FinishedReporting
      L6_2.fCallback = L7_2
      L7_2 = {}
      L8_2 = A0_2
      L9_2 = A1_2
      L7_2[1] = L8_2
      L7_2[2] = L9_2
      L6_2.tCallbackData = L7_2
      L4_2(L5_2, L6_2)
    end
    bActiveReporter = A0_2
    L4_2 = L3_2.tReportVO
    if L4_2 then
      L4_2 = MrxUtil
      L4_2 = L4_2.GetRandomTableElement
      L5_2 = L3_2.tReportVO
      L4_2 = L4_2(L5_2)
      L5_2 = {}
      L6_2 = {}
      L7_2 = L4_2
      L8_2 = A0_2
      L6_2[1] = L7_2
      L6_2[2] = L8_2
      L5_2[1] = L6_2
      L6_2 = MrxVoSequence
      L6_2 = L6_2.Start
      L7_2 = L5_2
      L8_2 = nil
      L9_2 = MrxVoSequence
      L9_2 = L9_2.knPriorityFreeplay
      L6_2(L7_2, L8_2, L9_2)
    elseif A1_2 == "Pir" then
      L4_2 = MrxVoSequence
      L4_2 = L4_2.Start
      L5_2 = {}
      L6_2 = "Fiona.PirateCoverage.Reporting03"
      L5_2[1] = L6_2
      L6_2 = nil
      L7_2 = MrxVoSequence
      L7_2 = L7_2.knPriorityFreeplay
      L4_2(L5_2, L6_2, L7_2)
    else
      L4_2 = MrxVoSequence
      L4_2 = L4_2.Start
      L5_2 = {}
      L6_2 = "Fiona.Misc.Reporting01"
      L5_2[1] = L6_2
      L6_2 = nil
      L7_2 = MrxVoSequence
      L7_2 = L7_2.knPriorityFreeplay
      L4_2(L5_2, L6_2, L7_2)
    end
    L4_2 = Net
    L4_2 = L4_2.IsServer
    L4_2 = L4_2()
    if L4_2 then
      L4_2 = Net
      L4_2 = L4_2.SetPursuitReportingState
      L5_2 = A0_2
      L6_2 = 1
      L7_2 = A1_2
      L4_2(L5_2, L6_2, L7_2)
    end
  end
end

HandleReporter1 = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = _tFactions
  L2_2 = L2_2[A1_2]
  L3_2 = RemoveReportingDisplay
  L4_2 = A0_2
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
  L3_2 = bActiveReporter
  if L3_2 then
    L3_2 = false
    bActiveReporter = L3_2
    L3_2 = VO
    L3_2 = L3_2.Cancel
    L4_2 = A0_2
    L5_2 = false
    L3_2(L4_2, L5_2)
    L3_2 = Hud
    L3_2 = L3_2.FactionDisplay
    L4_2 = L3_2
    L3_2 = L3_2.HideMeter
    L5_2 = {}
    L5_2.sFaction = A1_2
    L3_2(L4_2, L5_2)
  end
  L3_2 = L2_2.nReportFrequency
  if L3_2 then
    L3_2 = SetReportDelay
    L4_2 = L2_2.nReportFrequency
    L3_2(L4_2)
  else
    L3_2 = SetReportDelay
    L4_2 = 15
    L3_2(L4_2)
  end
  L3_2 = Net
  L3_2 = L3_2.IsServer
  L3_2 = L3_2()
  if L3_2 then
    L3_2 = Net
    L3_2 = L3_2.SetPursuitReportingState
    L4_2 = A0_2
    L5_2 = 2
    L6_2 = A1_2
    L3_2(L4_2, L5_2, L6_2)
  end
end

HandleReporter2 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = MrxSupport
  L1_2 = L1_2.TestAALevel
  L2_2 = "jammer"
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    L1_2 = false
    return L1_2
  end
  L1_2 = GetFaction
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L2_2 = pairs
    L3_2 = MrxSupport
    L3_2 = L3_2.tAA
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2, L6_2 in L2_2, L3_2, L4_2 do
      L7_2 = type
      L8_2 = L5_2
      L7_2 = L7_2(L8_2)
      if L7_2 == "userdata" then
        L7_2 = Vehicle
        L7_2 = L7_2.GetDriver
        L8_2 = L5_2
        L7_2 = L7_2(L8_2)
        if L7_2 then
          L8_2 = GetFaction
          L9_2 = L7_2
          L8_2 = L8_2(L9_2)
          if L8_2 and L8_2 ~= L1_2 then
            L9_2 = true
            return L9_2
          end
        end
      end
    end
  end
end

AmIBeingJammed = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = GetFactionStringAbbrev
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = _tFactions
  L3_2 = L3_2[L2_2]
  if A1_2 == 0 then
    L4_2 = ValidateReporter
    L5_2 = A0_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      L4_2 = HandleReporter0
      L5_2 = A0_2
      L6_2 = L2_2
      L4_2(L5_2, L6_2)
    else
      L4_2 = Report
      L4_2 = L4_2.Failed
      L5_2 = A0_2
      L4_2(L5_2)
    end
  elseif A1_2 == 1 then
    L4_2 = ValidateReporter
    L5_2 = A0_2
    L4_2 = L4_2(L5_2)
    if not L4_2 then
      return
    else
      L4_2 = bActiveReporter
      if L4_2 then
        L4_2 = bActiveReporter
        L4_2 = L4_2 ~= A0_2
        if L4_2 ~= A0_2 then
          L4_2 = Debug
          L4_2 = L4_2.Printdf
          L5_2 = "bActiveReporter ~= uGuid (we're getting a status change for a non-reporter)"
          L4_2(L5_2)
          L4_2 = HandleReporter0
          L5_2 = A0_2
          L6_2 = L2_2
          L7_2 = true
          L4_2(L5_2, L6_2, L7_2)
      end
      else
        L4_2 = HandleReporter1
        L5_2 = A0_2
        L6_2 = L2_2
        L4_2(L5_2, L6_2)
      end
    end
  elseif A1_2 == 2 then
    L4_2 = HandleReporter2
    L5_2 = A0_2
    L6_2 = L2_2
    L4_2(L5_2, L6_2)
  end
end

HandleReporter = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = GetFactionStringAbbrev
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = _tFactions
  L2_2 = L2_2[L1_2]
  L3_2 = CanAttitudeBeMutable
  L4_2 = L1_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L3_2 = IsAttitudeMutable
    L4_2 = L1_2
    L3_2 = L3_2(L4_2)
    if not L3_2 then
      L3_2 = false
      return L3_2
  end
  else
    L3_2 = tDisabledReporters
    L3_2 = L3_2[A0_2]
    if L3_2 then
      L3_2 = GetFaction
      L4_2 = A0_2
      L3_2 = L3_2(L4_2)
      if not L3_2 then
        L3_2 = "Civ"
      end
      L4_2 = Report
      L4_2 = L4_2.SetDelay
      L5_2 = Pg
      L5_2 = L5_2.GetGuidByName
      L6_2 = L3_2
      L5_2 = L5_2(L6_2)
      L6_2 = 3
      L4_2(L5_2, L6_2)
      L4_2 = false
      return L4_2
    else
      L3_2 = sFaction
      if L3_2 ~= "Civ" then
        L3_2 = sFaction
        if L3_2 ~= "VZ" then
          L3_2 = bReportingDisabled
          if not L3_2 then
            L3_2 = _tFactions
            L3_2 = L3_2[L1_2]
            if L3_2 then
              L3_2 = _tFactions
              L3_2 = L3_2[L1_2]
              L3_2 = L3_2.bCanReport
              if L3_2 then
                goto lbl_61
              end
            end
          end
        end
      end
      L3_2 = false
      do return L3_2 end
      goto lbl_73
      ::lbl_61::
      L3_2 = Object
      L3_2 = L3_2.HasLabel
      L4_2 = A0_2
      L5_2 = "Female"
      L3_2 = L3_2(L4_2, L5_2)
      if L3_2 then
        L3_2 = false
        return L3_2
      else
        L3_2 = true
        return L3_2
      end
    end
  end
  ::lbl_73::
end

ValidateReporter = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = false
  bActiveReporter = L2_2
  L2_2 = RemoveReportingDisplay
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
  L2_2 = _tFactions
  L2_2 = L2_2[A1_2]
  if L2_2 then
    L2_2 = CanAttitudeBeMutable
    L3_2 = A1_2
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = Report
      L2_2 = L2_2.GetInfractions
      L3_2 = A0_2
      L2_2 = L2_2(L3_2)
      if L2_2 then
        L3_2 = pairs
        L4_2 = L2_2
        L3_2, L4_2, L5_2 = L3_2(L4_2)
        for L6_2, L7_2 in L3_2, L4_2, L5_2 do
          L8_2 = Debug
          L8_2 = L8_2.Printf
          L9_2 = tostring
          L10_2 = L6_2
          L9_2 = L9_2(L10_2)
          L10_2 = ":\n"
          L11_2 = tostring
          L12_2 = L7_2
          L11_2 = L11_2(L12_2)
          L12_2 = "--------------------"
          L9_2 = L9_2 .. L10_2 .. L11_2 .. L12_2
          L8_2(L9_2)
        end
        L3_2 = 0
        L4_2 = L2_2.DamageObject
        L4_2 = L4_2[2]
        L4_2 = L4_2 * 1
        L3_2 = L3_2 + L4_2
        L4_2 = L2_2.DestroyObject
        L4_2 = L4_2[2]
        L4_2 = L4_2 * 25
        L3_2 = L3_2 + L4_2
        L4_2 = L2_2.Trespassing
        L4_2 = L4_2[2]
        L4_2 = L4_2 * 20
        L3_2 = L3_2 + L4_2
        L4_2 = L2_2.Hijack
        L4_2 = L4_2[2]
        L4_2 = L4_2 * 10
        L3_2 = L3_2 + L4_2
        L4_2 = L2_2.SpecialEvent
        L4_2 = L4_2[1]
        L5_2 = L2_2.SpecialEvent
        L5_2 = L5_2[2]
        L4_2 = L4_2 * L5_2
        L3_2 = L3_2 + L4_2
        L4_2 = L2_2.DestroyPerson
        L4_2 = L4_2[2]
        L4_2 = L4_2 * 50
        L3_2 = L3_2 + L4_2
        L4_2 = L2_2.DamagePerson
        L4_2 = L4_2[2]
        L4_2 = L4_2 * 3
        L3_2 = L3_2 + L4_2
        L4_2 = math
        L4_2 = L4_2.max
        L5_2 = L3_2
        L6_2 = -60
        L4_2 = L4_2(L5_2, L6_2)
        L3_2 = L4_2
        L4_2 = ChangeRelation
        L5_2 = A1_2
        L6_2 = "Pmc"
        L7_2 = -L3_2
        L4_2(L5_2, L6_2, L7_2)
      end
    end
  end
  L2_2 = Report
  L2_2 = L2_2.Completed
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = _tFactions
  L2_2 = L2_2[A1_2]
  if L2_2 then
    L2_2 = _tFactions
    L2_2 = L2_2[A1_2]
    L2_2 = L2_2.nReportFrequency
    if L2_2 then
      L2_2 = SetReportDelay
      L3_2 = _tFactions
      L3_2 = L3_2[A1_2]
      L3_2 = L3_2.nReportFrequency
      L3_2 = L3_2 * 2
      L2_2(L3_2)
  end
  else
    L2_2 = SetReportDelay
    L3_2 = 30
    L2_2(L3_2)
  end
  L2_2 = GetRelation
  L3_2 = A1_2
  L4_2 = "Pmc"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = _knRelationMin
  if L2_2 <= L3_2 then
    L2_2 = IncrementPursuit
    L3_2 = A1_2
    L2_2(L3_2)
  else
    L2_2 = _tFactions
    L2_2 = L2_2[A1_2]
    L2_2 = L2_2.tReportedVO
    if L2_2 then
      L2_2 = MrxUtil
      L2_2 = L2_2.GetRandomTableElement
      L3_2 = _tFactions
      L3_2 = L3_2[A1_2]
      L3_2 = L3_2.tReportedVO
      L2_2 = L2_2(L3_2)
      L3_2 = MrxVoSequence
      L3_2 = L3_2.Start
      L4_2 = L2_2
      L5_2 = nil
      L6_2 = MrxVoSequence
      L6_2 = L6_2.knPriorityFreeplay
      L3_2(L4_2, L5_2, L6_2)
    end
  end
  L2_2 = Event
  L2_2 = L2_2.Post
  L3_2 = "HeroReported"
  L4_2 = {}
  L5_2 = _tFactions
  L5_2 = L5_2[A1_2]
  L5_2 = L5_2.sFactionTemplate
  L6_2 = A0_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L2_2(L3_2, L4_2)
  L2_2 = Net
  L2_2 = L2_2.IsServer
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = Net
    L2_2 = L2_2.SetPursuitReportingState
    L3_2 = A0_2
    L4_2 = 3
    L5_2 = A1_2
    L2_2(L3_2, L4_2, L5_2)
  end
end

FinishedReporting = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = pairs
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
  end
end

expand = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = tFactionGuids
  if not L1_2 then
    L1_2 = {}
    L2_2 = Pg
    L2_2 = L2_2.GetGuidByName
    L3_2 = "Allied"
    L2_2 = L2_2(L3_2)
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = "China"
    L3_2 = L3_2(L4_2)
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "OC"
    L4_2 = L4_2(L5_2)
    L5_2 = Pg
    L5_2 = L5_2.GetGuidByName
    L6_2 = "Guerilla"
    L5_2 = L5_2(L6_2)
    L6_2 = Pg
    L6_2 = L6_2.GetGuidByName
    L7_2 = "Pirate"
    L6_2 = L6_2(L7_2)
    L7_2 = Pg
    L7_2 = L7_2.GetGuidByName
    L8_2 = "VZ"
    L7_2 = L7_2(L8_2)
    L8_2 = Pg
    L8_2 = L8_2.GetGuidByName
    L9_2 = "Civ"
    L8_2, L9_2 = L8_2(L9_2)
    L1_2[1] = L2_2
    L1_2[2] = L3_2
    L1_2[3] = L4_2
    L1_2[4] = L5_2
    L1_2[5] = L6_2
    L1_2[6] = L7_2
    L1_2[7] = L8_2
    L1_2[8] = L9_2
  end
  tFactionGuids = L1_2
  L1_2 = pairs
  L2_2 = tFactionGuids
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Report
    L6_2 = L6_2.SetDelay
    L7_2 = L5_2
    L8_2 = A0_2
    L6_2(L7_2, L8_2)
  end
end

SetReportDelay = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = pairs
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
  end
end

expand = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = {}
  L2_2 = "VZ"
  L3_2 = "Allied"
  L4_2 = "China"
  L5_2 = "Guerilla"
  L6_2 = "OC"
  L7_2 = "Pirate"
  L8_2 = "PMC"
  L9_2 = "Civ"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L1_2[7] = L8_2
  L1_2[8] = L9_2
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = Object
    L7_2 = L7_2.HasLabel
    L8_2 = A0_2
    L9_2 = L6_2
    L7_2 = L7_2(L8_2, L9_2)
    if L7_2 then
      return L6_2
    end
  end
  L2_2 = "Civ"
  return L2_2
end

GetFaction = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Object
  L1_2 = L1_2.IsDisguised
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = Vehicle
    L1_2 = L1_2.GetFromRider
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    L2_2 = GetFaction
    L3_2 = L1_2
    return L2_2(L3_2)
  end
  L1_2 = GetFaction
  L2_2 = A0_2
  return L1_2(L2_2)
end

GetPerceivedFaction = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 == "string" then
    L1_2 = Pg
    L1_2 = L1_2.GetGuidByName
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    A0_2 = L1_2
  end
  if not A0_2 then
    return
  end
  L1_2 = bActiveReporter
  if A0_2 == L1_2 then
    L1_2 = HandleReporter
    L2_2 = bActiveReporter
    L3_2 = 2
    L1_2(L2_2, L3_2)
  end
  L1_2 = tDisabledReporters
  L1_2[A0_2] = true
end

DisableReporter = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 == "string" then
    L1_2 = Pg
    L1_2 = L1_2.GetGuidByName
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    A0_2 = L1_2
  end
  if not A0_2 then
    return
  end
  L1_2 = tDisabledReporters
  if not L1_2 then
    L1_2 = {}
  end
  tDisabledReporters = L1_2
  L1_2 = tDisabledReporters
  L1_2[A0_2] = nil
end

EnableReporter = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  bReportingDisabled = A0_2
  L1_2 = bReportingDisabled
  if L1_2 then
    L1_2 = bActiveReporter
    if L1_2 then
      L1_2 = HandleReporter
      L2_2 = bActiveReporter
      L3_2 = 2
      L1_2(L2_2, L3_2)
    end
  else
    L1_2 = pairs
    L2_2 = _tFactions
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    for L4_2, L5_2 in L1_2, L2_2, L3_2 do
      L6_2 = L5_2.sFactionTemplate
      if L6_2 then
        L6_2 = Report
        L6_2 = L6_2.SetDelay
        L7_2 = Pg
        L7_2 = L7_2.GetGuidByName
        L8_2 = L5_2.sFactionTemplate
        L7_2 = L7_2(L8_2)
        L8_2 = 1
        L6_2(L7_2, L8_2)
      end
    end
  end
end

DisableReporting = L0_1

function L0_1(A0_2, A1_2)
  local L2_2
  L2_2 = _tFactions
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L2_2 = _tFactions
    L2_2 = L2_2[A0_2]
    L2_2.bCanReport = A1_2
  else
  end
end

SetFactionReporting = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = _tFactions
  L2_2 = L2_2[A0_2]
  L2_2 = L2_2.sFactionTemplate
  L1_2 = L1_2(L2_2)
  L2_2 = Pg
  L2_2 = L2_2.GetPursuitState
  L2_2 = L2_2()
  L3_2 = L2_2.Level
  L3_2 = L3_2 + 1
  L4_2 = Math
  L4_2 = L4_2.min
  L5_2 = L3_2
  L6_2 = 3
  L4_2 = L4_2(L5_2, L6_2)
  L3_2 = L4_2
  L4_2 = Pg
  L4_2 = L4_2.SetPursuit
  L5_2 = L1_2
  L6_2 = L3_2
  L7_2 = true
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = Pg
  L4_2 = L4_2.SetPursuitSeconds
  L5_2 = L1_2
  L6_2 = 5
  L7_2 = true
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = Hud
  L4_2 = L4_2.FactionDisplay
  L5_2 = L4_2
  L4_2 = L4_2.StartPursuit
  L6_2 = {}
  L6_2.nDuration = 5
  L6_2.sFaction = A0_2
  L4_2(L5_2, L6_2)
  L4_2 = _tFactions
  L4_2 = L4_2[A0_2]
  L4_2 = L4_2.tPursuitVO
  if L4_2 then
    L4_2 = MrxUtil
    L4_2 = L4_2.GetRandomTableElement
    L5_2 = _tFactions
    L5_2 = L5_2[A0_2]
    L5_2 = L5_2.tPursuitVO
    L4_2 = L4_2(L5_2)
    L5_2 = MrxVoSequence
    L5_2 = L5_2.Start
    L6_2 = L4_2
    L7_2 = nil
    L8_2 = MrxVoSequence
    L8_2 = L8_2.knPriorityFreeplay
    L5_2(L6_2, L7_2, L8_2)
  end
end

IncrementPursuit = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = Pg
  L2_2 = L2_2.LockPursuit
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
  L2_2 = GetFaction
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = GetFactionAbbrev
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  L4_2 = Hud
  L4_2 = L4_2.FactionDisplay
  L5_2 = L4_2
  L4_2 = L4_2.StartPursuit
  L6_2 = {}
  L6_2.sFaction = L3_2
  L6_2.nDuration = -1
  L4_2(L5_2, L6_2)
end

LockPursuit = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = pairs
  L1_2 = _tFactions
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2 in L0_2, L1_2, L2_2 do
    L4_2 = Hud
    L4_2 = L4_2.FactionDisplay
    L5_2 = L4_2
    L4_2 = L4_2.HideMeter
    L6_2 = {}
    L6_2.sFaction = L3_2
    L4_2(L5_2, L6_2)
  end
  L0_2 = Pg
  L0_2 = L0_2.ClearPursuitLock
  L1_2 = true
  L0_2(L1_2)
end

ClearPursuitLock = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = Pg
  L3_2 = L3_2.SetCustomPursuit
  L4_2 = A0_2
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = GetFaction
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  L4_2 = GetFactionAbbrev
  L5_2 = L3_2
  L4_2 = L4_2(L5_2)
  L5_2 = Hud
  L5_2 = L5_2.FactionDisplay
  L6_2 = L5_2
  L5_2 = L5_2.StartPursuit
  L7_2 = {}
  L7_2.sFaction = L4_2
  L7_2.nDuration = -1
  L5_2(L6_2, L7_2)
end

SetCustomPursuit = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = pairs
  L1_2 = _tFactions
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2 in L0_2, L1_2, L2_2 do
    L4_2 = Hud
    L4_2 = L4_2.FactionDisplay
    L5_2 = L4_2
    L4_2 = L4_2.HideMeter
    L6_2 = {}
    L6_2.sFaction = L3_2
    L4_2(L5_2, L6_2)
  end
  L0_2 = Pg
  L0_2 = L0_2.ClearCustomPursuit
  L0_2()
end

ClearCustomPursuit = L0_1
L0_1 = {}
L1_1 = {}
L2_1 = {}
L3_1 = "altitude"
L4_1 = 70
L2_1[L3_1] = L4_1
L3_1 = "speed"
L4_1 = 120
L2_1[L3_1] = L4_1
L3_1 = "template"
L4_1 = "Support Vehicle (Tucano)"
L2_1[L3_1] = L4_1
L3_1 = "bMulti"
L4_1 = true
L2_1[L3_1] = L4_1
L3_1 = {}
L4_1 = "altitude"
L5_1 = 100
L3_1[L4_1] = L5_1
L4_1 = "speed"
L5_1 = 130
L3_1[L4_1] = L5_1
L4_1 = "template"
L5_1 = "Support Vehicle (Tucano)"
L3_1[L4_1] = L5_1
L4_1 = "bMulti"
L5_1 = true
L3_1[L4_1] = L5_1
L4_1 = {}
L5_1 = "altitude"
L6_1 = 130
L4_1[L5_1] = L6_1
L5_1 = "speed"
L6_1 = 140
L4_1[L5_1] = L6_1
L5_1 = "template"
L6_1 = "Support Vehicle (Tucano)"
L4_1[L5_1] = L6_1
L5_1 = "bMulti"
L6_1 = true
L4_1[L5_1] = L6_1
L1_1[1] = L2_1
L1_1[2] = L3_1
L1_1[3] = L4_1
L2_1 = {}
L3_1 = {}
L4_1 = "altitude"
L5_1 = 60
L3_1[L4_1] = L5_1
L4_1 = "speed"
L5_1 = 100
L3_1[L4_1] = L5_1
L4_1 = "template"
L5_1 = "Support Vehicle (OV10)"
L3_1[L4_1] = L5_1
L4_1 = {}
L5_1 = "altitude"
L6_1 = 90
L4_1[L5_1] = L6_1
L5_1 = "speed"
L6_1 = 110
L4_1[L5_1] = L6_1
L5_1 = "template"
L6_1 = "Support Vehicle (OV10)"
L4_1[L5_1] = L6_1
L5_1 = {}
L6_1 = "altitude"
L7_1 = 120
L5_1[L6_1] = L7_1
L6_1 = "speed"
L7_1 = 120
L5_1[L6_1] = L7_1
L6_1 = "template"
L7_1 = "Support Vehicle (OV10)"
L5_1[L6_1] = L7_1
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L3_1 = {}
L4_1 = {}
L5_1 = "altitude"
L6_1 = 50
L4_1[L5_1] = L6_1
L5_1 = "speed"
L6_1 = 80
L4_1[L5_1] = L6_1
L5_1 = "template"
L6_1 = "Support Vehicle (Cessna)"
L4_1[L5_1] = L6_1
L5_1 = {}
L6_1 = "altitude"
L7_1 = 80
L5_1[L6_1] = L7_1
L6_1 = "speed"
L7_1 = 80
L5_1[L6_1] = L7_1
L6_1 = "template"
L7_1 = "Support Vehicle (Cessna)"
L5_1[L6_1] = L7_1
L6_1 = {}
L7_1 = "altitude"
L8_1 = 110
L6_1[L7_1] = L8_1
L7_1 = "speed"
L8_1 = 80
L6_1[L7_1] = L8_1
L7_1 = "template"
L8_1 = "Support Vehicle (Cessna)"
L6_1[L7_1] = L8_1
L7_1 = {}
L8_1 = "altitude"
L9_1 = 300
L7_1[L8_1] = L9_1
L8_1 = "speed"
L9_1 = 120
L7_1[L8_1] = L9_1
L8_1 = "template"
L9_1 = "Support Vehicle (727)"
L7_1[L8_1] = L9_1
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L3_1[4] = L7_1
L4_1 = {}
L5_1 = {}
L6_1 = "altitude"
L7_1 = 90
L5_1[L6_1] = L7_1
L6_1 = "speed"
L7_1 = 120
L5_1[L6_1] = L7_1
L6_1 = "template"
L7_1 = "Support Vehicle (A10)"
L5_1[L6_1] = L7_1
L6_1 = "bMulti"
L7_1 = true
L5_1[L6_1] = L7_1
L6_1 = {}
L7_1 = "altitude"
L8_1 = 60
L6_1[L7_1] = L8_1
L7_1 = "speed"
L8_1 = 120
L6_1[L7_1] = L8_1
L7_1 = "template"
L8_1 = "Support Vehicle (A10)"
L6_1[L7_1] = L8_1
L7_1 = "bMulti"
L8_1 = true
L6_1[L7_1] = L8_1
L7_1 = {}
L8_1 = "altitude"
L9_1 = 100
L7_1[L8_1] = L9_1
L8_1 = "speed"
L9_1 = 200
L7_1[L8_1] = L9_1
L8_1 = "template"
L9_1 = "Support Vehicle (F35)"
L7_1[L8_1] = L9_1
L8_1 = "bMulti"
L9_1 = true
L7_1[L8_1] = L9_1
L8_1 = {}
L9_1 = "altitude"
L10_1 = 300
L8_1[L9_1] = L10_1
L9_1 = "speed"
L10_1 = 160
L8_1[L9_1] = L10_1
L9_1 = "template"
L10_1 = "Support Vehicle (B2)"
L8_1[L9_1] = L10_1
L9_1 = {}
L10_1 = "altitude"
L11_1 = 180
L9_1[L10_1] = L11_1
L10_1 = "speed"
L11_1 = 220
L9_1[L10_1] = L11_1
L10_1 = "template"
L11_1 = "Support Vehicle (F117)"
L9_1[L10_1] = L11_1
L10_1 = {}
L11_1 = "altitude"
L12_1 = 250
L10_1[L11_1] = L12_1
L11_1 = "speed"
L12_1 = 120
L10_1[L11_1] = L12_1
L11_1 = "template"
L12_1 = "Support Vehicle (C130)"
L10_1[L11_1] = L12_1
L11_1 = {}
L12_1 = "altitude"
L13_1 = 180
L11_1[L12_1] = L13_1
L12_1 = "speed"
L13_1 = 120
L11_1[L12_1] = L13_1
L12_1 = "template"
L13_1 = "Support Vehicle (AC130)"
L11_1[L12_1] = L13_1
L12_1 = {}
L13_1 = "altitude"
L14_1 = 50
L12_1[L13_1] = L14_1
L13_1 = "speed"
L14_1 = 60
L12_1[L13_1] = L14_1
L13_1 = "template"
L14_1 = "Support Vehicle (Predator)"
L12_1[L13_1] = L14_1
L13_1 = {}
L14_1 = "altitude"
L15_1 = 60
L13_1[L14_1] = L15_1
L14_1 = "speed"
L15_1 = 60
L13_1[L14_1] = L15_1
L14_1 = "template"
L15_1 = "Support Vehicle (Predator)"
L13_1[L14_1] = L15_1
L14_1 = {}
L15_1 = "altitude"
L16_1 = 60
L14_1[L15_1] = L16_1
L15_1 = "speed"
L16_1 = 60
L14_1[L15_1] = L16_1
L15_1 = "template"
L16_1 = "Support Vehicle (Predator)"
L14_1[L15_1] = L16_1
L4_1[1] = L5_1
L4_1[2] = L6_1
L4_1[3] = L7_1
L4_1[4] = L8_1
L4_1[5] = L9_1
L4_1[6] = L10_1
L4_1[7] = L11_1
L4_1[8] = L12_1
L4_1[9] = L13_1
L4_1[10] = L14_1
L5_1 = {}
L6_1 = {}
L7_1 = "altitude"
L8_1 = 100
L6_1[L7_1] = L8_1
L7_1 = "speed"
L8_1 = 200
L6_1[L7_1] = L8_1
L7_1 = "template"
L8_1 = "Support Vehicle (Q5)"
L6_1[L7_1] = L8_1
L7_1 = "bMulti"
L8_1 = true
L6_1[L7_1] = L8_1
L7_1 = {}
L8_1 = "altitude"
L9_1 = 200
L7_1[L8_1] = L9_1
L8_1 = "speed"
L9_1 = 200
L7_1[L8_1] = L9_1
L8_1 = "template"
L9_1 = "Support Vehicle (Q5)"
L7_1[L8_1] = L9_1
L8_1 = "bMulti"
L9_1 = true
L7_1[L8_1] = L9_1
L8_1 = {}
L9_1 = "altitude"
L10_1 = 160
L8_1[L9_1] = L10_1
L9_1 = "speed"
L10_1 = 240
L8_1[L9_1] = L10_1
L9_1 = "template"
L10_1 = "Support Vehicle (Q5)"
L8_1[L9_1] = L10_1
L9_1 = "bMulti"
L10_1 = true
L8_1[L9_1] = L10_1
L5_1[1] = L6_1
L5_1[2] = L7_1
L5_1[3] = L8_1
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1
L0_1[5] = L5_1
tFlybys = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L0_2 = bReportingDisabled
  if not L0_2 then
    L0_2 = math
    L0_2 = L0_2.randi
    L1_2 = 3
    L0_2 = L0_2(L1_2)
    L1_2 = WifMissionFlow
    L1_2 = L1_2.HasKey
    L2_2 = "Invasion"
    L1_2 = L1_2(L2_2)
    if L1_2 then
      L0_2 = L0_2 + 2
    end
    L1_2 = tFlybys
    L1_2 = L1_2[L0_2]
    L2_2 = Math
    L2_2 = L2_2.randi
    L3_2 = table
    L3_2 = L3_2.getn
    L4_2 = L1_2
    L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2 = L3_2(L4_2)
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
    L2_2 = L1_2[L2_2]
    L3_2 = 1
    L4_2 = L2_2.bMulti
    if L4_2 then
      L4_2 = Math
      L4_2 = L4_2.randi
      L5_2 = 3
      L4_2 = L4_2(L5_2)
      L3_2 = L4_2
    end
    while 0 < L3_2 do
      L4_2 = Player
      L4_2 = L4_2.GetLocalCharacter
      L4_2 = L4_2()
      if L4_2 then
        L5_2 = Pg
        L5_2 = L5_2.FindPointFromCamera
        L6_2 = 300
        L7_2 = L2_2.altitude
        L8_2 = 10
        L9_2 = Player
        L9_2 = L9_2.GetLocalPlayer
        L9_2 = L9_2()
        L10_2 = math
        L10_2 = L10_2.randi
        L11_2 = 360
        L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2 = L10_2(L11_2)
        L5_2, L6_2, L7_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
        L8_2 = Pg
        L8_2 = L8_2.FindPointFromCamera
        L9_2 = 300
        L10_2 = L2_2.altitude
        L11_2 = 10
        L12_2 = Player
        L12_2 = L12_2.GetLocalPlayer
        L12_2 = L12_2()
        L13_2 = math
        L13_2 = L13_2.randi
        L14_2 = 360
        L13_2, L14_2, L15_2, L16_2, L17_2, L18_2 = L13_2(L14_2)
        L8_2, L9_2, L10_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
        L11_2 = L5_2
        L12_2 = L6_2
        fz = L7_2
        fy = L12_2
        fx = L11_2
        if L8_2 and L10_2 then
          L11_2 = fy
          if L11_2 then
            L11_2 = fy
            L12_2 = Math
            L12_2 = L12_2.randi
            L13_2 = 15
            L12_2 = L12_2(L13_2)
            L11_2 = L11_2 + L12_2
            L12_2 = Math
            L12_2 = L12_2.randi
            L13_2 = 15
            L12_2 = L12_2(L13_2)
            L11_2 = L11_2 - L12_2
            fy = L11_2
            L11_2 = Airstrike
            L11_2 = L11_2.Flyby
            L12_2 = L2_2.template
            L13_2 = L8_2
            L14_2 = L10_2
            L15_2 = fx
            L16_2 = fz
            L17_2 = fy
            L18_2 = L2_2.altitude
            L17_2 = L17_2 + L18_2
            L18_2 = L2_2.speed
            L11_2(L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
          else
          end
        else
        end
      end
      L3_2 = L3_2 - 1
    end
  end
  L0_2 = SetupNextFlyby
  L0_2()
end

RandomFlyby = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.TimerRelative
  L2_2 = {}
  L3_2 = Math
  L3_2 = L3_2.randi
  L4_2 = 71
  L3_2 = L3_2(L4_2)
  L3_2 = 19 + L3_2
  L2_2[1] = L3_2
  L3_2 = RandomFlyby
  L0_2(L1_2, L2_2, L3_2)
end

SetupNextFlyby = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  if A0_2 then
    L1_2 = _tFactions
    L1_2 = L1_2[A0_2]
    if L1_2 then
      L2_2 = L1_2.sPdaFactionId
      return L2_2
    end
  end
  L1_2 = nil
  return L1_2
end

GetPdaFactionIdFromFactionId = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = 1
  L2_2 = pairs
  L3_2 = _tFactions
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    if L1_2 == A0_2 then
      return L5_2
    end
    L1_2 = L1_2 + 1
  end
  L2_2 = nil
  return L2_2
end

GetFactionIdFromIndex = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = 1
  L2_2 = pairs
  L3_2 = _tFactions
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    if L5_2 == A0_2 then
      return L1_2
    end
    L1_2 = L1_2 + 1
  end
  L2_2 = nil
  return L2_2
end

GetIndexFromFactionId = L0_1
