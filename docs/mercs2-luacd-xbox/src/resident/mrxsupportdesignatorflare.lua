local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxSupportDesignator"
L0_1(L1_1)

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = Pg
  L0_2 = L0_2.LoadAsset
  L1_2 = "global_weapon_sw500"
  L2_2 = "model"
  L0_2(L1_2, L2_2)
end

Init = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = Pg
  L0_2 = L0_2.UnloadAsset
  L1_2 = "global_weapon_sw500"
  L2_2 = "model"
  L0_2(L1_2, L2_2)
end

Deinit = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  if not A1_2 then
    L2_2 = {}
    A1_2 = L2_2
  end
  L2_2 = A0_2.uOwner
  A1_2.uOwner = L2_2
  A1_2.bDesignateOnDeath = true
  L2_2 = A0_2.bDesignationComplete
  A1_2.bDesignationComplete = L2_2
  A1_2.sDesignationType = "Flare Designator"
  L2_2 = MrxSupportDesignator
  L2_2 = L2_2.ValidateWaterDropZone
  A1_2.fValidationFunction = L2_2
  L2_2 = {}
  A1_2.tCallbackList = L2_2
  A1_2.sAATestLevel = "none"
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
  L3_2 = A1_2
  L2_2 = A1_2.AddCompleteCallback
  L4_2 = DesignationCompleteCallback
  L5_2 = {}
  L6_2 = A1_2
  L5_2[1] = L6_2
  L2_2(L3_2, L4_2, L5_2)
  return A1_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = A0_2.uGuid
  if L1_2 then
    L1_2 = Object
    L1_2 = L1_2.GetPosition
    L2_2 = A0_2.uGuid
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    if L1_2 and L2_2 and L3_2 then
      L4_2 = Airstrike
      L4_2 = L4_2.SpawnOrdnance
      L5_2 = "Flare Projectile Stage 2"
      L6_2 = L1_2
      L7_2 = L2_2
      L8_2 = L3_2
      L9_2 = 0
      L10_2 = -2
      L11_2 = 0
      L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
    end
  end
end

DesignationCompleteCallback = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = "flare"
  return L1_2
end

GetType = L0_1
