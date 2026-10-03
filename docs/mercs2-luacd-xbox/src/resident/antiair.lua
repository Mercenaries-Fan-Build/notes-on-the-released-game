local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1
L0_1 = inherit
L1_1 = "EnemyBlippable"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "HomingMissile"
L0_1(L1_1)
L0_1 = false
tColorAlly = L0_1
L0_1 = false
tColorNeutral = L0_1
L0_1 = false
tColorEmpty = L0_1
L0_1 = false
tColorPmc = L0_1
L0_1 = {}
L1_1 = {}
L1_1.sLevel = "basic"
L1_1.iArg = 1
L2_1 = {}
L3_1 = 255
L4_1 = 255
L5_1 = 255
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tFlash = L2_1
L1_1.sTexture = "radar_AA"
L1_1.nAARange = 100
L1_1.nSize = 8
L1_1.bSticky = true
L1_1.nSortOrder = 2
L2_1 = {}
L2_1.sTexture = "HUD_anti-air"
L3_1 = {}
L4_1 = 255
L5_1 = 255
L6_1 = 255
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L2_1.tFlash = L3_1
L2_1.nVerticalOffset = 3.5
L2_1.bJust2DCheck = true
L1_1.tMarker = L2_1
L0_1[1] = L1_1
L1_1 = {}
L1_1.sLevel = "medium"
L1_1.iArg = 2
L2_1 = {}
L3_1 = 255
L4_1 = 255
L5_1 = 255
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tFlash = L2_1
L1_1.sTexture = "radar_SAM"
L1_1.nAARange = 200
L1_1.nSize = 8
L1_1.bSticky = true
L1_1.nSortOrder = 2
L2_1 = {}
L2_1.sTexture = "HUD_SAM"
L3_1 = {}
L4_1 = 255
L5_1 = 255
L6_1 = 255
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L2_1.tFlash = L3_1
L2_1.nVerticalOffset = 3.5
L2_1.bJust2DCheck = true
L1_1.tMarker = L2_1
L0_1[2] = L1_1
L1_1 = {}
L1_1.sLevel = "advanced"
L1_1.iArg = 3
L2_1 = {}
L3_1 = 255
L4_1 = 255
L5_1 = 255
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tFlash = L2_1
L1_1.sTexture = "radar_AA"
L1_1.nAARange = 200
L1_1.nSize = 8
L1_1.bSticky = true
L1_1.nSortOrder = 2
L2_1 = {}
L2_1.sTexture = "HUD_anti-air"
L3_1 = {}
L4_1 = 255
L5_1 = 255
L6_1 = 255
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L2_1.tFlash = L3_1
L2_1.nVerticalOffset = 3.5
L2_1.bJust2DCheck = true
L1_1.tMarker = L2_1
L0_1[3] = L1_1
L1_1 = {}
L1_1.sLevel = "jammer"
L1_1.iArg = 4
L2_1 = {}
L3_1 = 255
L4_1 = 255
L5_1 = 255
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tFlash = L2_1
L1_1.sTexture = "radar_Jammer"
L1_1.nAARange = 200
L1_1.nSize = 8
L1_1.bSticky = true
L1_1.nSortOrder = 2
L2_1 = {}
L2_1.sTexture = "HUD_jammer"
L3_1 = {}
L4_1 = 255
L5_1 = 255
L6_1 = 255
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L2_1.tFlash = L3_1
L2_1.nVerticalOffset = 3.5
L2_1.bJust2DCheck = true
L1_1.tMarker = L2_1
L0_1[4] = L1_1
_tPrototype = L0_1
L0_1 = tEvent
if not L0_1 then
  L0_1 = {}
end
tEvent = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = getfenv
  L1_2 = L1_2()
  L2_2 = pairs
  L3_2 = _tPrototype
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = setmetatable
    L8_2 = L6_2
    L9_2 = {}
    L9_2.__index = L1_2
    L7_2(L8_2, L9_2)
  end
