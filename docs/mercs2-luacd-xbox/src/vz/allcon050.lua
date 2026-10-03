local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContractOutpost"
L0_1(L1_1)

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = {}
  L0_2.sOutpostBldg = "AllJob001_01_Outpost"
  L1_2 = {}
  L2_2 = "AllJob001_01_CapturePt1"
  L1_2[1] = L2_2
  L0_2.tCapturePts = L1_2
  L0_2.sStagingLayer = "Vz_State_AllJob001_01_Staging"
  L0_2.sStagingTgLayer = "Vz_State_AllCon050_Tg"
  L0_2.sPristineLayer = "Vz_State_AllJob001_01_Pristine"
  L0_2.sDefenseLayer = "Vz_State_AllJob001_01_Defenses"
  L0_2.sCapturedLayer = "Vz_State_AllJob001_01_Captured"
  L0_2.sCapturedTgLayer = "Vz_State_AllCon050c_Tg"
  L0_2.sRivalFaction = "Vza"
  L0_2.nStartingHealth = 6
  L0_2.nRusherQuota = 1
  return L0_2
end

GetOutpostConfig = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = MrxTaskContractOutpost
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-All050-02"
  L4_2 = 0.5
  L5_2 = {}
  L5_2.mattias = "Mattias-In-Mission-Contract-All050-06"
  L5_2.jennifer = "Jennifer-In-Mission-Contract-All050-07"
  L5_2.chris = "Chris-In-Mission-Contract-All050-08"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L1_2(L2_2)
end

Activated = L0_1
