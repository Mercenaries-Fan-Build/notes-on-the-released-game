local L0_1, L1_1, L2_1, L3_1
L0_1 = {}
L0_1.BUTTON_PAD1_U = 1
L0_1.BUTTON_PAD1_D = 2
L0_1.BUTTON_PAD1_L = 3
L0_1.BUTTON_PAD1_R = 4
L0_1.BUTTON_PAD2_U = 5
L0_1.BUTTON_PAD2_D = 6
L0_1.BUTTON_PAD2_L = 7
L0_1.BUTTON_PAD2_R = 8
L0_1.BUTTON_L_STICK_L = 9
L0_1.BUTTON_L_STICK_R = 10
L0_1.BUTTON_L_STICK_U = 11
L0_1.BUTTON_L_STICK_D = 12
L0_1.BUTTON_R_STICK_L = 13
L0_1.BUTTON_R_STICK_R = 14
L0_1.BUTTON_R_STICK_U = 15
L0_1.BUTTON_R_STICK_D = 16
L0_1.BUTTON_ALT1_1 = 17
L0_1.BUTTON_ALT1_2 = 18
L0_1.BUTTON_ALT1_3 = 19
L0_1.BUTTON_ALT2_1 = 20
L0_1.BUTTON_ALT2_2 = 21
L0_1.BUTTON_ALT2_3 = 22
L0_1.BUTTON_SYS1 = 23
L0_1.BUTTON_SYS2 = 24
Joystick = L0_1
L0_1 = {}
ControlFocusQueue = L0_1
L0_1 = {}
ControlModeManager = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  if nil == A1_2 then
    A1_2 = false
  end
  L4_2 = A0_2
  L3_2 = A0_2.GetOwner
  L3_2 = L3_2(L4_2)
  if nil == L3_2 or A2_2 then
    L3_2 = "global"
  end
  L4_2 = ControlFocusQueue
  L4_2 = L4_2[L3_2]
  if not L4_2 then
    L4_2 = ControlFocusQueue
    L5_2 = {}
    L4_2[L3_2] = L5_2
  end
  L4_2 = table
  L4_2 = L4_2.insert
  L5_2 = ControlFocusQueue
  L5_2 = L5_2[L3_2]
  L6_2 = 1
  L7_2 = {}
  L7_2.oWidget = A0_2
  L7_2.bPause = A1_2
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = ControlModeManager
  L4_2 = L4_2[L3_2]
  if nil ~= L4_2 then
    L4_2 = ControlModeManager
    L4_2 = L4_2[L3_2]
    if L4_2 then
      L4_2 = SetDialogBoxMode
      L5_2 = L3_2
      L6_2 = false
      L4_2(L5_2, L6_2)
    else
      L4_2 = SetSupportMenuMode
      L5_2 = L3_2
      L6_2 = false
      L4_2(L5_2, L6_2)
    end
  end
  L4_2 = ControlModeManager
  L4_2[L3_2] = A1_2
  if A1_2 then
    L4_2 = SetDialogBoxMode
    L5_2 = L3_2
    L6_2 = true
    L4_2(L5_2, L6_2)
  else
    L4_2 = SetSupportMenuMode
    L5_2 = L3_2
    L6_2 = true
    L4_2(L5_2, L6_2)
  end
end

GetControlFocus = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  if A1_2 then
    L3_2 = A1_2
  else
    L5_2 = A0_2
    L4_2 = A0_2.GetOwner
    L4_2 = L4_2(L5_2)
    L3_2 = L4_2
  end
  if nil == L3_2 or A2_2 then
    L3_2 = "global"
  end
  L4_2 = ControlFocusQueue
  L4_2 = L4_2[L3_2]
  if not L4_2 then
    return
  end
  L5_2 = nil
  L6_2 = pairs
  L7_2 = ControlFocusQueue
  L7_2 = L7_2[L3_2]
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  for L9_2, L10_2 in L6_2, L7_2, L8_2 do
    L11_2 = L10_2.oWidget
    if A0_2 == L11_2 then
      L5_2 = L9_2
    end
  end
  if not L5_2 then
    return
  end
  L6_2 = table
  L6_2 = L6_2.remove
  L7_2 = ControlFocusQueue
  L7_2 = L7_2[L3_2]
  L8_2 = L5_2
  L6_2(L7_2, L8_2)
  L6_2 = ControlModeManager
  L6_2 = L6_2[L3_2]
  if nil ~= L6_2 then
    L6_2 = ControlModeManager
    L6_2 = L6_2[L3_2]
    if L6_2 then
      L6_2 = SetDialogBoxMode
      L7_2 = L3_2
      L8_2 = false
      L6_2(L7_2, L8_2)
    else
      L6_2 = SetSupportMenuMode
      L7_2 = L3_2
      L8_2 = false
      L6_2(L7_2, L8_2)
    end
  end
  L6_2 = ControlFocusQueue
  L6_2 = L6_2[L3_2]
  L6_2 = L6_2[1]
  if L6_2 then
    L7_2 = ControlModeManager
    L8_2 = L6_2.bPause
    L7_2[L3_2] = L8_2
    L7_2 = L6_2.bPause
    if L7_2 then
      L7_2 = SetDialogBoxMode
      L8_2 = L3_2
      L9_2 = true
      L7_2(L8_2, L9_2)
    else
      L7_2 = SetSupportMenuMode
      L8_2 = L3_2
      L9_2 = true
      L7_2(L8_2, L9_2)
    end
  end
end

ReleaseControlFocus = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2
  if nil == L1_2 then
    L1_2 = "global"
  end
  L2_2 = ControlFocusQueue
  L2_2 = L2_2[L1_2]
  if L2_2 then
    L2_2 = ControlFocusQueue
    L2_2 = L2_2[L1_2]
    L2_2 = L2_2[1]
    if L2_2 then
      L2_2 = ControlFocusQueue
      L2_2 = L2_2[L1_2]
      L2_2 = L2_2[1]
      L2_2 = L2_2.oWidget
      return L2_2
    end
  end
  L2_2 = nil
  return L2_2
end

GetCurrentControlHolder = L0_1

function L0_1(A0_2, A1_2)
end

InformControlOwnerChanged = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  if nil == A0_2 then
    L1_2 = true
    return L1_2
  end
  L1_2 = Net
  L1_2 = L1_2.IsMultiplayer
  L1_2 = L1_2()
  if not L1_2 then
    L1_2 = true
    return L1_2
  end
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "userdata" ~= L1_2 then
    L1_2 = false
    return L1_2
  end
  L1_2 = Player
  L1_2 = L1_2.GetViewportId
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = IsViewportLocal
  L3_2 = L1_2
  return L2_2(L3_2)
end

IsPlayerLocal = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  if nil == A0_2 then
    L1_2 = true
    return L1_2
  end
  L1_2 = Net
  L1_2 = L1_2.IsMultiplayer
  L1_2 = L1_2()
  if not L1_2 then
    L1_2 = true
    return L1_2
  end
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "userdata" ~= L1_2 then
    L1_2 = false
    return L1_2
  end
  L1_2 = tonumber
  L2_2 = Sys
  L2_2 = L2_2.GuidToString
  L3_2 = A0_2
  L2_2, L3_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2)
  if 1 < L1_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = true
  return L2_2
end

IsViewportLocal = L0_1
L0_1 = {}
L1_1 = {}
L0_1.EventList = L1_1
L1_1 = {}
L1_1.EventType = 2
L0_1.RenderEvent = L1_1
L1_1 = {}
L0_1.ScriptEventList = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" == L1_2 then
    L1_2 = A0_2.EventType
    if L1_2 then
      L1_2 = table
      L1_2 = L1_2.insert
      L2_2 = EventManager
      L2_2 = L2_2.ScriptEventList
      L3_2 = A0_2
      L1_2(L2_2, L3_2)
    end
  end
end

L0_1.SendEvent = L1_1

function L1_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L0_2 = table
  L0_2 = L0_2.insert
  L1_2 = EventManager
  L1_2 = L1_2.EventList
  L2_2 = RenderEvent
  L0_2(L1_2, L2_2)
  L0_2 = pairs
  L1_2 = EventManager
  L1_2 = L1_2.ScriptEventList
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = table
    L5_2 = L5_2.insert
    L6_2 = EventManager
    L6_2 = L6_2.EventList
    L7_2 = L4_2
    L5_2(L6_2, L7_2)
    L5_2 = EventManager
    L5_2 = L5_2.ScriptEventList
    L5_2[L3_2] = nil
  end
  L0_2 = pairs
  L1_2 = EventManager
  L1_2 = L1_2.EventList
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = L4_2.EventType
    if 8 == L5_2 then
      L5_2 = pairs
      L6_2 = WidgetIdIndex
      L5_2, L6_2, L7_2 = L5_2(L6_2)
      for L8_2 in L5_2, L6_2, L7_2 do
        L9_2 = _GuiInternal
        L9_2 = L9_2.CorrectWidgetForResolution
        L10_2 = L8_2
        L9_2(L10_2)
      end
    else
      L5_2 = L4_2.EventType
      if "ControllerInput" == L5_2 then
        L5_2 = GetCurrentControlHolder
        L6_2 = L4_2.uPlayerGuid
        L5_2 = L5_2(L6_2)
        if L5_2 then
          L6_2 = L5_2.BasicData
          L6_2 = L6_2.bEnabled
          if L6_2 then
            L6_2 = L5_2.EventHandlers
            L7_2 = L4_2.EventType
            L6_2 = L6_2[L7_2]
            if L6_2 then
              L6_2 = L5_2.EventHandlers
              L7_2 = L4_2.EventType
              L6_2 = L6_2[L7_2]
              L7_2 = L5_2
              L8_2 = L4_2
              L6_2(L7_2, L8_2)
            end
          end
        end
      else
        L5_2 = WidgetManager
        L5_2 = L5_2.WidgetEventIndex
        L6_2 = L4_2.EventType
        L5_2 = L5_2[L6_2]
        if L5_2 ~= nil then
          L5_2 = pairs
          L6_2 = WidgetManager
          L6_2 = L6_2.WidgetEventIndex
          L7_2 = L4_2.EventType
          L6_2 = L6_2[L7_2]
          L5_2, L6_2, L7_2 = L5_2(L6_2)
          for L8_2, L9_2 in L5_2, L6_2, L7_2 do
            L10_2 = L9_2.EventHandlers
            L11_2 = L4_2.EventType
            L10_2 = L10_2[L11_2]
            if L10_2 ~= nil then
              L10_2 = L9_2.BasicData
              L10_2 = L10_2.bEnabled
              if L10_2 then
                L10_2 = L4_2.uPlayerGuid
                L11_2 = L9_2.BasicData
                L11_2 = L11_2.uOwnerGuid
                if L10_2 ~= L11_2 then
                  L10_2 = L4_2.uPlayerGuid
                  if nil ~= L10_2 then
                    goto lbl_102
                  end
                end
                L10_2 = L9_2.EventHandlers
                L11_2 = L4_2.EventType
                L10_2 = L10_2[L11_2]
                L11_2 = L9_2
                L12_2 = L4_2
                L10_2(L11_2, L12_2)
              end
            end
            ::lbl_102::
          end
        end
      end
    end
    L5_2 = EventManager
    L5_2 = L5_2.EventList
    L5_2[L3_2] = nil
  end
end

L0_1.ProcessEvents = L1_1
EventManager = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = EventManager
  L1_2 = L1_2.SendEvent
  L2_2 = A0_2
  L1_2(L2_2)
end

SentEvent = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = A0_2.EventType
  if 8 == L1_2 then
    L2_2 = pairs
    L3_2 = WidgetIdIndex
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2 in L2_2, L3_2, L4_2 do
      L6_2 = _GuiInternal
      L6_2 = L6_2.CorrectWidgetForResolution
      L7_2 = L5_2
      L6_2(L7_2)
    end
  elseif "ControllerInput" == L1_2 then
    L2_2 = GetCurrentControlHolder
    L3_2 = A0_2.uPlayerGuid
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L3_2 = L2_2.BasicData
      L3_2 = L3_2.bEnabled
      if L3_2 then
        L3_2 = L2_2.EventHandlers
        L3_2 = L3_2[L1_2]
        if L3_2 then
          L3_2 = L2_2.EventHandlers
          L3_2 = L3_2[L1_2]
          L4_2 = L2_2
          L5_2 = A0_2
          L3_2(L4_2, L5_2)
        end
      end
    end
  else
    L2_2 = WidgetManager
    L2_2 = L2_2.WidgetEventIndex
    L2_2 = L2_2[L1_2]
    if L2_2 ~= nil then
      L2_2 = pairs
      L3_2 = WidgetManager
      L3_2 = L3_2.WidgetEventIndex
      L3_2 = L3_2[L1_2]
      L2_2, L3_2, L4_2 = L2_2(L3_2)
      for L5_2, L6_2 in L2_2, L3_2, L4_2 do
        L7_2 = L6_2.EventHandlers
        L7_2 = L7_2[L1_2]
        if L7_2 ~= nil then
          L7_2 = L6_2.BasicData
          L7_2 = L7_2.bEnabled
          if L7_2 then
            L7_2 = A0_2.uPlayerGuid
            L8_2 = L6_2.BasicData
            L8_2 = L8_2.uOwnerGuid
            if L7_2 ~= L8_2 then
              L7_2 = A0_2.uPlayerGuid
              if nil ~= L7_2 then
                goto lbl_68
              end
            end
            L7_2 = L6_2.EventHandlers
            L7_2 = L7_2[L1_2]
            L8_2 = L6_2
            L9_2 = A0_2
            L7_2(L8_2, L9_2)
          end
        end
        ::lbl_68::
      end
    end
  end
end

ProcessEventImmediate = L0_1
L0_1 = {}
L1_1 = {}
L0_1.WidgetList = L1_1
L1_1 = {}
L0_1.WidgetEventIndex = L1_1
L1_1 = {}
L0_1.WidgetNameIndex = L1_1
L1_1 = {}
L0_1.WidgetNamePlayerIndex = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = pairs
  L2_2 = WidgetManager
  L2_2 = L2_2.WidgetList
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    if L5_2 == A0_2 then
      return
    end
  end
  L1_2 = table
  L1_2 = L1_2.insert
  L2_2 = WidgetManager
  L2_2 = L2_2.WidgetList
  L3_2 = A0_2
  L1_2(L2_2, L3_2)
  L1_2 = pairs
  L2_2 = A0_2.EventHandlers
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2 in L1_2, L2_2, L3_2 do
    L5_2 = WidgetManager
    L5_2 = L5_2.WidgetEventIndex
    L5_2 = L5_2[L4_2]
    if L5_2 == nil then
      L5_2 = WidgetManager
      L5_2 = L5_2.WidgetEventIndex
      L6_2 = {}
      L5_2[L4_2] = L6_2
    end
    L5_2 = table
    L5_2 = L5_2.insert
    L6_2 = WidgetManager
    L6_2 = L6_2.WidgetEventIndex
    L6_2 = L6_2[L4_2]
    L7_2 = A0_2
    L5_2(L6_2, L7_2)
  end
  L1_2 = A0_2.BasicData
  L1_2 = L1_2.name
  if L1_2 then
    L1_2 = WidgetManager
    L1_2 = L1_2.WidgetNameIndex
    L2_2 = A0_2.BasicData
    L2_2 = L2_2.name
    L1_2 = L1_2[L2_2]
    if not L1_2 then
      L1_2 = WidgetManager
      L1_2 = L1_2.WidgetNameIndex
      L2_2 = A0_2.BasicData
      L2_2 = L2_2.name
      L3_2 = {}
      L1_2[L2_2] = L3_2
    end
    L1_2 = table
    L1_2 = L1_2.insert
    L2_2 = WidgetManager
    L2_2 = L2_2.WidgetNameIndex
    L3_2 = A0_2.BasicData
    L3_2 = L3_2.name
    L2_2 = L2_2[L3_2]
    L3_2 = A0_2
    L1_2(L2_2, L3_2)
  end
  L1_2 = A0_2.BasicData
  L1_2 = L1_2.name
  if L1_2 then
    L1_2 = A0_2.BasicData
    L1_2 = L1_2.uOwnerGuid
    if L1_2 then
      L1_2 = WidgetManager
      L1_2 = L1_2.WidgetNamePlayerIndex
      L2_2 = A0_2.BasicData
      L2_2 = L2_2.uOwnerGuid
      L1_2 = L1_2[L2_2]
      if not L1_2 then
        L1_2 = WidgetManager
        L1_2 = L1_2.WidgetNamePlayerIndex
        L2_2 = A0_2.BasicData
        L2_2 = L2_2.uOwnerGuid
        L3_2 = {}
        L1_2[L2_2] = L3_2
      end
      L1_2 = WidgetManager
      L1_2 = L1_2.WidgetNamePlayerIndex
      L2_2 = A0_2.BasicData
      L2_2 = L2_2.uOwnerGuid
      L1_2 = L1_2[L2_2]
      L2_2 = A0_2.BasicData
      L2_2 = L2_2.name
      L1_2[L2_2] = A0_2
    end
  end
  L2_2 = A0_2
  L1_2 = A0_2.SetEnabled
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = _GuiInternal
  L1_2 = L1_2.ActivateWidget
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  L3_2 = true
  L1_2(L2_2, L3_2)
end

