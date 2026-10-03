local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1
L0_1 = import
L1_1 = "WifEquipmentData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUnlockFanfare"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifMissionData"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifMissionFlow"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = {}
L0_1.none = 0
L0_1.chapter_one_tiny = 5000
L0_1.chapter_one_small = 100000
L0_1.chapter_one_medium = 300000
L0_1.chapter_one_large = 500000
L0_1.chapter_one_boss = 750000
L0_1.chapter_two_tiny = 50000
L0_1.chapter_two_small = 500000
L0_1.chapter_two_medium = 1000000
L0_1.chapter_two_large = 2000000
L0_1.chapter_two_boss = 2000000
_tCashReward = L0_1
L0_1 = {}
L0_1.none = 0
L0_1.chapter_one_tiny = 5
L0_1.chapter_one_small = 100
L0_1.chapter_one_medium = 250
L0_1.chapter_one_large = 500
L0_1.chapter_one_boss = 1000
L0_1.chapter_two_tiny = 10
L0_1.chapter_two_small = 200
L0_1.chapter_two_medium = 500
L0_1.chapter_two_large = 1000
L0_1.chapter_two_boss = 2500
_tFuelReward = L0_1
L0_1 = {}
L0_1.none = 0
L0_1.chapter_one_tiny = 5
L0_1.chapter_one_small = 25
L0_1.chapter_one_medium = 50
L0_1.chapter_one_large = 75
L0_1.chapter_one_boss = 100
L0_1.chapter_two_tiny = 5
L0_1.chapter_two_small = 25
L0_1.chapter_two_medium = 50
L0_1.chapter_two_large = 75
L0_1.chapter_two_boss = 100
_tMoodReward = L0_1
L0_1 = {}
L1_1 = {}
L2_1 = {}
L3_1 = {}
L4_1 = "al"
L5_1 = "All"
L3_1[1] = L4_1
L3_1[2] = L5_1
L4_1 = {}
L5_1 = "c4"
L6_1 = "All"
L4_1[1] = L5_1
L4_1[2] = L6_1
L5_1 = {}
L6_1 = "gl"
L7_1 = "All"
L5_1[1] = L6_1
L5_1[2] = L7_1
L6_1 = {}
L7_1 = "lightmg"
L8_1 = "All"
L6_1[1] = L7_1
L6_1[2] = L8_1
L7_1 = {}
L8_1 = "combatairpatrol"
L9_1 = "All"
L7_1[1] = L8_1
L7_1[2] = L9_1
L8_1 = {}
L9_1 = "tankbuster"
L10_1 = "All"
L8_1[1] = L9_1
L8_1[2] = L10_1
L9_1 = {}
L10_1 = "hmmwvsofttop"
L11_1 = "All"
L9_1[1] = L10_1
L9_1[2] = L11_1
L10_1 = {}
L11_1 = "ch"
L12_1 = "Chi"
L10_1[1] = L11_1
L10_1[2] = L12_1
L11_1 = {}
L12_1 = "c4"
L13_1 = "Chi"
L11_1[1] = L12_1
L11_1[2] = L13_1
L12_1 = {}
L13_1 = "sniperch"
L14_1 = "Chi"
L12_1[1] = L13_1
L12_1[2] = L14_1
L13_1 = {}
L14_1 = "nglv50cal"
L15_1 = "Chi"
L13_1[1] = L14_1
L13_1[2] = L15_1
L14_1 = {}
L15_1 = "bombingrun"
L16_1 = "Chi"
L14_1[1] = L15_1
L14_1[2] = L16_1
L15_1 = {}
L16_1 = "artillery"
L17_1 = "Chi"
L15_1[1] = L16_1
L15_1[2] = L17_1
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L2_1[4] = L6_1
L2_1[5] = L7_1
L2_1[6] = L8_1
L2_1[7] = L9_1
L2_1[8] = L10_1
L2_1[9] = L11_1
L2_1[10] = L12_1
L2_1[11] = L13_1
L2_1[12] = L14_1
L2_1[13] = L15_1
L1_1.tSupport = L2_1
L0_1.AllChiIntro = L1_1
L1_1 = {}
L1_1.nCash = 10000000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_large
L2_1.All = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "[AllCon001.Terms.reward]"
L2_1[1] = L3_1
L1_1.tCustomRewards = L2_1
L0_1.AllCon001 = L1_1
L1_1 = {}
L1_1.nCash = 5000000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_large
L2_1.All = L3_1
L1_1.tAttitude = L2_1
L0_1.AllCon002 = L1_1
L1_1 = {}
L1_1.nCash = 25000000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_boss
L2_1.All = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "[AllCon003.Terms.Reward]"
L2_1[1] = L3_1
L1_1.tCustomRewards = L2_1
L0_1.AllCon003 = L1_1
L1_1 = {}
L2_1 = _tCashReward
L2_1 = L2_1.chapter_two_medium
L1_1.nCash = L2_1
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_one_small
L2_1.All = L3_1
L1_1.tAttitude = L2_1
L0_1.AllCon008 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "hmmwvarmoredtow"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.AllCon008_Milestone1 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "clusterbomb"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.AllCon008_Milestone2 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "ah1z"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.AllCon008_Milestone3 = L1_1
L1_1 = {}
L2_1 = _tCashReward
L2_1 = L2_1.chapter_two_medium
L1_1.nCash = L2_1
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_medium
L2_1.All = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "atal"
L4_1 = "amal"
L5_1 = "laserguidedbomb"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tSupport = L2_1
L2_1 = {}
L3_1 = "FuelTank10"
L2_1[1] = L3_1
L1_1.tEquipment = L2_1
L2_1 = {}
L3_1 = {}
L4_1 = "carpetbomb"
L5_1 = 2
L3_1[1] = L4_1
L3_1[2] = L5_1
L4_1 = {}
L5_1 = "laviiimgs"
L6_1 = 1
L4_1[1] = L5_1
L4_1[2] = L6_1
L2_1[1] = L3_1
L2_1[2] = L4_1
L1_1.tStockpile = L2_1
L0_1.AllCon050 = L1_1
L1_1 = {}
L2_1 = _tCashReward
L2_1 = L2_1.chapter_two_medium
L1_1.nCash = L2_1
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_medium
L2_1.All = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "laviiimgs"
L4_1 = "aa"
L2_1[1] = L3_1
L2_1[2] = L4_1
L1_1.tSupport = L2_1
L2_1 = {}
L3_1 = "FuelTank12"
L2_1[1] = L3_1
L1_1.tEquipment = L2_1
L2_1 = {}
L3_1 = {}
L4_1 = "m2a3"
L5_1 = 1
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1[1] = L3_1
L1_1.tStockpile = L2_1
L0_1.AllCon052 = L1_1
L1_1 = {}
L2_1 = _tCashReward
L2_1 = L2_1.chapter_two_medium
L1_1.nCash = L2_1
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_medium
L2_1.All = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "m2a3"
L4_1 = "laviiiat"
L2_1[1] = L3_1
L2_1[2] = L4_1
L1_1.tSupport = L2_1
L2_1 = {}
L3_1 = "FuelTank11"
L2_1[1] = L3_1
L1_1.tEquipment = L2_1
L0_1.AllCon053 = L1_1
L1_1 = {}
L1_1.nCash = 1000000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_small
L2_1.All = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "hmmwvarmored50cal"
L4_1 = "bombingrun"
L2_1[1] = L3_1
L2_1[2] = L4_1
L1_1.tSupport = L2_1
L0_1.AllJob002_Milestone1 = L1_1
L1_1 = {}
L1_1.nCash = 1250000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_small
L2_1.All = L3_1
L1_1.tAttitude = L2_1
L0_1.AllJob002_Milestone2 = L1_1
L1_1 = {}
L1_1.nCash = 1500000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_small
L2_1.All = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "surgicalstrike"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.AllJob002_Milestone3 = L1_1
L1_1 = {}
L1_1.nCash = 2000000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_small
L2_1.All = L3_1
L1_1.tAttitude = L2_1
L0_1.AllJob002_Milestone4 = L1_1
L1_1 = {}
L1_1.nCash = 2500000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_small
L2_1.All = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "mh53j"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.AllJob002_Milestone5 = L1_1
L1_1 = {}
L1_1.nCash = 3000000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_small
L2_1.All = L3_1
L1_1.tAttitude = L2_1
L0_1.AllJob002_Milestone6 = L1_1
L1_1 = {}
L1_1.nCash = 4000000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_small
L2_1.All = L3_1
L1_1.tAttitude = L2_1
L0_1.AllJob002_Milestone7 = L1_1
L1_1 = {}
L1_1.nCash = 5000000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_small
L2_1.All = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "laviii50cal"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.AllJob002_Milestone8 = L1_1
L1_1 = {}
L1_1.nCash = 7000000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_small
L2_1.All = L3_1
L1_1.tAttitude = L2_1
L0_1.AllJob002_Milestone9 = L1_1
L1_1 = {}
L1_1.nCash = 10000000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_small
L2_1.All = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "moab"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.AllJob002_Milestone10 = L1_1
L1_1 = {}
L2_1 = _tCashReward
L2_1 = L2_1.chapter_two_tiny
L1_1.nCash = L2_1
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_tiny
L2_1.All = L3_1
L1_1.tAttitude = L2_1
L0_1.AllJob003_PerTarget = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "laviii25mm"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.AllJob003_Milestone1 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "daisycutter"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L2_1 = {}
L3_1 = {}
L4_1 = "cruisemissile"
L5_1 = 2
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1[1] = L3_1
L1_1.tStockpile = L2_1
L0_1.AllJob003_Milestone2 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "laviiimewss"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.AllJob003_Milestone3 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "carpetbomb"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.AllJob003_Milestone4 = L1_1
L1_1 = {}
L2_1 = _tCashReward
L2_1 = L2_1.chapter_two_small
L1_1.nCash = L2_1
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_small
L2_1.All = L3_1
L1_1.tAttitude = L2_1
L0_1.AllJob020_PerTarget = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "hmmwvarmoredgl"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L2_1 = {}
L3_1 = {}
L4_1 = "clusterbomb"
L5_1 = 2
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1[1] = L3_1
L1_1.tStockpile = L2_1
L0_1.AllJob020_Milestone1 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "smartbomb"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L2_1 = {}
L3_1 = {}
L4_1 = "ah1z"
L5_1 = 1
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1[1] = L3_1
L1_1.tStockpile = L2_1
L0_1.AllJob020_Milestone2 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "bunkerbuster"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.AllJob020_Milestone3 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "cruisemissile"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.AllJob020_Milestone4 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "laviiiad"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.AllJob020_Milestone5 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "hmmwvavenger"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.AllJob020_Milestone6 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "m1a2"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.AllJob020_Milestone7 = L1_1
L1_1 = {}
L1_1.nCash = 5000000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_large
L2_1.Chi = L3_1
L1_1.tAttitude = L2_1
L0_1.ChiCon001 = L1_1
L1_1 = {}
L1_1.nCash = 10000000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_large
L2_1.Chi = L3_1
L1_1.tAttitude = L2_1
L0_1.ChiCon002 = L1_1
L1_1 = {}
L1_1.nCash = 25000000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_boss
L2_1.Chi = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "[AllCon003.Terms.Reward]"
L2_1[1] = L3_1
L1_1.tCustomRewards = L2_1
L0_1.ChiCon003 = L1_1
L1_1 = {}
L2_1 = _tCashReward
L2_1 = L2_1.chapter_two_medium
L1_1.nCash = L2_1
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_small
L2_1.Chi = L3_1
L1_1.tAttitude = L2_1
L0_1.ChiCon008 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = {}
L4_1 = "sx2150mlrs"
L5_1 = 1
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1[1] = L3_1
L1_1.tStockpile = L2_1
L0_1.ChiCon008_Milestone1 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "wz551"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.ChiCon008_Milestone2 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "mi26ch"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.ChiCon008_Milestone3 = L1_1
L1_1 = {}
L2_1 = _tCashReward
L2_1 = L2_1.chapter_two_medium
L1_1.nCash = L2_1
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_small
L2_1.Chi = L3_1
L1_1.tAttitude = L2_1
L0_1.ChiCon009 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "sx2150mlrs"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.ChiCon009_Milestone1 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "clusterbomb"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.ChiCon009_Milestone2 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "pgz95"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.ChiCon009_Milestone3 = L1_1
L1_1 = {}
L2_1 = _tCashReward
L2_1 = L2_1.chapter_two_medium
L1_1.nCash = L2_1
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_medium
L2_1.Chi = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "tankbuster"
L4_1 = "plz45"
L5_1 = "aa"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tSupport = L2_1
L2_1 = {}
L3_1 = "FuelTank13"
L2_1[1] = L3_1
L1_1.tEquipment = L2_1
L2_1 = {}
L3_1 = {}
L4_1 = "rocketartillery"
L5_1 = 2
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1[1] = L3_1
L1_1.tStockpile = L2_1
L0_1.ChiCon050 = L1_1
L1_1 = {}
L2_1 = _tCashReward
L2_1 = L2_1.chapter_two_medium
L1_1.nCash = L2_1
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_medium
L2_1.Chi = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "zbd2000"
L4_1 = "atch"
L5_1 = "fuelairbomb"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tSupport = L2_1
L2_1 = {}
L3_1 = "FuelTank14"
L2_1[1] = L3_1
L1_1.tEquipment = L2_1
L2_1 = {}
L3_1 = {}
L4_1 = "pgz95"
L5_1 = 1
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1[1] = L3_1
L1_1.tStockpile = L2_1
L0_1.ChiCon051 = L1_1
L1_1 = {}
L2_1 = _tCashReward
L2_1 = L2_1.chapter_two_medium
L1_1.nCash = L2_1
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_medium
L2_1.Chi = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "ztz63a"
L4_1 = "rocketartillery"
L2_1[1] = L3_1
L2_1[2] = L4_1
L1_1.tSupport = L2_1
L2_1 = {}
L3_1 = "FuelTank9"
L2_1[1] = L3_1
L1_1.tEquipment = L2_1
L0_1.ChiCon053 = L1_1
L1_1 = {}
L1_1.nCash = 1000000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_small
L2_1.Chi = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "combatairpatrol"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.ChiJob002_Milestone1 = L1_1
L1_1 = {}
L1_1.nCash = 1250000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_small
L2_1.Chi = L3_1
L1_1.tAttitude = L2_1
L0_1.ChiJob002_Milestone2 = L1_1
L1_1 = {}
L1_1.nCash = 1500000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_small
L2_1.Chi = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = {}
L4_1 = "clusterbomb"
L5_1 = 2
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1[1] = L3_1
L1_1.tStockpile = L2_1
L0_1.ChiJob002_Milestone3 = L1_1
L1_1 = {}
L1_1.nCash = 2000000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_small
L2_1.Chi = L3_1
L1_1.tAttitude = L2_1
L0_1.ChiJob002_Milestone4 = L1_1
L1_1 = {}
L1_1.nCash = 2500000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_small
L2_1.Chi = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "strategicmissile"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.ChiJob002_Milestone5 = L1_1
L1_1 = {}
L1_1.nCash = 3000000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_small
L2_1.Chi = L3_1
L1_1.tAttitude = L2_1
L0_1.ChiJob002_Milestone6 = L1_1
L1_1 = {}
L1_1.nCash = 4000000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_medium
L2_1.Chi = L3_1
L1_1.tAttitude = L2_1
L0_1.ChiJob002_Milestone7 = L1_1
L1_1 = {}
L1_1.nCash = 5000000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_medium
L2_1.Chi = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = {}
L4_1 = "wz10"
L5_1 = 1
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1[1] = L3_1
L1_1.tStockpile = L2_1
L0_1.ChiJob002_Milestone8 = L1_1
L1_1 = {}
L1_1.nCash = 7000000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_medium
L2_1.Chi = L3_1
L1_1.tAttitude = L2_1
L0_1.ChiJob002_Milestone9 = L1_1
L1_1 = {}
L1_1.nCash = 10000000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_large
L2_1.Chi = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "laserguidedbomb"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.ChiJob002_Milestone10 = L1_1
L1_1 = {}
L2_1 = _tCashReward
L2_1 = L2_1.chapter_two_tiny
L1_1.nCash = L2_1
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_tiny
L2_1.Chi = L3_1
L1_1.tAttitude = L2_1
L0_1.ChiJob003_PerTarget = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = {}
L4_1 = "ztz63a"
L5_1 = 1
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1[1] = L3_1
L1_1.tStockpile = L2_1
L0_1.ChiJob003_Milestone1 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = {}
L4_1 = "strategicmissile"
L5_1 = 2
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1[1] = L3_1
L1_1.tStockpile = L2_1
L0_1.ChiJob003_Milestone2 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "ka29b"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.ChiJob003_Milestone3 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "wz10"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.ChiJob003_Milestone4 = L1_1
L1_1 = {}
L2_1 = _tCashReward
L2_1 = L2_1.chapter_two_small
L1_1.nCash = L2_1
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_two_small
L2_1.Chi = L3_1
L1_1.tAttitude = L2_1
L0_1.ChiJob020_PerTarget = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "amch"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.ChiJob020_Milestone1 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "pgz95command"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.ChiJob020_Milestone2 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "nglvgl"
L4_1 = "surgicalstrike"
L2_1[1] = L3_1
L2_1[2] = L4_1
L1_1.tSupport = L2_1
L0_1.ChiJob020_Milestone3 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "ztz98"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.ChiJob020_Milestone4 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = {}
L4_1 = "uh1transportgr"
L5_1 = "Gur"
L3_1[1] = L4_1
L3_1[2] = L5_1
L4_1 = {}
L5_1 = "gr"
L6_1 = "Gur"
L4_1[1] = L5_1
L4_1[2] = L6_1
L5_1 = {}
L6_1 = "m151softtopgr"
L7_1 = "Gur"
L5_1[1] = L6_1
L5_1[2] = L7_1
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tSupport = L2_1
L0_1.GurIntro = L1_1
L1_1 = {}
L1_1.nCash = 850000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_one_large
L2_1.Gur = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "[GurCon001.Terms.BonusPayment]"
L2_1[1] = L3_1
L1_1.tCustomRewards = L2_1
L0_1.GurCon001 = L1_1
L1_1 = {}
L1_1.nCash = 750000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_one_large
L2_1.Gur = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "[GurCon002.Terms.BonusPayment]"
L2_1[1] = L3_1
L1_1.tCustomRewards = L2_1
L0_1.GurCon002 = L1_1
L1_1 = {}
L2_1 = _tCashReward
L2_1 = L2_1.chapter_one_medium
L1_1.nCash = L2_1
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_one_small
L2_1.Gur = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "[GurCon003.Objectives.bonus]"
L2_1[1] = L3_1
L1_1.tCustomRewards = L2_1
L0_1.GurCon003 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = {}
L4_1 = "m113aagr"
L5_1 = 1
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1[1] = L3_1
L1_1.tStockpile = L2_1
L0_1.GurCon003_Milestone1 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "junkers"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.GurCon003_Milestone2 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "piranha"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.GurCon003_Milestone3 = L1_1
L1_1 = {}
L2_1 = _tCashReward
L2_1 = L2_1.chapter_one_medium
L1_1.nCash = L2_1
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_one_medium
L2_1.Gur = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "endriagoattack"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.GurCon005 = L1_1
L1_1 = {}
L2_1 = _tCashReward
L2_1 = L2_1.chapter_one_medium
L1_1.nCash = L2_1
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_one_medium
L2_1.Gur = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "m551"
L4_1 = "sniperch"
L2_1[1] = L3_1
L2_1[2] = L4_1
L1_1.tSupport = L2_1
L2_1 = {}
L3_1 = "FuelTank8"
L2_1[1] = L3_1
L1_1.tEquipment = L2_1
L0_1.GurCon050 = L1_1
L1_1 = {}
L2_1 = _tCashReward
L2_1 = L2_1.chapter_one_medium
L1_1.nCash = L2_1
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_one_medium
L2_1.Gur = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "endriagosuperiority"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L2_1 = {}
L3_1 = "FuelTank6"
L2_1[1] = L3_1
L1_1.tEquipment = L2_1
L0_1.GurCon052 = L1_1
L1_1 = {}
L2_1 = _tCashReward
L2_1 = L2_1.chapter_one_medium
L1_1.nCash = L2_1
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_one_medium
L2_1.Gur = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "m113gr"
L4_1 = "artillery"
L5_1 = "Support"
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L1_1.tSupport = L2_1
L2_1 = {}
L3_1 = "FuelTank7"
L2_1[1] = L3_1
L1_1.tEquipment = L2_1
L0_1.GurCon053 = L1_1
L1_1 = {}
L2_1 = _tCashReward
L2_1 = L2_1.chapter_one_tiny
L1_1.nCash = L2_1
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_one_tiny
L2_1.Gur = L3_1
L1_1.tAttitude = L2_1
L0_1.GurJob001_PerTarget = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "c4"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.GurJob001_Milestone1 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "m15150calgr"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.GurJob001_Milestone2 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = {}
L4_1 = "endriagoelite"
L5_1 = 1
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1[1] = L3_1
L1_1.tStockpile = L2_1
L0_1.GurJob001_Milestone3 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "tankbuster"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.GurJob001_Milestone4 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "endriagoelite"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.GurJob001_Milestone5 = L1_1
L1_1 = {}
L1_1.nCash = 150000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_one_small
L2_1.Gur = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "turbosquidgr"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.GurJob002_Milestone1 = L1_1
L1_1 = {}
L1_1.nCash = 200000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_one_small
L2_1.Gur = L3_1
L1_1.tAttitude = L2_1
L0_1.GurJob002_Milestone2 = L1_1
L1_1 = {}
L1_1.nCash = 250000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_one_small
L2_1.Gur = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = {}
L4_1 = "bombingrun"
L5_1 = 3
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1[1] = L3_1
L1_1.tStockpile = L2_1
L0_1.GurJob002_Milestone3 = L1_1
L1_1 = {}
L1_1.nCash = 300000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_one_small
L2_1.Gur = L3_1
L1_1.tAttitude = L2_1
L0_1.GurJob002_Milestone4 = L1_1
L1_1 = {}
L1_1.nCash = 400000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_one_small
L2_1.Gur = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = {}
L4_1 = "daisycutter"
L5_1 = 3
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1[1] = L3_1
L1_1.tStockpile = L2_1
L0_1.GurJob002_Milestone5 = L1_1
L1_1 = {}
L1_1.nCash = 500000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_one_medium
L2_1.Gur = L3_1
L1_1.tAttitude = L2_1
L0_1.GurJob002_Milestone6 = L1_1
L1_1 = {}
L1_1.nCash = 700000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_one_medium
L2_1.Gur = L3_1
L1_1.tAttitude = L2_1
L0_1.GurJob002_Milestone7 = L1_1
L1_1 = {}
L1_1.nCash = 1000000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_one_medium
L2_1.Gur = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "bombingrun"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.GurJob002_Milestone8 = L1_1
L1_1 = {}
L1_1.nCash = 1250000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_one_medium
L2_1.Gur = L3_1
L1_1.tAttitude = L2_1
L0_1.GurJob002_Milestone9 = L1_1
L1_1 = {}
L1_1.nCash = 1500000
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_one_large
L2_1.Gur = L3_1
L1_1.tAttitude = L2_1
L2_1 = {}
L3_1 = "daisycutter"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.GurJob002_Milestone10 = L1_1
L1_1 = {}
L2_1 = _tCashReward
L2_1 = L2_1.chapter_one_tiny
L1_1.nCash = L2_1
L2_1 = {}
L3_1 = _tMoodReward
L3_1 = L3_1.chapter_one_tiny
L2_1.Gur = L3_1
L1_1.tAttitude = L2_1
L0_1.GurJob006_PerTarget = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = {}
L4_1 = "m35guntruckgr"
L5_1 = 1
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1[1] = L3_1
L1_1.tStockpile = L2_1
L0_1.GurJob006_Milestone1 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = {}
L4_1 = "m551"
L5_1 = 1
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1[1] = L3_1
L1_1.tStockpile = L2_1
L0_1.GurJob006_Milestone2 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = {}
L4_1 = "endriagosuperiority"
L5_1 = 1
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1[1] = L3_1
L1_1.tStockpile = L2_1
L0_1.GurJob006_Milestone3 = L1_1
L1_1 = {}
L2_1 = {}
L3_1 = "m35aagr"
L2_1[1] = L3_1
L1_1.tSupport = L2_1
L0_1.GurJob006_Milestone4 = L1_1
L1_1 = "GurJob020_PerTarget"
L2_1 = {}
L3_1 = _tCashReward
L3_1 = L3_1.chapter_one_medium
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = _tMoodReward
L4_1 = L4_1.chapter_one_small
L3_1.Gur = L4_1
L2_1.tAttitude = L3_1
L0_1[L1_1] = L2_1
L1_1 = "GurJob020_Milestone1"
L2_1 = {}
L3_1 = {}
L4_1 = "rpg"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "GurJob020_Milestone2"
L2_1 = {}
L3_1 = {}
L4_1 = "combatairpatrol"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "GurJob020_Milestone3"
L2_1 = {}
L3_1 = {}
L4_1 = "m35guntruckgr"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "GurJob020_Milestone4"
L2_1 = {}
L3_1 = {}
L4_1 = "civilian"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "GurJob020_Milestone5"
L2_1 = {}
L3_1 = {}
L4_1 = "m113aagr"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilCon001"
L2_1 = {}
L3_1 = 995000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Oil"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_large
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilCon002"
L2_1 = {}
L3_1 = _tCashReward
L3_1 = L3_1.chapter_one_large
L2_1.nCash = L3_1
L3_1 = "nFuel"
L4_1 = _tFuelReward
L4_1 = L4_1.chapter_one_medium
L2_1[L3_1] = L4_1
L3_1 = {}
L4_1 = "Oil"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_large
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L3_1 = {}
L4_1 = {}
L5_1 = "turbosquidoc"
L6_1 = "Oil"
L7_1 = true
L4_1[1] = L5_1
L4_1[2] = L6_1
L4_1[3] = L7_1
L5_1 = {}
L6_1 = "oc"
L7_1 = "Oil"
L8_1 = true
L5_1[1] = L6_1
L5_1[2] = L7_1
L5_1[3] = L8_1
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1.tSupport = L3_1
L3_1 = {}
L4_1 = {}
L5_1 = "cqb"
L6_1 = 2
L7_1 = true
L4_1[1] = L5_1
L4_1[2] = L6_1
L4_1[3] = L7_1
L5_1 = {}
L6_1 = "ext"
L7_1 = 1
L8_1 = true
L5_1[1] = L6_1
L5_1[2] = L7_1
L5_1[3] = L8_1
L6_1 = {}
L7_1 = "c4"
L8_1 = 1
L9_1 = true
L6_1[1] = L7_1
L6_1[2] = L8_1
L6_1[3] = L9_1
L7_1 = {}
L8_1 = "oc"
L9_1 = 2
L10_1 = true
L7_1[1] = L8_1
L7_1[2] = L9_1
L7_1[3] = L10_1
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L3_1[4] = L7_1
L2_1.tStockpile = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilCon003"
L2_1 = {}
L3_1 = _tCashReward
L3_1 = L3_1.chapter_one_medium
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Oil"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_small
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilCon003_Milestone1"
L2_1 = {}
L3_1 = {}
L4_1 = "lightmg"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilCon003_Milestone2"
L2_1 = {}
L3_1 = {}
L4_1 = "cqb"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilCon003_Milestone3"
L2_1 = {}
L3_1 = {}
L4_1 = {}
L5_1 = "coandasuperiority"
L6_1 = 1
L4_1[1] = L5_1
L4_1[2] = L6_1
L3_1[1] = L4_1
L2_1.tStockpile = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilCon005"
L2_1 = {}
L3_1 = _tCashReward
L3_1 = L3_1.chapter_one_medium
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Oil"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_small
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilCon005_Milestone1"
L2_1 = {}
L3_1 = {}
L4_1 = "guntruckoc"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilCon005_Milestone2"
L2_1 = {}
L3_1 = {}
L4_1 = "omen"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilCon005_Milestone3"
L2_1 = {}
L3_1 = {}
L4_1 = "coandagunship"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilCon020"
L2_1 = {}
L3_1 = {}
L4_1 = "[OilCon020.Objectives.CustomReward]"
L3_1[1] = L4_1
L2_1.tCustomRewards = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilCon021"
L2_1 = {}
L3_1 = 25000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Oil"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_small
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilCon050"
L2_1 = {}
L3_1 = _tCashReward
L3_1 = L3_1.chapter_one_medium
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Oil"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_medium
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L3_1 = {}
L4_1 = "uptankbuster"
L5_1 = "ext"
L6_1 = "c4"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L2_1.tSupport = L3_1
L3_1 = {}
L4_1 = "FuelTank1"
L3_1[1] = L4_1
L2_1.tEquipment = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilCon051"
L2_1 = {}
L3_1 = _tCashReward
L3_1 = L3_1.chapter_one_medium
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Oil"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_medium
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L3_1 = {}
L4_1 = "FuelTank3"
L3_1[1] = L4_1
L2_1.tEquipment = L3_1
L3_1 = {}
L4_1 = "stingrayii"
L5_1 = "upclusterbomb"
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilCon052"
L2_1 = {}
L3_1 = _tCashReward
L3_1 = L3_1.chapter_one_medium
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Oil"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_medium
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L3_1 = {}
L4_1 = "coandaattack"
L5_1 = "upcombatairpatrol"
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1.tSupport = L3_1
L3_1 = {}
L4_1 = "FuelTank2"
L3_1[1] = L4_1
L2_1.tEquipment = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilJob004_PerTarget"
L2_1 = {}
L3_1 = _tCashReward
L3_1 = L3_1.chapter_one_tiny
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Oil"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_tiny
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilJob004_Milestone1"
L2_1 = {}
L3_1 = {}
L4_1 = {}
L5_1 = "extgl"
L6_1 = 1
L4_1[1] = L5_1
L4_1[2] = L6_1
L3_1[1] = L4_1
L2_1.tStockpile = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilJob004_Milestone2"
L2_1 = {}
L3_1 = {}
L4_1 = {}
L5_1 = "guntruckoc"
L6_1 = 1
L4_1[1] = L5_1
L4_1[2] = L6_1
L3_1[1] = L4_1
L2_1.tStockpile = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilJob004_Milestone3"
L2_1 = {}
L3_1 = {}
L4_1 = {}
L5_1 = "coandagunship"
L6_1 = 1
L4_1[1] = L5_1
L4_1[2] = L6_1
L3_1[1] = L4_1
L2_1.tStockpile = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilJob004_Milestone4"
L2_1 = {}
L3_1 = {}
L4_1 = "extgl"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilJob008_PerTarget"
L2_1 = {}
L3_1 = _tCashReward
L3_1 = L3_1.chapter_one_small
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Oil"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_small
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilJob008_Milestone1"
L2_1 = {}
L3_1 = {}
L4_1 = {}
L5_1 = "gl"
L6_1 = 2
L4_1[1] = L5_1
L4_1[2] = L6_1
L3_1[1] = L4_1
L2_1.tStockpile = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilJob008_Milestone2"
L2_1 = {}
L3_1 = {}
L4_1 = {}
L5_1 = "omen"
L6_1 = 1
L4_1[1] = L5_1
L4_1[2] = L6_1
L3_1[1] = L4_1
L2_1.tStockpile = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilJob008_Milestone3"
L2_1 = {}
L3_1 = {}
L4_1 = "coandatransport"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilJob008_Milestone4"
L2_1 = {}
L3_1 = {}
L4_1 = "gl"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilJob008_Milestone5"
L2_1 = {}
L3_1 = {}
L4_1 = "luxury"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilJob011_Milestone1"
L2_1 = {}
L3_1 = 150000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Oil"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_small
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L3_1 = {}
L4_1 = {}
L5_1 = "stingrayii"
L6_1 = 1
L4_1[1] = L5_1
L4_1[2] = L6_1
L3_1[1] = L4_1
L2_1.tStockpile = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilJob011_Milestone2"
L2_1 = {}
L3_1 = 200000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Oil"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_small
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilJob011_Milestone3"
L2_1 = {}
L3_1 = 250000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Oil"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_small
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L3_1 = {}
L4_1 = {}
L5_1 = "coandaattack"
L6_1 = 1
L4_1[1] = L5_1
L4_1[2] = L6_1
L3_1[1] = L4_1
L2_1.tStockpile = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilJob011_Milestone4"
L2_1 = {}
L3_1 = 300000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Oil"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_small
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilJob011_Milestone5"
L2_1 = {}
L3_1 = 400000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Oil"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_small
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L3_1 = {}
L4_1 = "tankbuster"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilJob011_Milestone6"
L2_1 = {}
L3_1 = 500000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Oil"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_medium
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilJob011_Milestone7"
L2_1 = {}
L3_1 = 700000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Oil"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_medium
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilJob011_Milestone8"
L2_1 = {}
L3_1 = 1000000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Oil"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_medium
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L3_1 = {}
L4_1 = "combatairpatrol"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilJob011_Milestone9"
L2_1 = {}
L3_1 = 1250000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Oil"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_medium
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L0_1[L1_1] = L2_1
L1_1 = "OilJob011_Milestone10"
L2_1 = {}
L3_1 = 1500000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Oil"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_large
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L3_1 = {}
L4_1 = "coandasuperiority"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon001"
L2_1 = {}
L3_1 = _tCashReward
L3_1 = L3_1.none
L2_1.nCash = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon002"
L2_1 = {}
L3_1 = 650000
L2_1.nCash = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon003"
L2_1 = {}
L3_1 = _tCashReward
L3_1 = L3_1.none
L2_1.nCash = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon004"
L2_1 = {}
L3_1 = 25000000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "nuke"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon013"
L2_1 = {}
L3_1 = "nWagerPercent"
L4_1 = 5
L2_1[L3_1] = L4_1
L3_1 = "nWagerMinPercent"
L4_1 = 5
L2_1[L3_1] = L4_1
L3_1 = "nWagerMaxPercent"
L4_1 = 20
L2_1[L3_1] = L4_1
L3_1 = "nWagerMax"
L4_1 = 5000000
L2_1[L3_1] = L4_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon015"
L2_1 = {}
L3_1 = "nWager"
L4_1 = 100000
L2_1[L3_1] = L4_1
L3_1 = "nWagerMin"
L4_1 = 100000
L2_1[L3_1] = L4_1
L3_1 = "nWagerMax"
L4_1 = 500000
L2_1[L3_1] = L4_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon015_Milestone1"
L2_1 = {}
L3_1 = {}
L4_1 = {}
L5_1 = "sidecarmotorcycle"
L6_1 = 1
L4_1[1] = L5_1
L4_1[2] = L6_1
L3_1[1] = L4_1
L2_1.tStockpile = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon015_Milestone2"
L2_1 = {}
L3_1 = {}
L4_1 = {}
L5_1 = "valiantpython"
L6_1 = 1
L4_1[1] = L5_1
L4_1[2] = L6_1
L3_1[1] = L4_1
L2_1.tStockpile = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon015_Milestone3"
L2_1 = {}
L3_1 = {}
L4_1 = {}
L5_1 = "tankbike"
L6_1 = 1
L4_1[1] = L5_1
L4_1[2] = L6_1
L3_1[1] = L4_1
L2_1.tStockpile = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon016"
L2_1 = {}
L3_1 = "nWager"
L4_1 = 100000
L2_1[L3_1] = L4_1
L3_1 = "nWagerMin"
L4_1 = 100000
L2_1[L3_1] = L4_1
L3_1 = "nWagerMax"
L4_1 = 500000
L2_1[L3_1] = L4_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon016_Milestone1"
L2_1 = {}
L3_1 = {}
L4_1 = {}
L5_1 = "mattiaschopper"
L6_1 = 1
L4_1[1] = L5_1
L4_1[2] = L6_1
L3_1[1] = L4_1
L2_1.tStockpile = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon016_Milestone2"
L2_1 = {}
L3_1 = {}
L4_1 = {}
L5_1 = "dsvscoutvehicle"
L6_1 = 1
L4_1[1] = L5_1
L4_1[2] = L6_1
L3_1[1] = L4_1
L2_1.tStockpile = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon016_Milestone3"
L2_1 = {}
L3_1 = {}
L4_1 = {}
L5_1 = "panhardassault"
L6_1 = 1
L4_1[1] = L5_1
L4_1[2] = L6_1
L3_1[1] = L4_1
L2_1.tStockpile = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon018"
L2_1 = {}
L3_1 = "nWager"
L4_1 = 100000
L2_1[L3_1] = L4_1
L3_1 = "nWagerMin"
L4_1 = 100000
L2_1[L3_1] = L4_1
L3_1 = "nWagerMax"
L4_1 = 1000000
L2_1[L3_1] = L4_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon018_Milestone1"
L2_1 = {}
L3_1 = {}
L4_1 = {}
L5_1 = "buggyhellfire"
L6_1 = 1
L4_1[1] = L5_1
L4_1[2] = L6_1
L3_1[1] = L4_1
L2_1.tStockpile = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon018_Milestone2"
L2_1 = {}
L3_1 = {}
L4_1 = {}
L5_1 = "patrolboatpmc"
L6_1 = 1
L4_1[1] = L5_1
L4_1[2] = L6_1
L3_1[1] = L4_1
L2_1.tStockpile = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon018_Milestone3"
L2_1 = {}
L3_1 = {}
L4_1 = {}
L5_1 = "veyronassault"
L6_1 = 1
L4_1[1] = L5_1
L4_1[2] = L6_1
L3_1[1] = L4_1
L2_1.tStockpile = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon031"
L2_1 = {}
L3_1 = "nWager"
L4_1 = 1000
L2_1[L3_1] = L4_1
L3_1 = "nWagerMin"
L4_1 = 1000
L2_1[L3_1] = L4_1
L3_1 = "nWagerMax"
L4_1 = 100000
L2_1[L3_1] = L4_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon031_Milestone1"
L2_1 = {}
L3_1 = {}
L4_1 = {}
L5_1 = "fiona"
L6_1 = 1
L4_1[1] = L5_1
L4_1[2] = L6_1
L3_1[1] = L4_1
L2_1.tStockpile = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon032"
L2_1 = {}
L3_1 = "nWager"
L4_1 = 1000
L2_1[L3_1] = L4_1
L3_1 = "nWagerMin"
L4_1 = 1000
L2_1[L3_1] = L4_1
L3_1 = "nWagerMax"
L4_1 = 100000
L2_1[L3_1] = L4_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon032_Milestone1"
L2_1 = {}
L3_1 = {}
L4_1 = {}
L5_1 = "fiona"
L6_1 = 2
L4_1[1] = L5_1
L4_1[2] = L6_1
L3_1[1] = L4_1
L2_1.tStockpile = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon033"
L2_1 = {}
L3_1 = "nWager"
L4_1 = 10000
L2_1[L3_1] = L4_1
L3_1 = "nWagerMin"
L4_1 = 10000
L2_1[L3_1] = L4_1
L3_1 = "nWagerMax"
L4_1 = 100000
L2_1[L3_1] = L4_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon033_Milestone1"
L2_1 = {}
L3_1 = {}
L4_1 = {}
L5_1 = "fiona"
L6_1 = 3
L4_1[1] = L5_1
L4_1[2] = L6_1
L3_1[1] = L4_1
L2_1.tStockpile = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon034"
L2_1 = {}
L3_1 = "nWager"
L4_1 = 10000
L2_1[L3_1] = L4_1
L3_1 = "nWagerMin"
L4_1 = 10000
L2_1[L3_1] = L4_1
L3_1 = "nWagerMax"
L4_1 = 100000
L2_1[L3_1] = L4_1
L0_1[L1_1] = L2_1
L1_1 = "PmcCon034_Milestone1"
L2_1 = {}
L3_1 = {}
L4_1 = {}
L5_1 = "fiona"
L6_1 = 4
L4_1[1] = L5_1
L4_1[2] = L6_1
L3_1[1] = L4_1
L2_1.tStockpile = L3_1
L0_1[L1_1] = L2_1
L1_1 = "VzaCon001"
L2_1 = {}
L3_1 = _tCashReward
L3_1 = L3_1.none
L2_1.nCash = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcJob001_Milestone1"
L2_1 = {}
L3_1 = {}
L4_1 = "tankbike"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcJob001_Milestone2"
L2_1 = {}
L3_1 = {}
L4_1 = "mattiaschopper"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcJob001_Milestone3"
L2_1 = {}
L3_1 = {}
L4_1 = "panhardassault"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcJob001_Milestone4"
L2_1 = {}
L3_1 = {}
L4_1 = "veyronassault"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcJob001_Milestone5"
L2_1 = {}
L3_1 = {}
L4_1 = "valiantpython"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcJob001_Milestone6"
L2_1 = {}
L3_1 = {}
L4_1 = "sidecarmotorcycle"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcJob001_Milestone7"
L2_1 = {}
L3_1 = {}
L4_1 = "dsvscoutvehicle"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcJob001_Milestone8"
L2_1 = {}
L3_1 = {}
L4_1 = "patrolboatpmc"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PmcJob001_Milestone9"
L2_1 = {}
L3_1 = {}
L4_1 = "buggyhellfire"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "MecCon001"
L2_1 = {}
L3_1 = {}
L4_1 = {}
L5_1 = "monstertruck"
L6_1 = "Pmc"
L7_1 = true
L4_1[1] = L5_1
L4_1[2] = L6_1
L4_1[3] = L7_1
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirIntro"
L2_1 = {}
L3_1 = {}
L4_1 = {}
L5_1 = "sniperru"
L6_1 = "Pir"
L4_1[1] = L5_1
L4_1[2] = L6_1
L5_1 = {}
L6_1 = "m15150calvz"
L7_1 = "Pir"
L5_1[1] = L6_1
L5_1[2] = L7_1
L6_1 = {}
L7_1 = "pr"
L8_1 = "Pir"
L6_1[1] = L7_1
L6_1[2] = L8_1
L7_1 = {}
L8_1 = "alouette3transportvz"
L9_1 = "Pir"
L7_1[1] = L8_1
L7_1[2] = L9_1
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L3_1[4] = L7_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirCon001"
L2_1 = {}
L3_1 = _tCashReward
L3_1 = L3_1.chapter_one_small
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Pir"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_small
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirCon001_Milestone1"
L2_1 = {}
L3_1 = {}
L4_1 = "jetskiciv"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirCon001_Milestone2"
L2_1 = {}
L3_1 = {}
L4_1 = "dinghy"
L5_1 = "monster"
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirCon001_Milestone3"
L2_1 = {}
L3_1 = {}
L4_1 = "sports"
L5_1 = "buggypr"
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirCon002"
L2_1 = {}
L3_1 = 20000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Pir"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_small
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirCon002_Milestone1"
L2_1 = {}
L3_1 = {}
L4_1 = "t300m60"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirCon002_Milestone2"
L2_1 = {}
L3_1 = {}
L4_1 = "alouette3attackpr"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirCon002_Milestone3"
L2_1 = {}
L3_1 = {}
L4_1 = "m113vz"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirCon003"
L2_1 = {}
L3_1 = 30000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Pir"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_small
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirCon003_Milestone1"
L2_1 = {}
L3_1 = {}
L4_1 = "m113jammervz"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirCon003_Milestone2"
L2_1 = {}
L3_1 = {}
L4_1 = "alouette3attackvz"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirCon003_Milestone3"
L2_1 = {}
L3_1 = {}
L4_1 = "m35aavz"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirCon004"
L2_1 = {}
L3_1 = _tCashReward
L3_1 = L3_1.chapter_one_medium
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Pir"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_small
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirCon004_Milestone1"
L2_1 = {}
L3_1 = {}
L4_1 = "m35guntruckvz"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirCon004_Milestone2"
L2_1 = {}
L3_1 = {}
L4_1 = "alouette3elite"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirCon004_Milestone3"
L2_1 = {}
L3_1 = {}
L4_1 = "amx30aa"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirCon051"
L2_1 = {}
L3_1 = _tCashReward
L3_1 = L3_1.chapter_one_medium
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Pir"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_medium
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L3_1 = {}
L4_1 = "scorpion90"
L5_1 = "patrolboatvz"
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1.tSupport = L3_1
L3_1 = {}
L4_1 = "FuelTank5"
L3_1[1] = L4_1
L2_1.tEquipment = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirCon052"
L2_1 = {}
L3_1 = _tCashReward
L3_1 = L3_1.chapter_one_medium
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Pir"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_medium
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L3_1 = {}
L4_1 = "mi35"
L5_1 = "speedboat"
L3_1[1] = L4_1
L3_1[2] = L5_1
L2_1.tSupport = L3_1
L3_1 = {}
L4_1 = "FuelTank4"
L3_1[1] = L4_1
L2_1.tEquipment = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirJob012_Milestone1"
L2_1 = {}
L3_1 = 100000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Pir"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_small
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L3_1 = {}
L4_1 = "alouette3transportpr"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirJob012_Milestone2"
L2_1 = {}
L3_1 = 125000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Pir"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_small
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirJob012_Milestone3"
L2_1 = {}
L3_1 = 150000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Pir"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_small
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L3_1 = {}
L4_1 = "m15150calvz"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirJob012_Milestone4"
L2_1 = {}
L3_1 = 175000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Pir"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_small
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirJob012_Milestone5"
L2_1 = {}
L3_1 = 200000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Pir"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_small
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L3_1 = {}
L4_1 = "bike"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirJob012_Milestone6"
L2_1 = {}
L3_1 = 250000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Pir"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_medium
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirJob012_Milestone7"
L2_1 = {}
L3_1 = 300000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Pir"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_medium
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirJob012_Milestone8"
L2_1 = {}
L3_1 = 500000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Pir"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_medium
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L3_1 = {}
L4_1 = "alouette3superiority"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirJob012_Milestone9"
L2_1 = {}
L3_1 = 750000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Pir"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_medium
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirJob012_Milestone10"
L2_1 = {}
L3_1 = 1000000
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Pir"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_large
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L3_1 = {}
L4_1 = "amx30elite"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirJob020_PerTarget"
L2_1 = {}
L3_1 = _tCashReward
L3_1 = L3_1.chapter_one_small
L2_1.nCash = L3_1
L3_1 = {}
L4_1 = "Pir"
L5_1 = _tMoodReward
L5_1 = L5_1.chapter_one_small
L3_1[L4_1] = L5_1
L2_1.tAttitude = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirJob020_Milestone1"
L2_1 = {}
L3_1 = {}
L4_1 = "covert"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirJob020_Milestone2"
L2_1 = {}
L3_1 = {}
L4_1 = "m113aavz"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirJob020_Milestone3"
L2_1 = {}
L3_1 = {}
L4_1 = "utility"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirJob020_Milestone4"
L2_1 = {}
L3_1 = {}
L4_1 = "amx30"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
L1_1 = "PirJob020_Milestone5"
L2_1 = {}
L3_1 = {}
L4_1 = "mi26vz"
L3_1[1] = L4_1
L2_1.tSupport = L3_1
L0_1[L1_1] = L2_1
_tRewards = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L0_2 = pairs
  L1_2 = _tRewards
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = nil
    L6_2 = string
    L6_2 = L6_2.sub
    L7_2 = L3_2
    L8_2 = 1
    L9_2 = 9
    L6_2 = L6_2(L7_2, L8_2, L9_2)
    if L6_2 then
      L7_2 = WifMissionData
      L7_2 = L7_2.tMissionData
      L7_2 = L7_2[L6_2]
      if L7_2 then
        L5_2 = L7_2.sFactionId
      end
      L4_2.sMissionId = L6_2
    end
    if L5_2 then
      L4_2.sFactionId = L5_2
    end
    L7_2 = L4_2.tSupport
    if L7_2 then
      L7_2 = ipairs
      L8_2 = L4_2.tSupport
      L7_2, L8_2, L9_2 = L7_2(L8_2)
      for L10_2, L11_2 in L7_2, L8_2, L9_2 do
        L12_2 = type
        L13_2 = L11_2
        L12_2 = L12_2(L13_2)
        if L12_2 == "string" then
          L12_2 = {}
          L13_2 = L11_2
          L12_2[1] = L13_2
          L11_2 = L12_2
        end
        if L5_2 then
          L12_2 = L11_2[2]
          if not L12_2 then
            L11_2[2] = L5_2
          end
        end
        L12_2 = L11_2[3]
        if not L12_2 then
          L11_2[3] = false
        end
        L12_2 = L4_2.tSupport
        L12_2[L10_2] = L11_2
      end
    end
    L7_2 = L4_2.tEquipment
    if L7_2 then
      L7_2 = ipairs
      L8_2 = L4_2.tEquipment
      L7_2, L8_2, L9_2 = L7_2(L8_2)
      for L10_2, L11_2 in L7_2, L8_2, L9_2 do
        L12_2 = type
        L13_2 = L11_2
        L12_2 = L12_2(L13_2)
        if L12_2 == "string" then
          L12_2 = {}
          L13_2 = L11_2
          L12_2[1] = L13_2
          L11_2 = L12_2
        end
        if L5_2 then
          L12_2 = L11_2[2]
          if not L12_2 then
            L11_2[2] = L5_2
          end
        end
        L12_2 = L11_2[3]
        if not L12_2 then
          L11_2[3] = false
        end
        L12_2 = L4_2.tEquipment
        L12_2[L10_2] = L11_2
      end
    end
    L7_2 = L4_2.tStockpile
    if L7_2 then
      L7_2 = ipairs
      L8_2 = L4_2.tStockpile
      L7_2, L8_2, L9_2 = L7_2(L8_2)
      for L10_2, L11_2 in L7_2, L8_2, L9_2 do
        L12_2 = type
        L13_2 = L11_2
        L12_2 = L12_2(L13_2)
        if L12_2 == "string" then
          L12_2 = {}
          L13_2 = L11_2
          L12_2[1] = L13_2
          L11_2 = L12_2
        end
        L12_2 = L11_2[2]
        if not L12_2 then
          L11_2[2] = 1
        end
        L12_2 = L11_2[3]
        if not L12_2 then
          L11_2[3] = false
        end
        L12_2 = L4_2.tStockpile
        L12_2[L10_2] = L11_2
      end
    end
  end
