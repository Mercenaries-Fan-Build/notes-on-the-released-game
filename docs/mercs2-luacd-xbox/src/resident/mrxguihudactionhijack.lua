local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = "ui_HUD_Minigame_Press_Button"
_ksPressSound = L0_1
L0_1 = "ui_HUD_Minigame_Error"
_ksErrorSound = L0_1
L0_1 = "ui_HUD_Minigame_Tap_Button_lp"
_ksMashSound = L0_1
L0_1 = "ui_HUD_Minigame_Tap_Button_Recover_lp"
_ksRecoverSound = L0_1
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

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2, A9_2, A10_2, A11_2, A12_2, A13_2)
  local L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2
  L14_2 = type
  L15_2 = A0_2
  L14_2 = L14_2(L15_2)
  if "userdata" ~= L14_2 then
    return
  end
  L14_2 = _ControllerSpriteTextureMapping
  L14_2 = L14_2[A1_2]
  if L14_2 then
    L14_2 = _ControllerSpriteData
    L14_2 = L14_2[A1_2]
    if L14_2 then
      goto lbl_16
    end
  end
  do return end
  ::lbl_16::
  if not A3_2 then
    A3_2 = -1
  end
  L14_2 = MrxGui
  L14_2 = L14_2.GetWidgetByNameAndOwner
  L15_2 = "Action Hijack"
  L16_2 = A0_2
  L14_2 = L14_2(L15_2, L16_2)
  if not L14_2 then
    return
  end
  L15_2 = type
  L16_2 = A13_2
  L15_2 = L15_2(L16_2)
  if "number" ~= L15_2 then
    A13_2 = 1
  end
  L16_2 = L14_2
  L15_2 = L14_2.GetLocation
  L15_2, L16_2, L17_2, L18_2 = L15_2(L16_2)
  L19_2 = L14_2.CustomData
  L19_2 = L19_2.nOriginalWidth
  L19_2 = L19_2 * A13_2
  L19_2 = L19_2 * 0.5
  L20_2 = L14_2.CustomData
  L20_2 = L20_2.nOriginalHeight
  L20_2 = L20_2 * A13_2
  L20_2 = L20_2 * 0.5
  L21_2 = A4_2 or L21_2
  if not A4_2 then
    L21_2 = 0
  end
  L21_2 = L21_2 + 1
  A4_2 = L21_2 * 320
  L21_2 = A5_2 or L21_2
  if not A5_2 then
    L21_2 = 0
  end
  L21_2 = L21_2 + 1
  A5_2 = L21_2 * 190
  L22_2 = L14_2
  L21_2 = L14_2.SetLocation
  L23_2 = A4_2 - L19_2
  L24_2 = A5_2 - L20_2
  L25_2 = A4_2 + L19_2
  L26_2 = A5_2 + L20_2
  L21_2(L22_2, L23_2, L24_2, L25_2, L26_2)
  L22_2 = L14_2
  L21_2 = L14_2.SetTranslucency
  L23_2 = A6_2 or L23_2
  if not A6_2 then
    L23_2 = 190
  end
  L21_2(L22_2, L23_2)
  L21_2 = L14_2.CustomData
  L21_2 = L21_2.oButton
  L22_2 = L14_2.CustomData
  L22_2 = L22_2.oTimer
  L23_2 = L14_2.CustomData
  L23_2 = L23_2.oFail
  L25_2 = L21_2
  L24_2 = L21_2.SetTexture
  L26_2 = _ControllerSpriteTextureMapping
  L26_2 = L26_2[A1_2]
  L24_2(L25_2, L26_2)
  L25_2 = L21_2
  L24_2 = L21_2.SetTextureSize
  L26_2 = _ControllerSpriteData
  L26_2 = L26_2[A1_2]
  L26_2 = L26_2[5]
  L27_2 = _ControllerSpriteData
  L27_2 = L27_2[A1_2]
  L27_2 = L27_2[6]
  L24_2(L25_2, L26_2, L27_2)
  L25_2 = L14_2
  L24_2 = L14_2.GetLocation
  L24_2, L25_2, L26_2, L27_2 = L24_2(L25_2)
  L28_2 = A4_2
  L29_2 = A5_2
  L30_2 = 64 * A13_2
  L32_2 = L23_2
  L31_2 = L23_2.SetLocation
  L33_2 = L24_2
  L34_2 = L25_2
  L35_2 = L26_2
  L36_2 = L27_2
  L31_2(L32_2, L33_2, L34_2, L35_2, L36_2)
  L32_2 = L22_2
  L31_2 = L22_2.SetLocation
  L33_2 = L28_2 - L30_2
  L34_2 = L29_2 - L30_2
  L35_2 = L28_2 + L30_2
  L36_2 = L29_2 + L30_2
  L31_2(L32_2, L33_2, L34_2, L35_2, L36_2)
  L32_2 = L21_2
  L31_2 = L21_2.SetLocation
  L33_2 = _ControllerSpriteData
  L33_2 = L33_2[A1_2]
  L33_2 = L33_2[1]
  L33_2 = L33_2 / 2
  L33_2 = L33_2 * A13_2
  L33_2 = L28_2 - L33_2
  L34_2 = _ControllerSpriteData
  L34_2 = L34_2[A1_2]
  L34_2 = L34_2[4]
  L34_2 = L34_2 * A13_2
  L34_2 = L25_2 + L34_2
  L35_2 = _ControllerSpriteData
  L35_2 = L35_2[A1_2]
  L35_2 = L35_2[1]
  L35_2 = L35_2 / 2
  L35_2 = L35_2 * A13_2
  L35_2 = L28_2 + L35_2
  L36_2 = _ControllerSpriteData
  L36_2 = L36_2[A1_2]
  L36_2 = L36_2[4]
  L37_2 = _ControllerSpriteData
  L37_2 = L37_2[A1_2]
  L37_2 = L37_2[2]
  L36_2 = L36_2 + L37_2
  L36_2 = L36_2 * A13_2
  L36_2 = L25_2 + L36_2
  L31_2(L32_2, L33_2, L34_2, L35_2, L36_2)
  L32_2 = L21_2
  L31_2 = L21_2.SetFrameSize
  L33_2 = _ControllerSpriteData
  L33_2 = L33_2[A1_2]
  L33_2 = L33_2[1]
  L34_2 = _ControllerSpriteData
  L34_2 = L34_2[A1_2]
  L34_2 = L34_2[2]
  L31_2(L32_2, L33_2, L34_2)
  if A7_2 then
    L31_2 = L14_2.CustomData
    L31_2 = L31_2.oSparkL
    L32_2 = L14_2.CustomData
    L32_2 = L32_2.oSparkR
    L34_2 = L31_2
    L33_2 = L31_2.SetVisible
    L35_2 = true
    L33_2(L34_2, L35_2)
    L34_2 = L32_2
    L33_2 = L32_2.SetVisible
    L35_2 = true
    L33_2(L34_2, L35_2)
    L34_2 = L31_2
    L33_2 = L31_2.PlayAnimation
    L35_2 = 0
    L36_2 = 2
    L37_2 = 0.25
    L38_2 = true
    L33_2(L34_2, L35_2, L36_2, L37_2, L38_2)
    L34_2 = L32_2
    L33_2 = L32_2.PlayAnimation
    L35_2 = 0
    L36_2 = 2
    L37_2 = 0.25
    L38_2 = true
    L33_2(L34_2, L35_2, L36_2, L37_2, L38_2)
  else
    L31_2 = L14_2.CustomData
    L31_2 = L31_2.oSparkL
    L32_2 = L14_2.CustomData
    L32_2 = L32_2.oSparkR
    L34_2 = L31_2
    L33_2 = L31_2.SetVisible
    L35_2 = false
    L33_2(L34_2, L35_2)
    L34_2 = L32_2
    L33_2 = L32_2.SetVisible
    L35_2 = false
    L33_2(L34_2, L35_2)
  end
  if nil == A9_2 then
    A9_2 = false
  end
  if nil == A10_2 then
    A10_2 = true
  end
  L31_2 = 1
  L32_2 = Joystick
  L32_2 = L32_2.BUTTON_L_STICK_L
  if A1_2 >= L32_2 then
    L32_2 = Joystick
    L32_2 = L32_2.BUTTON_R_STICK_D
    if A1_2 <= L32_2 then
      L31_2 = 2
    end
  end
  L33_2 = L21_2
  L32_2 = L21_2.SetFrame
  L34_2 = 0
  L32_2(L33_2, L34_2)
  if 0 < A3_2 then
    L33_2 = L21_2
    L32_2 = L21_2.PlayAnimation
    L34_2 = 0
    L35_2 = L31_2
    L36_2 = A3_2
    L37_2 = true
    L32_2(L33_2, L34_2, L35_2, L36_2, L37_2)
  else
    L33_2 = L21_2
    L32_2 = L21_2.SetFrame
    L34_2 = L31_2
    L32_2(L33_2, L34_2)
    L33_2 = L21_2
    L32_2 = L21_2.HaltAnimation
    L32_2(L33_2)
  end
  L33_2 = L21_2
  L32_2 = L21_2.SetVisible
  L34_2 = true
  L32_2(L33_2, L34_2)
  L32_2 = L14_2.CustomData
  L32_2 = L32_2.oFail
  L33_2 = L32_2
  L32_2 = L32_2.SetVisible
  L34_2 = false
  L32_2(L33_2, L34_2)
  if nil == A12_2 then
    A12_2 = true
  end
  if A12_2 then
    L33_2 = L22_2
    L32_2 = L22_2.SetTexture
    L34_2 = "countdown_circle"
    L32_2(L33_2, L34_2)
    L33_2 = L22_2
    L32_2 = L22_2.SetClockAnimation
    L34_2 = A8_2 or L34_2
    if not A8_2 then
      L34_2 = 0
    end
    L35_2 = A2_2
    L36_2 = A9_2
    L37_2 = A10_2
    L32_2(L33_2, L34_2, L35_2, L36_2, L37_2)
  else
    L33_2 = L22_2
    L32_2 = L22_2.SetTexture
    L34_2 = "icon_hijack_glow"
    L32_2(L33_2, L34_2)
    L33_2 = L22_2
    L32_2 = L22_2.SetClockAnimation
    L34_2 = 1
    L35_2 = 1
    L36_2 = true
    L37_2 = A10_2
    L32_2(L33_2, L34_2, L35_2, L36_2, L37_2)
  end
  L33_2 = L22_2
  L32_2 = L22_2.SetVisible
  L34_2 = true
  L32_2(L33_2, L34_2)
  if A11_2 then
    L32_2 = L14_2.CustomData
    L32_2 = L32_2.bRecoverSoundLooping
    if not L32_2 then
      L32_2 = L14_2.CustomData
      L32_2 = L32_2.bSoundLooping
      if L32_2 then
        L32_2 = L14_2.CustomData
        L32_2.bSoundLooping = false
        L32_2 = Sound
        L32_2 = L32_2.StopSound
        L33_2 = 0
        L34_2 = _ksMashSound
        L32_2(L33_2, L34_2)
      end
      L32_2 = Sound
      L32_2 = L32_2.CueSound
      L33_2 = 0
      L34_2 = _ksRecoverSound
      L32_2(L33_2, L34_2)
      L32_2 = L14_2.CustomData
      L32_2.bRecoverSoundLooping = true
    end
  else
    if A7_2 then
      L32_2 = L14_2.CustomData
      L32_2 = L32_2.bSoundLooping
      if not L32_2 then
        L32_2 = L14_2.CustomData
        L32_2 = L32_2.bRecoverSoundLooping
        if L32_2 then
          L32_2 = L14_2.CustomData
          L32_2.bRecoverSoundLooping = false
          L32_2 = Sound
          L32_2 = L32_2.StopSound
          L33_2 = 0
          L34_2 = _ksRecoverSound
          L32_2(L33_2, L34_2)
        end
        L32_2 = Sound
        L32_2 = L32_2.CueSound
        L33_2 = 0
        L34_2 = _ksMashSound
        L32_2(L33_2, L34_2)
        L32_2 = L14_2.CustomData
        L32_2.bSoundLooping = true
    end
    else
      L32_2 = Sound
      L32_2 = L32_2.CueSound
      L33_2 = 0
      L34_2 = _ksPressSound
      L32_2(L33_2, L34_2)
    end
  end
