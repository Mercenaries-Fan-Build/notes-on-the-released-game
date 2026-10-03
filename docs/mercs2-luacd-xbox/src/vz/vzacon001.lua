local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxClusterBomb"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxState"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxAchievements"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiSatellite"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxCopterDrop"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = 0
NETEVENT_CLIENTSETUP = L0_1
L0_1 = 0
iInsideMinigame = L0_1
L0_1 = 1
iGate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = NETEVENT_CLIENTSETUP
  if A0_2 == L2_2 then
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
    L2_2 = Graphics
    L2_2 = L2_2.Atmosphere
    L2_2 = L2_2.ChangeLineRegionSetting
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = "rgn_atmo_carmonaislandrain"
    L3_2 = L3_2(L4_2)
    L4_2 = "night"
    L2_2(L3_2, L4_2)
  end
end

NetEventCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L7_2 = A0_2
  L6_2 = A0_2._GetFlag
  L8_2 = "VZ001CP02"
  L6_2 = L6_2(L7_2, L8_2)
  if L6_2 then
    L6_2 = {}
    L7_2 = "Vz_State_VzaCon001"
    L8_2 = "vz_state_VzaCon001_Pristine"
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L2_2 = L6_2
    L6_2 = {}
    L7_2 = "Vz_State_VzaCon001_CP01"
    L8_2 = "Vz_State_VzaCon001_CP02"
    L9_2 = "Vz_State_VzaCon001_PreGate1"
    L10_2 = "Vz_State_VzaCon001_PreGate2"
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L6_2[4] = L10_2
    L3_2 = L6_2
    L4_2 = A0_2.AssetsLoaded
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L5_2 = L6_2
  else
    L7_2 = A0_2
    L6_2 = A0_2._GetFlag
    L8_2 = "VZ001CP01"
    L6_2 = L6_2(L7_2, L8_2)
    if L6_2 then
      L6_2 = {}
      L7_2 = "Vz_State_VzaCon001"
      L8_2 = "vz_state_VzaCon001_Pristine"
      L9_2 = "Vz_State_VzaCon001_CP02"
      L10_2 = "Vz_State_VzaCon001_PreGate2"
      L6_2[1] = L7_2
      L6_2[2] = L8_2
      L6_2[3] = L9_2
      L6_2[4] = L10_2
      L2_2 = L6_2
      L6_2 = {}
      L7_2 = "Vz_State_VzaCon001_CP01"
      L8_2 = "Vz_State_VzaCon001_PreGate1"
      L6_2[1] = L7_2
      L6_2[2] = L8_2
      L3_2 = L6_2
      L4_2 = A0_2.AssetsLoaded
      L6_2 = {}
      L7_2 = A0_2
      L6_2[1] = L7_2
      L5_2 = L6_2
    else
      L6_2 = {}
      L7_2 = "Vz_State_VzaCon001"
      L8_2 = "vz_state_VzaCon001_Pristine"
      L9_2 = "Vz_State_VzaCon001_CP01"
      L10_2 = "Vz_State_VzaCon001_CP02"
      L11_2 = "Vz_State_VzaCon001_PreGate1"
      L12_2 = "Vz_State_VzaCon001_PreGate2"
      L6_2[1] = L7_2
      L6_2[2] = L8_2
      L6_2[3] = L9_2
      L6_2[4] = L10_2
      L6_2[5] = L11_2
      L6_2[6] = L12_2
      L2_2 = L6_2
      L6_2 = {}
      L3_2 = L6_2
      L4_2 = A0_2.StandardSetup
      L6_2 = {}
      L7_2 = A0_2
      L6_2[1] = L7_2
      L5_2 = L6_2
      L6_2 = SetStartupWeapons
      L6_2()
    end
  end
  L6_2 = MrxLayerManager
  L6_2 = L6_2.Remove
  L7_2 = L3_2
  L8_2 = MrxLayerManager
  L8_2 = L8_2.Add
  L9_2 = {}
  L10_2 = L2_2
  L11_2 = L4_2
  L12_2 = L5_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L9_2[3] = L12_2
  L6_2(L7_2, L8_2, L9_2)
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = Net
  L1_2 = L1_2.DoneReloadingLayers
  if L1_2 then
    L1_2 = Net
    L1_2 = L1_2.DoneReloadingLayers
    L1_2()
  end
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "VzaCon001_StartingBoat"
  L1_2 = L1_2(L2_2)
  
  function L2_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3
    L1_3 = {}
    _tPlayers = L1_3
    L1_3 = Player
    L1_3 = L1_3.GetAllPlayers
    L1_3 = L1_3()
    L2_3 = ipairs
    L3_3 = L1_3
    L2_3, L3_3, L4_3 = L2_3(L3_3)
    for L5_3, L6_3 in L2_3, L3_3, L4_3 do
      L7_3 = Player
      L7_3 = L7_3.GetCharacter
      L8_3 = L6_3
      L7_3 = L7_3(L8_3)
      L8_3 = Human
      L8_3 = L8_3.Inventory
      L8_3 = L8_3.GetPrimaryWeapon
      L9_3 = L7_3
      L8_3 = L8_3(L9_3)
      if L8_3 then
        L9_3 = Weapon
        L9_3 = L9_3.SetReserveAmmo
        L10_3 = L8_3
        L11_3 = Weapon
        L11_3 = L11_3.GetMaxReserveAmmo
        L12_3 = L8_3
        L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3 = L11_3(L12_3)
        L9_3(L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3)
      end
      L9_3 = Human
      L9_3 = L9_3.SetState
      L10_3 = L7_3
      L11_3 = "Upright"
      L12_3 = "Idle"
      L9_3(L10_3, L11_3, L12_3)
      L9_3 = nil
      if L5_3 == 1 then
        L10_3 = Vehicle
        L10_3 = L10_3.Enter
        L11_3 = A0_3
        L12_3 = L7_3
        L13_3 = "d"
        L14_3 = false
        L10_3(L11_3, L12_3, L13_3, L14_3)
        L9_3 = "D"
      else
        L10_3 = Net
        L10_3 = L10_3.SendEvent_JoinPOForceRequest
        L10_3()
        L10_3 = Vehicle
        L10_3 = L10_3.Enter
        L11_3 = A0_3
        L12_3 = L7_3
        L13_3 = "p"
        L14_3 = false
        L10_3(L11_3, L12_3, L13_3, L14_3)
        L9_3 = "P"
      end
      L10_3 = A0_2
      L11_3 = L10_3
      L10_3 = L10_3._CreateEvent
      L12_3 = Event
      L12_3 = L12_3.ObjectInSeat
      L13_3 = {}
      L14_3 = L7_3
      L15_3 = A0_3
      L16_3 = L9_3
      L17_3 = "E"
      L13_3[1] = L14_3
      L13_3[2] = L15_3
      L13_3[3] = L16_3
      L13_3[4] = L17_3
      L14_3 = A0_2
      L14_3 = L14_3.EnsureHeroesInBoat
      L15_3 = {}
      L16_3 = A0_2
      L15_3[1] = L16_3
      L10_3(L11_3, L12_3, L13_3, L14_3, L15_3)
      L10_3 = _tPlayers
      L10_3[L7_3] = false
    end
    L2_3 = Net
    L2_3 = L2_3.IsServer
    L2_3 = L2_3()
    if L2_3 then
      L2_3 = Net
      L2_3 = L2_3.SendEvent_ForceClientTether
      L2_3()
    end
    L2_3 = Net
    L2_3 = L2_3.IsMultiplayer
    L2_3 = L2_3()
    if L2_3 then
      L2_3 = Net
      L2_3 = L2_3.IsServer
      L2_3 = L2_3()
      if not L2_3 then
        goto lbl_102
      end
    end
    L2_3 = MrxStatsManager
    L2_3 = L2_3.DeleteVehicleTimer
    L2_3()
    L2_3 = MrxStatsManager
    L2_3 = L2_3.AddVehicleTimer
    L2_3()
    ::lbl_102::
  end
  
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectHibernation
  L5_2 = {}
  L6_2 = L1_2
  L7_2 = "a"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = L2_2
  L7_2 = {}
  L8_2 = L1_2
  L7_2[1] = L8_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
