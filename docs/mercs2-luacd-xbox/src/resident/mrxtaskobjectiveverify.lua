local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1
L0_1 = inherit
L1_1 = "MrxTaskObjective"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVerifyManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportPickup"
L0_1(L1_1)
L0_1 = 0
NETEVENT_VERIFY = L0_1
L0_1 = 1
L1_1 = 2
L2_1 = 3
L3_1 = 4
L4_1 = 5
L5_1 = 6
L6_1 = 7
L7_1 = {}
L8_1 = {}

function L9_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L1_2 = L0_1
  A0_2.nCurrHVTState = L1_2
  L1_2 = MrxTaskObjective
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = A0_2._nSupportCount
  if not L1_2 then
    L1_2 = 0
  end
  A0_2._nSupportCount = L1_2
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
  L4_2 = SendPlayerJoinEvents
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  _evClientJoined = L1_2
  L1_2 = A0_2._tEvents
  L2_2 = Event
  L2_2 = L2_2.CreatePersistent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = A0_2._uTgtObjFilter
  L4_2[1] = L5_2
  L5_2 = A0_2._TargetDestroyed
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.uDeathEvent = L2_2
  L1_2 = A0_2._tEvents
  L2_2 = {}
  L1_2.uProxEvent = L2_2
  L1_2 = pairs
  L2_2 = A0_2._tTargets
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = A0_2._tEvents
    L6_2 = L6_2.uProxEvent
    L7_2 = Event
    L7_2 = L7_2.Create
    L8_2 = Event
    L8_2 = L8_2.ObjectProximity
    L9_2 = {}
    L10_2 = "hero"
    L11_2 = L4_2
    L12_2 = "<"
    L13_2 = 10
    L14_2 = false
    L15_2 = false
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L9_2[4] = L13_2
    L9_2[5] = L14_2
    L9_2[6] = L15_2
    L10_2 = A0_2.HeroProximity
    L11_2 = {}
    L12_2 = A0_2
    L13_2 = L4_2
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
    L6_2[L4_2] = L7_2
  end
  L2_2 = A0_2
  L1_2 = A0_2._CreatePersistentEvent
  L3_2 = Event
  L3_2 = L3_2.HumanStateTransition
  L4_2 = {}
  L5_2 = A0_2._uTgtObjFilter
  L6_2 = "*"
  L7_2 = "KnockedDown.Idle"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = A0_2._TargetBashed
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreatePersistentEvent
  L3_2 = Event
  L3_2 = L3_2.HumanStateTransition
  L4_2 = {}
  L5_2 = A0_2._uTgtObjFilter
  L6_2 = "KnockedDown.*"
  L7_2 = "Upright.*"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = A0_2._TargetOutOfSubdued
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = MrxSupportData
  L2_2 = L2_2.GetFreebie
  L3_2 = _GetSupportByFaction
  L4_2 = L1_2.sFactionId
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  if L2_2 then
    L3_2 = L2_2.oSupport
    L4_2 = L3_2
    L3_2 = L3_2.SetHeliDestroyedCB
    L5_2 = _HelicopterDestroyedCallback
    L6_2 = A0_2
    L3_2(L4_2, L5_2, L6_2)
    L3_2 = L2_2.oSupport
    L4_2 = L3_2
    L3_2 = L3_2.SetHeliLandedCB
    L5_2 = _HelicopterLandedCallback
    L6_2 = A0_2
    L3_2(L4_2, L5_2, L6_2)
    L3_2 = L2_2.oSupport
    L4_2 = L3_2
    L3_2 = L3_2.SetPilotKilledCB
    L5_2 = _PilotKilledCallback
    L6_2 = A0_2
    L3_2(L4_2, L5_2, L6_2)
    L3_2 = L2_2.oSupport
    L4_2 = L3_2
    L3_2 = L3_2.SetHeliSpawnedCB
    L5_2 = _HelicopterSpawnedCallback
    L3_2(L4_2, L5_2)
    L3_2 = L2_2.oSupport
    L4_2 = L3_2
    L3_2 = L3_2.SetHeliDamagedCB
    L5_2 = _HelicopterDamagedCallback
    L6_2 = A0_2
    L3_2(L4_2, L5_2, L6_2)
  end
  A0_2._bIsVerified = false
  L3_2 = ObjectFilter
  L3_2 = L3_2.GetObjects
  L4_2 = A0_2._uTgtObjFilter
  L5_2 = false
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = true
  bActivating = L4_2
  L4_2 = ipairs
  L5_2 = L3_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = _TargetOnHibernate
    L10_2 = A0_2
    L11_2 = L8_2
    L9_2(L10_2, L11_2)
    L9_2 = MrxVerifyManager
    L9_2 = L9_2.AddTarget
    L10_2 = L8_2
    L9_2(L10_2)
  end
  L4_2 = false
  bActivating = L4_2
end

Activated = L9_1

function L9_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._TargetOutOfSubdued
  L1_2(L2_2)
  L1_2 = pairs
  L2_2 = L8_1
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L7_2 = A0_2
    L6_2 = A0_2._RemoveSupport
    L8_2 = L4_2
    L6_2(L7_2, L8_2)
  end
  L1_2 = MrxTaskObjective
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L9_1
L9_1 = {}
tActiveHelicopters = L9_1

function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = tActiveHelicopters
  L2_2[A1_2] = A0_2
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ObjectDelete
  L4_2 = {}
  L5_2 = uGuid
  L4_2[1] = L5_2
  
  function L5_2(A0_3)
    local L1_3
    L1_3 = tActiveHelicopters
    L1_3[A0_3] = nil
  end
  
  L6_2 = {}
  L7_2 = A1_2
  L6_2[1] = L7_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
end

_HelicopterSpawnedCallback = L9_1

