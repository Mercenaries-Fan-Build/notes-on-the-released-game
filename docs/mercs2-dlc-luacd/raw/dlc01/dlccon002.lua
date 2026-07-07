local L0_1, L1_1, L2_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxTaskRace"
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
L1_1 = "MrxUtil"
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
L0_1 = 10000
kTimeCash = L0_1
L0_1 = 2000
kVZSoldierCash = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = {}
  L3_2 = "DLC01_DLCCon002_Race"
  L2_2[1] = L3_2
  L3_2 = MrxLayerManager
  L3_2 = L3_2.Add
  L4_2 = L2_2
  L5_2 = A0_2.LoadAssets2
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L3_2(L4_2, L5_2, L6_2)
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "Monster1"
  L1_2 = L1_2(L2_2)
  uTruck = L1_2
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
    
    function L6_2()
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
    
    L2_2(L3_2, L4_2, L5_2, L6_2)
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

LoadAssets2 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
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
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Oil020-12"
  L2_2[1] = L3_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.StartRace
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.CheckPointVO
  L1_2(L2_2)
  L1_2 = MrxMusic
  L1_2 = L1_2.PlaySpecialMusic
  L2_2 = "Dlc_mu_ali"
  L1_2(L2_2)
  L1_2 = 0
  nVZSoldierCounter = L1_2
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2 = L1_2()
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "Monster1"
  L2_2 = L2_2(L3_2)
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectInSeat
  L5_2 = {}
  L6_2 = L1_2
  L7_2 = L2_2
  L8_2 = "D"
  L9_2 = "E"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  
  function L6_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = Hud
    L0_3 = L0_3.ObjectiveTray
    L1_3 = L0_3
    L0_3 = L0_3.SetSlotToText
    L2_3 = {}
    L2_3.nSlot = 2
    L3_3 = "[DLCCon002.UI.KillCounter] "
    L4_3 = nVZSoldierCounter
    L3_3 = L3_3 .. L4_3
    L2_3.sText = L3_3
    L0_3(L1_3, L2_3)
  end
  
  L7_2 = {}
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  eEnterVehicle = L3_2
  L3_2 = Event
  L3_2 = L3_2.CreatePersistent
  L4_2 = Event
  L4_2 = L4_2.Button
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetLocalPlayer
  L6_2 = L6_2()
  L7_2 = "lbutton"
  L8_2 = "press"
  L9_2 = true
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L6_2 = FlipVehicle
  L7_2 = {}
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  evFlipVehicle = L3_2
  L3_2 = Event
  L3_2 = L3_2.CreatePersistent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 1
  L5_2[1] = L6_2
  L6_2 = CheckFlipped
  L7_2 = {}
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  evVehicleFlipped = L3_2
  L3_2 = ObjectFilter
  L3_2 = L3_2.Create
  L3_2 = L3_2()
  uVZFilter = L3_2
  L3_2 = ObjectFilter
  L3_2 = L3_2.SetFilter
  L4_2 = uVZFilter
  L5_2 = "Human&&VZ"
  L3_2(L4_2, L5_2)
  L3_2 = Event
  L3_2 = L3_2.CreatePersistent
  L4_2 = Event
  L4_2 = L4_2.ObjectDeath
  L5_2 = {}
  L6_2 = uVZFilter
  L5_2[1] = L6_2
  
  function L6_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = nVZSoldierCounter
    L0_3 = L0_3 + 1
    nVZSoldierCounter = L0_3
    L0_3 = Hud
    L0_3 = L0_3.ObjectiveTray
    L1_3 = L0_3
    L0_3 = L0_3.SetSlotToText
    L2_3 = {}
    L2_3.nSlot = 2
    L3_3 = "[DLCCon002.UI.KillCounter] "
    L4_3 = nVZSoldierCounter
    L3_3 = L3_3 .. L4_3
    L2_3.sText = L3_3
    L0_3(L1_3, L2_3)
    L0_3 = MrxPmc
    L0_3 = L0_3.AddCashQty
    L1_3 = kVZSoldierCash
    L0_3(L1_3)
  end
  
  L7_2 = {}
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  eVZSoldierDestroyed = L3_2
end

