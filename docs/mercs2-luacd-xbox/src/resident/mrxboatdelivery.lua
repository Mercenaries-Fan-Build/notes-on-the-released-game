local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxSupportDelivery"
L0_1(L1_1)
L0_1 = inherit
L1_1 = "MrxSupportDesignatorFlare"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = MrxSupportDelivery
  L3_2 = L2_2
  L2_2 = L2_2.Create
  L4_2 = A1_2
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = Create
  L2_2.Create = L3_2
  L4_2 = L2_2
  L3_2 = L2_2.SetCargo
  L5_2 = A0_2.sCargoToDeliver
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetModuleName
  L5_2 = "MrxBoatDelivery"
  L3_2(L4_2, L5_2)
  L3_2 = MrxSupportDesignatorFlare
  L4_2 = L3_2
  L3_2 = L3_2.Create
  L3_2 = L3_2(L4_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetAATestLevel
  L6_2 = "none"
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetDesignator
  L6_2 = L3_2
  L4_2(L5_2, L6_2)
  return L2_2
end

Create = L0_1
