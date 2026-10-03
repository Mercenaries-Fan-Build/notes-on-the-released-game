local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTimer"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxAchievements"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxState"
L0_1(L1_1)
L0_1 = 0
NETEVENT_SETSTARTUPWEAPONS = L0_1
L0_1 = 1
NETEVENT_RETURNWEAPONS = L0_1
L0_1 = nil
tLocalP2Weapons = L0_1
L0_1 = nil
tP2Weapons = L0_1
L0_1 = nil
bP2PresentAtStart = L0_1
L0_1 = nil
P1BoundaryEvent = L0_1
L0_1 = nil
P2BoundaryEvent = L0_1
L0_1 = nil
evClientSetup = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = NETEVENT_SETSTARTUPWEAPONS
  if A0_2 == L2_2 then
    L2_2 = tP2Weapons
    if not L2_2 then
      L2_2 = MrxState
      L2_2 = L2_2._GetTotalRefCount
      L2_2 = L2_2()
      if L2_2 == 0 then
        L2_2 = SetP2Weapons
        L2_2()
      else
        L2_2 = Event
        L2_2 = L2_2.Create
        L3_2 = Event
        L3_2 = L3_2.TimerRelative
        L4_2 = {}
        L5_2 = 1
        L4_2[1] = L5_2
        L5_2 = NetEventCallback
        L6_2 = {}
        L7_2 = A0_2
        L6_2[1] = L7_2
        L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
        evClientSetup = L2_2
      end
    end
  else
    L2_2 = NETEVENT_RETURNWEAPONS
    if A0_2 == L2_2 then
      L2_2 = Event
      L2_2 = L2_2.Delete
      L3_2 = evClientSetup
      L2_2(L3_2)
      L2_2 = nil
      evClientSetup = L2_2
      L2_2 = tP2Weapons
      if L2_2 then
        L2_2 = Player
        L2_2 = L2_2.GetSecondaryCharacter
        L2_2 = L2_2()
        uCharacter = L2_2
        L2_2 = ipairs
        L3_2 = tP2Weapons
        L2_2, L3_2, L4_2 = L2_2(L3_2)
        for L5_2, L6_2 in L2_2, L3_2, L4_2 do
        end
        L2_2 = Human
        L2_2 = L2_2.Inventory
        L2_2 = L2_2.SetAllWeapons
        L3_2 = uCharacter
        L4_2 = tP2Weapons
        L2_2(L3_2, L4_2)
        L2_2 = MrxUtil
        L2_2 = L2_2.EnableHeroWeapons
        L3_2 = false
        L2_2(L3_2)
        L2_2 = nil
        tP2Weapons = L2_2
        L2_2 = Player
        L2_2 = L2_2.SetAimMode
        L3_2 = Player
        L3_2 = L3_2.GetPrimaryPlayer
        L3_2 = L3_2()
        L4_2 = true
        L2_2(L3_2, L4_2)
        L2_2 = Player
        L2_2 = L2_2.SetAimMode
        L3_2 = Player
        L3_2 = L3_2.GetSecondaryPlayer
        L3_2 = L3_2()
        L4_2 = true
        L2_2(L3_2, L4_2)
      end
    end
  end
end

NetEventCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = Hud
  L2_2 = L2_2.SupportMenu
  L3_2 = L2_2
  L2_2 = L2_2.SetShootingGalleryMode
  L4_2 = {}
  L4_2.bEnable = true
  L2_2(L3_2, L4_2)
  L2_2 = {}
  L3_2 = "Vz_State_PmcCon018"
  L4_2 = "vz_State_PmcCon018_Veh"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  tLayersToAdd = L2_2
  L2_2 = MrxLayerManager
  L2_2 = L2_2.Add
  L3_2 = tLayersToAdd
  L4_2 = A0_2.AssetsLoaded
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = _SetupP1Weapons
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = Player
  L2_2 = L2_2.GetSecondaryCharacter
  L2_2 = L2_2()
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2._CreateEvent
    L4_2 = Event
    L4_2 = L4_2.ObjectHibernation
    L5_2 = {}
    L6_2 = Player
    L6_2 = L6_2.GetSecondaryCharacter
    L6_2 = L6_2()
    L7_2 = "awake"
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    
    function L6_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3
      L0_3 = Net
      L0_3 = L0_3.SendCustomEvent
      L1_3 = "PmcCon018"
      L2_3 = NETEVENT_SETSTARTUPWEAPONS
      L3_3 = {}
      L4_3 = true
      L0_3(L1_3, L2_3, L3_3, L4_3)
    end
    
    L2_2(L3_2, L4_2, L5_2, L6_2)
  end
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = MrxSupportData
  L1_2 = L1_2.AddFreebie
  L2_2 = "Practice Laser"
  L3_2 = 1
  L4_2 = Player
  L4_2 = L4_2.GetPrimaryPlayer
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L4_2()
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  L1_2 = Player
  L1_2 = L1_2.GetSecondaryCharacter
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = MrxSupportData
    L1_2 = L1_2.AddFreebie
    L2_2 = "Practice Laser"
    L3_2 = 1
    L4_2 = Player
    L4_2 = L4_2.GetSecondaryPlayer
    L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L4_2()
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
    L1_2 = true
    bP2PresentAtStart = L1_2
  else
    L1_2 = MrxSupportData
    L1_2 = L1_2.AddFreebie
    L2_2 = "Practice Laser"
    L3_2 = 1
    L4_2 = Player
    L4_2 = L4_2.GetPrimaryPlayer
    L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L4_2()
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  end
  L1_2 = Ai
  L1_2 = L1_2.GetRelation
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "OC"
  L2_2 = L2_2(L3_2)
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "PMC"
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L3_2(L4_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  OCRelation = L1_2
  L1_2 = Ai
  L1_2 = L1_2.SetRelation
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "OC"
  L2_2 = L2_2(L3_2)
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "PMC"
  L3_2 = L3_2(L4_2)
  L4_2 = 100
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = nil
  StartingCash = L1_2
  L1_2 = nil
  oCancelEvent = L1_2
  L1_2 = nil
  oMoneyUpdate = L1_2
  L1_2 = nil
  oTimerEvent = L1_2
  L1_2 = nil
  oCurObjective = L1_2
  L1_2 = 0
  CurPoints = L1_2
  L1_2 = 0
  AirStrikes = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.GetNumCompletions
  L1_2 = L1_2(L2_2)
  nCompletions = L1_2
  L1_2 = 1
  nDeleteIndex = L1_2
  L1_2 = {}
  tObjectsToDelete = L1_2
  L1_2 = nCompletions
  if 2 <= L1_2 then
    L1_2 = 100
    PointGoal = L1_2
  else
    L1_2 = nCompletions
    if L1_2 == 1 then
      L1_2 = 80
      PointGoal = L1_2
    else
      L1_2 = 60
      PointGoal = L1_2
    end
  end
  L1_2 = Event
  L1_2 = L1_2.CreatePersistent
  L2_2 = Event
  L2_2 = L2_2.ScriptEvent
  L3_2 = {}
  L4_2 = "mpPlayerJoin"
  
  function L5_2(A0_3)
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
  
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L4_2 = Net
  L4_2 = L4_2.SendCustomEvent
  L5_2 = {}
  L6_2 = "PmcCon018"
  L7_2 = NETEVENT_SETSTARTUPWEAPONS
  L8_2 = {}
  L9_2 = true
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  _evClientJoinedPMC018 = L1_2
  L1_2 = _ObjectiveStart
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = _RandomSpread
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Player
  L1_2 = L1_2.SetAimMode
  L2_2 = Player
  L2_2 = L2_2.GetPrimaryPlayer
  L2_2 = L2_2()
  L3_2 = false
  L1_2(L2_2, L3_2)
  L1_2 = Player
  L1_2 = L1_2.GetSecondaryPlayer
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = Player
    L1_2 = L1_2.SetAimMode
    L2_2 = Player
    L2_2 = L2_2.GetSecondaryPlayer
    L2_2 = L2_2()
    L3_2 = false
    L1_2(L2_2, L3_2)
  end
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.SetSlotToText
  L3_2 = {}
  L3_2.nSlot = 1
  L4_2 = "[white]"
  L5_2 = "[PmcCon018.HUD.PointsEarned] "
  L6_2 = tostring
  L7_2 = CurPoints
  L6_2 = L6_2(L7_2)
  L4_2 = L4_2 .. L5_2 .. L6_2
  L3_2.sText = L4_2
  L1_2(L2_2, L3_2)
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.SetSlotToText
  L3_2 = {}
  L3_2.nSlot = 2
  L4_2 = "[white]"
  L5_2 = "[PmcCon018.HUD.PointsNeeded] "
  L6_2 = PointGoal
  L4_2 = L4_2 .. L5_2 .. L6_2
  L3_2.sText = L4_2
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "Airstrike"
  
  function L6_2()
    local L0_3, L1_3
    L0_3 = true
    return L0_3
  end
  
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = AirStrikeVO
    L1_3 = A0_2
    L2_3 = CurPoints
    L0_3(L1_3, L2_3)
    L0_3 = 1
    AirStrikes = L0_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._CreateEvent
    L2_3 = Event
    L2_3 = L2_3.ScriptEvent
    L3_3 = {}
    L4_3 = "Airstrike"
    
    function L5_3()
      local L0_4, L1_4
      L0_4 = true
      return L0_4
    end
    
    L3_3[1] = L4_3
    L3_3[2] = L5_3
    
    function L4_3()
      local L0_4, L1_4, L2_4, L3_4, L4_4, L5_4, L6_4
      L0_4 = AirStrikeVO
      L1_4 = A0_2
      L2_4 = CurPoints
      L0_4(L1_4, L2_4)
      L0_4 = 2
      AirStrikes = L0_4
      L0_4 = oTimerEvent
      if L0_4 then
        L0_4 = Event
        L0_4 = L0_4.Delete
        L1_4 = oTimerEvent
        L0_4(L1_4)
      end
      L0_4 = A0_2
      L1_4 = L0_4
      L0_4 = L0_4._CreateEvent
      L2_4 = Event
      L2_4 = L2_4.TimerRelative
      L3_4 = {}
      L4_4 = 15
      L3_4[1] = L4_4
      L4_4 = _TimeUp
      L5_4 = {}
      L6_4 = A0_2
      L5_4[1] = L6_4
      L0_4 = L0_4(L1_4, L2_4, L3_4, L4_4, L5_4)
      oTimerEvent = L0_4
    end
    
    L0_3(L1_3, L2_3, L3_3, L4_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2
  L1_2 = {}
  L2_2 = "PMCCon018_Obj_marker 0x0012d13c"
  L3_2 = "PMCCon018_Obj_marker 0x0012d13d"
  L4_2 = "PMCCon018_Obj_marker 0x0012d13f"
  L5_2 = "PMCCon018_Obj_marker 0x0012d140"
  L6_2 = "PMCCon018_Obj_marker 0x0012d141"
  L7_2 = "PMCCon018_Obj_marker 0x0012d143"
  L8_2 = "PMCCon018_Obj_marker 0x0012d145"
  L9_2 = "PMCCon018_Obj_marker 0x0012d146"
  L10_2 = "PMCCon018_Obj_marker 0x0012d152"
  L11_2 = "PMCCon018_Obj_marker 0x0012d153"
  L12_2 = "PMCCon018_Obj_marker 0x0012d154"
  L13_2 = "PMCCon018_Obj_marker 0x0012d156"
  L14_2 = "PMCCon018_Obj_marker 0x0012d157"
  L15_2 = "PMCCon018_Obj_marker 0x0012d159"
  L16_2 = "PMCCon018_Obj_marker 0x0012d15b"
  L17_2 = "PMCCon018_Obj_marker 0x0012d15d"
  L18_2 = "PMCCon018_Obj_marker 0x0012d15f"
  L19_2 = "PMCCon018_Obj_marker 0x0012d160"
  L20_2 = "PMCCon018_Obj_marker 0x0012d164"
  L21_2 = "PMCCon018_Obj_marker 0x0012d16c"
  L22_2 = "PMCCon018_Obj_marker 0x0012d1a2"
  L23_2 = "PMCCon018_Obj_marker 0x0012d1a3"
  L24_2 = "PMCCon018_Obj_marker 0x0012d1a4"
  L25_2 = "PMCCon018_Obj_marker 0x0012d1a5"
  L26_2 = "PMCCon018_Obj_marker 0x0012d1a8"
  L27_2 = "PMCCon018_Obj_marker 0x0012d1aa"
  L28_2 = "PMCCon018_Obj_marker 0x0012d1af"
  L29_2 = "PMCCon018_Obj_marker 0x0012d1b3"
  L30_2 = "PMCCon018_Obj_marker 0x0012d1b4"
  L31_2 = "PMCCon018_Obj_marker 0x0012d1b5"
  L32_2 = "PMCCon018_Obj_marker 0x0012d1b6"
  L33_2 = "PMCCon018_Obj_marker 0x0012d1ba"
  L34_2 = "PMCCon018_Obj_marker 0x0012d1ac"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L1_2[7] = L8_2
  L1_2[8] = L9_2
  L1_2[9] = L10_2
  L1_2[10] = L11_2
  L1_2[11] = L12_2
  L1_2[12] = L13_2
  L1_2[13] = L14_2
  L1_2[14] = L15_2
  L1_2[15] = L16_2
  L1_2[16] = L17_2
  L1_2[17] = L18_2
  L1_2[18] = L19_2
  L1_2[19] = L20_2
  L1_2[20] = L21_2
  L1_2[21] = L22_2
  L1_2[22] = L23_2
  L1_2[23] = L24_2
  L1_2[24] = L25_2
  L1_2[25] = L26_2
  L1_2[26] = L27_2
  L1_2[27] = L28_2
  L1_2[28] = L29_2
  L1_2[29] = L30_2
  L1_2[30] = L31_2
  L1_2[31] = L32_2
  L1_2[32] = L33_2
  L1_2[33] = L34_2
  tMarkersVehicles = L1_2
  L1_2 = {}
  L2_2 = "PMCCon018_Obj_marker"
  L3_2 = "PMCCon018_Obj_marker 0x0012d13e"
  L4_2 = "PMCCon018_Obj_marker 0x0012d142"
  L5_2 = "PMCCon018_Obj_marker 0x0012d144"
  L6_2 = "PMCCon018_Obj_marker 0x0012d147"
  L7_2 = "PMCCon018_Obj_marker 0x0012d148"
  L8_2 = "PMCCon018_Obj_marker 0x0012d149"
  L9_2 = "PMCCon018_Obj_marker 0x0012d14a"
  L10_2 = "PMCCon018_Obj_marker 0x0012d14b"
  L11_2 = "PMCCon018_Obj_marker 0x0012d14c"
  L12_2 = "PMCCon018_Obj_marker 0x0012d14d"
  L13_2 = "PMCCon018_Obj_marker 0x0012d14e"
  L14_2 = "PMCCon018_Obj_marker 0x0012d14f"
  L15_2 = "PMCCon018_Obj_marker 0x0012d150"
  L16_2 = "PMCCon018_Obj_marker 0x0012d151"
  L17_2 = "PMCCon018_Obj_marker 0x0012d155"
  L18_2 = "PMCCon018_Obj_marker 0x0012d158"
  L19_2 = "PMCCon018_Obj_marker 0x0012d15a"
  L20_2 = "PMCCon018_Obj_marker 0x0012d15c"
  L21_2 = "PMCCon018_Obj_marker 0x0012d15e"
  L22_2 = "PMCCon018_Obj_marker 0x0012d161"
  L23_2 = "PMCCon018_Obj_marker 0x0012d162"
  L24_2 = "PMCCon018_Obj_marker 0x0012d163"
  L25_2 = "PMCCon018_Obj_marker 0x0012d165"
  L26_2 = "PMCCon018_Obj_marker 0x0012d166"
  L27_2 = "PMCCon018_Obj_marker 0x0012d167"
  L28_2 = "PMCCon018_Obj_marker 0x0012d168"
  L29_2 = "PMCCon018_Obj_marker 0x0012d169"
  L30_2 = "PMCCon018_Obj_marker 0x0012d16a"
  L31_2 = "PMCCon018_Obj_marker 0x0012d16b"
  L32_2 = "PMCCon018_Obj_marker 0x0012d16d"
  L33_2 = "PMCCon018_Obj_marker 0x0012d16e"
  L34_2 = "PMCCon018_Obj_marker 0x0012d1a6"
  L35_2 = "PMCCon018_Obj_marker 0x0012d1a7"
  L36_2 = "PMCCon018_Obj_marker 0x0012d1a9"
  L37_2 = "PMCCon018_Obj_marker 0x0012d1ab"
  L38_2 = "PMCCon018_Obj_marker 0x0012d1ad"
  L39_2 = "PMCCon018_Obj_marker 0x0012d1ae"
  L40_2 = "PMCCon018_Obj_marker 0x0012d1b1"
  L41_2 = "PMCCon018_Obj_marker 0x0012d1b2"
  L42_2 = "PMCCon018_Obj_marker 0x0012d1b7"
  L43_2 = "PMCCon018_Obj_marker 0x0012d1b8"
  L44_2 = "PMCCon018_Obj_marker 0x0012d1b9"
  L45_2 = "PMCCon018_Obj_marker 0x0012d1bb"
  L46_2 = "PMCCon018_Obj_marker 0x0012d1bc"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L1_2[7] = L8_2
  L1_2[8] = L9_2
  L1_2[9] = L10_2
  L1_2[10] = L11_2
  L1_2[11] = L12_2
  L1_2[12] = L13_2
  L1_2[13] = L14_2
  L1_2[14] = L15_2
  L1_2[15] = L16_2
  L1_2[16] = L17_2
  L1_2[17] = L18_2
  L1_2[18] = L19_2
  L1_2[19] = L20_2
  L1_2[20] = L21_2
  L1_2[21] = L22_2
  L1_2[22] = L23_2
  L1_2[23] = L24_2
  L1_2[24] = L25_2
  L1_2[25] = L26_2
  L1_2[26] = L27_2
  L1_2[27] = L28_2
  L1_2[28] = L29_2
  L1_2[29] = L30_2
  L1_2[30] = L31_2
  L1_2[31] = L32_2
  L1_2[32] = L33_2
  L1_2[33] = L34_2
  L1_2[34] = L35_2
  L1_2[35] = L36_2
  L1_2[36] = L37_2
  L1_2[37] = L38_2
  L1_2[38] = L39_2
  L1_2[39] = L40_2
  L1_2[40] = L41_2
  L1_2[41] = L42_2
  L1_2[42] = L43_2
  L1_2[43] = L44_2
  L1_2[44] = L45_2
  L1_2[45] = L46_2
  tMarkersBarrels = L1_2
  L1_2 = 1
  L2_2 = 8
  L3_2 = 1
  for L4_2 = L1_2, L2_2, L3_2 do
    L5_2 = GetRandomTableIndex
    L6_2 = tMarkersVehicles
    L5_2 = L5_2(L6_2)
    L6_2 = Pg
    L6_2 = L6_2.GetGuidByName
    L7_2 = tMarkersVehicles
    L7_2 = L7_2[L5_2]
    L6_2 = L6_2(L7_2)
    if L6_2 == nil then
      L4_2 = L4_2 - 1
    else
      L6_2 = Object
      L6_2 = L6_2.GetPosition
      L7_2 = Pg
      L7_2 = L7_2.GetGuidByName
      L8_2 = tMarkersVehicles
      L8_2 = L8_2[L5_2]
      L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2 = L7_2(L8_2)
      L6_2, L7_2, L8_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2)
      L9_2 = Pg
      L9_2 = L9_2.Spawn
      L10_2 = "M35 (Cargo) (VZ)"
      L11_2 = L6_2
      L12_2 = L7_2
      L13_2 = L8_2
      L14_2 = 0
      L15_2 = false
      L16_2 = true
      L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
      uSPAWN = L9_2
      L9_2 = Object
      L9_2 = L9_2.SetTransformToObject
      L10_2 = uSPAWN
      L11_2 = Pg
      L11_2 = L11_2.GetGuidByName
      L12_2 = tMarkersVehicles
      L12_2 = L12_2[L5_2]
      L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2 = L11_2(L12_2)
      L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2)
      L9_2 = table
      L9_2 = L9_2.remove
      L10_2 = tMarkersVehicles
      L11_2 = L5_2
      L9_2(L10_2, L11_2)
      L10_2 = A0_2
      L9_2 = A0_2._CreateEvent
      L11_2 = Event
      L11_2 = L11_2.ObjectDeath
      L12_2 = {}
      L13_2 = uSPAWN
      L12_2[1] = L13_2
      L13_2 = _AddPoints
      L14_2 = {}
      L15_2 = 3
      L16_2 = A0_2
      L14_2[1] = L15_2
      L14_2[2] = L16_2
      L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
      L9_2 = tObjectsToDelete
      L10_2 = nDeleteIndex
      L11_2 = uSPAWN
      L9_2[L10_2] = L11_2
      L9_2 = nDeleteIndex
      L9_2 = L9_2 + 1
      nDeleteIndex = L9_2
    end
  end
  L1_2 = 1
  L2_2 = 7
  L3_2 = 1
  for L4_2 = L1_2, L2_2, L3_2 do
    L5_2 = GetRandomTableIndex
    L6_2 = tMarkersVehicles
    L5_2 = L5_2(L6_2)
    L6_2 = Pg
    L6_2 = L6_2.GetGuidByName
    L7_2 = tMarkersVehicles
    L7_2 = L7_2[L5_2]
    L6_2 = L6_2(L7_2)
    if L6_2 == nil then
      L4_2 = L4_2 - 1
    else
      L6_2 = Object
      L6_2 = L6_2.GetPosition
      L7_2 = Pg
      L7_2 = L7_2.GetGuidByName
      L8_2 = tMarkersVehicles
      L8_2 = L8_2[L5_2]
      L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2 = L7_2(L8_2)
      L6_2, L7_2, L8_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2)
      L9_2 = Pg
      L9_2 = L9_2.Spawn
      L10_2 = "_vzoutpost_fueltanks_PmcCon018"
      L11_2 = L6_2
      L12_2 = L7_2
      L13_2 = L8_2
      L14_2 = 0
      L15_2 = false
      L16_2 = true
      L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
      uSPAWN = L9_2
      L9_2 = Object
      L9_2 = L9_2.SetTransformToObject
      L10_2 = uSPAWN
      L11_2 = Pg
      L11_2 = L11_2.GetGuidByName
      L12_2 = tMarkersVehicles
      L12_2 = L12_2[L5_2]
      L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2 = L11_2(L12_2)
      L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2)
      L9_2 = table
      L9_2 = L9_2.remove
      L10_2 = tMarkersVehicles
      L11_2 = L5_2
      L9_2(L10_2, L11_2)
      L10_2 = A0_2
      L9_2 = A0_2._CreateEvent
      L11_2 = Event
      L11_2 = L11_2.ObjectDeath
      L12_2 = {}
      L13_2 = uSPAWN
      L12_2[1] = L13_2
      L13_2 = _AddPoints
      L14_2 = {}
      L15_2 = 5
      L16_2 = A0_2
      L14_2[1] = L15_2
      L14_2[2] = L16_2
      L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
      L9_2 = tObjectsToDelete
      L10_2 = nDeleteIndex
      L11_2 = uSPAWN
      L9_2[L10_2] = L11_2
      L9_2 = nDeleteIndex
      L9_2 = L9_2 + 1
      nDeleteIndex = L9_2
    end
  end
  L1_2 = 1
  L2_2 = 9
  L3_2 = 1
  for L4_2 = L1_2, L2_2, L3_2 do
    L5_2 = GetRandomTableIndex
    L6_2 = tMarkersVehicles
    L5_2 = L5_2(L6_2)
    L6_2 = Pg
    L6_2 = L6_2.GetGuidByName
    L7_2 = tMarkersVehicles
    L7_2 = L7_2[L5_2]
    L6_2 = L6_2(L7_2)
    if L6_2 == nil then
      L4_2 = L4_2 - 1
    else
      L6_2 = Object
      L6_2 = L6_2.GetPosition
      L7_2 = Pg
      L7_2 = L7_2.GetGuidByName
      L8_2 = tMarkersVehicles
      L8_2 = L8_2[L5_2]
      L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2 = L7_2(L8_2)
      L6_2, L7_2, L8_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2)
      L9_2 = Pg
      L9_2 = L9_2.Spawn
      L10_2 = "M151 .50Cal (VZ)"
      L11_2 = L6_2
      L12_2 = L7_2
      L13_2 = L8_2
      L14_2 = 0
      L15_2 = false
      L16_2 = true
      L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
      uSPAWN = L9_2
      L9_2 = Object
      L9_2 = L9_2.SetTransformToObject
      L10_2 = uSPAWN
      L11_2 = Pg
      L11_2 = L11_2.GetGuidByName
      L12_2 = tMarkersVehicles
      L12_2 = L12_2[L5_2]
      L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2 = L11_2(L12_2)
      L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2)
      L9_2 = table
      L9_2 = L9_2.remove
      L10_2 = tMarkersVehicles
      L11_2 = L5_2
      L9_2(L10_2, L11_2)
      L10_2 = A0_2
      L9_2 = A0_2._CreateEvent
      L11_2 = Event
      L11_2 = L11_2.ObjectDeath
      L12_2 = {}
      L13_2 = uSPAWN
      L12_2[1] = L13_2
      L13_2 = _AddPoints
      L14_2 = {}
      L15_2 = 2
      L16_2 = A0_2
      L14_2[1] = L15_2
      L14_2[2] = L16_2
      L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
      L9_2 = tObjectsToDelete
      L10_2 = nDeleteIndex
      L11_2 = uSPAWN
      L9_2[L10_2] = L11_2
      L9_2 = nDeleteIndex
      L9_2 = L9_2 + 1
      nDeleteIndex = L9_2
    end
  end
  L1_2 = 0
  nTempCounter = L1_2
  L1_2 = ipairs
  L2_2 = tMarkersVehicles
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Pg
    L6_2 = L6_2.GetGuidByName
    L7_2 = tMarkersVehicles
    L7_2 = L7_2[L4_2]
    L6_2 = L6_2(L7_2)
    if L6_2 then
      L6_2 = Math
      L6_2 = L6_2.randi
      L7_2 = 0
      L8_2 = 3
      L6_2 = L6_2(L7_2, L8_2)
      CoinToss = L6_2
      L6_2 = CoinToss
      if L6_2 ~= 0 then
        L6_2 = CoinToss
        if L6_2 ~= 1 then
          L6_2 = CoinToss
          if L6_2 ~= 3 then
            goto lbl_360
          end
        end
      end
      L6_2 = Object
      L6_2 = L6_2.GetPosition
      L7_2 = Pg
      L7_2 = L7_2.GetGuidByName
      L8_2 = L5_2
      L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2 = L7_2(L8_2)
      L6_2, L7_2, L8_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2)
      L9_2 = Pg
      L9_2 = L9_2.Spawn
      L10_2 = "_global_explosivebarrel_Long_Hibernation"
      L11_2 = L6_2
      L12_2 = L7_2
      L13_2 = L8_2
      L14_2 = 0
      L15_2 = false
      L16_2 = true
      L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
      uSPAWN = L9_2
      L9_2 = tObjectsToDelete
      L10_2 = nDeleteIndex
      L11_2 = uSPAWN
      L9_2[L10_2] = L11_2
      L9_2 = nDeleteIndex
      L9_2 = L9_2 + 1
      nDeleteIndex = L9_2
      L9_2 = nTempCounter
      L9_2 = L9_2 + 1
      nTempCounter = L9_2
      L10_2 = A0_2
      L9_2 = A0_2._CreateEvent
      L11_2 = Event
      L11_2 = L11_2.ObjectDeath
      L12_2 = {}
      L13_2 = uSPAWN
      L12_2[1] = L13_2
      L13_2 = _AddPoints
      L14_2 = {}
      L15_2 = 1
      L16_2 = A0_2
      L14_2[1] = L15_2
      L14_2[2] = L16_2
      L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
    end
    ::lbl_360::
  end
  L1_2 = ipairs
  L2_2 = tMarkersBarrels
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Pg
    L6_2 = L6_2.GetGuidByName
    L7_2 = tMarkersBarrels
    L7_2 = L7_2[L4_2]
    L6_2 = L6_2(L7_2)
    if L6_2 then
      L6_2 = Math
      L6_2 = L6_2.randi
      L7_2 = 0
      L8_2 = 3
      L6_2 = L6_2(L7_2, L8_2)
      CoinToss = L6_2
      L6_2 = CoinToss
      if L6_2 ~= 0 then
        L6_2 = CoinToss
        if L6_2 ~= 1 then
          L6_2 = CoinToss
          if L6_2 ~= 3 then
            goto lbl_428
          end
        end
      end
      L6_2 = Object
      L6_2 = L6_2.GetPosition
      L7_2 = Pg
      L7_2 = L7_2.GetGuidByName
      L8_2 = L5_2
      L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2 = L7_2(L8_2)
      L6_2, L7_2, L8_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2)
      L9_2 = Pg
      L9_2 = L9_2.Spawn
      L10_2 = "_global_explosivebarrel_Long_Hibernation"
      L11_2 = L6_2
      L12_2 = L7_2
      L13_2 = L8_2
      L14_2 = 0
      L15_2 = false
      L16_2 = true
      L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
      uSPAWN = L9_2
      L9_2 = tObjectsToDelete
      L10_2 = nDeleteIndex
      L11_2 = uSPAWN
      L9_2[L10_2] = L11_2
      L9_2 = nDeleteIndex
      L9_2 = L9_2 + 1
      nDeleteIndex = L9_2
      L9_2 = nTempCounter
      L9_2 = L9_2 + 1
      nTempCounter = L9_2
      L10_2 = A0_2
      L9_2 = A0_2._CreateEvent
      L11_2 = Event
      L11_2 = L11_2.ObjectDeath
      L12_2 = {}
      L13_2 = uSPAWN
      L12_2[1] = L13_2
      L13_2 = _AddPoints
      L14_2 = {}
      L15_2 = 1
      L16_2 = A0_2
      L14_2[1] = L15_2
      L14_2[2] = L16_2
      L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
    end
    ::lbl_428::
  end
