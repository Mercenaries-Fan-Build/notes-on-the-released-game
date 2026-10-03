local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiBase"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiManager"
L0_1(L1_1)
L0_1 = 50

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = false
  L3_2 = false
  L5_2 = A0_2
  L4_2 = A0_2.GetLocation
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  L8_2 = L7_2 - L5_2
  L9_2 = L6_2 - L4_2
  L10_2 = A0_2.BasicData
  L10_2 = L10_2.name
  if "MessageBox" == L10_2 then
    L3_2 = true
    L11_2 = A0_2
    L10_2 = A0_2.SetTranslucency
    L12_2 = 128
    L10_2(L11_2, L12_2)
  end
  L10_2 = A0_2.CustomData
  L10_2.sTextFont = "english_18"
  L10_2 = A0_2.CustomData
  L10_2.nTextScale = 1
  L10_2 = A0_2.CustomData
  L11_2 = L2_2 or L11_2
  if not L2_2 then
    L11_2 = false
  end
  L10_2.bFlowDown = L11_2
  L10_2 = A0_2.CustomData
  L10_2.bAdvancing = false
  L10_2 = A0_2.CustomData
  L11_2 = L0_1
  L11_2 = -1 * L11_2
  L10_2.nAdvanceSpeed = L11_2
  L10_2 = A0_2.CustomData
  L10_2.nAdvanceDistanceRemaining = 0
  if L2_2 then
    L10_2 = A0_2.CustomData
    L11_2 = A0_2.CustomData
    L11_2 = L11_2.nAdvanceSpeed
    L11_2 = L11_2 * -1
    L10_2.nAdvanceSpeed = L11_2
  end
  if not L3_2 then
    L11_2 = A0_2
    L10_2 = A0_2.SetTranslucency
    L12_2 = 0
    L10_2(L11_2, L12_2)
  end
  L10_2 = A0_2.CustomData
  L10_2.bHasBackdrop = L3_2
  L10_2 = A0_2.CustomData
  L10_2.nBorder = 0
  if L3_2 then
    L10_2 = A0_2.CustomData
    L10_2.nBorder = 12
    L10_2 = A0_2.CustomData
    L12_2 = A0_2
    L11_2 = A0_2.GetChildren
    L11_2 = L11_2(L12_2)
    L10_2.tBackdropWidgets = L11_2
  end
  L10_2 = A0_2.CustomData
  L11_2 = L9_2 or L11_2
  if not L9_2 then
    L11_2 = 300
  end
  L12_2 = A0_2.CustomData
  L12_2 = L12_2.nBorder
  L12_2 = L12_2 * 2
  L11_2 = L11_2 - L12_2
  L10_2.nWidth = L11_2
  L10_2 = A0_2.CustomData
  L11_2 = L8_2 or L11_2
  if not L8_2 then
    L11_2 = 100
  end
  L12_2 = A0_2.CustomData
  L12_2 = L12_2.nBorder
  L12_2 = L12_2 * 2
  L11_2 = L11_2 - L12_2
  L10_2.nHeight = L11_2
  L10_2 = A0_2.CustomData
  L11_2 = A0_2.CustomData
  L11_2 = L11_2.nBorder
  L11_2 = L4_2 + L11_2
  L10_2.x1 = L11_2
  L10_2 = A0_2.CustomData
  L11_2 = A0_2.CustomData
  L11_2 = L11_2.nBorder
  L11_2 = L6_2 - L11_2
  L10_2.x2 = L11_2
  L10_2 = A0_2.CustomData
  L11_2 = A0_2.CustomData
  L11_2 = L11_2.nBorder
  L11_2 = L5_2 + L11_2
  L10_2.y1 = L11_2
  L10_2 = A0_2.CustomData
  L11_2 = A0_2.CustomData
  L11_2 = L11_2.nBorder
  L11_2 = L7_2 - L11_2
  L10_2.y2 = L11_2
  L10_2 = A0_2.CustomData
  L11_2 = A0_2.CustomData
  L11_2 = L11_2.nHeight
  L10_2.nRemainingSpace = L11_2
  L10_2 = A0_2.CustomData
  L11_2 = {}
  L10_2.CurrentMessages = L11_2
  L10_2 = A0_2.CustomData
  L11_2 = {}
  L12_2 = {}
  L11_2[1] = L12_2
  L12_2 = {}
  L11_2[2] = L12_2
  L12_2 = {}
  L11_2[3] = L12_2
  L12_2 = {}
  L11_2[4] = L12_2
  L12_2 = {}
  L11_2[5] = L12_2
  L10_2.PendingMessages = L11_2
  L10_2 = A0_2.CustomData
  L11_2 = {}
  L10_2.MessageIndex = L11_2
  L10_2 = A0_2.CustomData
  L10_2.nNextMessageId = 1
  L11_2 = A0_2
  L10_2 = A0_2.SetEventHandler
  L12_2 = "GuiUpdate"
  L13_2 = HandleTextBufferUpdateEvent
  L10_2(L11_2, L12_2, L13_2)
  L10_2 = AddMessage
  A0_2.AddMessage = L10_2
  L10_2 = GetCurrentMessageId
  A0_2.GetCurrentMessageId = L10_2
  L10_2 = ClearMessages
  A0_2.ClearMessages = L10_2
  L10_2 = ClearVisibleMessages
  A0_2.ClearVisibleMessages = L10_2
  L10_2 = RemovePendingMessage
  A0_2.RemovePendingMessage = L10_2
  L10_2 = ModifyPendingMessage
  A0_2.ModifyPendingMessage = L10_2
  L10_2 = SetLocation
  A0_2.SetLocation = L10_2
  L11_2 = A0_2
  L10_2 = A0_2.SetVisible
  L12_2 = false
  L10_2(L11_2, L12_2)
end

