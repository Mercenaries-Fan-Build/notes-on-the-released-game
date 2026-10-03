local L0_1, L1_1, L2_1, L3_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxLayerManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxOilCon002Delivery"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTimer"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiPda"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPlayer"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTransit"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "DangerousBuilding"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFuelAirBomb"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxCinematic"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTaskObjectiveDestroy"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifBios"
L0_1(L1_1)
L0_1 = {}
L1_1 = "oilcon002_loc_postA"
L2_1 = "oilcon002_loc_postB"
L3_1 = "oilcon002_loc_postC"
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
tBlipLocations = L0_1
L0_1 = 0
NETEVENT_STARTHACK = L0_1
L0_1 = 1
NETEVENT_STOPHACK = L0_1
L0_1 = 2
NETEVENT_MOVE_LUCKY_LADY = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = NETEVENT_STARTHACK
  if A0_2 == L2_2 then
    L2_2 = NetSafeStartHack
    L2_2()
  else
    L2_2 = NETEVENT_STOPHACK
    if A0_2 == L2_2 then
      L2_2 = StopHack
      L3_2 = tBlipLocations
      L2_2(L3_2)
    else
      L2_2 = NETEVENT_MOVE_LUCKY_LADY
      if A0_2 == L2_2 then
        L2_2 = Object
        L2_2 = L2_2.SetTransformToObject
        L3_2 = A1_2[1]
        L4_2 = Pg
        L4_2 = L4_2.GetGuidByName
        L5_2 = "OilCon002_HeliTele"
        L4_2, L5_2 = L4_2(L5_2)
        L2_2(L3_2, L4_2, L5_2)
      end
    end
  end
end

NetEventCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L1_2 = WifBios
  L1_2 = L1_2.AddDossierEntry
  L2_2 = "BioEwan"
  L1_2(L2_2)
  L1_2 = Player
  L1_2 = L1_2.GetAnyCharacter
  L1_2 = L1_2()
  uPlayer = L1_2
  L1_2 = Player
  L1_2 = L1_2.GetPrimaryCharacter
  L1_2 = L1_2()
  uPrimaryPlayer = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "oilcon002_loc_postA"
  L1_2 = L1_2(L2_2)
  oPostLoc01 = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "oilcon002_loc_postB"
  L1_2 = L1_2(L2_2)
  oPostLoc02 = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "oilcon002_loc_postC"
  L1_2 = L1_2(L2_2)
  oPostLoc03 = L1_2
  L1_2 = {}
  L2_2 = "ArmoredTruck_OilCon002_Target01"
  L3_2 = "ArmoredTruck_OilCon002_Target02"
  L4_2 = "ArmoredTruck_OilCon002_Target03"
  L5_2 = "ArmoredTruck_OilCon002_Target04"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  tVanList = L1_2
  L1_2 = {}
  L2_2 = "Fiona-In-Mission-Contract-Oil02-07"
  L3_2 = 1.5
  L4_2 = "Ewan-In-Mission-Contract-Oil02-104"
  L5_2 = 1
  L6_2 = {}
  L6_2.mattias = "Mattias-In-Mission-Contract-Oil02-105"
  L6_2.jennifer = "Jennifer-In-Mission-Contract-Oil02-106"
  L6_2.chris = "Chris-In-Mission-Contract-Oil02-107"
  L7_2 = "Fiona-In-Mission-Contract-Oil02-108"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  tPost01Lines = L1_2
  L1_2 = {}
  L2_2 = "Fiona-In-Mission-Contract-Oil02-42"
  L3_2 = 1.5
  L4_2 = "Ewan-None-Freeplay-Support-99"
  L5_2 = {}
  L5_2.mattias = "Mattias-In-Mission-Contract-Oil02-110"
  L5_2.jennifer = "Jennifer-In-Mission-Contract-Oil02-111"
  L5_2.chris = "Chris-In-Mission-Contract-Oil02-112"
  L6_2 = "Fiona-In-Mission-Contract-Oil02-113"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  tPost02Lines = L1_2
  L1_2 = {}
  L2_2 = "Fiona-In-Mission-Contract-Oil02-08"
  L3_2 = "Rubin-In-Mission-Contract-Oil02-29"
  L4_2 = "VZSoldier-In-Mission-Contract-Oil02-26"
  L5_2 = "Rubin-In-Mission-Contract-Oil02-27"
  L6_2 = "VZSoldier-In-Mission-Contract-Oil02-28"
  L7_2 = 0.5
  L8_2 = "Fiona-In-Mission-Contract-Oil02-25"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L1_2[7] = L8_2
  tPost03Lines = L1_2
  L1_2 = {}
  L2_2 = tPost01Lines
  L3_2 = tPost02Lines
  L4_2 = tPost03Lines
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  tDeliveryLines = L1_2
  L1_2 = 15
  nTimeLimit = L1_2
  L1_2 = table
  L1_2 = L1_2.getn
  L2_2 = tBlipLocations
  L1_2 = L1_2(L2_2)
  nTotalDeliveryLocs = L1_2
  L1_2 = "[OilCon002.Objectives.deliverPosts]"
  sDeliveryObjectiveText = L1_2
  L1_2 = "[OilCon002.Display.deadline]"
  sDeadlineText = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "OilCon002_RescueSite"
  L1_2 = L1_2(L2_2)
  uRescueLoc = L1_2
  L1_2 = {}
  tFalse = L1_2
  L1_2 = {}
  tCompletedLoc = L1_2
  L1_2 = 0
  nPartsComplete = L1_2
  L1_2 = true
  bCheckActive = L1_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._GetFlag
  L3_2 = "AllPostsPlaced"
  L1_2 = L1_2(L2_2, L3_2)
  L3_2 = A0_2
  L2_2 = A0_2._GetFlag
  L4_2 = "PartPostsPlaced"
  L2_2 = L2_2(L3_2, L4_2)
  nRecoverStatus = L2_2
  if L1_2 then
    L2_2 = MrxOilCon002Delivery
    L2_2 = L2_2.GetCurrentDropZones
    L2_2 = L2_2()
    L4_2 = A0_2
    L3_2 = A0_2.LoadVansLayer
    L3_2(L4_2)
    nTimeLimit = L1_2
    L3_2 = MrxTimer
    L4_2 = L3_2
    L3_2 = L3_2.Create
    L5_2 = {}
    L6_2 = nTimeLimit
    L5_2.nStartTime = L6_2
    L5_2.iTray = 2
    L6_2 = {}
    L7_2 = {}
    L8_2 = Cancel
    L9_2 = {}
    L10_2 = A0_2
    L9_2[1] = L10_2
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L6_2[1] = L7_2
    L5_2.tDoneCallbacks = L6_2
    L3_2 = L3_2(L4_2, L5_2)
    oMissionTimer = L3_2
    L3_2 = oMissionTimer
    L4_2 = L3_2
    L3_2 = L3_2.Start
    L3_2(L4_2)
    L3_2 = FreebieAdd
    L4_2 = A0_2
    L5_2 = 1
    L6_2 = false
    L3_2(L4_2, L5_2, L6_2)
    L3_2 = MrxVoSequence
    L3_2 = L3_2.Start
    L4_2 = tPost03Lines
    L3_2(L4_2)
    L3_2 = Hud
    L3_2 = L3_2.ObjectiveTray
    L4_2 = L3_2
    L3_2 = L3_2.SetSlotToText
    L5_2 = {}
    L5_2.nSlot = 1
    L6_2 = sDeadlineText
    L5_2.sText = L6_2
    L3_2(L4_2, L5_2)
    L3_2 = ipairs
    L4_2 = L2_2
    L3_2, L4_2, L5_2 = L3_2(L4_2)
    for L6_2, L7_2 in L3_2, L4_2, L5_2 do
      L8_2 = Pg
      L8_2 = L8_2.GetGuidByName
      L9_2 = L7_2
      L8_2 = L8_2(L9_2)
      L9_2 = Object
      L9_2 = L9_2.GetPosition
      L10_2 = L8_2
      L9_2, L10_2, L11_2 = L9_2(L10_2)
      L13_2 = A0_2
      L12_2 = A0_2._CreateEvent
      L14_2 = Event
      L14_2 = L14_2.ObjectProximity
      L15_2 = {}
      L16_2 = uPlayer
      L17_2 = L8_2
      L18_2 = "<"
      L19_2 = 150
      L20_2 = false
      L21_2 = true
      L15_2[1] = L16_2
      L15_2[2] = L17_2
      L15_2[3] = L18_2
      L15_2[4] = L19_2
      L15_2[5] = L20_2
      L15_2[6] = L21_2
      L16_2 = Pg
      L16_2 = L16_2.Spawn
      L17_2 = {}
      L18_2 = "Listening Post"
      L19_2 = L9_2
      L20_2 = L10_2
      L21_2 = L11_2
      L17_2[1] = L18_2
      L17_2[2] = L19_2
      L17_2[3] = L20_2
      L17_2[4] = L21_2
      L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2)
      eSpawnPosts = L12_2
    end
  else
    L2_2 = nRecoverStatus
    if L2_2 then
      L3_2 = A0_2
      L2_2 = A0_2.RecoverPostsStatus
      L2_2(L3_2)
    else
      L2_2 = StartPostDeliveryObjective
      L3_2 = A0_2
      L2_2(L3_2)
    end
  end
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = uPlayer
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "OilCon002_ParkingStructure01(critical)"
  L7_2 = L7_2(L8_2)
  L8_2 = "<"
  L9_2 = 75
  L10_2 = false
  L11_2 = true
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  
  function L6_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = Pg
    L0_3 = L0_3.Spawn
    L1_3 = "Emplaced MG (VZ)"
    L2_3 = 3038.45
    L3_3 = -4.41
    L4_3 = 1461.63
    L5_3 = 90
    L0_3 = L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
    uParkingStructureMG = L0_3
  end
  
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  eSpawnMG = L2_2
  L2_2 = Vehicle
  L2_2 = L2_2.Usable
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "OilCon002_VZAirportHeli01"
  L3_2 = L3_2(L4_2)
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = Vehicle
  L2_2 = L2_2.Usable
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "OilCon002_VZAirportHeli02"
  L3_2 = L3_2(L4_2)
  L4_2 = false
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = uPlayer
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "OilCon002_VZHeliPilot"
  L7_2 = L7_2(L8_2)
  L8_2 = "<"
  L9_2 = 150
  L10_2 = false
  L11_2 = true
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  
  function L6_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L1_3 = Pg
    L1_3 = L1_3.Spawn
    L2_3 = "VZ Officer"
    L3_3 = 3171
    L4_3 = -3.63
    L5_3 = 1501.2
    L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3)
    uVZPilot = L1_3
    L2_3 = A0_3
    L1_3 = A0_3._CreateEvent
    L3_3 = Event
    L3_3 = L3_3.ObjectIsReady
    L4_3 = {}
    L5_3 = uVZPilot
    L4_3[1] = L5_3
    
    function L5_3(A0_4)
      local L1_4, L2_4, L3_4, L4_4, L5_4, L6_4, L7_4, L8_4
      L1_4 = Vehicle
      L1_4 = L1_4.Usable
      L2_4 = Pg
      L2_4 = L2_4.GetGuidByName
      L3_4 = "OilCon002_VZAirportHeli01"
      L2_4 = L2_4(L3_4)
      L3_4 = true
      L1_4(L2_4, L3_4)
      L1_4 = Ai
      L1_4 = L1_4.Goal
      L2_4 = {}
      L3_4 = uVZPilot
      L2_4.AIGuid = L3_4
      L2_4.Goal = "MoveTo"
      L3_4 = Pg
      L3_4 = L3_4.GetGuidByName
      L4_4 = "OilCon002_VZAirportHeli01"
      L3_4 = L3_4(L4_4)
      L2_4.Target = L3_4
      L2_4.Haste = 0.7
      L2_4.Priority = "HiPri"
      L3_4 = Vehicle
      L3_4 = L3_4.Enter
      L2_4.Callback = L3_4
      L3_4 = {}
      L4_4 = Pg
      L4_4 = L4_4.GetGuidByName
      L5_4 = "OilCon002_VZAirportHeli01"
      L4_4 = L4_4(L5_4)
      L5_4 = uVZPilot
      L6_4 = "d"
      L7_4 = false
      L8_4 = false
      L3_4[1] = L4_4
      L3_4[2] = L5_4
      L3_4[3] = L6_4
      L3_4[4] = L7_4
      L3_4[5] = L8_4
      L2_4.CallbackData = L3_4
      L1_4(L2_4)
      L2_4 = A0_4
      L1_4 = A0_4._CreateEvent
      L3_4 = Event
      L3_4 = L3_4.ObjectInSeat
      L4_4 = {}
      L5_4 = uVZPilot
      L6_4 = Pg
      L6_4 = L6_4.GetGuidByName
      L7_4 = "OilCon002_VZAirportHeli01"
      L6_4 = L6_4(L7_4)
      L7_4 = "d"
      L8_4 = "ei"
      L4_4[1] = L5_4
      L4_4[2] = L6_4
      L4_4[3] = L7_4
      L4_4[4] = L8_4
      
      function L5_4(A0_5)
        local L1_5, L2_5, L3_5, L4_5
        L1_5 = Ai
        L1_5 = L1_5.Goal
        L2_5 = {}
        L3_5 = uVZPilot
        L2_5.AIGuid = L3_5
        L2_5.Goal = "HeliTakeoff"
        L2_5.Priority = "hiPri"
        L1_5 = L1_5(L2_5)
        VZTakeoff = L1_5
        L1_5 = VZTakeoff
        if L1_5 then
          L1_5 = Ai
          L1_5 = L1_5.Anchor
          L2_5 = {}
          L3_5 = uActor
          L2_5.AIGuid = L3_5
          L2_5.AnchorRadius = 200
          L3_5 = Pg
          L3_5 = L3_5.GetGuidByName
          L4_5 = "OilCon002_VZAirportHeliPath"
          L3_5 = L3_5(L4_5)
          L2_5.AnchorGuid = L3_5
          L1_5(L2_5)
          L1_5 = Ai
          L1_5 = L1_5.Goal
          L2_5 = {}
          L3_5 = uVZPilot
          L2_5.AIGuid = L3_5
          L2_5.Goal = "PathMove"
          L3_5 = Pg
          L3_5 = L3_5.GetGuidByName
          L4_5 = "OilCon002_VZAirportHeliPath"
          L3_5 = L3_5(L4_5)
          L2_5.Target = L3_5
          L2_5.Haste = 0.575
          L2_5.Mode = "Loop"
          L2_5.Priority = "loPri"
          L1_5(L2_5)
        end
      end
      
      L6_4 = {}
      L7_4 = A0_4
      L6_4[1] = L7_4
      L1_4 = L1_4(L2_4, L3_4, L4_4, L5_4, L6_4)
      eVZHeliPatrol = L1_4
    end
    
    L6_3 = {}
    L7_3 = A0_3
    L6_3[1] = L7_3
    L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
    eVZPilotGetIn = L1_3
  end
  
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  eVZPilotTakeoff = L2_2
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectDeath
  L5_2 = {}
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "OilCon002_ParkingStructure01(critical)"
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L6_2(L7_2)
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L5_2[7] = L12_2
  L5_2[8] = L13_2
  L5_2[9] = L14_2
  L5_2[10] = L15_2
  L5_2[11] = L16_2
  L5_2[12] = L17_2
  L5_2[13] = L18_2
  L5_2[14] = L19_2
  L5_2[15] = L20_2
  L5_2[16] = L21_2
  L6_2 = GarageDeath
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  eParkStructDeath = L2_2
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L1_2 = {}
  L2_2 = oPostLoc01
  L3_2 = oPostLoc02
  L4_2 = oPostLoc03
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  tCompleted = L1_2
  L1_2 = {}
  tCompPosts = L1_2
  L1_2 = 0
  nReset = L1_2
  L1_2 = false
  bReconfig = L1_2
  L1_2 = MrxOilCon002Delivery
  L1_2 = L1_2.ResetDropZones
  L1_2()
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "OilCon002_MasterDelivery"
  L3_2.sModuleName = "MrxTaskObjective"
  L4_2 = sDeliveryObjectiveText
  L3_2.sDspShortDesc = L4_2
  L3_2.nQuota = 3
  L3_2.bDspMsgCcl = false
  L4_2 = {}
  L5_2 = {}
  L6_2 = AllPostsCheck
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  L4_2 = {}
  L5_2 = "Fiona-Banter-Contract-Oil02-01"
  L6_2 = {}
  L6_2.mattias = "Mattias-Banter-Contract-Oil02-02"
  L6_2.jennifer = "Jennifer-Banter-Contract-Oil02-03"
  L6_2.chris = "Chris-Banter-Contract-Oil02-04"
  L7_2 = 2
  L8_2 = "Fiona-In-Mission-Contract-Oil02-03"
  L9_2 = 0.5
  L10_2 = "Fiona-In-Mission-Contract-Oil02-06"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L3_2.vVoSeqOnAdd = L4_2
  
  function L4_2()
    local L0_3, L1_3
    L0_3 = MrxTutorialManager
    L0_3 = L0_3.ShowMessage
    L1_3 = "[OilCon002.Tutorial.pDAReminder]"
    L0_3(L1_3)
    L0_3 = TutorialRemove
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L3_2.fOnInitialNotesComplete = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  uMasterDeliveryObj = L1_2
  L1_2 = uMasterDeliveryObj
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = 34
    L4_2[1] = L5_2
    
    function L5_2(A0_3)
      local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3
      L1_3 = MrxVoSequence
      L1_3 = L1_3.Start
      L2_3 = {}
      L3_3 = "Ewan-In-Mission-Contract-Oil02-96"
      L4_3 = {}
      L4_3.mattias = "Mattias-In-Mission-Contract-Oil02-100"
      L4_3.jennifer = "Jennifer-In-Mission-Contract-Oil02-101"
      L4_3.chris = "Chris-In-Mission-Contract-Oil02-102"
      L5_3 = "Ewan-In-Mission-Contract-Oil02-103"
      L6_3 = 5
      L7_3 = "Fiona-In-Mission-Contract-Oil02-133"
      L8_3 = {}
      L9_3 = FreebieAdd
      L10_3 = {}
      L11_3 = A0_3
      L12_3 = 2
      L13_3 = true
      L10_3[1] = L11_3
      L10_3[2] = L12_3
      L10_3[3] = L13_3
      L8_3[1] = L9_3
      L8_3[2] = L10_3
      L2_3[1] = L3_3
      L2_3[2] = L4_3
      L2_3[3] = L5_3
      L2_3[4] = L6_3
      L2_3[5] = L7_3
      L2_3[6] = L8_3
      L1_3(L2_3)
    end
    
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  end
  L1_2 = ExitReminder
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = MrxOilCon002Delivery
  L1_2 = L1_2.GetCurrentDropZones
  L1_2 = L1_2()
  tDeliveryLocations = L1_2
  L1_2 = {}
  uSubDelivery = L1_2
  L1_2 = ipairs
  L2_2 = tDeliveryLocations
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = AddPostDelivery
    L7_2 = A0_2
    L8_2 = Pg
    L8_2 = L8_2.GetGuidByName
    L9_2 = L5_2
    L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2 = L8_2(L9_2)
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
    L6_2 = uSubDelivery
    L8_2 = A0_2
    L7_2 = A0_2.CreateChild
    L9_2 = {}
    L10_2 = "OilCon002_SubDelivery"
    L11_2 = L4_2
    L10_2 = L10_2 .. L11_2
    L9_2.sName = L10_2
    L9_2.sModuleName = "MrxTaskObjectiveDeliver"
    L9_2.sTgtLabelFilter = "Listening Post"
    L10_2 = sDeliveryObjectiveText
    L9_2.sDspShortDesc = L10_2
    L9_2.bDspDescPda = false
    L9_2.vDestLoc = L5_2
    L9_2.nQuota = 1
    L9_2.fDist = 10
    L9_2.bUseDestRing = true
    L9_2.bDisplayHelpText = false
    L9_2.bXZOnly = false
    L9_2.bDspMsg = false
    L10_2 = {}
    L11_2 = {}
    L12_2 = SubDeliveryComplete
    L13_2 = {}
    L14_2 = A0_2
    L15_2 = L5_2
    L13_2[1] = L14_2
    L13_2[2] = L15_2
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L10_2[1] = L11_2
    L9_2.tOnComplete = L10_2
    L7_2 = L7_2(L8_2, L9_2)
    L6_2[L5_2] = L7_2
  end
