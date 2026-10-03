local L0_1, L1_1
L0_1 = inherit
L1_1 = "MecJob"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = {}
  L3_2 = "vz_state_gua_upperclass_pristine"
  L4_2 = "Vz_State_MecJob"
  L5_2 = "Vz_State_MecJob003"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L3_2 = MrxLayerManager
  L3_2 = L3_2.Add
  L4_2 = L2_2
  L5_2 = A0_2.AssetsLoaded
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L3_2(L4_2, L5_2, L6_2)
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  A0_2.sVehImg = "global_polaroid_calderone"
  A0_2.sVehLabel = "amx30"
  A0_2.sObjText = "[MecJob003.Objectives.001]"
  A0_2.iMinHealth = 30
  L1_2 = {}
  L2_2 = "Fiona-In-Mission-Job-Mec03-01"
  L1_2[1] = L2_2
  A0_2.sIntro = L1_2
  A0_2.sWrongVeh = "Eva-In-Mission-Contract-Mech01-08"
  A0_2.sRightVeh = "Fiona-In-Mission-Job-Mec03-03"
  A0_2.sPropVehTemplate = "Monster Truck phase2"
  L1_2 = MecJob
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxLayerManager
  L1_2 = L1_2.MarkForRemoval
  L2_2 = "Vz_State_MecJob003"
  L1_2(L2_2)
  L1_2 = MecJob
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
