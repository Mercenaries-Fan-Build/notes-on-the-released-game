local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPlayer"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = _tEvents
  if L2_2 then
    L2_2 = DestroyTether
    L2_2()
  end
  L2_2 = {}
  _tEvents = L2_2
  iTetherMin = A0_2
  iTetherMax = A1_2
  L2_2 = Pg
  L2_2 = L2_2.SetBoundaryRadius
  L3_2 = 38.5
  L2_2(L3_2)
end

SetupTether = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = pairs
  L1_2 = Player
  L1_2 = L1_2.GetAllPlayers
  L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2 = L1_2()
  L0_2, L1_2, L2_2 = L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = Player
    L5_2 = L5_2.SetOutBoundary
    L6_2 = L4_2
    L7_2 = false
    L5_2(L6_2, L7_2)
  end
  L0_2 = pairs
  L1_2 = _tEvents
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = Event
    L5_2 = L5_2.Delete
    L6_2 = L4_2
    L5_2(L6_2)
  end
  L0_2 = nil
  _tEvents = L0_2
end

DestroyTether = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = _primaryChar
  if not L1_2 then
    L1_2 = A0_2
    L2_2 = Player
    L2_2 = L2_2.GetCharacter
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    _primaryChar = L2_2
  else
    L1_2 = Player
    L1_2 = L1_2.GetCharacter
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    L2_2 = tostring
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    L3_2 = GetSquaredDistance
    L4_2 = _primaryChar
    L5_2 = L1_2
    L3_2 = L3_2(L4_2, L5_2)
    L4_2 = iTetherMin
    L5_2 = iTetherMin
    L4_2 = L4_2 * L5_2
    if L3_2 < L4_2 then
      L4_2 = _TetherInsideMin
      L5_2 = _primaryChar
      L6_2 = L1_2
      L4_2(L5_2, L6_2)
    else
      L4_2 = iTetherMax
      L5_2 = iTetherMax
      L4_2 = L4_2 * L5_2
      if L3_2 > L4_2 then
        L4_2 = _TetherOutsideMax
        L5_2 = _primaryChar
        L6_2 = L1_2
        L4_2(L5_2, L6_2)
      else
        L4_2 = _TetherBetweenMinAndMax
        L5_2 = _primaryChar
        L6_2 = L1_2
        L4_2(L5_2, L6_2)
      end
    end
  end
end

AddPlayer = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L4_2 = Player
  L4_2 = L4_2.GetAllPlayers
  L4_2 = L4_2()
  L5_2 = pairs
  L6_2 = L4_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = Player
    L10_2 = L10_2.GetCharacter
    L11_2 = L9_2
    L10_2 = L10_2(L11_2)
    if L10_2 ~= nil then
      L11_2 = Object
      L11_2 = L11_2.IsAlive
      L12_2 = L10_2
      L11_2 = L11_2(L12_2)
      if L11_2 then
        L11_2 = Object
        L11_2 = L11_2.GetPosition
        L12_2 = L10_2
        L11_2, L12_2, L13_2 = L11_2(L12_2)
        L2_2 = L13_2
        L1_2 = L12_2
        L0_2 = L11_2
        L11_2 = Object
        L11_2 = L11_2.GetYaw
        L12_2 = L10_2
        L11_2 = L11_2(L12_2)
        L3_2 = L11_2
        L11_2 = L0_2
        L12_2 = L1_2
        L13_2 = L2_2
        L14_2 = L3_2
        return L11_2, L12_2, L13_2, L14_2
      end
    end
  end
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "loc_playerStart"
  L5_2 = L5_2(L6_2)
  L6_2 = Object
  L6_2 = L6_2.GetPosition
  L7_2 = L5_2
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  L2_2 = L8_2
  L1_2 = L7_2
  L0_2 = L6_2
  L6_2 = Object
  L6_2 = L6_2.GetYaw
  L7_2 = L5_2
  L6_2 = L6_2(L7_2)
  L3_2 = L6_2
  L6_2 = L0_2
  L7_2 = L1_2
  L8_2 = L2_2
  L9_2 = L3_2
  return L6_2, L7_2, L8_2, L9_2
end

GetRespawnOrigin = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L2_2 = tostring
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  L3_2 = Player
  L3_2 = L3_2.GetCharacter
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = PlayerAddMessage
  L5_2 = "INSIDE: "
  L6_2 = L2_2
  L5_2 = L5_2 .. L6_2
  L4_2(L5_2)
  L4_2 = L2_2
  L5_2 = "_in"
  L4_2 = L4_2 .. L5_2
  L5_2 = _tEvents
  L5_2[L4_2] = nil
  L5_2 = L2_2
  L6_2 = "_out"
  L5_2 = L5_2 .. L6_2
  L6_2 = Event
  L6_2 = L6_2.Delete
  L7_2 = _tEvents
  L7_2 = L7_2[L5_2]
  L6_2(L7_2)
  L6_2 = _tEvents
  L6_2[L5_2] = nil
  L6_2 = L2_2
  L7_2 = "_btw"
  L6_2 = L6_2 .. L7_2
  L7_2 = _tEvents
  L8_2 = Event
  L8_2 = L8_2.Create
  L9_2 = Event
  L9_2 = L9_2.ObjectProximity
  L10_2 = {}
  L11_2 = A0_2
  L12_2 = A1_2
  L13_2 = ">="
  L14_2 = iTetherMin
  L15_2 = false
  L16_2 = true
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L10_2[5] = L15_2
  L10_2[6] = L16_2
  L11_2 = _TetherBetweenMinAndMax
  L12_2 = {}
  L13_2 = A0_2
  L14_2 = A1_2
  L12_2[1] = L13_2
  L12_2[2] = L14_2
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
  L7_2[L6_2] = L8_2
