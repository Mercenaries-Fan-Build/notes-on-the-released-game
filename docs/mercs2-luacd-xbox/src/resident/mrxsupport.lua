local L0_1, L1_1
L0_1 = import
L1_1 = "MrxSupportDesignator"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiHudMessage"
L0_1(L1_1)
L0_1 = import
L1_1 = "AntiAir"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxAchievements"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = nil
oDesignator = L0_1
L0_1 = "Support Vehicle (Mig27)"
sDeliveryVehicle = L0_1
L0_1 = Pg
L0_1 = L0_1.GetGuidByName
L1_1 = "Support Vehicle (Mig27)"
L0_1 = L0_1(L1_1)
uDeliveryVehicle = L0_1
L0_1 = "Dumb Bomb Projectile"
sBomb = L0_1
L0_1 = Pg
L0_1 = L0_1.GetGuidByName
L1_1 = "Dumb Bomb Projectile"
L0_1 = L0_1(L1_1)
uBomb = L0_1
L0_1 = nil
uOwner = L0_1
L0_1 = 0
nAircraftBlip = L0_1
L0_1 = {}
tEvents = L0_1
L0_1 = {}
tAA = L0_1
L0_1 = tAA
L0_1.basic = 0
L0_1 = tAA
L0_1.medium = 0
L0_1 = tAA
L0_1.advanced = 0
L0_1 = tAA
L0_1.jammer = 0
L0_1 = "Arachnid Guy"
sRecruit = L0_1
L0_1 = {}
tVOCues = L0_1
L0_1 = {}
tLocalNetObjects = L0_1
L0_1 = {}
tRemoteNetObjects = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = o
  if not L2_2 then
    L2_2 = {}
  end
  L3_2 = setmetatable
  L4_2 = L2_2
  L5_2 = A0_2
  L3_2(L4_2, L5_2)
  A0_2.__index = A0_2
  L4_2 = L2_2
  L3_2 = L2_2.SetDesignator
  L5_2 = nil
  L3_2(L4_2, L5_2)
  L3_2 = A0_2.sDeliveryVehicle
  L2_2.sDeliveryVehicle = L3_2
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = A0_2.sDeliveryVehicle
  L3_2 = L3_2(L4_2)
  L2_2.uDeliveryVehicle = L3_2
  L3_2 = A0_2.sBomb
  L2_2.sBomb = L3_2
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = A0_2.sBomb
  L3_2 = L3_2(L4_2)
  L2_2.uBomb = L3_2
  L4_2 = L2_2
  L3_2 = L2_2.SetOwner
  L5_2 = A1_2 or L5_2
  if not A1_2 then
    L5_2 = A0_2.uOwner
  end
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetModuleName
  L5_2 = "MrxSupport"
  L3_2(L4_2, L5_2)
  return L2_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2
end

DesignationCallback = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.oDesignator
  return L1_2
end

GetDesignator = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  A0_2.oDesignator = A1_2
  if A1_2 then
    L3_2 = A1_2
    L2_2 = A1_2.SetParentSupport
    L4_2 = A0_2
    L2_2(L3_2, L4_2)
  end
end

SetDesignator = L0_1

function L0_1(A0_2, A1_2)
  A0_2.sModuleName = A1_2
end

SetModuleName = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.sModuleName
  return L1_2
end

GetModuleName = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = ObjectState
  L1_2 = L1_2.GetStringHash
  L2_2 = A0_2.sModuleName
  return L1_2(L2_2)
end

GetModule = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if "userdata" ~= L2_2 then
    return
  end
  A0_2.uOwner = A1_2
  L2_2 = A0_2.oDesignator
  if L2_2 then
    L2_2 = A0_2.oDesignator
    L3_2 = L2_2
    L2_2 = L2_2.SetOwner
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  end
end

SetOwner = L0_1

function L0_1(A0_2, A1_2)
  A0_2.sFactionId = A1_2
end

SetFaction = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.sFactionId
  return L1_2
end

GetFaction = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.oDesignator
  if L1_2 then
    L1_2 = A0_2.oDesignator
    L1_2 = L1_2.sAATestLevel
    if L1_2 then
      L1_2 = "[PDA.Support.denied."
      L2_2 = tostring
      L3_2 = A0_2.oDesignator
      L3_2 = L3_2.sAATestLevel
      L2_2 = L2_2(L3_2)
      L3_2 = "]"
      L1_2 = L1_2 .. L2_2 .. L3_2
      L2_2 = TestAALevel
      L3_2 = A0_2.oDesignator
      L3_2 = L3_2.sAATestLevel
      L2_2 = L2_2(L3_2)
      if L2_2 then
        return L1_2
      end
    end
  end
  L2_2 = A0_2
  L1_2 = A0_2.GetFaction
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = MrxFactionManager
    L1_2 = L1_2.GetAttitudeLabel
    L3_2 = A0_2
    L2_2 = A0_2.GetFaction
    L2_2 = L2_2(L3_2)
    L3_2 = "Pmc"
    L1_2 = L1_2(L2_2, L3_2)
    if L1_2 == "Hostile" then
      L1_2 = "[Generic.Attitudes.Hostile]"
      return L1_2
    end
  end
  L1_2 = MrxSupportManager
  L1_2 = L1_2.IsRecruitAvailable
  L3_2 = A0_2
  L2_2 = A0_2.GetRecruit
  L2_2, L3_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    L1_2 = "[PDA.Support.denied.rearming]"
    return L1_2
  end
  L1_2 = nil
  return L1_2
end

GetDenialCondition = L0_1

function L0_1(A0_2, A1_2)
  local L2_2
  L2_2 = A0_2.uOwner
  return L2_2
end

GetOwner = L0_1

function L0_1(A0_2, A1_2)
  A0_2.sRecruit = A1_2
end

SetRecruit = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.sRecruit
  return L1_2
end

