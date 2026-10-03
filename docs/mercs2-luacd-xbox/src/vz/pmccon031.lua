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
L0_1 = {}
tCarsToDelete = L0_1
L0_1 = false
bDamageWarning = L0_1
L0_1 = 0
CoolDown = L0_1
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
        L2_2 = Player
        L2_2 = L2_2.SetAimMode
        L3_2 = Player
        L3_2 = L3_2.GetPrimaryPlayer
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
  L2_2 = {}
  L3_2 = "Vz_State_PmcCon031"
  L4_2 = "Vz_state_PMC"
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
      L1_3 = "PmcCon031"
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
  L6_2 = "PmcCon031"
  L7_2 = NETEVENT_SETSTARTUPWEAPONS
  L8_2 = {}
  L9_2 = true
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  _evClientJoinedPMC031 = L1_2
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
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetNumCompletions
  L1_2 = L1_2(L2_2)
  nCompletions = L1_2
  L1_2 = 2.5
  PointDist = L1_2
  L1_2 = 10
  NumCars = L1_2
  L1_2 = nCompletions
  if L1_2 == 0 then
    L1_2 = 240
    nTimeLimit = L1_2
    L1_2 = "4:00"
    sTimeToBeat = L1_2
  else
    L1_2 = nCompletions
    if L1_2 == 1 then
      L1_2 = 150
      nTimeLimit = L1_2
      L1_2 = "2:30"
      sTimeToBeat = L1_2
    else
      L1_2 = nCompletions
      if 2 <= L1_2 then
        L1_2 = 90
        nTimeLimit = L1_2
        L1_2 = "1:30"
        sTimeToBeat = L1_2
      end
    end
  end
  L2_2 = A0_2
  L1_2 = A0_2._SetupObjective
  L3_2 = nTimeLimit
  L4_2 = nQuota
  L1_2(L2_2, L3_2, L4_2)
end

Activated = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = Player
  L3_2 = L3_2.GetSecondaryCharacter
  L3_2 = L3_2()
  if L3_2 then
    L3_2 = Human
    L3_2 = L3_2.Inventory
    L3_2 = L3_2.GetAllWeapons
    L4_2 = Player
    L4_2 = L4_2.GetSecondaryCharacter
    L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L4_2()
    L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
    tLocalP2Weapons = L3_2
  end
  L3_2 = Player
  L3_2 = L3_2.SetAimMode
  L4_2 = Player
  L4_2 = L4_2.GetPrimaryPlayer
  L4_2 = L4_2()
  L5_2 = false
  L3_2(L4_2, L5_2)
  L3_2 = Player
  L3_2 = L3_2.GetSecondaryPlayer
  L3_2 = L3_2()
  if L3_2 then
    L3_2 = Player
    L3_2 = L3_2.SetAimMode
    L4_2 = Player
    L4_2 = L4_2.GetSecondaryPlayer
    L4_2 = L4_2()
    L5_2 = false
    L3_2(L4_2, L5_2)
  end
  L3_2 = MrxTimer
  L4_2 = L3_2
  L3_2 = L3_2.Create
  L5_2 = {}
  L5_2.nStartTime = A1_2
  L5_2.nStopTime = 0
  L5_2.nStep = 0.1
  L5_2.nWarning = 10
  L5_2.bUseTenths = true
  L5_2.iTray = 1
  L6_2 = {}
  L7_2 = {}
  L8_2 = TimeUp
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L6_2[1] = L7_2
  L5_2.tDoneCallbacks = L6_2
  L3_2 = L3_2(L4_2, L5_2)
  A0_2.CourseTimer = L3_2
  L3_2 = _CountDownVOSetup
  L4_2 = A0_2
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
  L3_2 = A0_2.CourseTimer
  L4_2 = L3_2
  L3_2 = L3_2.Start
  L3_2(L4_2)
  L3_2 = PlayMusic
  L4_2 = A0_2
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
  L3_2 = Object
  L3_2 = L3_2.GetHealth
  L4_2 = Player
  L4_2 = L4_2.GetLocalCharacter
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L4_2()
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  nHealth = L3_2
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.ObjectHealth
  L6_2 = {}
  L7_2 = Player
  L7_2 = L7_2.GetLocalCharacter
  L7_2 = L7_2()
  L8_2 = "<"
  L9_2 = nHealth
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L7_2 = DamageWarningVO
  L3_2(L4_2, L5_2, L6_2, L7_2)
  L3_2 = 0
  iGlsDead = L3_2
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.ObjectDeath
  L6_2 = {}
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "Emplaced GL 0x00126f78"
  L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  
  function L7_2()
    local L0_3, L1_3, L2_3
    L0_3 = DamageWarningVO
    L0_3()
    L0_3 = iGlsDead
    L0_3 = L0_3 + 1
    iGlsDead = L0_3
    L0_3 = iGlsDead
    if L0_3 == 2 then
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._SetCancelMessage
      L2_3 = "[PmcCon031.Terms.CancelTurrets]"
      L0_3(L1_3, L2_3)
      L0_3 = Cancel
      L1_3 = A0_2
      L0_3(L1_3)
    end
  end
  
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  uGLDeath1 = L3_2
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.ObjectDeath
  L6_2 = {}
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "Emplaced GL 0x0012d383"
  L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  
  function L7_2()
    local L0_3, L1_3, L2_3
    L0_3 = DamageWarningVO
    L0_3()
    L0_3 = iGlsDead
    L0_3 = L0_3 + 1
    iGlsDead = L0_3
    L0_3 = iGlsDead
    if L0_3 == 2 then
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._SetCancelMessage
      L2_3 = "[PmcCon031.Terms.CancelTurrets]"
      L0_3(L1_3, L2_3)
      L0_3 = Cancel
      L1_3 = A0_2
      L0_3(L1_3)
    end
  end
  
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  uGLDeath2 = L3_2
  L3_2 = 0
  iMGsDead = L3_2
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.ObjectDeath
  L6_2 = {}
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "Emplaced MG 0x00126f7a"
  L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  
  function L7_2()
    local L0_3, L1_3, L2_3
    L0_3 = iMGsDead
    L0_3 = L0_3 + 1
    iMGsDead = L0_3
    L0_3 = iMGsDead
    if L0_3 == 2 then
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._SetCancelMessage
      L2_3 = "[PmcCon031.Terms.CancelTurrets]"
      L0_3(L1_3, L2_3)
      L0_3 = Cancel
      L1_3 = A0_2
      L0_3(L1_3)
    end
  end
  
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  uMGDeath1 = L3_2
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.ObjectDeath
  L6_2 = {}
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "Emplaced MG 0x0012d380"
  L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  
  function L7_2()
    local L0_3, L1_3, L2_3
    L0_3 = iMGsDead
    L0_3 = L0_3 + 1
    iMGsDead = L0_3
    L0_3 = iMGsDead
    if L0_3 == 2 then
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._SetCancelMessage
      L2_3 = "[PmcCon031.Terms.CancelTurrets]"
      L0_3(L1_3, L2_3)
      L0_3 = Cancel
      L1_3 = A0_2
      L0_3(L1_3)
    end
  end
  
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  uMGDeath2 = L3_2
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.ObjectDeath
  L6_2 = {}
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "Emplaced Recoiless Rifle 0x0012d382"
  L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  
  function L7_2()
    local L0_3, L1_3
    L0_3 = DamageWarningVO
    L0_3()
  end
  
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  uRRDeath2 = L3_2
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.ObjectDeath
  L6_2 = {}
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "Emplaced Recoiless Rifle 0x00126f75"
  L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  
  function L7_2()
    local L0_3, L1_3
    L0_3 = DamageWarningVO
    L0_3()
  end
  
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  uRRDeath2 = L3_2
  L3_2 = _MoveToMG
  L4_2 = A0_2
  L3_2(L4_2)
