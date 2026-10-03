local L0_1, L1_1
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = tEvents
if not L0_1 then
  L0_1 = {}
end
tEvents = L0_1
L0_1 = {}
L0_1.China = "Chinese Airborne"
L0_1.Allied = "Allied Airborne"
tTemplates = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = A0_2
  L6_2 = "awake"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = Start
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = A1_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
end

OnActivate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ObjectHealth
  L4_2 = {}
  L5_2 = A0_2
  L6_2 = "<"
  L7_2 = "100"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = RemoveChute
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = A1_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
end

Start = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = MrxUtil
  L2_2 = L2_2.GetFaction
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = Object
  L3_2 = L3_2.GetPosition
  L4_2 = A0_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  z = L5_2
  y = L4_2
  x = L3_2
  L3_2 = Object
  L3_2 = L3_2.GetYaw
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  yaw = L3_2
  L3_2 = Object
  L3_2 = L3_2.Remove
  L4_2 = A0_2
  L5_2 = 0.25
  L3_2(L4_2, L5_2)
  L3_2 = Pg
  L3_2 = L3_2.Spawn
  L4_2 = tTemplates
  L4_2 = L4_2[L2_2]
  L5_2 = x
  L6_2 = y
  L7_2 = z
  L8_2 = yaw
  L9_2 = true
  L10_2 = true
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  L3_2 = Object
  L3_2 = L3_2.SetYaw
  L4_2 = A0_2
  L5_2 = yaw
  L3_2(L4_2, L5_2)
end

RemoveChute = L0_1