HandleInstantiationEventForTextBuffer = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L6_2 = ValidateParameter
  L7_2 = A0_2
  L8_2 = "number"
  L9_2 = nil
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  A0_2 = L6_2
  L6_2 = ValidateParameter
  L7_2 = A1_2
  L8_2 = "number"
  L9_2 = nil
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  A1_2 = L6_2
  L6_2 = ValidateParameter
  L7_2 = A2_2
  L8_2 = "number"
  L9_2 = 300
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  A2_2 = L6_2
  L6_2 = ValidateParameter
  L7_2 = A3_2
  L8_2 = "number"
  L9_2 = 100
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  A3_2 = L6_2
  L6_2 = ValidateParameter
  L7_2 = A4_2
  L8_2 = "boolean"
  L9_2 = false
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  A4_2 = L6_2
  L6_2 = ValidateParameter
  L7_2 = A5_2
  L8_2 = "boolean"
  L9_2 = true
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  A5_2 = L6_2
  if not A0_2 or not A1_2 then
    return
  end
  L6_2 = MrxGui
  L6_2 = L6_2.ImageWidget
  L7_2 = L6_2
  L6_2 = L6_2.new
  L6_2 = L6_2(L7_2)
  NewTextBuffer = L6_2
  L6_2 = NewTextBuffer
  L7_2 = L6_2
  L6_2 = L6_2.SetLocation
  L8_2 = A0_2
  L9_2 = A1_2
  L10_2 = A2_2 or L10_2
  if not A2_2 then
    L10_2 = 300
  end
  L10_2 = A0_2 + L10_2
  L11_2 = A3_2 or L11_2
  if not A3_2 then
    L11_2 = 100
  end
  L11_2 = A1_2 + L11_2
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  L6_2 = NewTextBuffer
  L6_2 = L6_2.CustomData
  L6_2.sTextFont = "english_18"
  L6_2 = NewTextBuffer
  L6_2 = L6_2.CustomData
  L6_2.nTextScale = 1
  L6_2 = NewTextBuffer
  L6_2 = L6_2.CustomData
  L7_2 = A4_2 or L7_2
  if not A4_2 then
    L7_2 = false
  end
  L6_2.bFlowDown = L7_2
  L6_2 = NewTextBuffer
  L6_2 = L6_2.CustomData
  L6_2.bAdvancing = false
  L6_2 = NewTextBuffer
  L6_2 = L6_2.CustomData
  L7_2 = L0_1
  L7_2 = -1 * L7_2
  L6_2.nAdvanceSpeed = L7_2
  L6_2 = NewTextBuffer
  L6_2 = L6_2.CustomData
  L6_2.nAdvanceDistanceRemaining = 0
  if A4_2 then
    L6_2 = NewTextBuffer
    L6_2 = L6_2.CustomData
    L7_2 = NewTextBuffer
    L7_2 = L7_2.CustomData
    L7_2 = L7_2.nAdvanceSpeed
    L7_2 = L7_2 * -1
    L6_2.nAdvanceSpeed = L7_2
  end
  if A5_2 then
    L6_2 = NewTextBuffer
    L7_2 = L6_2
    L6_2 = L6_2.SetColor
    L8_2 = 16
    L9_2 = 16
    L10_2 = 32
    L6_2(L7_2, L8_2, L9_2, L10_2)
    L6_2 = NewTextBuffer
    L7_2 = L6_2
    L6_2 = L6_2.SetTranslucency
    L8_2 = 192
    L6_2(L7_2, L8_2)
  else
    L6_2 = NewTextBuffer
    L7_2 = L6_2
    L6_2 = L6_2.SetTranslucency
    L8_2 = 0
    L6_2(L7_2, L8_2)
  end
  L6_2 = NewTextBuffer
  L6_2 = L6_2.CustomData
  L6_2.bHasBackdrop = A5_2
  L6_2 = NewTextBuffer
  L6_2 = L6_2.CustomData
  L6_2.nBorder = 0
  if A5_2 then
    L6_2 = NewTextBuffer
    L6_2 = L6_2.CustomData
    L6_2.nBorder = 20
  end
  L6_2 = NewTextBuffer
  L7_2 = L6_2
  L6_2 = L6_2.GetLocation
  L6_2, L7_2, L8_2, L9_2 = L6_2(L7_2)
  L10_2 = NewTextBuffer
  L10_2 = L10_2.CustomData
  L11_2 = A2_2 or L11_2
  if not A2_2 then
    L11_2 = 300
  end
  L12_2 = NewTextBuffer
  L12_2 = L12_2.CustomData
  L12_2 = L12_2.nBorder
  L12_2 = L12_2 * 2
  L11_2 = L11_2 - L12_2
  L10_2.nWidth = L11_2
  L10_2 = NewTextBuffer
  L10_2 = L10_2.CustomData
  L11_2 = A3_2 or L11_2
  if not A3_2 then
    L11_2 = 100
  end
  L12_2 = NewTextBuffer
  L12_2 = L12_2.CustomData
  L12_2 = L12_2.nBorder
  L12_2 = L12_2 * 2
  L11_2 = L11_2 - L12_2
  L10_2.nHeight = L11_2
  L10_2 = NewTextBuffer
  L10_2 = L10_2.CustomData
  L11_2 = NewTextBuffer
  L11_2 = L11_2.CustomData
  L11_2 = L11_2.nBorder
  L11_2 = L6_2 + L11_2
  L10_2.x1 = L11_2
  L10_2 = NewTextBuffer
  L10_2 = L10_2.CustomData
  L11_2 = NewTextBuffer
  L11_2 = L11_2.CustomData
  L11_2 = L11_2.nBorder
  L11_2 = L8_2 - L11_2
  L10_2.x2 = L11_2
  L10_2 = NewTextBuffer
  L10_2 = L10_2.CustomData
  L11_2 = NewTextBuffer
  L11_2 = L11_2.CustomData
  L11_2 = L11_2.nBorder
  L11_2 = L7_2 + L11_2
  L10_2.y1 = L11_2
  L10_2 = NewTextBuffer
  L10_2 = L10_2.CustomData
  L11_2 = NewTextBuffer
  L11_2 = L11_2.CustomData
  L11_2 = L11_2.nBorder
  L11_2 = L9_2 - L11_2
  L10_2.y2 = L11_2
  L10_2 = NewTextBuffer
  L10_2 = L10_2.CustomData
  L11_2 = NewTextBuffer
  L11_2 = L11_2.CustomData
  L11_2 = L11_2.nHeight
  L10_2.nRemainingSpace = L11_2
  L10_2 = NewTextBuffer
  L10_2 = L10_2.CustomData
  L11_2 = {}
  L10_2.CurrentMessages = L11_2
  L10_2 = NewTextBuffer
  L10_2 = L10_2.CustomData
  L11_2 = {}
  L12_2 = {}
  L11_2[1] = L12_2
  L12_2 = {}
  L11_2[2] = L12_2
  L12_2 = {}
  L11_2[3] = L12_2
  L12_2 = {}
  L11_2[4] = L12_2
  L12_2 = {}
  L11_2[5] = L12_2
  L10_2.PendingMessages = L11_2
  L10_2 = oWidget
  L10_2 = L10_2.CustomData
  L11_2 = {}
  L10_2.MessageIndex = L11_2
  L10_2 = oWidget
  L10_2 = L10_2.CustomData
  L10_2.nNextMessageId = 1
  L10_2 = NewTextBuffer
  L11_2 = L10_2
  L10_2 = L10_2.SetEventHandler
  L12_2 = "GuiUpdate"
  L13_2 = HandleTextBufferUpdateEvent
  L10_2(L11_2, L12_2, L13_2)
  L10_2 = NewTextBuffer
  L11_2 = AddMessage
  L10_2.AddMessage = L11_2
  L10_2 = NewTextBuffer
  L11_2 = GetCurrentMessageId
  L10_2.GetCurrentMessageId = L11_2
  L10_2 = NewTextBuffer
  L11_2 = ClearMessages
  L10_2.ClearMessages = L11_2
  L10_2 = NewTextBuffer
  L11_2 = ClearVisibleMessages
  L10_2.ClearVisibleMessages = L11_2
  L10_2 = NewTextBuffer
  L11_2 = RemovePendingMessage
  L10_2.RemovePendingMessage = L11_2
  L10_2 = NewTextBuffer
  L11_2 = ModifyPendingMessage
  L10_2.ModifyPendingMessage = L11_2
  L10_2 = NewTextBuffer
  L11_2 = SetLocation
  L10_2.SetLocation = L11_2
  L10_2 = NewTextBuffer
  L11_2 = L10_2
  L10_2 = L10_2.SetVisible
  L12_2 = false
  L10_2(L11_2, L12_2)
  L10_2 = MrxGui
  L10_2 = L10_2.AddWidget
  L11_2 = NewTextBuffer
  L10_2(L11_2)
  L10_2 = NewTextBuffer
  return L10_2
end

InstantiateTextBuffer = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L5_2 = MrxGui
  L5_2 = L5_2.ImageWidget
  L5_2 = L5_2.SetLocation
  L6_2 = A0_2
  L7_2 = A1_2
  L8_2 = A2_2
  L9_2 = A3_2
  L10_2 = A4_2
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L6_2 = A0_2
  L5_2 = A0_2.GetLocation
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  L9_2 = A0_2.CustomData
  L10_2 = A0_2.CustomData
  L10_2 = L10_2.nBorder
  L10_2 = L5_2 + L10_2
  L9_2.x1 = L10_2
  L9_2 = A0_2.CustomData
  L10_2 = A0_2.CustomData
  L10_2 = L10_2.nBorder
  L10_2 = L7_2 - L10_2
  L9_2.x2 = L10_2
  L9_2 = A0_2.CustomData
  L10_2 = A0_2.CustomData
  L10_2 = L10_2.nBorder
  L10_2 = L6_2 + L10_2
  L9_2.y1 = L10_2
  L9_2 = A0_2.CustomData
  L10_2 = A0_2.CustomData
  L10_2 = L10_2.nBorder
  L10_2 = L8_2 - L10_2
  L9_2.y2 = L10_2
end

