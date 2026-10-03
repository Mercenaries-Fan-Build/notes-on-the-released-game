local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGuiBase"
L0_1(L1_1)
L0_1 = true
_bTutorialsOn = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L5_2 = Gui
  L5_2 = L5_2.FindGuiLocation
  if L5_2 then
    L5_2 = Gui
    L5_2 = L5_2.FindGuiLocation
    L6_2 = A0_2
    L7_2 = A2_2
    L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2, L7_2)
    L9_2 = DisplayTutorial
    L10_2 = A0_2
    L11_2 = A1_2
    L12_2 = L5_2
    L13_2 = L6_2
    L14_2 = L7_2
    L15_2 = L8_2
    L16_2 = nil
    L17_2 = nil
    L18_2 = A3_2
    L19_2 = A4_2
    return L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
  end
  L5_2 = false
  return L5_2
end

DisplayTutorialForObject = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2, A9_2)
  local L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L10_2 = type
  L11_2 = A1_2
  L10_2 = L10_2(L11_2)
  if "string" ~= L10_2 then
    L10_2 = false
    return L10_2
  end
  L10_2 = _GetTutorialsEnabled
  L10_2 = L10_2()
  if not L10_2 then
    L10_2 = type
    L11_2 = A8_2
    L10_2 = L10_2(L11_2)
    if "function" == L10_2 then
      L10_2 = type
      L11_2 = A9_2
      L10_2 = L10_2(L11_2)
      if "table" ~= L10_2 then
        L10_2 = {}
        A9_2 = L10_2
      end
      L10_2 = A8_2
      L11_2 = unpack
      L12_2 = A9_2
      L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2 = L11_2(L12_2)
      L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
    end
    L10_2 = true
    return L10_2
  else
    if A2_2 and A3_2 and (not A4_2 or not A5_2) then
      L10_2 = 10
      A4_2 = A2_2 + L10_2
      A5_2 = A3_2 + L10_2
      A2_2 = A2_2 - L10_2
      A3_2 = A3_2 - L10_2
    end
    L10_2 = _CreateTutorial
    L11_2 = A1_2
    L12_2 = A2_2
    L13_2 = A3_2
    L14_2 = A4_2
    L15_2 = A5_2
    L16_2 = A6_2
    L17_2 = A7_2
    L18_2 = A8_2
    L19_2 = A9_2
    L20_2 = A0_2
    return L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
  end
end

