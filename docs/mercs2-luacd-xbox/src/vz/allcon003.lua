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
L0_1 = import
L1_1 = "MrxLayerManager"
L0_1(L1_1)

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Remove
  L2_2 = "state_car_city_act2ALL_staging"
  L1_2(L2_2)
  L1_2 = 0
  nCompleted = L1_2
  L1_2 = false
  bHostile = L1_2
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
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = MrxSupportData
  L1_2 = L1_2.AddFreebie
  L2_2 = "AL_CruiseMissile"
  L1_2(L2_2)
  L1_2 = MrxSupportData
  L1_2 = L1_2.AddFreebie
  L2_2 = "AL_CruiseMissile"
  L1_2(L2_2)
  L1_2 = MrxSupportData
  L1_2 = L1_2.AddFreebie
  L2_2 = "AL_CruiseMissile"
  L1_2(L2_2)
  L1_2 = MrxSupportData
  L1_2 = L1_2.AddFreebie
  L2_2 = "AL_CruiseMissile"
  L1_2(L2_2)
  L1_2 = MrxSupportData
  L1_2 = L1_2.AddFreebie
  L2_2 = "Gunship"
  L1_2(L2_2)
  L1_2 = MrxSupportData
  L1_2 = L1_2.AddFreebie
  L2_2 = "Gunship"
  L1_2(L2_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-All03-18"
  L4_2 = {}
  L4_2.mattias = "Mattias-In-Mission-Contract-Chi03-32"
  L4_2.chris = "Chris-In-Mission-Contract-Chi03-34"
  L4_2.jennifer = "Jennifer-In-Mission-Contract-Chi03-33"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
  L1_2 = SetupObjectives
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = CaracasIsHell
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Add
  L2_2 = "vz_state_allcon003_invasion"
  L1_2(L2_2)
end

Start = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Verify"
  L3_2.sModuleName = "MrxTaskObjectiveVerify"
  L4_2 = {}
  L5_2 = "AllCon003_HVT"
  L4_2[1] = L5_2
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[AllCon003.Objective.verify]"
  L3_2.sFactionId = "All"
  L4_2 = {}
  L5_2 = {}
  L6_2 = GoHostile
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnTargetDestroyed = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = OneObjectiveDown
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "DestroyBuildings"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = {}
  L5_2 = "AllCon003_A01"
  L6_2 = "AllCon003_A02"
  L7_2 = "AllCon003_A03"
  L8_2 = "AllCon003_A04"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[AllCon003.Objective.destroy]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.OneObjectiveDown
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.GoHostile
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnPartComplete = L4_2
  L1_2(L2_2, L3_2)
end

SetupObjectives = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = bHostile
  if L1_2 then
    return
  end
  L1_2 = true
  bHostile = L1_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-All03-13"
  L4_2 = {}
  L5_2 = MrxFactionManager
  L5_2 = L5_2.ChangeRelation
  L6_2 = {}
  L7_2 = "Chi"
  L8_2 = "Pmc"
  L9_2 = -200
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = {}
  L6_2 = MrxFactionManager
  L6_2 = L6_2.SetFactionReporting
  L7_2 = {}
  L8_2 = "Chi"
  L9_2 = false
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = {}
  L6_2.mattias = "Mattias-In-Mission-Contract-All03-14"
  L6_2.chris = "Chris-In-Mission-Contract-All03-16"
  L6_2.jennifer = "Jennifer-In-Mission-Contract-All03-15"
  L7_2 = "Fiona-In-Mission-Contract-All03-17"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L1_2(L2_2)
end

GoHostile = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Ai
  L1_2 = L1_2.AddInfraction
  L2_2 = Player
  L2_2 = L2_2.GetLocalCharacter
  L2_2 = L2_2()
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "China"
  L3_2 = L3_2(L4_2)
  L4_2 = 100
  L1_2(L2_2, L3_2, L4_2)
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
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = Player
  L2_2 = L2_2.GetLocalCharacter
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L2_2()
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  z = L3_2
  y = L2_2
  x = L1_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-All03-20"
  L2_2[1] = L3_2
  L1_2(L2_2)
  L1_2 = Airstrike
  L1_2 = L1_2.Flyby
  L2_2 = "Support Vehicle (Autogunship)"
  L3_2 = x
  L3_2 = L3_2 - 50
  L4_2 = z
  L4_2 = L4_2 + 300
  L5_2 = x
  L6_2 = z
  L7_2 = y
  L7_2 = L7_2 + 100
  L8_2 = 40
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
end

NukeItFromOrbit = L0_1

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
    L3_2 = "Fiona-In-Mission-Contract-All03-08"
    L2_2[1] = L3_2
    L1_2(L2_2)
    L1_2 = true
    bPlayedWarning = L1_2
  end
end

DecrementTimer = L0_1

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
  local L1_2, L2_2, L3_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-All03-07"
  L2_2[1] = L3_2
  L1_2(L2_2)
end

BonusCancel = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Add
  L2_2 = "state_car_city_act2ALL_staging"
  L1_2(L2_2)
  L1_2 = MrxSupportData
  L1_2 = L1_2.RemoveFreebie
  L2_2 = "AL_CruiseMissile"
  L1_2(L2_2)
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
