local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiBase"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiDialogBox"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiManager"
L0_1(L1_1)
L0_1 = "store"
sFlashFile = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "userdata" ~= L1_2 then
    L1_2 = false
    return L1_2
  end
  L1_2 = _tShopList
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = false
    return L1_2
  end
  L1_2 = MrxGui
  L1_2 = L1_2.FlashWidget
  L2_2 = L1_2
  L1_2 = L1_2.new
  L1_2 = L1_2(L2_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetOwner
  L4_2 = A0_2
  L2_2(L3_2, L4_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetVisible
  L4_2 = false
  L2_2(L3_2, L4_2)
  L3_2 = L1_2
  L2_2 = L1_2.Pause
  L2_2(L3_2)
  L2_2 = L1_2.CustomData
  L3_2 = {}
  L2_2.tItems = L3_2
  L2_2 = _AddItemWidget
  L1_2.AddItem = L2_2
  L2_2 = _AddItemFullWidget
  L1_2.AddItemFull = L2_2
  L2_2 = _SetCallbackWidget
  L1_2.SetCallback = L2_2
  L2_2 = _SetCloseCallbackWidget
  L1_2.SetCloseCallback = L2_2
  L2_2 = _CommenceWidget
  L1_2.Commence = L2_2
  L2_2 = sFlashFile
  if L2_2 then
    L3_2 = L1_2
    L2_2 = L1_2.SetSwfFile
    L4_2 = sFlashFile
    L5_2 = _FlashLoadedCallback
    L6_2 = {}
    L7_2 = L1_2
    L6_2[1] = L7_2
    L2_2(L3_2, L4_2, L5_2, L6_2)
    L2_2 = MrxGui
    L2_2 = L2_2.AddWidget
    L3_2 = L1_2
    L2_2(L3_2)
  else
    L2_2 = L1_2.CustomData
    L2_2.bLoaded = true
  end
  L2_2 = 283.33334
  L4_2 = L1_2
  L3_2 = L1_2.SetLocation
  L5_2 = 320 - L2_2
  L6_2 = 0
  L7_2 = 320 + L2_2
  L8_2 = 480
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  L3_2 = _tShopList
  L3_2[A0_2] = L1_2
  L3_2 = true
  return L3_2
end

Create = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2, A9_2)
  local L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L10_2 = type
  L11_2 = A0_2
  L10_2 = L10_2(L11_2)
  if "userdata" ~= L10_2 then
    L10_2 = false
    return L10_2
  end
  L10_2 = _tShopList
  L10_2 = L10_2[A0_2]
  if not L10_2 then
    L10_2 = false
    return L10_2
  end
  L10_2 = _tShopList
  L10_2 = L10_2[A0_2]
  L11_2 = L10_2
  L10_2 = L10_2.AddItem
  L12_2 = A1_2
  L13_2 = A2_2
  L14_2 = A3_2
  L15_2 = A4_2
  L16_2 = A5_2
  L17_2 = A6_2
  L18_2 = A7_2
  L19_2 = A8_2
  L20_2 = A9_2
  return L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
end

AddItem = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2, A9_2)
  local L10_2, L11_2, L12_2, L13_2
  L10_2 = type
  L11_2 = A1_2
  L10_2 = L10_2(L11_2)
  if "string" ~= L10_2 then
    L10_2 = false
    return L10_2
  end
  L10_2 = type
  L11_2 = A2_2
  L10_2 = L10_2(L11_2)
  if "number" == L10_2 then
    L10_2 = type
    L11_2 = A3_2
    L10_2 = L10_2(L11_2)
    if "number" == L10_2 then
      L10_2 = type
      L11_2 = A4_2
      L10_2 = L10_2(L11_2)
      if "number" == L10_2 then
        goto lbl_25
      end
    end
  end
  L10_2 = false
  do return L10_2 end
  ::lbl_25::
  L10_2 = {}
  L10_2.sName = A1_2
  L10_2.nCashCost = A2_2
  L10_2.nCurrentStock = A3_2
  L10_2.nMaxStock = A4_2
  L10_2.bUnlocked = A5_2
  L10_2.sId = A6_2
  L10_2.bFuelTank = A7_2
  L10_2.nFuelQuantity = A8_2
  L10_2.sRawName = A9_2
  L11_2 = table
  L11_2 = L11_2.insert
  L12_2 = A0_2.CustomData
  L12_2 = L12_2.tItems
  L13_2 = L10_2
  L11_2(L12_2, L13_2)
  L11_2 = true
  return L11_2
