local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = import
L1_1 = "DangerousBuilding"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxLayerManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxState"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxMusic"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifPmcInterior"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportTransit"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifVzBoundary"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = {}
  L3_2 = "vz_State_Pmc_LivedIn"
  L4_2 = "vz_state_merida_act2_helo"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = {}
  L4_2 = "vz_state_pmccon003_solbunkerbase"
  L5_2 = "vz_state_pmccon003"
  L6_2 = "vz_state_sol_bunker"
  L7_2 = "vz_state_sol_base_pristine"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L5_2 = A0_2
  L4_2 = A0_2._GetFlag
  L6_2 = "BunkerBusterDeployed"
  L4_2 = L4_2(L5_2, L6_2)
  if L4_2 then
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L2_2
    L6_2 = "vz_state_pmccon003_bunkerdefenses"
    L4_2(L5_2, L6_2)
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L2_2
    L6_2 = "vz_state_pmccon003_BunkerAA"
    L4_2(L5_2, L6_2)
  else
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L3_2
    L6_2 = "vz_state_pmccon003_bunkerdefenses"
    L4_2(L5_2, L6_2)
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L3_2
    L6_2 = "vz_state_pmccon003_BunkerAA"
    L4_2(L5_2, L6_2)
  end
  L5_2 = A0_2
  L4_2 = A0_2._GetFlag
  L6_2 = "PMCRaceComplete"
  L4_2 = L4_2(L5_2, L6_2)
  if L4_2 then
    L5_2 = A0_2
    L4_2 = A0_2._GetFlag
    L6_2 = "PMCDefenseComplete"
    L4_2 = L4_2(L5_2, L6_2)
    if not L4_2 then
      L4_2 = table
      L4_2 = L4_2.insert
      L5_2 = L3_2
      L6_2 = "vz_state_pmccon003_pmcattack"
      L4_2(L5_2, L6_2)
  end
  else
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L2_2
    L6_2 = "vz_state_pmccon003_pmcattack"
    L4_2(L5_2, L6_2)
  end
  L5_2 = A0_2
  L4_2 = A0_2._GetFlag
  L6_2 = "PMCDefenseComplete"
  L4_2 = L4_2(L5_2, L6_2)
  if L4_2 then
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L3_2
    L6_2 = "vz_state_pmccon003_getcarmona"
    L4_2(L5_2, L6_2)
  else
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L2_2
    L6_2 = "vz_state_pmccon003_getcarmona"
    L4_2(L5_2, L6_2)
  end
  L4_2 = MrxLayerManager
  L4_2 = L4_2.Add
  L5_2 = L3_2
  
  function L6_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = MrxLayerManager
    L0_3 = L0_3.Remove
    L1_3 = L2_2
    L2_3 = A0_2
    L2_3 = L2_3.AssetsLoaded
    L3_3 = {}
    L4_3 = A0_2
    L3_3[1] = L4_3
    L0_3(L1_3, L2_3, L3_3)
  end
  
  L4_2(L5_2, L6_2)
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "_Pmcoutpost_bld_hq_livedin_pmccon003 0x000fe1ff"
  L1_2 = L1_2(L2_2)
  uPMCguid = L1_2
  L1_2 = nil
  oGetCarmona = L1_2
  L1_2 = nil
  uCarmona = L1_2
  L1_2 = nil
  uCarmonaJeep = L1_2
  L1_2 = nil
  uCarmonaHeli = L1_2
  L1_2 = {}
  L2_2 = "PTH_Carmona_Flee_01"
  L3_2 = "PTH_Carmona_Flee_02"
  L4_2 = "PTH_Carmona_Flee_03"
  L5_2 = "PTH_Carmona_Flee_04"
  L6_2 = "PTH_Carmona_Flee_05"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  tEscapePaths = L1_2
  L1_2 = WifVzBoundary
  L1_2 = L1_2.SetupBoundaryPMCCON003
  L1_2()
  L1_2 = Object
  L1_2 = L1_2.SetInvincible
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "Solano_Bunker"
  L2_2 = L2_2(L3_2)
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = MrxSupportManager
  L1_2 = L1_2.IsRecruitAvailable
  L2_2 = "Copter"
  L1_2(L2_2)
  L1_2 = MrxSupportManager
  L1_2 = L1_2.StartRecruitCooldown
  L2_2 = "Copter"
  L3_2 = -1
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "PMCDefenseComplete"
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.GetCarmona
    L3_2 = A0_2
    L1_2(L2_2, L3_2)
  else
    L2_2 = A0_2
    L1_2 = A0_2._GetFlag
    L3_2 = "PMCRaceComplete"
    L1_2 = L1_2(L2_2, L3_2)
    if L1_2 then
      L2_2 = A0_2
      L1_2 = A0_2.ClearPMCGrounds
      L3_2 = A0_2
      L1_2(L2_2, L3_2)
    else
      L2_2 = A0_2
      L1_2 = A0_2._GetFlag
      L3_2 = "BunkerBusterDeployed"
      L1_2 = L1_2(L2_2, L3_2)
      if L1_2 then
        L1_2 = Object
        L1_2 = L1_2.Remove
        L2_2 = Pg
        L2_2 = L2_2.GetGuidByName
        L3_2 = "PMC003_EwanTaxi"
        L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L2_2(L3_2)
        L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
        L2_2 = A0_2
        L1_2 = A0_2.BunkerBuster
        L3_2 = A0_2
        L1_2(L2_2, L3_2)
      else
        L2_2 = A0_2
        L1_2 = A0_2._GetFlag
        L3_2 = "BoardedLuckyLady"
        L1_2 = L1_2(L2_2, L3_2)
        if L1_2 then
          L1_2 = Object
          L1_2 = L1_2.Remove
          L2_2 = Pg
          L2_2 = L2_2.GetGuidByName
          L3_2 = "PMC003_EwanTaxi"
          L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L2_2(L3_2)
          L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
          L2_2 = A0_2
          L1_2 = A0_2.BunkerBuster
          L3_2 = A0_2
          L1_2(L2_2, L3_2)
        else
          L1_2 = Pg
          L1_2 = L1_2.GetGuidByName
          L2_2 = "PMC003_EwanTaxi"
          L1_2 = L1_2(L2_2)
          L2_2 = Vehicle
          L2_2 = L2_2.GetDriver
          L3_2 = L1_2
          L2_2 = L2_2(L3_2)
          L3_2 = Ai
          L3_2 = L3_2.Goal
          L4_2 = {}
          L4_2.AIGuid = L2_2
          L4_2.Goal = "Idle"
          L4_2.Priority = "hiPri"
          L4_2.MaintainRotorSpeed = true
          L3_2 = L3_2(L4_2)
          A0_2.uIdleGoal = L3_2
          L4_2 = A0_2
          L3_2 = A0_2.CreateChild
          L5_2 = {}
          L5_2.sName = "Action"
          L5_2.sModuleName = "MrxTaskObjectiveEnterVehicle"
          L5_2.vTgtInclude = L1_2
          L6_2 = Player
          L6_2 = L6_2.GetAllCharacters
          L6_2 = L6_2()
          L5_2.uPlayer = L6_2
          L5_2.sActionLabel = "[PmcCon003.Objectives.001]"
          L5_2.sDspShortDesc = "[PmcCon003.Objectives.001]"
          L5_2.bUseAnySeat = true
          L6_2 = {}
          L7_2 = {}
          L8_2 = TransitTeleport
          L9_2 = {}
          L10_2 = A0_2
          L11_2 = L1_2
          L9_2[1] = L10_2
          L9_2[2] = L11_2
          L7_2[1] = L8_2
          L7_2[2] = L9_2
          L6_2[1] = L7_2
          L5_2.tOnComplete = L6_2
          L6_2 = {}
          L7_2 = {}
          L8_2 = A0_2.Cancel
          L9_2 = {}
          L10_2 = A0_2
          L9_2[1] = L10_2
          L7_2[1] = L8_2
          L7_2[2] = L9_2
          L6_2[1] = L7_2
          L5_2.tOnCancel = L6_2
          L6_2 = {}
          L7_2 = {}
          L8_2 = "Ewan-In-Mission-Contract-Pmc03-127"
          L9_2 = L2_2
          L7_2[1] = L8_2
          L7_2[2] = L9_2
          L8_2 = {}
          L9_2 = "Ewan-In-Mission-Contract-Pmc03-124"
          L10_2 = L2_2
          L8_2[1] = L9_2
          L8_2[2] = L10_2
          L9_2 = {}
          L10_2 = "Ewan-In-Mission-Contract-Pmc03-125"
          L11_2 = L2_2
          L9_2[1] = L10_2
          L9_2[2] = L11_2
          L6_2[1] = L7_2
          L6_2[2] = L8_2
          L6_2[3] = L9_2
          L5_2.vVoSeqOnAdd = L6_2
          L3_2(L4_2, L5_2)
        end
      end
    end
  end
