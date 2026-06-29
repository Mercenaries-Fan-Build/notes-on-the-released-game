local L0_1, L1_1, L2_1
L0_1 = import
L1_1 = "MrxPmc"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxSupportData"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = tEvents
if not L0_1 then
  L0_1 = {}
end
tEvents = L0_1
L0_1 = tMarker
if not L0_1 then
  L0_1 = {}
end
tMarker = L0_1
L0_1 = tHelpers
if not L0_1 then
  L0_1 = {}
end
tHelpers = L0_1
L0_1 = 250000
nCost = L0_1
L0_1 = "munitions"
sLocalName = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2
  L2_2 = Object
  L2_2 = L2_2.GetHealth
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = type
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if L3_2 == "number" and 0 < L2_2 then
    L3_2 = tEvents
    L4_2 = {}
    L3_2[A0_2] = L4_2
    L3_2 = tMarker
    L4_2 = {}
    L3_2[A0_2] = L4_2
    L3_2 = tHelpers
    L4_2 = tHelpers
    L4_2 = L4_2[A0_2]
    if not L4_2 then
      L4_2 = {}
    end
    L3_2[A0_2] = L4_2
    L3_2 = tMarker
    L3_2 = L3_2[A0_2]
    L4_2 = Marker
    L4_2 = L4_2.AddDisc
    L5_2 = A0_2
    L6_2 = 4.5
    L7_2 = 0
    L8_2 = 255
    L9_2 = 0
    L10_2 = 0.02
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
    L3_2.uMarker = L4_2
    L3_2 = Object
    L3_2 = L3_2.GetPosition
    L4_2 = A0_2
    L3_2, L4_2, L5_2 = L3_2(L4_2)
    L6_2 = tHelpers
    L6_2 = L6_2[A0_2]
    L7_2 = Pg
    L7_2 = L7_2.Spawn
    L8_2 = "location"
    L9_2 = L3_2
    L10_2 = L4_2
    L11_2 = L5_2
    L12_2 = 0
    L13_2 = false
    L14_2 = true
    L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
    L6_2.uBlipHelp = L7_2
    L6_2 = Event
    L6_2 = L6_2.Create
    L7_2 = Event
    L7_2 = L7_2.ObjectHibernation
    L8_2 = {}
    L9_2 = A0_2
    L10_2 = "awake"
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    
    function L9_2()
      local L0_3, L1_3
      L0_3 = SetupActivationEvents
      L1_3 = A0_2
      L0_3(L1_3)
    end
    
    L6_2(L7_2, L8_2, L9_2)
    L6_2 = tMarker
    L6_2 = L6_2[A0_2]
    L7_2 = Marker
    L7_2 = L7_2.AddBlip
    L8_2 = tHelpers
    L8_2 = L8_2[A0_2]
    L8_2 = L8_2.uBlipHelp
    L9_2 = "HUD_Rearm_DLC"
    L10_2 = 30
    L11_2 = 51
    L12_2 = 204
    L13_2 = 153
    L14_2 = 255
    L15_2 = 10
    L16_2 = 150
    L17_2 = 225
    L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
    L6_2.uIcon = L7_2
    L6_2 = tMarker
    L6_2 = L6_2[A0_2]
    L7_2 = "Blip_"
    L8_2 = tostring
    L9_2 = A0_2
    L8_2 = L8_2(L9_2)
    L7_2 = L7_2 .. L8_2
    L6_2.uMiniMap = L7_2
    L6_2 = Minimap
    L7_2 = L6_2
    L6_2 = L6_2.AddObjectiveWithGuid
    L8_2 = tMarker
    L8_2 = L8_2[A0_2]
    L8_2 = L8_2.uMiniMap
    L9_2 = A0_2
    L10_2 = 0
    L11_2 = 0
    L12_2 = 0
    L13_2 = 51
    L14_2 = 204
    L15_2 = 153
    L16_2 = 8
    L17_2 = 8
    L18_2 = "MiniMap_Icon_Rearm_DLC"
    L19_2 = false
    L20_2 = nil
    L21_2 = nil
    L22_2 = 10
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2)
  end
end

OnActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = OnDeactivate
  L2_2 = A0_2
  L1_2(L2_2)
end

