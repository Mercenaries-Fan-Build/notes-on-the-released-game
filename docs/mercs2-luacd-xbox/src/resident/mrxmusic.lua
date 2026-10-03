local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1
L0_1 = 0
NETEVENT_ENTERFREEPLAY = L0_1
L0_1 = 1
NETEVENT_ENTERCONTRACT = L0_1
L0_1 = 2
NETEVENT_PLAYSPECIALMUSIC = L0_1
L0_1 = 3
NETEVENT_STOPSPECIALMUSIC = L0_1
L0_1 = true
_bPrevDynamic = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = Sound
  L0_2 = L0_2.IsDynamicMusic
  L0_2 = L0_2()
  _bPrevDynamic = L0_2
  L0_2 = Sound
  L0_2 = L0_2.SetDynamicMusic
  L1_2 = false
  L0_2(L1_2)
end

_DisableDynamicMusic = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = Sound
  L0_2 = L0_2.SetDynamicMusic
  L1_2 = _bPrevDynamic
  L0_2(L1_2)
end

_RestoreDynamicMusic = L0_1
L0_1 = {}
L1_1 = {}
L2_1 = {}
L3_1 = {}
L4_1 = "mu_fac_an_explore_01"
L3_1[1] = L4_1
L2_1.explore = L3_1
L3_1 = {}
L4_1 = "mu_fac_an_threat_01"
L3_1[1] = L4_1
L2_1.action = L3_1
L3_1 = {}
L4_1 = "mu_fac_an_win_01"
L3_1[1] = L4_1
L2_1.mission_success = L3_1
L3_1 = {}
L4_1 = "mu_fac_an_fail_01"
L3_1[1] = L4_1
L2_1.mission_failure = L3_1
L3_1 = {}
L4_1 = "mu_fac_an_hijack_01"
L5_1 = "mu_fac_an_hijack_02"
L6_1 = "mu_fac_an_hijack_03"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L2_1.hijack = L3_1
L3_1 = {}
L4_1 = "mu_fac_an_kickass_01"
L3_1[1] = L4_1
L2_1.hijack_success = L3_1
L3_1 = {}
L4_1 = "mu_shell_01"
L3_1[1] = L4_1
L2_1.shell = L3_1
L3_1 = {}
L4_1 = "mu_shell_01"
L3_1[1] = L4_1
L2_1.pause = L3_1
L1_1.an = L2_1
L2_1 = {}
L3_1 = {}
L4_1 = "mu_fac_oc_explore_01"
L3_1[1] = L4_1
L2_1.explore = L3_1
L3_1 = {}
L4_1 = "mu_fac_oc_threat_01"
L3_1[1] = L4_1
L2_1.action = L3_1
L3_1 = {}
L4_1 = "mu_fac_oc_win_01"
L3_1[1] = L4_1
L2_1.mission_success = L3_1
L3_1 = {}
L4_1 = "mu_fac_oc_fail_01"
L3_1[1] = L4_1
L2_1.mission_failure = L3_1
L3_1 = {}
L4_1 = "mu_fac_oc_hijack_01"
L5_1 = "mu_fac_oc_hijack_02"
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1.hijack = L3_1
L3_1 = {}
L4_1 = "mu_fac_oc_kickass_01"
L3_1[1] = L4_1
L2_1.hijack_success = L3_1
L3_1 = {}
L4_1 = "mu_shell_01"
L3_1[1] = L4_1
L2_1.shell = L3_1
L3_1 = {}
L4_1 = "mu_shell_01"
L3_1[1] = L4_1
L2_1.pause = L3_1
L1_1.oc = L2_1
L2_1 = {}
L3_1 = {}
L4_1 = "mu_fac_gr_explore_01"
L3_1[1] = L4_1
L2_1.explore = L3_1
L3_1 = {}
L4_1 = "mu_fac_gr_threat_01"
L3_1[1] = L4_1
L2_1.action = L3_1
L3_1 = {}
L4_1 = "mu_fac_gr_win_01"
L3_1[1] = L4_1
L2_1.mission_success = L3_1
L3_1 = {}
L4_1 = "mu_fac_gr_fail_01"
L3_1[1] = L4_1
L2_1.mission_failure = L3_1
L3_1 = {}
L4_1 = "mu_fac_gr_hijack_01"
L5_1 = "mu_fac_gr_hijack_02"
L6_1 = "mu_fac_gr_hijack_03"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L2_1.hijack = L3_1
L3_1 = {}
L4_1 = "mu_fac_gr_kickass_01"
L3_1[1] = L4_1
L2_1.hijack_success = L3_1
L3_1 = {}
L4_1 = "mu_shell_01"
L3_1[1] = L4_1
L2_1.shell = L3_1
L3_1 = {}
L4_1 = "mu_shell_01"
L3_1[1] = L4_1
L2_1.pause = L3_1
L1_1.gr = L2_1
L2_1 = {}
L3_1 = {}
L4_1 = "mu_fac_ch_explore_01"
L3_1[1] = L4_1
L2_1.explore = L3_1
L3_1 = {}
L4_1 = "mu_fac_ch_threat_01"
L3_1[1] = L4_1
L2_1.action = L3_1
L3_1 = {}
L4_1 = "mu_fac_ch_win_01"
L3_1[1] = L4_1
L2_1.mission_success = L3_1
L3_1 = {}
L4_1 = "mu_fac_ch_fail_01"
L3_1[1] = L4_1
L2_1.mission_failure = L3_1
L3_1 = {}
L4_1 = "mu_fac_ch_hijack_01"
L5_1 = "mu_fac_ch_hijack_02"
L6_1 = "mu_fac_ch_hijack_03"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L2_1.hijack = L3_1
L3_1 = {}
L4_1 = "mu_fac_ch_kickass_01"
L3_1[1] = L4_1
L2_1.hijack_success = L3_1
L3_1 = {}
L4_1 = "mu_shell_01"
L3_1[1] = L4_1
L2_1.shell = L3_1
L3_1 = {}
L4_1 = "mu_shell_01"
L3_1[1] = L4_1
L2_1.pause = L3_1
L1_1.ch = L2_1
L2_1 = {}
L3_1 = {}
L4_1 = "mu_fac_pmc_explore_01"
L3_1[1] = L4_1
L2_1.explore = L3_1
L3_1 = {}
L4_1 = "mu_fac_pmc_threat_01"
L3_1[1] = L4_1
L2_1.action = L3_1
L3_1 = {}
L4_1 = "mu_fac_pmc_win_01"
L3_1[1] = L4_1
L2_1.mission_success = L3_1
L3_1 = {}
L4_1 = "mu_fac_pmc_fail_01"
L3_1[1] = L4_1
L2_1.mission_failure = L3_1
L3_1 = {}
L4_1 = "mu_fac_oc_hijack_01"
L5_1 = "mu_fac_oc_hijack_02"
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1.hijack = L3_1
L3_1 = {}
L4_1 = "mu_fac_pmc_kickass_01"
L3_1[1] = L4_1
L2_1.hijack_success = L3_1
L3_1 = {}
L4_1 = "mu_shell_01"
L3_1[1] = L4_1
L2_1.shell = L3_1
L3_1 = {}
L4_1 = "mu_shell_01"
L3_1[1] = L4_1
L2_1.pause = L3_1
L1_1.pmc = L2_1
L0_1.factions = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = {}
L4_1 = "mu_nomission_city_explore_01"
L3_1[1] = L4_1
L2_1.explore = L3_1
L3_1 = {}
L4_1 = "mu_nomission_city_threat_01"
L3_1[1] = L4_1
L2_1.action = L3_1
L3_1 = {}
L4_1 = "mu_nomission_city_threat_02"
L3_1[1] = L4_1
L2_1.high_action = L3_1
L3_1 = {}
L4_1 = "mu_nomission_city_fail_01"
L3_1[1] = L4_1
L2_1.mission_failure = L3_1
L3_1 = {}
L4_1 = "mu_fac_pmc_win_01"
L3_1[1] = L4_1
L2_1.mission_success = L3_1
L3_1 = {}
L4_1 = "mu_fac_oc_hijack_01"
L5_1 = "mu_fac_oc_hijack_02"
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1.hijack = L3_1
L3_1 = {}
L4_1 = "mu_fac_pmc_kickass_01"
L3_1[1] = L4_1
L2_1.hijack_success = L3_1
L3_1 = {}
L4_1 = "mu_shell_01"
L3_1[1] = L4_1
L2_1.shell = L3_1
L3_1 = {}
L4_1 = "mu_shell_01"
L3_1[1] = L4_1
L2_1.pause = L3_1
L1_1.freeplay_city = L2_1
L2_1 = {}
L3_1 = {}
L4_1 = "mu_nomission_jungle_explore_01"
L3_1[1] = L4_1
L2_1.explore = L3_1
L3_1 = {}
L4_1 = "mu_nomission_jungle_threat_01"
L3_1[1] = L4_1
L2_1.action = L3_1
L3_1 = {}
L4_1 = "mu_nomission_jungle_threat_02"
L3_1[1] = L4_1
L2_1.high_action = L3_1
L3_1 = {}
L4_1 = "mu_nomission_jungle_fail_01"
L3_1[1] = L4_1
L2_1.mission_failure = L3_1
L3_1 = {}
L4_1 = "mu_fac_pmc_win_01"
L3_1[1] = L4_1
L2_1.mission_success = L3_1
L3_1 = {}
L4_1 = "mu_fac_oc_hijack_01"
L5_1 = "mu_fac_oc_hijack_02"
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1.hijack = L3_1
L3_1 = {}
L4_1 = "mu_fac_pmc_kickass_01"
L3_1[1] = L4_1
L2_1.hijack_success = L3_1
L3_1 = {}
L4_1 = "mu_shell_01"
L3_1[1] = L4_1
L2_1.shell = L3_1
L3_1 = {}
L4_1 = "mu_shell_01"
L3_1[1] = L4_1
L2_1.pause = L3_1
L1_1.freeplay_jungle = L2_1
L2_1 = {}
L3_1 = {}
L4_1 = "mu_nomission_water_explore_01"
L3_1[1] = L4_1
L2_1.explore = L3_1
L3_1 = {}
L4_1 = "mu_nomission_water_threat_01"
L3_1[1] = L4_1
L2_1.action = L3_1
L3_1 = {}
L4_1 = "mu_nomission_water_threat_02"
L3_1[1] = L4_1
L2_1.high_action = L3_1
L3_1 = {}
L4_1 = "mu_nomission_water_fail_01"
L3_1[1] = L4_1
L2_1.mission_failure = L3_1
L3_1 = {}
L4_1 = "mu_fac_pmc_win_01"
L3_1[1] = L4_1
L2_1.mission_success = L3_1
L3_1 = {}
L4_1 = "mu_fac_oc_hijack_01"
L5_1 = "mu_fac_oc_hijack_02"
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1.hijack = L3_1
L3_1 = {}
L4_1 = "mu_fac_pmc_kickass_01"
L3_1[1] = L4_1
L2_1.hijack_success = L3_1
L3_1 = {}
L4_1 = "mu_shell_01"
L3_1[1] = L4_1
L2_1.shell = L3_1
L3_1 = {}
L4_1 = "mu_shell_01"
L3_1[1] = L4_1
L2_1.pause = L3_1
L1_1.freeplay_water = L2_1
L0_1.freeplay = L1_1
_tMusicCues = L0_1
L0_1 = "freeplay_city"
_sRootFactionRegion = L0_1
L0_1 = "source"
_sSourceMusicState = L0_1
L0_1 = {}
L1_1 = {}
L1_1.entryState = "none"
L1_1.exitState = "none"
L2_1 = {}
L2_1.entryState = "silence"
L2_1.exitState = "silence"
L3_1 = {}
L3_1.entryState = "explore"
L3_1.exitState = "explore"
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
_tSourceMusicTransitions = L0_1
L0_1 = "hijack_success"
_sHijackSuccessMusicState = L0_1
L0_1 = "hijack_success_resume"
_sHijackResumeMusicState = L0_1
L0_1 = 5
_fNonActionInterval = L0_1
L0_1 = 15
_fActionInterval = L0_1
L0_1 = {}
L1_1 = "misc1"
L2_1 = "misc2"
L0_1[1] = L1_1
L0_1[2] = L2_1
_tMiscMusicStates = L0_1

