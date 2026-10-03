local L0_1, L1_1, L2_1, L3_1
uOwner = L0_1
L0_1 = false
bDesignationComplete = L0_1
L0_1 = nil
sDesignationType = L0_1
L0_1 = nil
sAATestLevel = L0_1
L0_1 = nil
fValidationFunction = L0_1
L0_1 = {}
tCallbackList = L0_1
L0_1 = {}
tVOCues = L0_1
L0_1 = nil
nX = L0_1
L0_1 = nil
nY = L0_1
L0_1 = nil
nZ = L0_1
L0_1 = nil
uGuid = L0_1
L0_1 = nil
oParentSupport = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = A0_2.bDesignationComplete
  if not L1_2 then
    L1_2 = nil
    return L1_2
  end
  L1_2 = A0_2.nX
  L2_2 = A0_2.nY
  L3_2 = A0_2.nZ
  L4_2 = A0_2.uGuid
  L5_2 = A0_2.uTarget
  return L1_2, L2_2, L3_2, L4_2, L5_2
end

GetTarget = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2.sDesignationType
  if L1_2 then
    L1_2 = A0_2.sDesignationType
    if "Beacon Designator" == L1_2 then
      L1_2 = A0_2.uGuid
      if L1_2 then
        L1_2 = Object
        L1_2 = L1_2.Remove
        L2_2 = A0_2.uGuid
        L1_2(L2_2)
      end
    end
  end
end

RemoveBeacon = L0_1

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
  A1_2.bDesignateOnDeath = true
  L2_2 = A0_2.sDesignationType
  A1_2.sDesignationType = L2_2
  L2_2 = A0_2.sAATestLevel
  A1_2.sAATestLevel = L2_2
  L2_2 = A0_2.fValidationFunction
  A1_2.fValidationFunction = L2_2
  L2_2 = {}
  A1_2.tCallbackList = L2_2
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
  local L2_2, L3_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" ~= L2_2 then
    return
  end
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if "userdata" ~= L2_2 then
    return
  end
  A0_2.uOwner = A1_2
end

SetOwner = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L4_2 = A0_2
  L3_2 = A0_2.SetCompleteCallback
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
end

AddCompleteCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2
  L2_2 = A0_2.tCallbackList
  L2_2[A1_2] = nil
end

RemoveCompleteCallback = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  L3_2 = type
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if "function" == L3_2 then
    L3_2 = {}
    L4_2 = type
    L5_2 = A2_2
    L4_2 = L4_2(L5_2)
    if "table" == L4_2 then
      L3_2 = A2_2
    end
    L4_2 = A0_2.tCallbackList
    L4_2[A1_2] = L3_2
  end
end

SetCompleteCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" ~= L2_2 then
    return
  end
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if "string" ~= L2_2 and nil ~= A1_2 then
    return
  end
  A0_2.sDesignationType = A1_2
end

SetDesignationType = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" ~= L2_2 then
    return
  end
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if "function" ~= L2_2 and nil ~= A1_2 then
    return
  end
  A0_2.fValidationFunction = A1_2
end

SetValidationFunction = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" ~= L2_2 then
    return
  end
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if "boolean" ~= L2_2 then
    return
  end
  A0_2.bValidateTarget = A1_2
end

SetTargetValidationRequired = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" ~= L2_2 then
    return
  end
  A0_2.sAATestLevel = A1_2
end

SetAATestLevel = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2
  L4_2 = type
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if "table" ~= L4_2 then
    return
  end
  L4_2 = type
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  if "number" == L4_2 then
    L4_2 = type
    L5_2 = A2_2
    L4_2 = L4_2(L5_2)
    if "number" == L4_2 then
      L4_2 = type
      L5_2 = A3_2
      L4_2 = L4_2(L5_2)
      if "number" == L4_2 then
        goto lbl_23
      end
    end
  end
  do return end
  ::lbl_23::
  A0_2.nX = A1_2
  A0_2.nY = A2_2
  A0_2.nZ = A3_2
end

SetTargetLocation = L0_1

function L0_1(A0_2, A1_2)
end

OnDeny = L0_1

function L0_1(A0_2, A1_2)
  A0_2.oParentSupport = A1_2
