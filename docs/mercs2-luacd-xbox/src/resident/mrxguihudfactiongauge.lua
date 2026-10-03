local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGuiBase"
L0_1(L1_1)
L0_1 = 0
_knMin = L0_1
L0_1 = 100
_knMax = L0_1
L0_1 = "[0x1cab5133]"
_ksPursuit = L0_1
L0_1 = false
_tLevels = L0_1
L0_1 = false
_tLevelNames = L0_1
L0_1 = false
_tLevelColors = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = {}
  L1_2 = _knMin
  L2_2 = 25
  L3_2 = 50
  L4_2 = 75
  L0_2[1] = L1_2
  L0_2[2] = L2_2
  L0_2[3] = L3_2
  L0_2[4] = L4_2
  _tLevels = L0_2
  L0_2 = {}
  L1_2 = "[0x671b379b]"
  L2_2 = "[0x7c4225bc]"
  L3_2 = "[0xdb614732]"
  L4_2 = "[0x8c4d842e]"
  L0_2[1] = L1_2
  L0_2[2] = L2_2
  L0_2[3] = L3_2
  L0_2[4] = L4_2
  _tLevelNames = L0_2
  L0_2 = {}
  L0_2.nR = 255
  L0_2.nG = 255
  L0_2.bB = 255
  L1_2 = {}
  L2_2 = {}
  L2_2.nR = 255
  L2_2.nG = 96
  L2_2.nB = 96
  L3_2 = {}
  L3_2.nR = 160
  L3_2.nG = 160
  L3_2.nB = 160
  L4_2 = {}
  L4_2.nR = 96
  L4_2.nG = 96
  L4_2.nB = 255
  L5_2 = {}
  L5_2.nR = 96
  L5_2.nG = 96
  L5_2.nB = 255
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  _tLevelColors = L1_2
end

Init = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = _tLevels
  L1_2 = #L1_2
  L2_2 = L1_2
  while 0 < L2_2 do
    L3_2 = _tLevels
    L3_2 = L3_2[L2_2]
    if A0_2 < L3_2 then
      L1_2 = L2_2 - 1
    end
    L2_2 = L2_2 - 1
  end
  L3_2 = _tLevels
  L3_2 = L3_2[L1_2]
  L4_2 = _tLevels
  L5_2 = L1_2 + 1
  L4_2 = L4_2[L5_2]
  if not L4_2 then
    L4_2 = 100
  end
  L5_2 = A0_2 - L3_2
  L6_2 = L4_2 - L3_2
  L6_2 = 100 / L6_2
  L5_2 = L5_2 * L6_2
  L6_2 = A0_2
  L7_2 = _tLevelNames
  L7_2 = L7_2[L1_2]
  return L6_2, L7_2
end

GetBarValueAndName = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L4_2 = ipairs
  L5_2 = A0_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = type
    L10_2 = L8_2
    L9_2 = L9_2(L10_2)
    if "number" ~= L9_2 then
      L9_2 = false
      return L9_2
    end
  end
  L4_2 = ipairs
  L5_2 = A1_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = type
    L10_2 = L8_2
    L9_2 = L9_2(L10_2)
    if "string" ~= L9_2 then
      L9_2 = false
      return L9_2
    end
  end
  L4_2 = A0_2[1]
  if L4_2 ~= 0 then
    L4_2 = false
    return L4_2
  end
  L4_2 = #A0_2
  L5_2 = #A1_2
  if L4_2 ~= L5_2 then
    L4_2 = false
    return L4_2
  end
  L4_2 = -1
  L5_2 = ipairs
  L6_2 = A0_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    if L4_2 == L9_2 then
      L10_2 = false
      return L10_2
    elseif L9_2 < L4_2 then
      L10_2 = false
      return L10_2
    end
  end
  L5_2 = {}
  _tLevels = L5_2
  L5_2 = ipairs
  L6_2 = A0_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = _tLevels
    L10_2[L8_2] = L9_2
  end
  L5_2 = {}
  _tLevelNames = L5_2
  L5_2 = ipairs
  L6_2 = A1_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = _tLevelNames
    L10_2[L8_2] = L9_2
  end
  L5_2 = type
  L6_2 = A2_2
  L5_2 = L5_2(L6_2)
  if "string" == L5_2 then
    _ksPursuit = A2_2
  end
  if A3_2 then
    L5_2 = ipairs
    L6_2 = _tLevels
    L5_2, L6_2, L7_2 = L5_2(L6_2)
    for L8_2, L9_2 in L5_2, L6_2, L7_2 do
      L10_2 = _tLevels
      L11_2 = L8_2 + 1
      L10_2 = L10_2[L11_2]
      if L10_2 then
      else
      end
    end
  end
  L5_2 = true
  return L5_2
end

