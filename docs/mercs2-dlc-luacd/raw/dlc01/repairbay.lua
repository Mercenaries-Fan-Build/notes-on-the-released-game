local L0_1, L1_1, L2_1
L0_1 = import
L1_1 = "MrxPmc"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxUtil"
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
L0_1 = tPrices
if not L0_1 then
  L0_1 = {}
end
tPrices = L0_1
L0_1 = tHelpers
if not L0_1 then
  L0_1 = {}
end
tHelpers = L0_1
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
    L4_2 = tEvents
    L4_2 = L4_2[A0_2]
    if not L4_2 then
      L4_2 = {}
    end
    L3_2[A0_2] = L4_2
    L3_2 = tMarker
    L4_2 = tMarker
    L4_2 = L4_2[A0_2]
    if not L4_2 then
      L4_2 = {}
    end
    L3_2[A0_2] = L4_2
    L3_2 = tPrices
    L4_2 = tPrices
    L4_2 = L4_2[A0_2]
    if not L4_2 then
      L4_2 = {}
    end
    L3_2[A0_2] = L4_2
    L3_2 = tHelpers
    L4_2 = tHelpers
    L4_2 = L4_2[A0_2]
    if not L4_2 then
      L4_2 = {}
    end
    L3_2[A0_2] = L4_2
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
      local L0_3, L1_3, L2_3
      L0_3 = Object
      L0_3 = L0_3.IsAlive
      L1_3 = A0_2
      L0_3 = L0_3(L1_3)
      if L0_3 then
        L1_3 = SetupActivationEvents
        L2_3 = A0_2
        L1_3(L2_3)
      end
    end
    
    L6_2(L7_2, L8_2, L9_2)
    L6_2 = tMarker
    L6_2 = L6_2[A0_2]
    L7_2 = Marker
    L7_2 = L7_2.AddBlip
    L8_2 = tHelpers
    L8_2 = L8_2[A0_2]
    L8_2 = L8_2.uBlipHelp
    L9_2 = "HUD_Repair_DLC"
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
    L18_2 = "MiniMap_Icon_Repair_DLC"
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
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L1_2 = tPrices
  L1_2 = L1_2[A0_2]
  L1_2.nCost = 500000
  L1_2 = "vehicle"
  L2_2 = "hp_veh_spawn"
  L3_2 = Object
  L3_2 = L3_2.GetHardpointPosition
  L4_2 = A0_2
  L5_2 = "hp_veh_spawn"
  L3_2, L4_2, L5_2 = L3_2(L4_2, L5_2)
  L6_2 = {}
  L7_2 = 7.064171
  L8_2 = 1.165347
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = tEvents
  L7_2 = L7_2[A0_2]
  L8_2 = Event
  L8_2 = L8_2.Create
  L9_2 = Event
  L9_2 = L9_2.ObjectProximity
  L10_2 = {}
  L11_2 = L1_2
  L12_2 = A0_2
  L13_2 = "<"
  L14_2 = 25
  L15_2 = false
  L16_2 = false
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L10_2[5] = L15_2
  L10_2[6] = L16_2
  
  function L11_2(A0_3)
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
  
  L12_2 = {}
  L13_2 = A0_2
  L12_2[1] = L13_2
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
  L7_2.uTutorial = L8_2
  L7_2 = tHelpers
  L7_2 = L7_2[A0_2]
  L8_2 = Pg
  L8_2 = L8_2.Spawn
  L9_2 = "location"
  L10_2 = L3_2
  L11_2 = L4_2
  L12_2 = L5_2
  L13_2 = 0
  L14_2 = false
  L15_2 = true
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  L7_2.uDiscHelp = L8_2
  L7_2 = tMarker
  L7_2 = L7_2[A0_2]
  L7_2 = L7_2.uMarker
  if L7_2 then
    L7_2 = Marker
    L7_2 = L7_2.Remove
    L8_2 = tMarker
    L8_2 = L8_2[A0_2]
    L8_2 = L8_2.uMarker
    L7_2(L8_2)
    L7_2 = tMarker
    L7_2 = L7_2[A0_2]
    L8_2 = Marker
    L8_2 = L8_2.AddDisc
    L9_2 = tHelpers
    L9_2 = L9_2[A0_2]
    L9_2 = L9_2.uDiscHelp
    L10_2 = 3
    L11_2 = 0
    L12_2 = 255
    L13_2 = 0
    L14_2 = 0.05
    L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
    L7_2.uMarker = L8_2
  else
    L7_2 = tMarker
    L7_2 = L7_2[A0_2]
    L8_2 = Marker
    L8_2 = L8_2.AddDisc
    L9_2 = tHelpers
    L9_2 = L9_2[A0_2]
    L9_2 = L9_2.uDiscHelp
    L10_2 = 3
    L11_2 = 0
    L12_2 = 255
    L13_2 = 0
    L14_2 = 0.05
    L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
    L7_2.uMarker = L8_2
  end
  L7_2 = PlayerOutside
  L8_2 = A0_2
  L7_2(L8_2)
  L7_2 = tEvents
  L7_2 = L7_2[A0_2]
  L8_2 = Event
  L8_2 = L8_2.Create
  L9_2 = Event
  L9_2 = L9_2.ObjectProximity
  L10_2 = {}
  L11_2 = L1_2
  L12_2 = L3_2
  L13_2 = L4_2
  L14_2 = L5_2
  L15_2 = "<"
  L16_2 = 5
  L17_2 = true
  L18_2 = false
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L10_2[5] = L15_2
  L10_2[6] = L16_2
  L10_2[7] = L17_2
  L10_2[8] = L18_2
  L11_2 = InitiateRepair
  L12_2 = {}
  L13_2 = A0_2
  L12_2[1] = L13_2
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
  L7_2.uProximity = L8_2