end

SetParentSupport = L0_1

function L0_1(A0_2, A1_2)
  local L2_2
  L2_2 = A0_2.oParentSupport
  return L2_2
end

GetParentSupport = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = pairs
  L3_2 = A1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2 in L2_2, L3_2, L4_2 do
    L6_2 = A1_2[L5_2]
    if not L6_2 then
      L6_2 = A0_2[L5_2]
    end
    A0_2[L5_2] = L6_2
  end
end

Configure = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = type
  L3_2 = A0_2.uOwner
  L2_2 = L2_2(L3_2)
  if "userdata" ~= L2_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = Airstrike
  L2_2 = L2_2.EquipDesignator
  L3_2 = A0_2.uOwner
  L4_2 = A0_2.sDesignationType
  L5_2 = nil
  L6_2 = nil
  L7_2 = A1_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  A0_2.uWeaponGuid = L2_2
  L2_2 = A0_2.uWeaponGuid
  if L2_2 then
    L2_2 = Weapon
    L2_2 = L2_2.SetReserveAmmo
    L3_2 = A0_2.uWeaponGuid
    L4_2 = 1
    L2_2(L3_2, L4_2)
  end
  L2_2 = A0_2.uWeaponGuid
  return L2_2
end

Commence = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = "none"
  return L1_2
end

GetType = L0_1
L0_1 = 8
L1_1 = {}
L2_1 = {}
L2_1.nRadius = 3
L2_1.nHeightTolerance = 2
L2_1.bWater = false
L1_1.default = L2_1
L2_1 = {}
L2_1.nRadius = 3
L2_1.nHeightTolerance = 2
L2_1.bWater = true
L1_1.Jetski = L2_1
L2_1 = {}
L2_1.nRadius = 2
L2_1.nHeightTolerance = 2
L2_1.bWater = false
L1_1.box = L2_1
L2_1 = L1_1.box
L1_1["0x8000721F"] = L2_1
L2_1 = L1_1.box
L1_1["0x80006252"] = L2_1
L2_1 = L1_1.box
L1_1["0x8000721E"] = L2_1
L2_1 = L1_1.box
L1_1["0x80007D92"] = L2_1
L2_1 = L1_1.box
L1_1["0x80009AE8"] = L2_1
L2_1 = L1_1.box
L1_1["0x80009ae9"] = L2_1
L2_1 = L1_1.box
L1_1["0x8000721B"] = L2_1
L2_1 = L1_1.box
L1_1["0x8000855D"] = L2_1
L2_1 = L1_1.box
L1_1["0x80007221"] = L2_1
L2_1 = L1_1.box
L1_1["0x8000A259"] = L2_1
L2_1 = L1_1.box
L1_1["0x8000721C"] = L2_1
L2_1 = L1_1.box
L1_1["0x80006251"] = L2_1
L2_1 = L1_1.box
L1_1["0x8000721D"] = L2_1
L2_1 = L1_1.box
L1_1["0x80007223"] = L2_1
L2_1 = L1_1.box
L1_1["0x80008E5D"] = L2_1
L2_1 = {}
L3_1 = {}
L3_1.nHeightMax = 16
L3_1.nInnerRadius = 4
L3_1.nOuterRadius = 13
L3_1.nInnerHeightTolerance = 1
L3_1.nOuterHeightTolerance = 2.5
L2_1.default = L3_1
L3_1 = {}
L3_1.nHeightMax = 16
L3_1.nInnerRadius = 3
L3_1.nOuterRadius = 13
L3_1.nInnerHeightTolerance = 1
L3_1.nOuterHeightTolerance = 2.5
L2_1["0x80008208"] = L3_1
L3_1 = {}
L3_1.nHeightMax = 20
L3_1.nInnerRadius = 6
L3_1.nOuterRadius = 19
L3_1.nInnerHeightTolerance = 1
L3_1.nOuterHeightTolerance = 2.5
L2_1["0x80009467"] = L3_1
L3_1 = {}
L3_1.nHeightMax = 20
L3_1.nInnerRadius = 6
L3_1.nOuterRadius = 19
L3_1.nInnerHeightTolerance = 1
L3_1.nOuterHeightTolerance = 2.5
L2_1["0x80009466"] = L3_1
L3_1 = {}
L3_1.nHeightMax = 16
L3_1.nInnerRadius = 4
L3_1.nOuterRadius = 11
L3_1.nInnerHeightTolerance = 1
L3_1.nOuterHeightTolerance = 2.5
L2_1["0x800092C4"] = L3_1
L3_1 = {}
L3_1.nHeightMax = 16
L3_1.nInnerRadius = 4
L3_1.nOuterRadius = 11
L3_1.nInnerHeightTolerance = 1
L3_1.nOuterHeightTolerance = 2.5
L2_1["0x800081FF"] = L3_1
L3_1 = {}
L3_1.nHeightMax = 16
L3_1.nInnerRadius = 4
L3_1.nOuterRadius = 13
L3_1.nInnerHeightTolerance = 1
L3_1.nOuterHeightTolerance = 2.5
L2_1["0x80008529"] = L3_1
L3_1 = {}
L3_1.nHeightMax = 16
L3_1.nInnerRadius = 4
L3_1.nOuterRadius = 13
L3_1.nInnerHeightTolerance = 1
L3_1.nOuterHeightTolerance = 2.5
L2_1["0x80008207"] = L3_1
L3_1 = {}
L3_1.nHeightMax = 14
L3_1.nInnerRadius = 3
L3_1.nOuterRadius = 8
L3_1.nInnerHeightTolerance = 1
L3_1.nOuterHeightTolerance = 2.5
L2_1["0x800081FB"] = L3_1
L3_1 = {}
L3_1.nHeightMax = 14
L3_1.nInnerRadius = 3
L3_1.nOuterRadius = 8
L3_1.nInnerHeightTolerance = 1
L3_1.nOuterHeightTolerance = 2.5
L2_1["0x800081FA"] = L3_1
L3_1 = {}
L3_1.nHeightMax = 14
L3_1.nInnerRadius = 3
L3_1.nOuterRadius = 8
L3_1.nInnerHeightTolerance = 1
L3_1.nOuterHeightTolerance = 2.5
L2_1["0x80008204"] = L3_1
L3_1 = L2_1["0x80008208"]
L2_1["0x80008686"] = L3_1
L3_1 = {}
L3_1.nHeightMax = 29
L3_1.nInnerRadius = 8
L3_1.nOuterRadius = 24
L3_1.nInnerHeightTolerance = 1
L3_1.nOuterHeightTolerance = 2.5
L2_1["0x80006F71"] = L3_1

