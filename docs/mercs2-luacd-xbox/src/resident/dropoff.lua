local L0_1, L1_1
L0_1 = import
L1_1 = "MrxCopterDrop"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
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
    local L0_3, L1_3, L2_3
    L0_3 = StartTimer
    L1_3 = A0_2
    L2_3 = 0
    L0_3(L1_3, L2_3)
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
  L1_2 = L1_2.CargoDrop
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = tEvents
    L2_2 = L2_2[A0_2]
    L2_2 = L2_2.CargoDrop
    L1_2(L2_2)
    L1_2 = tEvents
    L1_2 = L1_2[A0_2]
    L1_2.CargoDrop = nil
  end
  L1_2 = tEvents
  L1_2[A0_2] = nil
  L1_2 = nil
  NumDrops = L1_2
end

OnDeactivate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = math
  L2_2 = L2_2.randf
  L3_2 = 30
  L4_2 = 60
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = tEvents
  L3_2 = L3_2[A0_2]
  L3_2 = L3_2.CargoDrop
  if L3_2 then
    return
  else
    L3_2 = tEvents
    L3_2 = L3_2[A0_2]
    L4_2 = Event
    L4_2 = L4_2.Create
    L5_2 = Event
    L5_2 = L5_2.TimerRelative
    L6_2 = {}
    L7_2 = L2_2
    L6_2[1] = L7_2
    L7_2 = SetupCargoDrop
    L8_2 = {}
    L9_2 = A0_2
    L10_2 = A1_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
    L3_2.CargoDrop = L4_2
  end
end

StartTimer = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = tEvents
  L2_2 = L2_2[A0_2]
  L2_2.CargoDrop = nil
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = A0_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  z = L4_2
  y = L3_2
  x = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.GetFaction
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 == "VZ" then
    L3_2 = "VZ"
    HeloFaction = L3_2
    L3_2 = {}
    L4_2 = "_port_containera_light"
    L5_2 = "_port_containerb_light"
    L6_2 = "_port_containerc_light"
    L7_2 = "_port_containerd_light"
    L8_2 = "M151 .50Cal (VZ)"
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L3_2[4] = L7_2
    L3_2[5] = L8_2
    tDropOffObjects = L3_2
  elseif L2_2 == "Guerilla" then
    L3_2 = "GR"
    HeloFaction = L3_2
    L3_2 = {}
    L4_2 = "_port_containera"
    L5_2 = "_port_containerb"
    L6_2 = "_port_containerc"
    L7_2 = "_port_containerd"
    L8_2 = "M151 (MG) (GR)"
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L3_2[4] = L7_2
    L3_2[5] = L8_2
    tDropOffObjects = L3_2
  elseif L2_2 == "China" then
    L3_2 = "CH"
    HeloFaction = L3_2
    L3_2 = {}
    L4_2 = "_port_containera"
    L5_2 = "_port_containerb"
    L6_2 = "_port_containerc"
    L7_2 = "_port_containerd"
    L8_2 = "NGLV (MG)"
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L3_2[4] = L7_2
    L3_2[5] = L8_2
    tDropOffObjects = L3_2
  elseif L2_2 == "OC" then
    L3_2 = {}
    L4_2 = "_port_containera_light"
    L5_2 = "_port_containerb_light"
    L6_2 = "_port_containerc_light"
    L7_2 = "_port_containerd_light"
    L8_2 = "EXT"
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L3_2[4] = L7_2
    L3_2[5] = L8_2
    tDropOffObjects = L3_2
    L3_2 = "OC"
    HeloFaction = L3_2
  elseif L2_2 == "Allied" then
    L3_2 = "AL"
    HeloFaction = L3_2
    L3_2 = {}
    L4_2 = "_port_containera"
    L5_2 = "_port_containerb"
    L6_2 = "_port_containerc"
    L7_2 = "_port_containerd"
    L8_2 = "HMMWV (Armored) (50Cal)"
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L3_2[4] = L7_2
    L3_2[5] = L8_2
    tDropOffObjects = L3_2
  elseif L2_2 == "Pirate" then
    L3_2 = {}
    L4_2 = "_port_containera_light"
    L5_2 = "_port_containerb_light"
    L6_2 = "_port_containerc_light"
    L7_2 = "_port_containerd_light"
    L8_2 = "T300 (M60)"
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L3_2[4] = L7_2
    L3_2[5] = L8_2
    tDropOffObjects = L3_2
    L3_2 = "PR"
    HeloFaction = L3_2
  end
  L3_2 = MrxUtil
  L3_2 = L3_2.GetRandomTableElement
  L4_2 = tDropOffObjects
  L3_2 = L3_2(L4_2)
  sCargoTemplate = L3_2
  L3_2 = MrxCopterDrop
  L3_2 = L3_2.Create
  L4_2 = HeloFaction
  L5_2 = sCargoTemplate
  L6_2 = x
  L7_2 = y
  L8_2 = z
  L9_2 = false
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  A1_2 = A1_2 + 1
  if A1_2 < 1 then
    L3_2 = StartTimer
    L4_2 = A0_2
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
  end
end

SetupCargoDrop = L0_1
