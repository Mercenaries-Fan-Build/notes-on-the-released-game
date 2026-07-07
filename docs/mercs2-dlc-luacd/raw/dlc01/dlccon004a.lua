local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1, L18_1, L19_1, L20_1, L21_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = inherit
L1_1 = "DangerousBuilding"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "DLCCopterDrop"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "DLCEscalation"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "DLCComboMeter"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "WifVzBoundary"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "DLCCon004_Cash"
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
L1_1 = "DlcCopterDrop"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxMusic"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "dlc_moonpatrol"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
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
L4_1 = "Car"
L5_1 = "M151 .50Cal (VZ) (DriverGunner)"
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
L5_1 = "Car"
L6_1 = 2
L4_1[1] = L5_1
L4_1[2] = L6_1
L3_1.tDensity = L4_1
L2_1[1] = L3_1
L3_1 = {}
L4_1 = {}
L4_1.sCommand = "RemoveTemplate"
L5_1 = {}
L6_1 = "Driving"
L7_1 = "Stopped"
L8_1 = "Offroad"
L5_1[1] = L6_1
L5_1[2] = L7_1
L5_1[3] = L8_1
L4_1.tSituation = L5_1
L4_1.tTemplate = "M151 Softtop (VZ) (Driver)"
L3_1[1] = L4_1
L4_1 = {}
L5_1 = {}
L6_1 = {}
L6_1.sCommand = "AddTemplate"
L7_1 = {}
L8_1 = "Driving"
L9_1 = "Stopped"
L10_1 = "Offroad"
L11_1 = "Tank"
L7_1[1] = L8_1
L7_1[2] = L9_1
L7_1[3] = L10_1
L7_1[4] = L11_1
L6_1.tSituation = L7_1
L7_1 = {}
L8_1 = "Tank"
L9_1 = "Scorpion90 (Full)"
L10_1 = 1
L7_1[1] = L8_1
L7_1[2] = L9_1
L7_1[3] = L10_1
L6_1.tTemplate = L7_1
L7_1 = {}
L8_1 = "Tank"
L9_1 = 1
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
L9_1 = "Car"
L10_1 = 4
L8_1[1] = L9_1
L8_1[2] = L10_1
L7_1.tDensity = L8_1
L6_1[1] = L7_1
L7_1 = {}
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
L12_1 = 2
L10_1[1] = L11_1
L10_1[2] = L12_1
L9_1.tDensity = L10_1
L8_1[1] = L9_1
L9_1 = {}
L10_1 = {}
L10_1.sCommand = "AddTemplate"
L11_1 = {}
L12_1 = "Heli"
L13_1 = "Stopped"
L11_1[1] = L12_1
L11_1[2] = L13_1
L10_1.tSituation = L11_1
L11_1 = {}
L12_1 = "Heli"
L13_1 = "Alouette3 Elite (Driver)"
L14_1 = 1
L11_1[1] = L12_1
L11_1[2] = L13_1
L11_1[3] = L14_1
L10_1.tTemplate = L11_1
L11_1 = {}
L12_1 = "Heli"
L13_1 = 1
L11_1[1] = L12_1
L11_1[2] = L13_1
L10_1.tDensity = L11_1
L9_1[1] = L10_1
L10_1 = {}
L11_1 = {}
L11_1.sCommand = "AddTemplate"
L12_1 = {}
L13_1 = "Driving"
L14_1 = "Offroad"
L12_1[1] = L13_1
L12_1[2] = L14_1
L11_1.tSituation = L12_1
L12_1 = {}
L13_1 = "Heli"
L14_1 = "Alouette3 Elite (Driver)"
L15_1 = 1
L12_1[1] = L13_1
L12_1[2] = L14_1
L12_1[3] = L15_1
L11_1.tTemplate = L12_1
L12_1 = {}
L13_1 = "Heli"
L14_1 = 1
L12_1[1] = L13_1
L12_1[2] = L14_1
L11_1.tDensity = L12_1
L10_1[1] = L11_1
L11_1 = {}
L12_1 = {}
L13_1 = {}
L14_1 = {}
L15_1 = {}
L16_1 = {}
L17_1 = {}
L18_1 = {}
L19_1 = {}
L20_1 = {}
L21_1 = {}
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
tLocalEscalationTable = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = {}
  L2_2 = "DLC01_DlcCon004"
  L1_2[1] = L2_2
  L2_2 = Net
  L2_2 = L2_2.IsClient
  L2_2 = L2_2()
  if not L2_2 then
    L2_2 = MrxLayerManager
    L2_2 = L2_2.Add
    L3_2 = L1_2
    L4_2 = LoadAssets2
    L5_2 = {}
    L6_2 = A0_2
    L5_2[1] = L6_2
    L2_2(L3_2, L4_2, L5_2)
  end
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = EquipWeapons
  L2_2 = A0_2
  L3_2 = Player
  L3_2 = L3_2.GetLocalCharacter
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L3_2()
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "DLCCON004_UberPanhard_01"
  L1_2 = L1_2(L2_2)
  L2_2 = Object
  L2_2 = L2_2.IsHibernated
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2._CreateEvent
    L4_2 = Event
    L4_2 = L4_2.ObjectHibernation
    L5_2 = {}
    L6_2 = L1_2
    L7_2 = "awake"
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L6_2 = A0_2.AssetsLoaded
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  else
    L3_2 = A0_2
    L2_2 = A0_2.AssetsLoaded
    L2_2(L3_2)
  end
