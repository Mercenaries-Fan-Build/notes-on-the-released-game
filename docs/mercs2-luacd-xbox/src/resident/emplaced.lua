local L0_1, L1_1

function L0_1()
  local L0_2, L1_2
  L0_2 = uEvent
  if not L0_2 then
    L0_2 = {}
  end
  uEvent = L0_2
end

Init = L0_1

function L0_1()
  local L0_2, L1_2
  uEvent = L0_2
end

Deinit = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = uEvent
  L4_2 = uEvent
  L4_2 = L4_2[A0_2]
  if not L4_2 then
    L4_2 = {}
  end
  L3_2[A0_2] = L4_2
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectHibernation
  L5_2 = {}
  L6_2 = A0_2
  L7_2 = "awake"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = Activate
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
end

OnActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = CreateEnterEvent
  L2_2 = A0_2
  L1_2(L2_2)
end

Activate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = uEvent
  L2_2 = uEvent
  L2_2 = L2_2[A0_2]
  if not L2_2 then
    L2_2 = {}
  end
  L1_2[A0_2] = L2_2
  L1_2 = uEvent
  L1_2 = L1_2[A0_2]
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ObjectInSeat
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = A0_2
  L7_2 = "Gunner"
  L8_2 = "enter"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = Enter
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  L1_2.Enter = L2_2
end

CreateEnterEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = uEvent
  L3_2 = uEvent
  L3_2 = L3_2[A0_2]
  if not L3_2 then
    L3_2 = {}
  end
  L2_2[A0_2] = L3_2
  L2_2 = uEvent
  L2_2 = L2_2[A0_2]
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectInSeat
  L5_2 = {}
  L6_2 = A1_2
  L7_2 = A0_2
  L8_2 = "Gunner"
  L9_2 = "exit"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L6_2 = Exit
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L2_2.Exit = L3_2
end

CreateExitEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = Object
  L2_2 = L2_2.IsPlayerControlled
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = Player
    L3_2 = L3_2.IsLocal
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      goto lbl_14
    end
  end
  do return end
  ::lbl_14::
  L3_2 = Player
  L3_2 = L3_2.GetCamera
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L4_2 = Graphics
    L4_2 = L4_2.Camera
    L4_2 = L4_2.SetFocusParams
    L5_2 = 0
    L6_2 = 0
    L7_2 = 2
    L8_2 = 2
    L9_2 = 600
    L10_2 = 4
    L11_2 = 0
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  end
  L4_2 = CreateExitEvent
  L5_2 = A1_2
  L6_2 = A0_2
  L4_2(L5_2, L6_2)
end

Enter = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = Object
  L2_2 = L2_2.IsPlayerControlled
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = Player
    L3_2 = L3_2.IsLocal
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      goto lbl_14
    end
  end
  do return end
  ::lbl_14::
  L3_2 = Player
  L3_2 = L3_2.GetCamera
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L4_2 = Graphics
    L4_2 = L4_2.Camera
    L4_2 = L4_2.RestoreFocusParams
    L5_2 = 0
    L6_2 = 0
    L4_2(L5_2, L6_2)
  end
  L4_2 = CreateEnterEvent
  L5_2 = A1_2
  L4_2(L5_2)
end

Exit = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = uEvent
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = uEvent
    L3_2 = L3_2[A0_2]
    L3_2 = L3_2.Enter
    L2_2(L3_2)
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = uEvent
    L3_2 = L3_2[A0_2]
    L3_2 = L3_2.Exit
    L2_2(L3_2)
    L2_2 = uEvent
    L2_2[A0_2] = nil
  end
end

OnDeactivate = L0_1
