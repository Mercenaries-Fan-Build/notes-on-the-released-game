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
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
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
    L6_2, L7_2, L8_2, L9_2 = L6_2(L7_2)
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
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
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = 3
  L6_2[1] = L7_2
  L7_2 = Salvo
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
end

Start = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = Player
  L2_2 = L2_2.GetLocalCharacter
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2 = L2_2()
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  if L1_2 then
    L4_2 = Object
    L4_2 = L4_2.IsAwake
    L5_2 = A0_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      goto lbl_16
    end
  end
  do return end
  ::lbl_16::
  L4_2 = Pg
  L4_2 = L4_2.FastCollectGroundVehicles
  L5_2 = L1_2
  L6_2 = L2_2
  L7_2 = L3_2
  L8_2 = 200
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L5_2 = pairs
  L6_2 = L4_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = uLastTarget
    if L9_2 ~= L10_2 then
      L10_2 = Object
      L10_2 = L10_2.IsAlive
      L11_2 = L9_2
      L10_2 = L10_2(L11_2)
      if L10_2 then
        L10_2 = Object
        L10_2 = L10_2.HasLabel
        L11_2 = L9_2
        L12_2 = "VZ"
        L10_2 = L10_2(L11_2, L12_2)
        if not L10_2 then
          L10_2 = Object
          L10_2 = L10_2.HasLabel
          L11_2 = L9_2
          L12_2 = "China"
          L10_2 = L10_2(L11_2, L12_2)
          if not L10_2 then
            L10_2 = Object
            L10_2 = L10_2.HasLabel
            L11_2 = L9_2
            L12_2 = "Guerilla"
            L10_2 = L10_2(L11_2, L12_2)
            if not L10_2 then
              goto lbl_59
            end
          end
        end
        uTarget = L9_2
        break
      end
    end
    ::lbl_59::
  end
  L5_2 = uTarget
  uLastTarget = L5_2
  L5_2 = uTarget
  if L5_2 then
    L5_2 = 1
    L6_2 = 4
    L7_2 = 1
    for L8_2 = L5_2, L6_2, L7_2 do
      L9_2 = Event
      L9_2 = L9_2.Create
      L10_2 = Event
      L10_2 = L10_2.TimerRelative
      L11_2 = {}
      L12_2 = 0.25 * L8_2
      L11_2[1] = L12_2
      L12_2 = LaunchMissile
      L13_2 = {}
      L14_2 = A0_2
      L15_2 = uTarget
      L13_2[1] = L14_2
      L13_2[2] = L15_2
      L9_2(L10_2, L11_2, L12_2, L13_2)
    end
  else
  end
  L5_2 = Event
  L5_2 = L5_2.Create
  L6_2 = Event
  L6_2 = L6_2.TimerRelative
  L7_2 = {}
  L8_2 = 3
  L7_2[1] = L8_2
  L8_2 = Salvo
  L9_2 = {}
  L10_2 = A0_2
  L11_2 = uTarget
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L5_2(L6_2, L7_2, L8_2, L9_2)
end

Salvo = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  if not A1_2 then
    return
  end
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = A0_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L5_2 = Object
  L5_2 = L5_2.GetPosition
  L6_2 = A1_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  if not L5_2 or not L2_2 then
    return
  end
  L8_2 = math
  L8_2 = L8_2.randi
  L9_2 = 5
  L8_2 = L8_2(L9_2)
  L8_2 = L5_2 + L8_2
  L9_2 = math
  L9_2 = L9_2.randi
  L10_2 = 5
  L9_2 = L9_2(L10_2)
  L5_2 = L8_2 - L9_2
  L8_2 = math
  L8_2 = L8_2.randi
  L9_2 = 5
  L8_2 = L8_2(L9_2)
  L8_2 = L7_2 + L8_2
  L9_2 = math
  L9_2 = L9_2.randi
  L10_2 = 5
  L9_2 = L9_2(L10_2)
  L7_2 = L8_2 - L9_2
  L8_2 = L5_2 - L2_2
  L9_2 = L6_2 - L3_2
  L10_2 = L7_2 - L4_2
  L11_2 = Math
  L11_2 = L11_2.Normalize
  L12_2 = L8_2
  L13_2 = L9_2
  L14_2 = L10_2
  L11_2, L12_2, L13_2 = L11_2(L12_2, L13_2, L14_2)
  L10_2 = L13_2
  L9_2 = L12_2
  L8_2 = L11_2
  L11_2 = Sound
  L11_2 = L11_2.CueSound
  L12_2 = A0_2
  L13_2 = "wpn_tankgun_fire_npc"
  L11_2(L12_2, L13_2)
  L11_2 = Pg
  L11_2 = L11_2.Spawn
  L12_2 = "global_particle_muzzleflash_tank"
  L13_2 = L2_2
  L14_2 = L3_2
  L15_2 = L4_2
  L11_2(L12_2, L13_2, L14_2, L15_2)
  L11_2 = 100
  L12_2 = Airstrike
  L12_2 = L12_2.SpawnOrdnance
  L13_2 = "Gunship Shell"
  L14_2 = L2_2
  L15_2 = L3_2
  L16_2 = L4_2
  L17_2 = L8_2 * L11_2
  L18_2 = L9_2 * L11_2
  L19_2 = L10_2 * L11_2
  L20_2 = "impact"
  L21_2 = 1
  L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
end

LaunchMissile = L0_1
