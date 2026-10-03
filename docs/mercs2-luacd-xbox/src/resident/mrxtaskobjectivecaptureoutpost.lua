local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskObjective"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxOutpostManager"
L0_1(L1_1)

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxTaskObjective
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2.uOutpostBldg
  if L2_2 then
    L3_2 = MrxOutpostManager
    L3_2 = L3_2.RegisterOutpostEvent
    L4_2 = L2_2
    L5_2 = A0_2._HandleOutpostStatusChange
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L3_2(L4_2, L5_2, L6_2)
  end
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2.uOutpostBldg
  if L2_2 then
    L3_2 = MrxOutpostManager
    L3_2 = L3_2.UnregisterOutpost
    L4_2 = L2_2
    L3_2(L4_2)
  end
  L3_2 = MrxTaskObjective
  L3_2 = L3_2.Cleanup
  L4_2 = A0_2
  L3_2(L4_2)
end

Cleanup = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  L3_2 = MrxOutpostManager
  L3_2 = L3_2.knStatusCaptured
  if A2_2 == L3_2 then
    L4_2 = A0_2
    L3_2 = A0_2.RemoveTarget
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
    L4_2 = A0_2
    L3_2 = A0_2.CompletePart
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
  else
    L3_2 = MrxOutpostManager
    L3_2 = L3_2.knStatusDestroyed
    if A2_2 == L3_2 then
      L4_2 = A0_2
      L3_2 = A0_2.RemoveTarget
      L5_2 = A1_2
      L3_2(L4_2, L5_2)
      L4_2 = A0_2
      L3_2 = A0_2.CancelPart
      L5_2 = A1_2
      L3_2(L4_2, L5_2)
    end
  end
end

_HandleOutpostStatusChange = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = "[Generic.ObjectiveOutpost]"
  return L0_2
end

_GetShortDescription = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2.bOptional
  if L2_2 then
    L2_2 = "[objoutpost2]"
    return L2_2
  else
    L2_2 = "[objoutpost]"
    return L2_2
  end
end

GetInlineIcon = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = "objective_outpost"
  return L0_2
end

_GetTargetRadarIcon = L0_1

function L0_1(A0_2)
  local L1_2
  if A0_2 then
    L1_2 = "icon_outpost_2_mc"
    return L1_2
  else
    L1_2 = "icon_outpost_1_mc"
    return L1_2
  end
end

_GetTargetPdaIcon = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = "HUD_objective_outpost"
  return L0_2
end

_GetTargetGameSpaceIcon = L0_1
