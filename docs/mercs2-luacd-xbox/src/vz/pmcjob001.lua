local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskJobCollectType"
L0_1(L1_1)

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxTaskJobCollectType
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._SetShortDescription
  L3_2 = "[PmcJob001.Objectives]"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._SetCollectName
  L3_2 = "[PmcJob001.Title]"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._SetLabelFilter
  L3_2 = "SpareParts"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._SetQuota
  L3_2 = 100
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._Go
  L1_2(L2_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxTaskJobCollectType
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
