local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
end

SetCounterMessageVisible = L0_1

function L0_1(A0_2, A1_2)
end

SetMeleeMessage = L0_1

function L0_1(A0_2, A1_2)
end

DisplayCounterMessage = L0_1

function L0_1(A0_2, A1_2)
end

HandleUpdateEvent = L0_1

function L0_1(A0_2, A1_2)
end

HandleInitializationEvent = L0_1

function L0_1(A0_2)
  local L1_2
end

HideOnComplete = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L4_2 = type
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  if "userdata" ~= L4_2 then
    L4_2 = MrxGui
    L4_2 = L4_2.GetWidgetByName
    L5_2 = "Context Action Text"
    L4_2 = L4_2(L5_2)
    L3_2 = L4_2
  else
    L4_2 = MrxGui
    L4_2 = L4_2.GetWidgetByNameAndOwner
    L5_2 = "Context Action Text"
    L6_2 = A1_2
    L4_2 = L4_2(L5_2, L6_2)
    L3_2 = L4_2
  end
  if not L3_2 then
    return
  end
  if not A2_2 then
    A2_2 = 1
  end
  L4_2 = L3_2.CustomData
  L4_2 = L4_2.bInitialized
  if not L4_2 then
    L4_2 = _Initialize
    L5_2 = L3_2
    L4_2(L5_2)
  end
  if not A0_2 then
    L4_2 = L3_2.CustomData
    L4_2 = L4_2.tMessageQueue
    L4_2[A2_2] = nil
    L4_2 = L3_2.CustomData
    L4_2 = L4_2.nCurrentPriority
    if A2_2 ~= L4_2 then
      goto lbl_126
    end
    L4_2 = 0
    L5_2 = nil
    L6_2 = pairs
    L7_2 = L3_2.CustomData
    L7_2 = L7_2.tMessageQueue
    L6_2, L7_2, L8_2 = L6_2(L7_2)
    for L9_2, L10_2 in L6_2, L7_2, L8_2 do
      L4_2 = L9_2
      L5_2 = L10_2
    end
    if L5_2 then
      L6_2 = L3_2.CustomData
      L6_2 = L6_2.sCurrentText
      if L6_2 then
        L6_2 = L3_2.CustomData
        L6_2 = L6_2.sCurrentText
        if L6_2 == L5_2 then
          goto lbl_66
        end
      end
      L6_2 = Sound
      L6_2 = L6_2.CueSound
      L7_2 = 0
      L8_2 = "ui_HUD_Contextual_Action_Alert"
      L6_2(L7_2, L8_2)
      ::lbl_66::
      L7_2 = L3_2
      L6_2 = L3_2.SetText
      L8_2 = "[action] "
      L9_2 = L5_2
      L8_2 = L8_2 .. L9_2
      L6_2(L7_2, L8_2)
      L7_2 = L3_2
      L6_2 = L3_2.AnimateToPoint
      L8_2 = L3_2.CustomData
      L8_2 = L8_2.nVisiblePoint
      L9_2 = 0
      L10_2 = true
      L6_2(L7_2, L8_2, L9_2, L10_2)
      L6_2 = L3_2.CustomData
      L6_2.nCurrentPriority = L4_2
      L6_2 = L3_2.CustomData
      L6_2.sCurrentText = A0_2
    else
      L7_2 = L3_2
      L6_2 = L3_2.AnimateToPoint
      L8_2 = L3_2.CustomData
      L8_2 = L8_2.nFadePoint
      L9_2 = 1
      L10_2 = true
      L11_2 = ContextActionWidgetRemovalCallback
      L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
      L6_2 = L3_2.CustomData
      L6_2.sCurrentText = nil
    end
  else
    L4_2 = L3_2.CustomData
    L4_2 = L4_2.tMessageQueue
    L4_2[A2_2] = A0_2
    L4_2 = L3_2.CustomData
    L4_2 = L4_2.sCurrentText
    if L4_2 then
      L4_2 = L3_2.CustomData
      L4_2 = L4_2.sCurrentText
      if L4_2 == A0_2 then
        goto lbl_108
      end
    end
    L4_2 = Sound
    L4_2 = L4_2.CueSound
    L5_2 = 0
    L6_2 = "ui_HUD_Contextual_Action_Alert"
    L4_2(L5_2, L6_2)
    ::lbl_108::
    L5_2 = L3_2
    L4_2 = L3_2.SetVisible
    L6_2 = true
    L4_2(L5_2, L6_2)
    L5_2 = L3_2
    L4_2 = L3_2.SetText
    L6_2 = "[action] "
    L7_2 = A0_2
    L6_2 = L6_2 .. L7_2
    L4_2(L5_2, L6_2)
    L4_2 = L3_2.CustomData
    L4_2.nCurrentPriority = A2_2
    L4_2 = L3_2.CustomData
    L4_2.sCurrentText = A0_2
    L5_2 = L3_2
    L4_2 = L3_2.AnimateToPoint
    L6_2 = L3_2.CustomData
    L6_2 = L6_2.nVisiblePoint
    L7_2 = 0
    L8_2 = true
    L4_2(L5_2, L6_2, L7_2, L8_2)
  end
  ::lbl_126::
end

SetContextActionMessage = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2.SetVisible
  L3_2 = false
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.SetText
  L3_2 = ""
  L1_2(L2_2, L3_2)
  L1_2 = A0_2.CustomData
  L1_2.nCurrentPriority = 0
  L2_2 = A0_2
  L1_2 = A0_2.SetTranslucency
  L3_2 = 255
  L1_2(L2_2, L3_2)
end

ContextActionWidgetRemovalCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = A0_2.CustomData
  L1_2.bInitialized = true
  L1_2 = A0_2.CustomData
  L2_2 = {}
  L1_2.tMessageQueue = L2_2
  L1_2 = A0_2.CustomData
  L1_2.nCurrentPriority = 0
  L1_2 = A0_2.CustomData
  L3_2 = A0_2
  L2_2 = A0_2.AddAnimationPoint
  L4_2 = {}
  L4_2.TranslucencyLevel = 255
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.nVisiblePoint = L2_2
  L1_2 = A0_2.CustomData
  L3_2 = A0_2
  L2_2 = A0_2.AddAnimationPoint
  L4_2 = {}
  L4_2.TranslucencyLevel = 0
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.nFadePoint = L2_2
end

_Initialize = L0_1
