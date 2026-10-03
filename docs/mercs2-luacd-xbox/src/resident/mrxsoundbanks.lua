local L0_1, L1_1
L0_1 = import
L1_1 = "MrxSound"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSoundCategories"
L0_1(L1_1)
L0_1 = 0
_nOutstandingAssets = L0_1
L0_1 = 0
_nSubmittedRequests = L0_1
L0_1 = 64
L1_1 = {}
_tPendingRequests = L1_1
L1_1 = 0
_nLastAddedIndex = L1_1
L1_1 = nil
_funcBatchComplete = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = _AddAssetRequest
  L3_2 = A0_2
  L4_2 = "soundbank"
  L5_2 = true
  L2_2(L3_2, L4_2, L5_2)
  if A1_2 then
    _funcBatchComplete = A1_2
  end
end

LoadSoundBank = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = _AddAssetRequest
  L3_2 = A0_2
  L4_2 = "soundbank"
  L5_2 = false
  L2_2(L3_2, L4_2, L5_2)
  if A1_2 then
    _funcBatchComplete = A1_2
  end
end

UnloadSoundBank = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = _AddAssetRequest
  L3_2 = A0_2
  L4_2 = "wavebank"
  L5_2 = true
  L2_2(L3_2, L4_2, L5_2)
  if A1_2 then
    _funcBatchComplete = A1_2
  end
end

LoadWaveBank = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = _AddAssetRequest
  L3_2 = A0_2
  L4_2 = "wavebank"
  L5_2 = false
  L2_2(L3_2, L4_2, L5_2)
  if A1_2 then
    _funcBatchComplete = A1_2
  end
end

UnloadWaveBank = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  L4_2 = Sound
  L4_2 = L4_2.LoadTempBank
  L5_2 = _GetLocalizedName
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  L6_2 = A1_2
  L7_2 = A2_2
  L8_2 = A3_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
end

LoadTempBank = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  L4_2 = Sound
  L4_2 = L4_2.UnloadTempBank
  L5_2 = _GetLocalizedName
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  L6_2 = A1_2
  L7_2 = A2_2
  L8_2 = A3_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
end

UnloadTempBank = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Sound
  L1_2 = L1_2._GetLibVersion
  L1_2 = L1_2()
  if 12 <= L1_2 then
    L1_2 = Sound
    L1_2 = L1_2.RequestAmbienceBank
    L2_2 = _GetLocalizedName
    L3_2 = A0_2
    L2_2, L3_2 = L2_2(L3_2)
    L1_2(L2_2, L3_2)
  end
end

RequestAmbienceBank = L1_1

function L1_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = _nSubmittedRequests
  L1_2 = L0_1
  if L0_2 < L1_2 then
    L0_2 = _nLastAddedIndex
    if 0 < L0_2 then
      L0_2 = _tPendingRequests
      L1_2 = _nLastAddedIndex
      L0_2 = L0_2[L1_2]
      L0_2 = L0_2[3]
      L1_2 = _tPendingRequests
      L2_2 = _nLastAddedIndex
      L1_2 = L1_2[L2_2]
      L1_2 = L1_2[1]
      L2_2 = _tPendingRequests
      L3_2 = _nLastAddedIndex
      L2_2 = L2_2[L3_2]
      L2_2 = L2_2[2]
      if L0_2 then
        L3_2 = Sound
        L3_2 = L3_2.LoadBankWithCallback
        L4_2 = _GetLocalizedName
        L5_2 = L1_2
        L4_2 = L4_2(L5_2)
        L5_2 = L2_2
        L6_2 = _FlagAssetOpComplete
        L3_2(L4_2, L5_2, L6_2)
      else
        L3_2 = Sound
        L3_2 = L3_2.UnloadBankWithCallback
        L4_2 = _GetLocalizedName
        L5_2 = L1_2
        L4_2 = L4_2(L5_2)
        L5_2 = L2_2
        L6_2 = _FlagAssetOpComplete
        L3_2(L4_2, L5_2, L6_2)
      end
      L3_2 = _nLastAddedIndex
      L3_2 = L3_2 - 1
      _nLastAddedIndex = L3_2
      L3_2 = _nSubmittedRequests
      L3_2 = L3_2 + 1
      _nSubmittedRequests = L3_2
    end
  end
