local L0_1, L1_1, L2_1
L0_1 = 2
_knShowTime = L0_1
L0_1 = 20
_knPulsingThreshold = L0_1
L0_1 = 100
_knVisibleThreshold = L0_1
L0_1 = 0.4
_knPulseTime = L0_1
L0_1 = {}
L0_1.texture = "global_gui_hud02"
L0_1.u1 = 0.443359
L0_1.v1 = 0.466797
L0_1.u2 = 0.552734
L0_1.v2 = 0.576172
L1_1 = {}
L2_1 = {}
L2_1.texture = "HUD_vehicle_armor_1"
L2_1.u1 = 0
L2_1.v1 = 0
L2_1.u2 = 1
L2_1.v2 = 1
L1_1.ArmorVehicle = L2_1
L2_1 = {}
L2_1.texture = "HUD_vehicle_armor_2"
L2_1.u1 = 0
L2_1.v1 = 0
L2_1.u2 = 1
L2_1.v2 = 1
L1_1.ArmorLight = L2_1
L2_1 = {}
L2_1.texture = "HUD_vehicle_armor_3"
L2_1.u1 = 0
L2_1.v1 = 0
L2_1.u2 = 1
L2_1.v2 = 1
L1_1.ArmorMedium = L2_1
L2_1 = {}
L2_1.texture = "HUD_vehicle_armor_4"
L2_1.u1 = 0
L2_1.v1 = 0
L2_1.u2 = 1
L2_1.v2 = 1
L1_1.ArmorTank = L2_1

function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L4_2 = 100 * A1_2
  L4_2 = L4_2 / A2_2
  if L4_2 < 1 and 0 < L4_2 then
    L4_2 = 1
  end
  L6_2 = A0_2
  L5_2 = A0_2.SetText
  L7_2 = string
  L7_2 = L7_2.format
  L8_2 = "%d"
  L9_2 = L4_2
  L7_2, L8_2, L9_2, L10_2, L11_2 = L7_2(L8_2, L9_2)
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  L5_2 = A0_2.CustomData
  L6_2 = L5_2.bVehicle
  L6_2 = L6_2 ~= A3_2
  L7_2 = L5_2.nPreviousValue
  if not L7_2 then
    L5_2.nPreviousValue = 0
  end
  L7_2 = L5_2.nPreviousValue
  if 20 < L7_2 and L4_2 <= 20 then
    L8_2 = A0_2
    L7_2 = A0_2.SetAnimationPoint
    L9_2 = L5_2.nNeutralPoint
    L10_2 = {}
    L10_2.RedLevel = 128
    L10_2.GreenLevel = 16
    L10_2.BlueLevel = 16
    L7_2(L8_2, L9_2, L10_2)
  else
    L7_2 = L5_2.nPreviousValue
    if L7_2 <= 20 and 20 < L4_2 then
      L8_2 = A0_2
      L7_2 = A0_2.SetAnimationPoint
      L9_2 = L5_2.nNeutralPoint
      L10_2 = {}
      L11_2 = L5_2.nR
      L10_2.RedLevel = L11_2
      L11_2 = L5_2.nG
      L10_2.GreenLevel = L11_2
      L11_2 = L5_2.nB
      L10_2.BlueLevel = L11_2
      L7_2(L8_2, L9_2, L10_2)
    end
  end
  if not L6_2 then
    L7_2 = L5_2.nPreviousValue
    if L4_2 > L7_2 then
      L8_2 = A0_2
      L7_2 = A0_2.SetColor
      L9_2 = 16
      L10_2 = 128
      L11_2 = 16
      L7_2(L8_2, L9_2, L10_2, L11_2)
      L8_2 = A0_2
      L7_2 = A0_2.AnimateToPoint
      L9_2 = L5_2.nNeutralPoint
      L10_2 = 1
      L11_2 = true
      L7_2(L8_2, L9_2, L10_2, L11_2)
    else
      L7_2 = L5_2.nPreviousValue
      if L4_2 < L7_2 then
        L8_2 = A0_2
        L7_2 = A0_2.SetColor
        L9_2 = 216
        L10_2 = 16
        L11_2 = 16
        L7_2(L8_2, L9_2, L10_2, L11_2)
        L8_2 = A0_2
        L7_2 = A0_2.AnimateToPoint
        L9_2 = L5_2.nNeutralPoint
        L10_2 = 1
        L11_2 = true
        L7_2(L8_2, L9_2, L10_2, L11_2)
      end
    end
  else
    L8_2 = A0_2
    L7_2 = A0_2.AnimateToPoint
    L9_2 = L5_2.nNeutralPoint
    L10_2 = 0
    L11_2 = true
    L7_2(L8_2, L9_2, L10_2, L11_2)
  end
  L5_2.bVehicle = A3_2
  L5_2.nPreviousValue = L4_2
end