end

SetupActivationEvents = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L2_2 = Vehicle
  L2_2 = L2_2.GetDriver
  L3_2 = A1_2[1]
  L2_2 = L2_2(L3_2)
  L3_2 = MrxPmc
  L3_2 = L3_2.GetCashQty
  L3_2 = L3_2()
  L4_2 = Object
  L4_2 = L4_2.GetHealth
  L5_2 = A1_2[1]
  L4_2 = L4_2(L5_2)
  L5_2 = Object
  L5_2 = L5_2.GetMaxHealth
  L6_2 = A1_2[1]
  L5_2 = L5_2(L6_2)
  L6_2 = L4_2 / L5_2
  L6_2 = L6_2 * 100
  if L2_2 then
    L7_2 = Object
    L7_2 = L7_2.HasLabel
    L8_2 = L2_2
    L9_2 = "hero"
    L7_2 = L7_2(L8_2, L9_2)
    if L7_2 then
      L7_2 = Vehicle
      L7_2 = L7_2.IsFlying
      L8_2 = A1_2[1]
      L7_2 = L7_2(L8_2)
      if not L7_2 then
        L7_2 = tEvents
        L7_2 = L7_2[A0_2]
        L8_2 = Event
        L8_2 = L8_2.Create
        L9_2 = Event
        L9_2 = L9_2.ObjectDeath
        L10_2 = {}
        L11_2 = A1_2[1]
        L10_2[1] = L11_2
        L11_2 = Object
        L11_2 = L11_2.FadeOut
        L12_2 = {}
        L13_2 = A1_2[1]
        L14_2 = 1.5
        L15_2 = true
        L12_2[1] = L13_2
        L12_2[2] = L14_2
        L12_2[3] = L15_2
        L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
        L7_2.uCleanUp = L8_2
        L7_2 = tPrices
        L7_2 = L7_2[A0_2]
        L7_2 = L7_2.nCost
        if L3_2 >= L7_2 then
          if L6_2 < 99 then
            L7_2 = tMarker
            L7_2 = L7_2[A0_2]
            L7_2 = L7_2.uMarker
            if L7_2 then
              L7_2 = Marker
              L7_2 = L7_2.Remove
              L8_2 = tMarker
              L8_2 = L8_2[A0_2]
              L8_2 = L8_2.uMarker
              L7_2(L8_2)
              L7_2 = tMarker
              L7_2 = L7_2[A0_2]
              L8_2 = Marker
              L8_2 = L8_2.AddDisc
              L9_2 = tHelpers
              L9_2 = L9_2[A0_2]
              L9_2 = L9_2.uDiscHelp
              L10_2 = 3
              L11_2 = 255
              L12_2 = 255
              L13_2 = 0
              L14_2 = 0.05
              L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
              L7_2.uMarker = L8_2
            end
            L7_2 = Sound
            L7_2 = L7_2.CueSound
            L8_2 = A1_2[1]
            L9_2 = "ui_HUD_Pickup_Weapon_Large"
            L7_2(L8_2, L9_2)
            L7_2 = StartCinematic
            L8_2 = A0_2
            L9_2 = A1_2[1]
            L10_2 = L2_2
            L7_2(L8_2, L9_2, L10_2)
            L7_2 = tEvents
            L7_2 = L7_2[A0_2]
            L8_2 = Event
            L8_2 = L8_2.Create
            L9_2 = Event
            L9_2 = L9_2.ObjectProximity
            L10_2 = {}
            L11_2 = Player
            L11_2 = L11_2.GetAnyCharacter
            L11_2 = L11_2()
            L12_2 = A0_2
            L13_2 = ">"
            L14_2 = 20
            L15_2 = true
            L16_2 = false
            L10_2[1] = L11_2
            L10_2[2] = L12_2
            L10_2[3] = L13_2
            L10_2[4] = L14_2
            L10_2[5] = L15_2
            L10_2[6] = L16_2
            L11_2 = SetupActivationEvents
            L12_2 = {}
            L13_2 = A0_2
            L12_2[1] = L13_2
            L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
            L7_2.uRecycle = L8_2
          else
            L7_2 = tMarker
            L7_2 = L7_2[A0_2]
            L7_2 = L7_2.uMarker
            if L7_2 then
              L7_2 = Marker
              L7_2 = L7_2.Remove
              L8_2 = tMarker
              L8_2 = L8_2[A0_2]
              L8_2 = L8_2.uMarker
              L7_2(L8_2)
              L7_2 = tMarker
              L7_2 = L7_2[A0_2]
              L8_2 = Marker
              L8_2 = L8_2.AddDisc
              L9_2 = tHelpers
              L9_2 = L9_2[A0_2]
              L9_2 = L9_2.uDiscHelp
              L10_2 = 3
              L11_2 = 255
              L12_2 = 255
              L13_2 = 0
              L14_2 = 0.05
              L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
              L7_2.uMarker = L8_2
            end
            L7_2 = MrxSubtitle
            L7_2 = L7_2.Add
            L8_2 = "[buildings.repairBay.undamaged]"
            L7_2(L8_2)
            L7_2 = tEvents
            L7_2 = L7_2[A0_2]
            L8_2 = Event
            L8_2 = L8_2.Create
            L9_2 = Event
            L9_2 = L9_2.TimerRelative
            L10_2 = {}
            L11_2 = 15
            L10_2[1] = L11_2
            L11_2 = SetupActivationEvents
            L12_2 = {}
            L13_2 = A0_2
            L12_2[1] = L13_2
            L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
            L7_2.uRecycle = L8_2
          end
        else
          L7_2 = tMarker
          L7_2 = L7_2[A0_2]
          L7_2 = L7_2.uMarker
          if L7_2 then
            L7_2 = Marker
            L7_2 = L7_2.Remove
            L8_2 = tMarker
            L8_2 = L8_2[A0_2]
            L8_2 = L8_2.uMarker
            L7_2(L8_2)
            L7_2 = tMarker
            L7_2 = L7_2[A0_2]
            L8_2 = Marker
            L8_2 = L8_2.AddDisc
            L9_2 = tHelpers
            L9_2 = L9_2[A0_2]
            L9_2 = L9_2.uDiscHelp
            L10_2 = 3
            L11_2 = 255
            L12_2 = 255
            L13_2 = 0
            L14_2 = 0.05
            L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
            L7_2.uMarker = L8_2
          end
          L7_2 = MrxSubtitle
          L7_2 = L7_2.Add
          L8_2 = "[buildings.repairBay.noFunds]"
          L7_2(L8_2)
          L7_2 = tEvents
          L7_2 = L7_2[A0_2]
          L8_2 = Event
          L8_2 = L8_2.Create
          L9_2 = Event
          L9_2 = L9_2.TimerRelative
          L10_2 = {}
          L11_2 = 5
          L10_2[1] = L11_2
          L11_2 = SetupActivationEvents
          L12_2 = {}
          L13_2 = A0_2
          L12_2[1] = L13_2
          L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
          L7_2.uRecycle = L8_2
        end
    end
  end
  else
    L7_2 = tMarker
    L7_2 = L7_2[A0_2]
    L7_2 = L7_2.uMarker
    if L7_2 then
      L7_2 = Marker
      L7_2 = L7_2.Remove
      L8_2 = tMarker
      L8_2 = L8_2[A0_2]
      L8_2 = L8_2.uMarker
      L7_2(L8_2)
      L7_2 = tMarker
      L7_2 = L7_2[A0_2]
      L8_2 = Marker
      L8_2 = L8_2.AddDisc
      L9_2 = tHelpers
      L9_2 = L9_2[A0_2]
      L9_2 = L9_2.uDiscHelp
      L10_2 = 3
      L11_2 = 255
      L12_2 = 255
      L13_2 = 0
      L14_2 = 0.05
      L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
      L7_2.uMarker = L8_2
    end
    L7_2 = tEvents
    L7_2 = L7_2[A0_2]
    L8_2 = Event
    L8_2 = L8_2.Create
    L9_2 = Event
    L9_2 = L9_2.TimerRelative
    L10_2 = {}
    L11_2 = 5
    L10_2[1] = L11_2
    L11_2 = SetupActivationEvents
    L12_2 = {}
    L13_2 = A0_2
    L12_2[1] = L13_2
    L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
    L7_2.uRecycle = L8_2
  end
