local L0_1, L1_1, L2_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiHudActionHijack"
L0_1(L1_1)
L0_1 = false
L1_1 = 5

function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L4_2 = Vehicle
  L4_2 = L4_2.IsFlying
  L5_2 = A3_2
  L4_2 = L4_2(L5_2)
  if L4_2 then
    L4_2 = _THIS
    L5_2 = L4_2
    L4_2 = L4_2.Create
    L6_2 = nil
    L7_2 = A0_2
    L8_2 = A1_2
    L9_2 = A2_2
    L10_2 = A3_2
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
    L4_2 = true
    return L4_2
  end
  L4_2 = false
  return L4_2
end

StartHijack = L2_1

function L2_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  if not A1_2 then
    L6_2 = {}
    A1_2 = L6_2
  end
  A1_2._hijacker = A2_2
  A1_2._hijackee = A3_2
  A1_2._seat = A4_2
  A1_2._vehicle = A5_2
  L6_2 = setmetatable
  L7_2 = A1_2
  L8_2 = {}
  L8_2.__index = A0_2
  L6_2(L7_2, L8_2)
  L6_2 = Object
  L6_2 = L6_2.IsPlayerControlled
  L7_2 = A1_2._hijacker
  L6_2 = L6_2(L7_2)
  A1_2._hijackerPlayer = L6_2
  L6_2 = A1_2._hijackerPlayer
  if L6_2 then
    L6_2 = L0_1
    if not L6_2 then
      A1_2._buttonPressed = false
      L6_2 = Event
      L6_2 = L6_2.Create
      L7_2 = Event
      L7_2 = L7_2.TimerRelative
      L8_2 = {}
      L9_2 = 0.9
      L8_2[1] = L9_2
      L9_2 = ButtonStart
      L10_2 = {}
      L11_2 = A1_2
      L10_2[1] = L11_2
      L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
      A1_2._buttonTimer = L6_2
  end
  else
    A1_2._buttonPressed = true
  end
  L6_2 = Human
  L6_2 = L6_2.SetState
  L7_2 = A1_2._hijacker
  L8_2 = "InVehicle"
  L9_2 = "ActionHijackHijackerA"
  L6_2(L7_2, L8_2, L9_2)
  L6_2 = Human
  L6_2 = L6_2.SetState
  L7_2 = A1_2._hijackee
  L8_2 = "InVehicle"
  L9_2 = "ActionHijackHijackeeA"
  L6_2(L7_2, L8_2, L9_2)
  L6_2 = Event
  L6_2 = L6_2.Create
  L7_2 = Event
  L7_2 = L7_2.HumanActionComplete
  L8_2 = {}
  L9_2 = A1_2._hijacker
  L8_2[1] = L9_2
  L9_2 = PullOutPilot
  L10_2 = {}
  L11_2 = A1_2
  L10_2[1] = L11_2
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
  A1_2._actionTimer = L6_2
  L6_2 = Ai
  L6_2 = L6_2.Enable
  L7_2 = A1_2._hijackee
  L8_2 = false
  L6_2(L7_2, L8_2)
  return A1_2
end

Create = L2_1

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.Minigame
  L3_2 = {}
  L4_2 = A0_2._hijackerPlayer
  L5_2 = "BUTTON_PAD2_UP"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L4_2 = ButtonPressed
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  A0_2._eventButton = L1_2
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 1
  L3_2[1] = L4_2
  L4_2 = ButtonTimeout
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  A0_2._buttonTimer = L1_2
  L1_2 = MrxGuiHudActionHijack
  L1_2 = L1_2.SetDisplayVisible
  L2_2 = A0_2._hijackerPlayer
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = MrxGuiHudActionHijack
  L1_2 = L1_2.SetDisplayButton
  L2_2 = A0_2._hijackerPlayer
  L3_2 = MrxGui
  L3_2 = L3_2.Joystick
  L3_2 = L3_2.BUTTON_PAD2_U
  L1_2(L2_2, L3_2)
  L1_2 = MrxGuiHudActionHijack
  L1_2 = L1_2.SetDisplayMashAnimation
  L2_2 = A0_2._hijackerPlayer
  L3_2 = false
  L1_2(L2_2, L3_2)
end

