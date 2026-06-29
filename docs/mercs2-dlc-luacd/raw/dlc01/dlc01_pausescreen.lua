local L0_1, L1_1, L2_1
L0_1 = import
L1_1 = "MrxGuiBase"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxGuiManager"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxGuiDialogBox"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxSound"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxPlayState"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "WifMissionFlow"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxPlayer"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxStatsManager"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxUtil"
L2_1 = false
L0_1(L1_1, L2_1)
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
L0_1 = false
tControlMap = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = {}
  L1_2 = {}
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD1_U
  L1_2[L2_2] = "[SHELL.Controls.Support_Menu]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD1_D
  L1_2[L2_2] = "[SHELL.Controls.Support_Menu]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD1_L
  L1_2[L2_2] = "[SHELL.Controls.Switch_Explosive]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_U
  L1_2[L2_2] = "[SHELL.Controls.Action]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_D
  L1_2[L2_2] = "[SHELL.Controls.Jump]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_L
  L1_2[L2_2] = "[SHELL.Controls.Reload]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_R
  L1_2[L2_2] = "[SHELL.Controls.Melee]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_L_STICK_L
  L1_2[L2_2] = "[SHELL.Controls.LeftRight]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_L_STICK_U
  L1_2[L2_2] = "[SHELL.Controls.UpDown]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_R_STICK_L
  L1_2[L2_2] = "[SHELL.Controls.TurnLR]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_R_STICK_U
  L1_2[L2_2] = "[SHELL.Controls.PitchUpDown]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT1_1
  L1_2[L2_2] = "[SHELL.Controls.Crouch]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT1_2
  L1_2[L2_2] = "[SHELL.Controls.Use_Explosive]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT1_3
  L1_2[L2_2] = "[SHELL.Controls.Sprint]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_1
  L1_2[L2_2] = "[SHELL.Controls.Fire_Primary]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_2
  L1_2[L2_2] = "[SHELL.Controls.Switch_Primary]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_3
  L1_2[L2_2] = "[SHELL.Controls.Zoom]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_SYS1
  L1_2[L2_2] = "[SHELL.Controls.Pause]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_SYS2
  L1_2[L2_2] = "[SHELL.Controls.PDA]"
  L0_2.human = L1_2
  L1_2 = {}
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD1_U
  L1_2[L2_2] = "[SHELL.Controls.Show_Cash_And_Fuel]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD1_D
  L1_2[L2_2] = "[SHELL.Controls.Show_Cash_And_Fuel]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD1_R
  L1_2[L2_2] = "[SHELL.Controls.Camera_Mode]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_U
  L1_2[L2_2] = "[SHELL.Controls.Exit]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_D
  L1_2[L2_2] = "[SHELL.Controls.Forward]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_L
  L1_2[L2_2] = "[SHELL.Controls.Reverse]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_R
  L1_2[L2_2] = "[SHELL.Controls.Call_Allies]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_L_STICK_L
  L1_2[L2_2] = "[SHELL.Controls.TurnLR]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_R_STICK_L
  L1_2[L2_2] = "[SHELL.Controls.Look_LR]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_R_STICK_U
  L1_2[L2_2] = "[SHELL.Controls.PitchUpDown]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT1_1
  L1_2[L2_2] = "[SHELL.Controls.Handbrake]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_1
  L1_2[L2_2] = "[SHELL.Controls.Fire_Primary]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_2
  L1_2[L2_2] = "[SHELL.Controls.Switch_Primary]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_3
  L1_2[L2_2] = "[SHELL.Controls.Reset_Camera]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_SYS1
  L1_2[L2_2] = "[SHELL.Controls.Pause]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_SYS2
  L1_2[L2_2] = "[SHELL.Controls.PDA]"
  L0_2.car = L1_2
  L1_2 = {}
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD1_U
  L1_2[L2_2] = "[SHELL.Controls.Show_Cash_And_Fuel]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD1_D
  L1_2[L2_2] = "[SHELL.Controls.Show_Cash_And_Fuel]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_U
  L1_2[L2_2] = "[SHELL.Controls.Exit]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_D
  L1_2[L2_2] = "[SHELL.Controls.Forward]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_L
  L1_2[L2_2] = "[SHELL.Controls.Reverse]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_R
  L1_2[L2_2] = "[SHELL.Controls.Call_Allies]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_L_STICK_L
  L1_2[L2_2] = "[SHELL.Controls.TurnLR]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_L_STICK_U
  L1_2[L2_2] = "[SHELL.Controls.Move]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_R_STICK_L
  L1_2[L2_2] = "[SHELL.Controls.Aim_LR]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_R_STICK_U
  L1_2[L2_2] = "[SHELL.Controls.Aim_UD]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_1
  L1_2[L2_2] = "[SHELL.Controls.Fire_Primary]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_2
  L1_2[L2_2] = "[SHELL.Controls.Switch_Primary]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_3
  L1_2[L2_2] = "[SHELL.Controls.Reset_Camera]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_SYS1
  L1_2[L2_2] = "[SHELL.Controls.Pause]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_SYS2
  L1_2[L2_2] = "[SHELL.Controls.PDA]"
  L0_2.tank = L1_2
  L1_2 = {}
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD1_U
  L1_2[L2_2] = "[SHELL.Controls.Show_Cash_And_Fuel]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD1_D
  L1_2[L2_2] = "[SHELL.Controls.Show_Cash_And_Fuel]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD1_L
  L1_2[L2_2] = "[SHELL.Controls.Winch]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_U
  L1_2[L2_2] = "[SHELL.Controls.Exit]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_D
  L1_2[L2_2] = "[SHELL.Controls.Raise]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_L
  L1_2[L2_2] = "[SHELL.Controls.Lower]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_R
  L1_2[L2_2] = "[SHELL.Controls.Call_Allies]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_L_STICK_L
  L1_2[L2_2] = "[SHELL.Controls.LeftRight]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_L_STICK_U
  L1_2[L2_2] = "[SHELL.Controls.Move]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_R_STICK_L
  L1_2[L2_2] = "[SHELL.Controls.TurnLR]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_R_STICK_U
  L1_2[L2_2] = "[SHELL.Controls.Aim_UD]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT1_1
  L1_2[L2_2] = "[SHELL.Controls.Lower]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT1_2
  L1_2[L2_2] = "[SHELL.Controls.Raise]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_1
  L1_2[L2_2] = "[SHELL.Controls.Fire_Primary]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_2
  L1_2[L2_2] = "[SHELL.Controls.Switch_Primary]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_3
  L1_2[L2_2] = "[SHELL.Controls.Reset_Camera]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_SYS1
  L1_2[L2_2] = "[SHELL.Controls.Pause]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_SYS2
  L1_2[L2_2] = "[SHELL.Controls.PDA]"
  L0_2.helicopter = L1_2
  L1_2 = {}
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD1_U
  L1_2[L2_2] = "Seat Menu"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD1_D
  L1_2[L2_2] = "Seat Menu"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_U
  L1_2[L2_2] = "Exit"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_D
  L1_2[L2_2] = "Accelerate"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_L
  L1_2[L2_2] = "Decelerate"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_R
  L1_2[L2_2] = "Winch"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_L_STICK_L
  L1_2[L2_2] = "Roll L/R"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_L_STICK_U
  L1_2[L2_2] = "Pitch U/D"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_R_STICK_L
  L1_2[L2_2] = "Turn L/R"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_R_STICK_U
  L1_2[L2_2] = "Aim U/D"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT1_1
  L1_2[L2_2] = "Lower"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT1_2
  L1_2[L2_2] = "Raise"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT1_3
  L1_2[L2_2] = "Toggle VTOL"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_1
  L1_2[L2_2] = "Fire Weapon"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_2
  L1_2[L2_2] = "Switch Weapon"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_3
  L1_2[L2_2] = "Camera Mode"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_SYS1
  L1_2[L2_2] = "Pause"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_SYS2
  L1_2[L2_2] = "PDA"
  L0_2.jet = L1_2
  L1_2 = {}
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD1_U
  L1_2[L2_2] = "[SHELL.Controls.Show_Cash_And_Fuel]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD1_D
  L1_2[L2_2] = "[SHELL.Controls.Show_Cash_And_Fuel]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD1_R
  L1_2[L2_2] = "[SHELL.Controls.Camera_Mode]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_U
  L1_2[L2_2] = "[SHELL.Controls.Exit]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_D
  L1_2[L2_2] = "[SHELL.Controls.Forward]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_L
  L1_2[L2_2] = "[SHELL.Controls.Reverse]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_R
  L1_2[L2_2] = "[SHELL.Controls.Call_Allies]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_L_STICK_L
  L1_2[L2_2] = "[SHELL.Controls.TurnLR]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_R_STICK_L
  L1_2[L2_2] = "[SHELL.Controls.Look_LR]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_R_STICK_U
  L1_2[L2_2] = "[SHELL.Controls.PitchUpDown]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT1_1
  L1_2[L2_2] = "[SHELL.Controls.Handbrake]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_1
  L1_2[L2_2] = "[SHELL.Controls.Fire_Primary]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_2
  L1_2[L2_2] = "[SHELL.Controls.Switch_Primary]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_3
  L1_2[L2_2] = "[SHELL.Controls.Reset_Camera]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_SYS1
  L1_2[L2_2] = "[SHELL.Controls.Pause]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_SYS2
  L1_2[L2_2] = "[SHELL.Controls.PDA]"
  L0_2.boat = L1_2
  L1_2 = {}
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_U
  L1_2[L2_2] = "[SHELL.Controls.Exit]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_D
  L1_2[L2_2] = "[SHELL.Controls.Exit]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_L_STICK_U
  L1_2[L2_2] = "[SHELL.Controls.Climb_UD]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_R_STICK_L
  L1_2[L2_2] = "[SHELL.Controls.Look_LR]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_R_STICK_U
  L1_2[L2_2] = "[SHELL.Controls.Look_LR]"
  L0_2.ladder = L1_2
  L1_2 = {}
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_R
  L1_2[L2_2] = "[SHELL.Controls.Call_Allies]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_R_STICK_L
  L1_2[L2_2] = "[SHELL.Controls.Aim_LR]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_R_STICK_U
  L1_2[L2_2] = "[SHELL.Controls.Aim_UD]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_1
  L1_2[L2_2] = "[SHELL.Controls.Fire_Primary]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_2
  L1_2[L2_2] = "[SHELL.Controls.Switch_Primary]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_3
  L1_2[L2_2] = "[SHELL.Controls.Camera_Mode]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_SYS1
  L1_2[L2_2] = "[SHELL.Controls.Pause]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_SYS2
  L1_2[L2_2] = "[SHELL.Controls.PDA]"
  L0_2.seat = L1_2
  L1_2 = {}
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD1_U
  L1_2[L2_2] = "[SHELL.Controls.Show_Cash_And_Fuel]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD1_D
  L1_2[L2_2] = "[SHELL.Controls.Show_Cash_And_Fuel]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD1_R
  L1_2[L2_2] = "[SHELL.Controls.Camera_Mode]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_D
  L1_2[L2_2] = "[SHELL.Controls.Forward]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_L
  L1_2[L2_2] = "[SHELL.Controls.Reverse]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_L_STICK_L
  L1_2[L2_2] = "[SHELL.Controls.TurnLR]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_R_STICK_L
  L1_2[L2_2] = "[SHELL.Controls.Look_LR]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_R_STICK_U
  L1_2[L2_2] = "[SHELL.Controls.PitchUpDown]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT1_1
  L1_2[L2_2] = "[SHELL.Controls.Handbrake]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT1_2
  L1_2[L2_2] = "[SHELL.Controls.boost]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_1
  L1_2[L2_2] = "[SHELL.Controls.Fire_Primary]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_2
  L1_2[L2_2] = "[SHELL.Controls.Jump]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_3
  L1_2[L2_2] = "[SHELL.Controls.Reset_Camera]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_SYS1
  L1_2[L2_2] = "[SHELL.Controls.Pause]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_SYS2
  L1_2[L2_2] = "[SHELL.Controls.PDA]"
  L0_2.dlc_car_boost = L1_2
  L1_2 = {}
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD1_U
  L1_2[L2_2] = "[SHELL.Controls.Show_Cash_And_Fuel]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD1_D
  L1_2[L2_2] = "[SHELL.Controls.Show_Cash_And_Fuel]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD1_R
  L1_2[L2_2] = "[SHELL.Controls.Camera_Mode]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_U
  L1_2[L2_2] = "[SHELL.Controls.Exit]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_D
  L1_2[L2_2] = "[SHELL.Controls.Forward]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_L
  L1_2[L2_2] = "[SHELL.Controls.Reverse]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_L_STICK_L
  L1_2[L2_2] = "[SHELL.Controls.TurnLR]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_R_STICK_L
  L1_2[L2_2] = "[SHELL.Controls.Look_LR]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_R_STICK_U
  L1_2[L2_2] = "[SHELL.Controls.PitchUpDown]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT1_1
  L1_2[L2_2] = "[SHELL.Controls.Handbrake]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_1
  L1_2[L2_2] = "[SHELL.Controls.Fire_Primary]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_2
  L1_2[L2_2] = "[SHELL.Controls.Jump]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_3
  L1_2[L2_2] = "[SHELL.Controls.Reset_Camera]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_SYS1
  L1_2[L2_2] = "[SHELL.Controls.Pause]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_SYS2
  L1_2[L2_2] = "[SHELL.Controls.PDA]"
  L0_2.dlc_car_singleweaponjump = L1_2
  L1_2 = {}
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD1_U
  L1_2[L2_2] = "[SHELL.Controls.Show_Cash_And_Fuel]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD1_D
  L1_2[L2_2] = "[SHELL.Controls.Show_Cash_And_Fuel]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_U
  L1_2[L2_2] = "[SHELL.Controls.Exit]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_D
  L1_2[L2_2] = "[SHELL.Controls.Forward]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_L
  L1_2[L2_2] = "[SHELL.Controls.Reverse]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_PAD2_R
  L1_2[L2_2] = "[SHELL.Controls.Call_Allies]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_L_STICK_L
  L1_2[L2_2] = "[SHELL.Controls.TurnLR]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_L_STICK_U
  L1_2[L2_2] = "[SHELL.Controls.Move]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_R_STICK_L
  L1_2[L2_2] = "[SHELL.Controls.Aim_LR]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_R_STICK_U
  L1_2[L2_2] = "[SHELL.Controls.Aim_UD]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT1_2
  L1_2[L2_2] = "[SHELL.Controls.callstrike]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_1
  L1_2[L2_2] = "[SHELL.Controls.Fire_Primary]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_2
  L1_2[L2_2] = "[SHELL.Controls.Switch_Primary]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_ALT2_3
  L1_2[L2_2] = "[SHELL.Controls.Reset_Camera]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_SYS1
  L1_2[L2_2] = "[SHELL.Controls.Pause]"
  L2_2 = Joystick
  L2_2 = L2_2.BUTTON_SYS2
  L1_2[L2_2] = "[SHELL.Controls.PDA]"
  L0_2.dlc_tank_strike = L1_2
  tControlMap = L0_2
