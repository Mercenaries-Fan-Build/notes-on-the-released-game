local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiBase"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiHudMessage"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiSupportShop"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiTutorial"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiHudFactionGauge"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTaskObjective"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxBootstrap"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifMissionData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSoundCategories"
L0_1(L1_1)
L0_1 = {}
HudInterface = L0_1
L0_1 = _G
L1_1 = HudInterface
L0_1.Hud = L1_1
L0_1 = {}
PdaInterface = L0_1
L0_1 = _G
L1_1 = PdaInterface
L0_1.oPda = L1_1
L0_1 = _G
L1_1 = PdaInterface
L0_1.Pda = L1_1
L0_1 = HudInterface
L1_1 = {}
L0_1.Radar = L1_1
L0_1 = HudInterface
L0_1 = L0_1.Radar

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "Minimap"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.AddObjective
    L10_2 = A1_2.sName
    L11_2 = A1_2.nX
    L12_2 = A1_2.nY
    L13_2 = A1_2.nZ
    L14_2 = A1_2.nR
    L15_2 = A1_2.nG
    L16_2 = A1_2.nB
    L17_2 = A1_2.nWidth
    L18_2 = A1_2.nHeight
    L19_2 = A1_2.sTexture
    L20_2 = A1_2.uGuid
    L21_2 = A1_2.bSticky
    L22_2 = A1_2.bRotate
    L23_2 = A1_2.bOriented
    L24_2 = A1_2.nSortOrder
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2)
  end
  L3_2 = Net
  L3_2 = L3_2.IsServer
  L3_2 = L3_2()
  if L3_2 then
    L3_2 = A1_2.bDontNetSync
    if not L3_2 then
      L3_2 = Net
      L3_2 = L3_2.SendEvent_AddRadarObjective
      L4_2 = A1_2.sName
      if not L4_2 then
        L4_2 = ""
      end
      L5_2 = A1_2.nX
      if not L5_2 then
        L5_2 = 0
      end
      L6_2 = A1_2.nY
      if not L6_2 then
        L6_2 = 2
      end
      L7_2 = A1_2.nZ
      if not L7_2 then
        L7_2 = 0
      end
      L8_2 = A1_2.nR
      if not L8_2 then
        L8_2 = 255
      end
      L9_2 = A1_2.nG
      if not L9_2 then
        L9_2 = 255
      end
      L10_2 = A1_2.nB
      if not L10_2 then
        L10_2 = 0
      end
      L11_2 = A1_2.nWidth
      if not L11_2 then
        L11_2 = 3
      end
      L12_2 = A1_2.nHeight
      if not L12_2 then
        L12_2 = 3
      end
      L13_2 = MrxUtil
      L13_2 = L13_2.MarkerGetIndexByName_Radar
      L14_2 = A1_2.sTexture
      if not L14_2 then
        L14_2 = ""
      end
      L13_2 = L13_2(L14_2)
      L14_2 = A1_2.uGuid
      if not L14_2 then
        L14_2 = 0
      end
      L15_2 = A1_2.bSticky
      if not L15_2 then
        L15_2 = false
      end
      L16_2 = A1_2.bRotate
      if not L16_2 then
        L16_2 = false
      end
      L17_2 = A1_2.bOriented
      if not L17_2 then
        L17_2 = false
      end
      L18_2 = A1_2.nSortOrder
      if not L18_2 then
        L18_2 = 5
      end
      L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
    end
  end
end

L0_1.AddObjective = L1_1
L0_1 = HudInterface
L0_1 = L0_1.Radar

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "Minimap"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.AddObjective
    L10_2 = A1_2.sName
    L11_2 = A1_2.nX
    L12_2 = A1_2.nY
    L13_2 = A1_2.nZ
    L14_2 = A1_2.nR
    L15_2 = A1_2.nG
    L16_2 = A1_2.nB
    L17_2 = A1_2.nWidth
    L18_2 = A1_2.nHeight
    L19_2 = A1_2.sTexture
    L20_2 = A1_2.uGuid
    L21_2 = A1_2.bSticky
    L22_2 = A1_2.bRotate
    L23_2 = A1_2.bOriented
    L24_2 = A1_2.nSortOrder
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2)
  end
  L3_2 = Net
  L3_2 = L3_2.IsServer
  L3_2 = L3_2()
  if L3_2 then
    L3_2 = A1_2.bDontNetSync
    if not L3_2 then
      L3_2 = Net
      L3_2 = L3_2.SendEvent_AddRadarObjective
      L4_2 = A1_2.sName
      if not L4_2 then
        L4_2 = ""
      end
      L5_2 = A1_2.nX
      if not L5_2 then
        L5_2 = 0
      end
      L6_2 = A1_2.nY
      if not L6_2 then
        L6_2 = 2
      end
      L7_2 = A1_2.nZ
      if not L7_2 then
        L7_2 = 0
      end
      L8_2 = A1_2.nR
      if not L8_2 then
        L8_2 = 255
      end
      L9_2 = A1_2.nG
      if not L9_2 then
        L9_2 = 255
      end
      L10_2 = A1_2.nB
      if not L10_2 then
        L10_2 = 0
      end
      L11_2 = A1_2.nWidth
      if not L11_2 then
        L11_2 = 3
      end
      L12_2 = A1_2.nHeight
      if not L12_2 then
        L12_2 = 3
      end
      L13_2 = MrxUtil
      L13_2 = L13_2.MarkerGetIndexByName_Radar
      L14_2 = A1_2.sTexture
      if not L14_2 then
        L14_2 = ""
      end
      L13_2 = L13_2(L14_2)
      L14_2 = A1_2.uGuid
      if not L14_2 then
        L14_2 = 0
      end
      L15_2 = A1_2.bSticky
      if not L15_2 then
        L15_2 = false
      end
      L16_2 = A1_2.bRotate
      if not L16_2 then
        L16_2 = false
      end
      L17_2 = A1_2.bOriented
      if not L17_2 then
        L17_2 = false
      end
      L18_2 = A1_2.nSortOrder
      if not L18_2 then
        L18_2 = 5
      end
      L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
    end
  end
end

L0_1.UpdateObjective = L1_1
L0_1 = HudInterface
L0_1 = L0_1.Radar

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A1_2.sName
  if not L2_2 then
    return
  end
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "Minimap"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.DeleteObjective
    L10_2 = A1_2.sName
    L8_2(L9_2, L10_2)
  end
  L3_2 = {}
  L4_2 = Net
  L4_2 = L4_2.IsServer
  L4_2 = L4_2()
  if L4_2 then
    L4_2 = A1_2.bDontNetSync
    if not L4_2 then
      L4_2 = Net
      L4_2 = L4_2.SendEvent_RemoveRadarObjective
      L5_2 = A1_2.sName
      L4_2(L5_2)
    end
  end
end

L0_1.RemoveObjective = L1_1
L0_1 = HudInterface
L0_1 = L0_1.Radar

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "Minimap"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = A1_2.nDuration
  if not L3_2 then
    L3_2 = 2
  end
  A1_2.nDuration = L3_2
  L3_2 = A1_2.nMinWidth
  if not L3_2 then
    L3_2 = 2
  end
  A1_2.nMinWidth = L3_2
  L3_2 = A1_2.nMinHeight
  if not L3_2 then
    L3_2 = 2
  end
  A1_2.nMinHeight = L3_2
  L3_2 = A1_2.nMaxWidth
  if not L3_2 then
    L3_2 = 6
  end
  A1_2.nMaxWidth = L3_2
  L3_2 = A1_2.nMaxHeight
  if not L3_2 then
    L3_2 = 6
  end
  A1_2.nMaxHeight = L3_2
  L3_2 = A1_2.nSpeedWidth
  if not L3_2 then
    L3_2 = 8
  end
  A1_2.nSpeedWidth = L3_2
  L3_2 = A1_2.nSpeedHeight
  if not L3_2 then
    L3_2 = 8
  end
  A1_2.nSpeedHeight = L3_2
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.AnimateObjectiveSize
    L10_2 = A1_2.sName
    L11_2 = A1_2.nDuration
    L12_2 = A1_2.nMinWidth
    L13_2 = A1_2.nMinHeight
    L14_2 = A1_2.nMaxWidth
    L15_2 = A1_2.nMaxHeight
    L16_2 = A1_2.bOneWay
    L17_2 = A1_2.nSpeedWidth
    L18_2 = A1_2.nSpeedHeight
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  end
end

L0_1.AnimateObjectiveSize = L1_1
L0_1 = HudInterface
L0_1 = L0_1.Radar

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "Minimap"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = A1_2.nDuration
  if not L3_2 then
    L3_2 = 1
  end
  A1_2.nDuration = L3_2
  L3_2 = A1_2.nMinAlpha
  if not L3_2 then
    L3_2 = 0
  end
  A1_2.nMinAlpha = L3_2
  L3_2 = A1_2.nMaxAlpha
  if not L3_2 then
    L3_2 = 1
  end
  A1_2.nMaxAlpha = L3_2
  L3_2 = A1_2.bOneWay
  if not L3_2 then
    L3_2 = false
  end
  A1_2.bOneWay = L3_2
  L3_2 = A1_2.nSpeed
  if not L3_2 then
    L3_2 = 0.5
  end
  A1_2.nSpeed = L3_2
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.AnimateObjectiveAlpha
    L10_2 = A1_2.sName
    L11_2 = A1_2.nDuration
    L12_2 = A1_2.nMinAlpha
    L13_2 = A1_2.nMaxAlpha
    L14_2 = A1_2.bOneWay
    L15_2 = A1_2.nSpeed
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  end
end

L0_1.AnimateObjectiveAlpha = L1_1
L0_1 = HudInterface
L0_1 = L0_1.Radar

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "Minimap"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = A1_2.nTotalBlips
  if not L3_2 then
    L3_2 = 4
  end
  A1_2.nTotalBlips = L3_2
  L3_2 = A1_2.nVisibleBlips
  if not L3_2 then
    L3_2 = 1
  end
  A1_2.nVisibleBlips = L3_2
  L3_2 = A1_2.nMinWidth
  if not L3_2 then
    L3_2 = 2
  end
  A1_2.nMinWidth = L3_2
  L3_2 = A1_2.nMaxWidth
  if not L3_2 then
    L3_2 = 8
  end
  A1_2.nMaxWidth = L3_2
  L3_2 = A1_2.nBlipDelay
  if not L3_2 then
    L3_2 = 1
  end
  A1_2.nBlipDelay = L3_2
  L3_2 = A1_2.nAlphaAtMin
  if not L3_2 then
    L3_2 = 0
  end
  A1_2.nAlphaAtMin = L3_2
  L3_2 = A1_2.nAlphaAtMax
  if not L3_2 then
    L3_2 = 1
  end
  A1_2.nAlphaAtMax = L3_2
  L3_2 = A1_2.nGrowSpeed
  if not L3_2 then
    L3_2 = 5
  end
  A1_2.nGrowSpeed = L3_2
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.AnimateObjectiveSonar
    L10_2 = A1_2.sName
    L11_2 = A1_2.nDuration
    L12_2 = A1_2.sTexture
    L13_2 = A1_2.nTotalBlips
    L14_2 = A1_2.nVisibleBlips
    L15_2 = A1_2.nMinWidth
    L16_2 = A1_2.nMaxWidth
    L17_2 = A1_2.nBlipDelay
    L18_2 = A1_2.nAlphaAtMin
    L19_2 = A1_2.nAlphaAtMax
    L20_2 = A1_2.nGrowSpeed
    L21_2 = A1_2.nRed
    L22_2 = A1_2.nGreen
    L23_2 = A1_2.nBlue
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2)
  end
end

L0_1.AnimateObjectiveSonar = L1_1
L0_1 = HudInterface
L0_1 = L0_1.Radar

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "Minimap"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.UnanimateObjective
    L10_2 = A1_2.sName
    L11_2 = A1_2.sType
    L8_2(L9_2, L10_2, L11_2)
  end
end

L0_1.UnanimateObjective = L1_1
L0_1 = HudInterface
L0_1 = L0_1.Radar

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "MinimapFlash"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.AddRegion
    L10_2 = A1_2.uGuid
    L11_2 = A1_2.nRed
    L12_2 = A1_2.nGreen
    L13_2 = A1_2.nBlue
    L14_2 = A1_2.nAlpha
    L15_2 = A1_2.bInvert
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  end
end

L0_1.AddLineRegion = L1_1
L0_1 = HudInterface
L0_1 = L0_1.Radar

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "MinimapFlash"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.RemoveRegion
    L10_2 = A1_2.uGuid
    L8_2(L9_2, L10_2)
  end
end

L0_1.RemoveLineRegion = L1_1
L0_1 = HudInterface
L1_1 = {}
L1_1.sName = "MessageBox"
L0_1.MessageBox = L1_1
L0_1 = HudInterface
L0_1 = L0_1.MessageBox

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = A0_2.sName
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = {}
  L4_2 = nil
  L5_2 = pairs
  L6_2 = L2_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L11_2 = L9_2
    L10_2 = L9_2.AddMessage
    L12_2 = A1_2.sMessage
    L13_2 = A1_2.nPriority
    L14_2 = A1_2.nDuration
    L15_2 = A1_2.nFadeTime
    L16_2 = A1_2.bClearBuffer
    L17_2 = A1_2.bAllowsAppends
    L18_2 = A1_2.fCallback
    L19_2 = A1_2.tCallbackData
    L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
    L4_2 = L10_2
    L11_2 = L9_2
    L10_2 = L9_2.GetOwner
    L10_2 = L10_2(L11_2)
    L3_2[L10_2] = L4_2
  end
  return L3_2
