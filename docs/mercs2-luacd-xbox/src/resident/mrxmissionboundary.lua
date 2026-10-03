local L0_1, L1_1
L0_1 = import
L1_1 = "MrxTimer"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  if A1_2 == nil then
    return
  end
  L2_2 = {}
  L3_2 = setmetatable
  L4_2 = L2_2
  L5_2 = A0_2
  L3_2(L4_2, L5_2)
  A0_2.__index = A0_2
  L2_2._tConfig = A1_2
  L3_2 = {}
  L2_2.tEvents = L3_2
  L3_2 = nil
  L4_2 = type
  L5_2 = A1_2.sRegionName
  L4_2 = L4_2(L5_2)
  if L4_2 == "string" then
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = A1_2.sRegionName
    L4_2 = L4_2(L5_2)
    L3_2 = L4_2
  else
    L3_2 = A1_2.sRegionName
  end
  if L3_2 then
    L2_2.uRgn = L3_2
    L4_2 = L2_2.tEvents
    L5_2 = Event
    L5_2 = L5_2.Create
    L6_2 = Event
    L6_2 = L6_2.Boundary
    L7_2 = {}
    L8_2 = Player
    L8_2 = L8_2.GetAnyCharacter
    L8_2 = L8_2()
    L9_2 = L2_2.uRgn
    L10_2 = "exit"
    L11_2 = false
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L7_2[4] = L11_2
    L8_2 = _OutsideBoundary
    L9_2 = {}
    L10_2 = L2_2
    L9_2[1] = L10_2
    L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
    L4_2.eOutside = L5_2
  else
    L4_2 = type
    L5_2 = A1_2.sPoint
    L4_2 = L4_2(L5_2)
    if L4_2 == "string" then
      L4_2 = Pg
      L4_2 = L4_2.GetGuidByName
      L5_2 = A1_2.sPoint
      L4_2 = L4_2(L5_2)
      L2_2.uPoint = L4_2
    else
      L4_2 = A1_2.sPoint
      L2_2.uPoint = L4_2
    end
    L4_2 = A1_2.fRadius
    L2_2.fRadius = L4_2
    L4_2 = L2_2.tEvents
    L5_2 = Event
    L5_2 = L5_2.Create
    L6_2 = Event
    L6_2 = L6_2.ObjectProximity
    L7_2 = {}
    L8_2 = Player
    L8_2 = L8_2.GetAnyCharacter
    L8_2 = L8_2()
    L9_2 = L2_2.uPoint
    L10_2 = ">"
    L11_2 = L2_2.fRadius
    L12_2 = false
    L13_2 = true
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L7_2[4] = L11_2
    L7_2[5] = L12_2
    L7_2[6] = L13_2
    L8_2 = _OutsideRange
    L9_2 = {}
    L10_2 = L2_2
    L9_2[1] = L10_2
    L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
    L4_2.eOutside = L5_2
  end
  L4_2 = A1_2.fCallback
  L2_2.fCallback = L4_2
  L4_2 = A1_2.tCallbackData
  L2_2.tCallbackData = L4_2
  L4_2 = MrxUtil
  L4_2 = L4_2.SetDefault
  L5_2 = A1_2.fWarnTime
  L6_2 = 15
  L4_2 = L4_2(L5_2, L6_2)
  L2_2.fWarnTime = L4_2
  L4_2 = MrxUtil
  L4_2 = L4_2.SetDefault
  L5_2 = A1_2.fFailTime
  L6_2 = 30
  L4_2 = L4_2(L5_2, L6_2)
  L2_2.fFailTime = L4_2
  L4_2 = MrxUtil
  L4_2 = L4_2.SetDefault
  L5_2 = A1_2.iTray
  L6_2 = 3
  L4_2 = L4_2(L5_2, L6_2)
  L2_2.iTray = L4_2
  return L2_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = pairs
  L2_2 = A0_2.tEvents
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Event
    L6_2 = L6_2.Delete
    L7_2 = L5_2
    L6_2(L7_2)
    L6_2 = A0_2.tEvents
    L6_2[L4_2] = nil
  end
  L1_2 = A0_2.oTimer
  if L1_2 then
    L1_2 = A0_2.oTimer
    L2_2 = L1_2
    L1_2 = L1_2.Stop
    L1_2(L2_2)
    A0_2.oTimer = nil
  end
end

Cancel = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.uRgn
  return L1_2
end

