local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxMissionFlow"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxCinematic"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiBase"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxLayerManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPlayState"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxStarterManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxState"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTransit"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "Munitions"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifVzBoundary"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifPmcInterior"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxAchievements"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVerifyManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifHints"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSoundBootstrap"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifBios"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifPmcInterior"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSoundCategories"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxMusic"
L0_1(L1_1)
L0_1 = import
L1_1 = "friendlygate"
L0_1(L1_1)

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
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = _BeginBlockingSequence
    L0_3()
    
    function L0_3()
      local L0_4, L1_4, L2_4
      L0_4 = UnlockMission
      L1_4 = "VzaCon001"
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
    
    function L1_3()
      local L0_4, L1_4, L2_4, L3_4
      L0_4 = WifBios
      L0_4 = L0_4.AddDossierEntry
      L1_4 = "BioChris"
      L0_4(L1_4)
      L0_4 = WifBios
      L0_4 = L0_4.AddDossierEntry
      L1_4 = "BioJennifer"
      L0_4(L1_4)
      L0_4 = WifBios
      L0_4 = L0_4.AddDossierEntry
      L1_4 = "BioMattias"
      L0_4(L1_4)
      L0_4 = WifBios
      L0_4 = L0_4.AddDossierEntry
      L1_4 = "BioFiona"
      L0_4(L1_4)
      L0_4 = WifBios
      L0_4 = L0_4.AddDossierEntry
      L1_4 = "BioSolano"
      L0_4(L1_4)
      L0_4 = WifBios
      L0_4 = L0_4.AddDossierEntry
      L1_4 = "BioBlanco"
      L0_4(L1_4)
      L0_4 = WifBios
      L0_4 = L0_4.AddDossierEntry
      L1_4 = "BioCarmona"
      L0_4(L1_4)
      L0_4 = SetGrappleEnabled
      L1_4 = false
      L0_4(L1_4)
      L0_4 = SetVehicleDisguiseEnabled
      L1_4 = false
      L0_4(L1_4)
      L0_4 = EnableResourceCounters
      L1_4 = false
      L0_4(L1_4)
      L0_4 = MrxSupportData
      L0_4 = L0_4.SetHeliPilotRecruited
      L1_4 = false
      L0_4(L1_4)
      L0_4 = MrxSupportData
      L0_4 = L0_4.SetMechanicRecruited
      L1_4 = false
      L0_4(L1_4)
      L0_4 = MrxSupportData
      L0_4 = L0_4.SetJetPilotRecruited
      L1_4 = false
      L0_4(L1_4)
      L0_4 = _PlayMovie
      L1_4 = {}
      L2_4 = "01_AOA_"
      L3_4 = L0_2
      L2_4 = L2_4 .. L3_4
      L1_4.sMovie = L2_4
      L2_4 = L0_3
      L1_4.fCallback = L2_4
      L1_4.bSubtitles = true
      L0_4(L1_4)
    end
    
    L2_3 = MrxCheatBootstrap
    L2_3 = L2_3.IsSkipModeEnabled
    L2_3 = L2_3()
    if not L2_3 then
      L2_3 = MrxState
      L2_3 = L2_3.Enter
      L3_3 = MrxState
      L3_3 = L3_3.STATE_WAITFORGAME
      L4_3 = L1_3
      L2_3(L3_3, L4_3)
    else
      L2_3 = L1_3
      L2_3()
    end
  end
  
  L2_2.fConseq = L3_2
  L1_2.Start = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "VzaCon001"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = _BeginBlockingSequence
    L0_3()
    
    function L0_3()
      local L0_4, L1_4
      L0_4 = UnlockMission
      L1_4 = "PmcCon001"
      L0_4(L1_4)
      L0_4 = MrxSoundBootstrap
      L0_4 = L0_4.SetPmcRadio
      L1_4 = "ReporterNeutral.MissionVO.VZCon01"
      L0_4(L1_4)
      L0_4 = _EndBlockingSequence
      L0_4()
    end
    
    function L1_3()
      local L0_4, L1_4, L2_4, L3_4
      L0_4 = WifVzBoundary
      L0_4 = L0_4.SetupBoundary00
      L0_4()
      L0_4 = GetMissionStartLocations
      L1_4 = "PmcCon001"
      L0_4 = L0_4(L1_4)
      L1_4 = type
      L2_4 = L0_4
      L1_4 = L1_4(L2_4)
      if L1_4 == "table" then
        L1_4 = MrxUtil
        L1_4 = L1_4.TeleportHeroesToLocations
        L2_4 = L0_4
        L3_4 = L0_3
        L1_4(L2_4, L3_4)
      end
    end
    
    function L2_3()
      local L0_4, L1_4, L2_4, L3_4
      L0_4 = EnableResourceCounters
      L1_4 = true
      L0_4(L1_4)
      L0_4 = MrxAchievements
      L0_4 = L0_4.NetGrantAchievement
      L1_4 = "ACHIEVEMENT_RAGE"
      L0_4(L1_4)
      L0_4 = _PlayMovie
      L1_4 = {}
      L2_4 = "02_AOB_"
      L3_4 = L0_2
      L2_4 = L2_4 .. L3_4
      L1_4.sMovie = L2_4
      L2_4 = L1_3
      L1_4.fCallback = L2_4
      L1_4.bSubtitles = true
      L0_4(L1_4)
    end
    
    L3_3 = MrxCheatBootstrap
    L3_3 = L3_3.IsSkipModeEnabled
    L3_3 = L3_3()
    if not L3_3 then
      L3_3 = MrxState
      L3_3 = L3_3.Enter
      L4_3 = MrxState
      L4_3 = L4_3.STATE_WAITFORGAME
      L5_3 = L2_3
      L3_3(L4_3, L5_3)
    else
      L3_3 = L2_3
      L3_3()
    end
  end
  
  L2_2.fConseq = L3_2
  L1_2.VzaCon001 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "PmcCon001"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = WifBios
    L0_3 = L0_3.AddDossierEntry
    L1_3 = "BioUP"
    L0_3(L1_3)
    L0_3 = WifBios
    L0_3 = L0_3.AddDossierEntry
    L1_3 = "BioRubin"
    L0_3(L1_3)
    L0_3 = _BeginBlockingSequence
    L0_3()
    L0_3 = WifHints
    L0_3 = L0_3.AddActiveHint
    L1_3 = "FionaHint25"
    L0_3(L1_3)
    
    function L0_3()
      local L0_4, L1_4, L2_4
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
    
    function L1_3()
      local L0_4, L1_4, L2_4, L3_4
      L0_4 = MrxAchievements
      L0_4 = L0_4.NetGrantAchievement
      L1_4 = "ACHIEVEMENT_HELLOHURRAY"
      L0_4(L1_4)
      L0_4 = WifVzBoundary
      L0_4 = L0_4.SetupBoundaryINTRO_OIL
      L0_4()
      L0_4 = Pg
      L0_4 = L0_4.GetGuidByName
      L1_4 = "_ocoutpost_wallgate 0x000f9a64"
      L0_4 = L0_4(L1_4)
      if L0_4 then
        L1_4 = friendlygate
        L1_4 = L1_4.LockGate
        L2_4 = L0_4
        L3_4 = true
        L1_4(L2_4, L3_4)
      end
      L1_4 = UnlockMission
      L2_4 = "OilCon020"
      L1_4(L2_4)
      L1_4 = UnlockMission
      L2_4 = "PmcCon031"
      L1_4(L2_4)
      L1_4 = UnlockMission
      L2_4 = "PmcJob001"
      L1_4(L2_4)
      L1_4 = WifPmcInterior
      L1_4 = L1_4.Unlock
      L1_4()
      L1_4 = WifPmcInterior
      L1_4 = L1_4.SetTeleportCallback
      L2_4 = L0_3
      L1_4(L2_4)
      L1_4 = WifPmcInterior
      L1_4 = L1_4.Enter
      L2_4 = true
      L1_4(L2_4)
    end
    
    function L2_3()
      local L0_4, L1_4, L2_4, L3_4, L4_4, L5_4
      L0_4 = MrxLayerManager
      L0_4 = L0_4.MarkForRemoval
      L1_4 = "Vz_State_Pmc_Pristine"
      L0_4(L1_4)
      L0_4 = {}
      L1_4 = "Vz_State_Pmc_LivedIn"
      L2_4 = "vz_state_gur_fuel_junglemountains"
      L3_4 = "vz_state_oil_fuel_maroutskirts"
      L4_4 = "vz_state_gurcon005_airportdefbase_staging"
      L5_4 = "vz_state_pmc_act1"
      L0_4[1] = L1_4
      L0_4[2] = L2_4
      L0_4[3] = L3_4
      L0_4[4] = L4_4
      L0_4[5] = L5_4
      L1_4 = MrxLayerManager
      L1_4 = L1_4.MarkForAddition
      L2_4 = L0_4
      L1_4(L2_4)
      L1_4 = MrxLayerManager
      L1_4 = L1_4.ProcessMarkedLayers
      L2_4 = L1_3
      L1_4(L2_4)
    end
    
    function L3_3()
      local L0_4, L1_4, L2_4, L3_4
      L0_4 = _PlayMovie
      L1_4 = {}
      L2_4 = "06_YNH_"
      L3_4 = L0_2
      L2_4 = L2_4 .. L3_4
      L1_4.sMovie = L2_4
      L2_4 = L2_3
      L1_4.fCallback = L2_4
      L1_4.bSubtitles = true
      L0_4(L1_4)
    end
    
    L4_3 = MrxCheatBootstrap
    L4_3 = L4_3.IsSkipModeEnabled
    L4_3 = L4_3()
    if not L4_3 then
      L4_3 = MrxState
      L4_3 = L4_3.Enter
      L5_3 = MrxState
      L5_3 = L5_3.STATE_WAITFORGAME
      L6_3 = L3_3
      L4_3(L5_3, L6_3)
    else
      L4_3 = L3_3
      L4_3()
    end
  end
  
  L2_2.fConseq = L3_2
  L1_2.PmcCon001 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "OilCon020"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = UnlockMission
    L1_3 = "OilCon021"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.RemoveActiveHint
    L1_3 = "FionaHint25"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.AddActiveHint
    L1_3 = "FionaHint21"
    L0_3(L1_3)
    L0_3 = MrxAchievements
    L0_3 = L0_3.AchievementAddCount
    L1_3 = "ACHIEVEMENT_GUN_RUNNER"
    L2_3 = 1
    L0_3(L1_3, L2_3)
    L0_3 = MrxCheatBootstrap
    L0_3 = L0_3.IsSkipModeEnabled
    L0_3 = L0_3()
    if not L0_3 then
      L0_3 = MrxVoSequence
      L0_3 = L0_3.Start
      L1_3 = {}
      L2_3 = "Fiona-In-Mission-Freeplay-None-21"
      L1_3[1] = L2_3
      L2_3 = nil
      L3_3 = MrxVoSequence
      L3_3 = L3_3.knPriorityFreeplay
      L0_3(L1_3, L2_3, L3_3)
    end
  end
  
  L2_2.fConseq = L3_2
  L1_2.OilCon020 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "OilCon021"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = WifHints
    L0_3 = L0_3.AddActiveHint
    L1_3 = "FionaHint22"
    L0_3(L1_3)
    L0_3 = MrxStarterManager
    L0_3 = L0_3.DestroyStarter
    L1_3 = "OilStarter5"
    L0_3(L1_3)
    L0_3 = MrxFactionManager
    L0_3 = L0_3.SetAttitudeMutable
    L1_3 = "Oil"
    L0_3(L1_3)
    L0_3 = Pg
    L0_3 = L0_3.GetGuidByName
    L1_3 = "_ocoutpost_wallgate 0x000f9a64"
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L1_3 = friendlygate
      L1_3 = L1_3.LockGate
      L2_3 = L0_3
      L3_3 = false
      L1_3(L2_3, L3_3)
    end
    L1_3 = SetVehicleDisguiseEnabled
    L2_3 = true
    L1_3(L2_3)
    L1_3 = UnlockMission
    L2_3 = "OilCon002"
    L1_3(L2_3)
    L1_3 = MrxLayerManager
    L1_3 = L1_3.MarkForRemoval
    L2_3 = "vz_state_OilCon021_staging"
    L1_3(L2_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.OilCon021 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "OilJob011"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "OilJob011_Target_01"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "OilJob011_Target_02"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "OilJob011_Target_03"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "OilJob011_Target_04"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "OilJob011_Target_05"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "OilJob012_Target_01"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "OilJob012_Target_02"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "OilJob012_Target_03"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "OilJob012_Target_04"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "OilJob012_Target_05"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.OilJob011 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "PmcCon002"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = _BeginBlockingSequence
    L0_3()
    
    function L0_3()
      local L0_4, L1_4, L2_4
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
    
    function L1_3()
      local L0_4, L1_4
      L0_4 = WifPmcInterior
      L0_4 = L0_4.SetTeleportCallback
      L1_4 = L0_3
      L0_4(L1_4)
      L0_4 = WifPmcInterior
      L0_4 = L0_4.Enter
      L1_4 = true
      L0_4(L1_4)
    end
    
    function L2_3()
      local L0_4, L1_4, L2_4
      L0_4 = MrxAchievements
      L0_4 = L0_4.NetGrantAchievement
      L1_4 = "ACHIEVEMENT_RUNNING_WITH_DEVIL"
      L0_4(L1_4)
      L0_4 = MrxSoundBootstrap
      L0_4 = L0_4.SetPmcRadio
      L1_4 = "ReporterNeutral.MissionVO.PMC02"
      L0_4(L1_4)
      L0_4 = WifHints
      L0_4 = L0_4.RemoveActiveHint
      L1_4 = "FionaHint10"
      L0_4(L1_4)
      L0_4 = MrxVerifyManager
      L0_4 = L0_4.SetKilledIfNotSet
      L1_4 = "PmcCon002 Blanco"
      L0_4(L1_4)
      L0_4 = _PlayMovie
      L1_4 = {}
      L1_4.sMovie = "11_SR1_S"
      L2_4 = L1_3
      L1_4.fCallback = L2_4
      L1_4.bSubtitles = true
      L0_4(L1_4)
    end
    
    L3_3 = MrxCheatBootstrap
    L3_3 = L3_3.IsSkipModeEnabled
    L3_3 = L3_3()
    if not L3_3 then
      L3_3 = MrxState
      L3_3 = L3_3.Enter
      L4_3 = MrxState
      L4_3 = L4_3.STATE_WAITFORGAME
      L5_3 = L2_3
      L3_3(L4_3, L5_3)
    else
      L3_3 = L2_3
      L3_3()
    end
  end
  
  L2_2.fConseq = L3_2
  L1_2.PmcCon002 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "PmcCon002"
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L0_3 = HasKey
      L1_3 = "MecIntro"
      L0_3 = L0_3(L1_3)
      L0_3 = not L0_3
    end
    return L0_3
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = WifBios
    L0_3 = L0_3.AddDossierEntry
    L1_3 = "BioEva"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.RemoveActiveHint
    L1_3 = "FionaHint18"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.AddActiveHint
    L1_3 = "FionaHint30"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.PmcCon002_NotMecIntro = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "PmcCon002"
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L0_3 = HasKey
      L1_3 = "MecIntro"
      L0_3 = L0_3(L1_3)
      if L0_3 then
        L0_3 = HasKey
        L1_3 = "MecCon001"
        L0_3 = L0_3(L1_3)
        L0_3 = not L0_3
      end
    end
    return L0_3
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = WifHints
    L0_3 = L0_3.RemoveActiveHint
    L1_3 = "FionaHint30"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.AddActiveHint
    L1_3 = "FionaHint26"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.PmcCon002_MecIntro = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "PmcCon002"
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L0_3 = HasKey
      L1_3 = "MecCon001"
      L0_3 = L0_3(L1_3)
      if L0_3 then
        L0_3 = HasKey
        L1_3 = "JetIntro"
        L0_3 = L0_3(L1_3)
        L0_3 = not L0_3
      end
    end
    return L0_3
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = WifHints
    L0_3 = L0_3.RemoveActiveHint
    L1_3 = "FionaHint26"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.AddActiveHint
    L1_3 = "FionaHint32"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.PmcCon002_MecCon001 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "PmcCon002"
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L0_3 = HasKey
      L1_3 = "JetIntro"
      L0_3 = L0_3(L1_3)
      if L0_3 then
        L0_3 = HasKey
        L1_3 = "JetCon001"
        L0_3 = L0_3(L1_3)
        L0_3 = not L0_3
      end
    end
    return L0_3
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = WifHints
    L0_3 = L0_3.AddActiveHint
    L1_3 = "FionaHint29"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.PmcCon002_JetIntro = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "PmcCon002"
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L0_3 = HasKey
      L1_3 = "JetCon001"
      L0_3 = L0_3(L1_3)
    end
    return L0_3
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = WifHints
    L0_3 = L0_3.AddActiveHint
    L1_3 = "FionaHint28"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "PmcCon003"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.PmcCon002_JetCon001 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "PmcCon003"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = AwardKey
    L1_3 = "Invasion"
    L0_3(L1_3)
    L0_3 = MrxSoundBootstrap
    L0_3 = L0_3.SetPmcRadio
    L1_3 = "ReporterNeutral.MissionVO.Invasion01"
    L0_3(L1_3)
    L0_3 = _BeginBlockingSequence
    L0_3()
    
    function L0_3()
      local L0_4, L1_4, L2_4
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
      L0_4 = WifVzBoundary
      L0_4 = L0_4.SetupBoundary02
      L0_4()
    end
    
    function L1_3()
      local L0_4, L1_4, L2_4, L3_4, L4_4, L5_4, L6_4, L7_4, L8_4, L9_4, L10_4, L11_4, L12_4, L13_4, L14_4, L15_4, L16_4, L17_4, L18_4, L19_4, L20_4, L21_4, L22_4, L23_4, L24_4, L25_4, L26_4, L27_4, L28_4, L29_4, L30_4, L31_4, L32_4, L33_4, L34_4, L35_4, L36_4, L37_4, L38_4, L39_4, L40_4, L41_4, L42_4, L43_4, L44_4, L45_4, L46_4, L47_4, L48_4, L49_4, L50_4, L51_4
      L0_4 = WifHints
      L0_4 = L0_4.RemoveActiveHint
      L1_4 = "FionaHint28"
      L0_4(L1_4)
      L0_4 = WifHints
      L0_4 = L0_4.AddActiveHint
      L1_4 = "FionaHint33"
      L0_4(L1_4)
      L0_4 = MrxAchievements
      L0_4 = L0_4.NetGrantAchievement
      L1_4 = "ACHIEVEMENT_BETTER_RUN"
      L0_4(L1_4)
      L0_4 = MrxVerifyManager
      L0_4 = L0_4.SetKilledIfNotSet
      L1_4 = "CarmonaTarget"
      L0_4(L1_4)
      L0_4 = _AddIntro
      L1_4 = "PmcBoss"
      L2_4 = "AllChi"
      L0_4(L1_4, L2_4)
      L0_4 = MrxLayerManager
      L0_4 = L0_4.MarkForRemoval
      L1_4 = {}
      L2_4 = "vz_state_amazon_act1"
      L3_4 = "vz_state_mar_industrial_act2"
      L4_4 = "vz_state_mar_city_pristine"
      L5_4 = "vz_state_mar_city_act1"
      L6_4 = "vz_state_mar_city_act1_depot"
      L1_4[1] = L2_4
      L1_4[2] = L3_4
      L1_4[3] = L4_4
      L1_4[4] = L5_4
      L1_4[5] = L6_4
      L0_4(L1_4)
      L0_4 = MrxLayerManager
      L0_4 = L0_4.MarkForAddition
      L1_4 = {}
      L2_4 = "vz_state_All_Hq_Structures"
      L3_4 = "vz_state_staging_all_HQ"
      L4_4 = "vz_state_staging_chi_HQ"
      L5_4 = "vz_state_cumana_act1ALL_N"
      L6_4 = "vz_state_cumana_act1ALL_S"
      L7_4 = "vz_state_cumana_act1ALL_staging"
      L8_4 = "vz_state_cumana_act1CHI"
      L9_4 = "vz_state_amazon_act2"
      L10_4 = "vz_state_margarita_act2"
      L11_4 = "vz_state_mar_industrial_act3"
      L12_4 = "vz_state_mar_city_ruined"
      L13_4 = "vz_state_mar_city_act2"
      L14_4 = "vz_state_car_dock_act1"
      L15_4 = "vz_state_car_estate_act1"
      L16_4 = "vz_state_car_big_lineregion"
      L17_4 = "vz_state_car_shanty_act1"
      L18_4 = "vz_state_All_fuel_amazon"
      L19_4 = "vz_state_chi_fuel_amazon"
      L20_4 = "vz_state_car_city_act1"
      L21_4 = "vz_state_vza_con001_post"
      L22_4 = "Vz_State_AllJob005_01"
      L23_4 = "Vz_State_AllJob005_02"
      L24_4 = "Vz_State_AllJob005_03"
      L25_4 = "Vz_State_AllJob005_04"
      L26_4 = "Vz_State_AllJob005_05"
      L27_4 = "Vz_State_AllJob005_01_Staging"
      L28_4 = "Vz_State_AllJob005_02_Staging"
      L29_4 = "Vz_State_AllJob005_03_Staging"
      L30_4 = "Vz_State_AllJob005_04_Staging"
      L31_4 = "Vz_State_AllJob005_05_Staging"
      L32_4 = "Vz_State_AllJob009_01_Staging"
      L33_4 = "Vz_State_AllJob009_02_Staging"
      L34_4 = "Vz_State_AllJob009_03_Staging"
      L35_4 = "Vz_State_AllJob009_04_Staging"
      L36_4 = "Vz_State_AllJob009_05_Staging"
      L37_4 = "Vz_State_AllJob010_01_Staging"
      L38_4 = "Vz_State_AllJob010_02_Staging"
      L39_4 = "Vz_State_AllJob010_03_Staging"
      L40_4 = "Vz_State_AllJob010_04_Staging"
      L41_4 = "Vz_State_AllJob010_05_Staging"
      L42_4 = "Vz_State_ChiCon005_a_Pristine"
      L43_4 = "Vz_State_ChiCon005_b_Pristine"
      L44_4 = "Vz_State_ChiCon005_c_Pristine"
      L45_4 = "Vz_State_ChiCon006_a_Pristine"
      L46_4 = "Vz_State_ChiCon006_b_Pristine"
      L47_4 = "Vz_State_ChiCon006_c_Pristine"
      L48_4 = "Vz_State_ChiJob005_A_Staging"
      L49_4 = "Vz_State_ChiJob005_B_Staging"
      L50_4 = "Vz_State_ChiJob005_C_Staging"
      L51_4 = "Vz_State_ChiJob005_D_Staging"
      L1_4[1] = L2_4
      L1_4[2] = L3_4
      L1_4[3] = L4_4
      L1_4[4] = L5_4
      L1_4[5] = L6_4
      L1_4[6] = L7_4
      L1_4[7] = L8_4
      L1_4[8] = L9_4
      L1_4[9] = L10_4
      L1_4[10] = L11_4
      L1_4[11] = L12_4
      L1_4[12] = L13_4
      L1_4[13] = L14_4
      L1_4[14] = L15_4
      L1_4[15] = L16_4
      L1_4[16] = L17_4
      L1_4[17] = L18_4
      L1_4[18] = L19_4
      L1_4[19] = L20_4
      L1_4[20] = L21_4
      L1_4[21] = L22_4
      L1_4[22] = L23_4
      L1_4[23] = L24_4
      L1_4[24] = L25_4
      L1_4[25] = L26_4
      L1_4[26] = L27_4
      L1_4[27] = L28_4
      L1_4[28] = L29_4
      L1_4[29] = L30_4
      L1_4[30] = L31_4
      L1_4[31] = L32_4
      L1_4[32] = L33_4
      L1_4[33] = L34_4
      L1_4[34] = L35_4
      L1_4[35] = L36_4
      L1_4[36] = L37_4
      L1_4[37] = L38_4
      L1_4[38] = L39_4
      L1_4[39] = L40_4
      L1_4[40] = L41_4
      L1_4[41] = L42_4
      L1_4[42] = L43_4
      L1_4[43] = L44_4
      L1_4[44] = L45_4
      L1_4[45] = L46_4
      L1_4[46] = L47_4
      L1_4[47] = L48_4
      L1_4[48] = L49_4
      L1_4[49] = L50_4
      L1_4[50] = L51_4
      L2_4 = "Vz_State_ChiJob005_E_Staging"
      L3_4 = "Vz_State_ChiJob005_F_Staging"
      L4_4 = "Vz_State_ChiJob005_G_Staging"
      L5_4 = "Vz_State_ChiJob009_A_Staging"
      L6_4 = "Vz_State_ChiJob010_01_Staging"
      L7_4 = "Vz_State_ChiJob010_02_Staging"
      L8_4 = "Vz_State_ChiJob010_03_Staging"
      L9_4 = "Vz_State_ChiJob010_04_Staging"
      L10_4 = "Vz_State_ChiJob010_05_Staging"
      L11_4 = "Vz_State_PirJob012_01_Pristine"
      L12_4 = "Vz_State_PirJob012_01_Staging"
      L13_4 = "Vz_State_PirJob012_02_Staging"
      L14_4 = "Vz_State_PirJob012_03_Pristine"
      L15_4 = "Vz_State_PirJob012_03_Staging"
      L16_4 = "Vz_State_PirJob012_04_Staging"
      L1_4[51] = L2_4
      L1_4[52] = L3_4
      L1_4[53] = L4_4
      L1_4[54] = L5_4
      L1_4[55] = L6_4
      L1_4[56] = L7_4
      L1_4[57] = L8_4
      L1_4[58] = L9_4
      L1_4[59] = L10_4
      L1_4[60] = L11_4
      L1_4[61] = L12_4
      L1_4[62] = L13_4
      L1_4[63] = L14_4
      L1_4[64] = L15_4
      L1_4[65] = L16_4
      L0_4(L1_4)
      L0_4 = _PlayMovie
      L1_4 = {}
      L1_4.sMovie = "11_SR2_S"
      L2_4 = L0_3
      L1_4.fCallback = L2_4
      L1_4.bSubtitles = true
      L0_4(L1_4)
    end
    
    L2_3 = MrxCheatBootstrap
    L2_3 = L2_3.IsSkipModeEnabled
    L2_3 = L2_3()
    if not L2_3 then
      L2_3 = MrxState
      L2_3 = L2_3.Enter
      L3_3 = MrxState
      L3_3 = L3_3.STATE_WAITFORGAME
      L4_3 = L1_3
      L2_3(L3_3, L4_3)
    else
      L2_3 = L1_3
      L2_3()
    end
  end
  
  L2_2.fConseq = L3_2
  L1_2.PmcCon003 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "AllChiIntro"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = WifBios
    L0_3 = L0_3.AddDossierEntry
    L1_3 = "BioAllies"
    L0_3(L1_3)
    L0_3 = WifBios
    L0_3 = L0_3.AddDossierEntry
    L1_3 = "BioChina"
    L0_3(L1_3)
    L0_3 = WifBios
    L0_3 = L0_3.AddDossierEntry
    L1_3 = "BioJoyce"
    L0_3(L1_3)
    L0_3 = WifBios
    L0_3 = L0_3.AddDossierEntry
    L1_3 = "BioPeng"
    L0_3(L1_3)
    L0_3 = MrxFactionManager
    L0_3 = L0_3.SetAttitudeMutable
    L1_3 = "All"
    L0_3(L1_3)
    L0_3 = MrxFactionManager
    L0_3 = L0_3.SetAttitudeMutable
    L1_3 = "Chi"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "AllCon050"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "ChiCon050"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.AllChiIntro = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "PmcCon004"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L0_3 = _BeginBlockingSequence
    L0_3()
    
    function L0_3()
      local L0_4, L1_4
      L0_4 = DestroyMission
      L1_4 = "AllCon001"
      L0_4(L1_4)
      L0_4 = DestroyMission
      L1_4 = "AllCon002"
      L0_4(L1_4)
      L0_4 = DestroyMission
      L1_4 = "AllCon003"
      L0_4(L1_4)
      L0_4 = DestroyMission
      L1_4 = "AllCon008"
      L0_4(L1_4)
      L0_4 = DestroyMission
      L1_4 = "AllCon050"
      L0_4(L1_4)
      L0_4 = DestroyMission
      L1_4 = "ChiCon001"
      L0_4(L1_4)
      L0_4 = DestroyMission
      L1_4 = "ChiCon002"
      L0_4(L1_4)
      L0_4 = DestroyMission
      L1_4 = "ChiCon003"
      L0_4(L1_4)
      L0_4 = DestroyMission
      L1_4 = "ChiCon008"
      L0_4(L1_4)
      L0_4 = DestroyMission
      L1_4 = "ChiCon050"
      L0_4(L1_4)
      L0_4 = DestroyMission
      L1_4 = "GurCon003"
      L0_4(L1_4)
      L0_4 = MrxStarterManager
      L0_4 = L0_4.DestroyStarter
      L1_4 = "AllStarter0"
      L0_4(L1_4)
      L0_4 = MrxStarterManager
      L0_4 = L0_4.DestroyStarter
      L1_4 = "ChiStarter0"
      L0_4(L1_4)
    end
    
    function L1_3(A0_4)
      local L1_4, L2_4, L3_4
      L1_4 = Sys
      L1_4 = L1_4.ForceNextAutosave
      if L1_4 then
        L1_4 = Sys
        L1_4 = L1_4.ForceNextAutosave
        L1_4()
      end
      L1_4 = MrxMusic
      L1_4 = L1_4.StopSpecialMusic
      L2_4 = "silence"
      L1_4(L2_4)
      L1_4 = MrxSoundCategories
      L1_4 = L1_4.Fade
      L2_4 = "credits"
      L3_4 = false
      L1_4(L2_4, L3_4)
      L2_4 = A0_4
      L1_4 = A0_4.SetSwfFile
      L3_4 = nil
      L1_4(L2_4, L3_4)
      L1_4 = MrxGuiBase
      L1_4 = L1_4.ReleaseControlFocus
      L2_4 = A0_4
      L1_4(L2_4)
      L1_4 = MrxGui
      L1_4 = L1_4.RemoveWidget
      L2_4 = A0_4
      L1_4(L2_4)
      L2_4 = A0_4
      L1_4 = A0_4.delete
      L1_4(L2_4)
      L1_4 = MrxGui
      L1_4 = L1_4.FadeFromColor
      L2_4 = 0
      L1_4(L2_4)
      L1_4 = _EndBlockingSequence
      L1_4()
      L1_4 = Sys
      L1_4 = L1_4.RequestGameState
      L2_4 = "unloading"
      L1_4(L2_4)
      L1_4 = Net
      L1_4 = L1_4.QuitGame
      L1_4()
    end
    
    function L2_3(A0_4)
      local L1_4, L2_4, L3_4, L4_4, L5_4, L6_4
      L1_4 = MrxMusic
      L1_4 = L1_4.PlaySpecialMusic
      L2_4 = "mu_maintheme"
      L1_4(L2_4)
      L2_4 = A0_4
      L1_4 = A0_4.SetFlashEventHandler
      L3_4 = "creditsEnd"
      L4_4 = L1_3
      L5_4 = {}
      L6_4 = A0_4
      L5_4[1] = L6_4
      L1_4(L2_4, L3_4, L4_4, L5_4)
      L2_4 = A0_4
      L1_4 = A0_4.SetEventHandler
      L3_4 = "ControllerInput"
      L4_4 = L1_3
      L1_4(L2_4, L3_4, L4_4)
      L1_4 = MrxGuiBase
      L1_4 = L1_4.GetControlFocus
      L2_4 = A0_4
      L1_4(L2_4)
    end
    
    function L3_3()
      local L0_4, L1_4, L2_4, L3_4, L4_4, L5_4, L6_4
      L0_4 = MrxGui
      L0_4 = L0_4.FadeToColor
      L1_4 = 0
      L0_4(L1_4)
      L0_4 = MrxCheatBootstrap
      L0_4 = L0_4.IsSkipModeEnabled
      L0_4 = L0_4()
      if not L0_4 then
        L0_4 = MrxState
        L0_4 = L0_4.Exit
        L1_4 = MrxState
        L1_4 = L1_4.STATE_WAITFORGAME
        L0_4(L1_4)
      end
      L0_4 = Sys
      L0_4 = L0_4.RequestGameState
      L1_4 = "cinematic"
      L0_4(L1_4)
      L0_4 = MrxGui
      L0_4 = L0_4.FlashWidget
      L1_4 = L0_4
      L0_4 = L0_4.new
      L0_4 = L0_4(L1_4)
      L2_4 = L0_4
      L1_4 = L0_4.SetFullscreen
      L3_4 = true
      L1_4(L2_4, L3_4)
      L2_4 = L0_4
      L1_4 = L0_4.SetSwfFile
      L3_4 = "credits"
      L4_4 = L2_3
      L5_4 = {}
      L6_4 = L0_4
      L5_4[1] = L6_4
      L1_4(L2_4, L3_4, L4_4, L5_4)
      L1_4 = MrxGui
      L1_4 = L1_4.AddWidget
      L2_4 = L0_4
      L1_4(L2_4)
      L1_4 = Net
      L1_4 = L1_4.IsServer
      L1_4 = L1_4()
      if L1_4 then
        L1_4 = Net
        L1_4 = L1_4.SendCustomEvent
        L2_4 = "WifMissionFlow"
        L3_4 = NETEVENT_CLIENTCREDITS
        L4_4 = {}
        L1_4(L2_4, L3_4, L4_4)
      end
    end
    
    function L4_3()
      local L0_4, L1_4, L2_4, L3_4
      L0_4 = WifHints
      L0_4 = L0_4.RemoveActiveHint
      L1_4 = "FionaHint06"
      L0_4(L1_4)
      L0_4 = MrxVerifyManager
      L0_4 = L0_4.SetSolanoVerified
      L0_4()
      L0_4 = "15_ACK_"
      L1_4 = L0_2
      L0_4 = L0_4 .. L1_4
      L1_4 = L0_3
      L1_4()
      L1_4 = MrxAchievements
      L1_4 = L1_4.NetGrantAchievement
      L2_4 = "ACHIEVEMENT_HERO_AND_MADMAN"
      L1_4(L2_4)
      L1_4 = MrxVerifyManager
      L1_4 = L1_4.CheckTechnoVikingAchievement
      L1_4 = L1_4()
      if L1_4 then
        L1_4 = MrxAchievements
        L1_4 = L1_4.NetGrantAchievement
        L2_4 = "ACHIEVEMENT_TECHNO_VIKING"
        L3_4 = Player
        L3_4 = L3_4.GetPrimaryPlayer
        L3_4 = L3_4()
        L1_4(L2_4, L3_4)
      end
      L1_4 = MrxSoundCategories
      L1_4 = L1_4.Fade
      L2_4 = "credits"
      L3_4 = true
      L1_4(L2_4, L3_4)
      L1_4 = _PlayMovie
      L2_4 = {}
      L2_4.sMovie = L0_4
      L3_4 = L3_3
      L2_4.fCallback = L3_4
      L2_4.bSubtitles = true
      L1_4(L2_4)
    end
    
    L5_3 = MrxCheatBootstrap
    L5_3 = L5_3.IsSkipModeEnabled
    L5_3 = L5_3()
    if not L5_3 then
      L5_3 = MrxState
      L5_3 = L5_3.Enter
      L6_3 = MrxState
      L6_3 = L6_3.STATE_WAITFORGAME
      L7_3 = L4_3
      L5_3(L6_3, L7_3)
    else
      L5_3 = L4_3
      L5_3()
    end
  end
  
  L2_2.fConseq = L3_2
  L1_2.PmcCon004 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "PmcCon016"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = UnlockMission
    L1_3 = "PmcCon015"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.PmcCon016 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "PmcCon031"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = UnlockMission
    L1_3 = "PmcCon032"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.PmcCon031 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "PmcCon032"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = UnlockMission
    L1_3 = "PmcCon033"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.PmcCon032 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = GetKeyValue
    L1_3 = "PmcCon031"
    L0_3 = L0_3(L1_3)
    L0_3 = 3 <= L0_3
    return L0_3
  end
  
  L2_2.fPrereq = L3_2
  L3_2 = _AddHeroCostume
  L2_2.fConseq = L3_2
  L1_2.PmcCon031_x3 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = GetKeyValue
    L1_3 = "PmcCon032"
    L0_3 = L0_3(L1_3)
    L0_3 = 3 <= L0_3
    return L0_3
  end
  
  L2_2.fPrereq = L3_2
  L3_2 = _AddHeroCostume
  L2_2.fConseq = L3_2
  L1_2.PmcCon032_x3 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = GetKeyValue
    L1_3 = "PmcCon033"
    L0_3 = L0_3(L1_3)
    L0_3 = 3 <= L0_3
    return L0_3
  end
  
  L2_2.fPrereq = L3_2
  L3_2 = _AddHeroCostume
  L2_2.fConseq = L3_2
  L1_2.PmcCon033_x3 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = GetKeyValue
    L1_3 = "PmcCon034"
    L0_3 = L0_3(L1_3)
    L0_3 = 3 <= L0_3
    return L0_3
  end
  
  L2_2.fPrereq = L3_2
  L3_2 = _AddHeroCostume
  L2_2.fConseq = L3_2
  L1_2.PmcCon034_x3 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "MecCon001"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = _BeginBlockingSequence
    L0_3()
    
    function L0_3()
      local L0_4, L1_4, L2_4
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
    
    function L1_3()
      local L0_4, L1_4, L2_4
      L0_4 = MrxStarterManager
      L0_4 = L0_4.DestroyStarter
      L1_4 = "MecBoss"
      L0_4(L1_4)
      L0_4 = WifHints
      L0_4 = L0_4.AddActiveHint
      L1_4 = "FionaHint16"
      L0_4(L1_4)
      L0_4 = WifHints
      L0_4 = L0_4.UnlockAllHints
      L1_4 = "Eva"
      L0_4(L1_4)
      L0_4 = UnlockMission
      L1_4 = "PmcCon016"
      L0_4(L1_4)
      L0_4 = SetGrappleEnabled
      L1_4 = true
      L0_4(L1_4)
      L0_4 = _RemoveIntro
      L1_4 = "HelPmcBoss"
      L2_4 = "Mec"
      L0_4(L1_4, L2_4)
      L0_4 = _AddIntro
      L1_4 = "MecPmcBoss"
      L2_4 = "Jet"
      L0_4(L1_4, L2_4)
      L0_4 = WifPmcInterior
      L0_4 = L0_4.SetTeleportCallback
      L1_4 = L0_3
      L0_4(L1_4)
      L0_4 = WifPmcInterior
      L0_4 = L0_4.Enter
      L1_4 = true
      L0_4(L1_4)
    end
    
    function L2_3()
      local L0_4, L1_4, L2_4, L3_4
      L0_4 = _PlayMovie
      L1_4 = {}
      L2_4 = "08_RME_"
      L3_4 = L0_2
      L2_4 = L2_4 .. L3_4
      L1_4.sMovie = L2_4
      L2_4 = L1_3
      L1_4.fCallback = L2_4
      L1_4.bSubtitles = true
      L0_4(L1_4)
      L0_4 = MrxAchievements
      L0_4 = L0_4.NetGrantAchievement
      L1_4 = "ACHIEVEMENT_OIL_AND_GAZ"
      L0_4(L1_4)
    end
    
    L3_3 = MrxCheatBootstrap
    L3_3 = L3_3.IsSkipModeEnabled
    L3_3 = L3_3()
    if not L3_3 then
      L3_3 = MrxState
      L3_3 = L3_3.Enter
      L4_3 = MrxState
      L4_3 = L4_3.STATE_WAITFORGAME
      L5_3 = L2_3
      L3_3(L4_3, L5_3)
    else
      L3_3 = L2_3
      L3_3()
    end
  end
  
  L2_2.fConseq = L3_2
  L1_2.MecCon001 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "JetIntro"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = WifBios
    L0_3 = L0_3.AddDossierEntry
    L1_3 = "BioMisha"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.RemoveActiveHint
    L1_3 = "FionaHint32"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.RemoveActiveHint
    L1_3 = "FionaHint16"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.AddActiveHint
    L1_3 = "FionaHint17"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "JetCon001"
    L0_3(L1_3)
    L0_3 = WifVzBoundary
    L0_3 = L0_3.SetupBoundaryPOST_EVA_POST_PIR
    L0_3()
    L0_3 = WifVzBoundary
    L0_3 = L0_3.SetInteriorMode
    L1_3 = true
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.JetIntro = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "JetCon001"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = _BeginBlockingSequence
    L0_3()
    
    function L0_3()
      local L0_4, L1_4, L2_4
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
    
    function L1_3()
      local L0_4, L1_4, L2_4
      L0_4 = _RemoveIntro
      L1_4 = "MecPmcBoss"
      L2_4 = "Jet"
      L0_4(L1_4, L2_4)
      L0_4 = WifHints
      L0_4 = L0_4.RemoveActiveHint
      L1_4 = "FionaHint29"
      L0_4(L1_4)
      L0_4 = WifHints
      L0_4 = L0_4.RemoveActiveHint
      L1_4 = "FionaHint17"
      L0_4(L1_4)
      L0_4 = WifHints
      L0_4 = L0_4.UnlockAllHints
      L1_4 = "Misha"
      L0_4(L1_4)
      L0_4 = MrxStarterManager
      L0_4 = L0_4.DestroyStarter
      L1_4 = "JetBoss"
      L0_4(L1_4)
      L0_4 = UnlockMission
      L1_4 = "PmcCon018"
      L0_4(L1_4)
      L0_4 = WifPmcInterior
      L0_4 = L0_4.SetTeleportCallback
      L1_4 = L0_3
      L0_4(L1_4)
      L0_4 = WifPmcInterior
      L0_4 = L0_4.Enter
      L1_4 = true
      L0_4(L1_4)
    end
    
    function L2_3()
      local L0_4, L1_4, L2_4, L3_4
      L0_4 = MrxLayerManager
      L0_4 = L0_4.MarkForRemoval
      L1_4 = {}
      L2_4 = "Vz_State_JetCon001_Pristine"
      L3_4 = "Vz_State_JetCon001_CP01"
      L1_4[1] = L2_4
      L1_4[2] = L3_4
      L0_4(L1_4)
      L0_4 = MrxLayerManager
      L0_4 = L0_4.MarkForAddition
      L1_4 = "vz_state_JetCon001_Post"
      L0_4(L1_4)
      L0_4 = _PlayMovie
      L1_4 = {}
      L2_4 = "09_RJE_"
      L3_4 = L0_2
      L2_4 = L2_4 .. L3_4
      L1_4.sMovie = L2_4
      L2_4 = L1_3
      L1_4.fCallback = L2_4
      L1_4.bSubtitles = true
      L0_4(L1_4)
      L0_4 = MrxAchievements
      L0_4 = L0_4.NetGrantAchievement
      L1_4 = "ACHIEVEMENT_ANALOG_KID"
      L0_4(L1_4)
    end
    
    L3_3 = MrxCheatBootstrap
    L3_3 = L3_3.IsSkipModeEnabled
    L3_3 = L3_3()
    if not L3_3 then
      L3_3 = MrxState
      L3_3 = L3_3.Enter
      L4_3 = MrxState
      L4_3 = L4_3.STATE_WAITFORGAME
      L5_3 = L2_3
      L3_3(L4_3, L5_3)
    else
      L3_3 = L2_3
      L3_3()
    end
  end
  
  L2_2.fConseq = L3_2
  L1_2.JetCon001 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "PmcJob001"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  L1_2.PmcJob001 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "OilCon002"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = MrxSoundBootstrap
    L0_3 = L0_3.SetPmcRadio
    L1_3 = "ReporterNeutral.MissionVO.Oil02"
    L0_3(L1_3)
    L0_3 = _BeginBlockingSequence
    L0_3()
    
    function L0_3()
      local L0_4, L1_4, L2_4, L3_4, L4_4
      L0_4 = WifHints
      L0_4 = L0_4.RemoveActiveHint
      L1_4 = "FionaHint21"
      L0_4(L1_4)
      L0_4 = WifHints
      L0_4 = L0_4.RemoveActiveHint
      L1_4 = "FionaHint22"
      L0_4(L1_4)
      L0_4 = WifHints
      L0_4 = L0_4.AddActiveHint
      L1_4 = "FionaHint20"
      L0_4(L1_4)
      L0_4 = WifHints
      L0_4 = L0_4.AddActiveHint
      L1_4 = "FionaHint19"
      L0_4(L1_4)
      L0_4 = WifHints
      L0_4 = L0_4.AddActiveHint
      L1_4 = "FionaHint18"
      L0_4(L1_4)
      L0_4 = WifHints
      L0_4 = L0_4.UnlockAllHints
      L1_4 = "Ewan"
      L0_4(L1_4)
      L0_4 = Munitions
      L0_4 = L0_4.SetMunitionsTaggable
      L1_4 = true
      L0_4(L1_4)
      L0_4 = MrxTransit
      L0_4 = L0_4.SetSystemEnabled
      L1_4 = true
      L0_4(L1_4)
      L0_4 = MrxTransit
      L0_4 = L0_4.SetLocationEnabled
      L1_4 = 1
      L2_4 = "Pmc"
      L3_4 = true
      L0_4(L1_4, L2_4, L3_4)
      L0_4 = MrxTransit
      L0_4 = L0_4.SetLocationEnabled
      L1_4 = 2
      L2_4 = "Oil"
      L3_4 = true
      L0_4(L1_4, L2_4, L3_4)
      L0_4 = MrxHqManager
      L0_4 = L0_4.GetHq
      L1_4 = "OilHq"
      L0_4 = L0_4(L1_4)
      L2_4 = L0_4
      L1_4 = L0_4.RefreshUiDisplay
      L1_4(L2_4)
      L1_4 = MrxUnlockFanfare
      L1_4 = L1_4.AddUnlockedItem
      L2_4 = {}
      L2_4.sType = "bounty"
      L2_4.sFactionId = "Oil"
      L1_4(L2_4)
      L1_4 = UnlockMission
      L2_4 = "OilCon050"
      L1_4(L2_4)
      L1_4 = UnlockMission
      L2_4 = "OilJob004"
      L1_4(L2_4)
      L1_4 = UnlockMission
      L2_4 = "OilJob008"
      L1_4(L2_4)
      L1_4 = UnlockMission
      L2_4 = "OilJob011"
      L1_4(L2_4)
      L1_4 = UnlockMission
      L2_4 = "PmcCon013"
      L1_4(L2_4)
      L1_4 = UnlockMission
      L2_4 = "PmcCon034"
      L1_4(L2_4)
      L1_4 = MrxLayerManager
      L1_4 = L1_4.MarkForRemoval
      L2_4 = "vz_state_gurcon005_airportdefbase_staging"
      L1_4(L2_4)
      L1_4 = MrxLayerManager
      L1_4 = L1_4.MarkForAddition
      L2_4 = {}
      L3_4 = "vz_state_gurcon005_airportdefbase"
      L4_4 = "vz_state_mar_city_act1_depot"
      L2_4[1] = L3_4
      L2_4[2] = L4_4
      L1_4(L2_4)
      L1_4 = WifVzBoundary
      L1_4 = L1_4.SetupBoundaryPOST_OIL
      L1_4()
      L1_4 = _AddIntro
      L2_4 = "PmcBoss"
      L3_4 = "Gur"
      L1_4(L2_4, L3_4)
      L1_4 = _AddIntro
      L2_4 = "HelPmcBoss"
      L3_4 = "Mec"
      L1_4(L2_4, L3_4)
      L1_4 = WifPmcInterior
      L1_4 = L1_4.Enter
      L2_4 = true
      L1_4(L2_4)
      L1_4 = MrxCheatBootstrap
      L1_4 = L1_4.IsSkipModeEnabled
      L1_4 = L1_4()
      if not L1_4 then
        L1_4 = MrxState
        L1_4 = L1_4.Exit
        L2_4 = MrxState
        L2_4 = L2_4.STATE_WAITFORGAME
        L3_4 = _EndBlockingSequence
        L1_4(L2_4, L3_4)
      else
        L1_4 = _EndBlockingSequence
        L1_4()
      end
    end
    
    function L1_3()
      local L0_4, L1_4, L2_4, L3_4
      L0_4 = MrxAchievements
      L0_4 = L0_4.NetGrantAchievement
      L1_4 = "ACHIEVEMENT_WILD_ONE"
      L0_4(L1_4)
      L0_4 = _PlayMovie
      L1_4 = {}
      L2_4 = "07_RHE_"
      L3_4 = L0_2
      L2_4 = L2_4 .. L3_4
      L1_4.sMovie = L2_4
      L2_4 = L0_3
      L1_4.fCallback = L2_4
      L1_4.bSubtitles = true
      L0_4(L1_4)
    end
    
    L2_3 = MrxCheatBootstrap
    L2_3 = L2_3.IsSkipModeEnabled
    L2_3 = L2_3()
    if not L2_3 then
      L2_3 = MrxState
      L2_3 = L2_3.Enter
      L3_3 = MrxState
      L3_3 = L3_3.STATE_WAITFORGAME
      L4_3 = L1_3
      L2_3(L3_3, L4_3)
    else
      L2_3 = L1_3
      L2_3()
    end
  end
  
  L2_2.fConseq = L3_2
  L1_2.OilCon002 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "GurIntro"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = WifBios
    L0_3 = L0_3.AddDossierEntry
    L1_3 = "BioAcosta"
    L0_3(L1_3)
    L0_3 = WifBios
    L0_3 = L0_3.AddDossierEntry
    L1_3 = "BioPLAV"
    L0_3(L1_3)
    L0_3 = MrxFactionManager
    L0_3 = L0_3.SetAttitudeMutable
    L1_3 = "Gur"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.RemoveActiveHint
    L1_3 = "FionaHint19"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.AddActiveHint
    L1_3 = "FionaHint09"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "GurCon053"
    L0_3(L1_3)
    L0_3 = HasKey
    L1_3 = "MecIntro"
    L0_3 = L0_3(L1_3)
    if not L0_3 then
      L0_3 = WifVzBoundary
      L0_3 = L0_3.SetupBoundaryPOST_EVA_PRE_PIR
      L0_3()
      L0_3 = WifVzBoundary
      L0_3 = L0_3.SetInteriorMode
      L1_3 = true
      L0_3(L1_3)
    end
  end
  
  L2_2.fConseq = L3_2
  L1_2.GurIntro = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "MecIntro"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = WifHints
    L0_3 = L0_3.RemoveActiveHint
    L1_3 = "FionaHint18"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "MecCon001"
    L0_3(L1_3)
    L0_3 = AwardKey
    L1_3 = "MonsterV4"
    L0_3(L1_3)
    L0_3 = HasKey
    L1_3 = "GurIntro"
    L0_3 = L0_3(L1_3)
    if not L0_3 then
      L0_3 = WifVzBoundary
      L0_3 = L0_3.SetupBoundaryPOST_EVA_PRE_PIR
      L0_3()
      L0_3 = WifVzBoundary
      L0_3 = L0_3.SetInteriorMode
      L1_3 = true
      L0_3(L1_3)
    end
  end
  
  L2_2.fConseq = L3_2
  L1_2.MecIntro = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "OilCon050"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = _BeginBlockingSequence
    L0_3()
    L0_3 = WifHints
    L0_3 = L0_3.RemoveActiveHint
    L1_3 = "FionaHint20"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.AddActiveHint
    L1_3 = "FionaHint23"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.AddActiveHint
    L1_3 = "FionaHint24"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "OilCon001"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "OilCon051"
    L0_3(L1_3)
    L0_3 = MrxLayerManager
    L0_3 = L0_3.MarkForRemoval
    L1_3 = "vz_state_mar_altagracia_act1"
    L0_3(L1_3)
    L0_3 = MrxLayerManager
    L0_3 = L0_3.MarkForAddition
    L1_3 = "vz_state_mar_altagracia_act2"
    L0_3(L1_3)
    L0_3 = _ChangeOutpostStaging
    L1_3 = _EndBlockingSequence
    L0_3(L1_3)
    L0_3 = HasKey
    L1_3 = "GurCon053"
    L0_3 = L0_3(L1_3)
    if not L0_3 then
      L0_3 = MrxCheatBootstrap
      L0_3 = L0_3.IsSkipModeEnabled
      L0_3 = L0_3()
      if not L0_3 then
        L0_3 = MrxVoSequence
        L0_3 = L0_3.Start
        L1_3 = {}
        L2_3 = "Fiona.Misc.Outposts24"
        L1_3[1] = L2_3
        L2_3 = nil
        L3_3 = MrxVoSequence
        L3_3 = L3_3.knPriorityFreeplay
        L0_3(L1_3, L2_3, L3_3)
      end
    end
  end
  
  L2_2.fConseq = L3_2
  L1_2.OilCon050 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "OilCon001"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = MrxSoundBootstrap
    L0_3 = L0_3.SetPmcRadio
    L1_3 = "ReporterNeutral.MissionVO.Oil01"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.RemoveActiveHint
    L1_3 = "FionaHint23"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.RemoveActiveHint
    L1_3 = "FionaHint24"
    L0_3(L1_3)
    L0_3 = MrxLayerManager
    L0_3 = L0_3.MarkForRemoval
    L1_3 = "vz_state_mar_industrial_act1"
    L0_3(L1_3)
    L0_3 = MrxLayerManager
    L0_3 = L0_3.MarkForAddition
    L1_3 = {}
    L2_3 = "vz_state_mar_industrial_act2"
    L3_3 = "vz_state_oilcon001_post"
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.OilCon001 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "OilCon001"
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L0_3 = HasKey
      L1_3 = "GurCon001"
      L0_3 = L0_3(L1_3)
    end
    return L0_3
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = WifHints
    L0_3 = L0_3.AddActiveHint
    L1_3 = "FionaHint10"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "PmcCon002"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.OilCon001_GurCon001 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "OilCon051"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = _BeginBlockingSequence
    L0_3()
    L0_3 = UnlockMission
    L1_3 = "OilCon003"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "OilCon052"
    L0_3(L1_3)
    L0_3 = MrxLayerManager
    L0_3 = L0_3.MarkForRemoval
    L1_3 = "vz_state_mar_outskirt_act1"
    L0_3(L1_3)
    L0_3 = MrxLayerManager
    L0_3 = L0_3.MarkForAddition
    L1_3 = "vz_state_mar_outskirt_act2"
    L0_3(L1_3)
    L0_3 = _ChangeOutpostStaging
    L1_3 = _EndBlockingSequence
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.OilCon051 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "OilCon052"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = _BeginBlockingSequence
    L0_3()
    L0_3 = HasKey
    L1_3 = "ChiCon002"
    L0_3 = L0_3(L1_3)
    if not L0_3 then
      L0_3 = UnlockMission
      L1_3 = "OilCon005"
      L0_3(L1_3)
    end
    L0_3 = _ChangeOutpostStaging
    L1_3 = _EndBlockingSequence
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.OilCon052 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "OilCon050"
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L0_3 = HasKey
      L1_3 = "OilCon051"
      L0_3 = L0_3(L1_3)
      if L0_3 then
        L0_3 = HasKey
        L1_3 = "OilCon052"
        L0_3 = L0_3(L1_3)
      end
    end
    return L0_3
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = MrxAchievements
    L0_3 = L0_3.NetGrantAchievement
    L1_3 = "ACHIEVEMENT_PIPELINE"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.OilOutposts = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "GurCon053"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = _BeginBlockingSequence
    L0_3()
    L0_3 = WifHints
    L0_3 = L0_3.RemoveActiveHint
    L1_3 = "FionaHint09"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.AddActiveHint
    L1_3 = "FionaHint14"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.AddActiveHint
    L1_3 = "FionaHint15"
    L0_3(L1_3)
    L0_3 = MrxUnlockFanfare
    L0_3 = L0_3.AddUnlockedItem
    L1_3 = {}
    L1_3.sType = "bounty"
    L1_3.sFactionId = "Gur"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "GurCon002"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "GurCon050"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "GurJob001"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "GurJob002"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "GurJob006"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "GurJob020"
    L0_3(L1_3)
    L0_3 = HasKey
    L1_3 = "OilCon050"
    L0_3 = L0_3(L1_3)
    if not L0_3 then
      L0_3 = MrxCheatBootstrap
      L0_3 = L0_3.IsSkipModeEnabled
      L0_3 = L0_3()
      if not L0_3 then
        L0_3 = MrxVoSequence
        L0_3 = L0_3.Start
        L1_3 = {}
        L2_3 = "Fiona.Misc.Outposts24"
        L1_3[1] = L2_3
        L2_3 = nil
        L3_3 = MrxVoSequence
        L3_3 = L3_3.knPriorityFreeplay
        L0_3(L1_3, L2_3, L3_3)
      end
    end
    L0_3 = _ChangeOutpostStaging
    L1_3 = _EndBlockingSequence
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.GurCon053 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "GurCon002"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = WifHints
    L0_3 = L0_3.RemoveActiveHint
    L1_3 = "FionaHint14"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.RemoveActiveHint
    L1_3 = "FionaHint15"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.AddActiveHint
    L1_3 = "FionaHint11"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.AddActiveHint
    L1_3 = "FionaHint12"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "GurCon003"
    L0_3(L1_3)
    L0_3 = MrxSoundBootstrap
    L0_3 = L0_3.SetPmcRadio
    L1_3 = "ReporterNeutral.MissionVO.Gur02"
    L0_3(L1_3)
    L0_3 = MrxLayerManager
    L0_3 = L0_3.MarkForRemoval
    L1_3 = {}
    L2_3 = "vz_state_merida_act1"
    L3_3 = "vz_state_merida_act1_helo"
    L4_3 = "vz_state_merida_act1_staging"
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L1_3[3] = L4_3
    L0_3(L1_3)
    L0_3 = MrxLayerManager
    L0_3 = L0_3.MarkForAddition
    L1_3 = {}
    L2_3 = "vz_state_merida_act2"
    L3_3 = "vz_state_merida_act2_helo"
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "Mendez"
    L0_3(L1_3)
    L0_3 = _RemoveIntro
    L1_3 = "PmcBoss"
    L2_3 = "Gur"
    L0_3(L1_3, L2_3)
    L0_3 = _AddIntro
    L1_3 = "PmcBoss"
    L2_3 = "Pir"
    L0_3(L1_3, L2_3)
    L0_3 = WifVzBoundary
    L0_3 = L0_3.SetupBoundaryPOST_EVA_POST_PIR
    L0_3()
  end
  
  L2_2.fConseq = L3_2
  L1_2.GurCon002 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "PirIntro"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = WifBios
    L0_3 = L0_3.AddDossierEntry
    L1_3 = "BioDevilbwoy"
    L0_3(L1_3)
    L0_3 = WifBios
    L0_3 = L0_3.AddDossierEntry
    L1_3 = "BioPirates"
    L0_3(L1_3)
    L0_3 = MrxFactionManager
    L0_3 = L0_3.SetAttitudeMutable
    L1_3 = "Pir"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "PirCon001"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.PirIntro = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "GurCon003"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = WifHints
    L0_3 = L0_3.RemoveActiveHint
    L1_3 = "FionaHint12"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.AddActiveHint
    L1_3 = "FionaHint13"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "GurCon001"
    L0_3(L1_3)
    L0_3 = MrxLayerManager
    L0_3 = L0_3.MarkForRemoval
    L1_3 = "vz_state_jungle_mountain_act1"
    L0_3(L1_3)
    L0_3 = MrxLayerManager
    L0_3 = L0_3.MarkForAddition
    L1_3 = "vz_state_jungle_mountain_act2"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.GurCon003 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "GurCon001"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = WifHints
    L0_3 = L0_3.RemoveActiveHint
    L1_3 = "FionaHint11"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.RemoveActiveHint
    L1_3 = "FionaHint13"
    L0_3(L1_3)
    L0_3 = MrxSoundBootstrap
    L0_3 = L0_3.SetPmcRadio
    L1_3 = "ReporterNeutral.MissionVO.Gur01"
    L0_3(L1_3)
    L0_3 = MrxLayerManager
    L0_3 = L0_3.MarkForRemoval
    L1_3 = {}
    L2_3 = "vz_state_gurcon001_fortress"
    L3_3 = "vz_state_gurcon001_staging"
    L4_3 = "Vz_State_GurCon001"
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L1_3[3] = L4_3
    L0_3(L1_3)
    L0_3 = MrxLayerManager
    L0_3 = L0_3.MarkForAddition
    L1_3 = "vz_state_gurcon001_fortress_destroyed"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.GurCon001 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "GurCon050"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = _BeginBlockingSequence
    L0_3()
    L0_3 = UnlockMission
    L1_3 = "GurCon005"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "GurCon052"
    L0_3(L1_3)
    L0_3 = _ChangeOutpostStaging
    L1_3 = _EndBlockingSequence
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.GurCon050 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "GurCon052"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = _BeginBlockingSequence
    L0_3()
    L0_3 = MrxStarterManager
    L0_3 = L0_3.RequestStarter
    L1_3 = "GurStarter4"
    L0_3(L1_3)
    L0_3 = _ChangeOutpostStaging
    L1_3 = _EndBlockingSequence
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.GurCon052 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "GurCon050"
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L0_3 = HasKey
      L1_3 = "GurCon052"
      L0_3 = L0_3(L1_3)
      if L0_3 then
        L0_3 = HasKey
        L1_3 = "GurCon053"
        L0_3 = L0_3(L1_3)
      end
    end
    return L0_3
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = MrxAchievements
    L0_3 = L0_3.NetGrantAchievement
    L1_3 = "ACHIEVEMENT_PIPELINE"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.GurOutposts = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "GurJob002"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "GurJob002_01_Target"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "GurJob002_02_Target"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "GurJob002_03_Target"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "GurJob002_04_Target"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "GurJob002_05_Target"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "GurJob012_01_Target"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "GurJob012_02_Target"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "GurJob012_03_Target"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "GurJob012_04_Target"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "GurJob012_05_Target"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.GurJob002 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "AllCon002"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = UnlockMission
    L1_3 = "AllCon001"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.AddActiveHint
    L1_3 = "FionaHint01"
    L0_3(L1_3)
    L0_3 = MrxSoundBootstrap
    L0_3 = L0_3.SetPmcRadio
    L1_3 = "ReporterNeutral.MissionVO.All02"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.AllCon002 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "AllCon001"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = UnlockMission
    L1_3 = "AllCon003"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.RemoveActiveHint
    L1_3 = "FionaHint03"
    L0_3(L1_3)
    L0_3 = MrxSoundBootstrap
    L0_3 = L0_3.SetPmcRadio
    L1_3 = "ReporterNeutral.MissionVO.All01"
    L0_3(L1_3)
    L0_3 = MrxLayerManager
    L0_3 = L0_3.MarkForRemoval
    L1_3 = {}
    L2_3 = "vz_state_car_city_act1"
    L3_3 = "vz_state_car_estate_act1"
    L4_3 = "vz_state_car_dock_act1"
    L5_3 = "vz_state_car_city_act2chi"
    L6_3 = "vz_state_car_city_act2chi_staging"
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L1_3[3] = L4_3
    L1_3[4] = L5_3
    L1_3[5] = L6_3
    L0_3(L1_3)
    L0_3 = MrxLayerManager
    L0_3 = L0_3.MarkForAddition
    L1_3 = {}
    L2_3 = "vz_state_car_city_act2all"
    L3_3 = "vz_state_car_city_act2all_staging"
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.AllCon001 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "AllCon003"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = _BeginBlockingSequence
    L0_3()
    
    function L0_3()
      local L0_4, L1_4, L2_4
      L0_4 = WifVzBoundary
      L0_4 = L0_4.EnableExclusionBoundary
      L1_4 = "Boundary_ALHQ_Exclusion"
      L2_4 = true
      L0_4(L1_4, L2_4)
      L0_4 = WifVzBoundary
      L0_4 = L0_4.DrawExclusionBoundaryOnMap
      L1_4 = "Boundary_ALHQ_Exclusion"
      L2_4 = true
      L0_4(L1_4, L2_4)
      L0_4 = MrxTransit
      L0_4 = L0_4.SetLocationIsNuked
      L1_4 = 7
      L2_4 = true
      L0_4(L1_4, L2_4)
      L0_4 = UnlockMission
      L1_4 = "PmcCon004"
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
    
    function L1_3()
      local L0_4, L1_4, L2_4, L3_4
      L0_4 = GetMissionStartLocations
      L1_4 = "PmcCon004"
      L0_4 = L0_4(L1_4)
      L1_4 = type
      L2_4 = L0_4
      L1_4 = L1_4(L2_4)
      if L1_4 == "table" then
        L1_4 = MrxUtil
        L1_4 = L1_4.TeleportHeroesToLocations
        L2_4 = L0_4
        L3_4 = L0_3
        L1_4(L2_4, L3_4)
      end
    end
    
    function L2_3()
      local L0_4, L1_4, L2_4, L3_4, L4_4, L5_4, L6_4, L7_4
      L0_4 = WifHints
      L0_4 = L0_4.RemoveActiveHint
      L1_4 = "FionaHint01"
      L0_4(L1_4)
      L0_4 = WifHints
      L0_4 = L0_4.RemoveActiveHint
      L1_4 = "FionaHint02"
      L0_4(L1_4)
      L0_4 = WifHints
      L0_4 = L0_4.RemoveActiveHint
      L1_4 = "FionaHint04"
      L0_4(L1_4)
      L0_4 = WifHints
      L0_4 = L0_4.RemoveActiveHint
      L1_4 = "FionaHint05"
      L0_4(L1_4)
      L0_4 = WifHints
      L0_4 = L0_4.RemoveActiveHint
      L1_4 = "FionaHint07"
      L0_4(L1_4)
      L0_4 = WifHints
      L0_4 = L0_4.RemoveActiveHint
      L1_4 = "FionaHint08"
      L0_4(L1_4)
      L0_4 = WifHints
      L0_4 = L0_4.AddActiveHint
      L1_4 = "FionaHint06"
      L0_4(L1_4)
      L0_4 = MrxVerifyManager
      L0_4 = L0_4.SetKilledIfNotSet
      L1_4 = "AllCon003_HVT"
      L0_4(L1_4)
      L0_4 = MrxLayerManager
      L0_4 = L0_4.MarkForRemoval
      L1_4 = {}
      L2_4 = "vz_state_car_city_act1"
      L3_4 = "vz_state_car_city_act2all"
      L4_4 = "vz_state_car_city_act2all_staging"
      L5_4 = "vz_state_car_city_act2chi_staging"
      L6_4 = "vz_state_car_city_act2chi"
      L7_4 = "vz_state_car_city_act3chi"
      L1_4[1] = L2_4
      L1_4[2] = L3_4
      L1_4[3] = L4_4
      L1_4[4] = L5_4
      L1_4[5] = L6_4
      L1_4[6] = L7_4
      L0_4(L1_4)
      L0_4 = MrxLayerManager
      L0_4 = L0_4.MarkForAddition
      L1_4 = {}
      L2_4 = "vz_state_PmcCon004_AlliesNuked"
      L3_4 = "vz_state_car_city_act3all"
      L1_4[1] = L2_4
      L1_4[2] = L3_4
      L0_4(L1_4)
      L0_4 = MrxLayerManager
      L0_4 = L0_4.ProcessMarkedLayers
      L0_4()
      L0_4 = _PlayMovie
      L1_4 = {}
      L2_4 = "13_AVI_"
      L3_4 = L0_2
      L2_4 = L2_4 .. L3_4
      L1_4.sMovie = L2_4
      L2_4 = L1_3
      L1_4.fCallback = L2_4
      L1_4.bSubtitles = true
      L0_4(L1_4)
      L0_4 = MrxAchievements
      L0_4 = L0_4.NetGrantAchievement
      L1_4 = "ACHIEVEMENT_NO_COMPROMISE"
      L0_4(L1_4)
    end
    
    L3_3 = MrxCheatBootstrap
    L3_3 = L3_3.IsSkipModeEnabled
    L3_3 = L3_3()
    if not L3_3 then
      L3_3 = MrxState
      L3_3 = L3_3.Enter
      L4_3 = MrxState
      L4_3 = L4_3.STATE_WAITFORGAME
      L5_3 = L2_3
      L3_3(L4_3, L5_3)
    else
      L3_3 = L2_3
      L3_3()
    end
  end
  
  L2_2.fConseq = L3_2
  L1_2.AllCon003 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "AllCon050"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = _BeginBlockingSequence
    L0_3()
    L0_3 = WifHints
    L0_3 = L0_3.RemoveActiveHint
    L1_3 = "FionaHint33"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.AddActiveHint
    L1_3 = "FionaHint03"
    L0_3(L1_3)
    L0_3 = HasKey
    L1_3 = "ChiCon050"
    L0_3 = L0_3(L1_3)
    if not L0_3 then
      L0_3 = WifHints
      L0_3 = L0_3.AddActiveHint
      L1_3 = "FionaHint04"
      L0_3(L1_3)
    end
    L0_3 = MrxUnlockFanfare
    L0_3 = L0_3.AddUnlockedItem
    L1_3 = {}
    L1_3.sType = "bounty"
    L1_3.sFactionId = "All"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "AllCon002"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "AllCon052"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "AllJob002"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "AllJob003"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "AllJob020"
    L0_3(L1_3)
    L0_3 = _ChangeOutpostStaging
    L1_3 = _EndBlockingSequence
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.AllCon050 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "AllCon052"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = _BeginBlockingSequence
    L0_3()
    L0_3 = HasKey
    L1_3 = "PmcCon004"
    L0_3 = L0_3(L1_3)
    if not L0_3 then
      L0_3 = UnlockMission
      L1_3 = "AllCon008"
      L0_3(L1_3)
    end
    L0_3 = UnlockMission
    L1_3 = "AllCon053"
    L0_3(L1_3)
    L0_3 = _ChangeOutpostStaging
    L1_3 = _EndBlockingSequence
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.AllCon052 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "AllCon053"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = _BeginBlockingSequence
    L0_3()
    L0_3 = MrxStarterManager
    L0_3 = L0_3.RequestStarter
    L1_3 = "AllStarter4"
    L0_3(L1_3)
    L0_3 = _ChangeOutpostStaging
    L1_3 = _EndBlockingSequence
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.AllCon053 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "AllCon050"
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L0_3 = HasKey
      L1_3 = "AllCon052"
      L0_3 = L0_3(L1_3)
      if L0_3 then
        L0_3 = HasKey
        L1_3 = "AllCon053"
        L0_3 = L0_3(L1_3)
      end
    end
    return L0_3
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = MrxAchievements
    L0_3 = L0_3.NetGrantAchievement
    L1_3 = "ACHIEVEMENT_PIPELINE"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.AllOutposts = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "AllJob002"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "AllJob002_01_Target"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "AllJob002_02_Target"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "AllJob002_03_Target"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "AllJob002_04_Target"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "AllJob002_05_Target"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "AllJob010_01_Target"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "AllJob010_02_Target"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "AllJob010_03_Target"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "AllJob010_04_Target"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "AllJob010_05_Target"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.AllJob002 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "AllCon050"
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L0_3 = HasKey
      L1_3 = "ChiCon050"
      L0_3 = L0_3(L1_3)
    end
    return L0_3
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = WifHints
    L0_3 = L0_3.RemoveActiveHint
    L1_3 = "FionaHint07"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.RemoveActiveHint
    L1_3 = "FionaHint04"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.AddActiveHint
    L1_3 = "FionaHint02"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.AllCon050_ChiCon050 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "AllCon001"
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L0_3 = HasKey
      L1_3 = "ChiCon001"
      L0_3 = L0_3(L1_3)
    end
    return L0_3
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3, L2_3
    L0_3 = _RemoveIntro
    L1_3 = "PmcBoss"
    L2_3 = "AllChi"
    L0_3(L1_3, L2_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.AllCon001_ChiCon001 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "ChiCon050"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = _BeginBlockingSequence
    L0_3()
    L0_3 = WifHints
    L0_3 = L0_3.RemoveActiveHint
    L1_3 = "FionaHint33"
    L0_3(L1_3)
    L0_3 = HasKey
    L1_3 = "AllCon050"
    L0_3 = L0_3(L1_3)
    if not L0_3 then
      L0_3 = WifHints
      L0_3 = L0_3.AddActiveHint
      L1_3 = "FionaHint07"
      L0_3(L1_3)
    end
    L0_3 = WifHints
    L0_3 = L0_3.AddActiveHint
    L1_3 = "FionaHint08"
    L0_3(L1_3)
    L0_3 = MrxUnlockFanfare
    L0_3 = L0_3.AddUnlockedItem
    L1_3 = {}
    L1_3.sType = "bounty"
    L1_3.sFactionId = "Chi"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "ChiCon001"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "ChiCon051"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "ChiJob002"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "ChiJob003"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "ChiJob020"
    L0_3(L1_3)
    L0_3 = _ChangeOutpostStaging
    L1_3 = _EndBlockingSequence
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.ChiCon050 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "ChiCon001"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = UnlockMission
    L1_3 = "ChiCon002"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.RemoveActiveHint
    L1_3 = "FionaHint08"
    L0_3(L1_3)
    L0_3 = WifHints
    L0_3 = L0_3.AddActiveHint
    L1_3 = "FionaHint05"
    L0_3(L1_3)
    L0_3 = MrxSoundBootstrap
    L0_3 = L0_3.SetPmcRadio
    L1_3 = "ReporterNeutral.MissionVO.Chi01"
    L0_3(L1_3)
    L0_3 = MrxLayerManager
    L0_3 = L0_3.MarkForRemoval
    L1_3 = {}
    L2_3 = "vz_state_cumana_act1ALL_N"
    L3_3 = "vz_state_cumana_act1ALL_S"
    L4_3 = "vz_state_cumana_act1ALL_staging"
    L5_3 = "vz_state_cumana_act1CHI"
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L1_3[3] = L4_3
    L1_3[4] = L5_3
    L0_3(L1_3)
    L0_3 = MrxLayerManager
    L0_3 = L0_3.MarkForAddition
    L1_3 = "vz_state_cumana_act2chi"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.ChiCon001 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "ChiCon002"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3
    L0_3 = DestroyMission
    L1_3 = "OilCon005"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "ChiCon003"
    L0_3(L1_3)
    L0_3 = MrxSoundBootstrap
    L0_3 = L0_3.SetPmcRadio
    L1_3 = "ReporterNeutral.MissionVO.Chi02"
    L0_3(L1_3)
    L0_3 = MrxLayerManager
    L0_3 = L0_3.MarkForRemoval
    L1_3 = {}
    L2_3 = "vz_state_mar_city_act2"
    L3_3 = "vz_state_staging_OilDepot"
    L4_3 = "vz_state_staging_OilHQ"
    L5_3 = "vz_state_car_city_act1"
    L6_3 = "vz_state_car_city_all"
    L7_3 = "vz_state_car_estate_act1"
    L8_3 = "vz_state_car_dock_act1"
    L9_3 = "vz_state_car_city_act2all"
    L10_3 = "vz_state_car_city_act2all_staging"
    L11_3 = "vz_state_chicon002_HQ_Pristine"
    L12_3 = "vz_state_chicon002_Depot_Pristine"
    L13_3 = "vz_state_chicon002_Bridge_Pristine"
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L1_3[3] = L4_3
    L1_3[4] = L5_3
    L1_3[5] = L6_3
    L1_3[6] = L7_3
    L1_3[7] = L8_3
    L1_3[8] = L9_3
    L1_3[9] = L10_3
    L1_3[10] = L11_3
    L1_3[11] = L12_3
    L1_3[12] = L13_3
    L0_3(L1_3)
    L0_3 = MrxLayerManager
    L0_3 = L0_3.MarkForAddition
    L1_3 = {}
    L2_3 = "vz_state_car_city_act2chi"
    L3_3 = "vz_state_car_city_act2chi_staging"
    L4_3 = "vz_state_mar_city_act3"
    L5_3 = "vz_state_chicon002_HQ_Destroyed"
    L6_3 = "vz_state_chicon002_Depot_Destroyed"
    L7_3 = "vz_state_chicon002_Bridge_Destroyed"
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L1_3[3] = L4_3
    L1_3[4] = L5_3
    L1_3[5] = L6_3
    L1_3[6] = L7_3
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.ChiCon002 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "ChiCon003"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = _BeginBlockingSequence
    L0_3()
    
    function L0_3()
      local L0_4, L1_4, L2_4
      L0_4 = WifVzBoundary
      L0_4 = L0_4.EnableExclusionBoundary
      L1_4 = "Boundary_CHHQ_Exclusion"
      L2_4 = true
      L0_4(L1_4, L2_4)
      L0_4 = WifVzBoundary
      L0_4 = L0_4.DrawExclusionBoundaryOnMap
      L1_4 = "Boundary_CHHQ_Exclusion"
      L2_4 = true
      L0_4(L1_4, L2_4)
      L0_4 = MrxTransit
      L0_4 = L0_4.SetLocationIsNuked
      L1_4 = 12
      L2_4 = true
      L0_4(L1_4, L2_4)
      L0_4 = MrxTransit
      L0_4 = L0_4.SetLocationIsNuked
      L1_4 = 30
      L2_4 = true
      L0_4(L1_4, L2_4)
      L0_4 = UnlockMission
      L1_4 = "PmcCon004"
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
    
    function L1_3()
      local L0_4, L1_4, L2_4, L3_4
      L0_4 = GetMissionStartLocations
      L1_4 = "PmcCon004"
      L0_4 = L0_4(L1_4)
      L1_4 = type
      L2_4 = L0_4
      L1_4 = L1_4(L2_4)
      if L1_4 == "table" then
        L1_4 = MrxUtil
        L1_4 = L1_4.TeleportHeroesToLocations
        L2_4 = L0_4
        L3_4 = L0_3
        L1_4(L2_4, L3_4)
      end
    end
    
    function L2_3()
      local L0_4, L1_4, L2_4, L3_4, L4_4, L5_4, L6_4, L7_4, L8_4
      L0_4 = WifHints
      L0_4 = L0_4.RemoveActiveHint
      L1_4 = "FionaHint01"
      L0_4(L1_4)
      L0_4 = WifHints
      L0_4 = L0_4.RemoveActiveHint
      L1_4 = "FionaHint02"
      L0_4(L1_4)
      L0_4 = WifHints
      L0_4 = L0_4.RemoveActiveHint
      L1_4 = "FionaHint03"
      L0_4(L1_4)
      L0_4 = WifHints
      L0_4 = L0_4.RemoveActiveHint
      L1_4 = "FionaHint04"
      L0_4(L1_4)
      L0_4 = WifHints
      L0_4 = L0_4.RemoveActiveHint
      L1_4 = "FionaHint05"
      L0_4(L1_4)
      L0_4 = WifHints
      L0_4 = L0_4.RemoveActiveHint
      L1_4 = "FionaHint07"
      L0_4(L1_4)
      L0_4 = WifHints
      L0_4 = L0_4.AddActiveHint
      L1_4 = "FionaHint06"
      L0_4(L1_4)
      L0_4 = MrxVerifyManager
      L0_4 = L0_4.SetKilledIfNotSet
      L1_4 = "ChiCon003_HVT"
      L0_4(L1_4)
      L0_4 = MrxLayerManager
      L0_4 = L0_4.MarkForRemoval
      L1_4 = {}
      L2_4 = "vz_state_cumana_act1"
      L3_4 = "vz_state_car_city_act1"
      L4_4 = "vz_state_car_city_act2chi"
      L5_4 = "vz_state_car_city_act2chi_staging"
      L6_4 = "vz_state_car_city_act2all_staging"
      L7_4 = "vz_state_car_city_act2all"
      L8_4 = "vz_state_car_city_act3all"
      L1_4[1] = L2_4
      L1_4[2] = L3_4
      L1_4[3] = L4_4
      L1_4[4] = L5_4
      L1_4[5] = L6_4
      L1_4[6] = L7_4
      L1_4[7] = L8_4
      L0_4(L1_4)
      L0_4 = MrxLayerManager
      L0_4 = L0_4.MarkForAddition
      L1_4 = {}
      L2_4 = "vz_state_PmcCon004_ChinaNuked"
      L3_4 = "vz_state_car_city_act3chi"
      L1_4[1] = L2_4
      L1_4[2] = L3_4
      L0_4(L1_4)
      L0_4 = MrxLayerManager
      L0_4 = L0_4.ProcessMarkedLayers
      L0_4()
      L0_4 = _PlayMovie
      L1_4 = {}
      L2_4 = "14_CVI_"
      L3_4 = L0_2
      L2_4 = L2_4 .. L3_4
      L1_4.sMovie = L2_4
      L2_4 = L1_3
      L1_4.fCallback = L2_4
      L1_4.bSubtitles = true
      L0_4(L1_4)
      L0_4 = MrxAchievements
      L0_4 = L0_4.NetGrantAchievement
      L1_4 = "ACHIEVEMENT_NO_COMPROMISE"
      L0_4(L1_4)
    end
    
    L3_3 = MrxCheatBootstrap
    L3_3 = L3_3.IsSkipModeEnabled
    L3_3 = L3_3()
    if not L3_3 then
      L3_3 = MrxState
      L3_3 = L3_3.Enter
      L4_3 = MrxState
      L4_3 = L4_3.STATE_WAITFORGAME
      L5_3 = L2_3
      L3_3(L4_3, L5_3)
    else
      L3_3 = L2_3
      L3_3()
    end
  end
  
  L2_2.fConseq = L3_2
  L1_2.ChiCon003 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "ChiCon051"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = _BeginBlockingSequence
    L0_3()
    L0_3 = HasKey
    L1_3 = "PmcCon004"
    L0_3 = L0_3(L1_3)
    if not L0_3 then
      L0_3 = UnlockMission
      L1_3 = "ChiCon008"
      L0_3(L1_3)
    end
    L0_3 = UnlockMission
    L1_3 = "ChiCon053"
    L0_3(L1_3)
    L0_3 = _ChangeOutpostStaging
    L1_3 = _EndBlockingSequence
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.ChiCon051 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "ChiCon053"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = _BeginBlockingSequence
    L0_3()
    L0_3 = UnlockMission
    L1_3 = "ChiCon009"
    L0_3(L1_3)
    L0_3 = _ChangeOutpostStaging
    L1_3 = _EndBlockingSequence
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.ChiCon053 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "ChiCon050"
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L0_3 = HasKey
      L1_3 = "ChiCon051"
      L0_3 = L0_3(L1_3)
      if L0_3 then
        L0_3 = HasKey
        L1_3 = "ChiCon053"
        L0_3 = L0_3(L1_3)
      end
    end
    return L0_3
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = MrxAchievements
    L0_3 = L0_3.NetGrantAchievement
    L1_3 = "ACHIEVEMENT_PIPELINE"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.ChiOutposts = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "ChiJob002"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "ChiJob002_Target_01"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "ChiJob002_Target_02"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "ChiJob002_Target_03"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "ChiJob002_Target_04"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "ChiJob002_Target_05"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "ChiJob010_Target_01"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "ChiJob010_Target_02"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "ChiJob010_Target_03"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "ChiJob010_Target_04"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "ChiJob010_Target_05"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.ChiJob002 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "PirCon001"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3, L2_3
    L0_3 = _RemoveIntro
    L1_3 = "PmcBoss"
    L2_3 = "Pir"
    L0_3(L1_3, L2_3)
    L0_3 = MrxUnlockFanfare
    L0_3 = L0_3.AddUnlockedItem
    L1_3 = {}
    L1_3.sType = "bounty"
    L1_3.sFactionId = "Pir"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "PirCon002"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "PirCon051"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "PirJob012"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "PirJob020"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.PirCon001 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "PirCon051"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = _BeginBlockingSequence
    L0_3()
    L0_3 = UnlockMission
    L1_3 = "PirCon003"
    L0_3(L1_3)
    L0_3 = UnlockMission
    L1_3 = "PirCon052"
    L0_3(L1_3)
    L0_3 = _ChangeOutpostStaging
    L1_3 = _EndBlockingSequence
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.PirCon051 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "PirCon052"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = _BeginBlockingSequence
    L0_3()
    L0_3 = UnlockMission
    L1_3 = "PirCon004"
    L0_3(L1_3)
    L0_3 = _ChangeOutpostStaging
    L1_3 = _EndBlockingSequence
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.PirCon052 = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "PirCon051"
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L0_3 = HasKey
      L1_3 = "PirCon052"
      L0_3 = L0_3(L1_3)
    end
    return L0_3
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = MrxAchievements
    L0_3 = L0_3.NetGrantAchievement
    L1_3 = "ACHIEVEMENT_PIPELINE"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.PrOutposts = L2_2
  L2_2 = {}
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = HasKey
    L1_3 = "PirJob012"
    return L0_3(L1_3)
  end
  
  L2_2.fPrereq = L3_2
  
  function L3_2()
    local L0_3, L1_3
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "PirJob012_Target_01"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "PirJob012_Target_02"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "PirJob012_Target_03"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "PirJob012_Target_04"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "PirJob012_Target_05"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "PirJob012_Target_06"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "PirJob012_Target_07"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "PirJob012_Target_08"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "PirJob012_Target_09"
    L0_3(L1_3)
    L0_3 = MrxVerifyManager
    L0_3 = L0_3.SetKilledIfNotSet
    L1_3 = "PirJob012_Target_10"
    L0_3(L1_3)
  end
  
  L2_2.fConseq = L3_2
  L1_2.PirJob012 = L2_2
  return L1_2
end

GetOriginalFlowData = L0_1

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
  L2_2 = MrxStarterManager
  L2_2 = L2_2.GetStarter
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L4_2 = L2_2
    L3_2 = L2_2.AddIntro
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
    L3_2 = MrxCheatBootstrap
    L3_2 = L3_2.IsSkipModeEnabled
    L3_2 = L3_2()
    if L3_2 then
      L4_2 = L2_2
      L3_2 = L2_2.SetViewedIntro
      L5_2 = A1_2
      L6_2 = true
      L3_2(L4_2, L5_2, L6_2)
    end
  end
end

_AddIntro = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = MrxStarterManager
  L2_2 = L2_2.GetStarter
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L4_2 = L2_2
    L3_2 = L2_2.RemoveIntro
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
  end
end

_RemoveIntro = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = MrxCheatBootstrap
  L1_2 = L1_2.IsSkipModeEnabled
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = MrxUtil
    L1_2 = L1_2.CallWithOptionalArgs
    L2_2 = A0_2.fCallback
    L3_2 = A0_2.tCallbackData
    L1_2(L2_2, L3_2)
  else
    L1_2 = Hud
    L1_2 = L1_2.Cinematic
    L2_2 = L1_2
    L1_2 = L1_2.Show
    L3_2 = {}
    L4_2 = A0_2.sMovie
    L3_2.sMovie = L4_2
    L4_2 = A0_2.fCallback
    L3_2.fCallback = L4_2
    L4_2 = A0_2.tCallbackData
    L3_2.tCallbackData = L4_2
    L4_2 = A0_2.bSubtitles
    L3_2.bSubtitles = L4_2
    L1_2(L2_2, L3_2)
  end
end

_PlayMovie = L0_1

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

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = WifPmcInterior
  L0_2 = L0_2.GetAvailableCostumes
  L0_2 = L0_2()
  if not L0_2 then
    L0_2 = 1
  end
  L1_2 = WifPmcInterior
  L1_2 = L1_2.SetAvailableCostumes
  L2_2 = L0_2 + 1
  L1_2 = L1_2(L2_2)
  L2_2 = #L1_2
  if 1 <= L2_2 then
    L2_2 = ipairs
    L3_2 = L1_2
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2, L6_2 in L2_2, L3_2, L4_2 do
      L7_2 = MrxUnlockFanfare
      L7_2 = L7_2.AddUnlockedItem
      L8_2 = {}
      L8_2.sType = "outfit"
      L8_2.sName = L6_2
      L7_2(L8_2)
    end
  end
end

_AddHeroCostume = L0_1
L0_1 = 0
NETEVENT_CLIENTCREDITS = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = NETEVENT_CLIENTCREDITS
  if A0_2 == L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Create
    L2_2 = Event
    L2_2 = L2_2.GameStateChange
    L3_2 = {}
    L4_2 = "cinematic"
    L5_2 = "exit"
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L4_2 = _ClientStartCredits
    L1_2(L2_2, L3_2, L4_2)
  end
end

NetEventCallback = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = MrxGui
  L0_2 = L0_2.FadeToColor
  L1_2 = 0
  L0_2(L1_2)
  L0_2 = Sys
  L0_2 = L0_2.RequestGameState
  L1_2 = "cinematic"
  L0_2(L1_2)
  L0_2 = MrxGui
  L0_2 = L0_2.FlashWidget
  L1_2 = L0_2
  L0_2 = L0_2.new
  L0_2 = L0_2(L1_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetFullscreen
  L3_2 = true
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetSwfFile
  L3_2 = "credits"
  L4_2 = _ClientEndCredits
  L5_2 = {}
  L6_2 = L0_2
  L5_2[1] = L6_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = MrxGui
  L1_2 = L1_2.AddWidget
  L2_2 = L0_2
  L1_2(L2_2)
end

_ClientStartCredits = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2
  L1_2 = A0_2.SetFlashEventHandler
  L3_2 = "creditsEnd"
  L4_2 = _ClientQuitToShell
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

_ClientEndCredits = L0_1

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