SetLocation = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2)
  local L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L9_2 = type
  L10_2 = A0_2
  L9_2 = L9_2(L10_2)
  if "table" == L9_2 then
    L9_2 = type
    L10_2 = A1_2
    L9_2 = L9_2(L10_2)
    if "string" == L9_2 then
      goto lbl_13
    end
  end
  L9_2 = nil
  do return L9_2 end
  ::lbl_13::
  L9_2 = ValidateParameter
  L10_2 = A2_2
  L11_2 = "number"
  L12_2 = 5
  L9_2 = L9_2(L10_2, L11_2, L12_2)
  A2_2 = L9_2
  L9_2 = ValidateParameter
  L10_2 = A3_2
  L11_2 = "number"
  L12_2 = 2
  L9_2 = L9_2(L10_2, L11_2, L12_2)
  A3_2 = L9_2
  L9_2 = ValidateParameter
  L10_2 = A4_2
  L11_2 = "number"
  L12_2 = 0.25
  L9_2 = L9_2(L10_2, L11_2, L12_2)
  A4_2 = L9_2
  L9_2 = ValidateParameter
  L10_2 = A5_2
  L11_2 = "boolean"
  L12_2 = false
  L9_2 = L9_2(L10_2, L11_2, L12_2)
  A5_2 = L9_2
  L9_2 = ValidateParameter
  L10_2 = A6_2
  L11_2 = "boolean"
  L12_2 = true
  L9_2 = L9_2(L10_2, L11_2, L12_2)
  A6_2 = L9_2
  L9_2 = ValidateParameter
  L10_2 = A7_2
  L11_2 = "function"
  L12_2 = nil
  L9_2 = L9_2(L10_2, L11_2, L12_2)
  A7_2 = L9_2
  L9_2 = ValidateParameter
  L10_2 = A8_2
  L11_2 = "table"
  L12_2 = {}
  L9_2 = L9_2(L10_2, L11_2, L12_2)
  A8_2 = L9_2
  L9_2 = MrxGui
  L9_2 = L9_2.TextWidget
  L10_2 = L9_2
  L9_2 = L9_2.new
  L9_2 = L9_2(L10_2)
  NewTextMessage = L9_2
  L9_2 = A0_2.BasicData
  L9_2 = L9_2.name
  if "PDA Subtitle Buffer" ~= L9_2 then
    L9_2 = MrxGuiManager
    L9_2 = L9_2.AddWidgetToHud
    L11_2 = A0_2
    L10_2 = A0_2.GetOwner
    L10_2 = L10_2(L11_2)
    L11_2 = NewTextMessage
    L9_2(L10_2, L11_2)
  end
  L9_2 = A0_2.BasicData
  L9_2 = L9_2.name
  if "Subtitle Buffer" ~= L9_2 then
    L9_2 = A0_2.BasicData
    L9_2 = L9_2.name
    if "PDA Subtitle Buffer" ~= L9_2 then
      L9_2 = NewTextMessage
      L10_2 = L9_2
      L9_2 = L9_2.SetOwner
      L12_2 = A0_2
      L11_2 = A0_2.GetOwner
      L11_2, L12_2, L13_2, L14_2, L15_2 = L11_2(L12_2)
      L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
    end
  end
  L9_2 = NewTextMessage
  L10_2 = L9_2
  L9_2 = L9_2.SetFont
  L11_2 = A0_2.CustomData
  L11_2 = L11_2.sTextFont
  L9_2(L10_2, L11_2)
  L9_2 = NewTextMessage
  L10_2 = L9_2
  L9_2 = L9_2.SetScale
  L11_2 = A0_2.CustomData
  L11_2 = L11_2.nTextScale
  L9_2(L10_2, L11_2)
  L9_2 = NewTextMessage
  L10_2 = L9_2
  L9_2 = L9_2.SetText
  L11_2 = A1_2
  L9_2(L10_2, L11_2)
  L9_2 = NewTextMessage
  L9_2 = L9_2.CustomData
  L10_2 = A5_2 or L10_2
  if not A5_2 then
    L10_2 = false
  end
  L9_2.bClearBuffer = L10_2
  if nil == A6_2 then
    L9_2 = NewTextMessage
    L9_2 = L9_2.CustomData
    L9_2.bAllowsAppends = true
  else
    L9_2 = NewTextMessage
    L9_2 = L9_2.CustomData
    L9_2.bAllowsAppends = A6_2
  end
  L9_2 = NewTextMessage
  L9_2 = L9_2.CustomData
  L10_2 = A3_2 or L10_2
  if not A3_2 then
    L10_2 = 2
  end
  L9_2.nDisplayDuration = L10_2
  L9_2 = NewTextMessage
  L9_2 = L9_2.CustomData
  L10_2 = A4_2 or L10_2
  if not A4_2 then
    L10_2 = 0.5
  end
  L9_2.nFadeDuration = L10_2
  L9_2 = NewTextMessage
  L10_2 = L9_2
  L9_2 = L9_2.SetLocation
  L11_2 = A0_2.CustomData
  L11_2 = L11_2.x1
  L12_2 = A0_2.CustomData
  L12_2 = L12_2.y1
  L13_2 = A0_2.CustomData
  L13_2 = L13_2.x2
  L14_2 = A0_2.CustomData
  L14_2 = L14_2.y2
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
  L9_2 = NewTextMessage
  L10_2 = L9_2
  L9_2 = L9_2.Wrap
  L9_2(L10_2)
  L9_2 = NewTextMessage
  L9_2 = L9_2.CustomData
  L10_2 = GetMessageHeight
  L11_2 = NewTextMessage
  L10_2 = L10_2(L11_2)
  L9_2.nHeight = L10_2
  L9_2 = NewTextMessage
  L9_2 = L9_2.CustomData
  L9_2.bNeedsScrolling = true
  L9_2 = NewTextMessage
  L9_2 = L9_2.CustomData
  L9_2.fCallback = A7_2
  L9_2 = NewTextMessage
  L9_2 = L9_2.CustomData
  L9_2.tCallbackData = A8_2
  L9_2 = NewTextMessage
  L10_2 = CallCallback
  L9_2.CallCallback = L10_2
  if A3_2 < 0 then
    L9_2 = NewTextMessage
    L9_2 = L9_2.CustomData
    L9_2.nDisplayDuration = 10000
    L9_2 = NewTextMessage
    L9_2 = L9_2.CustomData
    L9_2.bPersistent = true
  end
  if not A2_2 then
    A2_2 = 5
  end
  L9_2 = type
  L10_2 = A2_2
  L9_2 = L9_2(L10_2)
  if "number" ~= L9_2 or A2_2 < 0 or 5 < A2_2 then
    A2_2 = 5
  end
  L9_2 = NewTextMessage
  L9_2.ParentWidget = A0_2
  if 0 == A2_2 then
    L9_2 = A0_2.CustomData
    L9_2 = L9_2.nRemainingSpace
    L10_2 = 1
    while true do
      L11_2 = NewTextMessage
      L11_2 = L11_2.CustomData
      L11_2 = L11_2.nHeight
      if not (L9_2 < L11_2) then
        break
      end
      L11_2 = A0_2.CustomData
      L11_2 = L11_2.CurrentMessages
      L11_2 = L11_2[L10_2]
      if not L11_2 then
        break
      end
      L11_2 = A0_2.CustomData
      L11_2 = L11_2.CurrentMessages
      L11_2 = L11_2[L10_2]
      L11_2 = L11_2.CustomData
      L11_2.nDisplayDuration = 0
      L11_2 = A0_2.CustomData
      L11_2 = L11_2.CurrentMessages
      L11_2 = L11_2[L10_2]
      L11_2 = L11_2.CustomData
      L11_2.bPersistent = nil
      L11_2 = A0_2.CustomData
      L11_2 = L11_2.CurrentMessages
      L11_2 = L11_2[L10_2]
      L11_2 = L11_2.CustomData
      L11_2.nFadeDuration = 0
      L11_2 = A0_2.CustomData
      L11_2 = L11_2.CurrentMessages
      L11_2 = L11_2[L10_2]
      L11_2 = L11_2.CustomData
      L11_2 = L11_2.nHeight
      L9_2 = L9_2 + L11_2
      L10_2 = L10_2 + 1
    end
    L11_2 = NewTextMessage
    L11_2 = L11_2.CustomData
    L11_2.bZeroPriority = true
    L11_2 = A0_2.CustomData
    L11_2 = L11_2.PendingMessages
    L11_2 = L11_2[1]
    L11_2 = L11_2[1]
    while L11_2 do
      L12_2 = L11_2.CustomData
      L12_2 = L12_2.bZeroPriority
      if not L12_2 then
        break
      end
      L12_2 = table
      L12_2 = L12_2.remove
      L13_2 = A0_2.CustomData
      L13_2 = L13_2.PendingMessages
      L13_2 = L13_2[1]
      L14_2 = 1
      L12_2(L13_2, L14_2)
      L12_2 = L11_2.CustomData
      L12_2 = L12_2.nId
      if L12_2 then
        L12_2 = A0_2.CustomData
        L12_2 = L12_2.MessageIndex
        L13_2 = L11_2.CustomData
        L13_2 = L13_2.nId
        L12_2[L13_2] = nil
      end
      L12_2 = MrxGuiManager
      L12_2 = L12_2.RemoveWidgetFromHud
      L14_2 = A0_2
      L13_2 = A0_2.GetOwner
      L13_2 = L13_2(L14_2)
      L14_2 = L11_2
      L12_2(L13_2, L14_2)
      L12_2 = MrxGui
      L12_2 = L12_2.RemoveWidget
      L13_2 = L11_2
      L12_2(L13_2)
      L13_2 = L11_2
      L12_2 = L11_2.delete
      L12_2(L13_2)
      L12_2 = A0_2.CustomData
      L12_2 = L12_2.PendingMessages
      L12_2 = L12_2[1]
      L11_2 = L12_2[1]
    end
    L12_2 = table
    L12_2 = L12_2.insert
    L13_2 = A0_2.CustomData
    L13_2 = L13_2.PendingMessages
    L13_2 = L13_2[1]
    L14_2 = 1
    L15_2 = NewTextMessage
    L12_2(L13_2, L14_2, L15_2)
    L12_2 = true
    while L12_2 do
      L13_2 = PushMessageIntoTextBuffer
      L14_2 = A0_2
      L13_2 = L13_2(L14_2)
      L12_2 = L13_2
    end
  else
    L9_2 = table
    L9_2 = L9_2.insert
    L10_2 = A0_2.CustomData
    L10_2 = L10_2.PendingMessages
    L10_2 = L10_2[A2_2]
    L11_2 = NewTextMessage
    L9_2(L10_2, L11_2)
    L9_2 = A0_2.CustomData
    L9_2 = L9_2.nNextMessageId
    L10_2 = A0_2.CustomData
    L10_2 = L10_2.MessageIndex
    L11_2 = NewTextMessage
    L10_2[L9_2] = L11_2
    L10_2 = NewTextMessage
    L10_2 = L10_2.CustomData
    L10_2.nId = L9_2
    L10_2 = NewTextMessage
    L10_2 = L10_2.CustomData
    L10_2.nPriority = A2_2
    L10_2 = A0_2.CustomData
    L11_2 = L9_2 + 1
    L10_2.nNextMessageId = L11_2
    L10_2 = true
    while L10_2 do
      L11_2 = PushMessageIntoTextBuffer
      L12_2 = A0_2
      L11_2 = L11_2(L12_2)
      L10_2 = L11_2
    end
  end
  L9_2 = A0_2.CustomData
  L9_2 = L9_2.bHasBackdrop
  if L9_2 then
    L10_2 = A0_2
    L9_2 = A0_2.SetVisible
    L11_2 = true
    L9_2(L10_2, L11_2)
  end
  L9_2 = NewTextMessage
  L9_2 = L9_2.CustomData
  L9_2 = L9_2.nId
  return L9_2
