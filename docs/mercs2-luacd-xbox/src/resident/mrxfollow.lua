local L0_1, L1_1
L0_1 = import
L1_1 = "MrxVoSequence"
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
  A1_2.iStartVOIdx = 1
  A1_2.iStopVOIdx = 1
  A1_2.iLostVOIdx = 1
  A1_2.iFoundVOIdx = 1
  A1_2.iHostileVOIdx = 1
  A1_2.iHostileRecoveredVOIdx = 1
  return A1_2
end

Create = L0_1

function L0_1(A0_2, A1_2)
  A0_2._vActor = A1_2
end

SetActor = L0_1

function L0_1(A0_2, A1_2)
  A0_2._vObjectToFollow = A1_2
end

SetObjectToFollow = L0_1

function L0_1(A0_2, A1_2, A2_2)
  A0_2._fCallback = A1_2
  A0_2._tCallbackData = A2_2
end

SetCallback = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  if A1_2 then
    L3_2 = A0_2._vActor
    if L3_2 then
      L3_2 = A0_2._vObjectToFollow
      if not L3_2 then
        L3_2 = Player
        L3_2 = L3_2.GetLocalCharacter
        L3_2 = L3_2()
      end
      A0_2._vObjectToFollow = L3_2
      A0_2.bVOOverride = true
      L4_2 = A0_2
      L3_2 = A0_2._Follow
      L5_2 = A2_2
      L6_2 = A0_2._vObjectToFollow
      L3_2(L4_2, L5_2, L6_2)
    end
  else
    A0_2.bVOOverride = true
    L4_2 = A0_2
    L3_2 = A0_2._ToggleFollowingBehavior
    L5_2 = false
    L3_2(L4_2, L5_2)
    L4_2 = A0_2
    L3_2 = A0_2._RemoveContextAction
    L3_2(L4_2)
    L3_2 = pairs
    L4_2 = A0_2._tEvents
    L3_2, L4_2, L5_2 = L3_2(L4_2)
    for L6_2, L7_2 in L3_2, L4_2, L5_2 do
      L8_2 = Event
      L8_2 = L8_2.Delete
      L9_2 = L7_2
      L8_2(L9_2)
      L8_2 = A0_2._tEvents
      L8_2[L6_2] = nil
    end
  end
end

Activate = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L4_2 = A0_2
  L3_2 = A0_2._ToggleFollowingBehavior
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
  L4_2 = A0_2
  L3_2 = A0_2._ToggleContextAction
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
end

