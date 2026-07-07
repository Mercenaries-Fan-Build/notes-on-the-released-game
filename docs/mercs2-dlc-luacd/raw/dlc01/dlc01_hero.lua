local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1
L0_1 = import
L1_1 = "MrxGui"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxSound"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxUtil"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxPmc"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "WifEquipmentData"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxParkingLotManager"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = {}
tEvent = L0_1
L0_1 = 7.5
L1_1 = 4
L2_1 = 0
L3_1 = 0.03
L4_1 = 2
L5_1 = 2.5
L6_1 = 0.3
L7_1 = {}
L8_1 = {}
L9_1 = 10
L10_1 = 0
L11_1 = 3
L12_1 = 100
L13_1 = 1
L14_1 = 0.45

function L15_1()
  local L0_2, L1_2
  L0_2 = MrxParkingLotManager
  L0_2 = L0_2.Setup
  L0_2()
end

Init = L15_1

function L15_1()
  local L0_2, L1_2
  L0_2 = MrxParkingLotManager
  L0_2 = L0_2.Cleanup
  L0_2()
end

Deinit = L15_1

function L15_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.ObjectHibernation
  L3_2 = {}
  L4_2 = A0_2
  L5_2 = "awake"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L4_2 = Activate
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

OnActivate = L15_1

function L15_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Object
  L1_2 = L1_2.IsPlayerControlled
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L2_2 = Player
    L2_2 = L2_2.IsLocal
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = GetAttribute
      L3_2 = A0_2
      L4_2 = "attitude"
      L2_2 = L2_2(L3_2, L4_2)
      if 2 < L2_2 then
        L2_2 = L3_1
        L2_2 = L2_2 * 1.5
        L2_1 = L2_2
        L2_2 = L11_1
        L2_2 = L2_2 * 1.5
        L10_1 = L2_2
      else
        L2_2 = L3_1
        L2_1 = L2_2
        L2_2 = L11_1
        L10_1 = L2_2
      end
      L2_2 = tEvent
      L3_2 = tEvent
      L3_2 = L3_2[A0_2]
      if not L3_2 then
        L3_2 = {}
      end
      L2_2[A0_2] = L3_2
      L2_2 = SetupSurvivalSystem
      L3_2 = L1_2
      L4_2 = A0_2
      L5_2 = true
      L2_2(L3_2, L4_2, L5_2)
      L2_2 = SetupInventory
      L3_2 = A0_2
      L2_2(L3_2)
      L2_2 = SetupTransferSystem
      L3_2 = L1_2
      L4_2 = A0_2
      L2_2(L3_2, L4_2)
    else
    end
  end
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 3
  L4_2[1] = L5_2
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = Gui
    L0_3 = L0_3.SetPickupMarkerVisibleDistance
    L1_3 = 20
    L2_3 = false
    L0_3(L1_3, L2_3)
    L0_3 = Gui
    L0_3 = L0_3.SetPickupMarkerSize
    L1_3 = 18
    L2_3 = false
    L0_3(L1_3, L2_3)
    L0_3 = Gui
    L0_3 = L0_3.SetPickupMarkerSize
    L1_3 = 18
    L2_3 = true
    L0_3(L1_3, L2_3)
  end
  
  L2_2(L3_2, L4_2, L5_2)
end

Activate = L15_1

function L15_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Object
  L1_2 = L1_2.IsPlayerControlled
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L2_2 = Player
    L2_2 = L2_2.IsLocal
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    if not L2_2 then
      return
    end
  else
    return
  end
  L2_2 = CleanupSurvival
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = MrxSound
  L2_2 = L2_2.EndSurvivalMode
  L2_2()
  L2_2 = tEvent
  L2_2 = L2_2[A0_2]
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectHealth
  L5_2 = {}
  L6_2 = A0_2
  L7_2 = ">"
  L8_2 = 5
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L6_2 = SetupSurvivalSystem
  L7_2 = {}
  L8_2 = L1_2
  L9_2 = A0_2
  L10_2 = true
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2.FullHealth = L3_2
end

OnDeath = L15_1

function L15_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Object
  L1_2 = L1_2.IsPlayerControlled
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    return
  end
  L2_2 = Player
  L2_2 = L2_2.IsLocal
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L2_2 = SaveOutInventory
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = CleanupSurvival
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = CleanupTransferSystem
  L3_2 = L1_2
  L4_2 = A0_2
  L2_2(L3_2, L4_2)
