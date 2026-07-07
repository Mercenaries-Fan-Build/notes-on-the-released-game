local L0_1, L1_1, L2_1, L3_1
L0_1 = import
L1_1 = "MrxGuiBase"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = "english_18"
_ksFont = L0_1
L0_1 = 1
_knScale = L0_1
L0_1 = 156
_knTextR = L0_1
L0_1 = 154
_knTextG = L0_1
L0_1 = 133
_knTextB = L0_1
L0_1 = 210
_knTextLitR = L0_1
L0_1 = 210
_knTextLitG = L0_1
L0_1 = 190
_knTextLitB = L0_1
L0_1 = "ui_PDA_Accept"
_ksAcceptSound = L0_1
L0_1 = "ui_PDA_Cancel"
_ksCancelSound = L0_1
L0_1 = "ui_PDA_Scroll"
_ksChangeSound = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2, A9_2, A10_2, A11_2)
  local L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2
  L12_2 = type
  L13_2 = A1_2
  L12_2 = L12_2(L13_2)
  if "string" ~= L12_2 then
    return
  end
  L12_2 = type
  L13_2 = A2_2
  L12_2 = L12_2(L13_2)
  if "table" ~= L12_2 then
    return
  end
  L12_2 = table
  L12_2 = L12_2.getn
  L13_2 = A2_2
  L12_2 = L12_2(L13_2)
  if L12_2 < 1 then
    A2_2[1] = "[Generic.Ok]"
  end
  L12_2 = _ValidateParameter
  L13_2 = A3_2
  L14_2 = "number"
  L15_2 = 1
  L12_2 = L12_2(L13_2, L14_2, L15_2)
  A3_2 = L12_2
  L12_2 = _ValidateParameter
  L13_2 = A4_2
  L14_2 = "function"
  L15_2 = nil
  L12_2 = L12_2(L13_2, L14_2, L15_2)
  A4_2 = L12_2
  L12_2 = _ValidateParameter
  L13_2 = A5_2
  L14_2 = "table"
  L15_2 = {}
  L12_2 = L12_2(L13_2, L14_2, L15_2)
  A5_2 = L12_2
  L12_2 = _ValidateParameter
  L13_2 = A11_2
  L14_2 = "number"
  L15_2 = nil
  L12_2 = L12_2(L13_2, L14_2, L15_2)
  A11_2 = L12_2
  if nil == A10_2 then
    A10_2 = true
  end
  L12_2 = _BuildDialogBox
  L13_2 = A1_2
  L14_2 = A2_2
  L15_2 = A3_2
  L16_2 = A4_2
  L17_2 = A5_2
  L18_2 = A0_2
  L19_2 = A6_2
  L20_2 = A7_2
  L21_2 = A8_2
  L22_2 = A9_2
  L23_2 = A11_2
  L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2)
  L14_2 = L12_2
  L13_2 = L12_2.SetOwner
  L15_2 = A0_2
  L13_2(L14_2, L15_2)
  L13_2 = MrxGuiBase
  L13_2 = L13_2.GetControlFocus
  L14_2 = L12_2
  L15_2 = A10_2
  L13_2(L14_2, L15_2)
  L13_2 = Close
  L12_2.Close = L13_2
  return L12_2
end

DisplayDialogBox = L0_1

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
  L2_2 = A0_2
  L1_2 = A0_2.DeleteWithChildren
  L1_2(L2_2)
end

