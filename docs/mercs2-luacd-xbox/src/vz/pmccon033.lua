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
L0_1 = 2
NETEVENT_TARGETSDOWN = L0_1
L0_1 = 3
NETEVENT_TARGETSUP = L0_1
L0_1 = nil
tLocalP2Weapons = L0_1
L0_1 = nil
tP2Weapons = L0_1
L0_1 = nil
evClientSetup = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
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
    else
      L2_2 = NETEVENT_TARGETSDOWN
      if A0_2 == L2_2 then
        L2_2 = {}
        L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3ae"
        L4_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3af"
        L5_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3b0"
        L6_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3b1"
        L2_2[1] = L3_2
        L2_2[2] = L4_2
        L2_2[3] = L5_2
        L2_2[4] = L6_2
        tTargetsToPop = L2_2
        L2_2 = ipairs
        L3_2 = tTargetsToPop
        L2_2, L3_2, L4_2 = L2_2(L3_2)
        for L5_2, L6_2 in L2_2, L3_2, L4_2 do
          L7_2 = Event
          L7_2 = L7_2.Create
          L8_2 = Event
          L8_2 = L8_2.ObjectHibernation
          L9_2 = {}
          L10_2 = Pg
          L10_2 = L10_2.GetGuidByName
          L11_2 = L6_2
          L10_2 = L10_2(L11_2)
          L11_2 = "awake"
          L9_2[1] = L10_2
          L9_2[2] = L11_2
          L10_2 = Vehicle
          L10_2 = L10_2.OpenDoor
          L11_2 = {}
          L12_2 = Pg
          L12_2 = L12_2.GetGuidByName
          L13_2 = L6_2
          L12_2 = L12_2(L13_2)
          L13_2 = "pivot"
          L11_2[1] = L12_2
          L11_2[2] = L13_2
          L7_2(L8_2, L9_2, L10_2, L11_2)
        end
      else
        L2_2 = NETEVENT_TARGETSUP
        if A0_2 == L2_2 then
          L2_2 = {}
          L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3ae"
          L4_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3af"
          L5_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3b0"
          L6_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3b1"
          L2_2[1] = L3_2
          L2_2[2] = L4_2
          L2_2[3] = L5_2
          L2_2[4] = L6_2
          tTargetsToPop = L2_2
          L2_2 = ipairs
          L3_2 = tTargetsToPop
          L2_2, L3_2, L4_2 = L2_2(L3_2)
          for L5_2, L6_2 in L2_2, L3_2, L4_2 do
            L7_2 = Vehicle
            L7_2 = L7_2.CloseDoor
            L8_2 = Pg
            L8_2 = L8_2.GetGuidByName
            L9_2 = L6_2
            L8_2 = L8_2(L9_2)
            L9_2 = "pivot"
            L7_2(L8_2, L9_2)
          end
        end
      end
    end
  end
end

NetEventCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = {}
  L3_2 = "Vz_State_PmcCon033"
  L4_2 = "Vz_State_PmcCon033_PopDown"
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
  L2_2 = Net
  L2_2 = L2_2.SendCustomEvent
  L3_2 = "PmcCon033"
  L4_2 = NETEVENT_SETSTARTUPWEAPONS
  L5_2 = {}
  L6_2 = true
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L2_2 = Hud
  L2_2 = L2_2.SupportMenu
  L3_2 = L2_2
  L2_2 = L2_2.SetShootingGalleryMode
  L4_2 = {}
  L4_2.bEnable = true
  L2_2(L3_2, L4_2)
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetNumCompletions
  L1_2 = L1_2(L2_2)
  if L1_2 == 0 then
    L2_2 = 90
    nTimeLimit = L2_2
    L2_2 = "1:30"
    sTimeToBeat = L2_2
  elseif L1_2 == 1 then
    L2_2 = 60
    nTimeLimit = L2_2
    L2_2 = "1:00"
    sTimeToBeat = L2_2
  elseif 2 <= L1_2 then
    L2_2 = 45
    nTimeLimit = L2_2
    L2_2 = "0:45"
    sTimeToBeat = L2_2
  end
  L2_2 = MrxTimer
  L3_2 = L2_2
  L2_2 = L2_2.Create
  L4_2 = {}
  L4_2.nStartTime = 0
  L4_2.nStopTime = 600
  L4_2.nStep = 0.1
  L4_2.iTray = 2
  L5_2 = nTimeLimit
  L4_2.nWarning = L5_2
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
  L2_2 = Hud
  L2_2 = L2_2.ObjectiveTray
  L3_2 = L2_2
  L2_2 = L2_2.SetSlotToText
  L4_2 = {}
  L4_2.nSlot = 1
  L5_2 = "[PmcCon032.Terms.TimeToBeatText]"
  L6_2 = " "
  L7_2 = sTimeToBeat
  L5_2 = L5_2 .. L6_2 .. L7_2
  L4_2.sText = L5_2
  L2_2(L3_2, L4_2)
  L2_2 = _CountDownVOSetup
  L3_2 = A0_2
  L4_2 = nTimeLimit
  L2_2(L3_2, L4_2)
  L2_2 = PlayMusic
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
  L7_2 = "PmcCon033"
  L8_2 = NETEVENT_SETSTARTUPWEAPONS
  L9_2 = {}
  L10_2 = true
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  _evClientJoinedPMC033 = L2_2
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
  L2_2 = A0_2._SetupObjective
  L2_2(L3_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = {}
  L2_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3ae"
  L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3af"
  L4_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3b0"
  L5_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3b1"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  tTargetsToPop = L1_2
  L1_2 = ipairs
  L2_2 = tTargetsToPop
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L7_2 = A0_2
    L6_2 = A0_2._CreateEvent
    L8_2 = Event
    L8_2 = L8_2.ObjectHibernation
    L9_2 = {}
    L10_2 = Pg
    L10_2 = L10_2.GetGuidByName
    L11_2 = L5_2
    L10_2 = L10_2(L11_2)
    L11_2 = "awake"
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L10_2 = Vehicle
    L10_2 = L10_2.OpenDoor
    L11_2 = {}
    L12_2 = Pg
    L12_2 = L12_2.GetGuidByName
    L13_2 = L5_2
    L12_2 = L12_2(L13_2)
    L13_2 = "pivot"
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  end
  L1_2 = Net
  L1_2 = L1_2.SendCustomEvent
  L2_2 = "PmcCon033"
  L3_2 = NETEVENT_TARGETSDOWN
  L4_2 = {}
  L5_2 = true
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = 2.3
  PointDist = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.GetNumCompletions
  L1_2 = L1_2(L2_2)
  if L1_2 <= 1 then
    L1_2 = MrxVoSequence
    L1_2 = L1_2.Start
    L2_2 = {}
    L3_2 = "Fiona-In-Mission-MinorContract-Pmc33-03"
    L2_2[1] = L3_2
    L1_2(L2_2)
  end
  L1_2 = A0_2.CourseTimer
  L2_2 = L1_2
  L1_2 = L1_2.Start
  L1_2(L2_2)
  L1_2 = MrxShootingGallery
  L1_2 = L1_2.SetupBorder
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "PMCCon033_LR1"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L2_2(L3_2)
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
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
  L3_2.vDestLoc = "PistolRange 0x0012d20a"
  L4_2 = PointDist
  L3_2.fDist = L4_2
  L3_2.bStop = false
  L3_2.bUseDestRing = true
  
  function L4_2()
    local L0_3, L1_3
    L0_3 = _DestroyObj1
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L3_2.fOnComplete = L4_2
  L1_2(L2_2, L3_2)
end

_SetupObjective = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = 0
  Counter = L1_2
  L1_2 = {}
  L2_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d202"
  L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d201"
  L4_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d203"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  tTargets = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "RPG Range1"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = tTargets
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[PmcCon033.Objectives.Portaits]"
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
  DestroyObj1 = L1_2
  L1_2 = Object
  L1_2 = L1_2.IsAlive
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d202"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  if not L1_2 then
    L1_2 = Object
    L1_2 = L1_2.IsAlive
    L2_2 = Pg
    L2_2 = L2_2.GetGuidByName
    L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d201"
    L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L2_2(L3_2)
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
    if not L1_2 then
      L1_2 = Object
      L1_2 = L1_2.IsAlive
      L2_2 = Pg
      L2_2 = L2_2.GetGuidByName
      L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d203"
      L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L2_2(L3_2)
      L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
      if not L1_2 then
        L1_2 = DestroyObj1
        L2_2 = L1_2
        L1_2 = L1_2.Complete
        L1_2(L2_2)
      end
    end
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
      local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
      L0_3 = Counter
      L0_3 = L0_3 + 1
      Counter = L0_3
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._CreateEvent
      L2_3 = Event
      L2_3 = L2_3.TimerRelative
      L3_3 = {}
      L4_3 = 2
      L3_3[1] = L4_3
      
      function L4_3()
        local L0_4, L1_4
        L0_4 = Counter
        L0_4 = L0_4 - 1
        Counter = L0_4
      end
      
      L0_3(L1_3, L2_3, L3_3, L4_3)
      L0_3 = Counter
      if L0_3 == 3 then
        L0_3 = 0
        Counter = L0_3
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
  L3_2 = "PMCCon033_LR2"
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
  L3_2.vDestLoc = "PistolRange 0x0012d20c"
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
  L2_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d213"
  L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d214"
  L4_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d215"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  tTargets = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "RPG Range2"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = tTargets
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[PmcCon033.Objectives.Portaits]"
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
  DestroyObj2 = L1_2
  L1_2 = Object
  L1_2 = L1_2.IsAlive
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d213"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  if not L1_2 then
    L1_2 = Object
    L1_2 = L1_2.IsAlive
    L2_2 = Pg
    L2_2 = L2_2.GetGuidByName
    L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d214"
    L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L2_2(L3_2)
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
    if not L1_2 then
      L1_2 = Object
      L1_2 = L1_2.IsAlive
      L2_2 = Pg
      L2_2 = L2_2.GetGuidByName
      L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d215"
      L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L2_2(L3_2)
      L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
      if not L1_2 then
        L1_2 = DestroyObj2
        L2_2 = L1_2
        L1_2 = L1_2.Complete
        L1_2(L2_2)
      end
    end
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
      local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
      L0_3 = Counter
      L0_3 = L0_3 + 1
      Counter = L0_3
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._CreateEvent
      L2_3 = Event
      L2_3 = L2_3.TimerRelative
      L3_3 = {}
      L4_3 = 2
      L3_3[1] = L4_3
      
      function L4_3()
        local L0_4, L1_4
        L0_4 = Counter
        L0_4 = L0_4 - 1
        Counter = L0_4
      end
      
      L0_3(L1_3, L2_3, L3_3, L4_3)
      L0_3 = Counter
      if L0_3 == 3 then
        L0_3 = 0
        Counter = L0_3
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
  L3_2 = "PMCCon033_LR3"
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
  L3_2.vDestLoc = "PistolRange 0x0012d217"
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
  L2_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d218"
  L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d219"
  L4_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d21a"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  tTargets = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "RPG Range3"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = tTargets
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[PmcCon033.Objectives.Portaits]"
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
  DestroyObj3 = L1_2
  L1_2 = Object
  L1_2 = L1_2.IsAlive
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d218"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  if not L1_2 then
    L1_2 = Object
    L1_2 = L1_2.IsAlive
    L2_2 = Pg
    L2_2 = L2_2.GetGuidByName
    L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d219"
    L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L2_2(L3_2)
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
    if not L1_2 then
      L1_2 = Object
      L1_2 = L1_2.IsAlive
      L2_2 = Pg
      L2_2 = L2_2.GetGuidByName
      L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d21a"
      L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L2_2(L3_2)
      L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
      if not L1_2 then
        L1_2 = DestroyObj3
        L2_2 = L1_2
        L1_2 = L1_2.Complete
        L1_2(L2_2)
      end
    end
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
      local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
      L0_3 = Counter
      L0_3 = L0_3 + 1
      Counter = L0_3
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._CreateEvent
      L2_3 = Event
      L2_3 = L2_3.TimerRelative
      L3_3 = {}
      L4_3 = 2
      L3_3[1] = L4_3
      
      function L4_3()
        local L0_4, L1_4
        L0_4 = Counter
        L0_4 = L0_4 - 1
        Counter = L0_4
      end
      
      L0_3(L1_3, L2_3, L3_3, L4_3)
      L0_3 = Counter
      if L0_3 == 3 then
        L0_3 = 0
        Counter = L0_3
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
  L3_2 = "PMCCon033_LR4"
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
  L3_2.vDestLoc = "PistolRange 0x0012d226"
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
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = {}
  L2_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d22a"
  L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d229"
  L4_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d228"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  tTargets = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "RPG Range4"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = tTargets
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[PmcCon033.Objectives.Portaits]"
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
  DestroyObj4 = L1_2
  L1_2 = Object
  L1_2 = L1_2.IsAlive
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d22a"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  if not L1_2 then
    L1_2 = Object
    L1_2 = L1_2.IsAlive
    L2_2 = Pg
    L2_2 = L2_2.GetGuidByName
    L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d229"
    L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L2_2(L3_2)
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
    if not L1_2 then
      L1_2 = Object
      L1_2 = L1_2.IsAlive
      L2_2 = Pg
      L2_2 = L2_2.GetGuidByName
      L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d228"
      L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L2_2(L3_2)
      L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
      if not L1_2 then
        L1_2 = DestroyObj4
        L2_2 = L1_2
        L1_2 = L1_2.Complete
        L1_2(L2_2)
      end
    end
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
      local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
      L0_3 = Counter
      L0_3 = L0_3 + 1
      Counter = L0_3
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._CreateEvent
      L2_3 = Event
      L2_3 = L2_3.TimerRelative
      L3_3 = {}
      L4_3 = 4
      L3_3[1] = L4_3
      
      function L4_3()
        local L0_4, L1_4
        L0_4 = Counter
        L0_4 = L0_4 - 1
        Counter = L0_4
      end
      
      L0_3(L1_3, L2_3, L3_3, L4_3)
      L0_3 = Counter
      if L0_3 == 3 then
        L0_3 = 0
        Counter = L0_3
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
  L3_2 = "PMCCon033_LR5"
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
  L3_2.vDestLoc = "PistolRange 0x0012d3a7"
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
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "RPG Range5"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = {}
  L5_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3a8"
  L6_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3a9"
  L7_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3aa"
  L8_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3ab"
  L9_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3ac"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[PmcCon033.Objectives.Portaits]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = _DestroyObj6
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  DestroyObj5 = L1_2
  L1_2 = Object
  L1_2 = L1_2.IsAlive
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3a8"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  if not L1_2 then
    L1_2 = Object
    L1_2 = L1_2.IsAlive
    L2_2 = Pg
    L2_2 = L2_2.GetGuidByName
    L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3a9"
    L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L2_2(L3_2)
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
    if not L1_2 then
      L1_2 = Object
      L1_2 = L1_2.IsAlive
      L2_2 = Pg
      L2_2 = L2_2.GetGuidByName
      L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3aa"
      L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L2_2(L3_2)
      L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
      if not L1_2 then
        L1_2 = Object
        L1_2 = L1_2.IsAlive
        L2_2 = Pg
        L2_2 = L2_2.GetGuidByName
        L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3ab"
        L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L2_2(L3_2)
        L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
        if not L1_2 then
          L1_2 = Object
          L1_2 = L1_2.IsAlive
          L2_2 = Pg
          L2_2 = L2_2.GetGuidByName
          L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3ac"
          L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L2_2(L3_2)
          L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
          if not L1_2 then
            L1_2 = DestroyObj5
            L2_2 = L1_2
            L1_2 = L1_2.Complete
            L1_2(L2_2)
          end
        end
      end
    end
  end
end

_DestroyObj5 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Remove
  L2_2 = {}
  L3_2 = "Vz_State_PmcCon033_PopDown"
  L2_2[1] = L3_2
  L1_2(L2_2)
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Add
  L2_2 = {}
  L3_2 = "Vz_State_PmcCon033_PopUp"
  L2_2[1] = L3_2
  L3_2 = _DestroyObj6
  L4_2 = {}
  L5_2 = A0_2
  L4_2[1] = L5_2
  L1_2(L2_2, L3_2, L4_2)
end

TempLoadLayers = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = {}
  L2_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3ae"
  L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3af"
  L4_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3b0"
  L5_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3b1"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  tTargetsToPop = L1_2
  L1_2 = ipairs
  L2_2 = tTargetsToPop
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Vehicle
    L6_2 = L6_2.CloseDoor
    L7_2 = Pg
    L7_2 = L7_2.GetGuidByName
    L8_2 = L5_2
    L7_2 = L7_2(L8_2)
    L8_2 = "pivot"
    L6_2(L7_2, L8_2)
  end
  L1_2 = Net
  L1_2 = L1_2.SendCustomEvent
  L2_2 = "PmcCon033"
  L3_2 = NETEVENT_TARGETSUP
  L4_2 = {}
  L5_2 = true
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "RPG Range Pop"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = tTargetsToPop
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[PmcCon033.Objectives.Portaits]"
  
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
      L0_3 = L0_3._SetCancelMessage
      L1_3 = A0_2
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
  DestroyObj6 = L1_2
  L1_2 = Object
  L1_2 = L1_2.IsAlive
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3ae"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  if not L1_2 then
    L1_2 = Object
    L1_2 = L1_2.IsAlive
    L2_2 = Pg
    L2_2 = L2_2.GetGuidByName
    L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3af"
    L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L2_2(L3_2)
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
    if not L1_2 then
      L1_2 = Object
      L1_2 = L1_2.IsAlive
      L2_2 = Pg
      L2_2 = L2_2.GetGuidByName
      L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3b0"
      L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L2_2(L3_2)
      L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
      if not L1_2 then
        L1_2 = Object
        L1_2 = L1_2.IsAlive
        L2_2 = Pg
        L2_2 = L2_2.GetGuidByName
        L3_2 = "_pmcoutpost_shootinggallerytarget01 0x0012d3b1"
        L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L2_2(L3_2)
        L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
        if not L1_2 then
          L1_2 = DestroyObj6
          L2_2 = L1_2
          L1_2 = L1_2.Complete
          L1_2(L2_2)
        end
      end
    end
  end
end

_DestroyObj6 = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = MrxMusic
  L2_2 = L2_2.PlaySpecialMusic
  L3_2 = "mu_mission_pmccon033_01"
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
    L1_3 = "mu_mission_pmccon033_02"
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
    L1_3 = "mu_mission_pmccon033_01"
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
  L4_2 = "Pistol (silver)"
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
  L3_2 = "Pistol (silver)"
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
end

_CountDownVOSetup = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = A0_2.CourseTimer
  L2_2 = L1_2
  L1_2 = L1_2.Pause
  L1_2(L2_2)
  L1_2 = MrxShootingGallery
  L1_2 = L1_2.SetupBorder
  L2_2 = nil
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
  L2_2 = "PmcCon033"
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
  L2_2 = "PmcCon033"
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

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = _evClientJoinedPMC033
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = _evMoveWeapons
  L1_2(L2_2)
  L1_2 = Hud
  L1_2 = L1_2.SupportMenu
  L2_2 = L1_2
  L1_2 = L1_2.SetShootingGalleryMode
  L3_2 = {}
  L3_2.bEnable = false
  L1_2(L2_2, L3_2)
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
  L1_2 = MrxShootingGallery
  L1_2 = L1_2.SetupBorder
  L2_2 = nil
  L1_2(L2_2)
  L1_2 = MrxMusic
  L1_2 = L1_2.StopSpecialMusic
  L1_2()
  L1_2 = A0_2.CourseTimer
  if L1_2 then
    L1_2 = MrxTimer
    L1_2 = L1_2.Stop
    L2_2 = A0_2.CourseTimer
    L1_2(L2_2)
  end
  L1_2 = ipairs
  L2_2 = tLayersToAdd
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = MrxLayerManager
    L6_2 = L6_2.MarkForRemoval
    L7_2 = L5_2
    L6_2(L7_2)
  end
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