end

OnDeactivate = L15_1

function L15_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Human
  L1_2 = L1_2.Inventory
  L1_2 = L1_2.GetAllWeapons
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = Weapon
    L7_2 = L7_2.GetMaxReserveAmmo
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    if L7_2 then
      L8_2 = Weapon
      L8_2 = L8_2.SetReserveAmmo
      L9_2 = L6_2
      L10_2 = L7_2
      L8_2(L9_2, L10_2)
    end
  end
end

SetupInventory = L15_1

function L15_1(A0_2)
  local L1_2, L2_2
  L1_2 = Human
  L1_2 = L1_2.Inventory
  L1_2 = L1_2.GetAllWeapons
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
end

SaveOutInventory = L15_1

function L15_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = tEvent
  L2_2 = L2_2[A0_2]
  L2_2 = L2_2.Timer
  L1_2(L2_2)
  L1_2 = tEvent
  L1_2 = L1_2[A0_2]
  L1_2.Timer = nil
  L1_2 = Object
  L1_2 = L1_2.IsPlayerControlled
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = Object
  L2_2 = L2_2.GetHealth
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = L7_1
  L3_2 = L3_2[L1_2]
  if L3_2 then
    L3_2 = CreateHealTimer
    L4_2 = A0_2
    L5_2 = L1_1
    L3_2(L4_2, L5_2)
  else
    L3_2 = L9_1
    if L2_2 < L3_2 then
      L3_2 = tEvent
      L3_2 = L3_2[A0_2]
      L3_2 = L3_2.Cooldown
      if not L3_2 then
        L3_2 = StartSurvivalMode
        L4_2 = L1_2
        L5_2 = A0_2
        L3_2(L4_2, L5_2)
    end
    else
      L3_2 = tEvent
      L3_2 = L3_2[A0_2]
      L3_2 = L3_2.Cooldown
      if L3_2 then
      else
        L3_2 = CreateHealTimer
        L4_2 = A0_2
        L5_2 = L0_1
        L3_2(L4_2, L5_2)
      end
    end
  end
  L3_2 = CreateDropEvent
  L4_2 = A0_2
  L3_2(L4_2)
end

HealthDropped = L15_1

function L15_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Object
  L1_2 = L1_2.GetHealth
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = Object
  L2_2 = L2_2.GetMaxHealth
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L1_2 then
    return
  end
  L3_2 = L2_2 - L1_2
  L4_2 = L2_1
  L3_2 = L3_2 * L4_2
  L4_2 = Object
  L4_2 = L4_2.InSeat
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if L4_2 then
    L4_2 = L4_1
    L3_2 = L3_2 * L4_2
  end
  L4_2 = Math
  L4_2 = L4_2.max
  L5_2 = L5_1
  L5_2 = L5_2 / L3_2
  L6_2 = L6_1
  L4_2 = L4_2(L5_2, L6_2)
  L5_2 = Math
  L5_2 = L5_2.max
  L6_2 = L3_2
  L7_2 = 1
  L5_2 = L5_2(L6_2, L7_2)
  L3_2 = L5_2
  L5_2 = Object
  L5_2 = L5_2.SetHealth
  L6_2 = A0_2
  L7_2 = Math
  L7_2 = L7_2.min
  L8_2 = L1_2 + L3_2
  L9_2 = L2_2
  L7_2, L8_2, L9_2 = L7_2(L8_2, L9_2)
  L5_2(L6_2, L7_2, L8_2, L9_2)
  if L1_2 < L2_2 then
    L5_2 = CreateHealTimer
    L6_2 = A0_2
    L7_2 = L4_2
    L5_2(L6_2, L7_2)
  end
  L5_2 = Object
  L5_2 = L5_2.IsPlayerControlled
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  L6_2 = L7_1
  L6_2 = L6_2[L5_2]
  if L6_2 then
    L6_2 = L9_1
    if L1_2 >= L6_2 then
      L6_2 = EndSurvivalMode
      L7_2 = L5_2
      L8_2 = A0_2
      L6_2(L7_2, L8_2)
    end
  end
  L6_2 = CreateDropEvent
  L7_2 = A0_2
  L6_2(L7_2)
end

Heal = L15_1