end

_SetupObjective = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = nCompletions
  if L1_2 < 2 then
    L1_2 = {}
    L2_2 = "Fiona-In-Mission-MinorContract-Pmc31-32"
    L3_2 = 1
    L4_2 = "Fiona-In-Mission-MinorContract-Pmc31-29"
    L1_2[1] = L2_2
    L1_2[2] = L3_2
    L1_2[3] = L4_2
    tMGVO = L1_2
  else
    L1_2 = {}
    L2_2 = "Fiona-In-Mission-MinorContract-Pmc31-29"
    L1_2[1] = L2_2
    tMGVO = L1_2
  end
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "MoveToMG"
  L3_2.sDspShortDesc = "[PmcCon031.Objectives.MoveMG]"
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2 = Player
  L4_2 = L4_2.GetAnyCharacter
  L4_2 = L4_2()
  L3_2.vTgtInclude = L4_2
  L3_2.bDspBlp = true
  L3_2.vDestLoc = "PmcCon031_MGPoint"
  L3_2.fDist = 3
  L3_2.bStop = true
  
  function L4_2()
    local L0_3, L1_3
    L0_3 = _DestroyStatues
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L3_2.fOnComplete = L4_2
  L4_2 = tMGVO
  L3_2.vVoSeqOnAdd = L4_2
  L1_2(L2_2, L3_2)
end

