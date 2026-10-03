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
L0_1 = "garage"
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
  L1_2 = _tGarageList
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
  L3_2 = _tGarageList
  L3_2[A0_2] = L1_2
  L3_2 = true
  return L3_2
end

Create = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2)
  local L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L9_2 = type
  L10_2 = A0_2
  L9_2 = L9_2(L10_2)
  if "userdata" ~= L9_2 then
    L9_2 = false
    return L9_2
  end
  L9_2 = _tGarageList
  L9_2 = L9_2[A0_2]
  if not L9_2 then
    L9_2 = false
    return L9_2
  end
  L9_2 = _tGarageList
  L9_2 = L9_2[A0_2]
  L10_2 = L9_2
  L9_2 = L9_2.AddItem
  L11_2 = A1_2
  L12_2 = A2_2
  L13_2 = A3_2
  L14_2 = A4_2
  L15_2 = A5_2
  L16_2 = A6_2
  L17_2 = A7_2
  L18_2 = A8_2
  return L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
end

AddItem = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2)
  local L9_2, L10_2, L11_2, L12_2
  L9_2 = type
  L10_2 = A2_2
  L9_2 = L9_2(L10_2)
  if "string" == L9_2 then
    L9_2 = type
    L10_2 = A3_2
    L9_2 = L9_2(L10_2)
    if "string" == L9_2 then
      goto lbl_13
    end
  end
  L9_2 = false
  do return L9_2 end
  ::lbl_13::
  L9_2 = type
  L10_2 = A5_2
  L9_2 = L9_2(L10_2)
  if "number" == L9_2 then
    L9_2 = type
    L10_2 = A6_2
    L9_2 = L9_2(L10_2)
    if "number" == L9_2 then
      goto lbl_25
    end
  end
  L9_2 = false
  do return L9_2 end
  ::lbl_25::
  L9_2 = type
  L10_2 = A4_2
  L9_2 = L9_2(L10_2)
  if "string" == L9_2 then
    L9_2 = string
    L9_2 = L9_2.lower
    L10_2 = A4_2
    L9_2 = L9_2(L10_2)
    A4_2 = L9_2
  end
  L9_2 = {}
  L9_2.sId = A1_2
  L9_2.sName = A2_2
  L9_2.sDescription = A3_2
  L9_2.sType = A4_2
  L9_2.nCurrentStock = A5_2
  L9_2.nMaxStock = A6_2
  L9_2.sIcon = A7_2
  L9_2.bNew = A8_2
  L10_2 = table
  L10_2 = L10_2.insert
  L11_2 = A0_2.CustomData
  L11_2 = L11_2.tItems
  L12_2 = L9_2
  L10_2(L11_2, L12_2)
  L10_2 = true
  return L10_2
end

_AddItemWidget = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = type
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if "userdata" ~= L3_2 then
    L3_2 = false
    return L3_2
  end
  L3_2 = _tGarageList
  L3_2 = L3_2[A0_2]
  if not L3_2 then
    L3_2 = false
    return L3_2
  end
  L3_2 = _tGarageList
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

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "userdata" ~= L1_2 then
    return
  end
  L1_2 = _tGarageList
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    return
  end
  L1_2 = _tGarageList
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
    L1_2 = _RunGarage
    L2_2 = A0_2
    L1_2(L2_2)
  end
end

_CommenceWidget = L0_1
L0_1 = false
_tGarageList = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = {}
  _tGarageList = L0_2
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
    L1_2 = _RunGarage
    L2_2 = A0_2
    L1_2(L2_2)
  end
end

_FlashLoadedCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = sFlashFile
  if L1_2 then
    L1_2 = _SetupGarageFlash
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
  end
end

