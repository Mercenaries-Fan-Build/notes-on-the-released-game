local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = 3
  nBonusMult = L1_2
  L1_2 = 0
  nDudeHealth = L1_2
  L1_2 = 100
  nVehHealth = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.GetNumCompletions
  L1_2 = L1_2(L2_2)
  nCompletions = L1_2
  L1_2 = {}
  L2_2 = "Fiona-In-Mission-MinorContract-Oil03-23"
  L1_2[1] = L2_2
  tInitialVOTable = L1_2
  L1_2 = nCompletions
  if L1_2 == 1 then
    L1_2 = table
    L1_2 = L1_2.insert
    L2_2 = tInitialVOTable
    L3_2 = "Fiona-In-Mission-MinorContract-Oil03-25"
    L1_2(L2_2, L3_2)
  else
    L1_2 = nCompletions
    if 2 <= L1_2 then
      L1_2 = table
      L1_2 = L1_2.insert
      L2_2 = tInitialVOTable
      L3_2 = "Fiona-In-Mission-MinorContract-Oil03-26"
      L1_2(L2_2, L3_2)
    else
      L1_2 = table
      L1_2 = L1_2.insert
      L2_2 = tInitialVOTable
      L3_2 = "Fiona-In-Mission-MinorContract-Oil03-24"
      L1_2(L2_2, L3_2)
    end
  end
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "TalktoDuder"
  L3_2.sModuleName = "MrxTaskObjectiveAction"
  L3_2.sActionLabel = "[ContextAction.Talk]"
  L3_2.vTgtInclude = "OilCon003_deliv"
  L3_2.sDspShortDesc = "[OilCon003.Objectives.001]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = DeliverDude
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnPartComplete = L4_2
  L4_2 = tInitialVOTable
  L3_2.vVoSeqOnAdd = L4_2
  L1_2(L2_2, L3_2)
  L1_2 = Ai
  L1_2 = L1_2.SetState
  L2_2 = {}
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "OilCon003_deliv"
  L3_2 = L3_2(L4_2)
  L2_2.AIGuid = L3_2
  L2_2.State = "Pacifist"
  L2_2.Value = true
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "OilCon003_deliv"
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L4_2[7] = L11_2
  L5_2 = DudeKilled
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
  L7_2 = "OilCon003_deliv"
  L6_2 = L6_2(L7_2)
  L7_2 = "<"
  L8_2 = 60
  L9_2 = false
  L10_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L5_2 = TakeSeat
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Ai
  L1_2 = L1_2.Role
  L2_2 = {}
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "OilCon003_deliv"
  L3_2 = L3_2(L4_2)
  L2_2.AIGuid = L3_2
  L2_2.Role = "Idle"
  L2_2.Priority = "hiPri"
  L1_2(L2_2)
  L1_2 = ObjectFilter
  L1_2 = L1_2.Create
  L1_2 = L1_2()
  L2_2 = ObjectFilter
  L2_2 = L2_2.SetFilter
  L3_2 = L1_2
  L4_2 = "VZ"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "OilCon003_deliv"
  L6_2 = L6_2(L7_2)
  L7_2 = L1_2
  L8_2 = "<"
  L9_2 = 100
  L10_2 = false
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = VZWarning
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = {}
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "OilCon003_deliv"
  L2_2 = L2_2(L3_2)
  L1_2.AIGuid = L2_2
  L1_2.Goal = "Enter"
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "_global_bencha 0x000a0b11"
  L2_2 = L2_2(L3_2)
  L1_2.Target = L2_2
  L1_2.Priority = "hiPri"
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 1
  L5_2[1] = L6_2
  L6_2 = Ai
  L6_2 = L6_2.Goal
  L7_2 = {}
  L8_2 = L1_2
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
  L8_2 = "OilCon003_deliv"
  L7_2 = L7_2(L8_2)
  L8_2 = "<"
  L9_2 = 5
  L10_2 = false
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = ExitSeat
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

TakeSeat = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Ai
  L1_2 = L1_2.Goal
  L2_2 = {}
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "OilCon003_deliv"
  L3_2 = L3_2(L4_2)
  L2_2.AIGuid = L3_2
  L2_2.Goal = "Exit"
  L2_2.Priority = "hiPri"
  L1_2(L2_2)