_MoveToMG = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2, L47_2, L48_2, L49_2, L50_2, L51_2, L52_2
  L1_2 = 0
  L2_2 = {}
  L3_2 = "_pmcoutpost_column_noreflection 0x00127085"
  L4_2 = "_pmcoutpost_column_noreflection 0x00127086"
  L5_2 = "_pmcoutpost_column_noreflection 0x00127087"
  L6_2 = "_pmcoutpost_column_noreflection 0x00127088"
  L7_2 = "_pmcoutpost_column_noreflection 0x00127089"
  L8_2 = "_pmcoutpost_column_noreflection 0x0012708a"
  L9_2 = "_pmcoutpost_column_noreflection 0x0012708b"
  L10_2 = "_pmcoutpost_column_noreflection 0x0012708c"
  L11_2 = "_pmcoutpost_column_noreflection 0x0012708d"
  L12_2 = "_pmcoutpost_column_noreflection 0x0012d09f"
  L13_2 = "_pmcoutpost_column_noreflection 0x0012d0a1"
  L14_2 = "_pmcoutpost_column_noreflection 0x0012d0a3"
  L15_2 = "_pmcoutpost_column_noreflection 0x0012d0a4"
  L16_2 = "_pmcoutpost_column_noreflection 0x0012d0a5"
  L17_2 = "_pmcoutpost_column_noreflection 0x0012d0a6"
  L18_2 = "_pmcoutpost_column_noreflection 0x0012d0a7"
  L19_2 = "_pmcoutpost_column_noreflection 0x0012d0a8"
  L20_2 = "_pmcoutpost_column_noreflection 0x0012d0a9"
  L21_2 = "_pmcoutpost_column_noreflection 0x0012d0aa"
  L22_2 = "_pmcoutpost_column_noreflection 0x0012d0ab"
  L23_2 = "_pmcoutpost_column_noreflection 0x0012d0ac"
  L24_2 = "_pmcoutpost_column_noreflection 0x0012d0ad"
  L25_2 = "_pmcoutpost_column_noreflection 0x0012d0ae"
  L26_2 = "_pmcoutpost_column_noreflection 0x0012d0af"
  L27_2 = "_pmcoutpost_column_noreflection 0x0012d0b0"
  L28_2 = "_pmcoutpost_column_noreflection 0x0012d0b1"
  L29_2 = "_pmcoutpost_column_noreflection 0x0012d0b2"
  L30_2 = "_pmcoutpost_column_noreflection 0x0012d0b3"
  L31_2 = "_pmcoutpost_column_noreflection 0x0012d0b4"
  L32_2 = "_pmcoutpost_column_noreflection 0x0012d0b5"
  L33_2 = "_pmcoutpost_column_noreflection 0x0012d0b6"
  L34_2 = "_pmcoutpost_column_noreflection 0x0012d0b7"
  L35_2 = "_pmcoutpost_column_noreflection 0x0012d0b8"
  L36_2 = "_pmcoutpost_column_noreflection 0x0012d0b9"
  L37_2 = "_pmcoutpost_column_noreflection 0x0012d0ba"
  L38_2 = "_pmcoutpost_column_noreflection 0x0012d0bb"
  L39_2 = "_pmcoutpost_column_noreflection 0x0012d0bc"
  L40_2 = "_pmcoutpost_column_noreflection 0x0012d0bd"
  L41_2 = "_pmcoutpost_column_noreflection 0x0012d0bf"
  L42_2 = "_pmcoutpost_column_noreflection 0x0012d0c0"
  L43_2 = "_pmcoutpost_column_noreflection 0x0012d0c1"
  L44_2 = "_pmcoutpost_column_noreflection 0x0012d0c2"
  L45_2 = "_pmcoutpost_column_noreflection 0x0012d0c3"
  L46_2 = "_pmcoutpost_column_noreflection 0x0012d0c4"
  L47_2 = "_pmcoutpost_column_noreflection 0x0012d0c5"
  L48_2 = "_pmcoutpost_column_noreflection 0x0012d0c6"
  L49_2 = "_pmcoutpost_column_noreflection 0x0012d0c7"
  L50_2 = "_pmcoutpost_column_noreflection 0x0012d0c8"
  L51_2 = "_pmcoutpost_column_noreflection 0x0012d0c9"
  L52_2 = "_pmcoutpost_column_noreflection 0x0012d0cb"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L2_2[6] = L8_2
  L2_2[7] = L9_2
  L2_2[8] = L10_2
  L2_2[9] = L11_2
  L2_2[10] = L12_2
  L2_2[11] = L13_2
  L2_2[12] = L14_2
  L2_2[13] = L15_2
  L2_2[14] = L16_2
  L2_2[15] = L17_2
  L2_2[16] = L18_2
  L2_2[17] = L19_2
  L2_2[18] = L20_2
  L2_2[19] = L21_2
  L2_2[20] = L22_2
  L2_2[21] = L23_2
  L2_2[22] = L24_2
  L2_2[23] = L25_2
  L2_2[24] = L26_2
  L2_2[25] = L27_2
  L2_2[26] = L28_2
  L2_2[27] = L29_2
  L2_2[28] = L30_2
  L2_2[29] = L31_2
  L2_2[30] = L32_2
  L2_2[31] = L33_2
  L2_2[32] = L34_2
  L2_2[33] = L35_2
  L2_2[34] = L36_2
  L2_2[35] = L37_2
  L2_2[36] = L38_2
  L2_2[37] = L39_2
  L2_2[38] = L40_2
  L2_2[39] = L41_2
  L2_2[40] = L42_2
  L2_2[41] = L43_2
  L2_2[42] = L44_2
  L2_2[43] = L45_2
  L2_2[44] = L46_2
  L2_2[45] = L47_2
  L2_2[46] = L48_2
  L2_2[47] = L49_2
  L2_2[48] = L50_2
  L2_2[49] = L51_2
  L2_2[50] = L52_2
  tStatueTargets = L2_2
  L2_2 = ipairs
  L3_2 = tStatueTargets
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = Object
    L7_2 = L7_2.IsAlive
    L8_2 = Pg
    L8_2 = L8_2.GetGuidByName
    L9_2 = L6_2
    L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2, L47_2, L48_2, L49_2, L50_2, L51_2, L52_2 = L8_2(L9_2)
    L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2, L47_2, L48_2, L49_2, L50_2, L51_2, L52_2)
    if L7_2 then
      L1_2 = L1_2 + 1
    end
  end
  L2_2 = Math
  L2_2 = L2_2.randi
  L3_2 = 1
  L4_2 = 15
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 == 1 then
    L3_2 = A0_2
    L2_2 = A0_2._CreateEvent
    L4_2 = Event
    L4_2 = L4_2.TimerRelative
    L5_2 = {}
    L6_2 = 10
    L5_2[1] = L6_2
    L6_2 = MrxVoSequence
    L6_2 = L6_2.Start
    L7_2 = {}
    L8_2 = {}
    L9_2 = "Fiona-In-Mission-MinorContract-Pmc33-02"
    L8_2[1] = L9_2
    L7_2[1] = L8_2
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  end
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "Fake Destroy Statues"
  L4_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2.vTgtInclude = "MGStatueLoc"
  L4_2.bDspMsg = false
  L4_2.bDspDescPda = false
  L4_2.bDspBlpWld = false
  L4_2.bDspBlpRdr = true
  L4_2.bDspBlpPda = true
  L4_2.sDspShortDesc = "[PmcCon031.Objectives.TakeOut]"
  L2_2 = L2_2(L3_2, L4_2)
  oFakeMachineGunObj = L2_2
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "Destroy Statues"
  L4_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2.sTgtLabelFilter = "PMCCon031Statue"
  L5_2 = tStatueTargets
  L4_2.vTgtInclude = L5_2
  L4_2.nQuota = L1_2
  L4_2.bDspBlp = false
  L4_2.sDspShortDesc = "[PmcCon031.Objectives.TakeOut]"
  L5_2 = {}
  L6_2 = {}
  L7_2 = StatueKilled
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnPartComplete = L5_2
  
  function L5_2()
    local L0_3, L1_3
    L0_3 = _MoveToRR
    L1_3 = A0_2
    L0_3(L1_3)
    L0_3 = oFakeMachineGunObj
    L0_3 = L0_3.Complete
    L1_3 = oFakeMachineGunObj
    L0_3(L1_3)
    L0_3 = oFakeMachineGunObj2
    if L0_3 then
      L0_3 = oFakeMachineGunObj2
      L0_3 = L0_3.Complete
      L1_3 = oFakeMachineGunObj2
      L0_3(L1_3)
    end
  end
  
  L4_2.fOnComplete = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  oMachineGunObj = L2_2
  if L1_2 <= 0 then
    L2_2 = oMachineGunObj
    L2_2 = L2_2.Complete
    L3_2 = oMachineGunObj
    L2_2(L3_2)
  end
