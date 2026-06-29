local L0_1, L1_1, L2_1
L0_1 = import
L1_1 = "MrxSound"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxMusic"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxSoundCategories"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxSoundBanks"
L2_1 = false
L0_1(L1_1, L2_1)

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
  L3_2 = 0.15
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
  L0_2 = LoadRequiredAssetsDLC
  L0_2()
  L0_2 = LoadResidentAssetsVZ
  L0_2()
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
  L1_2 = "DLCTest_streaming"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "DLCTest_streaming"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadWaveBank
  L1_2 = "DLCTest_resident"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "DLCTest_resident"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadWaveBank
  L1_2 = "vo_stream_DLCTest"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.LoadSoundBank
  L1_2 = "vo_resident_DLCTest"
  L0_2(L1_2)
end

LoadBanks = L0_1

function L0_1()
  local L0_2, L1_2
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
  L1_2 = "DLCTest_streaming"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "DLCTest_streaming"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadWaveBank
  L1_2 = "DLCTest_resident"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "DLCTest_resident"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadWaveBank
  L1_2 = "vo_stream_DLCTest"
  L0_2(L1_2)
  L0_2 = MrxSoundBanks
  L0_2 = L0_2.UnloadSoundBank
  L1_2 = "vo_resident_DLCTest"
  L0_2(L1_2)
  L0_2 = UnloadResidentAssetsVZ
  L0_2()
  L0_2 = UnloadRequiredAssetsDLC
  L0_2()
end

UnloadBanks = L0_1

function L0_1(A0_2)
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

_GetLocalizedName = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = string
  L1_2 = L1_2.find
  L2_2 = A0_2
  L3_2 = ".pws"
  L1_2 = L1_2(L2_2, L3_2)
  L2_2 = string
  L2_2 = L2_2.sub
  L3_2 = A0_2
  L4_2 = 1
  L5_2 = L1_2 - 1
  return L2_2(L3_2, L4_2, L5_2)
end

_StripPWSExtension = L0_1

function L0_1()
  local L0_2, L1_2
  
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
    L4_3 = string
    L4_3 = L4_3.upper
    L5_3 = L3_3
    L4_3 = L4_3(L5_3)
    L3_3 = L4_3
    L4_3 = string
    L4_3 = L4_3.upper
    L5_3 = L2_3
    L4_3 = L4_3(L5_3)
    L2_3 = L4_3
    L4_3 = Net
    L4_3 = L4_3.DLCGetMountPoint
    L4_3 = L4_3()
    L5_3 = "\\"
    L6_3 = L3_3
    L3_3 = L4_3 .. L5_3 .. L6_3
    L4_3 = L3_3
    L5_3 = "\\"
    L6_3 = L2_3
    L7_3 = ".PWS"
    L4_3 = L4_3 .. L5_3 .. L6_3 .. L7_3
    L5_3 = Sound
    L5_3 = L5_3.OpenStreamFile
    L6_3 = L4_3
    L7_3 = A0_3
    L5_3(L6_3, L7_3)
  end
  
  _OpenFile = L0_2
  L0_2 = _OpenFile
  L1_2 = "DLCTest_streaming.pws"
  L0_2(L1_2)
  L0_2 = _OpenFile
  L1_2 = "vo_stream_DLCTest.pws"
  L0_2(L1_2)
end

OpenStreamsDLC = L0_1

function L0_1()
  local L0_2, L1_2
  
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
    L4_3 = string
    L4_3 = L4_3.upper
    L5_3 = L3_3
    L4_3 = L4_3(L5_3)
    L3_3 = L4_3
    L4_3 = string
    L4_3 = L4_3.upper
    L5_3 = L2_3
    L4_3 = L4_3(L5_3)
    L2_3 = L4_3
    L4_3 = Net
    L4_3 = L4_3.DLCGetMountPoint
    L4_3 = L4_3()
    L5_3 = "\\"
    L6_3 = L3_3
    L3_3 = L4_3 .. L5_3 .. L6_3
    L4_3 = L3_3
    L5_3 = "\\"
    L6_3 = L2_3
    L7_3 = ".PWS"
    L4_3 = L4_3 .. L5_3 .. L6_3 .. L7_3
    L5_3 = Sound
    L5_3 = L5_3.CloseStreamFile
    L6_3 = L4_3
    L7_3 = A0_3
    L5_3(L6_3, L7_3)
  end
  
  _CloseFile = L0_2
  L0_2 = _CloseFile
  L1_2 = "DLCTest_streaming.pws"
  L0_2(L1_2)
  L0_2 = _CloseFile
  L1_2 = "vo_stream_DLCTest.pws"
  L0_2(L1_2)
end

CloseStreamsDLC = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = OpenStreamsDLC
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

LoadRequiredAssetsDLC = L0_1

function L0_1()
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
  L0_2 = CloseStreamsDLC
  L0_2()
end

UnloadRequiredAssetsDLC = L0_1

function L0_1()
  local L0_2, L1_2
  
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
  L1_2 = "ambience.pws"
  L0_2(L1_2)
  L0_2 = _OpenFile
  L1_2 = "music.pws"
  L0_2(L1_2)
end

OpenStreamsVZ = L0_1

function L0_1()
  local L0_2, L1_2
  
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
    L5_3 = L5_3.CloseStreamFile
    L6_3 = L4_3
    L7_3 = A0_3
    L5_3(L6_3, L7_3)
  end
  
  _CloseFile = L0_2
  L0_2 = _CloseFile
  L1_2 = "vo_stream.pws"
  L0_2(L1_2)
  L0_2 = _CloseFile
  L1_2 = "ambience.pws"
  L0_2(L1_2)
end

CloseStreamsVZ = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = OpenStreamsVZ
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

LoadResidentAssetsVZ = L0_1

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
  L0_2 = CloseStreamsVZ
  L0_2()
end

UnloadResidentAssetsVZ = L0_1
