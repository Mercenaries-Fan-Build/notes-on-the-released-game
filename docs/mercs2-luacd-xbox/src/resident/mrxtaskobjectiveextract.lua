local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskObjective"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFollow"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = MrxTaskObjective
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = L1_2.fDist
  L4_2 = 40
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.fDist = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = L1_2.bStop
  L4_2 = false
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.bStop = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = L1_2.bXZOnly
  L4_2 = false
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.bXZOnly = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = L1_2.bHumansFollow
  L4_2 = true
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.bHumansFollow = L2_2
  L2_2 = ObjectFilter
  L2_2 = L2_2.GetObjects
  L3_2 = A0_2._uTgtObjFilter
  L4_2 = false
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = L2_2[1]
  L4_2 = L1_2.oFollower
  if L4_2 then
    L4_2 = L1_2.oFollower
    A0_2.oFollower = L4_2
  else
    L4_2 = L1_2.bHumansFollow
    if L4_2 then
      L4_2 = {}
      L4_2._vActor = L3_2
      L5_2 = L1_2.uStartAttachedToPlayer
      L4_2._vObjectToFollow = L5_2
      L5_2 = _OnAttachment
      L4_2._fCallback = L5_2
      L5_2 = {}
      L6_2 = A0_2
      L7_2 = "follow"
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      L4_2._tCallbackData = L5_2
      L5_2 = L1_2.tStartFollowVO
      L4_2.tStartFollowVO = L5_2
      L5_2 = L1_2.tStopFollowVO
      L4_2.tStopFollowVO = L5_2
      L5_2 = L1_2.tLostVO
      L4_2.tLostVO = L5_2
      L5_2 = L1_2.tFoundVO
      L4_2.tFoundVO = L5_2
      L5_2 = MrxFollow
      L6_2 = L5_2
      L5_2 = L5_2.Create
      L7_2 = L4_2
      L5_2 = L5_2(L6_2, L7_2)
      L7_2 = L5_2
      L6_2 = L5_2.Activate
      L8_2 = true
      L9_2 = L1_2.uStartAttachedToPlayer
      L9_2 = L9_2 ~= nil
      L6_2(L7_2, L8_2, L9_2)
      A0_2.oFollower = L5_2
    end
  end
  L4_2 = ObjectFilter
  L4_2 = L4_2.Create
  L4_2 = L4_2()
  L5_2 = CheckForHeli
  L6_2 = A0_2
  L7_2 = L3_2
  L5_2(L6_2, L7_2)
  L6_2 = A0_2
  L5_2 = A0_2._CreateEvent
  L7_2 = Event
  L7_2 = L7_2.ObjectDeath
  L8_2 = {}
  L9_2 = A0_2._uTgtObjFilter
  L8_2[1] = L9_2
  L9_2 = TargetDestroyed
  L10_2 = {}
  L11_2 = A0_2
  L10_2[1] = L11_2
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L5_2 = MrxSupportData
  L5_2 = L5_2.AddFreebie
  L6_2 = "Extraction_AL"
  L5_2(L6_2)
  L5_2 = Event
  L5_2 = L5_2.CreatePersistent
  L6_2 = Event
  L6_2 = L6_2.ScriptEvent
  L7_2 = {}
  L8_2 = "mpPlayerJoin"
  
  function L9_2(A0_3)
    local L1_3, L2_3
    L1_3 = Net
    L1_3 = L1_3.IsServer
    L1_3 = L1_3()
    if L1_3 then
      L1_3 = Player
      L1_3 = L1_3.IsLocal
      L2_3 = A0_3[1]
      L1_3 = L1_3(L2_3)
      L1_3 = not L1_3
    end
    return L1_3
  end
  
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L8_2 = SendPlayerJoinEvents
  L5_2 = L5_2(L6_2, L7_2, L8_2)
  _evClientJoined = L5_2
end

Activated = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = Net
  L0_2 = L0_2.IsServer
  L0_2 = L0_2()
  if not L0_2 then
    return
  end
  L0_2 = MrxSupportData
  L0_2 = L0_2.AddFreebie
  L1_2 = "Extraction_AL"
  L2_2 = nil
  L3_2 = Player
  L3_2 = L3_2.GetSecondaryPlayer
  L3_2 = L3_2()
  L0_2(L1_2, L2_2, L3_2)
end

