local L0_1, L1_1, L2_1, L3_1, L4_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = false
_bFloatCrosshair = L0_1
L0_1 = "ui_HUD_SAM_targeting"
_ksTargettingSound = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2)
  local L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  if A1_2 then
    if 0 < A1_2 then
      L9_2 = A0_2
      L8_2 = A0_2.SetColor
      L10_2 = 0
      L11_2 = 0
      L12_2 = 255
      L8_2(L9_2, L10_2, L11_2, L12_2)
      L8_2 = A0_2.ParentWidget
      L9_2 = L8_2
      L8_2 = L8_2.SetColor
      L10_2 = 0
      L11_2 = 0
      L12_2 = 255
      L13_2 = nil
      L14_2 = true
      L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
    elseif A1_2 < 0 then
      L9_2 = A0_2
      L8_2 = A0_2.SetColor
      L10_2 = 255
      L11_2 = 0
      L12_2 = 0
      L8_2(L9_2, L10_2, L11_2, L12_2)
      L8_2 = A0_2.ParentWidget
      L9_2 = L8_2
      L8_2 = L8_2.SetColor
      L10_2 = 255
      L11_2 = 0
      L12_2 = 0
      L13_2 = nil
      L14_2 = true
      L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
    else
      L9_2 = A0_2
      L8_2 = A0_2.SetColor
      L10_2 = 255
      L11_2 = 255
      L12_2 = 255
      L8_2(L9_2, L10_2, L11_2, L12_2)
      L8_2 = A0_2.ParentWidget
      L9_2 = L8_2
      L8_2 = L8_2.SetColor
      L10_2 = 255
      L11_2 = 255
      L12_2 = 255
      L13_2 = nil
      L14_2 = true
      L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
    end
  else
    L9_2 = A0_2
    L8_2 = A0_2.SetColor
    L10_2 = 255
    L11_2 = 255
    L12_2 = 255
    L8_2(L9_2, L10_2, L11_2, L12_2)
    L8_2 = A0_2.ParentWidget
    L9_2 = L8_2
    L8_2 = L8_2.SetColor
    L10_2 = 255
    L11_2 = 255
    L12_2 = 255
    L13_2 = nil
    L14_2 = true
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  end
  L8_2 = Gui
  L8_2 = L8_2.GetReticlePosition
  L10_2 = A0_2
  L9_2 = A0_2.GetOwner
  L9_2, L10_2, L11_2, L12_2, L13_2, L14_2 = L9_2(L10_2)
  L8_2, L9_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L10_2 = _bFloatCrosshair
  if L10_2 then
    L10_2 = A0_2.CustomData
    L11_2 = A2_2 or L11_2
    if not A2_2 then
      L11_2 = L8_2
    end
    L10_2.nSetCenterX = L11_2
    L10_2 = A0_2.CustomData
    L11_2 = A3_2 or L11_2
    if not A3_2 then
      L11_2 = L9_2
    end
    L10_2.nSetCenterY = L11_2
  else
    L10_2 = A0_2.CustomData
    L10_2.nSetCenterX = L8_2
    L10_2 = A0_2.CustomData
    L10_2.nSetCenterY = L9_2
  end
  L10_2 = A0_2.CustomData
  L11_2 = A4_2 or L11_2
  if not A4_2 then
    L11_2 = 0
  end
  L10_2.nSetSpreadX = L11_2
  L10_2 = A0_2.CustomData
  L11_2 = A5_2 or L11_2
  if not A5_2 then
    L11_2 = 0
  end
  L10_2.nSetSpreadY = L11_2
  L10_2 = type
  L11_2 = A6_2
  L10_2 = L10_2(L11_2)
  if "number" ~= L10_2 then
    A6_2 = -1
  end
  L10_2 = type
  L11_2 = A7_2
  L10_2 = L10_2(L11_2)
  if "number" ~= L10_2 then
    A7_2 = -1
  end
  L10_2 = A0_2.CustomData
  L10_2 = L10_2.oHealth
  L11_2 = L10_2
  L10_2 = L10_2.SetHealth
  L12_2 = A6_2
  L13_2 = A7_2
  L10_2(L11_2, L12_2, L13_2)
  L10_2 = A0_2.CustomData
  L10_2.nCurHealth = A6_2
  L10_2 = A0_2.CustomData
  L10_2.nMaxHealth = A7_2
end

HandleReticleColorChangeEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = type
  L3_2 = A1_2.sReticleType
  L2_2 = L2_2(L3_2)
  if "string" ~= L2_2 then
    return
  end
  L2_2 = A1_2.sReticleType
  if "Homing" == L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.SetVisible
    L4_2 = false
    L2_2(L3_2, L4_2)
  else
    L2_2 = A1_2.sReticleType
    if "Normal" == L2_2 then
      L3_2 = A0_2
      L2_2 = A0_2.SetVisible
      L4_2 = true
      L2_2(L3_2, L4_2)
      L2_2 = A1_2.uReticleTexture
      if L2_2 then
        L3_2 = A0_2
        L2_2 = A0_2.SetTexture
        L4_2 = A1_2.uReticleTexture
        L2_2(L3_2, L4_2)
      end
      L2_2 = A0_2.CustomData
      L2_2 = L2_2.oCrosshair
      if not L2_2 then
        L2_2 = A0_2.CustomData
        L4_2 = A0_2
        L3_2 = A0_2.GetChildren
        L3_2 = L3_2(L4_2)
        L3_2 = L3_2[2]
        L2_2.oCrosshair = L3_2
      end
      L2_2 = A1_2.bReticleCrosshair
      if nil ~= L2_2 then
        L2_2 = A0_2.CustomData
        L2_2 = L2_2.oCrosshair
        L3_2 = L2_2
        L2_2 = L2_2.SetVisible
        L4_2 = A1_2.bReticleCrosshair
        L2_2(L3_2, L4_2)
      end
      L2_2 = A1_2.sReticleHealthType
      if L2_2 then
        L2_2 = A0_2.CustomData
        L2_2 = L2_2.oCrosshair
        L3_2 = A1_2.sReticleHealthType
        if "straight (bottom)" == L3_2 then
          L3_2 = L2_2.CustomData
          L3_2 = L3_2.oHealthCurve
          L4_2 = L3_2
          L3_2 = L3_2.Hide
          L3_2(L4_2)
          L3_2 = L2_2.CustomData
          L4_2 = L2_2.CustomData
          L4_2 = L4_2.oHealthStraight
          L3_2.oHealth = L4_2
        else
          L3_2 = L2_2.CustomData
          L3_2 = L3_2.oHealthStraight
          L4_2 = L3_2
          L3_2 = L3_2.Hide
          L3_2(L4_2)
          L3_2 = L2_2.CustomData
          L4_2 = L2_2.CustomData
          L4_2 = L4_2.oHealthCurve
          L3_2.oHealth = L4_2
        end
        L3_2 = L2_2.CustomData
        L3_2 = L3_2.oHealth
        L4_2 = L3_2
        L3_2 = L3_2.SetHealth
        L5_2 = L2_2.CustomData
        L5_2 = L5_2.nCurHealth
        L6_2 = L2_2.CustomData
        L6_2 = L6_2.nMaxHealth
        L3_2(L4_2, L5_2, L6_2)
      end
    else
      L2_2 = A1_2.sReticleType
      if "None" == L2_2 then
        L3_2 = A0_2
        L2_2 = A0_2.SetVisible
        L4_2 = false
        L2_2(L3_2, L4_2)
      end
    end
  end
end

HandleReticleGunSwitchEvent = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Gui
  L1_2 = L1_2.GetReticlePosition
  L3_2 = A0_2
  L2_2 = A0_2.GetOwner
  L2_2, L3_2, L4_2, L5_2, L6_2 = L2_2(L3_2)
  L1_2, L2_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L3_2 = _MoveReticle
  L4_2 = A0_2
  L5_2 = L1_2
  L6_2 = L2_2
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = SetReticleOwner
  A0_2.SetOwner = L3_2
  L3_2 = A0_2.CustomData
  L3_2.nSpreadX = 0
  L3_2 = A0_2.CustomData
  L3_2.nSpreadY = 0
  L4_2 = A0_2
  L3_2 = A0_2.SetEventHandler
  L5_2 = "GuiReticlePositionChange"
  L6_2 = HandleReticlePositionChange
  L3_2(L4_2, L5_2, L6_2)
end

HandleReticleInitialization = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L4_2 = A1_2.nX
  if L4_2 then
    L4_2 = A1_2.nY
    if L4_2 then
      L2_2 = A1_2.nX
      L3_2 = A1_2.nY
  end
  else
    L4_2 = Gui
    L4_2 = L4_2.GetReticlePosition
    L6_2 = A0_2
    L5_2 = A0_2.GetOwner
    L5_2, L6_2, L7_2 = L5_2(L6_2)
    L4_2, L5_2 = L4_2(L5_2, L6_2, L7_2)
    L3_2 = L5_2
    L2_2 = L4_2
  end
  L4_2 = _MoveReticle
  L5_2 = A0_2
  L6_2 = L2_2
  L7_2 = L3_2
  L4_2(L5_2, L6_2, L7_2)
end

HandleReticlePositionChange = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L4_2 = A0_2
  L3_2 = A0_2.GetLocation
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  L7_2 = A1_2 * 320
  L7_2 = 320 + L7_2
  L8_2 = A2_2 * 240
  L8_2 = 240 - L8_2
  L9_2 = L5_2 - L3_2
  L10_2 = L6_2 - L4_2
  L12_2 = A0_2
  L11_2 = A0_2.SetLocation
  L13_2 = L9_2 / 2
  L13_2 = L7_2 - L13_2
  L14_2 = L10_2 / 2
  L14_2 = L8_2 - L14_2
  L11_2(L12_2, L13_2, L14_2)
end

