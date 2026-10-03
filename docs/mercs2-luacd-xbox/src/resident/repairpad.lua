local L0_1, L1_1
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)
L0_1 = tEvents
if not L0_1 then
  L0_1 = {}
end
tEvents = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = tEvents
  L3_2 = tEvents
  L3_2 = L3_2[A0_2]
  if not L3_2 then
    L3_2 = {}
  end
  L2_2[A0_2] = L3_2
  L2_2 = tEvents
  L2_2 = L2_2[A0_2]
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectHibernation
  L5_2 = {}
  L6_2 = A0_2
  L7_2 = "awake"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  
  function L6_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = Vehicle
    L0_3 = L0_3.SetParts
    L1_3 = A0_2
    L2_3 = "LightFront"
    L3_3 = false
    L0_3 = L0_3(L1_3, L2_3, L3_3)
    bLightStart = L0_3
    L0_3 = SetupActivationEvents
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L2_2.uActivate = L3_2
end

OnActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = tEvents
  if not L1_2 then
    L1_2 = {}
  end
  tEvents = L1_2
  L1_2 = tEvents
  L2_2 = tEvents
  L2_2 = L2_2[A0_2]
  if not L2_2 then
    L2_2 = {}
  end
  L1_2[A0_2] = L2_2
  L1_2 = pairs
  L2_2 = tEvents
  L2_2 = L2_2[A0_2]
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Event
    L6_2 = L6_2.Delete
    L7_2 = L5_2
    L6_2(L7_2)
  end
  L1_2 = tEvents
  L1_2[A0_2] = nil
end

OnDeactivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Vehicle
  L1_2 = L1_2.SetParts
  L2_2 = A0_2
  L3_2 = "LightFront"
  L4_2 = false
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = OnDeactivate
  L2_2 = A0_2
  L1_2(L2_2)
end

OnDeath = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Vehicle
  L1_2 = L1_2.SetParts
  L2_2 = A0_2
  L3_2 = "LightFront"
  L4_2 = true
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  bLightStart = L1_2
end

SetupActivationEvents = L0_1
