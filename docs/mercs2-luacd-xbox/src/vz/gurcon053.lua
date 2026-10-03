local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContractOutpost"
L0_1(L1_1)

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = {}
  L0_2.sOutpostBldg = "GurJob008_02_Outpost"
  L1_2 = {}
  L2_2 = "GurJob008_02_CapturePt3"
  L1_2[1] = L2_2
  L0_2.tCapturePts = L1_2
  L0_2.sStagingLayer = "Vz_State_GurJob008_02_Staging"
  L0_2.sStagingTgLayer = "Vz_State_GurCon053_Tg"
  L0_2.sPristineLayer = "Vz_State_GurJob008_02_Pristine"
  L0_2.sDefenseLayer = "Vz_State_GurJob008_02_Defenses"
  L0_2.sCapturedLayer = "Vz_State_GurJob008_02_Captured"
  L0_2.sCapturedTgLayer = "Vz_State_GurCon053c_Tg"
  L0_2.sRivalFaction = "Vza"
  L0_2.nStartingHealth = 3
  L0_2.nRusherQuota = 1
  return L0_2
end

GetOutpostConfig = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = MrxTaskContractOutpost
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = WifMissionFlow
  L1_2 = L1_2.HasKey
  L2_2 = "OilCon050"
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.ObjectProximity
    L4_2 = {}
    L5_2 = Player
    L5_2 = L5_2.GetAnyCharacter
    L5_2 = L5_2()
    L6_2 = Pg
    L6_2 = L6_2.GetGuidByName
    L7_2 = "GurJob008_02_Outpost"
    L6_2 = L6_2(L7_2)
    L7_2 = "<"
    L8_2 = 100
    L9_2 = false
    L10_2 = false
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L4_2[3] = L7_2
    L4_2[4] = L8_2
    L4_2[5] = L9_2
    L4_2[6] = L10_2
    L5_2 = NearOutpost
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
    L1_2 = GurCon053_FionaVO_Activate_PreOil
    L2_2 = A0_2
    L1_2(L2_2)
  else
    L1_2 = GurCon053_FionaVO_Activate_PostOil
    L2_2 = A0_2
    L1_2(L2_2)
  end
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona.Misc.Outposts02"
  L4_2 = 0.5
  L5_2 = "Fiona.Misc.Outposts04"
  L6_2 = 0.5
  L7_2 = "Fiona.Misc.Outposts06"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L1_2(L2_2)
end

GurCon053_FionaVO_Activate_PreOil = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona.Misc.Outposts07"
  L2_2[1] = L3_2
  L1_2(L2_2)
end

NearOutpost = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Gur053-01"
  L2_2[1] = L3_2
  L1_2(L2_2)
end

GurCon053_FionaVO_Activate_PostOil = L0_1