end

Init = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxGuiDialogBox
  L1_2 = L1_2.oSystemDialogBoxFlash
  if L1_2 then
    return
  end
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bActive
  if L1_2 then
    return
  end
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bHaveFlash
  if not L1_2 then
    L1_2 = A0_2.CustomData
    L1_2 = L1_2.bLoading
    if not L1_2 then
      L1_2 = A0_2.CustomData
      L1_2 = L1_2.oMapFlash
      L2_2 = MrxGuiBase
      L2_2 = L2_2.AddWidget
      L3_2 = L1_2
      L2_2(L3_2)
      L2_2 = A0_2.CustomData
      L2_2.bLoading = true
      L3_2 = L1_2
      L2_2 = L1_2.SetSwfFile
      L4_2 = L1_2.CustomData
      L4_2 = L4_2.sFile
      L5_2 = _FinishPauseOpen
      L6_2 = {}
      L7_2 = A0_2
      L6_2[1] = L7_2
      L2_2(L3_2, L4_2, L5_2, L6_2)
    end
  end
end

OpenPauseScreen = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L1_2 = _FinishLoad
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = MrxSound
  L1_2 = L1_2.EnterPauseState
  L1_2()
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oMapFlash
  L2_2 = L1_2
  L1_2 = L1_2.Restart
  L1_2(L2_2)
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oMapFlash
  L2_2 = L1_2
  L1_2 = L1_2.Play
  L1_2(L2_2)
  L1_2 = A0_2.CustomData
  L1_2.bActive = true
  L1_2 = MrxGuiBase
  L1_2 = L1_2.GetControlFocus
  L2_2 = A0_2
  L3_2 = true
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.SetVisible
  L3_2 = true
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = MrxGuiBase
    L7_2 = L7_2.AddWidgetWithChildren
    L8_2 = L6_2
    L7_2(L8_2)
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oMapFlash
  L3_2 = MrxPlayState
  L3_2 = L3_2.Get
  L3_2 = L3_2()
  L4_2 = MrxPlayState
  L4_2 = L4_2._knMission
  L3_2 = L3_2 == L4_2
  L4_2 = WifMissionFlow
  L4_2 = L4_2.GetLastCompletedContractName
  L4_2 = L4_2()
  if not L4_2 then
    L4_2 = "none"
  end
  L5_2 = MrxPlayState
  L5_2 = L5_2.GetTotalTimeElapsed
  L5_2 = L5_2()
  L6_2 = _GuiInternal
  L6_2 = L6_2.SetFlashPauseMenu
  L7_2 = L2_2.BasicData
  L7_2 = L7_2.uId
  L8_2 = L3_2
  L9_2 = L4_2
  L10_2 = L5_2
  L11_2 = MrxStatsManager
  L11_2 = L11_2.GetPercentCompleted
  L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L11_2()
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
  L6_2 = Player
  L6_2 = L6_2.GetLocalPlayer
  L6_2 = L6_2()
  if L6_2 then
    L7_2 = MrxGuiManager
    L7_2 = L7_2.GetHudState
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    L8_2 = A0_2.CustomData
    L8_2 = L8_2.tHudStates
    L8_2[L6_2] = L7_2
    if L7_2 then
      L8_2 = MrxGuiManager
      L8_2 = L8_2.ToggleHud
      L9_2 = L6_2
      L10_2 = false
      L8_2(L9_2, L10_2)
    end
    L8_2 = Player
    L8_2 = L8_2.GetControlBindingType
    L9_2 = L6_2
    L8_2 = L8_2(L9_2)
    L9_2 = tControlMap
    L9_2 = L9_2[L8_2]
    if not L9_2 then
      L9_2 = {}
    end
    L10_2 = Vehicle
    L10_2 = L10_2.GetFromRider
    L11_2 = Player
    L11_2 = L11_2.GetLocalCharacter
    L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L11_2()
    L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
    if L8_2 == "car" then
      L11_2 = Pg
      L11_2 = L11_2.GetGuidByName
      L12_2 = "BombCar"
      L11_2 = L11_2(L12_2)
      if L10_2 == L11_2 then
        L11_2 = tControlMap
        L9_2 = L11_2.dlc_car_boost
      else
        L11_2 = Object
        L11_2 = L11_2.GetParent
        L12_2 = L10_2
        L11_2 = L11_2(L12_2)
        L12_2 = Pg
        L12_2 = L12_2.GetGuidByName
        L13_2 = "Panhard (DLCCON004)"
        L12_2 = L12_2(L13_2)
        if L11_2 == L12_2 then
          L11_2 = tControlMap
          L9_2 = L11_2.dlc_car_singleweaponjump
        end
      end
    elseif L8_2 == "tank" then
      L11_2 = Object
      L11_2 = L11_2.GetParent
      L12_2 = L10_2
      L11_2 = L11_2(L12_2)
      L12_2 = Pg
      L12_2 = L12_2.GetGuidByName
      L13_2 = "DLC_M1A3"
      L12_2 = L12_2(L13_2)
      if L11_2 == L12_2 then
        L11_2 = tControlMap
        L9_2 = L11_2.dlc_tank_strike
      end
    end
    L11_2 = pairs
    L12_2 = L9_2
    L11_2, L12_2, L13_2 = L11_2(L12_2)
    for L14_2, L15_2 in L11_2, L12_2, L13_2 do
      L17_2 = L2_2
      L16_2 = L2_2.CallActionScriptCallback
      L18_2 = "controllerDisplay"
      L19_2 = {}
      L20_2 = L14_2
      L21_2 = L15_2
      L19_2[1] = L20_2
      L19_2[2] = L21_2
      L16_2(L17_2, L18_2, L19_2)
    end
  end
  L7_2 = true
  L8_2 = Sys
  L8_2 = L8_2.SubtitlesEnabled
  if L8_2 then
    L8_2 = Sys
    L8_2 = L8_2.SubtitlesEnabled
    L8_2 = L8_2()
    L7_2 = L8_2
  end
  L9_2 = L2_2
  L8_2 = L2_2.CallActionScriptCallback
  L10_2 = "videoSubtitles"
  L11_2 = {}
  L12_2 = L7_2
  L11_2[1] = L12_2
  L8_2(L9_2, L10_2, L11_2)
  L8_2 = true
  L9_2 = Sys
  L9_2 = L9_2.RumbleEnabled
  if L9_2 then
    L9_2 = Sys
    L9_2 = L9_2.RumbleEnabled
    L9_2 = L9_2()
    L8_2 = L9_2
  end
  L10_2 = L2_2
  L9_2 = L2_2.CallActionScriptCallback
  L11_2 = "gameRumble"
  L12_2 = {}
  L13_2 = L8_2
  L12_2[1] = L13_2
  L9_2(L10_2, L11_2, L12_2)
  L9_2 = true
  bTutorials = L9_2
  L9_2 = Sys
  L9_2 = L9_2.TutorialsEnabled
  if L9_2 then
    L9_2 = Sys
    L9_2 = L9_2.TutorialsEnabled
    L9_2 = L9_2()
    bTutorials = L9_2
  end
  L10_2 = L2_2
  L9_2 = L2_2.CallActionScriptCallback
  L11_2 = "gameTutorials"
  L12_2 = {}
  L13_2 = bTutorials
  L12_2[1] = L13_2
  L9_2(L10_2, L11_2, L12_2)
  L9_2 = false
  L10_2 = Sys
  L10_2 = L10_2.YAxisInverted
  if L10_2 then
    L10_2 = Sys
    L10_2 = L10_2.YAxisInverted
    L10_2 = L10_2()
    L9_2 = L10_2
  end
  L11_2 = L2_2
  L10_2 = L2_2.CallActionScriptCallback
  L12_2 = "gameinvert"
  L13_2 = {}
  L14_2 = L9_2
  L13_2[1] = L14_2
  L10_2(L11_2, L12_2, L13_2)
  L10_2 = false
  L11_2 = MrxPlayState
  L11_2 = L11_2.IsFree
  L11_2 = L11_2()
  if not L11_2 then
    L10_2 = true
  end
  L12_2 = L2_2
  L11_2 = L2_2.CallActionScriptCallback
  L13_2 = "activeContract"
  L14_2 = {}
  L15_2 = L10_2
  L14_2[1] = L15_2
  L11_2(L12_2, L13_2, L14_2)
  L11_2 = MrxPlayer
  L11_2 = L11_2.CanMedEvac
  L11_2 = L11_2()
  L13_2 = L2_2
  L12_2 = L2_2.CallActionScriptCallback
  L14_2 = "medevacEnable"
  L15_2 = {}
  L16_2 = L11_2
  L15_2[1] = L16_2
  L12_2(L13_2, L14_2, L15_2)
  L12_2 = A0_2.CustomData
  L12_2 = L12_2.bSaveDisabled
  if L12_2 then
    L13_2 = L2_2
    L12_2 = L2_2.CallActionScriptCallback
    L14_2 = "disableSave"
    L15_2 = {}
    L16_2 = true
    L15_2[1] = L16_2
    L12_2(L13_2, L14_2, L15_2)
  end
