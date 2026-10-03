local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1
L0_1 = inherit
L1_1 = "MrxTaskJobVerifySet"
L0_1(L1_1)
L0_1 = {}
L1_1 = {}
L1_1.vSequence = "Fiona-In-Mission-Job-Oil11-01"
L2_1 = {}
L2_1.vSequence = "Fiona-In-Mission-Job-Oil11-04"
L3_1 = {}
L3_1.vSequence = "Fiona-In-Mission-Job-Oil11-01"
L4_1 = {}
L4_1.vSequence = "Fiona-In-Mission-Job-Oil11-04"
L5_1 = {}
L5_1.vSequence = "Fiona-In-Mission-Job-Oil11-04"
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1
L0_1[5] = L5_1
_tTargetNearbyVo = L0_1
L0_1 = {}
L1_1 = {}
L1_1.vSequence = "Fiona-In-Mission-Job-Oil11-14"
L2_1 = {}
L3_1 = "["
L4_1 = 1
L5_1 = 9
L6_1 = "]"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L2_1[4] = L6_1
L1_1.tRange = L2_1
L2_1 = {}
L2_1.vSequence = "Fiona-In-Mission-Job-Oil11-15"
L3_1 = {}
L4_1 = "["
L5_1 = 1
L6_1 = 9
L7_1 = "]"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L3_1[4] = L7_1
L2_1.tRange = L3_1
L3_1 = {}
L3_1.vSequence = "Fiona-In-Mission-Job-All03-08"
L4_1 = {}
L5_1 = "["
L6_1 = 1
L7_1 = 9
L8_1 = "]"
L4_1[1] = L5_1
L4_1[2] = L6_1
L4_1[3] = L7_1
L4_1[4] = L8_1
L3_1.tRange = L4_1
L4_1 = {}
L4_1.vSequence = "Fiona-In-Mission-Job-All03-09"
L5_1 = {}
L6_1 = "["
L7_1 = 1
L8_1 = 9
L9_1 = "]"
L5_1[1] = L6_1
L5_1[2] = L7_1
L5_1[3] = L8_1
L5_1[4] = L9_1
L4_1.tRange = L5_1
L5_1 = {}
L5_1.vSequence = "Fiona-In-Mission-Job-Oil11-16"
L6_1 = {}
L7_1 = "["
L8_1 = 2
L9_1 = 9
L10_1 = "]"
L6_1[1] = L7_1
L6_1[2] = L8_1
L6_1[3] = L9_1
L6_1[4] = L10_1
L5_1.tRange = L6_1
L6_1 = {}
L6_1.vSequence = "Fiona-In-Mission-Job-Oil11-17"
L7_1 = {}
L8_1 = 10
L7_1[1] = L8_1
L6_1.tRange = L7_1
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1
L0_1[5] = L5_1
L0_1[6] = L6_1
_tTargetCompleteVo = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "OilJob011_Target_01"
  L4_2.sDefenseLayer = "vz_State_OilJob011_01"
  L4_2.sStagingLayer = "vz_State_OilJob011_01_staging"
  L4_2.sPristineLayer = "vz_State_OilJob011_01_pristine"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "OilJob011_Target_02"
  L4_2.sDefenseLayer = "vz_State_OilJob011_02"
  L4_2.sStagingLayer = "vz_State_OilJob011_02_staging"
  L4_2.sPristineLayer = "vz_State_OilJob011_02_pristine"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "OilJob011_Target_03"
  L4_2.sDefenseLayer = "vz_State_OilJob011_03"
  L4_2.sStagingLayer = "vz_State_OilJob011_03_staging"
  L4_2.sPristineLayer = "vz_State_OilJob011_03_pristine"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "OilJob011_Target_04"
  L4_2.sDefenseLayer = "vz_State_OilJob011_04"
  L4_2.sStagingLayer = "vz_State_OilJob011_04_staging"
  L4_2.sPristineLayer = "vz_State_OilJob011_04_pristine"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "OilJob011_Target_05"
  L4_2.sDefenseLayer = "vz_State_OilJob011_05"
  L4_2.sStagingLayer = "vz_State_OilJob011_05_staging"
  L4_2.sPristineLayer = "vz_State_OilJob011_05_pristine"
  L2_2(L3_2, L4_2)
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
    L10_2 = "OilJob012_Target_"
    L11_2 = L6_2
    L10_2 = L10_2 .. L11_2
    L9_2.sTarget = L10_2
    L10_2 = "vz_State_OilJob012_"
    L11_2 = L6_2
    L10_2 = L10_2 .. L11_2
    L9_2.sDefenseLayer = L10_2
    L10_2 = "vz_State_OilJob011_"
    L11_2 = L6_2
    L12_2 = "_staging"
    L10_2 = L10_2 .. L11_2 .. L12_2
    L9_2.sStagingLayer = L10_2
    L10_2 = "vz_State_OilJob011_"
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
  L3_2 = "Oil"
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
