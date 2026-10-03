local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiHudActionHijack"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSound"
L0_1(L1_1)
L0_1 = import
L1_1 = "Hero"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxAchievements"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxMusic"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifFreePlay"
L0_1(L1_1)
L0_1 = 0.2
L1_1 = nil
L2_1 = {}
L3_1 = {}
L4_1 = 1
L5_1 = 1.2
L6_1 = 1.4
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L2_1.EASYTAP = L3_1
L3_1 = {}
L4_1 = 0.8
L5_1 = 1
L6_1 = 1.2
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L2_1.MEDTAP = L3_1
L3_1 = {}
L4_1 = 0.6
L5_1 = 0.8
L6_1 = 1
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L2_1.HARDTAP = L3_1
L3_1 = {}
L4_1 = 1
L5_1 = 1.2
L6_1 = 1.4
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L2_1.EASYMASH = L3_1
L3_1 = {}
L4_1 = 1
L5_1 = 1.2
L6_1 = 1.4
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L2_1.MEDMASH = L3_1
L3_1 = {}
L4_1 = 1
L5_1 = 1.2
L6_1 = 1.4
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L2_1.HARDMASH = L3_1
L3_1 = {}
L3_1.nDURATION = 1
L4_1 = Controller
L4_1 = L4_1.RPad_Down
L3_1.GRAPHIC = L4_1
L4_1 = Controller
L4_1 = L4_1.RPad_Down
L3_1.INPUT = L4_1
L3_1.nTimeReduction = 1
L3_1.nTimeReduction2 = 1.5
L3_1.nKnockdown2 = 0.5
L3_1.nKnockdown3 = 0.5
L4_1 = false
_bIsInHijack = L4_1
L4_1 = nil
_fUnloadCallback = L4_1
L4_1 = nil
_tUnloadCallbackArgs = L4_1

function L4_1()
  local L0_2, L1_2
  L0_2 = _bIsInHijack
  return L0_2
end

IsInHijack = L4_1

function L4_1(A0_2, A1_2)
  _fUnloadCallback = A0_2
  _tUnloadCallbackArgs = A1_2
end

SetUnloadCallback = L4_1
L4_1 = 0
RULESET_TANK = L4_1
L4_1 = 1
RULESET_HELICOPTER = L4_1
L4_1 = 2
RULESET_APC = L4_1
L4_1 = nil
RULESET_SOLANO = L4_1

function L4_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = RULESET_HELICOPTER
  if A1_2 == L2_2 then
    L2_2 = Vehicle
    L2_2 = L2_2.IsFlying
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = true
      return L2_2
    end
  end
  L2_2 = false
  return L2_2
end

CheckGoodStart = L4_1

function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = {}
  A0_2.tAnimation = L1_2
  L1_2 = {}
  A0_2.tEvent = L1_2
  L1_2 = MrxGuiManager
  L1_2 = L1_2.ToggleHud
  L2_2 = A0_2._hijackerPlayer
  L3_2 = false
  L4_2 = "hijack"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Vehicle
  L1_2 = L1_2.EnableTurret
  L2_2 = A0_2._hijackee
  L3_2 = "head"
  L4_2 = false
  L5_2 = "all"
  L6_2 = false
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = A0_2._hijackerPlayer
  L2_2 = Player
  L2_2 = L2_2.GetLocalPlayer
  L2_2 = L2_2()
  if L1_2 == L2_2 then
    L1_2 = MrxSound
    L1_2 = L1_2.BeginActionHijack
    L2_2 = RULESET_SOLANO
    L2_2 = not L2_2
    L1_2(L2_2)
  end
  L1_2 = Object
  L1_2 = L1_2.SetInvincible
  L2_2 = A0_2._hijackee
  L3_2 = true
  L4_2 = "Hijack"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Object
  L1_2 = L1_2.SetInvincible
  L2_2 = A0_2._hijacker
  L3_2 = true
  L4_2 = "Hijack"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Object
  L1_2 = L1_2.SetInvincible
  L2_2 = A0_2._vehicle
  L3_2 = true
  L4_2 = "Hijack"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2 = L1_2()
  L2_2 = A0_2._hijacker
  if L1_2 == L2_2 then
    L1_2 = true
    bNeedAtmosphereChange = L1_2
    L1_2 = ChangeAtmosphere
    L2_2 = true
    L1_2(L2_2)
    L1_2 = Graphics
    L1_2 = L1_2.Camera
    L1_2 = L1_2.SetFocusParams
    L2_2 = 0
    L3_2 = 0
    L4_2 = 0.1
    L5_2 = 4
    L6_2 = 6
    L7_2 = 1
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
    L1_2 = Graphics
    L1_2 = L1_2.Effect
    L1_2 = L1_2.CameraFade
    L2_2 = 0
    L1_2(L2_2)
  end
  L1_2 = Vehicle
  L1_2 = L1_2.IsHijackRemote
  if L1_2 then
    L1_2 = Vehicle
    L1_2 = L1_2.IsHijackRemote
    L2_2 = A0_2._hijacker
    L1_2 = L1_2(L2_2)
  end
  A0_2._bRemote = L1_2
  L1_2 = A0_2.tFaceAnimSets
  if L1_2 then
    L1_2 = pairs
    L2_2 = A0_2.tFaceAnimSets
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    for L4_2, L5_2 in L1_2, L2_2, L3_2 do
      L6_2 = A0_2.tFaceAnimSets
      L6_2 = L6_2[L4_2]
      L6_2 = L6_2.ActorAnim
      if L6_2 then
        L7_2 = A0_2.tFaceAnimSets
        L7_2 = L7_2[L4_2]
        L7_2 = L7_2.ActorGuid
        L8_2 = Animation
        L8_2 = L8_2.BindFaceAnimSet
        L9_2 = L7_2
        L10_2 = L6_2
        L8_2 = L8_2(L9_2, L10_2)
        L9_2 = VO
        L9_2 = L9_2.SetCinematicMode
        L10_2 = true
        L9_2(L10_2)
        A0_2._bUsingCinematicMode = true
      end
    end
  end
  L1_2 = Vehicle
  L1_2 = L1_2.HijackStart
  if L1_2 then
    L1_2 = Vehicle
    L1_2 = L1_2.HijackStart
    L2_2 = A0_2._hijacker
    L3_2 = A0_2._hijackee
    L4_2 = A0_2._vehicle
    L5_2 = A0_2
    L1_2(L2_2, L3_2, L4_2, L5_2)
  end
  A0_2.bDidSuccess = false
  A0_2.bDidFailure = false
  L1_2 = true
  _bIsInHijack = L1_2
  L1_2 = WifFreePlay
  L1_2 = L1_2.StopNag
  L1_2()
end

InitializeActionHijack = L4_1

function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  A0_2._bTankCleanup = true
  L1_2 = Ai
  L1_2 = L1_2.Enable
  L2_2 = A0_2._hijackee
  L3_2 = false
  L1_2(L2_2, L3_2)
  L1_2 = Vehicle
  L1_2 = L1_2.ClearControls
  L2_2 = A0_2._vehicle
  L1_2(L2_2)
  L1_2 = Object
  L1_2 = L1_2.DisablePhysics
  L2_2 = A0_2._hijacker
  L1_2(L2_2)
  L1_2 = Vehicle
  L1_2 = L1_2.EnableTurret
  L2_2 = A0_2._vehicle
  L3_2 = "main_turret"
  L4_2 = false
  L5_2 = "pitch"
  L6_2 = false
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Vehicle
  L1_2 = L1_2.SetTurretPitch
  L2_2 = A0_2._vehicle
  L3_2 = "main_turret"
  L4_2 = 0
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Object
  L1_2 = L1_2.SetVisible
  L2_2 = A0_2._hijackee
  L3_2 = true
  L1_2(L2_2, L3_2)
end

TankPrep = L4_1

