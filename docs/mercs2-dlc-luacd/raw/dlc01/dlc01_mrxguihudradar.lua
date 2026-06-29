local L0_1, L1_1, L2_1
L0_1 = import
L1_1 = "MrxGui"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxGuiBase"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxGuiManager"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L2_1 = false
L0_1(L1_1, L2_1)

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2)
  local L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.tRegionGuids
  L7_2 = L7_2[A1_2]
  if not L7_2 then
    L7_2 = 1
    while true do
      L8_2 = A0_2.CustomData
      L8_2 = L8_2.tRegions
      L8_2 = L8_2[L7_2]
      if not L8_2 then
        break
      end
      L7_2 = L7_2 + 1
    end
  else
    L9_2 = A0_2
    L8_2 = A0_2.RemoveRegion
    L10_2 = A1_2
    L8_2(L9_2, L10_2)
  end
  L8_2 = {}
  L8_2.uGuid = A1_2
  L9_2 = A2_2
  L10_2 = A3_2
  L11_2 = A4_2
  L12_2 = A5_2
  L13_2 = _Clamp
  L14_2 = L9_2
  L15_2 = 0
  L16_2 = 255
  L13_2 = L13_2(L14_2, L15_2, L16_2)
  L9_2 = L13_2
  L13_2 = _Clamp
  L14_2 = L10_2
  L15_2 = 0
  L16_2 = 255
  L13_2 = L13_2(L14_2, L15_2, L16_2)
  L10_2 = L13_2
  L13_2 = _Clamp
  L14_2 = L11_2
  L15_2 = 0
  L16_2 = 255
  L13_2 = L13_2(L14_2, L15_2, L16_2)
  L11_2 = L13_2
  L13_2 = _Clamp
  L14_2 = L12_2
  L15_2 = 0
  L16_2 = 255
  L13_2 = L13_2(L14_2, L15_2, L16_2)
  L12_2 = L13_2
  if not L9_2 then
    L9_2 = 64
  end
  if not L10_2 then
    L10_2 = 64
  end
  if not L11_2 then
    L11_2 = 160
  end
  if not L12_2 then
    L12_2 = 128
  end
  L13_2 = L12_2 / 255
  L12_2 = L13_2 * 100
  L13_2 = "0x"
  L14_2 = string
  L14_2 = L14_2.format
  L15_2 = "%02X"
  L16_2 = L9_2
  L14_2 = L14_2(L15_2, L16_2)
  L15_2 = string
  L15_2 = L15_2.format
  L16_2 = "%02X"
  L17_2 = L10_2
  L15_2 = L15_2(L16_2, L17_2)
  L16_2 = string
  L16_2 = L16_2.format
  L17_2 = "%02X"
  L18_2 = L11_2
  L16_2 = L16_2(L17_2, L18_2)
  L13_2 = L13_2 .. L14_2 .. L15_2 .. L16_2
  L8_2.sColor = L13_2
  L8_2.nAlpha = L12_2
  L8_2.bInvert = A6_2
  L13_2 = A0_2.CustomData
  L13_2 = L13_2.tRegions
  L13_2[L7_2] = L8_2
  L13_2 = A0_2.CustomData
  L13_2 = L13_2.tRegionGuids
  L13_2[A1_2] = L7_2
  L13_2 = A0_2.CustomData
  L13_2 = L13_2.bHaveFlash
  if L13_2 then
    L13_2 = _DisplayMinimapRegion
    L14_2 = A0_2
    L15_2 = L7_2
    L13_2(L14_2, L15_2)
  end
end

AddRegionToMinimap = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  if A0_2 then
    L3_2 = type
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
    if "number" == L3_2 then
      goto lbl_9
    end
  end
  do return end
  ::lbl_9::
  if A2_2 < A0_2 then
    return A2_2
  end
  if A0_2 < A1_2 then
    return A1_2
  end
  return A0_2
end

_Clamp = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.tRegionGuids
  L2_2 = L2_2[A1_2]
  if L2_2 then
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.tRegionGuids
    L3_2[L2_2] = nil
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.bHaveFlash
    if L3_2 then
      L4_2 = A0_2
      L3_2 = A0_2.CallActionScriptCallback
      L5_2 = "RemoveZone"
      L6_2 = {}
      L7_2 = L2_2
      L6_2[1] = L7_2
      L3_2(L4_2, L5_2, L6_2)
    end
  end
end

