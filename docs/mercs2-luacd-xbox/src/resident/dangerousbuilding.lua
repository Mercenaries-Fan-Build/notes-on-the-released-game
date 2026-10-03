local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = {}
tDBs = L0_1
L0_1 = 0
L1_1 = 8
L2_1 = 16
L3_1 = L2_1
L4_1 = 0

function L5_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  if A2_2 and 0 < A2_2 then
    return
  end
  L3_2 = tDBs
  L4_2 = tDBs
  L4_2 = L4_2[A0_2]
  if not L4_2 then
    L4_2 = {}
  end
  L3_2[A0_2] = L4_2
  L3_2 = tDBs
  L3_2 = L3_2[A0_2]
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.ObjectHibernation
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = "awake"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = Start
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L3_2.WakeEvent = L4_2
end

OnActivate = L5_1

function L5_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = tDBs
  L1_2 = L1_2[A0_2]
  L1_2.WakeEvent = nil
  L1_2 = Object
  L1_2 = L1_2.IsAlive
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    return
  end
  L1_2 = tDBs
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = tDBs
    L1_2 = L1_2[A0_2]
    L1_2 = L1_2.WakeupFunc
    if L1_2 then
      L1_2 = MrxUtil
      L1_2 = L1_2.CallWithOptionalArgs
      L2_2 = tDBs
      L2_2 = L2_2[A0_2]
      L2_2 = L2_2.WakeupFunc
      L3_2 = {}
      L4_2 = A0_2
      L3_2[1] = L4_2
      L1_2(L2_2, L3_2)
    end
  end
  L1_2 = Net
  L1_2 = L1_2.IsClient
  L1_2 = L1_2()
  if not L1_2 then
    L1_2 = Object
    L1_2 = L1_2.HasLabel
    L2_2 = A0_2
    L3_2 = "Occupied"
    L1_2 = L1_2(L2_2, L3_2)
    if L1_2 then
      L1_2 = SetupOccupied
      L2_2 = A0_2
      L3_2 = false
      L1_2(L2_2, L3_2)
      return
    end
    L1_2 = L3_1
    L2_2 = tDBs
    L2_2 = L2_2[A0_2]
    if L2_2 then
      L2_2 = tDBs
      L2_2 = L2_2[A0_2]
      L2_2 = L2_2.Rarity
      if L2_2 then
        L2_2 = tDBs
        L2_2 = L2_2[A0_2]
        L1_2 = L2_2.Rarity
      end
    end
    if not (L1_2 < 0) then
      L2_2 = L0_1
      L3_2 = L1_1
      if not (L2_2 >= L3_2) then
        L2_2 = tDBs
        L2_2 = L2_2[A0_2]
        if not L2_2 then
          goto lbl_75
        end
        L2_2 = tDBs
        L2_2 = L2_2[A0_2]
        L2_2 = L2_2.Active
        if not L2_2 then
          goto lbl_75
        end
      end
    end
    do return end
    ::lbl_75::
    L2_2 = math
    L2_2 = L2_2.randf
    L2_2 = L2_2()
    L3_2 = L1_1
    L2_2 = L2_2 * L3_2
    L2_2 = L2_2 * L1_2
    L3_2 = L1_1
    if L2_2 < L3_2 then
      L3_2 = TurnOnRandomDB
      L4_2 = A0_2
      L5_2 = false
      L3_2(L4_2, L5_2)
    else
    end
  end
end

Start = L5_1