function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = Event
  L2_2 = L2_2.Post
  L3_2 = "ActionHijackStart"
  L4_2 = {}
  L5_2 = A0_2
  L4_2[1] = L5_2
  L2_2(L3_2, L4_2)
  A0_2.nCurrent = A1_2
  L2_2 = Vehicle
  L2_2 = L2_2.SetHijackState
  if L2_2 then
    L2_2 = A0_2._bRemote
    if not L2_2 then
      L2_2 = Vehicle
      L2_2 = L2_2.SetHijackState
      L3_2 = A0_2._hijacker
      L4_2 = A1_2
      L2_2(L3_2, L4_2)
    end
  end
  L2_2 = A0_2.nCurrent
  L2_2 = A0_2[L2_2]
  L2_2 = L2_2.nReactiveLoop
  if L2_2 ~= nil then
    L2_2 = PlayReactiveLoop
    L3_2 = A0_2
    L4_2 = A0_2.nCurrent
    L4_2 = A0_2[L4_2]
    L2_2(L3_2, L4_2)
  else
    L2_2 = Play
    L3_2 = A0_2
    L4_2 = A0_2.nCurrent
    L4_2 = A0_2[L4_2]
    L4_2 = L4_2.hijackerAnimation
    L5_2 = A0_2.nCurrent
    L5_2 = A0_2[L5_2]
    L5_2 = L5_2.hijackeeAnimation
    L6_2 = A0_2.nCurrent
    L6_2 = A0_2[L6_2]
    L6_2 = L6_2.vehicleAnimation
    L7_2 = A0_2.nCurrent
    L7_2 = A0_2[L7_2]
    L7_2 = L7_2.ExtraActors
    L8_2 = A0_2.nCurrent
    L8_2 = A0_2[L8_2]
    L8_2 = L8_2.tFaceAnimations
    L9_2 = A0_2.nCurrent
    L9_2 = A0_2[L9_2]
    L9_2 = L9_2.tCharactersFaceStates
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
    L2_2 = A0_2.nCurrent
    L2_2 = A0_2[L2_2]
    L2_2 = L2_2.nTankHijackExplosion
    if L2_2 then
      L2_2 = Event
      L2_2 = L2_2.Delete
      L3_2 = A0_2.tEvent
      L3_2 = L3_2._explosionTimer
      L2_2(L3_2)
      L2_2 = A0_2.tEvent
      L3_2 = Event
      L3_2 = L3_2.Create
      L4_2 = Event
      L4_2 = L4_2.TimerRelative
      L5_2 = {}
      L6_2 = A0_2.nCurrent
      L6_2 = A0_2[L6_2]
      L6_2 = L6_2.nTankHijackExplosion
      L6_2 = L6_2.nDelay
      L7_2 = false
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      
      function L6_2(A0_3)
        local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3
        L1_3 = Object
        L1_3 = L1_3.GetHardpointPosition
        L2_3 = A0_3._vehicle
        L3_3 = "hp_seat_lt"
        L1_3, L2_3, L3_3 = L1_3(L2_3, L3_3)
        L4_3 = A0_3.nCurrent
        L4_3 = A0_3[L4_3]
        L4_3 = L4_3.nTankHijackExplosion
        L4_3 = L4_3.fSetCameraShake
        if L4_3 ~= nil then
          L4_3 = Player
          L4_3 = L4_3.GetLocalCharacter
          L4_3 = L4_3()
          L5_3 = A0_3._hijacker
          if L4_3 == L5_3 then
            L4_3 = A0_3.nCurrent
            L4_3 = A0_3[L4_3]
            L4_3 = L4_3.nTankHijackExplosion
            L4_3 = L4_3.fSetCameraShake
            L5_3 = A0_3.nCurrent
            L5_3 = A0_3[L5_3]
            L5_3 = L5_3.nTankHijackExplosion
            L5_3 = L5_3.fSetCameraAmplitude
            L6_3 = Player
            L6_3 = L6_3.GetLocalPlayer
            L6_3 = L6_3()
            player = L6_3
            L6_3 = Player
            L6_3 = L6_3.GetCamera
            L7_3 = player
            L6_3 = L6_3(L7_3)
            playerCamera = L6_3
            L6_3 = Player
            L6_3 = L6_3.GetCharacter
            L7_3 = player
            L6_3 = L6_3(L7_3)
            playerCharacter = L6_3
            L6_3 = Camera
            L6_3 = L6_3.Shake
            L7_3 = playerCamera
            L8_3 = "ShakeCameraMedium"
            L9_3 = playerCharacter
            L10_3 = L5_3
            L11_3 = L4_3
            L6_3(L7_3, L8_3, L9_3, L10_3, L11_3)
          end
        end
        L4_3 = A0_3.nCurrent
        L4_3 = A0_3[L4_3]
        L4_3 = L4_3.nTankHijackExplosion
        L4_3 = L4_3.fSetRumbleLength
        if L4_3 ~= nil then
          L4_3 = A0_3.nCurrent
          L4_3 = A0_3[L4_3]
          L4_3 = L4_3.nTankHijackExplosion
          L4_3 = L4_3.fSetRumbleLength
          L5_3 = Pg
          L5_3 = L5_3.Rumble
          L6_3 = A0_3._hijacker
          L7_3 = L4_3
          L5_3(L6_3, L7_3)
        end
        if L1_3 and L2_3 and L3_3 then
          L4_3 = Pg
          L4_3 = L4_3.Spawn
          L5_3 = "global_particle_explosion_tankhatch"
          L6_3 = L1_3
          L7_3 = L2_3
          L8_3 = L3_3
          L9_3 = 0
          L4_3(L5_3, L6_3, L7_3, L8_3, L9_3)
        end
      end
      
      L7_2 = {}
      L8_2 = A0_2
      L7_2[1] = L8_2
      L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
      L2_2._explosionTimer = L3_2
    end
    L2_2 = A0_2.nCurrent
    L2_2 = A0_2[L2_2]
    L2_2 = L2_2.tMultiEvents
    if L2_2 ~= nil then
      L2_2 = A0_2.nCurrent
      L2_2 = A0_2[L2_2]
      L2_2 = L2_2.tMultiEvents
      L3_2 = A0_2._hijacker
      L4_2 = _ProcessMultiEventTable
      L5_2 = L3_2
      L6_2 = L2_2
      L4_2(L5_2, L6_2)
    end
    L2_2 = A0_2.nCurrent
    L2_2 = A0_2[L2_2]
    L2_2 = L2_2.nMultiEvent
    if L2_2 then
      L2_2 = Event
      L2_2 = L2_2.Create
      L3_2 = Event
      L3_2 = L3_2.TimerRelative
      L4_2 = {}
      L5_2 = A0_2.nCurrent
      L5_2 = A0_2[L5_2]
      L5_2 = L5_2.nChopperKill
      L5_2 = L5_2.nDelay
      L6_2 = false
      L4_2[1] = L5_2
      L4_2[2] = L6_2
      
      function L5_2(A0_3)
        local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
        L1_3 = Pg
        L1_3 = L1_3.GetGuidByName
        L2_3 = A0_3.nCurrent
        L2_3 = A0_3[L2_3]
        L2_3 = L2_3.nChopperKill
        L2_3 = L2_3.nLocation
        L1_3 = L1_3(L2_3)
        L2_3 = Object
        L2_3 = L2_3.GetPosition
        L3_3 = L1_3
        L2_3, L3_3, L4_3 = L2_3(L3_3)
        z = L4_3
        y = L3_3
        x = L2_3
        L2_3 = Pg
        L2_3 = L2_3.Spawn
        L3_3 = A0_3.nCurrent
        L3_3 = A0_3[L3_3]
        L3_3 = L3_3.nChopperKill
        L3_3 = L3_3.dVehicle
        L4_3 = x
        L5_3 = y
        L6_3 = z
        L2_3 = L2_3(L3_3, L4_3, L5_3, L6_3)
        L3_3 = Object
        L3_3 = L3_3.Kill
        L4_3 = L2_3
        L3_3(L4_3)
      end
      
      L6_2 = {}
      L7_2 = A0_2
      L6_2[1] = L7_2
      L2_2(L3_2, L4_2, L5_2, L6_2)
    end
    L2_2 = A0_2.nCurrent
    L2_2 = A0_2[L2_2]
    L2_2 = L2_2.nControllerRumble
    if L2_2 then
      L2_2 = Event
      L2_2 = L2_2.Delete
      L3_2 = A0_2.tEvent
      L3_2 = L3_2._rumbleTimer
      L2_2(L3_2)
      L2_2 = A0_2.tEvent
      L3_2 = Event
      L3_2 = L3_2.Create
      L4_2 = Event
      L4_2 = L4_2.TimerRelative
      L5_2 = {}
      L6_2 = A0_2.nCurrent
      L6_2 = A0_2[L6_2]
      L6_2 = L6_2.nControllerRumble
      L6_2 = L6_2.nDelay
      L7_2 = false
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      
      function L6_2(A0_3)
        local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3
        L1_3 = Player
        L1_3 = L1_3.GetLocalCharacter
        L1_3 = L1_3()
        L2_3 = A0_3._hijacker
        if L1_3 == L2_3 then
          L1_3 = A0_3.nCurrent
          L1_3 = A0_3[L1_3]
          L1_3 = L1_3.nControllerRumble
          L1_3 = L1_3.fSetRumbleLength
          L2_3 = Pg
          L2_3 = L2_3.Rumble
          L3_3 = A0_3._hijacker
          L4_3 = L1_3
          L2_3(L3_3, L4_3)
        end
        L1_3 = A0_3.nCurrent
        L1_3 = A0_3[L1_3]
        L1_3 = L1_3.nControllerRumble
        L1_3 = L1_3.bPEvent
        if L1_3 ~= nil then
          L1_3 = A0_3.nCurrent
          L1_3 = A0_3[L1_3]
          L1_3 = L1_3.nControllerRumble
          L1_3 = L1_3.objectInstanceTemplate
          L2_3 = A0_3.nCurrent
          L2_3 = A0_3[L2_3]
          L2_3 = L2_3.nControllerRumble
          L2_3 = L2_3.objectHardPointBoneName
          L3_3 = A0_3.nCurrent
          L3_3 = A0_3[L3_3]
          L3_3 = L3_3.nControllerRumble
          L3_3 = L3_3.sPFXname
          L4_3 = Object
          L4_3 = L4_3.GetHardpointPosition
          L5_3 = L1_3
          L6_3 = L2_3
          L4_3, L5_3, L6_3 = L4_3(L5_3, L6_3)
          if L4_3 and L5_3 and L6_3 then
            L7_3 = Pg
            L7_3 = L7_3.Spawn
            L8_3 = L3_3
            L9_3 = L4_3
            L10_3 = L5_3
            L11_3 = L6_3
            L12_3 = 0
            L7_3 = L7_3(L8_3, L9_3, L10_3, L11_3, L12_3)
            L8_3 = Object
            L8_3 = L8_3.SetTransformToObject
            L9_3 = L7_3
            L10_3 = L1_3
            L11_3 = L2_3
            L8_3(L9_3, L10_3, L11_3)
          end
        end
      end
      
      L7_2 = {}
      L8_2 = A0_2
      L7_2[1] = L8_2
      L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
      L2_2._rumbleTimer = L3_2
    end
    L2_2 = A0_2.nCurrent
    L2_2 = A0_2[L2_2]
    L2_2 = L2_2.nCameraParams
    if L2_2 then
      L2_2 = A0_2.nCurrent
      L2_2 = A0_2[L2_2]
      L2_2 = L2_2.nCameraParams
      L2_2 = L2_2.nDelay
      if not L2_2 then
        L2_2 = 0
      end
      L3_2 = Event
      L3_2 = L3_2.Delete
      L4_2 = A0_2.tEvent
      L4_2 = L4_2._cameraParamsTimer
      L3_2(L4_2)
      L3_2 = A0_2.tEvent
      L4_2 = Event
      L4_2 = L4_2.Create
      L5_2 = Event
      L5_2 = L5_2.TimerRelative
      L6_2 = {}
      L7_2 = L2_2
      L8_2 = false
      L6_2[1] = L7_2
      L6_2[2] = L8_2
      
      function L7_2(A0_3)
        local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3
        L1_3 = A0_3.nCurrent
        L1_3 = A0_3[L1_3]
        L1_3 = L1_3.nCameraParams
        L1_3 = L1_3.nPlayerCam
        if not L1_3 then
          L1_3 = 0
        end
        L2_3 = A0_3.nCurrent
        L2_3 = A0_3[L2_3]
        L2_3 = L2_3.nCameraParams
        L2_3 = L2_3.nStartNear
        if not L2_3 then
          L2_3 = 0
        end
        L3_3 = A0_3.nCurrent
        L3_3 = A0_3[L3_3]
        L3_3 = L3_3.nCameraParams
        L3_3 = L3_3.nEndNear
        if not L3_3 then
          L3_3 = 0.1
        end
        L4_3 = A0_3.nCurrent
        L4_3 = A0_3[L4_3]
        L4_3 = L4_3.nCameraParams
        L4_3 = L4_3.nStartFar
        if not L4_3 then
          L4_3 = 4
        end
        L5_3 = A0_3.nCurrent
        L5_3 = A0_3[L5_3]
        L5_3 = L5_3.nCameraParams
        L5_3 = L5_3.nEndFar
        if not L5_3 then
          L5_3 = 6
        end
        L6_3 = A0_3.nCurrent
        L6_3 = A0_3[L6_3]
        L6_3 = L6_3.nCameraParams
        L6_3 = L6_3.nBlur
        if not L6_3 then
          L6_3 = 0.2
        end
        L7_3 = A0_3.nCurrent
        L7_3 = A0_3[L7_3]
        L7_3 = L7_3.nCameraParams
        L7_3 = L7_3.nDuration
        if not L7_3 then
          L7_3 = 0
        end
        L8_3 = Player
        L8_3 = L8_3.GetLocalCharacter
        L8_3 = L8_3()
        L9_3 = A0_3._hijacker
        if L8_3 == L9_3 then
          L8_3 = Graphics
          L8_3 = L8_3.Camera
          L8_3 = L8_3.SetFocusParams
          L9_3 = L1_3
          L10_3 = L2_3
          L11_3 = L3_3
          L12_3 = L4_3
          L13_3 = L5_3
          L14_3 = L6_3
          L15_3 = L7_3
          L8_3(L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3)
        end
      end
      
      L8_2 = {}
      L9_2 = A0_2
      L8_2[1] = L9_2
      L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
      L3_2._cameraParamsTimer = L4_2
    end
    L2_2 = A0_2.nCurrent
    L2_2 = A0_2[L2_2]
    L2_2 = L2_2.nAnimCameraShake
    if L2_2 then
    end
    L2_2 = A0_2.nCurrent
    L2_2 = A0_2[L2_2]
    L2_2 = L2_2.nChopperKill
    if L2_2 then
      L2_2 = Event
      L2_2 = L2_2.Create
      L3_2 = Event
      L3_2 = L3_2.TimerRelative
      L4_2 = {}
      L5_2 = A0_2.nCurrent
      L5_2 = A0_2[L5_2]
      L5_2 = L5_2.nChopperKill
      L5_2 = L5_2.nDelay
      L6_2 = false
      L4_2[1] = L5_2
      L4_2[2] = L6_2
      
      function L5_2(A0_3)
        local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
        L1_3 = Pg
        L1_3 = L1_3.GetGuidByName
        L2_3 = A0_3.nCurrent
        L2_3 = A0_3[L2_3]
        L2_3 = L2_3.nChopperKill
        L2_3 = L2_3.nLocation
        L1_3 = L1_3(L2_3)
        L2_3 = Object
        L2_3 = L2_3.GetPosition
        L3_3 = L1_3
        L2_3, L3_3, L4_3 = L2_3(L3_3)
        z = L4_3
        y = L3_3
        x = L2_3
        L2_3 = Pg
        L2_3 = L2_3.Spawn
        L3_3 = A0_3.nCurrent
        L3_3 = A0_3[L3_3]
        L3_3 = L3_3.nChopperKill
        L3_3 = L3_3.dVehicle
        L4_3 = x
        L5_3 = y
        L6_3 = z
        L2_3 = L2_3(L3_3, L4_3, L5_3, L6_3)
        L3_3 = Object
        L3_3 = L3_3.Kill
        L4_3 = L2_3
        L3_3(L4_3)
      end
      
      L6_2 = {}
      L7_2 = A0_2
      L6_2[1] = L7_2
      L2_2(L3_2, L4_2, L5_2, L6_2)
    end
    L2_2 = A0_2._bRemote
    if L2_2 then
      L2_2 = A0_2.nCurrent
      L2_2 = A0_2[L2_2]
      L3_2 = OnAnimationCompleteRemote
      L2_2.OnAnimationComplete = L3_2
    else
      L2_2 = A0_2.nCurrent
      L2_2 = A0_2[L2_2]
      L3_2 = OnAnimationComplete
      L2_2.OnAnimationComplete = L3_2
    end
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = A0_2.tEvent
    L3_2 = L3_2.eHumanActionComplete_Hijacker
    L2_2(L3_2)
    L2_2 = A0_2.tEvent
    L3_2 = Event
    L3_2 = L3_2.Create
    L4_2 = Event
    L4_2 = L4_2.HumanActionComplete
    L5_2 = {}
    L6_2 = A0_2._hijacker
    L5_2[1] = L6_2
    L6_2 = A0_2.nCurrent
    L6_2 = A0_2[L6_2]
    L6_2 = L6_2.OnAnimationComplete
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
    L2_2.eHumanActionComplete_Hijacker = L3_2
    L2_2 = A0_2.nCurrent
    L2_2 = A0_2[L2_2]
    L2_2 = L2_2.bDriverDone
    if L2_2 ~= true then
      L2_2 = A0_2.nCurrent
      L2_2 = A0_2[L2_2]
      L2_2 = L2_2.bDriverDoneRagdoll
      if L2_2 ~= true then
        L2_2 = A0_2.nCurrent
        L2_2 = A0_2[L2_2]
        L2_2 = L2_2.bDriverDoneDead
        if L2_2 ~= true then
          L2_2 = A0_2.nCurrent
          L2_2 = A0_2[L2_2]
          L2_2 = L2_2.bDriverDoneRemove
          if L2_2 ~= true then
            L2_2 = A0_2.nCurrent
            L2_2 = A0_2[L2_2]
            L2_2 = L2_2.bDriverDoneStanding
            if L2_2 ~= true then
              goto lbl_296
            end
          end
        end
      end
    end
    L2_2 = Human
    L2_2 = L2_2.SetPreemptiveRagdoll
    if L2_2 ~= nil then
      L2_2 = A0_2.nCurrent
      L2_2 = A0_2[L2_2]
      L2_2 = L2_2.bDriverDoneRagdoll
      if not L2_2 then
        L2_2 = A0_2.nCurrent
        L2_2 = A0_2[L2_2]
        L2_2 = L2_2.bDriverDoneDead
        if not L2_2 then
          goto lbl_277
        end
      end
      L2_2 = Human
      L2_2 = L2_2.SetPreemptiveRagdoll
      L3_2 = A0_2._hijackee
      L2_2(L3_2)
    end
    ::lbl_277::
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = A0_2.tEvent
    L3_2 = L3_2.eHumanActionComplete_Driver
    L2_2(L3_2)
    L2_2 = A0_2.tEvent
    L3_2 = Event
    L3_2 = L3_2.Create
    L4_2 = Event
    L4_2 = L4_2.HumanActionComplete
    L5_2 = {}
    L6_2 = A0_2._hijackee
    L5_2[1] = L6_2
    L6_2 = OnDriverDone
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
    L2_2.eHumanActionComplete_Driver = L3_2
    ::lbl_296::
    L2_2 = A0_2._ActorOne
    if L2_2 then
      L2_2 = A0_2.nCurrent
      L2_2 = A0_2[L2_2]
      L2_2 = L2_2.bActorOneDoneDead
      if L2_2 == true then
        L2_2 = Human
        L2_2 = L2_2.SetPreemptiveRagdoll
        if L2_2 ~= nil then
          L2_2 = A0_2.nCurrent
          L2_2 = A0_2[L2_2]
          L2_2 = L2_2.bDriverDoneRagdoll
          if not L2_2 then
            L2_2 = A0_2.nCurrent
            L2_2 = A0_2[L2_2]
            L2_2 = L2_2.bActorOneDoneDead
            if not L2_2 then
              goto lbl_322
            end
          end
          L2_2 = Human
          L2_2 = L2_2.SetPreemptiveRagdoll
          L3_2 = A0_2._ActorOne
          L2_2(L3_2)
        end
        ::lbl_322::
        L2_2 = Event
        L2_2 = L2_2.Delete
        L3_2 = A0_2.tEvent
        L3_2 = L3_2.eHumanActionComplete_ActorOne
        L2_2(L3_2)
        L2_2 = A0_2.tEvent
        L3_2 = Event
        L3_2 = L3_2.Create
        L4_2 = Event
        L4_2 = L4_2.HumanActionComplete
        L5_2 = {}
        L6_2 = A0_2._ActorOne
        L5_2[1] = L6_2
        L6_2 = OnDriverDone
        L7_2 = {}
        L8_2 = A0_2
        L7_2[1] = L8_2
        L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
        L2_2.eHumanActionComplete_ActorOne = L3_2
      end
    end
    L2_2 = A0_2._ActorTwo
    if L2_2 then
      L2_2 = A0_2.nCurrent
      L2_2 = A0_2[L2_2]
      L2_2 = L2_2.bActorTwoDoneDead
      if L2_2 == true then
        L2_2 = Human
        L2_2 = L2_2.SetPreemptiveRagdoll
        if L2_2 ~= nil then
          L2_2 = A0_2.nCurrent
          L2_2 = A0_2[L2_2]
          L2_2 = L2_2.bDriverDoneRagdoll
          if not L2_2 then
            L2_2 = A0_2.nCurrent
            L2_2 = A0_2[L2_2]
            L2_2 = L2_2.bActorTwoDoneDead
            if not L2_2 then
              goto lbl_367
            end
          end
          L2_2 = Human
          L2_2 = L2_2.SetPreemptiveRagdoll
          L3_2 = A0_2._ActorTwo
          L2_2(L3_2)
        end
        ::lbl_367::
        L2_2 = Event
        L2_2 = L2_2.Delete
        L3_2 = A0_2.tEvent
        L3_2 = L3_2.eHumanActionComplete_ActorTwo
        L2_2(L3_2)
        L2_2 = A0_2.tEvent
        L3_2 = Event
        L3_2 = L3_2.Create
        L4_2 = Event
        L4_2 = L4_2.HumanActionComplete
        L5_2 = {}
        L6_2 = A0_2._ActorTwo
        L5_2[1] = L6_2
        L6_2 = OnDriverDone
        L7_2 = {}
        L8_2 = A0_2
        L7_2[1] = L8_2
        L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
        L2_2.eHumanActionComplete_ActorTwo = L3_2
      end
    end
  end
  L2_2 = A0_2.nCurrent
  L2_2 = A0_2[L2_2]
  L2_2._buttonPressed = true
  L2_2 = A0_2.nCurrent
  L2_2 = A0_2[L2_2]
  L2_2.bSuccess = true
  L2_2 = A0_2.nCurrent
  L2_2 = A0_2[L2_2]
  L2_2 = L2_2.miniGame
  if L2_2 then
    L2_2 = A0_2._hijackerPlayer
    if L2_2 then
      L2_2 = A0_2._bRemote
      if not L2_2 then
        L2_2 = A0_2.nCurrent
        L2_2 = A0_2[L2_2]
        L2_2._buttonPressed = false
        L2_2 = A0_2.nCurrent
        L2_2 = A0_2[L2_2]
        L2_2.bSuccess = false
        L2_2 = A0_2.nCurrent
        L2_2 = A0_2[L2_2]
        L3_2 = OnMinigameStatus
        L2_2.OnMinigameStatus = L3_2
        L2_2 = A0_2.nCurrent
        L2_2 = A0_2[L2_2]
        L3_2 = OnMinigameStart
        L2_2.OnMinigameStart = L3_2
        L2_2 = Event
        L2_2 = L2_2.Delete
        L3_2 = A0_2.tEvent
        L3_2 = L3_2._buttonTimer
        L2_2(L3_2)
        L2_2 = A0_2.tEvent
        L3_2 = Event
        L3_2 = L3_2.Create
        L4_2 = Event
        L4_2 = L4_2.TimerRelative
        L5_2 = {}
        L6_2 = A0_2.nCurrent
        L6_2 = A0_2[L6_2]
        L6_2 = L6_2.miniGameStartDelay
        L7_2 = false
        L5_2[1] = L6_2
        L5_2[2] = L7_2
        L6_2 = A0_2.nCurrent
        L6_2 = A0_2[L6_2]
        L6_2 = L6_2.OnMinigameStart
        L7_2 = {}
        L8_2 = A0_2
        L7_2[1] = L8_2
        L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
        L2_2._buttonTimer = L3_2
      end
    end
  end
