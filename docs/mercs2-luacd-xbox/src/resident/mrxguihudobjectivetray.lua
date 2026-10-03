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

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L3_2 = type
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if "number" ~= L3_2 then
    L3_2 = false
    return L3_2
  end
  if A1_2 < 1 or 3 < A1_2 then
    L3_2 = false
    return L3_2
  end
  L3_2 = type
  L4_2 = A2_2
  L3_2 = L3_2(L4_2)
  if "table" ~= L3_2 then
    L3_2 = false
    return L3_2
  end
  L4_2 = A0_2
  L3_2 = A0_2.ClearSlot
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
  L4_2 = A2_2
  L3_2 = A2_2.GetLocation
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  if not L5_2 then
    L7_2 = A0_2.CustomData
    L7_2 = L7_2.nDefaultWidth
    L5_2 = L3_2 + L7_2
  end
  if not L6_2 then
    L7_2 = A0_2.CustomData
    L7_2 = L7_2.nDefaultHeight
    L6_2 = L4_2 + L7_2
  end
  if not L5_2 or not L6_2 then
    L8_2 = A2_2
    L7_2 = A2_2.SetLocation
    L9_2 = L3_2
    L10_2 = L4_2
    L11_2 = L5_2
    L12_2 = L6_2
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  end
  L8_2 = A0_2
  L7_2 = A0_2.GetChildren
  L7_2 = L7_2(L8_2)
  L7_2 = L7_2[A1_2]
  L8_2 = L7_2
  L7_2 = L7_2.GetLocation
  L7_2, L8_2 = L7_2(L8_2)
  L10_2 = A0_2
  L9_2 = A0_2.GetChildren
  L9_2 = L9_2(L10_2)
  L9_2 = L9_2[A1_2]
  L10_2 = L9_2
  L9_2 = L9_2.SetLocation
  L11_2 = nil
  L12_2 = L8_2
  L13_2 = nil
  L14_2 = A0_2.CustomData
  L14_2 = L14_2.nDefaultHeight
  L14_2 = L8_2 + L14_2
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
  L10_2 = A2_2
  L9_2 = A2_2.SetOwner
  L12_2 = A0_2
  L11_2 = A0_2.GetOwner
  L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2 = L11_2(L12_2)
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  L10_2 = A0_2
  L9_2 = A0_2.GetChildren
  L9_2 = L9_2(L10_2)
  L9_2 = L9_2[A1_2]
  L11_2 = L9_2
  L10_2 = L9_2.GetLocation
  L10_2, L11_2, L12_2 = L10_2(L11_2)
  L13_2 = L5_2 - L3_2
  L15_2 = A2_2
  L14_2 = A2_2.SetLocation
  L16_2 = L12_2 - L13_2
  L17_2 = L11_2
  L14_2(L15_2, L16_2, L17_2)
  L15_2 = L9_2
  L14_2 = L9_2.GetChildren
  L14_2 = L14_2(L15_2)
  L14_2 = L14_2[1]
  if L14_2 then
    L15_2 = L9_2
    L14_2 = L9_2.GetChildren
    L14_2 = L14_2(L15_2)
    L14_2 = L14_2[1]
    L16_2 = L9_2
    L15_2 = L9_2.RemoveChild
    L17_2 = L14_2
    L15_2(L16_2, L17_2)
    L15_2 = MrxGui
    L15_2 = L15_2.RemoveWidget
    L16_2 = L14_2
    L15_2(L16_2)
    L15_2 = MrxGuiManager
    L15_2 = L15_2.RemoveWidgetFromHud
    L17_2 = L14_2
    L16_2 = L14_2.GetOwner
    L16_2 = L16_2(L17_2)
    L17_2 = L14_2
    L15_2(L16_2, L17_2)
    L16_2 = L14_2
    L15_2 = L14_2.delete
    L15_2(L16_2)
  end
  L15_2 = A2_2
  L14_2 = A2_2.SetOwner
  L17_2 = A0_2
  L16_2 = A0_2.GetOwner
  L16_2, L17_2 = L16_2(L17_2)
  L14_2(L15_2, L16_2, L17_2)
  L15_2 = A2_2
  L14_2 = A2_2.SetVisible
  L17_2 = A0_2
  L16_2 = A0_2.GetVisible
  L16_2, L17_2 = L16_2(L17_2)
  L14_2(L15_2, L16_2, L17_2)
  L15_2 = L9_2
  L14_2 = L9_2.AddChild
  L16_2 = A2_2
  L14_2(L15_2, L16_2)
  L14_2 = MrxGuiManager
  L14_2 = L14_2.AddWidgetToHud
  L16_2 = A2_2
  L15_2 = A2_2.GetOwner
  L15_2 = L15_2(L16_2)
  L16_2 = A2_2
  L14_2(L15_2, L16_2)
  L14_2 = MrxGui
  L14_2 = L14_2.AddWidgetWithChildren
  L15_2 = A2_2
  L14_2(L15_2)
  L14_2 = true
  return L14_2