end

AddMessage = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.fCallback
  if L1_2 then
    L1_2 = type
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.tCallbackData
    L1_2 = L1_2(L2_2)
    if "table" ~= L1_2 then
      L1_2 = A0_2.CustomData
      L2_2 = {}
      L1_2.tCallbackData = L2_2
    end
    L1_2 = A0_2.CustomData
    L1_2 = L1_2.fCallback
    L2_2 = unpack
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.tCallbackData
    L2_2, L3_2 = L2_2(L3_2)
    L1_2(L2_2, L3_2)
    L1_2 = A0_2.CustomData
    L1_2.fCallback = nil
  end
end

CallCallback = L1_1

function L1_1(A0_2)
  local L1_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.CurrentMessages
  L1_2 = L1_2[1]
  if L1_2 then
    L1_2 = A0_2.CustomData
    L1_2 = L1_2.CurrentMessages
    L1_2 = L1_2[1]
    L1_2 = L1_2.CustomData
    L1_2.nDisplayDuration = 0
    L1_2 = A0_2.CustomData
    L1_2 = L1_2.CurrentMessages
    L1_2 = L1_2[1]
    L1_2 = L1_2.CustomData
    L1_2.bPersistent = nil
  end
end

AdvanceMessages = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = {}
  visibleIds = L1_2
  L1_2 = pairs
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.CurrentMessages
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L5_2.CustomData
    L6_2 = L6_2.nId
    if L6_2 then
      L6_2 = table
      L6_2 = L6_2.insert
      L7_2 = visibleIds
      L8_2 = L5_2.CustomData
      L8_2 = L8_2.nId
      L6_2(L7_2, L8_2)
    end
  end
  L1_2 = visibleIds
  return L1_2
end

GetCurrentMessageId = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = A0_2.CustomData
  L1_2.bAdvancing = false
  L1_2 = A0_2.CustomData
  L1_2.nAdvanceDistanceRemaining = 0
  L1_2 = A0_2.CustomData
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nHeight
  L1_2.nRemainingSpace = L2_2
  L1_2 = pairs
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.CurrentMessages
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = MrxGuiManager
    L6_2 = L6_2.RemoveWidgetFromHud
    L8_2 = A0_2
    L7_2 = A0_2.GetOwner
    L7_2 = L7_2(L8_2)
    L8_2 = L5_2
    L6_2(L7_2, L8_2)
    L6_2 = MrxGui
    L6_2 = L6_2.RemoveWidget
    L7_2 = L5_2
    L6_2(L7_2)
    L7_2 = L5_2
    L6_2 = L5_2.delete
    L6_2(L7_2)
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.CurrentMessages
    L6_2[L4_2] = nil
  end
  L1_2 = A0_2.CustomData
  L2_2 = {}
  L1_2.CurrentMessages = L2_2
  L2_2 = A0_2
  L1_2 = A0_2.RemoveAllChildren
  L1_2(L2_2)
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bHasBackdrop
  if L1_2 then
    L1_2 = A0_2.CustomData
    L1_2 = L1_2.tBackdropWidgets
    if L1_2 then
      L1_2 = pairs
      L2_2 = A0_2.CustomData
      L2_2 = L2_2.tBackdropWidgets
      L1_2, L2_2, L3_2 = L1_2(L2_2)
      for L4_2, L5_2 in L1_2, L2_2, L3_2 do
        L7_2 = A0_2
        L6_2 = A0_2.AddChild
        L8_2 = L5_2
        L6_2(L7_2, L8_2)
      end
    end
  end
  L1_2 = 1
  while true do
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.PendingMessages
    L2_2 = L2_2[L1_2]
    if not L2_2 then
      break
    end
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.PendingMessages
    L3_2 = {}
    L2_2[L1_2] = L3_2
    L1_2 = L1_2 + 1
  end
  L2_2 = A0_2.CustomData
  L3_2 = {}
  L2_2.MessageIndex = L3_2
  L3_2 = A0_2
  L2_2 = A0_2.SetVisible
  L4_2 = false
  L2_2(L3_2, L4_2)
end

