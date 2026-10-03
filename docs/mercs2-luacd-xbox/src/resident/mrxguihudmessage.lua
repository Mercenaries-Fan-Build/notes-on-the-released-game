local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiBase"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxHqManager"
L0_1(L1_1)
L0_1 = 256
nGlobalWidth = L0_1
L0_1 = 128
nGlobalHeight = L0_1
L0_1 = 320
nX = L0_1
L0_1 = 340
nY = L0_1
L0_1 = 5
nMagnification = L0_1
L0_1 = 0.1
nAnimationTimeLength = L0_1
L0_1 = 3
nLifeTime = L0_1
L0_1 = 1
nFadeTime = L0_1
L0_1 = false
_gFanfareFlashWidget = L0_1
L0_1 = false
_gFullscreenFadeWidget = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = _gFanfareFlashWidget
  if L2_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = nil
  if not A0_2 then
    A0_2 = "contract"
  end
  L3_2 = "fanfare_contract"
  L4_2 = _LoadCompleteCallback
  if "mission" == A0_2 then
    L3_2 = "fanfare_mission"
  elseif "wager" == A0_2 then
    L3_2 = "fanfare_wager"
  elseif "support" == A0_2 then
    L3_2 = "fanfare_support_unlocked"
    L4_2 = _SupportLoadCompleteCallback
  elseif "contact" == A0_2 then
    L3_2 = "fanfare_new_contact"
    L4_2 = _ContactLoadCompleteCallback
  elseif "card" == A0_2 then
    L5_2 = type
    L6_2 = A1_2
    L5_2 = L5_2(L6_2)
    if "string" == L5_2 then
      L5_2 = string
      L5_2 = L5_2.lower
      L6_2 = A1_2
      L5_2 = L5_2(L6_2)
      L2_2 = L5_2
      if "an" == L2_2 or "ch" == L2_2 or "oc" == L2_2 or "gr" == L2_2 or "pr" == L2_2 then
        L5_2 = "fanfare_new_contact_"
        L6_2 = A1_2
        L7_2 = "_businesscard"
        L3_2 = L5_2 .. L6_2 .. L7_2
        L4_2 = _CardLoadCompleteCallback
      else
        L5_2 = false
        return L5_2
      end
    end
  end
  L5_2 = MrxGui
  L5_2 = L5_2.FlashWidget
  L6_2 = L5_2
  L5_2 = L5_2.new
  L5_2 = L5_2(L6_2)
  _gFanfareFlashWidget = L5_2
  L5_2 = _gFanfareFlashWidget
  L6_2 = L5_2
  L5_2 = L5_2.SetFullscreen
  L7_2 = true
  L5_2(L6_2, L7_2)
  L5_2 = _gFanfareFlashWidget
  L5_2 = L5_2.CustomData
  L5_2.sFaction = L2_2
  L5_2 = _GuiInternal
  L5_2 = L5_2.GetWidgetViewport
  L6_2 = _gFanfareFlashWidget
  L6_2 = L6_2.BasicData
  L6_2 = L6_2.uId
  L5_2 = L5_2(L6_2)
  L6_2 = _gFanfareFlashWidget
  L7_2 = L6_2
  L6_2 = L6_2.SetOwner
  L8_2 = Player
  L8_2 = L8_2.GetLocalPlayer
  L8_2, L9_2, L10_2, L11_2 = L8_2()
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  L6_2 = _gFanfareFlashWidget
  L6_2 = L6_2.CustomData
  L7_2 = _gFanfareFlashWidget
  L7_2 = L7_2.EventHandlers
  L7_2 = L7_2.ControllerInput
  L6_2.HandleFlashInput = L7_2
  L6_2 = _gFanfareFlashWidget
  L7_2 = L6_2
  L6_2 = L6_2.SetEventHandler
  L8_2 = "ControllerInput"
  L9_2 = _HandleFanfareInput
  L6_2(L7_2, L8_2, L9_2)
  L6_2 = _GuiInternal
  L6_2 = L6_2.SetWidgetViewport
  L7_2 = _gFanfareFlashWidget
  L7_2 = L7_2.BasicData
  L7_2 = L7_2.uId
  L8_2 = L5_2
  L6_2(L7_2, L8_2)
  L6_2 = _gFanfareFlashWidget
  L6_2 = L6_2.CustomData
  L6_2.bLoadingComplete = false
  L6_2 = _gFanfareFlashWidget
  L6_2 = L6_2.CustomData
  L6_2.bReadyToStart = false
  L6_2 = _gFanfareFlashWidget
  L7_2 = L6_2
  L6_2 = L6_2.SetVisible
  L8_2 = false
  L6_2(L7_2, L8_2)
  L6_2 = _gFanfareFlashWidget
  L7_2 = L6_2
  L6_2 = L6_2.SetSwfFile
  L8_2 = L3_2
  L9_2 = L4_2
  L10_2 = {}
  L11_2 = _gFanfareFlashWidget
  L10_2[1] = L11_2
  L6_2(L7_2, L8_2, L9_2, L10_2)
  L6_2 = _gFanfareFlashWidget
  L7_2 = L6_2
  L6_2 = L6_2.Pause
  L6_2(L7_2)
  L6_2 = _gFanfareFlashWidget
  L6_2 = L6_2.CustomData
  L6_2.sType = A0_2
  L6_2 = MrxGui
  L6_2 = L6_2.AddWidget
  L7_2 = _gFanfareFlashWidget
  L6_2(L7_2)
  if "contract" == A0_2 or "mission" == A0_2 or "wager" == A0_2 then
    L6_2 = MrxGui
    L6_2 = L6_2.ImageWidget
    L7_2 = L6_2
    L6_2 = L6_2.new
    L6_2 = L6_2(L7_2)
    _gFullscreenFadeWidget = L6_2
    L6_2 = _gFullscreenFadeWidget
    L7_2 = L6_2
    L6_2 = L6_2.SetColor
    L8_2 = 0
    L9_2 = 0
    L10_2 = 0
    L11_2 = 0
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
    L6_2 = _gFullscreenFadeWidget
    L7_2 = L6_2
    L6_2 = L6_2.SetFullscreen
    L8_2 = true
    L6_2(L7_2, L8_2)
    L6_2 = _gFullscreenFadeWidget
    L6_2 = L6_2.CustomData
    L6_2.nAlpha = 0
  end
  L6_2 = true
  return L6_2
end

CreateFanfare = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _gFanfareFlashWidget
  if not L2_2 then
    L2_2 = false
    return L2_2
  end
  if nil == A0_2 then
    L2_2 = _gFanfareFlashWidget
    L2_2 = L2_2.CustomData
    L2_2.fCallback = nil
    L2_2 = _gFanfareFlashWidget
    L2_2 = L2_2.CustomData
    L3_2 = {}
    L2_2.tCallbackData = L3_2
    L2_2 = true
    return L2_2
  end
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "function" ~= L2_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = A1_2
  L3_2 = type
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if "table" ~= L3_2 then
    L3_2 = {}
    L2_2 = L3_2
  end
  L3_2 = _gFanfareFlashWidget
  L3_2 = L3_2.CustomData
  L3_2.fCallback = A0_2
  L3_2 = _gFanfareFlashWidget
  L3_2 = L3_2.CustomData
  L3_2.tCallbackData = L2_2
  L3_2 = true
  return L3_2
end

SetFanfareCompleteCallback = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2
  L5_2 = _gFanfareFlashWidget
  if not L5_2 then
    L5_2 = false
    return L5_2
  end
  L5_2 = _gFanfareFlashWidget
  L5_2 = L5_2.CustomData
  L5_2 = L5_2.sType
  if "support" ~= L5_2 then
    L5_2 = false
    return L5_2
  end
  L5_2 = type
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  if "string" ~= L5_2 then
    L5_2 = false
    return L5_2
  end
  L5_2 = type
  L6_2 = A1_2
  L5_2 = L5_2(L6_2)
  if "string" ~= L5_2 then
    L5_2 = false
    return L5_2
  end
  L5_2 = type
  L6_2 = A2_2
  L5_2 = L5_2(L6_2)
  if "string" ~= L5_2 then
    L5_2 = false
    return L5_2
  end
  L5_2 = type
  L6_2 = A3_2
  L5_2 = L5_2(L6_2)
  if "string" ~= L5_2 then
    L5_2 = false
    return L5_2
  end
  L5_2 = _gFanfareFlashWidget
  L5_2 = L5_2.CustomData
  L5_2 = L5_2.tItemList
  if not L5_2 then
    L5_2 = _gFanfareFlashWidget
    L5_2 = L5_2.CustomData
    L6_2 = {}
    L5_2.tItemList = L6_2
  end
  L5_2 = {}
  L5_2.sTexture = A0_2
  L5_2.sItemName = A1_2
  L5_2.sFaction = A2_2
  L5_2.sContactName = A3_2
  L5_2.sBlipName = A4_2
  L6_2 = table
  L6_2 = L6_2.insert
  L7_2 = _gFanfareFlashWidget
  L7_2 = L7_2.CustomData
  L7_2 = L7_2.tItemList
  L8_2 = L5_2
  L6_2(L7_2, L8_2)
  L6_2 = true
  return L6_2
end

SupportFanfareAddItem = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _gFanfareFlashWidget
  if not L0_2 then
    L0_2 = false
    return L0_2
  end
  L0_2 = _gFanfareFlashWidget
  L0_2 = L0_2.CustomData
  L0_2 = L0_2.sType
  if "support" ~= L0_2 then
    L0_2 = false
    return L0_2
  end
  L0_2 = _gFanfareFlashWidget
  L0_2 = L0_2.CustomData
  L0_2.bReadyToStart = true
  L0_2 = _gFanfareFlashWidget
  L0_2 = L0_2.CustomData
  L0_2 = L0_2.bLoadingComplete
  if L0_2 then
    L0_2 = _BeginSupportFanfare
    L1_2 = _gFanfareFlashWidget
    L0_2(L1_2)
  end
  L0_2 = true
  return L0_2
end

SupportFanfareCommence = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2.CustomData
  L1_2.bLoadingComplete = true
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bReadyToStart
  if L1_2 then
    L1_2 = _BeginSupportFanfare
    L2_2 = A0_2
    L1_2(L2_2)
  end
end

_SupportLoadCompleteCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2
  L1_2 = A0_2.SetVisible
  L3_2 = true
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.Play
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 3
  L3_2[1] = L4_2
  L4_2 = _ScrollOutFanfare
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

_BeginSupportFanfare = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2
  L1_2 = A0_2.CallActionScriptCallback
  L3_2 = "Continue"
  L4_2 = {}
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 1
  L3_2[1] = L4_2
  L4_2 = _DeleteFanfareWidget
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