end

LoadAssets2 = L0_1

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
  L1_2 = DLCEscalation
  L2_2 = tLocalEscalationTable
  L1_2.tEscalationTable = L2_2
  L1_2 = 0
  nTimeRemaining = L1_2
  L1_2 = 0
  nLocalBldgCount = L1_2
  L1_2 = 0
  nCollectedTimePickups = L1_2
  L1_2 = false
  bEnteredVehicle = L1_2
  L1_2 = nil
  uDeadUberVehicle = L1_2
  L1_2 = 0
  nTotalCash = L1_2
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
  L4_2[1] = L5_2
  L5_2 = {}
  L6_2 = {}
  L7_2 = "Car"
  L8_2 = 3
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
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
  L5_2[1] = L6_2
  L6_2 = {}
  L7_2 = {}
  L8_2 = "Car"
  L9_2 = 3
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L6_2[1] = L7_2
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
  L5_2 = {}
  L6_2 = "Heli"
  L7_2 = {}
  L8_2 = {}
  L9_2 = "Tank"
  L10_2 = "M113 AA (VZ) (Full)"
  L11_2 = 1
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L7_2[1] = L8_2
  L8_2 = {}
  L9_2 = {}
  L10_2 = "Tank"
  L11_2 = 1
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L8_2[1] = L9_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L6_2 = {}
  L7_2 = "Tank"
  L8_2 = {}
  L9_2 = {}
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  tLocalPursuitTable = L1_2
  L1_2 = DLCEscalation
  L2_2 = tLocalPursuitTable
  L1_2.tPursuitTable = L2_2
  L1_2 = WifVzBoundary
  L1_2 = L1_2.SetupBoundary
  L2_2 = "RGN_DLCCON004_Boundary"
  L3_2 = false
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetNumCompletions
  L1_2 = L1_2(L2_2)
  L2_2 = DangerousBuilding
  L2_2 = L2_2.SetRarity
  L3_2 = "all"
  L4_2 = "always"
  L2_2(L3_2, L4_2)
  L2_2 = DLCComboMeter
  L2_2 = L2_2.Combo_Init
  L3_2 = A0_2
  L4_2 = Player
  L4_2 = L4_2.GetLocalPlayer
  L4_2 = L4_2()
  L5_2 = 5
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  A0_2.tComboData = L2_2
  L2_2 = MrxTimer
  L3_2 = L2_2
  L2_2 = L2_2.Create
  L4_2 = {}
  L4_2.nStartTime = 120
  L4_2.nWarning = 30
  L4_2.iTray = 2
  L5_2 = {}
  L6_2 = {}
  L7_2 = _RoundComplete
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tDoneCallbacks = L5_2
  L5_2 = {}
  L6_2 = {}
  L7_2 = _TimeWarningVo
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tWarnCallbacks = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  oMyTimer = L2_2
  L2_2 = oMyTimer
  L3_2 = L2_2
  L2_2 = L2_2.Start
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreatePersistentEvent
  L4_2 = Event
  L4_2 = L4_2.ScriptEvent
  L5_2 = {}
  L6_2 = "TimeAdded"
  
  function L7_2(A0_3)
    local L1_3, L2_3
    L1_3 = oMyTimer
    L2_3 = L1_3
    L1_3 = L1_3.GetTime
    L1_3 = L1_3(L2_3)
    L1_3 = 0 < L1_3
    return L1_3
  end
  
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = _AddTime
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = oMyTimer
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  eTimeAdded = L2_2
  L2_2 = DLCEscalation
  L2_2 = L2_2.StartPursuit
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = InitCashCollectionRound
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "DLCCON004_UberPanhard_01"
  L2_2 = L2_2(L3_2)
  L4_2 = A0_2
  L3_2 = A0_2.OnPlayerExitVehicle
  L5_2 = L2_2
  L3_2(L4_2, L5_2)
  L4_2 = A0_2
  L3_2 = A0_2.SetupVehicleDeathEvent
  L5_2 = L2_2
  L3_2(L4_2, L5_2)
  L3_2 = dlc_moonpatrol
  L3_2 = L3_2.SetImpulse
  L4_2 = 8.5
  L3_2(L4_2)
  L3_2 = dlc_moonpatrol
  L3_2 = L3_2.SetPosition
  L4_2 = 0.05
  L3_2(L4_2)
