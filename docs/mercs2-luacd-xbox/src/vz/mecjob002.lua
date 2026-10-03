local L0_1, L1_1
L0_1 = inherit
L1_1 = "MecJob"
L0_1(L1_1)

function L0_1(A0_2)
  local L1_2, L2_2
  A0_2.sVehImg = "global_polaroid_cortez"
  A0_2.sVehLabel = "m35"
  A0_2.sObjText = "[MecJob002.Objectives.001]"
  A0_2.iMinHealth = 30
  L1_2 = {}
  L2_2 = "Fiona-In-Mission-Job-Mec02-01"
  L1_2[1] = L2_2
  A0_2.sIntro = L1_2
  A0_2.sWrongVeh = "Eva-In-Mission-Contract-Mech01-07"
  A0_2.sRightVeh = "Fiona-In-Mission-Job-Mec02-02"
  A0_2.sPropVehTemplate = "Monster Truck phase1"
  L1_2 = MecJob
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
end

Activated = L0_1
