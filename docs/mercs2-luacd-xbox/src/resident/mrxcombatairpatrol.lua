local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorSmoke"
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
  L5_2 = L2_2
  L4_2 = L2_2.SetDesignator
  L6_2 = L3_2
  L4_2(L5_2, L6_2)
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
  L6_2 = "MrxCombatAirPatrol"
  L4_2(L5_2, L6_2)
  L4_2 = A0_2.sDeliveryVehicle
  L2_2.sDeliveryVehicle = L4_2
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = A0_2.sDeliveryVehicle
  L4_2 = L4_2(L5_2)
  L2_2.uDeliveryVehicle = L4_2
  return L2_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L1_2 = Pg
  L1_2 = L1_2.FindPointFromCamera
  L2_2 = 300
  L3_2 = 100
  L4_2 = -1
  L5_2 = A0_2.uOwner
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  L4_2 = Pg
  L4_2 = L4_2.FindPointFromCamera
  L5_2 = 200
  L6_2 = 100
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
  L13_2 = L5_2 + 65
  L14_2 = 100
  L15_2 = Strike
  L16_2 = {}
  L17_2 = A0_2
  L16_2[1] = L17_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
  A0_2.uJet = L7_2
  L8_2 = Event
  L8_2 = L8_2.Create
  L9_2 = Event
  L9_2 = L9_2.TimerRelative
  L10_2 = {}
  L11_2 = 3
  L10_2[1] = L11_2
  L11_2 = MrxSupport
  L11_2 = L11_2.PlayAirstrikeVO
  L12_2 = {}
  L13_2 = L7_2
  L14_2 = {}
  L15_2 = "Misha-None-Freeplay-Support-07"
  L16_2 = "Misha-None-Freeplay-Support-13"
  L17_2 = "Misha-None-Freeplay-Support-15"
  L18_2 = "Misha-None-Freeplay-Support-26"
  L14_2[1] = L15_2
  L14_2[2] = L16_2
  L14_2[3] = L17_2
  L14_2[4] = L18_2
  L12_2[1] = L13_2
  L12_2[2] = L14_2
  L8_2(L9_2, L10_2, L11_2, L12_2)
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
  L6_2 = Pg
  L6_2 = L6_2.FastCollectFlying
  L7_2 = L2_2
  L8_2 = L3_2
  L9_2 = L4_2
  L10_2 = 200
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
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
      L13_2 = Object
      L13_2 = L13_2.HasLabel
      L14_2 = Vehicle
      L14_2 = L14_2.GetDriver
      L15_2 = L12_2
      L14_2 = L14_2(L15_2)
      L15_2 = "pmc"
      L13_2 = L13_2(L14_2, L15_2)
      if not L13_2 then
        L13_2 = Event
        L13_2 = L13_2.Create
        L14_2 = Event
        L14_2 = L14_2.TimerRelative
        L15_2 = {}
        L16_2 = 0.2 * L7_2
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
end

Strike = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2
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
  L11_2 = Debug
  L11_2 = L11_2.Printf
  L12_2 = "Position: "
  L13_2 = tostring
  L14_2 = L2_2
  L13_2 = L13_2(L14_2)
  L14_2 = ", "
  L15_2 = tostring
  L16_2 = L3_2
  L15_2 = L15_2(L16_2)
  L16_2 = ", "
  L17_2 = tostring
  L18_2 = L4_2
  L17_2 = L17_2(L18_2)
  L12_2 = L12_2 .. L13_2 .. L14_2 .. L15_2 .. L16_2 .. L17_2
  L11_2(L12_2)
  L11_2 = Airstrike
  L11_2 = L11_2.SpawnTargettedOrdnance
  L12_2 = "Airstrike AA Missile"
  L13_2 = L2_2
  L14_2 = L3_2
  L15_2 = L4_2
  L16_2 = L8_2
  L17_2 = L9_2
  L18_2 = L10_2
  L19_2 = A1_2
  L20_2 = "impact"
  L21_2 = nil
  L23_2 = A0_2
  L22_2 = A0_2.GetOwner
  L22_2, L23_2 = L22_2(L23_2)
  L11_2 = L11_2(L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2)
  L12_2 = BlipAircraft
  L13_2 = L11_2
  L14_2 = {}
  L15_2 = 255
  L16_2 = 0
  L17_2 = 0
  L14_2[1] = L15_2
  L14_2[2] = L16_2
  L14_2[3] = L17_2
  L12_2(L13_2, L14_2)
end

LaunchMissile = L0_1