end

SetSlotToWidget = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = type
  L4_2 = A2_2
  L3_2 = L3_2(L4_2)
  if "string" ~= L3_2 then
    L3_2 = nil
    return L3_2
  end
  L4_2 = A0_2
  L3_2 = A0_2.GetChildren
  L3_2 = L3_2(L4_2)
  L3_2 = L3_2[A1_2]
  L4_2 = nil
  if L3_2 then
    L6_2 = L3_2
    L5_2 = L3_2.GetChildren
    L5_2 = L5_2(L6_2)
    L4_2 = L5_2[1]
  else
    L5_2 = nil
    return L5_2
  end
  if L4_2 then
    L5_2 = L4_2.BasicData
    L5_2 = L5_2.type
    if "text" == L5_2 then
      L6_2 = L4_2
      L5_2 = L4_2.SetText
      L7_2 = A2_2
      L5_2(L6_2, L7_2)
      return L4_2
    end
  end
  L5_2 = MrxGui
  L5_2 = L5_2.TextWidget
  L6_2 = L5_2
  L5_2 = L5_2.new
  L5_2 = L5_2(L6_2)
  L7_2 = L5_2
  L6_2 = L5_2.SetFont
  L8_2 = "english_18"
  L6_2(L7_2, L8_2)
  L7_2 = L5_2
  L6_2 = L5_2.SetScale
  L8_2 = 1
  L6_2(L7_2, L8_2)
  L7_2 = L5_2
  L6_2 = L5_2.SetText
  L8_2 = A2_2
  L6_2(L7_2, L8_2)
  L7_2 = L5_2
  L6_2 = L5_2.SetLocation
  L8_2 = 0
  L9_2 = 0
  L10_2 = A0_2.CustomData
  L10_2 = L10_2.nDefaultWidth
  L11_2 = A0_2.CustomData
  L11_2 = L11_2.nDefaultHeight
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  L7_2 = L5_2
  L6_2 = L5_2.SetLocation
  L8_2 = 0
  L9_2 = 0
  L10_2 = A0_2.CustomData
  L10_2 = L10_2.nDefaultWidth
  L12_2 = L5_2
  L11_2 = L5_2.GetHeight
  L11_2, L12_2 = L11_2(L12_2)
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L7_2 = L5_2
  L6_2 = L5_2.SetJustification
  L8_2 = "right"
  L6_2(L7_2, L8_2)
  L7_2 = L5_2
  L6_2 = L5_2.SetAnchoring
  L8_2 = "left"
  L9_2 = "top"
  L6_2(L7_2, L8_2, L9_2)
  L7_2 = A0_2
  L6_2 = A0_2.SetSlotToWidget
  L8_2 = A1_2
  L9_2 = L5_2
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    return L5_2
  end
  L7_2 = L5_2
  L6_2 = L5_2.delete
  L6_2(L7_2)
  L6_2 = nil
  return L6_2
end

