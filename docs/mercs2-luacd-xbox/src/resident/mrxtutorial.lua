local L0_1, L1_1
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  if not A1_2 then
    L2_2 = {}
    A1_2 = L2_2
  end
  L2_2 = setmetatable
  L3_2 = A1_2
  L4_2 = {}
  L4_2.__index = A0_2
  L2_2(L3_2, L4_2)
  L2_2 = {}
  A1_2._tEvents = L2_2
  return A1_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = A0_2._tEvents
  if L1_2 then
    L1_2 = pairs
    L2_2 = A0_2._tEvents
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    for L4_2, L5_2 in L1_2, L2_2, L3_2 do
      L6_2 = Event
      L6_2 = L6_2.Delete
      L7_2 = L5_2
      L6_2(L7_2)
    end
    L1_2 = {}
    A0_2._tEvents = L1_2
  end
end

DestroyEvents = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.sName
  return L1_2
end

GetName = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = MrxTutorialManager
  L2_2 = L2_2.SetCurrentTutorial
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2 = L2_2(L3_2, L4_2)
  L4_2 = A0_2
  L3_2 = A0_2.DestroyEvents
  L3_2(L4_2)
  if L2_2 then
    L4_2 = A0_2
    L3_2 = A0_2.SetupCompletionCriteria
    L3_2(L4_2)
    L4_2 = A0_2
    L3_2 = A0_2.SetupCancellationCriteria
    L3_2(L4_2)
  else
    L4_2 = A0_2
    L3_2 = A0_2.SetupActivationCriteria
    L3_2(L4_2)
  end
  return L2_2
end

ActivateTutorial = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = MrxTutorialManager
  L2_2 = L2_2.HideCurrentTutorial
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    L4_2 = A0_2
    L3_2 = A0_2.DestroyEvents
    L3_2(L4_2)
    if A1_2 then
      L3_2 = MrxTutorialManager
      L3_2 = L3_2.DestroyTutorial
      L4_2 = A0_2
      L3_2(L4_2)
    else
      L4_2 = A0_2
      L3_2 = A0_2.SetupActivationCriteria
      L3_2(L4_2)
    end
  end
end

EndTutorial = L0_1

function L0_1(A0_2)
  local L1_2
end

SetupActivationCriteria = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 20
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

function L0_1(A0_2)
  local L1_2
end

SetupCancellationCriteria = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2
  L5_2 = Event
  L5_2 = L5_2.Create
  L6_2 = A1_2
  L7_2 = A2_2
  L8_2 = A3_2
  L9_2 = A4_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = table
  L6_2 = L6_2.insert
  L7_2 = A0_2._tEvents
  L8_2 = L5_2
  L6_2(L7_2, L8_2)
  return L5_2
end

_CreateEvent = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2
  L5_2 = Event
  L5_2 = L5_2.CreatePersistent
  L6_2 = A1_2
  L7_2 = A2_2
  L8_2 = A3_2
  L9_2 = A4_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = table
  L6_2 = L6_2.insert
  L7_2 = A0_2._tEvents
  L8_2 = L5_2
  L6_2(L7_2, L8_2)
  return L5_2
end

_CreatePersistentEvent = L0_1