GetRecruit = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2.GetDenialCondition
  L1_2 = L1_2(L2_2)
  if "[PDA.Support.denied.rearming]" == L1_2 then
    L1_2 = MrxSupportManager
    L1_2 = L1_2.GetRecruitTimes
    L3_2 = A0_2
    L2_2 = A0_2.GetRecruit
    L2_2, L3_2 = L2_2(L3_2)
    return L1_2(L2_2, L3_2)
  end
end

GetElapsedCooldownTime = L0_1

function L0_1(A0_2, A1_2)
  A0_2.sSupportName = A1_2
end

SetSupportName = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.sSupportName
  return L1_2
end

GetSupportName = L0_1

function L0_1(A0_2, A1_2)
  A0_2.nFuelCost = A1_2
end

SetFuelCost = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.nFuelCost
  if not L1_2 then
    L1_2 = 0
  end
  return L1_2
end

GetFuelCost = L0_1

function L0_1(A0_2, A1_2)
  A0_2.nCashCost = A1_2
end

SetCashCost = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.nCashCost
  return L1_2
end

GetCashCost = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2.oDesignator
  if L1_2 then
    L1_2 = A0_2.oDesignator
    L1_2 = L1_2.ShouldSuppressIconAnimationOnDirectUse
    if L1_2 then
      L1_2 = A0_2.oDesignator
      L2_2 = L1_2
      L1_2 = L1_2.ShouldSuppressIconAnimationOnDirectUse
      return L1_2(L2_2)
    end
  end
  L1_2 = true
  return L1_2
end

ShouldSuppressIconAnimationOnDirectUse = L0_1

function L0_1(A0_2, A1_2)
  A0_2.tVOCues = A1_2
end

SetVOCues = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.tVOCues
  return L1_2
end

GetVOCues = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 == "table" then
    L2_2 = MrxUtil
    L2_2 = L2_2.SetDefault
    L3_2 = A1_2
    L4_2 = true
    L2_2 = L2_2(L3_2, L4_2)
    A1_2 = L2_2
    L2_2 = MrxUtil
    L2_2 = L2_2.GetRandomTableElement
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    L3_2 = MrxVoSequence
    L3_2 = L3_2.Start
    L4_2 = L2_2
    L5_2 = nil
    L6_2 = MrxVoSequence
    L6_2 = L6_2.knPriorityFreeplay
    L7_2 = A1_2
    L3_2(L4_2, L5_2, L6_2, L7_2)
  else
  end
end

PlayRandomVOCue = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2
  L2_2 = A0_2
  L1_2 = A0_2.GetSupportName
  L1_2 = L1_2(L2_2)
  L3_2 = A0_2
  L2_2 = A0_2.GetFuelCost
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = math
    L3_2 = L3_2.min
    L4_2 = L2_2
    L5_2 = MrxPmc
    L5_2 = L5_2.GetFuelQty
    L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2 = L5_2()
    L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2)
    L4_2 = MrxPmc
    L4_2 = L4_2.AddFuelQty
    L5_2 = L3_2 * -1
    L4_2(L5_2)
    A0_2.nFuelConsumed = L3_2
  end
  L3_2 = MrxPmc
  L3_2 = L3_2.GetFreebieQty
  L4_2 = L1_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    if L3_2 < 1 then
      L5_2 = A0_2
      L4_2 = A0_2.GetCashCost
      L4_2 = L4_2(L5_2)
      if L4_2 then
        L5_2 = MrxPmc
        L5_2 = L5_2.AddCashQty
        L6_2 = -L4_2
        L5_2(L6_2)
      end
    else
      L4_2 = MrxPmc
      L4_2 = L4_2.AddFreebieQty
      L5_2 = L1_2
      L6_2 = -1
      L4_2(L5_2, L6_2)
      A0_2.sFreebieConsumed = L1_2
    end
  else
    L4_2 = MrxPmc
    L4_2 = L4_2.GetSupportQty
    L5_2 = L1_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      L5_2 = MrxPmc
      L5_2 = L5_2.AddSupportQty
      L6_2 = L1_2
      L7_2 = -1
      L5_2(L6_2, L7_2)
      A0_2.sStockpileConsumed = L1_2
    end
  end
  L4_2 = Net
  L4_2 = L4_2.SendEvent_Support
  if L4_2 then
    L4_2 = nil
    L5_2 = nil
    L6_2 = nil
    L7_2 = nil
    L8_2 = nil
    L9_2 = nil
    L10_2 = A0_2.oDesignator
    if L10_2 then
      L10_2 = A0_2.oDesignator
      L11_2 = L10_2
      L10_2 = L10_2.GetTarget
      L10_2, L11_2, L12_2, L13_2, L14_2 = L10_2(L11_2)
      L8_2 = L14_2
      L7_2 = L13_2
      L6_2 = L12_2
      L5_2 = L11_2
      L4_2 = L10_2
    end
    L10_2 = A0_2.oFinalDestination
    L11_2 = type
    L12_2 = L10_2
    L11_2 = L11_2(L12_2)
    if "string" == L11_2 then
      L11_2 = Pg
      L11_2 = L11_2.GetGuidByName
      L12_2 = L10_2
      L11_2 = L11_2(L12_2)
      L10_2 = L11_2
    end
    L11_2 = A0_2.sBomb
    L12_2 = type
    L13_2 = L11_2
    L12_2 = L12_2(L13_2)
    if "string" == L12_2 then
      L12_2 = Pg
      L12_2 = L12_2.GetGuidByName
      L13_2 = L11_2
      L12_2 = L12_2(L13_2)
      L11_2 = L12_2
    end
    L12_2 = A0_2.oDesignator
    L12_2 = L12_2.bDesignationComplete
    if L12_2 then
      L9_2 = true
    end
    L12_2 = Net
    L12_2 = L12_2.SendEvent_Support
    L14_2 = A0_2
    L13_2 = A0_2.GetModule
    L13_2 = L13_2(L14_2)
    L14_2 = L4_2 or L14_2
    if not L4_2 then
      L14_2 = 0
    end
    L15_2 = L5_2 or L15_2
    if not L5_2 then
      L15_2 = 0
    end
    L16_2 = L6_2 or L16_2
    if not L6_2 then
      L16_2 = 0
    end
    L17_2 = L7_2 or L17_2
    if not L7_2 then
      L17_2 = 0
    end
    L18_2 = L8_2 or L18_2
    if not L8_2 then
      L18_2 = 0
    end
    L19_2 = A0_2.uCargoToDeliver
    if not L19_2 then
      L19_2 = 0
    end
    L20_2 = L10_2
    L21_2 = A0_2.uDeliveryVehicle
    L22_2 = L11_2
    L23_2 = L9_2
    L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2)
  end
  L4_2 = Event
  L4_2 = L4_2.Post
  L5_2 = "SupportUsed"
  L6_2 = A0_2
  L4_2(L5_2, L6_2)
  L5_2 = A0_2
  L4_2 = A0_2.GetRecruit
  L4_2 = L4_2(L5_2)
  if L4_2 == "Copter" then
    L4_2 = MrxSupportManager
    L4_2 = L4_2.StartRecruitCooldown
    L5_2 = "Copter"
    L6_2 = 60
    L4_2(L5_2, L6_2)
  end
  L5_2 = A0_2
  L4_2 = A0_2.DesignationCallback
  return L4_2(L5_2)
