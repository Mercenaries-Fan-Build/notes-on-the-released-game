local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTaskObjectiveDeliver"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxLayerManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTimer"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxAchievements"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxMusic"
L0_1(L1_1)
L0_1 = {}
L1_1 = "Target1"
L2_1 = "Target2"
L3_1 = "Target3"
L4_1 = "Target4"
L5_1 = "Target5"
L6_1 = "Target6"
L7_1 = "Target7"
L8_1 = "Target8"
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1
L0_1[5] = L5_1
L0_1[6] = L6_1
L0_1[7] = L7_1
L0_1[8] = L8_1
tDestroyLocs = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = MrxMusic
  L1_2 = L1_2.PlaySpecialMusic
  L2_2 = "mu_mission_chicon009_01"
  L1_2(L2_2)
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Remove
  L2_2 = {}
  L3_2 = "vz_state_cumana_act1ALL_S"
  L2_2[1] = L3_2
  L1_2(L2_2)
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "ChiCon009_ZBD2000"
  L1_2 = L1_2(L2_2)
  L2_2 = Vehicle
  L2_2 = L2_2.Usable
  L3_2 = L1_2
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = 600
  L3_2 = 30
  L5_2 = A0_2
  L4_2 = A0_2.GetNumCompletions
  L4_2 = L4_2(L5_2)
  if L4_2 == 1 then
    L2_2 = 500
    L3_2 = 20
  elseif 2 <= L4_2 then
    L2_2 = 400
    L3_2 = 15
  end
  L5_2 = MrxTimer
  L6_2 = L5_2
  L5_2 = L5_2.Create
  L7_2 = {}
  L7_2.nStartTime = L2_2
  L8_2 = L2_2 / 2
  L7_2.nWarning = L8_2
  L7_2.iTray = 2
  L8_2 = {}
  L9_2 = {}
  L10_2 = OutOfTime
  L11_2 = {}
  L12_2 = A0_2
  L11_2[1] = L12_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L8_2[1] = L9_2
  L7_2.tDoneCallbacks = L8_2
  L5_2 = L5_2(L6_2, L7_2)
  oTimer = L5_2
  L5_2 = oTimer
  L6_2 = L5_2
  L5_2 = L5_2.Start
  L5_2(L6_2)
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = {}
  L7_2 = "Fiona-In-Mission-Contract-Chi09-01"
  L8_2 = 3
  L9_2 = "Fiona-In-Mission-Contract-Chi09-05"
  L10_2 = 3
  L11_2 = "Fiona-In-Mission-Contract-Chi09-18"
  L12_2 = 3
  L13_2 = "Fiona-In-Mission-Contract-Chi09-19"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L6_2[5] = L11_2
  L6_2[6] = L12_2
  L6_2[7] = L13_2
  L5_2(L6_2)
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "ChiCon009_ZBD2000"
  L5_2 = L5_2(L6_2)
  L6_2 = Vehicle
  L6_2 = L6_2.Usable
  L7_2 = L5_2
  L8_2 = false
  L6_2(L7_2, L8_2)
  L7_2 = A0_2
  L6_2 = A0_2.CreateChild
  L8_2 = {}
  L8_2.sName = "Acquire the ZBD2000"
  L8_2.sModuleName = "MrxTaskObjectiveEnterVehicle"
  L8_2.vTgtInclude = "ChiCon009_ZBD2000"
  L8_2.nQuota = 1
  L9_2 = Player
  L9_2 = L9_2.GetAnyCharacter
  L9_2 = L9_2()
  L8_2.uPlayer = L9_2
  L8_2.sDspShortDesc = "[ChiCon009.Objectives.004]"
  L9_2 = {}
  L10_2 = {}
  L11_2 = RendezvousAmbulance
  L12_2 = {}
  L13_2 = A0_2
  L12_2[1] = L13_2
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L9_2[1] = L10_2
  L8_2.tOnComplete = L9_2
  L9_2 = {}
  L10_2 = {}
  L11_2 = A0_2.VehicleUnentered
  L12_2 = {}
  L13_2 = A0_2
  L12_2[1] = L13_2
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L9_2[1] = L10_2
  L8_2.tOnCancel = L9_2
  L6_2 = L6_2(L7_2, L8_2)
  L8_2 = A0_2
  L7_2 = A0_2._CreateEvent
  L9_2 = Event
  L9_2 = L9_2.ObjectInSeat
  L10_2 = {}
  L11_2 = Player
  L11_2 = L11_2.GetAnyCharacter
  L11_2 = L11_2()
  L12_2 = Pg
  L12_2 = L12_2.GetGuidByName
  L13_2 = "ChiCon009_ZBD2000"
  L12_2 = L12_2(L13_2)
  L13_2 = "D"
  L14_2 = "E"
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L11_2 = L6_2.Complete
  L12_2 = {}
  L13_2 = L6_2
  L12_2[1] = L13_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L7_2 = FionaChiCon009Vo
  L8_2 = A0_2
  L7_2(L8_2)
  L7_2 = AmbulanceSetup
  L8_2 = A0_2
  L7_2(L8_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "RendezvousAmbulance"
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2 = Player
  L4_2 = L4_2.GetAnyCharacter
  L4_2 = L4_2()
  L3_2.vTgtInclude = L4_2
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "loc_AmbulanceRendezvous"
  L4_2 = L4_2(L5_2)
  L3_2.vDestLoc = L4_2
  L3_2.sDspShortDesc = "[ChiCon009.Objectives.005]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = AmbulanceObjective
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.MineActive
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnCancel = L4_2
  L1_2(L2_2, L3_2)
end

RendezvousAmbulance = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 10
  L4_2[1] = L5_2
  L5_2 = AmbulanceSetup
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

AmbulanceTemp = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "loc_SpawnAmbulance"
  L1_2 = L1_2(L2_2)
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L5_2 = Pg
  L5_2 = L5_2.Spawn
  L6_2 = "Ambulance (Driver)"
  L7_2 = L2_2
  L8_2 = L3_2
  L9_2 = L4_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  civAmbulance = L5_2
end

AmbulanceSetup = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L1_2 = MrxUtil
  L1_2 = L1_2.DisplayHealthBar
  L2_2 = A0_2
  L3_2 = civAmbulance
  L4_2 = 0
  L5_2 = true
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Escort the Ambulance"
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2 = civAmbulance
  L3_2.vTgtInclude = L4_2
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "loc_AmbulanceDropoff"
  L4_2 = L4_2(L5_2)
  L3_2.vDestLoc = L4_2
  L3_2.sDspBlpRdrIcon = "objective_defend"
  L3_2.sDspShortDesc = "[ChiCon009.Objectives.003]"
  
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-Pmc01-10"
    L3_3 = 3
    L4_3 = {}
    L5_3 = A0_2
    L5_3 = L5_3.Complete
    L6_3 = {}
    L7_3 = A0_2
    L6_3[1] = L7_3
    L4_3[1] = L5_3
    L4_3[2] = L6_3
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L1_3[3] = L4_3
    L0_3(L1_3)
  end
  
  L3_2.fOnComplete = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.AmbulanceDestroyed
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnCancel = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "Special Case: Ambulance Destination Blip"
  L4_2.sModuleName = "MrxTaskObjective"
  L4_2.sDspShortDesc = "[ChiCon009.Objectives.006]"
  L4_2.bTrackOnActivate = true
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "loc_AmbulanceDropoff"
  L5_2 = L5_2(L6_2)
  L4_2.vTgtInclude = L5_2
  
  function L5_2()
    local L0_3, L1_3
  end
  
  L4_2.fOnComplete = L5_2
  
  function L5_2()
    local L0_3, L1_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.OutOfTime
    L0_3(L1_3)
  end
  
  L4_2.fOnCancel = L5_2
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = civAmbulance
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "loc_AmbulanceDropoff"
  L7_2 = L7_2(L8_2)
  L8_2 = "<"
  L9_2 = 10
  L10_2 = false
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = A0_2.Complete
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectDeath
  L5_2 = {}
  L6_2 = civAmbulance
  L5_2[1] = L6_2
  L6_2 = L1_2.Cancel
  L7_2 = {}
  L8_2 = L1_2
  L7_2[1] = L8_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  A0_2.eDeath = L2_2
  L3_2 = A0_2
  L2_2 = A0_2.GetNumCompletions
  L2_2 = L2_2(L3_2)
  L3_2 = 0.1
  if L2_2 == 1 then
    L3_2 = 0.2
  elseif 2 <= L2_2 then
    L3_2 = 0.25
  end
  L4_2 = Ai
  L4_2 = L4_2.Goal
  L5_2 = {}
  L6_2 = Vehicle
  L6_2 = L6_2.GetDriver
  L7_2 = civAmbulance
  L6_2 = L6_2(L7_2)
  L5_2.AIGuid = L6_2
  L5_2.Goal = "PathMove"
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Path_Ambulance"
  L6_2 = L6_2(L7_2)
  L5_2.Target = L6_2
  L5_2.Priority = "lowPri"
  L5_2.Timeout = 0
  L5_2.Mode = "Oneway"
  L5_2.Start = "Nearest"
  L5_2.Haste = 0.1
  L6_2 = {}
  L7_2 = {}
  L8_2 = L1_2.Complete
  L9_2 = {}
  L10_2 = L1_2
  L9_2[1] = L10_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L6_2[1] = L7_2
  L5_2.CallbackData = L6_2
  L4_2(L5_2)
  L4_2 = MrxVoSequence
  L4_2 = L4_2.Start
  L5_2 = {}
  L6_2 = "Fiona-In-Mission-Contract-Chi09-08"
  L7_2 = 3
  L8_2 = {}
  L9_2 = A0_2.PlayAmbulanceMusic
  L10_2 = {}
  L11_2 = A0_2
  L10_2[1] = L11_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L4_2(L5_2)
  L4_2 = Object
  L4_2 = L4_2.GetHibernationDistance
  L5_2 = civAmbulance
  L4_2 = L4_2(L5_2)
  L6_2 = A0_2
  L5_2 = A0_2._CreateEvent
  L7_2 = Event
  L7_2 = L7_2.ObjectProximity
  L8_2 = {}
  L9_2 = Player
  L9_2 = L9_2.GetAnyCharacter
  L9_2 = L9_2()
  L10_2 = civAmbulance
  L11_2 = ">"
  L12_2 = L4_2 - 25
  L13_2 = false
  L14_2 = false
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  L8_2[5] = L13_2
  L8_2[6] = L14_2
  
  function L9_2()
    local L0_3, L1_3, L2_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-Chi09-20"
    L1_3[1] = L2_3
    L0_3(L1_3)
  end
  
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = A0_2
  L5_2 = A0_2._CreateEvent
  L7_2 = Event
  L7_2 = L7_2.ObjectHibernation
  L8_2 = {}
  L9_2 = civAmbulance
  L10_2 = "hibernated"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  
  function L9_2()
    local L0_3, L1_3, L2_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-Chi09-20"
    L1_3[1] = L2_3
    L0_3(L1_3)
    L0_3 = AmbulanceAbandoned
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L5_2(L6_2, L7_2, L8_2, L9_2)
end

AmbulanceObjective = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxMusic
  L1_2 = L1_2.PlaySpecialMusic
  L2_2 = "mu_fac_oc_kickass_01"
  L1_2(L2_2)
end

PlayAmbulanceMusic = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Target4"
  L6_2 = L6_2(L7_2)
  L7_2 = "<"
  L8_2 = 60
  L9_2 = false
  L10_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-Chi09-14"
    L3_3 = 5
    L4_3 = {}
    L4_3.mattias = "Mattias-In-Mission-Contract-Chi09-15"
    L4_3.jennifer = "Jennifer-In-Mission-Contract-Chi09-16"
    L4_3.chris = "Chris-In-Mission-Contract-Chi09-17"
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L1_3[3] = L4_3
    L0_3(L1_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Target1"
  L6_2 = L6_2(L7_2)
  L7_2 = "<"
  L8_2 = 75
  L9_2 = false
  L10_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-Chi09-02"
    L1_3[1] = L2_3
    L0_3(L1_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

FionaChiCon009Vo = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[ChiCon009.Terms.Cancel05]"
  L1_2(L2_2, L3_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Chi09-09"
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

VehicleDeath = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[ChiCon009.Terms.Cancel01]"
  L1_2(L2_2, L3_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Chi09-10"
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

VehicleUnentered = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[ChiCon009.Terms.Cancel02]"
  L1_2(L2_2, L3_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Chi09-12"
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

MineActive = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[ChiCon009.Terms.Cancel04]"
  L1_2(L2_2, L3_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-All04-14"
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

OutOfTime = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[ChiCon009.Terms.Cancel03]"
  L1_2(L2_2, L3_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-All04-14"
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

AmbulanceDestroyed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[ChiCon009.Terms.Cancel06]"
  L1_2(L2_2, L3_2)
  L1_2 = A0_2.Cancel
  L2_2 = A0_2
  L1_2(L2_2)
end

AmbulanceAbandoned = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Add
  L2_2 = {}
  L3_2 = "vz_state_cumana_act1ALL_S"
  L2_2[1] = L3_2
  L1_2(L2_2)
  L1_2 = oTimer
  if L1_2 then
    L1_2 = oTimer
    L2_2 = L1_2
    L1_2 = L1_2.Stop
    L1_2(L2_2)
  end
  L1_2 = Object
  L1_2 = L1_2.IsValid
  L2_2 = civAmbulance
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = MrxUtil
    L1_2 = L1_2.StopHealthBar
    L2_2 = civAmbulance
    L1_2(L2_2)
    L1_2 = Object
    L1_2 = L1_2.Remove
    L2_2 = civAmbulance
    L1_2(L2_2)
  end
  L1_2 = MrxMusic
  L1_2 = L1_2.StopSpecialMusic
  L1_2()
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
