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
L0_1 = nil
uWeapon = L0_1
L0_1 = 0
WeaponClipAmmo = L0_1
L0_1 = 0
WeaponReserveAmmo = L0_1
L0_1 = 1
VOTimer = L0_1
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
        L2_2 = Event
        L2_2 = L2_2.Delete
        L3_2 = _evMoveWeapons
        L2_2(L3_2)
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
  L3_2 = "Vz_State_PmcCon032"
  L2_2[1] = L3_2
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
      L1_3 = "PmcCon032"
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
  L1_2 = 0
  nTimeLimit = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.GetNumCompletions
  L1_2 = L1_2(L2_2)
  if L1_2 == 0 then
    L2_2 = 150
    nTimeLimit = L2_2
    L2_2 = "[PmcCon032.Terms.TimeToBeat3]"
    sTimeToBeat = L2_2
  elseif L1_2 == 1 then
    L2_2 = 80
    nTimeLimit = L2_2
    L2_2 = "[PmcCon032.Terms.TimeToBeat2]"
    sTimeToBeat = L2_2
  elseif 2 <= L1_2 then
    L2_2 = 60
    nTimeLimit = L2_2
    L2_2 = "[PmcCon032.Terms.TimeToBeat1]"
    sTimeToBeat = L2_2
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
    L4_3 = L4_3.GetAllCharacters
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
      L2_4 = "[PmcCon031.OtherThing]"
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
  L2_2 = Object
  L2_2 = L2_2.GetHealth
  L3_2 = Player
  L3_2 = L3_2.GetLocalCharacter
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L3_2()
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  nHealth = L2_2
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectHealth
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetLocalCharacter
  L6_2 = L6_2()
  L7_2 = "<"
  L8_2 = nHealth
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L6_2 = MrxVoSequence
  L6_2 = L6_2.Start
  L7_2 = {}
  L8_2 = {}
  L9_2 = "Fiona-In-Mission-MinorContract-Pmc31-19"
  L8_2[1] = L9_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L2_2 = Hud
  L2_2 = L2_2.ObjectiveTray
  L3_2 = L2_2
  L2_2 = L2_2.SetSlotToText
  L4_2 = {}
  L4_2.nSlot = 1
  L5_2 = "[PmcCon032.Terms.TimeToBeatText] "
  L6_2 = sTimeToBeat
  L5_2 = L5_2 .. L6_2
  L4_2.sText = L5_2
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
  L7_2 = "PmcCon032"
  L8_2 = NETEVENT_SETSTARTUPWEAPONS
  L9_2 = {}
  L10_2 = true
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  _evClientJoinedPMC032 = L2_2
  L2_2 = Net
  L2_2 = L2_2.SendCustomEvent
  L3_2 = "PmcCon032"
  L4_2 = NETEVENT_SETSTARTUPWEAPONS
  L5_2 = {}
  L6_2 = true
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L2_2 = Player
  L2_2 = L2_2.GetSecondaryCharacter
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = Human
    L2_2 = L2_2.Inventory
    L2_2 = L2_2.GetAllWeapons
    L3_2 = Player
    L3_2 = L3_2.GetSecondaryCharacter
    L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L3_2()
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
    tLocalP2Weapons = L2_2
  end
  L3_2 = A0_2
  L2_2 = A0_2._MoveToPoint1
  L4_2 = nTimeLimit
  L2_2(L3_2, L4_2)
end

