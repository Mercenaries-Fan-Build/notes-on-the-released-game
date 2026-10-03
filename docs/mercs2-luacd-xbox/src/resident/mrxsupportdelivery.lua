local L0_1, L1_1, L2_1, L3_1, L4_1
L0_1 = inherit
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorSmoke"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = "UH1 Transport (PMC) (Driver)"
sDeliveryVehicle = L0_1
L0_1 = "box"
sCargoToDeliver = L0_1
L0_1 = Pg
L0_1 = L0_1.GetGuidByName
L1_1 = sCargoToDeliver
L0_1 = L0_1(L1_1)
uCargoToDeliver = L0_1
L0_1 = 0.5
nCargoDropHeight = L0_1
L0_1 = 250
nAltitude = L0_1
L0_1 = {}
L1_1 = "Ewan-None-Freeplay-Support-73"
L2_1 = "Ewan-None-Freeplay-Support-10"
L3_1 = "Ewan-None-Freeplay-Support-91"
L4_1 = "Ewan-None-Freeplay-Support-90"
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = {}
  L3_2 = setmetatable
  L4_2 = L2_2
  L5_2 = A0_2
  L3_2(L4_2, L5_2)
  A0_2.__index = A0_2
  L3_2 = A0_2.bCareless
  L2_2.bCareless = L3_2
  L3_2 = A0_2.oTarget
  L2_2.oTarget = L3_2
  L3_2 = A0_2.sDeliveryVehicle
  L2_2.sDeliveryVehicle = L3_2
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = A0_2.sDeliveryVehicle
  L3_2 = L3_2(L4_2)
  L2_2.uDeliveryVehicle = L3_2
  L3_2 = A0_2.sFinalDestination
  L2_2.sFinalDestination = L3_2
  L3_2 = A0_2.sCargoToDeliver
  L2_2.sCargoToDeliver = L3_2
  L3_2 = A0_2.uCargoToDeliver
  L2_2.uCargoToDeliver = L3_2
  L3_2 = A0_2.nCargoDropHeight
  L2_2.nCargoDropHeight = L3_2
  L2_2.bNeedsConnection = false
  L2_2.oUpdateEvent = nil
  L3_2 = MrxSupportDesignatorSmoke
  L4_2 = L3_2
  L3_2 = L3_2.Create
  L3_2 = L3_2(L4_2)
  oDesignator = L3_2
  L4_2 = L2_2
  L3_2 = L2_2.SetDesignator
  L5_2 = oDesignator
  L3_2(L4_2, L5_2)
  L3_2 = oDesignator
  L4_2 = L3_2
  L3_2 = L3_2.SetSmokeColor
  L5_2 = "blue"
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetOwner
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetRecruit
  L5_2 = "Copter"
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetModuleName
  L5_2 = "MrxSupportDelivery"
  L3_2(L4_2, L5_2)
  return L2_2
end

Create = L1_1

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _DesignatorCallback
  L2_2 = A0_2
  L1_2(L2_2)
end

DesignationCallback = L1_1

function L1_1(A0_2, A1_2)
  A0_2.uCargoToDeliver = A1_2
  A0_2.bSetCargoGuidCalled = true
end

SetCargoGuid = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  A0_2.sCargoToDeliver = A1_2
  L2_2 = PickCargo
  L3_2 = A0_2
  L4_2 = A0_2.sCargoToDeliver
  L2_2(L3_2, L4_2)
end

SetCargo = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  if not A1_2 then
    return
  end
  L2_2 = nil
  L3_2 = type
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if L3_2 == "table" then
    L3_2 = MrxUtil
    L3_2 = L3_2.GetRandomTableElement
    L4_2 = A1_2
    L3_2 = L3_2(L4_2)
    L2_2 = L3_2
  else
    L2_2 = A1_2
  end
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  A0_2.uCargoToDeliver = L3_2
end

PickCargo = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" ~= L2_2 then
    return
  end
  A0_2.bCareless = A1_2
end

SetCareless = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" ~= L2_2 then
    return
  end
  A0_2.oFinalDestination = A1_2
end

SetFinalDestination = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" ~= L2_2 then
    return
  end
  L2_2 = type
  L3_2 = nCargoDropHeight
  L2_2 = L2_2(L3_2)
  if "number" ~= L2_2 then
    return
  end
  L2_2 = nCargoDropHeight
  A0_2.nCargoDropHeight = L2_2
end