end

InitiateRepair = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L3_2 = Player
  L3_2 = L3_2.GetPrimaryPlayer
  L3_2 = L3_2()
  L4_2 = Player
  L4_2 = L4_2.GetCamera
  L5_2 = L3_2
  L4_2 = L4_2(L5_2)
  L5_2 = {}
  L6_2 = -15.5
  L7_2 = 14.5
  L8_2 = -30.5
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L6_2 = {}
  L7_2 = 7.064171
  L8_2 = 0
  L9_2 = 1.165347
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L7_2 = Object
  L7_2 = L7_2.GetPosition
  L8_2 = A0_2
  L7_2, L8_2, L9_2 = L7_2(L8_2)
  L10_2 = Player
  L10_2 = L10_2.SetCinematicMode
  L11_2 = L3_2
  L12_2 = true
  L10_2(L11_2, L12_2)
  L10_2 = Camera
  L10_2 = L10_2.SetPosition
  L11_2 = L4_2
  L12_2 = L5_2[1]
  L12_2 = L7_2 + L12_2
  L13_2 = L5_2[2]
  L13_2 = L8_2 + L13_2
  L14_2 = L5_2[3]
  L14_2 = L9_2 + L14_2
  L10_2(L11_2, L12_2, L13_2, L14_2)
  L10_2 = Camera
  L10_2 = L10_2.SetLookAt
  L11_2 = L4_2
  L12_2 = A0_2
  L13_2 = false
  L10_2(L11_2, L12_2, L13_2)
  L10_2 = tEvents
  L10_2 = L10_2[A0_2]
  L11_2 = Event
  L11_2 = L11_2.Create
  L12_2 = Event
  L12_2 = L12_2.TimerRelative
  L13_2 = {}
  L14_2 = 1
  L13_2[1] = L14_2
  L14_2 = Repair
  L15_2 = {}
  L16_2 = A0_2
  L17_2 = A1_2
  L18_2 = L3_2
  L19_2 = L4_2
  L15_2[1] = L16_2
  L15_2[2] = L17_2
  L15_2[3] = L18_2
  L15_2[4] = L19_2
  L11_2 = L11_2(L12_2, L13_2, L14_2, L15_2)
  L10_2.uRepairReady = L11_2
