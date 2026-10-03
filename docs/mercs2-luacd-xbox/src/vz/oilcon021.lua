local L0_1, L1_1
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "DangerousBuilding"
L0_1(L1_1)
L0_1 = 0
NETEVENT_CLIENTSETUP = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = false
  bEarlyFind = L1_2
  L1_2 = false
  bTalked = L1_2
  L1_2 = 0
  nAlreadyHeard = L1_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Pg
  L1_2 = L1_2.LoadAsset
  L2_2 = "all_aisoldiermale_bare_upright_taunt_fb"
  L3_2 = "animation"
  L1_2(L2_2, L3_2)
  L1_2 = DangerousBuilding
  L1_2 = L1_2.SetRarity
  L2_2 = "all"
  L3_2 = "never"
  L1_2(L2_2, L3_2)
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "psych"
  L1_2 = L1_2(L2_2)
  L2_2 = Vehicle
  L2_2 = L2_2.Usable
  L3_2 = L1_2
  L4_2 = false
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 2
  L5_2[1] = L6_2
  L6_2 = KillTrucks
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L2_2 = {}
  L3_2 = {}
  L3_2.mattias = "Mattias-In-Mission-Contract-Pmc01-163"
  L3_2.jennifer = "Jennifer-In-Mission-Contract-Pmc01-164"
  L3_2.chris = "Chris-In-Mission-Contract-Pmc01-165"
  L4_2 = "Fiona-In-Mission-Contract-Pmc01-166"
  L5_2 = {}
  L5_2.mattias = "Mattias-In-Mission-Contract-Pmc01-172"
  L5_2.jennifer = "Jennifer-In-Mission-Contract-Pmc01-170"
  L5_2.chris = "Chris-In-Mission-Contract-Pmc01-171"
  L6_2 = "Fiona-In-Mission-Contract-Oil020-22"
  L7_2 = "Fiona-In-Mission-Contract-Oil020-24"
  L8_2 = "Fiona-In-Mission-Contract-Oil020-23"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L2_2[6] = L8_2
  tStartTalk = L2_2
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "OilCon021: Get the Devastator"
  L4_2.sModuleName = "MrxTaskObjectiveAction"
  L4_2.sActionLabel = "[ContextAction.Talk]"
  L5_2 = tStartTalk
  L4_2.vVoSeqOnAdd = L5_2
  L4_2.vTgtInclude = "MailTalk"
  L4_2.sDspShortDesc = "[OilCon021.Objectives.001]"
  L5_2 = {}
  L6_2 = {}
  L7_2 = SetupDeliverTruck
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnPartComplete = L5_2
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._SetCancelMessage
    L2_3 = "[GurCon003.Terms.Cancel03]"
    L0_3(L1_3, L2_3)
    L0_3 = A0_2
    L0_3 = L0_3.Cancel
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L4_2.fOnCancel = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  oTalk = L2_2
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectDeath
  L5_2 = {}
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "MailTruck"
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L6_2(L7_2)
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = TruckLost
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  eDevasDestroyed = L2_2
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ObjectPhysicsEvent
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "MailTruck"
  L5_2 = L5_2(L6_2)
  L6_2 = "VehicleSinking"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = TruckLost
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAnyCharacter
  L6_2 = L6_2()
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "MailTalk"
  L7_2 = L7_2(L8_2)
  L8_2 = "<"
  L9_2 = 60
  L10_2 = false
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = SetupContactGuy
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAnyCharacter
  L6_2 = L6_2()
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "MailTruck"
  L7_2 = L7_2(L8_2)
  L8_2 = "<"
  L9_2 = 4
  L10_2 = false
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = SpottedDevastator
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectDeath
  L5_2 = {}
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "intercom_locked"
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L6_2(L7_2)
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = DropDestroyed
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L2_2 = Net
  L2_2 = L2_2.SendCustomEvent
  L3_2 = "OilCon021"
  L4_2 = NETEVENT_CLIENTSETUP
  L5_2 = {}
  L2_2(L3_2, L4_2, L5_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[OilCon020.Terms.Cancel03]"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.Cancel
  L1_2(L2_2)
end

DropDestroyed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 1
  L4_2[1] = L5_2
  L5_2 = CheckForHostile
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  eHostileCheck = L1_2
  L1_2 = Ai
  L1_2 = L1_2.GetFeeling
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "MailTalk"
  L2_2 = L2_2(L3_2)
  L3_2 = Player
  L3_2 = L3_2.GetLocalCharacter
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L3_2()
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  if L1_2 and L1_2 <= -33 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = eHostileCheck
    L2_2(L3_2)
    L2_2 = Ai
    L2_2 = L2_2.Role
    L3_2 = {}
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "MailTalk"
    L4_2 = L4_2(L5_2)
    L3_2.AIGuid = L4_2
    L3_2.Role = "Idle"
    L3_2.Priority = "loPri"
    L2_2(L3_2)
    L2_2 = true
    bEarlyFind = L2_2
    L3_2 = A0_2
    L2_2 = A0_2._SetCancelMessage
    L4_2 = "[OilCon021.Terms.Cancel02]"
    L2_2(L3_2, L4_2)
    L2_2 = MrxVoSequence
    L2_2 = L2_2.Start
    L3_2 = {}
    L4_2 = "Fiona.fio_g73"
    L5_2 = {}
    L6_2 = A0_2.Cancel
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L2_2(L3_2)
  end
end

CheckForHostile = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = CheckForHostile
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Ai
  L1_2 = L1_2.SetInfractionMultiplier
  L2_2 = GetGuidByName
  L3_2 = "OC"
  L2_2 = L2_2(L3_2)
  L3_2 = 0.1
  L1_2(L2_2, L3_2)
  L1_2 = {}
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "MailTalk"
  L2_2 = L2_2(L3_2)
  L1_2.AIGuid = L2_2
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "UPseat"
  L2_2 = L2_2(L3_2)
  L1_2.Target = L2_2
  L1_2.Goal = "Enter"
  L1_2.Priority = "hiPri"
  L2_2 = Seated
  L1_2.Callback = L2_2
  L2_2 = {}
  L3_2 = A0_2
  L2_2[1] = L3_2
  L1_2.CallbackData = L2_2
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 2
  L5_2[1] = L6_2
  L6_2 = Ai
  L6_2 = L6_2.Goal
  L7_2 = {}
  L8_2 = L1_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

SetupContactGuy = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Ai
  L1_2 = L1_2.Goal
  L2_2 = {}
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "MailTalk"
  L3_2 = L3_2(L4_2)
  L2_2.AIGuid = L3_2
  L2_2.Goal = "Idle"
  L2_2.Priority = "hiPri"
  L1_2(L2_2)
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
  L7_2 = "MailTalk"
  L6_2 = L6_2(L7_2)
  L7_2 = "<"
  L8_2 = 4
  L9_2 = false
  L10_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L5_2 = Conversation
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

Seated = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = Ai
  L2_2 = L2_2.Goal
  L3_2 = {}
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "MailTalk"
  L4_2 = L4_2(L5_2)
  L3_2.AIGuid = L4_2
  L3_2.Goal = "Exit"
  L3_2.Priority = "hiPri"
  L3_2.Force = true
  L4_2 = KeepFacing
  L3_2.Callback = L4_2
  L4_2 = {}
  L5_2 = A0_2
  L6_2 = A1_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L3_2.CallbackData = L4_2
  L2_2(L3_2)
end

Conversation = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = Ai
  L2_2 = L2_2.Goal
  L3_2 = {}
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "MailTalk"
  L4_2 = L4_2(L5_2)
  L3_2.AIGuid = L4_2
  L4_2 = A1_2[1]
  L3_2.Target = L4_2
  L3_2.Goal = "Face"
  L3_2.Position = true
  L3_2.Priority = "hiPri"
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 4
  L5_2[1] = L6_2
  L6_2 = KeepFacing
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A1_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  eFacing = L2_2
  L2_2 = Ai
  L2_2 = L2_2.Role
  L3_2 = {}
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "MailTalk"
  L4_2 = L4_2(L5_2)
  L3_2.AIGuid = L4_2
  L3_2.Role = "Idle"
  L3_2.Priority = "hiPri"
  L2_2(L3_2)
end

KeepFacing = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = eFacing
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = eFacing
    L2_2(L3_2)
  end
  L2_2 = {}
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "MailTalk"
  L3_2 = L3_2(L4_2)
  L2_2.AIGuid = L3_2
  L2_2.Target = A1_2
  L2_2.Goal = "Face"
  L2_2.Position = true
  L2_2.Priority = "hiPri"
  L3_2 = Speak
  L2_2.Callback = L3_2
  L3_2 = {}
  L4_2 = A0_2
  L3_2[1] = L4_2
  L2_2.CallbackData = L3_2
  uFacer = L2_2
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 2
  L5_2[1] = L6_2
  L6_2 = Ai
  L6_2 = L6_2.Goal
  L7_2 = {}
  L8_2 = uFacer
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

Turn = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Ai
  L1_2 = L1_2.Goal
  L2_2 = {}
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "MailTalk"
  L3_2 = L3_2(L4_2)
  L2_2.AIGuid = L3_2
  L3_2 = Player
  L3_2 = L3_2.GetLocalCharacter
  L3_2 = L3_2()
  L2_2.Target = L3_2
  L2_2.Goal = "Speak"
  L2_2.Priority = "hiPri"
  L1_2 = L1_2(L2_2)
  uSpeak = L1_2
end

Speak = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[OilCon021.Terms.Cancel01]"
  L1_2(L2_2, L3_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Oil021-09"
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

TruckLost = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L2_2 = true
  bTalked = L2_2
  L2_2 = bEarlyFind
  if L2_2 == false then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = eEarlyEnter
    L2_2(L3_2)
    L2_2 = Turn
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
    L2_2 = Object
    L2_2 = L2_2.HasLabel
    L3_2 = A1_2
    L4_2 = "Mattias"
    L2_2 = L2_2(L3_2, L4_2)
    if L2_2 then
      L2_2 = "Mattias-In-Mission-Contract-Oil021-01"
      sTalkedVO = L2_2
    else
      L2_2 = Object
      L2_2 = L2_2.HasLabel
      L3_2 = A1_2
      L4_2 = "Jennifer"
      L2_2 = L2_2(L3_2, L4_2)
      if L2_2 then
        L2_2 = "Jennifer-In-Mission-Contract-Oil021-02"
        sTalkedVO = L2_2
      else
        L2_2 = Object
        L2_2 = L2_2.HasLabel
        L3_2 = A1_2
        L4_2 = "Chris"
        L2_2 = L2_2(L3_2, L4_2)
        if L2_2 then
          L2_2 = "Chris-In-Mission-Contract-Oil021-03"
          sTalkedVO = L2_2
        end
      end
    end
    L2_2 = MrxVoSequence
    L2_2 = L2_2.Start
    L3_2 = {}
    L4_2 = {}
    L5_2 = sTalkedVO
    L6_2 = A1_2
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L5_2 = {}
    L6_2 = "OCMerc-In-Mission-Contract-Oil021-04"
    L7_2 = Pg
    L7_2 = L7_2.GetGuidByName
    L8_2 = "MailTalk"
    L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2 = L7_2(L8_2)
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L5_2[4] = L9_2
    L5_2[5] = L10_2
    L5_2[6] = L11_2
    L5_2[7] = L12_2
    L5_2[8] = L13_2
    L5_2[9] = L14_2
    L6_2 = {}
    L7_2 = Human
    L7_2 = L7_2.DoAction
    L8_2 = {}
    L9_2 = Pg
    L9_2 = L9_2.GetGuidByName
    L10_2 = "MailTalk"
    L9_2 = L9_2(L10_2)
    L10_2 = "ExitAction"
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L7_2 = "Fiona-In-Mission-Contract-Oil020-25"
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L3_2[4] = L7_2
    L2_2(L3_2)
    L2_2 = Pg
    L2_2 = L2_2.GetGuidByName
    L3_2 = "MailTalk"
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L4_2 = A0_2
      L3_2 = A0_2._CreateEvent
      L5_2 = Event
      L5_2 = L5_2.TimerRelative
      L6_2 = {}
      L7_2 = 3.5
      L6_2[1] = L7_2
      L7_2 = Human
      L7_2 = L7_2.PlayRawAnimation
      L8_2 = {}
      L9_2 = L2_2
      L10_2 = "all_aisoldiermale_bare_upright_taunt_fb"
      L11_2 = false
      L12_2 = false
      L13_2 = 0
      L14_2 = false
      L8_2[1] = L9_2
      L8_2[2] = L10_2
      L8_2[3] = L11_2
      L8_2[4] = L12_2
      L8_2[5] = L13_2
      L8_2[6] = L14_2
      L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
    end
  end
  L2_2 = DeliverTruckObjective
  L3_2 = A0_2
  L2_2(L3_2)
end

SetupDeliverTruck = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = true
  bEarlyFind = L1_2
  L1_2 = oTalk
  L2_2 = L1_2
  L1_2 = L1_2.Configure
  L3_2 = {}
  L3_2.bDsp = false
  L1_2(L2_2, L3_2)
  L1_2 = oTalk
  L2_2 = L1_2
  L1_2 = L1_2.Complete
  L1_2(L2_2)
  L1_2 = DeliverTruckObjective
  L2_2 = A0_2
  L1_2(L2_2)
end

EarlyFind = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Ai
  L1_2 = L1_2.Role
  L2_2 = {}
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "MailTalk"
  L3_2 = L3_2(L4_2)
  L2_2.AIGuid = L3_2
  L2_2.Role = "Idle"
  L2_2.Priority = "loPri"
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = eHostileCheck
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = eDevasDestroyed
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectInSeat
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "MailTruck"
  L6_2 = L6_2(L7_2)
  L7_2 = "a"
  L8_2 = "e"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = MrxMusic
  L5_2 = L5_2.PlaySpecialMusic
  L6_2 = {}
  L7_2 = "mu_mission_oilcon021_01"
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "OilCon021: Deliver the Devastator"
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L3_2.vTgtInclude = "MailTruck"
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "loc_MailDrop"
  L4_2 = L4_2(L5_2)
  L3_2.vDestLoc = L4_2
  L3_2.fDist = 8
  L3_2.bStop = true
  L3_2.bXZOnly = true
  L3_2.sDspShortDesc = "[OilCon021.Objectives.002]"
  
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-Oil021-12"
    L3_3 = {}
    L4_3 = A0_2
    L4_3 = L4_3.Complete
    L5_3 = {}
    L6_3 = A0_2
    L5_3[1] = L6_3
    L3_3[1] = L4_3
    L3_3[2] = L5_3
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L0_3(L1_3)
  end
  
  L3_2.fOnComplete = L4_2
  
  function L4_2()
    local L0_3, L1_3, L2_3
    L0_3 = Object
    L0_3 = L0_3.IsAlive
    L1_3 = Pg
    L1_3 = L1_3.GetGuidByName
    L2_3 = "MailTruck"
    L1_3, L2_3 = L1_3(L2_3)
    L0_3 = L0_3(L1_3, L2_3)
    if not L0_3 then
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._SetCancelMessage
      L2_3 = "[OilCon021.Terms.Cancel01]"
      L0_3(L1_3, L2_3)
    end
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.Cancel
    L0_3(L1_3)
  end
  
  L3_2.fOnCancel = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  oDevast = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "MailTruck"
  L5_2 = L5_2(L6_2)
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "OilCon021_Laugher_4"
  L6_2 = L6_2(L7_2)
  L7_2 = "<"
  L8_2 = 20
  L9_2 = false
  L10_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L5_2 = Mocking
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectInSeat
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "psych"
  L6_2 = L6_2(L7_2)
  L7_2 = "a"
  L8_2 = "e"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = FionaVOwrong
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

DeliverTruckObjective = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = bTalked
  if L2_2 == false then
    L2_2 = EarlyFind
    L3_2 = A0_2
    L2_2(L3_2)
  end
  L2_2 = Object
  L2_2 = L2_2.HasLabel
  L3_2 = A1_2[1]
  L4_2 = "Mattias"
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    L2_2 = "Mattias-In-Mission-Contract-Pmc01-131"
    sFoundVO = L2_2
    L2_2 = "Mattias-In-Mission-Contract-Pmc01-141"
    sFoundVO2 = L2_2
    L2_2 = "Mattias-In-Mission-Contract-Pmc01-147"
    sFoundVO3 = L2_2
  else
    L2_2 = Object
    L2_2 = L2_2.HasLabel
    L3_2 = A1_2[1]
    L4_2 = "Jennifer"
    L2_2 = L2_2(L3_2, L4_2)
    if L2_2 then
      L2_2 = "Jennifer-In-Mission-Contract-Pmc01-132"
      sFoundVO = L2_2
      L2_2 = "Jennifer-In-Mission-Contract-Pmc01-142"
      sFoundVO2 = L2_2
      L2_2 = "Jennifer-In-Mission-Contract-Pmc01-145"
      sFoundVO3 = L2_2
    else
      L2_2 = Object
      L2_2 = L2_2.HasLabel
      L3_2 = A1_2[1]
      L4_2 = "Chris"
      L2_2 = L2_2(L3_2, L4_2)
      if L2_2 then
        L2_2 = "Chris-In-Mission-Contract-Pmc01-133"
        sFoundVO = L2_2
        L2_2 = "Chris-In-Mission-Contract-Pmc01-143"
        sFoundVO2 = L2_2
        L2_2 = "Chris-In-Mission-Contract-Pmc01-146"
        sFoundVO3 = L2_2
      end
    end
  end
  L2_2 = MrxVoSequence
  L2_2 = L2_2.Start
  L3_2 = {}
  L4_2 = {}
  L5_2 = sFoundVO
  L6_2 = A1_2[1]
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = "Fiona-In-Mission-MinorContract-Oil03-12"
  L6_2 = {}
  L7_2 = sFoundVO2
  L8_2 = A1_2[1]
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = "Fiona-In-Mission-Contract-Pmc01-144"
  L8_2 = {}
  L9_2 = sFoundVO3
  L10_2 = A1_2[1]
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L9_2 = {}
  L10_2 = 3
  L9_2[1] = L10_2
  L10_2 = {}
  L11_2 = OndaflyMocking
  L12_2 = {}
  L13_2 = A0_2
  L12_2[1] = L13_2
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L3_2[5] = L8_2
  L3_2[6] = L9_2
  L3_2[7] = L10_2
  L2_2(L3_2)
end

SpottedDevastator = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "MailTruck"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L2_2(L3_2)
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.FastCollectHumans
  L6_2 = L1_2
  L7_2 = L2_2
  L8_2 = L3_2
  L9_2 = 10
  L10_2 = "OC && Human"
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L6_2 = table
  L6_2 = L6_2.getn
  L7_2 = L5_2
  L6_2 = L6_2(L7_2)
  nOCmocker = L6_2
  L6_2 = nOCmocker
  if 0 < L6_2 then
    L6_2 = DotheMocking
    L7_2 = A0_2
    L8_2 = L5_2[1]
    L6_2(L7_2, L8_2)
  else
    L7_2 = A0_2
    L6_2 = A0_2._CreateEvent
    L8_2 = Event
    L8_2 = L8_2.TimerRelative
    L9_2 = {}
    L10_2 = 3
    L9_2[1] = L10_2
    L10_2 = OndaflyMocking
    L11_2 = {}
    L12_2 = A0_2
    L11_2[1] = L12_2
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  end
end

OndaflyMocking = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = Vehicle
  L2_2 = L2_2.GetDriver
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "MailTruck"
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  if L2_2 then
    L3_2 = nAlreadyHeard
    L3_2 = L3_2 + 1
    nAlreadyHeard = L3_2
    L3_2 = nAlreadyHeard
    if L3_2 == 1 then
      L4_2 = A0_2
      L3_2 = A0_2._CreateEvent
      L5_2 = Event
      L5_2 = L5_2.TimerRelative
      L6_2 = {}
      L7_2 = 0.5
      L6_2[1] = L7_2
      
      function L7_2(A0_3)
        local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
        L1_3 = Object
        L1_3 = L1_3.HasLabel
        L2_3 = L2_2
        L3_3 = "Mattias"
        L1_3 = L1_3(L2_3, L3_3)
        if L1_3 then
          L1_3 = "Mattias-In-Mission-Contract-Pmc01-148"
          sMockVO1 = L1_3
        else
          L1_3 = Object
          L1_3 = L1_3.HasLabel
          L2_3 = L2_2
          L3_3 = "Jennifer"
          L1_3 = L1_3(L2_3, L3_3)
          if L1_3 then
            L1_3 = "Jennifer-In-Mission-Contract-Pmc01-149"
            sMockVO1 = L1_3
          else
            L1_3 = Object
            L1_3 = L1_3.HasLabel
            L2_3 = L2_2
            L3_3 = "Chris"
            L1_3 = L1_3(L2_3, L3_3)
            if L1_3 then
              L1_3 = "Chris-In-Mission-Contract-Pmc01-150"
              sMockVO1 = L1_3
            end
          end
        end
        L1_3 = MrxVoSequence
        L1_3 = L1_3.Start
        L2_3 = {}
        L3_3 = {}
        L4_3 = "OCMerc-In-Mission-Contract-Pmc01-161"
        L5_3 = A1_2
        L3_3[1] = L4_3
        L3_3[2] = L5_3
        L4_3 = {}
        L5_3 = sMockVO1
        L6_3 = L2_2
        L4_3[1] = L5_3
        L4_3[2] = L6_3
        L5_3 = "Fiona-In-Mission-Contract-Pmc01-152"
        L2_3[1] = L3_3
        L2_3[2] = L4_3
        L2_3[3] = L5_3
        L1_3(L2_3)
      end
      
      L8_2 = {}
      L9_2 = A0_2
      L8_2[1] = L9_2
      L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
    else
      L3_2 = nAlreadyHeard
      if L3_2 == 2 then
        L4_2 = A0_2
        L3_2 = A0_2._CreateEvent
        L5_2 = Event
        L5_2 = L5_2.TimerRelative
        L6_2 = {}
        L7_2 = 0.5
        L6_2[1] = L7_2
        
        function L7_2(A0_3)
          local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
          L1_3 = Object
          L1_3 = L1_3.HasLabel
          L2_3 = L2_2
          L3_3 = "Mattias"
          L1_3 = L1_3(L2_3, L3_3)
          if L1_3 then
            L1_3 = "Mattias-In-Mission-Contract-Pmc01-154"
            sMockVO2 = L1_3
          else
            L1_3 = Object
            L1_3 = L1_3.HasLabel
            L2_3 = L2_2
            L3_3 = "Jennifer"
            L1_3 = L1_3(L2_3, L3_3)
            if L1_3 then
              L1_3 = "Jennifer-In-Mission-Contract-Pmc01-155"
              sMockVO2 = L1_3
            else
              L1_3 = Object
              L1_3 = L1_3.HasLabel
              L2_3 = L2_2
              L3_3 = "Chris"
              L1_3 = L1_3(L2_3, L3_3)
              if L1_3 then
                L1_3 = "Chris-In-Mission-Contract-Pmc01-156"
                sMockVO2 = L1_3
              end
            end
          end
          L1_3 = MrxVoSequence
          L1_3 = L1_3.Start
          L2_3 = {}
          L3_3 = {}
          L4_3 = "OCMerc-In-Mission-Contract-Pmc01-158"
          L5_3 = A1_2
          L3_3[1] = L4_3
          L3_3[2] = L5_3
          L4_3 = {}
          L5_3 = sMockVO2
          L6_3 = L2_2
          L4_3[1] = L5_3
          L4_3[2] = L6_3
          L5_3 = "Fiona-In-Mission-Contract-Pmc01-153"
          L6_3 = "Fiona-In-Mission-Contract-Pmc01-157"
          L2_3[1] = L3_3
          L2_3[2] = L4_3
          L2_3[3] = L5_3
          L2_3[4] = L6_3
          L1_3(L2_3)
        end
        
        L8_2 = {}
        L9_2 = A0_2
        L8_2[1] = L9_2
        L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
      else
        L3_2 = nAlreadyHeard
        if L3_2 == 4 then
          L4_2 = A0_2
          L3_2 = A0_2._CreateEvent
          L5_2 = Event
          L5_2 = L5_2.TimerRelative
          L6_2 = {}
          L7_2 = 0.5
          L6_2[1] = L7_2
          
          function L7_2(A0_3)
            local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
            L1_3 = Object
            L1_3 = L1_3.HasLabel
            L2_3 = L2_2
            L3_3 = "Mattias"
            L1_3 = L1_3(L2_3, L3_3)
            if L1_3 then
              L1_3 = "Mattias-In-Mission-Contract-Oil021-06"
              sMockVO4 = L1_3
            else
              L1_3 = Object
              L1_3 = L1_3.HasLabel
              L2_3 = L2_2
              L3_3 = "Jennifer"
              L1_3 = L1_3(L2_3, L3_3)
              if L1_3 then
                L1_3 = "Jennifer-In-Mission-Contract-Oil021-07"
                sMockVO4 = L1_3
              else
                L1_3 = Object
                L1_3 = L1_3.HasLabel
                L2_3 = L2_2
                L3_3 = "Chris"
                L1_3 = L1_3(L2_3, L3_3)
                if L1_3 then
                  L1_3 = "Chris-In-Mission-Contract-Oil021-08"
                  sMockVO4 = L1_3
                end
              end
            end
            L1_3 = MrxVoSequence
            L1_3 = L1_3.Start
            L2_3 = {}
            L3_3 = {}
            L4_3 = "OCMerc-In-Mission-Contract-Pmc01-159"
            L5_3 = A1_2
            L3_3[1] = L4_3
            L3_3[2] = L5_3
            L4_3 = {}
            L5_3 = sMockVO4
            L6_3 = L2_2
            L4_3[1] = L5_3
            L4_3[2] = L6_3
            L2_3[1] = L3_3
            L2_3[2] = L4_3
            L1_3(L2_3)
          end
          
          L8_2 = {}
          L9_2 = A0_2
          L8_2[1] = L9_2
          L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
        else
          L3_2 = nAlreadyHeard
          if L3_2 == 6 then
            L4_2 = A0_2
            L3_2 = A0_2._CreateEvent
            L5_2 = Event
            L5_2 = L5_2.TimerRelative
            L6_2 = {}
            L7_2 = 0.5
            L6_2[1] = L7_2
            
            function L7_2(A0_3)
              local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
              L1_3 = Object
              L1_3 = L1_3.HasLabel
              L2_3 = L2_2
              L3_3 = "Mattias"
              L1_3 = L1_3(L2_3, L3_3)
              if L1_3 then
                L1_3 = "Mattias-In-Mission-Contract-Pmc01-167"
                sMockVO5 = L1_3
              else
                L1_3 = Object
                L1_3 = L1_3.HasLabel
                L2_3 = L2_2
                L3_3 = "Jennifer"
                L1_3 = L1_3(L2_3, L3_3)
                if L1_3 then
                  L1_3 = "Jennifer-In-Mission-Contract-Pmc01-168"
                  sMockVO5 = L1_3
                else
                  L1_3 = Object
                  L1_3 = L1_3.HasLabel
                  L2_3 = L2_2
                  L3_3 = "Chris"
                  L1_3 = L1_3(L2_3, L3_3)
                  if L1_3 then
                    L1_3 = "Chris-In-Mission-Contract-Pmc01-169"
                    sMockVO5 = L1_3
                  end
                end
              end
              L1_3 = MrxVoSequence
              L1_3 = L1_3.Start
              L2_3 = {}
              L3_3 = {}
              L4_3 = "OCMerc-In-Mission-Contract-Pmc01-158"
              L5_3 = A1_2
              L3_3[1] = L4_3
              L3_3[2] = L5_3
              L4_3 = {}
              L5_3 = sMockVO5
              L6_3 = L2_2
              L4_3[1] = L5_3
              L4_3[2] = L6_3
              L2_3[1] = L3_3
              L2_3[2] = L4_3
              L1_3(L2_3)
            end
            
            L8_2 = {}
            L9_2 = A0_2
            L8_2[1] = L9_2
            L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
          else
            L3_2 = {}
            L4_2 = {}
            L5_2 = "OCMerc-In-Mission-Contract-Pmc01-158"
            L6_2 = A1_2
            L4_2[1] = L5_2
            L4_2[2] = L6_2
            L5_2 = {}
            L6_2 = "OCMerc-In-Mission-Contract-Pmc01-159"
            L7_2 = A1_2
            L5_2[1] = L6_2
            L5_2[2] = L7_2
            L6_2 = {}
            L7_2 = "OCMerc-In-Mission-Contract-Pmc01-161"
            L8_2 = A1_2
            L6_2[1] = L7_2
            L6_2[2] = L8_2
            L7_2 = {}
            L8_2 = "OCMerc-In-Mission-Contract-Pmc01-162"
            L9_2 = A1_2
            L7_2[1] = L8_2
            L7_2[2] = L9_2
            L8_2 = {}
            L9_2 = "OCMerc-In-Mission-Contract-Pmc01-160"
            L10_2 = A1_2
            L8_2[1] = L9_2
            L8_2[2] = L10_2
            L3_2[1] = L4_2
            L3_2[2] = L5_2
            L3_2[3] = L6_2
            L3_2[4] = L7_2
            L3_2[5] = L8_2
            L4_2 = MrxUtil
            L4_2 = L4_2.GetRandomTableElement
            L5_2 = L3_2
            L4_2 = L4_2(L5_2)
            L5_2 = MrxVoSequence
            L5_2 = L5_2.Start
            L6_2 = {}
            L7_2 = L4_2
            L6_2[1] = L7_2
            L5_2(L6_2)
          end
        end
      end
    end
  end
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = 12
  L6_2[1] = L7_2
  L7_2 = OndaflyMocking
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
end

DotheMocking = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L1_2 = 1
  L2_2 = 4
  L3_2 = 1
  for L4_2 = L1_2, L2_2, L3_2 do
    L5_2 = Pg
    L5_2 = L5_2.GetGuidByName
    L6_2 = "OilCon021_Laugher_"
    L7_2 = L4_2
    L6_2 = L6_2 .. L7_2
    L5_2 = L5_2(L6_2)
    L6_2 = L4_2 / 2
    if L5_2 then
      L8_2 = A0_2
      L7_2 = A0_2._CreateEvent
      L9_2 = Event
      L9_2 = L9_2.TimerRelative
      L10_2 = {}
      L11_2 = L6_2
      L10_2[1] = L11_2
      L11_2 = Human
      L11_2 = L11_2.PlayRawAnimation
      L12_2 = {}
      L13_2 = L5_2
      L14_2 = "all_aisoldiermale_bare_upright_laugh_fb"
      L15_2 = false
      L16_2 = false
      L17_2 = 0
      L18_2 = false
      L12_2[1] = L13_2
      L12_2[2] = L14_2
      L12_2[3] = L15_2
      L12_2[4] = L16_2
      L12_2[5] = L17_2
      L12_2[6] = L18_2
      L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
    end
  end
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 4
  L4_2[1] = L5_2
  L5_2 = Human
  L5_2 = L5_2.PlayRawAnimation
  L6_2 = {}
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "OilCon021_Laugher_3"
  L7_2 = L7_2(L8_2)
  L8_2 = "all_aisoldiermale_bare_upright_laugh_fb"
  L9_2 = false
  L10_2 = false
  L11_2 = 0
  L12_2 = false
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L6_2[5] = L11_2
  L6_2[6] = L12_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

Mocking = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Oil020-26"
  L2_2[1] = L3_2
  L1_2(L2_2)
end

FionaVOwrong = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Oil021-05"
  L4_2 = {}
  L4_2.mattias = "Mattias-In-Mission-Contract-Oil021-06"
  L4_2.jennifer = "Jennifer-In-Mission-Contract-Oil021-07"
  L4_2.chris = "Chris-In-Mission-Contract-Oil021-08"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
end

FionaVOroad = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "OilCon021_deadblocker"
  L1_2 = L1_2(L2_2)
  uKilled = L1_2
  L1_2 = uKilled
  if L1_2 then
    L1_2 = Object
    L1_2 = L1_2.Kill
    L2_2 = uKilled
    L1_2(L2_2)
  end
end

KillTrucks = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2
  L4_2 = Net
  L4_2 = L4_2.SendCustomEvent
  L5_2 = "OilCon021"
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
end

NetEventCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = eEarlyEnter
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eEarlyEnter
    L1_2(L2_2)
  end
  L1_2 = DangerousBuilding
  L1_2 = L1_2.SetRarity
  L2_2 = "all"
  L3_2 = "default"
  L1_2(L2_2, L3_2)
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
