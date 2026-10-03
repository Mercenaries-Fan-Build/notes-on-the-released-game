local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1
L0_1 = import
L1_1 = "MrxActionHijack"
L0_1(L1_1)
L0_1 = "All_M2A3_driverdoor_actionhijack_getin_section01_fb"
L1_1 = "All_M2A3_driverdoor_actionhijack_getin_failsection01_fb"
L2_1 = "All_M2A3_driverdoor_actionhijack_getin_section02_fb"
L3_1 = "All_M2A3_driverdoor_actionhijack_getin_failsection02_fb"
L4_1 = "All_M2A3_driverdoor_actionhijack_getin_section03_fb"

function L5_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = "animation"
  L1_2 = Pg
  L1_2 = L1_2.LoadAsset
  L2_2 = L0_1
  L3_2 = L0_2
  L1_2(L2_2, L3_2)
  L1_2 = Pg
  L1_2 = L1_2.LoadAsset
  L2_2 = L1_1
  L3_2 = L0_2
  L1_2(L2_2, L3_2)
  L1_2 = Pg
  L1_2 = L1_2.LoadAsset
  L2_2 = L2_1
  L3_2 = L0_2
  L1_2(L2_2, L3_2)
  L1_2 = Pg
  L1_2 = L1_2.LoadAsset
  L2_2 = L3_1
  L3_2 = L0_2
  L1_2(L2_2, L3_2)
  L1_2 = Pg
  L1_2 = L1_2.LoadAsset
  L2_2 = L4_1
  L3_2 = L0_2
  L1_2(L2_2, L3_2)
end

Init = L5_1

function L5_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = "animation"
  L1_2 = Pg
  L1_2 = L1_2.UnloadAsset
  L2_2 = L0_1
  L3_2 = L0_2
  L1_2(L2_2, L3_2)
  L1_2 = Pg
  L1_2 = L1_2.UnloadAsset
  L2_2 = L1_1
  L3_2 = L0_2
  L1_2(L2_2, L3_2)
  L1_2 = Pg
  L1_2 = L1_2.UnloadAsset
  L2_2 = L2_1
  L3_2 = L0_2
  L1_2(L2_2, L3_2)
  L1_2 = Pg
  L1_2 = L1_2.UnloadAsset
  L2_2 = L3_1
  L3_2 = L0_2
  L1_2(L2_2, L3_2)
  L1_2 = Pg
  L1_2 = L1_2.UnloadAsset
  L2_2 = L4_1
  L3_2 = L0_2
  L1_2(L2_2, L3_2)
end

Deinit = L5_1

function L5_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L4_2 = _THIS
  L5_2 = L4_2
  L4_2 = L4_2.Initialize
  L6_2 = nil
  L7_2 = A0_2
  L8_2 = A1_2
  L9_2 = A2_2
  L10_2 = A3_2
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  L4_2 = true
  return L4_2
end

StartHijack = L5_1