function L5_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = tDBs
  L3_2 = tDBs
  L3_2 = L3_2[A0_2]
  if not L3_2 then
    L3_2 = {}
  end
  L2_2[A0_2] = L3_2
  L2_2 = Net
  L2_2 = L2_2.IsClient
  L2_2 = L2_2()
  if L2_2 then
    if not A1_2 then
      return
    else
    end
  else
    L2_2 = Net
    L2_2 = L2_2.IsServer
    L2_2 = L2_2()
    if L2_2 then
      L2_2 = Net
      L2_2 = L2_2.SendEvent_SetOccupiedDangerousBuilding
      L3_2 = A0_2
      L2_2(L3_2)
      L2_2 = tDBs
      L2_2 = L2_2[A0_2]
      L3_2 = Event
      L3_2 = L3_2.Create
      L4_2 = Event
      L4_2 = L4_2.ObjectHealth
      L5_2 = {}
      L6_2 = A0_2
      L7_2 = "<"
      L8_2 = Object
      L8_2 = L8_2.GetHealth
      L9_2 = A0_2
      L8_2, L9_2, L10_2, L11_2 = L8_2(L9_2)
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      L5_2[3] = L8_2
      L5_2[4] = L9_2
      L5_2[5] = L10_2
      L5_2[6] = L11_2
      L6_2 = TurnOn
      L7_2 = {}
      L8_2 = A0_2
      L9_2 = true
      L10_2 = false
      L11_2 = false
      L7_2[1] = L8_2
      L7_2[2] = L9_2
      L7_2[3] = L10_2
      L7_2[4] = L11_2
      L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
      L2_2.HealthEvent = L3_2
    end
  end
  L2_2 = tDBs
  L2_2 = L2_2[A0_2]
  L2_2 = L2_2.Blip
  if not L2_2 then
    L2_2 = tDBs
    L2_2 = L2_2[A0_2]
    L2_2.Blip = true
    L2_2 = Hud
    L2_2 = L2_2.Radar
    L3_2 = L2_2
    L2_2 = L2_2.AddObjective
    L4_2 = {}
    L5_2 = "db_"
    L6_2 = tostring
    L7_2 = A0_2
    L6_2 = L6_2(L7_2)
    L5_2 = L5_2 .. L6_2
    L4_2.sName = L5_2
    L4_2.nR = 170
    L4_2.nG = 170
    L4_2.nB = 170
    L4_2.nWidth = 8
    L4_2.nHeight = 8
    L4_2.sTexture = "temp_radar_icon_db"
    L4_2.uGuid = A0_2
    L4_2.bSticky = false
    L4_2.bDontNetSync = true
    L4_2.nSortOrder = 3
    L2_2(L3_2, L4_2)
  end
end

SetupOccupied = L5_1