end

Init = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = _tRewards
  L1_2 = L1_2[A0_2]
  return L1_2
end

GetRewards = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2
  L1_2 = gtAllSupport
  if not L1_2 then
    L1_2 = {}
    gtAllSupport = L1_2
    L1_2 = {}
    gtAllEquipment = L1_2
  end
  L1_2 = gtAllSupport
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    L1_2 = {}
    L2_2 = {}
    L3_2 = pairs
    L4_2 = _tRewards
    L3_2, L4_2, L5_2 = L3_2(L4_2)
    for L6_2, L7_2 in L3_2, L4_2, L5_2 do
      L8_2 = type
      L9_2 = L7_2.tSupport
      L8_2 = L8_2(L9_2)
      if L8_2 == "table" then
        L8_2 = ipairs
        L9_2 = L7_2.tSupport
        L8_2, L9_2, L10_2 = L8_2(L9_2)
        for L11_2, L12_2 in L8_2, L9_2, L10_2 do
          L13_2 = L12_2[1]
          L14_2 = L12_2[2]
          if A0_2 == L14_2 then
            L15_2 = MrxSupportData
            L15_2 = L15_2.tSupportData
            L15_2 = L15_2[L13_2]
            if L15_2 then
              L15_2 = table
              L15_2 = L15_2.insert
              L16_2 = L1_2
              L17_2 = L13_2
              L15_2(L16_2, L17_2)
            end
          end
        end
      end
      L8_2 = L7_2.sFactionId
      if A0_2 == L8_2 then
        L8_2 = type
        L9_2 = L7_2.tEquipment
        L8_2 = L8_2(L9_2)
        if L8_2 == "table" then
          L9_2 = ipairs
          L10_2 = L7_2.tEquipment
          L9_2, L10_2, L11_2 = L9_2(L10_2)
          for L12_2, L13_2 in L9_2, L10_2, L11_2 do
            L14_2 = type
            L15_2 = L13_2
            L14_2 = L14_2(L15_2)
            if L14_2 == "table" then
              L14_2 = ipairs
              L15_2 = L7_2.tEquipment
              L14_2, L15_2, L16_2 = L14_2(L15_2)
              for L17_2, L18_2 in L14_2, L15_2, L16_2 do
                L19_2 = L18_2[1]
                L20_2 = L18_2[2]
                L21_2 = table
                L21_2 = L21_2.insert
                L22_2 = L2_2
                L23_2 = L19_2
                L21_2(L22_2, L23_2)
              end
            else
              L14_2 = WifEquipmentData
              L14_2 = L14_2.GetEquipmentData
              L15_2 = L13_2
              L14_2 = L14_2(L15_2)
              if L14_2 then
                L14_2 = table
                L14_2 = L14_2.insert
                L15_2 = L2_2
                L16_2 = L13_2
                L14_2(L15_2, L16_2)
              end
            end
          end
        elseif L8_2 == "string" then
          L9_2 = WifEquipmentData
          L9_2 = L9_2.GetEquipmentData
          L10_2 = L7_2.tEquipment
          L9_2 = L9_2(L10_2)
          if L9_2 then
            L9_2 = table
            L9_2 = L9_2.insert
            L10_2 = L2_2
            L11_2 = L7_2.tEquipment
            L9_2(L10_2, L11_2)
          end
        end
      end
    end
    L3_2 = gtAllSupport
    L3_2[A0_2] = L1_2
    L3_2 = gtAllEquipment
    L3_2[A0_2] = L2_2
  end
  L1_2 = gtAllSupport
  L1_2 = L1_2[A0_2]
  L2_2 = gtAllEquipment
  L2_2 = L2_2[A0_2]
  return L1_2, L2_2