end

_RandomSpread = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = oTimerEvent
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = oTimerEvent
    L2_2(L3_2)
  end
  L3_2 = A1_2
  L2_2 = A1_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 8
  L5_2[1] = L6_2
  L6_2 = _TimeUp
  L7_2 = {}
  L8_2 = A1_2
  L7_2[1] = L8_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  oTimerEvent = L2_2
  L2_2 = CurPoints
  L2_2 = L2_2 + A0_2
  CurPoints = L2_2
  L2_2 = Hud
  L2_2 = L2_2.ObjectiveTray
  L3_2 = L2_2
  L2_2 = L2_2.SetSlotToText
  L4_2 = {}
  L4_2.nSlot = 1
  L5_2 = "[green]"
  L6_2 = "[PmcCon018.HUD.PointsEarned] "
  L7_2 = tostring
  L8_2 = CurPoints
  L7_2 = L7_2(L8_2)
  L5_2 = L5_2 .. L6_2 .. L7_2
  L4_2.sText = L5_2
  L2_2(L3_2, L4_2)
  L3_2 = A1_2
  L2_2 = A1_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 0.5
  L5_2[1] = L6_2
  
  function L6_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = Hud
    L0_3 = L0_3.ObjectiveTray
    L1_3 = L0_3
    L0_3 = L0_3.SetSlotToText
    L2_3 = {}
    L2_3.nSlot = 1
    L3_3 = "[white]"
    L4_3 = "[PmcCon018.HUD.PointsEarned] "
    L5_3 = tostring
    L6_3 = CurPoints
    L5_3 = L5_3(L6_3)
    L3_3 = L3_3 .. L4_3 .. L5_3
    L2_3.sText = L3_3
    L0_3(L1_3, L2_3)
  end
  
  L2_2(L3_2, L4_2, L5_2, L6_2)
