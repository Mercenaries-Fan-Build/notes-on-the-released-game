local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxApcDrop"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPlayer"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTimer"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = import
L1_1 = "HijackContractManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxArtilleryAttack"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxMusic"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVerifyManager"
L0_1(L1_1)
L0_1 = 0
NETEVENT_HIJACKSOLANO = L0_1
L0_1 = 1
NETEVENT_ARTILLERYATTACK = L0_1
L0_1 = 2
NETEVENT_KILLBRIDGE = L0_1
L0_1 = 3
NETEVENT_CHANGEATMOSPHERE = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = {}
  L3_2 = "vz_state_SolBunkerBase_Act1"
  L4_2 = "vz_state_SolBunkerBase_Act1"
  L5_2 = "vz_state_PmcCon003_SolBunkerBanse "
  L6_2 = "vz_state_sol_bunker"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L3_2 = MrxLayerManager
  L3_2 = L3_2.Remove
  L4_2 = L2_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = {}
    L1_3 = "vz_state_SolBunkerBase_PmcCon004"
    L2_3 = "vz_state_pmccon004"
    L3_3 = "vz_state_sol_base_pristine"
    L4_3 = "vz_state_SolanoBase_PMC004"
    L5_3 = "vz_state_sol_bunker_pmc004"
    L6_3 = "vz_state_Car_city_pristine"
    L0_3[1] = L1_3
    L0_3[2] = L2_3
    L0_3[3] = L3_3
    L0_3[4] = L4_3
    L0_3[5] = L5_3
    L0_3[6] = L6_3
    L1_3 = MrxLayerManager
    L1_3 = L1_3.Add
    L2_3 = L0_3
    L3_3 = A0_2
    L3_3 = L3_3.AssetsLoaded
    L4_3 = {}
    L5_3 = A0_2
    L4_3[1] = L5_3
    L1_3(L2_3, L3_3, L4_3)
  end
  
  L3_2(L4_2, L5_2)
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.ChangeLineRegionSetting
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "rgn_atmo_caracas"
  L2_2 = L2_2(L3_2)
  L3_2 = "warzone"
  L1_2(L2_2, L3_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.ChangeLineRegionSetting
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "rgn_atmo_Angelfalls"
  L2_2 = L2_2(L3_2)
  L3_2 = "WarzoneSolano"
  L1_2(L2_2, L3_2)
  L1_2 = Net
  L1_2 = L1_2.IsServer
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = Net
    L1_2 = L1_2.SendCustomEvent
    L2_2 = "PmcCon004"
    L3_2 = NETEVENT_CHANGEATMOSPHERE
    L4_2 = {}
    L1_2(L2_2, L3_2, L4_2)
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
    L6_2 = "PmcCon004"
    L7_2 = NETEVENT_CHANGEATMOSPHERE
    L8_2 = {}
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
    _evClientJoinedPMC004 = L1_2
  end
  L1_2 = Net
  L1_2 = L1_2.IsServer
  L1_2()
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "Alouette3 Attack (VZ) 0x00105219"
  L1_2 = L1_2(L2_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectHibernation
  L5_2 = {}
  L6_2 = L1_2
  L7_2 = "awake"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = Vehicle
  L6_2 = L6_2.Usable
  L7_2 = {}
  L8_2 = L1_2
  L9_2 = false
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "DestroyBunker"
  L4_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2.vTgtInclude = "Solano_Bunker_PMC004"
  L4_2.sDspShortDesc = "[PmcCon004.Objectives.001]"
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._SetFlag
    L2_3 = "HijackInitiated"
    L0_3(L1_3, L2_3)
    L0_3 = _Checkpoint
    L1_3 = {}
    L2_3 = "BunkerCheckpoint"
    L1_3[1] = L2_3
    L0_3(L1_3)
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._CreateEvent
    L2_3 = Event
    L2_3 = L2_3.TimerRelative
    L3_3 = {}
    L4_3 = 7
    L3_3[1] = L4_3
    
    function L4_3()
      local L0_4, L1_4, L2_4
      L0_4 = MrxVoSequence
      L0_4 = L0_4.Start
      L1_4 = {}
      L2_4 = "Fiona.Cam.02"
      L1_4[1] = L2_4
      L0_4(L1_4)
    end
    
    L0_3(L1_3, L2_3, L3_3, L4_3)
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.SolanoHijackInit
    L0_3(L1_3)
  end
  
  L4_2.fOnComplete = L5_2
  L5_2 = {}
  L6_2 = {}
  L7_2 = A0_2.BunkerIntact
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnCancel = L5_2
  L2_2(L3_2, L4_2)
  L2_2 = MrxSupportData
  L2_2 = L2_2.AddFreebie
  L3_2 = "PmcCon004_Nuke"
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ScriptEvent
  L5_2 = {}
  L6_2 = "Nuked"
  
  function L7_2()
    local L0_3, L1_3
    L0_3 = true
    return L0_3
  end
  
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = NukeDetonated
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L2_2 = SetCompoundMusic
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = BridgeDestruction
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = HijackContractManager
  L2_2 = L2_2.SetActiveContract
  L3_2 = A0_2
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2._GetFlag
  L4_2 = "HijackInitiated"
  L2_2 = L2_2(L3_2, L4_2)
  if not L2_2 then
    L2_2 = MrxVoSequence
    L2_2 = L2_2.Start
    L3_2 = {}
    L4_2 = "Fiona-In-Mission-Contract-Pmc04-01"
    L5_2 = 0.5
    L6_2 = "Misha-In-Mission-Contract-Pmc04-02"
    L7_2 = 0.5
    L8_2 = "Fiona-In-Mission-Contract-Pmc04-03"
    L9_2 = 0.5
    L10_2 = {}
    L11_2 = SetMissionMusic
    L12_2 = {}
    L13_2 = A0_2
    L12_2[1] = L13_2
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L3_2[4] = L7_2
    L3_2[5] = L8_2
    L3_2[6] = L9_2
    L3_2[7] = L10_2
    L2_2(L3_2)
  end
end

Activated = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = MrxUtil
  L2_2 = L2_2.GetDistanceToObject
  L3_2 = "Solano_Bunker_PMC004"
  L4_2 = A1_2[1]
  L5_2 = A1_2[2]
  L6_2 = A1_2[3]
  L7_2 = true
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  if L2_2 < 20 then
    L2_2 = Object
    L2_2 = L2_2.Kill
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = "Solano_Bunker_PMC004"
    L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L3_2(L4_2)
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
    L2_2 = Player
    L2_2 = L2_2.GetLocalPlayer
    L2_2 = L2_2()
    L3_2 = Player
    L3_2 = L3_2.GetCamera
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    L4_2 = Player
    L4_2 = L4_2.GetCharacter
    L5_2 = L2_2
    L4_2 = L4_2(L5_2)
    L5_2 = Camera
    L5_2 = L5_2.Shake
    L6_2 = L3_2
    L7_2 = "ShakeCameraMedium"
    L8_2 = L4_2
    L9_2 = 6
    L10_2 = 5
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  else
    L2_2 = MrxVoSequence
    L2_2 = L2_2.Start
    L3_2 = {}
    L4_2 = "Fiona-In-Mission-Contract-Pmc04-65"
    L5_2 = 3
    L6_2 = {}
    L7_2 = A0_2.BunkerIntact
    L8_2 = {}
    L9_2 = A0_2
    L8_2[1] = L9_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L2_2(L3_2)
  end
end

NukeDetonated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = Sound
  L1_2 = L1_2.SetDynamicMusic
  L2_2 = false
  L1_2(L2_2)
  L1_2 = MrxMusic
  L1_2 = L1_2.PlaySpecialMusic
  L2_2 = "mu_pmc_006_01"
  L1_2(L2_2)
end

SetMissionMusic = L0_1

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
  L7_2 = "lnrgn_CompoundMusic"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = MrxMusic
    L0_3 = L0_3.StopSpecialMusic
    L0_3()
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._CreateEvent
    L2_3 = Event
    L2_3 = L2_3.TimerRelative
    L3_3 = {}
    L4_3 = 3
    L3_3[1] = L4_3
    
    function L4_3()
      local L0_4, L1_4
      L0_4 = MrxMusic
      L0_4 = L0_4.PlaySpecialMusic
      L1_4 = "mu_pmc_006_02"
      L0_4(L1_4)
    end
    
    L0_3 = L0_3(L1_3, L2_3, L3_3, L4_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

SetCompoundMusic = L0_1

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
  L7_2 = "lnrg_destroybridge1"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Solano.vp7sol01"
    L3_3 = 0.5
    L4_3 = {}
    L4_3.mattias = "Mattias-In-Mission-Contract-Pmc04-06"
    L4_3.jennifer = "Jennifer-In-Mission-Contract-Pmc04-07"
    L4_3.chris = "Chris-In-Mission-Contract-Pmc04-08"
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L1_3[3] = L4_3
    L0_3(L1_3)
    L0_3 = MrxArtilleryAttack
    L0_3 = L0_3.Create
    L1_3 = Pg
    L1_3 = L1_3.GetGuidByName
    L2_3 = "loc_solattack1"
    L3_3 = 16
    L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3 = L1_3(L2_3, L3_3)
    L0_3(L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3)
    L0_3 = MrxArtilleryAttack
    L0_3 = L0_3.Create
    L1_3 = Pg
    L1_3 = L1_3.GetGuidByName
    L2_3 = "loc_solattack2"
    L3_3 = 16
    L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3 = L1_3(L2_3, L3_3)
    L0_3(L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3)
    L0_3 = Net
    L0_3 = L0_3.SendCustomEvent
    L1_3 = "PmcCon004"
    L2_3 = NETEVENT_ARTILLERYATTACK
    L3_3 = {}
    L4_3 = Pg
    L4_3 = L4_3.GetGuidByName
    L5_3 = "loc_solattack1"
    L6_3 = 16
    L4_3 = L4_3(L5_3, L6_3)
    L5_3 = Pg
    L5_3 = L5_3.GetGuidByName
    L6_3 = "loc_solattack2"
    L7_3 = 15
    L5_3, L6_3, L7_3 = L5_3(L6_3, L7_3)
    L3_3[1] = L4_3
    L3_3[2] = L5_3
    L3_3[3] = L6_3
    L3_3[4] = L7_3
    L0_3(L1_3, L2_3, L3_3)
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._CreateEvent
    L2_3 = Event
    L2_3 = L2_3.TimerRelative
    L3_3 = {}
    L4_3 = 10
    L3_3[1] = L4_3
    
    function L4_3()
      local L0_4, L1_4
    end
    
    L0_3 = L0_3(L1_3, L2_3, L3_3, L4_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
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
  L7_2 = "lnrg_destroybridge2"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Solano.vp7sol02"
    L3_3 = 0.5
    L4_3 = {}
    L4_3.mattias = "Mattias-In-Mission-Contract-Pmc04-67"
    L4_3.jennifer = "Jennifer-In-Mission-Contract-Pmc04-68"
    L4_3.chris = "Chris-In-Mission-Contract-Pmc04-69"
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L1_3[3] = L4_3
    L0_3(L1_3)
    L0_3 = MrxArtilleryAttack
    L0_3 = L0_3.Create
    L1_3 = Pg
    L1_3 = L1_3.GetGuidByName
    L2_3 = "loc_solattack3"
    L3_3 = 16
    L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3 = L1_3(L2_3, L3_3)
    L0_3(L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3)
    L0_3 = MrxArtilleryAttack
    L0_3 = L0_3.Create
    L1_3 = Pg
    L1_3 = L1_3.GetGuidByName
    L2_3 = "loc_solattack4"
    L3_3 = 16
    L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3 = L1_3(L2_3, L3_3)
    L0_3(L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3)
    L0_3 = Net
    L0_3 = L0_3.SendCustomEvent
    L1_3 = "PmcCon004"
    L2_3 = NETEVENT_ARTILLERYATTACK
    L3_3 = {}
    L4_3 = Pg
    L4_3 = L4_3.GetGuidByName
    L5_3 = "loc_solattack3"
    L6_3 = 16
    L4_3 = L4_3(L5_3, L6_3)
    L5_3 = Pg
    L5_3 = L5_3.GetGuidByName
    L6_3 = "loc_solattack4"
    L7_3 = 15
    L5_3, L6_3, L7_3 = L5_3(L6_3, L7_3)
    L3_3[1] = L4_3
    L3_3[2] = L5_3
    L3_3[3] = L6_3
    L3_3[4] = L7_3
    L0_3(L1_3, L2_3, L3_3)
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._CreateEvent
    L2_3 = Event
    L2_3 = L2_3.TimerRelative
    L3_3 = {}
    L4_3 = 10
    L3_3[1] = L4_3
    
    function L4_3()
      local L0_4, L1_4
    end
    
    L0_3 = L0_3(L1_3, L2_3, L3_3, L4_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

BridgeDestruction = L0_1

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
  L7_2 = "lnrgn_apcdrop1"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = SetUpApcDrop1
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
end

DetectBridgeOneProximity = L0_1

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
  L7_2 = "lnrgn_apcdrop2"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = SetUpApcDrop2
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

DetectBridgeTwoProximity = L0_1

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
  L7_2 = "lnrgn_apcdrop3"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = SetUpApcDrop3
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

DetectBridgeThreeProximity = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = ApcDrop
  L2_2 = A0_2
  L3_2 = "pth_apcdrop1_veh1"
  L4_2 = "M151 .50Cal (VZ) (Full)"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = ApcDrop
  L2_2 = A0_2
  L3_2 = "pth_apcdrop1_veh2"
  L4_2 = "M151 .50Cal (VZ) (Full)"
  L1_2(L2_2, L3_2, L4_2)
end

SetUpApcDrop1 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = ApcDrop
  L2_2 = A0_2
  L3_2 = "pth_apcdrop2_veh1"
  L4_2 = "M35 (Cargo) (VZ) (Full)"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = ApcDrop
  L2_2 = A0_2
  L3_2 = "pth_apcdrop2_veh2"
  L4_2 = "M35 (Cargo) (VZ) (Full)"
  L1_2(L2_2, L3_2, L4_2)
end

SetUpApcDrop2 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = ApcDrop
  L2_2 = A0_2
  L3_2 = "pth_apcdrop3_veh1"
  L4_2 = "M113 (VZ) (Full)"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = ApcDrop
  L2_2 = A0_2
  L3_2 = "pth_apcdrop3_veh2"
  L4_2 = "M113 (VZ) (Full)"
  L1_2(L2_2, L3_2, L4_2)
end

SetUpApcDrop3 = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L3_2 = MrxUtil
  L3_2 = L3_2.FindSpawnPointOutOfView
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  L5_2 = 200
  L3_2, L4_2, L5_2, L6_2, L7_2 = L3_2(L4_2, L5_2)
  if not L3_2 then
    return
  end
  L8_2 = Pg
  L8_2 = L8_2.Spawn
  L9_2 = A2_2
  L10_2 = L4_2
  L11_2 = L5_2
  L12_2 = L6_2
  L13_2 = L7_2
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  L9_2 = Object
  L9_2 = L9_2.SetHibernationDistance
  L10_2 = L8_2
  L11_2 = 300
  L9_2(L10_2, L11_2)
  L10_2 = A0_2
  L9_2 = A0_2._CreateEvent
  L11_2 = Event
  L11_2 = L11_2.ObjectHibernation
  L12_2 = {}
  L13_2 = L8_2
  L14_2 = "awake"
  L12_2[1] = L13_2
  L12_2[2] = L14_2
  
  function L13_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L0_3 = {}
    L1_3 = L8_2
    L0_3.uVehicle = L1_3
    L1_3 = A1_2
    L0_3.inDest = L1_3
    L0_3.inDestType = "path"
    L0_3.inSpeed = 0.7
    L1_3 = A0_2
    L2_3 = L1_3
    L1_3 = L1_3._CreateEvent
    L3_3 = Event
    L3_3 = L3_3.TimerRelative
    L4_3 = {}
    L5_3 = 3
    L4_3[1] = L5_3
    
    function L5_3(A0_4)
      local L1_4, L2_4, L3_4
      L1_4 = MrxApcDrop
      L2_4 = L1_4
      L1_4 = L1_4.Create
      L3_4 = A0_4
      L1_4(L2_4, L3_4)
    end
    
    L6_3 = {}
    L7_3 = L0_3
    L6_3[1] = L7_3
    L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
  end
  
  L9_2(L10_2, L11_2, L12_2, L13_2)
end

ApcDrop = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  if A1_2 then
    L2_2 = gtAPCEvents
    L2_2[A1_2] = nil
  end
  L2_2 = Math
  L2_2 = L2_2.randi
  L3_2 = kfAPCSpawnDelayLow
  L4_2 = kfAPCSpawnDelayHigh
  L2_2 = L2_2(L3_2, L4_2)
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = L2_2
  L6_2[1] = L7_2
  L7_2 = _APCSpawn
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
end

_DelayedAPCSpawn = L0_1

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
  L7_2 = "lnrgn_helicheck1"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = SpawnHelis
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

DetectHeli1 = L0_1

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
  L7_2 = "lnrgn_helicheck2"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = SpawnHelis
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

DetectHeli2 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = MrxPlayer
  L1_2 = L1_2.IsInVehicle
  L2_2 = "Helicopter"
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = Object
    L1_2 = L1_2.GetPosition
    L2_2 = Player
    L2_2 = L2_2.GetCharacter
    L3_2 = Player
    L3_2 = L3_2.GetLocalPlayer
    L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L3_2()
    L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
    L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
    L4_2 = Pg
    L4_2 = L4_2.Spawn
    L5_2 = "Alouette3 Superiority (Driver)"
    L6_2 = L1_2 + 100
    L7_2 = L2_2 + 100
    L8_2 = L3_2 + 100
    L4_2(L5_2, L6_2, L7_2, L8_2)
  end
end

SpawnHelis = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Add
  L2_2 = "vz_State_PmcCon004SolanoHijack"
  L3_2 = SolanoHijackLayerLoaded
  L4_2 = {}
  L5_2 = A0_2
  L4_2[1] = L5_2
  L1_2(L2_2, L3_2, L4_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "SolanoHijackComplete"
  
  function L6_2()
    local L0_3, L1_3
    L0_3 = true
    return L0_3
  end
  
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = A0_2.Complete
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "SolanoHijackFailed"
  
  function L6_2()
    local L0_3, L1_3
    L0_3 = true
    return L0_3
  end
  
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = A0_2.Cancel
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

SolanoHijackInit = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Get Solano"
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2 = Player
  L4_2 = L4_2.GetAnyCharacter
  L4_2 = L4_2()
  L3_2.vTgtInclude = L4_2
  L3_2.vDestLoc = "loc_BunkerDoor"
  L3_2.vDestRegion = "lnrgn_GetSolano"
  L3_2.sDspShortDesc = "[PmcCon004.Objectives.003]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = SolanoHijackObjective
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.SolanoEscaped
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnCancel = L4_2
  L1_2(L2_2, L3_2)
end

SolanoObjective = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Get Solano"
  L3_2.sModuleName = "MrxTaskObjectiveEnterVehicle"
  L3_2.vTgtInclude = "Mi35 (Solano Hijack)"
  L3_2.nQuota = 1
  L4_2 = Player
  L4_2 = L4_2.GetAnyCharacter
  L4_2 = L4_2()
  L3_2.uPlayer = L4_2
  L3_2.sDspShortDesc = "[PmcCon004.Objectives.002]"
  L4_2 = {}
  L3_2.tOnComplete = L4_2
  L4_2 = {}
  L3_2.tOnCancel = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  oSolanoHeliObjective = L1_2
end

SolanoHijackObjective = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = SolanoObjective
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = PlayerEntersDockRegion
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = SolanoStaging
  L2_2 = A0_2
  L1_2(L2_2)
end

SolanoHijackLayerLoaded = L0_1

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
  L7_2 = "lnrgn_explosion1"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = MrxUtil
    L0_3 = L0_3.SpawnObject
    L1_3 = "Explosion (grenade)"
    L2_3 = Pg
    L2_3 = L2_3.GetGuidByName
    L3_3 = "loc_explosion1"
    L2_3, L3_3 = L2_3(L3_3)
    L0_3(L1_3, L2_3, L3_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
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
  L7_2 = "lnrgn_explosion2_3"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = MrxUtil
    L0_3 = L0_3.SpawnObject
    L1_3 = "Explosion (grenade)"
    L2_3 = Pg
    L2_3 = L2_3.GetGuidByName
    L3_3 = "loc_explosion2"
    L2_3, L3_3, L4_3, L5_3 = L2_3(L3_3)
    L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
    L0_3 = MrxUtil
    L0_3 = L0_3.SpawnObject
    L1_3 = "Explosion (grenade)"
    L2_3 = Pg
    L2_3 = L2_3.GetGuidByName
    L3_3 = "loc_explosion3"
    L2_3, L3_3, L4_3, L5_3 = L2_3(L3_3)
    L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
    L0_3 = MrxUtil
    L0_3 = L0_3.SpawnObject
    L1_3 = "VZ Soldier (Mook)"
    L2_3 = Pg
    L2_3 = L2_3.GetGuidByName
    L3_3 = "loc_spawnmans"
    L2_3, L3_3, L4_3, L5_3 = L2_3(L3_3)
    L0_3 = L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
    L1_3 = MrxUtil
    L1_3 = L1_3.SpawnObject
    L2_3 = "VZ Soldier (Mook)"
    L3_3 = Pg
    L3_3 = L3_3.GetGuidByName
    L4_3 = "loc_spawnmans"
    L3_3, L4_3, L5_3 = L3_3(L4_3)
    L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3)
    L2_3 = Ai
    L2_3 = L2_3.Goal
    L3_3 = {}
    L3_3.AIGuid = L0_3
    L3_3.Goal = "PathMove"
    L4_3 = Pg
    L4_3 = L4_3.GetGuidByName
    L5_3 = "pth_explodingmans"
    L4_3 = L4_3(L5_3)
    L3_3.Target = L4_3
    L3_3.Priority = "HiPri"
    L3_3.Haste = 1
    L2_3(L3_3)
    L2_3 = Ai
    L2_3 = L2_3.Goal
    L3_3 = {}
    L3_3.AIGuid = L1_3
    L3_3.Goal = "PathMove"
    L4_3 = Pg
    L4_3 = L4_3.GetGuidByName
    L5_3 = "pth_explodingmans"
    L4_3 = L4_3(L5_3)
    L3_3.Target = L4_3
    L3_3.Priority = "HiPri"
    L3_3.Haste = 1
    L2_3(L3_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

SolanoStaging = L0_1

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
  L7_2 = "timerLineRegion"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = SolanoRace
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

PlayerEntersTimerRegion = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.ObjectProximity
  L3_2 = {}
  L4_2 = "hero"
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "activateActionHijack_Lineregion"
  L5_2 = L5_2(L6_2)
  L6_2 = "<"
  L7_2 = 50
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L4_2 = ProximityCallback
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

PlayerEntersDockRegion = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "SolanoBunkerDoors"
  L1_2 = L1_2(L2_2)
  L2_2 = Object
  L2_2 = L2_2.OpenGate
  L3_2 = L1_2
  L2_2(L3_2)
end

OpenBunkerDoors = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A1_2[1]
  uCharGuid = L2_2
  L2_2 = Player
  L2_2 = L2_2.GetLocalCharacter
  L2_2 = L2_2()
  uLocalChar = L2_2
  L2_2 = uLocalChar
  L3_2 = uCharGuid
  if L2_2 == L3_2 then
    L2_2 = DockAttack
    L3_2 = A0_2
    L4_2 = uCharGuid
    L2_2(L3_2, L4_2)
  else
    L2_2 = Net
    L2_2 = L2_2.SendCustomEvent
    L3_2 = "PmcCon004"
    L4_2 = NETEVENT_HIJACKSOLANO
    L5_2 = {}
    L2_2(L3_2, L4_2, L5_2)
  end
end

ProximityCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = NETEVENT_HIJACKSOLANO
  if A0_2 == L2_2 then
    L2_2 = DockAttack
    L3_2 = self
    L4_2 = Player
    L4_2 = L4_2.GetLocalCharacter
    L4_2 = L4_2()
    L2_2(L3_2, L4_2)
  else
    L2_2 = NETEVENT_ARTILLERYATTACK
    if A0_2 == L2_2 then
      L2_2 = MrxArtilleryAttack
      L2_2 = L2_2.Create
      L3_2 = A1_2[1]
      L2_2(L3_2)
      L2_2 = MrxArtilleryAttack
      L2_2 = L2_2.Create
      L3_2 = A1_2[2]
      L2_2(L3_2)
    else
      L2_2 = NETEVENT_KILLBRIDGE
      if A0_2 == L2_2 then
        L2_2 = Object
        L2_2 = L2_2.Kill
        L3_2 = A1_2[1]
        L2_2(L3_2)
        L2_2 = Object
        L2_2 = L2_2.Kill
        L3_2 = A1_2[2]
        L2_2(L3_2)
      else
        L2_2 = NETEVENT_CHANGEATMOSPHERE
        if A0_2 == L2_2 then
          L2_2 = Graphics
          L2_2 = L2_2.Atmosphere
          L2_2 = L2_2.ChangeLineRegionSetting
          L3_2 = Pg
          L3_2 = L3_2.GetGuidByName
          L4_2 = "rgn_atmo_caracas"
          L3_2 = L3_2(L4_2)
          L4_2 = "warzone"
          L2_2(L3_2, L4_2)
          L2_2 = Graphics
          L2_2 = L2_2.Atmosphere
          L2_2 = L2_2.ChangeLineRegionSetting
          L3_2 = Pg
          L3_2 = L3_2.GetGuidByName
          L4_2 = "rgn_atmo_Angelfalls"
          L3_2 = L3_2(L4_2)
          L4_2 = "WarzoneSolano"
          L2_2(L3_2, L4_2)
        end
      end
    end
  end
end

NetEventCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = oTimer
  if L2_2 then
    L2_2 = oTimer
    L3_2 = L2_2
    L2_2 = L2_2.Stop
    L2_2(L3_2)
  end
  L2_2 = Vehicle
  L2_2 = L2_2.GetFromRider
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  uCurrentVehicle = L2_2
  L2_2 = uCurrentVehicle
  if L2_2 then
    L2_2 = Vehicle
    L2_2 = L2_2.Exit
    L3_2 = uCurrentVehicle
    L4_2 = A1_2
    L5_2 = true
    L2_2(L3_2, L4_2, L5_2)
  end
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "Mi35 (Solano Hijack)"
  L2_2 = L2_2(L3_2)
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 0.5
  L5_2[1] = L6_2
  
  function L6_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = Vehicle
    L0_3 = L0_3.Enter
    L1_3 = L2_2
    L2_3 = A1_2
    L3_3 = "d"
    L4_3 = false
    L5_3 = true
    L0_3 = L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
  end
  
  L3_2(L4_2, L5_2, L6_2)
end

DockAttack = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = MrxTimer
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L3_2 = {}
  L3_2.nStartTime = 60
  L3_2.nWarning = 15
  L3_2.iTray = 2
  L4_2 = {}
  L5_2 = {}
  L6_2 = OutOfTimeSubtitle
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tDoneCallbacks = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  oTimer = L1_2
  L1_2 = StartTimeSubtitle
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = oTimer
  L2_2 = L1_2
  L1_2 = L1_2.Start
  L1_2(L2_2)
end

SolanoRace = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2._PlayVo
  L3_2 = 0
  L4_2 = "Fiona-In-Mission-Contract-Pmc04-10"
  L1_2(L2_2, L3_2, L4_2)
end

StartTimeSubtitle = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = HijackContractManager
  L1_2 = L1_2.CancelActiveContract
  L1_2()
end

OutOfTimeSubtitle = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[PmcCon004.Terms.Cancel01]"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.Cancel
  L1_2(L2_2)
end

BunkerIntact = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[PmcCon004.Terms.Cancel02]"
  L1_2(L2_2, L3_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Pmc04-66"
  L4_2 = 3
  L5_2 = {}
  L6_2 = A0_2.Cancel
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L1_2(L2_2)
end

SolanoEscaped = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = _evClientJoinedPMC004
  L1_2(L2_2)
  L1_2 = MrxVerifyManager
  L1_2 = L1_2.GetKilled
  L1_2 = L1_2()
  if L1_2 == 0 then
    L1_2 = Net
    L1_2 = L1_2.IsActive
    L1_2 = L1_2()
    if L1_2 then
      L2_2 = A0_2
      L1_2 = A0_2._SetPlayer1Bonus
      L3_2 = 25000000
      L1_2(L2_2, L3_2)
      L2_2 = A0_2
      L1_2 = A0_2._SetPlayer2Bonus
      L3_2 = 25000000
      L1_2(L2_2, L3_2)
    else
      L2_2 = A0_2
      L1_2 = A0_2._SetPlayer1Bonus
      L3_2 = 25000000
      L1_2(L2_2, L3_2)
    end
  end
  L1_2 = MrxSupportData
  L1_2 = L1_2.RemoveFreebie
  L2_2 = "PmcCon004_Nuke"
  L1_2(L2_2)
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
