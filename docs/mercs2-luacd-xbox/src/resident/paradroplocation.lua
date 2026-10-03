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
L0_1.China = "Support Vehicle (paradop_ch)"
L0_1.Allied = "Support Vehicle (paradop_al)"
tTemplates = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.ObjectHibernation
  L3_2 = {}
  L4_2 = A0_2
  L5_2 = "awake"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L4_2 = Start
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

OnActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  L4_2 = MrxUtil
  L4_2 = L4_2.GetFaction
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if L1_2 and L4_2 then
    L5_2 = tTemplates
    L5_2 = L5_2[L4_2]
    if L5_2 then
      L5_2 = Airstrike
      L5_2 = L5_2.Flyby
      L6_2 = tTemplates
      L6_2 = L6_2[L4_2]
      L7_2 = L1_2 - 50
      L8_2 = L3_2 + 300
      L9_2 = L1_2
      L10_2 = L3_2
      L11_2 = L2_2 + 100
      L12_2 = 40
      L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  end
  else
    return
  end
  L5_2 = Object
  L5_2 = L5_2.Remove
  L6_2 = A0_2
  L5_2(L6_2)
end

Start = L0_1