end

L0_1.AddMessage = L1_1
L0_1 = HudInterface
L0_1 = L0_1.MessageBox

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L2_2 = true
  L3_2 = _GetWidgetsForPlayers
  L4_2 = A1_2.vPlayer
  L5_2 = A0_2.sName
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = pairs
  L5_2 = L3_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    if L2_2 then
      L10_2 = L8_2
      L9_2 = L8_2.ModifyPendingMessage
      L11_2 = A1_2.tMessageIds
      L13_2 = L8_2
      L12_2 = L8_2.GetOwner
      L12_2 = L12_2(L13_2)
      L11_2 = L11_2[L12_2]
      L12_2 = A1_2.sMessage
      L13_2 = A1_2.nDuration
      L14_2 = A1_2.nFadeTime
      L15_2 = A1_2.bClearBuffer
      L16_2 = A1_2.bAllowsAppends
      L17_2 = A1_2.fCallback
      L18_2 = A1_2.tCallbackData
      L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
      L2_2 = L9_2
    end
  end
  return L2_2
end

L0_1.ModifyPendingMessage = L1_1
L0_1 = HudInterface
L0_1 = L0_1.MessageBox

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = A0_2.sName
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.RemovePendingMessage
    L10_2 = A1_2.tMessageIds
    L12_2 = L7_2
    L11_2 = L7_2.GetOwner
    L11_2 = L11_2(L12_2)
    L10_2 = L10_2[L11_2]
    L8_2(L9_2, L10_2)
  end
end

L0_1.RemovePendingMessage = L1_1
L0_1 = HudInterface
L0_1 = L0_1.MessageBox

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = A0_2.sName
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.ClearMessages
    L8_2(L9_2)
  end
end

L0_1.Clear = L1_1
L0_1 = {}
L1_1 = {}
L1_1.sColor = "[objt]"
L1_1.sHexColor = "FFC800"
L1_1.sPrefix = "Objective"
L1_1.sStatus = "added"
L1_1.nPriority = 1
L1_1.sSoundCue = "ui_HUD_Objective_New"
L0_1.add = L1_1
L1_1 = {}
L1_1.sColor = "[2ndobjt]"
L1_1.sHexColor = "33CC99"
L1_1.sPrefix = "Bonus"
L1_1.sStatus = "added"
L1_1.nPriority = 2
L1_1.sSoundCue = "ui_HUD_Objective_New"
L0_1.bonus_add = L1_1
L1_1 = {}
L1_1.sColor = "[2ndobjt]"
L1_1.sHexColor = "33CC99"
L1_1.sPrefix = "Bounty"
L1_1.sStatus = "added"
L1_1.nPriority = 3
L1_1.sSoundCue = "ui_HUD_Objective_New"
L0_1.bty_add = L1_1
L1_1 = {}
L1_1.sColor = "[objt]"
L1_1.sHexColor = "FFC800"
L1_1.sPrefix = "Objective"
L1_1.sStatus = "updated"
L1_1.nPriority = 1
L1_1.sSoundCue = "ui_HUD_Objective_Update"
L0_1.upd = L1_1
L1_1 = {}
L1_1.sColor = "[2ndobjt]"
L1_1.sHexColor = "33CC99"
L1_1.sPrefix = "Bonus"
L1_1.sStatus = "updated"
L1_1.nPriority = 2
L1_1.sSoundCue = "ui_HUD_Objective_Update"
L0_1.bonus_upd = L1_1
L1_1 = {}
L1_1.sColor = "[2ndobjt]"
L1_1.sHexColor = "33CC99"
L1_1.sPrefix = "Bounty"
L1_1.sStatus = "updated"
L1_1.nPriority = 3
L1_1.sSoundCue = "ui_HUD_Objective_Update"
L0_1.bty_upd = L1_1
L1_1 = {}
L1_1.sColor = "[objt]"
L1_1.sHexColor = "FFC800"
L1_1.sPrefix = "Objective"
L1_1.sStatus = "completed"
L1_1.nPriority = 1
L1_1.sSoundCue = "ui_HUD_Objective_Complete"
L0_1.cpl = L1_1
L1_1 = {}
L1_1.sColor = "[2ndobjt]"
L1_1.sHexColor = "33CC99"
L1_1.sPrefix = "Bonus"
L1_1.sStatus = "completed"
L1_1.nPriority = 2
L1_1.sSoundCue = "ui_HUD_Objective_Complete"
L0_1.bonus_cpl = L1_1
L1_1 = {}
L1_1.sColor = "[2ndobjt]"
L1_1.sHexColor = "33CC99"
L1_1.sPrefix = "Bounty"
L1_1.sStatus = "completed"
L1_1.nPriority = 3
L1_1.sSoundCue = "ui_HUD_Objective_Complete"
L0_1.bty_cpl = L1_1
L1_1 = {}
L1_1.sColor = "[red]"
L1_1.sHexColor = "FF0000"
L1_1.sPrefix = "Objective"
L1_1.sStatus = "cancelled"
L1_1.nPriority = 1
L0_1.ccl = L1_1
L1_1 = {}
L1_1.sColor = "[red]"
L1_1.sHexColor = "FF0000"
L1_1.sPrefix = "Bonus"
L1_1.sStatus = "cancelled"
L1_1.nPriority = 2
L0_1.bonus_ccl = L1_1
L1_1 = {}
L1_1.sColor = "[red]"
L1_1.sHexColor = "FF0000"
L1_1.sPrefix = "Bounty"
L1_1.sStatus = "cancelled"
L1_1.nPriority = 3
L0_1.bty_ccl = L1_1
L1_1 = {}
L1_1.sColor = "[2ndobjt]"
L1_1.sHexColor = "33CC99"
L1_1.sPrefix = "Collectible"
L1_1.sStatus = "updated"
L1_1.nPriority = 4
L1_1.sSoundCue = "ui_HUD_Objective_Update"
L0_1.collectible_upd = L1_1
tObjectiveMessageConfigs = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = pairs
  L2_2 = tObjectiveMessageConfigs
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = String
    L6_2 = L6_2.GetHash
    L7_2 = L4_2
    L6_2 = L6_2(L7_2)
    if L6_2 == A0_2 then
      return L4_2
    end
  end
end

GetMessageTypeFromHash = L0_1
L0_1 = {}
_tMsgIdsByGroup = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2)
  local L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2
  L7_2 = Net
  L7_2 = L7_2.IsClient
  L7_2 = L7_2()
  if L7_2 and A1_2 == 99 then
    L7_2 = Hud
    L7_2 = L7_2.MessageBox
    L8_2 = L7_2
    L7_2 = L7_2.AddMessage
    L9_2 = {}
    L9_2.sMessage = "[Generic.CheckpointReached]"
    L7_2(L8_2, L9_2)
    return
  end
  L7_2 = Net
  L7_2 = L7_2.IsClient
  L7_2 = L7_2()
  if L7_2 then
    L7_2 = type
    L8_2 = A1_2
    L7_2 = L7_2(L8_2)
    if L7_2 ~= "string" then
      L7_2 = MrxUtil
      L7_2 = L7_2.GetInlineIconNameByIndex
      L8_2 = A1_2
      L7_2 = L7_2(L8_2)
      A1_2 = L7_2
    end
  end
  L7_2 = Net
  L7_2 = L7_2.IsClient
  L7_2 = L7_2()
  if L7_2 then
    L7_2 = type
    L8_2 = A4_2
    L7_2 = L7_2(L8_2)
    if L7_2 ~= "string" then
      L7_2 = tostring
      L8_2 = A4_2
      L7_2 = L7_2(L8_2)
      A4_2 = L7_2
    end
  end
  L7_2 = type
  L8_2 = A2_2
  L7_2 = L7_2(L8_2)
  if L7_2 ~= "string" then
    L7_2 = GetMessageTypeFromHash
    L8_2 = A2_2
    L7_2 = L7_2(L8_2)
    A2_2 = L7_2
  end
  L7_2 = tObjectiveMessageConfigs
  L7_2 = L7_2[A2_2]
  L8_2 = tObjectiveMessageConfigs
  L8_2 = L8_2[A2_2]
  if not L8_2 then
    return
  end
  L8_2 = L7_2.sStatus
  L9_2 = L7_2.sColor
  L10_2 = L7_2.sHexColor
  L11_2 = L7_2.sPrefix
  L12_2 = L7_2.nPriority
  L13_2 = L7_2.sSoundCue
  L14_2 = A1_2
  L15_2 = " [objective."
  L16_2 = L11_2
  L17_2 = L8_2
  L18_2 = "]"
  L14_2 = L14_2 .. L15_2 .. L16_2 .. L17_2 .. L18_2
  L15_2 = nil
  L16_2 = L9_2
  L17_2 = L14_2
  L18_2 = " "
  L19_2 = A3_2
  L15_2 = L16_2 .. L17_2 .. L18_2 .. L19_2
  if A0_2 then
    L16_2 = Net
    L16_2 = L16_2.IsServer
    L16_2 = L16_2()
    if L16_2 then
      L16_2 = Net
      L16_2 = L16_2.SendEvent_ObjectiveMessage
      L17_2 = MrxUtil
      L17_2 = L17_2.GetInlineIconIndexByName
      L18_2 = A1_2
      L17_2 = L17_2(L18_2)
      L18_2 = A2_2
      L19_2 = A3_2
      L20_2 = StringToGuid
      L21_2 = A4_2
      L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2 = L20_2(L21_2)
      L16_2(L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2)
    end
    L16_2 = MrxBootstrap
    L16_2 = L16_2.IsGuiLoaded
    L16_2 = L16_2()
    if L16_2 ~= true then
      L16_2 = Event
      L16_2 = L16_2.Create
      L17_2 = Event
      L17_2 = L17_2.TimerRelative
      L18_2 = {}
      L19_2 = 1
      L18_2[1] = L19_2
      L19_2 = DisplayObjectiveMessage
      L20_2 = {}
      L21_2 = A0_2
      L22_2 = A1_2
      L23_2 = A2_2
      L24_2 = A3_2
      L25_2 = A4_2
      L26_2 = A5_2
      L27_2 = A6_2
      L20_2[1] = L21_2
      L20_2[2] = L22_2
      L20_2[3] = L23_2
      L20_2[4] = L24_2
      L20_2[5] = L25_2
      L20_2[6] = L26_2
      L20_2[7] = L27_2
      L16_2(L17_2, L18_2, L19_2, L20_2)
    else
      function L16_2()
        local L0_3, L1_3, L2_3
        
        L0_3 = A4_2
        if L0_3 then
          L0_3 = A4_2
          _sGroupIdOfDisplayedMsg = L0_3
          L0_3 = _tMsgIdsByGroup
          L1_3 = A4_2
          L0_3[L1_3] = nil
        end
        L0_3 = MrxUtil
        L0_3 = L0_3.CallWithOptionalArgs
        L1_3 = A5_2
        L2_3 = A6_2
        L0_3(L1_3, L2_3)
      end
      
      L17_2 = false
      if A4_2 then
        L18_2 = _sGroupIdOfDisplayedMsg
        if L18_2 ~= A4_2 then
          L18_2 = _tMsgIdsByGroup
          L18_2 = L18_2[A4_2]
          if L18_2 then
            L19_2 = Hud
            L19_2 = L19_2.MessageBox
            L20_2 = L19_2
            L19_2 = L19_2.ModifyPendingMessage
            L21_2 = {}
            L21_2.tMessageIds = L18_2
            L21_2.sMessage = L15_2
            L19_2 = L19_2(L20_2, L21_2)
            L17_2 = L19_2
          end
        end
      end
      if not L17_2 then
        if A4_2 then
          L18_2 = _sGroupIdOfDisplayedMsg
          if L18_2 == A4_2 then
            L12_2 = 0
          end
        end
        L18_2 = Hud
        L18_2 = L18_2.MessageBox
        L19_2 = L18_2
        L18_2 = L18_2.AddMessage
        L20_2 = {}
        L20_2.sMessage = L15_2
        L20_2.nPriority = L12_2
        L20_2.nDuration = 5
        L20_2.bClearBuffer = true
        L20_2.bAllowsAppends = false
        L20_2.fCallback = L16_2
        L18_2 = L18_2(L19_2, L20_2)
        if A4_2 and L18_2 then
          L19_2 = _tMsgIdsByGroup
          L19_2[A4_2] = L18_2
        end
      end
      L18_2 = Pda
      L18_2 = L18_2.Database
      L19_2 = L18_2
      L18_2 = L18_2.AddLogEntry
      L20_2 = {}
      L20_2.sType = "objective"
      L20_2.sName = ""
      L21_2 = L14_2
      L22_2 = " "
      L23_2 = A3_2
      L21_2 = L21_2 .. L22_2 .. L23_2
      L20_2.sMessage = L21_2
      L20_2.sColor = L10_2
      L18_2(L19_2, L20_2)
    end
    L16_2 = _evClientJoined
    if L16_2 then
      L16_2 = Event
      L16_2 = L16_2.Delete
      L17_2 = _evClientJoined
      L16_2(L17_2)
    end
    if A2_2 == "add" or A2_2 == "bonus_add" or A2_2 == "bty_add" or A2_2 == "upd" or A2_2 == "bonus_upd" or A2_2 == "bty_upd" then
      L16_2 = Event
      L16_2 = L16_2.CreatePersistent
      L17_2 = Event
      L17_2 = L17_2.ScriptEvent
      L18_2 = {}
      L19_2 = "mpPlayerJoin"
      
      function L20_2(A0_3)
        local L1_3, L2_3
        L1_3 = Net
        L1_3 = L1_3.IsServer
        L1_3 = L1_3()
        if L1_3 then
          L1_3 = Player
          L1_3 = L1_3.IsLocal
          L2_3 = A0_3[1]
          L1_3 = L1_3(L2_3)
          L1_3 = not L1_3
        end
        return L1_3
      end
      
      L18_2[1] = L19_2
      L18_2[2] = L20_2
      L19_2 = Net
      L19_2 = L19_2.SendEvent_ObjectiveMessage
      L20_2 = {}
      L21_2 = MrxUtil
      L21_2 = L21_2.GetInlineIconIndexByName
      L22_2 = A1_2
      L21_2 = L21_2(L22_2)
      L22_2 = A2_2
      L23_2 = A3_2
      L24_2 = StringToGuid
      L25_2 = A4_2
      L24_2, L25_2, L26_2, L27_2 = L24_2(L25_2)
      L20_2[1] = L21_2
      L20_2[2] = L22_2
      L20_2[3] = L23_2
      L20_2[4] = L24_2
      L20_2[5] = L25_2
      L20_2[6] = L26_2
      L20_2[7] = L27_2
      L16_2 = L16_2(L17_2, L18_2, L19_2, L20_2)
      _evClientJoined = L16_2
    end
    if L13_2 then
      L16_2 = Sound
      L16_2 = L16_2.CueSound
      L17_2 = 0
      L18_2 = L13_2
      L16_2(L17_2, L18_2)
    end
  end
