local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSubtitle"
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
  nPlayedVO1 = L1_2
  L1_2 = 0
  nPlayedVO2 = L1_2
  L1_2 = 0
  nPlayedVO3 = L1_2
  L1_2 = 0
  nPlayedVO4 = L1_2
  L1_2 = 24
  nGoods = L1_2
  L1_2 = 24
  nGoods1 = L1_2
  L1_2 = 24
  nGoodCopy = L1_2
  L1_2 = false
  bClientwasIn = L1_2
  L1_2 = 0
  nGoods2 = L1_2
  L1_2 = 950
  nCargoValue = L1_2
  L1_2 = 0
  nGoodsDelivered = L1_2
  L1_2 = 5
  nRequired = L1_2
  L1_2 = {}
  L2_2 = "JugPickup_1"
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
    L2_2 = 16
    nRequired = L2_2
    L2_2 = nRequired
    L3_2 = nCargoValue
    L2_2 = L2_2 * L3_2
    nRequiredCash = L2_2
    L2_2 = {}
    L3_2 = "Fiona-In-Mission-MinorContract-Pir02-23"
    L4_2 = 2
    L5_2 = "Fiona-In-Mission-MinorContract-Pir02-24"
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
    tStartTalk = L2_2
  elseif L1_2 == 1 then
    L2_2 = 9
    nRequired = L2_2
    L2_2 = nRequired
    L3_2 = nCargoValue
    L2_2 = L2_2 * L3_2
    nRequiredCash = L2_2
    L2_2 = {}
    L3_2 = "Fiona-In-Mission-MinorContract-Pir02-22"
    L4_2 = 2
    L5_2 = "Fiona-In-Mission-MinorContract-Pir02-25"
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
    tStartTalk = L2_2
  else
    L2_2 = 5
    nRequired = L2_2
    L2_2 = nRequired
    L3_2 = nCargoValue
    L2_2 = L2_2 * L3_2
    nRequiredCash = L2_2
    L2_2 = {}
    L3_2 = "Fiona-Banter-MinorContract-Pir03-01"
    L4_2 = 0.2
    L5_2 = {}
    L5_2.mattias = "mattias-Banter-MinorContract-Pir03-02"
    L5_2.jennifer = "jennifer-Banter-MinorContract-Pir03-03"
    L5_2.chris = "chris-Banter-MinorContract-Pir03-04"
    L6_2 = "Fiona-Banter-MinorContract-Pir03-05"
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
    L2_2[4] = L6_2
    tStartTalk = L2_2
  end
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = "PirCon002: GotoVehicle"
  L4_2.sModuleName = "MrxTaskObjectiveEnterVehicle"
  L5_2 = tPickups
  L4_2.vTgtInclude = L5_2
  L4_2.nQuota = 1
  L5_2 = tStartTalk
  L4_2.vVoSeqOnAdd = L5_2
  L4_2.sDspShortDesc = "[PirCon002.Objectives.001]"
  L5_2 = {}
  L6_2 = {}
  L7_2 = DeliverObjective
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tOnComplete = L5_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
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
    L1_3[1] = L2_3
    L0_3(L1_3)
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._CreateEvent
    L2_3 = Event
    L2_3 = L2_3.TimerRelative
    L3_3 = {}
    L4_3 = 3
    L3_3[1] = L4_3
    L4_3 = A0_2
    L4_3 = L4_3.Cancel
    L5_3 = {}
    L6_3 = A0_2
    L5_3[1] = L6_3
    L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
  end
  
  L4_2.fOnCancel = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  oGotoVehicle = L2_2
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
  L8_2 = "JugPickup_1"
  L7_2 = L7_2(L8_2)
  L8_2 = "<"
  L9_2 = 30
  L10_2 = false
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = StartCheckingCargo
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
  L5_2 = 2
  L4_2[1] = L5_2
  L5_2 = CheckGoodsLost
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