end

_AddItemWidget = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2, A9_2, A10_2, A11_2, A12_2)
  local L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2
  L13_2 = type
  L14_2 = A0_2
  L13_2 = L13_2(L14_2)
  if "userdata" ~= L13_2 then
    L13_2 = false
    return L13_2
  end
  L13_2 = _tShopList
  L13_2 = L13_2[A0_2]
  if not L13_2 then
    L13_2 = false
    return L13_2
  end
  L13_2 = _tShopList
  L13_2 = L13_2[A0_2]
  L14_2 = L13_2
  L13_2 = L13_2.AddItemFull
  L15_2 = A1_2
  L16_2 = A2_2
  L17_2 = A3_2
  L18_2 = A4_2
  L19_2 = A5_2
  L20_2 = A6_2
  L21_2 = A7_2
  L22_2 = A8_2
  L23_2 = A9_2
  L24_2 = A10_2
  L25_2 = A11_2
  L26_2 = A12_2
  return L13_2(L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2)
end

AddItemFull = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2, A9_2, A10_2, A11_2, A12_2)
  local L13_2, L14_2, L15_2, L16_2
  L13_2 = type
  L14_2 = A1_2
  L13_2 = L13_2(L14_2)
  if "string" == L13_2 then
    L13_2 = type
    L14_2 = A2_2
    L13_2 = L13_2(L14_2)
    if "string" == L13_2 then
      L13_2 = type
      L14_2 = A3_2
      L13_2 = L13_2(L14_2)
      if "string" == L13_2 and nil ~= A8_2 then
        goto lbl_20
      end
    end
  end
  L13_2 = false
  do return L13_2 end
  ::lbl_20::
  L13_2 = type
  L14_2 = A4_2
  L13_2 = L13_2(L14_2)
  if "number" == L13_2 then
    L13_2 = type
    L14_2 = A5_2
    L13_2 = L13_2(L14_2)
    if "number" == L13_2 then
      L13_2 = type
      L14_2 = A6_2
      L13_2 = L13_2(L14_2)
      if "number" == L13_2 then
        goto lbl_37
      end
    end
  end
  L13_2 = false
  do return L13_2 end
  ::lbl_37::
  L13_2 = {}
  L13_2.sName = A1_2
  L13_2.sDesc = A2_2
  L13_2.sTexture = A3_2
  L13_2.nCashCost = A4_2
  L13_2.nCurrentStock = A5_2
  L13_2.nMaxStock = A6_2
  L13_2.bUnlocked = A7_2
  L13_2.sId = A8_2
  L13_2.bFuelTank = A9_2
  L13_2.bMarkAsNew = A10_2
  L13_2.nFuelQuantity = A11_2
  L13_2.sRawName = A12_2
  L14_2 = table
  L14_2 = L14_2.insert
  L15_2 = A0_2.CustomData
  L15_2 = L15_2.tItems
  L16_2 = L13_2
  L14_2(L15_2, L16_2)
  L14_2 = true
  return L14_2
end

_AddItemFullWidget = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = type
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if "userdata" ~= L3_2 then
    L3_2 = false
    return L3_2
  end
  L3_2 = _tShopList
  L3_2 = L3_2[A0_2]
  if not L3_2 then
    L3_2 = false
    return L3_2
  end
  L3_2 = _tShopList
  L3_2 = L3_2[A0_2]
  L4_2 = L3_2
  L3_2 = L3_2.SetCallback
  L5_2 = A1_2
  L6_2 = A2_2
  return L3_2(L4_2, L5_2, L6_2)
