local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTutorial"
L0_1(L1_1)

function L0_1()
  local L0_2, L1_2
  L0_2 = "[Tutorial.WheeledVehicleBasic]"
  return L0_2
end

GetMessage = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectInSeat
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetLocalCharacter
  L5_2 = L5_2()
  L6_2 = "Car"
  L7_2 = "D"
  L8_2 = "E"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = A0_2.ActivateTutorial2
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  A0_2._oActivate1 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectInSeat
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetLocalCharacter
  L5_2 = L5_2()
  L6_2 = "Car"
  L7_2 = "D"
  L8_2 = "I"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = A0_2.ActivateTutorial2
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  A0_2._oActivate1 = L1_2
end

SetupActivationCriteria = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2._oActivate1
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2._oActivate1
    L1_2(L2_2)
  end
  L1_2 = A0_2._oActivate2
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2._oActivate1
    L1_2(L2_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2.ActivateTutorial
  L3_2 = true
  L1_2(L2_2, L3_2)
end

ActivateTutorial2 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectInSeat
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetLocalCharacter
  L5_2 = L5_2()
  L6_2 = "Car"
  L7_2 = "D"
  L8_2 = "X"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = A0_2.EndTutorial
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = false
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

SetupCancellationCriteria = L0_1
