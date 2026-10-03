local L0_1, L1_1, L2_1, L3_1
L0_1 = tEvents
if not L0_1 then
  L0_1 = {}
end
tEvents = L0_1
L0_1 = inherit
L1_1 = "VehicleBlippable"
L0_1(L1_1)
L0_1 = {}
L1_1 = 255
L2_1 = 255
L3_1 = 255
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
tFlash = L0_1
L0_1 = "temp_radar_icon_helicopter"
sTexture = L0_1
L0_1 = 5
nSize = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectHibernation
  L5_2 = {}
  L6_2 = A0_2
  L7_2 = "awake"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = Start
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A1_2
  L10_2 = A2_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
end

OnActivate = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L3_2 = Object
  L3_2 = L3_2.GetPosition
  L4_2 = A0_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  L6_2 = ""
  L7_2 = Object
  L7_2 = L7_2.HasLabel
  L8_2 = A0_2
  L9_2 = "Blueprints"
  L7_2 = L7_2(L8_2, L9_2)
  if L7_2 then
    L7_2 = Pg
    L7_2 = L7_2.Spawn
    L8_2 = "Supply Drop (Blueprints)"
    L9_2 = L3_2
    L10_2 = L4_2 + 200
    L11_2 = L5_2
    L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
    L6_2 = L7_2
  else
    L7_2 = Object
    L7_2 = L7_2.HasLabel
    L8_2 = A0_2
    L9_2 = "Treasure"
    L7_2 = L7_2(L8_2, L9_2)
    if L7_2 then
      L7_2 = Pg
      L7_2 = L7_2.Spawn
      L8_2 = "Supply Drop (Treasure)"
      L9_2 = L3_2
      L10_2 = L4_2 + 200
      L11_2 = L5_2
      L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
      L6_2 = L7_2
    else
      L7_2 = Pg
      L7_2 = L7_2.Spawn
      L8_2 = "Supply Drop (Light MG)"
      L9_2 = L3_2
      L10_2 = L4_2 + 200
      L11_2 = L5_2
      L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
      L6_2 = L7_2
    end
  end
  L7_2 = Event
  L7_2 = L7_2.Create
  L8_2 = Event
  L8_2 = L8_2.ObjectHibernation
  L9_2 = {}
  L10_2 = L6_2
  L11_2 = "awake"
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L10_2 = _DeployWinch
  L11_2 = {}
  L12_2 = A0_2
  L13_2 = L6_2
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L7_2(L8_2, L9_2, L10_2, L11_2)
  L7_2 = getfenv
  L7_2 = L7_2()
  L9_2 = L7_2
  L8_2 = L7_2.Create
  L10_2 = A0_2
  L11_2 = A1_2
  L8_2 = L8_2(L9_2, L10_2, L11_2)
end

Start = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = Object
  L2_2 = L2_2.SetWinchState
  L3_2 = A0_2
  L4_2 = "deployed"
  L2_2(L3_2, L4_2)
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 0.1
  L4_2[1] = L5_2
  L5_2 = AttachCargo
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = A1_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
end

_DeployWinch = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = Object
  L2_2 = L2_2.AttachCargoToWinch
  L3_2 = A1_2
  L4_2 = A0_2
  L2_2(L3_2, L4_2)
end

AttachCargo = L0_1
