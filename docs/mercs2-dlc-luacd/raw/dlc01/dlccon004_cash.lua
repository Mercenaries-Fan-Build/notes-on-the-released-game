local L0_1, L1_1, L2_1
L0_1 = import
L1_1 = "MrxPmc"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "DLCComboMeter"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = "pickup_crate_2"
L1_1 = {}
tGlobalCashInstances = L1_1

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = tGlobalCashInstances
  L3_2 = L3_2[A0_2]
  if not L3_2 then
    L3_2 = {}
  end
  L4_2 = Marker
  L4_2 = L4_2.Add
  L5_2 = 0
  L6_2 = 0
  L7_2 = 0
  L8_2 = A0_2
  L9_2 = 0
  L10_2 = 255
  L11_2 = 0
  L12_2 = 0.5
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L3_2.Marker = L4_2
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = 30
  L6_2[1] = L7_2
  L7_2 = OnDeactivate
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L3_2.TimerEvent = L4_2
  L4_2 = Hud
  L4_2 = L4_2.Radar
  L5_2 = L4_2
  L4_2 = L4_2.AddObjective
  L6_2 = {}
  L7_2 = "Cash"
  L8_2 = tostring
  L9_2 = A0_2
  L8_2 = L8_2(L9_2)
  L7_2 = L7_2 .. L8_2
  L6_2.sName = L7_2
  L6_2.uGuid = A0_2
  L6_2.nR = 0
  L6_2.nG = 255
  L6_2.nB = 0
  L6_2.nWidth = A2_2
  L6_2.nHeight = A2_2
  L4_2(L5_2, L6_2)
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.ObjectProximity
  L6_2 = {}
  L7_2 = Player
  L7_2 = L7_2.GetAnyCharacter
  L7_2 = L7_2()
  L8_2 = A0_2
  L9_2 = "<"
  L10_2 = 7
  L11_2 = false
  L12_2 = true
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L6_2[5] = L11_2
  L6_2[6] = L12_2
  L7_2 = CashPickedUp
  L8_2 = {}
  L9_2 = A2_2
  L10_2 = A0_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L3_2.PickupEvent = L4_2
  L4_2 = tGlobalCashInstances
  L4_2[A0_2] = L3_2
end

OnActivate = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = Event
  L2_2 = L2_2.Post
  L3_2 = "CashPickup"
  L4_2 = {}
  L5_2 = A0_2
  L4_2[1] = L5_2
  L2_2(L3_2, L4_2)
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = A1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L5_2 = Pg
  L5_2 = L5_2.Spawn
  L6_2 = "global_particle_explosion_pickup_money"
  L7_2 = L2_2
  L8_2 = L3_2
  L9_2 = L4_2
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L5_2 = OnDeactivate
  L6_2 = A1_2
  L5_2(L6_2)
end

CashPickedUp = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = tGlobalCashInstances
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    return
  end
  L2_2 = L1_2.Marker
  if L2_2 then
    L2_2 = Marker
    L2_2 = L2_2.Remove
    L3_2 = L1_2.Marker
    L2_2(L3_2)
    L1_2.Marker = nil
  end
  L2_2 = Hud
  L2_2 = L2_2.Radar
  L3_2 = L2_2
  L2_2 = L2_2.RemoveObjective
  L4_2 = {}
  L5_2 = "Cash"
  L6_2 = tostring
  L7_2 = A0_2
  L6_2 = L6_2(L7_2)
  L5_2 = L5_2 .. L6_2
  L4_2.sName = L5_2
  L2_2(L3_2, L4_2)
  L2_2 = L1_2.TimerEvent
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = L1_2.TimerEvent
    L2_2(L3_2)
  end
  L2_2 = L1_2.ProximityEvent
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = L1_2.ProximityEvent
    L2_2(L3_2)
  end
  L2_2 = tGlobalCashInstances
  L2_2[A0_2] = nil
  L2_2 = Object
  L2_2 = L2_2.Remove
  L3_2 = A0_2
  L2_2(L3_2)
end

OnDeactivate = L1_1

function L1_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = ipairs
  L1_2 = tGlobalCashInstances
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = Event
    L5_2 = L5_2.Delete
    L6_2 = tGlobalCashInstances
    L6_2 = L6_2.TimerEvent
    L5_2(L6_2)
    L5_2 = Event
    L5_2 = L5_2.Delete
    L6_2 = tGlobalCashInstances
    L6_2 = L6_2.ProximityEvent
    L5_2(L6_2)
    L5_2 = Object
    L5_2 = L5_2.Delete
    L6_2 = L4_2
    L5_2(L6_2)
  end
end

Cleanup = L1_1