function L0_1(A0_2)
  local L1_2
  if A0_2 < 0 then
  else
    _fActionInterval = A0_2
  end
end

SetMusicActionInterval = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  if 0 < A2_2 and A2_2 < 4 then
    L4_2 = false
    L5_2 = pairs
    L6_2 = _tMusicCues
    L5_2, L6_2, L7_2 = L5_2(L6_2)
    for L8_2, L9_2 in L5_2, L6_2, L7_2 do
      L10_2 = pairs
      L11_2 = L9_2
      L10_2, L11_2, L12_2 = L10_2(L11_2)
      for L13_2, L14_2 in L10_2, L11_2, L12_2 do
        if L13_2 == A0_2 then
          L15_2 = pairs
          L16_2 = L14_2
          L15_2, L16_2, L17_2 = L15_2(L16_2)
          for L18_2, L19_2 in L15_2, L16_2, L17_2 do
            if L18_2 == A1_2 then
              L19_2[A2_2] = A3_2
              L4_2 = true
            end
          end
        end
      end
    end
    if not L4_2 then
    else
    end
  end
end

BindMusicCue = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = pairs
  L1_2 = _tMusicCues
  L1_2 = L1_2.factions
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = _InitializeFaction
    L6_2 = L3_2
    L5_2(L6_2)
    L5_2 = _BindMusicStateCues
    L6_2 = L3_2
    L7_2 = L4_2
    L5_2(L6_2, L7_2)
  end
  L0_2 = pairs
  L1_2 = _tMusicCues
  L1_2 = L1_2.freeplay
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = _InitializeFreeplay
    L6_2 = L3_2
    L5_2(L6_2)
    L5_2 = _BindMusicStateCues
    L6_2 = L3_2
    L7_2 = L4_2
    L5_2(L6_2, L7_2)
  end
  L0_2 = Sound
  L0_2 = L0_2.SetRootFactionRegionMusic
  L1_2 = _sRootFactionRegion
  L0_2(L1_2)
  L0_2 = Sound
  L0_2 = L0_2.SetSourceMusic
  L1_2 = _sSourceMusicState
  L0_2(L1_2)
  L0_2 = Sound
  L0_2 = L0_2._GetLibVersion
  L0_2 = L0_2()
  if 11 <= L0_2 then
    L0_2 = Sound
    L0_2 = L0_2.ClearSourceMusicEntryStates
    L0_2()
    L0_2 = pairs
    L1_2 = _tSourceMusicTransitions
    L0_2, L1_2, L2_2 = L0_2(L1_2)
    for L3_2, L4_2 in L0_2, L1_2, L2_2 do
      L5_2 = Sound
      L5_2 = L5_2.AddSourceMusicEntryState
      L6_2 = L4_2.entryState
      L5_2(L6_2)
    end
  else
    L0_2 = Sound
    L0_2 = L0_2.ClearSourceMusicTransitions
    L0_2()
    L0_2 = pairs
    L1_2 = _tSourceMusicTransitions
    L0_2, L1_2, L2_2 = L0_2(L1_2)
    for L3_2, L4_2 in L0_2, L1_2, L2_2 do
      L5_2 = Sound
      L5_2 = L5_2.SetSourceMusicTransition
      L6_2 = L4_2.entryState
      L7_2 = L4_2.exitState
      L5_2(L6_2, L7_2)
    end
  end
  L0_2 = Sound
  L0_2 = L0_2.SetHijackMusic
  L1_2 = _sHijackSuccessMusicState
  L2_2 = _sHijackResumeMusicState
  L0_2(L1_2, L2_2)
  L0_2 = _evClientJoined
  if not L0_2 then
    L0_2 = Net
    L0_2 = L0_2.IsServer
    L0_2 = L0_2()
    if L0_2 then
      L0_2 = Event
      L0_2 = L0_2.CreatePersistent
      L1_2 = Event
      L1_2 = L1_2.ScriptEvent
      L2_2 = {}
      L3_2 = "mpPlayerJoin"
      
      function L4_2(A0_3)
        local L1_3, L2_3
        L1_3 = Net
        L1_3 = L1_3.IsServer
        L1_3 = L1_3()
        if L1_3 then
          L1_3 = Player
          L1_3 = L1_3.IsLocal
          L2_3 = A0_3[1]
          L1_3 = L1_3(L2_3)
          L1_3 = not L1_3
        end
        return L1_3
      end
      
      L2_2[1] = L3_2
      L2_2[2] = L4_2
      L3_2 = SendPlayerJoinEvents
      L0_2 = L0_2(L1_2, L2_2, L3_2)
      _evClientJoined = L0_2
    end
  end