_ScrollOutFanfare = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  L3_2 = _gFanfareFlashWidget
  if not L3_2 then
    L3_2 = false
    return L3_2
  end
  L3_2 = _gFanfareFlashWidget
  L3_2 = L3_2.CustomData
  L3_2 = L3_2.sType
  if "contact" ~= L3_2 then
    L3_2 = false
    return L3_2
  end
  L3_2 = type
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if "string" ~= L3_2 then
    L3_2 = false
    return L3_2
  end
  L3_2 = type
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if "string" ~= L3_2 then
    L3_2 = false
    return L3_2
  end
  L3_2 = type
  L4_2 = A2_2
  L3_2 = L3_2(L4_2)
  if "string" ~= L3_2 then
    L3_2 = false
    return L3_2
  end
  L3_2 = _gFanfareFlashWidget
  L3_2 = L3_2.CustomData
  L3_2.sTexture = A0_2
  L3_2 = _gFanfareFlashWidget
  L3_2 = L3_2.CustomData
  L3_2.sContactName = A1_2
  L3_2 = _gFanfareFlashWidget
  L3_2 = L3_2.CustomData
  L3_2.sFaction = A2_2
  L3_2 = _gFanfareFlashWidget
  L3_2 = L3_2.CustomData
  L3_2.bReadyToStart = true
  L3_2 = _gFanfareFlashWidget
  L3_2 = L3_2.CustomData
  L3_2 = L3_2.bLoadingComplete
  if L3_2 then
    L3_2 = _BeginContactFanfare
    L4_2 = _gFanfareFlashWidget
    L3_2(L4_2)
  end
  L3_2 = true
  return L3_2
end

ContactFanfareCommence = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2.CustomData
  L1_2.bLoadingComplete = true
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bReadyToStart
  if L1_2 then
    L1_2 = _BeginContactFanfare
    L2_2 = A0_2
    L1_2(L2_2)
  end
end

_ContactLoadCompleteCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2
  L1_2 = A0_2.SetVisible
  L3_2 = true
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.Play
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 3
  L3_2[1] = L4_2
  L4_2 = _ScrollOutFanfare
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

_BeginContactFanfare = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2)
  local L7_2, L8_2, L9_2
  L7_2 = _gFanfareFlashWidget
  L8_2 = _gFanfareFlashWidget
  if not L8_2 then
    L8_2 = false
    return L8_2
  end
  L8_2 = L7_2.CustomData
  L8_2.sTitle = A0_2
  L8_2 = L7_2.CustomData
  L8_2.sName = A1_2
  L8_2 = L7_2.CustomData
  L8_2.sJobTitle = A2_2
  L8_2 = L7_2.CustomData
  L8_2.sPhone1 = A3_2
  L8_2 = L7_2.CustomData
  L8_2.sPhone2 = A4_2
  L8_2 = L7_2.CustomData
  L8_2.sEmail = A5_2
  L8_2 = type
  L9_2 = A6_2
  L8_2 = L8_2(L9_2)
  if "number" == L8_2 then
    L8_2 = L7_2.CustomData
    L8_2.nDisplayTime = A6_2
  else
    L8_2 = L7_2.CustomData
    L8_2.nDisplayTime = 3
  end
  if A0_2 and A1_2 and A2_2 and A3_2 and A4_2 and A5_2 then
    L8_2 = L7_2.CustomData
    L8_2.bCardReady = true
  end
  L8_2 = true
  return L8_2
end

CardFanfareSetParameters = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = _gFanfareFlashWidget
  if not L0_2 then
    L0_2 = false
    return L0_2
  end
  L0_2 = _gFanfareFlashWidget
  L0_2 = L0_2.CustomData
  L0_2 = L0_2.sType
  if "card" ~= L0_2 then
    L0_2 = false
    return L0_2
  end
  L0_2 = _gFanfareFlashWidget
  L0_2 = L0_2.CustomData
  L0_2 = L0_2.bCardReady
  if not L0_2 then
    L0_2 = false
    return L0_2
  end
  L0_2 = _gFanfareFlashWidget
  L0_2 = L0_2.CustomData
  L0_2.bReadyToStart = true
  L0_2 = _gFanfareFlashWidget
  L0_2 = L0_2.CustomData
  L0_2 = L0_2.bLoadingComplete
  if L0_2 then
    L0_2 = _BeginCardFanfare
    L1_2 = _gFanfareFlashWidget
    L0_2(L1_2)
  end
  L0_2 = Net
  L0_2 = L0_2.IsServer
  L0_2 = L0_2()
  if L0_2 then
    L0_2 = Net
    L0_2 = L0_2.SendEvent_CardFanfare
    L1_2 = _gFanfareFlashWidget
    L1_2 = L1_2.CustomData
    L1_2 = L1_2.sFaction
    L2_2 = _gFanfareFlashWidget
    L2_2 = L2_2.CustomData
    L2_2 = L2_2.sTitle
    L3_2 = _gFanfareFlashWidget
    L3_2 = L3_2.CustomData
    L3_2 = L3_2.sName
    L4_2 = _gFanfareFlashWidget
    L4_2 = L4_2.CustomData
    L4_2 = L4_2.sJobTitle
    L5_2 = _gFanfareFlashWidget
    L5_2 = L5_2.CustomData
    L5_2 = L5_2.sPhone1
    L6_2 = _gFanfareFlashWidget
    L6_2 = L6_2.CustomData
    L6_2 = L6_2.sPhone2
    L7_2 = _gFanfareFlashWidget
    L7_2 = L7_2.CustomData
    L7_2 = L7_2.sEmail
    L8_2 = _gFanfareFlashWidget
    L8_2 = L8_2.CustomData
    L8_2 = L8_2.nDisplayTime
    L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  end
  L0_2 = true
  return L0_2
end

CardFanfareCommence = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2.CustomData
  L1_2.bLoadingComplete = true
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bReadyToStart
  if L1_2 then
    L1_2 = _BeginCardFanfare
    L2_2 = A0_2
    L1_2(L2_2)
  end
end

_CardLoadCompleteCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2
  L1_2 = A0_2.SetVisible
  L3_2 = true
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.Play
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.CallActionScriptCallback
  L3_2 = "Start"
  L4_2 = {}
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.sTitle
  L6_2 = A0_2.CustomData
  L6_2 = L6_2.sName
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.sJobTitle
  L8_2 = A0_2.CustomData
  L8_2 = L8_2.sPhone1
  L9_2 = A0_2.CustomData
  L9_2 = L9_2.sPhone2
  L10_2 = A0_2.CustomData
  L10_2 = L10_2.sEmail
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L1_2(L2_2, L3_2, L4_2)
  L2_2 = A0_2
  L1_2 = A0_2.SetFlashEventHandler
  L3_2 = "FanfareOff"
  L4_2 = _CleanupCardFanfare
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 1
  L3_2[1] = L4_2
  L4_2 = _ContinueCardFanfare
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

_BeginCardFanfare = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2
  L1_2 = A0_2.CallActionScriptCallback
  L3_2 = "Continue"
  L4_2 = {}
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nDisplayTime
  if not L4_2 then
    L4_2 = 3
  end
  L3_2[1] = L4_2
  L4_2 = _EndCardFanfare
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

_ContinueCardFanfare = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2.CallActionScriptCallback
  L3_2 = "End"
  L4_2 = {}
  L1_2(L2_2, L3_2, L4_2)
end

_EndCardFanfare = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 0.1
  L3_2[1] = L4_2
  L4_2 = _DeleteFanfareWidget
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

_CleanupCardFanfare = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2
  L4_2 = _gFanfareFlashWidget
  if not L4_2 then
    L4_2 = false
    return L4_2
  end
  L4_2 = _gFanfareFlashWidget
  L4_2 = L4_2.CustomData
  L4_2 = L4_2.sType
  if "contract" ~= L4_2 then
    L4_2 = _gFanfareFlashWidget
    L4_2 = L4_2.CustomData
    L4_2 = L4_2.sType
    if "mission" ~= L4_2 then
      L4_2 = _gFanfareFlashWidget
      L4_2 = L4_2.CustomData
      L4_2 = L4_2.sType
      if "wager" ~= L4_2 then
        L4_2 = false
        return L4_2
      end
    end
  end
  L4_2 = type
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if "string" ~= L4_2 then
    L4_2 = false
    return L4_2
  end
  L4_2 = _gFanfareFlashWidget
  L4_2 = L4_2.CustomData
  L4_2 = L4_2.sType
  if "mission" == L4_2 then
    A1_2 = nil
  end
  L4_2 = _gFanfareFlashWidget
  L4_2 = L4_2.CustomData
  L4_2.sProfileName1 = A0_2
  L4_2 = _gFanfareFlashWidget
  L4_2 = L4_2.CustomData
  L4_2.sProfileName2 = A1_2
  L4_2 = _gFanfareFlashWidget
  L4_2 = L4_2.CustomData
  L4_2.bAllowRetry = A3_2
  L4_2 = type
  L5_2 = A2_2
  L4_2 = L4_2(L5_2)
  if "string" == L4_2 then
    L4_2 = _gFanfareFlashWidget
    L4_2 = L4_2.CustomData
    L4_2.sCancelMsg = A2_2
  end
  L4_2 = true
  return L4_2
end

SetFanfareParameters = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2
  L4_2 = _gFanfareFlashWidget
  if not L4_2 then
    L4_2 = false
    return L4_2
  end
  L4_2 = _gFanfareFlashWidget
  L4_2 = L4_2.CustomData
  L4_2 = L4_2.sType
  if "contract" ~= L4_2 then
    L4_2 = _gFanfareFlashWidget
    L4_2 = L4_2.CustomData
    L4_2 = L4_2.sType
    if "wager" ~= L4_2 then
      L4_2 = false
      return L4_2
    end
  end
  L4_2 = type
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if "string" ~= L4_2 then
    L4_2 = false
    return L4_2
  end
  L4_2 = type
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  if "number" ~= L4_2 then
    L4_2 = false
    return L4_2
  end
  L4_2 = type
  L5_2 = A3_2
  L4_2 = L4_2(L5_2)
  if "number" ~= L4_2 then
    A3_2 = 1
  end
  L4_2 = _gFanfareFlashWidget
  L4_2 = L4_2.CustomData
  L4_2 = L4_2.sCancelMsg
  if L4_2 then
    L4_2 = false
    return L4_2
  end
  L4_2 = _gFanfareFlashWidget
  L4_2 = L4_2.CustomData
  L4_2 = L4_2.tLineList
  if not L4_2 then
    L4_2 = _gFanfareFlashWidget
    L4_2 = L4_2.CustomData
    L5_2 = {}
    L4_2.tLineList = L5_2
  end
  L4_2 = {}
  L4_2.sDescription = A0_2
  L4_2.nValue = A1_2
  L4_2.sType = A2_2
  L4_2.nPlayer = A3_2
  L5_2 = table
  L5_2 = L5_2.insert
  L6_2 = _gFanfareFlashWidget
  L6_2 = L6_2.CustomData
  L6_2 = L6_2.tLineList
  L7_2 = L4_2
  L5_2(L6_2, L7_2)
  L5_2 = true
  return L5_2
end

