local L0_1, L1_1
L0_1 = 0.4
_knPulseTime = L0_1
L0_1 = 0.1
_knPulseTimeFast = L0_1
L0_1 = 2
_knMoveTime = L0_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = 3
nVehicleNameTime = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L1_2 = A0_2.CustomData
  L1_2.nValue = 0
  L3_2 = A0_2
  L2_2 = A0_2.GetColor
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L6_2 = A0_2
  L5_2 = A0_2.AddAnimationPoint
  L7_2 = {}
  L7_2.RedLevel = L2_2
  L7_2.GreenLevel = L3_2
  L7_2.BlueLevel = L4_2
  L5_2 = L5_2(L6_2, L7_2)
  L1_2.nBasePoint = L5_2
  L6_2 = A0_2
  L5_2 = A0_2.AddAnimationPoint
  L7_2 = {}
  L7_2.GreenLevel = 0
  L7_2.BlueLevel = 0
  L5_2 = L5_2(L6_2, L7_2)
  L1_2.nRedPoint = L5_2
  L5_2 = _PulseRed
  A0_2.PulseRed = L5_2
  L5_2 = _PulseRedLoop
  A0_2.PulseRedLoop = L5_2
  L5_2 = _HaltPulse
  A0_2.HaltPulse = L5_2
  L5_2 = SetDisguiseLevel
  A0_2.SetDisguiseLevel = L5_2
  L5_2 = SetVehicleName
  A0_2.SetVehicleName = L5_2
  L6_2 = A0_2
  L5_2 = A0_2.GetChildren
  L5_2 = L5_2(L6_2)
  L6_2 = L5_2[3]
  L1_2.oIcon = L6_2
  L6_2 = L5_2[4]
  L1_2.oIconCross = L6_2
  L6_2 = L5_2[1]
  L1_2.oBarBack = L6_2
  L6_2 = L5_2[2]
  L1_2.oBarFront = L6_2
  L6_2 = L5_2[5]
  L1_2.oIdentifier = L6_2
  L6_2 = pairs
  L7_2 = L5_2
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  for L9_2, L10_2 in L6_2, L7_2, L8_2 do
    L11_2 = SetUpVisibilityManagement
    L12_2 = L10_2
    L11_2(L12_2)
  end
  L6_2 = L1_2.oBarFront
  L7_2 = L6_2
  L6_2 = L6_2.GetLocation
  L6_2, L7_2, L8_2, L9_2 = L6_2(L7_2)
  L10_2 = L1_2.oBarFront
  L11_2 = L10_2
  L10_2 = L10_2.GetTextureCoordinates
  L10_2, L11_2, L12_2, L13_2 = L10_2(L11_2)
  L1_2.nBarX = L6_2
  L14_2 = L8_2 - L6_2
  L1_2.nBarWidth = L14_2
  L1_2.nBarU = L10_2
  L14_2 = L12_2 - L10_2
  L1_2.nBarTexWidth = L14_2
  L14_2 = L1_2.oIcon
  L16_2 = L14_2
  L15_2 = L14_2.AddAnimationPoint
  L17_2 = {}
  L17_2.TranslucencyLevel = 0
  L15_2 = L15_2(L16_2, L17_2)
  L1_2.nIconFade = L15_2
  L16_2 = L14_2
  L15_2 = L14_2.AddAnimationPoint
  L17_2 = {}
  L17_2.TranslucencyLevel = 255
  L15_2 = L15_2(L16_2, L17_2)
  L1_2.nIconBase = L15_2
  L15_2 = L1_2.oIconCross
  L17_2 = L15_2
  L16_2 = L15_2.AddAnimationPoint
  L18_2 = {}
  L18_2.TranslucencyLevel = 0
  L16_2 = L16_2(L17_2, L18_2)
  L1_2.nIconCrossFade = L16_2
  L17_2 = L15_2
  L16_2 = L15_2.AddAnimationPoint
  L18_2 = {}
  L18_2.TranslucencyLevel = 255
  L16_2 = L16_2(L17_2, L18_2)
  L1_2.nIconCrossBase = L16_2
  L17_2 = A0_2
  L16_2 = A0_2.SetVisible
  L18_2 = false
  L16_2(L17_2, L18_2)
end