SetCargoDropHeight = L1_1
L1_1 = 0
_nHelicopterNumber = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2
  L1_2 = Net
  L1_2 = L1_2.IsClient
  L1_2 = L1_2()
  if L1_2 then
    return
  end
  L1_2 = A0_2.bSetCargoGuidCalled
  if not L1_2 then
    L1_2 = PickCargo
    L2_2 = A0_2
    L3_2 = A0_2.sCargoToDeliver
    L1_2(L2_2, L3_2)
  end
  L1_2 = Object
  L1_2 = L1_2.GetHibernationDistance
  L2_2 = A0_2.uCargoToDeliver
  L1_2 = L1_2(L2_2)
  L1_2 = -L1_2
  if not L1_2 then
    L1_2 = -155
  end
  L2_2 = Math
  L2_2 = L2_2.max
  L3_2 = L1_2 + 5
  L4_2 = -150
  L2_2 = L2_2(L3_2, L4_2)
  L1_2 = L2_2
  L2_2 = Pg
  L2_2 = L2_2.SpawnFromCamera
  L3_2 = A0_2.uCargoToDeliver
  L4_2 = L1_2
  L5_2 = 1
  L6_2 = true
  L7_2 = Player
  L7_2 = L7_2.GetLocalPlayer
  L7_2 = L7_2()
  L8_2 = false
  L9_2 = true
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  if not L2_2 then
    return
  end
  L3_2 = A0_2.oDesignator
  L4_2 = L3_2
  L3_2 = L3_2.GetTarget
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  L6_2 = Pg
  L6_2 = L6_2.FindPointFromCamera
  L7_2 = L1_2
  L8_2 = MrxSupport
  L8_2 = L8_2.GetSpawnHeight
  L8_2 = L8_2()
  L9_2 = 30
  L10_2 = A0_2.uOwner
  L11_2 = math
  L11_2 = L11_2.randi
  L12_2 = 120
  L11_2 = L11_2(L12_2)
  L11_2 = 300 + L11_2
  L6_2, L7_2, L8_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  if L4_2 then
    L9_2 = MrxSupport
    L9_2 = L9_2.GetSpawnHeight
    L9_2 = L9_2()
    L9_2 = L4_2 + L9_2
    if L7_2 < L9_2 then
      L9_2 = MrxSupport
      L9_2 = L9_2.GetSpawnHeight
      L9_2 = L9_2()
      L7_2 = L4_2 + L9_2
    end
  end
  L9_2 = Pg
  L9_2 = L9_2.Spawn
  L10_2 = A0_2.uDeliveryVehicle
  L11_2 = L6_2
  L12_2 = L7_2
  L13_2 = L8_2
  L14_2 = 0
  L15_2 = false
  L16_2 = true
  L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
  A0_2.uHeli = L9_2
  if not L9_2 then
    L10_2 = Object
    L10_2 = L10_2.Remove
    L11_2 = L2_2
    L10_2(L11_2)
    return
  end
  L10_2 = Object
  L10_2 = L10_2.GetPosition
  L11_2 = L9_2
  L10_2, L11_2, L12_2 = L10_2(L11_2)
  L13_2 = A0_2.oDesignator
  L14_2 = L13_2
  L13_2 = L13_2.GetTarget
  L13_2, L14_2, L15_2 = L13_2(L14_2)
  L16_2 = Math
  L16_2 = L16_2.GetXZHeading
  L17_2 = L13_2 - L10_2
  L18_2 = L14_2 - L11_2
  L19_2 = L15_2 - L12_2
  L16_2 = L16_2(L17_2, L18_2, L19_2)
  L17_2 = Object
  L17_2 = L17_2.SetYaw
  L18_2 = L9_2
  L19_2 = L16_2
  L17_2(L18_2, L19_2)
  L17_2 = Event
  L17_2 = L17_2.Create
  L18_2 = Event
  L18_2 = L18_2.ObjectHibernation
  L19_2 = {}
  L20_2 = L9_2
  L21_2 = "awake"
  L19_2[1] = L20_2
  L19_2[2] = L21_2
  L20_2 = _DeployWinch
  L21_2 = {}
  L22_2 = A0_2
  L23_2 = L9_2
  L24_2 = L2_2
  L21_2[1] = L22_2
  L21_2[2] = L23_2
  L21_2[3] = L24_2
  L17_2(L18_2, L19_2, L20_2, L21_2)
end

