local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGuiBase"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportManager"
L0_1(L1_1)
L0_1 = 0.022222223
_knFrame = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L2_2 = A1_2.oSupport
  L3_2 = type
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if "table" == L3_2 then
    L3_2 = L2_2.GetOwner
    if L3_2 then
      goto lbl_11
    end
  end
  do return end
  ::lbl_11::
  L3_2 = A1_2.oImageWidget
  if not L3_2 then
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.bEnabled
    if not L4_2 then
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.bSuspendInput
      if not L4_2 then
        goto lbl_39
      end
    end
  end
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.bAddItemInProgress
  if not L4_2 then
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.bSuspendInput
    if not L4_2 then
      goto lbl_37
    end
  end
  L4_2 = table
  L4_2 = L4_2.insert
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.tPendingItemQueue
  L6_2 = A1_2
  L4_2(L5_2, L6_2)
  do return end
  ::lbl_37::
  L4_2 = A0_2.CustomData
  L4_2.bAddItemInProgress = true
  ::lbl_39::
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.bEnabled
  if not L4_2 then
    L4_2 = A1_2.bAnimate
    if L4_2 then
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.oAddAnim
      L5_2 = L4_2
      L4_2 = L4_2.Show
      L6_2 = A1_2.sIcon
      L7_2 = A1_2.sName
      L4_2(L5_2, L6_2, L7_2)
      L4_2 = _AddItemToInternalList
      L5_2 = A0_2
      L6_2 = A1_2
      L4_2(L5_2, L6_2)
      return
    end
  end
  L4_2 = Net
  L4_2 = L4_2.IsServer
  L4_2 = L4_2()
  if L4_2 then
    L4_2 = A1_2.bDontNetSync
    if not L4_2 then
      L4_2 = Net
      L4_2 = L4_2.SendEvent_AddSupportItem
      L5_2 = A1_2.sName
      if not L5_2 then
        L5_2 = ""
      end
      L6_2 = A1_2.sIcon
      if not L6_2 then
        L6_2 = ""
      end
      L7_2 = A1_2.sLitIcon
      if not L7_2 then
        L7_2 = ""
      end
      L8_2 = A1_2.oSupport
      L9_2 = L8_2
      L8_2 = L8_2.GetModuleName
      L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2 = L8_2(L9_2)
      L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
    end
  end
  L4_2 = _AddItemToInternalList
  L5_2 = A0_2
  L6_2 = A1_2
  L4_2(L5_2, L6_2)
  L4_2 = type
  L5_2 = L3_2
  L4_2 = L4_2(L5_2)
  if "table" == L4_2 then
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.tDisplayList
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.nSelectedDisplayIndex
    L4_2 = L4_2[L5_2]
    L4_2 = L4_2.CustomData
    L4_2 = L4_2.oIcon
    L5_2 = false
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.bEnabled
    if not L6_2 then
      L7_2 = A0_2
      L6_2 = A0_2.Open
      L6_2(L7_2)
      L5_2 = true
    end
    L6_2 = pairs
    L7_2 = L3_2.EventHandlers
    L6_2, L7_2, L8_2 = L6_2(L7_2)
    for L9_2 in L6_2, L7_2, L8_2 do
      L11_2 = L3_2
      L10_2 = L3_2.SetEventHandler
      L12_2 = L9_2
      L13_2 = nil
      L10_2(L11_2, L12_2, L13_2)
    end
    L7_2 = L3_2
    L6_2 = L3_2.GetOwner
    L6_2 = L6_2(L7_2)
    L8_2 = A0_2
    L7_2 = A0_2.GetOwner
    L7_2 = L7_2(L8_2)
    if L6_2 ~= L7_2 then
      L7_2 = L3_2
      L6_2 = L3_2.SetOwner
      L9_2 = A0_2
      L8_2 = A0_2.GetOwner
      L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2 = L8_2(L9_2)
      L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
    end
    L7_2 = L3_2
    L6_2 = L3_2.SetTranslucency
    L8_2 = 255
    L6_2(L7_2, L8_2)
    L7_2 = L3_2
    L6_2 = L3_2.SetAnchoring
    L8_2 = "left"
    L9_2 = "center"
    L6_2(L7_2, L8_2, L9_2)
    L7_2 = L3_2
    L6_2 = L3_2.GetLocation
    L6_2, L7_2, L8_2, L9_2 = L6_2(L7_2)
    L11_2 = L4_2
    L10_2 = L4_2.GetLocation
    L10_2, L11_2, L12_2, L13_2 = L10_2(L11_2)
    L15_2 = L3_2
    L14_2 = L3_2.AddAnimationPoint
    L16_2 = {}
    L16_2.x = L10_2
    L16_2.y = L11_2
    L16_2.x2 = L12_2
    L16_2.y2 = L13_2
    L16_2.TranslucencyLevel = 0
    L14_2 = L14_2(L15_2, L16_2)
    L16_2 = L4_2
    L15_2 = L4_2.SetLocation
    L17_2 = L6_2
    L18_2 = L7_2
    L19_2 = L8_2
    L20_2 = L9_2
    L15_2(L16_2, L17_2, L18_2, L19_2, L20_2)
    L16_2 = L4_2
    L15_2 = L4_2.SetTranslucency
    L17_2 = 0
    L15_2(L16_2, L17_2)
    L15_2 = L3_2.CustomData
    L15_2.oParentSupportMenu = A0_2
    L16_2 = L4_2
    L15_2 = L4_2.AnimateToPoint
    L17_2 = L4_2.CustomData
    L17_2 = L17_2.nOriginalPoint
    L18_2 = 1
    L19_2 = true
    L15_2(L16_2, L17_2, L18_2, L19_2)
    L16_2 = L3_2
    L15_2 = L3_2.AnimateToPoint
    L17_2 = L14_2
    L18_2 = 1
    L19_2 = true
    L20_2 = _RemoveAddAnimationComplete
    L15_2(L16_2, L17_2, L18_2, L19_2, L20_2)
  else
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.bEnabled
    if L4_2 then
      L4_2 = {}
      L5_2 = 1
      L6_2 = A0_2
      L7_2 = A1_2.fCallback
      L8_2 = A1_2.tCallbackData
      L4_2[1] = L5_2
      L4_2[2] = L6_2
      L4_2[3] = L7_2
      L4_2[4] = L8_2
      L5_2 = _PerformAddAnimation
      L6_2 = A0_2
      L7_2 = _AddAnimationComplete
      L8_2 = L4_2
      L5_2(L6_2, L7_2, L8_2)
    else
      L5_2 = A0_2
      L4_2 = A0_2.SetVisible
      L6_2 = false
      L4_2(L5_2, L6_2)
    end
  end
end

AddItem = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A1_2.bAlreadyAdded
  if L2_2 then
    return
  end
  L2_2 = CreateInternalListItem
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nNumberOfItems
  if L3_2 <= 0 then
    L3_2 = table
    L3_2 = L3_2.insert
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.tItemList
    L5_2 = L2_2
    L3_2(L4_2, L5_2)
  else
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.nSelectedItemIndex
    if L3_2 <= 0 then
      L3_2 = A0_2.CustomData
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.tItemList
      L4_2 = #L4_2
      L3_2.nSelectedItemIndex = L4_2
    else
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.nSelectedItemIndex
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.tItemList
      L4_2 = #L4_2
      if L3_2 > L4_2 then
        L3_2 = A0_2.CustomData
        L3_2.nSelectedItemIndex = 1
      end
    end
    L3_2 = table
    L3_2 = L3_2.insert
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.tItemList
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.nSelectedItemIndex
    L6_2 = L2_2
    L3_2(L4_2, L5_2, L6_2)
  end
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nNumberOfItems
  if L3_2 < 0 then
    L3_2 = A0_2.CustomData
    L3_2.nNumberOfItems = 0
  end
  L3_2 = L2_2.oSupport
  L4_2 = L3_2
  L3_2 = L3_2.GetOwner
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L3_2 = L2_2.oSupport
    L4_2 = L3_2
    L3_2 = L3_2.SetOwner
    L6_2 = A0_2
    L5_2 = A0_2.GetOwner
    L5_2, L6_2 = L5_2(L6_2)
    L3_2(L4_2, L5_2, L6_2)
  end
  L3_2 = L2_2.nFuelCost
  if L3_2 then
    L3_2 = L2_2.oSupport
    L4_2 = L3_2
    L3_2 = L3_2.SetFuelCost
    L5_2 = L2_2.nFuelCost
    L3_2(L4_2, L5_2)
  end
  L3_2 = L2_2.nCashCost
  if L3_2 then
    L3_2 = L2_2.oSupport
    L4_2 = L3_2
    L3_2 = L3_2.SetCashCost
    L5_2 = L2_2.nCashCost
    L3_2(L4_2, L5_2)
  end
  L3_2 = A0_2.CustomData
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nNumberOfItems
  L4_2 = L4_2 + 1
  L3_2.nNumberOfItems = L4_2
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nSelectedItemIndex
  if L3_2 <= 0 then
    L3_2 = A0_2.CustomData
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.tItemList
    L4_2 = #L4_2
    L3_2.nSelectedItemIndex = L4_2
  else
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.nSelectedItemIndex
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.tItemList
    L4_2 = #L4_2
    if L3_2 > L4_2 then
      L3_2 = A0_2.CustomData
      L3_2.nSelectedItemIndex = 1
    end
  end
  A1_2.bAlreadyAdded = true
end

_AddItemToInternalList = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L4_2 = pairs
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.tPendingItemQueue
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = L8_2.sName
    if A1_2 == L9_2 then
      L3_2 = L7_2
    end
  end
  if L3_2 then
    L4_2 = table
    L4_2 = L4_2.remove
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.tPendingItemQueue
    L6_2 = L3_2
    L4_2(L5_2, L6_2)
  end
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oAddAnim
  L5_2 = L4_2
  L4_2 = L4_2.Remove
  L6_2 = A1_2
  L4_2(L5_2, L6_2)
  L4_2 = nil
  L5_2 = pairs
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.tItemList
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = L9_2.sName
    if A1_2 == L10_2 then
      L4_2 = L8_2
    end
  end
  if not L4_2 then
    return
  end
  L5_2 = Net
  L5_2 = L5_2.IsServer
  L5_2 = L5_2()
  if L5_2 and not A2_2 then
    L5_2 = Net
    L5_2 = L5_2.SendEvent_RemoveSupportItem
    L6_2 = A1_2
    L5_2(L6_2)
  end
  L5_2 = table
  L5_2 = L5_2.remove
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.tItemList
  L7_2 = L4_2
  L5_2(L6_2, L7_2)
  L5_2 = A0_2.CustomData
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.nNumberOfItems
  L6_2 = L6_2 - 1
  L5_2.nNumberOfItems = L6_2
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nSelectedItemIndex
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.nNumberOfItems
  if L5_2 > L6_2 then
    L5_2 = A0_2.CustomData
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.nNumberOfItems
    L5_2.nSelectedItemIndex = L6_2
  end
  L6_2 = A0_2
  L5_2 = A0_2._SetDisplayInformation
  L5_2(L6_2)
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.bEnabled
  if L5_2 then
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.nNumberOfItems
    if L5_2 <= 0 then
      L5_2 = A0_2.CustomData
      L5_2.bSuspendInput = false
      L6_2 = A0_2
      L5_2 = A0_2.Close
      L5_2(L6_2)
  end
  else
    L6_2 = A0_2
    L5_2 = A0_2.SetVisible
    L7_2 = false
    L5_2(L6_2, L7_2)
  end
end

RemoveItem = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2.CustomData
  L1_2.nNumberOfItems = 0
  L1_2 = A0_2.CustomData
  L1_2.nSelectedItemIndex = 1
  L1_2 = A0_2.CustomData
  L2_2 = {}
  L1_2.tItemList = L2_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bEnabled
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.Close
    L1_2(L2_2)
  end
end

RemoveAll = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bSuspendInput
  if L1_2 then
    L1_2 = A0_2.CustomData
    L1_2.bConfirmEntered = true
    return
  end
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.tItemList
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nSelectedItemIndex
  L1_2 = L1_2[L2_2]
  L2_2 = L1_2.oSupport
  L4_2 = L2_2
  L3_2 = L2_2.GetFuelCost
  L3_2 = L3_2(L4_2)
  L4_2 = MrxPmc
  L4_2 = L4_2.GetFuelQty
  L4_2 = L4_2()
  if L3_2 and L3_2 > L4_2 then
    L5_2 = L2_2.bUnrestrictedByFuel
    if not L5_2 then
      return
    end
  end
  L6_2 = L2_2
  L5_2 = L2_2.GetSupportName
  L5_2 = L5_2(L6_2)
  L6_2 = MrxPmc
  L6_2 = L6_2.GetFreebieQty
  L7_2 = L5_2
  L6_2 = L6_2(L7_2)
  if L6_2 then
    if L6_2 < 1 then
      L8_2 = L2_2
      L7_2 = L2_2.GetCashCost
      L7_2 = L7_2(L8_2)
      if not L7_2 then
        return
      end
      L8_2 = MrxPmc
      L8_2 = L8_2.GetCashQty
      L8_2 = L8_2()
      if L7_2 > L8_2 then
        return
      end
    end
  else
    L7_2 = MrxPmc
    L7_2 = L7_2.GetSupportQty
    L8_2 = L5_2
    L7_2 = L7_2(L8_2)
    if L7_2 and L7_2 < 1 then
      return
    end
    L8_2 = A0_2.CustomData
    L8_2 = L8_2.bShootingGalleryMode
    if L8_2 then
      return
    end
  end
  L8_2 = L2_2
  L7_2 = L2_2.GetDenialCondition
  L7_2 = L7_2(L8_2)
  if L7_2 then
    return
  end
  L8_2 = L2_2
  L7_2 = L2_2.ShouldSuppressIconAnimationOnDirectUse
  L7_2 = L7_2(L8_2)
  if not L7_2 then
    L7_2 = MrxGuiBase
    L7_2 = L7_2.GetWidgetByNameAndOwner
    L8_2 = "Current Gun"
    L10_2 = A0_2
    L9_2 = A0_2.GetOwner
    L9_2, L10_2 = L9_2(L10_2)
    L7_2 = L7_2(L8_2, L9_2, L10_2)
    if L7_2 then
      L9_2 = L7_2
      L8_2 = L7_2.SetSuppressAnimation
      L10_2 = true
      L8_2(L9_2, L10_2)
    end
  end
  if L1_2 then
    L7_2 = L1_2.fTrigger
    if L7_2 then
      L7_2 = L1_2.fTrigger
      L8_2 = unpack
      L9_2 = L1_2.tCallbackData
      L8_2, L9_2, L10_2 = L8_2(L9_2)
      L7_2 = L7_2(L8_2, L9_2, L10_2)
      bSuccess = L7_2
    end
  end
  L8_2 = A0_2
  L7_2 = A0_2.Close
  L7_2(L8_2)
  L7_2 = A0_2.CustomData
  L7_2.bSuspendInput = true
  L7_2 = bSuccess
  if not L7_2 then
    L7_2 = oGunAmmoCounter
    if L7_2 then
      L7_2 = oGunAmmoCounter
      L8_2 = L7_2
      L7_2 = L7_2.SetSuppressAnimation
      L9_2 = false
      L7_2(L8_2, L9_2)
    end
    return
  end
  L7_2 = Sound
  L7_2 = L7_2.CueSound
  L8_2 = 0
  L9_2 = "ui_HUD_Support_Select"
  L7_2(L8_2, L9_2)
  L8_2 = L2_2
  L7_2 = L2_2.ShouldSuppressIconAnimationOnDirectUse
  L7_2 = L7_2(L8_2)
  if not L7_2 then
    L7_2 = A0_2.CustomData
    L7_2 = L7_2.tDisplayList
    L7_2 = L7_2[3]
    L8_2 = L7_2
    L7_2 = L7_2.SetVisible
    L9_2 = false
    L7_2(L8_2, L9_2)
    L7_2 = _CreateFlyingIcon
    L8_2 = A0_2.CustomData
    L8_2 = L8_2.tDisplayList
    L8_2 = L8_2[3]
    L7_2(L8_2)
  end
end