function L5_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  if not A1_2 then
    L6_2 = {}
    A1_2 = L6_2
  end
  A1_2._hijacker = A2_2
  A1_2._hijackee = A3_2
  A1_2._seat = A4_2
  A1_2._vehicle = A5_2
  L6_2 = setmetatable
  L7_2 = A1_2
  L8_2 = {}
  L8_2.__index = A0_2
  L6_2(L7_2, L8_2)
  L6_2 = Object
  L6_2 = L6_2.IsPlayerControlled
  L7_2 = A1_2._hijacker
  L6_2 = L6_2(L7_2)
  A1_2._hijackerPlayer = L6_2
  L6_2 = MrxActionHijack
  L6_2 = L6_2.InitializeActionHijack
  L7_2 = A1_2
  L6_2(L7_2)
  L6_2 = Vehicle
  L6_2 = L6_2.SetTurretYaw
  L7_2 = A1_2._vehicle
  L8_2 = "main_turret"
  L9_2 = 0
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  L7_2 = Vehicle
  L7_2 = L7_2.EnableTurret
  L8_2 = A1_2._vehicle
  L9_2 = "main_turret"
  L10_2 = false
  L11_2 = "all"
  L12_2 = true
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L6_2 = L7_2
  L7_2 = MrxActionHijack
  L7_2 = L7_2.TankPrep
  L8_2 = A1_2
  L7_2(L8_2)
  L7_2 = {}
  L7_2.hijackerAnimation = "ActionHijackHijackerA"
  L7_2.hijackeeAnimation = "ActionHijackHijackeeA"
  L7_2.hijackerAnimationFail = "ActionHijackHijackerFailA"
  L7_2.hijackeeAnimationFail = "ActionHijackHijackeeFailA"
  L8_2 = L0_1
  L7_2.vehicleAnimation = L8_2
  L8_2 = L1_1
  L7_2.vehicleAnimationFail = L8_2
  L8_2 = {}
  L9_2 = {}
  L9_2.nTime = 0.73
  L10_2 = {}
  L10_2.nlength = 0.2
  L9_2.tControllerRumble = L10_2
  L10_2 = {}
  L10_2.fSetCameraAmplitude = 1
  L10_2.fSetCameraShake = 0.1
  L9_2.tCameraShake = L10_2
  L8_2[1] = L9_2
  L7_2.tMultiEvents = L8_2
  L7_2.miniGameStartDelay = 2.83
  L8_2 = {}
  L8_2.nTimeOut = 0.5
  L8_2.sAction = "press"
  L8_2.bExtraHudParameters = true
  L8_2.nTranslucency = 255
  L8_2.bShowTimer = false
  L8_2.nHudButtonMotionSpeed = 0.25
  L8_2.nXPosition = 0
  L8_2.nYPosition = -0.4
  L9_2 = Controller
  L9_2 = L9_2.LStick_Up
  L8_2.button = L9_2
  L8_2.nScale = 1.2
  L7_2.miniGame = L8_2
  L8_2 = OnFailureEvents
  L7_2.OnFailureAnimationBegin = L8_2
  L8_2 = {}
  L9_2 = {}
  L9_2.nTime = 0
  L10_2 = {}
  L10_2.nlength = 0.2
  L9_2.tControllerRumble = L10_2
  L10_2 = {}
  L10_2.fSetCameraAmplitude = 2.5
  L10_2.fSetCameraShake = 0.1
  L9_2.tCameraShake = L10_2
  L10_2 = {}
  L10_2.nTime = 1.8
  L11_2 = {}
  L11_2.nlength = 0.5
  L10_2.tControllerRumble = L11_2
  L11_2 = {}
  L11_2.fSetCameraAmplitude = 2.5
  L11_2.fSetCameraShake = 0.1
  L10_2.tCameraShake = L11_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L7_2.tFailureMultiEvents = L8_2
  A1_2[1] = L7_2
  L7_2 = {}
  L7_2.hijackerAnimation = "ActionHijackHijackerB"
  L7_2.hijackeeAnimation = "ActionHijackHijackeeB"
  L7_2.hijackerAnimationFail = "ActionHijackHijackerFailB"
  L7_2.hijackeeAnimationFail = "ActionHijackHijackeeFailB"
  L8_2 = L2_1
  L7_2.vehicleAnimation = L8_2
  L8_2 = L3_1
  L7_2.vehicleAnimationFail = L8_2
  L8_2 = {}
  L9_2 = {}
  L9_2.nTime = 0
  L10_2 = {}
  L10_2.nlength = 0.2
  L9_2.tControllerRumble = L10_2
  L10_2 = {}
  L10_2.fSetCameraAmplitude = 2.5
  L10_2.fSetCameraShake = 0.1
  L9_2.tCameraShake = L10_2
  L10_2 = {}
  L10_2.nTime = 1.33
  L11_2 = {}
  L11_2.nlength = 0.2
  L10_2.tControllerRumble = L11_2
  L11_2 = {}
  L11_2.fSetCameraAmplitude = 2
  L11_2.fSetCameraShake = 0.1
  L10_2.tCameraShake = L11_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L7_2.tMultiEvents = L8_2
  L7_2.miniGameStartDelay = 1.3
  L8_2 = {}
  L8_2.nTimeOut = 0.8
  L8_2.sAction = "press"
  L8_2.bExtraHudParameters = true
  L8_2.nTranslucency = 255
  L8_2.bShowTimer = false
  L8_2.nHudButtonMotionSpeed = 0.2
  L8_2.nXPosition = -0.5
  L8_2.nYPosition = 0.2
  L8_2.sAction = "press"
  L9_2 = Controller
  L9_2 = L9_2.RPad_Left
  L8_2.button = L9_2
  L7_2.miniGame = L8_2
  L8_2 = OnFailureEvents
  L7_2.OnFailureAnimationBegin = L8_2
  L8_2 = {}
  L9_2 = {}
  L9_2.nTime = 1
  L10_2 = {}
  L10_2.nlength = 0.2
  L9_2.tControllerRumble = L10_2
  L10_2 = {}
  L10_2.fSetCameraAmplitude = 2.5
  L10_2.fSetCameraShake = 0.1
  L9_2.tCameraShake = L10_2
  L10_2 = {}
  L10_2.nTime = 1.9
  L11_2 = {}
  L11_2.nlength = 0.5
  L10_2.tControllerRumble = L11_2
  L11_2 = {}
  L11_2.fSetCameraAmplitude = 1
  L11_2.fSetCameraShake = 0.1
  L10_2.tCameraShake = L11_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L7_2.tFailureMultiEvents = L8_2
  A1_2[2] = L7_2
  L7_2 = {}
  L7_2.hijackerAnimation = "ActionHijackHijackerC"
  L7_2.hijackeeAnimation = "ActionHijackHijackeeC"
  L8_2 = L4_1
  L7_2.vehicleAnimation = L8_2
  L8_2 = {}
  L9_2 = {}
  L9_2.nTime = 0.33
  L10_2 = {}
  L10_2.nlength = 0.2
  L9_2.tControllerRumble = L10_2
  L10_2 = {}
  L10_2.fSetCameraAmplitude = 2.5
  L10_2.fSetCameraShake = 0.1
  L9_2.tCameraShake = L10_2
  L8_2[1] = L9_2
  L7_2.tMultiEvents = L8_2
  L7_2.bDriverDoneDead = true
  A1_2[3] = L7_2
  L7_2 = MrxActionHijack
  L7_2 = L7_2.Begin
  L8_2 = A1_2
  L9_2 = 1
  L7_2(L8_2, L9_2)
  return A1_2
end

Initialize = L5_1

function L5_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2.nCurrent
  L2_2 = A0_2[L2_2]
  L2_2 = L2_2.tFailureMultiEvents
  L3_2 = A0_2._hijacker
  L4_2 = MrxActionHijack
  L4_2 = L4_2._ProcessMultiEventTable
  L5_2 = L3_2
  L6_2 = L2_2
  L4_2(L5_2, L6_2)
end

OnFailureEvents = L5_1
