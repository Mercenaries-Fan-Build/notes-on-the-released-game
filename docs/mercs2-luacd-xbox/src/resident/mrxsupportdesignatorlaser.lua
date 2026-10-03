local L0_1, L1_1
L0_1 = import
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = inherit
L1_1 = "MrxSupportDesignator"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = Pg
  L0_2 = L0_2.LoadAsset
  L1_2 = "global_weapon_laserrangefinder"
  L2_2 = "model"
  L0_2(L1_2, L2_2)
end

Init = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = Pg
  L0_2 = L0_2.UnloadAsset
  L1_2 = "global_weapon_laserrangefinder"
  L2_2 = "model"
  L0_2(L1_2, L2_2)
end

Deinit = L0_1

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
  A1_2.sDesignationType = "Laser Designator"
  L2_2 = A0_2.fValidationFunction
  A1_2.fValidationFunction = L2_2
  L2_2 = {}
  A1_2.tCallbackList = L2_2
  A1_2.sAATestLevel = "medium"
  L2_2 = A0_2.nX
  A1_2.nX = L2_2
  L2_2 = A0_2.nY
  A1_2.nY = L2_2
  L2_2 = A0_2.nZ
  A1_2.nZ = L2_2
  L2_2 = A0_2.uGuid
  A1_2.uGuid = L2_2
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
  L5_2 = LaserFinished
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L7_2 = false
  return L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

Commence = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2.sAATestLevel
  if L2_2 then
    L2_2 = MrxSupport
    L2_2 = L2_2.TestAALevel
    L3_2 = A0_2.sAATestLevel
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = MrxSupport
      L2_2 = L2_2.DenialMessage
      L3_2 = "aa"
      L2_2(L3_2)
      return
    end
  end
  L3_2 = A0_2
  L2_2 = A0_2.GetParentSupport
  L2_2 = L2_2(L3_2)
  L3_2 = L2_2
  L2_2 = L2_2.GetFuelCost
  L2_2 = L2_2(L3_2)
  L3_2 = MrxPmc
  L3_2 = L3_2.GetFuelQty
  L3_2 = L3_2()
  if L2_2 > L3_2 then
    L2_2 = MrxSupport
    L2_2 = L2_2.DenialMessage
    L3_2 = "fuel"
    L2_2(L3_2)
    return
  end
  L2_2 = MrxSupportManager
  L2_2 = L2_2.IsRecruitAvailable
  L4_2 = A0_2
  L3_2 = A0_2.GetParentSupport
  L3_2 = L3_2(L4_2)
  L4_2 = L3_2
  L3_2 = L3_2.GetRecruit
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  if not L2_2 then
    return
  end
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = A1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L6_2 = A0_2
  L5_2 = A0_2.SetDesignationParameters
  L7_2 = L2_2
  L8_2 = L3_2
  L9_2 = L4_2
  L10_2 = A1_2
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L6_2 = A0_2
  L5_2 = A0_2.CompleteDesignation
  L5_2(L6_2)
  L5_2 = MrxSupportManager
  L5_2 = L5_2.StartRecruitCooldown
  L7_2 = A0_2
  L6_2 = A0_2.GetParentSupport
  L6_2 = L6_2(L7_2)
  L7_2 = L6_2
  L6_2 = L6_2.GetRecruit
  L6_2, L7_2, L8_2, L9_2, L10_2 = L6_2(L7_2)
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
end

LaserFinished = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = false
  return L1_2
end

ShouldSuppressIconAnimationOnDirectUse = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = "laser"
  return L1_2
end

GetType = L0_1