end

StandardSetup = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = _tPlayers
  L2_2[A1_2] = true
  L2_2 = true
  L3_2 = pairs
  L4_2 = _tPlayers
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    if not L7_2 then
      L2_2 = false
      break
    end
  end
  if L2_2 then
    L3_2 = Player
    L3_2 = L3_2.GetAllPlayers
    L3_2 = L3_2()
    if L3_2 then
      L4_2 = ipairs
      L5_2 = L3_2
      L4_2, L5_2, L6_2 = L4_2(L5_2)
      for L7_2, L8_2 in L4_2, L5_2, L6_2 do
        L9_2 = Player
        L9_2 = L9_2.GetCamera
        L10_2 = L8_2
        L9_2 = L9_2(L10_2)
        if L9_2 then
          L10_2 = Camera
          L10_2 = L10_2.StopBlending
          if L10_2 then
            L10_2 = Camera
            L10_2 = L10_2.StopBlending
            L11_2 = L9_2
            L10_2(L11_2)
          end
        end
      end
    end
    L5_2 = A0_2
    L4_2 = A0_2.AssetsLoaded
    L4_2(L5_2)
    L4_2 = nil
    _tPlayers = L4_2
  else
  end
end

EnsureHeroesInBoat = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = false
  bCinematicSkipped = L1_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = MrxFactionManager
  L1_2 = L1_2.DisableReporting
  L2_2 = true
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectInSeat
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = "VzaCon001_StartingBoat"
  L7_2 = "d"
  L8_2 = "x"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = MrxTutorialManager
  L5_2 = L5_2.HideMessage
  L6_2 = {}
  L7_2 = false
  L8_2 = "VzaCon001"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "VzaCon001_StartingBoat"
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = MrxTutorialManager
  L5_2 = L5_2.HideMessage
  L6_2 = {}
  L7_2 = false
  L8_2 = "VzaCon001"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
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
  L7_2 = "region_killvzaheli"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = StopTheMusic
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.ObjectHibernation
  L3_2 = {}
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "Carmona_VzaCon001"
  L4_2 = L4_2(L5_2)
  L5_2 = "awake"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  
  function L4_2()
    local L0_3, L1_3
    L0_3 = DropCarmonaWeapons
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L1_2(L2_2, L3_2, L4_2)
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
  L7_2 = "region_brokenbridge"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = BrokenBridgeEncounter
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
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
  L7_2 = "region_vza_handbrake"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = HandbrakeTutorial
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
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
  L7_2 = "region_vza_usegrenade"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = GrenadeHint
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
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
  L7_2 = "region_vza_tankswitch"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = TankSwitch
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "Satellite Targetting Success"
  
  function L6_2()
    local L0_3, L1_3
    L0_3 = true
    return L0_3
  end
  
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = AirstrikeMinigame_SuccessVO
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "Satellite Targetting Start"
  
  function L6_2()
    local L0_3, L1_3
    L0_3 = true
    return L0_3
  end
  
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = AirstrikeMinigame_InsideVO
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "VZ001CP02"
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.DeliverTank
    L1_2(L2_2)
  else
    L2_2 = A0_2
    L1_2 = A0_2._GetFlag
    L3_2 = "VZ001CP01"
    L1_2 = L1_2(L2_2, L3_2)
    if L1_2 then
      L2_2 = A0_2
      L1_2 = A0_2.GetToFirstWaypoint
      L1_2(L2_2)
    else
      L2_2 = A0_2
      L1_2 = A0_2.BoatApproach
      L1_2(L2_2)
      L1_2 = SetupAirstrikeEvent
      L2_2 = A0_2
      L1_2(L2_2)
    end
  end
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.ChangeLineRegionSetting
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "rgn_atmo_carmonaislandrain"
  L2_2 = L2_2(L3_2)
  L3_2 = "night"
  L1_2(L2_2, L3_2)
  L1_2 = Net
  L1_2 = L1_2.SendCustomEvent
  L2_2 = "VzaCon001"
  L3_2 = NETEVENT_CLIENTSETUP
  L4_2 = {}
  L5_2 = true
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

Activated = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  L4_2 = Net
  L4_2 = L4_2.SendCustomEvent
  L5_2 = "VzaCon001"
  L6_2 = NETEVENT_CLIENTSETUP
  L7_2 = {}
  L8_2 = true
  L4_2(L5_2, L6_2, L7_2, L8_2)
end

OnPlayerJoined = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L0_2 = Player
  L0_2 = L0_2.GetLocalPlayer
  L0_2 = L0_2()
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2 = L1_2()
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "Carbine"
  L2_2 = L2_2(L3_2)
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "C4"
  L3_2 = L3_2(L4_2)
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "Grenade"
  L4_2 = L4_2(L5_2)
  L5_2 = Human
  L5_2 = L5_2.Inventory
  L5_2 = L5_2.SetAllWeapons
  L6_2 = L1_2
  L7_2 = {}
  L8_2 = L2_2
  L9_2 = L4_2
  L10_2 = L3_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L5_2(L6_2, L7_2)
  L5_2 = Human
  L5_2 = L5_2.Inventory
  L5_2 = L5_2.GetPrimaryWeapon
  L6_2 = L1_2
  L5_2 = L5_2(L6_2)
  L6_2 = Event
  L6_2 = L6_2.Create
  L7_2 = Event
  L7_2 = L7_2.ObjectHibernation
  L8_2 = {}
  L9_2 = L5_2
  L10_2 = "awake"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L9_2 = FillWeapon
  L10_2 = {}
  L11_2 = L5_2
  L10_2[1] = L11_2
  L6_2(L7_2, L8_2, L9_2, L10_2)
