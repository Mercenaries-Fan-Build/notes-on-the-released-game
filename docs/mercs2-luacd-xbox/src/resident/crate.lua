local L0_1, L1_1, L2_1
L0_1 = "pickup_crate_2"
L1_1 = {}

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = L1_1
  L2_2 = L1_1
  L2_2 = L2_2[A0_2]
  if not L2_2 then
    L2_2 = {}
  end
  L1_2[A0_2] = L2_2
  L1_2 = L1_1
  L1_2 = L1_2[A0_2]
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = A0_2
  L6_2 = "awake"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = Awake
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.Awake = L2_2
end

OnActivate = L2_1

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = L1_1
  L2_2 = L1_1
  L2_2 = L2_2[A0_2]
  if not L2_2 then
    L2_2 = {}
  end
  L1_2[A0_2] = L2_2
  L1_2 = L1_1
  L1_2 = L1_2[A0_2]
  L1_2 = L1_2.Winched
  if not L1_2 then
    L1_2 = L1_1
    L1_2 = L1_2[A0_2]
    L2_2 = Event
    L2_2 = L2_2.CreatePersistent
    L3_2 = Event
    L3_2 = L3_2.ObjectWinched
    L4_2 = {}
    L5_2 = A0_2
    L6_2 = 0
    L7_2 = "any"
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L4_2[3] = L7_2
    L5_2 = Awake
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
    L1_2.Winched = L2_2
  end
  L1_2 = Object
  L1_2 = L1_2.IsWinched
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = L1_1
    L1_2 = L1_2[A0_2]
    L1_2 = L1_2.Marker
    if L1_2 then
      L1_2 = Marker
      L1_2 = L1_2.Remove
      L2_2 = L1_1
      L2_2 = L2_2[A0_2]
      L2_2 = L2_2.Marker
      L1_2(L2_2)
      L1_2 = L1_1
      L1_2 = L1_2[A0_2]
      L1_2.Marker = nil
    end
  else
    L1_2 = L1_1
    L1_2 = L1_2[A0_2]
    L2_2 = Marker
    L2_2 = L2_2.AddBlip
    L3_2 = A0_2
    L4_2 = L0_1
    L5_2 = 48
    L6_2 = 255
    L7_2 = 255
    L8_2 = 255
    L9_2 = 255
    L10_2 = 0.5
    L11_2 = 16
    L12_2 = 20
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
    L1_2.Marker = L2_2
  end
end

Awake = L2_1

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = L1_1
  L2_2 = L1_1
  L2_2 = L2_2[A0_2]
  if not L2_2 then
    L2_2 = {}
  end
  L1_2[A0_2] = L2_2
  L1_2 = L1_1
  L1_2 = L1_2[A0_2]
  L1_2 = L1_2.Marker
  if L1_2 then
    L1_2 = Marker
    L1_2 = L1_2.Remove
    L2_2 = L1_1
    L2_2 = L2_2[A0_2]
    L2_2 = L2_2.Marker
    L1_2(L2_2)
    L1_2 = L1_1
    L1_2 = L1_2[A0_2]
    L1_2.Marker = nil
  end
  L1_2 = pairs
  L2_2 = L1_1
  L2_2 = L2_2[A0_2]
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Event
    L6_2 = L6_2.Delete
    L7_2 = L5_2
    L6_2(L7_2)
  end
  L1_2 = L1_1
  L1_2[A0_2] = nil
end

OnDeactivate = L2_1

function L2_1(A0_2)
  local L1_2, L2_2
  L1_2 = OnDeactivate
  L2_2 = A0_2
  L1_2(L2_2)
end

OnDeath = L2_1