end

_AddPoints = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = table
  L1_2 = L1_2.getn
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if 0 < L1_2 then
    L2_2 = Math
    L2_2 = L2_2.randi
    L3_2 = 1
    L4_2 = L1_2
    L2_2 = L2_2(L3_2, L4_2)
    i = L2_2
  end
  L2_2 = i
  return L2_2
end

GetRandomTableIndex = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Player
  L1_2 = L1_2.GetSecondaryCharacter
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = Human
    L1_2 = L1_2.Inventory
    L1_2 = L1_2.GetAllWeapons
    L2_2 = Player
    L2_2 = L2_2.GetSecondaryCharacter
    L2_2, L3_2, L4_2, L5_2, L6_2 = L2_2()
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
    tLocalP2Weapons = L1_2
  end
  L2_2 = A0_2
  L1_2 = A0_2.GetNumCompletions
  L1_2 = L1_2(L2_2)
  if L1_2 == 0 then
    L2_2 = "[PmcCon018.objectives.001]"
    sDescription = L2_2
  elseif L1_2 == 1 then
    L2_2 = "[PmcCon018.objectives.002]"
    sDescription = L2_2
  else
    L2_2 = "[PmcCon018.objectives.003]"
    sDescription = L2_2
  end
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "Burnout"
  L4_2.sModuleName = "MrxTaskObjectiveDestroy"
  L5_2 = sDescription
  L4_2.sDspShortDesc = L5_2
  L4_2.vTgtInclude = "PMCCon018_Obj_marker"
  L4_2.bDspBlpWld = false
  L4_2.bDspBlpRdr = true
  L4_2.bDspBlpPda = true
  
  function L5_2()
    local L0_3, L1_3
    L0_3 = A0_2
    L0_3 = L0_3.Cancel
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L4_2.fOnCancel = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  oCurObjective = L2_2
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 10
  L5_2[1] = L6_2
  
  function L6_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._CreateEvent
    L2_3 = Event
    L2_3 = L2_3.Boundary
    L3_3 = {}
    L4_3 = Player
    L4_3 = L4_3.GetAnyCharacter
    L4_3 = L4_3()
    L5_3 = Pg
    L5_3 = L5_3.GetGuidByName
    L6_3 = "PMCCon018OutOfBounds"
    L5_3 = L5_3(L6_3)
    L6_3 = "exit"
    L3_3[1] = L4_3
    L3_3[2] = L5_3
    L3_3[3] = L6_3
    
    function L4_3()
      local L0_4, L1_4, L2_4, L3_4, L4_4, L5_4, L6_4
      L0_4 = MrxVoSequence
      L0_4 = L0_4.Start
      L1_4 = {}
      L2_4 = "Misha-In-Mission-MinorContract-Pmc18-05"
      L3_4 = {}
      L4_4 = _OutOfBounds
      L5_4 = {}
      L6_4 = A0_2
      L5_4[1] = L6_4
      L3_4[1] = L4_4
      L3_4[2] = L5_4
      L1_4[1] = L2_4
      L1_4[2] = L3_4
      L0_4(L1_4)
    end
    
    L0_3 = L0_3(L1_3, L2_3, L3_3, L4_3)
    P1BoundaryEvent = L0_3
  end
  
  L2_2(L3_2, L4_2, L5_2, L6_2)