AddFanfareLineItem = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = _gFanfareFlashWidget
  if not L1_2 then
    L1_2 = false
    return L1_2
  end
  L1_2 = _gFanfareFlashWidget
  L1_2 = L1_2.CustomData
  L1_2 = L1_2.sType
  if "contract" ~= L1_2 then
    L1_2 = _gFanfareFlashWidget
    L1_2 = L1_2.CustomData
    L1_2 = L1_2.sType
    if "wager" ~= L1_2 then
      goto lbl_29
    end
  end
  L1_2 = _gFanfareFlashWidget
  L1_2 = L1_2.CustomData
  L1_2 = L1_2.sCancelMsg
  if not L1_2 then
    L1_2 = _gFanfareFlashWidget
    L1_2 = L1_2.CustomData
    L1_2 = L1_2.tLineList
    if not L1_2 then
      L1_2 = false
      do return L1_2 end
      goto lbl_37
      ::lbl_29::
      L1_2 = _gFanfareFlashWidget
      L1_2 = L1_2.CustomData
      L1_2 = L1_2.sType
      if "mission" == L1_2 then
      else
        L1_2 = false
        return L1_2
      end
    end
  end
  ::lbl_37::
  L1_2 = MrxHqManager
  L1_2 = L1_2.LockAllHq
  L1_2()
  L1_2 = Net
  L1_2 = L1_2.IsServer
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = Net
    L1_2 = L1_2.SendEvent_Fanfare
    L2_2 = _gFanfareFlashWidget
    L2_2 = L2_2.CustomData
    L2_2 = L2_2.sType
    L3_2 = ""
    L4_2 = ""
    L5_2 = ""
    L6_2 = _gFanfareFlashWidget
    L6_2 = L6_2.CustomData
    L6_2 = L6_2.sCancelMsg
    if not L6_2 then
      L6_2 = ""
    end
    L7_2 = _gFanfareFlashWidget
    L7_2 = L7_2.CustomData
    L7_2 = L7_2.tLineList
    if not L7_2 then
      L7_2 = {}
    end
    L8_2 = A0_2 or L8_2
    if not A0_2 then
      L8_2 = 2
    end
    L9_2 = 0
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  end
  if not A0_2 then
    A0_2 = 2
  end
  L1_2 = _gFanfareFlashWidget
  L1_2 = L1_2.CustomData
  L2_2 = 1 / A0_2
  L1_2.nDilationSpeed = L2_2
  L1_2 = _gFanfareFlashWidget
  L1_2 = L1_2.CustomData
  L1_2.nPrevTimeScale = 1
  L1_2 = MrxGui
  L1_2 = L1_2.AddWidget
  L2_2 = _gFanfareFlashWidget
  L1_2(L2_2)
  L1_2 = _gFanfareFlashWidget
  L2_2 = L1_2
  L1_2 = L1_2.SetEventHandler
  L3_2 = "GuiUpdate"
  L4_2 = _SlowdownUpdate
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = MrxGui
  L1_2 = L1_2.AddWidget
  L2_2 = _gFullscreenFadeWidget
  L1_2(L2_2)
  L1_2 = MrxGuiManager
  L1_2 = L1_2.GetHudState
  L2_2 = Player
  L2_2 = L2_2.GetLocalPlayer
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L2_2()
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  L2_2 = _gFanfareFlashWidget
  L2_2 = L2_2.CustomData
  L2_2.bHudState = L1_2
  if L1_2 then
    L2_2 = MrxGuiManager
    L2_2 = L2_2.ToggleHud
    L3_2 = Player
    L3_2 = L3_2.GetLocalPlayer
    L3_2 = L3_2()
    L4_2 = false
    L2_2(L3_2, L4_2)
  end
  L2_2 = MrxGui
  L2_2 = L2_2.GetWidgetByName
  L3_2 = "Pause Layout"
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L4_2 = L2_2
    L3_2 = L2_2.SetUserSaveEnabled
    L5_2 = false
    L3_2(L4_2, L5_2)
  end
  L3_2 = _gFanfareFlashWidget
  L3_2 = L3_2.CustomData
  L3_2 = L3_2.bSuppressedPda
  if not L3_2 then
    L3_2 = _gFanfareFlashWidget
    L3_2 = L3_2.CustomData
    L3_2.bSuppressedPda = true
    L3_2 = Pda
    L4_2 = L3_2
    L3_2 = L3_2.SetSuppressed
    L5_2 = {}
    L5_2.vPlayer = nil
    L5_2.bSuppress = true
    L3_2(L4_2, L5_2)
  end
  L3_2 = Player
  L3_2 = L3_2.SetScopeEnabled
  if L3_2 then
    L3_2 = Player
    L3_2 = L3_2.GetLocalPlayer
    L3_2 = L3_2()
    if L3_2 then
      L3_2 = Player
      L3_2 = L3_2.SetScopeEnabled
      L4_2 = Player
      L4_2 = L4_2.GetLocalPlayer
      L4_2 = L4_2()
      L5_2 = false
      L3_2(L4_2, L5_2)
    end
  end
  L3_2 = true
  return L3_2
end

CommenceFanfare = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = _gFanfareFlashWidget
  if not L0_2 then
    L0_2 = false
    return L0_2
  end
  L0_2 = _gFanfareFlashWidget
  L1_2 = L0_2
  L0_2 = L0_2.CallActionScriptCallback
  L2_2 = "soundMoneyGainStop"
  L3_2 = {}
  L0_2(L1_2, L2_2, L3_2)
  L0_2 = _gFanfareFlashWidget
  L1_2 = L0_2
  L0_2 = L0_2.CallActionScriptCallback
  L2_2 = "soundMoneyLoseStop"
  L3_2 = {}
  L0_2(L1_2, L2_2, L3_2)
  L0_2 = _gFanfareFlashWidget
  L1_2 = L0_2
  L0_2 = L0_2.CallActionScriptCallback
  L2_2 = "CloseFanfare"
  L3_2 = {}
  L0_2(L1_2, L2_2, L3_2)
  L0_2 = _EndFanfare
  L1_2 = _gFanfareFlashWidget
  L2_2 = "false"
  L0_2(L1_2, L2_2)
end

NetClientCloseFanfare = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = _gFanfareFlashWidget
  L2_2 = L2_2.CustomData
  L2_2 = L2_2.nDilationSpeed
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nPrevTimeScale
  L4_2 = L2_2 * A1_2
  L3_2 = L3_2 - L4_2
  if L3_2 <= 0 then
    L3_2 = 0
    L4_2 = _BeginFanfareFlash
    L5_2 = A0_2
    L4_2(L5_2)
    L5_2 = A0_2
    L4_2 = A0_2.SetEventHandler
    L6_2 = "GuiUpdate"
    L7_2 = nil
    L4_2(L5_2, L6_2, L7_2)
  end
  L4_2 = A0_2.CustomData
  L4_2.nPrevTimeScale = L3_2
  L4_2 = 192
  L5_2 = _gFullscreenFadeWidget
  L5_2 = L5_2.CustomData
  L6_2 = _gFullscreenFadeWidget
  L6_2 = L6_2.CustomData
  L6_2 = L6_2.nAlpha
  L7_2 = A1_2 * L2_2
  L7_2 = L7_2 * L4_2
  L6_2 = L6_2 + L7_2
  L5_2.nAlpha = L6_2
  L5_2 = _gFullscreenFadeWidget
  L5_2 = L5_2.CustomData
  L5_2 = L5_2.nAlpha
  if L4_2 < L5_2 then
    L5_2 = _gFullscreenFadeWidget
    L5_2 = L5_2.CustomData
    L5_2.nAlpha = L4_2
  end
  L5_2 = _gFullscreenFadeWidget
  L6_2 = L5_2
  L5_2 = L5_2.SetColor
  L7_2 = 0
  L8_2 = 0
  L9_2 = 0
  L10_2 = _gFullscreenFadeWidget
  L10_2 = L10_2.CustomData
  L10_2 = L10_2.nAlpha
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
end

_SlowdownUpdate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2.CustomData
  L1_2.bLoadingComplete = true
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bReadyToStart
  if L1_2 then
    L1_2 = _BeginFanfareFlash
    L2_2 = A0_2
    L1_2(L2_2)
  end
end

_LoadCompleteCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bLoadingComplete
  if L1_2 then
    L1_2 = MrxGuiBase
    L1_2 = L1_2.GetWidgetByName
    L2_2 = "Pause Layout"
    L1_2 = L1_2(L2_2)
    oPauseScreen = L1_2
    L1_2 = oPauseScreen
    if L1_2 then
      L1_2 = oPauseScreen
      L2_2 = L1_2
      L1_2 = L1_2.Close
      L1_2(L2_2)
      L1_2 = Sys
      L1_2 = L1_2.RequestGameState
      L2_2 = "ingame"
      L1_2(L2_2)
    end
    L1_2 = Player
    L1_2 = L1_2.GetLocalCharacter
    L1_2 = L1_2()
    if L1_2 then
      L1_2 = Object
      L1_2 = L1_2.SetInvincible
      L2_2 = Player
      L2_2 = L2_2.GetLocalCharacter
      L2_2 = L2_2()
      L3_2 = true
      L4_2 = "Fanfare"
      L1_2(L2_2, L3_2, L4_2)
    end
    L1_2 = _InitializeFanfareFlash
    L2_2 = A0_2
    L1_2(L2_2)
    L1_2 = Event
    L1_2 = L1_2.Create
    L2_2 = Event
    L2_2 = L2_2.TimerRelative
    L3_2 = {}
    L4_2 = 0.01
    L5_2 = true
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L4_2 = _InitialDelay
    L5_2 = {}
    L6_2 = A0_2
    L5_2[1] = L6_2
    L1_2(L2_2, L3_2, L4_2, L5_2)
    L1_2 = MrxGuiBase
    L1_2 = L1_2.GetControlFocus
    L2_2 = A0_2
    L3_2 = false
    L1_2(L2_2, L3_2)
  else
    L1_2 = A0_2.CustomData
    L1_2.bReadyToStart = true
  end
end