OnDeath = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = pairs
    L2_2 = tEvents
    L2_2 = L2_2[A0_2]
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    for L4_2, L5_2 in L1_2, L2_2, L3_2 do
      L6_2 = Event
      L6_2 = L6_2.Delete
      L7_2 = L5_2
      L6_2(L7_2)
    end
    L1_2 = tEvents
    L1_2[A0_2] = nil
  end
  L1_2 = tMarker
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = tMarker
    L1_2 = L1_2[A0_2]
    L1_2 = L1_2.uMarker
    if L1_2 then
      L1_2 = Marker
      L1_2 = L1_2.Remove
      L2_2 = tMarker
      L2_2 = L2_2[A0_2]
      L2_2 = L2_2.uMarker
      L1_2(L2_2)
    end
    L1_2 = tMarker
    L1_2 = L1_2[A0_2]
    L1_2 = L1_2.uIcon
    if L1_2 then
      L1_2 = Marker
      L1_2 = L1_2.Remove
      L2_2 = tMarker
      L2_2 = L2_2[A0_2]
      L2_2 = L2_2.uIcon
      L1_2(L2_2)
    end
    L1_2 = tMarker
    L1_2 = L1_2[A0_2]
    L1_2 = L1_2.uMiniMap
    if L1_2 then
      L1_2 = Minimap
      L2_2 = L1_2
      L1_2 = L1_2.DeleteObjective
      L3_2 = tMarker
      L3_2 = L3_2[A0_2]
      L3_2 = L3_2.uMiniMap
      L1_2(L2_2, L3_2)
      L1_2 = tMarker
      L1_2 = L1_2[A0_2]
      L1_2.uMiniMap = nil
    end
    L1_2 = tMarker
    L1_2[A0_2] = nil
  end
end

OnDeactivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = "vehicle"
  L2_2 = tEvents
  L2_2 = L2_2[A0_2]
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = L1_2
  L7_2 = A0_2
  L8_2 = "<"
  L9_2 = 25
  L10_2 = false
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  
  function L6_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L1_3 = tEvents
    L1_3 = L1_3[A0_3]
    L2_3 = Event
    L2_3 = L2_3.Create
    L3_3 = Event
    L3_3 = L3_3.TimerRelative
    L4_3 = {}
    L5_3 = 7
    L4_3[1] = L5_3
    L5_3 = MrxTutorialManager
    L5_3 = L5_3.HideMessage
    L6_3 = {}
    L7_3 = true
    L6_3[1] = L7_3
    L2_3 = L2_3(L3_3, L4_3, L5_3, L6_3)
    L1_3.uHideTutorial = L2_3
  end
  
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2.uTutorial = L3_2
  L2_2 = tEvents
  L2_2 = L2_2[A0_2]
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = L1_2
  L7_2 = A0_2
  L8_2 = "<"
  L9_2 = 5
  L10_2 = true
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = Rearm
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2.uProximity = L3_2
end

SetupActivationEvents = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = Object
  L2_2 = L2_2.HasLabel
  L3_2 = A0_2
  L4_2 = "helipad"
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    L2_2 = MrxTutorialManager
    L2_2 = L2_2.StartTutorial
    L3_2 = "HeliRepairPad"
    L2_2(L3_2)
  else
  end
  L2_2 = Vehicle
  L2_2 = L2_2.GetDriver
  L3_2 = A1_2[1]
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = Object
    L2_2 = L2_2.HasLabel
    L3_2 = Vehicle
    L3_2 = L3_2.GetDriver
    L4_2 = A1_2[1]
    L3_2 = L3_2(L4_2)
    L4_2 = "hero"
    L2_2 = L2_2(L3_2, L4_2)
    if L2_2 then
      L2_2 = Vehicle
      L2_2 = L2_2.IsFlying
      L3_2 = A1_2[1]
      L2_2 = L2_2(L3_2)
      if not L2_2 then
        L2_2 = Sound
        L2_2 = L2_2.CueSound
        L3_2 = A1_2[1]
        L4_2 = "ui_HUD_Pickup_Weapon_Large"
        L2_2(L3_2, L4_2)
        L2_2 = Vehicle
        L2_2 = L2_2.RestoreAmmo
        L3_2 = A1_2[1]
        L2_2(L3_2)
        L2_2 = MrxSubtitle
        L2_2 = L2_2.Add
        L3_2 = "[buildings.ammoBay.rearmed]"
        L2_2(L3_2)
        L2_2 = tEvents
        L2_2 = L2_2[A0_2]
        L3_2 = Event
        L3_2 = L3_2.Create
        L4_2 = Event
        L4_2 = L4_2.TimerRelative
        L5_2 = {}
        L6_2 = 30
        L5_2[1] = L6_2
        L6_2 = SetupActivationEvents
        L7_2 = {}
        L8_2 = A0_2
        L7_2[1] = L8_2
        L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
        L2_2.uRecycle = L3_2
    end
  end
  else
    L2_2 = tEvents
    L2_2 = L2_2[A0_2]
    L3_2 = Event
    L3_2 = L3_2.Create
    L4_2 = Event
    L4_2 = L4_2.TimerRelative
    L5_2 = {}
    L6_2 = 3
    L5_2[1] = L6_2
    L6_2 = SetupActivationEvents
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
    L2_2.uRecycle = L3_2
  end
end

Rearm = L0_1