end

_DestroyStatues = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = oMachineGunObj
  L2_2 = L2_2._nCompleted
  L3_2 = oMachineGunObj
  L3_2 = L3_2._nQuota
  L3_2 = L3_2 - 5
  if L2_2 == L3_2 then
    L2_2 = oFakeMachineGunObj
    L3_2 = L2_2
    L2_2 = L2_2.Configure
    L4_2 = {}
    L4_2.bDspBlpRdr = false
    L2_2(L3_2, L4_2)
    L3_2 = A0_2
    L2_2 = A0_2.CreateChild
    L4_2 = {}
    L4_2.sName = "Destroy Statues Blip"
    L4_2.sModuleName = "MrxTaskObjectiveDestroy"
    L5_2 = tStatueTargets
    L4_2.vTgtInclude = L5_2
    L4_2.bDspMsg = false
    L4_2.bDspDescPda = false
    L4_2.bDspBlpWld = true
    L4_2.bDspBlpRdr = false
    L4_2.bDspBlpPda = false
    L4_2.sDspShortDesc = "[PmcCon031.Objectives.TakeOut]"
    L2_2 = L2_2(L3_2, L4_2)
    oFakeMachineGunObj2 = L2_2
  end
end

StatueKilled = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.curObj
  L1_2 = L1_2._nCompleted
  L2_2 = A0_2.curObj
  L2_2 = L2_2._nQuota
  L2_2 = L2_2 - 4
  if L1_2 == L2_2 then
    L1_2 = A0_2.curObj
    L2_2 = L1_2
    L1_2 = L1_2.Configure
    L3_2 = {}
    L3_2.bDspBlp = true
    L1_2(L2_2, L3_2)
  end
end

Obj_MGStatues_StatueKilled = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = uMGDeath1
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = uMGDeath2
  L1_2(L2_2)
  L1_2 = 0
  CarsMissed = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "MoveToRR"
  L3_2.sDspShortDesc = "[PmcCon031.Objectives.MoveRR]"
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2 = Player
  L4_2 = L4_2.GetAnyCharacter
  L4_2 = L4_2()
  L3_2.vTgtInclude = L4_2
  L3_2.bDspBlp = true
  L3_2.vDestLoc = "PmcCon031_RRPoint"
  L3_2.fDist = 6
  L3_2.bStop = true
  
  function L4_2()
    local L0_3, L1_3
    L0_3 = _SpawnCar
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L3_2.fOnComplete = L4_2
  L4_2 = {}
  L5_2 = "Fiona-In-Mission-MinorContract-Pmc31-36"
  L4_2[1] = L5_2
  L3_2.vVoSeqOnAdd = L4_2
  L1_2(L2_2, L3_2)
end

_MoveToRR = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.nSlot = 3
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "MoveToGL"
  L3_2.sDspShortDesc = "[PmcCon031.Objectives.MoveGL]"
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2 = Player
  L4_2 = L4_2.GetAnyCharacter
  L4_2 = L4_2()
  L3_2.vTgtInclude = L4_2
  L3_2.bDspBlp = true
  L3_2.vDestLoc = "PmcCon031_GLPoint"
  L3_2.fDist = 2
  L3_2.bStop = true
  
  function L4_2()
    local L0_3, L1_3
    L0_3 = _DestroyStatuesGL
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L3_2.fOnComplete = L4_2
  L4_2 = {}
  L5_2 = "Fiona-In-Mission-MinorContract-Pmc31-31"
  L4_2[1] = L5_2
  L3_2.vVoSeqOnAdd = L4_2
  L1_2(L2_2, L3_2)
end