RemoveRegionFromMinimap = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = AddRegionToMinimap
  A0_2.AddRegion = L1_2
  L1_2 = RemoveRegionFromMinimap
  A0_2.RemoveRegion = L1_2
  L1_2 = A0_2.CustomData
  L2_2 = {}
  L1_2.tRegions = L2_2
  L1_2 = A0_2.CustomData
  L2_2 = {}
  L1_2.tRegionGuids = L2_2
  L1_2 = A0_2.CustomData
  L1_2.bHaveFlash = false
  L2_2 = A0_2
  L1_2 = A0_2.SetSwfFile
  L3_2 = "minimap.gfx"
  L4_2 = _FinishInitialization
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = A0_2.ParentWidget
  oParent = L1_2
  L1_2 = oParent
  L2_2 = L1_2
  L1_2 = L1_2.GetChildren
  L1_2 = L1_2(L2_2)
  L1_2 = L1_2[3]
  oRadarObject = L1_2
  L1_2 = oRadarObject
  if L1_2 then
    L1_2 = oRadarObject
    L2_2 = L1_2
    L1_2 = L1_2.SetEventHandler
    L3_2 = "SetTargetMarker"
    L4_2 = HandleSetTargetMarker
    L1_2(L2_2, L3_2, L4_2)
    L1_2 = oRadarObject
    L2_2 = L1_2
    L1_2 = L1_2.SetEventHandler
    L3_2 = "SetGPSDest"
    L4_2 = HandleSetGPSDest
    L1_2(L2_2, L3_2, L4_2)
    L1_2 = oRadarObject
    L2_2 = L1_2
    L1_2 = L1_2.SetEventHandler
    L3_2 = "ClearGPSDest"
    L4_2 = HandleClearGPSDest
    L1_2(L2_2, L3_2, L4_2)
  end
end

_Initialize = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = A0_2.CustomData
  L1_2.bHaveFlash = true
  L1_2 = pairs
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.tRegions
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2 in L1_2, L2_2, L3_2 do
    L5_2 = _DisplayMinimapRegion
    L6_2 = A0_2
    L7_2 = L4_2
    L5_2(L6_2, L7_2)
  end
end

_FinishInitialization = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.tRegions
  L2_2 = L2_2[A1_2]
  if not L2_2 then
    return
  end
  L3_2 = Pg
  L3_2 = L3_2.GetLineRegionPoints
  L4_2 = L2_2.uGuid
  L5_2 = L2_2.bInvert
  L3_2, L4_2 = L3_2(L4_2, L5_2)
  L5_2 = nil
  L6_2 = true
  L7_2 = 35
  L8_2 = 40
  L9_2 = 1
  L10_2 = Gui
  L10_2 = L10_2.GetMapCorrectionOffset
  if L10_2 then
    L10_2 = Gui
    L10_2 = L10_2.GetMapCorrectionOffset
    L10_2, L11_2, L12_2 = L10_2()
    L9_2 = L12_2
    L8_2 = L11_2
    L7_2 = L10_2
  end
  L10_2 = ipairs
  L11_2 = L3_2
  L10_2, L11_2, L12_2 = L10_2(L11_2)
  for L13_2, L14_2 in L10_2, L11_2, L12_2 do
    L5_2 = L4_2[L13_2]
    if L6_2 then
      L16_2 = A0_2
      L15_2 = A0_2.CallActionScriptCallback
      L17_2 = "AddZone"
      L18_2 = {}
      L19_2 = A1_2
      L20_2 = true
      L21_2 = false
      L22_2 = L14_2 + L7_2
      L22_2 = L22_2 * L9_2
      L23_2 = L5_2 + L8_2
      L23_2 = L23_2 * L9_2
      L24_2 = L2_2.sColor
      L25_2 = L2_2.nAlpha
      L18_2[1] = L19_2
      L18_2[2] = L20_2
      L18_2[3] = L21_2
      L18_2[4] = L22_2
      L18_2[5] = L23_2
      L18_2[6] = L24_2
      L18_2[7] = L25_2
      L15_2(L16_2, L17_2, L18_2)
      L6_2 = false
    else
      L16_2 = A0_2
      L15_2 = A0_2.CallActionScriptCallback
      L17_2 = "AddZone"
      L18_2 = {}
      L19_2 = A1_2
      L20_2 = false
      L21_2 = false
      L22_2 = L14_2 + L7_2
      L22_2 = L22_2 * L9_2
      L23_2 = L5_2 + L8_2
      L23_2 = L23_2 * L9_2
      L18_2[1] = L19_2
      L18_2[2] = L20_2
      L18_2[3] = L21_2
      L18_2[4] = L22_2
      L18_2[5] = L23_2
      L15_2(L16_2, L17_2, L18_2)
    end
  end
  L11_2 = A0_2
  L10_2 = A0_2.CallActionScriptCallback
  L12_2 = "AddZone"
  L13_2 = {}
  L14_2 = A1_2
  L15_2 = false
  L16_2 = true
  L17_2 = 0
  L18_2 = 0
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L13_2[3] = L16_2
  L13_2[4] = L17_2
  L13_2[5] = L18_2
  L10_2(L11_2, L12_2, L13_2)
