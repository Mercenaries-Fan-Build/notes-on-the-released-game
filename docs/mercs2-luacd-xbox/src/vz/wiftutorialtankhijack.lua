local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTutorial"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)

function L0_1()
  local L0_2, L1_2
  L0_2 = "[Tutorial.TankHijack]"
  return L0_2
end

GetMessage = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2 = L1_2()
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = "tank"
  L7_2 = L1_2
  L8_2 = "<"
  L9_2 = 20
  L10_2 = false
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = A0_2.ActivateTutorial2
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

SetupActivationCriteria = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if L2_2 == "table" then
    L2_2 = pairs
    L3_2 = A1_2
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2, L6_2 in L2_2, L3_2, L4_2 do
      L7_2 = Vehicle
      L7_2 = L7_2.GetRiders
      L8_2 = L6_2
      L9_2 = "g"
      L7_2 = L7_2(L8_2, L9_2)
      L8_2 = nil
      L9_2 = MrxFactionManager
      L9_2 = L9_2.GetFactionStringAbbrev
      L10_2 = L6_2
      L9_2 = L9_2(L10_2)
      L10_2 = MrxFactionManager
      L10_2 = L10_2.GetFactionStringAbbrev
      L11_2 = Player
      L11_2 = L11_2.GetLocalCharacter
      L11_2, L12_2, L13_2 = L11_2()
      L10_2 = L10_2(L11_2, L12_2, L13_2)
      L11_2 = MrxFactionManager
      L11_2 = L11_2.GetAttitudeLabel
      L12_2 = L10_2
      L13_2 = L9_2
      L11_2 = L11_2(L12_2, L13_2)
      if L11_2 == "Hostile" then
      end
      L12_2 = type
      L13_2 = L7_2
      L12_2 = L12_2(L13_2)
      if L12_2 == "table" then
        L12_2 = table
        L12_2 = L12_2.getn
        L13_2 = L7_2
        L12_2 = L12_2(L13_2)
        L8_2 = L12_2
      end
      if L8_2 and 1 < L8_2 then
      else
        return
      end
    end
  end
  L3_2 = A0_2
  L2_2 = A0_2.ActivateTutorial
  L2_2(L3_2)
end

ActivateTutorial2 = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  if A1_2 == true then
    A1_2 = false
  end
  L2_2 = MrxTutorial
  L2_2 = L2_2.EndTutorial
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

EndTutorial = L0_1
