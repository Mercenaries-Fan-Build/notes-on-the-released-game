local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = "ui_HUD_Money_Gain"
_kTickUpSound = L0_1
L0_1 = "ui_HUD_Money_Lose"
_kTickDownSound = L0_1
L0_1 = 0.5
_kDefaultTickTime = L0_1
L0_1 = 2.05
_kTickLong = L0_1
L0_1 = 1.25
_kTickMedium = L0_1
L0_1 = 0.5
_kTickShort = L0_1
L0_1 = 0.2
_kPulseTime = L0_1
L0_1 = 0.1
_kWindowTime = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.nCurrentValue
  return L1_2
end

GetCounterValue = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L4_2 = type
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  if "number" ~= L4_2 then
    L4_2 = false
    return L4_2
  end
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nCurrentValue
  if A1_2 == L4_2 and (not A3_2 or 0 == A3_2) then
    L4_2 = false
    return L4_2
  end
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.bSuppressed
  if L4_2 then
    L4_2 = A0_2.CustomData
    L4_2.nDisplayValue = A1_2
    L4_2 = A0_2.CustomData
    L4_2.nCurrentValue = A1_2
    L4_2 = A0_2.CustomData
    L4_2.nDeltaValue = 0
    L4_2 = A0_2.CustomData
    L4_2.bActive = false
    L4_2 = A0_2.CustomData
    L4_2.nMagnitude = 0
    L5_2 = A0_2
    L4_2 = A0_2.SetEventHandler
    L6_2 = "GuiUpdate"
    L7_2 = nil
    L4_2(L5_2, L6_2, L7_2)
    L5_2 = A0_2
    L4_2 = A0_2.UpdateText
    L4_2(L5_2)
    L4_2 = false
    return L4_2
  else
    L4_2 = A3_2 or L4_2
    if not A3_2 then
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.nCurrentValue
      L4_2 = A1_2 - L4_2
    end
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.oReasonList
    if L5_2 then
      L5_2 = type
      L6_2 = A2_2
      L5_2 = L5_2(L6_2)
      if "string" == L5_2 then
        L5_2 = A0_2.CustomData
        L5_2 = L5_2.oReasonList
        L6_2 = L5_2
        L5_2 = L5_2.AddReason
        L7_2 = A2_2
        L8_2 = L4_2
        L5_2(L6_2, L7_2, L8_2)
      elseif 0 < L4_2 then
        L5_2 = A0_2.CustomData
        L5_2 = L5_2.oReasonList
        L6_2 = L5_2
        L5_2 = L5_2.AddReason
        L7_2 = "[Generic.MoneyReasons.Credit]"
        L8_2 = L4_2
        L5_2(L6_2, L7_2, L8_2)
      else
        L5_2 = A0_2.CustomData
        L5_2 = L5_2.oReasonList
        L6_2 = L5_2
        L5_2 = L5_2.AddReason
        L7_2 = "[Generic.MoneyReasons.Debit]"
        L8_2 = L4_2
        L5_2(L6_2, L7_2, L8_2)
      end
    end
    if 0 < L4_2 then
      L6_2 = A0_2
      L5_2 = A0_2.PulseRise
      L7_2 = _kPulseTime
      L5_2(L6_2, L7_2)
    elseif L4_2 < 0 then
      L6_2 = A0_2
      L5_2 = A0_2.PulseFall
      L7_2 = _kPulseTime
      L5_2(L6_2, L7_2)
    end
    L5_2 = 0
    L6_2 = nil
    L7_2 = nil
    if 0 < L4_2 then
      if 1000000 < L4_2 then
        L6_2 = "UI_hud_cashUp_large"
        L7_2 = _kTickLong
        L5_2 = 3
      elseif 100000 < L4_2 then
        L6_2 = "UI_hud_cashUp_med"
        L7_2 = _kTickMedium
        L5_2 = 2
      else
        L6_2 = "UI_hud_cashUp_small"
        L7_2 = _kTickShort
        L5_2 = 1
      end
    elseif L4_2 < 0 then
      if L4_2 < -1000000 then
        L6_2 = "UI_hud_cashDown_large"
        L7_2 = _kTickLong
        L5_2 = -3
      elseif L4_2 < -100000 then
        L6_2 = "UI_hud_cashDown_med"
        L7_2 = _kTickMedium
        L5_2 = -2
      else
        L6_2 = "UI_hud_cashDown_small"
        L7_2 = _kTickShort
        L5_2 = -1
      end
    end
    L8_2 = false
    if L6_2 then
      L9_2 = math
      L9_2 = L9_2.abs
      L10_2 = L5_2
      L9_2 = L9_2(L10_2)
      L10_2 = math
      L10_2 = L10_2.abs
      L11_2 = A0_2.CustomData
      L11_2 = L11_2.nMagnitude
      L10_2 = L10_2(L11_2)
      if L9_2 > L10_2 then
        L8_2 = true
      else
        L9_2 = math
        L9_2 = L9_2.abs
        L10_2 = L5_2
        L9_2 = L9_2(L10_2)
        L10_2 = math
        L10_2 = L10_2.abs
        L11_2 = A0_2.CustomData
        L11_2 = L11_2.nMagnitude
        L10_2 = L10_2(L11_2)
        if L9_2 == L10_2 then
          L9_2 = A0_2.CustomData
          L9_2 = L9_2.nMagnitude
          if L5_2 ~= L9_2 then
            L8_2 = true
          end
        end
      end
    end
    if L8_2 then
      L9_2 = Sound
      L9_2 = L9_2.CueSound
      L10_2 = 0
      L11_2 = L6_2
      L9_2(L10_2, L11_2)
      L9_2 = A0_2.CustomData
      L9_2.nMagnitude = L5_2
      L9_2 = A0_2.CustomData
      L9_2.nTickSpeed = L7_2
    end
    L9_2 = A0_2.CustomData
    L10_2 = A0_2.CustomData
    L10_2 = L10_2.nDisplayValue
    L10_2 = A1_2 - L10_2
    L11_2 = A0_2.CustomData
    L11_2 = L11_2.nTickSpeed
    L10_2 = L10_2 / L11_2
    L9_2.nDeltaValue = L10_2
    L9_2 = A0_2.CustomData
    L9_2.nCurrentValue = A1_2
    L9_2 = A0_2.CustomData
    L9_2.bActive = true
    L9_2 = A0_2.CustomData
    L9_2 = L9_2.bPersistWhenLow
    if L9_2 then
      L9_2 = MrxPmc
      L9_2 = L9_2.GetFuelCapacity
      L9_2 = L9_2()
      if not L9_2 then
        L9_2 = 300
      end
      L9_2 = L9_2 * 0.1
      if 0 < L4_2 then
        L10_2 = A0_2.CustomData
        L10_2 = L10_2.nCurrentValue
        if L9_2 < L10_2 then
          L10_2 = A0_2.CustomData
          L10_2.bPersist = false
      end
      elseif L4_2 < 0 then
        L10_2 = A0_2.CustomData
        L10_2 = L10_2.nCurrentValue
        if L9_2 >= L10_2 then
          L10_2 = A0_2.CustomData
          L10_2.bPersist = true
        end
      end
    end
    L10_2 = A0_2
    L9_2 = A0_2.SetEventHandler
    L11_2 = "GuiUpdate"
    L12_2 = _HandleCounterUpdateEvent
    L9_2(L10_2, L11_2, L12_2)
    L9_2 = true
    return L9_2
  end
