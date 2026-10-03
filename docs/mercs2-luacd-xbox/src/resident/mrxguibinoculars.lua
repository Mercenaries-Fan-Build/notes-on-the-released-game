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
  if not L2_2 then
    L2_2 = MrxSound
    L2_2 = L2_2.EnterScopeView
    L2_2()
    L3_2 = A0_2
    L2_2 = A0_2.SetVisible
    L4_2 = true
    L2_2(L3_2, L4_2)
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
      L2_2 = L2_2.oDescription
      L3_2 = L2_2
      L2_2 = L2_2.SetVisible
      L4_2 = false
      L2_2(L3_2, L4_2)
      L2_2 = A0_2.CustomData
      L2_2 = L2_2.oReticle
      L4_2 = L2_2
      L3_2 = L2_2.AnimateToPoint
      L5_2 = L2_2.CustomData
      L5_2 = L5_2.nEndPoint
      L6_2 = _nIntroZoomTime
      L6_2 = L6_2 * 0.5
      L7_2 = true
      L3_2(L4_2, L5_2, L6_2, L7_2)
    else
      L2_2 = _FinishEnter
      L3_2 = A0_2
      L2_2(L3_2)
    end
  end
end

HandleBinocularsEnter = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
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
  L2_2 = L2_2.oFocusText
  L3_2 = L2_2
  L2_2 = L2_2.SetVisible
  L4_2 = true
  L2_2(L3_2, L4_2)
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
  L2_2 = L2_2.oDescription
  L3_2 = L2_2
  L2_2 = L2_2.SetVisible
  L4_2 = true
  L2_2(L3_2, L4_2)
end

_FinishEnter = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = A0_2
  L2_2 = A0_2.GetOwner
  L2_2 = L2_2(L3_2)
  L3_2 = A1_2.uPlayerGuid
  if L2_2 ~= L3_2 then
    return
  end
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
  L3_2 = L3_2.bOn
  if L3_2 then
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
      L3_2 = L3_2.oFaction
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
      L4_2 = A0_2
      L3_2 = A0_2.AnimateToPoint
      L5_2 = A0_2.CustomData
      L5_2 = L5_2.nBigPoint
      L6_2 = _nIntroZoomTime
      L7_2 = true
      L8_2 = _FinishExit
      L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.oReticle
      L5_2 = L3_2
      L4_2 = L3_2.AnimateToPoint
      L6_2 = L3_2.CustomData
      L6_2 = L6_2.nFadePoint
      L7_2 = _nIntroZoomTime
      L7_2 = L7_2 * 0.9
      L8_2 = true
      L9_2 = L3_2.SetVisible
      L10_2 = {}
      L11_2 = false
      L10_2[1] = L11_2
      L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
    else
      L3_2 = _FinishExit
      L4_2 = A0_2
      L3_2(L4_2)
    end
  end
end

HandleBinocularsExit = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
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
  end
  L1_2 = A0_2.CustomData
  L1_2.bHaveHudState = false
  L1_2 = A0_2.CustomData
  L1_2.bOn = false
  L1_2 = MrxSound
  L1_2 = L1_2.ExitScopeView
  L1_2()
end