L0_1.AddWidget = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = pairs
  L2_2 = WidgetManager
  L2_2 = L2_2.WidgetList
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    if L5_2 == A0_2 then
      L6_2 = table
      L6_2 = L6_2.remove
      L7_2 = WidgetManager
      L7_2 = L7_2.WidgetList
      L8_2 = L4_2
      L6_2(L7_2, L8_2)
    end
  end
  L1_2 = pairs
  L2_2 = A0_2.EventHandlers
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2 in L1_2, L2_2, L3_2 do
    L5_2 = WidgetManager
    L5_2 = L5_2.WidgetEventIndex
    L5_2 = L5_2[L4_2]
    if L5_2 ~= nil then
      L5_2 = pairs
      L6_2 = WidgetManager
      L6_2 = L6_2.WidgetEventIndex
      L6_2 = L6_2[L4_2]
      L5_2, L6_2, L7_2 = L5_2(L6_2)
      for L8_2 in L5_2, L6_2, L7_2 do
        L9_2 = WidgetManager
        L9_2 = L9_2.WidgetEventIndex
        L9_2 = L9_2[L4_2]
        L9_2 = L9_2[L8_2]
        if L9_2 == A0_2 then
          L9_2 = table
          L9_2 = L9_2.remove
          L10_2 = WidgetManager
          L10_2 = L10_2.WidgetEventIndex
          L10_2 = L10_2[L4_2]
          L11_2 = L8_2
          L9_2(L10_2, L11_2)
        end
      end
    end
  end
  L1_2 = A0_2.BasicData
  L1_2 = L1_2.name
  if L1_2 then
    L1_2 = WidgetManager
    L1_2 = L1_2.WidgetNameIndex
    L2_2 = A0_2.BasicData
    L2_2 = L2_2.name
    L1_2 = L1_2[L2_2]
    if L1_2 then
      L1_2 = nil
      L2_2 = pairs
      L3_2 = WidgetManager
      L3_2 = L3_2.WidgetNameIndex
      L4_2 = A0_2.BasicData
      L4_2 = L4_2.name
      L3_2 = L3_2[L4_2]
      L2_2, L3_2, L4_2 = L2_2(L3_2)
      for L5_2, L6_2 in L2_2, L3_2, L4_2 do
        if L6_2 == A0_2 then
          L1_2 = L5_2
        end
      end
      if L1_2 then
        L2_2 = table
        L2_2 = L2_2.remove
        L3_2 = WidgetManager
        L3_2 = L3_2.WidgetNameIndex
        L4_2 = A0_2.BasicData
        L4_2 = L4_2.name
        L3_2 = L3_2[L4_2]
        L4_2 = L1_2
        L2_2(L3_2, L4_2)
      end
    end
  end
  L1_2 = A0_2.BasicData
  L1_2 = L1_2.name
  if L1_2 then
    L1_2 = A0_2.BasicData
    L1_2 = L1_2.uOwnerGuid
    if L1_2 then
      L1_2 = WidgetManager
      L1_2 = L1_2.WidgetNamePlayerIndex
      L2_2 = A0_2.BasicData
      L2_2 = L2_2.uOwnerGuid
      L1_2 = L1_2[L2_2]
      if L1_2 then
        L1_2 = WidgetManager
        L1_2 = L1_2.WidgetNamePlayerIndex
        L2_2 = A0_2.BasicData
        L2_2 = L2_2.uOwnerGuid
        L1_2 = L1_2[L2_2]
        L2_2 = A0_2.BasicData
        L2_2 = L2_2.name
        L1_2[L2_2] = nil
      end
    end
  end
  L2_2 = A0_2
  L1_2 = A0_2.SetEnabled
  L3_2 = false
  L1_2(L2_2, L3_2)
  L1_2 = _GuiInternal
  L1_2 = L1_2.ActivateWidget
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  L3_2 = false
  L1_2(L2_2, L3_2)
end

L0_1.RemoveWidget = L1_1

function L1_1()
  local L0_2, L1_2
  L0_2 = WidgetManager
  L1_2 = {}
  L0_2.WidgetList = L1_2
  L0_2 = WidgetManager
  L1_2 = {}
  L0_2.WidgetEventIndex = L1_2
  L0_2 = WidgetManager
  L1_2 = {}
  L0_2.WidgetNameIndex = L1_2
  L0_2 = WidgetManager
  L1_2 = {}
  L0_2.WidgetNamePlayerIndex = L1_2
end

L0_1.RemoveAll = L1_1

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = WidgetManager
  L1_2 = L1_2.RemoveWidget
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = WidgetManager
  L1_2 = L1_2.AddWidget
  L2_2 = A0_2
  L1_2(L2_2)
end

L0_1.UpdateWidgetEventHandlers = L1_1

function L1_1(A0_2)
  local L1_2, L2_2
  if A0_2 then
    L1_2 = WidgetManager
    L1_2 = L1_2.WidgetNameIndex
    L1_2 = L1_2[A0_2]
    if L1_2 then
      L1_2 = WidgetManager
      L1_2 = L1_2.WidgetNameIndex
      L1_2 = L1_2[A0_2]
      L2_2 = WidgetManager
      L2_2 = L2_2.WidgetNameIndex
      L2_2 = L2_2[A0_2]
      L2_2 = #L2_2
      L1_2 = L1_2[L2_2]
      return L1_2
  end
  else
    L1_2 = nil
    return L1_2
  end
end

L0_1.GetWidgetByName = L1_1

function L1_1(A0_2)
  local L1_2
  if A0_2 then
    L1_2 = WidgetManager
    L1_2 = L1_2.WidgetNameIndex
    L1_2 = L1_2[A0_2]
    if L1_2 then
      L1_2 = WidgetManager
      L1_2 = L1_2.WidgetNameIndex
      L1_2 = L1_2[A0_2]
      return L1_2
  end
  else
    L1_2 = {}
    return L1_2
  end
end

L0_1.GetAllWidgetsByName = L1_1

function L1_1(A0_2)
  local L1_2
  if A0_2 then
    L1_2 = WidgetManager
    L1_2 = L1_2.WidgetList
    L1_2 = L1_2[A0_2]
    return L1_2
  else
    L1_2 = nil
    return L1_2
  end
end

L0_1.GetWidgetByIndexNumber = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "string" == L2_2 then
    L2_2 = type
    L3_2 = A1_2
    L2_2 = L2_2(L3_2)
    if "userdata" == L2_2 then
      L2_2 = WidgetManager
      L2_2 = L2_2.WidgetNamePlayerIndex
      L2_2 = L2_2[A1_2]
      if L2_2 then
        L2_2 = WidgetManager
        L2_2 = L2_2.WidgetNamePlayerIndex
        L2_2 = L2_2[A1_2]
        L2_2 = L2_2[A0_2]
        if L2_2 then
          L2_2 = WidgetManager
          L2_2 = L2_2.WidgetNamePlayerIndex
          L2_2 = L2_2[A1_2]
          L2_2 = L2_2[A0_2]
          return L2_2
        end
      end
    end
  end
  L2_2 = nil
  return L2_2
end

L0_1.GetWidgetByNameAndOwner = L1_1
WidgetManager = L0_1
L0_1 = {}
WidgetIdIndex = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = pairs
  L1_2 = WidgetManager
  L1_2 = L1_2.WidgetList
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = L4_2.BasicData
    L5_2 = L5_2.type
    if "text" == L5_2 then
      L5_2 = PushWidgetToFront
      L6_2 = L4_2
      L5_2(L6_2)
    end
  end
end

PushAllTextToFront = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = WidgetManager
  L1_2 = L1_2.AddWidget
  L2_2 = A0_2
  L1_2(L2_2)
end

AddWidget = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = WidgetManager
  L1_2 = L1_2.AddWidget
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = type
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    if "table" == L7_2 then
      L7_2 = AddWidgetWithChildren
      L8_2 = L6_2
      L7_2(L8_2)
    end
  end
end

AddWidgetWithChildren = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = WidgetManager
  L1_2 = L1_2.RemoveWidget
  L2_2 = A0_2
  L1_2(L2_2)
end

RemoveWidget = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = WidgetManager
  L1_2 = L1_2.RemoveWidget
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = type
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    if "table" == L7_2 then
      L7_2 = RemoveWidgetWithChildren
      L8_2 = L6_2
      L7_2(L8_2)
    end
  end
end

RemoveWidgetWithChildren = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.PushWidgetToFront
  if L1_2 then
    L1_2 = _GuiInternal
    L1_2 = L1_2.PushWidgetToFront
    L2_2 = A0_2.BasicData
    L2_2 = L2_2.uId
    L1_2(L2_2)
  end
end

PushWidgetToFront = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.PushWidgetToBack
  if L1_2 then
    L1_2 = _GuiInternal
    L1_2 = L1_2.PushWidgetToBack
    L2_2 = A0_2.BasicData
    L2_2 = L2_2.uId
    L1_2(L2_2)
  end
end

PushWidgetToBack = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = WidgetManager
  L1_2 = L1_2.GetWidgetByName
  L2_2 = A0_2
  return L1_2(L2_2)
end

GetWidgetByName = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = WidgetManager
  L1_2 = L1_2.GetAllWidgetsByName
  L2_2 = A0_2
  return L1_2(L2_2)
end

GetAllWidgetsByName = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = WidgetManager
  L2_2 = L2_2.GetWidgetByNameAndOwner
  L3_2 = A0_2
  L4_2 = A1_2
  return L2_2(L3_2, L4_2)
end

GetWidgetByNameAndOwner = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.delete
  L1_2(L2_2)
end

_DestroyWidget = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = {}
  L2_2 = pairs
  L3_2 = WidgetIdIndex
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    if L6_2 then
      L7_2 = L6_2.BasicData
      L7_2 = L7_2.bTransient
      if L7_2 then
        L8_2 = L6_2
        L7_2 = L6_2.GetOwner
        L7_2 = L7_2(L8_2)
        if L7_2 == A0_2 then
          L7_2 = table
          L7_2 = L7_2.insert
          L8_2 = L1_2
          L9_2 = L6_2
          L7_2(L8_2, L9_2)
        end
      end
    end
  end
  L2_2 = ipairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = RemoveWidget
    L8_2 = L6_2
    L7_2(L8_2)
    L8_2 = L6_2
    L7_2 = L6_2.delete
    L7_2(L8_2)
  end
end

DeleteTransientWidgets = L0_1
L0_1 = {}
L1_1 = {}
L1_1.bEnabled = false
L0_1.BasicData = L1_1
L1_1 = {}
L0_1.CustomData = L1_1
L1_1 = {}
L0_1.EventHandlers = L1_1
L1_1 = _DestroyWidget
L0_1.__gc = L1_1
Widget = L0_1
L0_1 = Widget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  if not A1_2 then
    L2_2 = {}
    A1_2 = L2_2
  end
  L2_2 = {}
  L3_2 = _GuiInternal
  L3_2 = L3_2.CreateWidget
  L3_2 = L3_2()
  L2_2.uId = L3_2
  L2_2.bTransient = true
  A1_2.BasicData = L2_2
  L2_2 = {}
  A1_2.CustomData = L2_2
  L2_2 = {}
  A1_2.EventHandlers = L2_2
  L2_2 = setmetatable
  L3_2 = A1_2
  L4_2 = A0_2
  L2_2(L3_2, L4_2)
  A0_2.__index = A0_2
  L2_2 = WidgetIdIndex
  L3_2 = A1_2.BasicData
  L3_2 = L3_2.uId
  L2_2[L3_2] = A1_2
  return A1_2
end

L0_1.new = L1_1
L0_1 = Widget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L3_2 = A0_2
  L2_2 = A0_2.new
  L4_2 = A1_2
  return L2_2(L3_2, L4_2)
end

L0_1.New = L1_1
L0_1 = Widget

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = WidgetIdIndex
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  L1_2[L2_2] = nil
  A0_2.EventCallbackData = nil
  A0_2.EventParamData = nil
  L1_2 = A0_2.BasicData
  L1_2 = L1_2.type
  if "flash" == L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Create
    L2_2 = Event
    L2_2 = L2_2.TimerRelative
    L3_2 = {}
    L4_2 = 1
    L3_2[1] = L4_2
    L4_2 = _GuiInternal
    L4_2 = L4_2.DeleteWidget
    L5_2 = {}
    L6_2 = A0_2.BasicData
    L6_2 = L6_2.uId
    L5_2[1] = L6_2
    L1_2(L2_2, L3_2, L4_2, L5_2)
  else
    L1_2 = _GuiInternal
    L1_2 = L1_2.DeleteWidget
    L2_2 = A0_2.BasicData
    L2_2 = L2_2.uId
    L1_2(L2_2)
  end
end

L0_1.delete = L1_1
L0_1 = Widget

function L1_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.delete
  return L1_2(L2_2)
end

L0_1.Delete = L1_1
L0_1 = Widget

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L8_2 = L6_2
    L7_2 = L6_2.DeleteWithChildren
    L7_2(L8_2)
  end
  L3_2 = A0_2
  L2_2 = A0_2.delete
  L2_2(L3_2)
end

L0_1.DeleteWithChildren = L1_1
L0_1 = Widget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = A0_2.BasicData
  L3_2 = A1_2 or L3_2
  if not A1_2 then
    L3_2 = A0_2.BasicData
    L3_2 = L3_2.name
  end
  L2_2.name = L3_2
end

L0_1.SetName = L1_1
L0_1 = Widget

function L1_1(A0_2)
  local L1_2
  L1_2 = A0_2.BasicData
  L1_2 = L1_2.name
  return L1_2
end

L0_1.GetName = L1_1
L0_1 = Widget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.SetWidgetVisible
  L3_2 = A0_2.BasicData
  L3_2 = L3_2.uId
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
  L2_2 = _GuiInternal
  L2_2 = L2_2.nVersion
  if not L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.GetChildren
    L2_2 = L2_2(L3_2)
    L3_2 = pairs
    L4_2 = L2_2
    L3_2, L4_2, L5_2 = L3_2(L4_2)
    for L6_2, L7_2 in L3_2, L4_2, L5_2 do
      if L7_2 then
        L8_2 = L7_2.SetVisible
        if L8_2 then
          L9_2 = L7_2
          L8_2 = L7_2.SetVisible
          L10_2 = A1_2
          L8_2(L9_2, L10_2)
        end
      end
    end
  end
end

L0_1.SetVisible = L1_1
L0_1 = Widget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.GetWidgetVisible
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  return L1_2(L2_2)
end

L0_1.GetVisible = L1_1
L0_1 = Widget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.SetWidgetSleep
  if L2_2 then
    L2_2 = _GuiInternal
    L2_2 = L2_2.SetWidgetSleep
    L3_2 = A0_2.BasicData
    L3_2 = L3_2.uId
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  end
end

L0_1.SetSleeping = L1_1
L0_1 = Widget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.GetWidgetSleep
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  return L1_2(L2_2)
end

L0_1.GetSleeping = L1_1
L0_1 = Widget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.bImmortalEvents
  if A1_2 ~= L2_2 then
    L2_2 = A0_2.BasicData
    L2_2.bImmortalEvents = A1_2
    L2_2 = A0_2.BasicData
    L2_2 = L2_2.bEnabled
    if L2_2 then
      L3_2 = A0_2
      L2_2 = A0_2.SetEnabled
      L4_2 = false
      L2_2(L3_2, L4_2)
      L3_2 = A0_2
      L2_2 = A0_2.SetEnabled
      L4_2 = true
      L2_2(L3_2, L4_2)
    end
    L3_2 = A0_2
    L2_2 = A0_2.GetChildren
    L2_2 = L2_2(L3_2)
    L3_2 = pairs
    L4_2 = L2_2
    L3_2, L4_2, L5_2 = L3_2(L4_2)
    for L6_2, L7_2 in L3_2, L4_2, L5_2 do
      L9_2 = L7_2
      L8_2 = L7_2.SetUseImmortalEvents
      L10_2 = A1_2
      L8_2(L9_2, L10_2)
    end
  end
end

L0_1.SetUseImmortalEvents = L1_1
L0_1 = Widget

function L1_1(A0_2, A1_2)
  local L2_2
  if not A1_2 then
    L2_2 = A0_2.BasicData
    L2_2.bTransient = nil
  else
    L2_2 = A0_2.BasicData
    L2_2.bTransient = A1_2
  end
end

