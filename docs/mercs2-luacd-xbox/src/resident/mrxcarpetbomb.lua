local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorSatellite"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = {}
  L3_2 = setmetatable
  L4_2 = L2_2
  L5_2 = A0_2
  L3_2(L4_2, L5_2)
  A0_2.__index = A0_2
  L2_2.nTotalLines = 7
  L3_2 = L2_2.nTotalLines
  L2_2.nRemainingLines = L3_2
  L2_2.nTimeInterval = 0.35
  L3_2 = MrxSupportDesignatorSatellite
  L4_2 = L3_2
  L3_2 = L3_2.Create
  L3_2 = L3_2(L4_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetDesignator
  L6_2 = L3_2
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetRecruit
  L6_2 = "Fiona"
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetOwner
  L6_2 = A1_2
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetModuleName
  L6_2 = "MrxCarpetBomb"
  L4_2(L5_2, L6_2)
  return L2_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L1_2 = 100
  L3_2 = A0_2
  L2_2 = A0_2.GetDesignator
  L2_2 = L2_2(L3_2)
  L3_2 = L2_2
  L2_2 = L2_2.GetTarget
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  L6_2 = Camera
  L6_2 = L6_2.GetYaw
  L7_2 = Player
  L7_2 = L7_2.GetCamera
  L9_2 = A0_2
  L8_2 = A0_2.GetOwner
  L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2 = L8_2(L9_2)
  L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
  A0_2.nHeading = L6_2
  L6_2 = Pg
  L6_2 = L6_2.FindPointFromCamera
  L7_2 = -300
  L8_2 = L1_2
  L9_2 = -1
  L10_2 = A0_2.uOwner
  L6_2, L7_2, L8_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
  L9_2 = L3_2 + L1_2
  if L7_2 < L9_2 then
    L7_2 = L3_2 + L1_2
  end
  L9_2 = Airstrike
  L9_2 = L9_2.Flyby
  L10_2 = "Support Vehicle (B2)"
  L11_2 = L6_2
  L12_2 = L8_2
  L13_2 = L2_2
  L14_2 = L4_2
  L15_2 = L7_2
  L16_2 = 100
  L17_2 = DropBomb
  L18_2 = {}
  L19_2 = A0_2
  L18_2[1] = L19_2
  L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  A0_2.uJet = L9_2
  L10_2 = MrxSupport
  L10_2 = L10_2.PlayAirstrikeVO
  L11_2 = L9_2
  L12_2 = {}
  L13_2 = ""
  L12_2[1] = L13_2
  L10_2(L11_2, L12_2)
end

DesignationCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = A0_2.uJet
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  L4_2 = nil
  L5_2 = nil
  L6_2 = nil
  L5_2 = L2_2
  L7_2 = Airstrike
  L7_2 = L7_2.SpawnCarpetBombLine
  L8_2 = L1_2
  L9_2 = L2_2
  L10_2 = L3_2
  L11_2 = A0_2.nHeading
  L13_2 = A0_2
  L12_2 = A0_2.GetOwner
  L12_2 = L12_2(L13_2)
  L13_2 = nil
  L14_2 = 5
  L15_2 = 15
  L7_2, L8_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  L6_2 = L8_2
  L4_2 = L7_2
  A0_2.nNextX = L4_2
  L7_2 = math
  L7_2 = L7_2.randi
  L8_2 = 10
  L9_2 = 30
  L7_2 = L7_2(L8_2, L9_2)
  L7_2 = L5_2 + L7_2
  A0_2.nNextY = L7_2
  A0_2.nNextZ = L6_2
  L7_2 = Event
  L7_2 = L7_2.Create
  L8_2 = Event
  L8_2 = L8_2.TimerRelative
  L9_2 = {}
  L10_2 = A0_2.nTimeInterval
  L9_2[1] = L10_2
  L10_2 = NextExplosionCallback
  L11_2 = {}
  L12_2 = A0_2
  L11_2[1] = L12_2
  L7_2(L8_2, L9_2, L10_2, L11_2)
end

DropBomb = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = Airstrike
  L3_2 = L3_2.SpawnCarpetBombLine
  L4_2 = A0_2.nNextX
  L5_2 = A0_2.nNextY
  L6_2 = A0_2.nNextZ
  L7_2 = A0_2.nHeading
  L9_2 = A0_2
  L8_2 = A0_2.GetOwner
  L8_2 = L8_2(L9_2)
  L9_2 = nil
  L10_2 = 5
  L11_2 = 15
  L3_2, L4_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  L2_2 = L4_2
  L1_2 = L3_2
  A0_2.nNextX = L1_2
  A0_2.nNextZ = L2_2
  L3_2 = A0_2.nRemainingLines
  L3_2 = L3_2 - 1
  A0_2.nRemainingLines = L3_2
  L3_2 = A0_2.nRemainingLines
  if L3_2 <= 0 then
    L3_2 = A0_2.nTotalLines
    A0_2.nRemainingLines = L3_2
  else
    L3_2 = Event
    L3_2 = L3_2.Create
    L4_2 = Event
    L4_2 = L4_2.TimerRelative
    L5_2 = {}
    L6_2 = A0_2.nTimeInterval
    L5_2[1] = L6_2
    L6_2 = NextExplosionCallback
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L3_2(L4_2, L5_2, L6_2, L7_2)
  end
end

NextExplosionCallback = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = Object
  L0_2 = L0_2.GetPosition
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2 = L1_2()
  L0_2, L1_2, L2_2 = L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = Pg
  L3_2 = L3_2.Spawn
  L4_2 = "carpetbomb_explosion"
  L5_2 = L0_2
  L6_2 = L1_2
  L7_2 = L2_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
end

explode = L0_1
