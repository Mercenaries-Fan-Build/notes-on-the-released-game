local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxApcDrop"
L0_1(L1_1)
L0_1 = import
L1_1 = "DangerousBuilding"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTimer"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxMusic"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiInterface"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPlayState"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = {}
  L3_2 = "vz_state_gua_upperclass_pristine"
  L4_2 = "Vz_State_MecJob"
  L5_2 = "VZ_State_MecCon001"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L3_2 = MrxLayerManager
  L3_2 = L3_2.Add
  L4_2 = L2_2
  L5_2 = A0_2._SetupVehicles1
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L3_2(L4_2, L5_2, L6_2)
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Net
  L1_2 = L1_2.DoneReloadingLayers
  if L1_2 then
    L1_2 = Net
    L1_2 = L1_2.DoneReloadingLayers
    L1_2()
  end
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "race_cp"
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 ~= nil then
    L2_2 = A0_2
    L1_2 = A0_2._GetFlag
    L3_2 = "race_cp"
    L1_2 = L1_2(L2_2, L3_2)
    L1_2 = L1_2 + 1
    giAttempts = L1_2
    L1_2 = MrxUtil
    L1_2 = L1_2.SpawnObject
    L2_2 = "Monster Truck"
    L3_2 = "mc001.car.respawn"
    L1_2 = L1_2(L2_2, L3_2)
    A0_2.uCar = L1_2
    L1_2 = Player
    L1_2 = L1_2.GetCurrentPlayers
    L1_2 = L1_2()
    if 1 < L1_2 then
      L1_2 = MrxUtil
      L1_2 = L1_2.SpawnObject
      L2_2 = "Offroad Motorcycle (GR)"
      L3_2 = "mc001.bike.respawn"
      L1_2 = L1_2(L2_2, L3_2)
      A0_2.uBike = L1_2
    end
    L1_2 = Object
    L1_2 = L1_2.IsHibernated
    L2_2 = A0_2.uCar
    L1_2 = L1_2(L2_2)
    if L1_2 then
      L2_2 = A0_2
      L1_2 = A0_2._CreateEvent
      L3_2 = Event
      L3_2 = L3_2.ObjectHibernation
      L4_2 = {}
      L5_2 = A0_2.uCar
      L6_2 = "awake"
      L4_2[1] = L5_2
      L4_2[2] = L6_2
      L5_2 = _SetupVehicles2
      L6_2 = {}
      L7_2 = A0_2
      L6_2[1] = L7_2
      L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
    else
      L2_2 = A0_2
      L1_2 = A0_2._SetupVehicles2
      L1_2(L2_2)
    end
  else
    L1_2 = 1
    giAttempts = L1_2
    L1_2 = MrxUtil
    L1_2 = L1_2.SpawnObject
    L2_2 = "Monster Truck"
    L3_2 = "meccon_monster"
    L1_2 = L1_2(L2_2, L3_2)
    A0_2.uCar = L1_2
    L1_2 = Player
    L1_2 = L1_2.GetCurrentPlayers
    L1_2 = L1_2()
    if 1 < L1_2 then
      L1_2 = MrxUtil
      L1_2 = L1_2.SpawnObject
      L2_2 = "Offroad Motorcycle (GR)"
      L3_2 = "mc001.bike.spawn"
      L1_2(L2_2, L3_2)
    end
    L2_2 = A0_2
    L1_2 = A0_2.AssetsLoaded
    L1_2(L2_2)
  end
end

_SetupVehicles1 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Player
  L1_2 = L1_2.IsCoopMultiplayer
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = nil
    L2_2 = nil
    L4_2 = A0_2
    L3_2 = A0_2._GetFlag
    L5_2 = "race_P2"
    L3_2 = L3_2(L4_2, L5_2)
    if L3_2 then
      L1_2 = A0_2.uBike
      L2_2 = A0_2.uCar
    else
      L1_2 = A0_2.uCar
      L2_2 = A0_2.uBike
    end
    L3_2 = Vehicle
    L3_2 = L3_2.Enter
    L4_2 = L1_2
    L5_2 = Player
    L5_2 = L5_2.GetPrimaryCharacter
    L5_2 = L5_2()
    L6_2 = "d"
    L7_2 = true
    L8_2 = false
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
    L3_2 = Net
    L3_2 = L3_2.SendCustomEvent
    L4_2 = "MecCon001"
    L5_2 = NETEVENT_ENTERVEHICLE
    L6_2 = {}
    L7_2 = L2_2
    L6_2[1] = L7_2
    L7_2 = true
    L3_2(L4_2, L5_2, L6_2, L7_2)
    L3_2 = A0_2._tEvents
    L4_2 = Event
    L4_2 = L4_2.Create
    L5_2 = Event
    L5_2 = L5_2.ScriptEvent
    L6_2 = {}
    L7_2 = "mpPlayerLeft"
    
    function L8_2(A0_3)
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
    
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L7_2 = _MyOnPlayerLeft
    L8_2 = {}
    L9_2 = A0_2
    L8_2[1] = L9_2
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
    L3_2.eMPwait = L4_2
  else
    L1_2 = Vehicle
    L1_2 = L1_2.Enter
    L2_2 = A0_2.uCar
    L3_2 = Player
    L3_2 = L3_2.GetPrimaryCharacter
    L3_2 = L3_2()
    L4_2 = "d"
    L5_2 = true
    L1_2(L2_2, L3_2, L4_2, L5_2)
  end
  L1_2 = A0_2._tEvents
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ObjectInSeat
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = A0_2.uCar
  L7_2 = "d"
  L8_2 = "e"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = AssetsLoaded
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.eVehicleSetup = L2_2
end

