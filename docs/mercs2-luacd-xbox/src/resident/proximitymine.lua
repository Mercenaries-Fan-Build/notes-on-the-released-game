local L0_1, L1_1
uEvent = L0_1
L0_1 = nil
uFilter = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = {}
  uEvent = L0_2
  L0_2 = ObjectFilter
  L0_2 = L0_2.Create
  L0_2 = L0_2()
  uFilter = L0_2
  L0_2 = ObjectFilter
  L0_2 = L0_2.SetFilter
  L1_2 = uFilter
  L2_2 = "human"
  L0_2(L1_2, L2_2)
end

Init = L0_1

function L0_1()
  local L0_2, L1_2
  uEvent = L0_2
  L0_2 = nil
  uFilter = L0_2
end

Deinit = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = uEvent
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = uFilter
  L7_2 = A0_2
  L8_2 = "<"
  L9_2 = 6
  L10_2 = false
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = Triggered
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2[A0_2] = L3_2
end

OnActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = uEvent
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uEvent
    L2_2 = L2_2[A0_2]
    L1_2(L2_2)
    L1_2 = uEvent
    L1_2[A0_2] = nil
  end
end

OnDeactivate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 0.001
  L4_2[1] = L5_2
  L5_2 = Popup
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
end

Triggered = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  if not L1_2 then
    return
  end
  L4_2 = Object
  L4_2 = L4_2.Remove
  L5_2 = A0_2
  L4_2(L5_2)
  L4_2 = Airstrike
  L4_2 = L4_2.SpawnOrdnance
  L5_2 = "Grenade MG Projectile"
  L6_2 = L1_2
  L7_2 = L2_2
  L8_2 = L3_2
  L9_2 = 0
  L10_2 = 8
  L11_2 = 0
  L12_2 = "distance"
  L13_2 = 1.8
  L14_2 = nil
  L15_2 = Object
  L15_2 = L15_2.Kill
  L16_2 = {}
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
end

Popup = L0_1