end

StartPostDeliveryObjective = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Add
  L2_2 = "VZ_state_OilCon002_Objectives"
  L1_2(L2_2)
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Add
  L2_2 = "VZ_state_OilCon002_Objectives02"
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 2
  L4_2[1] = L5_2
  L5_2 = StartVansMoving
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  eVanLayerReady = L1_2
end

LoadVansLayer = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = uSubDelivery
  if L1_2 then
    L1_2 = pairs
    L2_2 = uSubDelivery
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    for L4_2, L5_2 in L1_2, L2_2, L3_2 do
      L7_2 = L5_2
      L6_2 = L5_2.Cancel
      L6_2(L7_2)
    end
  end
  L1_2 = math
  L1_2 = L1_2.randi
  L2_2 = table
  L2_2 = L2_2.getn
  L3_2 = tVanList
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  nTargNum = L1_2
  L1_2 = tVanList
  L2_2 = nTargNum
  L1_2 = L1_2[L2_2]
  sTargVan = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = sTargVan
  L1_2 = L1_2(L2_2)
  uTargVan = L1_2
  L1_2 = uTargVan
  uBlipTarget = L1_2
  L1_2 = Vehicle
  L1_2 = L1_2.GetDriver
  L2_2 = uTargVan
  L1_2 = L1_2(L2_2)
  uVZDriver = L1_2
  L1_2 = Vehicle
  L1_2 = L1_2.GetRiders
  L2_2 = uTargVan
  L3_2 = "p"
  L1_2 = L1_2(L2_2, L3_2)
  tVZShotgun = L1_2
  L1_2 = tVZShotgun
  L1_2 = L1_2[1]
  uVZShotgun = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectHealthLessThan
  L4_2 = {}
  L5_2 = uTargVan
  L6_2 = 1
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = TimeOut
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  eTargetVanDeath = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = uPlayer
  L6_2 = uTargVan
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
  L5_2 = HostageInVan
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = uTargVan
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  eVanReady = L1_2
  L1_2 = StartHack
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 40
  L4_2[1] = L5_2
  L5_2 = StartHijackObjective
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

StartVansMoving = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = A1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L5_2 = Pg
  L5_2 = L5_2.Spawn
  L6_2 = "OC Executive (OilCon002_Hostage)"
  L7_2 = L2_2
  L8_2 = L3_2
  L9_2 = L4_2 + 30
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  uHostage = L5_2
  L5_2 = Vehicle
  L5_2 = L5_2.GetSeatFromRider
  L6_2 = uVZShotgun
  L5_2 = L5_2(L6_2)
  uHostSeat = L5_2
  L5_2 = Ai
  L5_2 = L5_2.SetRelation
  L6_2 = GetGuidByName
  L7_2 = "OC"
  L6_2 = L6_2(L7_2)
  L7_2 = uVZDriver
  L8_2 = 0
  L5_2(L6_2, L7_2, L8_2)
  L5_2 = Ai
  L5_2 = L5_2.SetRelation
  L6_2 = GetGuidByName
  L7_2 = "OC"
  L6_2 = L6_2(L7_2)
  L7_2 = uVZShotgun
  L8_2 = 0
  L5_2(L6_2, L7_2, L8_2)
  L6_2 = A0_2
  L5_2 = A0_2._CreateEvent
  L7_2 = Event
  L7_2 = L7_2.ObjectHibernation
  L8_2 = {}
  L9_2 = uHostage
  L10_2 = "awake"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  
  function L9_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L1_3 = Ai
    L1_3 = L1_3.SetState
    L2_3 = {}
    L3_3 = uHostage
    L2_3.AIGuid = L3_3
    L2_3.State = "Pacifist"
    L2_3.Value = true
    L1_3(L2_3)
    L1_3 = Ai
    L1_3 = L1_3.SetRelation
    L2_3 = GetGuidByName
    L3_3 = "VZ"
    L2_3 = L2_3(L3_3)
    L3_3 = uHostage
    L4_3 = 0
    L1_3(L2_3, L3_3, L4_3)
    L1_3 = Vehicle
    L1_3 = L1_3.EnterBySeatGuid
    L2_3 = A1_2
    L3_3 = uHostage
    L4_3 = uHostSeat
    L5_3 = true
    L6_3 = false
    L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
    bHostageIn = L1_3
    L1_3 = bHostageIn
    if L1_3 then
      L2_3 = A0_3
      L1_3 = A0_3._CreateEvent
      L3_3 = Event
      L3_3 = L3_3.TimerRelative
      L4_3 = {}
      L5_3 = 1
      L4_3[1] = L5_3
      L5_3 = Object
      L5_3 = L5_3.Remove
      L6_3 = {}
      L7_3 = uVZShotgun
      L6_3[1] = L7_3
      L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
    end
  end
  
  L10_2 = {}
  L11_2 = A0_2
  L10_2[1] = L11_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  eHostageReady = L5_2
  L5_2 = uHostage
  if L5_2 then
    L6_2 = A0_2
    L5_2 = A0_2._CreateEvent
    L7_2 = Event
    L7_2 = L7_2.ObjectDeath
    L8_2 = {}
    L9_2 = uHostage
    L8_2[1] = L9_2
    L9_2 = TimeOut
    L10_2 = {}
    L11_2 = A0_2
    L10_2[1] = L11_2
    L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
    eHostageDeath = L5_2
  end