end

Begin = L4_1

function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if L2_2 == "table" then
    L2_2 = pairs
    L3_2 = A1_2
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2, L6_2 in L2_2, L3_2, L4_2 do
      L7_2 = Event
      L7_2 = L7_2.Create
      L8_2 = Event
      L8_2 = L8_2.TimerRelative
      L9_2 = {}
      L10_2 = L6_2.nTime
      L11_2 = false
      L9_2[1] = L10_2
      L9_2[2] = L11_2
      
      function L10_2(A0_3)
        local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3
        L1_3 = type
        L2_3 = L6_2
        L2_3 = L2_3.tControllerRumble
        L1_3 = L1_3(L2_3)
        if L1_3 == "table" then
          L1_3 = L6_2
          L1_3 = L1_3.tControllerRumble
          L1_3 = L1_3.nlength
          L2_3 = Pg
          L2_3 = L2_3.Rumble
          L3_3 = A0_2
          L4_3 = L1_3
          L2_3(L3_3, L4_3)
        end
        L1_3 = type
        L2_3 = L6_2
        L2_3 = L2_3.tCameraShake
        L1_3 = L1_3(L2_3)
        if L1_3 == "table" then
          L1_3 = Player
          L1_3 = L1_3.GetLocalCharacter
          L1_3 = L1_3()
          L2_3 = A0_2
          if L1_3 == L2_3 then
            L1_3 = L6_2
            L1_3 = L1_3.tCameraShake
            L1_3 = L1_3.fSetCameraShake
            L2_3 = L6_2
            L2_3 = L2_3.tCameraShake
            L2_3 = L2_3.fSetCameraAmplitude
            L3_3 = Player
            L3_3 = L3_3.GetLocalPlayer
            L3_3 = L3_3()
            player = L3_3
            L3_3 = Player
            L3_3 = L3_3.GetCamera
            L4_3 = player
            L3_3 = L3_3(L4_3)
            playerCamera = L3_3
            L3_3 = Player
            L3_3 = L3_3.GetCharacter
            L4_3 = player
            L3_3 = L3_3(L4_3)
            playerCharacter = L3_3
            L3_3 = Camera
            L3_3 = L3_3.Shake
            L4_3 = playerCamera
            L5_3 = "ShakeCameraMedium"
            L6_3 = playerCharacter
            L7_3 = L2_3
            L8_3 = L1_3
            L3_3(L4_3, L5_3, L6_3, L7_3, L8_3)
          end
        end
        L1_3 = type
        L2_3 = L6_2
        L2_3 = L2_3.tCameraParams
        L1_3 = L1_3(L2_3)
        if L1_3 == "table" then
          L1_3 = L6_2
          L1_3 = L1_3.tCameraParams
          L1_3 = L1_3.nDelay
          if not L1_3 then
            L1_3 = 0
          end
          L2_3 = L6_2
          L2_3 = L2_3.tCameraParams
          L2_3 = L2_3.nPlayerCam
          if not L2_3 then
            L2_3 = 0
          end
          L3_3 = L6_2
          L3_3 = L3_3.tCameraParams
          L3_3 = L3_3.nStartNear
          if not L3_3 then
            L3_3 = 0
          end
          L4_3 = L6_2
          L4_3 = L4_3.tCameraParams
          L4_3 = L4_3.nEndNear
          if not L4_3 then
            L4_3 = 0.1
          end
          L5_3 = L6_2
          L5_3 = L5_3.tCameraParams
          L5_3 = L5_3.nStartFar
          if not L5_3 then
            L5_3 = 10
          end
          L6_3 = L6_2
          L6_3 = L6_3.tCameraParams
          L6_3 = L6_3.nEndFar
          if not L6_3 then
            L6_3 = 40
          end
          L7_3 = L6_2
          L7_3 = L7_3.tCameraParams
          L7_3 = L7_3.nBlur
          if not L7_3 then
            L7_3 = 0.2
          end
          L8_3 = L6_2
          L8_3 = L8_3.tCameraParams
          L8_3 = L8_3.nDuration
          if not L8_3 then
            L8_3 = 0
          end
          L9_3 = L6_2
          L9_3 = L9_3.tCameraParams
          L9_3 = L9_3.nFoV
          if not L9_3 then
            L9_3 = 55
          end
          L10_3 = Player
          L10_3 = L10_3.GetLocalCharacter
          L10_3 = L10_3()
          L11_3 = A0_2
          if L10_3 == L11_3 then
            L10_3 = Graphics
            L10_3 = L10_3.Camera
            L10_3 = L10_3.SetFocusParams
            L11_3 = L2_3
            L12_3 = L3_3
            L13_3 = L4_3
            L14_3 = L5_3
            L15_3 = L6_3
            L16_3 = L7_3
            L17_3 = L8_3
            L10_3(L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3)
            L10_3 = Graphics
            L10_3 = L10_3.Camera
            L10_3 = L10_3.SetFovParams
            L11_3 = L2_3
            L12_3 = L9_3
            L13_3 = L8_3
            L10_3(L11_3, L12_3, L13_3)
          end
        end
        L1_3 = type
        L2_3 = L6_2
        L2_3 = L2_3.tParticleEfx
        L1_3 = L1_3(L2_3)
        if L1_3 == "table" then
          L1_3 = L6_2
          L1_3 = L1_3.tParticleEfx
          L1_3 = L1_3.bSetTransToObj
          if not L1_3 then
            L1_3 = true
          end
          L2_3 = L6_2
          L2_3 = L2_3.tParticleEfx
          L2_3 = L2_3.objectInstanceTemplate
          L3_3 = L6_2
          L3_3 = L3_3.tParticleEfx
          L3_3 = L3_3.objectHardPointBoneName
          L4_3 = L6_2
          L4_3 = L4_3.tParticleEfx
          L4_3 = L4_3.sPFXname
          L5_3 = Object
          L5_3 = L5_3.GetHardpointPosition
          L6_3 = L2_3
          L7_3 = L3_3
          L5_3, L6_3, L7_3 = L5_3(L6_3, L7_3)
          if L5_3 and L6_3 and L7_3 then
            L8_3 = Pg
            L8_3 = L8_3.Spawn
            L9_3 = L4_3
            L10_3 = L5_3
            L11_3 = L6_3
            L12_3 = L7_3
            L13_3 = 0
            L8_3 = L8_3(L9_3, L10_3, L11_3, L12_3, L13_3)
            if L1_3 then
              L9_3 = Object
              L9_3 = L9_3.SetTransformToObject
              L10_3 = L8_3
              L11_3 = L2_3
              L12_3 = L3_3
              L9_3(L10_3, L11_3, L12_3)
            end
          end
        end
        L1_3 = type
        L2_3 = L6_2
        L2_3 = L2_3.tDetachEvent
        L1_3 = L1_3(L2_3)
        if L1_3 == "table" then
          L1_3 = nil
          L2_3 = nil
          L3_3 = nil
          L4_3 = nil
          L5_3 = nil
          L6_3 = nil
          L7_3 = L6_2
          L2_3 = L7_3.objectInstanceTemplate
          L7_3 = L6_2
          L6_3 = L7_3.objectHardPointBoneName
          L7_3 = L6_2
          L5_3 = L7_3.sPFXname
          L7_3 = Pg
          L7_3 = L7_3.GetGuidByName
          L8_3 = L5_3
          L7_3 = L7_3(L8_3)
          L4_3 = L7_3
          L7_3 = Object
          L7_3 = L7_3.Attach
          L8_3 = L2_3
          L9_3 = L6_3
          L10_3 = L4_3
          L7_3, L8_3 = L7_3(L8_3, L9_3, L10_3)
          L3_3 = L8_3
          L1_3 = L7_3
          L7_3 = nil
          L8_3 = Object
          L8_3 = L8_3.Detach
          L9_3 = L2_3
          L10_3 = L3_3
          L8_3 = L8_3(L9_3, L10_3)
          L7_3 = L8_3
          L8_3 = Object
          L8_3 = L8_3.Remove
          L9_3 = L3_3
          L8_3 = L8_3(L9_3)
          L7_3 = L8_3
        end
        L1_3 = type
        L2_3 = L6_2
        L2_3 = L2_3.tPlaySingleVO
        L1_3 = L1_3(L2_3)
        if L1_3 == "table" then
          L1_3 = L6_2
          L1_3 = L1_3.tPlaySingleVO
          L1_3 = L1_3.nSpeaker
          L2_3 = tostring
          L3_3 = L6_2
          L3_3 = L3_3.tPlaySingleVO
          L3_3 = L3_3.nCueName
          L2_3 = L2_3(L3_3)
          L3_3 = VO
          L3_3 = L3_3.Cue
          L4_3 = L1_3
          L5_3 = L2_3
          
          function L6_3()
            local L0_4, L1_4
            L0_4 = true
            return L0_4
          end
          
          L7_3 = {}
          L8_3 = VO
          L8_3 = L8_3.PRIORITY_CINEMATIC
          L3_3(L4_3, L5_3, L6_3, L7_3, L8_3)
        end
        L1_3 = type
        L2_3 = L6_2
        L2_3 = L2_3.tPlayMusic
        L1_3 = L1_3(L2_3)
        if L1_3 == "table" then
          L1_3 = tostring
          L2_3 = L6_2
          L2_3 = L2_3.tPlayMusic
          L2_3 = L2_3.nMusicName
          L1_3 = L1_3(L2_3)
          L2_3 = MrxMusic
          L2_3 = L2_3.PlaySpecialMusic
          L3_3 = L1_3
          L2_3(L3_3)
        end
        L1_3 = type
        L2_3 = L6_2
        L2_3 = L2_3.tPlaySoundFx
        L1_3 = L1_3(L2_3)
        if L1_3 == "table" then
          L1_3 = tostring
          L2_3 = L6_2
          L2_3 = L2_3.tPlaySoundFx
          L2_3 = L2_3.nSoundFxName
          L1_3 = L1_3(L2_3)
          L2_3 = Sound
          L2_3 = L2_3.CueSound
          L3_3 = 0
          L4_3 = L1_3
          L2_3(L3_3, L4_3)
        end
        L1_3 = type
        L2_3 = L6_2
        L2_3 = L2_3.tStopSoundFx
        L1_3 = L1_3(L2_3)
        if L1_3 == "table" then
          L1_3 = tostring
          L2_3 = L6_2
          L2_3 = L2_3.tStopSoundFx
          L2_3 = L2_3.nSoundFxName
          L1_3 = L1_3(L2_3)
          L2_3 = Sound
          L2_3 = L2_3.StopSound
          L3_3 = 0
          L4_3 = L1_3
          L2_3(L3_3, L4_3)
        end
        L1_3 = type
        L2_3 = L6_2
        L2_3 = L2_3.tHeliKill
        L1_3 = L1_3(L2_3)
        if L1_3 == "table" then
          L1_3 = L6_2
          L1_3 = L1_3.tHeliKill
          L1_3 = L1_3.tExplosionHP
          L2_3 = MrxUtil
          L2_3 = L2_3.SpawnObject
          L3_3 = "fx_Explosion_Huge"
          L4_3 = L1_3
          L2_3(L3_3, L4_3)
          L2_3 = MrxUtil
          L2_3 = L2_3.SpawnObject
          L3_3 = "global_particle_firelargesmoke_infinite"
          L4_3 = L1_3
          L2_3 = L2_3(L3_3, L4_3)
          L3_3 = Event
          L3_3 = L3_3.Create
          L4_3 = Event
          L4_3 = L4_3.TimerRelative
          L5_3 = {}
          L6_3 = 20
          L5_3[1] = L6_3
          L6_3 = Object
          L6_3 = L6_3.Remove
          L7_3 = {}
          L8_3 = L2_3
          L7_3[1] = L8_3
          L3_3(L4_3, L5_3, L6_3, L7_3)
        end
        L1_3 = type
        L2_3 = L6_2
        L2_3 = L2_3.tLinkObject
        L1_3 = L1_3(L2_3)
        if L1_3 == "table" then
          L1_3 = L6_2
          L1_3 = L1_3.tLinkObject
          L2_3 = L1_3.vObject
          ChildObjectGuid = L2_3
          L2_3 = L1_3.vParent
          ParentObjectGuid = L2_3
          L2_3 = L1_3.vAttachPoint
          AttachPointName = L2_3
          L2_3 = L1_3.vState
          StateValue = L2_3
          L2_3 = ToggleLinkedObject
          L3_3 = A0_3
          L4_3 = ChildObjectGuid
          L5_3 = ParentObjectGuid
          L6_3 = AttachPointName
          L7_3 = StateValue
          L2_3(L3_3, L4_3, L5_3, L6_3, L7_3)
        end
      end
      
      L11_2 = {}
      L12_2 = self
      L11_2[1] = L12_2
      L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
      L6_2._MultiEventTimer = L7_2
    end
  end