function L5_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L4_2 = Net
  L4_2 = L4_2.IsClient
  L4_2 = L4_2()
  if L4_2 and not A3_2 then
    return
  end
  L4_2 = ConvertToTableOfGuids
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  L5_2 = pairs
  L6_2 = L4_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    if L9_2 then
      L10_2 = Object
      L10_2 = L10_2.IsAlive
      L11_2 = L9_2
      L10_2 = L10_2(L11_2)
      if L10_2 then
        L10_2 = tDBs
        L10_2 = L10_2[L9_2]
        if not L10_2 then
          goto lbl_34
        end
        L10_2 = tDBs
        L10_2 = L10_2[L9_2]
        L10_2 = L10_2.Active
        if L10_2 ~= true then
          goto lbl_34
        end
      end
    end
    do return end
    ::lbl_34::
    L10_2 = tDBs
    L11_2 = tDBs
    L11_2 = L11_2[L9_2]
    if not L11_2 then
      L11_2 = {}
    end
    L10_2[L9_2] = L11_2
    L10_2 = Net
    L10_2 = L10_2.IsClient
    L10_2 = L10_2()
    if L10_2 then
      L10_2 = tDBs
      L10_2 = L10_2[L9_2]
      L10_2.Permanent = A2_2
    else
      L10_2 = tDBs
      L10_2 = L10_2[L9_2]
      L11_2 = tDBs
      L11_2 = L11_2[L9_2]
      L11_2 = L11_2.Permanent
      if not L11_2 then
        L11_2 = A2_2
      end
      L10_2.Permanent = L11_2
    end
    L10_2 = tDBs
    L10_2 = L10_2[L9_2]
    L10_2.Active = true
    L10_2 = Ai
    L10_2 = L10_2.TweakAttachedSpawners
    L11_2 = L9_2
    L12_2 = {}
    L12_2.SpawnerState = "on"
    L10_2(L11_2, L12_2)
    if A1_2 then
      L10_2 = tDBs
      L10_2 = L10_2[L9_2]
      L10_2 = L10_2.Blip
      if L10_2 then
        L10_2 = Hud
        L10_2 = L10_2.Radar
        L11_2 = L10_2
        L10_2 = L10_2.RemoveObjective
        L12_2 = {}
        L13_2 = "db_"
        L14_2 = tostring
        L15_2 = L9_2
        L14_2 = L14_2(L15_2)
        L13_2 = L13_2 .. L14_2
        L12_2.sName = L13_2
        L12_2.bDontNetSync = true
        L10_2(L11_2, L12_2)
      end
      L10_2 = Hud
      L10_2 = L10_2.Radar
      L11_2 = L10_2
      L10_2 = L10_2.AddObjective
      L12_2 = {}
      L13_2 = "db_"
      L14_2 = tostring
      L15_2 = L9_2
      L14_2 = L14_2(L15_2)
      L13_2 = L13_2 .. L14_2
      L12_2.sName = L13_2
      L12_2.nR = 250
      L12_2.nG = 0
      L12_2.nB = 0
      L12_2.nWidth = 8
      L12_2.nHeight = 8
      L12_2.sTexture = "temp_radar_icon_dbactive"
      L12_2.uGuid = L9_2
      L12_2.bSticky = false
      L12_2.bDontNetSync = true
      L10_2(L11_2, L12_2)
      L10_2 = Hud
      L10_2 = L10_2.Radar
      L11_2 = L10_2
      L10_2 = L10_2.AnimateObjectiveSize
      L12_2 = {}
      L13_2 = "db_"
      L14_2 = tostring
      L15_2 = L9_2
      L14_2 = L14_2(L15_2)
      L13_2 = L13_2 .. L14_2
      L12_2.sName = L13_2
      L12_2.nDuration = 5
      L12_2.nMinWidth = 4
      L12_2.nMinHeight = 4
      L12_2.nMaxWidth = 12
      L12_2.nMaxHeight = 12
      L12_2.nSpeedWidth = 20
      L12_2.nSpeedHeight = 20
      L10_2(L11_2, L12_2)
      L10_2 = tDBs
      L10_2 = L10_2[L9_2]
      L10_2.Blip = true
    end
    L10_2 = Net
    L10_2 = L10_2.IsServer
    L10_2 = L10_2()
    if L10_2 and not A3_2 then
      L10_2 = Net
      L10_2 = L10_2.SendEvent_AddDangerousBuilding
      L11_2 = L9_2
      L12_2 = A1_2
      L13_2 = tDBs
      L13_2 = L13_2[L9_2]
      L13_2 = L13_2.Permanent
      L10_2(L11_2, L12_2, L13_2)
    end
  end
end

TurnOn = L5_1

function L5_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = tDBs
  if L1_2 ~= nil then
    L1_2 = tDBs
    L1_2 = L1_2[A0_2]
    if L1_2 ~= nil then
      L1_2 = tDBs
      L1_2 = L1_2[A0_2]
      L1_2 = L1_2.Blip
      if L1_2 then
        L1_2 = Hud
        L1_2 = L1_2.Radar
        L2_2 = L1_2
        L1_2 = L1_2.AnimateObjectiveAlpha
        L3_2 = {}
        L4_2 = "db_"
        L5_2 = tostring
        L6_2 = A0_2
        L5_2 = L5_2(L6_2)
        L4_2 = L4_2 .. L5_2
        L3_2.sName = L4_2
        L3_2.nDuration = 4
        L3_2.nMinAlpha = 0
        L3_2.nMaxAlpha = 1
        L3_2.nSpeed = 2
        L1_2(L2_2, L3_2)
      end
    end
  end
end

OccupiedBuildingSpawnCallback = L5_1