end

Activated = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = Vehicle
  L2_2 = L2_2.GetFromRider
  L3_2 = Player
  L3_2 = L3_2.GetPrimaryCharacter
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L3_2()
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  if L2_2 ~= A1_2 then
    L2_2 = Vehicle
    L2_2 = L2_2.Enter
    L3_2 = A1_2
    L4_2 = Player
    L4_2 = L4_2.GetPrimaryCharacter
    L4_2 = L4_2()
    L5_2 = "p"
    L6_2 = true
    L7_2 = false
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  end
  L2_2 = MrxSupportTransit
  L3_2 = L2_2
  L2_2 = L2_2.TransitToPoint
  L4_2 = A1_2
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "loc_ChopperDropoff_P1"
  L5_2, L6_2, L7_2, L8_2, L9_2 = L5_2(L6_2)
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectInSeat
  L5_2 = {}
  L6_2 = "Hero"
  L7_2 = A1_2
  L8_2 = "a"
  L9_2 = "x"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L6_2 = BunkerBuster
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

TransitTeleport = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2
  L1_2 = A0_2.IsActive
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    return
  end
  L1_2 = MrxSupportManager
  L1_2 = L1_2.GetRecruitTimes
  L2_2 = "copter"
  L1_2, L2_2 = L1_2(L2_2)
  L4_2 = A0_2
  L3_2 = A0_2._SetFlag
  L5_2 = "BoardedLuckyLady"
  L3_2(L4_2, L5_2)
  L4_2 = A0_2
  L3_2 = A0_2._GetFlag
  L5_2 = "BunkerBusterDeployed"
  L3_2 = L3_2(L4_2, L5_2)
  if L3_2 then
    L3_2 = _Checkpoint
    L4_2 = {}
    L5_2 = "loc_HindCheckpoint_P1"
    L6_2 = "loc_HindCheckpoint_P2"
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L3_2(L4_2)
  else
    L3_2 = _Checkpoint
    L4_2 = {}
    L5_2 = "loc_ChopperDropoff_P1"
    L6_2 = "loc_ChopperDropoff_P2"
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L3_2(L4_2)
  end
  L4_2 = A0_2
  L3_2 = A0_2.CreateChild
  L5_2 = {}
  L5_2.sName = "Deploy Bunker Buster on Solano's Bunker."
  L5_2.sModuleName = "MrxTaskObjectiveDestroy"
  L6_2 = {}
  L7_2 = "Solano_Bunker"
  L6_2[1] = L7_2
  L5_2.vTgtInclude = L6_2
  L5_2.sDspShortDesc = "[PmcCon003.Objectives.002]"
  L6_2 = {}
  L7_2 = {}
  L8_2 = A0_2.VODeployedBB
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L6_2[1] = L7_2
  L5_2.tOnComplete = L6_2
  L6_2 = {}
  L7_2 = {}
  L8_2 = A0_2.Cancel
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L6_2[1] = L7_2
  L5_2.tOnCancel = L6_2
  L6_2 = {}
  L7_2 = "Fiona-In-Mission-Contract-Pmc03-01"
  L8_2 = "Fiona-In-Mission-Contract-Pmc03-02"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2.vVoSeqOnAdd = L6_2
  L3_2 = L3_2(L4_2, L5_2)
  oBustBunker = L3_2
  L4_2 = A0_2
  L3_2 = A0_2._CreatePersistentEvent
  L5_2 = Event
  L5_2 = L5_2.ScriptEvent
  L6_2 = {}
  L7_2 = "Busted"
  
  function L8_2()
    local L0_3, L1_3
    L0_3 = true
    return L0_3
  end
  
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = BBDeployed
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  L3_2 = MrxSupportData
  L3_2 = L3_2.AddFreebie
  L4_2 = "Bunker Buster"
  L5_2 = 1
  L6_2 = Player
  L6_2 = L6_2.GetPrimaryPlayer
  L6_2, L7_2, L8_2, L9_2, L10_2 = L6_2()
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  L3_2 = BunkerApproachRegionActivate
  L4_2 = A0_2
  L3_2(L4_2)
  L3_2 = BunkerTankAmbushRegionActive
  L4_2 = A0_2
  L3_2(L4_2)
  L3_2 = AngelFallsBridgeRegionActivate
  L4_2 = A0_2
  L3_2(L4_2)
end

BunkerBuster = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L1_2 = MrxSupportManager
  L1_2 = L1_2.GetRecruitTimes
  L2_2 = "copter"
  L1_2, L2_2 = L1_2(L2_2)
  L3_2 = MrxSupportManager
  L3_2 = L3_2.StartRecruitCooldown
  L4_2 = "Copter"
  L5_2 = -1
  L3_2(L4_2, L5_2)
  L4_2 = A0_2
  L3_2 = A0_2._SetFlag
  L5_2 = "BunkerBusterDeployed"
  L3_2(L4_2, L5_2)
  L3_2 = _Checkpoint
  L4_2 = {}
  L5_2 = "loc_HindCheckpoint_P1"
  L6_2 = "loc_HindCheckpoint_P2"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L3_2(L4_2)
  L3_2 = MrxVoSequence
  L3_2 = L3_2.Start
  L4_2 = {}
  L5_2 = {}
  L5_2.mattias = "Mattias-In-Mission-Contract-Pmc03-03"
  L5_2.jennifer = "Jennifer-In-Mission-Contract-Pmc03-04"
  L5_2.chris = "Chris-In-Mission-Contract-Pmc03-123"
  L6_2 = "Fiona-In-Mission-Contract-Pmc03-134"
  L7_2 = {}
  L7_2.mattias = "Mattias-In-Mission-Contract-Pmc03-82"
  L7_2.jennifer = "Jennifer-In-Mission-Contract-Pmc03-83"
  L7_2.chris = "Chris-In-Mission-Contract-Pmc03-84"
  L8_2 = "Fiona-In-Mission-Contract-Pmc03-54"
  L9_2 = {}
  L9_2.mattias = "Mattias-In-Mission-Contract-Pmc03-85"
  L9_2.jennifer = "Jennifer-In-Mission-Contract-Pmc03-86"
  L9_2.chris = "Chris-In-Mission-Contract-Pmc03-87"
  L10_2 = "Fiona-In-Mission-Contract-Pmc03-23"
  L11_2 = {}
  L11_2.mattias = "Mattias-In-Mission-Contract-Pmc03-24"
  L11_2.jennifer = "Jennifer-In-Mission-Contract-Pmc03-25"
  L11_2.chris = "Chris-In-Mission-Contract-Pmc03-26"
  L12_2 = "Fiona-In-Mission-Contract-Pmc03-56"
  L13_2 = {}
  L13_2.mattias = "Mattias-In-Mission-Contract-Pmc03-88"
  L13_2.jennifer = "Jennifer-In-Mission-Contract-Pmc03-89"
  L13_2.chris = "Chris-In-Mission-Contract-Pmc03-90"
  L14_2 = "Fiona-In-Mission-Contract-Pmc03-50"
  L15_2 = {}
  L15_2.mattias = "Mattias-In-Mission-Contract-Pmc03-91"
  L15_2.jennifer = "Jennifer-In-Mission-Contract-Pmc03-92"
  L15_2.chris = "Chris-In-Mission-Contract-Pmc03-93"
  L16_2 = {}
  L17_2 = A0_2.PMCRace
  L18_2 = {}
  L19_2 = A0_2
  L18_2[1] = L19_2
  L16_2[1] = L17_2
  L16_2[2] = L18_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L4_2[7] = L11_2
  L4_2[8] = L12_2
  L4_2[9] = L13_2
  L4_2[10] = L14_2
  L4_2[11] = L15_2
  L4_2[12] = L16_2
  L3_2(L4_2)