end

_InitializeMusic = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = sFaction
  if L0_2 then
    L0_2 = Net
    L0_2 = L0_2.SendCustomEvent
    L1_2 = "MrxMusic"
    L2_2 = NETEVENT_ENTERCONTRACT
    L3_2 = {}
    L4_2 = sFaction
    L3_2[1] = L4_2
    L4_2 = true
    L0_2(L1_2, L2_2, L3_2, L4_2)
  else
    L0_2 = Net
    L0_2 = L0_2.SendCustomEvent
    L1_2 = "MrxMusic"
    L2_2 = NETEVENT_ENTERFREEPLAY
    L3_2 = {}
    L4_2 = true
    L0_2(L1_2, L2_2, L3_2, L4_2)
  end
  L0_2 = _sCurrentMusicCue
  if L0_2 then
    L0_2 = Net
    L0_2 = L0_2.SendCustomEvent
    L1_2 = "MrxMusic"
    L2_2 = NETEVENT_PLAYSPECIALMUSIC
    L3_2 = {}
    L4_2 = _sCurrentMusicCue
    L3_2[1] = L4_2
    L4_2 = true
    L0_2(L1_2, L2_2, L3_2, L4_2)
  else
    L0_2 = Net
    L0_2 = L0_2.SendCustomEvent
    L1_2 = "MrxMusic"
    L2_2 = NETEVENT_STOPSPECIALMUSIC
    L3_2 = {}
    L4_2 = _sStopSpecialMusicCue
    if not L4_2 then
      L4_2 = "silence"
    end
    L5_2 = 0
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L4_2 = true
    L0_2(L1_2, L2_2, L3_2, L4_2)
  end