_Initialize = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = A0_2.CustomData
  L4_2 = L3_2.oIcon
  L5_2 = math
  L5_2 = L5_2.max
  L6_2 = math
  L6_2 = L6_2.min
  L7_2 = 100
  L8_2 = A1_2
  L6_2 = L6_2(L7_2, L8_2)
  L7_2 = 0
  L5_2 = L5_2(L6_2, L7_2)
  A1_2 = L5_2
  L3_2.bIsDisguised = A2_2
  L3_2.nNewDisguiseLevel = A1_2
end

SetDisguiseLevel = L0_1
L0_1 = 1
STATE_DISGUISED = L0_1
L0_1 = 2
STATE_UNDISGUISED = L0_1
L0_1 = 3
STATE_GAINING = L0_1
L0_1 = 4
STATE_LOSING = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L2_2 = A0_2.CustomData
  L3_2 = 0
  L4_2 = L2_2.bWasDisguised
  if L4_2 then
    L4_2 = L2_2.bIsDisguised
    L4_2 = not L4_2
  end
  L5_2 = L2_2.bIsDisguised
  L6_2 = 0.001
  L7_2 = math
  L7_2 = L7_2.abs
  L8_2 = L2_2.nLastDisguiseLevel
  L9_2 = L2_2.nNewDisguiseLevel
  L8_2 = L8_2 - L9_2
  L7_2 = L7_2(L8_2)
  L7_2 = L6_2 < L7_2
  if L7_2 then
    if L5_2 then
      L3_2 = STATE_LOSING
    else
      L3_2 = STATE_GAINING
    end
  elseif L5_2 then
    L3_2 = STATE_DISGUISED
  else
    L3_2 = STATE_UNDISGUISED
  end
  L8_2 = L2_2.oIdentifier
  L9_2 = L8_2
  L8_2 = L8_2.GetVisible
  L8_2 = L8_2(L9_2)
  if L8_2 then
    L8_2 = L2_2.nNewDisguiseLevel
    if L8_2 < 50 then
      L8_2 = L2_2.bIsDisguised
      if L8_2 then
        L8_2 = L2_2.oIdentifier
        L9_2 = L8_2
        L8_2 = L8_2.ChangeVisible
        L10_2 = false
        L8_2(L9_2, L10_2)
        L8_2 = L2_2.oIdentifier
        L8_2 = L8_2.CustomData
        L8_2.nVisibleTime = 0
    end
    else
      L8_2 = L2_2.oIdentifier
      L8_2 = L8_2.CustomData
      L9_2 = L2_2.oIdentifier
      L9_2 = L9_2.CustomData
      L9_2 = L9_2.nVisibleTime
      L9_2 = L9_2 - A1_2
      L8_2.nVisibleTime = L9_2
      L8_2 = L2_2.oIdentifier
      L8_2 = L8_2.CustomData
      L8_2 = L8_2.nVisibleTime
      if L8_2 <= 0 then
        L8_2 = L2_2.oIdentifier
        L9_2 = L8_2
        L8_2 = L8_2.ChangeVisible
        L10_2 = false
        L8_2(L9_2, L10_2)
      end
    end
  end
  L8_2 = L2_2.oIdentifier
  L8_2 = L8_2.CustomData
  L8_2 = L8_2.bVisible
  L8_2 = not L8_2
  L9_2 = STATE_DISGUISED
  if L9_2 == L3_2 then
    L9_2 = L2_2.oIcon
    L10_2 = L9_2
    L9_2 = L9_2.ChangeVisible
    L11_2 = true
    L9_2(L10_2, L11_2)
    L9_2 = L2_2.oIconCross
    L10_2 = L9_2
    L9_2 = L9_2.ChangeVisible
    L11_2 = false
    L9_2(L10_2, L11_2)
    L9_2 = L2_2.oBarFront
    L10_2 = L9_2
    L9_2 = L9_2.ChangeVisible
    L11_2 = false
    L9_2(L10_2, L11_2)
    L9_2 = L2_2.oBarBack
    L10_2 = L9_2
    L9_2 = L9_2.ChangeVisible
    L11_2 = false
    L9_2(L10_2, L11_2)
    L2_2.nIconTimeUntilHide = nil
  else
    L9_2 = STATE_UNDISGUISED
    if L9_2 == L3_2 then
      L9_2 = L2_2.oBarFront
      L10_2 = L9_2
      L9_2 = L9_2.ChangeVisible
      L11_2 = false
      L9_2(L10_2, L11_2)
      L9_2 = L2_2.oBarBack
      L10_2 = L9_2
      L9_2 = L9_2.ChangeVisible
      L11_2 = false
      L9_2(L10_2, L11_2)
      L9_2 = L2_2.nIconTimeUntilHide
      if not L9_2 then
        L9_2 = L2_2.oIcon
        L10_2 = L9_2
        L9_2 = L9_2.ChangeVisible
        L11_2 = true
        L9_2(L10_2, L11_2)
        L9_2 = L2_2.oIconCross
        L10_2 = L9_2
        L9_2 = L9_2.ChangeVisible
        L11_2 = true
        L9_2(L10_2, L11_2)
        L2_2.nIconTimeUntilHide = 1
      else
        L9_2 = L2_2.nIconTimeUntilHide
        if 0 < L9_2 then
          L9_2 = L2_2.nIconTimeUntilHide
          L9_2 = L9_2 - A1_2
          L2_2.nIconTimeUntilHide = L9_2
          L9_2 = L2_2.nIconTimeUntilHide
          if L9_2 <= 0 then
            L2_2.nIconTimeUntilHide = -1
            L9_2 = L2_2.oIcon
            L10_2 = L9_2
            L9_2 = L9_2.ChangeVisible
            L11_2 = false
            L9_2(L10_2, L11_2)
            L9_2 = L2_2.oIconCross
            L10_2 = L9_2
            L9_2 = L9_2.ChangeVisible
            L11_2 = false
            L9_2(L10_2, L11_2)
          end
        end
      end
    else
      L9_2 = STATE_GAINING
      if L9_2 == L3_2 then
        L9_2 = L2_2.oIcon
        L10_2 = L9_2
        L9_2 = L9_2.ChangeVisible
        L11_2 = true
        L9_2(L10_2, L11_2)
        L9_2 = L2_2.oIconCross
        L10_2 = L9_2
        L9_2 = L9_2.ChangeVisible
        L11_2 = true
        L9_2(L10_2, L11_2)
        L9_2 = L2_2.oBarFront
        L10_2 = L9_2
        L9_2 = L9_2.ChangeVisible
        L11_2 = L8_2
        L9_2(L10_2, L11_2)
        L9_2 = L2_2.oBarBack
        L10_2 = L9_2
        L9_2 = L9_2.ChangeVisible
        L11_2 = L8_2
        L9_2(L10_2, L11_2)
        L9_2 = L2_2.oBarFront
        L10_2 = L9_2
        L9_2 = L9_2.SetColor
        L11_2 = 255
        L12_2 = 102
        L13_2 = 102
        L9_2(L10_2, L11_2, L12_2, L13_2)
        L2_2.nIconTimeUntilHide = nil
      else
        L9_2 = STATE_LOSING
        if L9_2 == L3_2 then
          L9_2 = L2_2.oIcon
          L10_2 = L9_2
          L9_2 = L9_2.ChangeVisible
          L11_2 = true
          L9_2(L10_2, L11_2)
          L9_2 = L2_2.oIconCross
          L10_2 = L9_2
          L9_2 = L9_2.ChangeVisible
          L11_2 = false
          L9_2(L10_2, L11_2)
          L9_2 = L2_2.oBarFront
          L10_2 = L9_2
          L9_2 = L9_2.ChangeVisible
          L11_2 = L8_2
          L9_2(L10_2, L11_2)
          L9_2 = L2_2.oBarBack
          L10_2 = L9_2
          L9_2 = L9_2.ChangeVisible
          L11_2 = L8_2
          L9_2(L10_2, L11_2)
          L9_2 = L2_2.oBarFront
          L10_2 = L9_2
          L9_2 = L9_2.SetColor
          L11_2 = 200
          L12_2 = 255
          L13_2 = 200
          L9_2(L10_2, L11_2, L12_2, L13_2)
          L2_2.nIconTimeUntilHide = nil
        end
      end
    end
  end
  L9_2 = L2_2.oBarFront
  L11_2 = L9_2
  L10_2 = L9_2.SetLocation
  L12_2 = L2_2.nBarX
  L13_2 = nil
  L14_2 = L2_2.nBarX
  L15_2 = L2_2.nBarWidth
  L16_2 = L2_2.nLastDisguiseLevel
  L16_2 = L16_2 / 100
  L15_2 = L15_2 * L16_2
  L14_2 = L14_2 + L15_2
  L10_2(L11_2, L12_2, L13_2, L14_2)
  L11_2 = L9_2
  L10_2 = L9_2.SetTextureCoordinates
  L12_2 = L2_2.nBarU
  L13_2 = nil
  L14_2 = L2_2.nBarU
  L15_2 = L2_2.nBarTexWidth
  L16_2 = L2_2.nLastDisguiseLevel
  L16_2 = L16_2 / 100
  L15_2 = L15_2 * L16_2
  L14_2 = L14_2 + L15_2
  L10_2(L11_2, L12_2, L13_2, L14_2)
  L10_2 = L2_2.bIsDisguised
  L2_2.bWasDisguised = L10_2
  L10_2 = L2_2.nNewDisguiseLevel
  L2_2.nLastDisguiseLevel = L10_2
  L10_2 = L2_2.oIcon
  L11_2 = L10_2
  L10_2 = L10_2.SetVisible
  L12_2 = Player
  L12_2 = L12_2.GetVehicleDisguise
  L12_2, L13_2, L14_2, L15_2, L16_2 = L12_2()
  L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
  L10_2 = L2_2.oIconCross
  L11_2 = L10_2
  L10_2 = L10_2.SetVisible
  L12_2 = Player
  L12_2 = L12_2.GetVehicleDisguise
  L12_2, L13_2, L14_2, L15_2, L16_2 = L12_2()
  L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
  L10_2 = L2_2.oBarFront
  L11_2 = L10_2
  L10_2 = L10_2.SetVisible
  L12_2 = Player
  L12_2 = L12_2.GetVehicleDisguise
  L12_2, L13_2, L14_2, L15_2, L16_2 = L12_2()
  L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
  L10_2 = L2_2.oBarBack
  L11_2 = L10_2
  L10_2 = L10_2.SetVisible
  L12_2 = Player
  L12_2 = L12_2.GetVehicleDisguise
  L12_2, L13_2, L14_2, L15_2, L16_2 = L12_2()
  L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