end

_FinishPauseOpen = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bActive
  if not L1_2 then
    return
  end
  L1_2 = A0_2.CustomData
  L1_2.bActive = false
  L1_2 = MrxGuiBase
  L1_2 = L1_2.ReleaseControlFocus
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bHaveFlash
  if L1_2 then
    L1_2 = A0_2.CustomData
    L1_2 = L1_2.oMapFlash
    L2_2 = L1_2
    L1_2 = L1_2.CallActionScriptCallback
    L3_2 = "saveProfile"
    L4_2 = {}
    L1_2(L2_2, L3_2, L4_2)
    L1_2 = A0_2.CustomData
    L1_2 = L1_2.oMapFlash
    L2_2 = L1_2
    L1_2 = L1_2.Pause
    L1_2(L2_2)
    L1_2 = A0_2.CustomData
    L1_2 = L1_2.oMapFlash
    L2_2 = L1_2
    L1_2 = L1_2.SetSwfFile
    L3_2 = nil
    L1_2(L2_2, L3_2)
    L1_2 = A0_2.CustomData
    L1_2.bHaveFlash = false
  else
    L1_2 = A0_2.CustomData
    L1_2 = L1_2.bLoading
    if L1_2 then
      L1_2 = A0_2.CustomData
      L1_2 = L1_2.oMapFlash
      L2_2 = L1_2
      L1_2 = L1_2.SetSwfFile
      L3_2 = nil
      L1_2(L2_2, L3_2)
      L1_2 = A0_2.CustomData
      L1_2.bLoading = false
    end
  end
  L2_2 = A0_2
  L1_2 = A0_2.SetVisible
  L3_2 = false
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = MrxGuiBase
    L7_2 = L7_2.RemoveWidgetWithChildren
    L8_2 = L6_2
    L7_2(L8_2)
  end
  L2_2 = Player
  L2_2 = L2_2.GetLocalPlayer
  L2_2 = L2_2()
  if L2_2 then
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.tHudStates
    L3_2 = L3_2[L2_2]
    if L3_2 then
      L3_2 = MrxGuiManager
      L3_2 = L3_2.ToggleHud
      L4_2 = L2_2
      L5_2 = true
      L3_2(L4_2, L5_2)
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.tHudStates
      L3_2[L2_2] = nil
    end
  end
  L3_2 = MrxSound
  L3_2 = L3_2.ExitPauseState
  L3_2()
  L3_2 = 3
  L4_2 = {}
  L4_2.EventType = "GuiShowAmmoCounter"
  L4_2.bShowGun = true
  L4_2.bShowExplosive = true
  L4_2.nTime = L3_2
  L5_2 = MrxGuiBase
  L5_2 = L5_2.SentEvent
  L6_2 = L4_2
  L5_2(L6_2)
  L5_2 = {}
  L5_2.EventType = "ShowAllCounters"
  L5_2.nTime = L3_2
  L6_2 = MrxGuiBase
  L6_2 = L6_2.SentEvent
  L7_2 = L5_2
  L6_2(L7_2)
  L6_2 = bTutorials
  if L6_2 == true then
    L6_2 = Sys
    L6_2 = L6_2.TutorialsEnabled
    L6_2 = L6_2()
    if L6_2 == false then
      L6_2 = MrxTutorialManager
      L6_2 = L6_2.HideMessage
      L7_2 = true
      L6_2(L7_2)
    end
  end