end

_DisplayMinimapRegion = L0_1
L0_1 = "Target marker"
_sTargetName = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L2_2 = A1_2.number
  if L2_2 then
    L2_2 = A1_2.x
    if L2_2 then
      L2_2 = A1_2.y
      if L2_2 then
        L2_2 = A1_2.z
        if L2_2 then
          L2_2 = A1_2.r
          if L2_2 then
            L2_2 = A1_2.g
            if L2_2 then
              L2_2 = A1_2.b
              if L2_2 then
                L2_2 = A1_2.texture
                if L2_2 then
                  L3_2 = A0_2
                  L2_2 = A0_2.AddObjective
                  L4_2 = _sTargetName
                  L5_2 = tostring
                  L6_2 = A1_2.number
                  L5_2 = L5_2(L6_2)
                  L4_2 = L4_2 .. L5_2
                  L5_2 = A1_2.x
                  L6_2 = A1_2.y
                  L7_2 = A1_2.z
                  L8_2 = A1_2.r
                  L9_2 = A1_2.g
                  L10_2 = A1_2.b
                  L11_2 = 6
                  L12_2 = 6
                  L13_2 = A1_2.texture
                  L14_2 = A1_2.uGuid
                  L15_2 = true
                  L16_2 = nil
                  L17_2 = nil
                  L18_2 = 5
                  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
              end
            end
          end
        end
      end
    end
    else
      L3_2 = A0_2
      L2_2 = A0_2.DeleteObjective
      L4_2 = _sTargetName
      L5_2 = tostring
      L6_2 = A1_2.number
      L5_2 = L5_2(L6_2)
      L4_2 = L4_2 .. L5_2
      L2_2(L3_2, L4_2)
    end
  end
end

HandleSetTargetMarker = L0_1
L0_1 = "GPS Beacon Marker"
_sGPSName = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L3_2 = A0_2
  L2_2 = A0_2.AddObjective
  L4_2 = _sGPSName
  L5_2 = A1_2.PosX
  L6_2 = 0
  L7_2 = A1_2.PosZ
  L8_2 = 255
  L9_2 = 255
  L10_2 = 255
  L11_2 = 10.666667
  L12_2 = 10.666667
  L13_2 = "MiniMap_Icon_GPS_Marker"
  L14_2 = nil
  L15_2 = true
  L16_2 = nil
  L17_2 = nil
  L18_2 = 4
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
end

HandleSetGPSDest = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L3_2 = A0_2
  L2_2 = A0_2.DeleteObjective
  L4_2 = _sGPSName
  L2_2(L3_2, L4_2)
end