end

_ProcessMultiEventTable = L4_1

function L4_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = A1_2
  L5_2 = L5_2(L6_2)
  ChildGuid = L5_2
  if A4_2 == true then
    L5_2 = Object
    L5_2 = L5_2.Attach
    L6_2 = A2_2
    L7_2 = A3_2
    L8_2 = ChildGuid
    L5_2, L6_2 = L5_2(L6_2, L7_2, L8_2)
    L1_1 = L6_2
    bResult = L5_2
  else
    L5_2 = L1_1
    if L5_2 then
      L5_2 = Object
      L5_2 = L5_2.Detach
      L6_2 = A2_2
      L7_2 = L1_1
      L5_2 = L5_2(L6_2, L7_2)
      bResult = L5_2
      L5_2 = Object
      L5_2 = L5_2.Remove
      L6_2 = L1_1
      L5_2 = L5_2(L6_2)
      bResult = L5_2
    end
  end
end

ToggleLinkedObject = L4_1

function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = type
  L2_2 = A0_2.nCurrent
  L2_2 = A0_2[L2_2]
  L2_2 = L2_2.tVehicleAnimations
  L1_2 = L1_2(L2_2)
  if L1_2 == "table" then
    L1_2 = type
    L2_2 = A0_2.nCurrent
    L2_2 = A0_2[L2_2]
    L2_2 = L2_2.tReactiveLoopFaceStates
    L1_2 = L1_2(L2_2)
    if L1_2 == "table" then
      L1_2 = Play
      L2_2 = A0_2
      L3_2 = A0_2.nCurrent
      L3_2 = A0_2[L3_2]
      L3_2 = L3_2.tHijackerAnimations
      L4_2 = A0_2.nCurrent
      L4_2 = A0_2[L4_2]
      L4_2 = L4_2.nReactiveLoop
      L3_2 = L3_2[L4_2]
      L4_2 = A0_2.nCurrent
      L4_2 = A0_2[L4_2]
      L4_2 = L4_2.tHijackeeAnimations
      L5_2 = A0_2.nCurrent
      L5_2 = A0_2[L5_2]
      L5_2 = L5_2.nReactiveLoop
      L4_2 = L4_2[L5_2]
      L5_2 = A0_2.nCurrent
      L5_2 = A0_2[L5_2]
      L5_2 = L5_2.tVehicleAnimations
      L6_2 = A0_2.nCurrent
      L6_2 = A0_2[L6_2]
      L6_2 = L6_2.nReactiveLoop
      L5_2 = L5_2[L6_2]
      L6_2 = nil
      L7_2 = A0_2.nCurrent
      L7_2 = A0_2[L7_2]
      L7_2 = L7_2.tReactiveLoopFaceStates
      L8_2 = A0_2.nCurrent
      L8_2 = A0_2[L8_2]
      L8_2 = L8_2.nReactiveLoop
      L7_2 = L7_2[L8_2]
      L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
    else
      L1_2 = Play
      L2_2 = A0_2
      L3_2 = A0_2.nCurrent
      L3_2 = A0_2[L3_2]
      L3_2 = L3_2.tHijackerAnimations
      L4_2 = A0_2.nCurrent
      L4_2 = A0_2[L4_2]
      L4_2 = L4_2.nReactiveLoop
      L3_2 = L3_2[L4_2]
      L4_2 = A0_2.nCurrent
      L4_2 = A0_2[L4_2]
      L4_2 = L4_2.tHijackeeAnimations
      L5_2 = A0_2.nCurrent
      L5_2 = A0_2[L5_2]
      L5_2 = L5_2.nReactiveLoop
      L4_2 = L4_2[L5_2]
      L5_2 = A0_2.nCurrent
      L5_2 = A0_2[L5_2]
      L5_2 = L5_2.tVehicleAnimations
      L6_2 = A0_2.nCurrent
      L6_2 = A0_2[L6_2]
      L6_2 = L6_2.nReactiveLoop
      L5_2 = L5_2[L6_2]
      L1_2(L2_2, L3_2, L4_2, L5_2)
    end
  else
    L1_2 = type
    L2_2 = A0_2.nCurrent
    L2_2 = A0_2[L2_2]
    L2_2 = L2_2.tReactiveLoopFaceStates
    L1_2 = L1_2(L2_2)
    if L1_2 == "table" then
      L1_2 = Play
      L2_2 = A0_2
      L3_2 = A0_2.nCurrent
      L3_2 = A0_2[L3_2]
      L3_2 = L3_2.tHijackerAnimations
      L4_2 = A0_2.nCurrent
      L4_2 = A0_2[L4_2]
      L4_2 = L4_2.nReactiveLoop
      L3_2 = L3_2[L4_2]
      L4_2 = A0_2.nCurrent
      L4_2 = A0_2[L4_2]
      L4_2 = L4_2.tHijackeeAnimations
      L5_2 = A0_2.nCurrent
      L5_2 = A0_2[L5_2]
      L5_2 = L5_2.nReactiveLoop
      L4_2 = L4_2[L5_2]
      L5_2 = nil
      L6_2 = nil
      L7_2 = A0_2.nCurrent
      L7_2 = A0_2[L7_2]
      L7_2 = L7_2.tReactiveLoopFaceStates
      L8_2 = A0_2.nCurrent
      L8_2 = A0_2[L8_2]
      L8_2 = L8_2.nReactiveLoop
      L7_2 = L7_2[L8_2]
      L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
    else
      L1_2 = Play
      L2_2 = A0_2
      L3_2 = A0_2.nCurrent
      L3_2 = A0_2[L3_2]
      L3_2 = L3_2.tHijackerAnimations
      L4_2 = A0_2.nCurrent
      L4_2 = A0_2[L4_2]
      L4_2 = L4_2.nReactiveLoop
      L3_2 = L3_2[L4_2]
      L4_2 = A0_2.nCurrent
      L4_2 = A0_2[L4_2]
      L4_2 = L4_2.tHijackeeAnimations
      L5_2 = A0_2.nCurrent
      L5_2 = A0_2[L5_2]
      L5_2 = L5_2.nReactiveLoop
      L4_2 = L4_2[L5_2]
      L1_2(L2_2, L3_2, L4_2)
    end
  end
  L1_2 = CreateReactiveLoopAnimationCompleteEvent
  L2_2 = A0_2
  L1_2(L2_2)
end

PlayReactiveLoop = L4_1

function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.tEvent
  L2_2 = L2_2.eHumanActionComplete_Hijacker
  L1_2(L2_2)
  L1_2 = A0_2.tEvent
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.HumanActionComplete
  L4_2 = {}
  L5_2 = A0_2._hijacker
  L4_2[1] = L5_2
  L5_2 = OnReactiveLoopAnimationComplete
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.eHumanActionComplete_Hijacker = L2_2
end

CreateReactiveLoopAnimationCompleteEvent = L4_1

function L4_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2.nCurrent
  L1_2 = A0_2[L1_2]
  L1_2 = L1_2.bMinigameDone
  if L1_2 == true then
    return
  end
  L1_2 = CreateReactiveLoopAnimationCompleteEvent
  L2_2 = A0_2
  L1_2(L2_2)
end

OnReactiveLoopAnimationComplete = L4_1

function L4_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2)
  local L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L7_2 = type
  L8_2 = A1_2
  L7_2 = L7_2(L8_2)
  if L7_2 == "string" then
    L7_2 = Human
    L7_2 = L7_2.SetState
    L8_2 = A0_2._hijacker
    L9_2 = "InVehicle"
    L10_2 = A1_2
    L7_2(L8_2, L9_2, L10_2)
  end
  L7_2 = type
  L8_2 = A2_2
  L7_2 = L7_2(L8_2)
  if L7_2 == "string" then
    L7_2 = Human
    L7_2 = L7_2.SetState
    L8_2 = A0_2._hijackee
    L9_2 = "InVehicle"
    L10_2 = A2_2
    L7_2(L8_2, L9_2, L10_2)
  end
  L7_2 = type
  L8_2 = A3_2
  L7_2 = L7_2(L8_2)
  if L7_2 == "string" then
    L7_2 = Object
    L7_2 = L7_2.PlayAnimation
    L8_2 = A0_2._vehicle
    L9_2 = A3_2
    L10_2 = false
    L11_2 = "hijack"
    L12_2 = L0_1
    L13_2 = true
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  end
  if A4_2 ~= nil then
    L7_2 = A0_2._ActorOne
    if L7_2 then
      L7_2 = type
      L8_2 = A4_2.ActorOne
      L7_2 = L7_2(L8_2)
      if L7_2 == "string" then
        L7_2 = Human
        L7_2 = L7_2.SetState
        L8_2 = A0_2._ActorOne
        L9_2 = "InVehicle"
        L10_2 = A4_2.ActorOne
        L7_2(L8_2, L9_2, L10_2)
      end
    end
    L7_2 = A0_2._ActorTwo
    if L7_2 then
      L7_2 = type
      L8_2 = A4_2.ActorTwo
      L7_2 = L7_2(L8_2)
      if L7_2 == "string" then
        L7_2 = Human
        L7_2 = L7_2.SetState
        L8_2 = A0_2._ActorTwo
        L9_2 = "InVehicle"
        L10_2 = A4_2.ActorTwo
        L7_2(L8_2, L9_2, L10_2)
      end
    end
  end
  if A5_2 ~= nil then
    L7_2 = type
    L8_2 = A5_2
    L7_2 = L7_2(L8_2)
    if L7_2 == "table" then
      L7_2 = type
      L8_2 = A5_2.hijacker
      L7_2 = L7_2(L8_2)
      if L7_2 == "table" then
        L7_2 = A5_2.hijacker
        charTable = L7_2
        L7_2 = A0_2._hijacker
        charGuid = L7_2
        L7_2 = SetMultiFacialExpressions
        L8_2 = charGuid
        L9_2 = charTable
        L7_2(L8_2, L9_2)
      end
      L7_2 = type
      L8_2 = A5_2.hijackee
      L7_2 = L7_2(L8_2)
      if L7_2 == "table" then
        L7_2 = A5_2.hijackee
        charTable = L7_2
        L7_2 = A0_2._hijackee
        charGuid = L7_2
        L7_2 = SetMultiFacialExpressions
        L8_2 = charGuid
        L9_2 = charTable
        L7_2(L8_2, L9_2)
      else
      end
    end
  end
  if A6_2 ~= nil then
    L7_2 = type
    L8_2 = A6_2
    L7_2 = L7_2(L8_2)
    if L7_2 == "table" then
      L7_2 = type
      L8_2 = A6_2.hijacker
      L7_2 = L7_2(L8_2)
      if L7_2 == "table" then
        L7_2 = A6_2.hijacker
        charTable = L7_2
        L7_2 = A0_2._hijacker
        charGuid = L7_2
        L7_2 = SetMultiFacialExpressions
        L8_2 = charGuid
        L9_2 = charTable
        L7_2(L8_2, L9_2)
      end
      L7_2 = type
      L8_2 = A6_2.hijackee
      L7_2 = L7_2(L8_2)
      if L7_2 == "table" then
        L7_2 = A6_2.hijackee
        charTable = L7_2
        L7_2 = A0_2._hijackee
        charGuid = L7_2
        L7_2 = SetMultiFacialExpressions
        L8_2 = charGuid
        L9_2 = charTable
        L7_2(L8_2, L9_2)
      end
      L7_2 = type
      L8_2 = A6_2.actorOne
      L7_2 = L7_2(L8_2)
      if L7_2 == "table" then
        L7_2 = A6_2.actorOne
        charTable = L7_2
        L7_2 = A0_2._ActorOne
        charGuid = L7_2
        L7_2 = SetMultiFacialExpressions
        L8_2 = charGuid
        L9_2 = charTable
        L7_2(L8_2, L9_2)
      end
      L7_2 = type
      L8_2 = A6_2.actorTwo
      L7_2 = L7_2(L8_2)
      if L7_2 == "table" then
        L7_2 = A6_2.actorTwo
        charTable = L7_2
        L7_2 = A0_2._ActorTwo
        charGuid = L7_2
        L7_2 = SetMultiFacialExpressions
        L8_2 = charGuid
        L9_2 = charTable
        L7_2(L8_2, L9_2)
      else
      end
    end
  end
end

Play = L4_1

function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if L2_2 == "table" then
    L2_2 = pairs
    L3_2 = A1_2
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2, L6_2 in L2_2, L3_2, L4_2 do
      L7_2 = Animation
      L7_2 = L7_2.PlayFacialExpression
      L8_2 = A0_2
      L9_2 = L6_2.state
      L10_2 = L6_2.weight
      L11_2 = L6_2.duration
      L12_2 = L6_2.blend
      L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
    end
  else
  end
end

SetMultiFacialExpressions = L4_1