Trigger = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bEnabled
  if L2_2 then
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.bAnimatingAdd
    if L2_2 and not A1_2 then
      L2_2 = MrxGuiBase
      L2_2 = L2_2.GetControlFocus
      L3_2 = A0_2
      L4_2 = false
      L2_2(L3_2, L4_2)
      L2_2 = A0_2.CustomData
      L2_2.bAnimatingAdd = false
      L2_2 = A0_2.CustomData
      L2_2.bSnapAddAnimation = true
    end
    return
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bSuspendInput
  if L2_2 then
    return
  end
  L2_2 = MrxGuiBase
  L2_2 = L2_2.GetWidgetByNameAndOwner
  L3_2 = "PDA"
  L5_2 = A0_2
  L4_2 = A0_2.GetOwner
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2 = L4_2(L5_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  L3_2 = L2_2.CustomData
  L3_2 = L3_2.bActive
  if L3_2 then
    return
  end
  L3_2 = MrxGuiBase
  L3_2 = L3_2.GetWidgetByNameAndOwner
  L4_2 = "money"
  L6_2 = A0_2
  L5_2 = A0_2.GetOwner
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2 = L5_2(L6_2)
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  L4_2 = MrxGuiBase
  L4_2 = L4_2.GetWidgetByNameAndOwner
  L5_2 = "fuel"
  L7_2 = A0_2
  L6_2 = A0_2.GetOwner
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2 = L6_2(L7_2)
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nNumberOfItems
  if L5_2 <= 0 then
    L6_2 = L3_2
    L5_2 = L3_2.Show
    L7_2 = 4
    L5_2(L6_2, L7_2)
    L6_2 = L4_2
    L5_2 = L4_2.Show
    L7_2 = 4
    L5_2(L6_2, L7_2)
    return
  end
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.oAddAnim
  L6_2 = L5_2
  L5_2 = L5_2.Hide
  L5_2(L6_2)
  L6_2 = A0_2
  L5_2 = A0_2.SetVisible
  L7_2 = true
  L5_2(L6_2, L7_2)
  L5_2 = A0_2.CustomData
  L5_2.bEnabled = true
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.oUpArrow
  L6_2 = L5_2
  L5_2 = L5_2.SetVisible
  L7_2 = false
  L5_2(L6_2, L7_2)
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.oDownArrow
  L6_2 = L5_2
  L5_2 = L5_2.SetVisible
  L7_2 = false
  L5_2(L6_2, L7_2)
  L5_2 = A0_2.CustomData
  L5_2.nBufferedInput = 0
  L5_2 = A0_2.CustomData
  L5_2.bConfirmEntered = nil
  if L3_2 then
    L6_2 = L3_2
    L5_2 = L3_2.Show
    L7_2 = -1
    L5_2(L6_2, L7_2)
  end
  if L4_2 then
    L6_2 = L4_2
    L5_2 = L4_2.Show
    L7_2 = -1
    L5_2(L6_2, L7_2)
  end
  L6_2 = A0_2
  L5_2 = A0_2.SetLocation
  L5_2(L6_2)
  L6_2 = A0_2
  L5_2 = A0_2._SetDisplayInformation
  L5_2(L6_2)
  if A1_2 then
    L5_2 = A0_2.CustomData
    L5_2.bAnimatingAdd = true
  else
    L5_2 = A0_2.CustomData
    L5_2.bAnimatingAdd = false
    L5_2 = MrxGuiBase
    L5_2 = L5_2.GetControlFocus
    L6_2 = A0_2
    L7_2 = false
    L5_2(L6_2, L7_2)
    L5_2 = Event
    L5_2 = L5_2.Post
    L6_2 = "Support Menu Open"
    L7_2 = {}
    L9_2 = A0_2
    L8_2 = A0_2.GetOwner
    L8_2 = L8_2(L9_2)
    L7_2.uPlayer = L8_2
    L5_2(L6_2, L7_2)
  end
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.tDisplayList
  L6_2 = L5_2[2]
  L7_2 = L6_2
  L6_2 = L6_2.SetupOpen
  L6_2(L7_2)
  L6_2 = L5_2[3]
  L7_2 = L6_2
  L6_2 = L6_2.SetupOpen
  L6_2(L7_2)
  L6_2 = L5_2[4]
  L7_2 = L6_2
  L6_2 = L6_2.SetupOpen
  L6_2(L7_2)
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.oDescripters
  L7_2 = L6_2
  L6_2 = L6_2.SetVisible
  L8_2 = false
  L6_2(L7_2, L8_2)
  L6_2 = L5_2[2]
  L6_2 = L6_2.CustomData
  L6_2 = L6_2.oOrbit
  L7_2 = L6_2
  L6_2 = L6_2.AnimateToPoint
  L8_2 = L5_2[2]
  L8_2 = L8_2.CustomData
  L8_2 = L8_2.oOrbit
  L8_2 = L8_2.CustomData
  L8_2 = L8_2.nFadeInPoint
  L9_2 = _knFrame
  L9_2 = L9_2 * 10
  L10_2 = false
  L6_2(L7_2, L8_2, L9_2, L10_2)
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.oBulletRing
  L8_2 = L6_2
  L7_2 = L6_2.SetTranslucency
  L9_2 = 0
  L7_2(L8_2, L9_2)
  L8_2 = L6_2
  L7_2 = L6_2.AnimateToPoint
  L9_2 = L6_2.CustomData
  L9_2 = L9_2.nFadeInPoint
  L10_2 = _knFrame
  L10_2 = L10_2 * 15
  L11_2 = true
  L7_2(L8_2, L9_2, L10_2, L11_2)
  L7_2 = 1
  while L7_2 <= 5 do
    L9_2 = L6_2
    L8_2 = L6_2.AnimateBullet
    L10_2 = L7_2
    L11_2 = _knFrame
    L11_2 = L11_2 * 15
    L12_2 = 270
    L13_2 = 0
    L14_2 = 1
    L15_2 = false
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
    L7_2 = L7_2 + 1
  end
  L8_2 = A0_2.CustomData
  L8_2 = L8_2.oUpArrowBg
  L9_2 = L8_2
  L8_2 = L8_2.SetVisible
  L10_2 = false
  L8_2(L9_2, L10_2)
  L8_2 = A0_2.CustomData
  L8_2 = L8_2.oDownArrowBg
  L9_2 = L8_2
  L8_2 = L8_2.SetVisible
  L10_2 = false
  L8_2(L9_2, L10_2)
  L8_2 = A0_2.CustomData
  L8_2 = L8_2.oFrame
  L9_2 = _FrameClosed
  L10_2 = L8_2
  L9_2(L10_2)
  L10_2 = L8_2
  L9_2 = L8_2.SetVisible
  L11_2 = false
  L9_2(L10_2, L11_2)
  L10_2 = L8_2
  L9_2 = L8_2.AnimateToPoint
  L11_2 = L8_2.CustomData
  L11_2 = L11_2.nClosePoint
  L12_2 = 0
  L13_2 = true
  L9_2(L10_2, L11_2, L12_2, L13_2)
  L9_2 = A0_2.CustomData
  L9_2.bSuspendInput = true
  L9_2 = A0_2.CustomData
  L9_2.nTime = 0
  L10_2 = A0_2
  L9_2 = A0_2.SetEventHandler
  L11_2 = "GuiUpdate"
  L12_2 = HandleUpdateForOpen
  L9_2(L10_2, L11_2, L12_2)
  L9_2 = A0_2.CustomData
  L9_2.bCloseOnComplete = false
  L9_2 = A0_2.CustomData
  L9_2 = L9_2.oClockIcon
  L10_2 = L9_2
  L9_2 = L9_2.SetVisible
  L11_2 = false
  L9_2(L10_2, L11_2)
  L9_2 = Sound
  L9_2 = L9_2.CueSound
  L10_2 = 0
  L11_2 = "ui_HUD_Support_Open_Menu"
  L9_2(L10_2, L11_2)
end

Open = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bEnabled
  if not L1_2 then
    return
  end
  L1_2 = MrxGuiBase
  L1_2 = L1_2.ReleaseControlFocus
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bSuspendInput
  if L1_2 then
    L1_2 = A0_2.CustomData
    L1_2.bCloseOnComplete = true
    return
  end
  L1_2 = A0_2.CustomData
  L1_2.bEnabled = false
  L1_2 = MrxGuiBase
  L1_2 = L1_2.GetWidgetByNameAndOwner
  L2_2 = "money"
  L4_2 = A0_2
  L3_2 = A0_2.GetOwner
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L3_2(L4_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  L2_2 = MrxGuiBase
  L2_2 = L2_2.GetWidgetByNameAndOwner
  L3_2 = "fuel"
  L5_2 = A0_2
  L4_2 = A0_2.GetOwner
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L4_2(L5_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  if L1_2 then
    L4_2 = L1_2
    L3_2 = L1_2.Hide
    L3_2(L4_2)
  end
  if L2_2 then
    L4_2 = L2_2
    L3_2 = L2_2.Hide
    L3_2(L4_2)
  end
  L3_2 = pairs
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.tPendingItemQueue
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L9_2 = A0_2
    L8_2 = A0_2.AddItem
    L10_2 = {}
    L11_2 = L7_2.sName
    L10_2.sName = L11_2
    L11_2 = L7_2.sIcon
    L10_2.sIcon = L11_2
    L11_2 = L7_2.sLitIcon
    L10_2.sLitIcon = L11_2
    L11_2 = L7_2.oSupport
    L10_2.oSupport = L11_2
    L11_2 = L7_2.bAlreadyAdded
    L10_2.bAlreadyAdded = L11_2
    L8_2(L9_2, L10_2)
    L8_2 = L7_2.fCallback
    if L8_2 then
      L8_2 = L7_2.fCallback
      L9_2 = unpack
      L10_2 = L7_2.tCallbackData
      if not L10_2 then
        L10_2 = {}
      end
      L9_2, L10_2, L11_2 = L9_2(L10_2)
      L8_2(L9_2, L10_2, L11_2)
    end
  end
  L3_2 = A0_2.CustomData
  L4_2 = {}
  L3_2.tPendingItemQueue = L4_2
  L3_2 = A0_2.CustomData
  L3_2.bAddItemInProgress = false
  L3_2 = A0_2.CustomData
  L3_2.bSuspendInput = false
  L3_2 = A0_2.CustomData
  L3_2.nTime = 0
  L4_2 = A0_2
  L3_2 = A0_2.SetEventHandler
  L5_2 = "GuiUpdate"
  L6_2 = HandleUpdateForClose
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = Sound
  L3_2 = L3_2.CueSound
  L4_2 = 0
  L5_2 = "ui_HUD_Support_Close_Menu"
  L3_2(L4_2, L5_2)
  L3_2 = Event
  L3_2 = L3_2.Post
  L4_2 = "Support Menu Close"
  L5_2 = {}
  L7_2 = A0_2
  L6_2 = A0_2.GetOwner
  L6_2 = L6_2(L7_2)
  L5_2.uPlayer = L6_2
  L3_2(L4_2, L5_2)
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oClockIcon
  L4_2 = L3_2
  L3_2 = L3_2.SetVisible
  L5_2 = false
  L3_2(L4_2, L5_2)
end

Close = L0_1

function L0_1(A0_2, A1_2)
end

SetCash = L0_1

function L0_1(A0_2, A1_2)
end

SetFuel = L0_1

function L0_1(A0_2, A1_2)
  local L2_2
  L2_2 = A0_2.CustomData
  L2_2.bShootingGalleryMode = A1_2
end

SetShootingGalleryMode = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L3_2 = A0_2.CustomData
  L4_2 = table
  L4_2 = L4_2.getn
  L5_2 = L2_2[2]
  L6_2 = L5_2
  L5_2 = L5_2.GetChildren
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2 = L5_2(L6_2)
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2)
  L3_2.nMaxDisplayItems = L4_2
  L3_2 = L2_2[2]
  L4_2 = L3_2
  L3_2 = L3_2.GetChildren
  L3_2 = L3_2(L4_2)
  L4_2 = L3_2[1]
  L5_2 = L4_2
  L4_2 = L4_2.SetTranslucency
  L6_2 = 0
  L4_2(L5_2, L6_2)
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nMaxDisplayItems
  L4_2 = L3_2[L4_2]
  L5_2 = L4_2
  L4_2 = L4_2.SetTranslucency
  L6_2 = 0
  L4_2(L5_2, L6_2)
  L4_2 = L3_2[1]
  L5_2 = L4_2
  L4_2 = L4_2.GetLocation
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  L7_2 = 1
  while "nAddPoint" do
    L8_2 = A0_2.CustomData
    L8_2 = L8_2.nMaxDisplayItems
    if not (L7_2 <= L8_2) then
      break
    end
    L8_2 = L3_2[L7_2]
    L9_2 = L8_2
    L8_2 = L8_2.GetLocation
    L8_2, L9_2, L10_2 = L8_2(L9_2)
    L11_2 = L3_2[L7_2]
    L11_2 = L11_2.CustomData
    L12_2 = L3_2[L7_2]
    L13_2 = L12_2
    L12_2 = L12_2.AddAnimationPoint
    L14_2 = {}
    L14_2.x = L8_2
    L14_2.x2 = L10_2
    L12_2 = L12_2(L13_2, L14_2)
    L11_2.nAddPoint = L12_2
    L11_2 = L3_2[L7_2]
    L11_2 = L11_2.CustomData
    L12_2 = L3_2[L7_2]
    L13_2 = L12_2
    L12_2 = L12_2.GetChildren
    L12_2 = L12_2(L13_2)
    L12_2 = L12_2[1]
    L11_2.oBackground = L12_2
    L11_2 = L3_2[L7_2]
    L11_2 = L11_2.CustomData
    L12_2 = L3_2[L7_2]
    L13_2 = L12_2
    L12_2 = L12_2.GetChildren
    L12_2 = L12_2(L13_2)
    L12_2 = L12_2[2]
    L11_2.oIcon = L12_2
    L7_2 = L7_2 + 1
  end
  L7_2 = 1
  L8_2 = 255
  while true do
    L9_2 = A0_2.CustomData
    L9_2 = L9_2.nMaxDisplayItems
    if not (L7_2 <= L9_2) then
      break
    end
    L9_2 = _SetupItemAnimationPoints
    L10_2 = L7_2
    L11_2 = L3_2
    L9_2(L10_2, L11_2)
    L7_2 = L7_2 + 1
  end
  L9_2 = nil
  L7_2 = 1
  while true do
    L10_2 = A0_2.CustomData
    L10_2 = L10_2.nMaxDisplayItems
    if not (L7_2 <= L10_2) then
      break
    end
    L9_2 = L3_2[L7_2]
    L10_2 = MrxGuiBase
    L10_2 = L10_2.PushWidgetToFront
    L11_2 = L9_2.CustomData
    L11_2 = L11_2.oIcon
    L10_2(L11_2)
    L7_2 = L7_2 + 1
  end
  L7_2 = 1
  while true do
    L10_2 = A0_2.CustomData
    L10_2 = L10_2.nMaxDisplayItems
    if not (L7_2 <= L10_2) then
      break
    end
    L9_2 = L3_2[L7_2]
    L10_2 = MrxGuiBase
    L10_2 = L10_2.PushWidgetToFront
    L11_2 = L9_2.CustomData
    L11_2 = L11_2.oStatus
    L10_2(L11_2)
    L7_2 = L7_2 + 1
  end
  L10_2 = A0_2.CustomData
  L10_2.tDisplayList = L3_2
  L10_2 = A0_2.CustomData
  L11_2 = L2_2[3]
  L10_2.oCursor = L11_2
  L10_2 = A0_2.CustomData
  L10_2.nSelectedDisplayIndex = 3
  L10_2 = A0_2.CustomData
  L10_2.nSelectedItemIndex = 0
  L10_2 = A0_2.CustomData
  L10_2.nNumberOfItems = 0
  L10_2 = A0_2.CustomData
  L11_2 = {}
  L10_2.tItemList = L11_2
  L10_2 = A0_2.CustomData
  L11_2 = {}
  L10_2.tPendingItemQueue = L11_2
  L10_2 = A0_2.CustomData
  L10_2.bAddItemInProgress = false
  L10_2 = A0_2.CustomData
  L10_2.nItemSpacing = 43
  L10_2 = A0_2.CustomData
  L11_2 = A0_2.CustomData
  L12_2 = L2_2[2]
  L13_2 = L12_2
  L12_2 = L12_2.GetLocation
  L12_2, L13_2 = L12_2(L13_2)
  L11_2.nDisplayY = L13_2
  L10_2.nDisplayX = L12_2
  L10_2 = A0_2.CustomData
  L11_2 = L2_2[2]
  L12_2 = L11_2
  L11_2 = L11_2.AddAnimationPoint
  L13_2 = {}
  L14_2 = A0_2.CustomData
  L14_2 = L14_2.nDisplayX
  L13_2.x = L14_2
  L14_2 = A0_2.CustomData
  L14_2 = L14_2.nDisplayY
  L13_2.y = L14_2
  L11_2 = L11_2(L12_2, L13_2)
  L10_2.nDisplayPoint = L11_2
  L10_2 = A0_2.CustomData
  L10_2.nBufferedInput = 0
  L10_2 = A0_2.CustomData
  L10_2.bConfirmEntered = nil
  L10_2 = _SetDisplayInformation
  A0_2._SetDisplayInformation = L10_2
  L10_2 = _ScrollUp
  A0_2._ScrollUp = L10_2
  L10_2 = _ScrollDown
  A0_2._ScrollDown = L10_2
  L11_2 = A0_2
  L10_2 = A0_2._SetDisplayInformation
  L10_2(L11_2)
  L10_2 = SetCash
  A0_2.SetCash = L10_2
  L10_2 = SetFuel
  A0_2.SetFuel = L10_2
  L10_2 = Open
  A0_2.Open = L10_2
  L10_2 = Close
  A0_2.Close = L10_2
  L10_2 = Trigger
  A0_2.Trigger = L10_2
  L10_2 = AddItem
  A0_2.AddItem = L10_2
  L10_2 = RemoveItem
  A0_2.RemoveItem = L10_2
  L10_2 = RemoveAll
  A0_2.RemoveAll = L10_2
  L10_2 = SetShootingGalleryMode
  A0_2.SetShootingGalleryMode = L10_2
  L11_2 = A0_2
  L10_2 = A0_2.SetEventHandler
  L12_2 = "ControllerInput"
  L13_2 = HandleInputEvent
  L10_2(L11_2, L12_2, L13_2)
  L11_2 = A0_2
  L10_2 = A0_2.SetEventHandler
  L12_2 = "GuiGameStateChange"
  L13_2 = _HandleGameStateChangeEvent
  L10_2(L11_2, L12_2, L13_2)
  L11_2 = A0_2
  L10_2 = A0_2.SetVisible
  L12_2 = false
  L10_2(L11_2, L12_2)
  L10_2 = A0_2.CustomData
  L10_2.bEnabled = false
  L10_2 = L2_2[1]
  L11_2 = L10_2
  L10_2 = L10_2.GetChildren
  L10_2 = L10_2(L11_2)
  L10_2 = L10_2[1]
  L11_2 = L10_2
  L10_2 = L10_2.GetChildren
  L10_2 = L10_2(L11_2)
  L11_2 = L10_2[2]
  L12_2 = L11_2
  L11_2 = L11_2.GetChildren
  L11_2 = L11_2(L12_2)
  L11_2 = L11_2[1]
  L12_2 = L10_2[3]
  L13_2 = L12_2
  L12_2 = L12_2.GetChildren
  L12_2 = L12_2(L13_2)
  L12_2 = L12_2[1]
  L13_2 = L11_2.CustomData
  L15_2 = L11_2
  L14_2 = L11_2.AddAnimationPoint
  L16_2 = {}
  L16_2.TranslucencyLevel = 255
  L14_2 = L14_2(L15_2, L16_2)
  L13_2.nFadeInPoint = L14_2
  L13_2 = L11_2.CustomData
  L15_2 = L11_2
  L14_2 = L11_2.AddAnimationPoint
  L16_2 = {}
  L16_2.TranslucencyLevel = 0
  L14_2 = L14_2(L15_2, L16_2)
  L13_2.nFadeOutPoint = L14_2
  L13_2 = L12_2.CustomData
  L15_2 = L12_2
  L14_2 = L12_2.AddAnimationPoint
  L16_2 = {}
  L16_2.TranslucencyLevel = 255
  L14_2 = L14_2(L15_2, L16_2)
  L13_2.nFadeInPoint = L14_2
  L13_2 = L12_2.CustomData
  L15_2 = L12_2
  L14_2 = L12_2.AddAnimationPoint
  L16_2 = {}
  L16_2.TranslucencyLevel = 0
  L14_2 = L14_2(L15_2, L16_2)
  L13_2.nFadeOutPoint = L14_2
  L13_2 = A0_2.CustomData
  L13_2.oUpArrow = L11_2
  L13_2 = A0_2.CustomData
  L13_2.oDownArrow = L12_2
  L13_2 = L10_2[2]
  L14_2 = L10_2[3]
  L15_2 = L13_2.CustomData
  L17_2 = L13_2
  L16_2 = L13_2.AddAnimationPoint
  L18_2 = {}
  L18_2.TranslucencyLevel = 255
  L16_2 = L16_2(L17_2, L18_2)
  L15_2.nFadeInPoint = L16_2
  L15_2 = L13_2.CustomData
  L17_2 = L13_2
  L16_2 = L13_2.AddAnimationPoint
  L18_2 = {}
  L18_2.TranslucencyLevel = 0
  L16_2 = L16_2(L17_2, L18_2)
  L15_2.nFadeOutPoint = L16_2
  L15_2 = L14_2.CustomData
  L17_2 = L14_2
  L16_2 = L14_2.AddAnimationPoint
  L18_2 = {}
  L18_2.TranslucencyLevel = 255
  L16_2 = L16_2(L17_2, L18_2)
  L15_2.nFadeInPoint = L16_2
  L15_2 = L14_2.CustomData
  L17_2 = L14_2
  L16_2 = L14_2.AddAnimationPoint
  L18_2 = {}
  L18_2.TranslucencyLevel = 0
  L16_2 = L16_2(L17_2, L18_2)
  L15_2.nFadeOutPoint = L16_2
  L15_2 = A0_2.CustomData
  L15_2.oUpArrowBg = L13_2
  L15_2 = A0_2.CustomData
  L15_2.oDownArrowBg = L14_2
  L15_2 = L10_2[1]
  L17_2 = L15_2
  L16_2 = L15_2.GetLocation
  L16_2, L17_2, L18_2, L19_2 = L16_2(L17_2)
  L20_2 = L15_2.CustomData
  L22_2 = L15_2
  L21_2 = L15_2.GetChildren
  L21_2 = L21_2(L22_2)
  L20_2.tFramePieces = L21_2
  L20_2 = L15_2.CustomData
  L22_2 = L15_2
  L21_2 = L15_2.AddAnimationPoint
  L23_2 = {}
  L23_2.y = L17_2
  L23_2.y2 = L19_2
  L21_2 = L21_2(L22_2, L23_2)
  L20_2.nOriginPoint = L21_2
  L20_2 = L15_2.CustomData
  L22_2 = L15_2
  L21_2 = L15_2.AddAnimationPoint
  L23_2 = {}
  L24_2 = L17_2 + L19_2
  L24_2 = L24_2 / 2
  L23_2.y = L24_2
  L24_2 = L17_2 + L19_2
  L24_2 = L24_2 / 2
  L23_2.y2 = L24_2
  L21_2 = L21_2(L22_2, L23_2)
  L20_2.nClosePoint = L21_2
  L20_2 = A0_2.CustomData
  L20_2.oFrame = L15_2
  L20_2 = L2_2[3]
  L21_2 = L20_2
  L20_2 = L20_2.GetChildren
  L20_2 = L20_2(L21_2)
  L20_2 = L20_2[2]
  L21_2 = A0_2.CustomData
  L21_2.oBulletRing = L20_2
  L21_2 = _InitializeBullets
  L22_2 = L20_2
  L21_2(L22_2)
  L21_2 = A0_2.CustomData
  L22_2 = L2_2[3]
  L23_2 = L22_2
  L22_2 = L22_2.GetChildren
  L22_2 = L22_2(L23_2)
  L22_2 = L22_2[1]
  L21_2.oDescripters = L22_2
  L21_2 = A0_2.CustomData
  L21_2 = L21_2.oDescripters
  L22_2 = L21_2
  L21_2 = L21_2.GetChildren
  L21_2 = L21_2(L22_2)
  L22_2 = A0_2.CustomData
  L23_2 = L21_2[1]
  L22_2.oSupportNameText = L23_2
  L22_2 = A0_2.CustomData
  L23_2 = L21_2[2]
  L22_2.oFuelCostIcon = L23_2
  L22_2 = A0_2.CustomData
  L23_2 = L21_2[3]
  L22_2.oFuelCostText = L23_2
  L22_2 = A0_2.CustomData
  L23_2 = L21_2[4]
  L22_2.oStockpileText = L23_2
  L22_2 = A0_2.CustomData
  L23_2 = L21_2[5]
  L22_2.oDesignator = L23_2
  L22_2 = L15_2.CustomData
  L23_2 = A0_2.CustomData
  L23_2 = L23_2.oSupportNameText
  L22_2.oSupportNameText = L23_2
  L22_2 = A0_2.CustomData
  L23_2 = L2_2[3]
  L24_2 = L23_2
  L23_2 = L23_2.GetChildren
  L23_2 = L23_2(L24_2)
  L23_2 = L23_2[3]
  L22_2.oClockIcon = L23_2
  L22_2 = A0_2.CustomData
  L22_2 = L22_2.oClockIcon
  L23_2 = L22_2
  L22_2 = L22_2.SetVisible
  L24_2 = false
  L22_2(L23_2, L24_2)
  L22_2 = InitAddWidget
  L23_2 = 51
  L24_2 = 246
  L25_2 = 47
  L27_2 = A0_2
  L26_2 = A0_2.GetOwner
  L26_2, L27_2 = L26_2(L27_2)
  L22_2 = L22_2(L23_2, L24_2, L25_2, L26_2, L27_2)
  L23_2 = MrxGuiManager
  L23_2 = L23_2.AddWidgetToHud
  L25_2 = A0_2
  L24_2 = A0_2.GetOwner
  L24_2 = L24_2(L25_2)
  L25_2 = L22_2
  L26_2 = true
  L23_2(L24_2, L25_2, L26_2)
  L23_2 = A0_2.CustomData
  L23_2.oAddAnim = L22_2
end

HandleInitializationEvent = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.nNumberOfItems
  if L1_2 < 1 then
    L1_2 = 1
    while L1_2 <= 5 do
      L2_2 = A0_2.CustomData
      L2_2 = L2_2.tDisplayList
      L2_2 = L2_2[L1_2]
      L2_2 = L2_2.CustomData
      L2_2 = L2_2.oIcon
      L3_2 = L2_2
      L2_2 = L2_2.SetVisible
      L4_2 = false
      L2_2(L3_2, L4_2)
      L1_2 = L1_2 + 1
    end
    return
  end
  L1_2 = 1
  while L1_2 <= 5 do
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.tDisplayList
    L2_2 = L2_2[L1_2]
    L2_2 = L2_2.CustomData
    L2_2 = L2_2.oIcon
    L3_2 = L2_2
    L2_2 = L2_2.SetVisible
    L4_2 = true
    L2_2(L3_2, L4_2)
    L1_2 = L1_2 + 1
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.tDisplayList
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.tItemList
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nSelectedItemIndex
  L5_2 = math
  L5_2 = L5_2.floor
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.nMaxDisplayItems
  L6_2 = L6_2 / 2
  L5_2 = L5_2(L6_2)
  L4_2 = L4_2 - L5_2
  L5_2 = nil
  L6_2 = 1
  while true do
    L7_2 = #L2_2
    if not (L6_2 <= L7_2) then
      break
    end
    L7_2 = WrapIndex
    L8_2 = L4_2
    L9_2 = A0_2.CustomData
    L9_2 = L9_2.nNumberOfItems
    L7_2 = L7_2(L8_2, L9_2)
    L5_2 = L7_2
    L7_2 = L3_2[L5_2]
    L7_2 = L7_2.sIcon
    if L7_2 then
      L7_2 = L2_2[L6_2]
      L7_2 = L7_2.CustomData
      L7_2 = L7_2.oIcon
      L8_2 = L7_2
      L7_2 = L7_2.SetTexture
      L9_2 = L3_2[L5_2]
      L9_2 = L9_2.sIcon
      L7_2(L8_2, L9_2)
      L7_2 = L2_2[L6_2]
      L7_2 = L7_2.CustomData
      L7_2 = L7_2.oIcon
      L8_2 = L7_2
      L7_2 = L7_2.SetVisible
      L9_2 = true
      L7_2(L8_2, L9_2)
    else
      L7_2 = L2_2[L6_2]
      L7_2 = L7_2.CustomData
      L7_2 = L7_2.oIcon
      L8_2 = L7_2
      L7_2 = L7_2.SetVisible
      L9_2 = false
      L7_2(L8_2, L9_2)
    end
    L7_2 = L2_2[L6_2]
    L7_2 = L7_2.CustomData
    L8_2 = L3_2[L5_2]
    L8_2 = L8_2.sIcon
    L7_2.sIcon = L8_2
    L7_2 = L2_2[L6_2]
    L7_2 = L7_2.CustomData
    L8_2 = L3_2[L5_2]
    L8_2 = L8_2.sLitIcon
    L7_2.sLitIcon = L8_2
    L7_2 = L2_2[L6_2]
    L7_2 = L7_2.CustomData
    L7_2 = L7_2.oStatus
    L8_2 = L3_2[L5_2]
    L8_2 = L8_2.oSupport
    if L8_2 then
      L8_2 = nil
      L9_2 = MrxPmc
      L9_2 = L9_2.GetSupportQty
      L10_2 = L3_2[L5_2]
      L10_2 = L10_2.oSupport
      L11_2 = L10_2
      L10_2 = L10_2.GetSupportName
      L10_2, L11_2, L12_2, L13_2 = L10_2(L11_2)
      L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2)
      L10_2 = MrxPmc
      L10_2 = L10_2.GetFreebieQty
      L11_2 = L3_2[L5_2]
      L11_2 = L11_2.oSupport
      L12_2 = L11_2
      L11_2 = L11_2.GetSupportName
      L11_2, L12_2, L13_2 = L11_2(L12_2)
      L10_2 = L10_2(L11_2, L12_2, L13_2)
      if not L10_2 then
        L11_2 = A0_2.CustomData
        L11_2 = L11_2.bShootingGalleryMode
        if L11_2 then
          L8_2 = "disabled"
      end
      else
        L11_2 = L3_2[L5_2]
        L11_2 = L11_2.oSupport
        L12_2 = L11_2
        L11_2 = L11_2.GetFuelCost
        L11_2 = L11_2(L12_2)
        L12_2 = MrxPmc
        L12_2 = L12_2.GetFuelQty
        L12_2 = L12_2()
        if L11_2 > L12_2 then
          L11_2 = L3_2[L5_2]
          L11_2 = L11_2.oSupport
          L11_2 = L11_2.bUnrestrictedByFuel
          if not L11_2 then
            L8_2 = "fuel"
        end
        elseif L9_2 and L9_2 < 1 then
          L8_2 = "zero"
        else
          L11_2 = L3_2[L5_2]
          L11_2 = L11_2.oSupport
          L12_2 = L11_2
          L11_2 = L11_2.GetDenialCondition
          L11_2 = L11_2(L12_2)
          L8_2 = L11_2
        end
      end
      L11_2 = L2_2[L6_2]
      L12_2 = L11_2
      L11_2 = L11_2.SetStatus
      L13_2 = L8_2
      L11_2(L12_2, L13_2)
    else
      L8_2 = L2_2[L6_2]
      L9_2 = L8_2
      L8_2 = L8_2.SetStatus
      L10_2 = nil
      L8_2(L9_2, L10_2)
    end
    L6_2 = L6_2 + 1
    L4_2 = L4_2 + 1
  end
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.oCursor
  L9_2 = L7_2
  L8_2 = L7_2.SetVisible
  L10_2 = true
  L8_2(L9_2, L10_2)
  L8_2 = UpdateDisplayText
  L9_2 = A0_2
  L8_2(L9_2)
end

_SetDisplayInformation = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.nNumberOfItems
  if L1_2 <= 1 then
    return
  end
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bSuspendInput
  if L1_2 then
    L1_2 = A0_2.CustomData
    L1_2 = L1_2.bConfirmEntered
    if not L1_2 then
      L1_2 = A0_2.CustomData
      L2_2 = A0_2.CustomData
      L2_2 = L2_2.nBufferedInput
      L2_2 = L2_2 - 1
      L1_2.nBufferedInput = L2_2
    end
    return
  end
  L1_2 = A0_2.CustomData
  L1_2.bSuspendInput = true
  L1_2 = A0_2.CustomData
  L2_2 = WrapIndex
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nSelectedItemIndex
  L3_2 = L3_2 + 1
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nNumberOfItems
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.nSelectedItemIndex = L2_2
  L2_2 = A0_2
  L1_2 = A0_2._SetDisplayInformation
  L1_2(L2_2)
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.tDisplayList
  L2_2 = L1_2[1]
  L3_2 = L2_2
  L2_2 = L2_2.SetVisible
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = L1_2[2]
  L3_2 = L2_2
  L2_2 = L2_2.SetVisible
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = L1_2[3]
  L3_2 = L2_2
  L2_2 = L2_2.SetVisible
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = L1_2[4]
  L3_2 = L2_2
  L2_2 = L2_2.SetVisible
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = L1_2[1]
  L3_2 = L2_2
  L2_2 = L2_2.SetTranslucency
  L4_2 = 255
  L2_2(L3_2, L4_2)
  L2_2 = L1_2[2]
  L3_2 = L2_2
  L2_2 = L2_2.SetTranslucency
  L4_2 = 255
  L2_2(L3_2, L4_2)
  L2_2 = L1_2[3]
  L3_2 = L2_2
  L2_2 = L2_2.SetTranslucency
  L4_2 = 255
  L2_2(L3_2, L4_2)
  L2_2 = L1_2[4]
  L3_2 = L2_2
  L2_2 = L2_2.SetTranslucency
  L4_2 = 255
  L2_2(L3_2, L4_2)
  L2_2 = _HaltStatusPulse
  L3_2 = L1_2[1]
  L3_2 = L3_2.CustomData
  L3_2 = L3_2.oStatus
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = _HaltStatusPulse
  L3_2 = L1_2[2]
  L3_2 = L3_2.CustomData
  L3_2 = L3_2.oStatus
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = _HaltStatusPulse
  L3_2 = L1_2[3]
  L3_2 = L3_2.CustomData
  L3_2 = L3_2.oStatus
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = _HaltStatusPulse
  L3_2 = L1_2[4]
  L3_2 = L3_2.CustomData
  L3_2 = L3_2.oStatus
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = _SetupSquish
  L3_2 = L1_2[4]
  L4_2 = true
  L5_2 = false
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = _SetupItemPrev
  L3_2 = L1_2[3]
  L2_2(L3_2)
  L2_2 = _SetupItemPrev
  L3_2 = L1_2[2]
  L2_2(L3_2)
  L2_2 = _SetupSquish
  L3_2 = L1_2[1]
  L4_2 = false
  L5_2 = true
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oDescripters
  L3_2 = L2_2
  L2_2 = L2_2.SetVisible
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oFrame
  L4_2 = L2_2
  L3_2 = L2_2.AnimateToPoint
  L5_2 = L2_2.CustomData
  L5_2 = L5_2.nClosePoint
  L6_2 = _knFrame
  L6_2 = L6_2 * 5
  L7_2 = true
  L8_2 = _FrameClosed
  L9_2 = {}
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oUpArrow
  L5_2 = L3_2
  L4_2 = L3_2.SetVisible
  L6_2 = true
  L4_2(L5_2, L6_2)
  L5_2 = L3_2
  L4_2 = L3_2.AnimateToPoint
  L6_2 = L3_2.CustomData
  L6_2 = L6_2.nFadeInPoint
  L7_2 = 0
  L8_2 = true
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L5_2 = L3_2
  L4_2 = L3_2.AnimateToPoint
  L6_2 = L3_2.CustomData
  L6_2 = L6_2.nFadeOutPoint
  L7_2 = _knFrame
  L7_2 = L7_2 * 5
  L8_2 = false
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = A0_2.CustomData
  L4_2.nTime = 0
  L5_2 = A0_2
  L4_2 = A0_2.SetEventHandler
  L6_2 = "GuiUpdate"
  L7_2 = HandleUpdateForTriggerDown
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = A0_2.CustomData
  L4_2.nAnimatingWidgets = 0
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oClockIcon
  L5_2 = L4_2
  L4_2 = L4_2.SetVisible
  L6_2 = false
  L4_2(L5_2, L6_2)
  L4_2 = Sound
  L4_2 = L4_2.CueSound
  L5_2 = 0
  L6_2 = "ui_HUD_Support_Scroll"
  L4_2(L5_2, L6_2)
end

_ScrollDown = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.nNumberOfItems
  if L1_2 <= 1 then
    return
  end
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bSuspendInput
  if L1_2 then
    L1_2 = A0_2.CustomData
    L1_2 = L1_2.bConfirmEntered
    if not L1_2 then
      L1_2 = A0_2.CustomData
      L2_2 = A0_2.CustomData
      L2_2 = L2_2.nBufferedInput
      L2_2 = L2_2 + 1
      L1_2.nBufferedInput = L2_2
    end
    return
  end
  L1_2 = A0_2.CustomData
  L1_2.bSuspendInput = true
  L1_2 = A0_2.CustomData
  L2_2 = WrapIndex
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nSelectedItemIndex
  L3_2 = L3_2 - 1
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nNumberOfItems
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.nSelectedItemIndex = L2_2
  L2_2 = A0_2
  L1_2 = A0_2._SetDisplayInformation
  L1_2(L2_2)
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.tDisplayList
  L2_2 = L1_2[2]
  L3_2 = L2_2
  L2_2 = L2_2.SetVisible
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = L1_2[3]
  L3_2 = L2_2
  L2_2 = L2_2.SetVisible
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = L1_2[4]
  L3_2 = L2_2
  L2_2 = L2_2.SetVisible
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = L1_2[5]
  L3_2 = L2_2
  L2_2 = L2_2.SetVisible
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = L1_2[2]
  L3_2 = L2_2
  L2_2 = L2_2.SetTranslucency
  L4_2 = 255
  L2_2(L3_2, L4_2)
  L2_2 = L1_2[3]
  L3_2 = L2_2
  L2_2 = L2_2.SetTranslucency
  L4_2 = 255
  L2_2(L3_2, L4_2)
  L2_2 = L1_2[4]
  L3_2 = L2_2
  L2_2 = L2_2.SetTranslucency
  L4_2 = 255
  L2_2(L3_2, L4_2)
  L2_2 = L1_2[5]
  L3_2 = L2_2
  L2_2 = L2_2.SetTranslucency
  L4_2 = 255
  L2_2(L3_2, L4_2)
  L2_2 = _HaltStatusPulse
  L3_2 = L1_2[2]
  L3_2 = L3_2.CustomData
  L3_2 = L3_2.oStatus
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = _HaltStatusPulse
  L3_2 = L1_2[3]
  L3_2 = L3_2.CustomData
  L3_2 = L3_2.oStatus
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = _HaltStatusPulse
  L3_2 = L1_2[4]
  L3_2 = L3_2.CustomData
  L3_2 = L3_2.oStatus
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = _HaltStatusPulse
  L3_2 = L1_2[5]
  L3_2 = L3_2.CustomData
  L3_2 = L3_2.oStatus
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = _SetupSquish
  L3_2 = L1_2[2]
  L4_2 = true
  L5_2 = true
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = _SetupItemNext
  L3_2 = L1_2[3]
  L2_2(L3_2)
  L2_2 = _SetupItemNext
  L3_2 = L1_2[4]
  L2_2(L3_2)
  L2_2 = _SetupSquish
  L3_2 = L1_2[5]
  L4_2 = false
  L5_2 = false
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oDescripters
  L3_2 = L2_2
  L2_2 = L2_2.SetVisible
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oFrame
  L4_2 = L2_2
  L3_2 = L2_2.AnimateToPoint
  L5_2 = L2_2.CustomData
  L5_2 = L5_2.nClosePoint
  L6_2 = _knFrame
  L6_2 = L6_2 * 5
  L7_2 = true
  L8_2 = _FrameClosed
  L9_2 = {}
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oDownArrow
  L5_2 = L3_2
  L4_2 = L3_2.SetVisible
  L6_2 = true
  L4_2(L5_2, L6_2)
  L5_2 = L3_2
  L4_2 = L3_2.AnimateToPoint
  L6_2 = L3_2.CustomData
  L6_2 = L6_2.nFadeInPoint
  L7_2 = 0
  L8_2 = true
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L5_2 = L3_2
  L4_2 = L3_2.AnimateToPoint
  L6_2 = L3_2.CustomData
  L6_2 = L6_2.nFadeOutPoint
  L7_2 = _knFrame
  L7_2 = L7_2 * 5
  L8_2 = false
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = A0_2.CustomData
  L4_2.nTime = 0
  L5_2 = A0_2
  L4_2 = A0_2.SetEventHandler
  L6_2 = "GuiUpdate"
  L7_2 = HandleUpdateForTriggerUp
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = A0_2.CustomData
  L4_2.nAnimatingWidgets = 0
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oClockIcon
  L5_2 = L4_2
  L4_2 = L4_2.SetVisible
  L6_2 = false
  L4_2(L5_2, L6_2)
  L4_2 = Sound
  L4_2 = L4_2.CueSound
  L5_2 = 0
  L6_2 = "ui_HUD_Support_Scroll"
  L4_2(L5_2, L6_2)
end

_ScrollUp = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = {}
  L2_2 = pairs
  L3_2 = A0_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L1_2[L5_2] = L6_2
  end
  L2_2 = ValidateParameter
  L3_2 = L1_2.sName
  L4_2 = "string"
  L5_2 = "Unnamed"
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  L1_2.sName = L2_2
  L2_2 = Net
  L2_2 = L2_2.IsClient
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = type
    L3_2 = L1_2.sIcon
    L2_2 = L2_2(L3_2)
    if L2_2 ~= "string" then
      L2_2 = type
      L3_2 = L1_2.sIcon
      L2_2 = L2_2(L3_2)
      if L2_2 ~= "userdata" then
        L1_2.sIcon = "HUD_ICON_support_crate"
      end
    end
    L2_2 = type
    L3_2 = L1_2.sLitIcon
    L2_2 = L2_2(L3_2)
    if L2_2 ~= "string" then
      L2_2 = type
      L3_2 = L1_2.sLitIcon
      L2_2 = L2_2(L3_2)
      if L2_2 ~= "userdata" then
        L2_2 = L1_2.sIcon
        L1_2.sLitIcon = L2_2
      end
    end
  else
    L2_2 = ValidateParameter
    L3_2 = L1_2.sIcon
    L4_2 = "string"
    L5_2 = "HUD_ICON_support_crate"
    L2_2 = L2_2(L3_2, L4_2, L5_2)
    L1_2.sIcon = L2_2
    L2_2 = ValidateParameter
    L3_2 = L1_2.sLitIcon
    L4_2 = "string"
    L5_2 = L1_2.sIcon
    L2_2 = L2_2(L3_2, L4_2, L5_2)
    L1_2.sLitIcon = L2_2
  end
  L2_2 = ValidateParameter
  L3_2 = L1_2.oSupport
  L4_2 = "table"
  L5_2 = nil
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  L1_2.oSupport = L2_2
  L2_2 = TriggerItem
  L1_2.fTrigger = L2_2
  L2_2 = {}
  L3_2 = L1_2.oSupport
  L2_2[1] = L3_2
  L1_2.tCallbackData = L2_2
  return L1_2
end

CreateInternalListItem = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  if A0_2 then
    L1_2 = A0_2.Create
    if L1_2 then
      L1_2 = A0_2.Commence
      if L1_2 then
        goto lbl_10
      end
    end
  end
  do return end
  ::lbl_10::
  L2_2 = A0_2
  L1_2 = A0_2.Create
  L3_2 = A0_2.uOwner
  L1_2 = L1_2(L2_2, L3_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetSupportName
  L5_2 = A0_2
  L4_2 = A0_2.GetSupportName
  L4_2, L5_2 = L4_2(L5_2)
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetFuelCost
  L5_2 = A0_2
  L4_2 = A0_2.GetFuelCost
  L4_2, L5_2 = L4_2(L5_2)
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetCashCost
  L5_2 = A0_2
  L4_2 = A0_2.GetCashCost
  L4_2, L5_2 = L4_2(L5_2)
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = L1_2
  L2_2 = L1_2.Commence
  L4_2 = true
  return L2_2(L3_2, L4_2)
end

TriggerItem = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bEnabled
  if not L2_2 then
    return
  end
  L2_2 = _UpdateDisplayedText
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = _UpdateClockIcon
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

UpdateDisplayText = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 0.1
  L3_2[1] = L4_2
  L4_2 = UpdateDisplayText
  L5_2 = {}
  L6_2 = A0_2
  L7_2 = true
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

_FixText = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.tItemList
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nSelectedItemIndex
  L1_2 = L1_2[L2_2]
  L2_2 = L1_2.oSupport
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oSupportNameText
  L4_2 = L3_2
  L3_2 = L3_2.SetText
  L5_2 = L1_2.sName
  L3_2(L4_2, L5_2)
  L3_2 = L2_2 or L3_2
  if L2_2 then
    L4_2 = L2_2
    L3_2 = L2_2.GetDenialCondition
    L3_2 = L3_2(L4_2)
  end
  if L3_2 then
    L4_2 = string
    L4_2 = L4_2.lower
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    if "[pda.support.denied.rearming]" == L4_2 or "[Generic.Attitudes.Hostile]" == L3_2 then
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.oFuelCostIcon
      L5_2 = L4_2
      L4_2 = L4_2.SetTranslucency
      L6_2 = 0
      L4_2(L5_2, L6_2)
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.oFuelCostText
      L5_2 = L4_2
      L4_2 = L4_2.SetTranslucency
      L6_2 = 0
      L4_2(L5_2, L6_2)
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.oStockpileText
      L5_2 = L4_2
      L4_2 = L4_2.SetColor
      L6_2 = 255
      L7_2 = 64
      L8_2 = 64
      L4_2(L5_2, L6_2, L7_2, L8_2)
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.oStockpileText
      L5_2 = L4_2
      L4_2 = L4_2.SetText
      L6_2 = L3_2
      L4_2(L5_2, L6_2)
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.oDesignator
      L5_2 = L4_2
      L4_2 = L4_2.SetText
      L6_2 = ""
      L4_2(L5_2, L6_2)
  end
  else
    L5_2 = L2_2
    L4_2 = L2_2.GetSupportName
    L4_2 = L4_2(L5_2)
    L5_2 = MrxPmc
    L5_2 = L5_2.GetFreebieQty
    L6_2 = L4_2
    L5_2 = L5_2(L6_2)
    if L5_2 then
      if L5_2 < 1 then
        L7_2 = L2_2
        L6_2 = L2_2.GetCashCost
        L6_2 = L6_2(L7_2)
        if L6_2 then
          L7_2 = A0_2.CustomData
          L7_2 = L7_2.oStockpileText
          L8_2 = L7_2
          L7_2 = L7_2.SetText
          L9_2 = "$"
          L10_2 = L6_2
          L9_2 = L9_2 .. L10_2
          L7_2(L8_2, L9_2)
          L7_2 = MrxPmc
          L7_2 = L7_2.GetCashQty
          L7_2 = L7_2()
          if L6_2 > L7_2 then
            L7_2 = A0_2.CustomData
            L7_2 = L7_2.oStockpileText
            L8_2 = L7_2
            L7_2 = L7_2.SetColor
            L9_2 = 255
            L10_2 = 64
            L11_2 = 64
            L7_2(L8_2, L9_2, L10_2, L11_2)
          else
            L7_2 = A0_2.CustomData
            L7_2 = L7_2.oStockpileText
            L8_2 = L7_2
            L7_2 = L7_2.SetColor
            L9_2 = 255
            L10_2 = 255
            L11_2 = 255
            L7_2(L8_2, L9_2, L10_2, L11_2)
          end
        else
          L7_2 = A0_2.CustomData
          L7_2 = L7_2.oStockpileText
          L8_2 = L7_2
          L7_2 = L7_2.SetText
          L9_2 = "[Generic.SupportQtyDepleted]"
          L7_2(L8_2, L9_2)
          L7_2 = A0_2.CustomData
          L7_2 = L7_2.oStockpileText
          L8_2 = L7_2
          L7_2 = L7_2.SetColor
          L9_2 = 255
          L10_2 = 64
          L11_2 = 64
          L7_2(L8_2, L9_2, L10_2, L11_2)
        end
      else
        L6_2 = "[green]"
        L7_2 = L5_2
        L8_2 = " [Generic.SupportQtyFreeSuffix]"
        L6_2 = L6_2 .. L7_2 .. L8_2
        L7_2 = A0_2.CustomData
        L7_2 = L7_2.oStockpileText
        L8_2 = L7_2
        L7_2 = L7_2.SetText
        L9_2 = L6_2
        L7_2(L8_2, L9_2)
        L7_2 = A0_2.CustomData
        L7_2 = L7_2.oStockpileText
        L8_2 = L7_2
        L7_2 = L7_2.SetColor
        L9_2 = 255
        L10_2 = 255
        L11_2 = 255
        L7_2(L8_2, L9_2, L10_2, L11_2)
      end
    else
      L6_2 = MrxPmc
      L6_2 = L6_2.GetSupportQty
      L7_2 = L4_2
      L6_2 = L6_2(L7_2)
      if L6_2 then
        L7_2 = A0_2.CustomData
        L7_2 = L7_2.oStockpileText
        L8_2 = L7_2
        L7_2 = L7_2.SetText
        L9_2 = "[Generic.SupportQtyPrefix] "
        L10_2 = L6_2
        L9_2 = L9_2 .. L10_2
        L7_2(L8_2, L9_2)
        if L6_2 < 1 then
          L7_2 = A0_2.CustomData
          L7_2 = L7_2.oStockpileText
          L8_2 = L7_2
          L7_2 = L7_2.SetColor
          L9_2 = 255
          L10_2 = 64
          L11_2 = 64
          L7_2(L8_2, L9_2, L10_2, L11_2)
        else
          L7_2 = A0_2.CustomData
          L7_2 = L7_2.oStockpileText
          L8_2 = L7_2
          L7_2 = L7_2.SetColor
          L9_2 = 255
          L10_2 = 255
          L11_2 = 255
          L7_2(L8_2, L9_2, L10_2, L11_2)
        end
      else
        L7_2 = A0_2.CustomData
        L7_2 = L7_2.oStockpileText
        L8_2 = L7_2
        L7_2 = L7_2.SetText
        L9_2 = ""
        L7_2(L8_2, L9_2)
      end
    end
    L7_2 = L2_2
    L6_2 = L2_2.GetFuelCost
    L6_2 = L6_2(L7_2)
    if not L6_2 or L6_2 == 0 then
      L7_2 = A0_2.CustomData
      L7_2 = L7_2.oFuelCostText
      L8_2 = L7_2
      L7_2 = L7_2.SetTranslucency
      L9_2 = 0
      L7_2(L8_2, L9_2)
      L7_2 = A0_2.CustomData
      L7_2 = L7_2.oFuelCostIcon
      L8_2 = L7_2
      L7_2 = L7_2.SetTranslucency
      L9_2 = 0
      L7_2(L8_2, L9_2)
    else
      L7_2 = A0_2.CustomData
      L7_2 = L7_2.oFuelCostIcon
      L8_2 = L7_2
      L7_2 = L7_2.SetTranslucency
      L9_2 = 255
      L7_2(L8_2, L9_2)
      L7_2 = A0_2.CustomData
      L7_2 = L7_2.oFuelCostText
      L8_2 = L7_2
      L7_2 = L7_2.SetTranslucency
      L9_2 = 255
      L7_2(L8_2, L9_2)
      L7_2 = A0_2.CustomData
      L7_2 = L7_2.oFuelCostText
      L8_2 = L7_2
      L7_2 = L7_2.SetText
      L9_2 = L6_2
      L7_2(L8_2, L9_2)
      L7_2 = MrxPmc
      L7_2 = L7_2.GetFuelQty
      L7_2 = L7_2()
      if L6_2 > L7_2 then
        L7_2 = L2_2.bUnrestrictedByFuel
        if not L7_2 then
          L7_2 = A0_2.CustomData
          L7_2 = L7_2.oFuelCostText
          L8_2 = L7_2
          L7_2 = L7_2.SetColor
          L9_2 = 255
          L10_2 = 64
          L11_2 = 64
          L7_2(L8_2, L9_2, L10_2, L11_2)
          L7_2 = A0_2.CustomData
          L7_2 = L7_2.oFuelCostIcon
          L8_2 = L7_2
          L7_2 = L7_2.SetColor
          L9_2 = 255
          L10_2 = 64
          L11_2 = 64
          L7_2(L8_2, L9_2, L10_2, L11_2)
      end
      else
        L7_2 = A0_2.CustomData
        L7_2 = L7_2.oFuelCostText
        L8_2 = L7_2
        L7_2 = L7_2.SetColor
        L9_2 = 255
        L10_2 = 255
        L11_2 = 255
        L7_2(L8_2, L9_2, L10_2, L11_2)
        L7_2 = A0_2.CustomData
        L7_2 = L7_2.oFuelCostIcon
        L8_2 = L7_2
        L7_2 = L7_2.SetColor
        L9_2 = 255
        L10_2 = 255
        L11_2 = 255
        L7_2(L8_2, L9_2, L10_2, L11_2)
      end
    end
    L7_2 = " "
    L9_2 = L2_2
    L8_2 = L2_2.GetDesignator
    L8_2 = L8_2(L9_2)
    if L8_2 then
      L9_2 = L2_2
      L8_2 = L2_2.GetDesignator
      L8_2 = L8_2(L9_2)
      L9_2 = L8_2
      L8_2 = L8_2.GetType
      L8_2 = L8_2(L9_2)
      if "smoke" == L8_2 then
        L7_2 = "[Generic.SupportDesignators.Smoke]"
      elseif "satellite" == L8_2 then
        L7_2 = "[Generic.SupportDesignators.Satellite]"
      elseif "advanced satellite" == L8_2 then
        L7_2 = "[Generic.SupportDesignators.AdvSatellite]"
      elseif "beacon" == L8_2 then
        L7_2 = "[Generic.SupportDesignators.Beacon]"
      elseif "laser" == L8_2 then
        L7_2 = "[Generic.SupportDesignators.Laser]"
      elseif "flare" == L8_2 then
        L7_2 = "[Generic.SupportDesignators.Flare]"
      end
    end
    L8_2 = A0_2.CustomData
    L8_2 = L8_2.oDesignator
    L9_2 = L8_2
    L8_2 = L8_2.SetText
    L10_2 = L7_2
    L8_2(L9_2, L10_2)
  end
end

_UpdateDisplayedText = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.tItemList
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nSelectedItemIndex
  L2_2 = L2_2[L3_2]
  L3_2 = L2_2.oSupport
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oClockIcon
  L5_2 = L4_2
  L4_2 = L4_2.SetVisible
  L6_2 = false
  L4_2(L5_2, L6_2)
  if L3_2 then
    L4_2 = L3_2.GetElapsedCooldownTime
    if L4_2 then
      L5_2 = L3_2
      L4_2 = L3_2.GetElapsedCooldownTime
      L4_2, L5_2 = L4_2(L5_2)
      if L4_2 and L5_2 and L4_2 < L5_2 then
        L6_2 = A0_2.CustomData
        L6_2 = L6_2.oClockIcon
        L7_2 = L6_2
        L6_2 = L6_2.SetVisible
        L8_2 = true
        L6_2(L7_2, L8_2)
        if 0 < L5_2 then
          L6_2 = A0_2.CustomData
          L6_2 = L6_2.oClockIcon
          L7_2 = L6_2
          L6_2 = L6_2.SetClockAnimation
          L8_2 = L4_2
          L9_2 = L5_2
          L6_2(L7_2, L8_2, L9_2)
          if not A1_2 then
            L6_2 = A0_2.CustomData
            L6_2 = L6_2.oClockIcon
            L7_2 = L6_2
            L6_2 = L6_2.SetClockAnimationCallback
            L8_2 = _FixText
            L9_2 = {}
            L10_2 = A0_2
            L9_2[1] = L10_2
            L6_2(L7_2, L8_2, L9_2)
          end
        end
      else
        L6_2 = A0_2.CustomData
        L6_2 = L6_2.oClockIcon
        L7_2 = L6_2
        L6_2 = L6_2.SetClockAnimationCallback
        L8_2 = nil
        L9_2 = nil
        L6_2(L7_2, L8_2, L9_2)
      end
  end
  else
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.oClockIcon
    L5_2 = L4_2
    L4_2 = L4_2.SetClockAnimationCallback
    L6_2 = nil
    L7_2 = nil
    L4_2(L5_2, L6_2, L7_2)
  end
end

_UpdateClockIcon = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.tDisplayList
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.tItemList
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nSelectedItemIndex
  L4_2 = math
  L4_2 = L4_2.floor
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nMaxDisplayItems
  L5_2 = L5_2 / 2
  L4_2 = L4_2(L5_2)
  L3_2 = L3_2 - L4_2
  L4_2 = nil
  L5_2 = 1
  while true do
    L6_2 = #L1_2
    if not (L5_2 <= L6_2) then
      break
    end
    L6_2 = WrapIndex
    L7_2 = L3_2
    L8_2 = A0_2.CustomData
    L8_2 = L8_2.nNumberOfItems
    L6_2 = L6_2(L7_2, L8_2)
    L4_2 = L6_2
    L6_2 = L1_2[L5_2]
    L6_2 = L6_2.CustomData
    L6_2 = L6_2.oStatus
    L7_2 = L2_2[L4_2]
    L7_2 = L7_2.oSupport
    if L7_2 then
      L7_2 = nil
      L8_2 = MrxPmc
      L8_2 = L8_2.GetSupportQty
      L9_2 = L2_2[L4_2]
      L9_2 = L9_2.oSupport
      L10_2 = L9_2
      L9_2 = L9_2.GetSupportName
      L9_2, L10_2, L11_2, L12_2 = L9_2(L10_2)
      L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
      L9_2 = MrxPmc
      L9_2 = L9_2.GetFreebieQty
      L10_2 = L2_2[L4_2]
      L10_2 = L10_2.oSupport
      L11_2 = L10_2
      L10_2 = L10_2.GetSupportName
      L10_2, L11_2, L12_2 = L10_2(L11_2)
      L9_2 = L9_2(L10_2, L11_2, L12_2)
      if not L9_2 then
        L10_2 = A0_2.CustomData
        L10_2 = L10_2.bShootingGalleryMode
        if L10_2 then
          L7_2 = "disabled"
      end
      else
        L10_2 = L2_2[L4_2]
        L10_2 = L10_2.oSupport
        L11_2 = L10_2
        L10_2 = L10_2.GetFuelCost
        L10_2 = L10_2(L11_2)
        L11_2 = MrxPmc
        L11_2 = L11_2.GetFuelQty
        L11_2 = L11_2()
        if L10_2 > L11_2 then
          L10_2 = L2_2[L4_2]
          L10_2 = L10_2.oSupport
          L10_2 = L10_2.bUnrestrictedByFuel
          if not L10_2 then
            L7_2 = "fuel"
        end
        elseif L8_2 and L8_2 < 1 then
          L7_2 = "zero"
        else
          L10_2 = L2_2[L4_2]
          L10_2 = L10_2.oSupport
          L11_2 = L10_2
          L10_2 = L10_2.GetDenialCondition
          L10_2 = L10_2(L11_2)
          L7_2 = L10_2
        end
      end
      L10_2 = L1_2[L5_2]
      L11_2 = L10_2
      L10_2 = L10_2.SetStatus
      L12_2 = L7_2
      L10_2(L11_2, L12_2)
    else
      L7_2 = L1_2[L5_2]
      L8_2 = L7_2
      L7_2 = L7_2.SetStatus
      L9_2 = nil
      L7_2(L8_2, L9_2)
    end
    L5_2 = L5_2 + 1
    L3_2 = L3_2 + 1
  end
end

_UpdateStatusDisplay = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = _UpdateDisplayedText
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = _UpdateStatusDisplay
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.tItemList
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nSelectedItemIndex
  L1_2 = L1_2[L2_2]
  L2_2 = L1_2.oSupport
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oClockIcon
  L4_2 = L3_2
  L3_2 = L3_2.GetVisible
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L3_2 = _UpdateClockIcon
    L4_2 = A0_2
    L5_2 = false
    L3_2(L4_2, L5_2)
  end
end

_UpdateDisplayPeriodic = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nIdleTime
  if not L2_2 then
    L2_2 = A0_2.CustomData
    L2_2.nIdleTime = 0
  end
  L2_2 = A0_2.CustomData
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nIdleTime
  L3_2 = A1_2 + L3_2
  L2_2.nIdleTime = L3_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nIdleTime
  if 0.5 < L2_2 then
    L2_2 = _UpdateDisplayPeriodic
    L3_2 = A0_2
    L2_2(L3_2)
    L2_2 = A0_2.CustomData
    L2_2.nIdleTime = 0
  end
end

HandleUpdateForIdle = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oSupportNameText
  L2_2 = L1_2
  L1_2 = L1_2.GetLocation
  L1_2 = L1_2(L2_2)
  L2_2 = math
  L2_2 = L2_2.max
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oSupportNameText
  L4_2 = L3_2
  L3_2 = L3_2.GetWidth
  L3_2 = L3_2(L4_2)
  L4_2 = 140
  L2_2 = L2_2(L3_2, L4_2)
  L1_2 = L1_2 + L2_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.tFramePieces
  L2_2 = L2_2[2]
  L3_2 = L2_2
  L2_2 = L2_2.GetLocation
  L2_2 = L2_2(L3_2)
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.tFramePieces
  L3_2 = L3_2[2]
  L4_2 = L3_2
  L3_2 = L3_2.SetLocation
  L5_2 = L2_2
  L6_2 = nil
  L7_2 = L1_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
  L3_2 = nil
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.tFramePieces
  L4_2 = L4_2[3]
  L5_2 = L4_2
  L4_2 = L4_2.GetLocation
  L4_2, L5_2 = L4_2(L5_2)
  L3_2 = L5_2
  L2_2 = L4_2
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.tFramePieces
  L4_2 = L4_2[3]
  L5_2 = L4_2
  L4_2 = L4_2.SetLocation
  L6_2 = L1_2
  L7_2 = L3_2
  L4_2(L5_2, L6_2, L7_2)
  L5_2 = A0_2
  L4_2 = A0_2.SetVisible
  L6_2 = false
  L4_2(L5_2, L6_2)
end

_FrameClosed = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  if not A1_2 then
    return
  end
  L2_2 = _knFrame
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nTime
  if not L3_2 then
    L3_2 = A0_2.CustomData
    L3_2.nTime = 0
  end
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nTime
  L4_2 = L3_2 + A1_2
  L5_2 = A0_2.CustomData
  L5_2.nTime = L4_2
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.tDisplayList
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 4
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = math
    L6_2 = L6_2.max
    L7_2 = 0
    L8_2 = L2_2 * 4
    L8_2 = L4_2 - L8_2
    L6_2 = L6_2(L7_2, L8_2)
    L7_2 = L5_2[2]
    L8_2 = L7_2
    L7_2 = L7_2.TriggerSquish
    L9_2 = L2_2 * 10
    L10_2 = true
    L11_2 = true
    L7_2(L8_2, L9_2, L10_2, L11_2)
  end
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 5
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = L5_2[3]
    L7_2 = L6_2
    L6_2 = L6_2.TriggerNext
    L8_2 = L2_2 * 10
    L6_2(L7_2, L8_2)
  end
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 6
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = L5_2[4]
    L7_2 = L6_2
    L6_2 = L6_2.TriggerNext
    L8_2 = L2_2 * 10
    L6_2(L7_2, L8_2)
  end
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 7
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = L5_2[5]
    L7_2 = L6_2
    L6_2 = L6_2.TriggerSquish
    L8_2 = L2_2 * 10
    L9_2 = false
    L10_2 = false
    L6_2(L7_2, L8_2, L9_2, L10_2)
  end
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 12
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.oFrame
    L8_2 = L6_2
    L7_2 = L6_2.SetVisible
    L9_2 = true
    L7_2(L8_2, L9_2)
    L8_2 = L6_2
    L7_2 = L6_2.AnimateToPoint
    L9_2 = L6_2.CustomData
    L9_2 = L9_2.nOriginPoint
    L10_2 = L2_2 * 5
    L11_2 = true
    L12_2 = _FrameAnimationCompleteCallback
    L13_2 = {}
    L14_2 = A0_2
    L13_2[1] = L14_2
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
    L7_2 = A0_2.CustomData
    L7_2.nTime = 0
    L8_2 = A0_2
    L7_2 = A0_2.SetEventHandler
    L9_2 = "GuiUpdate"
    L10_2 = HandleUpdateForIdle
    L7_2(L8_2, L9_2, L10_2)
  end
end

HandleUpdateForTriggerUp = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  if not A1_2 then
    return
  end
  L2_2 = _knFrame
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nTime
  if not L3_2 then
    L3_2 = A0_2.CustomData
    L3_2.nTime = 0
  end
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nTime
  L4_2 = L3_2 + A1_2
  L5_2 = A0_2.CustomData
  L5_2.nTime = L4_2
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.tDisplayList
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 4
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = L5_2[4]
    L7_2 = L6_2
    L6_2 = L6_2.TriggerSquish
    L8_2 = L2_2 * 10
    L9_2 = true
    L10_2 = false
    L6_2(L7_2, L8_2, L9_2, L10_2)
  end
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 5
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = L5_2[3]
    L7_2 = L6_2
    L6_2 = L6_2.TriggerPrev
    L8_2 = L2_2 * 10
    L6_2(L7_2, L8_2)
  end
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 6
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = L5_2[2]
    L7_2 = L6_2
    L6_2 = L6_2.TriggerPrev
    L8_2 = L2_2 * 10
    L6_2(L7_2, L8_2)
  end
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 7
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = L5_2[1]
    L7_2 = L6_2
    L6_2 = L6_2.TriggerSquish
    L8_2 = L2_2 * 10
    L9_2 = false
    L10_2 = true
    L6_2(L7_2, L8_2, L9_2, L10_2)
  end
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 12
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.oFrame
    L8_2 = L6_2
    L7_2 = L6_2.SetVisible
    L9_2 = true
    L7_2(L8_2, L9_2)
    L8_2 = L6_2
    L7_2 = L6_2.AnimateToPoint
    L9_2 = L6_2.CustomData
    L9_2 = L9_2.nOriginPoint
    L10_2 = L2_2 * 5
    L11_2 = true
    L12_2 = _FrameAnimationCompleteCallback
    L13_2 = {}
    L14_2 = A0_2
    L13_2[1] = L14_2
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
    L7_2 = A0_2.CustomData
    L7_2.nTime = 0
    L8_2 = A0_2
    L7_2 = A0_2.SetEventHandler
    L9_2 = "GuiUpdate"
    L10_2 = HandleUpdateForIdle
    L7_2(L8_2, L9_2, L10_2)
    L7_2 = A0_2.CustomData
    L7_2 = L7_2.tPendingItemQueue
    L7_2 = #L7_2
    if 0 < L7_2 then
      L7_2 = _AddAnimationComplete
      L8_2 = nil
      L9_2 = A0_2
      L7_2(L8_2, L9_2)
    end
  end
end

HandleUpdateForTriggerDown = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  if not A1_2 then
    return
  end
  L2_2 = 0.016666668
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nTime
  if not L3_2 then
    L3_2 = A0_2.CustomData
    L3_2.nTime = 0
  end
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nTime
  L4_2 = L3_2 + A1_2
  L5_2 = A0_2.CustomData
  L5_2.nTime = L4_2
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.tDisplayList
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 3
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = L5_2[3]
    L6_2 = L6_2.CustomData
    L6_2 = L6_2.oOrbit
    L7_2 = L6_2
    L6_2 = L6_2.AnimateToPoint
    L8_2 = L5_2[3]
    L8_2 = L8_2.CustomData
    L8_2 = L8_2.oOrbit
    L8_2 = L8_2.CustomData
    L8_2 = L8_2.nFadeInPoint
    L9_2 = L2_2 * 10
    L10_2 = false
    L6_2(L7_2, L8_2, L9_2, L10_2)
  end
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 5
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = L5_2[2]
    L7_2 = L6_2
    L6_2 = L6_2.TriggerOpen
    L8_2 = L2_2 * 5
    L6_2(L7_2, L8_2)
  end
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 6
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = L5_2[4]
    L6_2 = L6_2.CustomData
    L6_2 = L6_2.oOrbit
    L7_2 = L6_2
    L6_2 = L6_2.AnimateToPoint
    L8_2 = L5_2[4]
    L8_2 = L8_2.CustomData
    L8_2 = L8_2.oOrbit
    L8_2 = L8_2.CustomData
    L8_2 = L8_2.nFadeInPoint
    L9_2 = L2_2 * 10
    L10_2 = false
    L6_2(L7_2, L8_2, L9_2, L10_2)
  end
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 8
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = L5_2[3]
    L7_2 = L6_2
    L6_2 = L6_2.TriggerOpen
    L8_2 = L2_2 * 5
    L6_2(L7_2, L8_2)
  end
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 11
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = L5_2[4]
    L7_2 = L6_2
    L6_2 = L6_2.TriggerOpen
    L8_2 = L2_2 * 5
    L6_2(L7_2, L8_2)
  end
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 13
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.oFrame
    L8_2 = L6_2
    L7_2 = L6_2.SetVisible
    L9_2 = true
    L7_2(L8_2, L9_2)
    L8_2 = L6_2
    L7_2 = L6_2.AnimateToPoint
    L9_2 = L6_2.CustomData
    L9_2 = L9_2.nOriginPoint
    L10_2 = L2_2 * 5
    L11_2 = true
    L12_2 = _SetVisible
    L13_2 = {}
    L14_2 = A0_2.CustomData
    L14_2 = L14_2.oDescripters
    L15_2 = true
    L13_2[1] = L14_2
    L13_2[2] = L15_2
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  end
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 20
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = A0_2.CustomData
    L6_2.nTime = 0
    L7_2 = A0_2
    L6_2 = A0_2.SetEventHandler
    L8_2 = "GuiUpdate"
    L9_2 = HandleUpdateForIdle
    L6_2(L7_2, L8_2, L9_2)
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.nNumberOfItems
    if 1 < L6_2 then
      L6_2 = A0_2.CustomData
      L6_2 = L6_2.oUpArrowBg
      L7_2 = A0_2.CustomData
      L7_2 = L7_2.oDownArrowBg
      L9_2 = L6_2
      L8_2 = L6_2.SetTranslucency
      L10_2 = 0
      L8_2(L9_2, L10_2)
      L9_2 = L7_2
      L8_2 = L7_2.SetTranslucency
      L10_2 = 0
      L8_2(L9_2, L10_2)
      L9_2 = L6_2
      L8_2 = L6_2.SetVisible
      L10_2 = true
      L8_2(L9_2, L10_2)
      L9_2 = L7_2
      L8_2 = L7_2.SetVisible
      L10_2 = true
      L8_2(L9_2, L10_2)
      L9_2 = L6_2
      L8_2 = L6_2.GetChildren
      L8_2 = L8_2(L9_2)
      L8_2 = L8_2[1]
      L9_2 = L8_2
      L8_2 = L8_2.SetVisible
      L10_2 = false
      L8_2(L9_2, L10_2)
      L9_2 = L7_2
      L8_2 = L7_2.GetChildren
      L8_2 = L8_2(L9_2)
      L8_2 = L8_2[1]
      L9_2 = L8_2
      L8_2 = L8_2.SetVisible
      L10_2 = false
      L8_2(L9_2, L10_2)
      L9_2 = L6_2
      L8_2 = L6_2.AnimateToPoint
      L10_2 = L6_2.CustomData
      L10_2 = L10_2.nFadeInPoint
      L11_2 = L2_2 * 5
      L12_2 = true
      L8_2(L9_2, L10_2, L11_2, L12_2)
      L9_2 = L7_2
      L8_2 = L7_2.AnimateToPoint
      L10_2 = L7_2.CustomData
      L10_2 = L10_2.nFadeInPoint
      L11_2 = L2_2 * 5
      L12_2 = true
      L13_2 = _AnimationCompleteCallback
      L14_2 = {}
      L15_2 = A0_2
      L14_2[1] = L15_2
      L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
    else
      L6_2 = _AnimationCompleteCallback
      L7_2 = A0_2
      L8_2 = A0_2
      L6_2(L7_2, L8_2)
    end
  end
end

HandleUpdateForOpen = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  if not A1_2 then
    return
  end
  L2_2 = _knFrame
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nTime
  if not L3_2 then
    L3_2 = A0_2.CustomData
    L3_2.nTime = 0
  end
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nTime
  L4_2 = L3_2 + A1_2
  L5_2 = A0_2.CustomData
  L5_2.nTime = L4_2
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.tDisplayList
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 1
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.oBulletRing
    L7_2 = L6_2
    L6_2 = L6_2.AnimateBullet
    L8_2 = 1
    L9_2 = L2_2 * 15
    L10_2 = 0
    L11_2 = 180
    L12_2 = 1
    L13_2 = true
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.oUpArrowBg
    L7_2 = A0_2.CustomData
    L7_2 = L7_2.oDownArrowBg
    L9_2 = L6_2
    L8_2 = L6_2.AnimateToPoint
    L10_2 = L6_2.CustomData
    L10_2 = L10_2.nFadeOutPoint
    L11_2 = L2_2 * 5
    L12_2 = true
    L8_2(L9_2, L10_2, L11_2, L12_2)
    L9_2 = L7_2
    L8_2 = L7_2.AnimateToPoint
    L10_2 = L7_2.CustomData
    L10_2 = L10_2.nFadeOutPoint
    L11_2 = L2_2 * 5
    L12_2 = true
    L8_2(L9_2, L10_2, L11_2, L12_2)
  end
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 2
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.oBulletRing
    L7_2 = L6_2
    L6_2 = L6_2.AnimateBullet
    L8_2 = 2
    L9_2 = L2_2 * 15
    L10_2 = 0
    L11_2 = 180
    L12_2 = 1
    L13_2 = true
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  end
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 3
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.oBulletRing
    L7_2 = L6_2
    L6_2 = L6_2.AnimateBullet
    L8_2 = 3
    L9_2 = L2_2 * 15
    L10_2 = 0
    L11_2 = 180
    L12_2 = 1
    L13_2 = true
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  end
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 4
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.oBulletRing
    L7_2 = L6_2
    L6_2 = L6_2.AnimateBullet
    L8_2 = 4
    L9_2 = L2_2 * 15
    L10_2 = 0
    L11_2 = 180
    L12_2 = 1
    L13_2 = true
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  end
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 5
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.oBulletRing
    L7_2 = L6_2
    L6_2 = L6_2.AnimateBullet
    L8_2 = 5
    L9_2 = L2_2 * 15
    L10_2 = 0
    L11_2 = 180
    L12_2 = 1
    L13_2 = true
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.oDescripters
    L7_2 = L6_2
    L6_2 = L6_2.SetVisible
    L8_2 = false
    L6_2(L7_2, L8_2)
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.oFrame
    L8_2 = L6_2
    L7_2 = L6_2.AnimateToPoint
    L9_2 = L6_2.CustomData
    L9_2 = L9_2.nClosePoint
    L10_2 = L2_2 * 5
    L11_2 = true
    L7_2(L8_2, L9_2, L10_2, L11_2)
  end
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 7
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = L5_2[2]
    L7_2 = L6_2
    L6_2 = L6_2.TriggerClose
    L8_2 = L2_2 * 5
    L6_2(L7_2, L8_2)
  end
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 9
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = L5_2[3]
    L7_2 = L6_2
    L6_2 = L6_2.TriggerClose
    L8_2 = L2_2 * 5
    L6_2(L7_2, L8_2)
  end
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 11
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = L5_2[4]
    L7_2 = L6_2
    L6_2 = L6_2.TriggerClose
    L8_2 = L2_2 * 5
    L6_2(L7_2, L8_2)
  end
  L6_2 = _PassedPoint
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L2_2 * 22
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L7_2 = A0_2
    L6_2 = A0_2.SetVisible
    L8_2 = false
    L6_2(L7_2, L8_2)
    L7_2 = A0_2
    L6_2 = A0_2.SetEventHandler
    L8_2 = "GuiUpdate"
    L9_2 = nil
    L6_2(L7_2, L8_2, L9_2)
    L6_2 = A0_2.CustomData
    L6_2.nTime = 0
    L6_2 = A0_2.CustomData
    L6_2.bSuspendInput = false
    L6_2 = A0_2.CustomData
    L6_2 = L6_2.tPendingItemQueue
    L6_2 = #L6_2
    if 0 < L6_2 then
      L6_2 = _AddAnimationComplete
      L7_2 = nil
      L8_2 = A0_2
      L6_2(L7_2, L8_2)
    end
  end
end

HandleUpdateForClose = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2
  if A0_2 < A1_2 then
    if A0_2 < A2_2 and A2_2 <= A1_2 then
      L3_2 = true
      return L3_2
    end
  elseif A1_2 < A0_2 and A2_2 < A0_2 and A1_2 <= A2_2 then
    L3_2 = true
    return L3_2
  end
  L3_2 = false
  return L3_2
end

_PassedPoint = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  L4_2 = A1_2
  L3_2 = A1_2.SetVisible
  L5_2 = A2_2
  L3_2(L4_2, L5_2)
end

_SetVisible = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2
  L2_2 = A1_2[A0_2]
  L3_2 = L2_2.CustomData
  L5_2 = L2_2
  L4_2 = L2_2.GetChildren
  L4_2 = L4_2(L5_2)
  L5_2 = L4_2[1]
  L6_2 = L4_2[2]
  L7_2 = L4_2[3]
  L8_2 = L4_2[4]
  L9_2 = L4_2[5]
  L3_2.oIconBg = L5_2
  L3_2.oIcon = L6_2
  L3_2.oBorder = L7_2
  L3_2.oOrbit = L8_2
  L3_2.oStatus = L9_2
  L10_2 = A0_2 + 1
  L10_2 = A1_2[L10_2]
  if L10_2 then
    L10_2 = A0_2 + 1
    L10_2 = A1_2[L10_2]
    L12_2 = L10_2
    L11_2 = L10_2.GetLocation
    L11_2, L12_2 = L11_2(L12_2)
    L14_2 = L2_2
    L13_2 = L2_2.AddAnimationPoint
    L15_2 = {}
    L15_2.x = L11_2
    L15_2.y = L12_2
    L13_2 = L13_2(L14_2, L15_2)
    L3_2.nNextPoint = L13_2
  end
  L10_2 = A0_2 - 1
  L10_2 = A1_2[L10_2]
  if L10_2 then
    L10_2 = A0_2 - 1
    L10_2 = A1_2[L10_2]
    L12_2 = L10_2
    L11_2 = L10_2.GetLocation
    L11_2, L12_2 = L11_2(L12_2)
    L14_2 = L2_2
    L13_2 = L2_2.AddAnimationPoint
    L15_2 = {}
    L15_2.x = L11_2
    L15_2.y = L12_2
    L13_2 = L13_2(L14_2, L15_2)
    L3_2.nPrevPoint = L13_2
  end
  L11_2 = L2_2
  L10_2 = L2_2.GetLocation
  L10_2, L11_2, L12_2, L13_2 = L10_2(L11_2)
  L15_2 = L2_2
  L14_2 = L2_2.AddAnimationPoint
  L16_2 = {}
  L16_2.x = L10_2
  L16_2.y = L11_2
  L16_2.x2 = L12_2
  L16_2.y2 = L13_2
  L14_2 = L14_2(L15_2, L16_2)
  L3_2.nOriginPoint = L14_2
  L15_2 = L2_2
  L14_2 = L2_2.AddAnimationPoint
  L16_2 = {}
  L16_2.x = L10_2
  L16_2.y = L11_2
  L16_2.x2 = L12_2
  L16_2.y2 = L11_2
  L14_2 = L14_2(L15_2, L16_2)
  L3_2.nSquishTop = L14_2
  L15_2 = L2_2
  L14_2 = L2_2.AddAnimationPoint
  L16_2 = {}
  L16_2.x = L10_2
  L16_2.y = L13_2
  L16_2.x2 = L12_2
  L16_2.y2 = L13_2
  L14_2 = L14_2(L15_2, L16_2)
  L3_2.nSquishBottom = L14_2
  L15_2 = L2_2
  L14_2 = L2_2.AddAnimationPoint
  L16_2 = {}
  L17_2 = L10_2 - 25
  L16_2.x = L17_2
  L16_2.y = L11_2
  L14_2 = L14_2(L15_2, L16_2)
  L3_2.nExitPoint = L14_2
  L15_2 = L2_2
  L14_2 = L2_2.AddAnimationPoint
  L16_2 = {}
  L16_2.x = L10_2
  L16_2.y = L11_2
  L14_2 = L14_2(L15_2, L16_2)
  L3_2.nEnterPoint = L14_2
  L14_2 = 0.75
  L15_2 = nil
  L16_2 = nil
  L17_2 = nil
  L18_2 = nil
  L19_2 = A0_2 - 1
  L19_2 = A1_2[L19_2]
  if L19_2 then
    L19_2 = A0_2 - 1
    L19_2 = A1_2[L19_2]
    L21_2 = L19_2
    L20_2 = L19_2.GetChildren
    L20_2 = L20_2(L21_2)
    L15_2 = L20_2[2]
    L21_2 = L19_2
    L20_2 = L19_2.GetChildren
    L20_2 = L20_2(L21_2)
    L16_2 = L20_2[1]
  end
  L19_2 = A0_2 + 1
  L19_2 = A1_2[L19_2]
  if L19_2 then
    L19_2 = A0_2 + 1
    L19_2 = A1_2[L19_2]
    L21_2 = L19_2
    L20_2 = L19_2.GetChildren
    L20_2 = L20_2(L21_2)
    L17_2 = L20_2[2]
    L21_2 = L19_2
    L20_2 = L19_2.GetChildren
    L20_2 = L20_2(L21_2)
    L18_2 = L20_2[1]
  end
  L19_2 = _SetUpFlipPoints
  L20_2 = L6_2
  L21_2 = L15_2
  L22_2 = L17_2
  L19_2(L20_2, L21_2, L22_2)
  L19_2 = _SetUpFlipPoints
  L20_2 = L5_2
  L21_2 = L16_2
  L22_2 = L18_2
  L19_2(L20_2, L21_2, L22_2)
  L19_2 = _TriggerItemFlipIn
  L2_2.FlipIconIn = L19_2
  L19_2 = _TriggerItemFlipOut
  L2_2.FlipIconOut = L19_2
  L19_2 = L7_2.CustomData
  L21_2 = L7_2
  L20_2 = L7_2.AddAnimationPoint
  L22_2 = {}
  L22_2.TranslucencyLevel = 0
  L20_2 = L20_2(L21_2, L22_2)
  L19_2.nFadeOutPoint = L20_2
  L19_2 = L7_2.CustomData
  L21_2 = L7_2
  L20_2 = L7_2.AddAnimationPoint
  L22_2 = {}
  L22_2.TranslucencyLevel = 255
  L20_2 = L20_2(L21_2, L22_2)
  L19_2.nFadeInPoint = L20_2
  L19_2 = nil
  L20_2 = nil
  L21_2 = A0_2 - 1
  L21_2 = A1_2[L21_2]
  if L21_2 then
    L21_2 = A0_2 - 1
    L21_2 = A1_2[L21_2]
    L22_2 = L21_2
    L21_2 = L21_2.GetChildren
    L21_2 = L21_2(L22_2)
    L20_2 = L21_2[3]
  end
  L21_2 = A0_2 + 1
  L21_2 = A1_2[L21_2]
  if L21_2 then
    L21_2 = A0_2 + 1
    L21_2 = A1_2[L21_2]
    L22_2 = L21_2
    L21_2 = L21_2.GetChildren
    L21_2 = L21_2(L22_2)
    L19_2 = L21_2[3]
  end
  L21_2 = _SetUpScaledPoints
  L22_2 = L7_2
  L23_2 = L20_2
  L24_2 = L19_2
  L21_2(L22_2, L23_2, L24_2)
  L21_2 = L8_2.CustomData
  L23_2 = L8_2
  L22_2 = L8_2.AddAnimationPoint
  L24_2 = {}
  L24_2.TranslucencyLevel = 0
  L24_2.nRotation = -90
  L24_2.nRotationDirection = -1
  L22_2 = L22_2(L23_2, L24_2)
  L21_2.nFadeOutPoint = L22_2
  L21_2 = L8_2.CustomData
  L23_2 = L8_2
  L22_2 = L8_2.AddAnimationPoint
  L24_2 = {}
  L24_2.TranslucencyLevel = 255
  L24_2.nRotation = 0
  L24_2.nRotationDirection = 1
  L22_2 = L22_2(L23_2, L24_2)
  L21_2.nFadeInPoint = L22_2
  L21_2 = nil
  L22_2 = nil
  L23_2 = A0_2 - 1
  L23_2 = A1_2[L23_2]
  if L23_2 then
    L23_2 = A0_2 - 1
    L23_2 = A1_2[L23_2]
    L24_2 = L23_2
    L23_2 = L23_2.GetChildren
    L23_2 = L23_2(L24_2)
    L22_2 = L23_2[4]
  end
  L23_2 = A0_2 + 1
  L23_2 = A1_2[L23_2]
  if L23_2 then
    L23_2 = A0_2 + 1
    L23_2 = A1_2[L23_2]
    L24_2 = L23_2
    L23_2 = L23_2.GetChildren
    L23_2 = L23_2(L24_2)
    L21_2 = L23_2[4]
  end
  L23_2 = _SetUpScaledPoints
  L24_2 = L8_2
  L25_2 = L22_2
  L26_2 = L21_2
  L23_2(L24_2, L25_2, L26_2)
  L23_2 = L9_2.CustomData
  L25_2 = L9_2
  L24_2 = L9_2.AddAnimationPoint
  L26_2 = {}
  L26_2.TranslucencyLevel = 255
  L24_2 = L24_2(L25_2, L26_2)
  L23_2.nFadeInPoint = L24_2
  L23_2 = L9_2.CustomData
  L25_2 = L9_2
  L24_2 = L9_2.AddAnimationPoint
  L26_2 = {}
  L26_2.TranslucencyLevel = 0
  L24_2 = L24_2(L25_2, L26_2)
  L23_2.nFadeOutPoint = L24_2
  L24_2 = L9_2
  L23_2 = L9_2.SetVisible
  L25_2 = false
  L23_2(L24_2, L25_2)
  L24_2 = L9_2
  L23_2 = L9_2.SetTranslucency
  L25_2 = 0
  L23_2(L24_2, L25_2)
  L23_2 = nil
  L24_2 = nil
  L25_2 = A0_2 - 1
  L25_2 = A1_2[L25_2]
  if L25_2 then
    L25_2 = A0_2 - 1
    L25_2 = A1_2[L25_2]
    L26_2 = L25_2
    L25_2 = L25_2.GetChildren
    L25_2 = L25_2(L26_2)
    L24_2 = L25_2[5]
  end
  L25_2 = A0_2 + 1
  L25_2 = A1_2[L25_2]
  if L25_2 then
    L25_2 = A0_2 + 1
    L25_2 = A1_2[L25_2]
    L26_2 = L25_2
    L25_2 = L25_2.GetChildren
    L25_2 = L25_2(L26_2)
    L23_2 = L25_2[5]
  end
  L25_2 = _SetUpScaledPoints
  L26_2 = L9_2
  L27_2 = L24_2
  L28_2 = L23_2
  L25_2(L26_2, L27_2, L28_2)
  L25_2 = _SetItemTexture
  L2_2.SetItemTexture = L25_2
  L25_2 = _TriggerItemNext
  L2_2.TriggerNext = L25_2
  L25_2 = _TriggerItemPrev
  L2_2.TriggerPrev = L25_2
  L25_2 = _TriggerSquish
  L2_2.TriggerSquish = L25_2
  L25_2 = _SetupItemOpen
  L2_2.SetupOpen = L25_2
  L25_2 = _TriggerItemOpenMain
  L2_2.TriggerOpen = L25_2
  L25_2 = _TriggerItemClose
  L2_2.TriggerClose = L25_2
  L25_2 = _MoveTo
  L2_2.MoveTo = L25_2
  L25_2 = _SetItemStatus
  L2_2.SetStatus = L25_2
  L26_2 = L2_2
  L25_2 = L2_2.SetStatus
  L27_2 = nil
  L25_2(L26_2, L27_2)
end

_SetupItemAnimationPoints = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oIcon
  L3_2 = L2_2
  L2_2 = L2_2.SetTexture
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

_SetItemTexture = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oStatus
  if not A1_2 then
    L3_2 = L2_2.CustomData
    L3_2.bInUse = false
    L4_2 = L2_2
    L3_2 = L2_2.SetTextureCoordinates
    L5_2 = 0.9921875
    L6_2 = 0
    L7_2 = 0.99609375
    L8_2 = 1
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
    return
  end
  if "fuel" == A1_2 then
    L3_2 = L2_2.CustomData
    L3_2.bInUse = true
    L4_2 = L2_2
    L3_2 = L2_2.SetTextureCoordinates
    L5_2 = 0
    L6_2 = 0
    L7_2 = 0.125
    L8_2 = 1
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  elseif "[PDA.Support.denied.basic]" == A1_2 then
    L3_2 = L2_2.CustomData
    L3_2.bInUse = true
    L4_2 = L2_2
    L3_2 = L2_2.SetTextureCoordinates
    L5_2 = 0.375
    L6_2 = 0
    L7_2 = 0.5
    L8_2 = 1
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  elseif "[PDA.Support.denied.medium]" == A1_2 then
    L3_2 = L2_2.CustomData
    L3_2.bInUse = true
    L4_2 = L2_2
    L3_2 = L2_2.SetTextureCoordinates
    L5_2 = 0.125
    L6_2 = 0
    L7_2 = 0.25
    L8_2 = 1
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  elseif "[PDA.Support.denied.jammer]" == A1_2 then
    L3_2 = L2_2.CustomData
    L3_2.bInUse = true
    L4_2 = L2_2
    L3_2 = L2_2.SetTextureCoordinates
    L5_2 = 0.25
    L6_2 = 0
    L7_2 = 0.375
    L8_2 = 1
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  elseif "[Generic.Attitudes.Hostile]" == A1_2 then
    L3_2 = L2_2.CustomData
    L3_2.bInUse = true
    L4_2 = L2_2
    L3_2 = L2_2.SetTextureCoordinates
    L5_2 = 0.625
    L6_2 = 0
    L7_2 = 0.75
    L8_2 = 1
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  elseif "zero" == A1_2 then
    L3_2 = L2_2.CustomData
    L3_2.bInUse = true
    L4_2 = L2_2
    L3_2 = L2_2.SetTextureCoordinates
    L5_2 = 0.5
    L6_2 = 0
    L7_2 = 0.625
    L8_2 = 1
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  elseif "disabled" == A1_2 then
    L3_2 = L2_2.CustomData
    L3_2.bInUse = true
    L4_2 = L2_2
    L3_2 = L2_2.SetTextureCoordinates
    L5_2 = 0.75
    L6_2 = 0
    L7_2 = 0.875
    L8_2 = 1
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  else
    L3_2 = L2_2.CustomData
    L3_2.bInUse = false
    L4_2 = L2_2
    L3_2 = L2_2.SetTextureCoordinates
    L5_2 = 0.9921875
    L6_2 = 0
    L7_2 = 0.99609375
    L8_2 = 1
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  end
end

_SetItemStatus = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = _StatusPulseToOpaque
  L2_2 = A0_2
  L1_2(L2_2)
end

_StartStatusPulse = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  if A1_2 then
    L3_2 = A0_2
    L2_2 = A0_2.AnimateToPoint
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.nFadeInPoint
    L5_2 = 0
    L6_2 = true
    L2_2(L3_2, L4_2, L5_2, L6_2)
  else
    L3_2 = A0_2
    L2_2 = A0_2.AnimateToPoint
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.nFadeOutPoint
    L5_2 = 0
    L6_2 = true
    L2_2(L3_2, L4_2, L5_2, L6_2)
  end
end

_HaltStatusPulse = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2
  L1_2 = A0_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nFadeOutPoint
  L4_2 = 0.75
  L5_2 = true
  L6_2 = _StatusPulseToOpaque
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

_StatusPulseToClear = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2
  L1_2 = A0_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nFadeInPoint
  L4_2 = 0.75
  L5_2 = true
  L6_2 = _StatusPulseToClear
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

_StatusPulseToOpaque = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L3_2 = A0_2.CustomData
  L5_2 = A0_2
  L4_2 = A0_2.GetLocation
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  L8_2 = L6_2 - L4_2
  L9_2 = L7_2 - L5_2
  L11_2 = A0_2
  L10_2 = A0_2.AddAnimationPoint
  L12_2 = {}
  L12_2.x = L4_2
  L12_2.y = L5_2
  L12_2.x2 = L6_2
  L12_2.y2 = L7_2
  L10_2 = L10_2(L11_2, L12_2)
  L3_2.nScalePoint = L10_2
  L10_2 = L6_2 - L4_2
  L3_2.nOriginalWidth = L10_2
  L10_2 = L7_2 - L5_2
  L3_2.nOriginalHeight = L10_2
  if A1_2 then
    L11_2 = A1_2
    L10_2 = A1_2.GetLocation
    L10_2, L11_2, L12_2, L13_2 = L10_2(L11_2)
    L14_2 = L12_2 - L10_2
    L15_2 = L13_2 - L11_2
    L16_2 = L14_2 + L8_2
    L16_2 = L16_2 / 2
    L3_2.nFlipPrevMidWidth = L16_2
    L3_2.nFlipPrevMidHeight = 0
    L3_2.nFlipPrevEndWidth = L14_2
    L3_2.nFlipPrevEndHeight = L15_2
  end
  if A2_2 then
    L11_2 = A2_2
    L10_2 = A2_2.GetLocation
    L10_2, L11_2, L12_2, L13_2 = L10_2(L11_2)
    L14_2 = L12_2 - L10_2
    L15_2 = L13_2 - L11_2
    L16_2 = L14_2 + L8_2
    L16_2 = L16_2 / 2
    L3_2.nFlipNextMidWidth = L16_2
    L3_2.nFlipNextMidHeight = 0
    L3_2.nFlipNextEndWidth = L14_2
    L3_2.nFlipNextEndHeight = L15_2
  end
  L10_2 = L8_2 * 0.375
  L3_2.nExitWidth = L10_2
  L3_2.nExitHeight = L9_2
  L10_2 = _ScaleTo
  A0_2.ScaleTo = L10_2
end

_SetUpFlipPoints = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L4_2 = A0_2
  L3_2 = A0_2.GetLocation
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  L7_2 = L5_2 + L3_2
  L7_2 = L7_2 / 2
  L8_2 = L6_2 + L4_2
  L8_2 = L8_2 / 2
  L9_2 = A0_2.CustomData
  tData = L9_2
  L9_2 = tData
  L11_2 = A0_2
  L10_2 = A0_2.AddAnimationPoint
  L12_2 = {}
  L12_2.x = L3_2
  L12_2.y = L4_2
  L12_2.x2 = L5_2
  L12_2.y2 = L6_2
  L10_2 = L10_2(L11_2, L12_2)
  L9_2.nScalePoint = L10_2
  L9_2 = tData
  L10_2 = L5_2 - L3_2
  L9_2.nOriginalWidth = L10_2
  L9_2 = tData
  L10_2 = L6_2 - L4_2
  L9_2.nOriginalHeight = L10_2
  if A2_2 then
    L10_2 = A2_2
    L9_2 = A2_2.GetLocation
    L9_2, L10_2, L11_2, L12_2 = L9_2(L10_2)
    L13_2 = tData
    L14_2 = L11_2 - L9_2
    L13_2.nNextWidth = L14_2
    L13_2 = tData
    L14_2 = L12_2 - L10_2
    L13_2.nNextHeight = L14_2
  end
  if A1_2 then
    L10_2 = A1_2
    L9_2 = A1_2.GetLocation
    L9_2, L10_2, L11_2, L12_2 = L9_2(L10_2)
    L13_2 = tData
    L14_2 = L11_2 - L9_2
    L13_2.nPrevWidth = L14_2
    L13_2 = tData
    L14_2 = L12_2 - L10_2
    L13_2.nPrevHeight = L14_2
  end
  L9_2 = _ScaleTo
  A0_2.ScaleTo = L9_2
end

_SetUpScaledPoints = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2)
  local L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2
  L8_2 = A0_2
  L7_2 = A0_2.GetLocation
  L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
  L11_2 = L7_2 + L9_2
  L11_2 = L11_2 / 2
  L12_2 = L8_2 + L10_2
  L12_2 = L12_2 / 2
  L13_2 = A0_2.CustomData
  L14_2 = L7_2
  L15_2 = L9_2
  if A1_2 then
    L16_2 = A1_2 / 2
    L14_2 = L11_2 - L16_2
    L16_2 = A1_2 / 2
    L15_2 = L11_2 + L16_2
  end
  L16_2 = L8_2
  L17_2 = L10_2
  if A2_2 then
    L18_2 = A2_2 / 2
    L16_2 = L12_2 - L18_2
    L18_2 = A2_2 / 2
    L17_2 = L12_2 + L18_2
  end
  if A3_2 and A3_2 <= 0 and A4_2 then
    L19_2 = A0_2
    L18_2 = A0_2.SetLocation
    L20_2 = L14_2
    L21_2 = L16_2
    L22_2 = L15_2
    L23_2 = L17_2
    L18_2(L19_2, L20_2, L21_2, L22_2, L23_2)
    L18_2 = type
    L19_2 = A5_2
    L18_2 = L18_2(L19_2)
    if "function" == L18_2 then
      L18_2 = A6_2
      L19_2 = type
      L20_2 = L18_2
      L19_2 = L19_2(L20_2)
      if "table" ~= L19_2 then
        L19_2 = {}
        L18_2 = L19_2
      end
      L19_2 = table
      L19_2 = L19_2.insert
      L20_2 = L18_2
      L21_2 = 1
      L22_2 = A0_2
      L19_2(L20_2, L21_2, L22_2)
      L19_2 = A5_2
      L20_2 = unpack
      L21_2 = L18_2
      L20_2, L21_2, L22_2, L23_2, L24_2 = L20_2(L21_2)
      L19_2(L20_2, L21_2, L22_2, L23_2, L24_2)
    end
  else
    L19_2 = A0_2
    L18_2 = A0_2.SetAnimationPoint
    L20_2 = L13_2.nScalePoint
    L21_2 = {}
    L21_2.x = L14_2
    L21_2.y = L16_2
    L21_2.x2 = L15_2
    L21_2.y2 = L17_2
    L18_2(L19_2, L20_2, L21_2)
    L19_2 = A0_2
    L18_2 = A0_2.AnimateToPoint
    L20_2 = L13_2.nScalePoint
    L21_2 = A3_2
    L22_2 = A4_2
    L23_2 = A5_2
    L24_2 = A6_2
    L18_2(L19_2, L20_2, L21_2, L22_2, L23_2, L24_2)
  end
end

_ScaleTo = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  if A2_2 and A2_2 <= 0 and A3_2 then
    L6_2 = A0_2.AnimationPoints
    L6_2 = L6_2[A1_2]
    if not L6_2 then
      return
    end
    L8_2 = A0_2
    L7_2 = A0_2.SetLocation
    L9_2 = L6_2.nX1
    L10_2 = L6_2.nY1
    L11_2 = L6_2.nX2
    L12_2 = L6_2.nY2
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
    L7_2 = type
    L8_2 = A4_2
    L7_2 = L7_2(L8_2)
    if "function" == L7_2 then
      L7_2 = A5_2
      L8_2 = type
      L9_2 = L7_2
      L8_2 = L8_2(L9_2)
      if "table" ~= L8_2 then
        L8_2 = {}
        L7_2 = L8_2
      end
      L8_2 = table
      L8_2 = L8_2.insert
      L9_2 = L7_2
      L10_2 = 1
      L11_2 = A0_2
      L8_2(L9_2, L10_2, L11_2)
      L8_2 = A4_2
      L9_2 = unpack
      L10_2 = L7_2
      L9_2, L10_2, L11_2, L12_2 = L9_2(L10_2)
      L8_2(L9_2, L10_2, L11_2, L12_2)
    end
  else
    L7_2 = A0_2
    L6_2 = A0_2.AnimateToPoint
    L8_2 = A1_2
    L9_2 = A2_2
    L10_2 = A3_2
    L11_2 = A4_2
    L12_2 = A5_2
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  end
end

_MoveTo = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2
  L2_2 = A0_2.CustomData
  L3_2 = L2_2.nPrevPoint
  if not L3_2 then
    return
  end
  L4_2 = A0_2
  L3_2 = A0_2.AnimateToPoint
  L5_2 = L2_2.nPrevPoint
  L6_2 = 0
  L7_2 = true
  L3_2(L4_2, L5_2, L6_2, L7_2)
  L4_2 = A0_2
  L3_2 = A0_2.AnimateToPoint
  L5_2 = L2_2.nOriginPoint
  L6_2 = A1_2
  L7_2 = false
  L3_2(L4_2, L5_2, L6_2, L7_2)
  L3_2 = L2_2.oIconBg
  L4_2 = L2_2.oIcon
  L5_2 = A1_2 / 2
  L7_2 = L4_2
  L6_2 = L4_2.ScaleTo
  L8_2 = L4_2.CustomData
  L8_2 = L8_2.nFlipPrevEndWidth
  L9_2 = L4_2.CustomData
  L9_2 = L9_2.nFlipPrevEndHeight
  L10_2 = 0
  L11_2 = true
  L12_2 = L4_2.ScaleTo
  L13_2 = {}
  L14_2 = L4_2.CustomData
  L14_2 = L14_2.nFlipPrevMidWidth
  L15_2 = L4_2.CustomData
  L15_2 = L15_2.nFlipPrevMidHeight
  L16_2 = L5_2
  L17_2 = true
  L18_2 = L4_2.ScaleTo
  L19_2 = {}
  L20_2 = L4_2.CustomData
  L20_2 = L20_2.nOriginalWidth
  L21_2 = L4_2.CustomData
  L21_2 = L21_2.nOriginalHeight
  L22_2 = L5_2
  L19_2[1] = L20_2
  L19_2[2] = L21_2
  L19_2[3] = L22_2
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L13_2[3] = L16_2
  L13_2[4] = L17_2
  L13_2[5] = L18_2
  L13_2[6] = L19_2
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L7_2 = L3_2
  L6_2 = L3_2.ScaleTo
  L8_2 = L3_2.CustomData
  L8_2 = L8_2.nFlipPrevEndWidth
  L9_2 = L3_2.CustomData
  L9_2 = L9_2.nFlipPrevEndHeight
  L10_2 = 0
  L11_2 = true
  L12_2 = L3_2.ScaleTo
  L13_2 = {}
  L14_2 = L3_2.CustomData
  L14_2 = L14_2.nFlipPrevMidWidth
  L15_2 = L3_2.CustomData
  L15_2 = L15_2.nFlipPrevMidHeight
  L16_2 = L5_2
  L17_2 = true
  L18_2 = L3_2.ScaleTo
  L19_2 = {}
  L20_2 = L3_2.CustomData
  L20_2 = L20_2.nOriginalWidth
  L21_2 = L3_2.CustomData
  L21_2 = L21_2.nOriginalHeight
  L22_2 = L5_2
  L19_2[1] = L20_2
  L19_2[2] = L21_2
  L19_2[3] = L22_2
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L13_2[3] = L16_2
  L13_2[4] = L17_2
  L13_2[5] = L18_2
  L13_2[6] = L19_2
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L6_2 = L2_2.oBorder
  L8_2 = L6_2
  L7_2 = L6_2.ScaleTo
  L9_2 = L6_2.CustomData
  L9_2 = L9_2.nPrevWidth
  L10_2 = L6_2.CustomData
  L10_2 = L10_2.nPrevHeight
  L11_2 = 0
  L12_2 = true
  L13_2 = L6_2.ScaleTo
  L14_2 = {}
  L15_2 = L6_2.CustomData
  L15_2 = L15_2.nOriginalWidth
  L16_2 = L6_2.CustomData
  L16_2 = L16_2.nOriginalHeight
  L17_2 = A1_2
  L18_2 = true
  L14_2[1] = L15_2
  L14_2[2] = L16_2
  L14_2[3] = L17_2
  L14_2[4] = L18_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L7_2 = L2_2.oOrbit
  L9_2 = L7_2
  L8_2 = L7_2.ScaleTo
  L10_2 = L7_2.CustomData
  L10_2 = L10_2.nPrevWidth
  L11_2 = L7_2.CustomData
  L11_2 = L11_2.nPrevHeight
  L12_2 = 0
  L13_2 = true
  L14_2 = L7_2.ScaleTo
  L15_2 = {}
  L16_2 = L7_2.CustomData
  L16_2 = L16_2.nOriginalWidth
  L17_2 = L7_2.CustomData
  L17_2 = L17_2.nOriginalHeight
  L18_2 = A1_2
  L19_2 = true
  L15_2[1] = L16_2
  L15_2[2] = L17_2
  L15_2[3] = L18_2
  L15_2[4] = L19_2
  L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  L8_2 = L2_2.oStatus
  L10_2 = L8_2
  L9_2 = L8_2.ScaleTo
  L11_2 = L8_2.CustomData
  L11_2 = L11_2.nPrevWidth
  L12_2 = L8_2.CustomData
  L12_2 = L12_2.nPrevHeight
  L13_2 = 0
  L14_2 = true
  L15_2 = L8_2.ScaleTo
  L16_2 = {}
  L17_2 = L8_2.CustomData
  L17_2 = L17_2.nOriginalWidth
  L18_2 = L8_2.CustomData
  L18_2 = L18_2.nOriginalHeight
  L19_2 = A1_2
  L20_2 = true
  L16_2[1] = L17_2
  L16_2[2] = L18_2
  L16_2[3] = L19_2
  L16_2[4] = L20_2
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
end

_TriggerItemNext = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2
  L2_2 = A0_2.CustomData
  L3_2 = L2_2.nNextPoint
  if not L3_2 then
    return
  end
  L4_2 = A0_2
  L3_2 = A0_2.AnimateToPoint
  L5_2 = L2_2.nNextPoint
  L6_2 = 0
  L7_2 = true
  L3_2(L4_2, L5_2, L6_2, L7_2)
  L4_2 = A0_2
  L3_2 = A0_2.AnimateToPoint
  L5_2 = L2_2.nOriginPoint
  L6_2 = A1_2
  L7_2 = false
  L3_2(L4_2, L5_2, L6_2, L7_2)
  L3_2 = L2_2.oIconBg
  L4_2 = L2_2.oIcon
  L5_2 = A1_2 / 2
  L7_2 = L4_2
  L6_2 = L4_2.ScaleTo
  L8_2 = L4_2.CustomData
  L8_2 = L8_2.nFlipNextEndWidth
  L9_2 = L4_2.CustomData
  L9_2 = L9_2.nFlipNextEndHeight
  L10_2 = 0
  L11_2 = true
  L12_2 = L4_2.ScaleTo
  L13_2 = {}
  L14_2 = L4_2.CustomData
  L14_2 = L14_2.nFlipNextMidWidth
  L15_2 = L4_2.CustomData
  L15_2 = L15_2.nFlipNextMidHeight
  L16_2 = L5_2
  L17_2 = true
  L18_2 = L4_2.ScaleTo
  L19_2 = {}
  L20_2 = L4_2.CustomData
  L20_2 = L20_2.nOriginalWidth
  L21_2 = L4_2.CustomData
  L21_2 = L21_2.nOriginalHeight
  L22_2 = L5_2
  L19_2[1] = L20_2
  L19_2[2] = L21_2
  L19_2[3] = L22_2
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L13_2[3] = L16_2
  L13_2[4] = L17_2
  L13_2[5] = L18_2
  L13_2[6] = L19_2
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L7_2 = L3_2
  L6_2 = L3_2.ScaleTo
  L8_2 = L3_2.CustomData
  L8_2 = L8_2.nFlipNextEndWidth
  L9_2 = L3_2.CustomData
  L9_2 = L9_2.nFlipNextEndHeight
  L10_2 = 0
  L11_2 = true
  L12_2 = L3_2.ScaleTo
  L13_2 = {}
  L14_2 = L3_2.CustomData
  L14_2 = L14_2.nFlipNextMidWidth
  L15_2 = L3_2.CustomData
  L15_2 = L15_2.nFlipNextMidHeight
  L16_2 = L5_2
  L17_2 = true
  L18_2 = L3_2.ScaleTo
  L19_2 = {}
  L20_2 = L3_2.CustomData
  L20_2 = L20_2.nOriginalWidth
  L21_2 = L3_2.CustomData
  L21_2 = L21_2.nOriginalHeight
  L22_2 = L5_2
  L19_2[1] = L20_2
  L19_2[2] = L21_2
  L19_2[3] = L22_2
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L13_2[3] = L16_2
  L13_2[4] = L17_2
  L13_2[5] = L18_2
  L13_2[6] = L19_2
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L6_2 = L2_2.oBorder
  L8_2 = L6_2
  L7_2 = L6_2.ScaleTo
  L9_2 = L6_2.CustomData
  L9_2 = L9_2.nNextWidth
  L10_2 = L6_2.CustomData
  L10_2 = L10_2.nNextHeight
  L11_2 = 0
  L12_2 = true
  L13_2 = L6_2.ScaleTo
  L14_2 = {}
  L15_2 = L6_2.CustomData
  L15_2 = L15_2.nOriginalWidth
  L16_2 = L6_2.CustomData
  L16_2 = L16_2.nOriginalHeight
  L17_2 = A1_2
  L18_2 = true
  L14_2[1] = L15_2
  L14_2[2] = L16_2
  L14_2[3] = L17_2
  L14_2[4] = L18_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L7_2 = L2_2.oOrbit
  L9_2 = L7_2
  L8_2 = L7_2.ScaleTo
  L10_2 = L7_2.CustomData
  L10_2 = L10_2.nNextWidth
  L11_2 = L7_2.CustomData
  L11_2 = L11_2.nNextHeight
  L12_2 = 0
  L13_2 = true
  L14_2 = L7_2.ScaleTo
  L15_2 = {}
  L16_2 = L7_2.CustomData
  L16_2 = L16_2.nOriginalWidth
  L17_2 = L7_2.CustomData
  L17_2 = L17_2.nOriginalHeight
  L18_2 = A1_2
  L19_2 = true
  L15_2[1] = L16_2
  L15_2[2] = L17_2
  L15_2[3] = L18_2
  L15_2[4] = L19_2
  L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  L8_2 = L2_2.oStatus
  L10_2 = L8_2
  L9_2 = L8_2.ScaleTo
  L11_2 = L8_2.CustomData
  L11_2 = L11_2.nNextWidth
  L12_2 = L8_2.CustomData
  L12_2 = L12_2.nNextHeight
  L13_2 = 0
  L14_2 = true
  L15_2 = L8_2.ScaleTo
  L16_2 = {}
  L17_2 = L8_2.CustomData
  L17_2 = L17_2.nOriginalWidth
  L18_2 = L8_2.CustomData
  L18_2 = L18_2.nOriginalHeight
  L19_2 = A1_2
  L20_2 = true
  L16_2[1] = L17_2
  L16_2[2] = L18_2
  L16_2[3] = L19_2
  L16_2[4] = L20_2
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
end

_TriggerItemPrev = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = A0_2.CustomData
  L3_2 = A0_2
  L2_2 = A0_2.MoveTo
  L4_2 = L1_2.nPrevPoint
  L5_2 = 0
  L6_2 = true
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oIconBg
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oIcon
  L5_2 = L3_2
  L4_2 = L3_2.ScaleTo
  L6_2 = L3_2.CustomData
  L6_2 = L6_2.nFlipPrevEndWidth
  L7_2 = L3_2.CustomData
  L7_2 = L7_2.nFlipPrevEndHeight
  L8_2 = 0
  L9_2 = true
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  L5_2 = L2_2
  L4_2 = L2_2.ScaleTo
  L6_2 = L2_2.CustomData
  L6_2 = L6_2.nFlipPrevEndWidth
  L7_2 = L2_2.CustomData
  L7_2 = L7_2.nFlipPrevEndHeight
  L8_2 = 0
  L9_2 = true
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  L4_2 = L1_2.oBorder
  L6_2 = L4_2
  L5_2 = L4_2.ScaleTo
  L7_2 = L4_2.CustomData
  L7_2 = L7_2.nPrevWidth
  L8_2 = L4_2.CustomData
  L8_2 = L8_2.nPrevHeight
  L9_2 = 0
  L10_2 = true
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L5_2 = L1_2.oOrbit
  L7_2 = L5_2
  L6_2 = L5_2.ScaleTo
  L8_2 = L5_2.CustomData
  L8_2 = L8_2.nPrevWidth
  L9_2 = L5_2.CustomData
  L9_2 = L9_2.nPrevHeight
  L10_2 = 0
  L11_2 = true
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  L6_2 = L1_2.oStatus
  L8_2 = L6_2
  L7_2 = L6_2.ScaleTo
  L9_2 = L6_2.CustomData
  L9_2 = L9_2.nPrevWidth
  L10_2 = L6_2.CustomData
  L10_2 = L10_2.nPrevHeight
  L11_2 = 0
  L12_2 = true
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
end

_SetupItemNext = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = A0_2.CustomData
  L3_2 = A0_2
  L2_2 = A0_2.MoveTo
  L4_2 = L1_2.nNextPoint
  L5_2 = 0
  L6_2 = true
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L2_2 = L1_2.oIconBg
  L3_2 = L1_2.oIcon
  L5_2 = L3_2
  L4_2 = L3_2.ScaleTo
  L6_2 = L3_2.CustomData
  L6_2 = L6_2.nFlipNextEndWidth
  L7_2 = L3_2.CustomData
  L7_2 = L7_2.nFlipNextEndHeight
  L8_2 = 0
  L9_2 = true
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  L5_2 = L2_2
  L4_2 = L2_2.ScaleTo
  L6_2 = L2_2.CustomData
  L6_2 = L6_2.nFlipNextEndWidth
  L7_2 = L2_2.CustomData
  L7_2 = L7_2.nFlipNextEndHeight
  L8_2 = 0
  L9_2 = true
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  L4_2 = L1_2.oBorder
  L6_2 = L4_2
  L5_2 = L4_2.ScaleTo
  L7_2 = L4_2.CustomData
  L7_2 = L7_2.nNextWidth
  L8_2 = L4_2.CustomData
  L8_2 = L8_2.nNextHeight
  L9_2 = 0
  L10_2 = true
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L5_2 = L1_2.oOrbit
  L7_2 = L5_2
  L6_2 = L5_2.ScaleTo
  L8_2 = L5_2.CustomData
  L8_2 = L8_2.nNextWidth
  L9_2 = L5_2.CustomData
  L9_2 = L9_2.nNextHeight
  L10_2 = 0
  L11_2 = true
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  L6_2 = L1_2.oStatus
  L8_2 = L6_2
  L7_2 = L6_2.ScaleTo
  L9_2 = L6_2.CustomData
  L9_2 = L9_2.nNextWidth
  L10_2 = L6_2.CustomData
  L10_2 = L10_2.nNextHeight
  L11_2 = 0
  L12_2 = true
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
end

_SetupItemPrev = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oIcon
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.oIconBg
  if A2_2 then
    L7_2 = L4_2
    L6_2 = L4_2.ScaleTo
    L8_2 = L4_2.CustomData
    L8_2 = L8_2.nExitWidth
    L9_2 = nil
    L10_2 = 0
    L11_2 = true
    L12_2 = L4_2.ScaleTo
    L13_2 = {}
    L14_2 = L4_2.CustomData
    L14_2 = L14_2.nOriginalWidth
    L15_2 = nil
    L16_2 = A1_2
    L17_2 = true
    L13_2[1] = L14_2
    L13_2[2] = L15_2
    L13_2[3] = L16_2
    L13_2[4] = L17_2
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
    L7_2 = L5_2
    L6_2 = L5_2.ScaleTo
    L8_2 = L5_2.CustomData
    L8_2 = L8_2.nExitWidth
    L9_2 = nil
    L10_2 = 0
    L11_2 = true
    L12_2 = L5_2.ScaleTo
    L13_2 = {}
    L14_2 = L5_2.CustomData
    L14_2 = L14_2.nOriginalWidth
    L15_2 = nil
    L16_2 = A1_2
    L17_2 = true
    L13_2[1] = L14_2
    L13_2[2] = L15_2
    L13_2[3] = L16_2
    L13_2[4] = L17_2
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
    L7_2 = A0_2
    L6_2 = A0_2.AnimateToPoint
    L8_2 = A0_2.CustomData
    L8_2 = L8_2.nOriginPoint
    L9_2 = A1_2
    L10_2 = true
    L6_2(L7_2, L8_2, L9_2, L10_2)
    L7_2 = A0_2
    L6_2 = A0_2.SetVisible
    L8_2 = true
    L6_2(L7_2, L8_2)
  else
    if A3_2 then
      L7_2 = A0_2
      L6_2 = A0_2.AnimateToPoint
      L8_2 = A0_2.CustomData
      L8_2 = L8_2.nSquishTop
      L9_2 = A1_2
      L10_2 = true
      L6_2(L7_2, L8_2, L9_2, L10_2)
    else
      L7_2 = A0_2
      L6_2 = A0_2.AnimateToPoint
      L8_2 = A0_2.CustomData
      L8_2 = L8_2.nSquishBottom
      L9_2 = A1_2
      L10_2 = true
      L6_2(L7_2, L8_2, L9_2, L10_2)
    end
    L7_2 = L4_2
    L6_2 = L4_2.ScaleTo
    L8_2 = L4_2.CustomData
    L8_2 = L8_2.nOriginalWidth
    L9_2 = nil
    L10_2 = 0
    L11_2 = true
    L12_2 = L4_2.ScaleTo
    L13_2 = {}
    L14_2 = L4_2.CustomData
    L14_2 = L14_2.nExitWidth
    L15_2 = nil
    L16_2 = A1_2
    L17_2 = true
    L13_2[1] = L14_2
    L13_2[2] = L15_2
    L13_2[3] = L16_2
    L13_2[4] = L17_2
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
    L7_2 = L5_2
    L6_2 = L5_2.ScaleTo
    L8_2 = L5_2.CustomData
    L8_2 = L8_2.nOriginalWidth
    L9_2 = nil
    L10_2 = 0
    L11_2 = true
    L12_2 = L5_2.ScaleTo
    L13_2 = {}
    L14_2 = L5_2.CustomData
    L14_2 = L14_2.nExitWidth
    L15_2 = nil
    L16_2 = A1_2
    L17_2 = true
    L13_2[1] = L14_2
    L13_2[2] = L15_2
    L13_2[3] = L16_2
    L13_2[4] = L17_2
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  end
end

_TriggerSquish = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oIcon
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oIconBg
  if A1_2 then
    L6_2 = A0_2
    L5_2 = A0_2.SetVisible
    L7_2 = false
    L5_2(L6_2, L7_2)
    if A2_2 then
      L6_2 = A0_2
      L5_2 = A0_2.AnimateToPoint
      L7_2 = A0_2.CustomData
      L7_2 = L7_2.nSquishTop
      L8_2 = 0
      L9_2 = true
      L5_2(L6_2, L7_2, L8_2, L9_2)
    else
      L6_2 = A0_2
      L5_2 = A0_2.AnimateToPoint
      L7_2 = A0_2.CustomData
      L7_2 = L7_2.nSquishBottom
      L8_2 = 0
      L9_2 = true
      L5_2(L6_2, L7_2, L8_2, L9_2)
    end
    L6_2 = L3_2
    L5_2 = L3_2.ScaleTo
    L7_2 = L3_2.CustomData
    L7_2 = L7_2.nExitWidth
    L8_2 = nil
    L9_2 = 0
    L10_2 = true
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
    L6_2 = L4_2
    L5_2 = L4_2.ScaleTo
    L7_2 = L4_2.CustomData
    L7_2 = L7_2.nExitWidth
    L8_2 = nil
    L9_2 = 0
    L10_2 = true
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  else
    L6_2 = A0_2
    L5_2 = A0_2.AnimateToPoint
    L7_2 = A0_2.CustomData
    L7_2 = L7_2.nOriginPoint
    L8_2 = 0
    L9_2 = true
    L5_2(L6_2, L7_2, L8_2, L9_2)
    L6_2 = L3_2
    L5_2 = L3_2.ScaleTo
    L7_2 = L3_2.CustomData
    L7_2 = L7_2.nOriginalWidth
    L8_2 = nil
    L9_2 = 0
    L10_2 = true
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
    L6_2 = L4_2
    L5_2 = L4_2.ScaleTo
    L7_2 = L4_2.CustomData
    L7_2 = L7_2.nOriginalWidth
    L8_2 = nil
    L9_2 = 0
    L10_2 = true
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  end
end

_SetupSquish = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oIcon
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oIconBg
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oBorder
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oOrbit
  L6_2 = A0_2
  L5_2 = A0_2.MoveTo
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.nExitPoint
  L8_2 = 0
  L9_2 = true
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = L1_2
  L5_2 = L1_2.ScaleTo
  L7_2 = 0
  L8_2 = nil
  L9_2 = 0
  L10_2 = true
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L6_2 = L1_2
  L5_2 = L1_2.SetVisible
  L7_2 = false
  L5_2(L6_2, L7_2)
  L6_2 = L2_2
  L5_2 = L2_2.ScaleTo
  L7_2 = 0
  L8_2 = nil
  L9_2 = 0
  L10_2 = true
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L6_2 = L2_2
  L5_2 = L2_2.SetVisible
  L7_2 = false
  L5_2(L6_2, L7_2)
  L6_2 = L3_2
  L5_2 = L3_2.SetTranslucency
  L7_2 = 0
  L5_2(L6_2, L7_2)
  L6_2 = L3_2
  L5_2 = L3_2.AnimateToPoint
  L7_2 = L3_2.CustomData
  L7_2 = L7_2.nFadeOutPoint
  L8_2 = 0
  L9_2 = true
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = L4_2
  L5_2 = L4_2.SetTranslucency
  L7_2 = 0
  L5_2(L6_2, L7_2)
  L6_2 = L4_2
  L5_2 = L4_2.AnimateToPoint
  L7_2 = L4_2.CustomData
  L7_2 = L7_2.nFadeOutPoint
  L8_2 = 0
  L9_2 = true
  L5_2(L6_2, L7_2, L8_2, L9_2)
end

_SetupItemOpen = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oIcon
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oIconBg
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oBorder
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.oStatus
  L7_2 = A0_2
  L6_2 = A0_2.AnimateToPoint
  L8_2 = A0_2.CustomData
  L8_2 = L8_2.nEnterPoint
  L9_2 = A1_2
  L10_2 = false
  L6_2(L7_2, L8_2, L9_2, L10_2)
  L7_2 = L4_2
  L6_2 = L4_2.AnimateToPoint
  L8_2 = L4_2.CustomData
  L8_2 = L8_2.nFadeInPoint
  L9_2 = A1_2
  L10_2 = false
  L6_2(L7_2, L8_2, L9_2, L10_2)
  L7_2 = L2_2
  L6_2 = L2_2.ScaleTo
  L8_2 = 0
  L9_2 = nil
  L10_2 = 0
  L11_2 = true
  L12_2 = L2_2.ScaleTo
  L13_2 = {}
  L14_2 = L2_2.CustomData
  L14_2 = L14_2.nOriginalWidth
  L15_2 = nil
  L16_2 = A1_2
  L17_2 = true
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L13_2[3] = L16_2
  L13_2[4] = L17_2
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L7_2 = L2_2
  L6_2 = L2_2.SetVisible
  L8_2 = true
  L6_2(L7_2, L8_2)
  L7_2 = L3_2
  L6_2 = L3_2.ScaleTo
  L8_2 = 0
  L9_2 = nil
  L10_2 = 0
  L11_2 = true
  L12_2 = L3_2.ScaleTo
  L13_2 = {}
  L14_2 = L3_2.CustomData
  L14_2 = L14_2.nOriginalWidth
  L15_2 = nil
  L16_2 = A1_2
  L17_2 = true
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L13_2[3] = L16_2
  L13_2[4] = L17_2
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L7_2 = L3_2
  L6_2 = L3_2.SetVisible
  L8_2 = true
  L6_2(L7_2, L8_2)
  L6_2 = L5_2.CustomData
  L6_2 = L6_2.bInUse
  if L6_2 then
    L7_2 = L5_2
    L6_2 = L5_2.SetVisible
    L8_2 = true
    L6_2(L7_2, L8_2)
    L7_2 = L5_2
    L6_2 = L5_2.SetTranslucency
    L8_2 = 0
    L6_2(L7_2, L8_2)
    L7_2 = L5_2
    L6_2 = L5_2.AnimateToPoint
    L8_2 = L5_2.CustomData
    L8_2 = L8_2.nFadeInPoint
    L9_2 = A1_2
    L10_2 = true
    L6_2(L7_2, L8_2, L9_2, L10_2)
  end
end

_TriggerItemOpenMain = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oIcon
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oIconBg
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oBorder
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.oOrbit
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.oStatus
  L8_2 = A0_2
  L7_2 = A0_2.AnimateToPoint
  L9_2 = A0_2.CustomData
  L9_2 = L9_2.nExitPoint
  L10_2 = A1_2
  L11_2 = false
  L7_2(L8_2, L9_2, L10_2, L11_2)
  L8_2 = L4_2
  L7_2 = L4_2.AnimateToPoint
  L9_2 = L4_2.CustomData
  L9_2 = L9_2.nFadeOutPoint
  L10_2 = A1_2
  L11_2 = false
  L7_2(L8_2, L9_2, L10_2, L11_2)
  L8_2 = L5_2
  L7_2 = L5_2.AnimateToPoint
  L9_2 = L5_2.CustomData
  L9_2 = L9_2.nFadeOutPoint
  L10_2 = A1_2
  L11_2 = false
  L7_2(L8_2, L9_2, L10_2, L11_2)
  L8_2 = L2_2
  L7_2 = L2_2.ScaleTo
  L9_2 = L2_2.CustomData
  L9_2 = L9_2.nOriginalWidth
  L10_2 = nil
  L11_2 = 0
  L12_2 = true
  L13_2 = L2_2.ScaleTo
  L14_2 = {}
  L15_2 = 0
  L16_2 = nil
  L17_2 = A1_2
  L18_2 = true
  L14_2[1] = L15_2
  L14_2[2] = L16_2
  L14_2[3] = L17_2
  L14_2[4] = L18_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L8_2 = L3_2
  L7_2 = L3_2.ScaleTo
  L9_2 = L3_2.CustomData
  L9_2 = L9_2.nOriginalWidth
  L10_2 = nil
  L11_2 = 0
  L12_2 = true
  L13_2 = L3_2.ScaleTo
  L14_2 = {}
  L15_2 = 0
  L16_2 = nil
  L17_2 = A1_2
  L18_2 = true
  L14_2[1] = L15_2
  L14_2[2] = L16_2
  L14_2[3] = L17_2
  L14_2[4] = L18_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L8_2 = L6_2
  L7_2 = L6_2.SetTranslucency
  L9_2 = 255
  L7_2(L8_2, L9_2)
  L8_2 = L6_2
  L7_2 = L6_2.AnimateToPoint
  L9_2 = L6_2.CustomData
  L9_2 = L9_2.nFadeOutPoint
  L10_2 = A1_2
  L11_2 = true
  L12_2 = L6_2.SetVisible
  L13_2 = {}
  L14_2 = false
  L13_2[1] = L14_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
end

_TriggerItemClose = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
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
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L2_2 = 1
  while true do
    L3_2 = L1_2[L2_2]
    if not L3_2 then
      break
    end
    L3_2 = L1_2[L2_2]
    L3_2 = L3_2.CustomData
    L4_2 = L1_2[L2_2]
    L5_2 = L4_2
    L4_2 = L4_2.AddAnimationPoint
    L6_2 = {}
    L4_2 = L4_2(L5_2, L6_2)
    L3_2.nTargetPoint = L4_2
    L3_2 = L1_2[L2_2]
    L3_2 = L3_2.CustomData
    L4_2 = L1_2[L2_2]
    L5_2 = L4_2
    L4_2 = L4_2.GetRotation
    L4_2 = L4_2(L5_2)
    L3_2.nOriginalRotation = L4_2
    L2_2 = L2_2 + 1
  end
  L3_2 = _AnimateBullet
  A0_2.AnimateBullet = L3_2
end

_InitializeBullets = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2)
  local L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L8_2 = A0_2
  L7_2 = A0_2.GetChildren
  L7_2 = L7_2(L8_2)
  L7_2 = L7_2[A1_2]
  if not L7_2 then
    return
  end
  L8_2 = L7_2.CustomData
  L8_2 = L8_2.nOriginalRotation
  L10_2 = L7_2
  L9_2 = L7_2.SetRotation
  L11_2 = L8_2 + A3_2
  L9_2(L10_2, L11_2)
  L10_2 = L7_2
  L9_2 = L7_2.SetAnimationPoint
  L11_2 = L7_2.CustomData
  L11_2 = L11_2.nTargetPoint
  L12_2 = {}
  L13_2 = L8_2 + A4_2
  L12_2.nRotation = L13_2
  L12_2.nRotationDirection = A5_2
  L9_2(L10_2, L11_2, L12_2)
  L10_2 = L7_2
  L9_2 = L7_2.AnimateToPoint
  L11_2 = L7_2.CustomData
  L11_2 = L11_2.nTargetPoint
  L12_2 = A2_2
  L13_2 = true
  L14_2 = _ResetBullet
  L15_2 = {}
  L16_2 = A6_2
  L15_2[1] = L16_2
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
end