end

Init = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectHibernation
  L5_2 = {}
  L6_2 = A0_2
  L7_2 = "awake"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = Awake
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A2_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
end

OnActivate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = Object
  L2_2 = L2_2.IsAlive
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L2_2 = tEvent
  L3_2 = {}
  L2_2[A0_2] = L3_2
  L2_2 = Object
  L2_2 = L2_2.GetHibernationDistance
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = _tPrototype
  L3_2 = L3_2[A1_2]
  L3_2 = L3_2.nAARange
  if L2_2 <= L3_2 then
    L2_2 = ActivateAA
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  else
    L2_2 = CreateNearnessEvent
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  end
end

Awake = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = tEvent
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = tEvent
    L1_2 = L1_2[A0_2]
    L1_2 = L1_2.oClose
    if L1_2 then
      L1_2 = Event
      L1_2 = L1_2.Delete
      L2_2 = tEvent
      L2_2 = L2_2[A0_2]
      L2_2 = L2_2.oClose
      L1_2(L2_2)
    end
  end
  L1_2 = tEvent
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = tEvent
    L1_2 = L1_2[A0_2]
    L1_2 = L1_2.oFar
    if L1_2 then
      L1_2 = Event
      L1_2 = L1_2.Delete
      L2_2 = tEvent
      L2_2 = L2_2[A0_2]
      L2_2 = L2_2.oFar
      L1_2(L2_2)
    end
  end
  L1_2 = tEvent
  L1_2[A0_2] = nil
  L1_2 = EnemyBlippable
  L1_2 = L1_2.OnDeactivate
  L2_2 = A0_2
  L1_2(L2_2)
end

OnDeactivate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = tEvent
  L2_2 = L2_2[A0_2]
  L2_2 = L2_2.oClose
  if L2_2 then
    return
  end
  L2_2 = tEvent
  L2_2 = L2_2[A0_2]
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAnyCharacter
  L6_2 = L6_2()
  L7_2 = A0_2
  L8_2 = "<"
  L9_2 = _tPrototype
  L9_2 = L9_2[A1_2]
  L9_2 = L9_2.nAARange
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L6_2 = ActivateWithEvents
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A1_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2.oClose = L3_2
end

CreateNearnessEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = tEvent
  L2_2 = L2_2[A0_2]
  L2_2.oClose = nil
  L2_2 = ActivateAA
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
  L2_2 = CreateDistanceEvent
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

ActivateWithEvents = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = tEvent
  L2_2 = L2_2[A0_2]
  L2_2.oFar = nil
  L2_2 = ClearBlipped
  L3_2 = tEvent
  L3_2 = L3_2[A0_2]
  L3_2 = L3_2.oInstance
  L2_2(L3_2)
  L2_2 = CreateNearnessEvent
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

DeactivateWithEvents = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = tEvent
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L2_2 = tEvent
    L2_2 = L2_2[A0_2]
    L2_2 = L2_2.oClose
    if L2_2 then
      L2_2 = Event
      L2_2 = L2_2.Delete
      L3_2 = tEvent
      L3_2 = L3_2[A0_2]
      L3_2 = L3_2.oClose
      L2_2(L3_2)
      L2_2 = tEvent
      L2_2 = L2_2[A0_2]
      L2_2.oClose = nil
    end
  end
  L2_2 = _tPrototype
  L2_2 = L2_2[A1_2]
  L3_2 = tEvent
  L3_2 = L3_2[A0_2]
  L5_2 = L2_2
  L4_2 = L2_2.Create
  L6_2 = A0_2
  L4_2 = L4_2(L5_2, L6_2)
  L3_2.oInstance = L4_2
end