HandleHealthChangedEventNew = L2_1

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = A0_2.CustomData
  L3_2 = A0_2
  L2_2 = A0_2.GetColor
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  L1_2.nR = L2_2
  L1_2.nG = L3_2
  L1_2.nB = L4_2
  L1_2.nA = L5_2
  L1_2.bVehicle = false
  L7_2 = A0_2
  L6_2 = A0_2.AddAnimationPoint
  L8_2 = {}
  L8_2.RedLevel = L2_2
  L8_2.GreenLevel = L3_2
  L8_2.BlueLevel = L4_2
  L6_2 = L6_2(L7_2, L8_2)
  L1_2.nNeutralPoint = L6_2
end

HandleInitializationNew = L2_1

function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L4_2 = 100 * A1_2
  L4_2 = L4_2 / A2_2
  L5_2 = A0_2.CustomData
  L6_2 = L5_2.bHidden
  if L6_2 then
    L5_2.bHidden = false
    L7_2 = A0_2
    L6_2 = A0_2.SetVisible
    L8_2 = true
    L6_2(L7_2, L8_2)
    L7_2 = A0_2
    L6_2 = A0_2.AnimateToPoint
    L8_2 = L5_2.nStartPoint
    L9_2 = 0.15
    L10_2 = true
    L11_2 = _SetCounterVisible
    L12_2 = {}
    L13_2 = L5_2.oCounter
    L12_2[1] = L13_2
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  end
  L6_2 = _knShowTime
  L5_2.nRemainingTime = L6_2
  L5_2.nCurrentLife = L4_2
  L6_2 = _knPulsingThreshold
  if L4_2 < L6_2 then
    L6_2 = L5_2.bPulsing
    if not L6_2 then
      L5_2.bPulsing = true
      L7_2 = A0_2
      L6_2 = A0_2.AnimateToPoint
      L8_2 = L5_2.nRedColorPoint
      L9_2 = _knPulseTime
      L10_2 = false
      L11_2 = _LoopToNeutral
      L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  end
  else
    L6_2 = L5_2.bPulsing
    if L6_2 then
      L6_2 = _knPulsingThreshold
      if L4_2 >= L6_2 then
        L7_2 = A0_2
        L6_2 = A0_2.AnimateToPoint
        L8_2 = L5_2.nNeutralColorPoint
        L9_2 = _knPulseTime
        L10_2 = true
        L6_2(L7_2, L8_2, L9_2, L10_2)
        L5_2.bPulsing = false
      end
    end
  end
end

HandleHealthChangedEventMain = L2_1

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L3_2 = A1_2
  L2_2 = A1_2.SetVisible
  L4_2 = true
  L2_2(L3_2, L4_2)
end

_SetCounterVisible = L2_1

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2.CustomData
  L3_2 = L2_2.bHidden
  if not L3_2 then
    L3_2 = L2_2.nCurrentLife
    L4_2 = _knVisibleThreshold
    if L3_2 >= L4_2 then
      L3_2 = L2_2.bPulsing
      if not L3_2 then
        L3_2 = L2_2.nRemainingTime
        L3_2 = L3_2 - A1_2
        L2_2.nRemainingTime = L3_2
        L3_2 = L2_2.nRemainingTime
        if L3_2 <= 0 then
          L3_2 = _knShowTime
          L2_2.nRemainingTime = L3_2
          L3_2 = A0_2.CustomData
          L3_2.bHidden = true
          L4_2 = A0_2
          L3_2 = A0_2.AnimateToPoint
          L5_2 = L2_2.nClosePoint
          L6_2 = 0.15
          L7_2 = true
          L8_2 = A0_2.SetVisible
          L9_2 = {}
          L10_2 = false
          L9_2[1] = L10_2
          L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
          L3_2 = L2_2.oCounter
          L4_2 = L3_2
          L3_2 = L3_2.SetVisible
          L5_2 = false
          L3_2(L4_2, L5_2)
        end
      end
    end
  end
end

HandleUpdateMain = L2_1

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2
  L1_2 = A0_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nRedColorPoint
  L4_2 = _knPulseTime
  L5_2 = true
  L6_2 = _LoopToNeutral
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

_LoopToRed = L2_1

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2
  L1_2 = A0_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nNeutralColorPoint
  L4_2 = _knPulseTime
  L5_2 = true
  L6_2 = _LoopToRed
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

_LoopToNeutral = L2_1

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2.CustomData
  L3_2 = L2_2.bHidden
  if L3_2 then
    L2_2.bHidden = false
    L4_2 = A0_2
    L3_2 = A0_2.SetVisible
    L5_2 = true
    L3_2(L4_2, L5_2)
    L4_2 = A0_2
    L3_2 = A0_2.AnimateToPoint
    L5_2 = L2_2.nStartPoint
    L6_2 = 0.15
    L7_2 = true
    L8_2 = _SetCounterVisible
    L9_2 = {}
    L10_2 = L2_2.oCounter
    L9_2[1] = L10_2
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  end
  L3_2 = A1_2.nTime
  if not L3_2 then
    L3_2 = _knShowTime
  end
  L2_2.nRemainingTime = L3_2
end

