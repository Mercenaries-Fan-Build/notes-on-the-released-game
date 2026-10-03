local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTutorial"
L0_1(L1_1)

function L0_1()
  local L0_2, L1_2
  L0_2 = "[Tutorial.SatelliteInterrupted]"
  return L0_2
end

GetMessage = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "Satellite Targetting Start"
  
  function L6_2()
    local L0_3, L1_3
    L0_3 = true
    return L0_3
  end
  
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = SetupNextActivationCriteria
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

SetupActivationCriteria = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Object
  L1_2 = L1_2.GetHealth
  L2_2 = Player
  L2_2 = L2_2.GetLocalCharacter
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2 = L2_2()
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  A0_2._nPlayerHealth = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "Satellite Targetting Cancelled"
  
  function L6_2()
    local L0_3, L1_3
    L0_3 = true
    return L0_3
  end
  
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = ActivateTutorial2
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

SetupNextActivationCriteria = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2._nPlayerHealth
  L2_2 = Object
  L2_2 = L2_2.GetHealth
  L3_2 = Player
  L3_2 = L3_2.GetLocalCharacter
  L3_2 = L3_2()
  L2_2 = L2_2(L3_2)
  if L1_2 > L2_2 then
    L2_2 = A0_2
    L1_2 = A0_2.ActivateTutorial
    L3_2 = true
    L1_2(L2_2, L3_2)
  else
    L2_2 = A0_2
    L1_2 = A0_2.SetupActivationCriteria
    L1_2(L2_2)
  end
end

ActivateTutorial2 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
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
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

SetupCompletionCriteria = L0_1
