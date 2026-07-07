local L0_1, L1_1, L2_1
L0_1 = import
L1_1 = "MrxPmc"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxTankBuster"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxSupportData"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxGuiInterface"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxUtil"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxGuiBase"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = "FreeTankBuster"
ksTankBuster = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = MrxTankBuster
  L1_2 = L0_2
  L0_2 = L0_2.Create
  L0_2 = L0_2(L1_2)
  L1_2 = MrxSupportData
  L1_2 = L1_2.tFreebieData
  L2_2 = ksTankBuster
  L3_2 = {}
  L3_2.sName = "[support.airstrike.tankbuster.name]"
  L3_2.sIcon = "support_tank_buster"
  L3_2.nFreebieQty = 1
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
end

CreateTankSupport = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  if not A1_2 then
    L2_2 = {}
    A1_2 = L2_2
  end
  L2_2 = setmetatable
  L3_2 = A1_2
  L4_2 = {}
  L4_2.__index = A0_2
  L2_2(L3_2, L4_2)
  L2_2 = {}
  A1_2._tEvents = L2_2
  L2_2 = A1_2.uPlayer
  if not L2_2 then
    L2_2 = Player
    L2_2 = L2_2.GetLocalPlayer
    L2_2 = L2_2()
  end
  A1_2.uPlayer = L2_2
  L2_2 = A1_2.sStrikeName
  if not L2_2 then
    L2_2 = ksTankBuster
  end
  A1_2.sStrikeName = L2_2
  L3_2 = A1_2
  L2_2 = A1_2.OnExitVeh
  L4_2 = Player
  L4_2 = L4_2.GetCharacter
  L5_2 = A1_2.uPlayer
  L4_2, L5_2 = L4_2(L5_2)
  L2_2(L3_2, L4_2, L5_2)
  return A1_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = pairs
  L2_2 = A0_2._tEvents
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Event
    L6_2 = L6_2.Delete
    L7_2 = L5_2
    L6_2(L7_2)
  end
  A0_2._tEvents = nil
  L1_2 = MrxSupportData
  L1_2 = L1_2.RemoveFreebie
  L2_2 = A0_2.sStrikeName
  L1_2(L2_2)
end

Cleanup = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = A0_2._tEvents
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.ObjectInSeat
  L6_2 = {}
  L7_2 = A1_2
  L8_2 = A2_2
  L9_2 = "a"
  L10_2 = "x"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L7_2 = OnExitVeh
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L3_2.eVehicleEnter = L4_2
  L3_2 = A0_2._tEvents
  L4_2 = Event
  L4_2 = L4_2.CreatePersistent
  L5_2 = Event
  L5_2 = L5_2.Button
  L6_2 = {}
  L7_2 = Object
  L7_2 = L7_2.IsPlayerControlled
  L8_2 = A1_2
  L7_2 = L7_2(L8_2)
  L8_2 = "lbutton"
  L9_2 = "press"
  L10_2 = true
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L7_2 = OnButtonPress
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L3_2.eButtonPress = L4_2
end

OnEnterVeh = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = A0_2._tEvents
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.ObjectInSeat
  L6_2 = {}
  L7_2 = A1_2
  L8_2 = "Vehicle"
  L9_2 = "a"
  L10_2 = "e"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L7_2 = OnEnterVeh
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L3_2.eVehicleEnter = L4_2
  L3_2 = Event
  L3_2 = L3_2.Delete
  L4_2 = A0_2._tEvents
  L4_2 = L4_2.eButtonPress
  L3_2(L4_2)
  L3_2 = A0_2._tEvents
  L3_2.eButton = nil
end

OnExitVeh = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = MrxGuiBase
  L1_2 = L1_2.GetCurrentControlHolder
  L2_2 = Player
  L2_2 = L2_2.GetLocalPlayer
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L2_2()
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  if L1_2 then
    return
  end
  L1_2 = MrxSupportData
  L1_2 = L1_2.GetFreebie
  L2_2 = A0_2.sStrikeName
  L1_2 = L1_2(L2_2)
  L2_2 = MrxPmc
  L2_2 = L2_2.GetFreebieQty
  L3_2 = L1_2.sName
  L2_2 = L2_2(L3_2)
  L3_2 = type
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if L3_2 == "number" and 0 < L2_2 then
    L3_2 = L1_2.oSupport
    L4_2 = L3_2
    L3_2 = L3_2.GetDenialCondition
    L3_2 = L3_2(L4_2)
    if L3_2 == nil then
      L3_2 = {}
      L4_2 = "Fiona-In-Mission-Contract-Dlc03-08"
      L5_2 = "Fiona-In-Mission-Contract-Dlc03-09"
      L6_2 = "Fiona-In-Mission-Contract-Dlc03-10"
      L7_2 = "Fiona-In-Mission-Contract-Dlc03-11"
      L8_2 = "Fiona-In-Mission-Contract-Dlc03-12"
      L3_2[1] = L4_2
      L3_2[2] = L5_2
      L3_2[3] = L6_2
      L3_2[4] = L7_2
      L3_2[5] = L8_2
      L4_2 = MrxUtil
      L4_2 = L4_2.GetRandomTableElement
      L5_2 = L3_2
      L4_2 = L4_2(L5_2)
      L5_2 = Hud
      L5_2 = L5_2.MessageBox
      L6_2 = L5_2
      L5_2 = L5_2.AddMessage
      L7_2 = {}
      L7_2.sMessage = "[vehicles.dlcCon003_vehicleStrike]"
      L5_2(L6_2, L7_2)
      L5_2 = MrxVoSequence
      L5_2 = L5_2.Start
      L6_2 = {}
      L7_2 = L4_2
      L6_2[1] = L7_2
      L5_2(L6_2)
      L5_2 = MrxPmc
      L5_2 = L5_2.SetFreebieQty
      L6_2 = L1_2.sName
      L7_2 = L2_2 - 1
      L5_2(L6_2, L7_2)
      L5_2 = L1_2.oSupport
      L6_2 = L5_2
      L5_2 = L5_2.DesignationCallback
      L5_2(L6_2)
      L5_2 = MrxTutorialManager
      L5_2 = L5_2.HideMessage
      L6_2 = true
      L5_2(L6_2)
    else
    end
  end
end

OnButtonPress = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = MrxSupportData
  L2_2 = L2_2.GetFreebie
  L3_2 = A0_2.sStrikeName
  L2_2 = L2_2(L3_2)
  if not A1_2 then
    A1_2 = 1
  end
  L3_2 = MrxPmc
  L3_2 = L3_2.GetFreebieQty
  L4_2 = L2_2.sName
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L3_2 = 0
  end
  A1_2 = A1_2 + L3_2
  L4_2 = MrxSupportData
  L4_2 = L4_2.RemoveFreebie
  L5_2 = A0_2.sStrikeName
  L4_2(L5_2)
  L4_2 = MrxSupportData
  L4_2 = L4_2.AddFreebie
  L5_2 = A0_2.sStrikeName
  L6_2 = A1_2
  L7_2 = A0_2.uPlayer
  L4_2(L5_2, L6_2, L7_2)
end

AddStrike = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = 1
  L3_2 = A0_2
  L4_2 = 1
  for L5_2 = L2_2, L3_2, L4_2 do
    L6_2 = Pg
    L6_2 = L6_2.SpawnFromCamera
    L7_2 = "amx30"
    L8_2 = L5_2 * 15
    L8_2 = A1_2 + L8_2
    L6_2(L7_2, L8_2)
  end
end

TestTank = L0_1
