local L0_1, L1_1
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSoundCategories"
L0_1(L1_1)
L0_1 = VO
L0_1 = L0_1.PRIORITY_CINEMATIC
knPriorityCinematic = L0_1
L0_1 = VO
L0_1 = L0_1.PRIORITY_SCRIPTED_BRIEFING
knPriorityBriefing = L0_1
L0_1 = VO
L0_1 = L0_1.PRIORITY_SCRIPTED_CONTRACT
knPriorityContract = L0_1
L0_1 = VO
L0_1 = L0_1.PRIORITY_SCRIPTED_BOUNTIES
knPriorityBounties = L0_1
L0_1 = VO
L0_1 = L0_1.PRIORITY_SCRIPTED_FREEPLAY
knPriorityFreeplay = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L4_2 = MrxUtil
  L4_2 = L4_2.SetDefault
  L5_2 = A3_2
  L6_2 = true
  L4_2 = L4_2(L5_2, L6_2)
  A3_2 = L4_2
  L4_2 = type
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if L4_2 == "string" then
    L5_2 = {}
    L6_2 = A0_2
    L5_2[1] = L6_2
    A0_2 = L5_2
  end
  L5_2 = not L4_2
  if L5_2 == "table" then
    L5_2 = false
    return L5_2
  end
  L5_2 = type
  L6_2 = A1_2
  L5_2 = L5_2(L6_2)
  if L5_2 ~= "boolean" then
    A1_2 = false
  end
  L5_2 = type
  L6_2 = A2_2
  L5_2 = L5_2(L6_2)
  if L5_2 ~= "number" then
    A2_2 = knPriorityContract
  end
  if A1_2 then
    A2_2 = knPriorityCinematic
  end
  L5_2 = {}
  L6_2 = {}
  L7_2 = ipairs
  L8_2 = A0_2
  L7_2, L8_2, L9_2 = L7_2(L8_2)
  for L10_2, L11_2 in L7_2, L8_2, L9_2 do
    L12_2 = type
    L13_2 = L11_2
    L12_2 = L12_2(L13_2)
    if L12_2 == "string" or L12_2 == "number" or L12_2 == "function" then
      L13_2 = {}
      L14_2 = L11_2
      L13_2[1] = L14_2
      L11_2 = L13_2
    end
    L13_2 = nil
    L14_2 = L11_2[1]
    if L14_2 then
      L14_2 = L11_2[1]
      L15_2 = L11_2[2]
      L16_2 = type
      L17_2 = L14_2
      L16_2 = L16_2(L17_2)
      L17_2 = type
      L18_2 = L15_2
      L17_2 = L17_2(L18_2)
      if L16_2 == "string" then
        L18_2 = L15_2
        if L17_2 == "string" then
          L19_2 = Pg
          L19_2 = L19_2.GetGuidByName
          L20_2 = L18_2
          L19_2 = L19_2(L20_2)
          L18_2 = L19_2
        elseif L17_2 == "nil" then
          L18_2 = 0
        end
        L19_2 = {}
        L19_2.vSpeaker = L18_2
        L19_2.sCue = L14_2
        L13_2 = L19_2
        L19_2 = table
        L19_2 = L19_2.insert
        L20_2 = L5_2
        L21_2 = L18_2
        L19_2(L20_2, L21_2)
      elseif L16_2 == "function" then
        L18_2 = L11_2[3]
        L19_2 = {}
        L19_2.fCallback = L14_2
        L19_2.tCallbackArgs = L15_2
        L19_2.bIgnoreOnSkip = L18_2
        L13_2 = L19_2
      elseif L16_2 == "number" then
        if L14_2 < 0 then
          L14_2 = 0
        end
        L18_2 = {}
        L18_2.nDelay = L14_2
        L13_2 = L18_2
      end
    else
      L14_2 = MrxUtil
      L14_2 = L14_2.GetCharacterIdentity
      L15_2 = Player
      L15_2 = L15_2.GetPrimaryCharacter
      L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L15_2()
      L14_2 = L14_2(L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
      if L14_2 then
        L15_2 = {}
        L16_2 = L11_2[L14_2]
        L15_2.sCue = L16_2
        L16_2 = Player
        L16_2 = L16_2.GetPrimaryCharacter
        L16_2 = L16_2()
        L15_2.vSpeaker = L16_2
        L13_2 = L15_2
      else
      end
    end
    if L13_2 then
      L14_2 = table
      L14_2 = L14_2.insert
      L15_2 = L6_2
      L16_2 = L13_2
      L14_2(L15_2, L16_2)
    end
  end
  L7_2 = true
  L8_2 = _tSequence
  if L8_2 then
    L8_2 = _tSequence
    L8_2 = L8_2.nPriority
    if A2_2 <= L8_2 then
      L7_2 = false
      L8_2 = Stop
      L9_2 = L7_2
      L8_2(L9_2)
    else
      L8_2 = _CallSequenceCallbacks
      L9_2 = L6_2
      L8_2(L9_2)
      L8_2 = false
      return L8_2
    end
  end
  _tSequence = L6_2
  L8_2 = _tSequence
  L8_2.nPriority = A2_2
  L8_2 = _tSequence
  L8_2.bSendNetEvent = A3_2
  L8_2 = 0.25
  _nBaseDelay = L8_2
  L8_2 = type
  L9_2 = A0_2.nBaseDelay
  L8_2 = L8_2(L9_2)
  if L8_2 == "number" then
    L8_2 = A0_2.nBaseDelay
    if 0 <= L8_2 then
      L8_2 = A0_2.nBaseDelay
      _nBaseDelay = L8_2
    end
  end
  if L7_2 then
    L8_2 = MrxSoundCategories
    L8_2 = L8_2.Fade
    L9_2 = "vosequence"
    L10_2 = true
    L8_2(L9_2, L10_2)
  end
  L8_2 = table
  L8_2 = L8_2.insert
  L9_2 = L5_2
  L10_2 = Player
  L10_2 = L10_2.GetPrimaryCharacter
  L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L10_2()
  L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
  L8_2 = Player
  L8_2 = L8_2.GetSecondaryCharacter
  L8_2 = L8_2()
  if L8_2 then
    L9_2 = table
    L9_2 = L9_2.insert
    L10_2 = L5_2
    L11_2 = L8_2
    L9_2(L10_2, L11_2)
  end
  L9_2 = ipairs
  L10_2 = L5_2
  L9_2, L10_2, L11_2 = L9_2(L10_2)
  for L12_2, L13_2 in L9_2, L10_2, L11_2 do
    L14_2 = VO
    L14_2 = L14_2.AddSequence
    L15_2 = L13_2
    L16_2 = A2_2
    L14_2(L15_2, L16_2)
  end
  L9_2 = _tSequence
  L9_2.tSpeakers = L5_2
  L9_2 = _ExecuteStage
  L10_2 = 1
  L9_2(L10_2)
  L9_2 = true
  return L9_2
end

Start = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = _tSequence
  if not L1_2 then
    return
  end
  L1_2 = _tSequence
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    L2_2 = Cleanup
    L2_2()
    return
  end
  
  function L2_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
    L1_3 = _bStoppingSequence
    if L1_3 then
      return
    end
    L1_3 = _tSequence
    if not L1_3 then
      return
    end
    L1_3 = _uTimeoutEvent
    if L1_3 then
      L1_3 = Event
      L1_3 = L1_3.Delete
      L2_3 = _uTimeoutEvent
      L1_3(L2_3)
      L1_3 = nil
      _uTimeoutEvent = L1_3
    end
    L1_3 = A0_2
    L1_3 = L1_3 + 1
    L2_3 = _tSequence
    L2_3 = L2_3[L1_3]
    if not L2_3 then
      L3_3 = Cleanup
      L3_3()
      return
    end
    L3_3 = 0
    L4_3 = L2_3.nDelay
    if L4_3 then
      while L2_3 do
        L4_3 = L2_3.nDelay
        if not L4_3 then
          break
        end
        L4_3 = L2_3.nDelay
        L3_3 = L3_3 + L4_3
        L1_3 = L1_3 + 1
        L4_3 = _tSequence
        L2_3 = L4_3[L1_3]
      end
    else
      L4_3 = L2_3.fCallback
      if L4_3 then
        L3_3 = 0
      else
        L3_3 = _nBaseDelay
      end
    end
    if A0_3 == "cancel" then
      L3_3 = L3_3 + 5
    end
    if 0 < L3_3 then
      L4_3 = Event
      L4_3 = L4_3.Create
      L5_3 = Event
      L5_3 = L5_3.TimerRelative
      L6_3 = {}
      L7_3 = L3_3
      L6_3[1] = L7_3
      L7_3 = _ExecuteStage
      L8_3 = {}
      L9_3 = L1_3
      L8_3[1] = L9_3
      L4_3 = L4_3(L5_3, L6_3, L7_3, L8_3)
      _uDelayTimer = L4_3
    else
      L4_3 = _ExecuteStage
      L5_3 = L1_3
      L4_3(L5_3)
    end
  end
  
  L3_2 = L1_2.sCue
  if L3_2 then
    L3_2 = VO
    L3_2 = L3_2.Cue
    L4_2 = L1_2.vSpeaker
    L5_2 = L1_2.sCue
    L6_2 = L2_2
    L7_2 = {}
    L8_2 = _tSequence
    L8_2 = L8_2.nPriority
    L9_2 = _tSequence
    L9_2 = L9_2.bSendNetEvent
    L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
    if not L3_2 then
    end
    L4_2 = Pda
    L4_2 = L4_2.Database
    L5_2 = L4_2
    L4_2 = L4_2.AddLogEntry
    L6_2 = {}
    L6_2.sType = "dialog"
    L6_2.sName = ""
    L7_2 = "["
    L8_2 = L1_2.sCue
    L9_2 = "]"
    L7_2 = L7_2 .. L8_2 .. L9_2
    L6_2.sMessage = L7_2
    L6_2.sColor = "FFFFFF"
    L4_2(L5_2, L6_2)
    L4_2 = _knTimeout
    if L4_2 then
      L4_2 = Event
      L4_2 = L4_2.Create
      L5_2 = Event
      L5_2 = L5_2.TimerRelative
      L6_2 = {}
      L7_2 = _knTimeout
      L6_2[1] = L7_2
      L7_2 = VO
      L7_2 = L7_2.Cancel
      L8_2 = {}
      L9_2 = L1_2.vSpeaker
      L10_2 = L1_2.sCue
      L11_2 = _tSequence
      L11_2 = L11_2.bSendNetEvent
      L8_2[1] = L9_2
      L8_2[2] = L10_2
      L8_2[3] = L11_2
      L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
      _uTimeoutEvent = L4_2
    end
  else
    L3_2 = L1_2.fCallback
    if L3_2 then
      L1_2.bCalled = true
      L3_2 = MrxUtil
      L3_2 = L3_2.CallWithOptionalArgs
      L4_2 = L1_2.fCallback
      L5_2 = L1_2.tCallbackArgs
      L3_2(L4_2, L5_2)
      L3_2 = L2_2
      L3_2()
    end
  end
end

_ExecuteStage = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = _tSequence
  if L3_2 then
    if A2_2 then
      L3_2 = _tSequence
      L3_2 = L3_2.nPriority
      if L3_2 ~= A2_2 then
        return
      end
    end
    L3_2 = true
    _bStoppingSequence = L3_2
    L3_2 = ipairs
    L4_2 = _tSequence
    L3_2, L4_2, L5_2 = L3_2(L4_2)
    for L6_2, L7_2 in L3_2, L4_2, L5_2 do
      L8_2 = L7_2.sCue
      if L8_2 then
        L8_2 = VO
        L8_2 = L8_2.Cancel
        L9_2 = L7_2.vSpeaker
        L10_2 = L7_2.sCue
        L11_2 = _tSequence
        L11_2 = L11_2.bSendNetEvent
        L8_2(L9_2, L10_2, L11_2)
      end
    end
    L3_2 = MrxUtil
    L3_2 = L3_2.SetDefault
    L4_2 = A1_2
    L5_2 = true
    L3_2 = L3_2(L4_2, L5_2)
    A1_2 = L3_2
    if A1_2 then
      L3_2 = _CallSequenceCallbacks
      L4_2 = _tSequence
      L3_2(L4_2)
    end
    L3_2 = nil
    _bStoppingSequence = L3_2
    L3_2 = Cleanup
    L4_2 = A0_2
    L3_2(L4_2)
  end
  L3_2 = _uDelayTimer
  if L3_2 then
    L3_2 = Event
    L3_2 = L3_2.Delete
    L4_2 = _uDelayTimer
    L3_2(L4_2)
    L3_2 = nil
    _uDelayTimer = L3_2
  end
  L3_2 = _uTimeoutEvent
  if L3_2 then
    L3_2 = Event
    L3_2 = L3_2.Delete
    L4_2 = _uTimeoutEvent
    L3_2(L4_2)
    L3_2 = nil
    _uTimeoutEvent = L3_2
  end
end

Stop = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = _tSequence
  if not L1_2 then
    return
  end
  L1_2 = MrxUtil
  L1_2 = L1_2.SetDefault
  L2_2 = A0_2
  L3_2 = true
  L1_2 = L1_2(L2_2, L3_2)
  A0_2 = L1_2
  if A0_2 then
    L1_2 = MrxSoundCategories
    L1_2 = L1_2.Fade
    L2_2 = "vosequence"
    L3_2 = false
    L1_2(L2_2, L3_2)
  end
  L1_2 = _tSequence
  L1_2 = L1_2.tSpeakers
  if L1_2 then
    L1_2 = ipairs
    L2_2 = _tSequence
    L2_2 = L2_2.tSpeakers
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    for L4_2, L5_2 in L1_2, L2_2, L3_2 do
      L6_2 = VO
      L6_2 = L6_2.RemoveSequence
      L7_2 = L5_2
      L8_2 = _tSequence
      L8_2 = L8_2.nPriority
      L6_2(L7_2, L8_2)
    end
  end
  L1_2 = nil
  _tSequence = L1_2
end

Cleanup = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = _tSequence
  if L0_2 then
    L0_2 = MrxSoundCategories
    L0_2 = L0_2.Fade
    L1_2 = "vosequence"
    L2_2 = false
    L0_2(L1_2, L2_2)
  end
  L0_2 = nil
  _tSequence = L0_2
  L0_2 = nil
  _nBaseDelay = L0_2
  L0_2 = nil
  _bCinematic = L0_2
  L0_2 = nil
  _bStoppingSequence = L0_2
  L0_2 = nil
  _uTimeoutEvent = L0_2
  L0_2 = nil
  _knTimeout = L0_2
end

Reset = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = ipairs
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L5_2.fCallback
    if L6_2 then
      L6_2 = L5_2.bIgnoreOnSkip
      if not L6_2 then
        L6_2 = L5_2.bCalled
        if not L6_2 then
          L5_2.bCalled = true
          L6_2 = MrxUtil
          L6_2 = L6_2.CallWithOptionalArgs
          L7_2 = L5_2.fCallback
          L8_2 = L5_2.tCallbackArgs
          L6_2(L7_2, L8_2)
        end
      end
    end
  end
end

_CallSequenceCallbacks = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _tSequence
  L0_2 = L0_2 ~= nil
  return L0_2
end

IsSequenceInProgress = L0_1
