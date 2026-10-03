local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxCinematic"
L0_1(L1_1)

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = MrxCinematic
  L1_2 = L1_2.PlaceholderSequence
  L2_2 = {}
  L3_2 = {}
  L3_2.sCaption = "This contract is not yet implemented."
  L2_2[1] = L3_2
  L3_2 = A0_2.Complete
  L4_2 = {}
  L5_2 = A0_2
  L4_2[1] = L5_2
  L1_2(L2_2, L3_2, L4_2)
end

Activated = L0_1