SetSlotToText = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L5_2 = type
  L6_2 = A2_2
  L5_2 = L5_2(L6_2)
  if "string" ~= L5_2 then
    L5_2 = nil
    return L5_2
  end
  if not A3_2 then
    L5_2 = A0_2.CustomData
    A3_2 = L5_2.nDefaultWidth
  end
  if not A4_2 then
    L5_2 = A0_2.CustomData
    A4_2 = L5_2.nDefaultHeight
  end
  L6_2 = A0_2
  L5_2 = A0_2.GetChildren
  L5_2 = L5_2(L6_2)
  L5_2 = L5_2[A1_2]
  L6_2 = nil
  if L5_2 then
    L8_2 = L5_2
    L7_2 = L5_2.GetChildren
    L7_2 = L7_2(L8_2)
    L6_2 = L7_2[1]
  else
    L7_2 = nil
    return L7_2
  end
  if L6_2 then
    L7_2 = L6_2.BasicData
    L7_2 = L7_2.type
    if "image" == L7_2 then
      L8_2 = L6_2
      L7_2 = L6_2.SetTexture
      L9_2 = A2_2
      L7_2(L8_2, L9_2)
      L8_2 = L6_2
      L7_2 = L6_2.GetLocation
      L7_2, L8_2 = L7_2(L8_2)
      L10_2 = L6_2
      L9_2 = L6_2.SetLocation
      L11_2 = L7_2
      L12_2 = L8_2
      L13_2 = L7_2 + A3_2
      L14_2 = L8_2 + A4_2
      L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
      return L6_2
    end
  end
  L7_2 = MrxGui
  L7_2 = L7_2.ImageWidget
  L8_2 = L7_2
  L7_2 = L7_2.new
  L7_2 = L7_2(L8_2)
  L9_2 = L7_2
  L8_2 = L7_2.SetTexture
  L10_2 = A2_2
  L8_2(L9_2, L10_2)
  L9_2 = L7_2
  L8_2 = L7_2.SetLocation
  L10_2 = 0
  L11_2 = 0
  L12_2 = A3_2
  L13_2 = A4_2
  L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  L9_2 = L7_2
  L8_2 = L7_2.SetAnchoring
  L10_2 = "left"
  L11_2 = "top"
  L8_2(L9_2, L10_2, L11_2)
  L9_2 = A0_2
  L8_2 = A0_2.SetSlotToWidget
  L10_2 = A1_2
  L11_2 = L7_2
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  if L8_2 then
    return L7_2
  end
  L8_2 = nil
  return L8_2
end

SetSlotToImage = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L2_2 = L2_2[A1_2]
  if L2_2 then
    L4_2 = L2_2
    L3_2 = L2_2.GetChildren
    L3_2 = L3_2(L4_2)
    L3_2 = L3_2[1]
    if L3_2 then
      goto lbl_12
    end
  end
  do return end
  ::lbl_12::
  L4_2 = L2_2
  L3_2 = L2_2.GetLocation
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  L7_2 = L6_2 - L4_2
  L8_2 = A0_2.CustomData
  L8_2 = L8_2.nDefaultHeight
  if L7_2 > L8_2 then
    L7_2 = A1_2 + 1
    L8_2 = L6_2 - L4_2
    L9_2 = A0_2.CustomData
    L9_2 = L9_2.nDefaultHeight
    L8_2 = L8_2 - L9_2
    while true do
      L10_2 = A0_2
      L9_2 = A0_2.GetChildren
      L9_2 = L9_2(L10_2)
      L9_2 = L9_2[L7_2]
      if not L9_2 then
        break
      end
      L10_2 = A0_2
      L9_2 = A0_2.GetChildren
      L9_2 = L9_2(L10_2)
      L9_2 = L9_2[L7_2]
      L10_2 = L9_2
      L9_2 = L9_2.GetLocation
      L9_2, L10_2 = L9_2(L10_2)
      L12_2 = A0_2
      L11_2 = A0_2.GetChildren
      L11_2 = L11_2(L12_2)
      L11_2 = L11_2[L7_2]
      L12_2 = L11_2
      L11_2 = L11_2.SetLocation
      L13_2 = nil
      L14_2 = L10_2 - L8_2
      L11_2(L12_2, L13_2, L14_2)
      L7_2 = L7_2 + 1
    end
    L10_2 = L2_2
    L9_2 = L2_2.SetLocation
    L11_2 = nil
    L12_2 = L4_2
    L13_2 = nil
    L14_2 = A0_2.CustomData
    L14_2 = L14_2.nDefaultHeight
    L14_2 = L4_2 + L14_2
    L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
  end
  L7_2 = MrxGui
  L7_2 = L7_2.RemoveWidgetWithChildren
  L8_2 = L2_2
  L7_2(L8_2)
  L8_2 = L2_2
  L7_2 = L2_2.GetChildren
  L7_2 = L7_2(L8_2)
  L7_2 = L7_2[1]
  L9_2 = L2_2
  L8_2 = L2_2.RemoveChild
  L10_2 = L7_2
  L8_2(L9_2, L10_2)
  L8_2 = MrxGuiManager
  L8_2 = L8_2.RemoveWidgetFromHud
  L10_2 = L7_2
  L9_2 = L7_2.GetOwner
  L9_2 = L9_2(L10_2)
  L10_2 = L7_2
  L8_2(L9_2, L10_2)
  L9_2 = L7_2
  L8_2 = L7_2.delete
  L8_2(L9_2)