function L9_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2._bIsVerified
  if not L1_2 then
    L1_2 = A0_2.nCurrHVTState
    L2_2 = L2_1
    if L1_2 ~= L2_2 then
      L1_2 = A0_2.nCurrHVTState
      L2_2 = L3_1
      if L1_2 ~= L2_2 then
        L1_2 = A0_2.nCurrHVTState
        L2_2 = L5_1
        if L1_2 ~= L2_2 then
          L1_2 = A0_2.nCurrHVTState
          L2_2 = L4_1
          if L1_2 ~= L2_2 then
            L1_2 = L1_1
            A0_2.nCurrHVTState = L1_2
          end
        end
      end
    end
    L1_2 = Sys
    L1_2 = L1_2.IsGermanSKU
    L1_2 = L1_2()
    if not L1_2 then
      L1_2 = MrxTutorialManager
      L1_2 = L1_2.ShowMessage
      L2_2 = "[Tutorial.ObjectiveVerify.Key1]"
      L1_2(L2_2)
    end
  end
end

_TargetIntoSubdued = L9_1

function L9_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2._bIsVerified
  if not L1_2 then
    L1_2 = L2_1
    A0_2.nCurrHVTState = L1_2
    L1_2 = MrxTutorialManager
    L1_2 = L1_2.ShowMessage
    L2_2 = "[Tutorial.ObjectiveVerify.Key2]"
    L1_2(L2_2)
  end
end

_HelicopterDestroyedCallback = L9_1

function L9_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2._bIsVerified
  if not L1_2 then
    L1_2 = L3_1
    A0_2.nCurrHVTState = L1_2
    L1_2 = MrxTutorialManager
    L1_2 = L1_2.ShowMessage
    L2_2 = "[Tutorial.ObjectiveVerify.Key1]"
    L1_2(L2_2)
  end
end

_HelicopterDamagedCallback = L9_1

function L9_1(A0_2)
  local L1_2, L2_2
  L1_2 = L5_1
  A0_2.nCurrHVTState = L1_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.ShowMessage
  L2_2 = "[Tutorial.ObjectiveVerify.Key1]"
  L1_2(L2_2)
end

_PilotKilledCallback = L9_1

function L9_1(A0_2)
  local L1_2, L2_2
  L1_2 = L4_1
  A0_2.nCurrHVTState = L1_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.ShowMessage
  L2_2 = "[Tutorial.ObjectiveVerify.Key3]"
  L1_2(L2_2)
end

_HelicopterLandedCallback = L9_1

function L9_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2._bIsVerified
  if not L1_2 then
    L1_2 = A0_2._bIsDead
    if not L1_2 then
      L1_2 = L0_1
      A0_2.nCurrHVTState = L1_2
      L1_2 = MrxTutorialManager
      L1_2 = L1_2.ShowMessage
      L2_2 = "[Tutorial.ObjectiveVerify.Key4]"
      L1_2(L2_2)
    end
  end
end

_TargetOutOfSubdued = L9_1

function L9_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = MrxUtil
  L3_2 = L3_2.GetFaction
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = L3_2
  L4_2 = L4_2(L5_2)
  L5_2 = {}
  L6_2 = Object
  L6_2 = L6_2.HasLabel
  L7_2 = A1_2
  L8_2 = "Coward"
  L6_2 = L6_2(L7_2, L8_2)
  if L6_2 then
    L6_2 = {}
    L7_2 = {}
    L8_2 = "VZCivMale-In-Mission-Contract-Pmc01-50"
    L9_2 = "VZCivMale-In-Mission-Contract-Pmc01-55"
    L10_2 = "VZCivMale-In-Mission-Contract-Pmc01-58"
    L11_2 = "VZSoldier-In-Mission-Contract-Pmc01-57"
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L7_2[4] = L11_2
    L6_2.Guerilla = L7_2
    L7_2 = {}
    L8_2 = "VZCivMale-In-Mission-Contract-Pmc01-50"
    L9_2 = "VZCivMale-In-Mission-Contract-Pmc01-55"
    L10_2 = "VZCivMale-In-Mission-Contract-Pmc01-58"
    L11_2 = "VZSoldier-In-Mission-Contract-Pmc01-57"
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L7_2[4] = L11_2
    L6_2.VZ = L7_2
    L5_2 = L6_2
    L6_2 = Ai
    L6_2 = L6_2.SetState
    L7_2 = {}
    L7_2.AIGuid = A1_2
    L7_2.State = "Pacifist"
    L7_2.Value = true
    L6_2(L7_2)
    L6_2 = Human
    L6_2 = L6_2.DoAction
    L7_2 = A1_2
    L8_2 = "Cower"
    L6_2(L7_2, L8_2)
    L6_2 = Ai
    L6_2 = L6_2.Goal
    L7_2 = {}
    L7_2.AIGuid = A1_2
    L7_2.Goal = "Idle"
    L7_2.Priority = "HiPri"
    L7_2.Force = true
    L6_2(L7_2)
  else
    L6_2 = {}
    L7_2 = {}
    L8_2 = "AlliedSoldier01.Subdued.Taunt01"
    L9_2 = "AlliedSoldier01.Subdued.Taunt03"
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L6_2.Allied = L7_2
    L7_2 = {}
    L8_2 = "ChinaSoldier01.Subdued.Taunt01"
    L9_2 = "ChinaSoldier01.Subdued.Taunt02"
    L10_2 = "ChinaSoldier01.Subdued.Taunt03"
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L6_2.China = L7_2
    L7_2 = {}
    L8_2 = "GurSoldier01.Subdued.Taunt01"
    L9_2 = "GurSoldier01.Subdued.Taunt02"
    L10_2 = "GurSoldier01.Subdued.Taunt03"
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L6_2.Guerilla = L7_2
    L7_2 = {}
    L8_2 = "OCSoldier01.Subdued.Taunt01"
    L7_2[1] = L8_2
    L6_2.OC = L7_2
    L7_2 = {}
    L8_2 = "VZSoldier01.Subdued.Taunt01"
    L9_2 = "VZSoldier01.Subdued.Taunt02"
    L10_2 = "VZSoldier01.Subdued.Taunt03"
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L6_2.VZ = L7_2
    L5_2 = L6_2
  end
  L6_2 = L5_2[L3_2]
  if L6_2 then
    L6_2 = Object
    L6_2 = L6_2.HasLabel
    L7_2 = "Blanco"
    L6_2 = L6_2(L7_2)
    if not L6_2 then
      L6_2 = MrxUtil
      L6_2 = L6_2.GetRandomTableElement
      L7_2 = L5_2[L3_2]
      L6_2 = L6_2(L7_2)
      L7_2 = MrxVoSequence
      L7_2 = L7_2.Start
      L8_2 = L6_2
      L9_2 = A1_2
      L10_2 = MrxVoSequence
      L10_2 = L10_2.knPriorityFreeplay
      L7_2(L8_2, L9_2, L10_2)
    end
  end
  if L4_2 then
    L6_2 = Ai
    L6_2 = L6_2.AddInfraction
    L7_2 = Player
    L7_2 = L7_2.GetPrimaryCharacter
    L7_2 = L7_2()
    L8_2 = L4_2
    L9_2 = 5
    L6_2(L7_2, L8_2, L9_2)
    L6_2 = Player
    L6_2 = L6_2.GetSecondaryCharacter
    L6_2 = L6_2()
    if L6_2 then
      L6_2 = Ai
      L6_2 = L6_2.AddInfraction
      L7_2 = Player
      L7_2 = L7_2.GetSecondaryCharacter
      L7_2 = L7_2()
      L8_2 = L4_2
      L9_2 = 5
      L6_2(L7_2, L8_2, L9_2)
    else
    end
  end