end

SetCallback = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  if nil == A1_2 then
    L3_2 = A0_2.CustomData
    L3_2.fCallback = nil
    L3_2 = A0_2.CustomData
    L3_2.tCallbackData = nil
    L3_2 = true
    return L3_2
  end
  L3_2 = type
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if "function" ~= L3_2 then
    L3_2 = false
    return L3_2
  end
  L3_2 = A0_2.CustomData
  L3_2.fCallback = A1_2
  L3_2 = type
  L4_2 = A2_2
  L3_2 = L3_2(L4_2)
  if "table" == L3_2 then
    L3_2 = A0_2.CustomData
    L3_2.tCallbackData = A2_2
  else
    L3_2 = A0_2.CustomData
    L3_2.tCallbackData = nil
  end
  L3_2 = true
  return L3_2
end

_SetCallbackWidget = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = type
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if "userdata" ~= L3_2 then
    L3_2 = false
    return L3_2
  end
  L3_2 = _tShopList
  L3_2 = L3_2[A0_2]
  if not L3_2 then
    L3_2 = false
    return L3_2
  end
  L3_2 = _tShopList
  L3_2 = L3_2[A0_2]
  L4_2 = L3_2
  L3_2 = L3_2.SetCloseCallback
  L5_2 = A1_2
  L6_2 = A2_2
  return L3_2(L4_2, L5_2, L6_2)
end

SetCloseCallback = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  if nil == A1_2 then
    L3_2 = A0_2.CustomData
    L3_2.fCloseCallback = nil
    L3_2 = A0_2.CustomData
    L3_2.tCloseCallbackData = nil
    L3_2 = true
    return L3_2
  end
  L3_2 = type
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if "function" ~= L3_2 then
    L3_2 = false
    return L3_2
  end
  L3_2 = A0_2.CustomData
  L3_2.fCloseCallback = A1_2
  L3_2 = type
  L4_2 = A2_2
  L3_2 = L3_2(L4_2)
  if "table" == L3_2 then
    L3_2 = A0_2.CustomData
    L3_2.tCloseCallbackData = A2_2
  else
    L3_2 = A0_2.CustomData
    L3_2.tCloseCallbackData = nil
  end
  L3_2 = true
  return L3_2
end

_SetCloseCallbackWidget = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "userdata" ~= L1_2 then
    return
  end
  L1_2 = _tShopList
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    return
  end
  L1_2 = _tShopList
  L1_2 = L1_2[A0_2]
  L2_2 = L1_2
  L1_2 = L1_2.Commence
  return L1_2(L2_2)
end

Commence = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2.CustomData
  L1_2.bRunning = true
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bLoaded
  if L1_2 then
    L1_2 = _RunShop
    L2_2 = A0_2
    L1_2(L2_2)
  end
end

_CommenceWidget = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "userdata" ~= L1_2 then
    return
  end
  L1_2 = _tShopList
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    return
  end
  L1_2 = _FlashCloseShopCallback
  L2_2 = _tShopList
  L2_2 = L2_2[A0_2]
  L3_2 = nil
  L1_2(L2_2, L3_2)
end

Close = L0_1
L0_1 = false
_tShopList = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = {}
  _tShopList = L0_2
end

Init = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2.CustomData
  L1_2.bLoaded = true
  L2_2 = A0_2
  L1_2 = A0_2.Pause
  L1_2(L2_2)
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bRunning
  if L1_2 then
    L1_2 = _RunShop
    L2_2 = A0_2
    L1_2(L2_2)
  end
end

_FlashLoadedCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = sFlashFile
  if L1_2 then
    L1_2 = _SetupShopFlash
    L2_2 = A0_2
    L1_2(L2_2)
    L2_2 = A0_2
    L1_2 = A0_2.SetVisible
    L3_2 = true
    L1_2(L2_2, L3_2)
    L1_2 = MrxGuiBase
    L1_2 = L1_2.GetControlFocus
    L2_2 = A0_2
    L3_2 = true
    L1_2(L2_2, L3_2)
    L2_2 = A0_2
    L1_2 = A0_2.Play
    L1_2(L2_2)
    L1_2 = MrxGuiManager
    L1_2 = L1_2.GetHudState
    L1_2 = L1_2()
    if L1_2 then
      L1_2 = MrxGuiManager
      L1_2 = L1_2.ToggleHud
      L3_2 = A0_2
      L2_2 = A0_2.GetOwner
      L2_2 = L2_2(L3_2)
      L3_2 = false
      L1_2(L2_2, L3_2)
      L1_2 = A0_2.CustomData
      L1_2.bRestoreHud = true
    end
  else
    L1_2 = _CreateShopDialogBox
    L2_2 = A0_2
    L1_2(L2_2)
  end
end

_RunShop = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L1_2 = {}
  L2_2 = pairs
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.tItems
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = nil
    L8_2 = L6_2.bUnlocked
    if not L8_2 then
      L7_2 = ""
    else
      L8_2 = L6_2.nCashCost
      L9_2 = MrxPmc
      L9_2 = L9_2.GetCashQty
      L9_2 = L9_2()
      if L8_2 > L9_2 then
        L7_2 = "[red]"
      else
        L7_2 = "[green]"
      end
    end
    L8_2 = string
    L8_2 = L8_2.format
    L9_2 = "%s%s ($%d) (%d/%d)"
    L10_2 = L7_2
    L11_2 = L6_2.sName
    L12_2 = L6_2.nCashCost
    L13_2 = L6_2.nCurrentStock
    L14_2 = L6_2.nMaxStock
    L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
    L1_2[L5_2] = L8_2
  end
  L2_2 = #L1_2
  L2_2 = L2_2 + 1
  L1_2[L2_2] = "[Generic.Cancel]"
  L3_2 = A0_2.CustomData
  L3_2.nCancelIndex = L2_2
  L3_2 = MrxGuiDialogBox
  L3_2 = L3_2.DisplayDialogBox
  L5_2 = A0_2
  L4_2 = A0_2.GetOwner
  L4_2 = L4_2(L5_2)
  L5_2 = "[Generic.Cash]: $"
  L6_2 = MrxPmc
  L6_2 = L6_2.GetCashQty
  L6_2 = L6_2()
  L5_2 = L5_2 .. L6_2
  L6_2 = L1_2
  L7_2 = 1
  L8_2 = _CloseShopDialogBox
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
end

_CreateShopDialogBox = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nCancelIndex
  if A1_2 ~= L2_2 then
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.fCallback
    if L2_2 then
      L2_2 = A0_2.CustomData
      L2_2 = L2_2.tCallbackData
      if not L2_2 then
        L2_2 = {}
      end
      L3_2 = table
      L3_2 = L3_2.insert
      L4_2 = L2_2
      L5_2 = A0_2.CustomData
      L5_2 = L5_2.tItems
      L5_2 = L5_2[A1_2]
      L5_2 = L5_2.sName
      L3_2(L4_2, L5_2)
      L3_2 = table
      L3_2 = L3_2.insert
      L4_2 = L2_2
      L5_2 = 1
      L3_2(L4_2, L5_2)
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.fCallback
      L4_2 = unpack
      L5_2 = L2_2
      L4_2, L5_2 = L4_2(L5_2)
      L3_2(L4_2, L5_2)
    end
  end
  L3_2 = A0_2
  L2_2 = A0_2.GetOwner
  L2_2 = L2_2(L3_2)
  L4_2 = A0_2
  L3_2 = A0_2.delete
  L3_2(L4_2)
  L3_2 = _tShopList
  L3_2[L2_2] = nil
end

