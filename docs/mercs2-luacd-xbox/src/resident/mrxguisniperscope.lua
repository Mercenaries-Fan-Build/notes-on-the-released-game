local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGuiManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSound"
L0_1(L1_1)
L0_1 = 3
_nIntroZoomScale = L0_1
L0_1 = 0.25
_nIntroZoomTime = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = A0_2
  L2_2 = A0_2.GetOwner
  L2_2 = L2_2(L3_2)
  L3_2 = A1_2.uPlayerGuid
  if L2_2 ~= L3_2 then
    return
  end
  L2_2 = A1_2.bSniper
  if L2_2 then
    L2_2 = MrxSound
    L2_2 = L2_2.EnterScopeView
    L2_2()
    L3_2 = A0_2
    L2_2 = A0_2.SetVisible
    L4_2 = true
    L2_2(L3_2, L4_2)
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.bNeedsPush
    if L2_2 then
      L2_2 = MrxGui
      L2_2 = L2_2.PushWidgetToBack
      L3_2 = A0_2
      L2_2(L3_2)
      L2_2 = MrxGui
      L2_2 = L2_2.PushWidgetToFront
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.oFocusText
      L2_2(L3_2)
      L2_2 = MrxGui
      L2_2 = L2_2.PushWidgetToFront
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.oFaction
      L2_2(L3_2)
      L2_2 = MrxGui
      L2_2 = L2_2.PushWidgetToFront
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.oDescription
      L2_2(L3_2)
      L2_2 = MrxGui
      L2_2 = L2_2.PushWidgetToFront
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.oHealth
      L2_2(L3_2)
      L2_2 = A0_2.CustomData
      L2_2.bNeedsPush = nil
    end
    L2_2 = A0_2.CustomData
    L2_2.bOn = true
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.bUsingZoom
    if L2_2 then
      L3_2 = A0_2
      L2_2 = A0_2.AnimateToPoint
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.nEndPoint
      L5_2 = _nIntroZoomTime
      L6_2 = true
      L7_2 = _FinishEnter
      L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
      L2_2 = A0_2.CustomData
      L2_2 = L2_2.oFocusText
      L3_2 = L2_2
      L2_2 = L2_2.SetVisible
      L4_2 = false
      L2_2(L3_2, L4_2)
      L2_2 = A0_2.CustomData
      L2_2 = L2_2.oDescription
      L3_2 = L2_2
      L2_2 = L2_2.SetVisible
      L4_2 = false
      L2_2(L3_2, L4_2)
      L2_2 = A0_2.CustomData
      L2_2 = L2_2.oHealth
      L3_2 = L2_2
      L2_2 = L2_2.SetVisible
      L4_2 = false
      L2_2(L3_2, L4_2)
      L2_2 = A0_2.CustomData
      L2_2 = L2_2.oFocusText
      L3_2 = L2_2
      L2_2 = L2_2.SetEnabled
      L4_2 = true
      L2_2(L3_2, L4_2)
      L2_2 = A0_2.CustomData
      L2_2 = L2_2.oFaction
      L3_2 = L2_2
      L2_2 = L2_2.SetEnabled
      L4_2 = true
      L2_2(L3_2, L4_2)
      L2_2 = A0_2.CustomData
      L2_2 = L2_2.oHealth
      L3_2 = L2_2
      L2_2 = L2_2.SetEnabled
      L4_2 = false
      L2_2(L3_2, L4_2)
    else
      L2_2 = _FinishEnter
      L3_2 = A0_2
      L2_2(L3_2)
    end
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.bHaveHudState
    if not L2_2 then
      L2_2 = MrxGuiManager
      L2_2 = L2_2.GetHudState
      L4_2 = A0_2
      L3_2 = A0_2.GetOwner
      L3_2, L4_2, L5_2, L6_2, L7_2 = L3_2(L4_2)
      L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
      L3_2 = A0_2.CustomData
      L3_2.bHudState = L2_2
      if L2_2 then
        L3_2 = MrxGuiManager
        L3_2 = L3_2.ToggleHud
        L5_2 = A0_2
        L4_2 = A0_2.GetOwner
        L4_2 = L4_2(L5_2)
        L5_2 = false
        L6_2 = "scope"
        L3_2(L4_2, L5_2, L6_2)
      end
      L3_2 = A0_2.CustomData
      L3_2.bHaveHudState = true
      L3_2 = MrxGui
      L3_2 = L3_2.GetWidgetByNameAndOwner
      L4_2 = "Guns"
      L6_2 = A0_2
      L5_2 = A0_2.GetOwner
      L5_2, L6_2, L7_2 = L5_2(L6_2)
      L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
      L4_2 = _RecursiveWakeup
      L5_2 = L3_2
      L6_2 = true
      L4_2(L5_2, L6_2)
      L4_2 = MrxGui
      L4_2 = L4_2.GetWidgetByNameAndOwner
      L5_2 = "Health Counter"
      L7_2 = A0_2
      L6_2 = A0_2.GetOwner
      L6_2, L7_2 = L6_2(L7_2)
      L4_2 = L4_2(L5_2, L6_2, L7_2)
      L5_2 = _RecursiveWakeup
      L6_2 = L4_2
      L7_2 = true
      L5_2(L6_2, L7_2)
    end
  end