function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L1_2 = -1
  L2_2 = false
  L3_2 = A0_2.nCurrent
  L3_2 = A0_2[L3_2]
  L3_2 = L3_2.miniGame
  L3_2 = L3_2.sAction
  if L3_2 == "press" then
    L3_2 = A0_2.nCurrent
    L3_2 = A0_2[L3_2]
    L3_2 = L3_2.miniGame
    L4_2 = A0_2.nCurrent
    L4_2 = A0_2[L4_2]
    L4_2 = L4_2.miniGame
    L4_2 = L4_2.nHudButtonMotionSpeed
    if not L4_2 then
      L4_2 = -1
    end
    L3_2.nHudButtonMotionSpeed = L4_2
    L3_2 = Event
    L3_2 = L3_2.Delete
    L4_2 = A0_2.tEvent
    L4_2 = L4_2._eMinigame
    L3_2(L4_2)
    L3_2 = A0_2.tEvent
    L4_2 = Event
    L4_2 = L4_2.Create
    L5_2 = Event
    L5_2 = L5_2.Minigame
    L6_2 = {}
    L7_2 = A0_2._hijackerPlayer
    L8_2 = A0_2.nCurrent
    L8_2 = A0_2[L8_2]
    L8_2 = L8_2.miniGame
    L8_2 = L8_2.nTimeOut
    L9_2 = A0_2.nCurrent
    L9_2 = A0_2[L9_2]
    L9_2 = L9_2.miniGame
    L9_2 = L9_2.sAction
    L10_2 = A0_2.nCurrent
    L10_2 = A0_2[L10_2]
    L10_2 = L10_2.miniGame
    L10_2 = L10_2.button
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L6_2[4] = L10_2
    L7_2 = A0_2.nCurrent
    L7_2 = A0_2[L7_2]
    L7_2 = L7_2.OnMinigameStatus
    L8_2 = {}
    L9_2 = A0_2
    L8_2[1] = L9_2
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
    L3_2._eMinigame = L4_2
  else
    L3_2 = A0_2.nCurrent
    L3_2 = A0_2[L3_2]
    L3_2 = L3_2.miniGame
    L3_2 = L3_2.sAction
    if L3_2 == "hold" then
      L3_2 = A0_2.nCurrent
      L3_2 = A0_2[L3_2]
      L3_2 = L3_2.miniGame
      L4_2 = A0_2.nCurrent
      L4_2 = A0_2[L4_2]
      L4_2 = L4_2.miniGame
      L4_2 = L4_2.nHudButtonMotionSpeed
      if not L4_2 then
        L4_2 = -1
      end
      L3_2.nHudButtonMotionSpeed = L4_2
      L3_2 = Event
      L3_2 = L3_2.Delete
      L4_2 = A0_2.tEvent
      L4_2 = L4_2._eMinigame
      L3_2(L4_2)
      L3_2 = A0_2.tEvent
      L4_2 = Event
      L4_2 = L4_2.Create
      L5_2 = Event
      L5_2 = L5_2.Minigame
      L6_2 = {}
      L7_2 = A0_2._hijackerPlayer
      L8_2 = A0_2.nCurrent
      L8_2 = A0_2[L8_2]
      L8_2 = L8_2.miniGame
      L8_2 = L8_2.nTimeOut
      L9_2 = A0_2.nCurrent
      L9_2 = A0_2[L9_2]
      L9_2 = L9_2.miniGame
      L9_2 = L9_2.sAction
      L10_2 = A0_2.nCurrent
      L10_2 = A0_2[L10_2]
      L10_2 = L10_2.miniGame
      L10_2 = L10_2.button
      L11_2 = A0_2.nCurrent
      L11_2 = A0_2[L11_2]
      L11_2 = L11_2.miniGame
      L11_2 = L11_2.nTime
      L6_2[1] = L7_2
      L6_2[2] = L8_2
      L6_2[3] = L9_2
      L6_2[4] = L10_2
      L6_2[5] = L11_2
      L7_2 = A0_2.nCurrent
      L7_2 = A0_2[L7_2]
      L7_2 = L7_2.OnMinigameStatus
      L8_2 = {}
      L9_2 = A0_2
      L8_2[1] = L9_2
      L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
      L3_2._eMinigame = L4_2
    else
      L3_2 = A0_2.nCurrent
      L3_2 = A0_2[L3_2]
      L3_2 = L3_2.miniGame
      L3_2 = L3_2.sAction
      if L3_2 == "tap" then
        L3_2 = A0_2.nCurrent
        L3_2 = A0_2[L3_2]
        L3_2 = L3_2.miniGame
        L4_2 = A0_2.nCurrent
        L4_2 = A0_2[L4_2]
        L4_2 = L4_2.miniGame
        L4_2 = L4_2.nHudButtonMotionSpeed
        if not L4_2 then
          L4_2 = 0.1
        end
        L3_2.nHudButtonMotionSpeed = L4_2
        L3_2 = A0_2.nCurrent
        L3_2 = A0_2[L3_2]
        L3_2 = L3_2.miniGame
        L3_2.nPlayerScore = 0
        L3_2 = A0_2.nCurrent
        L3_2 = A0_2[L3_2]
        L3_2 = L3_2.miniGame
        L3_2.nDriverScore = 0
        L3_2 = A0_2.nCurrent
        L3_2 = A0_2[L3_2]
        L3_2 = L3_2.miniGame
        L4_2 = A0_2.nCurrent
        L4_2 = A0_2[L4_2]
        L4_2 = L4_2.miniGame
        L4_2 = L4_2.nDriverDifficulty
        if not L4_2 then
          L4_2 = 0.1
        end
        L3_2.nDriverDifficulty = L4_2
        L3_2 = A0_2.nCurrent
        L3_2 = A0_2[L3_2]
        L3_2 = L3_2.miniGame
        L4_2 = A0_2.nCurrent
        L4_2 = A0_2[L4_2]
        L4_2 = L4_2.miniGame
        L4_2 = L4_2.nSuccessThreshold
        if not L4_2 then
          L4_2 = 3
        end
        L3_2.nSuccessThreshold = L4_2
        L3_2 = Event
        L3_2 = L3_2.Delete
        L4_2 = A0_2.tEvent
        L4_2 = L4_2._eMinigame
        L3_2(L4_2)
        L3_2 = A0_2.tEvent
        L4_2 = Event
        L4_2 = L4_2.Create
        L5_2 = Event
        L5_2 = L5_2.Minigame
        L6_2 = {}
        L7_2 = A0_2._hijackerPlayer
        L8_2 = A0_2.nCurrent
        L8_2 = A0_2[L8_2]
        L8_2 = L8_2.miniGame
        L8_2 = L8_2.nTimeOut
        L9_2 = A0_2.nCurrent
        L9_2 = A0_2[L9_2]
        L9_2 = L9_2.miniGame
        L9_2 = L9_2.sAction
        L10_2 = A0_2.nCurrent
        L10_2 = A0_2[L10_2]
        L10_2 = L10_2.miniGame
        L10_2 = L10_2.button
        L6_2[1] = L7_2
        L6_2[2] = L8_2
        L6_2[3] = L9_2
        L6_2[4] = L10_2
        L7_2 = A0_2.nCurrent
        L7_2 = A0_2[L7_2]
        L7_2 = L7_2.OnMinigameStatus
        L8_2 = {}
        L9_2 = A0_2
        L8_2[1] = L9_2
        L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
        L3_2._eMinigame = L4_2
        L3_2 = A0_2.nCurrent
        L3_2 = A0_2[L3_2]
        L4_2 = OnDriverSimulatedButtonPress
        L3_2.OnDriverSimulatedButtonPress = L4_2
        L3_2 = Event
        L3_2 = L3_2.Delete
        L4_2 = A0_2.tEvent
        L4_2 = L4_2._eventDriverSimulatedButton
        L3_2(L4_2)
        L3_2 = A0_2.tEvent
        L4_2 = Event
        L4_2 = L4_2.Create
        L5_2 = Event
        L5_2 = L5_2.TimerRelative
        L6_2 = {}
        L7_2 = A0_2.nCurrent
        L7_2 = A0_2[L7_2]
        L7_2 = L7_2.miniGame
        L7_2 = L7_2.nDriverDifficulty
        L8_2 = false
        L6_2[1] = L7_2
        L6_2[2] = L8_2
        L7_2 = A0_2.nCurrent
        L7_2 = A0_2[L7_2]
        L7_2 = L7_2.OnDriverSimulatedButtonPress
        L8_2 = {}
        L9_2 = A0_2
        L8_2[1] = L9_2
        L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
        L3_2._eventDriverSimulatedButton = L4_2
      end
    end
  end
  L3_2 = A0_2.nCurrent
  L3_2 = A0_2[L3_2]
  L3_2 = L3_2.miniGame
  L3_2 = L3_2.bExtraHudParameters
  if L3_2 == true then
    L3_2 = MrxGuiHudActionHijack
    L3_2 = L3_2.ShowButton
    L4_2 = A0_2._hijackerPlayer
    L5_2 = A0_2.nCurrent
    L5_2 = A0_2[L5_2]
    L5_2 = L5_2.miniGame
    L5_2 = L5_2.button
    L6_2 = A0_2.nCurrent
    L6_2 = A0_2[L6_2]
    L6_2 = L6_2.miniGame
    L6_2 = L6_2.nTimeOut
    L7_2 = A0_2.nCurrent
    L7_2 = A0_2[L7_2]
    L7_2 = L7_2.miniGame
    L7_2 = L7_2.nHudButtonMotionSpeed
    L8_2 = A0_2.nCurrent
    L8_2 = A0_2[L8_2]
    L8_2 = L8_2.miniGame
    L8_2 = L8_2.nXPosition
    L9_2 = A0_2.nCurrent
    L9_2 = A0_2[L9_2]
    L9_2 = L9_2.miniGame
    L9_2 = L9_2.nYPosition
    L10_2 = A0_2.nCurrent
    L10_2 = A0_2[L10_2]
    L10_2 = L10_2.miniGame
    L10_2 = L10_2.nTranslucency
    L11_2 = A0_2.nCurrent
    L11_2 = A0_2[L11_2]
    L11_2 = L11_2.miniGame
    L11_2 = L11_2.bShowSparks
    L12_2 = A0_2.nCurrent
    L12_2 = A0_2[L12_2]
    L12_2 = L12_2.miniGame
    L12_2 = L12_2.nElapsedTime
    L13_2 = A0_2.nCurrent
    L13_2 = A0_2[L13_2]
    L13_2 = L13_2.miniGame
    L13_2 = L13_2.bFillTimer
    L14_2 = A0_2.nCurrent
    L14_2 = A0_2[L14_2]
    L14_2 = L14_2.miniGame
    L14_2 = L14_2.bClockwise
    L15_2 = A0_2.nCurrent
    L15_2 = A0_2[L15_2]
    L15_2 = L15_2.miniGame
    L15_2 = L15_2.bIsRecovery
    L16_2 = A0_2.nCurrent
    L16_2 = A0_2[L16_2]
    L16_2 = L16_2.miniGame
    L16_2 = L16_2.bShowTimer
    L17_2 = A0_2.nCurrent
    L17_2 = A0_2[L17_2]
    L17_2 = L17_2.miniGame
    L17_2 = L17_2.nScale
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  else
    L3_2 = MrxGuiHudActionHijack
    L3_2 = L3_2.ShowButton
    L4_2 = A0_2._hijackerPlayer
    L5_2 = A0_2.nCurrent
    L5_2 = A0_2[L5_2]
    L5_2 = L5_2.miniGame
    L5_2 = L5_2.button
    L6_2 = A0_2.nCurrent
    L6_2 = A0_2[L6_2]
    L6_2 = L6_2.miniGame
    L6_2 = L6_2.nTimeOut
    L7_2 = A0_2.nCurrent
    L7_2 = A0_2[L7_2]
    L7_2 = L7_2.miniGame
    L7_2 = L7_2.nHudButtonMotionSpeed
    L8_2 = nil
    L9_2 = nil
    L10_2 = nil
    L11_2 = L2_2
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  end
end

OnMinigameStart = L4_1

function L4_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  if A1_2 ~= "update" then
  end
  if A1_2 == "success" then
    L3_2 = A0_2.nCurrent
    L3_2 = A0_2[L3_2]
    L3_2.bSuccess = true
    L3_2 = MrxGuiHudActionHijack
    L3_2 = L3_2.HideButton
    L4_2 = A0_2._hijackerPlayer
    L3_2(L4_2)
    L3_2 = Sound
    L3_2 = L3_2.CueSound
    L4_2 = 0
    L5_2 = "ui_HUD_Minigame_Press_Button"
    L3_2(L4_2, L5_2)
  elseif A1_2 == "failed" then
    L3_2 = A0_2.nCurrent
    L3_2 = A0_2[L3_2]
    L3_2 = L3_2.nReactiveLoop
    if L3_2 ~= nil then
      L3_2 = MrxGuiHudActionHijack
      L3_2 = L3_2.ShowFail
      L4_2 = A0_2._hijackerPlayer
      L3_2(L4_2)
      L3_2 = A0_2.nCurrent
      L3_2 = A0_2[L3_2]
      L3_2 = L3_2.nReactiveLoop
      if 1 < L3_2 then
        L3_2 = A0_2.nCurrent
        L3_2 = A0_2[L3_2]
        L3_2.bSuccess = false
        L3_2 = A0_2.nCurrent
        L3_2 = A0_2[L3_2]
        L3_2.bMinigameDone = true
        L3_2 = DoFailureAnimation
        L4_2 = A0_2
        L3_2(L4_2)
        L3_2 = MrxGuiHudActionHijack
        L3_2 = L3_2.ShowFail
        L4_2 = A0_2._hijackerPlayer
        L3_2(L4_2)
      else
        L3_2 = A0_2.nCurrent
        L3_2 = A0_2[L3_2]
        L3_2.bSuccess = false
        L3_2 = MrxGuiHudActionHijack
        L3_2 = L3_2.ShowFail
        L4_2 = A0_2._hijackerPlayer
        L3_2(L4_2)
      end
    else
      L3_2 = A0_2.nCurrent
      L3_2 = A0_2[L3_2]
      L3_2.bSuccess = false
      L3_2 = MrxGuiHudActionHijack
      L3_2 = L3_2.ShowFail
      L4_2 = A0_2._hijackerPlayer
      L3_2(L4_2)
    end
  elseif A1_2 == "update" then
    L3_2 = A0_2.nCurrent
    L3_2 = A0_2[L3_2]
    L3_2 = L3_2.miniGame
    L3_2 = L3_2.sAction
    if L3_2 == "tap" then
      L3_2 = HandleTapMinigame
      L4_2 = A0_2
      L5_2 = A1_2
      L6_2 = A2_2
      L3_2(L4_2, L5_2, L6_2)
    end
  elseif A1_2 == "timeout" then
    L3_2 = A0_2.nCurrent
    L3_2 = A0_2[L3_2]
    L3_2.bSuccess = false
    L3_2 = MrxGuiHudActionHijack
    L3_2 = L3_2.ShowFail
    L4_2 = A0_2._hijackerPlayer
    L3_2(L4_2)
    L3_2 = A0_2.nCurrent
    L3_2 = A0_2[L3_2]
    L3_2.bEndReactiveLoop = true
  else
    L3_2 = A0_2.nCurrent
    L3_2 = A0_2[L3_2]
    L3_2.bSuccess = true
    L3_2 = MrxGuiHudActionHijack
    L3_2 = L3_2.HideButton
    L4_2 = A0_2._hijackerPlayer
    L3_2(L4_2)
  end
end

OnMinigameStatus = L4_1

