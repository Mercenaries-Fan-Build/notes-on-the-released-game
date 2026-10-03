local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = import
L1_1 = "DangerousBuilding"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)
L0_1 = 0
NETEVENT_CLIENTSETUP = L0_1
L0_1 = 1
NETEVENT_CLIENTSETUP2 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = 20
  nGoods = L1_2
  L1_2 = 20
  nGoodCopy = L1_2
  L1_2 = false
  bClientwasIn = L1_2
  L1_2 = 20
  nGoods1 = L1_2
  L1_2 = 0
  nGoods2 = L1_2
  L1_2 = 500
  nCargoValue = L1_2
  L1_2 = 0
  nGoodsDelivered = L1_2
  L1_2 = false
  bPursuitStarted = L1_2
  L1_2 = false
  nPlayedVO1 = L1_2
  L1_2 = false
  nPlayedVO2 = L1_2
  L1_2 = false
  nPlayedVO3 = L1_2
  L1_2 = false
  nPlayedVO4 = L1_2
  L1_2 = false
  nPlayedVO5 = L1_2
  L1_2 = false
  nPlayedVO6 = L1_2
  L1_2 = {}
  L2_2 = "GunPickup"
  L1_2[1] = L2_2
  tPickups = L1_2
  L1_2 = Player
  L1_2 = L1_2.IsCoopMultiplayer
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = SetupMPGame
    L2_2 = A0_2
    L1_2(L2_2)
  end
  L1_2 = MrxFactionManager
  L1_2 = L1_2.DisableReporting
  L2_2 = true
  L1_2(L2_2)
  L1_2 = DangerousBuilding
  L1_2 = L1_2.SetRarity
  L2_2 = "all"
  L3_2 = "never"
  L1_2(L2_2, L3_2)
  L1_2 = Vehicle
  L1_2 = L1_2.Usable
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "stager"
  L2_2 = L2_2(L3_2)
  L3_2 = false
  L1_2(L2_2, L3_2)
  L1_2 = Net
  L1_2 = L1_2.SendCustomEvent
  L2_2 = "OilCon020"
  L3_2 = NETEVENT_CLIENTSETUP
  L4_2 = {}
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = {}
  L2_2 = "Fiona-In-Mission-Contract-Oil020-27"
  L3_2 = {}
  L3_2.mattias = "Mattias-In-Mission-Contract-Oil020-28"
  L3_2.jennifer = "Jennifer-In-Mission-Contract-Oil020-29"
  L3_2.chris = "Chris-In-Mission-Contract-Oil020-30"
  L4_2 = "Fiona-In-Mission-Contract-Oil020-31"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  tInitialVOTable = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "OilCon002: deliver guns to the Oil HQ"
  L3_2.sModuleName = "MrxTaskObjectiveEnterVehicle"
  L4_2 = tPickups
  L3_2.vTgtInclude = L4_2
  L4_2 = tInitialVOTable
  L3_2.vVoSeqOnAdd = L4_2
  L3_2.nQuota = 1
  L3_2.sDspShortDesc = "[OilCon020.Objectives.001]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = ObjDeliverGoods
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.Cancel
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnCancel = L4_2
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "GunPickup"
  L6_2 = L6_2(L7_2)
  L7_2 = "<"
  L8_2 = 40
  L9_2 = false
  L10_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L5_2 = StartCargoCheck
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "GunPickup"
  L6_2 = L6_2(L7_2)
  L7_2 = "<"
  L8_2 = 80
  L9_2 = false
  L10_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L5_2 = SpottedTruck
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "GunPickup"
  L6_2 = L6_2(L7_2)
  L7_2 = "<"
  L8_2 = 120
  L9_2 = false
  L10_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L5_2 = GPSTuteDone
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "loc_VehDisTalk"
  L6_2 = L6_2(L7_2)
  L7_2 = "> "
  L8_2 = 85
  L9_2 = false
  L10_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L5_2 = GPSTuteStart
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "GunPickup"
  L6_2 = L6_2(L7_2)
  L7_2 = "<"
  L8_2 = 7
  L9_2 = false
  L10_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L5_2 = AIReact
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreatePersistentEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 2
  L4_2[1] = L5_2
  L5_2 = CheckGoodsLost
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  eCheckGuns = L1_2
end

StartCargoCheck = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Oil020-37"
  L4_2 = {}
  L5_2 = OpenPDA
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = 1
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
end

GPSTuteStart = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = eOpenPDA
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = eOpenPDA
    L2_2(L3_2)
  end
  L2_2 = eFionaFirstOpen
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = eFionaFirstOpen
    L2_2(L3_2)
  end
  L2_2 = eClearBeacon
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = eClearBeacon
    L2_2(L3_2)
  end
  L2_2 = eFionaNO
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = eFionaNO
    L2_2(L3_2)
  end
  L2_2 = eFionaOK
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = eFionaOK
    L2_2(L3_2)
  end
  L2_2 = eSetBeacon
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = eSetBeacon
    L2_2(L3_2)
  end
  L2_2 = eSetAgain
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = eSetAgain
    L2_2(L3_2)
  end
  if A1_2 == 2 then
    L2_2 = DoTheNag
    L3_2 = A0_2
    L2_2(L3_2)
  else
    L3_2 = A0_2
    L2_2 = A0_2._CreateEvent
    L4_2 = Event
    L4_2 = L4_2.TimerRelative
    L5_2 = {}
    L6_2 = 5
    L5_2[1] = L6_2
    L6_2 = DoTheNag
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
    eGPSnag = L2_2
  end
  L2_2 = MrxTutorialManager
  L2_2 = L2_2.ShowMessage
  L3_2 = "[OilCon020.Objectives.PDATut]"
  L4_2 = false
  L5_2 = "OilCon020"
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = Pda
  L2_2 = L2_2.Map
  L3_2 = L2_2
  L2_2 = L2_2.SetBeaconTutorialMode
  L4_2 = {}
  L4_2.bEnable = true
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ScriptEvent
  L5_2 = {}
  L6_2 = "PDA Open"
  
  function L7_2(A0_3)
    local L1_3, L2_3
    L1_3 = Player
    L1_3 = L1_3.GetLocalPlayer
    L1_3 = L1_3()
    L2_3 = A0_3.uPlayer
    L1_3 = L1_3 == L2_3
    return L1_3
  end
  
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = TuteInPDA
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  eOpenPDA = L2_2
end