end

SetCounterValue = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L3_2 = A0_2
  L2_2 = A0_2.SetValue
  L5_2 = A0_2
  L4_2 = A0_2.GetValue
  L4_2 = L4_2(L5_2)
  L4_2 = L4_2 + A1_2
  L2_2(L3_2, L4_2)
end

ModifyCounterValue = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  if nil == A1_2 then
    L2_2 = A0_2.CustomData
    L2_2.sAppend = nil
  else
    L2_2 = type
    L3_2 = A1_2
    L2_2 = L2_2(L3_2)
    if "string" == L2_2 then
      L2_2 = A0_2.CustomData
      L2_2.sAppend = A1_2
    end
  end
  L3_2 = A0_2
  L2_2 = A0_2.UpdateText
  L2_2(L3_2)
end

SetCounterAppendedString = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if "number" == L2_2 then
    L2_2 = A0_2.CustomData
    L2_2.nTickSpeed = A1_2
  end
end

SetCounterTickSpeed = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bActive
  return L1_2
end

IsTicking = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bActive
  if L2_2 then
    L2_2 = A0_2.CustomData
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.nDisplayValue
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.nDeltaValue
    L4_2 = L4_2 * A1_2
    L3_2 = L3_2 + L4_2
    L2_2.nDisplayValue = L3_2
    L2_2 = false
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.nDeltaValue
    if L3_2 < 0 then
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.nDisplayValue
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.nCurrentValue
      if L3_2 <= L4_2 then
        L2_2 = true
      end
    else
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.nDeltaValue
      if 0 < L3_2 then
        L3_2 = A0_2.CustomData
        L3_2 = L3_2.nDisplayValue
        L4_2 = A0_2.CustomData
        L4_2 = L4_2.nCurrentValue
        if L3_2 >= L4_2 then
          L2_2 = true
        end
      else
        L2_2 = true
      end
    end
    if L2_2 then
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.bPersist
      if L3_2 then
        L3_2 = A0_2.CustomData
        L3_2 = L3_2.nDeltaValue
        if 0 < L3_2 then
          L4_2 = A0_2
          L3_2 = A0_2.PulseFall
          L5_2 = _kPulseTime
          L3_2(L4_2, L5_2)
        end
      else
        L4_2 = A0_2
        L3_2 = A0_2.HaltPulse
        L5_2 = _kPulseTime
        L3_2(L4_2, L5_2)
      end
      L3_2 = A0_2.CustomData
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.nCurrentValue
      L3_2.nDisplayValue = L4_2
      L3_2 = A0_2.CustomData
      L3_2.nDeltaValue = 0
      L3_2 = A0_2.CustomData
      L3_2.bActive = false
      L3_2 = A0_2.CustomData
      L3_2.nMagnitude = 0
    end
    L4_2 = A0_2
    L3_2 = A0_2.UpdateText
    L3_2(L4_2)
  end