GetRegion = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = Player
  L2_2 = L2_2.GetPrimaryCharacter
  L2_2 = L2_2()
  L3_2 = Player
  L3_2 = L3_2.GetSecondaryCharacter
  L3_2 = L3_2()
  if L3_2 == A1_2 and L2_2 then
    L4_2 = Object
    L4_2 = L4_2.GetDistanceFrom
    L5_2 = L2_2
    L6_2 = A1_2
    L4_2 = L4_2(L5_2, L6_2)
    L5_2 = Pg
    L5_2 = L5_2.GetTetherDiameterStart
    L5_2 = L5_2()
    if L4_2 > L5_2 then
      L4_2 = A0_2.tEvents
      L5_2 = Event
      L5_2 = L5_2.Create
      L6_2 = Event
      L6_2 = L6_2.Boundary
      L7_2 = {}
      L8_2 = Player
      L8_2 = L8_2.GetAnyCharacter
      L8_2 = L8_2()
      L9_2 = A0_2.uRgn
      L10_2 = "exit"
      L11_2 = false
      L7_2[1] = L8_2
      L7_2[2] = L9_2
      L7_2[3] = L10_2
      L7_2[4] = L11_2
      L8_2 = _OutsideBoundary
      L9_2 = {}
      L10_2 = A0_2
      L9_2[1] = L10_2
      L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
      L4_2.eOutside = L5_2
      return
    end
  end
  L5_2 = A0_2
  L4_2 = A0_2._CallCallback
  L6_2 = "exit"
  L4_2(L5_2, L6_2)
  L4_2 = A0_2.tEvents
  L5_2 = Event
  L5_2 = L5_2.Create
  L6_2 = Event
  L6_2 = L6_2.Boundary
  L7_2 = {}
  L8_2 = A1_2
  L9_2 = A0_2.uRgn
  L10_2 = "enter"
  L11_2 = false
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L8_2 = _InsideBoundary
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L4_2.eReturn = L5_2
  L4_2 = A0_2._tConfig
  L4_2 = L4_2.tExitVOs
  if L4_2 then
    L4_2 = MrxUtil
    L4_2 = L4_2.GetRandomTableElement
    L5_2 = A0_2._tConfig
    L5_2 = L5_2.tExitVOs
    L4_2 = L4_2(L5_2)
    L5_2 = MrxVoSequence
    L5_2 = L5_2.Start
    L6_2 = {}
    L7_2 = L4_2
    L8_2 = {}
    L9_2 = _StartTimer
    L10_2 = {}
    L11_2 = A0_2
    L10_2[1] = L11_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L5_2(L6_2)
  else
    L5_2 = A0_2
    L4_2 = A0_2._StartTimer
    L4_2(L5_2)
  end
end

_OutsideBoundary = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L2_2 = Player
  L2_2 = L2_2.GetAllPlayers
  L2_2 = L2_2()
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = Player
    L8_2 = L8_2.GetCharacter
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    if L8_2 and L8_2 ~= A1_2 then
      L9_2 = Object
      L9_2 = L9_2.InsideBoundary
      L10_2 = L8_2
      L11_2 = A0_2.uRgn
      L9_2 = L9_2(L10_2, L11_2)
      if not L9_2 then
        L9_2 = A0_2.tEvents
        L10_2 = Event
        L10_2 = L10_2.Create
        L11_2 = Event
        L11_2 = L11_2.Boundary
        L12_2 = {}
        L13_2 = L8_2
        L14_2 = A0_2.uRgn
        L15_2 = "enter"
        L16_2 = false
        L12_2[1] = L13_2
        L12_2[2] = L14_2
        L12_2[3] = L15_2
        L12_2[4] = L16_2
        L13_2 = _InsideBoundary
        L14_2 = {}
        L15_2 = A0_2
        L14_2[1] = L15_2
        L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2)
        L9_2.eReturn = L10_2
        return
      end
    end
  end
  L3_2 = A0_2.oTimer
  if L3_2 then
    L3_2 = A0_2.oTimer
    L4_2 = L3_2
    L3_2 = L3_2.Stop
    L3_2(L4_2)
    A0_2.oTimer = nil
  end
  L3_2 = A0_2.tEvents
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.Boundary
  L6_2 = {}
  L7_2 = Player
  L7_2 = L7_2.GetAnyCharacter
  L7_2 = L7_2()
  L8_2 = A0_2.uRgn
  L9_2 = "exit"
  L10_2 = false
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L7_2 = _OutsideBoundary
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L3_2.eOutside = L4_2
  L4_2 = A0_2
  L3_2 = A0_2._CallCallback
  L5_2 = "return"
  L3_2(L4_2, L5_2)
end