_CloseShopDialogBox = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2
  L2_2 = A0_2
  L1_2 = A0_2.CallActionScriptCallback
  L3_2 = "AddStockpile"
  L4_2 = {}
  L5_2 = MrxPmc
  L5_2 = L5_2.GetCashQty
  L5_2 = L5_2()
  L6_2 = MrxPmc
  L6_2 = L6_2.GetFuelQty
  L6_2 = L6_2()
  L7_2 = MrxPmc
  L7_2 = L7_2.GetFuelCapacity
  L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2 = L7_2()
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L4_2[7] = L11_2
  L4_2[8] = L12_2
  L4_2[9] = L13_2
  L4_2[10] = L14_2
  L4_2[11] = L15_2
  L4_2[12] = L16_2
  L4_2[13] = L17_2
  L4_2[14] = L18_2
  L4_2[15] = L19_2
  L4_2[16] = L20_2
  L4_2[17] = L21_2
  L4_2[18] = L22_2
  L4_2[19] = L23_2
  L4_2[20] = L24_2
  L4_2[21] = L25_2
  L4_2[22] = L26_2
  L4_2[23] = L27_2
  L4_2[24] = L28_2
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = {}
  L2_2 = 3
  L3_2 = MrxGui
  L3_2 = L3_2.GetWidgetByNameAndOwner
  L4_2 = "PDA"
  L6_2 = A0_2
  L5_2 = A0_2.GetOwner
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2 = L5_2(L6_2)
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2)
  if L3_2 then
    L4_2 = 1
    L5_2 = nil
    L6_2 = nil
    while L2_2 >= L4_2 do
      L8_2 = L3_2
      L7_2 = L3_2.GetEquippedSupport
      L9_2 = L4_2
      L7_2, L8_2 = L7_2(L8_2, L9_2)
      L6_2 = L8_2
      L5_2 = L7_2
      L7_2 = {}
      L7_2.sName = L5_2
      L7_2.sIcon = L6_2
      L8_2 = A0_2.CustomData
      L8_2 = L8_2.tItems
      L8_2 = #L8_2
      L8_2 = L8_2 + 1
      L7_2.nId = L8_2
      L7_2.sRawName = L5_2
      L1_2[L4_2] = L7_2
      L7_2 = table
      L7_2 = L7_2.insert
      L8_2 = A0_2.CustomData
      L8_2 = L8_2.tItems
      L9_2 = L1_2[L4_2]
      L7_2(L8_2, L9_2)
      L4_2 = L4_2 + 1
    end
  end
  L4_2 = pairs
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.tItems
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = MrxSupportData
    L9_2 = L9_2.tSupportData
    L10_2 = L8_2.sId
    L9_2 = L9_2[L10_2]
    L10_2 = MrxSupportData
    L10_2 = L10_2.IsSupportEquippable
    L11_2 = L8_2.sId
    L10_2 = L10_2(L11_2)
    L11_2 = " "
    if L9_2 then
      L12_2 = L9_2.oSupport
      if L12_2 then
        L12_2 = L9_2.oSupport
        L13_2 = L12_2
        L12_2 = L12_2.GetDesignator
        L12_2 = L12_2(L13_2)
        if L12_2 then
          L12_2 = L9_2.oSupport
          L13_2 = L12_2
          L12_2 = L12_2.GetDesignator
          L12_2 = L12_2(L13_2)
          L13_2 = L12_2
          L12_2 = L12_2.GetType
          L12_2 = L12_2(L13_2)
          if "smoke" == L12_2 then
            L11_2 = "[Generic.SupportDesignators.Smoke]"
          elseif "satellite" == L12_2 then
            L11_2 = "[Generic.SupportDesignators.Satellite]"
          elseif "advanced satellite" == L12_2 then
            L11_2 = "[Generic.SupportDesignators.AdvSatellite]"
          elseif "beacon" == L12_2 then
            L11_2 = "[Generic.SupportDesignators.Beacon]"
          elseif "laser" == L12_2 then
            L11_2 = "[Generic.SupportDesignators.Laser]"
          elseif "flare" == L12_2 then
            L11_2 = "[Generic.SupportDesignators.Flare]"
          end
        end
      end
    end
    L12_2 = L8_2.sDesc
    if L12_2 then
      L12_2 = L8_2.sTexture
      if L12_2 then
        L12_2 = L8_2.nCurrentStock
        if L12_2 then
          L13_2 = A0_2
          L12_2 = A0_2.CallActionScriptCallback
          L14_2 = "AddShopItem"
          L15_2 = {}
          L16_2 = L7_2
          L17_2 = L8_2.sName
          L18_2 = L8_2.sDesc
          L19_2 = L8_2.sTexture
          L20_2 = L8_2.nCurrentStock
          if not L20_2 then
            L20_2 = 0
          end
          L21_2 = L8_2.nMaxStock
          L22_2 = L8_2.nCashCost
          L23_2 = L8_2.bUnlocked
          if not L23_2 then
            L23_2 = false
          end
          L24_2 = L8_2.bFuelTank
          if not L24_2 then
            L24_2 = false
          end
          L25_2 = L8_2.bMarkAsNew
          if not L25_2 then
            L25_2 = false
          end
          L26_2 = L10_2
          L27_2 = L8_2.nFuelQuantity
          if not L27_2 then
            L27_2 = 9999
          end
          L28_2 = L11_2
          L15_2[1] = L16_2
          L15_2[2] = L17_2
          L15_2[3] = L18_2
          L15_2[4] = L19_2
          L15_2[5] = L20_2
          L15_2[6] = L21_2
          L15_2[7] = L22_2
          L15_2[8] = L23_2
          L15_2[9] = L24_2
          L15_2[10] = L25_2
          L15_2[11] = L26_2
          L15_2[12] = L27_2
          L15_2[13] = L28_2
          L12_2(L13_2, L14_2, L15_2)
      end
    end
    elseif L9_2 then
      L13_2 = A0_2
      L12_2 = A0_2.CallActionScriptCallback
      L14_2 = "AddShopItem"
      L15_2 = {}
      L16_2 = L7_2
      L17_2 = L8_2.sName
      L18_2 = L9_2.sDescription
      L19_2 = L9_2.sIcon
      L20_2 = MrxPmc
      L20_2 = L20_2.GetSupportQty
      L21_2 = L8_2.sId
      L20_2 = L20_2(L21_2)
      if not L20_2 then
        L20_2 = 0
      end
      L21_2 = L9_2.nMaxStock
      L22_2 = L8_2.nCashCost
      if not L22_2 then
        L22_2 = L9_2.nCashCost
      end
      L23_2 = L9_2.bUnlocked
      if not L23_2 then
        L23_2 = false
      end
      L24_2 = L8_2.bFuelTank
      if not L24_2 then
        L24_2 = false
      end
      L25_2 = L8_2.bMarkAsNew
      if not L25_2 then
        L25_2 = false
      end
      L26_2 = L10_2
      L27_2 = L8_2.nFuelQuantity
      if not L27_2 then
        L27_2 = 9999
      end
      L28_2 = L11_2
      L15_2[1] = L16_2
      L15_2[2] = L17_2
      L15_2[3] = L18_2
      L15_2[4] = L19_2
      L15_2[5] = L20_2
      L15_2[6] = L21_2
      L15_2[7] = L22_2
      L15_2[8] = L23_2
      L15_2[9] = L24_2
      L15_2[10] = L25_2
      L15_2[11] = L26_2
      L15_2[12] = L27_2
      L15_2[13] = L28_2
      L12_2(L13_2, L14_2, L15_2)
    end
    L12_2 = pairs
    L13_2 = L1_2
    L12_2, L13_2, L14_2 = L12_2(L13_2)
    for L15_2, L16_2 in L12_2, L13_2, L14_2 do
      L17_2 = L8_2.sRawName
      L18_2 = L16_2.sRawName
      if L17_2 == L18_2 then
        L17_2 = L8_2.sName
        L16_2.sName = L17_2
      end
    end
  end
  L4_2 = pairs
  L5_2 = L1_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = L8_2.nId
    if L9_2 then
      L9_2 = L8_2.sName
      if L9_2 then
        L10_2 = A0_2
        L9_2 = A0_2.CallActionScriptCallback
        L11_2 = "AddSupportEquipped"
        L12_2 = {}
        L13_2 = L7_2
        L14_2 = L8_2.nId
        L15_2 = L8_2.sName
        L16_2 = L8_2.sIcon
        L12_2[1] = L13_2
        L12_2[2] = L14_2
        L12_2[3] = L15_2
        L12_2[4] = L16_2
        L9_2(L10_2, L11_2, L12_2)
      end
    end
  end
  L5_2 = A0_2
  L4_2 = A0_2.SetFlashEventHandler
  L6_2 = "BuyStockpile"
  L7_2 = _FlashSupportBoughtCallback
  L8_2 = {}
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L5_2 = A0_2
  L4_2 = A0_2.SetFlashEventHandler
  L6_2 = "equip"
  L7_2 = _FlashSupportEquippedCallback
  L8_2 = {}
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L5_2 = A0_2
  L4_2 = A0_2.SetFlashEventHandler
  L6_2 = "closeStore"
  L7_2 = _FlashCloseShopCallback
  L8_2 = {}
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = MrxGui
  L4_2 = L4_2.ImageWidget
  L5_2 = L4_2
  L4_2 = L4_2.new
  L4_2 = L4_2(L5_2)
  L6_2 = L4_2
  L5_2 = L4_2.SetFullscreen
  L7_2 = true
  L5_2(L6_2, L7_2)
  L6_2 = L4_2
  L5_2 = L4_2.SetColor
  L7_2 = 0
  L8_2 = 0
  L9_2 = 0
  L10_2 = 192
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L6_2 = L4_2
  L5_2 = L4_2.SetOwner
  L8_2 = A0_2
  L7_2 = A0_2.GetOwner
  L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2 = L7_2(L8_2)
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2)
  L5_2 = A0_2.CustomData
  L5_2.oBg = L4_2
  L5_2 = MrxGui
  L5_2 = L5_2.RemoveWidget
  L6_2 = A0_2
  L5_2(L6_2)
  L5_2 = MrxGui
  L5_2 = L5_2.AddWidget
  L6_2 = L4_2
  L5_2(L6_2)
  L5_2 = MrxGui
  L5_2 = L5_2.AddWidget
  L6_2 = A0_2
  L5_2(L6_2)
