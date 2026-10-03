local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContractOutpost"
L0_1(L1_1)

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = {}
  L0_2.sOutpostBldg = "GurJob003_Outpost"
  L1_2 = {}
  L2_2 = "GurJob003_CapturePt1"
  L1_2[1] = L2_2
  L0_2.tCapturePts = L1_2
  L0_2.sDspShortDesc = "[GurCon050.Objectives.001]"
  L0_2.sStagingLayer = "Vz_State_GurJob003_Staging"
  L0_2.sStagingTgLayer = "Vz_State_GurCon050_Tg"
  L0_2.sPristineLayer = "Vz_State_GurJob003_Pristine"
  L0_2.sDefenseLayer = "Vz_State_GurJob003_Defenses"
  L0_2.sCapturedLayer = "Vz_State_GurJob003_Captured"
  L0_2.sCapturedTgLayer = "Vz_State_GurCon050c_Tg"
  L0_2.sRivalFaction = "Vza"
  L0_2.nStartingHealth = 3
  L0_2.nRusherQuota = 1
  return L0_2
end

GetOutpostConfig = L0_1