end

DisplayObjectiveMessage = L0_1
L0_1 = HudInterface
L1_1 = {}
L0_1.SupportMenu = L1_1
L0_1 = HudInterface
L0_1 = L0_1.SupportMenu

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "Support Menu"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.AddItem
    L10_2 = {}
    L11_2 = A1_2.sName
    L10_2.sName = L11_2
    L11_2 = A1_2.sIcon
    L10_2.sIcon = L11_2
    L11_2 = A1_2.oSupport
    L10_2.oSupport = L11_2
    L11_2 = A1_2.bAnimate
    L10_2.bAnimate = L11_2
    L11_2 = A1_2.bDontNetSync
    L10_2.bDontNetSync = L11_2
    L8_2(L9_2, L10_2)
  end
end

L0_1.AddItem = L1_1
L0_1 = HudInterface
L0_1 = L0_1.SupportMenu

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "Support Menu"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.RemoveItem
    L10_2 = A1_2.sName
    L11_2 = A1_2.bDontNetSync
    L8_2(L9_2, L10_2, L11_2)
  end
end

L0_1.RemoveItem = L1_1
L0_1 = HudInterface
L0_1 = L0_1.SupportMenu

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "Support Menu"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.SetShootingGalleryMode
    L10_2 = A1_2.bEnable
    L8_2(L9_2, L10_2)
  end
end

L0_1.SetShootingGalleryMode = L1_1
L0_1 = HudInterface
L1_1 = {}
L0_1.ObjectiveTray = L1_1
L0_1 = {}
tClientSlotText = L0_1
L0_1 = HudInterface
L0_1 = L0_1.ObjectiveTray

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "Objective Tray"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.SetSlotToText
    L10_2 = A1_2.nSlot
    L11_2 = A1_2.sText
    L8_2(L9_2, L10_2, L11_2)
  end
  L3_2 = {}
  L4_2 = Net
  L4_2 = L4_2.IsServer
  L4_2 = L4_2()
  if L4_2 then
    L4_2 = A1_2.bDontNetSync
    if not L4_2 then
      L4_2 = type
      L5_2 = A1_2.vPlayer
      L4_2 = L4_2(L5_2)
      if "table" == L4_2 then
        L3_2 = A1_2.vPlayer
      else
        L4_2 = type
        L5_2 = A1_2.vPlayer
        L4_2 = L4_2(L5_2)
        if "userdata" == L4_2 then
          L4_2 = {}
          L5_2 = A1_2.vPlayer
          L4_2[1] = L5_2
          L3_2 = L4_2
        else
          L4_2 = A1_2.vPlayer
          if not L4_2 then
            L4_2 = Player
            L4_2 = L4_2.GetAllPlayers
            L4_2 = L4_2()
            L3_2 = L4_2
          else
            return
          end
        end
      end
      L4_2 = pairs
      L5_2 = L3_2
      L4_2, L5_2, L6_2 = L4_2(L5_2)
      for L7_2, L8_2 in L4_2, L5_2, L6_2 do
        L9_2 = Player
        L9_2 = L9_2.IsRemote
        L10_2 = Player
        L10_2 = L10_2.GetPlayerId
        L11_2 = L8_2
        L10_2, L11_2, L12_2 = L10_2(L11_2)
        L9_2 = L9_2(L10_2, L11_2, L12_2)
        if L9_2 then
          L9_2 = Net
          L9_2 = L9_2.SendEvent_SetObjectiveTraySlotText
          L10_2 = L8_2
          L11_2 = A1_2.nSlot
          L12_2 = A1_2.sText
          L9_2(L10_2, L11_2, L12_2)
        end
      end
      L4_2 = tClientSlotText
      L5_2 = A1_2.nSlot
      L6_2 = A1_2.sText
      L4_2[L5_2] = L6_2
      L4_2 = Event
      L4_2 = L4_2.Delete
      L5_2 = _evSetClientSlotText
      L4_2(L5_2)
      L4_2 = Event
      L4_2 = L4_2.CreatePersistent
      L5_2 = Event
      L5_2 = L5_2.ScriptEvent
      L6_2 = {}
      L7_2 = "mpPlayerJoin"
      
      function L8_2(A0_3)
        local L1_3, L2_3
        L1_3 = Net
        L1_3 = L1_3.IsServer
        L1_3 = L1_3()
        if L1_3 then
          L1_3 = Player
          L1_3 = L1_3.IsLocal
          L2_3 = A0_3[1]
          L1_3 = L1_3(L2_3)
          L1_3 = not L1_3
        end
        return L1_3
      end
      
      L6_2[1] = L7_2
      L6_2[2] = L8_2
      L7_2 = SendSlotText
      L4_2 = L4_2(L5_2, L6_2, L7_2)
      _evSetClientSlotText = L4_2
    end
  end
end

L0_1.SetSlotToText = L1_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.ObjectHibernation
  L2_2 = {}
  L3_2 = Player
  L3_2 = L3_2.GetSecondaryCharacter
  L3_2 = L3_2()
  L4_2 = "awake"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
    L0_3 = pairs
    L1_3 = tClientSlotText
    L0_3, L1_3, L2_3 = L0_3(L1_3)
    for L3_3, L4_3 in L0_3, L1_3, L2_3 do
      L5_3 = Net
      L5_3 = L5_3.SendEvent_SetObjectiveTraySlotText
      L6_3 = Player
      L6_3 = L6_3.GetSecondaryPlayer
      L6_3 = L6_3()
      L7_3 = L3_3
      L8_3 = L4_3
      L5_3(L6_3, L7_3, L8_3)
    end
  end
  
  L0_2(L1_2, L2_2, L3_2)
end

SendSlotText = L0_1
L0_1 = HudInterface
L0_1 = L0_1.ObjectiveTray

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "Objective Tray"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.SetSlotToImage
    L10_2 = A1_2.nSlot
    L11_2 = A1_2.sTexture
    L12_2 = A1_2.nWidth
    L13_2 = A1_2.nHeight
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  end
  L3_2 = {}
  L4_2 = Net
  L4_2 = L4_2.IsServer
  L4_2 = L4_2()
  if L4_2 then
    L4_2 = A1_2.bDontNetSync
    if not L4_2 then
      L4_2 = type
      L5_2 = A1_2.vPlayer
      L4_2 = L4_2(L5_2)
      if "table" == L4_2 then
        L3_2 = A1_2.vPlayer
      else
        L4_2 = type
        L5_2 = A1_2.vPlayer
        L4_2 = L4_2(L5_2)
        if "userdata" == L4_2 then
          L4_2 = {}
          L5_2 = A1_2.vPlayer
          L4_2[1] = L5_2
          L3_2 = L4_2
        else
          L4_2 = A1_2.vPlayer
          if not L4_2 then
            L4_2 = Player
            L4_2 = L4_2.GetAllPlayers
            L4_2 = L4_2()
            L3_2 = L4_2
          else
            return
          end
        end
      end
      L4_2 = pairs
      L5_2 = L3_2
      L4_2, L5_2, L6_2 = L4_2(L5_2)
      for L7_2, L8_2 in L4_2, L5_2, L6_2 do
        L9_2 = Player
        L9_2 = L9_2.IsRemote
        L10_2 = Player
        L10_2 = L10_2.GetPlayerId
        L11_2 = L8_2
        L10_2, L11_2, L12_2, L13_2, L14_2 = L10_2(L11_2)
        L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
        if L9_2 then
          L9_2 = Net
          L9_2 = L9_2.SendEvent_SetObjectiveTraySlotImage
          L10_2 = L8_2
          L11_2 = A1_2.nSlot
          L12_2 = A1_2.sTexture
          L13_2 = A1_2.nWidth
          L14_2 = A1_2.nHeight
          L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
        end
      end
    end
  end
end

L0_1.SetSlotToImage = L1_1
L0_1 = HudInterface
L0_1 = L0_1.ObjectiveTray

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "Objective Tray"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.SetSlotToWidget
    L10_2 = A1_2.nSlot
    L11_2 = A1_2.oWidget
    L8_2(L9_2, L10_2, L11_2)
  end
end

L0_1.SetSlotToWidget = L1_1
L0_1 = HudInterface
L0_1 = L0_1.ObjectiveTray

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "Objective Tray"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.ClearSlot
    L10_2 = A1_2.nSlot
    L8_2(L9_2, L10_2)
  end
  L3_2 = tClientSlotText
  L4_2 = A1_2.nSlot
  L3_2[L4_2] = nil
  L3_2 = {}
  L4_2 = Net
  L4_2 = L4_2.IsServer
  L4_2 = L4_2()
  if L4_2 then
    L4_2 = A1_2.bDontNetSync
    if not L4_2 then
      L4_2 = type
      L5_2 = A1_2.vPlayer
      L4_2 = L4_2(L5_2)
      if "table" == L4_2 then
        L3_2 = A1_2.vPlayer
      else
        L4_2 = type
        L5_2 = A1_2.vPlayer
        L4_2 = L4_2(L5_2)
        if "userdata" == L4_2 then
          L4_2 = {}
          L5_2 = A1_2.vPlayer
          L4_2[1] = L5_2
          L3_2 = L4_2
        else
          L4_2 = A1_2.vPlayer
          if not L4_2 then
            L4_2 = Player
            L4_2 = L4_2.GetAllPlayers
            L4_2 = L4_2()
            L3_2 = L4_2
          else
            return
          end
        end
      end
      L4_2 = pairs
      L5_2 = L3_2
      L4_2, L5_2, L6_2 = L4_2(L5_2)
      for L7_2, L8_2 in L4_2, L5_2, L6_2 do
        L9_2 = Player
        L9_2 = L9_2.IsRemote
        L10_2 = Player
        L10_2 = L10_2.GetPlayerId
        L11_2 = L8_2
        L10_2, L11_2 = L10_2(L11_2)
        L9_2 = L9_2(L10_2, L11_2)
        if L9_2 then
          L9_2 = Net
          L9_2 = L9_2.SendEvent_ClearObjectiveTraySlot
          L10_2 = L8_2
          L11_2 = A1_2.nSlot
          L9_2(L10_2, L11_2)
        end
      end
    end
  end
end

L0_1.ClearSlot = L1_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L6_2 = Net
  L6_2 = L6_2.IsServer
  L6_2 = L6_2()
  if not L6_2 then
    L6_2 = MrxGuiBase
    L6_2 = L6_2.GetWidgetByName
    L7_2 = "Objective Tray"
    L6_2 = L6_2(L7_2)
    if not L6_2 then
      L7_2 = Event
      L7_2 = L7_2.Create
      L8_2 = Event
      L8_2 = L8_2.TimerRelative
      L9_2 = {}
      L10_2 = 2
      L9_2[1] = L10_2
      L10_2 = NetClientSetObjectiveTraySlot
      L11_2 = {}
      L12_2 = A0_2
      L13_2 = A1_2
      L14_2 = A2_2
      L15_2 = A3_2
      L16_2 = A4_2
      L17_2 = A5_2
      L11_2[1] = L12_2
      L11_2[2] = L13_2
      L11_2[3] = L14_2
      L11_2[4] = L15_2
      L11_2[5] = L16_2
      L11_2[6] = L17_2
      L7_2(L8_2, L9_2, L10_2, L11_2)
      return
    end
    if A1_2 then
      L7_2 = Hud
      L7_2 = L7_2.ObjectiveTray
      L8_2 = L7_2
      L7_2 = L7_2.SetSlotToImage
      L9_2 = {}
      L9_2.nSlot = A0_2
      L9_2.sTexture = A3_2
      L9_2.nWidth = A4_2
      L9_2.nHeight = A5_2
      L7_2(L8_2, L9_2)
    else
      L7_2 = Hud
      L7_2 = L7_2.ObjectiveTray
      L8_2 = L7_2
      L7_2 = L7_2.SetSlotToText
      L9_2 = {}
      L9_2.nSlot = A0_2
      L9_2.sText = A2_2
      L7_2(L8_2, L9_2)
    end
  end