end

BeginSupportSequence = L0_1

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
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = type
  L3_2 = A0_2.oDesignator
  L2_2 = L2_2(L3_2)
  if "table" ~= L2_2 then
    L2_2 = A0_2.uOwner
    if L2_2 then
      L2_2 = MrxSupportManager
      L2_2 = L2_2.CurrentlyEquippedSupport
      L3_2 = L2_2
      L2_2 = L2_2.AddSupport
      L4_2 = A0_2
      L2_2(L3_2, L4_2)
    end
    L3_2 = A0_2
    L2_2 = A0_2.BeginSupportSequence
    L2_2(L3_2)
    L2_2 = true
    return L2_2
  end
  L2_2 = type
  L3_2 = A0_2.oDesignator
  L3_2 = L3_2.GetTarget
  L2_2 = L2_2(L3_2)
  if "function" ~= L2_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = type
  L3_2 = A0_2.oDesignator
  L3_2 = L3_2.Configure
  L2_2 = L2_2(L3_2)
  if "function" ~= L2_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = type
  L3_2 = A0_2.oDesignator
  L3_2 = L3_2.Commence
  L2_2 = L2_2(L3_2)
  if "function" ~= L2_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = MrxSupportManager
  L2_2 = L2_2.IsRecruitAvailable
  L4_2 = A0_2
  L3_2 = A0_2.GetRecruit
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  if not L2_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = A0_2.oDesignator
  L3_2 = L2_2
  L2_2 = L2_2.SetOwner
  L4_2 = A0_2.uOwner
  L2_2(L3_2, L4_2)
  L2_2 = A0_2.oDesignator
  L3_2 = L2_2
  L2_2 = L2_2.SetCompleteCallback
  L4_2 = BeginSupportSequence
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = A0_2.uOwner
  if L2_2 then
    L2_2 = MrxSupportManager
    L2_2 = L2_2.CurrentlyEquippedSupport
    L3_2 = L2_2
    L2_2 = L2_2.AddSupport
    L4_2 = A0_2
    L2_2(L3_2, L4_2)
  end
  L2_2 = A0_2.oDesignator
  L3_2 = L2_2
  L2_2 = L2_2.Commence
  L4_2 = A1_2
  return L2_2(L3_2, L4_2)
end

Commence = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  if not A2_2 then
    A2_2 = false
  end
  L4_2 = A1_2 or L4_2
  if not A1_2 then
    L4_2 = {}
    L5_2 = 0
    L6_2 = 173
    L7_2 = 239
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L4_2[3] = L7_2
  end
  L5_2 = nAircraftBlip
  L5_2 = L5_2 + 1
  nAircraftBlip = L5_2
  L5_2 = tostring
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  L6_2 = Hud
  L6_2 = L6_2.Radar
  L7_2 = L6_2
  L6_2 = L6_2.AddObjective
  L8_2 = {}
  L8_2.sName = L5_2
  L9_2 = L4_2[1]
  L8_2.nR = L9_2
  L9_2 = L4_2[2]
  L8_2.nG = L9_2
  L9_2 = L4_2[3]
  L8_2.nB = L9_2
  L8_2.nWidth = 3
  L8_2.nHeight = 3
  L8_2.sTexture = A3_2
  L8_2.uGuid = A0_2
  L8_2.bSticky = A2_2
  L8_2.nSortOrder = 4
  L6_2(L7_2, L8_2)
  L6_2 = tEvents
  L7_2 = {}
  L6_2[L5_2] = L7_2
  L6_2 = tEvents
  L6_2 = L6_2[L5_2]
  L6_2.uGuid = A0_2
  L6_2 = tEvents
  L6_2 = L6_2[L5_2]
  L7_2 = Event
  L7_2 = L7_2.Create
  L8_2 = Event
  L8_2 = L8_2.ObjectHibernation
  L9_2 = {}
  L10_2 = A0_2
  L11_2 = "hibernated"
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L10_2 = _RemoveBlipCallback
  L11_2 = {}
  L12_2 = L5_2
  L13_2 = true
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
  L6_2.uHibernation = L7_2
  L6_2 = tEvents
  L6_2 = L6_2[L5_2]
  L7_2 = Event
  L7_2 = L7_2.Create
  L8_2 = Event
  L8_2 = L8_2.ObjectDeath
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L10_2 = _RemoveBlipCallback
  L11_2 = {}
  L12_2 = L5_2
  L13_2 = false
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
  L6_2.uDeath = L7_2
  L6_2 = Vehicle
  L6_2 = L6_2.GetDriver
  L7_2 = A0_2
  L6_2 = L6_2(L7_2)
  if L6_2 then
  end
  return L5_2