function L15_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = Event
  L2_2 = L2_2.Delete
  L3_2 = tEvent
  L3_2 = L3_2[A0_2]
  L3_2 = L3_2.Timer
  L2_2(L3_2)
  L2_2 = tEvent
  L2_2 = L2_2[A0_2]
  L2_2.Timer = nil
  L2_2 = tEvent
  L2_2 = L2_2[A0_2]
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = A1_2
  L5_2[1] = L6_2
  L6_2 = Heal
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2.Timer = L3_2
  L2_2 = Object
  L2_2 = L2_2.IsPlayerControlled
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
end

CreateHealTimer = L15_1

function L15_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = tEvent
  L2_2 = L2_2[A0_2]
  L2_2 = L2_2.HealthDropped
  L1_2(L2_2)
  L1_2 = tEvent
  L1_2 = L1_2[A0_2]
  L1_2.HealthDropped = nil
  L1_2 = tEvent
  L1_2 = L1_2[A0_2]
  L2_2 = Event
  L2_2 = L2_2.CreatePersistent
  L3_2 = Event
  L3_2 = L3_2.ObjectHealth
  L4_2 = {}
  L5_2 = A0_2
  L6_2 = "<"
  L7_2 = Object
  L7_2 = L7_2.GetHealth
  L8_2 = A0_2
  L7_2, L8_2 = L7_2(L8_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = HealthDropped
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.HealthDropped = L2_2
end

CreateDropEvent = L15_1

function L15_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Object
  L1_2 = L1_2.IsPlayerControlled
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    L2_2 = CleanEvents
    L3_2 = tEvent
    L3_2 = L3_2[A0_2]
    L2_2(L3_2)
    return
  end
  L2_2 = tEvent
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L2_2 = tEvent
    L2_2 = L2_2[A0_2]
    L2_2 = L2_2.Cooldown
    if L2_2 then
      L2_2 = SurvivalCooldownEnded
      L3_2 = L1_2
      L4_2 = A0_2
      L2_2(L3_2, L4_2)
    end
  end
  L2_2 = MrxGui
  L2_2 = L2_2.FadeFromColor
  L3_2 = 0
  L4_2 = L1_2
  L2_2(L3_2, L4_2)
  L2_2 = CleanEvents
  L3_2 = tEvent
  L3_2 = L3_2[A0_2]
  L2_2(L3_2)
end

CleanupSurvival = L15_1

function L15_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 ~= "table" then
    return
  end
  L1_2 = pairs
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = type
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    if L6_2 == "table" then
      L6_2 = CleanEvents
      L7_2 = L5_2
      L6_2(L7_2)
    else
      L6_2 = Event
      L6_2 = L6_2.Delete
      L7_2 = L5_2
      L6_2(L7_2)
    end
  end
end

CleanEvents = L15_1

function L15_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  L3_2 = L7_1
  L3_2[A0_2] = false
  L3_2 = Player
  L3_2 = L3_2.SetSurvivalMode
  L4_2 = A0_2
  L5_2 = false
  L3_2(L4_2, L5_2)
  L3_2 = Player
  L3_2 = L3_2.SetHealthClamp
  L4_2 = A0_2
  L5_2 = true
  L3_2(L4_2, L5_2)
  if A2_2 then
    L3_2 = HealthDropped
    L4_2 = A1_2
    L3_2(L4_2)
  end
end

SetupSurvivalSystem = L15_1

function L15_1(A0_2, A1_2, A2_2)
end

SurvivalModeCallback = L15_1

function L15_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  L3_2 = SetupSurvivalSystem
  L4_2 = A0_2
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
  L3_2 = type
  L4_2 = A2_2
  L3_2 = L3_2(L4_2)
  if "number" ~= L3_2 then
    A2_2 = 2
  end
  L3_2 = MrxGui
  L3_2 = L3_2.FadeFromColor
  L4_2 = A2_2
  L5_2 = A0_2
  L3_2(L4_2, L5_2)
  L3_2 = MrxSound
  L3_2 = L3_2.EndSurvivalMode
  L3_2()
end

EndSurvivalMode = L15_1

function L15_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = " --> Called from HealthDropped"
  if A2_2 then
    L3_2 = " --> Callback function"
  end
  L4_2 = tEvent
  L4_2 = L4_2[A1_2]
  if L4_2 then
    L4_2 = tEvent
    L4_2 = L4_2[A1_2]
    L4_2 = L4_2.Cooldown
    if L4_2 then
      goto lbl_18
    end
  end
  L4_2 = L7_1
  L4_2 = L4_2[A0_2]
  ::lbl_18::
  if L4_2 then
    return
  end
  L4_2 = Event
  L4_2 = L4_2.Post
  L5_2 = "SurvivalMode"
  L6_2 = {}
  L7_2 = A1_2
  L6_2[1] = L7_2
  L4_2(L5_2, L6_2)
  if not A1_2 then
    L4_2 = Player
    L4_2 = L4_2.GetCharacter
    L5_2 = A0_2
    L4_2 = L4_2(L5_2)
    A1_2 = L4_2
  end
  L4_2 = MrxGui
  L4_2 = L4_2.FadeToColor
  L5_2 = 0.3
  L6_2 = A0_2
  L7_2 = 255
  L8_2 = 0
  L9_2 = 0
  L10_2 = L12_1
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  L4_2 = Object
  L4_2 = L4_2.SetInvincible
  L5_2 = A1_2
  L6_2 = true
  L7_2 = "Survival"
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = tEvent
  L4_2 = L4_2[A1_2]
  L5_2 = Event
  L5_2 = L5_2.CreatePersistent
  L6_2 = Event
  L6_2 = L6_2.TimerRelative
  L7_2 = {}
  L8_2 = L10_1
  L7_2[1] = L8_2
  L8_2 = SurvivalCooldownEnded
  L9_2 = {}
  L10_2 = A0_2
  L11_2 = A1_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L4_2.Cooldown = L5_2
  L4_2 = MrxSound
  L4_2 = L4_2.BeginSurvivalMode
  L4_2()
end

StartSurvivalMode = L15_1

function L15_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = Event
  L2_2 = L2_2.Delete
  L3_2 = tEvent
  L3_2 = L3_2[A1_2]
  L3_2 = L3_2.Cooldown
  L2_2(L3_2)
  L2_2 = tEvent
  L2_2 = L2_2[A1_2]
  L2_2.Cooldown = nil
  L2_2 = L7_1
  L2_2[A0_2] = true
  L2_2 = Object
  L2_2 = L2_2.SetInvincible
  L3_2 = A1_2
  L4_2 = false
  L5_2 = "Survival"
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = Player
  L2_2 = L2_2.SetSurvivalMode
  L3_2 = A0_2
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = Player
  L2_2 = L2_2.SetHealthClamp
  L3_2 = A0_2
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = MrxGui
  L2_2 = L2_2.FadeFromColor
  L3_2 = 3
  L4_2 = A0_2
  L2_2(L3_2, L4_2)
  L2_2 = Event
  L2_2 = L2_2.Post
  L3_2 = "SurvivalCooldownEnded"
  L4_2 = {}
  L5_2 = A1_2
  L4_2[1] = L5_2
  L2_2(L3_2, L4_2)
  L2_2 = CreateHealTimer
  L3_2 = A1_2
  L4_2 = L1_1
  L2_2(L3_2, L4_2)
  L2_2 = tEvent
  L2_2 = L2_2[A1_2]
  L3_2 = L14_1
  L2_2.nTimeScale = L3_2
end

SurvivalCooldownEnded = L15_1

function L15_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  do return end
  L2_2 = Object
  L2_2 = L2_2.GetHealth
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  L3_2 = L9_1
  L3_2 = L2_2 / L3_2
  L4_2 = L14_1
  L4_2 = 1 - L4_2
  L3_2 = L3_2 * L4_2
  L4_2 = L14_1
  L3_2 = L3_2 + L4_2
  L4_2 = Sys
  L4_2 = L4_2.SetTimeScale
  L5_2 = Math
  L5_2 = L5_2.min
  L6_2 = L3_2
  L7_2 = L13_1
  L5_2, L6_2, L7_2 = L5_2(L6_2, L7_2)
  L4_2(L5_2, L6_2, L7_2)
end

SetTimeScale = L15_1

function L15_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = nRiders
  if not L1_2 then
    L1_2 = 0
  end
  nRiders = L1_2
  L1_2 = nRiders
  L1_2 = L1_2 + 1
  nRiders = L1_2
  L1_2 = uRiderEvent
  if L1_2 then
    return
  end
  L1_2 = Event
  L1_2 = L1_2.CreatePersistent
  L2_2 = Event
  L2_2 = L2_2.ObjectInSeat
  L3_2 = {}
  L4_2 = Player
  L4_2 = L4_2.GetLocalCharacter
  L4_2 = L4_2()
  L5_2 = 0
  L6_2 = "pg"
  L7_2 = "e"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L4_2 = EnterPassengerCallback
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  uRiderEvent = L1_2
end

SetupTransferSystem = L15_1

function L15_1(A0_2)
  local L1_2, L2_2
  L1_2 = nRiders
  if L1_2 then
    L1_2 = uRiderEvent
    if L1_2 then
      goto lbl_8
    end
  end
  do return end
  ::lbl_8::
  L1_2 = nRiders
  L1_2 = L1_2 - 1
  nRiders = L1_2
  L1_2 = nRiders
  if L1_2 == 0 then
    L1_2 = uRiderEvent
    if L1_2 then
      L1_2 = Event
      L1_2 = L1_2.Delete
      L2_2 = uRiderEvent
      L1_2(L2_2)
      L1_2 = nil
      uRiderEvent = L1_2
      L1_2 = nil
      nRiders = L1_2
    end
  end
end

CleanupTransferSystem = L15_1

function L15_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L4_2 = Vehicle
  L4_2 = L4_2.GetDriver
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  if L4_2 == A0_2 then
    return
  end
  L5_2 = Vehicle
  L5_2 = L5_2.IsSeatALadder
  L6_2 = A3_2
  L5_2 = L5_2(L6_2)
  if L5_2 then
    return
  end
  if L4_2 then
    L5_2 = Object
    L5_2 = L5_2.IsPlayerControlled
    L6_2 = L4_2
    L5_2 = L5_2(L6_2)
    if L5_2 then
      return
    end
    L5_2 = Object
    L5_2 = L5_2.HasLabel
    L6_2 = A1_2
    L7_2 = "Car"
    L5_2 = L5_2(L6_2, L7_2)
    if not L5_2 then
      L5_2 = Object
      L5_2 = L5_2.HasLabel
      L6_2 = A1_2
      L7_2 = "Truck"
      L5_2 = L5_2(L6_2, L7_2)
      if not L5_2 then
        return
      end
    end
    if A2_2 == "gunner" then
      L5_2 = Ai
      L5_2 = L5_2.GetRelation
      L6_2 = A0_2
      L7_2 = L4_2
      L5_2 = L5_2(L6_2, L7_2)
      if 0 <= L5_2 then
        return
      end
    end
  elseif A2_2 == "gunner" then
    return
  end
  L5_2 = Vehicle
  L5_2 = L5_2.GetSeatByType
  L6_2 = A1_2
  L7_2 = "d"
  L5_2 = L5_2(L6_2, L7_2)
  if L5_2 then
    L6_2 = Vehicle
    L6_2 = L6_2.IsSeatBlocked
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    if not L6_2 then
      goto lbl_67
    end
  end
  do return end
  ::lbl_67::
  L6_2 = Vehicle
  L6_2 = L6_2.GetSeatFromRider
  L7_2 = A0_2
  L6_2 = L6_2(L7_2)
  L7_2 = Vehicle
  L7_2 = L7_2.GetSeatToSeat
  L8_2 = L6_2
  L9_2 = false
  L7_2 = L7_2(L8_2, L9_2)
  L8_2 = false
  if L7_2 then
    L9_2 = ipairs
    L10_2 = L7_2
    L9_2, L10_2, L11_2 = L9_2(L10_2)
    for L12_2, L13_2 in L9_2, L10_2, L11_2 do
      if L13_2 == L5_2 then
        L8_2 = true
        break
      end
    end
  end
  if not L8_2 then
    return
  end
  if L4_2 then
    L9_2 = Vehicle
    L9_2 = L9_2.Exit
    L10_2 = A1_2
    L11_2 = L4_2
    L12_2 = false
    L9_2(L10_2, L11_2, L12_2)
    L9_2 = Event
    L9_2 = L9_2.Create
    L10_2 = Event
    L10_2 = L10_2.ObjectInSeat
    L11_2 = {}
    L12_2 = L4_2
    L13_2 = 0
    L14_2 = "a"
    L15_2 = "x"
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L11_2[3] = L14_2
    L11_2[4] = L15_2
    L12_2 = Vehicle
    L12_2 = L12_2.TransferToSeat
    L13_2 = {}
    L14_2 = A0_2
    L15_2 = L5_2
    L16_2 = false
    L13_2[1] = L14_2
    L13_2[2] = L15_2
    L13_2[3] = L16_2
    L9_2(L10_2, L11_2, L12_2, L13_2)
  else
    L9_2 = Vehicle
    L9_2 = L9_2.TransferToSeat
    L10_2 = A0_2
    L11_2 = L5_2
    L12_2 = false
    L9_2(L10_2, L11_2, L12_2)
  end
end

EnterPassengerCallback = L15_1

function L15_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  if not A0_2 or not A1_2 then
    return
  end
  L2_2 = Player
  L2_2 = L2_2.GetCharacter
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  A0_2 = L2_2 or A0_2
  if not L2_2 then
  end
  L2_2 = Object
  L2_2 = L2_2.IsPlayerControlled
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L2_2 = nil
  L3_2 = 1
  L4_2 = 3
  L5_2 = 1
  for L6_2 = L3_2, L4_2, L5_2 do
    L7_2 = Object
    L7_2 = L7_2.HasLabel
    L8_2 = A0_2
    L9_2 = tostring
    L10_2 = A1_2
    L11_2 = L6_2
    L10_2 = L10_2 .. L11_2
    L9_2, L10_2, L11_2 = L9_2(L10_2)
    L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
    if L7_2 then
      L2_2 = L6_2
    end
    L6_2 = L6_2 + 1
  end
  if not L2_2 then
    L2_2 = 2
  end
  return L2_2
end

GetAttribute = L15_1
L15_1 = nil
_uHideMessage = L15_1

function L15_1()
  local L0_2, L1_2
  L0_2 = type
  L1_2 = _uHideMessage
  L0_2 = L0_2(L1_2)
  if L0_2 == "userdata" then
    L0_2 = MrxTutorialManager
    L0_2 = L0_2.HideMessage
    L1_2 = true
    L0_2(L1_2)
    L0_2 = Event
    L0_2 = L0_2.Delete
    L1_2 = _uHideMessage
    L0_2(L1_2)
  end
  L0_2 = nil
  _uHideMessage = L0_2
end

HideTutorialMessage = L15_1

function L15_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.TimerRelative
  L2_2 = {}
  L3_2 = 5
  L2_2[1] = L3_2
  L3_2 = HideTutorialMessage
  L4_2 = {}
  L0_2 = L0_2(L1_2, L2_2, L3_2, L4_2)
  _uHideMessage = L0_2
end

TutorialCueCallback = L15_1

function L15_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = _uHideMessage
  if not L1_2 then
    L1_2 = MrxPmc
    L1_2 = L1_2.HasEquipment
    L2_2 = "GrapplingHook"
    L1_2 = L1_2(L2_2)
    if not L1_2 then
      L1_2 = "[Tutorial.Grapple.Key1]"
      L2_2 = MrxTutorialManager
      L2_2 = L2_2.ShowMessage
      L3_2 = L1_2
      L4_2 = true
      L2_2 = L2_2(L3_2, L4_2)
      if L2_2 then
        L2_2 = MrxUtil
        L2_2 = L2_2.GetCharacterIdentity
        L3_2 = A0_2
        L2_2 = L2_2(L3_2)
        L3_2 = {}
        L3_2.mattias = "Mattias.Grapple01"
        L3_2.jennifer = "Jen.Grapple"
        L3_2.chris = "Chris.Grapple01"
        CueTable = L3_2
        L3_2 = MrxVoSequence
        L3_2 = L3_2.Start
        L4_2 = {}
        L5_2 = {}
        L6_2 = CueTable
        L6_2 = L6_2[L2_2]
        L7_2 = A0_2
        L5_2[1] = L6_2
        L5_2[2] = L7_2
        L6_2 = TutorialCueCallback
        L4_2[1] = L5_2
        L4_2[2] = L6_2
        L5_2 = nil
        L6_2 = MrxVoSequence
        L6_2 = L6_2.knPriorityFreeplay
        L3_2(L4_2, L5_2, L6_2)
        L3_2 = "InValid"
        _uHideMessage = L3_2
      end
    end
  end
end

DisableGrappleTriggered = L15_1
