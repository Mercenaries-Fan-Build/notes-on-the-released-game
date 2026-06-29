local L0_1, L1_1, L2_1
L0_1 = import
L1_1 = "MrxTutorialManager"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "DlcCon001"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxUtil"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxGuiBase"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = nil
uVehicle = L0_1
L0_1 = 0
nMaxSpeed = L0_1
L0_1 = 0
nMinSpeedAsPercent = L0_1
L0_1 = 0
nReactorHealthSlot = L0_1
L0_1 = 0
nSpeedTraySlot = L0_1
L0_1 = 0
L1_1 = 0
L2_1 = 0
nLastZ = L2_1
nLastY = L1_1
nLastX = L0_1
L0_1 = 0
nHeading = L0_1
L0_1 = 0
nReactorHealth = L0_1
L0_1 = 0
nBaseReactorHealth = L0_1
L0_1 = 0
nHealthLoss = L0_1
L0_1 = false
bTimerActive = L0_1
L0_1 = false
bInitialRed = L0_1
L0_1 = false
bInitialYellow = L0_1
L0_1 = false
bRedSparks = L0_1
L0_1 = nil
eEffect = L0_1
L0_1 = true
eMaterialAnimation = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = A0_2.uVehicle
  uVehicle = L1_2
  L1_2 = Event
  L1_2 = L1_2.CreatePersistent
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 0.1
  L3_2[1] = L4_2
  L4_2 = UpdateSpeed
  L5_2 = {}
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  evSpeed = L1_2
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.ObjectDeath
  L3_2 = {}
  L4_2 = uVehicle
  L3_2[1] = L4_2
  L4_2 = VehicleExplosion
  L5_2 = {}
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  evVehicleDestroyed = L1_2
  L1_2 = A0_2.nMaxSpeed
  nMaxSpeed = L1_2
  L1_2 = A0_2.nMinSpeedAsPercent
  nMinSpeedAsPercent = L1_2
  L1_2 = SetReactorHealth
  L2_2 = A0_2.nReactorHealth
  L1_2(L2_2)
  L1_2 = A0_2.nReactorHealth
  nBaseReactorHealth = L1_2
  L1_2 = A0_2.nHealthLoss
  nHealthLoss = L1_2
  L1_2 = A0_2.nReactorHealthSlot
  nReactorHealthSlot = L1_2
  L1_2 = A0_2.nSpeedTraySlot
  nSpeedTraySlot = L1_2
  L1_2 = DisplayReactorHealth
  L1_2()
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 15
  L3_2[1] = L4_2
  
  function L4_2()
    local L0_3, L1_3
    L0_3 = true
    bTimerActive = L0_3
  end
  
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Event
  L1_2 = L1_2.CreatePersistent
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 1
  L3_2[1] = L4_2
  L4_2 = Flipped
  L5_2 = {}
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  evFlipped = L1_2
end

InitializeSpeed = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = Vehicle
  L0_2 = L0_2.IsFlipped
  L1_2 = uVehicle
  L0_2 = L0_2(L1_2)
  if L0_2 then
    L0_2 = Object
    L0_2 = L0_2.GetVelocity
    L1_2 = uVehicle
    L0_2 = L0_2(L1_2)
    if L0_2 < 10 then
      L0_2 = {}
      L1_2 = "Fiona-In-Mission-Contract-Dlc01-13"
      L2_2 = "Fiona-In-Mission-Contract-Dlc01-14"
      L0_2[1] = L1_2
      L0_2[2] = L2_2
      tPossibleVO = L0_2
      L0_2 = MrxUtil
      L0_2 = L0_2.GetRandomTableElement
      L1_2 = tPossibleVO
      L0_2 = L0_2(L1_2)
      sVOLine = L0_2
      L0_2 = Event
      L0_2 = L0_2.Create
      L1_2 = Event
      L1_2 = L1_2.TimerRelative
      L2_2 = {}
      L3_2 = 1
      L2_2[1] = L3_2
      
      function L3_2()
        local L0_3, L1_3, L2_3
        L0_3 = MrxVoSequence
        L0_3 = L0_3.Start
        L1_3 = {}
        L2_3 = sVOLine
        L1_3[1] = L2_3
        L0_3(L1_3)
      end
      
      L0_2(L1_2, L2_2, L3_2)
    end
  end
end

Flipped = L0_1

function L0_1(A0_2)
  local L1_2
  nReactorHealth = A0_2
end

