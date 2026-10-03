local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxCinematic"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxAchievements"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxMusic"
L0_1(L1_1)
L0_1 = "_outskirt_bld_mercbar 0x000c7042"
ksBarExitBuilding = L0_1
L0_1 = "BarExit Camera Location"
ksBarExitCameraLocation = L0_1
L0_1 = {}
L1_1 = "pmcoutpost_hq_door_roof"
L2_1 = "pmcoutpost_hq_door_garage"
L3_1 = "pmcoutpost_hq_door_entrance"
L4_1 = "pmcoutpost_hqgarage_door_big01"
L5_1 = "pmcoutpost_hqgarage_door_big02"
L6_1 = "pmcoutpost_hqgarage_door_backdoor"
L7_1 = "pmcoutpost_hqgarage_door_topdoor"
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1
L0_1[5] = L5_1
L0_1[6] = L6_1
L0_1[7] = L7_1
tPmcDoors = L0_1
L0_1 = 0
NETEVENT_SETSTARTUPWEAPONS = L0_1
L0_1 = 1
NETEVENT_MOVECOLLISION = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = Pg
  L0_2 = L0_2.GetGuidByName
  L1_2 = "PMC001_FrontDoor_InvisiblePhysics"
  L0_2 = L0_2(L1_2)
  if L0_2 then
    L1_2 = Event
    L1_2 = L1_2.Create
    L2_2 = Event
    L2_2 = L2_2.ObjectHibernation
    L3_2 = {}
    L4_2 = L0_2
    L5_2 = "awake"
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L4_2 = NetSafeMoveInvisibleCollision
    L1_2(L2_2, L3_2, L4_2)
  else
    L1_2 = Event
    L1_2 = L1_2.Create
    L2_2 = Event
    L2_2 = L2_2.TimerRelative
    L3_2 = {}
    L4_2 = 1
    L3_2[1] = L4_2
    L4_2 = ClientMoveCollision
    L1_2(L2_2, L3_2, L4_2)
  end
end

ClientMoveCollision = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = NETEVENT_SETSTARTUPWEAPONS
  if A0_2 == L2_2 then
    L2_2 = nil
    bMoveInvisibleCollision = L2_2
    L2_2 = Event
    L2_2 = L2_2.Create
    L3_2 = Event
    L3_2 = L3_2.ObjectHibernation
    L4_2 = {}
    L5_2 = Player
    L5_2 = L5_2.GetLocalCharacter
    L5_2 = L5_2()
    L6_2 = "awake"
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L5_2 = SetStartupWeapons
    L2_2(L3_2, L4_2, L5_2)
    L2_2 = A1_2[1]
    if L2_2 == 1 then
      L2_2 = ClientMoveCollision
      L2_2()
    end
  else
    L2_2 = NETEVENT_MOVECOLLISION
    if A0_2 == L2_2 then
      L2_2 = ClientMoveCollision
      L2_2()
    end
  end
end

NetEventCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = {}
  L3_2 = {}
  L4_2 = "Vz_State_PmcCon001"
  L5_2 = "VZ_State_Pmc_Pristine"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L5_2 = A0_2
  L4_2 = A0_2._GetFlag
  L6_2 = "HijackInitiated"
  L4_2 = L4_2(L5_2, L6_2)
  if L4_2 then
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L2_2
    L6_2 = "vz_state_pmccon001_VillaSoldiers"
    L4_2(L5_2, L6_2)
  else
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L3_2
    L6_2 = "vz_state_pmccon001_VillaSoldiers"
    L4_2(L5_2, L6_2)
  end
  L4_2 = MrxLayerManager
  L4_2 = L4_2.Remove
  L5_2 = L2_2
  
  function L6_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = MrxLayerManager
    L0_3 = L0_3.Add
    L1_3 = L3_2
    L2_3 = A0_2
    L2_3 = L2_3.AssetsLoaded
    L3_3 = {}
    L4_3 = A0_2
    L3_3[1] = L4_3
    L0_3(L1_3, L2_3, L3_3)
  end
  
  L4_2(L5_2, L6_2)
  L4_2 = SetStartupWeapons
  L4_2()
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.ActivateMission
  L1_2(L2_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  bMoveInvisibleCollision = L1_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "PMC_CentralBuilding"
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  
  function L5_2(A0_3)
    local L1_3, L2_3, L3_3
    L2_3 = A0_3
    L1_3 = A0_3._SetCancelMessage
    L3_3 = "[PmcCon001.Terms.Cancel03]"
    L1_3(L2_3, L3_3)
    L2_3 = A0_3
    L1_3 = A0_3.Cancel
    L1_3(L2_3)
  end
  
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "_pmcoutpost_bld_hqsuites 0x000cf8c2"
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  
  function L5_2(A0_3)
    local L1_3, L2_3, L3_3
    L2_3 = A0_3
    L1_3 = A0_3._SetCancelMessage
    L3_3 = "[PmcCon001.Terms.Cancel03]"
    L1_3(L2_3, L3_3)
    L2_3 = A0_3
    L1_3 = A0_3.Cancel
    L1_3(L2_3)
  end
  
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "pmcoutpost_bld_hqgarage"
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  
  function L5_2(A0_3)
    local L1_3, L2_3, L3_3
    L2_3 = A0_3
    L1_3 = A0_3._SetCancelMessage
    L3_3 = "[PmcCon001.Terms.Cancel03]"
    L1_3(L2_3, L3_3)
    L2_3 = A0_3
    L1_3 = A0_3.Cancel
    L1_3(L2_3)
  end
  
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.ChangeLineRegionSetting
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "rgn_atmo_PMCinterior"
  L2_2 = L2_2(L3_2)
  L3_2 = "warzone"
  L1_2(L2_2, L3_2)
  L1_2 = Ai
  L1_2 = L1_2.SetLaneActive
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "Road 0x000a7417"
  L2_2 = L2_2(L3_2)
  L3_2 = 1
  L4_2 = false
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Ai
  L1_2 = L1_2.SetLaneActive
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "Road 0x000d3c9a"
  L2_2 = L2_2(L3_2)
  L3_2 = 1
  L4_2 = false
  L1_2(L2_2, L3_2, L4_2)
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "HijackInitiated"
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.GoToVillaInterior
    L3_2 = A0_2
    L1_2(L2_2, L3_2)
    L1_2 = GateCloser
    L2_2 = A0_2
    L1_2(L2_2)
  else
    L2_2 = A0_2
    L1_2 = A0_2._GetFlag
    L3_2 = "VillaReached"
    L1_2 = L1_2(L2_2, L3_2)
    if L1_2 then
      L2_2 = A0_2
      L1_2 = A0_2.KillSolanoEntourage01
      L3_2 = A0_2
      L1_2(L2_2, L3_2)
    else
      L1_2 = IntroBanter
      L2_2 = A0_2
      L1_2(L2_2)
      L1_2 = VZJeepPursuitRegionActivate
      L2_2 = A0_2
      L1_2(L2_2)
      L1_2 = SetupGateCloser
      L2_2 = A0_2
      L1_2(L2_2)
      L1_2 = SetUpBanterRegion
      L2_2 = A0_2
      L1_2(L2_2)
      L1_2 = 0
      L2_2 = bMoveInvisibleCollision
      if L2_2 then
        L1_2 = 1
      end
      L2_2 = Net
      L2_2 = L2_2.SendCustomEvent
      L3_2 = "PmcCon001"
      L4_2 = NETEVENT_SETSTARTUPWEAPONS
      L5_2 = {}
      L6_2 = L1_2
      L5_2[1] = L6_2
      L2_2(L3_2, L4_2, L5_2)
      L2_2 = PmcInvulnerable
      L3_2 = A0_2
      L2_2(L3_2)
      L2_2 = MrxFactionManager
      L2_2 = L2_2.DisableReporting
      L3_2 = true
      L2_2(L3_2)
    end
  end
end

ActivateMission = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = 0
  L5_2 = bMoveInvisibleCollision
  if L5_2 then
    L4_2 = 1
  end
  L5_2 = Net
  L5_2 = L5_2.SendCustomEvent
  L6_2 = "PmcCon001"
  L7_2 = NETEVENT_SETSTARTUPWEAPONS
  L8_2 = {}
  L9_2 = L4_2
  L8_2[1] = L9_2
  L5_2(L6_2, L7_2, L8_2)
end

OnPlayerJoined = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L0_2 = Player
  L0_2 = L0_2.GetLocalCharacter
  L0_2 = L0_2()
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "Assault Rifle"
  L1_2 = L1_2(L2_2)
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "C4"
  L2_2 = L2_2(L3_2)
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "Grenade"
  L3_2 = L3_2(L4_2)
  L4_2 = Human
  L4_2 = L4_2.Inventory
  L4_2 = L4_2.SetAllWeapons
  L5_2 = L0_2
  L6_2 = {}
  L7_2 = L1_2
  L8_2 = L2_2
  L9_2 = L3_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L4_2(L5_2, L6_2)
  L4_2 = Human
  L4_2 = L4_2.Inventory
  L4_2 = L4_2.GetPrimaryWeapon
  L5_2 = L0_2
  L4_2 = L4_2(L5_2)
  L5_2 = Weapon
  L5_2 = L5_2.SetReserveAmmo
  L6_2 = L4_2
  L7_2 = Weapon
  L7_2 = L7_2.GetMaxReserveAmmo
  L8_2 = L4_2
  L7_2, L8_2, L9_2 = L7_2(L8_2)
  L5_2(L6_2, L7_2, L8_2, L9_2)
end

SetStartupWeapons = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Pmc01-72"
  L4_2 = {}
  L4_2.mattias = "Mattias-In-Mission-Contract-Pmc01-73"
  L4_2.jennifer = "Jennifer-In-Mission-Contract-Pmc01-74"
  L4_2.chris = "Chris-In-Mission-Contract-Pmc01-75"
  L5_2 = "Fiona-In-Mission-Contract-Pmc01-76"
  L6_2 = 5
  L7_2 = {}
  L8_2 = SetupGoToObjective
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L1_2(L2_2)
end

IntroBanter = L0_1

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
  L7_2 = "Region_PMC001_VZCheckpointRegion"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = JeepPursuit01
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

VZJeepPursuitRegionActivate = L0_1

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
  L4_2[1] = L5_2
  L5_2 = {}
  L6_2 = {}
  L7_2 = "Car"
  L8_2 = 1
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
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
  L5_2[1] = L6_2
  L6_2 = {}
  L7_2 = {}
  L8_2 = "Car"
  L9_2 = 1
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L6_2[1] = L7_2
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
  L6_2[1] = L7_2
  L7_2 = {}
  L8_2 = {}
  L9_2 = "Car"
  L10_2 = 1
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L7_2[1] = L8_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = {}
  L6_2 = "Heli"
  L7_2 = {}
  L8_2 = {}
  L9_2 = "Car"
  L10_2 = "M151 .50Cal (VZ) (DriverGunner)"
  L11_2 = 1
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L7_2[1] = L8_2
  L8_2 = {}
  L9_2 = {}
  L10_2 = "Car"
  L11_2 = 1
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L8_2[1] = L9_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L2_2 = MrxFactionManager
  L2_2 = L2_2.SetCustomPursuit
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "VZ"
  L3_2 = L3_2(L4_2)
  L4_2 = -1
  L5_2 = L1_2
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.Boundary
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAnyCharacter
  L6_2 = L6_2()
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "Region_PMC001_EndPursuit"
  L7_2 = L7_2(L8_2)
  L8_2 = "enter"
  L9_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L6_2 = StopPursuit
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

JeepPursuit01 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxFactionManager
  L1_2 = L1_2.ClearCustomPursuit
  L1_2()
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona.PMC.Aaron01"
  L2_2[1] = L3_2
  L1_2(L2_2)
end

StopPursuit = L0_1

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
  L7_2 = "Region_PmcCon001_VillaWideRegion"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = GateCloser
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

SetupGateCloser = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L1_2 = {}
  L2_2 = "Pmc001_Door_Front"
  L3_2 = "PMC001_Garage_01"
  L4_2 = "PMC001_Garage_02"
  L5_2 = "PMC001_Garage_03"
  L6_2 = "PMC001_Rear_BottomDoor"
  L7_2 = "PMC001_Rear_TopDoor"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  
  function L2_2(A0_3)
    local L1_3, L2_3
    L1_3 = Object
    L1_3 = L1_3.CloseGate
    L2_3 = A0_3
    L1_3(L2_3)
  end
  
  L3_2 = pairs
  L4_2 = L1_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = Pg
    L8_2 = L8_2.GetGuidByName
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    L9_2 = Event
    L9_2 = L9_2.Create
    L10_2 = Event
    L10_2 = L10_2.ObjectHibernation
    L11_2 = {}
    L12_2 = L8_2
    L13_2 = "awake"
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L12_2 = L2_2
    L13_2 = {}
    L14_2 = L8_2
    L13_2[1] = L14_2
    L9_2(L10_2, L11_2, L12_2, L13_2)
  end
  L3_2 = Object
  L3_2 = L3_2.CloseGate
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "pmc_middle_gate"
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2 = L4_2(L5_2)
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
end

GateCloser = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Player
  L1_2 = L1_2.GetAnyCharacter
  L1_2 = L1_2()
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "PMC001: Go to the Villa"
  L4_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2.vTgtInclude = L1_2
  L4_2.vDestLoc = "loc_PMC1a"
  L4_2.vDestRegion = "reg_PMC001a"
  L4_2.bStop = false
  L4_2.bXZOnly = true
  L4_2.sDspShortDesc = "[PmcCon001.Objectives.001]"
  L5_2 = {}
  L6_2 = "Fiona-In-Mission-Contract-Pmc01-78"
  L7_2 = "Fiona-In-Mission-Contract-Pmc01-79"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2.vVoSeqOnAdd = L5_2
  L5_2 = {}
  L6_2 = {}
  L7_2 = KillSolanoEntourage01
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnComplete = L5_2
  L5_2 = {}
  L6_2 = {}
  L7_2 = A0_2.Cancel
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnCancel = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  oGotoVilla = L2_2
end

SetupGoToObjective = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L2_2 = A0_2
  L1_2 = A0_2._SetFlag
  L3_2 = "VillaReached"
  L1_2(L2_2, L3_2)
  L1_2 = _Checkpoint
  L2_2 = {}
  L3_2 = "Checkpoint_PMC001_VillaReached"
  L2_2[1] = L3_2
  L1_2(L2_2)
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "PMC001_HVT_01"
  L1_2 = L1_2(L2_2)
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "PMC001_HVT_02"
  L2_2 = L2_2(L3_2)
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "PMC001_HVT_03"
  L3_2 = L3_2(L4_2)
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "PMC001_HVT_04"
  L4_2 = L4_2(L5_2)
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "PMC001_HVT_05"
  L5_2 = L5_2(L6_2)
  L7_2 = A0_2
  L6_2 = A0_2.CreateChild
  L8_2 = {}
  L8_2.sName = "Kill Solano's Entourage!"
  L8_2.sModuleName = "MrxTaskObjectiveDestroy"
  L9_2 = {}
  L10_2 = L1_2
  L11_2 = L2_2
  L12_2 = L3_2
  L13_2 = L4_2
  L14_2 = L5_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L9_2[3] = L12_2
  L9_2[4] = L13_2
  L9_2[5] = L14_2
  L8_2.vTgtInclude = L9_2
  L8_2.bDspBlp = true
  L8_2.sDspShortDesc = "[PmcCon001.Objectives.002]"
  L9_2 = {}
  L10_2 = "Fiona-In-Mission-Contract-Pmc01-94"
  L11_2 = {}
  L11_2.mattias = "Mattias-In-Mission-Contract-Pmc01-97"
  L11_2.jennifer = "Jennifer-In-Mission-Contract-Pmc01-95"
  L11_2.chris = "Chris-In-Mission-Contract-Pmc01-96"
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L8_2.vVoSeqOnAdd = L9_2
  L9_2 = {}
  L10_2 = {}
  L11_2 = GoToVillaInteriorLayerLoad
  L12_2 = {}
  L13_2 = A0_2
  L12_2[1] = L13_2
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L9_2[1] = L10_2
  L8_2.tOnComplete = L9_2
  L9_2 = {}
  L10_2 = {}
  L11_2 = A0_2.Cancel
  L12_2 = {}
  L13_2 = A0_2
  L12_2[1] = L13_2
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L9_2[1] = L10_2
  L8_2.tOnCancel = L9_2
  L6_2 = L6_2(L7_2, L8_2)
  A0_2.curObj = L6_2
end

KillSolanoEntourage01 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = GoToVillaInterior
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = {}
  L2_2 = "vz_state_PmcCon001_InvestigateVilla"
  L1_2[1] = L2_2
  L2_2 = MrxLayerManager
  L2_2 = L2_2.Add
  L3_2 = L1_2
  L4_2 = {}
  L5_2 = A0_2
  L4_2[1] = L5_2
  L2_2(L3_2, L4_2)
end

GoToVillaInteriorLayerLoad = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L1_2 = {}
  L2_2 = "Pmc001_Door_Front"
  L3_2 = "PMC001_Rear_BottomDoor"
  L4_2 = "PMC001_Rear_TopDoor"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "PMC001_Door_Front"
  L2_2 = L2_2(L3_2)
  
  function L3_2(A0_3)
    local L1_3, L2_3
    L1_3 = Object
    L1_3 = L1_3.OpenGate
    L2_3 = A0_3
    L1_3(L2_3)
  end
  
  L4_2 = pairs
  L5_2 = L1_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = Pg
    L9_2 = L9_2.GetGuidByName
    L10_2 = L8_2
    L9_2 = L9_2(L10_2)
    L10_2 = Event
    L10_2 = L10_2.Create
    L11_2 = Event
    L11_2 = L11_2.ObjectHibernation
    L12_2 = {}
    L13_2 = L9_2
    L14_2 = "awake"
    L12_2[1] = L13_2
    L12_2[2] = L14_2
    L13_2 = L3_2
    L14_2 = {}
    L15_2 = L9_2
    L14_2[1] = L15_2
    L10_2(L11_2, L12_2, L13_2, L14_2)
  end
  L5_2 = A0_2
  L4_2 = A0_2._CreateEvent
  L6_2 = Event
  L6_2 = L6_2.ObjectHibernation
  L7_2 = {}
  L8_2 = Pg
  L8_2 = L8_2.GetGuidByName
  L9_2 = "Pmc001_Door_Front"
  L8_2 = L8_2(L9_2)
  L9_2 = "hibernated"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L8_2 = CheckFrontDoor
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
end

GateOpener = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "Pmc001_Door_Front"
  L5_2 = L5_2(L6_2)
  L6_2 = "awake"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = GateOpener
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

CheckFrontDoor = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = bMoveInvisibleCollision
  if not L0_2 then
    L0_2 = Object
    L0_2 = L0_2.GetPosition
    L1_2 = Pg
    L1_2 = L1_2.GetGuidByName
    L2_2 = "PMC001_FrontDoor_InvisiblePhysics"
    L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2 = L1_2(L2_2)
    L0_2, L1_2, L2_2 = L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
    L3_2 = Object
    L3_2 = L3_2.SetPosition
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "PMC001_FrontDoor_InvisiblePhysics"
    L4_2 = L4_2(L5_2)
    L5_2 = L0_2
    L6_2 = L1_2 - 30
    L7_2 = L2_2
    L3_2(L4_2, L5_2, L6_2, L7_2)
    L3_2 = Net
    L3_2 = L3_2.IsServer
    L3_2 = L3_2()
    if L3_2 then
      L3_2 = Net
      L3_2 = L3_2.SendCustomEvent
      L4_2 = "PmcCon001"
      L5_2 = NETEVENT_MOVECOLLISION
      L6_2 = {}
      L3_2(L4_2, L5_2, L6_2)
    end
    L3_2 = true
    bMoveInvisibleCollision = L3_2
  end
end

NetSafeMoveInvisibleCollision = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Player
  L1_2 = L1_2.GetAnyCharacter
  L1_2 = L1_2()
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "PMC001: Go to Villa Interior"
  L4_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2.vTgtInclude = L1_2
  L4_2.vDestLoc = "loc_PMC001_InvestigateVilla01"
  L4_2.vDestRegion = "Region_PMC001_InvestigateVilla01"
  L4_2.bStop = false
  L4_2.bXZOnly = true
  L4_2.sDspShortDesc = "[PmcCon001.Objectives.006]"
  L5_2 = {}
  L6_2 = {}
  L7_2 = "Fiona-In-Mission-Contract-Pmc01-11"
  L6_2[1] = L7_2
  L5_2[1] = L6_2
  L4_2.vVoSeqOnAdd = L5_2
  L5_2 = {}
  L6_2 = {}
  L7_2 = GoToVillaInterior02
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnComplete = L5_2
  L5_2 = {}
  L6_2 = {}
  L7_2 = A0_2.Cancel
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnCancel = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  oGotoVilla = L2_2
end

GoToVillaInterior = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Player
  L1_2 = L1_2.GetAnyCharacter
  L1_2 = L1_2()
  L3_2 = A0_2
  L2_2 = A0_2._SetFlag
  L4_2 = "HijackInitiated"
  L2_2(L3_2, L4_2)
  L2_2 = _Checkpoint
  L3_2 = {}
  L4_2 = "TankHijackCheckpoint"
  L3_2[1] = L4_2
  L2_2(L3_2)
  L2_2 = NetSafeMoveInvisibleCollision
  L2_2()
  L2_2 = GateOpener
  L3_2 = A0_2
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "PMC001: Investigate Villa Interior"
  L4_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2.vTgtInclude = L1_2
  L4_2.vDestLoc = "loc_PMC001_InvestigateVilla02"
  L4_2.vDestRegion = "Region_PMC001_VillaInterior"
  L4_2.bStop = false
  L4_2.bXZOnly = true
  L4_2.sDspShortDesc = "[PmcCon001.Objectives.007]"
  L5_2 = {}
  L6_2 = {}
  L7_2 = "Fiona-In-Mission-Contract-Pmc01-38"
  L6_2[1] = L7_2
  L5_2[1] = L6_2
  L4_2.vVoSeqOnAdd = L5_2
  L5_2 = {}
  L6_2 = {}
  L7_2 = ObjectInSightCheck
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnComplete = L5_2
  L5_2 = {}
  L6_2 = {}
  L7_2 = A0_2.Cancel
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnCancel = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  oGotoVilla = L2_2
end

GoToVillaInterior02 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectIsVisible
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "_pmcoutpost_column 0x000a74ec"
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = LoadTank
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

ObjectInSightCheck = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  
  function L1_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._CreateEvent
    L2_3 = Event
    L2_3 = L2_3.ObjectHibernation
    L3_3 = {}
    L4_3 = Pg
    L4_3 = L4_3.GetGuidByName
    L5_3 = "PMC001_EntourageScorpion"
    L4_3 = L4_3(L5_3)
    L5_3 = "awake"
    L3_3[1] = L4_3
    L3_3[2] = L5_3
    L4_3 = ActionHijackTank
    L5_3 = A0_2
    L4_3, L5_3 = L4_3(L5_3)
    L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
  end
  
  L2_2 = MrxLayerManager
  L2_2 = L2_2.Add
  L3_2 = "vz_state_PmcCon001_ActionHijackTutorial"
  L4_2 = L1_2
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = MrxVoSequence
  L2_2 = L2_2.Start
  L3_2 = "Fiona-In-Mission-Contract-Pmc01-102"
  L2_2(L3_2)
end

LoadTank = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Object
  L1_2 = L1_2.Kill
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "PMC001_GarageEntrance"
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = Ai
  L1_2 = L1_2.Goal
  L2_2 = {}
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "PMC001_EntourageScorpion"
  L4_2, L5_2 = L4_2(L5_2)
  L3_2 = L3_2(L4_2, L5_2)
  L2_2.AIGuid = L3_2
  L2_2.Goal = "PathMove"
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "Path_PMC001_GarageSmash"
  L3_2 = L3_2(L4_2)
  L2_2.Target = L3_2
  L2_2.Priority = "HiPri"
  L2_2.Haste = 1
  L1_2 = L1_2(L2_2)
  vGoal = L1_2
  L1_2 = Sound
  L1_2 = L1_2.CueSound
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "PMC001_EntourageScorpion"
  L2_2 = L2_2(L3_2)
  L3_2 = "exp_bust_thru_wall"
  L1_2(L2_2, L3_2)
end

GarageSmash = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = Vehicle
  L2_2 = L2_2.GetDriver
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = Object
    L3_2 = L3_2.IsPlayerControlled
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L4_2 = MrxAchievements
      L4_2 = L4_2.NetGrantAchievement
      L5_2 = "ACHIEVEMENT_RIDE_DRAGON"
      L6_2 = L3_2
      L4_2(L5_2, L6_2)
    end
  end
end

RideDragonAchievement = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "PMC001_EntourageScorpion"
  L1_2 = L1_2(L2_2)
  L2_2 = MrxTutorialManager
  L2_2 = L2_2.ShowMessage
  L3_2 = "[Tutorial.ActionHijack]"
  L2_2(L3_2)
  L2_2 = Object
  L2_2 = L2_2.IsAlive
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "PMC001_EntourageScorpion"
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  if L2_2 then
    L2_2 = GarageSmash
    L3_2 = A0_2
    L2_2(L3_2)
    L2_2 = Vehicle
    L2_2 = L2_2.Usable
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = "PMC001_EntourageScorpion"
    L3_2 = L3_2(L4_2)
    L4_2 = false
    L2_2(L3_2, L4_2)
    L3_2 = A0_2
    L2_2 = A0_2.CreateChild
    L4_2 = {}
    L4_2.sName = "Hijack the Tank"
    L4_2.sModuleName = "MrxTaskObjectiveEnterVehicle"
    L4_2.sActionLabel = "Hijack"
    L5_2 = Pg
    L5_2 = L5_2.GetGuidByName
    L6_2 = "PMC001_EntourageScorpion"
    L5_2 = L5_2(L6_2)
    L4_2.vTgtInclude = L5_2
    L4_2.sDspShortDesc = "[PmcCon001.Objectives.004]"
    L5_2 = {}
    L6_2 = {}
    L6_2.mattias = "Mattias-In-Mission-Contract-Pmc01-101"
    L6_2.jennifer = "Jennifer-In-Mission-Contract-Pmc01-99"
    L6_2.chris = "Chris-In-Mission-Contract-Pmc01-100"
    L7_2 = "Fiona-In-Mission-Contract-Pmc01-102"
    L8_2 = {}
    L8_2.mattias = "Mattias-In-Mission-Contract-Pmc01-107"
    L8_2.jennifer = "Jennifer-In-Mission-Contract-Pmc01-108"
    L8_2.chris = "Chris-In-Mission-Contract-Pmc01-109"
    L9_2 = "Fiona.vo.fio.vp1fio07"
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L5_2[4] = L9_2
    L4_2.vVoSeqOnAdd = L5_2
    
    function L5_2()
      local L0_3, L1_3, L2_3
      L0_3 = RideDragonAchievement
      L1_3 = A0_2
      L2_3 = L1_2
      L0_3(L1_3, L2_3)
      L0_3 = KillSolanoEntourage02Load
      L1_3 = A0_2
      L0_3(L1_3)
      L0_3 = MrxTutorialManager
      L0_3 = L0_3.HideMessage
      L0_3()
    end
    
    L4_2.fOnComplete = L5_2
    L6_2 = A0_2
    L5_2 = A0_2._CreateEvent
    L7_2 = Event
    L7_2 = L7_2.ObjectInSeat
    L8_2 = {}
    L9_2 = Player
    L9_2 = L9_2.GetAnyCharacter
    L9_2 = L9_2()
    L10_2 = Pg
    L10_2 = L10_2.GetGuidByName
    L11_2 = "PMC001_EntourageScorpion"
    L10_2 = L10_2(L11_2)
    L11_2 = "D"
    L12_2 = "E"
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L8_2[4] = L12_2
    
    function L9_2()
      local L0_3, L1_3
      L0_3 = oHijackTank
      L1_3 = L0_3
      L0_3 = L0_3.Complete
      L0_3(L1_3)
    end
    
    L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L4_2[3] = L7_2
    L4_2[4] = L8_2
    L4_2[5] = L9_2
    L4_2[6] = L10_2
    L4_2[7] = L11_2
    L4_2[8] = L12_2
    L2_2 = L2_2(L3_2, L4_2)
    oHijackTank = L2_2
  else
    L2_2 = KillSolanoEntourage02Load
    L3_2 = A0_2
    L2_2(L3_2)
  end
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectDeath
  L5_2 = {}
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "PMC001_EntourageScorpion"
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L6_2(L7_2)
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L5_2[7] = L12_2
  
  function L6_2()
    local L0_3, L1_3
    L0_3 = oHijackTank
    L1_3 = L0_3
    L0_3 = L0_3.Complete
    L0_3(L1_3)
  end
  
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  oTankDestroyed = L2_2
end

ActionHijackTank = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Pmc01-48"
  L4_2 = 1
  L5_2 = {}
  L5_2.mattias = "Mattias-In-Mission-Contract-Pmc01-51"
  L5_2.jennifer = "Jennifer-In-Mission-Contract-Pmc01-52"
  L5_2.chris = "Chris-In-Mission-Contract-Pmc01-53"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L1_2(L2_2)
  L1_2 = {}
  L2_2 = "vz_State_PMC001_VillaWaveOne"
  L1_2[1] = L2_2
  L2_2 = MrxLayerManager
  L2_2 = L2_2.Add
  L3_2 = L1_2
  L4_2 = KillSolanoEntourage02
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = {}
  L3_2 = "vz_State_PMC001_VillaWaveOne"
  L2_2[1] = L3_2
end

KillSolanoEntourage02Load = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = Wave01
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Kill Solano's Entourage!"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L3_2.sTgtLabelFilter = "VZ"
  L3_2.nQuota = 10
  L3_2.bDspBlp = true
  L3_2.sDspShortDesc = "[PmcCon001.Objectives.005]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.RunAndFleeInTerror
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
  L1_2 = L1_2(L2_2, L3_2)
  A0_2.curObj = L1_2
end

KillSolanoEntourage02 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Pmc01-12"
  L4_2 = 1
  L5_2 = {}
  L6_2 = A0_2.Complete
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

Pmc01FionaVOComplete = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = {}
  L2_2 = utop02
  L3_2 = utop03
  L4_2 = utop04
  L5_2 = ubottom01
  L6_2 = ubottom02
  L7_2 = ugarage02
  L8_2 = uw2_top01
  L9_2 = uw2_top03
  L10_2 = uw2_bottom01
  L11_2 = uw2_bottom03
  L12_2 = uw2_bottom04
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L1_2[7] = L8_2
  L1_2[8] = L9_2
  L1_2[9] = L10_2
  L1_2[10] = L11_2
  L1_2[11] = L12_2
  tBothWaves = L1_2
  L1_2 = pairs
  L2_2 = tBothWaves
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    if L5_2 then
      L6_2 = Ai
      L6_2 = L6_2.Goal
      L7_2 = {}
      L7_2.AIGuid = L5_2
      L7_2.Goal = "MoveTo"
      L8_2 = Pg
      L8_2 = L8_2.GetGuidByName
      L9_2 = "loc_EntourageFleePoint"
      L8_2 = L8_2(L9_2)
      L7_2.Target = L8_2
      L7_2.Haste = 1
      L7_2.Priority = "HiPri"
      L6_2(L7_2)
    end
  end
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Pmc01-12"
  L4_2 = 1
  L5_2 = {}
  L6_2 = A0_2.Complete
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

RunAndFleeInTerror = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "top02"
  L1_2 = L1_2(L2_2)
  utop02 = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "top03"
  L1_2 = L1_2(L2_2)
  utop03 = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "top04"
  L1_2 = L1_2(L2_2)
  utop04 = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "bottom01"
  L1_2 = L1_2(L2_2)
  ubottom01 = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "bottom02"
  L1_2 = L1_2(L2_2)
  ubottom02 = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "garage02"
  L1_2 = L1_2(L2_2)
  ugarage02 = L1_2
  L1_2 = utop02
  if L1_2 then
    L1_2 = Ai
    L1_2 = L1_2.Goal
    L2_2 = {}
    L3_2 = utop02
    L2_2.AIGuid = L3_2
    L2_2.Goal = "PathMove"
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = "Path_top02"
    L3_2 = L3_2(L4_2)
    L2_2.Target = L3_2
    L2_2.Priority = "hiPri"
    L2_2.Haste = 1
    L1_2(L2_2)
  else
  end
  L1_2 = utop03
  if L1_2 then
    L1_2 = Ai
    L1_2 = L1_2.Goal
    L2_2 = {}
    L3_2 = utop03
    L2_2.AIGuid = L3_2
    L2_2.Goal = "PathMove"
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = "Path_top03"
    L3_2 = L3_2(L4_2)
    L2_2.Target = L3_2
    L2_2.Priority = "hiPri"
    L2_2.Haste = 1
    L1_2(L2_2)
  else
  end
  L1_2 = utop04
  if L1_2 then
    L1_2 = Ai
    L1_2 = L1_2.Goal
    L2_2 = {}
    L3_2 = utop04
    L2_2.AIGuid = L3_2
    L2_2.Goal = "PathMove"
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = "Path_top04"
    L3_2 = L3_2(L4_2)
    L2_2.Target = L3_2
    L2_2.Priority = "hiPri"
    L2_2.Haste = 1
    L1_2(L2_2)
  else
  end
  L1_2 = ubottom01
  if L1_2 then
    L1_2 = Ai
    L1_2 = L1_2.Goal
    L2_2 = {}
    L3_2 = ubottom01
    L2_2.AIGuid = L3_2
    L2_2.Goal = "PathMove"
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = "Path_Bottom01"
    L3_2 = L3_2(L4_2)
    L2_2.Target = L3_2
    L2_2.Priority = "hiPri"
    L2_2.Haste = 1
    L1_2(L2_2)
  else
  end
  L1_2 = ubottom02
  if L1_2 then
    L1_2 = Ai
    L1_2 = L1_2.Goal
    L2_2 = {}
    L3_2 = ubottom02
    L2_2.AIGuid = L3_2
    L2_2.Goal = "PathMove"
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = "Path_PMC001_WaveTwo_BottomLeft"
    L3_2 = L3_2(L4_2)
    L2_2.Target = L3_2
    L2_2.Priority = "hiPri"
    L2_2.Haste = 1
    L1_2(L2_2)
  else
  end
  L1_2 = ugarage02
  if L1_2 then
    L1_2 = Ai
    L1_2 = L1_2.Goal
    L2_2 = {}
    L3_2 = ugarage02
    L2_2.AIGuid = L3_2
    L2_2.Goal = "PathMove"
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = "Path_PMC001_GarageSmash"
    L3_2 = L3_2(L4_2)
    L2_2.Target = L3_2
    L2_2.Priority = "hiPri"
    L2_2.Haste = 1
    L1_2(L2_2)
  else
  end
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 15
  L4_2[1] = L5_2
  L5_2 = SetUpWave02
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

Wave01 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = {}
  L2_2 = "vz_state_Pmc001_VillaWaveTwo"
  L1_2[1] = L2_2
  L2_2 = MrxLayerManager
  L2_2 = L2_2.Add
  L3_2 = L1_2
  L4_2 = Wave02
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L2_2(L3_2, L4_2, L5_2)
end

SetUpWave02 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "w2_top01"
  L1_2 = L1_2(L2_2)
  uw2_top01 = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "w2_top02"
  L1_2 = L1_2(L2_2)
  uw2_top02 = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "w2_top03"
  L1_2 = L1_2(L2_2)
  uw2_top03 = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "w2_top04"
  L1_2 = L1_2(L2_2)
  uw2_top04 = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "w2_bottom01"
  L1_2 = L1_2(L2_2)
  uw2_bottom01 = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "w2_bottom02"
  L1_2 = L1_2(L2_2)
  uw2_bottom02 = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "w2_bottom03"
  L1_2 = L1_2(L2_2)
  uw2_bottom03 = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "w2_bottom04"
  L1_2 = L1_2(L2_2)
  uw2_bottom04 = L1_2
  L1_2 = uw2_top01
  if L1_2 then
    L1_2 = Ai
    L1_2 = L1_2.Goal
    L2_2 = {}
    L3_2 = uw2_top01
    L2_2.AIGuid = L3_2
    L2_2.Goal = "PathMove"
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = "Path_PMC001_WaveTwo_TopRight"
    L3_2 = L3_2(L4_2)
    L2_2.Target = L3_2
    L2_2.Priority = "hiPri"
    L2_2.Haste = 1
    L1_2(L2_2)
  else
  end
  L1_2 = uw2_top03
  if L1_2 then
    L1_2 = Ai
    L1_2 = L1_2.Goal
    L2_2 = {}
    L3_2 = uw2_top03
    L2_2.AIGuid = L3_2
    L2_2.Goal = "PathMove"
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = "Path_PMC001_WaveTwo_TopLeft"
    L3_2 = L3_2(L4_2)
    L2_2.Target = L3_2
    L2_2.Priority = "hiPri"
    L2_2.Haste = 1
    L1_2(L2_2)
  else
  end
  L1_2 = uw2_bottom01
  if L1_2 then
    L1_2 = Ai
    L1_2 = L1_2.Goal
    L2_2 = {}
    L3_2 = uw2_bottom01
    L2_2.AIGuid = L3_2
    L2_2.Goal = "PathMove"
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = "Path_PMC001_WaveTwo_BottomLeft"
    L3_2 = L3_2(L4_2)
    L2_2.Target = L3_2
    L2_2.Priority = "hiPri"
    L2_2.Haste = 1
    L1_2(L2_2)
  else
  end
  L1_2 = uw2_bottom03
  if L1_2 then
    L1_2 = Ai
    L1_2 = L1_2.Goal
    L2_2 = {}
    L3_2 = uw2_bottom03
    L2_2.AIGuid = L3_2
    L2_2.Goal = "PathMove"
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = "Path_Bottom01"
    L3_2 = L3_2(L4_2)
    L2_2.Target = L3_2
    L2_2.Priority = "hiPri"
    L2_2.Haste = 1
    L1_2(L2_2)
  else
  end
  L1_2 = uw2_bottom04
  if L1_2 then
    L1_2 = Ai
    L1_2 = L1_2.Goal
    L2_2 = {}
    L3_2 = uw2_bottom04
    L2_2.AIGuid = L3_2
    L2_2.Goal = "PathMove"
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = "Path_Bottom01"
    L3_2 = L3_2(L4_2)
    L2_2.Target = L3_2
    L2_2.Priority = "hiPri"
    L2_2.Haste = 1
    L1_2(L2_2)
  else
  end
end

Wave02 = L0_1

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
  L7_2 = "Region_PMC_FrontGate"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._CreateEvent
    L2_3 = Event
    L2_3 = L2_3.TimerRelative
    L3_3 = {}
    L4_3 = 2
    L3_3[1] = L4_3
    L4_3 = CourtyardPanic
    L5_3 = {}
    L6_3 = A0_2
    L5_3[1] = L6_3
    L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

SetupCourtyardPanic = L0_1

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
  L7_2 = "Region_PMC001_Banter01"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = Banter
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

SetUpBanterRegion = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Pmc01-83"
  L4_2 = {}
  L4_2.mattias = "Mattias-In-Mission-Contract-Pmc01-86"
  L4_2.jennifer = "Jennifer-In-Mission-Contract-Pmc01-84"
  L4_2.chris = "Chris-In-Mission-Contract-Pmc01-85"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
end

Banter = L0_1

function L0_1(A0_2)
  local L1_2
end

PmcInvulnerable = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
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
    L8_2 = Human
    L8_2 = L8_2.ForceExitSeatNoSnap
    L9_2 = L7_2
    L8_2(L9_2)
  end
  L2_2 = pairs
  L3_2 = tPmcDoors
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = Pg
    L7_2 = L7_2.GetGuidByName
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    L8_2 = Hud
    L8_2 = L8_2.Radar
    L9_2 = L8_2
    L8_2 = L8_2.RemoveObjective
    L10_2 = {}
    L11_2 = L7_2
    L10_2[1] = L11_2
    L8_2(L9_2, L10_2)
  end
  L2_2 = {}
  L3_2 = "Vz_State_PmcCon001"
  L4_2 = "VZ_State_Pmc_Pristine"
  L5_2 = "vz_state_PmcCon001_ActionHijackTutorial"
  L6_2 = "vz_state_PmcCon001_InvestigateVilla"
  L7_2 = "vz_state_pmccon001_VillaSoldiers"
  L8_2 = "vz_state_Pmc001_VillaWaveOne"
  L9_2 = "vz_state_Pmc001_VillaWaveTwo"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L2_2[6] = L8_2
  L2_2[7] = L9_2
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = MrxLayerManager
    L8_2 = L8_2.MarkForRemoval
    L9_2 = L7_2
    L8_2(L9_2)
  end
  L3_2 = Ai
  L3_2 = L3_2.SetRelation
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "VZ"
  L4_2 = L4_2(L5_2)
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "PMC"
  L5_2 = L5_2(L6_2)
  L6_2 = -100
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = MrxFactionManager
  L3_2 = L3_2.DisableReporting
  L4_2 = false
  L3_2(L4_2)
  L3_2 = MrxFactionManager
  L3_2 = L3_2.ClearPursuitLock
  L3_2()
  L3_2 = Graphics
  L3_2 = L3_2.Atmosphere
  L3_2 = L3_2.ChangeLineRegionSetting
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "rgn_atmo_PMCinterior"
  L4_2 = L4_2(L5_2)
  L5_2 = "default"
  L3_2(L4_2, L5_2)
  L3_2 = MrxTaskContract
  L3_2 = L3_2.Cleanup
  L4_2 = A0_2
  L3_2(L4_2)
end

Cleanup = L0_1
