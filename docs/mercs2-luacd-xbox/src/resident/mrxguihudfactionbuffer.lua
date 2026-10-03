local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = 2
_knNumSlots = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L1_2 = L1_2[1]
  L3_2 = A0_2
  L2_2 = A0_2.GetLocation
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  L6_2 = A0_2.CustomData
  L8_2 = L1_2
  L7_2 = L1_2.GetLocation
  L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
  L11_2 = L10_2 - L8_2
  L12_2 = {}
  L6_2.tSlotLife = L12_2
  L12_2 = {}
  L6_2.tSlotPointData = L12_2
  L12_2 = {}
  L6_2.tSlotOccupants = L12_2
  L12_2 = {}
  L6_2.tFactionGauges = L12_2
  L12_2 = 1
  while true do
    L13_2 = _knNumSlots
    if not (L12_2 <= L13_2) then
      break
    end
    L13_2 = L6_2.tSlotLife
    L13_2[L12_2] = 0
    L13_2 = L6_2.tSlotPointData
    L14_2 = {}
    L14_2.x = L2_2
    L15_2 = L12_2 - 1
    L15_2 = L15_2 * L11_2
    L15_2 = L3_2 + L15_2
    L14_2.y = L15_2
    L14_2.TranslucencyLevel = 255
    L13_2[L12_2] = L14_2
    L12_2 = L12_2 + 1
  end
  L13_2 = L6_2.tSlotPointData
  L14_2 = _knNumSlots
  L14_2 = L14_2 + 1
  L15_2 = {}
  L15_2.x = L2_2
  L15_2.y = L5_2
  L15_2.TranslucencyLevel = 0
  L13_2[L14_2] = L15_2
  L6_2.oTemplateGauge = L1_2
  L13_2 = MrxGui
  L13_2 = L13_2.RemoveWidgetWithChildren
  L14_2 = L6_2.oTemplateGauge
  L13_2(L14_2)
  L14_2 = A0_2
  L13_2 = A0_2.SetEventHandler
  L15_2 = "GuiUpdate"
  L16_2 = _Update
  L13_2(L14_2, L15_2, L16_2)
  L13_2 = AddFactionGauge
  A0_2.AddFactionGauge = L13_2
  L13_2 = SetInsideFactionZone
  A0_2.SetInsideFactionZone = L13_2
  L13_2 = SetValue
  A0_2.SetValue = L13_2
  L13_2 = ShowAll
  A0_2.ShowAll = L13_2
  L13_2 = StartTimer
  A0_2.StartTimer = L13_2
  L13_2 = StartPursuit
  A0_2.StartPursuit = L13_2
  L13_2 = HideGauge
  A0_2.HideGauge = L13_2
end

Initialize = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = type
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if "string" ~= L3_2 then
    return
  end
  L3_2 = type
  L4_2 = A2_2
  L3_2 = L3_2(L4_2)
  if "string" ~= L3_2 then
    A2_2 = nil
  end
  L3_2 = A0_2.CustomData
  L4_2 = L3_2.oTemplateGauge
  L5_2 = L4_2
  L4_2 = L4_2.Duplicate
  L4_2 = L4_2(L5_2)
  L6_2 = L4_2
  L5_2 = L4_2._Initialize
  L5_2(L6_2)
  L6_2 = L4_2
  L5_2 = L4_2.SetIcon
  L7_2 = A2_2
  L5_2(L6_2, L7_2)
  L5_2 = L4_2.CustomData
  L5_2 = L5_2.oTimer
  L6_2 = L5_2
  L5_2 = L5_2._Initialize
  L5_2(L6_2)
  L5_2 = L4_2.CustomData
  L6_2 = {}
  L5_2.tSlotPoints = L6_2
  L5_2 = 1
  while true do
    L6_2 = _knNumSlots
    L6_2 = L6_2 + 1
    if not (L5_2 <= L6_2) then
      break
    end
    L6_2 = L4_2.CustomData
    L6_2 = L6_2.tSlotPoints
    L8_2 = L4_2
    L7_2 = L4_2.AddAnimationPoint
    L9_2 = L3_2.tSlotPointData
    L9_2 = L9_2[L5_2]
    L7_2 = L7_2(L8_2, L9_2)
    L6_2[L5_2] = L7_2
    L5_2 = L5_2 + 1
  end
  L7_2 = A0_2
  L6_2 = A0_2.AddChild
  L8_2 = L4_2
  L6_2(L7_2, L8_2)
  L6_2 = L3_2.tFactionGauges
  L6_2[A1_2] = L4_2
  L7_2 = L4_2
  L6_2 = L4_2.SetVisible
  L8_2 = false
  L6_2(L7_2, L8_2)
  L6_2 = A0_2.BasicData
  L6_2 = L6_2.bEnabled
  if L6_2 then
    L6_2 = MrxGui
    L6_2 = L6_2.AddWidgetWithChildren
    L7_2 = L4_2
    L6_2(L7_2)
  end
  L7_2 = L4_2
  L6_2 = L4_2.AnimateToPoint
  L8_2 = L4_2.CustomData
  L8_2 = L8_2.tSlotPoints
  L9_2 = _knNumSlots
  L9_2 = L9_2 + 1
  L8_2 = L8_2[L9_2]
  L9_2 = 0
  L10_2 = true
  L11_2 = L4_2.SetVisible
  L12_2 = false
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
end