_BeginFanfareFlash = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L1_2 = A0_2.CustomData
  L3_2 = A0_2
  L2_2 = A0_2.SetVisible
  L4_2 = true
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2.Pause
  L2_2(L3_2)
  L2_2 = L1_2.sCancelMsg
  if not L2_2 then
    L2_2 = nil
  end
  L3_2 = L1_2.sCancelMsg
  L3_2 = L3_2 == nil
  L4_2 = 1
  L5_2 = L1_2.sProfileName2
  if L5_2 then
    L4_2 = 2
  end
  if L3_2 then
    L6_2 = A0_2
    L5_2 = A0_2.CallActionScriptCallback
    L7_2 = "fanfareInitialize"
    L8_2 = {}
    L9_2 = L3_2
    L10_2 = L1_2.bAllowRetry
    L11_2 = L4_2
    L12_2 = " "
    L13_2 = Net
    L13_2 = L13_2.IsClient
    L13_2 = L13_2()
    L13_2 = not L13_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L8_2[4] = L12_2
    L8_2[5] = L13_2
    L5_2(L6_2, L7_2, L8_2)
  else
    L6_2 = A0_2
    L5_2 = A0_2.CallActionScriptCallback
    L7_2 = "fanfareInitialize"
    L8_2 = {}
    L9_2 = false
    L10_2 = L1_2.bAllowRetry
    if L10_2 then
      L10_2 = Net
      L10_2 = L10_2.IsClient
      L10_2 = L10_2()
      L10_2 = not L10_2
    end
    L11_2 = L4_2
    L12_2 = L2_2
    L13_2 = Net
    L13_2 = L13_2.IsClient
    L13_2 = L13_2()
    L13_2 = not L13_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L8_2[4] = L12_2
    L8_2[5] = L13_2
    L5_2(L6_2, L7_2, L8_2)
  end
  L5_2 = L1_2.tLineList
  if not L5_2 then
    L5_2 = {}
    L1_2.tLineList = L5_2
  end
  if L3_2 then
    L6_2 = A0_2
    L5_2 = A0_2.CallActionScriptCallback
    L7_2 = "AddProfile1Name"
    L8_2 = {}
    L9_2 = L1_2.sProfileName1
    L8_2[1] = L9_2
    L5_2(L6_2, L7_2, L8_2)
    L5_2 = 1
    L6_2 = nil
    L7_2 = pairs
    L8_2 = L1_2.tLineList
    L7_2, L8_2, L9_2 = L7_2(L8_2)
    for L10_2, L11_2 in L7_2, L8_2, L9_2 do
      L12_2 = L11_2.nPlayer
      if 1 == L12_2 then
        L12_2 = L11_2.nValue
        if L12_2 < 0 then
          L12_2 = L11_2.nValue
          L6_2 = L12_2 * -1
          L5_2 = 0
        else
          L6_2 = L11_2.nValue
          L5_2 = 1
        end
        L13_2 = A0_2
        L12_2 = A0_2.CallActionScriptCallback
        L14_2 = "AddProfile1Data"
        L15_2 = {}
        L16_2 = L11_2.sDescription
        L17_2 = L6_2
        L18_2 = L5_2
        L19_2 = L11_2.sType
        L15_2[1] = L16_2
        L15_2[2] = L17_2
        L15_2[3] = L18_2
        L15_2[4] = L19_2
        L12_2(L13_2, L14_2, L15_2)
      end
    end
    L7_2 = L1_2.sProfileName2
    if L7_2 then
      L8_2 = A0_2
      L7_2 = A0_2.CallActionScriptCallback
      L9_2 = "AddProfile2Name"
      L10_2 = {}
      L11_2 = L1_2.sProfileName2
      L10_2[1] = L11_2
      L7_2(L8_2, L9_2, L10_2)
      L7_2 = 1
      L8_2 = nil
      L9_2 = pairs
      L10_2 = L1_2.tLineList
      L9_2, L10_2, L11_2 = L9_2(L10_2)
      for L12_2, L13_2 in L9_2, L10_2, L11_2 do
        L14_2 = L13_2.nPlayer
        if 2 == L14_2 then
          L14_2 = L13_2.nValue
          if L14_2 < 0 then
            L14_2 = L13_2.nValue
            L8_2 = L14_2 * -1
            L7_2 = 0
          else
            L8_2 = L13_2.nValue
            L7_2 = 1
          end
          L15_2 = A0_2
          L14_2 = A0_2.CallActionScriptCallback
          L16_2 = "AddProfile2Data"
          L17_2 = {}
          L18_2 = L13_2.sDescription
          L19_2 = L8_2
          L20_2 = L7_2
          L21_2 = L13_2.sType
          L17_2[1] = L18_2
          L17_2[2] = L19_2
          L17_2[3] = L20_2
          L17_2[4] = L21_2
          L14_2(L15_2, L16_2, L17_2)
        end
      end
    end
  end
  L6_2 = A0_2
  L5_2 = A0_2.SetFlashEventHandler
  L7_2 = "closeFanfare"
  L8_2 = _EndFanfare
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = A0_2
  L5_2 = A0_2.SetFlashEventHandler
  L7_2 = "Retry"
  L8_2 = _EndFanfare
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = A0_2
  L5_2 = A0_2.SetFlashEventHandler
  L7_2 = "FanfareCountUpComplete"
  L8_2 = _ContinueFanfare
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L5_2(L6_2, L7_2, L8_2, L9_2)
end

_InitializeFanfareFlash = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2.CallActionScriptCallback
  L3_2 = "fanfareButtonsAppear"
  L4_2 = {}
  L1_2(L2_2, L3_2, L4_2)
end

_ContinueFanfare = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2.SetVisible
  L3_2 = true
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.Play
  L1_2(L2_2)
end

_InitialDelay = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Sys
  L1_2 = L1_2.IsConfirmOnCircle
  if L1_2 then
    L1_2 = Sys
    L1_2 = L1_2.IsConfirmOnCircle
    L1_2 = L1_2()
    if L1_2 then
      L1_2 = Event
      L1_2 = L1_2.Create
      L2_2 = Event
      L2_2 = L2_2.Button
      L3_2 = {}
      L4_2 = Player
      L4_2 = L4_2.GetLocalPlayer
      L4_2 = L4_2()
      L5_2 = "cancel"
      L6_2 = "press"
      L7_2 = true
      L3_2[1] = L4_2
      L3_2[2] = L5_2
      L3_2[3] = L6_2
      L3_2[4] = L7_2
      L4_2 = _EndFanfare
      L5_2 = {}
      L6_2 = A0_2
      L5_2[1] = L6_2
      L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
      _evSkip = L1_2
  end
  else
    L1_2 = Event
    L1_2 = L1_2.Create
    L2_2 = Event
    L2_2 = L2_2.Button
    L3_2 = {}
    L4_2 = Player
    L4_2 = L4_2.GetLocalPlayer
    L4_2 = L4_2()
    L5_2 = "selection"
    L6_2 = "press"
    L7_2 = true
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L3_2[4] = L7_2
    L4_2 = _EndFanfare
    L5_2 = {}
    L6_2 = A0_2
    L5_2[1] = L6_2
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
    _evSkip = L1_2
  end
end

_SkipFanfare = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = Event
  L1_2 = L1_2.CreatePersistent
  L2_2 = Event
  L2_2 = L2_2.Button
  L3_2 = {}
  L4_2 = Player
  L4_2 = L4_2.GetLocalPlayer
  L4_2 = L4_2()
  L5_2 = "lsleft"
  L6_2 = "press"
  L7_2 = true
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L4_2 = _GuiInternal
  L4_2 = L4_2.SendFlashInput
  L5_2 = {}
  L6_2 = A0_2.BasicData
  L6_2 = L6_2.uId
  L7_2 = 9
  L8_2 = "p"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  _evLSLeft = L1_2
  L1_2 = Event
  L1_2 = L1_2.CreatePersistent
  L2_2 = Event
  L2_2 = L2_2.Button
  L3_2 = {}
  L4_2 = Player
  L4_2 = L4_2.GetLocalPlayer
  L4_2 = L4_2()
  L5_2 = "lsright"
  L6_2 = "press"
  L7_2 = true
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L4_2 = _GuiInternal
  L4_2 = L4_2.SendFlashInput
  L5_2 = {}
  L6_2 = A0_2.BasicData
  L6_2 = L6_2.uId
  L7_2 = 10
  L8_2 = "p"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  _evLSRight = L1_2
  L1_2 = Sys
  L1_2 = L1_2.IsConfirmOnCircle
  if L1_2 then
    L1_2 = Sys
    L1_2 = L1_2.IsConfirmOnCircle
    L1_2 = L1_2()
    if L1_2 then
      L1_2 = Event
      L1_2 = L1_2.Create
      L2_2 = Event
      L2_2 = L2_2.Button
      L3_2 = {}
      L4_2 = Player
      L4_2 = L4_2.GetLocalPlayer
      L4_2 = L4_2()
      L5_2 = "cancel"
      L6_2 = "press"
      L7_2 = true
      L3_2[1] = L4_2
      L3_2[2] = L5_2
      L3_2[3] = L6_2
      L3_2[4] = L7_2
      L4_2 = _GuiInternal
      L4_2 = L4_2.SendFlashInput
      L5_2 = {}
      L6_2 = A0_2.BasicData
      L6_2 = L6_2.uId
      L7_2 = 6
      L8_2 = "p"
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      L5_2[3] = L8_2
      L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
      _evSelect = L1_2
  end
  else
    L1_2 = Event
    L1_2 = L1_2.CreatePersistent
    L2_2 = Event
    L2_2 = L2_2.Button
    L3_2 = {}
    L4_2 = Player
    L4_2 = L4_2.GetLocalPlayer
    L4_2 = L4_2()
    L5_2 = "selection"
    L6_2 = "press"
    L7_2 = true
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L3_2[4] = L7_2
    L4_2 = _GuiInternal
    L4_2 = L4_2.SendFlashInput
    L5_2 = {}
    L6_2 = A0_2.BasicData
    L6_2 = L6_2.uId
    L7_2 = 6
    L8_2 = "p"
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
    _evSelect = L1_2
  end
end

_RetryEvents = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = _gFanfareFlashWidget
  if L0_2 then
    L0_2 = _GuiInternal
    L0_2 = L0_2.SendFlashInput
    L1_2 = _gFanfareFlashWidget
    L1_2 = L1_2.BasicData
    L1_2 = L1_2.uId
    L2_2 = MrxGuiBase
    L2_2 = L2_2.Joystick
    L2_2 = L2_2.BUTTON_PAD2_D
    L3_2 = "p"
    L0_2(L1_2, L2_2, L3_2)
  end
end

OnPlayerJoined = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = Event
  L0_2 = L0_2.Delete
  L1_2 = _evSurvivalMode
  L0_2(L1_2)
  L0_2 = Event
  L0_2 = L0_2.Delete
  L1_2 = _evAutoCancel
  L0_2(L1_2)
  L0_2 = Event
  L0_2 = L0_2.Delete
  L1_2 = _evSkip
  L0_2(L1_2)
  L0_2 = Event
  L0_2 = L0_2.Delete
  L1_2 = _evLSLeft
  L0_2(L1_2)
  L0_2 = Event
  L0_2 = L0_2.Delete
  L1_2 = _evLSRight
  L0_2(L1_2)
  L0_2 = Event
  L0_2 = L0_2.Delete
  L1_2 = _evSelect
  L0_2(L1_2)
end

_DeleteFanfareEvents = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = _gFanfareFlashWidget
  if not L2_2 then
    return
  end
  L2_2 = Net
  L2_2 = L2_2.IsServer
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = Net
    L2_2 = L2_2.SendEvent_CloseFanfare
    if L2_2 then
      L2_2 = Net
      L2_2 = L2_2.SendEvent_CloseFanfare
      L2_2()
    end
  end
  L2_2 = _gFanfareFlashWidget
  L2_2 = L2_2.CustomData
  L2_2 = L2_2.bHudState
  if L2_2 then
    L2_2 = MrxGuiManager
    L2_2 = L2_2.ToggleHud
    L3_2 = Player
    L3_2 = L3_2.GetLocalPlayer
    L3_2 = L3_2()
    L4_2 = true
    L2_2(L3_2, L4_2)
  end
  L2_2 = _gFanfareFlashWidget
  L3_2 = L2_2
  L2_2 = L2_2.CallActionScriptCallback
  L4_2 = "requestClose"
  L5_2 = {}
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = nil
  _gFanfareFlashWidget = L2_2
  L2_2 = MrxGuiBase
  L2_2 = L2_2.ReleaseControlFocus
  L3_2 = A0_2
  L2_2(L3_2)
  if "true" == A1_2 then
    L2_2 = A0_2.CustomData
    L2_2.bRetry = false
  elseif "false" == A1_2 then
    L2_2 = A0_2.CustomData
    L2_2.bRetry = true
  end
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 0.01
  L4_2[1] = L5_2
  L5_2 = _DeleteFanfareWidget
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L2_2 = MrxGui
  L2_2 = L2_2.RemoveWidget
  L3_2 = _gFullscreenFadeWidget
  L2_2(L3_2)
  L2_2 = _gFullscreenFadeWidget
  L3_2 = L2_2
  L2_2 = L2_2.delete
  L2_2(L3_2)
  L2_2 = Player
  L2_2 = L2_2.GetLocalCharacter
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = Object
    L2_2 = L2_2.SetInvincible
    L3_2 = Player
    L3_2 = L3_2.GetLocalCharacter
    L3_2 = L3_2()
    L4_2 = false
    L5_2 = "Fanfare"
    L2_2(L3_2, L4_2, L5_2)
  end
  L2_2 = MrxHqManager
  L2_2 = L2_2.UnlockAllHq
  L2_2()
