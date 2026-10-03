local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGuiBase"
L0_1(L1_1)
L0_1 = "english_18"
_ksFontSmall = L0_1
L0_1 = "english_20"
_ksFont = L0_1
L0_1 = 1
_knScale = L0_1
L0_1 = 1
_knScaleBig = L0_1
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

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2, A9_2, A10_2, A11_2, A12_2, A13_2, A14_2, A15_2, A16_2, A17_2, A18_2, A19_2)
  local L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2
  L20_2 = type
  L21_2 = A0_2
  L20_2 = L20_2(L21_2)
  if "userdata" ~= L20_2 then
    return
  end
  L20_2 = type
  L21_2 = A1_2
  L20_2 = L20_2(L21_2)
  if "string" ~= L20_2 then
    return
  end
  L20_2 = _ValidateParameter
  L21_2 = A6_2
  L22_2 = "number"
  L23_2 = nil
  L20_2 = L20_2(L21_2, L22_2, L23_2)
  A6_2 = L20_2
  L20_2 = _ValidateParameter
  L21_2 = A7_2
  L22_2 = "number"
  L23_2 = nil
  L20_2 = L20_2(L21_2, L22_2, L23_2)
  A7_2 = L20_2
  L20_2 = _ValidateParameter
  L21_2 = A5_2
  L22_2 = "number"
  L23_2 = A6_2
  L20_2 = L20_2(L21_2, L22_2, L23_2)
  A5_2 = L20_2
  L20_2 = _ValidateParameter
  L21_2 = A9_2
  L22_2 = "number"
  L23_2 = 0
  L20_2 = L20_2(L21_2, L22_2, L23_2)
  A9_2 = L20_2
  L20_2 = _ValidateParameter
  L21_2 = A10_2
  L22_2 = "number"
  L23_2 = 9
  L20_2 = L20_2(L21_2, L22_2, L23_2)
  A10_2 = L20_2
  L20_2 = _ValidateParameter
  L21_2 = A8_2
  L22_2 = "number"
  L23_2 = A9_2
  L20_2 = L20_2(L21_2, L22_2, L23_2)
  A8_2 = L20_2
  L20_2 = _ValidateParameter
  L21_2 = A11_2
  L22_2 = "function"
  L23_2 = nil
  L20_2 = L20_2(L21_2, L22_2, L23_2)
  A11_2 = L20_2
  L20_2 = _ValidateParameter
  L21_2 = A12_2
  L22_2 = "table"
  L23_2 = {}
  L20_2 = L20_2(L21_2, L22_2, L23_2)
  A12_2 = L20_2
  L20_2 = _ValidateParameter
  L21_2 = A13_2
  L22_2 = "function"
  L23_2 = nil
  L20_2 = L20_2(L21_2, L22_2, L23_2)
  A13_2 = L20_2
  L20_2 = _ValidateParameter
  L21_2 = A14_2
  L22_2 = "table"
  L23_2 = {}
  L20_2 = L20_2(L21_2, L22_2, L23_2)
  A14_2 = L20_2
  if nil == A19_2 then
    A19_2 = true
  end
  L20_2 = _BuildNumericBox
  L21_2 = A1_2
  L22_2 = A2_2
  L23_2 = A3_2
  L24_2 = A4_2
  L25_2 = A5_2
  L26_2 = A6_2
  L27_2 = A7_2
  L28_2 = A8_2
  L29_2 = A9_2
  L30_2 = A10_2
  L31_2 = A11_2
  L32_2 = A12_2
  L33_2 = A13_2
  L34_2 = A14_2
  L35_2 = A15_2
  L36_2 = A16_2
  L37_2 = A17_2
  L38_2 = A18_2
  L20_2 = L20_2(L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2)
  L22_2 = L20_2
  L21_2 = L20_2.SetOwner
  L23_2 = A0_2
  L21_2(L22_2, L23_2)
  L21_2 = MrxGuiBase
  L21_2 = L21_2.GetControlFocus
  L22_2 = L20_2
  L23_2 = A19_2
  L21_2(L22_2, L23_2)
  L21_2 = Close
  L20_2.Close = L21_2
  return L20_2
end

