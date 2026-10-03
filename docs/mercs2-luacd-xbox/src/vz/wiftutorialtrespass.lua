local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTutorial"
L0_1(L1_1)

function L0_1()
  local L0_2, L1_2
  L0_2 = "[Tutorial.Trespassing]"
  return L0_2
end

GetMessage = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A0_2._CompleteEvent
  if not L2_2 then
    L2_2 = MrxTutorial
    L2_2 = L2_2.ActivateTutorial
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  end
end

ActivateTutorial = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = A0_2._CompleteEvent
  if not L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = 10
    L4_2[1] = L5_2
    L5_2 = A0_2.EndTutorial
    L6_2 = {}
    L7_2 = A0_2
    L8_2 = true
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
    A0_2._CompleteEvent = L1_2
  end
end

SetupCompletionCriteria = L0_1