SendPlayerJoinEvents = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = ObjectFilter
  L2_2 = L2_2.Create
  L2_2 = L2_2()
  L3_2 = ObjectFilter
  L3_2 = L3_2.SetFilter
  L4_2 = L2_2
  L5_2 = "Allied && Helicopter"
  L3_2(L4_2, L5_2)
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.ObjectProximity
  L6_2 = {}
  L7_2 = L2_2
  L8_2 = A1_2
  L9_2 = "<"
  L10_2 = 40
  L11_2 = false
  L12_2 = false
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L6_2[5] = L11_2
  L6_2[6] = L12_2
  L7_2 = TargetStopsForHeli
  L8_2 = {}
  L9_2 = A0_2
  L10_2 = A1_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  eHeliClose = L3_2
end

CheckForHeli = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L3_2 = A0_2
  L2_2 = A0_2.CancelPart
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

TargetDestroyed = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = A2_2[1]
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L4_2 = Object
    L4_2 = L4_2.HasLabel
    L5_2 = L3_2
    L6_2 = "Allied"
    L4_2 = L4_2(L5_2, L6_2)
    if L4_2 then
      L4_2 = A0_2.oFollower
      if L4_2 then
        L4_2 = A0_2.oFollower
        L5_2 = L4_2
        L4_2 = L4_2.Activate
        L6_2 = false
        L4_2(L5_2, L6_2)
      end
      L4_2 = Vehicle
      L4_2 = L4_2.GetFromRider
      L5_2 = A1_2
      L4_2 = L4_2(L5_2)
      if L4_2 then
        L5_2 = Ai
        L5_2 = L5_2.Goal
        L6_2 = {}
        L6_2.AIGuid = A1_2
        L6_2.Goal = "Exit"
        L6_2.Priority = "hiPri"
        L6_2.Force = true
        L7_2 = TargetRunsForHeli
        L6_2.Callback = L7_2
        L7_2 = {}
        L8_2 = A0_2
        L9_2 = A1_2
        L10_2 = A2_2
        L11_2 = "Target"
        L7_2[1] = L8_2
        L7_2[2] = L9_2
        L7_2[3] = L10_2
        L7_2[4] = L11_2
        L6_2.CallbackData = L7_2
        L5_2(L6_2)
      end
      L6_2 = A0_2
      L5_2 = A0_2._CreateEvent
      L7_2 = Event
      L7_2 = L7_2.TimerRelative
      L8_2 = {}
      L9_2 = 3
      L8_2[1] = L9_2
      L9_2 = TargetRunsForHeli
      L10_2 = {}
      L11_2 = A0_2
      L12_2 = A1_2
      L13_2 = A2_2
      L14_2 = "Target"
      L10_2[1] = L11_2
      L10_2[2] = L12_2
      L10_2[3] = L13_2
      L10_2[4] = L14_2
      L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
      L6_2 = A0_2
      L5_2 = A0_2._CreateEvent
      L7_2 = Event
      L7_2 = L7_2.ObjectHealth
      L8_2 = {}
      L9_2 = A2_2[1]
      L10_2 = "<"
      L11_2 = Object
      L11_2 = L11_2.GetHealth
      L12_2 = A2_2[1]
      L11_2 = L11_2(L12_2)
      L11_2 = L11_2 - 25
      L8_2[1] = L9_2
      L8_2[2] = L10_2
      L8_2[3] = L11_2
      L9_2 = AbortExtract
      L10_2 = {}
      L11_2 = A0_2
      L12_2 = A1_2
      L10_2[1] = L11_2
      L10_2[2] = L12_2
      L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
      uHeliHurt = L5_2
      L6_2 = A0_2
      L5_2 = A0_2._CreateEvent
      L7_2 = Event
      L7_2 = L7_2.TimerRelative
      L8_2 = {}
      L9_2 = 50
      L8_2[1] = L9_2
      L9_2 = AbortExtract
      L10_2 = {}
      L11_2 = A0_2
      L12_2 = A1_2
      L10_2[1] = L11_2
      L10_2[2] = L12_2
      L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
      eHeliFailsafe = L5_2
      L6_2 = A0_2
      L5_2 = A0_2._CreateEvent
      L7_2 = Event
      L7_2 = L7_2.ObjectProximity
      L8_2 = {}
      L9_2 = A2_2[1]
      L10_2 = A1_2
      L11_2 = ">"
      L12_2 = 70
      L13_2 = false
      L14_2 = false
      L8_2[1] = L9_2
      L8_2[2] = L10_2
      L8_2[3] = L11_2
      L8_2[4] = L12_2
      L8_2[5] = L13_2
      L8_2[6] = L14_2
      L9_2 = AbortExtract
      L10_2 = {}
      L11_2 = A0_2
      L12_2 = A1_2
      L10_2[1] = L11_2
      L10_2[2] = L12_2
      L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
      eHeliFar = L5_2
      L6_2 = A0_2
      L5_2 = A0_2._CreateEvent
      L7_2 = Event
      L7_2 = L7_2.ObjectInSeat
      L8_2 = {}
      L9_2 = A1_2
      L10_2 = A2_2[1]
      L11_2 = "a"
      L12_2 = "e"
      L8_2[1] = L9_2
      L8_2[2] = L10_2
      L8_2[3] = L11_2
      L8_2[4] = L12_2
      L9_2 = TargetIn
      L10_2 = {}
      L11_2 = A0_2
      L12_2 = A1_2
      L13_2 = A2_2
      L14_2 = A1_2
      L15_2 = 1
      L10_2[1] = L11_2
      L10_2[2] = L12_2
      L10_2[3] = L13_2
      L10_2[4] = L14_2
      L10_2[5] = L15_2
      L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  end
  else
    L4_2 = CheckForHeli
    L5_2 = A0_2
    L6_2 = A1_2
    L4_2(L5_2, L6_2)
  end
