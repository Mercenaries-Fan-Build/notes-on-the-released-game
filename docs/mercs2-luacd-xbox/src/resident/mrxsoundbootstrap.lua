local L0_1, L1_1
L0_1 = import
L1_1 = "MrxSound"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxMusic"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSoundCategories"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSoundBanks"
L0_1(L1_1)

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L0_2 = Sound
  L0_2 = L0_2.DefineReverbPreset
  L1_2 = 1
  L2_2 = "CITY_KG_LIGHT_REFLECTIONS"
  L3_2 = -1000
  L4_2 = -1000
  L5_2 = 0
  L6_2 = 0.09
  L7_2 = 0.23
  L8_2 = -602
  L9_2 = 0.02
  L10_2 = -698
  L11_2 = 0.03
  L12_2 = 100
  L13_2 = 100
  L14_2 = 5000
  L15_2 = 0
  L16_2 = 5000
  L17_2 = -5000
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  L0_2 = Sound
  L0_2 = L0_2._GetLibVersion
  L0_2 = L0_2()
  if 10 <= L0_2 then
    L0_2 = Sound
    L0_2 = L0_2.SetReverbPreset
    L1_2 = "CITY_KG_LIGHT_REFLECTIONS"
    L0_2(L1_2)
  else
    L0_2 = Sound
    L0_2 = L0_2.SetReverbPreset
    L1_2 = 1
    L0_2(L1_2)
  end
  L0_2 = Sound
  L0_2 = L0_2.SetReverb
  L1_2 = 1
  L0_2(L1_2)
  L0_2 = MrxSoundCategories
  L0_2 = L0_2.SetPitchCategory
  L1_2 = "survivalmode"
  L2_2 = "non_ui"
  L3_2 = 0.5
  L4_2 = 0.5
  L5_2 = 0.5
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2)
  L0_2 = MrxSoundCategories
  L0_2 = L0_2.SetPitchCategory
  L1_2 = "survivalmode"
  L2_2 = "chatter"
  L3_2 = 0.75
  L4_2 = 0.5
  L5_2 = 0.5
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2)
  L0_2 = MrxSoundCategories
  L0_2 = L0_2.SetFadeCategory
  L1_2 = "vosequence"
  L2_2 = "non_ui"
  L3_2 = 0.3
  L4_2 = 0.5
  L5_2 = 0.5
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2)
  L0_2 = MrxSoundCategories
  L0_2 = L0_2.SetFadeCategory
  L1_2 = "vosequence"
  L2_2 = "chatter"
  L3_2 = 0.3
  L4_2 = 0.5
  L5_2 = 0.5
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2)
  L0_2 = MrxSoundCategories
  L0_2 = L0_2.SetFadeCategory
  L1_2 = "vosequence"
  L2_2 = "music"
  L3_2 = 0.4
  L4_2 = 0.5
  L5_2 = 0.5
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2)
  L0_2 = MrxSoundCategories
  L0_2 = L0_2.SetFadeCategory
  L1_2 = "actionhijack"
  L2_2 = "Non_Action_Hijack"
  L3_2 = 0.4
  L4_2 = 0.5
  L5_2 = 0.5
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2)
  L0_2 = MrxSoundCategories
  L0_2 = L0_2.SetFadeCategory
  L1_2 = "actionhijack"
  L2_2 = "chatter"
  L3_2 = 0.3
  L4_2 = 0.5
  L5_2 = 0.5
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2)
  L0_2 = MrxSoundCategories
  L0_2 = L0_2.SetFadeCategory
  L1_2 = "survivalmode"
  L2_2 = "non_ui"
  L3_2 = 0.4
  L4_2 = 0.5
  L5_2 = 0.5
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2)
  L0_2 = MrxSoundCategories
  L0_2 = L0_2.SetFadeCategory
  L1_2 = "survivalmode"
  L2_2 = "chatter"
  L3_2 = 0.3
  L4_2 = 0.5
  L5_2 = 0.5
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2)
  L0_2 = MrxSoundCategories
  L0_2 = L0_2.SetFadeCategory
  L1_2 = "survivalmode"
  L2_2 = "music"
  L3_2 = 0.5
  L4_2 = 0.5
  L5_2 = 0.5
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2)
  L0_2 = MrxSoundCategories
  L0_2 = L0_2.SetFadeCategory
  L1_2 = "fanfare"
  L2_2 = "non_ui"
  L3_2 = 0.1
  L4_2 = 0.5
  L5_2 = 0.5
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2)
  L0_2 = MrxSoundCategories
  L0_2 = L0_2.SetFadeCategory
  L1_2 = "fanfare"
  L2_2 = "vo"
  L3_2 = 0.1
  L4_2 = 0.5
  L5_2 = 0.5
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2)
  L0_2 = MrxSoundCategories
  L0_2 = L0_2.SetFadeCategory
  L1_2 = "satelliteview"
  L2_2 = "non_ui"
  L3_2 = 0.1
  L4_2 = 0.5
  L5_2 = 0.5
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2)
  L0_2 = MrxSoundCategories
  L0_2 = L0_2.SetFadeCategory
  L1_2 = "satelliteview"
  L2_2 = "chatter"
  L3_2 = 0.1
  L4_2 = 0.5
  L5_2 = 0.5
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "an"
  L2_2 = "explore"
  L3_2 = 1
  L4_2 = "mu_fac_an_explore_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "an"
  L2_2 = "action"
  L3_2 = 1
  L4_2 = "mu_fac_an_threat_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "an"
  L2_2 = "mission_success"
  L3_2 = 1
  L4_2 = "mu_fac_an_win_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "an"
  L2_2 = "mission_failure"
  L3_2 = 1
  L4_2 = "mu_fac_an_fail_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "an"
  L2_2 = "hijack"
  L3_2 = 1
  L4_2 = "mu_fac_an_hijack_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "an"
  L2_2 = "hijack"
  L3_2 = 2
  L4_2 = "mu_fac_an_hijack_02"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "an"
  L2_2 = "hijack"
  L3_2 = 3
  L4_2 = "mu_fac_an_hijack_03"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "an"
  L2_2 = "hijack_success"
  L3_2 = 1
  L4_2 = "mu_fac_an_kickass_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "an"
  L2_2 = "shell"
  L3_2 = 1
  L4_2 = "mu_shell_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "an"
  L2_2 = "pause"
  L3_2 = 1
  L4_2 = "mu_shell_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "oc"
  L2_2 = "explore"
  L3_2 = 1
  L4_2 = "mu_fac_oc_explore_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "oc"
  L2_2 = "action"
  L3_2 = 1
  L4_2 = "mu_fac_oc_threat_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "oc"
  L2_2 = "mission_success"
  L3_2 = 1
  L4_2 = "mu_fac_oc_win_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "oc"
  L2_2 = "mission_failure"
  L3_2 = 1
  L4_2 = "mu_fac_oc_fail_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "oc"
  L2_2 = "hijack"
  L3_2 = 1
  L4_2 = "mu_fac_oc_hijack_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "oc"
  L2_2 = "hijack"
  L3_2 = 2
  L4_2 = "mu_fac_oc_hijack_02"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "oc"
  L2_2 = "hijack_success"
  L3_2 = 1
  L4_2 = "mu_fac_oc_kickass_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "oc"
  L2_2 = "shell"
  L3_2 = 1
  L4_2 = "mu_shell_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "oc"
  L2_2 = "pause"
  L3_2 = 1
  L4_2 = "mu_shell_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "gr"
  L2_2 = "explore"
  L3_2 = 1
  L4_2 = "mu_fac_gr_explore_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "gr"
  L2_2 = "action"
  L3_2 = 1
  L4_2 = "mu_fac_gr_threat_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "gr"
  L2_2 = "mission_success"
  L3_2 = 1
  L4_2 = "mu_fac_gr_win_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "gr"
  L2_2 = "mission_failure"
  L3_2 = 1
  L4_2 = "mu_fac_gr_fail_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "gr"
  L2_2 = "hijack"
  L3_2 = 1
  L4_2 = "mu_fac_gr_hijack_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "gr"
  L2_2 = "hijack"
  L3_2 = 2
  L4_2 = "mu_fac_gr_hijack_02"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "gr"
  L2_2 = "hijack"
  L3_2 = 3
  L4_2 = "mu_fac_gr_hijack_03"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "gr"
  L2_2 = "hijack_success"
  L3_2 = 1
  L4_2 = "mu_fac_gr_kickass_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "gr"
  L2_2 = "shell"
  L3_2 = 1
  L4_2 = "mu_shell_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "gr"
  L2_2 = "pause"
  L3_2 = 1
  L4_2 = "mu_shell_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "ch"
  L2_2 = "explore"
  L3_2 = 1
  L4_2 = "mu_fac_ch_explore_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "ch"
  L2_2 = "action"
  L3_2 = 1
  L4_2 = "mu_fac_ch_threat_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "ch"
  L2_2 = "mission_success"
  L3_2 = 1
  L4_2 = "mu_fac_ch_win_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "ch"
  L2_2 = "mission_failure"
  L3_2 = 1
  L4_2 = "mu_fac_ch_fail_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "ch"
  L2_2 = "hijack"
  L3_2 = 1
  L4_2 = "mu_fac_ch_hijack_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "ch"
  L2_2 = "hijack"
  L3_2 = 2
  L4_2 = "mu_fac_ch_hijack_02"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "ch"
  L2_2 = "hijack"
  L3_2 = 3
  L4_2 = "mu_fac_ch_hijack_03"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "ch"
  L2_2 = "hijack_success"
  L3_2 = 1
  L4_2 = "mu_fac_ch_kickass_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "ch"
  L2_2 = "shell"
  L3_2 = 1
  L4_2 = "mu_shell_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "ch"
  L2_2 = "pause"
  L3_2 = 1
  L4_2 = "mu_shell_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "pmc"
  L2_2 = "explore"
  L3_2 = 1
  L4_2 = "mu_fac_pmc_explore_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "pmc"
  L2_2 = "action"
  L3_2 = 1
  L4_2 = "mu_fac_pmc_threat_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "pmc"
  L2_2 = "mission_success"
  L3_2 = 1
  L4_2 = "mu_fac_pmc_win_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "pmc"
  L2_2 = "mission_failure"
  L3_2 = 1
  L4_2 = "mu_fac_pmc_fail_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "pmc"
  L2_2 = "hijack"
  L3_2 = 1
  L4_2 = "mu_fac_oc_hijack_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "pmc"
  L2_2 = "hijack"
  L3_2 = 2
  L4_2 = "mu_fac_oc_hijack_02"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "pmc"
  L2_2 = "hijack_success"
  L3_2 = 1
  L4_2 = "mu_fac_pmc_kickass_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "pmc"
  L2_2 = "shell"
  L3_2 = 1
  L4_2 = "mu_shell_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "pmc"
  L2_2 = "pause"
  L3_2 = 1
  L4_2 = "mu_shell_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_city"
  L2_2 = "explore"
  L3_2 = 1
  L4_2 = "mu_nomission_city_explore_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_city"
  L2_2 = "action"
  L3_2 = 1
  L4_2 = "mu_nomission_city_threat_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_city"
  L2_2 = "high_action"
  L3_2 = 1
  L4_2 = "mu_nomission_city_threat_02"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_city"
  L2_2 = "mission_failure"
  L3_2 = 1
  L4_2 = "mu_nomission_city_fail_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_city"
  L2_2 = "mission_success"
  L3_2 = 1
  L4_2 = "mu_fac_pmc_win_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_city"
  L2_2 = "hijack"
  L3_2 = 1
  L4_2 = "mu_fac_oc_hijack_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_city"
  L2_2 = "hijack"
  L3_2 = 2
  L4_2 = "mu_fac_oc_hijack_02"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_city"
  L2_2 = "hijack_success"
  L3_2 = 1
  L4_2 = "mu_fac_pmc_kickass_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_city"
  L2_2 = "shell"
  L3_2 = 1
  L4_2 = "mu_shell_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_city"
  L2_2 = "pause"
  L3_2 = 1
  L4_2 = "mu_shell_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_jungle"
  L2_2 = "explore"
  L3_2 = 1
  L4_2 = "mu_nomission_jungle_explore_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_jungle"
  L2_2 = "action"
  L3_2 = 1
  L4_2 = "mu_nomission_jungle_threat_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_jungle"
  L2_2 = "high_action"
  L3_2 = 1
  L4_2 = "mu_nomission_jungle_threat_02"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_jungle"
  L2_2 = "mission_failure"
  L3_2 = 1
  L4_2 = "mu_nomission_jungle_fail_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_jungle"
  L2_2 = "mission_success"
  L3_2 = 1
  L4_2 = "mu_fac_pmc_win_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_jungle"
  L2_2 = "hijack"
  L3_2 = 1
  L4_2 = "mu_fac_oc_hijack_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_jungle"
  L2_2 = "hijack"
  L3_2 = 2
  L4_2 = "mu_fac_oc_hijack_02"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_jungle"
  L2_2 = "hijack_success"
  L3_2 = 1
  L4_2 = "mu_fac_pmc_kickass_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_jungle"
  L2_2 = "shell"
  L3_2 = 1
  L4_2 = "mu_shell_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_jungle"
  L2_2 = "pause"
  L3_2 = 1
  L4_2 = "mu_shell_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_water"
  L2_2 = "explore"
  L3_2 = 1
  L4_2 = "mu_nomission_water_explore_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_water"
  L2_2 = "action"
  L3_2 = 1
  L4_2 = "mu_nomission_water_threat_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_water"
  L2_2 = "high_action"
  L3_2 = 1
  L4_2 = "mu_nomission_water_threat_02"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_water"
  L2_2 = "mission_failure"
  L3_2 = 1
  L4_2 = "mu_nomission_water_fail_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_water"
  L2_2 = "mission_success"
  L3_2 = 1
  L4_2 = "mu_fac_pmc_win_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_water"
  L2_2 = "hijack"
  L3_2 = 1
  L4_2 = "mu_fac_oc_hijack_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_water"
  L2_2 = "hijack"
  L3_2 = 2
  L4_2 = "mu_fac_oc_hijack_02"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_water"
  L2_2 = "hijack_success"
  L3_2 = 1
  L4_2 = "mu_fac_pmc_kickass_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_water"
  L2_2 = "shell"
  L3_2 = 1
  L4_2 = "mu_shell_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindMusicCue
  L1_2 = "freeplay_water"
  L2_2 = "pause"
  L3_2 = 1
  L4_2 = "mu_shell_01"
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = MrxSoundCategories
  L0_2 = L0_2.SetDuckOnGlobalTableLoad
  L1_2 = true
  L0_2(L1_2)
  L0_2 = LoadBanks
  L0_2()
  L0_2 = MrxMusic
  L0_2 = L0_2.AddMusicPlaylist
  L1_2 = "mu_src_radio"
  L2_2 = 0
  L0_2(L1_2, L2_2)
  L0_2 = SetPmcRadio
  L0_2()
  L0_2 = MrxMusic
  L0_2 = L0_2.AddMusicPlaylist
  L1_2 = "mu_src_civ"
  L2_2 = 0
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_civ"
  L2_2 = "mu_src_civ"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.AddMusicPlaylist
  L1_2 = "mu_src_gr_01"
  L2_2 = 0
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_gr_01"
  L2_2 = "MU_SRC_PLAV_HQ_02"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_gr_01"
  L2_2 = "mu_src_plav_op_03"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_gr_01"
  L2_2 = "mu_src_plav_op_04"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_gr_01"
  L2_2 = "mu_src_plav_op_05"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.AddMusicPlaylist
  L1_2 = "mu_src_plav_op_01"
  L2_2 = 0
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_plav_op_01"
  L2_2 = "MU_SRC_PLAV_HQ_03"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_plav_op_01"
  L2_2 = "MU_SRC_PLAV_HQ_04"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_plav_op_01"
  L2_2 = "MU_SRC_PLAV_HQ_05"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.AddMusicPlaylist
  L1_2 = "mu_src_pmc_hq_01"
  L2_2 = 0
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_pmc_hq_01"
  L2_2 = "MU_SRC_PMC_HQ_01"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_pmc_hq_01"
  L2_2 = "MU_SRC_PMC_HQ_02"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_pmc_hq_01"
  L2_2 = "MU_SRC_PMC_HQ_03"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_pmc_hq_01"
  L2_2 = "MU_SRC_PMC_HQ_04"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_pmc_hq_01"
  L2_2 = "MU_SRC_PMC_HQ_05"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_pmc_hq_01"
  L2_2 = "MU_SRC_UP_OP_04_for_HQ"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_pmc_hq_01"
  L2_2 = "MU_SRC_UP_OP_03_for_HQ"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_pmc_hq_01"
  L2_2 = "MU_SRC_UP_OP_02_for_HQ"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.AddMusicPlaylist
  L1_2 = "mu_src_pr_hq_01"
  L2_2 = 0
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_pr_hq_01"
  L2_2 = "mu_src_pr_hq_01"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.AddMusicPlaylist
  L1_2 = "mu_src_up_hq_01"
  L2_2 = 0
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_up_hq_01"
  L2_2 = "mu_src_up_hq_01"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.AddMusicPlaylist
  L1_2 = "mu_src_up_op_01"
  L2_2 = 0
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_up_op_01"
  L2_2 = "mu_src_up_op_01"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_up_op_01"
  L2_2 = "mu_src_up_op_02"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_up_op_01"
  L2_2 = "mu_src_up_op_03"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_up_op_01"
  L2_2 = "mu_src_up_op_04"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_up_op_01"
  L2_2 = "MU_SRC_PMC_HQ_04"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.AddMusicPlaylist
  L1_2 = "mu_src_al_hq_01"
  L2_2 = 0
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_al_hq_01"
  L2_2 = "mu_src_al_hq_01"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_al_hq_01"
  L2_2 = "mu_src_al_hq_02"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_al_hq_01"
  L2_2 = "mu_src_al_hq_03"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.AddMusicPlaylist
  L1_2 = "mu_src_al_op_01"
  L2_2 = 0
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_al_op_01"
  L2_2 = "mu_src_al_op_01"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_al_op_01"
  L2_2 = "mu_src_al_op_02"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_al_op_01"
  L2_2 = "mu_src_al_op_03"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_al_op_01"
  L2_2 = "mu_src_al_op_04"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_al_op_01"
  L2_2 = "mu_src_al_op_05"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.AddMusicPlaylist
  L1_2 = "mu_src_ch_hq_01"
  L2_2 = 0
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_ch_hq_01"
  L2_2 = "mu_src_ch_hq_01"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_ch_hq_01"
  L2_2 = "mu_src_ch_hq_02"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_ch_hq_01"
  L2_2 = "mu_src_ch_hq_03"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_ch_hq_01"
  L2_2 = "mu_src_ch_hq_04"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_ch_hq_01"
  L2_2 = "mu_src_ch_hq_05"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.AddMusicPlaylist
  L1_2 = "mu_src_ch_op_01"
  L2_2 = 0
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_ch_op_01"
  L2_2 = "mu_src_ch_op_05"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.AddMusicPlaylist
  L1_2 = "mu_src_oc_hq_01"
  L2_2 = 0
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_oc_hq_01"
  L2_2 = "mu_src_oc_hq_01"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.AddMusicPlaylist
  L1_2 = "mu_src_oc_hq_01"
  L2_2 = 0
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_oc_hq_01"
  L2_2 = "mu_src_oc_hq_01"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.AddMusicPlaylist
  L1_2 = "mu_src_al_op_01_contact"
  L2_2 = 0
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_al_op_01_contact"
  L2_2 = "mu_src_al_op_01_contact"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_al_op_01_contact"
  L2_2 = "mu_src_al_op_02_contact"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_al_op_01_contact"
  L2_2 = "mu_src_al_op_03_contact"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_al_op_01_contact"
  L2_2 = "mu_src_al_op_04_contact"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_al_op_01_contact"
  L2_2 = "mu_src_al_op_05_contact"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.AddMusicPlaylist
  L1_2 = "mu_src_ch_op_01_contact"
  L2_2 = 0
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_ch_op_01_contact"
  L2_2 = "mu_src_ch_op_05_contact"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.AddMusicPlaylist
  L1_2 = "mu_src_plav_op_01_contact"
  L2_2 = 0
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_plav_op_01_contact"
  L2_2 = "MU_SRC_PLAV_HQ_03_contact"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_plav_op_01_contact"
  L2_2 = "MU_SRC_PLAV_HQ_04_contact"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_plav_op_01_contact"
  L2_2 = "MU_SRC_PLAV_HQ_05_contact"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.AddMusicPlaylist
  L1_2 = "mu_src_oc_hq_01_contact"
  L2_2 = 0
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_oc_hq_01_contact"
  L2_2 = "mu_src_oc_hq_01_contact"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.AddMusicPlaylist
  L1_2 = "mu_src_oc_op_01_contact"
  L2_2 = 0
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_oc_op_01_contact"
  L2_2 = "mu_src_up_op_01_contact"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_oc_op_01_contact"
  L2_2 = "mu_src_up_op_02_contact"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_oc_op_01_contact"
  L2_2 = "mu_src_up_op_03_contact"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_oc_op_01_contact"
  L2_2 = "mu_src_up_op_04_contact"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_src_oc_op_01_contact"
  L2_2 = "MU_SRC_PMC_HQ_04_for_UP_contact"
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.AddMusicPlaylist
  L1_2 = "mu_mission_pircon002_02"
  L2_2 = 0
  L0_2(L1_2, L2_2)
  L0_2 = MrxMusic
  L0_2 = L0_2.BindPlaylistCue
  L1_2 = "mu_mission_pircon002_02"
  L2_2 = "mu_mission_pircon002_02"
  L0_2(L1_2, L2_2)
  L0_2 = MrxSound
  L0_2 = L0_2.Initialize
  L0_2()