end

_HandleCounterUpdateEvent = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = A0_2.CustomData
  L1_2.nCurrentValue = 0
  L1_2 = A0_2.CustomData
  L1_2.nDisplayValue = 0
  L1_2 = A0_2.CustomData
  L2_2 = _kDefaultTickTime
  L1_2.nTickSpeed = L2_2
  L1_2 = A0_2.CustomData
  L1_2.nDeltaValue = 1
  L1_2 = A0_2.CustomData
  L1_2.bActive = false
  L1_2 = A0_2.CustomData
  L1_2.sAppend = nil
  L1_2 = A0_2.CustomData
  L1_2.bSuppressed = false
  L1_2 = A0_2.CustomData
  L1_2.nMagnitude = 0
  L1_2 = GetCounterValue
  A0_2.GetValue = L1_2
  L1_2 = SetCounterValue
  A0_2.SetValue = L1_2
  L1_2 = ModifyCounterValue
  A0_2.ModifyValue = L1_2
  L1_2 = SetCounterTickSpeed
  A0_2.SetTickSpeed = L1_2
  L1_2 = SetCounterAppendedString
  A0_2.SetAppendedString = L1_2
  L1_2 = _UpdateText
  A0_2.UpdateText = L1_2
  L1_2 = IsTicking
  A0_2.IsTicking = L1_2
  L1_2 = HaltPulse
  A0_2.HaltPulse = L1_2
  L1_2 = PulseRise
  A0_2.PulseRise = L1_2
  L1_2 = PulseFall
  A0_2.PulseFall = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.UpdateText
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetColor
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  L4_2 = A0_2.CustomData
  L6_2 = A0_2
  L5_2 = A0_2.AddAnimationPoint
  L7_2 = {}
  L7_2.RedLevel = L1_2
  L7_2.GreenLevel = L2_2
  L7_2.BlueLevel = L3_2
  L5_2 = L5_2(L6_2, L7_2)
  L4_2.nBaseColor = L5_2
  L4_2 = A0_2.CustomData
  L6_2 = A0_2
  L5_2 = A0_2.AddAnimationPoint
  L7_2 = {}
  L7_2.RedLevel = 255
  L7_2.GreenLevel = 64
  L7_2.BlueLevel = 64
  L5_2 = L5_2(L6_2, L7_2)
  L4_2.nFallColor = L5_2
  L4_2 = A0_2.CustomData
  L6_2 = A0_2
  L5_2 = A0_2.AddAnimationPoint
  L7_2 = {}
  L7_2.RedLevel = 255
  L7_2.GreenLevel = 255
  L7_2.BlueLevel = 255
  L5_2 = L5_2(L6_2, L7_2)
  L4_2.nRiseColor = L5_2
  L4_2 = A0_2.BasicData
  L4_2 = L4_2.name
  if L4_2 == "Money Counter" then
    L4_2 = A0_2.ParentWidget
    L4_2 = L4_2.ParentWidget
    L5_2 = L4_2
    L4_2 = L4_2.GetChildren
    L4_2 = L4_2(L5_2)
    L4_2 = L4_2[3]
    L5_2 = L4_2.CustomData
    L5_2.bFormatMoney = true
    L5_2 = A0_2.CustomData
    L5_2.oReasonList = L4_2
    L5_2 = A0_2.CustomData
    L5_2.bFormatMoney = true
  else
    L4_2 = A0_2.BasicData
    L4_2 = L4_2.name
    if L4_2 == "Fuel Counter" then
      L4_2 = A0_2.ParentWidget
      L4_2 = L4_2.ParentWidget
      L5_2 = L4_2
      L4_2 = L4_2.GetChildren
      L4_2 = L4_2(L5_2)
      L4_2 = L4_2[4]
      L5_2 = L4_2.CustomData
      L5_2.nBufferSize = 0
      L5_2 = A0_2.CustomData
      L5_2.bPersistWhenLow = true
      L5_2 = A0_2.CustomData
      L5_2.oReasonList = L4_2
    end
  end
  L5_2 = A0_2
  L4_2 = A0_2.UpdateText
  L4_2(L5_2)
