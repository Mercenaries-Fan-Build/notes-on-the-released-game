local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1
L0_1 = {}
LocalWidgetList = L0_1
L0_1 = import
if L0_1 then
  L0_1 = import
  L1_1 = "mrxguishell"
  L0_1(L1_1)
else
  L0_1 = {}
  mrxguishell = L0_1
end
L0_1 = LocalWidgetList
L1_1 = {}
L1_1.name = "Shell"
L1_1.x1 = 0
L1_1.y1 = 0
L1_1.x2 = 640
L1_1.y2 = 480
L1_1.RedLevel = 255
L1_1.GreenLevel = 255
L1_1.BlueLevel = 255
L1_1.TranslucencyLevel = 255
L1_1.HorizontalAnchor = "center"
L1_1.VerticalAnchor = "center"
L1_1.visible = 1
L1_1.container = false
L1_1.EventHandlerFile = "mrxguishell"
L2_1 = {}
L3_1 = mrxguishell
L3_1 = L3_1.HandleServerUpdate
L2_1.LobbyServerUpdated = L3_1
L3_1 = mrxguishell
L3_1 = L3_1.HandleServerAdd
L2_1.LobbyServerAdded = L3_1
L3_1 = mrxguishell
L3_1 = L3_1.HandleInput
L2_1.ControllerInput = L3_1
L3_1 = mrxguishell
L3_1 = L3_1.HandleServerRemove
L2_1.LobbyServerRemoved = L3_1
L3_1 = mrxguishell
L3_1 = L3_1.HandleInitializationEvent
L2_1.GuiInitialization = L3_1
L3_1 = mrxguishell
L3_1 = L3_1.HandleGameStateChangeEvent
L2_1.GuiGameStateChange = L3_1
L1_1.EventHandlers = L2_1
L2_1 = {}
L2_1.LobbyServerUpdated = "HandleServerUpdate"
L2_1.LobbyServerAdded = "HandleServerAdd"
L2_1.ControllerInput = "HandleInput"
L2_1.LobbyServerRemoved = "HandleServerRemove"
L2_1.GuiInitialization = "HandleInitializationEvent"
L2_1.GuiGameStateChange = "HandleGameStateChangeEvent"
L1_1.EventHandlerNames = L2_1
L2_1 = {}
L3_1 = {}
L3_1.name = "Shell Background"
L3_1.x1 = 0
L3_1.y1 = 0
L3_1.x2 = 640
L3_1.y2 = 480
L3_1.RedLevel = 0
L3_1.GreenLevel = 0
L3_1.BlueLevel = 0
L3_1.TranslucencyLevel = 255
L3_1.HorizontalAnchor = "center"
L3_1.VerticalAnchor = "center"
L3_1.visible = 1
L3_1.container = false
L3_1.WidgetType = "image"
L3_1.texture = nil
L3_1.textureFile = nil
L3_1.rotation = 0
L3_1.u1 = 0
L3_1.v1 = 0
L3_1.u2 = 1
L3_1.v2 = 1
L3_1.EventHandlerFile = "mrxguishell"
L4_1 = {}
L5_1 = mrxguishell
L5_1 = L5_1.MakeFullscreen
L4_1.GuiInitialization = L5_1
L3_1.EventHandlers = L4_1
L4_1 = {}
L4_1.GuiInitialization = "MakeFullscreen"
L3_1.EventHandlerNames = L4_1
L4_1 = {}
L5_1 = {}
L5_1.name = "New Text"
L5_1.x1 = 120
L5_1.y1 = 390
L5_1.x2 = 520
L5_1.y2 = 406
L5_1.RedLevel = 255
L5_1.GreenLevel = 255
L5_1.BlueLevel = 255
L5_1.TranslucencyLevel = 255
L5_1.HorizontalAnchor = "center"
L5_1.VerticalAnchor = "bottom"
L5_1.visible = 1
L5_1.container = false
L5_1.WidgetType = "text"
L5_1.text = ""
L5_1.font = "font_16"
L5_1.scale = 1
L5_1.Justification = "center"
L5_1.EventHandlerFile = ""
L6_1 = {}
L5_1.EventHandlers = L6_1
L6_1 = {}
L5_1.EventHandlerNames = L6_1
L6_1 = {}
L5_1.Children = L6_1
L4_1[1] = L5_1
L3_1.Children = L4_1
L2_1[1] = L3_1
L1_1.Children = L2_1
L0_1[1] = L1_1
L0_1 = import
if L0_1 then
  L0_1 = import
  L1_1 = "MrxGuiBase"
  L0_1(L1_1)
end

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = pairs
  L1_2 = AddedWidgetList
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2 in L0_2, L1_2, L2_2 do
    L4_2 = MrxGuiBase
    L4_2 = L4_2.RemoveWidget
    L5_2 = AddedWidgetList
    L5_2 = L5_2[L3_2]
    L4_2(L5_2)
  end
  L0_2 = {}
  AddedWidgetList = L0_2
  L0_2 = pairs
  L1_2 = LocalWidgetList
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2 in L0_2, L1_2, L2_2 do
    L4_2 = MrxGuiBase
    L4_2 = L4_2.LoadAndAddWidgetFromLayoutFileData
    L5_2 = LocalWidgetList
    L5_2 = L5_2[L3_2]
    L6_2 = AddedWidgetList
    L4_2(L5_2, L6_2)
  end
end

ReInit = L0_1