end

Init = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = UnloadBanks
  L0_2()
end

ExitGame = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = MrxSoundBanks
  L0_2 = L0_2._LoadRequiredAssets
  L0_2()
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadWaveBank
  L1_2 = "ambience"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "ambience"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadWaveBank
  L1_2 = "amb_birds"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "amb_birds"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadWaveBank
  L1_2 = "amb_shared"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadWaveBank
  L1_2 = "collision_shared"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "collision_shared"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadWaveBank
  L1_2 = "destruction_shared"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "destruction_shared"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadWaveBank
  L1_2 = "fol_shared"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "fol_shared"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "veh_shared"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadWaveBank
  L1_2 = "veh_shared"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "wpn_shared"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadWaveBank
  L1_2 = "wpn_shared"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "building_destruct"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadWaveBank
  L1_2 = "bulding_destruct"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "veh_support"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadWaveBank
  L1_2 = "veh_support"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "music"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadWaveBank
  L1_2 = "music"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadWaveBank
  L1_2 = "ui_hud"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "ui_hud"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadWaveBank
  L1_2 = "vo_stream"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_mattias"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_Chris"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_carmona"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_Jen"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_Fiona"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_Ewan"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_Misha"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_Misc"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_alliedSoldier_01"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_alliedSoldier_02"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_alliedSoldier_black_03"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_chinSoldier_01"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_chinSoldier_02"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_oc_merc_01"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_oc_merc_02"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_vzCiv_01"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_vzCiv_02"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_vzCiv_female_01"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_vzCiv_female_02"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_vzGurSoldier_01"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_vzGurSoldier_02"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_vzGurSoldier_female_01"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_vzSoldier_01"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_vzSoldier_02"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_pirate_01"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_pirate_02"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_pirate_female_01"
  L0_2(L1_2)