function L4_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = A0_2.nCurrent
  L3_2 = A0_2[L3_2]
  L3_2 = L3_2.miniGame
  if L3_2 ~= nil then
    L3_2 = A0_2.nCurrent
    L3_2 = A0_2[L3_2]
    L3_2 = L3_2.miniGame
    L3_2 = L3_2.nPlayerScore
    if L3_2 ~= nil then
      L3_2 = A0_2.nCurrent
      L3_2 = A0_2[L3_2]
      L3_2 = L3_2.bMinigameDone
      if L3_2 ~= true then
        L3_2 = A0_2.nCurrent
        L3_2 = A0_2[L3_2]
        L3_2 = L3_2.nReactiveLoop
        if L3_2 ~= nil then
          goto lbl_23
        end
      end
    end
  end
  do return end
  ::lbl_23::
  if not A2_2 then
    A2_2 = 1
  end
  L3_2 = true
  L4_2 = A0_2.nCurrent
  L4_2 = A0_2[L4_2]
  L4_2 = L4_2.miniGame
  L5_2 = A0_2.nCurrent
  L5_2 = A0_2[L5_2]
  L5_2 = L5_2.miniGame
  L5_2 = L5_2.nPlayerScore
  L6_2 = 1 - A2_2
  L5_2 = L5_2 + L6_2
  L4_2.nPlayerScore = L5_2
  L4_2 = false
  L5_2 = false
  L6_2 = A0_2.nCurrent
  L6_2 = A0_2[L6_2]
  L6_2 = L6_2.miniGame
  L6_2 = L6_2.nPlayerScore
  L7_2 = A0_2.nCurrent
  L7_2 = A0_2[L7_2]
  L7_2 = L7_2.miniGame
  L7_2 = L7_2.nSuccessThreshold
  if L6_2 > L7_2 then
    L4_2 = true
  end
  if A1_2 ~= "driver" then
    L6_2 = A0_2.nCurrent
    L6_2 = A0_2[L6_2]
    L6_2 = L6_2.miniGame
    L6_2 = L6_2.nDriverScore
    L7_2 = A0_2.nCurrent
    L7_2 = A0_2[L7_2]
    L7_2 = L7_2.miniGame
    L7_2 = L7_2.nSuccessThreshold
    if not (L6_2 > L7_2) then
      goto lbl_63
    end
  end
  L5_2 = true
  ::lbl_63::
  if L4_2 or L5_2 then
    L6_2 = A0_2.nCurrent
    L6_2 = A0_2[L6_2]
    L6_2 = L6_2.miniGame
    L6_2.nPlayerScore = 0
    L6_2 = A0_2.nCurrent
    L6_2 = A0_2[L6_2]
    L6_2 = L6_2.miniGame
    L6_2.nDriverScore = 0
  end
  if L4_2 then
    L6_2 = A0_2.nCurrent
    L6_2 = A0_2[L6_2]
    L7_2 = A0_2.nCurrent
    L7_2 = A0_2[L7_2]
    L7_2 = L7_2.nReactiveLoop
    L7_2 = L7_2 + 1
    L6_2.nReactiveLoop = L7_2
    L3_2 = false
    L6_2 = Sound
    L6_2 = L6_2.CueSound
    L7_2 = 0
    L8_2 = "ui_HUD_Minigame_Press_Button"
    L6_2(L7_2, L8_2)
    L6_2 = A0_2.nCurrent
    L6_2 = A0_2[L6_2]
    L6_2 = L6_2.nReactiveLoop
    L7_2 = table
    L7_2 = L7_2.maxn
    L8_2 = A0_2.nCurrent
    L8_2 = A0_2[L8_2]
    L8_2 = L8_2.tHijackerAnimations
    L7_2 = L7_2(L8_2)
    if L6_2 > L7_2 then
      L6_2 = A0_2.nCurrent
      L6_2 = A0_2[L6_2]
      L6_2.bSuccess = true
      L6_2 = A0_2.nCurrent
      L6_2 = A0_2[L6_2]
      L6_2.bMinigameDone = true
      L6_2 = DeleteAllEvents
      L7_2 = A0_2
      L6_2(L7_2)
      L6_2 = DoSuccessAnimation
      L7_2 = A0_2
      L6_2(L7_2)
      L6_2 = Sound
      L6_2 = L6_2.CueSound
      L7_2 = 0
      L8_2 = "ui_HUD_Minigame_Press_Button"
      L6_2(L7_2, L8_2)
    else
      L6_2 = PlayReactiveLoop
      L7_2 = A0_2
      L6_2(L7_2)
    end
  end
  if L5_2 or A1_2 == "timeout" then
    L6_2 = A0_2.nCurrent
    L6_2 = A0_2[L6_2]
    L7_2 = A0_2.nCurrent
    L7_2 = A0_2[L7_2]
    L7_2 = L7_2.nReactiveLoop
    L7_2 = L7_2 - 1
    L6_2.nReactiveLoop = L7_2
    L3_2 = false
    L6_2 = Pg
    L6_2 = L6_2.Rumble
    L7_2 = A0_2._hijacker
    L8_2 = 0.15555
    L6_2(L7_2, L8_2)
    L6_2 = A0_2.nCurrent
    L6_2 = A0_2[L6_2]
    L6_2 = L6_2.nReactiveLoop
    if L6_2 < 1 or A1_2 == "timeout" then
      L6_2 = A0_2.nCurrent
      L6_2 = A0_2[L6_2]
      L6_2.bSuccess = false
      L6_2 = A0_2.nCurrent
      L6_2 = A0_2[L6_2]
      L6_2.bMinigameDone = true
      L6_2 = DeleteAllEvents
      L7_2 = A0_2
      L6_2(L7_2)
      L6_2 = DoFailureAnimation
      L7_2 = A0_2
      L6_2(L7_2)
      L6_2 = MrxGuiHudActionHijack
      L6_2 = L6_2.ShowFail
      L7_2 = A0_2._hijackerPlayer
      L8_2 = 1
      L6_2(L7_2, L8_2)
    else
      L6_2 = A0_2.nCurrent
      L6_2 = A0_2[L6_2]
      L6_2 = L6_2.miniGame
      L7_2 = A0_2.nCurrent
      L7_2 = A0_2[L7_2]
      L7_2 = L7_2.miniGame
      L7_2 = L7_2.nDriverDifficulty
      L8_2 = A0_2.nCurrent
      L8_2 = A0_2[L8_2]
      L8_2 = L8_2.miniGame
      L8_2 = L8_2.nDriverDifficulty
      L8_2 = L8_2 * 0.1
      L7_2 = L7_2 - L8_2
      L6_2.nDriverDifficulty = L7_2
      L6_2 = PlayReactiveLoop
      L7_2 = A0_2
      L6_2(L7_2)
    end
  end
  return L3_2
end

HandleTapMinigame = L4_1

function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = A0_2.nCurrent
  L1_2 = A0_2[L1_2]
  L1_2 = L1_2.bEndReactiveLoop
  if L1_2 == true then
    L1_2 = DoFailureAnimation
    L2_2 = A0_2
    L1_2(L2_2)
    return
  end
  L1_2 = A0_2.nCurrent
  L1_2 = A0_2[L1_2]
  L1_2 = L1_2.miniGame
  L2_2 = A0_2.nCurrent
  L2_2 = A0_2[L2_2]
  L2_2 = L2_2.miniGame
  L2_2 = L2_2.nSuccessThreshold
  L1_2.nDriverScore = L2_2
  L1_2 = HandleTapMinigame
  L2_2 = A0_2
  L3_2 = "driver"
  L1_2(L2_2, L3_2)
  L1_2 = A0_2.tEvent
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = A0_2.nCurrent
  L5_2 = A0_2[L5_2]
  L5_2 = L5_2.miniGame
  L5_2 = L5_2.nDriverDifficulty
  L6_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = A0_2.nCurrent
  L5_2 = A0_2[L5_2]
  L5_2 = L5_2.OnDriverSimulatedButtonPress
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2._eventDriverSimulatedButton = L2_2
end

OnDriverSimulatedButtonPress = L4_1

function L4_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2
  L4_2 = Event
  L4_2 = L4_2.Post
  L5_2 = "ActionHijackFinish"
  L6_2 = {}
  L6_2.Hijacker = A0_2
  L6_2.Hijackee = A1_2
  L6_2.Vehicle = A2_2
  L6_2.Success = A3_2
  L4_2(L5_2, L6_2)
  L4_2 = false
  _bIsInHijack = L4_2
  L4_2 = MrxUtil
  L4_2 = L4_2.CallWithOptionalArgs
  L5_2 = _fUnloadCallback
  L6_2 = _tUnloadCallbackArgs
  L4_2(L5_2, L6_2)
  L4_2 = SetUnloadCallback
  L5_2 = nil
  L6_2 = nil
  L4_2(L5_2, L6_2)
  L4_2 = WifFreePlay
  L4_2 = L4_2.StartNag
  L4_2()
end

ActionHijackFinish = L4_1

function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Event
  L1_2 = L1_2.Post
  L2_2 = "ActionHijackComplete"
  L3_2 = {}
  L4_2 = A0_2
  L3_2[1] = L4_2
  L1_2(L2_2, L3_2)
  L1_2 = A0_2.nCurrent
  L1_2 = A0_2[L1_2]
  L1_2 = L1_2.bSuccess
  if L1_2 == true then
    L1_2 = DoSuccessAnimation
    L2_2 = A0_2
    L1_2(L2_2)
  else
    L1_2 = DoFailureAnimation
    L2_2 = A0_2
    L1_2(L2_2)
  end
end

OnAnimationComplete = L4_1

function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = type
  L3_2 = A0_2.nCurrent
  L3_2 = A0_2[L3_2]
  L3_2 = L3_2.GetNextSuccessAnimation
  L2_2 = L2_2(L3_2)
  if L2_2 == "function" then
    L2_2 = A0_2.nCurrent
    L2_2 = A0_2[L2_2]
    L2_2 = L2_2.GetNextSuccessAnimation
    L3_2 = A0_2
    L4_2 = A0_2.nCurrent
    L2_2 = L2_2(L3_2, L4_2)
    L1_2 = L2_2
  else
    L2_2 = A0_2.nCurrent
    L1_2 = L2_2 + 1
  end
  L2_2 = DeleteAllEvents
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = A0_2[L1_2]
  if L2_2 then
    L2_2 = MrxGuiHudActionHijack
    L2_2 = L2_2.HideButton
    L3_2 = A0_2._hijackerPlayer
    L2_2(L3_2)
    A0_2.nCurrent = L1_2
    L2_2 = Begin
    L3_2 = A0_2
    L4_2 = A0_2.nCurrent
    L2_2(L3_2, L4_2)
  else
    L2_2 = A0_2._hijackerPlayer
    L3_2 = Player
    L3_2 = L3_2.GetLocalPlayer
    L3_2 = L3_2()
    if L2_2 == L3_2 then
      L2_2 = MrxSound
      L2_2 = L2_2.EndActionHijack
      L3_2 = RULESET_SOLANO
      L3_2 = not L3_2
      L4_2 = true
      L2_2(L3_2, L4_2)
    end
    L2_2 = ActionHijackComplete
    L3_2 = A0_2
    L2_2(L3_2)
  end
end

DoSuccessAnimation = L4_1

function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Vehicle
  L1_2 = L1_2.SetHijackSuccess
  if L1_2 then
    L1_2 = A0_2._bRemote
    if not L1_2 then
      L1_2 = Vehicle
      L1_2 = L1_2.SetHijackSuccess
      L2_2 = A0_2._hijacker
      L3_2 = false
      L1_2(L2_2, L3_2)
    end
  end
  L1_2 = MrxGuiHudActionHijack
  L1_2 = L1_2.SetDisplayVisible
  L2_2 = A0_2._hijackerPlayer
  L3_2 = false
  L1_2(L2_2, L3_2)
  L1_2 = DeleteAllEvents
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = type
  L2_2 = A0_2.nCurrent
  L2_2 = A0_2[L2_2]
  L2_2 = L2_2.OnFailureAnimationBegin
  L1_2 = L1_2(L2_2)
  if L1_2 == "function" then
    L1_2 = A0_2.nCurrent
    L1_2 = A0_2[L1_2]
    L1_2 = L1_2.OnFailureAnimationBegin
    L2_2 = A0_2
    L3_2 = A0_2.nCurrent
    L1_2 = L1_2(L2_2, L3_2)
    if L1_2 then
      return
    end
  end
  L1_2 = RestoreCamera
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = A0_2.nCurrent
  L1_2 = A0_2[L1_2]
  L1_2 = L1_2.hijackerAnimationFail
  if L1_2 then
    L1_2 = Human
    L1_2 = L1_2.SetState
    L2_2 = A0_2._hijacker
    L3_2 = "InVehicle"
    L4_2 = A0_2.nCurrent
    L4_2 = A0_2[L4_2]
    L4_2 = L4_2.hijackerAnimationFail
    L1_2(L2_2, L3_2, L4_2)
  end
  L1_2 = A0_2.nCurrent
  L1_2 = A0_2[L1_2]
  L1_2 = L1_2.tCharactersFaceStates
  if L1_2 ~= nil then
    L1_2 = type
    L2_2 = A0_2.nCurrent
    L2_2 = A0_2[L2_2]
    L2_2 = L2_2.tCharactersFaceStates
    L1_2 = L1_2(L2_2)
    if L1_2 == "table" then
      L1_2 = A0_2.nCurrent
      L1_2 = A0_2[L1_2]
      L1_2 = L1_2.tCharactersFaceStates
      sCharacterTable = L1_2
      L1_2 = type
      L2_2 = sCharacterTable
      L2_2 = L2_2.hijackerFail
      L1_2 = L1_2(L2_2)
      if L1_2 == "table" then
        L1_2 = sCharacterTable
        L1_2 = L1_2.hijackerFail
        charTable = L1_2
        L1_2 = A0_2._hijacker
        charGuid = L1_2
        L1_2 = SetMultiFacialExpressions
        L2_2 = charGuid
        L3_2 = charTable
        L1_2(L2_2, L3_2)
      end
      L1_2 = type
      L2_2 = sCharacterTable
      L2_2 = L2_2.hijackeeFail
      L1_2 = L1_2(L2_2)
      if L1_2 == "table" then
        L1_2 = sCharacterTable
        L1_2 = L1_2.hijackeeFail
        charTable = L1_2
        L1_2 = A0_2._hijackee
        charGuid = L1_2
        L1_2 = SetMultiFacialExpressions
        L2_2 = charGuid
        L3_2 = charTable
        L1_2(L2_2, L3_2)
      end
      L1_2 = type
      L2_2 = sCharacterTable
      L2_2 = L2_2.actorOneFail
      L1_2 = L1_2(L2_2)
      if L1_2 == "table" then
        L1_2 = sCharacterTable
        L1_2 = L1_2.actorOneFail
        charTable = L1_2
        L1_2 = A0_2._ActorOne
        charGuid = L1_2
        L1_2 = SetMultiFacialExpressions
        L2_2 = charGuid
        L3_2 = charTable
        L1_2(L2_2, L3_2)
      end
      L1_2 = type
      L2_2 = sCharacterTable
      L2_2 = L2_2.actorTwoFail
      L1_2 = L1_2(L2_2)
      if L1_2 == "table" then
        L1_2 = sCharacterTable
        L1_2 = L1_2.actorTwoFail
        charTable = L1_2
        L1_2 = A0_2._ActorTwo
        charGuid = L1_2
        L1_2 = SetMultiFacialExpressions
        L2_2 = charGuid
        L3_2 = charTable
        L1_2(L2_2, L3_2)
      else
      end
    else
    end
  end
  L1_2 = type
  L2_2 = A0_2.nCurrent
  L2_2 = A0_2[L2_2]
  L2_2 = L2_2.OnFailAnimationStart
  L1_2 = L1_2(L2_2)
  if L1_2 == "function" then
    L1_2 = A0_2.nCurrent
    L1_2 = A0_2[L1_2]
    L1_2 = L1_2.OnFailAnimationStart
    L2_2 = A0_2
    L3_2 = A0_2.nCurrent
    L1_2(L2_2, L3_2)
  end
  L1_2 = A0_2.nCurrent
  L1_2 = A0_2[L1_2]
  L1_2 = L1_2.hijackeeAnimationFail
  if L1_2 ~= nil then
    L1_2 = Human
    L1_2 = L1_2.SetState
    L2_2 = A0_2._hijackee
    L3_2 = "InVehicle"
    L4_2 = A0_2.nCurrent
    L4_2 = A0_2[L4_2]
    L4_2 = L4_2.hijackeeAnimationFail
    L1_2(L2_2, L3_2, L4_2)
  end
  L1_2 = A0_2.nCurrent
  L1_2 = A0_2[L1_2]
  L1_2 = L1_2.vehicleAnimationFail
  if L1_2 ~= nil then
    L1_2 = Object
    L1_2 = L1_2.PlayAnimation
    L2_2 = A0_2._vehicle
    L3_2 = A0_2.nCurrent
    L3_2 = A0_2[L3_2]
    L3_2 = L3_2.vehicleAnimationFail
    L4_2 = false
    L5_2 = "hijack"
    L6_2 = L0_1
    L7_2 = true
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  end
  L1_2 = A0_2.nCurrent
  L1_2 = A0_2[L1_2]
  L1_2 = L1_2.ExtraActors
  if L1_2 ~= nil then
    L1_2 = A0_2.nCurrent
    L1_2 = A0_2[L1_2]
    L1_2 = L1_2.ExtraActors
    L1_2 = L1_2.ActorOneAnimationFail
    if L1_2 ~= nil then
      L1_2 = Human
      L1_2 = L1_2.SetState
      L2_2 = A0_2._ActorOne
      L3_2 = "InVehicle"
      L4_2 = A0_2.nCurrent
      L4_2 = A0_2[L4_2]
      L4_2 = L4_2.ExtraActors
      L4_2 = L4_2.ActorOneAnimationFail
      L1_2(L2_2, L3_2, L4_2)
    end
    L1_2 = A0_2.nCurrent
    L1_2 = A0_2[L1_2]
    L1_2 = L1_2.ExtraActors
    L1_2 = L1_2.ActorTwoAnimationFail
    if L1_2 ~= nil then
      L1_2 = Human
      L1_2 = L1_2.SetState
      L2_2 = A0_2._ActorTwo
      L3_2 = "InVehicle"
      L4_2 = A0_2.nCurrent
      L4_2 = A0_2[L4_2]
      L4_2 = L4_2.ExtraActors
      L4_2 = L4_2.ActorTwoAnimationFail
      L1_2(L2_2, L3_2, L4_2)
    end
  end
  L1_2 = Human
  L1_2 = L1_2.SetPreemptiveRagdoll
  if L1_2 ~= nil then
    L1_2 = Human
    L1_2 = L1_2.SetPreemptiveRagdoll
    L2_2 = A0_2._hijacker
    L1_2(L2_2)
  end
  L1_2 = A0_2.tEvent
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.HumanActionComplete
  L4_2 = {}
  L5_2 = A0_2._hijacker
  L4_2[1] = L5_2
  L5_2 = OnFailAnimationComplete
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2._FailureAnimationTimer = L2_2
end

