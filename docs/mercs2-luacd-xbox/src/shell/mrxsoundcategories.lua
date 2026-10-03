local L0_1, L1_1
L0_1 = {}
L1_1 = {}
L0_1.vosequence = L1_1
L1_1 = {}
L0_1.credits = L1_1
L1_1 = {}
L0_1.actionhijack = L1_1
L1_1 = {}
L0_1.survivalmode = L1_1
L1_1 = {}
L0_1.fanfare = L1_1
L1_1 = {}
L0_1.satelliteview = L1_1
_tFadeSettings = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2
  L5_2 = _tFadeSettings
  L5_2 = L5_2[A0_2]
  L6_2 = {}
  L7_2 = A2_2
  L8_2 = A3_2
  L9_2 = A4_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L5_2[A1_2] = L6_2
end

SetFadeCategory = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = pairs
  L3_2 = _tFadeSettings
  L3_2 = L3_2[A0_2]
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = L6_2[1]
    L8_2 = L6_2[2]
    L9_2 = L6_2[3]
    if A1_2 then
      L10_2 = Sound
      L10_2 = L10_2.FadeCategoryDown
      L11_2 = L5_2
      L12_2 = L7_2
      L13_2 = L8_2
      L10_2(L11_2, L12_2, L13_2)
    else
      L10_2 = Sound
      L10_2 = L10_2.FadeCategoryUp
      L11_2 = L5_2
      L12_2 = L9_2
      L10_2(L11_2, L12_2)
    end
  end
end

Fade = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = SetFadeCategory
  L1_2 = "credits"
  L2_2 = "sfx"
  L3_2 = 0
  L4_2 = 0.5
  L5_2 = 0.5
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2)
  L0_2 = SetFadeCategory
  L1_2 = "credits"
  L2_2 = "vo"
  L3_2 = 0
  L4_2 = 0.5
  L5_2 = 0.5
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2)
end

_AdditionalFadeSetup = L0_1
L0_1 = {}
L1_1 = {}
L0_1.survivalmode = L1_1
_tPitchSettings = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2
  L5_2 = _tPitchSettings
  L5_2 = L5_2[A0_2]
  L6_2 = {}
  L7_2 = A2_2
  L8_2 = A3_2
  L9_2 = A4_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L5_2[A1_2] = L6_2
end

SetPitchCategory = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = pairs
  L3_2 = _tPitchSettings
  L3_2 = L3_2[A0_2]
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = L6_2[1]
    L8_2 = L6_2[2]
    L9_2 = L6_2[3]
    if A1_2 then
      L10_2 = Sound
      L10_2 = L10_2.PitchCategoryActivate
      L11_2 = L5_2
      L12_2 = L7_2
      L13_2 = L8_2
      L10_2(L11_2, L12_2, L13_2)
    else
      L10_2 = Sound
      L10_2 = L10_2.PitchCategoryDeactivate
      L11_2 = L5_2
      L12_2 = L9_2
      L10_2(L11_2, L12_2)
    end
  end
end

Pitch = L0_1
L0_1 = false
_bDuckOnGlobalTableLoad = L0_1

function L0_1(A0_2)
  local L1_2
  _bDuckOnGlobalTableLoad = A0_2
end

SetDuckOnGlobalTableLoad = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = _bDuckOnGlobalTableLoad
  if L0_2 then
    L0_2 = Sound
    L0_2 = L0_2.SetMasterVolume
    L1_2 = 0
    L2_2 = 0.3
    L0_2(L1_2, L2_2)
  end
end

_DuckGlobalTable = L0_1
L0_1 = 0
_nMasterVolumeRefCount = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = _nMasterVolumeRefCount
  if L1_2 == 0 then
    L1_2 = Sound
    L1_2 = L1_2.SetMasterVolume
    L2_2 = 0
    L3_2 = A0_2
    L1_2(L2_2, L3_2)
  end
  L1_2 = _nMasterVolumeRefCount
  L1_2 = L1_2 + 1
  _nMasterVolumeRefCount = L1_2
end

DuckMasterVolume = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = _nMasterVolumeRefCount
  L1_2 = L1_2 - 1
  _nMasterVolumeRefCount = L1_2
  L1_2 = _nMasterVolumeRefCount
  if L1_2 == 0 then
    L1_2 = Sound
    L1_2 = L1_2.SetMasterVolume
    L2_2 = 1
    L3_2 = A0_2
    L1_2(L2_2, L3_2)
  end
end

UnduckMasterVolume = L0_1
