local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTutorial"
L0_1(L1_1)

function L0_1()
  local L0_2, L1_2
  L0_2 = "[Tutorial.Swimming]"
  return L0_2
end

GetMessage = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2 = L1_2()
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.HumanStateTransition
  L5_2 = {}
  L6_2 = L1_2
  L7_2 = "*"
  L8_2 = "Swim.*"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L6_2 = A0_2.ActivateTutorial
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = true
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

SetupActivationCriteria = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2 = L1_2()
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.HumanStateTransition
  L5_2 = {}
  L6_2 = L1_2
  L7_2 = "Swim.*"
  L8_2 = "Upright.*"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L6_2 = A0_2.EndTutorial
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = false
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.HumanStateTransition
  L5_2 = {}
  L6_2 = L1_2
  L7_2 = "Swim.*"
  L8_2 = "InVehicle.*"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L6_2 = A0_2.EndTutorial
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = false
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

SetupCancellationCriteria = L0_1
