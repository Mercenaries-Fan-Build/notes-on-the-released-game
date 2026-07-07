local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1, L18_1, L19_1, L20_1, L21_1, L22_1, L23_1, L24_1, L25_1, L26_1, L27_1, L28_1, L29_1, L30_1, L31_1, L32_1, L33_1, L34_1, L35_1, L36_1, L37_1, L38_1, L39_1, L40_1, L41_1, L42_1, L43_1, L44_1, L45_1, L46_1, L47_1, L48_1, L49_1, L50_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "dlc_moonpatrol"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "DLCEscalation"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxMusic"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxPmc"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxTaskObjectiveEnterVehicle"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxTaskObjectiveDestroy"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxTimer"
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
L1_1 = "SpeedTools"
L2_1 = true
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "WifVzBoundary"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "DLC01_MissionHub"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = {}
L1_1 = {}
L2_1 = {}
L2_1.sCommand = "AddTemplate"
L3_1 = {}
L4_1 = "Driving"
L5_1 = "Stopped"
L6_1 = "Offroad"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L2_1.tSituation = L3_1
L3_1 = {}
L4_1 = "Heli"
L5_1 = "Alouette3 Attack (VZ) (Driver)"
L6_1 = 1
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L2_1.tTemplate = L3_1
L1_1[1] = L2_1
L2_1 = {}
L3_1 = {}
L3_1.sCommand = "UpdateDensity"
L4_1 = {}
L5_1 = "Driving"
L6_1 = "Stopped"
L7_1 = "Offroad"
L4_1[1] = L5_1
L4_1[2] = L6_1
L4_1[3] = L7_1
L3_1.tSituation = L4_1
L4_1 = {}
L5_1 = "Tank"
L6_1 = 2
L4_1[1] = L5_1
L4_1[2] = L6_1
L3_1.tDensity = L4_1
L2_1[1] = L3_1
L3_1 = {}
L4_1 = {}
L4_1.sCommand = "UpdateDensity"
L5_1 = {}
L6_1 = "Driving"
L7_1 = "Stopped"
L8_1 = "Offroad"
L5_1[1] = L6_1
L5_1[2] = L7_1
L5_1[3] = L8_1
L4_1.tSituation = L5_1
L5_1 = {}
L6_1 = "Heli"
L7_1 = 2
L5_1[1] = L6_1
L5_1[2] = L7_1
L4_1.tDensity = L5_1
L3_1[1] = L4_1
L4_1 = {}
L5_1 = {}
L5_1.sCommand = "UpdateDensity"
L6_1 = {}
L7_1 = "Driving"
L8_1 = "Stopped"
L9_1 = "Offroad"
L6_1[1] = L7_1
L6_1[2] = L8_1
L6_1[3] = L9_1
L5_1.tSituation = L6_1
L6_1 = {}
L7_1 = "Tank"
L8_1 = 3
L6_1[1] = L7_1
L6_1[2] = L8_1
L5_1.tDensity = L6_1
L4_1[1] = L5_1
L5_1 = {}
L6_1 = {}
L6_1.sCommand = "UpdateDensity"
L7_1 = {}
L8_1 = "Driving"
L9_1 = "Stopped"
L10_1 = "Offroad"
L7_1[1] = L8_1
L7_1[2] = L9_1
L7_1[3] = L10_1
L6_1.tSituation = L7_1
L7_1 = {}
L8_1 = "Heli"
L9_1 = 3
L7_1[1] = L8_1
L7_1[2] = L9_1
L6_1.tDensity = L7_1
L5_1[1] = L6_1
L6_1 = {}
L7_1 = {}
L7_1.sCommand = "UpdateDensity"
L8_1 = {}
L9_1 = "Driving"
L10_1 = "Stopped"
L11_1 = "Offroad"
L8_1[1] = L9_1
L8_1[2] = L10_1
L8_1[3] = L11_1
L7_1.tSituation = L8_1
L8_1 = {}
L9_1 = "Tank"
L10_1 = 4
L8_1[1] = L9_1
L8_1[2] = L10_1
L7_1.tDensity = L8_1
L6_1[1] = L7_1
L7_1 = {}
L8_1 = {}
L8_1.sCommand = "UpdateDensity"
L9_1 = {}
L10_1 = "Driving"
L11_1 = "Stopped"
L12_1 = "Offroad"
L9_1[1] = L10_1
L9_1[2] = L11_1
L9_1[3] = L12_1
L8_1.tSituation = L9_1
L9_1 = {}
L10_1 = "Heli"
L11_1 = 4
L9_1[1] = L10_1
L9_1[2] = L11_1
L8_1.tDensity = L9_1
L7_1[1] = L8_1
L8_1 = {}
L9_1 = {}
L9_1.sCommand = "UpdateDensity"
L10_1 = {}
L11_1 = "Driving"
L12_1 = "Stopped"
L13_1 = "Offroad"
L10_1[1] = L11_1
L10_1[2] = L12_1
L10_1[3] = L13_1
L9_1.tSituation = L10_1
L10_1 = {}
L11_1 = "Tank"
L12_1 = 5
L10_1[1] = L11_1
L10_1[2] = L12_1
L9_1.tDensity = L10_1
L8_1[1] = L9_1
L9_1 = {}
L10_1 = {}
L10_1.sCommand = "UpdateDensity"
L11_1 = {}
L12_1 = "Driving"
L13_1 = "Stopped"
L14_1 = "Offroad"
L11_1[1] = L12_1
L11_1[2] = L13_1
L11_1[3] = L14_1
L10_1.tSituation = L11_1
L11_1 = {}
L12_1 = "Heli"
L13_1 = 5
L11_1[1] = L12_1
L11_1[2] = L13_1
L10_1.tDensity = L11_1
L9_1[1] = L10_1
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1
L0_1[5] = L5_1
L0_1[6] = L6_1
L0_1[7] = L7_1
L0_1[8] = L8_1
L0_1[9] = L9_1
tLocalEscalationTable = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = {}
  L3_2 = "DLC01_DlcCon001"
  L4_2 = "DLC01_SpeedCity"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = MrxLayerManager
  L3_2 = L3_2.Add
  L4_2 = L2_2
  L5_2 = SetupVehicle
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L3_2(L4_2, L5_2, L6_2)
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "BombCar"
  L1_2 = L1_2(L2_2)
  L2_2 = Object
  L2_2 = L2_2.IsHibernated
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Create
    L3_2 = Event
    L3_2 = L3_2.ObjectHibernation
    L4_2 = {}
    L5_2 = L1_2
    L6_2 = "awake"
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    
    function L5_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3
      L0_3 = Vehicle
      L0_3 = L0_3.Enter
      L1_3 = L1_2
      L2_3 = Player
      L2_3 = L2_3.GetPrimaryCharacter
      L2_3 = L2_3()
      L3_3 = "d"
      L4_3 = true
      L0_3(L1_3, L2_3, L3_3, L4_3)
      L0_3 = A0_2
      L0_3 = L0_3.AssetsLoaded
      L1_3 = A0_2
      L0_3(L1_3)
    end
    
    L2_2(L3_2, L4_2, L5_2)
  else
    L2_2 = Vehicle
    L2_2 = L2_2.Enter
    L3_2 = L1_2
    L4_2 = Player
    L4_2 = L4_2.GetPrimaryCharacter
    L4_2 = L4_2()
    L5_2 = "d"
    L6_2 = true
    L2_2(L3_2, L4_2, L5_2, L6_2)
    L2_2 = A0_2.AssetsLoaded
    L3_2 = A0_2
    L2_2(L3_2)
  end
