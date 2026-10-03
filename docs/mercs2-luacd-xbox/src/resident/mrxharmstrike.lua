local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorBeacon"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = {}
  L3_2 = setmetatable
  L4_2 = L2_2
  L5_2 = A0_2
  L3_2(L4_2, L5_2)
  A0_2.__index = A0_2
  L3_2 = MrxSupportDesignatorBeacon
  L4_2 = L3_2
  L3_2 = L3_2.Create
  L3_2 = L3_2(L4_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetDesignator
  L6_2 = L3_2
  L4_2(L5_2, L6_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetAATestLevel
  L6_2 = "advanced"
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
  L6_2 = "MrxHARMStrike"
  L4_2(L5_2, L6_2)
  return L2_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2
  L1_2 = 0
  L2_2 = 200
  L3_2 = Pg
  L3_2 = L3_2.FindPointFromCamera
  L4_2 = 300
  L5_2 = 35
  L6_2 = -1
  L7_2 = A0_2.uOwner
  L3_2, L4_2, L5_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L6_2 = Object
  L6_2 = L6_2.GetPosition
  L7_2 = Player
  L7_2 = L7_2.GetCharacter
  L8_2 = A0_2.uOwner
  L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2 = L7_2(L8_2)
  L6_2, L7_2, L8_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2)
  L9_2 = L8_2 - L5_2
  L9_2 = L9_2 * -1
  L10_2 = L6_2 - L3_2
  L11_2 = Math
  L11_2 = L11_2.Normalize
  L12_2 = L9_2
  L13_2 = 0
  L14_2 = L10_2
  L11_2, L12_2, L13_2 = L11_2(L12_2, L13_2, L14_2)
  L11_2 = L11_2 * L1_2
  L13_2 = L13_2 * L1_2
  L14_2 = L3_2 - L6_2
  L15_2 = 0
  L16_2 = L5_2 - L8_2
  L17_2 = Math
  L17_2 = L17_2.Normalize
  L18_2 = L14_2
  L19_2 = 0
  L20_2 = L16_2
  L17_2, L18_2, L19_2 = L17_2(L18_2, L19_2, L20_2)
  L16_2 = L19_2
  L15_2 = L18_2
  L14_2 = L17_2
  L14_2 = L14_2 * L2_2
  L16_2 = L16_2 * L2_2
  L17_2 = Airstrike
  L17_2 = L17_2.Flyby
  L18_2 = "Support Vehicle (F117)"
  L19_2 = L3_2
  L20_2 = L5_2
  L21_2 = L3_2 + L11_2
  L22_2 = L6_2 - L3_2
  L21_2 = L21_2 + L22_2
  L21_2 = L21_2 + L14_2
  L22_2 = L5_2 + L13_2
  L23_2 = L8_2 - L5_2
  L22_2 = L22_2 + L23_2
  L22_2 = L22_2 + L16_2
  L23_2 = L7_2 + 35
  L24_2 = 80
  L25_2 = Strike
  L26_2 = {}
  L27_2 = A0_2
  L26_2[1] = L27_2
  L17_2 = L17_2(L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2)
  A0_2.uJet = L17_2
  L18_2 = Sound
  L18_2 = L18_2.CueSound
  L19_2 = 0
  L20_2 = "vo_allies_a_Yes01"
  L18_2(L19_2, L20_2)
  L18_2 = Sound
  L18_2 = L18_2.CueSound
  L19_2 = 0
  L20_2 = "veh_b52_flyby"
  L18_2(L19_2, L20_2)
end

DesignationCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L1_2 = Player
  L1_2 = L1_2.GetCharacter
  L2_2 = A0_2.uOwner
  L1_2 = L1_2(L2_2)
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L5_2 = ObjectFilter
  L5_2 = L5_2.Create
  L5_2 = L5_2()
  L7_2 = L5_2
  L6_2 = L5_2.SetFilter
  L8_2 = "AA (Medium)"
  L6_2(L7_2, L8_2)
  L7_2 = L5_2
  L6_2 = L5_2.SetRelation
  L8_2 = L1_2
  L9_2 = "<"
  L10_2 = 0
  L6_2(L7_2, L8_2, L9_2, L10_2)
  L6_2 = Pg
  L6_2 = L6_2.FastCollectGroundVehicles
  L7_2 = L2_2
  L8_2 = L3_2
  L9_2 = L4_2
  L10_2 = 200
  L11_2 = L5_2
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  L7_2 = 0
  L8_2 = ipairs
  L9_2 = L6_2
  L8_2, L9_2, L10_2 = L8_2(L9_2)
  for L11_2, L12_2 in L8_2, L9_2, L10_2 do
    L13_2 = Vehicle
    L13_2 = L13_2.GetDriver
    L14_2 = L12_2
    L13_2 = L13_2(L14_2)
    if L13_2 then
      L13_2 = Event
      L13_2 = L13_2.Create
      L14_2 = Event
      L14_2 = L14_2.TimerRelative
      L15_2 = {}
      L16_2 = 0.4 * L7_2
      L15_2[1] = L16_2
      L16_2 = LaunchMissile
      L17_2 = {}
      L18_2 = A0_2
      L19_2 = L12_2
      L17_2[1] = L18_2
      L17_2[2] = L19_2
      L13_2(L14_2, L15_2, L16_2, L17_2)
      L7_2 = L7_2 + 1
    end
  end
end

Strike = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Object
  L1_2 = L1_2.GetPos
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
end

BombExplodes = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = A0_2.uJet
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L5_2 = Object
  L5_2 = L5_2.Get
  L6_2 = nil
  L7_2 = nil
  L8_2 = Object
  L8_2 = L8_2.GetPosition
  L9_2 = A1_2
  L8_2, L9_2, L10_2 = L8_2(L9_2)
  L11_2 = L8_2 - L2_2
  L12_2 = L9_2 - L3_2
  L13_2 = L10_2 - L4_2
  L14_2 = Math
  L14_2 = L14_2.Normalize
  L15_2 = L11_2
  L16_2 = L12_2
  L17_2 = L13_2
  L14_2, L15_2, L16_2 = L14_2(L15_2, L16_2, L17_2)
  L13_2 = L16_2
  L12_2 = L15_2
  L11_2 = L14_2
  L14_2 = 30
  L15_2 = Airstrike
  L15_2 = L15_2.SpawnTargettedOrdnance
  L16_2 = "Vehicle AT Missile"
  L17_2 = L2_2
  L18_2 = L3_2
  L19_2 = L4_2
  L20_2 = L11_2 * L14_2
  L21_2 = L14_2
  L22_2 = L13_2 * L14_2
  L23_2 = A1_2
  L24_2 = "impact"
  L25_2 = 1
  L26_2 = nil
  L27_2 = BombExplodes
  L28_2 = {}
  L29_2 = uBomb
  L28_2[1] = L29_2
  L15_2 = L15_2(L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2)
end

LaunchMissile = L0_1
