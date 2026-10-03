local L0_1, L1_1
L0_1 = import
L1_1 = "MrxHqManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxStarterManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifPmcInterior"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifFreePlay"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxMusic"
L0_1(L1_1)
L0_1 = -1
_knNull = L0_1
L0_1 = 0
_knFree = L0_1
L0_1 = 1
_knMission = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = _knNull
  L1_2 = A0_2 ~= L1_2
  return L1_2
end

IsValidState = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = _knNull
  if A0_2 == L2_2 then
    L1_2 = "null"
  else
    L2_2 = _knFree
    if A0_2 == L2_2 then
      L1_2 = "free"
    else
      L2_2 = _knMission
      if A0_2 == L2_2 then
        L1_2 = "mission"
      end
    end
  end
  return L1_2
end

GetStateDisplayName = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = IsValidState
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = _nCurrState
    if A0_2 ~= L1_2 then
      _nCurrState = A0_2
      L1_2 = _knFree
      if A0_2 == L1_2 then
        L1_2 = nil
        _oCurrMission = L1_2
        L1_2 = MrxMusic
        L1_2 = L1_2.EnterFreeplayMusic
        L1_2()
        L1_2 = WifFreePlay
        L1_2 = L1_2.StartNag
        L1_2()
      else
        L1_2 = WifFreePlay
        L1_2 = L1_2.StopNag
        L1_2()
      end
      L1_2 = Pda
      L1_2 = L1_2.Map
      L2_2 = L1_2
      L1_2 = L1_2.SetMissionChangeAllowed
      L3_2 = {}
      L4_2 = _knFree
      L4_2 = A0_2 == L4_2
      L3_2.bAllow = L4_2
      L1_2(L2_2, L3_2)
      L1_2 = _UpdateHqObjectiveMarkers
      L1_2()
    else
      L1_2 = false
      return L1_2
    end
  else
    L1_2 = false
    return L1_2
  end
  L1_2 = true
  return L1_2
end

Set = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _nCurrState
  return L0_2
end

Get = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  if A0_2 then
    L1_2 = A0_2.IsContract
    if L1_2 then
      L2_2 = A0_2
      L1_2 = A0_2.IsContract
      L1_2 = L1_2(L2_2)
      if L1_2 then
        _oCurrMission = A0_2
        L1_2 = true
        return L1_2
    end
  end
  else
    L1_2 = false
    return L1_2
  end
end

SetCurrentMission = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _oCurrMission
  return L0_2
end

GetCurrentMission = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = Get
  L0_2 = L0_2()
  L1_2 = _knFree
  L0_2 = L0_2 == L1_2
  return L0_2
end

IsFree = L0_1

function L0_1()
  local L0_2, L1_2
  _nCurrState = L0_2
  L0_2 = nil
  _oCurrMission = L0_2
  L0_2 = MrxMusic
  L0_2 = L0_2.EnterFreeplayMusic
  L0_2()
  L0_2 = MrxStarterManager
  L0_2 = L0_2.DestroyAllStarters
  L0_2()
end

Reset = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L0_2 = MrxStarterManager
  L0_2 = L0_2.GetStarters
  L0_2 = L0_2()
  L1_2 = pairs
  L2_2 = L0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L7_2 = L5_2
    L6_2 = L5_2.GetHq
    L6_2 = L6_2(L7_2)
    L8_2 = L5_2
    L7_2 = L5_2.IsPmcStarter
    L7_2 = L7_2(L8_2)
    if L6_2 then
      L8_2 = MrxHqManager
      L8_2 = L8_2.GetHq
      L9_2 = L6_2
      L8_2 = L8_2(L9_2)
      if L8_2 then
        L10_2 = L8_2
        L9_2 = L8_2.RefreshUiDisplay
        L9_2(L10_2)
      end
    elseif L7_2 then
      L8_2 = WifPmcInterior
      L8_2 = L8_2.RefreshUiDisplay
      L8_2()
    end
  end
end

_UpdateHqObjectiveMarkers = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = GetTimeElapsedInPriorSessions
  L0_2 = L0_2()
  L1_2 = Sys
  L1_2 = L1_2.TimeStampGetElapsed
  L2_2 = _uSessionStartTimestamp
  L1_2 = L1_2(L2_2)
  L2_2 = type
  L3_2 = L0_2
  L2_2 = L2_2(L3_2)
  if L2_2 == "number" then
    L2_2 = type
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    if L2_2 == "number" then
      L2_2 = math
      L2_2 = L2_2.ceil
      L3_2 = L0_2 + L1_2
      return L2_2(L3_2)
  end
  else
    L2_2 = Sys
    L2_2 = L2_2.MainTime
    return L2_2()
  end
end

GetTotalTimeElapsed = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = Sys
  L0_2 = L0_2.MainTimeStamp
  L0_2 = L0_2()
  _uSessionStartTimestamp = L0_2
end

StartSessionTimer = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _uSessionStartTimestamp
  return L0_2
end

GetSessionTimer = L0_1

function L0_1(A0_2)
  local L1_2
  _nTimeElapsedInPriorSessions = A0_2
end

SetTimeElapsedInPriorSessions = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _nTimeElapsedInPriorSessions
  return L0_2
end

GetTimeElapsedInPriorSessions = L0_1
