local L0_1, L1_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = A0_2.AIGuid
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Create
    L2_2 = Event
    L2_2 = L2_2.ObjectHibernation
    L3_2 = {}
    L4_2 = A0_2.AIGuid
    L5_2 = "awake"
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    
    function L4_2()
      local L0_3, L1_3
      L0_3 = Ai
      L0_3 = L0_3.Goal
      L1_3 = A0_2
      L0_3(L1_3)
    end
    
    L1_2(L2_2, L3_2, L4_2)
  end
end

Goal = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = A0_2.AIGuid
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Create
    L2_2 = Event
    L2_2 = L2_2.ObjectHibernation
    L3_2 = {}
    L4_2 = A0_2.AIGuid
    L5_2 = "awake"
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    
    function L4_2()
      local L0_3, L1_3
      L0_3 = Ai
      L0_3 = L0_3.DefaultGoal
      L1_3 = A0_2
      L0_3(L1_3)
    end
    
    L1_2(L2_2, L3_2, L4_2)
  end
end

DefaultGoal = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = A0_2.AIGuid
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Create
    L2_2 = Event
    L2_2 = L2_2.ObjectHibernation
    L3_2 = {}
    L4_2 = A0_2.AIGuid
    L5_2 = "awake"
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    
    function L4_2()
      local L0_3, L1_3
      L0_3 = Ai
      L0_3 = L0_3.RemoveGoal
      L1_3 = A0_2
      L0_3(L1_3)
    end
    
    L1_2(L2_2, L3_2, L4_2)
  end
end

RemoveGoal = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = A0_2.Vehicle
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Create
    L2_2 = Event
    L2_2 = L2_2.ObjectHibernation
    L3_2 = {}
    L4_2 = A0_2.AIGuid
    L5_2 = "awake"
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    
    function L4_2()
      local L0_3, L1_3
      L0_3 = Ai
      L0_3 = L0_3.Deploy
      L1_3 = A0_2
      L0_3(L1_3)
    end
    
    L1_2(L2_2, L3_2, L4_2)
  end
end

Deploy = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = A0_2.AIGuid
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Create
    L2_2 = Event
    L2_2 = L2_2.ObjectHibernation
    L3_2 = {}
    L4_2 = A0_2.AIGuid
    L5_2 = "awake"
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    
    function L4_2()
      local L0_3, L1_3
      L0_3 = Ai
      L0_3 = L0_3.Role
      L1_3 = A0_2
      L0_3(L1_3)
    end
    
    L1_2(L2_2, L3_2, L4_2)
  end
end

Role = L0_1
