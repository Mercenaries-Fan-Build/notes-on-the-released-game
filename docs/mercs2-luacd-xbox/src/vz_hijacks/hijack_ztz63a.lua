local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1
L0_1 = import
L1_1 = "MrxActionHijack"
L0_1(L1_1)
L0_1 = "all_ZTZ63a_driverhatch_actionhijack_getin_section01_fb"
L1_1 = "all_ZTZ63a_driverhatch_actionhijack_getin_section01fail_fb"
L2_1 = "all_ZTZ63a_driverhatch_actionhijack_getin_section02_fb"
L3_1 = "all_ZTZ63a_driverhatch_actionhijack_getin_loopa_fb"
L4_1 = "all_ZTZ63a_driverhatch_actionhijack_getin_section02loopfailure_fb"
L5_1 = "all_ZTZ63a_driverhatch_actionhijack_getin_section03_fb"

function L6_1()
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
  L1_2 = Pg
  L1_2 = L1_2.LoadAsset
  L2_2 = L5_1
  L3_2 = L0_2
  L1_2(L2_2, L3_2)
end

Init = L6_1

function L6_1()
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
  L1_2 = Pg
  L1_2 = L1_2.UnloadAsset
  L2_2 = L5_1
  L3_2 = L0_2
  L1_2(L2_2, L3_2)
end

Deinit = L6_1

function L6_1(A0_2, A1_2, A2_2, A3_2)
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

StartHijack = L6_1

