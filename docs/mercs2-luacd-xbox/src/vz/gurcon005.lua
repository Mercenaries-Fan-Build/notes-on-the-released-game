local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxLayerManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = {}
  L3_2 = "VZ_state_gurcon005"
  L4_2 = "VZ_state_gurcon005_junglebase"
  L5_2 = "VZ_state_gurcon005_airportdefbase"
  L6_2 = "VZ_state_gurcon005_depot"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
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
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = 0
  TargetsKilled = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Assassinate Universal Petroleum Targets"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = {}
  L5_2 = "GurCon005_Target01"
  L6_2 = "GurCon005_Target02"
  L7_2 = "GurCon005_Target03"
  L8_2 = "GurCon005_Target04"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L3_2.vTgtInclude = L4_2
  L3_2.bDspBlp = true
  L3_2.sDspShortDesc = "[GurCon005.Objectives.005]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = TargetKilledVO
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnPartComplete = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.Complete
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.Cancel
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnCancel = L4_2
  L4_2 = {}
  L3_2.vVoSeqOnAdd = L4_2
  L1_2(L2_2, L3_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = false
  bNoReport = L1_2
end

Reported = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = TargetsKilled
  if L1_2 == 0 then
    L1_2 = MrxVoSequence
    L1_2 = L1_2.Start
    L2_2 = {}
    L3_2 = "Fiona-In-Mission-MinorContract-Gur05-17"
    L2_2[1] = L3_2
    L1_2(L2_2)
  else
    L1_2 = TargetsKilled
    if L1_2 == 1 then
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = "Fiona-In-Mission-MinorContract-Gur05-18"
      L2_2[1] = L3_2
      L1_2(L2_2)
    else
      L1_2 = TargetsKilled
      if L1_2 == 2 then
        L1_2 = MrxVoSequence
        L1_2 = L1_2.Start
        L2_2 = {}
        L3_2 = "Fiona-In-Mission-MinorContract-Gur05-20"
        L2_2[1] = L3_2
        L1_2(L2_2)
      else
        L1_2 = TargetsKilled
        if L1_2 == 3 then
          L1_2 = MrxVoSequence
          L1_2 = L1_2.Start
          L2_2 = {}
          L3_2 = "Fiona-In-Mission-MinorContract-Gur05-21"
          L2_2[1] = L3_2
          L1_2(L2_2)
        end
      end
    end
  end
  L1_2 = TargetsKilled
  L1_2 = L1_2 + 1
  TargetsKilled = L1_2
end

TargetKilledVO = L0_1
