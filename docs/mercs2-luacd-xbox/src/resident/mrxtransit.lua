local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportTransit"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUnlockFanfare"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSound"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxAchievements"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxState"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxStatsManager"
L0_1(L1_1)
L0_1 = 20
_nTransitFuelCost = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L3_2 = _bInitialized
  if L3_2 then
    L3_2 = _bEnabled
    if L3_2 then
      goto lbl_9
    end
  end
  L3_2 = false
  do return L3_2 end
  ::lbl_9::
  L3_2 = {}
  L3_2.Pmc = 1
  L3_2.Oil = 2
  L3_2.Gur = 3
  L3_2.Pir = 4
  L3_2.All = 5
  L3_2.Chi = 6
  L3_2.Vza = 7
  L4_2 = {}
  L5_2 = 0
  L6_2 = pairs
  L7_2 = _tLandingZones
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  for L9_2, L10_2 in L6_2, L7_2, L8_2 do
    L11_2 = L10_2.bEnabled
    if L11_2 then
      L11_2 = L10_2.bSuppressed
      if not L11_2 then
        L11_2 = L10_2.bIsNuked
        if not L11_2 then
          L11_2 = Object
          L11_2 = L11_2.GetPosition
          L12_2 = L10_2.uLocation1
          L11_2, L12_2, L13_2 = L11_2(L12_2)
          L14_2 = 100
          L15_2 = L10_2.sFactionAbbrev
          if L15_2 then
            L15_2 = L10_2.sFactionAbbrev
            L15_2 = L3_2[L15_2]
            L14_2 = L15_2 or L14_2
            if not L15_2 then
            end
          end
          L15_2 = {}
          L16_2 = GetName
          L17_2 = L9_2
          L18_2 = true
          L16_2 = L16_2(L17_2, L18_2)
          L15_2.sName = L16_2
          L15_2.nX = L11_2
          L15_2.nY = L13_2
          L15_2.nSortOrder = L14_2
          L4_2[L9_2] = L15_2
          L5_2 = L5_2 + 1
        end
      end
    end
  end
  if 0 < L5_2 then
    L6_2 = true
    _bInTransit = L6_2
  end
  L6_2 = MrxGui
  L6_2 = L6_2.GetWidgetByNameAndOwner
  L7_2 = "PDA"
  L8_2 = A0_2
  L6_2 = L6_2(L7_2, L8_2)
  L8_2 = L6_2
  L7_2 = L6_2.OpenTransitInterface
  L9_2 = L4_2
  L10_2 = _InterfaceCallback
  L11_2 = {}
  L12_2 = A1_2
  L13_2 = A2_2
  L14_2 = L6_2
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L11_2[3] = L14_2
  L7_2(L8_2, L9_2, L10_2, L11_2)
end

OpenInterface = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2
  _bInTransit = L5_2
  L6_2 = A4_2
  L5_2 = A4_2.Close
  L5_2(L6_2)
  L5_2 = tonumber
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  L6_2 = type
  L7_2 = A2_2
  L6_2 = L6_2(L7_2)
  if "function" == L6_2 then
    L6_2 = type
    L7_2 = A3_2
    L6_2 = L6_2(L7_2)
    if "table" ~= L6_2 then
      L6_2 = {}
      A3_2 = L6_2
    end
    L6_2 = table
    L6_2 = L6_2.insert
    L7_2 = A3_2
    L8_2 = A0_2
    L6_2(L7_2, L8_2)
    L6_2 = table
    L6_2 = L6_2.insert
    L7_2 = A3_2
    L8_2 = A1_2
    L6_2(L7_2, L8_2)
    L6_2 = A2_2
    L7_2 = unpack
    L8_2 = A3_2
    L7_2, L8_2 = L7_2(L8_2)
    L6_2(L7_2, L8_2)
  end
end

_InterfaceCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = _bInitialized
  if L1_2 then
    L1_2 = _bEnabled
    if L1_2 then
      goto lbl_9
    end
  end
  L1_2 = false
  do return L1_2 end
  ::lbl_9::
  L1_2 = _tLandingZones
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = L1_2.bSuppressed
  if not L2_2 then
    L2_2 = L1_2.bEnabled
    if L2_2 then
      L2_2 = L1_2.bIsNuked
      if not L2_2 then
        goto lbl_26
      end
    end
  end
  L2_2 = false
  do return L2_2 end
  ::lbl_26::
  L2_2 = L1_2.uLocation1
  if not L2_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = true
  _bInTransit = L2_2
  
  function L2_2()
    local L0_3, L1_3
    _bInTransit = L0_3
    L0_3 = MrxSound
    L0_3 = L0_3.EndTransit
    L0_3()
  end
  
  L3_2 = MrxUtil
  L3_2 = L3_2.TeleportHeroesToLocations
  L4_2 = {}
  L5_2 = L1_2.uLocation1
  L6_2 = L1_2.uLocation2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = L2_2
  L3_2(L4_2, L5_2)
  L3_2 = MrxSound
  L3_2 = L3_2.BeginTransit
  L3_2()
  L3_2 = true
  return L3_2
end

Transit = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = _bInitialized
  if L1_2 then
    L1_2 = _bEnabled
    if L1_2 then
      goto lbl_9
    end
  end
  L1_2 = nil
  do return L1_2 end
  ::lbl_9::
  L1_2 = _tLandingZones
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    L2_2 = nil
    return L2_2
  end
  L2_2 = L1_2.uLocation1
  return L2_2
end

GetTransitPoint = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = _tLandingZones
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L3_2 = L2_2.sName
    if A1_2 then
      L4_2 = L2_2.sFactionAbbrev
      if L4_2 then
        L5_2 = MrxFactionManager
        L5_2 = L5_2.GetInlineIcon
        L6_2 = L4_2
        L5_2 = L5_2(L6_2)
        if L5_2 then
          L6_2 = L5_2
          L7_2 = " "
          L8_2 = L3_2
          L3_2 = L6_2 .. L7_2 .. L8_2
        end
      end
    end
    return L3_2
  end
end

GetName = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = _bInitialized
  if not L0_2 then
    L0_2 = nil
    return L0_2
  end
  L0_2 = {}
  L1_2 = pairs
  L2_2 = _tLandingZones
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L5_2.bEnabled
    if L6_2 then
      L0_2[L4_2] = L5_2
    end
  end
  return L0_2
end

GetUnlockedLocations = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = _tLandingZones
  if not L0_2 then
    return
  end
  L0_2 = {}
  L1_2 = pairs
  L2_2 = _tLandingZones
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L5_2.bFake
    if not L6_2 then
      L0_2[L4_2] = L5_2
    end
  end
  return L0_2
end

GetUnlockableLocations = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = _tLandingZones
  if not L0_2 then
    L0_2 = 0
    return L0_2
  end
  L0_2 = 0
  L1_2 = pairs
  L2_2 = _tLandingZones
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L5_2.bEnabled
    if L6_2 then
      L6_2 = L5_2.bSuppressed
      if not L6_2 then
        L6_2 = L5_2.bIsNuked
        if not L6_2 then
          L0_2 = L0_2 + 1
        end
      end
    end
  end
  return L0_2
end

GetNumValidLocations = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = _bInitialized
  if not L2_2 then
    L2_2 = Reset
    L2_2()
  end
  L2_2 = not A1_2
  L3_2 = pairs
  L4_2 = _tLandingZones
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = L7_2.sFactionAbbrev
    if L8_2 == A0_2 then
      L8_2 = L7_2.bSuppressed
      if L8_2 ~= L2_2 then
        L7_2.bSuppressed = L2_2
      end
    end
  end
end

