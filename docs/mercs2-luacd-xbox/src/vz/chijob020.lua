local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1
L0_1 = inherit
L1_1 = "MrxTaskJobDestroySet"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxLayerManager"
L0_1(L1_1)
L0_1 = {}
L1_1 = {}
L1_1.vSequence = "Fiona-None-Freeplay-None-02"
L2_1 = {}
L3_1 = "["
L4_1 = 1
L5_1 = 2
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
L5_1 = 3
L6_1 = 5
L7_1 = "]"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L3_1[4] = L7_1
L2_1.tRange = L3_1
L3_1 = {}
L3_1.vSequence = "Fiona-None-Freeplay-None-08"
L4_1 = {}
L5_1 = "["
L6_1 = 6
L7_1 = 8
L8_1 = "]"
L4_1[1] = L5_1
L4_1[2] = L6_1
L4_1[3] = L7_1
L4_1[4] = L8_1
L3_1.tRange = L4_1
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
_tTargetNearbyVo = L0_1
L0_1 = {}
L1_1 = {}
L1_1.vSequence = "Fiona-In-Mission-Job-All05-06"
L2_1 = {}
L3_1 = "["
L4_1 = 1
L5_1 = 2
L6_1 = "]"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L2_1[4] = L6_1
L1_1.tRange = L2_1
L2_1 = {}
L2_1.vSequence = "Fiona-In-Mission-Job-Chi10-07"
L3_1 = {}
L4_1 = "["
L5_1 = 3
L6_1 = 7
L7_1 = "]"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L3_1[4] = L7_1
L2_1.tRange = L3_1
L3_1 = {}
L3_1.vSequence = "Fiona-In-Mission-Job-Chi10-10"
L4_1 = {}
L5_1 = 8
L4_1[1] = L5_1
L3_1.tRange = L4_1
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
_tTargetCompleteVo = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "_city_bld_corner16x16d 0x00123386"
  L4_2.sPristineLayer = "Vz_State_ChiJob005_A_Pristine"
  L4_2.sDefenseLayer = "Vz_State_ChiJob005_A_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_ChiJob005_A_Destroyed"
  L4_2.sStagingLayer = "Vz_State_ChiJob005_A_Staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "_caracas_bld_theater01 0x000ef1b1"
  L4_2.sPristineLayer = "Vz_State_ChiJob005_B_Pristine"
  L4_2.sDefenseLayer = "Vz_State_ChiJob005_B_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_ChiJob005_B_Destroyed"
  L4_2.sStagingLayer = "Vz_State_ChiJob005_B_Staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "_estate_bld_mansion03 0x000b277c"
  L4_2.sPristineLayer = "Vz_State_ChiJob005_C_Pristine"
  L4_2.sDefenseLayer = "Vz_State_ChiJob005_C_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_ChiJob005_C_Destroyed"
  L4_2.sStagingLayer = "Vz_State_ChiJob005_C_Staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "_caracas_bld_hospitalvargas 0x000a1b04"
  L4_2.sPristineLayer = "Vz_State_ChiJob005_D_Pristine"
  L4_2.sDefenseLayer = "Vz_State_ChiJob005_D_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_ChiJob005_D_Destroyed"
  L4_2.sStagingLayer = "Vz_State_ChiJob005_D_Staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "_caracas_bld_historical04 0x000a1a4a"
  L4_2.sPristineLayer = "Vz_State_ChiJob005_E_Pristine"
  L4_2.sDefenseLayer = "Vz_State_ChiJob005_E_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_ChiJob005_E_Destroyed"
  L4_2.sStagingLayer = "Vz_State_ChiJob005_E_Staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "_estate_bld_mansion01 0x000b279c"
  L4_2.sPristineLayer = "Vz_State_ChiJob005_F_Pristine"
  L4_2.sDefenseLayer = "Vz_State_ChiJob005_F_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_ChiJob005_F_Destroyed"
  L4_2.sStagingLayer = "Vz_State_ChiJob005_F_Staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "_estate_bld_mansion03 0x000a1d31"
  L4_2.sPristineLayer = "Vz_State_ChiJob005_G_Pristine"
  L4_2.sDefenseLayer = "Vz_State_ChiJob005_G_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_ChiJob005_G_Destroyed"
  L4_2.sStagingLayer = "Vz_State_ChiJob005_G_Staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "demo_obj_oilrig 0x0009878a"
  L4_2.sPristineLayer = "Vz_State_ChiJob009_A_Pristine"
  L4_2.sDefenseLayer = "Vz_State_ChiJob009_A_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_ChiJob009_A_Destroyed"
  L4_2.sStagingLayer = "Vz_State_ChiJob009_A_Staging"
  L2_2(L3_2, L4_2)
  L2_2 = MrxLayerManager
  L2_2 = L2_2.MarkForAddition
  L3_2 = "Vz_State_ChiJob009_A_Pristine_tg"
  L2_2(L3_2)
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