_MoveReticle = L0_1
L0_1 = {}
L1_1 = {}
L1_1.nXS = 0
L1_1.nYS = -1
L2_1 = {}
L2_1.nXS = 1
L2_1.nYS = 0
L3_1 = {}
L3_1.nXS = 0
L3_1.nYS = 1
L4_1 = {}
L4_1.nXS = -1
L4_1.nYS = 0
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L2_2 = A0_2
  L1_2 = A0_2.GetLocation
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  L5_2 = L1_2 + L3_2
  L5_2 = L5_2 * 0.5
  L6_2 = L2_2 + L4_2
  L6_2 = L6_2 * 0.5
  L7_2 = {}
  L9_2 = A0_2
  L8_2 = A0_2.GetChildren
  L8_2 = L8_2(L9_2)
  L9_2 = pairs
  L10_2 = L8_2
  L9_2, L10_2, L11_2 = L9_2(L10_2)
  for L12_2, L13_2 in L9_2, L10_2, L11_2 do
    L15_2 = L13_2
    L14_2 = L13_2.GetLocation
    L14_2, L15_2, L16_2, L17_2 = L14_2(L15_2)
    L18_2 = {}
    L19_2 = L14_2 - L5_2
    L18_2.nX1 = L19_2
    L19_2 = L15_2 - L6_2
    L18_2.nY1 = L19_2
    L19_2 = L16_2 - L5_2
    L18_2.nX2 = L19_2
    L19_2 = L17_2 - L6_2
    L18_2.nY2 = L19_2
    L19_2 = L0_1
    L19_2 = L19_2[L12_2]
    L19_2 = L19_2.nXS
    L19_2 = L19_2 * 320
    L18_2.nXS = L19_2
    L19_2 = L0_1
    L19_2 = L19_2[L12_2]
    L19_2 = L19_2.nYS
    L19_2 = L19_2 * 320
    L18_2.nYS = L19_2
    L7_2[L12_2] = L18_2
  end
  L9_2 = A0_2.CustomData
  L9_2.tChildren = L8_2
  L9_2 = A0_2.CustomData
  L9_2.tOffsets = L7_2
  L9_2 = A0_2.ParentWidget
  L10_2 = L9_2
  L9_2 = L9_2.GetChildren
  L9_2 = L9_2(L10_2)
  L10_2 = A0_2.CustomData
  L11_2 = L9_2[1]
  L10_2.oHealthCurve = L11_2
  L10_2 = A0_2.CustomData
  L11_2 = L9_2[3]
  L10_2.oHealthStraight = L11_2
  L10_2 = A0_2.CustomData
  L11_2 = L9_2[1]
  L10_2.oHealth = L11_2
  L10_2 = A0_2.CustomData
  L10_2 = L10_2.oHealthStraight
  L11_2 = L10_2
  L10_2 = L10_2.SetVisible
  L12_2 = false
  L10_2(L11_2, L12_2)
  L10_2 = A0_2.CustomData
  L10_2.nCurHealth = 0
  L10_2 = A0_2.CustomData
  L10_2.nMaxHealth = 0
  L10_2 = A0_2.EventHandlers
  L10_2 = L10_2.GuiUpdate
  if not L10_2 then
    L11_2 = A0_2
    L10_2 = A0_2.SetEventHandler
    L12_2 = "GuiUpdate"
    L13_2 = HandleCrosshairUpdate
    L10_2(L11_2, L12_2, L13_2)
  end
  L10_2 = Gui
  L10_2 = L10_2.GetReticlePosition
  L12_2 = A0_2
  L11_2 = A0_2.GetOwner
  L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2 = L11_2(L12_2)
  L10_2, L11_2 = L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
  L12_2 = A0_2.CustomData
  L12_2.nSetCenterX = L10_2
  L12_2 = A0_2.CustomData
  L12_2.nCurCenterX = L10_2
  L12_2 = A0_2.CustomData
  L12_2.nSetCenterY = L11_2
  L12_2 = A0_2.CustomData
  L12_2.nCurCenterY = L11_2
  L12_2 = A0_2.CustomData
  L12_2.nSetSpreadX = 0
  L12_2 = A0_2.CustomData
  L12_2.nCurSpreadX = 0
  L12_2 = A0_2.CustomData
  L12_2.nSetSpreadY = 0
  L12_2 = A0_2.CustomData
  L12_2.nCurSpreadY = 0
end

HandleCrosshairInitialization = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2)
end

_MoveCrosshairChildToPoint = L1_1

function L1_1(A0_2, A1_2, A2_2)
  local L3_2
  if A2_2 <= 0 then
    return A0_2
  end
  if 1 <= A2_2 then
    return A1_2
  end
  L3_2 = A1_2 - A0_2
  L3_2 = L3_2 * A2_2
  L3_2 = A0_2 + L3_2
  return L3_2
end

Interpolate = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L2_2 = A0_2.CustomData
  L3_2 = Interpolate
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nCurCenterX
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nSetCenterX
  L6_2 = A1_2 * 5
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L2_2.nCurCenterX = L3_2
  L2_2 = A0_2.CustomData
  L3_2 = Interpolate
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nCurCenterY
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nSetCenterY
  L6_2 = A1_2 * 5
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L2_2.nCurCenterY = L3_2
  L2_2 = A0_2.CustomData
  L3_2 = Interpolate
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nCurSpreadX
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nSetSpreadX
  L6_2 = A1_2 * 5
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L2_2.nCurSpreadX = L3_2
  L2_2 = A0_2.CustomData
  L3_2 = Interpolate
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nCurSpreadY
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nSetSpreadY
  L6_2 = A1_2 * 5
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L2_2.nCurSpreadY = L3_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nCurCenterX
  L2_2 = 320 * L2_2
  L2_2 = 320 + L2_2
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nCurCenterY
  L3_2 = 240 * L3_2
  L3_2 = 240 - L3_2
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nCurSpreadX
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nCurSpreadY
  L6_2 = ipairs
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.tChildren
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  for L9_2, L10_2 in L6_2, L7_2, L8_2 do
    L11_2 = A0_2.CustomData
    L11_2 = L11_2.tOffsets
    L11_2 = L11_2[L9_2]
    L13_2 = L10_2
    L12_2 = L10_2.SetLocation
    L14_2 = L11_2.nX1
    L14_2 = L2_2 + L14_2
    L15_2 = L11_2.nXS
    L15_2 = L15_2 * L4_2
    L14_2 = L14_2 + L15_2
    L15_2 = L11_2.nY1
    L15_2 = L3_2 + L15_2
    L16_2 = L11_2.nYS
    L16_2 = L16_2 * L5_2
    L15_2 = L15_2 + L16_2
    L12_2(L13_2, L14_2, L15_2)
  end
end

HandleCrosshairUpdate = L1_1
L1_1 = 100
_nHealthLength = L1_1
L1_1 = _nHealthLength
L1_1 = L1_1 / 2
_nHalfHealthLength = L1_1
L1_1 = 180
_nHealthCenter = L1_1
L1_1 = 80
_nBaseAlpha = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L1_2 = L1_2[1]
  L2_2 = A0_2.CustomData
  L2_2.oHealth = L1_2
  L3_2 = A0_2
  L2_2 = A0_2.SetPieSliceRender
  L4_2 = _nHealthCenter
  L5_2 = _nHalfHealthLength
  L4_2 = L4_2 - L5_2
  L4_2 = L4_2 - 2
  L5_2 = _nHealthCenter
  L6_2 = _nHalfHealthLength
  L5_2 = L5_2 + L6_2
  L5_2 = L5_2 + 2
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetPieSliceRender
  L4_2 = _nHealthCenter
  L5_2 = _nHalfHealthLength
  L4_2 = L4_2 - L5_2
  L5_2 = _nHealthCenter
  L6_2 = _nHalfHealthLength
  L5_2 = L5_2 + L6_2
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = _SetHealth
  A0_2.SetHealth = L2_2
  L2_2 = _ForceHideHealth
  A0_2.Hide = L2_2
  L2_2 = A0_2.CustomData
  L4_2 = A0_2
  L3_2 = A0_2.AddAnimationPoint
  L5_2 = {}
  L5_2.TranslucencyLevel = 0
  L3_2 = L3_2(L4_2, L5_2)
  L2_2.nFadedPoint = L3_2
  L2_2 = A0_2.CustomData
  L4_2 = A0_2
  L3_2 = A0_2.AddAnimationPoint
  L5_2 = {}
  L6_2 = _nBaseAlpha
  L5_2.TranslucencyLevel = L6_2
  L3_2 = L3_2(L4_2, L5_2)
  L2_2.nVisiblePoint = L3_2