DisplayNumericBox = L0_1

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
L0_1 = 70
_knCursorHeight = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2, A9_2, A10_2, A11_2, A12_2, A13_2, A14_2, A15_2, A16_2, A17_2)
  local L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2, L47_2, L48_2, L49_2, L50_2, L51_2, L52_2, L53_2, L54_2, L55_2, L56_2, L57_2, L58_2, L59_2, L60_2, L61_2, L62_2, L63_2, L64_2, L65_2, L66_2, L67_2, L68_2, L69_2, L70_2, L71_2
  L18_2 = 170
  L19_2 = 100
  L20_2 = 298
  L21_2 = 10
  L22_2 = 20
  L23_2 = L19_2
  L24_2 = MrxGuiBase
  L24_2 = L24_2.ImageWidget
  L25_2 = L24_2
  L24_2 = L24_2.new
  L24_2 = L24_2(L25_2)
  L26_2 = L24_2
  L25_2 = L24_2.SetLocation
  L27_2 = L18_2
  L28_2 = L19_2
  L29_2 = L18_2 + L20_2
  L30_2 = 400
  L25_2(L26_2, L27_2, L28_2, L29_2, L30_2)
  L25_2 = L24_2.BasicData
  L25_2.bContainer = true
  L26_2 = L24_2
  L25_2 = L24_2.SetOwner
  L27_2 = uPlayerGuid
  L25_2(L26_2, L27_2)
  L26_2 = L24_2
  L25_2 = L24_2.SetVisible
  L27_2 = false
  L25_2(L26_2, L27_2)
  L25_2 = MrxGuiBase
  L25_2 = L25_2.TextWidget
  L26_2 = L25_2
  L25_2 = L25_2.new
  L25_2 = L25_2(L26_2)
  L27_2 = L25_2
  L26_2 = L25_2.SetLocation
  L28_2 = L18_2 + L21_2
  L29_2 = L23_2 + L22_2
  L30_2 = L18_2 + L20_2
  L30_2 = L30_2 - L21_2
  L31_2 = 390
  L26_2(L27_2, L28_2, L29_2, L30_2, L31_2)
  L27_2 = L25_2
  L26_2 = L25_2.SetFont
  L28_2 = _ksFontSmall
  L26_2(L27_2, L28_2)
  L27_2 = L25_2
  L26_2 = L25_2.SetScale
  L28_2 = _knScale
  L26_2(L27_2, L28_2)
  L27_2 = L25_2
  L26_2 = L25_2.SetColor
  L28_2 = _knTextLitR
  L29_2 = _knTextLitG
  L30_2 = _knTextLitB
  L26_2(L27_2, L28_2, L29_2, L30_2)
  L27_2 = L25_2
  L26_2 = L25_2.SetText
  L28_2 = A0_2
  L26_2(L27_2, L28_2)
  L27_2 = L25_2
  L26_2 = L25_2.Wrap
  L26_2(L27_2)
  L27_2 = L25_2
  L26_2 = L25_2.SetOwner
  L28_2 = uPlayerGuid
  L26_2(L27_2, L28_2)
  L25_2.ParentWidget = L24_2
  L27_2 = L25_2
  L26_2 = L25_2.GetHeight
  L26_2 = L26_2(L27_2)
  L26_2 = L23_2 + L26_2
  L27_2 = L22_2 * 2.5
  L23_2 = L26_2 + L27_2
  L26_2 = L21_2 + L18_2
  L27_2 = MrxGuiBase
  L27_2 = L27_2.TextWidget
  L28_2 = L27_2
  L27_2 = L27_2.new
  L27_2 = L27_2(L28_2)
  L29_2 = L27_2
  L28_2 = L27_2.SetLocation
  L30_2 = L26_2
  L31_2 = L23_2
  L32_2 = L18_2 + L20_2
  L32_2 = L32_2 - L21_2
  L33_2 = 390
  L28_2(L29_2, L30_2, L31_2, L32_2, L33_2)
  L29_2 = L27_2
  L28_2 = L27_2.SetFont
  L30_2 = _ksFont
  L28_2(L29_2, L30_2)
  L29_2 = L27_2
  L28_2 = L27_2.SetScale
  L30_2 = _knScaleBig
  L28_2(L29_2, L30_2)
  L29_2 = L27_2
  L28_2 = L27_2.SetColor
  L30_2 = _knTextR
  L31_2 = _knTextG
  L32_2 = _knTextB
  L28_2(L29_2, L30_2, L31_2, L32_2)
  L29_2 = L27_2
  L28_2 = L27_2.SetText
  L30_2 = A2_2
  L28_2(L29_2, L30_2)
  L29_2 = L27_2
  L28_2 = L27_2.SetOwner
  L30_2 = uPlayerGuid
  L28_2(L29_2, L30_2)
  L27_2.ParentWidget = L24_2
  L29_2 = L27_2
  L28_2 = L27_2.GetWidth
  L28_2 = L28_2(L29_2)
  L26_2 = L26_2 + L28_2
  L28_2 = MrxGuiBase
  L28_2 = L28_2.ImageWidget
  L29_2 = L28_2
  L28_2 = L28_2.new
  L28_2 = L28_2(L29_2)
  L30_2 = L28_2
  L29_2 = L28_2.SetTranslucency
  L31_2 = 0
  L29_2(L30_2, L31_2)
  L30_2 = L28_2
  L29_2 = L28_2.SetLocation
  L31_2 = L26_2
  L32_2 = L23_2
  L33_2 = L18_2 + L20_2
  L33_2 = L33_2 - L21_2
  L34_2 = 390
  L29_2(L30_2, L31_2, L32_2, L33_2, L34_2)
  L30_2 = L28_2
  L29_2 = L28_2.SetOwner
  L31_2 = uPlayerGuid
  L29_2(L30_2, L31_2)
  L28_2.ParentWidget = L24_2
  L29_2 = 0
  L30_2 = 10
  L31_2 = {}
  L32_2 = A9_2
  L33_2 = A8_2
  L34_2 = -1
  for L35_2 = L32_2, L33_2, L34_2 do
    L36_2 = MrxGuiBase
    L36_2 = L36_2.TextWidget
    L37_2 = L36_2
    L36_2 = L36_2.new
    L36_2 = L36_2(L37_2)
    L38_2 = L36_2
    L37_2 = L36_2.SetLocation
    L39_2 = L26_2
    L40_2 = L23_2
    L41_2 = L18_2 + L20_2
    L41_2 = L41_2 - L21_2
    L42_2 = L23_2
    L37_2(L38_2, L39_2, L40_2, L41_2, L42_2)
    L38_2 = L36_2
    L37_2 = L36_2.SetFont
    L39_2 = _ksFont
    L37_2(L38_2, L39_2)
    L38_2 = L36_2
    L37_2 = L36_2.SetScale
    L39_2 = _knScaleBig
    L37_2(L38_2, L39_2)
    L38_2 = L36_2
    L37_2 = L36_2.SetColor
    L39_2 = _knTextR
    L40_2 = _knTextG
    L41_2 = _knTextB
    L37_2(L38_2, L39_2, L40_2, L41_2)
    L38_2 = L36_2
    L37_2 = L36_2.SetText
    L39_2 = "0"
    L37_2(L38_2, L39_2)
    L38_2 = L36_2
    L37_2 = L36_2.SetJustification
    L39_2 = "center"
    L37_2(L38_2, L39_2)
    L38_2 = L36_2
    L37_2 = L36_2.SetOwner
    L39_2 = uPlayerGuid
    L37_2(L38_2, L39_2)
    L36_2.ParentWidget = L28_2
    L38_2 = L28_2
    L37_2 = L28_2.AddChild
    L39_2 = L36_2
    L37_2(L38_2, L39_2)
    L37_2 = L36_2.CustomData
    L37_2.nValue = 0
    L37_2 = L36_2.CustomData
    L38_2 = math
    L38_2 = L38_2.pow
    L39_2 = 10
    L40_2 = L35_2
    L38_2 = L38_2(L39_2, L40_2)
    L37_2.nScale = L38_2
    L38_2 = L36_2
    L37_2 = L36_2.GetWidth
    L37_2 = L37_2(L38_2)
    L37_2 = L37_2 * 1.5
    L30_2 = L37_2
    L39_2 = L36_2
    L38_2 = L36_2.GetHeight
    L38_2 = L38_2(L39_2)
    L40_2 = L36_2
    L39_2 = L36_2.SetLocation
    L41_2 = L26_2
    L42_2 = L23_2
    L43_2 = L26_2 + L37_2
    L44_2 = L23_2 + L38_2
    L39_2(L40_2, L41_2, L42_2, L43_2, L44_2)
    L39_2 = MrxGuiBase
    L39_2 = L39_2.ImageWidget
    L40_2 = L39_2
    L39_2 = L39_2.new
    L39_2 = L39_2(L40_2)
    L41_2 = L39_2
    L40_2 = L39_2.SetColor
    L42_2 = 63
    L43_2 = 59.25
    L44_2 = 42.75
    L40_2(L41_2, L42_2, L43_2, L44_2)
    L41_2 = L39_2
    L40_2 = L39_2.SetTranslucency
    L42_2 = 255
    L40_2(L41_2, L42_2)
    L41_2 = L39_2
    L40_2 = L39_2.SetLocation
    L42_2 = L26_2
    L43_2 = L23_2
    L44_2 = L26_2 + L37_2
    L45_2 = L23_2 + L38_2
    L40_2(L41_2, L42_2, L43_2, L44_2, L45_2)
    L41_2 = L39_2
    L40_2 = L39_2.SetOwner
    L42_2 = uPlayerGuid
    L40_2(L41_2, L42_2)
    L39_2.ParentWidget = L24_2
    L40_2 = table
    L40_2 = L40_2.insert
    L41_2 = L31_2
    L42_2 = L39_2
    L40_2(L41_2, L42_2)
    L40_2 = L26_2 + L37_2
    L26_2 = L40_2 + 2
    L40_2 = math
    L40_2 = L40_2.max
    L41_2 = L29_2
    L42_2 = L38_2
    L40_2 = L40_2(L41_2, L42_2)
    L29_2 = L40_2
  end
  L32_2 = MrxGuiBase
  L32_2 = L32_2.ImageWidget
  L33_2 = L32_2
  L32_2 = L32_2.new
  L32_2 = L32_2(L33_2)
  L34_2 = L32_2
  L33_2 = L32_2.SetColor
  L35_2 = 84
  L36_2 = 79
  L37_2 = 57
  L33_2(L34_2, L35_2, L36_2, L37_2)
  L34_2 = L32_2
  L33_2 = L32_2.SetTranslucency
  L35_2 = 0
  L33_2(L34_2, L35_2)
  L34_2 = L32_2
  L33_2 = L32_2.SetVisible
  L35_2 = false
  L33_2(L34_2, L35_2)
  L34_2 = L32_2
  L33_2 = L32_2.SetLocation
  L35_2 = L18_2 + L21_2
  L36_2 = 0
  L37_2 = L18_2 + L21_2
  L37_2 = L37_2 + L30_2
  L38_2 = _knCursorHeight
  L33_2(L34_2, L35_2, L36_2, L37_2, L38_2)
  L34_2 = L32_2
  L33_2 = L32_2.SetOwner
  L35_2 = uPlayerGuid
  L33_2(L34_2, L35_2)
  L32_2.ParentWidget = L24_2
  L33_2 = L32_2.CustomData
  L35_2 = L32_2
  L34_2 = L32_2.AddAnimationPoint
  L36_2 = {}
  L36_2.x = 1
  L36_2.x2 = 1
  L34_2 = L34_2(L35_2, L36_2)
  L33_2.nClosePoint = L34_2
  L33_2 = L32_2.CustomData
  L35_2 = L32_2
  L34_2 = L32_2.AddAnimationPoint
  L36_2 = {}
  L36_2.x = 1
  L36_2.x2 = 1
  L34_2 = L34_2(L35_2, L36_2)
  L33_2.nOpenPoint = L34_2
  L33_2 = L32_2.CustomData
  L35_2 = L32_2
  L34_2 = L32_2.AddAnimationPoint
  L36_2 = {}
  L36_2.TranslucencyLevel = 255
  L34_2 = L34_2(L35_2, L36_2)
  L33_2.nPulseHighPoint = L34_2
  L33_2 = L32_2.CustomData
  L35_2 = L32_2
  L34_2 = L32_2.AddAnimationPoint
  L36_2 = {}
  L36_2.TranslucencyLevel = 100
  L34_2 = L34_2(L35_2, L36_2)
  L33_2.nPulseLowPoint = L34_2
  L34_2 = L32_2
  L33_2 = L32_2.SetIgnoresPause
  L35_2 = true
  L33_2(L34_2, L35_2)
  L33_2 = MrxGuiBase
  L33_2 = L33_2.ImageWidget
  L34_2 = L33_2
  L33_2 = L33_2.new
  L33_2 = L33_2(L34_2)
  L35_2 = L33_2
  L34_2 = L33_2.SetColor
  L36_2 = 84
  L37_2 = 79
  L38_2 = 57
  L34_2(L35_2, L36_2, L37_2, L38_2)
  L35_2 = L33_2
  L34_2 = L33_2.SetTranslucency
  L36_2 = 205
  L34_2(L35_2, L36_2)
  L35_2 = L33_2
  L34_2 = L33_2.SetLocation
  L36_2 = L18_2 + L21_2
  L37_2 = 0
  L38_2 = L18_2 + L21_2
  L38_2 = L38_2 + L30_2
  L39_2 = _knCursorHeight
  L34_2(L35_2, L36_2, L37_2, L38_2, L39_2)
  L35_2 = L33_2
  L34_2 = L33_2.SetOwner
  L36_2 = uPlayerGuid
  L34_2(L35_2, L36_2)
  L33_2.ParentWidget = L32_2
  L34_2 = L33_2.CustomData
  L36_2 = L33_2
  L35_2 = L33_2.AddAnimationPoint
  L37_2 = {}
  L37_2.TranslucencyLevel = 255
  L35_2 = L35_2(L36_2, L37_2)
  L34_2.nPulseHighPoint = L35_2
  L34_2 = L33_2.CustomData
  L36_2 = L33_2
  L35_2 = L33_2.AddAnimationPoint
  L37_2 = {}
  L37_2.TranslucencyLevel = 100
  L35_2 = L35_2(L36_2, L37_2)
  L34_2.nPulseLowPoint = L35_2
  L35_2 = L33_2
  L34_2 = L33_2.SetIgnoresPause
  L36_2 = true
  L34_2(L35_2, L36_2)
  L35_2 = L32_2
  L34_2 = L32_2.AddChild
  L36_2 = L33_2
  L34_2(L35_2, L36_2)
  L34_2 = Pulse
  L35_2 = L33_2
  L34_2(L35_2)
  L34_2 = MrxGuiBase
  L34_2 = L34_2.ImageWidget
  L35_2 = L34_2
  L34_2 = L34_2.new
  L34_2 = L34_2(L35_2)
  L36_2 = L34_2
  L35_2 = L34_2.SetTexture
  L37_2 = "global_gui_hud02"
  L35_2(L36_2, L37_2)
  L36_2 = L34_2
  L35_2 = L34_2.SetTextureCoordinates
  L37_2 = 0.001953
  L38_2 = 0.947266
  L39_2 = 0.162109
  L40_2 = 0.986328
  L35_2(L36_2, L37_2, L38_2, L39_2, L40_2)
  L36_2 = L34_2
  L35_2 = L34_2.SetLocation
  L37_2 = L18_2 + L21_2
  L38_2 = 0
  L39_2 = L18_2 + L21_2
  L39_2 = L39_2 + L30_2
  L40_2 = L30_2
  L35_2(L36_2, L37_2, L38_2, L39_2, L40_2)
  L36_2 = L32_2
  L35_2 = L32_2.AddChild
  L37_2 = L34_2
  L35_2(L36_2, L37_2)
  L35_2 = MrxGuiBase
  L35_2 = L35_2.ImageWidget
  L36_2 = L35_2
  L35_2 = L35_2.new
  L35_2 = L35_2(L36_2)
  L37_2 = L35_2
  L36_2 = L35_2.SetTexture
  L38_2 = "global_gui_hud02"
  L36_2(L37_2, L38_2)
  L37_2 = L35_2
  L36_2 = L35_2.SetTextureCoordinates
  L38_2 = 0.001953
  L39_2 = 0.986328
  L40_2 = 0.162109
  L41_2 = 0.947266
  L36_2(L37_2, L38_2, L39_2, L40_2, L41_2)
  L36_2 = L30_2
  L38_2 = L35_2
  L37_2 = L35_2.SetLocation
  L39_2 = L18_2 + L21_2
  L40_2 = _knCursorHeight
  L40_2 = L40_2 - L36_2
  L41_2 = L18_2 + L21_2
  L41_2 = L41_2 + L30_2
  L42_2 = _knCursorHeight
  L37_2(L38_2, L39_2, L40_2, L41_2, L42_2)
  L38_2 = L32_2
  L37_2 = L32_2.AddChild
  L39_2 = L35_2
  L37_2(L38_2, L39_2)
  L37_2 = MrxGuiBase
  L37_2 = L37_2.TextWidget
  L38_2 = L37_2
  L37_2 = L37_2.new
  L37_2 = L37_2(L38_2)
  L39_2 = L37_2
  L38_2 = L37_2.SetLocation
  L40_2 = L26_2
  L41_2 = L23_2
  L42_2 = L18_2 + L20_2
  L42_2 = L42_2 - L21_2
  L43_2 = 390
  L38_2(L39_2, L40_2, L41_2, L42_2, L43_2)
  L39_2 = L37_2
  L38_2 = L37_2.SetFont
  L40_2 = _ksFont
  L38_2(L39_2, L40_2)
  L39_2 = L37_2
  L38_2 = L37_2.SetScale
  L40_2 = _knScaleBig
  L38_2(L39_2, L40_2)
  L39_2 = L37_2
  L38_2 = L37_2.SetColor
  L40_2 = _knTextR
  L41_2 = _knTextG
  L42_2 = _knTextB
  L38_2(L39_2, L40_2, L41_2, L42_2)
  L39_2 = L37_2
  L38_2 = L37_2.SetText
  L40_2 = A3_2
  L38_2(L39_2, L40_2)
  L39_2 = L37_2
  L38_2 = L37_2.SetOwner
  L40_2 = uPlayerGuid
  L38_2(L39_2, L40_2)
  L37_2.ParentWidget = L24_2
  L38_2 = L23_2 + L29_2
  L39_2 = _knCursorHeight
  L39_2 = L39_2 - L29_2
  L39_2 = L39_2 * 0.5
  L38_2 = L38_2 + L39_2
  L23_2 = L38_2 + 8
  L38_2 = L24_2.CustomData
  L39_2 = A9_2 - A7_2
  L39_2 = L39_2 + 1
  L38_2.nSelectedIndex = L39_2
  L39_2 = L28_2
  L38_2 = L28_2.GetChildren
  L38_2 = L38_2(L39_2)
  L39_2 = L24_2.CustomData
  L39_2 = L39_2.nSelectedIndex
  L38_2 = L38_2[L39_2]
  if not L38_2 then
    L38_2 = L24_2.CustomData
    L38_2.nSelectedIndex = 1
  end
  L39_2 = L28_2
  L38_2 = L28_2.GetChildren
  L38_2 = L38_2(L39_2)
  L39_2 = L24_2.CustomData
  L39_2 = L39_2.nSelectedIndex
  L38_2 = L38_2[L39_2]
  L40_2 = L38_2
  L39_2 = L38_2.GetLocation
  L39_2, L40_2, L41_2, L42_2 = L39_2(L40_2)
  L43_2 = L42_2 + L40_2
  L43_2 = L43_2 * 0.5
  L44_2 = _knCursorHeight
  L44_2 = L44_2 * 0.5
  L43_2 = L43_2 - L44_2
  L45_2 = L32_2
  L44_2 = L32_2.SetLocation
  L46_2 = L39_2
  L47_2 = L43_2
  L48_2 = L41_2
  L49_2 = _knCursorHeight
  L49_2 = L43_2 + L49_2
  L44_2(L45_2, L46_2, L47_2, L48_2, L49_2)
  L45_2 = L38_2
  L44_2 = L38_2.SetColor
  L46_2 = _knTextLitR
  L47_2 = _knTextLitG
  L48_2 = _knTextLitB
  L44_2(L45_2, L46_2, L47_2, L48_2)
  L44_2 = nil
  if A1_2 then
    L45_2 = MrxGuiBase
    L45_2 = L45_2.TextWidget
    L46_2 = L45_2
    L45_2 = L45_2.new
    L45_2 = L45_2(L46_2)
    L44_2 = L45_2
    L46_2 = L44_2
    L45_2 = L44_2.SetFont
    L47_2 = _ksFontSmall
    L45_2(L46_2, L47_2)
    L46_2 = L44_2
    L45_2 = L44_2.SetJustification
    L47_2 = "left"
    L45_2(L46_2, L47_2)
    L46_2 = L44_2
    L45_2 = L44_2.SetColor
    L47_2 = _knTextR
    L48_2 = _knTextG
    L49_2 = _knTextB
    L45_2(L46_2, L47_2, L48_2, L49_2)
    L46_2 = L44_2
    L45_2 = L44_2.SetText
    L47_2 = A1_2
    L45_2(L46_2, L47_2)
    L46_2 = L44_2
    L45_2 = L44_2.SetOwner
    L47_2 = uPlayerGuid
    L45_2(L46_2, L47_2)
    L46_2 = L44_2
    L45_2 = L44_2.GetHeight
    L45_2 = L45_2(L46_2)
    L47_2 = L44_2
    L46_2 = L44_2.SetLocation
    L48_2 = L18_2 + L21_2
    L49_2 = L23_2
    L50_2 = L18_2 + L20_2
    L50_2 = L50_2 - L21_2
    L51_2 = L23_2 + L36_2
    L46_2(L47_2, L48_2, L49_2, L50_2, L51_2)
    L46_2 = L23_2 + L45_2
    L23_2 = L46_2 + L21_2
  end
  L45_2 = MrxGuiBase
  L45_2 = L45_2.TextWidget
  L46_2 = L45_2
  L45_2 = L45_2.new
  L45_2 = L45_2(L46_2)
  L47_2 = L45_2
  L46_2 = L45_2.SetFont
  L48_2 = _ksFontSmall
  L46_2(L47_2, L48_2)
  L47_2 = L45_2
  L46_2 = L45_2.SetJustification
  L48_2 = "center"
  L46_2(L47_2, L48_2)
  L47_2 = L45_2
  L46_2 = L45_2.SetColor
  L48_2 = _knTextR
  L49_2 = _knTextG
  L50_2 = _knTextB
  L46_2(L47_2, L48_2, L49_2, L50_2)
  L47_2 = L45_2
  L46_2 = L45_2.SetText
  L48_2 = "[move] [PDA.Common.MoveSelection]  [confirm] [Generic.Confirm]"
  L46_2(L47_2, L48_2)
  L47_2 = L45_2
  L46_2 = L45_2.SetOwner
  L48_2 = uPlayerGuid
  L46_2(L47_2, L48_2)
  L47_2 = L45_2
  L46_2 = L45_2.GetHeight
  L46_2 = L46_2(L47_2)
  L48_2 = L45_2
  L47_2 = L45_2.SetLocation
  L49_2 = L18_2 + L21_2
  L50_2 = L23_2
  L51_2 = L18_2 + L20_2
  L51_2 = L51_2 - L21_2
  L52_2 = L23_2 + L36_2
  L47_2(L48_2, L49_2, L50_2, L51_2, L52_2)
  L47_2 = L23_2 + L36_2
  L23_2 = L47_2 - 10
  L47_2 = {}
  L48_2 = 0
  L49_2 = 0.8730469
  L50_2 = 0
  L51_2 = 0.078125
  L52_2 = 0.083984375
  L53_2 = 0.17382812
  L54_2 = 0.1796875
  L55_2 = 0.2734375
  L56_2 = 0.6666667
  L57_2 = 447 * L56_2
  L58_2 = 48 * L56_2
  L59_2 = 46 * L56_2
  L60_2 = 48 * L56_2
  L61_2 = L23_2 - L19_2
  L62_2 = "global_gui_hud02"
  L63_2 = L19_2
  L64_2 = 2
  L65_2 = MrxGuiBase
  L65_2 = L65_2.ImageWidget
  L66_2 = L65_2
  L65_2 = L65_2.new
  L65_2 = L65_2(L66_2)
  L47_2[1] = L65_2
  L65_2 = L47_2[1]
  L66_2 = L65_2
  L65_2 = L65_2.SetTexture
  L67_2 = L62_2
  L65_2(L66_2, L67_2)
  L65_2 = L47_2[1]
  L66_2 = L65_2
  L65_2 = L65_2.SetLocation
  L67_2 = L18_2
  L68_2 = L63_2
  L69_2 = L18_2 + L57_2
  L70_2 = L63_2 + L58_2
  L65_2(L66_2, L67_2, L68_2, L69_2, L70_2)
  L65_2 = L47_2[1]
  L66_2 = L65_2
  L65_2 = L65_2.SetTextureCoordinates
  L67_2 = L48_2
  L68_2 = L55_2
  L69_2 = L49_2
  L70_2 = L54_2
  L65_2(L66_2, L67_2, L68_2, L69_2, L70_2)
  L65_2 = L47_2[1]
  L66_2 = L65_2
  L65_2 = L65_2.SetOwner
  L67_2 = uPlayerGuid
  L65_2(L66_2, L67_2)
  L61_2 = L61_2 - L58_2
  L63_2 = L63_2 + L58_2
  L65_2 = 20 * L56_2
  L65_2 = L60_2 - L65_2
  L65_2 = L61_2 - L65_2
  L59_2 = L65_2 + L22_2
  L65_2 = MrxGuiBase
  L65_2 = L65_2.ImageWidget
  L66_2 = L65_2
  L65_2 = L65_2.new
  L65_2 = L65_2(L66_2)
  L47_2[L64_2] = L65_2
  L65_2 = L47_2[L64_2]
  L66_2 = L65_2
  L65_2 = L65_2.SetTexture
  L67_2 = L62_2
  L65_2(L66_2, L67_2)
  L65_2 = L47_2[L64_2]
  L66_2 = L65_2
  L65_2 = L65_2.SetLocation
  L67_2 = L18_2
  L68_2 = L63_2
  L69_2 = L18_2 + L57_2
  L70_2 = L63_2 + L59_2
  L65_2(L66_2, L67_2, L68_2, L69_2, L70_2)
  L65_2 = L47_2[L64_2]
  L66_2 = L65_2
  L65_2 = L65_2.SetTextureCoordinates
  L67_2 = L48_2
  L68_2 = L52_2
  L69_2 = L49_2
  L70_2 = L53_2
  L65_2(L66_2, L67_2, L68_2, L69_2, L70_2)
  L65_2 = L47_2[L64_2]
  L66_2 = L65_2
  L65_2 = L65_2.SetOwner
  L67_2 = uPlayerGuid
  L65_2(L66_2, L67_2)
  L61_2 = L61_2 - L59_2
  L63_2 = L63_2 + L59_2
  L64_2 = L64_2 + 1
  L65_2 = MrxGuiBase
  L65_2 = L65_2.ImageWidget
  L66_2 = L65_2
  L65_2 = L65_2.new
  L65_2 = L65_2(L66_2)
  L47_2[L64_2] = L65_2
  L65_2 = L47_2[L64_2]
  L66_2 = L65_2
  L65_2 = L65_2.SetTexture
  L67_2 = L62_2
  L65_2(L66_2, L67_2)
  L65_2 = L47_2[L64_2]
  L66_2 = L65_2
  L65_2 = L65_2.SetLocation
  L67_2 = L18_2
  L68_2 = L63_2
  L69_2 = L18_2 + L57_2
  L70_2 = L63_2 + L60_2
  L65_2(L66_2, L67_2, L68_2, L69_2, L70_2)
  L65_2 = L47_2[L64_2]
  L66_2 = L65_2
  L65_2 = L65_2.SetTextureCoordinates
  L67_2 = L48_2
  L68_2 = L54_2
  L69_2 = L49_2
  L70_2 = L55_2
  L65_2(L66_2, L67_2, L68_2, L69_2, L70_2)
  L65_2 = L47_2[L64_2]
  L66_2 = L65_2
  L65_2 = L65_2.SetOwner
  L67_2 = uPlayerGuid
  L65_2(L66_2, L67_2)
  L63_2 = L63_2 + L60_2
  L64_2 = 1
  while true do
    L65_2 = L47_2[L64_2]
    if not L65_2 then
      break
    end
    L66_2 = L24_2
    L65_2 = L24_2.AddChild
    L67_2 = L47_2[L64_2]
    L65_2(L66_2, L67_2)
    L64_2 = L64_2 + 1
  end
  L64_2 = 1
  while true do
    L65_2 = L31_2[L64_2]
    if not L65_2 then
      break
    end
    L66_2 = L24_2
    L65_2 = L24_2.AddChild
    L67_2 = L31_2[L64_2]
    L65_2(L66_2, L67_2)
    L64_2 = L64_2 + 1
  end
  L66_2 = L24_2
  L65_2 = L24_2.AddChild
  L67_2 = L25_2
  L65_2(L66_2, L67_2)
  L66_2 = L24_2
  L65_2 = L24_2.AddChild
  L67_2 = L32_2
  L65_2(L66_2, L67_2)
  L66_2 = L24_2
  L65_2 = L24_2.AddChild
  L67_2 = L27_2
  L65_2(L66_2, L67_2)
  L66_2 = L24_2
  L65_2 = L24_2.AddChild
  L67_2 = L28_2
  L65_2(L66_2, L67_2)
  L66_2 = L24_2
  L65_2 = L24_2.AddChild
  L67_2 = L37_2
  L65_2(L66_2, L67_2)
  L66_2 = L24_2
  L65_2 = L24_2.AddChild
  L67_2 = L45_2
  L65_2(L66_2, L67_2)
  if L44_2 then
    L66_2 = L24_2
    L65_2 = L24_2.AddChild
    L67_2 = L44_2
    L65_2(L66_2, L67_2)
  end
  L65_2 = L24_2.CustomData
  L65_2.oCursor = L32_2
  L65_2 = L24_2.CustomData
  L65_2.oDigits = L28_2
  L65_2 = L24_2.CustomData
  L65_2.nMinimumDigit = A8_2
  L65_2 = L24_2.CustomData
  L65_2.nMaximumDigit = A9_2
  L65_2 = L24_2.CustomData
  L65_2.nMinimumValue = A5_2
  L65_2 = L24_2.CustomData
  L65_2.nMaximumValue = A6_2
  L65_2 = L24_2.CustomData
  L65_2.fAcceptCallback = A10_2
  L65_2 = L24_2.CustomData
  L65_2.tAcceptCallbackArgs = A11_2
  L65_2 = L24_2.CustomData
  L65_2.fCancelCallback = A12_2
  L65_2 = L24_2.CustomData
  L65_2.tCancelCallbackArgs = A13_2
  L65_2 = L63_2 - L19_2
  L66_2 = L65_2 / 2
  L19_2 = 240 - L66_2
  if L19_2 < 0 then
    L19_2 = 0
  end
  L67_2 = L24_2
  L66_2 = L24_2.SetLocation
  L68_2 = L18_2
  L69_2 = L19_2
  L66_2(L67_2, L68_2, L69_2)
  L67_2 = L24_2
  L66_2 = L24_2.SetCoordinates
  L68_2 = L18_2
  L69_2 = L19_2
  L70_2 = L18_2 + L20_2
  L71_2 = L19_2 + L65_2
  L66_2(L67_2, L68_2, L69_2, L70_2, L71_2)
  if A14_2 and A15_2 and A16_2 and A17_2 then
    L61_2 = L65_2
    L66_2 = nil
    L67_2 = nil
    if "left" == A16_2 then
      if A14_2 < 48 then
        A14_2 = 48
      end
      L66_2 = A14_2
    elseif "right" == A16_2 then
      if A14_2 < 48 then
        A14_2 = 48
      end
      L68_2 = 640 - L20_2
      L66_2 = L68_2 - A14_2
    elseif "center" == A16_2 then
      L68_2 = L20_2 * 0.5
      L68_2 = A14_2 - L68_2
      L66_2 = L68_2 + 320
      if L66_2 < 48 then
        L66_2 = 48
      else
        L68_2 = 592 - L20_2
        if L66_2 > L68_2 then
          L66_2 = 592 - L20_2
        end
      end
    end
    if "top" == A17_2 then
      if A15_2 < 36 then
        A15_2 = 36
      end
      L67_2 = A15_2
    elseif "bottom" == A17_2 then
      if A15_2 < 36 then
        A15_2 = 36
      end
      L68_2 = 480 - L61_2
      L67_2 = L68_2 - A15_2
    elseif "center" == A17_2 then
      L68_2 = L61_2 * 0.5
      L68_2 = A15_2 - L68_2
      L67_2 = L68_2 + 240
      if L67_2 < 36 then
        L67_2 = 36
      else
        L68_2 = 444 - L61_2
        if L67_2 > L68_2 then
          L67_2 = 444 - L61_2
        end
      end
    end
    L69_2 = L24_2
    L68_2 = L24_2.SetAnchoring
    L70_2 = A16_2
    L71_2 = A17_2
    L68_2(L69_2, L70_2, L71_2)
    L69_2 = L24_2
    L68_2 = L24_2.SetLocation
    L70_2 = L66_2
    L71_2 = L67_2
    L68_2(L69_2, L70_2, L71_2)
  end
  L66_2 = MrxGuiBase
  L66_2 = L66_2.AddWidgetWithChildren
  L67_2 = L24_2
  L66_2(L67_2)
  L67_2 = L24_2
  L66_2 = L24_2.SetEventHandler
  L68_2 = "ControllerInput"
  L69_2 = _HandleInputEvent
  L66_2(L67_2, L68_2, L69_2)
  L66_2 = _ComputeValue
  L24_2._ComputeValue = L66_2
  L66_2 = _SetValue
  L24_2._SetValue = L66_2
  L66_2 = _ChangeSelection
  L24_2._ChangeSelection = L66_2
  L66_2 = _ModifySelection
  L24_2._ModifySelection = L66_2
  L67_2 = L24_2
  L66_2 = L24_2._SetValue
  L68_2 = A4_2
  L66_2(L67_2, L68_2)
  return L24_2