end

_ObjectiveStart = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = AirStrikes
  if L1_2 == 2 then
    L1_2 = CurPoints
    L2_2 = PointGoal
    if L1_2 >= L2_2 then
      L1_2 = {}
      L2_2 = "Misha-In-Mission-MinorContract-Pmc18-06"
      L3_2 = "Misha-In-Mission-MinorContract-Pmc18-07"
      L4_2 = "Misha-In-Mission-MinorContract-Pmc18-08"
      L1_2[1] = L2_2
      L1_2[2] = L3_2
      L1_2[3] = L4_2
      tPossibleVO = L1_2
      L1_2 = MrxUtil
      L1_2 = L1_2.GetRandomTableElement
      L2_2 = tPossibleVO
      L1_2 = L1_2(L2_2)
      sVOLine = L1_2
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = sVOLine
      L4_2 = {}
      L5_2 = A0_2.Complete
      L6_2 = {}
      L7_2 = A0_2
      L6_2[1] = L7_2
      L4_2[1] = L5_2
      L4_2[2] = L6_2
      L2_2[1] = L3_2
      L2_2[2] = L4_2
      L1_2(L2_2)
    else
      L1_2 = CurPoints
      L2_2 = PointGoal
      if L1_2 < L2_2 then
        L2_2 = A0_2
        L1_2 = A0_2._SetCancelMessage
        L3_2 = "[PmcCon018.Terms.CancelPoints]"
        L1_2(L2_2, L3_2)
        L1_2 = A0_2.Cancel
        L2_2 = A0_2
        L1_2(L2_2)
      else
      end
    end
  end
