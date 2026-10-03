local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1
L0_1 = import
L1_1 = "MrxActionHijack"
L0_1(L1_1)
L0_1 = "All_BankTruck_driverdoor_actionhijack_getin_section01_fb"
L1_1 = "All_BankTruck_driverdoor_actionhijack_getin_section01failure_fb"
L2_1 = "All_BankTruck_driverdoor_actionhijack_getin_section02_fb"
L3_1 = "All_BankTruck_driverdoor_actionhijack_getin_section02failure_fb"
L4_1 = "All_BankTruck_driverdoor_actionhijack_getin_section03_fb"

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
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
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
  L9_2.fSetCameraAmplitude = 1
  L9_2.fSetCameraShake = 0.1
  L8_2.tCameraShake = L9_2
  L9_2 = {}
  L9_2.nTime = 3.56
  L10_2 = {}
  L10_2.nlength = 0.2
  L9_2.tControllerRumble = L10_2
  L10_2 = {}
  L10_2.fSetCameraAmplitude = 2.5
  L10_2.fSetCameraShake = 0.2
  L9_2.tCameraShake = L10_2
  L10_2 = {}
  L11_2 = A1_2._hijacker
  L10_2.objectInstanceTemplate = L11_2
  L10_2.objectHardPointBoneName = "Bone_RFootBone1"
  L10_2.sPFXname = "global_particle_shatteringGlass_vehicle"
  L9_2.tParticleEfx = L10_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L6_2.tMultiEvents = L7_2
  L6_2.miniGameStartDelay = 2.8
  L7_2 = {}
  L7_2.nTimeOut = 2
  L7_2.sAction = "press"
  L7_2.bExtraHudParameters = true
  L7_2.nTranslucency = 255
  L7_2.bShowTimer = false
  L7_2.nHudButtonMotionSpeed = 0.2
  L7_2.nXPosition = -0.5
  L7_2.nYPosition = 0.2
  L8_2 = Controller
  L8_2 = L8_2.RPad_Left
  L7_2.button = L8_2
  L6_2.miniGame = L7_2
  L7_2 = OnFailureEvents
  L6_2.OnFailureAnimationBegin = L7_2
  L7_2 = {}
  L8_2 = {}
  L8_2.nTime = 1.1
  L9_2 = {}
  L9_2.nlength = 0.2
  L8_2.tControllerRumble = L9_2
  L9_2 = {}
  L9_2.fSetCameraAmplitude = 2
  L9_2.fSetCameraShake = 0.1
  L8_2.tCameraShake = L9_2
  L9_2 = {}
  L9_2.nTime = 2.2
  L10_2 = {}
  L10_2.nlength = 0.5
  L9_2.tControllerRumble = L10_2
  L10_2 = {}
  L10_2.fSetCameraAmplitude = 2
  L10_2.fSetCameraShake = 0.1
  L9_2.tCameraShake = L10_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L6_2.tFailureMultiEvents = L7_2
  A1_2[1] = L6_2
  L6_2 = {}
  L6_2.hijackerAnimation = "ActionHijackHijackerB"
  L6_2.hijackeeAnimation = "ActionHijackHijackeeB"
  L6_2.hijackerAnimationFail = "ActionHijackHijackerFailB"
  L6_2.hijackeeAnimationFail = "ActionHijackHijackeeFailB"
  L7_2 = L2_1
  L6_2.vehicleAnimation = L7_2
  L7_2 = L3_1
  L6_2.vehicleAnimationFail = L7_2
  L7_2 = {}
  L8_2 = {}
  L8_2.nTime = 0.5
  L9_2 = {}
  L9_2.nlength = 0.2
  L8_2.tControllerRumble = L9_2
  L9_2 = {}
  L9_2.fSetCameraAmplitude = 2
  L9_2.fSetCameraShake = 0.1
  L8_2.tCameraShake = L9_2
  L7_2[1] = L8_2
  L6_2.tMultiEvents = L7_2
  L6_2.miniGameStartDelay = 0.5
  L7_2 = {}
  L7_2.nTimeOut = 0.7
  L7_2.sAction = "press"
  L7_2.bExtraHudParameters = true
  L7_2.nTranslucency = 255
  L7_2.bShowTimer = false
  L7_2.nHudButtonMotionSpeed = 0.2
  L7_2.nYPosition = 0.8
  L7_2.nXPosition = 0
  L8_2 = Controller
  L8_2 = L8_2.RPad_Down
  L7_2.button = L8_2
  L6_2.miniGame = L7_2
  L7_2 = OnFailureEvents
  L6_2.OnFailureAnimationBegin = L7_2
  L7_2 = {}
  L8_2 = {}
  L8_2.nTime = 1.1
  L9_2 = {}
  L9_2.nlength = 0.2
  L8_2.tControllerRumble = L9_2
  L9_2 = {}
  L9_2.fSetCameraAmplitude = 2
  L9_2.fSetCameraShake = 0.1
  L8_2.tCameraShake = L9_2
  L9_2 = {}
  L9_2.nTime = 2.2
  L10_2 = {}
  L10_2.nlength = 0.5
  L9_2.tControllerRumble = L10_2
  L10_2 = {}
  L10_2.fSetCameraAmplitude = 2
  L10_2.fSetCameraShake = 0.1
  L9_2.tCameraShake = L10_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L6_2.tFailureMultiEvents = L7_2
  A1_2[2] = L6_2
  L6_2 = {}
  L6_2.hijackerAnimation = "ActionHijackHijackerC"
  L6_2.hijackeeAnimation = "ActionHijackHijackeeC"
  L7_2 = L4_1
  L6_2.vehicleAnimation = L7_2
  L7_2 = {}
  L8_2 = {}
  L8_2.nTime = 0.76
  L9_2 = {}
  L9_2.nlength = 0.1
  L8_2.tControllerRumble = L9_2
  L9_2 = {}
  L9_2.fSetCameraAmplitude = 2
  L9_2.fSetCameraShake = 0.1
  L8_2.tCameraShake = L9_2
  L9_2 = {}
  L9_2.nTime = 1.43
  L10_2 = {}
  L10_2.nlength = 0.1
  L9_2.tControllerRumble = L10_2
  L10_2 = {}
  L10_2.fSetCameraAmplitude = 2
  L10_2.fSetCameraShake = 0.1
  L9_2.tCameraShake = L10_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
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
