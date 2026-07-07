local L0_1, L1_1, L2_1
L0_1 = import
L1_1 = "MrxGuiBase"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = nil
tEvents = L0_1
L0_1 = nil
uFilter = L0_1
L0_1 = 0
NETEVENT_STARTEMITTERS = L0_1
L0_1 = 1
NETEVENT_STOPEMITTERS = L0_1
L0_1 = 10
nImpulse = L0_1
L0_1 = 0.15
nPosition = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = NETEVENT_STARTEMITTERS
  if A0_2 == L2_2 then
    L2_2 = StartEmitters
    L3_2 = A1_2[1]
    L2_2(L3_2)
  else
    L2_2 = NETEVENT_STOPEMITTERS
    if A0_2 == L2_2 then
      L2_2 = StopEmitters
      L3_2 = A1_2[1]
      L2_2(L3_2)
    end
  end
end

NetEventCallback = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = {}
  tEvents = L0_2
end

Init = L0_1

function L0_1()
  local L0_2, L1_2
  tEvents = L0_2
end

Deinit = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = OnExit
  L3_2 = 0
  L4_2 = A0_2
  L2_2(L3_2, L4_2)
end

OnActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = OnDeactivate
  L2_2 = A0_2
  L1_2(L2_2)
end

OnDeath = L0_1

function L0_1(A0_2)
  local L1_2
  nImpulse = A0_2
end

SetImpulse = L0_1

function L0_1(A0_2)
  local L1_2
  nPosition = A0_2
end

SetPosition = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = tEvents
  L2_2 = L2_2[A0_2]
  L3_2 = type
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if L3_2 == "table" then
    L3_2 = pairs
    L4_2 = L2_2
    L3_2, L4_2, L5_2 = L3_2(L4_2)
    for L6_2, L7_2 in L3_2, L4_2, L5_2 do
      L8_2 = Event
      L8_2 = L8_2.Delete
      L9_2 = L7_2
      L8_2(L9_2)
    end
  else
    L3_2 = Event
    L3_2 = L3_2.Delete
    L4_2 = L2_2
    L3_2(L4_2)
  end
  L3_2 = tEvents
  L3_2[A0_2] = nil
end

OnDeactivate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = {}
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectInSeat
  L5_2 = {}
  L6_2 = A0_2
  L7_2 = A1_2
  L8_2 = "d"
  L9_2 = "xo"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L6_2 = OnExit
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L2_2.eExit = L3_2
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ScriptEvent
  L5_2 = {}
  L6_2 = "mpPlayerLeft"
  
  function L7_2(A0_3)
    local L1_3, L2_3
    L1_3 = A0_2
    L2_3 = A0_3[2]
    L1_3 = L1_3 == L2_3
    return L1_3
  end
  
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = OnExit
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A1_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2.eMPquit = L3_2
  L3_2 = tEvents
  L3_2[A1_2] = L2_2
  L3_2 = ResetJump
  L4_2 = A1_2
  L3_2(L4_2)
end

OnEnter = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = tEvents
  L2_2 = L2_2[A1_2]
  L3_2 = type
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if L3_2 == "table" then
    L3_2 = pairs
    L4_2 = L2_2
    L3_2, L4_2, L5_2 = L3_2(L4_2)
    for L6_2, L7_2 in L3_2, L4_2, L5_2 do
      L8_2 = Event
      L8_2 = L8_2.Delete
      L9_2 = L7_2
      L8_2(L9_2)
    end
  end
  L3_2 = tEvents
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.ObjectInSeat
  L6_2 = {}
  L7_2 = Player
  L7_2 = L7_2.GetAnyCharacter
  L7_2 = L7_2()
  L8_2 = A1_2
  L9_2 = "d"
  L10_2 = "ei"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L7_2 = OnEnter
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  L3_2[A1_2] = L4_2
  L3_2 = StopEmitters
  L4_2 = A1_2
  L3_2(L4_2)
  L3_2 = Net
  L3_2 = L3_2.IsActive
  L3_2 = L3_2()
  if L3_2 then
    L3_2 = Net
    L3_2 = L3_2.SendCustomEvent
    L4_2 = "moonpatrol"
    L5_2 = NETEVENT_STOPEMITTERS
    L6_2 = {}
    L7_2 = A1_2
    L6_2[1] = L7_2
    L3_2(L4_2, L5_2, L6_2)
  end
end

