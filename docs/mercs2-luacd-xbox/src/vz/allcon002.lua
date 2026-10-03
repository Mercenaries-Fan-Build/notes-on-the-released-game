local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "DangerousBuilding"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = 0
NETEVENT_STARTEMITTERS = L0_1
L0_1 = 1
NETEVENT_STARTPLUMES = L0_1
L0_1 = 2
NETEVENT_CLEANSMOKE = L0_1
L0_1 = 3
NETEVENT_AIRSTRUCK = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = {}
  L3_2 = "vz_state_car_shanty_act1"
  L4_2 = "vz_state_staging_all_HQ"
  L5_2 = "vz_state_car_city_act1"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L3_2 = {}
  L4_2 = "Vz_State_AllCon002"
  L3_2[1] = L4_2
  L5_2 = A0_2
  L4_2 = A0_2._GetFlag
  L6_2 = "BoatsKilled"
  L4_2 = L4_2(L5_2, L6_2)
  if L4_2 then
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L2_2
    L6_2 = "vz_State_AllCon002_Boats"
    L4_2(L5_2, L6_2)
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L2_2
    L6_2 = "vz_State_AllCon002_mlrs"
    L4_2(L5_2, L6_2)
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L3_2
    L6_2 = "vz_State_AllCon002_officers"
    L4_2(L5_2, L6_2)
  else
    L5_2 = A0_2
    L4_2 = A0_2._GetFlag
    L6_2 = "MLRSkilled"
    L4_2 = L4_2(L5_2, L6_2)
    if L4_2 then
      L4_2 = table
      L4_2 = L4_2.insert
      L5_2 = L2_2
      L6_2 = "vz_State_AllCon002_mlrs"
      L4_2(L5_2, L6_2)
      L4_2 = table
      L4_2 = L4_2.insert
      L5_2 = L3_2
      L6_2 = "vz_State_AllCon002_Boats"
      L4_2(L5_2, L6_2)
    else
      L4_2 = table
      L4_2 = L4_2.insert
      L5_2 = L3_2
      L6_2 = "vz_State_AllCon002_mlrs"
      L4_2(L5_2, L6_2)
    end
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
end

LoadAssets = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = NETEVENT_STARTEMITTERS
  if A0_2 == L2_2 then
    L2_2 = Pop
    L3_2 = A1_2[1]
    L4_2 = A1_2[2]
    L5_2 = A1_2[3]
    L6_2 = A1_2[4]
    L2_2(L3_2, L4_2, L5_2, L6_2)
  else
    L2_2 = NETEVENT_STARTPLUMES
    if A0_2 == L2_2 then
      L2_2 = Plumes
      L3_2 = A1_2[1]
      L4_2 = A1_2[2]
      L5_2 = A1_2[3]
      L6_2 = A1_2[4]
      L2_2(L3_2, L4_2, L5_2, L6_2)
    else
      L2_2 = NETEVENT_CLEANSMOKE
      if A0_2 == L2_2 then
        L2_2 = SmokeClean
        L2_2()
      else
        L2_2 = NETEVENT_AIRSTRUCK
        if A0_2 == L2_2 then
          L2_2 = AirStriked
          L3_2 = A1_2[1]
          L4_2 = A1_2[2]
          L5_2 = A1_2[3]
          L2_2(L3_2, L4_2, L5_2)
        end
      end
    end
  end
end

NetEventCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = {}
  _tSmokeParticleObjects = L1_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = 0
  nStrike = L1_2
  L1_2 = 100
  nCaracasLife = L1_2
  L1_2 = 3
  nAAalive = L1_2
  L1_2 = 1
  bBombard = L1_2
  L1_2 = 1
  nStrikeFrequency = L1_2
  L1_2 = 4
  uANTalk = L1_2
  L1_2 = 0
  uShellVoPlayed = L1_2
  L1_2 = 2
  nDamMod = L1_2
  L1_2 = Flybys
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 15
  L4_2[1] = L5_2
  L5_2 = SetupANTalker
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "BoatsKilled"
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 then
    L1_2 = Obj4_Verify
    L2_2 = A0_2
    L1_2(L2_2)
  else
    L2_2 = A0_2
    L1_2 = A0_2._GetFlag
    L3_2 = "MLRSkilled"
    L1_2 = L1_2(L2_2, L3_2)
    if L1_2 then
      L2_2 = A0_2
      L1_2 = A0_2._GetFlag
      L3_2 = "MLRSkilled"
      L1_2 = L1_2(L2_2, L3_2)
      nCaracasLife = L1_2
      L1_2 = DisplayCaracasHealth
      L2_2 = A0_2
      L1_2(L2_2)
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = "Fiona-In-Mission-Contract-All02-28"
      L4_2 = {}
      L5_2 = Obj3_BoatAA
      L6_2 = {}
      L7_2 = A0_2
      L6_2[1] = L7_2
      L4_2[1] = L5_2
      L4_2[2] = L6_2
      L2_2[1] = L3_2
      L2_2[2] = L4_2
      L1_2(L2_2)
    else
      L1_2 = DestroyMLRS
      L2_2 = A0_2
      L1_2(L2_2)
    end
  end
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L1_2 = {}
  L2_2 = "Fiona-Banter-Contract-All01-01"
  L3_2 = {}
  L3_2.mattias = "mattias-Banter-Contract-All01-28"
  L3_2.jennifer = "jennifer-Banter-Contract-All01-30"
  L3_2.chris = "chris-Banter-Contract-All01-29"
  L4_2 = "Fiona-In-Mission-Contract-All02-22"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "DestroyChinaAA"
  L4_2.sModuleName = "MrxTaskObjectiveDestroy"
  L5_2 = {}
  L6_2 = "Obj1_A"
  L7_2 = "Obj1_B"
  L8_2 = "Obj1_C"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L4_2.vTgtInclude = L5_2
  L4_2.vVoSeqOnAdd = L1_2
  L4_2.sDspShortDesc = "[AllCon002.Objectives.001]"
  L5_2 = {}
  L6_2 = {}
  L7_2 = AADestroyed
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnPartComplete = L5_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._SetFlag
    L2_3 = "MLRSkilled"
    L3_3 = nCaracasLife
    L0_3(L1_3, L2_3, L3_3)
    L0_3 = _Checkpoint
    L1_3 = {}
    L2_3 = "Loc_All002_Ckpt_1p1"
    L3_3 = "Loc_All002_Ckpt_1p2"
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L0_3(L1_3)
    L0_3 = MrxLayerManager
    L0_3 = L0_3.Add
    L1_3 = {}
    L2_3 = "vz_State_AllCon002_Boats"
    L1_3[1] = L2_3
    L0_3(L1_3)
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-All02-28"
    L3_3 = {}
    L4_3 = Obj3_BoatAA
    L5_3 = {}
    L6_3 = A0_2
    L5_3[1] = L6_3
    L3_3[1] = L4_3
    L3_3[2] = L5_3
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L0_3(L1_3)
  end
  
  L4_2.fOnComplete = L5_2
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
  L2_2(L3_2, L4_2)
  L2_2 = DisplayCaracasHealth
  L3_2 = A0_2
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 5
  L5_2[1] = L6_2
  L6_2 = Obj1_Bombard
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = "A"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 10
  L5_2[1] = L6_2
  L6_2 = Obj1_Bombard
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = "B"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 20
  L5_2[1] = L6_2
  L6_2 = Obj1_Bombard
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = "C"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "Obj1_A"
  L2_2 = L2_2(L3_2)
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectPhysicsEvent
  L5_2 = {}
  L6_2 = L2_2
  L7_2 = "VehicleSinking"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = LauncherSunk
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = L2_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "Obj1_B"
  L3_2 = L3_2(L4_2)
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.ObjectPhysicsEvent
  L6_2 = {}
  L7_2 = L3_2
  L8_2 = "VehicleSinking"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = LauncherSunk
  L8_2 = {}
  L9_2 = A0_2
  L10_2 = L3_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "Obj1_C"
  L4_2 = L4_2(L5_2)
  L5_2 = Event
  L5_2 = L5_2.Create
  L6_2 = Event
  L6_2 = L6_2.ObjectPhysicsEvent
  L7_2 = {}
  L8_2 = L4_2
  L9_2 = "VehicleSinking"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L8_2 = LauncherSunk
  L9_2 = {}
  L10_2 = A0_2
  L11_2 = L4_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = 1
  L7_2 = 5
  L8_2 = 1
  for L9_2 = L6_2, L7_2, L8_2 do
    L10_2 = Pg
    L10_2 = L10_2.GetGuidByName
    L11_2 = "loc_Rockets_"
    L12_2 = L9_2
    L11_2 = L11_2 .. L12_2
    L10_2 = L10_2(L11_2)
    L11_2 = Pg
    L11_2 = L11_2.GetGuidByName
    L12_2 = "loc_Rockets_see_"
    L13_2 = L9_2
    L12_2 = L12_2 .. L13_2
    L11_2 = L11_2(L12_2)
    L13_2 = A0_2
    L12_2 = A0_2._CreateEvent
    L14_2 = Event
    L14_2 = L14_2.ObjectProximity
    L15_2 = {}
    L16_2 = L5_2
    L17_2 = L11_2
    L18_2 = "<"
    L19_2 = 65
    L20_2 = false
    L21_2 = true
    L15_2[1] = L16_2
    L15_2[2] = L17_2
    L15_2[3] = L18_2
    L15_2[4] = L19_2
    L15_2[5] = L20_2
    L15_2[6] = L21_2
    L16_2 = MPShelling
    L17_2 = {}
    L18_2 = L10_2
    L19_2 = L11_2
    L20_2 = L9_2
    L17_2[1] = L18_2
    L17_2[2] = L19_2
    L17_2[3] = L20_2
    L12_2(L13_2, L14_2, L15_2, L16_2, L17_2)
  end
  L7_2 = A0_2
  L6_2 = A0_2._CreateEvent
  L8_2 = Event
  L8_2 = L8_2.Boundary
  L9_2 = {}
  L10_2 = Player
  L10_2 = L10_2.GetPrimaryCharacter
  L10_2 = L10_2()
  L11_2 = Pg
  L11_2 = L11_2.GetGuidByName
  L12_2 = "Reg_AllCon002_Strikes"
  L11_2 = L11_2(L12_2)
  L12_2 = "enter"
  L13_2 = false
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L9_2[3] = L12_2
  L9_2[4] = L13_2
  L10_2 = AirstrikesOn
  L11_2 = {}
  L12_2 = A0_2
  L11_2[1] = L12_2
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  eAirstrikes = L6_2
end