end

DisguiseUpdate = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  if not A2_2 then
    L4_2 = "temp_radar_icon_pmc"
  else
    L5_2 = _tFactionTextures
    L4_2 = L5_2[A2_2]
  end
  if not L4_2 then
    L4_2 = "temp_radar_icon_pmc"
  end
  if not A1_2 then
    L6_2 = A0_2
    L5_2 = A0_2.SetVisible
    L7_2 = false
    L5_2(L6_2, L7_2)
    L5_2 = pairs
    L7_2 = A0_2
    L6_2 = A0_2.GetChildren
    L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L6_2(L7_2)
    L5_2, L6_2, L7_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
    for L8_2, L9_2 in L5_2, L6_2, L7_2 do
      L11_2 = L9_2
      L10_2 = L9_2.ChangeVisible
      L12_2 = false
      L10_2(L11_2, L12_2)
    end
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.oIdentifier
    L6_2 = L5_2
    L5_2 = L5_2.Set
    L7_2 = nil
    L5_2(L6_2, L7_2)
    L5_2 = A0_2.CustomData
    L5_2.nLastDisguiseLevel = nil
    L5_2 = A0_2.CustomData
    L5_2.bWasDisguised = nil
    L5_2 = A0_2.CustomData
    L5_2.bPulsing = false
    L6_2 = A0_2
    L5_2 = A0_2.SetEventHandler
    L7_2 = "GuiUpdate"
    L8_2 = nil
    L5_2(L6_2, L7_2, L8_2)
  else
    L6_2 = A0_2
    L5_2 = A0_2.SetVisible
    L7_2 = true
    L5_2(L6_2, L7_2)
    L5_2 = pairs
    L7_2 = A0_2
    L6_2 = A0_2.GetChildren
    L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L6_2(L7_2)
    L5_2, L6_2, L7_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
    for L8_2, L9_2 in L5_2, L6_2, L7_2 do
      L11_2 = L9_2
      L10_2 = L9_2.ChangeVisible
      L12_2 = false
      L13_2 = true
      L10_2(L11_2, L12_2, L13_2)
      L11_2 = L9_2
      L10_2 = L9_2.SetVisible
      L12_2 = Player
      L12_2 = L12_2.GetVehicleDisguise
      L12_2, L13_2 = L12_2()
      L10_2(L11_2, L12_2, L13_2)
    end
    L6_2 = A0_2
    L5_2 = A0_2.SetEventHandler
    L7_2 = "GuiUpdate"
    L8_2 = DisguiseUpdate
    L5_2(L6_2, L7_2, L8_2)
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.oIdentifier
    L6_2 = L5_2
    L5_2 = L5_2.Set
    L7_2 = A1_2
    L5_2(L6_2, L7_2)
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.oIdentifier
    L6_2 = L5_2
    L5_2 = L5_2.ChangeVisible
    L7_2 = true
    L5_2(L6_2, L7_2)
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.oIdentifier
    L6_2 = L5_2
    L5_2 = L5_2.SetVisible
    L7_2 = true
    L5_2(L6_2, L7_2)
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.oIcon
    L6_2 = L5_2
    L5_2 = L5_2.SetTexture
    L7_2 = L4_2
    L5_2(L6_2, L7_2)
    L5_2 = A0_2.CustomData
    L6_2 = A0_2.CustomData
    L6_2.nLastDisguiseLevel = 0
    L6_2 = A0_2.CustomData
    L6_2.nNewDisguiseLevel = 0
    L6_2 = A0_2.CustomData
    L6_2.bWasDisguised = false
    L6_2 = A0_2.CustomData
    L6_2.bIsDisguised = false
    L6_2 = A0_2.CustomData
    L6_2.bPulsing = false
  end