end

_SubmitAssetRequest = L1_1

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = _nLastAddedIndex
  L3_2 = L3_2 + 1
  _nLastAddedIndex = L3_2
  L3_2 = _tPendingRequests
  L4_2 = _nLastAddedIndex
  L5_2 = {}
  L6_2 = A0_2
  L7_2 = A1_2
  L8_2 = A2_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L3_2[L4_2] = L5_2
  L3_2 = _nOutstandingAssets
  L3_2 = L3_2 + 1
  _nOutstandingAssets = L3_2
  L3_2 = _SubmitAssetRequest
  L3_2()
end

_AddAssetRequest = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = string
  L1_2 = L1_2.sub
  L2_2 = A0_2
  L3_2 = 1
  L4_2 = 3
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  if L1_2 == "vo_" then
    L2_2 = Gui
    L2_2 = L2_2.GetLanguageName
    L2_2 = L2_2()
    L3_2 = A0_2
    L4_2 = "."
    L5_2 = L2_2
    L3_2 = L3_2 .. L4_2 .. L5_2
    return L3_2
  end
  return A0_2
end

_GetLocalizedName = L1_1

function L1_1()
  local L0_2, L1_2
  
  function L0_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3
    L1_3 = string
    L1_3 = L1_3.find
    L2_3 = A0_3
    L3_3 = ".pws"
    L1_3 = L1_3(L2_3, L3_3)
    L2_3 = string
    L2_3 = L2_3.sub
    L3_3 = A0_3
    L4_3 = 1
    L5_3 = L1_3 - 1
    return L2_3(L3_3, L4_3, L5_3)
  end
  
  _StripPWSExtension = L0_2
  
  function L0_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L1_3 = _StripPWSExtension
    L2_3 = A0_3
    L1_3 = L1_3(L2_3)
    L2_3 = _GetLocalizedName
    L3_3 = L1_3
    L2_3 = L2_3(L3_3)
    L3_3 = Sound
    L3_3 = L3_3.GetAudioDir
    L3_3 = L3_3()
    L4_3 = L3_3
    L5_3 = "\\"
    L6_3 = L2_3
    L7_3 = ".pws"
    L4_3 = L4_3 .. L5_3 .. L6_3 .. L7_3
    L5_3 = Sound
    L5_3 = L5_3.OpenStreamFile
    L6_3 = L4_3
    L7_3 = A0_3
    L5_3(L6_3, L7_3)
  end
  
  _OpenFile = L0_2
  L0_2 = _OpenFile
  L1_2 = "vo_stream.pws"
  L0_2(L1_2)
  L0_2 = _OpenFile
  L1_2 = "music.pws"
  L0_2(L1_2)
  L0_2 = _OpenFile
  L1_2 = "ambience.pws"
  L0_2(L1_2)
end

_OpenStreamFiles = L1_1

function L1_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = _OpenStreamFiles
  L0_2()
  L0_2 = Pg
  L0_2 = L0_2.LoadAsset
  L1_2 = "Mercs2Globals"
  L2_2 = "sounddb"
  L3_2 = MrxSoundCategories
  L3_2 = L3_2._DuckGlobalTable
  L0_2(L1_2, L2_2, L3_2)
  L0_2 = Pg
  L0_2 = L0_2.LoadAsset
  L1_2 = "MusicMarkers"
  L2_2 = "musicmarkers"
  L0_2(L1_2, L2_2)
  L0_2 = Pg
  L0_2 = L0_2.LoadAsset
  L1_2 = "MusicTransitions"
  L2_2 = "musictransitions"
  L0_2(L1_2, L2_2)