DestroyMLRS = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 5
  L5_2[1] = L6_2
  L6_2 = Object
  L6_2 = L6_2.Kill
  L7_2 = {}
  L8_2 = A1_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

LauncherSunk = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = 2
  bBombard = L1_2
  L1_2 = 1
  nDamMod = L1_2
  L1_2 = 3
  nHuangs = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreatePersistentEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 30
  L4_2[1] = L5_2
  L5_2 = DamageCaracas
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  eDamageCarac = L1_2
  L1_2 = eAirstrikes
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eAirstrikes
    L1_2(L2_2)
  end
  L1_2 = eAirstrikes2
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eAirstrikes2
    L1_2(L2_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 2
  L4_2[1] = L5_2
  L5_2 = SetupWreck
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "DestroyBoatChinaAA"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = {}
  L5_2 = "RiverBoat_1"
  L6_2 = "RiverBoat_2"
  L7_2 = "RiverBoat_3"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[AllCon002.Objectives.002]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = BoatDestroyed
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnPartComplete = L4_2
  
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._SetFlag
    L2_3 = "BoatsKilled"
    L0_3(L1_3, L2_3)
    L0_3 = _Checkpoint
    L1_3 = {}
    L2_3 = "Loc_All2_Check2p1"
    L3_3 = "Loc_All2_Check2p2"
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L0_3(L1_3)
    L0_3 = MrxLayerManager
    L0_3 = L0_3.Add
    L1_3 = {}
    L2_3 = "vz_State_AllCon002_officers"
    L1_3[1] = L2_3
    L0_3(L1_3)
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-All02-37"
    L3_3 = "Fiona-In-Mission-Contract-All02-39"
    L4_3 = {}
    L5_3 = Obj4_Verify
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
  L6_2 = A0_2.Cancel
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnCancel = L4_2
  L1_2(L2_2, L3_2)
end

Obj3_BoatAA = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = nHuangs
  L1_2 = L1_2 - 1
  nHuangs = L1_2
  L1_2 = nHuangs
  if L1_2 == 2 then
    L1_2 = MrxVoSequence
    L1_2 = L1_2.Start
    L2_2 = {}
    L3_2 = "Fiona-In-Mission-Contract-All01-23"
    L2_2[1] = L3_2
    L1_2(L2_2)
  else
    L1_2 = nHuangs
    if L1_2 == 1 then
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = "Fiona-In-Mission-MinorContract-Oil04-09"
      L2_2[1] = L3_2
      L1_2(L2_2)
    end
  end
end

BoatDestroyed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Ai
  L1_2 = L1_2.Role
  L2_2 = {}
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "Turncoat"
  L3_2 = L3_2(L4_2)
  L2_2.AIGuid = L3_2
  L2_2.Role = "Idle"
  L2_2.Priority = "hiPri"
  L1_2(L2_2)
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
  L7_2 = "Turncoat"
  L6_2 = L6_2(L7_2)
  L7_2 = "<"
  L8_2 = 35
  L9_2 = false
  L10_2 = true
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L5_2 = RunAway
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = 1
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = eBoatDamage
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eBoatDamage
    L1_2(L2_2)
  end
  L1_2 = eDamageCarac
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eDamageCarac
    L1_2(L2_2)
  end
  L1_2 = eDisplay1
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eDisplay1
    L1_2(L2_2)
  end
  L1_2 = eDisplay2
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eDisplay2
    L1_2(L2_2)
  end
  L1_2 = eDisplay3
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eDisplay3
    L1_2(L2_2)
  end
  L1_2 = 3
  nOfficers = L1_2
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 1
  L1_2(L2_2, L3_2)
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 2
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Verify the Allied turncoat"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = {}
  L5_2 = "Turncoat"
  L6_2 = "Turncoat2"
  L7_2 = "Turncoat3"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[AllCon002.Objectives.003]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = OfficerDown
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnPartComplete = L4_2
  
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-All02-40"
    L3_3 = "Fiona-In-Mission-Contract-All02-41"
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
  L1_2(L2_2, L3_2)
end

Obj4_Verify = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = nOfficers
  L1_2 = L1_2 - 1
  nOfficers = L1_2
  L1_2 = nOfficers
  if L1_2 == 2 then
    L1_2 = MrxVoSequence
    L1_2 = L1_2.Start
    L2_2 = {}
    L3_2 = "Fiona-In-Mission-Contract-All02-38"
    L2_2[1] = L3_2
    L1_2(L2_2)
  else
    L1_2 = nOfficers
    if L1_2 == 1 then
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = "Fiona-In-Mission-Contract-All02-36"
      L2_2[1] = L3_2
      L1_2(L2_2)
    end
  end
end

OfficerDown = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  if 1 < A1_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = uSpot
    L2_2(L3_2)
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = uDistSpot
    L2_2(L3_2)
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = uCloseSpot
    L2_2(L3_2)
  end
  L2_2 = Ai
  L2_2 = L2_2.Goal
  L3_2 = {}
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "Turncoat"
  L4_2 = L4_2(L5_2)
  L3_2.AIGuid = L4_2
  L3_2.Goal = "PathMove"
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "Pa_RunMan_"
  L6_2 = A1_2
  L5_2 = L5_2 .. L6_2
  L4_2 = L4_2(L5_2)
  L3_2.Target = L4_2
  L3_2.Haste = 0.8
  L3_2.Priority = "hiPri"
  L4_2 = RunAwayCheck
  L3_2.Callback = L4_2
  L4_2 = {}
  L5_2 = A0_2
  L6_2 = A1_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L3_2.CallbackData = L4_2
  L2_2(L3_2)
end

RunAway = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  if A3_2 == 0 then
    L4_2 = RunAway
    L5_2 = A0_2
    L6_2 = A1_2
    L4_2(L5_2, L6_2)
  elseif A3_2 == 1 then
    L4_2 = A1_2 + 1
    if L4_2 == 6 then
    else
      L6_2 = A0_2
      L5_2 = A0_2._CreateEvent
      L7_2 = Event
      L7_2 = L7_2.ObjectProximity
      L8_2 = {}
      L9_2 = Player
      L9_2 = L9_2.GetAnyCharacter
      L9_2 = L9_2()
      L10_2 = Pg
      L10_2 = L10_2.GetGuidByName
      L11_2 = "Turncoat"
      L10_2 = L10_2(L11_2)
      L11_2 = "<"
      L12_2 = 20
      L13_2 = false
      L14_2 = true
      L8_2[1] = L9_2
      L8_2[2] = L10_2
      L8_2[3] = L11_2
      L8_2[4] = L12_2
      L8_2[5] = L13_2
      L8_2[6] = L14_2
      L9_2 = SpottedHim
      L10_2 = {}
      L11_2 = A0_2
      L12_2 = L4_2
      L10_2[1] = L11_2
      L10_2[2] = L12_2
      L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
      uDistSpot = L5_2
      L6_2 = A0_2
      L5_2 = A0_2._CreateEvent
      L7_2 = Event
      L7_2 = L7_2.ObjectProximity
      L8_2 = {}
      L9_2 = Player
      L9_2 = L9_2.GetAnyCharacter
      L9_2 = L9_2()
      L10_2 = Pg
      L10_2 = L10_2.GetGuidByName
      L11_2 = "Turncoat"
      L10_2 = L10_2(L11_2)
      L11_2 = "<"
      L12_2 = 5
      L13_2 = false
      L14_2 = true
      L8_2[1] = L9_2
      L8_2[2] = L10_2
      L8_2[3] = L11_2
      L8_2[4] = L12_2
      L8_2[5] = L13_2
      L8_2[6] = L14_2
      L9_2 = RunAway
      L10_2 = {}
      L11_2 = A0_2
      L12_2 = L4_2
      L10_2[1] = L11_2
      L10_2[2] = L12_2
      L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
      uCloseSpot = L5_2
    end
  end
end

RunAwayCheck = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = Object
  L2_2 = L2_2.IsVisible
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "Turncoat"
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  if L2_2 then
    L2_2 = RunAway
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  else
    L3_2 = A0_2
    L2_2 = A0_2._CreateEvent
    L4_2 = Event
    L4_2 = L4_2.TimerRelative
    L5_2 = {}
    L6_2 = 2
    L5_2[1] = L6_2
    L6_2 = SpottedHim
    L7_2 = {}
    L8_2 = A0_2
    L9_2 = A1_2
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
    uSpot = L2_2
  end
end

SpottedHim = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = nAAalive
  L1_2 = L1_2 - 1
  nAAalive = L1_2
  L1_2 = nAAalive
  if L1_2 == 2 then
    L1_2 = MrxVoSequence
    L1_2 = L1_2.Start
    L2_2 = {}
    L3_2 = "Fiona-In-Mission-Contract-All02-29"
    L2_2[1] = L3_2
    L1_2(L2_2)
  else
    L1_2 = nAAalive
    if L1_2 == 1 then
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = "Fiona-In-Mission-Contract-All02-30"
      L2_2[1] = L3_2
      L1_2(L2_2)
    else
      L1_2 = nAAalive
      if L1_2 == 0 then
      end
    end
  end
end

AADestroyed = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = uANTalk
  L2_2 = L2_2 - 1
  uANTalk = L2_2
  L2_2 = uANTalk
  if L2_2 == 3 then
    L2_2 = MrxVoSequence
    L2_2 = L2_2.Start
    L3_2 = {}
    L4_2 = {}
    L5_2 = "AlliedSoldier-In-Mission-Contract-All02-32"
    L6_2 = A1_2[1]
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L3_2[1] = L4_2
    L2_2(L3_2)
  else
    L2_2 = uANTalk
    if L2_2 == 2 then
      L2_2 = MrxVoSequence
      L2_2 = L2_2.Start
      L3_2 = {}
      L4_2 = {}
      L5_2 = "AlliedSoldier-In-Mission-Contract-All02-33"
      L6_2 = A1_2[1]
      L4_2[1] = L5_2
      L4_2[2] = L6_2
      L3_2[1] = L4_2
      L2_2(L3_2)
    else
      L2_2 = uANTalk
      if L2_2 == 1 then
        L2_2 = MrxVoSequence
        L2_2 = L2_2.Start
        L3_2 = {}
        L4_2 = {}
        L5_2 = "AlliedSoldier-In-Mission-Contract-All02-34"
        L6_2 = A1_2[1]
        L4_2[1] = L5_2
        L4_2[2] = L6_2
        L3_2[1] = L4_2
        L2_2(L3_2)
      else
        L2_2 = 4
        uANTalk = L2_2
      end
    end
  end
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 20
  L5_2[1] = L6_2
  L6_2 = SetupANTalker
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

AlliedSpeaks = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = Player
  L2_2 = L2_2.GetPrimaryCharacter
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L2_2()
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.FastCollectHumans
  L6_2 = L1_2
  L7_2 = L2_2
  L8_2 = L3_2
  L9_2 = 15
  L10_2 = "Allied && Human"
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L6_2 = table
  L6_2 = L6_2.getn
  L7_2 = L5_2
  L6_2 = L6_2(L7_2)
  nAnSold = L6_2
  L6_2 = nAnSold
  if 0 < L6_2 then
    L6_2 = AlliedSpeaks
    L7_2 = A0_2
    L8_2 = L5_2
    L6_2(L7_2, L8_2)
  else
    L7_2 = A0_2
    L6_2 = A0_2._CreateEvent
    L8_2 = Event
    L8_2 = L8_2.TimerRelative
    L9_2 = {}
    L10_2 = 15
    L9_2[1] = L10_2
    L10_2 = SetupANTalker
    L11_2 = {}
    L12_2 = A0_2
    L11_2[1] = L12_2
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  end
end

SetupANTalker = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = uAirstrikeOn
  if L1_2 == 1 then
    L1_2 = MPShelling
    L1_2()
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = nStrikeFrequency
    L4_2[1] = L5_2
    L5_2 = AirstrikeThePlayer
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
    eAnotherStrike = L1_2
  end
end

AirstrikeThePlayer = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = 0
  uAirstrikeOn = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetPrimaryCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Reg_AllCon002_Strikes"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = AirstrikesOn
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  eAirstrikes2 = L1_2
end

AirstrikesOff = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = uShellVoPlayed
  if L1_2 == 0 then
    L1_2 = 1
    uShellVoPlayed = L1_2
    L1_2 = MrxVoSequence
    L1_2 = L1_2.Start
    L2_2 = {}
    L3_2 = "Fiona-In-Mission-Contract-All02-26"
    L2_2[1] = L3_2
    L1_2(L2_2)
  end
  L1_2 = 1
  uAirstrikeOn = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetPrimaryCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Reg_AllCon002_Strikes"
  L6_2 = L6_2(L7_2)
  L7_2 = "exit"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = AirstrikesOff
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = AirstrikeThePlayer
  L2_2 = A0_2
  L1_2(L2_2)
end

AirstrikesOn = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "Obj1_"
  L4_2 = A1_2
  L3_2 = L3_2 .. L4_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = Object
    L3_2 = L3_2.IsAwake
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L3_2 = Object
      L3_2 = L3_2.IsPlayerControlled
      L4_2 = L2_2
      L3_2 = L3_2(L4_2)
      if not L3_2 then
        L3_2 = Vehicle
        L3_2 = L3_2.GetDriver
        L4_2 = L2_2
        L3_2 = L3_2(L4_2)
        if L3_2 then
          L4_2 = Vehicle
          L4_2 = L4_2.GetSeatByType
          L5_2 = L2_2
          L6_2 = "p"
          L4_2 = L4_2(L5_2, L6_2)
          uSeat = L4_2
          L4_2 = Vehicle
          L4_2 = L4_2.Usable
          L5_2 = uSeat
          L6_2 = false
          L4_2(L5_2, L6_2)
          L4_2 = Ai
          L4_2 = L4_2.Anchor
          L5_2 = {}
          L5_2.AIGuid = L3_2
          L5_2.AnchorRadius = 0
          L4_2(L5_2)
          L4_2 = Ai
          L4_2 = L4_2.Goal
          L5_2 = {}
          L5_2.AIGuid = L3_2
          L5_2.Goal = "Attack"
          L5_2.Force = true
          L6_2 = Pg
          L6_2 = L6_2.GetGuidByName
          L7_2 = "loc_FireTgt_"
          L8_2 = A1_2
          L7_2 = L7_2 .. L8_2
          L6_2 = L6_2(L7_2)
          L5_2.Target = L6_2
          L5_2.Priority = "hiPri"
          L4_2(L5_2)
          L4_2 = bBombard
          if L4_2 == 1 then
            L5_2 = A0_2
            L4_2 = A0_2._CreateEvent
            L6_2 = Event
            L6_2 = L6_2.TimerRelative
            L7_2 = {}
            L8_2 = 5
            L7_2[1] = L8_2
            L8_2 = Obj1_StopBombard
            L9_2 = {}
            L10_2 = A0_2
            L11_2 = A1_2
            L9_2[1] = L10_2
            L9_2[2] = L11_2
            L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
            L5_2 = A0_2
            L4_2 = A0_2._CreateEvent
            L6_2 = Event
            L6_2 = L6_2.TimerRelative
            L7_2 = {}
            L8_2 = 10.5
            L7_2[1] = L8_2
            L8_2 = ShellCaracas
            L9_2 = {}
            L10_2 = A0_2
            L11_2 = A1_2
            L9_2[1] = L10_2
            L9_2[2] = L11_2
            L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
          end
        end
    end
    else
      L3_2 = bBombard
      if L3_2 == 1 then
        L4_2 = A0_2
        L3_2 = A0_2._CreateEvent
        L5_2 = Event
        L5_2 = L5_2.TimerRelative
        L6_2 = {}
        L7_2 = 10.5
        L6_2[1] = L7_2
        L7_2 = ShellCaracas
        L8_2 = {}
        L9_2 = A0_2
        L10_2 = A1_2
        L8_2[1] = L9_2
        L8_2[2] = L10_2
        L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
        L4_2 = A0_2
        L3_2 = A0_2._CreateEvent
        L5_2 = Event
        L5_2 = L5_2.TimerRelative
        L6_2 = {}
        L7_2 = 26
        L6_2[1] = L7_2
        L7_2 = Obj1_Bombard
        L8_2 = {}
        L9_2 = A0_2
        L10_2 = A1_2
        L8_2[1] = L9_2
        L8_2[2] = L10_2
        L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
      end
    end
  end
end

Obj1_Bombard = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "Obj1_"
  L4_2 = A1_2
  L3_2 = L3_2 .. L4_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = Object
    L3_2 = L3_2.IsPlayerControlled
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    if not L3_2 then
      L3_2 = Vehicle
      L3_2 = L3_2.GetDriver
      L4_2 = L2_2
      L3_2 = L3_2(L4_2)
      if L3_2 then
        L4_2 = Ai
        L4_2 = L4_2.RemoveGoal
        L5_2 = {}
        L5_2.AIGuid = L3_2
        L5_2.Handle = 0
        L4_2(L5_2)
        L4_2 = Ai
        L4_2 = L4_2.Goal
        L5_2 = {}
        L5_2.AIGuid = L3_2
        L5_2.Goal = "Idle"
        L5_2.LeaveTurretOn = true
        L5_2.Priority = "hiPri"
        L4_2(L5_2)
        L4_2 = bBombard
        if L4_2 == 1 then
          L5_2 = A0_2
          L4_2 = A0_2._CreateEvent
          L6_2 = Event
          L6_2 = L6_2.TimerRelative
          L7_2 = {}
          L8_2 = 26
          L7_2[1] = L8_2
          L8_2 = Obj1_Bombard
          L9_2 = {}
          L10_2 = A0_2
          L11_2 = A1_2
          L9_2[1] = L10_2
          L9_2[2] = L11_2
          L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
        end
      end
    end
  end
end

Obj1_StopBombard = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L1_2 = {}
  L2_2 = "AllCon002_kill_front"
  L3_2 = "AllCon002_kill_mid"
  L4_2 = "AllCon002_kill_back"
  L5_2 = "_cumana_bridge_midA 0x000caf7c"
  L6_2 = "_cumana_bridge_midA 0x000caf7b"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  tBridgeSeg = L1_2
  L1_2 = ipairs
  L2_2 = tBridgeSeg
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Pg
    L6_2 = L6_2.GetGuidByName
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    L8_2 = A0_2
    L7_2 = A0_2._CreateEvent
    L9_2 = Event
    L9_2 = L9_2.ObjectHibernation
    L10_2 = {}
    L11_2 = L6_2
    L12_2 = "awake"
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L11_2 = WreckBridge
    L12_2 = {}
    L13_2 = A0_2
    L14_2 = L6_2
    L12_2[1] = L13_2
    L12_2[2] = L14_2
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
    L8_2 = A0_2
    L7_2 = A0_2._CreateEvent
    L9_2 = Event
    L9_2 = L9_2.TimerRelative
    L10_2 = {}
    L11_2 = 4
    L10_2[1] = L11_2
    L11_2 = BoatDelay
    L12_2 = {}
    L13_2 = A0_2
    L12_2[1] = L13_2
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  end
end

SetupWreck = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  if A1_2 then
    L2_2 = Object
    L2_2 = L2_2.Kill
    L3_2 = A1_2
    L2_2(L3_2)
  end
end

WreckBridge = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = 1
  L2_2 = 3
  L3_2 = 1
  for L4_2 = L1_2, L2_2, L3_2 do
    L5_2 = Pg
    L5_2 = L5_2.GetGuidByName
    L6_2 = "RiverBoat_"
    L7_2 = L4_2
    L6_2 = L6_2 .. L7_2
    L5_2 = L5_2(L6_2)
    L7_2 = A0_2
    L6_2 = A0_2._CreateEvent
    L8_2 = Event
    L8_2 = L8_2.ObjectHibernation
    L9_2 = {}
    L10_2 = L5_2
    L11_2 = "awake"
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L10_2 = StartRiverAttack
    L11_2 = {}
    L12_2 = A0_2
    L13_2 = L4_2
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  end
end

BoatDelay = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = Object
  L2_2 = L2_2.IsAlive
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "RiverBoat_"
  L5_2 = A1_2
  L4_2 = L4_2 .. L5_2
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  if L2_2 then
    L2_2 = Vehicle
    L2_2 = L2_2.GetDriver
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = "RiverBoat_"
    L5_2 = A1_2
    L4_2 = L4_2 .. L5_2
    L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L3_2(L4_2)
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
    if L2_2 then
      L3_2 = Object
      L3_2 = L3_2.IsPlayerControlled
      L4_2 = Pg
      L4_2 = L4_2.GetGuidByName
      L5_2 = "RiverBoat_"
      L6_2 = A1_2
      L5_2 = L5_2 .. L6_2
      L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L4_2(L5_2)
      L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
      if not L3_2 then
        L3_2 = A1_2 * 4
        nBoatTime = L3_2
        L4_2 = A0_2
        L3_2 = A0_2._CreateEvent
        L5_2 = Event
        L5_2 = L5_2.TimerRelative
        L6_2 = {}
        L7_2 = nBoatTime
        L6_2[1] = L7_2
        L7_2 = PathMoveBoat
        L8_2 = {}
        L9_2 = A0_2
        L10_2 = A1_2
        L11_2 = L2_2
        L8_2[1] = L9_2
        L8_2[2] = L10_2
        L8_2[3] = L11_2
        L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
      end
    end
  end
end

StartRiverAttack = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "RiverBoat_"
  L5_2 = A1_2
  L4_2 = L4_2 .. L5_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L4_2 = Vehicle
    L4_2 = L4_2.GetDriver
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      L5_2 = Object
      L5_2 = L5_2.IsPlayerControlled
      L6_2 = Pg
      L6_2 = L6_2.GetGuidByName
      L7_2 = "RiverBoat_"
      L8_2 = A1_2
      L7_2 = L7_2 .. L8_2
      L6_2, L7_2, L8_2, L9_2, L10_2 = L6_2(L7_2)
      L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
      if not L5_2 then
        L5_2 = Ai
        L5_2 = L5_2.Goal
        L6_2 = {}
        L6_2.AIGuid = L4_2
        L6_2.Goal = "PathMove"
        L7_2 = Pg
        L7_2 = L7_2.GetGuidByName
        L8_2 = "Pa_Boat_"
        L9_2 = A1_2
        L10_2 = "_1"
        L8_2 = L8_2 .. L9_2 .. L10_2
        L7_2 = L7_2(L8_2)
        L6_2.Target = L7_2
        L6_2.Start = "Nearest"
        L6_2.Priority = "hiPri"
        L6_2.Force = true
        L7_2 = RiverAttack
        L6_2.Callback = L7_2
        L7_2 = {}
        L8_2 = A0_2
        L9_2 = A1_2
        L7_2[1] = L8_2
        L7_2[2] = L9_2
        L6_2.CallbackData = L7_2
        L5_2(L6_2)
      end
    end
  end
end

PathMoveBoat = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  if A3_2 == 0 then
    L4_2 = PathMoveBoat
    L5_2 = A0_2
    L6_2 = A1_2
    L7_2 = A2_2
    L4_2(L5_2, L6_2, L7_2)
  elseif A3_2 == 1 then
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "RiverBoat_"
    L6_2 = A1_2
    L5_2 = L5_2 .. L6_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      L5_2 = Vehicle
      L5_2 = L5_2.GetDriver
      L6_2 = L4_2
      L5_2 = L5_2(L6_2)
      if L5_2 then
        L6_2 = Object
        L6_2 = L6_2.IsPlayerControlled
        L7_2 = Pg
        L7_2 = L7_2.GetGuidByName
        L8_2 = "RiverBoat_"
        L9_2 = A1_2
        L8_2 = L8_2 .. L9_2
        L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2 = L7_2(L8_2)
        L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
        if not L6_2 then
          L6_2 = Ai
          L6_2 = L6_2.Anchor
          L7_2 = {}
          L7_2.AIGuid = L5_2
          L7_2.AnchorRadius = 0
          L6_2(L7_2)
          L6_2 = Pg
          L6_2 = L6_2.GetGuidByName
          L7_2 = "loc_FireTgt_Boat"
          L8_2 = A1_2
          L9_2 = "_1"
          L7_2 = L7_2 .. L8_2 .. L9_2
          L6_2 = L6_2(L7_2)
          L7_2 = Ai
          L7_2 = L7_2.Goal
          L8_2 = {}
          L8_2.AIGuid = L5_2
          L8_2.Goal = "Attack"
          L8_2.Force = true
          L8_2.Target = L6_2
          L8_2.Priority = "hiPri"
          L7_2(L8_2)
          L8_2 = A0_2
          L7_2 = A0_2._CreateEvent
          L9_2 = Event
          L9_2 = L9_2.TimerRelative
          L10_2 = {}
          L11_2 = 18
          L10_2[1] = L11_2
          L11_2 = RiverAttackStop
          L12_2 = {}
          L13_2 = A0_2
          L14_2 = A1_2
          L15_2 = L5_2
          L12_2[1] = L13_2
          L12_2[2] = L14_2
          L12_2[3] = L15_2
          L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
          L8_2 = A0_2
          L7_2 = A0_2._CreateEvent
          L9_2 = Event
          L9_2 = L9_2.TimerRelative
          L10_2 = {}
          L11_2 = 4
          L10_2[1] = L11_2
          L11_2 = DamageCaracas
          L12_2 = {}
          L13_2 = A0_2
          L12_2[1] = L13_2
          L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
          eBoatDamage = L7_2
        end
      end
    end
  end
end

RiverAttack = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "RiverBoat_"
  L5_2 = A1_2
  L4_2 = L4_2 .. L5_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L4_2 = Vehicle
    L4_2 = L4_2.GetDriver
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      L5_2 = Object
      L5_2 = L5_2.IsPlayerControlled
      L6_2 = Pg
      L6_2 = L6_2.GetGuidByName
      L7_2 = "RiverBoat_"
      L8_2 = A1_2
      L7_2 = L7_2 .. L8_2
      L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2 = L6_2(L7_2)
      L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
      if not L5_2 then
        L5_2 = Ai
        L5_2 = L5_2.Goal
        L6_2 = {}
        L6_2.AIGuid = L4_2
        L6_2.Force = true
        L6_2.Goal = "Idle"
        L6_2.LeaveTurretOn = true
        L6_2.Priority = "hiPri"
        L5_2(L6_2)
        L6_2 = A0_2
        L5_2 = A0_2._CreateEvent
        L7_2 = Event
        L7_2 = L7_2.TimerRelative
        L8_2 = {}
        L9_2 = 15
        L8_2[1] = L9_2
        L9_2 = RiverAttack
        L10_2 = {}
        L11_2 = A0_2
        L12_2 = A1_2
        L13_2 = L4_2
        L14_2 = 1
        L10_2[1] = L11_2
        L10_2[2] = L12_2
        L10_2[3] = L13_2
        L10_2[4] = L14_2
        L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
      end
    end
  end
end

RiverAttackStop = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L2_2 = DamageCaracas
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = "loc_strike_"
  L3_2 = A1_2
  L4_2 = "_2"
  L2_2 = L2_2 .. L3_2 .. L4_2
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = 0.4
  L6_2[1] = L7_2
  L7_2 = MPpop
  L8_2 = {}
  L9_2 = A0_2
  L10_2 = L2_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  L3_2 = "loc_strike_"
  L4_2 = A1_2
  L5_2 = "_3"
  L3_2 = L3_2 .. L4_2 .. L5_2
  L5_2 = A0_2
  L4_2 = A0_2._CreateEvent
  L6_2 = Event
  L6_2 = L6_2.TimerRelative
  L7_2 = {}
  L8_2 = 0.8
  L7_2[1] = L8_2
  L8_2 = MPpop
  L9_2 = {}
  L10_2 = A0_2
  L11_2 = L3_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  L4_2 = "loc_strike_"
  L5_2 = A1_2
  L6_2 = "_4"
  L4_2 = L4_2 .. L5_2 .. L6_2
  L6_2 = A0_2
  L5_2 = A0_2._CreateEvent
  L7_2 = Event
  L7_2 = L7_2.TimerRelative
  L8_2 = {}
  L9_2 = 1.4
  L8_2[1] = L9_2
  L9_2 = MPpop
  L10_2 = {}
  L11_2 = A0_2
  L12_2 = L4_2
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L5_2 = "loc_strike_"
  L6_2 = A1_2
  L7_2 = "_5"
  L5_2 = L5_2 .. L6_2 .. L7_2
  L7_2 = A0_2
  L6_2 = A0_2._CreateEvent
  L8_2 = Event
  L8_2 = L8_2.TimerRelative
  L9_2 = {}
  L10_2 = 1.7
  L9_2[1] = L10_2
  L10_2 = MPpop
  L11_2 = {}
  L12_2 = A0_2
  L13_2 = L5_2
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  L6_2 = "loc_strike_"
  L7_2 = A1_2
  L8_2 = "_6"
  L6_2 = L6_2 .. L7_2 .. L8_2
  L8_2 = A0_2
  L7_2 = A0_2._CreateEvent
  L9_2 = Event
  L9_2 = L9_2.TimerRelative
  L10_2 = {}
  L11_2 = 2
  L10_2[1] = L11_2
  L11_2 = MPpop
  L12_2 = {}
  L13_2 = A0_2
  L14_2 = L6_2
  L12_2[1] = L13_2
  L12_2[2] = L14_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L7_2 = "loc_strike_"
  L8_2 = A1_2
  L9_2 = "_7"
  L7_2 = L7_2 .. L8_2 .. L9_2
  L9_2 = A0_2
  L8_2 = A0_2._CreateEvent
  L10_2 = Event
  L10_2 = L10_2.TimerRelative
  L11_2 = {}
  L12_2 = 2.6
  L11_2[1] = L12_2
  L12_2 = MPpop
  L13_2 = {}
  L14_2 = A0_2
  L15_2 = L7_2
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  L8_2 = "loc_strike_"
  L9_2 = A1_2
  L10_2 = "_8"
  L8_2 = L8_2 .. L9_2 .. L10_2
  L10_2 = A0_2
  L9_2 = A0_2._CreateEvent
  L11_2 = Event
  L11_2 = L11_2.TimerRelative
  L12_2 = {}
  L13_2 = 3
  L12_2[1] = L13_2
  L13_2 = MPpop
  L14_2 = {}
  L15_2 = A0_2
  L16_2 = L8_2
  L14_2[1] = L15_2
  L14_2[2] = L16_2
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
  L9_2 = "loc_strike_"
  L10_2 = A1_2
  L11_2 = "_9"
  L9_2 = L9_2 .. L10_2 .. L11_2
  L11_2 = A0_2
  L10_2 = A0_2._CreateEvent
  L12_2 = Event
  L12_2 = L12_2.TimerRelative
  L13_2 = {}
  L14_2 = 3.4
  L13_2[1] = L14_2
  L14_2 = MPpop
  L15_2 = {}
  L16_2 = A0_2
  L17_2 = L9_2
  L15_2[1] = L16_2
  L15_2[2] = L17_2
  L10_2(L11_2, L12_2, L13_2, L14_2, L15_2)
  L10_2 = "loc_strike_"
  L11_2 = A1_2
  L12_2 = "_10"
  L10_2 = L10_2 .. L11_2 .. L12_2
  L12_2 = A0_2
  L11_2 = A0_2._CreateEvent
  L13_2 = Event
  L13_2 = L13_2.TimerRelative
  L14_2 = {}
  L15_2 = 3.8
  L14_2[1] = L15_2
  L15_2 = MPpop
  L16_2 = {}
  L17_2 = A0_2
  L18_2 = L10_2
  L16_2[1] = L17_2
  L16_2[2] = L18_2
  L11_2(L12_2, L13_2, L14_2, L15_2, L16_2)
  L11_2 = "loc_strike_"
  L12_2 = A1_2
  L13_2 = "_11"
  L11_2 = L11_2 .. L12_2 .. L13_2
  L13_2 = A0_2
  L12_2 = A0_2._CreateEvent
  L14_2 = Event
  L14_2 = L14_2.TimerRelative
  L15_2 = {}
  L16_2 = 4
  L15_2[1] = L16_2
  L16_2 = MPpop
  L17_2 = {}
  L18_2 = A0_2
  L19_2 = L11_2
  L17_2[1] = L18_2
  L17_2[2] = L19_2
  L12_2(L13_2, L14_2, L15_2, L16_2, L17_2)
end

ShellCaracas = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  L3_2 = Object
  L3_2 = L3_2.IsAwake
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L3_2 = Object
    L3_2 = L3_2.GetPosition
    L4_2 = L2_2
    L3_2, L4_2, L5_2 = L3_2(L4_2)
    uPopZ = L5_2
    uPopY = L4_2
    uPopX = L3_2
    L3_2 = Pop
    L4_2 = uPopX
    L5_2 = uPopY
    L6_2 = uPopZ
    L7_2 = L2_2
    L3_2(L4_2, L5_2, L6_2, L7_2)
    L3_2 = Net
    L3_2 = L3_2.IsActive
    L3_2 = L3_2()
    if L3_2 then
      L3_2 = Net
      L3_2 = L3_2.SendCustomEvent
      L4_2 = "AllCon002"
      L5_2 = NETEVENT_STARTEMITTERS
      L6_2 = {}
      L7_2 = uPopX
      L8_2 = uPopY
      L9_2 = uPopZ
      L10_2 = L2_2
      L6_2[1] = L7_2
      L6_2[2] = L8_2
      L6_2[3] = L9_2
      L6_2[4] = L10_2
      L3_2(L4_2, L5_2, L6_2)
    end
  end
end

MPpop = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  L4_2 = Object
  L4_2 = L4_2.IsAwake
  L5_2 = A3_2
  L4_2 = L4_2(L5_2)
  if L4_2 then
    L4_2 = Pg
    L4_2 = L4_2.Spawn
    L5_2 = "global_particle_airstrike_distance"
    L6_2 = A0_2
    L7_2 = A1_2
    L8_2 = A2_2
    L4_2(L5_2, L6_2, L7_2, L8_2)
  end
end

Pop = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.SetSlotToText
  L3_2 = {}
  L3_2.nSlot = 1
  L3_2.sText = "[red][AllCon002.Objectives.caracasHealth]"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 0.5
  L4_2[1] = L5_2
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = Hud
    L0_3 = L0_3.ObjectiveTray
    L1_3 = L0_3
    L0_3 = L0_3.SetSlotToText
    L2_3 = {}
    L2_3.nSlot = 1
    L2_3.sText = "[white][AllCon002.Objectives.caracasHealth]"
    L0_3(L1_3, L2_3)
  end
  
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  eDisplay1 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 1
  L4_2[1] = L5_2
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = Hud
    L0_3 = L0_3.ObjectiveTray
    L1_3 = L0_3
    L0_3 = L0_3.SetSlotToText
    L2_3 = {}
    L2_3.nSlot = 1
    L2_3.sText = "[red][AllCon002.Objectives.caracasHealth]"
    L0_3(L1_3, L2_3)
  end
  
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  eDisplay2 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 1.5
  L4_2[1] = L5_2
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = Hud
    L0_3 = L0_3.ObjectiveTray
    L1_3 = L0_3
    L0_3 = L0_3.SetSlotToText
    L2_3 = {}
    L2_3.nSlot = 1
    L2_3.sText = "[white][AllCon002.Objectives.caracasHealth]"
    L0_3(L1_3, L2_3)
  end
  
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  eDisplay3 = L1_2
  L1_2 = "green"
  L2_2 = nCaracasLife
  if L2_2 <= 60 then
    L1_2 = "yellow"
  end
  L2_2 = nCaracasLife
  if L2_2 <= 25 then
    L1_2 = "red"
  end
  L2_2 = nCaracasLife
  if L2_2 < 1 then
    L2_2 = 0
    nCaracasLife = L2_2
  end
  L2_2 = "["
  L3_2 = L1_2
  L4_2 = "][bar"
  L5_2 = nCaracasLife
  L6_2 = "]"
  L2_2 = L2_2 .. L3_2 .. L4_2 .. L5_2 .. L6_2
  sHudText = L2_2
  L2_2 = Hud
  L2_2 = L2_2.ObjectiveTray
  L3_2 = L2_2
  L2_2 = L2_2.SetSlotToText
  L4_2 = {}
  L4_2.vPlayer = nil
  L4_2.nSlot = 2
  L5_2 = sHudText
  L4_2.sText = L5_2
  L2_2(L3_2, L4_2)
end

DisplayCaracasHealth = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = nCaracasLife
  L2_2 = nDamMod
  L1_2 = L1_2 - L2_2
  nCaracasLife = L1_2
  L1_2 = DisplayCaracasHealth
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = nCaracasLife
  if L1_2 == 98 then
    L1_2 = MPplumes
    L2_2 = 1
    L1_2(L2_2)
    L1_2 = MPplumes
    L2_2 = 2
    L1_2(L2_2)
    L1_2 = MPplumes
    L2_2 = 12
    L1_2(L2_2)
  else
    L1_2 = nCaracasLife
    if L1_2 == 90 then
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = "Fiona-In-Mission-Contract-All02-18"
      L2_2[1] = L3_2
      L1_2(L2_2)
    else
      L1_2 = nCaracasLife
      if L1_2 == 44 then
        L1_2 = MPplumes
        L2_2 = 3
        L1_2(L2_2)
        L1_2 = MPplumes
        L2_2 = 4
        L1_2(L2_2)
        L1_2 = MPplumes
        L2_2 = 11
        L1_2(L2_2)
        L1_2 = MrxVoSequence
        L1_2 = L1_2.Start
        L2_2 = {}
        L3_2 = "Fiona-In-Mission-Contract-All02-17"
        L2_2[1] = L3_2
        L1_2(L2_2)
      else
        L1_2 = nCaracasLife
        if L1_2 == 24 then
          L1_2 = MPplumes
          L2_2 = 5
          L1_2(L2_2)
          L1_2 = MPplumes
          L2_2 = 6
          L1_2(L2_2)
          L1_2 = MPplumes
          L2_2 = 10
          L1_2(L2_2)
          L1_2 = MrxVoSequence
          L1_2 = L1_2.Start
          L2_2 = {}
          L3_2 = "Fiona-In-Mission-Contract-All02-19"
          L2_2[1] = L3_2
          L1_2(L2_2)
        else
          L1_2 = nCaracasLife
          if L1_2 == 18 then
            L1_2 = MPplumes
            L2_2 = 7
            L1_2(L2_2)
            L1_2 = MPplumes
            L2_2 = 8
            L1_2(L2_2)
            L1_2 = MPplumes
            L2_2 = 9
            L1_2(L2_2)
            L1_2 = MrxVoSequence
            L1_2 = L1_2.Start
            L2_2 = {}
            L3_2 = "Fiona-In-Mission-Contract-All02-20"
            L2_2[1] = L3_2
            L1_2(L2_2)
          end
        end
      end
    end
  end
  L1_2 = nCaracasLife
  if L1_2 <= 3 then
    L1_2 = 0
    bBombard = L1_2
    L2_2 = A0_2
    L1_2 = A0_2._SetCancelMessage
    L3_2 = "[AllCon002.Terms.Cancel01]"
    L1_2(L2_2, L3_2)
    L1_2 = MrxVoSequence
    L1_2 = L1_2.Start
    L2_2 = {}
    L3_2 = "Fiona-In-Mission-Contract-All02-21"
    L2_2[1] = L3_2
    L1_2(L2_2)
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = 4.5
    L4_2[1] = L5_2
    L5_2 = A0_2.Cancel
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  end
end

DamageCaracas = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "Loc_Smoke_"
  L3_2 = A0_2
  L2_2 = L2_2 .. L3_2
  L1_2 = L1_2(L2_2)
  L2_2 = Object
  L2_2 = L2_2.IsAwake
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = Object
    L2_2 = L2_2.GetPosition
    L3_2 = L1_2
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    uPlumeZ = L4_2
    uPlumeY = L3_2
    uPlumeX = L2_2
    L2_2 = Plumes
    L3_2 = uPlumeX
    L4_2 = uPlumeY
    L5_2 = uPlumeZ
    L6_2 = A0_2
    L2_2(L3_2, L4_2, L5_2, L6_2)
    L2_2 = Net
    L2_2 = L2_2.IsActive
    L2_2 = L2_2()
    if L2_2 then
      L2_2 = Net
      L2_2 = L2_2.SendCustomEvent
      L3_2 = "AllCon002"
      L4_2 = NETEVENT_STARTPLUMES
      L5_2 = {}
      L6_2 = uPlumeX
      L7_2 = uPlumeY
      L8_2 = uPlumeZ
      L9_2 = A0_2
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      L5_2[3] = L8_2
      L5_2[4] = L9_2
      L2_2(L3_2, L4_2, L5_2)
    else
    end
  end
end

MPplumes = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  L4_2 = _tSmokeParticleObjects
  if L4_2 == nil then
    L4_2 = {}
    _tSmokeParticleObjects = L4_2
  end
  L4_2 = Pg
  L4_2 = L4_2.Spawn
  L5_2 = "global_particle_env_smokeplume_distance_tall"
  L6_2 = A0_2
  L7_2 = A1_2
  L8_2 = A2_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L5_2 = table
  L5_2 = L5_2.insert
  L6_2 = _tSmokeParticleObjects
  L7_2 = L4_2
  L5_2(L6_2, L7_2)
  L5_2 = table
  L5_2 = L5_2.getn
  L6_2 = _tSmokeParticleObjects
  L5_2 = L5_2(L6_2)
  nTotalPlumes = L5_2
end

Plumes = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2
  L3_2 = "Rocket Artillery Projectile"
  L4_2 = 5
  L5_2 = 4
  L6_2 = 1
  L7_2 = 15
  L8_2 = Player
  L8_2 = L8_2.GetControlledObject
  L9_2 = Player
  L9_2 = L9_2.GetLocalPlayer
  L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2 = L9_2()
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2)
  L9_2 = Object
  L9_2 = L9_2.GetVelocity
  L10_2 = L8_2
  L9_2 = L9_2(L10_2)
  if not L9_2 then
    L9_2 = 1
  end
  if L9_2 < 10 then
    L10_2 = L9_2 + 4
    L10_2 = L10_2 * 10
    uFixedSpeed = L10_2
    L10_2 = 6
    nStrikeFrequency = L10_2
  elseif L9_2 < 16 then
    L10_2 = 3
    nStrikeFrequency = L10_2
    L10_2 = L9_2 * 11
    uFixedSpeed = L10_2
  else
    L10_2 = L9_2 * 11
    uFixedSpeed = L10_2
    L10_2 = 1
    nStrikeFrequency = L10_2
    L10_2 = uFixedSpeed
    if 250 < L10_2 then
      L10_2 = 240
      uFixedSpeed = L10_2
    end
  end
  L10_2 = Pg
  L10_2 = L10_2.FindPointFromCamera
  L11_2 = uFixedSpeed
  L12_2 = 20
  L13_2 = -1
  L10_2, L11_2, L12_2 = L10_2(L11_2, L12_2, L13_2)
  L13_2 = Object
  L13_2 = L13_2.GetPosition
  L14_2 = Player
  L14_2 = L14_2.GetPrimaryCharacter
  L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2 = L14_2()
  L13_2, L14_2, L15_2 = L13_2(L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2)
  L16_2 = math
  L16_2 = L16_2.randf
  L16_2 = L16_2()
  L16_2 = L16_2 * 7
  L17_2 = math
  L17_2 = L17_2.randf
  L17_2 = L17_2()
  L17_2 = L17_2 * 7
  L16_2 = L16_2 - L17_2
  L16_2 = L10_2 - L16_2
  L17_2 = L16_2 - L13_2
  L18_2 = L11_2 - L14_2
  L19_2 = L12_2 - L15_2
  L20_2 = Math
  L20_2 = L20_2.Normalize
  L21_2 = L17_2
  L22_2 = L18_2
  L23_2 = L19_2
  L20_2, L21_2, L22_2 = L20_2(L21_2, L22_2, L23_2)
  L19_2 = L22_2
  L18_2 = L21_2
  L17_2 = L20_2
  L20_2 = L12_2 - L15_2
  L20_2 = -L20_2
  L21_2 = 0
  L22_2 = L16_2 - L13_2
  L23_2 = Math
  L23_2 = L23_2.Normalize
  L24_2 = L20_2
  L25_2 = L21_2
  L26_2 = L22_2
  L23_2, L24_2, L25_2 = L23_2(L24_2, L25_2, L26_2)
  L22_2 = L25_2
  L21_2 = L24_2
  L20_2 = L23_2
  L23_2 = 1
  L24_2 = L6_2
  L25_2 = 1
  for L26_2 = L23_2, L24_2, L25_2 do
    L27_2 = L4_2
    L28_2 = L5_2
    L29_2 = math
    L29_2 = L29_2.randf
    L29_2 = L29_2()
    L29_2 = L29_2 * L27_2
    L30_2 = math
    L30_2 = L30_2.randf
    L30_2 = L30_2()
    L30_2 = L30_2 * L27_2
    L29_2 = L29_2 - L30_2
    L30_2 = 2.5 - L26_2
    L30_2 = L30_2 * L27_2
    L29_2 = L29_2 + L30_2
    L29_2 = -L29_2
    L30_2 = math
    L30_2 = L30_2.randf
    L30_2 = L30_2()
    L30_2 = L30_2 * L28_2
    L31_2 = math
    L31_2 = L31_2.randf
    L31_2 = L31_2()
    L31_2 = L31_2 * L28_2
    L30_2 = L30_2 - L31_2
    L30_2 = -L30_2
    L31_2 = {}
    L31_2.sAmmo = L3_2
    L32_2 = L20_2 * L29_2
    L32_2 = L16_2 + L32_2
    L33_2 = L17_2 * L30_2
    L32_2 = L32_2 + L33_2
    L31_2.nTargetX = L32_2
    L32_2 = L11_2 + 250
    L31_2.nTargetY = L32_2
    L32_2 = L22_2 * L29_2
    L32_2 = L12_2 + L32_2
    L33_2 = L19_2 * L30_2
    L32_2 = L32_2 + L33_2
    L31_2.nTargetZ = L32_2
    if A0_2 then
      L32_2 = Pg
      L32_2 = L32_2.GetGuidByName
      L33_2 = "loc_Rockets_"
      L34_2 = A2_2
      L35_2 = "_"
      L36_2 = L26_2
      L33_2 = L33_2 .. L34_2 .. L35_2 .. L36_2
      L32_2 = L32_2(L33_2)
      if L32_2 then
        L33_2 = Object
        L33_2 = L33_2.GetPosition
        L34_2 = L32_2
        L33_2, L34_2, L35_2 = L33_2(L34_2)
        L36_2 = {}
        L36_2.sAmmo = L3_2
        L36_2.nTargetX = L33_2
        L37_2 = L34_2 + 250
        L36_2.nTargetY = L37_2
        L36_2.nTargetZ = L35_2
      else
        L31_2 = nil
      end
    end
    L32_2 = Pg
    L32_2 = L32_2.GetGuidByName
    L33_2 = "China"
    L32_2 = L32_2(L33_2)
    if L31_2 then
      L33_2 = Event
      L33_2 = L33_2.Create
      L34_2 = Event
      L34_2 = L34_2.TimerRelative
      L35_2 = {}
      L36_2 = L7_2 / 22
      L36_2 = L26_2 * L36_2
      L36_2 = 2 + L36_2
      L35_2[1] = L36_2
      L36_2 = TriggerFallingMissile
      L37_2 = {}
      L38_2 = L31_2
      L39_2 = L32_2
      L37_2[1] = L38_2
      L37_2[2] = L39_2
      L33_2(L34_2, L35_2, L36_2, L37_2)
    end
  end