end

HandleHealthInitialization = L1_1

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  if 0 <= A1_2 and 0 < A2_2 then
    L4_2 = A0_2
    L3_2 = A0_2.IsAnimating
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L3_2 = A0_2.CustomData
      L3_2.bFadingIn = true
      L4_2 = A0_2
      L3_2 = A0_2.AnimateToPoint
      L5_2 = A0_2.CustomData
      L5_2 = L5_2.nVisiblePoint
      L6_2 = 0
      L7_2 = true
      L8_2 = _HealthFadeInEnd
      L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
    else
      L4_2 = A0_2
      L3_2 = A0_2.SetTranslucency
      L5_2 = _nBaseAlpha
      L3_2(L4_2, L5_2)
    end
    L3_2 = math
    L3_2 = L3_2.min
    L4_2 = A1_2
    L5_2 = A2_2
    L3_2 = L3_2(L4_2, L5_2)
    A1_2 = L3_2
    L3_2 = A1_2 / A2_2
    L4_2 = _nHealthLength
    L4_2 = L4_2 * L3_2
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.oHealth
    L6_2 = L5_2
    L5_2 = L5_2.SetPieSliceRender
    L7_2 = _nHealthCenter
    L8_2 = _nHalfHealthLength
    L7_2 = L7_2 - L8_2
    L8_2 = _nHealthLength
    L8_2 = L8_2 - L4_2
    L7_2 = L7_2 + L8_2
    L8_2 = _nHealthCenter
    L9_2 = _nHalfHealthLength
    L8_2 = L8_2 + L9_2
    L5_2(L6_2, L7_2, L8_2)
  else
    L4_2 = A0_2
    L3_2 = A0_2.IsAnimating
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.bFadingIn
      if not L3_2 then
        goto lbl_59
      end
    end
    L4_2 = A0_2
    L3_2 = A0_2.AnimateToPoint
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.nFadedPoint
    L6_2 = 0.5
    L7_2 = true
    L3_2(L4_2, L5_2, L6_2, L7_2)
  end
  ::lbl_59::
end

_SetHealth = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2
  L1_2 = A0_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nFadedPoint
  L4_2 = 0
  L5_2 = true
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = A0_2.CustomData
  L1_2.bFadingIn = nil
end

_ForceHideHealth = L1_1

function L1_1(A0_2)
  local L1_2
  L1_2 = A0_2.CustomData
  L1_2.bFadingIn = nil
end

_HealthFadeInEnd = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L1_2 = L1_2[1]
  L2_2 = A0_2.CustomData
  L2_2.oHealth = L1_2
  L3_2 = L1_2
  L2_2 = L1_2.GetLocation
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  L6_2 = A0_2.CustomData
  L6_2.nX1 = L2_2
  L6_2 = A0_2.CustomData
  L7_2 = L4_2 - L2_2
  L6_2.nLength = L7_2
  L6_2 = _SetHealthStraight
  A0_2.SetHealth = L6_2
  L6_2 = _ForceHideHealth
  A0_2.Hide = L6_2
  L6_2 = A0_2.CustomData
  L8_2 = A0_2
  L7_2 = A0_2.AddAnimationPoint
  L9_2 = {}
  L9_2.TranslucencyLevel = 0
  L7_2 = L7_2(L8_2, L9_2)
  L6_2.nFadedPoint = L7_2
  L6_2 = A0_2.CustomData
  L8_2 = A0_2
  L7_2 = A0_2.AddAnimationPoint
  L9_2 = {}
  L10_2 = _nBaseAlpha
  L9_2.TranslucencyLevel = L10_2
  L7_2 = L7_2(L8_2, L9_2)
  L6_2.nVisiblePoint = L7_2
  L7_2 = A0_2
  L6_2 = A0_2.Hide
  L6_2(L7_2)
end

HandleHealthInitializationBar = L1_1

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  if 0 <= A1_2 and 0 < A2_2 then
    L4_2 = A0_2
    L3_2 = A0_2.IsAnimating
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L3_2 = A0_2.CustomData
      L3_2.bFadingIn = true
      L4_2 = A0_2
      L3_2 = A0_2.AnimateToPoint
      L5_2 = A0_2.CustomData
      L5_2 = L5_2.nVisiblePoint
      L6_2 = 0
      L7_2 = true
      L8_2 = _HealthFadeInEnd
      L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
    else
      L4_2 = A0_2
      L3_2 = A0_2.SetTranslucency
      L5_2 = _nBaseAlpha
      L3_2(L4_2, L5_2)
    end
    L3_2 = math
    L3_2 = L3_2.min
    L4_2 = A1_2
    L5_2 = A2_2
    L3_2 = L3_2(L4_2, L5_2)
    A1_2 = L3_2
    L3_2 = A1_2 / A2_2
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.nLength
    L4_2 = L4_2 * L3_2
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.oHealth
    L6_2 = L5_2
    L5_2 = L5_2.SetLocation
    L7_2 = A0_2.CustomData
    L7_2 = L7_2.nX1
    L8_2 = nil
    L9_2 = A0_2.CustomData
    L9_2 = L9_2.nX1
    L9_2 = L9_2 + L4_2
    L10_2 = nil
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  else
    L4_2 = A0_2
    L3_2 = A0_2.IsAnimating
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.bFadingIn
      if not L3_2 then
        goto lbl_58
      end
    end
    L4_2 = A0_2
    L3_2 = A0_2.AnimateToPoint
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.nFadedPoint
    L6_2 = 0.5
    L7_2 = true
    L3_2(L4_2, L5_2, L6_2, L7_2)
  end
  ::lbl_58::