function L6_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
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
  L6_2 = MrxActionHijack
  L6_2 = L6_2.TankPrep
  L7_2 = A1_2
  L6_2(L7_2)
  L6_2 = {}
  L6_2.hijackerAnimation = "ActionHijackHijackerA"
  L6_2.hijackeeAnimation = "ActionHijackHijackeeA"
  L6_2.hijackerAnimationFail = "ActionHijackHijackerFailA"
  L6_2.hijackeeAnimationFail = "ActionHijackHijackeeFailA"
  L7_2 = L0_1
  L6_2.vehicleAnimation = L7_2
  L7_2 = L1_1
  L6_2.vehicleAnimationFail = L7_2
  L7_2 = {}
  L8_2 = {}
  L8_2.nTime = 0.1
  L9_2 = {}
  L9_2.nlength = 0.2
  L8_2.tControllerRumble = L9_2
  L9_2 = {}
  L9_2.fSetCameraAmplitude = 2
  L9_2.fSetCameraShake = 0.1
  L8_2.tCameraShake = L9_2
  L7_2[1] = L8_2
  L6_2.tMultiEvents = L7_2
  L6_2.miniGameStartDelay = 1.71
  L7_2 = {}
  L7_2.nTimeOut = 0.75
  L7_2.sAction = "press"
  L7_2.bExtraHudParameters = true
  L7_2.nTranslucency = 255
  L7_2.bShowTimer = false
  L7_2.nHudButtonMotionSpeed = 0.25
  L7_2.nXPosition = 0.5
  L7_2.nYPosition = 0.2
  L8_2 = Controller
  L8_2 = L8_2.LStick_Right
  L7_2.button = L8_2
  L7_2.nScale = 1.2
  L6_2.miniGame = L7_2
  L7_2 = OnFailureEvents
  L6_2.OnFailureAnimationBegin = L7_2
  L7_2 = {}
  L8_2 = {}
  L8_2.nTime = 0.46
  L9_2 = {}
  L9_2.nlength = 0.5
  L8_2.tControllerRumble = L9_2
  L9_2 = {}
  L9_2.fSetCameraAmplitude = 2.5
  L9_2.fSetCameraShake = 0.1
  L8_2.tCameraShake = L9_2
  L7_2[1] = L8_2
  L6_2.tFailureMultiEvents = L7_2
  A1_2[1] = L6_2
  L6_2 = {}
  L6_2.hijackerAnimation = "ActionHijackHijackerB"
  L6_2.hijackeeAnimation = "ActionHijackHijackeeB"
  L7_2 = L2_1
  L6_2.vehicleAnimation = L7_2
  L7_2 = {}
  L8_2 = {}
  L8_2.nTime = 0.43
  L9_2 = {}
  L9_2.nlength = 0.2
  L8_2.tControllerRumble = L9_2
  L9_2 = {}
  L9_2.fSetCameraAmplitude = 2
  L9_2.fSetCameraShake = 0.1
  L8_2.tCameraShake = L9_2
  L9_2 = {}
  L9_2.nTime = 3.5
  L10_2 = {}
  L10_2.nlength = 0.2
  L9_2.tControllerRumble = L10_2
  L10_2 = {}
  L10_2.fSetCameraAmplitude = 1
  L10_2.fSetCameraShake = 0.1
  L9_2.tCameraShake = L10_2
  L10_2 = {}
  L10_2.nTime = 4.23
  L11_2 = {}
  L11_2.nlength = 0.2
  L10_2.tControllerRumble = L11_2
  L11_2 = {}
  L11_2.fSetCameraAmplitude = 1
  L11_2.fSetCameraShake = 0.1
  L10_2.tCameraShake = L11_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L6_2.tMultiEvents = L7_2
  A1_2[2] = L6_2
  L6_2 = {}
  L6_2.hijackerAnimationFail = "ActionHijackHijackerFailB"
  L6_2.hijackeeAnimationFail = "ActionHijackHijackeeFailB"
  L7_2 = L4_1
  L6_2.vehicleAnimationFail = L7_2
  L6_2.nReactiveLoop = 2
  L7_2 = {}
  L8_2 = "ActionHijackHijackerDLoopH"
  L9_2 = "ActionHijackHijackerDLoopG"
  L10_2 = "ActionHijackHijackerDLoopF"
  L11_2 = "ActionHijackHijackerDLoopD"
  L12_2 = "ActionHijackHijackerDLoopC"
  L13_2 = "ActionHijackHijackerDLoopB"
  L14_2 = "ActionHijackHijackerDLoopA"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L7_2[5] = L12_2
  L7_2[6] = L13_2
  L7_2[7] = L14_2
  L6_2.tHijackerAnimations = L7_2
  L7_2 = {}
  L8_2 = "ActionHijackHijackeeBLoopH"
  L9_2 = "ActionHijackHijackeeBLoopG"
  L10_2 = "ActionHijackHijackeeBLoopF"
  L11_2 = "ActionHijackHijackeeBLoopD"
  L12_2 = "ActionHijackHijackeeBLoopC"
  L13_2 = "ActionHijackHijackeeBLoopB"
  L14_2 = "ActionHijackHijackeeBLoopA"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L7_2[5] = L12_2
  L7_2[6] = L13_2
  L7_2[7] = L14_2
  L6_2.tHijackeeAnimations = L7_2
  L7_2 = {}
  L8_2 = L3_1
  L9_2 = L3_1
  L10_2 = L3_1
  L11_2 = L3_1
  L12_2 = L3_1
  L13_2 = L3_1
  L14_2 = L3_1
  L15_2 = L3_1
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L7_2[5] = L12_2
  L7_2[6] = L13_2
  L7_2[7] = L14_2
  L7_2[8] = L15_2
  L6_2.tVehicleAnimations = L7_2
  L6_2.miniGameStartDelay = 0.01
  L7_2 = {}
  L7_2.nTimeOut = 20
  L7_2.sAction = "tap"
  L8_2 = Controller
  L8_2 = L8_2.RPad_Down
  L7_2.button = L8_2
  L7_2.bExtraHudParameters = true
  L7_2.nTranslucency = 255
  L7_2.nXPosition = 0
  L7_2.nYPosition = 0.8
  L7_2.bShowTimer = false
  L7_2.nDriverDifficulty = 0.7
  L7_2.nSuccessThreshold = 1
  L6_2.miniGame = L7_2
  L7_2 = OnFailureEvents
  L6_2.OnFailureAnimationBegin = L7_2
  L7_2 = {}
  L8_2 = {}
  L8_2.nTime = 0.2
  L9_2 = {}
  L9_2.nlength = 0.5
  L8_2.tControllerRumble = L9_2
  L9_2 = {}
  L9_2.fSetCameraAmplitude = 1
  L9_2.fSetCameraShake = 0.1
  L8_2.tCameraShake = L9_2
  L7_2[1] = L8_2
  L6_2.tFailureMultiEvents = L7_2
  A1_2[3] = L6_2
  L6_2 = {}
  L6_2.hijackerAnimation = "ActionHijackHijackerC"
  L6_2.hijackeeAnimation = "ActionHijackHijackeeC"
  L7_2 = L5_1
  L6_2.vehicleAnimation = L7_2
  L7_2 = {}
  L8_2 = {}
  L8_2.nTime = 0
  L9_2 = {}
  L9_2.nlength = 0.2
  L8_2.tControllerRumble = L9_2
  L9_2 = {}
  L9_2.nTime = 1.03
  L10_2 = {}
  L10_2.nlength = 0.2
  L9_2.tControllerRumble = L10_2
  L10_2 = {}
  L10_2.fSetCameraAmplitude = 2
  L10_2.fSetCameraShake = 0.1
  L9_2.tCameraShake = L10_2
  L10_2 = {}
  L10_2.nTime = 1.73
  L11_2 = {}
  L11_2.nlength = 0.2
  L10_2.tControllerRumble = L11_2
  L11_2 = {}
  L11_2.fSetCameraAmplitude = 2
  L11_2.fSetCameraShake = 0.1
  L10_2.tCameraShake = L11_2
  L11_2 = {}
  L11_2.nTime = 2.8
  L12_2 = {}
  L12_2.nlength = 0.2
  L11_2.tControllerRumble = L12_2
  L12_2 = {}
  L12_2.fSetCameraAmplitude = 2.5
  L12_2.fSetCameraShake = 0.1
  L11_2.tCameraShake = L12_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L6_2.tMultiEvents = L7_2
  L6_2.bDriverDoneDead = true
  A1_2[4] = L6_2
  L6_2 = MrxActionHijack
  L6_2 = L6_2.Begin
  L7_2 = A1_2
  L8_2 = 1
  L6_2(L7_2, L8_2)
  return A1_2
end

Initialize = L6_1

function L6_1(A0_2, A1_2)
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

OnFailureEvents = L6_1