end

_BuildNumericBox = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = 0
  L2_2 = ipairs
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oDigits
  L4_2 = L3_2
  L3_2 = L3_2.GetChildren
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L3_2(L4_2)
  L2_2, L3_2, L4_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = L6_2.CustomData
    L7_2 = L7_2.nValue
    L8_2 = L6_2.CustomData
    L8_2 = L8_2.nScale
    L7_2 = L7_2 * L8_2
    L1_2 = L1_2 + L7_2
  end
  return L1_2
end

_ComputeValue = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = string
  L2_2 = L2_2.format
  L3_2 = "%0"
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nMaximumDigit
  L4_2 = L4_2 + 1
  L5_2 = "d"
  L3_2 = L3_2 .. L4_2 .. L5_2
  L4_2 = A1_2
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = ipairs
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oDigits
  L5_2 = L4_2
  L4_2 = L4_2.GetChildren
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L4_2(L5_2)
  L3_2, L4_2, L5_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = string
    L8_2 = L8_2.sub
    L9_2 = L2_2
    L10_2 = L6_2
    L11_2 = L6_2
    L8_2 = L8_2(L9_2, L10_2, L11_2)
    L9_2 = L7_2.CustomData
    L10_2 = tonumber
    L11_2 = L8_2
    L10_2 = L10_2(L11_2)
    L9_2.nValue = L10_2
    L10_2 = L7_2
    L9_2 = L7_2.SetText
    L11_2 = L8_2
    L9_2(L10_2, L11_2)
  end