L0_1.SetTransient = L1_1
L0_1 = {}
L0_1.GuiAmmoUpdate = true
L0_1.GuiMinimapUpdate = true
L0_1.GuiHealthUpdate = true
L0_1.GuiVehicleHealthUpdate = true
L0_1.GuiReticleUpdate = true
L0_1.GuiWeaponEquippedUpdate = true
L0_1.GuiSupportMenuEnter = true
L0_1.GuiPlayerReceiveDamage = true
L0_1.GuiVehicleNameUpdate = true
L0_1.GuiVehicleDisguiseUpdate = true
_tOwnerRequiredEvents = L0_1
L0_1 = Widget

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  if not A1_2 then
    return
  end
  L3_2 = type
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if L3_2 == "string" and "GuiInitialization" == A1_2 then
    L3_2 = A0_2.EventHandlers
    L3_2.GuiInitialization = A2_2
  else
    L3_2 = type
    L4_2 = A1_2
    L3_2 = L3_2(L4_2)
    if L3_2 == "string" and "GuiUpdate" == A1_2 then
      L3_2 = A0_2.EventHandlers
      L3_2[A1_2] = A2_2
      L3_2 = _GuiInternal
      L3_2 = L3_2.SetWidgetUpdateCallback
      L4_2 = A0_2.BasicData
      L4_2 = L4_2.uId
      L5_2 = A2_2
      L6_2 = {}
      L7_2 = A0_2
      L6_2[1] = L7_2
      L3_2(L4_2, L5_2, L6_2)
    else
      L3_2 = type
      L4_2 = A1_2
      L3_2 = L3_2(L4_2)
      if L3_2 == "string" then
        L3_2 = type
        L4_2 = Event
        L4_2 = L4_2[A1_2]
        L3_2 = L3_2(L4_2)
        if "nil" ~= L3_2 then
          L3_2 = A0_2.EventHandlers
          L3_2[A1_2] = A2_2
          L3_2 = A0_2.EventHandlerData
          if L3_2 then
            L3_2 = A0_2.EventHandlerData
            L3_2 = L3_2[A1_2]
            if nil ~= L3_2 then
              L3_2 = Event
              L3_2 = L3_2.Delete
              L4_2 = A0_2.EventHandlerData
              L4_2 = L4_2[A1_2]
              L3_2(L4_2)
              L3_2 = A0_2.EventHandlerData
              L3_2[A1_2] = nil
            end
          end
          if not A2_2 then
            return
          end
          L3_2 = _tOwnerRequiredEvents
          L3_2 = L3_2[A1_2]
          if L3_2 then
            L4_2 = A0_2
            L3_2 = A0_2.GetOwner
            L3_2 = L3_2(L4_2)
            if not L3_2 then
              return
            end
          end
          L3_2 = A0_2.BasicData
          L3_2 = L3_2.bEnabled
          if L3_2 then
            L3_2 = A0_2.EventHandlerData
            if not L3_2 then
              L3_2 = {}
            end
            A0_2.EventHandlerData = L3_2
            L3_2 = A0_2.EventCallbackData
            if not L3_2 then
              L3_2 = {}
              L4_2 = A0_2
              L3_2[1] = L4_2
            end
            A0_2.EventCallbackData = L3_2
            L3_2 = A0_2.EventParamData
            if not L3_2 then
              L3_2 = {}
              L4_2 = A0_2.BasicData
              L4_2 = L4_2.uOwnerGuid
              L3_2[1] = L4_2
            end
            A0_2.EventParamData = L3_2
            L3_2 = A0_2.EventHandlerData
            L4_2 = Event
            L4_2 = L4_2.CreatePersistent
            L5_2 = Event
            L5_2 = L5_2[A1_2]
            L6_2 = A0_2.EventParamData
            L7_2 = A2_2
            L8_2 = A0_2.EventCallbackData
            L9_2 = A0_2.BasicData
            L9_2 = L9_2.bImmortalEvents
            L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
            L3_2[A1_2] = L4_2
          end
      end
      else
        L3_2 = A1_2
        if L3_2 then
          if A2_2 then
            L4_2 = A0_2.EventHandlers
            L4_2 = L4_2[L3_2]
            if not L4_2 then
              L4_2 = WidgetManager
              L4_2 = L4_2.WidgetEventIndex
              L4_2 = L4_2[L3_2]
              if L4_2 == nil then
                L4_2 = WidgetManager
                L4_2 = L4_2.WidgetEventIndex
                L5_2 = {}
                L4_2[L3_2] = L5_2
              end
              L4_2 = table
              L4_2 = L4_2.insert
              L5_2 = WidgetManager
              L5_2 = L5_2.WidgetEventIndex
              L5_2 = L5_2[L3_2]
              L6_2 = A0_2
              L4_2(L5_2, L6_2)
            end
          end
          if not A2_2 and L3_2 then
            L4_2 = WidgetManager
            L4_2 = L4_2.WidgetEventIndex
            L4_2 = L4_2[L3_2]
            if L4_2 then
              L4_2 = pairs
              L5_2 = WidgetManager
              L5_2 = L5_2.WidgetEventIndex
              L5_2 = L5_2[L3_2]
              L4_2, L5_2, L6_2 = L4_2(L5_2)
              for L7_2, L8_2 in L4_2, L5_2, L6_2 do
                if L8_2 == A0_2 then
                  L9_2 = table
                  L9_2 = L9_2.remove
                  L10_2 = WidgetManager
                  L10_2 = L10_2.WidgetEventIndex
                  L10_2 = L10_2[L3_2]
                  L11_2 = L7_2
                  L9_2(L10_2, L11_2)
                end
              end
            end
          end
          L4_2 = A0_2.EventHandlers
          L4_2[L3_2] = A2_2
        end
      end
    end
  end
end

L0_1.SetEventHandler = L1_1
L0_1 = Widget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = {}
  A0_2.AnimationPoints = L1_2
  L1_2 = {}
  L2_2 = {}
  L1_2.tPointQueue = L2_2
  L1_2.fCompletion = nil
  L2_2 = {}
  L1_2.tCompletionData = L2_2
  L1_2.bAnimating = false
  A0_2.AnimationData = L1_2
end

L0_1._InitAnimationData = L1_1
L0_1 = Widget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2.AnimationData
  if not L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2._InitAnimationData
    L2_2(L3_2)
  end
  L2_2 = table
  L2_2 = L2_2.getn
  L3_2 = A0_2.AnimationPoints
  L2_2 = L2_2(L3_2)
  L2_2 = L2_2 + 1
  L3_2 = {}
  L4_2 = A1_2.RedLevel
  L3_2.RedLevel = L4_2
  L4_2 = A1_2.GreenLevel
  L3_2.GreenLevel = L4_2
  L4_2 = A1_2.BlueLevel
  L3_2.BlueLevel = L4_2
  L4_2 = A1_2.TranslucencyLevel
  L3_2.TranslucencyLevel = L4_2
  L4_2 = A1_2.nAnimationTime
  if not L4_2 then
    L4_2 = 0
  end
  L3_2.nAnimationTime = L4_2
  L4_2 = A1_2.nU1
  L3_2.nU1 = L4_2
  L4_2 = A1_2.nV1
  L3_2.nV1 = L4_2
  L4_2 = A1_2.nU2
  L3_2.nU2 = L4_2
  L4_2 = A1_2.nV2
  L3_2.nV2 = L4_2
  L4_2 = A1_2.nRotation
  L3_2.nRotation = L4_2
  L4_2 = A1_2.nRotationDirection
  L3_2.nRotationDirection = L4_2
  L4_2 = A1_2.x
  if not L4_2 then
    L4_2 = A1_2.x1
  end
  L3_2.nX1 = L4_2
  L4_2 = A1_2.y
  if not L4_2 then
    L4_2 = A1_2.y1
  end
  L3_2.nY1 = L4_2
  L4_2 = A1_2.x2
  if not L4_2 then
    L4_2 = A1_2.x1
  end
  L3_2.nX2 = L4_2
  L4_2 = A1_2.y2
  if not L4_2 then
    L4_2 = A1_2.y1
  end
  L3_2.nY2 = L4_2
  L4_2 = A1_2.x
  if not L4_2 then
    L4_2 = A1_2.x1
    if L4_2 then
      L4_2 = A1_2.x2
      if not L4_2 then
        L3_2.nX2 = nil
      end
    end
  end
  L4_2 = A1_2.y
  if not L4_2 then
    L4_2 = A1_2.y1
    if L4_2 then
      L4_2 = A1_2.y2
      if not L4_2 then
        L3_2.nY2 = nil
      end
    end
  end
  L4_2 = table
  L4_2 = L4_2.insert
  L5_2 = A0_2.AnimationPoints
  L6_2 = L3_2
  L4_2(L5_2, L6_2)
  return L2_2
end

L0_1.AddAnimationPoint = L1_1
L0_1 = Widget

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  L3_2 = type
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if "number" ~= L3_2 then
    return
  end
  L3_2 = type
  L4_2 = A2_2
  L3_2 = L3_2(L4_2)
  if "table" ~= L3_2 then
    return
  end
  L3_2 = A0_2.AnimationData
  if not L3_2 then
    L4_2 = A0_2
    L3_2 = A0_2._InitAnimationData
    L3_2(L4_2)
  end
  L3_2 = {}
  L4_2 = A2_2.RedLevel
  L3_2.RedLevel = L4_2
  L4_2 = A2_2.GreenLevel
  L3_2.GreenLevel = L4_2
  L4_2 = A2_2.BlueLevel
  L3_2.BlueLevel = L4_2
  L4_2 = A2_2.TranslucencyLevel
  L3_2.TranslucencyLevel = L4_2
  L4_2 = A2_2.nAnimationTime
  if not L4_2 then
    L4_2 = 0
  end
  L3_2.nAnimationTime = L4_2
  L4_2 = A2_2.nU1
  L3_2.nU1 = L4_2
  L4_2 = A2_2.nV1
  L3_2.nV1 = L4_2
  L4_2 = A2_2.nU2
  L3_2.nU2 = L4_2
  L4_2 = A2_2.nV2
  L3_2.nV2 = L4_2
  L4_2 = A2_2.nRotation
  L3_2.nRotation = L4_2
  L4_2 = A2_2.nRotationDirection
  L3_2.nRotationDirection = L4_2
  L4_2 = A2_2.x
  if not L4_2 then
    L4_2 = A2_2.x1
  end
  L3_2.nX1 = L4_2
  L4_2 = A2_2.y
  if not L4_2 then
    L4_2 = A2_2.y1
  end
  L3_2.nY1 = L4_2
  L4_2 = A2_2.x2
  if not L4_2 then
    L4_2 = A2_2.x1
  end
  L3_2.nX2 = L4_2
  L4_2 = A2_2.y2
  if not L4_2 then
    L4_2 = A2_2.y1
  end
  L3_2.nY2 = L4_2
  L4_2 = A2_2.x
  if not L4_2 then
    L4_2 = A2_2.x1
    if L4_2 then
      L4_2 = A2_2.x2
      if not L4_2 then
        L3_2.nX2 = nil
      end
    end
  end
  L4_2 = A2_2.y
  if not L4_2 then
    L4_2 = A2_2.y1
    if L4_2 then
      L4_2 = A2_2.y2
      if not L4_2 then
        L3_2.nY2 = nil
      end
    end
  end
  L4_2 = A0_2.AnimationPoints
  L4_2[A1_2] = L3_2
end

L0_1.SetAnimationPoint = L1_1
L0_1 = Widget

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2)
  local L7_2, L8_2, L9_2, L10_2, L11_2
  L7_2 = type
  L8_2 = A1_2
  L7_2 = L7_2(L8_2)
  if "number" ~= L7_2 then
    return
  end
  L7_2 = type
  L8_2 = A0_2.AnimationPoints
  L8_2 = L8_2[A1_2]
  L7_2 = L7_2(L8_2)
  if "table" ~= L7_2 then
    return
  end
  L7_2 = A0_2.AnimationData
  if not L7_2 then
    return
  end
  L7_2 = A0_2.AnimationPoints
  L7_2 = L7_2[A1_2]
  L8_2 = ValidateParameter
  L9_2 = A2_2
  L10_2 = "number"
  L11_2 = L7_2.nAnimationTime
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  A2_2 = L8_2
  L8_2 = ValidateParameter
  L9_2 = A2_2
  L10_2 = "number"
  L11_2 = 0
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  A2_2 = L8_2
  L8_2 = ValidateParameter
  L9_2 = A4_2
  L10_2 = "function"
  L11_2 = nil
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  A4_2 = L8_2
  L8_2 = ValidateParameter
  L9_2 = A5_2
  L10_2 = "table"
  L11_2 = nil
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  A5_2 = L8_2
  L8_2 = ValidateParameter
  L9_2 = A6_2
  L10_2 = "number"
  L11_2 = nil
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  A6_2 = L8_2
  L7_2.nAnimationTime = A2_2
  L8_2 = ValidateParameter
  L9_2 = A3_2
  L10_2 = "boolean"
  L11_2 = false
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  A3_2 = L8_2
  if A3_2 then
    L8_2 = A0_2.AnimationData
    L9_2 = {}
    L8_2.tPointQueue = L9_2
    L8_2 = A0_2.AnimationData
    L8_2.nTimeRemaining = -1
    L8_2 = A0_2.AnimationData
    L8_2.fCompletion = nil
    L8_2 = A0_2.AnimationData
    L8_2.bAnimating = false
  end
  L8_2 = {}
  L8_2.nPoint = A1_2
  L8_2.fCompletion = A4_2
  L8_2.tCompletionData = A5_2
  L8_2.nElapsedTime = A6_2
  L9_2 = table
  L9_2 = L9_2.insert
  L10_2 = A0_2.AnimationData
  L10_2 = L10_2.tPointQueue
  L11_2 = L8_2
  L9_2(L10_2, L11_2)
  L9_2 = A0_2.AnimationData
  L9_2 = L9_2.bAnimating
  if not L9_2 then
    L9_2 = _HandleAnimationComplete
    L10_2 = A0_2
    L9_2(L10_2)
  end
  L9_2 = A0_2.AnimationData
  L9_2.bAnimating = true
end

L0_1.AnimateToPoint = L1_1
L0_1 = Widget

function L1_1(A0_2)
  local L1_2
  L1_2 = A0_2.AnimationData
  if L1_2 then
    L1_2 = A0_2.AnimationData
    L1_2 = L1_2.bAnimating
  end
  return L1_2
end

L0_1.IsAnimating = L1_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2
  L1_2 = A0_2.AnimationData
  L1_2 = L1_2.bHandlingAnimationComplete
  if L1_2 then
    return
  end
  L1_2 = A0_2.AnimationData
  L1_2.bHandlingAnimationComplete = true
  L1_2 = A0_2.AnimationData
  L1_2 = L1_2.fCompletion
  if L1_2 then
    L1_2 = A0_2.AnimationData
    L1_2 = L1_2.tCompletionData
    if not L1_2 then
      L1_2 = {}
    end
    L2_2 = table
    L2_2 = L2_2.insert
    L3_2 = L1_2
    L4_2 = 1
    L5_2 = A0_2
    L2_2(L3_2, L4_2, L5_2)
    L2_2 = A0_2.AnimationData
    L2_2 = L2_2.fCompletion
    L3_2 = unpack
    L4_2 = L1_2
    L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2 = L3_2(L4_2)
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2)
  end
  L1_2 = A0_2.AnimationData
  L1_2.fCompletion = nil
  L1_2 = A0_2.AnimationData
  L1_2.tCompletionData = nil
  L1_2 = nil
  L2_2 = nil
  while not L1_2 do
    L3_2 = table
    L3_2 = L3_2.getn
    L4_2 = A0_2.AnimationData
    L4_2 = L4_2.tPointQueue
    L3_2 = L3_2(L4_2)
    if L3_2 < 1 then
      L3_2 = A0_2.AnimationData
      L3_2.bAnimating = false
      L3_2 = A0_2.AnimationData
      L3_2.bHandlingAnimationComplete = nil
      return
    end
    L3_2 = A0_2.AnimationData
    L3_2 = L3_2.tPointQueue
    L3_2 = L3_2[1]
    if L3_2 then
      L3_2 = A0_2.AnimationData
      L3_2 = L3_2.tPointQueue
      L3_2 = L3_2[1]
      L1_2 = L3_2.nPoint
    end
    L3_2 = A0_2.AnimationPoints
    L3_2 = L3_2[L1_2]
    if not L3_2 then
      L1_2 = nil
    end
    L3_2 = A0_2.AnimationData
    L4_2 = A0_2.AnimationData
    L4_2 = L4_2.tPointQueue
    L4_2 = L4_2[1]
    L4_2 = L4_2.fCompletion
    L3_2.fCompletion = L4_2
    L3_2 = A0_2.AnimationData
    L4_2 = A0_2.AnimationData
    L4_2 = L4_2.tPointQueue
    L4_2 = L4_2[1]
    L4_2 = L4_2.tCompletionData
    L3_2.tCompletionData = L4_2
    L3_2 = A0_2.AnimationData
    L3_2 = L3_2.tPointQueue
    L3_2 = L3_2[1]
    L2_2 = L3_2.nElapsedTime
    L3_2 = table
    L3_2 = L3_2.remove
    L4_2 = A0_2.AnimationData
    L4_2 = L4_2.tPointQueue
    L5_2 = 1
    L3_2(L4_2, L5_2)
  end
  L3_2 = A0_2.AnimationPoints
  L3_2 = L3_2[L1_2]
  L4_2 = A0_2.AnimationData
  L4_2.bAnimating = true
  L5_2 = A0_2
  L4_2 = A0_2.GetLocation
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  L8_2 = false
  L9_2 = L3_2.nX1
  if L9_2 then
    L9_2 = L3_2.nY1
    if L9_2 then
      L9_2 = L3_2.nX2
      if not L9_2 then
        L9_2 = L3_2.nY2
        if not L9_2 then
          L8_2 = true
        end
      end
    end
  end
  if L8_2 then
    L9_2 = _GuiInternal
    L9_2 = L9_2.InterpolateWidget
    L10_2 = A0_2.BasicData
    L10_2 = L10_2.uId
    L11_2 = L3_2.nAnimationTime
    L12_2 = L3_2.nX1
    if not L12_2 then
      L12_2 = L4_2
    end
    L13_2 = L3_2.nY1
    if not L13_2 then
      L13_2 = L5_2
    end
    L14_2 = nil
    L15_2 = nil
    L16_2 = L3_2.RedLevel
    if not L16_2 then
      L16_2 = -4096
    end
    L17_2 = L3_2.GreenLevel
    if not L17_2 then
      L17_2 = -4096
    end
    L18_2 = L3_2.BlueLevel
    if not L18_2 then
      L18_2 = -4096
    end
    L19_2 = L3_2.TranslucencyLevel
    if not L19_2 then
      L19_2 = -4096
    end
    L20_2 = _HandleAnimationComplete
    L21_2 = {}
    L22_2 = A0_2
    L21_2[1] = L22_2
    L22_2 = L3_2.nU1
    L23_2 = L3_2.nV1
    L24_2 = L3_2.nU2
    L25_2 = L3_2.nV2
    L26_2 = L3_2.nRotation
    L27_2 = L3_2.nRotationDirection
    L28_2 = L2_2
    L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2)
  else
    L9_2 = _GuiInternal
    L9_2 = L9_2.InterpolateWidget
    L10_2 = A0_2.BasicData
    L10_2 = L10_2.uId
    L11_2 = L3_2.nAnimationTime
    L12_2 = L3_2.nX1
    if not L12_2 then
      L12_2 = L4_2
    end
    L13_2 = L3_2.nY1
    if not L13_2 then
      L13_2 = L5_2
    end
    L14_2 = L3_2.nX2
    if not L14_2 then
      L14_2 = L6_2
    end
    L15_2 = L3_2.nY2
    if not L15_2 then
      L15_2 = L7_2
    end
    L16_2 = L3_2.RedLevel
    if not L16_2 then
      L16_2 = -4096
    end
    L17_2 = L3_2.GreenLevel
    if not L17_2 then
      L17_2 = -4096
    end
    L18_2 = L3_2.BlueLevel
    if not L18_2 then
      L18_2 = -4096
    end
    L19_2 = L3_2.TranslucencyLevel
    if not L19_2 then
      L19_2 = -4096
    end
    L20_2 = _HandleAnimationComplete
    L21_2 = {}
    L22_2 = A0_2
    L21_2[1] = L22_2
    L22_2 = L3_2.nU1
    L23_2 = L3_2.nV1
    L24_2 = L3_2.nU2
    L25_2 = L3_2.nV2
    L26_2 = L3_2.nRotation
    L27_2 = L3_2.nRotationDirection
    L28_2 = L2_2
    L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2)
  end
  L9_2 = A0_2.AnimationData
  L9_2.bHandlingAnimationComplete = nil