end

SendPlayerJoinEvents = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Sound
  L1_2 = L1_2.AddFactionMusic
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "none"
  L3_2 = 15
  L4_2 = 0
  L5_2 = 0
  L6_2 = _fNonActionInterval
  L7_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "explore"
  L3_2 = 30
  L4_2 = 0
  L5_2 = 0
  L6_2 = _fNonActionInterval
  L7_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "action"
  L3_2 = 0
  L4_2 = 3
  L5_2 = 0
  L6_2 = _fActionInterval
  L7_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "mission_success"
  L3_2 = 0
  L4_2 = -1
  L5_2 = 0
  L6_2 = 0
  L7_2 = 5
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "mission_failure"
  L3_2 = 0
  L4_2 = -1
  L5_2 = 0
  L6_2 = 0
  L7_2 = 5
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "hijack"
  L3_2 = 0
  L4_2 = -1
  L5_2 = 0
  L6_2 = 0
  L7_2 = 4
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "hijack_success"
  L3_2 = 120
  L4_2 = 3
  L5_2 = 0
  L6_2 = 10
  L7_2 = 8
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "hijack_success_resume"
  L3_2 = 0
  L4_2 = -1
  L5_2 = 0
  L6_2 = 0
  L7_2 = 8
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "source"
  L3_2 = 0
  L4_2 = 0
  L5_2 = 0
  L6_2 = _fNonActionInterval
  L7_2 = 4
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "shell"
  L3_2 = 0
  L4_2 = -1
  L5_2 = 0
  L6_2 = 0
  L7_2 = 4
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = _tMiscMusicStates
  L2_2 = L2_2[1]
  L3_2 = 0
  L4_2 = -1
  L5_2 = 0
  L6_2 = 0
  L7_2 = 4
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = _tMiscMusicStates
  L2_2 = L2_2[2]
  L3_2 = 0
  L4_2 = -1
  L5_2 = 0
  L6_2 = 0
  L7_2 = 4
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "pause"
  L3_2 = 0
  L4_2 = -1
  L5_2 = 0.25
  L6_2 = 0
  L7_2 = 2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "silence"
  L3_2 = 0
  L4_2 = -1
  L5_2 = 0
  L6_2 = 0
  L7_2 = 4
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.SetActionThresholdsMusic
  L2_2 = "none"
  L3_2 = 2
  L4_2 = 0
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Sound
  L1_2 = L1_2.SetActionThresholdsMusic
  L2_2 = "explore"
  L3_2 = 2
  L4_2 = 0
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "none"
  L3_2 = "explore"
  L4_2 = 1
  L5_2 = 1
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "none"
  L3_2 = "action"
  L4_2 = 1
  L5_2 = 0
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "explore"
  L3_2 = "none"
  L4_2 = 1
  L5_2 = 1
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "explore"
  L3_2 = "action"
  L4_2 = 1
  L5_2 = 0
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "source"
  L3_2 = "action"
  L4_2 = 1
  L5_2 = 0
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "action"
  L3_2 = "explore"
  L4_2 = 1
  L5_2 = 0
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "hijack_success"
  L3_2 = "explore"
  L4_2 = 1
  L5_2 = 3
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "hijack_success"
  L3_2 = "explore"
  L4_2 = 1
  L5_2 = 0
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "hijack_success"
  L3_2 = "hijack_success_resume"
  L4_2 = 1
  L5_2 = 1
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "hijack_success_resume"
  L3_2 = "explore"
  L4_2 = 1
  L5_2 = 3
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "hijack_success_resume"
  L3_2 = "action"
  L4_2 = 1
  L5_2 = 3
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "mission_failure"
  L3_2 = "silence"
  L4_2 = 1
  L5_2 = 2
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "mission_success"
  L3_2 = "silence"
  L4_2 = 1
  L5_2 = 2
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