end

SetStartupWeapons = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Weapon
  L1_2 = L1_2.SetReserveAmmo
  L2_2 = A0_2
  L3_2 = Weapon
  L3_2 = L3_2.GetMaxReserveAmmo
  L4_2 = A0_2
  L3_2, L4_2 = L3_2(L4_2)
  L1_2(L2_2, L3_2, L4_2)
end

FillWeapon = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 0.1
  L4_2[1] = L5_2
  L5_2 = A0_2.GetToBeach
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

BoatApproach = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Sound
  L1_2 = L1_2.SetDynamicMusic
  L2_2 = false
  L1_2(L2_2)
  L1_2 = MrxMusic
  L1_2 = L1_2.PlaySpecialMusic
  L2_2 = "mu_nomission_water_threat_01"
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "VZA001: Go to the Beach"
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2 = Player
  L4_2 = L4_2.GetAnyCharacter
  L4_2 = L4_2()
  L3_2.vTgtInclude = L4_2
  L3_2.vDestLoc = "loc_vza_beach"
  L3_2.vDestRegion = "region_vza_beach"
  L3_2.bStop = false
  L3_2.bXZOnly = true
  L3_2.sDspShortDesc = "[VzaCon001.Objectives.001]"
  L4_2 = {}
  L5_2 = "Fiona-In-Mission-Contract-Vz01-146"
  L6_2 = 0.5
  L7_2 = {}
  L7_2.mattias = "Mattias-In-Mission-Contract-Vz01-147"
  L7_2.jennifer = "Jennifer-In-Mission-Contract-Vz01-148"
  L7_2.chris = "Chris-In-Mission-Contract-Vz01-149"
  L8_2 = 0.5
  L9_2 = "Fiona-In-Mission-Contract-Vz01-150"
  L10_2 = 0.5
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L3_2.vVoSeqOnAdd = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.BoatCheck
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
  oGetToBeach = L1_2
end

GetToBeach = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = Object
  L1_2 = L1_2.IsPlayerControlled
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "VzaCon001_StartingBoat"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  if L1_2 then
    L1_2 = MrxTutorialManager
    L1_2 = L1_2.BeginCustomTutorial
    L2_2 = "VzaCon001"
    L1_2(L2_2)
    L1_2 = MrxTutorialManager
    L1_2 = L1_2.ShowMessage
    L2_2 = "[Tutorial.EnterExit]"
    L3_2 = false
    L4_2 = "VzaCon001"
    L1_2(L2_2, L3_2, L4_2)
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.ObjectInSeat
    L4_2 = {}
    L5_2 = Player
    L5_2 = L5_2.GetAnyCharacter
    L5_2 = L5_2()
    L6_2 = Pg
    L6_2 = L6_2.GetGuidByName
    L7_2 = "VzaCon001_StartingBoat"
    L6_2 = L6_2(L7_2)
    L7_2 = "D"
    L8_2 = "X"
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L4_2[3] = L7_2
    L4_2[4] = L8_2
    L5_2 = A0_2.DropInWeapon
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  else
    L1_2 = A0_2.DropInWeapon
    L2_2 = A0_2
    L1_2(L2_2)
  end
end