end

_EndFanfare = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.fCallback
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.tCallbackData
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.bRetry
  L4_2 = _gFanfareFlashWidget
  if L4_2 == A0_2 then
    L4_2 = nil
    _gFanfareFlashWidget = L4_2
  end
  L5_2 = A0_2
  L4_2 = A0_2.SetSwfFile
  L6_2 = nil
  L4_2(L5_2, L6_2)
  L4_2 = MrxGui
  L4_2 = L4_2.RemoveWidget
  L5_2 = A0_2
  L4_2(L5_2)
  L5_2 = A0_2
  L4_2 = A0_2.delete
  L4_2(L5_2)
  L4_2 = MrxGui
  L4_2 = L4_2.GetWidgetByName
  L5_2 = "Pause Layout"
  L4_2 = L4_2(L5_2)
  if L4_2 then
    L6_2 = L4_2
    L5_2 = L4_2.SetUserSaveEnabled
    L7_2 = true
    L5_2(L6_2, L7_2)
  end
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.bSuppressedPda
  if L5_2 then
    L5_2 = Pda
    L6_2 = L5_2
    L5_2 = L5_2.SetSuppressed
    L7_2 = {}
    L7_2.vPlayer = nil
    L7_2.bSuppress = false
    L5_2(L6_2, L7_2)
    L5_2 = A0_2.CustomData
    L5_2.bSupressedPda = nil
  end
  L5_2 = Player
  L5_2 = L5_2.SetScopeEnabled
  if L5_2 then
    L5_2 = Player
    L5_2 = L5_2.GetLocalPlayer
    L5_2 = L5_2()
    if L5_2 then
      L5_2 = Player
      L5_2 = L5_2.SetScopeEnabled
      L6_2 = Player
      L6_2 = L6_2.GetLocalPlayer
      L6_2 = L6_2()
      L7_2 = true
      L5_2(L6_2, L7_2)
    end
  end
  L5_2 = type
  L6_2 = L1_2
  L5_2 = L5_2(L6_2)
  if "function" == L5_2 then
    L5_2 = type
    L6_2 = L2_2
    L5_2 = L5_2(L6_2)
    if "table" ~= L5_2 then
      L5_2 = {}
      L2_2 = L5_2
    end
    L5_2 = A0_2.CustomData
    L5_2 = L5_2.sType
    if "contract" ~= L5_2 then
      L5_2 = A0_2.CustomData
      L5_2 = L5_2.sType
      if "mission" ~= L5_2 then
        L5_2 = A0_2.CustomData
        L5_2 = L5_2.sType
        if "wager" ~= L5_2 then
          goto lbl_87
        end
      end
    end
    L5_2 = table
    L5_2 = L5_2.insert
    L6_2 = L2_2
    L7_2 = L3_2
    L5_2(L6_2, L7_2)
    ::lbl_87::
    L5_2 = L1_2
    L6_2 = unpack
    L7_2 = L2_2
    L6_2, L7_2 = L6_2(L7_2)
    L5_2(L6_2, L7_2)
  end
end

_DeleteFanfareWidget = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.HandleFlashInput
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

_HandleFanfareInput = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2)
  local L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2
  L8_2 = type
  L9_2 = A1_2
  L8_2 = L8_2(L9_2)
  if "string" ~= L8_2 then
    L8_2 = false
    return L8_2
  end
  L8_2 = type
  L9_2 = A2_2
  L8_2 = L8_2(L9_2)
  if "string" ~= L8_2 then
    L8_2 = false
    return L8_2
  end
  L8_2 = MrxGui
  L8_2 = L8_2.Widget
  L9_2 = L8_2
  L8_2 = L8_2.new
  L8_2 = L8_2(L9_2)
  L10_2 = L8_2
  L9_2 = L8_2.SetAnchoring
  L11_2 = "center"
  L12_2 = "center"
  L9_2(L10_2, L11_2, L12_2)
  L10_2 = L8_2
  L9_2 = L8_2.SetLocation
  L11_2 = 0
  L12_2 = 0
  L13_2 = 640
  L14_2 = 480
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
  L9_2 = MrxGui
  L9_2 = L9_2.TextWidget
  L10_2 = L9_2
  L9_2 = L9_2.new
  L9_2 = L9_2(L10_2)
  L11_2 = L9_2
  L10_2 = L9_2.SetFont
  L12_2 = "fanfare_36"
  L10_2(L11_2, L12_2)
  L11_2 = L9_2
  L10_2 = L9_2.SetScale
  L12_2 = 1
  L10_2(L11_2, L12_2)
  L11_2 = L9_2
  L10_2 = L9_2.SetAnchoring
  L12_2 = "center"
  L13_2 = "center"
  L10_2(L11_2, L12_2, L13_2)
  L11_2 = L9_2
  L10_2 = L9_2.SetText
  L12_2 = A1_2
  L10_2(L11_2, L12_2)
  L11_2 = L9_2
  L10_2 = L9_2.SetOwner
  L12_2 = A0_2
  L10_2(L11_2, L12_2)
  L10_2 = MrxGui
  L10_2 = L10_2.TextWidget
  L11_2 = L10_2
  L10_2 = L10_2.new
  L10_2 = L10_2(L11_2)
  L12_2 = L10_2
  L11_2 = L10_2.SetFont
  L13_2 = "fanfare_36"
  L11_2(L12_2, L13_2)
  L12_2 = L10_2
  L11_2 = L10_2.SetScale
  L13_2 = 1
  L11_2(L12_2, L13_2)
  L12_2 = L10_2
  L11_2 = L10_2.SetAnchoring
  L13_2 = "center"
  L14_2 = "center"
  L11_2(L12_2, L13_2, L14_2)
  L12_2 = L10_2
  L11_2 = L10_2.SetText
  L13_2 = A2_2
  L11_2(L12_2, L13_2)
  L12_2 = L10_2
  L11_2 = L10_2.SetOwner
  L13_2 = A0_2
  L11_2(L12_2, L13_2)
  L12_2 = L8_2
  L11_2 = L8_2.AddChild
  L13_2 = L9_2
  L11_2(L12_2, L13_2)
  L12_2 = L8_2
  L11_2 = L8_2.AddChild
  L13_2 = L10_2
  L11_2(L12_2, L13_2)
  L12_2 = L9_2
  L11_2 = L9_2.GetWidth
  L11_2 = L11_2(L12_2)
  L13_2 = L9_2
  L12_2 = L9_2.GetHeight
  L12_2 = L12_2(L13_2)
  L14_2 = L10_2
  L13_2 = L10_2.GetWidth
  L13_2 = L13_2(L14_2)
  L15_2 = L10_2
  L14_2 = L10_2.GetHeight
  L14_2 = L14_2(L15_2)
  L15_2 = 320
  L16_2 = 240
  L17_2 = L11_2 * 0.5
  L17_2 = L15_2 - L17_2
  L18_2 = L12_2 * 1
  L18_2 = L16_2 - L18_2
  L19_2 = L13_2 * 0.5
  L19_2 = L15_2 - L19_2
  L20_2 = L14_2 * 0
  L20_2 = L16_2 + L20_2
  L21_2 = 0 - L11_2
  L22_2 = 640
  L24_2 = L9_2
  L23_2 = L9_2.SetLocation
  L25_2 = L21_2
  L26_2 = L18_2
  L23_2(L24_2, L25_2, L26_2)
  L24_2 = L10_2
  L23_2 = L10_2.SetLocation
  L25_2 = L22_2
  L26_2 = L20_2
  L23_2(L24_2, L25_2, L26_2)
  L24_2 = L9_2
  L23_2 = L9_2.AddAnimationPoint
  L25_2 = {}
  L25_2.x = L17_2
  L23_2 = L23_2(L24_2, L25_2)
  L25_2 = L10_2
  L24_2 = L10_2.AddAnimationPoint
  L26_2 = {}
  L26_2.x = L19_2
  L24_2 = L24_2(L25_2, L26_2)
  L25_2 = A3_2 or L25_2
  if not A3_2 then
    L25_2 = 0.25
  end
  L26_2 = A4_2 or L26_2
  if not A4_2 then
    L26_2 = 3
  end
  L27_2 = A5_2 or L27_2
  if not A5_2 then
    L27_2 = 1
  end
  L28_2 = MrxGui
  L28_2 = L28_2.AddWidget
  L29_2 = L9_2
  L28_2(L29_2)
  L28_2 = MrxGui
  L28_2 = L28_2.AddWidget
  L29_2 = L10_2
  L28_2(L29_2)
  L29_2 = L9_2
  L28_2 = L9_2.AnimateToPoint
  L30_2 = L23_2
  L31_2 = L25_2
  L32_2 = true
  L33_2 = _TextDelay
  L34_2 = {}
  L35_2 = L8_2
  L36_2 = L26_2
  L37_2 = L27_2
  L34_2[1] = L35_2
  L34_2[2] = L36_2
  L34_2[3] = L37_2
  L28_2(L29_2, L30_2, L31_2, L32_2, L33_2, L34_2)
  L29_2 = L10_2
  L28_2 = L10_2.AnimateToPoint
  L30_2 = L24_2
  L31_2 = L25_2
  L32_2 = true
  L33_2 = _TextDelay
  L34_2 = {}
  L35_2 = L8_2
  L36_2 = L26_2
  L37_2 = L27_2
  L34_2[1] = L35_2
  L34_2[2] = L36_2
  L34_2[3] = L37_2
  L28_2(L29_2, L30_2, L31_2, L32_2, L33_2, L34_2)
  L28_2 = L8_2.CustomData
  L29_2 = Event
  L29_2 = L29_2.Create
  L30_2 = Event
  L30_2 = L30_2.TimerRelative
  L31_2 = {}
  L32_2 = L25_2 + L26_2
  L32_2 = L32_2 + L27_2
  L32_2 = L32_2 + 0.1
  L31_2[1] = L32_2
  L32_2 = _TextFanfareDone
  L33_2 = {}
  L34_2 = L8_2
  L35_2 = A6_2
  L36_2 = A7_2
  L33_2[1] = L34_2
  L33_2[2] = L35_2
  L33_2[3] = L36_2
  L29_2 = L29_2(L30_2, L31_2, L32_2, L33_2)
  L28_2.uTimerEvent = L29_2
  L28_2 = Net
  L28_2 = L28_2.IsServer
  L28_2 = L28_2()
  if L28_2 then
    L28_2 = Net
    L28_2 = L28_2.SendEvent_TextFanfare
    L29_2 = A1_2
    L30_2 = A2_2
    L31_2 = L25_2
    L32_2 = L26_2
    L33_2 = L27_2
    L28_2(L29_2, L30_2, L31_2, L32_2, L33_2)
  end
end

ShowTextFanfare = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  L3_2 = type
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if "function" == L3_2 then
    L3_2 = A1_2
    L4_2 = A2_2 or L4_2
    if A2_2 then
      L4_2 = unpack
      L5_2 = A2_2
      L4_2 = L4_2(L5_2)
    end
    L3_2(L4_2)
  end
  L3_2 = MrxGui
  L3_2 = L3_2.RemoveWidget
  L4_2 = A0_2
  L3_2(L4_2)
  L4_2 = A0_2
  L3_2 = A0_2.delete
  L3_2(L4_2)