end

HeroProximity = L9_1

function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = bActivating
  if not L2_2 then
    L2_2 = MrxTutorialManager
    L2_2 = L2_2.HideMessage
    L2_2()
  end
  L2_2 = A0_2._tEvents
  L3_2 = A0_2._tEvents
  L3_2 = L3_2.uOnAwakeEvent
  if not L3_2 then
    L3_2 = {}
  end
  L2_2.uOnAwakeEvent = L3_2
  L2_2 = A0_2._tEvents
  L2_2 = L2_2.uOnAwakeEvent
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectHibernation
  L5_2 = {}
  L6_2 = A1_2
  L7_2 = "awake"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = A0_2._TargetOnAwake
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A1_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2[A1_2] = L3_2
end

_TargetOnHibernate = L9_1

function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2._bIsVerified
  if not L2_2 then
    L2_2 = A0_2.nCurrHVTState
    if L2_2 == nil then
    else
      L2_2 = A0_2.nCurrHVTState
      L3_2 = L0_1
      if L2_2 == L3_2 then
        L3_2 = A0_2
        L2_2 = A0_2._TargetOutOfSubdued
        L4_2 = A0_2
        L2_2(L3_2, L4_2)
      else
        L2_2 = A0_2.nCurrHVTState
        L3_2 = L1_1
        if L2_2 == L3_2 then
          L3_2 = A0_2
          L2_2 = A0_2._TargetIntoSubdued
          L4_2 = A0_2
          L2_2(L3_2, L4_2)
        else
          L2_2 = A0_2.nCurrHVTState
          L3_2 = L2_1
          if L2_2 == L3_2 then
            L3_2 = A0_2
            L2_2 = A0_2._HelicopterDestroyedCallback
            L2_2(L3_2)
          else
            L2_2 = A0_2.nCurrHVTState
            L3_2 = L3_1
            if L2_2 ~= L3_2 then
              L2_2 = A0_2.nCurrHVTState
              L3_2 = L5_1
              if L2_2 ~= L3_2 then
                goto lbl_43
              end
            end
            L3_2 = A0_2
            L2_2 = A0_2._HelicopterDamagedCallback
            L4_2 = A0_2
            L2_2(L3_2, L4_2)
            goto lbl_59
            ::lbl_43::
            L2_2 = A0_2.nCurrHVTState
            L3_2 = L4_1
            if L2_2 == L3_2 then
              L2_2 = _HelicopterLandedCallback
              L3_2 = A0_2
              L2_2(L3_2)
            else
              L2_2 = A0_2.nCurrHVTState
              L3_2 = L6_1
              if L2_2 == L3_2 then
                L2_2 = MrxTutorialManager
                L2_2 = L2_2.ShowMessage
                L3_2 = "[Tutorial.ObjectiveVerify.Key5]"
                L2_2(L3_2)
              end
            end
          end
        end
      end
    end
  end
  ::lbl_59::
  L2_2 = Debug
  L2_2 = L2_2.Printf
  L3_2 = "CorpseCleanup: "
  L4_2 = tostring
  L5_2 = Human
  L5_2 = L5_2.SetAllowCorpseCleanup
  L6_2 = A1_2
  L7_2 = false
  L5_2, L6_2, L7_2, L8_2, L9_2 = L5_2(L6_2, L7_2)
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  L3_2 = L3_2 .. L4_2
  L2_2(L3_2)
  L2_2 = A0_2._tEvents
  L3_2 = A0_2._tEvents
  L3_2 = L3_2.uOnHibernateEvent
  if not L3_2 then
    L3_2 = {}
  end
  L2_2.uOnHibernateEvent = L3_2
  L2_2 = A0_2._tEvents
  L2_2 = L2_2.uOnHibernateEvent
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectHibernation
  L5_2 = {}
  L6_2 = A1_2
  L7_2 = "hibernated"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = A0_2._TargetOnHibernate
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A1_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2[A1_2] = L3_2
end

_TargetOnAwake = L9_1

