local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTimer"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = 0
  nPlayed1 = L1_2
  L1_2 = 0
  nPlayed2 = L1_2
  L1_2 = nil
  gbLostTooManyBirds = L1_2
  L1_2 = 10
  nParrotLostLine = L1_2
  L1_2 = 42
  nGoods = L1_2
  L1_2 = 42
  nGoodCopy = L1_2
  L1_2 = false
  bClientwasIn = L1_2
  L1_2 = 42
  nGoods1 = L1_2
  L1_2 = 0
  nGoods2 = L1_2
  L1_2 = 100
  nTruckHealth = L1_2
  L1_2 = 0
  ParrotChat = L1_2
  L1_2 = false
  bParrotVOon = L1_2
  L1_2 = 1900
  nCargoValue = L1_2
  L1_2 = 0
  nGoodsDelivered = L1_2
  L1_2 = {}
  tInitialVOTable = L1_2
  L1_2 = {}
  L2_2 = "ParrotPickup"
  L1_2[1] = L2_2
  tPickups = L1_2
  L1_2 = Player
  L1_2 = L1_2.IsCoopMultiplayer
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = SetupMPGame
    L2_2 = A0_2
    L1_2(L2_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2.GetNumCompletions
  L1_2 = L1_2(L2_2)
  if 2 <= L1_2 then
    L2_2 = 2
    nDifficult = L2_2
    L2_2 = 25
    nRequired = L2_2
    L2_2 = nRequired
    L3_2 = nCargoValue
    L2_2 = L2_2 * L3_2
    nRequiredCash = L2_2
    L2_2 = {}
    L3_2 = "Fiona-In-Mission-MinorContract-Pir03-40"
    L4_2 = "Fiona-In-Mission-MinorContract-Pir03-41"
    L5_2 = "Fiona-In-Mission-MinorContract-Pir03-37"
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
    tInitialVOTable = L2_2
  elseif L1_2 == 1 then
    L2_2 = 1
    nDifficult = L2_2
    L2_2 = 15
    nRequired = L2_2
    L2_2 = nRequired
    L3_2 = nCargoValue
    L2_2 = L2_2 * L3_2
    nRequiredCash = L2_2
    L2_2 = {}
    L3_2 = "Fiona-In-Mission-MinorContract-Pir03-38"
    L4_2 = "Fiona-In-Mission-MinorContract-Pir03-39"
    L5_2 = "Fiona-In-Mission-MinorContract-Pir03-36"
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
    tInitialVOTable = L2_2
  else
    L2_2 = 0
    nDifficult = L2_2
    L2_2 = 7
    nRequired = L2_2
    L2_2 = nRequired
    L3_2 = nCargoValue
    L2_2 = L2_2 * L3_2
    nRequiredCash = L2_2
  end
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "PirCon003gotoVehicle"
  L4_2.sModuleName = "MrxTaskObjectiveEnterVehicle"
  L5_2 = tPickups
  L4_2.vTgtInclude = L5_2
  L4_2.nQuota = 1
  L5_2 = tInitialVOTable
  L4_2.vVoSeqOnAdd = L5_2
  L4_2.sDspShortDesc = "[PirCon003.Objectives.001]"
  L5_2 = {}
  L6_2 = {}
  L7_2 = DeliverTruck
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnComplete = L5_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = false
    bParrotVOon = L0_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._SetCancelMessage
    L2_3 = "[PirCon003.Terms.Cancel03]"
    L0_3(L1_3, L2_3)
    L0_3 = MrxMusic
    L0_3 = L0_3.StopSpecialMusic
    L1_3 = "none"
    L0_3(L1_3)
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-Oil020-07"
    L3_3 = {}
    L4_3 = A0_2
    L4_3 = L4_3.Cancel
    L5_3 = {}
    L6_3 = A0_2
    L5_3[1] = L6_3
    L3_3[1] = L4_3
    L3_3[2] = L5_3
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L0_3(L1_3)
  end
  
  L4_2.fOnCancel = L5_2
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAnyCharacter
  L6_2 = L6_2()
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "ParrotPickup"
  L7_2 = L7_2(L8_2)
  L8_2 = "<"
  L9_2 = 10
  L10_2 = false
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = BirdTalk
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 3
  L5_2[1] = L6_2
  L6_2 = StartCheckingBirds
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._CreatePersistentEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 1.5
  L4_2[1] = L5_2
  L5_2 = CheckGoodsLost
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

StartCheckingBirds = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2
  L1_2 = A0_2.GetNumCompletions
  L1_2 = L1_2(L2_2)
  if L1_2 == 2 or L1_2 == 6 then
    L3_2 = A0_2
    L2_2 = A0_2._CreateEvent
    L4_2 = Event
    L4_2 = L4_2.TimerRelative
    L5_2 = {}
    L6_2 = 9
    L5_2[1] = L6_2
    L6_2 = VO
    L6_2 = L6_2.CueWithoutSubtitles
    L7_2 = {}
    L8_2 = 0
    L9_2 = "Parrot-In-Mission-MinorContract-Pir03-07"
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
    L3_2 = A0_2
    L2_2 = A0_2._CreateEvent
    L4_2 = Event
    L4_2 = L4_2.TimerRelative
    L5_2 = {}
    L6_2 = 10
    L5_2[1] = L6_2
    
    function L6_2(A0_3)
      local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
      L1_3 = MrxVoSequence
      L1_3 = L1_3.Start
      L2_3 = {}
      L3_3 = "Fiona-In-Mission-MinorContract-Pir03-28"
      L4_3 = {}
      L4_3.mattias = "Mattias-In-Mission-MinorContract-Pir03-30"
      L4_3.jennifer = "jennifer-In-Mission-MinorContract-Pir03-31"
      L4_3.chris = "chris-In-Mission-MinorContract-Pir03-32"
      L5_3 = {}
      L6_3 = ParrotVO
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
    
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  elseif L1_2 == 1 or L1_2 == 4 then
    L3_2 = A0_2
    L2_2 = A0_2._CreateEvent
    L4_2 = Event
    L4_2 = L4_2.TimerRelative
    L5_2 = {}
    L6_2 = 9
    L5_2[1] = L6_2
    L6_2 = VO
    L6_2 = L6_2.CueWithoutSubtitles
    L7_2 = {}
    L8_2 = 0
    L9_2 = "Parrot-In-Mission-MinorContract-Pir03-07"
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
    L3_2 = A0_2
    L2_2 = A0_2._CreateEvent
    L4_2 = Event
    L4_2 = L4_2.TimerRelative
    L5_2 = {}
    L6_2 = 10
    L5_2[1] = L6_2
    
    function L6_2(A0_3)
      local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
      L1_3 = MrxVoSequence
      L1_3 = L1_3.Start
      L2_3 = {}
      L3_3 = "Fiona-In-Mission-MinorContract-Pir03-29"
      L4_3 = {}
      L4_3.mattias = "Mattias-In-Mission-MinorContract-Pir03-33"
      L4_3.jennifer = "jennifer-In-Mission-MinorContract-Pir03-34"
      L4_3.chris = "chris-In-Mission-MinorContract-Pir03-35"
      L5_3 = {}
      L6_3 = ParrotVO
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
    
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  else
    L2_2 = VO
    L2_2 = L2_2.CueWithoutSubtitles
    L3_2 = 0
    L4_2 = "Parrot-In-Mission-MinorContract-Pir03-07"
    L2_2(L3_2, L4_2)
    L3_2 = A0_2
    L2_2 = A0_2._CreateEvent
    L4_2 = Event
    L4_2 = L4_2.TimerRelative
    L5_2 = {}
    L6_2 = 1
    L5_2[1] = L6_2
    L6_2 = VO
    L6_2 = L6_2.CueWithoutSubtitles
    L7_2 = {}
    L8_2 = 0
    L9_2 = "Parrot-In-Mission-MinorContract-Pir03-09"
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
    L3_2 = A0_2
    L2_2 = A0_2._CreateEvent
    L4_2 = Event
    L4_2 = L4_2.TimerRelative
    L5_2 = {}
    L6_2 = 2
    L5_2[1] = L6_2
    
    function L6_2(A0_3)
      local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3
      L1_3 = MrxVoSequence
      L1_3 = L1_3.Start
      L2_3 = {}
      L3_3 = "Fiona-Banter-MinorContract-Pir02-01"
      L4_3 = {}
      L4_3.mattias = "mattias-Banter-MinorContract-Pir02-02"
      L4_3.jennifer = "jennifer-Banter-MinorContract-Pir02-03"
      L4_3.chris = "chris-Banter-MinorContract-Pir02-04"
      L5_3 = "Fiona-Banter-MinorContract-Pir02-05"
      L6_3 = {}
      L6_3.mattias = "mattias-Banter-MinorContract-Pir02-06"
      L6_3.jennifer = "jennifer-Banter-MinorContract-Pir02-07"
      L6_3.chris = "chris-Banter-MinorContract-Pir02-08"
      L7_3 = "Fiona-Banter-MinorContract-Pir02-13"
      L8_3 = {}
      L8_3.mattias = "mattias-Banter-MinorContract-Pir02-14"
      L8_3.jennifer = "jennifer-Banter-MinorContract-Pir02-15"
      L8_3.chris = "chris-Banter-MinorContract-Pir02-16"
      L9_3 = "Fiona-Banter-MinorContract-Pir02-17"
      L10_3 = {}
      L11_3 = ParrotVO
      L12_3 = {}
      L13_3 = A0_3
      L12_3[1] = L13_3
      L10_3[1] = L11_3
      L10_3[2] = L12_3
      L2_3[1] = L3_3
      L2_3[2] = L4_3
      L2_3[3] = L5_3
      L2_3[4] = L6_3
      L2_3[5] = L7_3
      L2_3[6] = L8_3
      L2_3[7] = L9_3
      L2_3[8] = L10_3
      L1_3(L2_3)
    end
    
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  end
end

BirdTalk = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = MrxMusic
  L1_2 = L1_2.PlaySpecialMusic
  L2_2 = "mu_mission_pircon003_02"
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetNumCompletions
  L1_2 = L1_2(L2_2)
  L2_2 = {}
  tPursuitTable = L2_2
  if 2 <= L1_2 then
    L2_2 = "[PirCon003.Objectives.Hard]"
    sScaleObj = L2_2
  elseif L1_2 == 1 then
    L2_2 = "[PirCon003.Objectives.Med]"
    sScaleObj = L2_2
  else
    L2_2 = "[PirCon003.Objectives.Easy]"
    sScaleObj = L2_2
  end
  L2_2 = "[PirCon003.Objectives.Req]"
  L3_2 = MrxUtil
  L3_2 = L3_2.FormatMoney
  L4_2 = nRequiredCash
  L3_2 = L3_2(L4_2)
  L4_2 = " [PirCon003.Objectives.ReqB]"
  L2_2 = L2_2 .. L3_2 .. L4_2
  sHText = L2_2
  L2_2 = Hud
  L2_2 = L2_2.ObjectiveTray
  L3_2 = L2_2
  L2_2 = L2_2.SetSlotToText
  L4_2 = {}
  L4_2.vPlayer = nil
  L4_2.nSlot = 2
  L5_2 = sHText
  L4_2.sText = L5_2
  L2_2(L3_2, L4_2)
  L2_2 = DisplayGoodsLost
  L3_2 = A0_2
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "PirCon003: Deliver goods"
  L4_2.sModuleName = "MrxTaskObjectiveDeliver"
  L5_2 = tPickups
  L4_2.vTgtInclude = L5_2
  L4_2.nQuota = 1
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "loc_DeliverySpot"
  L5_2 = L5_2(L6_2)
  L4_2.vDestLoc = L5_2
  L4_2.fDist = 10
  L5_2 = sScaleObj
  L4_2.sDspShortDesc = L5_2
  L4_2.bStop = true
  L4_2.bXZOnly = false
  
  function L5_2()
    local L0_3, L1_3
    L0_3 = bClientwasIn
    if L0_3 then
      L0_3 = ActivateDelivered
      L1_3 = A0_2
      L0_3(L1_3)
    else
      L0_3 = CountDelivered
      L1_3 = A0_2
      L0_3(L1_3)
    end
  end
  
  L4_2.fOnComplete = L5_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = false
    bParrotVOon = L0_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._SetCancelMessage
    L2_3 = "[PirCon003.Terms.Cancel03]"
    L0_3(L1_3, L2_3)
    L0_3 = MrxMusic
    L0_3 = L0_3.StopSpecialMusic
    L1_3 = "none"
    L0_3(L1_3)
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = "Fiona-In-Mission-Contract-Oil020-07"
    L3_3 = {}
    L4_3 = A0_2
    L4_3 = L4_3.Cancel
    L5_3 = {}
    L6_3 = A0_2
    L5_3[1] = L6_3
    L3_3[1] = L4_3
    L3_3[2] = L5_3
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    L0_3(L1_3)
  end
  
  L4_2.fOnCancel = L5_2
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "ParrotPickup"
  L6_2 = L6_2(L7_2)
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "loc_vzAttack"
  L7_2 = L7_2(L8_2)
  L8_2 = ">"
  L9_2 = 150
  L10_2 = false
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = DaCustomPursuit
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = nDifficult
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAnyCharacter
  L6_2 = L6_2()
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "loc_DeliverySpot_end"
  L7_2 = L7_2(L8_2)
  L8_2 = "<"
  L9_2 = 250
  L10_2 = false
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = MrxFactionManager
  L6_2 = L6_2.ClearCustomPursuit
  L7_2 = {}
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAnyCharacter
  L6_2 = L6_2()
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "loc_CliffyA"
  L7_2 = L7_2(L8_2)
  L8_2 = "<"
  L9_2 = 50
  L10_2 = false
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = CliffyA
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

DeliverTruck = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = true
  bParrotVOon = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 4
  L4_2[1] = L5_2
  L5_2 = SpeedVO
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 6
  L4_2[1] = L5_2
  L5_2 = DamageVO
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

ParrotVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = nTruckHealth
  L2_2 = Object
  L2_2 = L2_2.GetHealth
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "ParrotPickup"
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  nTruckHealth = L2_2
  L2_2 = nTruckHealth
  if L1_2 > L2_2 then
    L2_2 = bParrotVOon
    if L2_2 then
      L2_2 = {}
      L3_2 = "Parrot-In-Mission-MinorContract-Pir03-07"
      L4_2 = "Parrot-In-Mission-MinorContract-Pir03-06"
      L5_2 = "Parrot-In-Mission-MinorContract-Pir03-05"
      L6_2 = "Parrot-In-Mission-MinorContract-Pir03-14"
      L7_2 = "Parrot-In-Mission-MinorContract-Pir03-17"
      L8_2 = "Parrot-In-Mission-MinorContract-Pir03-07"
      L9_2 = "Parrot-In-Mission-MinorContract-Pir03-09"
      L10_2 = "Parrot-In-Mission-MinorContract-Pir03-09"
      L11_2 = "Parrot-In-Mission-MinorContract-Pir03-07"
      L12_2 = "Parrot-In-Mission-MinorContract-Pir03-06"
      L2_2[1] = L3_2
      L2_2[2] = L4_2
      L2_2[3] = L5_2
      L2_2[4] = L6_2
      L2_2[5] = L7_2
      L2_2[6] = L8_2
      L2_2[7] = L9_2
      L2_2[8] = L10_2
      L2_2[9] = L11_2
      L2_2[10] = L12_2
      L3_2 = MrxUtil
      L3_2 = L3_2.GetRandomTableElement
      L4_2 = L2_2
      L3_2 = L3_2(L4_2)
      L4_2 = MrxUtil
      L4_2 = L4_2.GetRandomTableElement
      L5_2 = L2_2
      L4_2 = L4_2(L5_2)
      L5_2 = VO
      L5_2 = L5_2.CueWithoutSubtitles
      L6_2 = 0
      L7_2 = L3_2
      L5_2(L6_2, L7_2)
      L6_2 = A0_2
      L5_2 = A0_2._CreateEvent
      L7_2 = Event
      L7_2 = L7_2.TimerRelative
      L8_2 = {}
      L9_2 = 1.5
      L8_2[1] = L9_2
      L9_2 = VO
      L9_2 = L9_2.CueWithoutSubtitles
      L10_2 = {}
      L11_2 = 0
      L12_2 = L3_2
      L10_2[1] = L11_2
      L10_2[2] = L12_2
      L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
      L6_2 = A0_2
      L5_2 = A0_2._CreateEvent
      L7_2 = Event
      L7_2 = L7_2.TimerRelative
      L8_2 = {}
      L9_2 = 15
      L8_2[1] = L9_2
      L9_2 = DamageVO
      L10_2 = {}
      L11_2 = A0_2
      L10_2[1] = L11_2
      L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  end
  else
    L3_2 = A0_2
    L2_2 = A0_2._CreateEvent
    L4_2 = Event
    L4_2 = L4_2.TimerRelative
    L5_2 = {}
    L6_2 = 5
    L5_2[1] = L6_2
    L6_2 = DamageVO
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  end
end

DamageVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L1_2 = ParrotChat
  if L1_2 == 0 then
    L1_2 = bParrotVOon
    if L1_2 then
      L1_2 = {}
      L2_2 = "Parrot-In-Mission-MinorContract-Pir03-16"
      L3_2 = "Parrot-In-Mission-MinorContract-Pir03-16"
      L4_2 = "Parrot-In-Mission-MinorContract-Pir03-19"
      L5_2 = "Parrot-In-Mission-MinorContract-Pir03-15"
      L6_2 = "Parrot-In-Mission-MinorContract-Pir03-07"
      L7_2 = "Parrot-In-Mission-MinorContract-Pir03-07"
      L8_2 = "Parrot-In-Mission-MinorContract-Pir03-07"
      L9_2 = "Parrot-In-Mission-MinorContract-Pir03-07"
      L10_2 = "Parrot-In-Mission-MinorContract-Pir03-07"
      L11_2 = "Parrot-In-Mission-MinorContract-Pir03-08"
      L12_2 = "Parrot-In-Mission-MinorContract-Pir03-08"
      L13_2 = "Parrot-In-Mission-MinorContract-Pir03-06"
      L14_2 = "Parrot-In-Mission-MinorContract-Pir03-07"
      L15_2 = "Parrot-In-Mission-MinorContract-Pir03-06"
      L16_2 = "Parrot-In-Mission-MinorContract-Pir03-05"
      L17_2 = "Parrot-In-Mission-MinorContract-Pir03-14"
      L18_2 = "Parrot-In-Mission-MinorContract-Pir03-14"
      L19_2 = "Parrot-In-Mission-MinorContract-Pir03-17"
      L20_2 = "Parrot-In-Mission-MinorContract-Pir03-07"
      L21_2 = "Parrot-In-Mission-MinorContract-Pir03-09"
      L1_2[1] = L2_2
      L1_2[2] = L3_2
      L1_2[3] = L4_2
      L1_2[4] = L5_2
      L1_2[5] = L6_2
      L1_2[6] = L7_2
      L1_2[7] = L8_2
      L1_2[8] = L9_2
      L1_2[9] = L10_2
      L1_2[10] = L11_2
      L1_2[11] = L12_2
      L1_2[12] = L13_2
      L1_2[13] = L14_2
      L1_2[14] = L15_2
      L1_2[15] = L16_2
      L1_2[16] = L17_2
      L1_2[17] = L18_2
      L1_2[18] = L19_2
      L1_2[19] = L20_2
      L1_2[20] = L21_2
      L2_2 = MrxUtil
      L2_2 = L2_2.GetRandomTableElement
      L3_2 = L1_2
      L2_2 = L2_2(L3_2)
      L3_2 = MrxUtil
      L3_2 = L3_2.GetRandomTableElement
      L4_2 = L1_2
      L3_2 = L3_2(L4_2)
      L4_2 = VO
      L4_2 = L4_2.CueWithoutSubtitles
      L5_2 = 0
      L6_2 = L2_2
      L4_2(L5_2, L6_2)
      L5_2 = A0_2
      L4_2 = A0_2._CreateEvent
      L6_2 = Event
      L6_2 = L6_2.TimerRelative
      L7_2 = {}
      L8_2 = 1
      L7_2[1] = L8_2
      L8_2 = VO
      L8_2 = L8_2.CueWithoutSubtitles
      L9_2 = {}
      L10_2 = 0
      L11_2 = L2_2
      L9_2[1] = L10_2
      L9_2[2] = L11_2
      L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
      L4_2 = 1
      ParrotChat = L4_2
      L5_2 = A0_2
      L4_2 = A0_2._CreateEvent
      L6_2 = Event
      L6_2 = L6_2.TimerRelative
      L7_2 = {}
      L8_2 = 7
      L7_2[1] = L8_2
      L8_2 = ParrotCooldown
      L9_2 = {}
      L10_2 = A0_2
      L9_2[1] = L10_2
      L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
    end
  end
end

ParrotLostVO = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = 0
  ParrotChat = L1_2
end

ParrotCooldown = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "ParrotPickup"
  L1_2 = L1_2(L2_2)
  uTruck = L1_2
  L1_2 = Object
  L1_2 = L1_2.IsAwake
  L2_2 = uTruck
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = Object
    L1_2 = L1_2.GetVelocity
    L2_2 = uTruck
    L1_2 = L1_2(L2_2)
    nTruckSpeed = L1_2
    L1_2 = nTruckSpeed
    if 25 < L1_2 then
      L1_2 = bParrotVOon
      if L1_2 then
        L1_2 = {}
        L2_2 = "Parrot-In-Mission-MinorContract-Pir03-07"
        L3_2 = "Parrot-In-Mission-MinorContract-Pir03-06"
        L4_2 = "Parrot-In-Mission-MinorContract-Pir03-11"
        L5_2 = "Parrot-In-Mission-MinorContract-Pir03-07"
        L6_2 = "Parrot-In-Mission-MinorContract-Pir03-06"
        L7_2 = "Parrot-In-Mission-MinorContract-Pir03-05"
        L8_2 = "Parrot-In-Mission-MinorContract-Pir03-05"
        L9_2 = "Parrot-In-Mission-MinorContract-Pir03-14"
        L10_2 = "Parrot-In-Mission-MinorContract-Pir03-07"
        L11_2 = "Parrot-In-Mission-MinorContract-Pir03-09"
        L12_2 = "Parrot-In-Mission-MinorContract-Pir03-15"
        L13_2 = "Parrot-In-Mission-MinorContract-Pir03-07"
        L14_2 = "Parrot-In-Mission-MinorContract-Pir03-07"
        L15_2 = "Parrot-In-Mission-MinorContract-Pir03-07"
        L16_2 = "Parrot-In-Mission-MinorContract-Pir03-07"
        L17_2 = "Parrot-In-Mission-MinorContract-Pir03-07"
        L1_2[1] = L2_2
        L1_2[2] = L3_2
        L1_2[3] = L4_2
        L1_2[4] = L5_2
        L1_2[5] = L6_2
        L1_2[6] = L7_2
        L1_2[7] = L8_2
        L1_2[8] = L9_2
        L1_2[9] = L10_2
        L1_2[10] = L11_2
        L1_2[11] = L12_2
        L1_2[12] = L13_2
        L1_2[13] = L14_2
        L1_2[14] = L15_2
        L1_2[15] = L16_2
        L1_2[16] = L17_2
        L2_2 = MrxUtil
        L2_2 = L2_2.GetRandomTableElement
        L3_2 = L1_2
        L2_2 = L2_2(L3_2)
        L3_2 = VO
        L3_2 = L3_2.CueWithoutSubtitles
        L4_2 = 0
        L5_2 = L2_2
        L3_2(L4_2, L5_2)
        L4_2 = A0_2
        L3_2 = A0_2._CreateEvent
        L5_2 = Event
        L5_2 = L5_2.TimerRelative
        L6_2 = {}
        L7_2 = 20
        L6_2[1] = L7_2
        L7_2 = SpeedVO
        L8_2 = {}
        L9_2 = A0_2
        L8_2[1] = L9_2
        L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
    end
    else
      L2_2 = A0_2
      L1_2 = A0_2._CreateEvent
      L3_2 = Event
      L3_2 = L3_2.TimerRelative
      L4_2 = {}
      L5_2 = 5
      L4_2[1] = L5_2
      L5_2 = SpeedVO
      L6_2 = {}
      L7_2 = A0_2
      L6_2[1] = L7_2
      L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
    end
  end
end

SpeedVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = {}
  L2_2 = Vehicle
  L2_2 = L2_2.GetDriver
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "CliffyA"
  L3_2, L4_2, L5_2, L6_2, L7_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2.AIGuid = L2_2
  L1_2.Goal = "PathMove"
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "Pa_CliffyA"
  L2_2 = L2_2(L3_2)
  L1_2.Target = L2_2
  L1_2.Priority = "hiPri"
  uBlockParam = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 0.3
  L4_2[1] = L5_2
  L5_2 = Ai
  L5_2 = L5_2.Goal
  L6_2 = {}
  L7_2 = uBlockParam
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = {}
  L2_2 = Vehicle
  L2_2 = L2_2.GetDriver
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "CliffyB"
  L3_2, L4_2, L5_2, L6_2, L7_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L1_2.AIGuid = L2_2
  L1_2.Goal = "PathMove"
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "Pa_CliffyB"
  L2_2 = L2_2(L3_2)
  L1_2.Target = L2_2
  L1_2.Priority = "hiPri"
  uBlockParam2 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 1
  L4_2[1] = L5_2
  L5_2 = Ai
  L5_2 = L5_2.Goal
  L6_2 = {}
  L7_2 = uBlockParam2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

CliffyA = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = nGoods
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "ParrotPickup"
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = Object
    L3_2 = L3_2.IsAlive
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L3_2 = MrxUtil
      L3_2 = L3_2.TestDistanceToAllPlayers
      L4_2 = L2_2
      L5_2 = 35
      L6_2 = false
      L7_2 = true
      L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
      if not L3_2 then
        L4_2 = A0_2
        L3_2 = A0_2._CreateEvent
        L5_2 = Event
        L5_2 = L5_2.TimerRelative
        L6_2 = {}
        L7_2 = 1
        L6_2[1] = L7_2
        
        function L7_2(A0_3)
          local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
          L1_3 = MrxUtil
          L1_3 = L1_3.TestDistanceToAllPlayers
          L2_3 = L2_2
          L3_3 = 35
          L4_3 = false
          L5_3 = true
          L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3)
          if not L1_3 then
            L1_3 = Object
            L1_3 = L1_3.GetHardpointPosition
            L2_3 = L2_2
            L3_3 = "HP_Truckbed"
            L1_3, L2_3, L3_3 = L1_3(L2_3, L3_3)
            if L1_3 and L2_3 and L3_3 then
              L4_3 = Pg
              L4_3 = L4_3.GetObjectsInArea
              L5_3 = L1_3
              L6_3 = L2_3
              L7_3 = L3_3
              L8_3 = 1
              L9_3 = "BirdBox"
              L4_3 = L4_3(L5_3, L6_3, L7_3, L8_3, L9_3)
              L5_3 = table
              L5_3 = L5_3.getn
              L6_3 = L4_3
              L5_3 = L5_3(L6_3)
              nGoods1 = L5_3
            end
          end
        end
        
        L8_2 = {}
        L9_2 = A0_2
        L8_2[1] = L9_2
        L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
      end
    else
      L3_2 = 0
      nGoods1 = L3_2
    end
  end
  L3_2 = bClientwasIn
  if L3_2 then
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = "ParrotPickup_2"
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L4_2 = Object
      L4_2 = L4_2.IsAlive
      L5_2 = L3_2
      L4_2 = L4_2(L5_2)
      if L4_2 then
        L4_2 = MrxUtil
        L4_2 = L4_2.TestDistanceToAllPlayers
        L5_2 = L3_2
        L6_2 = 45
        L7_2 = false
        L8_2 = true
        L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
        if not L4_2 then
          L5_2 = A0_2
          L4_2 = A0_2._CreateEvent
          L6_2 = Event
          L6_2 = L6_2.TimerRelative
          L7_2 = {}
          L8_2 = 1
          L7_2[1] = L8_2
          
          function L8_2(A0_3)
            local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
            L1_3 = MrxUtil
            L1_3 = L1_3.TestDistanceToAllPlayers
            L2_3 = L2_2
            L3_3 = 35
            L4_3 = false
            L5_3 = true
            L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3)
            if not L1_3 then
              L1_3 = Object
              L1_3 = L1_3.GetHardpointPosition
              L2_3 = L3_2
              L3_3 = "HP_Truckbed"
              L1_3, L2_3, L3_3 = L1_3(L2_3, L3_3)
              if L1_3 and L2_3 and L3_3 then
                L4_3 = Pg
                L4_3 = L4_3.GetObjectsInArea
                L5_3 = L1_3
                L6_3 = L2_3
                L7_3 = L3_3
                L8_3 = 1
                L9_3 = "BirdBox"
                L4_3 = L4_3(L5_3, L6_3, L7_3, L8_3, L9_3)
                L5_3 = table
                L5_3 = L5_3.getn
                L6_3 = L4_3
                L5_3 = L5_3(L6_3)
                nGoods2 = L5_3
              end
            end
          end
          
          L9_2 = {}
          L10_2 = A0_2
          L9_2[1] = L10_2
          L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
        end
      else
        L4_2 = 0
        nGoods2 = L4_2
      end
    end
  end
  L3_2 = nGoods1
  L4_2 = nGoods2
  L3_2 = L3_2 + L4_2
  nGoods = L3_2
  L3_2 = nGoods
  if L1_2 > L3_2 then
    L3_2 = ParrotLostVO
    L4_2 = A0_2
    L3_2(L4_2)
    L3_2 = DisplayGoodsLost
    L4_2 = A0_2
    L3_2(L4_2)
  end
