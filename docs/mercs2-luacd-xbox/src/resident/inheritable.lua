local L0_1, L1_1
L0_1 = {}
tInstance = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectHibernation
  L5_2 = {}
  L6_2 = A0_2
  L7_2 = "awake"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = Awake
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A2_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
end

OnActivate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = getfenv
  L2_2 = L2_2()
  L4_2 = L2_2
  L3_2 = L2_2.Create
  L5_2 = A0_2
  L6_2 = A1_2
  L3_2 = L3_2(L4_2, L5_2, L6_2)
end

Awake = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = tInstance
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L3_2 = L1_2
    L2_2 = L1_2.Delete
    L2_2(L3_2)
  end
end

OnDeactivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = OnDeactivate
  L2_2 = A0_2
  L1_2(L2_2)
end

OnDeath = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = {}
  L4_2 = setmetatable
  L5_2 = L3_2
  L6_2 = {}
  L6_2.__index = A0_2
  L4_2(L5_2, L6_2)
  L3_2.uGuid = A1_2
  L4_2 = tostring
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  L3_2.sName = L4_2
  L4_2 = tInstance
  L4_2[A1_2] = L3_2
  return L3_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = tInstance
  L2_2 = A0_2.uGuid
  L1_2[L2_2] = nil
end

Delete = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = tInstance
  L1_2 = L1_2[A0_2]
  return L1_2
end

GetFromGuid = L0_1