ActivateAA = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = tEvent
  L2_2 = L2_2[A0_2]
  L2_2 = L2_2.oFar
  if L2_2 then
    return
  end
  L2_2 = tEvent
  L2_2 = L2_2[A0_2]
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAllCharacters
  L6_2 = L6_2()
  L7_2 = A0_2
  L8_2 = ">"
  L9_2 = _tPrototype
  L9_2 = L9_2[A1_2]
  L9_2 = L9_2.nAARange
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L6_2 = DeactivateWithEvents
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A1_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2.oFar = L3_2
end

CreateDistanceEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = EnemyBlippable
  L2_2 = L2_2.SetBlipped
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = A0_2.bHostile
  if L2_2 then
    L2_2 = MrxSupport
    L2_2 = L2_2.AddAntiAir
    L3_2 = A0_2.uGuid
    L4_2 = A0_2.sLevel
    L2_2(L3_2, L4_2)
  end
end

SetBlipped = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = _HomingLockClear
  L3_2 = nil
  L4_2 = {}
  L5_2 = A0_2.uOwnerGuid
  L4_2.uOwnerGuid = L5_2
  L5_2 = A0_2.uGuid
  L4_2.uVehicleGuid = L5_2
  L5_2 = A0_2.uPlayerGuid
  L4_2.uPlayerGuid = L5_2
  L2_2(L3_2, L4_2)
  L2_2 = A0_2.bHostile
  if L2_2 then
    L2_2 = MrxSupport
    L2_2 = L2_2.RemoveAntiAir
    L3_2 = A0_2.uGuid
    L2_2(L3_2)
  end
  L2_2 = EnemyBlippable
  L2_2 = L2_2.ClearBlipped
  L3_2 = A0_2
  L2_2(L3_2)
end

ClearBlipped = L0_1
L0_1 = {}
_tLockOns = L0_1
L0_1 = {}
_tLockOnState = L0_1
L0_1 = {}
_tLockOnUpdates = L0_1
L0_1 = "ui_hud_sam_targeted"
ksCueTargeted = L0_1
L0_1 = "ui_hud_radar_targeting_alert"
ksCueTargeting = L0_1
L0_1 = "ui_hud_radar_targeting_new_alert"
ksCueAlert = L0_1
L0_1 = 1
knCueAlertCooldown = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = false
  _bAlertCoolingDown = L0_2
end

_CooldownComplete = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  if A0_2 then
    L2_2 = ksCueAlert
    if A1_2 == L2_2 then
      L2_2 = _bAlertCoolingDown
      if L2_2 then
        return
      end
      L2_2 = Event
      L2_2 = L2_2.Create
      L3_2 = Event
      L3_2 = L3_2.TimerRelative
      L4_2 = {}
      L5_2 = knCueAlertCooldown
      L4_2[1] = L5_2
      L5_2 = _CooldownComplete
      L2_2(L3_2, L4_2, L5_2)
      L2_2 = true
      _bAlertCoolingDown = L2_2
    end
  end
end