end

_TimeUp = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2 = L1_2()
  uCharacter = L1_2
  L1_2 = Human
  L1_2 = L1_2.Inventory
  L1_2 = L1_2.GetAllWeapons
  L2_2 = uCharacter
  L1_2 = L1_2(L2_2)
  tP1Weapons = L1_2
  L1_2 = ipairs
  L2_2 = tP1Weapons
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Human
    L6_2 = L6_2.Inventory
    L6_2 = L6_2.DropWeapon
    L7_2 = uCharacter
    L8_2 = L5_2
    L6_2(L7_2, L8_2)
    L6_2 = Object
    L6_2 = L6_2.GetPosition
    L7_2 = uCharacter
    L6_2, L7_2, L8_2 = L6_2(L7_2)
    z = L8_2
    y = L7_2
    x = L6_2
    L6_2 = Object
    L6_2 = L6_2.DisablePhysics
    L7_2 = L5_2
    L6_2(L7_2)
    L6_2 = Object
    L6_2 = L6_2.SetPosition
    L7_2 = L5_2
    L8_2 = x
    L9_2 = y
    L9_2 = L9_2 - 5
    L10_2 = z
    L6_2(L7_2, L8_2, L9_2, L10_2)
  end
end

_SetupP1Weapons = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L0_2 = Player
  L0_2 = L0_2.GetSecondaryCharacter
  L0_2 = L0_2()
  uCharacter = L0_2
  L0_2 = Human
  L0_2 = L0_2.Inventory
  L0_2 = L0_2.GetAllWeapons
  L1_2 = uCharacter
  L0_2 = L0_2(L1_2)
  tP2Weapons = L0_2
  L0_2 = ipairs
  L1_2 = tP2Weapons
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
  end
  L0_2 = ipairs
  L1_2 = tP2Weapons
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = Human
    L5_2 = L5_2.Inventory
    L5_2 = L5_2.DropWeapon
    L6_2 = uCharacter
    L7_2 = L4_2
    L5_2(L6_2, L7_2)
    L5_2 = Object
    L5_2 = L5_2.GetPosition
    L6_2 = uCharacter
    L5_2, L6_2, L7_2 = L5_2(L6_2)
    z = L7_2
    y = L6_2
    x = L5_2
    L5_2 = Object
    L5_2 = L5_2.DisablePhysics
    L6_2 = L4_2
    L5_2(L6_2)
    L5_2 = Object
    L5_2 = L5_2.SetPosition
    L6_2 = L4_2
    L7_2 = x
    L8_2 = y
    L8_2 = L8_2 - 5
    L9_2 = z
    L5_2(L6_2, L7_2, L8_2, L9_2)
  end
  L0_2 = Player
  L0_2 = L0_2.SetAimMode
  L1_2 = Player
  L1_2 = L1_2.GetPrimaryPlayer
  L1_2 = L1_2()
  L2_2 = false
  L0_2(L1_2, L2_2)
  L0_2 = Player
  L0_2 = L0_2.SetAimMode
  L1_2 = Player
  L1_2 = L1_2.GetSecondaryPlayer
  L1_2 = L1_2()
  L2_2 = false
  L0_2(L1_2, L2_2)
end

