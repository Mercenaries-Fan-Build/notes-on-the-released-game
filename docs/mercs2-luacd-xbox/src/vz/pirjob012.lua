local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskJobVerifySet"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "PirJob012_Target_01"
  L4_2.sDefenseLayer = "Vz_State_PirJob012_01"
  L4_2.sPristineLayer = "Vz_State_PirJob012_01_Pristine"
  L4_2.sStagingLayer = "Vz_State_PirJob012_01_Staging"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-Pir12-01"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "PirJob012_Target_02"
  L4_2.sDefenseLayer = "Vz_State_PirJob012_02"
  L4_2.sPristineLayer = "Vz_State_PirJob012_02_Pristine"
  L4_2.sStagingLayer = "Vz_State_PirJob012_02_Staging"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-Pir12-16"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "PirJob012_Target_03"
  L4_2.sDefenseLayer = "Vz_State_PirJob012_03"
  L4_2.sPristineLayer = "Vz_State_PirJob012_03_Pristine"
  L4_2.sStagingLayer = "Vz_State_PirJob012_03_Staging"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-Pir12-02"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "PirJob012_Target_04"
  L4_2.sDefenseLayer = "Vz_State_PirJob012_04"
  L4_2.sStagingLayer = "Vz_State_PirJob012_04_Staging"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-Pir12-17"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "PirJob012_Target_05"
  L4_2.sDefenseLayer = "Vz_State_PirJob012_05"
  L4_2.sPristineLayer = "Vz_State_PirJob012_05_Pristine"
  L4_2.sStagingLayer = "Vz_State_PirJob012_05_Staging"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-Pir12-19"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "PirJob012_Target_06"
  L4_2.sDefenseLayer = "Vz_State_PirJob012_06"
  L4_2.sPristineLayer = "Vz_State_PirJob012_06_Pristine"
  L4_2.sStagingLayer = "Vz_State_PirJob012_06_Staging"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-Pir12-05"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "PirJob012_Target_07"
  L4_2.sDefenseLayer = "Vz_State_PirJob012_07"
  L4_2.sPristineLayer = "Vz_State_PirJob012_07_Pristine"
  L4_2.sStagingLayer = "Vz_State_PirJob012_07_Staging"
  L4_2.vNearVoSequence = "Fiona.Brian.05"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "PirJob012_Target_08"
  L4_2.sDefenseLayer = "Vz_State_PirJob012_08"
  L4_2.sPristineLayer = "Vz_State_PirJob012_08_Pristine"
  L4_2.sStagingLayer = "Vz_State_PirJob012_08_Staging"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-Pir12-21"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "PirJob012_Target_09"
  L4_2.sDefenseLayer = "Vz_State_PirJob012_09"
  L4_2.sPristineLayer = "Vz_State_PirJob012_09_Pristine"
  L4_2.sStagingLayer = "Vz_State_PirJob012_09_Staging"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-Pir12-10"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "PirJob012_Target_10"
  L4_2.sDefenseLayer = "Vz_State_PirJob012_10"
  L4_2.sPristineLayer = "Vz_State_PirJob012_10_Pristine"
  L4_2.sStagingLayer = "Vz_State_PirJob012_10_Staging"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-Pir12-23"
  L2_2(L3_2, L4_2)
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
  L3_2 = "Pir"
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

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxTaskJobVerifySet
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