Activated = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = Pg
  L0_2 = L0_2.GetGuidByName
  L1_2 = "Monster1"
  L0_2 = L0_2(L1_2)
  L1_2 = Vehicle
  L1_2 = L1_2.IsFlipped
  L2_2 = L0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = Object
    L1_2 = L1_2.GetVelocity
    L2_2 = L0_2
    L1_2 = L1_2(L2_2)
    if L1_2 < 5 then
      L1_2 = MrxTutorialManager
      L1_2 = L1_2.ShowMessage
      L2_2 = "[DLCCon001.UI.FlipCar]"
      L1_2(L2_2)
      L1_2 = Event
      L1_2 = L1_2.Create
      L2_2 = Event
      L2_2 = L2_2.TimerRelative
      L3_2 = {}
      L4_2 = 10
      L3_2[1] = L4_2
      L4_2 = MrxTutorialManager
      L4_2 = L4_2.HideMessage
      L5_2 = {}
      L1_2(L2_2, L3_2, L4_2, L5_2)
    end
  end
end

CheckFlipped = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = Pg
  L0_2 = L0_2.GetGuidByName
  L1_2 = "Monster1"
  L0_2 = L0_2(L1_2)
  L1_2 = Vehicle
  L1_2 = L1_2.IsFlipped
  L2_2 = L0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = Object
    L1_2 = L1_2.GetVelocity
    L2_2 = L0_2
    L1_2 = L1_2(L2_2)
    if L1_2 < 5 then
      L1_2 = Object
      L1_2 = L1_2.GetMass
      L2_2 = L0_2
      L1_2 = L1_2(L2_2)
      L2_2 = Object
      L2_2 = L2_2.ApplyAngularImpulse
      L3_2 = L0_2
      L4_2 = -L1_2
      L4_2 = L4_2 * 2.5
      L5_2 = 0
      L6_2 = L1_2 * 2.5
      L7_2 = true
      L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  end
  else
    return
  end
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 0.25
  L3_2[1] = L4_2
  L4_2 = FlipVehicle
  L5_2 = {}
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

FlipVehicle = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = {}
  L2_2 = "Fiona-In-Mission-Contract-Dlc02-19"
  L3_2 = {}
  L4_2 = A0_2.Cancel
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L3_2 = A0_2
  L2_2 = A0_2._SetCancelMessage
  L4_2 = "[ChiCon009.Terms.Cancel05]"
  L2_2(L3_2, L4_2)
  L2_2 = MrxVoSequence
  L2_2 = L2_2.Start
  L3_2 = L1_2
  L2_2(L3_2)
end