_FinishExit = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2
  L2_2 = A0_2
  L1_2 = A0_2.SetVisible
  L3_2 = false
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L8_2 = L6_2
    L7_2 = L6_2.SetEnabled
    L9_2 = false
    L7_2(L8_2, L9_2)
  end
  L2_2 = L1_2[2]
  L3_2 = L1_2[3]
  L4_2 = L1_2[7]
  L5_2 = L1_2[8]
  L6_2 = A0_2.CustomData
  L6_2.oReticle = L2_2
  L6_2 = A0_2.CustomData
  L6_2.oFocusText = L3_2
  L6_2 = A0_2.CustomData
  L6_2.oFaction = L4_2
  L6_2 = A0_2.CustomData
  L6_2.oDescription = L5_2
  L6_2 = A0_2.CustomData
  L6_2.bHudState = true
  L7_2 = L5_2
  L6_2 = L5_2.Wrap
  L6_2(L7_2)
  L6_2 = L3_2.CustomData
  L6_2.oDescription = L5_2
  L6_2 = _GuiInternal
  L6_2 = L6_2.SetWidgetUseNewRescale
  if L6_2 then
    L7_2 = L3_2
    L6_2 = L3_2.GetLocation
    L6_2, L7_2, L8_2, L9_2 = L6_2(L7_2)
    L10_2 = A0_2.CustomData
    L10_2.nTextX1 = L6_2
    L10_2 = A0_2.CustomData
    L10_2.nTextY1 = L7_2
    L10_2 = A0_2.CustomData
    L10_2.nTextX2 = L8_2
    L10_2 = A0_2.CustomData
    L10_2.nTextY2 = L9_2
    L11_2 = L5_2
    L10_2 = L5_2.GetLocation
    L10_2, L11_2, L12_2, L13_2 = L10_2(L11_2)
    L14_2 = A0_2.CustomData
    L14_2.nDescX1 = L10_2
    L14_2 = A0_2.CustomData
    L14_2.nDescY1 = L11_2
    L14_2 = A0_2.CustomData
    L14_2.nDescX2 = L12_2
    L14_2 = A0_2.CustomData
    L14_2.nDescY2 = L13_2
    L15_2 = A0_2
    L14_2 = A0_2.GetLocation
    L14_2, L15_2, L16_2, L17_2 = L14_2(L15_2)
    L18_2 = L16_2 - L14_2
    L19_2 = _nIntroZoomScale
    L18_2 = L18_2 * L19_2
    L18_2 = L18_2 * 0.5
    L19_2 = L17_2 - L15_2
    L20_2 = _nIntroZoomScale
    L19_2 = L19_2 * L20_2
    L19_2 = L19_2 * 0.5
    L20_2 = A0_2.CustomData
    L22_2 = A0_2
    L21_2 = A0_2.AddAnimationPoint
    L23_2 = {}
    L24_2 = 320 - L18_2
    L23_2.x = L24_2
    L24_2 = 240 - L19_2
    L23_2.y = L24_2
    L24_2 = 320 + L18_2
    L23_2.x2 = L24_2
    L24_2 = 240 + L19_2
    L23_2.y2 = L24_2
    L21_2 = L21_2(L22_2, L23_2)
    L20_2.nBigPoint = L21_2
    L20_2 = A0_2.CustomData
    L22_2 = A0_2
    L21_2 = A0_2.AddAnimationPoint
    L23_2 = {}
    L23_2.x = L14_2
    L23_2.y = L15_2
    L23_2.x2 = L16_2
    L23_2.y2 = L17_2
    L21_2 = L21_2(L22_2, L23_2)
    L20_2.nEndPoint = L21_2
    L20_2 = A0_2.CustomData
    L20_2.bUsingZoom = true
    L20_2 = _GuiInternal
    L20_2 = L20_2.SetWidgetUseNewRescale
    L21_2 = A0_2.BasicData
    L21_2 = L21_2.uId
    L22_2 = true
    L20_2(L21_2, L22_2)
    L21_2 = A0_2
    L20_2 = A0_2.AnimateToPoint
    L22_2 = A0_2.CustomData
    L22_2 = L22_2.nBigPoint
    L23_2 = 0
    L24_2 = true
    L20_2(L21_2, L22_2, L23_2, L24_2)
    L20_2 = L2_2.CustomData
    L22_2 = L2_2
    L21_2 = L2_2.AddAnimationPoint
    L23_2 = {}
    L23_2.TranslucencyLevel = 0
    L21_2 = L21_2(L22_2, L23_2)
    L20_2.nFadePoint = L21_2
    L20_2 = L2_2.CustomData
    L22_2 = L2_2
    L21_2 = L2_2.AddAnimationPoint
    L23_2 = {}
    L23_2.TranslucencyLevel = 255
    L21_2 = L21_2(L22_2, L23_2)
    L20_2.nEndPoint = L21_2
    L21_2 = L2_2
    L20_2 = L2_2.AnimateToPoint
    L22_2 = nFadePoint
    L23_2 = 0
    L24_2 = true
    L20_2(L21_2, L22_2, L23_2, L24_2)
  end
end

HandleInitialization = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
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
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oPointer
  if not L3_2 then
    L4_2 = A0_2
    L3_2 = A0_2.GetLocation
    L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
    L8_2 = A0_2
    L7_2 = A0_2.GetChildren
    L7_2 = L7_2(L8_2)
    L7_2 = L7_2[1]
    L9_2 = L7_2
    L8_2 = L7_2.GetLocation
    L8_2, L9_2, L10_2, L11_2 = L8_2(L9_2)
    L12_2 = L10_2 - L8_2
    L12_2 = L12_2 * 0.5
    L13_2 = L5_2 + L3_2
    L13_2 = L13_2 * 0.5
    L14_2 = L5_2 - L3_2
    L15_2 = A0_2.CustomData
    L15_2.oPointer = L7_2
    L15_2 = A0_2.CustomData
    L15_2.nMaxDistance = L14_2
    L15_2 = A0_2.CustomData
    L15_2.nCenter = L13_2
    L15_2 = A0_2.CustomData
    L15_2.nPointerSize = L12_2
    L15_2 = A0_2.CustomData
    L15_2.nPointerY = L9_2
  end
  L3_2 = L2_2 / 360
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nMaxDistance
  L3_2 = L3_2 * L4_2
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nCenter
  L3_2 = L3_2 + L4_2
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oPointer
  L5_2 = L4_2
  L4_2 = L4_2.SetLocation
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.nPointerSize
  L6_2 = L3_2 - L6_2
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.nPointerY
  L4_2(L5_2, L6_2, L7_2)