_InitializeFaction = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Sound
  L1_2 = L1_2.AddFactionMusic
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "none"
  L3_2 = 15
  L4_2 = 0
  L5_2 = 0
  L6_2 = _fNonActionInterval
  L7_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "explore"
  L3_2 = 30
  L4_2 = 0
  L5_2 = 0
  L6_2 = _fNonActionInterval
  L7_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "action"
  L3_2 = 0
  L4_2 = 1
  L5_2 = 0
  L6_2 = _fActionInterval
  L7_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "high_action"
  L3_2 = 0
  L4_2 = 2
  L5_2 = 0
  L6_2 = _fActionInterval
  L7_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "mission_success"
  L3_2 = 0
  L4_2 = -1
  L5_2 = 0
  L6_2 = 0
  L7_2 = 5
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "mission_failure"
  L3_2 = 0
  L4_2 = -1
  L5_2 = 0
  L6_2 = 0
  L7_2 = 5
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "hijack"
  L3_2 = 0
  L4_2 = -1
  L5_2 = 0
  L6_2 = 0
  L7_2 = 4
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "hijack_success"
  L3_2 = 120
  L4_2 = 3
  L5_2 = 0
  L6_2 = 10
  L7_2 = 8
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "hijack_success_resume"
  L3_2 = 0
  L4_2 = -1
  L5_2 = 0
  L6_2 = 0
  L7_2 = 8
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "source"
  L3_2 = 0
  L4_2 = 0
  L5_2 = 0
  L6_2 = _fNonActionInterval
  L7_2 = 4
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "shell"
  L3_2 = 0
  L4_2 = -1
  L5_2 = 0
  L6_2 = 0
  L7_2 = 4
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = _tMiscMusicStates
  L2_2 = L2_2[1]
  L3_2 = 0
  L4_2 = -1
  L5_2 = 0
  L6_2 = 0
  L7_2 = 4
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = _tMiscMusicStates
  L2_2 = L2_2[2]
  L3_2 = 0
  L4_2 = -1
  L5_2 = 0
  L6_2 = 0
  L7_2 = 4
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "pause"
  L3_2 = 0
  L4_2 = -1
  L5_2 = 0.25
  L6_2 = 0
  L7_2 = 2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicState
  L2_2 = "silence"
  L3_2 = 0
  L4_2 = -1
  L5_2 = 0
  L6_2 = 0
  L7_2 = 4
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Sound
  L1_2 = L1_2.SetActionThresholdsMusic
  L2_2 = "none"
  L3_2 = 2
  L4_2 = 0
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Sound
  L1_2 = L1_2.SetActionThresholdsMusic
  L2_2 = "explore"
  L3_2 = 2
  L4_2 = 0
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "none"
  L3_2 = "explore"
  L4_2 = 1
  L5_2 = 1
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "none"
  L3_2 = "action"
  L4_2 = 1
  L5_2 = 0
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "none"
  L3_2 = "high_action"
  L4_2 = 1
  L5_2 = 0
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "explore"
  L3_2 = "none"
  L4_2 = 1
  L5_2 = 1
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "explore"
  L3_2 = "action"
  L4_2 = 1
  L5_2 = 0
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "explore"
  L3_2 = "high_action"
  L4_2 = 1
  L5_2 = 0
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "source"
  L3_2 = "action"
  L4_2 = 1
  L5_2 = 0
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "source"
  L3_2 = "high_action"
  L4_2 = 1
  L5_2 = 0
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "action"
  L3_2 = "explore"
  L4_2 = 1
  L5_2 = 0
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "action"
  L3_2 = "high_action"
  L4_2 = 1
  L5_2 = 0
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "high_action"
  L3_2 = "explore"
  L4_2 = 1
  L5_2 = 0
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "high_action"
  L3_2 = "action"
  L4_2 = 1
  L5_2 = 0
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "hijack_success"
  L3_2 = "explore"
  L4_2 = 1
  L5_2 = 3
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "hijack_success"
  L3_2 = "explore"
  L4_2 = 1
  L5_2 = 0
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "hijack_success"
  L3_2 = "hijack_success_resume"
  L4_2 = 1
  L5_2 = 1
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "hijack_success_resume"
  L3_2 = "explore"
  L4_2 = 1
  L5_2 = 3
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "hijack_success_resume"
  L3_2 = "action"
  L4_2 = 1
  L5_2 = 3
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "hijack_success_resume"
  L3_2 = "high_action"
  L4_2 = 1
  L5_2 = 3
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "mission_failure"
  L3_2 = "silence"
  L4_2 = 1
  L5_2 = 2
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = Sound
  L1_2 = L1_2.AddMusicTransition
  L2_2 = "mission_success"
  L3_2 = "silence"
  L4_2 = 1
  L5_2 = 2
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