function L5_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = Net
  L2_2 = L2_2.IsClient
  L2_2 = L2_2()
  if L2_2 and not A1_2 then
    return
  end
  L2_2 = ConvertToTableOfGuids
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    if not L7_2 then
      return
    end
    L8_2 = tDBs
    L9_2 = tDBs
    L9_2 = L9_2[L7_2]
    if not L9_2 then
      L9_2 = {}
    end
    L8_2[L7_2] = L9_2
    L8_2 = tDBs
    L8_2 = L8_2[L7_2]
    L8_2.Active = true
    L8_2 = tDBs
    L8_2 = L8_2[L7_2]
    L8_2.Reward = 0
    L8_2 = Ai
    L8_2 = L8_2.TweakAttachedSpawners
    L9_2 = L7_2
    L10_2 = {}
    L10_2.SpawnerState = "on"
    L10_2.SpawnerType = "Once"
    L10_2.RadiusType = "RADIUS_PLAYER_2D"
    L10_2.ActiveRadius = 100
    L10_2.SkipPercentChange = 100
    L10_2.SpawnList = "Spawnlist (VZ Tower)"
    L8_2(L9_2, L10_2)
    L8_2 = Ai
    L8_2 = L8_2.TweakAttachedSpawnersInGroup
    L9_2 = L7_2
    L10_2 = "ground"
    L11_2 = {}
    L11_2.SpawnerState = "off"
    L8_2(L9_2, L10_2, L11_2)
    L8_2 = L0_1
    L8_2 = L8_2 + 1
    L0_1 = L8_2
    L8_2 = Net
    L8_2 = L8_2.IsServer
    L8_2 = L8_2()
    if L8_2 and not A1_2 then
      L8_2 = Net
      L8_2 = L8_2.SendEvent_AddRandomDangerousBuilding
      L9_2 = L7_2
      L8_2(L9_2)
    end
  end
end

TurnOnRandomDB = L5_1

function L5_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = tDBs
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = tDBs
    L1_2 = L1_2[A0_2]
    L1_2 = L1_2.Permanent
    if L1_2 then
      return
  end
  else
    L1_2 = RemoveDB
    L2_2 = A0_2
    L3_2 = false
    L4_2 = false
    L1_2(L2_2, L3_2, L4_2)
  end
  L1_2 = tDBs
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = tDBs
    L1_2 = L1_2[A0_2]
    L1_2 = L1_2.WakeEvent
    if L1_2 then
      L1_2 = Event
      L1_2 = L1_2.Delete
      L2_2 = tDBs
      L2_2 = L2_2[A0_2]
      L2_2 = L2_2.WakeEvent
      L1_2(L2_2)
      L1_2 = tDBs
      L1_2 = L1_2[A0_2]
      L1_2.WakeEvent = nil
    end
    L1_2 = tDBs
    L1_2 = L1_2[A0_2]
    L1_2 = L1_2.HealthEvent
    if L1_2 then
      L1_2 = Event
      L1_2 = L1_2.Delete
      L2_2 = tDBs
      L2_2 = L2_2[A0_2]
      L2_2 = L2_2.HealthEvent
      L1_2(L2_2)
      L1_2 = tDBs
      L1_2 = L1_2[A0_2]
      L1_2.HealthEvent = nil
    end
  end
end

OnDeactivate = L5_1

function L5_1(A0_2)
  local L1_2, L2_2
  L1_2 = RemoveDB
  L2_2 = A0_2.uGuid
  L1_2(L2_2)
end

Delete = L5_1

function L5_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = RemoveDB
  L2_2 = A0_2
  L3_2 = true
  L4_2 = false
  L1_2(L2_2, L3_2, L4_2)
end

OnDeath = L5_1

function L5_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = RemoveDB
  L2_2 = A0_2
  L3_2 = false
  L4_2 = false
  L1_2(L2_2, L3_2, L4_2)
end

ClearProperties = L5_1

