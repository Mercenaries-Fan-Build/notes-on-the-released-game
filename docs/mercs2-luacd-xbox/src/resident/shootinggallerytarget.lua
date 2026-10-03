local L0_1, L1_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = Sys
  L3_2 = L3_2.GuidToString
  L4_2 = A2_2
  L3_2 = L3_2(L4_2)
  if L3_2 == "0x7687DF41" then
    L4_2 = Vehicle
    L4_2 = L4_2.OpenDoor
    L5_2 = A0_2
    L6_2 = "pivot"
    L4_2(L5_2, L6_2)
  elseif L3_2 == "0xACB51200" then
    L4_2 = Vehicle
    L4_2 = L4_2.CloseDoor
    L5_2 = A0_2
    L6_2 = "pivot"
    L4_2(L5_2, L6_2)
  end
end

OnStateChange = L0_1