EnableFactionLocations = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = _bInitialized
  if not L3_2 then
    L3_2 = Reset
    L3_2()
  end
  L3_2 = _tLandingZones
  if L3_2 then
    L3_2 = _tLandingZones
    L3_2 = L3_2[A0_2]
    if L3_2 then
      L3_2 = _tLandingZones
      L3_2 = L3_2[A0_2]
      L4_2 = L3_2.bFake
      if L4_2 then
        return
      end
      L4_2 = L3_2.bEnabled
      if not L4_2 and not A2_2 then
        L4_2 = L3_2.bHasPlayedFanfare
        if not L4_2 then
          L3_2.bHasPlayedFanfare = true
          L4_2 = MrxUnlockFanfare
          L4_2 = L4_2.AddUnlockedItem
          L5_2 = {}
          L5_2.sType = "landingzone"
          L5_2.sFactionId = A1_2
          L6_2 = Object
          L6_2 = L6_2.GetLocalizedName
          L7_2 = L3_2.uLocation1
          L6_2 = L6_2(L7_2)
          L5_2.sName = L6_2
          L4_2(L5_2)
        end
      end
      L3_2.sFactionAbbrev = A1_2
      L3_2.bEnabled = true
      L4_2 = MrxFactionManager
      L4_2 = L4_2.TestAttitude
      L5_2 = A1_2
      L6_2 = "Pmc"
      L7_2 = ">="
      L8_2 = "Neutral"
      L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
      if not L4_2 then
        L3_2.bSuppressed = true
      end
    end
  end
  L3_2 = GetUnlockedLocations
  L3_2 = L3_2()
  L4_2 = _GetTableSizeSlow
  L5_2 = L3_2
  L4_2 = L4_2(L5_2)
  L5_2 = GetUnlockableLocations
  L5_2 = L5_2()
  L6_2 = _GetTableSizeSlow
  L7_2 = L5_2
  L6_2 = L6_2(L7_2)
  if L4_2 >= L6_2 then
    L7_2 = MrxAchievements
    L7_2 = L7_2.NetGrantAchievement
    L8_2 = "ACHIEVEMENT_BURN_THE_SKY"
    L9_2 = Player
    L9_2 = L9_2.GetPrimaryPlayer
    L9_2 = L9_2()
    L7_2(L8_2, L9_2)
  end
end

SetLocationEnabled = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    L1_2 = 0
    return L1_2
  end
  L1_2 = 0
  L2_2 = pairs
  L3_2 = A0_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2 in L2_2, L3_2, L4_2 do
    L1_2 = L1_2 + 1
  end
  return L1_2
end

_GetTableSizeSlow = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = _bInitialized
  if not L2_2 then
    L2_2 = Reset
    L2_2()
  end
  L2_2 = _tLandingZones
  if L2_2 then
    L2_2 = _tLandingZones
    L2_2 = L2_2[A0_2]
    if L2_2 then
      L2_2 = _tLandingZones
      L2_2 = L2_2[A0_2]
      L3_2 = L2_2.bSuppressed
      if L3_2 ~= A1_2 then
        L2_2.bSuppressed = A1_2
      end
    end
  end
end

SuppressLocation = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = _tLandingZones
  if L1_2 then
    L1_2 = _tLandingZones
    L1_2 = L1_2[A0_2]
    if L1_2 then
      L1_2 = _tLandingZones
      L1_2 = L1_2[A0_2]
      L1_2 = L1_2.bEnabled
    end
  end
  return L1_2
end

IsLocationEnabled = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = _bInitialized
  if L2_2 then
    L2_2 = _tLandingZones
    if L2_2 then
      L2_2 = _tLandingZones
      L2_2 = L2_2[A0_2]
      if L2_2 then
        L2_2 = _tLandingZones
        L2_2 = L2_2[A0_2]
        L2_2.bIsNuked = A1_2
        L3_2 = true
        return L3_2
      end
    end
  end
  L2_2 = false
  return L2_2
end

SetLocationIsNuked = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _bInitialized
  if L0_2 then
    L0_2 = _bEnabled
  end
  return L0_2
end