end

Activated = L0_1

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
  local L1_2, L2_2, L3_2
  L1_2 = oMyTimer
  L2_2 = L1_2
  L1_2 = L1_2.Stop
  L1_2(L2_2)
  L1_2 = A0_2.oScoreBoard
  if L1_2 then
    L1_2 = A0_2.oScoreBoard
    L2_2 = L1_2
    L1_2 = L1_2.Close
    L1_2(L2_2)
    A0_2.oScoreBoard = nil
  end
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = eCashPickup
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = eTimeAdded
  L1_2(L2_2)
  L1_2 = DLCCon004_Cash
  L1_2 = L1_2.Cleanup
  L1_2()
  L1_2 = DLCEscalation
  L1_2 = L1_2.ClearPursuit
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = DLCComboMeter
  L1_2 = L1_2.Combo_Cleanup
  L2_2 = A0_2.tComboData
  L1_2(L2_2)
  L1_2 = RestoreWeapons
  L2_2 = A0_2
  L3_2 = Player
  L3_2 = L3_2.GetLocalCharacter
  L3_2 = L3_2()
  L1_2(L2_2, L3_2)
  L1_2 = WifVzBoundary
  L1_2 = L1_2.RemoveWorldBoundary
  L1_2()
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2 = L1_2()
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L5_2 = DLCCopterDrop
  L5_2 = L5_2.Create
  L6_2 = "GR"
  L7_2 = A0_2
  L8_2 = L2_2
  L9_2 = L3_2
  L10_2 = L4_2
  L11_2 = true
  L5_2, L6_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  L7_2 = table
  L7_2 = L7_2.insert
  L8_2 = tPlacedUberVehicles
  L9_2 = tostring
  L10_2 = L6_2
  L9_2, L10_2, L11_2, L12_2 = L9_2(L10_2)
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L7_2 = Hud
  L7_2 = L7_2.Radar
  L8_2 = L7_2
  L7_2 = L7_2.AddObjective
  L9_2 = {}
  L10_2 = "UberVehicle"
  L11_2 = tostring
  L12_2 = L6_2
  L11_2 = L11_2(L12_2)
  L10_2 = L10_2 .. L11_2
  L9_2.sName = L10_2
  L9_2.uGuid = L6_2
  L9_2.nR = 255
  L9_2.nG = 255
  L9_2.nB = 0
  L9_2.nWidth = 8
  L9_2.nHeight = 8
  L9_2.sTexture = "objective_action"
  L9_2.bSticky = true
  L9_2.bDontNetSync = true
  L7_2(L8_2, L9_2)
end

