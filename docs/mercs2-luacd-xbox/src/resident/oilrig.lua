local L0_1, L1_1
L0_1 = import
L1_1 = "MrxLayerManager"
L0_1(L1_1)
L0_1 = nil
_tOilrigEvents = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _tOilrigEvents
  if not L0_2 then
    L0_2 = {}
    _tOilrigEvents = L0_2
    L0_2 = {}
    tTGLayers = L0_2
    L0_2 = tTGLayers
    L0_2["0x000B637B"] = "vz_state_mer_oilrig_pristine"
    L0_2 = tTGLayers
    L0_2["0x0009878A"] = "vz_state_chijob009_a_pristine"
    L0_2 = tTGLayers
    L0_2["0x00098789"] = "vz_state_chijob009_b_pristine"
  end
end

Init = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = pairs
  L1_2 = _tOilrigEvents
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = _CleanupOilrigEvents
    L6_2 = L3_2
    L5_2(L6_2)
  end
  L0_2 = nil
  _tOilrigEvents = L0_2
  L0_2 = nil
  tTGLayers = L0_2
end

Deinit = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _tOilrigEvents
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L2_2 = _FinishDestruction
    L3_2 = A0_2
    L2_2(L3_2)
  end
  L2_2 = Object
  L2_2 = L2_2.IsAlive
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L2_2 = tTGLayers
    L3_2 = Sys
    L3_2 = L3_2.GuidToString
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
    L2_2 = L2_2[L3_2]
    L3_2 = MrxLayerManager
    L3_2 = L3_2.Remove
    L4_2 = L2_2
    L3_2(L4_2)
  end
end

OnDeactivate = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = Sys
  L3_2 = L3_2.GuidToString
  L4_2 = A2_2
  L3_2 = L3_2(L4_2)
  if L3_2 == "0x28825D4C" then
    L4_2 = tTGLayers
    L5_2 = Sys
    L5_2 = L5_2.GuidToString
    L6_2 = A0_2
    L5_2 = L5_2(L6_2)
    L4_2 = L4_2[L5_2]
    L5_2 = MrxLayerManager
    L5_2 = L5_2.Remove
    L6_2 = L4_2
    L7_2 = "_tg"
    L6_2 = L6_2 .. L7_2
    L5_2(L6_2)
    L5_2 = Sound
    L5_2 = L5_2.CueSound
    L6_2 = A0_2
    L7_2 = "seq_oilrig_destruction"
    L5_2(L6_2, L7_2)
    L5_2 = Camera
    L5_2 = L5_2.Shake
    L6_2 = StringToGuid
    L7_2 = "0x1"
    L6_2 = L6_2(L7_2)
    L7_2 = "ShakeCameraConstantlyRandom"
    L8_2 = A0_2
    L9_2 = 0.5
    L10_2 = 2000
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
    L5_2 = {}
    L6_2 = Event
    L6_2 = L6_2.Create
    L7_2 = Event
    L7_2 = L7_2.TimerRelative
    L8_2 = {}
    L9_2 = 2.5
    L8_2[1] = L9_2
    L9_2 = _DestroyOilrigSequence
    L10_2 = {}
    L11_2 = A0_2
    L12_2 = A1_2
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
    L7_2 = table
    L7_2 = L7_2.insert
    L8_2 = L5_2
    L9_2 = L6_2
    L7_2(L8_2, L9_2)
    L7_2 = _tOilrigEvents
    L7_2[A0_2] = L5_2
  elseif L3_2 == "0x694683EB" then
    L4_2 = Sound
    L4_2 = L4_2.CueSound
    L5_2 = A0_2
    L6_2 = "sfx_amb_oilrig_destruction"
    L4_2(L5_2, L6_2)
    L4_2 = Camera
    L4_2 = L4_2.Shake
    L5_2 = StringToGuid
    L6_2 = "0x1"
    L5_2 = L5_2(L6_2)
    L6_2 = "ShakeCameraConstantlyRandom"
    L7_2 = A0_2
    L8_2 = 1.2
    L9_2 = 2000
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  end
end

OnStateChange = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = _tOilrigEvents
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L2_2 = pairs
    L3_2 = L1_2
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2, L6_2 in L2_2, L3_2, L4_2 do
      L7_2 = Event
      L7_2 = L7_2.Delete
      L8_2 = L6_2
      L7_2(L8_2)
    end
    L2_2 = _tOilrigEvents
    L2_2[A0_2] = nil
  end