_InsideBoundary = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = Player
  L2_2 = L2_2.GetPrimaryCharacter
  L2_2 = L2_2()
  L3_2 = Player
  L3_2 = L3_2.GetSecondaryCharacter
  L3_2 = L3_2()
  if L3_2 == A1_2 and L2_2 then
    L4_2 = Object
    L4_2 = L4_2.GetDistanceFrom
    L5_2 = L2_2
    L6_2 = A1_2
    L4_2 = L4_2(L5_2, L6_2)
    L5_2 = Pg
    L5_2 = L5_2.GetTetherDiameterStart
    L5_2 = L5_2()
    if L4_2 > L5_2 then
      L4_2 = A0_2.tEvents
      L5_2 = Event
      L5_2 = L5_2.Create
      L6_2 = Event
      L6_2 = L6_2.ObjectProximity
      L7_2 = {}
      L8_2 = Player
      L8_2 = L8_2.GetAnyCharacter
      L8_2 = L8_2()
      L9_2 = A0_2.uPoint
      L10_2 = ">"
      L11_2 = A0_2.fRadius
      L12_2 = false
      L13_2 = true
      L7_2[1] = L8_2
      L7_2[2] = L9_2
      L7_2[3] = L10_2
      L7_2[4] = L11_2
      L7_2[5] = L12_2
      L7_2[6] = L13_2
      L8_2 = _OutsideRange
      L9_2 = {}
      L10_2 = A0_2
      L9_2[1] = L10_2
      L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
      L4_2.eOutside = L5_2
      return
    end
  end
  L5_2 = A0_2
  L4_2 = A0_2._CallCallback
  L6_2 = "exit"
  L4_2(L5_2, L6_2)
  L4_2 = A0_2.tEvents
  L5_2 = Event
  L5_2 = L5_2.Create
  L6_2 = Event
  L6_2 = L6_2.ObjectProximity
  L7_2 = {}
  L8_2 = A1_2
  L9_2 = A0_2.uPoint
  L10_2 = "<="
  L11_2 = A0_2.fRadius
  L11_2 = L11_2 - 10
  L12_2 = false
  L13_2 = true
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L7_2[5] = L12_2
  L7_2[6] = L13_2
  L8_2 = _InsideRange
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L4_2.eReturn = L5_2
  L4_2 = A0_2._tConfig
  L4_2 = L4_2.tExitVOs
  if L4_2 then
    L4_2 = MrxUtil
    L4_2 = L4_2.GetRandomTableElement
    L5_2 = A0_2._tConfig
    L5_2 = L5_2.tExitVOs
    L4_2 = L4_2(L5_2)
    L5_2 = MrxVoSequence
    L5_2 = L5_2.Start
    L6_2 = {}
    L7_2 = L4_2
    L8_2 = {}
    L9_2 = _StartTimer
    L10_2 = {}
    L11_2 = A0_2
    L10_2[1] = L11_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L5_2(L6_2)
  else
    L5_2 = A0_2
    L4_2 = A0_2._StartTimer
    L4_2(L5_2)
  end
end

_OutsideRange = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L2_2 = Player
  L2_2 = L2_2.GetAllPlayers
  L2_2 = L2_2()
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = Player
    L8_2 = L8_2.GetCharacter
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    if L8_2 and L8_2 ~= A1_2 then
      L9_2 = Object
      L9_2 = L9_2.GetDistanceFrom
      L10_2 = L8_2
      L11_2 = A0_2.uPoint
      L12_2 = true
      L9_2 = L9_2(L10_2, L11_2, L12_2)
      L10_2 = A0_2.fRadius
      if L9_2 > L10_2 then
        L9_2 = A0_2.tEvents
        L10_2 = Event
        L10_2 = L10_2.Create
        L11_2 = Event
        L11_2 = L11_2.ObjectProximity
        L12_2 = {}
        L13_2 = A1_2
        L14_2 = A0_2.uPoint
        L15_2 = "<="
        L16_2 = A0_2.fRadius
        L16_2 = L16_2 - 10
        L17_2 = false
        L18_2 = true
        L12_2[1] = L13_2
        L12_2[2] = L14_2
        L12_2[3] = L15_2
        L12_2[4] = L16_2
        L12_2[5] = L17_2
        L12_2[6] = L18_2
        L13_2 = _InsideRange
        L14_2 = {}
        L15_2 = A0_2
        L14_2[1] = L15_2
        L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2)
        L9_2.eReturn = L10_2
        return
      end
    end
  end
  L3_2 = A0_2.oTimer
  if L3_2 then
    L3_2 = A0_2.oTimer
    L4_2 = L3_2
    L3_2 = L3_2.Stop
    L3_2(L4_2)
    A0_2.oTimer = nil
  end
  L3_2 = A0_2.tEvents
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.ObjectProximity
  L6_2 = {}
  L7_2 = Player
  L7_2 = L7_2.GetAnyCharacter
  L7_2 = L7_2()
  L8_2 = A0_2.uPoint
  L9_2 = ">"
  L10_2 = A0_2.fRadius
  L11_2 = false
  L12_2 = true
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L6_2[5] = L11_2
  L6_2[6] = L12_2
  L7_2 = _OutsideRange
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L3_2.eOutside = L4_2
  L3_2 = A0_2._tConfig
  L3_2 = L3_2.tReturnVOs
  if L3_2 then
    L3_2 = MrxUtil
    L3_2 = L3_2.GetRandomTableElement
    L4_2 = A0_2._tConfig
    L4_2 = L4_2.tReturnVOs
    L3_2 = L3_2(L4_2)
    L4_2 = MrxVoSequence
    L4_2 = L4_2.Start
    L5_2 = {}
    L6_2 = L3_2
    L5_2[1] = L6_2
    L4_2(L5_2)
  end
  L4_2 = A0_2
  L3_2 = A0_2._CallCallback
  L5_2 = "return"
  L3_2(L4_2, L5_2)