SetP2Weapons = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  L5_2 = A0_2
  L4_2 = A0_2._CreateEvent
  L6_2 = Event
  L6_2 = L6_2.TimerRelative
  L7_2 = {}
  L8_2 = 10
  L7_2[1] = L8_2
  
  function L8_2()
    local L0_3, L1_3
    L0_3 = Player
    L0_3 = L0_3.GetSecondaryCharacter
    L0_3 = L0_3()
    if L0_3 then
      L0_3 = Human
      L0_3 = L0_3.Inventory
      L0_3 = L0_3.GetAllWeapons
      L1_3 = Player
      L1_3 = L1_3.GetSecondaryCharacter
      L1_3 = L1_3()
      L0_3 = L0_3(L1_3)
      tLocalP2Weapons = L0_3
    end
  end
  
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = P1BoundaryEvent
  if L4_2 then
    L4_2 = Event
    L4_2 = L4_2.Delete
    L5_2 = P1BoundaryEvent
    L4_2(L5_2)
    L4_2 = nil
    P1BoundaryEvent = L4_2
  end
  L5_2 = A0_2
  L4_2 = A0_2._CreateEvent
  L6_2 = Event
  L6_2 = L6_2.TimerRelative
  L7_2 = {}
  L8_2 = 10
  L7_2[1] = L8_2
  
  function L8_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = P1BoundaryEvent
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = P1BoundaryEvent
      L0_3(L1_3)
      L0_3 = nil
      P1BoundaryEvent = L0_3
    end
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._CreateEvent
    L2_3 = Event
    L2_3 = L2_3.Boundary
    L3_3 = {}
    L4_3 = Player
    L4_3 = L4_3.GetAnyCharacter
    L4_3 = L4_3()
    L5_3 = Pg
    L5_3 = L5_3.GetGuidByName
    L6_3 = "PMCCon018OutOfBounds"
    L5_3 = L5_3(L6_3)
    L6_3 = "exit"
    L3_3[1] = L4_3
    L3_3[2] = L5_3
    L3_3[3] = L6_3
    
    function L4_3()
      local L0_4, L1_4, L2_4, L3_4, L4_4, L5_4, L6_4
      L0_4 = MrxVoSequence
      L0_4 = L0_4.Start
      L1_4 = {}
      L2_4 = "Misha-In-Mission-MinorContract-Pmc18-05"
      L3_4 = {}
      L4_4 = _OutOfBounds
      L5_4 = {}
      L6_4 = A0_2
      L5_4[1] = L6_4
      L3_4[1] = L4_4
      L3_4[2] = L5_4
      L1_4[1] = L2_4
      L1_4[2] = L3_4
      L0_4(L1_4)
    end
    
    L0_3 = L0_3(L1_3, L2_3, L3_3, L4_3)
    P1BoundaryEvent = L0_3
  end
  
  L4_2(L5_2, L6_2, L7_2, L8_2)
end

OnPlayerJoined = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2
  L4_2 = MrxPmc
  L4_2 = L4_2.GetFreebieQty
  L5_2 = "[support.airstrike.laserguidedbomb.name]"
  L4_2 = L4_2(L5_2)
  nP1Freebies = L4_2
  L4_2 = bP2PresentAtStart
  if L4_2 then
    L4_2 = nP1Freebies
    L5_2 = AirStrikes
    L4_2 = L4_2 + L5_2
    if L4_2 == 1 then
      L4_2 = MrxSupportData
      L4_2 = L4_2.AddFreebie
      L5_2 = "Practice Laser"
      L4_2(L5_2)
    end
  end
end

