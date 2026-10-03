local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1
L0_1 = {}
L1_1 = "All_HQ"
L2_1 = "Gur_HQ2"
L3_1 = "GurHQ"
L4_1 = "MecRecruit"
L5_1 = "OilHQ"
L6_1 = "PMC1.1"
L7_1 = "Teleporter 0x000921c5"
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1
L0_1[5] = L5_1
L0_1[6] = L6_1
L0_1[7] = L7_1
L1_1 = nil
L2_1 = nil
L3_1 = nil
L4_1 = nil
L5_1 = nil
L6_1 = nil
L7_1 = nil

function L8_1()
  local L0_2, L1_2
  L0_2 = Go
  L0_2()
end

Init = L8_1

function L8_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = L0_1
  L1_2 = Math
  L1_2 = L1_2.floor
  L2_2 = Math
  L2_2 = L2_2.randf
  L3_2 = 1
  L4_2 = table
  L4_2 = L4_2.maxn
  L5_2 = L0_1
  L4_2, L5_2 = L4_2(L5_2)
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2, L4_2, L5_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  L0_2 = L0_2[L1_2]
  L5_1 = L0_2
  L0_2 = Pg
  L0_2 = L0_2.GetGuidByName
  L1_2 = L5_1
  L0_2 = L0_2(L1_2)
  L7_1 = L0_2
  L0_2 = L7_1
  if L0_2 ~= nil then
    L0_2 = Object
    L0_2 = L0_2.GetPosition
    L1_2 = L7_1
    L0_2, L1_2, L2_2 = L0_2(L1_2)
    L3_1 = L2_2
    L2_1 = L1_2
    L1_1 = L0_2
  else
    L0_2 = nil
    L1_2 = nil
    L2_2 = nil
    L3_1 = L2_2
    L2_1 = L1_2
    L1_1 = L0_2
  end
  L0_2 = L1_1
  if L0_2 == nil then
    L0_2 = Event
    L0_2 = L0_2.Create
    L1_2 = Event
    L1_2 = L1_2.TimerRelative
    L2_2 = {}
    L3_2 = 0.1
    L2_2[1] = L3_2
    L3_2 = Go
    L4_2 = nil
    L0_2 = L0_2(L1_2, L2_2, L3_2, L4_2)
    L6_1 = L0_2
  else
    L0_2 = Math
    L0_2 = L0_2.randf
    L1_2 = 5
    L2_2 = 20
    L0_2 = L0_2(L1_2, L2_2)
    L4_1 = L0_2
    L0_2 = Object
    L0_2 = L0_2.SetPosition
    L1_2 = Player
    L1_2 = L1_2.GetLocalCharacter
    L1_2 = L1_2()
    L2_2 = L1_1
    L3_2 = L2_1
    L3_2 = L3_2 + 20
    L4_2 = L3_1
    L0_2(L1_2, L2_2, L3_2, L4_2)
    L0_2 = Event
    L0_2 = L0_2.Create
    L1_2 = Event
    L1_2 = L1_2.TimerRelative
    L2_2 = {}
    L3_2 = Math
    L3_2 = L3_2.randf
    L4_2 = 5
    L5_2 = 20
    L3_2, L4_2, L5_2 = L3_2(L4_2, L5_2)
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
    L3_2 = Go
    L4_2 = nil
    L0_2 = L0_2(L1_2, L2_2, L3_2, L4_2)
    L6_1 = L0_2
  end
end

Go = L8_1