SetLevels = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L1_2 = A0_2.CustomData
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L1_2.nCurrentValue = 0
  L1_2.nCurrentMood = 0
  L1_2.nCurrentLevel = 1
  L1_2.nMaxLevel = 4
  L1_2.nMinLevel = 1
  L3_2 = L2_2[2]
  L4_2 = L3_2
  L3_2 = L3_2.GetChildren
  L3_2 = L3_2(L4_2)
  L4_2 = L3_2[3]
  L1_2.oGaugeFront = L4_2
  L4_2 = L3_2[2]
  L1_2.oGaugeDelta = L4_2
  L4_2 = L2_2[3]
  L1_2.oIcon = L4_2
  L4_2 = L2_2[5]
  L1_2.oMood = L4_2
  L4_2 = L2_2[1]
  L5_2 = L4_2
  L4_2 = L4_2.GetChildren
  L4_2 = L4_2(L5_2)
  L4_2 = L4_2[1]
  L1_2.oPursuit = L4_2
  L4_2 = L1_2.oMood
  L5_2 = L4_2
  L4_2 = L4_2.SetJustification
  L6_2 = "right"
  L4_2(L5_2, L6_2)
  L4_2 = L1_2.oGaugeFront
  L5_2 = L4_2
  L4_2 = L4_2.GetLocation
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  L8_2 = L1_2.oGaugeFront
  L9_2 = L8_2
  L8_2 = L8_2.GetTextureCoordinates
  L8_2, L9_2, L10_2, L11_2 = L8_2(L9_2)
  L12_2 = L6_2 - L4_2
  L1_2.nGaugeLength = L12_2
  L1_2.nGaugeBaseX = L4_2
  L12_2 = L1_2.oGaugeFront
  L13_2 = L12_2
  L12_2 = L12_2.AddAnimationPoint
  L14_2 = {}
  L14_2.x = L4_2
  L14_2.x2 = L4_2
  L14_2.nU1 = L8_2
  L14_2.nV1 = L9_2
  L14_2.nU2 = L8_2
  L14_2.nV2 = L11_2
  L12_2 = L12_2(L13_2, L14_2)
  L1_2.nGaugeFrontEmptyPoint = L12_2
  L12_2 = L1_2.oGaugeFront
  L13_2 = L12_2
  L12_2 = L12_2.AddAnimationPoint
  L14_2 = {}
  L14_2.x = L4_2
  L14_2.x2 = L6_2
  L12_2 = L12_2(L13_2, L14_2)
  L1_2.nGaugeFrontDestPoint = L12_2
  L12_2 = L1_2.oGaugeDelta
  L13_2 = L12_2
  L12_2 = L12_2.AddAnimationPoint
  L14_2 = {}
  L14_2.x = L4_2
  L14_2.x2 = L6_2
  L12_2 = L12_2(L13_2, L14_2)
  L1_2.nGaugeDeltaDestPoint = L12_2
  L12_2 = L1_2.oGaugeFront
  L13_2 = L12_2
  L12_2 = L12_2.AddAnimationPoint
  L14_2 = {}
  L12_2 = L12_2(L13_2, L14_2)
  L1_2.nGaugeFrontColorPoint = L12_2
  L12_2 = L1_2.oGaugeDelta
  L13_2 = L12_2
  L12_2 = L12_2.AddAnimationPoint
  L14_2 = {}
  L12_2 = L12_2(L13_2, L14_2)
  L1_2.nGaugeDeltaNullPoint = L12_2
  L12_2 = L1_2.oGaugeDelta
  L13_2 = L12_2
  L12_2 = L12_2.SetLocation
  L14_2 = L6_2
  L15_2 = nil
  L16_2 = L6_2
  L17_2 = nil
  L12_2(L13_2, L14_2, L15_2, L16_2, L17_2)
  L12_2 = L1_2.oMood
  L13_2 = L12_2
  L12_2 = L12_2.GetColor
  L12_2, L13_2, L14_2 = L12_2(L13_2)
  L15_2 = L1_2.oMood
  L16_2 = L15_2
  L15_2 = L15_2.AddAnimationPoint
  L17_2 = {}
  L17_2.RedLevel = 64
  L17_2.GreenLevel = 255
  L17_2.BlueLevel = 64
  L15_2 = L15_2(L16_2, L17_2)
  L1_2.nMoodRaisePoint = L15_2
  L15_2 = L1_2.oMood
  L16_2 = L15_2
  L15_2 = L15_2.AddAnimationPoint
  L17_2 = {}
  L17_2.RedLevel = 210
  L17_2.GreenLevel = 0
  L17_2.BlueLevel = 0
  L15_2 = L15_2(L16_2, L17_2)
  L1_2.nMoodLowerPoint = L15_2
  L15_2 = L1_2.oMood
  L16_2 = L15_2
  L15_2 = L15_2.AddAnimationPoint
  L17_2 = {}
  L17_2.RedLevel = L12_2
  L17_2.GreenLevel = L13_2
  L17_2.BlueLevel = L14_2
  L15_2 = L15_2(L16_2, L17_2)
  L1_2.nMoodStartPoint = L15_2
  L1_2.nGaugeFrontU1 = L8_2
  L15_2 = L10_2 - L8_2
  L1_2.nGaugeFrontUDiff = L15_2
  L15_2 = SetValue
  A0_2.SetValue = L15_2
  L15_2 = GetValue
  A0_2.GetValue = L15_2
  L15_2 = SetIcon
  A0_2.SetIcon = L15_2
  L15_2 = SetIconVisible
  A0_2.SetIconVisible = L15_2
  L15_2 = ChangeValue
  A0_2.ChangeValue = L15_2
  L15_2 = StartTimer
  A0_2.StartTimer = L15_2
  L15_2 = StopTimer
  A0_2.StopTimer = L15_2
  L15_2 = StartPursuitGauge
  A0_2.StartPursuit = L15_2
  L15_2 = StopPursuitGauge
  A0_2.StopPursuit = L15_2
  L15_2 = IsPursuitActive
  A0_2.IsPursuitActive = L15_2
  L15_2 = GetRemainingPursuitTime
  A0_2.GetRemainingPursuitTime = L15_2
  L15_2 = Initialize
  A0_2._Initialize = L15_2
  L15_2 = _RiseToValue
  A0_2._RiseToValue = L15_2
  L15_2 = _CancelRise
  A0_2._CancelRise = L15_2
  L15_2 = MrxGuiBase
  L15_2 = L15_2.Widget
  L15_2 = L15_2.SetVisible
  A0_2._RealSetVisible = L15_2
  L15_2 = _SetVisible
  A0_2.SetVisible = L15_2
  L15_2 = L2_2[4]
  L1_2.oTimer = L15_2
  L1_2.fTimerCallback = nil
  L1_2.tTimerCallbackData = nil
  L15_2 = L1_2.oTimer
  L16_2 = L15_2
  L15_2 = L15_2.SetVisible
  L17_2 = false
  L15_2(L16_2, L17_2)
  L16_2 = A0_2
  L15_2 = A0_2.SetValue
  L17_2 = 100
  L18_2 = true
  L15_2(L16_2, L17_2, L18_2)
end