HandleShowHealthEvent = L2_1

function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = A0_2.CustomData
  L3_2 = A0_2
  L2_2 = A0_2.GetLocation
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  L6_2 = L5_2 + L3_2
  L6_2 = L6_2 * 0.5
  L8_2 = A0_2
  L7_2 = A0_2.GetColor
  L7_2, L8_2, L9_2 = L7_2(L8_2)
  L11_2 = A0_2
  L10_2 = A0_2.AddAnimationPoint
  L12_2 = {}
  L12_2.x = L2_2
  L12_2.y = L3_2
  L12_2.x2 = L4_2
  L12_2.y2 = L5_2
  L10_2 = L10_2(L11_2, L12_2)
  L1_2.nStartPoint = L10_2
  L11_2 = A0_2
  L10_2 = A0_2.AddAnimationPoint
  L12_2 = {}
  L12_2.x = L2_2
  L12_2.y = L6_2
  L12_2.x2 = L4_2
  L12_2.y2 = L6_2
  L12_2.RedLevel = L7_2
  L12_2.GreenLevel = L8_2
  L12_2.BlueLevel = L9_2
  L10_2 = L10_2(L11_2, L12_2)
  L1_2.nClosePoint = L10_2
  L10_2 = A0_2.ParentWidget
  L11_2 = L10_2
  L10_2 = L10_2.GetChildren
  L10_2 = L10_2(L11_2)
  L10_2 = L10_2[2]
  L1_2.oCounter = L10_2
  L10_2 = _knShowTime
  L10_2 = L10_2 * 5
  L1_2.nRemainingTime = L10_2
  L1_2.nCurrentLife = 100
  L11_2 = A0_2
  L10_2 = A0_2.AddAnimationPoint
  L12_2 = {}
  L12_2.RedLevel = L7_2
  L12_2.GreenLevel = L8_2
  L12_2.BlueLevel = L9_2
  L10_2 = L10_2(L11_2, L12_2)
  L1_2.nNeutralColorPoint = L10_2
  L11_2 = A0_2
  L10_2 = A0_2.AddAnimationPoint
  L12_2 = {}
  L12_2.RedLevel = 210
  L12_2.GreenLevel = 0
  L12_2.BlueLevel = 0
  L10_2 = L10_2(L11_2, L12_2)
  L1_2.nRedColorPoint = L10_2
  L1_2.bPulsing = false
  L11_2 = A0_2
  L10_2 = A0_2.SetEventHandler
  L12_2 = "GuiUpdate"
  L13_2 = HandleUpdateMain
  L10_2(L11_2, L12_2, L13_2)
  L11_2 = A0_2
  L10_2 = A0_2.SetEventHandler
  L12_2 = "ShowAllCounters"
  L13_2 = HandleShowHealthEvent
  L10_2(L11_2, L12_2, L13_2)
end

HandleInitializationMain = L2_1

function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2
  L5_2 = A0_2
  L4_2 = A0_2.SetTranslucency
  if A3_2 then
    L6_2 = 0
    if L6_2 then
      goto lbl_8
    end
  end
  L6_2 = 255
  ::lbl_8::
  L4_2(L5_2, L6_2)
end

HandleIconUpdateHuman = L2_1

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  if not A1_2 then
    return
  end
  L3_2 = A0_2
  L2_2 = A0_2.SetTexture
  L4_2 = A1_2.texture
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2.SetTextureCoordinates
  L4_2 = A1_2.u1
  L5_2 = A1_2.v1
  L6_2 = A1_2.u2
  L7_2 = A1_2.v2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

SetVehicleIcon = L2_1

function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L5_2 = A0_2
  L4_2 = A0_2.SetTranslucency
  if A3_2 then
    L6_2 = 255
    if L6_2 then
      goto lbl_8
    end
  end
  L6_2 = 0
  ::lbl_8::
  L4_2(L5_2, L6_2)
  if A3_2 then
    L5_2 = A0_2
    L4_2 = A0_2.GetOwner
    L4_2 = L4_2(L5_2)
    L5_2 = Player
    L5_2 = L5_2.GetCharacter
    L6_2 = L4_2
    L5_2 = L5_2(L6_2)
    L6_2 = Vehicle
    L6_2 = L6_2.GetFromRider
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    L7_2 = pairs
    L8_2 = L1_1
    L7_2, L8_2, L9_2 = L7_2(L8_2)
    for L10_2, L11_2 in L7_2, L8_2, L9_2 do
      L12_2 = Object
      L12_2 = L12_2.HasLabel
      L13_2 = L6_2
      L14_2 = L10_2
      L12_2 = L12_2(L13_2, L14_2)
      if L12_2 then
        L12_2 = SetVehicleIcon
        L13_2 = A0_2
        L14_2 = L11_2
        L12_2(L13_2, L14_2)
        return
      end
    end
    L7_2 = SetVehicleIcon
    L8_2 = A0_2
    L9_2 = L0_1
    L7_2(L8_2, L9_2)
  end
end