end

SetupVehicle = L0_1
L0_1 = nil
uVehicle = L0_1
L0_1 = 0
nScore = L0_1
L0_1 = 0
nTimeBonus = L0_1
L0_1 = 0
nBonusScore = L0_1
L0_1 = nil
oMasterTimer = L0_1
L0_1 = nil
uLastTarget = L0_1
L0_1 = nil
uTargetMarker = L0_1
L0_1 = 0
nEscalationIndex = L0_1
L0_1 = 0
nTargetsComplete = L0_1
L0_1 = 0
nMinTargetDistance = L0_1
L0_1 = 0
nMaxTargetDistance = L0_1
L0_1 = 0
nTargetsUntilEscalation = L0_1
L0_1 = 0
nTimetoDestroy = L0_1
L0_1 = 0
nMissedBuildings = L0_1
L0_1 = 0
nMissedBuildingsAllowed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = ""
  L1_2(L2_2, L3_2)
  L1_2 = DLCEscalation
  L2_2 = tLocalEscalationTable
  L1_2.tEscalationTable = L2_2
  L1_2 = {}
  L2_2 = {}
  L3_2 = "Driving"
  L4_2 = {}
  L5_2 = {}
  L6_2 = "Car"
  L7_2 = "M151 Softtop (VZ) (Driver)"
  L8_2 = 1
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L6_2 = {}
  L7_2 = "Heli"
  L8_2 = "Alouette3 Attack (VZ) (Driver)"
  L9_2 = 1
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L7_2 = {}
  L8_2 = "Tank"
  L9_2 = "Scorpion90 (Driver)"
  L10_2 = 1
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = {}
  L6_2 = {}
  L7_2 = "Car"
  L8_2 = 3
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = {}
  L8_2 = "Heli"
  L9_2 = 1
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L8_2 = {}
  L9_2 = "Tank"
  L10_2 = 1
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L3_2 = {}
  L4_2 = "Stopped"
  L5_2 = {}
  L6_2 = {}
  L7_2 = "Car"
  L8_2 = "M151 Softtop (VZ) (Driver)"
  L9_2 = 1
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L7_2 = {}
  L8_2 = "Heli"
  L9_2 = "Alouette3 Attack (VZ) (Driver)"
  L10_2 = 1
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L8_2 = {}
  L9_2 = "Tank"
  L10_2 = "Scorpion90 (Driver)"
  L11_2 = 1
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L6_2 = {}
  L7_2 = {}
  L8_2 = "Car"
  L9_2 = 3
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L8_2 = {}
  L9_2 = "Heli"
  L10_2 = 1
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L9_2 = {}
  L10_2 = "Tank"
  L11_2 = 1
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L4_2 = {}
  L5_2 = "Offroad"
  L6_2 = {}
  L7_2 = {}
  L8_2 = "Car"
  L9_2 = "M151 Softtop (VZ) (Driver)"
  L10_2 = 1
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L6_2[1] = L7_2
  L7_2 = {}
  L8_2 = {}
  L9_2 = "Car"
  L10_2 = 3
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L7_2[1] = L8_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  tLocalPursuitTable = L1_2
  L1_2 = DLCEscalation
  L2_2 = tLocalPursuitTable
  L1_2.tPursuitTable = L2_2
  L1_2 = Hud
  L1_2 = L1_2.ResourceCounter
  L2_2 = L1_2
  L1_2 = L1_2.SetSuppressed
  L3_2 = {}
  L3_2.bSuppressCash = true
  L3_2.bSuppressFuel = true
  L1_2(L2_2, L3_2)
  L1_2 = MrxPmc
  L1_2 = L1_2.AddCashQty
  L2_2 = MrxPmc
  L2_2 = L2_2.GetCashQty
  L2_2 = L2_2()
  L2_2 = -L2_2
  L3_2 = nil
  L4_2 = nil
  L5_2 = false
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = Player
  L1_2 = L1_2.SetFuel
  L2_2 = 0
  L1_2(L2_2)
  L1_2 = Hud
  L1_2 = L1_2.ResourceCounter
  L2_2 = L1_2
  L1_2 = L1_2.SetSuppressed
  L3_2 = {}
  L3_2.bSuppressCash = false
  L3_2.bSuppressFuel = false
  L1_2(L2_2, L3_2)
  L1_2 = WifVzBoundary
  L1_2 = L1_2.SetupBoundary
  L2_2 = "Speed Boundary"
  L3_2 = false
  L1_2(L2_2, L3_2)
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "BombCar"
  L1_2 = L1_2(L2_2)
  uVehicle = L1_2
  L1_2 = WifMissionFlow
  L1_2 = L1_2.SetGrappleEnabled
  L2_2 = false
  L1_2(L2_2)
  L1_2 = Player
  L1_2 = L1_2.SetVehicleDisguise
  L2_2 = false
  L1_2(L2_2)
  L1_2 = Hud
  L1_2 = L1_2.ResourceCounter
  L2_2 = L1_2
  L1_2 = L1_2.Show
  L3_2 = {}
  L3_2.nDuration = -1
  L1_2(L2_2, L3_2)
  L1_2 = Hud
  L1_2 = L1_2.ResourceCounter
  L2_2 = L1_2
  L1_2 = L1_2.SetSuppressed
  L3_2 = {}
  L3_2.bSuppressCash = false
  L3_2.bSuppressFuel = true
  L1_2(L2_2, L3_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.ChangeLineRegionSetting
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "SpeedAtmo2"
  L2_2 = L2_2(L3_2)
  L3_2 = "day"
  L1_2(L2_2, L3_2)
  L1_2 = SetupMusic
  L1_2()
  L1_2 = MrxTimer
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L3_2 = {}
  L3_2.nStartTime = 0
  L3_2.nStopTime = 3600
  L3_2.nStep = 1
  L3_2.nWarning = 3600
  L3_2.iTray = 0
  L1_2 = L1_2(L2_2, L3_2)
  oMasterTimer = L1_2
  L1_2 = Setup
  L2_2 = A0_2
  L1_2(L2_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Player
  L1_2 = L1_2.SetSeatMovementLocks
  L2_2 = Player
  L2_2 = L2_2.GetPrimaryPlayer
  L2_2 = L2_2()
  L3_2 = true
  L4_2 = false
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = oMasterTimer
  L2_2 = L1_2
  L1_2 = L1_2.Start
  L1_2(L2_2)
  L1_2 = SpeedTools
  L1_2 = L1_2.InitializeSpeed
  L2_2 = {}
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "BombCar"
  L3_2 = L3_2(L4_2)
  L2_2.uVehicle = L3_2
  L2_2.nMaxSpeed = 36.1
  L2_2.nMinSpeedAsPercent = 0.8
  L2_2.nReactorHealth = 40
  L2_2.nHealthLoss = 1
  L2_2.nReactorHealthSlot = 2
  L2_2.nSpeedTraySlot = 3
  L1_2(L2_2)
  L1_2 = SpeedTools
  L1_2 = L1_2.InitializeRandomHealthPickups
  L2_2 = {}
  L2_2.sHealthPickupLabel = "BarrierSpawn"
  L2_2.nHealthPickups = 50
  L2_2.nHealthPickupMinSpawnDist = 100
  L2_2.nHealthPickupMaxSpawnDist = 400
  L2_2.nHealthPickupSpawnRadius = 90
  L2_2.nHealthPickupOutofRange = 500
  L2_2.bHealthPacksEnabled = true
  L2_2.nSpawnChance = 2
  L2_2.nHealthRestored = 5
  L1_2(L2_2)
  L1_2 = SpeedTools
  L1_2 = L1_2.SetupBoost
  L2_2 = {}
  L2_2.bEnableBoost = true
  L2_2.nRumbleLength = 0.5
  L2_2.nRumbleIntensity = 0.25
  L2_2.nBoostUseRate = 3
  L1_2(L2_2)
  L1_2 = dlc_moonpatrol
  L1_2 = L1_2.SetImpulse
  L2_2 = 17
  L1_2(L2_2)
  L1_2 = dlc_moonpatrol
  L1_2 = L1_2.SetPosition
  L2_2 = 0.05
  L1_2(L2_2)
  L1_2 = ResetScore
  L1_2()
  L1_2 = Event
  L1_2 = L1_2.CreatePersistent
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 85
  L3_2[1] = L4_2
  L4_2 = PlayRandomVO
  L5_2 = {}
  L6_2 = "Timed"
  L5_2[1] = L6_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  evRandomVO = L1_2
  L1_2 = Event
  L1_2 = L1_2.CreatePersistent
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 1
  L3_2[1] = L4_2
  L4_2 = UpdateScore
  L5_2 = {}
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  evTimerScore = L1_2
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.ObjectDeath
  L3_2 = {}
  L4_2 = uVehicle
  L3_2[1] = L4_2
  L4_2 = GameOver
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  evVehicleDestroyed = L1_2
  L1_2 = Event
  L1_2 = L1_2.CreatePersistent
  L2_2 = Event
  L2_2 = L2_2.ObjectDeath
  L3_2 = {}
  L4_2 = "Helicopter"
  L3_2[1] = L4_2
  
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = MrxPmc
    L0_3 = L0_3.AddCashQty
    L1_3 = 5000000
    L2_3 = true
    L3_3 = "[DLCCon001.UI.AirAssassin]"
    L0_3(L1_3, L2_3, L3_3)
  end
  
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  evHeliDestroyed = L1_2
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 2
  L3_2[1] = L4_2
  
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-Dlc01-01"
    L3_3 = 0.25
    L4_3 = "Fiona-In-Mission-Contract-Dlc01-03"
    L5_3 = 0.25
    L6_3 = "Fiona-In-Mission-Contract-Dlc01-02"
    L7_3 = 0.25
    L8_3 = "Fiona-In-Mission-Contract-Dlc01-05"
    L9_3 = 0.25
    L10_3 = "Fiona-In-Mission-Contract-Dlc01-06"
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L1_3[3] = L4_3
    L1_3[4] = L5_3
    L1_3[5] = L6_3
    L1_3[6] = L7_3
    L1_3[7] = L8_3
    L1_3[8] = L9_3
    L1_3[9] = L10_3
    L0_3(L1_3)
    L0_3 = Event
    L0_3 = L0_3.Create
    L1_3 = Event
    L1_3 = L1_3.TimerRelative
    L2_3 = {}
    L3_3 = 31
    L2_3[1] = L3_3
    
    function L3_3()
      local L0_4, L1_4
      L0_4 = PlayRandomVO
      L1_4 = "BoostDangers"
      L0_4(L1_4)
    end
    
    L0_3(L1_3, L2_3, L3_3)
  end
  
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  evVOIntro = L1_2
  L1_2 = DLCEscalation
  L1_2 = L1_2.StartPursuit
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = 2
  nEscalationIndex = L1_2
  L1_2 = 0
  nTargetsComplete = L1_2
  L1_2 = 400
  nMinTargetDistance = L1_2
  L1_2 = 500
  nMaxTargetDistance = L1_2
  L1_2 = 5
  nTargetsUntilEscalation = L1_2
  L1_2 = 60
  nTimetoDestroy = L1_2
  L1_2 = 0
  nMissedBuildings = L1_2
  L1_2 = 10
  nMissedBuildingsAllowed = L1_2
  L1_2 = SetupRandomTargetLocation
  L2_2 = A0_2
  L3_2 = true
  L1_2(L2_2, L3_2)
end

Setup = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = nTimeBonus
  L0_2 = L0_2 + 20000
  nTimeBonus = L0_2
  L0_2 = SpeedTools
  L0_2 = L0_2.IsBoosting
  L0_2 = L0_2()
  if L0_2 then
    L0_2 = nBonusScore
    L0_2 = L0_2 + 25000
    nBonusScore = L0_2
  end
end

UpdateScore = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = 0
  nScore = L0_2
  L0_2 = 0
  nTimeBonus = L0_2
  L0_2 = 0
  nBonusScore = L0_2
end

ResetScore = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L2_2 = table
  L2_2 = L2_2.getn
  L3_2 = tTargetLocations
  L2_2 = L2_2(L3_2)
  L3_2 = 1
  if 0 < L2_2 then
    L4_2 = Math
    L4_2 = L4_2.randi
    L5_2 = 1
    L6_2 = L2_2
    L4_2 = L4_2(L5_2, L6_2)
    L3_2 = L4_2
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = tTargetLocations
    L5_2 = L5_2[L3_2]
    L4_2 = L4_2(L5_2)
    if A1_2 then
      L5_2 = Pg
      L5_2 = L5_2.GetGuidByName
      L6_2 = "_caracas_bld_historical04 0x0014f132"
      L5_2 = L5_2(L6_2)
      L4_2 = L5_2
    else
      L5_2 = Object
      L5_2 = L5_2.GetDistanceFrom
      L6_2 = uVehicle
      L7_2 = L4_2
      L5_2 = L5_2(L6_2, L7_2)
      L6_2 = Object
      L6_2 = L6_2.IsAlive
      L7_2 = L4_2
      L6_2 = L6_2(L7_2)
      if L6_2 then
        L6_2 = nMinTargetDistance
        if not (L5_2 < L6_2) then
          L6_2 = nMaxTargetDistance
          if not (L5_2 > L6_2) then
            L6_2 = uLastTarget
            if L4_2 ~= L6_2 then
              goto lbl_54
            end
          end
        end
      end
      L6_2 = SetupRandomTargetLocation
      L7_2 = A0_2
      L6_2(L7_2)
      L6_2 = PlayRandomVO
      L7_2 = "TargetSwap"
      L6_2(L7_2)
      return
    end
    ::lbl_54::
    L6_2 = A0_2
    L5_2 = A0_2.CreateChild
    L7_2 = {}
    L7_2.sName = "[DLCCon001.UI.DestroyTarget]"
    L7_2.sModuleName = "MrxTaskObjectiveDestroy"
    L7_2.vTgtInclude = L4_2
    L7_2.sDspShortDesc = "[DLCCon001.Objectives.001]"
    L7_2.nDspBlpWldFarDist = 500
    
    function L8_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
      L0_3 = PlayRandomVO
      L1_3 = "TargetDestroyed"
      L0_3(L1_3)
      L0_3 = uTargetMarker
      if L0_3 then
        L0_3 = Marker
        L0_3 = L0_3.Remove
        L1_3 = uTargetMarker
        L0_3(L1_3)
      end
      L0_3 = nTargetsComplete
      L0_3 = L0_3 + 1
      nTargetsComplete = L0_3
      L0_3 = nTargetsComplete
      L1_3 = nTargetsUntilEscalation
      if L0_3 == L1_3 then
        L0_3 = DLCEscalation
        L0_3 = L0_3.ParseEscalationTable
        L1_3 = nEscalationIndex
        L0_3(L1_3)
        L0_3 = nEscalationIndex
        L0_3 = L0_3 + 1
        nEscalationIndex = L0_3
        L0_3 = 0
        nTargetsComplete = L0_3
      end
      L0_3 = MrxPmc
      L0_3 = L0_3.AddCashQty
      L1_3 = 350000
      L2_3 = true
      L3_3 = "[DLCCon001.UI.TargetDemolished]"
      L0_3(L1_3, L2_3, L3_3)
      L0_3 = nScore
      L0_3 = L0_3 + 350000
      nScore = L0_3
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = evTargetTimer
      L0_3(L1_3)
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = evTargetNear
      L0_3(L1_3)
      L0_3 = Event
      L0_3 = L0_3.Create
      L1_3 = Event
      L1_3 = L1_3.TimerRelative
      L2_3 = {}
      L3_3 = 2
      L2_3[1] = L3_3
      L3_3 = SetupRandomTargetLocation
      L4_3 = {}
      L5_3 = A0_2
      L4_3[1] = L5_3
      L0_3(L1_3, L2_3, L3_3, L4_3)
    end
    
    L7_2.fOnComplete = L8_2
    L5_2 = L5_2(L6_2, L7_2)
    oTarget = L5_2
    L5_2 = Object
    L5_2 = L5_2.GetPosition
    L6_2 = L4_2
    L5_2, L6_2, L7_2 = L5_2(L6_2)
    L8_2 = Event
    L8_2 = L8_2.Create
    L9_2 = Event
    L9_2 = L9_2.ObjectDeath
    L10_2 = {}
    L11_2 = L4_2
    L10_2[1] = L11_2
    L11_2 = Pg
    L11_2 = L11_2.Spawn
    L12_2 = {}
    L13_2 = "DLC_Explosion (Daisy Cutter)"
    L14_2 = L5_2
    L15_2 = L6_2
    L16_2 = L7_2
    L12_2[1] = L13_2
    L12_2[2] = L14_2
    L12_2[3] = L15_2
    L12_2[4] = L16_2
    L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
    evTargetBuildingExplosion = L8_2
    L8_2 = Event
    L8_2 = L8_2.Create
    L9_2 = Event
    L9_2 = L9_2.ObjectHibernation
    L10_2 = {}
    L11_2 = L4_2
    L12_2 = "awake"
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L11_2 = CreateDiscMarker
    L12_2 = {}
    L13_2 = L4_2
    L12_2[1] = L13_2
    L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
    evTargetAwake = L8_2
    L8_2 = Event
    L8_2 = L8_2.Create
    L9_2 = Event
    L9_2 = L9_2.ObjectProximity
    L10_2 = {}
    L11_2 = uVehicle
    L12_2 = L4_2
    L13_2 = "<"
    L14_2 = 200
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L10_2[3] = L13_2
    L10_2[4] = L14_2
    L11_2 = PlayRandomVO
    L12_2 = {}
    L13_2 = "TargetNear"
    L12_2[1] = L13_2
    L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
    evTargetNear = L8_2
    L8_2 = Event
    L8_2 = L8_2.Create
    L9_2 = Event
    L9_2 = L9_2.TimerRelative
    L10_2 = {}
    L11_2 = nTimetoDestroy
    L10_2[1] = L11_2
    
    function L11_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
      L0_3 = oTarget
      L1_3 = L0_3
      L0_3 = L0_3.Cancel
      L0_3(L1_3)
      L0_3 = uTargetMarker
      if L0_3 then
        L0_3 = Marker
        L0_3 = L0_3.Remove
        L1_3 = uTargetMarker
        L0_3(L1_3)
      end
      L0_3 = nMissedBuildings
      L0_3 = L0_3 + 1
      nMissedBuildings = L0_3
      L0_3 = nMissedBuildings
      L1_3 = nMissedBuildingsAllowed
      if L0_3 == L1_3 then
        L0_3 = A0_2
        L1_3 = L0_3
        L0_3 = L0_3._SetCancelMessage
        L2_3 = "[DLCCon001.UI.BuildingFail]"
        L0_3(L1_3, L2_3)
        L0_3 = Cancel
        L1_3 = A0_2
        L0_3(L1_3)
        return
      end
      L0_3 = MessageBox
      L1_3 = L0_3
      L0_3 = L0_3.AddMessage
      L2_3 = "[DLCCon001.UI.TargetChanged]"
      L0_3(L1_3, L2_3)
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = evTargetBuildingExplosion
      L0_3(L1_3)
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = evTargetAwake
      L0_3(L1_3)
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = evTargetNear
      L0_3(L1_3)
      L0_3 = Event
      L0_3 = L0_3.Create
      L1_3 = Event
      L1_3 = L1_3.TimerRelative
      L2_3 = {}
      L3_3 = 5
      L2_3[1] = L3_3
      L3_3 = SetupRandomTargetLocation
      L4_3 = {}
      L5_3 = A0_2
      L4_3[1] = L5_3
      L0_3 = L0_3(L1_3, L2_3, L3_3, L4_3)
      evReselectTarget = L0_3
    end
    
    L8_2 = L8_2(L9_2, L10_2, L11_2)
    evTargetTimer = L8_2
    uLastTarget = L4_2
  end
end

SetupRandomTargetLocation = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Junk
  L1_2 = L1_2.GetModelBBoxExtents
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  L4_2 = Math
  L4_2 = L4_2.Length
  L5_2 = L1_2
  L6_2 = 0
  L7_2 = L3_2
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  L4_2 = L4_2 / 2
  L5_2 = Marker
  L5_2 = L5_2.AddDiscDLC
  L6_2 = A0_2
  L7_2 = L4_2
  L8_2 = 255
  L9_2 = 200
  L10_2 = 0
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  uTargetMarker = L5_2
end

CreateDiscMarker = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L1_2 = oTarget
  if L1_2 then
    L1_2 = oTarget
    L2_2 = L1_2
    L1_2 = L1_2.Cancel
    L1_2(L2_2)
  end
  L1_2 = uTargetMarker
  if L1_2 then
    L1_2 = Marker
    L1_2 = L1_2.Remove
    L2_2 = uTargetMarker
    L1_2(L2_2)
  end
  L1_2 = WifVzBoundary
  L1_2 = L1_2.RemoveWorldBoundary
  L1_2()
  L1_2 = WifMissionFlow
  L1_2 = L1_2.SetGrappleEnabled
  L2_2 = true
  L1_2(L2_2)
  L1_2 = Player
  L1_2 = L1_2.SetVehicleDisguise
  L2_2 = true
  L1_2(L2_2)
  L1_2 = Player
  L1_2 = L1_2.SetSeatMovementLocks
  L2_2 = Player
  L2_2 = L2_2.GetPrimaryPlayer
  L2_2 = L2_2()
  L3_2 = true
  L4_2 = true
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Hud
  L1_2 = L1_2.ResourceCounter
  L2_2 = L1_2
  L1_2 = L1_2.SetSuppressed
  L3_2 = {}
  L3_2.bSuppressCash = false
  L3_2.bSuppressFuel = false
  L1_2(L2_2, L3_2)
  L1_2 = SpeedTools
  L1_2 = L1_2.DeinitSpeed
  L1_2()
  L1_2 = SpeedTools
  L1_2 = L1_2.DeinitRandomHealthPickups
  L1_2()
  L1_2 = SpeedTools
  L1_2 = L1_2.SetupBoost
  L2_2 = {}
  L2_2.bEnableBoost = false
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evTimerScore
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evVOIntro
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evVehicleDestroyed
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evHeliDestroyed
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evTargetTimer
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evReselectTarget
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evTargetAwake
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evRandomVO
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evOutofVehicle
  L1_2(L2_2)
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.nSlot = 1
  L1_2(L2_2, L3_2)
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.nSlot = 2
  L1_2(L2_2, L3_2)
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.nSlot = 3
  L1_2(L2_2, L3_2)
  L1_2 = oMasterTimer
  L2_2 = L1_2
  L1_2 = L1_2.Stop
  L1_2(L2_2)
  L1_2 = oMasterTimer
  L2_2 = L1_2
  L1_2 = L1_2.GetTime
  L1_2 = L1_2(L2_2)
  L2_2 = PlayRandomVO
  L3_2 = "ContractComplete"
  L2_2(L3_2)
  L2_2 = MrxPmc
  L2_2 = L2_2.AddCashQty
  L3_2 = nTimeBonus
  L4_2 = nBonusScore
  L3_2 = L3_2 + L4_2
  L2_2(L3_2)
  L2_2 = nScore
  L3_2 = nTimeBonus
  L2_2 = L2_2 + L3_2
  L3_2 = nBonusScore
  L2_2 = L2_2 + L3_2
  L3_2 = MrxPmc
  L3_2 = L3_2.GetCashQty
  L3_2 = L3_2()
  L3_2 = L3_2 - L2_2
  L4_2 = ""
  if L3_2 < 0 then
    L4_2 = "-"
  end
  L5_2 = "[DLCCon001.UI.BaseScore] "
  L6_2 = MrxUtil
  L6_2 = L6_2.FormatMoney
  L7_2 = nScore
  L6_2 = L6_2(L7_2)
  L7_2 = "[n]"
  L8_2 = "[Fanfare.Completion.TimeBonus]: "
  L9_2 = MrxUtil
  L9_2 = L9_2.FormatMoney
  L10_2 = nTimeBonus
  L9_2 = L9_2(L10_2)
  L10_2 = "[n]"
  L11_2 = "[DLCCon001.UI.BoostBonus] "
  L12_2 = MrxUtil
  L12_2 = L12_2.FormatMoney
  L13_2 = nBonusScore
  L12_2 = L12_2(L13_2)
  L13_2 = "[n]"
  L14_2 = "[Scoring.Misc]: "
  L15_2 = L4_2
  L16_2 = MrxUtil
  L16_2 = L16_2.FormatMoney
  L17_2 = math
  L17_2 = L17_2.abs
  L18_2 = L3_2
  L17_2, L18_2, L19_2 = L17_2(L18_2)
  L16_2 = L16_2(L17_2, L18_2, L19_2)
  L17_2 = "[n][green][Scoring.Total]: "
  L18_2 = MrxUtil
  L18_2 = L18_2.FormatMoney
  L19_2 = MrxPmc
  L19_2 = L19_2.GetCashQty
  L19_2 = L19_2()
  L18_2 = L18_2(L19_2)
  L19_2 = "[n]"
  L5_2 = L5_2 .. L6_2 .. L7_2 .. L8_2 .. L9_2 .. L10_2 .. L11_2 .. L12_2 .. L13_2 .. L14_2 .. L15_2 .. L16_2 .. L17_2 .. L18_2 .. L19_2
  L6_2 = MrxGui
  L6_2 = L6_2.DisplayDialogBox
  L7_2 = Player
  L7_2 = L7_2.GetPrimaryPlayer
  L7_2 = L7_2()
  L8_2 = L5_2
  L9_2 = {}
  L10_2 = nil
  L11_2 = A0_2.Complete
  L12_2 = {}
  L13_2 = A0_2
  L12_2[1] = L13_2
  L13_2 = nil
  L14_2 = nil
  L15_2 = "center"
  L16_2 = "center"
  L17_2 = true
  L18_2 = nil
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  A0_2.oScoreBoard = L6_2
  L6_2 = Net
  L6_2 = L6_2.LeaderboardPushScore
  L7_2 = "DlcCon001"
  L8_2 = MrxPmc
  L8_2 = L8_2.GetCashQty
  L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2 = L8_2()
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
  L6_2 = DLC01_MissionHub
  L6_2 = L6_2.SetPrevBest
  L7_2 = "DlcCon001"
  L8_2 = MrxPmc
  L8_2 = L8_2.GetCashQty
  L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2 = L8_2()
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
end

GameOver = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  A0_2.oScoreBoard = nil
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Complete
  L2_2 = A0_2
  L1_2(L2_2)
end

Complete = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = oTarget
  if L1_2 then
    L1_2 = oTarget
    L2_2 = L1_2
    L1_2 = L1_2.Cancel
    L1_2(L2_2)
  end
  L1_2 = uTargetMarker
  if L1_2 then
    L1_2 = Marker
    L1_2 = L1_2.Remove
    L2_2 = uTargetMarker
    L1_2(L2_2)
  end
  L1_2 = oMasterTimer
  if L1_2 then
    L1_2 = oMasterTimer
    L2_2 = L1_2
    L1_2 = L1_2.Stop
    L1_2(L2_2)
  end
  L1_2 = DLCEscalation
  L1_2 = L1_2.ClearPursuit
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = WifVzBoundary
  L1_2 = L1_2.RemoveWorldBoundary
  L1_2()
  L1_2 = WifMissionFlow
  L1_2 = L1_2.SetGrappleEnabled
  L2_2 = true
  L1_2(L2_2)
  L1_2 = Player
  L1_2 = L1_2.SetVehicleDisguise
  L2_2 = true
  L1_2(L2_2)
  L1_2 = Player
  L1_2 = L1_2.SetSeatMovementLocks
  L2_2 = Player
  L2_2 = L2_2.GetPrimaryPlayer
  L2_2 = L2_2()
  L3_2 = true
  L4_2 = true
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Hud
  L1_2 = L1_2.ResourceCounter
  L2_2 = L1_2
  L1_2 = L1_2.SetSuppressed
  L3_2 = {}
  L3_2.bSuppressCash = false
  L3_2.bSuppressFuel = false
  L1_2(L2_2, L3_2)
  L1_2 = SpeedTools
  L1_2 = L1_2.DeinitSpeed
  L1_2()
  L1_2 = SpeedTools
  L1_2 = L1_2.DeinitRandomHealthPickups
  L1_2()
  L1_2 = SpeedTools
  L1_2 = L1_2.SetupBoost
  L2_2 = {}
  L2_2.bEnableBoost = false
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evTimerScore
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evVOIntro
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evVehicleDestroyed
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evHeliDestroyed
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evTargetTimer
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evReselectTarget
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evTargetAwake
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evRandomVO
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evOutofVehicle
  L1_2(L2_2)
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.nSlot = 1
  L1_2(L2_2, L3_2)
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.nSlot = 2
  L1_2(L2_2, L3_2)
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.nSlot = 3
  L1_2(L2_2, L3_2)
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cancel
  L2_2 = A0_2
  L1_2(L2_2)
end

Cancel = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = oTarget
  if L1_2 then
    L1_2 = oTarget
    L2_2 = L1_2
    L1_2 = L1_2.Cancel
    L1_2(L2_2)
  end
  L1_2 = uTargetMarker
  if L1_2 then
    L1_2 = Marker
    L1_2 = L1_2.Remove
    L2_2 = uTargetMarker
    L1_2(L2_2)
  end
  L1_2 = oMasterTimer
  if L1_2 then
    L1_2 = oMasterTimer
    L2_2 = L1_2
    L1_2 = L1_2.Stop
    L1_2(L2_2)
  end
  L1_2 = A0_2.oScoreBoard
  if L1_2 then
    L1_2 = A0_2.oScoreBoard
    L2_2 = L1_2
    L1_2 = L1_2.Close
    L1_2(L2_2)
    A0_2.oScoreBoard = nil
  end
  L1_2 = DLCEscalation
  L1_2 = L1_2.ClearPursuit
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = WifVzBoundary
  L1_2 = L1_2.RemoveWorldBoundary
  L1_2()
  L1_2 = WifMissionFlow
  L1_2 = L1_2.SetGrappleEnabled
  L2_2 = true
  L1_2(L2_2)
  L1_2 = Player
  L1_2 = L1_2.SetVehicleDisguise
  L2_2 = true
  L1_2(L2_2)
  L1_2 = Player
  L1_2 = L1_2.SetSeatMovementLocks
  L2_2 = Player
  L2_2 = L2_2.GetPrimaryPlayer
  L2_2 = L2_2()
  L3_2 = true
  L4_2 = true
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Hud
  L1_2 = L1_2.ResourceCounter
  L2_2 = L1_2
  L1_2 = L1_2.SetSuppressed
  L3_2 = {}
  L3_2.bSuppressCash = false
  L3_2.bSuppressFuel = false
  L1_2(L2_2, L3_2)
  L1_2 = SpeedTools
  L1_2 = L1_2.DeinitSpeed
  L1_2()
  L1_2 = SpeedTools
  L1_2 = L1_2.DeinitRandomHealthPickups
  L1_2()
  L1_2 = SpeedTools
  L1_2 = L1_2.SetupBoost
  L2_2 = {}
  L2_2.bEnableBoost = false
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evTimerScore
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evVOIntro
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evVehicleDestroyed
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evHeliDestroyed
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evTargetTimer
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evReselectTarget
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evTargetAwake
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evRandomVO
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evOutofVehicle
  L1_2(L2_2)
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.nSlot = 1
  L1_2(L2_2, L3_2)
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.nSlot = 2
  L1_2(L2_2, L3_2)
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.nSlot = 3
  L1_2(L2_2, L3_2)
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = MrxMusic
  L0_2 = L0_2.PlaySpecialMusic
  L1_2 = "Dlc_mu_manny"
  L0_2(L1_2)
end

SetupMusic = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = pairs
  L2_2 = tRandomVO
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L5_2.sType
    if L6_2 == A0_2 then
      L6_2 = table
      L6_2 = L6_2.getn
      L7_2 = L5_2.tVO
      L6_2 = L6_2(L7_2)
      L7_2 = Math
      L7_2 = L7_2.randi
      L8_2 = 1
      L9_2 = L6_2
      L7_2 = L7_2(L8_2, L9_2)
      if A0_2 == "BoostDangers" then
        L8_2 = MrxVoSequence
        L8_2 = L8_2.Start
        L9_2 = {}
        L10_2 = L5_2.tVO
        L10_2 = L10_2[L7_2]
        L11_2 = ShowBoostTutorial
        L9_2[1] = L10_2
        L9_2[2] = L11_2
        L8_2(L9_2)
      else
        L8_2 = MrxVoSequence
        L8_2 = L8_2.Start
        L9_2 = L5_2.tVO
        L9_2 = L9_2[L7_2]
        L8_2(L9_2)
      end
    end
  end
end

PlayRandomVO = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = MrxTutorialManager
  L0_2 = L0_2.ShowMessage
  L1_2 = "[DLCCon001.UI.Boost]"
  L0_2(L1_2)
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.TimerRelative
  L2_2 = {}
  L3_2 = 10
  L2_2[1] = L3_2
  L3_2 = MrxTutorialManager
  L3_2 = L3_2.ShowMessage
  L4_2 = {}
  L5_2 = "[DLCCon001.UI.Jump]"
  L4_2[1] = L5_2
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.TimerRelative
  L2_2 = {}
  L3_2 = 20
  L2_2[1] = L3_2
  L3_2 = MrxTutorialManager
  L3_2 = L3_2.HideMessage
  L4_2 = {}
  L0_2(L1_2, L2_2, L3_2, L4_2)
end

ShowBoostTutorial = L0_1
L0_1 = {}
L1_1 = "_caracas_bld_historical04 0x0014f12f"
L2_1 = "_caracas_bld_historical04 0x0014f161"
L3_1 = "_caracas_bld_historical04 0x0014f4a5"
L4_1 = "_caracas_bld_historical05 0x0014f131"
L5_1 = "_caracas_bld_historical05 0x0014f133"
L6_1 = "_caracas_bld_historical05 0x0014f13a"
L7_1 = "_caracas_bld_historical05 0x0014f13b"
L8_1 = "_caracas_bld_historical05 0x0014f157"
L9_1 = "_caracas_bld_historical05 0x0014f158"
L10_1 = "_caracas_bld_historical05 0x0014f168"
L11_1 = "_caracas_bld_historical05 0x0014f2f9"
L12_1 = "_caracas_bld_historical05 0x0014f320"
L13_1 = "_caracas_bld_historical05 0x0014f34e"
L14_1 = "_caracas_bld_historical05 0x0014f378"
L15_1 = "_caracas_bld_historical05 0x0014f379"
L16_1 = "_caracas_bld_historical05 0x0014f48e"
L17_1 = "_caracas_bld_historical05 0x0014f48f"
L18_1 = "_caracas_bld_historical05 0x0014f4a1"
L19_1 = "_caracas_bld_historical05 0x0014f4ba"
L20_1 = "_caracas_bld_historical05 0x0014f4bb"
L21_1 = "_caracas_bld_historical05 0x0014f4de"
L22_1 = "_caracas_bld_historical05 0x00152514"
L23_1 = "_caracas_bld_skyscrapercollapsed01 0x0015260f"
L24_1 = "_caracas_bld_skyscrapercollapsed01 0x00152706"
L25_1 = "_city_bld_corner16x16a 0x0014f17d"
L26_1 = "_city_bld_corner16x16a 0x0014f279"
L27_1 = "_city_bld_corner16x16a 0x001526bb"
L28_1 = "_city_bld_corner16x16a 0x00152707"
L29_1 = "_city_bld_corner16x16b 0x0014f0fd"
L30_1 = "_city_bld_corner16x16b 0x0014f101"
L31_1 = "_city_bld_corner16x16c 0x0014efea"
L32_1 = "_city_bld_corner16x16c 0x001525ef"
L33_1 = "_city_bld_corner16x32A 0x0014f052"
L34_1 = "_city_bld_corner16x32A 0x0014f053"
L35_1 = "_city_bld_corner16x32A 0x0014f0b7"
L36_1 = "_city_bld_corner16x32A 0x0014f0b9"
L37_1 = "_city_bld_corner16x32A 0x0014f13f"
L38_1 = "_city_bld_corner16x32A 0x0014f140"
L39_1 = "_city_bld_corner16x32A 0x0014f27a"
L40_1 = "_city_bld_corner16x32A 0x0014f297"
L41_1 = "_city_bld_corner16x32A 0x0014f299"
L42_1 = "_city_bld_corner16x32A 0x001526b9"
L43_1 = "_city_bld_corner16x32B 0x0014f0fe"
L44_1 = "_city_bld_corner16x32B 0x0014f100"
L45_1 = "_city_bld_corner16x32B 0x0014f107"
L46_1 = "_city_bld_corner16x32B 0x0014f10a"
L47_1 = "_city_bld_corner16x32B 0x0014f186"
L48_1 = "_city_bld_corner16x32B 0x00152601"
L49_1 = "_city_bld_corner32x32A 0x0014f051"
L50_1 = "_city_bld_corner32x32A 0x0014f298"
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1
L0_1[5] = L5_1
L0_1[6] = L6_1
L0_1[7] = L7_1
L0_1[8] = L8_1
L0_1[9] = L9_1
L0_1[10] = L10_1
L0_1[11] = L11_1
L0_1[12] = L12_1
L0_1[13] = L13_1
L0_1[14] = L14_1
L0_1[15] = L15_1
L0_1[16] = L16_1
L0_1[17] = L17_1
L0_1[18] = L18_1
L0_1[19] = L19_1
L0_1[20] = L20_1
L0_1[21] = L21_1
L0_1[22] = L22_1
L0_1[23] = L23_1
L0_1[24] = L24_1
L0_1[25] = L25_1
L0_1[26] = L26_1
L0_1[27] = L27_1
L0_1[28] = L28_1
L0_1[29] = L29_1
L0_1[30] = L30_1
L0_1[31] = L31_1
L0_1[32] = L32_1
L0_1[33] = L33_1
L0_1[34] = L34_1
L0_1[35] = L35_1
L0_1[36] = L36_1
L0_1[37] = L37_1
L0_1[38] = L38_1
L0_1[39] = L39_1
L0_1[40] = L40_1
L0_1[41] = L41_1
L0_1[42] = L42_1
L0_1[43] = L43_1
L0_1[44] = L44_1
L0_1[45] = L45_1
L0_1[46] = L46_1
L0_1[47] = L47_1
L0_1[48] = L48_1
L0_1[49] = L49_1
L0_1[50] = L50_1
L1_1 = "_city_bld_corner32x32A 0x001551dd"
L2_1 = "_city_bld_corner32x32B 0x0014f0fc"
L3_1 = "_city_bld_corner32x32B 0x0014f0ff"
L4_1 = "_city_bld_corner32x32B 0x0014f108"
L5_1 = "_city_bld_corner32x32B 0x0014f109"
L6_1 = "_city_bld_corner32x32B 0x0014f10e"
L7_1 = "_city_bld_corner32x32B 0x0014f10f"
L8_1 = "_city_bld_corner32x32D 0x0014eff3"
L9_1 = "_city_bld_corner32x32D 0x0014f067"
L10_1 = "_city_bld_corner32x32D 0x0014f1d7"
L11_1 = "_city_bld_corner32x32D 0x00152642"
L12_1 = "_city_bld_corner32x32D 0x001526be"
L13_1 = "_city_bld_segment16x16A 0x0014eff4"
L14_1 = "_city_bld_segment16x16A 0x0014f1a9"
L15_1 = "_city_bld_segment16x16A 0x0014f218"
L16_1 = "_city_bld_segment16x16A 0x0014f23a"
L17_1 = "_city_bld_segment16x16A 0x001526bc"
L18_1 = "_city_bld_segment16x16A 0x001526bd"
L19_1 = "_city_bld_segment16x16A 0x001526e3"
L20_1 = "_city_bld_segment16x16A 0x001526e4"
L21_1 = "_city_bld_segment16x32A 0x0014f00d"
L22_1 = "_city_bld_segment16x32A 0x0014f05a"
L23_1 = "_city_bld_segment16x32A 0x0014f05c"
L24_1 = "_city_bld_segment16x32A 0x0014f063"
L25_1 = "_city_bld_segment16x32A 0x0014f065"
L26_1 = "_city_bld_segment16x32A 0x0014f094"
L27_1 = "_city_bld_segment16x32A 0x0014f095"
L28_1 = "_city_bld_segment16x32A 0x0014f0b5"
L29_1 = "_city_bld_segment16x32A 0x0014f0b6"
L30_1 = "_city_bld_segment16x32A 0x0014f103"
L31_1 = "_city_bld_segment16x32A 0x0014f105"
L32_1 = "_city_bld_segment16x32A 0x0014f10c"
L33_1 = "_city_bld_segment16x32A 0x0014f10d"
L34_1 = "_city_bld_segment16x32A 0x0014f187"
L35_1 = "_city_bld_segment16x32A 0x0014f1a5"
L36_1 = "_city_bld_segment16x32A 0x0014f217"
L37_1 = "_city_bld_segment16x32A 0x001525ee"
L38_1 = "_city_bld_segment16x32A 0x00152612"
L39_1 = "_city_bld_segment16x32A 0x00152613"
L40_1 = "_city_bld_segment16x32A 0x00152662"
L41_1 = "_city_bld_segment16x32A 0x00152665"
L42_1 = "_city_bld_segment16x32A 0x001526ba"
L43_1 = "_city_bld_segment32x32A 0x0014eff9"
L44_1 = "_city_bld_segment32x32A 0x0014f05b"
L45_1 = "_city_bld_segment32x32A 0x0014f064"
L46_1 = "_city_bld_segment32x32A 0x0014f093"
L47_1 = "_city_bld_segment32x32A 0x0014f0b4"
L48_1 = "_city_bld_segment32x32A 0x0014f104"
L49_1 = "_city_bld_segment32x32A 0x0014f10b"
L50_1 = "_city_bld_segment32x32A 0x00152611"
L0_1[51] = L1_1
L0_1[52] = L2_1
L0_1[53] = L3_1
L0_1[54] = L4_1
L0_1[55] = L5_1
L0_1[56] = L6_1
L0_1[57] = L7_1
L0_1[58] = L8_1
L0_1[59] = L9_1
L0_1[60] = L10_1
L0_1[61] = L11_1
L0_1[62] = L12_1
L0_1[63] = L13_1
L0_1[64] = L14_1
L0_1[65] = L15_1
L0_1[66] = L16_1
L0_1[67] = L17_1
L0_1[68] = L18_1
L0_1[69] = L19_1
L0_1[70] = L20_1
L0_1[71] = L21_1
L0_1[72] = L22_1
L0_1[73] = L23_1
L0_1[74] = L24_1
L0_1[75] = L25_1
L0_1[76] = L26_1
L0_1[77] = L27_1
L0_1[78] = L28_1
L0_1[79] = L29_1
L0_1[80] = L30_1
L0_1[81] = L31_1
L0_1[82] = L32_1
L0_1[83] = L33_1
L0_1[84] = L34_1
L0_1[85] = L35_1
L0_1[86] = L36_1
L0_1[87] = L37_1
L0_1[88] = L38_1
L0_1[89] = L39_1
L0_1[90] = L40_1
L0_1[91] = L41_1
L0_1[92] = L42_1
L0_1[93] = L43_1
L0_1[94] = L44_1
L0_1[95] = L45_1
L0_1[96] = L46_1
L0_1[97] = L47_1
L0_1[98] = L48_1
L0_1[99] = L49_1
L0_1[100] = L50_1
L1_1 = "_city_bld_segment32x32A 0x00152661"
L2_1 = "_city_bld_segment32x32A 0x00152664"
L3_1 = "_city_bld_segment32x32A 0x001551f0"
L4_1 = "_city_bld_skyscraper01 0x0014f066"
L5_1 = "_city_bld_skyscraper01 0x0014f13c"
L6_1 = "_city_bld_skyscraper01 0x0014f177"
L7_1 = "_city_bld_skyscraper01 0x0014f17e"
L8_1 = "_city_bld_skyscraper01 0x0014f183"
L9_1 = "_city_bld_skyscraper01 0x0014f22b"
L10_1 = "_city_bld_skyscraper01 0x0015263f"
L11_1 = "_city_bld_skyscraper03 0x0014efff"
L12_1 = "_city_bld_skyscraper03 0x0014f0f7"
L13_1 = "_city_bld_skyscraper03 0x0014f0fb"
L14_1 = "_city_bld_skyscraper03 0x0014f176"
L0_1[101] = L1_1
L0_1[102] = L2_1
L0_1[103] = L3_1
L0_1[104] = L4_1
L0_1[105] = L5_1
L0_1[106] = L6_1
L0_1[107] = L7_1
L0_1[108] = L8_1
L0_1[109] = L9_1
L0_1[110] = L10_1
L0_1[111] = L11_1
L0_1[112] = L12_1
L0_1[113] = L13_1
L0_1[114] = L14_1
tTargetLocations = L0_1
L0_1 = {}
L1_1 = {}
L1_1.sType = "Timed"
L2_1 = {}
L3_1 = "Fiona-In-Mission-Contract-Dlc01-22"
L4_1 = "Fiona-In-Mission-Contract-Dlc01-23"
L5_1 = "Fiona-In-Mission-Contract-Dlc01-24"
L6_1 = "Fiona-In-Mission-Contract-Dlc01-25"
L7_1 = "Fiona-In-Mission-Contract-Dlc01-26"
L8_1 = "Fiona-In-Mission-Contract-Dlc01-27"
L9_1 = "Fiona-In-Mission-Contract-Dlc01-04"
L10_1 = "Fiona-In-Mission-Contract-Dlc01-28"
L11_1 = "Fiona-In-Mission-Contract-Dlc01-29"
L12_1 = "Fiona-In-Mission-Contract-Dlc01-30"
L13_1 = "Fiona-In-Mission-Contract-Dlc01-31"
L14_1 = "Fiona-In-Mission-Contract-Dlc01-32"
L15_1 = "Fiona-In-Mission-Contract-Dlc01-35"
L16_1 = "Fiona-In-Mission-Contract-Dlc01-06"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L2_1[4] = L6_1
L2_1[5] = L7_1
L2_1[6] = L8_1
L2_1[7] = L9_1
L2_1[8] = L10_1
L2_1[9] = L11_1
L2_1[10] = L12_1
L2_1[11] = L13_1
L2_1[12] = L14_1
L2_1[13] = L15_1
L2_1[14] = L16_1
L1_1.tVO = L2_1
L2_1 = {}
L2_1.sType = "ContractComplete"
L3_1 = {}
L4_1 = "Fiona-In-Mission-Contract-Chi02-08"
L5_1 = "Fiona.vo2fio38"
L6_1 = "Fiona.jobscomplete02"
L7_1 = "Fiona.Race.DoingGreat04"
L8_1 = "Fiona.Wager.Win01"
L9_1 = "Fiona.Wager.Winning01"
L10_1 = "Fiona.Acheivements.NothingButGoodTime01"
L11_1 = "Fiona.Misc.ChickenReaction01"
L12_1 = "Fiona.Cam.01"
L13_1 = "Fiona.Cam.06"
L14_1 = "Fiona.Cam.02"
L15_1 = "Fiona-In-Mission-Contract-All01-26"
L16_1 = "Fiona-In-Mission-Job-All03-08"
L17_1 = "Fiona-In-Mission-Job-All10-10"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L3_1[4] = L7_1
L3_1[5] = L8_1
L3_1[6] = L9_1
L3_1[7] = L10_1
L3_1[8] = L11_1
L3_1[9] = L12_1
L3_1[10] = L13_1
L3_1[11] = L14_1
L3_1[12] = L15_1
L3_1[13] = L16_1
L3_1[14] = L17_1
L2_1.tVO = L3_1
L3_1 = {}
L3_1.sType = "ContractCanceled"
L4_1 = {}
L5_1 = "Fiona-In-Mission-Contract-All04-14"
L4_1[1] = L5_1
L3_1.tVO = L4_1
L4_1 = {}
L4_1.sType = "TargetNear"
L5_1 = {}
L6_1 = "Fiona-None-Freeplay-None-12"
L7_1 = "Fiona-None-Freeplay-None-02"
L8_1 = "Fiona-None-Freeplay-None-19"
L9_1 = "Fiona-None-Freeplay-None-05"
L10_1 = "Fiona-None-Freeplay-None-11"
L11_1 = "Fiona-None-Freeplay-None-07"
L5_1[1] = L6_1
L5_1[2] = L7_1
L5_1[3] = L8_1
L5_1[4] = L9_1
L5_1[5] = L10_1
L5_1[6] = L11_1
L4_1.tVO = L5_1
L5_1 = {}
L5_1.sType = "TargetDestroyed"
L6_1 = {}
L7_1 = "Fiona-In-Mission-Job-Chi07-06"
L8_1 = "Fiona-In-Mission-Job-Chi10-10"
L9_1 = "Fiona-In-Mission-Job-Chi10-07"
L10_1 = "Fiona-In-Mission-Job-Chi10-08"
L11_1 = "Fiona-In-Mission-Job-All05-06"
L6_1[1] = L7_1
L6_1[2] = L8_1
L6_1[3] = L9_1
L6_1[4] = L10_1
L6_1[5] = L11_1
L5_1.tVO = L6_1
L6_1 = {}
L6_1.sType = "ReactorHealthLow"
L7_1 = {}
L8_1 = "Fiona-In-Mission-Contract-Dlc01-17"
L9_1 = "Fiona-In-Mission-Contract-Dlc01-18"
L10_1 = "Fiona-In-Mission-Contract-Dlc01-19"
L11_1 = "Fiona-In-Mission-Contract-Dlc01-20"
L12_1 = "Fiona-In-Mission-Contract-Dlc01-21"
L7_1[1] = L8_1
L7_1[2] = L9_1
L7_1[3] = L10_1
L7_1[4] = L11_1
L7_1[5] = L12_1
L6_1.tVO = L7_1
L7_1 = {}
L7_1.sType = "TargetSwap"
L8_1 = {}
L9_1 = "Fiona-In-Mission-Contract-Dlc01-38"
L10_1 = "Fiona-In-Mission-Contract-Dlc01-39"
L11_1 = "Fiona-In-Mission-Contract-Dlc01-40"
L12_1 = "Fiona-In-Mission-Contract-Dlc01-41"
L13_1 = "Fiona-In-Mission-Contract-Dlc01-42"
L14_1 = "Fiona-In-Mission-Contract-Dlc01-43"
L15_1 = "Fiona-In-Mission-Contract-Dlc01-44"
L8_1[1] = L9_1
L8_1[2] = L10_1
L8_1[3] = L11_1
L8_1[4] = L12_1
L8_1[5] = L13_1
L8_1[6] = L14_1
L8_1[7] = L15_1
L7_1.tVO = L8_1
L8_1 = {}
L8_1.sType = "BoostDangers"
L9_1 = {}
L10_1 = "Fiona-In-Mission-Contract-Dlc01-08"
L11_1 = "Fiona-In-Mission-Contract-Dlc01-09"
L12_1 = "Fiona-In-Mission-Contract-Dlc01-10"
L13_1 = "Fiona-In-Mission-Contract-Dlc01-11"
L14_1 = "Fiona-In-Mission-Contract-Dlc01-12"
L9_1[1] = L10_1
L9_1[2] = L11_1
L9_1[3] = L12_1
L9_1[4] = L13_1
L9_1[5] = L14_1
L8_1.tVO = L9_1
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1
L0_1[5] = L5_1
L0_1[6] = L6_1
L0_1[7] = L7_1
L0_1[8] = L8_1
tRandomVO = L0_1