DisplayTutorial = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2, A9_2)
  local L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2
  L16_2 = MrxGuiBase
  L16_2 = L16_2.TextWidget
  L17_2 = L16_2
  L16_2 = L16_2.new
  L16_2 = L16_2(L17_2)
  L18_2 = L16_2
  L17_2 = L16_2.SetFont
  L19_2 = "english_20"
  L17_2(L18_2, L19_2)
  L18_2 = L16_2
  L17_2 = L16_2.SetScale
  L19_2 = 1
  L17_2(L18_2, L19_2)
  L18_2 = L16_2
  L17_2 = L16_2.SetOwner
  L19_2 = A9_2
  L17_2(L18_2, L19_2)
  L17_2 = A0_2
  L18_2 = "[n][n][confirm] [Generic.Continue][n][action] [Generic.DisableTutorials]"
  A0_2 = L17_2 .. L18_2
  L18_2 = L16_2
  L17_2 = L16_2.SetText
  L19_2 = A0_2
  L17_2(L18_2, L19_2)
  L18_2 = L16_2
  L17_2 = L16_2.Wrap
  L17_2(L18_2)
  L17_2 = type
  L18_2 = A1_2
  L17_2 = L17_2(L18_2)
  if "number" == L17_2 then
    L17_2 = type
    L18_2 = A2_2
    L17_2 = L17_2(L18_2)
    if "number" == L17_2 then
      goto lbl_72
    end
  end
  L17_2 = 5
  L18_2 = L17_2 * 2
  L18_2 = 418 - L18_2
  L18_2 = L18_2 - 48
  L20_2 = L16_2
  L19_2 = L16_2.SetLocation
  L21_2 = 0
  L22_2 = 0
  L23_2 = L18_2
  L24_2 = 0
  L19_2(L20_2, L21_2, L22_2, L23_2, L24_2)
  L20_2 = L16_2
  L19_2 = L16_2.SetText
  L21_2 = A0_2
  L19_2(L20_2, L21_2)
  L20_2 = L16_2
  L19_2 = L16_2.Wrap
  L19_2(L20_2)
  L20_2 = L16_2
  L19_2 = L16_2.GetHeight
  L19_2 = L19_2(L20_2)
  L21_2 = L16_2
  L20_2 = L16_2.SetLocation
  L22_2 = L18_2 / 2
  L22_2 = 320 - L22_2
  L23_2 = L19_2 / 2
  L23_2 = 240 - L23_2
  L24_2 = L18_2 / 2
  L24_2 = 320 + L24_2
  L25_2 = L19_2 / 2
  L25_2 = 240 + L25_2
  L20_2(L21_2, L22_2, L23_2, L24_2, L25_2)
  L21_2 = L16_2
  L20_2 = L16_2.GetLocation
  L20_2, L21_2, L22_2, L23_2 = L20_2(L21_2)
  L13_2 = L23_2
  L12_2 = L22_2
  L11_2 = L21_2
  L10_2 = L20_2
  if not A5_2 then
    A5_2 = "center"
  end
  if not A6_2 then
    A6_2 = "center"
  end
  goto lbl_255
  ::lbl_72::
  L17_2 = math
  L17_2 = L17_2.max
  L18_2 = A1_2
  L19_2 = 640 - A3_2
  L17_2 = L17_2(L18_2, L19_2)
  L17_2 = L17_2 - 48
  L17_2 = L17_2 - 32
  L17_2 = L17_2 * 408
  L18_2 = math
  L18_2 = L18_2.max
  L19_2 = A2_2
  L20_2 = 480 - A4_2
  L18_2 = L18_2(L19_2, L20_2)
  L18_2 = L18_2 - 36
  L18_2 = L18_2 - 32
  L18_2 = L18_2 * 544
  L19_2 = 5
  if L17_2 >= L18_2 then
    L20_2 = A1_2
    L21_2 = 640 - A3_2
    L22_2 = nil
    if L20_2 >= L21_2 then
      L23_2 = _OptimizeSize
      L24_2 = L16_2
      L25_2 = L19_2 * 2
      L25_2 = L20_2 - L25_2
      L25_2 = L25_2 - 32
      L25_2 = L25_2 - 48
      L26_2 = 408
      L23_2 = L23_2(L24_2, L25_2, L26_2)
      L22_2 = L23_2
      L23_2 = A1_2 - 32
      L12_2 = L23_2 - L19_2
      L10_2 = L12_2 - L22_2
      L14_2 = 1
    else
      L23_2 = _OptimizeSize
      L24_2 = L16_2
      L25_2 = L19_2 * 2
      L25_2 = L21_2 - L25_2
      L25_2 = L25_2 - 32
      L25_2 = L25_2 - 48
      L26_2 = 408
      L23_2 = L23_2(L24_2, L25_2, L26_2)
      L22_2 = L23_2
      L23_2 = A3_2 + 32
      L10_2 = L23_2 + L19_2
      L12_2 = L10_2 + L22_2
      L14_2 = -1
    end
    L24_2 = L16_2
    L23_2 = L16_2.SetLocation
    L25_2 = L10_2
    L26_2 = 0
    L27_2 = L12_2
    L28_2 = 0
    L23_2(L24_2, L25_2, L26_2, L27_2, L28_2)
    L24_2 = L16_2
    L23_2 = L16_2.GetHeight
    L23_2 = L23_2(L24_2)
    L24_2 = A2_2 + A4_2
    L24_2 = L24_2 * 0.5
    nCenterY = L24_2
    L24_2 = nCenterY
    L25_2 = L23_2 * 0.5
    L24_2 = L24_2 - L25_2
    L11_2 = L24_2 - L19_2
    L24_2 = nCenterY
    L25_2 = L23_2 * 0.5
    L24_2 = L24_2 + L25_2
    L13_2 = L24_2 + L19_2
    if L11_2 < 36 then
      L24_2 = 36 - L11_2
      L13_2 = L13_2 + L24_2
      L24_2 = 36 - L11_2
      L11_2 = L11_2 + L24_2
    elseif 444 < L13_2 then
      L24_2 = L13_2 - 444
      L11_2 = L11_2 - L24_2
      L24_2 = L13_2 - 444
      L13_2 = L13_2 - L24_2
    end
    L25_2 = L16_2
    L24_2 = L16_2.SetLocation
    L26_2 = L10_2
    L27_2 = L11_2 + L19_2
    L28_2 = L12_2
    L29_2 = L13_2 - L19_2
    L24_2(L25_2, L26_2, L27_2, L28_2, L29_2)
    L10_2 = L10_2 - L19_2
    L12_2 = L12_2 + L19_2
  else
    L15_2 = true
    L20_2 = A4_2 + A2_2
    L20_2 = L20_2 / 2
    L21_2 = A2_2
    L22_2 = 480 - A4_2
    L23_2 = nil
    L24_2 = nil
    if L21_2 >= L22_2 then
      L25_2 = _OptimizeSize
      L26_2 = L16_2
      L27_2 = 544
      L28_2 = L19_2 * 2
      L28_2 = L21_2 - L28_2
      L28_2 = L28_2 - 32
      L28_2 = L28_2 - 36
      L29_2 = true
      L25_2 = L25_2(L26_2, L27_2, L28_2, L29_2)
      L23_2 = L25_2
      L26_2 = L16_2
      L25_2 = L16_2.SetLocation
      L27_2 = 0
      L28_2 = 0
      L29_2 = L23_2
      L30_2 = 0
      L25_2(L26_2, L27_2, L28_2, L29_2, L30_2)
      L26_2 = L16_2
      L25_2 = L16_2.GetHeight
      L25_2 = L25_2(L26_2)
      L24_2 = L25_2
      L25_2 = A2_2 - 32
      L13_2 = L25_2 - L19_2
      L25_2 = L13_2 - L24_2
      L11_2 = L25_2 - L19_2
      L14_2 = 1
    else
      L25_2 = _OptimizeSize
      L26_2 = L16_2
      L27_2 = 544
      L28_2 = L19_2 * 2
      L28_2 = L22_2 - L28_2
      L28_2 = L28_2 - 32
      L28_2 = L28_2 - 36
      L29_2 = true
      L25_2 = L25_2(L26_2, L27_2, L28_2, L29_2)
      L23_2 = L25_2
      L26_2 = L16_2
      L25_2 = L16_2.SetLocation
      L27_2 = 0
      L28_2 = 0
      L29_2 = L23_2
      L30_2 = 0
      L25_2(L26_2, L27_2, L28_2, L29_2, L30_2)
      L26_2 = L16_2
      L25_2 = L16_2.GetHeight
      L25_2 = L25_2(L26_2)
      L24_2 = L25_2
      L25_2 = A4_2 + 32
      L11_2 = L25_2 + L19_2
      L25_2 = L11_2 + L24_2
      L13_2 = L25_2 + L19_2
      L14_2 = -1
    end
    L25_2 = A1_2 + A3_2
    L25_2 = L25_2 * 0.5
    nCenterX = L25_2
    L25_2 = nCenterX
    L26_2 = L23_2 * 0.5
    L25_2 = L25_2 - L26_2
    L10_2 = L25_2 - L19_2
    L25_2 = nCenterX
    L26_2 = L23_2 * 0.5
    L25_2 = L25_2 + L26_2
    L12_2 = L25_2 + L19_2
    if L10_2 < 48 then
      L25_2 = 48 - L10_2
      L12_2 = L12_2 + L25_2
      L25_2 = 48 - L10_2
      L10_2 = L10_2 + L25_2
    elseif 544 < L12_2 and A1_2 <= 544 then
      L25_2 = L12_2 - 544
      L10_2 = L10_2 - L25_2
      L25_2 = L12_2 - 544
      L12_2 = L12_2 - L25_2
    end
    L26_2 = L16_2
    L25_2 = L16_2.SetLocation
    L27_2 = L10_2 + L19_2
    L28_2 = L11_2
    L29_2 = L12_2 - L19_2
    L30_2 = L13_2
    L25_2(L26_2, L27_2, L28_2, L29_2, L30_2)
    L11_2 = L11_2 - L19_2
    L13_2 = L13_2 + L19_2
  end
  ::lbl_255::
  L17_2 = MrxGuiBase
  L17_2 = L17_2.Widget
  L18_2 = L17_2
  L17_2 = L17_2.new
  L17_2 = L17_2(L18_2)
  if A5_2 and A6_2 then
    L19_2 = L17_2
    L18_2 = L17_2.SetLocation
    L20_2 = L10_2
    L21_2 = L11_2
    L22_2 = L12_2
    L23_2 = L13_2
    L18_2(L19_2, L20_2, L21_2, L22_2, L23_2)
    L19_2 = L17_2
    L18_2 = L17_2.SetAnchoring
    L20_2 = A5_2
    L21_2 = A6_2
    L18_2(L19_2, L20_2, L21_2)
  else
    L19_2 = L17_2
    L18_2 = L17_2.SetLocation
    L20_2 = 0
    L21_2 = 0
    L22_2 = 640
    L23_2 = 480
    L18_2(L19_2, L20_2, L21_2, L22_2, L23_2)
    L19_2 = L17_2
    L18_2 = L17_2.SetFullscreen
    L20_2 = true
    L18_2(L19_2, L20_2)
  end
  L18_2 = MrxGuiBase
  L18_2 = L18_2.ImageWidget
  L19_2 = L18_2
  L18_2 = L18_2.new
  L18_2 = L18_2(L19_2)
  L20_2 = L18_2
  L19_2 = L18_2.SetLocation
  L21_2 = L10_2
  L22_2 = L11_2
  L23_2 = L12_2
  L24_2 = L13_2
  L19_2(L20_2, L21_2, L22_2, L23_2, L24_2)
  L20_2 = L18_2
  L19_2 = L18_2.SetColor
  L21_2 = 0
  L22_2 = 0
  L23_2 = 0
  L24_2 = 192
  L19_2(L20_2, L21_2, L22_2, L23_2, L24_2)
  L20_2 = L18_2
  L19_2 = L18_2.AddChild
  L21_2 = L16_2
  L19_2(L20_2, L21_2)
  L19_2 = nil
  if L14_2 then
    L20_2 = MrxGuiBase
    L20_2 = L20_2.SpriteWidget
    L21_2 = L20_2
    L20_2 = L20_2.new
    L20_2 = L20_2(L21_2)
    L19_2 = L20_2
    L21_2 = L19_2
    L20_2 = L19_2.SetTexture
    L22_2 = "temp_tutorial_arrow"
    L20_2(L21_2, L22_2)
    L21_2 = L19_2
    L20_2 = L19_2.SetTextureSize
    L22_2 = 128
    L23_2 = 64
    L20_2(L21_2, L22_2, L23_2)
    L21_2 = L19_2
    L20_2 = L19_2.SetFrameSize
    L22_2 = 32
    L23_2 = 64
    L20_2(L21_2, L22_2, L23_2)
    L21_2 = L19_2
    L20_2 = L19_2.SetFrame
    L22_2 = 0
    L20_2(L21_2, L22_2)
    L21_2 = L19_2
    L20_2 = L19_2.PlayAnimation
    L22_2 = 0
    L23_2 = 3
    L24_2 = 0.25
    L25_2 = true
    L20_2(L21_2, L22_2, L23_2, L24_2, L25_2)
    L21_2 = L19_2
    L20_2 = L19_2.SetOwner
    L22_2 = A9_2
    L20_2(L21_2, L22_2)
    L21_2 = L19_2
    L20_2 = L19_2.SetAnchoring
    L22_2 = A5_2
    L23_2 = A6_2
    L20_2(L21_2, L22_2, L23_2)
    L21_2 = L17_2
    L20_2 = L17_2.AddChild
    L22_2 = L19_2
    L20_2(L21_2, L22_2)
    if L15_2 then
      L20_2 = A1_2 + A3_2
      L20_2 = L20_2 * 0.5
      if L14_2 < 0 then
        L22_2 = L19_2
        L21_2 = L19_2.SetLocation
        L23_2 = L20_2 - 16
        L24_2 = L11_2 - 48
        L25_2 = L20_2 + 16
        L26_2 = L11_2 + 16
        L21_2(L22_2, L23_2, L24_2, L25_2, L26_2)
        L22_2 = L19_2
        L21_2 = L19_2.SetRotation
        L23_2 = 90
        L21_2(L22_2, L23_2)
        if A5_2 and A6_2 then
          L22_2 = L17_2
          L21_2 = L17_2.SetLocation
          L23_2 = L10_2
          L24_2 = L11_2 - 48
          L25_2 = L12_2
          L26_2 = L13_2
          L21_2(L22_2, L23_2, L24_2, L25_2, L26_2)
        end
      else
        L22_2 = L19_2
        L21_2 = L19_2.SetLocation
        L23_2 = L20_2 - 16
        L24_2 = L13_2 - 16
        L25_2 = L20_2 + 16
        L26_2 = L13_2 + 48
        L21_2(L22_2, L23_2, L24_2, L25_2, L26_2)
        L22_2 = L19_2
        L21_2 = L19_2.SetRotation
        L23_2 = 270
        L21_2(L22_2, L23_2)
        if A5_2 and A6_2 then
          L22_2 = L17_2
          L21_2 = L17_2.SetLocation
          L23_2 = L10_2
          L24_2 = L11_2
          L25_2 = L12_2
          L26_2 = L13_2 + 48
          L21_2(L22_2, L23_2, L24_2, L25_2, L26_2)
        end
      end
    else
      L20_2 = A2_2 + A4_2
      L20_2 = L20_2 * 0.5
      if L14_2 < 0 then
        L22_2 = L19_2
        L21_2 = L19_2.SetLocation
        L23_2 = L10_2 - 32
        L24_2 = L20_2 - 32
        L25_2 = L10_2
        L26_2 = L20_2 + 32
        L21_2(L22_2, L23_2, L24_2, L25_2, L26_2)
        if A5_2 and A6_2 then
          L22_2 = L17_2
          L21_2 = L17_2.SetLocation
          L23_2 = L10_2 - 32
          L24_2 = L11_2
          L25_2 = L12_2
          L26_2 = L13_2
          L21_2(L22_2, L23_2, L24_2, L25_2, L26_2)
        end
      else
        L22_2 = L19_2
        L21_2 = L19_2.SetLocation
        L23_2 = L12_2
        L24_2 = L20_2 - 32
        L25_2 = L12_2 + 32
        L26_2 = L20_2 + 32
        L21_2(L22_2, L23_2, L24_2, L25_2, L26_2)
        L22_2 = L19_2
        L21_2 = L19_2.SetRotation
        L23_2 = 180
        L21_2(L22_2, L23_2)
        if A5_2 and A6_2 then
          L22_2 = L17_2
          L21_2 = L17_2.SetLocation
          L23_2 = L10_2
          L24_2 = L11_2
          L25_2 = L12_2 + 32
          L26_2 = L13_2
          L21_2(L22_2, L23_2, L24_2, L25_2, L26_2)
        end
      end
    end
  end
  if L19_2 then
    L21_2 = L19_2
    L20_2 = L19_2.AddChild
    L22_2 = L18_2
    L20_2(L21_2, L22_2)
  else
    L21_2 = L17_2
    L20_2 = L17_2.AddChild
    L22_2 = L18_2
    L20_2(L21_2, L22_2)
  end
  L21_2 = L17_2
  L20_2 = L17_2.SetOwner
  L22_2 = A9_2
  L20_2(L21_2, L22_2)
  L21_2 = L18_2
  L20_2 = L18_2.SetOwner
  L22_2 = A9_2
  L20_2(L21_2, L22_2)
  L20_2 = MrxGuiBase
  L20_2 = L20_2.AddWidgetWithChildren
  L21_2 = L17_2
  L20_2(L21_2)
  L21_2 = L17_2
  L20_2 = L17_2.SetEventHandler
  L22_2 = "ControllerInput"
  L23_2 = _HandleInput
  L20_2(L21_2, L22_2, L23_2)
  L20_2 = L17_2.CustomData
  L20_2.fCallback = A7_2
  L20_2 = L17_2.CustomData
  L20_2.tCallbackData = A8_2
  L20_2 = MrxGuiBase
  L20_2 = L20_2.GetControlFocus
  L21_2 = L17_2
  L22_2 = true
  L20_2(L21_2, L22_2)
  L20_2 = true
  return L20_2
