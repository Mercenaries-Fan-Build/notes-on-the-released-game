local L0_1, L1_1, L2_1, L3_1
L0_1 = inherit
L1_1 = "MrxDaisyCutter"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorSmoke"
L0_1(L1_1)
L0_1 = "MOAB Projectile"
L1_1 = "Explosion (MOAB)"
L2_1 = "Support Vehicle (C130)"

function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = {}
  L3_2 = setmetatable
  L4_2 = L2_2
  L5_2 = A0_2
  L3_2(L4_2, L5_2)
  A0_2.__index = A0_2
  L3_2 = MrxSupportDesignatorSmoke
  L4_2 = L3_2
  L3_2 = L3_2.Create
  L3_2 = L3_2(L4_2)
  oDesignator = L3_2
  L3_2 = oDesignator
  L4_2 = L3_2
  L3_2 = L3_2.SetValidationFunction
  L5_2 = _NoValidation
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetDesignator
  L5_2 = oDesignator
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetOwner
  L5_2 = A1_2
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetRecruit
  L5_2 = "Fiona"
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.SetModuleName
  L5_2 = "MrxMOAB"
  L3_2(L4_2, L5_2)
  L3_2 = L2_1
  L2_2.sDeliveryVehicle = L3_2
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = L2_1
  L3_2 = L3_2(L4_2)
  L2_2.uDeliveryVehicle = L3_2
  L3_2 = L0_1
  L2_2.sBomb = L3_2
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = L0_1
  L3_2 = L3_2(L4_2)
  L2_2.uBomb = L3_2
  return L2_2
end

Create = L3_1