end

_SetHealthStraight = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L2_2 = MrxGui
  L2_2 = L2_2.Widget
  L2_2 = L2_2.SetOwner
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
  L2_2 = Gui
  L2_2 = L2_2.GetReticlePosition
  if L2_2 then
    L2_2 = Gui
    L2_2 = L2_2.GetReticlePosition
    L4_2 = A0_2
    L3_2 = A0_2.GetOwner
    L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2 = L3_2(L4_2)
    L2_2, L3_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
    L5_2 = A0_2
    L4_2 = A0_2.GetLocation
    L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
    L8_2 = L2_2 * 320
    L8_2 = 320 + L8_2
    L9_2 = L3_2 * 240
    L9_2 = 240 - L9_2
    L10_2 = L6_2 - L4_2
    L11_2 = L7_2 - L5_2
    L13_2 = A0_2
    L12_2 = A0_2.SetLocation
    L14_2 = L10_2 / 2
    L14_2 = L8_2 - L14_2
    L15_2 = L11_2 / 2
    L15_2 = L9_2 - L15_2
    L12_2(L13_2, L14_2, L15_2)
  end
end

SetReticleOwner = L1_1
L1_1 = -1
_kNoFlashTime = L1_1
L1_1 = 0.15
_kSlowFlashTime = L1_1
L1_1 = 0.15
_kMedFlashTime = L1_1
L1_1 = 0.01
_kFastFlashTime = L1_1
L1_1 = 0.4
_kMedBegin = L1_1
L1_1 = 0.75
_kHighBegin = L1_1
L1_1 = {}
L1_1.nR = 128
L1_1.nG = 128
L1_1.nB = 128
_ktNeutralColor = L1_1
L1_1 = {}
L1_1.nR = 0
L1_1.nG = 255
L1_1.nB = 0
_ktLockonColor = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2.CustomData
  L2_2.nPercent = 0
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L3_2 = L2_2[1]
  L4_2 = L3_2.CustomData
  L4_2.bFlashState = false
  L4_2 = L3_2.CustomData
  L4_2.nTimeUntilFlash = 0
  L4_2 = L3_2.CustomData
  L5_2 = _kSlowFlashTime
  L4_2.nFlashTime = L5_2
  L5_2 = L3_2
  L4_2 = L3_2.SetColor
  L6_2 = _ktNeutralColor
  L6_2 = L6_2.nR
  L7_2 = _ktNeutralColor
  L7_2 = L7_2.nG
  L8_2 = _ktNeutralColor
  L8_2 = L8_2.nB
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = L3_2.CustomData
  L4_2.nFramesWithoutUpdate = 0
  L4_2 = A0_2.CustomData
  L4_2.oTargettingReticle = L3_2
  L4_2 = A0_2.CustomData
  L5_2 = L2_2[2]
  L4_2.oLeft = L5_2
  L4_2 = A0_2.CustomData
  L5_2 = L2_2[3]
  L4_2.oRight = L5_2
  L4_2 = A0_2.CustomData
  L5_2 = L2_2[4]
  L4_2.oHealth = L5_2
  L4_2 = _GuiInternal
  L4_2 = L4_2.SetWidgetUseResolutionCorrection
  if L4_2 then
    L4_2 = _GuiInternal
    L4_2 = L4_2.SetWidgetUseResolutionCorrection
    L5_2 = L3_2.BasicData
    L5_2 = L5_2.uId
    L6_2 = false
    L4_2(L5_2, L6_2)
  end
  L4_2 = Gui
  L4_2 = L4_2.LoadTexture
  L5_2 = "global_gui_reticle_stinger_target"
  L4_2(L5_2)
end

HandleStingerReticleInitialization = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2)
  local L8_2, L9_2, L10_2, L11_2
  L8_2 = type
  L9_2 = A6_2
  L8_2 = L8_2(L9_2)
  if "number" ~= L8_2 then
    A6_2 = -1
  end
  L8_2 = type
  L9_2 = A7_2
  L8_2 = L8_2(L9_2)
  if "number" ~= L8_2 then
    A7_2 = -1
  end
  L8_2 = A0_2.CustomData
  L8_2 = L8_2.oHealth
  L9_2 = L8_2
  L8_2 = L8_2.SetHealth
  L10_2 = A6_2
  L11_2 = A7_2
  L8_2(L9_2, L10_2, L11_2)
end