ClearMessages = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2.CustomData
  L2_2.bAdvancing = false
  L2_2 = A0_2.CustomData
  L2_2.nAdvanceDistanceRemaining = 0
  L2_2 = A0_2.CustomData
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nHeight
  L2_2.nRemainingSpace = L3_2
  L2_2 = pairs
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.CurrentMessages
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = MrxGuiManager
    L7_2 = L7_2.RemoveWidgetFromHud
    L9_2 = A0_2
    L8_2 = A0_2.GetOwner
    L8_2 = L8_2(L9_2)
    L9_2 = L6_2
    L7_2(L8_2, L9_2)
    L7_2 = MrxGui
    L7_2 = L7_2.RemoveWidget
    L8_2 = L6_2
    L7_2(L8_2)
    L8_2 = L6_2
    L7_2 = L6_2.delete
    L7_2(L8_2)
    L7_2 = A0_2.CustomData
    L7_2 = L7_2.CurrentMessages
    L7_2[L5_2] = nil
  end
  L2_2 = A0_2.CustomData
  L3_2 = {}
  L2_2.CurrentMessages = L3_2
  L3_2 = A0_2
  L2_2 = A0_2.RemoveAllChildren
  L2_2(L3_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bHasBackdrop
  if L2_2 then
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.tBackdropWidgets
    if L2_2 then
      L2_2 = pairs
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.tBackdropWidgets
      L2_2, L3_2, L4_2 = L2_2(L3_2)
      for L5_2, L6_2 in L2_2, L3_2, L4_2 do
        L8_2 = A0_2
        L7_2 = A0_2.AddChild
        L9_2 = L6_2
        L7_2(L8_2, L9_2)
      end
    end
  end
  if A1_2 then
    L2_2 = true
    while L2_2 do
      L3_2 = PushMessageIntoTextBuffer
      L4_2 = A0_2
      L3_2 = L3_2(L4_2)
      L2_2 = L3_2
    end
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.CurrentMessages
  L2_2 = #L2_2
  if 0 == L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.SetVisible
    L4_2 = false
    L2_2(L3_2, L4_2)
  end
end

ClearVisibleMessages = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2)
  local L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L9_2 = A0_2.CustomData
  L9_2 = L9_2.MessageIndex
  L9_2 = L9_2[A1_2]
  if L9_2 then
    L10_2 = L9_2.CustomData
    L10_2 = L10_2.nPriority
    if L10_2 then
      L10_2 = nil
      L11_2 = pairs
      L12_2 = A0_2.CustomData
      L12_2 = L12_2.PendingMessages
      L13_2 = L9_2.CustomData
      L13_2 = L13_2.nPriority
      L12_2 = L12_2[L13_2]
      L11_2, L12_2, L13_2 = L11_2(L12_2)
      for L14_2, L15_2 in L11_2, L12_2, L13_2 do
        L16_2 = L15_2.CustomData
        L16_2 = L16_2.nId
        L17_2 = L9_2.CustomData
        L17_2 = L17_2.nId
        if L16_2 == L17_2 then
          L10_2 = L14_2
        end
      end
      if L10_2 then
        L11_2 = ValidateParameter
        L12_2 = A2_2
        L13_2 = "string"
        L14_2 = nil
        L11_2 = L11_2(L12_2, L13_2, L14_2)
        A2_2 = L11_2
        L11_2 = ValidateParameter
        L12_2 = A3_2
        L13_2 = "number"
        L14_2 = nil
        L11_2 = L11_2(L12_2, L13_2, L14_2)
        A3_2 = L11_2
        L11_2 = ValidateParameter
        L12_2 = A4_2
        L13_2 = "number"
        L14_2 = nil
        L11_2 = L11_2(L12_2, L13_2, L14_2)
        A4_2 = L11_2
        L11_2 = ValidateParameter
        L12_2 = A5_2
        L13_2 = "boolean"
        L14_2 = nil
        L11_2 = L11_2(L12_2, L13_2, L14_2)
        A5_2 = L11_2
        L11_2 = ValidateParameter
        L12_2 = A6_2
        L13_2 = "boolean"
        L14_2 = nil
        L11_2 = L11_2(L12_2, L13_2, L14_2)
        A6_2 = L11_2
        L11_2 = ValidateParameter
        L12_2 = A7_2
        L13_2 = "function"
        L14_2 = nil
        L11_2 = L11_2(L12_2, L13_2, L14_2)
        A7_2 = L11_2
        L11_2 = ValidateParameter
        L12_2 = A8_2
        L13_2 = "table"
        L14_2 = nil
        L11_2 = L11_2(L12_2, L13_2, L14_2)
        A8_2 = L11_2
        if A2_2 then
          L12_2 = L9_2
          L11_2 = L9_2.SetText
          L13_2 = A2_2
          L11_2(L12_2, L13_2)
          L12_2 = L9_2
          L11_2 = L9_2.Wrap
          L11_2(L12_2)
          L11_2 = L9_2.CustomData
          L12_2 = GetMessageHeight
          L13_2 = L9_2
          L12_2 = L12_2(L13_2)
          L11_2.nHeight = L12_2
        end
        L11_2 = L9_2.CustomData
        L12_2 = A5_2 or L12_2
        if not A5_2 then
          L12_2 = L9_2.CustomData
          L12_2 = L12_2.bClearBuffer
        end
        L11_2.bClearBuffer = L12_2
        L11_2 = L9_2.CustomData
        L12_2 = A6_2 or L12_2
        if not A6_2 then
          L12_2 = L9_2.CustomData
          L12_2 = L12_2.bAllowsAppends
        end
        L11_2.bAllowsAppends = L12_2
        L11_2 = L9_2.CustomData
        L12_2 = A3_2 or L12_2
        if not A3_2 then
          L12_2 = L9_2.CustomData
          L12_2 = L12_2.nDisplayDuration
        end
        L11_2.nDisplayDuration = L12_2
        L11_2 = L9_2.CustomData
        L12_2 = A4_2 or L12_2
        if not A4_2 then
          L12_2 = L9_2.CustomData
          L12_2 = L12_2.nFadeDuration
        end
        L11_2.nFadeDuration = L12_2
        L11_2 = L9_2.CustomData
        L12_2 = A7_2 or L12_2
        if not A7_2 then
          L12_2 = L9_2.CustomData
          L12_2 = L12_2.fCallback
        end
        L11_2.fCallback = L12_2
        L11_2 = L9_2.CustomData
        L12_2 = A8_2 or L12_2
        if not A8_2 then
          L12_2 = L9_2.CustomData
          L12_2 = L12_2.tCallbackData
          if not L12_2 then
            L12_2 = {}
          end
        end
        L11_2.tCallbackData = L12_2
        L11_2 = L9_2.CustomData
        L11_2 = L11_2.nDisplayDuration
        if L11_2 < 0 then
          L11_2 = L9_2.CustomData
          L11_2.bPersistent = true
        else
          L11_2 = L9_2.CustomData
          L11_2.bPersistent = nil
        end
        L11_2 = true
        return L11_2
      end
    end
  end
  L10_2 = false
  return L10_2
end

ModifyPendingMessage = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.MessageIndex
  L2_2 = L2_2[A1_2]
  if L2_2 then
    L3_2 = L2_2.CustomData
    L3_2 = L3_2.nPriority
    if L3_2 then
      L3_2 = nil
      L4_2 = pairs
      L5_2 = A0_2.CustomData
      L5_2 = L5_2.PendingMessages
      L6_2 = L2_2.CustomData
      L6_2 = L6_2.nPriority
      L5_2 = L5_2[L6_2]
      L4_2, L5_2, L6_2 = L4_2(L5_2)
      for L7_2, L8_2 in L4_2, L5_2, L6_2 do
        L9_2 = L8_2.CustomData
        L9_2 = L9_2.nId
        L10_2 = L2_2.CustomData
        L10_2 = L10_2.nId
        if L9_2 == L10_2 then
          L3_2 = L7_2
        end
      end
      if L3_2 then
        L4_2 = table
        L4_2 = L4_2.remove
        L5_2 = A0_2.CustomData
        L5_2 = L5_2.PendingMessages
        L6_2 = L2_2.CustomData
        L6_2 = L6_2.nPriority
        L5_2 = L5_2[L6_2]
        L6_2 = L3_2
        L4_2(L5_2, L6_2)
        L4_2 = A0_2.CustomData
        L4_2 = L4_2.MessageIndex
        L4_2[A1_2] = nil
        L4_2 = MrxGuiManager
        L4_2 = L4_2.RemoveWidgetFromHud
        L6_2 = A0_2
        L5_2 = A0_2.GetOwner
        L5_2 = L5_2(L6_2)
        L6_2 = L2_2
        L4_2(L5_2, L6_2)
        L4_2 = MrxGui
        L4_2 = L4_2.RemoveWidget
        L5_2 = L2_2
        L4_2(L5_2)
        L5_2 = L2_2
        L4_2 = L2_2.delete
        L4_2(L5_2)
        L4_2 = true
        return L4_2
      end
    end
  end
  L3_2 = false
  return L3_2
end

