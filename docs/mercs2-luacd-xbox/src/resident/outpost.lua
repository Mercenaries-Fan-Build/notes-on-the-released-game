local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiInterface"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxOutpostManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = {}
_tOutposts = L0_1
L0_1 = {}
L0_1.Allied = 0
L0_1.Pirate = 0
L0_1.China = 0
L0_1.Guerilla = 0
L0_1.OC = 0
_tSupportRefCount = L0_1
L0_1 = {}
L0_1.Allied = "SoldierDelivery_AL"
L0_1.Pirate = "SoldierDelivery_PR"
L0_1.China = "SoldierDelivery_CH"
L0_1.Guerilla = "SoldierDelivery_GR"
L0_1.OC = "SoldierDelivery_OC"
tDefaultSupport = L0_1
L0_1 = "VZ"
sDefenders = L0_1
L0_1 = "OC"
sAttackers = L0_1
L0_1 = 10
nCaptureTime = L0_1
L0_1 = 150
nStartRange = L0_1
L0_1 = 20
nSpawnTime = L0_1
L0_1 = 5000
iCashReward = L0_1
L0_1 = {}
tDBSpawners = L0_1
L0_1 = nil
fCapturedCallback = L0_1
L0_1 = {}
tCapturedCallbackData = L0_1
L0_1 = nil
fDestroyedCallback = L0_1
L0_1 = {}
tDestroyedCallbackData = L0_1
L0_1 = nil
fUpdatedCallback = L0_1
L0_1 = {}
tUpdatedCallbackData = L0_1
L0_1 = {}
tCapturePts = L0_1
L0_1 = 3
nStartingHealth = L0_1
L0_1 = 1
nRusherQuota = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2 or nil
  if A0_2 then
    L1_2 = _tOutposts
    L1_2 = L1_2[A0_2]
  end
  return L1_2
end

Find = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = Net
  L2_2 = L2_2.IsClient
  L2_2 = L2_2()
  if L2_2 then
    return
  end
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = A1_2.sOutpost
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L3_2 = {}
  L4_2 = setmetatable
  L5_2 = L3_2
  L6_2 = {}
  L6_2.__index = A0_2
  L4_2(L5_2, L6_2)
  L3_2.uGuid = L2_2
  L4_2 = pairs
  L5_2 = A1_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L3_2[L7_2] = L8_2
  end
  L4_2 = A1_2.sBoundary
  if L4_2 then
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L3_2.tCapturePts
    L6_2 = A1_2.sBoundary
    L4_2(L5_2, L6_2)
  end
  L4_2 = {}
  L3_2.tEvents = L4_2
  L5_2 = L3_2
  L4_2 = L3_2.Activate
  L4_2(L5_2)
  L4_2 = L3_2.tEvents
  L5_2 = Event
  L5_2 = L5_2.Create
  L6_2 = Event
  L6_2 = L6_2.ObjectDeath
  L7_2 = {}
  L8_2 = L3_2.uGuid
  L7_2[1] = L8_2
  L8_2 = L3_2.OnDeath
  L9_2 = {}
  L10_2 = L3_2
  L9_2[1] = L10_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L4_2.OnDeath = L5_2
  L4_2 = L3_2.tEvents
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
  L9_2 = {}
  L10_2 = L3_2
  L9_2[1] = L10_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L4_2.OnJoin = L5_2
  L4_2 = _tOutposts
  L5_2 = L3_2.uGuid
  L4_2[L5_2] = L3_2
  return L3_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Net
  L1_2 = L1_2.IsClient
  L1_2 = L1_2()
  if L1_2 then
    return
  end
  L1_2 = A0_2.bActive
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.Deactivate
    L1_2(L2_2)
  end
  L1_2 = pairs
  L2_2 = A0_2.tEvents
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Event
    L6_2 = L6_2.Delete
    L7_2 = L5_2
    L6_2(L7_2)
  end
  L1_2 = _tOutposts
  L2_2 = A0_2.uGuid
  L1_2[L2_2] = nil
end

Delete = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = Net
  L1_2 = L1_2.IsClient
  L1_2 = L1_2()
  if L1_2 then
    return
  end
  L2_2 = A0_2
  L1_2 = A0_2.Destroyed
  L1_2(L2_2)
end

OnDeath = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Net
  L1_2 = L1_2.IsClient
  L1_2 = L1_2()
  if L1_2 then
    return
  end
  L1_2 = A0_2.nStartingHealth
  A0_2.nCurrentHealth = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.SetDBFaction
  L3_2 = A0_2.sDefenders
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.TweakDBs
  L3_2 = "on"
  L1_2(L2_2, L3_2)
  L1_2 = {}
  A0_2.tMarkers = L1_2
  L1_2 = MrxSupportData
  L1_2 = L1_2.AddFreebie
  L2_2 = tDefaultSupport
  L3_2 = A0_2.sAttackers
  L2_2 = L2_2[L3_2]
  L1_2(L2_2)
  L1_2 = _tSupportRefCount
  L2_2 = A0_2.sAttackers
  L3_2 = _tSupportRefCount
  L4_2 = A0_2.sAttackers
  L3_2 = L3_2[L4_2]
  L3_2 = L3_2 + 1
  L1_2[L2_2] = L3_2
  L1_2 = {}
  A0_2.tRushers = L1_2
  L1_2 = {}
  A0_2.tBlacklist = L1_2
  L1_2 = {}
  A0_2.tRusherSuccess = L1_2
  A0_2.nAttackers = 0
  A0_2.nDefenders = 0
  L1_2 = A0_2.tEvents
  L2_2 = Event
  L2_2 = L2_2.CreatePersistent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 1
  L4_2[1] = L5_2
  L5_2 = A0_2.TimerTick
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.OnTimer = L2_2
  A0_2.bActive = true
  L2_2 = A0_2
  L1_2 = A0_2.UpdateHealthDisplay
  L1_2(L2_2)