end

_SetupShopFlash = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = {}
  L3_2 = 1
  L4_2 = string
  L4_2 = L4_2.gmatch
  L5_2 = A1_2
  L6_2 = "-*%d+"
  L4_2, L5_2, L6_2 = L4_2(L5_2, L6_2)
  for L7_2 in L4_2, L5_2, L6_2 do
    L8_2 = tonumber
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    L2_2[L3_2] = L8_2
    L3_2 = L3_2 + 1
  end
  L4_2 = L2_2[1]
  if L4_2 then
    L4_2 = L2_2[2]
    if L4_2 then
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.tItems
      L5_2 = L2_2[1]
      L4_2 = L4_2[L5_2]
      if L4_2 then
        L5_2 = A0_2.CustomData
        L5_2 = L5_2.fCallback
        if L5_2 then
          L5_2 = {}
          L6_2 = A0_2.CustomData
          L6_2 = L6_2.tCallbackData
          if L6_2 then
            L6_2 = pairs
            L7_2 = A0_2.CustomData
            L7_2 = L7_2.tCallbackData
            L6_2, L7_2, L8_2 = L6_2(L7_2)
            for L9_2, L10_2 in L6_2, L7_2, L8_2 do
              L5_2[L9_2] = L10_2
            end
          end
          L6_2 = table
          L6_2 = L6_2.insert
          L7_2 = L5_2
          L8_2 = L4_2.sId
          L6_2(L7_2, L8_2)
          L6_2 = table
          L6_2 = L6_2.insert
          L7_2 = L5_2
          L8_2 = L2_2[2]
          L6_2(L7_2, L8_2)
          L6_2 = A0_2.CustomData
          L6_2 = L6_2.fCallback
          L7_2 = unpack
          L8_2 = L5_2
          L7_2, L8_2, L9_2, L10_2, L11_2 = L7_2(L8_2)
          L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
        end
      end
    end
  end
