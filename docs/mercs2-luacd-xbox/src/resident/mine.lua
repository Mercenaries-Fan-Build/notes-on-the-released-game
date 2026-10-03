local L0_1, L1_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = uEvent
  if not L0_2 then
    L0_2 = {}
  end
  uEvent = L0_2
  L0_2 = uHumanFilter
  if not L0_2 then
    L0_2 = ObjectFilter
    L0_2 = L0_2.Create
    L0_2 = L0_2()
  end
  uHumanFilter = L0_2
  L0_2 = uVehicleFilter
  if not L0_2 then
    L0_2 = ObjectFilter
    L0_2 = L0_2.Create
    L0_2 = L0_2()
  end
  uVehicleFilter = L0_2
  L0_2 = ObjectFilter
  L0_2 = L0_2.SetFilter
  L1_2 = uHumanFilter
  L2_2 = "human"
  L0_2(L1_2, L2_2)
  L0_2 = ObjectFilter
  L0_2 = L0_2.SetFilter
  L1_2 = uVehicleFilter
  L2_2 = "vehicle"
  L0_2(L1_2, L2_2)
end

Init = L0_1

function L0_1()
  local L0_2, L1_2
  uHumanFilter = L0_2
  L0_2 = nil
  uVehicleFilter = L0_2
end

Deinit = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = Object
  L3_2 = L3_2.PlayMaterialAnimation
  L4_2 = A0_2
  L5_2 = "global_weapon_c4land_60thsec"
  L6_2 = true
  L3_2(L4_2, L5_2, L6_2)
  if A2_2 == 2 then
    L3_2 = uEvent
    L4_2 = Event
    L4_2 = L4_2.Create
    L5_2 = Event
    L5_2 = L5_2.ObjectProximity
    L6_2 = {}
    L7_2 = uHumanFilter
    L8_2 = A0_2
    L9_2 = "<"
    L10_2 = 1
    L11_2 = false
    L12_2 = false
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L6_2[4] = L10_2
    L6_2[5] = L11_2
    L6_2[6] = L12_2
    L7_2 = Object
    L7_2 = L7_2.Kill
    L8_2 = {}
    L9_2 = A0_2
    L8_2[1] = L9_2
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
    L3_2[A0_2] = L4_2
  else
  end
end

OnActivate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = Object
  L2_2 = L2_2.StopMaterialAnimation
  L3_2 = A0_2
  L4_2 = "global_weapon_c4land_60thsec"
  L2_2(L3_2, L4_2)
  L2_2 = Event
  L2_2 = L2_2.Delete
  L3_2 = uEvent
  L3_2 = L3_2[A0_2]
  L2_2(L3_2)
  L2_2 = uEvent
  L2_2[A0_2] = nil
end

OnDeactivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = Sound
  L1_2 = L1_2.CueSound
  L2_2 = A0_2
  L3_2 = "wpn_bomb_timer_01_finalstage"
  L1_2(L2_2, L3_2)
  L1_2 = uEvent
  L1_2[A0_2] = nil
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  if L1_2 then
    L4_2 = Object
    L4_2 = L4_2.HasLabel
    L5_2 = A0_2
    L6_2 = "HumanMine"
    L4_2 = L4_2(L5_2, L6_2)
    if L4_2 then
      L4_2 = Event
      L4_2 = L4_2.Create
      L5_2 = Event
      L5_2 = L5_2.TimerRelative
      L6_2 = {}
      L7_2 = 0.75
      L6_2[1] = L7_2
      L7_2 = Explode
      L8_2 = {}
      L9_2 = A0_2
      L10_2 = L1_2
      L11_2 = L2_2
      L12_2 = L3_2
      L13_2 = "human"
      L8_2[1] = L9_2
      L8_2[2] = L10_2
      L8_2[3] = L11_2
      L8_2[4] = L12_2
      L8_2[5] = L13_2
      L4_2(L5_2, L6_2, L7_2, L8_2)
    else
      L4_2 = Event
      L4_2 = L4_2.Create
      L5_2 = Event
      L5_2 = L5_2.TimerRelative
      L6_2 = {}
      L7_2 = 0.25
      L6_2[1] = L7_2
      L7_2 = Explode
      L8_2 = {}
      L9_2 = A0_2
      L10_2 = L1_2
      L11_2 = L2_2
      L12_2 = L3_2
      L13_2 = "veh"
      L8_2[1] = L9_2
      L8_2[2] = L10_2
      L8_2[3] = L11_2
      L8_2[4] = L12_2
      L8_2[5] = L13_2
      L4_2(L5_2, L6_2, L7_2, L8_2)
    end
  end
end

OnDeath = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2
  L5_2 = Sound
  L5_2 = L5_2.StopSound
  L6_2 = A0_2
  L7_2 = "wpn_bomb_timer_01_finalstage"
  L5_2(L6_2, L7_2)
  if A4_2 == "human" then
    L5_2 = Pg
    L5_2 = L5_2.Spawn
    L6_2 = "Explosion (Grenade)"
    L7_2 = A1_2
    L8_2 = A2_2
    L9_2 = A3_2
    L5_2(L6_2, L7_2, L8_2, L9_2)
  elseif A4_2 == "veh" then
    L5_2 = Pg
    L5_2 = L5_2.Spawn
    L6_2 = "Explosion (AT Mine)"
    L7_2 = A1_2
    L8_2 = A2_2
    L9_2 = A3_2
    L5_2(L6_2, L7_2, L8_2, L9_2)
  else
    L5_2 = Pg
    L5_2 = L5_2.Spawn
    L6_2 = "Explosion (Water Mine)"
    L7_2 = A1_2
    L8_2 = A2_2
    L9_2 = A3_2
    L5_2(L6_2, L7_2, L8_2, L9_2)
  end
end

Explode = L0_1