OpenPDA = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = eGPSnag
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eGPSnag
    L1_2(L2_2)
  end
  L1_2 = {}
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Oil020-38"
  L2_2[1] = L3_2
  L3_2 = {}
  L4_2 = "Fiona-In-Mission-Contract-Oil020-39"
  L3_2[1] = L4_2
  L4_2 = {}
  L5_2 = "Fiona-In-Mission-Contract-Oil020-40"
  L4_2[1] = L5_2
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L2_2 = MrxUtil
  L2_2 = L2_2.GetRandomTableElement
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  L3_2 = MrxVoSequence
  L3_2 = L3_2.Start
  L4_2 = {}
  L5_2 = L2_2
  L4_2[1] = L5_2
  L3_2(L4_2)
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = 9
  L6_2[1] = L7_2
  L7_2 = DoTheNag
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  eGPSnag = L3_2
end

DoTheNag = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = eGPSnag
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eGPSnag
    L1_2(L2_2)
  end
  L1_2 = eClosePDA
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eClosePDA
    L1_2(L2_2)
  end
  L1_2 = eFionaFirstOpen
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eFionaFirstOpen
    L1_2(L2_2)
  end
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.HideMessage
  L2_2 = false
  L3_2 = "OilCon020"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 0.5
  L6_2 = true
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = {}
  L7_2 = "Fiona-In-Mission-Contract-Oil020-43"
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  eFionaFirstOpen = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "GPS Beacon Set"
  L6_2 = ValidationFunction
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = BeaconUsed
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = tBeaconData
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  eSetBeacon = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "PDA Close"
  
  function L6_2(A0_3)
    local L1_3, L2_3
    L1_3 = uPlayer
    L2_3 = A0_3[1]
    L1_3 = L1_3 == L2_3
    return L1_3
  end
  
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = OpenPDA
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = 2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  eClosePDA = L1_2
end

TuteInPDA = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = true
  return L1_2
end

ValidationFunction = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = eFionaFirstOpen
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = eFionaFirstOpen
    L2_2(L3_2)
  end
  L2_2 = A1_2.nX
  L3_2 = A1_2.nY
  if 2675 <= L2_2 and L2_2 <= 2825 and L3_2 <= -350 and -500 <= L3_2 then
    L4_2 = eFionaFirstOpen
    if L4_2 then
      L4_2 = Event
      L4_2 = L4_2.Delete
      L5_2 = eFionaFirstOpen
      L4_2(L5_2)
    end
    L4_2 = eFionaNO
    if L4_2 then
      L4_2 = Event
      L4_2 = L4_2.Delete
      L5_2 = eFionaNO
      L4_2(L5_2)
    end
    L4_2 = eFionaOK
    if L4_2 then
      L4_2 = Event
      L4_2 = L4_2.Delete
      L5_2 = eFionaOK
      L4_2(L5_2)
    end
    L4_2 = MrxVoSequence
    L4_2 = L4_2.Start
    L5_2 = {}
    L6_2 = "Fiona-In-Mission-Contract-Oil020-46"
    L5_2[1] = L6_2
    L4_2(L5_2)
    L4_2 = eClosePDA
    if L4_2 then
      L4_2 = Event
      L4_2 = L4_2.Delete
      L5_2 = eClosePDA
      L4_2(L5_2)
    end
    L4_2 = NowClosePDA
    L5_2 = A0_2
    L4_2(L5_2)
  else
    L4_2 = AskToClearBeacon
    L5_2 = A0_2
    L4_2(L5_2)
  end
end