function L5_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L3_2 = Net
  L3_2 = L3_2.IsClient
  L3_2 = L3_2()
  if L3_2 and not A2_2 then
    return
  end
  L3_2 = ConvertToTableOfGuids
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  L4_2 = pairs
  L5_2 = L3_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = tDBs
    L9_2 = L9_2[L8_2]
    if L9_2 then
      L9_2 = false
      L10_2 = tDBs
      L10_2 = L10_2[L8_2]
      L10_2 = L10_2.Blip
      if L10_2 then
        L9_2 = true
        L10_2 = Hud
        L10_2 = L10_2.Radar
        L11_2 = L10_2
        L10_2 = L10_2.RemoveObjective
        L12_2 = {}
        L13_2 = "db_"
        L14_2 = tostring
        L15_2 = L8_2
        L14_2 = L14_2(L15_2)
        L13_2 = L13_2 .. L14_2
        L12_2.sName = L13_2
        L12_2.bDontNetSync = true
        L10_2(L11_2, L12_2)
        L10_2 = tDBs
        L10_2 = L10_2[L8_2]
        L10_2.Blip = nil
      end
      L10_2 = tDBs
      L10_2 = L10_2[L8_2]
      L10_2 = L10_2.Active
      if L10_2 then
        L9_2 = true
        L10_2 = Ai
        L10_2 = L10_2.TweakAttachedSpawners
        L11_2 = L8_2
        L12_2 = {}
        L12_2.SpawnerState = "off"
        L10_2(L11_2, L12_2)
        L10_2 = L0_1
        L10_2 = L10_2 - 1
        L0_1 = L10_2
        if A1_2 then
          L10_2 = tDBs
          L10_2 = L10_2[L8_2]
          L10_2 = L10_2.Reward
          if not L10_2 then
            L10_2 = L4_1
          end
          if 0 < L10_2 then
            L11_2 = MrxGui
            L11_2 = L11_2.AddMessage
            L12_2 = {}
            L13_2 = "[green]Occupied building destroyed! +$"
            L14_2 = L10_2
            L13_2 = L13_2 .. L14_2
            L12_2.sText = L13_2
            L12_2.nDuration = 4
            L11_2(L12_2)
            L11_2 = MrxPmc
            L11_2 = L11_2.AddCashQty
            L12_2 = L10_2
            L13_2 = true
            L11_2(L12_2, L13_2)
          else
          end
          L11_2 = tDBs
          L11_2 = L11_2[L8_2]
          L11_2.Tweaked = nil
        end
        L10_2 = tDBs
        L10_2 = L10_2[L8_2]
        L10_2 = L10_2.Tweaked
        if L10_2 then
          L10_2 = tDBs
          L10_2 = L10_2[L8_2]
          L10_2.Active = nil
          L10_2 = tDBs
          L10_2 = L10_2[L8_2]
          L10_2.Blip = nil
        else
          L10_2 = tDBs
          L10_2[L8_2] = nil
        end
      end
      if L9_2 then
        L10_2 = Net
        L10_2 = L10_2.IsServer
        L10_2 = L10_2()
        if L10_2 and not A2_2 then
          L10_2 = Net
          L10_2 = L10_2.SendEvent_RemoveDangerousBuilding
          L11_2 = L8_2
          L12_2 = A1_2
          L10_2(L11_2, L12_2)
        end
      end
    end
  end
end

RemoveDB = L5_1

function L5_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = RemoveDB
  L1_2 = tDBs
  L2_2 = false
  L3_2 = true
  L0_2(L1_2, L2_2, L3_2)
end

RemoveAllDBs = L5_1

function L5_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = tDBs
  if L0_2 then
    L0_2 = pairs
    L1_2 = tDBs
    L0_2, L1_2, L2_2 = L0_2(L1_2)
    for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    end
  else
  end
end

GetAllDBs = L5_1

function L5_1(A0_2)
  local L1_2
  if A0_2 then
    L1_2 = tDBs
    L1_2 = L1_2[A0_2]
    if L1_2 then
      L1_2 = tDBs
      L1_2 = L1_2[A0_2]
      L1_2 = L1_2.Rarity
      return L1_2
  end
  else
    L1_2 = L3_1
    return L1_2
  end
end

GetRarity = L5_1

function L5_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  if not A0_2 or not A1_2 then
    return
  end
  L2_2 = ConvertToTableOfGuids
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = ProcessProperties
    L9_2 = L7_2
    L10_2 = A1_2
    L8_2(L9_2, L10_2)
  end
end

SetProperties = L5_1

