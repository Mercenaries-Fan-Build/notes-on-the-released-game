local L0_1, L1_1
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxHq"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifHqData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = {}
_tHqs = L0_1
L0_1 = {}
_tHqEvents = L0_1

function L0_1(A0_2)
  local L1_2
  if A0_2 then
    L1_2 = _tHqs
    L1_2 = L1_2[A0_2]
    if L1_2 then
      goto lbl_9
    end
  end
  L1_2 = nil
  do return L1_2 end
  ::lbl_9::
  L1_2 = _tHqs
  L1_2 = L1_2[A0_2]
  return L1_2
end

GetHq = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = GetHq
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L3_2 = UnlockHq
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
    L2_2 = L3_2
  end
  L4_2 = L2_2
  L3_2 = L2_2.AddStarter
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
end

AddStarter = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = GetHq
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L4_2 = L2_2
  L3_2 = L2_2.RemoveStarter
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
end

RemoveStarter = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = _tHqs
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    L2_2 = WifHqData
    L2_2 = L2_2.GetHqConfigFromId
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if not L2_2 then
      return
    end
    L3_2 = _tHqs
    L4_2 = MrxHq
    L5_2 = L4_2
    L4_2 = L4_2.Create
    L6_2 = L2_2
    L4_2 = L4_2(L5_2, L6_2)
    L3_2[A0_2] = L4_2
    L3_2 = _tHqs
    L1_2 = L3_2[A0_2]
    L4_2 = L1_2
    L3_2 = L1_2.SetName
    L5_2 = A0_2
    L3_2(L4_2, L5_2)
  end
  L3_2 = L1_2
  L2_2 = L1_2.IsLocked
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L3_2 = L1_2
  L2_2 = L1_2.SetLock
  L4_2 = false
  L2_2(L3_2, L4_2)
  L3_2 = L1_2
  L2_2 = L1_2.RefreshUiDisplay
  L2_2(L3_2)
  L3_2 = L1_2
  L2_2 = L1_2.GetRespawn
  L2_2 = L2_2(L3_2)
  if L2_2 == nil then
    L2_2 = SetHqRespawn
    L3_2 = A0_2
    L4_2 = true
    L2_2(L3_2, L4_2)
  end
  return L1_2
end

UnlockHq = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = _tHqs
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    return
  end
  L3_2 = L1_2
  L2_2 = L1_2.IsLocked
  L2_2 = L2_2(L3_2)
  if L2_2 then
    return
  end
  L3_2 = L1_2
  L2_2 = L1_2.SetLock
  L4_2 = true
  L2_2(L3_2, L4_2)
  L3_2 = L1_2
  L2_2 = L1_2.RefreshUiDisplay
  L2_2(L3_2)
  L2_2 = _tHqEvents
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = _tHqEvents
    L3_2 = L3_2[A0_2]
    L2_2(L3_2)
    L2_2 = _tHqEvents
    L2_2[A0_2] = nil
  end
end

LockHq = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = pairs
  L1_2 = _tHqs
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L6_2 = L4_2
    L5_2 = L4_2.IsLocked
    L5_2 = L5_2(L6_2)
    if not L5_2 then
      L4_2.bGloballyLocked = true
      L5_2 = LockHq
      L6_2 = L3_2
      L5_2(L6_2)
    end
  end
end

LockAllHq = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = pairs
  L1_2 = _tHqs
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = L4_2.bGloballyLocked
    if L5_2 then
      L4_2.bGloballyLocked = nil
      L5_2 = UnlockHq
      L6_2 = L3_2
      L5_2(L6_2)
    end
  end
end

UnlockAllHq = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = _tHqs
  L2_2 = L2_2[A0_2]
  if not L2_2 then
    return
  end
  L3_2 = L2_2.bWatchBuildingHealth
  if L3_2 then
    L3_2 = _tHqEvents
    L4_2 = Event
    L4_2 = L4_2.Create
    L5_2 = Event
    L5_2 = L5_2.ObjectHealth
    L6_2 = {}
    L7_2 = A1_2
    L8_2 = "*"
    L9_2 = "<="
    L10_2 = 1
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L6_2[4] = L10_2
    L7_2 = _OnHqDeath
    L8_2 = {}
    L9_2 = A0_2
    L10_2 = A1_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
    L3_2[A1_2] = L4_2
  else
    L3_2 = _tHqEvents
    L4_2 = Event
    L4_2 = L4_2.Create
    L5_2 = Event
    L5_2 = L5_2.ObjectDeath
    L6_2 = {}
    L7_2 = A1_2
    L6_2[1] = L7_2
    L7_2 = _OnHqDeath
    L8_2 = {}
    L9_2 = A0_2
    L8_2[1] = L9_2
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
    L3_2[A1_2] = L4_2
  end
end