end

_HandleAnimationComplete = L0_1
L0_1 = Widget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.bEnabled
  if A1_2 == L2_2 then
    return
  end
  if A1_2 then
    L2_2 = pairs
    L3_2 = A0_2.EventHandlers
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2 in L2_2, L3_2, L4_2 do
      L6_2 = Event
      L6_2 = L6_2[L5_2]
      if L6_2 then
        L6_2 = _tOwnerRequiredEvents
        L6_2 = L6_2[L5_2]
        if L6_2 then
          L7_2 = A0_2
          L6_2 = A0_2.GetOwner
          L6_2 = L6_2(L7_2)
          L6_2 = not L6_2
          if L6_2 then
            goto lbl_48
          end
        end
        L6_2 = A0_2.EventHandlerData
        if not L6_2 then
          L6_2 = {}
        end
        A0_2.EventHandlerData = L6_2
        L6_2 = A0_2.EventHandlerData
        L7_2 = Event
        L7_2 = L7_2.CreatePersistent
        L8_2 = Event
        L8_2 = L8_2[L5_2]
        L9_2 = {}
        L10_2 = A0_2.BasicData
        L10_2 = L10_2.uOwnerGuid
        L9_2[1] = L10_2
        L10_2 = A0_2.EventHandlers
        L10_2 = L10_2[L5_2]
        L11_2 = {}
        L12_2 = A0_2
        L11_2[1] = L12_2
        L12_2 = A0_2.BasicData
        L12_2 = L12_2.bImmortalEvents
        L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
        L6_2[L5_2] = L7_2
      end
      ::lbl_48::
    end
  else
    L2_2 = A0_2.EventHandlerData
    if L2_2 then
      L2_2 = pairs
      L3_2 = A0_2.EventHandlerData
      L2_2, L3_2, L4_2 = L2_2(L3_2)
      for L5_2 in L2_2, L3_2, L4_2 do
        L6_2 = A0_2.EventHandlerData
        L6_2 = L6_2[L5_2]
        if nil ~= L6_2 then
          L6_2 = Event
          L6_2 = L6_2.Delete
          L7_2 = A0_2.EventHandlerData
          L7_2 = L7_2[L5_2]
          L6_2(L7_2)
          L6_2 = A0_2.EventHandlerData
          L6_2[L5_2] = nil
        end
      end
    end
  end
  L2_2 = A0_2.BasicData
  L2_2.bEnabled = A1_2
end

L0_1.SetEnabled = L1_1
L0_1 = Widget

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L5_2 = _GuiInternal
  L5_2 = L5_2.SetWidgetLocation
  L6_2 = A0_2.BasicData
  L6_2 = L6_2.uId
  L7_2 = A1_2
  L8_2 = A2_2
  L9_2 = A3_2
  L10_2 = A4_2
  L11_2 = true
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
end

L0_1.SetLocation = L1_1
L0_1 = Widget

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L5_2 = _GuiInternal
  L5_2 = L5_2.GetWidgetLocation
  L6_2 = A0_2.BasicData
  L6_2 = L6_2.uId
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  L9_2 = _GuiInternal
  L9_2 = L9_2.SetWidgetLocation
  L10_2 = A0_2.BasicData
  L10_2 = L10_2.uId
  L11_2 = A1_2 or L11_2
  if not A1_2 then
    L11_2 = L5_2
  end
  L12_2 = A2_2 or L12_2
  if not A2_2 then
    L12_2 = L6_2
  end
  L13_2 = A3_2 or L13_2
  if not A3_2 then
    L13_2 = L7_2
  end
  L14_2 = A4_2 or L14_2
  if not A4_2 then
    L14_2 = L8_2
  end
  L15_2 = false
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
end

L0_1.SetCoordinates = L1_1
L0_1 = Widget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.GetWidgetLocation
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  return L1_2(L2_2)
end

L0_1.GetLocation = L1_1
L0_1 = Widget

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L5_2 = _GuiInternal
  L5_2 = L5_2.SetWidgetCorrectedLocation
  if L5_2 then
    L5_2 = _GuiInternal
    L5_2 = L5_2.SetWidgetCorrectedLocation
    L6_2 = A0_2.BasicData
    L6_2 = L6_2.uId
    L7_2 = A1_2
    L8_2 = A2_2
    L9_2 = A3_2
    L10_2 = A4_2
    return L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  end
end

L0_1.SetCorrectedLocation = L1_1
L0_1 = Widget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.GetWidgetCorrectedLocation
  if L1_2 then
    L1_2 = _GuiInternal
    L1_2 = L1_2.GetWidgetCorrectedLocation
    L2_2 = A0_2.BasicData
    L2_2 = L2_2.uId
    return L1_2(L2_2)
  end
end

L0_1.GetCorrectedLocation = L1_1
L0_1 = Widget

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L6_2 = _GuiInternal
  L6_2 = L6_2.SetWidgetColor
  L7_2 = A0_2.BasicData
  L7_2 = L7_2.uId
  L8_2 = A1_2
  L9_2 = A2_2
  L10_2 = A3_2
  L11_2 = A4_2
  L12_2 = not A5_2
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
end

L0_1.SetColor = L1_1
L0_1 = Widget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.GetWidgetColor
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  return L1_2(L2_2)
end

L0_1.GetColor = L1_1
L0_1 = Widget

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = _GuiInternal
  L3_2 = L3_2.SetWidgetColor
  L4_2 = A0_2.BasicData
  L4_2 = L4_2.uId
  L5_2 = -255
  L6_2 = -255
  L7_2 = -255
  L8_2 = A1_2
  L9_2 = not A2_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
end

L0_1.SetTranslucency = L1_1
L0_1 = Widget

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.GetWidgetColor
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  return L4_2
end

L0_1.GetTranslucency = L1_1
L0_1 = Widget

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = _GuiInternal
  L3_2 = L3_2.GetWidgetAnchoring
  L4_2 = A0_2.BasicData
  L4_2 = L4_2.uId
  L3_2, L4_2 = L3_2(L4_2)
  if "left" == A1_2 then
    L3_2 = -1
  elseif "right" == A1_2 then
    L3_2 = 1
  elseif "center" == A1_2 then
    L3_2 = 0
  end
  if "top" == A2_2 then
    L4_2 = -1
  elseif "bottom" == A2_2 then
    L4_2 = 1
  elseif "center" == A2_2 then
    L4_2 = 0
  end
  L5_2 = _GuiInternal
  L5_2 = L5_2.SetWidgetAnchoring
  L6_2 = A0_2.BasicData
  L6_2 = L6_2.uId
  L7_2 = L3_2
  L8_2 = L4_2
  L5_2(L6_2, L7_2, L8_2)
end

L0_1.SetAnchoring = L1_1
L0_1 = Widget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.SetWidgetFullscreen
  L3_2 = A0_2.BasicData
  L3_2 = L3_2.uId
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

L0_1.SetFullscreen = L1_1
L0_1 = Widget

function L1_1(A0_2)
  local L1_2
  return L1_2
end