HandleStingerReticleColorChangeEvent = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L2_2 = false
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oTargettingReticle
  L4_2 = A1_2.nPercent
  if 0 < L4_2 then
    L4_2 = L3_2.CustomData
    L4_2.nFramesWithoutUpdate = 0
  end
  L4_2 = L3_2.EventHandlers
  L4_2 = L4_2.GuiUpdate
  if not L4_2 then
    L5_2 = L3_2
    L4_2 = L3_2.SetEventHandler
    L6_2 = "GuiUpdate"
    L7_2 = HandleStingerReticleUpdate
    L4_2(L5_2, L6_2, L7_2)
  end
  L5_2 = L3_2
  L4_2 = L3_2.SetVisible
  L6_2 = true
  L4_2(L5_2, L6_2)
  L4_2 = A1_2.nPercent
  if 1 <= L4_2 then
    L5_2 = L3_2
    L4_2 = L3_2.SetColor
    L6_2 = _ktLockonColor
    L6_2 = L6_2.nR
    L7_2 = _ktLockonColor
    L7_2 = L7_2.nG
    L8_2 = _ktLockonColor
    L8_2 = L8_2.nB
    L4_2(L5_2, L6_2, L7_2, L8_2)
    L4_2 = L3_2.CustomData
    L4_2.bFlashState = true
    L4_2 = L3_2.CustomData
    L5_2 = _kNoFlashTime
    L4_2.nFlashTime = L5_2
    L4_2 = L3_2.CustomData
    L4_2 = L4_2.bSoundLooping
    if L4_2 then
      L4_2 = Sound
      L4_2 = L4_2.StopSound
      L5_2 = 0
      L6_2 = _ksTargettingSound
      L4_2(L5_2, L6_2)
      L4_2 = L3_2.CustomData
      L4_2.bSoundLooping = false
    end
  else
    L4_2 = A1_2.nPercent
    L5_2 = _kHighBegin
    if L4_2 >= L5_2 then
      L4_2 = L3_2.CustomData
      L5_2 = _kFastFlashTime
      L4_2.nFlashTime = L5_2
    else
      L4_2 = A1_2.nPercent
      L5_2 = _kMedBegin
      if L4_2 >= L5_2 then
        L4_2 = L3_2.CustomData
        L5_2 = _kMedFlashTime
        L4_2.nFlashTime = L5_2
      else
        L4_2 = L3_2.CustomData
        L5_2 = _kSlowFlashTime
        L4_2.nFlashTime = L5_2
      end
    end
    L4_2 = A1_2.nPercent
    L5_2 = _kHighBegin
    if L4_2 >= L5_2 then
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.nPercent
      L5_2 = _kHighBegin
      if L4_2 <= L5_2 then
        L2_2 = true
      end
    end
    if L2_2 then
      L4_2 = L3_2.CustomData
      L4_2.nTimeUntilFlash = 0
    end
    L4_2 = L3_2.CustomData
    L4_2 = L4_2.bSoundLooping
    if not L4_2 then
      L4_2 = Sound
      L4_2 = L4_2.CueSound
      L5_2 = 0
      L6_2 = _ksTargettingSound
      L4_2(L5_2, L6_2)
      L4_2 = L3_2.CustomData
      L4_2.bSoundLooping = true
    end
  end
  L4_2 = A1_2.nX
  if L4_2 then
    L4_2 = A1_2.nY
    if L4_2 then
      L5_2 = L3_2
      L4_2 = L3_2.GetLocation
      L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
      L8_2 = L6_2 - L4_2
      L9_2 = L7_2 - L5_2
      L11_2 = L3_2
      L10_2 = L3_2.SetLocation
      L12_2 = A1_2.nX
      L13_2 = L8_2 / 2
      L12_2 = L12_2 - L13_2
      L13_2 = A1_2.nY
      L14_2 = L9_2 / 2
      L13_2 = L13_2 - L14_2
      L10_2(L11_2, L12_2, L13_2)
    end
  end
  L4_2 = A0_2.CustomData
  L5_2 = A1_2.nPercent
  L4_2.nPercent = L5_2
end

HandleStingerReticleDataUpdate = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2.CustomData
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nFramesWithoutUpdate
  L3_2 = L3_2 + 1
  L2_2.nFramesWithoutUpdate = L3_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nFramesWithoutUpdate
  if 1 < L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.SetColor
    L4_2 = _ktNeutralColor
    L4_2 = L4_2.nR
    L5_2 = _ktNeutralColor
    L5_2 = L5_2.nG
    L6_2 = _ktNeutralColor
    L6_2 = L6_2.nB
    L2_2(L3_2, L4_2, L5_2, L6_2)
    L2_2 = A0_2.CustomData
    L2_2.bFlashState = false
    L3_2 = A0_2
    L2_2 = A0_2.SetVisible
    L4_2 = false
    L2_2(L3_2, L4_2)
    L3_2 = A0_2
    L2_2 = A0_2.SetEventHandler
    L4_2 = "GuiUpdate"
    L5_2 = nil
    L2_2(L3_2, L4_2, L5_2)
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.bSoundLooping
    if L2_2 then
      L2_2 = Sound
      L2_2 = L2_2.StopSound
      L3_2 = 0
      L4_2 = _ksTargettingSound
      L2_2(L3_2, L4_2)
      L2_2 = A0_2.CustomData
      L2_2.bSoundLooping = false
    end
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nFlashTime
  if L2_2 < 0 then
    return
  end
  L2_2 = A0_2.CustomData
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nTimeUntilFlash
  L3_2 = L3_2 - A1_2
  L2_2.nTimeUntilFlash = L3_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nTimeUntilFlash
  if L2_2 <= 0 then
    L2_2 = A0_2.CustomData
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.nFlashTime
    L2_2.nTimeUntilFlash = L3_2
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.bFlashState
    if L2_2 then
      L3_2 = A0_2
      L2_2 = A0_2.SetColor
      L4_2 = _ktLockonColor
      L4_2 = L4_2.nR
      L5_2 = _ktLockonColor
      L5_2 = L5_2.nG
      L6_2 = _ktLockonColor
      L6_2 = L6_2.nB
      L2_2(L3_2, L4_2, L5_2, L6_2)
    else
      L3_2 = A0_2
      L2_2 = A0_2.SetColor
      L4_2 = _ktNeutralColor
      L4_2 = L4_2.nR
      L5_2 = _ktNeutralColor
      L5_2 = L5_2.nG
      L6_2 = _ktNeutralColor
      L6_2 = L6_2.nB
      L2_2(L3_2, L4_2, L5_2, L6_2)
    end
    L2_2 = A0_2.CustomData
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.bFlashState
    L3_2 = not L3_2
    L2_2.bFlashState = L3_2
  end
end