end

_TextFanfareDone = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = A2_2
  L6_2[1] = L7_2
  L7_2 = _TextFadeout
  L8_2 = {}
  L9_2 = A0_2
  L10_2 = A1_2
  L11_2 = A3_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
end

_TextDelay = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L4_2 = A0_2
  L3_2 = A0_2.AddAnimationPoint
  L5_2 = {}
  L5_2.TranslucencyLevel = 0
  L3_2 = L3_2(L4_2, L5_2)
  L5_2 = A0_2
  L4_2 = A0_2.AnimateToPoint
  L6_2 = L3_2
  L7_2 = A2_2
  L8_2 = true
  L9_2 = _TextDelete
  L10_2 = {}
  L11_2 = A1_2
  L10_2[1] = L11_2
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
end

_TextFadeout = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L3_2 = A1_2
  L2_2 = A1_2.RemoveChild
  L4_2 = A0_2
  L2_2(L3_2, L4_2)
  L2_2 = MrxGui
  L2_2 = L2_2.RemoveWidget
  L3_2 = A0_2
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2.delete
  L2_2(L3_2)
end

_TextDelete = L0_1
L0_1 = {}
L0_1.contact = "[Fanfare.Common.NewContact]"
L0_1.support = "[Fanfare.Common.NewShopItem]"
L0_1.stockpile = "[Fanfare.Common.NewStockpileItem]"
L0_1.landingzone = "[Fanfare.Common.NewLandingZone]"
L0_1.hvtcapture = "[Fanfare.Common.HvtCaptured]"
L0_1.hvtkill = "[Fanfare.Common.HvtKilled]"
L0_1.bounty = "[Fanfare.Common.NewBounties]"
L0_1.outfit = "[Fanfare.Common.NewOutfit]"
L0_1.highscore = "[Fanfare.Common.NewHighScore]"
_tEventTitles = L0_1
L0_1 = {}
L0_1.contact = "unlockables_newcontact"
L0_1.support = "unlockables_newshopitem"
L0_1.stockpile = "unlockables_newstockpileitem"
L0_1.landingzone = "unlockables_landingzone"
L0_1.hvtcapture = "unlockables_hvtcaptured"
L0_1.hvtkill = "unlockables_hvtkilled"
L0_1.bounty = "unlockables_newbounties"
L0_1.outfit = "unlockables_newoutfit"
L0_1.highscore = "unlockables_leaderboardupdated"
_tEventTextures = L0_1
L0_1 = {}
L0_1.contact = "ui_signal_ding"
L0_1.support = "ui_signal_ding"
L0_1.stockpile = "ui_signal_ding"
L0_1.landingzone = "ui_signal_ding"
L0_1.hvtcapture = "ui_signal_generic"
L0_1.hvtkill = "ui_signal_generic"
L0_1.bounty = "ui_signal_ding"
L0_1.outfit = "ui_signal_ding"
L0_1.highscore = "ui_signal_ding"
_tEventSounds = L0_1
L0_1 = {}
L0_1.contact = 398
L0_1.support = 456
L0_1.stockpile = 512
L0_1.landingzone = 512
L0_1.hvtcapture = 432
L0_1.hvtkill = 365
L0_1.bounty = 428
L0_1.outfit = 370
L0_1.highscore = 512
_tEventTextureWidths = L0_1
L0_1 = 0.5
_knTextQueueFadeTime = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2
  if A0_2 then
    L4_2 = _tEventTextures
    L4_2 = L4_2[A0_2]
    if L4_2 then
      goto lbl_8
    end
  end
  do return end
  ::lbl_8::
  L4_2 = type
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  if "string" ~= L4_2 then
    L4_2 = type
    L5_2 = A1_2
    L4_2 = L4_2(L5_2)
    if "table" ~= L4_2 then
      return
    end
  end
  L4_2 = nil
  L5_2 = nil
  L6_2 = 4
  L7_2 = L6_2
  L8_2 = type
  L9_2 = A1_2
  L8_2 = L8_2(L9_2)
  if "string" == L8_2 then
    L4_2 = A1_2
  else
    L8_2 = type
    L9_2 = A1_2
    L8_2 = L8_2(L9_2)
    if "table" == L8_2 then
      L8_2 = #A1_2
      L9_2 = math
      L9_2 = L9_2.max
      L10_2 = 1.5
      L11_2 = 4 / L8_2
      L9_2 = L9_2(L10_2, L11_2)
      L6_2 = L9_2
      L9_2 = _knTextQueueFadeTime
      L9_2 = L6_2 + L9_2
      L9_2 = L9_2 * L8_2
      L10_2 = _knTextQueueFadeTime
      L7_2 = L9_2 + L10_2
      L4_2 = A1_2[1]
      L5_2 = A1_2
      L9_2 = table
      L9_2 = L9_2.remove
      L10_2 = A1_2
      L11_2 = 1
      L9_2(L10_2, L11_2)
    end
  end
  L8_2 = 0.75
  L9_2 = 512 * L8_2
  L10_2 = MrxGui
  L10_2 = L10_2.Widget
  L11_2 = L10_2
  L10_2 = L10_2.new
  L10_2 = L10_2(L11_2)
  L12_2 = L10_2
  L11_2 = L10_2.SetLocation
  L13_2 = 0
  L14_2 = 0
  L15_2 = 512
  L16_2 = 128
  L11_2(L12_2, L13_2, L14_2, L15_2, L16_2)
  L11_2 = L10_2.CustomData
  L11_2.fCallback = A2_2
  L11_2 = L10_2.CustomData
  L11_2.tCallbackData = A3_2
  L11_2 = MrxGui
  L11_2 = L11_2.ImageWidget
  L12_2 = L11_2
  L11_2 = L11_2.new
  L11_2 = L11_2(L12_2)
  L13_2 = L11_2
  L12_2 = L11_2.SetLocation
  L14_2 = 0
  L15_2 = 0
  L16_2 = 512 * L8_2
  L17_2 = 128 * L8_2
  L12_2(L13_2, L14_2, L15_2, L16_2, L17_2)
  L13_2 = L11_2
  L12_2 = L11_2.SetTexture
  L14_2 = _tEventTextures
  L14_2 = L14_2[A0_2]
  L12_2(L13_2, L14_2)
  L12_2 = _GuiInternal
  L12_2 = L12_2.SetImageTextureTransience
  L13_2 = L11_2.BasicData
  L13_2 = L13_2.uId
  L14_2 = true
  L12_2(L13_2, L14_2)
  L12_2 = MrxGui
  L12_2 = L12_2.TextWidget
  L13_2 = L12_2
  L12_2 = L12_2.new
  L12_2 = L12_2(L13_2)
  L14_2 = L12_2
  L13_2 = L12_2.SetLocation
  L15_2 = 72 * L8_2
  L16_2 = 102 * L8_2
  L17_2 = 512 * L8_2
  L18_2 = 128 * L8_2
  L13_2(L14_2, L15_2, L16_2, L17_2, L18_2)
  L14_2 = L12_2
  L13_2 = L12_2.SetFont
  L15_2 = "english_18"
  L13_2(L14_2, L15_2)
  L14_2 = L12_2
  L13_2 = L12_2.SetText
  L15_2 = L4_2
  L13_2(L14_2, L15_2)
  L14_2 = L12_2
  L13_2 = L12_2.GetWidth
  L13_2 = L13_2(L14_2)
  if L5_2 then
    L14_2 = ipairs
    L15_2 = L5_2
    L14_2, L15_2, L16_2 = L14_2(L15_2)
    for L17_2, L18_2 in L14_2, L15_2, L16_2 do
      L20_2 = L12_2
      L19_2 = L12_2.SetText
      L21_2 = L18_2
      L19_2(L20_2, L21_2)
      L19_2 = math
      L19_2 = L19_2.max
      L20_2 = L13_2
      L22_2 = L12_2
      L21_2 = L12_2.GetWidth
      L21_2, L22_2 = L21_2(L22_2)
      L19_2 = L19_2(L20_2, L21_2, L22_2)
      L13_2 = L19_2
    end
    L15_2 = L12_2
    L14_2 = L12_2.SetText
    L16_2 = L4_2
    L14_2(L15_2, L16_2)
  end
  L14_2 = math
  L14_2 = L14_2.max
  L15_2 = 72 * L8_2
  L15_2 = L13_2 + L15_2
  L16_2 = L9_2
  L14_2 = L14_2(L15_2, L16_2)
  L9_2 = L14_2
  L14_2 = L12_2.CustomData
  L14_2.tTextQueue = L5_2
  L14_2 = L12_2.CustomData
  L14_2.nDisplayTime = L6_2
  L14_2 = L12_2.CustomData
  L16_2 = L12_2
  L15_2 = L12_2.AddAnimationPoint
  L17_2 = {}
  L17_2.TranslucencyLevel = 0
  L15_2 = L15_2(L16_2, L17_2)
  L14_2.nFadePoint = L15_2
  L14_2 = L12_2.CustomData
  L16_2 = L12_2
  L15_2 = L12_2.AddAnimationPoint
  L17_2 = {}
  L17_2.TranslucencyLevel = 255
  L15_2 = L15_2(L16_2, L17_2)
  L14_2.nBasePoint = L15_2
  L15_2 = L10_2
  L14_2 = L10_2.SetLocation
  L16_2 = 0
  L17_2 = 0
  L18_2 = L9_2
  L19_2 = 128 * L8_2
  L14_2(L15_2, L16_2, L17_2, L18_2, L19_2)
  L15_2 = L10_2
  L14_2 = L10_2.AddChild
  L16_2 = L11_2
  L14_2(L15_2, L16_2)
  L15_2 = L10_2
  L14_2 = L10_2.AddChild
  L16_2 = L12_2
  L14_2(L15_2, L16_2)
  L14_2 = L10_2.CustomData
  L14_2.oIcon = L11_2
  L14_2 = L10_2.CustomData
  L14_2.oInfo = L12_2
  L14_2 = Player
  L14_2 = L14_2.GetLocalPlayer
  L14_2 = L14_2()
  L16_2 = L10_2
  L15_2 = L10_2.SetOwner
  L17_2 = L14_2
  L15_2(L16_2, L17_2)
  L16_2 = L11_2
  L15_2 = L11_2.SetOwner
  L17_2 = L14_2
  L15_2(L16_2, L17_2)
  L16_2 = L12_2
  L15_2 = L12_2.SetOwner
  L17_2 = L14_2
  L15_2(L16_2, L17_2)
  L16_2 = L10_2
  L15_2 = L10_2.AddAnimationPoint
  L17_2 = {}
  L18_2 = L9_2 * 0.5
  L18_2 = 320 - L18_2
  L17_2.x = L18_2
  L17_2.y = 156
  L15_2 = L15_2(L16_2, L17_2)
  L17_2 = L10_2
  L16_2 = L10_2.SetAnchoring
  L18_2 = "center"
  L19_2 = "center"
  L16_2(L17_2, L18_2, L19_2)
  L17_2 = L10_2
  L16_2 = L10_2.SetLocation
  L18_2 = L9_2 * 0.5
  L18_2 = 320 - L18_2
  L19_2 = 640
  L16_2(L17_2, L18_2, L19_2)
  L16_2 = MrxGui
  L16_2 = L16_2.AddWidgetWithChildren
  L17_2 = L10_2
  L16_2(L17_2)
  L16_2 = L10_2.CustomData
  L16_2.sType = A0_2
  L16_2 = L10_2.CustomData
  L16_2.nTime = L7_2
  L17_2 = L10_2
  L16_2 = L10_2.AnimateToPoint
  L18_2 = L15_2
  L19_2 = 0.5
  L20_2 = true
  L21_2 = _EventFanfareFinishAppear
  L16_2(L17_2, L18_2, L19_2, L20_2, L21_2)
