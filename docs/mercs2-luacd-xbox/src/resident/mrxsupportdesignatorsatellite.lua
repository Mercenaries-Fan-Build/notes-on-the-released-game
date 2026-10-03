local L0_1, L1_1
L0_1 = import
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = inherit
L1_1 = "MrxSupportDesignator"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiSatellite"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSound"
L0_1(L1_1)
L0_1 = 170
nStartZoom = L0_1
L0_1 = 170
nMinZoom = L0_1
L0_1 = 170
nMaxZoom = L0_1
L0_1 = 100
nRadius = L0_1
L0_1 = false
tSectors = L0_1
L0_1 = 5000
nCost = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2
  L4_2 = A1_2 or nil
  if not A1_2 then
    L4_2 = A0_2.nMinZoom
  end
  A0_2.nMinZoom = L4_2
  L4_2 = A2_2 or L4_2
  if not A2_2 then
    L4_2 = A0_2.nMaxZoom
  end
  A0_2.nMaxZoom = L4_2
  L4_2 = A3_2 or L4_2
  if not A3_2 then
    L4_2 = A0_2.nStartZoom
  end
  A0_2.nStartZoom = L4_2
end

SetZoomLimits = L0_1

function L0_1(A0_2, A1_2)
  local L2_2
  L2_2 = A1_2 or nil
  if not A1_2 then
    L2_2 = A0_2.nRadius
  end
  A0_2.nRadius = L2_2
end

SetRadius = L0_1

function L0_1(A0_2, A1_2)
  A0_2.tSectors = A1_2
end

SetMinigameSectors = L0_1

function L0_1(A0_2, A1_2)
  A0_2.nCost = A1_2
end

SetCost = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = true
  return L1_2
end

ShouldSuppressIconAnimationOnDirectUse = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  if not A1_2 then
    L2_2 = {}
    A1_2 = L2_2
  end
  L2_2 = A0_2.uOwner
  A1_2.uOwner = L2_2
  L2_2 = A0_2.bDesignationComplete
  A1_2.bDesignationComplete = L2_2
  A1_2.sDesignationType = "Satellite Designator"
  L2_2 = A0_2.fValidationFunction
  A1_2.fValidationFunction = L2_2
  L2_2 = {}
  A1_2.tCallbackList = L2_2
  L2_2 = bil
  A1_2.sAATestLevel = L2_2
  L2_2 = A0_2.nX
  A1_2.nX = L2_2
  L2_2 = A0_2.nY
  A1_2.nY = L2_2
  L2_2 = A0_2.nZ
  A1_2.nZ = L2_2
  L2_2 = A0_2.uGuid
  A1_2.uGuid = L2_2
  L2_2 = A0_2.nStartZoom
  A1_2.nStartZoom = L2_2
  L2_2 = A0_2.nMinZoom
  A1_2.nMinZoom = L2_2
  L2_2 = A0_2.nMaxZoom
  A1_2.nMaxZoom = L2_2
  L2_2 = A0_2.nRadius
  A1_2.nRadius = L2_2
  L2_2 = A0_2.tSectors
  A1_2.tSectors = L2_2
  L2_2 = A0_2.nCost
  A1_2.nCost = L2_2
  L2_2 = setmetatable
  L3_2 = A1_2
  L4_2 = A0_2
  L2_2(L3_2, L4_2)
  A0_2.__index = A0_2
  return A1_2
end

Create = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = type
  L3_2 = A0_2.uOwner
  L2_2 = L2_2(L3_2)
  if "userdata" ~= L2_2 then
    return
  end
  L2_2 = Airstrike
  L2_2 = L2_2.EquipDesignator
  L3_2 = A0_2.uOwner
  L4_2 = A0_2.sDesignationType
  L5_2 = BeginSatelliteDesignation
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L7_2 = A1_2
  return L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

Commence = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = "satellite"
  return L1_2
end

GetType = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = type
  L2_2 = A0_2.uOwner
  L1_2 = L1_2(L2_2)
  if "userdata" ~= L1_2 then
    return
  end
  L1_2 = MrxSound
  L1_2 = L1_2.EnterSatelliteView
  L1_2()
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = Player
  L2_2 = L2_2.GetCharacter
  L3_2 = A0_2.uOwner
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L2_2(L3_2)
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L4_2 = Player
  L4_2 = L4_2.SetPDAMapMode
  L5_2 = A0_2.uOwner
  L6_2 = true
  L7_2 = L1_2
  L8_2 = A0_2.nStartZoom
  L8_2 = L2_2 + L8_2
  L9_2 = L3_2
  L10_2 = A0_2.nRadius
  L11_2 = A0_2.nStartZoom
  L12_2 = A0_2.nMinZoom
  L11_2 = L11_2 - L12_2
  L12_2 = A0_2.nMaxZoom
  L13_2 = A0_2.nStartZoom
  L12_2 = L12_2 - L13_2
  L13_2 = MrxGuiSatellite
  L13_2 = L13_2.UseMinigame
  L13_2 = L13_2()
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L4_2 = Player
  L4_2 = L4_2.SetPDAMapModeCallback
  L5_2 = A0_2.uOwner
  L6_2 = true
  L7_2 = SatelliteTargettingEnd
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = MrxGuiManager
  L4_2 = L4_2.ToggleSatellite
  L5_2 = A0_2.uOwner
  L6_2 = true
  L7_2 = "pmc"
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = Player
  L4_2 = L4_2.SetPDAMapModeCancelCallback
  L5_2 = A0_2.uOwner
  L6_2 = SatelliteTargettingCancel
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = MrxGuiSatellite
  L4_2 = L4_2.UseMinigame
  L4_2 = L4_2()
  if L4_2 then
    L4_2 = MrxGuiManager
    L4_2 = L4_2.SetSatelliteSuccessCallback
    L5_2 = A0_2.uOwner
    L6_2 = SatelliteTargettingEnd
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L4_2(L5_2, L6_2, L7_2)
    L4_2 = A0_2.tSectors
    if L4_2 then
      L4_2 = MrxGuiManager
      L4_2 = L4_2.SetSatelliteMinigameData
      L5_2 = A0_2.uOwner
      L6_2 = A0_2.tSectors
      L4_2(L5_2, L6_2)
    end
    L4_2 = MrxGuiManager
    L4_2 = L4_2.SetSatelliteCost
    L5_2 = A0_2.uOwner
    L6_2 = A0_2.nCost
    L4_2(L5_2, L6_2)
  end