end

_FlashSupportBoughtCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = _ParseString
  L3_2 = A1_2
  L2_2, L3_2 = L2_2(L3_2)
  if L3_2 and L2_2 then
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.tItems
    L4_2 = L4_2[L3_2]
    if L4_2 then
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.tItems
      L4_2 = L4_2[L3_2]
      L4_2 = L4_2.sRawName
      L5_2 = MrxGui
      L5_2 = L5_2.GetWidgetByNameAndOwner
      L6_2 = "PDA"
      L8_2 = A0_2
      L7_2 = A0_2.GetOwner
      L7_2, L8_2, L9_2 = L7_2(L8_2)
      L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
      if L5_2 and L4_2 then
        L7_2 = L5_2
        L6_2 = L5_2.SetEquippedSupport
        L8_2 = L4_2
        L9_2 = L2_2
        L6_2(L7_2, L8_2, L9_2)
      end
    end
  end
end

_FlashSupportEquippedCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = string
  L3_2 = L3_2.gmatch
  L4_2 = A0_2
  L5_2 = "(%d+)([, ]*)(%w+)"
  L3_2, L4_2, L5_2 = L3_2(L4_2, L5_2)
  for L6_2, L7_2, L8_2 in L3_2, L4_2, L5_2 do
    L9_2 = tonumber
    L10_2 = L6_2
    L9_2 = L9_2(L10_2)
    L1_2 = L9_2
    L9_2 = tonumber
    L10_2 = L8_2
    L9_2 = L9_2(L10_2)
    L2_2 = L9_2
  end
  L3_2 = type
  L4_2 = L1_2
  L3_2 = L3_2(L4_2)
  if "number" == L3_2 then
    L3_2 = type
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    if "number" == L3_2 then
      L3_2 = L1_2
      L4_2 = L2_2
      return L3_2, L4_2
    end
  end
  L3_2 = nil
  return L3_2