_MovetoGL = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2, L47_2, L48_2, L49_2, L50_2, L51_2, L52_2
  L1_2 = 0
  L2_2 = {}
  L3_2 = "_pmcoutpost_column_noreflection_large 0x0012d0cc"
  L4_2 = "_pmcoutpost_column_noreflection_large 0x0012d0cd"
  L5_2 = "_pmcoutpost_column_noreflection_large 0x0012d0ce"
  L6_2 = "_pmcoutpost_column_noreflection_large 0x0012d0cf"
  L7_2 = "_pmcoutpost_column_noreflection_large 0x0012d0d1"
  L8_2 = "_pmcoutpost_column_noreflection_large 0x0012d0d2"
  L9_2 = "_pmcoutpost_column_noreflection_large 0x0012d0d3"
  L10_2 = "_pmcoutpost_column_noreflection_large 0x0012d0d7"
  L11_2 = "_pmcoutpost_column_noreflection_large 0x0012d0d9"
  L12_2 = "_pmcoutpost_column_noreflection_large 0x0012d0da"
  L13_2 = "_pmcoutpost_column_noreflection_large 0x0012d0db"
  L14_2 = "_pmcoutpost_column_noreflection_large 0x0012d0e0"
  L15_2 = "_pmcoutpost_column_noreflection_large 0x0012d0e3"
  L16_2 = "_pmcoutpost_column_noreflection_large 0x0012d0e4"
  L17_2 = "_pmcoutpost_column_noreflection_large 0x0012d0e6"
  L18_2 = "_pmcoutpost_column_noreflection_large 0x0012d0e7"
  L19_2 = "_pmcoutpost_column_noreflection_large 0x0012d0e8"
  L20_2 = "_pmcoutpost_column_noreflection_large 0x0012d0e9"
  L21_2 = "_pmcoutpost_column_noreflection_large 0x0012d0ea"
  L22_2 = "_pmcoutpost_column_noreflection_large 0x0012d0eb"
  L23_2 = "_pmcoutpost_column_noreflection_large 0x0012d0ec"
  L24_2 = "_pmcoutpost_column_noreflection_large 0x0012d0ee"
  L25_2 = "_pmcoutpost_column_noreflection_large 0x0012d0ef"
  L26_2 = "_pmcoutpost_column_noreflection_large 0x0012d0f0"
  L27_2 = "_pmcoutpost_column_noreflection_large 0x0012d0f1"
  L28_2 = "_pmcoutpost_column_noreflection_large 0x0012d0f3"
  L29_2 = "_pmcoutpost_column_noreflection_large 0x0012d0f4"
  L30_2 = "_pmcoutpost_column_noreflection_large 0x0012d0f5"
  L31_2 = "_pmcoutpost_column_noreflection_large 0x0012d0f6"
  L32_2 = "_pmcoutpost_column_noreflection_large 0x0012d0f7"
  L33_2 = "_pmcoutpost_column_noreflection_large 0x0012d0f8"
  L34_2 = "_pmcoutpost_column_noreflection_large 0x0012d0fa"
  L35_2 = "_pmcoutpost_column_noreflection_large 0x0012d0fb"
  L36_2 = "_pmcoutpost_column_noreflection_large 0x0012d0fc"
  L37_2 = "_pmcoutpost_column_noreflection_large 0x0012d0fd"
  L38_2 = "_pmcoutpost_column_noreflection_large 0x0012d1d0"
  L39_2 = "_pmcoutpost_column_noreflection_large 0x0012d1d2"
  L40_2 = "_pmcoutpost_column_noreflection_large 0x0012d1d3"
  L41_2 = "_pmcoutpost_column_noreflection_large 0x0012d1d5"
  L42_2 = "_pmcoutpost_column_noreflection_large 0x0012d1d6"
  L43_2 = "_pmcoutpost_column_noreflection_large 0x0012d1d7"
  L44_2 = "_pmcoutpost_column_noreflection_large 0x0012d1d8"
  L45_2 = "_pmcoutpost_column_noreflection_large 0x0012d1d9"
  L46_2 = "_pmcoutpost_column_noreflection_large 0x0012d1da"
  L47_2 = "_pmcoutpost_column_noreflection_large 0x0012d1db"
  L48_2 = "_pmcoutpost_column_noreflection_large 0x0012d1dc"
  L49_2 = "_pmcoutpost_column_noreflection_large 0x0012d1dd"
  L50_2 = "_pmcoutpost_column_noreflection_large 0x0012d1de"
  L51_2 = "_pmcoutpost_column_noreflection_large 0x0012d1df"
  L52_2 = "_pmcoutpost_column_noreflection_large 0x0012d1e0"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L2_2[6] = L8_2
  L2_2[7] = L9_2
  L2_2[8] = L10_2
  L2_2[9] = L11_2
  L2_2[10] = L12_2
  L2_2[11] = L13_2
  L2_2[12] = L14_2
  L2_2[13] = L15_2
  L2_2[14] = L16_2
  L2_2[15] = L17_2
  L2_2[16] = L18_2
  L2_2[17] = L19_2
  L2_2[18] = L20_2
  L2_2[19] = L21_2
  L2_2[20] = L22_2
  L2_2[21] = L23_2
  L2_2[22] = L24_2
  L2_2[23] = L25_2
  L2_2[24] = L26_2
  L2_2[25] = L27_2
  L2_2[26] = L28_2
  L2_2[27] = L29_2
  L2_2[28] = L30_2
  L2_2[29] = L31_2
  L2_2[30] = L32_2
  L2_2[31] = L33_2
  L2_2[32] = L34_2
  L2_2[33] = L35_2
  L2_2[34] = L36_2
  L2_2[35] = L37_2
  L2_2[36] = L38_2
  L2_2[37] = L39_2
  L2_2[38] = L40_2
  L2_2[39] = L41_2
  L2_2[40] = L42_2
  L2_2[41] = L43_2
  L2_2[42] = L44_2
  L2_2[43] = L45_2
  L2_2[44] = L46_2
  L2_2[45] = L47_2
  L2_2[46] = L48_2
  L2_2[47] = L49_2
  L2_2[48] = L50_2
  L2_2[49] = L51_2
  L2_2[50] = L52_2
  L3_2 = "_pmcoutpost_column_noreflection_large 0x0012d1e1"
  L4_2 = "_pmcoutpost_column_noreflection_large 0x0012d1e2"
  L5_2 = "_pmcoutpost_column_noreflection_large 0x0012d1e3"
  L6_2 = "_pmcoutpost_column_noreflection_large 0x0012d1e4"
  L7_2 = "_pmcoutpost_column_noreflection_large 0x0012d1e5"
  L2_2[51] = L3_2
  L2_2[52] = L4_2
  L2_2[53] = L5_2
  L2_2[54] = L6_2
  L2_2[55] = L7_2
  tGrenadeStatueTargets = L2_2
  L2_2 = ipairs
  L3_2 = tGrenadeStatueTargets
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = Object
    L7_2 = L7_2.IsAlive
    L8_2 = Pg
    L8_2 = L8_2.GetGuidByName
    L9_2 = L6_2
    L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2, L47_2, L48_2, L49_2, L50_2, L51_2, L52_2 = L8_2(L9_2)
    L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2, L47_2, L48_2, L49_2, L50_2, L51_2, L52_2)
    if L7_2 then
      L1_2 = L1_2 + 1
    end
  end
  L1_2 = L1_2 - 5
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "Fake Destroy Statues"
  L4_2.sModuleName = "MrxTaskObjectiveDestroy"
  L5_2 = {}
  L6_2 = "RRStatueLoc2"
  L5_2[1] = L6_2
  L4_2.vTgtInclude = L5_2
  L4_2.bDspMsg = false
  L4_2.bDspBlp = true
  L4_2.bDspDescPda = false
  L4_2.bDspBlpWld = false
  L4_2.bDspBlpRdr = true
  L4_2.bDspBlpPda = true
  L4_2.sDspShortDesc = "[PmcCon031.Objectives.TakeOut]"
  L2_2 = L2_2(L3_2, L4_2)
  oFakeGrenadeObj = L2_2
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "Fake Destroy Statues2"
  L4_2.sModuleName = "MrxTaskObjectiveDestroy"
  L5_2 = {}
  L6_2 = "RRStatueLoc1"
  L5_2[1] = L6_2
  L4_2.vTgtInclude = L5_2
  L4_2.bDspMsg = false
  L4_2.bDspBlp = true
  L4_2.bDspDescPda = false
  L4_2.bDspBlpWld = false
  L4_2.bDspBlpRdr = true
  L4_2.bDspBlpPda = true
  L4_2.sDspShortDesc = "[PmcCon031.Objectives.TakeOut]"
  L2_2 = L2_2(L3_2, L4_2)
  oFakeGrenadeObj1 = L2_2
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "Emplaced Grenade Destroy"
  L4_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2.sTgtLabelFilter = "PMCCon031StatueGL"
  L4_2.nQuota = L1_2
  L4_2.bDspBlp = true
  L4_2.sDspShortDesc = "[PmcCon031.Objectives.TakeOut]"
  L5_2 = {}
  L6_2 = {}
  L7_2 = StatueKilledGrenade
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnPartComplete = L5_2
  
  function L5_2()
    local L0_3, L1_3
    L0_3 = uCountdown5
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = uCountdown5
      L0_3(L1_3)
    end
    L0_3 = uCountdown15
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = uCountdown15
      L0_3(L1_3)
    end
    L0_3 = uCountdown30
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = uCountdown30
      L0_3(L1_3)
    end
    L0_3 = oFakeGrenadeObj
    L0_3 = L0_3.Complete
    L1_3 = oFakeGrenadeObj
    L0_3(L1_3)
    L0_3 = oFakeGrenadeObj1
    L0_3 = L0_3.Complete
    L1_3 = oFakeGrenadeObj1
    L0_3(L1_3)
    L0_3 = oFakeGrenadeObj2
    if L0_3 then
      L0_3 = oFakeGrenadeObj2
      L0_3 = L0_3.Complete
      L1_3 = oFakeGrenadeObj2
      L0_3(L1_3)
    end
    L0_3 = CompleteVO
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L4_2.fOnComplete = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  oGrenadeObj = L2_2
  if L1_2 <= 0 then
    L2_2 = oGrenadeObj
    L2_2 = L2_2.Complete
    L3_2 = oGrenadeObj
    L2_2(L3_2)
  end
