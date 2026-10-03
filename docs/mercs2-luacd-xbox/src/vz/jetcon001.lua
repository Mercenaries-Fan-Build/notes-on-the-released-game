local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = import
L1_1 = "Munitions"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxAi"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = nil
oExtractBB = L0_1
L0_1 = nil
oDestroyBunker = L0_1
L0_1 = 0
nBBExtracted = L0_1
L0_1 = 0
nCallbackID = L0_1
L0_1 = 0
NETEVENT_SETBBQTY = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = NETEVENT_SETBBQTY
  if A0_2 == L2_2 then
    L2_2 = MrxPmc
    L2_2 = L2_2.SetSupportQty
    L3_2 = "bunkerbuster"
    L4_2 = A1_2[1]
    L2_2(L3_2, L4_2)
  end
end

NetEventCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = {}
  L3_2 = "Vz_State_JetCon001"
  L4_2 = "Vz_State_JetCon001_Pristine"
  L5_2 = "Vz_State_JetCon001_CP01"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L3_2 = MrxLayerManager
  L3_2 = L3_2.Add
  L4_2 = L2_2
  L5_2 = A0_2.AssetsLoaded
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L3_2(L4_2, L5_2, L6_2)
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = MrxSupportData
  L1_2 = L1_2.SetJetPilotRecruited
  L2_2 = true
  L1_2(L2_2)
  L1_2 = Vehicle
  L1_2 = L1_2.Usable
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "JetCon001_ScrambleCopter"
  L2_2 = L2_2(L3_2)
  L3_2 = false
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.BeachRegionActivate
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.AASiteRegionActivate
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.BBWarningRegionActivate
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.BunkerIslandRegionActivate
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "JC001CP02"
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 then
    L1_2 = {}
    L2_2 = "Vz_State_JetCon001_CP01"
    L1_2[1] = L2_2
    L2_2 = MrxLayerManager
    L2_2 = L2_2.Remove
    L3_2 = L1_2
    L2_2(L3_2)
    L2_2 = 3
    nBBExtracted = L2_2
    L2_2 = MrxPmc
    L2_2 = L2_2.SetSupportQty
    L3_2 = "bunkerbuster"
    L4_2 = 3
    L2_2(L3_2, L4_2)
    L2_2 = Net
    L2_2 = L2_2.SendCustomEvent
    L3_2 = "JetCon001"
    L4_2 = NETEVENT_SETBBQTY
    L5_2 = {}
    L6_2 = 3
    L5_2[1] = L6_2
    L2_2(L3_2, L4_2, L5_2)
    L3_2 = A0_2
    L2_2 = A0_2.DestroyBunker
    L2_2(L3_2)
  else
    L2_2 = A0_2
    L1_2 = A0_2._GetFlag
    L3_2 = "JC001CP01"
    L1_2 = L1_2(L2_2, L3_2)
    if L1_2 then
      L1_2 = MrxPmc
      L1_2 = L1_2.SetSupportQty
      L2_2 = "bunkerbuster"
      L3_2 = 0
      L1_2(L2_2, L3_2)
      L1_2 = Net
      L1_2 = L1_2.SendCustomEvent
      L2_2 = "JetCon001"
      L3_2 = NETEVENT_SETBBQTY
      L4_2 = {}
      L5_2 = 0
      L4_2[1] = L5_2
      L1_2(L2_2, L3_2, L4_2)
      L1_2 = 0
      nBBExtracted = L1_2
      L2_2 = A0_2
      L1_2 = A0_2.ExtractBB
      L1_2(L2_2)
    else
      L1_2 = MrxPmc
      L1_2 = L1_2.SetSupportQty
      L2_2 = "bunkerbuster"
      L3_2 = 0
      L1_2(L2_2, L3_2)
      L1_2 = Net
      L1_2 = L1_2.SendCustomEvent
      L2_2 = "JetCon001"
      L3_2 = NETEVENT_SETBBQTY
      L4_2 = {}
      L5_2 = 0
      L4_2[1] = L5_2
      L1_2(L2_2, L3_2, L4_2)
      L1_2 = 0
      nBBExtracted = L1_2
      L2_2 = A0_2
      L1_2 = A0_2.CheckpointRegionActivate
      L1_2(L2_2)
      L2_2 = A0_2
      L1_2 = A0_2.TravelMusicOnRegionActivate
      L1_2(L2_2)
      L2_2 = A0_2
      L1_2 = A0_2.ExtractBB
      L1_2(L2_2)
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = "Fiona-In-Mission-Contract-Jet01-01"
      L4_2 = 0.5
      L5_2 = {}
      L5_2.mattias = "Mattias-Briefing-Cinematic-Carmona-14"
      L5_2.jennifer = "Jennifer-Briefing-Cinematic-Carmona-15"
      L5_2.chris = "Chris-Briefing-Cinematic-Carmona-16"
      L6_2 = 0.5
      L7_2 = "Fiona-In-Mission-Contract-Pir051-02"
      L2_2[1] = L3_2
      L2_2[2] = L4_2
      L2_2[3] = L5_2
      L2_2[4] = L6_2
      L2_2[5] = L7_2
      L1_2(L2_2)
    end
  end
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Region_JetCon001_Checkpoint"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = CheckpointActivate
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

CheckpointRegionActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "JC001CP01"
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2._GetFlag
    L3_2 = "JC001CP02"
    L1_2 = L1_2(L2_2, L3_2)
    if L1_2 then
    else
      L2_2 = A0_2
      L1_2 = A0_2._SetFlag
      L3_2 = "JC001CP01"
      L1_2(L2_2, L3_2)
      L1_2 = _Checkpoint
      L2_2 = {}
      L3_2 = "CP01_P1"
      L4_2 = "CP01_P2"
      L2_2[1] = L3_2
      L2_2[2] = L4_2
      L1_2(L2_2)
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = "Fiona-In-Mission-Contract-Jet01-02"
      L2_2[1] = L3_2
      L1_2(L2_2)
    end
  end
end

CheckpointActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Region_JetCon001_SupplyBeachAssault"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = BeachAssault
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

BeachRegionActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Ai
  L1_2 = L1_2.Goal
  L2_2 = {}
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "JetCon001_BeachAssault_Tank01"
  L4_2, L5_2 = L4_2(L5_2)
  L3_2 = L3_2(L4_2, L5_2)
  L2_2.AIGuid = L3_2
  L2_2.Goal = "PathMove"
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "Path_JetCon001_SupplyBeachAmbush_Tank01"
  L3_2 = L3_2(L4_2)
  L2_2.Target = L3_2
  L2_2.Mode = "Loop"
  L2_2.Priority = "medPri"
  L2_2.Haste = 1
  L1_2(L2_2)
end

BeachAssault = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Region_JetCon001_Supply_AASite01"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = AASiteRegionAssault
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

AASiteRegionActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = {}
  L3_2.mattias = "Mattias-In-Mission-Contract-Jet01-31"
  L3_2.jennifer = "Jennifer-In-Mission-Contract-Jet01-32"
  L3_2.chris = "Chris-In-Mission-Contract-Jet01-33"
  L2_2[1] = L3_2
  L1_2(L2_2)
  L1_2 = Ai
  L1_2 = L1_2.Goal
  L2_2 = {}
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "JetCon001_Supply_AAJeep01"
  L4_2, L5_2 = L4_2(L5_2)
  L3_2 = L3_2(L4_2, L5_2)
  L2_2.AIGuid = L3_2
  L2_2.Goal = "PathMove"
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "JetCon001_AASite01_Jeep_Path"
  L3_2 = L3_2(L4_2)
  L2_2.Target = L3_2
  L2_2.Priority = "hiPri"
  L2_2.Haste = 0.5
  L1_2(L2_2)
end

AASiteRegionAssault = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Region_JetCon001_BBWarning"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = BBWarningVO
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

BBWarningRegionActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Jet01-15"
  L2_2[1] = L3_2
  L1_2(L2_2)
end

BBWarningVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Region_JetCon001_CopterAttack"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = A0_2.CopterSpawn
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

CopterAttackRegionActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Add
  L2_2 = "Vz_State_JetCon001_CopterAttack"
  L3_2 = A0_2.CopterMove
  L4_2 = {}
  L5_2 = A0_2
  L4_2[1] = L5_2
  L1_2(L2_2, L3_2, L4_2)
end

CopterSpawn = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Ai
  L1_2 = L1_2.Goal
  L2_2 = {}
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "JetCon001_AttackCopter"
  L4_2, L5_2 = L4_2(L5_2)
  L3_2 = L3_2(L4_2, L5_2)
  L2_2.AIGuid = L3_2
  L2_2.Goal = "PathMove"
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "Path_JetCon001_CopterAttack"
  L3_2 = L3_2(L4_2)
  L2_2.Target = L3_2
  L2_2.Start = "Nearest"
  L2_2.Mode = "Oneway"
  L2_2.Priority = "HiPri"
  L2_2.Haste = 1
  L3_2 = CopterAttack
  L2_2.Callback = L3_2
  L3_2 = {}
  L4_2 = A0_2
  L3_2[1] = L4_2
  L2_2.CallbackData = L3_2
  L1_2(L2_2)
end

CopterMove = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Ai
  L1_2 = L1_2.Goal
  L2_2 = {}
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "JetCon001_AttackCopter"
  L4_2, L5_2 = L4_2(L5_2)
  L3_2 = L3_2(L4_2, L5_2)
  L2_2.AIGuid = L3_2
  L2_2.Goal = "Attack"
  L3_2 = Player
  L3_2 = L3_2.GetLocalCharacter
  L3_2 = L3_2()
  L2_2.Target = L3_2
  L1_2(L2_2)
end

CopterAttack = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Region_JetCon001_BunkerIslandArrive"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = BunkerIslandArrive
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

BunkerIslandRegionActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Vehicle
  L1_2 = L1_2.Usable
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "JetCon001_ScrambleCopter"
  L2_2 = L2_2(L3_2)
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = Ai
  L1_2 = L1_2.Goal
  L2_2 = {}
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "JetCon001_Jeep_BunkerIsland"
  L4_2, L5_2 = L4_2(L5_2)
  L3_2 = L3_2(L4_2, L5_2)
  L2_2.AIGuid = L3_2
  L2_2.Goal = "PathMove"
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "Path_JetCon001_Bunker_JeepPatrol01"
  L3_2 = L3_2(L4_2)
  L2_2.Target = L3_2
  L2_2.Priority = "medPri"
  L2_2.Haste = 0.5
  L1_2(L2_2)
end

BunkerIslandArrive = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Region_JetCon001_NearBunker"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = NearBunkerVO
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

NearBunkerRegionActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Jet01-43"
  L4_2 = 0.5
  L5_2 = "Fiona-In-Mission-Contract-Jet01-04"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L1_2(L2_2)
end

NearBunkerVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "JetCon001_BunkerBuster"
  L3_2.sModuleName = "MrxTaskObjective"
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "JetCon001_BunkerBuster01"
  L5_2 = L5_2(L6_2)
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "JetCon001_BunkerBuster02"
  L6_2 = L6_2(L7_2)
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "JetCon001_BunkerBuster03"
  L7_2, L8_2 = L7_2(L8_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L3_2.vTgtInclude = L4_2
  L3_2.nQuota = 3
  L4_2 = {}
  L3_2.vTgtExclude = L4_2
  L3_2.sDspShortDesc = "[JetCon001.Objectives.001]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = DestroyBunker
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.Cancel
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnCancel = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  oExtractBB = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "JetCon001_BunkerBuster01"
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = CancelExtractBB
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  uBBDestroyed01 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "JetCon001_BunkerBuster02"
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = CancelExtractBB
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  uBBDestroyed02 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "JetCon001_BunkerBuster03"
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = CancelExtractBB
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  uBBDestroyed03 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "MunitionsPickup"
  
  function L6_2(A0_3)
    local L1_3, L2_3
    L1_3 = Pg
    L1_3 = L1_3.GetGuidByName
    L2_3 = "JetCon001_BunkerBuster01"
    L1_3 = L1_3(L2_3)
    L2_3 = A0_3[2]
    L1_3 = L1_3 == L2_3
    return L1_3
  end
  
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = BBPickup
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = 1
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  uBBExtract01 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "MunitionsPickup"
  
  function L6_2(A0_3)
    local L1_3, L2_3
    L1_3 = Pg
    L1_3 = L1_3.GetGuidByName
    L2_3 = "JetCon001_BunkerBuster02"
    L1_3 = L1_3(L2_3)
    L2_3 = A0_3[2]
    L1_3 = L1_3 == L2_3
    return L1_3
  end
  
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = BBPickup
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = 2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  uBBExtract02 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ScriptEvent
  L4_2 = {}
  L5_2 = "MunitionsPickup"
  
  function L6_2(A0_3)
    local L1_3, L2_3
    L1_3 = Pg
    L1_3 = L1_3.GetGuidByName
    L2_3 = "JetCon001_BunkerBuster03"
    L1_3 = L1_3(L2_3)
    L2_3 = A0_3[2]
    L1_3 = L1_3 == L2_3
    return L1_3
  end
  
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = BBPickup
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = 3
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  uBBExtract03 = L1_2
  L1_2 = Munitions
  L1_2 = L1_2.HideMarker
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "JetCon001_BunkerBuster01"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L2_2(L3_2)
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  L1_2 = Munitions
  L1_2 = L1_2.HideMarker
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "JetCon001_BunkerBuster02"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L2_2(L3_2)
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  L1_2 = Munitions
  L1_2 = L1_2.HideMarker
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "JetCon001_BunkerBuster03"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L2_2(L3_2)
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
end

ExtractBB = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = nBBExtracted
  L2_2 = L2_2 + 1
  nBBExtracted = L2_2
  L2_2 = Net
  L2_2 = L2_2.SendCustomEvent
  L3_2 = "JetCon001"
  L4_2 = NETEVENT_SETBBQTY
  L5_2 = {}
  L6_2 = nBBExtracted
  L5_2[1] = L6_2
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = uBBExtract01
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = "uBBDestroyed01"
    L2_2(L3_2)
  end
  L2_2 = uBBExtract02
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = "uBBDestroyed02"
    L2_2(L3_2)
  end
  L2_2 = uBBExtract03
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = "uBBDestroyed03"
    L2_2(L3_2)
  end
  L2_2 = oExtractBB
  L3_2 = L2_2
  L2_2 = L2_2.CompletePart
  L2_2(L3_2)
  L2_2 = nBBExtracted
  if L2_2 < 3 then
    L2_2 = oExtractBB
    L3_2 = L2_2
    L2_2 = L2_2.RemoveTarget
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "JetCon001_BunkerBuster0"
    L6_2 = A1_2
    L5_2 = L5_2 .. L6_2
    L4_2, L5_2, L6_2 = L4_2(L5_2)
    L2_2(L3_2, L4_2, L5_2, L6_2)
  else
    L3_2 = A0_2
    L2_2 = A0_2.CopterAttackRegionActivate
    L2_2(L3_2)
    L2_2 = MrxVoSequence
    L2_2 = L2_2.Start
    L3_2 = {}
    L4_2 = "Fiona-In-Mission-Contract-Jet01-41"
    L3_2[1] = L4_2
    L2_2(L3_2)
    L3_2 = A0_2
    L2_2 = A0_2._SetFlag
    L4_2 = "JC001CP02"
    L2_2(L3_2, L4_2)
    L2_2 = _Checkpoint
    L3_2 = {}
    L4_2 = "CP02_P1"
    L5_2 = "CP02_P2"
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L2_2(L3_2)
  end
end

BBPickup = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[JetCon001.Terms.Cancel01]"
  L1_2(L2_2, L3_2)
  L1_2 = oExtractBB
  L1_2 = L1_2.Cancel
  L2_2 = oExtractBB
  L1_2(L2_2)
end

CancelExtractBB = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.NearBunkerRegionActivate
  L1_2(L2_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Jet01-03"
  L4_2 = 2
  L5_2 = "Fiona-In-Mission-Contract-Jet01-44"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Destroy the VZ Bunker"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = {}
  L5_2 = "JetCon001_Bunker"
  L4_2[1] = L5_2
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[JetCon001.Objectives.002]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = CompleteDestroyBunker
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.Cancel
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnCancel = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  oDestroyBunker = L1_2
  L1_2 = MrxPmc
  L1_2 = L1_2.SetStockpileChangeCallback
  L2_2 = "bunkerbuster"
  L3_2 = "=="
  L4_2 = 0
  L5_2 = CancelDestroyBunker
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  nCallbackID = L1_2
end

DestroyBunker = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxPmc
  L1_2 = L1_2.DeleteStockpileChangeCallback
  L2_2 = nCallbackID
  L1_2(L2_2)
  L1_2 = MrxSupportData
  L1_2 = L1_2.SetJetPilotRecruited
  L2_2 = false
  L1_2(L2_2)
  L1_2 = {}
  L2_2 = "Vz_State_JetCon001_CP01"
  L1_2[1] = L2_2
  L2_2 = MrxLayerManager
  L2_2 = L2_2.Remove
  L3_2 = L1_2
  L2_2(L3_2)
  L2_2 = MrxTaskContract
  L2_2 = L2_2.Cleanup
  L3_2 = A0_2
  L2_2(L3_2)
end

Cleanup = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 12
  L4_2[1] = L5_2
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = Pg
    L0_3 = L0_3.GetGuidByName
    L1_3 = "JetCon001_Bunker"
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L0_3 = Object
      L0_3 = L0_3.IsAlive
      L1_3 = Pg
      L1_3 = L1_3.GetGuidByName
      L2_3 = "JetCon001_Bunker"
      L1_3, L2_3 = L1_3(L2_3)
      L0_3 = L0_3(L1_3, L2_3)
      if L0_3 then
        L0_3 = A0_2
        L1_3 = L0_3
        L0_3 = L0_3._SetCancelMessage
        L2_3 = "[JetCon001.Terms.Cancel02]"
        L0_3(L1_3, L2_3)
        L0_3 = oDestroyBunker
        L0_3 = L0_3.Cancel
        L1_3 = oDestroyBunker
        L0_3(L1_3)
      else
        L0_3 = oDestroyBunker
        L0_3 = L0_3.Complete
        L1_3 = oDestroyBunker
        L0_3(L1_3)
      end
    else
    end
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

CancelDestroyBunker = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 5
  L4_2[1] = L5_2
  
  function L5_2()
    local L0_3, L1_3
    L0_3 = A0_2
    L0_3 = L0_3.FionaCompleteVO
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

CompleteDestroyBunker = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Misha-In-Mission-Contract-Jet01-05"
  L4_2 = 0.5
  L5_2 = "Fiona-In-Mission-Contract-Jet01-06"
  L6_2 = 1
  L7_2 = {}
  L8_2 = A0_2.Complete
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L1_2(L2_2)
end

FionaCompleteVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Jet01-06"
  L4_2 = 1
  L5_2 = {}
  L6_2 = A0_2.Cancel
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L1_2(L2_2)
end

FionaFailVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Region_JetCon001_TravelMusic"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = StartTravelMusic
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

TravelMusicOnRegionActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Sound
  L1_2 = L1_2.SetActionLevelsMusic
  L2_2 = 10
  L3_2 = 0
  L4_2 = 0
  L5_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = Sound
  L1_2 = L1_2.LockActionLevelMusic
  L2_2 = true
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.TravelMusicOffRegionActivate
  L1_2(L2_2)
end

StartTravelMusic = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Region_JetCon001_Checkpoint"
  L6_2 = L6_2(L7_2)
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = StopTravelMusic
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

TravelMusicOffRegionActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = Sound
  L1_2 = L1_2.LockActionLevelMusic
  L2_2 = false
  L1_2(L2_2)
end

StopTravelMusic = L0_1