end

ShowButton = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "userdata" ~= L1_2 then
    return
  end
  L1_2 = MrxGui
  L1_2 = L1_2.GetWidgetByNameAndOwner
  L2_2 = "Action Hijack"
  L3_2 = A0_2
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 then
    L3_2 = L1_2
    L2_2 = L1_2.SetVisible
    L4_2 = false
    L2_2(L3_2, L4_2)
    L2_2 = L1_2.CustomData
    L2_2 = L2_2.oButton
    L3_2 = L2_2
    L2_2 = L2_2.HaltAnimation
    L2_2(L3_2)
    L2_2 = L1_2.CustomData
    L2_2 = L2_2.oSparkL
    L3_2 = L2_2
    L2_2 = L2_2.HaltAnimation
    L2_2(L3_2)
    L2_2 = L1_2.CustomData
    L2_2 = L2_2.oSparkR
    L3_2 = L2_2
    L2_2 = L2_2.HaltAnimation
    L2_2(L3_2)
    L2_2 = L1_2.CustomData
    L2_2 = L2_2.bSoundLooping
    if L2_2 then
      L2_2 = L1_2.CustomData
      L2_2.bSoundLooping = false
      L2_2 = Sound
      L2_2 = L2_2.StopSound
      L3_2 = 0
      L4_2 = _ksMashSound
      L2_2(L3_2, L4_2)
    end
    L2_2 = L1_2.CustomData
    L2_2 = L2_2.bRecoverSoundLooping
    if L2_2 then
      L2_2 = L1_2.CustomData
      L2_2.bRecoverSoundLooping = false
      L2_2 = Sound
      L2_2 = L2_2.StopSound
      L3_2 = 0
      L4_2 = _ksRecoverSound
      L2_2(L3_2, L4_2)
    end
  end
