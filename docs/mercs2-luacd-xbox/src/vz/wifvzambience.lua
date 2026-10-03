local L0_1, L1_1
L0_1 = {}
tBoundaryList = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L0_2 = pairs
  L1_2 = tBoundaryList
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = Pg
    L5_2 = L5_2.GetGuidByName
    L6_2 = L3_2
    L5_2 = L5_2(L6_2)
    L6_2 = SetupBoundaryEvent
    L7_2 = L5_2
    L8_2 = L4_2
    L9_2 = "any"
    L6_2(L7_2, L8_2, L9_2)
  end
end

Start = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  if A0_2 then
    L3_2 = Event
    L3_2 = L3_2.Create
    L4_2 = Event
    L4_2 = L4_2.Boundary
    L5_2 = {}
    L6_2 = Player
    L6_2 = L6_2.GetLocalCharacter
    L6_2 = L6_2()
    L7_2 = A0_2
    L8_2 = A2_2
    L9_2 = false
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L5_2[4] = L9_2
    L6_2 = CrossedBoundary
    L7_2 = {}
    L8_2 = A1_2
    L7_2[1] = L8_2
    L3_2(L4_2, L5_2, L6_2, L7_2)
  end
end

SetupBoundaryEvent = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2
  if not A2_2 or not A0_2 then
    return
  end
  if A3_2 == "enter" then
    L4_2 = Sound
    L4_2 = L4_2.CueAmbience
    L5_2 = A0_2
    L4_2(L5_2)
    L4_2 = SetupBoundaryEvent
    L5_2 = A2_2
    L6_2 = A0_2
    L7_2 = "exit"
    L4_2(L5_2, L6_2, L7_2)
  elseif A3_2 == "exit" then
    L4_2 = Sound
    L4_2 = L4_2.StopAmbience
    L5_2 = A0_2
    L4_2(L5_2)
    L4_2 = SetupBoundaryEvent
    L5_2 = A2_2
    L6_2 = A0_2
    L7_2 = "enter"
    L4_2(L5_2, L6_2, L7_2)
  end
end

CrossedBoundary = L0_1