end

GetAllPotentialShopItems = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L3_2 = type
  L4_2 = A0_2.nCashOverride
  L3_2 = L3_2(L4_2)
  if L3_2 == "number" then
    L2_2 = A0_2.nCashOverride
    A0_2.nCashOverride = nil
  else
    L3_2 = type
    L4_2 = A0_2.nCash
    L3_2 = L3_2(L4_2)
    if L3_2 == "number" then
      L2_2 = A0_2.nCash
      L3_2 = _bHalveCashReward
      if L3_2 then
        L2_2 = L2_2 * 0.5
      end
    end
  end
  if L2_2 then
    L3_2 = nil
    L4_2 = A0_2.sMissionId
    if L4_2 then
      L5_2 = WifMissionData
      L5_2 = L5_2.IsMissionAContract
      L6_2 = L4_2
      L5_2 = L5_2(L6_2)
      if L5_2 then
        L3_2 = "[Generic.Contracts]"
      end
    end
    L5_2 = MrxPmc
    L5_2 = L5_2.AddCashQty
    L6_2 = L2_2
    L7_2 = nil
    L8_2 = L3_2
    L5_2(L6_2, L7_2, L8_2)
  end
  L3_2 = type
  L4_2 = A0_2.nFuel
  L3_2 = L3_2(L4_2)
  if L3_2 == "number" then
    L3_2 = MrxPmc
    L3_2 = L3_2.AddFuelQty
    L4_2 = A0_2.nFuel
    L3_2(L4_2)
  end
  L3_2 = Net
  L3_2 = L3_2.IsClient
  L3_2 = L3_2()
  if not L3_2 then
    L3_2 = type
    L4_2 = A0_2.tAttitude
    L3_2 = L3_2(L4_2)
    if L3_2 == "table" then
      L3_2 = pairs
      L4_2 = A0_2.tAttitude
      L3_2, L4_2, L5_2 = L3_2(L4_2)
      for L6_2, L7_2 in L3_2, L4_2, L5_2 do
        L8_2 = MrxFactionManager
        L8_2 = L8_2.ChangeRelation
        L9_2 = L6_2
        L10_2 = "Pmc"
        L11_2 = L7_2
        L8_2(L9_2, L10_2, L11_2)
      end
    end
    L3_2 = type
    L4_2 = A0_2.tSupport
    L3_2 = L3_2(L4_2)
    if L3_2 ~= "table" then
      L3_2 = type
      L4_2 = A0_2.tEquipment
      L3_2 = L3_2(L4_2)
      if L3_2 ~= "table" then
        goto lbl_157
      end
    end
    L3_2 = {}
    L4_2 = {}
    L5_2 = type
    L6_2 = A0_2.tSupport
    L5_2 = L5_2(L6_2)
    if L5_2 == "table" then
      L5_2 = ipairs
      L6_2 = A0_2.tSupport
      L5_2, L6_2, L7_2 = L5_2(L6_2)
      for L8_2, L9_2 in L5_2, L6_2, L7_2 do
        L10_2 = L9_2[1]
        L11_2 = L9_2[2]
        L12_2 = L3_2[L11_2]
        if L12_2 then
          L12_2 = table
          L12_2 = L12_2.insert
          L13_2 = L3_2[L11_2]
          L14_2 = L10_2
          L12_2(L13_2, L14_2)
        else
          L12_2 = {}
          L13_2 = L10_2
          L12_2[1] = L13_2
          L3_2[L11_2] = L12_2
        end
        L12_2 = table
        L12_2 = L12_2.insert
        L13_2 = L4_2
        L14_2 = {}
        L14_2.sFactionId = L11_2
        L14_2.sSupportId = L10_2
        L12_2(L13_2, L14_2)
      end
      L5_2 = pairs
      L6_2 = L3_2
      L5_2, L6_2, L7_2 = L5_2(L6_2)
      for L8_2, L9_2 in L5_2, L6_2, L7_2 do
        L10_2 = MrxSupportData
        L10_2 = L10_2.Add
        L11_2 = L9_2
        L12_2 = L8_2
        L10_2(L11_2, L12_2)
      end
    end
    L5_2 = type
    L6_2 = A0_2.tEquipment
    L5_2 = L5_2(L6_2)
    if L5_2 == "table" then
      L5_2 = ipairs
      L6_2 = A0_2.tEquipment
      L5_2, L6_2, L7_2 = L5_2(L6_2)
      for L8_2, L9_2 in L5_2, L6_2, L7_2 do
        L10_2 = L9_2[1]
        L11_2 = L9_2[2]
        L12_2 = table
        L12_2 = L12_2.insert
        L13_2 = L4_2
        L14_2 = {}
        L14_2.sFactionId = L11_2
        L14_2.sEquipmentId = L10_2
        L12_2(L13_2, L14_2)
        L12_2 = WifEquipmentData
        L12_2 = L12_2.UnlockItem
        L13_2 = L10_2
        L14_2 = L11_2
        L12_2(L13_2, L14_2)
      end
    end
    if not A1_2 then
      L5_2 = MrxUnlockFanfare
      L5_2 = L5_2.AddUnlockedItems
      L6_2 = "support"
      L7_2 = L4_2
      L5_2(L6_2, L7_2)
    end
  end
  ::lbl_157::
  L3_2 = type
  L4_2 = A0_2.tStockpile
  L3_2 = L3_2(L4_2)
  if L3_2 == "table" then
    L3_2 = {}
    L4_2 = ipairs
    L5_2 = A0_2.tStockpile
    L4_2, L5_2, L6_2 = L4_2(L5_2)
    for L7_2, L8_2 in L4_2, L5_2, L6_2 do
      L9_2 = L8_2[1]
      L10_2 = L8_2[2]
      L11_2 = MrxPmc
      L11_2 = L11_2.AddSupportQty
      L12_2 = L9_2
      L13_2 = L10_2
      L11_2(L12_2, L13_2)
      L11_2 = table
      L11_2 = L11_2.insert
      L12_2 = L3_2
      L13_2 = {}
      L13_2.sSupportId = L9_2
      L13_2.nQty = L10_2
      L11_2(L12_2, L13_2)
    end
    if not A1_2 then
      L4_2 = MrxUnlockFanfare
      L4_2 = L4_2.AddUnlockedItems
      L5_2 = "stockpile"
      L6_2 = L3_2
      L4_2(L5_2, L6_2)
    end
  end