end

_LoadRequiredAssetsCommon = L1_1

function L1_1()
  local L0_2, L1_2, L2_2
  L0_2 = Pg
  L0_2 = L0_2.UnloadAsset
  L1_2 = "Mercs2Globals"
  L2_2 = "sounddb"
  L0_2(L1_2, L2_2)
  L0_2 = Pg
  L0_2 = L0_2.UnloadAsset
  L1_2 = "MusicMarkers"
  L2_2 = "musicmarkers"
  L0_2(L1_2, L2_2)
  L0_2 = Pg
  L0_2 = L0_2.UnloadAsset
  L1_2 = "MusicTransitions"
  L2_2 = "musictransitions"
  L0_2(L1_2, L2_2)
end

_UnloadRequiredAssetsCommon = L1_1

function L1_1()
  local L0_2, L1_2, L2_2
  L0_2 = _LoadRequiredAssetsCommon
  L0_2()
  L0_2 = Pg
  L0_2 = L0_2.LoadAsset
  L1_2 = "VehicleEngines"
  L2_2 = "animationtable"
  L0_2(L1_2, L2_2)
  L0_2 = Pg
  L0_2 = L0_2.LoadAsset
  L1_2 = "Sounds"
  L2_2 = "animationtable"
  L0_2(L1_2, L2_2)
  L0_2 = Pg
  L0_2 = L0_2.LoadAsset
  L1_2 = "SoundsAppendix"
  L2_2 = "animationtable"
  L0_2(L1_2, L2_2)
  L0_2 = Pg
  L0_2 = L0_2.LoadAsset
  L1_2 = "SoundMatch"
  L2_2 = "animationtable"
  L0_2(L1_2, L2_2)
  L0_2 = Pg
  L0_2 = L0_2.LoadAsset
  L1_2 = "SoundKey"
  L2_2 = "materialkeytable"
  L0_2(L1_2, L2_2)
end

_LoadRequiredAssets = L1_1

function L1_1()
  local L0_2, L1_2, L2_2
  L0_2 = _UnloadRequiredAssetsCommon
  L0_2()
  L0_2 = Pg
  L0_2 = L0_2.UnloadAsset
  L1_2 = "VehicleEngines"
  L2_2 = "animationtable"
  L0_2(L1_2, L2_2)
  L0_2 = Pg
  L0_2 = L0_2.UnloadAsset
  L1_2 = "Sounds"
  L2_2 = "animationtable"
  L0_2(L1_2, L2_2)
  L0_2 = Pg
  L0_2 = L0_2.UnloadAsset
  L1_2 = "SoundsAppendix"
  L2_2 = "animationtable"
  L0_2(L1_2, L2_2)
  L0_2 = Pg
  L0_2 = L0_2.UnloadAsset
  L1_2 = "SoundMatch"
  L2_2 = "animationtable"
  L0_2(L1_2, L2_2)
  L0_2 = Pg
  L0_2 = L0_2.UnloadAsset
  L1_2 = "SoundKey"
  L2_2 = "materialkeytable"
  L0_2(L1_2, L2_2)
end

_UnloadRequiredAssets = L1_1

function L1_1()
  local L0_2, L1_2
  L0_2 = _nSubmittedRequests
  L0_2 = L0_2 - 1
  _nSubmittedRequests = L0_2
  L0_2 = _nOutstandingAssets
  L0_2 = L0_2 - 1
  _nOutstandingAssets = L0_2
  L0_2 = _SubmitAssetRequest
  L0_2()
  L0_2 = _nOutstandingAssets
  if L0_2 == 0 then
    L0_2 = _funcBatchComplete
    if L0_2 then
      L0_2 = _funcBatchComplete
      L0_2()
      L0_2 = nil
      _funcBatchComplete = L0_2
      L0_2 = MrxSound
      L0_2 = L0_2._CheckSoundReady
      L0_2()
    end
  end
end

_FlagAssetOpComplete = L1_1
