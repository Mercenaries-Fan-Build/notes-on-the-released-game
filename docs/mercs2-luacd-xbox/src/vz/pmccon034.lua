local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxMultiPageMenu"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxLayerManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxShootingGallery"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTimer"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxAchievements"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxMusic"
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
        L2_2 = Object
        L2_2 = L2_2.SetInfiniteAmmo
        L3_2 = uCharacter
        L4_2 = false
        L2_2(L3_2, L4_2)
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
      end
    end
  end
end

NetEventCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = {}
  L3_2 = "vz_state_pmc"
  L4_2 = "Vz_State_PmcCon034"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  tLayersToAdd = L2_2
  L2_2 = Hud
  L2_2 = L2_2.SupportMenu
  L3_2 = L2_2
  L2_2 = L2_2.SetShootingGalleryMode
  L4_2 = {}
  L4_2.bEnable = true
  L2_2(L3_2, L4_2)
  L2_2 = MrxLayerManager
  L2_2 = L2_2.Add
  L3_2 = tLayersToAdd
  L4_2 = A0_2.AssetsLoaded
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = {}
  L3_2 = "Vz_State_PmcCon034"
  L2_2[1] = L3_2
  tLayersToAdd = L2_2
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
      L1_3 = "PmcCon034"
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
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Hud
  L1_2 = L1_2.SupportMenu
  L2_2 = L1_2
  L1_2 = L1_2.SetShootingGalleryMode
  L3_2 = {}
  L3_2.bEnable = true
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetNumCompletions
  L1_2 = L1_2(L2_2)
  if L1_2 == 0 then
    L2_2 = 90
    nTimeLimit = L2_2
    L2_2 = "1:30"
    TimeLimitDsp = L2_2
  elseif L1_2 == 1 then
    L2_2 = 60
    nTimeLimit = L2_2
    L2_2 = "1:00"
    TimeLimitDsp = L2_2
  elseif 2 <= L1_2 then
    L2_2 = 30
    nTimeLimit = L2_2
    L2_2 = "0:30"
    TimeLimitDsp = L2_2
  end
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
    L6_3 = "LR_PMCOOB"
    L5_3 = L5_3(L6_3)
    L6_3 = "exit"
    L3_3[1] = L4_3
    L3_3[2] = L5_3
    L3_3[3] = L6_3
    
    function L4_3()
      local L0_4, L1_4, L2_4
      L0_4 = A0_2
      L1_4 = L0_4
      L0_4 = L0_4._SetCancelMessage
      L2_4 = "[PmcCon034.Terms.CancelOOB]"
      L0_4(L1_4, L2_4)
      L0_4 = A0_2
      L1_4 = L0_4
      L0_4 = L0_4.Cancel
      L0_4(L1_4)
    end
    
    L0_3(L1_3, L2_3, L3_3, L4_3)
  end
  
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L2_2 = PlayMusic
  L3_2 = A0_2
  L4_2 = nTimeLimit
  L2_2(L3_2, L4_2)
  L2_2 = _CountDownVOSetup
  L3_2 = A0_2
  L4_2 = nTimeLimit
  L2_2(L3_2, L4_2)
  L2_2 = Event
  L2_2 = L2_2.CreatePersistent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "mpPlayerJoin"
  
  function L6_2(A0_3)
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
  
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = Net
  L5_2 = L5_2.SendCustomEvent
  L6_2 = {}
  L7_2 = "PmcCon034"
  L8_2 = NETEVENT_SETSTARTUPWEAPONS
  L9_2 = {}
  L10_2 = true
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  _evClientJoinedPMC034 = L2_2
  L2_2 = Net
  L2_2 = L2_2.SendCustomEvent
  L3_2 = "PmcCon034"
  L4_2 = NETEVENT_SETSTARTUPWEAPONS
  L5_2 = {}
  L6_2 = true
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L3_2 = A0_2
  L2_2 = A0_2._SetupObjective
  L4_2 = A0_2
  L2_2(L3_2, L4_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2
  L1_2 = Player
  L1_2 = L1_2.GetSecondaryCharacter
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = Human
    L1_2 = L1_2.Inventory
    L1_2 = L1_2.GetAllWeapons
    L2_2 = Player
    L2_2 = L2_2.GetSecondaryCharacter
    L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2 = L2_2()
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2)
    tLocalP2Weapons = L1_2
  end
  L1_2 = 0
  iTruckTargetNum = L1_2
  L1_2 = _CallTruckTarget
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = MrxTimer
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L3_2 = {}
  L3_2.nStartTime = 0
  L3_2.nStopTime = 600
  L3_2.nStep = 0.1
  L3_2.iTray = 2
  L4_2 = nTimeLimit
  L3_2.nWarning = L4_2
  L3_2.bUseTenths = true
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2._SetCancelMessage
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = "[PmcCon032.Terms.CancelTime]"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = {}
  L7_2 = A0_2.Cancel
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L3_2.tDoneCallbacks = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  A0_2.CourseTimer = L1_2
  L1_2 = A0_2.CourseTimer
  L2_2 = L1_2
  L1_2 = L1_2.Start
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetNumCompletions
  L1_2 = L1_2(L2_2)
  if L1_2 <= 1 then
    L1_2 = MrxVoSequence
    L1_2 = L1_2.Start
    L2_2 = {}
    L3_2 = "Fiona-In-Mission-MinorContract-Pmc34-03"
    L2_2[1] = L3_2
    L1_2(L2_2)
  end
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.SetSlotToText
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 1
  L4_2 = "[PmcCon032.Terms.TimeToBeatText] "
  L5_2 = TimeLimitDsp
  L4_2 = L4_2 .. L5_2
  L3_2.sText = L4_2
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "DestroyStatues"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L3_2.sDspShortDesc = "[PmcCon034.Objectives.DestroyStuff]"
  L4_2 = {}
  L5_2 = "PMC011_SniperStatue_Easy1"
  L6_2 = "PMC011_SniperStatue_Easy2"
  L7_2 = "PMC011_SniperStatue_Easy3"
  L8_2 = "PMC011_SniperStatue_Easy4"
  L9_2 = "PMC011_SniperStatue_Easy5"
  L10_2 = "PMC011_SniperStatue_Easy6"
  L11_2 = "PMC011_SniperStatue_Easy7"
  L12_2 = "PMC011_SniperStatue_Easy8"
  L13_2 = "PMC011_SniperStatue_Easy9"
  L14_2 = "PMC011_SniperStatue_Easy10"
  L15_2 = "PMC011_SniperStatue_Easy11"
  L16_2 = "PMC011_SniperStatue_Easy12"
  L17_2 = "PMC011_SniperStatue_Easy13"
  L18_2 = "PMC011_SniperStatue_Easy14"
  L19_2 = "PMC011_SniperStatue_Easy15"
  L20_2 = "PMC011_SniperStatue_Easy16"
  L21_2 = "PMC011_SniperStatue_Easy17"
  L22_2 = "PMC011_SniperStatue_Easy18"
  L23_2 = "PMC011_SniperStatue_Easy19"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L4_2[7] = L11_2
  L4_2[8] = L12_2
  L4_2[9] = L13_2
  L4_2[10] = L14_2
  L4_2[11] = L15_2
  L4_2[12] = L16_2
  L4_2[13] = L17_2
  L4_2[14] = L18_2
  L4_2[15] = L19_2
  L4_2[16] = L20_2
  L4_2[17] = L21_2
  L4_2[18] = L22_2
  L4_2[19] = L23_2
  L3_2.vTgtInclude = L4_2
  
  function L4_2()
    local L0_3, L1_3, L2_3
    L0_3 = A0_2
    L0_3 = L0_3.CourseTimer
    L1_3 = L0_3
    L0_3 = L0_3.GetTime
    L0_3 = L0_3(L1_3)
    EndTime = L0_3
    L0_3 = EndTime
    L1_3 = nTimeLimit
    if L0_3 > L1_3 then
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._SetCancelMessage
      L2_3 = "[PmcCon032.Terms.CancelTime]"
      L0_3(L1_3, L2_3)
      L0_3 = A0_2
      L0_3 = L0_3.CourseTimer
      L1_3 = L0_3
      L0_3 = L0_3.Pause
      L0_3(L1_3)
      L0_3 = A0_2
      L0_3 = L0_3.Cancel
      L1_3 = A0_2
      L0_3(L1_3)
    else
      L0_3 = CompleteVO
      L1_3 = A0_2
      L0_3(L1_3)
    end
  end
  
  L3_2.fOnComplete = L4_2
  L1_2(L2_2, L3_2)
  L1_2 = _AttachStatue
  L2_2 = A0_2
  L1_2(L2_2)
