local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiHudMessage"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxMusic"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTimer"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxAchievements"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  A0_2.bStarted = false
  A0_2.nCopterDead = false
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
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
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L1_2 = {}
  L2_2 = "PmcCon013_Copter01"
  L3_2 = "PmcCon013_Copter02"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = Pg
    L7_2 = L7_2.GetGuidByName
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    L9_2 = A0_2
    L8_2 = A0_2._CreateEvent
    L10_2 = Event
    L10_2 = L10_2.ObjectHibernation
    L11_2 = {}
    L12_2 = L7_2
    L13_2 = "awake"
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L12_2 = Vehicle
    L12_2 = L12_2.SetCanPlayerUse
    L13_2 = {}
    L14_2 = L7_2
    L15_2 = "p"
    L16_2 = false
    L13_2[1] = L14_2
    L13_2[2] = L15_2
    L13_2[3] = L16_2
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  end
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "PmcCon013_VehicleObjective"
  L4_2.sModuleName = "MrxTaskObjectiveEnterVehicle"
  L5_2 = {}
  L6_2 = "PmcCon013_Copter01"
  L7_2 = "PmcCon013_Copter02"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2.vTgtInclude = L5_2
  L4_2.nQuota = 1
  L5_2 = {}
  L6_2 = {}
  L7_2 = StartTheShallenge
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnComplete = L5_2
  L5_2 = {}
  L6_2 = {}
  L7_2 = A0_2.Cancel
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnCancel = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  PmcCon013_VehicleObjective = L2_2
end

Start = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = A0_2.bStarted
  if L1_2 then
    return
  else
    A0_2.bStarted = true
  end
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 0.5
  L4_2[1] = L5_2
  L5_2 = PmcCon013_VehicleObjective
  L5_2 = L5_2.Complete
  L6_2 = {}
  L7_2 = PmcCon013_VehicleObjective
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.ShowMessage
  L2_2 = "[Tutorial.Winch]"
  L3_2 = false
  L4_2 = "PmcCon013"
  L1_2(L2_2, L3_2, L4_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 7
  L4_2[1] = L5_2
  L5_2 = MrxTutorialManager
  L5_2 = L5_2.HideMessage
  L6_2 = {}
  L7_2 = false
  L8_2 = "PmcCon013"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreatePersistentEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = "PmcCon013_Copter"
  L4_2[1] = L5_2
  L5_2 = CopterDestroyed
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = MrxMusic
  L1_2 = L1_2.PlaySpecialMusic
  L2_2 = "mu_mission_pmccon013_01"
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetNumCompletions
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    L1_2 = 0
  end
  L1_2 = 5 + L1_2
  nTargetHeight = L1_2
  L1_2 = math
  L1_2 = L1_2.min
  L2_2 = nTargetHeight
  L3_2 = 7
  L1_2 = L1_2(L2_2, L3_2)
  nTargetHeight = L1_2
  L1_2 = 0
  nTicks = L1_2
  L1_2 = 0
  nPrevHeight = L1_2
  L1_2 = 0
  nPrevCount = L1_2
  L1_2 = 10
  nRadius = L1_2
  L1_2 = MrxTimer
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L3_2 = {}
  L3_2.nStartTime = 300
  L3_2.nWarning = 60
  L3_2.iTray = 3
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2._SetCancelMessage
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = "[OilCon005.Terms.Cancel03]"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = {}
  L7_2 = Cancel
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L3_2.tDoneCallbacks = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  oMissionTimer = L1_2
  L1_2 = oMissionTimer
  L2_2 = L1_2
  L1_2 = L1_2.Start
  L1_2(L2_2)
  L1_2 = string
  L1_2 = L1_2.format
  L2_2 = "[pmccon013.objective.short:%d]"
  L3_2 = nTargetHeight
  L1_2 = L1_2(L2_2, L3_2)
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "PmcCon013_Objective"
  L4_2.sModuleName = "MrxTaskObjective"
  L4_2.sDspShortDesc = L1_2
  L4_2.vTgtInclude = "PmcCon013_Target"
  L5_2 = {}
  L6_2 = {}
  L7_2 = A0_2.Complete
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnComplete = L5_2
  L5_2 = {}
  L6_2 = {}
  L7_2 = A0_2.Cancel
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnCancel = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  oObjective = L2_2
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "PmcCon013_Target"
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L3_2(L4_2)
  L2_2, L3_2, L4_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  z = L4_2
  nStartingY = L3_2
  x = L2_2
  L3_2 = A0_2
  L2_2 = A0_2._CreatePersistentEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 0.25
  L5_2[1] = L6_2
  L6_2 = PollHeight
  L7_2 = {}
  L8_2 = Pg
  L8_2 = L8_2.GetGuidByName
  L9_2 = "PmcCon013_Target"
  L8_2 = L8_2(L9_2)
  L9_2 = nStartingY
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L2_2 = Marker
  L2_2 = L2_2.AddDisc
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "PmcCon013_Loc"
  L3_2 = L3_2(L4_2)
  L4_2 = nRadius
  L5_2 = 255
  L6_2 = 200
  L7_2 = 0
  L8_2 = 0.25
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  uMarker = L2_2
  L2_2 = Net
  L2_2 = L2_2.IsServer
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = Net
    L2_2 = L2_2.SendEvent_AddMarkerObjective
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = "PmcCon013_Loc"
    L3_2 = L3_2(L4_2)
    L4_2 = uMarker
    L5_2 = 255
    L6_2 = 200
    L7_2 = 0
    L8_2 = 0.25
    L9_2 = 0
    L10_2 = nRadius
    L11_2 = 0
    L12_2 = true
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  end
end

StartTheShallenge = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = A0_2
  L3_2 = nStartingY
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2)
  L4_2 = nStartingY
  L4_2 = L2_2 - L4_2
  L5_2 = nTargetHeight
  if L4_2 > L5_2 then
    L5_2 = nPrevHeight
    if L4_2 == L5_2 then
      L5_2 = Object
      L5_2 = L5_2.IsWinched
      L6_2 = A0_2
      L5_2 = L5_2(L6_2)
      if not L5_2 then
        L5_2 = nTicks
        L5_2 = L5_2 + 1
        nTicks = L5_2
    end
  end
  else
    L5_2 = 0
    nTicks = L5_2
  end
  L5_2 = MrxUtil
  L5_2 = L5_2.GetDistanceBetween
  L6_2 = A0_2
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "PmcCon013_Loc"
  L7_2 = L7_2(L8_2)
  L8_2 = true
  L5_2 = L5_2(L6_2, L7_2, L8_2)
  L6_2 = nRadius
  if L5_2 > L6_2 then
    L5_2 = true
    bOOB = L5_2
  else
    L5_2 = false
    bOOB = L5_2
    L5_2 = Math
    L5_2 = L5_2.floor
    L6_2 = nTicks
    L6_2 = L6_2 / 4
    L5_2 = L5_2(L6_2)
    if 3 <= L5_2 then
      L6_2 = oObjective
      L7_2 = L6_2
      L6_2 = L6_2.Complete
      L6_2(L7_2)
    end
    nPrevHeight = L4_2
  end
  L5_2 = DisplayProgress
  L6_2 = L4_2
  L7_2 = nTargetHeight
  L8_2 = nCount
  L9_2 = bOOB
  L5_2(L6_2, L7_2, L8_2, L9_2)