end

_CreateTutorial = L0_1
L0_1 = 25
_knIncrement = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L4_2 = 10000
  L5_2 = 9999
  L6_2 = 0
  L7_2 = A1_2
  L9_2 = A0_2
  L8_2 = A0_2.SetLocation
  L10_2 = 0
  L11_2 = 0
  L12_2 = A1_2
  L13_2 = 0
  L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  L8_2 = _knIncrement
  L7_2 = L7_2 - L8_2
  while A2_2 > L6_2 and L4_2 > L5_2 and 0 < L7_2 do
    L9_2 = A0_2
    L8_2 = A0_2.SetLocation
    L10_2 = 0
    L11_2 = 0
    L12_2 = L7_2
    L13_2 = 0
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
    L9_2 = A0_2
    L8_2 = A0_2.GetHeight
    L8_2 = L8_2(L9_2)
    L6_2 = L8_2
    L4_2 = L5_2
    L8_2 = math
    L8_2 = L8_2.abs
    L9_2 = L7_2 - L6_2
    L8_2 = L8_2(L9_2)
    L5_2 = L8_2
    if L4_2 > L5_2 and A2_2 > L6_2 and L7_2 > L6_2 then
      L8_2 = _knIncrement
      L7_2 = L7_2 - L8_2
    end
  end
  if A3_2 then
    L8_2 = _knIncrement
    L8_2 = L7_2 + L8_2
    return L8_2
  end
  L8_2 = math
  L8_2 = L8_2.min
  L9_2 = _knIncrement
  L9_2 = L7_2 + L9_2
  L10_2 = A1_2
  return L8_2(L9_2, L10_2)
