local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1
L0_1 = inherit
L1_1 = "MrxTaskJobDestroySet"
L0_1(L1_1)
L0_1 = import
L1_1 = "DangerousBuilding"
L0_1(L1_1)
L0_1 = {}
L1_1 = {}
L1_1.vSequence = "Fiona-In-Mission-Job-Gur11-02"
L2_1 = {}
L2_1.vSequence = "Fiona-In-Mission-Job-Gur11-03"
L3_1 = {}
L3_1.vSequence = "Fiona-In-Mission-Job-Gur11-04"
L4_1 = {}
L4_1.vSequence = "Fiona-In-Mission-Job-Gur07-06"
L5_1 = {}
L5_1.vSequence = "Fiona-In-Mission-Job-Oil08-02"
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1
L0_1[5] = L5_1
_tTargetNearbyVo = L0_1
L0_1 = {}
L1_1 = {}
L1_1.vSequence = "Fiona.xfio164"
L2_1 = {}
L3_1 = "["
L4_1 = 1
L5_1 = 11
L6_1 = "]"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L2_1[4] = L6_1
L1_1.tRange = L2_1
L2_1 = {}
L2_1.vSequence = "Fiona.xfio165"
L3_1 = {}
L4_1 = "["
L5_1 = 1
L6_1 = 11
L7_1 = "]"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L3_1[4] = L7_1
L2_1.tRange = L3_1
L3_1 = {}
L3_1.vSequence = "Fiona-In-Mission-Job-Gur07-07"
L4_1 = {}
L5_1 = "["
L6_1 = 1
L7_1 = 11
L8_1 = "]"
L4_1[1] = L5_1
L4_1[2] = L6_1
L4_1[3] = L7_1
L4_1[4] = L8_1
L3_1.tRange = L4_1
L4_1 = {}
L4_1.vSequence = "Fiona-In-Mission-Job-Gur07-08"
L5_1 = {}
L6_1 = "["
L7_1 = 1
L8_1 = 11
L9_1 = "]"
L5_1[1] = L6_1
L5_1[2] = L7_1
L5_1[3] = L8_1
L5_1[4] = L9_1
L4_1.tRange = L5_1
L5_1 = {}
L5_1.vSequence = "Fiona-In-Mission-Job-Pir07-04"
L5_1.nWeight = 2
L6_1 = {}
L7_1 = "["
L8_1 = 3
L9_1 = 6
L10_1 = "]"
L6_1[1] = L7_1
L6_1[2] = L8_1
L6_1[3] = L9_1
L6_1[4] = L10_1
L5_1.tRange = L6_1
L6_1 = {}
L6_1.vSequence = "Fiona-In-Mission-Job-Gur11-05"
L7_1 = {}
L8_1 = "["
L9_1 = 1
L10_1 = 11
L11_1 = "]"
L7_1[1] = L8_1
L7_1[2] = L9_1
L7_1[3] = L10_1
L7_1[4] = L11_1
L6_1.tRange = L7_1
L7_1 = {}
L7_1.vSequence = "Fiona.cb2fio06"
L7_1.nWeight = 10
L8_1 = {}
L9_1 = "["
L10_1 = 12
L11_1 = 13
L12_1 = ")"
L8_1[1] = L9_1
L8_1[2] = L10_1
L8_1[3] = L11_1
L8_1[4] = L12_1
L7_1.tRange = L8_1
L8_1 = {}
L8_1.vSequence = "Fiona-In-Mission-Job-Gur07-10"
L8_1.nWeight = 10
L9_1 = {}
L10_1 = 13
L9_1[1] = L10_1
L8_1.tRange = L9_1
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1
L0_1[5] = L5_1
L0_1[6] = L6_1
L0_1[7] = L7_1
L0_1[8] = L8_1
_tTargetCompleteVo = L0_1
L0_1 = {}
L1_1 = "GurJob011a_Target"
L2_1 = "GurJob011b_Target"
L3_1 = "GurJob011c_Target"
L4_1 = "GurJob011d_Target"
L5_1 = "GurJob011e_Target"
L6_1 = "GurJob011f_Target"
L7_1 = "GurJob011g_Target"
L8_1 = "GurJob011h_Target"
L9_1 = "GurJob011i_Target"
L10_1 = "GurJob011j_Target"
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1
L0_1[5] = L5_1
L0_1[6] = L6_1
L0_1[7] = L7_1
L0_1[8] = L8_1
L0_1[9] = L9_1
L0_1[10] = L10_1
_tBuildings = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "GurJob007_Target01"
  L4_2.sPristineLayer = "Vz_State_GurJob007_01"
  L4_2.sDefenseLayer = "Vz_State_GurJob007_01_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_GurJob007_01_Destroyed"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "GurJob007_Target02"
  L4_2.sPristineLayer = "Vz_State_GurJob007_02"
  L4_2.sDefenseLayer = "Vz_State_GurJob007_02_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_GurJob007_02_Destroyed"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "GurJob007_Target03"
  L4_2.sPristineLayer = "Vz_State_GurJob007_03"
  L4_2.sDefenseLayer = "Vz_State_GurJob007_03_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_GurJob007_03_Destroyed"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "GurJob011a_Target"
  L4_2.sPristineLayer = "Vz_State_GurJob11_01"
  L4_2.sDefenseLayer = "Vz_State_GurJob011_01_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_GurJob011_01_Destroyed"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "GurJob011b_Target"
  L4_2.sPristineLayer = "Vz_State_GurJob11_02"
  L4_2.sDefenseLayer = "Vz_State_GurJob011_02_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_GurJob011_02_Destroyed"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "GurJob011c_Target"
  L4_2.sPristineLayer = "Vz_State_GurJob11_03"
  L4_2.sDefenseLayer = "Vz_State_GurJob011_03_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_GurJob011_03_Destroyed"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "GurJob011d_Target"
  L4_2.sPristineLayer = "Vz_State_GurJob11_04"
  L4_2.sDefenseLayer = "Vz_State_GurJob011_04_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_GurJob011_04_Destroyed"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "GurJob011e_Target"
  L4_2.sPristineLayer = "Vz_State_GurJob11_05"
  L4_2.sDefenseLayer = "Vz_State_GurJob011_05_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_GurJob011_05_Destroyed"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "GurJob011f_Target"
  L4_2.sPristineLayer = "Vz_State_GurJob11_06"
  L4_2.sDefenseLayer = "Vz_State_GurJob011_06_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_GurJob011_06_Destroyed"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "GurJob011g_Target"
  L4_2.sPristineLayer = "Vz_State_GurJob11_07"
  L4_2.sDefenseLayer = "Vz_State_GurJob011_07_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_GurJob011_07_Destroyed"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "GurJob011h_Target"
  L4_2.sPristineLayer = "Vz_State_GurJob11_08"
  L4_2.sDefenseLayer = "Vz_State_GurJob011_08_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_GurJob011_08_Destroyed"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "GurJob011i_Target"
  L4_2.sPristineLayer = "Vz_State_GurJob11_09"
  L4_2.sDefenseLayer = "Vz_State_GurJob011_09_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_GurJob011_09_Destroyed"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._AddTarget
  L4_2 = {}
  L4_2.sTarget = "GurJob011j_Target"
  L4_2.sPristineLayer = "Vz_State_GurJob11_10"
  L4_2.sDefenseLayer = "Vz_State_GurJob011_10_Defenses"
  L4_2.sDestroyedLayer = "Vz_State_GurJob011_10_Destroyed"
  L2_2(L3_2, L4_2)
  L2_2 = MrxTaskJobDestroySet
  L2_2 = L2_2.LoadAssets
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
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
  L1_2 = ActivateBuilding
  L2_2 = A0_2
  L3_2 = "GurJob007_Target01"
  L1_2(L2_2, L3_2)
  L1_2 = ActivateBuilding
  L2_2 = A0_2
  L3_2 = "GurJob007_Target02"
  L1_2(L2_2, L3_2)
  L1_2 = ActivateBuilding
  L2_2 = A0_2
  L3_2 = "GurJob007_Target03"
  L1_2(L2_2, L3_2)
  L1_2 = ipairs
  L2_2 = _tBuildings
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L7_2 = A0_2
    L6_2 = A0_2.ActivateBuilding
    L8_2 = L5_2
    L6_2(L7_2, L8_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2._Go
  L1_2(L2_2)
end

Activated = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  L3_2 = DangerousBuilding
  L3_2 = L3_2.TurnOn
  L4_2 = L2_2
  L5_2 = false
  L6_2 = true
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = Ai
  L3_2 = L3_2.TweakAttachedSpawners
  L4_2 = L2_2
  L5_2 = {}
  L5_2.SpawnerState = "on"
  L5_2.SpawnList = "Spawnlist (VZ Balcony)"
  L3_2(L4_2, L5_2)
  L3_2 = Ai
  L3_2 = L3_2.TweakAttachedSpawnersInGroup
  L4_2 = L2_2
  L5_2 = "Ground"
  L6_2 = {}
  L6_2.SpawnerState = "on"
  L6_2.SpawnList = "Spawnlist (VZ Ground)"
  L3_2(L4_2, L5_2, L6_2)
end

ActivateBuilding = L0_1