SetReactorHealth = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L0_2 = Math
  L0_2 = L0_2.abs
  L1_2 = Object
  L1_2 = L1_2.GetVelocity
  L2_2 = uVehicle
  L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L1_2(L2_2)
  L0_2 = L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = uVehicle
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  L4_2 = Math
  L4_2 = L4_2.GetXZHeading
  L5_2 = nLastX
  L5_2 = L1_2 - L5_2
  L6_2 = nLastY
  L6_2 = L2_2 - L6_2
  L7_2 = nLastZ
  L7_2 = L3_2 - L7_2
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  nHeading = L4_2
  L4_2 = L1_2
  L5_2 = L2_2
  nLastZ = L3_2
  nLasty = L5_2
  nLastX = L4_2
  L4_2 = "green"
  L5_2 = nMaxSpeed
  L6_2 = nMinSpeedAsPercent
  L5_2 = L5_2 * L6_2
  if L0_2 < L5_2 then
    L4_2 = "red"
  end
  L5_2 = Math
  L5_2 = L5_2.floor
  L6_2 = L0_2 * 2.237
  L5_2 = L5_2(L6_2)
  L6_2 = Hud
  L6_2 = L6_2.ObjectiveTray
  L7_2 = L6_2
  L6_2 = L6_2.SetSlotToText
  L8_2 = {}
  L8_2.vPlayer = nil
  L9_2 = nSpeedTraySlot
  L8_2.nSlot = L9_2
  L9_2 = "[DLCCon001.UI.Speed] ["
  L10_2 = L4_2
  L11_2 = "]"
  L12_2 = L5_2
  L13_2 = " [DLCCon001.UI.MPH]"
  L9_2 = L9_2 .. L10_2 .. L11_2 .. L12_2 .. L13_2
  L8_2.sText = L9_2
  L6_2(L7_2, L8_2)
  L6_2 = Vehicle
  L6_2 = L6_2.IsFlipped
  L7_2 = uVehicle
  L6_2 = L6_2(L7_2)
  if L6_2 then
    L6_2 = Object
    L6_2 = L6_2.GetVelocity
    L7_2 = uVehicle
    L6_2 = L6_2(L7_2)
    if L6_2 < 10 then
      L6_2 = MrxTutorialManager
      L6_2 = L6_2.ShowMessage
      L7_2 = "[DLCCon001.UI.FlipCar]"
      L6_2(L7_2)
      L6_2 = Event
      L6_2 = L6_2.Create
      L7_2 = Event
      L7_2 = L7_2.TimerRelative
      L8_2 = {}
      L9_2 = 10
      L8_2[1] = L9_2
      L9_2 = MrxTutorialManager
      L9_2 = L9_2.HideMessage
      L10_2 = {}
      L6_2(L7_2, L8_2, L9_2, L10_2)
    end
  end
  L6_2 = bTimerActive
  if L6_2 then
    L6_2 = nMaxSpeed
    L7_2 = nMinSpeedAsPercent
    L6_2 = L6_2 * L7_2
    if L0_2 < L6_2 then
      L6_2 = evReactorTimer
      if not L6_2 then
        L6_2 = Event
        L6_2 = L6_2.CreatePersistent
        L7_2 = Event
        L7_2 = L7_2.TimerRelative
        L8_2 = {}
        L9_2 = 1
        L8_2[1] = L9_2
        L9_2 = ReactorHealthLoss
        L10_2 = {}
        L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
        evReactorTimer = L6_2
    end
    else
      L6_2 = nMaxSpeed
      L7_2 = nMinSpeedAsPercent
      L6_2 = L6_2 * L7_2
      if L0_2 > L6_2 then
        L6_2 = evReactorTimer
        if L6_2 then
          L6_2 = ClearReactorTimer
          L7_2 = true
          L6_2(L7_2)
        end
      end
    end
  end
end

UpdateSpeed = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = nReactorHealth
  L1_2 = nHealthLoss
  L0_2 = L0_2 - L1_2
  nReactorHealth = L0_2
  L0_2 = DisplayReactorHealth
  L0_2()
  L0_2 = nReactorHealth
  if L0_2 <= 0 then
    L0_2 = Event
    L0_2 = L0_2.Delete
    L1_2 = evVehicleDestroyed
    L0_2(L1_2)
    L0_2 = VehicleExplosion
    L0_2()
    return
  end
end

ReactorHealthLoss = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evReactorTimer
  L1_2(L2_2)
  L1_2 = nil
  evReactorTimer = L1_2
  if A0_2 then
    L1_2 = DisplayReactorHealth
    L1_2()
  end
end

