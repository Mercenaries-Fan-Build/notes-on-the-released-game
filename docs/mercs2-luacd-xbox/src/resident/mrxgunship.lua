local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorSmoke"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = {}
  L3_2 = setmetatable
  L4_2 = L2_2
  L5_2 = A0_2
  L3_2(L4_2, L5_2)
  A0_2.__index = A0_2
  L3_2 = MrxSupportDesignatorSmoke
  L4_2 = L3_2
  L3_2 = L3_2.Create
  L3_2 = L3_2(L4_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetSmokeColor
  L6_2 = "red"
  L4_2(L5_2, L6_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetAATestLevel
  L6_2 = "basic"
  L4_2(L5_2, L6_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetValidationFunction
  L6_2 = _NoValidation
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetOwner
  L6_2 = A1_2
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetRecruit
  L6_2 = "Fiona"
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetDesignator
  L6_2 = L3_2
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetModuleName
  L6_2 = "MrxGunship"
  L4_2(L5_2, L6_2)
  return L2_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2
  L1_2 = Pg
  L1_2 = L1_2.FindPointFromCamera
  L2_2 = -300
  L3_2 = 60
  L4_2 = -1
  L5_2 = A0_2.uOwner
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  L4_2 = Pg
  L4_2 = L4_2.FindPointFromCamera
  L5_2 = -200
  L6_2 = 60
  L7_2 = -1
  L8_2 = A0_2.uOwner
  L4_2, L5_2, L6_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L7_2 = Object
  L7_2 = L7_2.GetPosition
  L8_2 = A0_2.uOwner
  L7_2, L8_2, L9_2 = L7_2(L8_2)
  L11_2 = A0_2
  L10_2 = A0_2.GetDesignator
  L10_2 = L10_2(L11_2)
  L11_2 = L10_2
  L10_2 = L10_2.GetTarget
  L10_2, L11_2, L12_2 = L10_2(L11_2)
  L13_2 = L10_2 - L7_2
  L14_2 = L11_2 - L8_2
  L15_2 = L12_2 - L9_2
  L16_2 = Math
  L16_2 = L16_2.Normalize
  L17_2 = L13_2
  L18_2 = L14_2
  L19_2 = L15_2
  L16_2, L17_2, L18_2 = L16_2(L17_2, L18_2, L19_2)
  L15_2 = L18_2
  L14_2 = L17_2
  L13_2 = L16_2
  L16_2 = L12_2 - L9_2
  L16_2 = -L16_2
  L17_2 = 0
  L18_2 = L10_2 - L7_2
  L19_2 = Math
  L19_2 = L19_2.Normalize
  L20_2 = L16_2
  L21_2 = L17_2
  L22_2 = L18_2
  L19_2, L20_2, L21_2 = L19_2(L20_2, L21_2, L22_2)
  L18_2 = L21_2
  L17_2 = L20_2
  L16_2 = L19_2
  L19_2 = MrxVoSequence
  L19_2 = L19_2.Start
  L20_2 = "Fiona-In-Mission-Contract-All03-20"
  L21_2 = nil
  L22_2 = MrxVoSequence
  L22_2 = L22_2.knPriorityFreeplay
  L19_2(L20_2, L21_2, L22_2)
  L19_2 = Airstrike
  L19_2 = L19_2.Flyby
  L20_2 = "Support Vehicle (AC130)"
  L21_2 = L1_2
  L22_2 = L3_2
  L23_2 = L16_2 * 30
  L23_2 = L4_2 - L23_2
  L24_2 = L18_2 * 30
  L24_2 = L6_2 - L24_2
  L25_2 = L5_2
  L26_2 = 45
  L27_2 = Salvo
  L28_2 = {}
  L29_2 = A0_2
  L28_2[1] = L29_2
  L19_2 = L19_2(L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2)
  A0_2.uJet = L19_2
end

DesignationCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L3_2 = A0_2
  L2_2 = A0_2.GetDesignator
  L2_2 = L2_2(L3_2)
  L3_2 = L2_2
  L2_2 = L2_2.GetTarget
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  if L2_2 then
    L5_2 = Object
    L5_2 = L5_2.IsAwake
    L6_2 = A0_2.uJet
    L5_2 = L5_2(L6_2)
    if L5_2 then
      L5_2 = MrxUtil
      L5_2 = L5_2.GetDistanceBetween
      L6_2 = A0_2.uJet
      L7_2 = Player
      L7_2 = L7_2.GetLocalCharacter
      L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L7_2()
      L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
      if not (300 < L5_2) then
        goto lbl_23
      end
    end
  end
  do return end
  ::lbl_23::
  L5_2 = Pg
  L5_2 = L5_2.GetAwakeObjects
  L6_2 = L2_2
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = 100
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = pairs
  L7_2 = L5_2
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  for L9_2, L10_2 in L6_2, L7_2, L8_2 do
    if L10_2 ~= A1_2 then
      L11_2 = Object
      L11_2 = L11_2.IsAlive
      L12_2 = L10_2
      L11_2 = L11_2(L12_2)
      if L11_2 then
        L11_2 = Object
        L11_2 = L11_2.HasLabel
        L12_2 = L10_2
        L13_2 = "VZ"
        L11_2 = L11_2(L12_2, L13_2)
        if not L11_2 then
          L11_2 = Object
          L11_2 = L11_2.HasLabel
          L12_2 = L10_2
          L13_2 = "China"
          L11_2 = L11_2(L12_2, L13_2)
          if not L11_2 then
            L11_2 = Object
            L11_2 = L11_2.HasLabel
            L12_2 = L10_2
            L13_2 = "Guerilla"
            L11_2 = L11_2(L12_2, L13_2)
            if not L11_2 then
              goto lbl_65
            end
          end
        end
        uTarget = L10_2
        break
      end
    end
    ::lbl_65::
  end
  L6_2 = 1
  L7_2 = 4
  L8_2 = 1
  for L9_2 = L6_2, L7_2, L8_2 do
    L10_2 = Event
    L10_2 = L10_2.Create
    L11_2 = Event
    L11_2 = L11_2.TimerRelative
    L12_2 = {}
    L13_2 = 0.25 * L9_2
    L12_2[1] = L13_2
    L13_2 = LaunchMissile
    L14_2 = {}
    L15_2 = A0_2
    L16_2 = uTarget
    L14_2[1] = L15_2
    L14_2[2] = L16_2
    L10_2(L11_2, L12_2, L13_2, L14_2)
  end
  L6_2 = Event
  L6_2 = L6_2.Create
  L7_2 = Event
  L7_2 = L7_2.TimerRelative
  L8_2 = {}
  L9_2 = 3
  L8_2[1] = L9_2
  L9_2 = Salvo
  L10_2 = {}
  L11_2 = A0_2
  L12_2 = uTarget
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L6_2(L7_2, L8_2, L9_2, L10_2)
end

Salvo = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2
  if not A1_2 then
    return
  end
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = A0_2.uJet
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
  L9_2 = 25
  L8_2 = L8_2(L9_2)
  L8_2 = L5_2 + L8_2
  L9_2 = math
  L9_2 = L9_2.randi
  L10_2 = 25
  L9_2 = L9_2(L10_2)
  L5_2 = L8_2 - L9_2
  L8_2 = math
  L8_2 = L8_2.randi
  L9_2 = 25
  L8_2 = L8_2(L9_2)
  L8_2 = L7_2 + L8_2
  L9_2 = math
  L9_2 = L9_2.randi
  L10_2 = 25
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
  L12_2 = A0_2.uJet
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
  L22_2 = uPlayer
  L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2)
end

LaunchMissile = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L5_2 = Ai
  L5_2 = L5_2.TestDropZone
  L6_2 = {}
  L6_2.Callback = A0_2
  L7_2 = {}
  L8_2 = A1_2
  L9_2 = A2_2
  L10_2 = A3_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L6_2.Location = L7_2
  L6_2.InnerRadius = 1
  L6_2.InnerHeightTolerance = 1
  L6_2.OuterRadius = 2
  L6_2.OuterHeightTolerance = 2
  L6_2.HeightMax = 5
  L6_2.SearchRadius = 12
  L6_2.Water = false
  L5_2 = L5_2(L6_2)
  if not L5_2 then
    L6_2 = A0_2
    L7_2 = false
    L8_2 = "noland"
    L6_2(L7_2, L8_2)
  end
end

_ValidateDropZone = L0_1