end

TargetStopsForHeli = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = {}
  L3_2.AIGuid = A1_2
  L3_2.Goal = "Enter"
  L4_2 = A2_2[1]
  L3_2.Target = L4_2
  L3_2.Priority = "hiPri"
  L3_2.Force = true
  L4_2 = CheckEnter
  L3_2.Callback = L4_2
  L4_2 = {}
  L5_2 = A0_2
  L6_2 = A2_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L3_2.CallbackData = L4_2
  tEnterGoal = L3_2
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = 2
  L6_2[1] = L7_2
  L7_2 = Ai
  L7_2 = L7_2.Goal
  L8_2 = {}
  L9_2 = tEnterGoal
  L8_2[1] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  eAIenter1 = L3_2
end

TargetRunsForHeli = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  if A3_2 == 0 then
    L5_2 = A0_2
    L4_2 = A0_2._CreateEvent
    L6_2 = Event
    L6_2 = L6_2.TimerRelative
    L7_2 = {}
    L8_2 = 1
    L7_2[1] = L8_2
    L8_2 = TargetRunsForHeli
    L9_2 = {}
    L10_2 = A0_2
    L11_2 = A2_2
    L12_2 = A1_2
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
    eAIenter2 = L4_2
  else
    L4_2 = eHeliFailsafe
    if L4_2 then
      L4_2 = Event
      L4_2 = L4_2.Delete
      L5_2 = eHeliFailsafe
      L4_2(L5_2)
    end
  end
end

CheckEnter = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = eHeliFar
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = eHeliFar
    L2_2(L3_2)
  end
  L2_2 = eHeliFailsafe
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = eHeliFailsafe
    L2_2(L3_2)
  end
  L2_2 = eHeliClose
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = eHeliClose
    L2_2(L3_2)
  end
  L2_2 = eAIenter1
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = eAIenter1
    L2_2(L3_2)
  end
  L2_2 = eAIenter2
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = eAIenter2
    L2_2(L3_2)
  end
  L2_2 = Ai
  L2_2 = L2_2.Goal
  L3_2 = {}
  L3_2.AIGuid = A1_2
  L4_2 = Player
  L4_2 = L4_2.GetLocalCharacter
  L4_2 = L4_2()
  L3_2.Target = L4_2
  L3_2.Goal = "Face"
  L3_2.Position = true
  L3_2.Priority = "hiPri"
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 2
  L5_2[1] = L6_2
  L6_2 = ResetPrisoner
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A1_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

AbortExtract = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = Ai
  L2_2 = L2_2.RemoveGoal
  L3_2 = {}
  L3_2.AIGuid = A1_2
  L3_2.Handle = 0
  L2_2(L3_2)
  L2_2 = A0_2.oFollower
  if L2_2 then
    L2_2 = A0_2.oFollower
    L3_2 = L2_2
    L2_2 = L2_2.Activate
    L4_2 = true
    L2_2(L3_2, L4_2)
  end
  L2_2 = CheckForHeli
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

ResetPrisoner = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L6_2 = A0_2
  L5_2 = A0_2._CreateEvent
  L7_2 = Event
  L7_2 = L7_2.TimerRelative
  L8_2 = {}
  L9_2 = 4
  L8_2[1] = L9_2
  L9_2 = A0_2.CompletePart
  L10_2 = {}
  L11_2 = A0_2
  L12_2 = A1_2
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
end

TargetIn = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxSupportData
  L1_2 = L1_2.RemoveFreebie
  L2_2 = "Extraction_AL"
  L1_2(L2_2)
  L1_2 = MrxTaskObjective
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