OnPlayerLeft = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = _evClientJoinedPMC018
  L1_2(L2_2)
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 1
  L1_2(L2_2, L3_2)
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 2
  L1_2(L2_2, L3_2)
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 3
  L1_2(L2_2, L3_2)
  L1_2 = Hud
  L1_2 = L1_2.SupportMenu
  L2_2 = L1_2
  L1_2 = L1_2.SetShootingGalleryMode
  L3_2 = {}
  L3_2.bEnable = false
  L1_2(L2_2, L3_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = oCancelEvent
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = oMoneyUpdate
  L1_2(L2_2)
  L1_2 = OOBTimer
  if L1_2 then
    L1_2 = OOBTimer
    L2_2 = L1_2
    L1_2 = L1_2.Stop
    L1_2(L2_2)
  end
  L1_2 = MrxSupportData
  L1_2 = L1_2.RemoveFreebie
  L2_2 = "Practice Laser"
  L1_2(L2_2)
  L1_2 = ipairs
  L2_2 = tObjectsToDelete
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    if L5_2 == nil then
    else
      L6_2 = Object
      L6_2 = L6_2.Remove
      L7_2 = L5_2
      L6_2(L7_2)
    end
  end
  L1_2 = MrxLayerManager
  L1_2 = L1_2.MarkForRemoval
  L2_2 = {}
  L3_2 = "vz_State_PmcCon018_Veh"
  L4_2 = "vz_State_PmcCon018"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
  L1_2 = Player
  L1_2 = L1_2.SetAimMode
  L2_2 = Player
  L2_2 = L2_2.GetPrimaryPlayer
  L2_2 = L2_2()
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = Player
  L1_2 = L1_2.GetSecondaryPlayer
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = Player
    L1_2 = L1_2.SetAimMode
    L2_2 = Player
    L2_2 = L2_2.GetSecondaryPlayer
    L2_2 = L2_2()
    L3_2 = true
    L1_2(L2_2, L3_2)
  end
  L1_2 = Ai
  L1_2 = L1_2.SetRelation
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "OC"
  L2_2 = L2_2(L3_2)
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "PMC"
  L3_2 = L3_2(L4_2)
  L4_2 = OCRelation
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[PmcCon018.Terms.CancelOOB]"
  L1_2(L2_2, L3_2)
  L1_2 = OOBTimer
  if not L1_2 then
    L1_2 = MrxTimer
    L2_2 = L1_2
    L1_2 = L1_2.Create
    L3_2 = {}
    L3_2.nStartTime = 10
    L3_2.nStopTime = 0
    L3_2.nWarning = 5
    L3_2.iTray = 3
    L4_2 = {}
    L5_2 = {}
    L6_2 = Cancel
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L4_2[1] = L5_2
    L3_2.tDoneCallbacks = L4_2
    L1_2 = L1_2(L2_2, L3_2)
    OOBTimer = L1_2
  end
  L1_2 = OOBTimer
  L2_2 = L1_2
  L1_2 = L1_2.Start
  L1_2(L2_2)
  L1_2 = TurnOffTimer
  L2_2 = A0_2
  L1_2(L2_2)
end

_OutOfBounds = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAllCharacters
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "PMCCon018OutOfBounds"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = Player
    L0_3 = L0_3.GetSecondaryCharacter
    L0_3 = L0_3()
    if L0_3 then
      L0_3 = Object
      L0_3 = L0_3.InsideBoundary
      L1_3 = Player
      L1_3 = L1_3.GetPrimaryCharacter
      L1_3 = L1_3()
      L2_3 = Pg
      L2_3 = L2_3.GetGuidByName
      L3_3 = "PMCCon018OutOfBounds"
      L2_3, L3_3 = L2_3(L3_3)
      L0_3 = L0_3(L1_3, L2_3, L3_3)
      if L0_3 == true then
        L0_3 = Object
        L0_3 = L0_3.InsideBoundary
        L1_3 = Player
        L1_3 = L1_3.GetSecondaryCharacter
        L1_3 = L1_3()
        L2_3 = Pg
        L2_3 = L2_3.GetGuidByName
        L3_3 = "PMCCon018OutOfBounds"
        L2_3, L3_3 = L2_3(L3_3)
        L0_3 = L0_3(L1_3, L2_3, L3_3)
        if L0_3 == true then
          L0_3 = OOBTimer
          L1_3 = L0_3
          L0_3 = L0_3.Stop
          L0_3(L1_3)
          L0_3 = RestartOOB
          L1_3 = A0_2
          L0_3(L1_3)
      end
      else
        L0_3 = TurnOffTimer
        L1_3 = A0_2
        L0_3(L1_3)
      end
    else
      L0_3 = Object
      L0_3 = L0_3.InsideBoundary
      L1_3 = Player
      L1_3 = L1_3.GetPrimaryCharacter
      L1_3 = L1_3()
      L2_3 = Pg
      L2_3 = L2_3.GetGuidByName
      L3_3 = "PMCCon018OutOfBounds"
      L2_3, L3_3 = L2_3(L3_3)
      L0_3 = L0_3(L1_3, L2_3, L3_3)
      if L0_3 == true then
        L0_3 = OOBTimer
        L1_3 = L0_3
        L0_3 = L0_3.Stop
        L0_3(L1_3)
        L0_3 = RestartOOB
        L1_3 = A0_2
        L0_3(L1_3)
      else
        L0_3 = TurnOffTimer
        L1_3 = A0_2
        L0_3(L1_3)
      end
    end
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

TurnOffTimer = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "PMCCon018OutOfBounds"
  L6_2 = L6_2(L7_2)
  L7_2 = "exit"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = P1BoundaryEvent
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = P1BoundaryEvent
      L0_3(L1_3)
    end
    L0_3 = P2BoundaryEvent
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = P2BoundaryEvent
      L0_3(L1_3)
    end
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Misha-In-Mission-MinorContract-Pmc18-05"
    L3_3 = {}
    L4_3 = _OutOfBounds
    L5_3 = {}
    L6_3 = A0_2
    L5_3[1] = L6_3
    L3_3[1] = L4_3
    L3_3[2] = L5_3
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L0_3(L1_3)
  end
  
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  P1BoundaryEvent = L1_2
end

RestartOOB = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 10
  L5_2[1] = L6_2
  
  function L6_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3
    L0_3 = A1_2
    L1_3 = CurPoints
    if L0_3 == L1_3 then
      L0_3 = {}
      L1_3 = "Chris.BadNews03"
      L2_3 = "Chris.Misc.Negative01"
      L3_3 = "Chris.Misc.Negative02"
      L4_3 = "Chris.Misc.Negative03"
      L5_3 = "Chris.Misc.Negative04"
      L6_3 = "Chris.Misc.Negative05"
      L0_3[1] = L1_3
      L0_3[2] = L2_3
      L0_3[3] = L3_3
      L0_3[4] = L4_3
      L0_3[5] = L5_3
      L0_3[6] = L6_3
      tChrisNegativeVO = L0_3
      L0_3 = {}
      L1_3 = "Mattias.BadNews01"
      L2_3 = "Mattias.Misc.Negative05"
      L3_3 = "Mattias.Misc.Negative01"
      L4_3 = "Mattias.Misc.Negative04"
      L5_3 = "Mattias.Misc.Negative01"
      L6_3 = "Mattias.Misc.Negative02"
      L7_3 = "Mattias.Misc.Negative03"
      L8_3 = "Mattias.Misc.Negative04"
      L9_3 = "Mattias.Misc.Negative05"
      L10_3 = "Mattias.BadNews03"
      L0_3[1] = L1_3
      L0_3[2] = L2_3
      L0_3[3] = L3_3
      L0_3[4] = L4_3
      L0_3[5] = L5_3
      L0_3[6] = L6_3
      L0_3[7] = L7_3
      L0_3[8] = L8_3
      L0_3[9] = L9_3
      L0_3[10] = L10_3
      tMattiasNegativeVO = L0_3
      L0_3 = {}
      L1_3 = "Jen.Negative01"
      L2_3 = "Jen.Negative02"
      L3_3 = "Jen.Negative04"
      L4_3 = "Jen.Negative05"
      L5_3 = "Jen.BadNews01"
      L0_3[1] = L1_3
      L0_3[2] = L2_3
      L0_3[3] = L3_3
      L0_3[4] = L4_3
      L0_3[5] = L5_3
      tJenNegativeVO = L0_3
      L0_3 = MrxVoSequence
      L0_3 = L0_3.Start
      L1_3 = {}
      L2_3 = {}
      L3_3 = MrxUtil
      L3_3 = L3_3.GetRandomTableElement
      L4_3 = tMattiasNegativeVO
      L3_3 = L3_3(L4_3)
      L2_3.mattias = L3_3
      L3_3 = MrxUtil
      L3_3 = L3_3.GetRandomTableElement
      L4_3 = tJenNegativeVO
      L3_3 = L3_3(L4_3)
      L2_3.jennifer = L3_3
      L3_3 = MrxUtil
      L3_3 = L3_3.GetRandomTableElement
      L4_3 = tChrisNegativeVO
      L3_3 = L3_3(L4_3)
      L2_3.chris = L3_3
      L1_3[1] = L2_3
      L0_3(L1_3)
    end
  end
  
  L2_2(L3_2, L4_2, L5_2, L6_2)
end

AirStrikeVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2 = L1_2()
  uCharacter = L1_2
  L1_2 = Net
  L1_2 = L1_2.SendCustomEvent
  L2_2 = "PmcCon018"
  L3_2 = NETEVENT_RETURNWEAPONS
  L4_2 = {}
  L5_2 = true
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = Human
  L1_2 = L1_2.Inventory
  L1_2 = L1_2.SetAllWeapons
  L2_2 = uCharacter
  L3_2 = tP1Weapons
  L1_2(L2_2, L3_2)
  L1_2 = Human
  L1_2 = L1_2.DisableWeapons
  L2_2 = uCharacter
  L1_2(L2_2)
  L1_2 = Player
  L1_2 = L1_2.GetSecondaryCharacter
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = Human
    L1_2 = L1_2.DisableWeapons
    L2_2 = Player
    L2_2 = L2_2.GetSecondaryCharacter
    L2_2, L3_2, L4_2, L5_2 = L2_2()
    L1_2(L2_2, L3_2, L4_2, L5_2)
  end
  L1_2 = MrxAchievements
  L1_2 = L1_2.NetGrantAchievement
  L2_2 = "ACHIEVEMENT_GONE_SHOOTIN"
  L1_2(L2_2)
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Complete
  L2_2 = A0_2
  L1_2(L2_2)
end

Complete = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2 = L1_2()
  uCharacter = L1_2
  L1_2 = Net
  L1_2 = L1_2.SendCustomEvent
  L2_2 = "PmcCon018"
  L3_2 = NETEVENT_RETURNWEAPONS
  L4_2 = {}
  L5_2 = true
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = Human
  L1_2 = L1_2.Inventory
  L1_2 = L1_2.SetAllWeapons
  L2_2 = uCharacter
  L3_2 = tP1Weapons
  L1_2(L2_2, L3_2)
  L1_2 = Human
  L1_2 = L1_2.DisableWeapons
  L2_2 = uCharacter
  L1_2(L2_2)
  L1_2 = Player
  L1_2 = L1_2.GetSecondaryCharacter
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = Human
    L1_2 = L1_2.DisableWeapons
    L2_2 = Player
    L2_2 = L2_2.GetSecondaryCharacter
    L2_2, L3_2, L4_2, L5_2 = L2_2()
    L1_2(L2_2, L3_2, L4_2, L5_2)
  end
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cancel
  L2_2 = A0_2
  L1_2(L2_2)
end

Cancel = L0_1