end

DispenseRewards = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = pairs
  L1_2 = _tRewards
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = DispenseRewards
    L6_2 = L4_2
    L7_2 = true
    L5_2(L6_2, L7_2)
  end
end

DispenseAllRewards = L0_1
L0_1 = 0
EVENT_GRANTREWARDKEY = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = pairs
  L2_2 = _tRewards
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = String
    L6_2 = L6_2.GetHash
    L7_2 = L4_2
    L6_2 = L6_2(L7_2)
    if L6_2 == A0_2 then
      return L4_2
    end
  end
  L1_2 = nil
  return L1_2
end

GetRewardKeyFromHash = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = EVENT_GRANTREWARDKEY
  if A0_2 == L2_2 then
    L2_2 = GetRewardKeyFromHash
    L3_2 = A1_2[1]
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L3_2 = GrantRewardKey
      L4_2 = L2_2
      L5_2 = A1_2[2]
      L3_2(L4_2, L5_2)
    end
  end
end

NetEventCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = GetRewards
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = Net
    L3_2 = L3_2.IsServer
    L3_2 = L3_2()
    if L3_2 then
      L3_2 = Net
      L3_2 = L3_2.SendCustomEvent
      L4_2 = "MrxRewardData"
      L5_2 = EVENT_GRANTREWARDKEY
      L6_2 = {}
      L7_2 = A0_2
      L8_2 = L2_2.nCashOverride2
      L6_2[1] = L7_2
      L6_2[2] = L8_2
      L3_2(L4_2, L5_2, L6_2)
      L3_2 = DispenseRewards
      L4_2 = L2_2
      L3_2(L4_2)
    end
    L3_2 = Net
    L3_2 = L3_2.IsClient
    L3_2 = L3_2()
    if L3_2 then
      if A1_2 then
        L2_2.nCashOverride = A1_2
      end
      L3_2 = DispenseRewards
      L4_2 = L2_2
      L5_2 = true
      L3_2(L4_2, L5_2)
    end
  end