end

ExitSeat = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-MinorContract-Oil03-04"
  L2_2[1] = L3_2
  L1_2(L2_2)
end

VZWarning = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[OilCon003.Terms.Cancel01]"
  L1_2(L2_2, L3_2)
  L1_2 = {}
  L2_2 = "Fiona-In-Mission-MinorContract-Oil03-22"
  L3_2 = "Fiona-In-Mission-MinorContract-Oil03-27"
  L4_2 = "Fiona-In-Mission-MinorContract-Oil03-28"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L2_2 = MrxUtil
  L2_2 = L2_2.GetRandomTableElement
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  L3_2 = {}
  L4_2 = L2_2
  L5_2 = {}
  L6_2 = A0_2.Cancel
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L4_2 = MrxVoSequence
  L4_2 = L4_2.Start
  L5_2 = L3_2
  L4_2(L5_2)
end

DudeKilled = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = {}
  L2_2 = "OilExec-In-Mission-MinorContract-Oil03-33"
  L3_2 = "OilExec-In-Mission-MinorContract-Oil03-34"
  L4_2 = "OilExec-In-Mission-MinorContract-Oil03-35"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L2_2 = MrxUtil
  L2_2 = L2_2.GetRandomTableElement
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  L3_2 = MrxVoSequence
  L3_2 = L3_2.Start
  L4_2 = L2_2
  L3_2(L4_2)
  L3_2 = 2
  nBonusMult = L3_2
  L3_2 = nBonusMult
  L4_2 = nBaseReward
  L3_2 = L3_2 * L4_2
  nTotalReward = L3_2
  L4_2 = A0_2
  L3_2 = A0_2._SetPlayer1Bonus
  L5_2 = nTotalReward
  L3_2(L4_2, L5_2)
  L4_2 = A0_2
  L3_2 = A0_2._SetPlayer2Bonus
  L5_2 = nTotalReward
  L3_2(L4_2, L5_2)
  L3_2 = "[OilCon003.Objectives.TipPrompt]"
  L4_2 = MrxUtil
  L4_2 = L4_2.FormatMoney
  L5_2 = nTotalReward
  L4_2 = L4_2(L5_2)
  L3_2 = L3_2 .. L4_2
  sHudText = L3_2
  L3_2 = Hud
  L3_2 = L3_2.ObjectiveTray
  L4_2 = L3_2
  L3_2 = L3_2.SetSlotToText
  L5_2 = {}
  L5_2.vPlayer = nil
  L5_2.nSlot = 2
  L6_2 = sHudText
  L5_2.sText = L6_2
  L3_2(L4_2, L5_2)
end

TimeWarningFirst = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = {}
  L2_2 = "OilExec-In-Mission-MinorContract-Oil03-36"
  L3_2 = "OilExec-In-Mission-MinorContract-Oil03-37"
  L4_2 = "OilExec-In-Mission-MinorContract-Oil03-38"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L2_2 = MrxUtil
  L2_2 = L2_2.GetRandomTableElement
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  L3_2 = MrxVoSequence
  L3_2 = L3_2.Start
  L4_2 = L2_2
  L3_2(L4_2)
  L3_2 = 1
  nBonusMult = L3_2
  L3_2 = nBonusMult
  L4_2 = nBaseReward
  L3_2 = L3_2 * L4_2
  nTotalReward = L3_2
  L4_2 = A0_2
  L3_2 = A0_2._SetPlayer1Bonus
  L5_2 = nTotalReward
  L3_2(L4_2, L5_2)
  L4_2 = A0_2
  L3_2 = A0_2._SetPlayer2Bonus
  L5_2 = nTotalReward
  L3_2(L4_2, L5_2)
  L3_2 = "[OilCon003.Objectives.TipPrompt]"
  L4_2 = MrxUtil
  L4_2 = L4_2.FormatMoney
  L5_2 = nTotalReward
  L4_2 = L4_2(L5_2)
  L3_2 = L3_2 .. L4_2
  sHudText = L3_2
  L3_2 = Hud
  L3_2 = L3_2.ObjectiveTray
  L4_2 = L3_2
  L3_2 = L3_2.SetSlotToText
  L5_2 = {}
  L5_2.vPlayer = nil
  L5_2.nSlot = 2
  L6_2 = sHudText
  L5_2.sText = L6_2
  L3_2(L4_2, L5_2)