RespawnUberVehicle = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = 250000
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "Destroy"
  L4_2.sModuleName = "MrxTaskObjective"
  L4_2.sDspShortDesc = "[DLCCon004.UI.ObjFanfare1]"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "Collect"
  L4_2.sModuleName = "MrxTaskObjective"
  L4_2.sDspShortDesc = "[DLCCon004.UI.ObjFanfare2]"
  L2_2(L3_2, L4_2)
  L2_2 = MrxVoSequence
  L2_2 = L2_2.Start
  L3_2 = {}
  L4_2 = "Fiona-In-Mission-Contract-Dlc04-16"
  L3_2[1] = L4_2
  L2_2(L3_2)
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "Arena_01"
  L2_2 = L2_2(L3_2)
  L3_2 = Object
  L3_2 = L3_2.GetPosition
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  L6_2 = Event
  L6_2 = L6_2.CreatePersistent
  L7_2 = Event
  L7_2 = L7_2.ScriptEvent
  L8_2 = {}
  L9_2 = "CashPickup"
  
  function L10_2(A0_3)
    local L1_3
    L1_3 = true
    return L1_3
  end
  
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  
  function L9_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3
    L1_3 = A0_3[1]
    L2_3 = 0
    if L1_3 == 1 then
      L3_3 = A0_2
      L3_3 = L3_3.tComboData
      L3_3 = L3_3.nCombo
      L2_3 = 1000 * L3_3
    elseif L1_3 == 3 then
      L3_3 = A0_2
      L3_3 = L3_3.tComboData
      L3_3 = L3_3.nCombo
      L2_3 = 10000 * L3_3
    elseif L1_3 == 5 then
      L3_3 = A0_2
      L3_3 = L3_3.tComboData
      L3_3 = L3_3.nCombo
      L2_3 = 50000 * L3_3
    end
    L3_3 = MrxPmc
    L3_3 = L3_3.AddCashQty
    L4_3 = L2_3
    L5_3 = true
    L6_3 = "[DLCCon004.UI.CashPickedUp]"
    L3_3(L4_3, L5_3, L6_3)
    L3_3 = Player
    L3_3 = L3_3.GetCash
    L3_3 = L3_3()
    L4_3 = L1_2
    if L3_3 >= L4_3 then
      L3_3 = "[green][DLCCon004.UI.CompletionFanfare] "
      L4_3 = MrxUtil
      L4_3 = L4_3.FormatMoney
      L5_3 = L1_2
      L4_3 = L4_3(L5_3)
      L3_3 = L3_3 .. L4_3
      L4_3 = MessageBox
      L5_3 = L4_3
      L4_3 = L4_3.AddMessage
      L6_3 = L3_3
      L7_3 = 0
      L8_3 = 5
      L9_3 = 0
      L10_3 = nil
      L11_3 = true
      L12_3 = nil
      L4_3(L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3)
      L4_3 = L1_2
      L4_3 = L4_3 * 2
      L1_2 = L4_3
    end
  end
  
  L10_2 = {}
  L11_2 = tData
  L10_2[1] = L11_2
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
  eCashPickup = L6_2
end