HandleIconUpdateVehicle = L2_1

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nHealthValue
  L2_2 = L2_2 / 100
  L4_2 = A0_2
  L3_2 = A0_2.GetChildren
  L3_2 = L3_2(L4_2)
  L3_2 = L3_2[5]
  L4_2 = L3_2
  L3_2 = L3_2.GetLocation
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.nBarLength
  L7_2 = L2_2 * L7_2
  L7_2 = L3_2 + L7_2
  if L5_2 < L7_2 then
    L8_2 = A0_2
    L7_2 = A0_2.GetChildren
    L7_2 = L7_2(L8_2)
    L7_2 = L7_2[5]
    L8_2 = L7_2
    L7_2 = L7_2.SetLocation
    L9_2 = nil
    L10_2 = nil
    L11_2 = 1 * A1_2
    L12_2 = A0_2.CustomData
    L12_2 = L12_2.nBarLength
    L11_2 = L11_2 * L12_2
    L11_2 = L5_2 + L11_2
    L7_2(L8_2, L9_2, L10_2, L11_2)
    L8_2 = A0_2
    L7_2 = A0_2.GetChildren
    L7_2 = L7_2(L8_2)
    L7_2 = L7_2[5]
    L8_2 = L7_2
    L7_2 = L7_2.GetTextureCoordinates
    L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
    L12_2 = A0_2
    L11_2 = A0_2.GetChildren
    L11_2 = L11_2(L12_2)
    L11_2 = L11_2[5]
    L12_2 = L11_2
    L11_2 = L11_2.GetLocation
    L11_2, L12_2, L13_2, L14_2 = L11_2(L12_2)
    L6_2 = L14_2
    L5_2 = L13_2
    L4_2 = L12_2
    L3_2 = L11_2
    L12_2 = A0_2
    L11_2 = A0_2.GetChildren
    L11_2 = L11_2(L12_2)
    L11_2 = L11_2[5]
    L12_2 = L11_2
    L11_2 = L11_2.SetTextureCoordinates
    L13_2 = nil
    L14_2 = nil
    L15_2 = A0_2.CustomData
    L15_2 = L15_2.nUDifference
    L16_2 = L5_2 - L3_2
    L17_2 = A0_2.CustomData
    L17_2 = L17_2.nBarLength
    L16_2 = L16_2 / L17_2
    L15_2 = L15_2 * L16_2
    L15_2 = L7_2 + L15_2
    L11_2(L12_2, L13_2, L14_2, L15_2)
  end
  L8_2 = A0_2
  L7_2 = A0_2.GetChildren
  L7_2 = L7_2(L8_2)
  L7_2 = L7_2[5]
  L8_2 = L7_2
  L7_2 = L7_2.GetLocation
  L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
  L6_2 = L10_2
  L5_2 = L9_2
  L4_2 = L8_2
  L3_2 = L7_2
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.nBarLength
  L7_2 = L2_2 * L7_2
  L7_2 = L3_2 + L7_2
  if L5_2 > L7_2 then
    L8_2 = A0_2
    L7_2 = A0_2.GetChildren
    L7_2 = L7_2(L8_2)
    L7_2 = L7_2[5]
    L8_2 = L7_2
    L7_2 = L7_2.SetLocation
    L9_2 = nil
    L10_2 = nil
    L11_2 = A0_2.CustomData
    L11_2 = L11_2.nHealthValue
    L11_2 = L11_2 / 100
    L12_2 = A0_2.CustomData
    L12_2 = L12_2.nBarLength
    L11_2 = L11_2 * L12_2
    L11_2 = L3_2 + L11_2
    L7_2(L8_2, L9_2, L10_2, L11_2)
    L8_2 = A0_2
    L7_2 = A0_2.GetChildren
    L7_2 = L7_2(L8_2)
    L7_2 = L7_2[5]
    L8_2 = L7_2
    L7_2 = L7_2.GetTextureCoordinates
    L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
    L12_2 = A0_2
    L11_2 = A0_2.GetChildren
    L11_2 = L11_2(L12_2)
    L11_2 = L11_2[5]
    L12_2 = L11_2
    L11_2 = L11_2.GetLocation
    L11_2, L12_2, L13_2, L14_2 = L11_2(L12_2)
    L6_2 = L14_2
    L5_2 = L13_2
    L4_2 = L12_2
    L3_2 = L11_2
    L12_2 = A0_2
    L11_2 = A0_2.GetChildren
    L11_2 = L11_2(L12_2)
    L11_2 = L11_2[5]
    L12_2 = L11_2
    L11_2 = L11_2.SetTextureCoordinates
    L13_2 = nil
    L14_2 = nil
    L15_2 = A0_2.CustomData
    L15_2 = L15_2.nUDifference
    L16_2 = L5_2 - L3_2
    L17_2 = A0_2.CustomData
    L17_2 = L17_2.nBarLength
    L16_2 = L16_2 / L17_2
    L15_2 = L15_2 * L16_2
    L15_2 = L7_2 + L15_2
    L11_2(L12_2, L13_2, L14_2, L15_2)
  end
  L8_2 = A0_2
  L7_2 = A0_2.GetChildren
  L7_2 = L7_2(L8_2)
  L7_2 = L7_2[4]
  L8_2 = L7_2
  L7_2 = L7_2.GetLocation
  L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
  L11_2 = A0_2.CustomData
  L11_2 = L11_2.nBarLength
  L11_2 = L11_2 * L2_2
  L11_2 = L3_2 + L11_2
  if L9_2 > L11_2 then
    L12_2 = A0_2
    L11_2 = A0_2.GetChildren
    L11_2 = L11_2(L12_2)
    L11_2 = L11_2[4]
    L12_2 = L11_2
    L11_2 = L11_2.SetLocation
    L13_2 = nil
    L14_2 = nil
    L15_2 = A0_2.CustomData
    L15_2 = L15_2.nBarLength
    L15_2 = 0.25 * L15_2
    L15_2 = L15_2 * A1_2
    L15_2 = L9_2 - L15_2
    L11_2(L12_2, L13_2, L14_2, L15_2)
  end
  L12_2 = A0_2
  L11_2 = A0_2.GetChildren
  L11_2 = L11_2(L12_2)
  L11_2 = L11_2[4]
  L12_2 = L11_2
  L11_2 = L11_2.GetLocation
  L11_2, L12_2, L13_2, L14_2 = L11_2(L12_2)
  L10_2 = L14_2
  L9_2 = L13_2
  L8_2 = L12_2
  L7_2 = L11_2
  if L5_2 > L9_2 then
    L12_2 = A0_2
    L11_2 = A0_2.GetChildren
    L11_2 = L11_2(L12_2)
    L11_2 = L11_2[4]
    L12_2 = L11_2
    L11_2 = L11_2.SetLocation
    L13_2 = nil
    L14_2 = nil
    L15_2 = L5_2
    L11_2(L12_2, L13_2, L14_2, L15_2)
  end