MonsterTruckDestroyed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2
  L1_2 = 45
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "MecRace"
  L4_2.sModuleName = "MrxTaskRace"
  L4_2.bUseTripWires = true
  L4_2.bUseTenths = true
  L4_2.fWidth = 15
  L5_2 = {}
  L5_2.nStartTime = 30
  L4_2.tTimerParams = L5_2
  L4_2.nAddTime = 7
  L4_2.sGateType = "gate"
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "Monster1"
  L5_2 = L5_2(L6_2)
  L4_2.vTgtInclude = L5_2
  L5_2 = {}
  L6_2 = "Fiona-In-Mission-Contract-Dlc02-15"
  L7_2 = 0.2
  L8_2 = "Fiona-In-Mission-Contract-Dlc02-11"
  L9_2 = 0.12
  L10_2 = "Fiona-In-Mission-Contract-Dlc02-09"
  L11_2 = 0.5
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L4_2.vVoSeqOnAdd = L5_2
  L5_2 = {}
  L6_2 = "check0"
  L7_2 = "check0a"
  L8_2 = "check1"
  L9_2 = "check2"
  L10_2 = "check3"
  L11_2 = "check4"
  L12_2 = "check5"
  L13_2 = "check6"
  L14_2 = "check7"
  L15_2 = "check8"
  L16_2 = "check9"
  L17_2 = "check10"
  L18_2 = "check11"
  L19_2 = "check12"
  L20_2 = "check13"
  L21_2 = "check14"
  L22_2 = "check15"
  L23_2 = "check16"
  L24_2 = "check17"
  L25_2 = "check18"
  L26_2 = "check19"
  L27_2 = "check20"
  L28_2 = "check21"
  L29_2 = "check22"
  L30_2 = "check22b"
  L31_2 = "check22c"
  L32_2 = "check23"
  L33_2 = "check24"
  L34_2 = "check25"
  L35_2 = "check26"
  L36_2 = "check27"
  L37_2 = "check28"
  L38_2 = "check29"
  L39_2 = "check30"
  L40_2 = "check31"
  L41_2 = "check32"
  L42_2 = "check33"
  L43_2 = "check34"
  L44_2 = "check35"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L5_2[7] = L12_2
  L5_2[8] = L13_2
  L5_2[9] = L14_2
  L5_2[10] = L15_2
  L5_2[11] = L16_2
  L5_2[12] = L17_2
  L5_2[13] = L18_2
  L5_2[14] = L19_2
  L5_2[15] = L20_2
  L5_2[16] = L21_2
  L5_2[17] = L22_2
  L5_2[18] = L23_2
  L5_2[19] = L24_2
  L5_2[20] = L25_2
  L5_2[21] = L26_2
  L5_2[22] = L27_2
  L5_2[23] = L28_2
  L5_2[24] = L29_2
  L5_2[25] = L30_2
  L5_2[26] = L31_2
  L5_2[27] = L32_2
  L5_2[28] = L33_2
  L5_2[29] = L34_2
  L5_2[30] = L35_2
  L5_2[31] = L36_2
  L5_2[32] = L37_2
  L5_2[33] = L38_2
  L5_2[34] = L39_2
  L5_2[35] = L40_2
  L5_2[36] = L41_2
  L5_2[37] = L42_2
  L5_2[38] = L43_2
  L5_2[39] = L44_2
  L4_2.tCourseLocs = L5_2
  
  function L5_2()
    local L0_3, L1_3
    L0_3 = Object
    L0_3 = L0_3.IsAlive
    L1_3 = uTruck
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3.CourseUnfinished
      L0_3(L1_3)
    else
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3.MonsterTruckDestroyed
      L0_3(L1_3)
    end
  end
  
  L4_2.fOnCancel = L5_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3, L18_3, L19_3, L20_3
    L0_3 = math
    L0_3 = L0_3.floor
    L1_3 = A0_2
    L1_3 = L1_3.oRace
    L1_3 = L1_3._oTimer
    L2_3 = L1_3
    L1_3 = L1_3.GetTime
    L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3, L18_3, L19_3, L20_3 = L1_3(L2_3)
    L0_3 = L0_3(L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3, L18_3, L19_3, L20_3)
    L1_3 = kTimeCash
    L1_3 = L0_3 * L1_3
    L2_3 = MrxPmc
    L2_3 = L2_3.AddCashQty
    L3_3 = L1_3
    L4_3 = "[Fanfare.Completion.TimeBonus]"
    L2_3(L3_3, L4_3)
    L2_3 = nVZSoldierCounter
    L3_3 = kVZSoldierCash
    L2_3 = L2_3 * L3_3
    L3_3 = L1_3 + L2_3
    L4_3 = MrxPmc
    L4_3 = L4_3.GetCashQty
    L4_3 = L4_3()
    L4_3 = L4_3 - L3_3
    L5_3 = ""
    if L4_3 < 0 then
      L5_3 = "-"
    end
    L6_3 = "[DLCCon002.UI.TimeRemaining] "
    L7_3 = MrxUtil
    L7_3 = L7_3.FormatMoney
    L8_3 = L1_3
    L7_3 = L7_3(L8_3)
    L8_3 = "[n][DLCCon002.UI.KillCounter] "
    L9_3 = MrxUtil
    L9_3 = L9_3.FormatMoney
    L10_3 = L2_3
    L9_3 = L9_3(L10_3)
    L10_3 = "[n][Scoring.Misc] : "
    L11_3 = L5_3
    L12_3 = MrxUtil
    L12_3 = L12_3.FormatMoney
    L13_3 = math
    L13_3 = L13_3.abs
    L14_3 = L4_3
    L13_3, L14_3, L15_3, L16_3, L17_3, L18_3, L19_3, L20_3 = L13_3(L14_3)
    L12_3 = L12_3(L13_3, L14_3, L15_3, L16_3, L17_3, L18_3, L19_3, L20_3)
    L13_3 = "[n][green][Scoring.Total] : "
    L14_3 = MrxUtil
    L14_3 = L14_3.FormatMoney
    L15_3 = MrxPmc
    L15_3 = L15_3.GetCashQty
    L15_3, L16_3, L17_3, L18_3, L19_3, L20_3 = L15_3()
    L14_3 = L14_3(L15_3, L16_3, L17_3, L18_3, L19_3, L20_3)
    L15_3 = "[n]"
    L6_3 = L6_3 .. L7_3 .. L8_3 .. L9_3 .. L10_3 .. L11_3 .. L12_3 .. L13_3 .. L14_3 .. L15_3
    L7_3 = A0_2
    L8_3 = MrxGui
    L8_3 = L8_3.DisplayDialogBox
    L9_3 = Player
    L9_3 = L9_3.GetPrimaryPlayer
    L9_3 = L9_3()
    L10_3 = L6_3
    L11_3 = {}
    L12_3 = nil
    L13_3 = A0_2
    L13_3 = L13_3.Complete
    L14_3 = {}
    L15_3 = A0_2
    L14_3[1] = L15_3
    L15_3 = nil
    L16_3 = nil
    L17_3 = "center"
    L18_3 = "center"
    L19_3 = true
    L20_3 = nil
    L8_3 = L8_3(L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3, L18_3, L19_3, L20_3)
    L7_3.oScoreBoard = L8_3
    L7_3 = Net
    L7_3 = L7_3.LeaderboardPushScore
    L8_3 = "DlcCon002"
    L9_3 = MrxPmc
    L9_3 = L9_3.GetCashQty
    L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3, L18_3, L19_3, L20_3 = L9_3()
    L7_3(L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3, L18_3, L19_3, L20_3)
    L7_3 = DLC01_MissionHub
    L7_3 = L7_3.SetPrevBest
    L8_3 = "DlcCon002"
    L9_3 = MrxPmc
    L9_3 = L9_3.GetCashQty
    L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3, L18_3, L19_3, L20_3 = L9_3()
    L7_3(L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3, L18_3, L19_3, L20_3)
  end
  
  L4_2.fOnComplete = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  A0_2.oRace = L2_2