end

_ParseString = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.fCloseCallback
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.tCloseCallbackData
  L5_2 = A0_2
  L4_2 = A0_2.GetOwner
  L4_2 = L4_2(L5_2)
  L5_2 = _tShopList
  L5_2[L4_2] = nil
  L5_2 = MrxGuiBase
  L5_2 = L5_2.ReleaseControlFocus
  L6_2 = A0_2
  L5_2(L6_2)
  if L2_2 then
    if not L3_2 then
      L5_2 = {}
      L3_2 = L5_2
    end
    L5_2 = L2_2
    L6_2 = unpack
    L7_2 = L3_2
    L6_2, L7_2, L8_2 = L6_2(L7_2)
    L5_2(L6_2, L7_2, L8_2)
  end
  L6_2 = A0_2
  L5_2 = A0_2.CallActionScriptCallback
  L7_2 = "requestClose"
  L8_2 = {}
  L5_2(L6_2, L7_2, L8_2)
  L5_2 = _RemoveFlashFile
  L6_2 = A0_2
  L5_2(L6_2)
end

_FlashCloseShopCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bRestoreHud
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
  L1_2 = L1_2.oBg
  L3_2 = A0_2
  L2_2 = A0_2.SetSwfFile
  L4_2 = nil
  L2_2(L3_2, L4_2)
  L2_2 = MrxGui
  L2_2 = L2_2.RemoveWidget
  L3_2 = A0_2
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2.delete
  L2_2(L3_2)
  L2_2 = MrxGui
  L2_2 = L2_2.RemoveWidget
  L3_2 = L1_2
  L2_2(L3_2)
  L3_2 = L1_2
  L2_2 = L1_2.delete
  L2_2(L3_2)
end

_RemoveFlashFile = L0_1