_AnimateBullet = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L3_2 = A0_2
  L2_2 = A0_2.SetRotation
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nOriginalRotation
  L2_2(L3_2, L4_2)
  if A1_2 then
    L3_2 = A0_2
    L2_2 = A0_2.SetVisible
    L4_2 = false
    L2_2(L3_2, L4_2)
  end
end

_ResetBullet = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2
  L1_2 = MrxGuiBase
  L1_2 = L1_2.ImageWidget
  L2_2 = L1_2
  L1_2 = L1_2.new
  L1_2 = L1_2(L2_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetVisible
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = L1_2.BasicData
  L2_2.bContainer = true
  L3_2 = L1_2
  L2_2 = L1_2.SetLocation
  L5_2 = A0_2
  L4_2 = A0_2.GetLocation
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2 = L4_2(L5_2)
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetOwner
  L5_2 = A0_2
  L4_2 = A0_2.GetOwner
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2 = L4_2(L5_2)
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2)
  L2_2 = _CopyImageParameters
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oIconBg
  L2_2 = L2_2(L3_2)
  L3_2 = _CopyImageParameters
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oIcon
  L3_2 = L3_2(L4_2)
  L4_2 = _CopyImageParameters
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.oBorder
  L4_2 = L4_2(L5_2)
  L5_2 = _CopyImageParameters
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.oBorder
  L5_2 = L5_2(L6_2)
  L6_2 = _CopyImageParameters
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.oOrbit
  L6_2 = L6_2(L7_2)
  L8_2 = L5_2
  L7_2 = L5_2.GetTextureCoordinates
  L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
  L11_2 = 0.80859375
  L12_2 = 0.24804688
  L14_2 = L5_2
  L13_2 = L5_2.SetTextureCoordinates
  L15_2 = L7_2 + L11_2
  L16_2 = L8_2 + L12_2
  L17_2 = L9_2 + L11_2
  L18_2 = L10_2 + L12_2
  L13_2(L14_2, L15_2, L16_2, L17_2, L18_2)
  L14_2 = L1_2
  L13_2 = L1_2.AddChild
  L15_2 = L2_2
  L13_2(L14_2, L15_2)
  L14_2 = L1_2
  L13_2 = L1_2.AddChild
  L15_2 = L3_2
  L13_2(L14_2, L15_2)
  L14_2 = L1_2
  L13_2 = L1_2.AddChild
  L15_2 = L4_2
  L13_2(L14_2, L15_2)
  L14_2 = L1_2
  L13_2 = L1_2.AddChild
  L15_2 = L5_2
  L13_2(L14_2, L15_2)
  L14_2 = L1_2
  L13_2 = L1_2.AddChild
  L15_2 = L6_2
  L13_2(L14_2, L15_2)
  L2_2.ParentWidget = L1_2
  L3_2.ParentWidget = L1_2
  L4_2.ParentWidget = L1_2
  L5_2.ParentWidget = L1_2
  L6_2.ParentWidget = L1_2
  L13_2 = L1_2.CustomData
  L13_2.oIconBg = L2_2
  L13_2 = L1_2.CustomData
  L13_2.oIcon = L3_2
  L13_2 = L1_2.CustomData
  L13_2.oBorder = L4_2
  L13_2 = L1_2.CustomData
  L13_2.oHighlight = L5_2
  L13_2 = L1_2.CustomData
  L13_2.oOrbit = L6_2
  L13_2 = _ScaleTo
  L2_2.ScaleTo = L13_2
  L13_2 = L2_2.CustomData
  L15_2 = L2_2
  L14_2 = L2_2.AddAnimationPoint
  L16_2 = {}
  L14_2 = L14_2(L15_2, L16_2)
  L13_2.nScalePoint = L14_2
  L14_2 = L2_2
  L13_2 = L2_2.GetLocation
  L13_2, L14_2, L15_2, L16_2 = L13_2(L14_2)
  L17_2 = L2_2.CustomData
  L18_2 = L16_2 - L14_2
  L17_2.nOriginalHeight = L18_2
  L17_2 = _ScaleTo
  L3_2.ScaleTo = L17_2
  L17_2 = L3_2.CustomData
  L19_2 = L3_2
  L18_2 = L3_2.AddAnimationPoint
  L20_2 = {}
  L18_2 = L18_2(L19_2, L20_2)
  L17_2.nScalePoint = L18_2
  L18_2 = L3_2
  L17_2 = L3_2.GetLocation
  L17_2, L18_2, L19_2, L20_2 = L17_2(L18_2)
  L21_2 = L3_2.CustomData
  L22_2 = L20_2 - L18_2
  L21_2.nOriginalHeight = L22_2
  L21_2 = L5_2.CustomData
  L23_2 = L5_2
  L22_2 = L5_2.AddAnimationPoint
  L24_2 = {}
  L24_2.TranslucencyLevel = 0
  L22_2 = L22_2(L23_2, L24_2)
  L21_2.oFadePoint = L22_2
  L21_2 = L6_2.CustomData
  L23_2 = L6_2
  L22_2 = L6_2.AddAnimationPoint
  L24_2 = {}
  L22_2 = L22_2(L23_2, L24_2)
  L21_2.oNullPoint = L22_2
  L21_2 = L6_2.CustomData
  L23_2 = L6_2
  L22_2 = L6_2.AddAnimationPoint
  L24_2 = {}
  L24_2.nRotation = 1
  L24_2.nRotationDirection = -1
  L24_2.TranslucencyLevel = 0
  L22_2 = L22_2(L23_2, L24_2)
  L21_2.oFadePoint = L22_2
  L21_2 = MrxGuiBase
  L21_2 = L21_2.GetWidgetByNameAndOwner
  L22_2 = "Ammo Counter Weapon Icon"
  L24_2 = A0_2
  L23_2 = A0_2.GetOwner
  L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2 = L23_2(L24_2)
  L21_2 = L21_2(L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2)
  if L21_2 then
    L23_2 = L21_2
    L22_2 = L21_2.GetLocation
    L22_2, L23_2 = L22_2(L23_2)
    L25_2 = L1_2
    L24_2 = L1_2.GetLocation
    L24_2, L25_2 = L24_2(L25_2)
    L27_2 = L3_2
    L26_2 = L3_2.GetLocation
    L26_2, L27_2 = L26_2(L27_2)
    L28_2 = L24_2 - L26_2
    L29_2 = L25_2 - L27_2
    L30_2 = L1_2.CustomData
    L32_2 = L1_2
    L31_2 = L1_2.AddAnimationPoint
    L33_2 = {}
    L34_2 = L22_2 + L28_2
    L33_2.x = L34_2
    L34_2 = L23_2 + L29_2
    L33_2.y = L34_2
    L31_2 = L31_2(L32_2, L33_2)
    L30_2.nTargetPoint = L31_2
  else
    L22_2 = L1_2.CustomData
    L24_2 = L1_2
    L23_2 = L1_2.AddAnimationPoint
    L25_2 = {}
    L25_2.TranslucencyLevel = 0
    L23_2 = L23_2(L24_2, L25_2)
    L22_2.nTargetPoint = L23_2
  end
  L22_2 = L1_2.CustomData
  L24_2 = L1_2
  L23_2 = L1_2.AddAnimationPoint
  L25_2 = {}
  L23_2 = L23_2(L24_2, L25_2)
  L22_2.nNullPoint = L23_2
  L22_2 = MrxGuiBase
  L22_2 = L22_2.AddWidgetWithChildren
  L23_2 = L1_2
  L22_2(L23_2)
  L23_2 = L5_2
  L22_2 = L5_2.AnimateToPoint
  L24_2 = L5_2.CustomData
  L24_2 = L24_2.oFadePoint
  L25_2 = _knFrame
  L25_2 = L25_2 * 10
  L26_2 = true
  L27_2 = L5_2.SetVisible
  L28_2 = {}
  L29_2 = false
  L28_2[1] = L29_2
  L22_2(L23_2, L24_2, L25_2, L26_2, L27_2, L28_2)
  L23_2 = L6_2
  L22_2 = L6_2.AnimateToPoint
  L24_2 = L6_2.CustomData
  L24_2 = L24_2.oNullPoint
  L25_2 = _knFrame
  L25_2 = L25_2 * 5
  L26_2 = true
  L22_2(L23_2, L24_2, L25_2, L26_2)
  L23_2 = L6_2
  L22_2 = L6_2.AnimateToPoint
  L24_2 = L6_2.CustomData
  L24_2 = L24_2.oFadePoint
  L25_2 = _knFrame
  L25_2 = L25_2 * 20
  L26_2 = false
  L27_2 = L6_2.SetVisible
  L28_2 = {}
  L29_2 = false
  L28_2[1] = L29_2
  L22_2(L23_2, L24_2, L25_2, L26_2, L27_2, L28_2)
  L23_2 = L1_2
  L22_2 = L1_2.AnimateToPoint
  L24_2 = L1_2.CustomData
  L24_2 = L24_2.nNullPoint
  L25_2 = _knFrame
  L25_2 = L25_2 * 25
  L26_2 = true
  L27_2 = _StartIconTranslation
  L22_2(L23_2, L24_2, L25_2, L26_2, L27_2)
  return L1_2
