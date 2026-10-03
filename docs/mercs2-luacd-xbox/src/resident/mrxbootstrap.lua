local L0_1, L1_1
L0_1 = import
L1_1 = "MrxSoundBootstrap"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiBootstrap"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxLayerManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPlayer"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxState"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = false
_bGuiLoaded = L0_1
L0_1 = false
_bLocalPlayerJoined = L0_1
L0_1 = true
_bHandleStateTransitions = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = false
  _bGuiLoaded = L2_2
  L2_2 = nil
  _sHeroSpawnLocation = L2_2
  L2_2 = false
  _bLocalPlayerJoined = L2_2
  _fOnDoneCallback = A0_2
  _tOnDoneCallbackArgs = A1_2
  L2_2 = MrxGuiBootstrap
  L2_2 = L2_2.SetOnGuiLoadedFunc
  L3_2 = _GuiLoaded
  L2_2(L3_2)
  L2_2 = MrxPlayer
  L2_2 = L2_2.SetLocalPlayerJoinedCallback
  L3_2 = _LocalPlayerJoined
  L2_2(L3_2)
  L2_2 = MrxPlayer
  L2_2 = L2_2.Start
  L2_2()
end

Start = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _bGuiLoaded
  return L0_2
end

IsGuiLoaded = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = _bGuiLoaded
  if not L0_2 then
    L0_2 = true
    _bGuiLoaded = L0_2
    L0_2 = _bHandleStateTransitions
    if L0_2 then
      L0_2 = MrxState
      L0_2 = L0_2.Enter
      L1_2 = MrxState
      L1_2 = L1_2.STATE_WAITFORGAME
      L2_2 = _End
      L0_2(L1_2, L2_2)
    else
      L0_2 = _End
      L0_2()
    end
  end
end

_GuiLoaded = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _bLocalPlayerJoined
  if not L0_2 then
    L0_2 = true
    _bLocalPlayerJoined = L0_2
    L0_2 = _End
    L0_2()
  end
end

_LocalPlayerJoined = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L0_2 = _bLocalPlayerJoined
  if not L0_2 then
    return
  end
  L0_2 = _bGuiLoaded
  if not L0_2 then
    return
  end
  L0_2 = _bHandleStateTransitions
  if L0_2 then
    L0_2 = MrxState
    L0_2 = L0_2.Exit
    L1_2 = MrxState
    L1_2 = L1_2.STATE_WAITFORGAME
    L0_2(L1_2)
  end
  L0_2 = MrxFactionManager
  L0_2 = L0_2.Setup
  L0_2()
  L0_2 = string
  L0_2 = L0_2.lower
  L1_2 = Sys
  L1_2 = L1_2.GetLevelName
  L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L1_2()
  L0_2 = L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  if L0_2 ~= "vz" then
    L1_2 = SetDefaultAtmosphere
    L1_2()
  end
  L1_2 = Sys
  L1_2 = L1_2.StartWithResources
  if L1_2 then
    L1_2 = Sys
    L1_2 = L1_2.StartWithResources
    L1_2 = L1_2()
    if L1_2 then
      L1_2 = MrxPmc
      L1_2 = L1_2.AddCashQty
      L2_2 = 10000000
      L1_2(L2_2)
      L1_2 = MrxPmc
      L1_2 = L1_2.SetFuelCapacity
      L2_2 = 9999
      L3_2 = true
      L1_2(L2_2, L3_2)
      L1_2 = MrxPmc
      L1_2 = L1_2.AddFuelQty
      L2_2 = 9999
      L1_2(L2_2)
      L1_2 = MrxSupportData
      L1_2 = L1_2.tSupportData
      L2_2 = pairs
      L3_2 = L1_2
      L2_2, L3_2, L4_2 = L2_2(L3_2)
      for L5_2, L6_2 in L2_2, L3_2, L4_2 do
        L7_2 = MrxPmc
        L7_2 = L7_2.AddSupportQty
        L8_2 = L5_2
        L9_2 = L6_2.nMaxStock
        L10_2 = MrxPmc
        L10_2 = L10_2.GetSupportQty
        L11_2 = L5_2
        L10_2 = L10_2(L11_2)
        if not L10_2 then
          L10_2 = 0
        end
        L9_2 = L9_2 - L10_2
        L7_2(L8_2, L9_2)
      end
      L2_2 = MrxSupportData
      L2_2 = L2_2.SetIgnoreRequirements
      L3_2 = true
      L2_2(L3_2)
    end
  end
  L1_2 = MrxUtil
  L1_2 = L1_2.CallWithOptionalArgs
  L2_2 = _fOnDoneCallback
  L3_2 = _tOnDoneCallbackArgs
  L1_2(L2_2, L3_2)
end