end

HandleSniperScopeEnter = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L8_2 = L6_2
    L7_2 = L6_2.SetEnabled
    L9_2 = true
    L7_2(L8_2, L9_2)
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oFocusText
  L3_2 = L2_2
  L2_2 = L2_2.SetLocation
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nTextX1
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nTextY1
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.nTextX2
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.nTextY2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oDescription
  L3_2 = L2_2
  L2_2 = L2_2.SetLocation
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nDescX1
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nDescY1
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.nDescX2
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.nDescY2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oFocusText
  L3_2 = L2_2
  L2_2 = L2_2.SetVisible
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oDescription
  L3_2 = L2_2
  L2_2 = L2_2.SetVisible
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oHealth
  L3_2 = L2_2
  L2_2 = L2_2.SetVisible
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = Player
  L2_2 = L2_2.GetTargetUnderReticle
  L4_2 = A0_2
  L3_2 = A0_2.GetOwner
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L3_2(L4_2)
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
  if L5_2 then
    L6_2 = Object
    L6_2 = L6_2.GetHealth
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    if not L6_2 then
      L6_2 = -1
    end
    L7_2 = Object
    L7_2 = L7_2.GetMaxHealth
    L8_2 = L5_2
    L7_2 = L7_2(L8_2)
    if not L7_2 then
      L7_2 = -1
    end
    L8_2 = HandleSniperHealthUpdate
    L9_2 = A0_2.CustomData
    L9_2 = L9_2.oHealth
    L10_2 = nil
    L11_2 = nil
    L12_2 = nil
    L13_2 = nil
    L14_2 = nil
    L15_2 = L6_2
    L16_2 = L7_2
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
  else
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.oHealth
    L7_2 = L6_2
    L6_2 = L6_2.SetVisible
    L8_2 = false
    L6_2(L7_2, L8_2)
  end
end

_FinishEnter = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = A0_2
  L2_2 = A0_2.GetOwner
  L2_2 = L2_2(L3_2)
  L3_2 = A1_2.uPlayerGuid
  if L2_2 ~= L3_2 then
    return
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bOn
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.GetChildren
    L2_2 = L2_2(L3_2)
    L3_2 = pairs
    L4_2 = L2_2
    L3_2, L4_2, L5_2 = L3_2(L4_2)
    for L6_2, L7_2 in L3_2, L4_2, L5_2 do
      L9_2 = L7_2
      L8_2 = L7_2.SetEnabled
      L10_2 = false
      L8_2(L9_2, L10_2)
    end
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.bUsingZoom
    if L3_2 then
      L3_2 = A0_2.CustomData
      L3_2.bOn = false
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.oFocusText
      L4_2 = L3_2
      L3_2 = L3_2.SetVisible
      L5_2 = false
      L3_2(L4_2, L5_2)
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.oDescription
      L4_2 = L3_2
      L3_2 = L3_2.SetVisible
      L5_2 = false
      L3_2(L4_2, L5_2)
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.oHealth
      L4_2 = L3_2
      L3_2 = L3_2.SetVisible
      L5_2 = false
      L3_2(L4_2, L5_2)
      L4_2 = A0_2
      L3_2 = A0_2.AnimateToPoint
      L5_2 = A0_2.CustomData
      L5_2 = L5_2.nBigPoint
      L6_2 = _nIntroZoomTime
      L7_2 = true
      L8_2 = _FinishExit
      L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
    else
      L3_2 = _FinishExit
      L4_2 = A0_2
      L3_2(L4_2)
    end
  end