HandleStingerReticleUpdate = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A1_2.sReticleType
  if not L2_2 then
    return
  end
  L2_2 = A1_2.sReticleType
  if "Homing" == L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.SetVisible
    L4_2 = true
    L2_2(L3_2, L4_2)
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.oTargettingReticle
    L3_2 = L2_2
    L2_2 = L2_2.SetVisible
    L4_2 = false
    L2_2(L3_2, L4_2)
    L2_2 = A1_2.nMaxLockOnRadius
    if L2_2 then
      L2_2 = SetStingerReticleRadius
      L3_2 = A0_2
      L4_2 = A1_2.nMaxLockOnRadius
      L2_2(L3_2, L4_2)
    end
    L2_2 = A1_2.nStingerReticleWidth
    if L2_2 then
      L2_2 = A1_2.nStingerReticleHeight
      if L2_2 then
        L2_2 = SetStingerReticleDimensions
        L3_2 = A0_2
        L4_2 = A1_2.nStingerReticleWidth
        L5_2 = A1_2.nStingerReticleHeight
        L2_2(L3_2, L4_2, L5_2)
      end
    end
  else
    L3_2 = A0_2
    L2_2 = A0_2.SetVisible
    L4_2 = false
    L2_2(L3_2, L4_2)
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.oTargettingReticle
    L3_2 = L2_2.CustomData
    L3_2 = L3_2.bSoundLooping
    if L3_2 then
      L3_2 = Sound
      L3_2 = L3_2.StopSound
      L4_2 = 0
      L5_2 = _ksTargettingSound
      L3_2(L4_2, L5_2)
      L3_2 = L2_2.CustomData
      L3_2.bSoundLooping = false
    end
  end
end

HandleStingerReticleGunSwitchEvent = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L3_2 = A0_2
  L2_2 = A0_2.GetLocation
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  L6_2 = L2_2 + L4_2
  L6_2 = L6_2 * 0.5
  L7_2 = L3_2 + L5_2
  L7_2 = L7_2 * 0.5
  L9_2 = A0_2
  L8_2 = A0_2.SetCoordinates
  L10_2 = L6_2 - A1_2
  L11_2 = L7_2 - A1_2
  L12_2 = L6_2 + A1_2
  L13_2 = L7_2 + A1_2
  L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
end

SetStingerReticleRadius = L1_1

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L4_2 = A0_2
  L3_2 = A0_2.GetCorrectedLocation
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.oHealth
  L8_2 = L7_2
  L7_2 = L7_2.GetLocation
  L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
  if L3_2 and L4_2 and L5_2 and L6_2 and L7_2 and L8_2 and L9_2 and L10_2 then
    L11_2 = L3_2 + L5_2
    L11_2 = L11_2 * 0.5
    L12_2 = L4_2 + L6_2
    L12_2 = L12_2 * 0.5
    L14_2 = A0_2
    L13_2 = A0_2.SetCorrectedLocation
    L15_2 = A1_2 / 2
    L15_2 = L11_2 - L15_2
    L16_2 = A2_2 / 2
    L16_2 = L12_2 - L16_2
    L17_2 = A1_2 / 2
    L17_2 = L11_2 + L17_2
    L18_2 = A2_2 / 2
    L18_2 = L12_2 + L18_2
    L13_2(L14_2, L15_2, L16_2, L17_2, L18_2)
    L13_2 = A0_2.CustomData
    L13_2 = L13_2.oLeft
    L14_2 = L13_2
    L13_2 = L13_2.SetCorrectedLocation
    L15_2 = A1_2 / 2
    L15_2 = L11_2 - L15_2
    L16_2 = A2_2 / 2
    L16_2 = L12_2 - L16_2
    L17_2 = L11_2
    L18_2 = A2_2 / 2
    L18_2 = L12_2 + L18_2
    L13_2(L14_2, L15_2, L16_2, L17_2, L18_2)
    L13_2 = A0_2.CustomData
    L13_2 = L13_2.oRight
    L14_2 = L13_2
    L13_2 = L13_2.SetCorrectedLocation
    L15_2 = L11_2
    L16_2 = A2_2 / 2
    L16_2 = L12_2 - L16_2
    L17_2 = A1_2 / 2
    L17_2 = L11_2 + L17_2
    L18_2 = A2_2 / 2
    L18_2 = L12_2 + L18_2
    L13_2(L14_2, L15_2, L16_2, L17_2, L18_2)
    L13_2 = L5_2 - L3_2
    L13_2 = A1_2 / L13_2
    L14_2 = L9_2 - L7_2
    L14_2 = L14_2 * L13_2
    L15_2 = L7_2 + L9_2
    L15_2 = L15_2 * 0.5
    L16_2 = A0_2.CustomData
    L16_2 = L16_2.oHealth
    L17_2 = L16_2
    L16_2 = L16_2.SetLocation
    L18_2 = L14_2 * 0.5
    L18_2 = L15_2 - L18_2
    L19_2 = L8_2
    L20_2 = L14_2 * 0.5
    L20_2 = L15_2 + L20_2
    L21_2 = L10_2
    L16_2(L17_2, L18_2, L19_2, L20_2, L21_2)
    L16_2 = A0_2.CustomData
    L16_2 = L16_2.oHealth
    L17_2 = L16_2
    L16_2 = L16_2.GetChildren
    L16_2 = L16_2(L17_2)
    L16_2 = L16_2[1]
    L17_2 = L16_2
    L16_2 = L16_2.SetLocation
    L18_2 = L14_2 * 0.5
    L18_2 = L15_2 - L18_2
    L19_2 = L8_2
    L20_2 = L14_2 * 0.5
    L20_2 = L15_2 + L20_2
    L21_2 = L10_2
    L16_2(L17_2, L18_2, L19_2, L20_2, L21_2)
  end
end