_RunGarage = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
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
  L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2 = L7_2()
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
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = nil
  L2_2 = pairs
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.tItems
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = L6_2.sType
    if "light" == L7_2 then
      L1_2 = "AddSupportLight"
    else
      L7_2 = L6_2.sType
      if "heavy" == L7_2 then
        L1_2 = "AddSupportHeavy"
      else
        L7_2 = L6_2.sType
        if "helicopters" == L7_2 then
          L1_2 = "AddSupportHelicopters"
        else
          L7_2 = L6_2.sType
          if "boats" == L7_2 then
            L1_2 = "AddSupportBoats"
          else
            L1_2 = "AddSupportCivilian"
          end
        end
      end
    end
    L8_2 = A0_2
    L7_2 = A0_2.CallActionScriptCallback
    L9_2 = L1_2
    L10_2 = {}
    L11_2 = L6_2.sId
    L12_2 = L6_2.sName
    L13_2 = L6_2.sDescription
    L14_2 = L6_2.sIcon
    L15_2 = L6_2.nCurrentStock
    L16_2 = L6_2.nMaxStock
    L17_2 = 0
    L18_2 = L6_2.bNew
    if not L18_2 then
      L18_2 = false
    end
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L10_2[3] = L13_2
    L10_2[4] = L14_2
    L10_2[5] = L15_2
    L10_2[6] = L16_2
    L10_2[7] = L17_2
    L10_2[8] = L18_2
    L7_2(L8_2, L9_2, L10_2)
  end
  L3_2 = A0_2
  L2_2 = A0_2.SetFlashEventHandler
  L4_2 = "vehicleSelect"
  L5_2 = _EndCallback
  L6_2 = {}
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L3_2 = A0_2
  L2_2 = A0_2.SetFlashEventHandler
  L4_2 = "closePDA"
  L5_2 = _CloseCallback
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = MrxGui
  L2_2 = L2_2.ImageWidget
  L3_2 = L2_2
  L2_2 = L2_2.new
  L2_2 = L2_2(L3_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetFullscreen
  L5_2 = true
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetColor
  L5_2 = 0
  L6_2 = 0
  L7_2 = 0
  L8_2 = 192
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetOwner
  L6_2 = A0_2
  L5_2 = A0_2.GetOwner
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2 = L5_2(L6_2)
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  L3_2 = A0_2.CustomData
  L3_2.oBg = L2_2
  L3_2 = MrxGui
  L3_2 = L3_2.RemoveWidget
  L4_2 = A0_2
  L3_2(L4_2)
  L3_2 = MrxGui
  L3_2 = L3_2.AddWidget
  L4_2 = L2_2
  L3_2(L4_2)
  L3_2 = MrxGui
  L3_2 = L3_2.AddWidget
  L4_2 = A0_2
  L3_2(L4_2)
end

_SetupGarageFlash = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = A0_2
  L2_2 = A0_2.GetOwner
  L2_2 = L2_2(L3_2)
  L3_2 = _tGarageList
  L3_2[L2_2] = nil
  L3_2 = MrxGuiBase
  L3_2 = L3_2.ReleaseControlFocus
  L4_2 = A0_2
  L3_2(L4_2)
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 0.1
  L7_2 = true
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = _RemoveFlashFile
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.fCallback
  if L3_2 then
    L3_2 = {}
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.tCallbackData
    if L4_2 then
      L4_2 = pairs
      L5_2 = A0_2.CustomData
      L5_2 = L5_2.tCallbackData
      L4_2, L5_2, L6_2 = L4_2(L5_2)
      for L7_2, L8_2 in L4_2, L5_2, L6_2 do
        L3_2[L7_2] = L8_2
      end
    end
    if A1_2 then
      L4_2 = table
      L4_2 = L4_2.insert
      L5_2 = L3_2
      L6_2 = A1_2
      L4_2(L5_2, L6_2)
    end
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.fCallback
    L5_2 = unpack
    L6_2 = L3_2
    L5_2, L6_2, L7_2, L8_2, L9_2 = L5_2(L6_2)
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  end
end

_EndCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = _EndCallback
  L2_2 = A0_2
  L3_2 = nil
  L1_2(L2_2, L3_2)
end

_CloseCallback = L0_1

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