end

AirStriked = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = AirStriked
  L4_2 = A0_2
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = Net
  L3_2 = L3_2.IsActive
  L3_2 = L3_2()
  if L3_2 then
    L3_2 = Net
    L3_2 = L3_2.SendCustomEvent
    L4_2 = "AllCon002"
    L5_2 = NETEVENT_AIRSTRUCK
    L6_2 = {}
    L7_2 = A0_2
    L8_2 = A1_2
    L9_2 = A2_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L3_2(L4_2, L5_2, L6_2)
  end
end

MPShelling = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = Airstrike
  L2_2 = L2_2.SpawnOrdnance
  L3_2 = A0_2.sAmmo
  L4_2 = A0_2.nTargetX
  L5_2 = A0_2.nTargetY
  L6_2 = A0_2.nTargetZ
  L7_2 = 0
  L8_2 = -100
  L9_2 = 0
  L10_2 = "impact"
  L11_2 = 1
  L12_2 = A1_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
end

TriggerFallingMissile = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L1_2 = {}
  L2_2 = {}
  L3_2 = {}
  L3_2.altitude = 90
  L3_2.speed = 120
  L3_2.template = "Support Vehicle (A10)"
  L3_2.bMulti = true
  L4_2 = {}
  L4_2.altitude = 60
  L4_2.speed = 120
  L4_2.template = "Support Vehicle (A10)"
  L4_2.bMulti = true
  L5_2 = {}
  L5_2.altitude = 100
  L5_2.speed = 200
  L5_2.template = "Support Vehicle (F35)"
  L5_2.bMulti = true
  L6_2 = {}
  L6_2.altitude = 180
  L6_2.speed = 220
  L6_2.template = "Support Vehicle (F117)"
  L7_2 = {}
  L7_2.altitude = 250
  L7_2.speed = 120
  L7_2.template = "Support Vehicle (C130)"
  L8_2 = {}
  L8_2.altitude = 180
  L8_2.speed = 120
  L8_2.template = "Support Vehicle (AC130)"
  L9_2 = {}
  L9_2.altitude = 50
  L9_2.speed = 60
  L9_2.template = "Support Vehicle (Predator)"
  L10_2 = {}
  L10_2.altitude = 60
  L10_2.speed = 60
  L10_2.template = "Support Vehicle (Predator)"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L2_2[6] = L8_2
  L2_2[7] = L9_2
  L2_2[8] = L10_2
  L3_2 = {}
  L4_2 = {}
  L4_2.altitude = 100
  L4_2.speed = 200
  L4_2.template = "Support Vehicle (Q5)"
  L4_2.bMulti = true
  L5_2 = {}
  L5_2.altitude = 200
  L5_2.speed = 200
  L5_2.template = "Support Vehicle (Q5)"
  L5_2.bMulti = true
  L6_2 = {}
  L6_2.altitude = 160
  L6_2.speed = 240
  L6_2.template = "Support Vehicle (Q5)"
  L6_2.bMulti = true
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  tFlybys = L1_2
  L1_2 = tFlybys
  L2_2 = Math
  L2_2 = L2_2.randi
  L3_2 = table
  L3_2 = L3_2.getn
  L4_2 = tFlybys
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  L1_2 = L1_2[L2_2]
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
  L5_2 = A0_2
  L4_2 = A0_2._CreateEvent
  L6_2 = Event
  L6_2 = L6_2.TimerRelative
  L7_2 = {}
  L8_2 = 15
  L7_2[1] = L8_2
  L8_2 = Flybys
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
end