RemovePendingMessage = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.CurrentMessages
  L2_2 = L2_2[0]
  if L2_2 then
    L3_2 = nil
    L4_2 = L2_2.CustomData
    L4_2 = L4_2.nFadeDuration
    if L4_2 <= 0 then
      L3_2 = 9999
    else
      L4_2 = L2_2.CustomData
      L4_2 = L4_2.nFadeDuration
      L4_2 = 256 / L4_2
      L3_2 = L4_2 * A1_2
    end
    L5_2 = L2_2
    L4_2 = L2_2.GetTranslucency
    L4_2 = L4_2(L5_2)
    if L3_2 > L4_2 then
      L4_2 = MrxGuiManager
      L4_2 = L4_2.RemoveWidgetFromHud
      L6_2 = A0_2
      L5_2 = A0_2.GetOwner
      L5_2 = L5_2(L6_2)
      L6_2 = L2_2
      L4_2(L5_2, L6_2)
      L4_2 = MrxGui
      L4_2 = L4_2.RemoveWidget
      L5_2 = L2_2
      L4_2(L5_2)
      L5_2 = L2_2
      L4_2 = L2_2.delete
      L4_2(L5_2)
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.CurrentMessages
      L4_2[0] = nil
      L4_2 = IsEmpty
      L5_2 = A0_2.CustomData
      L5_2 = L5_2.CurrentMessages
      L4_2 = L4_2(L5_2)
      if L4_2 then
        L5_2 = A0_2
        L4_2 = A0_2.SetVisible
        L6_2 = false
        L4_2(L5_2, L6_2)
      end
    else
      L5_2 = L2_2
      L4_2 = L2_2.SetTranslucency
      L7_2 = L2_2
      L6_2 = L2_2.GetTranslucency
      L6_2 = L6_2(L7_2)
      L6_2 = L6_2 - L3_2
      L4_2(L5_2, L6_2)
    end
  end
  L3_2 = 1
  while true do
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.CurrentMessages
    L4_2 = L4_2[L3_2]
    if not L4_2 then
      break
    end
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.CurrentMessages
    L4_2 = L4_2[L3_2]
    L6_2 = L4_2
    L5_2 = L4_2.GetTranslucency
    L5_2 = L5_2(L6_2)
    if L5_2 < 255 then
      L5_2 = nil
      L6_2 = L4_2.CustomData
      L6_2 = L6_2.nFadeDuration
      if L6_2 <= 0 then
        L5_2 = 9999
      else
        L6_2 = L4_2.CustomData
        L6_2 = L6_2.nFadeDuration
        L6_2 = 255 / L6_2
        L5_2 = L6_2 * A1_2
      end
      L7_2 = L4_2
      L6_2 = L4_2.SetTranslucency
      L9_2 = L4_2
      L8_2 = L4_2.GetTranslucency
      L8_2 = L8_2(L9_2)
      L8_2 = L8_2 + L5_2
      L6_2(L7_2, L8_2)
      L7_2 = L4_2
      L6_2 = L4_2.GetTranslucency
      L6_2 = L6_2(L7_2)
      if 255 < L6_2 then
        L7_2 = L4_2
        L6_2 = L4_2.SetTranslucency
        L8_2 = 255
        L6_2(L7_2, L8_2)
      end
    end
    L3_2 = L3_2 + 1
  end
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.bAdvancing
  if L4_2 then
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.CurrentMessages
    L4_2 = L4_2[1]
    if L4_2 then
      L5_2 = L4_2.CustomData
      L5_2 = L5_2.bPersistent
      if not L5_2 then
        L5_2 = L4_2.CustomData
        L6_2 = L4_2.CustomData
        L6_2 = L6_2.nDisplayDuration
        L6_2 = L6_2 - A1_2
        L5_2.nDisplayDuration = L6_2
        L5_2 = L4_2.CustomData
        L5_2 = L5_2.nDisplayDuration
        if L5_2 < 0 then
          L5_2 = L4_2.CustomData
          L5_2.nDisplayDuration = 0
        end
      end
    end
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.nAdvanceSpeed
    L5_2 = A1_2 * L5_2
    L6_2 = MboxAbs
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    L7_2 = A0_2.CustomData
    L7_2 = L7_2.nAdvanceDistanceRemaining
    if L6_2 >= L7_2 then
      if L5_2 < 0 then
        L6_2 = A0_2.CustomData
        L6_2 = L6_2.nAdvanceDistanceRemaining
        L5_2 = L6_2 * -1
      else
        L6_2 = A0_2.CustomData
        L5_2 = L6_2.nAdvanceDistanceRemaining
      end
      L6_2 = A0_2.CustomData
      L6_2.nAdvanceDistanceRemaining = 0
      L6_2 = A0_2.CustomData
      L6_2.bAdvancing = false
    else
      L6_2 = A0_2.CustomData
      L7_2 = A0_2.CustomData
      L7_2 = L7_2.nAdvanceDistanceRemaining
      L8_2 = MboxAbs
      L9_2 = L5_2
      L8_2 = L8_2(L9_2)
      L7_2 = L7_2 - L8_2
      L6_2.nAdvanceDistanceRemaining = L7_2
    end
    L6_2 = pairs
    L7_2 = A0_2.CustomData
    L7_2 = L7_2.CurrentMessages
    L6_2, L7_2, L8_2 = L6_2(L7_2)
    for L9_2 in L6_2, L7_2, L8_2 do
      L10_2 = A0_2.CustomData
      L10_2 = L10_2.CurrentMessages
      L10_2 = L10_2[L9_2]
      L11_2 = L10_2
      L10_2 = L10_2.OffsetLocation
      L12_2 = 0
      L13_2 = L5_2
      L10_2(L11_2, L12_2, L13_2)
    end
    L6_2 = IsEmpty
    L7_2 = A0_2.CustomData
    L7_2 = L7_2.CurrentMessages
    L6_2 = L6_2(L7_2)
    if L6_2 then
      L6_2 = A0_2.CustomData
      L6_2 = L6_2.CurrentMessages
      L6_2 = L6_2[0]
      if nil == L6_2 then
        L6_2 = A0_2.CustomData
        L6_2.nAdvanceDistanceRemaining = 0
        A0_2.bAdvancing = false
      end
    end
  else
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.CurrentMessages
    L4_2 = L4_2[1]
    if L4_2 then
      L5_2 = L4_2.CustomData
      L5_2 = L5_2.nDisplayDuration
      if A1_2 >= L5_2 then
        L5_2 = L4_2.CustomData
        L5_2 = L5_2.bPersistent
        if not L5_2 then
          L5_2 = A0_2.CustomData
          L5_2 = L5_2.CurrentMessages
          L5_2 = L5_2[0]
          if L5_2 then
            L5_2 = MrxGuiManager
            L5_2 = L5_2.RemoveWidgetFromHud
            L7_2 = A0_2
            L6_2 = A0_2.GetOwner
            L6_2 = L6_2(L7_2)
            L7_2 = A0_2.CustomData
            L7_2 = L7_2.CurrentMessages
            L7_2 = L7_2[0]
            L5_2(L6_2, L7_2)
            L5_2 = MrxGui
            L5_2 = L5_2.RemoveWidget
            L6_2 = A0_2.CustomData
            L6_2 = L6_2.CurrentMessages
            L6_2 = L6_2[0]
            L5_2(L6_2)
            L5_2 = A0_2.CustomData
            L5_2 = L5_2.CurrentMessages
            L5_2 = L5_2[0]
            L6_2 = L5_2
            L5_2 = L5_2.delete
            L5_2(L6_2)
            L5_2 = A0_2.CustomData
            L5_2 = L5_2.CurrentMessages
            L5_2[0] = nil
          end
          L5_2 = table
          L5_2 = L5_2.remove
          L6_2 = A0_2.CustomData
          L6_2 = L6_2.CurrentMessages
          L7_2 = 1
          L5_2(L6_2, L7_2)
          L5_2 = A0_2.CustomData
          L5_2 = L5_2.CurrentMessages
          L5_2[0] = L4_2
          L5_2 = A0_2.CustomData
          L6_2 = L4_2.CustomData
          L6_2 = L6_2.nHeight
          L5_2.nAdvanceDistanceRemaining = L6_2
          L5_2 = A0_2.CustomData
          L6_2 = A0_2.CustomData
          L6_2 = L6_2.nRemainingSpace
          L7_2 = L4_2.CustomData
          L7_2 = L7_2.nHeight
          L6_2 = L6_2 + L7_2
          L5_2.nRemainingSpace = L6_2
          L5_2 = true
          while L5_2 do
            L6_2 = PushMessageIntoTextBuffer
            L7_2 = A0_2
            L6_2 = L6_2(L7_2)
            L5_2 = L6_2
          end
          L6_2 = A0_2.CustomData
          L6_2.bAdvancing = true
      end
      else
        L5_2 = L4_2.CustomData
        L5_2 = L5_2.bPersistent
        if not L5_2 then
          L5_2 = L4_2.CustomData
          L6_2 = L4_2.CustomData
          L6_2 = L6_2.nDisplayDuration
          L6_2 = L6_2 - A1_2
          L5_2.nDisplayDuration = L6_2
        end
      end
    end
  end
end