end

HostageInVan = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = StopHack
  L2_2 = tBlipLocations
  L1_2(L2_2)
  L1_2 = StopHack
  L2_2 = tVanList
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = uPlayer
  L6_2 = uTargVan
  L7_2 = "<"
  L8_2 = 10
  L9_2 = false
  L10_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  
  function L5_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = MrxVoSequence
    L1_3 = L1_3.Start
    L2_3 = {}
    L3_3 = "Fiona-In-Mission-Contract-Oil02-135"
    L2_3[1] = L3_3
    L1_3(L2_3)
  end
  
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  eHijackHint = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "OilCon02_HijackTruck"
  L3_2.sModuleName = "MrxTaskObjectiveEnterVehicle"
  L3_2.sDspShortDesc = "[OilCon002.Objectives.hijack]"
  L4_2 = uTargVan
  L3_2.vTgtInclude = L4_2
  L3_2.nQuota = 1
  L3_2.bUseAnySeat = false
  L4_2 = {}
  L5_2 = {}
  L6_2 = PlayerInVan
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
  L4_2 = {}
  L5_2 = "Fiona-In-Mission-Contract-Oil02-19"
  L4_2[1] = L5_2
  L3_2.vVoSeqOnAdd = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  oVanHijack = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 8
  L4_2[1] = L5_2
  L5_2 = EwanInterlude
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  eEwanHire = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = uVZDriver
  L4_2[1] = L5_2
  
  function L5_2(A0_3)
    local L1_3, L2_3
    L1_3 = Object
    L1_3 = L1_3.IsAlive
    L2_3 = uHostage
    L1_3 = L1_3(L2_3)
    if L1_3 then
      L1_3 = A0_3.oVanHijack
      L2_3 = L1_3
      L1_3 = L1_3.Complete
      L1_3(L2_3)
    end
  end
  
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  eDriverCheck = L1_2
end

StartHijackObjective = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L1_2 = Vehicle
  L1_2 = L1_2.GetDriver
  L2_2 = uTargVan
  L1_2 = L1_2(L2_2)
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "TransitHeli_Spawn"
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2 = L3_2(L4_2)
  L2_2, L3_2, L4_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  L5_2 = Object
  L5_2 = L5_2.GetYaw
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "TransitHeli_Spawn"
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2 = L6_2(L7_2)
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  L6_2 = MrxVoSequence
  L6_2 = L6_2.Start
  L7_2 = {}
  L8_2 = "Fiona-In-Mission-Contract-Oil02-94"
  L7_2[1] = L8_2
  L6_2(L7_2)
  L7_2 = A0_2
  L6_2 = A0_2.CreateChild
  L8_2 = {}
  L8_2.sName = "OilCon02_HostageDelivery"
  L8_2.sModuleName = "MrxTaskObjectiveDeliver"
  L9_2 = uHostage
  L8_2.vTgtInclude = L9_2
  L9_2 = Pg
  L9_2 = L9_2.GetGuidByName
  L10_2 = "OilCon002_RescueSite"
  L9_2 = L9_2(L10_2)
  L8_2.vDestLoc = L9_2
  L8_2.fDist = 15
  L8_2.bStop = true
  L8_2.bXZOnly = false
  L8_2.sDspShortDesc = "[OilCon002.Objectives.deliverHostage02]"
  L8_2.uStartAttachedToPlayer = L1_2
  L9_2 = {}
  L10_2 = {}
  L11_2 = TransitStart
  L12_2 = {}
  L13_2 = A0_2
  L12_2[1] = L13_2
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L9_2[1] = L10_2
  L8_2.tOnComplete = L9_2
  L9_2 = {}
  L10_2 = {}
  L11_2 = A0_2.Cancel
  L12_2 = {}
  L13_2 = A0_2
  L12_2[1] = L13_2
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L9_2[1] = L10_2
  L8_2.tOnCancel = L9_2
  L6_2(L7_2, L8_2)
  L6_2 = Ai
  L6_2 = L6_2.Anchor
  L7_2 = {}
  L8_2 = uHostage
  L7_2.AIGuid = L8_2
  L7_2.AnchorRadius = 50
  L7_2.AnchorGuid = L1_2
  L6_2(L7_2)
  L7_2 = A0_2
  L6_2 = A0_2._CreateEvent
  L8_2 = Event
  L8_2 = L8_2.ObjectProximity
  L9_2 = {}
  L10_2 = uHostage
  L11_2 = Pg
  L11_2 = L11_2.GetGuidByName
  L12_2 = "OilCon002_RescueSite"
  L11_2 = L11_2(L12_2)
  L12_2 = "<"
  L13_2 = 20
  L14_2 = false
  L15_2 = true
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L9_2[3] = L12_2
  L9_2[4] = L13_2
  L9_2[5] = L14_2
  L9_2[6] = L15_2
  
  function L10_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
    L1_3 = Pg
    L1_3 = L1_3.Spawn
    L2_3 = "UH1 Transport (PMC) (Driver)"
    L3_3 = L2_2
    L4_3 = L3_2
    L5_3 = L4_2
    L6_3 = L5_2
    L7_3 = false
    L8_3 = true
    L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3)
    uLuckyLady = L1_3
    L1_3 = Vehicle
    L1_3 = L1_3.GetDriver
    L2_3 = uLuckyLady
    L1_3 = L1_3(L2_3)
    uEwan = L1_3
    L1_3 = Ai
    L1_3 = L1_3.Goal
    L2_3 = {}
    L3_3 = uEwan
    L2_3.AIGuid = L3_3
    L2_3.Goal = "PathMove"
    L3_3 = Pg
    L3_3 = L3_3.GetGuidByName
    L4_3 = "OilCon002_EwanHoldingPath"
    L3_3 = L3_3(L4_3)
    L2_3.Target = L3_3
    L2_3.Haste = 0.25
    L2_3.Priority = "LoPri"
    L1_3(L2_3)
    L2_3 = A0_3
    L1_3 = A0_3._CreateEvent
    L3_3 = Event
    L3_3 = L3_3.ObjectDeath
    L4_3 = {}
    L5_3 = uEwan
    L4_3[1] = L5_3
    L5_3 = EwanDeath
    L6_3 = {}
    L7_3 = A0_3
    L6_3[1] = L7_3
    L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
    ePilotEwanDeath = L1_3
    L1_3 = uLuckyLady
    if L1_3 then
      L1_3 = Event
      L1_3 = L1_3.Delete
      L2_3 = eSpawnEwan
      L1_3(L2_3)
    end
  end
  
  L11_2 = {}
  L12_2 = A0_2
  L11_2[1] = L12_2
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  eSpawnLLTrans = L6_2
end

StartRescueObjective = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = MrxUtil
  L1_2 = L1_2.GetDistanceToObject
  L2_2 = uTargVan
  L3_2 = 2517.5
  L4_2 = -33.75
  L5_2 = 1490.2
  L6_2 = true
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  nDist2hq = L1_2
  L1_2 = ClearTimer
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = eTargetVanDeath
  L1_2 = L1_2(L2_2)
  eVanDeathCancel = L1_2
  L1_2 = nil
  eTargetVanDeath = L1_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = {}
  L4_2 = "OilExec-In-Mission-Contract-Oil02-89"
  L5_2 = uHostage
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L4_2 = 0.25
  L5_2 = {}
  L5_2.mattias = "Mattias-In-Mission-Contract-Oil02-90"
  L5_2.jennifer = "Jennifer-In-Mission-Contract-Oil02-91"
  L5_2.chris = "Chris-In-Mission-Contract-Oil02-92"
  L6_2 = 0
  L7_2 = {}
  L8_2 = "OilExec-In-Mission-Contract-Oil02-93"
  L9_2 = uHostage
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L8_2 = {}
  L9_2 = StartRescueObjective
  L10_2 = {}
  L11_2 = A0_2
  L10_2[1] = L11_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L2_2[6] = L8_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectInSeat
  L4_2 = {}
  L5_2 = uHostage
  L6_2 = uTargVan
  L7_2 = "p"
  L8_2 = "xo"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = Ai
  L5_2 = L5_2.SetRelation
  L6_2 = {}
  L7_2 = GetGuidByName
  L8_2 = "VZ"
  L7_2 = L7_2(L8_2)
  L8_2 = uHostage
  L9_2 = -100
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  eHostageFree = L1_2
end

PlayerInVan = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = oMissionTimer
  if L1_2 then
    L1_2 = ClearTimer
    L2_2 = A0_2
    L1_2(L2_2)
  end
  L1_2 = uLuckyLady
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.ObjectHibernation
    L4_2 = {}
    L5_2 = uLuckyLady
    L6_2 = "hibernated"
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L5_2 = Object
    L5_2 = L5_2.Remove
    L6_2 = {}
    L7_2 = uLuckyLady
    L6_2[1] = L7_2
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  end
  L1_2 = StopHack
  L2_2 = tBlipLocations
  L1_2(L2_2)
  L1_2 = StopHack
  L2_2 = tVanList
  L1_2(L2_2)
  L1_2 = RemovePosts
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = 0
  nTotal = L1_2
  L1_2 = MrxTransit
  L1_2 = L1_2.Reset
  L1_2()
  L1_2 = MrxSupportData
  L1_2 = L1_2.RemoveFreebie
  L2_2 = "OilCon002_OC"
  L1_2(L2_2)
  L1_2 = MrxSupportData
  L1_2 = L1_2.RemoveFreebie
  L2_2 = "OilCon002_EXT"
  L1_2(L2_2)
  L1_2 = MrxSupportData
  L1_2 = L1_2.RemoveFreebie
  L2_2 = "OilCon002_LightMG"
  L1_2(L2_2)
  L1_2 = MrxSupportData
  L1_2 = L1_2.RemoveFreebie
  L2_2 = "OC_ClusterBomb"
  L1_2(L2_2)
  L1_2 = MrxLayerManager
  L1_2 = L1_2.MarkForRemoval
  L2_2 = "Vz_State_OilCon002"
  L1_2(L2_2)
  L1_2 = MrxLayerManager
  L1_2 = L1_2.MarkForRemoval
  L2_2 = "VZ_state_OilCon002_Objectives"
  L1_2(L2_2)
  L1_2 = MrxLayerManager
  L1_2 = L1_2.MarkForRemoval
  L2_2 = "VZ_state_OilCon002_Objectives02"
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 0.75
  L4_2[1] = L5_2
  L5_2 = MrxLayerManager
  L5_2 = L5_2.Remove
  L6_2 = {}
  L7_2 = "VZ_state_PilCon002_Epilogue"
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = MrxSupportData
  L1_2 = L1_2.RemoveFreebie
  L2_2 = "OilCon002_Delivery"
  L1_2(L2_2)
end