end

NetClientSetObjectiveTraySlot = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Net
  L1_2 = L1_2.IsServer
  L1_2 = L1_2()
  if not L1_2 then
    L1_2 = Hud
    L1_2 = L1_2.ObjectiveTray
    L2_2 = L1_2
    L1_2 = L1_2.ClearSlot
    L3_2 = {}
    L3_2.nSlot = A0_2
    L1_2(L2_2, L3_2)
  end
end

NetClientClearObjectiveTraySlot = L0_1
L0_1 = HudInterface
L1_1 = {}
L0_1.MapLabel = L1_1
L0_1 = HudInterface
L0_1 = L0_1.MapLabel

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "Map Label"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.Show
    L10_2 = A1_2.sLocation
    L11_2 = A1_2.nDuration
    L12_2 = true
    L8_2(L9_2, L10_2, L11_2, L12_2)
  end
end

L0_1.Show = L1_1
L0_1 = HudInterface
L1_1 = {}
L0_1.Announcement = L1_1
L0_1 = HudInterface
L0_1 = L0_1.Announcement

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L3_2 = vPlayer
  if not L3_2 then
    L3_2 = Player
    L3_2 = L3_2.GetAllPlayers
    L3_2 = L3_2()
    L2_2 = L3_2
  else
    L3_2 = type
    L4_2 = vPlayer
    L3_2 = L3_2(L4_2)
    if "userdata" == L3_2 then
      L3_2 = {}
      L4_2 = tPlayer
      L3_2[1] = L4_2
      L2_2 = L3_2
    else
      L3_2 = type
      L4_2 = vPlayer
      L3_2 = L3_2(L4_2)
      if "table" == L3_2 then
        L2_2 = vPlayer
      end
    end
  end
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = MrxGuiHudMessage
    L8_2 = L8_2.ShowMessage
    L9_2 = L7_2
    L10_2 = A1_2.sTexture
    L11_2 = A1_2.fZoomCallback
    L12_2 = A1_2.fFadeCallback
    L13_2 = A1_2.nX
    L14_2 = A1_2.nY
    L15_2 = A1_2.sHorizontalAnchor
    L16_2 = A1_2.sVerticalAnchor
    L17_2 = A1_2.nWidth
    L18_2 = A1_2.nHeight
    L19_2 = A1_2.nDuration
    L20_2 = A1_2.vSoundEffect
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
  end
end

L0_1.Show = L1_1
L0_1 = {}
L0_1.bPending = true
L0_1.bPaused = false
_tFanfareQueue = L0_1
L0_1 = _tFanfareQueue

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A0_2.bPending
  if L2_2 then
    A0_2.bPending = false
    L2_2 = A1_2
    L3_2 = A0_2
    L2_2(L3_2)
  else
    L2_2 = table
    L2_2 = L2_2.insert
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  end
end

L0_1.Append = L1_1
L0_1 = _tFanfareQueue

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = _tFanfareQueue
  L1_2 = L1_2.bPaused
  if not L1_2 then
    L1_2 = A0_2.bAdvancing
    if not L1_2 then
      L1_2 = Net
      L1_2 = L1_2.IsClient
      L1_2 = L1_2()
      if L1_2 then
        L1_2 = bClientPauseFanfare
        if L1_2 then
          return
        end
      end
      L1_2 = #A0_2
      if 0 < L1_2 then
        A0_2.bAdvancing = true
        L1_2 = A0_2[1]
        L2_2 = table
        L2_2 = L2_2.remove
        L3_2 = A0_2
        L4_2 = 1
        L2_2(L3_2, L4_2)
        L2_2 = L1_2
        L3_2 = A0_2
        L2_2(L3_2)
      else
        A0_2.bPending = true
      end
    end
  end
end

L0_1.Advance = L1_1
L0_1 = _tFanfareQueue

function L1_1(A0_2)
  local L1_2, L2_2
  A0_2.bAdvancing = false
  L2_2 = A0_2
  L1_2 = A0_2.Advance
  L1_2(L2_2)
end

L0_1.FinishItem = L1_1
L0_1 = HudInterface
L1_1 = {}
L0_1.FanfareQueue = L1_1
L0_1 = HudInterface
L0_1 = L0_1.FanfareQueue

function L1_1(A0_2, A1_2, ...)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = {}
  L4_2, L5_2, L6_2 = ...
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L4_2 = _tFanfareQueue
  L5_2 = L4_2
  L4_2 = L4_2.Append
  
  function L6_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = A1_2
    if L1_3 then
      L1_3 = A1_2
      L2_3 = unpack
      L3_3 = L3_2
      L2_3, L3_3 = L2_3(L3_3)
      L1_3(L2_3, L3_3)
    end
    L2_3 = A0_3
    L1_3 = A0_3.FinishItem
    L1_3(L2_3)
  end
  
  L4_2(L5_2, L6_2)
end

L0_1.Append = L1_1
L0_1 = HudInterface
L0_1 = L0_1.FanfareQueue

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _tFanfareQueue
  L1_2.bPaused = A0_2
  if not A0_2 then
    L1_2 = _tFanfareQueue
    L2_2 = L1_2
    L1_2 = L1_2.Advance
    L1_2(L2_2)
  end
end

L0_1.Pause = L1_1
L0_1 = HudInterface
L0_1 = L0_1.FanfareQueue

function L1_1(A0_2)
  local L1_2
  L1_2 = _tFanfareQueue
  L1_2.bPending = A0_2
end

L0_1.ClientSetPending = L1_1
L0_1 = false
bClientPauseFanfare = L0_1
L0_1 = HudInterface
L0_1 = L0_1.FanfareQueue

function L1_1(A0_2)
  local L1_2, L2_2
  bClientPauseFanfare = A0_2
  L1_2 = bClientPauseFanfare
  if not L1_2 then
    L1_2 = _tFanfareQueue
    L2_2 = L1_2
    L1_2 = L1_2.Advance
    L1_2(L2_2)
  end
end

L0_1.ClientPause = L1_1
L0_1 = HudInterface
L1_1 = {}
L0_1.JobFanfare = L1_1
L0_1 = HudInterface
L0_1 = L0_1.JobFanfare

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _tFanfareQueue
  L3_2 = L2_2
  L2_2 = L2_2.Append
  
  function L4_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3
    L1_3 = MrxGuiHudMessage
    L1_3 = L1_3.ShowCompletedMessage
    L2_3 = nil
    L3_3 = nil
    
    function L4_3()
      local L0_4, L1_4
      L0_4 = A1_2
      L0_4 = L0_4.fCallback
      if L0_4 then
        L0_4 = A1_2
        L0_4 = L0_4.fCallback
        L1_4 = A1_2
        L1_4 = L1_4.tCallbackData
        L0_4(L1_4)
      end
      L0_4 = A0_3
      L1_4 = L0_4
      L0_4 = L0_4.FinishItem
      L0_4(L1_4)
    end
    
    L1_3(L2_3, L3_3, L4_3)
  end
  
  L2_2(L3_2, L4_2)
end

L0_1.Complete = L1_1
L0_1 = HudInterface
L0_1 = L0_1.JobFanfare

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _tFanfareQueue
  L3_2 = L2_2
  L2_2 = L2_2.Append
  
  function L4_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3
    L1_3 = MrxGuiHudMessage
    L1_3 = L1_3.ShowFailedMessage
    L2_3 = nil
    L3_3 = nil
    
    function L4_3()
      local L0_4, L1_4
      L0_4 = A1_2
      L0_4 = L0_4.fCallback
      if L0_4 then
        L0_4 = A1_2
        L0_4 = L0_4.fCallback
        L1_4 = A1_2
        L1_4 = L1_4.tCallbackData
        L0_4(L1_4)
      end
      L0_4 = A0_3
      L1_4 = L0_4
      L0_4 = L0_4.FinishItem
      L0_4(L1_4)
    end
    
    L1_3(L2_3, L3_3, L4_3)
  end
  
  L2_2(L3_2, L4_2)
end

L0_1.Failed = L1_1
L0_1 = HudInterface
L1_1 = {}
L0_1.Fanfare = L1_1
L0_1 = HudInterface
L0_1 = L0_1.Fanfare

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = "contract"
  L3_2 = A1_2.sType
  if "wager" == L3_2 then
    L2_2 = "wager"
  else
    L3_2 = A1_2.sType
    if "mission" == L3_2 then
      L2_2 = "mission"
    end
  end
  L3_2 = _tFanfareQueue
  L4_2 = L3_2
  L3_2 = L3_2.Append
  
  function L5_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3
    L1_3 = MrxGuiHudMessage
    L1_3 = L1_3.CreateFanfare
    L2_3 = L2_2
    L1_3(L2_3)
    L1_3 = MrxGuiHudMessage
    L1_3 = L1_3.SetFanfareParameters
    L2_3 = A1_2
    L2_3 = L2_3.sProfileName1
    L3_3 = A1_2
    L3_3 = L3_3.sProfileName2
    L4_3 = A1_2
    L4_3 = L4_3.sCancelMsg
    L5_3 = A1_2
    L5_3 = L5_3.bAllowRetry
    L1_3(L2_3, L3_3, L4_3, L5_3)
    L1_3 = MrxGuiHudMessage
    L1_3 = L1_3.SetFanfareCompleteCallback
    
    function L2_3(...)
      local L1_4, L2_4
      L1_4 = A1_2
      L1_4 = L1_4.fCallback
      if L1_4 then
        L1_4 = A1_2
        L1_4 = L1_4.fCallback
        L2_4 = ...
        L1_4(L2_4)
      end
      L1_4 = A0_3
      L2_4 = L1_4
      L1_4 = L1_4.FinishItem
      L1_4(L2_4)
    end
    
    L3_3 = A1_2
    L3_3 = L3_3.tCallbackData
    L1_3(L2_3, L3_3)
    L2_3 = A0_3
    L1_3 = A0_3.FinishItem
    L1_3(L2_3)
  end
  
  L3_2(L4_2, L5_2)
  L3_2 = true
  return L3_2
end

L0_1.Create = L1_1
L0_1 = HudInterface
L0_1 = L0_1.Fanfare

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A1_2.sDescription
  L3_2 = A1_2.nValue
  L4_2 = A1_2.sValueType
  L5_2 = A1_2.nPlayer
  L6_2 = _tFanfareQueue
  L7_2 = L6_2
  L6_2 = L6_2.Append
  
  function L8_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3
    L1_3 = MrxGuiHudMessage
    L1_3 = L1_3.AddFanfareLineItem
    L2_3 = L2_2
    L3_3 = L3_2
    L4_3 = L4_2
    L5_3 = L5_2
    L1_3(L2_3, L3_3, L4_3, L5_3)
    L2_3 = A0_3
    L1_3 = A0_3.FinishItem
    L1_3(L2_3)
  end
  
  L6_2(L7_2, L8_2)
  L6_2 = true
  return L6_2
end

L0_1.AddItem = L1_1
L0_1 = Hud
L0_1 = L0_1.Fanfare

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _tFanfareQueue
  L3_2 = L2_2
  L2_2 = L2_2.Append
  
  function L4_2(A0_3)
    local L1_3, L2_3
    L1_3 = MrxGuiHudMessage
    L1_3 = L1_3.CommenceFanfare
    L2_3 = A1_2
    L2_3 = L2_3.nSlowdownDuration
    L1_3(L2_3)
  end
  
  L2_2(L3_2, L4_2)
  L2_2 = true
  return L2_2
end

L0_1.Commence = L1_1
L0_1 = HudInterface
L1_1 = {}
L0_1.SupportFanfare = L1_1
L0_1 = Hud
L0_1 = L0_1.SupportFanfare

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _tFanfareQueue
  L3_2 = L2_2
  L2_2 = L2_2.Append
  
  function L4_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = MrxGuiHudMessage
    L1_3 = L1_3.CreateFanfare
    L2_3 = "support"
    L1_3(L2_3)
    L1_3 = MrxGuiHudMessage
    L1_3 = L1_3.SetFanfareCompleteCallback
    
    function L2_3(...)
      local L1_4, L2_4
      L1_4 = A1_2
      L1_4 = L1_4.fCallback
      if L1_4 then
        L1_4 = A1_2
        L1_4 = L1_4.fCallback
        L2_4 = ...
        L1_4(L2_4)
      end
      L1_4 = A0_3
      L2_4 = L1_4
      L1_4 = L1_4.FinishItem
      L1_4(L2_4)
    end
    
    L3_3 = A1_2
    L3_3 = L3_3.tCallbackData
    L1_3(L2_3, L3_3)
    L2_3 = A0_3
    L1_3 = A0_3.FinishItem
    L1_3(L2_3)
  end
  
  L2_2(L3_2, L4_2)
  L2_2 = true
  return L2_2