end

StartCinematic = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L4_2 = Object
  L4_2 = L4_2.GetParent
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  L5_2 = Object
  L5_2 = L5_2.CloseGate
  L6_2 = A0_2
  L5_2(L6_2)
  L5_2 = Event
  L5_2 = L5_2.Create
  L6_2 = Event
  L6_2 = L6_2.TimerRelative
  L7_2 = {}
  L8_2 = 1
  L7_2[1] = L8_2
  L8_2 = Vehicle
  L8_2 = L8_2.Exit
  L9_2 = {}
  L10_2 = A1_2
  L11_2 = A2_2
  L12_2 = true
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L9_2[3] = L12_2
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L5_2 = Event
  L5_2 = L5_2.Create
  L6_2 = Event
  L6_2 = L6_2.TimerRelative
  L7_2 = {}
  L8_2 = 1.5
  L7_2[1] = L8_2
  
  function L8_2(A0_3, A1_3, A2_3, A3_3)
    local L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3
    if A1_3 then
      L4_3 = Object
      L4_3 = L4_3.IsAlive
      L5_3 = A1_3
      L4_3 = L4_3(L5_3)
      if L4_3 then
        L4_3 = Object
        L4_3 = L4_3.GetHealth
        L5_3 = A1_3
        L4_3 = L4_3(L5_3)
        if 5 < L4_3 then
          L4_3 = Object
          L4_3 = L4_3.GetHardpointPosition
          L5_3 = A0_3
          L6_3 = "hp_veh_spawn"
          L4_3, L5_3, L6_3 = L4_3(L5_3, L6_3)
          L7_3 = Object
          L7_3 = L7_3.GetYaw
          L8_3 = A0_3
          L7_3 = L7_3(L8_3)
          L8_3 = {}
          L9_3 = 7.064171
          L10_3 = 0
          L11_3 = 1.165
          L8_3[1] = L9_3
          L8_3[2] = L10_3
          L8_3[3] = L11_3
          L9_3 = Pg
          L9_3 = L9_3.Spawn
          L10_3 = A2_3
          L11_3 = L4_3
          L12_3 = L5_3
          L13_3 = L6_3
          L14_3 = L7_3
          L15_3 = true
          L16_3 = true
          L17_3 = A1_3
          L9_3 = L9_3(L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3)
          L10_3 = Object
          L10_3 = L10_3.FadeOut
          L11_3 = A1_3
          L12_3 = 0.25
          L13_3 = true
          L10_3(L11_3, L12_3, L13_3)
          L10_3 = MrxPmc
          L10_3 = L10_3.AddCashQty
          L11_3 = tPrices
          L11_3 = L11_3[A0_3]
          L11_3 = L11_3.nCost
          L11_3 = -L11_3
          L12_3 = nil
          L10_3(L11_3, L12_3)
          L10_3 = SettleIn
          L11_3 = A0_3
          L12_3 = L9_3
          L13_3 = A3_3
          L10_3(L11_3, L12_3, L13_3)
      end
    end
    else
      L4_3 = MrxSubtitle
      L4_3 = L4_3.Add
      L5_3 = "[buildings.repairBay.tooDamaged]"
      L4_3(L5_3)
      L4_3 = Object
      L4_3 = L4_3.OpenGate
      L5_3 = A0_3
      L4_3(L5_3)
      L4_3 = EndCinematic
      L5_3 = A0_3
      L6_3 = A3_3
      L4_3(L5_3, L6_3)
    end
  end
  
  L9_2 = {}
  L10_2 = A0_2
  L11_2 = A1_2
  L12_2 = L4_2
  L13_2 = A2_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L9_2[3] = L12_2
  L9_2[4] = L13_2
  L5_2(L6_2, L7_2, L8_2, L9_2)