_InitializeFreeplay = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L2_2 = Sound
  L2_2 = L2_2.SetFactionMusic
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = pairs
  L3_2 = A1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = pairs
    L8_2 = L6_2
    L7_2, L8_2, L9_2 = L7_2(L8_2)
    for L10_2, L11_2 in L7_2, L8_2, L9_2 do
      L12_2 = Sound
      L12_2 = L12_2.BindMusicCue
      L13_2 = L11_2
      L14_2 = L5_2
      L12_2(L13_2, L14_2)
    end
  end
end

_BindMusicStateCues = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = Sound
  L0_2 = L0_2.SetDynamicMusic
  L1_2 = true
  L0_2(L1_2)
  L0_2 = true
  _bPrevDynamic = L0_2
  L0_2 = _CleanupSpecialMusic
  L0_2()
  L0_2 = false
  _bPrevFactionLock = L0_2
  L0_2 = Sound
  L0_2 = L0_2.LockFactionMusic
  L1_2 = false
  L0_2(L1_2)
  L0_2 = Sound
  L0_2 = L0_2.SetActionLevelsMusic
  L1_2 = 0
  L2_2 = 0
  L3_2 = 0
  L4_2 = 0
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = Sound
  L0_2 = L0_2.LockActionLevelMusic
  L1_2 = false
  L0_2(L1_2)
end

Reset = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = Reset
  L0_2()
  L0_2 = Sound
  L0_2 = L0_2.ActivateFactionRegionMusic
  L0_2()
  L0_2 = Sound
  L0_2 = L0_2.TransitionMusic
  L1_2 = "explore"
  L0_2(L1_2)
  L0_2 = Net
  L0_2 = L0_2.IsServer
  L0_2 = L0_2()
  if L0_2 then
    L0_2 = nil
    _sCurrentContractFaction = L0_2
    L0_2 = Net
    L0_2 = L0_2.SendCustomEvent
    L1_2 = "MrxMusic"
    L2_2 = NETEVENT_ENTERFREEPLAY
    L3_2 = {}
    L4_2 = true
    L0_2(L1_2, L2_2, L3_2, L4_2)
  end