end

L0_1.Create = L1_1
L0_1 = Hud
L0_1 = L0_1.SupportFanfare

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _tFanfareQueue
  L3_2 = L2_2
  L2_2 = L2_2.Append
  
  function L4_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L1_3 = MrxGuiHudMessage
    L1_3 = L1_3.SupportFanfareAddItem
    L2_3 = A1_2
    L2_3 = L2_3.sTexture
    L3_3 = A1_2
    L3_3 = L3_3.sItemName
    L4_3 = A1_2
    L4_3 = L4_3.sFaction
    L5_3 = A1_2
    L5_3 = L5_3.sContactName
    L6_3 = A1_2
    L6_3 = L6_3.sBlipName
    L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
    L2_3 = A0_3
    L1_3 = A0_3.FinishItem
    L1_3(L2_3)
  end
  
  L2_2(L3_2, L4_2)
  L2_2 = true
  return L2_2
end

L0_1.AddItem = L1_1
L0_1 = Hud
L0_1 = L0_1.SupportFanfare

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _tFanfareQueue
  L3_2 = L2_2
  L2_2 = L2_2.Append
  
  function L4_2(A0_3)
    local L1_3
    L1_3 = MrxGuiHudMessage
    L1_3 = L1_3.SupportFanfareCommence
    L1_3()
  end
  
  L2_2(L3_2, L4_2)
  L2_2 = true
  return L2_2
end

L0_1.Commence = L1_1
L0_1 = HudInterface
L1_1 = {}
L0_1.ContactFanfare = L1_1
L0_1 = Hud
L0_1 = L0_1.ContactFanfare

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _tFanfareQueue
  L3_2 = L2_2
  L2_2 = L2_2.Append
  
  function L4_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3
    L1_3 = MrxGuiHudMessage
    L1_3 = L1_3.CreateFanfare
    L2_3 = "contact"
    L1_3(L2_3)
    L1_3 = MrxGuiHudMessage
    L1_3 = L1_3.SetFanfareCompleteCallback
    
    function L2_3(...)
      local L1_4, L2_4
      L1_4 = A1_2
      L1_4 = L1_4.fCallback
      if L1_4 then
        L1_4 = A1_2
        L1_4 = L1_4.fCallback
        L2_4 = ...
        L1_4(L2_4)
      end
      L1_4 = A0_3
      L2_4 = L1_4
      L1_4 = L1_4.FinishItem
      L1_4(L2_4)
    end
    
    L3_3 = A1_2
    L3_3 = L3_3.tCallbackData
    L1_3(L2_3, L3_3)
    L1_3 = MrxGuiHudMessage
    L1_3 = L1_3.ContactFanfareCommence
    L2_3 = "s"
    L3_3 = "s"
    L4_3 = "s"
    L1_3(L2_3, L3_3, L4_3)
  end
  
  L2_2(L3_2, L4_2)
  L2_2 = true
  return L2_2
end

L0_1.Commence = L1_1
L0_1 = HudInterface
L1_1 = {}
L0_1.CardFanfare = L1_1
L0_1 = Hud
L0_1 = L0_1.CardFanfare

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _tFanfareQueue
  L3_2 = L2_2
  L2_2 = L2_2.Append
  
  function L4_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
    L1_3 = MrxGuiHudMessage
    L1_3 = L1_3.CreateFanfare
    L2_3 = "card"
    L3_3 = A1_2
    L3_3 = L3_3.sFaction
    L1_3(L2_3, L3_3)
    L1_3 = MrxGuiHudMessage
    L1_3 = L1_3.CardFanfareSetParameters
    L2_3 = A1_2
    L2_3 = L2_3.sTitle
    L3_3 = A1_2
    L3_3 = L3_3.sName
    L4_3 = A1_2
    L4_3 = L4_3.sJobTitle
    L5_3 = A1_2
    L5_3 = L5_3.sPhone1
    L6_3 = A1_2
    L6_3 = L6_3.sPhone2
    L7_3 = A1_2
    L7_3 = L7_3.sEmail
    L8_3 = A1_2
    L8_3 = L8_3.nDisplayTime
    L1_3(L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3)
    L1_3 = MrxGuiHudMessage
    L1_3 = L1_3.SetFanfareCompleteCallback
    
    function L2_3(...)
      local L1_4, L2_4
      L1_4 = A1_2
      L1_4 = L1_4.fCallback
      if L1_4 then
        L1_4 = A1_2
        L1_4 = L1_4.fCallback
        L2_4 = ...
        L1_4(L2_4)
      end
      L1_4 = A0_3
      L2_4 = L1_4
      L1_4 = L1_4.FinishItem
      L1_4(L2_4)
    end
    
    L3_3 = A1_2
    L3_3 = L3_3.tCallbackData
    L1_3(L2_3, L3_3)
    L1_3 = MrxGuiHudMessage
    L1_3 = L1_3.CardFanfareCommence
    L1_3()
  end
  
  L2_2(L3_2, L4_2)
end

L0_1.Commence = L1_1
L0_1 = Hud
L1_1 = {}
L0_1.TextFanfare = L1_1
L0_1 = Hud
L0_1 = L0_1.TextFanfare

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _tFanfareQueue
  L3_2 = L2_2
  L2_2 = L2_2.Append
  
  function L4_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
    L1_3 = MrxGuiHudMessage
    L1_3 = L1_3.ShowTextFanfare
    L2_3 = nil
    L3_3 = A1_2
    L3_3 = L3_3.sLine1
    L4_3 = A1_2
    L4_3 = L4_3.sLine2
    L5_3 = A1_2
    L5_3 = L5_3.nEntranceTime
    L6_3 = A1_2
    L6_3 = L6_3.nDisplayTime
    L7_3 = A1_2
    L7_3 = L7_3.nFadeTime
    
    function L8_3(...)
      local L1_4, L2_4
      L1_4 = A1_2
      L1_4 = L1_4.fCallback
      if L1_4 then
        L1_4 = A1_2
        L1_4 = L1_4.fCallback
        L2_4 = ...
        L1_4(L2_4)
      end
      L1_4 = A0_3
      L2_4 = L1_4
      L1_4 = L1_4.FinishItem
      L1_4(L2_4)
    end
    
    L9_3 = A1_2
    L9_3 = L9_3.tCallbackData
    L1_3(L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3)
  end
  
  L2_2(L3_2, L4_2)
end

L0_1.Commence = L1_1
L0_1 = HudInterface
L1_1 = {}
L0_1.EventFanfare = L1_1
L0_1 = Hud
L0_1 = L0_1.EventFanfare

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A1_2.vText
  if not L2_2 then
    L2_2 = A1_2.sText
    if L2_2 then
      L2_2 = A1_2.sText
      A1_2.vText = L2_2
    end
  end
  L2_2 = _tFanfareQueue
  L3_2 = L2_2
  L2_2 = L2_2.Append
  
  function L4_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3
    L1_3 = MrxGuiHudMessage
    L1_3 = L1_3.ShowEventFanfare
    L2_3 = A1_2
    L2_3 = L2_3.sType
    L3_3 = A1_2
    L3_3 = L3_3.vText
    
    function L4_3(...)
      local L1_4, L2_4
      L1_4 = A1_2
      L1_4 = L1_4.fCallback
      if L1_4 then
        L1_4 = A1_2
        L1_4 = L1_4.fCallback
        L2_4 = ...
        L1_4(L2_4)
      end
      L1_4 = A0_3
      L2_4 = L1_4
      L1_4 = L1_4.FinishItem
      L1_4(L2_4)
    end
    
    L5_3 = A1_2
    L5_3 = L5_3.tCallbackData
    L1_3(L2_3, L3_3, L4_3, L5_3)
    L1_3 = type
    L2_3 = A1_2
    L2_3 = L2_3.vText
    L1_3 = L1_3(L2_3)
    if "string" == L1_3 then
      L1_3 = Pda
      L1_3 = L1_3.Database
      L2_3 = L1_3
      L1_3 = L1_3.AddLogEntry
      L3_3 = {}
      L3_3.sType = "event"
      L3_3.sName = ""
      L4_3 = MrxGuiHudMessage
      L4_3 = L4_3.GetEventFanfareTitle
      L5_3 = A1_2
      L5_3 = L5_3.sType
      L4_3 = L4_3(L5_3)
      L5_3 = ": "
      L6_3 = A1_2
      L6_3 = L6_3.vText
      L4_3 = L4_3 .. L5_3 .. L6_3
      L3_3.sMessage = L4_3
      L3_3.sColor = "3399FF"
      L1_3(L2_3, L3_3)
    else
      L1_3 = type
      L2_3 = A1_2
      L2_3 = L2_3.vText
      L1_3 = L1_3(L2_3)
      if "table" == L1_3 then
        L1_3 = ipairs
        L2_3 = A1_2
        L2_3 = L2_3.vText
        L1_3, L2_3, L3_3 = L1_3(L2_3)
        for L4_3, L5_3 in L1_3, L2_3, L3_3 do
          L6_3 = Pda
          L6_3 = L6_3.Database
          L7_3 = L6_3
          L6_3 = L6_3.AddLogEntry
          L8_3 = {}
          L8_3.sType = "event"
          L8_3.sName = ""
          L9_3 = MrxGuiHudMessage
          L9_3 = L9_3.GetEventFanfareTitle
          L10_3 = A1_2
          L10_3 = L10_3.sType
          L9_3 = L9_3(L10_3)
          L10_3 = ": "
          L11_3 = L5_3
          L9_3 = L9_3 .. L10_3 .. L11_3
          L8_3.sMessage = L9_3
          L8_3.sColor = "3399FF"
          L6_3(L7_3, L8_3)
        end
      end
    end
  end
  
  L2_2(L3_2, L4_2)
end

L0_1.Commence = L1_1
L0_1 = HudInterface
L1_1 = {}
L0_1.Cinematic = L1_1
L0_1 = HudInterface
L0_1 = L0_1.Cinematic

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = MrxGuiBase
  L2_2 = L2_2.GetWidgetByName
  L3_2 = "Cinematic Placeholder"
  L2_2 = L2_2(L3_2)
  L4_2 = L2_2
  L3_2 = L2_2.ShowMovie
  L5_2 = A1_2.sMovie
  L6_2 = A1_2.nFadeInTime
  L7_2 = A1_2.nFadeOutTime
  L8_2 = A1_2.fCallback
  L9_2 = A1_2.tCallbackData
  L10_2 = A1_2.bSubtitles
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
end

L0_1.Show = L1_1
L0_1 = HudInterface
L0_1 = L0_1.Cinematic

function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxGuiBase
  L1_2 = L1_2.GetWidgetByName
  L2_2 = "Cinematic Placeholder"
  L1_2 = L1_2(L2_2)
  L3_2 = L1_2
  L2_2 = L1_2.Hide
  L2_2(L3_2)
end

L0_1.Hide = L1_1
L0_1 = HudInterface
L0_1 = L0_1.Cinematic

function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxGuiBase
  L1_2 = L1_2.GetWidgetByName
  L2_2 = "Cinematic Placeholder"
  L1_2 = L1_2(L2_2)
  L3_2 = L1_2
  L2_2 = L1_2.Play
  L2_2(L3_2)
end

L0_1.Play = L1_1
L0_1 = HudInterface
L0_1 = L0_1.Cinematic

function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxGuiBase
  L1_2 = L1_2.GetWidgetByName
  L2_2 = "Cinematic Placeholder"
  L1_2 = L1_2(L2_2)
  L3_2 = L1_2
  L2_2 = L1_2.Pause
  L2_2(L3_2)
end

L0_1.Pause = L1_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2
  L4_2 = Net
  L4_2 = L4_2.IsServer
  L4_2 = L4_2()
  if not L4_2 then
    L4_2 = MrxSoundCategories
    L4_2 = L4_2.DuckMasterVolume
    L5_2 = 0.5
    L4_2(L5_2)
    L4_2 = Hud
    L4_2 = L4_2.Cinematic
    L5_2 = L4_2
    L4_2 = L4_2.Show
    L6_2 = {}
    L6_2.sMovie = A0_2
    L6_2.nFadeInTime = A1_2
    L6_2.nFadeOutTime = A2_2
    L6_2.bSubtitles = A3_2
    L4_2(L5_2, L6_2)
  end
end

NetClientShowMovie = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = Net
  L0_2 = L0_2.IsServer
  L0_2 = L0_2()
  if not L0_2 then
    L0_2 = MrxSoundCategories
    L0_2 = L0_2.UnduckMasterVolume
    L1_2 = 0.5
    L0_2(L1_2)
    L0_2 = MrxGuiBase
    L0_2 = L0_2.GetWidgetByName
    L1_2 = "Cinematic Placeholder"
    L0_2 = L0_2(L1_2)
    L2_2 = L0_2
    L1_2 = L0_2.HideSlow
    L1_2(L2_2)
  end
