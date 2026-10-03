local L0_1, L1_1

function L0_1()
  local L0_2, L1_2
end

Start = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.ObjectHibernation
  L2_2 = {}
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "Patrol_GurBase_Gate"
  L3_2 = L3_2(L4_2)
  L4_2 = "awake"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = StartPatrol
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "Patrol_GurBase_Gate"
  L5_2 = L5_2(L6_2)
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "path_gate_patrol"
  L6_2 = L6_2(L7_2)
  L7_2 = "loop"
  L8_2 = "lowpri"
  L9_2 = ".4"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L0_2(L1_2, L2_2, L3_2, L4_2)
end

GurBaseGatePatrol = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.ObjectHibernation
  L2_2 = {}
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "Guerilla_Trailer_Patrol"
  L3_2 = L3_2(L4_2)
  L4_2 = "awake"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = StartPatrol
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "Guerilla_Trailer_Patrol"
  L5_2 = L5_2(L6_2)
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Path_Trailer_Loop"
  L6_2 = L6_2(L7_2)
  L7_2 = "loop"
  L8_2 = "lowpri"
  L9_2 = ".1"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L0_2(L1_2, L2_2, L3_2, L4_2)
end

GurBaseTrailerPatrol = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.ObjectHibernation
  L2_2 = {}
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "Guerilla_Patrol_RoadOne"
  L3_2 = L3_2(L4_2)
  L4_2 = "awake"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = StartPatrol
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "Guerilla_Patrol_RoadOne"
  L5_2 = L5_2(L6_2)
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Path_GurBase_RoadOne"
  L6_2 = L6_2(L7_2)
  L7_2 = "loop"
  L8_2 = "lowpri"
  L9_2 = ".5"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L0_2(L1_2, L2_2, L3_2, L4_2)
end

GurBaseRoadPatrolOne = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.ObjectHibernation
  L2_2 = {}
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "\t"
  L3_2 = L3_2(L4_2)
  L4_2 = "awake"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = StartPatrol
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "Guerilla_Earthmover_Patrol"
  L5_2 = L5_2(L6_2)
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Path_EarthMover_Patrol"
  L6_2 = L6_2(L7_2)
  L7_2 = "loop"
  L8_2 = "lowpri"
  L9_2 = ".5"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L0_2(L1_2, L2_2, L3_2, L4_2)
end

GurBaseEarthmoverPatrol = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.ObjectHibernation
  L2_2 = {}
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "Guerilla_Moverarm_Patrol"
  L3_2 = L3_2(L4_2)
  L4_2 = "awake"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = StartPatrol
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "Guerilla_Moverarm_Patrol"
  L5_2 = L5_2(L6_2)
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Path_GurBase_MoverArm"
  L6_2 = L6_2(L7_2)
  L7_2 = "loop"
  L8_2 = "lowpri"
  L9_2 = ".2"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L0_2(L1_2, L2_2, L3_2, L4_2)
end

GurBaseMoverarmPatrol = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.ObjectHibernation
  L2_2 = {}
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "Squad_PatrolOne"
  L3_2 = L3_2(L4_2)
  L4_2 = "awake"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = StartPatrol
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "Squad_PatrolOne"
  L5_2 = L5_2(L6_2)
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Path_Squad_PatrolOne"
  L6_2 = L6_2(L7_2)
  L7_2 = "loop"
  L8_2 = "lowpri"
  L9_2 = ".2"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L0_2(L1_2, L2_2, L3_2, L4_2)
end

GurBaseSquadPatrolOne = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.ObjectHibernation
  L2_2 = {}
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "Guerilla_Patrol_RoadTwo"
  L3_2 = L3_2(L4_2)
  L4_2 = "awake"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = StartPatrol
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "Guerilla_Patrol_RoadTwo"
  L5_2 = L5_2(L6_2)
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Path_GurBase_RoadTwo"
  L6_2 = L6_2(L7_2)
  L7_2 = "loop"
  L8_2 = "lowpri"
  L9_2 = ".2"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L0_2(L1_2, L2_2, L3_2, L4_2)
end

GurBaseRoadPatrolTwo = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.ObjectHibernation
  L2_2 = {}
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "Guerilla_Patrol_FrontOne"
  L3_2 = L3_2(L4_2)
  L4_2 = "awake"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = StartPatrol
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "Guerilla_Patrol_FrontOne"
  L5_2 = L5_2(L6_2)
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Path_GurBase_Front_PatrolOne"
  L6_2 = L6_2(L7_2)
  L7_2 = "loop"
  L8_2 = "lowpri"
  L9_2 = ".2"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L0_2(L1_2, L2_2, L3_2, L4_2)
end

GurBaseFrontPatrolOne = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  if A3_2 == nil then
    A3_2 = "lowpri"
  end
  L5_2 = {}
  L5_2.AIGuid = A0_2
  L5_2.Goal = "PathMove"
  L5_2.Target = A1_2
  L5_2.Start = "First"
  L5_2.Priority = A3_2
  L5_2.Mode = A2_2
  L5_2.Haste = A4_2
  tGoalParams = L5_2
  L5_2 = Event
  L5_2 = L5_2.Create
  L6_2 = Event
  L6_2 = L6_2.TimerRelative
  L7_2 = {}
  L8_2 = 1
  L7_2[1] = L8_2
  L8_2 = Ai
  L8_2 = L8_2.Goal
  L9_2 = {}
  L10_2 = tGoalParams
  L9_2[1] = L10_2
  L5_2(L6_2, L7_2, L8_2, L9_2)
end

StartPatrol = L0_1