_End = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L0_2 = Graphics
  L0_2 = L0_2.Atmosphere
  L0_2 = L0_2.Begin
  L0_2()
  L0_2 = Graphics
  L0_2 = L0_2.Atmosphere
  L0_2 = L0_2.SetTime
  L1_2 = 0.3
  L0_2(L1_2)
  L0_2 = Graphics
  L0_2 = L0_2.Atmosphere
  L0_2 = L0_2.SetSky
  L1_2 = "afternoon"
  L0_2(L1_2)
  L0_2 = Graphics
  L0_2 = L0_2.Atmosphere
  L0_2 = L0_2.SetTimeSpeed
  L1_2 = 0
  L0_2(L1_2)
  L0_2 = Graphics
  L0_2 = L0_2.Atmosphere
  L0_2 = L0_2.SetAmbientCube
  L1_2 = 0.42
  L2_2 = 0.44
  L3_2 = 0.49
  L4_2 = 0.4
  L5_2 = 0.48
  L6_2 = 0.47
  L7_2 = 0.6
  L8_2 = 0.67
  L9_2 = 0.68
  L10_2 = 0.31
  L11_2 = 0.27
  L12_2 = 0.12
  L13_2 = 0.3
  L14_2 = 0.35
  L15_2 = 0.4
  L16_2 = 0.45
  L17_2 = 0.47
  L18_2 = 0.37
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  L0_2 = Graphics
  L0_2 = L0_2.Atmosphere
  L0_2 = L0_2.SetAmbientColor
  L1_2 = 0.45
  L2_2 = 0.45
  L3_2 = 0.45
  L0_2(L1_2, L2_2, L3_2)
  L0_2 = Graphics
  L0_2 = L0_2.Atmosphere
  L0_2 = L0_2.SetLightIntensity
  L1_2 = 1
  L0_2(L1_2)
  L0_2 = Graphics
  L0_2 = L0_2.Atmosphere
  L0_2 = L0_2.SetInscatteringMultiplier
  L1_2 = 50
  L0_2(L1_2)
  L0_2 = Graphics
  L0_2 = L0_2.Atmosphere
  L0_2 = L0_2.SetExtinctionMultiplier
  L1_2 = 0.8
  L0_2(L1_2)
  L0_2 = Graphics
  L0_2 = L0_2.Atmosphere
  L0_2 = L0_2.SetBetaRayMultiplier
  L1_2 = 0.001
  L0_2(L1_2)
  L0_2 = Graphics
  L0_2 = L0_2.Atmosphere
  L0_2 = L0_2.SetBetaMieMultiplier
  L1_2 = 0.01
  L0_2(L1_2)
  L0_2 = Graphics
  L0_2 = L0_2.Atmosphere
  L0_2 = L0_2.SetHenyeyGreensteinConst
  L1_2 = 0.9
  L0_2(L1_2)
  L0_2 = Graphics
  L0_2 = L0_2.Bloom
  L0_2 = L0_2.SetBlurRadius
  L1_2 = 0.5
  L0_2(L1_2)
  L0_2 = Graphics
  L0_2 = L0_2.Bloom
  L0_2 = L0_2.SetThreshold
  L1_2 = 0.775
  L0_2(L1_2)
  L0_2 = Graphics
  L0_2 = L0_2.Bloom
  L0_2 = L0_2.SetMultiplier
  L1_2 = 0
  L0_2(L1_2)
  L0_2 = Graphics
  L0_2 = L0_2.Monochrome
  L0_2 = L0_2.SetGradient
  L1_2 = 0
  L2_2 = 128
  L3_2 = 0
  L4_2 = 0
  L5_2 = 0
  L6_2 = 0
  L7_2 = 0
  L8_2 = 0.65
  L9_2 = 0.35
  L10_2 = 0
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  L0_2 = Graphics
  L0_2 = L0_2.Monochrome
  L0_2 = L0_2.SetGradient
  L1_2 = 128
  L2_2 = 255
  L3_2 = 0
  L4_2 = 0.65
  L5_2 = 0.35
  L6_2 = 0
  L7_2 = 1
  L8_2 = 1
  L9_2 = 1
  L10_2 = 0
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  L0_2 = Graphics
  L0_2 = L0_2.Contrast
  L0_2 = L0_2.SetLimit
  L1_2 = 0.1
  L0_2(L1_2)
  L0_2 = Graphics
  L0_2 = L0_2.Contrast
  L0_2 = L0_2.SetMultiplier
  L1_2 = 1.5
  L0_2(L1_2)
  L0_2 = Graphics
  L0_2 = L0_2.Atmosphere
  L0_2 = L0_2.End
  L1_2 = 8
  L0_2(L1_2)
end

SetDefaultAtmosphere = L0_1

function L0_1(A0_2)
  local L1_2
  _sHeroSpawnLocation = A0_2
end

SetHeroSpawnLocation = L0_1

function L0_1(A0_2)
  local L1_2
  _bHandleStateTransitions = A0_2
end

SetHandleStateTransitions = L0_1
