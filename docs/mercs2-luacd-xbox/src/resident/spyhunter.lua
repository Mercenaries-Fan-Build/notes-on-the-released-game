local L0_1, L1_1
tEvents = L0_1
L0_1 = false
gbEnableBoostMeter = L0_1
L0_1 = 0
NETEVENT_STARTEMITTERS = L0_1
L0_1 = 1
NETEVENT_STOPEMITTERS = L0_1
L0_1 = 2
NETEVENT_STARTEMITTERSMOKE = L0_1
L0_1 = 3
NETEVENT_STOPEMITTERSMOKE = L0_1

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
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = tEvents
  L3_2 = {}
  L2_2[A0_2] = L3_2
  L2_2 = tEvents
  L2_2 = L2_2[A0_2]
  L2_2.bReady = 1
  L3_2 = OnExit
  L4_2 = 0
  L5_2 = A0_2
  L3_2(L4_2, L5_2)
end

OnActivate = L0_1

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
  L2_2 = tEvents
  L2_2 = L2_2[A1_2]
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectInSeat
  L5_2 = {}
  L6_2 = A0_2
  L7_2 = A1_2
  L8_2 = "d"
  L9_2 = "a"
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
  L3_2 = CoolCheck
  L4_2 = A1_2
  L3_2(L4_2)
  L3_2 = gbEnableBoostMeter
  if L3_2 then
    L3_2 = DisplayBoost
    L4_2 = A1_2
    L3_2(L4_2)
  end
end

OnEnter = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  L2_2 = L1_2.bReady
  if L2_2 == 1 then
    L2_2 = ResetJump
    L3_2 = A0_2
    L2_2(L3_2)
  else
    L2_2 = Event
    L2_2 = L2_2.Create
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = 0.5
    L4_2[1] = L5_2
    L5_2 = CoolCheck
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
    L1_2.eCoolCheck = L2_2
  end
end

CoolCheck = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = tEvents
  L2_2 = L2_2[A1_2]
  L3_2 = type
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if L3_2 == "table" then
    L3_2 = Event
    L3_2 = L3_2.Delete
    L4_2 = L2_2.eJump
    L3_2(L4_2)
    L2_2.eJump = nil
  end
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectInSeat
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAnyCharacter
  L6_2 = L6_2()
  L7_2 = A1_2
  L8_2 = "d"
  L9_2 = "ei"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L6_2 = OnEnter
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L2_2.eEnter = L3_2
  L3_2 = String
  L3_2 = L3_2.GetHash
  L4_2 = "global_particle_fire_jetengine_orange_infinite"
  L3_2 = L3_2(L4_2)
  L4_2 = ObjectState
  L4_2 = L4_2.StopEmitter
  L5_2 = A1_2
  L6_2 = String
  L6_2 = L6_2.GetHash
  L7_2 = "hp_fx_jetexhaust"
  L6_2 = L6_2(L7_2)
  L7_2 = L3_2
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = Sound
  L4_2 = L4_2.SetVehicleEngineBoost
  if L4_2 then
    L4_2 = Sound
    L4_2 = L4_2.SetVehicleEngineBoost
    L5_2 = A1_2
    L6_2 = 0
    L4_2(L5_2, L6_2)
  end
end

OnExit = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = NETEVENT_STARTEMITTERS
  if A0_2 == L2_2 then
    L2_2 = NetSafeSetupBoost
    L3_2 = A1_2[1]
    L2_2(L3_2)
  else
    L2_2 = NETEVENT_STOPEMITTERS
    if A0_2 == L2_2 then
      L2_2 = NetSafeStopBoost
      L3_2 = A1_2[1]
      L2_2(L3_2)
    else
      L2_2 = NETEVENT_STARTEMITTERSMOKE
      if A0_2 == L2_2 then
        L2_2 = NetSafeSmokeStart
        L3_2 = A1_2[1]
        L2_2(L3_2)
      else
        L2_2 = NETEVENT_STOPEMITTERSMOKE
        if A0_2 == L2_2 then
          L2_2 = NetSafeSmokeStop
          L3_2 = A1_2[1]
          L2_2(L3_2)
        end
      end
    end
  end
end

NetEventCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Vehicle
  L1_2 = L1_2.GetDriver
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = Player
  L2_2 = L2_2.GetLocalCharacter
  L2_2 = L2_2()
  if L1_2 == L2_2 then
    L2_2 = Object
    L2_2 = L2_2.IsPlayerControlled
    L3_2 = L1_2
    return L2_2(L3_2)
  end
  L2_2 = nil
  return L2_2