Activated = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = MrxTimer
  L3_2 = L2_2
  L2_2 = L2_2.Create
  L4_2 = {}
  L4_2.nStartTime = 0
  L4_2.nStopTime = 600
  L4_2.nStep = 0.1
  L4_2.nWarning = A1_2
  L4_2.iTray = 2
  L4_2.bUseTenths = true
  L5_2 = {}
  L6_2 = {}
  L7_2 = A0_2._SetCancelMessage
  L8_2 = {}
  L9_2 = A0_2
  L10_2 = "[PmcCon032.Terms.CancelTime]"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = {}
  L8_2 = A0_2.Cancel
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2.tDoneCallbacks = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  A0_2.CourseTimer = L2_2
  L2_2 = A0_2.CourseTimer
  L3_2 = L2_2
  L2_2 = L2_2.Start
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2.GetNumCompletions
  L2_2 = L2_2(L3_2)
  if L2_2 <= 1 then
    L2_2 = MrxVoSequence
    L2_2 = L2_2.Start
    L3_2 = {}
    L4_2 = "Fiona-In-Mission-MinorContract-Pmc32-06"
    L3_2[1] = L4_2
    L2_2(L3_2)
  end
  L2_2 = MrxShootingGallery
  L2_2 = L2_2.SetupBorder
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "PMCCon032_Easy_LR1"
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L3_2(L4_2)
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "MoveToPoint"
  L4_2.sDspShortDesc = "[PmcCon032.Objectives.MoveToSandbags]"
  L4_2.sModuleName = "MrxTaskObjectiveDeliver"
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L4_2.vTgtInclude = L5_2
  L4_2.bDspBlp = true
  L4_2.vDestLoc = "PmcCon032_Easy_Point1"
  L5_2 = PointDist
  L4_2.fDist = L5_2
  L4_2.bStop = false
  L4_2.bUseDestRing = true
  
  function L5_2()
    local L0_3, L1_3
    L0_3 = _DestroyObj1
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L4_2.fOnComplete = L5_2
  L2_2(L3_2, L4_2)
end

_MoveToPoint1 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = 0
  Counter = L1_2
  L1_2 = {}
  L2_2 = "PMCCon032_Easy_Target1"
  L3_2 = "PMCCon032_Easy_Target2"
  L4_2 = "PMCCon032_Easy_Target3"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  tTargets = L1_2
  L1_2 = true
  bAllDead = L1_2
  L1_2 = ipairs
  L2_2 = tTargets
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Object
    L6_2 = L6_2.IsAlive
    L7_2 = Pg
    L7_2 = L7_2.GetGuidByName
    L8_2 = L5_2
    L7_2, L8_2, L9_2, L10_2, L11_2 = L7_2(L8_2)
    L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
    if L6_2 then
      L6_2 = false
      bAllDead = L6_2
    end
  end
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Gren Kill1"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = tTargets
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[PmcCon031.Objectives.TakeOut]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = _MoveToPoint2
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  uCurObj = L1_2
  L1_2 = bAllDead
  if L1_2 == true then
    L1_2 = uCurObj
    L1_2 = L1_2.Complete
    L2_2 = uCurObj
    L1_2(L2_2)
  end
  L1_2 = ipairs
  L2_2 = tTargets
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L7_2 = A0_2
    L6_2 = A0_2._CreateEvent
    L8_2 = Event
    L8_2 = L8_2.ObjectDeath
    L9_2 = {}
    L10_2 = Pg
    L10_2 = L10_2.GetGuidByName
    L11_2 = L5_2
    L10_2, L11_2 = L10_2(L11_2)
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    
    function L10_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
      L0_3 = Counter
      L0_3 = L0_3 + 1
      Counter = L0_3
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._CreateEvent
      L2_3 = Event
      L2_3 = L2_3.TimerRelative
      L3_3 = {}
      L4_3 = VOTimer
      L3_3[1] = L4_3
      
      function L4_3()
        local L0_4, L1_4
        L0_4 = Counter
        L0_4 = L0_4 - 1
        Counter = L0_4
      end
      
      L0_3(L1_3, L2_3, L3_3, L4_3)
      L0_3 = Counter
      if L0_3 == 2 then
        L0_3 = 0
        Counter = L0_3
        L0_3 = {}
        L1_3 = "Fiona.Cam.02"
        L2_3 = "Fiona.xfio168"
        L3_3 = "Fiona-In-Mission-Contract-Chi02-33"
        L4_3 = "Fiona-None-Freeplay-None-14"
        L5_3 = "Fiona.xfio164"
        L6_3 = "Fiona.va3fio12"
        L0_3[1] = L1_3
        L0_3[2] = L2_3
        L0_3[3] = L3_3
        L0_3[4] = L4_3
        L0_3[5] = L5_3
        L0_3[6] = L6_3
        tVoTable = L0_3
        L0_3 = MrxVoSequence
        L0_3 = L0_3.Start
        L1_3 = {}
        L2_3 = MrxUtil
        L2_3 = L2_3.GetRandomTableElement
        L3_3 = tVoTable
        L2_3, L3_3, L4_3, L5_3, L6_3 = L2_3(L3_3)
        L1_3[1] = L2_3
        L1_3[2] = L3_3
        L1_3[3] = L4_3
        L1_3[4] = L5_3
        L1_3[5] = L6_3
        L0_3(L1_3)
      end
    end
    
    L6_2(L7_2, L8_2, L9_2, L10_2)
  end