end

CheckGoodsLost = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = nGoods
  L2_2 = nCargoValue
  L1_2 = L1_2 * L2_2
  nCash = L1_2
  L1_2 = "[0x85070644]: "
  L2_2 = MrxUtil
  L2_2 = L2_2.FormatMoney
  L3_2 = nCash
  L2_2 = L2_2(L3_2)
  L1_2 = L1_2 .. L2_2
  sHudText = L1_2
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.SetSlotToText
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 1
  L4_2 = sHudText
  L3_2.sText = L4_2
  L1_2(L2_2, L3_2)
  
  function L1_2(A0_3, A1_3, A2_3)
    local L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
    L3_3 = true
    gbLostTooManyBirds = L3_3
    L3_3 = false
    bParrotVOon = L3_3
    L3_3 = MrxMusic
    L3_3 = L3_3.StopSpecialMusic
    L4_3 = "none"
    L3_3(L4_3)
    L4_3 = A0_3
    L3_3 = A0_3._SetCancelMessage
    L5_3 = "[PirCon003.Terms.Cancel01]"
    L3_3(L4_3, L5_3)
    L3_3 = MrxVoSequence
    L3_3 = L3_3.Start
    L4_3 = {}
    L5_3 = A2_3
    L6_3 = {}
    L7_3 = A0_3.Cancel
    L8_3 = {}
    L9_3 = A0_3
    L8_3[1] = L9_3
    L6_3[1] = L7_3
    L6_3[2] = L8_3
    L4_3[1] = L5_3
    L4_3[2] = L6_3
    L3_3(L4_3)
  end
  
  _TooManyBirdsLost = L1_2
  L1_2 = nGoods
  if L1_2 <= 37 then
    L1_2 = nPlayed1
    if L1_2 == 0 then
      L1_2 = 1
      nPlayed1 = L1_2
    end
  end
  L1_2 = nGoods
  L2_2 = nRequired
  if L1_2 < L2_2 then
    L1_2 = gbLostTooManyBirds
    if not L1_2 then
      L2_2 = A0_2
      L1_2 = A0_2._TooManyBirdsLost
      L3_2 = nRequiredCash
      L4_2 = "Fiona-In-Mission-MinorContract-Pir03-27"
      L1_2(L2_2, L3_2, L4_2)
    end
  end
