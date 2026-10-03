local L0_1, L1_1
L0_1 = inherit
L1_1 = "Inheritable"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = false
bSticky = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectHibernation
  L5_2 = {}
  L6_2 = A0_2
  L7_2 = "awake"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = Awake
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A2_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
end

OnActivate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = getfenv
  L2_2 = L2_2()
  L4_2 = L2_2
  L3_2 = L2_2.Create
  L5_2 = A0_2
  L6_2 = A1_2
  L3_2 = L3_2(L4_2, L5_2, L6_2)
end

Awake = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2.bActive
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.ClearBlipped
    L1_2(L2_2)
  end
  L1_2 = Inheritable
  L1_2 = L1_2.Delete
  L2_2 = A0_2
  L1_2(L2_2)
end

Delete = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.AddObjective
  L1_2(L2_2)
  A0_2.bActive = true
end

SetBlipped = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.RemoveObjective
  L1_2(L2_2)
  A0_2.bActive = nil
end

ClearBlipped = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2
  L2_2 = pairs
  L3_2 = tHiddenGuids
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = A0_2.uGuid
    if L7_2 == L6_2 then
      return
    end
  end
  if A1_2 then
    L2_2 = A0_2.tFlash
    if L2_2 then
      goto lbl_24
    end
  end
  L2_2 = A0_2.tColor
  if not L2_2 then
    L2_2 = {}
    L3_2 = 255
    L4_2 = 51
    L5_2 = 51
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
  end
  ::lbl_24::
  L3_2 = A0_2.nWidth
  if not L3_2 then
    L3_2 = A0_2.nSize
  end
  L4_2 = A0_2.nHeight
  if not L4_2 then
    L4_2 = A0_2.nSize
  end
  L5_2 = Hud
  L5_2 = L5_2.Radar
  L6_2 = L5_2
  L5_2 = L5_2.AddObjective
  L7_2 = {}
  L8_2 = A0_2.sName
  L7_2.sName = L8_2
  L8_2 = L2_2[1]
  L7_2.nR = L8_2
  L8_2 = L2_2[2]
  L7_2.nG = L8_2
  L8_2 = L2_2[3]
  L7_2.nB = L8_2
  L7_2.nWidth = L3_2
  L7_2.nHeight = L4_2
  L8_2 = A0_2.sTexture
  L7_2.sTexture = L8_2
  L8_2 = A0_2.uGuid
  L7_2.uGuid = L8_2
  L8_2 = A0_2.bSticky
  L7_2.bSticky = L8_2
  L8_2 = A0_2.bRotate
  L7_2.bRotate = L8_2
  L8_2 = A0_2.bOriented
  L7_2.bOriented = L8_2
  L8_2 = A0_2.nSortOrder
  L7_2.nSortOrder = L8_2
  L8_2 = A0_2.bNetSync
  L8_2 = not L8_2
  L7_2.bDontNetSync = L8_2
  L5_2(L6_2, L7_2)
  L5_2 = A0_2.tMarker
  if L5_2 then
    L6_2 = A0_2.uMarkerGuid
    if L6_2 then
      L6_2 = Net
      L6_2 = L6_2.IsServer
      L6_2 = L6_2()
      if L6_2 then
        L6_2 = A0_2.bNetSync
        if L6_2 then
          L6_2 = Net
          L6_2 = L6_2.SendEvent_RemoveMarkerObjective
          L7_2 = A0_2.uMarkerGuid
          L6_2(L7_2)
        end
      end
      L6_2 = Marker
      L6_2 = L6_2.Remove
      L7_2 = A0_2.uMarkerGuid
      L6_2(L7_2)
    end
    L6_2 = L5_2.sTexture
    if not L6_2 then
      L6_2 = "HUD_objective_destroy"
    end
    L7_2 = L5_2.nSize
    if not L7_2 then
      L7_2 = 32
    end
    L8_2 = MrxUtil
    L8_2 = L8_2.GetSecondaryObjectiveRgb
    L8_2, L9_2, L10_2 = L8_2()
    if A1_2 then
      L11_2 = L5_2.tFlash
      if L11_2 then
        goto lbl_109
      end
    end
    L11_2 = L5_2.tColor
    if not L11_2 then
      L11_2 = {}
      L12_2 = L8_2
      L13_2 = L9_2
      L14_2 = L10_2
      L15_2 = 255
      L11_2[1] = L12_2
      L11_2[2] = L13_2
      L11_2[3] = L14_2
      L11_2[4] = L15_2
    end
    ::lbl_109::
    L12_2 = L5_2.nVerticalOffset
    if not L12_2 then
      L12_2 = 0
    end
    L13_2 = L5_2.nNearDist
    if not L13_2 then
      L13_2 = 140
    end
    L14_2 = L5_2.nFarDist
    if not L14_2 then
      L14_2 = 150
    end
    L15_2 = L5_2.nClampDist
    if not L15_2 then
      L15_2 = -1
    end
    L16_2 = L5_2.sGroup
    if not L16_2 then
      L16_2 = ""
    end
    L17_2 = L5_2.bJust2DCheck
    if not L17_2 then
      L17_2 = false
    end
    L18_2 = Marker
    L18_2 = L18_2.AddBlip
    L19_2 = A0_2.uGuid
    L20_2 = L6_2
    L21_2 = L7_2
    L22_2 = L11_2[1]
    L23_2 = L11_2[2]
    L24_2 = L11_2[3]
    L25_2 = L11_2[4]
    L26_2 = L12_2
    L27_2 = L13_2
    L28_2 = L14_2
    L29_2 = L15_2
    L30_2 = L16_2
    L31_2 = L17_2
    L18_2 = L18_2(L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2)
    A0_2.uMarkerGuid = L18_2
    L18_2 = Net
    L18_2 = L18_2.IsServer
    L18_2 = L18_2()
    if L18_2 then
      L18_2 = A0_2.bNetSync
      if L18_2 then
        L18_2 = Net
        L18_2 = L18_2.SendEvent_AddMarkerObjective
        L19_2 = A0_2.uGuid
        L20_2 = A0_2.uMarkerGuid
        L21_2 = L11_2[1]
        L22_2 = L11_2[2]
        L23_2 = L11_2[3]
        L24_2 = L12_2
        L25_2 = 0
        L26_2 = 1
        L27_2 = 0.5 * L7_2
        L28_2 = false
        L29_2 = L13_2
        L30_2 = L14_2
        L18_2(L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2)
      end
    end
  end
