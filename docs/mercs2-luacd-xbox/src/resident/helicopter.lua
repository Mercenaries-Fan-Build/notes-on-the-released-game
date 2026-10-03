local L0_1, L1_1, L2_1, L3_1
L0_1 = inherit
L1_1 = "VehicleBlippable"
L0_1(L1_1)
L0_1 = {}
L1_1 = 255
L2_1 = 255
L3_1 = 255
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
tFlash = L0_1
L0_1 = "temp_radar_icon_helicopter"
sTexture = L0_1
L0_1 = 5
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