IsSystemEnabled = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L3_2 = IsSystemEnabled
  L3_2 = L3_2()
  if A0_2 == L3_2 then
    L3_2 = false
    return L3_2
  end
  _bEnabled = A0_2
  if A2_2 ~= true then
    L3_2 = _bEnabled
    if L3_2 then
      L3_2 = MrxSupportTransit
      L4_2 = L3_2
      L3_2 = L3_2.Create
      L5_2 = uPlayerGuid
      L3_2 = L3_2(L4_2, L5_2)
      L5_2 = L3_2
      L4_2 = L3_2.SetFuelCost
      L6_2 = GetTransitFuelCost
      L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L6_2()
      L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
      L4_2 = Hud
      L4_2 = L4_2.SupportMenu
      L5_2 = L4_2
      L4_2 = L4_2.AddItem
      L6_2 = {}
      L6_2.vPlayer = nil
      L6_2.sName = "[support.transit.name]"
      L6_2.sIcon = "HUD_ICON_support_helicopter"
      L6_2.oSupport = L3_2
      L6_2.bAnimate = A1_2
      L4_2(L5_2, L6_2)
    else
      L3_2 = Event
      L3_2 = L3_2.Delete
      L4_2 = _evClientJoinedTransit
      L3_2(L4_2)
      L3_2 = Hud
      L3_2 = L3_2.SupportMenu
      L4_2 = L3_2
      L3_2 = L3_2.RemoveItem
      L5_2 = {}
      L5_2.vPlayer = nil
      L5_2.sName = "[support.transit.name]"
      L3_2(L4_2, L5_2)
    end
  end
  L3_2 = Net
  L3_2 = L3_2.IsServer
  L3_2 = L3_2()
  if L3_2 then
    L3_2 = 0
    L4_2 = 0
    L5_2 = 0
    if A0_2 then
      L3_2 = 1
    end
    if A1_2 then
      L4_2 = 1
    end
    if A2_2 then
      L5_2 = 1
    end
    L6_2 = Net
    L6_2 = L6_2.SendCustomEvent
    L7_2 = "MrxTransit"
    L8_2 = NETEVENT_CLIENTTRANSIT
    L9_2 = {}
    L10_2 = L3_2
    L11_2 = L4_2
    L12_2 = L5_2
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L6_2(L7_2, L8_2, L9_2)
    L6_2 = _evClientJoinedTransit
    if L6_2 then
      L6_2 = Event
      L6_2 = L6_2.Delete
      L7_2 = _evClientJoinedTransit
      L6_2(L7_2)
    end
    L6_2 = Event
    L6_2 = L6_2.CreatePersistent
    L7_2 = Event
    L7_2 = L7_2.ScriptEvent
    L8_2 = {}
    L9_2 = "mpPlayerJoin"
    
    function L10_2(A0_3)
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
    
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L9_2 = Net
    L9_2 = L9_2.SendCustomEvent
    L10_2 = {}
    L11_2 = "MrxTransit"
    L12_2 = NETEVENT_CLIENTTRANSIT
    L13_2 = {}
    L14_2 = L3_2
    L15_2 = L4_2
    L16_2 = L5_2
    L13_2[1] = L14_2
    L13_2[2] = L15_2
    L13_2[3] = L16_2
    L14_2 = true
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L10_2[3] = L13_2
    L10_2[4] = L14_2
    L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
    _evClientJoinedTransit = L6_2
  end
  L3_2 = true
  return L3_2
end

SetSystemEnabled = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _bInitialized
  return L0_2
end