function L3_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L6_2 = L1_1
  L7_2 = tostring
  L8_2 = A4_2.uCargoToDeliver
  L7_2 = L7_2(L8_2)
  L6_2 = L6_2[L7_2]
  if not L6_2 then
    L6_2 = L1_1
    L6_2 = L6_2.default
  end
  L7_2 = L2_1
  L8_2 = tostring
  L9_2 = A4_2.uDeliveryVehicle
  L8_2 = L8_2(L9_2)
  L7_2 = L7_2[L8_2]
  if not L7_2 then
    L7_2 = L2_1
    L7_2 = L7_2.default
  end
  L8_2 = Ai
  L8_2 = L8_2.TestDropZone
  L9_2 = {}
  L9_2.Callback = A0_2
  L10_2 = {}
  L11_2 = A1_2
  L12_2 = A2_2
  L13_2 = A3_2
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L9_2.Location = L10_2
  L10_2 = L6_2.nRadius
  L9_2.InnerRadius = L10_2
  L10_2 = L6_2.nHeightTolerance
  L9_2.InnerHeightTolerance = L10_2
  L10_2 = L7_2.nOuterRadius
  L9_2.OuterRadius = L10_2
  L10_2 = L7_2.nOuterHeightTolerance
  L11_2 = L0_1
  L10_2 = L10_2 + L11_2
  L9_2.OuterHeightTolerance = L10_2
  L10_2 = L7_2.nHeightMax
  L11_2 = L0_1
  L10_2 = L10_2 + L11_2
  L9_2.HeightMax = L10_2
  L9_2.SearchRadius = 6
  L9_2.Water = A5_2
  L8_2 = L8_2(L9_2)
  if not L8_2 then
    L9_2 = A0_2
    L10_2 = false
    L11_2 = "nodrop"
    L9_2(L10_2, L11_2)
  end