end

_CreateFlyingIcon = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = MrxGuiBase
  L1_2 = L1_2.ImageWidget
  L2_2 = L1_2
  L1_2 = L1_2.new
  L1_2 = L1_2(L2_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetOwner
  L5_2 = A0_2
  L4_2 = A0_2.GetOwner
  L4_2, L5_2 = L4_2(L5_2)
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetLocation
  L5_2 = A0_2
  L4_2 = A0_2.GetLocation
  L4_2, L5_2 = L4_2(L5_2)
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetTexture
  L5_2 = A0_2
  L4_2 = A0_2.GetTexture
  L4_2, L5_2 = L4_2(L5_2)
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetTextureCoordinates
  L5_2 = A0_2
  L4_2 = A0_2.GetTextureCoordinates
  L4_2, L5_2 = L4_2(L5_2)
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetAnchoring
  L4_2 = "left"
  L5_2 = "top"
  L2_2(L3_2, L4_2, L5_2)
  return L1_2
end

_CopyImageParameters = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = MrxGuiBase
  L1_2 = L1_2.RemoveWidgetWithChildren
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L8_2 = L6_2
    L7_2 = L6_2.delete
    L7_2(L8_2)
  end
  L3_2 = A0_2
  L2_2 = A0_2.delete
  L2_2(L3_2)
end

_CompleteIconTranslation = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L1_2 = MrxGuiBase
  L1_2 = L1_2.GetWidgetByNameAndOwner
  L2_2 = "Current Gun"
  L4_2 = A0_2
  L3_2 = A0_2.GetOwner
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2 = L3_2(L4_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  if L1_2 then
    L3_2 = L1_2
    L2_2 = L1_2.TriggerAnimation
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.oIcon
    L5_2 = L4_2
    L4_2 = L4_2.GetTexture
    L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2 = L4_2(L5_2)
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  end
  L3_2 = A0_2
  L2_2 = A0_2.AnimateToPoint
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nTargetPoint
  L5_2 = _knFrame
  L5_2 = L5_2 * 10
  L6_2 = true
  L7_2 = _CompleteIconTranslation
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oIcon
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oIconBg
  L5_2 = L2_2
  L4_2 = L2_2.ScaleTo
  L6_2 = nil
  L7_2 = 0
  L8_2 = _knFrame
  L8_2 = L8_2 * 5
  L9_2 = true
  L10_2 = L2_2.ScaleTo
  L11_2 = {}
  L12_2 = nil
  L13_2 = L2_2.CustomData
  L13_2 = L13_2.nOriginalHeight
  L14_2 = _knFrame
  L14_2 = L14_2 * 5
  L15_2 = true
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L11_2[3] = L14_2
  L11_2[4] = L15_2
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  L5_2 = L3_2
  L4_2 = L3_2.ScaleTo
  L6_2 = nil
  L7_2 = 0
  L8_2 = _knFrame
  L8_2 = L8_2 * 5
  L9_2 = true
  L10_2 = L3_2.ScaleTo
  L11_2 = {}
  L12_2 = nil
  L13_2 = L3_2.CustomData
  L13_2 = L13_2.nOriginalHeight
  L14_2 = _knFrame
  L14_2 = L14_2 * 5
  L15_2 = true
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L11_2[3] = L14_2
  L11_2[4] = L15_2
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
end

_StartIconTranslation = L0_1

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

ValidateParameter = L0_1

function L0_1(A0_2, A1_2)
  if A1_2 < A0_2 then
    return A1_2
  end
  return A0_2
end

Min = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bEnabled
  if not L2_2 then
    return
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bAddItemInProgress
  if L2_2 then
    L2_2 = MrxGuiBase
    L2_2 = L2_2.Joystick
    L2_2 = L2_2.BUTTON_PAD2_D
    L3_2 = A1_2.ButtonPress
    if L2_2 ~= L3_2 then
      L2_2 = MrxGuiBase
      L2_2 = L2_2.Joystick
      L2_2 = L2_2.BUTTON_ALT2_1
      L3_2 = A1_2.ButtonPress
    end
    if L2_2 == L3_2 then
      L2_2 = A0_2.CustomData
      L2_2.bSnapAddAnimation = true
      L2_2 = Event
      L2_2 = L2_2.Post
      L3_2 = "Support Menu Open"
      L4_2 = {}
      L6_2 = A0_2
      L5_2 = A0_2.GetOwner
      L5_2 = L5_2(L6_2)
      L4_2.uPlayer = L5_2
      L2_2(L3_2, L4_2)
    end
  else
    L2_2 = MrxGuiBase
    L2_2 = L2_2.Joystick
    L2_2 = L2_2.BUTTON_PAD1_U
    L3_2 = A1_2.ButtonPress
    if L2_2 == L3_2 then
      L3_2 = A0_2
      L2_2 = A0_2._ScrollDown
      L2_2(L3_2)
    else
      L2_2 = MrxGuiBase
      L2_2 = L2_2.Joystick
      L2_2 = L2_2.BUTTON_PAD1_D
      L3_2 = A1_2.ButtonPress
      if L2_2 == L3_2 then
        L3_2 = A0_2
        L2_2 = A0_2._ScrollUp
        L2_2(L3_2)
      else
        L2_2 = MrxGuiBase
        L2_2 = L2_2.Joystick
        L2_2 = L2_2.BUTTON_PAD2_D
        L3_2 = A1_2.ButtonPress
        if L2_2 ~= L3_2 then
          L2_2 = MrxGuiBase
          L2_2 = L2_2.Joystick
          L2_2 = L2_2.BUTTON_ALT2_1
          L3_2 = A1_2.ButtonPress
          if L2_2 ~= L3_2 then
            goto lbl_66
          end
        end
        L3_2 = A0_2
        L2_2 = A0_2.Trigger
        L2_2(L3_2)
        goto lbl_84
        ::lbl_66::
        L2_2 = MrxGuiBase
        L2_2 = L2_2.Joystick
        L2_2 = L2_2.BUTTON_PAD1_L
        L3_2 = A1_2.ButtonPress
        if L2_2 ~= L3_2 then
          L2_2 = MrxGuiBase
          L2_2 = L2_2.Joystick
          L2_2 = L2_2.BUTTON_PAD1_R
          L3_2 = A1_2.ButtonPress
          if L2_2 == L3_2 then
          else
            L2_2 = A1_2.ButtonPress
            if L2_2 then
              L3_2 = A0_2
              L2_2 = A0_2.Close
              L2_2(L3_2)
            end
          end
        end
      end
    end
  end
  ::lbl_84::
end

HandleInputEvent = L0_1

function L0_1(A0_2, A1_2)
  if A1_2 < 1 then
    return A0_2
  end
  if 1 <= A0_2 and A0_2 <= A1_2 then
    return A0_2
  end
  if A0_2 < 1 then
    while A0_2 < 1 do
      A0_2 = A0_2 + A1_2
    end
    return A0_2
  end
  if A1_2 < A0_2 then
    while A1_2 < A0_2 do
      A0_2 = A0_2 - A1_2
    end
    return A0_2
  end
  return A0_2
end

WrapIndex = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A1_2.CustomData
  L2_2.bSuspendInput = false
  L2_2 = A1_2.CustomData
  L2_2 = L2_2.bEnabled
  if L2_2 then
    L2_2 = UpdateDisplayText
    L3_2 = A1_2
    L2_2(L3_2)
  end
  L2_2 = A1_2.CustomData
  L2_2 = L2_2.tPendingItemQueue
  L2_2 = #L2_2
  if 0 < L2_2 then
    L2_2 = _AddAnimationComplete
    L3_2 = nil
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  else
    L2_2 = A1_2.CustomData
    L2_2 = L2_2.bCloseOnComplete
    if L2_2 then
      L2_2 = A1_2.CustomData
      L2_2.bCloseOnComplete = false
      L2_2 = A1_2.CustomData
      L2_2.nBufferedInput = 0
      L2_2 = A1_2.CustomData
      L2_2.bConfirmEntered = nil
      L3_2 = A1_2
      L2_2 = A1_2.Close
      L2_2(L3_2)
    else
      L2_2 = math
      L2_2 = L2_2.abs
      L3_2 = A1_2.CustomData
      L3_2 = L3_2.nBufferedInput
      L2_2 = L2_2(L3_2)
      if 0.5 < L2_2 then
        L2_2 = A1_2.CustomData
        L2_2 = L2_2.nBufferedInput
        if 0 < L2_2 then
          L2_2 = A1_2.CustomData
          L3_2 = A1_2.CustomData
          L3_2 = L3_2.nBufferedInput
          L3_2 = L3_2 - 1
          L2_2.nBufferedInput = L3_2
          L3_2 = A1_2
          L2_2 = A1_2._ScrollUp
          L2_2(L3_2)
        else
          L2_2 = A1_2.CustomData
          L2_2 = L2_2.nBufferedInput
          if L2_2 < 0 then
            L2_2 = A1_2.CustomData
            L3_2 = A1_2.CustomData
            L3_2 = L3_2.nBufferedInput
            L3_2 = L3_2 + 1
            L2_2.nBufferedInput = L3_2
            L3_2 = A1_2
            L2_2 = A1_2._ScrollDown
            L2_2(L3_2)
          end
        end
      else
        L2_2 = A1_2.CustomData
        L2_2 = L2_2.bConfirmEntered
        if L2_2 then
          L3_2 = A1_2
          L2_2 = A1_2.Trigger
          L2_2(L3_2)
          L2_2 = A1_2.CustomData
          L2_2.bConfirmEntered = nil
        else
          L2_2 = A1_2.CustomData
          L2_2 = L2_2.tDisplayList
          L3_2 = ipairs
          L4_2 = L2_2
          L3_2, L4_2, L5_2 = L3_2(L4_2)
          for L6_2, L7_2 in L3_2, L4_2, L5_2 do
            L8_2 = L7_2.CustomData
            L8_2 = L8_2.oStatus
            L9_2 = L8_2.CustomData
            L9_2 = L9_2.bInUse
            if L9_2 then
              L9_2 = _StartStatusPulse
              L10_2 = L8_2
              L9_2(L10_2)
            else
              L9_2 = _HaltStatusPulse
              L10_2 = L8_2
              L9_2(L10_2)
            end
          end
          L3_2 = _HaltStatusPulse
          L4_2 = L2_2[1]
          L4_2 = L4_2.CustomData
          L4_2 = L4_2.oStatus
          L3_2(L4_2)
          L3_2 = _HaltStatusPulse
          L4_2 = L2_2[5]
          L4_2 = L4_2.CustomData
          L4_2 = L4_2.oStatus
          L3_2(L4_2)
        end
      end
    end
  end
end

_AnimationCompleteCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A1_2.CustomData
  L2_2 = L2_2.oDescripters
  L3_2 = L2_2
  L2_2 = L2_2.SetVisible
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = _AnimationCompleteCallback
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

_FrameAnimationCompleteCallback = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  if A1_2 and "SupportMenu" == A1_2 and A2_2 then
    if "Enter" == A2_2 then
      L4_2 = A0_2
      L3_2 = A0_2.Open
      L3_2(L4_2)
    end
    if "Exit" == A2_2 then
      L4_2 = A0_2
      L3_2 = A0_2.Close
      L3_2(L4_2)
    end
  end
end

_HandleGameStateChangeEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  if A1_2 then
    L3_2 = A1_2
    L2_2 = A1_2.SetTexture
    L5_2 = A0_2
    L4_2 = A0_2.GetTexture
    L4_2, L5_2 = L4_2(L5_2)
    L2_2(L3_2, L4_2, L5_2)
    L3_2 = A1_2
    L2_2 = A1_2.SetVisible
    L4_2 = true
    L2_2(L3_2, L4_2)
  end
  L2_2 = MrxGuiBase
  L2_2 = L2_2.RemoveWidget
  L3_2 = A0_2
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2.delete
  L2_2(L3_2)
end

_RemoveOnAnimationComplete = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 0.5
  L3_2[1] = L4_2
  L4_2 = _DelayedSupportMenuCloseCallback
  L5_2 = {}
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.oParentSupportMenu
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.fCallback
  L8_2 = A0_2.CustomData
  L8_2 = L8_2.tCallbackData
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = MrxGuiBase
  L1_2 = L1_2.RemoveWidget
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = _AddAnimationComplete
  L2_2 = nil
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oParentSupportMenu
  L1_2(L2_2, L3_2)
end

_RemoveAddAnimationComplete = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L4_2 = A0_2
  L3_2 = A0_2.Close
  L3_2(L4_2)
  L3_2 = type
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if "function" == L3_2 then
    L3_2 = A2_2
    L4_2 = type
    L5_2 = A2_2
    L4_2 = L4_2(L5_2)
    if "table" ~= L4_2 then
      L4_2 = {}
      L3_2 = L4_2
    end
    L4_2 = A1_2
    L5_2 = unpack
    L6_2 = L3_2
    L5_2, L6_2 = L5_2(L6_2)
    L4_2(L5_2, L6_2)
  end
end

_DelayedSupportMenuCloseCallback = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2
  if A2_2 then
    L4_2 = A2_2
    L5_2 = unpack
    L6_2 = A3_2 or L6_2
    if not A3_2 then
      L6_2 = {}
    end
    L5_2, L6_2 = L5_2(L6_2)
    L4_2(L5_2, L6_2)
  end
  L4_2 = A1_2.CustomData
  L4_2.bAddItemInProgress = false
  L4_2 = A1_2.CustomData
  L4_2 = L4_2.tPendingItemQueue
  L4_2 = #L4_2
  if L4_2 <= 0 then
    return
  end
  L5_2 = A1_2
  L4_2 = A1_2.AddItem
  L6_2 = A1_2.CustomData
  L6_2 = L6_2.tPendingItemQueue
  L6_2 = L6_2[1]
  L4_2(L5_2, L6_2)
  L4_2 = table
  L4_2 = L4_2.remove
  L5_2 = A1_2.CustomData
  L5_2 = L5_2.tPendingItemQueue
  L6_2 = 1
  L4_2(L5_2, L6_2)
end

_AddAnimationComplete = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.bEnabled
  if not L3_2 then
    return
  end
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nNumberOfItems
  if L3_2 < 1 then
    return
  end
  L3_2 = A0_2.CustomData
  L3_2.bSuspendInput = true
  L3_2 = A0_2.CustomData
  L3_2.bAddItemInProgress = true
  L3_2 = A0_2.CustomData
  L3_2.bSnapAddAnimation = false
  L3_2 = A0_2.CustomData
  L3_2.fAddCallback = A1_2
  L3_2 = A0_2.CustomData
  L3_2.tAddCallbackData = A2_2
  L4_2 = A0_2
  L3_2 = A0_2._SetDisplayInformation
  L3_2(L4_2)
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.tDisplayList
  L4_2 = L3_2[2]
  L5_2 = L4_2
  L4_2 = L4_2.SetVisible
  L6_2 = true
  L4_2(L5_2, L6_2)
  L4_2 = L3_2[3]
  L5_2 = L4_2
  L4_2 = L4_2.SetVisible
  L6_2 = false
  L4_2(L5_2, L6_2)
  L4_2 = L3_2[4]
  L5_2 = L4_2
  L4_2 = L4_2.SetVisible
  L6_2 = true
  L4_2(L5_2, L6_2)
  L4_2 = L3_2[5]
  L5_2 = L4_2
  L4_2 = L4_2.SetVisible
  L6_2 = true
  L4_2(L5_2, L6_2)
  L4_2 = L3_2[2]
  L5_2 = L4_2
  L4_2 = L4_2.SetTranslucency
  L6_2 = 255
  L4_2(L5_2, L6_2)
  L4_2 = L3_2[3]
  L5_2 = L4_2
  L4_2 = L4_2.SetTranslucency
  L6_2 = 255
  L4_2(L5_2, L6_2)
  L4_2 = L3_2[4]
  L5_2 = L4_2
  L4_2 = L4_2.SetTranslucency
  L6_2 = 255
  L4_2(L5_2, L6_2)
  L4_2 = L3_2[5]
  L5_2 = L4_2
  L4_2 = L4_2.SetTranslucency
  L6_2 = 255
  L4_2(L5_2, L6_2)
  L4_2 = _SetupItemNext
  L5_2 = L3_2[4]
  L4_2(L5_2)
  L4_2 = _SetupSquish
  L5_2 = L3_2[5]
  L6_2 = false
  L7_2 = false
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oDescripters
  L5_2 = L4_2
  L4_2 = L4_2.SetVisible
  L6_2 = false
  L4_2(L5_2, L6_2)
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oFrame
  L6_2 = L4_2
  L5_2 = L4_2.AnimateToPoint
  L7_2 = L4_2.CustomData
  L7_2 = L7_2.nClosePoint
  L8_2 = _knFrame
  L8_2 = L8_2 * 5
  L9_2 = true
  L10_2 = L4_2.SetVisible
  L11_2 = {}
  L12_2 = false
  L11_2[1] = L12_2
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.oDownArrow
  L7_2 = L5_2
  L6_2 = L5_2.SetVisible
  L8_2 = true
  L6_2(L7_2, L8_2)
  L7_2 = L5_2
  L6_2 = L5_2.AnimateToPoint
  L8_2 = L5_2.CustomData
  L8_2 = L8_2.nFadeInPoint
  L9_2 = 0
  L10_2 = true
  L6_2(L7_2, L8_2, L9_2, L10_2)
  L7_2 = L5_2
  L6_2 = L5_2.AnimateToPoint
  L8_2 = L5_2.CustomData
  L8_2 = L8_2.nFadeOutPoint
  L9_2 = _knFrame
  L9_2 = L9_2 * 5
  L10_2 = false
  L6_2(L7_2, L8_2, L9_2, L10_2)
  L6_2 = A0_2.CustomData
  L6_2.nTime = 0
  L7_2 = A0_2
  L6_2 = A0_2.SetEventHandler
  L8_2 = "GuiUpdate"
  L9_2 = _HandleUpdateForAdd
  L6_2(L7_2, L8_2, L9_2)
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.oClockIcon
  L7_2 = L6_2
  L6_2 = L6_2.SetVisible
  L8_2 = false
  L6_2(L7_2, L8_2)
  L6_2 = Sound
  L6_2 = L6_2.CueSound
  L7_2 = 0
  L8_2 = "ui_HUD_Support_Scroll"
  L6_2(L7_2, L8_2)
end

_PerformAddAnimation = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  if not A1_2 then
    return
  end
  L2_2 = _knFrame
  L3_2 = _knFrame
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nTime
  if not L4_2 then
    L4_2 = A0_2.CustomData
    L4_2.nTime = 0
  end
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nTime
  L5_2 = L4_2 + A1_2
  L6_2 = A0_2.CustomData
  L6_2.nTime = L5_2
  L6_2 = false
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.bSnapAddAnimation
  if L7_2 then
    L7_2 = L2_2 * 400
    L5_2 = L5_2 + L7_2
    L3_2 = 0
    L7_2 = A0_2.CustomData
    L7_2.bSnapAddAnimation = false
    L6_2 = true
  end
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.tDisplayList
  L8_2 = _PassedPoint
  L9_2 = L4_2
  L10_2 = L5_2
  L11_2 = L2_2 * 4
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  if L8_2 then
    L8_2 = L7_2[4]
    L9_2 = L8_2
    L8_2 = L8_2.TriggerNext
    L10_2 = L3_2 * 10
    L8_2(L9_2, L10_2)
  end
  L8_2 = _PassedPoint
  L9_2 = L4_2
  L10_2 = L5_2
  L11_2 = L2_2 * 5
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  if L8_2 then
    L8_2 = L7_2[5]
    L9_2 = L8_2
    L8_2 = L8_2.TriggerSquish
    L10_2 = L3_2 * 10
    L11_2 = false
    L12_2 = false
    L8_2(L9_2, L10_2, L11_2, L12_2)
  end
  L8_2 = _PassedPoint
  L9_2 = L4_2
  L10_2 = L5_2
  L11_2 = L2_2 * 15
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  if L8_2 or L6_2 then
    L8_2 = L7_2[3]
    L9_2 = _PassedPoint
    L10_2 = L4_2
    L11_2 = L5_2
    L12_2 = L2_2 * 15
    L9_2 = L9_2(L10_2, L11_2, L12_2)
    if L9_2 then
      L10_2 = L8_2
      L9_2 = L8_2.GetLocation
      L9_2, L10_2 = L9_2(L10_2)
      L12_2 = L8_2
      L11_2 = L8_2.SetLocation
      L13_2 = L9_2 + 200
      L14_2 = L10_2
      L11_2(L12_2, L13_2, L14_2)
      L12_2 = L8_2
      L11_2 = L8_2.SetVisible
      L13_2 = true
      L11_2(L12_2, L13_2)
    end
    L10_2 = L8_2
    L9_2 = L8_2.AnimateToPoint
    L11_2 = L8_2.CustomData
    L11_2 = L11_2.nAddPoint
    L12_2 = L3_2 * 15
    L13_2 = true
    L9_2(L10_2, L11_2, L12_2, L13_2)
  end
  L8_2 = _PassedPoint
  L9_2 = L4_2
  L10_2 = L5_2
  L11_2 = L2_2 * 30
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  if L8_2 or L6_2 then
    L8_2 = A0_2.CustomData
    L8_2 = L8_2.oFrame
    L10_2 = L8_2
    L9_2 = L8_2.SetVisible
    L11_2 = true
    L9_2(L10_2, L11_2)
    L10_2 = L8_2
    L9_2 = L8_2.AnimateToPoint
    L11_2 = L8_2.CustomData
    L11_2 = L11_2.nOriginPoint
    L12_2 = L3_2 * 5
    L13_2 = true
    L14_2 = _FrameAnimationCompleteCallback
    L15_2 = {}
    L16_2 = A0_2
    L15_2[1] = L16_2
    L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
    L9_2 = A0_2.CustomData
    L9_2.bSuspendInput = false
    L9_2 = A0_2.CustomData
    L9_2.bAddItemInProgress = false
  end
  L8_2 = _PassedPoint
  L9_2 = L4_2
  L10_2 = L5_2
  L11_2 = L2_2 * 150
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  if L8_2 or L6_2 then
    L8_2 = A0_2.CustomData
    L8_2.nTime = 0
    L9_2 = A0_2
    L8_2 = A0_2.SetEventHandler
    L10_2 = "GuiUpdate"
    L11_2 = HandleUpdateForIdle
    L8_2(L9_2, L10_2, L11_2)
    L8_2 = A0_2.CustomData
    L8_2.bAddItemInProgress = false
    L8_2 = A0_2.CustomData
    L8_2.bSuspendInput = false
    if not L6_2 then
      L8_2 = A0_2.CustomData
      L8_2 = L8_2.bAnimatingAdd
      if L8_2 then
        L9_2 = A0_2
        L8_2 = A0_2.Close
        L8_2(L9_2)
      end
    end
    L8_2 = A0_2.CustomData
    L8_2.bAnimatingAdd = false
    L8_2 = type
    L9_2 = A0_2.CustomData
    L9_2 = L9_2.fAddCallback
    L8_2 = L8_2(L9_2)
    if "function" == L8_2 then
      L8_2 = A0_2.CustomData
      L8_2 = L8_2.tAddCallbackData
      L9_2 = type
      L10_2 = L8_2
      L9_2 = L9_2(L10_2)
      if "table" ~= L9_2 then
        L9_2 = {}
        L8_2 = L9_2
      end
      L9_2 = A0_2.CustomData
      L9_2 = L9_2.fAddCallback
      L10_2 = unpack
      L11_2 = L8_2
      L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L10_2(L11_2)
      L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
    end
  end
end

_HandleUpdateForAdd = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L4_2 = MrxGuiBase
  L4_2 = L4_2.Widget
  L5_2 = L4_2
  L4_2 = L4_2.new
  L4_2 = L4_2(L5_2)
  L6_2 = L4_2
  L5_2 = L4_2.SetLocation
  L7_2 = A0_2
  L8_2 = A1_2
  L9_2 = A0_2 + 200
  L10_2 = A1_2 + A2_2
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L6_2 = L4_2
  L5_2 = L4_2.SetOwner
  L7_2 = A3_2
  L5_2(L6_2, L7_2)
  L5_2 = MrxGuiBase
  L5_2 = L5_2.ImageWidget
  L6_2 = L5_2
  L5_2 = L5_2.new
  L5_2 = L5_2(L6_2)
  L7_2 = L5_2
  L6_2 = L5_2.SetLocation
  L8_2 = A0_2
  L9_2 = A1_2
  L10_2 = A0_2 + A2_2
  L11_2 = A1_2 + A2_2
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  L7_2 = L5_2
  L6_2 = L5_2.SetTexture
  L8_2 = "global_gui_hud02"
  L6_2(L7_2, L8_2)
  L7_2 = L5_2
  L6_2 = L5_2.SetTextureCoordinates
  L8_2 = 0.195313
  L9_2 = 0.462891
  L10_2 = 0.378906
  L11_2 = 0.646484
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  L7_2 = L4_2
  L6_2 = L4_2.AddChild
  L8_2 = L5_2
  L6_2(L7_2, L8_2)
  L6_2 = A2_2 * 0.5
  L6_2 = A0_2 + L6_2
  L7_2 = L5_2.CustomData
  L9_2 = L5_2
  L8_2 = L5_2.AddAnimationPoint
  L10_2 = {}
  L10_2.x = L6_2
  L10_2.y = A1_2
  L10_2.x2 = L6_2
  L11_2 = A1_2 + A2_2
  L10_2.y2 = L11_2
  L8_2 = L8_2(L9_2, L10_2)
  L7_2.nHidePoint = L8_2
  L7_2 = L5_2.CustomData
  L9_2 = L5_2
  L8_2 = L5_2.AddAnimationPoint
  L10_2 = {}
  L10_2.x = A0_2
  L10_2.y = A1_2
  L11_2 = A0_2 + A2_2
  L10_2.x2 = L11_2
  L11_2 = A1_2 + A2_2
  L10_2.y2 = L11_2
  L8_2 = L8_2(L9_2, L10_2)
  L7_2.nShowPoint = L8_2
  L8_2 = L5_2
  L7_2 = L5_2.SetOwner
  L9_2 = A3_2
  L7_2(L8_2, L9_2)
  L7_2 = MrxGuiBase
  L7_2 = L7_2.ImageWidget
  L8_2 = L7_2
  L7_2 = L7_2.new
  L7_2 = L7_2(L8_2)
  L9_2 = L7_2
  L8_2 = L7_2.SetLocation
  L10_2 = A0_2
  L11_2 = A1_2
  L12_2 = A0_2 + A2_2
  L13_2 = A1_2 + A2_2
  L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  L9_2 = L7_2
  L8_2 = L7_2.SetOwner
  L10_2 = A3_2
  L8_2(L9_2, L10_2)
  L8_2 = L7_2.CustomData
  L10_2 = L7_2
  L9_2 = L7_2.AddAnimationPoint
  L11_2 = {}
  L11_2.x = L6_2
  L11_2.y = A1_2
  L11_2.x2 = L6_2
  L12_2 = A1_2 + A2_2
  L11_2.y2 = L12_2
  L9_2 = L9_2(L10_2, L11_2)
  L8_2.nHidePoint = L9_2
  L8_2 = L7_2.CustomData
  L10_2 = L7_2
  L9_2 = L7_2.AddAnimationPoint
  L11_2 = {}
  L11_2.x = A0_2
  L11_2.y = A1_2
  L12_2 = A0_2 + A2_2
  L11_2.x2 = L12_2
  L12_2 = A1_2 + A2_2
  L11_2.y2 = L12_2
  L9_2 = L9_2(L10_2, L11_2)
  L8_2.nShowPoint = L9_2
  L9_2 = L4_2
  L8_2 = L4_2.AddChild
  L10_2 = L7_2
  L8_2(L9_2, L10_2)
  L8_2 = MrxGuiBase
  L8_2 = L8_2.ImageWidget
  L9_2 = L8_2
  L8_2 = L8_2.new
  L8_2 = L8_2(L9_2)
  L10_2 = L8_2
  L9_2 = L8_2.SetLocation
  L11_2 = A0_2
  L12_2 = A1_2
  L13_2 = A0_2 + A2_2
  L14_2 = A1_2 + A2_2
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
  L10_2 = L8_2
  L9_2 = L8_2.SetTexture
  L11_2 = "global_gui_hud02"
  L9_2(L10_2, L11_2)
  L10_2 = L8_2
  L9_2 = L8_2.SetTextureCoordinates
  L11_2 = 0
  L12_2 = 0.458985
  L13_2 = 0.1875
  L14_2 = 0.646484
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
  L10_2 = L8_2
  L9_2 = L8_2.SetOwner
  L11_2 = A3_2
  L9_2(L10_2, L11_2)
  L9_2 = L8_2.CustomData
  L11_2 = L8_2
  L10_2 = L8_2.AddAnimationPoint
  L12_2 = {}
  L12_2.x = L6_2
  L12_2.y = A1_2
  L12_2.x2 = L6_2
  L13_2 = A1_2 + A2_2
  L12_2.y2 = L13_2
  L10_2 = L10_2(L11_2, L12_2)
  L9_2.nHidePoint = L10_2
  L9_2 = L8_2.CustomData
  L11_2 = L8_2
  L10_2 = L8_2.AddAnimationPoint
  L12_2 = {}
  L12_2.x = A0_2
  L12_2.y = A1_2
  L13_2 = A0_2 + A2_2
  L12_2.x2 = L13_2
  L13_2 = A1_2 + A2_2
  L12_2.y2 = L13_2
  L10_2 = L10_2(L11_2, L12_2)
  L9_2.nShowPoint = L10_2
  L10_2 = L4_2
  L9_2 = L4_2.AddChild
  L11_2 = L8_2
  L9_2(L10_2, L11_2)
  L9_2 = MrxGuiBase
  L9_2 = L9_2.TextWidget
  L10_2 = L9_2
  L9_2 = L9_2.new
  L9_2 = L9_2(L10_2)
  L11_2 = L9_2
  L10_2 = L9_2.SetLocation
  L12_2 = A0_2 + A2_2
  L12_2 = L12_2 + 4
  L13_2 = A1_2 + 10
  L10_2(L11_2, L12_2, L13_2)
  L11_2 = L9_2
  L10_2 = L9_2.SetFont
  L12_2 = "english_18"
  L10_2(L11_2, L12_2)
  L10_2 = L9_2.CustomData
  L12_2 = L9_2
  L11_2 = L9_2.AddAnimationPoint
  L13_2 = {}
  L13_2.TranslucencyLevel = 255
  L11_2 = L11_2(L12_2, L13_2)
  L10_2.nShowPoint = L11_2
  L10_2 = L9_2.CustomData
  L12_2 = L9_2
  L11_2 = L9_2.AddAnimationPoint
  L13_2 = {}
  L13_2.TranslucencyLevel = 0
  L11_2 = L11_2(L12_2, L13_2)
  L10_2.nHidePoint = L11_2
  L11_2 = L9_2
  L10_2 = L9_2.SetOwner
  L12_2 = A3_2
  L10_2(L11_2, L12_2)
  L11_2 = L4_2
  L10_2 = L4_2.AddChild
  L12_2 = L9_2
  L10_2(L11_2, L12_2)
  L10_2 = L4_2.CustomData
  L11_2 = {}
  L10_2.tQueue = L11_2
  L10_2 = L4_2.CustomData
  L10_2.oIcon = L7_2
  L10_2 = L4_2.CustomData
  L10_2.oText = L9_2
  L10_2 = L4_2.CustomData
  L10_2.oIconBg = L5_2
  L10_2 = L4_2.CustomData
  L10_2.oIconFrame = L8_2
  L10_2 = L4_2.CustomData
  L10_2.bActive = false
  L10_2 = _GuiInternal
  L10_2 = L10_2.SetWidgetUseNewRescale
  L11_2 = L4_2.BasicData
  L11_2 = L11_2.uId
  L12_2 = true
  L10_2(L11_2, L12_2)
  L10_2 = ShowNewAddAnimation
  L4_2.Show = L10_2
  L10_2 = HideNewAddAnimation
  L4_2.Hide = L10_2
  L10_2 = RemoveNewAddItem
  L4_2.Remove = L10_2
  L10_2 = MrxGuiBase
  L10_2 = L10_2.AddWidgetWithChildren
  L11_2 = L4_2
  L10_2(L11_2)
  L11_2 = L4_2
  L10_2 = L4_2.Hide
  L10_2(L11_2)
  return L4_2
end

InitAddWidget = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = table
  L3_2 = L3_2.insert
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.tQueue
  L5_2 = {}
  L6_2 = A1_2
  L7_2 = A2_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L3_2(L4_2, L5_2)
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.bActive
  if not L3_2 then
    L3_2 = A0_2.CustomData
    L3_2.bActive = true
    L4_2 = A0_2
    L3_2 = A0_2.SetVisible
    L5_2 = true
    L3_2(L4_2, L5_2)
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.oIconBg
    L5_2 = L3_2
    L4_2 = L3_2.AnimateToPoint
    L6_2 = L3_2.CustomData
    L6_2 = L6_2.nHidePoint
    L7_2 = 0.01
    L8_2 = true
    L9_2 = _NewAddProcessQueue
    L10_2 = {}
    L11_2 = A0_2
    L12_2 = true
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  end
end

ShowNewAddAnimation = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2
  L1_2 = A0_2.SetVisible
  L3_2 = false
  L1_2(L2_2, L3_2)
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oIconBg
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oIcon
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oIconFrame
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.oText
  L6_2 = L1_2
  L5_2 = L1_2.AnimateToPoint
  L7_2 = L1_2.CustomData
  L7_2 = L7_2.nHidePoint
  L8_2 = 0
  L9_2 = true
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = L4_2
  L5_2 = L4_2.AnimateToPoint
  L7_2 = L4_2.CustomData
  L7_2 = L7_2.nHidePoint
  L8_2 = 0
  L9_2 = true
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = L2_2
  L5_2 = L2_2.AnimateToPoint
  L7_2 = L2_2.CustomData
  L7_2 = L7_2.nHidePoint
  L8_2 = 0
  L9_2 = true
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = L3_2
  L5_2 = L3_2.AnimateToPoint
  L7_2 = L3_2.CustomData
  L7_2 = L7_2.nHidePoint
  L8_2 = 0
  L9_2 = true
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L5_2 = A0_2.CustomData
  L5_2.bActive = false
  L5_2 = A0_2.CustomData
  L6_2 = {}
  L5_2.tQueue = L6_2
end

HideNewAddAnimation = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = pairs
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.tQueue
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = L7_2[2]
    if L8_2 == A1_2 then
      L2_2 = L6_2
    end
  end
  if L2_2 then
    L3_2 = table
    L3_2 = L3_2.remove
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.tQueue
    L5_2 = L2_2
    L3_2(L4_2, L5_2)
  end
end

RemoveNewAddItem = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L3_2 = A1_2.CustomData
  L3_2 = L3_2.tQueue
  L3_2 = #L3_2
  if L3_2 < 1 then
    L4_2 = A1_2
    L3_2 = A1_2.Hide
    L3_2(L4_2)
    return
  end
  L3_2 = A1_2.CustomData
  L3_2 = L3_2.oIconBg
  L4_2 = A1_2.CustomData
  L4_2 = L4_2.oIcon
  L5_2 = A1_2.CustomData
  L5_2 = L5_2.oIconFrame
  L6_2 = A1_2.CustomData
  L6_2 = L6_2.oText
  L7_2 = A1_2.CustomData
  L7_2 = L7_2.tQueue
  L7_2 = L7_2[1]
  L8_2 = table
  L8_2 = L8_2.remove
  L9_2 = A1_2.CustomData
  L9_2 = L9_2.tQueue
  L10_2 = 1
  L8_2(L9_2, L10_2)
  L9_2 = L4_2
  L8_2 = L4_2.SetTexture
  L10_2 = L7_2[1]
  L8_2(L9_2, L10_2)
  L9_2 = L4_2
  L8_2 = L4_2.SetTextureCoordinates
  L10_2 = 0
  L11_2 = 0
  L12_2 = 1
  L13_2 = 1
  L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  L9_2 = L6_2
  L8_2 = L6_2.SetText
  L10_2 = L7_2[2]
  L8_2(L9_2, L10_2)
  L8_2 = 0.15
  L9_2 = 2
  if true == A2_2 then
    L11_2 = L4_2
    L10_2 = L4_2.SetTextureCoordinates
    L12_2 = 1
    L13_2 = 0
    L14_2 = 0
    L15_2 = 1
    L10_2(L11_2, L12_2, L13_2, L14_2, L15_2)
    L11_2 = L3_2
    L10_2 = L3_2.AnimateToPoint
    L12_2 = L3_2.CustomData
    L12_2 = L12_2.nShowPoint
    L13_2 = L8_2
    L14_2 = true
    L15_2 = _NewAddStepInitial2
    L16_2 = {}
    L17_2 = L6_2
    L18_2 = L4_2
    L19_2 = L5_2
    L20_2 = A1_2
    L16_2[1] = L17_2
    L16_2[2] = L18_2
    L16_2[3] = L19_2
    L16_2[4] = L20_2
    L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
    L11_2 = L6_2
    L10_2 = L6_2.AnimateToPoint
    L12_2 = L6_2.CustomData
    L12_2 = L12_2.nHidePoint
    L13_2 = 0
    L14_2 = true
    L10_2(L11_2, L12_2, L13_2, L14_2)
  else
    L11_2 = L3_2
    L10_2 = L3_2.AnimateToPoint
    L12_2 = L3_2.CustomData
    L12_2 = L12_2.nShowPoint
    L13_2 = L8_2
    L14_2 = true
    L15_2 = _NewAddStep2
    L16_2 = {}
    L17_2 = L6_2
    L18_2 = L4_2
    L19_2 = L5_2
    L20_2 = A1_2
    L16_2[1] = L17_2
    L16_2[2] = L18_2
    L16_2[3] = L19_2
    L16_2[4] = L20_2
    L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
    L11_2 = L6_2
    L10_2 = L6_2.AnimateToPoint
    L12_2 = L6_2.CustomData
    L12_2 = L12_2.nShowPoint
    L13_2 = L8_2
    L14_2 = true
    L10_2(L11_2, L12_2, L13_2, L14_2)
  end
  L11_2 = L4_2
  L10_2 = L4_2.AnimateToPoint
  L12_2 = L4_2.CustomData
  L12_2 = L12_2.nShowPoint
  L13_2 = L8_2
  L14_2 = true
  L10_2(L11_2, L12_2, L13_2, L14_2)
  L11_2 = L5_2
  L10_2 = L5_2.AnimateToPoint
  L12_2 = L5_2.CustomData
  L12_2 = L12_2.nShowPoint
  L13_2 = L8_2
  L14_2 = true
  L10_2(L11_2, L12_2, L13_2, L14_2)
end

_NewAddProcessQueue = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L5_2 = 0.15
  L6_2 = 2
  L8_2 = A2_2
  L7_2 = A2_2.SetTextureCoordinates
  L9_2 = 0
  L10_2 = 0
  L11_2 = 1
  L12_2 = 1
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L8_2 = A0_2
  L7_2 = A0_2.AnimateToPoint
  L9_2 = A0_2.CustomData
  L9_2 = L9_2.nShowPoint
  L10_2 = L6_2
  L11_2 = true
  L12_2 = _NewAddStep3
  L13_2 = {}
  L14_2 = A1_2
  L15_2 = A2_2
  L16_2 = A3_2
  L17_2 = A4_2
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L13_2[3] = L16_2
  L13_2[4] = L17_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L8_2 = A1_2
  L7_2 = A1_2.AnimateToPoint
  L9_2 = A1_2.CustomData
  L9_2 = L9_2.nShowPoint
  L10_2 = L6_2
  L11_2 = true
  L7_2(L8_2, L9_2, L10_2, L11_2)
  L8_2 = A2_2
  L7_2 = A2_2.AnimateToPoint
  L9_2 = A2_2.CustomData
  L9_2 = L9_2.nShowPoint
  L10_2 = L6_2
  L11_2 = true
  L7_2(L8_2, L9_2, L10_2, L11_2)
  L8_2 = A3_2
  L7_2 = A3_2.AnimateToPoint
  L9_2 = A3_2.CustomData
  L9_2 = L9_2.nShowPoint
  L10_2 = L6_2
  L11_2 = true
  L7_2(L8_2, L9_2, L10_2, L11_2)
end

_NewAddStep2 = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L5_2 = 0.15
  L6_2 = 2
  L8_2 = A0_2
  L7_2 = A0_2.AnimateToPoint
  L9_2 = A0_2.CustomData
  L9_2 = L9_2.nHidePoint
  L10_2 = L5_2
  L11_2 = true
  L12_2 = _NewAddProcessQueue
  L13_2 = {}
  L14_2 = A4_2
  L13_2[1] = L14_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L8_2 = A1_2
  L7_2 = A1_2.AnimateToPoint
  L9_2 = A1_2.CustomData
  L9_2 = L9_2.nHidePoint
  L10_2 = L5_2
  L11_2 = true
  L7_2(L8_2, L9_2, L10_2, L11_2)
  L8_2 = A2_2
  L7_2 = A2_2.AnimateToPoint
  L9_2 = A2_2.CustomData
  L9_2 = L9_2.nHidePoint
  L10_2 = L5_2
  L11_2 = true
  L7_2(L8_2, L9_2, L10_2, L11_2)
  L8_2 = A3_2
  L7_2 = A3_2.AnimateToPoint
  L9_2 = A3_2.CustomData
  L9_2 = L9_2.nHidePoint
  L10_2 = L5_2
  L11_2 = true
  L7_2(L8_2, L9_2, L10_2, L11_2)
end

_NewAddStep3 = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L5_2 = 0.15
  L6_2 = 2
  L8_2 = A0_2
  L7_2 = A0_2.AnimateToPoint
  L9_2 = A0_2.CustomData
  L9_2 = L9_2.nHidePoint
  L10_2 = L5_2
  L11_2 = true
  L12_2 = _NewAddStepInitial3
  L13_2 = {}
  L14_2 = A1_2
  L15_2 = A2_2
  L16_2 = A3_2
  L17_2 = A4_2
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L13_2[3] = L16_2
  L13_2[4] = L17_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L8_2 = A1_2
  L7_2 = A1_2.AnimateToPoint
  L9_2 = A1_2.CustomData
  L9_2 = L9_2.nHidePoint
  L10_2 = L5_2
  L11_2 = true
  L7_2(L8_2, L9_2, L10_2, L11_2)
  L8_2 = A2_2
  L7_2 = A2_2.AnimateToPoint
  L9_2 = A2_2.CustomData
  L9_2 = L9_2.nHidePoint
  L10_2 = L5_2
  L11_2 = true
  L7_2(L8_2, L9_2, L10_2, L11_2)
  L8_2 = A3_2
  L7_2 = A3_2.AnimateToPoint
  L9_2 = A3_2.CustomData
  L9_2 = L9_2.nHidePoint
  L10_2 = L5_2
  L11_2 = true
  L7_2(L8_2, L9_2, L10_2, L11_2)
end

_NewAddStepInitial2 = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L5_2 = 0.15
  L6_2 = 2
  L8_2 = A2_2
  L7_2 = A2_2.SetTextureCoordinates
  L9_2 = 0
  L10_2 = 0
  L11_2 = 1
  L12_2 = 1
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L8_2 = A0_2
  L7_2 = A0_2.AnimateToPoint
  L9_2 = A0_2.CustomData
  L9_2 = L9_2.nShowPoint
  L10_2 = L5_2
  L11_2 = true
  L12_2 = _NewAddStep2
  L13_2 = {}
  L14_2 = A1_2
  L15_2 = A2_2
  L16_2 = A3_2
  L17_2 = A4_2
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L13_2[3] = L16_2
  L13_2[4] = L17_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L8_2 = A1_2
  L7_2 = A1_2.AnimateToPoint
  L9_2 = A1_2.CustomData
  L9_2 = L9_2.nShowPoint
  L10_2 = L5_2
  L11_2 = true
  L7_2(L8_2, L9_2, L10_2, L11_2)
  L8_2 = A2_2
  L7_2 = A2_2.AnimateToPoint
  L9_2 = A2_2.CustomData
  L9_2 = L9_2.nShowPoint
  L10_2 = L5_2
  L11_2 = true
  L7_2(L8_2, L9_2, L10_2, L11_2)
  L8_2 = A3_2
  L7_2 = A3_2.AnimateToPoint
  L9_2 = A3_2.CustomData
  L9_2 = L9_2.nShowPoint
  L10_2 = L5_2
  L11_2 = true
  L7_2(L8_2, L9_2, L10_2, L11_2)
end

_NewAddStepInitial3 = L0_1