end

StartRace = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[PmcCon015.Terms.Cancel04]"
  L1_2(L2_2, L3_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Dlc02-18"
  L4_2 = {}
  L5_2 = A0_2.Cancel
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
end

CourseUnfinished = L0_1

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
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evFlipVehicle
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = evVehicleFlipped
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = eEnterVehicle
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = eVZSoldierDestroyed
  L1_2(L2_2)
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.nSlot = 2
  L1_2(L2_2, L3_2)
  L1_2 = A0_2.oScoreBoard
  if L1_2 then
    L1_2 = A0_2.oScoreBoard
    L2_2 = L1_2
    L1_2 = L1_2.Close
    L1_2(L2_2)
    A0_2.oScoreBoard = nil
  end
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L1_2 = {}
  L2_2 = "Fiona-In-Mission-Contract-Dlc02-05"
  L3_2 = "Fiona-In-Mission-Contract-Dlc02-06"
  L4_2 = "Fiona-In-Mission-Contract-Dlc02-07"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L2_2 = MrxUtil
  L2_2 = L2_2.GetRandomTableElement
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.ObjectProximity
  L6_2 = {}
  L7_2 = Player
  L7_2 = L7_2.GetAnyCharacter
  L7_2 = L7_2()
  L8_2 = Pg
  L8_2 = L8_2.GetGuidByName
  L9_2 = "check0a"
  L8_2 = L8_2(L9_2)
  L9_2 = "<"
  L10_2 = 30
  L11_2 = false
  L12_2 = false
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L6_2[5] = L11_2
  L6_2[6] = L12_2
  L7_2 = MrxVoSequence
  L7_2 = L7_2.Start
  L8_2 = {}
  L9_2 = L2_2
  L8_2[1] = L9_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  L3_2 = {}
  L4_2 = "Fiona-In-Mission-Contract-Dlc02-17"
  L3_2[1] = L4_2
  L4_2 = MrxUtil
  L4_2 = L4_2.GetRandomTableElement
  L5_2 = L3_2
  L4_2 = L4_2(L5_2)
  L6_2 = A0_2
  L5_2 = A0_2._CreateEvent
  L7_2 = Event
  L7_2 = L7_2.ObjectProximity
  L8_2 = {}
  L9_2 = Player
  L9_2 = L9_2.GetAnyCharacter
  L9_2 = L9_2()
  L10_2 = Pg
  L10_2 = L10_2.GetGuidByName
  L11_2 = "check2"
  L10_2 = L10_2(L11_2)
  L11_2 = "<"
  L12_2 = 20
  L13_2 = false
  L14_2 = false
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  L8_2[5] = L13_2
  L8_2[6] = L14_2
  L9_2 = MrxVoSequence
  L9_2 = L9_2.Start
  L10_2 = {}
  L11_2 = L4_2
  L10_2[1] = L11_2
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L5_2 = {}
  L6_2 = "Fiona-In-Mission-Contract-Dlc02-04"
  L5_2[1] = L6_2
  L6_2 = MrxUtil
  L6_2 = L6_2.GetRandomTableElement
  L7_2 = L5_2
  L6_2 = L6_2(L7_2)
  L8_2 = A0_2
  L7_2 = A0_2._CreateEvent
  L9_2 = Event
  L9_2 = L9_2.ObjectProximity
  L10_2 = {}
  L11_2 = Player
  L11_2 = L11_2.GetAnyCharacter
  L11_2 = L11_2()
  L12_2 = Pg
  L12_2 = L12_2.GetGuidByName
  L13_2 = "check11"
  L12_2 = L12_2(L13_2)
  L13_2 = "<"
  L14_2 = 20
  L15_2 = false
  L16_2 = false
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L10_2[5] = L15_2
  L10_2[6] = L16_2
  L11_2 = MrxVoSequence
  L11_2 = L11_2.Start
  L12_2 = {}
  L13_2 = L6_2
  L12_2[1] = L13_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L7_2 = {}
  L8_2 = "Fiona-In-Mission-Contract-Dlc02-03"
  L7_2[1] = L8_2
  L8_2 = MrxUtil
  L8_2 = L8_2.GetRandomTableElement
  L9_2 = L7_2
  L8_2 = L8_2(L9_2)
  L10_2 = A0_2
  L9_2 = A0_2._CreateEvent
  L11_2 = Event
  L11_2 = L11_2.ObjectProximity
  L12_2 = {}
  L13_2 = Player
  L13_2 = L13_2.GetAnyCharacter
  L13_2 = L13_2()
  L14_2 = Pg
  L14_2 = L14_2.GetGuidByName
  L15_2 = "check29"
  L14_2 = L14_2(L15_2)
  L15_2 = "<"
  L16_2 = 10
  L17_2 = false
  L18_2 = false
  L12_2[1] = L13_2
  L12_2[2] = L14_2
  L12_2[3] = L15_2
  L12_2[4] = L16_2
  L12_2[5] = L17_2
  L12_2[6] = L18_2
  L13_2 = MrxVoSequence
  L13_2 = L13_2.Start
  L14_2 = {}
  L15_2 = L8_2
  L14_2[1] = L15_2
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
  L9_2 = {}
  L10_2 = "Fiona-In-Mission-Contract-Dlc01-16"
  L9_2[1] = L10_2
  L10_2 = MrxUtil
  L10_2 = L10_2.GetRandomTableElement
  L11_2 = L9_2
  L10_2 = L10_2(L11_2)
  L12_2 = A0_2
  L11_2 = A0_2._CreateEvent
  L13_2 = Event
  L13_2 = L13_2.ObjectProximity
  L14_2 = {}
  L15_2 = Player
  L15_2 = L15_2.GetAnyCharacter
  L15_2 = L15_2()
  L16_2 = Pg
  L16_2 = L16_2.GetGuidByName
  L17_2 = "check35"
  L16_2 = L16_2(L17_2)
  L17_2 = "<"
  L18_2 = 10
  L19_2 = false
  L20_2 = false
  L14_2[1] = L15_2
  L14_2[2] = L16_2
  L14_2[3] = L17_2
  L14_2[4] = L18_2
  L14_2[5] = L19_2
  L14_2[6] = L20_2
  L15_2 = MrxVoSequence
  L15_2 = L15_2.Start
  L16_2 = {}
  L17_2 = L10_2
  L16_2[1] = L17_2
  L11_2(L12_2, L13_2, L14_2, L15_2, L16_2)
end

CheckPointVO = L0_1
