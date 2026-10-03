local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContractOutpost"
L0_1(L1_1)

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = {}
  L0_2.sOutpostBldg = "OilJob005_Outpost"
  L1_2 = {}
  L2_2 = "OilJob005_CapturePt2"
  L1_2[1] = L2_2
  L0_2.tCapturePts = L1_2
  L0_2.sDspShortDesc = "[OilCon052.Objectives.001]"
  L0_2.sStagingLayer = "Vz_State_OilJob005_Staging"
  L0_2.sStagingTgLayer = "Vz_State_OilCon052_Tg"
  L0_2.sPristineLayer = "Vz_State_OilJob005_Pristine"
  L0_2.sDefenseLayer = "Vz_State_OilJob005_Defenses"
  L0_2.sCapturedLayer = "Vz_State_OilJob005_Captured"
  L0_2.sCapturedTgLayer = "Vz_State_OilCon052c_Tg"
  L1_2 = {}
  L0_2.tDangerousBldgs = L1_2
  L0_2.sRivalFaction = "Vza"
  L0_2.nStartingHealth = 3
  L0_2.nRusherQuota = 1
  return L0_2
end

GetOutpostConfig = L0_1
