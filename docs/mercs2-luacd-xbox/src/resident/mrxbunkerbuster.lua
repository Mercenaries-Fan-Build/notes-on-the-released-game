local L0_1, L1_1, L2_1, L3_1
L0_1 = inherit
L1_1 = "MrxLaserGuidedBomb"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorLaser"
L0_1(L1_1)
L0_1 = {}
L1_1 = "Misha-None-Freeplay-Support-02"
L2_1 = "Misha-None-Freeplay-Support-12"
L3_1 = "Misha-None-Freeplay-Support-20"
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
tVOCues = L0_1
L0_1 = "Bunker Buster Projectile"
sBomb = L0_1
L0_1 = Pg
L0_1 = L0_1.GetGuidByName
L1_1 = "Bunker Buster Projectile"
L0_1 = L0_1(L1_1)
uBomb = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = {}
  L3_2 = setmetatable
  L4_2 = L2_2
  L5_2 = A0_2
  L3_2(L4_2, L5_2)
  A0_2.__index = A0_2
  L3_2 = MrxSupportDesignatorLaser
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
  L6_2 = "Pilot"
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetModuleName
  L6_2 = "MrxBunkerBuster"
  L4_2(L5_2, L6_2)
  L4_2 = A0_2.sDeliveryVehicle
  L2_2.sDeliveryVehicle = L4_2
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = A0_2.uDeliveryVehicle
  L4_2 = L4_2(L5_2)
  L2_2.uDeliveryVehicle = L4_2
  L4_2 = A0_2.sBomb
  L2_2.sBomb = L4_2
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = A0_2.sBomb
  L4_2 = L4_2(L5_2)
  L2_2.uBomb = L4_2
  L4_2 = A0_2.tVOCues
  L2_2.tVOCues = L4_2
  L4_2 = A0_2.BombExplodes
  L2_2.BombExplodes = L4_2
  return L2_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = A0_2.uSpawnedBomb
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  L4_2 = Pg
  L4_2 = L4_2.Spawn
  L5_2 = "Explosion (Bunker Buster Stage 1)"
  L6_2 = L1_2
  L7_2 = L2_2
  L8_2 = L3_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = Object
  L4_2 = L4_2.Kill
  L5_2 = A0_2.uSpawnedBomb
  L4_2(L5_2)
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = 0.5
  L6_2[1] = L7_2
  L7_2 = GroundExplosion
  L8_2 = {}
  L9_2 = "20"
  L10_2 = "0.04"
  L11_2 = L1_2
  L12_2 = L2_2
  L13_2 = L3_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  L8_2[5] = L13_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = 1
  L6_2[1] = L7_2
  L7_2 = GroundExplosion
  L8_2 = {}
  L9_2 = "45"
  L10_2 = "0.04"
  L11_2 = L1_2
  L12_2 = L2_2
  L13_2 = L3_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  L8_2[5] = L13_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = 1.5
  L6_2[1] = L7_2
  L7_2 = GroundExplosion
  L8_2 = {}
  L9_2 = "65"
  L10_2 = "0.05"
  L11_2 = L1_2
  L12_2 = L2_2
  L13_2 = L3_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  L8_2[5] = L13_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = 2.75
  L6_2[1] = L7_2
  L7_2 = FinalExplosion
  L8_2 = {}
  L9_2 = A0_2
  L10_2 = L1_2
  L11_2 = L2_2
  L12_2 = L3_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
end

