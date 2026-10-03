local L0_1, L1_1
L0_1 = inherit
L1_1 = "MecJob"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  A0_2.sVehImg = "global_polaroid_belmont"
  A0_2.sVehLabel = "rtr"
  A0_2.sObjText = "[MecJob001.Objectives.001]"
  A0_2.iMinHealth = 30
  L1_2 = {}
  L2_2 = "Fiona-In-Mission-Job-Mec01-02"
  L1_2[1] = L2_2
  A0_2.sIntro = L1_2
  A0_2.sWrongVeh = "Eva-In-Mission-Contract-Mech01-80"
  A0_2.sRightVeh = "Fiona-In-Mission-Job-Mec01-03"
  L1_2 = {}
  L2_2 = "mecjob001.rtrspawn1"
  L3_2 = "mecjob001.rtrspawn2"
  L4_2 = "mecjob001.rtrspawn3"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L2_2 = MecJob
  L2_2 = L2_2.Activated
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = Math
  L2_2 = L2_2.randi
  L3_2 = #L1_2
  L2_2 = L2_2(L3_2)
  L3_2 = MrxUtil
  L3_2 = L3_2.SpawnObject
  L4_2 = "RTR (crappy)"
  L5_2 = L1_2[L2_2]
  L3_2(L4_2, L5_2)
end

Activated = L0_1