end

HandleHeadingUpdate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L3_2 = A0_2
  L2_2 = A0_2.GetOwner
  L2_2 = L2_2(L3_2)
  L3_2 = A1_2.uPlayerGuid
  if L2_2 ~= L3_2 then
    return
  end
  L2_2 = tonumber
  L3_2 = A1_2.nZoomLevel
  L2_2 = L2_2(L3_2)
  L3_2 = type
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if "number" ~= L3_2 then
    return
  end
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oPointer
  if not L3_2 then
    L4_2 = A0_2
    L3_2 = A0_2.GetLocation
    L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
    L8_2 = A0_2
    L7_2 = A0_2.GetChildren
    L7_2 = L7_2(L8_2)
    L7_2 = L7_2[1]
    L9_2 = L7_2
    L8_2 = L7_2.GetLocation
    L8_2, L9_2, L10_2, L11_2 = L8_2(L9_2)
    L12_2 = L11_2 - L9_2
    L12_2 = L12_2 * 0.5
    L13_2 = L6_2 + L4_2
    L13_2 = L13_2 * 0.5
    L14_2 = L6_2 - L4_2
    L15_2 = A0_2.CustomData
    L15_2.oPointer = L7_2
    L15_2 = A0_2.CustomData
    L15_2.nMaxDistance = L14_2
    L15_2 = A0_2.CustomData
    L15_2.nCenter = L13_2
    L15_2 = A0_2.CustomData
    L15_2.nPointerSize = L12_2
    L15_2 = A0_2.CustomData
    L15_2.nPointerX = L8_2
  end
  L3_2 = L2_2 - 4
  L3_2 = L3_2 / -6
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nMaxDistance
  L3_2 = L3_2 * L4_2
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nCenter
  L3_2 = L3_2 + L4_2
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oPointer
  L5_2 = L4_2
  L4_2 = L4_2.SetLocation
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.nPointerX
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.nPointerSize
  L7_2 = L3_2 - L7_2
  L4_2(L5_2, L6_2, L7_2)
end

HandleZoomUpdate = L0_1

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
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L3_2 = A0_2
  L2_2 = A0_2.GetOwner
  L2_2 = L2_2(L3_2)
  L3_2 = A1_2.uPlayerGuid
  if L2_2 ~= L3_2 then
    return
  end
  L2_2 = type
  L3_2 = A1_2.sFocusName
  L2_2 = L2_2(L3_2)
  if "string" ~= L2_2 then
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
      L4_2.bSniper = false
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
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
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
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oPointer
  if not L3_2 then
    L4_2 = A0_2
    L3_2 = A0_2.GetLocation
    L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
    L8_2 = A0_2
    L7_2 = A0_2.GetChildren
    L7_2 = L7_2(L8_2)
    L7_2 = L7_2[1]
    L9_2 = L7_2
    L8_2 = L7_2.GetLocation
    L8_2, L9_2, L10_2, L11_2 = L8_2(L9_2)
    L12_2 = L11_2 - L9_2
    L12_2 = L12_2 * 0.5
    L13_2 = L6_2 + L4_2
    L13_2 = L13_2 * 0.5
    L14_2 = L6_2 - L4_2
    L15_2 = A0_2.CustomData
    L15_2.oPointer = L7_2
    L15_2 = A0_2.CustomData
    L15_2.nMaxDistance = L14_2
    L15_2 = A0_2.CustomData
    L15_2.nCenter = L13_2
    L15_2 = A0_2.CustomData
    L15_2.nPointerSize = L12_2
    L15_2 = A0_2.CustomData
    L15_2.nPointerX = L8_2
  end
  L3_2 = A1_2.nPitch
  L3_2 = L3_2 - 6
  L3_2 = L3_2 / 100
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nMaxDistance
  L3_2 = L3_2 * L4_2
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nCenter
  L3_2 = L3_2 + L4_2
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oPointer
  L5_2 = L4_2
  L4_2 = L4_2.SetLocation
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.nPointerX
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.nPointerSize
  L7_2 = L3_2 - L7_2
  L4_2(L5_2, L6_2, L7_2)
end

HandleVertScrollUpdate = L0_1