_Follow = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L3_2 = 30
  L4_2 = A0_2._vActor
  L5_2 = A0_2._GetActorGuid
  L6_2 = L4_2
  L5_2 = L5_2(L6_2)
  L6_2 = A0_2._GetActorGuid
  L7_2 = A2_2
  L6_2 = L6_2(L7_2)
  if A1_2 then
    L7_2 = Ai
    L7_2 = L7_2.LivingWorld
    L8_2 = {}
    L8_2.AIGuid = L5_2
    L8_2.Attrib = "LivingWorldBehaviour"
    L8_2.State = false
    L7_2(L8_2)
    L7_2 = Ai
    L7_2 = L7_2.GetFeeling
    L8_2 = L5_2
    L9_2 = L6_2
    L7_2 = L7_2(L8_2, L9_2)
    if L7_2 and L7_2 < 0 then
      L8_2 = Ai
      L8_2 = L8_2.SetFeeling
      L9_2 = L5_2
      L10_2 = L6_2
      L11_2 = 100
      L8_2(L9_2, L10_2, L11_2)
    end
    L8_2 = Ai
    L8_2 = L8_2.Role
    L9_2 = {}
    L9_2.AIGuid = L5_2
    L9_2.Role = "Follow"
    L9_2.Target = L6_2
    L9_2.MinDistance = 2
    L9_2.MaxDistance = L3_2
    L9_2.MoveDistance = 4
    L9_2.Priority = "hiPri"
    L9_2.HardPriority = true
    L10_2 = _OnFollowerCanceled
    L9_2.Callback = L10_2
    L10_2 = {}
    L11_2 = A0_2
    L10_2[1] = L11_2
    L9_2.CallbackData = L10_2
    L8_2 = L8_2(L9_2)
    A0_2._vObjectToFollow = L6_2
    L9_2 = Event
    L9_2 = L9_2.Delete
    L10_2 = A0_2._tEvents
    L10_2 = L10_2.eCloseEnough
    L9_2(L10_2)
    L9_2 = A0_2._tEvents
    L9_2.eCloseEnough = nil
    L9_2 = A0_2._tEvents
    L10_2 = Event
    L10_2 = L10_2.Create
    L11_2 = Event
    L11_2 = L11_2.ScriptEvent
    L12_2 = {}
    L13_2 = "mpPlayerLeft"
    
    function L14_2(A0_3)
      local L1_3, L2_3
      L1_3 = A0_2
      L1_3 = L1_3._vObjectToFollow
      L2_3 = A0_3[2]
      L1_3 = L1_3 == L2_3
      return L1_3
    end
    
    L12_2[1] = L13_2
    L12_2[2] = L14_2
    L13_2 = _Follow
    L14_2 = {}
    L15_2 = A0_2
    L16_2 = false
    L17_2 = nil
    L14_2[1] = L15_2
    L14_2[2] = L16_2
    L14_2[3] = L17_2
    L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2)
    L9_2.ePlayer = L10_2
    L9_2 = A0_2._tEvents
    L10_2 = Event
    L10_2 = L10_2.Create
    L11_2 = Event
    L11_2 = L11_2.ScriptEvent
    L12_2 = {}
    L13_2 = "transitStart"
    L14_2 = _TransitEvalFn
    L12_2[1] = L13_2
    L12_2[2] = L14_2
    L13_2 = _OnTransitStart
    L14_2 = {}
    L15_2 = A0_2
    L14_2[1] = L15_2
    L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2)
    L9_2.eTransit = L10_2
    L9_2 = A0_2.bVOOverride
    if not L9_2 then
      L10_2 = A0_2
      L9_2 = A0_2._PlayVO
      L11_2 = A0_2.tStartFollowVO
      L12_2 = A0_2.iStartVOIdx
      L9_2 = L9_2(L10_2, L11_2, L12_2)
      A0_2.iStartVOIdx = L9_2
    end
  else
    L7_2 = A0_2._tEvents
    L7_2 = L7_2.ePlayer
    if L7_2 then
      L7_2 = Event
      L7_2 = L7_2.Delete
      L8_2 = A0_2._tEvents
      L8_2 = L8_2.ePlayer
      L7_2(L8_2)
      L7_2 = A0_2._tEvents
      L7_2.ePlayer = nil
    end
    L7_2 = A0_2._tEvents
    L7_2 = L7_2.eTransit
    if L7_2 then
      L7_2 = Event
      L7_2 = L7_2.Delete
      L8_2 = A0_2._tEvents
      L8_2 = L8_2.eTransit
      L7_2(L8_2)
      L7_2 = A0_2._tEvents
      L7_2.eTransit = nil
    end
    L7_2 = Ai
    L7_2 = L7_2.Role
    L8_2 = {}
    L8_2.AIGuid = L5_2
    L8_2.Role = "Idle"
    L8_2.Priority = "hiPri"
    L8_2.Callback = nil
    L8_2.CallbackData = nil
    L7_2 = L7_2(L8_2)
    A0_2._aiRole = L7_2
    L7_2 = A0_2.bVOOverride
    if not L7_2 then
      L8_2 = A0_2
      L7_2 = A0_2._PlayVO
      L9_2 = A0_2.tStopFollowVO
      L10_2 = A0_2.iStopVOIdx
      L7_2 = L7_2(L8_2, L9_2, L10_2)
      A0_2.iStopVOIdx = L7_2
    end
  end
  A0_2.bVOOverride = nil
  L7_2 = A0_2._fCallback
  if L7_2 then
    L7_2 = type
    L8_2 = A0_2._tCallbackData
    L7_2 = L7_2(L8_2)
    if L7_2 == "table" then
      L7_2 = {}
      L8_2 = unpack
      L9_2 = A0_2._tCallbackData
      L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2 = L8_2(L9_2)
      L7_2[1] = L8_2
      L7_2[2] = L9_2
      L7_2[3] = L10_2
      L7_2[4] = L11_2
      L7_2[5] = L12_2
      L7_2[6] = L13_2
      L7_2[7] = L14_2
      L7_2[8] = L15_2
      L7_2[9] = L16_2
      L7_2[10] = L17_2
      L8_2 = table
      L8_2 = L8_2.insert
      L9_2 = L7_2
      L10_2 = L5_2
      L8_2(L9_2, L10_2)
      L8_2 = table
      L8_2 = L8_2.insert
      L9_2 = L7_2
      L10_2 = A1_2
      L8_2(L9_2, L10_2)
      L8_2 = A0_2._fCallback
      L9_2 = unpack
      L10_2 = L7_2
      L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2 = L9_2(L10_2)
      L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
    else
      L7_2 = A0_2._fCallback
      L8_2 = L5_2
      L9_2 = A1_2
      L7_2(L8_2, L9_2)
    end
  end