Close = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2, A9_2, A10_2)
  local L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2, L47_2, L48_2, L49_2, L50_2, L51_2
  L11_2 = 170
  L12_2 = 100
  L13_2 = 298
  L14_2 = 10
  L15_2 = 20
  L16_2 = L15_2 + L12_2
  L17_2 = MrxGuiBase
  L17_2 = L17_2.ImageWidget
  L18_2 = L17_2
  L17_2 = L17_2.new
  L17_2 = L17_2(L18_2)
  L19_2 = L17_2
  L18_2 = L17_2.SetLocation
  L20_2 = L11_2
  L21_2 = L12_2
  L22_2 = L11_2 + L13_2
  L23_2 = 400
  L18_2(L19_2, L20_2, L21_2, L22_2, L23_2)
  L18_2 = L17_2.BasicData
  L18_2.bContainer = true
  L19_2 = L17_2
  L18_2 = L17_2.SetOwner
  L20_2 = A5_2
  L18_2(L19_2, L20_2)
  L19_2 = L17_2
  L18_2 = L17_2.SetVisible
  L20_2 = false
  L18_2(L19_2, L20_2)
  L18_2 = MrxGuiBase
  L18_2 = L18_2.TextWidget
  L19_2 = L18_2
  L18_2 = L18_2.new
  L18_2 = L18_2(L19_2)
  L20_2 = L18_2
  L19_2 = L18_2.SetLocation
  L21_2 = L11_2 + L14_2
  L22_2 = L12_2 + L15_2
  L23_2 = L11_2 + L13_2
  L23_2 = L23_2 - L14_2
  L24_2 = 390
  L19_2(L20_2, L21_2, L22_2, L23_2, L24_2)
  L20_2 = L18_2
  L19_2 = L18_2.SetFont
  L21_2 = _ksFont
  L19_2(L20_2, L21_2)
  L20_2 = L18_2
  L19_2 = L18_2.SetScale
  L21_2 = _knScale
  L19_2(L20_2, L21_2)
  L20_2 = L18_2
  L19_2 = L18_2.SetColor
  L21_2 = _knTextLitR
  L22_2 = _knTextLitG
  L23_2 = _knTextLitB
  L19_2(L20_2, L21_2, L22_2, L23_2)
  L20_2 = L18_2
  L19_2 = L18_2.SetText
  L21_2 = A0_2
  L19_2(L20_2, L21_2)
  L20_2 = L18_2
  L19_2 = L18_2.Wrap
  L19_2(L20_2)
  L20_2 = L18_2
  L19_2 = L18_2.SetOwner
  L21_2 = A5_2
  L19_2(L20_2, L21_2)
  L18_2.ParentWidget = L17_2
  L20_2 = L18_2
  L19_2 = L18_2.GetHeight
  L19_2 = L19_2(L20_2)
  L19_2 = L16_2 + L19_2
  L16_2 = L19_2 + 4
  L19_2 = MrxGuiBase
  L19_2 = L19_2.ImageWidget
  L20_2 = L19_2
  L19_2 = L19_2.new
  L19_2 = L19_2(L20_2)
  L21_2 = L19_2
  L20_2 = L19_2.SetColor
  L22_2 = 84
  L23_2 = 79
  L24_2 = 57
  L20_2(L21_2, L22_2, L23_2, L24_2)
  L21_2 = L19_2
  L20_2 = L19_2.SetTranslucency
  L22_2 = 205
  L20_2(L21_2, L22_2)
  L21_2 = L19_2
  L20_2 = L19_2.SetLocation
  L22_2 = L11_2 + L14_2
  L23_2 = 1
  L24_2 = L11_2 + L13_2
  L24_2 = L24_2 - L14_2
  L25_2 = 2
  L20_2(L21_2, L22_2, L23_2, L24_2, L25_2)
  L21_2 = L19_2
  L20_2 = L19_2.SetOwner
  L22_2 = A5_2
  L20_2(L21_2, L22_2)
  L19_2.ParentWidget = L17_2
  L20_2 = L19_2.CustomData
  L22_2 = L19_2
  L21_2 = L19_2.AddAnimationPoint
  L23_2 = {}
  L23_2.y = 1
  L23_2.y2 = 1
  L21_2 = L21_2(L22_2, L23_2)
  L20_2.nClosePoint = L21_2
  L20_2 = L19_2.CustomData
  L22_2 = L19_2
  L21_2 = L19_2.AddAnimationPoint
  L23_2 = {}
  L23_2.y = 1
  L23_2.y2 = 1
  L21_2 = L21_2(L22_2, L23_2)
  L20_2.nOpenPoint = L21_2
  L20_2 = L19_2.CustomData
  L22_2 = L19_2
  L21_2 = L19_2.AddAnimationPoint
  L23_2 = {}
  L23_2.TranslucencyLevel = 255
  L21_2 = L21_2(L22_2, L23_2)
  L20_2.nPulseHighPoint = L21_2
  L20_2 = L19_2.CustomData
  L22_2 = L19_2
  L21_2 = L19_2.AddAnimationPoint
  L23_2 = {}
  L23_2.TranslucencyLevel = 100
  L21_2 = L21_2(L22_2, L23_2)
  L20_2.nPulseLowPoint = L21_2
  L21_2 = L19_2
  L20_2 = L19_2.SetIgnoresPause
  L22_2 = true
  L20_2(L21_2, L22_2)
  L20_2 = MrxGuiBase
  L20_2 = L20_2.ImageWidget
  L21_2 = L20_2
  L20_2 = L20_2.new
  L20_2 = L20_2(L21_2)
  L22_2 = L20_2
  L21_2 = L20_2.SetTranslucency
  L23_2 = 0
  L21_2(L22_2, L23_2)
  L22_2 = L20_2
  L21_2 = L20_2.SetLocation
  L23_2 = L11_2 + L14_2
  L24_2 = L16_2
  L25_2 = L11_2 + L13_2
  L25_2 = L25_2 - L14_2
  L26_2 = L16_2 + 200
  L21_2(L22_2, L23_2, L24_2, L25_2, L26_2)
  L22_2 = L20_2
  L21_2 = L20_2.SetOwner
  L23_2 = A5_2
  L21_2(L22_2, L23_2)
  L20_2.ParentWidget = L17_2
  L21_2 = 50
  L22_2 = 1
  while "string" do
    L23_2 = type
    L24_2 = A1_2[L22_2]
    L23_2 = L23_2(L24_2)
    if "string" ~= L23_2 then
      break
    end
    L23_2 = MrxGuiBase
    L23_2 = L23_2.TextWidget
    L24_2 = L23_2
    L23_2 = L23_2.new
    L23_2 = L23_2(L24_2)
    L25_2 = L23_2
    L24_2 = L23_2.SetLocation
    L26_2 = L11_2 + L21_2
    L27_2 = L16_2
    L28_2 = L11_2 + L13_2
    L28_2 = L28_2 - L14_2
    L29_2 = L16_2
    L24_2(L25_2, L26_2, L27_2, L28_2, L29_2)
    L25_2 = L23_2
    L24_2 = L23_2.SetFont
    L26_2 = _ksFont
    L24_2(L25_2, L26_2)
    L25_2 = L23_2
    L24_2 = L23_2.SetScale
    L26_2 = _knScale
    L24_2(L25_2, L26_2)
    L25_2 = L23_2
    L24_2 = L23_2.SetColor
    L26_2 = _knTextR
    L27_2 = _knTextG
    L28_2 = _knTextB
    L24_2(L25_2, L26_2, L27_2, L28_2)
    L25_2 = L23_2
    L24_2 = L23_2.SetText
    L26_2 = A1_2[L22_2]
    L24_2(L25_2, L26_2)
    L25_2 = L23_2
    L24_2 = L23_2.Wrap
    L24_2(L25_2)
    L25_2 = L23_2
    L24_2 = L23_2.SetOwner
    L26_2 = A5_2
    L24_2(L25_2, L26_2)
    L23_2.ParentWidget = L20_2
    L25_2 = L20_2
    L24_2 = L20_2.AddChild
    L26_2 = L23_2
    L24_2(L25_2, L26_2)
    L24_2 = L23_2.CustomData
    L26_2 = L23_2
    L25_2 = L23_2.GetHeight
    L25_2 = L25_2(L26_2)
    L24_2.nHeight = L25_2
    L22_2 = L22_2 + 1
    L24_2 = L23_2.CustomData
    L24_2 = L24_2.nHeight
    L24_2 = L16_2 + L24_2
    L16_2 = L24_2 + 2
  end
  if 1 == L22_2 then
    L24_2 = L17_2
    L23_2 = L17_2.DeleteWithChildren
    L23_2(L24_2)
    L23_2 = nil
    return L23_2
  end
  L24_2 = L20_2
  L23_2 = L20_2.GetChildren
  L23_2 = L23_2(L24_2)
  L23_2 = L23_2[A2_2]
  if not L23_2 then
    A2_2 = 1
  end
  L23_2 = L17_2.CustomData
  L23_2.nSelectedIndex = A2_2
  L24_2 = L20_2
  L23_2 = L20_2.GetChildren
  L23_2 = L23_2(L24_2)
  L24_2 = L17_2.CustomData
  L24_2 = L24_2.nSelectedIndex
  L23_2 = L23_2[L24_2]
  L25_2 = L23_2
  L24_2 = L23_2.GetLocation
  L24_2, L25_2 = L24_2(L25_2)
  L27_2 = L19_2
  L26_2 = L19_2.SetLocation
  L28_2 = nil
  L29_2 = L25_2
  L30_2 = nil
  L31_2 = L23_2.CustomData
  L31_2 = L31_2.nHeight
  L31_2 = L25_2 + L31_2
  L26_2(L27_2, L28_2, L29_2, L30_2, L31_2)
  L27_2 = L23_2
  L26_2 = L23_2.SetColor
  L28_2 = _knTextLitR
  L29_2 = _knTextLitG
  L30_2 = _knTextLitB
  L26_2(L27_2, L28_2, L29_2, L30_2)
  L26_2 = MrxGuiBase
  L26_2 = L26_2.TextWidget
  L27_2 = L26_2
  L26_2 = L26_2.new
  L26_2 = L26_2(L27_2)
  L16_2 = L16_2 + 8
  L28_2 = L26_2
  L27_2 = L26_2.SetLocation
  L29_2 = L11_2 + L14_2
  L30_2 = L16_2
  L31_2 = L11_2 + L13_2
  L31_2 = L31_2 - L14_2
  L32_2 = L16_2
  L27_2(L28_2, L29_2, L30_2, L31_2, L32_2)
  L28_2 = L26_2
  L27_2 = L26_2.SetFont
  L29_2 = _ksFont
  L27_2(L28_2, L29_2)
  L28_2 = L26_2
  L27_2 = L26_2.SetScale
  L29_2 = _knScale
  L27_2(L28_2, L29_2)
  L28_2 = L26_2
  L27_2 = L26_2.SetColor
  L29_2 = _knTextR
  L30_2 = _knTextG
  L31_2 = _knTextB
  L27_2(L28_2, L29_2, L30_2, L31_2)
  L28_2 = L26_2
  L27_2 = L26_2.SetJustification
  L29_2 = "center"
  L27_2(L28_2, L29_2)
  L27_2 = #A1_2
  if 1 < L27_2 then
    L28_2 = L26_2
    L27_2 = L26_2.SetText
    L29_2 = "[move] [PDA.Common.MoveSelection]  [confirm] [Generic.Confirm]"
    L27_2(L28_2, L29_2)
  else
    L28_2 = L26_2
    L27_2 = L26_2.SetText
    L29_2 = "[confirm] [Generic.Confirm]"
    L27_2(L28_2, L29_2)
  end
  L28_2 = L26_2
  L27_2 = L26_2.SetOwner
  L29_2 = A5_2
  L27_2(L28_2, L29_2)
  L26_2.ParentWidget = L17_2
  L27_2 = L26_2.CustomData
  L29_2 = L26_2
  L28_2 = L26_2.GetHeight
  L28_2 = L28_2(L29_2)
  L27_2.nHeight = L28_2
  L27_2 = L26_2.CustomData
  L27_2 = L27_2.nHeight
  L27_2 = L16_2 + L27_2
  L16_2 = L27_2 - 8
  L27_2 = {}
  L28_2 = 0
  L29_2 = 0.8730469
  L30_2 = 0
  L31_2 = 0.078125
  L32_2 = 0.083984375
  L33_2 = 0.17382812
  L34_2 = 0.1796875
  L35_2 = 0.2734375
  L36_2 = 0.6666667
  L37_2 = 447 * L36_2
  L38_2 = 48 * L36_2
  L39_2 = 46 * L36_2
  L40_2 = 48 * L36_2
  L41_2 = L16_2 - L12_2
  L42_2 = "global_gui_hud02"
  L43_2 = L12_2
  L44_2 = 2
  L45_2 = MrxGuiBase
  L45_2 = L45_2.ImageWidget
  L46_2 = L45_2
  L45_2 = L45_2.new
  L45_2 = L45_2(L46_2)
  L27_2[1] = L45_2
  L45_2 = L27_2[1]
  L46_2 = L45_2
  L45_2 = L45_2.SetTexture
  L47_2 = L42_2
  L45_2(L46_2, L47_2)
  L45_2 = L27_2[1]
  L46_2 = L45_2
  L45_2 = L45_2.SetLocation
  L47_2 = L11_2
  L48_2 = L43_2
  L49_2 = L11_2 + L37_2
  L50_2 = L43_2 + L38_2
  L45_2(L46_2, L47_2, L48_2, L49_2, L50_2)
  L45_2 = L27_2[1]
  L46_2 = L45_2
  L45_2 = L45_2.SetTextureCoordinates
  L47_2 = L28_2
  L48_2 = L35_2
  L49_2 = L29_2
  L50_2 = L34_2
  L45_2(L46_2, L47_2, L48_2, L49_2, L50_2)
  L45_2 = L27_2[1]
  L46_2 = L45_2
  L45_2 = L45_2.SetOwner
  L47_2 = A5_2
  L45_2(L46_2, L47_2)
  L41_2 = L41_2 - L38_2
  L43_2 = L43_2 + L38_2
  L45_2 = 20 * L36_2
  L45_2 = L40_2 - L45_2
  L45_2 = L41_2 - L45_2
  L39_2 = L45_2 + L15_2
  L45_2 = MrxGuiBase
  L45_2 = L45_2.ImageWidget
  L46_2 = L45_2
  L45_2 = L45_2.new
  L45_2 = L45_2(L46_2)
  L27_2[L44_2] = L45_2
  L45_2 = L27_2[L44_2]
  L46_2 = L45_2
  L45_2 = L45_2.SetTexture
  L47_2 = L42_2
  L45_2(L46_2, L47_2)
  L45_2 = L27_2[L44_2]
  L46_2 = L45_2
  L45_2 = L45_2.SetLocation
  L47_2 = L11_2
  L48_2 = L43_2
  L49_2 = L11_2 + L37_2
  L50_2 = L43_2 + L39_2
  L45_2(L46_2, L47_2, L48_2, L49_2, L50_2)
  L45_2 = L27_2[L44_2]
  L46_2 = L45_2
  L45_2 = L45_2.SetTextureCoordinates
  L47_2 = L28_2
  L48_2 = L32_2
  L49_2 = L29_2
  L50_2 = L33_2
  L45_2(L46_2, L47_2, L48_2, L49_2, L50_2)
  L45_2 = L27_2[L44_2]
  L46_2 = L45_2
  L45_2 = L45_2.SetOwner
  L47_2 = A5_2
  L45_2(L46_2, L47_2)
  L41_2 = L41_2 - L39_2
  L43_2 = L43_2 + L39_2
  L44_2 = L44_2 + 1
  L45_2 = MrxGuiBase
  L45_2 = L45_2.ImageWidget
  L46_2 = L45_2
  L45_2 = L45_2.new
  L45_2 = L45_2(L46_2)
  L27_2[L44_2] = L45_2
  L45_2 = L27_2[L44_2]
  L46_2 = L45_2
  L45_2 = L45_2.SetTexture
  L47_2 = L42_2
  L45_2(L46_2, L47_2)
  L45_2 = L27_2[L44_2]
  L46_2 = L45_2
  L45_2 = L45_2.SetLocation
  L47_2 = L11_2
  L48_2 = L43_2
  L49_2 = L11_2 + L37_2
  L50_2 = L43_2 + L40_2
  L45_2(L46_2, L47_2, L48_2, L49_2, L50_2)
  L45_2 = L27_2[L44_2]
  L46_2 = L45_2
  L45_2 = L45_2.SetTextureCoordinates
  L47_2 = L28_2
  L48_2 = L34_2
  L49_2 = L29_2
  L50_2 = L35_2
  L45_2(L46_2, L47_2, L48_2, L49_2, L50_2)
  L45_2 = L27_2[L44_2]
  L46_2 = L45_2
  L45_2 = L45_2.SetOwner
  L47_2 = A5_2
  L45_2(L46_2, L47_2)
  L43_2 = L43_2 + L40_2
  L44_2 = 1
  while true do
    L45_2 = L27_2[L44_2]
    if not L45_2 then
      break
    end
    L46_2 = L17_2
    L45_2 = L17_2.AddChild
    L47_2 = L27_2[L44_2]
    L45_2(L46_2, L47_2)
    L44_2 = L44_2 + 1
  end
  L46_2 = L17_2
  L45_2 = L17_2.AddChild
  L47_2 = L18_2
  L45_2(L46_2, L47_2)
  L46_2 = L17_2
  L45_2 = L17_2.AddChild
  L47_2 = L19_2
  L45_2(L46_2, L47_2)
  L46_2 = L17_2
  L45_2 = L17_2.AddChild
  L47_2 = L20_2
  L45_2(L46_2, L47_2)
  L46_2 = L17_2
  L45_2 = L17_2.AddChild
  L47_2 = L26_2
  L45_2(L46_2, L47_2)
  L45_2 = L17_2.CustomData
  L45_2.oCursor = L19_2
  L45_2 = L17_2.CustomData
  L45_2.oOptions = L20_2
  L45_2 = L17_2.CustomData
  L45_2.fCallback = A3_2
  L45_2 = L17_2.CustomData
  L45_2.tCallbackArgs = A4_2
  L45_2 = L17_2.CustomData
  L45_2.nCancelOption = A10_2
  L45_2 = L43_2 - L12_2
  L46_2 = L45_2 / 2
  L12_2 = 240 - L46_2
  if L12_2 < 0 then
    L12_2 = 0
  end
  L47_2 = L17_2
  L46_2 = L17_2.SetLocation
  L48_2 = L11_2
  L49_2 = L12_2
  L46_2(L47_2, L48_2, L49_2)
  L47_2 = L17_2
  L46_2 = L17_2.SetCoordinates
  L48_2 = L11_2
  L49_2 = L12_2
  L50_2 = L11_2 + L13_2
  L51_2 = L12_2 + L45_2
  L46_2(L47_2, L48_2, L49_2, L50_2, L51_2)
  if A6_2 and A7_2 and A8_2 and A9_2 then
    L41_2 = L45_2
    L46_2 = nil
    L47_2 = nil
    if "left" == A8_2 then
      if A6_2 < 48 then
        A6_2 = 48
      end
      L46_2 = A6_2
    elseif "right" == A8_2 then
      if A6_2 < 48 then
        A6_2 = 48
      end
      L48_2 = 640 - L13_2
      L46_2 = L48_2 - A6_2
    elseif "center" == A8_2 then
      L48_2 = L13_2 * 0.5
      L48_2 = A6_2 - L48_2
      L46_2 = L48_2 + 320
      if L46_2 < 48 then
        L46_2 = 48
      else
        L48_2 = 592 - L13_2
        if L46_2 > L48_2 then
          L46_2 = 592 - L13_2
        end
      end
    end
    if "top" == A9_2 then
      if A7_2 < 36 then
        A7_2 = 36
      end
      L47_2 = A7_2
    elseif "bottom" == A9_2 then
      if A7_2 < 36 then
        A7_2 = 36
      end
      L48_2 = 480 - L41_2
      L47_2 = L48_2 - A7_2
    elseif "center" == A9_2 then
      L48_2 = L41_2 * 0.5
      L48_2 = A7_2 - L48_2
      L47_2 = L48_2 + 240
      if L47_2 < 36 then
        L47_2 = 36
      else
        L48_2 = 444 - L41_2
        if L47_2 > L48_2 then
          L47_2 = 444 - L41_2
        end
      end
    end
    L49_2 = L17_2
    L48_2 = L17_2.SetAnchoring
    L50_2 = A8_2
    L51_2 = A9_2
    L48_2(L49_2, L50_2, L51_2)
    L49_2 = L17_2
    L48_2 = L17_2.SetLocation
    L50_2 = L46_2
    L51_2 = L47_2
    L48_2(L49_2, L50_2, L51_2)
  end
  L46_2 = MrxGuiBase
  L46_2 = L46_2.AddWidgetWithChildren
  L47_2 = L17_2
  L46_2(L47_2)
  L47_2 = L17_2
  L46_2 = L17_2.SetEventHandler
  L48_2 = "ControllerInput"
  L49_2 = _HandleInputEvent
  L46_2(L47_2, L48_2, L49_2)
  L46_2 = _ChangeSelection
  L17_2._ChangeSelection = L46_2
  L46_2 = Pulse
  L47_2 = L19_2
  L46_2(L47_2)
  return L17_2