Cleanup = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = {}
  L3_2.mattias = "Mattias-In-Mission-Contract-Oil02-114"
  L3_2.jennifer = "Jennifer-In-Mission-Contract-Oil02-115"
  L3_2.chris = "Chris-In-Mission-Contract-Oil02-116"
  L4_2 = "Ewan-In-Mission-Contract-Oil02-117"
  L5_2 = {}
  L5_2.mattias = "Mattias-In-Mission-Contract-Oil02-118"
  L5_2.jennifer = "Jennifer-In-Mission-Contract-Oil02-119"
  L5_2.chris = "Chris-In-Mission-Contract-Oil02-120"
  L6_2 = "Ewan-In-Mission-Contract-Oil02-121"
  L7_2 = {}
  L7_2.mattias = "Mattias-In-Mission-Contract-Oil02-122"
  L7_2.jennifer = "Jennifer-In-Mission-Contract-Oil02-123"
  L7_2.chris = "Chris-In-Mission-Contract-Oil02-124"
  L8_2 = "Ewan-In-Mission-Contract-Oil02-125"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L2_2[6] = L8_2
  L1_2(L2_2)
end

EwanInterlude = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L1_2 = Player
  L1_2 = L1_2.GetCurrentPlayers
  L1_2 = L1_2()
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "TransitHeli_Landing02"
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2 = L3_2(L4_2)
  L2_2, L3_2, L4_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L5_2 = Vehicle
  L5_2 = L5_2.GetFromRider
  L6_2 = uHostage
  L5_2 = L5_2(L6_2)
  uHostageRide = L5_2
  L5_2 = 1
  nCancelled = L5_2
  L5_2 = uHostageRide
  if L5_2 == nil then
    L5_2 = Ai
    L5_2 = L5_2.Goal
    L6_2 = {}
    L7_2 = uHostage
    L6_2.AIGuid = L7_2
    L6_2.Goal = "MoveTo"
    L7_2 = Pg
    L7_2 = L7_2.GetGuidByName
    L8_2 = "OilCon002_Entrance2Helipad"
    L7_2 = L7_2(L8_2)
    L6_2.Target = L7_2
    L6_2.Haste = 0.1
    L6_2.Priority = "HiPri"
    L7_2 = Object
    L7_2 = L7_2.Remove
    L6_2.Callback = L7_2
    L7_2 = {}
    L8_2 = uHostage
    L7_2[1] = L8_2
    L6_2.CallbackData = L7_2
    L5_2(L6_2)
  else
    L6_2 = A0_2
    L5_2 = A0_2._CreateEvent
    L7_2 = Event
    L7_2 = L7_2.ObjectInSeat
    L8_2 = {}
    L9_2 = uHostage
    L10_2 = uHostageRide
    L11_2 = "p"
    L12_2 = "x"
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L8_2[4] = L12_2
    L9_2 = Ai
    L9_2 = L9_2.Goal
    L10_2 = {}
    L11_2 = uHostage
    L10_2.AIGuid = L11_2
    L10_2.Goal = "MoveTo"
    L11_2 = Pg
    L11_2 = L11_2.GetGuidByName
    L12_2 = "OilCon002_Entrance2Helipad"
    L11_2 = L11_2(L12_2)
    L10_2.Target = L11_2
    L10_2.Haste = 0.1
    L10_2.Priority = "HiPri"
    L11_2 = Object
    L11_2 = L11_2.Remove
    L10_2.Callback = L11_2
    L11_2 = {}
    L12_2 = uHostage
    L11_2[1] = L12_2
    L10_2.CallbackData = L11_2
    L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
    eHostageOut = L5_2
  end
  L5_2 = eHostageDeath
  if L5_2 then
    L5_2 = Event
    L5_2 = L5_2.Delete
    L6_2 = eHostageDeath
    L5_2(L6_2)
  end
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = {}
  L7_2 = {}
  L8_2 = "OilExec-In-Mission-Contract-Oil01-67"
  L9_2 = uHostage
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L8_2 = 0.75
  L9_2 = {}
  L9_2.mattias = "Mattias-In-Mission-Contract-Oil02-126"
  L9_2.jennifer = "Jennifer-In-Mission-Contract-Oil02-127"
  L9_2.chris = "Chris-In-Mission-Contract-Oil02-128"
  L10_2 = "Ewan-In-Mission-Contract-Oil02-129"
  L11_2 = {}
  L12_2 = UPHeliLand
  L13_2 = {}
  L14_2 = A0_2
  L13_2[1] = L14_2
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L6_2[5] = L11_2
  L5_2(L6_2)
  L6_2 = A0_2
  L5_2 = A0_2._CreateEvent
  L7_2 = Event
  L7_2 = L7_2.ObjectProximity
  L8_2 = {}
  L9_2 = uLuckyLady
  L10_2 = Pg
  L10_2 = L10_2.GetGuidByName
  L11_2 = "TransitHeli_Landing"
  L10_2 = L10_2(L11_2)
  L11_2 = "<"
  L12_2 = 4
  L13_2 = true
  L14_2 = true
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  L8_2[5] = L13_2
  L8_2[6] = L14_2
  
  function L9_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3
    L1_3 = MrxVoSequence
    L1_3 = L1_3.Start
    L2_3 = {}
    L3_3 = {}
    L4_3 = "Ewan-In-Mission-Contract-Oil02-130"
    L5_3 = uEwan
    L3_3[1] = L4_3
    L3_3[2] = L5_3
    L2_3[1] = L3_3
    L1_3(L2_3)
  end
  
  L10_2 = {}
  L11_2 = A0_2
  L10_2[1] = L11_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  eTransitHeliLanded = L5_2
  L6_2 = A0_2
  L5_2 = A0_2._CreateEvent
  L7_2 = Event
  L7_2 = L7_2.ObjectInSeat
  L8_2 = {}
  L9_2 = uPrimaryPlayer
  L10_2 = uLuckyLady
  L11_2 = "a"
  L12_2 = "e"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  
  function L9_2(A0_3)
    local L1_3, L2_3
    L1_3 = oTransitEnt
    L1_3 = L1_3.Complete
    L2_3 = oTransitEnt
    L1_3(L2_3)
  end
  
  L10_2 = {}
  L11_2 = A0_2
  L10_2[1] = L11_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  eHeroIn = L5_2
end

TransitStart = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Player
  L1_2 = L1_2.GetPrimaryCharacter
  L1_2 = L1_2()
  uChar = L1_2
  L1_2 = Vehicle
  L1_2 = L1_2.GetSeatFromRider
  L2_2 = uChar
  L1_2 = L1_2(L2_2)
  uSeatTran = L1_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = {}
  L4_2 = "Ewan-In-Mission-Contract-Oil02-134"
  L5_2 = uEwan
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L4_2 = 0
  L5_2 = {}
  
  function L6_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3
    L1_3 = MrxTransit
    L1_3 = L1_3.SetSystemEnabled
    L2_3 = true
    L3_3 = false
    L4_3 = false
    L1_3(L2_3, L3_3, L4_3)
    L1_3 = MrxTransit
    L1_3 = L1_3.SetLocationEnabled
    L2_3 = 1
    L3_3 = "Pmc"
    L4_3 = true
    L1_3(L2_3, L3_3, L4_3)
    L1_3 = MrxTransit
    L1_3 = L1_3.OpenInterface
    L2_3 = Player
    L2_3 = L2_3.GetLocalPlayer
    L2_3 = L2_3()
    L3_3 = _TransitCallback
    L1_3(L2_3, L3_3)
  end
  
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L4_2 = "OilCon02_PMCTransit_"
  L5_2 = nCancelled
  L4_2 = L4_2 .. L5_2
  L3_2.sName = L4_2
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2 = uPlayer
  L3_2.vTgtInclude = L4_2
  L3_2.vDestLoc = "01_pmc_hq_lz_playerone"
  L3_2.fDist = 10
  L3_2.sDspShortDesc = "[OilCon002.Objectives.transit]"
  L3_2.bDspMsgCcl = false
  
  function L4_2()
    local L0_3, L1_3
    L0_3 = eExitLady
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = eExitLady
      L0_3(L1_3)
    end
    L0_3 = eHeroIn
    if L0_3 then
      L0_3 = Event
      L0_3 = L0_3.Delete
      L1_3 = eHeroIn
      L0_3(L1_3)
    end
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.EpilogTrigger
    L0_3(L1_3)
  end
  
  L3_2.fOnComplete = L4_2
  
  function L4_2()
    local L0_3, L1_3
    L0_3 = bTransitReset
    if L0_3 then
      L0_3 = false
      bTransitReset = L0_3
    else
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3.Cancel
      L0_3(L1_3)
    end
  end
  
  L3_2.fOnCancel = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  oPMCTransit = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = uPrimaryPlayer
  L6_2 = uLuckyLady
  L7_2 = ">"
  L8_2 = 20
  L9_2 = false
  L10_2 = true
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  
  function L5_2(A0_3)
    local L1_3, L2_3
    L1_3 = true
    bTransitReset = L1_3
    L1_3 = oPMCTransit
    L1_3 = L1_3.Cancel
    L2_3 = oPMCTransit
    L1_3(L2_3)
    L1_3 = nCancelled
    L1_3 = L1_3 + 1
    nCancelled = L1_3
    L2_3 = A0_3
    L1_3 = A0_3.ObjectifyLady
    L1_3(L2_3)
    L1_3 = eExitLady
    if L1_3 then
      L1_3 = Event
      L1_3 = L1_3.Delete
      L2_3 = eExitLady
      L1_3(L2_3)
    end
    L1_3 = eReenterLady
    if L1_3 then
      L1_3 = Event
      L1_3 = L1_3.Delete
      L2_3 = eReenterLady
      L1_3(L2_3)
    end
  end
  
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  eExitLady = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.LadyCheck
  L1_2(L2_2)
end

PMCTransit = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 0.5
  L4_2[1] = L5_2
  
  function L5_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
    L1_3 = MrxTransit
    L1_3 = L1_3.SetSystemEnabled
    L2_3 = true
    L1_3(L2_3)
    L1_3 = MrxTransit
    L1_3 = L1_3.SetLocationEnabled
    L2_3 = 1
    L3_3 = "Pmc"
    L1_3(L2_3, L3_3)
    L1_3 = MrxTransit
    L1_3 = L1_3.SetLocationEnabled
    L2_3 = 2
    L3_3 = "Oil"
    L1_3(L2_3, L3_3)
    L1_3 = MrxVoSequence
    L1_3 = L1_3.Start
    L2_3 = {}
    L3_3 = {}
    L3_3.mattias = "Mattias-In-Mission-Contract-Oil02-86"
    L3_3.jennifer = "Jennifer-In-Mission-Contract-Oil02-84"
    L3_3.chris = "Chris-In-Mission-Contract-Oil02-85"
    L4_3 = {}
    L5_3 = "Ewan-In-Mission-Contract-Oil02-87"
    L6_3 = uEpiEwan
    L4_3[1] = L5_3
    L4_3[2] = L6_3
    L5_3 = {}
    L6_3 = A0_3.Complete
    L7_3 = {}
    L8_3 = A0_3
    L7_3[1] = L8_3
    L5_3[1] = L6_3
    L5_3[2] = L7_3
    L2_3[1] = L3_3
    L2_3[2] = L4_3
    L2_3[3] = L5_3
    L1_3(L2_3)
  end
  
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

Epilogue = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "OilCon02_FinalDelivery"
  L3_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2 = uPlayer
  L3_2.vTgtInclude = L4_2
  L3_2.bHumansFollow = true
  L3_2.vDestLoc = "OilCon002_FinalDeliveryLoc"
  L3_2.fDist = 3
  L3_2.bStop = false
  L3_2.bXZOnly = false
  L3_2.sDspShortDesc = "[OilCon002.Objectives.finalDel]"
  L4_2 = uPlayerGuid
  L3_2.uStartAttachedToPlayer = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.Complete
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
  L4_2 = {}
  L5_2 = {}
  L5_2.mattias = "Mattias-In-Mission-Contract-Oil02-86"
  L5_2.jennifer = "Jennifer-In-Mission-Contract-Oil02-84"
  L5_2.chris = "Chris-In-Mission-Contract-Oil02-85"
  L6_2 = 0.75
  L7_2 = "Ewan-In-Mission-Contract-Oil02-87"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L3_2.vVoSeqOnAdd = L4_2
  L1_2(L2_2, L3_2)
end