end

_ToggleFollowingBehavior = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L2_2 = A0_2._vActor
  L3_2 = A0_2._GetActorGuid
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  L5_2 = A0_2
  L4_2 = A0_2._RemoveContextAction
  L4_2(L5_2)
  L4_2 = "[ContextAction.Follow]"
  L5_2 = 0
  if A1_2 then
    L4_2 = "[ContextAction.Stay]"
    L6_2 = A0_2._GetActorGuid
    L7_2 = A0_2._vObjectToFollow
    L6_2 = L6_2(L7_2)
    L5_2 = L6_2 or L5_2
    if not L6_2 then
      L5_2 = 0
    end
  end
  L6_2 = Pg
  L6_2 = L6_2.AddContextAction
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = 2
  L10_2 = 0
  L11_2 = 200
  L12_2 = 0
  L13_2 = 2
  L14_2 = L5_2
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L7_2 = Event
  L7_2 = L7_2.Delete
  L8_2 = A0_2._tEvents
  L8_2 = L8_2.uActionEvent
  L7_2(L8_2)
  L7_2 = A0_2._tEvents
  L8_2 = Event
  L8_2 = L8_2.Create
  L9_2 = Event
  L9_2 = L9_2.ContextAction
  L10_2 = {}
  L11_2 = L5_2
  L12_2 = L3_2
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L11_2 = A0_2._Follow
  L12_2 = {}
  L13_2 = A0_2
  L14_2 = not A1_2
  L12_2[1] = L13_2
  L12_2[2] = L14_2
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
  L7_2.uActionEvent = L8_2
end

_ToggleContextAction = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = A0_2._vActor
  L2_2 = A0_2._GetActorGuid
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  L3_2 = Pg
  L3_2 = L3_2.RemoveContextAction
  L4_2 = L2_2
  L3_2(L4_2)
end

_RemoveContextAction = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 == "string" then
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
    L1_2 = L3_2
  elseif L2_2 == "userdata" then
    L1_2 = A0_2
  end
  return L1_2
end

_GetActorGuid = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  if A2_2 == "targettoofar" then
    L4_2 = A0_2
    L3_2 = A0_2._OnFollowerLost
    L3_2(L4_2)
  elseif A2_2 == "targethostile" then
    L4_2 = A0_2
    L3_2 = A0_2._OnFollowerHostile
    L3_2(L4_2)
  elseif A2_2 == "targetdead" then
    return
  end
  L4_2 = A0_2
  L3_2 = A0_2._Follow
  L5_2 = false
  L3_2(L4_2, L5_2)
end