ClearReactorTimer = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = "white"
  if A0_2 then
    L1_2 = A0_2
  end
  L2_2 = "green"
  L3_2 = Math
  L3_2 = L3_2.ceil
  L4_2 = nReactorHealth
  L5_2 = nBaseReactorHealth
  L4_2 = L4_2 / L5_2
  L4_2 = L4_2 * 100
  L3_2 = L3_2(L4_2)
  if L3_2 < 40 then
    L2_2 = "red"
    L3_2 = bInitialRed
    if L3_2 then
      L3_2 = false
      bInitialRed = L3_2
      L3_2 = Object
      L3_2 = L3_2.GetPosition
      L4_2 = uVehicle
      L3_2, L4_2, L5_2 = L3_2(L4_2)
      L6_2 = Object
      L6_2 = L6_2.GetYaw
      L7_2 = uVehicle
      L6_2 = L6_2(L7_2)
      L7_2 = Pg
      L7_2 = L7_2.Spawn
      L8_2 = "dlc_global_particle_sparks_vehicle_box_red"
      L9_2 = L3_2
      L10_2 = L4_2
      L11_2 = L5_2
      L12_2 = L6_2
      L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
      eEffect = L7_2
      L7_2 = Object
      L7_2 = L7_2.Attach
      L8_2 = uVehicle
      L9_2 = "bone_frame"
      L10_2 = eEffect
      L7_2(L8_2, L9_2, L10_2)
      L7_2 = true
      bRedSparks = L7_2
      L7_2 = Sound
      L7_2 = L7_2.CueSound
      L8_2 = uVehicle
      L9_2 = "dlcfx_electric_lp-01"
      L7_2(L8_2, L9_2)
      L7_2 = DlcCon001
      L7_2 = L7_2.PlayRandomVO
      L8_2 = "ReactorHealthLow"
      L7_2(L8_2)
      L7_2 = FlashText
      L8_2 = "red"
      L9_2 = true
      L7_2(L8_2, L9_2)
      return
    end
  else
    L3_2 = Math
    L3_2 = L3_2.ceil
    L4_2 = nReactorHealth
    L5_2 = nBaseReactorHealth
    L4_2 = L4_2 / L5_2
    L4_2 = L4_2 * 100
    L3_2 = L3_2(L4_2)
    if L3_2 < 70 then
      L2_2 = "yellow"
      L3_2 = true
      bInitialRed = L3_2
      L3_2 = bInitialYellow
      if L3_2 then
        L3_2 = false
        bInitialYellow = L3_2
        L3_2 = FlashText
        L4_2 = "yellow"
        L5_2 = true
        L3_2(L4_2, L5_2)
        return
      end
      L3_2 = bRedSparks
      if L3_2 then
        L3_2 = false
        bRedSparks = L3_2
        L3_2 = Object
        L3_2 = L3_2.Remove
        L4_2 = eEffect
        L3_2(L4_2)
        L3_2 = Sound
        L3_2 = L3_2.StopSound
        L4_2 = uVehicle
        L5_2 = "dlcfx_electric_lp-01"
        L3_2(L4_2, L5_2)
      end
    end
  end
  if L2_2 == "green" then
    L3_2 = true
    bInitialYellow = L3_2
    L3_2 = false
    bRedSparks = L3_2
  end
  L3_2 = Hud
  L3_2 = L3_2.ObjectiveTray
  L4_2 = L3_2
  L3_2 = L3_2.SetSlotToText
  L5_2 = {}
  L6_2 = nReactorHealthSlot
  L5_2.nSlot = L6_2
  L6_2 = "["
  L7_2 = L1_2
  L8_2 = "][DLCCon001.UI.ReactorStability] ["
  L9_2 = L2_2
  L10_2 = "][bar"
  L11_2 = Math
  L11_2 = L11_2.ceil
  L12_2 = nReactorHealth
  L13_2 = nBaseReactorHealth
  L12_2 = L12_2 / L13_2
  L12_2 = L12_2 * 100
  L11_2 = L11_2(L12_2)
  L12_2 = "]"
  L6_2 = L6_2 .. L7_2 .. L8_2 .. L9_2 .. L10_2 .. L11_2 .. L12_2
  L5_2.sText = L6_2
  L3_2(L4_2, L5_2)
end

DisplayReactorHealth = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  if A1_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = evFlash1
    L2_2(L3_2)
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = evFlash2
    L2_2(L3_2)
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = evFlash3
    L2_2(L3_2)
  end
  L2_2 = DisplayReactorHealth
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 0.25
  L4_2[1] = L5_2
  L5_2 = DisplayReactorHealth
  L6_2 = {}
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  evFlash1 = L2_2
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 0.5
  L4_2[1] = L5_2
  L5_2 = DisplayReactorHealth
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  evFlash2 = L2_2
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 0.75
  L4_2[1] = L5_2
  L5_2 = DisplayReactorHealth
  L6_2 = {}
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  evFlash3 = L2_2
end

FlashText = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = false
  bTimerActive = L0_2
  L0_2 = Event
  L0_2 = L0_2.Delete
  L1_2 = evSpeed
  L0_2(L1_2)
  L0_2 = ClearReactorTimer
  L1_2 = false
  L0_2(L1_2)
  L0_2 = Object
  L0_2 = L0_2.GetPosition
  L1_2 = uVehicle
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  L3_2 = Pg
  L3_2 = L3_2.Spawn
  L4_2 = "Explosion (MOAB)"
  L5_2 = L0_2
  L6_2 = L1_2
  L7_2 = L2_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
  L3_2 = Object
  L3_2 = L3_2.Kill
  L4_2 = uVehicle
  L3_2(L4_2)