end

EnterFreeplayMusic = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Sound
  L1_2 = L1_2.SetFactionMusic
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Sound
  L1_2 = L1_2.LockFactionMusic
  L2_2 = true
  L1_2(L2_2)
  L1_2 = Sound
  L1_2 = L1_2.TransitionMusic
  L2_2 = "explore"
  L1_2(L2_2)
  L1_2 = Net
  L1_2 = L1_2.IsServer
  L1_2 = L1_2()
  if L1_2 then
    _sCurrentContractFaction = A0_2
    L1_2 = Net
    L1_2 = L1_2.SendCustomEvent
    L2_2 = "MrxMusic"
    L3_2 = NETEVENT_ENTERCONTRACT
    L4_2 = {}
    L5_2 = A0_2
    L4_2[1] = L5_2
    L5_2 = true
    L1_2(L2_2, L3_2, L4_2, L5_2)
  end
end

EnterContractMusic = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = _CleanupSpecialMusic
  L1_2()
  if A0_2 then
    L1_2 = Sound
    L1_2 = L1_2.TransitionMusic
    L2_2 = "mission_success"
    L3_2 = true
    L1_2(L2_2, L3_2)
  else
    L1_2 = Sound
    L1_2 = L1_2.TransitionMusic
    L2_2 = "mission_failure"
    L3_2 = true
    L1_2(L2_2, L3_2)
  end
end

PlayFanfare = L0_1
L0_1 = false
_bPrevFactionLock = L0_1
L0_1 = 0
_iCurrentMiscMusicIndex = L0_1
L0_1 = false
_bPlayingSpecialMusic = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = _iCurrentMiscMusicIndex
  if L1_2 == 0 then
    L1_2 = Sound
    L1_2 = L1_2.IsFactionLockedMusic
    L1_2 = L1_2()
    _bPrevFactionLock = L1_2
  end
  L1_2 = Sound
  L1_2 = L1_2.LockFactionMusic
  L2_2 = true
  L1_2(L2_2)
  L1_2 = _SetMiscMusicIndex
  L1_2()
  L1_2 = Sound
  L1_2 = L1_2.ClearMusicCues
  L2_2 = _tMiscMusicStates
  L3_2 = _iCurrentMiscMusicIndex
  L2_2 = L2_2[L3_2]
  L1_2(L2_2)
  L1_2 = Sound
  L1_2 = L1_2.BindMusicCue
  L2_2 = A0_2
  L3_2 = _tMiscMusicStates
  L4_2 = _iCurrentMiscMusicIndex
  L3_2 = L3_2[L4_2]
  L1_2(L2_2, L3_2)
  L1_2 = Sound
  L1_2 = L1_2.TransitionMusic
  L2_2 = _tMiscMusicStates
  L3_2 = _iCurrentMiscMusicIndex
  L2_2 = L2_2[L3_2]
  L1_2(L2_2)
  L1_2 = Net
  L1_2 = L1_2.IsServer
  L1_2 = L1_2()
  if L1_2 then
    _sCurrentMusicCue = A0_2
    L1_2 = Net
    L1_2 = L1_2.SendCustomEvent
    L2_2 = "MrxMusic"
    L3_2 = NETEVENT_PLAYSPECIALMUSIC
    L4_2 = {}
    L5_2 = A0_2
    L4_2[1] = L5_2
    L5_2 = true
    L1_2(L2_2, L3_2, L4_2, L5_2)
  end
  L1_2 = true
  _bPlayingSpecialMusic = L1_2
end

PlaySpecialMusic = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _iCurrentMiscMusicIndex
  if 1 < L0_2 then
    L0_2 = _iCurrentMiscMusicIndex
    L0_2 = L0_2 - 1
    _iCurrentMiscMusicIndex = L0_2
  else
    L0_2 = _iCurrentMiscMusicIndex
    L0_2 = L0_2 + 1
    _iCurrentMiscMusicIndex = L0_2
  end
end

_SetMiscMusicIndex = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = _bPlayingSpecialMusic
  if L0_2 then
    L0_2 = Sound
    L0_2 = L0_2.TransitionMusic
    L1_2 = _tMiscMusicStates
    L2_2 = _iCurrentMiscMusicIndex
    L1_2 = L1_2[L2_2]
    L0_2(L1_2)
  end
end

_ResumeSpecialMusic = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _bPlayingSpecialMusic
  return L0_2
end