FinalDelivery = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  if A1_2 == "oilcon002_loc_postA" then
    L2_2 = 100
    nPartsAdded = L2_2
  elseif A1_2 == "oilcon002_loc_postB" then
    L2_2 = 10
    nPartsAdded = L2_2
  elseif A1_2 == "oilcon002_loc_postC" then
    L2_2 = 1
    nPartsAdded = L2_2
  end
  L2_2 = nCompletedDeliveries
  if not L2_2 then
    L2_2 = 0
  end
  nCompletedDeliveries = L2_2
  L2_2 = nCompletedDeliveries
  L2_2 = L2_2 + 1
  nCompletedDeliveries = L2_2
  L2_2 = nil
  L3_2 = pairs
  L4_2 = tDeliveryLocations
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    if A1_2 == L7_2 then
      L2_2 = L6_2
      break
    end
  end
  if L2_2 then
    L3_2 = MrxOilCon002Delivery
    L3_2 = L3_2.RemoveDropZone
    L4_2 = L2_2
    L3_2(L4_2)
  else
  end
  L3_2 = uMasterDeliveryObj
  L4_2 = L3_2
  L3_2 = L3_2.CompletePart
  L3_2(L4_2)
  L3_2 = bRecovered
  if L3_2 then
    L3_2 = nLocsDone
    nTotal = L3_2
  else
    L3_2 = nTotal
    if not L3_2 then
      L3_2 = 0
    end
    nTotal = L3_2
  end
  L3_2 = nTotal
  L3_2 = L3_2 + 1
  nTotal = L3_2
  L3_2 = tDeliveryLines
  L4_2 = nTotal
  L3_2 = L3_2[L4_2]
  if L3_2 then
    L4_2 = A0_2
    L3_2 = A0_2._CreateEvent
    L5_2 = Event
    L5_2 = L5_2.TimerRelative
    L6_2 = {}
    L7_2 = 2
    L6_2[1] = L7_2
    
    function L7_2(A0_3)
      local L1_3, L2_3, L3_3
      L1_3 = MrxVoSequence
      L1_3 = L1_3.Start
      L2_3 = tDeliveryLines
      L3_3 = nTotal
      L2_3 = L2_3[L3_3]
      L1_3(L2_3)
      L1_3 = tDeliveryLines
      L2_3 = nTotal
      L1_3[L2_3] = nil
    end
    
    L8_2 = {}
    L9_2 = A0_2
    L8_2[1] = L9_2
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  end
  L3_2 = MrxSupportData
  L3_2 = L3_2.RemoveFreebie
  L4_2 = "OilCon002_Delivery"
  L3_2(L4_2)
  L3_2 = CheckPost
  L4_2 = A0_2
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
  L3_2 = nPartsComplete
  L4_2 = nPartsAdded
  L3_2 = L3_2 + L4_2
  nPartsComplete = L3_2
  L3_2 = table
  L3_2 = L3_2.getn
  L4_2 = tDeliveryLocations
  L3_2 = L3_2(L4_2)
  L4_2 = nTotal
  if L4_2 < 3 then
    L5_2 = A0_2
    L4_2 = A0_2.PartPostsCheck
    L4_2(L5_2)
  end
  L4_2 = nTotal
  if L4_2 == 2 then
    L5_2 = A0_2
    L4_2 = A0_2.StartTimer
    L6_2 = nTimeLimit
    L4_2(L5_2, L6_2)
  end
  L4_2 = bRecovered
  if L4_2 then
    L4_2 = false
    bRecovered = L4_2
  end
end

SubDeliveryComplete = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L0_2 = pairs
  L1_2 = tBlipLocations
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = Minimap
    L6_2 = L5_2
    L5_2 = L5_2.AddObjectiveWithGuid
    L7_2 = L4_2
    L8_2 = Pg
    L8_2 = L8_2.GetGuidByName
    L9_2 = L4_2
    L8_2 = L8_2(L9_2)
    L9_2 = 0
    L10_2 = 0
    L11_2 = 0
    L12_2 = 0
    L13_2 = 255
    L14_2 = 255
    L15_2 = nil
    L16_2 = nil
    L17_2 = "HUD_objective_unknown"
    L18_2 = true
    L19_2 = nil
    L20_2 = nil
    L21_2 = 6
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
    L5_2 = Hud
    L5_2 = L5_2.Radar
    L6_2 = L5_2
    L5_2 = L5_2.AnimateObjectiveSize
    L7_2 = {}
    L7_2.sName = L4_2
    L7_2.nDuration = 60
    L7_2.nMaxWidth = 10
    L7_2.nMaxHeight = 10
    L7_2.nSpeedWidth = 25
    L7_2.nSpeedHeight = 25
    L5_2(L6_2, L7_2)
  end
end

NetSafeStartHack = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = true
  bRndmFlash = L1_2
  L1_2 = NetSafeStartHack
  L1_2()
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 2
  L4_2[1] = L5_2
  
  function L5_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L2_3 = A0_3
    L1_3 = A0_3._CreateEvent
    L3_3 = Event
    L3_3 = L3_3.TimerRelative
    L4_3 = {}
    L5_3 = 10
    L4_3[1] = L5_3
    
    function L5_3(A0_4)
      local L1_4, L2_4, L3_4, L4_4, L5_4, L6_4, L7_4
      L2_4 = A0_4
      L1_4 = A0_4.HackVans
      L3_4 = tVanList
      L4_4 = 0.5
      L5_4 = 4
      L6_4 = 8
      L7_4 = "HUD_objective_unknown"
      L1_4(L2_4, L3_4, L4_4, L5_4, L6_4, L7_4)
      L2_4 = A0_4
      L1_4 = A0_4._CreateEvent
      L3_4 = Event
      L3_4 = L3_4.TimerRelative
      L4_4 = {}
      L5_4 = 10
      L4_4[1] = L5_4
      
      function L5_4(A0_5)
        local L1_5, L2_5, L3_5, L4_5, L5_5, L6_5, L7_5, L8_5, L9_5, L10_5
        L1_5 = StopHack
        L2_5 = tVanList
        L1_5(L2_5)
        L1_5 = true
        bRndmFlash = L1_5
        L2_5 = A0_5
        L1_5 = A0_5.HackRand
        L3_5 = tVanList
        L4_5 = 0.8
        L5_5 = 3
        L6_5 = 9
        L7_5 = "HUD_objective_unknown"
        L8_5 = 1
        L9_5 = 0.9
        L10_5 = 4
        L1_5(L2_5, L3_5, L4_5, L5_5, L6_5, L7_5, L8_5, L9_5, L10_5)
      end
      
      L6_4 = {}
      L7_4 = A0_4
      L6_4[1] = L7_4
      L1_4 = L1_4(L2_4, L3_4, L4_4, L5_4, L6_4)
      eVanBlip04 = L1_4
    end
    
    L6_3 = {}
    L7_3 = A0_3
    L6_3[1] = L7_3
    L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
    eVanBlip03 = L1_3
  end
  
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  eVanBlip01 = L1_2
  L1_2 = Net
  L1_2 = L1_2.IsServer
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = Net
    L1_2 = L1_2.SendCustomEvent
    L2_2 = "OilCon002"
    L3_2 = NETEVENT_STARTHACK
    L4_2 = {}
    L1_2(L2_2, L3_2, L4_2)
  end
end

StartHack = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2
  L6_2 = pairs
  L7_2 = A1_2
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  for L9_2, L10_2 in L6_2, L7_2, L8_2 do
    L11_2 = Minimap
    L12_2 = L11_2
    L11_2 = L11_2.AddObjectiveWithGuid
    L13_2 = L10_2
    L14_2 = Pg
    L14_2 = L14_2.GetGuidByName
    L15_2 = L10_2
    L14_2 = L14_2(L15_2)
    L15_2 = 0
    L16_2 = 0
    L17_2 = 0
    L18_2 = 255
    L19_2 = 200
    L20_2 = 0
    L21_2 = A4_2
    L22_2 = A4_2
    L23_2 = A5_2
    L24_2 = true
    L25_2 = nil
    L26_2 = nil
    L27_2 = 6
    L11_2(L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2)
    L11_2 = Hud
    L11_2 = L11_2.Radar
    L12_2 = L11_2
    L11_2 = L11_2.AnimateObjectiveAlpha
    L13_2 = {}
    L13_2.sName = L10_2
    L13_2.nDuration = 30
    L13_2.nMinAlpha = 0.1
    L13_2.nMaxAlpha = A2_2
    L13_2.nSpeed = A3_2
    L11_2(L12_2, L13_2)
  end
end

HackVans = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2)
  local L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2
  L9_2 = Object
  L9_2 = L9_2.GetPosition
  L10_2 = Player
  L10_2 = L10_2.GetPrimaryCharacter
  L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2 = L10_2()
  L9_2, L10_2, L11_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2)
  L12_2 = tRandBlip
  if A1_2 == L12_2 then
    L12_2 = tRandBlip
    tBlips = L12_2
  else
    L12_2 = {}
    tBlips = L12_2
    L12_2 = pairs
    L13_2 = A1_2
    L12_2, L13_2, L14_2 = L12_2(L13_2)
    for L15_2, L16_2 in L12_2, L13_2, L14_2 do
      L17_2 = Pg
      L17_2 = L17_2.GetGuidByName
      L18_2 = L16_2
      L17_2 = L17_2(L18_2)
      sGuid = L17_2
      L17_2 = table
      L17_2 = L17_2.insert
      L18_2 = tBlips
      L19_2 = sGuid
      L17_2(L18_2, L19_2)
    end
  end
  if not A8_2 then
    A8_2 = 1
  end
  L12_2 = math
  L12_2 = L12_2.randi
  L13_2 = table
  L13_2 = L13_2.getn
  L14_2 = tBlips
  L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2 = L13_2(L14_2)
  L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2)
  nRand = L12_2
  L12_2 = tBlips
  L13_2 = nRand
  L12_2 = L12_2[L13_2]
  uBlip = L12_2
  L12_2 = tostring
  L13_2 = uBlip
  L12_2 = L12_2(L13_2)
  L13_2 = "_"
  L14_2 = A8_2
  L12_2 = L12_2 .. L13_2 .. L14_2
  sName = L12_2
  L12_2 = Minimap
  L13_2 = L12_2
  L12_2 = L12_2.AddObjectiveWithGuid
  L14_2 = sName
  L15_2 = uBlip
  L16_2 = 0
  L17_2 = 0
  L18_2 = 0
  L19_2 = 255
  L20_2 = 200
  L21_2 = 0
  L22_2 = A4_2
  L23_2 = A4_2
  L24_2 = A5_2
  L25_2 = true
  L26_2 = nil
  L27_2 = nil
  L28_2 = 6
  L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2)
  L12_2 = Hud
  L12_2 = L12_2.Radar
  L13_2 = L12_2
  L12_2 = L12_2.AnimateObjectiveAlpha
  L14_2 = {}
  L15_2 = sName
  L14_2.sName = L15_2
  L14_2.nDuration = 30
  L14_2.nMinAlpha = 0.2
  L14_2.nMaxAlpha = A2_2
  L14_2.nSpeed = A3_2
  L12_2(L13_2, L14_2)
  L13_2 = A0_2
  L12_2 = A0_2._CreateEvent
  L14_2 = Event
  L14_2 = L14_2.TimerRelative
  L15_2 = {}
  L16_2 = A6_2
  L15_2[1] = L16_2
  
  function L16_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3
    L1_3 = bRndmFlash
    if L1_3 then
      L2_3 = A0_3
      L1_3 = A0_3.HackRand
      L3_3 = A1_2
      L4_3 = A2_2
      L5_3 = A3_2
      L6_3 = A4_2
      L7_3 = A5_2
      L8_3 = A6_2
      L9_3 = A7_2
      L10_3 = A8_2
      L10_3 = L10_3 + 10
      L1_3(L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3)
    end
  end
  
  L17_2 = {}
  L18_2 = A0_2
  L17_2[1] = L18_2
  L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2)
  eRandBlip = L12_2
  L13_2 = A0_2
  L12_2 = A0_2._CreateEvent
  L14_2 = Event
  L14_2 = L14_2.TimerRelative
  L15_2 = {}
  L16_2 = A7_2
  L15_2[1] = L16_2
  
  function L16_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = Minimap
    L2_3 = L1_3
    L1_3 = L1_3.DeleteObjective
    L3_3 = sName
    L1_3(L2_3, L3_3)
  end
  
  L17_2 = {}
  L18_2 = A0_2
  L17_2[1] = L18_2
  L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2)
  eRandBlip02 = L12_2
end