end

GrantRewardKey = L0_1

function L0_1(A0_2)
  local L1_2
  _bHalveCashReward = A0_2
end

EnableCashRewardHalving = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = {}
  L1_2 = pairs
  L2_2 = _tRewards
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L5_2.nWager
    if L6_2 then
      L6_2 = {}
      L7_2 = L5_2.nWager
      L6_2.nWager = L7_2
      L0_2[L4_2] = L6_2
    end
  end
  return L0_2
end

SaveSingleton = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  if A0_2 then
    L1_2 = pairs
    L2_2 = A0_2
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    for L4_2, L5_2 in L1_2, L2_2, L3_2 do
      L6_2 = _tRewards
      L6_2 = L6_2[L4_2]
      if L6_2 then
        L7_2 = pairs
        L8_2 = L5_2
        L7_2, L8_2, L9_2 = L7_2(L8_2)
        for L10_2, L11_2 in L7_2, L8_2, L9_2 do
          L6_2[L10_2] = L11_2
        end
      end
    end
  end
end

LoadSingleton = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  
  function L1_2(A0_3)
    local L1_3, L2_3
    L1_3 = math
    L1_3 = L1_3.floor
    L2_3 = A0_3 / 1000
    L1_3 = L1_3(L2_3)
    L1_3 = L1_3 * 1000
    return L1_3
  end
  
  L2_2 = nil
  L3_2 = A0_2.nWagerPercent
  if L3_2 then
    L3_2 = {}
    L2_2 = L3_2
    L3_2 = MrxPmc
    L3_2 = L3_2.GetCashQty
    L3_2 = L3_2()
    L4_2 = L1_2
    L5_2 = A0_2.nWagerPercent
    L5_2 = L5_2 / 100
    L5_2 = L3_2 * L5_2
    L4_2 = L4_2(L5_2)
    L2_2.nWager = L4_2
    L4_2 = A0_2.nWager
    if L4_2 ~= nil then
      L4_2 = L2_2.nWager
      L5_2 = A0_2.nWager
      if L4_2 > L5_2 then
        L4_2 = A0_2.nWager
        L2_2.nWager = L4_2
      end
    end
    L4_2 = L1_2
    L5_2 = A0_2.nWagerMinPercent
    L5_2 = L5_2 / 100
    L5_2 = L3_2 * L5_2
    L4_2 = L4_2(L5_2)
    L2_2.nWagerMin = L4_2
    L4_2 = A0_2.nWagerMin
    if L4_2 ~= nil then
      L4_2 = L2_2.nWagerMin
      L5_2 = A0_2.nWagerMin
      if L4_2 < L5_2 then
        L4_2 = A0_2.nWagerMin
        L2_2.nWagerMin = L4_2
      end
    end
    L4_2 = L1_2
    L5_2 = A0_2.nWagerMaxPercent
    L5_2 = L5_2 / 100
    L5_2 = L3_2 * L5_2
    L4_2 = L4_2(L5_2)
    L2_2.nWagerMax = L4_2
    L4_2 = A0_2.nWagerMax
    if L4_2 ~= nil then
      L4_2 = L2_2.nWagerMax
      L5_2 = A0_2.nWagerMax
      if L4_2 > L5_2 then
        L4_2 = A0_2.nWagerMax
        L2_2.nWagerMax = L4_2
      end
    end
    L2_2.nCash = L3_2
  end
  L3_2 = A0_2.nWager
  if L3_2 then
    L3_2 = {}
    L2_2 = L3_2
    L3_2 = A0_2.nWager
    L2_2.nWager = L3_2
    L3_2 = A0_2.nWagerMin
    L2_2.nWagerMin = L3_2
    L3_2 = A0_2.nWagerMax
    L2_2.nWagerMax = L3_2
    L3_2 = MrxPmc
    L3_2 = L3_2.GetCashQty
    L3_2 = L3_2()
    L2_2.nCash = L3_2
  end
  if L2_2 then
    L3_2 = L2_2.nWager
    L4_2 = L2_2.nWagerMin
    if L3_2 < L4_2 then
      L3_2 = L2_2.nWagerMin
      L2_2.nWager = L3_2
    end
    L3_2 = L2_2.nWager
    L4_2 = L2_2.nCash
    L5_2 = L2_2.nWagerMin
    if L4_2 < L5_2 then
      L3_2 = L2_2.nWagerMin
    else
      L4_2 = L2_2.nCash
      L5_2 = L2_2.nWager
      if L4_2 < L5_2 then
        L3_2 = L2_2.nCash
      end
    end
    L4_2 = L1_2
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    L2_2.nDefaultWager = L4_2
  end
  return L2_2