end

NetClientHideMovie = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = Net
  L0_2 = L0_2.IsServer
  L0_2 = L0_2()
  if not L0_2 then
    L0_2 = MrxGuiBase
    L0_2 = L0_2.GetWidgetByName
    L1_2 = "Cinematic Placeholder"
    L0_2 = L0_2(L1_2)
    if L0_2 then
      L2_2 = L0_2
      L1_2 = L0_2.IsMovieRunning
      return L1_2(L2_2)
    else
      L1_2 = false
      return L1_2
    end
  end
end

NetClientIsMovieRunning = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = Net
  L0_2 = L0_2.IsServer
  L0_2 = L0_2()
  if not L0_2 then
    L0_2 = MrxGuiBase
    L0_2 = L0_2.GetWidgetByName
    L1_2 = "Cinematic Placeholder"
    L0_2 = L0_2(L1_2)
    if L0_2 then
      L2_2 = L0_2
      L1_2 = L0_2.IsMovieHiding
      return L1_2(L2_2)
    else
      L1_2 = false
      return L1_2
    end
  end
end

NetClientIsMovieHiding = L0_1
L0_1 = HudInterface
L1_1 = {}
L0_1.CinematicPlaceholder = L1_1
L0_1 = HudInterface
L0_1 = L0_1.CinematicPlaceholder

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = MrxGuiBase
  L2_2 = L2_2.GetWidgetByName
  L3_2 = "Cinematic Placeholder"
  L2_2 = L2_2(L3_2)
  L4_2 = L2_2
  L3_2 = L2_2.Show
  L5_2 = A1_2.sTexture
  L6_2 = A1_2.sCaption
  L7_2 = A1_2.nFadeInTime
  L8_2 = A1_2.nFadeOutTime
  L9_2 = A1_2.fCallback
  L10_2 = A1_2.tCallbackData
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
end

L0_1.Show = L1_1
L0_1 = HudInterface
L0_1 = L0_1.CinematicPlaceholder

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = MrxGuiBase
  L2_2 = L2_2.GetWidgetByName
  L3_2 = "Cinematic Placeholder"
  L2_2 = L2_2(L3_2)
  L4_2 = L2_2
  L3_2 = L2_2.Hide
  L3_2(L4_2)
end

L0_1.Hide = L1_1
L0_1 = HudInterface
L1_1 = {}
L0_1.FactionDisplay = L1_1
L0_1 = HudInterface
L0_1 = L0_1.FactionDisplay

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "Faction Display"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.ShowAll
    L10_2 = A1_2.nDuration
    L8_2(L9_2, L10_2)
  end
end

L0_1.Show = L1_1
L0_1 = HudInterface
L0_1 = L0_1.FactionDisplay

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = Net
  L2_2 = L2_2.IsClient
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = A1_2.bForceOnClient
    if not L2_2 then
      return
    end
  end
  L2_2 = Net
  L2_2 = L2_2.IsServer
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = Net
    L2_2 = L2_2.SendEvent_PursuitMessage
    L3_2 = 0
    L4_2 = A1_2.sFaction
    L5_2 = A1_2.nValue
    L2_2(L3_2, L4_2, L5_2)
  end
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "Faction Display"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.SetValue
    L10_2 = A1_2.sFaction
    L11_2 = A1_2.nValue
    L12_2 = A1_2.bInitialize
    L8_2(L9_2, L10_2, L11_2, L12_2)
  end
end

L0_1.SetValue = L1_1
L0_1 = HudInterface
L0_1 = L0_1.FactionDisplay

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "Faction Display"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.SetInsideFactionZone
    L10_2 = A1_2.sFaction
    L11_2 = A1_2.bInside
    L12_2 = A1_2.bInitialize
    L8_2(L9_2, L10_2, L11_2, L12_2)
  end
end

L0_1.SetInsideFactionZone = L1_1
L0_1 = HudInterface
L0_1 = L0_1.FactionDisplay

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = MrxGuiHudFactionGauge
  L2_2 = L2_2.SetLevels
  L3_2 = A1_2.tLevelThresholds
  L4_2 = A1_2.tLevelNames
  L5_2 = A1_2.sPursuitName
  L6_2 = A1_2.bDisplayResult
  L2_2(L3_2, L4_2, L5_2, L6_2)
end

L0_1.ConfigureThresholds = L1_1
L0_1 = HudInterface
L0_1 = L0_1.FactionDisplay

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "Faction Display"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.AddFactionGauge
    L10_2 = A1_2.sFaction
    L11_2 = A1_2.sTexture
    L8_2(L9_2, L10_2, L11_2)
  end
end

L0_1.AddMeter = L1_1
L0_1 = HudInterface
L0_1 = L0_1.FactionDisplay

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "Faction Display"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.StartTimer
    L10_2 = A1_2.sFaction
    L11_2 = A1_2.nDuration
    L12_2 = A1_2.fCallback
    L13_2 = A1_2.tCallbackData
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  end
end

L0_1.StartTimer = L1_1
L0_1 = HudInterface
L0_1 = L0_1.FactionDisplay

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = Net
  L2_2 = L2_2.IsClient
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = A1_2.bForceOnClient
    if not L2_2 then
      return
    end
  end
  L2_2 = Net
  L2_2 = L2_2.IsServer
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = Net
    L2_2 = L2_2.SendEvent_PursuitMessage
    L3_2 = 1
    L4_2 = A1_2.sFaction
    L5_2 = A1_2.nDuration
    L2_2(L3_2, L4_2, L5_2)
  end
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "Faction Display"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.StartPursuit
    L10_2 = A1_2.sFaction
    L11_2 = A1_2.nDuration
    L12_2 = A1_2.fCallback
    L13_2 = A1_2.tCallbackData
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  end
end

L0_1.StartPursuit = L1_1
L0_1 = HudInterface
L0_1 = L0_1.FactionDisplay

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = Net
  L2_2 = L2_2.IsClient
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = A1_2.bForceOnClient
    if not L2_2 then
      return
    end
  end
  L2_2 = Net
  L2_2 = L2_2.IsServer
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = Net
    L2_2 = L2_2.SendEvent_PursuitMessage
    L3_2 = 2
    L4_2 = A1_2.sFaction
    L2_2(L3_2, L4_2)
  end
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "Faction Display"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.HideGauge
    L10_2 = A1_2.sFaction
    L8_2(L9_2, L10_2)
  end
end

L0_1.HideMeter = L1_1
L0_1 = HudInterface
L0_1 = L0_1.FactionDisplay

function L1_1(A0_2, A1_2)
end

L0_1.RemoveMeter = L1_1
L0_1 = HudInterface
L0_1 = L0_1.FactionDisplay

function L1_1(A0_2, A1_2)
end

L0_1.RemoveAllMeters = L1_1
L0_1 = HudInterface
L1_1 = {}
L1_1.sName = "Subtitle Buffer"
L0_1.SubtitleBuffer = L1_1
L0_1 = HudInterface
L0_1 = L0_1.SubtitleBuffer
L1_1 = HudInterface
L1_1 = L1_1.MessageBox
L1_1 = L1_1.AddMessage
L0_1.AddMessage = L1_1
L0_1 = HudInterface
L0_1 = L0_1.SubtitleBuffer
L1_1 = HudInterface
L1_1 = L1_1.MessageBox
L1_1 = L1_1.ModifyPendingMessage
L0_1.ModifyPendingMessage = L1_1
L0_1 = HudInterface
L0_1 = L0_1.SubtitleBuffer
L1_1 = HudInterface
L1_1 = L1_1.MessageBox
L1_1 = L1_1.RemovePendingMessage
L0_1.RemovePendingMessage = L1_1
L0_1 = HudInterface
L0_1 = L0_1.SubtitleBuffer
L1_1 = HudInterface
L1_1 = L1_1.MessageBox
L1_1 = L1_1.Clear
L0_1.Clear = L1_1
L0_1 = HudInterface
L1_1 = {}
L0_1.Shop = L1_1
L0_1 = HudInterface
L0_1 = L0_1.Shop

function L1_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = MrxGuiSupportShop
  L2_2 = L2_2.Create
  L3_2 = A1_2.uPlayer
  return L2_2(L3_2)
end

L0_1.Create = L1_1
L0_1 = HudInterface
L0_1 = L0_1.Shop

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = MrxGuiSupportShop
  L2_2 = L2_2.AddItem
  L3_2 = A1_2.uPlayer
  L4_2 = A1_2.sName
  L5_2 = A1_2.nCashCost
  L6_2 = A1_2.nCurrentStock
  L7_2 = A1_2.nMaxStock
  L8_2 = A1_2.bUnlocked
  L9_2 = A1_2.sId
  if not L9_2 then
    L9_2 = A1_2.sName
  end
  L10_2 = A1_2.bFuelTank
  L11_2 = A1_2.nFuelQuantity
  L12_2 = A1_2.sRawName
  return L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
end

L0_1.AddItem = L1_1
L0_1 = HudInterface
L0_1 = L0_1.Shop

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L2_2 = MrxGuiSupportShop
  L2_2 = L2_2.AddItemFull
  L3_2 = A1_2.uPlayer
  L4_2 = A1_2.sName
  L5_2 = A1_2.sDescription
  L6_2 = A1_2.sTexture
  L7_2 = A1_2.nCashCost
  L8_2 = A1_2.nCurrentStock
  L9_2 = A1_2.nMaxStock
  L10_2 = A1_2.bUnlocked
  L11_2 = A1_2.sId
  if not L11_2 then
    L11_2 = A1_2.sName
  end
  L12_2 = A1_2.bFuelTank
  L13_2 = A1_2.bMarkAsNew
  L14_2 = A1_2.nFuelQuantity
  L15_2 = A1_2.sRawName
  return L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
end

L0_1.AddItemFull = L1_1
L0_1 = Hud
L0_1 = L0_1.Shop

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = MrxGuiSupportShop
  L2_2 = L2_2.SetCallback
  L3_2 = A1_2.uPlayer
  L4_2 = A1_2.fCallback
  L5_2 = A1_2.tCallbackData
  return L2_2(L3_2, L4_2, L5_2)
end

L0_1.SetCallback = L1_1
L0_1 = Hud
L0_1 = L0_1.Shop

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = MrxGuiSupportShop
  L2_2 = L2_2.SetCloseCallback
  L3_2 = A1_2.uPlayer
  L4_2 = A1_2.fCallback
  L5_2 = A1_2.tCallbackData
  return L2_2(L3_2, L4_2, L5_2)
end

L0_1.SetCloseCallback = L1_1
L0_1 = Hud
L0_1 = L0_1.Shop

function L1_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = MrxGuiSupportShop
  L2_2 = L2_2.Commence
  L3_2 = A1_2.uPlayer
  return L2_2(L3_2)
end

L0_1.Commence = L1_1
L0_1 = Hud
L0_1 = L0_1.Shop

function L1_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = MrxGuiSupportShop
  L2_2 = L2_2.Close
  L3_2 = A1_2.uPlayer
  return L2_2(L3_2)
end

L0_1.Close = L1_1
L0_1 = HudInterface
L1_1 = {}
L0_1.ResourceCounter = L1_1
L0_1 = HudInterface
L0_1 = L0_1.ResourceCounter

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = nil
  L4_2 = "money"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = nil
  L4_2 = nil
  L5_2 = nil
  L6_2 = type
  L7_2 = A1_2
  L6_2 = L6_2(L7_2)
  if "number" == L6_2 then
    L3_2 = A1_2
  else
    L3_2 = A1_2.nValue
    L4_2 = A1_2.sReason
    L5_2 = A1_2.nIncrement
  end
  L6_2 = pairs
  L7_2 = L2_2
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  for L9_2, L10_2 in L6_2, L7_2, L8_2 do
    L12_2 = L10_2
    L11_2 = L10_2.SetValue
    L13_2 = L3_2
    L14_2 = L4_2
    L15_2 = L5_2
    L11_2(L12_2, L13_2, L14_2, L15_2)
    L12_2 = L10_2
    L11_2 = L10_2.Show
    L11_2(L12_2)
  end
end

L0_1.SetCash = L1_1
L0_1 = HudInterface
L0_1 = L0_1.ResourceCounter

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = nil
  L4_2 = "fuel"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = nil
  L4_2 = nil
  L5_2 = nil
  L6_2 = type
  L7_2 = A1_2
  L6_2 = L6_2(L7_2)
  if "number" == L6_2 then
    L3_2 = A1_2
  else
    L3_2 = A1_2.nValue
    L6_2 = tonumber
    L7_2 = A1_2.nMax
    L6_2 = L6_2(L7_2)
    L4_2 = L6_2
    L5_2 = A1_2.nIncrement
  end
  if L4_2 then
    L6_2 = "/"
    L7_2 = L4_2
    L4_2 = L6_2 .. L7_2
  end
  L6_2 = pairs
  L7_2 = L2_2
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  for L9_2, L10_2 in L6_2, L7_2, L8_2 do
    L12_2 = L10_2
    L11_2 = L10_2.SetValue
    L13_2 = L3_2
    L14_2 = nil
    L15_2 = L5_2
    L11_2(L12_2, L13_2, L14_2, L15_2)
    if L4_2 then
      L12_2 = L10_2
      L11_2 = L10_2.SetAppendedString
      L13_2 = L4_2
      L11_2(L12_2, L13_2)
    end
    L12_2 = L10_2
    L11_2 = L10_2.Show
    L11_2(L12_2)
  end
