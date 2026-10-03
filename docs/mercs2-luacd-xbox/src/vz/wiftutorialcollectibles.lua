local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1
L0_1 = inherit
L1_1 = "MrxTutorial"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = "Collectibles tutorial."
L1_1 = 1
L2_1 = nil
L3_1 = false
L4_1 = {}
L5_1 = "[Tutorial.Collectibles]"
L6_1 = "[Tutorial.Collectibles2]"
L4_1[1] = L5_1
L4_1[2] = L6_1
L5_1 = nil

function L6_1()
  local L0_2, L1_2
  L0_2 = L0_1
  return L0_2
end

GetMessage = L6_1

function L6_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = uEvent
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uEvent
    L1_2(L2_2)
    L1_2 = nil
    uEvent = L1_2
  end
  L1_2 = ObjectFilter
  L1_2 = L1_2.Create
  L1_2 = L1_2()
  uFilter = L1_2
  L1_2 = ObjectFilter
  L1_2 = L1_2.SetFilter
  L2_2 = uFilter
  L3_2 = "SpareParts"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = uFilter
  L6_2 = Player
  L6_2 = L6_2.GetLocalCharacter
  L6_2 = L6_2()
  L7_2 = "<"
  L8_2 = 5
  L9_2 = false
  L10_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L5_2 = ShowMessage
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  uEvent = L1_2
end

SetupActivationCriteria = L6_1

function L6_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = L2_1
  if not L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.ActivateTutorial
    L3_2 = true
    L1_2 = L1_2(L2_2, L3_2)
    bResult = L1_2
    L1_2 = bResult
    if L1_2 then
      L1_2 = true
      L2_1 = L1_2
    end
  end
  L1_2 = L2_1
  if L1_2 then
    L1_2 = L3_1
    if not L1_2 then
      L1_2 = L4_1
      L2_2 = L1_1
      L1_2 = L1_2[L2_2]
      L0_1 = L1_2
      L1_2 = MrxTutorialManager
      L1_2 = L1_2.UpdateCurrentTutorial
      L2_2 = A0_2
      L3_2 = true
      L1_2 = L1_2(L2_2, L3_2)
      L2_2 = L5_1
      if L2_2 then
        L2_2 = Event
        L2_2 = L2_2.Delete
        L3_2 = L5_1
        L2_2(L3_2)
        L2_2 = nil
        L5_1 = L2_2
      end
      L3_2 = A0_2
      L2_2 = A0_2._CreateEvent
      L4_2 = Event
      L4_2 = L4_2.TimerRelative
      L5_2 = {}
      L6_2 = 10
      L5_2[1] = L6_2
      L6_2 = HideMessage
      L7_2 = {}
      L8_2 = A0_2
      L7_2[1] = L8_2
      L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
      L5_1 = L2_2
      L2_2 = true
      L3_1 = L2_2
    end
  end
end

ShowMessage = L6_1

function L6_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.HideMessage
  L2_2 = false
  L3_2 = "Collectibles"
  L1_2(L2_2, L3_2)
  L1_2 = false
  L3_1 = L1_2
  L1_2 = L1_1
  L1_2 = L1_2 + 1
  L1_1 = L1_2
  L1_2 = L1_1
  if 2 < L1_2 then
    L1_2 = L5_1
    if L1_2 then
      L1_2 = Event
      L1_2 = L1_2.Delete
      L2_2 = L5_1
      L1_2(L2_2)
      L1_2 = nil
      L5_1 = L1_2
    end
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = 10
    L4_2[1] = L5_2
    L5_2 = EndTutorial
    L6_2 = {}
    L7_2 = A0_2
    L8_2 = true
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
    L5_1 = L1_2
  else
    L1_2 = SetupActivationCriteria
    L2_2 = A0_2
    L1_2(L2_2)
  end
end

HideMessage = L6_1

function L6_1(A0_2)
  local L1_2
end

SetupCompletionCriteria = L6_1

function L6_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = L5_1
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = L5_1
    L2_2(L3_2)
    L2_2 = nil
    L5_1 = L2_2
  end
  L2_2 = false
  L3_1 = L2_2
  L2_2 = MrxTutorial
  L2_2 = L2_2.EndTutorial
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

EndTutorial = L6_1
