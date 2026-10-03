local L0_1, L1_1, L2_1, L3_1
L0_1 = import
L1_1 = "MrxActionHijack"
L0_1(L1_1)
L0_1 = "All_Mi26_driverdoor_actionhijack_getin_section01_fb"
L1_1 = "All_Mi26_driverdoor_actionhijack_getin_section02_fb"
L2_1 = "All_Mi26_driverdoor_actionhijack_getin_section01failure_fb"

function L3_1()
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
end

Init = L3_1

function L3_1()
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
end

Deinit = L3_1

function L3_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L4_2 = MrxActionHijack
  L4_2 = L4_2.CheckGoodStart
  L5_2 = A3_2
  L6_2 = MrxActionHijack
  L6_2 = L6_2.RULESET_HELICOPTER
  L4_2 = L4_2(L5_2, L6_2)
  if L4_2 then
    L5_2 = _THIS
    L6_2 = L5_2
    L5_2 = L5_2.Initialize
    L7_2 = nil
    L8_2 = A0_2
    L9_2 = A1_2
    L10_2 = A2_2
    L11_2 = A3_2
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
    L5_2 = true
    return L5_2
  end
  L5_2 = false
  return L5_2
end

StartHijack = L3_1

function L3_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
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
  L6_2 = {}
  L6_2.hijackerAnimation = "ActionHijackHijackerA"
  L6_2.hijackeeAnimation = "ActionHijackHijackeeA"
  L7_2 = L0_1
  L6_2.vehicleAnimation = L7_2
  L6_2.hijackerAnimationFail = "ActionHijackHijackerFailA"
  L6_2.hijackeeAnimationFail = "ActionHijackHijackeeFailA"
  L7_2 = L2_1
  L6_2.vehicleAnimationFail = L7_2
  L6_2.miniGameStartDelay = 5.16
  L7_2 = {}
  L7_2.nTimeOut = 2.5
  L7_2.bExtraHudParameters = true
  L7_2.nTranslucency = 255
  L7_2.nXPosition = 0
  L7_2.nYPosition = 0.8
  L7_2.bShowTimer = false
  L7_2.sAction = "press"
  L8_2 = Controller
  L8_2 = L8_2.LStick_Down
  L7_2.button = L8_2
  L7_2.nScale = 1.2
  L7_2.nHudButtonMotionSpeed = 0.25
  L6_2.miniGame = L7_2
  L7_2 = {}
  L8_2 = {}
  L8_2.nTime = 0.13
  L9_2 = {}
  L9_2.nlength = 0.2
  L8_2.tControllerRumble = L9_2
  L9_2 = {}
  L9_2.fSetCameraAmplitude = 2.5
  L9_2.fSetCameraShake = 0.1
  L8_2.tCameraShake = L9_2
  L9_2 = {}
  L9_2.nTime = 2.06
  L10_2 = {}
  L10_2.nlength = 0.2
  L9_2.tControllerRumble = L10_2
  L10_2 = {}
  L10_2.nTime = 7.13
  L11_2 = {}
  L11_2.nlength = 0.2
  L10_2.tControllerRumble = L11_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L6_2.tMultiEvents = L7_2
  L7_2 = OnFailureEvents
  L6_2.OnFailureAnimationBegin = L7_2
  L7_2 = {}
  L8_2 = {}
  L8_2.nTime = 0.66
  L9_2 = {}
  L9_2.nlength = 0.2
  L8_2.tControllerRumble = L9_2
  L9_2 = {}
  L9_2.fSetCameraAmplitude = 2.5
  L9_2.fSetCameraShake = 0.1
  L8_2.tCameraShake = L9_2
  L9_2 = {}
  L9_2.nTime = 2.66
  L10_2 = {}
  L10_2.nlength = 0.5
  L9_2.tControllerRumble = L10_2
  L10_2 = {}
  L10_2.fSetCameraAmplitude = 2.5
  L10_2.fSetCameraShake = 0.1
  L9_2.tCameraShake = L10_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L6_2.tFailureMultiEvents = L7_2
  A1_2[1] = L6_2
  L6_2 = {}
  L6_2.hijackerAnimationFail = "ActionHijackHijackerFailA"
  L6_2.hijackeeAnimationFail = "ActionHijackHijackeeFailA"
  L7_2 = L2_1
  L6_2.vehicleAnimationFail = L7_2
  L6_2.nReactiveLoop = 2
  L7_2 = {}
  L8_2 = "ActionHijackHijackerDLoopA"
  L9_2 = "ActionHijackHijackerDLoopB"
  L10_2 = "ActionHijackHijackerDLoopC"
  L11_2 = "ActionHijackHijackerDLoopD"
  L12_2 = "ActionHijackHijackerDLoopE"
  L13_2 = "ActionHijackHijackerDLoopF"
  L14_2 = "ActionHijackHijackerDLoopG"
  L15_2 = "ActionHijackHijackerDLoopH"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L7_2[5] = L12_2
  L7_2[6] = L13_2
  L7_2[7] = L14_2
  L7_2[8] = L15_2
  L6_2.tHijackerAnimations = L7_2
  L7_2 = {}
  L8_2 = "ActionHijackHijackeeBLoopA"
  L9_2 = "ActionHijackHijackeeBLoopB"
  L10_2 = "ActionHijackHijackeeBLoopC"
  L11_2 = "ActionHijackHijackeeBLoopD"
  L12_2 = "ActionHijackHijackeeBLoopE"
  L13_2 = "ActionHijackHijackeeBLoopF"
  L14_2 = "ActionHijackHijackeeBLoopG"
  L15_2 = "ActionHijackHijackeeBLoopH"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L7_2[5] = L12_2
  L7_2[6] = L13_2
  L7_2[7] = L14_2
  L7_2[8] = L15_2
  L6_2.tHijackeeAnimations = L7_2
  L7_2 = {}
  L8_2 = L1_1
  L9_2 = L1_1
  L10_2 = L1_1
  L11_2 = L1_1
  L12_2 = L1_1
  L13_2 = L1_1
  L14_2 = L1_1
  L15_2 = L1_1
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
  L7_2.nTimeOut = 35
  L7_2.bExtraHudParameters = true
  L7_2.nTranslucency = 255
  L7_2.nXPosition = -0.5
  L7_2.nYPosition = 0.2
  L7_2.bShowTimer = false
  L7_2.sAction = "tap"
  L8_2 = Controller
  L8_2 = L8_2.RPad_Left
  L7_2.button = L8_2
  L7_2.nDriverDifficulty = 1.2
  L7_2.nSuccessThreshold = 1
  L6_2.miniGame = L7_2
  L7_2 = OnFailureEvents
  L6_2.OnFailureAnimationBegin = L7_2
  L7_2 = {}
  L8_2 = {}
  L8_2.nTime = 0.66
  L9_2 = {}
  L9_2.nlength = 0.2
  L8_2.tControllerRumble = L9_2
  L9_2 = {}
  L9_2.fSetCameraAmplitude = 2.5
  L9_2.fSetCameraShake = 0.1
  L8_2.tCameraShake = L9_2
  L9_2 = {}
  L9_2.nTime = 2.66
  L10_2 = {}
  L10_2.nlength = 0.5
  L9_2.tControllerRumble = L10_2
  L10_2 = {}
  L10_2.fSetCameraAmplitude = 2.5
  L10_2.fSetCameraShake = 0.1
  L9_2.tCameraShake = L10_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L6_2.tFailureMultiEvents = L7_2
  A1_2[2] = L6_2
  L6_2 = {}
  L6_2.hijackerAnimation = "ActionHijackHijackerB"
  L6_2.hijackeeAnimation = "ActionHijackHijackeeB"
  L7_2 = L1_1
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
  L9_2.nTime = 1.1
  L10_2 = {}
  L10_2.nlength = 0.2
  L9_2.tControllerRumble = L10_2
  L10_2 = {}
  L10_2.fSetCameraAmplitude = 2
  L10_2.fSetCameraShake = 0.1
  L9_2.tCameraShake = L10_2
  L10_2 = {}
  L10_2.nTime = 1.96
  L11_2 = {}
  L11_2.nlength = 0.2
  L10_2.tControllerRumble = L11_2
  L11_2 = {}
  L11_2.fSetCameraAmplitude = 2.5
  L11_2.fSetCameraShake = 0.1
  L10_2.tCameraShake = L11_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L6_2.tMultiEvents = L7_2
  L6_2.bDriverDoneRemove = true
  A1_2[3] = L6_2
  L6_2 = MrxActionHijack
  L6_2 = L6_2.Begin
  L7_2 = A1_2
  L8_2 = 1
  L6_2(L7_2, L8_2)
  return A1_2
end

Initialize = L3_1

function L3_1(A0_2, A1_2)
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

OnFailureEvents = L3_1
