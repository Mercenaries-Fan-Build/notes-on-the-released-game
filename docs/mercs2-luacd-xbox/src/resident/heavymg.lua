local L0_1, L1_1
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = tEvents
if not L0_1 then
  L0_1 = {}
end
tEvents = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = tEvents
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.WeaponEvent
  L5_2 = {}
  L6_2 = "Human"
  L7_2 = "Drop"
  L8_2 = A0_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L6_2 = Object
  L6_2 = L6_2.Remove
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2[A0_2] = L3_2
end

OnActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = tEvents
    L2_2 = L2_2[A0_2]
    L1_2(L2_2)
  end
end

OnDeactivate = L0_1
