local L0_1, L1_1, L2_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxTaskObjectiveEnterVehicle"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxUtil"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxTimer"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "DlcSpeedTimer"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "DlcVehicleStrike"
L2_1 = false
L0_1(L1_1, L2_1)

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = {}
  L2_2 = {}
  L3_2 = "monster truck"
  L4_2 = 80
  L5_2 = 10
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L3_2 = {}
  L4_2 = "escort"
  L5_2 = 50
  L6_2 = 20
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L4_2 = {}
  L5_2 = "Buggy (Hellfire)"
  L6_2 = 80
  L7_2 = 10
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L2_2 = L1_2[1]
  L3_2 = Pg
  L3_2 = L3_2.SpawnFromCamera
  L4_2 = L2_2[1]
  L5_2 = 20
  L3_2 = L3_2(L4_2, L5_2)
  A0_2.uCar = L3_2
  L5_2 = A0_2
  L4_2 = A0_2.CreateChild
  L6_2 = {}
  L6_2.sName = "Enter car"
  L6_2.sModuleName = "MrxTaskObjectiveEnterVehicle"
  L6_2.sDspShortDesc = "[MecCon001.Objectives.enterVehicle]"
  L6_2.vTgtInclude = L3_2
  L6_2.nQuota = 1
  
  function L7_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.CreateTimer
    L2_3 = 45
    L0_3(L1_3, L2_3)
    L0_3 = A0_2
    L1_3 = DlcSpeedTimer
    L1_3 = L1_3.Start
    L2_3 = L3_2
    L3_3 = L2_2
    L3_3 = L3_3[2]
    L4_3 = L2_2
    L4_3 = L4_3[3]
    L1_3 = L1_3(L2_3, L3_3, L4_3)
    L0_3.tSpeedTimer = L1_3
  end
  
  L6_2.fOnComplete = L7_2
  L4_2(L5_2, L6_2)
  L4_2 = A0_2._tEvents
  L5_2 = Event
  L5_2 = L5_2.Create
  L6_2 = Event
  L6_2 = L6_2.ObjectDeath
  L7_2 = {}
  L8_2 = L3_2
  L7_2[1] = L8_2
  L8_2 = MrxTaskContract
  L8_2 = L8_2.Cancel
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L4_2.eCarDeath = L5_2
  L4_2 = TestStrike
  L4_2()
end

Activated = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = Pg
  L0_2 = L0_2.SpawnFromCamera
  L1_2 = "amx30"
  L2_2 = 60
  L0_2(L1_2, L2_2)
  L0_2 = Pg
  L0_2 = L0_2.SpawnFromCamera
  L1_2 = "amx30"
  L2_2 = 40
  L0_2(L1_2, L2_2)
  L0_2 = Pg
  L0_2 = L0_2.SpawnFromCamera
  L1_2 = "rtr"
  L0_2(L1_2)
  L0_2 = DlcVehicleStrike
  L0_2 = L0_2.CreateTankSupport
  L0_2()
  L0_2 = DlcVehicleStrike
  L1_2 = L0_2
  L0_2 = L0_2.Create
  L0_2 = L0_2(L1_2)
  a = L0_2
  L0_2 = a
  L1_2 = L0_2
  L0_2 = L0_2.AddStrike
  L0_2(L1_2)
  L0_2 = _G
  L1_2 = a
  L0_2.a = L1_2
end

TestStrike = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = A0_2.tSpeedTimer
  if L1_2 then
    L1_2 = DlcSpeedTimer
    L1_2 = L1_2.Cleanup
    L2_2 = A0_2.tSpeedTimer
    L1_2(L2_2)
    A0_2.tSpeedTimer = nil
  end
  L1_2 = A0_2.uTimer
  if L1_2 then
    L1_2 = A0_2.uTimer
    L2_2 = L1_2
    L1_2 = L1_2.Stop
    L1_2(L2_2)
  end
  L1_2 = Object
  L1_2 = L1_2.IsAlive
  L2_2 = A0_2.uCar
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = Vehicle
    L1_2 = L1_2.Exit
    L2_2 = A0_2.uCar
    L3_2 = Player
    L3_2 = L3_2.GetLocalCharacter
    L3_2 = L3_2()
    L4_2 = true
    L1_2(L2_2, L3_2, L4_2)
    L1_2 = Object
    L1_2 = L1_2.Remove
    L2_2 = A0_2.uCar
    L1_2(L2_2)
  end
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = MrxTimer
  L3_2 = L2_2
  L2_2 = L2_2.Create
  L4_2 = {}
  L4_2.nStartTime = A1_2
  L4_2.nStep = 1
  L4_2.bUseTenths = false
  L4_2.nWarning = 0
  L4_2.iTray = 1
  L4_2.bPlaySounds = false
  L5_2 = {}
  L6_2 = {}
  L7_2 = MrxTaskContract
  L7_2 = L7_2.Complete
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2[1] = L6_2
  L4_2.tDoneCallbacks = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  A0_2.uTimer = L2_2
  L2_2 = A0_2.uTimer
  L3_2 = L2_2
  L2_2 = L2_2.Start
  L2_2(L3_2)
end

CreateTimer = L0_1
