local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1
L0_1 = import
L1_1 = "MrxActionHijack"
L0_1(L1_1)
L0_1 = {}
L1_1 = "All_AMX30AA_driverhatch_actionhijack_getin_section01_fb"
L2_1 = "All_AMX30AA_driverhatch_actionhijack_getin_section01failure_fb"
L3_1 = "All_AMX30AA_driverhatch_actionhijack_getin_section02_fb"
L4_1 = nil
L5_1 = nil

function L6_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = "animation"
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
  L2_2 = "Global_weapon_pistol"
  L3_2 = "model"
  L1_2(L2_2, L3_2)
end

Init = L6_1

function L6_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = "animation"
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
  L2_2 = "Global_weapon_pistol"
  L3_2 = "model"
  L1_2(L2_2, L3_2)
end

Deinit = L6_1

function L6_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Action Hijack Prop (Pistol)"
  L6_2 = L6_2(L7_2)
  L4_1 = L6_2
  L5_2 = "bone_pistol"
  L6_2 = Object
  L6_2 = L6_2.Attach
  L7_2 = A3_2
  L8_2 = L5_2
  L9_2 = L4_1
  L6_2, L7_2 = L6_2(L7_2, L8_2, L9_2)
  L5_1 = L7_2
  L4_2 = L6_2
  L6_2 = _THIS
  L7_2 = L6_2
  L6_2 = L6_2.Initialize
  L8_2 = nil
  L9_2 = A0_2
  L10_2 = A1_2
  L11_2 = A2_2
  L12_2 = A3_2
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L6_2 = true
  return L6_2
end

StartHijack = L6_1

function L6_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2
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
  L6_2 = RemoveWeapons
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
  L6_2.hijackerAnimation = "ActionHijackHijackerA"
  L6_2.hijackeeAnimation = "ActionHijackHijackeeA"
  L7_2 = L1_1
  L6_2.vehicleAnimation = L7_2
  L6_2.hijackerAnimationFail = "ActionHijackHijackerFailA"
  L6_2.hijackeeAnimationFail = "ActionHijackHijackeeFailA"
  L7_2 = L2_1
  L6_2.vehicleAnimationFail = L7_2
  L6_2.miniGameStartDelay = 0.53
  L7_2 = {}
  L7_2.nTimeOut = 1
  L7_2.bExtraHudParameters = true
  L7_2.nXPosition = 0.5
  L7_2.nYPosition = 0.2
  L7_2.nTranslucency = 255
  L7_2.bShowTimer = false
  L7_2.sAction = "press"
  L8_2 = Controller
  L8_2 = L8_2.RPad_Right
  L7_2.button = L8_2
  L7_2.nHudButtonMotionSpeed = 0.2
  L6_2.miniGame = L7_2
  L7_2 = {}
  L8_2 = {}
  L8_2.nTime = 0.6
  L9_2 = {}
  L9_2.nlength = 0.2
  L8_2.tControllerRumble = L9_2
  L9_2 = {}
  L9_2.fSetCameraAmplitude = 1
  L9_2.fSetCameraShake = 0.1
  L8_2.tCameraShake = L9_2
  L9_2 = {}
  L9_2.nTime = 1.13
  L10_2 = {}
  L10_2.nlength = 0.2
  L9_2.tControllerRumble = L10_2
  L10_2 = {}
  L10_2.fSetCameraAmplitude = 0.5
  L10_2.fSetCameraShake = 0.1
  L9_2.tCameraShake = L10_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L6_2.tMultiEvents = L7_2
  L7_2 = OnFailureEvents
  L6_2.OnFailureAnimationBegin = L7_2
  L7_2 = {}
  L8_2 = {}
  L8_2.nTime = 0.53
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
  L7_2 = L3_1
  L6_2.vehicleAnimation = L7_2
  L7_2 = {}
  L8_2 = {}
  L8_2.nTime = 1
  L9_2 = {}
  L9_2.nlength = 0.2
  L8_2.tControllerRumble = L9_2
  L9_2 = {}
  L9_2.fSetCameraAmplitude = 2
  L9_2.fSetCameraShake = 0.1
  L8_2.tCameraShake = L9_2
  L7_2[1] = L8_2
  L6_2.tMultiEvents = L7_2
  L6_2.bDriverDoneDead = true
  A1_2[2] = L6_2
  L6_2 = MrxActionHijack
  L6_2 = L6_2.Begin
  L7_2 = A1_2
  L8_2 = 1
  L6_2(L7_2, L8_2)
  return A1_2
end

Initialize = L6_1

function L6_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = Object
  L2_2 = L2_2.Detach
  L3_2 = A0_2._vehicle
  L4_2 = L5_1
  L2_2 = L2_2(L3_2, L4_2)
  L1_2 = L2_2
  L2_2 = Object
  L2_2 = L2_2.Remove
  L3_2 = L5_1
  L2_2 = L2_2(L3_2)
  L1_2 = L2_2
end

RemoveWeapons = L6_1

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