_SetupVehicles2 = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2._tEvents
  L2_2 = L2_2.eVehicleSetup
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2._GetFlag
    L4_2 = "race_P2"
    L2_2 = L2_2(L3_2, L4_2)
    if L2_2 then
      L2_2 = Event
      L2_2 = L2_2.Delete
      L3_2 = A0_2._tEvents
      L3_2 = L3_2.eVehicleSetup
      L2_2(L3_2)
      L2_2 = Vehicle
      L2_2 = L2_2.Enter
      L3_2 = A0_2.uCar
      L4_2 = Player
      L4_2 = L4_2.GetPrimaryCharacter
      L4_2 = L4_2()
      L5_2 = "d"
      L6_2 = true
      L2_2(L3_2, L4_2, L5_2, L6_2)
      L2_2 = A0_2._tEvents
      L3_2 = Event
      L3_2 = L3_2.Create
      L4_2 = Event
      L4_2 = L4_2.ObjectInSeat
      L5_2 = {}
      L6_2 = Player
      L6_2 = L6_2.GetAnyCharacter
      L6_2 = L6_2()
      L7_2 = A0_2.uCar
      L8_2 = "d"
      L9_2 = "e"
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      L5_2[3] = L8_2
      L5_2[4] = L9_2
      L6_2 = AssetsLoaded
      L7_2 = {}
      L8_2 = A0_2
      L7_2[1] = L8_2
      L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
      L2_2.eVehicleSetup = L3_2
    end
  end
end

_MyOnPlayerLeft = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = A0_2._tEvents
  L1_2.eVehicleSetup = nil
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "mechanicHQ.rgn.inside"
  L1_2 = L1_2(L2_2)
  A0_2.inRegion = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "mechanicHQ.rgn.outside"
  L1_2 = L1_2(L2_2)
  A0_2.outRegion = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "mechanicHQ"
  L1_2 = L1_2(L2_2)
  A0_2.garage = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = A0_2.uCar
  L4_2[1] = L5_2
  L5_2 = MonsterTruckDestroyed
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = A0_2.garage
  L4_2[1] = L5_2
  L5_2 = GarageDestroyed
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "race_cp"
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 ~= nil then
    L1_2 = Object
    L1_2 = L1_2.SetInvincible
    L2_2 = A0_2.uCar
    L3_2 = false
    L1_2(L2_2, L3_2)
    L1_2 = A0_2.uBike
    if L1_2 then
      L1_2 = Object
      L1_2 = L1_2.SetInvincible
      L2_2 = A0_2.uBike
      L3_2 = false
      L1_2(L2_2, L3_2)
    end
    L2_2 = A0_2
    L1_2 = A0_2.ObjGoToDestination
    L1_2(L2_2)
  else
    L1_2 = {}
    L2_2 = "Eva-In-Mission-Contract-Mech01-22"
    L3_2 = 0
    L4_2 = {}
    L4_2.mattias = "Mattias-In-Mission-Contract-Mech01-23"
    L4_2.jennifer = "Jennifer-In-Mission-Contract-Mech01-24"
    L4_2.chris = "Chris-In-Mission-Contract-Mech01-25"
    L5_2 = 0.2
    L6_2 = "Eva-In-Mission-Contract-Mech01-26"
    L7_2 = {}
    L8_2 = ObjGetInVehicle
    L9_2 = {}
    L10_2 = A0_2
    L9_2[1] = L10_2
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L1_2[1] = L2_2
    L1_2[2] = L3_2
    L1_2[3] = L4_2
    L1_2[4] = L5_2
    L1_2[5] = L6_2
    L1_2[6] = L7_2
    L2_2 = Player
    L2_2 = L2_2.GetCurrentPlayers
    L2_2 = L2_2()
    if 1 < L2_2 then
      L2_2 = table
      L2_2 = L2_2.insert
      L3_2 = L1_2
      L4_2 = table
      L4_2 = L4_2.getn
      L5_2 = L1_2
      L4_2 = L4_2(L5_2)
      L5_2 = "Eva-In-Mission-Contract-Mech01-72"
      L2_2(L3_2, L4_2, L5_2)
    end
    L2_2 = MrxVoSequence
    L2_2 = L2_2.Start
    L3_2 = L1_2
    L2_2(L3_2)
  end
  L1_2 = MrxMusic
  L1_2 = L1_2.PlaySpecialMusic
  L2_2 = "mu_mission_meccon001_01"
  L1_2(L2_2)
  L1_2 = StringToGuid
  L2_2 = "0xd047d"
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
  L6_2 = Object
  L6_2 = L6_2.Kill
  L7_2 = {}
  L8_2 = L1_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.HideMessage
  L1_2()
  L1_2 = Net
  L1_2 = L1_2.SendCustomEvent
  L2_2 = "MecCon001"
  L3_2 = NETEVENT_HIDETUT
  L4_2 = {}
  L1_2(L2_2, L3_2, L4_2)
  L2_2 = A0_2
  L1_2 = A0_2.TutorialCancel
  L1_2(L2_2)
  L1_2 = A0_2.curAiGoal
  if L1_2 then
    L1_2 = Ai
    L1_2 = L1_2.RemoveGoal
    L2_2 = A0_2.curAiGoal
    L1_2(L2_2)
    A0_2.curAiGoal = nil
  end
  
  function L1_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3
    L1_3 = Vehicle
    L1_3 = L1_3.GetRiders
    L2_3 = A0_3
    L1_3 = L1_3(L2_3)
    L2_3 = pairs
    L3_3 = L1_3
    L2_3, L3_3, L4_3 = L2_3(L3_3)
    for L5_3, L6_3 in L2_3, L3_3, L4_3 do
      L7_3 = Object
      L7_3 = L7_3.IsPlayerControlled
      L8_3 = L6_3
      L7_3 = L7_3(L8_3)
      if L7_3 ~= nil then
        L8_3 = Player
        L8_3 = L8_3.IsLocal
        L9_3 = L7_3
        L8_3 = L8_3(L9_3)
        if not L8_3 then
          goto lbl_27
        end
      end
      L8_3 = Vehicle
      L8_3 = L8_3.Exit
      L9_3 = A0_3
      L10_3 = L6_3
      L11_3 = true
      L8_3(L9_3, L10_3, L11_3)
      ::lbl_27::
    end
    L2_3 = Object
    L2_3 = L2_3.FadeOut
    L3_3 = A0_3
    L4_3 = 1
    L5_3 = true
    L2_3(L3_3, L4_3, L5_3)
  end
  
  L2_2 = L1_2
  L3_2 = A0_2.uCar
  L2_2(L3_2)
  L2_2 = A0_2.uBike
  if L2_2 then
    L2_2 = L1_2
    L3_2 = A0_2.uBike
    L2_2(L3_2)
  end
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "vz_mine_gate"
  L2_2 = L2_2(L3_2)
  L3_2 = Object
  L3_2 = L3_2.CloseGate
  L4_2 = L2_2
  L3_2(L4_2)
  L3_2 = {}
  L4_2 = "Vz_State_MecJob"
  L5_2 = "VZ_State_MecCon001"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L4_2 = pairs
  L5_2 = L3_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = MrxLayerManager
    L9_2 = L9_2.MarkForRemoval
    L10_2 = L8_2
    L9_2(L10_2)
  end
  L4_2 = MrxTaskContract
  L4_2 = L4_2.Cleanup
  L5_2 = A0_2
  L4_2(L5_2)
