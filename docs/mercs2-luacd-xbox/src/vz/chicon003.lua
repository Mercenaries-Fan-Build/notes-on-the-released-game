local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxCinematic"
L0_1(L1_1)
L0_1 = import
L1_1 = "DangerousBuilding"
L0_1(L1_1)
L0_1 = import
L1_1 = "Outpost"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = 0
  nCompleted = L1_2
  L1_2 = false
  bAlliesHateYou = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetLocalCharacter
  L5_2 = L5_2()
  L6_2 = "awake"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = Start
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = SetupObjectives
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = CaracasIsHell
  L2_2 = A0_2
  L1_2(L2_2)
end

Start = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = CreateProxEvents
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Chi03-17"
  L4_2 = 2
  L5_2 = "Fiona-In-Mission-Contract-Chi03-26"
  L6_2 = {}
  
  function L7_2()
    local L0_3, L1_3
    L0_3 = MrxSupportData
    L0_3 = L0_3.AddFreebie
    L1_3 = "CH_CruiseMissile"
    L0_3(L1_3)
    L0_3 = MrxSupportData
    L0_3 = L0_3.AddFreebie
    L1_3 = "CH_CruiseMissile"
    L0_3(L1_3)
    L0_3 = MrxSupportData
    L0_3 = L0_3.AddFreebie
    L1_3 = "CH_CruiseMissile"
    L0_3(L1_3)
    L0_3 = MrxSupportData
    L0_3 = L0_3.AddFreebie
    L1_3 = "CH_CruiseMissile"
    L0_3(L1_3)
  end
  
  L6_2[1] = L7_2
  L7_2 = {}
  L7_2.mattias = "Mattias-In-Mission-Contract-Chi03-32"
  L7_2.chris = "Chris-In-Mission-Contract-Chi03-34"
  L7_2.jennifer = "Jennifer-In-Mission-Contract-Chi03-33"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Verify"
  L3_2.sModuleName = "MrxTaskObjectiveVerify"
  L4_2 = {}
  L5_2 = "ChiCon003_HVT"
  L4_2[1] = L5_2
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[ChiCon003.Objective.verify]"
  L3_2.sFactionId = "Chi"
  L4_2 = {}
  L5_2 = {}
  L6_2 = MrxFactionManager
  L6_2 = L6_2.SetFactionReporting
  L7_2 = {}
  L8_2 = "All"
  L9_2 = false
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnTargetDestroyed = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = MrxFactionManager
  L6_2 = L6_2.SetFactionReporting
  L7_2 = {}
  L8_2 = "All"
  L9_2 = false
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = {}
  L7_2 = OneObjectiveDown
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = {}
  L8_2 = AlliesHateYou
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L3_2.tOnComplete = L4_2
  L1_2(L2_2, L3_2)
  L1_2 = {}
  L2_2 = "ChiCon003_Target01"
  L3_2 = "ChiCon003_Target02"
  L4_2 = "ChiCon003_Target04"
  L5_2 = "ChiCon003_Target05"
  L6_2 = "ChiCon003_Target06"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  tBuildings = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Destroy"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = tBuildings
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[ChiCon003.Objective.destroy]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = AlliesHateYou
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnPartComplete = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = MrxSupportData
  L6_2 = L6_2.AddFreebie
  L7_2 = {}
  L8_2 = "ChiCon003_Artillery"
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = {}
  L7_2 = OneObjectiveDown
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L3_2.tOnComplete = L4_2
  L1_2(L2_2, L3_2)
  L1_2 = pairs
  L2_2 = tBuildings
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = DangerousBuilding
    L6_2 = L6_2.TurnOn
    L7_2 = L5_2
    L8_2 = false
    L9_2 = false
    L10_2 = true
    L6_2(L7_2, L8_2, L9_2, L10_2)
  end
end

SetupObjectives = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "AllJob001_02_Outpost"
  L5_2 = L5_2(L6_2)
  L6_2 = "awake"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = {}
  L7_2 = {}
  L8_2 = "Fiona-In-Mission-Contract-Chi03-08"
  L7_2[1] = L8_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