IsSystemInitialized = L0_1
L0_1 = false
_tLandingZones = L0_1
L0_1 = false
_bInitialized = L0_1
L0_1 = false
_bEnabled = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L0_2 = Pg
  L0_2 = L0_2.GetAllLandingZones
  if not L0_2 then
    return
  end
  L0_2 = _bInitialized
  if L0_2 then
    return
  end
  L0_2 = Pg
  L0_2 = L0_2.GetAllLandingZones
  L1_2 = 1
  L0_2 = L0_2(L1_2)
  L1_2 = Pg
  L1_2 = L1_2.GetAllLandingZones
  L2_2 = 2
  L1_2 = L1_2(L2_2)
  if L0_2 then
    L2_2 = #L0_2
    if L2_2 ~= 0 then
      goto lbl_24
    end
  end
  do return end
  ::lbl_24::
  L2_2 = {}
  _tLandingZones = L2_2
  L2_2 = pairs
  L3_2 = L0_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = {}
    L7_2.uLocation1 = L6_2
    L8_2 = L1_2[L5_2]
    L7_2.uLocation2 = L8_2
    L8_2 = Object
    L8_2 = L8_2.GetLocalizedName
    L9_2 = L6_2
    L8_2 = L8_2(L9_2)
    L7_2.sName = L8_2
    L7_2.bEnabled = false
    L8_2 = _tLandingZones
    L8_2[L5_2] = L7_2
  end
  L2_2 = _tLandingZones
  L2_2 = L2_2[6]
  if L2_2 then
    L2_2 = _tLandingZones
    L2_2 = L2_2[6]
    L2_2.bFake = true
  end
  L2_2 = MrxFactionManager
  L2_2 = L2_2.GetFactionAbbrevs
  L2_2 = L2_2()
  L3_2 = ipairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = MrxFactionManager
    L8_2 = L8_2.CreatePersistentAttitudeChangeEvent
    L9_2 = {}
    L10_2 = L7_2
    L11_2 = "Pmc"
    L12_2 = nil
    L13_2 = nil
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L9_2[4] = L13_2
    
    function L10_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3
      L0_3 = MrxFactionManager
      L0_3 = L0_3.TestAttitude
      L1_3 = L7_2
      L2_3 = "Pmc"
      L3_3 = ">="
      L4_3 = "Neutral"
      L0_3 = L0_3(L1_3, L2_3, L3_3, L4_3)
      L1_3 = EnableFactionLocations
      L2_3 = L7_2
      L3_3 = L0_3
      L1_3(L2_3, L3_3)
    end
    
    L8_2(L9_2, L10_2)
  end
  L3_2 = true
  _bInitialized = L3_2
end

Reset = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = _bInitialized
  if not L0_2 then
    L0_2 = Reset
    L0_2()
  end
  L0_2 = {}
  L1_2 = _bEnabled
  L0_2.bEnabled = L1_2
  L1_2 = pairs
  L2_2 = _tLandingZones
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = {}
    L0_2[L4_2] = L6_2
    L6_2 = L0_2[L4_2]
    L7_2 = L5_2.sFactionAbbrev
    L6_2.sFactionAbbrev = L7_2
    L6_2 = L0_2[L4_2]
    L7_2 = L5_2.bHasPlayedFanfare
    L6_2.bHasPlayedFanfare = L7_2
    L6_2 = L0_2[L4_2]
    L7_2 = L5_2.bIsNuked
    L6_2.bIsNuked = L7_2
    L6_2 = L0_2[L4_2]
    L7_2 = L5_2.bEnabled
    L6_2.bEnabled = L7_2
  end
  return L0_2
end

SaveSingleton = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = _bInitialized
  if not L1_2 then
    L1_2 = Reset
    L1_2()
  end
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 == "table" then
    L1_2 = SetSystemEnabled
    L2_2 = A0_2.bEnabled
    L1_2(L2_2)
    L1_2 = pairs
    L2_2 = A0_2
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    for L4_2, L5_2 in L1_2, L2_2, L3_2 do
      L6_2 = type
      L7_2 = L4_2
      L6_2 = L6_2(L7_2)
      if L6_2 == "number" then
        L6_2 = type
        L7_2 = L5_2
        L6_2 = L6_2(L7_2)
        if L6_2 == "boolean" then
          L6_2 = _tLandingZones
          L6_2 = L6_2[L4_2]
          L6_2.sFactionAbbrev = "Pmc"
          L6_2 = _tLandingZones
          L6_2 = L6_2[L4_2]
          L6_2.bEnabled = L5_2
        else
          L6_2 = _tLandingZones
          L6_2 = L6_2[L4_2]
          L7_2 = L5_2.sFactionAbbrev
          L6_2.sFactionAbbrev = L7_2
          L6_2 = _tLandingZones
          L6_2 = L6_2[L4_2]
          L7_2 = L5_2.bHasPlayedFanfare
          L6_2.bHasPlayedFanfare = L7_2
          L6_2 = _tLandingZones
          L6_2 = L6_2[L4_2]
          L7_2 = L5_2.bIsNuked
          L6_2.bIsNuked = L7_2
          L6_2 = _tLandingZones
          L6_2 = L6_2[L4_2]
          L7_2 = L5_2.bEnabled
          L6_2.bEnabled = L7_2
          L6_2 = L5_2.sFactionAbbrev
          if L6_2 then
            L6_2 = MrxFactionManager
            L6_2 = L6_2.TestAttitude
            L7_2 = L5_2.sFactionAbbrev
            L8_2 = "Pmc"
            L9_2 = ">="
            L10_2 = "Neutral"
            L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
            if not L6_2 then
              L6_2 = _tLandingZones
              L6_2 = L6_2[L4_2]
              L6_2.bSuppressed = true
            end
          end
        end
      end
    end
  end