DoFailureAnimation = L4_1

function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = A0_2._hijacker
  uHijacker = L1_2
  L1_2 = A0_2._hijackee
  uHijackee = L1_2
  L1_2 = A0_2._vehicle
  uVehicle = L1_2
  L1_2 = A0_2.nCurrent
  L1_2 = A0_2[L1_2]
  L1_2 = L1_2.bSuccess
  bSuccess = L1_2
  L1_2 = DeleteAllEvents
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = type
  L2_2 = A0_2.nCurrent
  L2_2 = A0_2[L2_2]
  L2_2 = L2_2.OnFailureAnimationComplete
  L1_2 = L1_2(L2_2)
  if L1_2 == "function" then
    L1_2 = RULESET_SOLANO
    if L1_2 == true then
      L1_2 = CleanupCommonNonSuccess
      L2_2 = A0_2
      L3_2 = true
      L1_2(L2_2, L3_2)
      L1_2 = MrxGuiManager
      L1_2 = L1_2.ToggleHud
      L2_2 = A0_2._hijackerPlayer
      L3_2 = true
      L1_2(L2_2, L3_2)
      L1_2 = OnRagdollDone
      L2_2 = A0_2
      L3_2 = bSuccess
      L1_2(L2_2, L3_2)
    end
    L1_2 = A0_2.nCurrent
    L1_2 = A0_2[L1_2]
    L1_2 = L1_2.OnFailureAnimationComplete
    L2_2 = A0_2
    L3_2 = A0_2.nCurrent
    L1_2(L2_2, L3_2)
  else
    L1_2 = CleanupCommonNonSuccess
    L2_2 = A0_2
    L3_2 = true
    L1_2(L2_2, L3_2)
    L1_2 = A0_2._bRemote
    if not L1_2 then
      L1_2 = A0_2.tEvent
      L2_2 = Event
      L2_2 = L2_2.Create
      L3_2 = Event
      L3_2 = L3_2.TimerRelative
      L4_2 = {}
      L5_2 = nKnockdownDuration
      L4_2[1] = L5_2
      L5_2 = OnRagdollMinigameDone
      L6_2 = {}
      L7_2 = A0_2
      L8_2 = true
      L6_2[1] = L7_2
      L6_2[2] = L8_2
      L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
      L1_2._eMinigame = L2_2
      L1_2 = Object
      L1_2 = L1_2.IsPlayerControlled
      L2_2 = A0_2._hijacker
      L1_2 = L1_2(L2_2)
      L2_2 = Player
      L2_2 = L2_2.GetCamera
      L3_2 = L1_2
      L2_2 = L2_2(L3_2)
      L3_2 = Player
      L3_2 = L3_2.SetCinematicMode
      L4_2 = L1_2
      L5_2 = true
      L6_2 = true
      L3_2(L4_2, L5_2, L6_2)
      L3_2 = Camera
      L3_2 = L3_2.Blend
      L4_2 = L2_2
      L5_2 = 1
      L3_2(L4_2, L5_2)
      L3_2 = Camera
      L3_2 = L3_2.SetLookAt
      L4_2 = L2_2
      L5_2 = A0_2._hijacker
      L6_2 = "bone_chest"
      L3_2(L4_2, L5_2, L6_2)
      L3_2 = Camera
      L3_2 = L3_2.Hold
      L4_2 = L2_2
      L5_2 = true
      L6_2 = false
      L3_2(L4_2, L5_2, L6_2)
    else
      L1_2 = OnRagdollDone
      L2_2 = A0_2
      L3_2 = bSuccess
      L1_2(L2_2, L3_2)
    end
  end
  L1_2 = A0_2._hijackerPlayer
  L2_2 = Player
  L2_2 = L2_2.GetLocalPlayer
  L2_2 = L2_2()
  if L1_2 == L2_2 then
    L1_2 = MrxSound
    L1_2 = L1_2.EndActionHijack
    L2_2 = RULESET_SOLANO
    L2_2 = not L2_2
    L3_2 = false
    L1_2(L2_2, L3_2)
  end
  L1_2 = ActionHijackFinish
  L2_2 = uHijacker
  L3_2 = uHijackee
  L4_2 = uVehicle
  L5_2 = bSuccess
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

OnFailAnimationComplete = L4_1

function L4_1(A0_2, A1_2, A2_2)
end

OnRagdollMinigameUpdate = L4_1

function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  if A1_2 then
    L2_2 = MrxGuiHudActionHijack
    L2_2 = L2_2.HideButton
    L3_2 = A0_2._hijackerPlayer
    L2_2(L3_2)
    L2_2 = MrxGuiManager
    L2_2 = L2_2.ToggleHud
    L3_2 = A0_2._hijackerPlayer
    L4_2 = true
    L2_2(L3_2, L4_2)
  else
    L2_2 = MrxGuiHudActionHijack
    L2_2 = L2_2.ShowFail
    L3_2 = A0_2._hijackerPlayer
    L2_2(L3_2)
    L2_2 = MrxGuiManager
    L2_2 = L2_2.ToggleHud
    L3_2 = A0_2._hijackerPlayer
    L4_2 = true
    L2_2(L3_2, L4_2)
  end
  L2_2 = Event
  L2_2 = L2_2.Delete
  L3_2 = A0_2.tEvent
  L3_2 = L3_2._eMinigame
  L2_2(L3_2)
  L2_2 = A0_2.tEvent
  L2_2._eMinigame = nil
  L2_2 = OnRagdollDone
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

OnRagdollMinigameDone = L4_1

function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = Object
  L2_2 = L2_2.SetInvincible
  L3_2 = A0_2._hijacker
  L4_2 = false
  L5_2 = "Hijack"
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = Object
  L2_2 = L2_2.SetInvincible
  L3_2 = A0_2._hijackee
  L4_2 = false
  L5_2 = "Hijack"
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = Object
  L2_2 = L2_2.SetInvincible
  L3_2 = A0_2._vehicle
  L4_2 = false
  L5_2 = "Hijack"
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = Player
  L2_2 = L2_2.SetCinematicMode
  L3_2 = Object
  L3_2 = L3_2.IsPlayerControlled
  L4_2 = A0_2._hijacker
  L3_2 = L3_2(L4_2)
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = A0_2._bTankCleanup
  if L2_2 == true then
    L2_2 = Vehicle
    L2_2 = L2_2.StopTankHijackMotion
    L3_2 = A0_2._vehicle
    L2_2(L3_2)
    L2_2 = Object
    L2_2 = L2_2.SetVisible
    L3_2 = A0_2._hijackee
    L4_2 = false
    L2_2(L3_2, L4_2)
    L2_2 = Vehicle
    L2_2 = L2_2.EnableTurret
    L3_2 = A0_2._vehicle
    L4_2 = "main_turret"
    L5_2 = true
    L2_2(L3_2, L4_2, L5_2)
  end
  L2_2 = type
  L3_2 = A0_2._OnActionHijackComplete
  L2_2 = L2_2(L3_2)
  if L2_2 == "function" then
    L2_2 = A0_2._OnActionHijackComplete
    L3_2 = A0_2
    L2_2(L3_2)
  end
  L2_2 = Vehicle
  L2_2 = L2_2.HijackAbortDone
  if L2_2 then
    L2_2 = Vehicle
    L2_2 = L2_2.HijackAbortDone
    L3_2 = A0_2._hijacker
    L2_2(L3_2)
  end
  L2_2 = Human
  L2_2 = L2_2.SetState
  L3_2 = A0_2._hijackee
  L4_2 = "InVehicle"
  L5_2 = "Idle"
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = Ai
  L2_2 = L2_2.Enable
  L3_2 = A0_2._hijackee
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = {}
  A0_2.tAnimation = L2_2
  A0_2 = nil
end

OnRagdollDone = L4_1

function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.IsInterpolating
  L1_2 = L1_2()
  L1_2 = not L1_2
  bSafeToBegin = L1_2
  L1_2 = bSafeToBegin
  if L1_2 then
    if A0_2 then
      L1_2 = Graphics
      L1_2 = L1_2.Atmosphere
      L1_2 = L1_2.Begin
      L1_2()
      L1_2 = Graphics
      L1_2 = L1_2.Atmosphere
      L1_2 = L1_2.GetValue
      L2_2 = "fBloomTargetLuminance"
      L1_2 = L1_2(L2_2)
      vBloomTargetLuminance = L1_2
      L1_2 = Graphics
      L1_2 = L1_2.Atmosphere
      L1_2 = L1_2.GetValue
      L2_2 = "fBloomContastLimit"
      L1_2 = L1_2(L2_2)
      vBloomContrastLimit = L1_2
      L1_2 = Graphics
      L1_2 = L1_2.Atmosphere
      L1_2 = L1_2.GetValue
      L2_2 = "fBloomContastMultiplier"
      L1_2 = L1_2(L2_2)
      vBloomContrastMultiplier = L1_2
      L1_2 = Graphics
      L1_2 = L1_2.Atmosphere
      L1_2 = L1_2.SetValue
      L2_2 = "fBloomContastLimit"
      L3_2 = 0.125
      L1_2(L2_2, L3_2)
      L1_2 = Graphics
      L1_2 = L1_2.Atmosphere
      L1_2 = L1_2.SetValue
      L2_2 = "fBloomContastMultiplier"
      L3_2 = 1.5
      L1_2(L2_2, L3_2)
      L1_2 = Graphics
      L1_2 = L1_2.Atmosphere
      L1_2 = L1_2.End
      L2_2 = 0.45
      L1_2(L2_2)
      L1_2 = false
      bNeedAtmosphereChange = L1_2
    else
      L1_2 = Graphics
      L1_2 = L1_2.Atmosphere
      L1_2 = L1_2.Begin
      L1_2()
      L1_2 = Graphics
      L1_2 = L1_2.Atmosphere
      L1_2 = L1_2.SetValue
      L2_2 = "fBloomTargetLuminance"
      L3_2 = vBloomTargetLuminance
      L1_2(L2_2, L3_2)
      L1_2 = Graphics
      L1_2 = L1_2.Atmosphere
      L1_2 = L1_2.SetValue
      L2_2 = "fBloomContastLimit"
      L3_2 = vBloomContrastLimit
      L1_2(L2_2, L3_2)
      L1_2 = Graphics
      L1_2 = L1_2.Atmosphere
      L1_2 = L1_2.SetValue
      L2_2 = "fBloomContastMultiplier"
      L3_2 = vBloomContrastMultiplier
      L1_2(L2_2, L3_2)
      L1_2 = Graphics
      L1_2 = L1_2.Atmosphere
      L1_2 = L1_2.End
      L2_2 = 1.5
      L1_2(L2_2)
      L1_2 = false
      bNeedAtmosphereChange = L1_2
    end
  elseif A0_2 then
    L1_2 = bNeedAtmosphereChange
    if L1_2 then
      L1_2 = Event
      L1_2 = L1_2.Create
      L2_2 = Event
      L2_2 = L2_2.TimerRelative
      L3_2 = {}
      L4_2 = 1
      L3_2[1] = L4_2
      L4_2 = ChangeAtmosphere
      L5_2 = {}
      L6_2 = A0_2
      L5_2[1] = L6_2
      L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
      eventHandle = L1_2
    end
  end
  if not A0_2 then
    L1_2 = false
    bNeedAtmosphereChange = L1_2
    L1_2 = eventHandle
    if L1_2 then
      L1_2 = Event
      L1_2 = L1_2.Delete
      L2_2 = eventHandle
      L1_2(L2_2)
    end
    L1_2 = nil
    eventHandle = L1_2
  end
end

ChangeAtmosphere = L4_1