end

_CounterInitialization = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _PulseToRiseRise
  L3_2 = A0_2
  L4_2 = A1_2 or L4_2
  if not A1_2 then
    L4_2 = _kPulseTime
  end
  L2_2(L3_2, L4_2)
end

PulseRise = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _PulseToFallFall
  L3_2 = A0_2
  L4_2 = A1_2 or L4_2
  if not A1_2 then
    L4_2 = _kPulseTime
  end
  L2_2(L3_2, L4_2)
end

PulseFall = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L3_2 = A0_2
  L2_2 = A0_2.AnimateToPoint
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nBaseColor
  L5_2 = A1_2 or L5_2
  if not A1_2 then
    L5_2 = _kPulseTime
  end
  L6_2 = true
  L2_2(L3_2, L4_2, L5_2, L6_2)
end

HaltPulse = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = A0_2
  L2_2 = A0_2.AnimateToPoint
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nBaseColor
  L5_2 = A1_2
  L6_2 = true
  L7_2 = _PulseToRiseRise
  L8_2 = {}
  L9_2 = A1_2
  L8_2[1] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
end

_PulseToBaseRise = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = A0_2
  L2_2 = A0_2.AnimateToPoint
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nRiseColor
  L5_2 = A1_2
  L6_2 = true
  L7_2 = _PulseToBaseRise
  L8_2 = {}
  L9_2 = A1_2
  L8_2[1] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
end

_PulseToRiseRise = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = A0_2
  L2_2 = A0_2.AnimateToPoint
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nBaseColor
  L5_2 = A1_2
  L6_2 = true
  L7_2 = _PulseToFallFall
  L8_2 = {}
  L9_2 = A1_2
  L8_2[1] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
end

_PulseToBaseFall = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = A0_2
  L2_2 = A0_2.AnimateToPoint
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nFallColor
  L5_2 = A1_2
  L6_2 = true
  L7_2 = _PulseToBaseFall
  L8_2 = {}
  L9_2 = A1_2
  L8_2[1] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
end