end

HandleUpdateEvent = L2_1

function L2_1(A0_2, A1_2)
  if A0_2 < A1_2 then
    return A0_2
  else
    return A1_2
  end
end

Min = L2_1

function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L3_2 = 100 * A1_2
  L3_2 = L3_2 / A2_2
  if not L3_2 then
    L3_2 = 100
  end
  if 100 < L3_2 then
    L3_2 = 100
  end
  if L3_2 < 0 then
    L3_2 = 0
  end
  if L3_2 < 1 and 0 < L3_2 then
    L3_2 = 1
  end
  L5_2 = A0_2
  L4_2 = A0_2.GetChildren
  L4_2 = L4_2(L5_2)
  L4_2 = L4_2[5]
  L5_2 = L4_2
  L4_2 = L4_2.GetLocation
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  L7_2 = L6_2 - L4_2
  L8_2 = A0_2.CustomData
  L8_2 = L8_2.nHealthValue
  if L3_2 > L8_2 then
    L9_2 = A0_2
    L8_2 = A0_2.GetChildren
    L8_2 = L8_2(L9_2)
    L8_2 = L8_2[4]
    L9_2 = L8_2
    L8_2 = L8_2.SetColor
    L10_2 = 0
    L11_2 = 128
    L12_2 = 0
    L8_2(L9_2, L10_2, L11_2, L12_2)
    L9_2 = A0_2
    L8_2 = A0_2.GetChildren
    L8_2 = L8_2(L9_2)
    L8_2 = L8_2[3]
    L9_2 = L8_2
    L8_2 = L8_2.GetLocation
    L8_2 = L8_2(L9_2)
    L10_2 = A0_2
    L9_2 = A0_2.GetChildren
    L9_2 = L9_2(L10_2)
    L9_2 = L9_2[4]
    L10_2 = L9_2
    L9_2 = L9_2.SetLocation
    L11_2 = nil
    L12_2 = nil
    L13_2 = L3_2 / 100
    L14_2 = A0_2.CustomData
    L14_2 = L14_2.nBarLength
    L13_2 = L13_2 * L14_2
    L13_2 = L8_2 + L13_2
    L9_2(L10_2, L11_2, L12_2, L13_2)
    L10_2 = A0_2
    L9_2 = A0_2.GetChildren
    L9_2 = L9_2(L10_2)
    L9_2 = L9_2[1]
    L10_2 = L9_2
    L9_2 = L9_2.SetColor
    L11_2 = 0
    L12_2 = 255
    L13_2 = 0
    L9_2(L10_2, L11_2, L12_2, L13_2)
    L9_2 = A0_2.CustomData
    L9_2 = L9_2.nHealthValue
    if L9_2 <= 20 and 20 < L3_2 then
      L10_2 = A0_2
      L9_2 = A0_2.GetChildren
      L9_2 = L9_2(L10_2)
      L9_2 = L9_2[1]
      L9_2 = L9_2.CustomData
      L9_2.bPulse = false
    end
    L10_2 = A0_2
    L9_2 = A0_2.GetChildren
    L9_2 = L9_2(L10_2)
    L9_2 = L9_2[1]
    L9_2 = L9_2.CustomData
    L9_2.bGoingDown = false
  else
    L8_2 = A0_2.CustomData
    L8_2 = L8_2.nHealthValue
    if L3_2 < L8_2 then
      L9_2 = A0_2
      L8_2 = A0_2.GetChildren
      L8_2 = L8_2(L9_2)
      L8_2 = L8_2[5]
      L9_2 = L8_2
      L8_2 = L8_2.GetLocation
      L8_2 = L8_2(L9_2)
      L10_2 = A0_2
      L9_2 = A0_2.GetChildren
      L9_2 = L9_2(L10_2)
      L9_2 = L9_2[5]
      L10_2 = L9_2
      L9_2 = L9_2.SetLocation
      L11_2 = nil
      L12_2 = nil
      L13_2 = L3_2 / 100
      L14_2 = A0_2.CustomData
      L14_2 = L14_2.nBarLength
      L13_2 = L13_2 * L14_2
      L13_2 = L8_2 + L13_2
      L9_2(L10_2, L11_2, L12_2, L13_2)
      L10_2 = A0_2
      L9_2 = A0_2.GetChildren
      L9_2 = L9_2(L10_2)
      L9_2 = L9_2[4]
      L10_2 = L9_2
      L9_2 = L9_2.SetColor
      L11_2 = 128
      L12_2 = 0
      L13_2 = 0
      L9_2(L10_2, L11_2, L12_2, L13_2)
      L10_2 = A0_2
      L9_2 = A0_2.GetChildren
      L9_2 = L9_2(L10_2)
      L9_2 = L9_2[1]
      L10_2 = L9_2
      L9_2 = L9_2.SetColor
      L11_2 = 255
      L12_2 = 0
      L13_2 = 0
      L9_2(L10_2, L11_2, L12_2, L13_2)
      L9_2 = A0_2.CustomData
      L9_2 = L9_2.nHealthValue
      if 20 < L9_2 and L3_2 <= 20 then
        L10_2 = A0_2
        L9_2 = A0_2.GetChildren
        L9_2 = L9_2(L10_2)
        L9_2 = L9_2[1]
        L9_2 = L9_2.CustomData
        L9_2.bPulse = true
        L10_2 = A0_2
        L9_2 = A0_2.GetChildren
        L9_2 = L9_2(L10_2)
        L9_2 = L9_2[1]
        L9_2 = L9_2.CustomData
        L9_2.bGoingDown = false
      end
    end
  end
  L9_2 = A0_2
  L8_2 = A0_2.GetChildren
  L8_2 = L8_2(L9_2)
  L8_2 = L8_2[5]
  L9_2 = L8_2
  L8_2 = L8_2.GetLocation
  L8_2, L9_2, L10_2 = L8_2(L9_2)
  L6_2 = L10_2
  L5_2 = L9_2
  L4_2 = L8_2
  L9_2 = A0_2
  L8_2 = A0_2.GetChildren
  L8_2 = L8_2(L9_2)
  L8_2 = L8_2[5]
  L9_2 = L8_2
  L8_2 = L8_2.GetTextureCoordinates
  L8_2 = L8_2(L9_2)
  L10_2 = A0_2
  L9_2 = A0_2.GetChildren
  L9_2 = L9_2(L10_2)
  L9_2 = L9_2[5]
  L10_2 = L9_2
  L9_2 = L9_2.SetTextureCoordinates
  L11_2 = nil
  L12_2 = nil
  L13_2 = A0_2.CustomData
  L13_2 = L13_2.nUDifference
  L14_2 = L6_2 - L4_2
  L15_2 = A0_2.CustomData
  L15_2 = L15_2.nBarLength
  L14_2 = L14_2 / L15_2
  L13_2 = L13_2 * L14_2
  L13_2 = L8_2 + L13_2
  L9_2(L10_2, L11_2, L12_2, L13_2)
  L9_2 = A0_2.CustomData
  L9_2.nHealthValue = L3_2
  if 0 == L3_2 then
    L10_2 = A0_2
    L9_2 = A0_2.GetChildren
    L9_2 = L9_2(L10_2)
    L9_2 = L9_2[5]
    L10_2 = L9_2
    L9_2 = L9_2.SetVisible
    L11_2 = false
    L9_2(L10_2, L11_2)
  else
    L10_2 = A0_2
    L9_2 = A0_2.GetChildren
    L9_2 = L9_2(L10_2)
    L9_2 = L9_2[5]
    L10_2 = L9_2
    L9_2 = L9_2.SetVisible
    L12_2 = A0_2
    L11_2 = A0_2.GetVisible
    L11_2, L12_2, L13_2, L14_2, L15_2 = L11_2(L12_2)
    L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  end