end

ValidateGroundDropZone = L3_1

function L3_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L5_2 = ValidateGroundDropZone
  L6_2 = A0_2
  L7_2 = A1_2
  L8_2 = A2_2
  L9_2 = A3_2
  L10_2 = A4_2
  L11_2 = true
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
end

ValidateWaterDropZone = L3_1

function L3_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L5_2 = L2_1
  L6_2 = tostring
  L7_2 = A4_2.uDeliveryVehicle
  L6_2 = L6_2(L7_2)
  L5_2 = L5_2[L6_2]
  if not L5_2 then
    L5_2 = L2_1
    L5_2 = L5_2.default
  end
  L6_2 = Ai
  L6_2 = L6_2.TestDropZone
  L7_2 = {}
  L7_2.Callback = A0_2
  L8_2 = {}
  L9_2 = A1_2
  L10_2 = A2_2
  L11_2 = A3_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L7_2.Location = L8_2
  L7_2.InnerRadius = 3
  L7_2.InnerHeightTolerance = 2
  L8_2 = L5_2.nOuterRadius
  L7_2.OuterRadius = L8_2
  L8_2 = L5_2.nOuterHeightTolerance
  L8_2 = L8_2 + 8
  L7_2.OuterHeightTolerance = L8_2
  L8_2 = L5_2.nHeightMax
  L7_2.HeightMax = L8_2
  L7_2.SearchRadius = 20
  L7_2.Water = false
  L6_2 = L6_2(L7_2)
  if not L6_2 then
    L7_2 = A0_2
    L8_2 = false
    L9_2 = "noland"
    L7_2(L8_2, L9_2)
  end
end

ValidateLandingZone = L3_1

function L3_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  A0_2.bDesignationComplete = true
  L1_2 = pairs
  L2_2 = A0_2.tCallbackList
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L4_2
    L7_2 = unpack
    L8_2 = L5_2
    L7_2, L8_2 = L7_2(L8_2)
    L6_2(L7_2, L8_2)
  end
  L1_2 = Event
  L1_2 = L1_2.Post
  L2_2 = "Airstrike"
  L3_2 = {}
  L3_2.sStage = "DesignationComplete"
  L3_2.sType = "None"
  L1_2(L2_2, L3_2)
end

CompleteDesignation = L3_1

function L3_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2
  L6_2 = type
  L7_2 = A1_2
  L6_2 = L6_2(L7_2)
  if "number" ~= L6_2 then
    A1_2 = nil
  end
  L6_2 = type
  L7_2 = A2_2
  L6_2 = L6_2(L7_2)
  if "number" ~= L6_2 then
    A2_2 = nil
  end
  L6_2 = type
  L7_2 = A3_2
  L6_2 = L6_2(L7_2)
  if "number" ~= L6_2 then
    A3_2 = nil
  end
  L6_2 = type
  L7_2 = A4_2
  L6_2 = L6_2(L7_2)
  if "userdata" ~= L6_2 then
    A4_2 = nil
  end
  L6_2 = type
  L7_2 = A5_2
  L6_2 = L6_2(L7_2)
  if "userdata" ~= L6_2 then
    A5_2 = nil
  end
  L6_2 = A1_2 or L6_2
  if not A1_2 then
    L6_2 = A0_2.nX
  end
  A0_2.nX = L6_2
  L6_2 = A2_2 or L6_2
  if not A2_2 then
    L6_2 = A0_2.nY
  end
  A0_2.nY = L6_2
  L6_2 = A3_2 or L6_2
  if not A3_2 then
    L6_2 = A0_2.nZ
  end
  A0_2.nZ = L6_2
  L6_2 = A4_2 or L6_2
  if not A4_2 then
    L6_2 = A0_2.uGuid
  end
  A0_2.uGuid = L6_2
  L6_2 = A5_2 or L6_2
  if not A5_2 then
    L6_2 = A0_2.uTarget
  end
  A0_2.uTarget = L6_2
end

SetDesignationParameters = L3_1