_PulseToFallFall = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L1_2 = A0_2.CustomData
  L1_2.bTicking = false
  L1_2 = A0_2.CustomData
  L1_2.nVisibleTime = 0
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2[1]
  L3_2 = L1_2[2]
  L4_2 = L1_2[3]
  L5_2 = A0_2.CustomData
  L5_2.oBg1 = L2_2
  L5_2 = A0_2.CustomData
  L5_2.oBg2 = L3_2
  L5_2 = A0_2.CustomData
  L5_2.oCounter = L4_2
  L6_2 = L2_2
  L5_2 = L2_2.GetLocation
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  L9_2 = L6_2 + L8_2
  L9_2 = L9_2 * 0.5
  L10_2 = A0_2.CustomData
  L12_2 = L2_2
  L11_2 = L2_2.AddAnimationPoint
  L13_2 = {}
  L13_2.x = L5_2
  L13_2.y = L6_2
  L13_2.x2 = L7_2
  L13_2.y2 = L8_2
  L11_2 = L11_2(L12_2, L13_2)
  L10_2.nOpenPoint1 = L11_2
  L10_2 = A0_2.CustomData
  L12_2 = L2_2
  L11_2 = L2_2.AddAnimationPoint
  L13_2 = {}
  L13_2.x = L5_2
  L13_2.y = L9_2
  L13_2.x2 = L7_2
  L13_2.y2 = L9_2
  L11_2 = L11_2(L12_2, L13_2)
  L10_2.nClosePoint1 = L11_2
  L11_2 = L3_2
  L10_2 = L3_2.GetLocation
  L10_2, L11_2, L12_2, L13_2 = L10_2(L11_2)
  L8_2 = L13_2
  L7_2 = L12_2
  L6_2 = L11_2
  L5_2 = L10_2
  L10_2 = L6_2 + L8_2
  L9_2 = L10_2 * 0.5
  L10_2 = A0_2.CustomData
  L12_2 = L3_2
  L11_2 = L3_2.AddAnimationPoint
  L13_2 = {}
  L13_2.x = L5_2
  L13_2.y = L6_2
  L13_2.x2 = L7_2
  L13_2.y2 = L8_2
  L11_2 = L11_2(L12_2, L13_2)
  L10_2.nOpenPoint2 = L11_2
  L10_2 = A0_2.CustomData
  L12_2 = L3_2
  L11_2 = L3_2.AddAnimationPoint
  L13_2 = {}
  L13_2.x = L5_2
  L13_2.y = L9_2
  L13_2.x2 = L7_2
  L13_2.y2 = L9_2
  L11_2 = L11_2(L12_2, L13_2)
  L10_2.nClosePoint2 = L11_2
  L10_2 = {}
  L12_2 = A0_2
  L11_2 = A0_2.GetLocation
  L11_2, L12_2 = L11_2(L12_2)
  L6_2 = L12_2
  L5_2 = L11_2
  L12_2 = A0_2
  L11_2 = A0_2.AddAnimationPoint
  L13_2 = {}
  L13_2.x = L5_2
  L13_2.y = L6_2
  L11_2 = L11_2(L12_2, L13_2)
  L10_2[0] = L11_2
  L12_2 = A0_2
  L11_2 = A0_2.AddAnimationPoint
  L13_2 = {}
  L14_2 = L5_2 - 1.5
  L13_2.x = L14_2
  L14_2 = L6_2 - 1
  L13_2.y = L14_2
  L11_2 = L11_2(L12_2, L13_2)
  L10_2[1] = L11_2
  L12_2 = A0_2
  L11_2 = A0_2.AddAnimationPoint
  L13_2 = {}
  L14_2 = L5_2 + 2
  L13_2.x = L14_2
  L14_2 = L6_2 - 1.5
  L13_2.y = L14_2
  L11_2 = L11_2(L12_2, L13_2)
  L10_2[2] = L11_2
  L12_2 = A0_2
  L11_2 = A0_2.AddAnimationPoint
  L13_2 = {}
  L14_2 = L5_2 - 1
  L13_2.x = L14_2
  L14_2 = L6_2 + 1
  L13_2.y = L14_2
  L11_2 = L11_2(L12_2, L13_2)
  L10_2[3] = L11_2
  L12_2 = A0_2
  L11_2 = A0_2.AddAnimationPoint
  L13_2 = {}
  L14_2 = L5_2 + 2
  L13_2.x = L14_2
  L14_2 = L6_2 + 2
  L13_2.y = L14_2
  L11_2 = L11_2(L12_2, L13_2)
  L10_2[4] = L11_2
  L11_2 = A0_2.CustomData
  L11_2.nShakePoint = 1
  L11_2 = A0_2.CustomData
  L11_2.tShakePoints = L10_2
  L11_2 = _Show
  A0_2.Show = L11_2
  L11_2 = _Hide
  A0_2.Hide = L11_2
  L11_2 = TopLevelSetValue
  A0_2.SetValue = L11_2
  L11_2 = TopLevelSetAppendedString
  A0_2.SetAppendedString = L11_2
  L11_2 = SetSuppressed
  A0_2.SetSuppressed = L11_2
  L11_2 = A0_2.CustomData
  L11_2.bActive = true
  L12_2 = A0_2
  L11_2 = A0_2.Hide
  L11_2(L12_2)
end

_TopLevelInitialization = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bSuppressed
  if L2_2 then
    return
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bActive
  if not L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.SetVisible
    L4_2 = true
    L2_2(L3_2, L4_2)
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.oCounter
    L3_2 = L2_2
    L2_2 = L2_2.SetVisible
    L4_2 = false
    L2_2(L3_2, L4_2)
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.oBg1
    L3_2 = L2_2
    L2_2 = L2_2.AnimateToPoint
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.nOpenPoint1
    L5_2 = _kWindowTime
    L6_2 = true
    L7_2 = _FinishOpen
    L8_2 = {}
    L9_2 = A0_2
    L8_2[1] = L9_2
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.oBg2
    L3_2 = L2_2
    L2_2 = L2_2.AnimateToPoint
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.nOpenPoint2
    L5_2 = _kWindowTime
    L6_2 = true
    L2_2(L3_2, L4_2, L5_2, L6_2)
  end
  L2_2 = A0_2.CustomData
  L2_2.bActive = true
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nVisibleTime
  if -1 < L2_2 then
    L2_2 = A0_2.CustomData
    L3_2 = A1_2 or L3_2
    if not A1_2 then
      L3_2 = 2
    end
    L2_2.nVisibleTime = L3_2
  end
end