end

VehicleExplosion = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = nHeading
  return L0_2
end

GetHeading = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = false
  bTimerActive = L0_2
  L0_2 = Event
  L0_2 = L0_2.Delete
  L1_2 = evSpeed
  L0_2(L1_2)
  L0_2 = ClearReactorTimer
  L1_2 = false
  L0_2(L1_2)
end

DeinitSpeed = L0_1
L0_1 = {}
tHealthPickupLocations = L0_1
L0_1 = {}
tActiveHealthPickups = L0_1
L0_1 = " "
sHealthPickupLabel = L0_1
L0_1 = 0
nHealthPickupMinSpawnDist = L0_1
L0_1 = 0
nHealthPickupMaxSpawnDist = L0_1
L0_1 = 0
nHealthPickupSpawnRadius = L0_1
L0_1 = 0
nHealthPickupOutofRange = L0_1
L0_1 = false
bHealthPacksEnabled = L0_1
L0_1 = 0
nSpawnChance = L0_1
L0_1 = 0
nHealthRestored = L0_1
L0_1 = false
bHealthPickupsActive = L0_1
L0_1 = false
bFirstHealthPickup = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = A0_2.sHealthPickupLabel
  sHealthPickupLabel = L1_2
  L1_2 = A0_2.nHealthPickupMinSpawnDist
  nHealthPickupMinSpawnDist = L1_2
  L1_2 = A0_2.nHealthPickupMaxSpawnDist
  nHealthPickupMaxSpawnDist = L1_2
  L1_2 = A0_2.nHealthPickupSpawnRadius
  nHealthPickupSpawnRadius = L1_2
  L1_2 = A0_2.nHealthPickupOutofRange
  nHealthPickupOutofRange = L1_2
  L1_2 = A0_2.bHealthPacksEnabled
  bHealthPacksEnabled = L1_2
  L1_2 = A0_2.nSpawnChance
  nSpawnChance = L1_2
  L1_2 = A0_2.nHealthRestored
  nHealthRestored = L1_2
  L1_2 = true
  bHealthPickupsActive = L1_2
  L1_2 = true
  bFirstHealthPickup = L1_2
  L1_2 = A0_2.nHealthPickups
  if L1_2 < 20 then
    L1_2 = SetupRandomHealthPickups
    L2_2 = A0_2.nHealthPickups
    L1_2(L2_2)
  else
    L1_2 = math
    L1_2 = L1_2.floor
    L2_2 = A0_2.nHealthPickups
    L2_2 = L2_2 / 20
    L1_2 = L1_2(L2_2)
    L2_2 = SetupRandomHealthPickups
    L3_2 = 20
    L2_2(L3_2)
    if 1 < L1_2 then
      L2_2 = 1
      L3_2 = L1_2 - 1
      L4_2 = 1
      for L5_2 = L2_2, L3_2, L4_2 do
        L6_2 = Event
        L6_2 = L6_2.Create
        L7_2 = Event
        L7_2 = L7_2.TimerRelative
        L8_2 = {}
        L9_2 = 30 * L5_2
        L8_2[1] = L9_2
        L9_2 = SetupRandomHealthPickups
        L10_2 = {}
        L11_2 = 20
        L10_2[1] = L11_2
        L6_2(L7_2, L8_2, L9_2, L10_2)
      end
    end
    L2_2 = A0_2.nHealthPickups
    L3_2 = L1_2 * 20
    L2_2 = L2_2 - L3_2
    if 0 < L2_2 then
      L2_2 = Event
      L2_2 = L2_2.Create
      L3_2 = Event
      L3_2 = L3_2.TimerRelative
      L4_2 = {}
      L5_2 = 30 * L1_2
      L4_2[1] = L5_2
      L5_2 = SetupRandomHealthPickups
      L6_2 = {}
      L7_2 = A0_2.nHealthPickups
      L8_2 = L1_2 * 20
      L7_2 = L7_2 - L8_2
      L6_2[1] = L7_2
      L2_2(L3_2, L4_2, L5_2, L6_2)
    end
  end
end

InitializeRandomHealthPickups = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = 0
  L2_2 = 1
  L3_2 = A0_2
  L4_2 = 1
  for L5_2 = L2_2, L3_2, L4_2 do
    L6_2 = SelectRandomHealthPickup
    L6_2 = L6_2()
    L1_2 = L1_2 + L6_2
  end
  if 0 < L1_2 then
    L2_2 = Event
    L2_2 = L2_2.Create
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = 0.5
    L4_2[1] = L5_2
    L5_2 = SetupRandomHealthPickups
    L6_2 = {}
    L7_2 = L1_2
    L6_2[1] = L7_2
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
    evReselectHealthPickups = L2_2
  end