end

_SetValue = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oDigits
  L3_2 = L2_2
  L2_2 = L2_2.GetChildren
  L2_2 = L2_2(L3_2)
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nSelectedIndex
  L3_2 = L2_2[L3_2]
  L5_2 = A0_2
  L4_2 = A0_2._ComputeValue
  L4_2 = L4_2(L5_2)
  L5_2 = L3_2.CustomData
  L5_2 = L5_2.nScale
  L5_2 = A1_2 * L5_2
  L5_2 = L4_2 + L5_2
  L6_2 = math
  L6_2 = L6_2.min
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.nMaximumValue
  L8_2 = L5_2
  L6_2 = L6_2(L7_2, L8_2)
  L5_2 = L6_2
  L6_2 = math
  L6_2 = L6_2.max
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.nMinimumValue
  L8_2 = L5_2
  L6_2 = L6_2(L7_2, L8_2)
  L5_2 = L6_2
  L7_2 = A0_2
  L6_2 = A0_2._SetValue
  L8_2 = L5_2
  L6_2(L7_2, L8_2)
  L7_2 = L3_2
  L6_2 = L3_2.SetText
  L8_2 = tostring
  L9_2 = L3_2.CustomData
  L9_2 = L9_2.nValue
  L8_2, L9_2 = L8_2(L9_2)
  L6_2(L7_2, L8_2, L9_2)