AddFactionGauge = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
end

SetInsideFactionZone = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L4_2 = A0_2.CustomData
  L5_2 = L4_2.tFactionGauges
  L5_2 = L5_2[A1_2]
  if not L5_2 then
    return
  end
  L6_2 = math
  L6_2 = L6_2.abs
  L8_2 = L5_2
  L7_2 = L5_2.GetValue
  L7_2 = L7_2(L8_2)
  L7_2 = L7_2 - A2_2
  L6_2 = L6_2(L7_2)
  if L6_2 < 3 then
    A3_2 = true
  end
  L7_2 = 0.25
  if A3_2 then
    L7_2 = 0
  end
  L9_2 = L5_2
  L8_2 = L5_2.SetValue
  L10_2 = A2_2
  L11_2 = A3_2
  L8_2(L9_2, L10_2, L11_2)
  if not A3_2 then
    L8_2 = nil
    L9_2 = false
    L10_2 = _FindSlot
    L11_2 = A0_2
    L12_2 = A1_2
    L10_2, L11_2 = L10_2(L11_2, L12_2)
    L9_2 = L11_2
    L8_2 = L10_2
    L10_2 = 0
    L11_2 = L4_2.tSlotOccupants
    L11_2 = L11_2[L8_2]
    if L11_2 and not L9_2 then
      L11_2 = L4_2.tSlotOccupants
      L11_2 = L11_2[L8_2]
      L13_2 = L11_2
      L12_2 = L11_2.AnimateToPoint
      L14_2 = L11_2.CustomData
      L14_2 = L14_2.tSlotPoints
      L15_2 = _knNumSlots
      L15_2 = L15_2 + 1
      L14_2 = L14_2[L15_2]
      L15_2 = L7_2
      L16_2 = true
      L17_2 = L11_2.SetVisible
      L18_2 = false
      L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
    end
    L11_2 = L4_2.tSlotOccupants
    L11_2 = L11_2[L8_2]
    if L11_2 == L5_2 then
      L11_2 = L4_2.tSlotLife
      L10_2 = L11_2[L8_2]
    end
    L11_2 = L4_2.tSlotLife
    L12_2 = math
    L12_2 = L12_2.max
    L13_2 = 5
    L14_2 = L10_2
    L12_2 = L12_2(L13_2, L14_2)
    L11_2[L8_2] = L12_2
    L11_2 = L4_2.tSlotOccupants
    L11_2[L8_2] = L5_2
    L12_2 = L5_2
    L11_2 = L5_2.SetVisible
    L13_2 = true
    L11_2(L12_2, L13_2)
    if not L9_2 then
      L12_2 = L5_2
      L11_2 = L5_2.AnimateToPoint
      L13_2 = L5_2.CustomData
      L13_2 = L13_2.tSlotPoints
      L13_2 = L13_2[L8_2]
      L14_2 = L7_2
      L15_2 = true
      L11_2(L12_2, L13_2, L14_2, L15_2)
    end
    L11_2 = MrxGui
    L11_2 = L11_2.GetWidgetByNameAndOwner
    L12_2 = "Objective Tray"
    L14_2 = A0_2
    L13_2 = A0_2.GetOwner
    L13_2, L14_2, L15_2, L16_2, L17_2, L18_2 = L13_2(L14_2)
    L11_2 = L11_2(L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
    if L11_2 then
      L13_2 = L11_2
      L12_2 = L11_2.IsSlotOccupied
      L14_2 = 3
      L12_2 = L12_2(L13_2, L14_2)
      if L12_2 then
        L13_2 = L11_2
        L12_2 = L11_2.GetVisible
        L12_2 = L12_2(L13_2)
        if L12_2 then
          L13_2 = L11_2
          L12_2 = L11_2.SetVisible
          L14_2 = false
          L12_2(L13_2, L14_2)
          L12_2 = A0_2.CustomData
          L12_2.bTrayDisabled = true
        end
      end
    end
  end
end

SetValue = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L5_2 = A0_2.CustomData
  L6_2 = L5_2.tFactionGauges
  L6_2 = L6_2[A1_2]
  if not L6_2 then
    return
  end
  L7_2 = 0.25
  L8_2 = bInitialize
  if L8_2 then
    L7_2 = 0
  end
  L8_2 = nil
  L9_2 = false
  L10_2 = _FindSlot
  L11_2 = A0_2
  L12_2 = A1_2
  L10_2, L11_2 = L10_2(L11_2, L12_2)
  L9_2 = L11_2
  L8_2 = L10_2
  L10_2 = L5_2.tSlotOccupants
  L10_2 = L10_2[L8_2]
  if L10_2 and not L9_2 then
    L10_2 = L5_2.tSlotOccupants
    L10_2 = L10_2[L8_2]
    L12_2 = L10_2
    L11_2 = L10_2.AnimateToPoint
    L13_2 = L10_2.CustomData
    L13_2 = L13_2.tSlotPoints
    L14_2 = _knNumSlots
    L14_2 = L14_2 + 1
    L13_2 = L13_2[L14_2]
    L14_2 = L7_2
    L15_2 = true
    L16_2 = L10_2.SetVisible
    L17_2 = false
    L11_2(L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  end
  L11_2 = L6_2
  L10_2 = L6_2.StartTimer
  L12_2 = A2_2
  L13_2 = A3_2
  L14_2 = A4_2
  L10_2(L11_2, L12_2, L13_2, L14_2)
  L10_2 = L5_2.tSlotLife
  L11_2 = 5 + A2_2
  L10_2[L8_2] = L11_2
  L10_2 = L5_2.tSlotOccupants
  L10_2[L8_2] = L6_2
  L11_2 = L6_2
  L10_2 = L6_2.SetVisible
  L12_2 = true
  L13_2 = true
  L10_2(L11_2, L12_2, L13_2)
  if not L9_2 then
    L11_2 = L6_2
    L10_2 = L6_2.AnimateToPoint
    L12_2 = L6_2.CustomData
    L12_2 = L12_2.tSlotPoints
    L12_2 = L12_2[L8_2]
    L13_2 = L7_2
    L14_2 = true
    L10_2(L11_2, L12_2, L13_2, L14_2)
  end
  L10_2 = MrxGui
  L10_2 = L10_2.GetWidgetByNameAndOwner
  L11_2 = "Objective Tray"
  L13_2 = A0_2
  L12_2 = A0_2.GetOwner
  L12_2, L13_2, L14_2, L15_2, L16_2, L17_2 = L12_2(L13_2)
  L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  if L10_2 then
    L12_2 = L10_2
    L11_2 = L10_2.IsSlotOccupied
    L13_2 = 3
    L11_2 = L11_2(L12_2, L13_2)
    if L11_2 then
      L12_2 = L10_2
      L11_2 = L10_2.GetVisible
      L11_2 = L11_2(L12_2)
      if L11_2 then
        L12_2 = L10_2
        L11_2 = L10_2.SetVisible
        L13_2 = false
        L11_2(L12_2, L13_2)
        L11_2 = A0_2.CustomData
        L11_2.bTrayDisabled = true
      end
    end
  end
end

StartTimer = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L5_2 = A0_2.CustomData
  L6_2 = L5_2.tFactionGauges
  L6_2 = L6_2[A1_2]
  if not L6_2 then
    return
  end
  L7_2 = 0.25
  L8_2 = bInitialize
  if L8_2 then
    L7_2 = 0
  end
  L8_2 = nil
  L9_2 = false
  L10_2 = _FindSlot
  L11_2 = A0_2
  L12_2 = A1_2
  L10_2, L11_2 = L10_2(L11_2, L12_2)
  L9_2 = L11_2
  L8_2 = L10_2
  L10_2 = L5_2.tSlotOccupants
  L10_2 = L10_2[L8_2]
  if L10_2 and not L9_2 then
    L10_2 = L5_2.tSlotOccupants
    L10_2 = L10_2[L8_2]
    L12_2 = L10_2
    L11_2 = L10_2.AnimateToPoint
    L13_2 = L10_2.CustomData
    L13_2 = L13_2.tSlotPoints
    L14_2 = _knNumSlots
    L14_2 = L14_2 + 1
    L13_2 = L13_2[L14_2]
    L14_2 = L7_2
    L15_2 = true
    L16_2 = L10_2.SetVisible
    L17_2 = false
    L11_2(L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  end
  L11_2 = L6_2
  L10_2 = L6_2.StartPursuit
  L12_2 = A2_2
  L13_2 = A3_2
  L14_2 = A4_2
  L10_2(L11_2, L12_2, L13_2, L14_2)
  L10_2 = L5_2.tSlotOccupants
  L10_2[L8_2] = L6_2
  A2_2 = -3
  if L9_2 then
    L10_2 = L5_2.tSlotLife
    L10_2 = L10_2[L8_2]
    if not (L10_2 <= 0) then
      goto lbl_56
    end
  end
  L10_2 = L5_2.tSlotLife
  L11_2 = 2 + A2_2
  L10_2[L8_2] = L11_2
  ::lbl_56::
  if not L9_2 then
    L11_2 = L6_2
    L10_2 = L6_2.AnimateToPoint
    L12_2 = L6_2.CustomData
    L12_2 = L12_2.tSlotPoints
    L12_2 = L12_2[L8_2]
    L13_2 = L7_2
    L14_2 = true
    L10_2(L11_2, L12_2, L13_2, L14_2)
  end
  L10_2 = MrxGui
  L10_2 = L10_2.GetWidgetByNameAndOwner
  L11_2 = "Objective Tray"
  L13_2 = A0_2
  L12_2 = A0_2.GetOwner
  L12_2, L13_2, L14_2, L15_2, L16_2, L17_2 = L12_2(L13_2)
  L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  if L10_2 then
    L12_2 = L10_2
    L11_2 = L10_2.IsSlotOccupied
    L13_2 = 3
    L11_2 = L11_2(L12_2, L13_2)
    if L11_2 then
      L12_2 = L10_2
      L11_2 = L10_2.GetVisible
      L11_2 = L11_2(L12_2)
      if L11_2 then
        L12_2 = L10_2
        L11_2 = L10_2.SetVisible
        L13_2 = false
        L11_2(L12_2, L13_2)
        L11_2 = A0_2.CustomData
        L11_2.bTrayDisabled = true
      end
    end
  end
end

StartPursuit = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = A0_2.CustomData
  L3_2 = L2_2.tFactionGauges
  L3_2 = L3_2[A1_2]
  if not L3_2 then
    return
  end
  L4_2 = nil
  L5_2 = false
  L6_2 = _FindSlot
  L7_2 = A0_2
  L8_2 = A1_2
  L6_2, L7_2 = L6_2(L7_2, L8_2)
  L5_2 = L7_2
  L4_2 = L6_2
  if L5_2 then
    L6_2 = L2_2.tSlotOccupants
    L6_2[L4_2] = nil
    L6_2 = L2_2.tSlotLife
    L6_2[L4_2] = 0
    L7_2 = L3_2
    L6_2 = L3_2.SetTranslucency
    L9_2 = L3_2
    L8_2 = L3_2.GetTranslucency
    L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L8_2(L9_2)
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
    L7_2 = L3_2
    L6_2 = L3_2.AnimateToPoint
    L8_2 = L3_2.CustomData
    L8_2 = L8_2.tSlotPoints
    L9_2 = _knNumSlots
    L9_2 = L9_2 + 1
    L8_2 = L8_2[L9_2]
    L9_2 = 0.25
    L10_2 = true
    L11_2 = L3_2.SetVisible
    L12_2 = {}
    L13_2 = false
    L12_2[1] = L13_2
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
    L7_2 = L3_2
    L6_2 = L3_2.StopTimer
    L6_2(L7_2)
    L7_2 = L3_2
    L6_2 = L3_2.StopPursuit
    L6_2(L7_2)
  end
end

HideGauge = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
end

ModifyFactionMood = L0_1

function L0_1(A0_2, A1_2)
end

ShowAll = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  if not A1_2 then
    A1_2 = 0
  end
  L2_2 = A0_2.CustomData
  L3_2 = pairs
  L4_2 = L2_2.tSlotLife
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    if 0 < L7_2 then
      L8_2 = L2_2.tSlotLife
      L9_2 = L7_2 - A1_2
      L8_2[L6_2] = L9_2
      L8_2 = L2_2.tSlotLife
      L8_2 = L8_2[L6_2]
      if L8_2 <= 0 then
        L8_2 = L2_2.tSlotOccupants
        L8_2 = L8_2[L6_2]
        L10_2 = L8_2
        L9_2 = L8_2.IsPursuitActive
        L9_2 = L9_2(L10_2)
        if L9_2 then
          L10_2 = L8_2
          L9_2 = L8_2.SetVisible
          L11_2 = true
          L12_2 = false
          L13_2 = true
          L9_2(L10_2, L11_2, L12_2, L13_2)
          L9_2 = L2_2.tSlotLife
          L11_2 = L8_2
          L10_2 = L8_2.GetRemainingPursuitTime
          L10_2 = L10_2(L11_2)
          L10_2 = L10_2 + 2
          L9_2[L6_2] = L10_2
        else
          L10_2 = L8_2
          L9_2 = L8_2.SetTranslucency
          L12_2 = L8_2
          L11_2 = L8_2.GetTranslucency
          L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L11_2(L12_2)
          L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
          L10_2 = L8_2
          L9_2 = L8_2.AnimateToPoint
          L11_2 = L8_2.CustomData
          L11_2 = L11_2.tSlotPoints
          L12_2 = _knNumSlots
          L12_2 = L12_2 + 1
          L11_2 = L11_2[L12_2]
          L12_2 = 0.25
          L13_2 = true
          L14_2 = L8_2.SetVisible
          L15_2 = {}
          L16_2 = false
          L15_2[1] = L16_2
          L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
          L9_2 = L8_2.CustomData
          L9_2 = L9_2.bForceIcon
          if L9_2 then
            L10_2 = L8_2
            L9_2 = L8_2.SetIconVisible
            L11_2 = true
            L12_2 = 255
            L9_2(L10_2, L11_2, L12_2)
          end
          L9_2 = L2_2.tSlotOccupants
          L9_2[L6_2] = nil
        end
      end
    end
  end
  L3_2 = L2_2.bTrayDisabled
  if L3_2 then
    L3_2 = _IsBufferEmpty
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L3_2 = MrxGui
      L3_2 = L3_2.GetWidgetByNameAndOwner
      L4_2 = "Objective Tray"
      L6_2 = A0_2
      L5_2 = A0_2.GetOwner
      L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L5_2(L6_2)
      L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
      if L3_2 then
        L5_2 = L3_2
        L4_2 = L3_2.SetVisible
        L6_2 = true
        L4_2(L5_2, L6_2)
        L2_2.bTrayDisabled = false
      end
    end
  end
end

_Update = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = A0_2.CustomData
  L3_2 = L2_2.tFactionGauges
  L3_2 = L3_2[A1_2]
  if not L3_2 then
    return
  end
  L4_2 = nil
  L5_2 = false
  L6_2 = 1
  while true do
    L7_2 = _knNumSlots
    if not (L6_2 <= L7_2) then
      break
    end
    L7_2 = L2_2.tSlotOccupants
    L7_2 = L7_2[L6_2]
    if L3_2 == L7_2 then
      L4_2 = L6_2
      L5_2 = true
    end
    if not L5_2 and not L4_2 and not L7_2 then
      L4_2 = L6_2
    end
    L6_2 = L6_2 + 1
  end
  if not L4_2 then
    L7_2 = 99999
    L8_2 = pairs
    L9_2 = L2_2.tSlotLife
    L8_2, L9_2, L10_2 = L8_2(L9_2)
    for L11_2, L12_2 in L8_2, L9_2, L10_2 do
      if L12_2 < L7_2 then
        L7_2 = L12_2
        L4_2 = L11_2
      end
    end
  end
  L7_2 = L4_2
  L8_2 = L5_2
  return L7_2, L8_2
end

_FindSlot = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = pairs
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.tSlotOccupants
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    if L5_2 then
      L6_2 = false
      return L6_2
    end
  end
  L1_2 = true
  return L1_2
end

_IsBufferEmpty = L0_1