end

ClearSlot = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  if not A1_2 then
    L2_2 = false
    return L2_2
  end
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L2_2 = L2_2[A1_2]
  if L2_2 then
    L4_2 = L2_2
    L3_2 = L2_2.GetChildren
    L3_2 = L3_2(L4_2)
    L3_2 = L3_2[1]
    if L3_2 then
      L3_2 = true
      return L3_2
    end
  end
  L3_2 = false
  return L3_2
end

IsSlotOccupied = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L2_2 = 3
  L3_2 = 2
  L4_2 = 16
  L5_2 = A0_2.CustomData
  L5_2.nSpacing = 5
  L5_2 = A0_2.CustomData
  L5_2.nDefaultHeight = L4_2
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nSpacing
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.nDefaultHeight
  L5_2 = L5_2 + L6_2
  L6_2 = 1
  L8_2 = A0_2
  L7_2 = A0_2.GetLocation
  L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
  L11_2 = A0_2.CustomData
  L12_2 = L9_2 - L7_2
  L11_2.nDefaultWidth = L12_2
  while L2_2 >= L6_2 do
    L11_2 = MrxGui
    L11_2 = L11_2.Widget
    L12_2 = L11_2
    L11_2 = L11_2.new
    L11_2 = L11_2(L12_2)
    L13_2 = L11_2
    L12_2 = L11_2.SetOwner
    L15_2 = A0_2
    L14_2 = A0_2.GetOwner
    L14_2, L15_2, L16_2, L17_2 = L14_2(L15_2)
    L12_2(L13_2, L14_2, L15_2, L16_2, L17_2)
    L13_2 = L11_2
    L12_2 = L11_2.SetLocation
    L14_2 = L7_2
    L15_2 = L6_2 - 1
    L15_2 = L15_2 * L5_2
    L15_2 = L8_2 + L15_2
    L16_2 = L9_2
    L17_2 = L6_2 - 1
    L17_2 = L17_2 * L5_2
    L17_2 = L8_2 + L17_2
    L17_2 = L17_2 + L4_2
    L12_2(L13_2, L14_2, L15_2, L16_2, L17_2)
    L13_2 = L11_2
    L12_2 = L11_2.SetVisible
    L14_2 = false
    L12_2(L13_2, L14_2)
    L13_2 = L11_2
    L12_2 = L11_2.SetAnchoring
    L14_2 = "left"
    L15_2 = "top"
    L12_2(L13_2, L14_2, L15_2)
    L13_2 = A0_2
    L12_2 = A0_2.AddChild
    L14_2 = L11_2
    L12_2(L13_2, L14_2)
    L6_2 = L6_2 + 1
    L12_2 = MrxGuiManager
    L12_2 = L12_2.AddWidgetToHud
    L14_2 = A0_2
    L13_2 = A0_2.GetOwner
    L13_2 = L13_2(L14_2)
    L14_2 = L11_2
    L12_2(L13_2, L14_2)
  end
  L11_2 = SetSlotToWidget
  A0_2.SetSlotToWidget = L11_2
  L11_2 = SetSlotToText
  A0_2.SetSlotToText = L11_2
  L11_2 = SetSlotToImage
  A0_2.SetSlotToImage = L11_2
  L11_2 = ClearSlot
  A0_2.ClearSlot = L11_2
  L11_2 = IsSlotOccupied
  A0_2.IsSlotOccupied = L11_2
end

_HandleInitializationEvent = L0_1