end

TimeWarningSecond = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L3_2 = A0_2
  L2_2 = A0_2.GetNumCompletions
  L2_2 = L2_2(L3_2)
  nCompletions = L2_2
  L2_2 = nCompletions
  if L2_2 == 1 then
    L2_2 = 240
    nTimeLimit = L2_2
    L2_2 = 90
    nDecreaseRewardTimeFirst = L2_2
    L2_2 = 150
    nDecreaseRewardTimeSecond = L2_2
    L2_2 = 2
    nPurLevel = L2_2
    L2_2 = 15000
    nBaseReward = L2_2
    L2_2 = "OilCon3_Drop_Med"
    uDest = L2_2
  else
    L2_2 = nCompletions
    if 2 <= L2_2 then
      L2_2 = 200
      nTimeLimit = L2_2
      L2_2 = 120
      nDecreaseRewardTimeFirst = L2_2
      L2_2 = 150
      nDecreaseRewardTimeSecond = L2_2
      L2_2 = 3
      nPurLevel = L2_2
      L2_2 = 20000
      nBaseReward = L2_2
      L2_2 = "OilCon3_Drop_Hard"
      uDest = L2_2
    else
      L2_2 = 1
      nPurLevel = L2_2
      L2_2 = 240
      nTimeLimit = L2_2
      L2_2 = "OilCon3_Drop_Easy"
      uDest = L2_2
      L2_2 = 120
      nDecreaseRewardTimeFirst = L2_2
      L2_2 = 180
      nDecreaseRewardTimeSecond = L2_2
      L2_2 = 10000
      nBaseReward = L2_2
    end
  end
  L2_2 = nBonusMult
  L3_2 = nBaseReward
  L2_2 = L2_2 * L3_2
  nTotalReward = L2_2
  L2_2 = {}
  L3_2 = "OilExec-In-Mission-MinorContract-Oil03-29"
  L4_2 = "OilExec-In-Mission-MinorContract-Oil03-32"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = {}
  L4_2 = MrxUtil
  L4_2 = L4_2.GetRandomTableElement
  L5_2 = L2_2
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L4_2(L5_2)
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L3_2[5] = L8_2
  L3_2[6] = L9_2
  L3_2[7] = L10_2
  L3_2[8] = L11_2
  L3_2[9] = L12_2
  L3_2[10] = L13_2
  L4_2 = "[OilCon003.Objectives.TipPrompt]"
  L5_2 = MrxUtil
  L5_2 = L5_2.FormatMoney
  L6_2 = nTotalReward
  L5_2 = L5_2(L6_2)
  L4_2 = L4_2 .. L5_2
  sHudText = L4_2
  L4_2 = Hud
  L4_2 = L4_2.ObjectiveTray
  L5_2 = L4_2
  L4_2 = L4_2.SetSlotToText
  L6_2 = {}
  L6_2.vPlayer = nil
  L6_2.nSlot = 2
  L7_2 = sHudText
  L6_2.sText = L7_2
  L4_2(L5_2, L6_2)
  L4_2 = SpeedVO
  L5_2 = A0_2
  L4_2(L5_2)
  L4_2 = DamageVehicleVO
  L5_2 = A0_2
  L4_2(L5_2)
  L4_2 = DamageVO
  L5_2 = A0_2
  L4_2(L5_2)
  L5_2 = A0_2
  L4_2 = A0_2.CreateChild
  L6_2 = {}
  L6_2.sName = "DeliverVip"
  L6_2.sModuleName = "MrxTaskObjectiveDeliver"
  L6_2.vTgtInclude = "OilCon003_deliv"
  L7_2 = uDest
  L6_2.vDestLoc = L7_2
  L6_2.sDspShortDesc = "[OilCon003.Objectives.002]"
  L6_2.fDist = 15
  L6_2.uStartAttachedToPlayer = A1_2
  L6_2.bStop = true
  L6_2.bXZOnly = false
  L7_2 = nTimeLimit
  L6_2.nTimeLimit = L7_2
  
  function L7_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = Hud
    L0_3 = L0_3.ObjectiveTray
    L1_3 = L0_3
    L0_3 = L0_3.ClearSlot
    L2_3 = {}
    L2_3.vPlayer = nil
    L2_3.nSlot = 2
    L0_3(L1_3, L2_3)
    L0_3 = nil
    L1_3 = nCompletions
    if L1_3 == 1 then
      L0_3 = "Fiona-In-Mission-MinorContract-Oil03-07"
    else
      L1_3 = nCompletions
      if 2 <= L1_3 then
        L0_3 = "Fiona-In-Mission-MinorContract-Oil03-13"
      else
        L0_3 = "Fiona-In-Mission-MinorContract-Oil03-08"
      end
    end
    L1_3 = {}
    L2_3 = L0_3
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
    L2_3 = MrxVoSequence
    L2_3 = L2_3.Start
    L3_3 = L1_3
    L2_3(L3_3)
  end
  
  L6_2.fOnComplete = L7_2
  
  function L7_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L0_3 = Hud
    L0_3 = L0_3.ObjectiveTray
    L1_3 = L0_3
    L0_3 = L0_3.ClearSlot
    L2_3 = {}
    L2_3.vPlayer = nil
    L2_3.nSlot = 2
    L0_3(L1_3, L2_3)
    L0_3 = {}
    L1_3 = "OilExec-In-Mission-MinorContract-Oil03-39"
    L2_3 = "OilExec-In-Mission-MinorContract-Oil03-40"
    L0_3[1] = L1_3
    L0_3[2] = L2_3
    L1_3 = MrxUtil
    L1_3 = L1_3.GetRandomTableElement
    L2_3 = L0_3
    L1_3 = L1_3(L2_3)
    L2_3 = A0_2
    L3_3 = L2_3
    L2_3 = L2_3._SetCancelMessage
    L4_3 = "[OilCon003.Terms.Cancel02]"
    L2_3(L3_3, L4_3)
    L2_3 = {}
    L3_3 = L1_3
    L4_3 = {}
    L5_3 = A0_2
    L5_3 = L5_3.Cancel
    L6_3 = {}
    L7_3 = A0_2
    L6_3[1] = L7_3
    L4_3[1] = L5_3
    L4_3[2] = L6_3
    L2_3[1] = L3_3
    L2_3[2] = L4_3
    L3_3 = MrxVoSequence
    L3_3 = L3_3.Start
    L4_3 = L2_3
    L3_3(L4_3)
  end
  
  L6_2.fOnCancel = L7_2
  L6_2.vVoSeqOnAdd = L3_2
  L4_2(L5_2, L6_2)
  L5_2 = A0_2
  L4_2 = A0_2._CreateEvent
  L6_2 = Event
  L6_2 = L6_2.TimerRelative
  L7_2 = {}
  L8_2 = nDecreaseRewardTimeFirst
  L7_2[1] = L8_2
  L8_2 = TimeWarningFirst
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  L5_2 = A0_2
  L4_2 = A0_2._CreateEvent
  L6_2 = Event
  L6_2 = L6_2.TimerRelative
  L7_2 = {}
  L8_2 = nDecreaseRewardTimeSecond
  L7_2[1] = L8_2
  L8_2 = TimeWarningSecond
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  L5_2 = A0_2
  L4_2 = A0_2._CreateEvent
  L6_2 = Event
  L6_2 = L6_2.ObjectProximity
  L7_2 = {}
  L8_2 = Pg
  L8_2 = L8_2.GetGuidByName
  L9_2 = "OilCon003_deliv"
  L8_2 = L8_2(L9_2)
  L9_2 = Pg
  L9_2 = L9_2.GetGuidByName
  L10_2 = "OilCon3_start"
  L9_2 = L9_2(L10_2)
  L10_2 = ">"
  L11_2 = 150
  L12_2 = false
  L13_2 = false
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L7_2[5] = L12_2
  L7_2[6] = L13_2
  L8_2 = StartPursuit
  L9_2 = {}
  L10_2 = A0_2
  L11_2 = nPurLevel
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  L5_2 = A0_2
  L4_2 = A0_2._CreateEvent
  L6_2 = Event
  L6_2 = L6_2.ObjectProximity
  L7_2 = {}
  L8_2 = Pg
  L8_2 = L8_2.GetGuidByName
  L9_2 = "OilCon003_deliv"
  L8_2 = L8_2(L9_2)
  L9_2 = Pg
  L9_2 = L9_2.GetGuidByName
  L10_2 = uDest
  L9_2 = L9_2(L10_2)
  L10_2 = "<"
  L11_2 = 150
  L12_2 = false
  L13_2 = false
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L7_2[5] = L12_2
  L7_2[6] = L13_2
  L8_2 = ClearPursuit
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  L4_2 = Sound
  L4_2 = L4_2.LockActionLevelMusic
  L5_2 = true
  L4_2(L5_2)
  L4_2 = Sound
  L4_2 = L4_2.SetActionLevelsMusic
  L5_2 = 3
  L6_2 = 0
  L7_2 = 0
  L8_2 = 0
  L4_2(L5_2, L6_2, L7_2, L8_2)