end

_InsideRange = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Player
  L1_2 = L1_2.GetAllPlayers
  L1_2 = L1_2()
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = Object
    L7_2 = L7_2.GetDistanceFrom
    L8_2 = Player
    L8_2 = L8_2.GetCharacter
    L9_2 = L6_2
    L8_2 = L8_2(L9_2)
    L9_2 = A0_2.uPoint
    L7_2 = L7_2(L8_2, L9_2)
    L8_2 = A0_2.fRadius
    L8_2 = L8_2 - 10
    if L7_2 < L8_2 then
      return
    end
  end
  L2_2 = MrxTimer
  L3_2 = L2_2
  L2_2 = L2_2.Create
  L4_2 = {}
  L5_2 = A0_2.fFailTime
  L4_2.nStartTime = L5_2
  L5_2 = A0_2.fWarnTime
  L4_2.nWarning = L5_2
  L5_2 = A0_2.iTray
  L4_2.iTray = L5_2
  L5_2 = A0_2._tConfig
  L5_2 = L5_2.sLabel
  L4_2.sLabel = L5_2
  L5_2 = {}
  L6_2 = {}
  L7_2 = _FailTimeExpired
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tDoneCallbacks = L5_2
  L5_2 = {}
  L6_2 = {}
  L7_2 = _WarnTimeExpired
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tWarnCallbacks = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  A0_2.oTimer = L2_2
  L2_2 = A0_2.oTimer
  L3_2 = L2_2
  L2_2 = L2_2.Start
  L2_2(L3_2)
end

_StartTimer = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = A0_2._tConfig
  L1_2 = L1_2.tWarnVOs
  if L1_2 then
    L1_2 = MrxUtil
    L1_2 = L1_2.GetRandomTableElement
    L2_2 = A0_2._tConfig
    L2_2 = L2_2.tWarnVOs
    L1_2 = L1_2(L2_2)
    L2_2 = MrxVoSequence
    L2_2 = L2_2.Start
    L3_2 = {}
    L4_2 = L1_2
    L3_2[1] = L4_2
    L2_2(L3_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2._CallCallback
  L3_2 = "warning"
  L1_2(L2_2, L3_2)
end

_WarnTimeExpired = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2._CallCallback
  L3_2 = "fail"
  L1_2(L2_2, L3_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.tEvents
  L2_2 = L2_2.eReturn
  L1_2(L2_2)
  L1_2 = A0_2.tEvents
  L1_2.eReturn = nil
  L1_2 = A0_2.oTimer
  L2_2 = L1_2
  L1_2 = L1_2.Stop
  L1_2(L2_2)
  A0_2.oTimer = nil
end

_FailTimeExpired = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2.fCallback
  if not L2_2 then
    return
  end
  L2_2 = A0_2.tCallbackData
  if L2_2 then
    L2_2 = A0_2.fCallback
    L3_2 = A0_2
    L4_2 = A1_2
    L5_2 = unpack
    L6_2 = A0_2.tCallbackData
    L5_2, L6_2 = L5_2(L6_2)
    L2_2(L3_2, L4_2, L5_2, L6_2)
  else
    L2_2 = A0_2.fCallback
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  end
end

_CallCallback = L0_1