L0_1.GetFullscreen = L1_1
L0_1 = Widget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = Widget
  L3_2 = L2_2
  L2_2 = L2_2.new
  L2_2 = L2_2(L3_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetLocation
  L6_2 = A0_2
  L5_2 = A0_2.GetLocation
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L5_2(L6_2)
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetColor
  L6_2 = A0_2
  L5_2 = A0_2.GetColor
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L5_2(L6_2)
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetOwner
  L6_2 = A0_2
  L5_2 = A0_2.GetOwner
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L5_2(L6_2)
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetVisible
  L6_2 = A0_2
  L5_2 = A0_2.GetVisible
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L5_2(L6_2)
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L3_2 = pairs
  L4_2 = A0_2.BasicData
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2 in L3_2, L4_2, L5_2 do
    if L6_2 ~= "uId" then
      L7_2 = L2_2.BasicData
      L8_2 = A0_2.BasicData
      L8_2 = L8_2[L6_2]
      L7_2[L6_2] = L8_2
    end
  end
  L3_2 = L2_2.BasicData
  L3_2.bEnabled = false
  L3_2 = pairs
  L4_2 = A0_2.CustomData
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2 in L3_2, L4_2, L5_2 do
    L7_2 = L2_2.CustomData
    L8_2 = A0_2.CustomData
    L8_2 = L8_2[L6_2]
    L7_2[L6_2] = L8_2
  end
  L3_2 = pairs
  L4_2 = A0_2.EventHandlers
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2 in L3_2, L4_2, L5_2 do
    L8_2 = L2_2
    L7_2 = L2_2.SetEventHandler
    L9_2 = L6_2
    L10_2 = A0_2.EventHandlers
    L10_2 = L10_2[L6_2]
    L7_2(L8_2, L9_2, L10_2)
  end
  L2_2.ParentWidget = A1_2
  L4_2 = A0_2
  L3_2 = A0_2.GetChildren
  L3_2 = L3_2(L4_2)
  L4_2 = pairs
  L5_2 = L3_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    if L8_2 then
      L9_2 = L8_2.Duplicate
      if L9_2 then
        L10_2 = L2_2
        L9_2 = L2_2.AddChild
        L12_2 = L8_2
        L11_2 = L8_2.Duplicate
        L13_2 = L2_2
        L11_2, L12_2, L13_2 = L11_2(L12_2, L13_2)
        L9_2(L10_2, L11_2, L12_2, L13_2)
      end
    end
  end
  L4_2 = pairs
  L5_2 = A0_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2 in L4_2, L5_2, L6_2 do
    L8_2 = type
    L9_2 = A0_2[L7_2]
    L8_2 = L8_2(L9_2)
    if "table" ~= L8_2 and "EventHandlerData" ~= L7_2 then
      L8_2 = A0_2[L7_2]
      L2_2[L7_2] = L8_2
    end
  end
  return L2_2
end

L0_1.Duplicate = L1_1
L0_1 = Widget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  if nil ~= A1_2 then
    L2_2 = type
    L3_2 = A1_2
    L2_2 = L2_2(L3_2)
    if "userdata" ~= L2_2 then
      return
    end
  end
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uOwnerGuid
  if L2_2 == A1_2 then
    return
  end
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uOwnerGuid
  L3_2 = A0_2.BasicData
  L3_2.uOwnerGuid = A1_2
  L3_2 = A0_2.BasicData
  L3_2 = L3_2.name
  if L3_2 then
    if L2_2 then
      L3_2 = WidgetManager
      L3_2 = L3_2.WidgetNamePlayerIndex
      L3_2 = L3_2[L2_2]
      if L3_2 then
        L3_2 = WidgetManager
        L3_2 = L3_2.WidgetNamePlayerIndex
        L3_2 = L3_2[L2_2]
        L4_2 = A0_2.BasicData
        L4_2 = L4_2.name
        L3_2[L4_2] = nil
      end
    end
    L3_2 = A0_2.BasicData
    L3_2 = L3_2.uOwnerGuid
    if L3_2 then
      L3_2 = WidgetManager
      L3_2 = L3_2.WidgetNamePlayerIndex
      L4_2 = A0_2.BasicData
      L4_2 = L4_2.uOwnerGuid
      L3_2 = L3_2[L4_2]
      if not L3_2 then
        L3_2 = WidgetManager
        L3_2 = L3_2.WidgetNamePlayerIndex
        L4_2 = A0_2.BasicData
        L4_2 = L4_2.uOwnerGuid
        L5_2 = {}
        L3_2[L4_2] = L5_2
      end
      L3_2 = WidgetManager
      L3_2 = L3_2.WidgetNamePlayerIndex
      L4_2 = A0_2.BasicData
      L4_2 = L4_2.uOwnerGuid
      L3_2 = L3_2[L4_2]
      L4_2 = A0_2.BasicData
      L4_2 = L4_2.name
      L3_2[L4_2] = A0_2
    end
  end
  L3_2 = A0_2.BasicData
  L3_2 = L3_2.bEnabled
  if L3_2 then
    L4_2 = A0_2
    L3_2 = A0_2.SetEnabled
    L5_2 = false
    L3_2(L4_2, L5_2)
    L4_2 = A0_2
    L3_2 = A0_2.SetEnabled
    L5_2 = true
    L3_2(L4_2, L5_2)
  end
  L3_2 = _GuiInternal
  L3_2 = L3_2.SetWidgetViewport
  L4_2 = A0_2.BasicData
  L4_2 = L4_2.uId
  L5_2 = Player
  L5_2 = L5_2.GetViewportId
  L6_2 = A1_2
  L5_2, L6_2 = L5_2(L6_2)
  L3_2(L4_2, L5_2, L6_2)
end

L0_1.SetOwner = L1_1
L0_1 = Widget

function L1_1(A0_2)
  local L1_2
  L1_2 = A0_2.BasicData
  L1_2 = L1_2.uOwnerGuid
  return L1_2
end

L0_1.GetOwner = L1_1
L0_1 = Widget

function L1_1(A0_2)
  local L1_2
  L1_2 = A0_2.BasicData
  L1_2 = L1_2.type
  return L1_2
end

L0_1.GetType = L1_1
L0_1 = Widget

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.GetWidgetChildren
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  L1_2, L2_2 = L1_2(L2_2)
  L3_2 = Table
  L3_2 = L3_2.Create
  L4_2 = L2_2
  L5_2 = 0
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = pairs
  L5_2 = L1_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = Table
    L9_2 = L9_2.InsertI
    L10_2 = L3_2
    L11_2 = WidgetIdIndex
    L11_2 = L11_2[L8_2]
    L12_2 = L7_2
    L9_2(L10_2, L11_2, L12_2)
  end
  return L3_2
end

L0_1.GetChildren = L1_1
L0_1 = Widget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.AddWidgetChild
  L3_2 = A0_2.BasicData
  L3_2 = L3_2.uId
  L4_2 = A1_2.BasicData
  L4_2 = L4_2.uId
  L2_2(L3_2, L4_2)
end

L0_1.AddChild = L1_1
L0_1 = Widget

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  L3_2 = _GuiInternal
  L3_2 = L3_2.SetWidgetChild
  L4_2 = A0_2.BasicData
  L4_2 = L4_2.uId
  L5_2 = A2_2.BasicData
  L5_2 = L5_2.uId
  L3_2(L4_2, L5_2)
end

L0_1.SetChild = L1_1
L0_1 = Widget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.RemoveWidgetChild
  L3_2 = A0_2.BasicData
  L3_2 = L3_2.uId
  L4_2 = A1_2.BasicData
  L4_2 = L4_2.uId
  L2_2(L3_2, L4_2)
end

L0_1.RemoveChild = L1_1
L0_1 = Widget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.RemoveAllWidgetChildren
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  L1_2(L2_2)
end

L0_1.RemoveAllChildren = L1_1
L0_1 = Widget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.SetWidgetIgnoresPause
  L3_2 = A0_2.BasicData
  L3_2 = L3_2.uId
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

L0_1.SetIgnoresPause = L1_1
L0_1 = Widget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.GetWidgetIgnoresPause
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  return L1_2(L2_2)
end

L0_1.GetIgnoresPause = L1_1
L0_1 = {}
TextWidget = L0_1
L0_1 = TextWidget

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = A1_2 or nil
  if not A1_2 then
    L3_2 = {}
  end
  L4_2 = {}
  L4_2.type = "text"
  L4_2.bEnabled = false
  L5_2 = A2_2 or L5_2
  if not A2_2 then
    L5_2 = _GuiInternal
    L5_2 = L5_2.CreateTextWidget
    L5_2 = L5_2()
  end
  L4_2.uId = L5_2
  L4_2.text = " "
  L4_2.font = "font_16"
  L4_2.bTransient = true
  L3_2.BasicData = L4_2
  L4_2 = {}
  L3_2.CustomData = L4_2
  L4_2 = {}
  L3_2.EventHandlers = L4_2
  L4_2 = setmetatable
  L5_2 = L3_2
  L6_2 = A0_2
  L4_2(L5_2, L6_2)
  A0_2.__index = A0_2
  L4_2 = WidgetIdIndex
  L5_2 = L3_2.BasicData
  L5_2 = L5_2.uId
  L4_2[L5_2] = L3_2
  return L3_2
end

L0_1.new = L1_1
L0_1 = TextWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  if "" == A1_2 then
    A1_2 = " "
  end
  L2_2 = A0_2.BasicData
  L2_2.text = A1_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.SetTextText
  L3_2 = A0_2.BasicData
  L3_2 = L3_2.uId
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

L0_1.SetText = L1_1
L0_1 = TextWidget

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L5_2 = _GuiInternal
  L5_2 = L5_2.SetWidgetLocation
  L6_2 = A0_2.BasicData
  L6_2 = L6_2.uId
  L7_2 = A1_2
  L8_2 = A2_2
  L9_2 = A3_2
  L10_2 = A4_2
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
end

L0_1.SetLocation = L1_1
L0_1 = TextWidget

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L4_2 = A0_2
  L3_2 = A0_2.GetLocation
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.bWraps
  if L7_2 then
    L8_2 = A0_2
    L7_2 = A0_2.SetLocation
    L9_2 = L3_2 + A1_2
    L10_2 = L4_2 + A2_2
    L11_2 = L5_2 + A1_2
    L12_2 = L6_2 + A2_2
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  else
    L8_2 = A0_2
    L7_2 = A0_2.SetLocation
    L9_2 = L3_2 + A1_2
    L10_2 = L4_2 + A2_2
    L7_2(L8_2, L9_2, L10_2)
  end
end

L0_1.OffsetLocation = L1_1
L0_1 = TextWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A0_2.BasicData
  L2_2.font = A1_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.SetTextFont
  L3_2 = A0_2.BasicData
  L3_2 = L3_2.uId
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

L0_1.SetFont = L1_1
L0_1 = TextWidget

function L1_1(A0_2, A1_2)
  local L2_2
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.font
  return L2_2
end

L0_1.GetFont = L1_1
L0_1 = TextWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.SetTextJustification
  L3_2 = A0_2.BasicData
  L3_2 = L3_2.uId
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

L0_1.SetJustification = L1_1
L0_1 = TextWidget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.GetTextJustification
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  return L1_2(L2_2)
end

L0_1.GetJustification = L1_1
L0_1 = TextWidget

function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.CustomData
  L1_2.bWraps = true
  L1_2 = _GuiInternal
  L1_2 = L1_2.SetTextWrapping
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  L3_2 = true
  L1_2(L2_2, L3_2)
end

L0_1.Wrap = L1_1
L0_1 = TextWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A0_2.CustomData
  L2_2.bWraps = A1_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.SetTextWrapping
  L3_2 = A0_2.BasicData
  L3_2 = L3_2.uId
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

L0_1.SetWrapping = L1_1
L0_1 = TextWidget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.GetTextText
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  return L1_2(L2_2)
end

L0_1.GetText = L1_1
L0_1 = TextWidget

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.GetTextWidth
  if L1_2 then
    L1_2 = _GuiInternal
    L1_2 = L1_2.GetTextWidth
    L2_2 = A0_2.BasicData
    L2_2 = L2_2.uId
    return L1_2(L2_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2.GetLocation
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  L4_2 = L3_2 - L1_2
  return L4_2
end

L0_1.GetWidth = L1_1
L0_1 = TextWidget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.GetTextHeight
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  return L1_2(L2_2)
end

L0_1.GetHeight = L1_1
L0_1 = TextWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.SetTextScale
  L3_2 = A0_2.BasicData
  L3_2 = L3_2.uId
  L4_2 = A1_2
  return L2_2(L3_2, L4_2)
end

L0_1.SetScale = L1_1
L0_1 = TextWidget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.GetTextScale
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  return L1_2(L2_2)
end

L0_1.GetScale = L1_1
L0_1 = TextWidget

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.SplitText
  if not L1_2 then
    L1_2 = {}
    L2_2 = A0_2
    L1_2[1] = L2_2
    return L1_2
  end
  L1_2 = {}
  L2_2 = _GuiInternal
  L2_2 = L2_2.SplitText
  L3_2 = A0_2.BasicData
  L3_2 = L3_2.uId
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L2_2(L3_2)
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L1_2[7] = L8_2
  L1_2[8] = L9_2
  L1_2[9] = L10_2
  L1_2[10] = L11_2
  L1_2[11] = L12_2
  L1_2[12] = L13_2
  L2_2 = {}
  L3_2 = pairs
  L4_2 = L1_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = TextWidget
    L9_2 = L8_2
    L8_2 = L8_2.new
    L10_2 = nil
    L11_2 = L7_2
    L8_2 = L8_2(L9_2, L10_2, L11_2)
    L10_2 = L8_2
    L9_2 = L8_2.SetFont
    L12_2 = A0_2
    L11_2 = A0_2.GetFont
    L11_2, L12_2, L13_2 = L11_2(L12_2)
    L9_2(L10_2, L11_2, L12_2, L13_2)
    L10_2 = L8_2
    L9_2 = L8_2.GetName
    L9_2 = L9_2(L10_2)
    if L9_2 then
      L10_2 = L8_2
      L9_2 = L8_2.SetName
      L12_2 = A0_2
      L11_2 = A0_2.GetName
      L11_2 = L11_2(L12_2)
      L12_2 = " line "
      L13_2 = L6_2
      L11_2 = L11_2 .. L12_2 .. L13_2
      L9_2(L10_2, L11_2)
    end
    L9_2 = table
    L9_2 = L9_2.insert
    L10_2 = L2_2
    L11_2 = L8_2
    L9_2(L10_2, L11_2)
  end
  return L2_2
end

L0_1.SplitIntoLines = L1_1
L0_1 = TextWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.AnimateText
  if not L2_2 then
    return
  end
  L2_2 = _GuiInternal
  L2_2 = L2_2.AnimateText
  L3_2 = A0_2.BasicData
  L3_2 = L3_2.uId
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

L0_1.PerformTextAnimation = L1_1
L0_1 = TextWidget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.HaltTextAnimation
  if not L1_2 then
    return
  end
  L1_2 = _GuiInternal
  L1_2 = L1_2.HaltTextAnimation
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  L1_2(L2_2)
end

L0_1.HaltTextAnimation = L1_1
L0_1 = TextWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = TextWidget
  L3_2 = L2_2
  L2_2 = L2_2.new
  L2_2 = L2_2(L3_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetLocation
  L6_2 = A0_2
  L5_2 = A0_2.GetLocation
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L5_2(L6_2)
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetColor
  L6_2 = A0_2
  L5_2 = A0_2.GetColor
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L5_2(L6_2)
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetOwner
  L6_2 = A0_2
  L5_2 = A0_2.GetOwner
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L5_2(L6_2)
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetText
  L6_2 = A0_2
  L5_2 = A0_2.GetText
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L5_2(L6_2)
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetFont
  L6_2 = A0_2
  L5_2 = A0_2.GetFont
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L5_2(L6_2)
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetScale
  L6_2 = A0_2
  L5_2 = A0_2.GetScale
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L5_2(L6_2)
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L3_2 = pairs
  L4_2 = A0_2.BasicData
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2 in L3_2, L4_2, L5_2 do
    if L6_2 ~= "uId" then
      L7_2 = L2_2.BasicData
      L8_2 = A0_2.BasicData
      L8_2 = L8_2[L6_2]
      L7_2[L6_2] = L8_2
    end
  end
  L3_2 = L2_2.BasicData
  L3_2.bEnabled = false
  L3_2 = pairs
  L4_2 = A0_2.CustomData
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2 in L3_2, L4_2, L5_2 do
    L7_2 = L2_2.CustomData
    L8_2 = A0_2.CustomData
    L8_2 = L8_2[L6_2]
    L7_2[L6_2] = L8_2
  end
  L3_2 = pairs
  L4_2 = A0_2.EventHandlers
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2 in L3_2, L4_2, L5_2 do
    L8_2 = L2_2
    L7_2 = L2_2.SetEventHandler
    L9_2 = L6_2
    L10_2 = A0_2.EventHandlers
    L10_2 = L10_2[L6_2]
    L7_2(L8_2, L9_2, L10_2)
  end
  L2_2.ParentWidget = A1_2
  L4_2 = A0_2
  L3_2 = A0_2.GetChildren
  L3_2 = L3_2(L4_2)
  L4_2 = pairs
  L5_2 = L3_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    if L8_2 then
      L9_2 = L8_2.Duplicate
      if L9_2 then
        L10_2 = L2_2
        L9_2 = L2_2.AddChild
        L12_2 = L8_2
        L11_2 = L8_2.Duplicate
        L13_2 = L2_2
        L11_2, L12_2, L13_2 = L11_2(L12_2, L13_2)
        L9_2(L10_2, L11_2, L12_2, L13_2)
      end
    end
  end
  L4_2 = pairs
  L5_2 = A0_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2 in L4_2, L5_2, L6_2 do
    L8_2 = type
    L9_2 = A0_2[L7_2]
    L8_2 = L8_2(L9_2)
    if "table" ~= L8_2 then
      L8_2 = A0_2[L7_2]
      L2_2[L7_2] = L8_2
    end
  end
  return L2_2
end

L0_1.Duplicate = L1_1
L0_1 = {}
ImageWidget = L0_1
L0_1 = ImageWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A1_2 or nil
  if not A1_2 then
    L2_2 = {}
  end
  L3_2 = {}
  L3_2.type = "image"
  L3_2.bEnabled = false
  L4_2 = _GuiInternal
  L4_2 = L4_2.CreateImageWidget
  L4_2 = L4_2()
  L3_2.uId = L4_2
  L3_2.bTransient = true
  L2_2.BasicData = L3_2
  L3_2 = {}
  L2_2.CustomData = L3_2
  L3_2 = {}
  L2_2.EventHandlers = L3_2
  L3_2 = setmetatable
  L4_2 = L2_2
  L5_2 = A0_2
  L3_2(L4_2, L5_2)
  A0_2.__index = A0_2
  L3_2 = WidgetIdIndex
  L4_2 = L2_2.BasicData
  L4_2 = L4_2.uId
  L3_2[L4_2] = L2_2
  return L2_2
end

L0_1.new = L1_1
L0_1 = ImageWidget

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L3_2 = A1_2 or nil
  if not A1_2 then
    L3_2 = 0
  end
  L4_2 = A2_2 or L4_2
  if not A2_2 then
    L4_2 = 0
  end
  L6_2 = A0_2
  L5_2 = A0_2.GetLocation
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  L10_2 = A0_2
  L9_2 = A0_2.SetLocation
  L11_2 = L5_2 + L3_2
  L12_2 = L6_2 + L3_2
  L13_2 = L7_2 + L3_2
  L14_2 = L8_2 + L4_2
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
end

L0_1.OffsetLocation = L1_1
L0_1 = ImageWidget

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L4_2 = A0_2
  L3_2 = A0_2.SetLocation
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
end

L0_1.Move = L1_1
L0_1 = ImageWidget

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L5_2 = _GuiInternal
  L5_2 = L5_2.GetImageTextureCoordinates
  L6_2 = A0_2.BasicData
  L6_2 = L6_2.uId
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  L9_2 = _GuiInternal
  L9_2 = L9_2.SetImageTextureCoordinates
  L10_2 = A0_2.BasicData
  L10_2 = L10_2.uId
  L11_2 = A1_2 or L11_2
  if not A1_2 then
    L11_2 = L5_2
  end
  L12_2 = A2_2 or L12_2
  if not A2_2 then
    L12_2 = L6_2
  end
  L13_2 = A3_2 or L13_2
  if not A3_2 then
    L13_2 = L7_2
  end
  L14_2 = A4_2 or L14_2
  if not A4_2 then
    L14_2 = L8_2
  end
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
end

L0_1.SetTextureCoordinates = L1_1
L0_1 = ImageWidget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.GetImageTextureCoordinates
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  return L1_2(L2_2)
end

L0_1.GetTextureCoordinates = L1_1
L0_1 = ImageWidget

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = _GuiInternal
  L3_2 = L3_2.SetImageTiling
  if L3_2 then
    L3_2 = _GuiInternal
    L3_2 = L3_2.SetImageTiling
    L4_2 = A0_2.BasicData
    L4_2 = L4_2.uId
    L5_2 = A1_2
    L6_2 = A2_2
    L3_2(L4_2, L5_2, L6_2)
  end
end

L0_1.SetTileSize = L1_1
L0_1 = ImageWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A0_2.BasicData
  L2_2.sTextureName = A1_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.SetImageTexture
  L3_2 = A0_2.BasicData
  L3_2 = L3_2.uId
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

L0_1.SetTexture = L1_1
L0_1 = ImageWidget

function L1_1(A0_2)
  local L1_2
  L1_2 = A0_2.BasicData
  L1_2 = L1_2.sTextureName
  return L1_2
end

L0_1.GetTexture = L1_1
L0_1 = ImageWidget

function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2
  L4_2 = A0_2.BasicData
  L4_2.nRotation = A1_2
  L4_2 = _GuiInternal
  L4_2 = L4_2.SetImageRotation
  L5_2 = A0_2.BasicData
  L5_2 = L5_2.uId
  L6_2 = A1_2
  L4_2(L5_2, L6_2)
end

L0_1.SetRotation = L1_1
L0_1 = ImageWidget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.GetImageRotation
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  return L1_2(L2_2)
end

L0_1.GetRotation = L1_1
L0_1 = ImageWidget

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  if not A1_2 then
    A1_2 = 0
  end
  if not A2_2 then
    A2_2 = 10
  end
  L5_2 = _GuiInternal
  L5_2 = L5_2.SetImageClockAnimation
  L6_2 = A0_2.BasicData
  L6_2 = L6_2.uId
  L7_2 = A1_2
  L8_2 = A2_2
  L9_2 = A3_2
  L10_2 = A4_2
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
end

L0_1.SetClockAnimation = L1_1
L0_1 = ImageWidget

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = _GuiInternal
  L3_2 = L3_2.SetImageClockCallback
  L4_2 = A0_2.BasicData
  L4_2 = L4_2.uId
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
end

L0_1.SetClockAnimationCallback = L1_1
L0_1 = ImageWidget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.GetImageClockElapsed
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  return L1_2(L2_2)
end

L0_1.GetClockElapsedTime = L1_1
L0_1 = ImageWidget

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = _GuiInternal
  L3_2 = L3_2.SetImagePieSliceRender
  if L3_2 then
    L3_2 = _GuiInternal
    L3_2 = L3_2.SetImagePieSliceRender
    L4_2 = A0_2.BasicData
    L4_2 = L4_2.uId
    L5_2 = A1_2
    L6_2 = A2_2
    L3_2(L4_2, L5_2, L6_2)
  end
end

L0_1.SetPieSliceRender = L1_1
L0_1 = ImageWidget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.DisableImagePieSliceRender
  if L1_2 then
    L1_2 = _GuiInternal
    L1_2 = L1_2.DisableImagePieSliceRender
    L2_2 = A0_2.BasicData
    L2_2 = L2_2.uId
    L1_2(L2_2)
  end
end

L0_1.DisablePieSliceRender = L1_1
L0_1 = ImageWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = ImageWidget
  L3_2 = L2_2
  L2_2 = L2_2.new
  L2_2 = L2_2(L3_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetLocation
  L6_2 = A0_2
  L5_2 = A0_2.GetLocation
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L5_2(L6_2)
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetColor
  L6_2 = A0_2
  L5_2 = A0_2.GetColor
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L5_2(L6_2)
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetOwner
  L6_2 = A0_2
  L5_2 = A0_2.GetOwner
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L5_2(L6_2)
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetTexture
  L6_2 = A0_2
  L5_2 = A0_2.GetTexture
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L5_2(L6_2)
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetTextureCoordinates
  L6_2 = A0_2
  L5_2 = A0_2.GetTextureCoordinates
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L5_2(L6_2)
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L3_2 = pairs
  L4_2 = A0_2.BasicData
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2 in L3_2, L4_2, L5_2 do
    if L6_2 ~= "uId" then
      L7_2 = L2_2.BasicData
      L8_2 = A0_2.BasicData
      L8_2 = L8_2[L6_2]
      L7_2[L6_2] = L8_2
    end
  end
  L3_2 = L2_2.BasicData
  L3_2.bEnabled = false
  L3_2 = pairs
  L4_2 = A0_2.CustomData
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2 in L3_2, L4_2, L5_2 do
    L7_2 = L2_2.CustomData
    L8_2 = A0_2.CustomData
    L8_2 = L8_2[L6_2]
    L7_2[L6_2] = L8_2
  end
  L3_2 = pairs
  L4_2 = A0_2.EventHandlers
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2 in L3_2, L4_2, L5_2 do
    L8_2 = L2_2
    L7_2 = L2_2.SetEventHandler
    L9_2 = L6_2
    L10_2 = A0_2.EventHandlers
    L10_2 = L10_2[L6_2]
    L7_2(L8_2, L9_2, L10_2)
  end
  L2_2.ParentWidget = A1_2
  L4_2 = A0_2
  L3_2 = A0_2.GetChildren
  L3_2 = L3_2(L4_2)
  L4_2 = pairs
  L5_2 = L3_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    if L8_2 then
      L9_2 = L8_2.Duplicate
      if L9_2 then
        L10_2 = L2_2
        L9_2 = L2_2.AddChild
        L12_2 = L8_2
        L11_2 = L8_2.Duplicate
        L13_2 = L2_2
        L11_2, L12_2, L13_2 = L11_2(L12_2, L13_2)
        L9_2(L10_2, L11_2, L12_2, L13_2)
      end
    end
  end
  L4_2 = pairs
  L5_2 = A0_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2 in L4_2, L5_2, L6_2 do
    L8_2 = type
    L9_2 = A0_2[L7_2]
    L8_2 = L8_2(L9_2)
    if "table" ~= L8_2 then
      L8_2 = A0_2[L7_2]
      L2_2[L7_2] = L8_2
    end
  end
  return L2_2
end

L0_1.Duplicate = L1_1
L0_1 = {}
FlashWidget = L0_1
L0_1 = FlashWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.CreateFlashWidget
  if L2_2 then
    L2_2 = A1_2 or L2_2
    if not A1_2 then
      L2_2 = {}
    end
    L3_2 = {}
    L3_2.type = "flash"
    L3_2.bEnabled = false
    L4_2 = _GuiInternal
    L4_2 = L4_2.CreateFlashWidget
    L4_2 = L4_2()
    L3_2.uId = L4_2
    L3_2.bTransient = true
    L2_2.BasicData = L3_2
    L3_2 = {}
    L2_2.CustomData = L3_2
    L3_2 = {}
    L2_2.EventHandlers = L3_2
    L3_2 = setmetatable
    L4_2 = L2_2
    L5_2 = A0_2
    L3_2(L4_2, L5_2)
    A0_2.__index = A0_2
    L3_2 = WidgetIdIndex
    L4_2 = L2_2.BasicData
    L4_2 = L4_2.uId
    L3_2[L4_2] = L2_2
    L4_2 = L2_2
    L3_2 = L2_2.SetEventHandler
    L5_2 = "ControllerInput"
    L6_2 = _HandleInputForFlashWidget
    L3_2(L4_2, L5_2, L6_2)
    return L2_2
  else
    L2_2 = Widget
    L3_2 = L2_2
    L2_2 = L2_2.new
    L4_2 = A1_2
    return L2_2(L3_2, L4_2)
  end
end

L0_1.new = L1_1
L0_1 = FlashWidget

function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  L4_2 = A0_2.BasicData
  L4_2.sSwfName = A1_2
  L4_2 = _GuiInternal
  L4_2 = L4_2.SetFlashSwfFile
  L5_2 = A0_2.BasicData
  L5_2 = L5_2.uId
  L6_2 = A1_2
  L7_2 = A2_2
  L8_2 = A3_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
end

L0_1.SetSwfFile = L1_1
L0_1 = FlashWidget

function L1_1(A0_2)
  local L1_2
  L1_2 = A0_2.BasicData
  L1_2 = L1_2.sSwfName
  return L1_2
end

L0_1.GetSwfFile = L1_1
L0_1 = FlashWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.SetFlashPlaySpeed
  if L2_2 then
    L2_2 = _GuiInternal
    L2_2 = L2_2.SetFlashPlaySpeed
    L3_2 = A0_2.BasicData
    L3_2 = L3_2.uId
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  end
end

L0_1.SetPlaySpeed = L1_1
L0_1 = FlashWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.GetFlashPlaySpeed
  if L2_2 then
    L2_2 = _GuiInternal
    L2_2 = L2_2.GetFlashPlaySpeed
    L3_2 = A0_2.BasicData
    L3_2 = L3_2.uId
    L4_2 = A1_2
    return L2_2(L3_2, L4_2)
  end
end

L0_1.GetPlaySpeed = L1_1
L0_1 = FlashWidget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.PauseFlash
  if L1_2 then
    L1_2 = _GuiInternal
    L1_2 = L1_2.PauseFlash
    L2_2 = A0_2.BasicData
    L2_2 = L2_2.uId
    L1_2(L2_2)
  end
end

L0_1.Pause = L1_1
L0_1 = FlashWidget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.PlayFlash
  if L1_2 then
    L1_2 = _GuiInternal
    L1_2 = L1_2.PlayFlash
    L2_2 = A0_2.BasicData
    L2_2 = L2_2.uId
    L1_2(L2_2)
  end
end

L0_1.Play = L1_1
L0_1 = FlashWidget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.RestartFlash
  if L1_2 then
    L1_2 = _GuiInternal
    L1_2 = L1_2.RestartFlash
    L2_2 = A0_2.BasicData
    L2_2 = L2_2.uId
    L1_2(L2_2)
  end
end

L0_1.Restart = L1_1
L0_1 = FlashWidget

function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L4_2 = _GuiInternal
  L4_2 = L4_2.SetFlashCallback
  if L4_2 then
    L4_2 = _GuiInternal
    L4_2 = L4_2.SetFlashCallback
    L5_2 = A0_2.BasicData
    L5_2 = L5_2.uId
    L6_2 = A1_2
    L7_2 = _FlashCallback
    L8_2 = {}
    L9_2 = A0_2
    L10_2 = A2_2
    L11_2 = A3_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L4_2(L5_2, L6_2, L7_2, L8_2)
  end
end

L0_1.SetFlashEventHandler = L1_1
L0_1 = FlashWidget

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = table
  L3_2 = L3_2.insert
  L4_2 = A2_2
  L5_2 = 1
  L6_2 = A1_2
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = table
  L3_2 = L3_2.insert
  L4_2 = A2_2
  L5_2 = 1
  L6_2 = A0_2.BasicData
  L6_2 = L6_2.uId
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = _GuiInternal
  L3_2 = L3_2.CallFlashScriptFunction
  L4_2 = unpack
  L5_2 = A2_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  L3_2(L4_2, L5_2, L6_2)
end

L0_1.CallActionScriptCallback = L1_1
L0_1 = FlashWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.SetFlashTesselationAllowed
  if L2_2 then
    L2_2 = _GuiInternal
    L2_2 = L2_2.SetFlashTesselationAllowed
    L3_2 = A0_2.BasicData
    L3_2 = L3_2.uId
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  end
end

L0_1.SetTesselationAllowed = L1_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L4_2 = {}
  L5_2 = type
  L6_2 = A2_2
  L5_2 = L5_2(L6_2)
  if "table" == L5_2 then
    L5_2 = ipairs
    L6_2 = A2_2
    L5_2, L6_2, L7_2 = L5_2(L6_2)
    for L8_2, L9_2 in L5_2, L6_2, L7_2 do
      L4_2[L8_2] = L9_2
    end
  end
  L5_2 = type
  L6_2 = A1_2
  L5_2 = L5_2(L6_2)
  if "function" == L5_2 then
    L5_2 = table
    L5_2 = L5_2.insert
    L6_2 = L4_2
    L7_2 = 1
    L8_2 = A3_2
    L5_2(L6_2, L7_2, L8_2)
    L5_2 = table
    L5_2 = L5_2.insert
    L6_2 = L4_2
    L7_2 = 1
    L8_2 = A0_2
    L5_2(L6_2, L7_2, L8_2)
    L5_2 = A1_2
    L6_2 = unpack
    L7_2 = L4_2
    L6_2, L7_2, L8_2, L9_2, L10_2 = L6_2(L7_2)
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  end
end

_FlashCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = pairs
  L3_2 = A1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = string
    L7_2 = L7_2.find
    L8_2 = L5_2
    L9_2 = "ButtonPress"
    L7_2 = L7_2(L8_2, L9_2)
    if L7_2 then
      L7_2 = _GuiInternal
      L7_2 = L7_2.SendFlashInput
      L8_2 = A0_2.BasicData
      L8_2 = L8_2.uId
      L9_2 = L6_2
      L10_2 = "p"
      L7_2(L8_2, L9_2, L10_2)
    else
      L7_2 = string
      L7_2 = L7_2.find
      L8_2 = L5_2
      L9_2 = "ButtonReleased"
      L7_2 = L7_2(L8_2, L9_2)
      if L7_2 then
        L7_2 = _GuiInternal
        L7_2 = L7_2.SendFlashInput
        L8_2 = A0_2.BasicData
        L8_2 = L8_2.uId
        L9_2 = L6_2
        L10_2 = "r"
        L7_2(L8_2, L9_2, L10_2)
      end
    end
  end
end

_HandleInputForFlashWidget = L0_1
L0_1 = FlashWidget

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  if A1_2 and A2_2 then
    L3_2 = _GuiInternal
    L3_2 = L3_2.SendFlashLeftAnalogInput
    if L3_2 then
      L3_2 = _GuiInternal
      L3_2 = L3_2.SendFlashLeftAnalogInput
      L4_2 = A0_2.BasicData
      L4_2 = L4_2.uId
      L5_2 = A1_2
      L6_2 = A2_2
      L3_2(L4_2, L5_2, L6_2)
    end
  end
end

L0_1.HandleLeftAnalogInput = L1_1
L0_1 = FlashWidget

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  if A1_2 and A2_2 then
    L3_2 = _GuiInternal
    L3_2 = L3_2.SendFlashRightAnalogInput
    if L3_2 then
      L3_2 = _GuiInternal
      L3_2 = L3_2.SendFlashRightAnalogInput
      L4_2 = A0_2.BasicData
      L4_2 = L4_2.uId
      L5_2 = A1_2
      L6_2 = A2_2
      L3_2(L4_2, L5_2, L6_2)
    end
  end
end

L0_1.HandleRightAnalogInput = L1_1
L0_1 = {}
SpriteWidget = L0_1
L0_1 = SpriteWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A1_2 or nil
  if not A1_2 then
    L2_2 = {}
  end
  L3_2 = {}
  L3_2.type = "sprite"
  L3_2.bEnabled = false
  L4_2 = _GuiInternal
  L4_2 = L4_2.CreateSpriteWidget
  L4_2 = L4_2()
  L3_2.uId = L4_2
  L3_2.sTextureName = nil
  L3_2.bTransient = true
  L2_2.BasicData = L3_2
  L3_2 = {}
  L2_2.CustomData = L3_2
  L3_2 = {}
  L2_2.EventHandlers = L3_2
  L3_2 = setmetatable
  L4_2 = L2_2
  L5_2 = A0_2
  L3_2(L4_2, L5_2)
  A0_2.__index = A0_2
  L3_2 = WidgetIdIndex
  L4_2 = L2_2.BasicData
  L4_2 = L4_2.uId
  L3_2[L4_2] = L2_2
  return L2_2
end

L0_1.new = L1_1
L0_1 = SpriteWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.SetSpriteTexture
  L3_2 = A0_2.BasicData
  L3_2 = L3_2.uId
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

L0_1.SetTexture = L1_1
L0_1 = SpriteWidget

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = _GuiInternal
  L3_2 = L3_2.SetSpriteTextureSize
  L4_2 = A0_2.BasicData
  L4_2 = L4_2.uId
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
end

L0_1.SetTextureSize = L1_1
L0_1 = SpriteWidget

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = _GuiInternal
  L3_2 = L3_2.SetSpriteFrameSize
  L4_2 = A0_2.BasicData
  L4_2 = L4_2.uId
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
end

L0_1.SetFrameSize = L1_1
L0_1 = SpriteWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.SetSpriteFrame
  L3_2 = A0_2.BasicData
  L3_2 = L3_2.uId
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

L0_1.SetFrame = L1_1
L0_1 = SpriteWidget

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L5_2 = _GuiInternal
  L5_2 = L5_2.AnimateSprite
  L6_2 = A0_2.BasicData
  L6_2 = L6_2.uId
  L7_2 = A1_2
  L8_2 = A2_2
  L9_2 = A3_2
  L10_2 = A4_2
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
end

L0_1.PlayAnimation = L1_1
L0_1 = SpriteWidget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.HaltSpriteAnimation
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  L1_2(L2_2)
end

L0_1.HaltAnimation = L1_1
L0_1 = {}
MovieWidget = L0_1
L0_1 = MovieWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.CreateMovieWidget
  if L2_2 then
    L2_2 = A1_2 or L2_2
    if not A1_2 then
      L2_2 = {}
    end
    L3_2 = {}
    L3_2.type = "movie"
    L3_2.bEnabled = false
    L4_2 = _GuiInternal
    L4_2 = L4_2.CreateMovieWidget
    L4_2 = L4_2()
    L3_2.uId = L4_2
    L3_2.bTransient = true
    L2_2.BasicData = L3_2
    L3_2 = {}
    L2_2.CustomData = L3_2
    L3_2 = {}
    L2_2.EventHandlers = L3_2
    L3_2 = setmetatable
    L4_2 = L2_2
    L5_2 = A0_2
    L3_2(L4_2, L5_2)
    A0_2.__index = A0_2
    L3_2 = WidgetIdIndex
    L4_2 = L2_2.BasicData
    L4_2 = L4_2.uId
    L3_2[L4_2] = L2_2
    return L2_2
  else
    L2_2 = Widget
    L3_2 = L2_2
    L2_2 = L2_2.new
    L4_2 = A1_2
    return L2_2(L3_2, L4_2)
  end
end

L0_1.new = L1_1
L0_1 = MovieWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.SetMovieFile
  L3_2 = A0_2.BasicData
  L3_2 = L3_2.uId
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

L0_1.SetMovie = L1_1
L0_1 = MovieWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.PlayMovie
  L3_2 = A0_2.BasicData
  L3_2 = L3_2.uId
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

L0_1.Play = L1_1
L0_1 = MovieWidget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.StopMovie
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  L1_2(L2_2)
end

L0_1.Stop = L1_1
L0_1 = MovieWidget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.PauseMovie
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  L1_2(L2_2)
end

L0_1.Pause = L1_1
L0_1 = MovieWidget

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = _GuiInternal
  L3_2 = L3_2.SetMovieEndCallback
  L4_2 = A0_2.BasicData
  L4_2 = L4_2.uId
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
end

L0_1.SetEndCallback = L1_1
L0_1 = MovieWidget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _GuiInternal
  L1_2 = L1_2.GetMovieCurrentFrameNumber
  if L1_2 then
    L1_2 = _GuiInternal
    L1_2 = L1_2.GetMovieCurrentFrameNumber
    L2_2 = A0_2.BasicData
    L2_2 = L2_2.uId
    return L1_2(L2_2)
  end
  L1_2 = -1
  return L1_2
end

L0_1.GetCurrentFrame = L1_1
L0_1 = {}
MinimapWidget = L0_1
L0_1 = MinimapWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = Widget
  L2_2 = L2_2.SetOwner
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
  L2_2 = _GuiInternal
  L2_2 = L2_2.SetMinimapOwner
  if L2_2 then
    L2_2 = _GuiInternal
    L2_2 = L2_2.SetMinimapOwner
    L3_2 = A0_2.BasicData
    L3_2 = L3_2.uId
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  end
end

L0_1.SetOwner = L1_1
L0_1 = MinimapWidget

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2, A9_2, A10_2, A11_2, A12_2, A13_2)
  local L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2
  L14_2 = A0_2.BasicData
  L14_2.x = A2_2
  L14_2 = A0_2.BasicData
  L14_2.y = A3_2
  L14_2 = A0_2.BasicData
  L14_2.nRadius = A4_2
  L14_2 = A0_2.BasicData
  L14_2.texture = A5_2
  L14_2 = A0_2.BasicData
  L14_2.name = A1_2
  L14_2 = A0_2.BasicData
  L15_2 = A6_2 or L15_2
  if not A6_2 then
    L15_2 = 512
  end
  L14_2.nTexWidth = L15_2
  L14_2 = A0_2.BasicData
  L15_2 = A7_2 or L15_2
  if not A7_2 then
    L15_2 = -512
  end
  L14_2.nTexHeight = L15_2
  L14_2 = A0_2.BasicData
  L15_2 = A8_2 or L15_2
  if not A8_2 then
    L15_2 = -512
  end
  L14_2.nWorldXMin = L15_2
  L14_2 = A0_2.BasicData
  L15_2 = A9_2 or L15_2
  if not A9_2 then
    L15_2 = 512
  end
  L14_2.nWorldXMax = L15_2
  L14_2 = A0_2.BasicData
  L15_2 = A10_2 or L15_2
  if not A10_2 then
    L15_2 = -512
  end
  L14_2.nWorldZMin = L15_2
  L14_2 = A0_2.BasicData
  L15_2 = A11_2 or L15_2
  if not A11_2 then
    L15_2 = 512
  end
  L14_2.nWorldZMax = L15_2
  L14_2 = A0_2.BasicData
  L15_2 = A12_2 or L15_2
  if not A12_2 then
    L15_2 = "left"
  end
  L14_2.HorizontalAnchor = L15_2
  L14_2 = A0_2.BasicData
  L15_2 = A13_2 or L15_2
  if not A13_2 then
    L15_2 = "top"
  end
  L14_2.VerticalAnchor = L15_2
  L14_2 = A0_2.BasicData
  L14_2.type = "minimap"
  L14_2 = {}
  A0_2.NewObjectiveList = L14_2
  L14_2 = {}
  A0_2.UpdatingObjectiveList = L14_2
  L14_2 = _GuiInternal
  L14_2 = L14_2.MinimapCreate
  L15_2 = A0_2.BasicData
  L15_2 = L15_2.x
  L16_2 = A0_2.BasicData
  L16_2 = L16_2.y
  L17_2 = A0_2.BasicData
  L17_2 = L17_2.nRadius
  L18_2 = A0_2.BasicData
  L18_2 = L18_2.texture
  L19_2 = A0_2.BasicData
  L19_2 = L19_2.nTexWidth
  L20_2 = A0_2.BasicData
  L20_2 = L20_2.nTexHeight
  L21_2 = A0_2.BasicData
  L21_2 = L21_2.HorizontalAnchor
  L22_2 = A0_2.BasicData
  L22_2 = L22_2.VerticalAnchor
  L23_2 = A0_2.BasicData
  L23_2 = L23_2.nWorldXMin
  L24_2 = A0_2.BasicData
  L24_2 = L24_2.nWorldXMax
  L25_2 = A0_2.BasicData
  L25_2 = L25_2.nWorldZMin
  L26_2 = A0_2.BasicData
  L26_2 = L26_2.nWorldZMax
  L14_2 = L14_2(L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2)
  if L14_2 then
    L15_2 = A0_2.BasicData
    L15_2.uId = L14_2
    L15_2 = WidgetIdIndex
    L15_2[L14_2] = A0_2
  end
  L16_2 = A0_2
  L15_2 = A0_2.SetEventHandler
  L17_2 = "GuiMinimapUpdate"
  L18_2 = MinimapDataUpdateHandler
  L15_2(L16_2, L17_2, L18_2)
  L15_2 = WidgetManager
  L15_2 = L15_2.AddWidget
  L16_2 = A0_2
  L15_2(L16_2)
end

L0_1.SetUpMinimap = L1_1
L0_1 = MinimapWidget

function L1_1(A0_2, A1_2, A2_2)
end

L0_1.SetLocation = L1_1
L0_1 = MinimapWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.SetWidgetVisible
  L3_2 = A0_2.BasicData
  L3_2 = L3_2.uId
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    if L7_2 then
      L8_2 = L7_2.SetVisible
      if L8_2 then
        L9_2 = L7_2
        L8_2 = L7_2.SetVisible
        L10_2 = isVisible
        L8_2(L9_2, L10_2)
      end
    end
  end
end

L0_1.SetVisible = L1_1
L0_1 = MinimapWidget

function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  L4_2 = _GuiInternal
  L4_2 = L4_2.MinimapSetPlayerLocation
  L5_2 = A0_2.BasicData
  L5_2 = L5_2.uId
  L6_2 = A1_2
  L7_2 = A2_2
  L8_2 = A3_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
end

L0_1.SetPlayerLocation = L1_1
L0_1 = MinimapWidget

function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  L4_2 = _GuiInternal
  L4_2 = L4_2.MinimapSetFocusLocation
  L5_2 = A0_2.BasicData
  L5_2 = L5_2.uId
  L6_2 = A1_2
  L7_2 = A2_2
  L8_2 = A3_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
end

L0_1.SetFocusLocation = L1_1
L0_1 = MinimapWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.MinimapSetRotation
  L3_2 = A0_2.BasicData
  L3_2 = L3_2.uId
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

L0_1.SetRotation = L1_1
L0_1 = MinimapWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.MinimapSetRange
  L3_2 = A0_2.BasicData
  L3_2 = L3_2.uId
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

L0_1.SetRange = L1_1
L0_1 = MinimapWidget

function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  L4_2 = _GuiInternal
  L4_2 = L4_2.SetMinimapBorder
  if L4_2 then
    L4_2 = _GuiInternal
    L4_2 = L4_2.SetMinimapBorder
    L5_2 = A0_2.BasicData
    L5_2 = L5_2.uId
    L6_2 = A1_2
    L7_2 = A2_2
    L8_2 = A3_2
    L4_2(L5_2, L6_2, L7_2, L8_2)
  end
end

L0_1.SetBorder = L1_1
L0_1 = MinimapWidget

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2, A9_2, A10_2, A11_2, A12_2, A13_2, A14_2, A15_2)
  local L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2
  L16_2 = _GuiInternal
  L16_2 = L16_2.MinimapAddObjective
  L17_2 = A0_2.BasicData
  L17_2 = L17_2.uId
  L18_2 = A1_2
  L19_2 = A2_2 or L19_2
  if not A2_2 then
    L19_2 = 0
  end
  L20_2 = A3_2 or L20_2
  if not A3_2 then
    L20_2 = 2
  end
  L21_2 = A4_2 or L21_2
  if not A4_2 then
    L21_2 = 0
  end
  L22_2 = A5_2 or L22_2
  if not A5_2 then
    L22_2 = 255
  end
  L23_2 = A6_2 or L23_2
  if not A6_2 then
    L23_2 = 255
  end
  L24_2 = A7_2 or L24_2
  if not A7_2 then
    L24_2 = 0
  end
  L25_2 = A11_2
  L26_2 = A8_2
  L27_2 = A9_2
  L28_2 = A10_2
  L29_2 = A12_2
  L30_2 = A13_2
  L31_2 = A14_2
  L32_2 = A15_2
  L16_2(L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2)
end

L0_1.AddObjective = L1_1
L0_1 = MinimapWidget

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2, A9_2)
  local L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L10_2 = _GuiInternal
  L10_2 = L10_2.MinimapAnimateObjectiveSize
  if L10_2 then
    L10_2 = _GuiInternal
    L10_2 = L10_2.MinimapAnimateObjectiveSize
    L11_2 = A0_2.BasicData
    L11_2 = L11_2.uId
    L12_2 = A1_2
    L13_2 = A2_2
    L14_2 = A3_2
    L15_2 = A4_2
    L16_2 = A5_2
    L17_2 = A6_2
    L18_2 = A7_2 or L18_2
    if not A7_2 then
      L18_2 = false
    end
    L19_2 = A8_2 or L19_2
    if not A8_2 then
      L19_2 = 10
    end
    L20_2 = A9_2 or L20_2
    if not A9_2 then
      L20_2 = 10
    end
    L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
  end
end

L0_1.AnimateObjectiveSize = L1_1
L0_1 = MinimapWidget

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2)
  local L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L7_2 = _GuiInternal
  L7_2 = L7_2.MinimapAnimateObjectiveAlpha
  if L7_2 then
    L7_2 = _GuiInternal
    L7_2 = L7_2.MinimapAnimateObjectiveAlpha
    L8_2 = A0_2.BasicData
    L8_2 = L8_2.uId
    L9_2 = A1_2
    L10_2 = A2_2
    L11_2 = A3_2
    L12_2 = A4_2
    L13_2 = A5_2 or L13_2
    if not A5_2 then
      L13_2 = false
    end
    L14_2 = A6_2 or L14_2
    if not A6_2 then
      L14_2 = 0.5
    end
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  end
end