Initialize = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2
  L3_2 = A0_2.CustomData
  L4_2 = L3_2.bPursuitActive
  if L4_2 then
    L4_2 = _knMin
    if A1_2 > L4_2 then
      L5_2 = A0_2
      L4_2 = A0_2.StopPursuit
      L4_2(L5_2)
    end
  end
  L4_2 = L3_2.oGaugeFront
  L5_2 = L4_2
  L4_2 = L4_2.GetLocation
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  L8_2 = L6_2 - L4_2
  L9_2 = L3_2.nGaugeLength
  L8_2 = L8_2 / L9_2
  L8_2 = L8_2 * 100
  L9_2 = nil
  L10_2 = L3_2.nCurrentMood
  if A1_2 <= L10_2 then
    L10_2 = L3_2.nCurrentLevel
    while true do
      L11_2 = L3_2.nMinLevel
      if not (L10_2 >= L11_2) then
        break
      end
      L11_2 = _tLevels
      L11_2 = L11_2[L10_2]
      if A1_2 < L11_2 then
        L9_2 = L10_2 - 1
      end
      L10_2 = L10_2 - 1
    end
  else
    L10_2 = L3_2.nCurrentMood
    if A1_2 >= L10_2 then
      L10_2 = L3_2.nCurrentLevel
      L10_2 = L10_2 + 1
      L11_2 = _tLevels
      L11_2 = #L11_2
      while L10_2 <= L11_2 do
        L12_2 = _tLevels
        L12_2 = L12_2[L10_2]
        if A1_2 >= L12_2 then
          L9_2 = L10_2
        end
        L10_2 = L10_2 + 1
      end
    end
  end
  L10_2 = L9_2 or L10_2
  if not L9_2 then
    L10_2 = L3_2.nCurrentLevel
  end
  L11_2 = _tLevels
  L11_2 = L11_2[L10_2]
  L12_2 = _tLevels
  L13_2 = L10_2 + 1
  L12_2 = L12_2[L13_2]
  if not L12_2 then
    L12_2 = 100
  end
  L13_2 = A1_2
  L3_2.nCurrentMood = A1_2
  if A2_2 then
    L14_2 = _SnapBarToValue
    L15_2 = A0_2
    L16_2 = L13_2
    L14_2(L15_2, L16_2)
    L3_2.nCurrentLevel = L10_2
    L3_2.nCurrentValue = L13_2
    L14_2 = A0_2.CustomData
    L14_2 = L14_2.oMood
    L15_2 = L14_2
    L14_2 = L14_2.SetText
    L16_2 = _tLevelNames
    L17_2 = A0_2.CustomData
    L17_2 = L17_2.nCurrentLevel
    L16_2 = L16_2[L17_2]
    L14_2(L15_2, L16_2)
    do return end
    goto lbl_157
    L14_2 = 1.5
    L15_2 = math
    L15_2 = L15_2.abs
    L16_2 = L3_2.nCurrentLevel
    L16_2 = L9_2 - L16_2
    L15_2 = L15_2(L16_2)
    L15_2 = L15_2 - 1
    if 2 <= L15_2 then
      L14_2 = 0.5
    elseif 1 <= L15_2 then
      L14_2 = 1
    end
    L16_2 = L15_2 * L14_2
    L17_2 = nil
    L18_2 = L3_2.nCurrentLevel
    if L9_2 > L18_2 then
      L18_2 = _knMax
      L18_2 = L18_2 - L8_2
      L18_2 = L18_2 * L14_2
      L17_2 = L18_2 * 0.01
      L18_2 = L13_2 * L14_2
      L18_2 = L18_2 * 0.01
      L16_2 = L16_2 + L18_2
    else
      L18_2 = L3_2.nCurrentLevel
      if L9_2 < L18_2 then
        L18_2 = L8_2 * L14_2
        L17_2 = L18_2 * 0.01
        L18_2 = _knMax
        L18_2 = L18_2 - L13_2
        L18_2 = L18_2 * L14_2
        L18_2 = L18_2 * 0.01
        L16_2 = L16_2 + L18_2
      end
    end
    L18_2 = L3_2.nCurrentLevel
    if L9_2 < L18_2 then
      L18_2 = SetValueAndLevel
      L19_2 = A0_2
      L20_2 = _knMin
      L21_2 = false
      L22_2 = L17_2
      L23_2 = L3_2.nCurrentLevel
      L23_2 = L23_2 - 1
      L24_2 = _TransitionToLevel
      L25_2 = {}
      L26_2 = A0_2
      L27_2 = L9_2
      L28_2 = L13_2
      L29_2 = L16_2
      L30_2 = false
      L25_2[1] = L26_2
      L25_2[2] = L27_2
      L25_2[3] = L28_2
      L25_2[4] = L29_2
      L25_2[5] = L30_2
      L18_2(L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2)
    else
      L18_2 = L3_2.nCurrentLevel
      if L9_2 > L18_2 then
        L18_2 = SetValueAndLevel
        L19_2 = A0_2
        L20_2 = _knMax
        L21_2 = false
        L22_2 = L17_2
        L23_2 = L3_2.nCurrentLevel
        L23_2 = L23_2 + 1
        L24_2 = _TransitionToLevel
        L25_2 = {}
        L26_2 = A0_2
        L27_2 = L9_2
        L28_2 = L13_2
        L29_2 = L16_2
        L30_2 = true
        L25_2[1] = L26_2
        L25_2[2] = L27_2
        L25_2[3] = L28_2
        L25_2[4] = L29_2
        L25_2[5] = L30_2
        L18_2(L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2)
      end
    end
  else
    ::lbl_157::
    L14_2 = SetValueAndLevel
    L15_2 = A0_2
    L16_2 = L13_2
    L17_2 = A2_2
    L18_2 = _Abs
    L19_2 = L3_2.nCurrentValue
    L19_2 = L13_2 - L19_2
    L18_2 = L18_2(L19_2)
    L18_2 = L18_2 * 0.01
    L18_2 = L18_2 * 2
    L19_2 = L9_2
    L14_2(L15_2, L16_2, L17_2, L18_2, L19_2)
  end
end

SetValue = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L5_2 = A0_2.CustomData
  L6_2 = L5_2.nCurrentLevel
  if L6_2 == 1 and A1_2 < 1 then
  else
    L6_2 = L5_2.nCurrentLevel
    if A1_2 == L6_2 then
      if A4_2 then
        L6_2 = _SnapBarToValue
        L7_2 = A0_2
        L8_2 = _knMin
        L6_2(L7_2, L8_2)
      else
        L6_2 = _SnapBarToValue
        L7_2 = A0_2
        L8_2 = _knMax
        L6_2(L7_2, L8_2)
      end
      L6_2 = SetValueAndLevel
      L7_2 = A0_2
      L8_2 = A2_2
      L9_2 = false
      L10_2 = A3_2
      L11_2 = nil
      L12_2 = nil
      L13_2 = nil
      L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
    elseif A4_2 then
      L6_2 = _SnapBarToValue
      L7_2 = A0_2
      L8_2 = _knMin
      L6_2(L7_2, L8_2)
      L6_2 = _knMin
      L6_2 = A2_2 - L6_2
      L6_2 = L6_2 * 0.01
      L7_2 = L5_2.nCurrentLevel
      L7_2 = A1_2 - L7_2
      L6_2 = L6_2 + L7_2
      L7_2 = nil
      if 0 < L6_2 then
        L7_2 = A3_2 / L6_2
      else
        L7_2 = 0
      end
      A3_2 = A3_2 - L7_2
      L8_2 = SetValueAndLevel
      L9_2 = A0_2
      L10_2 = _knMax
      L11_2 = false
      L12_2 = L7_2
      L13_2 = L5_2.nCurrentLevel
      L13_2 = L13_2 + 1
      L14_2 = _TransitionToLevel
      L15_2 = {}
      L16_2 = A0_2
      L17_2 = A1_2
      L18_2 = A2_2
      L19_2 = A3_2
      L20_2 = A4_2
      L15_2[1] = L16_2
      L15_2[2] = L17_2
      L15_2[3] = L18_2
      L15_2[4] = L19_2
      L15_2[5] = L20_2
      L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
    else
      L6_2 = _SnapBarToValue
      L7_2 = A0_2
      L8_2 = _knMax
      L6_2(L7_2, L8_2)
      L6_2 = _knMax
      L6_2 = L6_2 - A2_2
      L6_2 = L6_2 * 0.01
      L7_2 = L5_2.nCurrentLevel
      L7_2 = L7_2 - A1_2
      L6_2 = L6_2 + L7_2
      L7_2 = nil
      if 0 < L6_2 then
        L7_2 = A3_2 / L6_2
      else
        L7_2 = 0
      end
      A3_2 = A3_2 - L7_2
      L8_2 = SetValueAndLevel
      L9_2 = A0_2
      L10_2 = _knMin
      L11_2 = false
      L12_2 = L7_2
      L13_2 = L5_2.nCurrentLevel
      L13_2 = L13_2 - 1
      L14_2 = _TransitionToLevel
      L15_2 = {}
      L16_2 = A0_2
      L17_2 = A1_2
      L18_2 = A2_2
      L19_2 = A3_2
      L20_2 = A4_2
      L15_2[1] = L16_2
      L15_2[2] = L17_2
      L15_2[3] = L18_2
      L15_2[4] = L19_2
      L15_2[5] = L20_2
      L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
    end
  end
end