end

HandleHealthChangedEvent = L2_1

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L2_2 = L2_2[3]
  L3_2 = L2_2
  L2_2 = L2_2.GetLocation
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L5_2 = A0_2.CustomData
  L6_2 = L4_2 - L2_2
  L5_2.nHealthValue = L6_2
  L5_2 = A0_2.CustomData
  L6_2 = L4_2 - L2_2
  L5_2.nBarLength = L6_2
  L6_2 = A0_2
  L5_2 = A0_2.GetChildren
  L5_2 = L5_2(L6_2)
  L5_2 = L5_2[5]
  L6_2 = L5_2
  L5_2 = L5_2.GetTextureCoordinates
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L8_2 = A0_2.CustomData
  L9_2 = L7_2 - L5_2
  L8_2.nUDifference = L9_2
end

HandleInitialization = L2_1

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L3_2 = A0_2
  L2_2 = A0_2.SetVisible
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = HandleInitialization
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

HandleVehicleInitialization = L2_1

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bPulse
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.bGoingDown
  L5_2 = A0_2
  L4_2 = A0_2.GetColor
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.bGoingDown
  if L7_2 then
    L7_2 = A0_2.CustomData
    L7_2 = L7_2.bPulse
    if L7_2 then
      goto lbl_56
    end
  end
  L7_2 = 192 * A1_2
  L8_2 = A0_2.CustomData
  L8_2 = L8_2.bPulse
  if L8_2 then
    L7_2 = 512 * A1_2
  end
  L8_2 = Min
  L9_2 = L7_2
  L10_2 = 255 - L4_2
  L8_2 = L8_2(L9_2, L10_2)
  L9_2 = Min
  L10_2 = L7_2
  L11_2 = 255 - L5_2
  L9_2 = L9_2(L10_2, L11_2)
  L10_2 = Min
  L11_2 = L7_2
  L12_2 = 255 - L6_2
  L10_2 = L10_2(L11_2, L12_2)
  L12_2 = A0_2
  L11_2 = A0_2.SetColor
  L13_2 = L4_2 + L8_2
  L14_2 = L5_2 + L9_2
  L15_2 = L6_2 + L10_2
  L11_2(L12_2, L13_2, L14_2, L15_2)
  L12_2 = A0_2
  L11_2 = A0_2.GetColor
  L11_2, L12_2, L13_2 = L11_2(L12_2)
  L6_2 = L13_2
  L5_2 = L12_2
  L4_2 = L11_2
  if 255 <= L4_2 and 255 <= L5_2 and 255 <= L6_2 then
    L11_2 = A0_2.CustomData
    L11_2 = L11_2.bPulse
    if L11_2 then
      L11_2 = A0_2.CustomData
      L11_2.bGoingDown = true
      goto lbl_94
      ::lbl_56::
      L7_2 = A0_2.CustomData
      L7_2 = L7_2.bPulse
      if L7_2 then
        L7_2 = A0_2.CustomData
        L7_2 = L7_2.bGoingDown
        if L7_2 then
          L7_2 = 512 * A1_2
          L8_2 = 0
          L9_2 = Min
          L10_2 = L7_2
          L11_2 = L5_2
          L9_2 = L9_2(L10_2, L11_2)
          L10_2 = Min
          L11_2 = L7_2
          L12_2 = L6_2
          L10_2 = L10_2(L11_2, L12_2)
          L12_2 = A0_2
          L11_2 = A0_2.SetColor
          L13_2 = L4_2 - L8_2
          L14_2 = L5_2 - L9_2
          L15_2 = L6_2 - L10_2
          L11_2(L12_2, L13_2, L14_2, L15_2)
          L12_2 = A0_2
          L11_2 = A0_2.GetColor
          L11_2, L12_2, L13_2 = L11_2(L12_2)
          L6_2 = L13_2
          L5_2 = L12_2
          L4_2 = L11_2
          if L5_2 <= 0 and L6_2 <= 0 then
            L11_2 = A0_2.CustomData
            L11_2 = L11_2.bPulse
            if L11_2 then
              L11_2 = A0_2.CustomData
              L11_2.bGoingDown = false
            end
          end
        end
      end
    end
  end
  ::lbl_94::