end

_ModifySelection = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oDigits
  L3_2 = L2_2
  L2_2 = L2_2.GetChildren
  L2_2 = L2_2(L3_2)
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nSelectedIndex
  L3_2 = L2_2[L3_2]
  L5_2 = L3_2
  L4_2 = L3_2.SetColor
  L6_2 = _knTextR
  L7_2 = _knTextG
  L8_2 = _knTextB
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = A0_2.CustomData
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nSelectedIndex
  L5_2 = L5_2 + A1_2
  L4_2.nSelectedIndex = L5_2
  if A1_2 < 0 then
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.nSelectedIndex
    if L4_2 < 1 then
      L4_2 = A0_2.CustomData
      L5_2 = #L2_2
      L4_2.nSelectedIndex = L5_2
    end
  else
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.nSelectedIndex
    L4_2 = L2_2[L4_2]
    if not L4_2 then
      L4_2 = A0_2.CustomData
      L4_2.nSelectedIndex = 1
    end
  end
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nSelectedIndex
  L4_2 = L2_2[L4_2]
  L6_2 = L4_2
  L5_2 = L4_2.GetLocation
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  L9_2 = A0_2.CustomData
  L9_2 = L9_2.oCursor
  L11_2 = L9_2
  L10_2 = L9_2.GetLocation
  L10_2, L11_2, L12_2, L13_2 = L10_2(L11_2)
  L14_2 = L11_2 + L13_2
  L14_2 = L14_2 * 0.5
  L15_2 = L8_2 + L6_2
  L15_2 = L15_2 / 2
  L16_2 = _knCursorHeight
  L16_2 = L16_2 * 0.5
  L15_2 = L15_2 - L16_2
  L17_2 = L9_2
  L16_2 = L9_2.SetAnimationPoint
  L18_2 = L9_2.CustomData
  L18_2 = L18_2.nOpenPoint
  L19_2 = {}
  L19_2.x = L5_2
  L19_2.y = L15_2
  L19_2.x2 = L7_2
  L20_2 = _knCursorHeight
  L20_2 = L15_2 + L20_2
  L19_2.y2 = L20_2
  L16_2(L17_2, L18_2, L19_2)
  L17_2 = L9_2
  L16_2 = L9_2.AnimateToPoint
  L18_2 = L9_2.CustomData
  L18_2 = L18_2.nOpenPoint
  L19_2 = 0.1
  L20_2 = true
  L16_2(L17_2, L18_2, L19_2, L20_2)
  L17_2 = L4_2
  L16_2 = L4_2.SetColor
  L18_2 = _knTextLitR
  L19_2 = _knTextLitG
  L20_2 = _knTextLitB
  L16_2(L17_2, L18_2, L19_2, L20_2)
