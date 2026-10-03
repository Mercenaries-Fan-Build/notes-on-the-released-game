local L0_1, L1_1, L2_1, L3_1, L4_1
L0_1 = import
L1_1 = "MrxActionHijack"
L0_1(L1_1)
L0_1 = "all_M551_driverhatch_actionhijack_getin_section01_fb"
L1_1 = "all_M551_driverhatch_actionhijack_getin_section02_fb"
L2_1 = "all_M551_driverhatch_actionhijack_getin_section01loopa_fb"
L3_1 = "all_M551_driverhatch_actionhijack_getin_section01loopfailure_fb"

function L4_1()
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
end

Init = L4_1

function L4_1()
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
end

Deinit = L4_1

function L4_1(A0_2, A1_2, A2_2, A3_2)
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

StartHijack = L4_1

function L4_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
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
  L6_2 = OnActionHijackComplete
  A1_2._OnActionHijackComplete = L6_2
  L6_2 = MrxActionHijack
  L6_2 = L6_2.InitializeActionHijack
  L7_2 = A1_2
  L6_2(L7_2)
  L6_2 = MrxActionHijack
  L6_2 = L6_2.TankPrep
  L7_2 = A1_2
  L6_2(L7_2)
  L6_2 = {}
  L7_2 = {}
  L8_2 = {}
  L8_2.state = "angry"
  L8_2.weight = 1
  L7_2.faceStateA = L8_2
  L6_2.hijacker = L7_2
  L7_2 = {}
  L8_2 = {}
  L8_2.state = "Scared"
  L8_2.weight = 1
  L7_2.faceStateA = L8_2
  L6_2.hijackee = L7_2
  FaceState_anim_BLoopA = L6_2
  L6_2 = {}
  L7_2 = {}
  L8_2 = {}
  L8_2.state = "angry"
  L8_2.weight = 0.75
  L7_2.faceStateA = L8_2
  L6_2.hijacker = L7_2
  L7_2 = {}
  L8_2 = {}
  L8_2.state = "Scared"
  L8_2.weight = 0.75
  L7_2.faceStateA = L8_2
  L6_2.hijackee = L7_2
  FaceState_anim_BLoopB = L6_2
  L6_2 = {}
  L7_2 = {}
  L8_2 = {}
  L8_2.state = "Scared"
  L8_2.weight = 0.5
  L7_2.faceStateA = L8_2
  L8_2 = {}
  L8_2.state = "EyesShut"
  L8_2.weight = 1
  L7_2.faceStateB = L8_2
  L8_2 = {}
  L8_2.state = "angry"
  L8_2.weight = 0
  L7_2.faceStateC = L8_2
  L6_2.hijackee = L7_2
  FaceState_anim_BLoopC = L6_2
  L6_2 = {}
  L7_2 = {}
  L8_2 = {}
  L8_2.state = "Scared"
  L8_2.weight = 0.25
  L7_2.faceStateA = L8_2
  L8_2 = {}
  L8_2.state = "EyesShut"
  L8_2.weight = 0
  L7_2.faceStateB = L8_2
  L8_2 = {}
  L8_2.state = "angry"
  L8_2.weight = 0
  L7_2.faceStateC = L8_2
  L6_2.hijackee = L7_2
  FaceState_anim_BLoopD = L6_2
  L6_2 = {}
  L7_2 = {}
  L8_2 = {}
  L8_2.state = "angry"
  L8_2.weight = 0.25
  L7_2.faceStateA = L8_2
  L8_2 = {}
  L8_2.state = "Scared"
  L8_2.weight = 0
  L7_2.faceStateB = L8_2
  L6_2.hijackee = L7_2
  FaceState_anim_BLoopE = L6_2
  L6_2 = {}
  L7_2 = {}
  L8_2 = {}
  L8_2.state = "angry"
  L8_2.weight = 0.5
  L7_2.faceStateA = L8_2
  L6_2.hijackee = L7_2
  FaceState_anim_BLoopF = L6_2
  L6_2 = {}
  L7_2 = {}
  L8_2 = {}
  L8_2.state = "angry"
  L8_2.weight = 0.75
  L7_2.faceStateA = L8_2
  L6_2.hijackee = L7_2
  FaceState_anim_BLoopG = L6_2
  L6_2 = {}
  L7_2 = {}
  L8_2 = {}
  L8_2.state = "angry"
  L8_2.weight = 1
  L7_2.faceStateA = L8_2
  L6_2.hijackee = L7_2
  FaceState_anim_BLoopH = L6_2
  L6_2 = {}
  L6_2.hijackerAnimation = "ActionHijackHijackerA"
  L6_2.hijackeeAnimation = "ActionHijackHijackeeA"
  L6_2.hijackerAnimationFail = "ActionHijackHijackerFailA"
  L6_2.hijackeeAnimationFail = "ActionHijackHijackeeFailA"
  L7_2 = L0_1
  L6_2.vehicleAnimation = L7_2
  L7_2 = door_anim_AFail
  L6_2.vehicleAnimationFail = L7_2
  L7_2 = {}
  L8_2 = {}
  L9_2 = {}
  L9_2.state = "angry"
  L9_2.weight = 0.5
  L8_2.faceStateA = L9_2
  L7_2.hijacker = L8_2
  L6_2.tCharactersFaceStates = L7_2
  L6_2.miniGameStartDelay = 1
  L7_2 = {}
  L7_2.nTimeOut = 1
  L7_2.bExtraHudParameters = true
  L7_2.nTranslucency = 255
  L7_2.nXPosition = -0.5
  L7_2.nYPosition = 0.2
  L7_2.nScale = 1.2
  L7_2.bShowTimer = false
  L7_2.sAction = "press"
  L8_2 = Controller
  L8_2 = L8_2.LStick_Left
  L7_2.button = L8_2
  L7_2.nHudButtonMotionSpeed = 0.25
  L6_2.miniGame = L7_2
  L7_2 = OnFailureEvents
  L6_2.OnFailureAnimationBegin = L7_2
  L7_2 = {}
  L8_2 = {}
  L8_2.nTime = 0.6
  L9_2 = {}
  L9_2.nlength = 0.5
  L8_2.tControllerRumble = L9_2
  L9_2 = {}
  L9_2.fSetCameraAmplitude = 1
  L9_2.fSetCameraShake = 0.1
  L8_2.tCameraShake = L9_2
  L7_2[1] = L8_2
  L6_2.tFailureMultiEvents = L7_2
  A1_2[1] = L6_2
  L6_2 = {}
  L6_2.hijackerAnimationFail = "ActionHijackHijackerFailA"
  L6_2.hijackeeAnimationFail = "ActionHijackHijackeeFailA"
  L7_2 = L3_1
  L6_2.vehicleAnimationFail = L7_2
  L6_2.nReactiveLoop = 3
  L7_2 = {}
  L8_2 = "ActionHijackHijackerDLoopH"
  L9_2 = "ActionHijackHijackerDLoopG"
  L10_2 = "ActionHijackHijackerDLoopF"
  L11_2 = "ActionHijackHijackerDLoopE"
  L12_2 = "ActionHijackHijackerDLoopD"
  L13_2 = "ActionHijackHijackerDLoopC"
  L14_2 = "ActionHijackHijackerDLoopB"
  L15_2 = "ActionHijackHijackerDLoopA"
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
  L8_2 = "ActionHijackHijackeeBLoopH"
  L9_2 = "ActionHijackHijackeeBLoopG"
  L10_2 = "ActionHijackHijackeeBLoopF"
  L11_2 = "ActionHijackHijackeeBLoopE"
  L12_2 = "ActionHijackHijackeeBLoopD"
  L13_2 = "ActionHijackHijackeeBLoopC"
  L14_2 = "ActionHijackHijackeeBLoopB"
  L15_2 = "ActionHijackHijackeeBLoopA"
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
  L8_2 = L2_1
  L9_2 = L2_1
  L10_2 = L2_1
  L11_2 = L2_1
  L12_2 = L2_1
  L13_2 = L2_1
  L14_2 = L2_1
  L15_2 = L2_1
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L7_2[5] = L12_2
  L7_2[6] = L13_2
  L7_2[7] = L14_2
  L7_2[8] = L15_2
  L6_2.tVehicleAnimations = L7_2
  L7_2 = {}
  L8_2 = FaceState_anim_BLoopH
  L9_2 = FaceState_anim_BLoopG
  L10_2 = FaceState_anim_BLoopF
  L11_2 = FaceState_anim_BLoopE
  L12_2 = FaceState_anim_BLoopD
  L13_2 = FaceState_anim_BLoopC
  L14_2 = FaceState_anim_BLoopB
  L15_2 = FaceState_anim_BLoopA
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L7_2[5] = L12_2
  L7_2[6] = L13_2
  L7_2[7] = L14_2
  L7_2[8] = L15_2
  L6_2.tReactiveLoopFaceStates = L7_2
  L6_2.miniGameStartDelay = 0.1
  L7_2 = {}
  L7_2.nTimeOut = 35
  L7_2.bExtraHudParameters = true
  L7_2.nTranslucency = 255
  L7_2.nXPosition = 0
  L7_2.nYPosition = -0.45
  L7_2.bShowTimer = false
  L7_2.sAction = "tap"
  L8_2 = Controller
  L8_2 = L8_2.RPad_Up
  L7_2.button = L8_2
  L7_2.nDriverDifficulty = 1.2
  L7_2.nSuccessThreshold = 1
  L6_2.miniGame = L7_2
  L7_2 = OnFailureEvents
  L6_2.OnFailureAnimationBegin = L7_2
  L7_2 = {}
  L8_2 = {}
  L8_2.nTime = 0.6
  L9_2 = {}
  L9_2.nlength = 0.5
  L8_2.tControllerRumble = L9_2
  L9_2 = {}
  L9_2.fSetCameraAmplitude = 1
  L9_2.fSetCameraShake = 0.1
  L8_2.tCameraShake = L9_2
  L7_2[1] = L8_2
  L6_2.tFailureMultiEvents = L7_2
  A1_2[2] = L6_2
  L6_2 = {}
  L6_2.hijackerAnimation = "ActionHijackHijackerB"
  L6_2.hijackeeAnimation = "ActionHijackHijackeeB"
  L7_2 = L1_1
  L6_2.vehicleAnimation = L7_2
  L7_2 = {}
  L8_2 = {}
  L8_2.nTime = 0.56
  L9_2 = {}
  L9_2.nlength = 0.2
  L8_2.tControllerRumble = L9_2
  L9_2 = {}
  L9_2.fSetCameraAmplitude = 1
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
  L10_2.nTime = 2.2
  L11_2 = {}
  L11_2.nlength = 0.5
  L10_2.tControllerRumble = L11_2
  L11_2 = {}
  L11_2.fSetCameraAmplitude = 2.5
  L11_2.fSetCameraShake = 0.1
  L10_2.tCameraShake = L11_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L6_2.tMultiEvents = L7_2
  L6_2.bDriverDoneDead = true
  A1_2[3] = L6_2
  L6_2 = MrxActionHijack
  L6_2 = L6_2.Begin
  L7_2 = A1_2
  L8_2 = 1
  L6_2(L7_2, L8_2)
  return A1_2
end

Initialize = L4_1

function L4_1(A0_2, A1_2)
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

OnFailureEvents = L4_1