end

_OptimizeSize = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L3_2 = A1_2.ButtonPress
  L4_2 = MrxGuiBase
  L4_2 = L4_2.Joystick
  L4_2 = L4_2.BUTTON_PAD2_D
  if L3_2 == L4_2 then
    L2_2 = true
  else
    L3_2 = A1_2.ButtonPress
    L4_2 = MrxGuiBase
    L4_2 = L4_2.Joystick
    L4_2 = L4_2.BUTTON_PAD2_U
    if L3_2 == L4_2 then
      L3_2 = _SetTutorialsEnabled
      L4_2 = false
      L3_2(L4_2)
      L2_2 = true
    end
  end
  if L2_2 then
    L3_2 = Sound
    L3_2 = L3_2.CueSound
    L4_2 = 0
    L5_2 = "ui_HUD_Continue"
    L3_2(L4_2, L5_2)
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.fCallback
    if L3_2 then
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.tCallbackData
      if not L3_2 then
        L3_2 = {}
      end
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.fCallback
      L5_2 = unpack
      L6_2 = L3_2
      L5_2, L6_2 = L5_2(L6_2)
      L4_2(L5_2, L6_2)
    end
    L3_2 = _DeleteTutorial
    L4_2 = A0_2
    L3_2(L4_2)
  end