InitCashCollectionRound = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L1_2 = MrxPmc
  L1_2 = L1_2.GetCashQty
  L1_2 = L1_2()
  L2_2 = DLCComboMeter
  L2_2 = L2_2.nCurDestroyedBldgs
  L3_2 = DLCComboMeter
  L3_2 = L3_2.nPeakCombo
  L2_2 = L2_2 * L3_2
  L2_2 = L2_2 * 500
  L3_2 = MrxPmc
  L3_2 = L3_2.AddCashQty
  L4_2 = L2_2
  L5_2 = "[DLCCon003.Display.scoreBonus]"
  L3_2(L4_2, L5_2)
  L3_2 = L1_2 + L2_2
  L4_2 = MrxPmc
  L4_2 = L4_2.GetCashQty
  L4_2 = L4_2()
  L4_2 = L4_2 - L3_2
  L5_2 = ""
  if L4_2 < 0 then
    L5_2 = "-"
  end
  L6_2 = "[DLCCon004.UI.score_collectedCash]: "
  L7_2 = MrxUtil
  L7_2 = L7_2.FormatMoney
  L8_2 = L1_2
  L7_2 = L7_2(L8_2)
  L8_2 = "[n][DLCCon004.UI.score_comboBonus]: "
  L9_2 = MrxUtil
  L9_2 = L9_2.FormatMoney
  L10_2 = L2_2
  L9_2 = L9_2(L10_2)
  L10_2 = "[n][Scoring.Misc]: "
  L11_2 = L5_2
  L12_2 = MrxUtil
  L12_2 = L12_2.FormatMoney
  L13_2 = math
  L13_2 = L13_2.abs
  L14_2 = L4_2
  L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2 = L13_2(L14_2)
  L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
  L13_2 = "[n][green][Scoring.Total]: "
  L14_2 = MrxUtil
  L14_2 = L14_2.FormatMoney
  L15_2 = MrxPmc
  L15_2 = L15_2.GetCashQty
  L15_2, L16_2, L17_2, L18_2, L19_2 = L15_2()
  L14_2 = L14_2(L15_2, L16_2, L17_2, L18_2, L19_2)
  L15_2 = "[n]"
  L6_2 = L6_2 .. L7_2 .. L8_2 .. L9_2 .. L10_2 .. L11_2 .. L12_2 .. L13_2 .. L14_2 .. L15_2
  L7_2 = MrxGui
  L7_2 = L7_2.DisplayDialogBox
  L8_2 = Player
  L8_2 = L8_2.GetPrimaryPlayer
  L8_2 = L8_2()
  L9_2 = L6_2
  L10_2 = {}
  L11_2 = nil
  L12_2 = A0_2.Complete
  L13_2 = {}
  L14_2 = A0_2
  L13_2[1] = L14_2
  L14_2 = nil
  L15_2 = nil
  L16_2 = "center"
  L17_2 = "center"
  L18_2 = true
  L19_2 = nil
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
  A0_2.oScoreBoard = L7_2
  L7_2 = Net
  L7_2 = L7_2.LeaderboardPushScore
  L8_2 = "DlcCon004"
  L9_2 = MrxPmc
  L9_2 = L9_2.GetCashQty
  L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2 = L9_2()
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
  L7_2 = DLC01_MissionHub
  L7_2 = L7_2.SetPrevBest
  L8_2 = "DlcCon004"
  L9_2 = MrxPmc
  L9_2 = L9_2.GetCashQty
  L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2 = L9_2()
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
end

_RoundComplete = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = {}
  L1_2 = "Fiona-In-Mission-Contract-Dlc04-01"
  L2_2 = "Fiona-In-Mission-Contract-Dlc04-02"
  L3_2 = "Fiona-In-Mission-Contract-Dlc04-03"
  L0_2[1] = L1_2
  L0_2[2] = L2_2
  L0_2[3] = L3_2
  L1_2 = PlayRandomVo
  L2_2 = L0_2
  L3_2 = 1
  L1_2(L2_2, L3_2)
end

_TimeWarningVo = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L4_2 = A1_2
  L3_2 = A1_2.AddTime
  L5_2 = A2_2[1]
  L3_2(L4_2, L5_2)
  L3_2 = MessageBox
  L4_2 = L3_2
  L3_2 = L3_2.AddMessage
  L5_2 = "[green] [DLCCon004.UI.TimeExtended]"
  L6_2 = 0
  L7_2 = 4
  L8_2 = 0
  L9_2 = nil
  L10_2 = true
  L11_2 = nil
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  L3_2 = nCollectedTimePickups
  L3_2 = L3_2 + 1
  nCollectedTimePickups = L3_2
  L3_2 = DLCEscalation
  L3_2 = L3_2.ParseEscalationTable
  L4_2 = nCollectedTimePickups
  L3_2(L4_2)
  L3_2 = {}
  L4_2 = "Fiona-In-Mission-Contract-Dlc04-11"
  L5_2 = "Fiona-In-Mission-Contract-Dlc04-12"
  L6_2 = "Fiona-In-Mission-Contract-Dlc04-13"
  L7_2 = "Fiona-In-Mission-Contract-Dlc04-14"
  L8_2 = "Fiona-In-Mission-Contract-Dlc04-15"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L3_2[5] = L8_2
  L4_2 = Sound
  L4_2 = L4_2.CueSound
  L5_2 = 0
  L6_2 = "clockBell"
  L4_2(L5_2, L6_2)
  L4_2 = A0_2._tEvents
  L5_2 = Event
  L5_2 = L5_2.Create
  L6_2 = Event
  L6_2 = L6_2.TimerRelative
  L7_2 = {}
  L8_2 = 0.8
  L7_2[1] = L8_2
  L8_2 = PlayRandomVo
  L9_2 = {}
  L10_2 = L3_2
  L11_2 = 0.25
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L4_2.eTimePickupVo = L5_2
end