end

L0_1.SetFuel = L1_1
L0_1 = HudInterface
L0_1 = L0_1.ResourceCounter

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = nil
  L4_2 = "money"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.SetSuppressed
    L10_2 = A1_2.bSuppressCash
    L8_2(L9_2, L10_2)
  end
  L3_2 = _GetWidgetsForPlayers
  L4_2 = nil
  L5_2 = "fuel"
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = pairs
  L5_2 = L3_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L10_2 = L8_2
    L9_2 = L8_2.SetSuppressed
    L11_2 = A1_2.bSuppressFuel
    L9_2(L10_2, L11_2)
  end
end

L0_1.SetSuppressed = L1_1
L0_1 = HudInterface
L0_1 = L0_1.ResourceCounter

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "money"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.Show
    L10_2 = A1_2.nDuration
    if not L10_2 then
      L10_2 = 3
    end
    L8_2(L9_2, L10_2)
  end
  L3_2 = _GetWidgetsForPlayers
  L4_2 = A1_2.vPlayer
  L5_2 = "fuel"
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = pairs
  L5_2 = L3_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L10_2 = L8_2
    L9_2 = L8_2.Show
    L11_2 = A1_2.nDuration
    if not L11_2 then
      L11_2 = 3
    end
    L9_2(L10_2, L11_2)
  end
end

L0_1.Show = L1_1
L0_1 = HudInterface
L0_1 = L0_1.ResourceCounter

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "money"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.Hide
    L8_2(L9_2)
  end
  L3_2 = _GetWidgetsForPlayers
  L4_2 = A1_2.vPlayer
  L5_2 = "fuel"
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = pairs
  L5_2 = L3_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L10_2 = L8_2
    L9_2 = L8_2.Hide
    L9_2(L10_2)
  end
end

L0_1.Hide = L1_1
L0_1 = HudInterface
L1_1 = {}
L0_1.Tutorial = L1_1
L0_1 = HudInterface
L0_1 = L0_1.Tutorial

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "tutorial"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.SetText
    L10_2 = A1_2.sText
    L8_2(L9_2, L10_2)
  end
end

L0_1.SetText = L1_1
L0_1 = HudInterface
L0_1 = L0_1.Tutorial

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L3_2 = type
  L4_2 = A1_2.vPlayer
  L3_2 = L3_2(L4_2)
  if "table" == L3_2 then
    L2_2 = vPlayer
  else
    L3_2 = type
    L4_2 = A1_2.vPlayer
    L3_2 = L3_2(L4_2)
    if "userdata" == L3_2 then
      L3_2 = {}
      L2_2 = L3_2
    else
      L3_2 = Player
      L3_2 = L3_2.GetAllPlayers
      L3_2 = L3_2()
      L2_2 = L3_2
    end
  end
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = MrxGuiTutorial
    L8_2 = L8_2.DisplayTutorialForObject
    L9_2 = L7_2
    L10_2 = A1_2.sMessage
    L11_2 = A1_2.uGuid
    L12_2 = A1_2.fCallback
    L13_2 = A1_2.tCallbackData
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  end
end

L0_1.ShowTutorialForObject = L1_1
L0_1 = HudInterface
L0_1 = L0_1.Tutorial

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L3_2 = type
  L4_2 = A1_2.vPlayer
  L3_2 = L3_2(L4_2)
  if "table" == L3_2 then
    L2_2 = vPlayer
  else
    L3_2 = type
    L4_2 = A1_2.vPlayer
    L3_2 = L3_2(L4_2)
    if "userdata" == L3_2 then
      L3_2 = {}
      L2_2 = L3_2
    else
      L3_2 = Player
      L3_2 = L3_2.GetAllPlayers
      L3_2 = L3_2()
      L2_2 = L3_2
    end
  end
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = MrxGuiTutorial
    L8_2 = L8_2.DisplayTutorial
    L9_2 = L7_2
    L10_2 = A1_2.sMessage
    L11_2 = A1_2.nX1
    L12_2 = A1_2.nY1
    L13_2 = A1_2.nX2
    L14_2 = A1_2.nY2
    L15_2 = A1_2.sHorizAnchor
    L16_2 = A1_2.sVertAnchor
    L17_2 = A1_2.fCallback
    L18_2 = A1_2.tCallbackData
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  end
end

L0_1.ShowTutorialOnscreen = L1_1
L0_1 = Hud
L1_1 = {}
L0_1.ClassyText = L1_1
L0_1 = Hud
L0_1 = L0_1.ClassyText

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "ClassyText"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.ShowText
    L10_2 = A1_2.sText
    L11_2 = nil
    L12_2 = A1_2.nY
    L13_2 = A1_2.nDuration
    L14_2 = nil
    L15_2 = A1_2.sJustification
    L16_2 = A1_2.sVertAnchor
    L17_2 = A1_2.sJustification
    L18_2 = A1_2.bExpand
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  end
end

L0_1.ShowText = L1_1
L0_1 = HudInterface
L1_1 = {}
L0_1.Satellite = L1_1
L0_1 = HudInterface
L0_1 = L0_1.Satellite

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "Satellite overlay"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.SetHelpText
    L10_2 = A1_2.sText
    if not L10_2 then
      L10_2 = " "
    end
    L8_2(L9_2, L10_2)
  end
end

L0_1.SetTutorialText = L1_1
L0_1 = PdaInterface

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "PDA"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.SetSuppressed
    L10_2 = A1_2.bSuppress
    L8_2(L9_2, L10_2)
  end
end

L0_1.SetSuppressed = L1_1
L0_1 = PdaInterface
L1_1 = {}
L0_1.Map = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Map

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "PDA"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.AddMapBlip
    L10_2 = A1_2.sName
    L11_2 = A1_2.nX
    L12_2 = A1_2.nY
    L13_2 = A1_2.sLabel
    L14_2 = A1_2.sDesc
    L15_2 = A1_2.uGuid
    L16_2 = A1_2.sTexture
    L17_2 = A1_2.sMission
    L18_2 = A1_2.nMeter
    L19_2 = A1_2.bSticky
    L20_2 = A1_2.bTodoList
    L21_2 = A1_2.sFaction
    if not L21_2 then
      L21_2 = "PMC"
    end
    L22_2 = A1_2.nSortOrder
    if not L22_2 then
      L22_2 = 5
    end
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2)
  end
  L3_2 = Net
  L3_2 = L3_2.IsServer
  L3_2 = L3_2()
  if L3_2 then
    L3_2 = A1_2.bDontNetSync
    if not L3_2 then
      L3_2 = 0
      L4_2 = A1_2.bSticky
      if L4_2 ~= nil then
        L4_2 = A1_2.bSticky
        if L4_2 then
          L3_2 = 1
        else
          L3_2 = 2
        end
      end
      L4_2 = nil
      L5_2 = A1_2.sTexture
      if L5_2 then
        L5_2 = MrxUtil
        L5_2 = L5_2.MarkerGetIndexByName_Pda
        L6_2 = A1_2.sTexture
        L5_2 = L5_2(L6_2)
        L4_2 = L5_2
      end
      L5_2 = Net
      L5_2 = L5_2.SendEvent_AddPdaObjective
      L6_2 = A1_2.sName
      L7_2 = A1_2.uGuid
      L8_2 = A1_2.sLabel
      L9_2 = L4_2
      L10_2 = WifMissionData
      L10_2 = L10_2.GetMissionIndexFromId
      L11_2 = A1_2.sMission
      L10_2 = L10_2(L11_2)
      L11_2 = L3_2
      L12_2 = A1_2.nSortOrder
      L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
    end
  end
end

L0_1.AddBlip = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Map

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "PDA"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.RemoveMapBlip
    L10_2 = A1_2.sName
    L8_2(L9_2, L10_2)
  end
  L3_2 = Net
  L3_2 = L3_2.IsServer
  L3_2 = L3_2()
  if L3_2 then
    L3_2 = A1_2.bDontNetSync
    if not L3_2 then
      L3_2 = Net
      L3_2 = L3_2.SendEvent_RemovePdaObjective
      L4_2 = A1_2.sName
      L3_2(L4_2)
    end
  end
end

L0_1.RemoveBlip = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Map

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "PDA"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.AddMapMission
    L10_2 = A1_2.sName
    L11_2 = A1_2.sLabel
    L12_2 = A1_2.sDesc
    L13_2 = A1_2.sFaction
    L14_2 = A1_2.sDefaultBlipTexture
    L15_2 = A1_2.sDefaultBlipLabel
    L16_2 = A1_2.bSuppress
    L17_2 = A1_2.bTrackable
    L18_2 = A1_2.nSortOrder
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  end
end

L0_1.AddMission = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Map

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "PDA"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.RemoveMapMission
    L10_2 = A1_2.sName
    L8_2(L9_2, L10_2)
  end
end

L0_1.RemoveMission = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Map

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "PDA"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.UpdateMapMission
    L10_2 = A1_2.sName
    L11_2 = A1_2.sLabel
    L12_2 = A1_2.sDesc
    L13_2 = A1_2.sFaction
    L14_2 = A1_2.sDefaultBlipTexture
    L15_2 = A1_2.sDefaultBlipLabel
    L16_2 = A1_2.bSuppress
    L17_2 = A1_2.bTrackable
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  end
end

L0_1.UpdateMission = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Map

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "PDA"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.SetSelectedMission
    L10_2 = A1_2.sName
    L11_2 = A1_2.bForceOnClient
    L8_2(L9_2, L10_2, L11_2)
  end
end

L0_1.SetSelectedMission = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Map

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = _GetWidgetsForPlayers
  L2_2 = Player
  L2_2 = L2_2.GetLocalPlayer
  L2_2 = L2_2()
  L3_2 = "PDA"
  L1_2 = L1_2(L2_2, L3_2)
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L8_2 = L6_2
    L7_2 = L6_2.GetSelectedMission
    return L7_2(L8_2)
  end
  L2_2 = nil
  return L2_2
end

L0_1.GetSelectedMission = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Map

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "PDA"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.AddLineRegion
    L10_2 = A1_2.uGuid
    L11_2 = A1_2.nRed
    L12_2 = A1_2.nGreen
    L13_2 = A1_2.nBlue
    L14_2 = A1_2.nAlpha
    L15_2 = A1_2.bInvert
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  end
end

L0_1.AddLineRegion = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Map

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "PDA"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.RemoveLineRegion
    L10_2 = A1_2.uGuid
    L8_2(L9_2, L10_2)
  end
end

L0_1.RemoveLineRegion = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Map

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "PDA"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.SetMissionTrackable
    L10_2 = A1_2.sName
    L11_2 = A1_2.bTrackable
    L8_2(L9_2, L10_2, L11_2)
  end
end

L0_1.SetMissionTrackable = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Map

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "PDA"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.SetMissionTrackCallback
    L10_2 = A1_2.fCallback
    L11_2 = A1_2.tCallbackData
    L8_2(L9_2, L10_2, L11_2)
  end
end

L0_1.SetMissionTrackCallback = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Map

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "PDA"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.SetMissionChangeAllowed
    L10_2 = A1_2.bAllow
    L8_2(L9_2, L10_2)
  end
end

L0_1.SetMissionChangeAllowed = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Map

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "PDA"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.SetFakePlayerLocation
    L10_2 = A1_2.nX
    L11_2 = A1_2.nY
    L12_2 = A1_2.nZ
    L8_2(L9_2, L10_2, L11_2, L12_2)
  end
end

L0_1.SetFakePlayerLocation = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Map

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "PDA"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.SetBeaconTutorialMode
    L10_2 = A1_2.bEnable
    L8_2(L9_2, L10_2)
  end
end

L0_1.SetBeaconTutorialMode = L1_1
L0_1 = PdaInterface
L1_1 = {}
L0_1.Support = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Support

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "PDA"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.AddSupport
    L10_2 = A1_2
    L8_2(L9_2, L10_2)
  end
end

L0_1.AddItem = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Support

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "PDA"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.RemoveSupport
    L10_2 = A1_2.sName
    L8_2(L9_2, L10_2)
  end
end

L0_1.RemoveItem = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Support

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "PDA"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.UpdateSupport
    L10_2 = A1_2.sName
    L11_2 = A1_2.sDescription
    L12_2 = A1_2.sIcon
    L13_2 = A1_2.nStock
    L14_2 = A1_2.nMaxStock
    L15_2 = A1_2.nFuelCost
    L16_2 = A1_2.oSupport
    L17_2 = A1_2.sType
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  end
end

L0_1.UpdateItem = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Support

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "PDA"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.SetEquippedSupport
    L10_2 = A1_2.sName
    L11_2 = A1_2.sId
    L8_2(L9_2, L10_2, L11_2)
  end
end

L0_1.SetEquippedItem = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Support

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = MrxGui
  L2_2 = L2_2.GetWidgetByNameAndOwner
  L3_2 = "PDA"
  L4_2 = A1_2.uPlayer
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    L4_2 = L2_2
    L3_2 = L2_2.ReadEquippedSupport
    return L3_2(L4_2)
  end
end