end

HandleSniperScopeExit = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2
  L1_2 = A0_2.SetVisible
  L3_2 = false
  L1_2(L2_2, L3_2)
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bHudState
  if L1_2 then
    L1_2 = MrxGuiManager
    L1_2 = L1_2.ToggleHud
    L3_2 = A0_2
    L2_2 = A0_2.GetOwner
    L2_2 = L2_2(L3_2)
    L3_2 = true
    L1_2(L2_2, L3_2)
  else
    L1_2 = MrxGui
    L1_2 = L1_2.GetWidgetByNameAndOwner
    L2_2 = "Guns"
    L4_2 = A0_2
    L3_2 = A0_2.GetOwner
    L3_2, L4_2, L5_2 = L3_2(L4_2)
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
    L2_2 = _RecursiveWakeup
    L3_2 = L1_2
    L4_2 = false
    L2_2(L3_2, L4_2)
    L2_2 = MrxGui
    L2_2 = L2_2.GetWidgetByNameAndOwner
    L3_2 = "Health Counter"
    L5_2 = A0_2
    L4_2 = A0_2.GetOwner
    L4_2, L5_2 = L4_2(L5_2)
    L2_2 = L2_2(L3_2, L4_2, L5_2)
    L3_2 = _RecursiveWakeup
    L4_2 = L2_2
    L5_2 = false
    L3_2(L4_2, L5_2)
  end
  L1_2 = A0_2.CustomData
  L1_2.bOn = false
  L1_2 = A0_2.CustomData
  L1_2.bHaveHudState = false
  L1_2 = MrxSound
  L1_2 = L1_2.ExitScopeView
  L1_2()
end

_FinishExit = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2
  L3_2 = A0_2
  L2_2 = A0_2.SetVisible
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = A0_2.CustomData
  L2_2.bNeedsPush = true
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.SetEnabled
    L10_2 = false
    L8_2(L9_2, L10_2)
  end
  L3_2 = L2_2[3]
  L4_2 = L2_2[5]
  L5_2 = A0_2.CustomData
  L5_2.oFocusText = L3_2
  L5_2 = A0_2.CustomData
  L6_2 = L2_2[4]
  L5_2.oFaction = L6_2
  L5_2 = A0_2.CustomData
  L5_2.oDescription = L4_2
  L5_2 = A0_2.CustomData
  L6_2 = L2_2[6]
  L5_2.oHealth = L6_2
  L5_2 = L3_2.CustomData
  L5_2.oDescription = L4_2
  L6_2 = L4_2
  L5_2 = L4_2.Wrap
  L5_2(L6_2)
  L5_2 = A0_2.CustomData
  L5_2.bHudState = true
  L5_2 = _GuiInternal
  L5_2 = L5_2.SetWidgetUseNewRescale
  if L5_2 then
    L6_2 = L3_2
    L5_2 = L3_2.GetLocation
    L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
    L9_2 = A0_2.CustomData
    L9_2.nTextX1 = L5_2
    L9_2 = A0_2.CustomData
    L9_2.nTextY1 = L6_2
    L9_2 = A0_2.CustomData
    L9_2.nTextX2 = L7_2
    L9_2 = A0_2.CustomData
    L9_2.nTextY2 = L8_2
    L10_2 = L4_2
    L9_2 = L4_2.GetLocation
    L9_2, L10_2, L11_2, L12_2 = L9_2(L10_2)
    L13_2 = A0_2.CustomData
    L13_2.nDescX1 = L9_2
    L13_2 = A0_2.CustomData
    L13_2.nDescY1 = L10_2
    L13_2 = A0_2.CustomData
    L13_2.nDescX2 = L11_2
    L13_2 = A0_2.CustomData
    L13_2.nDescY2 = L12_2
    L14_2 = A0_2
    L13_2 = A0_2.GetLocation
    L13_2, L14_2, L15_2, L16_2 = L13_2(L14_2)
    L17_2 = L15_2 - L13_2
    L18_2 = _nIntroZoomScale
    L17_2 = L17_2 * L18_2
    L17_2 = L17_2 * 0.5
    L18_2 = L16_2 - L14_2
    L19_2 = _nIntroZoomScale
    L18_2 = L18_2 * L19_2
    L18_2 = L18_2 * 0.5
    L19_2 = A0_2.CustomData
    L21_2 = A0_2
    L20_2 = A0_2.AddAnimationPoint
    L22_2 = {}
    L23_2 = 320 - L17_2
    L22_2.x = L23_2
    L23_2 = 240 - L18_2
    L22_2.y = L23_2
    L23_2 = 320 + L17_2
    L22_2.x2 = L23_2
    L23_2 = 240 + L18_2
    L22_2.y2 = L23_2
    L20_2 = L20_2(L21_2, L22_2)
    L19_2.nBigPoint = L20_2
    L19_2 = A0_2.CustomData
    L21_2 = A0_2
    L20_2 = A0_2.AddAnimationPoint
    L22_2 = {}
    L22_2.x = L13_2
    L22_2.y = L14_2
    L22_2.x2 = L15_2
    L22_2.y2 = L16_2
    L20_2 = L20_2(L21_2, L22_2)
    L19_2.nEndPoint = L20_2
    L19_2 = A0_2.CustomData
    L19_2.bUsingZoom = true
    L19_2 = _GuiInternal
    L19_2 = L19_2.SetWidgetUseNewRescale
    L20_2 = A0_2.BasicData
    L20_2 = L20_2.uId
    L21_2 = true
    L19_2(L20_2, L21_2)
    L20_2 = A0_2
    L19_2 = A0_2.AnimateToPoint
    L21_2 = A0_2.CustomData
    L21_2 = L21_2.nBigPoint
    L22_2 = 0
    L23_2 = true
    L19_2(L20_2, L21_2, L22_2, L23_2)
  end
