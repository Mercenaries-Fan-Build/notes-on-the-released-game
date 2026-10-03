local L0_1, L1_1
L0_1 = inherit
L1_1 = "Inheritable"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = Object
  L3_2 = L3_2.IsAlive
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    return
  end
  L3_2 = getfenv
  L3_2 = L3_2()
  L5_2 = L3_2
  L4_2 = L3_2.Create
  L6_2 = A0_2
  L7_2 = A1_2
  L4_2 = L4_2(L5_2, L6_2, L7_2)
end

OnActivate = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = Inheritable
  L3_2 = L3_2.Create
  L4_2 = A0_2
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L4_2 = Object
  L4_2 = L4_2.IsAlive
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    return L3_2
  end
  L4_2 = Object
  L4_2 = L4_2.HasLabel
  L5_2 = A1_2
  L6_2 = "CollectableInvalidated"
  L4_2 = L4_2(L5_2, L6_2)
  if L4_2 then
    L4_2 = Object
    L4_2 = L4_2.SetHibernationDistance
    L5_2 = A1_2
    L6_2 = 1.0E-6
    L4_2(L5_2, L6_2)
    L4_2 = Object
    L4_2 = L4_2.Kill
    L5_2 = A1_2
    L4_2(L5_2)
    return L3_2
  end
  L4_2 = Pg
  L4_2 = L4_2.AddContextAction
  L5_2 = A1_2
  L6_2 = "[ContextAction.Toolbox]"
  L7_2 = 2
  L8_2 = 0
  L9_2 = 0
  L10_2 = 0
  L11_2 = 0
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  L4_2 = Event
  L4_2 = L4_2.CreatePersistent
  L5_2 = Event
  L5_2 = L5_2.ContextAction
  L6_2 = {}
  L7_2 = Player
  L7_2 = L7_2.GetAnyCharacter
  L7_2 = L7_2()
  L8_2 = A1_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = L3_2.OnContextAction
  L8_2 = {}
  L9_2 = L3_2
  L8_2[1] = L9_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L3_2.uEvent = L4_2
  return L3_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.uEvent
  L1_2(L2_2)
  L1_2 = Pg
  L1_2 = L1_2.RemoveContextAction
  L2_2 = A0_2.uGuid
  L1_2(L2_2)
  L1_2 = Inheritable
  L1_2 = L1_2.Delete
  L2_2 = A0_2
  L1_2(L2_2)
end

Delete = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = Object
  L2_2 = L2_2.Kill
  L3_2 = A0_2.uGuid
  L2_2(L3_2)
end

OnContextAction = L0_1
