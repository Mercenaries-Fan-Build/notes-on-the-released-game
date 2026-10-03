local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1
L0_1 = inherit
L1_1 = "MrxTaskJobDestroySet"
L0_1(L1_1)
L0_1 = {}
L1_1 = {}
L1_1.vSequence = "Fiona-None-Freeplay-None-08"
L2_1 = {}
L3_1 = "["
L4_1 = 1
L5_1 = 5
L6_1 = "]"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L2_1[4] = L6_1
L1_1.tRange = L2_1
L2_1 = {}
L2_1.vSequence = "Fiona-None-Freeplay-None-12"
L3_1 = {}
L4_1 = "["
L5_1 = 6
L6_1 = 10
L7_1 = "]"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L3_1[4] = L7_1
L2_1.tRange = L3_1
L3_1 = {}
L3_1.vSequence = "Fiona-None-Freeplay-None-07"
L4_1 = {}
L5_1 = 11
L4_1[1] = L5_1
L3_1.tRange = L4_1
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
_tTargetNearbyVo = L0_1
L0_1 = {}
L1_1 = {}
L1_1.vSequence = "Fiona-None-Freeplay-None-14"
L2_1 = {}
L3_1 = 1
L2_1[1] = L3_1
L1_1.tRange = L2_1
L2_1 = {}
L2_1.vSequence = "Fiona-In-Mission-Job-Chi10-08"
L3_1 = {}
L4_1 = "["
L5_1 = 2
L6_1 = 5
L7_1 = "]"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L3_1[4] = L7_1
L2_1.tRange = L3_1
L3_1 = {}
L3_1.vSequence = "Fiona-None-Freeplay-None-15"
L4_1 = {}
L5_1 = "["
L6_1 = 6
L7_1 = 10
L8_1 = "]"
L4_1[1] = L5_1
L4_1[2] = L6_1
L4_1[3] = L7_1
L4_1[4] = L8_1
L3_1.tRange = L4_1
L4_1 = {}
L4_1.vSequence = "Fiona-In-Mission-Job-Chi07-06"
L5_1 = {}
L6_1 = 11
L5_1[1] = L6_1
L4_1.tRange = L5_1
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1
_tTargetCompleteVo = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "PirJob007_Objective1"
  L4_2.sPristineLayer = "Vz_State_PirJob007_A_Pristine"
  L4_2.sDefenseLayer = "Vz_State_PirJob007_A_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_PirJob007_A_Destroyed"
  L4_2.sStagingLayer = "Vz_State_PirJob007_A_Staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "PirJob007_Objective2"
  L4_2.sPristineLayer = "Vz_State_PirJob007_B_Pristine"
  L4_2.sDefenseLayer = "Vz_State_PirJob007_B_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_PirJob007_B_Destroyed"
  L4_2.sStagingLayer = "Vz_State_PirJob007_B_Staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "PirJob007_Objective3"
  L4_2.sPristineLayer = "Vz_State_PirJob007_C_Pristine"
  L4_2.sDefenseLayer = "Vz_State_PirJob007_C_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_PirJob007_C_Destroyed"
  L4_2.sStagingLayer = "Vz_State_PirJob007_C_Staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "PirJob007_Objective7"
  L4_2.sPristineLayer = "Vz_State_PirJob007_F_Pristine"
  L4_2.sDefenseLayer = "Vz_State_PirJob007_F_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_PirJob007_F_Destroyed"
  L4_2.sStagingLayer = "Vz_State_PirJob007_F_Staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "PirJob007_Objective8"
  L4_2.sPristineLayer = "Vz_State_PirJob007_G_Pristine"
  L4_2.sDefenseLayer = "Vz_State_PirJob007_G_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_PirJob007_G_Destroyed"
  L4_2.sStagingLayer = "Vz_State_PirJob007_G_Staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "PirJob010_Target01"
  L4_2.sPristineLayer = "Vz_State_PirJob010_01"
  L4_2.sDefenseLayer = "Vz_State_PirJob010_01_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_PirJob010_01_Destroyed"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "PirJob010_Target02"
  L4_2.sPristineLayer = "Vz_State_PirJob010_02"
  L4_2.sDefenseLayer = "Vz_State_PirJob010_02_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_PirJob010_02_Destroyed"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "PirJob010_Target03"
  L4_2.sPristineLayer = "Vz_State_PirJob010_03"
  L4_2.sDefenseLayer = "Vz_State_PirJob010_03_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_PirJob010_03_Destroyed"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "PirJob011_Target01"
  L4_2.sPristineLayer = "Vz_State_PirJob011_01"
  L4_2.sDefenseLayer = "Vz_State_PirJob011_01_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_PirJob011_01_Destroyed"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "PirJob011_Target02"
  L4_2.sPristineLayer = "Vz_State_PirJob011_02"
  L4_2.sDefenseLayer = "Vz_State_PirJob011_02_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_PirJob011_02_Destroyed"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "PirJob011_Target03"
  L4_2.sPristineLayer = "Vz_State_PirJob011_03"
  L4_2.sDefenseLayer = "Vz_State_PirJob011_03_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_PirJob011_03_Destroyed"
  L2_2(L3_2, L4_2)
  L2_2 = MrxTaskJobDestroySet
  L2_2 = L2_2.LoadAssets
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxTaskJobDestroySet
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
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

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxTaskJobDestroySet
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