end

ClosePauseScreen = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  if nil ~= A1_2 then
    L2_2 = A0_2.CustomData
    L3_2 = not A1_2
    L2_2.bSaveDisabled = L3_2
  end
end

SetUserSaveEnabled = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.bImposterEnabled
  if L3_2 then
    return
  end
  if not A1_2 or not A2_2 then
    return
  end
  if "Pause" ~= A1_2 then
    return
  end
  if "Enter" == A2_2 then
    L3_2 = OpenPauseScreen
    L4_2 = A0_2
    L3_2(L4_2)
  elseif "Exit" == A2_2 then
    L3_2 = ClosePauseScreen
    L4_2 = A0_2
    L3_2(L4_2)
  end
  L3_2 = MrxGuiBase
  L3_2 = L3_2.ChangeScreenResolution
  L3_2()
end

HandleStateChangeEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L3_2 = A0_2
  L2_2 = A0_2.SetUseImmortalEvents
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = A0_2.CustomData
  L4_2 = A0_2
  L3_2 = A0_2.GetChildren
  L3_2 = L3_2(L4_2)
  L3_2 = L3_2[3]
  L2_2.oMenu = L3_2
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L2_2 = L2_2[1]
  L3_2 = L2_2
  L2_2 = L2_2.SetFullscreen
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = ClosePauseScreen
  L3_2 = A0_2
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2.SetEventHandler
  L4_2 = "GuiStateChangeEvent"
  L5_2 = nil
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = A0_2
  L2_2 = A0_2.SetEventHandler
  L4_2 = "GuiStateChangeEvent"
  L5_2 = HandleStateChangeEvent
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = A0_2.CustomData
  L3_2 = {}
  L2_2.tHudStates = L3_2
