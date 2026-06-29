local L0_1, L1_1, L2_1, L3_1
L0_1 = inherit
L1_1 = "Blippable"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = {}
L1_1 = 100
L2_1 = 75
L3_1 = 255
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
tColor = L0_1
L0_1 = "MiniMap_Icon_Clock_DLC"
sTexture = L0_1
L0_1 = 8
nSize = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectHibernation
  L5_2 = {}
  L6_2 = A0_2
  L7_2 = "awake"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = Start
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A1_2
  L10_2 = A2_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
end

OnActivate = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = Object
  L3_2 = L3_2.GetHealth
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  L4_2 = type
  L5_2 = L3_2
  L4_2 = L4_2(L5_2)
  if L4_2 == "number" and 0 < L3_2 then
    L4_2 = getfenv
    L4_2 = L4_2()
    L6_2 = L4_2
    L5_2 = L4_2.Create
    L7_2 = A0_2
    L8_2 = A1_2
    L5_2 = L5_2(L6_2, L7_2, L8_2)
  end
end

Start = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  L4_2 = math
  L4_2 = L4_2.randf
  L5_2 = -2
  L6_2 = 2
  L4_2 = L4_2(L5_2, L6_2)
  L5_2 = math
  L5_2 = L5_2.randf
  L6_2 = -2
  L7_2 = 2
  L5_2 = L5_2(L6_2, L7_2)
  L6_2 = Pg
  L6_2 = L6_2.Spawn
  L7_2 = "DLCCon004_Timer_Pickup"
  L8_2 = L1_2 + L4_2
  L9_2 = L2_2 + 4
  L10_2 = L3_2 + L5_2
  L6_2(L7_2, L8_2, L9_2, L10_2)
  L6_2 = OnDeactivate
  L7_2 = A0_2
  L6_2(L7_2)
end

OnDeath = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = Blippable
  L3_2 = L3_2.Create
  L4_2 = A0_2
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetBlipped
  L6_2 = A1_2
  L4_2(L5_2, L6_2)
  return L3_2
end

Create = L0_1