end

VODeployedBB = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = MrxPmc
  L2_2 = L2_2.GetSupportQty
  L3_2 = "bunkerbuster"
  L2_2 = L2_2(L3_2)
  L3_2 = MrxPmc
  L3_2 = L3_2.GetFreebieQty
  L4_2 = "[support.airstrike.bunkerbuster.name]"
  L3_2 = L3_2(L4_2)
  if not L2_2 then
    L2_2 = 0
  end
  if not L3_2 then
    L3_2 = 0
  end
  L4_2 = MrxUtil
  L4_2 = L4_2.GetDistanceToObject
  L5_2 = "Solano_Bunker"
  L6_2 = A1_2[1]
  L7_2 = A1_2[2]
  L8_2 = A1_2[3]
  L9_2 = true
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  if L4_2 < 100 then
    L4_2 = oBustBunker
    L5_2 = L4_2
    L4_2 = L4_2.Complete
    L4_2(L5_2)
  elseif L3_2 < 1 and L2_2 < 1 then
    L4_2 = MrxVoSequence
    L4_2 = L4_2.Start
    L5_2 = {}
    L6_2 = "Fiona-In-Mission-Contract-Pmc03-132"
    L7_2 = 3
    L8_2 = {}
    L9_2 = A0_2.FailedToBust
    L10_2 = {}
    L11_2 = A0_2
    L10_2[1] = L11_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L4_2(L5_2)
  end
end

BBDeployed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[PmcCon003.Terms.Cancel01]"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.Cancel
  L1_2(L2_2)
end