_DesignatorCallback = L1_1

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L3_2 = {}
  L4_2 = {}
  L5_2 = "Ewan-None-Freeplay-Support-10"
  L6_2 = "Ewan-None-Freeplay-Support-73"
  L7_2 = "Ewan-None-Freeplay-Support-89"
  L8_2 = "Ewan-None-Freeplay-Support-91"
  L9_2 = "Ewan-None-Freeplay-Support-99"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L3_2.PMC = L4_2
  L4_2 = {}
  L5_2 = "AlliedSoldier01.Support.Incoming02"
  L6_2 = "AlliedSoldier01.Support.Incoming03"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L3_2.Allied = L4_2
  L4_2 = {}
  L5_2 = "ChinaSoldier01.Support.Incoming01"
  L6_2 = "ChinaSoldier01.Support.Incoming02"
  L7_2 = "ChinaSoldier01.Support.Incoming03"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L3_2.China = L4_2
  L4_2 = {}
  L5_2 = "VZSoldier01.Support.Air01"
  L4_2[1] = L5_2
  L3_2.VZ = L4_2
  L4_2 = {}
  L5_2 = "GurSoldier01.Support.Incoming01"
  L6_2 = "GurSoldier01.Support.Incoming02"
  L7_2 = "GurSoldier01.Support.Incoming03"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L3_2.Guerilla = L4_2
  L4_2 = {}
  L5_2 = "OCSoldier01.Support.Incoming01"
  L6_2 = "OCSoldier01.Support.Incoming02"
  L7_2 = "OCSoldier01.Support.Incoming03"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L3_2.OC = L4_2
  L0_1 = L3_2
  L3_2 = MrxUtil
  L3_2 = L3_2.GetFaction
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L4_2 = L0_1
    L4_2 = L4_2[L3_2]
    if L4_2 then
      L4_2 = MrxSupport
      L4_2 = L4_2.PlayRandomVOCue
      L5_2 = L0_1
      L5_2 = L5_2[L3_2]
      L4_2(L5_2)
    else
    end
  end
  L4_2 = Object
  L4_2 = L4_2.SetWinchState
  L5_2 = A1_2
  L6_2 = "deployed"
  L4_2(L5_2, L6_2)
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = 0.1
  L6_2[1] = L7_2
  L7_2 = Event
  L7_2 = L7_2.Create
  L8_2 = {}
  L9_2 = Event
  L9_2 = L9_2.ObjectHibernation
  L10_2 = {}
  L11_2 = A2_2
  L12_2 = "awake"
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L11_2 = _WaitCallback
  L12_2 = {}
  L13_2 = A0_2
  L14_2 = A1_2
  L15_2 = A2_2
  L12_2[1] = L13_2
  L12_2[2] = L14_2
  L12_2[3] = L15_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
end

_DeployWinch = L1_1

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L3_2 = A0_2.oDesignator
  L4_2 = L3_2
  L3_2 = L3_2.GetTarget
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  L6_2 = Vehicle
  L6_2 = L6_2.GetDriver
  L7_2 = A1_2
  L6_2 = L6_2(L7_2)
  L7_2 = MrxSupport
  L7_2 = L7_2.SetupDamageEvent
  L8_2 = A0_2
  L9_2 = A1_2
  L10_2 = false
  L7_2(L8_2, L9_2, L10_2)
  L7_2 = Object
  L7_2 = L7_2.SetYaw
  L8_2 = A2_2
  L9_2 = Object
  L9_2 = L9_2.GetYaw
  L10_2 = A1_2
  L9_2, L10_2, L11_2, L12_2, L13_2, L14_2 = L9_2(L10_2)
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L7_2 = Object
  L7_2 = L7_2.AttachCargoToWinch
  L8_2 = A2_2
  L9_2 = A1_2
  L7_2(L8_2, L9_2)
  L7_2 = Object
  L7_2 = L7_2.AddToDisposer
  L8_2 = A2_2
  L9_2 = "vehicle"
  L7_2(L8_2, L9_2)
  L7_2 = Ai
  L7_2 = L7_2.Deliver
  L8_2 = Vehicle
  L8_2 = L8_2.GetDriver
  L9_2 = A1_2
  L8_2 = L8_2(L9_2)
  L9_2 = L3_2
  L10_2 = L4_2
  L11_2 = L5_2
  L12_2 = A0_2.nCargoDropHeight
  L13_2 = A0_2.bCareless
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L7_2 = Event
  L7_2 = L7_2.Create
  L8_2 = Event
  L8_2 = L8_2.ObjectWinched
  L9_2 = {}
  L10_2 = A2_2
  L11_2 = A1_2
  L12_2 = "Detach"
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L9_2[3] = L12_2
  L10_2 = CargoDropped
  L11_2 = {}
  L12_2 = A0_2
  L13_2 = A1_2
  L14_2 = A2_2
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L11_2[3] = L14_2
  L7_2(L8_2, L9_2, L10_2, L11_2)
  L7_2 = Object
  L7_2 = L7_2.AddLabel
  L8_2 = A1_2
  L9_2 = "Disposable"
  L7_2(L8_2, L9_2)
end

_WaitCallback = L1_1

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  L3_2 = MrxSupport
  L3_2 = L3_2.GoHome
  L4_2 = A0_2
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
  L3_2 = Object
  L3_2 = L3_2.AddToDisposer
  L4_2 = A2_2
  L5_2 = "vehicle"
  L3_2(L4_2, L5_2)
end

CargoDropped = L1_1