HandleTextBufferUpdateEvent = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L1_2 = 0
  while true do
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.CurrentMessages
    L3_2 = L1_2 + 1
    L2_2 = L2_2[L3_2]
    if not L2_2 then
      break
    end
    L1_2 = L1_2 + 1
  end
  L2_2 = nil
  if 0 < L1_2 then
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.CurrentMessages
    L2_2 = L3_2[L1_2]
    if L2_2 then
      L3_2 = L2_2.CustomData
      L3_2 = L3_2.bAllowsAppends
      if not L3_2 then
        L3_2 = false
        return L3_2
      end
    end
  end
  L3_2 = false
  L4_2 = table
  L4_2 = L4_2.getn
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.CurrentMessages
  L4_2 = L4_2(L5_2)
  if 0 == L4_2 then
    L3_2 = true
  end
  L4_2 = nil
  L5_2 = 1
  L6_2 = 1
  L7_2 = 1
  while not L4_2 and L5_2 < 6 do
    L8_2 = A0_2.CustomData
    L8_2 = L8_2.PendingMessages
    L8_2 = L8_2[L5_2]
    L4_2 = L8_2[1]
    L6_2 = L5_2
    L7_2 = 1
    L5_2 = L5_2 + 1
  end
  if not L4_2 then
    L8_2 = false
    return L8_2
  end
  L8_2 = L4_2.CustomData
  L8_2 = L8_2.nHeight
  L9_2 = A0_2.CustomData
  L9_2 = L9_2.nRemainingSpace
  if L8_2 > L9_2 then
    L8_2 = A0_2.CustomData
    L8_2 = L8_2.nOneLineHeight
    if not L8_2 then
      L8_2 = MrxGui
      L8_2 = L8_2.TextWidget
      L9_2 = L8_2
      L8_2 = L8_2.new
      L8_2 = L8_2(L9_2)
      oTest = L8_2
      L8_2 = oTest
      L9_2 = L8_2
      L8_2 = L8_2.SetFont
      L10_2 = A0_2.CustomData
      L10_2 = L10_2.sTextFont
      L8_2(L9_2, L10_2)
      L8_2 = oTest
      L9_2 = L8_2
      L8_2 = L8_2.SetScale
      L10_2 = A0_2.CustomData
      L10_2 = L10_2.nTextScale
      L8_2(L9_2, L10_2)
      L8_2 = oTest
      L9_2 = L8_2
      L8_2 = L8_2.SetText
      L10_2 = "Test"
      L8_2(L9_2, L10_2)
      L8_2 = A0_2.CustomData
      L9_2 = oTest
      L10_2 = L9_2
      L9_2 = L9_2.GetHeight
      L9_2 = L9_2(L10_2)
      L8_2.nOneLineHeight = L9_2
      L8_2 = oTest
      L9_2 = L8_2
      L8_2 = L8_2.delete
      L8_2(L9_2)
    end
    L8_2 = A0_2.CustomData
    L8_2 = L8_2.nOneLineHeight
    L9_2 = A0_2.CustomData
    L9_2 = L9_2.nRemainingSpace
    if L8_2 > L9_2 then
      L8_2 = false
      return L8_2
    end
    L8_2 = L4_2.CustomData
    L8_2 = L8_2.nHeight
    L9_2 = A0_2.CustomData
    L9_2 = L9_2.nHeight
    if L8_2 > L9_2 then
      L9_2 = L4_2
      L8_2 = L4_2.SplitIntoLines
      L8_2 = L8_2(L9_2)
      L9_2 = L4_2.CustomData
      L9_2 = L9_2.nDisplayDuration
      L10_2 = #L8_2
      L9_2 = L9_2 / L10_2
      L10_2 = pairs
      L11_2 = L8_2
      L10_2, L11_2, L12_2 = L10_2(L11_2)
      for L13_2, L14_2 in L10_2, L11_2, L12_2 do
        L16_2 = L14_2
        L15_2 = L14_2.SetOwner
        L18_2 = L4_2
        L17_2 = L4_2.GetOwner
        L17_2, L18_2 = L17_2(L18_2)
        L15_2(L16_2, L17_2, L18_2)
        L16_2 = L14_2
        L15_2 = L14_2.SetScale
        L18_2 = L4_2
        L17_2 = L4_2.GetScale
        L17_2, L18_2 = L17_2(L18_2)
        L15_2(L16_2, L17_2, L18_2)
        L15_2 = L14_2.CustomData
        L15_2.bAllowsAppends = true
        L15_2 = L14_2.CustomData
        L15_2.bClearBuffer = false
        L15_2 = L14_2.CustomData
        L15_2.nDisplayDuration = L9_2
        L15_2 = L14_2.CustomData
        L16_2 = L4_2.CustomData
        L16_2 = L16_2.nFadeDuration
        L16_2 = L16_2 * 0.5
        L15_2.nFadeDuration = L16_2
        L15_2 = L14_2.CustomData
        L15_2.bNeedsScrolling = true
        L15_2 = L14_2.CustomData
        L16_2 = GetMessageHeight
        L17_2 = L14_2
        L16_2 = L16_2(L17_2)
        L15_2.nHeight = L16_2
        L15_2 = L14_2.CustomData
        L15_2.nPriority = L6_2
        L15_2 = CallCallback
        L14_2.CallCallback = L15_2
        L15_2 = MrxGui
        L15_2 = L15_2.RemoveWidget
        L16_2 = L14_2
        L15_2(L16_2)
        L15_2 = A0_2.BasicData
        L15_2 = L15_2.name
        if "PDA Subtitle Buffer" ~= L15_2 then
          L15_2 = MrxGuiManager
          L15_2 = L15_2.AddWidgetToHud
          L17_2 = A0_2
          L16_2 = A0_2.GetOwner
          L16_2 = L16_2(L17_2)
          L17_2 = L14_2
          L15_2(L16_2, L17_2)
        end
      end
      L10_2 = L8_2[1]
      if L10_2 then
        L10_2 = L8_2[1]
        L10_2 = L10_2.CustomData
        L11_2 = L4_2.CustomData
        L11_2 = L11_2.bClearBuffer
        L10_2.bClearBuffer = L11_2
        L10_2 = L8_2[1]
        L10_2 = L10_2.CustomData
        L11_2 = L4_2.CustomData
        L11_2 = L11_2.fCallback
        L10_2.fCallback = L11_2
        L10_2 = L8_2[1]
        L10_2 = L10_2.CustomData
        L11_2 = L4_2.CustomData
        L11_2 = L11_2.tCallbackData
        L10_2.tCallbackData = L11_2
        L10_2 = L8_2[1]
        L10_2 = L10_2.CustomData
        L11_2 = L9_2 * 1.5
        L10_2.nDisplayDuration = L11_2
      end
      L10_2 = #L8_2
      L10_2 = L8_2[L10_2]
      if L10_2 then
        L10_2 = #L8_2
        L10_2 = L8_2[L10_2]
        L10_2 = L10_2.CustomData
        L11_2 = L4_2.CustomData
        L11_2 = L11_2.bAllowsAppends
        L10_2.bAllowsAppends = L11_2
        L10_2 = #L8_2
        L10_2 = L8_2[L10_2]
        L10_2 = L10_2.CustomData
        L11_2 = L4_2.CustomData
        L11_2 = L11_2.nFadeDuration
        L10_2.nFadeDuration = L11_2
        L10_2 = #L8_2
        L10_2 = L8_2[L10_2]
        L10_2 = L10_2.CustomData
        L11_2 = L9_2 * 0.5
        L10_2.nDisplayDuration = L11_2
      end
      L10_2 = table
      L10_2 = L10_2.remove
      L11_2 = A0_2.CustomData
      L11_2 = L11_2.PendingMessages
      L11_2 = L11_2[L6_2]
      L12_2 = L7_2
      L10_2(L11_2, L12_2)
      L10_2 = L4_2.CustomData
      L10_2 = L10_2.nId
      if L10_2 then
        L10_2 = A0_2.CustomData
        L10_2 = L10_2.MessageIndex
        L11_2 = L4_2.CustomData
        L11_2 = L11_2.nId
        L10_2[L11_2] = nil
      end
      L10_2 = #L8_2
      while 0 < L10_2 do
        L11_2 = table
        L11_2 = L11_2.insert
        L12_2 = A0_2.CustomData
        L12_2 = L12_2.PendingMessages
        L12_2 = L12_2[L6_2]
        L13_2 = 1
        L14_2 = L8_2[L10_2]
        L11_2(L12_2, L13_2, L14_2)
        L10_2 = L10_2 - 1
      end
      L11_2 = MrxGuiManager
      L11_2 = L11_2.RemoveWidgetFromHud
      L13_2 = A0_2
      L12_2 = A0_2.GetOwner
      L12_2 = L12_2(L13_2)
      L13_2 = L4_2
      L11_2(L12_2, L13_2)
      L12_2 = L4_2
      L11_2 = L4_2.delete
      L11_2(L12_2)
      L4_2 = L8_2[1]
    else
      L8_2 = false
      return L8_2
    end
  end
  if not L4_2 then
    L8_2 = false
    return L8_2
  end
  L8_2 = L4_2.CustomData
  L8_2 = L8_2.bClearBuffer
  if L8_2 then
    L8_2 = ClearVisibleMessages
    L9_2 = A0_2
    L10_2 = false
    L8_2(L9_2, L10_2)
    L2_2 = nil
  end
  L9_2 = L4_2
  L8_2 = L4_2.SetTranslucency
  L10_2 = 0
  L8_2(L9_2, L10_2)
  L8_2 = A0_2.CustomData
  L8_2 = L8_2.CurrentMessages
  L2_2 = L8_2[L1_2]
  if L2_2 then
    L9_2 = L2_2
    L8_2 = L2_2.GetLocation
    L8_2, L9_2 = L8_2(L9_2)
    L10_2 = A0_2.CustomData
    L10_2 = L10_2.bFlowDown
    if L10_2 then
      L11_2 = L4_2
      L10_2 = L4_2.SetLocation
      L12_2 = A0_2.CustomData
      L12_2 = L12_2.x1
      L13_2 = L4_2.CustomData
      L13_2 = L13_2.nHeight
      L13_2 = L9_2 - L13_2
      L14_2 = A0_2.CustomData
      L14_2 = L14_2.x2
      L15_2 = L9_2
      L10_2(L11_2, L12_2, L13_2, L14_2, L15_2)
    else
      L11_2 = L4_2
      L10_2 = L4_2.SetLocation
      L12_2 = A0_2.CustomData
      L12_2 = L12_2.x1
      L13_2 = L2_2.CustomData
      L13_2 = L13_2.nHeight
      L13_2 = L9_2 + L13_2
      L14_2 = A0_2.CustomData
      L14_2 = L14_2.x2
      L15_2 = L2_2.CustomData
      L15_2 = L15_2.nHeight
      L15_2 = L9_2 + L15_2
      L16_2 = L4_2.CustomData
      L16_2 = L16_2.nHeight
      L15_2 = L15_2 + L16_2
      L10_2(L11_2, L12_2, L13_2, L14_2, L15_2)
    end
  else
    L8_2 = A0_2.CustomData
    L8_2 = L8_2.bFlowDown
    if L8_2 then
      L9_2 = L4_2
      L8_2 = L4_2.SetLocation
      L10_2 = A0_2.CustomData
      L10_2 = L10_2.x1
      L11_2 = A0_2.CustomData
      L11_2 = L11_2.y2
      L12_2 = L4_2.CustomData
      L12_2 = L12_2.nHeight
      L11_2 = L11_2 - L12_2
      L12_2 = A0_2.CustomData
      L12_2 = L12_2.x2
      L13_2 = A0_2.CustomData
      L13_2 = L13_2.y2
      L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
    else
      L9_2 = L4_2
      L8_2 = L4_2.SetLocation
      L10_2 = A0_2.CustomData
      L10_2 = L10_2.x1
      L11_2 = A0_2.CustomData
      L11_2 = L11_2.y1
      L12_2 = A0_2.CustomData
      L12_2 = L12_2.x2
      L13_2 = A0_2.CustomData
      L13_2 = L13_2.y1
      L14_2 = L4_2.CustomData
      L14_2 = L14_2.nHeight
      L13_2 = L13_2 + L14_2
      L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
    end
  end
  L8_2 = table
  L8_2 = L8_2.remove
  L9_2 = A0_2.CustomData
  L9_2 = L9_2.PendingMessages
  L9_2 = L9_2[L6_2]
  L10_2 = L7_2
  L8_2(L9_2, L10_2)
  L8_2 = L4_2.CustomData
  L8_2 = L8_2.nId
  if L8_2 then
    L8_2 = A0_2.CustomData
    L8_2 = L8_2.MessageIndex
    L9_2 = L4_2.CustomData
    L9_2 = L9_2.nId
    L8_2[L9_2] = nil
  end
  L8_2 = table
  L8_2 = L8_2.insert
  L9_2 = A0_2.CustomData
  L9_2 = L9_2.CurrentMessages
  L10_2 = L4_2
  L8_2(L9_2, L10_2)
  L9_2 = A0_2
  L8_2 = A0_2.AddChild
  L10_2 = L4_2
  L8_2(L9_2, L10_2)
  L8_2 = MrxGui
  L8_2 = L8_2.AddWidget
  L9_2 = L4_2
  L8_2(L9_2)
  L9_2 = L4_2
  L8_2 = L4_2.SetSleeping
  L10_2 = false
  L8_2(L9_2, L10_2)
  L8_2 = A0_2.CustomData
  L9_2 = A0_2.CustomData
  L9_2 = L9_2.nRemainingSpace
  L10_2 = L4_2.CustomData
  L10_2 = L10_2.nHeight
  L9_2 = L9_2 - L10_2
  L8_2.nRemainingSpace = L9_2
  L9_2 = L4_2
  L8_2 = L4_2.CallCallback
  L8_2(L9_2)
  L8_2 = A0_2.CustomData
  L8_2 = L8_2.bHasBackdrop
  if L8_2 then
    L9_2 = A0_2
    L8_2 = A0_2.SetVisible
    L10_2 = true
    L8_2(L9_2, L10_2)
  end
  L8_2 = true
  return L8_2
