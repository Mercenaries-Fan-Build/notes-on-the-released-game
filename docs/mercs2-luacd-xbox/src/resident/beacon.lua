local L0_1, L1_1

function L0_1()
  local L0_2, L1_2
  L0_2 = tEvents
  if not L0_2 then
    L0_2 = {}
  end
  tEvents = L0_2
end

Init = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = Object
  L2_2 = L2_2.PlayMaterialAnimation
  L3_2 = A0_2
  L4_2 = "global_weapon_beacon"
  L5_2 = true
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = tEvents
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 1
  L5_2[1] = L6_2
  L6_2 = Sound
  L6_2 = L6_2.CueSound
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = "wpn_bomb_timer_01_armed"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2[A0_2] = L3_2
end

OnActivate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = Object
  L2_2 = L2_2.StopMaterialAnimation
  L3_2 = A0_2
  L4_2 = "global_weapon_beacon"
  L2_2(L3_2, L4_2)
  L2_2 = Sound
  L2_2 = L2_2.StopSound
  L3_2 = A0_2
  L4_2 = "wpn_bomb_timer_01_armed"
  L2_2(L3_2, L4_2)
  L2_2 = Event
  L2_2 = L2_2.Delete
  L3_2 = tEvents
  L3_2 = L3_2[A0_2]
  L2_2(L3_2)
  L2_2 = tEvents
  L2_2[A0_2] = nil
end

OnDeactivate = L0_1