ButtonStart = L2_1

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = A0_2._buttonPressed
  if L1_2 == false then
    L1_2 = MrxGuiHudActionHijack
    L1_2 = L1_2.SetDisplayVisible
    L2_2 = A0_2._hijackerPlayer
    L3_2 = false
    L1_2(L2_2, L3_2)
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2._eventButton
    L1_2(L2_2)
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2._actionTimer
    L1_2(L2_2)
    L1_2 = Human
    L1_2 = L1_2.SetState
    L2_2 = A0_2._hijacker
    L3_2 = "InVehicle"
    L4_2 = "ActionHijackHijackerFailA"
    L1_2(L2_2, L3_2, L4_2)
    L1_2 = Human
    L1_2 = L1_2.SetState
    L2_2 = A0_2._hijackee
    L3_2 = "InVehicle"
    L4_2 = "ActionHijackHijackeeFailA"
    L1_2(L2_2, L3_2, L4_2)
    L1_2 = Event
    L1_2 = L1_2.Create
    L2_2 = Event
    L2_2 = L2_2.TimerRelative
    L3_2 = {}
    L4_2 = 0.01
    L3_2[1] = L4_2
    L4_2 = Vehicle
    L4_2 = L4_2.OpenDoor
    L5_2 = {}
    L6_2 = A0_2._vehicle
    L7_2 = "front_left"
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L1_2(L2_2, L3_2, L4_2, L5_2)
    L1_2 = Event
    L1_2 = L1_2.Create
    L2_2 = Event
    L2_2 = L2_2.TimerRelative
    L3_2 = {}
    L4_2 = 2
    L3_2[1] = L4_2
    L4_2 = Vehicle
    L4_2 = L4_2.CloseDoor
    L5_2 = {}
    L6_2 = A0_2._vehicle
    L7_2 = "front_left"
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L1_2(L2_2, L3_2, L4_2, L5_2)
    L1_2 = Event
    L1_2 = L1_2.Create
    L2_2 = Event
    L2_2 = L2_2.HumanActionComplete
    L3_2 = {}
    L4_2 = A0_2._hijacker
    L3_2[1] = L4_2
    L4_2 = RagdollFailure
    L5_2 = {}
    L6_2 = A0_2
    L5_2[1] = L6_2
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
    A0_2._actionTimer = L1_2
  end
end

ButtonTimeout = L2_1

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Human
  L1_2 = L1_2.SetState
  L2_2 = A0_2._hijacker
  L3_2 = "Upright"
  L4_2 = "MeleeKnockedDown"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Vehicle
  L1_2 = L1_2.HijackAbort
  L2_2 = A0_2._hijacker
  L1_2(L2_2)
  L1_2 = Ai
  L1_2 = L1_2.Enable
  L2_2 = A0_2._hijackee
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 2
  L3_2[1] = L4_2
  L4_2 = Getup
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  A0_2._eventTimer = L1_2
end

RagdollFailure = L2_1

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  if A1_2 == 1 then
    A0_2._buttonPressed = true
    L2_2 = MrxGuiHudActionHijack
    L2_2 = L2_2.SetDisplayVisible
    L3_2 = A0_2._hijackerPlayer
    L4_2 = false
    L2_2(L3_2, L4_2)
  else
    L2_2 = Event
    L2_2 = L2_2.Create
    L3_2 = Event
    L3_2 = L3_2.Minigame
    L4_2 = {}
    L5_2 = A0_2._hijackerPlayer
    L6_2 = "BUTTON_PAD2_UP"
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L5_2 = ButtonPressed
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
    A0_2._eventButton = L2_2
  end
end

ButtonPressed = L2_1

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Human
  L1_2 = L1_2.SetState
  L2_2 = A0_2._hijacker
  L3_2 = "Upright"
  L4_2 = "Idle"
  L1_2(L2_2, L3_2, L4_2)
end

Getup = L2_1

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = L0_1
  if L1_2 then
    L1_2 = L1_1
    A0_2._numPresses = L1_2
  else
    A0_2._numPresses = 0
  end
  L1_2 = Human
  L1_2 = L1_2.SetState
  L2_2 = A0_2._hijacker
  L3_2 = "InVehicle"
  L4_2 = "ActionHijackHijackerB"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Human
  L1_2 = L1_2.SetState
  L2_2 = A0_2._hijackee
  L3_2 = "InVehicle"
  L4_2 = "ActionHijackHijackeeB"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 0.01
  L3_2[1] = L4_2
  L4_2 = Vehicle
  L4_2 = L4_2.OpenDoor
  L5_2 = {}
  L6_2 = A0_2._vehicle
  L7_2 = "front_left"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.HumanActionComplete
  L3_2 = {}
  L4_2 = A0_2._hijacker
  L3_2[1] = L4_2
  L4_2 = StruggleLoop
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  A0_2._actionTimer = L1_2
end