end

HideButton = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "userdata" ~= L2_2 then
    return
  end
  L2_2 = MrxGui
  L2_2 = L2_2.GetWidgetByNameAndOwner
  L3_2 = "Action Hijack"
  L4_2 = A0_2
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    L4_2 = L2_2
    L3_2 = L2_2.SetVisible
    L5_2 = false
    L3_2(L4_2, L5_2)
    L3_2 = L2_2.CustomData
    L3_2 = L3_2.oButton
    L4_2 = L3_2
    L3_2 = L3_2.HaltAnimation
    L3_2(L4_2)
    L3_2 = L2_2.CustomData
    L3_2 = L3_2.oSparkL
    L4_2 = L3_2
    L3_2 = L3_2.HaltAnimation
    L3_2(L4_2)
    L3_2 = L2_2.CustomData
    L3_2 = L3_2.oSparkR
    L4_2 = L3_2
    L3_2 = L3_2.HaltAnimation
    L3_2(L4_2)
    if not A1_2 then
      A1_2 = 0.5
    end
    L3_2 = L2_2.CustomData
    L3_2 = L3_2.oFail
    L5_2 = L3_2
    L4_2 = L3_2.SetVisible
    L6_2 = true
    L4_2(L5_2, L6_2)
    L5_2 = L3_2
    L4_2 = L3_2.AnimateToPoint
    L6_2 = L3_2.CustomData
    L6_2 = L6_2.nStartPoint
    L7_2 = 0
    L8_2 = true
    L4_2(L5_2, L6_2, L7_2, L8_2)
    L5_2 = L3_2
    L4_2 = L3_2.AnimateToPoint
    L6_2 = L3_2.CustomData
    L6_2 = L6_2.nEndPoint
    L7_2 = A1_2
    L8_2 = false
    L9_2 = L3_2.SetVisible
    L10_2 = {}
    L11_2 = false
    L10_2[1] = L11_2
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
    L4_2 = Sound
    L4_2 = L4_2.CueSound
    L5_2 = 0
    L6_2 = _ksErrorSound
    L4_2(L5_2, L6_2)
    L4_2 = L2_2.CustomData
    L4_2 = L4_2.bSoundLooping
    if L4_2 then
      L4_2 = Sound
      L4_2 = L4_2.StopSound
      L5_2 = 0
      L6_2 = _ksMashSound
      L4_2(L5_2, L6_2)
      L4_2 = L2_2.CustomData
      L4_2.bSoundLooping = false
    end
    L4_2 = L2_2.CustomData
    L4_2 = L4_2.bRecoverSoundLooping
    if L4_2 then
      L4_2 = L2_2.CustomData
      L4_2.bRecoverSoundLooping = false
      L4_2 = Sound
      L4_2 = L4_2.StopSound
      L5_2 = 0
      L6_2 = _ksRecoverSound
      L4_2(L5_2, L6_2)
    end
  end