HackRand = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  if not A0_2 then
    return
  end
  L1_2 = false
  bRndmFlash = L1_2
  L1_2 = pairs
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Minimap
    L7_2 = L6_2
    L6_2 = L6_2.DeleteObjective
    L8_2 = L5_2
    L6_2(L7_2, L8_2)
  end
  L1_2 = Net
  L1_2 = L1_2.IsServer
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = Net
    L1_2 = L1_2.SendCustomEvent
    L2_2 = "OilCon002"
    L3_2 = NETEVENT_STOPHACK
    L4_2 = {}
    L1_2(L2_2, L3_2, L4_2)
  end
end

StopHack = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = oMissionTimer
  if L2_2 then
  else
    L2_2 = MrxTimer
    L3_2 = L2_2
    L2_2 = L2_2.Create
    L4_2 = {}
    L5_2 = A1_2 * 60
    L4_2.nStartTime = L5_2
    L4_2.iTray = 2
    L5_2 = {}
    L6_2 = {}
    L7_2 = TimeOut
    L8_2 = {}
    L9_2 = A0_2
    L8_2[1] = L9_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L5_2[1] = L6_2
    L4_2.tDoneCallbacks = L5_2
    L2_2 = L2_2(L3_2, L4_2)
    oMissionTimer = L2_2
    L2_2 = oMissionTimer
    L3_2 = L2_2
    L2_2 = L2_2.Start
    L2_2(L3_2)
    L2_2 = Hud
    L2_2 = L2_2.ObjectiveTray
    L3_2 = L2_2
    L2_2 = L2_2.SetSlotToText
    L4_2 = {}
    L4_2.nSlot = 1
    L5_2 = sDeadlineText
    L4_2.sText = L5_2
    L2_2(L3_2, L4_2)
  end
end

StartTimer = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = oMissionTimer
  if L1_2 then
    L1_2 = oMissionTimer
    L2_2 = L1_2
    L1_2 = L1_2.Stop
    L1_2(L2_2)
    L1_2 = nil
    oMissionTimer = L1_2
  end
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.SetSlotToText
  L3_2 = {}
  L3_2.nSlot = 1
  L3_2.sText = " "
  L1_2(L2_2, L3_2)
end

ClearTimer = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  L3_2 = DangerousBuilding
  L3_2 = L3_2.TurnOn
  L4_2 = L2_2
  L5_2 = false
  L6_2 = true
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = Ai
  L3_2 = L3_2.TweakAttachedSpawners
  L4_2 = L2_2
  L5_2 = {}
  L5_2.SpawnerState = "on"
  L5_2.SpawnList = "Spawnlist (VZ Balcony)"
  L3_2(L4_2, L5_2)
end

