local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1
L0_1 = inherit
L1_1 = "MrxTutorial"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = "Disguise tutorial."
L1_1 = -2
L2_1 = false
L3_1 = false
L4_1 = 0

function L5_1()
  local L0_2, L1_2
  L0_2 = L0_1
  return L0_2
end

GetMessage = L5_1
L5_1 = nil

function L6_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2 = L1_2()
  L2_2 = Player
  L2_2 = L2_2.VehicleDisguise
  L3_2 = {}
  L3_2.Player = L1_2
  L4_2 = DisguiseChangedCallback
  L3_2.Callback = L4_2
  L2_2(L3_2)
  L5_1 = A0_2
  L2_2 = L5_1
  L2_2._bDoOnce = nil
end

SetupActivationCriteria = L6_1
L6_1 = {}

function L7_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L3_2 = Player
  L3_2 = L3_2.GetVehicleDisguise
  L3_2 = L3_2()
  if not L3_2 then
    return
  end
  L3_2 = Player
  L3_2 = L3_2.GetLocalCharacter
  L3_2 = L3_2()
  L4_2 = Vehicle
  L4_2 = L4_2.GetFromRider
  L5_2 = L3_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    return
  end
  L5_2 = MrxFactionManager
  L5_2 = L5_2.GetInlineIcon
  L6_2 = MrxFactionManager
  L6_2 = L6_2.GetFactionStringAbbrev
  L7_2 = L4_2
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2 = L6_2(L7_2)
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L6_2 = Player
  L6_2 = L6_2.GetVehicleDisguiseState
  L7_2 = {}
  L7_2.Player = L3_2
  L6_2 = L6_2(L7_2)
  L7_2 = false
  L8_2 = tostring
  L9_2 = L6_2
  L8_2 = L8_2(L9_2)
  if L8_2 == "true" then
    L8_2 = "[Tutorial.VehicleDisguise.Key1:"
    L9_2 = L5_2
    L10_2 = "]"
    L8_2 = L8_2 .. L9_2 .. L10_2
    L0_1 = L8_2
    L8_2 = 1
    L1_1 = L8_2
    L7_2 = true
  else
    L8_2 = tostring
    L9_2 = L6_2
    L8_2 = L8_2(L9_2)
    if L8_2 == "false" then
      L8_2 = "[Tutorial.VehicleDisguise.Key2:"
      L9_2 = L5_2
      L10_2 = "]"
      L8_2 = L8_2 .. L9_2 .. L10_2
      L0_1 = L8_2
      L8_2 = 0
      L1_1 = L8_2
      L7_2 = true
    end
  end
  if not L7_2 then
    return
  end
  L8_2 = L5_1
  L8_2 = L8_2._bDoOnce
  if not L8_2 then
    L8_2 = L5_1
    L9_2 = L8_2
    L8_2 = L8_2.ActivateTutorial
    L10_2 = true
    L8_2 = L8_2(L9_2, L10_2)
    if L8_2 then
      L9_2 = L5_1
      L9_2._bDoOnce = true
      L9_2 = L1_1
      if L9_2 == 1 then
        L9_2 = true
        bDisplayedMsgOne = L9_2
      else
        L9_2 = true
        bDisplayedMsgTwo = L9_2
      end
    end
  else
    L8_2 = MrxTutorialManager
    L8_2 = L8_2.UpdateCurrentTutorial
    L9_2 = L5_1
    L10_2 = true
    L8_2 = L8_2(L9_2, L10_2)
    L9_2 = L1_1
    if L9_2 == 1 then
      L9_2 = true
      bDisplayedMsgOne = L9_2
    else
      L9_2 = true
      bDisplayedMsgTwo = L9_2
      L9_2 = L4_1
      L9_2 = L9_2 + 1
      L4_1 = L9_2
    end
  end
  L8_2 = bDisplayedMsgOne
  if L8_2 == true then
    L8_2 = bDisplayedMsgTwo
    if L8_2 == true then
      L8_2 = L4_1
      if 3 <= L8_2 then
        L8_2 = Event
        L8_2 = L8_2.Create
        L9_2 = Event
        L9_2 = L9_2.TimerRelative
        L10_2 = {}
        L11_2 = 6
        L10_2[1] = L11_2
        L11_2 = EndTutorial
        L12_2 = {}
        L13_2 = L5_1
        L14_2 = true
        L12_2[1] = L13_2
        L12_2[2] = L14_2
        L8_2(L9_2, L10_2, L11_2, L12_2)
    end
  end
  else
    L8_2 = _oHideMessageEvent
    if L8_2 then
      L8_2 = Event
      L8_2 = L8_2.Delete
      L9_2 = _oHideMessageEvent
      L8_2(L9_2)
    end
    L8_2 = Event
    L8_2 = L8_2.Create
    L9_2 = Event
    L9_2 = L9_2.TimerRelative
    L10_2 = {}
    L11_2 = 10
    L10_2[1] = L11_2
    L11_2 = HideDisguiseMessage
    L12_2 = {}
    L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
    _oHideMessageEvent = L8_2
  end
end

DisguiseChangedCallback = L7_1

function L7_1()
  local L0_2, L1_2, L2_2
  L0_2 = MrxTutorialManager
  L0_2 = L0_2.HideMessage
  L1_2 = false
  L2_2 = "VehicleDisguise"
  L0_2(L1_2, L2_2)
end

HideDisguiseMessage = L7_1

function L7_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2 = L1_2()
  L2_2 = Vehicle
  L2_2 = L2_2.GetFromRider
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.ObjectInSeat
  L6_2 = {}
  L7_2 = L1_2
  L8_2 = L2_2
  L9_2 = "A"
  L10_2 = "X"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L7_2 = A0_2.EndTutorial
  L8_2 = {}
  L9_2 = A0_2
  L10_2 = false
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  A0_2._oCancelEvent = L3_2
end

SetupCancellationCriteria = L7_1

function L7_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = Player
  L2_2 = L2_2.GetLocalCharacter
  L2_2 = L2_2()
  L3_2 = -1
  L1_1 = L3_2
  if A1_2 == true then
    L3_2 = Player
    L3_2 = L3_2.VehicleDisguise
    L4_2 = {}
    L4_2.Player = L2_2
    L4_2.Remove = true
    L3_2(L4_2)
  end
  L3_2 = MrxTutorial
  L3_2 = L3_2.EndTutorial
  L4_2 = A0_2
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
end

EndTutorial = L7_1

function L7_1(A0_2)
  local L1_2
end

SetupCompletionCriteria = L7_1
