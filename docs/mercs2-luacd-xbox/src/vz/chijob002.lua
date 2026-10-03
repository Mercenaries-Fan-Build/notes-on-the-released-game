local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1
L0_1 = inherit
L1_1 = "MrxTaskJobVerifySet"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = {}
L1_1 = {}
L1_1.vSequence = "Fiona-In-Mission-Job-Chi10-06"
L2_1 = {}
L2_1.vSequence = "Fiona-In-Mission-Job-Chi10-07"
L3_1 = {}
L3_1.vSequence = "Fiona-In-Mission-Job-Chi10-08"
L4_1 = {}
L4_1.vSequence = "Fiona-In-Mission-Job-Chi10-09"
L5_1 = {}
L6_1 = 9
L5_1[1] = L6_1
L4_1.tRange = L5_1
L5_1 = {}
L5_1.vSequence = "Fiona-In-Mission-Job-Chi10-10"
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1
L0_1[5] = L5_1
_tTargetCompleteVo = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "ChiJob002_Target_01"
  L4_2.sDefenseLayer = "Vz_State_ChiJob002_01"
  L4_2.sPristineLayer = "Vz_State_ChiJob002_01_Pristine"
  L4_2.sStagingLayer = "Vz_State_ChiJob002_01_Staging"
  L4_2.sVerifiedLayer = "Vz_State_ChiJob002_01_Staging"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-Chi02-06"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "ChiJob002_Target_02"
  L4_2.sDefenseLayer = "Vz_State_ChiJob002_02"
  L4_2.sPristineLayer = "Vz_State_ChiJob002_02_Pristine"
  L4_2.sStagingLayer = "Vz_State_ChiJob002_02_Staging"
  L4_2.sVerifiedLayer = "Vz_State_ChiJob002_02_Staging"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-Chi02-07"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "ChiJob002_Target_03"
  L4_2.sDefenseLayer = "Vz_State_ChiJob002_03"
  L4_2.sPristineLayer = "Vz_State_ChiJob002_03_Pristine"
  L4_2.sStagingLayer = "Vz_State_ChiJob002_02_Staging"
  L4_2.sVerifiedLayer = "Vz_State_ChiJob002_03_Staging"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-Chi02-08"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "ChiJob002_Target_04"
  L4_2.sDefenseLayer = "Vz_State_ChiJob002_04"
  L4_2.sPristineLayer = "Vz_State_ChiJob002_04_Pristine"
  L4_2.sStagingLayer = "Vz_State_ChiJob002_04_Staging"
  L4_2.sVerifiedLayer = "Vz_State_ChiJob002_02_Staging"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-Chi02-09"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "ChiJob002_Target_05"
  L4_2.sDefenseLayer = "Vz_State_ChiJob002_05"
  L4_2.sPristineLayer = "Vz_State_ChiJob002_05_Pristine"
  L4_2.sStagingLayer = "Vz_State_ChiJob002_05_Staging"
  L4_2.sVerifiedLayer = "Vz_State_ChiJob002_02_Staging"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-Chi02-10"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "ChiJob010_Target_01"
  L4_2.sDefenseLayer = "Vz_State_ChiJob010_01"
  L4_2.sPristineLayer = "Vz_State_ChiJob010_01_Pristine"
  L4_2.sStagingLayer = "Vz_State_ChiJob010_01_Staging"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-Chi10-02"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "ChiJob010_Target_02"
  L4_2.sDefenseLayer = "Vz_State_ChiJob010_02"
  L4_2.sPristineLayer = "Vz_State_ChiJob010_02_Pristine"
  L4_2.sStagingLayer = "Vz_State_ChiJob010_02_Staging"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-Chi10-01"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "ChiJob010_Target_03"
  L4_2.sDefenseLayer = "Vz_State_ChiJob010_03"
  L4_2.sStagingLayer = "Vz_State_ChiJob010_03_Staging"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-Chi10-13"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "ChiJob010_Target_04"
  L4_2.sDefenseLayer = "Vz_State_ChiJob010_04"
  L4_2.sPristineLayer = "Vz_State_ChiJob010_04_Pristine"
  L4_2.sStagingLayer = "Vz_State_ChiJob010_04_Staging"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-Chi10-14"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "ChiJob010_Target_05"
  L4_2.sDefenseLayer = "Vz_State_ChiJob010_05"
  L4_2.sPristineLayer = "Vz_State_ChiJob009_B_Pristine"
  L4_2.sStagingLayer = "Vz_State_ChiJob010_05_Staging"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-Chi10-15"
  L2_2(L3_2, L4_2)
  L2_2 = MrxLayerManager
  L2_2 = L2_2.MarkForAddition
  L3_2 = "Vz_State_ChiJob009_B_Pristine_tg"
  L2_2(L3_2)
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
  L3_2 = "Chi"
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