end

LoadBanks = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadWaveBank
  L1_2 = "ambience"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "ambience"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadWaveBank
  L1_2 = "amb_birds"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "amb_birds"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadWaveBank
  L1_2 = "amb_shared"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadWaveBank
  L1_2 = "collision_shared"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "collision_shared"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadWaveBank
  L1_2 = "destruction_shared"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "destruction_shared"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadWaveBank
  L1_2 = "fol_shared"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "fol_shared"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "veh_shared"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadWaveBank
  L1_2 = "veh_shared"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "wpn_shared"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadWaveBank
  L1_2 = "wpn_shared"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "building_destruct"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadWaveBank
  L1_2 = "bulding_destruct"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "veh_support"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadWaveBank
  L1_2 = "veh_support"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "music"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadWaveBank
  L1_2 = "music"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadWaveBank
  L1_2 = "ui_hud"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "ui_hud"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadWaveBank
  L1_2 = "vo_stream"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_mattias"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_Chris"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_carmona"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_Jen"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_Fiona"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_Ewan"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_Misha"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_Misc"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_alliedSoldier_01"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_alliedSoldier_02"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_alliedSoldier_black_03"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_chinSoldier_01"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_chinSoldier_02"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_oc_merc_01"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_oc_merc_02"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_vzCiv_01"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_vzCiv_02"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_vzCiv_female_01"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_vzCiv_female_02"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_vzGurSoldier_01"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_vzGurSoldier_02"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_vzGurSoldier_female_01"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_vzSoldier_01"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_vzSoldier_02"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_pirate_01"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_pirate_02"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_pirate_female_01"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2._UnloadRequiredAssets
  L0_2()