end

SetupRandomHealthPickups = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L0_2 = bHealthPickupsActive
  if not L0_2 then
    L0_2 = 0
    return L0_2
  end
  L0_2 = Object
  L0_2 = L0_2.GetPosition
  L1_2 = uVehicle
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  L3_2 = Pg
  L3_2 = L3_2.GetObjectsInArea
  L4_2 = L0_2
  L5_2 = L1_2
  L6_2 = L2_2
  L7_2 = nHealthPickupMaxSpawnDist
  L8_2 = sHealthPickupLabel
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  tHealthPickupLocations = L3_2
  L3_2 = table
  L3_2 = L3_2.getn
  L4_2 = tHealthPickupLocations
  L3_2 = L3_2(L4_2)
  L4_2 = 1
  if 0 < L3_2 then
    L5_2 = Math
    L5_2 = L5_2.randi
    L6_2 = 1
    L7_2 = L3_2
    L5_2 = L5_2(L6_2, L7_2)
    L4_2 = L5_2
    L5_2 = tHealthPickupLocations
    L5_2 = L5_2[L4_2]
    L6_2 = Object
    L6_2 = L6_2.GetPosition
    L7_2 = L5_2
    L6_2, L7_2, L8_2 = L6_2(L7_2)
    L9_2 = Math
    L9_2 = L9_2.GetXZHeading
    L10_2 = L6_2 - L0_2
    L11_2 = L7_2 - L1_2
    L12_2 = L8_2 - L2_2
    L9_2 = L9_2(L10_2, L11_2, L12_2)
    nHealthPickupHeading = L9_2
    L9_2 = Math
    L9_2 = L9_2.abs
    L10_2 = nHealthPickupHeading
    L11_2 = GetHeading
    L11_2 = L11_2()
    L10_2 = L10_2 - L11_2
    L9_2 = L9_2(L10_2)
    L10_2 = nHealthPickupSpawnRadius
    if not (L9_2 > L10_2) then
      L9_2 = Object
      L9_2 = L9_2.GetDistanceFrom
      L10_2 = uVehicle
      L11_2 = L5_2
      L9_2 = L9_2(L10_2, L11_2)
      L10_2 = nHealthPickupMinSpawnDist
      if not (L9_2 < L10_2) then
        goto lbl_65
      end
    end
    L9_2 = 1
    do return L9_2 end
    ::lbl_65::
    L9_2 = pairs
    L10_2 = tActiveHealthPickups
    L9_2, L10_2, L11_2 = L9_2(L10_2)
    for L12_2, L13_2 in L9_2, L10_2, L11_2 do
      L14_2 = L13_2.uLocationGuid
      if L14_2 == L5_2 then
        L14_2 = 1
        return L14_2
      end
    end
    L9_2 = table
    L9_2 = L9_2.insert
    L10_2 = tActiveHealthPickups
    L11_2 = {}
    L11_2.uLocationGuid = L5_2
    L9_2(L10_2, L11_2)
    L9_2 = 0
    L10_2 = pairs
    L11_2 = tActiveHealthPickups
    L10_2, L11_2, L12_2 = L10_2(L11_2)
    for L13_2, L14_2 in L10_2, L11_2, L12_2 do
      L15_2 = L14_2.uLocationGuid
      if L15_2 == L5_2 then
        L9_2 = L13_2
      end
    end
    L10_2 = Math
    L10_2 = L10_2.randi
    L11_2 = 1
    L12_2 = nSpawnChance
    L10_2 = L10_2(L11_2, L12_2)
    L10_2 = L10_2 == 1
    L11_2 = bHealthPacksEnabled
    if L11_2 and L10_2 then
      L11_2 = Pg
      L11_2 = L11_2.Spawn
      L12_2 = "DLC_Speed_Boost_Pickup"
      L13_2 = L6_2
      L14_2 = L7_2
      L15_2 = L8_2
      L11_2 = L11_2(L12_2, L13_2, L14_2, L15_2)
      L12_2 = Object
      L12_2 = L12_2.DisablePhysics
      L13_2 = L11_2
      L12_2(L13_2)
      L12_2 = tActiveHealthPickups
      L12_2 = L12_2[L9_2]
      L12_2.uPickupGuid = L11_2
      L12_2 = tActiveHealthPickups
      L12_2 = L12_2[L9_2]
      L13_2 = Event
      L13_2 = L13_2.Create
      L14_2 = Event
      L14_2 = L14_2.ObjectProximity
      L15_2 = {}
      L16_2 = uVehicle
      L17_2 = L11_2
      L18_2 = "<"
      L19_2 = 5
      L15_2[1] = L16_2
      L15_2[2] = L17_2
      L15_2[3] = L18_2
      L15_2[4] = L19_2
      L16_2 = PickupHealth
      L17_2 = {}
      L18_2 = L11_2
      L17_2[1] = L18_2
      L13_2 = L13_2(L14_2, L15_2, L16_2, L17_2)
      L12_2.evPickup = L13_2
    end
    L11_2 = tActiveHealthPickups
    L11_2 = L11_2[L9_2]
    L12_2 = Event
    L12_2 = L12_2.Create
    L13_2 = Event
    L13_2 = L13_2.ObjectProximity
    L14_2 = {}
    L15_2 = uVehicle
    L16_2 = L5_2
    L17_2 = ">"
    L18_2 = nHealthPickupOutofRange
    L14_2[1] = L15_2
    L14_2[2] = L16_2
    L14_2[3] = L17_2
    L14_2[4] = L18_2
    L15_2 = RemoveHealthPickup
    L16_2 = {}
    L17_2 = L5_2
    L16_2[1] = L17_2
    L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2)
    L11_2.evHealthPickupOutofRange = L12_2
    L11_2 = 0
    return L11_2
  else
    L5_2 = 1
    return L5_2
  end