function L4_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2 = L1_2()
  L2_2 = A0_2._hijacker
  if L1_2 == L2_2 then
    L1_2 = ChangeAtmosphere
    L2_2 = false
    L1_2(L2_2)
    L1_2 = Graphics
    L1_2 = L1_2.Camera
    L1_2 = L1_2.RestoreFocusParams
    L2_2 = 0
    L3_2 = 0.6
    L1_2(L2_2, L3_2)
    L1_2 = Graphics
    L1_2 = L1_2.Effect
    L1_2 = L1_2.CameraFade
    L2_2 = 1
    L1_2(L2_2)
  end
end

RestoreCamera = L4_1

function L4_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Animation
  L1_2 = L1_2.PlayFacialExpression
  L2_2 = A0_2._hijackee
  L3_2 = "DisableAll"
  L1_2(L2_2, L3_2)
  L1_2 = Animation
  L1_2 = L1_2.PlayFacialExpression
  L2_2 = A0_2._hijacker
  L3_2 = "DisableAll"
  L1_2(L2_2, L3_2)
  L1_2 = A0_2._ActorOne
  if L1_2 ~= nil then
    L1_2 = Animation
    L1_2 = L1_2.PlayFacialExpression
    L2_2 = A0_2._ActorOne
    L3_2 = "DisableAll"
    L1_2(L2_2, L3_2)
  end
  L1_2 = A0_2._ActorTwo
  if L1_2 ~= nil then
    L1_2 = Animation
    L1_2 = L1_2.PlayFacialExpression
    L2_2 = A0_2._ActorTwo
    L3_2 = "DisableAll"
    L1_2(L2_2, L3_2)
  end
  L1_2 = A0_2._bUsingCinematicMode
  if L1_2 then
    L1_2 = VO
    L1_2 = L1_2.SetCinematicMode
    L2_2 = false
    L1_2(L2_2)
  end
end

DisableFacialExpressions = L4_1

function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = RULESET_SOLANO
  if L2_2 == true then
  end
  L2_2 = DisableFacialExpressions
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = RULESET_SOLANO
  if L2_2 == true then
    L2_2 = Human
    L2_2 = L2_2.SetState
    L3_2 = A0_2._hijackee
    L4_2 = "InVehicle"
    L5_2 = "Idle"
    L2_2(L3_2, L4_2, L5_2)
  end
  if A1_2 == true then
    L2_2 = L3_1
    L2_2 = L2_2.nKnockdown2
    nKnockdownDuration = L2_2
    L2_2 = Hero
    L2_2 = L2_2.GetAttribute
    L3_2 = A0_2._hijacker
    L4_2 = "Attitude"
    L2_2 = L2_2(L3_2, L4_2)
    if 2 < L2_2 then
      L2_2 = L3_1
      L2_2 = L2_2.nKnockdown2
      nKnockdownDuration = L2_2
    end
    L2_2 = Human
    L2_2 = L2_2.Knockdown
    L3_2 = A0_2._hijacker
    L4_2 = nKnockdownDuration
    L2_2(L3_2, L4_2)
  end
  L2_2 = Vehicle
  L2_2 = L2_2.HijackAbort
  L3_2 = A0_2._hijacker
  L2_2(L3_2)
  L2_2 = Ai
  L2_2 = L2_2.Enable
  L3_2 = A0_2._hijackee
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = RULESET_SOLANO
  if L2_2 == true then
    L2_2 = nil
    RULESET_SOLANO = L2_2
  end
end

CleanupCommonNonSuccess = L4_1

function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2._hijacker
  uHijacker = L2_2
  L2_2 = A0_2._hijackee
  uHijackee = L2_2
  L2_2 = A0_2._vehicle
  uVehicle = L2_2
  L2_2 = Object
  L2_2 = L2_2.SetInvincible
  L3_2 = A0_2._hijacker
  L4_2 = false
  L5_2 = "Hijack"
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = Object
  L2_2 = L2_2.SetInvincible
  L3_2 = A0_2._hijackee
  L4_2 = false
  L5_2 = "Hijack"
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = Object
  L2_2 = L2_2.SetInvincible
  L3_2 = A0_2._vehicle
  L4_2 = false
  L5_2 = "Hijack"
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = DisableFacialExpressions
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = RestoreCamera
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = MrxGuiHudActionHijack
  L2_2 = L2_2.HideButton
  L3_2 = A0_2._hijackerPlayer
  L2_2(L3_2)
  L2_2 = MrxGuiManager
  L2_2 = L2_2.ToggleHud
  L3_2 = A0_2._hijackerPlayer
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = Vehicle
  L2_2 = L2_2.EnableTurret
  L3_2 = A0_2._hijackee
  L4_2 = "head"
  L5_2 = true
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = A0_2._bTankCleanup
  if L2_2 == true then
    L2_2 = Vehicle
    L2_2 = L2_2.StopTankHijackMotion
    L3_2 = A0_2._vehicle
    L2_2(L3_2)
    L2_2 = Vehicle
    L2_2 = L2_2.EnableTurret
    L3_2 = A0_2._vehicle
    L4_2 = "main_turret"
    L5_2 = true
    L2_2(L3_2, L4_2, L5_2)
  end
  L2_2 = A0_2._vehicle
  if L2_2 then
    L2_2 = Object
    L2_2 = L2_2.StopAnimationChannel
    L3_2 = A0_2._vehicle
    L4_2 = "hijack"
    L2_2(L3_2, L4_2)
  end
  if A1_2 == true then
    L2_2 = Vehicle
    L2_2 = L2_2.HijackComplete
    L3_2 = A0_2._hijacker
    L2_2(L3_2)
    L2_2 = type
    L3_2 = A0_2._OnActionHijackComplete
    L2_2 = L2_2(L3_2)
    if L2_2 == "function" then
      L2_2 = A0_2._OnActionHijackComplete
      L3_2 = A0_2
      L2_2(L3_2)
    end
  end
  A0_2 = nil
  L2_2 = ActionHijackFinish
  L3_2 = uHijacker
  L4_2 = uHijackee
  L5_2 = uVehicle
  L6_2 = A1_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
end

CompleteHijackNonFailure = L4_1

function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = A0_2._hijackerPlayer
  L2_2 = Player
  L2_2 = L2_2.GetLocalPlayer
  L2_2 = L2_2()
  if L1_2 == L2_2 then
    L1_2 = MrxSound
    L1_2 = L1_2.EndActionHijack
    L2_2 = RULESET_SOLANO
    L2_2 = not L2_2
    L3_2 = false
    L1_2(L2_2, L3_2)
  end
  L1_2 = Player
  L1_2 = L1_2.SetCinematicMode
  L2_2 = Object
  L2_2 = L2_2.IsPlayerControlled
  L3_2 = A0_2._hijacker
  L2_2 = L2_2(L3_2)
  L3_2 = false
  L1_2(L2_2, L3_2)
  L1_2 = DeleteAllEvents
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = RULESET_SOLANO
  if L1_2 == true then
    L1_2 = A0_2.CancelContract
    if L1_2 then
      L1_2 = A0_2.CancelContract
      L1_2()
    end
  end
  L1_2 = CleanupCommonNonSuccess
  L2_2 = A0_2
  L3_2 = false
  L1_2(L2_2, L3_2)
  L1_2 = Human
  L1_2 = L1_2.SetState
  L2_2 = A0_2._hijacker
  L3_2 = "Upright"
  L4_2 = "Idle"
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Object
  L1_2 = L1_2.EnablePhysics
  L2_2 = A0_2._hijacker
  L1_2(L2_2)
  L1_2 = Vehicle
  L1_2 = L1_2.HijackAbortDone
  L2_2 = A0_2._hijacker
  L1_2(L2_2)
  L1_2 = CompleteHijackNonFailure
  L2_2 = A0_2
  L3_2 = false
  L1_2(L2_2, L3_2)
end

ActionHijackCancel = L4_1

function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2 = L1_2()
  L2_2 = A0_2._hijacker
  if L1_2 == L2_2 then
    L1_2 = MrxAchievements
    L1_2 = L1_2.AchievementAddCount
    L2_2 = "ACHIEVEMENT_HEAVY_METAL_THUNDER"
    L3_2 = 1
    L4_2 = Player
    L4_2 = L4_2.GetLocalPlayer
    L4_2 = L4_2()
    L1_2(L2_2, L3_2, L4_2)
  end
  L1_2 = CompleteHijackNonFailure
  L2_2 = A0_2
  L3_2 = A0_2.nCurrent
  L3_2 = A0_2[L3_2]
  L3_2 = L3_2.bSuccess
  L1_2(L2_2, L3_2)
end

ActionHijackComplete = L4_1

function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = Ai
  L2_2 = L2_2.Enable
  L3_2 = A0_2._hijackee
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = A0_2.nCurrent
  L2_2 = A0_2[L2_2]
  L2_2 = L2_2.bDriverDoneRagdoll
  if L2_2 then
    L1_2 = false
    L2_2 = Human
    L2_2 = L2_2.ForceExitSeatNoSnap
    if L2_2 then
      L1_2 = true
      L2_2 = Human
      L2_2 = L2_2.ForceExitSeatNoSnap
      L3_2 = A0_2._hijackee
      L2_2(L3_2)
    end
    L2_2 = Hero
    L2_2 = L2_2.GetAttribute
    L3_2 = A0_2._hijacker
    L4_2 = "Brawn"
    L2_2 = L2_2(L3_2, L4_2)
    if 2 < L2_2 then
      L2_2 = Human
      L2_2 = L2_2.Knockdown
      L3_2 = A0_2._hijackee
      L4_2 = L3_1
      L4_2 = L4_2.nKnockdown2
      L2_2(L3_2, L4_2)
    else
      L2_2 = Human
      L2_2 = L2_2.Knockdown
      L3_2 = A0_2._hijackee
      L4_2 = L3_1
      L4_2 = L4_2.nKnockdown3
      L2_2(L3_2, L4_2)
    end
  else
    L2_2 = A0_2.nCurrent
    L2_2 = A0_2[L2_2]
    L2_2 = L2_2.bDriverDoneStanding
    if L2_2 then
      L1_2 = false
      L2_2 = Human
      L2_2 = L2_2.ForceExitSeatNoSnap
      if L2_2 then
        L1_2 = true
        L2_2 = Human
        L2_2 = L2_2.ForceExitSeatNoSnap
        L3_2 = A0_2._hijackee
        L2_2(L3_2)
      end
    else
      L2_2 = A0_2.nCurrent
      L2_2 = A0_2[L2_2]
      L2_2 = L2_2.bDriverDoneDead
      if L2_2 then
        L2_2 = A0_2.nCurrent
        L2_2 = A0_2[L2_2]
        L2_2 = L2_2.bDriverDoneDead
        if L2_2 ~= true then
        end
        L2_2 = Human
        L2_2 = L2_2.ForceExitSeatNoSnap
        if L2_2 then
          L2_2 = Human
          L2_2 = L2_2.ForceExitSeatNoSnap
          L3_2 = A0_2._hijackee
          L2_2(L3_2)
        end
        L2_2 = Object
        L2_2 = L2_2.Kill
        L3_2 = A0_2._hijackee
        L2_2(L3_2)
      else
        L2_2 = A0_2.nCurrent
        L2_2 = A0_2[L2_2]
        L2_2 = L2_2.bActorOneDoneDead
        if L2_2 then
          L2_2 = Human
          L2_2 = L2_2.ForceExitSeatNoSnap
          if L2_2 then
            L2_2 = Human
            L2_2 = L2_2.ForceExitSeatNoSnap
            L3_2 = A0_2._ActorOne
            L2_2(L3_2)
          end
          L2_2 = Object
          L2_2 = L2_2.Kill
          L3_2 = A0_2._ActorOne
          L2_2(L3_2)
        else
          L2_2 = A0_2.nCurrent
          L2_2 = A0_2[L2_2]
          L2_2 = L2_2.bActorTwoDoneDead
          if L2_2 then
            L2_2 = Human
            L2_2 = L2_2.ForceExitSeatNoSnap
            if L2_2 then
              L2_2 = Human
              L2_2 = L2_2.ForceExitSeatNoSnap
              L3_2 = A0_2._ActorTwo
              L2_2(L3_2)
            end
            L2_2 = Object
            L2_2 = L2_2.Kill
            L3_2 = A0_2._ActorTwo
            L2_2(L3_2)
          else
            L2_2 = A0_2.nCurrent
            L2_2 = A0_2[L2_2]
            L2_2 = L2_2.bDriverDoneRemove
            if L2_2 ~= true then
            end
            L2_2 = Object
            L2_2 = L2_2.Remove
            L3_2 = A0_2._hijackee
            L2_2(L3_2)
          end
        end
      end
    end
  end
end

OnDriverDone = L4_1

function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = pairs
  L2_2 = A0_2.tEvent
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Event
    L6_2 = L6_2.Delete
    L7_2 = L5_2
    L6_2(L7_2)
  end
  L1_2 = A0_2.nCurrent
  L1_2 = A0_2[L1_2]
  L1_2 = L1_2.tMultiEvents
  if L1_2 then
    L1_2 = A0_2.nCurrent
    L1_2 = A0_2[L1_2]
    L1_2 = L1_2.tMultiEvents
    L2_2 = ipairs
    L3_2 = L1_2
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2, L6_2 in L2_2, L3_2, L4_2 do
      L7_2 = L6_2._MultiEventTimer
      if L7_2 then
        L7_2 = Event
        L7_2 = L7_2.Delete
        L8_2 = L6_2._MultiEventTimer
        L7_2(L8_2)
        L6_2._MultiEventTimer = nil
      end
    end
  end
end

DeleteAllEvents = L4_1

function L4_1(A0_2)
  local L1_2
end

OnAnimationCompleteRemote = L4_1

function L4_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  if A1_2 == 0 then
    if A2_2 then
      L3_2 = A0_2.bDidSuccess
      if not L3_2 then
        A0_2.bDidSuccess = true
        L3_2 = DeleteAllEvents
        L4_2 = A0_2
        L3_2(L4_2)
        L3_2 = ActionHijackComplete
        L4_2 = A0_2
        L3_2(L4_2)
      end
    end
    if not A2_2 then
      L3_2 = A0_2.bDidFailure
      if not L3_2 then
        A0_2.bDidFailure = true
        L3_2 = RestoreCamera
        L4_2 = A0_2
        L3_2(L4_2)
        L3_2 = OnFailAnimationComplete
        L4_2 = A0_2
        L3_2(L4_2)
      end
    end
  elseif not A2_2 then
    L3_2 = A0_2.bDidFailure
    if not L3_2 then
      A0_2.bDidFailure = true
      L3_2 = DoFailureAnimation
      L4_2 = A0_2
      L3_2(L4_2)
    end
  else
    L3_2 = A0_2.nCurrent
    if A1_2 ~= L3_2 then
      L3_2 = DoSuccessAnimation
      L4_2 = A0_2
      L3_2(L4_2)
    end
  end
end

PushActionHijack = L4_1