function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  A0_2._bIsDead = true
  L3_2 = A0_2
  L2_2 = A0_2.GetConfig
  L2_2 = L2_2(L3_2)
  L3_2 = MrxUtil
  L3_2 = L3_2.ProcessCallbackTable
  L4_2 = L2_2.tOnTargetDestroyed
  L5_2 = {}
  L6_2 = A1_2
  L5_2[1] = L6_2
  L3_2(L4_2, L5_2)
  L3_2 = MrxUtil
  L3_2 = L3_2.CallWithOptionalArgs
  L4_2 = L2_2.fOnTargetDestroyed
  L5_2 = {}
  L6_2 = A1_2
  L5_2[1] = L6_2
  L3_2(L4_2, L5_2)
  L3_2 = A0_2._tEvents
  L3_2 = L3_2.uProxEvent
  if L3_2 then
    L3_2 = A0_2._tEvents
    L3_2 = L3_2.uProxEvent
    L3_2 = L3_2[A1_2]
    if L3_2 then
      L3_2 = Event
      L3_2 = L3_2.Delete
      L4_2 = A0_2._tEvents
      L4_2 = L4_2.uProxEvent
      L4_2 = L4_2[A1_2]
      L3_2(L4_2)
      L3_2 = A0_2._tEvents
      L3_2 = L3_2.uProxEvent
      L3_2[A1_2] = nil
    end
  end
  L3_2 = Pg
  L3_2 = L3_2.RemoveContextAction
  L4_2 = A1_2
  L3_2(L4_2)
  L3_2 = Sys
  L3_2 = L3_2.IsGermanSKU
  L3_2 = L3_2()
  if L3_2 then
    L3_2 = _TargetActionedComplete
    L4_2 = A0_2
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
  else
    L3_2 = Event
    L3_2 = L3_2.Create
    L4_2 = Event
    L4_2 = L4_2.TimerRelative
    L5_2 = {}
    L6_2 = 3
    L5_2[1] = L6_2
    L6_2 = A0_2._SetupVerify
    L7_2 = {}
    L8_2 = A0_2
    L9_2 = A1_2
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L3_2(L4_2, L5_2, L6_2, L7_2)
    L4_2 = A0_2
    L3_2 = A0_2._RemoveSupport
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
  end
end

_TargetDestroyed = L9_1

function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = L6_1
  A0_2.nCurrHVTState = L2_2
  L2_2 = MrxTutorialManager
  L2_2 = L2_2.ShowMessage
  L3_2 = "[Tutorial.ObjectiveVerify.Key5]"
  L2_2(L3_2)
  L2_2 = A0_2._tEvents
  L3_2 = A0_2._tEvents
  L3_2 = L3_2.uActionEvent
  if not L3_2 then
    L3_2 = {}
  end
  L2_2.uActionEvent = L3_2
  L2_2 = Pg
  L2_2 = L2_2.AddContextAction
  L3_2 = A1_2
  L4_2 = "[ContextAction.Verify]"
  L5_2 = 5
  L6_2 = 0
  L7_2 = 0
  L8_2 = 0
  L9_2 = 0
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  L2_2 = A0_2._tEvents
  L2_2 = L2_2.uActionEvent
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ContextAction
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAnyCharacter
  L6_2 = L6_2()
  L7_2 = A1_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = A0_2._TargetActioned
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2[A1_2] = L3_2
end

_SetupVerify = L9_1

function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = NETEVENT_VERIFY
  if A0_2 == L2_2 then
    L2_2 = NetSafeTargetActioned
    L3_2 = A1_2[1]
    L4_2 = A1_2[2]
    L2_2(L3_2, L4_2)
  end
end

NetEventCallback = L9_1

function L9_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = Net
  L3_2 = L3_2.SendCustomEvent
  L4_2 = "MrxTaskObjectiveVerify"
  L5_2 = NETEVENT_VERIFY
  L6_2 = {}
  L7_2 = A1_2
  L8_2 = A2_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = NonNetSafeTargetActioned
  L4_2 = A0_2
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
end

_TargetActioned = L9_1

function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = A1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L5_2 = Object
  L5_2 = L5_2.GetPosition
  L6_2 = A0_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L8_2 = Math
  L8_2 = L8_2.GetXZHeading
  L9_2 = L2_2 - L5_2
  L10_2 = L3_2 - L6_2
  L11_2 = L4_2 - L7_2
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  L9_2 = Object
  L9_2 = L9_2.SetYaw
  L10_2 = A0_2
  L11_2 = L8_2
  L9_2(L10_2, L11_2)
  L9_2 = Player
  L9_2 = L9_2.GetCamera
  L10_2 = Object
  L10_2 = L10_2.IsPlayerControlled
  L11_2 = A0_2
  L10_2, L11_2, L12_2, L13_2, L14_2 = L10_2(L11_2)
  L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
  if L9_2 then
    L10_2 = Camera
    L10_2 = L10_2.SetYaw
    L11_2 = L9_2
    L12_2 = 0
    L10_2(L11_2, L12_2)
  end
  L10_2 = Pg
  L10_2 = L10_2.Spawn
  L11_2 = "Verification Camera"
  L12_2 = Object
  L12_2 = L12_2.GetPosition
  L13_2 = A0_2
  L12_2, L13_2, L14_2 = L12_2(L13_2)
  L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2)
  L11_2 = Object
  L11_2 = L11_2.Attach
  L12_2 = A0_2
  L13_2 = "bone_attach_lhand"
  L14_2 = L10_2
  L11_2(L12_2, L13_2, L14_2)
  L11_2 = Player
  L11_2 = L11_2.SetInputEnabled
  L12_2 = Object
  L12_2 = L12_2.IsPlayerControlled
  L13_2 = A0_2
  L12_2 = L12_2(L13_2)
  L13_2 = false
  L14_2 = true
  L11_2(L12_2, L13_2, L14_2)
  L11_2 = Human
  L11_2 = L11_2.DoAction
  L12_2 = A0_2
  L13_2 = "VerifyCamera"
  L11_2(L12_2, L13_2)
  L11_2 = Event
  L11_2 = L11_2.Create
  L12_2 = Event
  L12_2 = L12_2.TimerRelative
  L13_2 = {}
  L14_2 = 2
  L13_2[1] = L14_2
  L14_2 = flashAnimation
  L11_2 = L11_2(L12_2, L13_2, L14_2)
  FlashEvent = L11_2
  return L10_2