end

GetWagerData = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  if not A0_2 then
    L1_2 = nil
    return L1_2
  end
  L1_2 = nil
  L2_2 = GetRewards
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = _GenerateStringFromRewardData
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    L1_2 = L3_2
  end
  L3_2 = WifMissionData
  L3_2 = L3_2.IsMissionAContract
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L3_2 = WifMissionData
    L3_2 = L3_2.GetMissionRepeatable
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
  end
  L4_2 = WifMissionData
  L4_2 = L4_2.GetMissionMilestoneData
  L5_2 = A0_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  if L4_2 then
    L7_2 = pairs
    L8_2 = L4_2
    L7_2, L8_2, L9_2 = L7_2(L8_2)
    for L10_2, L11_2 in L7_2, L8_2, L9_2 do
      L12_2 = nil
      if L3_2 then
        L13_2 = _FormatLevelMilestoneString
        L14_2 = L11_2
        L13_2 = L13_2(L14_2)
        L12_2 = L13_2
      else
        L13_2 = _FormatMilestoneString
        L14_2 = L11_2
        L15_2 = L5_2
        L16_2 = L6_2
        L13_2 = L13_2(L14_2, L15_2, L16_2)
        L12_2 = L13_2
      end
      if L12_2 then
        L13_2 = L1_2 or L13_2
        if not L1_2 then
          L13_2 = ""
        end
        L14_2 = L12_2
        L1_2 = L13_2 .. L14_2
      end
    end
  end
  if L2_2 then
    L7_2 = L2_2.tCustomRewards
    if L7_2 then
      L7_2 = ""
      L8_2 = pairs
      L9_2 = L2_2.tCustomRewards
      L8_2, L9_2, L10_2 = L8_2(L9_2)
      for L11_2, L12_2 in L8_2, L9_2, L10_2 do
        L13_2 = L7_2
        L14_2 = L12_2
        L15_2 = "\n"
        L7_2 = L13_2 .. L14_2 .. L15_2
      end
      L8_2 = L1_2 or L8_2
      if not L1_2 then
        L8_2 = ""
      end
      L9_2 = L7_2
      L1_2 = L8_2 .. L9_2
    end
  end
  if "" == L1_2 then
    L7_2 = nil
    return L7_2
  end
  return L1_2