end

_ChangeSelection = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L6_2 = A2_2 + A4_2
  L6_2 = L6_2 * 0.5
  L8_2 = A0_2
  L7_2 = A0_2.SetLocation
  L9_2 = A1_2
  L10_2 = L6_2
  L11_2 = A3_2
  L12_2 = L6_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L8_2 = A0_2
  L7_2 = A0_2.SetAnimationPoint
  L9_2 = A0_2.CustomData
  L9_2 = L9_2.nOpenPoint
  L10_2 = {}
  L10_2.x = A1_2
  L10_2.y = A2_2
  L10_2.x2 = A3_2
  L10_2.y2 = A4_2
  L7_2(L8_2, L9_2, L10_2)
  L8_2 = A0_2
  L7_2 = A0_2.AnimateToPoint
  L9_2 = A0_2.CustomData
  L9_2 = L9_2.nOpenPoint
  L10_2 = 0.075
  L11_2 = true
  L7_2(L8_2, L9_2, L10_2, L11_2)
  L8_2 = A5_2
  L7_2 = A5_2.SetColor
  L9_2 = _knTextLitR
  L10_2 = _knTextLitG
  L11_2 = _knTextLitB
  L7_2(L8_2, L9_2, L10_2, L11_2)
end

_CompleteAnimation = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
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
  L2_2 = A0_2._ModifySelection
  L4_2 = -1
  L2_2(L3_2, L4_2)
  L2_2 = Sound
  L2_2 = L2_2.CueSound
  L3_2 = 0
  L4_2 = _ksChangeSound
  L2_2(L3_2, L4_2)
  goto lbl_156
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
  L2_2 = A0_2._ModifySelection
  L4_2 = 1
  L2_2(L3_2, L4_2)
  L2_2 = Sound
  L2_2 = L2_2.CueSound
  L3_2 = 0
  L4_2 = _ksChangeSound
  L2_2(L3_2, L4_2)
  goto lbl_156
  ::lbl_43::
  L2_2 = MrxGuiBase
  L2_2 = L2_2.Joystick
  L2_2 = L2_2.BUTTON_PAD1_L
  L3_2 = A1_2.ButtonPress
  if L2_2 ~= L3_2 then
    L2_2 = MrxGuiBase
    L2_2 = L2_2.Joystick
    L2_2 = L2_2.BUTTON_L_STICK_L
    L3_2 = A1_2.ButtonPress
    if L2_2 ~= L3_2 then
      goto lbl_64
    end
  end
  L3_2 = A0_2
  L2_2 = A0_2._ChangeSelection
  L4_2 = -1
  L2_2(L3_2, L4_2)
  L2_2 = Sound
  L2_2 = L2_2.CueSound
  L3_2 = 0
  L4_2 = _ksChangeSound
  L2_2(L3_2, L4_2)
  goto lbl_156
  ::lbl_64::
  L2_2 = MrxGuiBase
  L2_2 = L2_2.Joystick
  L2_2 = L2_2.BUTTON_PAD1_R
  L3_2 = A1_2.ButtonPress
  if L2_2 ~= L3_2 then
    L2_2 = MrxGuiBase
    L2_2 = L2_2.Joystick
    L2_2 = L2_2.BUTTON_L_STICK_R
    L3_2 = A1_2.ButtonPress
    if L2_2 ~= L3_2 then
      goto lbl_85
    end
  end
  L3_2 = A0_2
  L2_2 = A0_2._ChangeSelection
  L4_2 = 1
  L2_2(L3_2, L4_2)
  L2_2 = Sound
  L2_2 = L2_2.CueSound
  L3_2 = 0
  L4_2 = _ksChangeSound
  L2_2(L3_2, L4_2)
  goto lbl_156
  ::lbl_85::
  L2_2 = MrxGuiBase
  L2_2 = L2_2.Joystick
  L2_2 = L2_2.BUTTON_PAD2_D
  L3_2 = A1_2.ButtonPress
  if L2_2 == L3_2 then
    L2_2 = MrxGuiBase
    L2_2 = L2_2.ReleaseControlFocus
    L3_2 = A0_2
    L2_2(L3_2)
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.fAcceptCallback
    if L2_2 then
      L2_2 = Sound
      L2_2 = L2_2.CueSound
      L3_2 = 0
      L4_2 = _ksAcceptSound
      L2_2(L3_2, L4_2)
      L2_2 = table
      L2_2 = L2_2.insert
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.tAcceptCallbackArgs
      L5_2 = A0_2
      L4_2 = A0_2._ComputeValue
      L4_2, L5_2 = L4_2(L5_2)
      L2_2(L3_2, L4_2, L5_2)
      L2_2 = A0_2.CustomData
      L2_2 = L2_2.fAcceptCallback
      L3_2 = unpack
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.tAcceptCallbackArgs
      L3_2, L4_2, L5_2 = L3_2(L4_2)
      L2_2(L3_2, L4_2, L5_2)
    end
    L3_2 = A0_2
    L2_2 = A0_2.Close
    L2_2(L3_2)
  else
    L2_2 = MrxGuiBase
    L2_2 = L2_2.Joystick
    L2_2 = L2_2.BUTTON_PAD2_R
    L3_2 = A1_2.ButtonPress
    if L2_2 == L3_2 then
      L2_2 = MrxGuiBase
      L2_2 = L2_2.ReleaseControlFocus
      L3_2 = A0_2
      L2_2(L3_2)
      L2_2 = A0_2.CustomData
      L2_2 = L2_2.fCancelCallback
      if L2_2 then
        L2_2 = Sound
        L2_2 = L2_2.CueSound
        L3_2 = 0
        L4_2 = _ksCancelSound
        L2_2(L3_2, L4_2)
        L2_2 = table
        L2_2 = L2_2.insert
        L3_2 = A0_2.CustomData
        L3_2 = L3_2.tAcceptCallbackArgs
        L5_2 = A0_2
        L4_2 = A0_2._ComputeValue
        L4_2, L5_2 = L4_2(L5_2)
        L2_2(L3_2, L4_2, L5_2)
        L2_2 = A0_2.CustomData
        L2_2 = L2_2.fCancelCallback
        L3_2 = unpack
        L4_2 = A0_2.CustomData
        L4_2 = L4_2.tCancelCallbackArgs
        L3_2, L4_2, L5_2 = L3_2(L4_2)
        L2_2(L3_2, L4_2, L5_2)
      end
      L3_2 = A0_2
      L2_2 = A0_2.Close
      L2_2(L3_2)
    end
  end
  ::lbl_156::
end

_HandleInputEvent = L0_1
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

function L0_1(A0_2, A1_2, A2_2)
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

_ValidateParameter = L0_1