end

SelectRandomHealthPickup = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = bFirstHealthPickup
  if L1_2 then
    L1_2 = false
    bFirstHealthPickup = L1_2
    L1_2 = MrxVoSequence
    L1_2 = L1_2.Start
    L2_2 = {}
    L3_2 = "Fiona-In-Mission-Contract-Dlc01-07"
    L4_2 = ShowHealthTutorial
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L1_2(L2_2)
  end
  L1_2 = Object
  L1_2 = L1_2.Remove
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Sound
  L1_2 = L1_2.CueSound
  L2_2 = uVehicle
  L3_2 = "dlcfx_nuke_health"
  L1_2(L2_2, L3_2)
  L1_2 = pairs
  L2_2 = tActiveHealthPickups
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L5_2.uPickupGuid
    if L6_2 == A0_2 then
      L6_2 = Event
      L6_2 = L6_2.Delete
      L7_2 = L5_2.evHealthPickupOutofRange
      L6_2(L7_2)
    end
  end
  L1_2 = nReactorHealth
  L2_2 = nHealthRestored
  L1_2 = L1_2 + L2_2
  nReactorHealth = L1_2
  L1_2 = nReactorHealth
  L2_2 = nBaseReactorHealth
  if L1_2 > L2_2 then
    L1_2 = nBaseReactorHealth
    nReactorHealth = L1_2
  end
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = uVehicle
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  L4_2 = Object
  L4_2 = L4_2.GetYaw
  L5_2 = uVehicle
  L4_2 = L4_2(L5_2)
  L5_2 = Pg
  L5_2 = L5_2.Spawn
  L6_2 = "dlc_global_particle_sparks_vehicle_box_blue"
  L7_2 = L1_2
  L8_2 = L2_2
  L9_2 = L3_2
  L10_2 = L4_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L6_2 = Object
  L6_2 = L6_2.Attach
  L7_2 = uVehicle
  L8_2 = "bone_frame"
  L9_2 = L5_2
  L6_2(L7_2, L8_2, L9_2)
  L6_2 = eMaterialAnimation
  if L6_2 then
    L6_2 = false
    eMaterialAnimation = L6_2
    L6_2 = Object
    L6_2 = L6_2.PlayMaterialAnimation
    L7_2 = uVehicle
    L8_2 = "energy_wave"
    L9_2 = false
    L6_2(L7_2, L8_2, L9_2)
    L6_2 = Event
    L6_2 = L6_2.Create
    L7_2 = Event
    L7_2 = L7_2.TimerRelative
    L8_2 = {}
    L9_2 = 1
    L8_2[1] = L9_2
    L9_2 = _GraphicsAto
    L10_2 = {}
    L6_2(L7_2, L8_2, L9_2, L10_2)
  end
  L6_2 = FlashText
  L7_2 = "green"
  L8_2 = true
  L6_2(L7_2, L8_2)
end

PickupHealth = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = MrxTutorialManager
  L0_2 = L0_2.ShowMessage
  L1_2 = "[DLCCon001.UI.HealthKit]"
  L0_2(L1_2)
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.TimerRelative
  L2_2 = {}
  L3_2 = 10
  L2_2[1] = L3_2
  L3_2 = MrxTutorialManager
  L3_2 = L3_2.HideMessage
  L4_2 = {}
  L0_2(L1_2, L2_2, L3_2, L4_2)
end

ShowHealthTutorial = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = Object
  L0_2 = L0_2.PlayMaterialAnimation
  L1_2 = uVehicle
  L2_2 = "energy_coil"
  L3_2 = true
  L0_2(L1_2, L2_2, L3_2)
  L0_2 = true
  eMaterialAnimation = L0_2
end

