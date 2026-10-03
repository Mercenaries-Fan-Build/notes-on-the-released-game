local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1
L0_1 = inherit
L1_1 = "MrxTutorial"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = {}
L1_1 = "OC"
L2_1 = "Pirate"
L3_1 = "Guerilla"
L4_1 = "Allied"
L5_1 = "China"
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1
L0_1[5] = L5_1
tFactions = L0_1
L0_1 = {}
L1_1 = {}
L2_1 = 2463.2
L3_1 = 1
L4_1 = 1492.27
L1_1[1] = L2_1
L1_1[2] = L3_1
L1_1[3] = L4_1
L2_1 = {}
L3_1 = 2140.88
L4_1 = 1
L5_1 = 2600.9
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L3_1 = {}
L4_1 = 1582.65
L5_1 = 1
L6_1 = -2408.16
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L4_1 = {}
L5_1 = 287.89
L6_1 = 1
L7_1 = 153.89
L4_1[1] = L5_1
L4_1[2] = L6_1
L4_1[3] = L7_1
L5_1 = {}
L6_1 = -2390.02
L7_1 = 1
L8_1 = 1128.63
L5_1[1] = L6_1
L5_1[2] = L7_1
L5_1[3] = L8_1
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1
L0_1[5] = L5_1
tPositions = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = "[Tutorial.VehicleHorn.Attract]"
  return L0_2
end

GetMessage = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.OnExitSeat
  L1_2(L2_2)
end

SetupActivationCriteria = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectInSeat
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetLocalCharacter
  L5_2 = L5_2()
  L6_2 = 0
  L7_2 = "a"
  L8_2 = "x"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = OnExitSeat
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = pairs
  L2_2 = tFactions
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L7_2 = A0_2
    L6_2 = A0_2.CreateEvent
    L8_2 = L4_2
    L6_2(L7_2, L8_2)
  end
end

OnEnterSeat = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.DestroyEvents
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectInSeat
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetLocalCharacter
  L5_2 = L5_2()
  L6_2 = 0
  L7_2 = "d"
  L8_2 = "e"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = OnEnterSeat
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

OnExitSeat = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetLocalCharacter
  L6_2 = L6_2()
  L7_2 = tPositions
  L7_2 = L7_2[A1_2]
  L7_2 = L7_2[1]
  L8_2 = tPositions
  L8_2 = L8_2[A1_2]
  L8_2 = L8_2[2]
  L9_2 = tPositions
  L9_2 = L9_2[A1_2]
  L9_2 = L9_2[3]
  L10_2 = "<"
  L11_2 = 500
  L12_2 = false
  L13_2 = true
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L5_2[7] = L12_2
  L5_2[8] = L13_2
  L6_2 = WithinRegion
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A1_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

CreateEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = Ai
  L2_2 = L2_2.GetRelation
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = tFactions
  L4_2 = L4_2[A1_2]
  L3_2 = L3_2(L4_2)
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "PMC"
  L4_2, L5_2 = L4_2(L5_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  if 0 < L2_2 then
    L4_2 = A0_2
    L3_2 = A0_2.ActivateTutorial
    L5_2 = true
    L3_2 = L3_2(L4_2, L5_2)
  end
end

WithinRegion = L0_1