end

_DestroyStatuesGL = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = oGrenadeObj
  L2_2 = L2_2._nCompleted
  L3_2 = oGrenadeObj
  L3_2 = L3_2._nQuota
  L3_2 = L3_2 - 10
  if L2_2 == L3_2 then
    L3_2 = A0_2
    L2_2 = A0_2.CreateChild
    L4_2 = {}
    L4_2.sName = "Destroy Grenade Statues Blip"
    L4_2.sModuleName = "MrxTaskObjectiveDestroy"
    L5_2 = tGrenadeStatueTargets
    L4_2.vTgtInclude = L5_2
    L4_2.bDspMsg = false
    L4_2.bDspDescPda = false
    L4_2.bDspBlpWld = true
    L4_2.bDspBlpRdr = false
    L4_2.bDspBlpPda = false
    L4_2.sDspShortDesc = "[PmcCon031.Objectives.TakeOut]"
    L2_2 = L2_2(L3_2, L4_2)
    oFakeGrenadeObj2 = L2_2
  end
end

StatueKilledGrenade = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = NumCars
  L1_2 = L1_2 - 1
  NumCars = L1_2
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.SetSlotToText
  L3_2 = {}
  L3_2.nSlot = 3
  L4_2 = "[PmcCon031.Terms.CarCount] "
  L5_2 = NumCars
  L4_2 = L4_2 .. L5_2
  L3_2.sText = L4_2
  L1_2(L2_2, L3_2)
  L1_2 = uEndCarObjTimer
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = uEndCarObjTimer
    L1_2(L2_2)
  end
  L1_2 = Math
  L1_2 = L1_2.randi
  L2_2 = 1
  L3_2 = 4
  L1_2 = L1_2(L2_2, L3_2)
  L2_2 = nil
  L3_2 = nil
  L4_2 = nil
  if L1_2 == 1 then
    L5_2 = "L300 (Fling Forward)"
    sCar = L5_2
    L5_2 = 2759.982
    L6_2 = -14.324945
    L4_2 = -867.9881
    L3_2 = L6_2
    L2_2 = L5_2
  elseif L1_2 == 2 then
    L5_2 = "R90 (Fling Right)"
    sCar = L5_2
    L5_2 = 2821.7236
    L6_2 = -14.031256
    L4_2 = -838.6553
    L3_2 = L6_2
    L2_2 = L5_2
  elseif L1_2 == 3 then
    L5_2 = "R90 (Fling Left)"
    sCar = L5_2
    L5_2 = 2688.671
    L6_2 = -14.32493
    L4_2 = -809.67426
    L3_2 = L6_2
    L2_2 = L5_2
  elseif L1_2 == 4 then
    L5_2 = "L300 (Fling Backward)"
    sCar = L5_2
    L5_2 = 2773.6199
    L6_2 = -21.570244
    L4_2 = -710.3076
    L3_2 = L6_2
    L2_2 = L5_2
  end
  L5_2 = Pg
  L5_2 = L5_2.Spawn
  L6_2 = sCar
  L7_2 = L2_2
  L8_2 = L3_2
  L9_2 = L4_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  uTempCar = L5_2
  L5_2 = table
  L5_2 = L5_2.insert
  L6_2 = tCarsToDelete
  L7_2 = uTempCar
  L5_2(L6_2, L7_2)
  L5_2 = NumCars
  if L5_2 == 0 then
    L6_2 = A0_2
    L5_2 = A0_2._CreateEvent
    L7_2 = Event
    L7_2 = L7_2.TimerRelative
    L8_2 = {}
    L9_2 = 10
    L8_2[1] = L9_2
    L9_2 = _MovetoGL
    L10_2 = {}
    L11_2 = A0_2
    L10_2[1] = L11_2
    L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
    uRecurse = L5_2
  else
    L6_2 = A0_2
    L5_2 = A0_2._CreateEvent
    L7_2 = Event
    L7_2 = L7_2.TimerRelative
    L8_2 = {}
    L9_2 = 10
    L8_2[1] = L9_2
    L9_2 = _SpawnCar
    L10_2 = {}
    L11_2 = A0_2
    L10_2[1] = L11_2
    L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
    uRecurse = L5_2
  end
  L5_2 = "TempStatue"
  L6_2 = NumCars
  L5_2 = L5_2 .. L6_2
  sObjName = L5_2
  L6_2 = A0_2
  L5_2 = A0_2.CreateChild
  L7_2 = {}
  L8_2 = sObjName
  L7_2.sName = L8_2
  L7_2.sModuleName = "MrxTaskObjectiveDestroy"
  L8_2 = uTempCar
  L7_2.vTgtInclude = L8_2
  L7_2.sDspShortDesc = "[PmcCon031.Objectives.DestroyCar]"
  
  function L8_2()
    local L0_3, L1_3
    L0_3 = _CarHit
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L7_2.fOnComplete = L8_2
  L5_2 = L5_2(L6_2, L7_2)
  uTempObj = L5_2
  L6_2 = A0_2
  L5_2 = A0_2._CreateEvent
  L7_2 = Event
  L7_2 = L7_2.TimerRelative
  L8_2 = {}
  L9_2 = 9
  L8_2[1] = L9_2
  
  function L9_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3
    L0_3 = uTempObj
    L0_3 = L0_3.Cancel
    L1_3 = uTempObj
    L0_3(L1_3)
    L0_3 = CarsMissed
    L0_3 = L0_3 + 1
    CarsMissed = L0_3
    L0_3 = CarsMissed
    if L0_3 == 4 then
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
  
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  uEndCarObjTimer = L5_2
  L6_2 = A0_2
  L5_2 = A0_2._CreateEvent
  L7_2 = Event
  L7_2 = L7_2.ObjectDeath
  L8_2 = {}
  L9_2 = uTempCar
  L8_2[1] = L9_2
  
  function L9_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = CoolDown
    if L0_3 == 0 then
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
      L0_3 = 1
      CoolDown = L0_3
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._CreateEvent
      L2_3 = Event
      L2_3 = L2_3.TimerRelative
      L3_3 = {}
      L4_3 = 25
      L3_3[1] = L4_3
      
      function L4_3()
        local L0_4, L1_4
        L0_4 = 0
        CoolDown = L0_4
      end
      
      L0_3(L1_3, L2_3, L3_3, L4_3)
    end
  end
  
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  uCongratVO = L5_2
  L6_2 = A0_2
  L5_2 = A0_2._CreateEvent
  L7_2 = Event
  L7_2 = L7_2.TimerRelative
  L8_2 = {}
  L9_2 = 5
  L8_2[1] = L9_2
  L9_2 = Event
  L9_2 = L9_2.Delete
  L10_2 = {}
  L11_2 = uCongratVO
  L10_2[1] = L11_2
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
end