_GraphicsAto = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = pairs
  L2_2 = tActiveHealthPickups
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L5_2.uLocationGuid
    if L6_2 == A0_2 then
      L6_2 = L5_2.uPickupGuid
      if L6_2 then
        L6_2 = Object
        L6_2 = L6_2.IsAlive
        L7_2 = L5_2.uPickupGuid
        L6_2 = L6_2(L7_2)
        if L6_2 then
          L6_2 = Object
          L6_2 = L6_2.Remove
          L7_2 = L5_2.uPickupGuid
          L6_2(L7_2)
        end
      end
      L6_2 = Event
      L6_2 = L6_2.Delete
      L7_2 = L5_2.evPickup
      L6_2(L7_2)
      L6_2 = table
      L6_2 = L6_2.remove
      L7_2 = tActiveHealthPickups
      L8_2 = L4_2
      L6_2(L7_2, L8_2)
    end
  end
  L1_2 = SetupRandomHealthPickups
  L2_2 = 1
  L1_2(L2_2)
end

RemoveHealthPickup = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = false
  bHealthPickupsActive = L0_2
  L0_2 = Event
  L0_2 = L0_2.Delete
  L1_2 = evReselectHealthPickups
  L0_2(L1_2)
  L0_2 = pairs
  L1_2 = tActiveHealthPickups
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = L4_2.uPickupGuid
    if L5_2 then
      L5_2 = Object
      L5_2 = L5_2.IsAlive
      L6_2 = L4_2.uPickupGuid
      L5_2 = L5_2(L6_2)
      if L5_2 then
        L5_2 = Object
        L5_2 = L5_2.Remove
        L6_2 = L4_2.uPickupGuid
        L5_2(L6_2)
      end
    end
    L5_2 = Event
    L5_2 = L5_2.Delete
    L6_2 = L4_2.evPickup
    L5_2(L6_2)
    L5_2 = Event
    L5_2 = L5_2.Delete
    L6_2 = L4_2.evHealthPickupOutofRange
    L5_2(L6_2)
  end
  L0_2 = {}
  tActiveHealthPickups = L0_2
end

DeinitRandomHealthPickups = L0_1
L0_1 = 0
nRumbleLength = L0_1
L0_1 = 0
nRumbleIntensity = L0_1
L0_1 = 0
nBoostUseRate = L0_1
L0_1 = false
bIsBoosting = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = false
  bIsBoosting = L1_2
  L1_2 = A0_2.nRumbleLength
  nRumbleLength = L1_2
  L1_2 = A0_2.nRumbleIntensity
  nRumbleIntensity = L1_2
  L1_2 = A0_2.nBoostUseRate
  if L1_2 then
    L1_2 = A0_2.nBoostUseRate
    L1_2 = L1_2 / 4
    nBoostUseRate = L1_2
  end
  L1_2 = A0_2.bEnableBoost
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.CreatePersistent
    L2_2 = Event
    L2_2 = L2_2.Button
    L3_2 = {}
    L4_2 = Player
    L4_2 = L4_2.GetLocalPlayer
    L4_2 = L4_2()
    L5_2 = "lbutton"
    L6_2 = "press"
    L7_2 = true
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L3_2[4] = L7_2
    L4_2 = TriggerBoost
    L5_2 = {}
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
    evTriggerBoost = L1_2
  else
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = evTriggerBoost
    L1_2(L2_2)
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = evStopBoost
    L1_2(L2_2)
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = evApplyBoost
    L1_2(L2_2)
  end
end