end

SetVehicleName = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L4_2 = A0_2
  L3_2 = A0_2.SetVehicleName
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
end

HandleVehicleNameUpdate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2
  L1_2 = A0_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nRedPoint
  L4_2 = 0
  L5_2 = true
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L2_2 = A0_2
  L1_2 = A0_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nRedPoint
  L4_2 = _knPulseTime
  L5_2 = false
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bPulse
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.AnimateToPoint
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.nBasePoint
    L4_2 = _knPulseTime
    L5_2 = false
    L6_2 = _PulseRedLoopLow
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  else
    L2_2 = A0_2
    L1_2 = A0_2.AnimateToPoint
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.nBasePoint
    L4_2 = _knPulseTime
    L4_2 = L4_2 * 2
    L5_2 = false
    L1_2(L2_2, L3_2, L4_2, L5_2)
  end
end

_PulseRed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = A0_2.CustomData
  L1_2.bPulse = true
  L2_2 = A0_2
  L1_2 = A0_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nRedPoint
  L4_2 = _knPulseTime
  L5_2 = false
  L6_2 = _PulseRedLoopHigh
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

_PulseRedLoop = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = _knPulseTime
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nLastDisguiseLevel
  if L2_2 then
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.nLastDisguiseLevel
    if L2_2 < 25 then
      L1_2 = _knPulseTimeFast
    end
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bPulse
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.AnimateToPoint
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.nRedPoint
    L5_2 = L1_2
    L6_2 = true
    L7_2 = _PulseRedLoopHigh
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  end
end