end

PushMessageIntoTextBuffer = L1_1

function L1_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.GetHeight
  return L1_2(L2_2)
end

GetMessageHeight = L1_1

function L1_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.Wrap
  L1_2(L2_2)
end

WrapText = L1_1

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 ~= "table" then
    L1_2 = nil
    return L1_2
  end
  L1_2 = table
  L1_2 = L1_2.getn
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L1_2 = L1_2 == 0
  return L1_2
end

IsEmpty = L1_1

function L1_1(A0_2)
  local L1_2
  if 0 < A0_2 then
    return A0_2
  end
  L1_2 = A0_2 * -1
  return L1_2
end

MboxAbs = L1_1

function L1_1(A0_2, A1_2, A2_2)
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

ValidateParameter = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A1_2.bOn
  if L2_2 then
    L2_2 = A0_2.CustomData
    L2_2.bE3HudMode = true
    L2_2 = MrxGuiBase
    L2_2 = L2_2.RemoveWidgetWithChildren
    L4_2 = A0_2
    L3_2 = A0_2.GetChildren
    L3_2 = L3_2(L4_2)
    L3_2 = L3_2[1]
    L2_2(L3_2)
    L2_2 = pairs
    L4_2 = A0_2
    L3_2 = A0_2.GetChildren
    L3_2 = L3_2(L4_2)
    L3_2 = L3_2[1]
    L3_2 = L3_2.CustomData
    L3_2 = L3_2.CurrentMessages
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2, L6_2 in L2_2, L3_2, L4_2 do
      L8_2 = L6_2
      L7_2 = L6_2.SetVisible
      L9_2 = false
      L7_2(L8_2, L9_2)
    end
  else
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.bE3HudMode
    if L2_2 then
      L2_2 = A0_2.CustomData
      L2_2.bE3HudMode = false
      L2_2 = MrxGuiBase
      L2_2 = L2_2.AddWidgetWithChildren
      L4_2 = A0_2
      L3_2 = A0_2.GetChildren
      L3_2 = L3_2(L4_2)
      L3_2 = L3_2[1]
      L2_2(L3_2)
      L2_2 = pairs
      L4_2 = A0_2
      L3_2 = A0_2.GetChildren
      L3_2 = L3_2(L4_2)
      L3_2 = L3_2[1]
      L3_2 = L3_2.CustomData
      L3_2 = L3_2.CurrentMessages
      L2_2, L3_2, L4_2 = L2_2(L3_2)
      for L5_2, L6_2 in L2_2, L3_2, L4_2 do
        L8_2 = L6_2
        L7_2 = L6_2.SetVisible
        L9_2 = true
        L7_2(L8_2, L9_2)
      end
    end
  end
end

HandleE3HudModeEvent = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A1_2.sMessage
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.AddMessage
    L4_2 = A1_2.sMessage
    L5_2 = nil
    L6_2 = A1_2.nDuration
    L2_2(L3_2, L4_2, L5_2, L6_2)
  end
end

HandleAddMessageEvent = L1_1

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = {}
  L1_2.CommandType = "rectangle"
  L1_2.x1 = 10
  L1_2.y1 = 10
  L1_2.x2 = 400
  L1_2.y2 = 300
  L1_2.u1 = 0
  L1_2.v1 = 0
  L1_2.u2 = 1
  L1_2.v2 = 1
  L1_2.RedLevel = 128
  L1_2.GreenLevel = 0
  L1_2.BlueLevel = 0
  L1_2.TranslucencyLevel = 192
  L1_2.texture = nil
  L1_2.HorizontalAnchor = "left"
  L1_2.VerticalAnchor = "top"
  L2_2 = A0_2.DrawingCommands
  L2_2[2] = L1_2
end

DrawDebugRectangle = L1_1