end

HandleInitialization = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L2_2 = L2_2[1]
  L3_2 = A0_2.CustomData
  L3_2.oBar = L2_2
  L4_2 = L2_2
  L3_2 = L2_2.GetLocation
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  L6_2 = A0_2.CustomData
  L6_2.nX = L3_2
  L6_2 = A0_2.CustomData
  L7_2 = L5_2 - L3_2
  L6_2.nLength = L7_2
end

HandleSniperHealthInit = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2)
  local L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  if 0 <= A6_2 and 0 <= A7_2 then
    L9_2 = A0_2
    L8_2 = A0_2.SetVisible
    L10_2 = true
    L8_2(L9_2, L10_2)
    L8_2 = A0_2.CustomData
    L8_2 = L8_2.oBar
    L9_2 = L8_2
    L8_2 = L8_2.SetLocation
    L10_2 = A0_2.CustomData
    L10_2 = L10_2.nX
    L11_2 = nil
    L12_2 = A0_2.CustomData
    L12_2 = L12_2.nX
    L13_2 = A0_2.CustomData
    L13_2 = L13_2.nLength
    L14_2 = A6_2 / A7_2
    L13_2 = L13_2 * L14_2
    L12_2 = L12_2 + L13_2
    L8_2(L9_2, L10_2, L11_2, L12_2)
  else
    L9_2 = A0_2
    L8_2 = A0_2.SetVisible
    L10_2 = false
    L8_2(L9_2, L10_2)
  end
end

HandleSniperHealthUpdate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L3_2 = A0_2
  L2_2 = A0_2.GetOwner
  L2_2 = L2_2(L3_2)
  L3_2 = A1_2.uPlayerGuid
  if L2_2 ~= L3_2 then
    return
  end
  L2_2 = A1_2.nZoomLevel
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.SetText
    L4_2 = "ZOOM x "
    L5_2 = A1_2.nZoomLevel
    L4_2 = L4_2 .. L5_2
    L2_2(L3_2, L4_2)
  end
end

HandleZoomUpdate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L3_2 = A0_2
  L2_2 = A0_2.GetOwner
  L2_2 = L2_2(L3_2)
  L3_2 = A1_2.uPlayerGuid
  if L2_2 ~= L3_2 then
    return
  end
  L2_2 = A1_2.nCameraHeading
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.SetText
    L4_2 = A1_2.nCameraHeading
    L2_2(L3_2, L4_2)
  end
end