_SetSound = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2
  L4_2 = _tLockOnState
  L4_2 = L4_2[A0_2]
  if not L4_2 then
    L4_2 = _tLockOnState
    L5_2 = {}
    L5_2.nTargeting = 0
    L5_2.nTargeted = 0
    L4_2[A0_2] = L5_2
  end
  L4_2 = _tLockOnState
  L4_2 = L4_2[A0_2]
  if A1_2 then
    if A2_2 == "add" then
      L5_2 = L4_2.nTargeted
      if L5_2 == 0 then
        L5_2 = _SetSound
        L6_2 = true
        L7_2 = ksCueTargeted
        L5_2(L6_2, L7_2)
      elseif not A3_2 then
        L5_2 = _SetSound
        L6_2 = true
        L7_2 = ksCueAlert
        L5_2(L6_2, L7_2)
      end
      L5_2 = L4_2.nTargeted
      L5_2 = L5_2 + 1
      L4_2.nTargeted = L5_2
    else
      L5_2 = L4_2.nTargeted
      L5_2 = L5_2 - 1
      L4_2.nTargeted = L5_2
      L5_2 = L4_2.nTargeted
      if L5_2 == 0 then
        L5_2 = _SetSound
        L6_2 = false
        L7_2 = ksCueTargeted
        L5_2(L6_2, L7_2)
      end
    end
  elseif A2_2 == "add" then
    L5_2 = L4_2.nTargeting
    if L5_2 == 0 then
      L5_2 = _SetSound
      L6_2 = true
      L7_2 = ksCueTargeting
      L5_2(L6_2, L7_2)
    elseif not A3_2 then
      L5_2 = _SetSound
      L6_2 = true
      L7_2 = ksCueAlert
      L5_2(L6_2, L7_2)
    end
    L5_2 = L4_2.nTargeting
    L5_2 = L5_2 + 1
    L4_2.nTargeting = L5_2
  else
    L5_2 = L4_2.nTargeting
    L5_2 = L5_2 - 1
    L4_2.nTargeting = L5_2
    L5_2 = L4_2.nTargeting
    if L5_2 == 0 then
      L5_2 = _SetSound
      L6_2 = false
      L7_2 = ksCueTargeting
      L5_2(L6_2, L7_2)
    end
  end
  L5_2 = L4_2.nTargeting
  if L5_2 == 0 then
    L5_2 = L4_2.nTargeted
    if L5_2 == 0 then
      L5_2 = _tLockOnState
      L5_2[A0_2] = nil
    end
  end
end

_UpdateHomingState = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = _tLockOns
  L3_2 = A1_2.uOwnerGuid
  L2_2 = L2_2[L3_2]
  if L2_2 then
    return
  end
  L2_2 = _tLockOns
  L3_2 = A1_2.uOwnerGuid
  L4_2 = {}
  L5_2 = Sys
  L5_2 = L5_2.RealTimeStamp
  L5_2 = L5_2()
  L4_2.uLockTimer = L5_2
  L2_2[L3_2] = L4_2
  L2_2 = _tLockOns
  L3_2 = A1_2.uOwnerGuid
  L2_2 = L2_2[L3_2]
  tLockOn = L2_2
  L2_2 = tLockOn
  L2_2.bTargeted = false
  L2_2 = tLockOn
  L2_2.bBlink = false
  L2_2 = tLockOn
  L3_2 = {}
  L2_2.tEvents = L3_2
  L2_2 = {}
  L3_2 = A1_2.uOwnerGuid
  L2_2.uOwnerGuid = L3_2
  L3_2 = A1_2.uVehicleGuid
  L2_2.uVehicleGuid = L3_2
  L3_2 = A1_2.uPlayerGuid
  L2_2.uPlayerGuid = L3_2
  L3_2 = nil
  L4_2 = A1_2.uPlayerGuid
  if L4_2 then
    L4_2 = Player
    L4_2 = L4_2.GetCharacter
    L5_2 = A1_2.uPlayerGuid
    L4_2 = L4_2(L5_2)
    L5_2 = Vehicle
    L5_2 = L5_2.GetFromRider
    L6_2 = L4_2
    L5_2 = L5_2(L6_2)
    L3_2 = L5_2
  end
  if L3_2 then
    L4_2 = tLockOn
    L4_2 = L4_2.tEvents
    L5_2 = Event
    L5_2 = L5_2.Create
    L6_2 = Event
    L6_2 = L6_2.ObjectDeath
    L7_2 = {}
    L8_2 = L3_2
    L7_2[1] = L8_2
    L8_2 = _HomingLockClear
    L9_2 = {}
    L10_2 = 0
    L11_2 = L2_2
    L12_2 = 1
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
    L4_2[1] = L5_2
    L4_2 = tLockOn
    L4_2 = L4_2.tEvents
    L5_2 = Event
    L5_2 = L5_2.Create
    L6_2 = Event
    L6_2 = L6_2.ObjectInSeat
    L7_2 = {}
    L8_2 = 0
    L9_2 = L3_2
    L10_2 = "d"
    L11_2 = "x"
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L7_2[4] = L11_2
    L8_2 = _HomingLockClear
    L9_2 = {}
    L10_2 = 0
    L11_2 = L2_2
    L12_2 = 2
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
    L4_2[2] = L5_2
  end
  L4_2 = A1_2.uVehicleGuid
  if not L4_2 then
    L4_2 = A1_2.uOwnerGuid
  end
  if L4_2 then
    L5_2 = tLockOn
    L5_2 = L5_2.tEvents
    L6_2 = Event
    L6_2 = L6_2.Create
    L7_2 = Event
    L7_2 = L7_2.ObjectDeath
    L8_2 = {}
    L9_2 = L4_2
    L8_2[1] = L9_2
    L9_2 = _HomingLockClear
    L10_2 = {}
    L11_2 = 0
    L12_2 = L2_2
    L13_2 = 3
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L10_2[3] = L13_2
    L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
    L5_2[3] = L6_2
    L5_2 = tLockOn
    L5_2 = L5_2.tEvents
    L6_2 = Event
    L6_2 = L6_2.Create
    L7_2 = Event
    L7_2 = L7_2.ObjectHibernation
    L8_2 = {}
    L9_2 = L4_2
    L10_2 = "s"
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L9_2 = _HomingLockClear
    L10_2 = {}
    L11_2 = 0
    L12_2 = L2_2
    L13_2 = 4
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L10_2[3] = L13_2
    L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
    L5_2[4] = L6_2
  end
  L5_2 = GetFromGuid
  L6_2 = A1_2.uVehicleGuid
  L5_2 = L5_2(L6_2)
  if L5_2 then
    L6_2 = L5_2.bActive
    if L6_2 then
      L6_2 = A1_2.uOwnerGuid
      L5_2.uOwnerGuid = L6_2
      L6_2 = A1_2.uPlayerGuid
      L5_2.uPlayerGuid = L6_2
    end
  end
  L6_2 = _UpdateHomingState
  L7_2 = A1_2.uPlayerGuid
  L8_2 = tLockOn
  L8_2 = L8_2.bTargeted
  L9_2 = "add"
  L6_2(L7_2, L8_2, L9_2)