end

_DestroyObj1 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = MrxShootingGallery
  L1_2 = L1_2.SetupBorder
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "PMCCon032_Easy_LR2"
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L1_2(L2_2, L3_2, L4_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "MoveToPoint"
  L3_2.sDspShortDesc = "[PmcCon032.Objectives.MoveToSandbags]"
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2 = Player
  L4_2 = L4_2.GetAnyCharacter
  L4_2 = L4_2()
  L3_2.vTgtInclude = L4_2
  L3_2.bDspBlp = true
  L3_2.vDestLoc = "PmcCon032_Easy_Point2"
  L4_2 = PointDist
  L3_2.fDist = L4_2
  L3_2.bStop = false
  L3_2.bUseDestRing = true
  
  function L4_2()
    local L0_3, L1_3
    L0_3 = _DestroyObj2
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L3_2.fOnComplete = L4_2
  L1_2(L2_2, L3_2)
end

_MoveToPoint2 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = {}
  L2_2 = "PMCCon032_Easy_Target4"
  L3_2 = "PMCCon032_Easy_Target5"
  L4_2 = "PMCCon032_Easy_Target6"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  tTargets = L1_2
  L1_2 = true
  bAllDead = L1_2
  L1_2 = 0
  Counter = L1_2
  L1_2 = ipairs
  L2_2 = tTargets
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Object
    L6_2 = L6_2.IsAlive
    L7_2 = Pg
    L7_2 = L7_2.GetGuidByName
    L8_2 = L5_2
    L7_2, L8_2, L9_2, L10_2, L11_2 = L7_2(L8_2)
    L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
    if L6_2 then
      L6_2 = false
      bAllDead = L6_2
    end
  end
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Gren Kill2"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = tTargets
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[PmcCon032.Objectives.DestroyCars]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = _MoveToPoint3
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  uCurObj = L1_2
  L1_2 = bAllDead
  if L1_2 == true then
    L1_2 = uCurObj
    L1_2 = L1_2.Complete
    L2_2 = uCurObj
    L1_2(L2_2)
  end
  L1_2 = ipairs
  L2_2 = tTargets
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L7_2 = A0_2
    L6_2 = A0_2._CreateEvent
    L8_2 = Event
    L8_2 = L8_2.ObjectDeath
    L9_2 = {}
    L10_2 = Pg
    L10_2 = L10_2.GetGuidByName
    L11_2 = L5_2
    L10_2, L11_2 = L10_2(L11_2)
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    
    function L10_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
      L0_3 = Counter
      L0_3 = L0_3 + 1
      Counter = L0_3
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._CreateEvent
      L2_3 = Event
      L2_3 = L2_3.TimerRelative
      L3_3 = {}
      L4_3 = VOTimer
      L3_3[1] = L4_3
      
      function L4_3()
        local L0_4, L1_4
        L0_4 = Counter
        L0_4 = L0_4 - 1
        Counter = L0_4
      end
      
      L0_3(L1_3, L2_3, L3_3, L4_3)
      L0_3 = Counter
      if L0_3 == 2 then
        L0_3 = 0
        Counter = L0_3
        L0_3 = {}
        L1_3 = "Fiona.Cam.02"
        L2_3 = "Fiona.xfio168"
        L3_3 = "Fiona-In-Mission-Contract-Chi02-33"
        L4_3 = "Fiona-None-Freeplay-None-14"
        L5_3 = "Fiona.xfio164"
        L6_3 = "Fiona.va3fio12"
        L0_3[1] = L1_3
        L0_3[2] = L2_3
        L0_3[3] = L3_3
        L0_3[4] = L4_3
        L0_3[5] = L5_3
        L0_3[6] = L6_3
        tVoTable = L0_3
        L0_3 = MrxVoSequence
        L0_3 = L0_3.Start
        L1_3 = {}
        L2_3 = MrxUtil
        L2_3 = L2_3.GetRandomTableElement
        L3_3 = tVoTable
        L2_3, L3_3, L4_3, L5_3, L6_3 = L2_3(L3_3)
        L1_3[1] = L2_3
        L1_3[2] = L3_3
        L1_3[3] = L4_3
        L1_3[4] = L5_3
        L1_3[5] = L6_3
        L0_3(L1_3)
      end
    end
    
    L6_2(L7_2, L8_2, L9_2, L10_2)
  end
end

_DestroyObj2 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = MrxShootingGallery
  L1_2 = L1_2.SetupBorder
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "PMCCon032_Easy_LR3"
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L1_2(L2_2, L3_2, L4_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "MoveToPoint"
  L3_2.sDspShortDesc = "[PmcCon032.Objectives.MoveToSandbags]"
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2 = Player
  L4_2 = L4_2.GetAnyCharacter
  L4_2 = L4_2()
  L3_2.vTgtInclude = L4_2
  L3_2.bDspBlp = true
  L3_2.vDestLoc = "PmcCon032_Easy_Point3"
  L4_2 = PointDist
  L3_2.fDist = L4_2
  L3_2.bStop = false
  L3_2.bUseDestRing = true
  
  function L4_2()
    local L0_3, L1_3
    L0_3 = _DestroyObj3
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L3_2.fOnComplete = L4_2
  L1_2(L2_2, L3_2)
end

_MoveToPoint3 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = {}
  L2_2 = "PMCCon032_Easy_Target7"
  L3_2 = "PMCCon032_Easy_Target8"
  L4_2 = "PMCCon032_Easy_Target9"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  tTargets = L1_2
  L1_2 = true
  bAllDead = L1_2
  L1_2 = 0
  Counter = L1_2
  L1_2 = ipairs
  L2_2 = tTargets
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Object
    L6_2 = L6_2.IsAlive
    L7_2 = Pg
    L7_2 = L7_2.GetGuidByName
    L8_2 = L5_2
    L7_2, L8_2, L9_2, L10_2, L11_2 = L7_2(L8_2)
    L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
    if L6_2 then
      L6_2 = false
      bAllDead = L6_2
    end
  end
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Gren Kill3"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = tTargets
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[PmcCon031.Objectives.TakeOut]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = _MoveToPoint4
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  uCurObj = L1_2
  L1_2 = bAllDead
  if L1_2 == true then
    L1_2 = uCurObj
    L1_2 = L1_2.Complete
    L2_2 = uCurObj
    L1_2(L2_2)
  end
  L1_2 = ipairs
  L2_2 = tTargets
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L7_2 = A0_2
    L6_2 = A0_2._CreateEvent
    L8_2 = Event
    L8_2 = L8_2.ObjectDeath
    L9_2 = {}
    L10_2 = Pg
    L10_2 = L10_2.GetGuidByName
    L11_2 = L5_2
    L10_2, L11_2 = L10_2(L11_2)
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    
    function L10_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
      L0_3 = Counter
      L0_3 = L0_3 + 1
      Counter = L0_3
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._CreateEvent
      L2_3 = Event
      L2_3 = L2_3.TimerRelative
      L3_3 = {}
      L4_3 = VOTimer
      L3_3[1] = L4_3
      
      function L4_3()
        local L0_4, L1_4
        L0_4 = Counter
        L0_4 = L0_4 - 1
        Counter = L0_4
      end
      
      L0_3(L1_3, L2_3, L3_3, L4_3)
      L0_3 = Counter
      if L0_3 == 2 then
        L0_3 = 0
        Counter = L0_3
        L0_3 = {}
        L1_3 = "Fiona.Cam.02"
        L2_3 = "Fiona.xfio168"
        L3_3 = "Fiona-In-Mission-Contract-Chi02-33"
        L4_3 = "Fiona-None-Freeplay-None-14"
        L5_3 = "Fiona.xfio164"
        L6_3 = "Fiona.va3fio12"
        L0_3[1] = L1_3
        L0_3[2] = L2_3
        L0_3[3] = L3_3
        L0_3[4] = L4_3
        L0_3[5] = L5_3
        L0_3[6] = L6_3
        tVoTable = L0_3
        L0_3 = MrxVoSequence
        L0_3 = L0_3.Start
        L1_3 = {}
        L2_3 = MrxUtil
        L2_3 = L2_3.GetRandomTableElement
        L3_3 = tVoTable
        L2_3, L3_3, L4_3, L5_3, L6_3 = L2_3(L3_3)
        L1_3[1] = L2_3
        L1_3[2] = L3_3
        L1_3[3] = L4_3
        L1_3[4] = L5_3
        L1_3[5] = L6_3
        L0_3(L1_3)
      end
    end
    
    L6_2(L7_2, L8_2, L9_2, L10_2)
  end
end

_DestroyObj3 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = MrxShootingGallery
  L1_2 = L1_2.SetupBorder
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "PMCCon032_Easy_LR4"
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L1_2(L2_2, L3_2, L4_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "MoveToPoint"
  L3_2.sDspShortDesc = "[PmcCon032.Objectives.MoveToSandbags]"
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2 = Player
  L4_2 = L4_2.GetAnyCharacter
  L4_2 = L4_2()
  L3_2.vTgtInclude = L4_2
  L3_2.bDspBlp = true
  L3_2.vDestLoc = "PmcCon032_Easy_Point4"
  L4_2 = PointDist
  L3_2.fDist = L4_2
  L3_2.bStop = false
  L3_2.bUseDestRing = true
  
  function L4_2()
    local L0_3, L1_3
    L0_3 = _DestroyObj4
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L3_2.fOnComplete = L4_2
  L1_2(L2_2, L3_2)
end

_MoveToPoint4 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2
  L1_2 = {}
  L2_2 = "PMC011_SniperStatue18 0x0012d2d2"
  L3_2 = "PMC011_SniperStatue18 0x0012d2d3"
  L4_2 = "PMC011_SniperStatue18 0x0012d2d4"
  L5_2 = "PMC011_SniperStatue18 0x0012d2d5"
  L6_2 = "PMC011_SniperStatue18 0x0012d2d6"
  L7_2 = "PMC011_SniperStatue18 0x0012d2d7"
  L8_2 = "PMC011_SniperStatue18 0x0012d2d8"
  L9_2 = "PMC011_SniperStatue18 0x0012d2d9"
  L10_2 = "PMC011_SniperStatue18 0x0012d2da"
  L11_2 = "PMC011_SniperStatue18 0x0012d2db"
  L12_2 = "PMC011_SniperStatue18 0x0012d2dc"
  L13_2 = "PMC011_SniperStatue18 0x0012d2dd"
  L14_2 = "PMC011_SniperStatue18 0x0012d2de"
  L15_2 = "PMC011_SniperStatue18 0x0012d2df"
  L16_2 = "PMC011_SniperStatue18 0x0012d2e0"
  L17_2 = "PMC011_SniperStatue18 0x0012d2e1"
  L18_2 = "PMC011_SniperStatue18 0x0012d2e2"
  L19_2 = "PMC011_SniperStatue18 0x0012d2e3"
  L20_2 = "PMC011_SniperStatue18 0x0012d2e4"
  L21_2 = "PMC011_SniperStatue18 0x0012d2e5"
  L22_2 = "PMC011_SniperStatue18 0x0012d2e6"
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
  tTargets = L1_2
  L1_2 = true
  bAllDead = L1_2
  L1_2 = 0
  Counter = L1_2
  L1_2 = ipairs
  L2_2 = tTargets
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Object
    L6_2 = L6_2.IsAlive
    L7_2 = Pg
    L7_2 = L7_2.GetGuidByName
    L8_2 = L5_2
    L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2 = L7_2(L8_2)
    L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2)
    if L6_2 then
      L6_2 = false
      bAllDead = L6_2
    end
  end
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Gren Kill4"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = tTargets
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[PmcCon031.Objectives.TakeOut]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = _MoveToPoint5
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  uCurObj = L1_2
  L1_2 = bAllDead
  if L1_2 == true then
    L1_2 = uCurObj
    L1_2 = L1_2.Complete
    L2_2 = uCurObj
    L1_2(L2_2)
  end
  L1_2 = ipairs
  L2_2 = tTargets
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L7_2 = A0_2
    L6_2 = A0_2._CreateEvent
    L8_2 = Event
    L8_2 = L8_2.ObjectDeath
    L9_2 = {}
    L10_2 = Pg
    L10_2 = L10_2.GetGuidByName
    L11_2 = L5_2
    L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2 = L10_2(L11_2)
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L9_2[4] = L13_2
    L9_2[5] = L14_2
    L9_2[6] = L15_2
    L9_2[7] = L16_2
    L9_2[8] = L17_2
    L9_2[9] = L18_2
    L9_2[10] = L19_2
    L9_2[11] = L20_2
    L9_2[12] = L21_2
    L9_2[13] = L22_2
    
    function L10_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
      L0_3 = Counter
      L0_3 = L0_3 + 1
      Counter = L0_3
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._CreateEvent
      L2_3 = Event
      L2_3 = L2_3.TimerRelative
      L3_3 = {}
      L4_3 = VOTimer
      L3_3[1] = L4_3
      
      function L4_3()
        local L0_4, L1_4
        L0_4 = Counter
        L0_4 = L0_4 - 1
        Counter = L0_4
      end
      
      L0_3(L1_3, L2_3, L3_3, L4_3)
      L0_3 = Counter
      if L0_3 == 10 then
        L0_3 = 0
        Counter = L0_3
        L0_3 = {}
        L1_3 = "Fiona.Cam.02"
        L2_3 = "Fiona.xfio168"
        L3_3 = "Fiona-In-Mission-Contract-Chi02-33"
        L4_3 = "Fiona-None-Freeplay-None-14"
        L5_3 = "Fiona.xfio164"
        L6_3 = "Fiona.va3fio12"
        L0_3[1] = L1_3
        L0_3[2] = L2_3
        L0_3[3] = L3_3
        L0_3[4] = L4_3
        L0_3[5] = L5_3
        L0_3[6] = L6_3
        tVoTable = L0_3
        L0_3 = MrxVoSequence
        L0_3 = L0_3.Start
        L1_3 = {}
        L2_3 = MrxUtil
        L2_3 = L2_3.GetRandomTableElement
        L3_3 = tVoTable
        L2_3, L3_3, L4_3, L5_3, L6_3 = L2_3(L3_3)
        L1_3[1] = L2_3
        L1_3[2] = L3_3
        L1_3[3] = L4_3
        L1_3[4] = L5_3
        L1_3[5] = L6_3
        L0_3(L1_3)
      end
    end
    
    L6_2(L7_2, L8_2, L9_2, L10_2)
  end
end

_DestroyObj4 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = MrxShootingGallery
  L1_2 = L1_2.SetupBorder
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "PMCCon032_Easy_LR5"
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L1_2(L2_2, L3_2, L4_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "MoveToPoint"
  L3_2.sDspShortDesc = "[PmcCon032.Objectives.MoveToTower]"
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2 = Player
  L4_2 = L4_2.GetAnyCharacter
  L4_2 = L4_2()
  L3_2.vTgtInclude = L4_2
  L3_2.bDspBlp = true
  L3_2.vDestLoc = "PmcCon032_Easy_Point5"
  L4_2 = PointDist
  L3_2.fDist = L4_2
  L3_2.bStop = false
  L3_2.bUseDestRing = true
  
  function L4_2()
    local L0_3, L1_3
    L0_3 = _DestroyObj5
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L3_2.fOnComplete = L4_2
  L1_2(L2_2, L3_2)
end

_MoveToPoint5 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = uCountdownHero
  L1_2(L2_2)
  L1_2 = {}
  L2_2 = "PMCCon032_Easy_Target10"
  L3_2 = "PMCCon032_Easy_Target11"
  L4_2 = "PMCCon032_Easy_Target12"
  L5_2 = "PMCCon032_Easy_Target13"
  L6_2 = "PMCCon032_Easy_Target14"
  L7_2 = "PMCCon032_Easy_Target15"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  tTargets = L1_2
  L1_2 = true
  bAllDead = L1_2
  L1_2 = ipairs
  L2_2 = tTargets
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Object
    L6_2 = L6_2.IsAlive
    L7_2 = Pg
    L7_2 = L7_2.GetGuidByName
    L8_2 = L5_2
    L7_2, L8_2 = L7_2(L8_2)
    L6_2 = L6_2(L7_2, L8_2)
    if L6_2 then
      L6_2 = false
      bAllDead = L6_2
    end
  end
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Gren Kill5"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = tTargets
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[PmcCon031.Objectives.TakeOut]"
  
  function L4_2()
    local L0_3, L1_3, L2_3
    L0_3 = MrxTimer
    L0_3 = L0_3.GetTime
    L1_3 = A0_2
    L1_3 = L1_3.CourseTimer
    L0_3 = L0_3(L1_3)
    L1_3 = nTimeLimit
    if L0_3 < L1_3 then
      L0_3 = CompleteVO
      L1_3 = A0_2
      L0_3(L1_3)
    else
      L0_3 = A0_2
      L0_3 = L0_3.CourseTimer
      L1_3 = L0_3
      L0_3 = L0_3.Pause
      L0_3(L1_3)
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._SetCancelMessage
      L2_3 = "[PmcCon032.Terms.CancelTime]"
      L0_3(L1_3, L2_3)
      L0_3 = A0_2
      L0_3 = L0_3.Cancel
      L1_3 = A0_2
      L0_3(L1_3)
    end
  end
  
  L3_2.fOnComplete = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  oFinalObj = L1_2
  L1_2 = bAllDead
  if L1_2 == true then
    L1_2 = oFinalObj
    L1_2 = L1_2.Complete
    L2_2 = oFinalObj
    L1_2(L2_2)
  end
end

_DestroyObj5 = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = MrxMusic
  L2_2 = L2_2.PlaySpecialMusic
  L3_2 = "mu_mission_pmccon032_01"
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
    L1_3 = "mu_mission_pmccon032_02"
    L0_3(L1_3)
  end
  
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  uMusicStartEvent = L2_2
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
    L1_3 = "mu_mission_pmccon032_01"
    L0_3(L1_3)
  end
  
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  uMusicEndEvent = L2_2
end

PlayMusic = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
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
  end
  L1_2 = _MoveWeapons
  L2_2 = uCharacter
  L3_2 = tP1Weapons
  L1_2(L2_2, L3_2)
  L1_2 = Event
  L1_2 = L1_2.CreatePersistent
  L2_2 = Event
  L2_2 = L2_2.ObjectProximity
  L3_2 = {}
  L4_2 = tP1Weapons
  L4_2 = L4_2[1]
  L5_2 = uCharacter
  L6_2 = ">"
  L7_2 = 50
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L4_2 = _MoveWeapons
  L5_2 = {}
  L6_2 = uCharacter
  L7_2 = tP1Weapons
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  _evMoveWeapons = L1_2
  L1_2 = Human
  L1_2 = L1_2.Inventory
  L1_2 = L1_2.SetAllWeapons
  L2_2 = uCharacter
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "Grenade Launcher"
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L3_2(L4_2)
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  L1_2 = Object
  L1_2 = L1_2.SetInfiniteAmmo
  L2_2 = uCharacter
  L3_2 = true
  L1_2(L2_2, L3_2)
end

_SetupP1Weapons = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
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
  end
  L0_2 = _MoveWeapons
  L1_2 = uCharacter
  L2_2 = tP2Weapons
  L0_2(L1_2, L2_2)
  L0_2 = Event
  L0_2 = L0_2.CreatePersistent
  L1_2 = Event
  L1_2 = L1_2.ObjectProximity
  L2_2 = {}
  L3_2 = tP2Weapons
  L3_2 = L3_2[1]
  L4_2 = uCharacter
  L5_2 = ">"
  L6_2 = 50
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L3_2 = _MoveWeapons
  L4_2 = {}
  L5_2 = uCharacter
  L6_2 = tP2Weapons
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L0_2 = L0_2(L1_2, L2_2, L3_2, L4_2)
  _evMoveWeapons = L0_2
  L0_2 = Human
  L0_2 = L0_2.Inventory
  L0_2 = L0_2.SetAllWeapons
  L1_2 = uCharacter
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "Grenade Launcher"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2 = L2_2(L3_2)
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L0_2 = Object
  L0_2 = L0_2.SetInfiniteAmmo
  L1_2 = uCharacter
  L2_2 = true
  L0_2(L1_2, L2_2)
end

SetP2Weapons = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = ipairs
  L3_2 = A1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = Object
    L7_2 = L7_2.GetPosition
    L8_2 = A0_2
    L7_2, L8_2, L9_2 = L7_2(L8_2)
    z = L9_2
    y = L8_2
    x = L7_2
    L7_2 = Object
    L7_2 = L7_2.DisablePhysics
    L8_2 = L6_2
    L7_2(L8_2)
    L7_2 = Object
    L7_2 = L7_2.SetPosition
    L8_2 = L6_2
    L9_2 = x
    L10_2 = y
    L10_2 = L10_2 - 5
    L11_2 = z
    L7_2(L8_2, L9_2, L10_2, L11_2)
  end
end

_MoveWeapons = L0_1

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
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = MrxShootingGallery
  L1_2 = L1_2.SetupBorder
  L2_2 = nil
  L1_2(L2_2)
  L1_2 = A0_2.CourseTimer
  L2_2 = L1_2
  L1_2 = L1_2.Pause
  L1_2(L2_2)
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
  L1_2 = {}
  L2_2 = "Fiona-In-Mission-MinorContract-Pmc31-02"
  L3_2 = "Fiona-In-Mission-MinorContract-Pmc31-20"
  L4_2 = "Fiona-In-Mission-MinorContract-Pmc31-21"
  L5_2 = "Fiona-In-Mission-MinorContract-Pmc32-01"
  L6_2 = "Fiona-In-Mission-MinorContract-Pmc32-02"
  L7_2 = "Fiona-In-Mission-MinorContract-Pmc34-01"
  L8_2 = "Fiona-In-Mission-MinorContract-Pmc31-33"
  L9_2 = "Fiona-In-Mission-MinorContract-Pmc31-35"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L1_2[7] = L8_2
  L1_2[8] = L9_2
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
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = {}
  L2_2 = "Fiona-In-Mission-MinorContract-Pmc31-04"
  L3_2 = "Fiona-In-Mission-MinorContract-Pmc31-11"
  L4_2 = "Fiona-In-Mission-MinorContract-Pmc31-14"
  L5_2 = "Fiona-In-Mission-MinorContract-Pmc31-15"
  L6_2 = "Fiona-In-Mission-MinorContract-Pmc31-16"
  L7_2 = "Fiona-In-Mission-MinorContract-Pmc31-22"
  L8_2 = "Fiona-In-Mission-MinorContract-Pmc31-23"
  L9_2 = "Fiona-In-Mission-MinorContract-Pmc32-03"
  L10_2 = "Fiona-In-Mission-MinorContract-Pmc34-02"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L1_2[7] = L8_2
  L1_2[8] = L9_2
  L1_2[9] = L10_2
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
  L2_2 = "PmcCon032"
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
  L2_2 = "PmcCon032"
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
        L2_4 = "[PmcCon031.OtherThing]"
        L0_4(L1_4, L2_4)
        L0_4 = A0_2
        L1_4 = L0_4
        L0_4 = L0_4.Cancel
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
  L2_2 = _evClientJoinedPMC032
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = _evMoveWeapons
  L1_2(L2_2)
  L1_2 = MrxShootingGallery
  L1_2 = L1_2.SetupBorder
  L2_2 = nil
  L1_2(L2_2)
  L1_2 = Hud
  L1_2 = L1_2.SupportMenu
  L2_2 = L1_2
  L1_2 = L1_2.SetShootingGalleryMode
  L3_2 = {}
  L3_2.bEnable = false
  L1_2(L2_2, L3_2)
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
  L1_2 = MrxLayerManager
  L1_2 = L1_2.MarkForAddition
  L2_2 = "vz_state_pmc"
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
  L1_2 = A0_2.CourseTimer
  if L1_2 then
    L1_2 = A0_2.CourseTimer
    L2_2 = L1_2
    L1_2 = L1_2.Stop
    L1_2(L2_2)
  end
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