end

DisplayGoodsLost = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "PirCon003 MP End"
  L3_2.sModuleName = "MrxTaskObjectiveAction"
  L3_2.vTgtInclude = "PirCon003_endTalk"
  L3_2.sDspShortDesc = "[PirCon003.Objectives.end]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = CountDelivered
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
  L1_2(L2_2, L3_2)
end

ActivateDelivered = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L1_2 = false
  bParrotVOon = L1_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "loc_DeliverySpot_end"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2 = L2_2(L3_2)
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetObjectsInArea
  L6_2 = L1_2
  L7_2 = L2_2
  L8_2 = L3_2
  L9_2 = 25
  L10_2 = "BirdBox"
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L6_2 = table
  L6_2 = L6_2.getn
  L7_2 = L5_2
  L6_2 = L6_2(L7_2)
  L7_2 = nCargoValue
  L7_2 = L6_2 * L7_2
  if L6_2 == 42 then
    L8_2 = bClientwasIn
    if not L8_2 then
      L9_2 = A0_2
      L8_2 = A0_2._SetPlayer1Bonus
      L10_2 = 2000000 + L7_2
      L8_2(L9_2, L10_2)
  end
  else
    if L6_2 == 84 then
      L8_2 = bClientwasIn
      if L8_2 then
        L8_2 = L7_2 / 2
        L8_2 = 2000000 + L8_2
        L10_2 = A0_2
        L9_2 = A0_2._SetPlayer1Bonus
        L11_2 = L8_2
        L9_2(L10_2, L11_2)
        L10_2 = A0_2
        L9_2 = A0_2._SetPlayer2Bonus
        L11_2 = L8_2
        L9_2(L10_2, L11_2)
    end
    else
      L8_2 = Net
      L8_2 = L8_2.IsActive
      L8_2 = L8_2()
      if L8_2 then
        L9_2 = A0_2
        L8_2 = A0_2._SetPlayer1Bonus
        L10_2 = L7_2 / 2
        L8_2(L9_2, L10_2)
        L9_2 = A0_2
        L8_2 = A0_2._SetPlayer2Bonus
        L10_2 = L7_2 / 2
        L8_2(L9_2, L10_2)
      else
        L9_2 = A0_2
        L8_2 = A0_2._SetPlayer1Bonus
        L10_2 = L7_2
        L8_2(L9_2, L10_2)
      end
    end
  end
  if 1 <= L6_2 then
    L8_2 = MrxVoSequence
    L8_2 = L8_2.Start
    L9_2 = {}
    L10_2 = "PirThug-In-Mission-MinorContract-Pir02-06"
    L11_2 = "Fiona-In-Mission-MinorContract-Pir02-05"
    L12_2 = {}
    L13_2 = A0_2.Complete
    L14_2 = {}
    L15_2 = A0_2
    L14_2[1] = L15_2
    L12_2[1] = L13_2
    L12_2[2] = L14_2
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L8_2(L9_2)
  else
    L8_2 = MrxVoSequence
    L8_2 = L8_2.Start
    L9_2 = {}
    L10_2 = "PirThug-In-Mission-MinorContract-Pir02-08"
    L9_2[1] = L10_2
    L8_2(L9_2)
    L9_2 = A0_2
    L8_2 = A0_2._SetCancelMessage
    L10_2 = "[PirCon003.Terms.Cancel01]"
    L8_2(L9_2, L10_2)
    L9_2 = A0_2
    L8_2 = A0_2._CreateEvent
    L10_2 = Event
    L10_2 = L10_2.TimerRelative
    L11_2 = {}
    L12_2 = 4
    L11_2[1] = L12_2
    L12_2 = A0_2.Cancel
    L13_2 = {}
    L14_2 = A0_2
    L13_2[1] = L14_2
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  end
end