_Show = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L3_2 = A1_2
  L2_2 = A1_2.SetVisible
  L4_2 = true
  L2_2(L3_2, L4_2)
  L3_2 = A1_2
  L2_2 = A1_2.SetEventHandler
  L4_2 = "GuiUpdate"
  L5_2 = _TopLevelUpdate
  L2_2(L3_2, L4_2, L5_2)
end

_FinishOpen = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bActive
  if not L1_2 then
    return
  end
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oCounter
  L1_2 = L1_2.CustomData
  L1_2 = L1_2.bPersist
  if L1_2 then
    return
  end
  L1_2 = A0_2.CustomData
  L1_2.bActive = false
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oCounter
  L2_2 = L1_2
  L1_2 = L1_2.SetVisible
  L3_2 = false
  L1_2(L2_2, L3_2)
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oBg1
  L2_2 = L1_2
  L1_2 = L1_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nClosePoint1
  L4_2 = _kWindowTime
  L5_2 = true
  L6_2 = _FinishClose
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oBg2
  L2_2 = L1_2
  L1_2 = L1_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nClosePoint2
  L4_2 = _kWindowTime
  L5_2 = true
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L2_2 = A0_2
  L1_2 = A0_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.tShakePoints
  L3_2 = L3_2[0]
  L4_2 = 0
  L5_2 = true
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = A0_2.CustomData
  L1_2.nMagnitude = 0
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oCounter
  L1_2 = L1_2.HaltPulse
  if L1_2 then
    L1_2 = A0_2.CustomData
    L1_2 = L1_2.oCounter
    L2_2 = L1_2
    L1_2 = L1_2.HaltPulse
    L3_2 = 0
    L1_2(L2_2, L3_2)
  end
  L1_2 = A0_2.CustomData
  L1_2.nVisibleTime = 0
  L2_2 = A0_2
  L1_2 = A0_2.SetEventHandler
  L3_2 = "GuiUpdate"
  L4_2 = nil
  L1_2(L2_2, L3_2, L4_2)
end

_Hide = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L3_2 = A1_2
  L2_2 = A1_2.SetVisible
  L4_2 = false
  L2_2(L3_2, L4_2)
end

_FinishClose = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  if not A1_2 then
    A1_2 = false
  end
  if A1_2 then
    A1_2 = true
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bSuppressed
  if L2_2 == A1_2 then
    return
  end
  L2_2 = A0_2.CustomData
  L2_2.bSuppressed = A1_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oCounter
  L2_2 = L2_2.CustomData
  L2_2.bSuppressed = A1_2
  if A1_2 then
    L3_2 = A0_2
    L2_2 = A0_2.Hide
    L2_2(L3_2)
  end
end

SetSuppressed = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oCounter
  L5_2 = L4_2
  L4_2 = L4_2.SetValue
  L6_2 = A1_2
  L7_2 = A2_2
  L8_2 = A3_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  if L4_2 then
    L5_2 = A0_2
    L4_2 = A0_2.Show
    L4_2(L5_2)
  end
end

TopLevelSetValue = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oCounter
  L3_2 = L2_2
  L2_2 = L2_2.SetAppendedString
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

TopLevelSetAppendedString = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oCounter
  L3_2 = L2_2
  L2_2 = L2_2.IsTicking
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = A0_2.AnimationData
    L3_2 = L3_2.bAnimating
    if not L3_2 then
      L4_2 = A0_2
      L3_2 = A0_2.AnimateToPoint
      L5_2 = A0_2.CustomData
      L5_2 = L5_2.tShakePoints
      L6_2 = A0_2.CustomData
      L6_2 = L6_2.nShakePoint
      L5_2 = L5_2[L6_2]
      L6_2 = 0.05
      L7_2 = true
      L3_2(L4_2, L5_2, L6_2, L7_2)
      L3_2 = A0_2.CustomData
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.nShakePoint
      L4_2 = L4_2 + 1
      L3_2.nShakePoint = L4_2
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.nShakePoint
      if 4 < L3_2 then
        L3_2 = A0_2.CustomData
        L3_2.nShakePoint = 1
      end
  end
  elseif not L2_2 then
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.bTicking
    if L3_2 then
      L4_2 = A0_2
      L3_2 = A0_2.AnimateToPoint
      L5_2 = A0_2.CustomData
      L5_2 = L5_2.tShakePoints
      L5_2 = L5_2[0]
      L6_2 = 0
      L7_2 = true
      L3_2(L4_2, L5_2, L6_2, L7_2)
    end
  end
  L3_2 = A0_2.CustomData
  L3_2.bTicking = L2_2
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.bTicking
  if not L3_2 then
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.nVisibleTime
    if 0 < L3_2 then
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.bAlwaysShow
      if not L3_2 then
        L3_2 = A0_2.CustomData
        L3_2 = L3_2.oCounter
        L3_2 = L3_2.CustomData
        L3_2 = L3_2.bPersist
        if not L3_2 then
          L3_2 = A0_2.CustomData
          L4_2 = A0_2.CustomData
          L4_2 = L4_2.nVisibleTime
          L4_2 = L4_2 - A1_2
          L3_2.nVisibleTime = L4_2
          L3_2 = A0_2.CustomData
          L3_2 = L3_2.nVisibleTime
          if L3_2 <= 0 then
            L3_2 = A0_2.CustomData
            L3_2.nVisibleTime = 0
            L4_2 = A0_2
            L3_2 = A0_2.Hide
            L3_2(L4_2)
          end
        end
      end
    end
  end
