local L0_1, L1_1
L0_1 = inherit
L1_1 = "Blippable"
L0_1(L1_1)
L0_1 = true
bRotate = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = getfenv
  L3_2 = L3_2()
  L5_2 = L3_2
  L4_2 = L3_2.Create
  L6_2 = A0_2
  L7_2 = A1_2
  L4_2 = L4_2(L5_2, L6_2, L7_2)
end

OnActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2.AddObjective
  L3_2 = A0_2.bFlash
  L1_2(L2_2, L3_2)
end

TimerCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  A0_2.bOriented = true
  L1_2 = Blippable
  L1_2 = L1_2.SetBlipped
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = A0_2.TimerEvent
  if not L1_2 then
    L1_2 = A0_2.bFlash
    if L1_2 then
      L1_2 = Event
      L1_2 = L1_2.CreatePersistent
      L2_2 = Event
      L2_2 = L2_2.TimerRelative
      L3_2 = {}
      L4_2 = 0.05
      L3_2[1] = L4_2
      L4_2 = TimerCallback
      L5_2 = {}
      L6_2 = A0_2
      L5_2[1] = L6_2
      L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
      A0_2.TimerEvent = L1_2
    end
  end
end

SetBlipped = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2.TimerEvent
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2.TimerEvent
    L1_2(L2_2)
    A0_2.TimerEvent = nil
  end
  L1_2 = Blippable
  L1_2 = L1_2.ClearBlipped
  L2_2 = A0_2
  L1_2(L2_2)
end

ClearBlipped = L0_1