_CreateDeathEvent = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  if A0_2 then
    L3_2 = Object
    L3_2 = L3_2.IsAlive
    L4_2 = A2_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L3_2 = _tHqEvents
      L4_2 = _CreateDeathEvent
      L5_2 = A1_2
      L6_2 = A2_2
      L4_2 = L4_2(L5_2, L6_2)
      L3_2[A2_2] = L4_2
    else
      L3_2 = _OnHqDeath
      L4_2 = A1_2
      L5_2 = A2_2
      L3_2(L4_2, L5_2)
    end
  else
    L3_2 = Object
    L3_2 = L3_2.IsAlive
    L4_2 = A2_2
    L3_2 = L3_2(L4_2)
    if not L3_2 then
      L3_2 = _tHqEvents
      L3_2 = L3_2[A2_2]
      if L3_2 then
        L3_2 = Event
        L3_2 = L3_2.Delete
        L4_2 = _tHqEvents
        L4_2 = L4_2[A2_2]
        L3_2(L4_2)
        L3_2 = _tHqEvents
        L3_2[A2_2] = nil
      end
    end
  end
end

_SetupRespawn = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = _tHqs
  L2_2 = L2_2[A0_2]
  if not L2_2 then
    return
  end
  L4_2 = L2_2
  L3_2 = L2_2.GetRespawn
  L3_2 = L3_2(L4_2)
  if L3_2 == A1_2 then
    return
  end
  L3_2 = nil
  L4_2 = L2_2.vBuildingName
  if not L4_2 then
    return
  end
  L5_2 = L2_2
  L4_2 = L2_2.SetRespawn
  L6_2 = A1_2
  L4_2(L5_2, L6_2)
  L4_2 = type
  L5_2 = L2_2.vBuildingName
  L4_2 = L4_2(L5_2)
  if L4_2 == "string" then
    L4_2 = {}
    L5_2 = L2_2.vBuildingName
    L4_2[1] = L5_2
    L2_2.vBuildingName = L4_2
  end
  L4_2 = ipairs
  L5_2 = L2_2.vBuildingName
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = Pg
    L9_2 = L9_2.GetGuidByName
    L10_2 = L8_2
    L9_2 = L9_2(L10_2)
    L3_2 = L9_2
    if not L3_2 then
    else
      L9_2 = _SetupRespawn
      L10_2 = A1_2
      L11_2 = A0_2
      L12_2 = L3_2
      L9_2(L10_2, L11_2, L12_2)
    end
  end
end

SetHqRespawn = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = _tHqs
  L2_2 = L2_2[A0_2]
  if not L2_2 then
    return
  end
  L4_2 = L2_2
  L3_2 = L2_2.SetLock
  L5_2 = not A1_2
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.RefreshUiDisplay
  L3_2(L4_2)
end

_SetHq = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L4_2 = _tHqs
  L4_2 = L4_2[A0_2]
  if not L4_2 then
    return
  end
  L5_2 = _tHqEvents
  L5_2[A1_2] = nil
  L5_2 = _SetHq
  L6_2 = A0_2
  L7_2 = false
  L5_2(L6_2, L7_2)
  L5_2 = type
  L6_2 = A3_2
  L5_2 = L5_2(L6_2)
  if L5_2 == "userdata" then
    L5_2 = Object
    L5_2 = L5_2.IsPlayerControlled
    L6_2 = A3_2
    L5_2 = L5_2(L6_2)
    if not L5_2 then
      goto lbl_33
    end
  end
  L6_2 = L4_2
  L5_2 = L4_2.GetFaction
  L5_2 = L5_2(L6_2)
  if L5_2 then
    L6_2 = MrxFactionManager
    L6_2 = L6_2.SetRelation
    L7_2 = L5_2
    L8_2 = "Pmc"
    L9_2 = -100
    L6_2(L7_2, L8_2, L9_2)
  end
  ::lbl_33::
  L5_2 = GetHq
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  if L5_2 then
    L7_2 = L5_2
    L6_2 = L5_2.GetRespawn
    L6_2 = L6_2(L7_2)
    if not L6_2 then
      return
    end
  end
  L6_2 = _tHqEvents
  L7_2 = Event
  L7_2 = L7_2.Create
  L8_2 = Event
  L8_2 = L8_2.ObjectHibernation
  L9_2 = {}
  L10_2 = A1_2
  L11_2 = "s"
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L10_2 = _OnHqHibernation
  L11_2 = {}
  L12_2 = A0_2
  L13_2 = A1_2
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
  L6_2[A1_2] = L7_2
end

_OnHqDeath = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = _tHqs
  L2_2 = L2_2[A0_2]
  if not L2_2 then
    return
  end
  L3_2 = _tHqEvents
  L3_2[A1_2] = nil
  L3_2 = Object
  L3_2 = L3_2.Revive
  L4_2 = A1_2
  L3_2(L4_2)
  L3_2 = _SetHq
  L4_2 = A0_2
  L5_2 = true
  L3_2(L4_2, L5_2)
  L3_2 = _tHqEvents
  L4_2 = _CreateDeathEvent
  L5_2 = A0_2
  L6_2 = A1_2
  L4_2 = L4_2(L5_2, L6_2)
  L3_2[A1_2] = L4_2
end

_OnHqHibernation = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _bInside
  return L0_2
end

IsInside = L0_1

function L0_1(A0_2)
  local L1_2
  _bInside = A0_2
end

SetInside = L0_1

function L0_1(A0_2, A1_2)
  _fUnloadCallback = A0_2
  _tUnloadCallbackArgs = A1_2
end

SetUnloadCallback = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _fUnloadCallback
  L1_2 = _tUnloadCallbackArgs
  return L0_2, L1_2
end

GetUnloadCallback = L0_1
