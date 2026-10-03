local L0_1, L1_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = Vehicle
  L2_2 = L2_2.GetRiders
  L3_2 = A0_2
  L4_2 = "driver"
  L2_2 = L2_2(L3_2, L4_2)
  if not L2_2 then
    L2_2 = {}
  end
  L3_2 = L2_2[1]
  if L3_2 == nil then
    L3_2 = Vehicle
    L3_2 = L3_2.OpenDoor
    L4_2 = A0_2
    L5_2 = "DriverHatch"
    L3_2(L4_2, L5_2)
  end
end

OnActivate = L0_1