end

_TopLevelUpdate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L3_2 = A0_2
  L2_2 = A0_2.Show
  L4_2 = A1_2.nTime
  if not L4_2 then
    L4_2 = 2
  end
  L2_2(L3_2, L4_2)
end

_HandleShowEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L3_2 = A0_2
  L2_2 = A0_2.GetOwner
  L2_2 = L2_2(L3_2)
  L3_2 = A1_2.uGuid
  if L2_2 ~= L3_2 then
    L2_2 = A1_2.uGuid
    if nil ~= L2_2 then
      goto lbl_12
    end
  end
  L3_2 = A0_2
  L2_2 = A0_2.SetValue
  L4_2 = A1_2.nValue
  L2_2(L3_2, L4_2)
  ::lbl_12::
end

_HandleSetValueEvent = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bFormatMoney
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.SetText
    L3_2 = _ConvertNumber
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.nDisplayValue
    L3_2, L4_2, L5_2 = L3_2(L4_2)
    L1_2(L2_2, L3_2, L4_2, L5_2)
  else
    L2_2 = A0_2
    L1_2 = A0_2.SetText
    L3_2 = string
    L3_2 = L3_2.format
    L4_2 = "%d"
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.nDisplayValue
    L3_2 = L3_2(L4_2, L5_2)
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.sAppend
    if not L4_2 then
      L4_2 = " "
    end
    L3_2 = L3_2 .. L4_2
    L1_2(L2_2, L3_2)
  end
end

_UpdateText = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = A0_2.CustomData
  L1_2.nDisplayTime = 0
  L1_2 = A0_2.CustomData
  L2_2 = {}
  L1_2.tReasons = L2_2
  L1_2 = A0_2.CustomData
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nBufferSize
  if not L2_2 then
    L2_2 = _knBufferSize
  end
  L1_2.nBufferSize = L2_2
  L1_2 = A0_2.CustomData
  L3_2 = A0_2
  L2_2 = A0_2.AddAnimationPoint
  L4_2 = {}
  L4_2.TranslucencyLevel = 255
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.nShowPoint = L2_2
  L1_2 = A0_2.CustomData
  L3_2 = A0_2
  L2_2 = A0_2.AddAnimationPoint
  L4_2 = {}
  L4_2.TranslucencyLevel = 0
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.nHidePoint = L2_2
  L1_2 = AddReason
  A0_2.AddReason = L1_2
  L1_2 = _FadeReasons
  A0_2.Hide = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nHidePoint
  L4_2 = 0
  L5_2 = true
  L6_2 = _ClearReasons
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

InitReasonList = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = table
  L3_2 = L3_2.insert
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.tReasons
  L5_2 = {}
  L6_2 = A2_2
  L7_2 = A1_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L3_2(L4_2, L5_2)
  L3_2 = _UpdateReasonDisplay
  L4_2 = A0_2
  L3_2(L4_2)
  L4_2 = A0_2
  L3_2 = A0_2.AnimateToPoint
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nShowPoint
  L6_2 = 0
  L7_2 = true
  L8_2 = _Delay
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
end

AddReason = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2
  L1_2 = A0_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nShowPoint
  L4_2 = 2
  L5_2 = true
  L6_2 = _FadeReasons
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

_Delay = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2
  L1_2 = A0_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nHidePoint
  L4_2 = 0.5
  L5_2 = true
  L6_2 = _ClearReasons
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

_FadeReasons = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.CustomData
  L2_2 = {}
  L1_2.tReasons = L2_2
  L2_2 = A0_2
  L1_2 = A0_2.SetText
  L3_2 = " "
  L1_2(L2_2, L3_2)
end