end

_SetupObjective = L0_1

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
  L1_2 = Human
  L1_2 = L1_2.Inventory
  L1_2 = L1_2.SetAllWeapons
  L2_2 = uCharacter
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "Anti-Material Rifle"
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L3_2(L4_2)
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  L1_2 = Object
  L1_2 = L1_2.SetInfiniteAmmo
  L2_2 = uCharacter
  L3_2 = true
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 10
  L4_2[1] = L5_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._CreateEvent
    L2_3 = Event
    L2_3 = L2_3.Boundary
    L3_3 = {}
    L4_3 = Player
    L4_3 = L4_3.GetPrimaryCharacter
    L4_3 = L4_3()
    L5_3 = Pg
    L5_3 = L5_3.GetGuidByName
    L6_3 = "PMCCon034OutOfBounds"
    L5_3 = L5_3(L6_3)
    L6_3 = "exit"
    L3_3[1] = L4_3
    L3_3[2] = L5_3
    L3_3[3] = L6_3
    
    function L4_3()
      local L0_4, L1_4, L2_4, L3_4, L4_4, L5_4, L6_4
      L0_4 = A0_2
      L1_4 = L0_4
      L0_4 = L0_4._SetCancelMessage
      L2_4 = "[PmcCon034.Terms.CancelOOB]"
      L0_4(L1_4, L2_4)
      L0_4 = MrxVoSequence
      L0_4 = L0_4.Start
      L1_4 = {}
      L2_4 = "Fiona-In-Mission-MinorContract-Pmc31-10"
      L3_4 = {}
      L4_4 = A0_2
      L4_4 = L4_4.Cancel
      L5_4 = {}
      L6_4 = A0_2
      L5_4[1] = L6_4
      L3_4[1] = L4_4
      L3_4[2] = L5_4
      L1_4[1] = L2_4
      L1_4[2] = L3_4
      L0_4(L1_4)
    end
    
    L0_3(L1_3, L2_3, L3_3, L4_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
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
  L0_2 = Human
  L0_2 = L0_2.Inventory
  L0_2 = L0_2.SetAllWeapons
  L1_2 = uCharacter
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "Anti-Material Rifle"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L2_2(L3_2)
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  L0_2 = Object
  L0_2 = L0_2.SetInfiniteAmmo
  L1_2 = uCharacter
  L2_2 = true
  L0_2(L1_2, L2_2)
end

SetP2Weapons = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "UH1 Transport (PMC) 0x00126e26"
  L1_2 = L1_2(L2_2)
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L5_2 = Pg
  L5_2 = L5_2.Spawn
  L6_2 = "_pmcoutpost_statueSolanobust_lowHP"
  L7_2 = L2_2
  L8_2 = L3_2 + 200
  L9_2 = L4_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  uCargo = L5_2
  L6_2 = A0_2
  L5_2 = A0_2._CreateEvent
  L7_2 = Event
  L7_2 = L7_2.ObjectHibernation
  L8_2 = {}
  L9_2 = L1_2
  L10_2 = "awake"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  
  function L9_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._CreateEvent
    L2_3 = Event
    L2_3 = L2_3.ObjectHibernation
    L3_3 = {}
    L4_3 = uCargo
    L5_3 = "awake"
    L3_3[1] = L4_3
    L3_3[2] = L5_3
    
    function L4_3()
      local L0_4, L1_4, L2_4, L3_4
      L0_4 = _DeployWinch
      L1_4 = L1_2
      L2_4 = uCargo
      L3_4 = A0_2
      L0_4(L1_4, L2_4, L3_4)
      L0_4 = A0_2
      L1_4 = L0_4
      L0_4 = L0_4.CreateChild
      L2_4 = {}
      L2_4.sName = "WinchStatue"
      L2_4.sModuleName = "MrxTaskObjectiveDestroy"
      L3_4 = uCargo
      L2_4.vTgtInclude = L3_4
      L2_4.sDspShortDesc = "[PmcCon034.Objectives.DestroyBonusStatue]"
      L2_4.bOptional = true
      
      function L3_4()
        local L0_5, L1_5, L2_5, L3_5, L4_5, L5_5, L6_5
        L0_5 = A0_2
        L1_5 = L0_5
        L0_5 = L0_5._CreateEvent
        L2_5 = Event
        L2_5 = L2_5.TimerRelative
        L3_5 = {}
        L4_5 = 10
        L3_5[1] = L4_5
        L4_5 = _AttachStatue
        L5_5 = {}
        L6_5 = A0_2
        L5_5[1] = L6_5
        L0_5 = L0_5(L1_5, L2_5, L3_5, L4_5, L5_5)
        oStatueTimer = L0_5
        L0_5 = _MinusTime
        L1_5 = A0_2
        L0_5(L1_5)
      end
      
      L2_4.fOnComplete = L3_4
      L0_4(L1_4, L2_4)
    end
    
    L0_3(L1_3, L2_3, L3_3, L4_3)
  end
  
  L5_2(L6_2, L7_2, L8_2, L9_2)
end

_AttachStatue = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = Object
  L3_2 = L3_2.SetWinchState
  L4_2 = A0_2
  L5_2 = "deployed"
  L3_2(L4_2, L5_2)
  L4_2 = A2_2
  L3_2 = A2_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = 0.1
  L6_2[1] = L7_2
  L7_2 = AttachCargo
  L8_2 = {}
  L9_2 = A0_2
  L10_2 = A1_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
end

_DeployWinch = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = Object
  L2_2 = L2_2.AttachCargoToWinch
  L3_2 = A1_2
  L4_2 = A0_2
  L2_2(L3_2, L4_2)
end

AttachCargo = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = PauseTimer
  if L1_2 then
    L1_2 = PauseTimer
    L2_2 = L1_2
    L1_2 = L1_2.Stop
    L1_2(L2_2)
  end
  L1_2 = MainTimerPause
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = MainTimerPause
    L1_2(L2_2)
  end
  L1_2 = A0_2.CourseTimer
  L2_2 = L1_2
  L1_2 = L1_2.Pause
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 5
  L4_2[1] = L5_2
  
  function L5_2()
    local L0_3, L1_3
    L0_3 = A0_2
    L0_3 = L0_3.CourseTimer
    L1_3 = L0_3
    L0_3 = L0_3.Resume
    L0_3(L1_3)
  end
  
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  MainTimerPause = L1_2
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.SetSlotToText
  L3_2 = {}
  L3_2.nSlot = 3
  L3_2.sText = "[green][PmcCon031.Terms.BonusTimePlus]"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 5
  L4_2[1] = L5_2
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = Hud
    L0_3 = L0_3.ObjectiveTray
    L1_3 = L0_3
    L0_3 = L0_3.ClearSlot
    L2_3 = {}
    L2_3.vPlayer = nil
    L2_3.nSlot = 3
    L0_3(L1_3, L2_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = _FixTimers
  L2_2 = A0_2
  L1_2(L2_2)
end

_MinusTime = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = _TruckTarget
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 43
  L4_2[1] = L5_2
  L5_2 = _CallTruckTarget
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

_CallTruckTarget = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = Pg
  L1_2 = L1_2.Spawn
  L2_2 = "El Grande (Driver)"
  L3_2 = 2663.6062
  L4_2 = -12.248225
  L5_2 = -938.5005
  L6_2 = false
  L7_2 = true
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  TruckSpawn = L1_2
  L1_2 = Pg
  L1_2 = L1_2.Spawn
  L2_2 = "_pmcoutpost_statueSolanobust_lowHP"
  L3_2 = 2665.4568
  L4_2 = -13.856117
  L5_2 = -940.5367
  L6_2 = 0
  L7_2 = false
  L8_2 = true
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  StatueSpawn = L1_2
  L1_2 = Object
  L1_2 = L1_2.SetTransformToObject
  L2_2 = TruckSpawn
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "TruckMoveLoc"
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L3_2(L4_2)
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  L1_2 = Object
  L1_2 = L1_2.SetTransformToObject
  L2_2 = StatueSpawn
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "StatueMoveLoc"
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L3_2(L4_2)
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  L1_2 = "TruckStatue"
  L2_2 = iTruckTargetNum
  L1_2 = L1_2 .. L2_2
  sTruckObjName = L1_2
  L1_2 = iTruckTargetNum
  L1_2 = L1_2 + 1
  iTruckTargetNum = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L4_2 = sTruckObjName
  L3_2.sName = L4_2
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = StatueSpawn
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[PmcCon034.Objectives.DestroyBonusStatue]"
  L3_2.bOptional = true
  
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = _MinusTime
    L1_3 = A0_2
    L0_3(L1_3)
    L0_3 = {}
    L1_3 = "Fiona.Cam.02"
    L2_3 = "Fiona.xfio168"
    L3_3 = "Fiona-In-Mission-Contract-Chi02-33"
    L4_3 = "Fiona.va3fio12"
    L5_3 = "Fiona-In-Mission-MinorContract-Pmc33-01"
    L0_3[1] = L1_3
    L0_3[2] = L2_3
    L0_3[3] = L3_3
    L0_3[4] = L4_3
    L0_3[5] = L5_3
    tVoTable = L0_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = MrxUtil
    L2_3 = L2_3.GetRandomTableElement
    L3_3 = tVoTable
    L2_3, L3_3, L4_3, L5_3 = L2_3(L3_3)
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L1_3[3] = L4_3
    L1_3[4] = L5_3
    L0_3(L1_3)
  end
  
  L3_2.fOnComplete = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  TruckObj = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 2
  L4_2[1] = L5_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = Ai
    L0_3 = L0_3.Goal
    L1_3 = {}
    L2_3 = Vehicle
    L2_3 = L2_3.GetDriver
    L3_3 = TruckSpawn
    L2_3 = L2_3(L3_3)
    L1_3.AIGuid = L2_3
    L1_3.Goal = "PathMove"
    L2_3 = Pg
    L2_3 = L2_3.GetGuidByName
    L3_3 = "Path 0x00126fc1"
    L2_3 = L2_3(L3_3)
    L1_3.Target = L2_3
    L1_3.Priority = "HiPri"
    L1_3.Haste = 0.15
    L2_3 = _KillTruckStatue
    L1_3.Callback = L2_3
    L2_3 = {}
    L3_3 = TruckSpawn
    L4_3 = StatueSpawn
    L5_3 = TruckObj
    L2_3[1] = L3_3
    L2_3[2] = L4_3
    L2_3[3] = L5_3
    L1_3.CallbackData = L2_3
    L0_3(L1_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

_TruckTarget = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  L3_2 = Object
  L3_2 = L3_2.Remove
  L4_2 = A0_2
  L3_2(L4_2)
  L3_2 = Object
  L3_2 = L3_2.Remove
  L4_2 = A1_2
  L3_2(L4_2)
  L3_2 = A2_2.Cancel
  L4_2 = A2_2
  L3_2(L4_2)
end

_KillTruckStatue = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = MrxMusic
  L2_2 = L2_2.PlaySpecialMusic
  L3_2 = "mu_mission_pmccon034_01"
  L2_2(L3_2)
  L2_2 = A1_2 - 25
  SecondsTilSpeedUp = L2_2
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = SecondsTilSpeedUp
  L5_2[1] = L6_2
  
  function L6_2()
    local L0_3, L1_3
    L0_3 = MrxMusic
    L0_3 = L0_3.PlaySpecialMusic
    L1_3 = "mu_mission_pmccon034_02"
    L0_3(L1_3)
  end
  
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  uMusicStartEvent = L2_2
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = A1_2
  L5_2[1] = L6_2
  
  function L6_2()
    local L0_3, L1_3
    L0_3 = MrxMusic
    L0_3 = L0_3.PlaySpecialMusic
    L1_3 = "mu_mission_pmccon034_01"
    L0_3(L1_3)
  end
  
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  uMusicEndEvent = L2_2
end

PlayMusic = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = A1_2
  L5_2[1] = L6_2
  L6_2 = FailureVO
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  uCountdownFail = L2_2
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = A1_2 - 6.5
  L5_2[1] = L6_2
  L6_2 = MrxVoSequence
  L6_2 = L6_2.Start
  L7_2 = {}
  L8_2 = "Fiona-In-Mission-MinorContract-Pmc31-13"
  L7_2[1] = L8_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  uCountdown5 = L2_2
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = A1_2 - 16.5
  L5_2[1] = L6_2
  L6_2 = MrxVoSequence
  L6_2 = L6_2.Start
  L7_2 = {}
  L8_2 = "Fiona-In-Mission-MinorContract-Pmc31-12"
  L7_2[1] = L8_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  uCountdown15 = L2_2
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = A1_2 - 31.5
  L5_2[1] = L6_2
  L6_2 = MrxVoSequence
  L6_2 = L6_2.Start
  L7_2 = {}
  L8_2 = "Fiona-In-Mission-MinorContract-Pmc11-01"
  L7_2[1] = L8_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  uCountdown30 = L2_2
  L2_2 = {}
  L3_2 = "Chris.BadNews03"
  L4_2 = "Chris.Misc.Negative01"
  L5_2 = "Chris.Misc.Negative02"
  L6_2 = "Chris.Misc.Negative03"
  L7_2 = "Chris.Misc.Negative04"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  tChrisNegativeVO = L2_2
  L2_2 = {}
  L3_2 = "Mattias.BadNews01"
  L4_2 = "Mattias.Misc.Negative05"
  L5_2 = "Mattias.Misc.Negative01"
  L6_2 = "Mattias.Misc.Negative01"
  L7_2 = "Mattias.Misc.Negative02"
  L8_2 = "Mattias.Misc.Negative03"
  L9_2 = "Mattias.Misc.Negative04"
  L10_2 = "Mattias.Misc.Negative05"
  L11_2 = "Mattias.BadNews03"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L2_2[6] = L8_2
  L2_2[7] = L9_2
  L2_2[8] = L10_2
  L2_2[9] = L11_2
  tMattiasNegativeVO = L2_2
  L2_2 = {}
  L3_2 = "Jen.Negative01"
  L4_2 = "Jen.Negative02"
  L5_2 = "Jen.Negative05"
  L6_2 = "Jen.BadNews01"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  tJenNegativeVO = L2_2
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = A1_2 - 3
  L5_2[1] = L6_2
  
  function L6_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
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
  
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  uCountdownHero = L2_2
  L2_2 = uMusicStartEvent
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = uMusicStartEvent
    L2_2(L3_2)
    L3_2 = A0_2
    L2_2 = A0_2._CreateEvent
    L4_2 = Event
    L4_2 = L4_2.TimerRelative
    L5_2 = {}
    L6_2 = A1_2 - 25
    L5_2[1] = L6_2
    
    function L6_2()
      local L0_3, L1_3
      L0_3 = MrxMusic
      L0_3 = L0_3.PlaySpecialMusic
      L1_3 = "mu_mission_pmccon034_02"
      L0_3(L1_3)
      L0_3 = nil
      uMusicStartEvent = L0_3
    end
    
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
    uMusicStartEvent = L2_2
  end
  L2_2 = uMusicEndEvent
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = uMusicEndEvent
    L2_2(L3_2)
    L3_2 = A0_2
    L2_2 = A0_2._CreateEvent
    L4_2 = Event
    L4_2 = L4_2.TimerRelative
    L5_2 = {}
    L6_2 = A1_2 - 25
    L5_2[1] = L6_2
    
    function L6_2()
      local L0_3, L1_3
      L0_3 = MrxMusic
      L0_3 = L0_3.PlaySpecialMusic
      L1_3 = "mu_mission_pmccon034_01"
      L0_3(L1_3)
      L0_3 = nil
      uMusicEndEvent = L0_3
    end
    
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
    uMusicEndEvent = L2_2
  end
end

_CountDownVOSetup = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = A0_2.CourseTimer
  L2_2 = L1_2
  L1_2 = L1_2.GetTime
  L1_2 = L1_2(L2_2)
  TimeLeft = L1_2
  L1_2 = nTimeLimit
  L2_2 = TimeLeft
  L1_2 = L1_2 - L2_2
  TimeLeft = L1_2
  L1_2 = TimeLeft
  L1_2 = L1_2 + 5
  TimeLeft = L1_2
  L1_2 = uCountdownFail
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uCountdownFail
    L1_2(L2_2)
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = TimeLeft
    L4_2[1] = L5_2
    
    function L5_2()
      local L0_3, L1_3
      L0_3 = FailureVO
      L1_3 = A0_2
      L0_3(L1_3)
      L0_3 = nil
      uCountdownFail = L0_3
    end
    
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
    uCountdownFail = L1_2
  end
  L1_2 = uCountdown5
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uCountdown5
    L1_2(L2_2)
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = TimeLeft
    L5_2 = L5_2 - 6.5
    L4_2[1] = L5_2
    
    function L5_2()
      local L0_3, L1_3
      L0_3 = MrxVoSequence
      L0_3 = L0_3.Start
      L1_3 = "Fiona-In-Mission-MinorContract-Pmc31-13"
      L0_3(L1_3)
      L0_3 = nil
      uCountdown5 = L0_3
    end
    
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
    uCountdown5 = L1_2
  end
  L1_2 = uCountdown15
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uCountdown15
    L1_2(L2_2)
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = TimeLeft
    L5_2 = L5_2 - 16.5
    L4_2[1] = L5_2
    
    function L5_2()
      local L0_3, L1_3
      L0_3 = MrxVoSequence
      L0_3 = L0_3.Start
      L1_3 = "Fiona-In-Mission-MinorContract-Pmc31-12"
      L0_3(L1_3)
      L0_3 = nil
      uCountdown15 = L0_3
    end
    
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
    uCountdown15 = L1_2
  end
  L1_2 = uCountdown30
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uCountdown30
    L1_2(L2_2)
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = TimeLeft
    L5_2 = L5_2 - 31.5
    L4_2[1] = L5_2
    
    function L5_2()
      local L0_3, L1_3
      L0_3 = MrxVoSequence
      L0_3 = L0_3.Start
      L1_3 = "Fiona-In-Mission-MinorContract-Pmc11-01"
      L0_3(L1_3)
      L0_3 = nil
      uCountdown30 = L0_3
    end
    
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
    uCountdown30 = L1_2
  end
  L1_2 = uMusicStartEvent
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uMusicStartEvent
    L1_2(L2_2)
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = TimeLeft
    L5_2 = L5_2 - 25
    L4_2[1] = L5_2
    
    function L5_2()
      local L0_3, L1_3
      L0_3 = MrxMusic
      L0_3 = L0_3.PlaySpecialMusic
      L1_3 = "mu_mission_pmccon034_02"
      L0_3(L1_3)
      L0_3 = nil
      uMusicStartEvent = L0_3
    end
    
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
    uMusicStartEvent = L1_2
  end
  L1_2 = uMusicEndEvent
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uMusicEndEvent
    L1_2(L2_2)
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = TimeLeft
    L5_2 = L5_2 - 25
    L4_2[1] = L5_2
    
    function L5_2()
      local L0_3, L1_3
      L0_3 = MrxMusic
      L0_3 = L0_3.PlaySpecialMusic
      L1_3 = "mu_mission_pmccon034_01"
      L0_3(L1_3)
      L0_3 = nil
      uMusicEndEvent = L0_3
    end
    
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
    uMusicEndEvent = L1_2
  end
  L1_2 = uCountdownHero
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uCountdownHero
    L1_2(L2_2)
    L1_2 = {}
    L2_2 = "Chris.BadNews03"
    L3_2 = "Chris.Misc.Negative01"
    L4_2 = "Chris.Misc.Negative02"
    L5_2 = "Chris.Misc.Negative03"
    L6_2 = "Chris.Misc.Negative04"
    L1_2[1] = L2_2
    L1_2[2] = L3_2
    L1_2[3] = L4_2
    L1_2[4] = L5_2
    L1_2[5] = L6_2
    tChrisNegativeVO = L1_2
    L1_2 = {}
    L2_2 = "Mattias.BadNews01"
    L3_2 = "Mattias.Misc.Negative05"
    L4_2 = "Mattias.Misc.Negative01"
    L5_2 = "Mattias.Misc.Negative01"
    L6_2 = "Mattias.Misc.Negative02"
    L7_2 = "Mattias.Misc.Negative03"
    L8_2 = "Mattias.Misc.Negative04"
    L9_2 = "Mattias.Misc.Negative05"
    L10_2 = "Mattias.BadNews03"
    L1_2[1] = L2_2
    L1_2[2] = L3_2
    L1_2[3] = L4_2
    L1_2[4] = L5_2
    L1_2[5] = L6_2
    L1_2[6] = L7_2
    L1_2[7] = L8_2
    L1_2[8] = L9_2
    L1_2[9] = L10_2
    tMattiasNegativeVO = L1_2
    L1_2 = {}
    L2_2 = "Jen.Negative01"
    L3_2 = "Jen.Negative02"
    L4_2 = "Jen.Negative05"
    L5_2 = "Jen.BadNews01"
    L1_2[1] = L2_2
    L1_2[2] = L3_2
    L1_2[3] = L4_2
    L1_2[4] = L5_2
    tJenNegativeVO = L1_2
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = TimeLeft
    L5_2 = L5_2 - 3
    L4_2[1] = L5_2
    
    function L5_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3
      uCountdownHero = L0_3
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
    
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
    uCountdownHero = L1_2
  end
end

_FixTimers = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = uCountdownFail
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uCountdownFail
    L1_2(L2_2)
  end
  L1_2 = uCountdown5
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uCountdown5
    L1_2(L2_2)
  end
  L1_2 = uCountdown15
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uCountdown15
    L1_2(L2_2)
  end
  L1_2 = uCountdown30
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uCountdown30
    L1_2(L2_2)
  end
  L1_2 = A0_2.CourseTimer
  L2_2 = L1_2
  L1_2 = L1_2.Pause
  L1_2(L2_2)
  L1_2 = {}
  L2_2 = "Fiona-In-Mission-MinorContract-Pmc31-02"
  L3_2 = "Fiona-In-Mission-MinorContract-Pmc31-20"
  L4_2 = "Fiona-In-Mission-MinorContract-Pmc31-21"
  L5_2 = "Fiona-In-Mission-MinorContract-Pmc32-01"
  L6_2 = "Fiona-In-Mission-MinorContract-Pmc32-02"
  L7_2 = "Fiona-In-Mission-MinorContract-Pmc34-01"
  L8_2 = "Fiona-In-Mission-MinorContract-Pmc31-33"
  L9_2 = "Fiona-In-Mission-MinorContract-Pmc31-35"
  L10_2 = "Fiona-In-Mission-MinorContract-Pmc33-01"
  L11_2 = "Fiona-In-Mission-MinorContract-Pmc33-01"
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
  L5_2 = Complete
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
end

CompleteVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = {}
  L2_2 = "Fiona-In-Mission-MinorContract-Pmc31-04"
  L3_2 = "Fiona-In-Mission-MinorContract-Pmc31-11"
  L4_2 = "Fiona-In-Mission-MinorContract-Pmc31-14"
  L5_2 = "Fiona-In-Mission-MinorContract-Pmc31-15"
  L6_2 = "Fiona-In-Mission-MinorContract-Pmc31-16"
  L7_2 = "Fiona-In-Mission-MinorContract-Pmc31-22"
  L8_2 = "Fiona-In-Mission-MinorContract-Pmc31-23"
  L9_2 = "Fiona-In-Mission-MinorContract-Pmc32-03"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L1_2[7] = L8_2
  L1_2[8] = L9_2
  tPossibleVO = L1_2
  L1_2 = WifMissionFlow
  L1_2 = L1_2.HasKey
  L2_2 = "JetCon001"
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = table
    L1_2 = L1_2.insert
    L2_2 = tPossibleVO
    L3_2 = "Fiona-In-Mission-MinorContract-Pmc31-17"
    L1_2(L2_2, L3_2)
  end
  L1_2 = MrxUtil
  L1_2 = L1_2.GetRandomTableElement
  L2_2 = tPossibleVO
  L1_2 = L1_2(L2_2)
  sVOLine = L1_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = sVOLine
  L2_2[1] = L3_2
  L1_2(L2_2)
end

FailureVO = L0_1

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
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = Player
    L0_3 = L0_3.GetSecondaryCharacter
    L0_3 = L0_3()
    if L0_3 then
      L0_3 = Human
      L0_3 = L0_3.Inventory
      L0_3 = L0_3.GetAllWeapons
      L1_3 = Player
      L1_3 = L1_3.GetSecondaryCharacter
      L1_3, L2_3, L3_3, L4_3, L5_3, L6_3 = L1_3()
      L0_3 = L0_3(L1_3, L2_3, L3_3, L4_3, L5_3, L6_3)
      tLocalP2Weapons = L0_3
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._CreateEvent
      L2_3 = Event
      L2_3 = L2_3.Boundary
      L3_3 = {}
      L4_3 = Player
      L4_3 = L4_3.GetSecondaryCharacter
      L4_3 = L4_3()
      L5_3 = Pg
      L5_3 = L5_3.GetGuidByName
      L6_3 = "PMCCon034OutOfBounds"
      L5_3 = L5_3(L6_3)
      L6_3 = "exit"
      L3_3[1] = L4_3
      L3_3[2] = L5_3
      L3_3[3] = L6_3
      
      function L4_3()
        local L0_4, L1_4, L2_4, L3_4, L4_4, L5_4, L6_4
        L0_4 = A0_2
        L1_4 = L0_4
        L0_4 = L0_4._SetCancelMessage
        L2_4 = "[PmcCon034.Terms.CancelOOB]"
        L0_4(L1_4, L2_4)
        L0_4 = MrxVoSequence
        L0_4 = L0_4.Start
        L1_4 = {}
        L2_4 = "Fiona-In-Mission-MinorContract-Pmc31-10"
        L3_4 = {}
        L4_4 = A0_2
        L4_4 = L4_4.Cancel
        L5_4 = {}
        L6_4 = A0_2
        L5_4[1] = L6_4
        L3_4[1] = L4_4
        L3_4[2] = L5_4
        L1_4[1] = L2_4
        L1_4[2] = L3_4
        L0_4(L1_4)
      end
      
      L0_3(L1_3, L2_3, L3_3, L4_3)
    end
  end
  
  L4_2(L5_2, L6_2, L7_2, L8_2)
end

OnPlayerJoined = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = _evClientJoinedPMC034
  L1_2(L2_2)
  L1_2 = Player
  L1_2 = L1_2.GetSecondaryCharacter
  L1_2 = L1_2()
  uCharacter = L1_2
  L1_2 = uCharacter
  if L1_2 then
    L1_2 = ipairs
    L2_2 = tLocalP2Weapons
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    end
  end
  L1_2 = Hud
  L1_2 = L1_2.SupportMenu
  L2_2 = L1_2
  L1_2 = L1_2.SetShootingGalleryMode
  L3_2 = {}
  L3_2.bEnable = false
  L1_2(L2_2, L3_2)
  L1_2 = TruckSpawn
  if L1_2 then
    L1_2 = Object
    L1_2 = L1_2.Remove
    L2_2 = TruckSpawn
    L1_2(L2_2)
  end
  L1_2 = StatueSpawn
  if L1_2 then
    L1_2 = Object
    L1_2 = L1_2.Remove
    L2_2 = StatueSpawn
    L1_2(L2_2)
  end
  L1_2 = uCargo
  if L1_2 then
    L1_2 = Object
    L1_2 = L1_2.Remove
    L2_2 = uCargo
    L1_2(L2_2)
  end
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "UH1 Transport (PMC) 0x00126e26"
  L1_2 = L1_2(L2_2)
  uHelo = L1_2
  L1_2 = uHelo
  if L1_2 then
    L1_2 = Object
    L1_2 = L1_2.SetPosition
    L2_2 = uHelo
    L3_2 = 2632
    L4_2 = 155
    L5_2 = -1000
    L6_2 = false
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  end
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
  L1_2 = A0_2.CourseTimer
  if L1_2 then
    L1_2 = A0_2.CourseTimer
    L2_2 = L1_2
    L1_2 = L1_2.Stop
    L1_2(L2_2)
  end
  L1_2 = oStatueTimer
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = oStatueTimer
    L1_2(L2_2)
  end
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = ipairs
  L2_2 = tLayersToAdd
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = MrxLayerManager
    L6_2 = L6_2.MarkForRemoval
    L7_2 = L5_2
    L6_2(L7_2)
  end
end

Cleanup = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2 = L1_2()
  uCharacter = L1_2
  L1_2 = Object
  L1_2 = L1_2.SetInfiniteAmmo
  L2_2 = uCharacter
  L3_2 = false
  L1_2(L2_2, L3_2)
  L1_2 = uMusicStartEvent
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uMusicStartEvent
    L1_2(L2_2)
  end
  L1_2 = Net
  L1_2 = L1_2.SendCustomEvent
  L2_2 = "PmcCon034"
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
  L1_2 = Object
  L1_2 = L1_2.SetInfiniteAmmo
  L2_2 = uCharacter
  L3_2 = false
  L1_2(L2_2, L3_2)
  L1_2 = Net
  L1_2 = L1_2.SendCustomEvent
  L2_2 = "PmcCon034"
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
