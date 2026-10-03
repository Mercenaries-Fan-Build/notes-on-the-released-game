local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskObjective"
L0_1(L1_1)

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxTaskObjective
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = A0_2._tEvents
  L2_2 = Event
  L2_2 = L2_2.CreatePersistent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = A0_2._uTgtObjFilter
  L4_2[1] = L5_2
  L5_2 = _TargetDestroyed
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.uDeathEvent = L2_2
  L1_2 = A0_2._tEvents
  L2_2 = Event
  L2_2 = L2_2.CreatePersistent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "ClientKill"
  
  function L6_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = ObjectFilter
    L1_3 = L1_3.Eval
    L2_3 = A0_2
    L2_3 = L2_3._uTgtObjFilter
    L3_3 = A0_3[1]
    L1_3 = L1_3(L2_3, L3_3)
    return L1_3
  end
  
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  
  function L5_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = A0_2
    L2_3 = L1_3
    L1_3 = L1_3.RemoveTarget
    L3_3 = A0_3[1]
    L1_3(L2_3, L3_3)
    L1_3 = A0_2
    L2_3 = L1_3
    L1_3 = L1_3.CompletePart
    L3_3 = A0_3[1]
    L1_3(L2_3, L3_3)
  end
  
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  L1_2.uClientKill = L2_2
end

Activated = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L5_2 = A0_2
  L4_2 = A0_2.GetConfig
  L4_2 = L4_2(L5_2)
  L5_2 = L4_2.bHeroOnly
  if L5_2 then
    L5_2 = type
    L6_2 = A1_2
    L5_2 = L5_2(L6_2)
    if L5_2 == "userdata" then
      L5_2 = ipairs
      L6_2 = Player
      L6_2 = L6_2.GetAllPlayers
      L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L6_2()
      L5_2, L6_2, L7_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
      for L8_2, L9_2 in L5_2, L6_2, L7_2 do
        L10_2 = Player
        L10_2 = L10_2.GetCharacter
        L11_2 = L9_2
        L10_2 = L10_2(L11_2)
        if L10_2 == A3_2 then
          L12_2 = A0_2
          L11_2 = A0_2.RemoveTarget
          L13_2 = A1_2
          L11_2(L12_2, L13_2)
          L12_2 = A0_2
          L11_2 = A0_2.CompletePart
          L13_2 = A1_2
          L11_2(L12_2, L13_2)
        end
      end
  end
  else
    L5_2 = type
    L6_2 = A1_2
    L5_2 = L5_2(L6_2)
    if L5_2 == "userdata" then
      L6_2 = A0_2
      L5_2 = A0_2.RemoveTarget
      L7_2 = A1_2
      L5_2(L6_2, L7_2)
      L6_2 = A0_2
      L5_2 = A0_2.CompletePart
      L7_2 = A1_2
      L5_2(L6_2, L7_2)
    end
  end
end

_TargetDestroyed = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = "[Generic.ObjectiveDestroy]"
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
    L2_2 = "[objdestroy2]"
    return L2_2
  else
    L2_2 = "[objdestroy]"
    return L2_2
  end
end

GetInlineIcon = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = "objective_destroy"
  return L0_2
end

_GetTargetRadarIcon = L0_1

function L0_1(A0_2)
  local L1_2
  if A0_2 then
    L1_2 = "icon_destroy_2_mc"
    return L1_2
  else
    L1_2 = "icon_destroy_1_mc"
    return L1_2
  end
end

_GetTargetPdaIcon = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = "HUD_objective_destroy"
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
