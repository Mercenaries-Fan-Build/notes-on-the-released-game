local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskObjectiveAction"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = 100
_knTgtNearbyRadius = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxTaskObjectiveAction
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateNearbyEvent
  L1_2(L2_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2
end

_PrepTargets = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L3_2 = MrxTaskObjectiveAction
  L3_2 = L3_2._TargetActioned
  L4_2 = A0_2
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = Human
  L3_2 = L3_2.SetState
  L4_2 = A2_2
  L5_2 = "Upright"
  L6_2 = "Idle"
  L3_2(L4_2, L5_2, L6_2)
  L4_2 = A0_2
  L3_2 = A0_2.GetConfig
  L3_2 = L3_2(L4_2)
  L4_2 = L3_2.oParent
  L5_2 = L4_2
  L4_2 = L4_2.GetConfig
  L4_2 = L4_2(L5_2)
  L3_2 = L4_2
  L4_2 = L3_2.tMaterielScale
  if L4_2 then
    L4_2 = pairs
    L5_2 = L3_2.tMaterielScale
    L4_2, L5_2, L6_2 = L4_2(L5_2)
    for L7_2, L8_2 in L4_2, L5_2, L6_2 do
      L9_2 = MrxFactionManager
      L9_2 = L9_2.GetFactionTemplateName
      L10_2 = L7_2
      L9_2 = L9_2(L10_2)
      L10_2 = Pg
      L10_2 = L10_2.GetGuidByName
      L11_2 = L9_2
      L10_2 = L10_2(L11_2)
      if L10_2 then
        L11_2 = Ai
        L11_2 = L11_2.AddInfraction
        L12_2 = A1_2
        L13_2 = L10_2
        L14_2 = 5
        L11_2(L12_2, L13_2, L14_2)
        L11_2 = Ai
        L11_2 = L11_2.SetRelation
        L12_2 = L10_2
        L13_2 = A2_2
        L14_2 = -100
        L11_2(L12_2, L13_2, L14_2)
      else
      end
    end
  end
end

_TargetActioned = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = "[Generic.ObjectiveRelease]"
  return L0_2
end

_GetShortDescription = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = ObjectFilter
  L1_2 = L1_2.Copy
  L3_2 = A0_2
  L2_2 = A0_2.GetTargetObjectFilter
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  A0_2._uFarTgtFilter = L1_2
  L1_2 = ObjectFilter
  L1_2 = L1_2.RemoveObject
  L2_2 = A0_2._uFarTgtFilter
  L3_2 = Player
  L3_2 = L3_2.GetAnyCharacter
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L3_2()
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  L1_2 = ObjectFilter
  L1_2 = L1_2.RemoveObject
  L2_2 = A0_2._uFarTgtFilter
  L3_2 = Player
  L3_2 = L3_2.GetAllCharacters
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L3_2()
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreatePersistentEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = A0_2._uFarTgtFilter
  L6_2 = Player
  L6_2 = L6_2.GetLocalCharacter
  L6_2 = L6_2()
  L7_2 = "<"
  L8_2 = _knTgtNearbyRadius
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = A0_2._TargetNearby
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

_CreateNearbyEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L2_2 = ipairs
  L3_2 = A1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L8_2 = A0_2
    L7_2 = A0_2.GetConfig
    L7_2 = L7_2(L8_2)
    L8_2 = L7_2.oParent
    L9_2 = L8_2
    L8_2 = L8_2.GetConfig
    L8_2 = L8_2(L9_2)
    L7_2 = L8_2
    L8_2 = L7_2.tMaterielScale
    if L8_2 then
      L8_2 = pairs
      L9_2 = L7_2.tMaterielScale
      L8_2, L9_2, L10_2 = L8_2(L9_2)
      for L11_2, L12_2 in L8_2, L9_2, L10_2 do
        L13_2 = MrxFactionManager
        L13_2 = L13_2.GetFactionTemplateName
        L14_2 = L11_2
        L13_2 = L13_2(L14_2)
        L14_2 = Pg
        L14_2 = L14_2.GetGuidByName
        L15_2 = L13_2
        L14_2 = L14_2(L15_2)
        if L14_2 then
          L15_2 = Ai
          L15_2 = L15_2.SetRelation
          L16_2 = L14_2
          L17_2 = L6_2
          L18_2 = 0
          L15_2(L16_2, L17_2, L18_2)
        else
        end
      end
    end
    L8_2 = Human
    L8_2 = L8_2.SetState
    L9_2 = L6_2
    L10_2 = "Subdued"
    L11_2 = "Idle"
    L8_2(L9_2, L10_2, L11_2)
    L8_2 = Pg
    L8_2 = L8_2.RemoveContextAction
    L9_2 = L6_2
    L8_2(L9_2)
    L9_2 = A0_2
    L8_2 = A0_2.GetConfig
    L8_2 = L8_2(L9_2)
    L9_2 = "[ContextAction.ReleasePrisoner]"
    L10_2 = Pg
    L10_2 = L10_2.AddContextAction
    L11_2 = L6_2
    L12_2 = L9_2
    L13_2 = 2
    L14_2 = 0
    L15_2 = 200
    L16_2 = 0
    L17_2 = 2
    L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
    L11_2 = ObjectFilter
    L11_2 = L11_2.RemoveObject
    L12_2 = A0_2._uFarTgtFilter
    L13_2 = L6_2
    L11_2(L12_2, L13_2)
    L12_2 = A0_2
    L11_2 = A0_2._CreateFarawayEvent
    L13_2 = L6_2
    L11_2(L12_2, L13_2)
  end
end

_TargetNearby = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = A1_2
  L7_2 = Player
  L7_2 = L7_2.GetLocalCharacter
  L7_2 = L7_2()
  L8_2 = ">"
  L9_2 = _knTgtNearbyRadius
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L6_2 = A0_2._TargetFaraway
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A1_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

_CreateFarawayEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = ObjectFilter
  L2_2 = L2_2.AddObject
  L3_2 = A0_2._uFarTgtFilter
  L4_2 = A1_2
  L5_2 = false
  L2_2(L3_2, L4_2, L5_2)
end

_TargetFaraway = L0_1