BombExplodes = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L4_2 = A0_2.uBomb
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "Bunker Buster Projectile"
  L5_2 = L5_2(L6_2)
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "Nuclear Bunker Buster Projectile"
  L6_2 = L6_2(L7_2)
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "Bunker Buster Projectile"
  L7_2 = L7_2(L8_2)
  if L4_2 == L7_2 then
    L7_2 = Pg
    L7_2 = L7_2.Spawn
    L8_2 = "Explosion (Bunker Buster Stage 2)"
    L9_2 = A1_2
    L10_2 = A2_2
    L11_2 = A3_2
    L7_2(L8_2, L9_2, L10_2, L11_2)
    L7_2 = Event
    L7_2 = L7_2.Create
    L8_2 = Event
    L8_2 = L8_2.TimerRelative
    L9_2 = {}
    L10_2 = 2
    L9_2[1] = L10_2
    L10_2 = AfterShock
    L11_2 = {}
    L12_2 = A0_2
    L13_2 = 50
    L14_2 = A1_2
    L15_2 = A2_2
    L16_2 = A3_2
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L11_2[3] = L14_2
    L11_2[4] = L15_2
    L11_2[5] = L16_2
    L7_2(L8_2, L9_2, L10_2, L11_2)
  else
    L7_2 = Pg
    L7_2 = L7_2.GetGuidByName
    L8_2 = "Nuclear Bunker Buster Projectile"
    L7_2 = L7_2(L8_2)
    if L4_2 == L7_2 then
      L7_2 = Pg
      L7_2 = L7_2.Spawn
      L8_2 = "global_particle_airstrike_tactnuke"
      L9_2 = A1_2
      L10_2 = A2_2
      L11_2 = A3_2
      L7_2(L8_2, L9_2, L10_2, L11_2)
      L7_2 = Event
      L7_2 = L7_2.Create
      L8_2 = Event
      L8_2 = L8_2.TimerRelative
      L9_2 = {}
      L10_2 = 1
      L9_2[1] = L10_2
      
      function L10_2()
        local L0_3, L1_3, L2_3, L3_3
        L0_3 = MrxUtil
        L0_3 = L0_3.SpawnObject
        L1_3 = "global_particle_exp_shockwave_ground_tactnuke"
        L2_3 = Pg
        L2_3 = L2_3.GetGuidByName
        L3_3 = "loc_shockwave"
        L2_3, L3_3 = L2_3(L3_3)
        L0_3(L1_3, L2_3, L3_3)
      end
      
      L7_2(L8_2, L9_2, L10_2)
      L7_2 = Event
      L7_2 = L7_2.Create
      L8_2 = Event
      L8_2 = L8_2.TimerRelative
      L9_2 = {}
      L10_2 = 2
      L9_2[1] = L10_2
      L10_2 = AfterShock
      L11_2 = {}
      L12_2 = A0_2
      L13_2 = 80
      L14_2 = A1_2
      L15_2 = A2_2
      L16_2 = A3_2
      L11_2[1] = L12_2
      L11_2[2] = L13_2
      L11_2[3] = L14_2
      L11_2[4] = L15_2
      L11_2[5] = L16_2
      L7_2(L8_2, L9_2, L10_2, L11_2)
      L7_2 = Event
      L7_2 = L7_2.Create
      L8_2 = Event
      L8_2 = L8_2.TimerRelative
      L9_2 = {}
      L10_2 = 2
      L9_2[1] = L10_2
      L10_2 = Event
      L10_2 = L10_2.Post
      L11_2 = {}
      L12_2 = "Nuked"
      L13_2 = {}
      L14_2 = A1_2
      L15_2 = A2_2
      L16_2 = A3_2
      L13_2[1] = L14_2
      L13_2[2] = L15_2
      L13_2[3] = L16_2
      L11_2[1] = L12_2
      L11_2[2] = L13_2
      L7_2(L8_2, L9_2, L10_2, L11_2)
    end
  end
end

FinalExplosion = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L5_2 = Graphics
  L5_2 = L5_2.Effect
  L5_2 = L5_2.Terrain
  L6_2 = "global_particle_exp_shockwave_ground_bunkerbuster"
  L7_2 = A0_2
  L8_2 = A1_2
  L9_2 = A2_2
  L10_2 = 0
  L11_2 = A4_2
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
end

GroundExplosion = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  if not A1_2 then
    A1_2 = 50
  end
  L5_2 = Event
  L5_2 = L5_2.Post
  L6_2 = "Busted"
  L7_2 = {}
  L8_2 = A2_2
  L9_2 = A3_2
  L10_2 = A4_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L5_2(L6_2, L7_2)
  L5_2 = Pg
  L5_2 = L5_2.FastCollectBuildings
  L6_2 = A2_2
  L7_2 = A3_2
  L8_2 = A4_2
  L9_2 = A1_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = pairs
  L7_2 = L5_2
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  for L9_2, L10_2 in L6_2, L7_2, L8_2 do
    L11_2 = math
    L11_2 = L11_2.randf
    L11_2 = L11_2()
    L11_2 = L11_2 * L9_2
    if 5 < L11_2 then
      L12_2 = math
      L12_2 = L12_2.randf
      L12_2 = L12_2()
      L11_2 = L12_2 * L11_2
    end
    L12_2 = Event
    L12_2 = L12_2.Create
    L13_2 = Event
    L13_2 = L13_2.TimerRelative
    L14_2 = {}
    L15_2 = L11_2
    L14_2[1] = L15_2
    L15_2 = Demolish
    L16_2 = {}
    L17_2 = L10_2
    L16_2[1] = L17_2
    L12_2(L13_2, L14_2, L15_2, L16_2)
  end
end

AfterShock = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  if L1_2 then
    L4_2 = Pg
    L4_2 = L4_2.Spawn
    L5_2 = "Explosion (Airstike Bomb Final Strike)"
    L6_2 = L1_2
    L7_2 = L2_2
    L8_2 = L3_2
    L4_2(L5_2, L6_2, L7_2, L8_2)
  end
end

Demolish = L0_1