end

BlipAircraft = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = Hud
  L2_2 = L2_2.Radar
  L3_2 = L2_2
  L2_2 = L2_2.RemoveObjective
  L4_2 = {}
  L4_2.sName = A0_2
  L2_2(L3_2, L4_2)
  L2_2 = Net
  L2_2 = L2_2.IsServer
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = Net
    L2_2 = L2_2.SendEvent_RemoveObjective
    L3_2 = A0_2
    L2_2(L3_2)
  end
  L2_2 = tEvents
  L2_2 = L2_2[A0_2]
  if L2_2 then
    if A1_2 then
      L2_2 = Object
      L2_2 = L2_2.IsAlive
      L3_2 = tEvents
      L3_2 = L3_2[A0_2]
      L3_2 = L3_2.uGuid
      L2_2 = L2_2(L3_2)
      if L2_2 then
        L2_2 = Object
        L2_2 = L2_2.Remove
        L3_2 = tEvents
        L3_2 = L3_2[A0_2]
        L3_2 = L3_2.uGuid
        L2_2(L3_2)
      end
    end
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = tEvents
    L3_2 = L3_2[A0_2]
    L3_2 = L3_2.uHibernation
    L2_2(L3_2)
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = tEvents
    L3_2 = L3_2[A0_2]
    L3_2 = L3_2.uDeath
    L2_2(L3_2)
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = tEvents
    L3_2 = L3_2[A0_2]
    L3_2 = L3_2.uDriver
    L2_2(L3_2)
    L2_2 = tEvents
    L2_2[A0_2] = nil
  end
end

_RemoveBlipCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = tAA
  L2_2 = L2_2[A0_2]
  if L2_2 then
    return
  end
  L2_2 = string
  L2_2 = L2_2.lower
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  A1_2 = L2_2
  L2_2 = tAA
  L3_2 = {}
  L2_2[A0_2] = L3_2
  L2_2 = tAA
  L2_2 = L2_2[A0_2]
  L2_2.level = A1_2
  L2_2 = tAA
  L3_2 = tAA
  L3_2 = L3_2[A1_2]
  L3_2 = L3_2 + 1
  L2_2[A1_2] = L3_2
  L2_2 = {}
  L3_2 = {}
  L3_2.texture = "radar_AA"
  L3_2.offset = 0
  L2_2.basic = L3_2
  L3_2 = {}
  L3_2.texture = "radar_SAM"
  L3_2.offset = 36
  L2_2.medium = L3_2
  L3_2 = {}
  L3_2.texture = "radar_SAM"
  L3_2.offset = 0
  L2_2.advanced = L3_2
  L3_2 = {}
  L3_2.texture = "radar_Jammer"
  L3_2.offset = 72
  L2_2.jammer = L3_2
  tRadarTextures = L2_2
end

AddAntiAir = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = tAA
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = _RemoveBlipCallback
    L2_2 = tostring
    L3_2 = A0_2
    L2_2, L3_2 = L2_2(L3_2)
    L1_2(L2_2, L3_2)
    L1_2 = tAA
    L1_2 = L1_2[A0_2]
    L1_2 = L1_2.level
    L2_2 = tAA
    L3_2 = tAA
    L3_2 = L3_2[L1_2]
    L3_2 = L3_2 - 1
    L2_2[L1_2] = L3_2
    L2_2 = tAA
    L2_2[A0_2] = nil
  end
end

RemoveAntiAir = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  if A0_2 == nil or A0_2 == "none" then
    return
  end
  L1_2 = string
  L1_2 = L1_2.lower
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  A0_2 = L1_2
  L1_2 = tAA
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = tAA
    L1_2 = L1_2[A0_2]
    if 0 < L1_2 then
      return A0_2
  end
  elseif A0_2 == "basic" then
    L1_2 = TestAALevel
    L2_2 = "medium"
    return L1_2(L2_2)
  else
    return
  end
end

TestAALevel = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  if A0_2 == "aa" then
    L1_2 = "[PDA.Support.denied.basic]"
    L2_2 = PlayRandomVOCue
    L3_2 = {}
    L4_2 = "Fiona.541168fio"
    L5_2 = "Fiona.541169fio"
    L6_2 = "Fiona.541170fio"
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L2_2(L3_2)
  elseif A0_2 == "jammer" then
    L1_2 = "[PDA.Support.denied.jammer]"
    L2_2 = PlayRandomVOCue
    L3_2 = {}
    L4_2 = "Fiona.Support.Jammed01"
    L3_2[1] = L4_2
    L2_2(L3_2)
  elseif A0_2 == "nodrop" then
    L1_2 = "[PDA.Support.denied.dropzone]"
  elseif A0_2 == "nomunitions" then
    L1_2 = "[PDA.Support.denied.nomunitions]"
  elseif A0_2 == "abortnodrop" then
    L1_2 = "[PDA.Support.denied.dropzone]"
  elseif A0_2 == "abortdamage" then
    L1_2 = "[PDA.Support.denied.damaged]"
  elseif A0_2 == "toomanysoldiersnil" then
    L1_2 = "[PDA.Support.denied.toomanysoldiers]"
  elseif A0_2 == "noland" then
    L1_2 = "[PDA.Support.denied.landingzone]"
  elseif A0_2 == "oilcon002_toofar" then
    L1_2 = "[PDA.Support.denied.unclear]"
    L2_2 = MrxVoSequence
    L2_2 = L2_2.Start
    L3_2 = "Fiona-In-Mission-Contract-Oil02-95"
    L4_2 = nil
    L5_2 = MrxVoSequence
    L5_2 = L5_2.knPriorityFreeplay
    L2_2(L3_2, L4_2, L5_2)
  elseif A0_2 == "toomanysoldiersnil" then
    L1_2 = "[PDA.Support.denied.toomanysoldiers]"
  elseif A0_2 == "toomanysoldiersAllied" then
    L1_2 = "[PDA.Support.denied.toomanysoldiersAllied]"
  elseif A0_2 == "toomanysoldiersChina" then
    L1_2 = "[PDA.Support.denied.toomanysoldiersChina]"
  elseif A0_2 == "toomanysoldiersGuerilla" then
    L1_2 = "[PDA.Support.denied.toomanysoldiersGuerilla]"
  elseif A0_2 == "toomanysoldiersOC" then
    L1_2 = "[PDA.Support.denied.toomanysoldiersOC]"
  elseif A0_2 == "toomanysoldiersPirate" then
    L1_2 = "[PDA.Support.denied.toomanysoldiersPirate]"
  elseif A0_2 == "fuel" then
    L1_2 = "[PDA.Support.denied.fuel]"
  end
  if L1_2 then
    L2_2 = Hud
    L2_2 = L2_2.MessageBox
    L3_2 = L2_2
    L2_2 = L2_2.AddMessage
    L4_2 = {}
    L5_2 = "[red][PDA.Support.denied.denied] "
    L6_2 = L1_2
    L5_2 = L5_2 .. L6_2
    L4_2.sMessage = L5_2
    L4_2.nDuration = 4
    L2_2(L3_2, L4_2)
  end