end

GenerateRewardString = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = GetRewards
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = L2_2.tCustomRewards
  if not L3_2 then
    L3_2 = {}
    L2_2.tCustomRewards = L3_2
  end
  L3_2 = table
  L3_2 = L3_2.insert
  L4_2 = L2_2.tCustomRewards
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
end

AddCustomReward = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L3_2 = ""
  if not A2_2 then
    A2_2 = ""
  end
  L4_2 = " "
  L5_2 = A2_2
  L6_2 = "\n"
  A2_2 = L4_2 .. L5_2 .. L6_2
  if not A1_2 then
    A1_2 = ""
  end
  L4_2 = A0_2.nCash
  if L4_2 then
    L4_2 = A0_2.nCash
    if 0 < L4_2 then
      L4_2 = "[cash] "
      L5_2 = MrxUtil
      L5_2 = L5_2.FormatMoney
      L6_2 = A0_2.nCash
      L5_2 = L5_2(L6_2)
      L4_2 = L4_2 .. L5_2
      L5_2 = L3_2
      L6_2 = A1_2
      L7_2 = L4_2
      L8_2 = A2_2
      L3_2 = L5_2 .. L6_2 .. L7_2 .. L8_2
    end
  end
  L4_2 = A0_2.nFuel
  if L4_2 then
    L4_2 = A0_2.nFuel
    if 0 < L4_2 then
      L4_2 = "[fuel] "
      L5_2 = A0_2.nFuel
      L4_2 = L4_2 .. L5_2
      L5_2 = L3_2
      L6_2 = A1_2
      L7_2 = L4_2
      L8_2 = A2_2
      L3_2 = L5_2 .. L6_2 .. L7_2 .. L8_2
    end
  end
  L4_2 = A0_2.tSupport
  if L4_2 then
    L4_2 = nil
    L5_2 = pairs
    L6_2 = A0_2.tSupport
    L5_2, L6_2, L7_2 = L5_2(L6_2)
    for L8_2, L9_2 in L5_2, L6_2, L7_2 do
      L10_2 = L9_2[1]
      L11_2 = L9_2[2]
      L12_2 = L9_2[3]
      if not L12_2 then
        if L10_2 then
          L13_2 = _GetPrintableSupportString
          L14_2 = L10_2
          L13_2 = L13_2(L14_2)
          L4_2 = L13_2
          if L11_2 then
            L13_2 = L4_2
            L14_2 = "\n"
            L15_2 = A1_2
            L16_2 = "[indent] "
            L17_2 = "([Briefing.Shop]: "
            L18_2 = MrxFactionManager
            L18_2 = L18_2.GetInlineIcon
            L19_2 = L11_2
            L18_2 = L18_2(L19_2)
            L19_2 = ")"
            L4_2 = L13_2 .. L14_2 .. L15_2 .. L16_2 .. L17_2 .. L18_2 .. L19_2
          end
        end
        if L4_2 then
          L13_2 = L3_2
          L14_2 = A1_2
          L15_2 = L4_2
          L16_2 = A2_2
          L3_2 = L13_2 .. L14_2 .. L15_2 .. L16_2
        end
      end
    end
  end
  L4_2 = A0_2.tEquipment
  if L4_2 then
    L4_2 = nil
    L5_2 = pairs
    L6_2 = A0_2.tEquipment
    L5_2, L6_2, L7_2 = L5_2(L6_2)
    for L8_2, L9_2 in L5_2, L6_2, L7_2 do
      L10_2 = L9_2[1]
      L11_2 = L9_2[2]
      L12_2 = L9_2[3]
      if not L12_2 then
        L13_2 = _GetPrintableEquipmentString
        L14_2 = L10_2
        L13_2 = L13_2(L14_2)
        L4_2 = L13_2
        if L11_2 then
          L13_2 = L4_2
          L14_2 = "\n"
          L15_2 = A1_2
          L16_2 = "[indent] "
          L17_2 = "([Briefing.Shop]: "
          L18_2 = MrxFactionManager
          L18_2 = L18_2.GetInlineIcon
          L19_2 = L11_2
          L18_2 = L18_2(L19_2)
          L19_2 = ")"
          L4_2 = L13_2 .. L14_2 .. L15_2 .. L16_2 .. L17_2 .. L18_2 .. L19_2
        end
        if L4_2 then
          L13_2 = L3_2
          L14_2 = A1_2
          L15_2 = L4_2
          L16_2 = A2_2
          L3_2 = L13_2 .. L14_2 .. L15_2 .. L16_2
        end
      end
    end
  end
  L4_2 = A0_2.tStockpile
  if L4_2 then
    L4_2 = nil
    L5_2 = pairs
    L6_2 = A0_2.tStockpile
    L5_2, L6_2, L7_2 = L5_2(L6_2)
    for L8_2, L9_2 in L5_2, L6_2, L7_2 do
      L10_2 = L9_2[1]
      L11_2 = L9_2[2]
      L12_2 = L9_2[3]
      if not L12_2 then
        if L10_2 then
          L13_2 = _GetPrintableSupportString
          L14_2 = L10_2
          L13_2 = L13_2(L14_2)
          L4_2 = L13_2
          if L11_2 and L4_2 then
            L13_2 = L4_2
            L14_2 = " (x "
            L15_2 = L11_2
            L16_2 = ")"
            L4_2 = L13_2 .. L14_2 .. L15_2 .. L16_2
          end
        end
        if L4_2 then
          L13_2 = L3_2
          L14_2 = A1_2
          L15_2 = L4_2
          L16_2 = A2_2
          L3_2 = L13_2 .. L14_2 .. L15_2 .. L16_2
        end
      end
    end
  end
  return L3_2