CountDelivered = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = {}
  L2_2 = "vz_State_PirCon003_MP"
  L1_2[1] = L2_2
  tLayersToAdd = L1_2
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Add
  L2_2 = tLayersToAdd
  L1_2(L2_2)
  L1_2 = {}
  L2_2 = "ParrotPickup"
  L3_2 = "ParrotPickup_2"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  tPickups = L1_2
  L1_2 = true
  bClientwasIn = L1_2
  L1_2 = 42
  nGoods2 = L1_2
  L1_2 = 84
  nGoodCopy = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "PirCon003_endTalk"
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  
  function L5_2(A0_3)
    local L1_3, L2_3, L3_3
    L2_3 = A0_3
    L1_3 = A0_3._SetCancelMessage
    L3_3 = "[PirCon003.Terms.Cancel04]"
    L1_3(L2_3, L3_3)
    L2_3 = A0_3
    L1_3 = A0_3.Cancel
    L1_3(L2_3)
  end
  
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "PirCon003_endTalk"
  L5_2 = L5_2(L6_2)
  L6_2 = "awake"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  
  function L5_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3
    L1_3 = Ai
    L1_3 = L1_3.Goal
    L2_3 = {}
    L3_3 = Pg
    L3_3 = L3_3.GetGuidByName
    L4_3 = "PirCon003_endTalk"
    L3_3 = L3_3(L4_3)
    L2_3.AIGuid = L3_3
    L2_3.Goal = "Idle"
    L2_3.Priority = "hiPri"
    L1_3(L2_3)
  end
  
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