end

GetDriverGuid = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = "green"
  L2_2 = nBoost
  if L2_2 <= 99 then
    L1_2 = "yellow"
  end
  L2_2 = nBoost
  if L2_2 <= 30 then
    L1_2 = "red"
  end
  L2_2 = [[

[GurCon003.Objectives.Boost]:[]]
  L3_2 = L1_2
  L4_2 = "][bar"
  L5_2 = nBoost
  L6_2 = "]"
  L2_2 = L2_2 .. L3_2 .. L4_2 .. L5_2 .. L6_2
  sHudText = L2_2
  L2_2 = GetDriverGuid
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  uPlayer = L2_2
  L2_2 = Hud
  L2_2 = L2_2.ObjectiveTray
  L3_2 = L2_2
  L2_2 = L2_2.SetSlotToText
  L4_2 = {}
  L5_2 = uPlayer
  L4_2.vPlayer = L5_2
  L4_2.nSlot = 1
  L5_2 = sHudText
  L4_2.sText = L5_2
  L2_2(L3_2, L4_2)
end

DisplayBoost = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  L2_2 = L1_2.eJump
  if not L2_2 then
    L2_2 = String
    L2_2 = L2_2.GetHash
    L3_2 = "global_particle_fire_jetengine_orange_infinite"
    L2_2 = L2_2(L3_2)
    L3_2 = ObjectState
    L3_2 = L3_2.StartEmitter
    L4_2 = A0_2
    L5_2 = String
    L5_2 = L5_2.GetHash
    L6_2 = "hp_fx_jetexhaust"
    L5_2 = L5_2(L6_2)
    L6_2 = L2_2
    L3_2(L4_2, L5_2, L6_2)
    L3_2 = GetDriverGuid
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
    uPlayer = L3_2
    L3_2 = uPlayer
    if L3_2 == nil then
      L3_2 = OnExit
      L4_2 = 0
      L5_2 = A0_2
      L3_2(L4_2, L5_2)
    else
      L3_2 = Event
      L3_2 = L3_2.Create
      L4_2 = Event
      L4_2 = L4_2.Button
      L5_2 = {}
      L6_2 = uPlayer
      L7_2 = "lbutton"
      L8_2 = "press"
      L9_2 = true
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      L5_2[3] = L8_2
      L5_2[4] = L9_2
      L6_2 = SetupBoost
      L7_2 = {}
      L8_2 = A0_2
      L7_2[1] = L8_2
      L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
      L1_2.eJump = L3_2
    end
  end
end

ResetJump = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = String
  L1_2 = L1_2.GetHash
  L2_2 = "global_particle_fire_jetengine_infinite"
  L1_2 = L1_2(L2_2)
  L2_2 = ObjectState
  L2_2 = L2_2.StopEmitter
  L3_2 = A0_2
  L4_2 = String
  L4_2 = L4_2.GetHash
  L5_2 = "hp_fx_jetexhaust"
  L4_2 = L4_2(L5_2)
  L5_2 = L1_2
  L2_2(L3_2, L4_2, L5_2)
end

NetSafeSmokeStop = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = 0
  nJump = L1_2
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  L1_2.bReady = 0
  L1_2.eJump = nil
  L2_2 = OnJump
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = String
  L2_2 = L2_2.GetHash
  L3_2 = "global_particle_fire_jetengine_orange_infinite"
  L2_2 = L2_2(L3_2)
  L3_2 = ObjectState
  L3_2 = L3_2.StopEmitter
  L4_2 = A0_2
  L5_2 = String
  L5_2 = L5_2.GetHash
  L6_2 = "hp_fx_jetexhaust"
  L5_2 = L5_2(L6_2)
  L6_2 = L2_2
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = String
  L3_2 = L3_2.GetHash
  L4_2 = "global_particle_fire_jetengine_boost_infinite"
  L3_2 = L3_2(L4_2)
  L4_2 = ObjectState
  L4_2 = L4_2.StartEmitter
  L5_2 = A0_2
  L6_2 = String
  L6_2 = L6_2.GetHash
  L7_2 = "hp_fx_jetexhaust"
  L6_2 = L6_2(L7_2)
  L7_2 = L3_2
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = Sound
  L4_2 = L4_2.SetVehicleEngineBoost
  if L4_2 then
    L4_2 = Sound
    L4_2 = L4_2.SetVehicleEngineBoost
    L5_2 = A0_2
    L6_2 = 1
    L4_2(L5_2, L6_2)
  end
  L4_2 = Net
  L4_2 = L4_2.IsActive
  L4_2 = L4_2()
  if L4_2 then
    L4_2 = Net
    L4_2 = L4_2.SendCustomEvent
    L5_2 = "spyhunter"
    L6_2 = NETEVENT_STARTEMITTERS
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L4_2(L5_2, L6_2, L7_2)
  end
end

SetupBoost = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = String
  L1_2 = L1_2.GetHash
  L2_2 = "global_particle_fire_jetengine_orange_infinite"
  L1_2 = L1_2(L2_2)
  L2_2 = ObjectState
  L2_2 = L2_2.StopEmitter
  L3_2 = A0_2
  L4_2 = String
  L4_2 = L4_2.GetHash
  L5_2 = "hp_fx_jetexhaust"
  L4_2 = L4_2(L5_2)
  L5_2 = L1_2
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = String
  L2_2 = L2_2.GetHash
  L3_2 = "global_particle_fire_jetengine_boost_infinite"
  L2_2 = L2_2(L3_2)
  L3_2 = ObjectState
  L3_2 = L3_2.StartEmitter
  L4_2 = A0_2
  L5_2 = String
  L5_2 = L5_2.GetHash
  L6_2 = "hp_fx_jetexhaust"
  L5_2 = L5_2(L6_2)
  L6_2 = L2_2
  L3_2(L4_2, L5_2, L6_2)
end

NetSafeSetupBoost = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = nJump
  if L1_2 <= 5 then
    L1_2 = Object
    L1_2 = L1_2.GetMass
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    L2_2 = nJump
    if L2_2 == 0 then
      L2_2 = Object
      L2_2 = L2_2.ApplyPointImpulse
      L3_2 = A0_2
      L4_2 = 0
      L5_2 = 0
      L6_2 = 50000
      L7_2 = 0
      L8_2 = -0.5
      L9_2 = -1.5
      L10_2 = true
      L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
    else
      L2_2 = nJump
      if L2_2 == 1 then
        L2_2 = Object
        L2_2 = L2_2.ApplyImpulse
        L3_2 = A0_2
        L4_2 = 0
        L5_2 = 10000
        L6_2 = 6 * L1_2
        L7_2 = true
        L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
      else
        L2_2 = nJump
        if L2_2 == 2 then
          L2_2 = Object
          L2_2 = L2_2.ApplyImpulse
          L3_2 = A0_2
          L4_2 = 0
          L5_2 = 20000
          L6_2 = 8 * L1_2
          L7_2 = true
          L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
        else
          L2_2 = nJump
          if L2_2 == 3 then
            L2_2 = Object
            L2_2 = L2_2.ApplyImpulse
            L3_2 = A0_2
            L4_2 = 0
            L5_2 = -0.5 * L1_2
            L6_2 = 10 * L1_2
            L7_2 = true
            L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
          else
            L2_2 = nJump
            if L2_2 == 4 then
              L2_2 = Object
              L2_2 = L2_2.ApplyImpulse
              L3_2 = A0_2
              L4_2 = 0
              L5_2 = -0.5 * L1_2
              L6_2 = 6 * L1_2
              L7_2 = true
              L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
            else
              L2_2 = nJump
              if L2_2 == 5 then
                L2_2 = Object
                L2_2 = L2_2.ApplyImpulse
                L3_2 = A0_2
                L4_2 = 0
                L5_2 = -0.5 * L1_2
                L6_2 = 4 * L1_2
                L7_2 = true
                L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
              end
            end
          end
        end
      end
    end
    L2_2 = tEvents
    L2_2 = L2_2[A0_2]
    L3_2 = Event
    L3_2 = L3_2.Create
    L4_2 = Event
    L4_2 = L4_2.TimerRelative
    L5_2 = {}
    L6_2 = 0.8
    L5_2[1] = L6_2
    L6_2 = OnJump
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
    L2_2.eJumping = L3_2
    L3_2 = nJump
    L3_2 = L3_2 + 1
    nJump = L3_2
  else
    L1_2 = StopBoost
    L2_2 = A0_2
    L1_2(L2_2)
  end
end

OnJump = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = String
  L1_2 = L1_2.GetHash
  L2_2 = "global_particle_fire_jetengine_boost_infinite"
  L1_2 = L1_2(L2_2)
  L2_2 = ObjectState
  L2_2 = L2_2.StopEmitter
  L3_2 = A0_2
  L4_2 = String
  L4_2 = L4_2.GetHash
  L5_2 = "hp_fx_jetexhaust"
  L4_2 = L4_2(L5_2)
  L5_2 = L1_2
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = Sound
  L2_2 = L2_2.SetVehicleEngineBoost
  if L2_2 then
    L2_2 = Sound
    L2_2 = L2_2.SetVehicleEngineBoost
    L3_2 = A0_2
    L4_2 = 0
    L2_2(L3_2, L4_2)
  end
  L2_2 = Net
  L2_2 = L2_2.IsActive
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = Net
    L2_2 = L2_2.SendCustomEvent
    L3_2 = "spyhunter"
    L4_2 = NETEVENT_STOPEMITTERS
    L5_2 = {}
    L6_2 = A0_2
    L5_2[1] = L6_2
    L2_2(L3_2, L4_2, L5_2)
  end
  L2_2 = CoolDown
  L3_2 = A0_2
  L2_2(L3_2)
end

StopBoost = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = String
  L1_2 = L1_2.GetHash
  L2_2 = "global_particle_fire_jetengine_boost_infinite"
  L1_2 = L1_2(L2_2)
  L2_2 = ObjectState
  L2_2 = L2_2.StopEmitter
  L3_2 = A0_2
  L4_2 = String
  L4_2 = L4_2.GetHash
  L5_2 = "hp_fx_jetexhaust"
  L4_2 = L4_2(L5_2)
  L5_2 = L1_2
  L2_2(L3_2, L4_2, L5_2)
end

NetSafeStopBoost = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = String
  L1_2 = L1_2.GetHash
  L2_2 = "global_particle_fire_jetengine_infinite"
  L1_2 = L1_2(L2_2)
  L2_2 = ObjectState
  L2_2 = L2_2.StartEmitter
  L3_2 = A0_2
  L4_2 = String
  L4_2 = L4_2.GetHash
  L5_2 = "hp_fx_jetexhaust"
  L4_2 = L4_2(L5_2)
  L5_2 = L1_2
  L2_2(L3_2, L4_2, L5_2)
end

NetSafeSmokeStart = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = String
  L1_2 = L1_2.GetHash
  L2_2 = "global_particle_fire_jetengine_infinite"
  L1_2 = L1_2(L2_2)
  L2_2 = ObjectState
  L2_2 = L2_2.StopEmitter
  L3_2 = A0_2
  L4_2 = String
  L4_2 = L4_2.GetHash
  L5_2 = "hp_fx_jetexhaust"
  L4_2 = L4_2(L5_2)
  L5_2 = L1_2
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = Net
  L2_2 = L2_2.IsActive
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = Net
    L2_2 = L2_2.SendCustomEvent
    L3_2 = "spyhunter"
    L4_2 = NETEVENT_STOPEMITTERSMOKE
    L5_2 = {}
    L6_2 = A0_2
    L5_2[1] = L6_2
    L2_2(L3_2, L4_2, L5_2)
  end
end

DontSmoke = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  L1_2.bReady = 1
  L2_2 = GetDriverGuid
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = ResetJump
    L3_2 = A0_2
    L2_2(L3_2)
  end
end

IsCool = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 5.5
  L4_2[1] = L5_2
  L5_2 = DontSmoke
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.eSmokeStop = L2_2
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 8
  L4_2[1] = L5_2
  L5_2 = IsCool
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.eReset = L2_2
  L2_2 = String
  L2_2 = L2_2.GetHash
  L3_2 = "global_particle_fire_jetengine_infinite"
  L2_2 = L2_2(L3_2)
  L3_2 = ObjectState
  L3_2 = L3_2.StartEmitter
  L4_2 = A0_2
  L5_2 = String
  L5_2 = L5_2.GetHash
  L6_2 = "hp_fx_jetexhaust"
  L5_2 = L5_2(L6_2)
  L6_2 = L2_2
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = Net
  L3_2 = L3_2.IsActive
  L3_2 = L3_2()
  if L3_2 then
    L3_2 = Net
    L3_2 = L3_2.SendCustomEvent
    L4_2 = "spyhunter"
    L5_2 = NETEVENT_STARTEMITTERSMOKE
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L3_2(L4_2, L5_2, L6_2)
  end
  L3_2 = gbEnableBoostMeter
  if L3_2 then
    L3_2 = DisplayBoost
    L4_2 = A0_2
    L3_2(L4_2)
  end
end

CoolDown = L0_1