_AddTime = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2.tWeaponTables
  if not L2_2 then
    L2_2 = {}
  end
  A0_2.tWeaponTables = L2_2
  L2_2 = A0_2.tWeaponTables
  L3_2 = Human
  L3_2 = L3_2.Inventory
  L3_2 = L3_2.GetAllWeapons
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L2_2[A1_2] = L3_2
  L2_2 = {}
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "Fuel-Air RPG"
  L3_2 = L3_2(L4_2)
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "Grenade"
  L4_2 = L4_2(L5_2)
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "C4"
  L5_2, L6_2 = L5_2(L6_2)
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L3_2 = Human
  L3_2 = L3_2.Inventory
  L3_2 = L3_2.SetAllWeapons
  L4_2 = A1_2
  L5_2 = L2_2
  L3_2(L4_2, L5_2)
  L3_2 = Object
  L3_2 = L3_2.SetInfiniteAmmo
  L4_2 = A1_2
  L5_2 = true
  L3_2(L4_2, L5_2)
end

EquipWeapons = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2.tWeaponTables
  L2_2 = L2_2[A1_2]
  if L2_2 then
    L3_2 = Human
    L3_2 = L3_2.Inventory
    L3_2 = L3_2.SetAllWeapons
    L4_2 = A1_2
    L5_2 = {}
    L6_2 = L2_2
    L5_2[1] = L6_2
    L3_2(L4_2, L5_2)
  end
  L3_2 = Object
  L3_2 = L3_2.SetInfiniteAmmo
  L4_2 = A1_2
  L5_2 = false
  L3_2(L4_2, L5_2)
end

RestoreWeapons = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = math
  L2_2 = L2_2.randf
  L2_2 = L2_2()
  if A1_2 > L2_2 then
    L2_2 = MrxUtil
    L2_2 = L2_2.GetRandomTableElement
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    L3_2 = MrxVoSequence
    L3_2 = L3_2.Start
    L4_2 = {}
    L5_2 = L2_2
    L4_2[1] = L5_2
    L3_2(L4_2)
  end
end

PlayRandomVo = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = Object
  L2_2 = L2_2.GetHealth
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  L3_2 = type
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if L3_2 == "number" and 0 < L2_2 then
    L4_2 = A0_2
    L3_2 = A0_2.CreateChild
    L5_2 = {}
    L5_2.sName = "Enter car"
    L5_2.sModuleName = "MrxTaskObjectiveEnterVehicle"
    L5_2.sDspShortDesc = "[MecCon001.Objectives.enterVehicle]"
    L5_2.vTgtInclude = A1_2
    
    function L6_2()
      local L0_3, L1_3, L2_3
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3.OnPlayerEnterVehicle
      L2_3 = A1_2
      L0_3(L1_3, L2_3)
    end
    
    L5_2.fOnComplete = L6_2
    L3_2 = L3_2(L4_2, L5_2)
  end
  L3_2 = MrxMusic
  L3_2 = L3_2.PlaySpecialMusic
  L4_2 = "Dlc_mu_ed_elevator-01"
  L3_2(L4_2)
end

OnPlayerExitVehicle = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2._tEvents
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectInSeat
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAnyCharacter
  L6_2 = L6_2()
  L7_2 = A1_2
  L8_2 = "d"
  L9_2 = "x"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L6_2 = OnPlayerExitVehicle
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A1_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2.eEnterUberVeh = L3_2
  L2_2 = MrxMusic
  L2_2 = L2_2.PlaySpecialMusic
  L3_2 = "Dlc_mu_ed_rock-02"
  L2_2(L3_2)
  L2_2 = bEnteredVehicle
  if L2_2 == false then
    L2_2 = Event
    L2_2 = L2_2.Create
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = 5
    L4_2[1] = L5_2
    L5_2 = MrxTutorialManager
    L5_2 = L5_2.ShowMessage
    L6_2 = "[DLCCon001.UI.Jump]"
    L5_2, L6_2, L7_2, L8_2, L9_2 = L5_2(L6_2)
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
    L2_2 = Event
    L2_2 = L2_2.Create
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = 15
    L4_2[1] = L5_2
    L5_2 = MrxTutorialManager
    L5_2 = L5_2.HideMessage
    L6_2 = {}
    L2_2(L3_2, L4_2, L5_2, L6_2)
    L2_2 = true
    bEnteredVehicle = L2_2
  end