SetupBoost = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.GetCurrentControlHolder
  L1_2 = Player
  L1_2 = L1_2.GetLocalPlayer
  L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2 = L1_2()
  L0_2 = L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  if L0_2 then
    return
  end
  L0_2 = nReactorHealth
  L1_2 = nBoostUseRate
  if L0_2 < L1_2 then
    return
  end
  L0_2 = true
  bIsBoosting = L0_2
  L0_2 = 3000
  L1_2 = Object
  L1_2 = L1_2.GetVelocity
  L2_2 = uVehicle
  L1_2 = L1_2(L2_2)
  if L1_2 < 15 then
    L0_2 = 50000
  end
  L1_2 = Event
  L1_2 = L1_2.CreatePersistent
  L2_2 = Event
  L2_2 = L2_2.Button
  L3_2 = {}
  L4_2 = Player
  L4_2 = L4_2.GetLocalPlayer
  L4_2 = L4_2()
  L5_2 = "lbutton"
  L6_2 = "release"
  L7_2 = true
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L4_2 = StopBoost
  L5_2 = {}
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  evStopBoost = L1_2
  L1_2 = String
  L1_2 = L1_2.GetHash
  L2_2 = "DLC_global_particle_fire_jetengine_boost_infinite"
  L1_2 = L1_2(L2_2)
  L2_2 = nReactorHealth
  L3_2 = nBoostUseRate
  L2_2 = L2_2 - L3_2
  nReactorHealth = L2_2
  L2_2 = DisplayReactorHealth
  L2_2()
  L2_2 = ObjectState
  L2_2 = L2_2.StartEmitter
  L3_2 = uVehicle
  L4_2 = String
  L4_2 = L4_2.GetHash
  L5_2 = "hp_fx_exhaust_a"
  L4_2 = L4_2(L5_2)
  L5_2 = L1_2
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = ObjectState
  L2_2 = L2_2.StartEmitter
  L3_2 = uVehicle
  L4_2 = String
  L4_2 = L4_2.GetHash
  L5_2 = "hp_fx_exhaust_b"
  L4_2 = L4_2(L5_2)
  L5_2 = L1_2
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = Pg
  L2_2 = L2_2.Rumble
  L3_2 = Player
  L3_2 = L3_2.GetLocalPlayer
  L3_2 = L3_2()
  L4_2 = nRumbleLength
  L5_2 = nRumbleIntensity
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = Object
  L2_2 = L2_2.ApplyImpulse
  L3_2 = uVehicle
  L4_2 = 0
  L5_2 = 0
  L6_2 = L0_2
  L7_2 = true
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L2_2 = Event
  L2_2 = L2_2.CreatePersistent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 0.25
  L4_2[1] = L5_2
  L5_2 = ApplyBoost
  L6_2 = {}
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  evApplyBoost = L2_2
end

TriggerBoost = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = nReactorHealth
  L1_2 = nBoostUseRate
  if L0_2 < L1_2 then
    L0_2 = StopBoost
    L0_2()
    return
  end
  L0_2 = 3000
  L1_2 = Object
  L1_2 = L1_2.GetVelocity
  L2_2 = uVehicle
  L1_2 = L1_2(L2_2)
  if L1_2 < 10 then
    L0_2 = 6000
  end
  L1_2 = Object
  L1_2 = L1_2.ApplyImpulse
  L2_2 = uVehicle
  L3_2 = 0
  L4_2 = 0
  L5_2 = L0_2
  L6_2 = true
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Vehicle
  L1_2 = L1_2.IsFlipped
  L2_2 = uVehicle
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = Object
    L1_2 = L1_2.GetVelocity
    L2_2 = uVehicle
    L1_2 = L1_2(L2_2)
    if L1_2 < 10 then
      L1_2 = Object
      L1_2 = L1_2.GetMass
      L2_2 = uVehicle
      L1_2 = L1_2(L2_2)
      L2_2 = Object
      L2_2 = L2_2.ApplyAngularImpulse
      L3_2 = uVehicle
      L4_2 = -L1_2
      L4_2 = L4_2 * 2.5
      L5_2 = 0
      L6_2 = L1_2 * 2.5
      L7_2 = true
      L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
    end
  end
  L1_2 = nReactorHealth
  L2_2 = nBoostUseRate
  L1_2 = L1_2 - L2_2
  nReactorHealth = L1_2
  L1_2 = DisplayReactorHealth
  L1_2()
end

ApplyBoost = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = false
  bIsBoosting = L0_2
  L0_2 = String
  L0_2 = L0_2.GetHash
  L1_2 = "DLC_global_particle_fire_jetengine_boost_infinite"
  L0_2 = L0_2(L1_2)
  L1_2 = ObjectState
  L1_2 = L1_2.StopEmitter
  L2_2 = uVehicle
  L3_2 = String
  L3_2 = L3_2.GetHash
  L4_2 = "hp_fx_exhaust_a"
  L3_2 = L3_2(L4_2)
  L4_2 = L0_2
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = ObjectState
  L1_2 = L1_2.StopEmitter
  L2_2 = uVehicle
  L3_2 = String
  L3_2 = L3_2.GetHash
  L4_2 = "hp_fx_exhaust_b"
  L3_2 = L3_2(L4_2)
  L4_2 = L0_2
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evApplyBoost
  L1_2(L2_2)
end

StopBoost = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = "green"
  L1_2 = nBoostAvailable
  if L1_2 < 66 then
    L0_2 = "yellow"
  end
  L1_2 = nBoostAvailable
  if L1_2 < 33 then
    L0_2 = "red"
  end
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.SetSlotToText
  L3_2 = {}
  L4_2 = nBoostTraySlot
  L3_2.nSlot = L4_2
  L4_2 = "Boost ["
  L5_2 = L0_2
  L6_2 = "][bar"
  L7_2 = nBoostAvailable
  L8_2 = "]"
  L4_2 = L4_2 .. L5_2 .. L6_2 .. L7_2 .. L8_2
  L3_2.sText = L4_2
  L1_2(L2_2, L3_2)
end

DisplayBoost = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = bIsBoosting
  return L0_2
end

IsBoosting = L0_1