SetStingerReticleDimensions = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L2_2 = {}
  L3_2 = L1_2[2]
  L2_2[1] = L3_2
  L3_2 = L1_2[3]
  L2_2[2] = L3_2
  L3_2 = L1_2[4]
  L2_2[3] = L3_2
  L3_2 = L1_2[5]
  L2_2[4] = L3_2
  L3_2 = A0_2.CustomData
  L3_2.tCircle = L2_2
  L3_2 = L1_2[1]
  L4_2 = L3_2.CustomData
  L6_2 = L3_2
  L5_2 = L3_2.AddAnimationPoint
  L7_2 = {}
  L7_2.nRotation = 359
  L7_2.nRotationDirection = 1
  L5_2 = L5_2(L6_2, L7_2)
  L4_2.nPoint = L5_2
  L4_2 = L3_2.CustomData
  L6_2 = L3_2
  L5_2 = L3_2.AddAnimationPoint
  L7_2 = {}
  L5_2 = L5_2(L6_2, L7_2)
  L4_2.nStopPoint = L5_2
  L4_2 = A0_2.CustomData
  L4_2.oArrow = L3_2
  L4_2 = A0_2.CustomData
  L6_2 = A0_2
  L5_2 = A0_2.AddAnimationPoint
  L7_2 = {}
  L7_2.TranslucencyLevel = 128
  L5_2 = L5_2(L6_2, L7_2)
  L4_2.nEnterPoint = L5_2
  L4_2 = A0_2.CustomData
  L6_2 = A0_2
  L5_2 = A0_2.AddAnimationPoint
  L7_2 = {}
  L7_2.TranslucencyLevel = 0
  L5_2 = L5_2(L6_2, L7_2)
  L4_2.nExitPoint = L5_2
  L4_2 = A0_2.CustomData
  L4_2.bEnabled = true
  L5_2 = A0_2
  L4_2 = A0_2.SetVisible
  L6_2 = false
  L4_2(L5_2, L6_2)
  L4_2 = _LaserReticleDisable
  L5_2 = A0_2
  L4_2(L5_2)
end

HandleLaserReticleInitialization = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = type
  L3_2 = A1_2.sReticleType
  L2_2 = L2_2(L3_2)
  if "string" ~= L2_2 then
    L2_2 = _LaserReticleDisable
    L3_2 = A0_2
    L2_2(L3_2)
    return
  end
  L2_2 = A1_2.sReticleType
  if "Laser" == L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.SetTranslucency
    L4_2 = 0
    L2_2(L3_2, L4_2)
    L3_2 = A0_2
    L2_2 = A0_2.SetVisible
    L4_2 = true
    L2_2(L3_2, L4_2)
    L2_2 = A0_2.CustomData
    L2_2.bEnabled = true
    L3_2 = A0_2
    L2_2 = A0_2.AnimateToPoint
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.nEnterPoint
    L5_2 = 0.5
    L6_2 = true
    L2_2(L3_2, L4_2, L5_2, L6_2)
    L2_2 = _LaserReticleSnapToNeutral
    L3_2 = A0_2
    L2_2(L3_2)
  else
    L2_2 = _LaserReticleDisable
    L3_2 = A0_2
    L2_2(L3_2)
  end
end

HandleLaserReticleGunSwitchEvent = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A1_2.bActive
  if L2_2 then
    L2_2 = A1_2.nTime
    if L2_2 then
      L2_2 = _LaserReticleAnimate
      L3_2 = A0_2
      L4_2 = A1_2.nTime
      L2_2(L3_2, L4_2)
  end
  else
    L2_2 = _LaserReticleSnapToNeutral
    L3_2 = A0_2
    L2_2(L3_2)
  end
end

HandleLaserReticleStateChangeEvent = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bEnabled
  if L1_2 then
    L1_2 = _LaserReticleSnapToNeutral
    L2_2 = A0_2
    L1_2(L2_2)
    L2_2 = A0_2
    L1_2 = A0_2.SetVisible
    L3_2 = false
    L1_2(L2_2, L3_2)
    L1_2 = A0_2.CustomData
    L1_2.bEnabled = false
  end
end

_LaserReticleDisable = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = pairs
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.tCircle
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L8_2 = L6_2
    L7_2 = L6_2.PlayAnimation
    L9_2 = 0
    L10_2 = 30
    L11_2 = A1_2
    L7_2(L8_2, L9_2, L10_2, L11_2)
  end
  L2_2 = _LaserReticleAnimateArrow
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

_LaserReticleAnimate = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oArrow
  if A1_2 < 0 then
    L4_2 = L2_2
    L3_2 = L2_2.AnimateToPoint
    L5_2 = L2_2.CustomData
    L5_2 = L5_2.nStopPoint
    L6_2 = 0
    L7_2 = true
    L3_2(L4_2, L5_2, L6_2, L7_2)
  else
    L4_2 = L2_2
    L3_2 = L2_2.SetRotation
    L5_2 = 0
    L3_2(L4_2, L5_2)
    L3_2 = L2_2.CustomData
    L3_2.nTime = A1_2
    L4_2 = L2_2
    L3_2 = L2_2.AnimateToPoint
    L5_2 = L2_2.CustomData
    L5_2 = L5_2.nPoint
    L6_2 = A1_2
    L7_2 = true
    L8_2 = _LaserReticleArrowLoop
    L9_2 = L2_2
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  end
end

_LaserReticleAnimateArrow = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = pairs
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.tCircle
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L7_2 = L5_2
    L6_2 = L5_2.HaltAnimation
    L6_2(L7_2)
    L7_2 = L5_2
    L6_2 = L5_2.SetFrame
    L8_2 = 0
    L6_2(L7_2, L8_2)
  end
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oArrow
  L3_2 = L1_2
  L2_2 = L1_2.AnimateToPoint
  L4_2 = L1_2.CustomData
  L4_2 = L4_2.nPoint
  L5_2 = 0
  L6_2 = true
  L7_2 = L1_2.SetRotation
  L8_2 = {}
  L9_2 = 0
  L8_2[1] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
end

_LaserReticleSnapToNeutral = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2.SetRotation
  L3_2 = 0
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nPoint
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nTime
  L5_2 = true
  L6_2 = _LaserReticleArrowLoop
  L7_2 = A0_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
end

_LaserReticleArrowLoop = L1_1