function L5_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if L2_2 == "string" then
    L2_2 = Pg
    L2_2 = L2_2.GetGuidByName
    L3_2 = A1_2
    L2_2 = L2_2(L3_2)
    A1_2 = L2_2
  end
  if A1_2 then
    L2_2 = table
    L2_2 = L2_2.insert
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  end
end

_Process = L5_1

function L5_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = {}
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 == "table" then
    L2_2 = pairs
    L3_2 = A0_2
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2, L6_2 in L2_2, L3_2, L4_2 do
      L7_2 = _Process
      L8_2 = L1_2
      L9_2 = L6_2
      L7_2(L8_2, L9_2)
    end
  else
    L2_2 = _Process
    L3_2 = L1_2
    L4_2 = A0_2
    L2_2(L3_2, L4_2)
  end
  return L1_2
end

ConvertToTableOfGuids = L5_1

function L5_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = Object
  L2_2 = L2_2.IsAlive
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L2_2 = tDBs
  L3_2 = tDBs
  L3_2 = L3_2[A0_2]
  if not L3_2 then
    L3_2 = {}
  end
  L2_2[A0_2] = L3_2
  L2_2 = A1_2.Density
  if L2_2 then
    L2_2 = math
    L2_2 = L2_2.ceil
    L3_2 = A1_2.Density
    L2_2 = L2_2(L3_2)
    A1_2.Density = L2_2
    L2_2 = math
    L2_2 = L2_2.min
    L3_2 = 100
    L4_2 = A1_2.Density
    L2_2 = L2_2(L3_2, L4_2)
    A1_2.Density = L2_2
    L2_2 = math
    L2_2 = L2_2.max
    L3_2 = 0
    L4_2 = A1_2.Density
    L2_2 = L2_2(L3_2, L4_2)
    A1_2.Density = L2_2
    L2_2 = A1_2.Density
    L2_2 = 100 - L2_2
    A1_2.ChanceNotActive = L2_2
    L2_2 = A1_2.Density
    L2_2 = 100 - L2_2
    A1_2.SkipPercentChance = L2_2
  end
  L2_2 = A1_2.Faction
  if L2_2 then
    L2_2 = SetFaction
    L3_2 = A0_2
    L4_2 = A1_2.Faction
    L2_2(L3_2, L4_2)
  end
  L2_2 = tDBs
  L2_2 = L2_2[A0_2]
  L3_2 = A1_2.Reward
  L2_2.Reward = L3_2
  L2_2 = A1_2.Rarity
  if L2_2 then
    L2_2 = SetRarity
    L3_2 = A0_2
    L4_2 = A1_2.Rarity
    L2_2(L3_2, L4_2)
  end
  L2_2 = A1_2.WakeupFunction
  if L2_2 then
    L2_2 = SetWakeupFunction
    L3_2 = A0_2
    L4_2 = A1_2.WakeupFunction
    L2_2(L3_2, L4_2)
  end
  L2_2 = A1_2.Group
  if L2_2 then
    L2_2 = Ai
    L2_2 = L2_2.TweakAttachedSpawnersInGroup
    L3_2 = A0_2
    L4_2 = A1_2.Group
    L5_2 = A1_2
    L2_2(L3_2, L4_2, L5_2)
  else
    L2_2 = Ai
    L2_2 = L2_2.TweakAttachedSpawners
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  end
  L2_2 = A1_2.Properties
  if L2_2 then
    L2_2 = tDBs
    L2_2 = L2_2[A0_2]
    L2_2.Tweaked = true
  end
  L2_2 = tDBs
  L2_2 = L2_2[A0_2]
  L2_2.Properties = A1_2
  L2_2 = tDBs
  L2_2 = L2_2[A0_2]
  L2_2 = L2_2.Properties
  L2_2.Properties = nil
end

ProcessProperties = L5_1