L0_1.AnimateObjectiveAlpha = L1_1
L0_1 = MinimapWidget

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2, A9_2, A10_2, A11_2, A12_2, A13_2, A14_2)
  local L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2
  L15_2 = _GuiInternal
  L15_2 = L15_2.MinimapAnimateObjectiveSonar
  if L15_2 then
    L15_2 = _GuiInternal
    L15_2 = L15_2.MinimapAnimateObjectiveSonar
    L16_2 = A0_2.BasicData
    L16_2 = L16_2.uId
    L17_2 = A1_2
    L18_2 = A2_2
    L19_2 = A3_2
    L20_2 = A4_2
    L21_2 = A5_2
    L22_2 = A6_2
    L23_2 = A7_2
    L24_2 = A8_2
    L25_2 = A9_2
    L26_2 = A10_2
    L27_2 = A11_2 or L27_2
    if not A11_2 then
      L27_2 = 5
    end
    L28_2 = A12_2 or L28_2
    if not A12_2 then
      L28_2 = 255
    end
    L29_2 = A13_2 or L29_2
    if not A13_2 then
      L29_2 = 255
    end
    L30_2 = A14_2 or L30_2
    if not A14_2 then
      L30_2 = 255
    end
    L15_2(L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2)
  end
end

L0_1.AnimateObjectiveSonar = L1_1
L0_1 = MinimapWidget

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = _GuiInternal
  L3_2 = L3_2.MinimapUnanimateObjective
  if L3_2 then
    L3_2 = _GuiInternal
    L3_2 = L3_2.MinimapUnanimateObjective
    L4_2 = A0_2.BasicData
    L4_2 = L4_2.uId
    L5_2 = A1_2
    L6_2 = A2_2 or L6_2
    if not A2_2 then
      L6_2 = "all"
    end
    L3_2(L4_2, L5_2, L6_2)
  end