BoatCheck = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.HideMessage
  L2_2 = false
  L3_2 = "VzaCon001"
  L1_2(L2_2, L3_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Vz01-221"
  L4_2 = 0.5
  L5_2 = {}
  L5_2.mattias = "Mattias-In-Mission-Contract-Vz01-232"
  L5_2.jennifer = "Jennifer-In-Mission-Contract-Vz01-177"
  L5_2.chris = "Chris-In-Mission-Contract-Vz01-178"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L1_2(L2_2)
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "loc_vza_weapondrop"
  L1_2 = L1_2(L2_2)
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "loc_vza_helispawn1"
  L5_2 = L5_2(L6_2)
  L6_2 = Object
  L6_2 = L6_2.GetPosition
  L7_2 = L5_2
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  L9_2 = MrxCopterDrop
  L9_2 = L9_2.Create
  L10_2 = "VZF"
  L11_2 = "Supply Drop (GL)"
  L12_2 = L2_2
  L13_2 = L3_2
  L14_2 = L4_2
  L15_2 = true
  L16_2 = L6_2
  L17_2 = L7_2
  L18_2 = L8_2
  L9_2, L10_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  L12_2 = A0_2
  L11_2 = A0_2._CreateEvent
  L13_2 = Event
  L13_2 = L13_2.TimerRelative
  L14_2 = {}
  L15_2 = 3
  L14_2[1] = L15_2
  L15_2 = WaitForWeapon
  L16_2 = {}
  L17_2 = A0_2
  L18_2 = L10_2
  L16_2[1] = L17_2
  L16_2[2] = L18_2
  L11_2(L12_2, L13_2, L14_2, L15_2, L16_2)
end

DropInWeapon = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "VZA001: Wait for Weapon"
  L4_2.sModuleName = "MrxTaskObjectiveDeliver"
  L5_2 = {}
  L6_2 = A1_2
  L5_2[1] = L6_2
  L4_2.vTgtInclude = L5_2
  L4_2.vDestLoc = "loc_vza_weapondrop"
  L4_2.vDestRegion = "region_vza_weapondrop"
  L4_2.bStop = false
  L4_2.bXZOnly = false
  L4_2.sDspShortDesc = "[VzaCon001.Objectives.002]"
  L5_2 = {}
  L6_2 = {}
  L7_2 = A0_2.BeachGuardsCheck
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnComplete = L5_2
  L5_2 = {}
  L6_2 = {}
  L7_2 = A0_2.FailSafe
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnCancel = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  oWaitForWeapon = L2_2
  L3_2 = A0_2
  L2_2 = A0_2.MeleeBashTuteSetup
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

WaitForWeapon = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Vz01-240"
  L2_2[1] = L3_2
  L1_2(L2_2)
  L1_2 = oWaitForWeapon
  L2_2 = L1_2
  L1_2 = L1_2.Complete
  L1_2(L2_2)
end

FailSafe = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "loc_vza_weapondrop"
  L2_2 = L2_2(L3_2)
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.ObjectProximity
  L6_2 = {}
  L7_2 = Player
  L7_2 = L7_2.GetPrimaryCharacter
  L7_2 = L7_2()
  L8_2 = L2_2
  L9_2 = "<"
  L10_2 = 10
  L11_2 = false
  L12_2 = false
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L6_2[5] = L11_2
  L6_2[6] = L12_2
  L7_2 = MeleeBashTute
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.ObjectDeath
  L6_2 = {}
  L7_2 = A1_2
  L6_2[1] = L7_2
  L7_2 = RemoveBashTute
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
end

MeleeBashTuteSetup = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.HideMessage
  L2_2 = false
  L3_2 = "VzaCon001"
  L1_2(L2_2, L3_2)
  L1_2 = oWaitForWeapon
  L2_2 = L1_2
  L1_2 = L1_2.Complete
  L1_2(L2_2)
end

RemoveBashTute = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.ShowMessage
  L2_2 = "[Tutorial.Melee]"
  L3_2 = false
  L4_2 = "VzaCon001"
  L1_2(L2_2, L3_2, L4_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 5
  L4_2[1] = L5_2
  L5_2 = MrxTutorialManager
  L5_2 = L5_2.HideMessage
  L6_2 = {}
  L7_2 = false
  L8_2 = "VzaCon001"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

MeleeBashTute = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = {}
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "vza_beachguard_1"
  L2_2 = L2_2(L3_2)
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "vza_beachguard_2"
  L3_2 = L3_2(L4_2)
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "vza_beachguard_3"
  L4_2 = L4_2(L5_2)
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "vza_beachguard_4"
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L1_2[7] = L8_2
  tSquad = L1_2
  L1_2 = false
  L2_2 = pairs
  L3_2 = tSquad
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = Object
    L7_2 = L7_2.IsAlive
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    if L7_2 then
      L1_2 = true
      break
    end
  end
  if L1_2 then
    L2_2 = KillBeachGuards
    L3_2 = A0_2
    L2_2(L3_2)
  else
    L2_2 = DestroyGateSetup
    L3_2 = A0_2
    L2_2(L3_2)
  end
end

BeachGuardsCheck = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "VZA001: EliminateBeachGuardsVZ"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = {}
  L5_2 = "vza_beachguard_1"
  L6_2 = "vza_beachguard_2"
  L7_2 = "vza_beachguard_3"
  L8_2 = "vza_beachguard_4"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[VzaCon001.Objectives.003]"
  L4_2 = {}
  L5_2 = "Fiona-In-Mission-Contract-Vz01-152"
  L6_2 = 0.5
  L7_2 = {}
  L7_2.mattias = "Mattias-In-Mission-Contract-Vz01-153"
  L7_2.jennifer = "Jennifer-In-Mission-Contract-Vz01-154"
  L7_2.chris = "Chris-In-Mission-Contract-Vz01-155"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L3_2.vVoSeqOnAdd = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.DestroyGateSetup
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
  oBeachEncounter = L1_2
  L1_2 = SetupShowShootTutorial
  L2_2 = A0_2
  L1_2(L2_2)
end

KillBeachGuards = L0_1

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
  L7_2 = "vza001_gate"
  L6_2 = L6_2(L7_2)
  L7_2 = "<"
  L8_2 = 125
  L9_2 = false
  L10_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L5_2 = ShowShootTutorial
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

SetupShowShootTutorial = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.ShowMessage
  L2_2 = [[
[Tutorial.Shoot]
[Tutorial.Reload] ]]
  L3_2 = false
  L4_2 = "VzaCon001"
  L1_2(L2_2, L3_2, L4_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 10
  L4_2[1] = L5_2
  L5_2 = MrxTutorialManager
  L5_2 = L5_2.HideMessage
  L6_2 = {}
  L7_2 = false
  L8_2 = "VzaCon001"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 12
  L4_2[1] = L5_2
  L5_2 = MrxTutorialManager
  L5_2 = L5_2.ShowMessage
  L6_2 = {}
  L7_2 = [=[
[Tutorial.Zoom]
[Tutorial.SwitchWeapons]]=]
  L8_2 = false
  L9_2 = "VzaCon001"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

ShowShootTutorial = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.HideMessage
  L2_2 = false
  L3_2 = "VzaCon001"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 2
  L4_2[1] = L5_2
  L5_2 = MrxTutorialManager
  L5_2 = L5_2.ShowMessage
  L6_2 = {}
  L7_2 = "[Tutorial.OpenPDA]"
  L8_2 = false
  L9_2 = "VzaCon001"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "PDA Open"
  
  function L6_2(A0_3)
    local L1_3, L2_3
    L1_3 = Player
    L1_3 = L1_3.GetLocalPlayer
    L1_3 = L1_3()
    L2_3 = A0_3.uPlayer
    L1_3 = L1_3 == L2_3
    return L1_3
  end
  
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = GatedPDAObjective
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

GatedPDAObjectiveSetup = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 0.5
  L6_2 = true
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = {}
  L7_2 = "Fiona-In-Mission-Contract-Vz01-242"
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "PDA Close"
  
  function L6_2(A0_3)
    local L1_3, L2_3
    L1_3 = uPlayer
    L2_3 = A0_3[1]
    L1_3 = L1_3 == L2_3
    return L1_3
  end
  
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = DestroyGateSetupTwo
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

GatedPDAObjective = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = DestroyGate
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = RemoveGrenadeHint
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 1
  L4_2[1] = L5_2
  L5_2 = DestroyGateSetupVO
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

DestroyGateSetup = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Vz01-208"
  L4_2 = 0.5
  L5_2 = "Fiona-In-Mission-Contract-Vz01-240"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 10
  L4_2[1] = L5_2
  L5_2 = GatedPDAObjectiveSetup
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

DestroyGateSetupVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = RemoveGrenadeHint
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Vz01-209"
  L4_2 = 0.5
  L5_2 = "VZSoldier-In-Mission-Contract-Vz01-210"
  L6_2 = 0.5
  L7_2 = "Fiona-In-Mission-Contract-Vz01-211"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 13
  L4_2[1] = L5_2
  L5_2 = ShowGateTutorial
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 13
  L4_2[1] = L5_2
  L5_2 = AddFreebies
  L6_2 = {}
  L7_2 = "self"
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 10
  L4_2[1] = L5_2
  L5_2 = ConfirmationFlyby
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

DestroyGateSetupTwo = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.HideMessage
  L2_2 = false
  L3_2 = "VzaCon001"
  L1_2(L2_2, L3_2)
  L1_2 = Object
  L1_2 = L1_2.IsAlive
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "vza001_gate"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.CreateChild
    L3_2 = {}
    L3_2.sName = "VZA001: DestroyGate"
    L3_2.sModuleName = "MrxTaskObjectiveDestroy"
    L4_2 = {}
    L5_2 = "vza001_gate"
    L4_2[1] = L5_2
    L3_2.vTgtInclude = L4_2
    L3_2.sDspShortDesc = "[VzaCon001.Objectives.005]"
    L4_2 = {}
    L5_2 = {}
    L6_2 = MrxTutorialManager
    L6_2 = L6_2.HideMessage
    L7_2 = {}
    L8_2 = false
    L9_2 = "VzaCon001"
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L6_2 = {}
    L7_2 = PostGate
    L8_2 = {}
    L9_2 = A0_2
    L8_2[1] = L9_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L4_2[1] = L5_2
    L4_2[2] = L6_2
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
    oDestroyGate = L1_2
  else
    L1_2 = PostGate
    L2_2 = A0_2
    L1_2(L2_2)
  end
end

DestroyGate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.ShowMessage
  L2_2 = [=[
[Tutorial.SupportMenu]
[Tutorial.UseSupport]]=]
  L3_2 = false
  L4_2 = "VzaCon001"
  L1_2(L2_2, L3_2, L4_2)
end

ShowGateTutorial = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxAchievements
  L1_2 = L1_2.NetGrantAchievement
  L2_2 = "ACHIEVEMENT_SCHOOLS_OUT"
  L1_2(L2_2)
  L1_2 = FirstCheckpoint
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = MrxMusic
  L1_2 = L1_2.StopSpecialMusic
  L1_2()
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 3
  L4_2[1] = L5_2
  
  function L5_2()
    local L0_3, L1_3
    L0_3 = MrxMusic
    L0_3 = L0_3.PlaySpecialMusic
    L1_3 = "Mu_nomission_jungle_threat_01"
    L0_3(L1_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 3
  L4_2[1] = L5_2
  L5_2 = CarmonaInHillsVO
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 8
  L4_2[1] = L5_2
  L5_2 = GetToFirstWaypoint
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

PostGate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Vz01-32"
  L2_2[1] = L3_2
  L1_2(L2_2)
end

CarmonaInHillsVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.ShowMessage
  L2_2 = "[Tutorial.Sprint]"
  L3_2 = false
  L4_2 = "VzaCon001"
  L1_2(L2_2, L3_2, L4_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 6
  L4_2[1] = L5_2
  L5_2 = MrxTutorialManager
  L5_2 = L5_2.HideMessage
  L6_2 = {}
  L7_2 = false
  L8_2 = "VzaCon001"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

SprintTutorial = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = {}
  L3_2.mattias = "Mattias-In-Mission-Contract-Vz01-167"
  L3_2.jennifer = "Jennifer-In-Mission-Contract-Vz01-168"
  L3_2.chris = "Chris-In-Mission-Contract-Vz01-169"
  L4_2 = "Fiona-In-Mission-Contract-Vz01-50"
  L5_2 = "Fiona-In-Mission-Job-Chi10-08"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L1_2(L2_2)
end

FirstGateDestroyedVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = MrxSupportData
  L1_2 = L1_2.RemoveFreebie
  L2_2 = "VzaCon01_SatBomb"
  L1_2(L2_2)
  L1_2 = SprintTutorial
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = SetupAirstrikeEvent
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "VZA001: GetToFirstWaypoint"
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2 = Player
  L4_2 = L4_2.GetAnyCharacter
  L4_2 = L4_2()
  L3_2.vTgtInclude = L4_2
  L3_2.vDestLoc = "loc_vza_waypoint1"
  L3_2.vDestRegion = "region_vza_waypoint1"
  L3_2.bStop = false
  L3_2.bXZOnly = true
  L3_2.sDspShortDesc = "[VzaCon001.Objectives.006]"
  L4_2 = {}
  L5_2 = "Fiona-In-Mission-Contract-Vz01-227"
  L4_2[1] = L5_2
  L3_2.vVoSeqOnAdd = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.KillVillageGuards_Failsafe
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
  oGetToFirstWaypoint = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 5
  L4_2[1] = L5_2
  L5_2 = MrxTutorialManager
  L5_2 = L5_2.HideMessage
  L6_2 = {}
  L7_2 = false
  L8_2 = "VzaCon001"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

GetToFirstWaypoint = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Object
  L1_2 = L1_2.IsAlive
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "vza_villageguard_1"
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  if not L1_2 then
    L1_2 = Object
    L1_2 = L1_2.IsAlive
    L2_2 = Pg
    L2_2 = L2_2.GetGuidByName
    L3_2 = "vza_villageguard_2"
    L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
    if not L1_2 then
      L1_2 = Object
      L1_2 = L1_2.IsAlive
      L2_2 = Pg
      L2_2 = L2_2.GetGuidByName
      L3_2 = "vza_villageguard_3"
      L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
      L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
      if not L1_2 then
        goto lbl_32
      end
    end
  end
  L1_2 = KillVillageGuards
  L2_2 = A0_2
  L1_2(L2_2)
  goto lbl_46
  ::lbl_32::
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Vz01-222"
  L4_2 = 0.5
  L5_2 = {}
  L5_2.mattias = "Mattias-In-Mission-Contract-Vz01-181"
  L5_2.jennifer = "Jennifer-In-Mission-Contract-Vz01-182"
  L5_2.chris = "Chris-In-Mission-Contract-Vz01-183"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L1_2(L2_2)
  L1_2 = DeliverCar
  L2_2 = A0_2
  L1_2(L2_2)
  ::lbl_46::
end

KillVillageGuards_Failsafe = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "VZA001: EliminateVillageGuards"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = {}
  L5_2 = "vza_villageguard_1"
  L6_2 = "vza_villageguard_2"
  L7_2 = "vza_villageguard_3"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[VzaCon001.Objectives.003]"
  L4_2 = {}
  L5_2 = "Fiona-In-Mission-Contract-Vz01-234"
  L4_2[1] = L5_2
  L3_2.vVoSeqOnAdd = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.SetupDeliverCar
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
  oKillVillageGuards = L1_2
end

KillVillageGuards = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Vz01-235"
  L2_2[1] = L3_2
  L1_2(L2_2)
  L1_2 = DeliverCar
  L2_2 = A0_2
  L1_2(L2_2)
end

SetupDeliverCar = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "loc_vza_cardrop"
  L1_2 = L1_2(L2_2)
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "loc_vza_helispawn2"
  L5_2 = L5_2(L6_2)
  L6_2 = Object
  L6_2 = L6_2.GetPosition
  L7_2 = L5_2
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  L9_2 = MrxCopterDrop
  L9_2 = L9_2.Create
  L10_2 = "VZF"
  L11_2 = "M151 Softtop (VZ)"
  L12_2 = L2_2
  L13_2 = L3_2
  L14_2 = L4_2
  L15_2 = false
  L16_2 = L6_2
  L17_2 = L7_2
  L18_2 = L8_2
  L9_2, L10_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  L11_2 = WaitForCar
  L12_2 = A0_2
  L13_2 = L10_2
  L11_2(L12_2, L13_2)
end

DeliverCar = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "VZA001: Wait for Car"
  L4_2.sModuleName = "MrxTaskObjectiveDeliver"
  L5_2 = {}
  L6_2 = A1_2
  L5_2[1] = L6_2
  L4_2.vTgtInclude = L5_2
  L4_2.vDestLoc = "loc_vza_cardrop"
  L4_2.vDestRegion = "region_vza_getincar"
  L4_2.bStop = false
  L4_2.bXZOnly = false
  L4_2.sDspShortDesc = "[VzaCon001.Objectives.007]"
  L5_2 = {}
  L6_2 = {}
  L7_2 = A0_2.GetToSecondWaypoint
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnComplete = L5_2
  L5_2 = {}
  L6_2 = {}
  L7_2 = A0_2.GetToSecondWaypoint
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnCancel = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  oWaitForCar = L2_2
end

WaitForCar = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "VZA001: GetToSecondWaypoint"
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2 = Player
  L4_2 = L4_2.GetAnyCharacter
  L4_2 = L4_2()
  L3_2.vTgtInclude = L4_2
  L3_2.vDestLoc = "loc_vza_waypoint2"
  L3_2.vDestRegion = "region_vza_waypoint2"
  L3_2.bStop = false
  L3_2.bXZOnly = true
  L3_2.sDspShortDesc = "[VzaCon001.Objectives.006]"
  L4_2 = {}
  L5_2 = "Fiona-In-Mission-Contract-Vz01-236"
  L4_2[1] = L5_2
  L3_2.vVoSeqOnAdd = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.DestroySecondGate
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
  oGetToSecondWaypoint = L1_2
end

GetToSecondWaypoint = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = 2
  iGate = L1_2
  L1_2 = Object
  L1_2 = L1_2.IsAlive
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "vza001_gate2"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.CreateChild
    L3_2 = {}
    L3_2.sName = "VZA001: DestroySecondGate"
    L3_2.sModuleName = "MrxTaskObjectiveDestroy"
    L4_2 = {}
    L5_2 = "vza001_gate2"
    L4_2[1] = L5_2
    L3_2.vTgtInclude = L4_2
    L3_2.sDspShortDesc = "[VzaCon001.Objectives.005]"
    L4_2 = {}
    L5_2 = "Fiona-In-Mission-Contract-Vz01-225"
    L6_2 = {}
    L6_2.mattias = "Mattias-In-Mission-Contract-Vz01-157"
    L6_2.jennifer = "Jennifer-In-Mission-Contract-Vz01-158"
    L6_2.chris = "Chris-In-Mission-Contract-Vz01-159"
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L3_2.vVoSeqOnAdd = L4_2
    L4_2 = {}
    L5_2 = {}
    L6_2 = DeliverTank
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
    oDestroySecondGate = L1_2
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = 5
    L4_2[1] = L5_2
    L5_2 = ShowGateTutorial
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = 5
    L4_2[1] = L5_2
    L5_2 = AddFreebies
    L6_2 = {}
    L7_2 = "self"
    L6_2[1] = L7_2
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  else
    L1_2 = DeliverTank
    L2_2 = A0_2
    L1_2(L2_2)
  end
end

DestroySecondGate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L1_2 = MrxSupportData
  L1_2 = L1_2.RemoveFreebie
  L2_2 = "VzaCon01_SatBomb"
  L1_2(L2_2)
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "loc_vza_amxdrop"
  L1_2 = L1_2(L2_2)
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "loc_vza_helispawn3"
  L5_2 = L5_2(L6_2)
  L6_2 = Object
  L6_2 = L6_2.GetPosition
  L7_2 = L5_2
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  L9_2 = MrxCopterDrop
  L9_2 = L9_2.Create
  L10_2 = "VZHF"
  L11_2 = "AMX30"
  L12_2 = L2_2
  L13_2 = L3_2
  L14_2 = L4_2
  L15_2 = false
  L16_2 = L6_2
  L17_2 = L7_2
  L18_2 = L8_2
  L9_2, L10_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  L11_2 = MrxVoSequence
  L11_2 = L11_2.Start
  L12_2 = {}
  L13_2 = "Fiona-In-Mission-Job-All10-06"
  L12_2[1] = L13_2
  L11_2(L12_2)
  L12_2 = A0_2
  L11_2 = A0_2._CreateEvent
  L13_2 = Event
  L13_2 = L13_2.TimerRelative
  L14_2 = {}
  L15_2 = 2
  L14_2[1] = L15_2
  L15_2 = WaitForTank
  L16_2 = {}
  L17_2 = A0_2
  L18_2 = L10_2
  L16_2[1] = L17_2
  L16_2[2] = L18_2
  L11_2(L12_2, L13_2, L14_2, L15_2, L16_2)
end

DeliverTank = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "VZA001: Wait for Tank"
  L4_2.sModuleName = "MrxTaskObjectiveDeliver"
  L5_2 = {}
  L6_2 = A1_2
  L5_2[1] = L6_2
  L4_2.vTgtInclude = L5_2
  L4_2.vDestLoc = "loc_vza_amxdrop"
  L4_2.vDestRegion = "region_vza_amxdrop"
  L4_2.bStop = false
  L4_2.bXZOnly = false
  L4_2.sDspShortDesc = "[VzaCon001.Objectives.008]"
  L5_2 = {}
  L6_2 = "Fiona-In-Mission-Contract-Vz01-218"
  L7_2 = 0.5
  L8_2 = {}
  L8_2.mattias = "Mattias-In-Mission-Contract-Vz01-232"
  L8_2.jennifer = "Jennifer-In-Mission-Contract-Vz01-230"
  L8_2.chris = "Chris-In-Mission-Contract-Vz01-229"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L4_2.vVoSeqOnAdd = L5_2
  L5_2 = {}
  L6_2 = {}
  L7_2 = A0_2.PauseBeforeThirdWaypoint
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnComplete = L5_2
  L5_2 = {}
  L6_2 = {}
  L7_2 = A0_2.PauseBeforeThirdWaypoint
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnCancel = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  oWaitForTank = L2_2
end

WaitForTank = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 2
  L4_2[1] = L5_2
  L5_2 = GetToThirdWaypoint
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

PauseBeforeThirdWaypoint = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = SecondCheckpoint
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "VZA001: GetToThirdWaypoint"
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2 = Player
  L4_2 = L4_2.GetAnyCharacter
  L4_2 = L4_2()
  L3_2.vTgtInclude = L4_2
  L3_2.vDestLoc = "loc_vza_waypoint3"
  L3_2.vDestRegion = "region_vza_waypoint3"
  L3_2.bStop = false
  L3_2.bXZOnly = true
  L3_2.sDspShortDesc = "[VzaCon001.Objectives.006]"
  L4_2 = {}
  L5_2 = "Fiona-In-Mission-Contract-Vz01-227"
  L4_2[1] = L5_2
  L3_2.vVoSeqOnAdd = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.GetToFourthWaypoint
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
  oGetToThirdWaypoint = L1_2
end

GetToThirdWaypoint = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "VZA001: GetToFourthWaypoint"
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2 = Player
  L4_2 = L4_2.GetAnyCharacter
  L4_2 = L4_2()
  L3_2.vTgtInclude = L4_2
  L3_2.vDestLoc = "loc_vza_waypoint4"
  L3_2.vDestRegion = "region_brokenbridge"
  L3_2.bStop = false
  L3_2.bXZOnly = true
  L3_2.sDspShortDesc = "[VzaCon001.Objectives.006]"
  L4_2 = {}
  L5_2 = "Fiona-In-Mission-Contract-Vz01-227"
  L4_2[1] = L5_2
  L3_2.vVoSeqOnAdd = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.RescueCarmona
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
  oGetToFourthWaypoint = L1_2
end

GetToFourthWaypoint = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = AddFreebies
  L2_2 = "self"
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "VZA001: Rescue Carmona"
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2 = Player
  L4_2 = L4_2.GetAnyCharacter
  L4_2 = L4_2()
  L3_2.vTgtInclude = L4_2
  L3_2.vDestLoc = "loc_vza_hotel"
  L3_2.vDestRegion = "region_vza_youwin"
  L3_2.bStop = false
  L3_2.bXZOnly = true
  L3_2.sDspShortDesc = "[VzaCon001.Objectives.009]"
  L4_2 = {}
  L5_2 = "Fiona-In-Mission-Contract-Vz01-244"
  L4_2[1] = L5_2
  L3_2.vVoSeqOnAdd = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.Complete
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
  oRescueCarmona = L1_2
end

RescueCarmona = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.ShowMessage
  L2_2 = "[Tutorial.Explosive]"
  L3_2 = false
  L4_2 = "VzaCon001"
  L1_2(L2_2, L3_2, L4_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 10
  L4_2[1] = L5_2
  L5_2 = MrxTutorialManager
  L5_2 = L5_2.EndCustomTutorial
  L6_2 = {}
  L7_2 = "VzaCon001"
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

GrenadeHint = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.HideMessage
  L2_2 = false
  L3_2 = "VzaCon001"
  L1_2(L2_2, L3_2)
end

RemoveGrenadeHint = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Ai
  L1_2 = L1_2.Goal
  L2_2 = {}
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "brokenbridge_mook"
  L3_2 = L3_2(L4_2)
  L2_2.AIGuid = L3_2
  L2_2.Goal = "PathMove"
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "path_brokenbridge"
  L3_2 = L3_2(L4_2)
  L2_2.Target = L3_2
  L2_2.Haste = 1
  L2_2.Mode = "OneWay"
  L2_2.Priority = "hiPri"
  L1_2(L2_2)
end

BrokenBridgeEncounter = L0_1

function L0_1(A0_2)
  local L1_2
end

BrokenBridgeEncounterComplete = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "Carmona_VzaCon001"
  L1_2 = L1_2(L2_2)
  L2_2 = Human
  L2_2 = L2_2.Inventory
  L2_2 = L2_2.GetAllWeapons
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = Human
    L8_2 = L8_2.Inventory
    L8_2 = L8_2.DropWeapon
    L9_2 = L1_2
    L10_2 = L7_2
    L8_2(L9_2, L10_2)
    L8_2 = Object
    L8_2 = L8_2.Remove
    L9_2 = L7_2
    L8_2(L9_2)
  end
end

DropCarmonaWeapons = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "Satellite Targetting Start"
  
  function L6_2()
    local L0_3, L1_3
    L0_3 = true
    return L0_3
  end
  
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = AirstrikeMinigame
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

SetupAirstrikeEvent = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = 1
  iInsideMinigame = L1_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.ShowMessage
  L2_2 = [=[
[Tutorial.MoveCamera]
[Tutorial.ConfirmTarget]]=]
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "Satellite Minigame Start"
  
  function L6_2()
    local L0_3, L1_3
    L0_3 = true
    return L0_3
  end
  
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = AirstrikeMinigame_Start
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "Satellite Targetting Success"
  
  function L6_2()
    local L0_3, L1_3
    L0_3 = true
    return L0_3
  end
  
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = AirstrikeMinigame_Success
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "Satellite Targetting Cancelled"
  
  function L6_2()
    local L0_3, L1_3
    L0_3 = true
    return L0_3
  end
  
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = AirstrikeMinigame_Cancel
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

AirstrikeMinigame = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.ShowMessage
  L2_2 = "[Tutorial.SatMinigame]"
  L1_2(L2_2)
end

AirstrikeMinigame_Start = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 10
  L4_2[1] = L5_2
  L5_2 = AirstrikeMinigame_GateCheck
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = 0
  iInsideMinigame = L1_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.HideMessage
  L2_2 = false
  L3_2 = "VzaCon001"
  L1_2(L2_2, L3_2)
end

AirstrikeMinigame_Success = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Vz01-163"
  L2_2[1] = L3_2
  L1_2(L2_2)
end

AirstrikeMinigame_SuccessVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Vz01-213"
  L2_2[1] = L3_2
  L1_2(L2_2)
end

AirstrikeMinigame_InsideVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = iGate
  if L1_2 == 1 then
    L1_2 = "vza001_gate"
    uGate = L1_2
  else
    L1_2 = "vza001_gate2"
    uGate = L1_2
  end
  L1_2 = Object
  L1_2 = L1_2.IsAlive
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = uGate
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  if L1_2 then
    L1_2 = {}
    L2_2 = "Fiona-In-Mission-Contract-Vz01-170"
    L3_2 = "Fiona-In-Mission-Contract-Vz01-171"
    L4_2 = "Fiona-In-Mission-Contract-Vz01-172"
    L5_2 = "Fiona-In-Mission-Contract-Vz01-173"
    L6_2 = "Fiona-In-Mission-Contract-Vz01-174"
    L1_2[1] = L2_2
    L1_2[2] = L3_2
    L1_2[3] = L4_2
    L1_2[4] = L5_2
    L1_2[5] = L6_2
    L2_2 = MrxVoSequence
    L2_2 = L2_2.Start
    L3_2 = {}
    L4_2 = {}
    L5_2 = MrxUtil
    L5_2 = L5_2.GetRandomTableElement
    L6_2 = L1_2
    L5_2 = L5_2(L6_2)
    L6_2 = uChar
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L3_2[1] = L4_2
    L2_2(L3_2)
    L2_2 = MrxSupport
    L2_2 = L2_2.PlayRandomVOCue
    L3_2 = tVO_GateNag
    L2_2(L3_2)
    L2_2 = AddFreebies
    L3_2 = A0_2
    L2_2(L3_2)
    L2_2 = ShowGateTutorial
    L3_2 = A0_2
    L2_2(L3_2)
    L3_2 = A0_2
    L2_2 = A0_2._CreateEvent
    L4_2 = Event
    L4_2 = L4_2.ScriptEvent
    L5_2 = {}
    L6_2 = "Satellite Targetting Start"
    
    function L7_2()
      local L0_3, L1_3
      L0_3 = true
      return L0_3
    end
    
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L6_2 = AirstrikeMinigame
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  end
end

AirstrikeMinigame_GateCheck = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "Satellite Targetting Start"
  
  function L6_2()
    local L0_3, L1_3
    L0_3 = true
    return L0_3
  end
  
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = AirstrikeMinigame
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = 0
  iInsideMinigame = L1_2
  L1_2 = Hud
  L1_2 = L1_2.Satellite
  L2_2 = L1_2
  L1_2 = L1_2.SetTutorialText
  L3_2 = {}
  L3_2.sText = nil
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 5
  L4_2[1] = L5_2
  L5_2 = ShowGateTutorial
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

AirstrikeMinigame_Cancel = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = MrxPlayer
  L1_2 = L1_2.IsInVehicle
  L2_2 = "Tank && !APC"
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = MrxTutorialManager
    L1_2 = L1_2.ShowMessage
    L2_2 = "[Tutorial.SwitchWeapons]"
    L3_2 = false
    L4_2 = "VzaCon001"
    L1_2(L2_2, L3_2, L4_2)
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = 7
    L4_2[1] = L5_2
    L5_2 = MrxTutorialManager
    L5_2 = L5_2.HideMessage
    L6_2 = {}
    L7_2 = false
    L8_2 = "VzaCon001"
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  end
end

TankSwitch = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = MrxPlayer
  L1_2 = L1_2.IsInVehicle
  L2_2 = "Vehicle"
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = MrxTutorialManager
    L1_2 = L1_2.ShowMessage
    L2_2 = "[Tutorial.Handbrake]"
    L3_2 = false
    L4_2 = "VzaCon001"
    L1_2(L2_2, L3_2, L4_2)
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = 5
    L4_2[1] = L5_2
    L5_2 = MrxTutorialManager
    L5_2 = L5_2.HideMessage
    L6_2 = {}
    L7_2 = false
    L8_2 = "VzaCon001"
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  end
end

HandbrakeTutorial = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = MrxSupportData
  L1_2 = L1_2.AddFreebie
  L2_2 = "VzaCon01_SatBomb"
  L3_2 = 1
  L4_2 = nil
  L5_2 = nil
  L6_2 = 1
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

AddFreebies = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = MrxMusic
  L1_2 = L1_2.StopSpecialMusic
  L1_2()
end

StopTheMusic = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "vza_treeattack_1"
  L1_2 = L1_2(L2_2)
  uVehicle = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "vza_treehillpath_2"
  L1_2 = L1_2(L2_2)
  uPath = L1_2
  L1_2 = Vehicle
  L1_2 = L1_2.GetDriver
  L2_2 = uVehicle
  L1_2 = L1_2(L2_2)
  L2_2 = Ai
  L2_2 = L2_2.Goal
  L3_2 = {}
  L3_2.AIGuid = L1_2
  L3_2.Goal = "PathMove"
  L4_2 = uPath
  L3_2.Target = L4_2
  L3_2.Haste = 1
  L3_2.Priority = "HiPri"
  L3_2.Timeout = 0
  L2_2 = L2_2(L3_2)
end

TreeAttack = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = oGetToBeach
  L2_2 = L1_2
  L1_2 = L1_2.Complete
  L1_2(L2_2)
end

BeachBypass = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = {}
  L2_2 = "Vz_State_VzaCon001"
  L3_2 = "vz_state_VzaCon001_Pristine"
  L4_2 = "Vz_State_VzaCon001_CP01"
  L5_2 = "Vz_State_VzaCon001_CP02"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L2_2 = MrxLayerManager
  L2_2 = L2_2.Remove
  L3_2 = L1_2
  L2_2(L3_2)
  L2_2 = {}
  L3_2 = "vz_state_vzacon001_ruined"
  L2_2[1] = L3_2
  tLayersToAdd = L2_2
  L2_2 = MrxLayerManager
  L2_2 = L2_2.Add
  L3_2 = tLayersToAdd
  L2_2(L3_2)
  L2_2 = MrxSupportData
  L2_2 = L2_2.RemoveFreebie
  L3_2 = "VzaCon001_Airstrike"
  L2_2(L3_2)
  L2_2 = MrxSupportData
  L2_2 = L2_2.RemoveFreebie
  L3_2 = "VzaCon01_SatBomb"
  L2_2(L3_2)
  L2_2 = MrxTaskContract
  L2_2 = L2_2.Cleanup
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = MrxFactionManager
  L2_2 = L2_2.DisableReporting
  L3_2 = false
  L2_2(L3_2)
  L2_2 = MrxTutorialManager
  L2_2 = L2_2.HideMessage
  L3_2 = false
  L4_2 = "VzaCon001"
  L2_2(L3_2, L4_2)
end

Cleanup = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = Sound
  L1_2 = L1_2.SetDynamicMusic
  L2_2 = false
  L1_2(L2_2)
  L1_2 = MrxMusic
  L1_2 = L1_2.PlaySpecialMusic
  L2_2 = "mu_nomission_water_explore_01"
  L1_2(L2_2)
end

SetMissionMusic = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = {}
  L2_2 = "Fiona-In-Mission-Contract-Vz01-164"
  L3_2 = "Fiona-In-Mission-Contract-Vz01-165"
  L4_2 = "Fiona-In-Mission-Contract-Vz01-166"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L2_2 = MrxSupport
  L2_2 = L2_2.PlayRandomVOCue
  L3_2 = L1_2
  L2_2(L3_2)
end

VO_GateNag = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = MrxMusic
  L1_2 = L1_2.StopSpecialMusic
  L1_2()
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 3
  L4_2[1] = L5_2
  
  function L5_2()
    local L0_3, L1_3
    L0_3 = MrxMusic
    L0_3 = L0_3.PlaySpecialMusic
    L1_3 = "Mu_nomission_jungle_threat_02"
    L0_3(L1_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

PlayHillMusic = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "VZ001CP01"
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 then
  else
    L2_2 = A0_2
    L1_2 = A0_2._SetFlag
    L3_2 = "VZ001CP01"
    L1_2(L2_2, L3_2)
    L1_2 = _Checkpoint
    L2_2 = {}
    L3_2 = "VZACP01_P1"
    L4_2 = "VZACP01_P2"
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L1_2(L2_2)
  end
end

FirstCheckpoint = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "VZ001CP02"
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 then
  else
    L2_2 = A0_2
    L1_2 = A0_2._SetFlag
    L3_2 = "VZ001CP02"
    L1_2(L2_2, L3_2)
    L1_2 = _Checkpoint
    L2_2 = {}
    L3_2 = "VZACP02_P1"
    L4_2 = "VZACP02_P2"
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L1_2(L2_2)
  end
end

SecondCheckpoint = L0_1