end

_HomingLockStart = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L2_2 = _tLockOns
  L3_2 = A1_2.uOwnerGuid
  L2_2 = L2_2[L3_2]
  if not L2_2 then
    L3_2 = _HomingLockStart
    L4_2 = A0_2
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
    return
  end
  L3_2 = A1_2.nPercent
  L3_2 = 1 <= L3_2
  L4_2 = L2_2.bTargeted
  if L4_2 ~= L3_2 then
    L4_2 = _UpdateHomingState
    L5_2 = A1_2.uPlayerGuid
    L6_2 = L2_2.bTargeted
    L7_2 = "remove"
    L4_2(L5_2, L6_2, L7_2)
    L4_2 = _UpdateHomingState
    L5_2 = A1_2.uPlayerGuid
    L6_2 = L3_2
    L7_2 = "add"
    L8_2 = true
    L4_2(L5_2, L6_2, L7_2, L8_2)
    L2_2.bTargeted = L3_2
  end
  L4_2 = GetFromGuid
  L5_2 = A1_2.uVehicleGuid
  L4_2 = L4_2(L5_2)
  if L4_2 then
    L5_2 = L4_2.bActive
    if L5_2 then
      L5_2 = A1_2.uOwnerGuid
      L4_2.uOwnerGuid = L5_2
      L5_2 = A1_2.uPlayerGuid
      L4_2.uPlayerGuid = L5_2
      if L3_2 then
        L5_2 = 5
        if L5_2 then
          goto lbl_51
        end
      end
      L5_2 = A1_2.nPercent
      L5_2 = 2 * L5_2
      L5_2 = 1 + L5_2
      ::lbl_51::
      L6_2 = Sys
      L6_2 = L6_2.TimeStampGetElapsed
      L7_2 = L2_2.uLockTimer
      L6_2 = L6_2(L7_2)
      L6_2 = L6_2 * L5_2
      if L3_2 then
        L7_2 = 0.1
        if L7_2 then
          goto lbl_62
        end
      end
      L7_2 = 0.2
      ::lbl_62::
      L8_2 = math
      L8_2 = L8_2.floor
      L9_2 = L6_2
      L8_2 = L8_2(L9_2)
      L8_2 = L6_2 - L8_2
      L9_2 = L7_2 * L5_2
      L8_2 = L8_2 < L9_2
      L9_2 = L2_2.bBlink
      if L9_2 ~= L8_2 then
        L2_2.bBlink = L8_2
        L10_2 = L4_2
        L9_2 = L4_2.AddObjective
        L11_2 = L8_2
        L9_2(L10_2, L11_2)
      end
    end
  end
  L5_2 = {}
  L6_2 = A1_2.uOwnerGuid
  L5_2.uOwnerGuid = L6_2
  L6_2 = A1_2.uVehicleGuid
  L5_2.uVehicleGuid = L6_2
  L6_2 = A1_2.uPlayerGuid
  L5_2.uPlayerGuid = L6_2
  L6_2 = Event
  L6_2 = L6_2.Delete
  L7_2 = L2_2.tEvents
  L7_2 = L7_2[5]
  L6_2(L7_2)
  L6_2 = L2_2.tEvents
  L7_2 = Event
  L7_2 = L7_2.Create
  L8_2 = Event
  L8_2 = L8_2.Timer
  L9_2 = {}
  L10_2 = 1
  L9_2[1] = L10_2
  
  function L10_2(A0_3, A1_3, A2_3)
    local L3_3, L4_3, L5_3, L6_3
    L3_3 = _HomingLockClear
    L4_3 = A0_3
    L5_3 = A1_3
    L6_3 = A2_3
    L3_3(L4_3, L5_3, L6_3)
  end
  
  L11_2 = {}
  L12_2 = 0
  L13_2 = L5_2
  L14_2 = nil
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L11_2[3] = L14_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
  L6_2[5] = L7_2
