local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1
L0_1 = inherit
L1_1 = "MrxTaskJobDestroySet"
L0_1(L1_1)
L0_1 = {}
L1_1 = {}
L1_1.vSequence = "Fiona-None-Freeplay-None-07"
L2_1 = {}
L2_1.vSequence = "Fiona-In-Mission-Job-Oil08-02"
L3_1 = {}
L3_1.vSequence = "Fiona-In-Mission-Job-Oil08-03"
L4_1 = {}
L4_1.vSequence = "Fiona-In-Mission-Job-Oil08-03"
L5_1 = {}
L5_1.vSequence = "Fiona-In-Mission-Job-Oil08-02"
L6_1 = {}
L6_1.vSequence = "Fiona-None-Freeplay-None-02"
L7_1 = {}
L7_1.vSequence = "Fiona-In-Mission-Job-Oil08-02"
L8_1 = {}
L8_1.vSequence = "Fiona-In-Mission-Job-Oil08-03"
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1
L0_1[5] = L5_1
L0_1[6] = L6_1
L0_1[7] = L7_1
L0_1[8] = L8_1
_tTargetNearbyVo = L0_1
L0_1 = {}
L1_1 = {}
L1_1.vSequence = "Fiona-In-Mission-Job-Oil08-04"
L2_1 = {}
L3_1 = 1
L2_1[1] = L3_1
L1_1.tRange = L2_1
L2_1 = {}
L2_1.vSequence = "Fiona-In-Mission-Job-Oil08-05"
L3_1 = {}
L4_1 = "["
L5_1 = 2
L6_1 = 7
L7_1 = "]"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L3_1[4] = L7_1
L2_1.tRange = L3_1
L3_1 = {}
L3_1.vSequence = "Fiona-In-Mission-Job-Oil08-06"
L4_1 = {}
L5_1 = "["
L6_1 = 8
L7_1 = 12
L8_1 = "]"
L4_1[1] = L5_1
L4_1[2] = L6_1
L4_1[3] = L7_1
L4_1[4] = L8_1
L3_1.tRange = L4_1
L4_1 = {}
L4_1.vSequence = "Fiona-In-Mission-Job-Oil08-07"
L5_1 = {}
L6_1 = 13
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
  L4_2.sTarget = "OilJob008b_Pristine_Objective 1"
  L4_2.sPristineLayer = "Vz_State_OilJob008_B_Pristine"
  L4_2.sDefenseLayer = "Vz_State_OilJob008_B_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_OilJob008_B_Destroyed"
  L4_2.sStagingLayer = "Vz_State_OilJob008_B_Staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "_maracaibo_bld_corner32x32B 0x0009b1e1"
  L4_2.sPristineLayer = "Vz_State_OilJob008_C_Pristine"
  L4_2.sDefenseLayer = "Vz_State_OilJob008_C_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_OilJob008_C_Destroyed"
  L4_2.sStagingLayer = "Vz_State_OilJob008_C_Staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "_OilJob008a_Pristine_Objective 4"
  L4_2.sPristineLayer = "Vz_State_PirJob002_01_Pristine"
  L4_2.sDefenseLayer = "Vz_State_PirJob002_01_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_PirJob002_01_Captured"
  L4_2.sStagingLayer = "Vz_State_PirJob002_01_Staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "_OilJob008a_Pristine_Objective 5"
  L4_2.sPristineLayer = "Vz_State_GurJob005_Pristine"
  L4_2.sDefenseLayer = "Vz_State_GurJob005_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_GurJob005_Captured"
  L4_2.sStagingLayer = "Vz_State_GurJob005_Staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "_OilJob008a_Pristine_Objective 6"
  L4_2.sPristineLayer = "Vz_State_OilJob008_k_Pristine"
  L4_2.sDefenseLayer = "Vz_State_OilJob008_k_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_OilJob008_k_Ruined"
  L4_2.sStagingLayer = "Vz_State_OilJob008_k_Staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "_OilJob008a_Pristine_Objective 7"
  L4_2.sPristineLayer = "Vz_State_OilJob008_l_Pristine"
  L4_2.sDefenseLayer = "Vz_State_OilJob008_l_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_OilJob008_l_Ruined"
  L4_2.sStagingLayer = "Vz_State_OilJob008_l_Staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "_OilJob008a_Pristine_Objective 8"
  L4_2.sPristineLayer = "Vz_State_OilJob008_m_Pristine"
  L4_2.sDefenseLayer = "Vz_State_OilJob008_m_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_OilJob008_m_Ruined"
  L4_2.sStagingLayer = "Vz_State_OilJob008_m_Staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "_OilJob008_D_Pristine_Objective 1"
  L4_2.sPristineLayer = "Vz_State_OilJob008_D_Pristine"
  L4_2.sDefenseLayer = "Vz_State_OilJob008_D_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_OilJob008_D_Ruined"
  L4_2.sStagingLayer = "Vz_State_OilJob008_D_Staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "_OilJob008_E_Pristine_Objective 1"
  L4_2.sPristineLayer = "Vz_State_OilJob008_E_Pristine"
  L4_2.sDefenseLayer = "Vz_State_OilJob008_E_Defenses"
  L4_2.sStagingLayer = "Vz_State_OilJob008_E_Staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "_OilJob008_F_Pristine_Objective 1"
  L4_2.sPristineLayer = "Vz_State_OilJob008_F_Pristine"
  L4_2.sDefenseLayer = "Vz_State_OilJob008_F_Defenses"
  L4_2.sStagingLayer = "Vz_State_OilJob008_F_Staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "_OilJob008_G_Pristine_Objective 1"
  L4_2.sPristineLayer = "Vz_State_OilJob008_G_Pristine"
  L4_2.sDefenseLayer = "Vz_State_OilJob008_G_Defenses"
  L4_2.sStagingLayer = "Vz_State_OilJob008_G_Staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "_OilJob008_H_Pristine_Objective 1"
  L4_2.sPristineLayer = "Vz_State_OilJob008_H_Pristine"
  L4_2.sDefenseLayer = "Vz_State_OilJob008_H_Defenses"
  L4_2.sStagingLayer = "Vz_State_OilJob008_H_Staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "_OilJob008_J_Pristine_Objective 1"
  L4_2.sPristineLayer = "Vz_State_OilJob008_J_Pristine"
  L4_2.sDefenseLayer = "Vz_State_OilJob008_J_Defenses"
  L4_2.sStagingLayer = "Vz_State_OilJob008_J_Staging"
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