CreateProxEvents = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = nCompleted
  L1_2 = L1_2 + 1
  nCompleted = L1_2
  L1_2 = nCompleted
  if L1_2 == 2 then
    L2_2 = A0_2
    L1_2 = A0_2.Complete
    L1_2(L2_2)
  end
end

OneObjectiveDown = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Chi03-10"
  L2_2[1] = L3_2
  L1_2(L2_2)
  L1_2 = MrxFactionManager
  L1_2 = L1_2.LockPursuit
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "Allied"
  L2_2 = L2_2(L3_2)
  L3_2 = 3
  L1_2(L2_2, L3_2)
end

BonusCancel = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = oBonus
  L1_2 = L1_2._oTimer
  L2_2 = L1_2
  L1_2 = L1_2.AddTime
  L3_2 = -600
  L1_2(L2_2, L3_2)
  L1_2 = bPlayedWarning
  if not L1_2 then
    L1_2 = MrxVoSequence
    L1_2 = L1_2.Start
    L2_2 = {}
    L3_2 = "Fiona-In-Mission-Contract-Chi03-11"
    L2_2[1] = L3_2
    L1_2(L2_2)
    L1_2 = true
    bPlayedWarning = L1_2
  end
end

DecrementTimer = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = bAlliesHateYou
  if L1_2 then
    return
  end
  L1_2 = true
  bAlliesHateYou = L1_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Chi03-18"
  L4_2 = {}
  L5_2 = MrxFactionManager
  L5_2 = L5_2.ChangeRelation
  L6_2 = {}
  L7_2 = "All"
  L8_2 = "Pmc"
  L9_2 = -200
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = {}
  L5_2.mattias = "Mattias-In-Mission-Contract-Chi03-19"
  L5_2.chris = "Chris-In-Mission-Contract-Chi03-21"
  L5_2.jennifer = "Jennifer-In-Mission-Contract-Chi03-20"
  L6_2 = "Fiona-In-Mission-Contract-Chi03-22"
  L7_2 = {}
  L7_2.mattias = "Mattias-In-Mission-Contract-Chi03-23"
  L7_2.chris = "Chris-In-Mission-Contract-Chi03-25"
  L7_2.jennifer = "Jennifer-In-Mission-Contract-Chi03-24"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L1_2(L2_2)
end

AlliesHateYou = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.ChangeLineRegionSetting
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "rgn_atmo_caracas"
  L2_2 = L2_2(L3_2)
  L3_2 = "warzone"
  L1_2(L2_2, L3_2)
end

CaracasIsHell = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L1_2 = {}
  L2_2 = "Road 0x000e76c0"
  L3_2 = "Road 0x000e76b9"
  L4_2 = "Road 0x000ee818"
  L5_2 = "Road 0x00110891"
  L6_2 = "Road 0x000ebd21"
  L7_2 = "Road 0x000ebd4e"
  L8_2 = "Road 0x000b0124"
  L9_2 = "Road 0x000b0125"
  L10_2 = "Road 0x000b0111"
  L11_2 = "Road 0x000b0123"
  L12_2 = "Road 0x000a1831"
  L13_2 = "Road 0x000a1992"
  L14_2 = "Road 0x0010b1bc"
  L15_2 = "Road 0x0010b3af"
  L16_2 = "Road 0x0010b215"
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
  tAlliedAttackRoute01 = L1_2
  L1_2 = pairs
  L2_2 = tAlliedAttackRoute01
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Ai
    L6_2 = L6_2.SetLaneActive
    L7_2 = Pg
    L7_2 = L7_2.GetGuidByName
    L8_2 = L5_2
    L7_2 = L7_2(L8_2)
    L8_2 = 1
    L9_2 = false
    L6_2(L7_2, L8_2, L9_2)
  end
end

SetBattlePathways = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2.Complete
  L2_2 = A0_2
  L1_2(L2_2)
end

_MissionComplete = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxFactionManager
  L1_2 = L1_2.ClearPursuitLock
  L1_2()
  L1_2 = MrxSupportData
  L1_2 = L1_2.RemoveFreebie
  L2_2 = "CH_CruiseMissile"
  L1_2(L2_2)
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
