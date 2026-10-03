local L0_1, L1_1, L2_1
L0_1 = inherit
L1_1 = "MrxTaskJobVerifySet"
L0_1(L1_1)
L0_1 = {}
L1_1 = {}
L1_1.vSequence = "Fiona-In-Mission-Job-Gur12-01"
L0_1[1] = L1_1
_tTargetNearbyVo = L0_1
L0_1 = {}
L1_1 = {}
L1_1.vSequence = "Fiona-In-Mission-Job-All03-08"
L2_1 = {}
L2_1.vSequence = "Fiona-In-Mission-Job-All03-09"
L0_1[1] = L1_1
L0_1[2] = L2_1
_tTargetCompleteVo = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = 1
  L3_2 = 5
  L4_2 = 1
  for L5_2 = L2_2, L3_2, L4_2 do
    L6_2 = string
    L6_2 = L6_2.format
    L7_2 = "%02d"
    L8_2 = L5_2
    L6_2 = L6_2(L7_2, L8_2)
    L8_2 = A0_2
    L7_2 = A0_2._AddTarget
    L9_2 = {}
    L10_2 = "GurJob002_"
    L11_2 = L6_2
    L12_2 = "_Target"
    L10_2 = L10_2 .. L11_2 .. L12_2
    L9_2.sTarget = L10_2
    L10_2 = "vz_State_GurJob002_"
    L11_2 = L6_2
    L10_2 = L10_2 .. L11_2
    L9_2.sDefenseLayer = L10_2
    L10_2 = "vz_State_GurJob002_"
    L11_2 = L6_2
    L12_2 = "_staging"
    L10_2 = L10_2 .. L11_2 .. L12_2
    L9_2.sStagingLayer = L10_2
    L10_2 = "vz_State_GurJob002_"
    L11_2 = L6_2
    L12_2 = "_pristine"
    L10_2 = L10_2 .. L11_2 .. L12_2
    L9_2.sPristineLayer = L10_2
    L7_2(L8_2, L9_2)
  end
  L2_2 = 1
  L3_2 = 5
  L4_2 = 1
  for L5_2 = L2_2, L3_2, L4_2 do
    L6_2 = string
    L6_2 = L6_2.format
    L7_2 = "%02d"
    L8_2 = L5_2
    L6_2 = L6_2(L7_2, L8_2)
    L8_2 = A0_2
    L7_2 = A0_2._AddTarget
    L9_2 = {}
    L10_2 = "GurJob012_"
    L11_2 = L6_2
    L12_2 = "_Target"
    L10_2 = L10_2 .. L11_2 .. L12_2
    L9_2.sTarget = L10_2
    L10_2 = "vz_State_GurJob012_"
    L11_2 = L6_2
    L10_2 = L10_2 .. L11_2
    L9_2.sDefenseLayer = L10_2
    L10_2 = "vz_State_GurJob012_"
    L11_2 = L6_2
    L12_2 = "_staging"
    L10_2 = L10_2 .. L11_2 .. L12_2
    L9_2.sStagingLayer = L10_2
    L10_2 = "vz_State_GurJob012_"
    L11_2 = L6_2
    L12_2 = "_pristine"
    L10_2 = L10_2 .. L11_2 .. L12_2
    L9_2.sPristineLayer = L10_2
    L7_2(L8_2, L9_2)
  end
  L2_2 = MrxTaskJobVerifySet
  L2_2 = L2_2.LoadAssets
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxTaskJobVerifySet
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._SetFactionId
  L3_2 = "Gur"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._SetTargetNearbyVo
  L3_2 = _tTargetNearbyVo
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