_SpawnCar = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = 0
  CarsMissed = L1_2
  L1_2 = MainTimerPause
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = MainTimerPause
    L1_2(L2_2)
  end
  L1_2 = MainTimer
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = MainTimer
    L1_2(L2_2)
  end
  L1_2 = _FixTimers
  L2_2 = A0_2
  L1_2(L2_2)
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
  end
  
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  MainTimerPause = L1_2
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.SetSlotToText
  L3_2 = {}
  L3_2.nSlot = 2
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
    L0_3 = A0_2
    L0_3 = L0_3.CourseTimer
    L1_3 = L0_3
    L0_3 = L0_3.Resume
    L0_3(L1_3)
    L0_3 = Hud
    L0_3 = L0_3.ObjectiveTray
    L1_3 = L0_3
    L0_3 = L0_3.ClearSlot
    L2_3 = {}
    L2_3.vPlayer = nil
    L2_3.nSlot = 2
    L0_3(L1_3, L2_3)
  end
  
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  MainTimer = L1_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = uRecurse
  L1_2(L2_2)
  L1_2 = NumCars
  if L1_2 == 0 then
    L1_2 = _MovetoGL
    L2_2 = A0_2
    L1_2(L2_2)
  else
    L1_2 = _SpawnCar
    L2_2 = A0_2
    L1_2(L2_2)
  end