_PulseRedLoopLow = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = _knPulseTime
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nLastDisguiseLevel
  if L2_2 then
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.nLastDisguiseLevel
    if L2_2 < 25 then
      L1_2 = _knPulseTimeFast
    end
  end
  L3_2 = A0_2
  L2_2 = A0_2.AnimateToPoint
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nBasePoint
  L5_2 = L1_2
  L6_2 = true
  L7_2 = _PulseRedLoopLow
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

_PulseRedLoopHigh = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2.CustomData
  L2_2.bPulse = false
  if A1_2 then
    L3_2 = A0_2
    L2_2 = A0_2.AnimateToPoint
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.nBasePoint
    L5_2 = 0
    L6_2 = true
    L2_2(L3_2, L4_2, L5_2, L6_2)
  end
end

_HaltPulse = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L4_2 = A0_2
  L3_2 = A0_2.SetVehicleName
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
end

_HandleVehicleChange = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L4_2 = A0_2
  L3_2 = A0_2.SetDisguiseLevel
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
end

HandleDisguiseUpdate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = A0_2.CustomData
  L3_2 = A0_2
  L2_2 = A0_2.AddAnimationPoint
  L4_2 = {}
  L4_2.TranslucencyLevel = 255
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.nVisiblePoint = L2_2
  L1_2 = A0_2.CustomData
  L3_2 = A0_2
  L2_2 = A0_2.AddAnimationPoint
  L4_2 = {}
  L4_2.TranslucencyLevel = 0
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.nInvisiblePoint = L2_2
  L1_2 = A0_2.CustomData
  L1_2.bVisible = true
  L1_2 = ChangeVisibility
  A0_2.ChangeVisible = L1_2
end