end

DeliverDude = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = nBaseReward
  if L1_2 then
    L1_2 = nBonusMult
    if L1_2 then
      L2_2 = A0_2
      L1_2 = A0_2._SetPlayer1Bonus
      L3_2 = nBaseReward
      L4_2 = nBonusMult
      L3_2 = L3_2 * L4_2
      L1_2(L2_2, L3_2)
      L2_2 = A0_2
      L1_2 = A0_2._SetPlayer2Bonus
      L3_2 = nBaseReward
      L4_2 = nBonusMult
      L3_2 = L3_2 * L4_2
      L1_2(L2_2, L3_2)
    end
  end
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Complete
  L2_2 = A0_2
  L1_2(L2_2)
end

Complete = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = Sound
  L1_2 = L1_2.LockActionLevelMusic
  L2_2 = false
  L1_2(L2_2)
  L1_2 = MrxFactionManager
  L1_2 = L1_2.ClearPursuitLock
  L1_2()
end

ClearPursuit = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  if A1_2 == 1 then
    L2_2 = {}
    L3_2 = {}
    L4_2 = "Driving"
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
    L9_2 = 3
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L6_2[1] = L7_2
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L4_2 = {}
    L5_2 = "Stopped"
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
    L10_2 = 3
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L7_2[1] = L8_2
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L4_2[3] = L7_2
    L5_2 = {}
    L6_2 = "Offroad"
    L7_2 = {}
    L8_2 = {}
    L9_2 = "Car"
    L10_2 = "M151 .50Cal (VZ) (DriverGunner)"
    L11_2 = 1
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L7_2[1] = L8_2
    L8_2 = {}
    L9_2 = {}
    L10_2 = "Car"
    L11_2 = 2
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L8_2[1] = L9_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
    L3_2 = MrxFactionManager
    L3_2 = L3_2.SetCustomPursuit
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "VZ"
    L4_2 = L4_2(L5_2)
    L5_2 = -1
    L6_2 = L2_2
    L3_2(L4_2, L5_2, L6_2)
  elseif A1_2 == 2 then
    L2_2 = {}
    L3_2 = {}
    L4_2 = "Driving"
    L5_2 = {}
    L6_2 = {}
    L7_2 = "Car"
    L8_2 = "M151 .50Cal (VZ) (DriverGunner)"
    L9_2 = 1
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L7_2 = {}
    L8_2 = "Car"
    L9_2 = "M113 (VZ) (DriverGunner)"
    L10_2 = 1
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L6_2 = {}
    L7_2 = {}
    L8_2 = "Car"
    L9_2 = 6
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L6_2[1] = L7_2
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L4_2 = {}
    L5_2 = "Stopped"
    L6_2 = {}
    L7_2 = {}
    L8_2 = "Car"
    L9_2 = "M151 .50Cal (VZ) (DriverGunner)"
    L10_2 = 1
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L8_2 = {}
    L9_2 = "Car"
    L10_2 = "M113 (VZ) (DriverGunner)"
    L11_2 = 1
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L7_2 = {}
    L8_2 = {}
    L9_2 = "Car"
    L10_2 = 6
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L7_2[1] = L8_2
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L4_2[3] = L7_2
    L5_2 = {}
    L6_2 = "Offroad"
    L7_2 = {}
    L8_2 = {}
    L9_2 = "Car"
    L10_2 = "M151 .50Cal (VZ) (DriverGunner)"
    L11_2 = 1
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L9_2 = {}
    L10_2 = "Car"
    L11_2 = "M113 (VZ) (DriverGunner)"
    L12_2 = 1
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L8_2 = {}
    L9_2 = {}
    L10_2 = "Car"
    L11_2 = 6
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L8_2[1] = L9_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
    L3_2 = MrxFactionManager
    L3_2 = L3_2.SetCustomPursuit
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "VZ"
    L4_2 = L4_2(L5_2)
    L5_2 = -1
    L6_2 = L2_2
    L3_2(L4_2, L5_2, L6_2)
  elseif A1_2 == 3 then
    L2_2 = {}
    L3_2 = {}
    L4_2 = "Driving"
    L5_2 = {}
    L6_2 = {}
    L7_2 = "Car"
    L8_2 = "M151 .50Cal (VZ) (DriverGunner)"
    L9_2 = 1
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L7_2 = {}
    L8_2 = "Tank"
    L9_2 = "Scorpion90 (Full)"
    L10_2 = 1
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L6_2 = {}
    L7_2 = {}
    L8_2 = "Car"
    L9_2 = 4
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L8_2 = {}
    L9_2 = "Tank"
    L10_2 = 2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L4_2 = {}
    L5_2 = "Stopped"
    L6_2 = {}
    L7_2 = {}
    L8_2 = "Car"
    L9_2 = "M151 .50Cal (VZ) (DriverGunner)"
    L10_2 = 1
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L8_2 = {}
    L9_2 = "Tank"
    L10_2 = "Scorpion90 (Full)"
    L11_2 = 1
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L7_2 = {}
    L8_2 = {}
    L9_2 = "Car"
    L10_2 = 4
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L9_2 = {}
    L10_2 = "Tank"
    L11_2 = 2
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L4_2[3] = L7_2
    L5_2 = {}
    L6_2 = "Offroad"
    L7_2 = {}
    L8_2 = {}
    L9_2 = "Car"
    L10_2 = "M151 .50Cal (VZ) (DriverGunner)"
    L11_2 = 1
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L9_2 = {}
    L10_2 = "Tank"
    L11_2 = "Scorpion90 (Full)"
    L12_2 = 1
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L8_2 = {}
    L9_2 = {}
    L10_2 = "Car"
    L11_2 = 4
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L10_2 = {}
    L11_2 = "Tank"
    L12_2 = 2
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
    L3_2 = MrxFactionManager
    L3_2 = L3_2.SetCustomPursuit
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "VZ"
    L4_2 = L4_2(L5_2)
    L5_2 = -1
    L6_2 = L2_2
    L3_2(L4_2, L5_2, L6_2)
  end