_ClearReasons = L0_1
L0_1 = 4
_knBufferSize = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L1_2 = 0
  L2_2 = ""
  L3_2 = nil
  L4_2 = 1
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.tReasons
  L5_2 = #L5_2
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.nBufferSize
  if L5_2 > L6_2 then
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.nBufferSize
    L6_2 = L5_2 - L6_2
    L4_2 = L6_2 + 1
  end
  L6_2 = pairs
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.tReasons
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  for L9_2, L10_2 in L6_2, L7_2, L8_2 do
    L11_2 = L10_2[1]
    L1_2 = L1_2 + L11_2
    if L9_2 >= L4_2 then
      L11_2 = L10_2[1]
      if 0 < L11_2 then
        L3_2 = "+"
      else
        L11_2 = L10_2[1]
        if L11_2 < 0 then
          L3_2 = "-"
        else
          L3_2 = " "
        end
      end
      L11_2 = A0_2.CustomData
      L11_2 = L11_2.bFormatMoney
      if L11_2 then
        L11_2 = L2_2
        L12_2 = L10_2[2]
        L13_2 = " ("
        L14_2 = L3_2
        L15_2 = _ConvertNumber
        L16_2 = math
        L16_2 = L16_2.abs
        L17_2 = L10_2[1]
        L16_2, L17_2 = L16_2(L17_2)
        L15_2 = L15_2(L16_2, L17_2)
        L16_2 = ")[n]"
        L2_2 = L11_2 .. L12_2 .. L13_2 .. L14_2 .. L15_2 .. L16_2
      else
        L11_2 = L2_2
        L12_2 = L10_2[2]
        L13_2 = " ("
        L14_2 = L3_2
        L15_2 = math
        L15_2 = L15_2.abs
        L16_2 = L10_2[1]
        L15_2 = L15_2(L16_2)
        L16_2 = ")[n]"
        L2_2 = L11_2 .. L12_2 .. L13_2 .. L14_2 .. L15_2 .. L16_2
      end
    end
  end
  L6_2 = ""
  if 0 < L1_2 then
    L6_2 = "[green]"
    L3_2 = "+"
  elseif L1_2 < 0 then
    L6_2 = "[red]"
    L3_2 = "-"
  else
    L6_2 = "[white]"
    L3_2 = " "
  end
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.bFormatMoney
  if L7_2 then
    L7_2 = L6_2
    L8_2 = L3_2
    L9_2 = _ConvertNumber
    L10_2 = math
    L10_2 = L10_2.abs
    L11_2 = L1_2
    L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2 = L10_2(L11_2)
    L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
    L10_2 = "[n][white]"
    L11_2 = L2_2
    L2_2 = L7_2 .. L8_2 .. L9_2 .. L10_2 .. L11_2
  else
    L7_2 = L6_2
    L8_2 = L3_2
    L9_2 = math
    L9_2 = L9_2.abs
    L10_2 = L1_2
    L9_2 = L9_2(L10_2)
    L10_2 = "[n][white]"
    L11_2 = L2_2
    L2_2 = L7_2 .. L8_2 .. L9_2 .. L10_2 .. L11_2
  end
  L8_2 = A0_2
  L7_2 = A0_2.SetText
  L9_2 = L2_2
  L7_2(L8_2, L9_2)
end

_UpdateReasonDisplay = L0_1
L0_1 = false
_tNumbers = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = 1000
  L2_2 = "[0xe00c096a]"
  if 1.0E15 < A0_2 then
    A0_2 = 1.0E15
  end
  if A0_2 < 0 then
    A0_2 = 0
  end
  L3_2 = pairs
  L4_2 = _tNumbers
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    if L6_2 > L1_2 and L6_2 <= A0_2 then
      L1_2 = L6_2
      L2_2 = L7_2
    end
  end
  L3_2 = string
  L3_2 = L3_2.format
  L4_2 = "[SHELL.Common.Money:%d:%d:%s]"
  L5_2 = A0_2 / L1_2
  L6_2 = A0_2 / L1_2
  L7_2 = math
  L7_2 = L7_2.floor
  L8_2 = A0_2 / L1_2
  L7_2 = L7_2(L8_2)
  L6_2 = L6_2 - L7_2
  L6_2 = 10 * L6_2
  L7_2 = L2_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  return L3_2
end

_ConvertNumber = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = {}
  _tNumbers = L0_2
  L0_2 = _tNumbers
  L0_2[1.0E15] = "[0x7be2637c]"
  L0_2 = _tNumbers
  L0_2[1.0E12] = "[0x9d96ba8f]"
  L0_2 = _tNumbers
  L0_2[1000000000] = "[0x4cf9c95f]"
  L0_2 = _tNumbers
  L0_2[1000000] = "[0xcd15e5e8]"
  L0_2 = _tNumbers
  L0_2[1000] = "[0xe00c096a]"
end

Init = L0_1