end

BeginSatelliteDesignation = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L5_2 = MrxGuiManager
  L5_2 = L5_2.ToggleSatellite
  L6_2 = A0_2.uOwner
  L7_2 = false
  L5_2(L6_2, L7_2)
  L5_2 = Player
  L5_2 = L5_2.SetPDAMapMode
  L6_2 = A0_2.uOwner
  L7_2 = false
  L5_2(L6_2, L7_2)
  L5_2 = Player
  L5_2 = L5_2.SetPDAMapModeCallback
  L6_2 = A0_2.uOwner
  L7_2 = true
  L8_2 = DoNothing
  L9_2 = {}
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = A0_2
  L5_2 = A0_2.SetTargetLocation
  L7_2 = A2_2
  L8_2 = A3_2
  L9_2 = A4_2
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L5_2 = MrxSound
  L5_2 = L5_2.ExitSatelliteView
  L5_2()
  L5_2 = Event
  L5_2 = L5_2.Create
  L6_2 = Event
  L6_2 = L6_2.TimerRelative
  L7_2 = {}
  L8_2 = 0.2
  L7_2[1] = L8_2
  L8_2 = PostEndStep
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L5_2(L6_2, L7_2, L8_2, L9_2)
end

SatelliteTargettingEnd = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = MrxGuiManager
  L1_2 = L1_2.ToggleSatellite
  L2_2 = A0_2.uOwner
  L3_2 = false
  L1_2(L2_2, L3_2)
  L1_2 = Player
  L1_2 = L1_2.SetPDAMapMode
  L2_2 = A0_2.uOwner
  L3_2 = false
  L1_2(L2_2, L3_2)
  L1_2 = Player
  L1_2 = L1_2.SetPDAMapModeCallback
  L2_2 = A0_2.uOwner
  L3_2 = true
  L4_2 = DoNothing
  L5_2 = {}
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = MrxSound
  L1_2 = L1_2.ExitSatelliteView
  L1_2()
end

SatelliteTargettingCancel = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.sAATestLevel
  if L1_2 then
    L1_2 = MrxSupport
    L1_2 = L1_2.TestAALevel
    L2_2 = A0_2.sAATestLevel
    L1_2 = L1_2(L2_2)
    if L1_2 then
      L1_2 = MrxSupport
      L1_2 = L1_2.DenialMessage
      L2_2 = "aa"
      L1_2(L2_2)
      return
    end
  end
  L2_2 = A0_2
  L1_2 = A0_2.GetParentSupport
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2
  L1_2 = L1_2.GetFuelCost
  L1_2 = L1_2(L2_2)
  L2_2 = MrxPmc
  L2_2 = L2_2.GetFuelQty
  L2_2 = L2_2()
  if L1_2 > L2_2 then
    L1_2 = MrxSupport
    L1_2 = L1_2.DenialMessage
    L2_2 = "fuel"
    L1_2(L2_2)
    return
  end
  L1_2 = MrxSupportManager
  L1_2 = L1_2.IsRecruitAvailable
  L3_2 = A0_2
  L2_2 = A0_2.GetParentSupport
  L2_2 = L2_2(L3_2)
  L3_2 = L2_2
  L2_2 = L2_2.GetRecruit
  L2_2, L3_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.CompleteDesignation
    L1_2(L2_2)
    L1_2 = MrxSupportManager
    L1_2 = L1_2.StartRecruitCooldown
    L3_2 = A0_2
    L2_2 = A0_2.GetParentSupport
    L2_2 = L2_2(L3_2)
    L3_2 = L2_2
    L2_2 = L2_2.GetRecruit
    L2_2, L3_2 = L2_2(L3_2)
    L1_2(L2_2, L3_2)
  end
end

PostEndStep = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxSupportManager
  L1_2 = L1_2.IsRecruitAvailable
  L3_2 = A0_2
  L2_2 = A0_2.GetParentSupport
  L2_2 = L2_2(L3_2)
  L3_2 = L2_2
  L2_2 = L2_2.GetRecruit
  L2_2, L3_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.CompleteDesignation
    L1_2(L2_2)
    L1_2 = MrxSupportManager
    L1_2 = L1_2.StartRecruitCooldown
    L3_2 = A0_2
    L2_2 = A0_2.GetParentSupport
    L2_2 = L2_2(L3_2)
    L3_2 = L2_2
    L2_2 = L2_2.GetRecruit
    L2_2, L3_2 = L2_2(L3_2)
    L1_2(L2_2, L3_2)
  end
end

_DelayDesignationComplete = L0_1

function L0_1()
  local L0_2, L1_2
end

DoNothing = L0_1