_TransitionToLevel = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2)
  local L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2
  L7_2 = _Clamp
  L8_2 = A1_2
  L9_2 = _knMin
  L10_2 = _knMax
  L7_2 = L7_2(L8_2, L9_2, L10_2)
  L8_2 = A0_2.CustomData
  L8_2 = L8_2.nCurrentValue
  if L7_2 == L8_2 then
    L8_2 = A0_2.CustomData
    L8_2 = L8_2.bPursuitActive
    if not L8_2 and not A2_2 then
      L8_2 = A0_2.CustomData
      L9_2 = A4_2 or L9_2
      if not A4_2 then
        L9_2 = A0_2.CustomData
        L9_2 = L9_2.nCurrentLevel
      end
      L8_2.nCurrentLevel = L9_2
      L8_2 = A0_2.CustomData
      L8_2 = L8_2.oMood
      L9_2 = L8_2
      L8_2 = L8_2.SetText
      L10_2 = _tLevelNames
      L11_2 = A0_2.CustomData
      L11_2 = L11_2.nCurrentLevel
      L10_2 = L10_2[L11_2]
      L8_2(L9_2, L10_2)
      if A5_2 then
        if not A6_2 then
          L8_2 = {}
          A6_2 = L8_2
        end
        L8_2 = A5_2
        L9_2 = unpack
        L10_2 = A6_2
        L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2 = L9_2(L10_2)
        L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2)
      end
      return
    end
  end
  L8_2 = A0_2.CustomData
  L9_2 = L8_2.oGaugeFront
  L10_2 = L9_2
  L9_2 = L9_2.SetColor
  L11_2 = 255
  L12_2 = 255
  L13_2 = 255
  L9_2(L10_2, L11_2, L12_2, L13_2)
  L9_2 = L8_2.oGaugeFront
  L10_2 = L9_2
  L9_2 = L9_2.GetLocation
  L9_2, L10_2, L11_2, L12_2 = L9_2(L10_2)
  L13_2 = L8_2.oGaugeFront
  L14_2 = L13_2
  L13_2 = L13_2.GetTextureCoordinates
  L13_2, L14_2, L15_2, L16_2 = L13_2(L14_2)
  L17_2 = L8_2.nGaugeBaseX
  L18_2 = L7_2 * 0.01
  L19_2 = L8_2.nGaugeLength
  L18_2 = L18_2 * L19_2
  L17_2 = L17_2 + L18_2
  L18_2 = L8_2.nGaugeFrontU1
  L19_2 = L7_2 * 0.01
  L20_2 = L8_2.nGaugeFrontUDiff
  L19_2 = L19_2 * L20_2
  L18_2 = L18_2 + L19_2
  L19_2 = L11_2 - L9_2
  L20_2 = L8_2.nGaugeLength
  L19_2 = L19_2 / L20_2
  L19_2 = L19_2 * 100
  L20_2 = {}
  L20_2.x = L9_2
  L20_2.x2 = L17_2
  L20_2.nU1 = L13_2
  L20_2.nV1 = L14_2
  L20_2.nU2 = L18_2
  L20_2.nV2 = L16_2
  L21_2 = {}
  L21_2.x = L17_2
  L21_2.x2 = L17_2
  L22_2 = L8_2.oGaugeFront
  L23_2 = L22_2
  L22_2 = L22_2.SetAnimationPoint
  L24_2 = L8_2.nGaugeFrontDestPoint
  L25_2 = L20_2
  L22_2(L23_2, L24_2, L25_2)
  L22_2 = L8_2.oGaugeDelta
  L23_2 = L22_2
  L22_2 = L22_2.SetAnimationPoint
  L24_2 = L8_2.nGaugeDeltaDestPoint
  L25_2 = L21_2
  L22_2(L23_2, L24_2, L25_2)
  L22_2 = A3_2 or L22_2
  if not A3_2 then
    L22_2 = math
    L22_2 = L22_2.abs
    L23_2 = L8_2.nCurrentValue
    L23_2 = L7_2 - L23_2
    L22_2 = L22_2(L23_2)
    L22_2 = L22_2 * 0.01
    L22_2 = L22_2 * 2
  end
  L23_2 = nil
  if L22_2 then
    L23_2 = L22_2 * 0.25
  else
    L23_2 = 0.5
  end
  if A2_2 then
    L24_2 = L8_2.oGaugeFront
    L25_2 = L24_2
    L24_2 = L24_2.AnimateToPoint
    L26_2 = L8_2.nGaugeFrontDestPoint
    L27_2 = 0
    L28_2 = true
    L24_2(L25_2, L26_2, L27_2, L28_2)
    L24_2 = L8_2.oGaugeDelta
    L25_2 = L24_2
    L24_2 = L24_2.AnimateToPoint
    L26_2 = L8_2.nGaugeDeltaDestPoint
    L27_2 = 0
    L28_2 = true
    L29_2 = _FinishGaugeAnimation
    L30_2 = {}
    L31_2 = A0_2
    L32_2 = L8_2.oGaugeDelta
    L32_2 = L32_2.SetVisible
    L33_2 = {}
    L34_2 = false
    L33_2[1] = L34_2
    L30_2[1] = L31_2
    L30_2[2] = L32_2
    L30_2[3] = L33_2
    L24_2(L25_2, L26_2, L27_2, L28_2, L29_2, L30_2)
  elseif L7_2 < L19_2 then
    L24_2 = L8_2.oGaugeDelta
    L25_2 = L24_2
    L24_2 = L24_2.SetColor
    L26_2 = 128
    L27_2 = 0
    L28_2 = 0
    L24_2(L25_2, L26_2, L27_2, L28_2)
    L24_2 = L8_2.oGaugeDelta
    L25_2 = L24_2
    L24_2 = L24_2.AnimateToPoint
    L26_2 = L8_2.nGaugeDeltaNullPoint
    L27_2 = 0
    L28_2 = true
    L24_2(L25_2, L26_2, L27_2, L28_2)
    L24_2 = L8_2.oGaugeFront
    L25_2 = L24_2
    L24_2 = L24_2.SetLocation
    L26_2 = L9_2
    L27_2 = nil
    L28_2 = L17_2
    L24_2(L25_2, L26_2, L27_2, L28_2)
    L24_2 = L8_2.oGaugeFront
    L25_2 = L24_2
    L24_2 = L24_2.SetTextureCoordinates
    L26_2 = nil
    L27_2 = nil
    L28_2 = L8_2.nGaugeFrontU1
    L29_2 = L8_2.nGaugeFrontUDiff
    L30_2 = _knMax
    L31_2 = _knMin
    L30_2 = L30_2 - L31_2
    L30_2 = L7_2 / L30_2
    L29_2 = L29_2 * L30_2
    L28_2 = L28_2 + L29_2
    L24_2(L25_2, L26_2, L27_2, L28_2)
    L24_2 = L8_2.oGaugeFront
    L25_2 = L24_2
    L24_2 = L24_2.AnimateToPoint
    L26_2 = L8_2.nGaugeFrontColorPoint
    L27_2 = L23_2
    L28_2 = true
    L29_2 = _Animate
    L30_2 = {}
    L31_2 = L8_2.oGaugeDelta
    L32_2 = L8_2.nGaugeDeltaDestPoint
    L33_2 = L22_2
    L34_2 = true
    L35_2 = _FinishGaugeAnimation
    L36_2 = {}
    L37_2 = A0_2
    L38_2 = A5_2
    L39_2 = A6_2
    L40_2 = true
    L36_2[1] = L37_2
    L36_2[2] = L38_2
    L36_2[3] = L39_2
    L36_2[4] = L40_2
    L30_2[1] = L31_2
    L30_2[2] = L32_2
    L30_2[3] = L33_2
    L30_2[4] = L34_2
    L30_2[5] = L35_2
    L30_2[6] = L36_2
    L24_2(L25_2, L26_2, L27_2, L28_2, L29_2, L30_2)
    L24_2 = L8_2.oGaugeDelta
    L25_2 = L24_2
    L24_2 = L24_2.SetLocation
    L26_2 = L17_2
    L27_2 = nil
    L28_2 = L11_2
    L24_2(L25_2, L26_2, L27_2, L28_2)
  elseif L7_2 > L19_2 then
    L24_2 = L8_2.oGaugeDelta
    L25_2 = L24_2
    L24_2 = L24_2.SetColor
    L26_2 = 0
    L27_2 = 128
    L28_2 = 0
    L24_2(L25_2, L26_2, L27_2, L28_2)
    L24_2 = L8_2.oGaugeDelta
    L25_2 = L24_2
    L24_2 = L24_2.AnimateToPoint
    L26_2 = L8_2.nGaugeDeltaNullPoint
    L27_2 = 0
    L28_2 = true
    L24_2(L25_2, L26_2, L27_2, L28_2)
    L24_2 = L8_2.oGaugeDelta
    L25_2 = L24_2
    L24_2 = L24_2.SetLocation
    L26_2 = L11_2
    L27_2 = nil
    L28_2 = L17_2
    L24_2(L25_2, L26_2, L27_2, L28_2)
    L24_2 = L8_2.oGaugeFront
    L25_2 = L24_2
    L24_2 = L24_2.AnimateToPoint
    L26_2 = L8_2.nGaugeFrontColorPoint
    L27_2 = L23_2
    L28_2 = true
    L29_2 = _Animate
    L30_2 = {}
    L31_2 = L8_2.oGaugeDelta
    L32_2 = L8_2.nGaugeDeltaDestPoint
    L33_2 = L22_2
    L34_2 = true
    L30_2[1] = L31_2
    L30_2[2] = L32_2
    L30_2[3] = L33_2
    L30_2[4] = L34_2
    L24_2(L25_2, L26_2, L27_2, L28_2, L29_2, L30_2)
    L24_2 = L8_2.oGaugeFront
    L25_2 = L24_2
    L24_2 = L24_2.AnimateToPoint
    L26_2 = L8_2.nGaugeFrontDestPoint
    L27_2 = L22_2
    L28_2 = false
    L29_2 = _FinishGaugeAnimation
    L30_2 = {}
    L31_2 = A0_2
    L32_2 = A5_2
    L33_2 = A6_2
    L34_2 = true
    L30_2[1] = L31_2
    L30_2[2] = L32_2
    L30_2[3] = L33_2
    L30_2[4] = L34_2
    L24_2(L25_2, L26_2, L27_2, L28_2, L29_2, L30_2)
  end
  L8_2.nCurrentValue = A1_2
  L24_2 = A4_2 or L24_2
  if not A4_2 then
    L24_2 = L8_2.nCurrentLevel
  end
  L8_2.nCurrentLevel = L24_2
  L24_2 = L8_2.nCurrentLevel
  if L24_2 then
    L24_2 = _tLevelColors
    L25_2 = L8_2.nCurrentLevel
    L24_2 = L24_2[L25_2]
    if L24_2 then
      L24_2 = _tLevelColors
      L25_2 = L8_2.nCurrentLevel
      L24_2 = L24_2[L25_2]
      L25_2 = L8_2.oGaugeFront
      L26_2 = L25_2
      L25_2 = L25_2.SetColor
      L27_2 = L24_2.nR
      L28_2 = L24_2.nG
      L29_2 = L24_2.nB
      L25_2(L26_2, L27_2, L28_2, L29_2)
    end
  end
