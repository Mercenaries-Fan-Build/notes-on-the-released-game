local L0_1, L1_1, L2_1, L3_1
L0_1 = inherit
L1_1 = "MrxTaskJobDestroyType"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = {}
L1_1 = {}
L1_1.vSequence = "Fiona-In-Mission-Job-Gur01-03"
L1_1.nWeight = 3
L2_1 = {}
L2_1.vSequence = "Fiona-In-Mission-Job-Gur01-04"
L2_1.nWeight = 3
L3_1 = {}
L3_1.vSequence = "Fiona-In-Mission-Job-Gur01-05"
L3_1.nWeight = 3
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
_tTargetCompleteVo = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxTaskJobDestroyType
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._SetShortDescription
  L3_2 = "[GurJob001.Terms.Summary]"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._SetLabelFilter
  L3_2 = "Billboard"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._SetHeroOnly
  L3_2 = true
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._SetTargetCompleteVo
  L3_2 = _tTargetCompleteVo
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._Go
  L1_2(L2_2)
end

Activated = L0_1
