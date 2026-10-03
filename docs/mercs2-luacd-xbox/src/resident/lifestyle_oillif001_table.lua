local L0_1, L1_1

function L0_1()
  local L0_2, L1_2
  L0_2 = SetStaging
  L0_2()
end

Init = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = 0
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "OilLif001 Table"
  L2_2 = L2_2(L3_2)
  L3_2 = Vehicle
  L3_2 = L3_2.GetRiders
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  L4_2 = pairs
  L5_2 = L3_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    if L1_2 == 0 then
      iRider1 = L8_2
      L1_2 = L1_2 + 1
    else
      iRider2 = L8_2
    end
  end
  L4_2 = Human
  L4_2 = L4_2.SetState
  L5_2 = iRider1
  L6_2 = "InVehicle"
  L7_2 = "lifestylejobPlayerArmwrestlingWinningloop01"
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = Human
  L4_2 = L4_2.SetState
  L5_2 = iRider2
  L6_2 = "InVehicle"
  L7_2 = "lifestylejobOpponentArmwrestlingWinningloop01"
  L4_2(L5_2, L6_2, L7_2)
end

SetStaging = L0_1