end

SetValueAndLevel = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = A0_2.CustomData
  L3_2 = L2_2.nGaugeBaseX
  L4_2 = L2_2.oGaugeFront
  L5_2 = L4_2
  L4_2 = L4_2.GetTextureCoordinates
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  L4_2 = L2_2.nGaugeFrontU1
  L8_2 = L2_2.nGaugeFrontU1
  L9_2 = L2_2.nGaugeFrontUDiff
  L10_2 = A1_2 / 100
  L9_2 = L9_2 * L10_2
  L6_2 = L8_2 + L9_2
  L8_2 = L2_2.oGaugeFront
  L9_2 = L8_2
  L8_2 = L8_2.SetLocation
  L10_2 = L3_2
  L11_2 = nil
  L12_2 = L2_2.nGaugeLength
  L13_2 = A1_2 / 100
  L12_2 = L12_2 * L13_2
  L12_2 = L3_2 + L12_2
  L8_2(L9_2, L10_2, L11_2, L12_2)
  L8_2 = L2_2.oGaugeFront
  L9_2 = L8_2
  L8_2 = L8_2.SetTextureCoordinates
  L10_2 = L4_2
  L11_2 = nil
  L12_2 = L6_2
  L8_2(L9_2, L10_2, L11_2, L12_2)
  L8_2 = L2_2.oGaugeDelta
  L9_2 = L8_2
  L8_2 = L8_2.SetLocation
  L10_2 = L3_2
  L11_2 = nil
  L12_2 = L3_2
  L8_2(L9_2, L10_2, L11_2, L12_2)
  L8_2 = L2_2.oGaugeFront
  L9_2 = L8_2
  L8_2 = L8_2.SetAnimationPoint
  L10_2 = L2_2.nGaugeFrontDestPoint
  L11_2 = {}
  L11_2.x = L3_2
  L12_2 = L2_2.nGaugeLength
  L13_2 = A1_2 / 100
  L12_2 = L12_2 * L13_2
  L12_2 = L3_2 + L12_2
  L11_2.x2 = L12_2
  L11_2.nU1 = L4_2
  L11_2.nV1 = L5_2
  L11_2.nU2 = L6_2
  L11_2.nV2 = L7_2
  L8_2(L9_2, L10_2, L11_2)
  L8_2 = L2_2.oGaugeDelta
  L9_2 = L8_2
  L8_2 = L8_2.SetAnimationPoint
  L10_2 = L2_2.nGaugeDeltaDestPoint
  L11_2 = {}
  L11_2.x = L3_2
  L12_2 = nX2
  L11_2.x2 = L12_2
  L8_2(L9_2, L10_2, L11_2)
  L8_2 = L2_2.oGaugeFront
  L9_2 = L8_2
  L8_2 = L8_2.AnimateToPoint
  L10_2 = L2_2.nGaugeFrontDestPoint
  L11_2 = 0
  L12_2 = true
  L8_2(L9_2, L10_2, L11_2, L12_2)
  L8_2 = L2_2.oGaugeDelta
  L9_2 = L8_2
  L8_2 = L8_2.AnimateToPoint
  L10_2 = L2_2.nGaugeDeltaDestPoint
  L11_2 = 0
  L12_2 = true
  L8_2(L9_2, L10_2, L11_2, L12_2)
  L2_2.nCurrentValue = A1_2
  L8_2 = L2_2.nCurrentLevel
  if L8_2 then
    L8_2 = _tLevelColors
    L9_2 = L2_2.nCurrentLevel
    L8_2 = L8_2[L9_2]
    if L8_2 then
      L8_2 = _tLevelColors
      L9_2 = L2_2.nCurrentLevel
      L8_2 = L8_2[L9_2]
      L9_2 = L2_2.oGaugeFront
      L10_2 = L9_2
      L9_2 = L9_2.SetColor
      L11_2 = L8_2.nR
      L12_2 = L8_2.nG
      L13_2 = L8_2.nB
      L9_2(L10_2, L11_2, L12_2, L13_2)
    end
  end