end

HandleInitializationEvent = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2
  L1_2 = A0_2.SetUseImmortalEvents
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = A0_2.CustomData
  L1_2.bActive = true
  L1_2 = MrxGuiBase
  L1_2 = L1_2.ImageWidget
  L2_2 = L1_2
  L1_2 = L1_2.new
  L1_2 = L1_2(L2_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetTransient
  L4_2 = false
  L2_2(L3_2, L4_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetFullscreen
  L4_2 = true
  L2_2(L3_2, L4_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetColor
  L4_2 = 0
  L5_2 = 0
  L6_2 = 0
  L7_2 = 192
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = A0_2
  L2_2 = A0_2.AddChild
  L4_2 = L1_2
  L2_2(L3_2, L4_2)
  L1_2.oParentWidget = A0_2
  L2_2 = MrxGuiBase
  L2_2 = L2_2.FlashWidget
  L3_2 = L2_2
  L2_2 = L2_2.new
  L2_2 = L2_2(L3_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetTransient
  L5_2 = false
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetAnchoring
  L5_2 = "center"
  L6_2 = "center"
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = 283.33334
  L5_2 = L2_2
  L4_2 = L2_2.SetLocation
  L6_2 = 320 - L3_2
  L7_2 = 0
  L8_2 = 320 + L3_2
  L9_2 = 480
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  L5_2 = A0_2
  L4_2 = A0_2.AddChild
  L6_2 = L2_2
  L4_2(L5_2, L6_2)
  L4_2 = A0_2.CustomData
  L4_2.oMapFlash = L2_2
  L4_2 = L2_2.CustomData
  L4_2.sFile = "pause_menu"
  L2_2.oParentWidget = A0_2
  L4_2 = OpenPauseScreen
  A0_2.Open = L4_2
  L4_2 = ClosePauseScreen
  A0_2.Close = L4_2
  L4_2 = SetUserSaveEnabled
  A0_2.SetUserSaveEnabled = L4_2
  L5_2 = A0_2
  L4_2 = A0_2.SetEventHandler
  L6_2 = "ControllerInput"
  L7_2 = _HandleInput
  L4_2(L5_2, L6_2, L7_2)
  A0_2.nAnalogInputHeld = 0
  L4_2 = A0_2.CustomData
  L5_2 = {}
  L4_2.tHudStates = L5_2
  L4_2 = Pg
  L4_2 = L4_2.LoadAsset
  L5_2 = "pause_graphic"
  L6_2 = "texture"
  L4_2(L5_2, L6_2)
  L5_2 = A0_2
  L4_2 = A0_2.Close
  L4_2(L5_2)
end

_Initialize = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = A0_2.CustomData
  L1_2.bHaveFlash = true
  L1_2 = A0_2.CustomData
  L1_2.bLoading = false
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.oMapFlash
  L3_2 = L1_2
  L2_2 = L1_2.SetFlashEventHandler
  L4_2 = "quitGame"
  L5_2 = _HandleQuitEvent
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetFlashEventHandler
  L4_2 = "closePause"
  L5_2 = _HandleCloseEvent
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetFlashEventHandler
  L4_2 = "messageMedEvac"
  L5_2 = _ConfirmMedEvacEvent
  L2_2(L3_2, L4_2, L5_2)
  L3_2 = L1_2
  L2_2 = L1_2.SetFlashEventHandler
  L4_2 = "messageButton"
  L5_2 = _HandleMedEvacEvent
  L6_2 = {}
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L3_2 = L1_2
  L2_2 = L1_2.Pause
  L2_2(L3_2)
end

_FinishLoad = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bActive
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.Close
    L2_2(L3_2)
  else
    L3_2 = A0_2
    L2_2 = A0_2.Open
    L2_2(L3_2)
  end
end

_HandleToggleEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oMapFlash
  L3_2 = L2_2.EventHandlers
  L3_2 = L3_2.ControllerInput
  L4_2 = L2_2
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
end

_HandleInput = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.oParentWidget
  L2_2 = L1_2.CustomData
  L2_2 = L2_2.bActive
  if L2_2 then
    L2_2 = Sys
    L2_2 = L2_2.RequestGameState
    L3_2 = "ingame"
    L2_2(L3_2)
    L3_2 = L1_2
    L2_2 = L1_2.Close
    L2_2(L3_2)
  end
end

_HandleCloseEvent = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.oParentWidget
  L2_2 = Sys
  L2_2 = L2_2.RequestGameState
  L3_2 = "unloading"
  L2_2(L3_2)
  L2_2 = Net
  L2_2 = L2_2.QuitGame
  L2_2()
  L3_2 = L1_2
  L2_2 = L1_2.Close
  L2_2(L3_2)
end

_HandleQuitEvent = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = MrxUtil
  L1_2 = L1_2.FormatMoney
  L2_2 = MrxPlayer
  L2_2 = L2_2.GetMedEvacCost
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L2_2()
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L3_2 = A0_2
  L2_2 = A0_2.CallActionScriptCallback
  L4_2 = "onlineMessage"
  L5_2 = {}
  L6_2 = "[SHELL.Confirmation.AreYouSure]"
  L7_2 = "[PauseMenu.Base.MedEvacMessage] "
  L8_2 = L1_2
  L9_2 = " [PauseMenu.Base.MedEvacMessageEnd]"
  L7_2 = L7_2 .. L8_2 .. L9_2
  L8_2 = 2
  L9_2 = "[SHELL.Confirmation.Yes]"
  L10_2 = "[SHELL.Confirmation.No]"
  L11_2 = "messageMedEvac"
  L12_2 = true
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L5_2[7] = L12_2
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = true
  _bMedEvac = L2_2
end

_ConfirmMedEvacEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = _bMedEvac
  if not L2_2 then
    return
  end
  L2_2 = nil
  _bMedEvac = L2_2
  L3_2 = A0_2
  L2_2 = A0_2.CallActionScriptCallback
  L4_2 = "onlineMessageClose"
  L5_2 = {}
  L2_2(L3_2, L4_2, L5_2)
  if A1_2 == "1" then
    L2_2 = MrxPlayer
    L2_2 = L2_2.MedEvac
    L2_2()
    L2_2 = Sys
    L2_2 = L2_2.RequestGameState
    L3_2 = "ingame"
    L2_2(L3_2)
  end
end

_HandleMedEvacEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L2_2 = L2_2[1]
  L3_2 = L2_2
  L2_2 = L2_2.SetFullscreen
  L4_2 = true
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2.SetVisible
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = A0_2.CustomData
  L2_2.bReceiveInput = false
  L2_2 = pairs
  L4_2 = A0_2
  L3_2 = A0_2.GetChildren
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L3_2(L4_2)
  L2_2, L3_2, L4_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L8_2 = L6_2
    L7_2 = L6_2.SetEnabled
    L9_2 = false
    L7_2(L8_2, L9_2)
  end
end

HandleImposterInitializationEvent = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.bImposterEnabled
  if not L3_2 then
    return
  end
  if not A1_2 or not A2_2 then
    return
  end
  if "Pause" ~= A1_2 then
    return
  end
  if "Enter" == A2_2 then
    L4_2 = A0_2
    L3_2 = A0_2.SetVisible
    L5_2 = true
    L3_2(L4_2, L5_2)
    L3_2 = A0_2.CustomData
    L3_2.bReceiveInput = true
    L3_2 = pairs
    L5_2 = A0_2
    L4_2 = A0_2.GetChildren
    L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L4_2(L5_2)
    L3_2, L4_2, L5_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
    for L6_2, L7_2 in L3_2, L4_2, L5_2 do
      L9_2 = L7_2
      L8_2 = L7_2.SetEnabled
      L10_2 = true
      L8_2(L9_2, L10_2)
    end
  elseif "Exit" == A2_2 then
    L4_2 = A0_2
    L3_2 = A0_2.SetVisible
    L5_2 = false
    L3_2(L4_2, L5_2)
    L3_2 = A0_2.CustomData
    L3_2.bReceiveInput = false
    L3_2 = pairs
    L5_2 = A0_2
    L4_2 = A0_2.GetChildren
    L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L4_2(L5_2)
    L3_2, L4_2, L5_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
    for L6_2, L7_2 in L3_2, L4_2, L5_2 do
      L9_2 = L7_2
      L8_2 = L7_2.SetEnabled
      L10_2 = false
      L8_2(L9_2, L10_2)
    end
    L3_2 = {}
    tEvent = L3_2
    L3_2 = tEvent
    L3_2.EventType = "ImposterShellEvent"
    L3_2 = tEvent
    L3_2.bOn = false
    L3_2 = MrxGuiBase
    L3_2 = L3_2.SentEvent
    L4_2 = tEvent
    L3_2(L4_2)
  end
  L3_2 = MrxGuiBase
  L3_2 = L3_2.ChangeScreenResolution
  L3_2()
end

HandleImposterStateChangeEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bReceiveInput
  if L2_2 then
    L2_2 = MrxGuiBase
    L2_2 = L2_2.Joystick
    L2_2 = L2_2.BUTTON_PAD2_D
    L3_2 = A1_2.ButtonPress
    if L2_2 == L3_2 then
      L2_2 = Sys
      L2_2 = L2_2.RequestGameState
      L3_2 = "ingame"
      L2_2(L3_2)
    end
  end
end

HandleImposterInputEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2
  L2_2 = A1_2.bOn
  if L2_2 then
    L2_2 = A0_2.CustomData
    L2_2.bImposterEnabled = true
  else
    L2_2 = A0_2.CustomData
    L2_2.bImposterEnabled = false
  end
end

HandleImposterEvent = L0_1