end

_GenerateStringFromRewardData = L0_1
L0_1 = true
_bPrintRewardType = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = MrxSupportData
  L2_2 = L2_2.tSupportData
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L3_2 = L2_2.sName
    if L3_2 then
      L1_2 = L2_2.sName
  end
  else
    L3_2 = nil
    return L3_2
  end
  L3_2 = _bPrintRewardType
  if L3_2 then
    L3_2 = {}
    L3_2.Airstrike = "[airstrike]"
    L3_2.Supply = "[supply]"
    L3_2.Light = "[vehmlight]"
    L3_2.Heavy = "[vehmheavy]"
    L3_2.Civilian = "[vehcivilian]"
    L3_2.Boat = "[vehboat]"
    L3_2.Heli = "[vehheli]"
    if L2_2 then
      L4_2 = L2_2.sType
      if L4_2 then
        L4_2 = L2_2.sType
        L4_2 = L3_2[L4_2]
        if L4_2 then
          L5_2 = L4_2
          L6_2 = " "
          L7_2 = L1_2
          L1_2 = L5_2 .. L6_2 .. L7_2
        end
      end
    end
  end
  return L1_2
end

_GetPrintableSupportString = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = WifEquipmentData
  L1_2 = L1_2.GetEquipmentData
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L2_2 = _bPrintRewardType
    if L2_2 then
      L2_2 = L1_2.nType
      L3_2 = WifEquipmentData
      L3_2 = L3_2.knTypeFuelTank
      if L2_2 == L3_2 then
        L2_2 = "[fuelsilo] "
        L3_2 = "[Generic.FuelSilo]"
        L2_2 = L2_2 .. L3_2
        return L2_2
      else
        L2_2 = L1_2.nType
        L3_2 = WifEquipmentData
        L3_2 = L3_2.knTypeGrapplingHook
        if L2_2 == L3_2 then
          L2_2 = WifEquipmentData
          L2_2 = L2_2.GetPlayerVisibleName
          L3_2 = A0_2
          return L2_2(L3_2)
        end
      end
    end
  end
  return A0_2
end

_GetPrintableEquipmentString = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = A0_2.nMilestone
  L4_2 = A0_2.sKey
  L5_2 = GetRewards
  L6_2 = L4_2
  L5_2 = L5_2(L6_2)
  L6_2 = nil
  if not L5_2 then
    L7_2 = nil
    return L7_2
  end
  L7_2 = nil
  if 1 == L3_2 then
    if A1_2 then
      L8_2 = _FormatMilestoneSuffix
      L9_2 = A1_2
      L10_2 = L3_2
      L8_2 = L8_2(L9_2, L10_2)
      L7_2 = L8_2
    end
  elseif A2_2 then
    L8_2 = _FormatMilestoneSuffix
    L9_2 = A2_2
    L10_2 = L3_2
    L8_2 = L8_2(L9_2, L10_2)
    L7_2 = L8_2
  end
  if not L7_2 then
    if 1 == L3_2 then
      L8_2 = L3_2
      L9_2 = " [PDA.Map.Target]"
      L7_2 = L8_2 .. L9_2
    else
      L8_2 = L3_2
      L9_2 = " [PDA.Map.Targets]"
      L7_2 = L8_2 .. L9_2
    end
  end
  L8_2 = L7_2
  L9_2 = ":\n"
  L7_2 = L8_2 .. L9_2
  L8_2 = WifMissionFlow
  L8_2 = L8_2.HasKey
  L9_2 = L4_2
  L8_2 = L8_2(L9_2)
  if L8_2 then
    L8_2 = "[check1] "
    L9_2 = L7_2
    L7_2 = L8_2 .. L9_2
  else
    L8_2 = "[check0] "
    L9_2 = L7_2
    L7_2 = L8_2 .. L9_2
  end
  L8_2 = L7_2
  L9_2 = _GenerateStringFromRewardData
  L10_2 = L5_2
  L11_2 = "[indent] "
  L9_2 = L9_2(L10_2, L11_2)
  L8_2 = L8_2 .. L9_2
  return L8_2
end

_FormatMilestoneString = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "string" == L2_2 then
    L2_2 = type
    L3_2 = A1_2
    L2_2 = L2_2(L3_2)
    if "number" == L2_2 then
      goto lbl_12
    end
  end
  do return end
  ::lbl_12::
  L2_2 = A0_2
  L3_2 = string
  L3_2 = L3_2.format
  L4_2 = "[%s:%d]"
  L5_2 = L2_2
  L6_2 = A1_2
  return L3_2(L4_2, L5_2, L6_2)
end

_FormatMilestoneSuffix = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = A0_2.sKey
  L2_2 = GetRewards
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L3_2 = "[Generic.Level] "
  L4_2 = A0_2.nMilestone
  L5_2 = ":\n"
  L3_2 = L3_2 .. L4_2 .. L5_2
  L4_2 = WifMissionFlow
  L4_2 = L4_2.HasKey
  L5_2 = L1_2
  L4_2 = L4_2(L5_2)
  if L4_2 then
    L4_2 = "[check1] "
    L5_2 = L3_2
    L3_2 = L4_2 .. L5_2
  else
    L4_2 = "[check0] "
    L5_2 = L3_2
    L3_2 = L4_2 .. L5_2
  end
  L4_2 = L3_2
  L5_2 = _GenerateStringFromRewardData
  L6_2 = L2_2
  L7_2 = "[indent] "
  L5_2 = L5_2(L6_2, L7_2)
  L4_2 = L4_2 .. L5_2
  return L4_2
end

_FormatLevelMilestoneString = L0_1
