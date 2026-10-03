local L0_1, L1_1
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiInterface"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  if not A1_2 then
    L2_2 = {}
    A1_2 = L2_2
  end
  L2_2 = setmetatable
  L3_2 = A1_2
  L4_2 = {}
  L4_2.__index = A0_2
  L2_2(L3_2, L4_2)
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = A1_2.nStartTime
  L4_2 = 30
  L2_2 = L2_2(L3_2, L4_2)
  A1_2.nStartTime = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = A1_2.nStopTime
  L4_2 = 0
  L2_2 = L2_2(L3_2, L4_2)
  A1_2.nStopTime = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = A1_2.nStep
  L4_2 = 1
  L2_2 = L2_2(L3_2, L4_2)
  A1_2.nStep = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = A1_2.bUseTenths
  L4_2 = false
  L2_2 = L2_2(L3_2, L4_2)
  A1_2.bUseTenths = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = A1_2.nWarning
  L4_2 = 5
  L2_2 = L2_2(L3_2, L4_2)
  A1_2.nWarning = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = A1_2.iTray
  L4_2 = 1
  L2_2 = L2_2(L3_2, L4_2)
  A1_2.iTray = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.SetDefault
  L3_2 = A1_2.bPlaySounds
  L4_2 = true
  L2_2 = L2_2(L3_2, L4_2)
  A1_2.bPlaySounds = L2_2
  return A1_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = A0_2.nStartTime
  A0_2._iCurrentTime = L1_2
  L1_2 = A0_2.nStartTime
  L2_2 = A0_2.nStopTime
  if L1_2 > L2_2 then
    A0_2._bCountdown = true
  end
  L1_2 = A0_2.Display
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.CreatePersistent
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = A0_2.nStep
  L3_2[1] = L4_2
  L4_2 = A0_2._Update
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  A0_2._TimerEvent = L1_2
  L1_2 = A0_2.bPlaySounds
  if L1_2 then
    L1_2 = Sound
    L1_2 = L1_2.CueSound
    L2_2 = 0
    L3_2 = "ui_HUD_Timer_Start"
    L1_2(L2_2, L3_2)
  end
end

Start = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = Junk
  L2_2 = L2_2.FormatTime
  L3_2 = A0_2._iCurrentTime
  L4_2 = A0_2.bUseTenths
  L2_2 = L2_2(L3_2, L4_2)
  L1_2 = L2_2
  L2_2 = A0_2._bCountdown
  if L2_2 then
    L2_2 = A0_2._iCurrentTime
    L3_2 = A0_2.nWarning
    if L2_2 <= L3_2 then
      L2_2 = "[red]"
      L3_2 = L1_2
      L1_2 = L2_2 .. L3_2
    end
  else
    L2_2 = A0_2._iCurrentTime
    L3_2 = A0_2.nWarning
    if L2_2 >= L3_2 then
      L2_2 = "[red]"
      L3_2 = L1_2
      L1_2 = L2_2 .. L3_2
    end
  end
  L2_2 = A0_2.sLabel
  if L2_2 then
    L2_2 = A0_2.sLabel
    L3_2 = " "
    L4_2 = L1_2
    L1_2 = L2_2 .. L3_2 .. L4_2
  end
  L2_2 = nil
  L3_2 = A0_2._iCurrentTime
  L4_2 = math
  L4_2 = L4_2.floor
  L5_2 = A0_2._iCurrentTime
  L4_2 = L4_2(L5_2)
  L3_2 = L3_2 - L4_2
  if 0.1 <= L3_2 then
    L2_2 = true
  end
  L3_2 = Hud
  L3_2 = L3_2.ObjectiveTray
  L4_2 = L3_2
  L3_2 = L3_2.SetSlotToText
  L5_2 = {}
  L6_2 = A0_2.iTray
  L5_2.nSlot = L6_2
  L5_2.sText = L1_2
  L5_2.bDontNetSync = L2_2
  L3_2(L4_2, L5_2)
end

Display = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2._TimerEvent
  L1_2(L2_2)
end

Pause = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Event
  L1_2 = L1_2.CreatePersistent
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = A0_2.nStep
  L3_2[1] = L4_2
  L4_2 = A0_2._Update
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  A0_2._TimerEvent = L1_2
end

Resume = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  if A1_2 then
    L2_2 = A0_2._iCurrentTime
    L2_2 = L2_2 + A1_2
    A0_2._iCurrentTime = L2_2
  end
  L2_2 = A0_2.Display
  L3_2 = A0_2
  L2_2(L3_2)
end