end

_CarHit = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = MrxMusic
  L2_2 = L2_2.PlaySpecialMusic
  L3_2 = "mu_mission_pmccon031_01"
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
    L1_3 = "mu_mission_pmccon031_02"
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
    L1_3 = "mu_mission_pmccon031_01"
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
  L0_2 = Object
  L0_2 = L0_2.SetInfiniteAmmo
  L1_2 = uCharacter
  L2_2 = true
  L0_2(L1_2, L2_2)
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

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  L3_2 = MrxShootingGallery
  L3_2 = L3_2.RemoveWeapons
  L4_2 = Player
  L4_2 = L4_2.GetLocalCharacter
  L4_2 = L4_2()
  L3_2 = L3_2(L4_2)
  tWeapons = L3_2
end

_SetupBorderWeapons = L0_1

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

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = bDamageWarning
  if L0_2 == false then
    L0_2 = true
    bDamageWarning = L0_2
    L0_2 = MrxVoSequence
    L0_2 = L0_2.Start
    L1_2 = {}
    L2_2 = "Fiona-In-Mission-MinorContract-Pmc31-19"
    L1_2[1] = L2_2
    L0_2(L1_2)
  end
end

DamageWarningVO = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = A1_2 - 5
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
  L6_2 = A1_2 - 15
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
  L6_2 = A1_2 - 30
  L5_2[1] = L6_2
  L6_2 = MrxVoSequence
  L6_2 = L6_2.Start
  L7_2 = {}
  L8_2 = "Fiona-In-Mission-MinorContract-Pmc11-01"
  L7_2[1] = L8_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  uCountdown30 = L2_2
end

_CountDownVOSetup = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = A0_2.CourseTimer
  L2_2 = L1_2
  L1_2 = L1_2.GetTime
  L1_2 = L1_2(L2_2)
  TimeLeft = L1_2
  L1_2 = TimeLeft
  L1_2 = L1_2 + 5
  TimeLeft = L1_2
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
    L5_2 = L5_2 - 5
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
    L5_2 = L5_2 - 15
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
    L5_2 = L5_2 - 30
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
end

_FixTimers = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = A0_2.CourseTimer
  L2_2 = L1_2
  L1_2 = L1_2.Pause
  L1_2(L2_2)
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
  L1_2 = oGrenadeObj
  if L1_2 then
    L1_2 = oGrenadeObj
    L1_2 = L1_2.Cancel
    L2_2 = oGrenadeObj
    L1_2(L2_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[PmcCon031.Terms.CancelTime]"
  L1_2(L2_2, L3_2)
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
  L4_2 = {}
  L5_2 = Cancel
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
end

TimeUp = L0_1

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
  L2_2 = "PmcCon031"
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
  L2_2 = "PmcCon031"
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
  L2_2 = _evClientJoinedPMC031
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = _evMoveWeapons
  L1_2(L2_2)
  L1_2 = tCarsToDelete
  if L1_2 then
    L1_2 = ipairs
    L2_2 = tCarsToDelete
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    for L4_2, L5_2 in L1_2, L2_2, L3_2 do
      if L5_2 then
        L6_2 = Object
        L6_2 = L6_2.Remove
        L7_2 = L5_2
        L6_2(L7_2)
      end
    end
  end
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
  L1_2 = MrxLayerManager
  L1_2 = L1_2.MarkForRemoval
  L2_2 = "Vz_State_PmcCon031"
  L1_2(L2_2)
  L1_2 = Hud
  L1_2 = L1_2.SupportMenu
  L2_2 = L1_2
  L1_2 = L1_2.SetShootingGalleryMode
  L3_2 = {}
  L3_2.bEnable = false
  L1_2(L2_2, L3_2)
  L1_2 = uTempObj
  if L1_2 then
    L1_2 = uTempObj
    L1_2 = L1_2.Cancel
    L2_2 = uTempObj
    L1_2(L2_2)
  end
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
  L1_2 = MrxLayerManager
  L1_2 = L1_2.MarkForAddition
  L2_2 = "vz_state_pmc"
  L1_2(L2_2)
  L1_2 = A0_2.CourseTimer
  L2_2 = L1_2
  L1_2 = L1_2.Stop
  L1_2(L2_2)
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