Flybys = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = _tSmokeParticleObjects
  if L0_2 then
    L0_2 = ipairs
    L1_2 = _tSmokeParticleObjects
    L0_2, L1_2, L2_2 = L0_2(L1_2)
    for L3_2, L4_2 in L0_2, L1_2, L2_2 do
      L5_2 = Object
      L5_2 = L5_2.Remove
      L6_2 = L4_2
      L5_2(L6_2)
    end
  end
end

SmokeClean = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Add
  L2_2 = {}
  L3_2 = "vz_state_staging_all_HQ"
  L2_2[1] = L3_2
  L1_2(L2_2)
  L1_2 = {}
  L2_2 = "vz_state_car_city_act1"
  L3_2 = "vz_state_car_shanty_act1"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L2_2 = MrxLayerManager
  L2_2 = L2_2.MarkForAddition
  L3_2 = L1_2
  L2_2(L3_2)
  L2_2 = eBoatDamage
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = eBoatDamage
    L2_2(L3_2)
  end
  L2_2 = eDamageCarac
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = eDamageCarac
    L2_2(L3_2)
  end
  L2_2 = eDisplay1
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = eDisplay1
    L2_2(L3_2)
  end
  L2_2 = eDisplay2
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = eDisplay2
    L2_2(L3_2)
  end
  L2_2 = eDisplay3
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = eDisplay3
    L2_2(L3_2)
  end
  L2_2 = Hud
  L2_2 = L2_2.ObjectiveTray
  L3_2 = L2_2
  L2_2 = L2_2.ClearSlot
  L4_2 = {}
  L4_2.vPlayer = nil
  L4_2.nSlot = 1
  L2_2(L3_2, L4_2)
  L2_2 = Hud
  L2_2 = L2_2.ObjectiveTray
  L3_2 = L2_2
  L2_2 = L2_2.ClearSlot
  L4_2 = {}
  L4_2.vPlayer = nil
  L4_2.nSlot = 2
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 2.5
  L5_2[1] = L6_2
  
  function L6_2()
    local L0_3, L1_3, L2_3
    L0_3 = Hud
    L0_3 = L0_3.ObjectiveTray
    L1_3 = L0_3
    L0_3 = L0_3.ClearSlot
    L2_3 = {}
    L2_3.vPlayer = nil
    L2_3.nSlot = 1
    L0_3(L1_3, L2_3)
  end
  
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L2_2 = SmokeClean
  L2_2()
  L2_2 = Net
  L2_2 = L2_2.IsActive
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = Net
    L2_2 = L2_2.SendCustomEvent
    L3_2 = "AllCon002"
    L4_2 = NETEVENT_CLEANSMOKE
    L5_2 = {}
    L2_2(L3_2, L4_2, L5_2)
  end
  L2_2 = MrxTaskContract
  L2_2 = L2_2.Cleanup
  L3_2 = A0_2
  L2_2(L3_2)
end

Cleanup = L0_1