HandleClearGPSDest = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.bTrespass
  if L4_2 then
    return
  end
  L4_2 = type
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  if "string" ~= L4_2 then
    return
  end
  L4_2 = type
  L5_2 = A2_2
  L4_2 = L4_2(L5_2)
  if "number" ~= L4_2 then
    A2_2 = nil
  end
  A3_2 = false
  if A3_2 then
    L5_2 = A0_2
    L4_2 = A0_2.SetText
    L6_2 = " "
    L4_2(L5_2, L6_2)
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.oFlash
    L5_2 = L4_2.CustomData
    L5_2 = L5_2.bLoaded
    if L5_2 then
      L6_2 = A0_2
      L5_2 = A0_2.SetVisible
      L7_2 = true
      L5_2(L6_2, L7_2)
    end
  else
    L5_2 = A0_2
    L4_2 = A0_2.GetVisible
    L4_2 = L4_2(L5_2)
    if L4_2 then
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.oFlash
      L5_2 = L4_2
      L4_2 = L4_2.SetVisible
      L6_2 = false
      L4_2(L5_2, L6_2)
      L5_2 = A0_2
      L4_2 = A0_2.SetEventHandler
      L6_2 = "GuiUpdate"
      L7_2 = nil
      L4_2(L5_2, L6_2, L7_2)
      L5_2 = A0_2
      L4_2 = A0_2.AnimateToPoint
      L6_2 = A0_2.CustomData
      L6_2 = L6_2.nFadeOutPoint
      L7_2 = 0.4
      L8_2 = true
      L9_2 = _HandleTransition
      L10_2 = {}
      L11_2 = A1_2
      L12_2 = A2_2
      L10_2[1] = L11_2
      L10_2[2] = L12_2
      L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
    end
    L5_2 = A0_2
    L4_2 = A0_2.SetVisible
    L6_2 = true
    L4_2(L5_2, L6_2)
    L5_2 = A0_2
    L4_2 = A0_2.SetText
    L6_2 = A1_2
    L4_2(L5_2, L6_2)
    L5_2 = A0_2
    L4_2 = A0_2.SetTranslucency
    L6_2 = 0
    L4_2(L5_2, L6_2)
    L4_2 = A0_2.CustomData
    L5_2 = A2_2 or L5_2
    if not A2_2 then
      L5_2 = 4
    end
    L4_2.nTime = L5_2
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.nTime
    if 0 <= L4_2 then
      L5_2 = A0_2
      L4_2 = A0_2.AnimateToPoint
      L6_2 = A0_2.CustomData
      L6_2 = L6_2.nFadeInPoint
      L7_2 = 0.4
      L8_2 = true
      L9_2 = A0_2.SetEventHandler
      L10_2 = {}
      L11_2 = "GuiUpdate"
      L12_2 = _HandleMapLabelUpdateEvent
      L10_2[1] = L11_2
      L10_2[2] = L12_2
      L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
    else
      L5_2 = A0_2
      L4_2 = A0_2.AnimateToPoint
      L6_2 = A0_2.CustomData
      L6_2 = L6_2.nFadeInPoint
      L7_2 = 0.4
      L8_2 = true
      L4_2(L5_2, L6_2, L7_2, L8_2)
    end
  end
end

ShowMapLabel = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L4_2 = A0_2
  L3_2 = A0_2.SetVisible
  L5_2 = false
  L3_2(L4_2, L5_2)
  L4_2 = A0_2
  L3_2 = A0_2.Show
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
end

_HandleTransition = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = A0_2.CustomData
  L1_2.nTime = 0
  L1_2 = ShowMapLabel
  A0_2.Show = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.SetVisible
  L3_2 = false
  L1_2(L2_2, L3_2)
  L1_2 = A0_2.CustomData
  L3_2 = A0_2
  L2_2 = A0_2.AddAnimationPoint
  L4_2 = {}
  L4_2.TranslucencyLevel = 255
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.nFadeInPoint = L2_2
  L1_2 = A0_2.CustomData
  L3_2 = A0_2
  L2_2 = A0_2.AddAnimationPoint
  L4_2 = {}
  L4_2.TranslucencyLevel = 0
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.nFadeOutPoint = L2_2
  L1_2 = MrxGuiBase
  L1_2 = L1_2.FlashWidget
  L2_2 = L1_2
  L1_2 = L1_2.new
  L1_2 = L1_2(L2_2)
  L3_2 = A0_2
  L2_2 = A0_2.GetLocation
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  L6_2 = L3_2 + L5_2
  L6_2 = L6_2 * 0.5
  L7_2 = 0.6666667
  L4_2 = L4_2 + 10
  L9_2 = L1_2
  L8_2 = L1_2.SetLocation
  L10_2 = 850 * L7_2
  L10_2 = L4_2 - L10_2
  L11_2 = L7_2 / 2
  L11_2 = 50 * L11_2
  L11_2 = L6_2 - L11_2
  L12_2 = L4_2
  L13_2 = L7_2 / 2
  L13_2 = 50 * L13_2
  L13_2 = L6_2 + L13_2
  L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  L9_2 = L1_2
  L8_2 = L1_2.SetAnchoring
  L10_2 = "right"
  L11_2 = "top"
  L8_2(L9_2, L10_2, L11_2)
  L9_2 = L1_2
  L8_2 = L1_2.SetName
  L10_2 = "maplabeltext"
  L8_2(L9_2, L10_2)
  L9_2 = L1_2
  L8_2 = L1_2.SetOwner
  L11_2 = A0_2
  L10_2 = A0_2.GetOwner
  L10_2, L11_2, L12_2, L13_2 = L10_2(L11_2)
  L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  L9_2 = A0_2
  L8_2 = A0_2.AddChild
  L10_2 = L1_2
  L8_2(L9_2, L10_2)
  L8_2 = A0_2.CustomData
  L8_2.oFlash = L1_2
  L1_2.ParentWidget = A0_2
  L8_2 = MrxGuiBase
  L8_2 = L8_2.AddWidget
  L9_2 = L1_2
  L8_2(L9_2)
  L9_2 = L1_2
  L8_2 = L1_2.SetVisible
  L10_2 = false
  L8_2(L9_2, L10_2)
  L8_2 = MrxGuiManager
  L8_2 = L8_2.AddWidgetToHud
  L10_2 = A0_2
  L9_2 = A0_2.GetOwner
  L9_2 = L9_2(L10_2)
  L10_2 = L1_2
  L8_2(L9_2, L10_2)