end

UnloadBanks = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxMusic
  L1_2 = L1_2.ClearMusicPlaylist
  L2_2 = "mu_src_radio"
  L1_2(L2_2)
  L1_2 = MrxMusic
  L1_2 = L1_2.BindPlaylistCue
  L2_2 = "mu_src_radio"
  L3_2 = "MU_SRC_PMC_HQ_01"
  L1_2(L2_2, L3_2)
  L1_2 = MrxMusic
  L1_2 = L1_2.BindPlaylistCue
  L2_2 = "mu_src_radio"
  L3_2 = "MU_SRC_PMC_HQ_02"
  L1_2(L2_2, L3_2)
  L1_2 = MrxMusic
  L1_2 = L1_2.BindPlaylistCue
  L2_2 = "mu_src_radio"
  L3_2 = "MU_SRC_PMC_HQ_03"
  L1_2(L2_2, L3_2)
  L1_2 = MrxMusic
  L1_2 = L1_2.BindPlaylistCue
  L2_2 = "mu_src_radio"
  L3_2 = "MU_SRC_PMC_HQ_04"
  L1_2(L2_2, L3_2)
  L1_2 = MrxMusic
  L1_2 = L1_2.BindPlaylistCue
  L2_2 = "mu_src_radio"
  L3_2 = "MU_SRC_PMC_HQ_05"
  L1_2(L2_2, L3_2)
  L1_2 = MrxMusic
  L1_2 = L1_2.BindPlaylistCue
  L2_2 = "mu_src_radio"
  L3_2 = "MU_SRC_UP_OP_04_for_HQ"
  L1_2(L2_2, L3_2)
  L1_2 = MrxMusic
  L1_2 = L1_2.BindPlaylistCue
  L2_2 = "mu_src_radio"
  L3_2 = "MU_SRC_UP_OP_03_for_HQ"
  L1_2(L2_2, L3_2)
  if A0_2 then
    L1_2 = MrxMusic
    L1_2 = L1_2.BindPlaylistCue
    L2_2 = "mu_src_radio"
    L3_2 = A0_2
    L1_2(L2_2, L3_2)
  end
end

SetPmcRadio = L0_1