PullOutPilot = L2_1

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Human
  L1_2 = L1_2.SetState
  L2_2 = A0_2._hijacker
  L3_2 = "InVehicle"
  L4_2 = "ActionHijackHijackerBLoop"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Human
  L1_2 = L1_2.SetState
  L2_2 = A0_2._hijackee
  L3_2 = "InVehicle"
  L4_2 = "ActionHijackHijackeeBLoop"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = MrxGuiHudActionHijack
  L1_2 = L1_2.SetDisplayVisible
  L2_2 = A0_2._hijackerPlayer
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = MrxGuiHudActionHijack
  L1_2 = L1_2.SetDisplayButton
  L2_2 = A0_2._hijackerPlayer
  L3_2 = MrxGui
  L3_2 = L3_2.Joystick
  L3_2 = L3_2.BUTTON_PAD2_R
  L1_2(L2_2, L3_2)
  L1_2 = MrxGuiHudActionHijack
  L1_2 = L1_2.SetDisplayMashAnimation
  L2_2 = A0_2._hijackerPlayer
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = Event
  L1_2 = L1_2.CreatePersistent
  L2_2 = Event
  L2_2 = L2_2.Minigame
  L3_2 = {}
  L4_2 = A0_2._hijackerPlayer
  L5_2 = "BUTTON_PAD2_RIGHT"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L4_2 = CountPresses
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  A0_2._eventButton = L1_2
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 3
  L3_2[1] = L4_2
  L4_2 = TugOfWarTimeout
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  A0_2._eventTimer = L1_2
end

StruggleLoop = L2_1

function L2_1(A0_2, A1_2)
  local L2_2
  if A1_2 == 1 then
    L2_2 = A0_2._numPresses
    L2_2 = L2_2 + 1
    A0_2._numPresses = L2_2
  end
end

CountPresses = L2_1

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxGuiHudActionHijack
  L1_2 = L1_2.SetDisplayVisible
  L2_2 = A0_2._hijackerPlayer
  L3_2 = false
  L1_2(L2_2, L3_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2._eventButton
  L1_2(L2_2)
  L1_2 = A0_2._numPresses
  L2_2 = L1_1
  if L1_2 >= L2_2 then
    L2_2 = A0_2
    L1_2 = A0_2.ClimbInToCockpit
    L1_2(L2_2)
  else
    L1_2 = Human
    L1_2 = L1_2.SetState
    L2_2 = A0_2._hijacker
    L3_2 = "InVehicle"
    L4_2 = "ActionHijackHijackerFailB"
    L1_2(L2_2, L3_2, L4_2)
    L1_2 = Human
    L1_2 = L1_2.SetState
    L2_2 = A0_2._hijackee
    L3_2 = "InVehicle"
    L4_2 = "ActionHijackHijackeeFailB"
    L1_2(L2_2, L3_2, L4_2)
    L1_2 = Event
    L1_2 = L1_2.Create
    L2_2 = Event
    L2_2 = L2_2.TimerRelative
    L3_2 = {}
    L4_2 = 1.23
    L3_2[1] = L4_2
    L4_2 = Vehicle
    L4_2 = L4_2.CloseDoor
    L5_2 = {}
    L6_2 = A0_2._vehicle
    L7_2 = "front_left"
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L1_2(L2_2, L3_2, L4_2, L5_2)
    L1_2 = Event
    L1_2 = L1_2.Create
    L2_2 = Event
    L2_2 = L2_2.HumanActionComplete
    L3_2 = {}
    L4_2 = A0_2._hijacker
    L3_2[1] = L4_2
    L4_2 = RagdollFailure
    L5_2 = {}
    L6_2 = A0_2
    L5_2[1] = L6_2
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
    A0_2._actionTimer = L1_2
  end
end

TugOfWarTimeout = L2_1

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Human
  L1_2 = L1_2.SetState
  L2_2 = A0_2._hijacker
  L3_2 = "InVehicle"
  L4_2 = "ActionHijackHijackerC"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Human
  L1_2 = L1_2.SetState
  L2_2 = A0_2._hijackee
  L3_2 = "InVehicle"
  L4_2 = "ActionHijackHijackeeC"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 2.13
  L3_2[1] = L4_2
  L4_2 = Vehicle
  L4_2 = L4_2.OpenDoor
  L5_2 = {}
  L6_2 = A0_2._vehicle
  L7_2 = "front_left"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.HumanActionComplete
  L3_2 = {}
  L4_2 = A0_2._hijacker
  L3_2[1] = L4_2
  L4_2 = Complete
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  A0_2._actionTimer = L1_2
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.HumanActionComplete
  L3_2 = {}
  L4_2 = A0_2._hijackee
  L3_2[1] = L4_2
  
  function L4_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = Vehicle
    L1_3 = L1_3.Exit
    L2_3 = A0_3._vehicle
    L3_3 = A0_3._hijackee
    L1_3(L2_3, L3_3)
  end
  
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  A0_2._hijackeeActionTimer = L1_2
end

ClimbInToCockpit = L2_1

function L2_1(A0_2)
  local L1_2, L2_2
  L1_2 = Vehicle
  L1_2 = L1_2.HijackComplete
  L2_2 = A0_2._hijacker
  L1_2(L2_2)
end

Complete = L2_1