end

L0_1.UnanimateObjective = L1_1
L0_1 = MinimapWidget

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2, A9_2, A10_2, A11_2, A12_2, A13_2, A14_2, A15_2)
  local L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2
  L16_2 = type
  L17_2 = A2_2
  L16_2 = L16_2(L17_2)
  if "userdata" ~= L16_2 then
    return
  end
  L16_2 = _GuiInternal
  L16_2 = L16_2.MinimapAddObjective
  L17_2 = A0_2.BasicData
  L17_2 = L17_2.uId
  L18_2 = A1_2
  L19_2 = A3_2 or L19_2
  if not A3_2 then
    L19_2 = 0
  end
  L20_2 = A4_2 or L20_2
  if not A4_2 then
    L20_2 = 2
  end
  L21_2 = A5_2 or L21_2
  if not A5_2 then
    L21_2 = 0
  end
  L22_2 = A6_2 or L22_2
  if not A6_2 then
    L22_2 = 255
  end
  L23_2 = A7_2 or L23_2
  if not A7_2 then
    L23_2 = 255
  end
  L24_2 = A8_2 or L24_2
  if not A8_2 then
    L24_2 = 0
  end
  L25_2 = A2_2
  L26_2 = A9_2
  L27_2 = A10_2
  L28_2 = A11_2
  L29_2 = A12_2
  L30_2 = A13_2
  L31_2 = A14_2
  L32_2 = A15_2
  L16_2(L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2)
end

L0_1.AddObjectiveWithGuid = L1_1
L0_1 = MinimapWidget

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2, A9_2, A10_2, A11_2, A12_2, A13_2, A14_2)
  local L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2
  L16_2 = A0_2
  L15_2 = A0_2.AddObjective
  L17_2 = A1_2
  L18_2 = A2_2
  L19_2 = A3_2
  L20_2 = A4_2
  L21_2 = A5_2
  L22_2 = A6_2
  L23_2 = A7_2
  L24_2 = A8_2
  L25_2 = A9_2
  L26_2 = A10_2
  L27_2 = A11_2
  L28_2 = A12_2
  L29_2 = A13_2
  L30_2 = A14_2
  L15_2(L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2)
end

L0_1.UpdateObjective = L1_1
L0_1 = MinimapWidget

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _GuiInternal
  L2_2 = L2_2.MinimapRemoveObjective
  L3_2 = A0_2.BasicData
  L3_2 = L3_2.uId
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

L0_1.DeleteObjective = L1_1
L0_1 = MinimapWidget

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = WidgetIdIndex
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  L1_2[L2_2] = nil
  L1_2 = _GuiInternal
  L1_2 = L1_2.MinimapDelete
  L2_2 = A0_2.BasicData
  L2_2 = L2_2.uId
  L1_2(L2_2)
end

L0_1.Delete = L1_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L5_2 = _GuiInternal
  L5_2 = L5_2.MinimapUpdate
  L6_2 = A0_2.BasicData
  L6_2 = L6_2.uId
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.nCorrectedX
  L8_2 = A0_2.CustomData
  L8_2 = L8_2.nCorrectedY
  L9_2 = A1_2
  L10_2 = A2_2
  L11_2 = A3_2
  L12_2 = A1_2
  L13_2 = A2_2
  L14_2 = A3_2
  L15_2 = A4_2
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  L6_2 = A0_2
  L5_2 = A0_2.GetOwner
  L5_2 = L5_2(L6_2)
  if L5_2 then
    L6_2 = Player
    L6_2 = L6_2.GetControlledObject
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    if L6_2 then
      L7_2 = Object
      L7_2 = L7_2.GetVelocity
      L8_2 = L6_2
      L7_2 = L7_2(L8_2)
      if L7_2 then
        L8_2 = 10
        L9_2 = 150
        L10_2 = 50
        L11_2 = 400
        L12_2 = nil
        if L7_2 < L8_2 then
          L12_2 = L9_2
        elseif L7_2 > L10_2 then
          L12_2 = L11_2
        else
          L13_2 = L7_2 - L8_2
          L14_2 = L11_2 - L9_2
          L13_2 = L13_2 * L14_2
          L14_2 = L10_2 - L8_2
          L13_2 = L13_2 / L14_2
          L12_2 = L9_2 + L13_2
        end
        L13_2 = _GuiInternal
        L13_2 = L13_2.MinimapSetRange
        L14_2 = A0_2.BasicData
        L14_2 = L14_2.uId
        L15_2 = L12_2
        L13_2(L14_2, L15_2)
      end
    end
  end
end

MinimapDataUpdateHandler = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A1_2.bOn
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.SetVisible
    L4_2 = false
    L2_2(L3_2, L4_2)
  else
    L3_2 = A0_2
    L2_2 = A0_2.SetVisible
    L4_2 = true
    L2_2(L3_2, L4_2)
  end
end

MinimapHandleE3HudModeEvent = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  
  function L3_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = GUIFileLoadedCallback
    L2_3 = A0_3
    L3_3 = A2_2
    L1_3(L2_3, L3_3)
    L1_3 = type
    L2_3 = A1_2
    L1_3 = L1_3(L2_3)
    if "function" == L1_3 then
      L1_3 = A1_2
      L2_3 = A0_3
      L1_3(L2_3)
    end
  end
  
  L4_2 = dynamic_import
  L5_2 = A0_2
  L6_2 = L3_2
  L4_2(L5_2, L6_2)
end

LoadGUIFile = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  if nil == A0_2 then
    return
  end
  L1_2 = 1
  L2_2 = nil
  while true do
    L3_2 = A0_2.AddedWidgetList
    if not L3_2 then
      break
    end
    L3_2 = A0_2.AddedWidgetList
    L3_2 = L3_2[L1_2]
    if not L3_2 then
      break
    end
    L3_2 = A0_2.AddedWidgetList
    L2_2 = L3_2[L1_2]
    L3_2 = RemoveWidgetWithChildren
    L4_2 = L2_2
    L3_2(L4_2)
    L1_2 = L1_2 + 1
  end
end

RemoveAllWidgetsInLayout = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  if nil == A0_2 then
    return
  end
  L1_2 = 1
  L2_2 = nil
  while true do
    L3_2 = A0_2.AddedWidgetList
    if not L3_2 then
      break
    end
    L3_2 = A0_2.AddedWidgetList
    L3_2 = L3_2[L1_2]
    if not L3_2 then
      break
    end
    L3_2 = A0_2.AddedWidgetList
    L2_2 = L3_2[L1_2]
    L3_2 = AddWidgetWithChildren
    L4_2 = L2_2
    L3_2(L4_2)
    L1_2 = L1_2 + 1
  end
end

ReAddAllWidgets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  if nil == A0_2 then
    return
  end
  L1_2 = 1
  L2_2 = nil
  while true do
    L3_2 = A0_2.AddedWidgetList
    if not L3_2 then
      break
    end
    L3_2 = A0_2.AddedWidgetList
    L3_2 = L3_2[L1_2]
    if not L3_2 then
      break
    end
    L3_2 = A0_2.AddedWidgetList
    L2_2 = L3_2[L1_2]
    L4_2 = L2_2
    L3_2 = L2_2.SetVisible
    L5_2 = false
    L3_2(L4_2, L5_2)
    L1_2 = L1_2 + 1
  end
end

HideAllWidgets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  if nil == A0_2 then
    return
  end
  L1_2 = 1
  L2_2 = nil
  while true do
    L3_2 = A0_2.AddedWidgetList
    if not L3_2 then
      break
    end
    L3_2 = A0_2.AddedWidgetList
    L3_2 = L3_2[L1_2]
    if not L3_2 then
      break
    end
    L3_2 = A0_2.AddedWidgetList
    L2_2 = L3_2[L1_2]
    L4_2 = L2_2
    L3_2 = L2_2.SetVisible
    L5_2 = true
    L3_2(L4_2, L5_2)
    L1_2 = L1_2 + 1
  end
end

ShowAllWidgets = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  if not A0_2 then
    return
  end
  L2_2 = 1
  L3_2 = nil
  while true do
    L4_2 = A0_2.AddedWidgetList
    if not L4_2 then
      break
    end
    L4_2 = A0_2.AddedWidgetList
    L4_2 = L4_2[L2_2]
    if not L4_2 then
      break
    end
    L4_2 = A0_2.AddedWidgetList
    L3_2 = L4_2[L2_2]
    L5_2 = L3_2
    L4_2 = L3_2.SetSleeping
    L6_2 = A1_2
    L4_2(L5_2, L6_2)
    L2_2 = L2_2 + 1
  end
end

SetAllWidgetsSleep = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  if not A0_2 then
    return
  end
  L1_2 = 1
  L2_2 = nil
  while true do
    L3_2 = A0_2.AddedWidgetList
    if not L3_2 then
      break
    end
    L3_2 = A0_2.AddedWidgetList
    L3_2 = L3_2[L1_2]
    if not L3_2 then
      break
    end
    L3_2 = A0_2.AddedWidgetList
    L2_2 = L3_2[L1_2]
    L3_2 = L2_2.BasicData
    L3_2 = L3_2.type
    if "text" == L3_2 then
      L3_2 = PushWidgetToFront
      L4_2 = L2_2
      L3_2(L4_2)
    end
    L1_2 = L1_2 + 1
  end
end

PushAllTextToFront = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  if nil == A0_2 then
    return
  end
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if "userdata" ~= L2_2 then
    return
  end
  L2_2 = 1
  L3_2 = nil
  while true do
    L4_2 = A0_2.AddedWidgetList
    if not L4_2 then
      break
    end
    L4_2 = A0_2.AddedWidgetList
    L4_2 = L4_2[L2_2]
    if not L4_2 then
      break
    end
    L4_2 = A0_2.AddedWidgetList
    L4_2 = L4_2[L2_2]
    CurrentWidget = L4_2
    L4_2 = CurrentWidget
    L5_2 = L4_2
    L4_2 = L4_2.SetOwner
    L6_2 = A1_2
    L4_2(L5_2, L6_2)
    L2_2 = L2_2 + 1
  end
end

AssignLayoutToPlayer = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    L1_2 = nil
    return L1_2
  end
  L1_2 = type
  L2_2 = A0_2.AddedWidgetList
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    L1_2 = nil
    return L1_2
  end
  L1_2 = {}
  L2_2 = {}
  L1_2.AddedWidgetList = L2_2
  L2_2 = A0_2.LocalWidgetList
  L1_2.LocalWidgetList = L2_2
  L2_2 = GUIFileLoadedCallback
  L3_2 = L1_2
  L2_2(L3_2)
  return L1_2
end

DuplicateLayout = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = {}
  A0_2.AddedWidgetList = L2_2
  L2_2 = 1
  while true do
    L3_2 = A0_2.LocalWidgetList
    L3_2 = L3_2[L2_2]
    if not L3_2 then
      break
    end
    L3_2 = LoadAndAddWidgetFromLayoutFileData
    L4_2 = A0_2.LocalWidgetList
    L4_2 = L4_2[L2_2]
    L5_2 = A0_2.AddedWidgetList
    L6_2 = nil
    L7_2 = A1_2
    L3_2(L4_2, L5_2, L6_2, L7_2)
    L2_2 = L2_2 + 1
  end
  L2_2 = 1
  L3_2 = nil
  while true do
    L4_2 = A0_2.AddedWidgetList
    if not L4_2 then
      break
    end
    L4_2 = A0_2.AddedWidgetList
    L4_2 = L4_2[L2_2]
    if not L4_2 then
      break
    end
    L4_2 = A0_2.AddedWidgetList
    L3_2 = L4_2[L2_2]
    L4_2 = L3_2.EventHandlers
    L4_2 = L4_2.GuiInitialization
    if L4_2 then
      L4_2 = L3_2.EventHandlers
      L4_2 = L4_2.GuiInitialization
      L5_2 = L3_2
      L6_2 = nil
      L4_2(L5_2, L6_2)
    end
    L2_2 = L2_2 + 1
  end
  L4_2 = pairs
  L5_2 = A0_2.AddedWidgetList
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = _GuiInternal
    L9_2 = L9_2.CorrectWidgetForResolution
    L10_2 = L8_2.BasicData
    L10_2 = L10_2.uId
    L9_2(L10_2)
  end
end

