local L0_1, L1_1
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = tEvents
if not L0_1 then
  L0_1 = {}
end
tEvents = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = tEvents
  L2_2 = tEvents
  L2_2 = L2_2[A0_2]
  if not L2_2 then
    L2_2 = {}
  end
  L1_2[A0_2] = L2_2
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.ObjectHibernation
  L3_2 = {}
  L4_2 = A0_2
  L5_2 = "awake"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  
  function L4_2()
    local L0_3, L1_3
    L0_3 = SetupGoal
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L1_2(L2_2, L3_2, L4_2)
end

OnActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = tEvents
  if not L1_2 then
    L1_2 = {}
  end
  tEvents = L1_2
  L1_2 = tEvents
  L2_2 = tEvents
  L2_2 = L2_2[A0_2]
  if not L2_2 then
    L2_2 = {}
  end
  L1_2[A0_2] = L2_2
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  L1_2 = L1_2.GoalVO
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = tEvents
    L2_2 = L2_2[A0_2]
    L2_2 = L2_2.GoalVO
    L1_2(L2_2)
    L1_2 = tEvents
    L1_2 = L1_2[A0_2]
    L1_2.GoalVO = nil
  end
  L1_2 = tEvents
  L1_2[A0_2] = nil
end

OnDeactivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "LR_Goal"
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = tEvents
    L1_2 = L1_2[A0_2]
    L2_2 = Event
    L2_2 = L2_2.Create
    L3_2 = Event
    L3_2 = L3_2.Boundary
    L4_2 = {}
    L5_2 = A0_2
    L6_2 = Pg
    L6_2 = L6_2.GetGuidByName
    L7_2 = "LR_Goal"
    L6_2 = L6_2(L7_2)
    L7_2 = "enter"
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L4_2[3] = L7_2
    
    function L5_2()
      local L0_3, L1_3, L2_3
      L0_3 = Pg
      L0_3 = L0_3.GetGuidByName
      L1_3 = "_global_soccergoal 0x000b0982"
      L0_3 = L0_3(L1_3)
      if L0_3 then
        L0_3 = MrxVoSequence
        L0_3 = L0_3.Start
        L1_3 = {}
        L2_3 = "Fiona.va3fio12"
        L1_3[1] = L2_3
        L0_3(L1_3)
        L0_3 = MrxPmc
        L0_3 = L0_3.AddCashQty
        L1_3 = 100000
        L0_3(L1_3)
        L0_3 = Object
        L0_3 = L0_3.Remove
        L1_3 = Pg
        L1_3 = L1_3.GetGuidByName
        L2_3 = "LR_Goal"
        L1_3, L2_3 = L1_3(L2_3)
        L0_3(L1_3, L2_3)
      end
    end
    
    L2_2 = L2_2(L3_2, L4_2, L5_2)
    L1_2.GoalVO = L2_2
  end
end

SetupGoal = L0_1