end

Repair = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 2
  L5_2[1] = L6_2
  
  function L6_2(A0_3, A1_3)
    local L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
    L2_3 = Player
    L2_3 = L2_3.GetCharacter
    L3_3 = A1_3
    L2_3 = L2_3(L3_3)
    L3_3 = Vehicle
    L3_3 = L3_3.GetDriver
    L4_3 = A1_2
    L3_3 = L3_3(L4_3)
    if L3_3 then
      L4_3 = Vehicle
      L4_3 = L4_3.Exit
      L5_3 = A1_2
      L6_3 = L3_3
      L7_3 = true
      L4_3(L5_3, L6_3, L7_3)
      L4_3 = Object
      L4_3 = L4_3.FadeOut
      L5_3 = L3_3
      L6_3 = 0.25
      L7_3 = true
      L4_3(L5_3, L6_3, L7_3)
    end
    L4_3 = Vehicle
    L4_3 = L4_3.Enter
    L5_3 = A1_2
    L6_3 = L2_3
    L7_3 = "d"
    L8_3 = true
    L9_3 = false
    L4_3 = L4_3(L5_3, L6_3, L7_3, L8_3, L9_3)
    bDriverIn = L4_3
    L4_3 = Event
    L4_3 = L4_3.Post
    L5_3 = "RepairBayUsed"
    L6_3 = {}
    L7_3 = A1_2
    L8_3 = uVeh
    L9_3 = tPrices
    L9_3 = L9_3[A0_3]
    L9_3 = L9_3.nCost
    L6_3[1] = L7_3
    L6_3[2] = L8_3
    L6_3[3] = L9_3
    L4_3(L5_3, L6_3)
    L4_3 = Object
    L4_3 = L4_3.OpenGate
    L5_3 = A0_3
    L4_3(L5_3)
    L4_3 = EndCinematic
    L5_3 = A0_3
    L6_3 = A1_3
    L4_3(L5_3, L6_3)
    L4_3 = MrxSubtitle
    L4_3 = L4_3.Add
    L5_3 = "[buildings.repairBay.repaired]"
    L4_3(L5_3)
  end
  
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A2_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
end

