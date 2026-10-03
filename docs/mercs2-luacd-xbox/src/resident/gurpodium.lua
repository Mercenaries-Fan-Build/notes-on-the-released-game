local L0_1, L1_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = {}
  tEvents = L0_2
  L0_2 = {}
  tSpeakers = L0_2
  L0_2 = {}
  tSpeechIndex = L0_2
  L0_2 = {}
  L1_2 = "GuerillaSoldier_Rebecca01_Guerilla Soldier_Prop1"
  L2_2 = "GuerillaSoldier_Rebecca01_Guerilla Soldier_Prop2"
  L3_2 = "GuerillaSoldier_Rebecca01_Guerilla Soldier_Prop3"
  L4_2 = "GuerillaSoldier_Rebecca01_Guerilla Soldier_Prop4"
  L5_2 = "GuerillaSoldier_Rebecca01_Guerilla Soldier_Prop5"
  L0_2[1] = L1_2
  L0_2[2] = L2_2
  L0_2[3] = L3_2
  L0_2[4] = L4_2
  L0_2[5] = L5_2
  tSpeech = L0_2
end

Init = L0_1

function L0_1()
  local L0_2, L1_2
  tEvents = L0_2
  L0_2 = nil
  tSpeakers = L0_2
  L0_2 = nil
  tSpeechIndex = L0_2
  L0_2 = nil
  tSpeech = L0_2
end

Deinit = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = Object
  L2_2 = L2_2.IsAlive
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = {}
    L3_2 = Event
    L3_2 = L3_2.Create
    L4_2 = Event
    L4_2 = L4_2.ObjectDeath
    L5_2 = {}
    L6_2 = A0_2
    L5_2[1] = L6_2
    L6_2 = OnDeath
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.eDeath = L3_2
    L3_2 = tEvents
    L3_2[A0_2] = L2_2
    L3_2 = Vehicle
    L3_2 = L3_2.GetRiders
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
    L4_2 = #L3_2
    if 0 < L4_2 then
      L4_2 = OnEnter
      L5_2 = L3_2[1]
      L6_2 = A0_2
      L4_2(L5_2, L6_2)
    end
  end
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
  L3_2 = tSpeakers
  L3_2[A0_2] = nil
  L3_2 = tSpeechIndex
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
  L8_2 = "a"
  L9_2 = "e"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L6_2 = OnEnter
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L2_2.eEntryExit = L3_2
  L3_2 = tEvents
  L3_2[A1_2] = L2_2
  L3_2 = CancelCue
  L4_2 = A1_2
  L3_2(L4_2)
  L3_2 = tSpeakers
  L3_2[A1_2] = nil
end

OnExit = L0_1

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
  L8_2 = "a"
  L9_2 = "x"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L6_2 = OnExit
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L2_2.eEntryExit = L3_2
  L3_2 = tEvents
  L3_2[A1_2] = L2_2
  L3_2 = tSpeakers
  L3_2[A1_2] = A0_2
  L3_2 = tSpeechIndex
  L3_2[A1_2] = 1
  L3_2 = StartNextCue
  L4_2 = A1_2
  L3_2(L4_2)
end

OnEnter = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = CancelCue
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = OnDeactivate
  L2_2 = A0_2
  L1_2(L2_2)
end

OnDeath = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = tSpeechIndex
  if L1_2 then
    L1_2 = tSpeechIndex
    L1_2 = L1_2[A0_2]
    if L1_2 then
      L1_2 = tSpeechIndex
      L2_2 = tSpeechIndex
      L2_2 = L2_2[A0_2]
      L2_2 = L2_2 + 1
      L1_2[A0_2] = L2_2
      L1_2 = tSpeechIndex
      L1_2 = L1_2[A0_2]
      if 5 < L1_2 then
        L1_2 = tSpeechIndex
        L1_2[A0_2] = 1
      end
      L1_2 = tEvents
      L1_2 = L1_2[A0_2]
      L2_2 = Event
      L2_2 = L2_2.Create
      L3_2 = Event
      L3_2 = L3_2.TimerRelative
      L4_2 = {}
      L5_2 = 1.5
      L6_2 = true
      L4_2[1] = L5_2
      L4_2[2] = L6_2
      L5_2 = StartNextCue
      L6_2 = {}
      L7_2 = A0_2
      L6_2[1] = L7_2
      L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
      L1_2.eStartNext = L2_2
      L2_2 = tEvents
      L2_2[A0_2] = L1_2
    end
  end
end

CueFinished = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = tSpeakers
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L2_2 = tSpeechIndex
    L2_2 = L2_2[A0_2]
    L3_2 = VO
    L3_2 = L3_2.CueWithoutSubtitles
    L4_2 = L1_2
    L5_2 = tSpeech
    L5_2 = L5_2[L2_2]
    L6_2 = CueFinished
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L8_2 = false
    L9_2 = false
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  else
  end
  L2_2 = tEvents
  L2_2 = L2_2[A0_2]
  L2_2.eStartNext = nil
  L3_2 = tEvents
  L3_2[A0_2] = L2_2
end

StartNextCue = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = tSpeakers
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L2_2 = tSpeechIndex
    L2_2 = L2_2[A0_2]
    L3_2 = VO
    L3_2 = L3_2.Cancel
    L4_2 = L1_2
    L5_2 = tSpeech
    L5_2 = L5_2[L2_2]
    L3_2(L4_2, L5_2)
  end
  L2_2 = tEvents
  L2_2 = L2_2[A0_2]
  L3_2 = L2_2.eStartNext
  if L3_2 then
    L3_2 = Event
    L3_2 = L3_2.Delete
    L4_2 = L2_2.eStartNext
    L3_2(L4_2)
    L2_2.eStartNext = nil
  end
  L3_2 = tEvents
  L3_2[A0_2] = L2_2
end

CancelCue = L0_1
