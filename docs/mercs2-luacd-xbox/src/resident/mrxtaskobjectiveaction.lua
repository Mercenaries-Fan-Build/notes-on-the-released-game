local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskObjective"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxTaskObjective
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._PrepTargets
  L1_2(L2_2)
  L1_2 = A0_2._tEvents
  L2_2 = Event
  L2_2 = L2_2.CreatePersistent
  L3_2 = Event
  L3_2 = L3_2.ContextAction
  L4_2 = {}
  L5_2 = 0
  L6_2 = A0_2._uTgtObjFilter
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = A0_2._TargetActioned
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.uActionEvent = L2_2
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
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = L1_2.sActionLabel
  L4_2 = "[ContextAction.Talk]"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = ObjectFilter
  L3_2 = L3_2.GetObjects
  L4_2 = A0_2._uTgtObjFilter
  L5_2 = false
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = ipairs
  L5_2 = L3_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = Pg
    L9_2 = L9_2.AddContextAction
    L10_2 = L8_2
    L11_2 = L2_2
    L12_2 = 2
    L13_2 = 0
    L14_2 = 200
    L15_2 = 0
    L16_2 = 2
    L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
  end
end

_PrepTargets = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = Pg
  L3_2 = L3_2.RemoveContextAction
  L4_2 = A2_2
  L3_2 = L3_2(L4_2)
  L4_2 = type
  L5_2 = A2_2
  L4_2 = L4_2(L5_2)
  if L4_2 == "userdata" then
    L5_2 = A0_2
    L4_2 = A0_2.RemoveTarget
    L6_2 = A2_2
    L4_2(L5_2, L6_2)
  end
  L5_2 = A0_2
  L4_2 = A0_2.CompletePart
  L6_2 = A1_2
  L7_2 = A2_2
  L4_2(L5_2, L6_2, L7_2)
end

_TargetActioned = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = Pg
  L2_2 = L2_2.RemoveContextAction
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  L3_2 = type
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if L3_2 == "userdata" then
    L4_2 = A0_2
    L3_2 = A0_2.RemoveTarget
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
  end
  L4_2 = A0_2
  L3_2 = A0_2.CancelPart
  L3_2(L4_2)
end

_TargetDestroyed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = ObjectFilter
  L1_2 = L1_2.GetObjects
  L2_2 = A0_2._uTgtObjFilter
  L3_2 = false
  L1_2 = L1_2(L2_2, L3_2)
  L2_2 = ipairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = Pg
    L7_2 = L7_2.RemoveContextAction
    L8_2 = L6_2
    L7_2(L8_2)
  end
  L2_2 = MrxTaskObjective
  L2_2 = L2_2.Cleanup
  L3_2 = A0_2
  L2_2(L3_2)
end

Cleanup = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = "[Generic.ObjectiveAction]"
  return L0_2
end

_GetShortDescription = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = "objective_action"
  return L0_2
end

_GetTargetRadarIcon = L0_1

function L0_1(A0_2)
  local L1_2
  if A0_2 then
    L1_2 = "icon_action_2_mc"
    return L1_2
  else
    L1_2 = "icon_action_1_mc"
    return L1_2
  end
end

_GetTargetPdaIcon = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = "HUD_objective_action"
  return L0_2
end

_GetTargetGameSpaceIcon = L0_1

function L0_1(A0_2)
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

_IsValidTarget = L0_1
