local L0_1, L1_1, L2_1
L0_1 = inherit
L1_1 = "MrxSupport"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorSmoke"
L2_1 = false
L0_1(L1_1, L2_1)

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
  L6_2 = nil
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetOwner
  L6_2 = A1_2
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetRecruit
  L6_2 = "Pilot"
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetDesignator
  L6_2 = L3_2
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetModuleName
  L6_2 = "MrxTankBuster"
  L4_2(L5_2, L6_2)
  return L2_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L1_2 = Pg
  L1_2 = L1_2.FindPointFromCamera
  L2_2 = 400
  L3_2 = 150
  L4_2 = -1
  L5_2 = A0_2.uOwner
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  L4_2 = Pg
  L4_2 = L4_2.FindPointFromCamera
  L5_2 = 200
  L6_2 = 60
  L7_2 = -1
  L8_2 = A0_2.uOwner
  L4_2, L5_2, L6_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L7_2 = Airstrike
  L7_2 = L7_2.Flyby
  L8_2 = A0_2.uDeliveryVehicle
  L9_2 = L1_2
  L10_2 = L3_2
  L11_2 = L4_2
  L12_2 = L6_2
  L13_2 = L5_2
  L14_2 = 120
  L15_2 = Strike
  L16_2 = {}
  L17_2 = A0_2
  L16_2[1] = L17_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
  A0_2.uJet = L7_2
  L7_2 = Event
  L7_2 = L7_2.Create
  L8_2 = Event
  L8_2 = L8_2.TimerRelative
  L9_2 = {}
  L10_2 = 3
  L9_2[1] = L10_2
  L10_2 = MrxSupport
  L10_2 = L10_2.PlayAirstrikeVO
  L11_2 = {}
  L12_2 = A0_2.uJet
  L13_2 = {}
  L14_2 = "Misha-None-Freeplay-Support-07"
  L15_2 = "Misha-None-Freeplay-Support-11"
  L16_2 = "Misha-None-Freeplay-Support-13"
  L17_2 = "Misha-None-Freeplay-Support-22"
  L18_2 = "Misha-None-Freeplay-Support-33"
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L13_2[3] = L16_2
  L13_2[4] = L17_2
  L13_2[5] = L18_2
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L7_2(L8_2, L9_2, L10_2, L11_2)
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
  L5_2 = Pg
  L5_2 = L5_2.FastCollectTanks
  L6_2 = L2_2
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = 200
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = 0
  L7_2 = ipairs
  L8_2 = L5_2
  L7_2, L8_2, L9_2 = L7_2(L8_2)
  for L10_2, L11_2 in L7_2, L8_2, L9_2 do
    L12_2 = Vehicle
    L12_2 = L12_2.GetDriver
    L13_2 = L11_2
    L12_2 = L12_2(L13_2)
    L13_2 = Object
    L13_2 = L13_2.IsAlive
    L14_2 = L11_2
    L13_2 = L13_2(L14_2)
    if L13_2 then
      if L12_2 then
        L13_2 = Object
        L13_2 = L13_2.HasLabel
        L14_2 = L12_2
        L15_2 = "PMC"
        L13_2 = L13_2(L14_2, L15_2)
        if L13_2 then
          goto lbl_54
        end
      end
      L13_2 = Event
      L13_2 = L13_2.Create
      L14_2 = Event
      L14_2 = L14_2.TimerRelative
      L15_2 = {}
      L16_2 = 0.2 * L6_2
      L15_2[1] = L16_2
      L16_2 = LaunchMissile
      L17_2 = {}
      L18_2 = A0_2
      L19_2 = L11_2
      L17_2[1] = L18_2
      L17_2[2] = L19_2
      L13_2(L14_2, L15_2, L16_2, L17_2)
      L6_2 = L6_2 + 1
    end
    ::lbl_54::
  end
end

Strike = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = A0_2.uJet
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L5_2 = Object
  L5_2 = L5_2.GetPosition
  L6_2 = A1_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
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
  L11_2 = 30
  L12_2 = Airstrike
  L12_2 = L12_2.SpawnTargettedOrdnance
  L13_2 = "Airstrike AT Missile"
  L14_2 = L2_2
  L15_2 = L3_2
  L16_2 = L4_2
  L17_2 = L8_2
  L18_2 = L9_2
  L19_2 = L10_2
  L20_2 = A1_2
  L21_2 = "impact"
  L22_2 = nil
  L24_2 = A0_2
  L23_2 = A0_2.GetOwner
  L23_2 = L23_2(L24_2)
  L24_2 = Object
  L24_2 = L24_2.Kill
  L25_2 = {}
  L26_2 = A1_2
  L25_2[1] = L26_2
  L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2)
  L13_2 = BlipAircraft
  L14_2 = L12_2
  L15_2 = {}
  L16_2 = 255
  L17_2 = 0
  L18_2 = 0
  L15_2[1] = L16_2
  L15_2[2] = L17_2
  L15_2[3] = L18_2
  L13_2(L14_2, L15_2)
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