AggravateBuilding = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "OilCon002_EpiEwan"
  L1_2 = L1_2(L2_2)
  uEpiEwan = L1_2
  L1_2 = Player
  L1_2 = L1_2.GetPrimaryCharacter
  L1_2 = L1_2()
  uChar = L1_2
  L1_2 = Object
  L1_2 = L1_2.SetTransformToObject
  L2_2 = uLuckyLady
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "OilCon002_HeliTele"
  L3_2, L4_2, L5_2, L6_2, L7_2 = L3_2(L4_2)
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2 = Net
  L1_2 = L1_2.IsServer
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = Net
    L1_2 = L1_2.SendCustomEvent
    L2_2 = "OilCon002"
    L3_2 = NETEVENT_MOVE_LUCKY_LADY
    L4_2 = {}
    L5_2 = uLuckyLady
    L4_2[1] = L5_2
    L5_2 = true
    L1_2(L2_2, L3_2, L4_2, L5_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 0.75
  L4_2[1] = L5_2
  
  function L5_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L1_3 = ePilotEwanDeath
    if L1_3 then
      L1_3 = Event
      L1_3 = L1_3.Delete
      L2_3 = ePilotEwanDeath
      L1_3(L2_3)
    end
    L1_3 = Object
    L1_3 = L1_3.Remove
    L2_3 = uEwan
    L1_3(L2_3)
    L1_3 = Vehicle
    L1_3 = L1_3.Enter
    L2_3 = uLuckyLady
    L3_3 = uEpiEwan
    L4_3 = "d"
    L5_3 = true
    L6_3 = false
    L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
    L2_3 = A0_3
    L1_3 = A0_3._CreateEvent
    L3_3 = Event
    L3_3 = L3_3.ObjectDeath
    L4_3 = {}
    L5_3 = uEpiEwan
    L4_3[1] = L5_3
    L5_3 = EwanDeath
    L6_3 = {}
    L7_3 = A0_3
    L6_3[1] = L7_3
    L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
    ePilotEwanDeath = L1_3
    L1_3 = Vehicle
    L1_3 = L1_3.EnterBySeatGuid
    L2_3 = uLuckyLady
    L3_3 = uChar
    L4_3 = uSeatTran
    L5_3 = true
    L6_3 = false
    L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
    bEpiPlayerIn = L1_3
    L1_3 = bEpiPlayerIn
    if L1_3 then
      L1_3 = EwanLand
      L2_3 = A0_3
      L3_3 = Pg
      L3_3 = L3_3.GetGuidByName
      L4_3 = "OilCon002_HeliTele"
      L3_3 = L3_3(L4_3)
      L4_3 = uEpiEwan
      L5_3 = false
      L1_3(L2_3, L3_3, L4_3, L5_3)
    end
  end
  
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = eReenterLady
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = eReenterLady
    L1_2(L2_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 2
  L4_2[1] = L5_2
  L5_2 = Epilogue
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

EpilogTrigger = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = uPlayer
  L7_2 = A1_2
  L8_2 = "<"
  L9_2 = 25
  L10_2 = false
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  
  function L6_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
    L1_3 = Object
    L1_3 = L1_3.GetPosition
    L2_3 = A1_2
    L1_3, L2_3, L3_3 = L1_3(L2_3)
    L4_3 = Pg
    L4_3 = L4_3.GetObjectsInArea
    L5_3 = L1_3
    L6_3 = L2_3
    L7_3 = L3_3
    L8_3 = 10
    L9_3 = "Listening Post"
    L4_3 = L4_3(L5_3, L6_3, L7_3, L8_3, L9_3)
    L5_3 = table
    L5_3 = L5_3.getn
    L6_3 = L4_3
    L5_3 = L5_3(L6_3)
    if L5_3 < 1 then
      L6_3 = MrxSupportData
      L6_3 = L6_3.AddFreebie
      L7_3 = "OilCon002_Delivery"
      L6_3(L7_3)
      L6_3 = ResetPostDelivery
      L7_3 = A0_3
      L8_3 = A1_2
      L6_3(L7_3, L8_3)
    end
  end
  
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  eAddPostDelivery01 = L2_2
end

AddPostDelivery = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAllCharacters
  L6_2 = L6_2()
  L7_2 = A1_2
  L8_2 = ">"
  L9_2 = 26
  L10_2 = false
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  
  function L6_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = MrxSupportData
    L1_3 = L1_3.RemoveFreebie
    L2_3 = "OilCon002_Delivery"
    L1_3(L2_3)
    L1_3 = AddPostDelivery
    L2_3 = A0_3
    L3_3 = A1_2
    L1_3(L2_3, L3_3)
  end
  
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  eResetPostDelivery01 = L2_2
end

ResetPostDelivery = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = oMissionTimer
  if L1_2 then
    L1_2 = MrxTimer
    L1_2 = L1_2.GetTime
    L2_2 = oMissionTimer
    L1_2 = L1_2(L2_2)
    nCheckpointTime = L1_2
  end
  L1_2 = false
  bCheckActive = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._SetFlag
  L3_2 = "AllPostsPlaced"
  L4_2 = nCheckpointTime
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = _Checkpoint
  L2_2 = {}
  L3_2 = "Starter_Oil0_Start1"
  L4_2 = "Starter_Oil0_Start2"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.LoadVansLayer
  L1_2(L2_2)
end

AllPostsCheck = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2._SetFlag
  L3_2 = "PartPostsPlaced"
  L4_2 = nPartsComplete
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = _Checkpoint
  L2_2 = {}
  L3_2 = "Starter_Oil0_Start1"
  L4_2 = "Starter_Oil0_Start2"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
end

PartPostsCheck = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L1_2 = true
  bRecovered = L1_2
  L1_2 = nRecoverStatus
  nPartsComplete = L1_2
  L1_2 = nRecoverStatus
  if L1_2 == 100 then
    L1_2 = {}
    L2_2 = "oilcon002_loc_postA"
    L1_2[1] = L2_2
    tRecoverLocs = L1_2
    L1_2 = {}
    L2_2 = "oilcon002_loc_postB"
    L3_2 = "oilcon002_loc_postC"
    L1_2[1] = L2_2
    L1_2[2] = L3_2
    tRemainingLocs = L1_2
  else
    L1_2 = nRecoverStatus
    if L1_2 == 10 then
      L1_2 = {}
      L2_2 = "oilcon002_loc_postB"
      L1_2[1] = L2_2
      tRecoverLocs = L1_2
      L1_2 = {}
      L2_2 = "oilcon002_loc_postA"
      L3_2 = "oilcon002_loc_postC"
      L1_2[1] = L2_2
      L1_2[2] = L3_2
      tRemainingLocs = L1_2
    else
      L1_2 = nRecoverStatus
      if L1_2 == 1 then
        L1_2 = {}
        L2_2 = "oilcon002_loc_postC"
        L1_2[1] = L2_2
        tRecoverLocs = L1_2
        L1_2 = {}
        L2_2 = "oilcon002_loc_postA"
        L3_2 = "oilcon002_loc_postB"
        L1_2[1] = L2_2
        L1_2[2] = L3_2
        tRemainingLocs = L1_2
      else
        L1_2 = nRecoverStatus
        if L1_2 == 110 then
          L1_2 = {}
          L2_2 = "oilcon002_loc_postA"
          L3_2 = "oilcon002_loc_postB"
          L1_2[1] = L2_2
          L1_2[2] = L3_2
          tRecoverLocs = L1_2
          L1_2 = {}
          L2_2 = "oilcon002_loc_postC"
          L1_2[1] = L2_2
          tRemainingLocs = L1_2
        else
          L1_2 = nRecoverStatus
          if L1_2 == 11 then
            L1_2 = {}
            L2_2 = "oilcon002_loc_postB"
            L3_2 = "oilcon002_loc_postC"
            L1_2[1] = L2_2
            L1_2[2] = L3_2
            tRecoverLocs = L1_2
            L1_2 = {}
            L2_2 = "oilcon002_loc_postA"
            L1_2[1] = L2_2
            tRemainingLocs = L1_2
          else
            L1_2 = nRecoverStatus
            if L1_2 == 101 then
              L1_2 = {}
              L2_2 = "oilcon002_loc_postA"
              L3_2 = "oilcon002_loc_postC"
              L1_2[1] = L2_2
              L1_2[2] = L3_2
              tRecoverLocs = L1_2
              L1_2 = {}
              L2_2 = "oilcon002_loc_postB"
              L1_2[1] = L2_2
              tRemainingLocs = L1_2
            end
          end
        end
      end
    end
  end
  L1_2 = table
  L1_2 = L1_2.getn
  L2_2 = tRecoverLocs
  L1_2 = L1_2(L2_2)
  nLocsDone = L1_2
  L1_2 = ipairs
  L2_2 = tRecoverLocs
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Pg
    L6_2 = L6_2.GetGuidByName
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    L7_2 = Object
    L7_2 = L7_2.GetPosition
    L8_2 = L6_2
    L7_2, L8_2, L9_2 = L7_2(L8_2)
    L10_2 = table
    L10_2 = L10_2.insert
    L11_2 = tCompletedLoc
    L12_2 = L5_2
    L10_2(L11_2, L12_2)
    L11_2 = A0_2
    L10_2 = A0_2._CreateEvent
    L12_2 = Event
    L12_2 = L12_2.ObjectProximity
    L13_2 = {}
    L14_2 = uPlayer
    L15_2 = L6_2
    L16_2 = "<"
    L17_2 = 150
    L18_2 = false
    L19_2 = true
    L13_2[1] = L14_2
    L13_2[2] = L15_2
    L13_2[3] = L16_2
    L13_2[4] = L17_2
    L13_2[5] = L18_2
    L13_2[6] = L19_2
    L14_2 = Pg
    L14_2 = L14_2.Spawn
    L15_2 = {}
    L16_2 = "Listening Post"
    L17_2 = L7_2
    L18_2 = L8_2
    L19_2 = L9_2
    L15_2[1] = L16_2
    L15_2[2] = L17_2
    L15_2[3] = L18_2
    L15_2[4] = L19_2
    L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2, L15_2)
    eSpawnPosts = L10_2
  end
  L2_2 = A0_2
  L1_2 = A0_2.RecoveryObjective
  L1_2(L2_2)
  L1_2 = table
  L1_2 = L1_2.getn
  L2_2 = tRemainingLocs
  L1_2 = L1_2(L2_2)
  if L1_2 == 1 then
    L2_2 = A0_2
    L1_2 = A0_2.StartTimer
    L3_2 = nTimeLimit
    L1_2(L2_2, L3_2)
  end
end

RecoverPostsStatus = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  L3_2 = Object
  L3_2 = L3_2.GetPosition
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  L6_2 = Pg
  L6_2 = L6_2.GetObjectsInArea
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = L5_2
  L10_2 = 10
  L11_2 = "Listening Post"
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  L7_2 = table
  L7_2 = L7_2.getn
  L8_2 = L6_2
  L7_2 = L7_2(L8_2)
  L8_2 = L6_2[1]
  L9_2 = table
  L9_2 = L9_2.insert
  L10_2 = tCompletedLoc
  L11_2 = A1_2
  L9_2(L10_2, L11_2)
  L9_2 = table
  L9_2 = L9_2.insert
  L10_2 = tCompPosts
  L11_2 = L8_2
  L9_2(L10_2, L11_2)
  L9_2 = ipairs
  L10_2 = tCompleted
  L9_2, L10_2, L11_2 = L9_2(L10_2)
  for L12_2, L13_2 in L9_2, L10_2, L11_2 do
    if L2_2 == L13_2 then
      L14_2 = tCompleted
      L14_2[L13_2] = L8_2
      break
    end
  end
  L10_2 = A0_2
  L9_2 = A0_2._CreateEvent
  L11_2 = Event
  L11_2 = L11_2.ObjectProximity
  L12_2 = {}
  L13_2 = L8_2
  L14_2 = L2_2
  L15_2 = ">"
  L16_2 = 10
  L17_2 = false
  L18_2 = false
  L12_2[1] = L13_2
  L12_2[2] = L14_2
  L12_2[3] = L15_2
  L12_2[4] = L16_2
  L12_2[5] = L17_2
  L12_2[6] = L18_2
  
  function L13_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = bCheckActive
    if L1_3 then
      L1_3 = PostAlert
      L2_3 = A0_3
      L3_3 = A1_2
      L1_3(L2_3, L3_3)
    end
  end
  
  L14_2 = {}
  L15_2 = A0_2
  L14_2[1] = L15_2
  L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
  eCheckPostDist = L9_2
end

CheckPost = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L1_2 = ipairs
  L2_2 = tBlipLocations
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Object
    L6_2 = L6_2.GetPosition
    L7_2 = Pg
    L7_2 = L7_2.GetGuidByName
    L8_2 = L5_2
    L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2 = L7_2(L8_2)
    L6_2, L7_2, L8_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
    z = L8_2
    y = L7_2
    x = L6_2
    L6_2 = Pg
    L6_2 = L6_2.GetObjectsInArea
    L7_2 = x
    L8_2 = y
    L9_2 = z
    L10_2 = 150
    L11_2 = "Listening Post"
    L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
    tPosts = L6_2
    L6_2 = ipairs
    L7_2 = tPosts
    L6_2, L7_2, L8_2 = L6_2(L7_2)
    for L9_2, L10_2 in L6_2, L7_2, L8_2 do
      L12_2 = A0_2
      L11_2 = A0_2._CreateEvent
      L13_2 = Event
      L13_2 = L13_2.ObjectHibernation
      L14_2 = {}
      L15_2 = L10_2
      L16_2 = "hibernated"
      L14_2[1] = L15_2
      L14_2[2] = L16_2
      L15_2 = Object
      L15_2 = L15_2.Remove
      L16_2 = {}
      L17_2 = L10_2
      L16_2[1] = L17_2
      L11_2(L12_2, L13_2, L14_2, L15_2, L16_2)
    end
  end
end

RemovePosts = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = {}
  tResetLocs = L4_2
  L4_2 = ipairs
  L5_2 = tCompletedLoc
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    if A1_2 == L8_2 then
      L9_2 = table
      L9_2 = L9_2.insert
      L10_2 = tResetLocs
      L11_2 = A1_2
      L9_2(L10_2, L11_2)
      L9_2 = table
      L9_2 = L9_2.remove
      L10_2 = tCompletedLoc
      L11_2 = L7_2
      L9_2(L10_2, L11_2)
      break
    end
  end
  if A1_2 == "oilcon002_loc_postA" then
    L4_2 = 100
    nPartsMinus = L4_2
  elseif A1_2 == "oilcon002_loc_postB" then
    L4_2 = 10
    nPartsMinus = L4_2
  elseif A1_2 == "oilcon002_loc_postC" then
    L4_2 = 1
    nPartsMinus = L4_2
  end
  L4_2 = nPartsComplete
  L5_2 = nPartsMinus
  L4_2 = L4_2 - L5_2
  nPartsComplete = L4_2
  L4_2 = nReset
  L4_2 = L4_2 + 1
  nReset = L4_2
  L4_2 = nTotal
  L4_2 = L4_2 - 1
  nTotal = L4_2
  L4_2 = 0
  nCompletedDeliveries = L4_2
  L4_2 = uMasterDeliveryObj
  L5_2 = L4_2
  L4_2 = L4_2.Cancel
  L4_2(L5_2)
  L4_2 = true
  bReset = L4_2
  L5_2 = A0_2
  L4_2 = A0_2.CreateChild
  L6_2 = {}
  L7_2 = "OilCon002_ResetMasterDelivery_"
  L8_2 = nReset
  L7_2 = L7_2 .. L8_2
  L6_2.sName = L7_2
  L6_2.sModuleName = "MrxTaskObjective"
  L7_2 = sDeliveryObjectiveText
  L6_2.sDspShortDesc = L7_2
  L6_2.nQuota = 3
  L6_2.bDspMsgAdd = false
  L7_2 = {}
  L8_2 = {}
  L9_2 = AllPostsCheck
  L10_2 = {}
  L11_2 = A0_2
  L10_2[1] = L11_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L7_2[1] = L8_2
  L6_2.tOnComplete = L7_2
  L4_2 = L4_2(L5_2, L6_2)
  uMasterDeliveryObj = L4_2
  L4_2 = MrxOilCon002Delivery
  L4_2 = L4_2.ResetDropZones
  L4_2()
  L4_2 = MrxOilCon002Delivery
  L4_2 = L4_2.GetCurrentDropZones
  L4_2 = L4_2()
  tDeliveryLocations = L4_2
  L4_2 = table
  L4_2 = L4_2.getn
  L5_2 = tCompletedLoc
  L4_2 = L4_2(L5_2)
  L5_2 = uMasterDeliveryObj
  L6_2 = L5_2
  L5_2 = L5_2.Configure
  L7_2 = {}
  L7_2.nPartsCompleted = L4_2
  L5_2 = L5_2(L6_2, L7_2)
  bSetComps = L5_2
  L5_2 = ipairs
  L6_2 = tResetLocs
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = Object
    L10_2 = L10_2.GetPosition
    L11_2 = Pg
    L11_2 = L11_2.GetGuidByName
    L12_2 = L9_2
    L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2 = L11_2(L12_2)
    L10_2, L11_2, L12_2 = L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2)
    L13_2 = Pg
    L13_2 = L13_2.FastCollectHumans
    L14_2 = L10_2
    L15_2 = L11_2
    L16_2 = L12_2
    L17_2 = 15
    L18_2 = "Hero"
    L13_2 = L13_2(L14_2, L15_2, L16_2, L17_2, L18_2)
    L14_2 = Pg
    L14_2 = L14_2.GetGuidByName
    L15_2 = L9_2
    L14_2 = L14_2(L15_2)
    L16_2 = A0_2
    L15_2 = A0_2._CreateEvent
    L17_2 = Event
    L17_2 = L17_2.ObjectProximity
    L18_2 = {}
    L19_2 = uPlayer
    L20_2 = L14_2
    L21_2 = "<"
    L22_2 = 25
    L23_2 = false
    L24_2 = false
    L18_2[1] = L19_2
    L18_2[2] = L20_2
    L18_2[3] = L21_2
    L18_2[4] = L22_2
    L18_2[5] = L23_2
    L18_2[6] = L24_2
    
    function L19_2(A0_3)
      local L1_3, L2_3, L3_3
      L1_3 = MrxSupportData
      L1_3 = L1_3.AddFreebie
      L2_3 = "OilCon002_Delivery"
      L1_3(L2_3)
      L1_3 = ResetPostDelivery
      L2_3 = A0_3
      L3_3 = L14_2
      L1_3(L2_3, L3_3)
    end
    
    L20_2 = {}
    L21_2 = A0_2
    L20_2[1] = L21_2
    L15_2 = L15_2(L16_2, L17_2, L18_2, L19_2, L20_2)
    eAddPostDeliveryReset = L15_2
    L15_2 = uSubDelivery
    L17_2 = A0_2
    L16_2 = A0_2.CreateChild
    L18_2 = {}
    L19_2 = "OilCon002_SubDeliveryReset"
    L20_2 = L8_2
    L21_2 = "_"
    L22_2 = nReset
    L19_2 = L19_2 .. L20_2 .. L21_2 .. L22_2
    L18_2.sName = L19_2
    L18_2.sModuleName = "MrxTaskObjectiveDeliver"
    L18_2.sTgtLabelFilter = "Listening Post"
    L19_2 = sDeliveryObjectiveText
    L18_2.sDspShortDesc = L19_2
    L18_2.bDspDescPda = false
    L18_2.vDestLoc = L9_2
    L18_2.nQuota = 1
    L18_2.fDist = 10
    L18_2.bUseDestRing = true
    L18_2.bDisplayHelpText = false
    L18_2.bXZOnly = false
    L18_2.bDspMsg = false
    L19_2 = {}
    L20_2 = {}
    L21_2 = SubDeliveryComplete
    L22_2 = {}
    L23_2 = A0_2
    L24_2 = L9_2
    L22_2[1] = L23_2
    L22_2[2] = L24_2
    L20_2[1] = L21_2
    L20_2[2] = L22_2
    L19_2[1] = L20_2
    L18_2.tOnComplete = L19_2
    L16_2 = L16_2(L17_2, L18_2)
    L15_2[L9_2] = L16_2
  end
end

ResetMasterObj = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L1_2 = {}
  L2_2 = oPostLoc01
  L3_2 = oPostLoc02
  L4_2 = oPostLoc03
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  tCompleted = L1_2
  L1_2 = {}
  tCompPosts = L1_2
  L1_2 = 0
  nReset = L1_2
  L1_2 = false
  bReconfig = L1_2
  L1_2 = MrxOilCon002Delivery
  L1_2 = L1_2.ResetDropZones
  L1_2()
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "OilCon002_MasterDelivery"
  L3_2.sModuleName = "MrxTaskObjective"
  L4_2 = sDeliveryObjectiveText
  L3_2.sDspShortDesc = L4_2
  L3_2.nQuota = 3
  L3_2.bDspMsgCcl = false
  L4_2 = {}
  L5_2 = {}
  L6_2 = AllPostsCheck
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  uMasterDeliveryObj = L1_2
  L1_2 = uMasterDeliveryObj
  L2_2 = L1_2
  L1_2 = L1_2.Configure
  L3_2 = {}
  L4_2 = nLocsDone
  L3_2.nPartsCompleted = L4_2
  L1_2(L2_2, L3_2)
  L1_2 = FreebieAdd
  L2_2 = A0_2
  L3_2 = 2
  L4_2 = true
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = ExitReminder
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = bRecovered
  if L1_2 then
    L1_2 = tRemainingLocs
    tDeliveryLocations = L1_2
  else
    L1_2 = MrxOilCon002Delivery
    L1_2 = L1_2.GetCurrentDropZones
    L1_2 = L1_2()
    tDeliveryLocations = L1_2
  end
  L1_2 = {}
  uSubDelivery = L1_2
  L1_2 = ipairs
  L2_2 = tDeliveryLocations
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = AddPostDelivery
    L7_2 = A0_2
    L8_2 = Pg
    L8_2 = L8_2.GetGuidByName
    L9_2 = L5_2
    L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2 = L8_2(L9_2)
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
    L6_2 = uSubDelivery
    L8_2 = A0_2
    L7_2 = A0_2.CreateChild
    L9_2 = {}
    L10_2 = "OilCon002_SubDelivery"
    L11_2 = L4_2
    L10_2 = L10_2 .. L11_2
    L9_2.sName = L10_2
    L9_2.sModuleName = "MrxTaskObjectiveDeliver"
    L9_2.sTgtLabelFilter = "Listening Post"
    L10_2 = sDeliveryObjectiveText
    L9_2.sDspShortDesc = L10_2
    L9_2.bDspDescPda = false
    L9_2.vDestLoc = L5_2
    L9_2.nQuota = 1
    L9_2.fDist = 10
    L9_2.bUseDestRing = true
    L9_2.bDisplayHelpText = false
    L9_2.bXZOnly = false
    L9_2.bDspMsg = false
    L10_2 = {}
    L11_2 = {}
    L12_2 = SubDeliveryComplete
    L13_2 = {}
    L14_2 = A0_2
    L15_2 = L5_2
    L13_2[1] = L14_2
    L13_2[2] = L15_2
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L10_2[1] = L11_2
    L9_2.tOnComplete = L10_2
    L7_2 = L7_2(L8_2, L9_2)
    L6_2[L5_2] = L7_2
  end