end

_TetherInsideMin = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L2_2 = tostring
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  L3_2 = Player
  L3_2 = L3_2.GetCharacter
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = PlayerAddMessage
  L5_2 = L3_2
  L6_2 = "BETWEEN: "
  L7_2 = L2_2
  L6_2 = L6_2 .. L7_2
  L4_2(L5_2, L6_2)
  L4_2 = L2_2
  L5_2 = "_btw"
  L4_2 = L4_2 .. L5_2
  L5_2 = _tEvents
  L5_2[L4_2] = nil
  L5_2 = L2_2
  L6_2 = "_in"
  L5_2 = L5_2 .. L6_2
  L6_2 = _tEvents
  L7_2 = Event
  L7_2 = L7_2.Create
  L8_2 = Event
  L8_2 = L8_2.ObjectProximity
  L9_2 = {}
  L10_2 = A0_2
  L11_2 = A1_2
  L12_2 = "<"
  L13_2 = iTetherMin
  L14_2 = false
  L15_2 = true
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L9_2[3] = L12_2
  L9_2[4] = L13_2
  L9_2[5] = L14_2
  L9_2[6] = L15_2
  L10_2 = _TetherInsideMin
  L11_2 = {}
  L12_2 = A0_2
  L13_2 = A1_2
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
  L6_2[L5_2] = L7_2
  L6_2 = L2_2
  L7_2 = "_out"
  L6_2 = L6_2 .. L7_2
  L7_2 = _tEvents
  L8_2 = Event
  L8_2 = L8_2.Create
  L9_2 = Event
  L9_2 = L9_2.ObjectProximity
  L10_2 = {}
  L11_2 = A0_2
  L12_2 = A1_2
  L13_2 = ">="
  L14_2 = iTetherMax
  L15_2 = false
  L16_2 = true
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L10_2[5] = L15_2
  L10_2[6] = L16_2
  L11_2 = _TetherOutsideMax
  L12_2 = {}
  L13_2 = A0_2
  L14_2 = A1_2
  L12_2[1] = L13_2
  L12_2[2] = L14_2
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
  L7_2[L6_2] = L8_2
  L7_2 = Player
  L7_2 = L7_2.SetOutBoundary
  L8_2 = L3_2
  L9_2 = false
  L7_2(L8_2, L9_2)
end

_TetherBetweenMinAndMax = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L2_2 = tostring
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  L3_2 = Player
  L3_2 = L3_2.GetCharacter
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = PlayerAddMessage
  L5_2 = L3_2
  L6_2 = "OUTSIDE: "
  L7_2 = L2_2
  L6_2 = L6_2 .. L7_2
  L4_2(L5_2, L6_2)
  L4_2 = L2_2
  L5_2 = "_in"
  L4_2 = L4_2 .. L5_2
  L5_2 = Event
  L5_2 = L5_2.Delete
  L6_2 = _tEvents
  L6_2 = L6_2[L4_2]
  L5_2(L6_2)
  L5_2 = _tEvents
  L5_2[L4_2] = nil
  L5_2 = L2_2
  L6_2 = "_out"
  L5_2 = L5_2 .. L6_2
  L6_2 = _tEvents
  L6_2[L5_2] = nil
  L6_2 = L2_2
  L7_2 = "_btw"
  L6_2 = L6_2 .. L7_2
  L7_2 = _tEvents
  L8_2 = Event
  L8_2 = L8_2.Create
  L9_2 = Event
  L9_2 = L9_2.ObjectProximity
  L10_2 = {}
  L11_2 = A0_2
  L12_2 = A1_2
  L13_2 = "<"
  L14_2 = iTetherMax
  L15_2 = false
  L16_2 = true
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L10_2[5] = L15_2
  L10_2[6] = L16_2
  L11_2 = _TetherBetweenMinAndMax
  L12_2 = {}
  L13_2 = A0_2
  L14_2 = A1_2
  L12_2[1] = L13_2
  L12_2[2] = L14_2
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
  L7_2[L6_2] = L8_2
  L7_2 = Player
  L7_2 = L7_2.SetOutBoundary
  L8_2 = L3_2
  L9_2 = true
  L7_2(L8_2, L9_2)
end

_TetherOutsideMax = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = A0_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L5_2 = Object
  L5_2 = L5_2.GetPosition
  L6_2 = A1_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L8_2 = L2_2 - L5_2
  L9_2 = L3_2 - L6_2
  L10_2 = L4_2 - L7_2
  L11_2 = L8_2 * L8_2
  L12_2 = L9_2 * L9_2
  L11_2 = L11_2 + L12_2
  L12_2 = L10_2 * L10_2
  L11_2 = L11_2 + L12_2
  return L11_2
end

GetSquaredDistance = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = MrxGui
  L2_2 = L2_2.GetWidgetByNameAndOwner
  L3_2 = "MessageBox"
  L4_2 = A0_2
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    L4_2 = L2_2
    L3_2 = L2_2.AddMessage
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
  end
end

PlayerAddMessage = L0_1