end

_SnapBarToValue = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.nCurrentValue
  return L1_2
end

GetValue = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oIcon
  if L2_2 then
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.oIcon
    L3_2 = L2_2
    L2_2 = L2_2.SetTexture
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  end
end

SetIcon = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oIcon
  if L3_2 then
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.oIcon
    L4_2 = L3_2
    L3_2 = L3_2.SetVisible
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
    if A2_2 then
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.oIcon
      L4_2 = L3_2
      L3_2 = L3_2.SetTranslucency
      L5_2 = A2_2
      L3_2(L4_2, L5_2)
    end
  end
end

SetIconVisible = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L4_2 = A0_2
  L3_2 = A0_2.SetValue
  L6_2 = A0_2
  L5_2 = A0_2.GetValue
  L5_2 = L5_2(L6_2)
  L5_2 = L5_2 + A1_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
end

ChangeValue = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = A0_2.CustomData
  L6_2 = A0_2
  L5_2 = A0_2.SetVisible
  L7_2 = true
  L8_2 = true
  L5_2(L6_2, L7_2, L8_2)
  L4_2.fTimerCallback = A2_2
  L4_2.tTimerCallbackData = A3_2
  L5_2 = L4_2.oTimer
  L6_2 = L5_2
  L5_2 = L5_2.SetCallback
  L7_2 = _TimerCallback
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L5_2(L6_2, L7_2, L8_2)
  L5_2 = L4_2.oTimer
  L6_2 = L5_2
  L5_2 = L5_2.Start
  L7_2 = A1_2
  L5_2(L6_2, L7_2)
end

StartTimer = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = A0_2.CustomData
  L1_2.fTimerCallback = nil
  L1_2.tTimerCallbackData = nil
  L2_2 = L1_2.oTimer
  L3_2 = L2_2
  L2_2 = L2_2.SetCallback
  L4_2 = nil
  L2_2(L3_2, L4_2)
  L2_2 = L1_2.oTimer
  L3_2 = L2_2
  L2_2 = L2_2.Stop
  L4_2 = nTime
  L2_2(L3_2, L4_2)
end

StopTimer = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = A0_2.CustomData
  L3_2 = A0_2
  L2_2 = A0_2.SetVisible
  L4_2 = true
  L5_2 = false
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = type
  L3_2 = L1_2.fTimerCallback
  L2_2 = L2_2(L3_2)
  if "function" == L2_2 then
    L2_2 = L1_2.fTimerCallback
    L3_2 = {}
    L4_2 = type
    L5_2 = L1_2.tTimerCallbackData
    L4_2 = L4_2(L5_2)
    if "table" == L4_2 then
      L3_2 = L1_2.tTimerCallbackData
    end
    L1_2.fTimerCallback = nil
    L1_2.tTimerCallbackData = nil
    L4_2 = L2_2
    L5_2 = unpack
    L6_2 = L3_2
    L5_2, L6_2 = L5_2(L6_2)
    L4_2(L5_2, L6_2)
  end
end

_TimerCallback = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2
  L5_2 = A1_2.CustomData
  L5_2 = L5_2.oMood
  L6_2 = L5_2
  L5_2 = L5_2.SetText
  L7_2 = _tLevelNames
  L8_2 = A1_2.CustomData
  L8_2 = L8_2.nCurrentLevel
  L7_2 = L7_2[L8_2]
  L5_2(L6_2, L7_2)
  L5_2 = type
  L6_2 = A2_2
  L5_2 = L5_2(L6_2)
  if "function" == L5_2 then
    if not A3_2 then
      L5_2 = {}
      A3_2 = L5_2
    end
    if not A4_2 then
      L5_2 = table
      L5_2 = L5_2.insert
      L6_2 = A3_2
      L7_2 = 1
      L8_2 = A0_2
      L5_2(L6_2, L7_2, L8_2)
    end
    L5_2 = A2_2
    L6_2 = unpack
    L7_2 = A3_2
    L6_2, L7_2, L8_2 = L6_2(L7_2)
    L5_2(L6_2, L7_2, L8_2)
  end
end

_FinishGaugeAnimation = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L4_2 = A0_2.CustomData
  L6_2 = A0_2
  L5_2 = A0_2.SetValue
  L7_2 = L4_2.nCurrentMood
  L8_2 = true
  L5_2(L6_2, L7_2, L8_2)
  L6_2 = A0_2
  L5_2 = A0_2.SetVisible
  L7_2 = true
  L8_2 = false
  L9_2 = true
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L4_2.bPursuitActive = true
  L5_2 = L4_2.oPursuit
  L6_2 = A0_2.CustomData
  L7_2 = L6_2.oMood
  L8_2 = L7_2
  L7_2 = L7_2.SetText
  L9_2 = _ksPursuit
  L7_2(L8_2, L9_2)
  L7_2 = L6_2.oGaugeFront
  L8_2 = L7_2
  L7_2 = L7_2.SetColor
  L9_2 = 210
  L10_2 = 0
  L11_2 = 0
  L7_2(L8_2, L9_2, L10_2, L11_2)
  L7_2 = L6_2.oGaugeFront
  L8_2 = L7_2
  L7_2 = L7_2.AnimateToPoint
  L9_2 = L6_2.nGaugeFrontEmptyPoint
  L10_2 = 0
  L11_2 = true
  L12_2 = _AnimateToEnd
  L13_2 = {}
  L14_2 = A0_2
  L15_2 = A1_2
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L7_2 = L6_2.oGaugeDelta
  L8_2 = L7_2
  L7_2 = L7_2.GetLocation
  L7_2 = L7_2(L8_2)
  L8_2 = L6_2.oGaugeDelta
  L9_2 = L8_2
  L8_2 = L8_2.SetLocation
  L10_2 = L7_2
  L11_2 = nil
  L12_2 = L7_2
  L13_2 = nil
  L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  L8_2 = L6_2.oGaugeDelta
  L9_2 = L8_2
  L8_2 = L8_2.AnimateToPoint
  L10_2 = L6_2.nGaugeDeltaNullPoint
  L11_2 = 0
  L12_2 = true
  L8_2(L9_2, L10_2, L11_2, L12_2)
  L8_2 = type
  L9_2 = A1_2
  L8_2 = L8_2(L9_2)
  if "number" == L8_2 and 0 < A1_2 then
    L8_2 = L5_2.CustomData
    L8_2.fCallback = A2_2
    L8_2 = L5_2.CustomData
    L8_2.tCallbackData = A3_2
    L8_2 = L5_2.CustomData
    L8_2.nTotalTime = A1_2
    L9_2 = L5_2
    L8_2 = L5_2.SetClockAnimationCallback
    L10_2 = _PursuitAnimationComplete
    L11_2 = {}
    L12_2 = A0_2
    L11_2[1] = L12_2
    L8_2(L9_2, L10_2, L11_2)
    L9_2 = L5_2
    L8_2 = L5_2.SetClockAnimation
    L10_2 = 0
    L11_2 = A1_2
    L12_2 = false
    L13_2 = true
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
    L9_2 = L5_2
    L8_2 = L5_2.SetVisible
    L10_2 = false
    L8_2(L9_2, L10_2)
  end
