local L0_1, L1_1, L2_1, L3_1, L4_1
L0_1 = inherit
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorBeacon"
L0_1(L1_1)
L0_1 = "Strategic Missile Projectile"
L1_1 = "Strategic Missile Projectile Launch"
L2_1 = "Strategic Missile Shrapnel"
L3_1 = "Explosion (Strategic Missile)"

function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = {}
  L3_2 = setmetatable
  L4_2 = L2_2
  L5_2 = A0_2
  L3_2(L4_2, L5_2)
  A0_2.__index = A0_2
  L3_2 = MrxSupportDesignatorBeacon
  L4_2 = L3_2
  L3_2 = L3_2.Create
  L3_2 = L3_2(L4_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetDesignator
  L6_2 = L3_2
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetOwner
  L6_2 = A1_2
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetRecruit
  L6_2 = "Fiona"
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetModuleName
  L6_2 = "MrxStrategicMissile"
  L4_2(L5_2, L6_2)
  return L2_2
end

Create = L4_1

function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = MrxUtil
  L3_2 = L3_2.GetRandomTableElement
  L4_2 = {}
  L5_2 = "ChinaSoldier01.Support.Artillery01"
  L6_2 = "ChinaSoldier01.Support.Incoming01"
  L7_2 = "ChinaSoldier01.Support.Incoming02"
  L8_2 = "ChinaSoldier01.Support.Incoming03"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L3_2 = L3_2(L4_2)
  L4_2 = {}
  L5_2 = MissileLaunch
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = nil
  L4_2 = MrxVoSequence
  L4_2 = L4_2.knPriorityFreeplay
  L5_2 = false
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

DesignationCallback = L4_1

function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L1_2 = Pg
  L1_2 = L1_2.FindPointFromCamera
  L2_2 = 150
  L3_2 = 10
  L4_2 = -1
  L5_2 = A0_2.uOwner
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  L4_2 = Airstrike
  L4_2 = L4_2.SpawnOrdnance
  L5_2 = L1_1
  L6_2 = L1_2
  L7_2 = L2_2
  L8_2 = L3_2
  L9_2 = 0
  L10_2 = 100
  L11_2 = 0
  L12_2 = "distance"
  L13_2 = 500
  L14_2 = A0_2.uOwner
  L15_2 = ActivateDelay
  L16_2 = {}
  L17_2 = A0_2
  L16_2[1] = L17_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
end

MissileLaunch = L4_1

function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 2
  L4_2[1] = L5_2
  L5_2 = A0_2.DropBomb
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
end

ActivateDelay = L4_1

function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L2_2 = A0_2
  L1_2 = A0_2.GetDesignator
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2
  L1_2 = L1_2.GetTarget
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  L2_2 = L2_2 + 100
  L5_2 = Airstrike
  L5_2 = L5_2.SpawnOrdnance
  L6_2 = L0_1
  L7_2 = L1_2
  L8_2 = L2_2
  L9_2 = L3_2
  L10_2 = 0
  L11_2 = -100
  L12_2 = 0
  L13_2 = "distance"
  L14_2 = 80
  L15_2 = A0_2.uOwner
  L16_2 = BombExplodes
  L17_2 = {}
  L18_2 = A0_2
  L17_2[1] = L18_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  A0_2.uSpawnedBomb = L5_2
end

DropBomb = L4_1

function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = A0_2.uSpawnedBomb
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  L5_2 = A0_2
  L4_2 = A0_2.GetDesignator
  L4_2 = L4_2(L5_2)
  L5_2 = L4_2
  L4_2 = L4_2.GetTarget
  L4_2, L5_2, L6_2, L7_2, L8_2 = L4_2(L5_2)
  L9_2 = Pg
  L9_2 = L9_2.Spawn
  L10_2 = L3_1
  L11_2 = L1_2
  L12_2 = L2_2
  L13_2 = L3_2
  L9_2(L10_2, L11_2, L12_2, L13_2)
  L9_2 = Object
  L9_2 = L9_2.Kill
  L10_2 = A0_2.uSpawnedBomb
  L9_2(L10_2)
  if L7_2 then
    L9_2 = Player
    L9_2 = L9_2.IsLocal
    L10_2 = A0_2.uOwner
    L9_2 = L9_2(L10_2)
    if L9_2 then
      L9_2 = Object
      L9_2 = L9_2.Remove
      L10_2 = L7_2
      L9_2(L10_2)
    end
  end
  L9_2 = Airstrike
  L9_2 = L9_2.ConeSpawn
  L10_2 = L2_1
  L11_2 = L1_2
  L12_2 = L2_2
  L13_2 = L3_2
  L14_2 = L4_2 - L1_2
  L15_2 = L5_2 - L2_2
  L16_2 = L6_2 - L3_2
  L17_2 = 5
  L18_2 = 20
  L19_2 = 2
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
  L9_2 = Airstrike
  L9_2 = L9_2.ConeSpawn
  L10_2 = L2_1
  L11_2 = L1_2
  L12_2 = L2_2
  L13_2 = L3_2
  L14_2 = L4_2 - L1_2
  L15_2 = L5_2 - L2_2
  L16_2 = L6_2 - L3_2
  L17_2 = 30
  L18_2 = 20
  L19_2 = 3
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
  L9_2 = Airstrike
  L9_2 = L9_2.ConeSpawn
  L10_2 = L2_1
  L11_2 = L1_2
  L12_2 = L2_2
  L13_2 = L3_2
  L14_2 = L4_2 - L1_2
  L15_2 = L5_2 - L2_2
  L16_2 = L6_2 - L3_2
  L17_2 = 45
  L18_2 = 20
  L19_2 = 3
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
  L9_2 = Airstrike
  L9_2 = L9_2.ConeSpawn
  L10_2 = L2_1
  L11_2 = L1_2
  L12_2 = L2_2
  L13_2 = L3_2
  L14_2 = L4_2 - L1_2
  L15_2 = L5_2 - L2_2
  L16_2 = L6_2 - L3_2
  L17_2 = 60
  L18_2 = 20
  L19_2 = 3
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
  L9_2 = Airstrike
  L9_2 = L9_2.ConeSpawn
  L10_2 = L2_1
  L11_2 = L1_2
  L12_2 = L2_2
  L13_2 = L3_2
  L14_2 = L4_2 - L1_2
  L15_2 = L5_2 - L2_2
  L16_2 = L6_2 - L3_2
  L17_2 = 75
  L18_2 = 20
  L19_2 = 3
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
  L9_2 = Airstrike
  L9_2 = L9_2.ConeSpawn
  L10_2 = L2_1
  L11_2 = L1_2
  L12_2 = L2_2
  L13_2 = L3_2
  L14_2 = L4_2 - L1_2
  L15_2 = L5_2 - L2_2
  L16_2 = L6_2 - L3_2
  L17_2 = 90
  L18_2 = 20
  L19_2 = 4
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
end

BombExplodes = L4_1