SetUpVisibilityManagement = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.bVisible
  if A1_2 ~= L3_2 or A2_2 then
    L3_2 = 0.25
    if A2_2 then
      L3_2 = 0
    end
    if A1_2 then
      L5_2 = A0_2
      L4_2 = A0_2.AnimateToPoint
      L6_2 = A0_2.CustomData
      L6_2 = L6_2.nVisiblePoint
      L7_2 = L3_2
      L8_2 = true
      L4_2(L5_2, L6_2, L7_2, L8_2)
    else
      L5_2 = A0_2
      L4_2 = A0_2.AnimateToPoint
      L6_2 = A0_2.CustomData
      L6_2 = L6_2.nInvisiblePoint
      L7_2 = L3_2
      L8_2 = true
      L4_2(L5_2, L6_2, L7_2, L8_2)
    end
    L4_2 = A0_2.CustomData
    L4_2.bVisible = A1_2
  end
end

ChangeVisibility = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2.SetVisible
  L3_2 = false
  L1_2(L2_2, L3_2)
  L1_2 = A0_2.CustomData
  L3_2 = A0_2
  L2_2 = A0_2.AddAnimationPoint
  L4_2 = {}
  L4_2.TranslucencyLevel = 255
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.nBasePoint = L2_2
  L3_2 = A0_2
  L2_2 = A0_2.AddAnimationPoint
  L4_2 = {}
  L4_2.TranslucencyLevel = 0
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.nFadePoint = L2_2
  L2_2 = SetIdentifier
  A0_2.Set = L2_2
end

_InitIdentifier = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2.CustomData
  if not A1_2 then
    L4_2 = A0_2
    L3_2 = A0_2.SetVisible
    L5_2 = false
    L3_2(L4_2, L5_2)
    L4_2 = A0_2
    L3_2 = A0_2.SetText
    L5_2 = " "
    L3_2(L4_2, L5_2)
    L4_2 = A0_2
    L3_2 = A0_2.ChangeVisible
    L5_2 = false
    L6_2 = true
    L3_2(L4_2, L5_2, L6_2)
  else
    L4_2 = A0_2
    L3_2 = A0_2.SetText
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
    L4_2 = A0_2
    L3_2 = A0_2.SetVisible
    L5_2 = true
    L3_2(L4_2, L5_2)
    L4_2 = A0_2
    L3_2 = A0_2.ChangeVisible
    L5_2 = true
    L3_2(L4_2, L5_2)
    L3_2 = A0_2.CustomData
    L4_2 = nVehicleNameTime
    L3_2.nVisibleTime = L4_2
  end
end

SetIdentifier = L0_1
L0_1 = false
_tFactionTextures = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = {}
  _tFactionTextures = L0_2
  L0_2 = StringToGuid
  L1_2 = "0xbbc34ef4"
  L0_2 = L0_2(L1_2)
  L1_2 = StringToGuid
  L2_2 = "0x41359cce"
  L1_2 = L1_2(L2_2)
  L2_2 = StringToGuid
  L3_2 = "0xe947b797"
  L2_2 = L2_2(L3_2)
  L3_2 = StringToGuid
  L4_2 = "0xb10d73ce"
  L3_2 = L3_2(L4_2)
  L4_2 = StringToGuid
  L5_2 = "0xc18215fe"
  L4_2 = L4_2(L5_2)
  L5_2 = StringToGuid
  L6_2 = "0x30e4a26f"
  L5_2 = L5_2(L6_2)
  L6_2 = StringToGuid
  L7_2 = "0xdcc8b14d"
  L6_2 = L6_2(L7_2)
  L7_2 = StringToGuid
  L8_2 = "0xb4420059"
  L7_2 = L7_2(L8_2)
  L8_2 = _tFactionTextures
  L8_2[L0_2] = "HUD_faction_AN"
  L8_2 = _tFactionTextures
  L8_2[L1_2] = "HUD_faction_CH"
  L8_2 = _tFactionTextures
  L8_2[L2_2] = "HUD_faction_OC"
  L8_2 = _tFactionTextures
  L8_2[L3_2] = "HUD_faction_GR"
  L8_2 = _tFactionTextures
  L8_2[L4_2] = "HUD_faction_PR"
  L8_2 = _tFactionTextures
  L8_2[L6_2] = "HUD_faction_CV"
  L8_2 = _tFactionTextures
  L8_2[L7_2] = "HUD_faction_VZ"
  L8_2 = _tFactionTextures
  L8_2[L5_2] = "HUD_faction_PMC"
end

Init = L0_1
