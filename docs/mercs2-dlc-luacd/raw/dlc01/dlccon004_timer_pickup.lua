local L0_1, L1_1, L2_1
L0_1 = import
L1_1 = "DLCCon004a"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = "pickup_crate_2"
L1_1 = {}
tGlobalTimerInstances = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = tGlobalTimerInstances
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    L1_2 = {}
  end
  L2_2 = Marker
  L2_2 = L2_2.Add
  L3_2 = 0
  L4_2 = 0
  L5_2 = 0
  L6_2 = A0_2
  L7_2 = 50
  L8_2 = 0
  L9_2 = 255
  L10_2 = 1
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  L1_2.Marker = L2_2
  L2_2 = Hud
  L2_2 = L2_2.Radar
  L3_2 = L2_2
  L2_2 = L2_2.AddObjective
  L4_2 = {}
  L5_2 = "Timer"
  L6_2 = tostring
  L7_2 = A0_2
  L6_2 = L6_2(L7_2)
  L5_2 = L5_2 .. L6_2
  L4_2.sName = L5_2
  L4_2.uGuid = A0_2
  L4_2.nR = 100
  L4_2.nG = 75
  L4_2.nB = 255
  L4_2.nWidth = 8
  L4_2.nHeight = 8
  L4_2.sTexture = "MiniMap_Icon_Clock_DLC"
  L2_2(L3_2, L4_2)
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = A0_2
  L7_2 = "<"
  L8_2 = 7
  L9_2 = false
  L10_2 = true
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L0_3 = Event
    L0_3 = L0_3.Post
    L1_3 = "TimeAdded"
    L2_3 = {}
    L3_3 = 30
    L2_3[1] = L3_3
    L0_3(L1_3, L2_3)
    L0_3 = Object
    L0_3 = L0_3.GetPosition
    L1_3 = A0_2
    L0_3, L1_3, L2_3 = L0_3(L1_3)
    L3_3 = Pg
    L3_3 = L3_3.Spawn
    L4_3 = "dlc_global_particle_explosion_pickup_timer"
    L5_3 = L0_3
    L6_3 = L1_3
    L7_3 = L2_3
    L3_3(L4_3, L5_3, L6_3, L7_3)
    L3_3 = OnDeactivate
    L4_3 = A0_2
    L3_3(L4_3)
  end
  
  L6_2 = {}
  L7_2 = iArg
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.PickupEvent = L2_2
  L2_2 = tGlobalTimerInstances
  L2_2[A0_2] = L1_2
end

OnActivate = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = tGlobalTimerInstances
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    return
  end
  L2_2 = L1_2.Marker
  if L2_2 then
    L2_2 = Marker
    L2_2 = L2_2.Remove
    L3_2 = L1_2.Marker
    L2_2(L3_2)
    L1_2.Marker = nil
  end
  L2_2 = Hud
  L2_2 = L2_2.Radar
  L3_2 = L2_2
  L2_2 = L2_2.RemoveObjective
  L4_2 = {}
  L5_2 = "Timer"
  L6_2 = tostring
  L7_2 = A0_2
  L6_2 = L6_2(L7_2)
  L5_2 = L5_2 .. L6_2
  L4_2.sName = L5_2
  L2_2(L3_2, L4_2)
  L2_2 = L1_2.ProximityEvent
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = L1_2.ProximityEvent
    L2_2(L3_2)
  end
  L2_2 = tGlobalTimerInstances
  L2_2[A0_2] = nil
  L2_2 = Object
  L2_2 = L2_2.Remove
  L3_2 = A0_2
  L2_2(L3_2)
end

OnDeactivate = L1_1