end

ShowEventFanfare = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = _tEventSounds
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.sType
  L1_2 = L1_2[L2_2]
  if L1_2 then
    L1_2 = Sound
    L1_2 = L1_2.CueSound
    L2_2 = 0
    L3_2 = _tEventSounds
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.sType
    L3_2 = L3_2[L4_2]
    L1_2(L2_2, L3_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2.AddAnimationPoint
  L3_2 = {}
  L3_2.TranslucencyLevel = 255
  L1_2 = L1_2(L2_2, L3_2)
  L3_2 = A0_2
  L2_2 = A0_2.AnimateToPoint
  L4_2 = L1_2
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nTime
  L6_2 = true
  L7_2 = _EventFanfareFinishDisplay
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oInfo
  L3_2 = L2_2.CustomData
  L3_2 = L3_2.tTextQueue
  if L3_2 then
    L4_2 = L2_2
    L3_2 = L2_2.AnimateToPoint
    L5_2 = L2_2.CustomData
    L5_2 = L5_2.nBasePoint
    L6_2 = L2_2.CustomData
    L6_2 = L6_2.nDisplayTime
    L7_2 = true
    L3_2(L4_2, L5_2, L6_2, L7_2)
    L4_2 = L2_2
    L3_2 = L2_2.AnimateToPoint
    L5_2 = L2_2.CustomData
    L5_2 = L5_2.nFadePoint
    L6_2 = _knTextQueueFadeTime
    L6_2 = L6_2 * 0.5
    L7_2 = false
    L8_2 = _EventFanfareProcessTextQueue
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  end
end

_EventFanfareFinishAppear = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.tTextQueue
  if L1_2 then
    L1_2 = A0_2.CustomData
    L1_2 = L1_2.tTextQueue
    L1_2 = L1_2[1]
    if not L1_2 then
      L2_2 = A0_2.CustomData
      L2_2.tTextQueue = nil
      return
    end
    L2_2 = table
    L2_2 = L2_2.remove
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.tTextQueue
    L4_2 = 1
    L2_2(L3_2, L4_2)
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.tTextQueue
    L2_2 = #L2_2
    if L2_2 < 1 then
      L2_2 = A0_2.CustomData
      L2_2.tTextQueue = nil
    end
    L3_2 = A0_2
    L2_2 = A0_2.SetText
    L4_2 = L1_2
    L2_2(L3_2, L4_2)
    L3_2 = A0_2
    L2_2 = A0_2.AnimateToPoint
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.nBasePoint
    L5_2 = _knTextQueueFadeTime
    L5_2 = L5_2 * 0.5
    L6_2 = true
    L7_2 = _EventFanfareContinueTextFade
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  end
end

_EventFanfareProcessTextQueue = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.tTextQueue
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.AnimateToPoint
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.nBasePoint
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.nDisplayTime
    L5_2 = true
    L1_2(L2_2, L3_2, L4_2, L5_2)
    L2_2 = A0_2
    L1_2 = A0_2.AnimateToPoint
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.nFadePoint
    L4_2 = _knTextQueueFadeTime
    L4_2 = L4_2 * 0.5
    L5_2 = false
    L6_2 = _EventFanfareProcessTextQueue
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  end
end

_EventFanfareContinueTextFade = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2.AddAnimationPoint
  L3_2 = {}
  L3_2.TranslucencyLevel = 0
  L1_2 = L1_2(L2_2, L3_2)
  L3_2 = A0_2
  L2_2 = A0_2.AnimateToPoint
  L4_2 = L1_2
  L5_2 = 1
  L6_2 = true
  L7_2 = _EventFanfareComplete
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

_EventFanfareFinishDisplay = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.fCallback
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.tCallbackData
  L3_2 = MrxGui
  L3_2 = L3_2.RemoveWidgetWithChildren
  L4_2 = A0_2
  L3_2(L4_2)
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oIcon
  L4_2 = L3_2
  L3_2 = L3_2.SetTexture
  L5_2 = nil
  L3_2(L4_2, L5_2)
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oIcon
  L4_2 = L3_2
  L3_2 = L3_2.delete
  L3_2(L4_2)
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.oInfo
  L4_2 = L3_2
  L3_2 = L3_2.delete
  L3_2(L4_2)
  L4_2 = A0_2
  L3_2 = A0_2.delete
  L3_2(L4_2)
  L3_2 = type
  L4_2 = L1_2
  L3_2 = L3_2(L4_2)
  if "function" == L3_2 then
    L3_2 = type
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    if "table" ~= L3_2 then
      L3_2 = {}
      L2_2 = L3_2
    end
    L3_2 = L1_2
    L4_2 = unpack
    L5_2 = L2_2
    L4_2, L5_2 = L4_2(L5_2)
    L3_2(L4_2, L5_2)
  end
end

_EventFanfareComplete = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = _tEventTitles
  L1_2 = L1_2[A0_2]
  return L1_2
end

GetEventFanfareTitle = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = A0_2
  L2_2 = A0_2.GetLocation
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  L6_2 = L4_2 - L2_2
  nGlobalWidth = L6_2
  L6_2 = L5_2 - L3_2
  nGlobalHeight = L6_2
  L6_2 = nGlobalWidth
  L6_2 = L6_2 / 2
  L6_2 = L2_2 + L6_2
  nX = L6_2
  L6_2 = nGlobalHeight
  L6_2 = L6_2 / 2
  L6_2 = L3_2 + L6_2
  nY = L6_2
  L6_2 = A0_2.ParentWidget
  L7_2 = L6_2
  L6_2 = L6_2.SetTranslucency
  L8_2 = 0
  L6_2(L7_2, L8_2)
  L6_2 = Event
  L6_2 = L6_2.Create
  L7_2 = Event
  L7_2 = L7_2.TimerRelative
  L8_2 = {}
  L9_2 = 0.5
  L8_2[1] = L9_2
  L9_2 = MrxGui
  L9_2 = L9_2.RemoveWidget
  L10_2 = {}
  L11_2 = A0_2.ParentWidget
  L10_2[1] = L11_2
  L6_2(L7_2, L8_2, L9_2, L10_2)
end

HandleInitialization = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = ShowMessage
  L4_2 = A0_2
  L5_2 = "global_gui_completed"
  L6_2 = A1_2
  L7_2 = A2_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
end

ShowCompletedMessage = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = ShowMessage
  L4_2 = A0_2
  L5_2 = "global_gui_failed"
  L6_2 = A1_2
  L7_2 = A2_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
end

ShowFailedMessage = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2, A9_2, A10_2, A11_2)
  local L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2
  L13_2 = type
  L14_2 = A0_2
  L13_2 = L13_2(L14_2)
  if "userdata" ~= L13_2 and nil ~= A0_2 then
    return
  end
  L13_2 = type
  L14_2 = A1_2
  L13_2 = L13_2(L14_2)
  if "string" ~= L13_2 then
    L13_2 = type
    L14_2 = A1_2
    L13_2 = L13_2(L14_2)
    if "userdata" ~= L13_2 then
      return
    end
  end
  L13_2 = Net
  L13_2 = L13_2.IsServer
  L13_2 = L13_2()
  if L13_2 then
    L13_2 = Player
    L13_2 = L13_2.IsLocal
    L14_2 = A0_2
    L13_2 = L13_2(L14_2)
    if not L13_2 then
      L13_2 = Net
      L13_2 = L13_2.SendEvent_ShowMessage
      L14_2 = A0_2
      L15_2 = A1_2
      L16_2 = A4_2 or L16_2
      if not A4_2 then
        L16_2 = nX
      end
      L17_2 = A5_2 or L17_2
      if not A5_2 then
        L17_2 = nY
      end
      L18_2 = A6_2 or L18_2
      if not A6_2 then
        L18_2 = "center"
      end
      L19_2 = A7_2 or L19_2
      if not A7_2 then
        L19_2 = "center"
      end
      L20_2 = A8_2 or L20_2
      if not A8_2 then
        L20_2 = nGlobalWidth
      end
      L21_2 = A9_2 or L21_2
      if not A9_2 then
        L21_2 = nGlobalTime
      end
      L22_2 = A10_2 or L22_2
      if not A10_2 then
        L22_2 = nLifeTime
      end
      L13_2(L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2)
      return
    end
  end
  L13_2 = MrxGui
  L13_2 = L13_2.ImageWidget
  L14_2 = L13_2
  L13_2 = L13_2.new
  L13_2 = L13_2(L14_2)
  L14_2 = A8_2 or L14_2
  if not A8_2 then
    L14_2 = nGlobalWidth
  end
  L15_2 = A9_2 or L15_2
  if not A9_2 then
    L15_2 = nGlobalHeight
  end
  L16_2 = A10_2 or L16_2
  if not A10_2 then
    L16_2 = nLifeTime
  end
  L18_2 = L13_2
  L17_2 = L13_2.AddAnimationPoint
  L19_2 = {}
  L20_2 = A4_2 or L20_2
  if not A4_2 then
    L20_2 = nX
  end
  L21_2 = L14_2 / 2
  L20_2 = L20_2 - L21_2
  L19_2.x = L20_2
  L20_2 = A5_2 or L20_2
  if not A5_2 then
    L20_2 = nY
  end
  L21_2 = L15_2 / 2
  L20_2 = L20_2 - L21_2
  L19_2.y = L20_2
  L20_2 = A4_2 or L20_2
  if not A4_2 then
    L20_2 = nX
  end
  L21_2 = L14_2 / 2
  L20_2 = L20_2 + L21_2
  L19_2.x1 = L20_2
  L20_2 = A5_2 or L20_2
  if not A5_2 then
    L20_2 = nY
  end
  L21_2 = L15_2 / 2
  L20_2 = L20_2 + L21_2
  L19_2.y1 = L20_2
  L19_2.TranslucencyLevel = 255
  L20_2 = nAnimationTimeLength
  L19_2.nAnimationTime = L20_2
  L17_2 = L17_2(L18_2, L19_2)
  L19_2 = L13_2
  L18_2 = L13_2.SetTranslucency
  L20_2 = 96
  L18_2(L19_2, L20_2)
  L19_2 = L13_2
  L18_2 = L13_2.SetTexture
  L20_2 = A1_2
  L18_2(L19_2, L20_2)
  L19_2 = L13_2
  L18_2 = L13_2.SetLocation
  L20_2 = nX
  L21_2 = nMagnification
  L21_2 = L14_2 * L21_2
  L20_2 = L20_2 - L21_2
  L21_2 = nY
  L22_2 = nMagnification
  L22_2 = L15_2 * L22_2
  L21_2 = L21_2 - L22_2
  L22_2 = nX
  L23_2 = nMagnification
  L23_2 = L14_2 * L23_2
  L22_2 = L22_2 + L23_2
  L23_2 = nY
  L24_2 = nMagnification
  L24_2 = L15_2 * L24_2
  L23_2 = L23_2 + L24_2
  L18_2(L19_2, L20_2, L21_2, L22_2, L23_2)
  L19_2 = L13_2
  L18_2 = L13_2.SetAnchoring
  L20_2 = A6_2 or L20_2
  if not A6_2 then
    L20_2 = "center"
  end
  L21_2 = A7_2 or L21_2
  if not A7_2 then
    L21_2 = "center"
  end
  L18_2(L19_2, L20_2, L21_2)
  L19_2 = L13_2
  L18_2 = L13_2.SetOwner
  L20_2 = A0_2
  L18_2(L19_2, L20_2)
  L19_2 = L13_2
  L18_2 = L13_2.SetName
  L20_2 = "Announcement"
  L18_2(L19_2, L20_2)
  L18_2 = L13_2.CustomData
  L18_2.fZoomCompleteCallback = A2_2
  L18_2 = L13_2.CustomData
  L18_2.fFadeCompleteCallback = A3_2
  L18_2 = L13_2.CustomData
  L18_2.nDisplayTime = L16_2
  L18_2 = _GuiInternal
  L18_2 = L18_2.SetImageTextureTransience
  L19_2 = L13_2.BasicData
  L19_2 = L19_2.uId
  L20_2 = true
  L18_2(L19_2, L20_2)
  L18_2 = nil
  L19_2 = type
  L20_2 = A11_2
  L19_2 = L19_2(L20_2)
  if "table" ~= L19_2 then
    L19_2 = {}
    L20_2 = A11_2
    L19_2[1] = L20_2
    L18_2 = L19_2
  else
    L18_2 = A11_2
  end
  L19_2 = pairs
  L20_2 = L18_2
  L19_2, L20_2, L21_2 = L19_2(L20_2)
  for L22_2, L23_2 in L19_2, L20_2, L21_2 do
    L24_2 = type
    L25_2 = L23_2
    L24_2 = L24_2(L25_2)
    if "string" == L24_2 then
      L24_2 = Sound
      L24_2 = L24_2.CueSound
      L25_2 = 0
      L26_2 = L23_2
      L24_2(L25_2, L26_2)
    end
  end
  L19_2 = MrxGui
  L19_2 = L19_2.AddWidget
  L20_2 = L13_2
  L19_2(L20_2)
  L20_2 = L13_2
  L19_2 = L13_2.AnimateToPoint
  L21_2 = L17_2
  L22_2 = nil
  L23_2 = true
  L24_2 = AnimationFinishCallback
  L19_2(L20_2, L21_2, L22_2, L23_2, L24_2)
  return L13_2