end

_CleanupOilrigEvents = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Camera
  L1_2 = L1_2.Shake
  L2_2 = StringToGuid
  L3_2 = "0x1"
  L2_2 = L2_2(L3_2)
  L3_2 = "StopShakeCameraConstantly"
  L4_2 = A0_2
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = _CleanupOilrigEvents
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Post
  L2_2 = "oilrigDestroyed"
  L3_2 = {}
  L4_2 = A0_2
  L3_2[1] = L4_2
  L1_2(L2_2, L3_2)
end

_FinishDestruction = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = ObjectState
  L1_2 = L1_2.GetLinkGuid
  L2_2 = A0_2
  L3_2 = String
  L3_2 = L3_2.GetHash
  L4_2 = "hp_snap_oilrig_bld_buildingA"
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L3_2(L4_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  L2_2 = Object
  L2_2 = L2_2.IsAlive
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L2_2 = {}
  L3_2 = {}
  L4_2 = _DestroyLinkedGuid
  L3_2.fn = L4_2
  L4_2 = {}
  L5_2 = L1_2
  L6_2 = "hp_snap_piece1A_oilrig_towerblowoutsmallA"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L3_2.args = L4_2
  L4_2 = {}
  L5_2 = _DestroyLinkedGuid
  L4_2.fn = L5_2
  L5_2 = {}
  L6_2 = L1_2
  L7_2 = "hp_snap_piece1B_oilrig_cranesmallA"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2.args = L5_2
  L4_2.minTime = 1
  L4_2.maxTime = 1.5
  L5_2 = {}
  L6_2 = _DestroyLinkedGuid
  L5_2.fn = L6_2
  L6_2 = {}
  L7_2 = L1_2
  L8_2 = "hp_snap_piece1B_oilrig_cranelargeA"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2.args = L6_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L3_2 = _ProcessNextEvent
  L4_2 = A0_2
  L5_2 = L2_2
  L6_2 = 1
  L3_2(L4_2, L5_2, L6_2)
end

_DestroyBuildingA = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = ObjectState
  L1_2 = L1_2.GetLinkGuid
  L2_2 = A0_2
  L3_2 = String
  L3_2 = L3_2.GetHash
  L4_2 = "hp_snap_oilrig_bld_buildingB"
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L3_2(L4_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  L2_2 = Object
  L2_2 = L2_2.IsAlive
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L2_2 = {}
  L3_2 = {}
  L4_2 = _DestroyLinkedGuid
  L3_2.fn = L4_2
  L4_2 = {}
  L5_2 = L1_2
  L6_2 = "hp_snap_piece1A_oilrig_towerblowoutsmallA"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L3_2.args = L4_2
  L3_2.minTime = 0.7
  L3_2.maxTime = 0.9
  L4_2 = {}
  L5_2 = _DestroyLinkedGuid
  L4_2.fn = L5_2
  L5_2 = {}
  L6_2 = L1_2
  L7_2 = "hp_snap_piece1B_oilrig_radiojammer"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2.args = L5_2
  L4_2.minTime = 0.5
  L5_2 = {}
  L6_2 = _DestroyLinkedGuid
  L5_2.fn = L6_2
  L6_2 = {}
  L7_2 = L1_2
  L8_2 = "hp_snap_mv_piece1B_oilrig_helipadsmallA"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2.args = L6_2
  L5_2.minTime = 1.4
  L5_2.maxTime = 1.6
  L6_2 = {}
  L7_2 = _DestroyLinkedGuid
  L6_2.fn = L7_2
  L7_2 = {}
  L8_2 = L1_2
  L9_2 = "hp_snap_piece2A_oilrig_cranesmallA"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L6_2.args = L7_2
  L7_2 = {}
  L8_2 = _DestroyLinkedGuid
  L7_2.fn = L8_2
  L8_2 = {}
  L9_2 = L1_2
  L10_2 = "hp_snap_piece2B_oilrig_cranelargeA"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L7_2.args = L8_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L3_2 = _ProcessNextEvent
  L4_2 = A0_2
  L5_2 = L2_2
  L6_2 = 1
  L3_2(L4_2, L5_2, L6_2)
end

_DestroyBuildingB = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = ObjectState
  L1_2 = L1_2.GetLinkGuid
  L2_2 = A0_2
  L3_2 = String
  L3_2 = L3_2.GetHash
  L4_2 = "hp_snap_oilrig_bld_buildingC"
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L3_2(L4_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  L2_2 = Object
  L2_2 = L2_2.IsAlive
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L2_2 = {}
  L3_2 = {}
  L4_2 = _DestroyLinkedGuid
  L3_2.fn = L4_2
  L4_2 = {}
  L5_2 = L1_2
  L6_2 = "hp_snap_piece1C_oilrig_cranesmallA"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L3_2.args = L4_2
  L3_2.minTime = 1
  L4_2 = {}
  L5_2 = _DestroyLinkedGuid
  L4_2.fn = L5_2
  L5_2 = {}
  L6_2 = L1_2
  L7_2 = "hp_snap_piece1C_oilrig_towerblowoutlargeA"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2.args = L5_2
  L4_2.minTime = 2.5
  L5_2 = {}
  L6_2 = _DestroyLinkedGuid
  L5_2.fn = L6_2
  L6_2 = {}
  L7_2 = L1_2
  L8_2 = "hp_snap_piece1B_oilrig_cranelargeA"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2.args = L6_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L3_2 = _ProcessNextEvent
  L4_2 = A0_2
  L5_2 = L2_2
  L6_2 = 1
  L3_2(L4_2, L5_2, L6_2)
end

_DestroyBuildingC = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = ObjectState
  L1_2 = L1_2.GetLinkGuid
  L2_2 = A0_2
  L3_2 = String
  L3_2 = L3_2.GetHash
  L4_2 = "hp_snap_oilrig_bld_buildingD"
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L3_2(L4_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L2_2 = Object
  L2_2 = L2_2.IsAlive
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L2_2 = {}
  L3_2 = {}
  L4_2 = _DestroyLinkedGuid
  L3_2.fn = L4_2
  L4_2 = {}
  L5_2 = L1_2
  L6_2 = "hp_snap_piece1b_oilrig_tankmedA_a"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L3_2.args = L4_2
  L3_2.minTime = 0.25
  L4_2 = {}
  L5_2 = _DestroyLinkedGuid
  L4_2.fn = L5_2
  L5_2 = {}
  L6_2 = L1_2
  L7_2 = "hp_snap_piece1b_oilrig_tankmedA_b"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2.args = L5_2
  L4_2.minTime = 0.25
  L5_2 = {}
  L6_2 = _DestroyLinkedGuid
  L5_2.fn = L6_2
  L6_2 = {}
  L7_2 = L1_2
  L8_2 = "hp_snap_piece1C_oilrig_tankmedA_c"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2.args = L6_2
  L5_2.minTime = 0.25
  L6_2 = {}
  L7_2 = _DestroyLinkedGuid
  L6_2.fn = L7_2
  L7_2 = {}
  L8_2 = L1_2
  L9_2 = "hp_snap_piece1b_oilrig_att_pipeblowout"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L6_2.args = L7_2
  L6_2.minTime = 0.75
  L7_2 = {}
  L8_2 = _DestroyLinkedGuid
  L7_2.fn = L8_2
  L8_2 = {}
  L9_2 = L1_2
  L10_2 = "hp_snap_mv_piece1b_oilrig_smokestack"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L7_2.args = L8_2
  L7_2.minTime = 1
  L8_2 = {}
  L9_2 = _DestroyLinkedGuid
  L8_2.fn = L9_2
  L9_2 = {}
  L10_2 = L1_2
  L11_2 = "hp_snap_mv_piece1A_oilrig_bld_helipadsmallA"
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L8_2.args = L9_2
  L8_2.minTime = 0.2
  L9_2 = {}
  L10_2 = _DestroyLinkedGuid
  L9_2.fn = L10_2
  L10_2 = {}
  L11_2 = L1_2
  L12_2 = "hp_snap_piece1A_oilrig_cranelargeA"
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L9_2.args = L10_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L2_2[6] = L8_2
  L2_2[7] = L9_2
  L3_2 = _ProcessNextEvent
  L4_2 = A0_2
  L5_2 = L2_2
  L6_2 = 1
  L3_2(L4_2, L5_2, L6_2)
end

_DestroyBuildingD = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2
  L2_2 = String
  L2_2 = L2_2.GetHash
  L3_2 = "fx_Explosion_HugeOil_RigOnly"
  L2_2 = L2_2(L3_2)
  uLargeExplosion = L2_2
  L2_2 = String
  L2_2 = L2_2.GetHash
  L3_2 = "fx_Explosion_HugeOilTower_RigOnly"
  L2_2 = L2_2(L3_2)
  uHugeExplosion = L2_2
  L2_2 = {}
  L3_2 = {}
  L4_2 = ObjectState
  L4_2 = L4_2.StartEmitter
  L3_2.fn = L4_2
  L4_2 = {}
  L5_2 = A0_2
  L6_2 = String
  L6_2 = L6_2.GetHash
  L7_2 = "hp_fx_explosionA"
  L6_2 = L6_2(L7_2)
  L7_2 = uLargeExplosion
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L3_2.args = L4_2
  L3_2.minTime = 1
  L3_2.maxTime = 1.2
  L4_2 = {}
  L5_2 = ObjectState
  L5_2 = L5_2.StartEmitter
  L4_2.fn = L5_2
  L5_2 = {}
  L6_2 = A0_2
  L7_2 = String
  L7_2 = L7_2.GetHash
  L8_2 = "hp_fx_explosionD"
  L7_2 = L7_2(L8_2)
  L8_2 = uLargeExplosion
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L4_2.args = L5_2
  L4_2.minTime = 0.5
  L5_2 = {}
  L6_2 = ObjectState
  L6_2 = L6_2.StartEmitter
  L5_2.fn = L6_2
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = String
  L8_2 = L8_2.GetHash
  L9_2 = "hp_fx_explosionE"
  L8_2 = L8_2(L9_2)
  L9_2 = uHugeExplosion
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L5_2.args = L6_2
  L5_2.minTime = 0.8
  L5_2.maxTime = 1
  L6_2 = {}
  L7_2 = ObjectState
  L7_2 = L7_2.StartEmitter
  L6_2.fn = L7_2
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = String
  L9_2 = L9_2.GetHash
  L10_2 = "hp_fx_explosionF"
  L9_2 = L9_2(L10_2)
  L10_2 = uHugeExplosion
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L6_2.args = L7_2
  L6_2.minTime = 0.8
  L6_2.maxTime = 1
  L7_2 = {}
  L8_2 = _DestroyBuildingD
  L7_2.fn = L8_2
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L7_2.args = L8_2
  L7_2.minTime = 1
  L8_2 = {}
  L9_2 = _DestroyLinkedGuid
  L8_2.fn = L9_2
  L9_2 = {}
  L10_2 = A0_2
  L11_2 = "hp_snap_oilrig_catwalkB"
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L8_2.args = L9_2
  L9_2 = {}
  L10_2 = _DestroyLinkedGuid
  L9_2.fn = L10_2
  L10_2 = {}
  L11_2 = A0_2
  L12_2 = "hp_snap_oilrig_scaffold"
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L9_2.args = L10_2
  L9_2.minTime = 0.5
  L10_2 = {}
  L11_2 = ObjectState
  L11_2 = L11_2.SetState
  L10_2.fn = L11_2
  L11_2 = {}
  L12_2 = A0_2
  L13_2 = A1_2
  L14_2 = String
  L14_2 = L14_2.GetHash
  L15_2 = "CollapseState"
  L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2 = L14_2(L15_2)
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L11_2[3] = L14_2
  L11_2[4] = L15_2
  L11_2[5] = L16_2
  L11_2[6] = L17_2
  L11_2[7] = L18_2
  L11_2[8] = L19_2
  L11_2[9] = L20_2
  L11_2[10] = L21_2
  L11_2[11] = L22_2
  L11_2[12] = L23_2
  L11_2[13] = L24_2
  L11_2[14] = L25_2
  L11_2[15] = L26_2
  L11_2[16] = L27_2
  L11_2[17] = L28_2
  L11_2[18] = L29_2
  L11_2[19] = L30_2
  L11_2[20] = L31_2
  L11_2[21] = L32_2
  L11_2[22] = L33_2
  L11_2[23] = L34_2
  L10_2.args = L11_2
  L10_2.minTime = 4
  L10_2.maxTime = 4.5
  L11_2 = {}
  L12_2 = _DestroyBuildingA
  L11_2.fn = L12_2
  L12_2 = {}
  L13_2 = A0_2
  L12_2[1] = L13_2
  L11_2.args = L12_2
  L11_2.minTime = 2
  L11_2.maxTime = 2.5
  L12_2 = {}
  L13_2 = ObjectState
  L13_2 = L13_2.StartEmitter
  L12_2.fn = L13_2
  L13_2 = {}
  L14_2 = A0_2
  L15_2 = String
  L15_2 = L15_2.GetHash
  L16_2 = "hp_fx_explosionI"
  L15_2 = L15_2(L16_2)
  L16_2 = uHugeExplosion
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L13_2[3] = L16_2
  L12_2.args = L13_2
  L12_2.minTime = 0.5
  L13_2 = {}
  L14_2 = _DestroyLinkedGuid
  L13_2.fn = L14_2
  L14_2 = {}
  L15_2 = A0_2
  L16_2 = "hp_snap_oilrig_towerblowoutdiagonal"
  L14_2[1] = L15_2
  L14_2[2] = L16_2
  L13_2.args = L14_2
  L13_2.minTime = 2
  L13_2.maxTime = 2.5
  L14_2 = {}
  L15_2 = Camera
  L15_2 = L15_2.Shake
  L14_2.fn = L15_2
  L15_2 = {}
  L16_2 = StringToGuid
  L17_2 = "0x1"
  L16_2 = L16_2(L17_2)
  L17_2 = "ShakeCameraMedium"
  L18_2 = ObjectState
  L18_2 = L18_2.GetLinkGuid
  L19_2 = A0_2
  L20_2 = String
  L20_2 = L20_2.GetHash
  L21_2 = "hp_snap_oilrig_bld_helipadlargeA"
  L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2 = L20_2(L21_2)
  L18_2 = L18_2(L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2)
  L19_2 = 0.3
  L15_2[1] = L16_2
  L15_2[2] = L17_2
  L15_2[3] = L18_2
  L15_2[4] = L19_2
  L14_2.args = L15_2
  L15_2 = {}
  L16_2 = ObjectState
  L16_2 = L16_2.StartEmitter
  L15_2.fn = L16_2
  L16_2 = {}
  L17_2 = A0_2
  L18_2 = String
  L18_2 = L18_2.GetHash
  L19_2 = "hp_fx_explosionJ"
  L18_2 = L18_2(L19_2)
  L19_2 = uHugeExplosion
  L16_2[1] = L17_2
  L16_2[2] = L18_2
  L16_2[3] = L19_2
  L15_2.args = L16_2
  L15_2.minTime = 0.2
  L16_2 = {}
  L17_2 = _DestroyLinkedGuid
  L16_2.fn = L17_2
  L17_2 = {}
  L18_2 = A0_2
  L19_2 = "hp_snap_oilrig_bld_helipadlargeA"
  L17_2[1] = L18_2
  L17_2[2] = L19_2
  L16_2.args = L17_2
  L16_2.minTime = 3
  L16_2.maxTime = 3.5
  L17_2 = {}
  L18_2 = _DestroyLinkedGuid
  L17_2.fn = L18_2
  L18_2 = {}
  L19_2 = A0_2
  L20_2 = "hp_snap_oilrig_towerdrillpipesB"
  L18_2[1] = L19_2
  L18_2[2] = L20_2
  L17_2.args = L18_2
  L18_2 = {}
  L19_2 = ObjectState
  L19_2 = L19_2.StartEmitter
  L18_2.fn = L19_2
  L19_2 = {}
  L20_2 = A0_2
  L21_2 = String
  L21_2 = L21_2.GetHash
  L22_2 = "hp_fx_explosionK"
  L21_2 = L21_2(L22_2)
  L22_2 = uHugeExplosion
  L19_2[1] = L20_2
  L19_2[2] = L21_2
  L19_2[3] = L22_2
  L18_2.args = L19_2
  L18_2.minTime = 0.8
  L19_2 = {}
  L20_2 = _DestroyLinkedGuid
  L19_2.fn = L20_2
  L20_2 = {}
  L21_2 = A0_2
  L22_2 = "hp_snap_oilrig_fueltanklargeA"
  L20_2[1] = L21_2
  L20_2[2] = L22_2
  L19_2.args = L20_2
  L19_2.minTime = 1
  L20_2 = {}
  L21_2 = _DestroyLinkedGuid
  L20_2.fn = L21_2
  L21_2 = {}
  L22_2 = A0_2
  L23_2 = "hp_snap_oilrig_fueltanklargeA_B"
  L21_2[1] = L22_2
  L21_2[2] = L23_2
  L20_2.args = L21_2
  L21_2 = {}
  L22_2 = _DestroyLinkedGuid
  L21_2.fn = L22_2
  L22_2 = {}
  L23_2 = A0_2
  L24_2 = "hp_snap_oilrig_fueltanklargeA_C"
  L22_2[1] = L23_2
  L22_2[2] = L24_2
  L21_2.args = L22_2
  L21_2.minTime = 1
  L22_2 = {}
  L23_2 = _DestroyLinkedGuid
  L22_2.fn = L23_2
  L23_2 = {}
  L24_2 = A0_2
  L25_2 = "hp_snap_oilrig_fueltanklargeA_A"
  L23_2[1] = L24_2
  L23_2[2] = L25_2
  L22_2.args = L23_2
  L23_2 = {}
  L24_2 = ObjectState
  L24_2 = L24_2.StartEmitter
  L23_2.fn = L24_2
  L24_2 = {}
  L25_2 = A0_2
  L26_2 = String
  L26_2 = L26_2.GetHash
  L27_2 = "hp_fx_explosionL"
  L26_2 = L26_2(L27_2)
  L27_2 = uLargeExplosion
  L24_2[1] = L25_2
  L24_2[2] = L26_2
  L24_2[3] = L27_2
  L23_2.args = L24_2
  L23_2.minTime = 0.5
  L24_2 = {}
  L25_2 = _DestroyLinkedGuid
  L24_2.fn = L25_2
  L25_2 = {}
  L26_2 = A0_2
  L27_2 = "hp_snap_oilrig_towerdrillpipesA"
  L25_2[1] = L26_2
  L25_2[2] = L27_2
  L24_2.args = L25_2
  L25_2 = {}
  L26_2 = ObjectState
  L26_2 = L26_2.StartEmitter
  L25_2.fn = L26_2
  L26_2 = {}
  L27_2 = A0_2
  L28_2 = String
  L28_2 = L28_2.GetHash
  L29_2 = "hp_fx_explosionM"
  L28_2 = L28_2(L29_2)
  L29_2 = uHugeExplosion
  L26_2[1] = L27_2
  L26_2[2] = L28_2
  L26_2[3] = L29_2
  L25_2.args = L26_2
  L25_2.minTime = 0.5
  L26_2 = {}
  L27_2 = ObjectState
  L27_2 = L27_2.StartEmitter
  L26_2.fn = L27_2
  L27_2 = {}
  L28_2 = A0_2
  L29_2 = String
  L29_2 = L29_2.GetHash
  L30_2 = "hp_fx_explosionN"
  L29_2 = L29_2(L30_2)
  L30_2 = uHugeExplosion
  L27_2[1] = L28_2
  L27_2[2] = L29_2
  L27_2[3] = L30_2
  L26_2.args = L27_2
  L26_2.minTime = 0.5
  L27_2 = {}
  L28_2 = Camera
  L28_2 = L28_2.Shake
  L27_2.fn = L28_2
  L28_2 = {}
  L29_2 = StringToGuid
  L30_2 = "0x1"
  L29_2 = L29_2(L30_2)
  L30_2 = "ShakeCameraMedium"
  L31_2 = ObjectState
  L31_2 = L31_2.GetLinkGuid
  L32_2 = A0_2
  L33_2 = String
  L33_2 = L33_2.GetHash
  L34_2 = "hp_snap_oilrig_towerdrill"
  L33_2, L34_2 = L33_2(L34_2)
  L31_2 = L31_2(L32_2, L33_2, L34_2)
  L32_2 = 0.8
  L28_2[1] = L29_2
  L28_2[2] = L30_2
  L28_2[3] = L31_2
  L28_2[4] = L32_2
  L27_2.args = L28_2
  L28_2 = {}
  L29_2 = _DestroyLinkedGuid
  L28_2.fn = L29_2
  L29_2 = {}
  L30_2 = A0_2
  L31_2 = "hp_snap_oilrig_towerdrill"
  L29_2[1] = L30_2
  L29_2[2] = L31_2
  L28_2.args = L29_2
  L28_2.minTime = 1.5
  L28_2.maxTime = 1.7
  L29_2 = {}
  L30_2 = _DestroyBuildingB
  L29_2.fn = L30_2
  L30_2 = {}
  L31_2 = A0_2
  L30_2[1] = L31_2
  L29_2.args = L30_2
  L29_2.minTime = 1
  L29_2.maxTime = 1.5
  L30_2 = {}
  L31_2 = _DestroyBuildingC
  L30_2.fn = L31_2
  L31_2 = {}
  L32_2 = A0_2
  L31_2[1] = L32_2
  L30_2.args = L31_2
  L30_2.minTime = 12
  L30_2.maxTime = 13
  L31_2 = {}
  L32_2 = _FinishDestruction
  L31_2.fn = L32_2
  L32_2 = {}
  L33_2 = A0_2
  L32_2[1] = L33_2
  L31_2.args = L32_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L2_2[6] = L8_2
  L2_2[7] = L9_2
  L2_2[8] = L10_2
  L2_2[9] = L11_2
  L2_2[10] = L12_2
  L2_2[11] = L13_2
  L2_2[12] = L14_2
  L2_2[13] = L15_2
  L2_2[14] = L16_2
  L2_2[15] = L17_2
  L2_2[16] = L18_2
  L2_2[17] = L19_2
  L2_2[18] = L20_2
  L2_2[19] = L21_2
  L2_2[20] = L22_2
  L2_2[21] = L23_2
  L2_2[22] = L24_2
  L2_2[23] = L25_2
  L2_2[24] = L26_2
  L2_2[25] = L27_2
  L2_2[26] = L28_2
  L2_2[27] = L29_2
  L2_2[28] = L30_2
  L2_2[29] = L31_2
  L3_2 = _ProcessNextEvent
  L4_2 = A0_2
  L5_2 = L2_2
  L6_2 = 1
  L3_2(L4_2, L5_2, L6_2)
end

_DestroyOilrigSequence = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = A1_2[A2_2]
  if not L3_2 then
    return
  end
  L4_2 = L3_2.fn
  L5_2 = unpack
  L6_2 = L3_2.args
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L5_2(L6_2)
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L4_2 = L3_2.minTime
  if not L4_2 then
    L4_2 = _ProcessNextEvent
    L5_2 = A0_2
    L6_2 = A1_2
    L7_2 = A2_2 + 1
    L4_2(L5_2, L6_2, L7_2)
  else
    L4_2 = nil
    L5_2 = L3_2.maxTime
    if L5_2 then
      L5_2 = Math
      L5_2 = L5_2.randf
      L6_2 = L3_2.minTime
      L7_2 = L3_2.maxTime
      L5_2 = L5_2(L6_2, L7_2)
      L4_2 = L5_2
    else
      L4_2 = L3_2.minTime
    end
    L5_2 = Event
    L5_2 = L5_2.Create
    L6_2 = Event
    L6_2 = L6_2.TimerRelative
    L7_2 = {}
    L8_2 = L4_2
    L7_2[1] = L8_2
    L8_2 = _ProcessNextEvent
    L9_2 = {}
    L10_2 = A0_2
    L11_2 = A1_2
    L12_2 = A2_2 + 1
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
    L6_2 = _tOilrigEvents
    L6_2 = L6_2[A0_2]
    if L6_2 then
      L7_2 = table
      L7_2 = L7_2.insert
      L8_2 = _tOilrigEvents
      L8_2 = L8_2[A0_2]
      L9_2 = L5_2
      L7_2(L8_2, L9_2)
    end
  end
end

_ProcessNextEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = ObjectState
  L2_2 = L2_2.GetLinkGuid
  L3_2 = A0_2
  L4_2 = String
  L4_2 = L4_2.GetHash
  L5_2 = A1_2
  L4_2, L5_2 = L4_2(L5_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  if not L2_2 then
  else
    L3_2 = Object
    L3_2 = L3_2.Kill
    L4_2 = L2_2
    L3_2(L4_2)
  end
end

_DestroyLinkedGuid = L0_1