end

RecoveryObjective = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L2_2 = Minimap
  L3_2 = L2_2
  L2_2 = L2_2.AddObjectiveWithGuid
  L4_2 = A1_2
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = A1_2
  L5_2 = L5_2(L6_2)
  L6_2 = 0
  L7_2 = 0
  L8_2 = 0
  L9_2 = 255
  L10_2 = 0
  L11_2 = 0
  L12_2 = nil
  L13_2 = nil
  L14_2 = "HUD_objective_action"
  L15_2 = true
  L16_2 = nil
  L17_2 = nil
  L18_2 = 5
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  L2_2 = Hud
  L2_2 = L2_2.Radar
  L3_2 = L2_2
  L2_2 = L2_2.AnimateObjectiveSize
  L4_2 = {}
  L4_2.sName = A1_2
  L4_2.nDuration = 60
  L4_2.nMaxWidth = 15
  L4_2.nMaxHeight = 15
  L4_2.nSpeedWidth = 45
  L4_2.nSpeedHeight = 45
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 5
  L5_2[1] = L6_2
  
  function L6_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = Minimap
    L2_3 = L1_3
    L1_3 = L1_3.DeleteObjective
    L3_3 = A1_2
    L1_3(L2_3, L3_3)
    L1_3 = ResetMasterObj
    L2_3 = A0_3
    L3_3 = A1_2
    L1_3(L2_3, L3_3)
  end
  
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A1_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  eAlertTemp = L2_2
  L2_2 = MrxVoSequence
  L2_2 = L2_2.Start
  L3_2 = {}
  L4_2 = "Fiona-In-Mission-Contract-Oil02-66"
  L3_2[1] = L4_2
  L2_2(L3_2)
end

PostAlert = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  L3_2 = Vehicle
  L3_2 = L3_2.GetRiders
  L4_2 = L2_2
  L5_2 = "g"
  L3_2 = L3_2(L4_2, L5_2)
  L5_2 = A0_2
  L4_2 = A0_2._CreateEvent
  L6_2 = Event
  L6_2 = L6_2.ObjectProximity
  L7_2 = {}
  L8_2 = uPlayer
  L9_2 = L2_2
  L10_2 = "<"
  L11_2 = 55
  L12_2 = false
  L13_2 = false
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L7_2[4] = L11_2
  L7_2[5] = L12_2
  L7_2[6] = L13_2
  
  function L8_2(A0_3)
    local L1_3, L2_3
    L1_3 = L3_2
    if L1_3 then
      L1_3 = MrxTutorialManager
      L1_3 = L1_3.ShowMessage
      L2_3 = "[OilCon002.Tutorial.hijackTutorial]"
      L1_3(L2_3)
      L1_3 = TutorialRemove
      L2_3 = A0_3
      L1_3(L2_3)
      L1_3 = eTankTutorial
      if L1_3 then
        L1_3 = Event
        L1_3 = L1_3.Delete
        L2_3 = eTankTutorial
        L1_3(L2_3)
      end
    end
  end
  
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  eTankTutorial = L4_2
end

HijackTutorial = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L1_2 = ipairs
  L2_2 = tBlipLocations
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Pg
    L6_2 = L6_2.GetGuidByName
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    uLocation = L6_2
    L7_2 = A0_2
    L6_2 = A0_2._CreateEvent
    L8_2 = Event
    L8_2 = L8_2.ObjectProximity
    L9_2 = {}
    L10_2 = uPlayer
    L11_2 = uLocation
    L12_2 = "<"
    L13_2 = 20
    L14_2 = false
    L15_2 = false
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L9_2[4] = L13_2
    L9_2[5] = L14_2
    L9_2[6] = L15_2
    
    function L10_2(A0_3)
      local L1_3, L2_3
      L1_3 = MrxPlayer
      L1_3 = L1_3.IsInVehicle
      L2_3 = "Vehicle"
      L1_3 = L1_3(L2_3)
      if L1_3 then
        L1_3 = MrxTutorialManager
        L1_3 = L1_3.ShowMessage
        L2_3 = "[OilCon002.Tutorial.supportReminder]"
        L1_3(L2_3)
        L1_3 = TutorialRemove
        L2_3 = A0_3
        L1_3(L2_3)
      else
        L1_3 = MrxTutorialManager
        L1_3 = L1_3.ShowMessage
        L2_3 = "[OilCon002.Tutorial.supportTutorial]"
        L1_3(L2_3)
        L1_3 = TutorialRemove
        L2_3 = A0_3
        L1_3(L2_3)
      end
    end
    
    L11_2 = {}
    L12_2 = A0_2
    L11_2[1] = L12_2
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  end
end

ExitReminder = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 5
  L4_2[1] = L5_2
  L5_2 = MrxTutorialManager
  L5_2 = L5_2.HideMessage
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

TutorialRemove = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[OilCon002.Terms.Cancel02]"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.Cancel
  L1_2(L2_2)
end

GarageDeath = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[OilCon002.Terms.Cancel01]"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.Cancel
  L1_2(L2_2)
end

TimeOut = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2._SetCancelMessage
  L3_2 = "[OilCon002.Terms.Cancel03]"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.Cancel
  L1_2(L2_2)
end

EwanDeath = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = Vehicle
  L2_2 = L2_2.GetSeatFromRider
  L3_2 = uVZDriver
  L2_2 = L2_2(L3_2)
  uDrSeat = L2_2
  L2_2 = Vehicle
  L2_2 = L2_2.GetSeatFromRider
  L3_2 = uVZShotgun
  L2_2 = L2_2(L3_2)
  uPaSeat = L2_2
  L2_2 = Object
  L2_2 = L2_2.GetAttachedObjects
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  tSeats = L2_2
  L2_2 = ipairs
  L3_2 = tSeats
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = Object
    L7_2 = L7_2.HasLabel
    L8_2 = L6_2
    L9_2 = "Human"
    L7_2 = L7_2(L8_2, L9_2)
    bHuman = L7_2
    L7_2 = uDrSeat
    if L6_2 ~= L7_2 then
      L7_2 = uPaSeat
      if L6_2 ~= L7_2 then
        L7_2 = bHuman
        if L7_2 == false then
          uHostSeat = L6_2
          break
        end
      end
    end
  end
end

GetHostageSeat = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Ai
  L1_2 = L1_2.Goal
  L2_2 = {}
  L3_2 = uEwan
  L2_2.AIGuid = L3_2
  L2_2.Goal = "HeliLand"
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "TransitHeli_Landing"
  L3_2 = L3_2(L4_2)
  L2_2.Target = L3_2
  L2_2.Haste = 0.3
  L2_2.Priority = "HiPri"
  L2_2.Force = true
  L1_2(L2_2)
  L1_2 = EwanLand
  L2_2 = A0_2
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "TransitHeli_Landing"
  L3_2 = L3_2(L4_2)
  L4_2 = uEwan
  L5_2 = true
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L2_2 = A0_2
  L1_2 = A0_2.ObjectifyLady
  L1_2(L2_2)
end

UPHeliLand = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L4_2 = "OilCon02_GetInHeli_"
  L5_2 = nCancelled
  L4_2 = L4_2 .. L5_2
  L3_2.sName = L4_2
  L3_2.sModuleName = "MrxTaskObjective"
  L4_2 = uLuckyLady
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[OilCon002.Objectives.enterLuckyLady]"
  L3_2.bDspBlp = true
  L3_2.sDspBlpRdrIcon = "objective_action"
  L3_2.sDspBlpWldIcon = "HUD_objective_action"
  L4_2 = {}
  L5_2 = {}
  L6_2 = PMCTransit
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
  oTransitEnt = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectInSeat
  L4_2 = {}
  L5_2 = uPrimaryPlayer
  L6_2 = uLuckyLady
  L7_2 = "a"
  L8_2 = "e"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  
  function L5_2(A0_3)
    local L1_3, L2_3
    L1_3 = oTransitEnt
    L1_3 = L1_3.Complete
    L2_3 = oTransitEnt
    L1_3(L2_3)
    L1_3 = eHeroIn
    if L1_3 then
      L1_3 = Event
      L1_3 = L1_3.Delete
      L2_3 = eHeroIn
      L1_3(L2_3)
    end
  end
  
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  eHeroIn = L1_2
end

ObjectifyLady = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectInSeat
  L4_2 = {}
  L5_2 = uPrimaryPlayer
  L6_2 = uLuckyLady
  L7_2 = "a"
  L8_2 = "e"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  
  function L5_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = MrxTransit
    L1_3 = L1_3.OpenInterface
    L2_3 = Player
    L2_3 = L2_3.GetLocalPlayer
    L2_3 = L2_3()
    L3_3 = _TransitCallback
    L1_3(L2_3, L3_3)
    L2_3 = A0_3
    L1_3 = A0_3.LadyCheck
    L1_3(L2_3)
  end
  
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  eReenterLady = L1_2
end

LadyCheck = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2
  L4_2 = Ai
  L4_2 = L4_2.Anchor
  L5_2 = {}
  L5_2.AIGuid = A2_2
  L5_2.AnchorRadius = 0
  L5_2.AnchorGuid = A1_2
  L4_2(L5_2)
  L4_2 = Ai
  L4_2 = L4_2.Goal
  L5_2 = {}
  L5_2.AIGuid = A2_2
  L5_2.Goal = "Idle"
  L5_2.MaintainRotorSpeed = A3_2
  L5_2.Priority = "medPri"
  L4_2(L5_2)
end

EwanLand = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  L3_2 = MrxSupportData
  L3_2 = L3_2.AddFreebie
  L4_2 = "OilCon002_OC"
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
  L3_2 = MrxSupportData
  L3_2 = L3_2.AddFreebie
  L4_2 = "OilCon002_EXT"
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
  L3_2 = MrxSupportData
  L3_2 = L3_2.AddFreebie
  L4_2 = "OilCon002_LightMG"
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
  if A2_2 then
    L3_2 = MrxSupportData
    L3_2 = L3_2.AddFreebie
    L4_2 = "OC_ClusterBomb"
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
  end
end

FreebieAdd = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  if not A1_2 then
    return
  end
  L2_2 = MrxLayerManager
  L2_2 = L2_2.Add
  L3_2 = "VZ_state_PilCon002_Epilogue"
  L2_2(L3_2)
  L2_2 = MrxTransit
  L2_2 = L2_2.Transit
  L3_2 = A0_2
  L2_2(L3_2)
end

_TransitCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = {}
  L2_2 = "VZ_state_OilCon002_Pristine"
  L3_2 = "Vz_State_OilCon002"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L2_2 = MrxLayerManager
  L2_2 = L2_2.Add
  L3_2 = L1_2
  L4_2 = AssetsLoaded
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L2_2(L3_2, L4_2, L5_2)
end

LoadAssets = L0_1