end

StartPursuitGauge = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L3_2 = A1_2.CustomData
  L4_2 = L3_2.nGaugeBaseX
  L6_2 = A0_2
  L5_2 = A0_2.GetTextureCoordinates
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  L5_2 = L3_2.nGaugeFrontU1
  L9_2 = L3_2.nGaugeLength
  L9_2 = L4_2 + L9_2
  L10_2 = L3_2.nGaugeFrontUDiff
  L10_2 = L5_2 + L10_2
  L11_2 = {}
  L11_2.x = L4_2
  L11_2.x2 = L9_2
  L11_2.nU1 = L5_2
  L11_2.nV1 = L6_2
  L11_2.nU2 = L10_2
  L11_2.nV2 = L8_2
  L13_2 = A0_2
  L12_2 = A0_2.SetAnimationPoint
  L14_2 = L3_2.nGaugeFrontDestPoint
  L15_2 = L11_2
  L12_2(L13_2, L14_2, L15_2)
  L13_2 = A0_2
  L12_2 = A0_2.AnimateToPoint
  L14_2 = L3_2.nGaugeFrontDestPoint
  L15_2 = A2_2
  L12_2(L13_2, L14_2, L15_2)
end

_AnimateToEnd = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = A0_2.CustomData
  L1_2.bPursuitActive = false
  L1_2 = A0_2.CustomData
  L2_2 = L1_2.oPursuit
  L4_2 = L2_2
  L3_2 = L2_2.AnimateToPoint
  L5_2 = L2_2.CustomData
  L5_2 = L5_2.nRedPoint
  L6_2 = 0
  L7_2 = true
  L3_2(L4_2, L5_2, L6_2, L7_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetVisible
  L5_2 = false
  L3_2(L4_2, L5_2)
  L1_2.fCallback = nil
  L1_2.tCallbackData = nil
  L1_2.nTotalTime = nil
  L4_2 = L2_2
  L3_2 = L2_2.SetClockAnimationCallback
  L5_2 = nil
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetClockAnimation
  L5_2 = 1
  L6_2 = 1
  L7_2 = false
  L8_2 = true
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  L3_2 = L1_2.oGaugeFront
  L4_2 = L3_2
  L3_2 = L3_2.SetColor
  L5_2 = 255
  L6_2 = 255
  L7_2 = 255
  L3_2(L4_2, L5_2, L6_2, L7_2)
  L3_2 = _SnapBarToValue
  L4_2 = A0_2
  L5_2 = L1_2.nCurrentValue
  L3_2(L4_2, L5_2)
  L4_2 = A0_2
  L3_2 = A0_2.SetValue
  L5_2 = L1_2.nCurrentMood
  L6_2 = true
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = L1_2.oMood
  L4_2 = L3_2
  L3_2 = L3_2.SetText
  L5_2 = _tLevelNames
  L6_2 = L1_2.nCurrentLevel
  L5_2 = L5_2[L6_2]
  L3_2(L4_2, L5_2)
end

StopPursuitGauge = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bPursuitActive
  return L1_2
end

IsPursuitActive = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oPursuit
  L3_2 = L1_2
  L2_2 = L1_2.GetClockElapsedTime
  L2_2 = L2_2(L3_2)
  L3_2 = L1_2.CustomData
  L3_2 = L3_2.nTotalTime
  if L3_2 and L2_2 then
    L3_2 = L1_2.CustomData
    L3_2 = L3_2.nTotalTime
    L3_2 = L3_2 - L2_2
    return L3_2
  end
  L3_2 = 0
  return L3_2
end

GetRemainingPursuitTime = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2
  L1_2 = A0_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nRedPoint
  L4_2 = 0.25
  L5_2 = true
  L6_2 = _LoopToBase
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

_LoopToRed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2
  L1_2 = A0_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nBasePoint
  L4_2 = 0.25
  L5_2 = true
  L6_2 = _LoopToRed
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

_LoopToBase = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oPursuit
  L2_2 = L1_2.CustomData
  L2_2 = L2_2.fCallback
  L3_2 = L1_2.CustomData
  L3_2 = L3_2.tCallbackData
  L4_2 = StopPursuitGauge
  L5_2 = A0_2
  L4_2(L5_2)
  L4_2 = type
  L5_2 = L2_2
  L4_2 = L4_2(L5_2)
  if "function" == L4_2 then
    L4_2 = type
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    if "table" ~= L4_2 then
      L4_2 = {}
      L3_2 = L4_2
    end
    L4_2 = L2_2
    L5_2 = unpack
    L6_2 = L3_2
    L5_2, L6_2 = L5_2(L6_2)
    L4_2(L5_2, L6_2)
  end
end

_PursuitAnimationComplete = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2
  if A1_2 then
    if A2_2 then
      L5_2 = A0_2
      L4_2 = A0_2._RealSetVisible
      L6_2 = true
      L4_2(L5_2, L6_2)
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.oIcon
      L5_2 = L4_2
      L4_2 = L4_2.SetVisible
      L6_2 = true
      L4_2(L5_2, L6_2)
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.oTimer
      L5_2 = L4_2
      L4_2 = L4_2.SetVisible
      L6_2 = true
      L4_2(L5_2, L6_2)
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.oPursuit
      L5_2 = L4_2
      L4_2 = L4_2.SetVisible
      L6_2 = false
      L4_2(L5_2, L6_2)
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.oMood
      L5_2 = L4_2
      L4_2 = L4_2.SetVisible
      L6_2 = false
      L4_2(L5_2, L6_2)
    elseif A3_2 then
      L5_2 = A0_2
      L4_2 = A0_2._RealSetVisible
      L6_2 = true
      L4_2(L5_2, L6_2)
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.oIcon
      L5_2 = L4_2
      L4_2 = L4_2.SetVisible
      L6_2 = true
      L4_2(L5_2, L6_2)
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.oTimer
      L5_2 = L4_2
      L4_2 = L4_2.SetVisible
      L6_2 = false
      L4_2(L5_2, L6_2)
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.oPursuit
      L5_2 = L4_2
      L4_2 = L4_2.SetVisible
      L6_2 = false
      L4_2(L5_2, L6_2)
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.oMood
      L5_2 = L4_2
      L4_2 = L4_2.SetVisible
      L6_2 = true
      L4_2(L5_2, L6_2)
    else
      L5_2 = A0_2
      L4_2 = A0_2._RealSetVisible
      L6_2 = true
      L4_2(L5_2, L6_2)
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.oPursuit
      L5_2 = L4_2
      L4_2 = L4_2.SetVisible
      L6_2 = false
      L4_2(L5_2, L6_2)
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.oTimer
      L5_2 = L4_2
      L4_2 = L4_2.IsActive
      L4_2 = L4_2(L5_2)
      if L4_2 then
        L4_2 = A0_2.CustomData
        L4_2 = L4_2.oTimer
        L5_2 = L4_2
        L4_2 = L4_2.SetVisible
        L6_2 = true
        L4_2(L5_2, L6_2)
        L4_2 = A0_2.CustomData
        L4_2 = L4_2.oMood
        L5_2 = L4_2
        L4_2 = L4_2.SetVisible
        L6_2 = false
        L4_2(L5_2, L6_2)
      else
        L4_2 = A0_2.CustomData
        L4_2 = L4_2.oTimer
        L5_2 = L4_2
        L4_2 = L4_2.SetVisible
        L6_2 = false
        L4_2(L5_2, L6_2)
        L4_2 = A0_2.CustomData
        L4_2 = L4_2.oMood
        L5_2 = L4_2
        L4_2 = L4_2.SetVisible
        L6_2 = true
        L4_2(L5_2, L6_2)
      end
    end
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.bPursuitActive
    if L4_2 then
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.oPursuit
      L5_2 = L4_2
      L4_2 = L4_2.SetVisible
      L6_2 = false
      L4_2(L5_2, L6_2)
    end
  else
    L5_2 = A0_2
    L4_2 = A0_2._RealSetVisible
    L6_2 = A1_2
    L4_2(L5_2, L6_2)
  end
end

_SetVisible = L0_1

function L0_1(A0_2, A1_2)
  if A0_2 < A1_2 then
    return A0_2
  end
  return A1_2
end

_Min = L0_1

function L0_1(A0_2, A1_2)
  if A1_2 < A0_2 then
    return A0_2
  end
  return A1_2
end

_Max = L0_1

function L0_1(A0_2, A1_2, A2_2)
  if A2_2 < A0_2 then
    A0_2 = A2_2
  end
  if A1_2 > A0_2 then
    A0_2 = A1_2
  end
  return A0_2
end

_Clamp = L0_1

function L0_1(A0_2)
  local L1_2
  if A0_2 < 0 then
    L1_2 = -1 * A0_2
    return L1_2
  end
  return A0_2
end

_Abs = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2)
  local L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L8_2 = A1_2
  L7_2 = A1_2.AnimateToPoint
  L9_2 = A2_2
  L10_2 = A3_2
  L11_2 = A4_2
  L12_2 = A5_2
  L13_2 = A6_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