end

HandleUpdateEventForBackground = L2_1

function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L4_2 = 100 * A1_2
  L4_2 = L4_2 / A2_2
  L5_2 = true
  if A3_2 then
    L7_2 = A0_2
    L6_2 = A0_2.GetVisible
    L6_2 = L6_2(L7_2)
    if not L6_2 then
      L5_2 = false
    end
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.bE3HudMode
    if not L6_2 then
      L7_2 = A0_2
      L6_2 = A0_2.SetVisible
      L8_2 = true
      L6_2(L7_2, L8_2)
    end
  else
    L7_2 = A0_2
    L6_2 = A0_2.SetVisible
    L8_2 = false
    L6_2(L7_2, L8_2)
  end
  L6_2 = HandleHealthChangedEvent
  L7_2 = A0_2
  L8_2 = A1_2
  L9_2 = A2_2
  L6_2(L7_2, L8_2, L9_2)
  L6_2 = type
  L7_2 = L4_2
  L6_2 = L6_2(L7_2)
  if "number" ~= L6_2 then
    L4_2 = 100
  end
  if 100 < L4_2 then
    L4_2 = 100
  end
  if L4_2 < 0 then
    L4_2 = 0
  end
  if not L5_2 then
    L7_2 = A0_2
    L6_2 = A0_2.GetChildren
    L6_2 = L6_2(L7_2)
    L6_2 = L6_2[1]
    L7_2 = L6_2
    L6_2 = L6_2.SetColor
    L8_2 = 255
    L9_2 = 255
    L10_2 = 255
    L6_2(L7_2, L8_2, L9_2, L10_2)
    L7_2 = A0_2
    L6_2 = A0_2.GetChildren
    L6_2 = L6_2(L7_2)
    L6_2 = L6_2[3]
    L7_2 = L6_2
    L6_2 = L6_2.GetLocation
    L6_2, L7_2, L8_2 = L6_2(L7_2)
    L10_2 = A0_2
    L9_2 = A0_2.GetChildren
    L9_2 = L9_2(L10_2)
    L9_2 = L9_2[5]
    L10_2 = L9_2
    L9_2 = L9_2.SetLocation
    L11_2 = nil
    L12_2 = nil
    L13_2 = L4_2 / 100
    L14_2 = A0_2.CustomData
    L14_2 = L14_2.nBarLength
    L13_2 = L13_2 * L14_2
    L13_2 = L6_2 + L13_2
    L9_2(L10_2, L11_2, L12_2, L13_2)
    L10_2 = A0_2
    L9_2 = A0_2.GetChildren
    L9_2 = L9_2(L10_2)
    L9_2 = L9_2[4]
    L10_2 = L9_2
    L9_2 = L9_2.SetLocation
    L11_2 = nil
    L12_2 = nil
    L13_2 = L4_2 / 100
    L14_2 = A0_2.CustomData
    L14_2 = L14_2.nBarLength
    L13_2 = L13_2 * L14_2
    L13_2 = L6_2 + L13_2
    L9_2(L10_2, L11_2, L12_2, L13_2)
    L10_2 = A0_2
    L9_2 = A0_2.GetChildren
    L9_2 = L9_2(L10_2)
    L9_2 = L9_2[5]
    L10_2 = L9_2
    L9_2 = L9_2.GetLocation
    L9_2, L10_2, L11_2 = L9_2(L10_2)
    L13_2 = A0_2
    L12_2 = A0_2.GetChildren
    L12_2 = L12_2(L13_2)
    L12_2 = L12_2[5]
    L13_2 = L12_2
    L12_2 = L12_2.GetTextureCoordinates
    L12_2 = L12_2(L13_2)
    L14_2 = A0_2
    L13_2 = A0_2.GetChildren
    L13_2 = L13_2(L14_2)
    L13_2 = L13_2[5]
    L14_2 = L13_2
    L13_2 = L13_2.SetTextureCoordinates
    L15_2 = nil
    L16_2 = nil
    L17_2 = A0_2.CustomData
    L17_2 = L17_2.nUDifference
    L18_2 = L11_2 - L9_2
    L19_2 = A0_2.CustomData
    L19_2 = L19_2.nBarLength
    L18_2 = L18_2 / L19_2
    L17_2 = L17_2 * L18_2
    L17_2 = L12_2 + L17_2
    L13_2(L14_2, L15_2, L16_2, L17_2)
  end