end

_HandleInput = L0_1

function L0_1(A0_2, A1_2)
end

_HandleStateChange = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxGuiBase
  L1_2 = L1_2.ReleaseControlFocus
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = MrxGuiBase
  L1_2 = L1_2.RemoveWidgetWithChildren
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = _DeleteChildren
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.delete
  L1_2(L2_2)
end

_DeleteTutorial = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = _DeleteChildren
    L8_2 = L6_2
    L7_2(L8_2)
    L8_2 = A0_2
    L7_2 = A0_2.RemoveChild
    L9_2 = L6_2
    L7_2(L8_2, L9_2)
    L8_2 = L6_2
    L7_2 = L6_2.delete
    L7_2(L8_2)
  end
end

_DeleteChildren = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = Sys
  L0_2 = L0_2.TutorialsEnabled
  if L0_2 then
    L0_2 = Sys
    L0_2 = L0_2.TutorialsEnabled
    return L0_2()
  end
  L0_2 = _bTutorialsOn
  return L0_2
end

_GetTutorialsEnabled = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = Sys
  L1_2 = L1_2.SetTutorialsEnabled
  if L1_2 then
    L1_2 = Sys
    L1_2 = L1_2.SetTutorialsEnabled
    L2_2 = A0_2
    L1_2(L2_2)
  else
    _bTutorialsOn = A0_2
  end
end

_SetTutorialsEnabled = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L2_2 = A0_2.CustomData
  L3_2 = L1_2[1]
  L2_2.oInfo = L3_2
  L2_2 = A0_2.CustomData
  L3_2 = L1_2[2]
  L2_2.oText = L3_2
  L2_2 = InitInfoImage
  L3_2 = L1_2[1]
  L2_2(L3_2)
  L2_2 = SetTutorialWidgetText
  A0_2.SetText = L2_2
  L2_2 = PushTutorialToFront
  A0_2.PushToFront = L2_2
end

TutorialWidgetInitialize = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oInfo
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oText
  if A1_2 then
    L5_2 = L3_2
    L4_2 = L3_2.SetText
    L6_2 = A1_2
    L4_2(L5_2, L6_2)
    L5_2 = L3_2
    L4_2 = L3_2.SetVisible
    L6_2 = true
    L4_2(L5_2, L6_2)
    L5_2 = L3_2
    L4_2 = L3_2.PerformTextAnimation
    L6_2 = "typewriter"
    L4_2(L5_2, L6_2)
    L5_2 = L3_2
    L4_2 = L3_2.GetWidth
    L4_2 = L4_2(L5_2)
    L6_2 = L2_2
    L5_2 = L2_2.Resize
    L7_2 = L4_2
    L5_2(L6_2, L7_2)
    L6_2 = L2_2
    L5_2 = L2_2.Show
    L5_2(L6_2)
    L6_2 = L2_2
    L5_2 = L2_2.GetLocation
    L5_2 = L5_2(L6_2)
    L7_2 = L3_2
    L6_2 = L3_2.SetLocation
    L8_2 = L5_2
    L6_2(L7_2, L8_2)
    L6_2 = Sound
    L6_2 = L6_2.CueSound
    L7_2 = 0
    L8_2 = "ui_signal_ding_up"
    L6_2(L7_2, L8_2)
  else
    L5_2 = L3_2
    L4_2 = L3_2.SetVisible
    L6_2 = false
    L4_2(L5_2, L6_2)
    L5_2 = L2_2
    L4_2 = L2_2.Hide
    L4_2(L5_2)
  end
end

SetTutorialWidgetText = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2
  L1_2 = A0_2.SetTranslucency
  L3_2 = 0
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L3_2 = A0_2
  L2_2 = A0_2.GetLocation
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  L6_2 = A0_2.CustomData
  L7_2 = L1_2[1]
  L6_2.oInfo = L7_2
  L6_2 = A0_2.CustomData
  L7_2 = L1_2[2]
  L6_2.oMid = L7_2
  L6_2 = A0_2.CustomData
  L7_2 = L1_2[3]
  L6_2.oEnd = L7_2
  L6_2 = A0_2.CustomData
  L7_2 = L1_2[4]
  L6_2.oStart = L7_2
  L6_2 = A0_2.CustomData
  L7_2 = L4_2 - L2_2
  L6_2.nMinWidth = L7_2
  L6_2 = ResizeInfoImage
  A0_2.Resize = L6_2
  L6_2 = ShowInfoImage
  A0_2.Show = L6_2
  L6_2 = HideInfoImage
  A0_2.Hide = L6_2
  L6_2 = A0_2.CustomData
  L6_2.sCurrentAnimation = "none"
  L6_2 = A0_2.CustomData
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.oInfo
  L8_2 = L7_2
  L7_2 = L7_2.AddAnimationPoint
  L9_2 = {}
  L7_2 = L7_2(L8_2, L9_2)
  L6_2.nInfoStart = L7_2
  L6_2 = A0_2.CustomData
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.oInfo
  L8_2 = L7_2
  L7_2 = L7_2.AddAnimationPoint
  L9_2 = {}
  L7_2 = L7_2(L8_2, L9_2)
  L6_2.nInfoEnd = L7_2
  L6_2 = A0_2.CustomData
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.oMid
  L8_2 = L7_2
  L7_2 = L7_2.AddAnimationPoint
  L9_2 = {}
  L7_2 = L7_2(L8_2, L9_2)
  L6_2.nMidStart = L7_2
  L6_2 = A0_2.CustomData
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.oMid
  L8_2 = L7_2
  L7_2 = L7_2.AddAnimationPoint
  L9_2 = {}
  L7_2 = L7_2(L8_2, L9_2)
  L6_2.nMidEnd = L7_2
  L6_2 = A0_2.CustomData
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.oStart
  L8_2 = L7_2
  L7_2 = L7_2.AddAnimationPoint
  L9_2 = {}
  L7_2 = L7_2(L8_2, L9_2)
  L6_2.nStartStart = L7_2
  L6_2 = A0_2.CustomData
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.oStart
  L8_2 = L7_2
  L7_2 = L7_2.AddAnimationPoint
  L9_2 = {}
  L7_2 = L7_2(L8_2, L9_2)
  L6_2.nStartEnd = L7_2