function L5_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = ConvertToTableOfGuids
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = string
    L8_2 = L8_2.lower
    L9_2 = A1_2
    L8_2 = L8_2(L9_2)
    A1_2 = L8_2
    if not L7_2 or not A1_2 then
    else
      L8_2 = tDBs
      L9_2 = tDBs
      L9_2 = L9_2[L7_2]
      if not L9_2 then
        L9_2 = {}
      end
      L8_2[L7_2] = L9_2
      L8_2 = tDBs
      L8_2 = L8_2[L7_2]
      L8_2.Faction = A1_2
      L8_2 = tDBs
      L8_2 = L8_2[L7_2]
      L8_2.Tweaked = true
      L8_2 = SetDBFaction
      L9_2 = L7_2
      L10_2 = A1_2
      L11_2 = tDBs
      L11_2 = L11_2[L7_2]
      L8_2(L9_2, L10_2, L11_2)
    end
  end
end

SetFaction = L5_1

function L5_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = ConvertToTableOfGuids
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    if not L7_2 or not A1_2 then
    else
      L8_2 = tDBs
      L9_2 = tDBs
      L9_2 = L9_2[L7_2]
      if not L9_2 then
        L9_2 = {}
      end
      L8_2[L7_2] = L9_2
      L8_2 = tDBs
      L8_2 = L8_2[L7_2]
      L8_2.WakeupFunc = A1_2
      L8_2 = tDBs
      L8_2 = L8_2[L7_2]
      L8_2.Tweaked = true
    end
  end
end

SetWakeupFunction = L5_1

function L5_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  if A1_2 then
    L2_2 = string
    L2_2 = L2_2.lower
    L3_2 = A1_2
    L2_2 = L2_2(L3_2)
    if L2_2 == "never" then
      A1_2 = -1
  end
  elseif A1_2 then
    L2_2 = string
    L2_2 = L2_2.lower
    L3_2 = A1_2
    L2_2 = L2_2(L3_2)
    if L2_2 == "always" then
      A1_2 = 0
    end
  end
  if A1_2 == "default" then
    A1_2 = L2_1
  end
  if A0_2 == "default" or A0_2 == "all" or A0_2 == "global" then
    L2_2 = A1_2 or L2_2
    if not A1_2 then
      L2_2 = L2_1
    end
    L3_1 = L2_2
    L2_2 = L3_1
    if L2_2 < 0 then
    end
    return
  end
  L2_2 = ConvertToTableOfGuids
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = tDBs
    L9_2 = tDBs
    L9_2 = L9_2[L7_2]
    if not L9_2 then
      L9_2 = {}
    end
    L8_2[L7_2] = L9_2
    L8_2 = tDBs
    L8_2 = L8_2[L7_2]
    L8_2.Rarity = A1_2
    L8_2 = tDBs
    L8_2 = L8_2[L7_2]
    L8_2.Tweaked = true
  end
end

SetRarity = L5_1

function L5_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L3_2 = type
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if L3_2 == "string" then
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
    A0_2 = L3_2
  end
  if not A0_2 or not A1_2 then
    return
  end
  L3_2 = {}
  L3_2.Ground = "Ground"
  L3_2.Balcony = "Balcony"
  L3_2.AA = "AA"
  L3_2.Window = "Balcony"
  L3_2.RoofTop = "Balcony"
  L4_2 = pairs
  L5_2 = L3_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = tostring
    L10_2 = "SpawnList ("
    L11_2 = A1_2
    L12_2 = " "
    L13_2 = L8_2
    L14_2 = ")"
    L10_2 = L10_2 .. L11_2 .. L12_2 .. L13_2 .. L14_2
    L9_2 = L9_2(L10_2)
    if A2_2 then
      L10_2 = A2_2.SpawnList
      if L10_2 then
        L10_2 = A2_2.Group
        if L10_2 then
          L10_2 = A2_2.Group
          if L10_2 ~= L7_2 then
            goto lbl_46
          end
        end
        L9_2 = A2_2.SpawnList
      end
    end
    ::lbl_46::
    L10_2 = Ai
    L10_2 = L10_2.TweakAttachedSpawnersInGroup
    L11_2 = A0_2
    L12_2 = L7_2
    L13_2 = {}
    L13_2.SpawnList = L9_2
    L10_2(L11_2, L12_2, L13_2)
  end
end

SetDBFaction = L5_1
