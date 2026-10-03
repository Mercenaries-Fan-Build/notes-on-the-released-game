local L0_1, L1_1, L2_1, L3_1
L0_1 = import
L1_1 = "MrxActionHijack"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxHqManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPlayState"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifHints"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifPmcInterior"
L0_1(L1_1)
L0_1 = 60
L1_1 = 600
L2_1 = 30

function L3_1()
  local L0_2, L1_2
  L0_2 = _bNagEnabled
  if L0_2 then
    return
  end
  L0_2 = true
  _bNagEnabled = L0_2
  L0_2 = _CreateNagTimer
  L1_2 = L0_1
  L0_2(L1_2)
end

StartNag = L3_1

function L3_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = _bNagEnabled
  if not L0_2 then
    return
  end
  L0_2 = _bNagInProgress
  if L0_2 then
    L0_2 = MrxVoSequence
    L0_2 = L0_2.Stop
    L1_2 = nil
    L2_2 = nil
    L3_2 = MrxVoSequence
    L3_2 = L3_2.knPriorityFreeplay
    L0_2(L1_2, L2_2, L3_2)
  end
  L0_2 = _DeleteNagTimer
  L0_2()
  L0_2 = nil
  _bNagEnabled = L0_2
end

StopNag = L3_1

function L3_1()
  local L0_2, L1_2
  L0_2 = _bNagEnabled
  L0_2 = L0_2 == true
  return L0_2
end

IsNagEnabled = L3_1

function L3_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = _DeleteNagTimer
  L1_2()
  L1_2 = _TestNagConditions
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Create
    L2_2 = Event
    L2_2 = L2_2.TimerRelative
    L3_2 = {}
    L4_2 = A0_2
    L3_2[1] = L4_2
    L4_2 = _Nag
    L1_2 = L1_2(L2_2, L3_2, L4_2)
    _uNagTimer = L1_2
  else
    L1_2 = StopNag
    L1_2()
  end
end

_CreateNagTimer = L3_1

function L3_1()
  local L0_2, L1_2
  L0_2 = _uNagTimer
  if L0_2 then
    L0_2 = Event
    L0_2 = L0_2.Delete
    L1_2 = _uNagTimer
    L0_2(L1_2)
    L0_2 = nil
    _uNagTimer = L0_2
  end
end

_DeleteNagTimer = L3_1

function L3_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = MrxVoSequence
  L0_2 = L0_2.IsSequenceInProgress
  L0_2 = L0_2()
  if L0_2 then
    L0_2 = _CreateNagTimer
    L1_2 = L2_1
    L0_2(L1_2)
    return
  end
  L0_2 = _TestNagConditions
  L0_2 = L0_2()
  if not L0_2 then
    L0_2 = StopNag
    L0_2()
    return
  end
  L0_2 = {}
  L1_2 = "Fiona.Misc.NoState01"
  L2_2 = "Fiona.Misc.NoState02"
  L0_2[1] = L1_2
  L0_2[2] = L2_2
  L1_2 = MrxUtil
  L1_2 = L1_2.GetRandomTableElement
  L2_2 = L0_2
  L1_2 = L1_2(L2_2)
  L2_2 = {}
  L3_2 = L1_2
  L4_2 = _NagComplete
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = MrxVoSequence
  L3_2 = L3_2.Start
  L4_2 = L2_2
  L5_2 = nil
  L6_2 = MrxVoSequence
  L6_2 = L6_2.knPriorityFreeplay
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  if L3_2 then
    L4_2 = true
    _bNagInProgress = L4_2
  else
    L4_2 = _CreateNagTimer
    L5_2 = L2_1
    L4_2(L5_2)
  end
end

_Nag = L3_1

function L3_1()
  local L0_2, L1_2
  _bNagInProgress = L0_2
  L0_2 = _CreateNagTimer
  L1_2 = L1_1
  L0_2(L1_2)
end

_NagComplete = L3_1

function L3_1()
  local L0_2, L1_2
  L0_2 = _bNagInProgress
  L0_2 = MrxPlayState
  L0_2 = L0_2.IsFree
  L0_2 = L0_2()
  if L0_2 then
    L0_2 = MrxActionHijack
    L0_2 = L0_2.IsInHijack
    L0_2 = L0_2()
    L0_2 = MrxHqManager
    L0_2 = L0_2.IsInside
    L0_2 = L0_2()
    L0_2 = WifPmcInterior
    L0_2 = L0_2.IsInside
    L0_2 = L0_2()
    L0_2 = WifHints
    L0_2 = L0_2.HasHint
    L1_2 = "Fiona"
    L0_2 = not L0_2 and L0_2
  end
  return L0_2
end

_TestNagConditions = L3_1