end

DoVerifyAnimation = L9_1

function L9_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  L3_2 = Event
  L3_2 = L3_2.Delete
  L4_2 = A2_2
  L3_2(L4_2)
end

Abort = L9_1

function L9_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = Sound
  L0_2 = L0_2.CueSound
  L1_2 = 0
  L2_2 = "ui_camera"
  L0_2(L1_2, L2_2)
  L0_2 = Pg
  L0_2 = L0_2.SpawnFromCamera
  L1_2 = "verify flash"
  L2_2 = 0
  L3_2 = 0
  L0_2(L1_2, L2_2, L3_2)
end

flashAnimation = L9_1

function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = DoVerifyAnimation
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.HumanActionComplete
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L6_2 = NetSafeTargetActionedComplete
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = L2_2
  L10_2 = Object
  L10_2 = L10_2.GetHealth
  L11_2 = A0_2
  L10_2, L11_2 = L10_2(L11_2)
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
end

NetSafeTargetActioned = L9_1

function L9_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L3_2 = DoVerifyAnimation
  L4_2 = A1_2
  L5_2 = A2_2
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = Pg
  L4_2 = L4_2.RemoveContextAction
  L5_2 = A2_2
  L4_2(L5_2)
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.HumanActionComplete
  L6_2 = {}
  L7_2 = A1_2
  L6_2[1] = L7_2
  L7_2 = A0_2._TargetActionedComplete
  L8_2 = {}
  L9_2 = A0_2
  L10_2 = A2_2
  L11_2 = A1_2
  L12_2 = L3_2
  L13_2 = Object
  L13_2 = L13_2.GetHealth
  L14_2 = A1_2
  L13_2, L14_2 = L13_2(L14_2)
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  L8_2[5] = L13_2
  L8_2[6] = L14_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
end

NonNetSafeTargetActioned = L9_1

function L9_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2
  L5_2 = MrxVerifyManager
  L5_2 = L5_2.UpdateTarget
  L6_2 = A1_2
  L7_2 = "killed"
  L5_2(L6_2, L7_2)
  A0_2.nCurrHVTState = nil
  L5_2 = MrxTutorialManager
  L5_2 = L5_2.HideMessage
  L5_2()
  A0_2._bIsVerified = true
  L6_2 = A0_2
  L5_2 = A0_2.GetConfig
  L5_2 = L5_2(L6_2)
  L6_2 = MrxUtil
  L6_2 = L6_2.ProcessCallbackTable
  L7_2 = L5_2.tOnTargetActioned
  L8_2 = {}
  L9_2 = A1_2
  L8_2[1] = L9_2
  L6_2(L7_2, L8_2)
  L6_2 = MrxUtil
  L6_2 = L6_2.CallWithOptionalArgs
  L7_2 = L5_2.fOnTargetActioned
  L8_2 = {}
  L9_2 = A1_2
  L8_2[1] = L9_2
  L6_2(L7_2, L8_2)
  L6_2 = Human
  L6_2 = L6_2.SetAllowCorpseCleanup
  L7_2 = A1_2
  L8_2 = true
  L6_2(L7_2, L8_2)
  if A3_2 then
    L6_2 = Object
    L6_2 = L6_2.Remove
    L7_2 = A3_2
    L6_2(L7_2)
    L6_2 = Object
    L6_2 = L6_2.EnablePhysics
    L7_2 = A2_2
    L6_2(L7_2)
    L6_2 = Player
    L6_2 = L6_2.SetInputEnabled
    L7_2 = Object
    L7_2 = L7_2.IsPlayerControlled
    L8_2 = A2_2
    L7_2 = L7_2(L8_2)
    L8_2 = true
    L9_2 = true
    L6_2(L7_2, L8_2, L9_2)
  end
  L6_2 = FlashEvent
  if L6_2 then
    L6_2 = Event
    L6_2 = L6_2.Delete
    L7_2 = FlashEvent
    L6_2(L7_2)
  end
  L6_2 = type
  L7_2 = A1_2
  L6_2 = L6_2(L7_2)
  if L6_2 == "userdata" then
    L7_2 = A0_2
    L6_2 = A0_2.RemoveTarget
    L8_2 = A1_2
    L6_2(L7_2, L8_2)
  end
  L7_2 = A0_2
  L6_2 = A0_2.CompletePart
  L8_2 = A1_2
  L9_2 = true
  L6_2(L7_2, L8_2, L9_2)
end

_TargetActionedComplete = L9_1

function L9_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  if A1_2 then
    L3_2 = Object
    L3_2 = L3_2.Remove
    L4_2 = A1_2
    L3_2(L4_2)
    L3_2 = Player
    L3_2 = L3_2.SetInputEnabled
    L4_2 = Object
    L4_2 = L4_2.IsPlayerControlled
    L5_2 = A0_2
    L4_2 = L4_2(L5_2)
    L5_2 = true
    L6_2 = true
    L3_2(L4_2, L5_2, L6_2)
  end
  L3_2 = FlashEvent
  if L3_2 then
    L3_2 = Event
    L3_2 = L3_2.Delete
    L4_2 = FlashEvent
    L3_2(L4_2)
  end
end

NetSafeTargetActionedComplete = L9_1