end

AddObjective = L0_1
L0_1 = {}
tHiddenGuids = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = tInstance
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L3_2 = L1_2
    L2_2 = L1_2.RemoveObjective
    L2_2(L3_2)
  end
  L2_2 = table
  L2_2 = L2_2.insert
  L3_2 = tHiddenGuids
  L4_2 = A0_2
  L2_2(L3_2, L4_2)
end

HideMarker = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Hud
  L1_2 = L1_2.Radar
  L2_2 = L1_2
  L1_2 = L1_2.RemoveObjective
  L3_2 = {}
  L4_2 = A0_2.sName
  L3_2.sName = L4_2
  L4_2 = A0_2.bNetSync
  L4_2 = not L4_2
  L3_2.bDontNetSync = L4_2
  L1_2(L2_2, L3_2)
  L1_2 = A0_2.uMarkerGuid
  if L1_2 then
    L1_2 = Marker
    L1_2 = L1_2.Remove
    L2_2 = A0_2.uMarkerGuid
    L1_2(L2_2)
    L1_2 = Net
    L1_2 = L1_2.IsServer
    L1_2 = L1_2()
    if L1_2 then
      L1_2 = A0_2.bDontNetSync
      if not L1_2 then
        L1_2 = Net
        L1_2 = L1_2.SendEvent_RemoveMarkerObjective
        L2_2 = A0_2.uMarkerGuid
        L1_2(L2_2)
      end
    end
    A0_2.uMarkerGuid = nil
  end
end

RemoveObjective = L0_1