end

InitInfoImage = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2
  L1_2 = A0_2.CustomData
  L1_2.bVisible = true
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.sCurrentAnimation
  if "open" == L1_2 then
    return
  end
  L1_2 = A0_2.CustomData
  L1_2.sCurrentAnimation = "open"
  L2_2 = A0_2
  L1_2 = A0_2.SetTranslucency
  L3_2 = 255
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetLocation
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.oInfo
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.oMid
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.oEnd
  L8_2 = A0_2.CustomData
  L8_2 = L8_2.oStart
  L10_2 = L7_2
  L9_2 = L7_2.GetLocation
  L9_2, L10_2, L11_2 = L9_2(L10_2)
  L12_2 = L11_2 - L9_2
  L13_2 = 0.5
  L15_2 = L5_2
  L14_2 = L5_2.SetAnimationPoint
  L16_2 = A0_2.CustomData
  L16_2 = L16_2.nInfoStart
  L17_2 = {}
  L18_2 = L4_2 - 2
  L17_2.y = L18_2
  L18_2 = L4_2 - 2
  L17_2.y2 = L18_2
  L14_2(L15_2, L16_2, L17_2)
  L15_2 = L5_2
  L14_2 = L5_2.SetAnimationPoint
  L16_2 = A0_2.CustomData
  L16_2 = L16_2.nInfoEnd
  L17_2 = {}
  L17_2.y = L2_2
  L17_2.y2 = L4_2
  L14_2(L15_2, L16_2, L17_2)
  L15_2 = L5_2
  L14_2 = L5_2.AnimateToPoint
  L16_2 = A0_2.CustomData
  L16_2 = L16_2.nInfoStart
  L17_2 = 0
  L18_2 = true
  L14_2(L15_2, L16_2, L17_2, L18_2)
  L15_2 = L6_2
  L14_2 = L6_2.SetAnimationPoint
  L16_2 = A0_2.CustomData
  L16_2 = L16_2.nMidStart
  L17_2 = {}
  L18_2 = L3_2 - L12_2
  L17_2.x = L18_2
  L18_2 = L3_2 - L12_2
  L17_2.x2 = L18_2
  L14_2(L15_2, L16_2, L17_2)
  L15_2 = L6_2
  L14_2 = L6_2.SetAnimationPoint
  L16_2 = A0_2.CustomData
  L16_2 = L16_2.nMidEnd
  L17_2 = {}
  L18_2 = L1_2 + L12_2
  L17_2.x = L18_2
  L18_2 = L3_2 - L12_2
  L17_2.x2 = L18_2
  L14_2(L15_2, L16_2, L17_2)
  L15_2 = L6_2
  L14_2 = L6_2.SetLocation
  L16_2 = L3_2 - L12_2
  L17_2 = nil
  L18_2 = L3_2 - L12_2
  L19_2 = nil
  L14_2(L15_2, L16_2, L17_2, L18_2, L19_2)
  L15_2 = L6_2
  L14_2 = L6_2.AnimateToPoint
  L16_2 = A0_2.CustomData
  L16_2 = L16_2.nMidEnd
  L17_2 = L13_2
  L18_2 = true
  L14_2(L15_2, L16_2, L17_2, L18_2)
  L15_2 = L8_2
  L14_2 = L8_2.SetAnimationPoint
  L16_2 = A0_2.CustomData
  L16_2 = L16_2.nStartStart
  L17_2 = {}
  L18_2 = L12_2 * 2
  L18_2 = L3_2 - L18_2
  L17_2.x = L18_2
  L18_2 = L3_2 - L12_2
  L17_2.x2 = L18_2
  L14_2(L15_2, L16_2, L17_2)
  L15_2 = L8_2
  L14_2 = L8_2.SetAnimationPoint
  L16_2 = A0_2.CustomData
  L16_2 = L16_2.nStartEnd
  L17_2 = {}
  L17_2.x = L1_2
  L18_2 = L1_2 + L12_2
  L17_2.x2 = L18_2
  L14_2(L15_2, L16_2, L17_2)
  L15_2 = L8_2
  L14_2 = L8_2.SetLocation
  L16_2 = L12_2 * 2
  L16_2 = L3_2 - L16_2
  L17_2 = L3_2 - L12_2
  L14_2(L15_2, L16_2, L17_2)
  L15_2 = L8_2
  L14_2 = L8_2.AnimateToPoint
  L16_2 = A0_2.CustomData
  L16_2 = L16_2.nStartEnd
  L17_2 = L13_2
  L18_2 = true
  L19_2 = _ExecAnim
  L20_2 = {}
  L21_2 = L5_2
  L22_2 = A0_2.CustomData
  L22_2 = L22_2.nInfoEnd
  L23_2 = L13_2 * 0.5
  L20_2[1] = L21_2
  L20_2[2] = L22_2
  L20_2[3] = L23_2
  L14_2(L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
end

ShowInfoImage = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.sCurrentAnimation
  if "close" == L1_2 then
    return
  end
  L1_2 = A0_2.CustomData
  L1_2.sCurrentAnimation = "close"
  L2_2 = A0_2
  L1_2 = A0_2.GetLocation
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.oInfo
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.oMid
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.oEnd
  L8_2 = A0_2.CustomData
  L8_2 = L8_2.oStart
  L10_2 = L7_2
  L9_2 = L7_2.GetLocation
  L9_2, L10_2, L11_2 = L9_2(L10_2)
  L12_2 = L11_2 - L9_2
  L13_2 = 0.5
  L15_2 = L5_2
  L14_2 = L5_2.SetAnimationPoint
  L16_2 = A0_2.CustomData
  L16_2 = L16_2.nInfoStart
  L17_2 = {}
  L18_2 = L4_2 - 2
  L17_2.y = L18_2
  L18_2 = L4_2 - 2
  L17_2.y2 = L18_2
  L14_2(L15_2, L16_2, L17_2)
  L15_2 = L5_2
  L14_2 = L5_2.SetAnimationPoint
  L16_2 = A0_2.CustomData
  L16_2 = L16_2.nInfoEnd
  L17_2 = {}
  L17_2.y = L2_2
  L17_2.y2 = L4_2
  L14_2(L15_2, L16_2, L17_2)
  L15_2 = L5_2
  L14_2 = L5_2.SetLocation
  L16_2 = nil
  L17_2 = L2_2
  L18_2 = nil
  L19_2 = L4_2
  L14_2(L15_2, L16_2, L17_2, L18_2, L19_2)
  L15_2 = L5_2
  L14_2 = L5_2.AnimateToPoint
  L16_2 = A0_2.CustomData
  L16_2 = L16_2.nInfoStart
  L17_2 = L13_2 * 0.5
  L18_2 = true
  L19_2 = _ExecTwoAnims
  L20_2 = {}
  L21_2 = L6_2
  L22_2 = A0_2.CustomData
  L22_2 = L22_2.nMidStart
  L23_2 = L13_2
  L24_2 = L8_2
  L25_2 = A0_2.CustomData
  L25_2 = L25_2.nStartStart
  L26_2 = L13_2
  L27_2 = A0_2
  L20_2[1] = L21_2
  L20_2[2] = L22_2
  L20_2[3] = L23_2
  L20_2[4] = L24_2
  L20_2[5] = L25_2
  L20_2[6] = L26_2
  L20_2[7] = L27_2
  L14_2(L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
  L15_2 = L6_2
  L14_2 = L6_2.SetAnimationPoint
  L16_2 = A0_2.CustomData
  L16_2 = L16_2.nMidStart
  L17_2 = {}
  L18_2 = L3_2 - L12_2
  L17_2.x = L18_2
  L18_2 = L3_2 - L12_2
  L17_2.x2 = L18_2
  L14_2(L15_2, L16_2, L17_2)
  L15_2 = L6_2
  L14_2 = L6_2.SetAnimationPoint
  L16_2 = A0_2.CustomData
  L16_2 = L16_2.nMidEnd
  L17_2 = {}
  L18_2 = L1_2 + L12_2
  L17_2.x = L18_2
  L18_2 = L3_2 - L12_2
  L17_2.x2 = L18_2
  L14_2(L15_2, L16_2, L17_2)
  L15_2 = L6_2
  L14_2 = L6_2.AnimateToPoint
  L16_2 = A0_2.CustomData
  L16_2 = L16_2.nMidEnd
  L17_2 = 0
  L18_2 = true
  L14_2(L15_2, L16_2, L17_2, L18_2)
  L15_2 = L8_2
  L14_2 = L8_2.SetAnimationPoint
  L16_2 = A0_2.CustomData
  L16_2 = L16_2.nStartStart
  L17_2 = {}
  L18_2 = L12_2 * 2
  L18_2 = L3_2 - L18_2
  L17_2.x = L18_2
  L18_2 = L3_2 - L12_2
  L17_2.x2 = L18_2
  L14_2(L15_2, L16_2, L17_2)
  L15_2 = L8_2
  L14_2 = L8_2.SetAnimationPoint
  L16_2 = A0_2.CustomData
  L16_2 = L16_2.nStartEnd
  L17_2 = {}
  L17_2.x = L1_2
  L18_2 = L1_2 + L12_2
  L17_2.x2 = L18_2
  L14_2(L15_2, L16_2, L17_2)
  L15_2 = L8_2
  L14_2 = L8_2.AnimateToPoint
  L16_2 = A0_2.CustomData
  L16_2 = L16_2.nStartEnd
  L17_2 = 0
  L18_2 = true
  L14_2(L15_2, L16_2, L17_2, L18_2)
end

HideInfoImage = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  L5_2 = A1_2
  L4_2 = A1_2.AnimateToPoint
  L6_2 = A2_2
  L7_2 = A3_2
  L8_2 = true
  L4_2(L5_2, L6_2, L7_2, L8_2)
end

_ExecAnim = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2)
  local L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L9_2 = A1_2
  L8_2 = A1_2.AnimateToPoint
  L10_2 = A2_2
  L11_2 = A3_2
  L12_2 = true
  L8_2(L9_2, L10_2, L11_2, L12_2)
  L9_2 = A4_2
  L8_2 = A4_2.AnimateToPoint
  L10_2 = A5_2
  L11_2 = A6_2
  L12_2 = true
  L13_2 = _EndAnim
  L14_2 = {}
  L15_2 = A7_2
  L14_2[1] = L15_2
  L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
end

_ExecTwoAnims = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L3_2 = A1_2
  L2_2 = A1_2.SetTranslucency
  L4_2 = 0
  L2_2(L3_2, L4_2)
  L2_2 = A1_2.CustomData
  L2_2.bVisible = false
end

_EndAnim = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bVisible
  L3_2 = math
  L3_2 = L3_2.max
  L4_2 = A1_2
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nMinWidth
  L3_2 = L3_2(L4_2, L5_2)
  A1_2 = L3_2
  L4_2 = A0_2
  L3_2 = A0_2.GetLocation
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.oEnd
  L8_2 = L7_2
  L7_2 = L7_2.GetLocation
  L7_2, L8_2, L9_2 = L7_2(L8_2)
  L10_2 = L9_2 - L7_2
  L11_2 = A0_2.CustomData
  L11_2 = L11_2.oInfo
  L12_2 = L11_2
  L11_2 = L11_2.GetLocation
  L11_2, L12_2 = L11_2(L12_2)
  L13_2 = A0_2.CustomData
  L13_2 = L13_2.oStart
  L14_2 = L13_2
  L13_2 = L13_2.GetLocation
  L13_2 = L13_2(L14_2)
  L14_2 = A0_2.CustomData
  L14_2 = L14_2.oMid
  L15_2 = L14_2
  L14_2 = L14_2.GetLocation
  L14_2, L15_2, L16_2 = L14_2(L15_2)
  L18_2 = A0_2
  L17_2 = A0_2.SetLocation
  L19_2 = L5_2 - A1_2
  L20_2 = nil
  L21_2 = L5_2
  L22_2 = nil
  L17_2(L18_2, L19_2, L20_2, L21_2, L22_2)
  L17_2 = A0_2.CustomData
  L17_2 = L17_2.oInfo
  L18_2 = L17_2
  L17_2 = L17_2.SetLocation
  L19_2 = L5_2 - A1_2
  L20_2 = L4_2
  L17_2(L18_2, L19_2, L20_2)
  if L2_2 then
    L17_2 = A0_2.CustomData
    L17_2 = L17_2.oInfo
    L18_2 = L17_2
    L17_2 = L17_2.SetLocation
    L19_2 = L11_2
    L20_2 = L12_2
    L17_2(L18_2, L19_2, L20_2)
    L17_2 = A0_2.CustomData
    L17_2 = L17_2.oStart
    L18_2 = L17_2
    L17_2 = L17_2.SetLocation
    L19_2 = L13_2
    L17_2(L18_2, L19_2)
    L17_2 = A0_2.CustomData
    L17_2 = L17_2.oMid
    L18_2 = L17_2
    L17_2 = L17_2.SetLocation
    L19_2 = L14_2
    L20_2 = nil
    L21_2 = L16_2
    L17_2(L18_2, L19_2, L20_2, L21_2)
    L17_2 = PerformResizeAnimation
    L18_2 = A0_2
    L19_2 = A1_2
    L17_2(L18_2, L19_2)
  end
  L17_2 = A0_2.CustomData
  L17_2 = L17_2.oEnd
  L18_2 = L17_2
  L17_2 = L17_2.SetLocation
  L19_2 = L5_2 - L10_2
  L20_2 = nil
  L21_2 = L5_2
  L17_2(L18_2, L19_2, L20_2, L21_2)
end

ResizeInfoImage = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2
  L3_2 = A0_2
  L2_2 = A0_2.GetLocation
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.oInfo
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.oMid
  L8_2 = A0_2.CustomData
  L8_2 = L8_2.oEnd
  L9_2 = A0_2.CustomData
  L9_2 = L9_2.oStart
  L11_2 = L8_2
  L10_2 = L8_2.GetLocation
  L10_2, L11_2, L12_2 = L10_2(L11_2)
  L13_2 = L12_2 - L10_2
  L14_2 = 0.5
  L16_2 = L6_2
  L15_2 = L6_2.GetLocation
  L15_2, L16_2, L17_2 = L15_2(L16_2)
  L19_2 = L6_2
  L18_2 = L6_2.SetAnimationPoint
  L20_2 = A0_2.CustomData
  L20_2 = L20_2.nInfoEnd
  L21_2 = {}
  L21_2.x = L2_2
  L21_2.y = L3_2
  L22_2 = L17_2 - L15_2
  L22_2 = L2_2 + L22_2
  L21_2.x2 = L22_2
  L21_2.y2 = L5_2
  L18_2(L19_2, L20_2, L21_2)
  L19_2 = L6_2
  L18_2 = L6_2.AnimateToPoint
  L20_2 = A0_2.CustomData
  L20_2 = L20_2.nInfoEnd
  L21_2 = L14_2
  L22_2 = true
  L18_2(L19_2, L20_2, L21_2, L22_2)
  L19_2 = L7_2
  L18_2 = L7_2.SetAnimationPoint
  L20_2 = A0_2.CustomData
  L20_2 = L20_2.nMidEnd
  L21_2 = {}
  L22_2 = L2_2 + L13_2
  L21_2.x = L22_2
  L22_2 = L4_2 - L13_2
  L21_2.x2 = L22_2
  L18_2(L19_2, L20_2, L21_2)
  L19_2 = L7_2
  L18_2 = L7_2.AnimateToPoint
  L20_2 = A0_2.CustomData
  L20_2 = L20_2.nMidEnd
  L21_2 = L14_2
  L22_2 = true
  L18_2(L19_2, L20_2, L21_2, L22_2)
  L19_2 = L9_2
  L18_2 = L9_2.SetAnimationPoint
  L20_2 = A0_2.CustomData
  L20_2 = L20_2.nStartEnd
  L21_2 = {}
  L21_2.x = L2_2
  L22_2 = L2_2 + L13_2
  L21_2.x2 = L22_2
  L18_2(L19_2, L20_2, L21_2)
  L19_2 = L9_2
  L18_2 = L9_2.AnimateToPoint
  L20_2 = A0_2.CustomData
  L20_2 = L20_2.nStartEnd
  L21_2 = L14_2
  L22_2 = true
  L18_2(L19_2, L20_2, L21_2, L22_2)
end

PerformResizeAnimation = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L2_2 = MrxGuiBase
  L2_2 = L2_2.PushWidgetToFront
  L3_2 = L1_2[2]
  L2_2(L3_2)
  L2_2 = L1_2[1]
  L4_2 = L2_2
  L3_2 = L2_2.GetChildren
  L3_2 = L3_2(L4_2)
  L1_2 = L3_2
  L3_2 = MrxGuiBase
  L3_2 = L3_2.PushWidgetToFront
  L4_2 = L1_2[1]
  L3_2(L4_2)
  L3_2 = MrxGuiBase
  L3_2 = L3_2.PushWidgetToFront
  L4_2 = L1_2[2]
  L3_2(L4_2)
  L3_2 = MrxGuiBase
  L3_2 = L3_2.PushWidgetToFront
  L4_2 = L1_2[3]
  L3_2(L4_2)
  L3_2 = MrxGuiBase
  L3_2 = L3_2.PushWidgetToFront
  L4_2 = L1_2[4]
  L3_2(L4_2)
end

PushTutorialToFront = L0_1
