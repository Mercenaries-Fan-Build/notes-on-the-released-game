local L0_1, L1_1, L2_1, L3_1
L0_1 = tEvents
if not L0_1 then
  L0_1 = {}
end
tEvents = L0_1
L0_1 = inherit
L1_1 = "VehicleBlippable"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupport"
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
L0_1 = {}
tCopters = L0_1
L0_1 = {}
tRetries = L0_1

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
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = getfenv
  L3_2 = L3_2()
  self = L3_2
  L3_2 = table
  L3_2 = L3_2.insert
  L4_2 = tCopters
  L5_2 = A0_2
  L3_2(L4_2, L5_2)
  L3_2 = FindLZ
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L4_2 = MrxSupport
    L4_2 = L4_2.GoHome
    L5_2 = self
    L6_2 = A0_2
    L4_2(L5_2, L6_2)
    L4_2 = table
    L4_2 = L4_2.remove
    L5_2 = tCopters
    L6_2 = 1
    L4_2(L5_2, L6_2)
  end
end

Start = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L4_2 = tCopters
  if not L4_2 then
    return
  end
  L4_2 = tCopters
  L4_2 = L4_2[1]
  if not A0_2 then
    L5_2 = tRetries
    L6_2 = tRetries
    L6_2 = L6_2[L4_2]
    if not L6_2 then
      L6_2 = 0
    end
    L5_2[L4_2] = L6_2
    L5_2 = tRetries
    L6_2 = tRetries
    L6_2 = L6_2[L4_2]
    L6_2 = L6_2 + 1
    L5_2[L4_2] = L6_2
    L5_2 = tRetries
    L5_2 = L5_2[L4_2]
    if 3 < L5_2 then
      L5_2 = MrxSupport
      L5_2 = L5_2.GoHome
      L6_2 = self
      L7_2 = L4_2
      L5_2(L6_2, L7_2)
      L5_2 = table
      L5_2 = L5_2.remove
      L6_2 = tCopters
      L7_2 = 1
      L5_2(L6_2, L7_2)
      return
    else
      L5_2 = Object
      L5_2 = L5_2.GetPosition
      L6_2 = Player
      L6_2 = L6_2.GetLocalCharacter
      L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L6_2()
      L5_2, L6_2, L7_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
      L8_2 = Ai
      L8_2 = L8_2.Goal
      L9_2 = {}
      L10_2 = Vehicle
      L10_2 = L10_2.GetDriver
      L11_2 = L4_2
      L10_2 = L10_2(L11_2)
      L9_2.AIGuid = L10_2
      L9_2.Goal = "MoveTo"
      L10_2 = {}
      L11_2 = L5_2
      L12_2 = L6_2 + 50
      L13_2 = L7_2
      L10_2[1] = L11_2
      L10_2[2] = L12_2
      L10_2[3] = L13_2
      L9_2.Location = L10_2
      L9_2.Priority = "hiPri"
      L8_2(L9_2)
      L8_2 = Event
      L8_2 = L8_2.Create
      L9_2 = Event
      L9_2 = L9_2.TimerRelative
      L10_2 = {}
      L11_2 = 3
      L10_2[1] = L11_2
      L11_2 = FindLZ
      L12_2 = {}
      L13_2 = L4_2
      L12_2[1] = L13_2
      L8_2(L9_2, L10_2, L11_2, L12_2)
      return
    end
  end
  L5_2 = self
  L6_2 = Ai
  L6_2 = L6_2.Goal
  L7_2 = {}
  L8_2 = Vehicle
  L8_2 = L8_2.GetDriver
  L9_2 = L4_2
  L8_2 = L8_2(L9_2)
  L7_2.AIGuid = L8_2
  L7_2.Goal = "HeliLand"
  L8_2 = {}
  L9_2 = A1_2
  L10_2 = A2_2
  L11_2 = A3_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L7_2.Location = L8_2
  L7_2.Priority = "hiPri"
  L8_2 = AllOut
  L7_2.Callback = L8_2
  L8_2 = {}
  L9_2 = self
  L10_2 = L4_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L7_2.CallbackData = L8_2
  L6_2 = L6_2(L7_2)
  L5_2.LandGoal = L6_2
  L5_2 = self
  L6_2 = L5_2
  L5_2 = L5_2.Create
  L7_2 = L4_2
  L8_2 = uRuntimeOwner
  L5_2 = L5_2(L6_2, L7_2, L8_2)
  L6_2 = table
  L6_2 = L6_2.remove
  L7_2 = tCopters
  L8_2 = 1
  L6_2(L7_2, L8_2)
end

FoundPosition = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  if A2_2 == 0 then
    L3_2 = MrxSupport
    L3_2 = L3_2.GoHome
    L4_2 = A0_2
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
    return
  end
  L3_2 = Ai
  L3_2 = L3_2.Deploy
  L4_2 = {}
  L4_2.Vehicle = A1_2
  L4_2.Role = "Passenger"
  L4_2.Force = true
  L4_2.MaintainRotorSpeed = true
  L5_2 = MrxSupport
  L5_2 = L5_2.GoHome
  L4_2.Callback = L5_2
  L5_2 = {}
  L6_2 = A0_2
  L7_2 = A1_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2.CallbackData = L5_2
  L3_2(L4_2)
end

AllOut = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = Player
  L2_2 = L2_2.GetLocalCharacter
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L2_2()
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  L4_2 = {}
  L4_2.nHeightMax = 20
  L4_2.nInnerRadius = 6
  L4_2.nOuterRadius = 19
  L4_2.nInnerHeightTolerance = 1
  L4_2.nOuterHeightTolerance = 2.5
  L5_2 = Ai
  L5_2 = L5_2.TestDropZone
  L6_2 = {}
  L7_2 = FoundPosition
  L6_2.Callback = L7_2
  L7_2 = {}
  L8_2 = L1_2
  L9_2 = L2_2
  L10_2 = L3_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L6_2.Location = L7_2
  L7_2 = L4_2.nInnerRadius
  L6_2.InnerRadius = L7_2
  L7_2 = L4_2.nInnerHeightTolerance
  L6_2.InnerHeightTolerance = L7_2
  L7_2 = L4_2.nOuterRadius
  L6_2.OuterRadius = L7_2
  L7_2 = L4_2.nOuterHeightTolerance
  L6_2.OuterHeightTolerance = L7_2
  L7_2 = L4_2.nHeightMax
  L6_2.HeightMax = L7_2
  L6_2.SearchRadius = 40
  L6_2.Water = false
  L5_2 = L5_2(L6_2)
  return L5_2
end

FindLZ = L0_1