BeaconUsed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = eFionaOK
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eFionaOK
    L1_2(L2_2)
  end
  L1_2 = eFionaNO
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eFionaNO
    L1_2(L2_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "GPS Beacon Cleared"
  L6_2 = ValidationFunction
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = BeaconCleared
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = tBeaconClearData
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  eClearBeacon = L1_2
  L1_2 = {}
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Oil020-44"
  L2_2[1] = L3_2
  L3_2 = {}
  L4_2 = "Fiona-In-Mission-Contract-Oil020-45"
  L3_2[1] = L4_2
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L2_2 = MrxUtil
  L2_2 = L2_2.GetRandomTableElement
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = 1.3
  L8_2 = true
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = MrxVoSequence
  L7_2 = L7_2.Start
  L8_2 = {}
  L9_2 = L2_2
  L8_2[1] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  eFionaNO = L3_2
end

AskToClearBeacon = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = eFionaNO
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eFionaNO
    L1_2(L2_2)
  end
  L1_2 = eFionaOK
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eFionaOK
    L1_2(L2_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "GPS Beacon Set"
  L6_2 = ValidationFunction
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = BeaconUsed
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = tBeaconData
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  eSetAgain = L1_2
  L1_2 = {}
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Oil020-41"
  L2_2[1] = L3_2
  L3_2 = {}
  L4_2 = "Fiona-In-Mission-Contract-Oil020-42"
  L3_2[1] = L4_2
  L4_2 = {}
  L5_2 = "Fiona-In-Mission-Contract-Oil020-43"
  L4_2[1] = L5_2
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
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = 1.5
  L8_2 = true
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = MrxVoSequence
  L7_2 = L7_2.Start
  L8_2 = {}
  L9_2 = L2_2
  L8_2[1] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  eFionaOK = L3_2
end

BeaconCleared = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = eClosePDA
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eClosePDA
    L1_2(L2_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "PDA Close"
  
  function L6_2(A0_3)
    local L1_3, L2_3
    L1_3 = uPlayer
    L2_3 = A0_3[1]
    L1_3 = L1_3 == L2_3
    return L1_3
  end
  
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = GPSTuteDone
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

NowClosePDA = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = eFionaNO
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eFionaNO
    L1_2(L2_2)
  end
  L1_2 = eFionaFirstOpen
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eFionaFirstOpen
    L1_2(L2_2)
  end
  L1_2 = eFionaOK
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eFionaOK
    L1_2(L2_2)
  end
  L1_2 = eSetBeacon
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eSetBeacon
    L1_2(L2_2)
  end
  L1_2 = eClearBeacon
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eClearBeacon
    L1_2(L2_2)
  end
  L1_2 = eClosePDA
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eClosePDA
    L1_2(L2_2)
  end
  L1_2 = eOpenPDA
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eOpenPDA
    L1_2(L2_2)
  end
  L1_2 = eGPSnag
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eGPSnag
    L1_2(L2_2)
  end
  L1_2 = eSetAgain
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eSetAgain
    L1_2(L2_2)
  end
  L1_2 = Pda
  L1_2 = L1_2.Map
  L2_2 = L1_2
  L1_2 = L1_2.SetBeaconTutorialMode
  L3_2 = {}
  L3_2.bEnable = false
  L1_2(L2_2, L3_2)
end

GPSTuteDone = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Vz01-215"
  L4_2 = "Fiona-In-Mission-Contract-Vz01-216"
  L5_2 = "Fiona-In-Mission-Contract-Vz01-217"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L1_2(L2_2)
end

VehDisguiseTalk = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "GunPickup_2"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2 = L2_2(L3_2)
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L4_2 = Object
  L4_2 = L4_2.GetYaw
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "GunPickup_2"
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2 = L5_2(L6_2)
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L5_2 = Pg
  L5_2 = L5_2.Spawn
  L6_2 = "El Grande"
  L7_2 = L1_2
  L8_2 = L2_2
  L9_2 = L3_2
  L10_2 = L4_2
  L11_2 = true
  L12_2 = true
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  uPickupB = L5_2
  L5_2 = table
  L5_2 = L5_2.insert
  L6_2 = tPickups
  L7_2 = uPickupB
  L5_2(L6_2, L7_2)
  L5_2 = {}
  L6_2 = "vz_State_OilCon020_MPDeliverables"
  L5_2[1] = L6_2
  tLayersToAdd = L5_2
  L5_2 = MrxLayerManager
  L5_2 = L5_2.Add
  L6_2 = tLayersToAdd
  L5_2(L6_2)
  L5_2 = true
  bClientwasIn = L5_2
  L5_2 = 20
  nGoods2 = L5_2
  L5_2 = 40
  nGoodCopy = L5_2
  L6_2 = A0_2
  L5_2 = A0_2._CreateEvent
  L7_2 = Event
  L7_2 = L7_2.ObjectProximity
  L8_2 = {}
  L9_2 = Pg
  L9_2 = L9_2.GetGuidByName
  L10_2 = uPickupB
  L9_2 = L9_2(L10_2)
  L10_2 = Pg
  L10_2 = L10_2.GetGuidByName
  L11_2 = "loc_DeliverStart"
  L10_2 = L10_2(L11_2)
  L11_2 = ">"
  L12_2 = 500
  L13_2 = false
  L14_2 = false
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  L8_2[5] = L13_2
  L8_2[6] = L14_2
  L9_2 = StartPursuit
  L10_2 = {}
  L11_2 = A0_2
  L10_2[1] = L11_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  ePursuitStart2 = L5_2
  L6_2 = A0_2
  L5_2 = A0_2._CreateEvent
  L7_2 = Event
  L7_2 = L7_2.ObjectDeath
  L8_2 = {}
  L9_2 = Pg
  L9_2 = L9_2.GetGuidByName
  L10_2 = "OilCon020_endTalk"
  L9_2, L10_2, L11_2, L12_2, L13_2, L14_2 = L9_2(L10_2)
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  L8_2[5] = L13_2
  L8_2[6] = L14_2
  
  function L9_2(A0_3)
    local L1_3, L2_3, L3_3
    L2_3 = A0_3
    L1_3 = A0_3._SetCancelMessage
    L3_3 = "[PirCon003.Terms.Cancel04]"
    L1_3(L2_3, L3_3)
    L2_3 = A0_3
    L1_3 = A0_3.Cancel
    L1_3(L2_3)
  end
  
  L10_2 = {}
  L11_2 = A0_2
  L10_2[1] = L11_2
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L6_2 = A0_2
  L5_2 = A0_2._CreateEvent
  L7_2 = Event
  L7_2 = L7_2.ObjectHibernation
  L8_2 = {}
  L9_2 = Pg
  L9_2 = L9_2.GetGuidByName
  L10_2 = "OilCon020_endTalk"
  L9_2 = L9_2(L10_2)
  L10_2 = "awake"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  
  function L9_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3
    L1_3 = Ai
    L1_3 = L1_3.Goal
    L2_3 = {}
    L3_3 = Pg
    L3_3 = L3_3.GetGuidByName
    L4_3 = "OilCon020_endTalk"
    L3_3 = L3_3(L4_3)
    L2_3.AIGuid = L3_3
    L2_3.Goal = "Idle"
    L2_3.Priority = "hiPri"
    L1_3(L2_3)
  end
  
  L10_2 = {}
  L11_2 = A0_2
  L10_2[1] = L11_2
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
end

SetupMPGame = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Object
  L1_2 = L1_2.IsVisible
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "GunPickup"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  if L1_2 then
    L1_2 = MrxVoSequence
    L1_2 = L1_2.Start
    L2_2 = {}
    L3_2 = "Fiona-In-Mission-Job-Oil00-06"
    L2_2[1] = L3_2
    L1_2(L2_2)
  else
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = 3
    L4_2[1] = L5_2
    L5_2 = SpottedTruck
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  end
end

SpottedTruck = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Oil020-32"
  L4_2 = "Fiona-In-Mission-Job-Oil00-06"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
end

FionaNag = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAllCharacters
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "GunPickup"
  L6_2 = L6_2(L7_2)
  L7_2 = ">"
  L8_2 = 40
  L9_2 = false
  L10_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L5_2 = FionaNag
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  eFionaNag = L1_2
  L1_2 = Ai
  L1_2 = L1_2.Goal
  L2_2 = {}
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "BoatGunnerMan"
  L3_2 = L3_2(L4_2)
  L2_2.AIGuid = L3_2
  L2_2.Goal = "Enter"
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "GunningBoat"
  L3_2 = L3_2(L4_2)
  L2_2.Target = L3_2
  L2_2.Role = "gunner"
  L2_2.Priority = "hiPri"
  L1_2(L2_2)
  L1_2 = StageJeep
  L2_2 = A0_2
  L1_2(L2_2)
end

AIReact = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L1_2 = eFionaNag
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eFionaNag
    L1_2(L2_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 5
  L4_2[1] = L5_2
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = {}
  L7_2 = "Fiona-In-Mission-Contract-Oil020-01"
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "VZSoldier-In-Mission-Contract-Oil020-17"
  L2_2[1] = L3_2
  L1_2(L2_2)
  L1_2 = MrxMusic
  L1_2 = L1_2.PlaySpecialMusic
  L2_2 = "mu_fac_oc_kickass_01"
  L1_2(L2_2)
  L1_2 = 1
  L2_2 = 4
  L3_2 = 1
  for L4_2 = L1_2, L2_2, L3_2 do
    L5_2 = Player
    L5_2 = L5_2.GetAnyCharacter
    L5_2 = L5_2()
    L6_2 = L4_2
    L7_2 = Pg
    L7_2 = L7_2.GetGuidByName
    L8_2 = "CartelBlock_"
    L9_2 = L6_2
    L8_2 = L8_2 .. L9_2
    L7_2 = L7_2(L8_2)
    L9_2 = A0_2
    L8_2 = A0_2._CreateEvent
    L10_2 = Event
    L10_2 = L10_2.ObjectProximity
    L11_2 = {}
    L12_2 = L5_2
    L13_2 = L7_2
    L14_2 = "<"
    L15_2 = 120
    L16_2 = false
    L17_2 = false
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L11_2[3] = L14_2
    L11_2[4] = L15_2
    L11_2[5] = L16_2
    L11_2[6] = L17_2
    L12_2 = CartelBlock
    L13_2 = {}
    L14_2 = A0_2
    L15_2 = L6_2
    L13_2[1] = L14_2
    L13_2[2] = L15_2
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  end
  L1_2 = DisplayGoodsLost
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "OilCon002: Deliver goods"
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "loc_GunDrop"
  L4_2 = L4_2(L5_2)
  L3_2.vDestLoc = L4_2
  L4_2 = tPickups
  L3_2.vTgtInclude = L4_2
  L3_2.nQuota = 1
  L3_2.fDist = 15
  L3_2.bStop = true
  L3_2.bXZOnly = true
  L3_2.sDspShortDesc = "[OilCon020.Objectives.002]"
  
  function L4_2()
    local L0_3, L1_3
    L0_3 = bClientwasIn
    if L0_3 then
      L0_3 = ActivateDelivered
      L1_3 = A0_2
      L0_3(L1_3)
    else
      L0_3 = CountDelivered
      L1_3 = A0_2
      L0_3(L1_3)
    end
  end
  
  L3_2.fOnComplete = L4_2
  
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = true
    nPlayedVO5 = L0_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._SetCancelMessage
    L2_3 = "[PirCon003.Terms.Cancel03]"
    L0_3(L1_3, L2_3)
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-Oil020-07"
    L3_3 = {}
    L4_3 = A0_2
    L4_3 = L4_3.Cancel
    L5_3 = {}
    L6_3 = A0_2
    L5_3[1] = L6_3
    L3_3[1] = L4_3
    L3_3[2] = L5_3
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L0_3(L1_3)
  end
  
  L3_2.fOnCancel = L4_2
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 18
  L4_2[1] = L5_2
  L5_2 = NowDriveVO
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "GunPickup"
  L5_2 = L5_2(L6_2)
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "loc_DeliverStart"
  L6_2 = L6_2(L7_2)
  L7_2 = ">"
  L8_2 = 550
  L9_2 = false
  L10_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L5_2 = StartPursuit
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  ePursuitStart = L1_2
end

ObjDeliverGoods = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Object
  L1_2 = L1_2.IsPlayerControlled
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "GunPickup"
  L2_2, L3_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 then
    L1_2 = MrxVoSequence
    L1_2 = L1_2.Start
    L2_2 = {}
    L3_2 = "Fiona-In-Mission-Job-Oil00-07"
    L2_2[1] = L3_2
    L1_2(L2_2)
  end
end

NowDriveVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Vehicle
  L1_2 = L1_2.Usable
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "stager"
  L2_2 = L2_2(L3_2)
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "stager"
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L2_2 = Vehicle
    L2_2 = L2_2.GetDriver
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    uStageJeepDriver = L2_2
    L2_2 = uStageJeepDriver
    if L2_2 then
      L2_2 = Object
      L2_2 = L2_2.IsPlayerControlled
      L3_2 = L1_2
      L2_2 = L2_2(L3_2)
      if not L2_2 then
        L2_2 = Ai
        L2_2 = L2_2.Goal
        L3_2 = {}
        L4_2 = uStageJeepDriver
        L3_2.AIGuid = L4_2
        L3_2.Goal = "PathMove"
        L4_2 = Pg
        L4_2 = L4_2.GetGuidByName
        L5_2 = "Pa_stager"
        L4_2 = L4_2(L5_2)
        L3_2.Target = L4_2
        L3_2.Priority = "hiPri"
        L2_2(L3_2)
    end
    else
      L2_2 = Object
      L2_2 = L2_2.GetPosition
      L3_2 = Pg
      L3_2 = L3_2.GetGuidByName
      L4_2 = "stager"
      L3_2, L4_2, L5_2, L6_2, L7_2 = L3_2(L4_2)
      L2_2, L3_2, L4_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
      z = L4_2
      y = L3_2
      x = L2_2
      L2_2 = Pg
      L2_2 = L2_2.FastCollectHumans
      L3_2 = x
      L4_2 = y
      L5_2 = z
      L6_2 = 10
      L7_2 = "VZ"
      L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
      tStillAlive = L2_2
      L2_2 = table
      L2_2 = L2_2.getn
      L3_2 = tStillAlive
      L2_2 = L2_2(L3_2)
      nStillAlive = L2_2
      L2_2 = nStillAlive
      if 0 < L2_2 then
        L2_2 = Ai
        L2_2 = L2_2.Goal
        L3_2 = {}
        L4_2 = tStillAlive
        L4_2 = L4_2[1]
        L3_2.AIGuid = L4_2
        L3_2.Goal = "Enter"
        L4_2 = Pg
        L4_2 = L4_2.GetGuidByName
        L5_2 = "stager"
        L4_2 = L4_2(L5_2)
        L3_2.Target = L4_2
        L3_2.Priority = "hiPri"
        L4_2 = StageJeep
        L3_2.Callback = L4_2
        L4_2 = {}
        L5_2 = A0_2
        L4_2[1] = L5_2
        L3_2.CallbackData = L4_2
        L2_2(L3_2)
      end
    end
  end
end

StageJeep = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = bPursuitStarted
  if not L1_2 then
    L1_2 = true
    bPursuitStarted = L1_2
    L1_2 = MrxVoSequence
    L1_2 = L1_2.Start
    L2_2 = {}
    L3_2 = "Fiona-In-Mission-Contract-Oil020-02"
    L2_2[1] = L3_2
    L1_2(L2_2)
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = 10
    L4_2[1] = L5_2
    L5_2 = MrxVoSequence
    L5_2 = L5_2.Start
    L6_2 = {}
    L7_2 = "Fiona-In-Mission-Contract-Oil020-11"
    L6_2[1] = L7_2
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
    L1_2 = {}
    L2_2 = {}
    L3_2 = "Driving"
    L4_2 = {}
    L5_2 = {}
    L6_2 = "Car"
    L7_2 = "M151 .50Cal (VZ) (DriverGunner)"
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
    L8_2 = "M151 .50Cal (VZ) (DriverGunner)"
    L9_2 = 1
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L5_2[1] = L6_2
    L6_2 = {}
    L7_2 = {}
    L8_2 = "Car"
    L9_2 = 4
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
    L9_2 = "M151 .50Cal (VZ) (DriverGunner)"
    L10_2 = 1
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L6_2[1] = L7_2
    L7_2 = {}
    L8_2 = {}
    L9_2 = "Car"
    L10_2 = 2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L7_2[1] = L8_2
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L4_2[3] = L7_2
    L1_2[1] = L2_2
    L1_2[2] = L3_2
    L1_2[3] = L4_2
    L2_2 = MrxFactionManager
    L2_2 = L2_2.SetCustomPursuit
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = "VZ"
    L3_2 = L3_2(L4_2)
    L4_2 = -1
    L5_2 = L1_2
    L2_2(L3_2, L4_2, L5_2)
    L3_2 = A0_2
    L2_2 = A0_2._CreateEvent
    L4_2 = Event
    L4_2 = L4_2.Boundary
    L5_2 = {}
    L6_2 = Player
    L6_2 = L6_2.GetAnyCharacter
    L6_2 = L6_2()
    L7_2 = Pg
    L7_2 = L7_2.GetGuidByName
    L8_2 = "Reg_Oil020_EndPursuit"
    L7_2 = L7_2(L8_2)
    L8_2 = "enter"
    L9_2 = false
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L5_2[4] = L9_2
    L6_2 = StopPursuit
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  end
end

StartPursuit = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = false
  bPursuitStarted = L1_2
  L1_2 = MrxFactionManager
  L1_2 = L1_2.ClearCustomPursuit
  L1_2()
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Oil020-14"
  L2_2[1] = L3_2
  L1_2(L2_2)
end

StopPursuit = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  if A1_2 == 1 then
    L2_2 = MrxVoSequence
    L2_2 = L2_2.Start
    L3_2 = {}
    L4_2 = "Fiona-In-Mission-Contract-Oil020-18"
    L3_2[1] = L4_2
    L2_2(L3_2)
  elseif A1_2 == 3 then
    L2_2 = MrxVoSequence
    L2_2 = L2_2.Start
    L3_2 = {}
    L4_2 = "Fiona-In-Mission-Contract-Oil020-13"
    L3_2[1] = L4_2
    L2_2(L3_2)
  elseif A1_2 == 5 then
    L2_2 = MrxVoSequence
    L2_2 = L2_2.Start
    L3_2 = {}
    L4_2 = "Fiona-In-Mission-Contract-Oil020-12"
    L3_2[1] = L4_2
    L2_2(L3_2)
  end
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "CartelBlock_"
  L4_2 = A1_2
  L3_2 = L3_2 .. L4_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = Vehicle
    L3_2 = L3_2.GetDriver
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L4_2 = Object
      L4_2 = L4_2.IsPlayerControlled
      L5_2 = L2_2
      L4_2 = L4_2(L5_2)
      if not L4_2 then
        L4_2 = {}
        L4_2.AIGuid = L3_2
        L4_2.Goal = "PathMove"
        L5_2 = Pg
        L5_2 = L5_2.GetGuidByName
        L6_2 = "Pa_CartelBlock_"
        L7_2 = A1_2
        L6_2 = L6_2 .. L7_2
        L5_2 = L5_2(L6_2)
        L4_2.Target = L5_2
        L4_2.Priority = "hiPri"
        L5_2 = RoadBlockStop
        L4_2.Callback = L5_2
        L5_2 = {}
        L6_2 = A0_2
        L7_2 = A1_2
        L5_2[1] = L6_2
        L5_2[2] = L7_2
        L4_2.CallbackData = L5_2
        L6_2 = A0_2
        L5_2 = A0_2._CreateEvent
        L7_2 = Event
        L7_2 = L7_2.TimerRelative
        L8_2 = {}
        L9_2 = 2
        L8_2[1] = L9_2
        L9_2 = Ai
        L9_2 = L9_2.Goal
        L10_2 = {}
        L11_2 = L4_2
        L10_2[1] = L11_2
        L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
      end
    end
  end
end

CartelBlock = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2
  if A3_2 == 0 then
    L4_2 = CartelBlock
    L5_2 = A0_2
    L6_2 = A1_2
    L4_2(L5_2, L6_2)
  else
    L4_2 = Ai
    L4_2 = L4_2.Goal
    L5_2 = {}
    L5_2.AIGuid = A2_2
    L5_2.Goal = "Stop"
    L5_2.Priority = "hiPri"
    L6_2 = NowBlockerExit
    L5_2.Callback = L6_2
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L5_2.CallbackData = L6_2
    L4_2(L5_2)
  end
end

RoadBlockStop = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  L3_2 = Ai
  L3_2 = L3_2.Goal
  L4_2 = {}
  L4_2.AIGuid = A1_2
  L4_2.Goal = "Exit"
  L4_2.Priority = "hiPri"
  L3_2(L4_2)
end

NowBlockerExit = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  if A3_2 == 0 then
    L4_2 = CartelBlock
    L5_2 = A0_2
    L6_2 = A1_2
    L4_2(L5_2, L6_2)
  else
    L4_2 = A2_2
    if L4_2 then
      L5_2 = Ai
      L5_2 = L5_2.Goal
      L6_2 = {}
      L6_2.AIGuid = L4_2
      L6_2.Goal = "MoveTo"
      L7_2 = Pg
      L7_2 = L7_2.GetGuidByName
      L8_2 = "GunPickup"
      L7_2 = L7_2(L8_2)
      L6_2.Target = L7_2
      L6_2.Force = true
      L6_2.Priority = "hiPri"
      L7_2 = BlockerChase
      L6_2.Callback = L7_2
      L7_2 = {}
      L8_2 = A0_2
      L7_2[1] = L8_2
      L6_2.CallbackData = L7_2
      L5_2(L6_2)
      L5_2 = Ai
      L5_2 = L5_2.SetHaste
      L6_2 = L4_2
      L7_2 = 1
      L5_2(L6_2, L7_2)
      L6_2 = A0_2
      L5_2 = A0_2._CreateEvent
      L7_2 = Event
      L7_2 = L7_2.TimerRelative
      L8_2 = {}
      L9_2 = 4
      L8_2[1] = L9_2
      L9_2 = BlockerChase
      L10_2 = {}
      L11_2 = A0_2
      L12_2 = A2_2
      L10_2[1] = L11_2
      L10_2[2] = L12_2
      L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
    end
  end
end

BlockerChase = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = nGoods
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "GunPickup"
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = Object
    L3_2 = L3_2.IsAlive
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L3_2 = MrxUtil
      L3_2 = L3_2.TestDistanceToAllPlayers
      L4_2 = L2_2
      L5_2 = 30
      L6_2 = false
      L7_2 = true
      L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
      if not L3_2 then
        L4_2 = A0_2
        L3_2 = A0_2._CreateEvent
        L5_2 = Event
        L5_2 = L5_2.TimerRelative
        L6_2 = {}
        L7_2 = 1
        L6_2[1] = L7_2
        
        function L7_2(A0_3)
          local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
          L1_3 = MrxUtil
          L1_3 = L1_3.TestDistanceToAllPlayers
          L2_3 = L2_2
          L3_3 = 30
          L4_3 = false
          L5_3 = true
          L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3)
          if not L1_3 then
            L1_3 = Object
            L1_3 = L1_3.GetHardpointPosition
            L2_3 = L2_2
            L3_3 = "HP_Truckbed"
            L1_3, L2_3, L3_3 = L1_3(L2_3, L3_3)
            if L1_3 and L2_3 and L3_3 then
              L4_3 = Pg
              L4_3 = L4_3.GetObjectsInArea
              L5_3 = L1_3
              L6_3 = L2_3
              L7_3 = L3_3
              L8_3 = 1
              L9_3 = "OilCon020gun"
              L4_3 = L4_3(L5_3, L6_3, L7_3, L8_3, L9_3)
              L5_3 = table
              L5_3 = L5_3.getn
              L6_3 = L4_3
              L5_3 = L5_3(L6_3)
              nGoods1 = L5_3
            end
          end
        end
        
        L8_2 = {}
        L9_2 = A0_2
        L8_2[1] = L9_2
        L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
      end
    else
      L3_2 = 0
      nGoods1 = L3_2
    end
  end
  L3_2 = bClientwasIn
  if L3_2 then
    L3_2 = uPickupB
    if L3_2 then
      L4_2 = Object
      L4_2 = L4_2.IsAlive
      L5_2 = L3_2
      L4_2 = L4_2(L5_2)
      if L4_2 then
        L4_2 = MrxUtil
        L4_2 = L4_2.TestDistanceToAllPlayers
        L5_2 = L3_2
        L6_2 = 30
        L7_2 = false
        L8_2 = true
        L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
        if not L4_2 then
          L5_2 = A0_2
          L4_2 = A0_2._CreateEvent
          L6_2 = Event
          L6_2 = L6_2.TimerRelative
          L7_2 = {}
          L8_2 = 1
          L7_2[1] = L8_2
          
          function L8_2(A0_3)
            local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
            L1_3 = MrxUtil
            L1_3 = L1_3.TestDistanceToAllPlayers
            L2_3 = L3_2
            L3_3 = 30
            L4_3 = false
            L5_3 = true
            L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3)
            if not L1_3 then
              L1_3 = Object
              L1_3 = L1_3.GetHardpointPosition
              L2_3 = L3_2
              L3_3 = "HP_Truckbed"
              L1_3, L2_3, L3_3 = L1_3(L2_3, L3_3)
              if L1_3 and L2_3 and L3_3 then
                L4_3 = Pg
                L4_3 = L4_3.GetObjectsInArea
                L5_3 = L1_3
                L6_3 = L2_3
                L7_3 = L3_3
                L8_3 = 1
                L9_3 = "OilCon020gun"
                L4_3 = L4_3(L5_3, L6_3, L7_3, L8_3, L9_3)
                L5_3 = table
                L5_3 = L5_3.getn
                L6_3 = L4_3
                L5_3 = L5_3(L6_3)
                nGoods2 = L5_3
              end
            end
          end
          
          L9_2 = {}
          L10_2 = A0_2
          L9_2[1] = L10_2
          L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
        end
      else
        L4_2 = 0
        nGoods2 = L4_2
      end
    end
  end
  L3_2 = nGoods1
  L4_2 = nGoods2
  L3_2 = L3_2 + L4_2
  nGoods = L3_2
  L3_2 = nGoods
  if L1_2 > L3_2 then
    L3_2 = DisplayGoodsLost
    L4_2 = A0_2
    L3_2(L4_2)
  end
end

CheckGoodsLost = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = nGoods
  L2_2 = nCargoValue
  L1_2 = L1_2 * L2_2
  nGunMoney = L1_2
  L1_2 = [[
[OilCon020.Objectives.hudCash]: 
 ]]
  L2_2 = MrxUtil
  L2_2 = L2_2.FormatMoney
  L3_2 = nGunMoney
  L2_2 = L2_2(L3_2)
  L1_2 = L1_2 .. L2_2
  sHudText = L1_2
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.SetSlotToText
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 1
  L4_2 = sHudText
  L3_2.sText = L4_2
  L1_2(L2_2, L3_2)
  L1_2 = nGoods
  if L1_2 == 35 then
    L1_2 = nPlayedVO1
    if not L1_2 then
      L1_2 = true
      nPlayedVO1 = L1_2
      L2_2 = A0_2
      L1_2 = A0_2._CreateEvent
      L3_2 = Event
      L3_2 = L3_2.TimerRelative
      L4_2 = {}
      L5_2 = 1
      L4_2[1] = L5_2
      L5_2 = A0_2._PlayVo
      L6_2 = {}
      L7_2 = A0_2
      L8_2 = 0
      L9_2 = "Fiona-In-Mission-Job-Oil00-08"
      L6_2[1] = L7_2
      L6_2[2] = L8_2
      L6_2[3] = L9_2
      L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  end
  else
    L1_2 = nGoods
    if L1_2 == 25 then
      L1_2 = nPlayedVO2
      if not L1_2 then
        L1_2 = true
        nPlayedVO2 = L1_2
        L2_2 = A0_2
        L1_2 = A0_2._CreateEvent
        L3_2 = Event
        L3_2 = L3_2.TimerRelative
        L4_2 = {}
        L5_2 = 1
        L4_2[1] = L5_2
        L5_2 = A0_2._PlayVo
        L6_2 = {}
        L7_2 = A0_2
        L8_2 = 0
        L9_2 = "Fiona-In-Mission-Job-Oil00-09"
        L6_2[1] = L7_2
        L6_2[2] = L8_2
        L6_2[3] = L9_2
        L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
    end
    else
      L1_2 = nGoods
      if L1_2 == 18 then
        L1_2 = nPlayedVO6
        if not L1_2 then
          L1_2 = true
          nPlayedVO6 = L1_2
          L1_2 = MrxVoSequence
          L1_2 = L1_2.Start
          L2_2 = {}
          L3_2 = "Fiona-In-Mission-Contract-Oil020-34"
          L2_2[1] = L3_2
          L1_2(L2_2)
      end
      else
        L1_2 = nGoods
        if L1_2 == 12 then
          L1_2 = nPlayedVO3
          if not L1_2 then
            L1_2 = true
            nPlayedVO3 = L1_2
            L2_2 = A0_2
            L1_2 = A0_2._CreateEvent
            L3_2 = Event
            L3_2 = L3_2.TimerRelative
            L4_2 = {}
            L5_2 = 1
            L4_2[1] = L5_2
            L5_2 = A0_2._PlayVo
            L6_2 = {}
            L7_2 = A0_2
            L8_2 = 0
            L9_2 = "Fiona-In-Mission-Job-Oil00-11"
            L6_2[1] = L7_2
            L6_2[2] = L8_2
            L6_2[3] = L9_2
            L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
        end
        else
          L1_2 = nGoods
          if L1_2 == 9 then
            L1_2 = nPlayedVO4
            if not L1_2 then
              L1_2 = true
              nPlayedVO4 = L1_2
              L1_2 = MrxVoSequence
              L1_2 = L1_2.Start
              L2_2 = {}
              L3_2 = "Fiona-In-Mission-Contract-Oil020-06"
              L2_2[1] = L3_2
              L1_2(L2_2)
            end
          end
        end
      end
    end
  end
  L1_2 = nGoods
  if L1_2 == 0 then
    L1_2 = nPlayedVO5
    if not L1_2 then
      L1_2 = true
      nPlayedVO5 = L1_2
      L2_2 = A0_2
      L1_2 = A0_2._SetCancelMessage
      L3_2 = "[OilCon020.Terms.Cancel02]"
      L1_2(L2_2, L3_2)
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = "Fiona-In-Mission-Job-Oil00-12"
      L2_2[1] = L3_2
      L1_2(L2_2)
      L2_2 = A0_2
      L1_2 = A0_2._CreateEvent
      L3_2 = Event
      L3_2 = L3_2.TimerRelative
      L4_2 = {}
      L5_2 = 3
      L4_2[1] = L5_2
      L5_2 = A0_2.Cancel
      L6_2 = {}
      L7_2 = A0_2
      L6_2[1] = L7_2
      L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
    end
  end
end

DisplayGoodsLost = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "OilCon020 End"
  L3_2.sModuleName = "MrxTaskObjectiveAction"
  L3_2.vTgtInclude = "OilCon020_endTalk"
  L3_2.sDspShortDesc = "[OilCon020.Objectives.003]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = CountDelivered
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.Cancel
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnCancel = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  oEndTalk = L1_2
end

ActivateDelivered = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = eCheckGuns
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eCheckGuns
    L1_2(L2_2)
  end
  L1_2 = true
  nPlayedVO1 = L1_2
  L1_2 = true
  nPlayedVO2 = L1_2
  L1_2 = true
  nPlayedVO3 = L1_2
  L1_2 = true
  nPlayedVO4 = L1_2
  L1_2 = true
  nPlayedVO5 = L1_2
  L1_2 = true
  nPlayedVO6 = L1_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "loc_GunDrop"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L2_2(L3_2)
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetObjectsInArea
  L6_2 = L1_2
  L7_2 = L2_2
  L8_2 = L3_2
  L9_2 = 25
  L10_2 = "OilCon020gun"
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L6_2 = table
  L6_2 = L6_2.getn
  L7_2 = L5_2
  L6_2 = L6_2(L7_2)
  nGoodsDelivered = L6_2
  L6_2 = nGoodsDelivered
  L7_2 = nCargoValue
  L6_2 = L6_2 * L7_2
  nTotalcash = L6_2
  L6_2 = Net
  L6_2 = L6_2.IsActive
  L6_2 = L6_2()
  if L6_2 then
    L6_2 = nTotalcash
    L6_2 = L6_2 / 2
    L8_2 = A0_2
    L7_2 = A0_2._SetPlayer1Bonus
    L9_2 = L6_2
    L7_2(L8_2, L9_2)
    L8_2 = A0_2
    L7_2 = A0_2._SetPlayer2Bonus
    L9_2 = L6_2
    L7_2(L8_2, L9_2)
  else
    L7_2 = A0_2
    L6_2 = A0_2._SetPlayer1Bonus
    L8_2 = nTotalcash
    L6_2(L7_2, L8_2)
  end
  L7_2 = A0_2
  L6_2 = A0_2._CreateEvent
  L8_2 = Event
  L8_2 = L8_2.TimerRelative
  L9_2 = {}
  L10_2 = 2
  L9_2[1] = L10_2
  L10_2 = IntercomResponse
  L11_2 = {}
  L12_2 = A0_2
  L11_2[1] = L12_2
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "OilCon020_takesTruck"
  L6_2 = L6_2(L7_2)
  if L6_2 then
    L7_2 = Object
    L7_2 = L7_2.IsAlive
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    if L7_2 then
      L7_2 = Object
      L7_2 = L7_2.IsPlayerControlled
      L8_2 = Pg
      L8_2 = L8_2.GetGuidByName
      L9_2 = "GunPickup"
      L8_2, L9_2, L10_2, L11_2, L12_2 = L8_2(L9_2)
      L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
      if not L7_2 then
        L7_2 = Ai
        L7_2 = L7_2.Goal
        L8_2 = {}
        L8_2.AIGuid = L6_2
        L8_2.Goal = "Enter"
        L9_2 = Pg
        L9_2 = L9_2.GetGuidByName
        L10_2 = "GunPickup"
        L9_2 = L9_2(L10_2)
        L8_2.Target = L9_2
        L8_2.Role = "driver"
        L8_2.Force = true
        L8_2.Priority = "hiPri"
        L9_2 = OCtakesTruck
        L8_2.Callback = L9_2
        L9_2 = {}
        L10_2 = A0_2
        L9_2[1] = L10_2
        L8_2.CallbackData = L9_2
        L7_2(L8_2)
      end
    end
  end
end

CountDelivered = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  if A2_2 == 1 then
    L3_2 = Object
    L3_2 = L3_2.IsPlayerControlled
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "GunPickup"
    L4_2, L5_2, L6_2 = L4_2(L5_2)
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    if not L3_2 then
      L3_2 = Ai
      L3_2 = L3_2.Goal
      L4_2 = {}
      L4_2.AIGuid = A1_2
      L4_2.Goal = "PathMove"
      L5_2 = Pg
      L5_2 = L5_2.GetGuidByName
      L6_2 = "Pa_OCTakes"
      L5_2 = L5_2(L6_2)
      L4_2.Target = L5_2
      L4_2.Priority = "hiPri"
      L3_2(L4_2)
    end
  end
end

OCtakesTruck = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = nGoodsDelivered
  if 10 <= L1_2 then
    L1_2 = MrxVoSequence
    L1_2 = L1_2.Start
    L2_2 = {}
    L3_2 = "OCMerc-In-Mission-Contract-Oil020-03"
    L4_2 = "Fiona-In-Mission-Job-Oil00-13"
    L5_2 = {}
    L6_2 = A0_2.Complete
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
    L1_2(L2_2)
  else
    L1_2 = nGoodsDelivered
    if 1 <= L1_2 then
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = "OCMerc-In-Mission-Contract-Oil020-04"
      L4_2 = "Fiona-In-Mission-Job-Oil00-13"
      L5_2 = {}
      L6_2 = A0_2.Complete
      L7_2 = {}
      L8_2 = A0_2
      L7_2[1] = L8_2
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      L2_2[1] = L3_2
      L2_2[2] = L4_2
      L2_2[3] = L5_2
      L1_2(L2_2)
    else
      L2_2 = A0_2
      L1_2 = A0_2._SetCancelMessage
      L3_2 = "[OilCon020.Terms.Cancel02]"
      L1_2(L2_2, L3_2)
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = "Fiona-In-Mission-Job-Oil00-12"
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
  end
end

IntercomResponse = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2
  L4_2 = Net
  L4_2 = L4_2.SendCustomEvent
  L5_2 = "OilCon020"
  L6_2 = NETEVENT_CLIENTSETUP
  L7_2 = {}
  L4_2(L5_2, L6_2, L7_2)
end

OnPlayerJoined = L0_1

function L0_1(A0_2, A1_2)
  local L2_2
  L2_2 = NETEVENT_CLIENTSETUP
  if A0_2 == L2_2 then
  end
  L2_2 = NETEVENT_CLIENTSETUP2
  if A0_2 == L2_2 then
  end
end

NetEventCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 1
  L1_2(L2_2, L3_2)
  L1_2 = Net
  L1_2 = L1_2.SendCustomEvent
  L2_2 = "OilCon020"
  L3_2 = NETEVENT_CLIENTSETUP2
  L4_2 = {}
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Player
  L1_2 = L1_2.GetAllPlayers
  L1_2 = L1_2()
  L2_2 = ipairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = Player
    L7_2 = L7_2.GetCharacter
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    L8_2 = Human
    L8_2 = L8_2.ForceExitSeatNoSnap
    L9_2 = L7_2
    L8_2(L9_2)
  end
  L2_2 = MrxFactionManager
  L2_2 = L2_2.ClearCustomPursuit
  L2_2()
  L2_2 = MrxFactionManager
  L2_2 = L2_2.DisableReporting
  L3_2 = false
  L2_2(L3_2)
  L2_2 = MrxMusic
  L2_2 = L2_2.StopSpecialMusic
  L3_2 = "none"
  L2_2(L3_2)
  L2_2 = MrxLayerManager
  L2_2 = L2_2.Remove
  L3_2 = "vz_State_OilCon020_Deliveribles"
  L2_2(L3_2)
  L2_2 = bClientwasIn
  if L2_2 then
    L2_2 = MrxLayerManager
    L2_2 = L2_2.Remove
    L3_2 = "vz_State_OilCon020_MPDeliverables"
    L2_2(L3_2)
  end
  L2_2 = MrxTutorialManager
  L2_2 = L2_2.HideMessage
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = GPSTuteDone
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = MrxTaskContract
  L2_2 = L2_2.Cleanup
  L3_2 = A0_2
  L2_2(L3_2)
end

Cleanup = L0_1
