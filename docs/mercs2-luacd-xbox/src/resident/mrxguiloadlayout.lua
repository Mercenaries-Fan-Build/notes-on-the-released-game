local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1
L0_1 = {}
LocalWidgetList = L0_1
L0_1 = import
if L0_1 then
  L0_1 = import
  L1_1 = "MrxGuiLoadScreen"
  L0_1(L1_1)
else
  L0_1 = {}
  MrxGuiLoadScreen = L0_1
end
L0_1 = LocalWidgetList
L1_1 = {}
L1_1.name = "Loading Screen"
L1_1.x1 = 0
L1_1.y1 = 0
L1_1.x2 = 640
L1_1.y2 = 480
L1_1.RedLevel = 255
L1_1.GreenLevel = 255
L1_1.BlueLevel = 255
L1_1.TranslucencyLevel = 0
L1_1.HorizontalAnchor = "left"
L1_1.VerticalAnchor = "top"
L1_1.visible = 1
L1_1.container = true
L1_1.EventHandlerFile = "MrxGuiLoadScreen"
L2_1 = {}
L3_1 = MrxGuiLoadScreen
L3_1 = L3_1.HandleStateChangeEvent
L2_1.LoadStateChange = L3_1
L3_1 = MrxGuiLoadScreen
L3_1 = L3_1.HandleInit
L2_1.GuiInitialization = L3_1
L1_1.EventHandlers = L2_1
L2_1 = {}
L2_1.LoadStateChange = "HandleStateChangeEvent"
L2_1.GuiInitialization = "HandleInit"
L1_1.EventHandlerNames = L2_1
L2_1 = {}
L3_1 = {}
L3_1.name = "Loading background"
L3_1.x1 = 0
L3_1.y1 = 0
L3_1.x2 = 640
L3_1.y2 = 480
L3_1.RedLevel = 0
L3_1.GreenLevel = 0
L3_1.BlueLevel = 0
L3_1.TranslucencyLevel = 255
L3_1.HorizontalAnchor = "left"
L3_1.VerticalAnchor = "top"
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
L3_1.EventHandlerFile = ""
L4_1 = {}
L3_1.EventHandlers = L4_1
L4_1 = {}
L3_1.EventHandlerNames = L4_1
L4_1 = {}
L3_1.Children = L4_1
L4_1 = {}
L4_1.name = "Loading text"
L4_1.x1 = 56
L4_1.y1 = 416
L4_1.x2 = 111
L4_1.y2 = 432
L4_1.RedLevel = 255
L4_1.GreenLevel = 255
L4_1.BlueLevel = 255
L4_1.TranslucencyLevel = 255
L4_1.HorizontalAnchor = "left"
L4_1.VerticalAnchor = "bottom"
L4_1.visible = 1
L4_1.container = false
L4_1.WidgetType = "text"
L4_1.text = "Loading"
L4_1.font = "font_16"
L4_1.scale = 1
L4_1.Justification = "left"
L4_1.EventHandlerFile = ""
L5_1 = {}
L4_1.EventHandlers = L5_1
L5_1 = {}
L4_1.EventHandlerNames = L5_1
L5_1 = {}
L4_1.Children = L5_1
L2_1[1] = L3_1
L2_1[2] = L4_1
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