end

Activate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Net
  L1_2 = L1_2.IsClient
  L1_2 = L1_2()
  if L1_2 then
    return
  end
  A0_2.bActive = nil
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.tEvents
  L2_2 = L2_2.OnTimer
  L1_2(L2_2)
  L1_2 = A0_2.tEvents
  L1_2.OnTimer = nil
  L2_2 = A0_2
  L1_2 = A0_2.CancelCallForAttackers
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.CancelCallForDefenders
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.IdleAllRushers
  L1_2(L2_2)
  L1_2 = _tSupportRefCount
  L2_2 = A0_2.sAttackers
  L3_2 = _tSupportRefCount
  L4_2 = A0_2.sAttackers
  L3_2 = L3_2[L4_2]
  L3_2 = L3_2 - 1
  L1_2[L2_2] = L3_2
  L1_2 = _tSupportRefCount
  L2_2 = A0_2.sAttackers
  L1_2 = L1_2[L2_2]
  if L1_2 <= 0 then
    L1_2 = MrxSupportData
    L1_2 = L1_2.RemoveFreebie
    L2_2 = tDefaultSupport
    L3_2 = A0_2.sAttackers
    L2_2 = L2_2[L3_2]
    L1_2(L2_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2.ClearHealthDisplay
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.TweakDBs
  L3_2 = "off"
  L1_2(L2_2, L3_2)
end

Deactivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2.nCurrentHealth
  if L1_2 <= 0 then
    L2_2 = A0_2
    L1_2 = A0_2.Captured
    L1_2(L2_2)
  else
    L2_2 = A0_2
    L1_2 = A0_2.CallForAttackers
    L1_2(L2_2)
    L1_2 = A0_2.nCurrentHealth
    L2_2 = A0_2.nStartingHealth
    if L1_2 < L2_2 then
      L2_2 = A0_2
      L1_2 = A0_2.CallForDefenders
      L1_2(L2_2)
    else
      L2_2 = A0_2
      L1_2 = A0_2.CancelCallForDefenders
      L1_2(L2_2)
    end
  end
end

TimerTick = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2
  L1_2 = A0_2.SetDBFaction
  L3_2 = A0_2.sAttackers
  L1_2(L2_2, L3_2)
  A0_2.bCaptured = true
  L1_2 = MrxOutpostManager
  L1_2 = L1_2.OutpostStatusChange
  L2_2 = A0_2.uGuid
  L3_2 = MrxOutpostManager
  L3_2 = L3_2.knStatusCaptured
  L1_2(L2_2, L3_2)
  L1_2 = MrxUtil
  L1_2 = L1_2.CallWithOptionalArgs
  L2_2 = A0_2.fCapturedCallback
  L3_2 = {}
  L4_2 = unpack
  L5_2 = A0_2.tCapturedCallbackData
  L4_2 = L4_2(L5_2)
  L5_2 = A0_2.uGuid
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.Delete
  L1_2(L2_2)
end

Captured = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  A0_2.bDestroyed = true
  L1_2 = MrxOutpostManager
  L1_2 = L1_2.OutpostStatusChange
  L2_2 = A0_2.uGuid
  L3_2 = MrxOutpostManager
  L3_2 = L3_2.knStatusDestroyed
  L1_2(L2_2, L3_2)
  L1_2 = MrxUtil
  L1_2 = L1_2.CallWithOptionalArgs
  L2_2 = A0_2.fDestroyedCallback
  L3_2 = {}
  L4_2 = unpack
  L5_2 = A0_2.tDestroyedCallbackData
  L4_2 = L4_2(L5_2)
  L5_2 = A0_2.uGuid
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.Delete
  L1_2(L2_2)
end

Destroyed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.bActive
  if not L1_2 then
    return
  end
  L1_2 = UpdateHealthDisplayHelper
  L2_2 = A0_2.nStartingHealth
  L3_2 = A0_2.nCurrentHealth
  L1_2(L2_2, L3_2)
end

UpdateHealthDisplay = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = ClearHealthDisplayHelper
  L1_2()
end

ClearHealthDisplay = L0_1
L0_1 = 0
NETEVENT_UPDATEHEALTHDISPLAY = L0_1
L0_1 = 1
NETEVENT_CLEARHEALTHDISPLAY = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = "[white][Generic.OutpostHealth]:"
  L3_2 = 1
  L4_2 = A0_2 - A1_2
  L5_2 = 1
  for L6_2 = L3_2, L4_2, L5_2 do
    L7_2 = L2_2
    L8_2 = " [green]X"
    L2_2 = L7_2 .. L8_2
  end
  L3_2 = 1
  L4_2 = A1_2
  L5_2 = 1
  for L6_2 = L3_2, L4_2, L5_2 do
    L7_2 = L2_2
    L8_2 = " [red]X"
    L2_2 = L7_2 .. L8_2
  end
  L3_2 = Hud
  L3_2 = L3_2.ObjectiveTray
  L4_2 = L3_2
  L3_2 = L3_2.SetSlotToText
  L5_2 = {}
  L5_2.nSlot = 1
  L5_2.sText = L2_2
  L5_2.bDontNetSync = true
  L3_2(L4_2, L5_2)
  L3_2 = Net
  L3_2 = L3_2.IsServer
  L3_2 = L3_2()
  if L3_2 then
    L3_2 = Net
    L3_2 = L3_2.SendCustomEvent
    L4_2 = "Outpost"
    L5_2 = NETEVENT_UPDATEHEALTHDISPLAY
    L6_2 = {}
    L7_2 = A0_2
    L8_2 = A1_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L3_2(L4_2, L5_2, L6_2)
  end
end

UpdateHealthDisplayHelper = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = Hud
  L0_2 = L0_2.ObjectiveTray
  L1_2 = L0_2
  L0_2 = L0_2.SetSlotToText
  L2_2 = {}
  L2_2.nSlot = 1
  L2_2.sText = " "
  L2_2.bDontNetSync = true
  L0_2(L1_2, L2_2)
  L0_2 = Net
  L0_2 = L0_2.IsServer
  L0_2 = L0_2()
  if L0_2 then
    L0_2 = Net
    L0_2 = L0_2.SendCustomEvent
    L1_2 = "Outpost"
    L2_2 = NETEVENT_CLEARHEALTHDISPLAY
    L3_2 = {}
    L0_2(L1_2, L2_2, L3_2)
  end
end

ClearHealthDisplayHelper = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = NETEVENT_UPDATEHEALTHDISPLAY
  if A0_2 == L2_2 then
    L2_2 = UpdateHealthDisplayHelper
    L3_2 = A1_2[1]
    L4_2 = A1_2[2]
    L2_2(L3_2, L4_2)
  else
    L2_2 = NETEVENT_CLEARHEALTHDISPLAY
    if A0_2 == L2_2 then
      L2_2 = ClearHealthDisplayHelper
      L2_2()
    end
  end
end

NetEventCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = A0_2.bActive
  if L1_2 then
    L1_2 = Net
    L1_2 = L1_2.SendCustomEvent
    L2_2 = "Outpost"
    L3_2 = NETEVENT_UPDATEHEALTHDISPLAY
    L4_2 = {}
    L5_2 = A0_2.nStartingHealth
    L6_2 = A0_2.nCurrentHealth
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L1_2(L2_2, L3_2, L4_2)
  end
end

SendPlayerJoinEvents = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = ipairs
  L3_2 = A0_2.tDBSpawners
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = Pg
    L7_2 = L7_2.GetGuidByName
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    if L7_2 then
      L8_2 = Ai
      L8_2 = L8_2.TweakAttachedSpawners
      L9_2 = L7_2
      L10_2 = {}
      L10_2.SpawnerState = A1_2
      L8_2(L9_2, L10_2)
    end
  end
end

TweakDBs = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L2_2 = {}
  L2_2.Ground = "Ground"
  L2_2.Balcony = "Balcony"
  L2_2.G1 = "AA"
  L2_2.Rooftop = "Balcony"
  L2_2.AA = "AA"
  L2_2.Window = "Balcony"
  L3_2 = ipairs
  L4_2 = A0_2.tDBSpawners
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = Pg
    L8_2 = L8_2.GetGuidByName
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    if L8_2 then
      L9_2 = pairs
      L10_2 = L2_2
      L9_2, L10_2, L11_2 = L9_2(L10_2)
      for L12_2, L13_2 in L9_2, L10_2, L11_2 do
        L14_2 = tostring
        L15_2 = "Spawnlist ("
        L16_2 = A1_2
        L17_2 = " "
        L18_2 = L13_2
        L19_2 = ")"
        L15_2 = L15_2 .. L16_2 .. L17_2 .. L18_2 .. L19_2
        L14_2 = L14_2(L15_2)
        L15_2 = Ai
        L15_2 = L15_2.TweakAttachedSpawnersInGroup
        L16_2 = L8_2
        L17_2 = L12_2
        L18_2 = {}
        L18_2.SpawnList = L14_2
        L19_2 = A0_2.nSpawnTime
        L18_2.SecondsPerCycle = L19_2
        L15_2(L16_2, L17_2, L18_2)
      end
    end
  end
end

SetDBFaction = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2.CallForRushers
  L3_2 = true
  L1_2(L2_2, L3_2)
end

CallForAttackers = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2.CallForRushers
  L3_2 = false
  L1_2(L2_2, L3_2)
end

CallForDefenders = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2
  if A1_2 then
    L2_2 = A0_2.sAttackers
    if L2_2 then
      goto lbl_7
    end
  end
  L2_2 = A0_2.sDefenders
  ::lbl_7::
  L4_2 = A0_2
  L3_2 = A0_2.GetCapturePoint
  L3_2 = L3_2(L4_2)
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = L3_2
  L4_2 = L4_2(L5_2)
  L5_2 = Object
  L5_2 = L5_2.GetPosition
  L6_2 = L4_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L9_2 = A0_2
  L8_2 = A0_2.IsRusherQuotaMet
  L10_2 = A1_2
  L8_2 = L8_2(L9_2, L10_2)
  if L8_2 then
    return
  end
  L8_2 = Pg
  L8_2 = L8_2.FastCollectHumans
  L9_2 = L5_2
  L10_2 = L6_2
  L11_2 = L7_2
  L12_2 = 50
  L13_2 = L2_2
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  L9_2 = {}
  L10_2 = pairs
  L11_2 = L8_2
  L10_2, L11_2, L12_2 = L10_2(L11_2)
  for L13_2, L14_2 in L10_2, L11_2, L12_2 do
    L15_2 = true
    L16_2 = Object
    L16_2 = L16_2.InVehicle
    L17_2 = L14_2
    L16_2, L17_2 = L16_2(L17_2)
    if L15_2 and L17_2 then
      L18_2 = Object
      L18_2 = L18_2.GetPhysicsType
      L19_2 = L17_2
      L18_2 = L18_2(L19_2)
      if L18_2 == "helicopter" then
        L15_2 = false
      end
    end
    if L15_2 and L17_2 then
      L18_2 = ipairs
      L19_2 = Player
      L19_2 = L19_2.GetAllPlayers
      L19_2, L20_2, L21_2, L22_2, L23_2, L24_2 = L19_2()
      L18_2, L19_2, L20_2 = L18_2(L19_2, L20_2, L21_2, L22_2, L23_2, L24_2)
      for L21_2, L22_2 in L18_2, L19_2, L20_2 do
        L23_2 = Player
        L23_2 = L23_2.GetControlledObject
        L24_2 = L22_2
        L23_2 = L23_2(L24_2)
        if L23_2 == L17_2 then
          L15_2 = false
        end
      end
    end
    if L15_2 and L16_2 then
      L18_2 = Vehicle
      L18_2 = L18_2.GetSeatParams
      L19_2 = L16_2
      L18_2 = L18_2(L19_2)
      if L18_2 then
        L19_2 = L18_2.IsGunner
        if L19_2 then
          L15_2 = false
        end
      end
    end
    if L15_2 then
      L18_2 = A0_2.tRusherSuccess
      L18_2 = L18_2[L14_2]
      if not L18_2 then
        L18_2 = A0_2.tBlacklist
        L18_2 = L18_2[L14_2]
        if not L18_2 then
          L18_2 = Ai
          L18_2 = L18_2.GetState
          L19_2 = {}
          L19_2.AIGuid = L14_2
          L19_2.State = "NoCapture"
          L18_2 = L18_2(L19_2)
          if not L18_2 and L3_2 then
            L18_2 = {}
            L18_2.uRusher = L14_2
            L18_2.uInVehicle = L17_2
            L19_2 = table
            L19_2 = L19_2.insert
            L20_2 = L9_2
            L21_2 = L18_2
            L19_2(L20_2, L21_2)
          end
        end
      end
    end
  end
  L10_2 = table
  L10_2 = L10_2.getn
  L11_2 = L9_2
  L10_2 = L10_2(L11_2)
  if L10_2 == 0 then
    L10_2 = pairs
    L11_2 = L8_2
    L10_2, L11_2, L12_2 = L10_2(L11_2)
    for L13_2, L14_2 in L10_2, L11_2, L12_2 do
      L15_2 = A0_2.tBlacklist
      L15_2 = L15_2[L14_2]
      if L15_2 then
        L15_2 = A0_2.tBlacklist
        L15_2[L14_2] = false
      end
    end
  end
  L10_2 = false
  L11_2 = ipairs
  L12_2 = L9_2
  L11_2, L12_2, L13_2 = L11_2(L12_2)
  for L14_2, L15_2 in L11_2, L12_2, L13_2 do
    L10_2 = true
    L16_2 = L15_2.uInVehicle
    if not L16_2 then
      L17_2 = A0_2
      L16_2 = A0_2.IssueCommand
      L18_2 = L15_2.uRusher
      L19_2 = L3_2
      L20_2 = A1_2
      L16_2(L17_2, L18_2, L19_2, L20_2)
    else
      L16_2 = L15_2.uInVehicle
      if L16_2 then
        L16_2 = table
        L16_2 = L16_2.getn
        L17_2 = L9_2
        L16_2 = L16_2(L17_2)
        if L16_2 == L14_2 then
          L16_2 = Vehicle
          L16_2 = L16_2.GetFromRider
          L17_2 = L15_2.uRusher
          L16_2 = L16_2(L17_2)
          L17_2 = Vehicle
          L17_2 = L17_2.Exit
          L18_2 = L16_2
          L19_2 = L15_2.uRusher
          L20_2 = true
          L17_2(L18_2, L19_2, L20_2)
          L18_2 = A0_2
          L17_2 = A0_2.IssueCommand
          L19_2 = L15_2.uRusher
          L20_2 = L3_2
          L21_2 = A1_2
          L17_2(L18_2, L19_2, L20_2, L21_2)
        end
      end
    end
    L17_2 = A0_2
    L16_2 = A0_2.IsRusherQuotaMet
    L18_2 = A1_2
    L16_2 = L16_2(L17_2, L18_2)
    if L16_2 then
      break
    end
  end
  if not L10_2 then
  end
end

CallForRushers = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.sCapturePt
  if L1_2 then
    L1_2 = A0_2.sCapturePt
    return L1_2
  else
    L1_2 = A0_2.tCapturePts
    if L1_2 then
      L1_2 = A0_2.tCapturePts
      L1_2 = L1_2[1]
      return L1_2
    end
  end
end

GetCapturePoint = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L4_2 = A0_2.tRushers
  L4_2 = L4_2[A1_2]
  if L4_2 then
    L4_2 = false
    return L4_2
  end
  L4_2 = Ai
  L4_2 = L4_2.Goal
  L5_2 = {}
  L5_2.AIGuid = A1_2
  L5_2.Goal = "MoveTo"
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = A2_2
  L6_2 = L6_2(L7_2)
  L5_2.Target = L6_2
  L5_2.Priority = "hiPri"
  L6_2 = A0_2.RusherGoalFulfilled
  L5_2.Callback = L6_2
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L5_2.CallbackData = L6_2
  L5_2.Force = true
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L5_2 = false
    return L5_2
  end
  L5_2 = PlayerRusherVO
  L6_2 = A1_2
  L5_2(L6_2)
  L5_2 = Ai
  L5_2 = L5_2.SetPriorityTarget
  L6_2 = uRunnerGuid
  L5_2(L6_2)
  L5_2 = Event
  L5_2 = L5_2.Create
  L6_2 = Event
  L6_2 = L6_2.TimerRelative
  L7_2 = {}
  L8_2 = 20
  L7_2[1] = L8_2
  L8_2 = A0_2.RusherFailed
  L9_2 = {}
  L10_2 = A0_2
  L11_2 = A1_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = Event
  L6_2 = L6_2.Create
  L7_2 = Event
  L7_2 = L7_2.ObjectDeath
  L8_2 = {}
  L9_2 = A1_2
  L8_2[1] = L9_2
  L9_2 = A0_2.RescindRusherCommand
  L10_2 = {}
  L11_2 = A0_2
  L12_2 = A1_2
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
  L7_2 = A0_2.tRushers
  L8_2 = {}
  L8_2.uMoveGoal = L4_2
  L8_2.uTimeoutEvent = L5_2
  L8_2.uDeathEvent = L6_2
  L8_2.bAttacker = A3_2
  L7_2[A1_2] = L8_2
  L8_2 = A0_2
  L7_2 = A0_2.MarkRusher
  L9_2 = A1_2
  L10_2 = true
  L7_2(L8_2, L9_2, L10_2)
  if A3_2 then
    L7_2 = A0_2.nAttackers
    L7_2 = L7_2 + 1
    A0_2.nAttackers = L7_2
  else
    L7_2 = A0_2.nDefenders
    L7_2 = L7_2 + 1
    A0_2.nDefenders = L7_2
  end
end

IssueCommand = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  if A2_2 == 0 then
    L4_2 = A0_2
    L3_2 = A0_2.RescindRusherCommand
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
    return
  end
  L3_2 = Ai
  L3_2 = L3_2.GetFactionGuid
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = A0_2.sDefenders
  L4_2 = L4_2(L5_2)
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = A0_2.sAttackers
  L5_2 = L5_2(L6_2)
  L6_2 = nil
  if L3_2 == L5_2 then
    L6_2 = true
  else
    if L3_2 == L4_2 then
      L6_2 = false
    else
    end
  end
  L7_2 = nil
  L8_2 = Object
  L8_2 = L8_2.InSeat
  L9_2 = A1_2
  L8_2 = L8_2(L9_2)
  if not L8_2 then
    L8_2 = A0_2.tRusherSuccess
    L8_2 = L8_2[A1_2]
    if not L8_2 then
      L8_2 = A0_2.tBlacklist
      L8_2 = L8_2[A1_2]
      if not L8_2 then
        if L6_2 then
          L7_2 = -1
        else
          L7_2 = 1
        end
      end
    end
  end
  L8_2 = nil
  if L7_2 then
    L10_2 = A0_2
    L9_2 = A0_2.HealthChange
    L11_2 = L7_2
    L9_2 = L9_2(L10_2, L11_2)
    L8_2 = L9_2
  end
  if L8_2 then
    L9_2 = A0_2.tRusherSuccess
    L9_2[A1_2] = true
    L10_2 = A0_2
    L9_2 = A0_2.RescindRusherCommand
    L11_2 = A1_2
    L9_2(L10_2, L11_2)
    L9_2 = Object
    L9_2 = L9_2.FadeOut
    L10_2 = A1_2
    L11_2 = 0.5
    L12_2 = true
    L9_2(L10_2, L11_2, L12_2)
  end
end

RusherGoalFulfilled = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2.CancelCallForRushers
  L3_2 = true
  L1_2(L2_2, L3_2)
end

CancelCallForAttackers = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2.CancelCallForRushers
  L3_2 = false
  L1_2(L2_2, L3_2)
end

CancelCallForDefenders = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = pairs
  L3_2 = A0_2.tRushers
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = L6_2.bAttacker
    if L7_2 == A1_2 then
      L8_2 = A0_2
      L7_2 = A0_2.RescindRusherCommand
      L9_2 = L5_2
      L7_2(L8_2, L9_2)
    end
  end
end

CancelCallForRushers = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A0_2.tBlacklist
  L2_2[A1_2] = true
  L3_2 = A0_2
  L2_2 = A0_2.RescindRusherCommand
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

RusherFailed = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2.tRushers
  L2_2 = L2_2[A1_2]
  if not L2_2 then
    return
  end
  L3_2 = Ai
  L3_2 = L3_2.RemoveGoal
  L4_2 = A1_2
  L5_2 = L2_2.uMoveGoal
  L3_2(L4_2, L5_2)
  L3_2 = Event
  L3_2 = L3_2.Delete
  L4_2 = L2_2.uTimeoutEvent
  L3_2(L4_2)
  L3_2 = Event
  L3_2 = L3_2.Delete
  L4_2 = L2_2.uDeathEvent
  L3_2(L4_2)
  L4_2 = A0_2
  L3_2 = A0_2.MarkRusher
  L5_2 = A1_2
  L6_2 = false
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = L2_2.bAttacker
  if L3_2 then
    L3_2 = A0_2.nAttackers
    L3_2 = L3_2 - 1
    A0_2.nAttackers = L3_2
  else
    L3_2 = A0_2.nDefenders
    L3_2 = L3_2 - 1
    A0_2.nDefenders = L3_2
  end
  L3_2 = A0_2.tRushers
  L3_2[A1_2] = nil
end

RescindRusherCommand = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L3_2 = A0_2.tRushers
  L3_2 = L3_2[A1_2]
  if not L3_2 then
    return
  end
  if A2_2 then
    L4_2 = nil
    L5_2 = L3_2.bAttacker
    if L5_2 then
      L4_2 = A0_2.sAttackers
    else
      L4_2 = A0_2.sDefenders
    end
    L5_2 = MrxFactionManager
    L5_2 = L5_2.GetFactionAbbrev
    L6_2 = L4_2
    L5_2 = L5_2(L6_2)
    L6_2 = nil
    if L5_2 then
      L7_2 = MrxFactionManager
      L7_2 = L7_2.GetMarkerTexture
      L8_2 = L5_2
      L7_2 = L7_2(L8_2)
      L6_2 = L7_2
    end
    if L6_2 then
      L7_2 = Marker
      L7_2 = L7_2.AddBlip
      L8_2 = A1_2
      L9_2 = L6_2
      L10_2 = 32
      L11_2 = 255
      L12_2 = 255
      L13_2 = 255
      L14_2 = 255
      L15_2 = 2
      L16_2 = nil
      L17_2 = nil
      L18_2 = 32
      L19_2 = nil
      L20_2 = true
      L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
      L3_2.uMarker = L7_2
      L7_2 = Net
      L7_2 = L7_2.IsServer
      L7_2 = L7_2()
      if L7_2 then
        L7_2 = MrxUtil
        L7_2 = L7_2.MarkerGetIndexByName_World
        L8_2 = L6_2
        L7_2 = L7_2(L8_2)
        L8_2 = Net
        L8_2 = L8_2.SendEvent_AddMarkerObjective
        L9_2 = A1_2
        L10_2 = L3_2.uMarker
        L11_2 = 255
        L12_2 = 255
        L13_2 = 255
        L14_2 = 2
        L15_2 = L7_2
        L16_2 = 1
        L17_2 = 16
        L18_2 = false
        L19_2 = nil
        L20_2 = nil
        L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
      end
    end
    if not L5_2 then
      goto lbl_139
    end
    L7_2 = {}
    L7_2.Pmc = "MiniMap_Icon_Faction_PMC"
    L7_2.Gur = "MiniMap_Icon_Faction_GR"
    L7_2.Oil = "MiniMap_Icon_Faction_OC"
    L7_2.Pir = "MiniMap_Icon_Faction_PR"
    L7_2.All = "MiniMap_Icon_Faction_AN"
    L7_2.Chi = "MiniMap_Icon_Faction_CH"
    L7_2.Vza = "MiniMap_Icon_Faction_VZ"
    L8_2 = L7_2[L5_2]
    L9_2 = Hud
    L9_2 = L9_2.Radar
    L10_2 = L9_2
    L9_2 = L9_2.AddObjective
    L11_2 = {}
    L12_2 = tostring
    L13_2 = A1_2
    L12_2 = L12_2(L13_2)
    L11_2.sName = L12_2
    L11_2.uGuid = A1_2
    L11_2.nR = 255
    L11_2.nG = 255
    L11_2.nB = 255
    L11_2.nWidth = 6
    L11_2.nHeight = 6
    L11_2.sTexture = L8_2
    L11_2.bSticky = true
    L12_2 = L3_2.bAttacker
    if L12_2 then
      L12_2 = 4
      if L12_2 then
        goto lbl_102
      end
    end
    L12_2 = 2
    ::lbl_102::
    L11_2.nSortOrder = L12_2
    L9_2(L10_2, L11_2)
  else
    L4_2 = L3_2.uMarker
    if L4_2 then
      L4_2 = Marker
      L4_2 = L4_2.Remove
      L5_2 = L3_2.uMarker
      L4_2(L5_2)
    end
    L4_2 = Hud
    L4_2 = L4_2.Radar
    L5_2 = L4_2
    L4_2 = L4_2.RemoveObjective
    L6_2 = {}
    L7_2 = tostring
    L8_2 = A1_2
    L7_2 = L7_2(L8_2)
    L6_2.sName = L7_2
    L4_2(L5_2, L6_2)
    L4_2 = Net
    L4_2 = L4_2.IsServer
    L4_2 = L4_2()
    if L4_2 then
      L4_2 = L3_2.uMarker
      if L4_2 then
        L4_2 = Net
        L4_2 = L4_2.SendEvent_RemoveMarkerObjective
        L5_2 = L3_2.uMarker
        L4_2(L5_2)
      end
      L4_2 = Net
      L4_2 = L4_2.SendEvent_RemoveRadarObjective
      L5_2 = tostring
      L6_2 = A1_2
      L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2 = L5_2(L6_2)
      L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
    end
  end
  ::lbl_139::
end

MarkRusher = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = "nDefenders"
  if A1_2 then
    L2_2 = "nAttackers"
  end
  L3_2 = A0_2[L2_2]
  L4_2 = A0_2.nRusherQuota
  L3_2 = L3_2 >= L4_2
  return L3_2
end

IsRusherQuotaMet = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  if A1_2 < 0 then
    L2_2 = A0_2.nCurrentHealth
    if L2_2 <= 0 then
      goto lbl_12
    end
  end
  if 0 < A1_2 then
    L2_2 = A0_2.nCurrentHealth
    L3_2 = A0_2.nStartingHealth
    ::lbl_12::
    if L2_2 >= L3_2 then
      L2_2 = false
      return L2_2
    end
  end
  L2_2 = A0_2.nCurrentHealth
  L2_2 = L2_2 + A1_2
  A0_2.nCurrentHealth = L2_2
  L3_2 = A0_2
  L2_2 = A0_2.UpdateHealthDisplay
  L2_2(L3_2)
  L2_2 = A0_2.fUpdatedCallback
  if L2_2 then
    L2_2 = MrxUtil
    L2_2 = L2_2.CallWithOptionalArgs
    L3_2 = A0_2.fUpdatedCallback
    L4_2 = {}
    L5_2 = unpack
    L6_2 = A0_2.tUpdatedCallbackData
    L5_2, L6_2 = L5_2(L6_2)
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L2_2(L3_2, L4_2)
  end
  L2_2 = A0_2.nCurrentHealth
  if L2_2 <= 0 then
    L3_2 = A0_2
    L2_2 = A0_2.Captured
    L2_2(L3_2)
  end
  L2_2 = true
  return L2_2
end

HealthChange = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = A0_2.uGuid
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  if L2_2 then
    L5_2 = Pg
    L5_2 = L5_2.FastCollectHumans
    L6_2 = L2_2
    L7_2 = L3_2
    L8_2 = L4_2
    L9_2 = 30
    L10_2 = A0_2.sAttackers
    L11_2 = "||"
    L12_2 = A0_2.sDefenders
    L10_2 = L10_2 .. L11_2 .. L12_2
    L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
    L6_2 = ipairs
    L7_2 = L5_2
    L6_2, L7_2, L8_2 = L6_2(L7_2)
    for L9_2, L10_2 in L6_2, L7_2, L8_2 do
      L11_2 = Ai
      L11_2 = L11_2.Role
      L12_2 = {}
      L12_2.AIGuid = L10_2
      L12_2.Role = "Idle"
      L12_2.Priority = "loPri"
      L11_2(L12_2)
    end
  end
end

IdleAllRushers = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxSupportData
  L1_2 = L1_2.GetFreebieName
  L2_2 = tDefaultSupport
  L2_2 = L2_2[A0_2]
  return L1_2(L2_2)
end

GetFactionSupportName = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = MrxUtil
  L1_2 = L1_2.GetFaction
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    return
  end
  L2_2 = Object
  L2_2 = L2_2.HasLabel
  L3_2 = A0_2
  L4_2 = "Female"
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    L2_2 = L1_2
    L3_2 = "F"
    L1_2 = L2_2 .. L3_2
  end
  L2_2 = {}
  L3_2 = {}
  L4_2 = "Mirron01_Soldier_AI Advance_x_x_x_x_x_01"
  L5_2 = "Mirron01_Soldier_AI Advance_x_x_x_x_x_03"
  L6_2 = "Matt01_Soldier_AI Advance_x_x_x_x_x_01"
  L7_2 = "Matt01_Soldier_AI Advance_x_x_x_x_x_03"
  L8_2 = "Allied NY_Richard01_Soldier_AI Advance_x_x_x_x_x_01"
  L9_2 = "Allied NY_Richard01_Soldier_AI Advance_x_x_x_x_x_03"
  L10_2 = "Mirron01_Soldier_AI Attack_Building_x_x_x_x_01"
  L11_2 = "Matt01_Soldier_AI Attack_Building_x_x_x_x_01"
  L12_2 = "Allied NY_Richard01_Soldier_AI Attack_Building_x_x_x_x_01"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L3_2[5] = L8_2
  L3_2[6] = L9_2
  L3_2[7] = L10_2
  L3_2[8] = L11_2
  L3_2[9] = L12_2
  L2_2.Allied = L3_2
  L3_2 = {}
  L4_2 = "VZSoldierArc_Zev01_VZ Soldier_AI Advance_x_x_x_x_x_03"
  L5_2 = "VZSoldierArc_Zev01_Soldier_AI Advance_x_x_x_x_x_02"
  L6_2 = "VZSoldierArc_Zev01_Soldier_AI Advance_x_x_x_x_x_03"
  L7_2 = "VZSoldierArc_Zev01_Soldier_AI Attack_Building_x_x_x_x_01"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L2_2.Guerilla = L3_2
  L3_2 = {}
  L4_2 = "GuerillaSoldier_Rebecca01_Soldier_AI Advance_x_x_x_x_x_00"
  L5_2 = "GuerillaSoldier_Rebecca01_Soldier_AI Advance_x_x_x_x_x_01"
  L6_2 = "GuerillaSoldier_Rebecca01_Soldier_AI Advance_x_x_x_x_x_03"
  L7_2 = "GuerillaSoldier_Rebecca01_Soldier_AI Attack_Building_x_x_x_x_01"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L2_2.GuerillaF = L3_2
  L3_2 = {}
  L4_2 = "VZSoldierArc_Zev01_VZ Soldier_AI Advance_x_x_x_x_x_03"
  L5_2 = "VZSoldierArc_Zev01_Soldier_AI Advance_x_x_x_x_x_02"
  L6_2 = "VZSoldierArc_Zev01_Soldier_AI Advance_x_x_x_x_x_03"
  L7_2 = "VZSoldierArc_Zev01_Soldier_AI Attack_Building_x_x_x_x_01"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L2_2.VZ = L3_2
  L3_2 = {}
  L4_2 = "Generic OC Soldier_Derek01_Soldier_AI Advance_x_x_x_x_x_01"
  L5_2 = "Generic OC Soldier_Derek01_Soldier_AI Advance_x_x_x_x_x_03"
  L6_2 = "Generic OC Soldier_Keith01_Soldier_AI Advance_x_x_x_x_x_01"
  L7_2 = "Generic OC Soldier_Keith01_Soldier_AI Advance_x_x_x_x_x_03"
  L8_2 = "Generic OC Soldier_Derek01_Soldier_AI Attack_Building_x_x_x_x_01"
  L9_2 = "Generic OC Soldier_Keith01_Soldier_AI Attack_Building_x_x_x_x_01"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L3_2[5] = L8_2
  L3_2[6] = L9_2
  L2_2.OC = L3_2
  L3_2 = {}
  L4_2 = "China Soldier_Ming01_Soldier_AI Advance_x_x_x_x_x_00"
  L5_2 = "China Soldier_Ming01_Soldier_AI Advance_x_x_x_x_x_01"
  L6_2 = "China Soldier_Ming01_Soldier_AI Advance_x_x_x_x_x_03"
  L7_2 = "China Soldier_Ming01_Soldier_AI Advance_x_x_x_x_x_05"
  L8_2 = "China Soldier_Ming01_Soldier_AI Attack_Building_x_x_x_x_01"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L3_2[5] = L8_2
  L2_2.China = L3_2
  L3_2 = {}
  L4_2 = "Pirate Thug_Darryl01_Soldier_AI Advance_x_x_x_x_x_01"
  L5_2 = "Pirate Thug_Darryl01_Soldier_AI Advance_x_x_x_x_x_03"
  L6_2 = "Pirate Thug_Jonell01_Soldier_AI Advance_x_x_x_x_x_01"
  L7_2 = "Pirate Thug_Jonell01_Soldier_AI Advance_x_x_x_x_x_03"
  L8_2 = "Pirate Thug_Darryl01_Soldier_AI Attack_Building_x_x_x_x_01"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L3_2[5] = L8_2
  L2_2.Pirate = L3_2
  L3_2 = {}
  L4_2 = "Pirate Thug_Jonell01_Soldier_AI Advance_x_x_x_x_x_00"
  L5_2 = "Pirate Thug_Jonell01_Soldier_AI Advance_x_x_x_x_x_01"
  L6_2 = "Pirate Thug_Jonell01_Soldier_AI Advance_x_x_x_x_x_03"
  L7_2 = "Pirate Thug_Jonell01_Soldier_AI Attack_Building_x_x_x_x_01"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L2_2.PirateF = L3_2
  L3_2 = L2_2[L1_2]
  if L3_2 then
    L3_2 = MrxUtil
    L3_2 = L3_2.GetRandomTableElement
    L4_2 = L2_2[L1_2]
    L3_2 = L3_2(L4_2)
    L4_2 = MrxVoSequence
    L4_2 = L4_2.Start
    L5_2 = L3_2
    L6_2 = nil
    L7_2 = MrxVoSequence
    L7_2 = L7_2.knPriorityFreeplay
    L4_2(L5_2, L6_2, L7_2)
  end
end

PlayerRusherVO = L0_1