end

HandleVehicleEvent = L2_1

function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A1_2.bOn
  if L2_2 then
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.bE3HudMode
    if not L2_2 then
      L3_2 = A0_2
      L2_2 = A0_2.GetVisible
      L2_2 = L2_2(L3_2)
      if not L2_2 then
        L2_2 = A0_2.CustomData
        L2_2.bStayInvisible = true
      end
      L3_2 = A0_2
      L2_2 = A0_2.SetVisible
      L4_2 = false
      L2_2(L3_2, L4_2)
      L2_2 = A0_2.CustomData
      L2_2.bE3HudMode = true
    end
  else
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.bStayInvisible
    if not L2_2 then
      L3_2 = A0_2
      L2_2 = A0_2.SetVisible
      L4_2 = true
      L2_2(L3_2, L4_2)
    end
    L2_2 = A0_2.CustomData
    L2_2.bE3HudMode = false
  end
end

HandleE3HudModeEvent = L2_1

function L2_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = {}
  L2_2.CommandType = "text"
  L2_2.x = 100
  L2_2.y = 100
  L2_2.text = A1_2
  L2_2.font = "lucida12"
  L2_2.RedLevel = 255
  L2_2.GreenLevel = 0
  L2_2.BlueLevel = 0
  L2_2.TranslucencyLevel = 255
  L2_2.HorizontalAnchor = "left"
  L2_2.VerticalAnchor = "top"
  L3_2 = A0_2.DrawingCommands
  L3_2[1] = L2_2
end

DrawDebugRectangle = L2_1