L0_1.ReadEquippedSupport = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Support

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = MrxGui
  L2_2 = L2_2.GetWidgetByNameAndOwner
  L3_2 = "PDA"
  L4_2 = A1_2.uPlayer
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    L4_2 = L2_2
    L3_2 = L2_2.RestoreEquippedSupport
    L5_2 = A1_2.vSupport
    L3_2(L4_2, L5_2)
  end
end

L0_1.RestoreEquippedSupport = L1_1
L0_1 = PdaInterface
L1_1 = {}
L0_1.Database = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Database

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "PDA"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.SetFactionAttitude
    L10_2 = A1_2.sName
    L11_2 = A1_2.sTexture
    L12_2 = A1_2.nAttitude
    L8_2(L9_2, L10_2, L11_2, L12_2)
  end
end

L0_1.SetFactionAttitude = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Database

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "PDA"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.AddLogEntry
    L10_2 = A1_2.sType
    L11_2 = A1_2.sName
    L12_2 = A1_2.sMessage
    L13_2 = A1_2.sColor
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  end
end

L0_1.AddLogEntry = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Database

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "PDA"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.AddHelpEntry
    L10_2 = A1_2.sTitle
    L11_2 = A1_2.sText
    L12_2 = A1_2.sIcon
    L8_2(L9_2, L10_2, L11_2, L12_2)
  end
end

L0_1.AddHelpEntry = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Database

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "PDA"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.AddDossierEntry
    L10_2 = A1_2.sTitle
    L11_2 = A1_2.sText
    L12_2 = A1_2.sIcon
    L8_2(L9_2, L10_2, L11_2, L12_2)
  end
end

L0_1.AddDossierEntry = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Database

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "PDA"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.AddStatisticCategory
    L10_2 = A1_2.sCategory
    L11_2 = A1_2.sIcon
    L8_2(L9_2, L10_2, L11_2)
  end
end

L0_1.AddStatisticCategory = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.Database

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = _GetWidgetsForPlayers
  L3_2 = A1_2.vPlayer
  L4_2 = "PDA"
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.AddStatisticEntry
    L10_2 = A1_2.sCategory
    L11_2 = A1_2.sDesc
    L12_2 = A1_2.sData
    L8_2(L9_2, L10_2, L11_2, L12_2)
  end
end

L0_1.AddStatisticEntry = L1_1
L0_1 = PdaInterface
L1_1 = {}
L1_1.sName = "PDA Subtitle Buffer"
L0_1.SubtitleBuffer = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.SubtitleBuffer
L1_1 = HudInterface
L1_1 = L1_1.MessageBox
L1_1 = L1_1.AddMessage
L0_1.AddMessage = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.SubtitleBuffer
L1_1 = HudInterface
L1_1 = L1_1.MessageBox
L1_1 = L1_1.ModifyPendingMessage
L0_1.ModifyPendingMessage = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.SubtitleBuffer
L1_1 = HudInterface
L1_1 = L1_1.MessageBox
L1_1 = L1_1.RemovePendingMessage
L0_1.RemovePendingMessage = L1_1
L0_1 = PdaInterface
L0_1 = L0_1.SubtitleBuffer
L1_1 = HudInterface
L1_1 = L1_1.MessageBox
L1_1 = L1_1.Clear
L0_1.Clear = L1_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2, A9_2, A10_2, A11_2, A12_2, A13_2, A14_2)
  local L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2
  L15_2 = MrxGuiBase
  L15_2 = L15_2.GetWidgetByNameAndOwner
  L16_2 = "Minimap"
  L17_2 = Player
  L17_2 = L17_2.GetLocalPlayer
  L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2 = L17_2()
  L15_2 = L15_2(L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2)
  if L15_2 then
    L17_2 = L15_2
    L16_2 = L15_2.AddObjective
    L18_2 = A0_2
    L19_2 = A1_2
    L20_2 = A2_2
    L21_2 = A3_2
    L22_2 = A4_2
    L23_2 = A5_2
    L24_2 = A6_2
    L25_2 = A7_2
    L26_2 = A8_2
    L27_2 = MrxUtil
    L27_2 = L27_2.MarkerGetNameByIndex_Radar
    L28_2 = A9_2
    L27_2 = L27_2(L28_2)
    L28_2 = A10_2
    L29_2 = A11_2 or L29_2
    if not A11_2 then
      L29_2 = false
    end
    L30_2 = A12_2 or L30_2
    if not A12_2 then
      L30_2 = false
    end
    L31_2 = A13_2 or L31_2
    if not A13_2 then
      L31_2 = false
    end
    L32_2 = A14_2 or L32_2
    if not A14_2 then
      L32_2 = 5
    end
    L16_2(L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2)
  else
  end
end

AddObjectiveToLocalPlayer = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2)
  local L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2
  L9_2 = MrxGuiBase
  L9_2 = L9_2.GetWidgetByNameAndOwner
  L10_2 = "PDA"
  L11_2 = Player
  L11_2 = L11_2.GetLocalPlayer
  L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2 = L11_2()
  L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2)
  if L9_2 then
    L11_2 = L9_2
    L10_2 = L9_2.AddMapBlip
    L12_2 = A0_2
    L13_2 = A1_2
    L14_2 = A2_2
    L15_2 = A3_2
    L16_2 = nil
    L17_2 = A4_2
    L18_2 = MrxUtil
    L18_2 = L18_2.MarkerGetNameByIndex_Pda
    L19_2 = A5_2
    L18_2 = L18_2(L19_2)
    L19_2 = WifMissionData
    L19_2 = L19_2.GetMissionIdFromIndex
    L20_2 = A6_2
    L19_2 = L19_2(L20_2)
    L20_2 = nil
    L21_2 = A7_2
    L22_2 = nil
    L23_2 = nil
    L24_2 = A8_2
    L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2)
  else
  end
end

AddPdaBlipToLocalPlayer = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = MrxGuiBase
  L1_2 = L1_2.GetWidgetByNameAndOwner
  L2_2 = "PDA"
  L3_2 = Player
  L3_2 = L3_2.GetLocalPlayer
  L3_2, L4_2 = L3_2()
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  if L1_2 then
    L3_2 = L1_2
    L2_2 = L1_2.RemoveMapBlip
    L4_2 = A0_2
    L2_2(L3_2, L4_2)
  else
  end
end

DeletePdaBlipForLocalPlayer = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = MrxGuiBase
  L1_2 = L1_2.GetWidgetByNameAndOwner
  L2_2 = "Minimap"
  L3_2 = Player
  L3_2 = L3_2.GetLocalPlayer
  L3_2, L4_2 = L3_2()
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  if L1_2 then
    L3_2 = L1_2
    L2_2 = L1_2.DeleteObjective
    L4_2 = A0_2
    L2_2(L3_2, L4_2)
  else
  end
end

DeleteObjectiveForLocalPlayer = L0_1
L0_1 = false
oTestFlash = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = oTestFlash
  if not L1_2 then
    L1_2 = MrxGui
    L1_2 = L1_2.FlashWidget
    L2_2 = L1_2
    L1_2 = L1_2.new
    L1_2 = L1_2(L2_2)
    oTestFlash = L1_2
    L1_2 = oTestFlash
    L2_2 = L1_2
    L1_2 = L1_2.SetFullscreen
    L3_2 = true
    L1_2(L2_2, L3_2)
    L1_2 = oTestFlash
    L2_2 = L1_2
    L1_2 = L1_2.SetOwner
    L3_2 = Player
    L3_2 = L3_2.GetLocalPlayer
    L3_2 = L3_2()
    L1_2(L2_2, L3_2)
    L1_2 = MrxGui
    L1_2 = L1_2.AddWidget
    L2_2 = oTestFlash
    L1_2(L2_2)
    L1_2 = MrxGuiBase
    L1_2 = L1_2.GetControlFocus
    L2_2 = oTestFlash
    L3_2 = true
    L1_2(L2_2, L3_2)
  end
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "string" ~= L1_2 then
    L1_2 = EndFlashTest
    L1_2()
  else
    L1_2 = oTestFlash
    L2_2 = L1_2
    L1_2 = L1_2.SetSwfFile
    L3_2 = A0_2
    L1_2(L2_2, L3_2)
  end
end

TestFlash = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = oTestFlash
  if L0_2 then
    L0_2 = oTestFlash
    L1_2 = L0_2
    L0_2 = L0_2.SetSwfFile
    L2_2 = nil
    L0_2(L1_2, L2_2)
    L0_2 = MrxGui
    L0_2 = L0_2.RemoveWidget
    L1_2 = oTestFlash
    L0_2(L1_2)
    L0_2 = MrxGuiBase
    L0_2 = L0_2.ReleaseControlFocus
    L1_2 = oTestFlash
    L0_2(L1_2)
    L0_2 = oTestFlash
    L1_2 = L0_2
    L0_2 = L0_2.delete
    L0_2(L1_2)
    L0_2 = false
    oTestFlash = L0_2
  end
end

EndFlashTest = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _G
  L1_2 = TestFlash
  L0_2.TestFlash = L1_2
  L0_2 = _G
  L1_2 = EndFlashTest
  L0_2.EndFlashTest = L1_2
end

Init = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  if not A0_2 then
    L2_2 = MrxGuiBase
    L2_2 = L2_2.GetAllWidgetsByName
    L3_2 = A1_2
    L2_2 = L2_2(L3_2)
    L3_2 = {}
    L4_2 = pairs
    L5_2 = L2_2
    L4_2, L5_2, L6_2 = L4_2(L5_2)
    for L7_2, L8_2 in L4_2, L5_2, L6_2 do
      L10_2 = L8_2
      L9_2 = L8_2.GetOwner
      L9_2 = L9_2(L10_2)
      if L9_2 then
        L9_2 = table
        L9_2 = L9_2.insert
        L10_2 = L3_2
        L11_2 = L8_2
        L9_2(L10_2, L11_2)
      end
    end
    return L3_2
  end
  L2_2 = nil
  L3_2 = type
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if "table" == L3_2 then
    L2_2 = A0_2
  else
    L3_2 = type
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
    if "userdata" == L3_2 then
      L3_2 = {}
      L4_2 = A0_2
      L3_2[1] = L4_2
      L2_2 = L3_2
    else
      L3_2 = {}
      return L3_2
    end
  end
  L3_2 = {}
  L4_2 = pairs
  L5_2 = L2_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = MrxGuiBase
    L9_2 = L9_2.GetWidgetByNameAndOwner
    L10_2 = A1_2
    L11_2 = L8_2
    L9_2 = L9_2(L10_2, L11_2)
    if L9_2 then
      L10_2 = table
      L10_2 = L10_2.insert
      L11_2 = L3_2
      L12_2 = L9_2
      L10_2(L11_2, L12_2)
    end
  end
  return L3_2
end

_GetWidgetsForPlayers = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = Hud
  L2_2 = L2_2.Radar
  L3_2 = L2_2
  L2_2 = L2_2.AddLineRegion
  L4_2 = {}
  L4_2.uGuid = A0_2
  L4_2.bInvert = A1_2
  L4_2.nRed = 0
  L4_2.nGreen = 0
  L4_2.nBlue = 0
  L4_2.nAlpha = 160
  L2_2(L3_2, L4_2)
  L2_2 = Pda
  L2_2 = L2_2.Map
  L3_2 = L2_2
  L2_2 = L2_2.AddLineRegion
  L4_2 = {}
  L4_2.uGuid = A0_2
  L4_2.bInvert = A1_2
  L4_2.nRed = 0
  L4_2.nGreen = 0
  L4_2.nBlue = 0
  L4_2.nAlpha = 160
  L2_2(L3_2, L4_2)
end

NetClientAddBoundary = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Hud
  L1_2 = L1_2.Radar
  L2_2 = L1_2
  L1_2 = L1_2.RemoveLineRegion
  L3_2 = {}
  L3_2.uGuid = A0_2
  L1_2(L2_2, L3_2)
  L1_2 = Pda
  L1_2 = L1_2.Map
  L2_2 = L1_2
  L1_2 = L1_2.RemoveLineRegion
  L3_2 = {}
  L3_2.uGuid = A0_2
  L1_2(L2_2, L3_2)
end

NetClientRemoveBoundary = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = Hud
  L2_2 = L2_2.FactionDisplay
  L3_2 = L2_2
  L2_2 = L2_2.SetValue
  L4_2 = {}
  L4_2.sFaction = A0_2
  L4_2.nValue = A1_2
  L4_2.bForceOnClient = true
  L2_2(L3_2, L4_2)
end

NetClientFactionSetValue = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = Hud
  L2_2 = L2_2.FactionDisplay
  L3_2 = L2_2
  L2_2 = L2_2.StartPursuit
  L4_2 = {}
  L4_2.sFaction = A0_2
  L4_2.nDuration = A1_2
  L4_2.bForceOnClient = true
  L2_2(L3_2, L4_2)
end

NetClientFactionStartPursuit = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = Hud
  L2_2 = L2_2.FactionDisplay
  L3_2 = L2_2
  L2_2 = L2_2.HideMeter
  L4_2 = {}
  L4_2.sFaction = A0_2
  L4_2.bForceOnClient = true
  L2_2(L3_2, L4_2)
end

NetClientFactionHideMeter = L0_1