end

Cleanup = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 2
  L4_2[1] = L5_2
  L5_2 = A0_2.Complete
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

MissionComplete = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[MecCon001.Terms.Cancel02]"
  L1_2(L2_2, L3_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Eva-In-Mission-Contract-Mech01-47"
  L4_2 = {}
  L5_2 = A0_2.Cancel
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
end

MonsterTruckDestroyed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[MecCon001.Terms.Cancel01]"
  L1_2(L2_2, L3_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Mech01-62"
  L4_2 = {}
  L5_2 = A0_2.Cancel
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
end

GarageDestroyed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = A0_2._tEvents
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = A0_2.uCar
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "mc001.loc.tutorialtrigger"
  L6_2 = L6_2(L7_2)
  L7_2 = "<"
  L8_2 = 25
  L9_2 = false
  L10_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L5_2 = StartTutorial
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.eJumpTutorialProx = L2_2
end

CreateTutorialTrigger = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Mech01-35"
  L2_2[1] = L3_2
  L1_2(L2_2)
  A0_2.bShowTutorialTray = true
  L2_2 = A0_2
  L1_2 = A0_2.SetupTutorialTray
  L1_2(L2_2)
end

StartTutorial = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateTutorialTrigger
  L1_2(L2_2)
  L1_2 = A0_2.uCar
  L2_2 = Vehicle
  L2_2 = L2_2.GetDriver
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = Object
    L3_2 = L3_2.IsPlayerControlled
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L4_2 = A0_2
      L3_2 = A0_2.JumpTutorial_InCar
      L5_2 = L2_2
      L6_2 = L1_2
      L3_2(L4_2, L5_2, L6_2)
  end
  else
    L4_2 = A0_2
    L3_2 = A0_2.JumpTutorial_OutCar
    L5_2 = L2_2
    L6_2 = L1_2
    L3_2(L4_2, L5_2, L6_2)
  end
end

SetupJumpTutorial = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = Event
  L3_2 = L3_2.Delete
  L4_2 = A0_2._tEvents
  L4_2 = L4_2.eJumpTutorial
  L3_2(L4_2)
  L3_2 = A0_2._tEvents
  L3_2.eJumpTutorial = nil
  L3_2 = A0_2._tEvents
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.ObjectInSeat
  L6_2 = {}
  L7_2 = Player
  L7_2 = L7_2.GetAnyCharacter
  L7_2 = L7_2()
  L8_2 = A2_2
  L9_2 = "d"
  L10_2 = "ei"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L7_2 = JumpTutorial_InCar
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L3_2.eJumpTutorialSeat = L4_2
  L3_2 = MrxTutorialManager
  L3_2 = L3_2.HideMessage
  L3_2()
  L3_2 = Net
  L3_2 = L3_2.SendCustomEvent
  L4_2 = "MecCon001"
  L5_2 = NETEVENT_HIDETUT
  L6_2 = {}
  L3_2(L4_2, L5_2, L6_2)
end

JumpTutorial_OutCar = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = Object
  L3_2 = L3_2.IsPlayerControlled
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = A0_2._tEvents
  L5_2 = Event
  L5_2 = L5_2.Create
  L6_2 = Event
  L6_2 = L6_2.Button
  L7_2 = {}
  L8_2 = L3_2
  L9_2 = "rtrigger"
  L10_2 = "press"
  L11_2 = true
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L8_2 = TutorialComplete
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L4_2.eJumpTutorial = L5_2
  L4_2 = A0_2._tEvents
  L5_2 = Event
  L5_2 = L5_2.Create
  L6_2 = Event
  L6_2 = L6_2.ObjectInSeat
  L7_2 = {}
  L8_2 = A1_2
  L9_2 = A2_2
  L10_2 = "d"
  L11_2 = "xo"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L8_2 = JumpTutorial_OutCar
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L4_2.eJumpTutorialSeat = L5_2
  L4_2 = A0_2.bShowTutorialTray
  if L4_2 then
    L5_2 = A0_2
    L4_2 = A0_2.SetupTutorialTray
    L4_2(L5_2)
  end
end

JumpTutorial_InCar = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Vehicle
  L1_2 = L1_2.GetDriver
  L2_2 = A0_2.uCar
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L2_2 = Object
    L2_2 = L2_2.IsPlayerControlled
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    L3_2 = Player
    L3_2 = L3_2.GetPrimaryPlayer
    L3_2 = L3_2()
    if L2_2 == L3_2 then
      L3_2 = MrxTutorialManager
      L3_2 = L3_2.ShowMessage
      L4_2 = "[MecCon001.Objectives.buttonTray]"
      L3_2(L4_2)
    else
      L3_2 = Net
      L3_2 = L3_2.SendCustomEvent
      L4_2 = "MecCon001"
      L5_2 = NETEVENT_SHOWTUT
      L6_2 = {}
      L3_2(L4_2, L5_2, L6_2)
    end
  end
end

SetupTutorialTray = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2.TutorialCancel
  L1_2(L2_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Stop
  L2_2 = true
  L1_2(L2_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Eva-In-Mission-Contract-Mech01-36"
  L4_2 = 0
  L5_2 = {}
  L5_2.mattias = "Mattias-In-Mission-Contract-Mech01-37"
  L5_2.jennifer = "Jennifer-In-Mission-Contract-Mech01-38"
  L5_2.chris = "Chris-In-Mission-Contract-Mech01-39"
  L6_2 = 0.5
  L7_2 = "Eva-In-Mission-Contract-Mech01-40"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L1_2(L2_2)
end

TutorialComplete = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  A0_2.bShowTutorialTray = nil
  L1_2 = A0_2._tEvents
  L1_2 = L1_2.eJumpTutorial
  if L1_2 then
    L1_2 = MrxTutorialManager
    L1_2 = L1_2.HideMessage
    L1_2()
    L1_2 = Net
    L1_2 = L1_2.SendCustomEvent
    L2_2 = "MecCon001"
    L3_2 = NETEVENT_HIDETUT
    L4_2 = {}
    L1_2(L2_2, L3_2, L4_2)
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2._tEvents
    L2_2 = L2_2.eJumpTutorial
    L1_2(L2_2)
    L1_2 = A0_2._tEvents
    L1_2.eJumpTutorial = nil
  end
  L1_2 = A0_2._tEvents
  L1_2 = L1_2.eJumpTutorialProx
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2._tEvents
    L2_2 = L2_2.eJumpTutorialProx
    L1_2(L2_2)
    L1_2 = A0_2._tEvents
    L1_2.eJumpTutorialProx = nil
  end
  L1_2 = A0_2._tEvents
  L1_2 = L1_2.eJumpTutorialSeat
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2._tEvents
    L2_2 = L2_2.eJumpTutorialSeat
    L1_2(L2_2)
    L1_2 = A0_2._tEvents
    L1_2.eJumpTutorialSeat = nil
  end
end

TutorialCancel = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Vehicle
  L1_2 = L1_2.GetDriver
  L2_2 = A0_2.uCar
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L2_2 = Object
    L2_2 = L2_2.IsPlayerControlled
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = MrxVoSequence
      L2_2 = L2_2.Stop
      L3_2 = true
      L2_2(L3_2)
      L3_2 = A0_2
      L2_2 = A0_2.ObjDriveAroundBlock
      L2_2(L3_2)
  end
  else
    L3_2 = A0_2
    L2_2 = A0_2.CreateChild
    L4_2 = {}
    L4_2.sName = "Enter car"
    L4_2.sModuleName = "MrxTaskObjectiveEnterVehicle"
    L4_2.sDspShortDesc = "[MecCon001.Objectives.enterVehicle]"
    L5_2 = A0_2.uCar
    L4_2.vTgtInclude = L5_2
    L4_2.nQuota = 1
    
    function L5_2()
      local L0_3, L1_3
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3.ObjDriveAroundBlock
      L0_3(L1_3)
    end
    
    L4_2.fOnComplete = L5_2
    L2_2 = L2_2(L3_2, L4_2)
  end
end

ObjGetInVehicle = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 1
  L4_2[1] = L5_2
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = {}
  L7_2 = {}
  L8_2 = "Eva-In-Mission-Contract-Mech01-27"
  L9_2 = 1.5
  L10_2 = {}
  L10_2.mattias = "Mattias-In-Mission-Contract-Mech01-29"
  L10_2.jennifer = "Jennifer-In-Mission-Contract-Mech01-30"
  L10_2.chris = "Chris-In-Mission-Contract-Mech01-31"
  L11_2 = 0
  L12_2 = "Eva-In-Mission-Contract-Mech01-32"
  L13_2 = {}
  L14_2 = SetupJumpTutorial
  L15_2 = {}
  L16_2 = A0_2
  L15_2[1] = L16_2
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L7_2[5] = L12_2
  L7_2[6] = L13_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "MecRace"
  L3_2.sModuleName = "MrxTaskRace"
  L3_2.sDspShortDesc = "[MecCon001.Objectives.driveAround]"
  L4_2 = A0_2.uCar
  L3_2.vTgtInclude = L4_2
  L4_2 = {}
  L5_2 = "mc001.race.001"
  L6_2 = "mc001.race.002"
  L7_2 = "mc001.race.003"
  L8_2 = "mc001.race.004"
  L9_2 = "mc001.race.001"
  L10_2 = "mc001.race.005"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L3_2.tCourseLocs = L4_2
  
  function L4_2()
    local L0_3, L1_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.ObjGoToDestination
    L0_3(L1_3)
  end
  
  L3_2.fOnComplete = L4_2
  
  function L4_2()
    local L0_3, L1_3
    L0_3 = Object
    L0_3 = L0_3.IsAlive
    L1_3 = A0_2
    L1_3 = L1_3.uCar
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3.Cancel
      L0_3(L1_3)
    end
  end
  
  L3_2.fOnCancel = L4_2
  L1_2(L2_2, L3_2)
end

ObjDriveAroundBlock = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "mc001 go to"
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L3_2.vDestLoc = "mc001.mines"
  L3_2.fDist = 8
  L3_2.bXZOnly = true
  L4_2 = A0_2.uCar
  L3_2.vTgtInclude = L4_2
  L3_2.bStop = false
  L3_2.bDetach = false
  L3_2.sDspShortDesc = "[MecCon001.Objectives.gotoMine]"
  
  function L4_2()
    local L0_3, L1_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.AtRaceStart
    L0_3(L1_3)
  end
  
  L3_2.fOnComplete = L4_2
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
  L5_2 = "Eva-In-Mission-Contract-Mech01-33"
  L6_2 = "Eva-In-Mission-Contract-Mech01-34"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L3_2.vVoSeqOnAdd = L4_2
  L1_2(L2_2, L3_2)
end

ObjGoToDestination = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2
  L1_2 = A0_2.TutorialCancel
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._SetFlag
  L3_2 = "race_cp"
  L4_2 = giAttempts
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Vehicle
  L1_2 = L1_2.GetDriver
  L2_2 = A0_2.uCar
  L1_2 = L1_2(L2_2)
  if L1_2 ~= nil then
    L2_2 = Player
    L2_2 = L2_2.GetSecondaryCharacter
    L2_2 = L2_2()
    if L1_2 == L2_2 then
      L3_2 = A0_2
      L2_2 = A0_2._SetFlag
      L4_2 = "race_P2"
      L2_2(L3_2, L4_2)
    end
  end
  L2_2 = _Checkpoint
  L3_2 = {}
  L4_2 = "meccon001.respawn.p1"
  L5_2 = "meccon001.respawn.p2"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L2_2(L3_2)
  L2_2 = MrxVoSequence
  L2_2 = L2_2.Start
  L3_2 = {}
  L4_2 = "Eva-In-Mission-Contract-Mech01-41"
  L3_2[1] = L4_2
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2.StartRace
  L2_2(L3_2)
end

AtRaceStart = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2
  L1_2 = 45
  L2_2 = giAttempts
  if 6 < L2_2 then
    L1_2 = 90
  else
    L2_2 = giAttempts
    if 3 < L2_2 then
      L1_2 = 60
    end
  end
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "MecRace"
  L4_2.sModuleName = "MrxTaskRace"
  L5_2 = A0_2.uCar
  L4_2.vTgtInclude = L5_2
  L5_2 = {}
  L6_2 = "mc001.race.019"
  L7_2 = "mc001.race.020"
  L8_2 = "mc001.race.020-1"
  L9_2 = "mc001.race.021"
  L10_2 = "mc001.race.022"
  L11_2 = "mc001.race.023"
  L12_2 = "mc001.race.024"
  L13_2 = "mc001.race.025"
  L14_2 = "mc001.race.026"
  L15_2 = "mc001.race.027"
  L16_2 = "mc001.race.028"
  L17_2 = "mc001.race.029"
  L18_2 = "mc001.race.030"
  L19_2 = "mc001.race.032"
  L20_2 = "mc001.race.034"
  L21_2 = "mc001.race.035"
  L22_2 = "mc001.race.035-1"
  L23_2 = "mc001.race.036"
  L24_2 = "mc001.race.037"
  L25_2 = "mc001.race.039"
  L26_2 = "mc001.race.040"
  L27_2 = "mc001.race.041"
  L28_2 = "mc001.race.042"
  L29_2 = "mc001.race.043"
  L30_2 = "mc001.race.044"
  L31_2 = "mc001.race.045"
  L32_2 = "mc001.race.046"
  L33_2 = "mc001.race.047"
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
  L5_2[15] = L20_2
  L5_2[16] = L21_2
  L5_2[17] = L22_2
  L5_2[18] = L23_2
  L5_2[19] = L24_2
  L5_2[20] = L25_2
  L5_2[21] = L26_2
  L5_2[22] = L27_2
  L5_2[23] = L28_2
  L5_2[24] = L29_2
  L5_2[25] = L30_2
  L5_2[26] = L31_2
  L5_2[27] = L32_2
  L5_2[28] = L33_2
  L4_2.tCourseLocs = L5_2
  L5_2 = {}
  L5_2.nStartTime = L1_2
  L4_2.tTimerParams = L5_2
  L4_2.nAddTime = 10
  L4_2.bUseCountdown = false
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Eva-In-Mission-Contract-Mech01-45"
    L3_3 = "Eva-In-Mission-Contract-Mech01-46"
    L4_3 = {}
    L5_3 = _CreateDeliverObjective
    L6_3 = {}
    L7_3 = A0_2
    L6_3[1] = L7_3
    L4_3[1] = L5_3
    L4_3[2] = L6_3
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L1_3[3] = L4_3
    L0_3(L1_3)
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._PlayerOutside
    L0_3(L1_3)
  end
  
  L4_2.fOnComplete = L5_2
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = Object
    L0_3 = L0_3.IsAlive
    L1_3 = A0_2
    L1_3 = L1_3.uCar
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._SetCancelMessage
      L2_3 = "[MecCon001.Terms.Cancel04]"
      L0_3(L1_3, L2_3)
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3.Cancel
      L0_3(L1_3)
    end
  end
  
  L4_2.fOnCancel = L5_2
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2.SetupPipeTrap
  L4_2 = "mc001.trap.trigger01"
  L5_2 = {}
  L5_2.mc001pipetrap11 = "mc001.loc.pipetrap11"
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = A0_2
  L2_2 = A0_2.SetupPipeTrap
  L4_2 = "mc001.trap.trigger02"
  L5_2 = {}
  L5_2.mc001pipetrap21 = "mc001.loc.pipetrap21"
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = A0_2
  L2_2 = A0_2.SetupPipeTrap
  L4_2 = "mc001.trap.trigger03"
  L5_2 = {}
  L5_2.mc001pipetrap31 = "mc001.loc.pipetrap31"
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = A0_2
  L2_2 = A0_2.SetupBridgeTrap
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2.SetupProxVo
  L4_2 = "mc001.race.029"
  L5_2 = 25
  L6_2 = {}
  L7_2 = "Fiona-In-Mission-Contract-Mech01-71"
  L6_2[1] = L7_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L3_2 = A0_2
  L2_2 = A0_2.SetupProxVo
  L4_2 = "mc001.trap.trigger01"
  L5_2 = 8
  L6_2 = {}
  L7_2 = "Fiona-In-Mission-Contract-Mech01-69"
  L6_2[1] = L7_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L3_2 = A0_2
  L2_2 = A0_2.SetupProxVo
  L4_2 = "mc001.trap.trigger02"
  L5_2 = 6
  L6_2 = {}
  L7_2 = "Fiona-In-Mission-Contract-Mech01-70"
  L6_2[1] = L7_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L3_2 = A0_2
  L2_2 = A0_2.SetupProxVo
  L4_2 = "mc001.turnrighwarn"
  L5_2 = 25
  L6_2 = {}
  L7_2 = "Fiona-In-Mission-Contract-Mech01-66"
  L6_2[1] = L7_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L3_2 = A0_2
  L2_2 = A0_2.SetupProxVo
  L4_2 = "mc001.bridgeWarn"
  L5_2 = 25
  L6_2 = {}
  L7_2 = "Fiona-In-Mission-Contract-Mech01-67"
  L6_2[1] = L7_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "vz_mine_gate"
  L2_2 = L2_2(L3_2)
  L3_2 = Object
  L3_2 = L3_2.OpenGate
  L4_2 = L2_2
  L3_2(L4_2)
  L3_2 = MrxMusic
  L3_2 = L3_2.PlaySpecialMusic
  L4_2 = "mu_mission_meccon001_02"
  L3_2(L4_2)
end

StartRace = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = Object
  L4_2 = L4_2.GetPosition
  L5_2 = L3_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  L7_2 = Object
  L7_2 = L7_2.GetYaw
  L8_2 = L3_2
  L7_2 = L7_2(L8_2)
  if not A2_2 then
    A2_2 = 1
  end
  L8_2 = Pg
  L8_2 = L8_2.Spawn
  L9_2 = "Offroad Motorcycle (AI ONLY)"
  L10_2 = L4_2
  L11_2 = L5_2
  L12_2 = L6_2
  L13_2 = L7_2
  L14_2 = false
  L15_2 = true
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  L9_2 = table
  L9_2 = L9_2.insert
  L10_2 = A0_2.tOpponents
  L11_2 = L8_2
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
  L13_2 = StartOpponent
  L14_2 = {}
  L15_2 = A0_2
  L16_2 = L8_2
  L17_2 = A2_2
  L14_2[1] = L15_2
  L14_2[2] = L16_2
  L14_2[3] = L17_2
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
end

SpawnOpponent = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = {}
  L5_2 = "mc001.pth.bike.001"
  L6_2 = "mc001.pth.bike.002"
  L7_2 = "mc001.pth.bike.003"
  L8_2 = "mc001.pth.bike.004"
  L9_2 = "mc001.pth.bike.005"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L6_2 = A0_2
  L5_2 = A0_2.OpponentAdvancePath
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = A2_2
  L10_2 = 1
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
end

StartOpponent = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L5_2 = A2_2[A4_2]
  if L5_2 then
    L6_2 = Pg
    L6_2 = L6_2.GetGuidByName
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    L7_2 = Junk
    L7_2 = L7_2.DrawPath
    L8_2 = L6_2
    L7_2(L8_2)
    L7_2 = Ai
    L7_2 = L7_2.Goal
    L8_2 = {}
    L8_2.AIGuid = A1_2
    L8_2.Goal = "PathMove"
    L8_2.Target = L6_2
    L8_2.Haste = A3_2
    L8_2.Priority = "HiPri"
    L8_2.Timeout = 10
    L9_2 = OpponentAdvancePath
    L8_2.Callback = L9_2
    L9_2 = {}
    L10_2 = A0_2
    L11_2 = A1_2
    L12_2 = A2_2
    L13_2 = A3_2
    L14_2 = A4_2 + 1
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L9_2[4] = L13_2
    L9_2[5] = L14_2
    L8_2.CallbackData = L9_2
    L7_2 = L7_2(L8_2)
    A0_2.curAiGoal = L7_2
  else
    A0_2.bOpponentFinished = true
  end
end

OpponentAdvancePath = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.ObjectProximity
  L6_2 = {}
  L7_2 = Player
  L7_2 = L7_2.GetAnyCharacter
  L7_2 = L7_2()
  L8_2 = Pg
  L8_2 = L8_2.GetGuidByName
  L9_2 = A1_2
  L8_2 = L8_2(L9_2)
  L9_2 = "<"
  L10_2 = 12
  L11_2 = false
  L12_2 = false
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L6_2[5] = L11_2
  L6_2[6] = L12_2
  L7_2 = TriggerPipeTrap
  L8_2 = {}
  L9_2 = A0_2
  L10_2 = A2_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
end

SetupPipeTrap = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = pairs
  L3_2 = A1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = Object
    L7_2 = L7_2.Kill
    L8_2 = Pg
    L8_2 = L8_2.GetGuidByName
    L9_2 = L5_2
    L8_2, L9_2 = L8_2(L9_2)
    L7_2(L8_2, L9_2)
  end
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 0.1
  L5_2[1] = L6_2
  L6_2 = SpawnExplosionPipeTrap
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A1_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

TriggerPipeTrap = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L2_2 = pairs
  L3_2 = A1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = Pg
    L7_2 = L7_2.GetGuidByName
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    L8_2 = Object
    L8_2 = L8_2.GetPosition
    L9_2 = L7_2
    L8_2, L9_2, L10_2 = L8_2(L9_2)
    L11_2 = Pg
    L11_2 = L11_2.Spawn
    L12_2 = "Explosion (Rocket Artillery)"
    L13_2 = L8_2
    L14_2 = L9_2
    L15_2 = L10_2
    L16_2 = 0
    L17_2 = false
    L18_2 = false
    L11_2(L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
    L11_2 = Pg
    L11_2 = L11_2.GetGuidByName
    L12_2 = L5_2
    L11_2 = L11_2(L12_2)
    L12_2 = Net
    L12_2 = L12_2.SendCustomEvent
    L13_2 = "MecCon001"
    L14_2 = NETEVENT_SPAWNEXPLOSION
    L15_2 = {}
    L16_2 = L11_2
    L15_2[1] = L16_2
    L12_2(L13_2, L14_2, L15_2)
  end
end

SpawnExplosionPipeTrap = L0_1

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
  L7_2 = "mc001.bridgeBomb.tigger"
  L6_2 = L6_2(L7_2)
  L7_2 = "<"
  L8_2 = 30
  L9_2 = false
  L10_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L5_2 = TriggerBridgeTrap
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

SetupBridgeTrap = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L2_2.nBaseDelay = 0
  L3_2 = "Fiona-In-Mission-Contract-Mech01-68"
  L2_2[1] = L3_2
  L1_2(L2_2)
end

TriggerBridgeTrap = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L5_2 = A0_2
  L4_2 = A0_2._CreateEvent
  L6_2 = Event
  L6_2 = L6_2.ObjectProximity
  L7_2 = {}
  L8_2 = Player
  L8_2 = L8_2.GetAnyCharacter
  L8_2 = L8_2()
  L9_2 = Pg
  L9_2 = L9_2.GetGuidByName
  L10_2 = A1_2
  L9_2 = L9_2(L10_2)
  L10_2 = "<"
  L11_2 = A2_2
  L12_2 = false
  L13_2 = false
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L7_2[5] = L12_2
  L7_2[6] = L13_2
  L8_2 = MrxVoSequence
  L8_2 = L8_2.Start
  L9_2 = {}
  L10_2 = A3_2
  L9_2[1] = L10_2
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
end

SetupProxVo = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Park inside the garage"
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2 = A0_2.uCar
  L3_2.vTgtInclude = L4_2
  L3_2.vDestLoc = "mechanicHQ_loc_delivery"
  L3_2.vDestRegion = "mechanicHQ.rgn.inside"
  L3_2.fDist = 3
  L3_2.bStop = true
  L3_2.bXZOnly = false
  L3_2.sDspShortDesc = "[MecCon001.Objectives.park]"
  L3_2.bDspMsgUpd = false
  L3_2.bDisplayHelpText = true
  L3_2.nQuota = 1
  
  function L4_2()
    local L0_3, L1_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._ExitGarage
    L0_3(L1_3)
  end
  
  L3_2.fOnComplete = L4_2
  
  function L4_2()
    local L0_3, L1_3
    L0_3 = Object
    L0_3 = L0_3.IsAlive
    L1_3 = A0_2
    L1_3 = L1_3.uCar
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3.Cancel
      L0_3(L1_3)
    end
  end
  
  L3_2.fOnCancel = L4_2
  L1_2(L2_2, L3_2)
end

_CreateDeliverObjective = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = Object
  L1_2 = L1_2.CloseGate
  L2_2 = A0_2.garage
  L1_2(L2_2)
  L1_2 = A0_2._tEvents
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = A0_2.outRegion
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = _PlayerInside
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.eDoorTrigger = L2_2
end

_PlayerOutside = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = Object
  L2_2 = L2_2.OpenGate
  L3_2 = A0_2.garage
  L2_2(L3_2)
  L2_2 = A0_2._tEvents
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.Boundary
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAllCharacters
  L6_2 = L6_2()
  L7_2 = A0_2.outRegion
  L8_2 = "exit"
  L9_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L6_2 = _PlayerOutside
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2.eDoorTrigger = L3_2
end

_PlayerInside = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2._tEvents
  L2_2 = L2_2.eDoorTrigger
  L1_2(L2_2)
  L1_2 = A0_2._tEvents
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAllCharacters
  L5_2 = L5_2()
  L6_2 = A0_2.outRegion
  L7_2 = "exit"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = _VehicleDelivered
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.eDoorTrigger = L2_2
end

_ExitGarage = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Object
  L1_2 = L1_2.InsideBoundary
  L2_2 = A0_2.uCar
  L3_2 = A0_2.inRegion
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 then
    L1_2 = Object
    L1_2 = L1_2.CloseGate
    L2_2 = A0_2.garage
    L1_2(L2_2)
    
    function L1_2()
      local L0_3, L1_3
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = A0_2
      L1_3 = L1_3._tEvents
      L1_3 = L1_3.eGateClosed
      L0_3(L1_3)
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = A0_2
      L1_3 = L1_3._tEvents
      L1_3 = L1_3.eGateStuck
      L0_3(L1_3)
      L0_3 = Object
      L0_3 = L0_3.Remove
      L1_3 = A0_2
      L1_3 = L1_3.uCar
      L0_3(L1_3)
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3.Complete
      L0_3(L1_3)
    end
    
    L2_2 = A0_2._tEvents
    L3_2 = Event
    L3_2 = L3_2.Create
    L4_2 = Event
    L4_2 = L4_2.ObjectPhysicsEvent
    L5_2 = {}
    L6_2 = A0_2.garage
    L7_2 = "gateFullyClosed"
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L6_2 = L1_2
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.eGateClosed = L3_2
    L2_2 = A0_2._tEvents
    L3_2 = Event
    L3_2 = L3_2.Create
    L4_2 = Event
    L4_2 = L4_2.ObjectPhysicsEvent
    L5_2 = {}
    L6_2 = A0_2.garage
    L7_2 = "gateStuck"
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L6_2 = L1_2
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.eGateStuck = L3_2
  else
    L2_2 = A0_2
    L1_2 = A0_2._CreateDeliverObjective
    L1_2(L2_2)
  end
end

_VehicleDelivered = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Complete2
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Hud
  L1_2 = L1_2.EventFanfare
  L2_2 = L1_2
  L1_2 = L1_2.Commence
  L3_2 = {}
  L3_2.sType = "stockpile"
  L3_2.sText = "[flagpmc][weapon.grapple]"
  L1_2(L2_2, L3_2)
end

Complete2 = L0_1
L0_1 = 0
NETEVENT_ENTERVEHICLE = L0_1
L0_1 = 5
NETEVENT_SPAWNEXPLOSION = L0_1
L0_1 = 10
NETEVENT_SHOWTUT = L0_1
L0_1 = 11
NETEVENT_HIDETUT = L0_1
L0_1 = 12
NETEVENT_CLIENTTUTCOMPLETE = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Player
  L1_2 = L1_2.GetSecondaryCharacter
  L1_2 = L1_2()
  L2_2 = Vehicle
  L2_2 = L2_2.GetFromRider
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  L3_2 = Net
  L3_2 = L3_2.IsReadyToTether
  L3_2 = L3_2()
  if L3_2 and not L2_2 then
    L3_2 = Vehicle
    L3_2 = L3_2.Enter
    L4_2 = A0_2
    L5_2 = L1_2
    L6_2 = "d"
    L7_2 = true
    L8_2 = false
    L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
    L4_2 = type
    L5_2 = A0_2
    L4_2 = L4_2(L5_2)
    if L4_2 == "userdata" then
    end
  elseif L2_2 and A0_2 ~= L2_2 then
    L3_2 = Event
    L3_2 = L3_2.Create
    L4_2 = Event
    L4_2 = L4_2.ObjectInSeat
    L5_2 = {}
    L6_2 = L1_2
    L7_2 = L2_2
    L8_2 = "a"
    L9_2 = "xo"
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L5_2[4] = L9_2
    L6_2 = NetClientEnterVehicle
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L3_2(L4_2, L5_2, L6_2, L7_2)
    L3_2 = Vehicle
    L3_2 = L3_2.Exit
    L4_2 = L2_2
    L5_2 = L1_2
    L3_2(L4_2, L5_2)
  else
    L3_2 = Event
    L3_2 = L3_2.Create
    L4_2 = Event
    L4_2 = L4_2.TimerRelative
    L5_2 = {}
    L6_2 = 0.2
    L5_2[1] = L6_2
    L6_2 = NetClientEnterVehicle
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L3_2(L4_2, L5_2, L6_2, L7_2)
  end
end

NetClientEnterVehicle = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = NETEVENT_ENTERVEHICLE
  if A0_2 == L2_2 then
    L2_2 = NetClientEnterVehicle
    L3_2 = A1_2[1]
    L2_2(L3_2)
  else
    L2_2 = NETEVENT_SPAWNEXPLOSION
    if A0_2 == L2_2 then
      L2_2 = Object
      L2_2 = L2_2.GetPosition
      L3_2 = A1_2[1]
      L2_2, L3_2, L4_2 = L2_2(L3_2)
      L5_2 = Pg
      L5_2 = L5_2.Spawn
      L6_2 = "Explosion (Rocket Artillery)"
      L7_2 = L2_2
      L8_2 = L3_2
      L9_2 = L4_2
      L10_2 = 0
      L11_2 = false
      L12_2 = false
      L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
    else
      L2_2 = NETEVENT_SHOWTUT
      if A0_2 == L2_2 then
        L2_2 = MrxTutorialManager
        L2_2 = L2_2.ShowMessage
        L3_2 = "[MecCon001.Objectives.buttonTray]"
        L2_2(L3_2)
        L2_2 = Event
        L2_2 = L2_2.Create
        L3_2 = Event
        L3_2 = L3_2.Button
        L4_2 = {}
        L5_2 = Player
        L5_2 = L5_2.GetSecondaryPlayer
        L5_2 = L5_2()
        L6_2 = "rtrigger"
        L7_2 = "press"
        L8_2 = true
        L4_2[1] = L5_2
        L4_2[2] = L6_2
        L4_2[3] = L7_2
        L4_2[4] = L8_2
        L5_2 = ClientTutorialComplete
        L2_2 = L2_2(L3_2, L4_2, L5_2)
        geJumpTutorial = L2_2
      else
        L2_2 = NETEVENT_HIDETUT
        if A0_2 == L2_2 then
          L2_2 = Event
          L2_2 = L2_2.Delete
          L3_2 = geJumpTutorial
          L2_2(L3_2)
          L2_2 = nil
          geJumpTutorial = L2_2
          L2_2 = MrxTutorialManager
          L2_2 = L2_2.HideMessage
          L2_2()
        else
          L2_2 = NETEVENT_CLIENTTUTCOMPLETE
          if A0_2 == L2_2 then
            L2_2 = MrxPlayState
            L2_2 = L2_2.GetCurrentMission
            L2_2 = L2_2()
            L4_2 = L2_2
            L3_2 = L2_2.TutorialComplete
            L3_2(L4_2)
          end
        end
      end
    end
  end
end

NetEventCallback = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2
  geJumpTutorial = L0_2
  L0_2 = MrxTutorialManager
  L0_2 = L0_2.HideMessage
  L0_2()
  L0_2 = Net
  L0_2 = L0_2.SendCustomEvent
  L1_2 = "MecCon001"
  L2_2 = NETEVENT_CLIENTTUTCOMPLETE
  L3_2 = {}
  L0_2(L1_2, L2_2, L3_2)
end

ClientTutorialComplete = L0_1