_IsPlayingSpecialMusic = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = _bPlayingSpecialMusic
  if L1_2 then
    L1_2 = _CleanupSpecialMusic
    L1_2()
    if A0_2 then
      L1_2 = Sound
      L1_2 = L1_2.TransitionMusic
      L2_2 = A0_2
      L1_2(L2_2)
    else
      L1_2 = Sound
      L1_2 = L1_2.TransitionMusic
      L2_2 = "none"
      L1_2(L2_2)
    end
    L1_2 = Net
    L1_2 = L1_2.IsServer
    L1_2 = L1_2()
    if L1_2 then
      L1_2 = nil
      _sCurrentMusicCue = L1_2
      _sStopSpecialMusicCue = A0_2
      L1_2 = Net
      L1_2 = L1_2.SendCustomEvent
      L2_2 = "MrxMusic"
      L3_2 = NETEVENT_STOPSPECIALMUSIC
      L4_2 = {}
      L5_2 = A0_2 or L5_2
      if not A0_2 then
        L5_2 = "none"
      end
      L6_2 = 0
      L4_2[1] = L5_2
      L4_2[2] = L6_2
      L5_2 = true
      L1_2(L2_2, L3_2, L4_2, L5_2)
    end
  end
end

StopSpecialMusic = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = _bPlayingSpecialMusic
  if L0_2 then
    L0_2 = Sound
    L0_2 = L0_2.LockFactionMusic
    L1_2 = _bPrevFactionLock
    L0_2(L1_2)
    L0_2 = 0
    _iCurrentMiscMusicIndex = L0_2
    L0_2 = false
    _bPlayingSpecialMusic = L0_2
    L0_2 = Net
    L0_2 = L0_2.IsServer
    L0_2 = L0_2()
    if L0_2 then
      L0_2 = nil
      _sCurrentMusicCue = L0_2
      L0_2 = Net
      L0_2 = L0_2.SendCustomEvent
      L1_2 = "MrxMusic"
      L2_2 = NETEVENT_STOPSPECIALMUSIC
      L3_2 = {}
      L4_2 = sNewState
      if not L4_2 then
        L4_2 = "none"
      end
      L5_2 = 1
      L3_2[1] = L4_2
      L3_2[2] = L5_2
      L4_2 = true
      L0_2(L1_2, L2_2, L3_2, L4_2)
    end
  end
end

_CleanupSpecialMusic = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = Sound
  L2_2 = L2_2.AddMusicSourcePlaylist
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

AddMusicPlaylist = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = Sound
  L2_2 = L2_2.AddCueToMusicSourcePlaylist
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

BindPlaylistCue = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = Sound
  L1_2 = L1_2.ClearMusicSourcePlaylist
  L2_2 = A0_2
  L1_2(L2_2)
end

ClearMusicPlaylist = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = pairs
  L2_2 = _tMusicCues
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = pairs
    L7_2 = L5_2
    L6_2, L7_2, L8_2 = L6_2(L7_2)
    for L9_2, L10_2 in L6_2, L7_2, L8_2 do
      L11_2 = String
      L11_2 = L11_2.GetHash
      L12_2 = L9_2
      L11_2 = L11_2(L12_2)
      if L11_2 == A0_2 then
        return L9_2
      end
    end
  end
  L1_2 = nil
  return L1_2
end

GetFactionByStringHash = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L1_2 = pairs
  L2_2 = _tMusicCues
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = pairs
    L7_2 = L5_2
    L6_2, L7_2, L8_2 = L6_2(L7_2)
    for L9_2, L10_2 in L6_2, L7_2, L8_2 do
      L11_2 = pairs
      L12_2 = L10_2
      L11_2, L12_2, L13_2 = L11_2(L12_2)
      for L14_2, L15_2 in L11_2, L12_2, L13_2 do
        L16_2 = String
        L16_2 = L16_2.GetHash
        L17_2 = L14_2
        L16_2 = L16_2(L17_2)
        if L16_2 == A0_2 then
          return L14_2
        end
      end
    end
  end
  L1_2 = "silence"
  return L1_2
end

GetStateByStringHash = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = NETEVENT_ENTERFREEPLAY
  if A0_2 == L2_2 then
    L2_2 = EnterFreeplayMusic
    L2_2()
  else
    L2_2 = NETEVENT_ENTERCONTRACT
    if A0_2 == L2_2 then
      L2_2 = GetFactionByStringHash
      L3_2 = A1_2[1]
      L2_2 = L2_2(L3_2)
      if L2_2 then
        L3_2 = EnterContractMusic
        L4_2 = L2_2
        L3_2(L4_2)
      else
      end
    else
      L2_2 = NETEVENT_PLAYSPECIALMUSIC
      if A0_2 == L2_2 then
        L2_2 = PlaySpecialMusic
        L3_2 = A1_2[1]
        L2_2(L3_2)
      else
        L2_2 = NETEVENT_STOPSPECIALMUSIC
        if A0_2 == L2_2 then
          L2_2 = GetStateByStringHash
          L3_2 = A1_2[1]
          L2_2 = L2_2(L3_2)
          L3_2 = A1_2[2]
          if L3_2 == 1 then
            L3_2 = _CleanupSpecialMusic
            L3_2()
          else
            L3_2 = StopSpecialMusic
            L4_2 = L2_2
            L3_2(L4_2)
          end
        end
      end
    end
  end
end

NetEventCallback = L0_1