function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = L0_1
  A0_2.nCurrHVTState = L2_2
  L2_2 = MrxTutorialManager
  L2_2 = L2_2.ShowMessage
  L3_2 = "[Tutorial.ObjectiveVerify.Key6]"
  L2_2(L3_2)
  L2_2 = Pg
  L2_2 = L2_2.AddContextAction
  L3_2 = A1_2
  L4_2 = "[ContextAction.Subdue]"
  L5_2 = 2
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreatePersistentEvent
  L4_2 = Event
  L4_2 = L4_2.HumanStateTransition
  L5_2 = {}
  L6_2 = A1_2
  L7_2 = "*"
  L8_2 = "Subdued.Idle"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L6_2 = A0_2._TargetSubdued
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  A0_2._uSubdueEvent = L2_2
end

_TargetBashed = L9_1
L9_1 = {}
L10_1 = {}
L11_1 = "Allied NY_Richard01_Soldier_AI Subdual_x_x_x_x_x_01"
L12_1 = "Mirron01_Soldier_AI Subdual_x_x_x_x_x_01"
L13_1 = "Matt01_Soldier_AI Subdual_x_x_x_x_x_01"
L10_1[1] = L11_1
L10_1[2] = L12_1
L10_1[3] = L13_1
L9_1.Allied = L10_1
L10_1 = {}
L11_1 = "China Soldier_Ming01_Soldier_AI Subdual_x_x_x_x_x_01"
L10_1[1] = L11_1
L9_1.China = L10_1
L10_1 = {}
L11_1 = "VZSoldierArc_Zev01_Soldier_AI Subdual_x_x_x_x_x_01"
L12_1 = "VZSoldierArc_Zev01_VZ Soldier_AI Subdual_x_x_x_x_x_08"
L10_1[1] = L11_1
L10_1[2] = L12_1
L9_1.Guerilla = L10_1
L10_1 = {}
L11_1 = "Generic OC Soldier_Keith01_Soldier_AI Subdual_x_x_x_x_x_01"
L12_1 = "Generic OC Soldier_Derek01_Soldier_AI Subdual_x_x_x_x_x_01"
L10_1[1] = L11_1
L10_1[2] = L12_1
L9_1.OC = L10_1
L10_1 = {}
L11_1 = "Pirate Thug_Jonell01_Soldier_AI Subdual_x_x_x_x_x_01"
L12_1 = "Pirate Thug_Darryl01_Soldier_AI Subdual_x_x_x_x_x_01"
L10_1[1] = L11_1
L10_1[2] = L12_1
L9_1.Pirate = L10_1
L10_1 = {}
L11_1 = "VZSoldierArc_Zev01_Soldier_AI Subdual_x_x_x_x_x_01"
L12_1 = "VZSoldierArc_Zev01_VZ Soldier_AI Subdual_x_x_x_x_x_08"
L10_1[1] = L11_1
L10_1[2] = L12_1
L9_1.VZ = L10_1
_tSubduedVO = L9_1

function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = _TargetIntoSubdued
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = Pg
  L2_2 = L2_2.RemoveContextAction
  L3_2 = A1_2
  L2_2(L3_2)
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = MrxUtil
  L3_2 = L3_2.GetFaction
  L4_2 = A1_2
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  if L2_2 then
    L3_2 = Ai
    L3_2 = L3_2.AddInfraction
    L4_2 = Player
    L4_2 = L4_2.GetPrimaryCharacter
    L4_2 = L4_2()
    L5_2 = L2_2
    L6_2 = 5
    L3_2(L4_2, L5_2, L6_2)
    L3_2 = Player
    L3_2 = L3_2.GetSecondaryCharacter
    L3_2 = L3_2()
    if L3_2 then
      L3_2 = Ai
      L3_2 = L3_2.AddInfraction
      L4_2 = Player
      L4_2 = L4_2.GetSecondaryCharacter
      L4_2 = L4_2()
      L5_2 = L2_2
      L6_2 = 5
      L3_2(L4_2, L5_2, L6_2)
    else
    end
  end
  L3_2 = Sys
  L3_2 = L3_2.IsGermanSKU
  L3_2 = L3_2()
  if L3_2 then
    L3_2 = _TargetExtracted
    L4_2 = A0_2
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
  else
    L3_2 = Pg
    L3_2 = L3_2.AddContextAction
    L4_2 = A1_2
    L5_2 = "[ContextAction.Carry]"
    L6_2 = 2
    L3_2(L4_2, L5_2, L6_2)
    L3_2 = A0_2._tEvents
    L3_2 = L3_2.uStowEvent
    if L3_2 then
      L3_2 = A0_2._tEvents
      L3_2 = L3_2.uStowEvent
      L3_2 = L3_2[A1_2]
      if L3_2 then
        return
      end
    end
    L4_2 = A0_2
    L3_2 = A0_2._AddSupport
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
    L3_2 = Object
    L3_2 = L3_2.AddLabel
    L4_2 = A1_2
    L5_2 = "Prisoner"
    L3_2(L4_2, L5_2)
    L3_2 = A0_2._tEvents
    L4_2 = A0_2._tEvents
    L4_2 = L4_2.uStowEvent
    if not L4_2 then
      L4_2 = {}
    end
    L3_2.uStowEvent = L4_2
    L3_2 = A0_2._tEvents
    L3_2 = L3_2.uStowEvent
    L4_2 = Event
    L4_2 = L4_2.Create
    L5_2 = Event
    L5_2 = L5_2.ObjectInSeat
    L6_2 = {}
    L7_2 = A1_2
    L8_2 = "ExtractionHelicopter"
    L9_2 = "a"
    L10_2 = "e"
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L6_2[4] = L10_2
    L7_2 = _TargetExtracted
    L8_2 = {}
    L9_2 = A0_2
    L10_2 = A1_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
    L3_2[A1_2] = L4_2
  end
  L4_2 = A0_2
  L3_2 = A0_2.GetConfig
  L3_2 = L3_2(L4_2)
  L4_2 = MrxUtil
  L4_2 = L4_2.ProcessCallbackTable
  L5_2 = L3_2.tOnTargetSubdued
  L6_2 = {}
  L7_2 = A1_2
  L6_2[1] = L7_2
  L4_2(L5_2, L6_2)
  L4_2 = MrxUtil
  L4_2 = L4_2.CallWithOptionalArgs
  L5_2 = L3_2.fOnTargetSubdued
  L6_2 = {}
  L7_2 = A1_2
  L6_2[1] = L7_2
  L4_2(L5_2, L6_2)