GUIFileLoadedCallback = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L5_2 = Widget
  L6_2 = A0_2.container
  if L6_2 then
    L6_2 = Widget
    L7_2 = L6_2
    L6_2 = L6_2.new
    L6_2 = L6_2(L7_2)
    L4_2 = L6_2
  else
    L6_2 = A0_2.WidgetType
    if L6_2 == "image" then
      L6_2 = ImageWidget
      L7_2 = L6_2
      L6_2 = L6_2.new
      L6_2 = L6_2(L7_2)
      L4_2 = L6_2
      L7_2 = L4_2
      L6_2 = L4_2.SetTexture
      L8_2 = A0_2.texture
      L6_2(L7_2, L8_2)
      L7_2 = L4_2
      L6_2 = L4_2.SetRotation
      L8_2 = A0_2.rotation
      L6_2(L7_2, L8_2)
      L7_2 = L4_2
      L6_2 = L4_2.SetTextureCoordinates
      L8_2 = A0_2.u1
      if not L8_2 then
        L8_2 = 0
      end
      L9_2 = A0_2.v1
      if not L9_2 then
        L9_2 = 0
      end
      L10_2 = A0_2.u2
      if not L10_2 then
        L10_2 = 1
      end
      L11_2 = A0_2.v2
      if not L11_2 then
        L11_2 = 1
      end
      L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
    else
      L6_2 = A0_2.WidgetType
      if L6_2 == "text" then
        L6_2 = TextWidget
        L7_2 = L6_2
        L6_2 = L6_2.new
        L6_2 = L6_2(L7_2)
        L4_2 = L6_2
        L7_2 = L4_2
        L6_2 = L4_2.SetText
        L8_2 = A0_2.text
        L6_2(L7_2, L8_2)
        L7_2 = L4_2
        L6_2 = L4_2.SetFont
        L8_2 = A0_2.font
        L6_2(L7_2, L8_2)
        L7_2 = L4_2
        L6_2 = L4_2.SetScale
        L8_2 = A0_2.scale
        L6_2(L7_2, L8_2)
        L7_2 = L4_2
        L6_2 = L4_2.SetJustification
        L8_2 = A0_2.Justification
        L6_2(L7_2, L8_2)
      else
        L6_2 = A0_2.WidgetType
        if L6_2 == "minimap" then
          L6_2 = MinimapWidget
          L7_2 = L6_2
          L6_2 = L6_2.new
          L6_2 = L6_2(L7_2)
          L4_2 = L6_2
          L7_2 = L4_2
          L6_2 = L4_2.SetUpMinimap
          L8_2 = A0_2.name
          L9_2 = A0_2.x1
          L10_2 = A0_2.nRadius
          L9_2 = L9_2 + L10_2
          L10_2 = A0_2.y1
          L11_2 = A0_2.nRadius
          L10_2 = L10_2 + L11_2
          L11_2 = A0_2.nRadius
          L12_2 = A0_2.texture
          L13_2 = A0_2.nTextureWidth
          L14_2 = A0_2.nTextureHeight
          L15_2 = A0_2.nWorldXMin
          L16_2 = A0_2.nWorldXMax
          L17_2 = A0_2.nWorldZMin
          L18_2 = A0_2.nWorldZMax
          L19_2 = A0_2.HorizontalAnchor
          L20_2 = A0_2.VerticalAnchor
          L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
          L7_2 = L4_2
          L6_2 = L4_2.SetBorder
          L8_2 = A0_2.sBorderTexture
          L9_2 = A0_2.nBorderTextureWidth
          L10_2 = A0_2.nBorderTextureHeight
          L6_2(L7_2, L8_2, L9_2, L10_2)
        else
          L6_2 = A0_2.WidgetType
          if L6_2 == "flash" then
            L6_2 = FlashWidget
            L7_2 = L6_2
            L6_2 = L6_2.new
            L6_2 = L6_2(L7_2)
            L4_2 = L6_2
          else
            L6_2 = A0_2.WidgetType
            if L6_2 == "sprite" then
              L6_2 = SpriteWidget
              L7_2 = L6_2
              L6_2 = L6_2.new
              L6_2 = L6_2(L7_2)
              L4_2 = L6_2
              L7_2 = L4_2
              L6_2 = L4_2.SetTexture
              L8_2 = A0_2.texture
              L6_2(L7_2, L8_2)
              L7_2 = L4_2
              L6_2 = L4_2.SetRotation
              L8_2 = A0_2.rotation
              L6_2(L7_2, L8_2)
              L7_2 = L4_2
              L6_2 = L4_2.SetTextureSize
              L8_2 = A0_2.textureWidth
              L9_2 = A0_2.textureHeight
              L6_2(L7_2, L8_2, L9_2)
              L7_2 = L4_2
              L6_2 = L4_2.SetFrameSize
              L8_2 = A0_2.u2
              L9_2 = A0_2.u1
              L8_2 = L8_2 - L9_2
              L9_2 = A0_2.textureWidth
              L8_2 = L8_2 * L9_2
              L9_2 = A0_2.v2
              L10_2 = A0_2.v1
              L9_2 = L9_2 - L10_2
              L10_2 = A0_2.textureHeight
              L9_2 = L9_2 * L10_2
              L6_2(L7_2, L8_2, L9_2)
              L7_2 = L4_2
              L6_2 = L4_2.SetFrame
              L8_2 = 0
              L6_2(L7_2, L8_2)
            else
              L6_2 = Widget
              L7_2 = L6_2
              L6_2 = L6_2.new
              L6_2 = L6_2(L7_2)
              L4_2 = L6_2
            end
          end
        end
      end
    end
  end
  L7_2 = L4_2
  L6_2 = L4_2.SetTransient
  L8_2 = false
  L6_2(L7_2, L8_2)
  L6_2 = A0_2.WidgetType
  if L6_2 ~= "minimap" then
    L7_2 = L4_2
    L6_2 = L4_2.SetLocation
    L8_2 = A0_2.x1
    L9_2 = A0_2.y1
    L10_2 = A0_2.x2
    L11_2 = A0_2.y2
    L12_2 = true
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
    L7_2 = L4_2
    L6_2 = L4_2.SetName
    L8_2 = A0_2.name
    L6_2(L7_2, L8_2)
  end
  L7_2 = L4_2
  L6_2 = L4_2.SetAnchoring
  L8_2 = A0_2.HorizontalAnchor
  L9_2 = A0_2.VerticalAnchor
  L6_2(L7_2, L8_2, L9_2)
  L6_2 = A0_2.WidgetType
  if L6_2 == "image" then
    L6_2 = A0_2.container
    if not L6_2 then
      L6_2 = A0_2.nTileWidth
      if L6_2 then
        L6_2 = A0_2.nTileHeight
        if L6_2 then
          L7_2 = L4_2
          L6_2 = L4_2.SetTileSize
          L8_2 = A0_2.nTileWidth
          L9_2 = A0_2.nTileHeight
          L6_2(L7_2, L8_2, L9_2)
        end
      end
    end
  end
  L6_2 = A0_2.visible
  if 0 < L6_2 then
    L7_2 = L4_2
    L6_2 = L4_2.SetVisible
    L8_2 = true
    L6_2(L7_2, L8_2)
  else
    L7_2 = L4_2
    L6_2 = L4_2.SetVisible
    L8_2 = false
    L6_2(L7_2, L8_2)
  end
  L6_2 = A0_2.container
  if L6_2 then
    L7_2 = L4_2
    L6_2 = L4_2.SetVisible
    L8_2 = false
    L6_2(L7_2, L8_2)
  end
  L6_2 = L4_2.BasicData
  L7_2 = A0_2.container
  L6_2.bContainer = L7_2
  L7_2 = L4_2
  L6_2 = L4_2.SetColor
  L8_2 = A0_2.RedLevel
  L9_2 = A0_2.GreenLevel
  L10_2 = A0_2.BlueLevel
  L11_2 = A0_2.TranslucencyLevel
  L12_2 = true
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L4_2.ParentWidget = A2_2
  L6_2 = table
  L6_2 = L6_2.insert
  L7_2 = A1_2
  L8_2 = L4_2
  L6_2(L7_2, L8_2)
  L6_2 = A0_2.WidgetType
  if L6_2 then
    L6_2 = A0_2.WidgetType
    if L6_2 == "minimap" then
      goto lbl_217
    end
  end
  L6_2 = WidgetManager
  L6_2 = L6_2.AddWidget
  L7_2 = L4_2
  L6_2(L7_2)
  ::lbl_217::
  L6_2 = pairs
  L7_2 = A0_2.EventHandlers
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  for L9_2, L10_2 in L6_2, L7_2, L8_2 do
    L12_2 = L4_2
    L11_2 = L4_2.SetEventHandler
    L13_2 = L9_2
    L14_2 = L10_2
    L11_2(L12_2, L13_2, L14_2)
  end
  L6_2 = A0_2.EventHandlers
  L6_2 = L6_2[0]
  if L6_2 then
    L7_2 = L4_2
    L6_2 = L4_2.SetEventHandler
    L8_2 = 0
    L9_2 = A0_2.EventHandlers
    L9_2 = L9_2[0]
    L6_2(L7_2, L8_2, L9_2)
  end
  A0_2.EventHandlerNames = nil
  A0_2.EventHandlerFile = nil
  A0_2.textureFile = nil
  if A3_2 then
    L7_2 = L4_2
    L6_2 = L4_2.SetOwner
    L8_2 = A3_2
    L6_2(L7_2, L8_2)
  end
  L6_2 = 1
  while true do
    L7_2 = A0_2.Children
    L7_2 = L7_2[L6_2]
    if not L7_2 then
      break
    end
    L7_2 = nil
    L8_2 = LoadAndAddWidgetFromLayoutFileData
    L9_2 = A0_2.Children
    L9_2 = L9_2[L6_2]
    L10_2 = A1_2
    L11_2 = L4_2
    L12_2 = A3_2
    L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
    L7_2 = L8_2
    L9_2 = L4_2
    L8_2 = L4_2.AddChild
    L10_2 = L7_2
    L8_2(L9_2, L10_2)
    L6_2 = L6_2 + 1
  end
  return L4_2
end

LoadAndAddWidgetFromLayoutFileData = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = dynamic_remove
  L2_2 = A0_2
  L1_2(L2_2)
end

UnloadGUIFile = L0_1
L0_1 = 640
nWidgetSpaceScreenWidth = L0_1
L0_1 = 480
nWidgetSpaceScreenHeight = L0_1
L0_1 = 640
nScreenWidth = L0_1
L0_1 = 480
nScreenHeight = L0_1
L0_1 = 0
nScreenPositionX = L0_1
L0_1 = 0
nScreenPositionY = L0_1
L0_1 = 1
nPixelWidth = L0_1
L0_1 = 1
nPixelHeight = L0_1
L0_1 = 1
nScreenScaleFactor = L0_1
L0_1 = _G
L0_1 = L0_1.g_nGuiScreenWidthTemp
if not L0_1 then
  L0_1 = 640
end
nScreenWidth = L0_1
L0_1 = _G
L0_1 = L0_1.g_nGuiScreenHeightTemp
if not L0_1 then
  L0_1 = 480
end
nScreenHeight = L0_1
L0_1 = _G
L0_1 = L0_1.g_nGuiScreenPositionXTemp
if not L0_1 then
  L0_1 = 0
end
nScreenPositionX = L0_1
L0_1 = _G
L0_1 = L0_1.g_nGuiScreenPositionYTemp
if not L0_1 then
  L0_1 = 0
end
nScreenPositionY = L0_1
L0_1 = _G
L0_1 = L0_1.g_nGuiScreenPixelWidthTemp
if not L0_1 then
  L0_1 = 1
end
nPixelWidth = L0_1
L0_1 = _G
L0_1 = L0_1.g_nGuiScreenPixelHeightTemp
if not L0_1 then
  L0_1 = 1
end
nPixelHeight = L0_1
L0_1 = nScreenHeight
L1_1 = nWidgetSpaceScreenHeight
L0_1 = L0_1 / L1_1
nScreenScaleFactor = L0_1
L0_1 = _G
L0_1.g_nGuiScreenWidthTemp = nil
L0_1 = _G
L0_1.g_nGuiScreenHeightTemp = nil
L0_1 = _G
L0_1.g_nGuiScreenPositionXTemp = nil
L0_1 = _G
L0_1.g_nGuiScreenPositionYTemp = nil
L0_1 = _G
L0_1.g_nGuiScreenPixelWidthTemp = nil
L0_1 = _G
L0_1.g_nGuiScreenPixelHeightTemp = nil

function L0_1(A0_2)
  local L1_2
  if A0_2 < 0 then
    L1_2 = A0_2 * -1
    return L1_2
  end
  return A0_2
end

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L6_2 = A0_2 or nil
  if not A0_2 then
    L6_2 = nScreenWidth
  end
  nScreenWidth = L6_2
  L6_2 = A1_2 or L6_2
  if not A1_2 then
    L6_2 = nScreenHeight
  end
  nScreenHeight = L6_2
  L6_2 = A2_2 or L6_2
  if not A2_2 then
    L6_2 = nPixelWidth
  end
  nPixelWidth = L6_2
  L6_2 = A3_2 or L6_2
  if not A3_2 then
    L6_2 = nPixelHeight
  end
  nPixelHeight = L6_2
  L6_2 = A4_2 or L6_2
  if not A4_2 then
    L6_2 = nScreenPositionX
  end
  nScreenPositionX = L6_2
  L6_2 = A5_2 or L6_2
  if not A5_2 then
    L6_2 = nScreenPositionY
  end
  nScreenPositionY = L6_2
  L6_2 = nScreenHeight
  L7_2 = nWidgetSpaceScreenHeight
  L6_2 = L6_2 / L7_2
  nScreenScaleFactor = L6_2
  L6_2 = pairs
  L7_2 = WidgetManager
  L7_2 = L7_2.WidgetList
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  for L9_2, L10_2 in L6_2, L7_2, L8_2 do
    if L10_2 then
      L11_2 = L10_2.BasicData
      L11_2.bCorrectedForResolution = false
    end
  end
  L6_2 = pairs
  L7_2 = WidgetManager
  L7_2 = L7_2.WidgetList
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  for L9_2, L10_2 in L6_2, L7_2, L8_2 do
    if L10_2 then
      L11_2 = L10_2.BasicData
      L11_2 = L11_2.bCorrectedForResolution
      if not L11_2 then
      end
    end
  end
end

ChangeScreenResolution = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2 or nil
  if not A0_2 then
    L2_2 = nPixelWidth
  end
  nPixelWidth = L2_2
  L2_2 = A1_2 or L2_2
  if not A1_2 then
    L2_2 = nPixelHeight
  end
  nPixelHeight = L2_2
  L2_2 = pairs
  L3_2 = WidgetManager
  L3_2 = L3_2.WidgetList
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    if L6_2 then
    end
  end
end

ChangeScreenPixelSize = L1_1

function L1_1(A0_2, A1_2, A2_2)
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

ValidateParameter = L1_1

function L1_1()
  local L0_2, L1_2
  L0_2 = EventManager
  L0_2 = L0_2.ProcessEvents
  L0_2()
end

Run = L1_1

function L1_1()
  local L0_2, L1_2
  L0_2 = EventManager
  L0_2 = L0_2.EventList
  return L0_2
end

GetEventListTable = L1_1
L1_1 = GuiSetDialogBoxMode
_SetDialogBoxMode = L1_1
L1_1 = _G
L2_1 = "GuiSetDialogBoxMode"
L3_1 = nil
L1_1[L2_1] = L3_1
L1_1 = GuiSetSupportMenuMode
_SetSupportMenuMode = L1_1
L1_1 = _G
L2_1 = "GuiSetSupportMenuMode"
L3_1 = nil
L1_1[L2_1] = L3_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "userdata" ~= L2_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if "boolean" ~= L2_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = type
  L3_2 = _SetDialogBoxMode
  L2_2 = L2_2(L3_2)
  if "function" ~= L2_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = _SetDialogBoxMode
  L3_2 = A0_2
  L4_2 = A1_2
  return L2_2(L3_2, L4_2)
end

SetDialogBoxMode = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "userdata" ~= L2_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if "boolean" ~= L2_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = type
  L3_2 = _SetSupportMenuMode
  L2_2 = L2_2(L3_2)
  if "function" ~= L2_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = _SetSupportMenuMode
  L3_2 = A0_2
  L4_2 = A1_2
  return L2_2(L3_2, L4_2)
end

SetSupportMenuMode = L1_1

function L1_1()
  local L0_2, L1_2, L2_2
  L0_2 = Widget
  L1_2 = L0_2
  L0_2 = L0_2.new
  L2_2 = TextWidget
  L0_2 = L0_2(L1_2, L2_2)
  TextWidget = L0_2
  L0_2 = Widget
  L1_2 = L0_2
  L0_2 = L0_2.new
  L2_2 = ImageWidget
  L0_2 = L0_2(L1_2, L2_2)
  ImageWidget = L0_2
  L0_2 = Widget
  L1_2 = L0_2
  L0_2 = L0_2.new
  L2_2 = FlashWidget
  L0_2 = L0_2(L1_2, L2_2)
  FlashWidget = L0_2
  L0_2 = Widget
  L1_2 = L0_2
  L0_2 = L0_2.new
  L2_2 = MinimapWidget
  L0_2 = L0_2(L1_2, L2_2)
  MinimapWidget = L0_2
  L0_2 = ImageWidget
  L1_2 = L0_2
  L0_2 = L0_2.new
  L2_2 = SpriteWidget
  L0_2 = L0_2(L1_2, L2_2)
  SpriteWidget = L0_2
  L0_2 = Widget
  L1_2 = L0_2
  L0_2 = L0_2.new
  L2_2 = MovieWidget
  L0_2 = L0_2(L1_2, L2_2)
  MovieWidget = L0_2
  L0_2 = Widget
  L0_2 = L0_2.BasicData
  L0_2.bTransient = nil
  L0_2 = TextWidget
  L0_2 = L0_2.BasicData
  L0_2.bTransient = nil
  L0_2 = ImageWidget
  L0_2 = L0_2.BasicData
  L0_2.bTransient = nil
  L0_2 = FlashWidget
  L0_2 = L0_2.BasicData
  L0_2.bTransient = nil
  L0_2 = MinimapWidget
  L0_2 = L0_2.BasicData
  L0_2.bTransient = nil
  L0_2 = SpriteWidget
  L0_2 = L0_2.BasicData
  L0_2.bTransient = nil
  L0_2 = MovieWidget
  L0_2 = L0_2.BasicData
  L0_2.bTransient = nil
  L0_2 = Sys
  L0_2 = L0_2.IsConfirmOnCircle
  if L0_2 then
    L0_2 = Sys
    L0_2 = L0_2.IsConfirmOnCircle
    L0_2 = L0_2()
    if L0_2 then
      L0_2 = Joystick
      L0_2 = L0_2.BUTTON_PAD2_D
      L1_2 = Joystick
      L1_2 = L1_2.BUTTON_PAD2_R
      L2_2 = Joystick
      L2_2.BUTTON_PAD2_D = L1_2
      L2_2 = Joystick
      L2_2.BUTTON_PAD2_R = L0_2
    end
  end
end

Init = L1_1

function L1_1()
  local L0_2, L1_2
end

ReInit = L1_1

function L1_1()
  local L0_2, L1_2
end

DeInit = L1_1