SetupMPGame = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 1
  L1_2(L2_2, L3_2)
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 2
  L1_2(L2_2, L3_2)
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Remove
  L2_2 = "vz_state_PirCon003_Deliverables"
  L1_2(L2_2)
  L1_2 = bClientwasIn
  if L1_2 then
    L1_2 = MrxLayerManager
    L1_2 = L1_2.Remove
    L2_2 = "vz_state_PirCon003_MP"
    L1_2(L2_2)
  end
  L1_2 = MrxFactionManager
  L1_2 = L1_2.ClearCustomPursuit
  L1_2()
  L1_2 = MrxMusic
  L1_2 = L1_2.StopSpecialMusic
  L2_2 = "none"
  L1_2(L2_2)
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  if A1_2 == 0 then
    L2_2 = {}
    L3_2 = {}
    L4_2 = "Driving"
    L5_2 = {}
    L6_2 = {}
    L7_2 = "Car"
    L8_2 = "M151 .50Cal (VZ) (DriverGunner)"
    L9_2 = 1
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L5_2[1] = L6_2
    L6_2 = {}
    L7_2 = {}
    L8_2 = "Car"
    L9_2 = 3
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L6_2[1] = L7_2
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L4_2 = {}
    L5_2 = "Stopped"
    L6_2 = {}
    L7_2 = {}
    L8_2 = "Car"
    L9_2 = "M151 .50Cal (VZ) (DriverGunner)"
    L10_2 = 1
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L6_2[1] = L7_2
    L7_2 = {}
    L8_2 = {}
    L9_2 = "Car"
    L10_2 = 3
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L7_2[1] = L8_2
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L4_2[3] = L7_2
    L5_2 = {}
    L6_2 = "Offroad"
    L7_2 = {}
    L8_2 = {}
    L9_2 = "Car"
    L10_2 = "M151 .50Cal (VZ) (DriverGunner)"
    L11_2 = 1
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L7_2[1] = L8_2
    L8_2 = {}
    L9_2 = {}
    L10_2 = "Car"
    L11_2 = 2
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L8_2[1] = L9_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L6_2 = {}
    L7_2 = "Heli"
    L8_2 = {}
    L9_2 = {}
    L10_2 = "Car"
    L11_2 = "M113 (VZ) (DriverGunner)"
    L12_2 = 1
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L8_2[1] = L9_2
    L9_2 = {}
    L10_2 = {}
    L11_2 = "Car"
    L12_2 = 2
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L9_2[1] = L10_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
    L2_2[4] = L6_2
    tPursuitTable = L2_2
  elseif A1_2 == 1 then
    L2_2 = {}
    L3_2 = {}
    L4_2 = "Driving"
    L5_2 = {}
    L6_2 = {}
    L7_2 = "Car"
    L8_2 = "M151 .50Cal (VZ) (DriverGunner)"
    L9_2 = 1
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L7_2 = {}
    L8_2 = "Car"
    L9_2 = "M35 (Guntruck) (VZ) (Full)"
    L10_2 = 1
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L6_2 = {}
    L7_2 = {}
    L8_2 = "Car"
    L9_2 = 5
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L6_2[1] = L7_2
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L4_2 = {}
    L5_2 = "Stopped"
    L6_2 = {}
    L7_2 = {}
    L8_2 = "Car"
    L9_2 = "M151 .50Cal (VZ) (DriverGunner)"
    L10_2 = 1
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L6_2[1] = L7_2
    L7_2 = {}
    L8_2 = {}
    L9_2 = "Car"
    L10_2 = 3
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L7_2[1] = L8_2
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L4_2[3] = L7_2
    L5_2 = {}
    L6_2 = "Offroad"
    L7_2 = {}
    L8_2 = {}
    L9_2 = "Car"
    L10_2 = "M151 .50Cal (VZ) (DriverGunner)"
    L11_2 = 1
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L7_2[1] = L8_2
    L8_2 = {}
    L9_2 = {}
    L10_2 = "Car"
    L11_2 = 2
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L8_2[1] = L9_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L6_2 = {}
    L7_2 = "Heli"
    L8_2 = {}
    L9_2 = {}
    L10_2 = "Heli"
    L11_2 = "Alouette3 Superiority (Driver)"
    L12_2 = 1
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L8_2[1] = L9_2
    L9_2 = {}
    L10_2 = {}
    L11_2 = "Heli"
    L12_2 = 1
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L9_2[1] = L10_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
    L2_2[4] = L6_2
    tPursuitTable = L2_2
  elseif A1_2 == 2 then
    L2_2 = {}
    L3_2 = {}
    L4_2 = "Driving"
    L5_2 = {}
    L6_2 = {}
    L7_2 = "Car"
    L8_2 = "M151 .50Cal (VZ) (DriverGunner)"
    L9_2 = 1
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L7_2 = {}
    L8_2 = "Car"
    L9_2 = "M35 (Guntruck) (VZ) (Full)"
    L10_2 = 1
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L8_2 = {}
    L9_2 = "Heli"
    L10_2 = "Alouette3 Attack (VZ) (Driver)"
    L11_2 = 1
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L6_2 = {}
    L7_2 = {}
    L8_2 = "Car"
    L9_2 = 4
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L8_2 = {}
    L9_2 = "Heli"
    L10_2 = 1
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L4_2 = {}
    L5_2 = "Stopped"
    L6_2 = {}
    L7_2 = {}
    L8_2 = "Car"
    L9_2 = "M151 .50Cal (VZ) (DriverGunner)"
    L10_2 = 1
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L8_2 = {}
    L9_2 = "Heli"
    L10_2 = "Alouette3 Attack (VZ) (Driver)"
    L11_2 = 1
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L7_2 = {}
    L8_2 = {}
    L9_2 = "Car"
    L10_2 = 3
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L9_2 = {}
    L10_2 = "Heli"
    L11_2 = 1
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L4_2[3] = L7_2
    L5_2 = {}
    L6_2 = "Offroad"
    L7_2 = {}
    L8_2 = {}
    L9_2 = "Car"
    L10_2 = "M151 .50Cal (VZ) (DriverGunner)"
    L11_2 = 1
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L7_2[1] = L8_2
    L8_2 = {}
    L9_2 = {}
    L10_2 = "Car"
    L11_2 = 2
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L8_2[1] = L9_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L6_2 = {}
    L7_2 = "Heli"
    L8_2 = {}
    L9_2 = {}
    L10_2 = "Heli"
    L11_2 = "Alouette3 Superiority (Driver)"
    L12_2 = 1
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L8_2[1] = L9_2
    L9_2 = {}
    L10_2 = {}
    L11_2 = "Heli"
    L12_2 = 2
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L9_2[1] = L10_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
    L2_2[4] = L6_2
    tPursuitTable = L2_2
  end
  L2_2 = MrxFactionManager
  L2_2 = L2_2.SetCustomPursuit
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "VZ"
  L3_2 = L3_2(L4_2)
  L4_2 = -1
  L5_2 = tPursuitTable
  L2_2(L3_2, L4_2, L5_2)
end

DaCustomPursuit = L0_1