end

_TargetSubdued = L9_1

function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  A0_2._bIsVerified = true
  A0_2.nCurrHVTState = nil
  L2_2 = MrxTutorialManager
  L2_2 = L2_2.HideMessage
  L2_2()
  L2_2 = MrxVerifyManager
  L2_2 = L2_2.UpdateTarget
  L3_2 = A1_2
  L4_2 = "captured"
  L2_2(L3_2, L4_2)
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if L2_2 == "userdata" then
    L3_2 = A0_2
    L2_2 = A0_2.RemoveTarget
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  end
  L2_2 = A0_2._tEvents
  L2_2 = L2_2.uStowEvent
  if L2_2 then
    L2_2 = A0_2._tEvents
    L2_2 = L2_2.uStowEvent
    L2_2[A1_2] = nil
    L3_2 = A0_2
    L2_2 = A0_2._RemoveSupport
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  end
  L3_2 = A0_2
  L2_2 = A0_2.CompletePart
  L4_2 = A1_2
  L5_2 = false
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = Object
  L2_2 = L2_2.FadeOut
  L3_2 = A1_2
  L4_2 = 0.25
  L5_2 = true
  L2_2(L3_2, L4_2, L5_2)
end

_TargetExtracted = L9_1

function L9_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = pairs
  L4_2 = tActiveHelicopters
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    if L6_2 and L7_2 then
      L8_2 = MrxSupportPickup
      L8_2 = L8_2.GoHome
      L9_2 = L7_2
      L10_2 = L6_2
      L8_2(L9_2, L10_2)
    end
  end
  L3_2 = {}
  tActiveHelicopters = L3_2
  L4_2 = A0_2
  L3_2 = A0_2.GetConfig
  L3_2 = L3_2(L4_2)
  L4_2 = MrxSupportData
  L4_2 = L4_2.RemoveFreebie
  L5_2 = _GetSupportByFaction
  L6_2 = L3_2.sFactionId
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L5_2(L6_2)
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  L4_2 = L7_1
  L5_2 = L3_2.sFactionId
  L4_2[L5_2] = nil
  L4_2 = A0_2._AttitudeChangeEvent
  if L4_2 then
    L4_2 = Event
    L4_2 = L4_2.Delete
    L5_2 = A0_2._AttitudeChangeEvent
    L4_2(L5_2)
  end
  L4_2 = MrxFactionManager
  L4_2 = L4_2.CreatePersistentAttitudeChangeEvent
  L5_2 = {}
  L6_2 = L3_2.sFactionId
  L7_2 = "Pmc"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  
  function L6_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = MrxFactionManager
    L0_3 = L0_3.GetAttitudeLabel
    L1_3 = A2_2
    L2_3 = "Pmc"
    L0_3 = L0_3(L1_3, L2_3)
    if L0_3 ~= "Hostile" then
      L0_3 = _AddSupport
      L1_3 = A0_2
      L2_3 = A1_2
      L0_3(L1_3, L2_3)
      L0_3 = _SetNonHostileAttitudeChangeEvent
      L1_3 = A0_2
      L2_3 = A1_2
      L3_3 = A2_2
      L0_3(L1_3, L2_3, L3_3)
    end
  end
  
  L7_2 = {}
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  A0_2._AttitudeChangeEvent = L4_2
end

_SetHostileAttitudeChangeEvent = L9_1

function L9_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L4_2 = A0_2
  L3_2 = A0_2.GetConfig
  L3_2 = L3_2(L4_2)
  L4_2 = MrxSupportData
  L4_2 = L4_2.AddFreebie
  L5_2 = _GetSupportByFaction
  L6_2 = L3_2.sFactionId
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = L7_1
  L5_2 = L3_2.sFactionId
  L4_2[L5_2] = true
  L4_2 = A0_2._AttitudeChangeEvent
  if L4_2 then
    L4_2 = Event
    L4_2 = L4_2.Delete
    L5_2 = A0_2._AttitudeChangeEvent
    L4_2(L5_2)
  end
  L4_2 = MrxFactionManager
  L4_2 = L4_2.CreatePersistentAttitudeChangeEvent
  L5_2 = {}
  L6_2 = L3_2.sFactionId
  L7_2 = "Pmc"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  
  function L6_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = MrxFactionManager
    L0_3 = L0_3.GetAttitudeLabel
    L1_3 = A2_2
    L2_3 = "Pmc"
    L0_3 = L0_3(L1_3, L2_3)
    if L0_3 == "Hostile" then
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._RemoveSupport
      L2_3 = A1_2
      L0_3(L1_3, L2_3)
      L0_3 = _SetHostileAttitudeChangeEvent
      L1_3 = A0_2
      L2_3 = A1_2
      L3_3 = A2_2
      L0_3(L1_3, L2_3, L3_3)
    end
  end
  
  L7_2 = {}
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  A0_2._AttitudeChangeEvent = L4_2
end

_SetNonHostileAttitudeChangeEvent = L9_1

function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2._nSupportCount
  L2_2 = L2_2 + 1
  A0_2._nSupportCount = L2_2
  L2_2 = L8_1
  L2_2 = L2_2[A1_2]
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = L8_1
    L3_2 = L3_2[A1_2]
    L2_2(L3_2)
    L2_2 = L8_1
    L2_2[A1_2] = nil
  end
  L2_2 = A0_2._nSupportCount
  if L2_2 == 1 then
    L3_2 = A0_2
    L2_2 = A0_2.GetConfig
    L2_2 = L2_2(L3_2)
    L3_2 = MrxSupportData
    L3_2 = L3_2.AddFreebie
    L4_2 = _GetSupportByFaction
    L5_2 = L2_2.sFactionId
    L4_2, L5_2 = L4_2(L5_2)
    L3_2(L4_2, L5_2)
    L3_2 = L7_1
    L4_2 = L2_2.sFactionId
    L3_2[L4_2] = true
    L4_2 = A0_2
    L3_2 = A0_2._CreateDistanceEvent
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
  end