end

ShowFail = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "userdata" ~= L1_2 then
    L1_2 = nil
    return L1_2
  end
  L1_2 = MrxGui
  L1_2 = L1_2.GetWidgetByNameAndOwner
  L2_2 = "Action Hijack"
  L3_2 = A0_2
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 then
    L2_2 = L1_2.CustomData
    L2_2 = L2_2.oTimer
    L3_2 = L2_2
    L2_2 = L2_2.GetClockElapsedTime
    return L2_2(L3_2)
  end
  L2_2 = nil
  return L2_2
end

GetElapsedTime = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "userdata" ~= L2_2 then
    return
  end
  L2_2 = MrxGui
  L2_2 = L2_2.GetWidgetByNameAndOwner
  L3_2 = "Action Hijack"
  L4_2 = A0_2
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    L4_2 = L2_2
    L3_2 = L2_2.SetVisible
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
    L3_2 = L2_2.CustomData
    L3_2 = L3_2.oButton
    L4_2 = L3_2
    L3_2 = L3_2.HaltAnimation
    L3_2(L4_2)
    L3_2 = L2_2.CustomData
    L3_2 = L3_2.oSparkL
    L4_2 = L3_2
    L3_2 = L3_2.HaltAnimation
    L3_2(L4_2)
    L3_2 = L2_2.CustomData
    L3_2 = L3_2.oSparkR
    L4_2 = L3_2
    L3_2 = L3_2.HaltAnimation
    L3_2(L4_2)
    L3_2 = L2_2.CustomData
    L3_2 = L3_2.oTimer
    L4_2 = L3_2
    L3_2 = L3_2.SetVisible
    L5_2 = false
    L3_2(L4_2, L5_2)
    L3_2 = L2_2.CustomData
    L3_2 = L3_2.oButton
    L4_2 = L3_2
    L3_2 = L3_2.SetVisible
    L5_2 = false
    L3_2(L4_2, L5_2)
  end
