local L0_1, L1_1, L2_1, L3_1
L0_1 = {}
LocalWidgetList = L0_1
L0_1 = import
if L0_1 then
  L0_1 = import
  L1_1 = "MrxGuiPauseScreen"
  L0_1(L1_1)
else
  L0_1 = {}
  MrxGuiPauseScreen = L0_1
end
L0_1 = LocalWidgetList
L1_1 = {}
L1_1.name = "Pause Layout"
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
L1_1.EventHandlerFile = "MrxGuiPauseScreen"
L2_1 = {}
L3_1 = MrxGuiPauseScreen
L3_1 = L3_1.HandleStateChangeEvent
L2_1.GuiGameStateChange = L3_1
L3_1 = MrxGuiPauseScreen
L3_1 = L3_1._Initialize
L2_1.GuiInitialization = L3_1
L3_1 = MrxGuiPauseScreen
L3_1 = L3_1._HandleToggleEvent
L2_1.TogglePAUSE = L3_1
L3_1 = MrxGuiPauseScreen
L3_1 = L3_1.HandleImposterEvent
L2_1.ImposterShellEvent = L3_1
L1_1.EventHandlers = L2_1
L2_1 = {}
L2_1.GuiGameStateChange = "HandleStateChangeEvent"
L2_1.GuiInitialization = "_Initialize"
L2_1.TogglePAUSE = "_HandleToggleEvent"
L2_1.ImposterShellEvent = "HandleImposterEvent"
L1_1.EventHandlerNames = L2_1
L2_1 = {}
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
