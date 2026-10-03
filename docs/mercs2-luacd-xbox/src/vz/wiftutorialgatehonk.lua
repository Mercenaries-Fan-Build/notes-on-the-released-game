local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTutorial"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)

function L0_1()
  local L0_2, L1_2
  L0_2 = "[Tutorial.GateHonk]"
  return L0_2
end

GetMessage = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = Sys
  L1_2 = L1_2.StringToGuid
  L2_2 = "0x000f9a64"
  L1_2 = L1_2(L2_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreatePersistentEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = L1_2
  L7_2 = Player
  L7_2 = L7_2.GetLocalCharacter
  L7_2 = L7_2()
  L8_2 = "<"
  L9_2 = 20
  L10_2 = false
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = ShowMessage
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  uEvent = L2_2
end

SetupActivationCriteria = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Player
  L1_2 = L1_2.GetVehicleDisguiseState
  L2_2 = {}
  L3_2 = Player
  L3_2 = L3_2.GetLocalCharacter
  L3_2 = L3_2()
  L2_2.Player = L3_2
  L1_2 = L1_2(L2_2)
  L2_2 = tostring
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if L2_2 == "true" then
    L2_2 = ActivateTutorial
    L3_2 = A0_2
    L4_2 = true
    L2_2(L3_2, L4_2)
  end
end

ShowMessage = L0_1