end

_AddSupport = L9_1

function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2._nSupportCount
  L2_2 = L2_2 - 1
  A0_2._nSupportCount = L2_2
  L2_2 = Math
  L2_2 = L2_2.max
  L3_2 = A0_2._nSupportCount
  L4_2 = 0
  L2_2 = L2_2(L3_2, L4_2)
  A0_2._nSupportCount = L2_2
  L2_2 = L8_1
  L2_2 = L2_2[A1_2]
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = L8_1
    L3_2 = L3_2[A1_2]
    L2_2(L3_2)
    L2_2 = L8_1
    L2_2[A1_2] = nil
  end
  L2_2 = A0_2._nSupportCount
  if L2_2 == 0 then
    L2_2 = A0_2._AttitudeChangeEvent
    if L2_2 then
    end
    L2_2 = pairs
    L3_2 = tActiveHelicopters
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2, L6_2 in L2_2, L3_2, L4_2 do
      if L5_2 and L6_2 then
        L7_2 = MrxSupportPickup
        L7_2 = L7_2.GoHome
        L8_2 = L6_2
        L9_2 = L5_2
        L7_2(L8_2, L9_2)
      end
    end
    L2_2 = {}
    tActiveHelicopters = L2_2
    L3_2 = A0_2
    L2_2 = A0_2.GetConfig
    L2_2 = L2_2(L3_2)
    L3_2 = MrxSupportData
    L3_2 = L3_2.RemoveFreebie
    L4_2 = _GetSupportByFaction
    L5_2 = L2_2.sFactionId
    L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L4_2(L5_2)
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
    L3_2 = L7_1
    L4_2 = L2_2.sFactionId
    L3_2[L4_2] = nil
  end
end

_RemoveSupport = L9_1

function L9_1(A0_2)
  local L1_2, L2_2
  L1_2 = {}
  L1_2.All = "Extraction_AL"
  L1_2.Chi = "Extraction_CH"
  L1_2.Gur = "Extraction_GR"
  L1_2.Oil = "Extraction_OC"
  L1_2.Pmc = "Extraction_PMC"
  L1_2.Pir = "Extraction_PR"
  L2_2 = L1_2[A0_2]
  if not L2_2 then
    L2_2 = L1_2.Pmc
  end
  return L2_2
end

_GetSupportByFaction = L9_1

function L9_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = Net
  L0_2 = L0_2.IsServer
  L0_2 = L0_2()
  if not L0_2 then
    return
  end
  L0_2 = pairs
  L1_2 = L7_1
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    if L4_2 then
      L5_2 = MrxSupportData
      L5_2 = L5_2.AddFreebie
      L6_2 = _GetSupportByFaction
      L7_2 = L3_2
      L6_2 = L6_2(L7_2)
      L7_2 = nil
      L8_2 = Player
      L8_2 = L8_2.GetSecondaryPlayer
      L8_2 = L8_2()
      L5_2(L6_2, L7_2, L8_2)
    end
  end
end

SendPlayerJoinEvents = L9_1

function L9_1()
  local L0_2, L1_2
  L0_2 = "[Generic.ObjectiveVerify]"
  return L0_2
end

_GetShortDescription = L9_1

function L9_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2.bOptional
  if L2_2 then
    L2_2 = "[objverify2]"
    return L2_2
  else
    L2_2 = "[objverify]"
    return L2_2
  end
end

GetInlineIcon = L9_1

function L9_1()
  local L0_2, L1_2
  L0_2 = true
  return L0_2
end

_GetJust2DCheckNeeded = L9_1

function L9_1()
  local L0_2, L1_2
  L0_2 = "objective_verify"
  return L0_2
end

_GetTargetRadarIcon = L9_1

function L9_1(A0_2)
  local L1_2
  if A0_2 then
    L1_2 = "icon_verify_2_mc"
    return L1_2
  else
    L1_2 = "icon_verify_1_mc"
    return L1_2
  end
end

_GetTargetPdaIcon = L9_1

function L9_1()
  local L0_2, L1_2
  L0_2 = "HUD_objective_verify"
  return L0_2
end

_GetTargetGameSpaceIcon = L9_1

function L9_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Player
  L1_2 = L1_2.GetAnyCharacter
  L1_2 = L1_2()
  L2_2 = Player
  L2_2 = L2_2.GetAllCharacters
  L2_2 = L2_2()
  if L1_2 == A0_2 then
    L3_2 = true
    return L3_2
  end
  if L2_2 == A0_2 then
    L3_2 = true
    return L3_2
  end
  L3_2 = Object
  L3_2 = L3_2.IsAlive
  L4_2 = A0_2
  return L3_2(L4_2)
end

_IsValidTarget = L9_1

function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = L8_1
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAllCharacters
  L6_2 = L6_2()
  L7_2 = A1_2
  L8_2 = ">"
  L9_2 = 150
  L10_2 = false
  L11_2 = true
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = _OnHVTOutOfRange
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A1_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2[A1_2] = L3_2
end

_CreateDistanceEvent = L9_1

function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = A0_2
  L2_2 = A0_2._RemoveSupport
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
  L2_2 = L8_1
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAnyCharacter
  L6_2 = L6_2()
  L7_2 = A1_2
  L8_2 = "<"
  L9_2 = 140
  L10_2 = false
  L11_2 = true
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = _AddSupport
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A1_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2[A1_2] = L3_2
end

_OnHVTOutOfRange = L9_1
