local L0_1, L1_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 0.1
  L3_2[1] = L4_2
  L4_2 = _GraphicsAto
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

OnActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.Begin
  L1_2()
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetColorValue
  L2_2 = "uiAmbientColor"
  L3_2 = 128
  L4_2 = 128
  L5_2 = 128
  L6_2 = 255
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetColorValue
  L2_2 = "uiAmbientCube0"
  L3_2 = 128
  L4_2 = 128
  L5_2 = 128
  L6_2 = 255
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetColorValue
  L2_2 = "uiAmbientCube1"
  L3_2 = 128
  L4_2 = 128
  L5_2 = 128
  L6_2 = 255
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetColorValue
  L2_2 = "uiAmbientCube2"
  L3_2 = 128
  L4_2 = 128
  L5_2 = 128
  L6_2 = 255
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetColorValue
  L2_2 = "uiAmbientCube3"
  L3_2 = 128
  L4_2 = 128
  L5_2 = 128
  L6_2 = 255
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetColorValue
  L2_2 = "uiAmbientCube4"
  L3_2 = 128
  L4_2 = 128
  L5_2 = 128
  L6_2 = 255
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetColorValue
  L2_2 = "uiAmbientCube5"
  L3_2 = 128
  L4_2 = 128
  L5_2 = 128
  L6_2 = 255
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetValue
  L2_2 = "fAtmosphereForce"
  L3_2 = 0
  L1_2(L2_2, L3_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetValue
  L2_2 = "fAtmosphereLimit"
  L3_2 = 200
  L1_2(L2_2, L3_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetValue
  L2_2 = "fBloomAdaptiveLuminancePercent"
  L3_2 = 0.98
  L1_2(L2_2, L3_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetValue
  L2_2 = "fBloomAdaptiveLuminanceScale"
  L3_2 = 30
  L1_2(L2_2, L3_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetValue
  L2_2 = "fBloomAmount"
  L3_2 = 1
  L1_2(L2_2, L3_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetValue
  L2_2 = "fBloomBlurRadius"
  L3_2 = 1
  L1_2(L2_2, L3_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetValue
  L2_2 = "fBloomContastLimit"
  L3_2 = 1
  L1_2(L2_2, L3_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetValue
  L2_2 = "fBloomContastMultiplier"
  L3_2 = 1.85
  L1_2(L2_2, L3_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetValue
  L2_2 = "fBloomMultiplier"
  L3_2 = 0.8
  L1_2(L2_2, L3_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetValue
  L2_2 = "fBloomTargetLuminance"
  L3_2 = 1
  L1_2(L2_2, L3_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetValue
  L2_2 = "fBloomThreshold"
  L3_2 = 1
  L1_2(L2_2, L3_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetColorValue
  L2_2 = "uiGradient0_Color2"
  L3_2 = 0
  L4_2 = 0
  L5_2 = 255
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetColorValue
  L2_2 = "uiGradient1_Color1"
  L3_2 = 0
  L4_2 = 0
  L5_2 = 255
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetValue
  L2_2 = "fLightIntensity"
  L3_2 = 1
  L1_2(L2_2, L3_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetColorValue
  L2_2 = "uiRimColor"
  L3_2 = 128
  L4_2 = 128
  L5_2 = 128
  L6_2 = 255
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetValue
  L2_2 = "fTimeRestore"
  L3_2 = 1.7
  L1_2(L2_2, L3_2)
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.End
  L1_2()
end

_GraphicsAto = L0_1