FailedToBust = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Race back to the base in time!"
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L3_2.vDestRegion = "Region_PMC003_MansionApproach"
  L4_2 = Player
  L4_2 = L4_2.GetAnyCharacter
  L4_2 = L4_2()
  L3_2.vTgtInclude = L4_2
  L3_2.bDspBlp = true
  L3_2.nTimeLimit = 600
  L3_2.sDspShortDesc = "[PmcCon003.Objectives.003]"
  L3_2.bStop = false
  L3_2.bXZOnly = false
  L4_2 = {}
  L5_2 = "Fiona-In-Mission-Contract-Pmc03-59"
  L4_2[1] = L5_2
  L3_2.vVoSeqOnAdd = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.LoadPMCAttack01
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = {}
  L7_2 = Pg
  L7_2 = L7_2.StopHeliWaveSpawner
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L3_2.tOnComplete = L4_2
  
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = Object
    L0_3 = L0_3.GetHealth
    L1_3 = Player
    L1_3 = L1_3.GetLocalCharacter
    L1_3, L2_3, L3_3, L4_3, L5_3 = L1_3()
    L0_3 = L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
    nHealth = L0_3
    L0_3 = nHealth
    if 0 < L0_3 then
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._SetCancelMessage
      L2_3 = "[PmcCon003.Terms.Cancel02]"
      L0_3(L1_3, L2_3)
      L0_3 = {}
      L1_3 = "Fiona-In-Mission-Contract-PMC03-148"
      L2_3 = {}
      L3_3 = A0_2
      L3_3 = L3_3.Cancel
      L4_3 = {}
      L5_3 = A0_2
      L4_3[1] = L5_3
      L2_3[1] = L3_3
      L2_3[2] = L4_3
      L0_3[1] = L1_3
      L0_3[2] = L2_3
      L1_3 = MrxVoSequence
      L1_3 = L1_3.Start
      L2_3 = L0_3
      L1_3(L2_3)
    end
  end
  
  L3_2.fOnCancel = L4_2
  L1_2(L2_2, L3_2)
  L1_2 = StartHeliPursuit
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = MrxMusic
  L1_2 = L1_2.PlaySpecialMusic
  L2_2 = "mu_pmc_panicloop_01"
  L1_2(L2_2)
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "LOC_PMC"
  L1_2 = L1_2(L2_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAnyCharacter
  L6_2 = L6_2()
  L7_2 = L1_2
  L8_2 = "<"
  L9_2 = 5000
  L10_2 = false
  L11_2 = true
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = MrxVoSequence
  L6_2 = L6_2.Start
  L7_2 = {}
  L8_2 = {}
  L9_2 = "Fiona-In-Mission-Contract-PMC03-141"
  L8_2[1] = L9_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAnyCharacter
  L6_2 = L6_2()
  L7_2 = L1_2
  L8_2 = "<"
  L9_2 = 3750
  L10_2 = false
  L11_2 = true
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = MrxVoSequence
  L6_2 = L6_2.Start
  L7_2 = {}
  L8_2 = {}
  L9_2 = "Fiona-In-Mission-Contract-PMC03-143"
  L8_2[1] = L9_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAnyCharacter
  L6_2 = L6_2()
  L7_2 = L1_2
  L8_2 = "<"
  L9_2 = 2500
  L10_2 = false
  L11_2 = true
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = MrxVoSequence
  L6_2 = L6_2.Start
  L7_2 = {}
  L8_2 = {}
  L9_2 = "Fiona-In-Mission-Contract-PMC03-142"
  L8_2[1] = L9_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAnyCharacter
  L6_2 = L6_2()
  L7_2 = L1_2
  L8_2 = "<"
  L9_2 = 1250
  L10_2 = false
  L11_2 = true
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = MrxVoSequence
  L6_2 = L6_2.Start
  L7_2 = {}
  L8_2 = {}
  L9_2 = "Fiona-In-Mission-Contract-PMC03-147"
  L8_2[1] = L9_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

PMCRace = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Add
  L2_2 = {}
  L3_2 = "vz_state_pmccon003_pmcattack"
  L2_2[1] = L3_2
  L3_2 = ClearPMCGrounds
  L4_2 = {}
  L5_2 = A0_2
  L4_2[1] = L5_2
  L1_2(L2_2, L3_2, L4_2)
end

LoadPMCAttack01 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._SetFlag
  L3_2 = "PMCRaceComplete"
  L1_2(L2_2, L3_2)
  L1_2 = _Checkpoint
  L2_2 = {}
  L3_2 = "loc_DefendPMCCheckpoint_P1"
  L4_2 = "loc_DefendPMCCheckpoint_P2"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
  L1_2 = Object
  L1_2 = L1_2.Remove
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "PMC003_EwanTaxi"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L2_2(L3_2)
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  L1_2 = WifPmcInterior
  L1_2 = L1_2.SetEntranceLock
  L2_2 = true
  L1_2(L2_2)
  L1_2 = WifPmcInterior
  L1_2 = L1_2.RefreshUiDisplay
  L1_2()
  L1_2 = {}
  L2_2 = "Fiona-In-Mission-Contract-Pmc03-149"
  L3_2 = "Fiona-In-Mission-Contract-Pmc03-150"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  tInitialVOTable = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._PMCHealthBar
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Clear out the VZ forces attacking the PMC!"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = {}
  L5_2 = "PMC003_AMX_01"
  L6_2 = "PMC003_AMX_02"
  L7_2 = "PMC003_AMX_03"
  L8_2 = "PMC003_AMX_04"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L3_2.vTgtInclude = L4_2
  L3_2.bDspBlp = true
  L3_2.sDspShortDesc = "[PmcCon003.Objectives.004]"
  
  function L4_2()
    local L0_3, L1_3, L2_3
    L0_3 = Object
    L0_3 = L0_3.IsAlive
    L1_3 = Pg
    L1_3 = L1_3.GetGuidByName
    L2_3 = "OBJ_Wave02_Tank01"
    L1_3, L2_3 = L1_3(L2_3)
    L0_3 = L0_3(L1_3, L2_3)
    if not L0_3 then
      L0_3 = Object
      L0_3 = L0_3.IsAlive
      L1_3 = Pg
      L1_3 = L1_3.GetGuidByName
      L2_3 = "OBJ_Wave02_Tank02"
      L1_3, L2_3 = L1_3(L2_3)
      L0_3 = L0_3(L1_3, L2_3)
      if not L0_3 then
        L0_3 = Object
        L0_3 = L0_3.IsAlive
        L1_3 = Pg
        L1_3 = L1_3.GetGuidByName
        L2_3 = "OBJ_Wave02_Tank03"
        L1_3, L2_3 = L1_3(L2_3)
        L0_3 = L0_3(L1_3, L2_3)
        if not L0_3 then
          L0_3 = Object
          L0_3 = L0_3.IsAlive
          L1_3 = Pg
          L1_3 = L1_3.GetGuidByName
          L2_3 = "OBJ_Wave02_Tank04"
          L1_3, L2_3 = L1_3(L2_3)
          L0_3 = L0_3(L1_3, L2_3)
          if not L0_3 then
            goto lbl_41
          end
        end
      end
    end
    L0_3 = ClearPMCGrounds_Wave2
    L1_3 = A0_2
    L0_3(L1_3)
    goto lbl_48
    ::lbl_41::
    L0_3 = EnterPMC
    L1_3 = A0_2
    L0_3(L1_3)
    L0_3 = MrxUtil
    L0_3 = L0_3.StopHealthBar
    L1_3 = uPMCguid
    L0_3(L1_3)
    ::lbl_48::
  end
  
  L3_2.fOnComplete = L4_2
  
  function L4_2()
    local L0_3, L1_3, L2_3
    L0_3 = MrxUtil
    L0_3 = L0_3.StopHealthBar
    L1_3 = uPMCguid
    L0_3(L1_3)
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._SetCancelMessage
    L2_3 = "[PmcCon003.Terms.Cancel03]"
    L0_3(L1_3, L2_3)
    L0_3 = A0_2
    L0_3 = L0_3.Cancel
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L3_2.fOnCancel = L4_2
  L4_2 = tInitialVOTable
  L3_2.vVoSeqOnAdd = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  oDestroyAttackers = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectHealthLessThan
  L4_2 = {}
  L5_2 = uPMCguid
  L6_2 = 1
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  
  function L5_2()
    local L0_3, L1_3
    L0_3 = oDestroyAttackers
    L0_3 = L0_3.Cancel
    L1_3 = oDestroyAttackers
    L0_3(L1_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "PMC003_AMX_01"
  L1_2 = L1_2(L2_2)
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "PMC003_AMX_02"
  L2_2 = L2_2(L3_2)
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "PMC003_AMX_03"
  L3_2 = L3_2(L4_2)
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "PMC003_AMX_04"
  L4_2 = L4_2(L5_2)
  L5_2 = TankAttackPMC
  L6_2 = A0_2
  L7_2 = L1_2
  L5_2(L6_2, L7_2)
  L5_2 = TankAttackPMC
  L6_2 = A0_2
  L7_2 = L2_2
  L5_2(L6_2, L7_2)
  L5_2 = TankAttackPMC
  L6_2 = A0_2
  L7_2 = L3_2
  L5_2(L6_2, L7_2)
  L5_2 = TankAttackPMC
  L6_2 = A0_2
  L7_2 = L4_2
  L5_2(L6_2, L7_2)
end

ClearPMCGrounds = L0_1

function L0_1(A0_2)
  local L1_2
end

LoadPMCAttack02 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = {}
  L2_2 = "Fiona-In-Mission-Contract-Pmc03-151"
  L1_2[1] = L2_2
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "Clear out the VZ forces attacking the PMC!"
  L4_2.sModuleName = "MrxTaskObjectiveDestroy"
  L5_2 = {}
  L6_2 = "OBJ_Wave02_Tank01"
  L7_2 = "OBJ_Wave02_Tank02"
  L8_2 = "OBJ_Wave02_Tank03"
  L9_2 = "OBJ_Wave02_Tank04"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L4_2.vTgtInclude = L5_2
  L4_2.bDspBlp = true
  L4_2.sDspShortDesc = "[PmcCon003.Objectives.004]"
  L5_2 = {}
  L6_2 = {}
  L7_2 = A0_2.EnterPMC
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = {}
  L8_2 = MrxUtil
  L8_2 = L8_2.StopHealthBar
  L9_2 = {}
  L10_2 = uPMCguid
  L9_2[1] = L10_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2.tOnComplete = L5_2
  L4_2.vVoSeqOnAdd = L1_2
  L2_2 = L2_2(L3_2, L4_2)
  oDestroyAttackersWave2 = L2_2
  L2_2 = Object
  L2_2 = L2_2.IsAlive
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "OBJ_Wave02_Tank03"
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  if L2_2 then
    L2_2 = TankBustPMCWall
    L3_2 = A0_2
    L4_2 = "OBJ_Wave02_Tank03"
    L5_2 = "_pmcoutpost_walla 0x000a3e1c"
    L6_2 = "Path_EastArmor01"
    L2_2(L3_2, L4_2, L5_2, L6_2)
  end
  L2_2 = Object
  L2_2 = L2_2.IsAlive
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "OBJ_Wave02_APC02"
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  if L2_2 then
    L2_2 = TankBustPMCWall
    L3_2 = A0_2
    L4_2 = "OBJ_Wave02_APC02"
    L5_2 = "_pmcoutpost_walla 0x000a3e1d"
    L6_2 = "Path_EastArmor02"
    L2_2(L3_2, L4_2, L5_2, L6_2)
  end
  L2_2 = Object
  L2_2 = L2_2.IsAlive
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "OBJ_Wave02_Tank04"
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  if L2_2 then
    L2_2 = TankBustPMCWall
    L3_2 = A0_2
    L4_2 = "OBJ_Wave02_Tank04"
    L5_2 = "_pmcoutpost_walla 0x000a3e1e"
    L6_2 = "Path_EastArmor03"
    L2_2(L3_2, L4_2, L5_2, L6_2)
  end
  L2_2 = Object
  L2_2 = L2_2.IsAlive
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "OBJ_Wave02_Tank02"
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  if L2_2 then
    L2_2 = TankBustPMCWall
    L3_2 = A0_2
    L4_2 = "OBJ_Wave02_Tank02"
    L5_2 = "_pmcoutpost_walla 0x000a3dea"
    L6_2 = "PTH_West_Attack_01"
    L2_2(L3_2, L4_2, L5_2, L6_2)
  end
  L2_2 = Object
  L2_2 = L2_2.IsAlive
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "OBJ_Wave02_APC01"
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  if L2_2 then
    L2_2 = TankBustPMCWall
    L3_2 = A0_2
    L4_2 = "OBJ_Wave02_APC01"
    L5_2 = "_pmcoutpost_wallb 0x000a3de8"
    L6_2 = "PTH_West_Attack_02"
    L2_2(L3_2, L4_2, L5_2, L6_2)
  end
  L2_2 = Object
  L2_2 = L2_2.IsAlive
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "OBJ_Wave02_Tank01"
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  if L2_2 then
    L2_2 = TankBustPMCWall
    L3_2 = A0_2
    L4_2 = "OBJ_Wave02_Tank01"
    L5_2 = "_pmcoutpost_walla 0x000a3deb"
    L6_2 = "PTH_West_Attack_03"
    L2_2(L3_2, L4_2, L5_2, L6_2)
  end
end

ClearPMCGrounds_Wave2 = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = Ai
  L2_2 = L2_2.RemoveGoal
  L3_2 = {}
  L3_2.AIGuid = A1_2
  L3_2.Handle = 0
  L2_2(L3_2)
  L2_2 = {}
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L2_2.AIGuid = L3_2
  L2_2.Goal = "Attack"
  L3_2 = uPMCguid
  L2_2.Target = L3_2
  L2_2.Priority = "MedPri"
  L2_2.Force = true
  tAttackGoalParams = L2_2
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectHibernation
  L5_2 = {}
  L6_2 = A1_2
  L7_2 = "awake"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = Ai
  L6_2 = L6_2.Goal
  L7_2 = {}
  L8_2 = tAttackGoalParams
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

TankAttackPMC = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = A2_2
  L4_2 = L4_2(L5_2)
  L5_2 = Object
  L5_2 = L5_2.GetPosition
  L6_2 = L4_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L8_2 = Pg
  L8_2 = L8_2.Spawn
  L9_2 = "Explosion (Rocket Artillery)"
  L10_2 = L5_2
  L11_2 = L6_2
  L12_2 = L7_2
  L13_2 = 0
  L14_2 = false
  L15_2 = true
  L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  L8_2 = Pg
  L8_2 = L8_2.GetGuidByName
  L9_2 = A1_2
  L8_2 = L8_2(L9_2)
  L9_2 = Ai
  L9_2 = L9_2.RemoveGoal
  L10_2 = {}
  L10_2.AIGuid = L8_2
  L10_2.Handle = 0
  L9_2(L10_2)
  L9_2 = Ai
  L9_2 = L9_2.Goal
  L10_2 = {}
  L11_2 = Vehicle
  L11_2 = L11_2.GetDriver
  L12_2 = L8_2
  L11_2 = L11_2(L12_2)
  L10_2.AIGuid = L11_2
  L10_2.Goal = "PathMove"
  L11_2 = Pg
  L11_2 = L11_2.GetGuidByName
  L12_2 = A3_2
  L11_2 = L11_2(L12_2)
  L10_2.Target = L11_2
  L10_2.Priority = "HiPri"
  L10_2.Haste = 1
  L10_2.Force = true
  L11_2 = TankAttackPMC
  L10_2.Callback = L11_2
  L11_2 = {}
  L12_2 = A0_2
  L13_2 = L8_2
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L10_2.CallbackData = L11_2
  L9_2(L10_2)
end

TankBustPMCWall = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = GetGuidByName
  L7_2 = "Region_PMC003_PMC"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = MrxUtil
    L0_3 = L0_3.DisplayHealthBar
    L1_3 = A0_2
    L2_3 = uPMCguid
    L3_3 = 0
    L4_3 = true
    L5_3 = 0
    L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._CreateEvent
    L2_3 = Event
    L2_3 = L2_3.Boundary
    L3_3 = {}
    L4_3 = Player
    L4_3 = L4_3.GetAnyCharacter
    L4_3 = L4_3()
    L5_3 = GetGuidByName
    L6_3 = "Region_PMC003_MansionApproach"
    L5_3 = L5_3(L6_3)
    L6_3 = "exit"
    L3_3[1] = L4_3
    L3_3[2] = L5_3
    L3_3[3] = L6_3
    
    function L4_3()
      local L0_4, L1_4
      L0_4 = MrxUtil
      L0_4 = L0_4.StopHealthBar
      L1_4 = uPMCguid
      L0_4(L1_4)
      L0_4 = _PMCHealthBar
      L1_4 = A0_2
      L0_4(L1_4)
    end
    
    L0_3(L1_3, L2_3, L3_3, L4_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

_PMCHealthBar = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Get inside the PMC!"
  L3_2.sModuleName = "MrxTaskObjectiveAction"
  L3_2.sActionLabel = "[ContextAction.Enter]"
  L3_2.sDspShortDesc = "[PmcCon003.Objectives.006]"
  L3_2.vTgtInclude = "PlayerLocation_PMC"
  L3_2.bDspBlp = true
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.CinematicCarmonaPMC
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.Cancel
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnCancel = L4_2
  L4_2 = {}
  L5_2 = "Fiona-In-Mission-Contract-Pmc03-152"
  L4_2[1] = L5_2
  L3_2.vVoSeqOnAdd = L4_2
  L1_2(L2_2, L3_2)
end

EnterPMC = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  
  function L1_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = MrxState
    L0_3 = L0_3.Exit
    L1_3 = MrxState
    L1_3 = L1_3.STATE_WAITFORGAME
    L2_3 = A0_2
    L2_3 = L2_3.SpawnCarmona
    L3_3 = {}
    L4_3 = A0_2
    L3_3[1] = L4_3
    L0_3(L1_3, L2_3, L3_3)
  end
  
  function L2_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = MrxUtil
    L0_3 = L0_3.GetCharacterIdentity
    L1_3 = Player
    L1_3 = L1_3.GetPrimaryCharacter
    L1_3, L2_3, L3_3, L4_3, L5_3 = L1_3()
    L0_3 = L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
    if L0_3 then
      L1_3 = string
      L1_3 = L1_3.upper
      L2_3 = string
      L2_3 = L2_3.sub
      L3_3 = L0_3
      L4_3 = 1
      L5_3 = 1
      L2_3, L3_3, L4_3, L5_3 = L2_3(L3_3, L4_3, L5_3)
      L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3)
      L0_3 = L1_3
    end
    if L0_3 ~= "M" and L0_3 ~= "J" and L0_3 ~= "C" then
      L0_3 = "M"
    end
    L1_3 = Hud
    L1_3 = L1_3.Cinematic
    L2_3 = L1_3
    L1_3 = L1_3.Show
    L3_3 = {}
    L4_3 = "12_CAR_"
    L5_3 = L0_3
    L4_3 = L4_3 .. L5_3
    L3_3.sMovie = L4_3
    L4_3 = L1_2
    L3_3.fCallback = L4_3
    L3_3.bSubtitles = true
    L1_3(L2_3, L3_3)
  end
  
  L3_2 = MrxLayerManager
  L3_2 = L3_2.Remove
  L4_2 = "vz_state_pmccon003_pmcattack"
  L3_2(L4_2)
  L3_2 = MrxState
  L3_2 = L3_2.Enter
  L4_2 = MrxState
  L4_2 = L4_2.STATE_WAITFORGAME
  L5_2 = L2_2
  L3_2(L4_2, L5_2)
end

CinematicCarmonaPMC = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Add
  L2_2 = {}
  L3_2 = "vz_state_pmccon003_getcarmona"
  L2_2[1] = L3_2
  L3_2 = GetCarmona
  L4_2 = {}
  L5_2 = A0_2
  L4_2[1] = L5_2
  L1_2(L2_2, L3_2, L4_2)
end

SpawnCarmona = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2
  L1_2 = A0_2._SetFlag
  L3_2 = "PMCDefenseComplete"
  L1_2(L2_2, L3_2)
  L1_2 = _Checkpoint
  L2_2 = {}
  L3_2 = "loc_CheckPointGetCarmona_P1"
  L4_2 = "loc_CheckPointGetCarmona_P2"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
  L1_2 = Object
  L1_2 = L1_2.Remove
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "PMC003_EwanTaxi"
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = MrxSupportManager
  L1_2 = L1_2.MakeRecruitAvailable
  L2_2 = "Copter"
  L1_2(L2_2)
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "CarmonaTarget"
  L1_2 = L1_2(L2_2)
  uCarmona = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "CarmonaJeep"
  L1_2 = L1_2(L2_2)
  uCarmonaJeep = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "CarmonaHeli"
  L1_2 = L1_2(L2_2)
  uCarmonaHeli = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Verify Carmona"
  L3_2.sModuleName = "MrxTaskObjectiveVerify"
  L4_2 = {}
  L5_2 = "CarmonaTarget"
  L4_2[1] = L5_2
  L3_2.vTgtInclude = L4_2
  L3_2.bDspBlp = true
  L3_2.sDspShortDesc = "[PmcCon003.Objectives.005]"
  
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = {}
    L1_3 = "Fiona-In-Mission-Contract-Pmc03-64"
    L2_3 = {}
    L3_3 = A0_2
    L3_3 = L3_3.Complete
    L4_3 = {}
    L5_3 = A0_2
    L4_3[1] = L5_3
    L2_3[1] = L3_3
    L2_3[2] = L4_3
    L0_3[1] = L1_3
    L0_3[2] = L2_3
    L1_3 = MrxVoSequence
    L1_3 = L1_3.Start
    L2_3 = L0_3
    L1_3(L2_3)
  end
  
  L3_2.fOnComplete = L4_2
  
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = {}
    L1_3 = "Fiona-In-Mission-Contract-Pmc03-158"
    L2_3 = {}
    L3_3 = A0_2
    L3_3 = L3_3.Cancel
    L4_3 = {}
    L5_3 = A0_2
    L4_3[1] = L5_3
    L2_3[1] = L3_3
    L2_3[2] = L4_3
    L0_3[1] = L1_3
    L0_3[2] = L2_3
    L1_3 = MrxVoSequence
    L1_3 = L1_3.Start
    L2_3 = L0_3
    L1_3(L2_3)
  end
  
  L3_2.fOnCancel = L4_2
  L4_2 = {}
  L5_2 = "Fiona-In-Mission-Contract-Pmc03-154"
  L4_2[1] = L5_2
  L3_2.vVoSeqOnAdd = L4_2
  L3_2.sFactionId = "Oil"
  L1_2 = L1_2(L2_2, L3_2)
  oGetCarmona = L1_2
  L1_2 = MountUpCarmona
  L2_2 = A0_2
  L1_2(L2_2)
end

GetCarmona = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Ai
  L1_2 = L1_2.SetState
  L2_2 = {}
  L3_2 = uCarmona
  L2_2.AIGuid = L3_2
  L2_2.State = "Vip"
  L2_2.Value = true
  L1_2(L2_2)
  L1_2 = {}
  L2_2 = uCarmona
  L1_2.AIGuid = L2_2
  L1_2.Goal = "Enter"
  L2_2 = uCarmonaJeep
  L1_2.Target = L2_2
  L1_2.Role = "driver"
  L1_2.Haste = 1.5
  L1_2.Force = true
  L1_2.Priority = "hiPri"
  L2_2 = DriveCarmonaToHeli
  L1_2.Callback = L2_2
  L2_2 = {}
  L3_2 = A0_2
  L4_2 = 0
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2.CallbackData = L2_2
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 1
  L5_2[1] = L6_2
  
  function L6_2()
    local L0_3, L1_3
    L0_3 = Ai
    L0_3 = L0_3.Goal
    L1_3 = L1_2
    L0_3 = L0_3(L1_3)
  end
  
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectInSeat
  L5_2 = {}
  L6_2 = uCarmona
  L7_2 = uCarmonaJeep
  L8_2 = "D"
  L9_2 = "E"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  
  function L6_2()
    local L0_3, L1_3
    L0_3 = StartPursuit
    L1_3 = A0_2
    L0_3(L1_3)
    L0_3 = HeliWaitForCarmona
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L2_2(L3_2, L4_2, L5_2, L6_2)
end

MountUpCarmona = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L4_2 = tEscapePaths
  L4_2 = #L4_2
  if A3_2 == 1 then
    if A1_2 == 0 then
    end
    A1_2 = A1_2 + 1
    L5_2 = eventHandle
    if L5_2 then
      L5_2 = Event
      L5_2 = L5_2.Delete
      L6_2 = eventHandle
      L5_2(L6_2)
      L5_2 = nil
      eventHandle = L5_2
    else
    end
  end
  if L4_2 < A1_2 then
    L5_2 = SwitchCarmonaToHeli
    L5_2()
    L5_2 = eventHandle
    if L5_2 then
      L5_2 = Event
      L5_2 = L5_2.Delete
      L6_2 = eventHandle
      L5_2(L6_2)
      L5_2 = nil
      eventHandle = L5_2
    end
  else
    L5_2 = Pg
    L5_2 = L5_2.GetGuidByName
    L6_2 = tEscapePaths
    L6_2 = L6_2[A1_2]
    L5_2 = L5_2(L6_2)
    L6_2 = math
    L6_2 = L6_2.randf
    L7_2 = 0.5
    L8_2 = 0.7
    L6_2 = L6_2(L7_2, L8_2)
    L7_2 = {}
    L8_2 = Vehicle
    L8_2 = L8_2.GetDriver
    L9_2 = uCarmonaJeep
    L8_2 = L8_2(L9_2)
    L7_2.AIGuid = L8_2
    L7_2.Goal = "PathMove"
    L7_2.Target = L5_2
    L7_2.Priority = "HiPri"
    L7_2.Force = true
    L7_2.Haste = L6_2
    L7_2.Timeout = 0
    L7_2.Start = "Nearest"
    L8_2 = DriveCarmonaToHeli
    L7_2.Callback = L8_2
    L8_2 = {}
    L9_2 = A0_2
    L10_2 = A1_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L7_2.CallbackData = L8_2
    L8_2 = Ai
    L8_2 = L8_2.Goal
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    L10_2 = A0_2
    L9_2 = A0_2._CreateEvent
    L11_2 = Event
    L11_2 = L11_2.TimerRelative
    L12_2 = {}
    L13_2 = 15
    L12_2[1] = L13_2
    L13_2 = DriveCarmonaTimeOut
    L14_2 = {}
    L15_2 = A0_2
    L16_2 = A1_2
    L17_2 = Vehicle
    L17_2 = L17_2.GetDriver
    L18_2 = uCarmonaJeep
    L17_2, L18_2 = L17_2(L18_2)
    L14_2[1] = L15_2
    L14_2[2] = L16_2
    L14_2[3] = L17_2
    L14_2[4] = L18_2
    L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
    eventHandle = L9_2
  end
end

DriveCarmonaToHeli = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = eventHandle
  if L3_2 then
    L3_2 = Event
    L3_2 = L3_2.Delete
    L4_2 = eventHandle
    L3_2(L4_2)
    L3_2 = nil
    eventHandle = L3_2
  end
  L3_2 = DriveCarmonaToHeli
  L4_2 = A0_2
  L5_2 = A1_2
  L6_2 = A2_2
  L7_2 = 0
  L3_2(L4_2, L5_2, L6_2, L7_2)
end

DriveCarmonaTimeOut = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Ai
  L1_2 = L1_2.Goal
  L2_2 = {}
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = uCarmonaJeep
  L3_2 = L3_2(L4_2)
  L2_2.AIGuid = L3_2
  L2_2.Goal = "PathMove"
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "Path_PMC003_CarmonaFlee"
  L3_2 = L3_2(L4_2)
  L2_2.Target = L3_2
  L2_2.Priority = "HiPri"
  L2_2.Force = true
  L2_2.Haste = 0.75
  L2_2.Timeout = 0
  L3_2 = SwitchCarmonaToHeli
  L2_2.Callback = L3_2
  L3_2 = {}
  L2_2.CallbackData = L3_2
  L1_2(L2_2)
  L1_2 = StartPursuit
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = HeliWaitForCarmona
  L2_2 = A0_2
  L1_2(L2_2)
end

DriveCarmonaDrive = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2
  if A3_2 == 1 then
    L4_2 = {}
    L4_2.AIGuid = A0_2
    L4_2.Goal = "Enter"
    L4_2.Target = A1_2
    L4_2.Role = "driver"
    L4_2.Force = true
    L4_2.Priority = "hiPri"
    L5_2 = Ai
    L5_2 = L5_2.Goal
    L6_2 = L4_2
    L5_2(L6_2)
  else
    L4_2 = Ai
    L4_2 = L4_2.Goal
    L5_2 = {}
    L5_2.AIGuid = A0_2
    L5_2.Goal = "Exit"
    L5_2.Priority = "hiPri"
    L6_2 = ExitAttempted
    L5_2.Callback = L6_2
    L4_2(L5_2)
  end
end

ExitAttempted = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  if A3_2 == 1 then
    L4_2 = Ai
    L4_2 = L4_2.RemoveGoal
    L5_2 = {}
    L5_2.AIGuid = A0_2
    L5_2.Handle = 0
    L4_2(L5_2)
    L4_2 = Ai
    L4_2 = L4_2.Goal
    L5_2 = {}
    L5_2.AIGuid = A0_2
    L5_2.Goal = "Exit"
    L5_2.Priority = "hiPri"
    L6_2 = ExitAttempted
    L5_2.Callback = L6_2
    L6_2 = {}
    L7_2 = A0_2
    L8_2 = A1_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L5_2.CallbackData = L6_2
    L4_2(L5_2)
  else
    L4_2 = Ai
    L4_2 = L4_2.Goal
    L5_2 = {}
    L5_2.AIGuid = A0_2
    L5_2.Goal = "Stop"
    L5_2.Priority = "hiPri"
    L6_2 = CarmonaStoppedAtDestn
    L5_2.Callback = L6_2
    L6_2 = {}
    L7_2 = A0_2
    L8_2 = A1_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L5_2.CallbackData = L6_2
    L4_2(L5_2)
  end
end

CarmonaStoppedAtDestn = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = StopPursuit
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Ai
  L1_2 = L1_2.RemoveGoal
  L2_2 = {}
  L3_2 = uCarmona
  L2_2.AIGuid = L3_2
  L2_2.Handle = 0
  L1_2(L2_2)
  L1_2 = Ai
  L1_2 = L1_2.Goal
  L2_2 = {}
  L3_2 = uCarmona
  L2_2.AIGuid = L3_2
  L2_2.Goal = "Stop"
  L2_2.Priority = "hiPri"
  L3_2 = CarmonaStoppedAtDestn
  L2_2.Callback = L3_2
  L3_2 = {}
  L4_2 = uCarmona
  L5_2 = uCarmonaHeli
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L2_2.CallbackData = L3_2
  L1_2(L2_2)
end

SwitchCarmonaToHeli = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectInSeat
  L4_2 = {}
  L5_2 = uCarmona
  L6_2 = uCarmonaHeli
  L7_2 = "D"
  L8_2 = "E"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = CarmonaHeliEscape
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

HeliWaitForCarmona = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Ai
  L1_2 = L1_2.RemoveGoal
  L2_2 = {}
  L3_2 = uCarmona
  L2_2.AIGuid = L3_2
  L2_2.Handle = 0
  L1_2(L2_2)
  L1_2 = MrxSupport
  L1_2 = L1_2.GoHome
  L2_2 = A0_2
  L3_2 = uCarmonaHeli
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = uCarmonaHeli
  L6_2 = "hibernated"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = oGetCarmona
  L5_2 = L5_2.Cancel
  L6_2 = {}
  L7_2 = oGetCarmona
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

CarmonaHeliEscape = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Region_PmcCon003_Bunker_ApproachEnc01"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = Bunker_Approach_Attack01
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

BunkerApproachRegionActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "Chopper_PmcCon003_Bunker_ApproachEnc01"
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L2_2 = Ai
    L2_2 = L2_2.Goal
    L3_2 = {}
    L4_2 = Vehicle
    L4_2 = L4_2.GetDriver
    L5_2 = L1_2
    L4_2 = L4_2(L5_2)
    L3_2.AIGuid = L4_2
    L3_2.Goal = "PathMove"
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "Path_PmcCon003_Bunker_ApproachEnc01"
    L4_2 = L4_2(L5_2)
    L3_2.Target = L4_2
    L3_2.Priority = "LowPri"
    L3_2.Haste = 0.5
    L2_2(L3_2)
  else
  end
end

Bunker_Approach_Attack01 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Region_Pmc003_Bunker_TankAmbush01"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = BunkerTankAmbush01
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

BunkerTankAmbushRegionActive = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "Scorpion_TankAmbush01"
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L2_2 = Ai
    L2_2 = L2_2.Goal
    L3_2 = {}
    L4_2 = Vehicle
    L4_2 = L4_2.GetDriver
    L5_2 = L1_2
    L4_2 = L4_2(L5_2)
    L3_2.AIGuid = L4_2
    L3_2.Goal = "PathMove"
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "Path_Pmc003_Bunker_TankAmbush01"
    L4_2 = L4_2(L5_2)
    L3_2.Target = L4_2
    L3_2.Priority = "MedPri"
    L3_2.Haste = 1
    L2_2(L3_2)
  else
  end
end

BunkerTankAmbush01 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "region_pmccon003_angelfallsbridge"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = AngelFallsBridgeAmbush
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  uEvent = L1_2
end

AngelFallsBridgeRegionActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "PmcCon003_Heli_BridgeAmbush"
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L2_2 = Ai
    L2_2 = L2_2.Goal
    L3_2 = {}
    L4_2 = Vehicle
    L4_2 = L4_2.GetDriver
    L5_2 = L1_2
    L4_2 = L4_2(L5_2)
    L3_2.AIGuid = L4_2
    L3_2.Goal = "PathMove"
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "Path_PmcCon003_AngelFallsBridge"
    L4_2 = L4_2(L5_2)
    L3_2.Target = L4_2
    L3_2.Priority = "LowPri"
    L3_2.Haste = 1
    L2_2(L3_2)
  else
  end
end

AngelFallsBridgeAmbush = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 10
  L4_2[1] = L5_2
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = {}
  L2_2 = {}
  L3_2 = "Driving"
  L4_2 = {}
  L5_2 = {}
  L6_2 = "Car"
  L7_2 = "M151 .50Cal (VZ) (DriverGunner)"
  L8_2 = 1
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L6_2 = {}
  L7_2 = "Tank"
  L8_2 = "Scorpion90 (Full)"
  L9_2 = 1
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = {}
  L6_2 = {}
  L7_2 = "Car"
  L8_2 = 4
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = {}
  L8_2 = "Tank"
  L9_2 = 2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L3_2 = {}
  L4_2 = "Stopped"
  L5_2 = {}
  L6_2 = {}
  L7_2 = "Car"
  L8_2 = "M151 .50Cal (VZ) (DriverGunner)"
  L9_2 = 1
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L7_2 = {}
  L8_2 = "Tank"
  L9_2 = "Scorpion90 (Full)"
  L10_2 = 1
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = {}
  L7_2 = {}
  L8_2 = "Car"
  L9_2 = 4
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L8_2 = {}
  L9_2 = "Tank"
  L10_2 = 2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L4_2 = {}
  L5_2 = "Offroad"
  L6_2 = {}
  L7_2 = {}
  L8_2 = "Car"
  L9_2 = "M151 .50Cal (VZ) (DriverGunner)"
  L10_2 = 1
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L8_2 = {}
  L9_2 = "Tank"
  L10_2 = "Scorpion90 (Full)"
  L11_2 = 1
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = {}
  L8_2 = {}
  L9_2 = "Car"
  L10_2 = 4
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L9_2 = {}
  L10_2 = "Tank"
  L11_2 = 2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L2_2 = MrxFactionManager
  L2_2 = L2_2.SetCustomPursuit
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "VZ"
  L3_2 = L3_2(L4_2)
  L4_2 = -1
  L5_2 = L1_2
  L2_2(L3_2, L4_2, L5_2)
end

StartPursuit = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = MrxFactionManager
  L1_2 = L1_2.ClearCustomPursuit
  L1_2()
end

StopPursuit = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L1_2 = {}
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "Alouette3 Elite (Driver)"
  L2_2 = L2_2(L3_2)
  L3_2 = 1
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L2_2 = {}
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "Mi35 (AA Driver)"
  L3_2 = L3_2(L4_2)
  L4_2 = 1
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = {}
  L3_2.NumToSpawn = 1
  L3_2.WaveDelay = 0
  L3_2.SpawnDist = 200
  L4_2 = {}
  L5_2 = L2_2
  L4_2[1] = L5_2
  L3_2.units = L4_2
  L4_2 = {}
  L4_2.NumToSpawn = 1
  L4_2.WaveDelay = 8
  L4_2.SpawnDist = 200
  L5_2 = {}
  L6_2 = L1_2
  L5_2[1] = L6_2
  L4_2.units = L5_2
  L5_2 = {}
  L5_2.NumToSpawn = 1
  L5_2.WaveDelay = 15
  L5_2.SpawnDist = 300
  L6_2 = {}
  L7_2 = L1_2
  L6_2[1] = L7_2
  L5_2.units = L6_2
  L6_2 = {}
  L6_2.NumToSpawn = 2
  L6_2.WaveDelay = 15
  L6_2.SpawnDist = 300
  L7_2 = {}
  L8_2 = L1_2
  L7_2[1] = L8_2
  L6_2.units = L7_2
  L7_2 = {}
  L7_2.NumToSpawn = 1
  L7_2.WaveDelay = 20
  L7_2.SpawnDist = 300
  L8_2 = {}
  L9_2 = L2_2
  L8_2[1] = L9_2
  L7_2.units = L8_2
  L8_2 = {}
  L8_2.NumToSpawn = 1
  L8_2.WaveDelay = 15
  L8_2.SpawnDist = 300
  L9_2 = {}
  L10_2 = L1_2
  L9_2[1] = L10_2
  L8_2.units = L9_2
  L9_2 = {}
  L9_2.NumToSpawn = 2
  L9_2.WaveDelay = 15
  L9_2.SpawnDist = 300
  L10_2 = {}
  L11_2 = L1_2
  L10_2[1] = L11_2
  L9_2.units = L10_2
  L10_2 = Pg
  L10_2 = L10_2.StartHeliWaveSpawner
  L11_2 = {}
  L12_2 = L3_2
  L13_2 = L4_2
  L14_2 = L5_2
  L15_2 = L6_2
  L16_2 = L7_2
  L17_2 = L8_2
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L11_2[3] = L14_2
  L11_2[4] = L15_2
  L11_2[5] = L16_2
  L11_2[6] = L17_2
  L10_2(L11_2)
end

StartHeliPursuit = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = StopPursuit
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Pg
  L1_2 = L1_2.StopHeliWaveSpawner
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = MrxSupportManager
  L1_2 = L1_2.MakeRecruitAvailable
  L2_2 = "Copter"
  L1_2(L2_2)
  L1_2 = MrxSupportData
  L1_2 = L1_2.RemoveFreebie
  L2_2 = "Bunker Buster"
  L1_2(L2_2)
  L1_2 = Object
  L1_2 = L1_2.Remove
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "PMC003_EwanTaxi"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2 = L2_2(L3_2)
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = MrxUtil
  L1_2 = L1_2.StopHealthBar
  L2_2 = uPMCguid
  L1_2(L2_2)
  L1_2 = WifPmcInterior
  L1_2 = L1_2.SetEntranceLock
  L2_2 = false
  L1_2(L2_2)
  L1_2 = WifPmcInterior
  L1_2 = L1_2.RefreshUiDisplay
  L1_2()
  L1_2 = {}
  L2_2 = "vz_state_pmccon003_BunkerAA"
  L3_2 = "vz_state_pmccon003_bunkerdefenses"
  L4_2 = "vz_state_pmccon003_solbunkerbase"
  L5_2 = "vz_state_pmccon003"
  L6_2 = "vz_state_pmccon003_getcarmona"
  L7_2 = "vz_state_pmccon003_pmcattack"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L2_2 = MrxLayerManager
  L2_2 = L2_2.MarkForRemoval
  L3_2 = L1_2
  L2_2(L3_2)
  L2_2 = {}
  L3_2 = "vz_State_Pmc_LivedIn"
  L4_2 = "vz_state_merida_act2_helo"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = MrxLayerManager
  L3_2 = L3_2.MarkForAddition
  L4_2 = L2_2
  L3_2(L4_2)
  L3_2 = MrxTaskContract
  L3_2 = L3_2.Cleanup
  L4_2 = A0_2
  L3_2(L4_2)
end

Cleanup = L0_1