end

OnPlayerEnterVehicle = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2._tEvents
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectDeath
  L5_2 = {}
  L6_2 = A1_2
  L5_2[1] = L6_2
  L6_2 = RespawnVehicle
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = false
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2.eVehicleDestroyed = L3_2
  L2_2 = A0_2._tEvents
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectPhysicsEvent
  L5_2 = {}
  L6_2 = A1_2
  L7_2 = "VehicleSinking"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = RespawnVehicle
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = true
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2.eVehicleSunk = L3_2
end

SetupVehicleDeathEvent = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2
  L3_2 = Event
  L3_2 = L3_2.Delete
  L4_2 = A0_2._tEvents
  L4_2 = L4_2.eVehicleDestroyed
  L3_2(L4_2)
  L3_2 = Event
  L3_2 = L3_2.Delete
  L4_2 = A0_2._tEvents
  L4_2 = L4_2.eVehicleSunk
  L3_2(L4_2)
  L3_2 = A2_2
  if A1_2 then
    L4_2 = Player
    L4_2 = L4_2.GetPrimaryCharacter
    L4_2 = L4_2()
    L3_2 = L4_2
  end
  L4_2 = Object
  L4_2 = L4_2.GetPosition
  L5_2 = L3_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  L7_2 = "global_particle_flaresmoke_green"
  L8_2 = Pg
  L8_2 = L8_2.Spawn
  L9_2 = L7_2
  L10_2 = L4_2
  L11_2 = L5_2
  L12_2 = L6_2
  L8_2(L9_2, L10_2, L11_2, L12_2)
  L8_2 = DlcCopterDrop
  L8_2 = L8_2.Create
  L9_2 = "PMC"
  L10_2 = "Panhard (DLCCON004)"
  L11_2 = L4_2
  L12_2 = L5_2
  L13_2 = L6_2
  L14_2 = true
  L8_2, L9_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L10_2 = {}
  L11_2 = "Fiona-In-Mission-Contract-Dlc04-07"
  L12_2 = "Fiona-In-Mission-Contract-Dlc04-08"
  L13_2 = "Fiona-In-Mission-Contract-Dlc04-09"
  L14_2 = "Fiona-In-Mission-Contract-Dlc04-10"
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L11_2 = PlayRandomVo
  L12_2 = L10_2
  L13_2 = 1
  L11_2(L12_2, L13_2)
  L12_2 = A0_2
  L11_2 = A0_2.SetupVehicleDeathEvent
  L13_2 = L9_2
  L11_2(L12_2, L13_2)
  L12_2 = A0_2
  L11_2 = A0_2._CreateEvent
  L13_2 = Event
  L13_2 = L13_2.ObjectProximity
  L14_2 = {}
  L15_2 = L9_2
  L16_2 = L4_2
  L17_2 = L5_2
  L18_2 = L6_2
  L19_2 = "<"
  L20_2 = 20
  L21_2 = false
  L22_2 = false
  L14_2[1] = L15_2
  L14_2[2] = L16_2
  L14_2[3] = L17_2
  L14_2[4] = L18_2
  L14_2[5] = L19_2
  L14_2[6] = L20_2
  L14_2[7] = L21_2
  L14_2[8] = L22_2
  L15_2 = OnPlayerExitVehicle
  L16_2 = {}
  L17_2 = A0_2
  L18_2 = L9_2
  L16_2[1] = L17_2
  L16_2[2] = L18_2
  L11_2(L12_2, L13_2, L14_2, L15_2, L16_2)
end

RespawnVehicle = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "You Ran Out of Time"
  L1_2(L2_2, L3_2)
  L1_2 = Combo_Cleanup
  L2_2 = A0_2.tComboData
  L1_2(L2_2)
  L1_2 = A0_2.Cancel
  L2_2 = A0_2
  L1_2(L2_2)
end

_TimerUp = L0_1