end

_HandleMapLabelInitialization = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = A0_2.CustomData
  L1_2.bLoaded = true
  L2_2 = A0_2
  L1_2 = A0_2.SetFlashEventHandler
  L3_2 = "close"
  L4_2 = _CompleteTextFlashAnimation
  L1_2(L2_2, L3_2, L4_2)
end

_CompleteTextFlashLoad = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.ParentWidget
  L2_2 = L1_2
  L1_2 = L1_2.SetVisible
  L3_2 = false
  L1_2(L2_2, L3_2)
end

_CompleteTextFlashAnimation = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2.CustomData
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nTime
  L3_2 = L3_2 - A1_2
  L2_2.nTime = L3_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nTime
  if L2_2 <= 0 then
    L3_2 = A0_2
    L2_2 = A0_2.SetEventHandler
    L4_2 = "GuiUpdate"
    L5_2 = nil
    L2_2(L3_2, L4_2, L5_2)
    L2_2 = A0_2.CustomData
    L2_2.nTime = 0
    L3_2 = A0_2
    L2_2 = A0_2.AnimateToPoint
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.nFadeOutPoint
    L5_2 = 0.4
    L6_2 = true
    L7_2 = A0_2.SetVisible
    L8_2 = {}
    L9_2 = false
    L8_2[1] = L9_2
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  end
end

_HandleMapLabelUpdateEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A1_2.bTrespassing
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.SetJustification
    L4_2 = "left"
    L2_2(L3_2, L4_2)
    L3_2 = A0_2
    L2_2 = A0_2.Show
    L4_2 = "[red][Generic.Trespassing]"
    L5_2 = -1
    L2_2(L3_2, L4_2, L5_2)
    L2_2 = A0_2.CustomData
    L2_2.bTrespass = true
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.oFlash
    L3_2 = L2_2
    L2_2 = L2_2.SetVisible
    L4_2 = false
    L2_2(L3_2, L4_2)
    L2_2 = MrxTutorialManager
    L2_2 = L2_2.StartTutorial
    L3_2 = "Trespass"
    L4_2 = true
    L2_2(L3_2, L4_2)
  else
    L2_2 = A0_2.CustomData
    L2_2.bTrespass = false
    L3_2 = A0_2
    L2_2 = A0_2.SetJustification
    L4_2 = "right"
    L2_2(L3_2, L4_2)
    L3_2 = A0_2
    L2_2 = A0_2.AnimateToPoint
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.nFadeOutPoint
    L5_2 = 0.4
    L6_2 = true
    L7_2 = A0_2.SetVisible
    L8_2 = {}
    L9_2 = false
    L8_2[1] = L9_2
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  end
end

_HandleMapLabelTrespassEvent = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2.SetVisible
  L3_2 = false
  L1_2(L2_2, L3_2)
end

_HandleTrespassIconInit = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A1_2.bTrespassing
  if L2_2 then
    L2_2 = A1_2.sFaction
    if L2_2 then
      L2_2 = _tIcons
      L3_2 = A1_2.sFaction
      L2_2 = L2_2[L3_2]
      if L2_2 then
        L3_2 = A0_2
        L2_2 = A0_2.SetVisible
        L4_2 = true
        L2_2(L3_2, L4_2)
        L3_2 = A0_2
        L2_2 = A0_2.SetTexture
        L4_2 = _tIcons
        L5_2 = A1_2.sFaction
        L4_2 = L4_2[L5_2]
        L2_2(L3_2, L4_2)
    end
  end
  else
    L3_2 = A0_2
    L2_2 = A0_2.SetVisible
    L4_2 = false
    L2_2(L3_2, L4_2)
  end
end

_HandleTrespassIconEvent = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = {}
  L0_2.All = "HUD_faction_AN"
  L0_2.Chi = "HUD_faction_CH"
  L0_2.Civ = "HUD_faction_CV"
  L0_2.Gur = "HUD_faction_GR"
  L0_2.Oil = "HUD_faction_OC"
  L0_2.Pir = "HUD_faction_PR"
  L0_2.Vz = "HUD_faction_VZ"
  _tIcons = L0_2
end

Init = L0_1