end

DenialMessage = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = dynamic_import
  L2_2 = A0_2
  L1_2(L2_2)
end

SynchNetImportModule = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2, A9_2, A10_2, A11_2, A12_2)
  local L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L13_2 = tRemoteNetObjects
  L13_2 = L13_2[A1_2]
  if not L13_2 then
    L13_2 = tRemoteNetObjects
    L15_2 = A0_2
    L14_2 = A0_2.Create
    L16_2 = A7_2
    L14_2 = L14_2(L15_2, L16_2)
    L13_2[A1_2] = L14_2
  end
  if A8_2 then
    L13_2 = tRemoteNetObjects
    L13_2 = L13_2[A1_2]
    L14_2 = L13_2
    L13_2 = L13_2.SetCargoGuid
    L15_2 = A8_2
    L13_2(L14_2, L15_2)
  end
  if A9_2 then
    L13_2 = tRemoteNetObjects
    L13_2 = L13_2[A1_2]
    L14_2 = L13_2
    L13_2 = L13_2.SetFinalDestination
    L15_2 = A9_2
    L13_2(L14_2, L15_2)
  end
  if A10_2 then
    L13_2 = tRemoteNetObjects
    L13_2 = L13_2[A1_2]
    L13_2.uDeliveryVehicle = A10_2
  end
  if A11_2 then
    L13_2 = tRemoteNetObjects
    L13_2 = L13_2[A1_2]
    L13_2.uBomb = A11_2
  end
  L13_2 = tRemoteNetObjects
  L13_2 = L13_2[A1_2]
  L13_2 = L13_2.oDesignator
  if L13_2 then
    L13_2 = tRemoteNetObjects
    L13_2 = L13_2[A1_2]
    L13_2 = L13_2.oDesignator
    L14_2 = L13_2
    L13_2 = L13_2.SetDesignationParameters
    L15_2 = A2_2
    L16_2 = A3_2
    L17_2 = A4_2
    L18_2 = A5_2
    L19_2 = A6_2
    L13_2(L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
    L13_2 = tRemoteNetObjects
    L13_2 = L13_2[A1_2]
    L13_2 = L13_2.oDesignator
    L13_2.bDesignationComplete = true
  end
  if A12_2 then
    L13_2 = Event
    L13_2 = L13_2.Post
    L14_2 = "Airstrike"
    L15_2 = {}
    L15_2.sStage = "DesignationComplete"
    L15_2.sType = "None"
    L13_2(L14_2, L15_2)
  end
  L13_2 = tRemoteNetObjects
  L13_2 = L13_2[A1_2]
  L14_2 = L13_2
  L13_2 = L13_2.DesignationCallback
  L13_2(L14_2)
end

SynchNetAction = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L5_2 = tLocalNetObjects
  L5_2 = L5_2[A1_2]
  if not L5_2 then
    L5_2 = tLocalNetObjects
    L7_2 = A0_2
    L6_2 = A0_2.Create
    L8_2 = Player
    L8_2 = L8_2.GetLocalPlayer
    L8_2, L9_2, L10_2, L11_2 = L8_2()
    L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
    L5_2[A1_2] = L6_2
  end
  L5_2 = MrxGui
  L5_2 = L5_2.GetWidgetByNameAndOwner
  L6_2 = "Support Menu"
  L7_2 = Player
  L7_2 = L7_2.GetLocalPlayer
  L7_2, L8_2, L9_2, L10_2, L11_2 = L7_2()
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  if L5_2 then
    L7_2 = L5_2
    L6_2 = L5_2.Open
    L6_2(L7_2)
    L7_2 = L5_2
    L6_2 = L5_2.AddItem
    L8_2 = {}
    L8_2.sName = A2_2
    L8_2.sIcon = A3_2
    L8_2.sLitIcon = A4_2
    L9_2 = tLocalNetObjects
    L9_2 = L9_2[A1_2]
    L8_2.oSupport = L9_2
    L6_2(L7_2, L8_2)
    L6_2 = Event
    L6_2 = L6_2.Create
    L7_2 = Event
    L7_2 = L7_2.TimerRelative
    L8_2 = {}
    L9_2 = 1
    L8_2[1] = L9_2
    L9_2 = L5_2.Close
    L10_2 = {}
    L11_2 = L5_2
    L10_2[1] = L11_2
    L6_2(L7_2, L8_2, L9_2, L10_2)
  end
end

SynchNetAddItem = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = MrxGui
  L1_2 = L1_2.GetWidgetByNameAndOwner
  L2_2 = "Support Menu"
  L3_2 = Player
  L3_2 = L3_2.GetLocalPlayer
  L3_2, L4_2 = L3_2()
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  if L1_2 then
    L3_2 = L1_2
    L2_2 = L1_2.RemoveItem
    L4_2 = A0_2
    L2_2(L3_2, L4_2)
  end
end

SynchNetRemoveItem = L0_1

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
  if "string" ~= L2_2 then
    return
  end
  A0_2.sDeliveryVehicle = A1_2
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  A0_2.uDeliveryVehicle = L2_2
end

SetDeliveryVehicle = L0_1

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
  if "string" ~= L2_2 then
    return
  end
  A0_2.sBomb = A1_2
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  A0_2.uBomb = L2_2
end

SetBomb = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.nFuelConsumed
  if L1_2 then
    L1_2 = MrxPmc
    L1_2 = L1_2.AddFuelQty
    L2_2 = A0_2.nFuelConsumed
    L1_2(L2_2)
    A0_2.nFuelConsumed = nil
  end
  L1_2 = A0_2.sStockpileConsumed
  if L1_2 then
    L1_2 = MrxPmc
    L1_2 = L1_2.AddSupportQty
    L2_2 = A0_2.sStockpileConsumed
    L3_2 = 1
    L1_2(L2_2, L3_2)
    A0_2.sStockpileConsumed = nil
  end
  L1_2 = A0_2.sFreebieConsumed
  if L1_2 then
    L1_2 = MrxPmc
    L1_2 = L1_2.AddFreebieQty
    L2_2 = A0_2.sFreebieConsumed
    L3_2 = 1
    L1_2(L2_2, L3_2)
    A0_2.sFreebieConsumed = nil
  end
end

RefundCosts = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = Ai
  L3_2 = L3_2.SetPriorityTarget
  L4_2 = A1_2
  L3_2(L4_2)
  L4_2 = A0_2
  L3_2 = A0_2.GetRecruit
  L3_2 = L3_2(L4_2)
  if L3_2 == "Copter" then
    L3_2 = Event
    L3_2 = L3_2.Create
    L4_2 = Event
    L4_2 = L4_2.ScriptEvent
    L5_2 = {}
    L6_2 = "RecruitAvailable"
    
    function L7_2(A0_3)
      local L1_3
      if A0_3 then
        L1_3 = A0_3[1]
        if L1_3 == "Copter" then
          L1_3 = true
          return L1_3
        end
      end
    end
    
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L6_2 = FadeOut
    L7_2 = {}
    L8_2 = A1_2
    L7_2[1] = L8_2
    L3_2(L4_2, L5_2, L6_2, L7_2)
  end
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectHealth
  L5_2 = {}
  L6_2 = A1_2
  L7_2 = "<"
  L8_2 = Object
  L8_2 = L8_2.GetHealth
  L9_2 = A1_2
  L8_2 = L8_2(L9_2)
  L8_2 = L8_2 * 0.6
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L6_2 = Abort
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A1_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  return L3_2(L4_2, L5_2, L6_2, L7_2)
end

SetupDamageEvent = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L3_2 = A0_2.bSupportAborted
  if L3_2 then
    return
  else
    A0_2.bSupportAborted = true
  end
  L3_2 = Object
  L3_2 = L3_2.DetachCargoFromWinch
  L4_2 = A0_2.uHeli
  L3_2(L4_2)
  if not A2_2 then
    L3_2 = A0_2.bSupportComplete
    if not L3_2 then
      L3_2 = Hud
      L3_2 = L3_2.MessageBox
      L4_2 = L3_2
      L3_2 = L3_2.AddMessage
      L5_2 = {}
      L5_2.sMessage = "[red][PDA.Support.denied.damaged]"
      L5_2.nDuration = 4
      L3_2(L4_2, L5_2)
    end
  end
  if A2_2 and A2_2 == "NoMunitions" then
    L3_2 = Hud
    L3_2 = L3_2.MessageBox
    L4_2 = L3_2
    L3_2 = L3_2.AddMessage
    L5_2 = {}
    L5_2.sMessage = "[red][PDA.Support.denied.notarget]"
    L5_2.nDuration = 4
    L3_2(L4_2, L5_2)
  else
    L3_2 = {}
    L4_2 = {}
    L5_2 = "Ewan.Support.Denial10"
    L6_2 = "Ewan.Support.Denial11"
    L7_2 = "Ewan.Support.Denial12"
    L8_2 = "Ewan.Support.Denial10"
    L9_2 = "Ewan.Support.Denial11"
    L10_2 = "Ewan.Support.Denial12"
    L11_2 = {}
    L12_2 = "Fiona.Support.Denial01"
    L13_2 = 0
    L14_2 = "Ewan.Support.Denial03"
    L15_2 = 1
    L16_2 = {}
    L16_2.jennifer = "Jen.Support.Denial01"
    L16_2.chris = "Chris.Support.Denial01"
    L16_2.mattias = "Mattias.Support.Denial01"
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L11_2[3] = L14_2
    L11_2[4] = L15_2
    L11_2[5] = L16_2
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L4_2[3] = L7_2
    L4_2[4] = L8_2
    L4_2[5] = L9_2
    L4_2[6] = L10_2
    L4_2[7] = L11_2
    L3_2.PMC = L4_2
    L4_2 = {}
    L5_2 = "AlliedSoldier01.Support.Denied01"
    L4_2[1] = L5_2
    L3_2.Allied = L4_2
    L4_2 = {}
    L5_2 = "ChinaSoldier01.Support.Denied01"
    L4_2[1] = L5_2
    L3_2.China = L4_2
    L4_2 = {}
    L5_2 = "GurSoldier01.Support.Denied01"
    L4_2[1] = L5_2
    L3_2.Guerilla = L4_2
    L4_2 = {}
    L5_2 = "OCSoldier01.Support.Denied01"
    L4_2[1] = L5_2
    L3_2.OC = L4_2
    L4_2 = {}
    L5_2 = "Fiona.PirateCoverage.Reinforcements01"
    L4_2[1] = L5_2
    L3_2.Pirate = L4_2
    tVO = L3_2
    L3_2 = MrxUtil
    L3_2 = L3_2.GetFaction
    L4_2 = A1_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L4_2 = tVO
      L4_2 = L4_2[L3_2]
      if L4_2 then
        L4_2 = PlayRandomVOCue
        L5_2 = tVO
        L5_2 = L5_2[L3_2]
        L4_2(L5_2)
      end
    end
    if L3_2 == "PMC" then
      L4_2 = Object
      L4_2 = L4_2.GetHealth
      L5_2 = A1_2
      L4_2 = L4_2(L5_2)
      L5_2 = Object
      L5_2 = L5_2.GetMaxHealth
      L6_2 = A1_2
      L5_2 = L5_2(L6_2)
      L6_2 = L4_2 * 200
      L6_2 = L5_2 - L6_2
      L7_2 = MrxPmc
      L7_2 = L7_2.AddCashQty
      L8_2 = L6_2
      L9_2 = true
      L10_2 = "[Generic.CopterRepair]"
      L7_2(L8_2, L9_2, L10_2)
    end
  end
  L3_2 = GoHome
  L4_2 = A0_2
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
end

Abort = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.ObjectDeath
  L6_2 = {}
  L7_2 = L3_2
  L6_2[1] = L7_2
  L7_2 = Abandon
  L8_2 = {}
  L9_2 = A0_2
  L10_2 = A1_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
end

SetupPilotKilledEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = Object
  L2_2 = L2_2.DetachCargoFromWinch
  L3_2 = A1_2
  L2_2(L3_2)
  L2_2 = sFaction
  if L2_2 == "PMC" then
    L2_2 = 0
  end
  A0_2.bSupportComplete = true
  L2_2 = MrxSupportManager
  L2_2 = L2_2.MakeRecruitAvailable
  L3_2 = "Copter"
  L2_2(L3_2)
end

Abandon = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  A0_2.bSupportComplete = true
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L4_2 = Object
    L4_2 = L4_2.IsAlive
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      L4_2 = nil
      L5_2 = nil
      L6_2 = nil
      L7_2 = {}
      L7_2.PMC = "01_pmc_hq_lz_playerone"
      L7_2.Allied = "07_all_hq_lz_playerone"
      L7_2.China = "12_chi_hq_lz_playerone"
      L7_2.Guerilla = "05_gur_hq_lz_playerone"
      L7_2.OC = "02_oil_hq_lz_playerone"
      L7_2.Pirate = "08_pir_hq_lz_playerone"
      tLocs = L7_2
      L7_2 = MrxUtil
      L7_2 = L7_2.GetFaction
      L8_2 = A1_2
      L7_2 = L7_2(L8_2)
      L8_2 = nil
      if L7_2 then
        L9_2 = tLocs
        L9_2 = L9_2[L7_2]
        if L9_2 then
          L9_2 = Pg
          L9_2 = L9_2.GetGuidByName
          L10_2 = tLocs
          L10_2 = L10_2[L7_2]
          L9_2 = L9_2(L10_2)
          L8_2 = L9_2
          if L8_2 then
            L9_2 = Object
            L9_2 = L9_2.GetDistanceFrom
            L10_2 = A1_2
            L11_2 = L8_2
            L9_2 = L9_2(L10_2, L11_2)
            if 20 < L9_2 then
              L9_2 = Object
              L9_2 = L9_2.GetPosition
              L10_2 = L8_2
              L9_2, L10_2, L11_2 = L9_2(L10_2)
              L6_2 = L11_2
              L5_2 = L10_2
              L4_2 = L9_2
            else
              L9_2 = Pg
              L9_2 = L9_2.FindPointFromCamera
              L10_2 = -600
              L11_2 = 200
              L12_2 = -1
              L9_2, L10_2, L11_2 = L9_2(L10_2, L11_2, L12_2)
              L6_2 = L11_2
              L5_2 = L10_2
              L4_2 = L9_2
            end
          end
        end
      end
      if not L8_2 then
        L9_2 = Pg
        L9_2 = L9_2.FindPointFromCamera
        L10_2 = -300
        L11_2 = 25
        L9_2, L10_2, L11_2 = L9_2(L10_2, L11_2)
        L6_2 = L11_2
        L5_2 = L10_2
        L4_2 = L9_2
      end
      if L4_2 then
        L9_2 = Ai
        L9_2 = L9_2.Goal
        L10_2 = {}
        L10_2.AIGuid = L3_2
        L10_2.Goal = "MoveTo"
        L11_2 = {}
        L12_2 = L4_2
        L13_2 = L5_2 + 30
        L14_2 = L6_2
        L11_2[1] = L12_2
        L11_2[2] = L13_2
        L11_2[3] = L14_2
        L10_2.Location = L11_2
        L10_2.Priority = "hiPri"
        L11_2 = Land
        L10_2.Callback = L11_2
        L11_2 = {}
        L12_2 = A0_2
        L13_2 = A1_2
        L14_2 = L4_2
        L15_2 = L5_2
        L16_2 = L6_2
        L17_2 = A2_2
        L11_2[1] = L12_2
        L11_2[2] = L13_2
        L11_2[3] = L14_2
        L11_2[4] = L15_2
        L11_2[5] = L16_2
        L11_2[6] = L17_2
        L10_2.CallbackData = L11_2
        L10_2.Force = true
        L9_2 = L9_2(L10_2)
        uGoal = L9_2
      else
      end
      L9_2 = Event
      L9_2 = L9_2.Create
      L10_2 = Event
      L10_2 = L10_2.ObjectHibernation
      L11_2 = {}
      L12_2 = A1_2
      L13_2 = "hibernated"
      L11_2[1] = L12_2
      L11_2[2] = L13_2
      L12_2 = Object
      L12_2 = L12_2.Remove
      L13_2 = {}
      L14_2 = A1_2
      L13_2[1] = L14_2
      L9_2(L10_2, L11_2, L12_2, L13_2)
      L9_2 = Event
      L9_2 = L9_2.Create
      L10_2 = Event
      L10_2 = L10_2.ObjectDelete
      L11_2 = {}
      L12_2 = A1_2
      L11_2[1] = L12_2
      L12_2 = MrxSupportManager
      L12_2 = L12_2.MakeRecruitAvailable
      L13_2 = {}
      L14_2 = "Copter"
      L13_2[1] = L14_2
      L9_2(L10_2, L11_2, L12_2, L13_2)
      if A2_2 then
        L9_2 = Event
        L9_2 = L9_2.Create
        L10_2 = Event
        L10_2 = L10_2.ObjectHibernation
        L11_2 = {}
        L12_2 = A2_2
        L13_2 = "hibernated"
        L11_2[1] = L12_2
        L11_2[2] = L13_2
        L12_2 = Object
        L12_2 = L12_2.Remove
        L13_2 = {}
        L14_2 = A2_2
        L13_2[1] = L14_2
        L9_2(L10_2, L11_2, L12_2, L13_2)
      end
    end
  end
end

GoHome = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L6_2 = Vehicle
  L6_2 = L6_2.GetDriver
  L7_2 = A1_2
  L6_2 = L6_2(L7_2)
  if A5_2 then
    L7_2 = Object
    L7_2 = L7_2.IsWinched
    L8_2 = A5_2
    L7_2 = L7_2(L8_2)
    if L7_2 then
      L7_2 = Object
      L7_2 = L7_2.FadeOut
      L8_2 = A5_2
      L9_2 = 1
      L10_2 = true
      L7_2(L8_2, L9_2, L10_2)
    end
  end
  if L6_2 then
    L7_2 = Object
    L7_2 = L7_2.IsAlive
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    if L7_2 then
      L7_2 = Ai
      L7_2 = L7_2.Goal
      L8_2 = {}
      L8_2.AIGuid = L6_2
      L8_2.Goal = "HeliLand"
      L9_2 = {}
      L10_2 = A2_2
      L11_2 = A3_2
      L12_2 = A4_2
      L9_2[1] = L10_2
      L9_2[2] = L11_2
      L9_2[3] = L12_2
      L8_2.Location = L9_2
      L8_2.Priority = "hiPri"
      L8_2.force = true
      L9_2 = FadeOut
      L8_2.Callback = L9_2
      L9_2 = {}
      L10_2 = A1_2
      L9_2[1] = L10_2
      L8_2.CallbackData = L9_2
      L7_2 = L7_2(L8_2)
  end
  else
    L7_2 = FadeOut
    L8_2 = A1_2
    L7_2(L8_2)
  end
end

Land = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = Object
  L2_2 = L2_2.IsValid
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L2_2 = Vehicle
  L2_2 = L2_2.GetDriver
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  if L2_2 then
    L3_2 = Object
    L3_2 = L3_2.HasLabel
    L4_2 = L2_2
    L5_2 = "Hero"
    L3_2 = L3_2(L4_2, L5_2)
    if L3_2 then
      return
    end
  end
  L3_2 = Object
  L3_2 = L3_2.DetachCargoFromWinch
  L4_2 = A0_2
  L3_2(L4_2)
  L3_2 = Ai
  L3_2 = L3_2.Deploy
  L4_2 = {}
  L4_2.Vehicle = A0_2
  L4_2.Role = "Passenger"
  L4_2.Force = true
  L3_2(L4_2)
  L3_2 = Object
  L3_2 = L3_2.FadeOut
  L4_2 = A0_2
  L5_2 = 2
  L6_2 = true
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L3_2 = Object
    L3_2 = L3_2.FadeOut
    L4_2 = Vehicle
    L4_2 = L4_2.GetDriver
    L5_2 = A0_2
    L4_2 = L4_2(L5_2)
    L5_2 = 2
    L6_2 = true
    L3_2(L4_2, L5_2, L6_2)
  end
end

FadeOut = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = {}
  L2_2.PMC = A1_2
  L3_2 = {}
  L4_2 = "AlliedSoldier01.Support.Incoming01"
  L5_2 = "AlliedSoldier01.Support.Incoming02"
  L6_2 = "AlliedSoldier01.Support.Incoming03"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L2_2.Allied = L3_2
  L3_2 = {}
  L4_2 = "ChinaSoldier01.Support.Incoming01"
  L5_2 = "ChinaSoldier01.Support.Incoming02"
  L6_2 = "ChinaSoldier01.Support.Incoming03"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L2_2.China = L3_2
  L3_2 = {}
  L4_2 = "VZSoldier01.Support.Air01"
  L3_2[1] = L4_2
  L2_2.VZ = L3_2
  L3_2 = {}
  L4_2 = "GurSoldier01.Support.Incoming01"
  L5_2 = "GurSoldier01.Support.Incoming02"
  L6_2 = "GurSoldier01.Support.Incoming03"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L2_2.Guerilla = L3_2
  L3_2 = {}
  L4_2 = "OCSoldier01.Support.Incoming01"
  L5_2 = "OCSoldier01.Support.Incoming02"
  L6_2 = "OCSoldier01.Support.Incoming03"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L2_2.OC = L3_2
  tVOOnTheWay = L2_2
  L2_2 = MrxUtil
  L2_2 = L2_2.GetFaction
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = tVOOnTheWay
    L3_2 = L3_2[L2_2]
    if L3_2 then
      L3_2 = PlayRandomVOCue
      L4_2 = tVOOnTheWay
      L4_2 = L4_2[L2_2]
      L5_2 = false
      L3_2(L4_2, L5_2)
    else
    end
  end
end

PlayAirstrikeVO = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = Player
  L0_2 = L0_2.GetSecondaryCharacter
  L0_2 = L0_2()
  if L0_2 then
    L0_2 = 250
    return L0_2
  else
    L0_2 = 50
    return L0_2
  end
end

GetSpawnHeight = L0_1