end

ShowMessage = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.nDisplayTime
  if 0 <= L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.SetEventHandler
    L3_2 = "GuiUpdate"
    L4_2 = HandleUpdateEvent
    L1_2(L2_2, L3_2, L4_2)
    L1_2 = A0_2.CustomData
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.nDisplayTime
    L1_2.nTimeRemaining = L2_2
  end
  L1_2 = type
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.fZoomCompleteCallback
  L1_2 = L1_2(L2_2)
  if "function" == L1_2 then
    L1_2 = A0_2.CustomData
    L1_2 = L1_2.fZoomCompleteCallback
    L2_2 = A0_2
    L1_2(L2_2)
  end
end

AnimationFinishCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2.CustomData
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nTimeRemaining
  L3_2 = L3_2 - A1_2
  L2_2.nTimeRemaining = L3_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nTimeRemaining
  if L2_2 < 0 then
    L3_2 = A0_2
    L2_2 = A0_2.SetEventHandler
    L4_2 = "GuiUpdate"
    L5_2 = nil
    L2_2(L3_2, L4_2, L5_2)
    L3_2 = A0_2
    L2_2 = A0_2.AddAnimationPoint
    L4_2 = {}
    L4_2.TranslucencyLevel = 0
    L5_2 = nFadeTime
    L4_2.nAnimationTime = L5_2
    L2_2 = L2_2(L3_2, L4_2)
    L4_2 = A0_2
    L3_2 = A0_2.AnimateToPoint
    L5_2 = L2_2
    L6_2 = nil
    L7_2 = true
    L8_2 = RemovalCallback
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  end
end

HandleUpdateEvent = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = type
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.fFadeCompleteCallback
  L1_2 = L1_2(L2_2)
  if "function" == L1_2 then
    L1_2 = A0_2.CustomData
    L1_2 = L1_2.fFadeCompleteCallback
    L2_2 = A0_2
    L1_2(L2_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2.SetTexture
  L3_2 = nil
  L1_2(L2_2, L3_2)
  L1_2 = MrxGui
  L1_2 = L1_2.RemoveWidget
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.delete
  L1_2(L2_2)
end

RemovalCallback = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = Gui
  L0_2 = L0_2.LoadFont
  L1_2 = "fanfare_36"
  L0_2(L1_2)
end

Init = L0_1
L0_1 = 566.6667
_nClassyTextWidth = L0_1
L0_1 = 33.333336
_nClassyTextHeight = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2.SetFullscreen
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = DisplayClassyText
  A0_2.ShowText = L1_2
end

HandleClassyTextInit = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2, A9_2)
  local L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2
  L10_2 = type
  L11_2 = A1_2
  L10_2 = L10_2(L11_2)
  if "string" ~= L10_2 then
    return
  end
  L10_2 = _nClassyTextWidth
  L10_2 = 640 - L10_2
  A2_2 = L10_2 * 0.5
  if not A3_2 then
    A3_2 = 240
  end
  if not A4_2 then
    A4_2 = 3
  end
  A6_2 = A8_2 or A6_2
  if not A8_2 then
    A6_2 = "left"
  end
  if not A7_2 then
    A7_2 = "center"
  end
  if not A8_2 then
    A8_2 = "left"
  end
  if not A9_2 then
    A9_2 = false
  end
  A4_2 = A4_2 * 30
  L10_2 = MrxGuiBase
  L10_2 = L10_2.FlashWidget
  L11_2 = L10_2
  L10_2 = L10_2.new
  L10_2 = L10_2(L11_2)
  L12_2 = A0_2
  L11_2 = A0_2.AddChild
  L13_2 = L10_2
  L11_2(L12_2, L13_2)
  L12_2 = L10_2
  L11_2 = L10_2.SetOwner
  L14_2 = A0_2
  L13_2 = A0_2.GetOwner
  L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2 = L13_2(L14_2)
  L11_2(L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2)
  L12_2 = A0_2
  L11_2 = A0_2.AddChild
  L13_2 = L10_2
  L11_2(L12_2, L13_2)
  L10_2.ParentWidget = A0_2
  
  function L11_2(A0_3, A1_3, A2_3)
    local L3_3, L4_3, L5_3, L6_3
    L3_3 = Math
    L3_3 = L3_3.max
    L4_3 = Math
    L4_3 = L4_3.min
    L5_3 = A0_3
    L6_3 = A2_3
    L4_3 = L4_3(L5_3, L6_3)
    L5_3 = A1_3
    L3_3 = L3_3(L4_3, L5_3)
    return L3_3
  end
  
  Clamp = L11_2
  A5_2 = 1
  L11_2 = _nClassyTextWidth
  L11_2 = L11_2 * A5_2
  L12_2 = _nClassyTextHeight
  L12_2 = L12_2 * A5_2
  L13_2 = A2_2
  L14_2 = Clamp
  L15_2 = L13_2
  L16_2 = 0
  L17_2 = 600
  L14_2 = L14_2(L15_2, L16_2, L17_2)
  L13_2 = L14_2
  L14_2 = Clamp
  L15_2 = L11_2
  L16_2 = 1
  L17_2 = 640 - L13_2
  L14_2 = L14_2(L15_2, L16_2, L17_2)
  L11_2 = L14_2
  L14_2 = A3_2
  if "center" == A7_2 then
    L15_2 = L12_2 * 0.5
    L14_2 = A3_2 - L15_2
  elseif "bottom" == A7_2 then
    L14_2 = A3_2 - L12_2
  end
  if not (L14_2 < 0) then
    L15_2 = L14_2 + L12_2
    if 480 < L15_2 then
    end
  end
  L15_2 = Clamp
  L16_2 = L14_2
  L17_2 = 0
  L18_2 = 450
  L15_2 = L15_2(L16_2, L17_2, L18_2)
  L14_2 = L15_2
  L15_2 = Clamp
  L16_2 = L12_2
  L17_2 = 1
  L18_2 = 480 - L14_2
  L15_2 = L15_2(L16_2, L17_2, L18_2)
  L12_2 = L15_2
  L16_2 = L10_2
  L15_2 = L10_2.SetLocation
  L17_2 = L13_2
  L18_2 = L14_2
  L19_2 = L13_2 + L11_2
  L20_2 = L14_2 + L12_2
  L15_2(L16_2, L17_2, L18_2, L19_2, L20_2)
  L16_2 = L10_2
  L15_2 = L10_2.SetAnchoring
  L17_2 = A6_2
  L18_2 = A7_2
  L15_2(L16_2, L17_2, L18_2)
  L16_2 = L10_2
  L15_2 = L10_2.SetSwfFile
  L17_2 = "text_effect"
  L18_2 = _ClassyTextLoadCompleteCallback
  L19_2 = {}
  L20_2 = L10_2
  L21_2 = A1_2
  L22_2 = A4_2
  L23_2 = A8_2
  L24_2 = A9_2
  L19_2[1] = L20_2
  L19_2[2] = L21_2
  L19_2[3] = L22_2
  L19_2[4] = L23_2
  L19_2[5] = L24_2
  L15_2(L16_2, L17_2, L18_2, L19_2)
  L15_2 = MrxGuiBase
  L15_2 = L15_2.AddWidget
  L16_2 = L10_2
  L15_2(L16_2)
end

DisplayClassyText = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L6_2 = A0_2
  L5_2 = A0_2.SetFlashEventHandler
  L7_2 = "close"
  L8_2 = _HandleClassyTextEnd
  L5_2(L6_2, L7_2, L8_2)
  L5_2 = 1
  if not A4_2 then
    L5_2 = 2
  end
  L6_2 = 1
  if "center" == A3_2 then
    L6_2 = 2
  elseif "right" == A3_2 then
    L6_2 = 3
  end
  L8_2 = A0_2
  L7_2 = A0_2.CallActionScriptCallback
  L9_2 = "textInput"
  L10_2 = {}
  L11_2 = A1_2
  L12_2 = L5_2
  L13_2 = L6_2
  L14_2 = A2_2
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L7_2(L8_2, L9_2, L10_2)
end

_ClassyTextLoadCompleteCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2
  L1_2 = A0_2.SetVisible
  L3_2 = false
  L1_2(L2_2, L3_2)
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 0.05
  L5_2 = true
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L4_2 = _DeleteClassyText
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

_HandleClassyTextEnd = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2.SetSwfFile
  L3_2 = nil
  L1_2(L2_2, L3_2)
  L1_2 = A0_2.ParentWidget
  L2_2 = L1_2
  L1_2 = L1_2.RemoveChild
  L3_2 = A0_2
  L1_2(L2_2, L3_2)
  A0_2.ParentWidget = nil
  L1_2 = MrxGuiBase
  L1_2 = L1_2.RemoveWidget
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.delete
  L1_2(L2_2)
end

_DeleteClassyText = L0_1