AddTime = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.SetSlotToText
  L3_2 = {}
  L4_2 = A0_2.iTray
  L3_2.nSlot = L4_2
  L3_2.sText = " "
  L1_2(L2_2, L3_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2._TimerEvent
  L1_2(L2_2)
  A0_2 = nil
end

Stop = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = A0_2._iCurrentTime
  L2_2 = 60
  L3_2 = nil
  L4_2 = nil
  L5_2 = math
  L5_2 = L5_2.abs
  L6_2 = A0_2.nStopTime
  L7_2 = A0_2._iCurrentTime
  L6_2 = L6_2 - L7_2
  L5_2 = L5_2(L6_2)
  if L5_2 < 10 then
    L2_2 = 1
  elseif L5_2 < 60 then
    L2_2 = 10
  end
  L6_2 = A0_2._bCountdown
  if L6_2 then
    L6_2 = math
    L6_2 = L6_2.floor
    L7_2 = A0_2._iCurrentTime
    L7_2 = L7_2 / L2_2
    L6_2 = L6_2(L7_2)
    L3_2 = L6_2
    L6_2 = A0_2._iCurrentTime
    L7_2 = A0_2.nStep
    L6_2 = L6_2 - L7_2
    A0_2._iCurrentTime = L6_2
    L6_2 = math
    L6_2 = L6_2.floor
    L7_2 = A0_2._iCurrentTime
    L7_2 = L7_2 / L2_2
    L6_2 = L6_2(L7_2)
    L4_2 = L6_2
    L6_2 = A0_2._iCurrentTime
    L7_2 = A0_2.nStopTime
    if L6_2 < L7_2 then
      L6_2 = A0_2.nStopTime
      A0_2._iCurrentTime = L6_2
    end
  else
    L6_2 = math
    L6_2 = L6_2.ceil
    L7_2 = A0_2._iCurrentTime
    L7_2 = L7_2 / L2_2
    L6_2 = L6_2(L7_2)
    L3_2 = L6_2
    L6_2 = A0_2._iCurrentTime
    L7_2 = A0_2.nStep
    L6_2 = L6_2 + L7_2
    A0_2._iCurrentTime = L6_2
    L6_2 = math
    L6_2 = L6_2.ceil
    L7_2 = A0_2._iCurrentTime
    L7_2 = L7_2 / L2_2
    L6_2 = L6_2(L7_2)
    L4_2 = L6_2
    L6_2 = A0_2._iCurrentTime
    L7_2 = A0_2.nStopTime
    if L6_2 > L7_2 then
      L6_2 = A0_2.nStopTime
      A0_2._iCurrentTime = L6_2
    end
  end
  if L3_2 ~= L4_2 then
    L6_2 = A0_2.bPlaySounds
    if L6_2 then
      L6_2 = Sound
      L6_2 = L6_2.CueSound
      L7_2 = 0
      L8_2 = "ui_HUD_Timer_Increment"
      L6_2(L7_2, L8_2)
    end
  end
  L6_2 = A0_2._bCountdown
  if L6_2 then
    L6_2 = A0_2.nWarning
    if L1_2 > L6_2 then
      L6_2 = A0_2._iCurrentTime
      L7_2 = A0_2.nWarning
      if L6_2 <= L7_2 then
        L6_2 = A0_2.bPlaySounds
        if L6_2 then
          L6_2 = Sound
          L6_2 = L6_2.CueSound
          L7_2 = 0
          L8_2 = "ui_HUD_Timer_Alert"
          L6_2(L7_2, L8_2)
        end
        L6_2 = _CallCallbacks
        L7_2 = A0_2.tWarnCallbacks
        L6_2(L7_2)
      end
    end
  else
    L6_2 = A0_2.nWarning
    if L1_2 < L6_2 then
      L6_2 = A0_2._iCurrentTime
      L7_2 = A0_2.nWarning
      if L6_2 >= L7_2 then
        L6_2 = A0_2.bPlaySounds
        if L6_2 then
          L6_2 = Sound
          L6_2 = L6_2.CueSound
          L7_2 = 0
          L8_2 = "ui_HUD_Timer_Alert"
          L6_2(L7_2, L8_2)
        end
        L6_2 = _CallCallbacks
        L7_2 = A0_2.tWarnCallbacks
        L6_2(L7_2)
      end
    end
  end
  L6_2 = A0_2.Display
  L7_2 = A0_2
  L6_2(L7_2)
  L6_2 = A0_2._iCurrentTime
  L7_2 = A0_2.nStopTime
  if L6_2 == L7_2 then
    L6_2 = _CallCallbacks
    L7_2 = A0_2.tDoneCallbacks
    L6_2(L7_2)
    L6_2 = A0_2.Stop
    L7_2 = A0_2
    L6_2(L7_2)
    L6_2 = A0_2.bPlaySounds
    if L6_2 then
      L6_2 = Sound
      L6_2 = L6_2.CueSound
      L7_2 = 0
      L8_2 = "ui_HUD_Timer_End"
      L6_2(L7_2, L8_2)
    end
  end
end

_Update = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2._iCurrentTime
  return L1_2
end

GetTime = L0_1

function L0_1(A0_2, A1_2)
  if A1_2 then
    A0_2._iCurrentTime = A1_2
  end
end

SetTime = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  if A0_2 then
    L1_2 = ipairs
    L2_2 = A0_2
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    for L4_2, L5_2 in L1_2, L2_2, L3_2 do
      L6_2 = MrxUtil
      L6_2 = L6_2.CallWithOptionalArgs
      L7_2 = L5_2[1]
      L8_2 = L5_2[2]
      L6_2(L7_2, L8_2)
    end
  end
end

_CallCallbacks = L0_1