end

SetDisplayVisible = L0_1

function L0_1()
  local L0_2, L1_2
end

SetDisplayButton = L0_1

function L0_1()
  local L0_2, L1_2
end

SetDisplayMashAnimation = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L2_2 = A0_2
  L1_2 = A0_2.GetLocation
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  L5_2 = L1_2 + L3_2
  L5_2 = L5_2 / 2
  L6_2 = L2_2 + L4_2
  L6_2 = L6_2 / 2
  L7_2 = A0_2.CustomData
  L8_2 = L3_2 - L1_2
  L7_2.nOriginalWidth = L8_2
  L7_2 = A0_2.CustomData
  L8_2 = L4_2 - L2_2
  L7_2.nOriginalHeight = L8_2
  L7_2 = MrxGui
  L7_2 = L7_2.ImageWidget
  L8_2 = L7_2
  L7_2 = L7_2.new
  L7_2 = L7_2(L8_2)
  L9_2 = L7_2
  L8_2 = L7_2.SetTexture
  L10_2 = "countdown_circle"
  L8_2(L9_2, L10_2)
  L9_2 = L7_2
  L8_2 = L7_2.SetLocation
  L10_2 = L5_2 - 64
  L11_2 = L6_2 - 64
  L12_2 = L5_2 + 64
  L13_2 = L6_2 + 64
  L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  L9_2 = L7_2
  L8_2 = L7_2.SetVisible
  L10_2 = false
  L8_2(L9_2, L10_2)
  L9_2 = L7_2
  L8_2 = L7_2.SetOwner
  L11_2 = A0_2
  L10_2 = A0_2.GetOwner
  L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2 = L10_2(L11_2)
  L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  L9_2 = L7_2
  L8_2 = L7_2.SetAnchoring
  L10_2 = "center"
  L11_2 = "center"
  L8_2(L9_2, L10_2, L11_2)
  L8_2 = MrxGui
  L8_2 = L8_2.AddWidget
  L9_2 = L7_2
  L8_2(L9_2)
  L9_2 = A0_2
  L8_2 = A0_2.AddChild
  L10_2 = L7_2
  L8_2(L9_2, L10_2)
  L8_2 = A0_2.CustomData
  L8_2.oTimer = L7_2
  L8_2 = MrxGui
  L8_2 = L8_2.SpriteWidget
  L9_2 = L8_2
  L8_2 = L8_2.new
  L8_2 = L8_2(L9_2)
  L10_2 = L8_2
  L9_2 = L8_2.SetTextureSize
  L11_2 = 128
  L12_2 = 128
  L9_2(L10_2, L11_2, L12_2)
  L10_2 = L8_2
  L9_2 = L8_2.SetFrameSize
  L11_2 = 128
  L12_2 = 64
  L9_2(L10_2, L11_2, L12_2)
  L10_2 = L8_2
  L9_2 = L8_2.SetLocation
  L11_2 = L5_2 - 49.5
  L12_2 = L6_2 - 42.5
  L13_2 = L5_2 + 49.5
  L14_2 = L6_2 + 42.5
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
  L10_2 = L8_2
  L9_2 = L8_2.SetVisible
  L11_2 = false
  L9_2(L10_2, L11_2)
  L10_2 = L8_2
  L9_2 = L8_2.SetOwner
  L12_2 = A0_2
  L11_2 = A0_2.GetOwner
  L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2 = L11_2(L12_2)
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  L10_2 = L8_2
  L9_2 = L8_2.SetAnchoring
  L11_2 = "center"
  L12_2 = "center"
  L9_2(L10_2, L11_2, L12_2)
  L9_2 = MrxGui
  L9_2 = L9_2.AddWidget
  L10_2 = L8_2
  L9_2(L10_2)
  L10_2 = A0_2
  L9_2 = A0_2.AddChild
  L11_2 = L8_2
  L9_2(L10_2, L11_2)
  L9_2 = A0_2.CustomData
  L9_2.oButton = L8_2
  L9_2 = MrxGui
  L9_2 = L9_2.ImageWidget
  L10_2 = L9_2
  L9_2 = L9_2.new
  L9_2 = L9_2(L10_2)
  L11_2 = L9_2
  L10_2 = L9_2.SetLocation
  L12_2 = L5_2 - 64
  L13_2 = L6_2 - 64
  L14_2 = L5_2 + 64
  L15_2 = L6_2 + 64
  L10_2(L11_2, L12_2, L13_2, L14_2, L15_2)
  L11_2 = L9_2
  L10_2 = L9_2.SetTexture
  L12_2 = "icon_fail"
  L10_2(L11_2, L12_2)
  L11_2 = L9_2
  L10_2 = L9_2.SetOwner
  L13_2 = A0_2
  L12_2 = A0_2.GetOwner
  L12_2, L13_2, L14_2, L15_2, L16_2, L17_2 = L12_2(L13_2)
  L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  L11_2 = L9_2
  L10_2 = L9_2.SetVisible
  L12_2 = false
  L10_2(L11_2, L12_2)
  L10_2 = L9_2.CustomData
  L12_2 = L9_2
  L11_2 = L9_2.AddAnimationPoint
  L13_2 = {}
  L13_2.TranslucencyLevel = 255
  L11_2 = L11_2(L12_2, L13_2)
  L10_2.nStartPoint = L11_2
  L10_2 = L9_2.CustomData
  L12_2 = L9_2
  L11_2 = L9_2.AddAnimationPoint
  L13_2 = {}
  L13_2.TranslucencyLevel = 0
  L11_2 = L11_2(L12_2, L13_2)
  L10_2.nEndPoint = L11_2
  L11_2 = L9_2
  L10_2 = L9_2.SetAnchoring
  L12_2 = "center"
  L13_2 = "center"
  L10_2(L11_2, L12_2, L13_2)
  L10_2 = MrxGui
  L10_2 = L10_2.AddWidget
  L11_2 = L9_2
  L10_2(L11_2)
  L11_2 = A0_2
  L10_2 = A0_2.AddChild
  L12_2 = L9_2
  L10_2(L11_2, L12_2)
  L10_2 = A0_2.CustomData
  L10_2.oFail = L9_2
  L10_2 = MrxGui
  L10_2 = L10_2.SpriteWidget
  L11_2 = L10_2
  L10_2 = L10_2.new
  L10_2 = L10_2(L11_2)
  L12_2 = L10_2
  L11_2 = L10_2.SetTexture
  L13_2 = "icon_sparks_left"
  L11_2(L12_2, L13_2)
  L12_2 = L10_2
  L11_2 = L10_2.SetTextureSize
  L13_2 = 128
  L14_2 = 128
  L11_2(L12_2, L13_2, L14_2)
  L12_2 = L10_2
  L11_2 = L10_2.SetFrameSize
  L13_2 = 64
  L14_2 = 64
  L11_2(L12_2, L13_2, L14_2)
  L12_2 = L10_2
  L11_2 = L10_2.SetVisible
  L13_2 = false
  L11_2(L12_2, L13_2)
  L12_2 = L10_2
  L11_2 = L10_2.SetLocation
  L13_2 = L5_2 - 64
  L14_2 = L6_2 - 24
  L15_2 = L5_2 - 16
  L16_2 = L6_2 + 24
  L11_2(L12_2, L13_2, L14_2, L15_2, L16_2)
  L12_2 = L10_2
  L11_2 = L10_2.SetOwner
  L14_2 = A0_2
  L13_2 = A0_2.GetOwner
  L13_2, L14_2, L15_2, L16_2, L17_2 = L13_2(L14_2)
  L11_2(L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  L12_2 = L10_2
  L11_2 = L10_2.SetAnchoring
  L13_2 = "center"
  L14_2 = "center"
  L11_2(L12_2, L13_2, L14_2)
  L11_2 = MrxGui
  L11_2 = L11_2.AddWidget
  L12_2 = L10_2
  L11_2(L12_2)
  L12_2 = A0_2
  L11_2 = A0_2.AddChild
  L13_2 = L10_2
  L11_2(L12_2, L13_2)
  L11_2 = A0_2.CustomData
  L11_2.oSparkL = L10_2
  L11_2 = MrxGui
  L11_2 = L11_2.SpriteWidget
  L12_2 = L11_2
  L11_2 = L11_2.new
  L11_2 = L11_2(L12_2)
  L13_2 = L11_2
  L12_2 = L11_2.SetTexture
  L14_2 = "icon_sparks_right"
  L12_2(L13_2, L14_2)
  L13_2 = L11_2
  L12_2 = L11_2.SetTextureSize
  L14_2 = 128
  L15_2 = 128
  L12_2(L13_2, L14_2, L15_2)
  L13_2 = L11_2
  L12_2 = L11_2.SetFrameSize
  L14_2 = 64
  L15_2 = 64
  L12_2(L13_2, L14_2, L15_2)
  L13_2 = L11_2
  L12_2 = L11_2.SetVisible
  L14_2 = false
  L12_2(L13_2, L14_2)
  L13_2 = L11_2
  L12_2 = L11_2.SetLocation
  L14_2 = L5_2 + 16
  L15_2 = L6_2 - 24
  L16_2 = L5_2 + 64
  L17_2 = L6_2 + 24
  L12_2(L13_2, L14_2, L15_2, L16_2, L17_2)
  L13_2 = L11_2
  L12_2 = L11_2.SetOwner
  L15_2 = A0_2
  L14_2 = A0_2.GetOwner
  L14_2, L15_2, L16_2, L17_2 = L14_2(L15_2)
  L12_2(L13_2, L14_2, L15_2, L16_2, L17_2)
  L13_2 = L11_2
  L12_2 = L11_2.SetAnchoring
  L14_2 = "center"
  L15_2 = "center"
  L12_2(L13_2, L14_2, L15_2)
  L12_2 = MrxGui
  L12_2 = L12_2.AddWidget
  L13_2 = L11_2
  L12_2(L13_2)
  L13_2 = A0_2
  L12_2 = A0_2.AddChild
  L14_2 = L11_2
  L12_2(L13_2, L14_2)
  L12_2 = A0_2.CustomData
  L12_2.oSparkR = L11_2
  L12_2 = Gui
  L12_2 = L12_2.LoadTexture
  L13_2 = "countdown_circle"
  L14_2 = "texture"
  L12_2(L13_2, L14_2)
  L12_2 = Gui
  L12_2 = L12_2.LoadTexture
  L13_2 = "icon_hijack_button_A"
  L14_2 = "texture"
  L12_2(L13_2, L14_2)
  L12_2 = Gui
  L12_2 = L12_2.LoadTexture
  L13_2 = "icon_hijack_button_B"
  L14_2 = "texture"
  L12_2(L13_2, L14_2)
  L12_2 = Gui
  L12_2 = L12_2.LoadTexture
  L13_2 = "icon_hijack_button_X"
  L14_2 = "texture"
  L12_2(L13_2, L14_2)
  L12_2 = Gui
  L12_2 = L12_2.LoadTexture
  L13_2 = "icon_hijack_button_Y"
  L14_2 = "texture"
  L12_2(L13_2, L14_2)
  L12_2 = Gui
  L12_2 = L12_2.LoadTexture
  L13_2 = "icon_hijack_joystick_down"
  L14_2 = "texture"
  L12_2(L13_2, L14_2)
  L12_2 = Gui
  L12_2 = L12_2.LoadTexture
  L13_2 = "icon_hijack_joystick_up"
  L14_2 = "texture"
  L12_2(L13_2, L14_2)
  L12_2 = Gui
  L12_2 = L12_2.LoadTexture
  L13_2 = "icon_hijack_joystick_left"
  L14_2 = "texture"
  L12_2(L13_2, L14_2)
  L12_2 = Gui
  L12_2 = L12_2.LoadTexture
  L13_2 = "icon_hijack_joystick_right"
  L14_2 = "texture"
  L12_2(L13_2, L14_2)
  L12_2 = Gui
  L12_2 = L12_2.LoadTexture
  L13_2 = "icon_fail"
  L14_2 = "texture"
  L12_2(L13_2, L14_2)
  L12_2 = Gui
  L12_2 = L12_2.LoadTexture
  L13_2 = "icon_sparks_left"
  L14_2 = "texture"
  L12_2(L13_2, L14_2)
  L12_2 = Gui
  L12_2 = L12_2.LoadTexture
  L13_2 = "icon_sparks_right"
  L14_2 = "texture"
  L12_2(L13_2, L14_2)
end

_HandleInitialization = L0_1
L0_1 = {}
_ControllerSpriteTextureMapping = L0_1
L0_1 = _ControllerSpriteTextureMapping
L1_1 = Joystick
L1_1 = L1_1.BUTTON_PAD2_U
L0_1[L1_1] = "icon_hijack_button_Y"
L0_1 = _ControllerSpriteTextureMapping
L1_1 = Joystick
L1_1 = L1_1.BUTTON_PAD2_D
L0_1[L1_1] = "icon_hijack_button_A"
L0_1 = _ControllerSpriteTextureMapping
L1_1 = Joystick
L1_1 = L1_1.BUTTON_PAD2_L
L0_1[L1_1] = "icon_hijack_button_X"
L0_1 = _ControllerSpriteTextureMapping
L1_1 = Joystick
L1_1 = L1_1.BUTTON_PAD2_R
L0_1[L1_1] = "icon_hijack_button_B"
L0_1 = _ControllerSpriteTextureMapping
L1_1 = Joystick
L1_1 = L1_1.BUTTON_L_STICK_L
L0_1[L1_1] = "icon_hijack_joystick_left"
L0_1 = _ControllerSpriteTextureMapping
L1_1 = Joystick
L1_1 = L1_1.BUTTON_L_STICK_R
L0_1[L1_1] = "icon_hijack_joystick_right"
L0_1 = _ControllerSpriteTextureMapping
L1_1 = Joystick
L1_1 = L1_1.BUTTON_L_STICK_U
L0_1[L1_1] = "icon_hijack_joystick_up"
L0_1 = _ControllerSpriteTextureMapping
L1_1 = Joystick
L1_1 = L1_1.BUTTON_L_STICK_D
L0_1[L1_1] = "icon_hijack_joystick_down"
L0_1 = {}
_ControllerSpriteData = L0_1
L0_1 = _ControllerSpriteData
L1_1 = Joystick
L1_1 = L1_1.BUTTON_PAD2_U
L2_1 = {}
L3_1 = 64
L4_1 = 64
L5_1 = 0
L6_1 = 24
L7_1 = 128
L8_1 = 64
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L2_1[4] = L6_1
L2_1[5] = L7_1
L2_1[6] = L8_1
L0_1[L1_1] = L2_1
L0_1 = _ControllerSpriteData
L1_1 = Joystick
L1_1 = L1_1.BUTTON_PAD2_D
L2_1 = _ControllerSpriteData
L3_1 = Joystick
L3_1 = L3_1.BUTTON_PAD2_U
L2_1 = L2_1[L3_1]
L0_1[L1_1] = L2_1
L0_1 = _ControllerSpriteData
L1_1 = Joystick
L1_1 = L1_1.BUTTON_PAD2_L
L2_1 = _ControllerSpriteData
L3_1 = Joystick
L3_1 = L3_1.BUTTON_PAD2_U
L2_1 = L2_1[L3_1]
L0_1[L1_1] = L2_1
L0_1 = _ControllerSpriteData
L1_1 = Joystick
L1_1 = L1_1.BUTTON_PAD2_R
L2_1 = _ControllerSpriteData
L3_1 = Joystick
L3_1 = L3_1.BUTTON_PAD2_U
L2_1 = L2_1[L3_1]
L0_1[L1_1] = L2_1
L0_1 = _ControllerSpriteData
L1_1 = Joystick
L1_1 = L1_1.BUTTON_L_STICK_L
L2_1 = {}
L3_1 = 116
L4_1 = 128
L5_1 = 0
L6_1 = 0
L7_1 = 512
L8_1 = 128
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L2_1[4] = L6_1
L2_1[5] = L7_1
L2_1[6] = L8_1
L0_1[L1_1] = L2_1
L0_1 = _ControllerSpriteData
L1_1 = Joystick
L1_1 = L1_1.BUTTON_L_STICK_R
L2_1 = _ControllerSpriteData
L3_1 = Joystick
L3_1 = L3_1.BUTTON_L_STICK_L
L2_1 = L2_1[L3_1]
L0_1[L1_1] = L2_1
L0_1 = _ControllerSpriteData
L1_1 = Joystick
L1_1 = L1_1.BUTTON_L_STICK_U
L2_1 = {}
L3_1 = 116
L4_1 = 128
L5_1 = 0
L6_1 = 0
L7_1 = 512
L8_1 = 128
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L2_1[4] = L6_1
L2_1[5] = L7_1
L2_1[6] = L8_1
L0_1[L1_1] = L2_1
L0_1 = _ControllerSpriteData
L1_1 = Joystick
L1_1 = L1_1.BUTTON_L_STICK_D
L2_1 = _ControllerSpriteData
L3_1 = Joystick
L3_1 = L3_1.BUTTON_L_STICK_U
L2_1 = L2_1[L3_1]
L0_1[L1_1] = L2_1