end

PollHeight = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = "[white]"
  if A1_2 < A0_2 then
    L4_2 = "[green]"
  end
  L5_2 = string
  L5_2 = L5_2.format
  L6_2 = "%.1d"
  L7_2 = A0_2
  L5_2 = L5_2(L6_2, L7_2)
  L6_2 = string
  L6_2 = L6_2.format
  L7_2 = L4_2
  L8_2 = "[pmccon013.objective.target:%.1d]"
  L7_2 = L7_2 .. L8_2
  L8_2 = A1_2
  L6_2 = L6_2(L7_2, L8_2)
  L7_2 = Hud
  L7_2 = L7_2.ObjectiveTray
  L8_2 = L7_2
  L7_2 = L7_2.SetSlotToText
  L9_2 = {}
  L9_2.nSlot = 1
  L9_2.sText = L6_2
  L7_2(L8_2, L9_2)
  if A3_2 then
    L7_2 = Hud
    L7_2 = L7_2.ObjectiveTray
    L8_2 = L7_2
    L7_2 = L7_2.SetSlotToText
    L9_2 = {}
    L9_2.nSlot = 2
    L9_2.sText = "[red][pmccon013.objective.oob]"
    L7_2(L8_2, L9_2)
  else
    L7_2 = string
    L7_2 = L7_2.format
    L8_2 = L4_2
    L9_2 = "[pmccon013.objective.current:%.1d]"
    L8_2 = L8_2 .. L9_2
    L9_2 = L5_2
    L7_2 = L7_2(L8_2, L9_2)
    L6_2 = L7_2
    L7_2 = Hud
    L7_2 = L7_2.ObjectiveTray
    L8_2 = L7_2
    L7_2 = L7_2.SetSlotToText
    L9_2 = {}
    L9_2.nSlot = 2
    L9_2.sText = L6_2
    L7_2(L8_2, L9_2)
  end
end

DisplayProgress = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2.GetNumCompletions
  L1_2 = L1_2(L2_2)
  if L1_2 == 2 then
    L2_2 = MrxAchievements
    L2_2 = L2_2.NetGrantAchievement
    L3_2 = "ACHIEVEMENT_BALLS_TO_THE_WALL"
    L2_2(L3_2)
  end
  L2_2 = MrxTaskContract
  L2_2 = L2_2.Complete
  L3_2 = A0_2
  L2_2(L3_2)
end

Complete = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxMusic
  L1_2 = L1_2.StopSpecialMusic
  L1_2()
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
  L1_2 = uMarker
  if L1_2 then
    L1_2 = Marker
    L1_2 = L1_2.Remove
    L2_2 = uMarker
    L1_2(L2_2)
  end
  L1_2 = Net
  L1_2 = L1_2.IsServer
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = uMarker
    if L1_2 then
      L1_2 = Net
      L1_2 = L1_2.SendEvent_RemoveMarkerObjective
      L2_2 = uMarker
      L1_2(L2_2)
    end
  end
  L1_2 = oMissionTimer
  if L1_2 then
    L1_2 = oMissionTimer
    L2_2 = L1_2
    L1_2 = L1_2.Stop
    L1_2(L2_2)
  end
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Remove
  L2_2 = {}
  L3_2 = "vz_state_PmcCon013_MP"
  L2_2[1] = L3_2
  L1_2(L2_2)
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.nCopterDead
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2._SetCancelMessage
    L3_2 = "[PmcCon016.Terms.Cancel03]"
    L1_2(L2_2, L3_2)
    L2_2 = A0_2
    L1_2 = A0_2.Cancel
    L1_2(L2_2)
  else
    A0_2.nCopterDead = true
  end
end

CopterDestroyed = L0_1