OnExit = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  if A0_2 then
    L1_2 = String
    L1_2 = L1_2.GetHash
    L2_2 = "global_particle_monstertruck_turbo"
    L1_2 = L1_2(L2_2)
    L2_2 = ObjectState
    L2_2 = L2_2.StartEmitter
    L3_2 = A0_2
    L4_2 = String
    L4_2 = L4_2.GetHash
    L5_2 = "hp_fx_exhaust_a"
    L4_2 = L4_2(L5_2)
    L5_2 = L1_2
    L2_2(L3_2, L4_2, L5_2)
    L2_2 = ObjectState
    L2_2 = L2_2.StartEmitter
    L3_2 = A0_2
    L4_2 = String
    L4_2 = L4_2.GetHash
    L5_2 = "hp_fx_exhaust_b"
    L4_2 = L4_2(L5_2)
    L5_2 = L1_2
    L2_2(L3_2, L4_2, L5_2)
    L2_2 = Sound
    L2_2 = L2_2.CueSound
    L3_2 = A0_2
    L4_2 = "dlcfx_truckBoost"
    L2_2(L3_2, L4_2)
  end
end

StartEmitters = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  if A0_2 then
    L1_2 = String
    L1_2 = L1_2.GetHash
    L2_2 = "global_particle_monstertruck_turbo"
    L1_2 = L1_2(L2_2)
    L2_2 = ObjectState
    L2_2 = L2_2.StopEmitter
    L3_2 = A0_2
    L4_2 = String
    L4_2 = L4_2.GetHash
    L5_2 = "hp_fx_exhaust_a"
    L4_2 = L4_2(L5_2)
    L5_2 = L1_2
    L2_2(L3_2, L4_2, L5_2)
    L2_2 = ObjectState
    L2_2 = L2_2.StopEmitter
    L3_2 = A0_2
    L4_2 = String
    L4_2 = L4_2.GetHash
    L5_2 = "hp_fx_exhaust_b"
    L4_2 = L4_2(L5_2)
    L5_2 = L1_2
    L2_2(L3_2, L4_2, L5_2)
  end
end

StopEmitters = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = MrxGuiBase
  L1_2 = L1_2.GetCurrentControlHolder
  L2_2 = Player
  L2_2 = L2_2.GetLocalPlayer
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L2_2()
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  if L1_2 then
    L1_2 = ResetJump
    L2_2 = A0_2
    L1_2(L2_2)
    return
  end
  L1_2 = Object
  L1_2 = L1_2.GetMass
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = Object
  L2_2 = L2_2.ApplyPointImpulse
  L3_2 = A0_2
  L4_2 = 0
  L5_2 = nImpulse
  L5_2 = L5_2 * L1_2
  L6_2 = 0.1 * L1_2
  L7_2 = 0
  L8_2 = 0
  L9_2 = nPosition
  L10_2 = true
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  L2_2 = StartEmitters
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = Net
  L2_2 = L2_2.IsActive
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = Net
    L2_2 = L2_2.SendCustomEvent
    L3_2 = "moonpatrol"
    L4_2 = NETEVENT_STARTEMITTERS
    L5_2 = {}
    L6_2 = A0_2
    L5_2[1] = L6_2
    L2_2(L3_2, L4_2, L5_2)
  end
  L2_2 = tEvents
  L2_2 = L2_2[A0_2]
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 1.5
  L5_2[1] = L6_2
  L6_2 = WaitForLanding
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2.eGrounded = L3_2
end

OnJump = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = StopEmitters
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Net
  L1_2 = L1_2.IsActive
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = Net
    L1_2 = L1_2.SendCustomEvent
    L2_2 = "moonpatrol"
    L3_2 = NETEVENT_STOPEMITTERS
    L4_2 = {}
    L5_2 = A0_2
    L4_2[1] = L5_2
    L1_2(L2_2, L3_2, L4_2)
  end
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ObjectIsGrounded
  L4_2 = {}
  L5_2 = A0_2
  L6_2 = true
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = ResetJump
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.eGrounded = L2_2
end

WaitForLanding = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Vehicle
  L1_2 = L1_2.GetDriver
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = Player
  L2_2 = L2_2.GetLocalCharacter
  L2_2 = L2_2()
  if L1_2 == L2_2 then
    L2_2 = tEvents
    L2_2 = L2_2[A0_2]
    L2_2.eGrounded = nil
    L3_2 = Event
    L3_2 = L3_2.Create
    L4_2 = Event
    L4_2 = L4_2.Button
    L5_2 = {}
    L6_2 = Object
    L6_2 = L6_2.IsPlayerControlled
    L7_2 = L1_2
    L6_2 = L6_2(L7_2)
    L7_2 = "rbutton"
    L8_2 = "press"
    L9_2 = true
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L5_2[4] = L9_2
    L6_2 = OnJump
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
    L2_2.eJump = L3_2
  end
end

ResetJump = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = Object
  L2_2 = L2_2.CloseGate
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = Event
  L2_2 = L2_2.Delete
  L3_2 = tEvents
  L3_2 = L3_2[A0_2]
  L2_2(L3_2)
  L2_2 = tEvents
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = uFilter
  L7_2 = A0_2
  L8_2 = "<"
  L9_2 = 10
  L10_2 = false
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = Activated
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2[A0_2] = L3_2
end

Deactivated = L0_1
