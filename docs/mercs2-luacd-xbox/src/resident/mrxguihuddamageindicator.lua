local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.bInitialized
  if not L3_2 then
    L3_2 = A0_2.CustomData
    L3_2.bInitialized = true
    L3_2 = A0_2.ParentWidget
    L4_2 = MrxGui
    L4_2 = L4_2.GetWidgetByNameAndOwner
    L5_2 = "reticle"
    L7_2 = A0_2
    L6_2 = A0_2.GetOwner
    L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2 = L6_2(L7_2)
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
    if L4_2 and L3_2 then
      L6_2 = L4_2
      L5_2 = L4_2.GetLocation
      L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
      L9_2 = L5_2 + L7_2
      L9_2 = L9_2 * 0.5
      L10_2 = L6_2 + L8_2
      L10_2 = L10_2 * 0.5
      L12_2 = L3_2
      L11_2 = L3_2.GetLocation
      L11_2, L12_2, L13_2, L14_2 = L11_2(L12_2)
      L15_2 = L13_2 - L11_2
      L16_2 = L14_2 - L12_2
      L18_2 = L3_2
      L17_2 = L3_2.SetLocation
      L19_2 = L15_2 * 0.5
      L19_2 = L9_2 - L19_2
      L20_2 = L16_2 * 0.5
      L20_2 = L10_2 - L20_2
      L17_2(L18_2, L19_2, L20_2)
    end
  end
  if not A2_2 then
    A2_2 = 20
  end
  if A2_2 <= 0 then
    return
  end
  L4_2 = A0_2
  L3_2 = A0_2.GetOwner
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L4_2 = Player
    L4_2 = L4_2.GetControlledObject
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      L5_2 = Object
      L5_2 = L5_2.GetMaxHealth
      L6_2 = L4_2
      L5_2 = L5_2(L6_2)
      if L5_2 then
        L6_2 = A2_2 * 100
        A2_2 = L6_2 / L5_2
      end
    end
  end
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nDamageAmount
  if not L4_2 then
    L4_2 = A0_2.CustomData
    L4_2.nDamageAmount = 0
  end
  L4_2 = MrxGui
  L4_2 = L4_2.ImageWidget
  L5_2 = L4_2
  L4_2 = L4_2.new
  L4_2 = L4_2(L5_2)
  L6_2 = A0_2
  L5_2 = A0_2.GetLocation
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  L10_2 = L4_2
  L9_2 = L4_2.SetTexture
  L12_2 = A0_2
  L11_2 = A0_2.GetTexture
  L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2 = L11_2(L12_2)
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
  L9_2 = L4_2.CustomData
  L9_2.nDamageDirection = A1_2
  L4_2.ParentWidget = A0_2
  L10_2 = L4_2
  L9_2 = L4_2.SetOwner
  L12_2 = A0_2
  L11_2 = A0_2.GetOwner
  L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2 = L11_2(L12_2)
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
  L10_2 = L4_2
  L9_2 = L4_2.SetEventHandler
  L11_2 = "GuiUpdate"
  L12_2 = HandleUpdateEvent
  L9_2(L10_2, L11_2, L12_2)
  L9_2 = Player
  L9_2 = L9_2.GetCameraXZHeading
  L11_2 = A0_2
  L10_2 = A0_2.GetOwner
  L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2 = L10_2(L11_2)
  L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
  L11_2 = L4_2
  L10_2 = L4_2.SetRotation
  L12_2 = L4_2.CustomData
  L12_2 = L12_2.nDamageDirection
  L12_2 = L9_2 - L12_2
  L10_2(L11_2, L12_2)
  L11_2 = L4_2
  L10_2 = L4_2.SetLocation
  L12_2 = L5_2
  L13_2 = L6_2
  L14_2 = L7_2
  L15_2 = L8_2
  L10_2(L11_2, L12_2, L13_2, L14_2, L15_2)
  L11_2 = L4_2
  L10_2 = L4_2.SetAnchoring
  L12_2 = "center"
  L13_2 = "center"
  L10_2(L11_2, L12_2, L13_2)
  L11_2 = L4_2
  L10_2 = L4_2.SetTranslucency
  L12_2 = math
  L12_2 = L12_2.min
  L13_2 = math
  L13_2 = L13_2.pow
  L14_2 = A2_2
  L15_2 = 0.5
  L13_2 = L13_2(L14_2, L15_2)
  L13_2 = L13_2 * 100
  L14_2 = 255
  L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2 = L12_2(L13_2, L14_2)
  L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
  L10_2 = MrxGui
  L10_2 = L10_2.AddWidget
  L11_2 = L4_2
  L10_2(L11_2)
end

HandleReceiveDamageEvent = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.CustomData
  L1_2.nDamageAmount = 0
  L2_2 = A0_2
  L1_2 = A0_2.SetVisible
  L3_2 = false
  L1_2(L2_2, L3_2)
end

_Finish = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = Player
  L2_2 = L2_2.GetCameraXZHeading
  L4_2 = A0_2
  L3_2 = A0_2.GetOwner
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L4_2 = A0_2
  L3_2 = A0_2.SetRotation
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nDamageDirection
  L5_2 = L5_2 + L2_2
  L3_2(L4_2, L5_2)
  L4_2 = A0_2
  L3_2 = A0_2.GetTranslucency
  L3_2 = L3_2(L4_2)
  L4_2 = 100 * A1_2
  L3_2 = L3_2 - L4_2
  if 0 < L3_2 then
    L5_2 = A0_2
    L4_2 = A0_2.SetTranslucency
    L6_2 = L3_2
    L4_2(L5_2, L6_2)
  else
    L4_2 = DeleteDamageIndicatorCallback
    L5_2 = A0_2
    L4_2(L5_2)
  end
end

HandleUpdateEvent = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxGui
  L1_2 = L1_2.RemoveWidget
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.delete
  L1_2(L2_2)
end

DeleteDamageIndicatorCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A1_2.bOn
  if L2_2 then
    L2_2 = A0_2.EventHandlers
    L2_2 = L2_2.GuiPlayerReceiveDamage
    if L2_2 then
      L3_2 = A0_2
      L2_2 = A0_2.SetEventHandler
      L4_2 = "GuiPlayerReceiveDamage"
      L5_2 = nil
      L2_2(L3_2, L4_2, L5_2)
    end
  else
    L2_2 = A0_2.EventHandlers
    L2_2 = L2_2.GuiPlayerReceiveDamage
    if not L2_2 then
      L3_2 = A0_2
      L2_2 = A0_2.SetEventHandler
      L4_2 = "GuiPlayerReceiveDamage"
      L5_2 = HandleReceiveDamageEvent
      L2_2(L3_2, L4_2, L5_2)
    end
  end
end

HandleE3HudModeEvent = L0_1