_OnFollowerCanceled = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = A0_2
  L1_2 = A0_2._PlayVO
  L3_2 = A0_2.tLostVO
  L4_2 = A0_2.iLostVOIdx
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  A0_2.iLostVOIdx = L1_2
  A0_2.bVOOverride = true
  L1_2 = A0_2._GetActorGuid
  L2_2 = A0_2._vActor
  L1_2 = L1_2(L2_2)
  L2_2 = A0_2._tEvents
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = L1_2
  L7_2 = A0_2._vObjectToFollow
  L8_2 = "<"
  L9_2 = 15
  L10_2 = false
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = _OnFollowerFound
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2.eCloseEnough = L3_2
end

_OnFollowerLost = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2._PlayVO
  L3_2 = A0_2.tFoundVO
  L4_2 = A0_2.iFoundVOIdx
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  A0_2.iFoundVOIdx = L1_2
  A0_2.bVOOverride = true
  L2_2 = A0_2
  L1_2 = A0_2._Follow
  L3_2 = true
  L4_2 = A0_2._vObjectToFollow
  L1_2(L2_2, L3_2, L4_2)
end

_OnFollowerFound = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2._PlayVO
  L3_2 = A0_2.tHostileVO
  L4_2 = A0_2.iHostileVOIdx
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  A0_2.iHostileVOIdx = L1_2
  A0_2.bVOOverride = true
end

_OnFollowerHostile = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = type
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if L3_2 == "table" then
    L3_2 = MrxVoSequence
    L3_2 = L3_2.Start
    L4_2 = {}
    L5_2 = {}
    L6_2 = Human
    L6_2 = L6_2.DoAction
    L7_2 = {}
    L8_2 = A0_2._vActor
    L9_2 = "SpeakGestureUB"
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L6_2 = {}
    L7_2 = A1_2[A2_2]
    L8_2 = A0_2._vActor
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L7_2 = {}
    L8_2 = Human
    L8_2 = L8_2.DoAction
    L9_2 = {}
    L10_2 = A0_2._vActor
    L11_2 = "ExitAction"
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L4_2[3] = L7_2
    L5_2 = false
    L6_2 = MrxVoSequence
    L6_2 = L6_2.knPriorityFreeplay
    L3_2(L4_2, L5_2, L6_2)
    A2_2 = A2_2 + 1
    L3_2 = table
    L3_2 = L3_2.getn
    L4_2 = A1_2
    L3_2 = L3_2(L4_2)
    if A2_2 > L3_2 then
      A2_2 = 1
    end
  end
  return A2_2
end

_PlayVO = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = true
  return L1_2
end

_TransitEvalFn = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = Vehicle
  L2_2 = L2_2.Enter
  L3_2 = A1_2[1]
  L4_2 = A0_2._vActor
  L5_2 = "p"
  L6_2 = true
  L7_2 = false
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = Vehicle
  L3_2 = L3_2.GetFromRider
  L4_2 = A0_2._vActor
  L3_2 = L3_2(L4_2)
  L4_2 = A1_2[1]
  if L3_2 == L4_2 then
    L3_2 = A0_2._tEvents
    L4_2 = Event
    L4_2 = L4_2.Create
    L5_2 = Event
    L5_2 = L5_2.ScriptEvent
    L6_2 = {}
    L7_2 = "transitEnd"
    L8_2 = _TransitEvalFn
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L7_2 = _OnTransitEnd
    L8_2 = {}
    L9_2 = A0_2
    L8_2[1] = L9_2
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
    L3_2.eTransit = L4_2
  else
    L4_2 = A0_2
    L3_2 = A0_2._ToggleFollowingBehavior
    L5_2 = false
    L3_2(L4_2, L5_2)
  end
end

_OnTransitStart = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = Vehicle
  L2_2 = L2_2.Exit
  L3_2 = A1_2[1]
  L4_2 = A0_2._vActor
  L5_2 = false
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  L3_2 = A0_2._tEvents
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.ScriptEvent
  L6_2 = {}
  L7_2 = "transitStart"
  L8_2 = _TransitEvalFn
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = _OnTransitStart
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L3_2.eTransit = L4_2
end

_OnTransitEnd = L0_1