StartCheckingCargo = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = MrxMusic
  L1_2 = L1_2.PlaySpecialMusic
  L2_2 = "mu_mission_pircon002_03"
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetNumCompletions
  L1_2 = L1_2(L2_2)
  if 2 <= L1_2 then
    L2_2 = "[PirCon002.Objectives.hard]"
    sScaleObj = L2_2
    L2_2 = {}
    L3_2 = {}
    L4_2 = "Driving"
    L5_2 = {}
    L6_2 = {}
    L7_2 = "Car"
    L8_2 = "EXT (DriverGunner)"
    L9_2 = 1
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L7_2 = {}
    L8_2 = "Car"
    L9_2 = "Guntruck (OC)(Full)"
    L10_2 = 1
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L8_2 = {}
    L9_2 = "Heli"
    L10_2 = "Coanda Superiority (Driver)"
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
    L9_2 = "EXT (DriverGunner)"
    L10_2 = 1
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L8_2 = {}
    L9_2 = "Heli"
    L10_2 = "Coanda Superiority (Driver)"
    L11_2 = 1
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L7_2 = {}
    L8_2 = {}
    L9_2 = "Car"
    L10_2 = 5
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
    L10_2 = "EXT (DriverGunner)"
    L11_2 = 1
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L9_2 = {}
    L10_2 = "Heli"
    L11_2 = "Coanda Superiority (Driver)"
    L12_2 = 1
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L8_2 = {}
    L9_2 = {}
    L10_2 = "Car"
    L11_2 = 5
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L10_2 = {}
    L11_2 = "Heli"
    L12_2 = 1
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L6_2 = {}
    L7_2 = "Heli"
    L8_2 = {}
    L9_2 = {}
    L10_2 = "Heli"
    L11_2 = "Coanda Superiority (Driver)"
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
    L3_2 = MrxFactionManager
    L3_2 = L3_2.SetCustomPursuit
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "OC"
    L4_2 = L4_2(L5_2)
    L5_2 = -1
    L6_2 = L2_2
    L3_2(L4_2, L5_2, L6_2)
  elseif L1_2 == 1 then
    L2_2 = "[PirCon002.Objectives.med]"
    sScaleObj = L2_2
    L2_2 = {}
    L3_2 = {}
    L4_2 = "Driving"
    L5_2 = {}
    L6_2 = {}
    L7_2 = "Car"
    L8_2 = "EXT (DriverGunner)"
    L9_2 = 1
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L7_2 = {}
    L8_2 = "Car"
    L9_2 = "Guntruck (OC) (Full)"
    L10_2 = 1
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L6_2 = {}
    L7_2 = {}
    L8_2 = "Car"
    L9_2 = 4
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
    L9_2 = "EXT (DriverGunner)"
    L10_2 = 1
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L6_2[1] = L7_2
    L7_2 = {}
    L8_2 = {}
    L9_2 = "Car"
    L10_2 = 5
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
    L10_2 = "EXT (DriverGunner)"
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
    L11_2 = "Coanda Superiority (Driver)"
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
    L3_2 = MrxFactionManager
    L3_2 = L3_2.SetCustomPursuit
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "OC"
    L4_2 = L4_2(L5_2)
    L5_2 = -1
    L6_2 = L2_2
    L3_2(L4_2, L5_2, L6_2)
  else
    L2_2 = "[PirCon002.Objectives.easy]"
    sScaleObj = L2_2
    L2_2 = {}
    L3_2 = {}
    L4_2 = "Driving"
    L5_2 = {}
    L6_2 = {}
    L7_2 = "Car"
    L8_2 = "EXT (DriverGunner)"
    L9_2 = 1
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L5_2[1] = L6_2
    L6_2 = {}
    L7_2 = {}
    L8_2 = "Car"
    L9_2 = 2
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
    L9_2 = "EXT (DriverGunner)"
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
    L10_2 = "EXT (DriverGunner)"
    L11_2 = 1
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L7_2[1] = L8_2
    L8_2 = {}
    L9_2 = {}
    L10_2 = "Car"
    L11_2 = 1
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L8_2[1] = L9_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
    L3_2 = MrxFactionManager
    L3_2 = L3_2.SetCustomPursuit
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "OC"
    L4_2 = L4_2(L5_2)
    L5_2 = -1
    L6_2 = L2_2
    L3_2(L4_2, L5_2, L6_2)
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
  L4_2.sName = "PirCon002: DeliverProps"
  L4_2.sModuleName = "MrxTaskObjectiveDeliver"
  L5_2 = tPickups
  L4_2.vTgtInclude = L5_2
  L4_2.nQuota = 1
  L4_2.vDestLoc = "loc_PirCon002deliver"
  L4_2.fDist = 15
  L4_2.bStop = true
  L4_2.bXZOnly = false
  L5_2 = sScaleObj
  L4_2.sDspShortDesc = L5_2
  
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
    L1_3[1] = L2_3
    L0_3(L1_3)
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._CreateEvent
    L2_3 = Event
    L2_3 = L2_3.TimerRelative
    L3_3 = {}
    L4_3 = 4
    L3_3[1] = L4_3
    L4_3 = A0_2
    L4_3 = L4_3.Cancel
    L5_3 = {}
    L6_3 = A0_2
    L5_3[1] = L6_3
    L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
  end
  
  L4_2.fOnCancel = L5_2
  L2_2(L3_2, L4_2)
  L2_2 = MrxVoSequence
  L2_2 = L2_2.Start
  L3_2 = {}
  L4_2 = "Fiona-In-Mission-MinorContract-Pir02-21"
  L5_2 = "Fiona-In-Mission-MinorContract-Pir03-01"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L2_2(L3_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "JugPickup_1"
  L6_2 = L6_2(L7_2)
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "loc_PirCon002deliver"
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
  L6_2 = L6_2.ClearPursuitLock
  L7_2 = {}
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "JugPickup_1"
  L6_2 = L6_2(L7_2)
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "loc_PirCon002deliver"
  L7_2 = L7_2(L8_2)
  L8_2 = "<"
  L9_2 = 120
  L10_2 = false
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = MrxMusic
  L6_2 = L6_2.StopSpecialMusic
  L7_2 = {}
  L8_2 = "none"
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

DeliverObjective = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = nGoods
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "JugPickup_1"
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
      L5_2 = 45
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
          L3_3 = 45
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
              L9_3 = "RumJug"
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
    L4_2 = "JugPickup_2"
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
            L3_3 = 45
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
                L9_3 = "RumJug"
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
    L3_2 = DisplayGoodsLost
    L4_2 = A0_2
    L3_2(L4_2)
  end
end

CheckGoodsLost = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = math
  L2_2 = L2_2.randi
  L3_2 = table
  L3_2 = L3_2.getn
  L4_2 = A1_2
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L4_2 = A0_2
  L3_2 = A0_2._PlayVo
  L5_2 = 0
  L6_2 = A1_2[L2_2]
  L3_2(L4_2, L5_2, L6_2)
end

_PlayRandomVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
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
  L1_2 = nGoods
  L2_2 = nRequired
  if L1_2 < L2_2 then
    L1_2 = nPlayedVO4
    if L1_2 == 0 then
      L2_2 = A0_2
      L1_2 = A0_2._SetCancelMessage
      L3_2 = "[PirCon002.Terms.Cancel01]"
      L1_2(L2_2, L3_2)
      L1_2 = MrxMusic
      L1_2 = L1_2.StopSpecialMusic
      L2_2 = "none"
      L1_2(L2_2)
      L1_2 = {}
      L2_2 = "Fiona-In-Mission-MinorContract-Pir02-28"
      L3_2 = "Fiona-In-Mission-MinorContract-Pir02-29"
      L4_2 = "Fiona-In-Mission-MinorContract-Pir02-30"
      L1_2[1] = L2_2
      L1_2[2] = L3_2
      L1_2[3] = L4_2
      L2_2 = MrxUtil
      L2_2 = L2_2.GetRandomTableElement
      L3_2 = L1_2
      L2_2 = L2_2(L3_2)
      L3_2 = {}
      L4_2 = L2_2
      L5_2 = {}
      L6_2 = A0_2.Cancel
      L7_2 = {}
      L8_2 = A0_2
      L7_2[1] = L8_2
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      L3_2[1] = L4_2
      L3_2[2] = L5_2
      L4_2 = MrxVoSequence
      L4_2 = L4_2.Start
      L5_2 = L3_2
      L4_2(L5_2)
      L4_2 = 1
      nPlayedVO4 = L4_2
    end
  else
    L1_2 = nGoods
    if L1_2 == 18 then
      L1_2 = nPlayedVO1
      if L1_2 == 0 then
        L1_2 = MrxVoSequence
        L1_2 = L1_2.Start
        L2_2 = {}
        L3_2 = "Fiona-In-Mission-MinorContract-Pir02-10"
        L2_2[1] = L3_2
        L1_2(L2_2)
        L1_2 = 1
        nPlayedVO1 = L1_2
      end
    else
      L1_2 = nGoods
      if L1_2 == 11 then
        L1_2 = nPlayedVO2
        if L1_2 == 0 then
          L1_2 = MrxVoSequence
          L1_2 = L1_2.Start
          L2_2 = {}
          L3_2 = "Fiona-In-Mission-MinorContract-Pir02-11"
          L2_2[1] = L3_2
          L1_2(L2_2)
          L1_2 = 1
          nPlayedVO2 = L1_2
        end
      else
        L1_2 = nGoods
        if L1_2 == 6 then
          L1_2 = nPlayedVO3
          if L1_2 == 0 then
            L1_2 = MrxVoSequence
            L1_2 = L1_2.Start
            L2_2 = {}
            L3_2 = "Fiona-In-Mission-MinorContract-Pir02-02"
            L2_2[1] = L3_2
            L1_2(L2_2)
            L1_2 = 1
            nPlayedVO3 = L1_2
          end
        end
      end
    end
  end
end

DisplayGoodsLost = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "PirCon002 MP End"
  L3_2.sModuleName = "MrxTaskObjectiveAction"
  L3_2.vTgtInclude = "PirCon002_endTalk"
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
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L1_2 = MrxMusic
  L1_2 = L1_2.StopSpecialMusic
  L2_2 = "none"
  L1_2(L2_2)
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "loc_PirCon002deliver"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L2_2(L3_2)
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetObjectsInArea
  L6_2 = L1_2
  L7_2 = L2_2
  L8_2 = L3_2
  L9_2 = 25
  L10_2 = "RumJug"
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L6_2 = table
  L6_2 = L6_2.getn
  L7_2 = L5_2
  L6_2 = L6_2(L7_2)
  L7_2 = nCargoValue
  L7_2 = L6_2 * L7_2
  if L6_2 == 24 then
    L8_2 = bClientwasIn
    if not L8_2 then
      L9_2 = A0_2
      L8_2 = A0_2._SetPlayer1Bonus
      L10_2 = 2000000 + L7_2
      L8_2(L9_2, L10_2)
  end
  else
    if L6_2 == 48 then
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
    L10_2 = "PirThug(female)-In-Mission-MinorContract-Pir02-19"
    L11_2 = "Fiona-In-Mission-MinorContract-Pir03-04"
    L12_2 = "PirThug(female)-In-Mission-MinorContract-Pir02-18"
    L13_2 = {}
    L14_2 = A0_2.Complete
    L15_2 = {}
    L16_2 = A0_2
    L15_2[1] = L16_2
    L13_2[1] = L14_2
    L13_2[2] = L15_2
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L9_2[4] = L13_2
    L8_2(L9_2)
  else
    L9_2 = A0_2
    L8_2 = A0_2._SetCancelMessage
    L10_2 = "[PirCon002.Terms.Cancel01]"
    L8_2(L9_2, L10_2)
    L8_2 = MrxVoSequence
    L8_2 = L8_2.Start
    L9_2 = {}
    L10_2 = "PirThug-In-Mission-MinorContract-Pir02-07"
    L11_2 = {}
    L12_2 = A0_2.Cancel
    L13_2 = {}
    L14_2 = A0_2
    L13_2[1] = L14_2
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L8_2(L9_2)
  end
end

CountDelivered = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = {}
  L2_2 = "vz_State_PirCon002_MP"
  L1_2[1] = L2_2
  tLayersToAdd = L1_2
  L1_2 = MrxLayerManager
  L1_2 = L1_2.Add
  L2_2 = tLayersToAdd
  L1_2(L2_2)
  L1_2 = {}
  L2_2 = "JugPickup_1"
  L3_2 = "JugPickup_2"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  tPickups = L1_2
  L1_2 = true
  bClientwasIn = L1_2
  L1_2 = 24
  nGoods2 = L1_2
  L1_2 = 48
  nGoodCopy = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "PirCon002_endTalk"
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
  L6_2 = "PirCon002_endTalk"
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
    L4_3 = "PirCon002_endTalk"
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
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2.GetNumCompletions
  L1_2 = L1_2(L2_2)
  L2_2 = Hud
  L2_2 = L2_2.ObjectiveTray
  L3_2 = L2_2
  L2_2 = L2_2.ClearSlot
  L4_2 = {}
  L4_2.vPlayer = nil
  L4_2.nSlot = 2
  L2_2(L3_2, L4_2)
  L2_2 = Hud
  L2_2 = L2_2.ObjectiveTray
  L3_2 = L2_2
  L2_2 = L2_2.ClearSlot
  L4_2 = {}
  L4_2.vPlayer = nil
  L4_2.nSlot = 1
  L2_2(L3_2, L4_2)
  L2_2 = MrxLayerManager
  L2_2 = L2_2.Remove
  L3_2 = "vz_State_PirCon002_Deliverables"
  L2_2(L3_2)
  L2_2 = bClientwasIn
  if L2_2 then
    L2_2 = MrxLayerManager
    L2_2 = L2_2.Remove
    L3_2 = "vz_state_PirCon002_MP"
    L2_2(L3_2)
  end
  L2_2 = MrxFactionManager
  L2_2 = L2_2.ClearCustomPursuit
  L2_2()
  L2_2 = MrxMusic
  L2_2 = L2_2.StopSpecialMusic
  L3_2 = "none"
  L2_2(L3_2)
  L2_2 = MrxTaskContract
  L2_2 = L2_2.Cleanup
  L3_2 = A0_2
  L2_2(L3_2)
end

Cleanup = L0_1