end

_Animate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2.SetText
  L3_2 = "00:00:00"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.SetVisible
  L3_2 = false
  L1_2(L2_2, L3_2)
  L1_2 = A0_2.CustomData
  L1_2.nTime = 0
  L1_2 = A0_2.CustomData
  L1_2.bEnabled = false
  L1_2 = SetFactionTimerCallback
  A0_2.SetCallback = L1_2
  L1_2 = StartFactionTimer
  A0_2.Start = L1_2
  L1_2 = StopFactionTimer
  A0_2.Stop = L1_2
  L1_2 = IsActive
  A0_2.IsActive = L1_2
  L1_2 = _InitializeFactionTimer
  A0_2._Initialize = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.Stop
  L1_2(L2_2)
end

_InitializeFactionTimer = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  L3_2 = A0_2.CustomData
  L3_2.fCallback = A1_2
  L3_2 = type
  L4_2 = A2_2
  L3_2 = L3_2(L4_2)
  if "table" == L3_2 then
    L3_2 = A0_2.CustomData
    L3_2.tCallbackData = A2_2
  end
end

SetFactionTimerCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L3_2 = A0_2
  L2_2 = A0_2.SetEventHandler
  L4_2 = "GuiUpdate"
  L5_2 = _UpdateTimer
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = A0_2.CustomData
  L2_2.bEnabled = true
  L2_2 = A0_2.CustomData
  L2_2.nTime = A1_2
  L3_2 = A0_2
  L2_2 = A0_2.SetVisible
  L4_2 = true
  L2_2(L3_2, L4_2)
end

StartFactionTimer = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2.SetEventHandler
  L3_2 = "GuiUpdate"
  L4_2 = nil
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = A0_2.CustomData
  L1_2.bEnabled = false
  L2_2 = A0_2
  L1_2 = A0_2.SetVisible
  L3_2 = false
  L1_2(L2_2, L3_2)
end

StopFactionTimer = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = A0_2.CustomData
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nTime
  L3_2 = L3_2 - A1_2
  L2_2.nTime = L3_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nTime
  if L2_2 <= 0 then
    L3_2 = A0_2
    L2_2 = A0_2.Stop
    L2_2(L3_2)
    L3_2 = A0_2
    L2_2 = A0_2.SetText
    L4_2 = "00:00:00"
    L2_2(L3_2, L4_2)
    L2_2 = type
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.fCallback
    L2_2 = L2_2(L3_2)
    if "function" == L2_2 then
      L2_2 = {}
      L3_2 = type
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.tCallbackData
      L3_2 = L3_2(L4_2)
      if "table" == L3_2 then
        L3_2 = A0_2.CustomData
        L2_2 = L3_2.tCallbackData
      end
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.fCallback
      L4_2 = A0_2.CustomData
      L4_2.fCallback = nil
      L4_2 = A0_2.CustomData
      L4_2.tCallbackData = nil
      L4_2 = L3_2
      L5_2 = unpack
      L6_2 = L2_2
      L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L5_2(L6_2)
      L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
    end
    return
  end
  L2_2 = A0_2.CustomData
  A1_2 = L2_2.nTime
  L2_2 = Math
  L2_2 = L2_2.floor
  L3_2 = A1_2 / 60
  L2_2 = L2_2(L3_2)
  L3_2 = Math
  L3_2 = L3_2.floor
  L4_2 = L2_2 * 60
  L4_2 = A1_2 - L4_2
  L3_2 = L3_2(L4_2)
  L4_2 = Math
  L4_2 = L4_2.floor
  L5_2 = Math
  L5_2 = L5_2.floor
  L6_2 = A1_2
  L5_2 = L5_2(L6_2)
  L5_2 = A1_2 - L5_2
  L5_2 = L5_2 * 100
  L4_2 = L4_2(L5_2)
  if L2_2 < 10 then
    L5_2 = "0"
    L6_2 = L2_2
    L2_2 = L5_2 .. L6_2
  end
  if L3_2 < 10 then
    L5_2 = "0"
    L6_2 = L3_2
    L3_2 = L5_2 .. L6_2
  end
  if L4_2 < 10 then
    L5_2 = "0"
    L6_2 = L4_2
    L4_2 = L5_2 .. L6_2
  end
  L6_2 = A0_2
  L5_2 = A0_2.SetText
  L7_2 = L2_2
  L8_2 = ":"
  L9_2 = L3_2
  L10_2 = ":"
  L11_2 = L4_2
  L7_2 = L7_2 .. L8_2 .. L9_2 .. L10_2 .. L11_2
  L5_2(L6_2, L7_2)
end

_UpdateTimer = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bEnabled
  return L1_2
end

IsActive = L0_1
