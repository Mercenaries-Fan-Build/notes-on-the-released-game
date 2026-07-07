local L0_1, L1_1, L2_1
L0_1 = import
L1_1 = "MrxPmc"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxTankBuster"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxSupportData"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "DlcVehicleStrike"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = tEvents
if not L0_1 then
  L0_1 = {}
end
tEvents = L0_1
L0_1 = tMarker
if not L0_1 then
  L0_1 = {}
end
tMarker = L0_1
L0_1 = tFocus
if not L0_1 then
  L0_1 = {}
end
tFocus = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = tEvents
  L3_2 = tEvents
  L3_2 = L3_2[A0_2]
  if not L3_2 then
    L3_2 = {}
  end
  L2_2[A0_2] = L3_2
  L2_2 = tMarker
  L3_2 = tMarker
  L3_2 = L3_2[A0_2]
  if not L3_2 then
    L3_2 = {}
  end
  L2_2[A0_2] = L3_2
  L2_2 = tFocus
  L3_2 = tFocus
  L3_2 = L3_2[A0_2]
  if not L3_2 then
    L3_2 = {}
  end
  L2_2[A0_2] = L3_2
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = A0_2
  L6_2 = "awake"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  
  function L5_2()
    local L0_3, L1_3
    L0_3 = SetupActivationEvents
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = tMarker
  L2_2 = L2_2[A0_2]
  L3_2 = Marker
  L3_2 = L3_2.AddBlip
  L4_2 = A0_2
  L5_2 = "pickup_munitions"
  L6_2 = 28
  L7_2 = 51
  L8_2 = 204
  L9_2 = 153
  L10_2 = 180
  L11_2 = 0.75
  L12_2 = 100
  L13_2 = 150
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L2_2.uMarker = L3_2
end

OnActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = OnDeactivate
  L2_2 = A0_2
  L1_2(L2_2)
end

OnDeath = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = tEvents
  if L1_2 then
    L1_2 = tEvents
    L1_2 = L1_2[A0_2]
    if L1_2 then
      L1_2 = tEvents
      L1_2 = L1_2[A0_2]
      L1_2 = L1_2.uCheckEvent
      if L1_2 then
        L1_2 = Event
        L1_2 = L1_2.Delete
        L2_2 = tEvents
        L2_2 = L2_2[A0_2]
        L2_2 = L2_2.uCheckEvent
        L1_2(L2_2)
        L1_2 = tEvents
        L1_2 = L1_2[A0_2]
        L1_2.uCheckEvent = nil
      end
      L1_2 = tEvents
      L1_2 = L1_2[A0_2]
      L1_2 = L1_2.uActivate
      if L1_2 then
        L1_2 = Event
        L1_2 = L1_2.Delete
        L2_2 = tEvents
        L2_2 = L2_2[A0_2]
        L2_2 = L2_2.uActivate
        L1_2(L2_2)
        L1_2 = tEvents
        L1_2 = L1_2[A0_2]
        L1_2.uActivate = nil
      end
      L1_2 = tEvents
      L1_2 = L1_2[A0_2]
      L1_2 = L1_2.uDeactivate
      if L1_2 then
        L1_2 = Event
        L1_2 = L1_2.Delete
        L2_2 = tEvents
        L2_2 = L2_2[A0_2]
        L2_2 = L2_2.uDeactivate
        L1_2(L2_2)
        L1_2 = tEvents
        L1_2 = L1_2[A0_2]
        L1_2.uDeactivate = nil
      end
      L1_2 = tEvents
      L1_2 = L1_2[A0_2]
      L1_2 = L1_2.uHideTutorial
      if L1_2 then
        L1_2 = Event
        L1_2 = L1_2.Delete
        L2_2 = tEvents
        L2_2 = L2_2[A0_2]
        L2_2 = L2_2.uHideTutorial
        L1_2(L2_2)
        L1_2 = tEvents
        L1_2 = L1_2[A0_2]
        L1_2.uHideTutorial = nil
      end
      L1_2 = tEvents
      L1_2[A0_2] = nil
    end
  end
  L1_2 = tMarker
  if L1_2 then
    L1_2 = tMarker
    L1_2 = L1_2[A0_2]
    if L1_2 then
      L1_2 = tMarker
      L1_2 = L1_2[A0_2]
      L1_2 = L1_2.uMarker
      if L1_2 then
        L1_2 = Marker
        L1_2 = L1_2.Remove
        L2_2 = tMarker
        L2_2 = L2_2[A0_2]
        L2_2 = L2_2.uMarker
        L1_2(L2_2)
      end
    end
  end
end

OnDeactivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = A0_2
  L7_2 = "<"
  L8_2 = 8
  L9_2 = false
  L10_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L5_2 = CallStrike
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.uActivate = L2_2
end

SetupActivationEvents = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  L4_2 = FindPlayer
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if L4_2 then
  else
    L5_2 = Player
    L5_2 = L5_2.GetPrimaryPlayer
    L5_2 = L5_2()
    L4_2 = L5_2
  end
  L5_2 = MrxSupportData
  L5_2 = L5_2.AddFreebie
  L6_2 = "FreeTankBuster"
  L5_2(L6_2)
  L5_2 = Pg
  L5_2 = L5_2.Spawn
  L6_2 = "global_particle_explosion_pickup_rocket"
  L7_2 = L1_2
  L8_2 = L2_2
  L9_2 = L3_2
  L10_2 = 0
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L5_2 = Object
  L5_2 = L5_2.FadeOut
  L6_2 = A0_2
  L7_2 = 0.075
  L8_2 = true
  L5_2(L6_2, L7_2, L8_2)
end

CallStrike = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  L4_2 = Pg
  L4_2 = L4_2.FastCollectHumans
  L5_2 = L1_2
  L6_2 = L2_2
  L7_2 = L3_2
  L8_2 = 20
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L5_2 = ipairs
  L6_2 = L4_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = Object
    L10_2 = L10_2.IsPlayerControlled
    L11_2 = L9_2
    L10_2 = L10_2(L11_2)
    if L10_2 then
      return L10_2
    else
      L11_2 = FindPlayerVehicle
      L12_2 = A0_2
      L11_2 = L11_2(L12_2)
      L10_2 = L11_2
      return L10_2
    end
  end
end

FindPlayer = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  L4_2 = Pg
  L4_2 = L4_2.FastCollectGroundVehicles
  L5_2 = L1_2
  L6_2 = L2_2
  L7_2 = L3_2
  L8_2 = 25
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L5_2 = ipairs
  L6_2 = L4_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = Object
    L10_2 = L10_2.IsPlayerControlled
    L11_2 = L9_2
    L10_2 = L10_2(L11_2)
    if L10_2 then
      return L10_2
    else
    end
  end
end

FindPlayerVehicle = L0_1