end

StartPursuit = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Vehicle
  L1_2 = L1_2.GetFromRider
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "OilCon003_deliv"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  uDude = L1_2
  L1_2 = uDude
  if L1_2 then
    L1_2 = Object
    L1_2 = L1_2.GetVelocity
    L2_2 = uDude
    L1_2 = L1_2(L2_2)
    nDudeSpeed = L1_2
    L1_2 = nDudeSpeed
    if 30 < L1_2 then
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = "OilExec-In-Mission-MinorContract-Oil03-15"
      L4_2 = {}
      L4_2.mattias = "mattias-In-Mission-MinorContract-Oil03-09"
      L4_2.jennifer = "jennifer-In-Mission-MinorContract-Oil03-10"
      L4_2.chris = "chris-In-Mission-MinorContract-Oil03-11"
      L2_2[1] = L3_2
      L2_2[2] = L4_2
      L1_2(L2_2)
      L2_2 = A0_2
      L1_2 = A0_2._CreateEvent
      L3_2 = Event
      L3_2 = L3_2.TimerRelative
      L4_2 = {}
      L5_2 = 30
      L4_2[1] = L5_2
      L5_2 = SpeedVO
      L6_2 = {}
      L7_2 = A0_2
      L6_2[1] = L7_2
      L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
    else
      L2_2 = A0_2
      L1_2 = A0_2._CreateEvent
      L3_2 = Event
      L3_2 = L3_2.TimerRelative
      L4_2 = {}
      L5_2 = 2
      L4_2[1] = L5_2
      L5_2 = SpeedVO
      L6_2 = {}
      L7_2 = A0_2
      L6_2[1] = L7_2
      L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
    end
  else
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = 5
    L4_2[1] = L5_2
    L5_2 = SpeedVO
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  end
end

SpeedVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Vehicle
  L1_2 = L1_2.GetFromRider
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "OilCon003_deliv"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  if L1_2 then
    L2_2 = nVehHealth
    L3_2 = Object
    L3_2 = L3_2.GetHealth
    L4_2 = L1_2
    L3_2 = L3_2(L4_2)
    nVehHealth = L3_2
    L3_2 = nVehHealth
    L3_2 = L2_2 - L3_2
    if 7 < L3_2 then
      L4_2 = MrxVoSequence
      L4_2 = L4_2.Start
      L5_2 = {}
      L6_2 = "OilExec-In-Mission-MinorContract-Oil03-17"
      L5_2[1] = L6_2
      L4_2(L5_2)
      L5_2 = A0_2
      L4_2 = A0_2._CreateEvent
      L6_2 = Event
      L6_2 = L6_2.TimerRelative
      L7_2 = {}
      L8_2 = 30
      L7_2[1] = L8_2
      L8_2 = ResetDamageVehVO
      L9_2 = {}
      L10_2 = A0_2
      L9_2[1] = L10_2
      L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
    else
      L5_2 = A0_2
      L4_2 = A0_2._CreateEvent
      L6_2 = Event
      L6_2 = L6_2.TimerRelative
      L7_2 = {}
      L8_2 = 3
      L7_2[1] = L8_2
      L8_2 = DamageVehicleVO
      L9_2 = {}
      L10_2 = A0_2
      L9_2[1] = L10_2
      L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
    end
  else
    L3_2 = A0_2
    L2_2 = A0_2._CreateEvent
    L4_2 = Event
    L4_2 = L4_2.TimerRelative
    L5_2 = {}
    L6_2 = 3
    L5_2[1] = L6_2
    L6_2 = DamageVehicleVO
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  end
end

DamageVehicleVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Vehicle
  L1_2 = L1_2.GetFromRider
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "OilCon003_deliv"
  L2_2, L3_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 then
    L2_2 = Object
    L2_2 = L2_2.GetHealth
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    nVehHealth = L2_2
  end
  L2_2 = DamageVehicleVO
  L3_2 = A0_2
  L2_2(L3_2)
end

ResetDamageVehVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = nDudeHealth
  L2_2 = Object
  L2_2 = L2_2.GetHealth
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "OilCon003_deliv"
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  nDudeHealth = L2_2
  L2_2 = nDudeHealth
  if L1_2 > L2_2 then
    L2_2 = MrxVoSequence
    L2_2 = L2_2.Start
    L3_2 = {}
    L4_2 = "OilExec-In-Mission-MinorContract-Oil03-14"
    L3_2[1] = L4_2
    L2_2(L3_2)
    L3_2 = A0_2
    L2_2 = A0_2._CreateEvent
    L4_2 = Event
    L4_2 = L4_2.TimerRelative
    L5_2 = {}
    L6_2 = 40
    L5_2[1] = L6_2
    L6_2 = DamageVO
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  else
    L3_2 = A0_2
    L2_2 = A0_2._CreateEvent
    L4_2 = Event
    L4_2 = L4_2.TimerRelative
    L5_2 = {}
    L6_2 = 2
    L5_2[1] = L6_2
    L6_2 = DamageVO
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  end
end

DamageVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxFactionManager
  L1_2 = L1_2.ClearPursuitLock
  L1_2()
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 2
  L1_2(L2_2, L3_2)
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