end

_BuildDialogBox = L0_1
L0_1 = 0.5
_knPulseTime = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.GetTranslucency
  L1_2 = L1_2(L2_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bRising
  if L2_2 then
    L2_2 = 255 - L1_2
    L2_2 = L2_2 / 255
    L3_2 = _knPulseTime
    L2_2 = L2_2 * L3_2
    L4_2 = A0_2
    L3_2 = A0_2.AnimateToPoint
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.nPulseHighPoint
    L6_2 = L2_2
    L7_2 = true
    L8_2 = _LoopToLow
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  else
    L2_2 = L1_2 - 100
    L2_2 = L2_2 / 255
    L3_2 = _knPulseTime
    L2_2 = L2_2 * L3_2
    L4_2 = A0_2
    L3_2 = A0_2.AnimateToPoint
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.nPulseLowPoint
    L6_2 = L2_2
    L7_2 = true
    L8_2 = _LoopToHigh
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  end
end

Pulse = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = A0_2.CustomData
  L1_2.bRising = true
  L2_2 = A0_2
  L1_2 = A0_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nPulseHighPoint
  L4_2 = _knPulseTime
  L5_2 = true
  L6_2 = _LoopToLow
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

_LoopToHigh = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = A0_2.CustomData
  L1_2.bRising = false
  L2_2 = A0_2
  L1_2 = A0_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nPulseLowPoint
  L4_2 = _knPulseTime
  L5_2 = true
  L6_2 = _LoopToHigh
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

_LoopToLow = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = A0_2.CustomData
  L1_2.bRising = false
  L1_2 = bImmediate
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.GetTranslucency
    L1_2 = L1_2(L2_2)
    L2_2 = 255 - L1_2
    L2_2 = L2_2 / 255
    L3_2 = _knPulseTime
    L2_2 = L2_2 * L3_2
    L4_2 = A0_2
    L3_2 = A0_2.AnimateToPoint
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.nPulseHighPoint
    L6_2 = L2_2
    L7_2 = true
    L3_2(L4_2, L5_2, L6_2, L7_2)
  else
    L2_2 = A0_2
    L1_2 = A0_2.AnimateToPoint
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.nPulseHighPoint
    L4_2 = 0
    L5_2 = true
    L1_2(L2_2, L3_2, L4_2, L5_2)
  end
end

HaltPulse = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2
  L2_2 = 1
  if A1_2 then
    L2_2 = -1
  end
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oOptions
  L4_2 = L3_2
  L3_2 = L3_2.GetChildren
  L3_2 = L3_2(L4_2)
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nSelectedIndex
  L4_2 = L3_2[L4_2]
  L6_2 = L4_2
  L5_2 = L4_2.SetColor
  L7_2 = _knTextR
  L8_2 = _knTextG
  L9_2 = _knTextB
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L5_2 = A0_2.CustomData
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.nSelectedIndex
  L6_2 = L6_2 + L2_2
  L5_2.nSelectedIndex = L6_2
  if A1_2 then
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.nSelectedIndex
    if L5_2 < 1 then
      L5_2 = A0_2.CustomData
      L6_2 = #L3_2
      L5_2.nSelectedIndex = L6_2
    end
  else
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.nSelectedIndex
    L5_2 = L3_2[L5_2]
    if not L5_2 then
      L5_2 = A0_2.CustomData
      L5_2.nSelectedIndex = 1
    end
  end
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nSelectedIndex
  L5_2 = L3_2[L5_2]
  L7_2 = L4_2
  L6_2 = L4_2.GetLocation
  L6_2, L7_2 = L6_2(L7_2)
  L8_2 = L4_2.CustomData
  L8_2 = L8_2.nHeight
  L8_2 = L7_2 + L8_2
  L10_2 = L5_2
  L9_2 = L5_2.GetLocation
  L9_2, L10_2 = L9_2(L10_2)
  L11_2 = L5_2.CustomData
  L11_2 = L11_2.nHeight
  L11_2 = L10_2 + L11_2
  L12_2 = A0_2.CustomData
  L12_2 = L12_2.oCursor
  L14_2 = L12_2
  L13_2 = L12_2.GetLocation
  L13_2, L14_2, L15_2, L16_2 = L13_2(L14_2)
  L17_2 = L14_2 + L16_2
  L17_2 = L17_2 * 0.5
  L19_2 = L12_2
  L18_2 = L12_2.SetAnimationPoint
  L20_2 = L12_2.CustomData
  L20_2 = L20_2.nClosePoint
  L21_2 = {}
  L21_2.y = L17_2
  L21_2.y2 = L17_2
  L18_2(L19_2, L20_2, L21_2)
  L19_2 = L12_2
  L18_2 = L12_2.SetAnimationPoint
  L20_2 = L12_2.CustomData
  L20_2 = L20_2.nOpenPoint
  L21_2 = {}
  L21_2.y = L10_2
  L21_2.y2 = L11_2
  L18_2(L19_2, L20_2, L21_2)
  L19_2 = L12_2
  L18_2 = L12_2.SetLocation
  L20_2 = nil
  L21_2 = L7_2
  L22_2 = nil
  L23_2 = L8_2
  L18_2(L19_2, L20_2, L21_2, L22_2, L23_2)
  L19_2 = L12_2
  L18_2 = L12_2.AnimateToPoint
  L20_2 = L12_2.CustomData
  L20_2 = L20_2.nClosePoint
  L21_2 = 0.075
  L22_2 = true
  L23_2 = _CompleteAnimation
  L24_2 = {}
  L25_2 = L10_2
  L26_2 = L11_2
  L27_2 = L5_2
  L24_2[1] = L25_2
  L24_2[2] = L26_2
  L24_2[3] = L27_2
  L18_2(L19_2, L20_2, L21_2, L22_2, L23_2, L24_2)
end

_ChangeSelection = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L4_2 = A1_2 + A2_2
  L4_2 = L4_2 * 0.5
  L6_2 = A0_2
  L5_2 = A0_2.SetLocation
  L7_2 = nil
  L8_2 = L4_2
  L9_2 = nil
  L10_2 = L4_2
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L6_2 = A0_2
  L5_2 = A0_2.SetAnimationPoint
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.nOpenPoint
  L8_2 = {}
  L8_2.y = A1_2
  L8_2.y2 = A2_2
  L5_2(L6_2, L7_2, L8_2)
  L6_2 = A0_2
  L5_2 = A0_2.AnimateToPoint
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.nOpenPoint
  L8_2 = 0.075
  L9_2 = true
  L10_2 = Pulse
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L6_2 = A3_2
  L5_2 = A3_2.SetColor
  L7_2 = _knTextLitR
  L8_2 = _knTextLitG
  L9_2 = _knTextLitB
  L5_2(L6_2, L7_2, L8_2, L9_2)
end

_CompleteAnimation = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = MrxGuiBase
  L2_2 = L2_2.Joystick
  L2_2 = L2_2.BUTTON_PAD1_D
  L3_2 = A1_2.ButtonPress
  if L2_2 ~= L3_2 then
    L2_2 = MrxGuiBase
    L2_2 = L2_2.Joystick
    L2_2 = L2_2.BUTTON_L_STICK_D
    L3_2 = A1_2.ButtonPress
    if L2_2 ~= L3_2 then
      goto lbl_22
    end
  end
  L3_2 = A0_2
  L2_2 = A0_2._ChangeSelection
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = Sound
  L2_2 = L2_2.CueSound
  L3_2 = 0
  L4_2 = _ksChangeSound
  L2_2(L3_2, L4_2)
  goto lbl_80
  ::lbl_22::
  L2_2 = MrxGuiBase
  L2_2 = L2_2.Joystick
  L2_2 = L2_2.BUTTON_PAD1_U
  L3_2 = A1_2.ButtonPress
  if L2_2 ~= L3_2 then
    L2_2 = MrxGuiBase
    L2_2 = L2_2.Joystick
    L2_2 = L2_2.BUTTON_L_STICK_U
    L3_2 = A1_2.ButtonPress
    if L2_2 ~= L3_2 then
      goto lbl_43
    end
  end
  L3_2 = A0_2
  L2_2 = A0_2._ChangeSelection
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = Sound
  L2_2 = L2_2.CueSound
  L3_2 = 0
  L4_2 = _ksChangeSound
  L2_2(L3_2, L4_2)
  goto lbl_80
  ::lbl_43::
  L2_2 = MrxGuiBase
  L2_2 = L2_2.Joystick
  L2_2 = L2_2.BUTTON_PAD2_D
  L3_2 = A1_2.ButtonPress
  if L2_2 == L3_2 then
    L2_2 = _CloseAndCallCallback
    L3_2 = A0_2
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.nSelectedIndex
    L2_2(L3_2, L4_2)
    L2_2 = Sound
    L2_2 = L2_2.CueSound
    L3_2 = 0
    L4_2 = _ksAcceptSound
    L2_2(L3_2, L4_2)
  else
    L2_2 = MrxGuiBase
    L2_2 = L2_2.Joystick
    L2_2 = L2_2.BUTTON_PAD2_R
    L3_2 = A1_2.ButtonPress
    if L2_2 == L3_2 then
      L2_2 = A0_2.CustomData
      L2_2 = L2_2.nCancelOption
      if L2_2 then
        L2_2 = _CloseAndCallCallback
        L3_2 = A0_2
        L4_2 = A0_2.CustomData
        L4_2 = L4_2.nCancelOption
        L2_2(L3_2, L4_2)
        L2_2 = Sound
        L2_2 = L2_2.CueSound
        L3_2 = 0
        L4_2 = _ksCancelSound
        L2_2(L3_2, L4_2)
      end
    end
  end
  ::lbl_80::
end

_HandleInputEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = MrxGuiBase
  L2_2 = L2_2.ReleaseControlFocus
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.fCallback
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.tCallbackArgs
  L5_2 = A0_2
  L4_2 = A0_2.Close
  L4_2(L5_2)
  if L2_2 then
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L3_2
    L6_2 = A1_2
    L4_2(L5_2, L6_2)
    L4_2 = L2_2
    L5_2 = unpack
    L6_2 = L3_2
    L5_2, L6_2 = L5_2(L6_2)
    L4_2(L5_2, L6_2)
  end
end

_CloseAndCallCallback = L0_1
L0_1 = 10
L1_1 = 200
L2_1 = 100

function L3_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2)
  local L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L8_2 = type
  L9_2 = A0_2
  L8_2 = L8_2(L9_2)
  if "userdata" ~= L8_2 then
    return
  end
  L8_2 = type
  L9_2 = A1_2
  L8_2 = L8_2(L9_2)
  if "string" ~= L8_2 then
    return
  end
  L8_2 = _BuildScrollingDialogBox
  L9_2 = A0_2
  L10_2 = A1_2
  L11_2 = A4_2
  L12_2 = A2_2
  L13_2 = A3_2
  L14_2 = A5_2
  L15_2 = A6_2
  L16_2 = A7_2
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
  L10_2 = L8_2
  L9_2 = L8_2.GetLocation
  L9_2, L10_2, L11_2, L12_2 = L9_2(L10_2)
  L13_2 = L11_2 - L9_2
  L13_2 = L13_2 * 0.5
  L13_2 = 320 - L13_2
  L14_2 = L12_2 - L10_2
  L14_2 = L14_2 * 0.5
  L14_2 = 240 - L14_2
  L16_2 = L8_2
  L15_2 = L8_2.SetLocation
  L17_2 = L13_2
  L18_2 = L14_2
  L15_2(L16_2, L17_2, L18_2)
  L16_2 = L8_2
  L15_2 = L8_2.SetAnchoring
  L17_2 = "center"
  L18_2 = "center"
  L15_2(L16_2, L17_2, L18_2)
  L15_2 = MrxGuiBase
  L15_2 = L15_2.AddWidgetWithChildren
  L16_2 = L8_2
  L15_2(L16_2)
  L15_2 = MrxGuiBase
  L15_2 = L15_2.GetControlFocus
  L16_2 = L8_2
  L17_2 = false
  L15_2(L16_2, L17_2)
  return L8_2