HandleHeadingUpdate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L3_2 = A0_2
  L2_2 = A0_2.GetOwner
  L2_2 = L2_2(L3_2)
  L3_2 = A1_2.uPlayerGuid
  if L2_2 ~= L3_2 then
    return
  end
  L2_2 = A1_2.sFocusName
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.SetText
    L4_2 = A1_2.sFocusName
    L2_2(L3_2, L4_2)
    L2_2 = A1_2.uFocusGuid
    if L2_2 then
      L2_2 = Event
      L2_2 = L2_2.Post
      L3_2 = "InFocus"
      L4_2 = {}
      L5_2 = A1_2.uFocusGuid
      L4_2.uTarget = L5_2
      L6_2 = A0_2
      L5_2 = A0_2.GetOwner
      L5_2 = L5_2(L6_2)
      L4_2.uViewer = L5_2
      L4_2.bSniper = true
      L2_2(L3_2, L4_2)
      L2_2 = A0_2.CustomData
      L2_2 = L2_2.oDescription
      L3_2 = L2_2
      L2_2 = L2_2.SetText
      L4_2 = MrxGui
      L4_2 = L4_2.GetObjectiveDescription
      L5_2 = A1_2.uFocusGuid
      L4_2 = L4_2(L5_2)
      if not L4_2 then
        L4_2 = " "
      end
      L2_2(L3_2, L4_2)
    else
      L2_2 = A0_2.CustomData
      L2_2 = L2_2.oDescription
      L3_2 = L2_2
      L2_2 = L2_2.SetText
      L4_2 = " "
      L2_2(L3_2, L4_2)
    end
  end
end

HandleFocusUpdate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L3_2 = A0_2
  L2_2 = A0_2.GetOwner
  L2_2 = L2_2(L3_2)
  L3_2 = A1_2.uPlayerGuid
  if L2_2 ~= L3_2 then
    return
  end
  L2_2 = type
  L3_2 = A1_2.FactionTexture
  L2_2 = L2_2(L3_2)
  if "userdata" == L2_2 or "string" == L2_2 then
    L4_2 = A0_2
    L3_2 = A0_2.SetTexture
    L5_2 = A1_2.FactionTexture
    L3_2(L4_2, L5_2)
    L4_2 = A0_2
    L3_2 = A0_2.SetTranslucency
    L5_2 = 255
    L3_2(L4_2, L5_2)
  elseif "number" == L2_2 then
    L4_2 = A0_2
    L3_2 = A0_2.SetTranslucency
    L5_2 = 0
    L3_2(L4_2, L5_2)
  end
end

HandleFactionUpdate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = A0_2
  L2_2 = A0_2.GetOwner
  L2_2 = L2_2(L3_2)
  L3_2 = A1_2.uPlayerGuid
  if L2_2 ~= L3_2 then
    return
  end
  L2_2 = tonumber
  L3_2 = A1_2.nCameraHeading
  L2_2 = L2_2(L3_2)
  L3_2 = type
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if "number" ~= L3_2 then
    return
  end
  L3_2 = 180
  while L2_2 < 0 do
    L2_2 = L2_2 + L3_2
  end
  while L3_2 < L2_2 do
    L2_2 = L2_2 - L3_2
  end
  L4_2 = L3_2 * 2
  L2_2 = L2_2 / L4_2
  L5_2 = A0_2
  L4_2 = A0_2.SetTextureCoordinates
  L6_2 = L2_2
  L7_2 = nil
  L8_2 = L2_2 + 0.5
  L9_2 = nil
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
end

HandleHorizScrollUpdate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = A0_2
  L2_2 = A0_2.GetOwner
  L2_2 = L2_2(L3_2)
  L3_2 = A1_2.uPlayerGuid
  if L2_2 ~= L3_2 then
    return
  end
  L2_2 = A1_2.nPitch
  L3_2 = type
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if "number" ~= L3_2 then
    return
  end
  L3_2 = 180
  while L2_2 < 0 do
    L2_2 = L2_2 + L3_2
  end
  while L3_2 < L2_2 do
    L2_2 = L2_2 - L3_2
  end
  L4_2 = L3_2 * 2
  L2_2 = L2_2 / L4_2
  L5_2 = A0_2
  L4_2 = A0_2.SetTextureCoordinates
  L6_2 = nil
  L7_2 = L2_2
  L8_2 = nil
  L9_2 = L2_2 + 0.5
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
end

HandleVertScrollUpdate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = A0_2
  L2_2 = A0_2.SetSleeping
  L4_2 = not A1_2
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = _RecursiveWakeup
    L9_2 = L7_2
    L10_2 = A1_2
    L8_2(L9_2, L10_2)
  end
end

_RecursiveWakeup = L0_1
