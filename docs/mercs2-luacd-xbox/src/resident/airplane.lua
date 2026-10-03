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
L0_1 = "temp_radar_icon_airplane"
sTexture = L0_1
L0_1 = 5
nSize = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = getfenv
  L3_2 = L3_2()
  L5_2 = L3_2
  L4_2 = L3_2.Create
  L6_2 = A0_2
  L7_2 = A1_2
  L4_2 = L4_2(L5_2, L6_2, L7_2)
end

OnActivate = L0_1