end

DisplayScrollingDialogBox = L3_1

function L3_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2)
  local L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2
  L8_2 = 298
  L9_2 = 10
  L10_2 = 30
  L11_2 = MrxGuiBase
  L11_2 = L11_2.TextWidget
  L12_2 = L11_2
  L11_2 = L11_2.new
  L11_2 = L11_2(L12_2)
  L13_2 = L11_2
  L12_2 = L11_2.SetFont
  L14_2 = "english_18"
  L12_2(L13_2, L14_2)
  L13_2 = L11_2
  L12_2 = L11_2.SetText
  L14_2 = A1_2
  L12_2(L13_2, L14_2)
  L13_2 = L11_2
  L12_2 = L11_2.SetLocation
  L14_2 = 0
  L15_2 = 0
  L16_2 = L8_2 - L9_2
  L16_2 = L16_2 - L9_2
  L17_2 = L1_1
  L12_2(L13_2, L14_2, L15_2, L16_2, L17_2)
  L13_2 = L11_2
  L12_2 = L11_2.Wrap
  L12_2(L13_2)
  L13_2 = L11_2
  L12_2 = L11_2.SetOwner
  L14_2 = A0_2
  L12_2(L13_2, L14_2)
  L12_2 = nil
  L13_2 = L1_1
  L15_2 = L11_2
  L14_2 = L11_2.GetHeight
  L14_2 = L14_2(L15_2)
  L15_2 = L1_1
  if L14_2 > L15_2 then
    L14_2 = _CreateScrollableWindow
    L15_2 = A0_2
    L16_2 = L11_2
    L17_2 = 0
    L18_2 = 0
    L19_2 = L9_2 * 2
    L19_2 = L8_2 - L19_2
    L20_2 = L0_1
    L19_2 = L19_2 - L20_2
    L20_2 = L1_1
    L14_2 = L14_2(L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
    L12_2 = L14_2
    L15_2 = L11_2
    L14_2 = L11_2.delete
    L14_2(L15_2)
    L11_2 = nil
  else
    L15_2 = L11_2
    L14_2 = L11_2.GetHeight
    L14_2 = L14_2(L15_2)
    L13_2 = L14_2
  end
  L14_2 = MrxGuiBase
  L14_2 = L14_2.Widget
  L15_2 = L14_2
  L14_2 = L14_2.new
  L14_2 = L14_2(L15_2)
  L15_2 = 50
  L16_2 = 2
  if A2_2 then
    L16_2 = 3
  end
  L17_2 = L9_2 * 2
  L17_2 = L8_2 - L17_2
  L17_2 = L17_2 / L16_2
  L19_2 = L14_2
  L18_2 = L14_2.SetLocation
  L20_2 = 0
  L21_2 = 0
  L22_2 = L17_2 * L16_2
  L23_2 = L15_2
  L18_2(L19_2, L20_2, L21_2, L22_2, L23_2)
  L19_2 = L14_2
  L18_2 = L14_2.SetOwner
  L20_2 = A0_2
  L18_2(L19_2, L20_2)
  L18_2 = MrxGuiBase
  L18_2 = L18_2.TextWidget
  L19_2 = L18_2
  L18_2 = L18_2.new
  L18_2 = L18_2(L19_2)
  L19_2 = MrxGuiBase
  L19_2 = L19_2.TextWidget
  L20_2 = L19_2
  L19_2 = L19_2.new
  L19_2 = L19_2(L20_2)
  L21_2 = L18_2
  L20_2 = L18_2.SetFont
  L22_2 = "english_18"
  L20_2(L21_2, L22_2)
  L21_2 = L18_2
  L20_2 = L18_2.SetText
  L22_2 = A5_2 or L22_2
  if not A5_2 then
    L22_2 = "[Generic.Accept]"
  end
  L20_2(L21_2, L22_2)
  L21_2 = L18_2
  L20_2 = L18_2.SetOwner
  L22_2 = A0_2
  L20_2(L21_2, L22_2)
  L21_2 = L18_2
  L20_2 = L18_2.SetJustification
  L22_2 = "center"
  L20_2(L21_2, L22_2)
  L21_2 = L18_2
  L20_2 = L18_2.GetHeight
  L20_2 = L20_2(L21_2)
  L22_2 = L18_2
  L21_2 = L18_2.SetLocation
  L23_2 = 0
  L24_2 = L15_2 / 2
  L25_2 = L20_2 / 2
  L24_2 = L24_2 - L25_2
  L25_2 = L17_2
  L26_2 = L15_2 / 2
  L27_2 = L20_2 / 2
  L26_2 = L26_2 + L27_2
  L21_2(L22_2, L23_2, L24_2, L25_2, L26_2)
  L22_2 = L18_2
  L21_2 = L18_2.Wrap
  L21_2(L22_2)
  L22_2 = L18_2
  L21_2 = L18_2.GetHeight
  L21_2 = L21_2(L22_2)
  L20_2 = L21_2
  L22_2 = L18_2
  L21_2 = L18_2.SetLocation
  L23_2 = 0
  L24_2 = L15_2 / 2
  L25_2 = L20_2 / 2
  L24_2 = L24_2 - L25_2
  L25_2 = L17_2
  L26_2 = L15_2 / 2
  L27_2 = L20_2 / 2
  L26_2 = L26_2 + L27_2
  L21_2(L22_2, L23_2, L24_2, L25_2, L26_2)
  L21_2 = _BuildStrokes
  L22_2 = L18_2
  L23_2 = 2
  L24_2 = 0
  L25_2 = L17_2 - 2
  L26_2 = L15_2
  L21_2(L22_2, L23_2, L24_2, L25_2, L26_2)
  L22_2 = L19_2
  L21_2 = L19_2.SetFont
  L23_2 = "english_18"
  L21_2(L22_2, L23_2)
  L22_2 = L19_2
  L21_2 = L19_2.SetText
  L23_2 = A6_2 or L23_2
  if not A6_2 then
    L23_2 = "[Generic.Decline]"
  end
  L21_2(L22_2, L23_2)
  L22_2 = L19_2
  L21_2 = L19_2.SetOwner
  L23_2 = A0_2
  L21_2(L22_2, L23_2)
  L22_2 = L19_2
  L21_2 = L19_2.SetJustification
  L23_2 = "center"
  L21_2(L22_2, L23_2)
  L22_2 = L19_2
  L21_2 = L19_2.SetLocation
  L23_2 = L17_2
  L24_2 = L15_2 / 2
  L25_2 = L20_2 / 2
  L24_2 = L24_2 - L25_2
  L25_2 = L17_2 * 2
  L26_2 = L15_2 / 2
  L27_2 = L20_2 / 2
  L26_2 = L26_2 + L27_2
  L21_2(L22_2, L23_2, L24_2, L25_2, L26_2)
  L22_2 = L19_2
  L21_2 = L19_2.Wrap
  L21_2(L22_2)
  L22_2 = L19_2
  L21_2 = L19_2.GetHeight
  L21_2 = L21_2(L22_2)
  L20_2 = L21_2
  L22_2 = L19_2
  L21_2 = L19_2.SetLocation
  L23_2 = L17_2
  L24_2 = L15_2 / 2
  L25_2 = L20_2 / 2
  L24_2 = L24_2 - L25_2
  L25_2 = L17_2 * 2
  L26_2 = L15_2 / 2
  L27_2 = L20_2 / 2
  L26_2 = L26_2 + L27_2
  L21_2(L22_2, L23_2, L24_2, L25_2, L26_2)
  L21_2 = _BuildStrokes
  L22_2 = L19_2
  L23_2 = L17_2 + 2
  L24_2 = 0
  L25_2 = L17_2 * 2
  L25_2 = L25_2 - 2
  L26_2 = L15_2
  L21_2(L22_2, L23_2, L24_2, L25_2, L26_2)
  L21_2 = nil
  if A2_2 then
    L22_2 = MrxGuiBase
    L22_2 = L22_2.TextWidget
    L23_2 = L22_2
    L22_2 = L22_2.new
    L22_2 = L22_2(L23_2)
    L21_2 = L22_2
    L23_2 = L21_2
    L22_2 = L21_2.SetFont
    L24_2 = "english_18"
    L22_2(L23_2, L24_2)
    L23_2 = L21_2
    L22_2 = L21_2.SetText
    L24_2 = A7_2 or L24_2
    if not A7_2 then
      L24_2 = "[Briefing.ChangeWager]"
    end
    L22_2(L23_2, L24_2)
    L23_2 = L21_2
    L22_2 = L21_2.SetJustification
    L24_2 = "center"
    L22_2(L23_2, L24_2)
    L23_2 = L21_2
    L22_2 = L21_2.SetOwner
    L24_2 = A0_2
    L22_2(L23_2, L24_2)
    L23_2 = L21_2
    L22_2 = L21_2.GetHeight
    L22_2 = L22_2(L23_2)
    L24_2 = L21_2
    L23_2 = L21_2.SetLocation
    L25_2 = L17_2 * 2
    L26_2 = L15_2 / 2
    L27_2 = L22_2 / 2
    L26_2 = L26_2 - L27_2
    L27_2 = L17_2 * 3
    L28_2 = L15_2 / 2
    L29_2 = L22_2 / 2
    L28_2 = L28_2 + L29_2
    L23_2(L24_2, L25_2, L26_2, L27_2, L28_2)
    L24_2 = L21_2
    L23_2 = L21_2.Wrap
    L23_2(L24_2)
    L24_2 = L21_2
    L23_2 = L21_2.GetHeight
    L23_2 = L23_2(L24_2)
    L22_2 = L23_2
    L24_2 = L21_2
    L23_2 = L21_2.SetLocation
    L25_2 = L17_2 * 2
    L26_2 = L15_2 / 2
    L27_2 = L22_2 / 2
    L26_2 = L26_2 - L27_2
    L27_2 = L17_2 * 3
    L28_2 = L15_2 / 2
    L29_2 = L22_2 / 2
    L28_2 = L28_2 + L29_2
    L23_2(L24_2, L25_2, L26_2, L27_2, L28_2)
    L23_2 = _BuildStrokes
    L24_2 = L21_2
    L25_2 = L17_2 * 2
    L25_2 = L25_2 + 2
    L26_2 = 0
    L27_2 = L17_2 * 3
    L27_2 = L27_2 - 2
    L28_2 = L15_2
    L23_2(L24_2, L25_2, L26_2, L27_2, L28_2)
  end
  L22_2 = MrxGuiBase
  L22_2 = L22_2.ImageWidget
  L23_2 = L22_2
  L22_2 = L22_2.new
  L22_2 = L22_2(L23_2)
  L24_2 = L22_2
  L23_2 = L22_2.SetColor
  L25_2 = 84
  L26_2 = 79
  L27_2 = 57
  L23_2(L24_2, L25_2, L26_2, L27_2)
  L24_2 = L22_2
  L23_2 = L22_2.SetOwner
  L25_2 = A0_2
  L23_2(L24_2, L25_2)
  L23_2 = L22_2.CustomData
  L25_2 = L22_2
  L24_2 = L22_2.AddAnimationPoint
  L26_2 = {}
  L26_2.y = 1
  L26_2.y2 = 1
  L24_2 = L24_2(L25_2, L26_2)
  L23_2.nClosePoint = L24_2
  L23_2 = L22_2.CustomData
  L25_2 = L22_2
  L24_2 = L22_2.AddAnimationPoint
  L26_2 = {}
  L26_2.y = 1
  L26_2.y2 = 1
  L24_2 = L24_2(L25_2, L26_2)
  L23_2.nOpenPoint = L24_2
  L23_2 = L22_2.CustomData
  L25_2 = L22_2
  L24_2 = L22_2.AddAnimationPoint
  L26_2 = {}
  L26_2.TranslucencyLevel = 255
  L24_2 = L24_2(L25_2, L26_2)
  L23_2.nPulseHighPoint = L24_2
  L23_2 = L22_2.CustomData
  L25_2 = L22_2
  L24_2 = L22_2.AddAnimationPoint
  L26_2 = {}
  L26_2.TranslucencyLevel = 100
  L24_2 = L24_2(L25_2, L26_2)
  L23_2.nPulseLowPoint = L24_2
  L24_2 = L22_2
  L23_2 = L22_2.SetIgnoresPause
  L25_2 = true
  L23_2(L24_2, L25_2)
  L24_2 = L22_2
  L23_2 = L22_2.SetLocation
  L25_2 = 0
  L26_2 = 0
  L27_2 = L17_2
  L28_2 = L15_2
  L23_2(L24_2, L25_2, L26_2, L27_2, L28_2)
  L23_2 = L14_2.CustomData
  L24_2 = {}
  L25_2 = L18_2
  L26_2 = L19_2
  L27_2 = L21_2
  L24_2[1] = L25_2
  L24_2[2] = L26_2
  L24_2[3] = L27_2
  L23_2.tOptions = L24_2
  L23_2 = L14_2.CustomData
  L23_2.oCursor = L22_2
  L23_2 = _SetScrollOption
  L14_2.SetOption = L23_2
  L24_2 = L14_2
  L23_2 = L14_2.AddChild
  L25_2 = L22_2
  L23_2(L24_2, L25_2)
  L24_2 = L14_2
  L23_2 = L14_2.AddChild
  L25_2 = L18_2
  L23_2(L24_2, L25_2)
  L24_2 = L14_2
  L23_2 = L14_2.AddChild
  L25_2 = L19_2
  L23_2(L24_2, L25_2)
  if L21_2 then
    L24_2 = L14_2
    L23_2 = L14_2.AddChild
    L25_2 = L21_2
    L23_2(L24_2, L25_2)
  end
  L23_2 = MrxGuiBase
  L23_2 = L23_2.TextWidget
  L24_2 = L23_2
  L23_2 = L23_2.new
  L23_2 = L23_2(L24_2)
  L25_2 = L23_2
  L24_2 = L23_2.SetLocation
  L26_2 = 0
  L27_2 = 0
  L28_2 = L9_2 * 2
  L28_2 = L8_2 - L28_2
  L29_2 = 10
  L24_2(L25_2, L26_2, L27_2, L28_2, L29_2)
  L25_2 = L23_2
  L24_2 = L23_2.SetFont
  L26_2 = _ksFont
  L24_2(L25_2, L26_2)
  L25_2 = L23_2
  L24_2 = L23_2.SetScale
  L26_2 = _knScale
  L24_2(L25_2, L26_2)
  L25_2 = L23_2
  L24_2 = L23_2.SetColor
  L26_2 = _knTextR
  L27_2 = _knTextG
  L28_2 = _knTextB
  L24_2(L25_2, L26_2, L27_2, L28_2)
  L25_2 = L23_2
  L24_2 = L23_2.SetJustification
  L26_2 = "center"
  L24_2(L25_2, L26_2)
  L25_2 = L23_2
  L24_2 = L23_2.SetText
  L26_2 = "[move] [PDA.Common.MoveSelection]  [confirm] [Generic.Confirm]"
  L24_2(L25_2, L26_2)
  L25_2 = L23_2
  L24_2 = L23_2.SetOwner
  L26_2 = uPlayerGuid
  L24_2(L25_2, L26_2)
  L25_2 = L23_2
  L24_2 = L23_2.GetHeight
  L24_2 = L24_2(L25_2)
  L25_2 = MrxGuiBase
  L25_2 = L25_2.Widget
  L26_2 = L25_2
  L25_2 = L25_2.new
  L25_2 = L25_2(L26_2)
  L27_2 = L25_2
  L26_2 = L25_2.SetOwner
  L28_2 = A0_2
  L26_2(L27_2, L28_2)
  L26_2 = MrxGuiBase
  L26_2 = L26_2.ImageWidget
  L27_2 = L26_2
  L26_2 = L26_2.new
  L26_2 = L26_2(L27_2)
  L27_2 = MrxGuiBase
  L27_2 = L27_2.ImageWidget
  L28_2 = L27_2
  L27_2 = L27_2.new
  L27_2 = L27_2(L28_2)
  L28_2 = MrxGuiBase
  L28_2 = L28_2.ImageWidget
  L29_2 = L28_2
  L28_2 = L28_2.new
  L28_2 = L28_2(L29_2)
  L30_2 = L26_2
  L29_2 = L26_2.SetOwner
  L31_2 = A0_2
  L29_2(L30_2, L31_2)
  L30_2 = L27_2
  L29_2 = L27_2.SetOwner
  L31_2 = A0_2
  L29_2(L30_2, L31_2)
  L30_2 = L28_2
  L29_2 = L28_2.SetOwner
  L31_2 = A0_2
  L29_2(L30_2, L31_2)
  L29_2 = 0.6666667
  L30_2 = 447 * L29_2
  L31_2 = 48 * L29_2
  L33_2 = L26_2
  L32_2 = L26_2.SetLocation
  L34_2 = 0
  L35_2 = 0
  L36_2 = L30_2
  L37_2 = L31_2
  L32_2(L33_2, L34_2, L35_2, L36_2, L37_2)
  L33_2 = L26_2
  L32_2 = L26_2.SetTexture
  L34_2 = "global_gui_hud02"
  L32_2(L33_2, L34_2)
  L33_2 = L26_2
  L32_2 = L26_2.SetTextureCoordinates
  L34_2 = 0
  L35_2 = 0.2734375
  L36_2 = 0.8730469
  L37_2 = 0.1796875
  L32_2(L33_2, L34_2, L35_2, L36_2, L37_2)
  L32_2 = L13_2 + L15_2
  L33_2 = L10_2 * 4
  L32_2 = L32_2 + L33_2
  L32_2 = L32_2 - L31_2
  L34_2 = L27_2
  L33_2 = L27_2.SetLocation
  L35_2 = 0
  L36_2 = 48 * L29_2
  L37_2 = L30_2
  L38_2 = L32_2
  L33_2(L34_2, L35_2, L36_2, L37_2, L38_2)
  L34_2 = L27_2
  L33_2 = L27_2.SetTexture
  L35_2 = "global_gui_hud02"
  L33_2(L34_2, L35_2)
  L34_2 = L27_2
  L33_2 = L27_2.SetTextureCoordinates
  L35_2 = 0
  L36_2 = 0.083984375
  L37_2 = 0.8730469
  L38_2 = 0.17382812
  L33_2(L34_2, L35_2, L36_2, L37_2, L38_2)
  L34_2 = L28_2
  L33_2 = L28_2.SetLocation
  L35_2 = 0
  L36_2 = L32_2
  L37_2 = L30_2
  L38_2 = L32_2 + L31_2
  L33_2(L34_2, L35_2, L36_2, L37_2, L38_2)
  L34_2 = L28_2
  L33_2 = L28_2.SetTexture
  L35_2 = "global_gui_hud02"
  L33_2(L34_2, L35_2)
  L34_2 = L28_2
  L33_2 = L28_2.SetTextureCoordinates
  L35_2 = 0
  L36_2 = 0.1796875
  L37_2 = 0.8730469
  L38_2 = 0.2734375
  L33_2(L34_2, L35_2, L36_2, L37_2, L38_2)
  L34_2 = L25_2
  L33_2 = L25_2.SetLocation
  L35_2 = 0
  L36_2 = 0
  L37_2 = L30_2
  L38_2 = L32_2 + L31_2
  L33_2(L34_2, L35_2, L36_2, L37_2, L38_2)
  L34_2 = L25_2
  L33_2 = L25_2.AddChild
  L35_2 = L26_2
  L33_2(L34_2, L35_2)
  L34_2 = L25_2
  L33_2 = L25_2.AddChild
  L35_2 = L27_2
  L33_2(L34_2, L35_2)
  L34_2 = L25_2
  L33_2 = L25_2.AddChild
  L35_2 = L28_2
  L33_2(L34_2, L35_2)
  L33_2 = MrxGuiBase
  L33_2 = L33_2.Widget
  L34_2 = L33_2
  L33_2 = L33_2.new
  L33_2 = L33_2(L34_2)
  L35_2 = L33_2
  L34_2 = L33_2.SetLocation
  L36_2 = 0
  L37_2 = 0
  L38_2 = L8_2
  L39_2 = L13_2 + L15_2
  L40_2 = L10_2 * 4
  L39_2 = L39_2 + L40_2
  L34_2(L35_2, L36_2, L37_2, L38_2, L39_2)
  L35_2 = L33_2
  L34_2 = L33_2.SetOwner
  L36_2 = A0_2
  L34_2(L35_2, L36_2)
  L35_2 = L33_2
  L34_2 = L33_2.AddChild
  L36_2 = L25_2
  L34_2(L35_2, L36_2)
  if L11_2 then
    L35_2 = L33_2
    L34_2 = L33_2.AddChild
    L36_2 = L11_2
    L34_2(L35_2, L36_2)
  end
  if L12_2 then
    L35_2 = L33_2
    L34_2 = L33_2.AddChild
    L36_2 = L12_2
    L34_2(L35_2, L36_2)
  end
  L35_2 = L33_2
  L34_2 = L33_2.AddChild
  L36_2 = L14_2
  L34_2(L35_2, L36_2)
  L35_2 = L33_2
  L34_2 = L33_2.AddChild
  L36_2 = L23_2
  L34_2(L35_2, L36_2)
  L34_2 = L33_2.CustomData
  L34_2.oOptions = L14_2
  L34_2 = L33_2.CustomData
  L34_2.oScroll = L12_2
  L34_2 = L33_2.CustomData
  L34_2.oCursor = L22_2
  if L12_2 then
    L35_2 = L12_2
    L34_2 = L12_2.SetLocation
    L36_2 = L9_2
    L37_2 = L10_2
    L34_2(L35_2, L36_2, L37_2)
  else
    L35_2 = L11_2
    L34_2 = L11_2.SetLocation
    L36_2 = L9_2
    L37_2 = L10_2
    L34_2(L35_2, L36_2, L37_2)
  end
  L35_2 = L14_2
  L34_2 = L14_2.SetLocation
  L36_2 = L9_2
  L37_2 = L10_2 * 1.75
  L37_2 = L13_2 + L37_2
  L34_2(L35_2, L36_2, L37_2)
  L35_2 = L23_2
  L34_2 = L23_2.SetLocation
  L36_2 = L9_2
  L37_2 = L10_2 * 2.25
  L37_2 = L13_2 + L37_2
  L37_2 = L37_2 + L15_2
  L34_2(L35_2, L36_2, L37_2)
  L34_2 = CloseScrollingBox
  L33_2.Close = L34_2
  L34_2 = L33_2.CustomData
  L34_2.nScroll = 0
  L34_2 = L33_2.CustomData
  L34_2.nPadScroll = 0
  L34_2 = L33_2.CustomData
  L34_2.nAnalogScroll = 0
  L34_2 = L33_2.CustomData
  L34_2.nNumOptions = L16_2
  L34_2 = L33_2.CustomData
  L34_2.nSelected = 1
  L34_2 = L33_2.CustomData
  L34_2.fCallback = A3_2
  L34_2 = L33_2.CustomData
  L34_2.tCallbackData = A4_2
  L35_2 = L33_2
  L34_2 = L33_2.SetEventHandler
  L36_2 = "GuiUpdate"
  L37_2 = _HandleScrollUpdate
  L34_2(L35_2, L36_2, L37_2)
  L35_2 = L33_2
  L34_2 = L33_2.SetEventHandler
  L36_2 = "ControllerInput"
  L37_2 = _HandleScrollInput
  L34_2(L35_2, L36_2, L37_2)
  L34_2 = Pulse
  L35_2 = L22_2
  L34_2(L35_2)
  return L33_2
end

_BuildScrollingDialogBox = L3_1

function L3_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L5_2 = 128
  L6_2 = 128
  L7_2 = 96
  L8_2 = 255
  L9_2 = 1
  L10_2 = MrxGuiBase
  L10_2 = L10_2.ImageWidget
  L11_2 = L10_2
  L10_2 = L10_2.new
  L10_2 = L10_2(L11_2)
  L12_2 = L10_2
  L11_2 = L10_2.SetColor
  L13_2 = L5_2
  L14_2 = L6_2
  L15_2 = L7_2
  L16_2 = L8_2
  L11_2(L12_2, L13_2, L14_2, L15_2, L16_2)
  L12_2 = L10_2
  L11_2 = L10_2.SetLocation
  L13_2 = A1_2
  L14_2 = A2_2
  L15_2 = A1_2 + L9_2
  L16_2 = A4_2
  L11_2(L12_2, L13_2, L14_2, L15_2, L16_2)
  L11_2 = MrxGuiBase
  L11_2 = L11_2.ImageWidget
  L12_2 = L11_2
  L11_2 = L11_2.new
  L11_2 = L11_2(L12_2)
  L13_2 = L11_2
  L12_2 = L11_2.SetColor
  L14_2 = L5_2
  L15_2 = L6_2
  L16_2 = L7_2
  L17_2 = L8_2
  L12_2(L13_2, L14_2, L15_2, L16_2, L17_2)
  L13_2 = L11_2
  L12_2 = L11_2.SetLocation
  L14_2 = A1_2
  L15_2 = A2_2
  L16_2 = A3_2
  L17_2 = A2_2 + L9_2
  L12_2(L13_2, L14_2, L15_2, L16_2, L17_2)
  L12_2 = MrxGuiBase
  L12_2 = L12_2.ImageWidget
  L13_2 = L12_2
  L12_2 = L12_2.new
  L12_2 = L12_2(L13_2)
  L14_2 = L12_2
  L13_2 = L12_2.SetColor
  L15_2 = L5_2
  L16_2 = L6_2
  L17_2 = L7_2
  L18_2 = L8_2
  L13_2(L14_2, L15_2, L16_2, L17_2, L18_2)
  L14_2 = L12_2
  L13_2 = L12_2.SetLocation
  L15_2 = A3_2 - L9_2
  L16_2 = A2_2
  L17_2 = A3_2
  L18_2 = A4_2
  L13_2(L14_2, L15_2, L16_2, L17_2, L18_2)
  L13_2 = MrxGuiBase
  L13_2 = L13_2.ImageWidget
  L14_2 = L13_2
  L13_2 = L13_2.new
  L13_2 = L13_2(L14_2)
  L15_2 = L13_2
  L14_2 = L13_2.SetColor
  L16_2 = L5_2
  L17_2 = L6_2
  L18_2 = L7_2
  L19_2 = L8_2
  L14_2(L15_2, L16_2, L17_2, L18_2, L19_2)
  L15_2 = L13_2
  L14_2 = L13_2.SetLocation
  L16_2 = A1_2
  L17_2 = A4_2 - L9_2
  L18_2 = A3_2
  L19_2 = A4_2
  L14_2(L15_2, L16_2, L17_2, L18_2, L19_2)
  L15_2 = A0_2
  L14_2 = A0_2.AddChild
  L16_2 = L10_2
  L14_2(L15_2, L16_2)
  L15_2 = A0_2
  L14_2 = A0_2.AddChild
  L16_2 = L11_2
  L14_2(L15_2, L16_2)
  L15_2 = A0_2
  L14_2 = A0_2.AddChild
  L16_2 = L12_2
  L14_2(L15_2, L16_2)
  L15_2 = A0_2
  L14_2 = A0_2.AddChild
  L16_2 = L13_2
  L14_2(L15_2, L16_2)
end

_BuildStrokes = L3_1

function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oScroll
  if L2_2 then
    L2_2 = math
    L2_2 = L2_2.abs
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.nScroll
    L2_2 = L2_2(L3_2)
    if 0.5 < L2_2 then
      L2_2 = L2_1
      L2_2 = A1_2 * L2_2
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.nScroll
      L2_2 = L2_2 * L3_2
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.oScroll
      L4_2 = L3_2
      L3_2 = L3_2.OffsetText
      L5_2 = L2_2
      L3_2(L4_2, L5_2)
    end
  end
end

_HandleScrollUpdate = L3_1

function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = MrxGuiBase
  L2_2 = L2_2.Joystick
  L2_2 = L2_2.BUTTON_PAD1_D
  L3_2 = A1_2.ButtonPress
  if L2_2 == L3_2 then
    L2_2 = A0_2.CustomData
    L2_2.nPadScroll = -1
  else
    L2_2 = MrxGuiBase
    L2_2 = L2_2.Joystick
    L2_2 = L2_2.BUTTON_PAD1_U
    L3_2 = A1_2.ButtonPress
    if L2_2 == L3_2 then
      L2_2 = A0_2.CustomData
      L2_2.nPadScroll = 1
    else
      L2_2 = A0_2.CustomData
      L2_2.nPadScroll = 0
    end
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nAnalogScroll
  if -1 == L2_2 then
    L2_2 = MrxGuiBase
    L2_2 = L2_2.Joystick
    L2_2 = L2_2.BUTTON_L_STICK_D
    L3_2 = A1_2.ButtonReleased
    if L2_2 == L3_2 then
      L2_2 = A0_2.CustomData
      L2_2.nAnalogScroll = 0
    end
  else
    L2_2 = MrxGuiBase
    L2_2 = L2_2.Joystick
    L2_2 = L2_2.BUTTON_L_STICK_D
    L3_2 = A1_2.ButtonPress
    if L2_2 == L3_2 then
      L2_2 = A0_2.CustomData
      L2_2.nAnalogScroll = -1
    end
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nAnalogScroll
  if 1 == L2_2 then
    L2_2 = MrxGuiBase
    L2_2 = L2_2.Joystick
    L2_2 = L2_2.BUTTON_L_STICK_U
    L3_2 = A1_2.ButtonReleased
    if L2_2 == L3_2 then
      L2_2 = A0_2.CustomData
      L2_2.nAnalogScroll = 0
    end
  else
    L2_2 = MrxGuiBase
    L2_2 = L2_2.Joystick
    L2_2 = L2_2.BUTTON_L_STICK_U
    L3_2 = A1_2.ButtonPress
    if L2_2 == L3_2 then
      L2_2 = A0_2.CustomData
      L2_2.nAnalogScroll = 1
    end
  end
  L2_2 = A0_2.CustomData
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nPadScroll
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nAnalogScroll
  L3_2 = L3_2 + L4_2
  L2_2.nScroll = L3_2
  L2_2 = 0
  L3_2 = MrxGuiBase
  L3_2 = L3_2.Joystick
  L3_2 = L3_2.BUTTON_PAD1_L
  L4_2 = A1_2.ButtonPress
  if L3_2 ~= L4_2 then
    L3_2 = MrxGuiBase
    L3_2 = L3_2.Joystick
    L3_2 = L3_2.BUTTON_L_STICK_L
    L4_2 = A1_2.ButtonPress
    if L3_2 ~= L4_2 then
      goto lbl_85
    end
  end
  L2_2 = -1
  goto lbl_98
  ::lbl_85::
  L3_2 = MrxGuiBase
  L3_2 = L3_2.Joystick
  L3_2 = L3_2.BUTTON_PAD1_R
  L4_2 = A1_2.ButtonPress
  if L3_2 ~= L4_2 then
    L3_2 = MrxGuiBase
    L3_2 = L3_2.Joystick
    L3_2 = L3_2.BUTTON_L_STICK_R
    L4_2 = A1_2.ButtonPress
    if L3_2 ~= L4_2 then
      goto lbl_98
    end
  end
  L2_2 = 1
  ::lbl_98::
  L3_2 = math
  L3_2 = L3_2.abs
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if 0.5 < L3_2 then
    L3_2 = A0_2.CustomData
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.nSelected
    L4_2 = L4_2 + L2_2
    L3_2.nSelected = L4_2
    while true do
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.nSelected
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.nNumOptions
      if not (L3_2 > L4_2) then
        break
      end
      L3_2 = A0_2.CustomData
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.nSelected
      L5_2 = A0_2.CustomData
      L5_2 = L5_2.nNumOptions
      L4_2 = L4_2 - L5_2
      L3_2.nSelected = L4_2
    end
    while true do
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.nSelected
      if not (L3_2 < 1) then
        break
      end
      L3_2 = A0_2.CustomData
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.nSelected
      L5_2 = A0_2.CustomData
      L5_2 = L5_2.nNumOptions
      L4_2 = L4_2 + L5_2
      L3_2.nSelected = L4_2
    end
    L3_2 = Sound
    L3_2 = L3_2.CueSound
    L4_2 = 0
    L5_2 = _ksChangeSound
    L3_2(L4_2, L5_2)
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.oOptions
    L4_2 = L3_2
    L3_2 = L3_2.SetOption
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.nSelected
    L3_2(L4_2, L5_2)
  end
  L3_2 = MrxGuiBase
  L3_2 = L3_2.Joystick
  L3_2 = L3_2.BUTTON_PAD2_D
  L4_2 = A1_2.ButtonPress
  if L3_2 == L4_2 then
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.fCallback
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.tCallbackData
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.nSelected
    L7_2 = A0_2
    L6_2 = A0_2.Close
    L6_2(L7_2)
    L6_2 = Sound
    L6_2 = L6_2.CueSound
    L7_2 = 0
    L8_2 = _ksAcceptSound
    L6_2(L7_2, L8_2)
    L6_2 = _CallScrollBoxCallback
    L7_2 = L3_2
    L8_2 = L4_2
    L9_2 = L5_2
    L6_2(L7_2, L8_2, L9_2)
  else
    L3_2 = MrxGuiBase
    L3_2 = L3_2.Joystick
    L3_2 = L3_2.BUTTON_PAD2_R
    L4_2 = A1_2.ButtonPress
    if L3_2 == L4_2 then
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.fCallback
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.tCallbackData
      L6_2 = A0_2
      L5_2 = A0_2.Close
      L5_2(L6_2)
      L5_2 = Sound
      L5_2 = L5_2.CueSound
      L6_2 = 0
      L7_2 = _ksCancelSound
      L5_2(L6_2, L7_2)
      L5_2 = _CallScrollBoxCallback
      L6_2 = L3_2
      L7_2 = L4_2
      L8_2 = 2
      L5_2(L6_2, L7_2, L8_2)
    end
  end
end

_HandleScrollInput = L3_1

function L3_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  if A0_2 then
    if not A1_2 then
      L3_2 = {}
      A1_2 = L3_2
    end
    L3_2 = table
    L3_2 = L3_2.insert
    L4_2 = A1_2
    L5_2 = A2_2
    L3_2(L4_2, L5_2)
    L3_2 = A0_2
    L4_2 = unpack
    L5_2 = A1_2
    L4_2, L5_2 = L4_2(L5_2)
    L3_2(L4_2, L5_2)
  end
end

_CallScrollBoxCallback = L3_1

function L3_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxGuiBase
  L1_2 = L1_2.ReleaseControlFocus
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = MrxGuiBase
  L1_2 = L1_2.RemoveWidgetWithChildren
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.DeleteWithChildren
  L1_2(L2_2)
end

CloseScrollingBox = L3_1

function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.tOptions
  L2_2 = L2_2[A1_2]
  if not L2_2 then
    return
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.tOptions
  L2_2 = L2_2[A1_2]
  L3_2 = L2_2
  L2_2 = L2_2.GetLocation
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L6_2 = A0_2
  L5_2 = A0_2.GetLocation
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  L9_2 = A0_2.CustomData
  L9_2.nSelectedIndex = A1_2
  L9_2 = A0_2.CustomData
  L9_2 = L9_2.oCursor
  L10_2 = L6_2 + L8_2
  L10_2 = L10_2 * 0.5
  L12_2 = L9_2
  L11_2 = L9_2.SetAnimationPoint
  L13_2 = L9_2.CustomData
  L13_2 = L13_2.nClosePoint
  L14_2 = {}
  L14_2.y = L10_2
  L14_2.y2 = L10_2
  L11_2(L12_2, L13_2, L14_2)
  L12_2 = L9_2
  L11_2 = L9_2.SetAnimationPoint
  L13_2 = L9_2.CustomData
  L13_2 = L13_2.nOpenPoint
  L14_2 = {}
  L14_2.y = L6_2
  L14_2.y2 = L8_2
  L11_2(L12_2, L13_2, L14_2)
  L12_2 = L9_2
  L11_2 = L9_2.SetLocation
  L13_2 = nil
  L14_2 = L6_2
  L15_2 = nil
  L16_2 = L8_2
  L11_2(L12_2, L13_2, L14_2, L15_2, L16_2)
  L12_2 = L9_2
  L11_2 = L9_2.AnimateToPoint
  L13_2 = L9_2.CustomData
  L13_2 = L13_2.nClosePoint
  L14_2 = 0.075
  L15_2 = true
  L16_2 = _CompleteScrollAnimation
  L17_2 = {}
  L18_2 = L2_2
  L19_2 = L4_2
  L17_2[1] = L18_2
  L17_2[2] = L19_2
  L11_2(L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
end

_SetScrollOption = L3_1

function L3_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L4_2 = A0_2
  L3_2 = A0_2.SetLocation
  L5_2 = A1_2
  L6_2 = nil
  L7_2 = A2_2
  L8_2 = nil
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  L4_2 = A0_2
  L3_2 = A0_2.AnimateToPoint
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nOpenPoint
  L6_2 = 0.075
  L7_2 = true
  L8_2 = Pulse
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
end

_CompleteScrollAnimation = L3_1

function L3_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2
  L6_2 = MrxGuiBase
  L6_2 = L6_2.Widget
  L7_2 = L6_2
  L6_2 = L6_2.new
  L6_2 = L6_2(L7_2)
  L8_2 = L6_2
  L7_2 = L6_2.SetLocation
  L9_2 = 0
  L10_2 = 0
  L11_2 = A4_2
  L12_2 = A5_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L8_2 = A1_2
  L7_2 = A1_2.GetHeight
  L7_2 = L7_2(L8_2)
  L9_2 = A1_2
  L8_2 = A1_2.SplitIntoLines
  L8_2 = L8_2(L9_2)
  L9_2 = #L8_2
  L9_2 = L7_2 / L9_2
  L10_2 = MrxGuiBase
  L10_2 = L10_2.Widget
  L11_2 = L10_2
  L10_2 = L10_2.new
  L10_2 = L10_2(L11_2)
  L12_2 = L10_2
  L11_2 = L10_2.SetLocation
  L13_2 = 0
  L14_2 = 0
  L15_2 = A4_2
  L16_2 = L7_2
  L11_2(L12_2, L13_2, L14_2, L15_2, L16_2)
  L11_2 = L10_2.CustomData
  L11_2.nLineHeight = L9_2
  L11_2 = 0
  L12_2 = pairs
  L13_2 = L8_2
  L12_2, L13_2, L14_2 = L12_2(L13_2)
  for L15_2, L16_2 in L12_2, L13_2, L14_2 do
    L18_2 = L16_2
    L17_2 = L16_2.SetLocation
    L19_2 = 0
    L20_2 = L11_2
    L17_2(L18_2, L19_2, L20_2)
    L18_2 = L16_2
    L17_2 = L16_2.SetOwner
    L19_2 = A0_2
    L17_2(L18_2, L19_2)
    L18_2 = L10_2
    L17_2 = L10_2.AddChild
    L19_2 = L16_2
    L17_2(L18_2, L19_2)
    L11_2 = L11_2 + L9_2
  end
  L12_2 = L10_2.CustomData
  L12_2.tLines = L8_2
  L12_2 = L10_2.CustomData
  L12_2.nMaxHeight = A5_2
  L12_2 = _UpdateTextAlpha
  L10_2.UpdateAlpha = L12_2
  L10_2.ParentWidget = L6_2
  L13_2 = L10_2
  L12_2 = L10_2.SetOwner
  L14_2 = A0_2
  L12_2(L13_2, L14_2)
  L13_2 = L10_2
  L12_2 = L10_2.UpdateAlpha
  L12_2(L13_2)
  L12_2 = MrxGuiBase
  L12_2 = L12_2.ImageWidget
  L13_2 = L12_2
  L12_2 = L12_2.new
  L12_2 = L12_2(L13_2)
  L13_2 = MrxGuiBase
  L13_2 = L13_2.ImageWidget
  L14_2 = L13_2
  L13_2 = L13_2.new
  L13_2 = L13_2(L14_2)
  L14_2 = L0_1
  L14_2 = L14_2 * 2
  L14_2 = A5_2 - L14_2
  L14_2 = L14_2 - 2
  L15_2 = A5_2 / L7_2
  L15_2 = L14_2 * L15_2
  L17_2 = L12_2
  L16_2 = L12_2.SetColor
  L18_2 = 64
  L19_2 = 64
  L20_2 = 48
  L16_2(L17_2, L18_2, L19_2, L20_2)
  L17_2 = L13_2
  L16_2 = L13_2.SetColor
  L18_2 = 128
  L19_2 = 128
  L20_2 = 96
  L16_2(L17_2, L18_2, L19_2, L20_2)
  L17_2 = L12_2
  L16_2 = L12_2.SetLocation
  L18_2 = A2_2 + A4_2
  L19_2 = A3_2
  L20_2 = A2_2 + A4_2
  L21_2 = L0_1
  L20_2 = L20_2 + L21_2
  L21_2 = A3_2 + A5_2
  L16_2(L17_2, L18_2, L19_2, L20_2, L21_2)
  L17_2 = L13_2
  L16_2 = L13_2.SetLocation
  L18_2 = A4_2
  L19_2 = L0_1
  L19_2 = L19_2 + 1
  L20_2 = L0_1
  L20_2 = A4_2 + L20_2
  L21_2 = L0_1
  L21_2 = L15_2 + L21_2
  L21_2 = L21_2 + 1
  L16_2(L17_2, L18_2, L19_2, L20_2, L21_2)
  L16_2 = MrxGuiBase
  L16_2 = L16_2.ImageWidget
  L17_2 = L16_2
  L16_2 = L16_2.new
  L16_2 = L16_2(L17_2)
  L18_2 = L16_2
  L17_2 = L16_2.SetTexture
  L19_2 = "global_gui_hud02"
  L17_2(L18_2, L19_2)
  L18_2 = L16_2
  L17_2 = L16_2.SetTextureCoordinates
  L19_2 = 0.001953
  L20_2 = 0.947266
  L21_2 = 0.162109
  L22_2 = 0.986328
  L17_2(L18_2, L19_2, L20_2, L21_2, L22_2)
  L18_2 = L16_2
  L17_2 = L16_2.SetLocation
  L19_2 = 0 + A4_2
  L20_2 = 0
  L21_2 = 0 + A4_2
  L22_2 = L0_1
  L21_2 = L21_2 + L22_2
  L22_2 = L0_1
  L17_2(L18_2, L19_2, L20_2, L21_2, L22_2)
  L17_2 = MrxGuiBase
  L17_2 = L17_2.ImageWidget
  L18_2 = L17_2
  L17_2 = L17_2.new
  L17_2 = L17_2(L18_2)
  L19_2 = L17_2
  L18_2 = L17_2.SetTexture
  L20_2 = "global_gui_hud02"
  L18_2(L19_2, L20_2)
  L19_2 = L17_2
  L18_2 = L17_2.SetTextureCoordinates
  L20_2 = 0.001953
  L21_2 = 0.986328
  L22_2 = 0.162109
  L23_2 = 0.947266
  L18_2(L19_2, L20_2, L21_2, L22_2, L23_2)
  L19_2 = L17_2
  L18_2 = L17_2.SetLocation
  L20_2 = A4_2
  L21_2 = L0_1
  L21_2 = A5_2 - L21_2
  L22_2 = L0_1
  L22_2 = A4_2 + L22_2
  L23_2 = A5_2
  L18_2(L19_2, L20_2, L21_2, L22_2, L23_2)
  L18_2 = L13_2.CustomData
  L18_2.nHeight = L15_2
  L18_2 = L13_2.CustomData
  L18_2.nTotalHeight = L14_2
  L19_2 = L6_2
  L18_2 = L6_2.AddChild
  L20_2 = L12_2
  L18_2(L19_2, L20_2)
  L19_2 = L6_2
  L18_2 = L6_2.AddChild
  L20_2 = L13_2
  L18_2(L19_2, L20_2)
  L19_2 = L6_2
  L18_2 = L6_2.AddChild
  L20_2 = L16_2
  L18_2(L19_2, L20_2)
  L19_2 = L6_2
  L18_2 = L6_2.AddChild
  L20_2 = L17_2
  L18_2(L19_2, L20_2)
  L19_2 = L6_2
  L18_2 = L6_2.AddChild
  L20_2 = L10_2
  L18_2(L19_2, L20_2)
  L18_2 = L6_2.CustomData
  L18_2.oBarBg = L12_2
  L18_2 = L6_2.CustomData
  L18_2.oBar = L13_2
  L18_2 = L6_2.CustomData
  L18_2.oTextContainer = L10_2
  L18_2 = L6_2.CustomData
  L18_2.nHeight = A5_2
  L18_2 = L6_2.CustomData
  L18_2.nTextHeight = L7_2
  L18_2 = L6_2.CustomData
  L18_2.nOffset = 0
  L18_2 = _OffsetText
  L6_2.OffsetText = L18_2
  L19_2 = L6_2
  L18_2 = L6_2.SetLocation
  L20_2 = A2_2
  L21_2 = A3_2
  L18_2(L19_2, L20_2, L21_2)
  return L6_2
end

_CreateScrollableWindow = L3_1

function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = A0_2
  L2_2 = A0_2.GetLocation
  L2_2, L3_2 = L2_2(L3_2)
  L4_2 = A0_2.CustomData
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nOffset
  L5_2 = L5_2 + A1_2
  L4_2.nOffset = L5_2
  L4_2 = A0_2.CustomData
  L5_2 = _Clamp
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.nOffset
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.nHeight
  L8_2 = A0_2.CustomData
  L8_2 = L8_2.nTextHeight
  L7_2 = L7_2 - L8_2
  L8_2 = 0
  L5_2 = L5_2(L6_2, L7_2, L8_2)
  L4_2.nOffset = L5_2
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oTextContainer
  L5_2 = L4_2
  L4_2 = L4_2.SetLocation
  L6_2 = L2_2
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.nOffset
  L7_2 = L3_2 + L7_2
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oTextContainer
  L5_2 = L4_2
  L4_2 = L4_2.UpdateAlpha
  L4_2(L5_2)
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oBarBg
  L5_2 = L4_2
  L4_2 = L4_2.GetLocation
  L4_2, L5_2 = L4_2(L5_2)
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.oBar
  L7_2 = L6_2
  L6_2 = L6_2.SetLocation
  L8_2 = L4_2
  L9_2 = L0_1
  L9_2 = L5_2 + L9_2
  L9_2 = L9_2 + 1
  L10_2 = A0_2.CustomData
  L10_2 = L10_2.nOffset
  L11_2 = A0_2.CustomData
  L11_2 = L11_2.nTextHeight
  L10_2 = L10_2 / L11_2
  L11_2 = A0_2.CustomData
  L11_2 = L11_2.oBar
  L11_2 = L11_2.CustomData
  L11_2 = L11_2.nTotalHeight
  L10_2 = L10_2 * L11_2
  L9_2 = L9_2 - L10_2
  L6_2(L7_2, L8_2, L9_2)
end

_OffsetText = L3_1

function L3_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = math
  L3_2 = L3_2.max
  L4_2 = math
  L4_2 = L4_2.min
  L5_2 = A0_2
  L6_2 = A2_2
  L4_2 = L4_2(L5_2, L6_2)
  L5_2 = A1_2
  return L3_2(L4_2, L5_2)
end

_Clamp = L3_1

function L3_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.nLineHeight
  L1_2 = L1_2 * 0.5
  L2_2 = A0_2.ParentWidget
  L3_2 = L2_2
  L2_2 = L2_2.GetLocation
  L2_2, L3_2 = L2_2(L3_2)
  L4_2 = L1_2 * 0.5
  L4_2 = L3_2 - L4_2
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nMaxHeight
  L5_2 = L3_2 + L5_2
  L5_2 = L5_2 - L1_2
  L6_2 = L1_2 * 0.5
  L5_2 = L5_2 - L6_2
  L6_2 = pairs
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.tLines
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  for L9_2, L10_2 in L6_2, L7_2, L8_2 do
    L12_2 = L10_2
    L11_2 = L10_2.GetLocation
    L11_2, L12_2 = L11_2(L12_2)
    L3_2 = L12_2
    L2_2 = L11_2
    if L4_2 > L3_2 then
      L12_2 = L10_2
      L11_2 = L10_2.SetTranslucency
      L13_2 = math
      L13_2 = L13_2.max
      L14_2 = L4_2 - L3_2
      L14_2 = L14_2 / L1_2
      L14_2 = 1 - L14_2
      L14_2 = L14_2 * 255
      L15_2 = 0
      L13_2, L14_2, L15_2 = L13_2(L14_2, L15_2)
      L11_2(L12_2, L13_2, L14_2, L15_2)
    elseif L5_2 < L3_2 then
      L12_2 = L10_2
      L11_2 = L10_2.SetTranslucency
      L13_2 = math
      L13_2 = L13_2.max
      L14_2 = L3_2 - L5_2
      L14_2 = L14_2 / L1_2
      L14_2 = 1 - L14_2
      L14_2 = L14_2 * 255
      L15_2 = 0
      L13_2, L14_2, L15_2 = L13_2(L14_2, L15_2)
      L11_2(L12_2, L13_2, L14_2, L15_2)
    else
      L12_2 = L10_2
      L11_2 = L10_2.SetTranslucency
      L13_2 = 255
      L11_2(L12_2, L13_2)
    end
  end
end

_UpdateTextAlpha = L3_1

function L3_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  L3_2 = type
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if L3_2 == A1_2 then
    return A0_2
  else
    return A2_2
  end
end

_ValidateParameter = L3_1
L3_1 = nil
oSystemDialogBoxFlash = L3_1

function L3_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = oSystemDialogBoxFlash
  if L3_2 == nil then
    L3_2 = MrxGuiBase
    L3_2 = L3_2.GetWidgetByNameAndOwner
    L4_2 = "PDA"
    L5_2 = Player
    L5_2 = L5_2.GetLocalPlayer
    L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L5_2()
    L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
    if L3_2 then
      L5_2 = L3_2
      L4_2 = L3_2.Close
      L4_2(L5_2)
    end
    L4_2 = MrxGuiBase
    L4_2 = L4_2.GetWidgetByName
    L5_2 = "Pause Layout"
    L4_2 = L4_2(L5_2)
    L3_2 = L4_2
    if L3_2 then
      L5_2 = L3_2
      L4_2 = L3_2.Close
      L4_2(L5_2)
      L4_2 = Sys
      L4_2 = L4_2.RequestGameState
      L5_2 = "ingame"
      L4_2(L5_2)
    end
    L4_2 = MrxGuiBase
    L4_2 = L4_2.FlashWidget
    L5_2 = L4_2
    L4_2 = L4_2.new
    L4_2 = L4_2(L5_2)
    oSystemDialogBoxFlash = L4_2
    L4_2 = oSystemDialogBoxFlash
    L5_2 = L4_2
    L4_2 = L4_2.SetOwner
    L6_2 = Player
    L6_2 = L6_2.GetLocalPlayer
    L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L6_2()
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
    L4_2 = oSystemDialogBoxFlash
    L5_2 = L4_2
    L4_2 = L4_2.SetLocation
    L6_2 = 160
    L7_2 = 120
    L8_2 = 480
    L9_2 = 360
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
    L4_2 = MrxGuiBase
    L4_2 = L4_2.AddWidget
    L5_2 = oSystemDialogBoxFlash
    L4_2(L5_2)
    L4_2 = oSystemDialogBoxFlash
    L5_2 = L4_2
    L4_2 = L4_2.SetSwfFile
    L6_2 = "dialog_box"
    L7_2 = SystemDialogBoxLoadedCallBack
    L8_2 = {}
    L9_2 = oSystemDialogBoxFlash
    L10_2 = A0_2
    L11_2 = A1_2
    L12_2 = A2_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L8_2[4] = L12_2
    L4_2(L5_2, L6_2, L7_2, L8_2)
  end
end

OpenSystemDialogBox = L3_1

function L3_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  if A0_2 ~= nil then
    L4_2 = MrxGuiBase
    L4_2 = L4_2.GetControlFocus
    L5_2 = A0_2
    L6_2 = true
    L4_2(L5_2, L6_2)
    L5_2 = A0_2
    L4_2 = A0_2.CallActionScriptCallback
    L6_2 = "onlineMessage"
    L7_2 = {}
    L8_2 = A1_2
    L9_2 = A2_2
    L10_2 = 1
    L11_2 = A3_2
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L7_2[4] = L11_2
    L4_2(L5_2, L6_2, L7_2)
    L5_2 = A0_2
    L4_2 = A0_2.SetFlashEventHandler
    L6_2 = "onlineMessageClose"
    L7_2 = CloseSystemDialogBox
    L8_2 = {}
    L4_2(L5_2, L6_2, L7_2, L8_2)
  end
end

SystemDialogBoxLoadedCallBack = L3_1

function L3_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.TimerRelative
  L2_2 = {}
  L3_2 = 0.01
  L4_2 = true
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = CloseSystemDialogBoxDelayed
  L4_2 = {}
  L5_2 = oSystemDialogBoxFlash
  L4_2[1] = L5_2
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = nil
  oSystemDialogBoxFlash = L0_2
end

CloseSystemDialogBox = L3_1

function L3_1(A0_2)
  local L1_2, L2_2, L3_2
  if A0_2 ~= nil then
    L1_2 = MrxGuiBase
    L1_2 = L1_2.ReleaseControlFocus
    L2_2 = A0_2
    L1_2(L2_2)
    L1_2 = MrxGuiBase
    L1_2 = L1_2.RemoveWidget
    L2_2 = A0_2
    L1_2(L2_2)
    L2_2 = A0_2
    L1_2 = A0_2.SetSwfFile
    L3_2 = nil
    L1_2(L2_2, L3_2)
    L2_2 = A0_2
    L1_2 = A0_2.delete
    L1_2(L2_2)
  end
end

CloseSystemDialogBoxDelayed = L3_1