end

_HomingLockUpdate = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = _tLockOns
  L4_2 = A1_2.uOwnerGuid
  L3_2 = L3_2[L4_2]
  if not L3_2 then
    return
  end
  L4_2 = ipairs
  L5_2 = L3_2.tEvents
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    if L7_2 ~= A2_2 then
      L9_2 = Event
      L9_2 = L9_2.Delete
      L10_2 = L8_2
      L9_2(L10_2)
    end
  end
  L4_2 = _UpdateHomingState
  L5_2 = A1_2.uPlayerGuid
  L6_2 = L3_2.bTargeted
  L7_2 = "remove"
  L8_2 = true
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = GetFromGuid
  L5_2 = A1_2.uVehicleGuid
  L4_2 = L4_2(L5_2)
  if L4_2 then
    L5_2 = L4_2.bActive
    if L5_2 then
      L5_2 = A1_2.uOwnerGuid
      L4_2.uOwnerGuid = L5_2
      L5_2 = A1_2.uPlayerGuid
      L4_2.uPlayerGuid = L5_2
      L3_2.bTargeted = false
      L5_2 = L3_2.bBlink
      if L5_2 then
        L3_2.bBlink = false
        L6_2 = L4_2
        L5_2 = L4_2.AddObjective
        L7_2 = false
        L5_2(L6_2, L7_2)
      end
    end
  end
  L5_2 = _tLockOns
  L6_2 = A1_2.uOwnerGuid
  L5_2[L6_2] = nil
end

_HomingLockClear = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = HomingMissile
  L2_2 = L2_2._HomingLaunched
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

_HomingLaunched = L0_1
