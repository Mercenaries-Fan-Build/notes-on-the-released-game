local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1
L0_1 = inherit
L1_1 = "MrxTaskJobVerifySet"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = {}
L1_1 = {}
L1_1.vSequence = "Fiona-In-Mission-Job-All10-03"
L2_1 = {}
L2_1.vSequence = "Fiona-In-Mission-Job-All10-12"
L3_1 = {}
L3_1.vSequence = "Fiona-In-Mission-Job-All10-13"
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
_tTargetNearbyVo = L0_1
L0_1 = {}
L1_1 = {}
L1_1.vSequence = "Fiona-In-Mission-Job-All10-06"
L2_1 = {}
L2_1.vSequence = "Fiona-In-Mission-Job-All10-08"
L3_1 = {}
L3_1.vSequence = "Fiona-In-Mission-Job-All10-09"
L4_1 = {}
L4_1.vSequence = "Fiona-In-Mission-Job-All10-10"
L5_1 = {}
L6_1 = {}
L7_1 = {}
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1
L0_1[5] = L5_1
L0_1[6] = L6_1
L0_1[7] = L7_1
_tTargetCompleteVo = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "AllJob002_01_Target"
  L4_2.sDefenseLayer = "vz_State_AllJob002_01_Defenses"
  L4_2.sStagingLayer = "vz_State_AllJob002_01_staging"
  L4_2.sPristineLayer = "vz_State_AllJob002_01_pristine"
  L4_2.sVerifiedLayer = "vz_State_AllJob002_01_staging"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-All02-01"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "AllJob002_02_Target"
  L4_2.sDefenseLayer = "vz_State_AllJob002_02_Defenses"
  L4_2.sStagingLayer = "vz_State_AllJob002_02_staging"
  L4_2.sPristineLayer = "vz_State_AllJob002_02_pristine"
  L4_2.sVerifiedLayer = "vz_State_AllJob002_02_staging"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-All02-02"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "AllJob002_03_Target"
  L4_2.sDefenseLayer = "vz_State_AllJob002_03_Defenses"
  L4_2.sStagingLayer = "vz_State_AllJob002_03_staging"
  L4_2.sPristineLayer = "vz_State_AllJob002_03_pristine"
  L4_2.sVerifiedLayer = "vz_State_AllJob002_03_staging"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-All02-03"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "AllJob002_04_Target"
  L4_2.sDefenseLayer = "vz_State_AllJob002_04_Defenses"
  L4_2.sStagingLayer = "vz_State_AllJob002_04_staging"
  L4_2.sPristineLayer = "vz_State_AllJob002_04_pristine"
  L4_2.sVerifiedLayer = "vz_State_AllJob002_04_staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "AllJob002_05_Target"
  L4_2.sDefenseLayer = "vz_State_AllJob002_05_Defenses"
  L4_2.sStagingLayer = "vz_State_AllJob002_05_staging"
  L4_2.sPristineLayer = "vz_State_AllJob002_05_pristine"
  L4_2.sVerifiedLayer = "vz_State_AllJob002_05_staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "AllJob010_01_Target"
  L4_2.sDefenseLayer = "vz_State_AllJob010_01"
  L4_2.sStagingLayer = "vz_State_AllJob010_01_staging"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "AllJob010_02_Target"
  L4_2.sDefenseLayer = "vz_State_AllJob010_02"
  L4_2.sStagingLayer = "vz_State_AllJob010_02_staging"
  L4_2.sPristineLayer = "vz_State_AllJob010_02_pristine"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-All10-02"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "AllJob010_03_Target"
  L4_2.sDefenseLayer = "vz_State_AllJob010_03"
  L4_2.sStagingLayer = "vz_State_AllJob010_03_staging"
  L4_2.sPristineLayer = "vz_State_AllJob010_03_pristine"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "AllJob010_04_Target"
  L4_2.sDefenseLayer = "vz_State_AllJob010_04"
  L4_2.sStagingLayer = "vz_State_AllJob010_04_staging"
  L4_2.sPristineLayer = "vz_State_AllJob010_04_pristine"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-All10-04"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "AllJob010_05_Target"
  L4_2.sDefenseLayer = "vz_State_AllJob010_05"
  L4_2.sStagingLayer = "vz_State_AllJob010_05_staging"
  L4_2.sPristineLayer = "vz_State_AllJob010_05_pristine"
  L4_2.vNearVoSequence = "Fiona-In-Mission-Job-All10-05"
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
  L1_2 = A0_2.JeepRegionActivate
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._SetFactionId
  L3_2 = "All"
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
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Region_AllJob002_04_TriggerJeep"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = JeepAssault
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

JeepRegionActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Ai
  L1_2 = L1_2.Goal
  L2_2 = {}
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "AllJob002_04_Jeep01"
  L4_2, L5_2 = L4_2(L5_2)
  L3_2 = L3_2(L4_2, L5_2)
  L2_2.AIGuid = L3_2
  L2_2.Goal = "PathMove"
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "Path_AllJob002_Jeep01"
  L3_2 = L3_2(L4_2)
  L2_2.Target = L3_2
  L2_2.Mode = "Oneway"
  L2_2.Priority = "hiPri"
  L2_2.Haste = 0.7
  L1_2(L2_2)
end

JeepAssault = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxTaskJobVerifySet
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
