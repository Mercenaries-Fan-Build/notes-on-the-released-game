local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxSupportDesignator"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  if not A1_2 then
    L2_2 = {}
    A1_2 = L2_2
  end
  L2_2 = A0_2.uOwner
  A1_2.uOwner = L2_2
  A1_2.bDesignateOnDeath = false
  L2_2 = A0_2.bDesignationComplete
  A1_2.bDesignationComplete = L2_2
  A1_2.sDesignationType = "Beacon Designator"
  A1_2.fValidationFunction = nil
  L2_2 = {}
  A1_2.tCallbackList = L2_2
  A1_2.sAATestLevel = "jammer"
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

function L0_1(A0_2)
  local L1_2
  L1_2 = "beacon"
  return L1_2
end

GetType = L0_1