end

LoadSingleton = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = SetSystemEnabled
  L1_2 = true
  L2_2 = false
  L0_2(L1_2, L2_2)
  L0_2 = pairs
  L1_2 = _tLandingZones
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = SetLocationEnabled
    L6_2 = L3_2
    L7_2 = "Pmc"
    L8_2 = true
    L5_2(L6_2, L7_2, L8_2)
  end
end

UnlockAllLandingZones = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _nTransitFuelCost
  return L0_2
end

GetTransitFuelCost = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _bInTransit
  return L0_2
end

IsInTransit = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = true
  _bInTransit = L3_2
  L3_2 = MrxStatsManager
  L3_2 = L3_2.IncreaseTransitCounter
  L3_2()
  L3_2 = MrxState
  L3_2 = L3_2.Enter
  L4_2 = MrxState
  L4_2 = L4_2.STATE_WAITFORSTREAMING
  L5_2 = A0_2
  L6_2 = A2_2
  L7_2 = FinishTransit
  L8_2 = {}
  L9_2 = A1_2
  L10_2 = A2_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  L3_2 = Net
  L3_2 = L3_2.IsServer
  L3_2 = L3_2()
  if L3_2 then
    L3_2 = Net
    L3_2 = L3_2.SendCustomEvent
    L4_2 = "MrxTransit"
    L5_2 = NETEVENT_STARTTRANSIT
    L6_2 = {}
    L3_2(L4_2, L5_2, L6_2)
  end
end

StartTransit = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 0.75
  L6_2 = true
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  
  function L5_2()
    local L0_3, L1_3, L2_3
    _bInTransit = L0_3
    L0_3 = MrxState
    L0_3 = L0_3.Exit
    L1_3 = MrxState
    L1_3 = L1_3.STATE_WAITFORSTREAMING
    L0_3(L1_3)
    L0_3 = MrxUtil
    L0_3 = L0_3.CallWithOptionalArgs
    L1_3 = A0_2
    L2_3 = A1_2
    L0_3(L1_3, L2_3)
  end
  
  L2_2(L3_2, L4_2, L5_2)
end

FinishTransit = L0_1
L0_1 = 0
NETEVENT_CLIENTTRANSIT = L0_1
L0_1 = 1
NETEVENT_STARTTRANSIT = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = NETEVENT_CLIENTTRANSIT
  if A0_2 == L2_2 then
    L2_2 = false
    L3_2 = false
    L4_2 = false
    L5_2 = A1_2[1]
    if L5_2 == 1 then
      L2_2 = true
    end
    L5_2 = A1_2[2]
    if L5_2 == 1 then
      L3_2 = true
    end
    L5_2 = A1_2[3]
    if L5_2 == 1 then
      L4_2 = true
    end
    L5_2 = SetSystemEnabled
    L6_2 = L2_2
    L7_2 = L3_2
    L8_2 = L4_2
    L5_2(L6_2, L7_2, L8_2)
  else
    L2_2 = NETEVENT_STARTTRANSIT
    if A0_2 == L2_2 then
      L2_2 = StartTransit
      L3_2 = nil
      L4_2 = nil
      L5_2 = nil
      L2_2(L3_2, L4_2, L5_2)
    end
  end
end

NetEventCallback = L0_1
