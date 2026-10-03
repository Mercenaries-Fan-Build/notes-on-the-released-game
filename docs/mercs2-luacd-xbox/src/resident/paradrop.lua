local L0_1, L1_1, L2_1, L3_1
L0_1 = inherit
L1_1 = "OrientedBlippable"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = tEvents
if not L0_1 then
  L0_1 = {}
end
tEvents = L0_1
L0_1 = {}
L0_1.China = "Chinese Paratrooper"
L0_1.Allied = "Allied Paratrooper"
tTemplates = L0_1
L0_1 = "temp_radar_icon_airplane"
sTexture = L0_1
L0_1 = 5
nSize = L0_1
L0_1 = {}
L1_1 = 0
L2_1 = 127
L3_1 = 255
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
tColorAlly = L0_1
L0_1 = {}
L1_1 = 200
L2_1 = 200
L3_1 = 200
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
tColorNeutral = L0_1
L0_1 = {}
L1_1 = 255
L2_1 = 0
L3_1 = 0
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
tColorEnemy = L0_1

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
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L1_2 = getfenv
  L1_2 = L1_2()
  L3_2 = L1_2
  L2_2 = L1_2.Create
  L4_2 = A0_2
  L5_2 = uRuntimeOwner
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  L3_2 = MrxUtil
  L3_2 = L3_2.GetFaction
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L4_2 = Ai
    L4_2 = L4_2.GetRelation
    L5_2 = Pg
    L5_2 = L5_2.GetGuidByName
    L6_2 = L3_2
    L5_2 = L5_2(L6_2)
    L6_2 = Pg
    L6_2 = L6_2.GetGuidByName
    L7_2 = "PMC"
    L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2 = L6_2(L7_2)
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
    nRelation = L4_2
  else
    L4_2 = 0
    nRelation = L4_2
  end
  L4_2 = Object
  L4_2 = L4_2.HasLabel
  L5_2 = A0_2
  L6_2 = "PMC"
  L4_2 = L4_2(L5_2, L6_2)
  if L4_2 then
    L4_2 = Object
    L4_2 = L4_2.SetUnkillable
    L5_2 = A0_2
    L6_2 = true
    L7_2 = "Support"
    L4_2(L5_2, L6_2, L7_2)
  end
  L4_2 = nRelation
  if L4_2 < 60 then
    L4_2 = nRelation
    if -60 < L4_2 then
      L4_2 = tColorNeutral
      L2_2.tColor = L4_2
  end
  else
    L4_2 = nRelation
    if L4_2 <= -60 then
      L4_2 = tColorEnemy
      L2_2.tColor = L4_2
    else
      L4_2 = nRelation
      if 60 <= L4_2 then
        L4_2 = tColorAlly
        L2_2.tColor = L4_2
      end
    end
  end
  L4_2 = OrientedBlippable
  L4_2 = L4_2.SetBlipped
  L5_2 = L2_2
  L4_2(L5_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetBlipped
  L4_2(L5_2)
  L4_2 = 1
  L5_2 = 16
  L6_2 = 1
  for L7_2 = L4_2, L5_2, L6_2 do
    L8_2 = Event
    L8_2 = L8_2.Create
    L9_2 = Event
    L9_2 = L9_2.TimerRelative
    L10_2 = {}
    L11_2 = L7_2 * 0.75
    L11_2 = 5.25 + L11_2
    L10_2[1] = L11_2
    L11_2 = DropDude
    L12_2 = {}
    L13_2 = A0_2
    L14_2 = iArg
    L12_2[1] = L13_2
    L12_2[2] = L14_2
    L8_2(L9_2, L10_2, L11_2, L12_2)
  end
end

Start = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = Object
  L2_2 = L2_2.IsAlive
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
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
    L3_2 = Pg
    L3_2 = L3_2.Spawn
    L4_2 = tTemplates
    L4_2 = L4_2[L2_2]
    L5_2 = x
    L6_2 = math
    L6_2 = L6_2.randi
    L7_2 = 10
    L6_2 = L6_2(L7_2)
    L5_2 = L5_2 + L6_2
    L6_2 = math
    L6_2 = L6_2.randi
    L7_2 = 10
    L6_2 = L6_2(L7_2)
    L5_2 = L5_2 - L6_2
    L6_2 = y
    L7_2 = z
    L8_2 = math
    L8_2 = L8_2.randi
    L9_2 = 10
    L8_2 = L8_2(L9_2)
    L7_2 = L7_2 + L8_2
    L8_2 = math
    L8_2 = L8_2.randi
    L9_2 = 10
    L8_2 = L8_2(L9_2)
    L7_2 = L7_2 - L8_2
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
end

DropDude = L0_1