SettleIn = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = Player
  L2_2 = L2_2.SetCinematicMode
  L3_2 = A1_2
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = Player
  L2_2 = L2_2.GetCamera
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  L3_2 = Camera
  L3_2 = L3_2.SetYaw
  L4_2 = L2_2
  L5_2 = 0
  L3_2(L4_2, L5_2)
end

EndCinematic = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  L4_2 = Pg
  L4_2 = L4_2.FastCollectGroundVehicles
  L5_2 = L1_2
  L6_2 = L2_2
  L7_2 = L3_2
  L8_2 = 15
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L5_2 = Object
  L5_2 = L5_2.CloseGate
  L6_2 = A0_2
  L5_2(L6_2)
  L5_2 = ipairs
  L6_2 = L4_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = Object
    L10_2 = L10_2.IsAlive
    L11_2 = L9_2
    L10_2 = L10_2(L11_2)
    if not L10_2 then
      L11_2 = Object
      L11_2 = L11_2.FadeOut
      L12_2 = L9_2
      L13_2 = 1
      L14_2 = true
      L11_2(L12_2, L13_2, L14_2)
    end
  end
  L5_2 = tEvents
  L5_2 = L5_2[A0_2]
  L6_2 = Event
  L6_2 = L6_2.Create
  L7_2 = Event
  L7_2 = L7_2.ObjectProximity
  L8_2 = {}
  L9_2 = Player
  L9_2 = L9_2.GetAnyCharacter
  L9_2 = L9_2()
  L10_2 = A0_2
  L11_2 = "<"
  L12_2 = 30
  L13_2 = true
  L14_2 = false
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  L8_2[5] = L13_2
  L8_2[6] = L14_2
  L9_2 = PlayerInside
  L10_2 = {}
  L11_2 = A0_2
  L10_2[1] = L11_2
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
  L5_2.eDoorTriggerIn = L6_2
end

PlayerOutside = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Object
  L1_2 = L1_2.OpenGate
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = A0_2
  L7_2 = ">"
  L8_2 = 30
  L9_2 = true
  L10_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L5_2 = PlayerOutside
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.eDoorTriggerOut = L2_2
end

PlayerInside = L0_1
