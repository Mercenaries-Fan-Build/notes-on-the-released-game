local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorSmoke"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorLaser"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorSatellite"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
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
  L5_2 = L3_2
  L4_2 = L3_2.SetValidationFunction
  L6_2 = nil
  L4_2(L5_2, L6_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetAATestLevel
  L6_2 = "basic"
  L4_2(L5_2, L6_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetTargetValidationRequired
  L6_2 = false
  L4_2(L5_2, L6_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetSmokeColor
  L6_2 = "red"
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
  L4_2 = L2_2.SetDesignator
  L6_2 = L3_2
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetModuleName
  L6_2 = "MrxFuelAirBomb"
  L4_2(L5_2, L6_2)
  L4_2 = A0_2.sDeliveryVehicle
  L2_2.sDeliveryVehicle = L4_2
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = A0_2.sDeliveryVehicle
  L4_2 = L4_2(L5_2)
  L2_2.uDeliveryVehicle = L4_2
  return L2_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2
  L1_2 = 0
  L2_2 = 20
  L3_2 = Pg
  L3_2 = L3_2.FindPointFromCamera
  L4_2 = 300
  L5_2 = 60
  L6_2 = -1
  L7_2 = A0_2.uOwner
  L3_2, L4_2, L5_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L6_2 = Pg
  L6_2 = L6_2.FindPointFromCamera
  L7_2 = 65
  L8_2 = 60
  L6_2, L7_2, L8_2 = L6_2(L7_2, L8_2)
  L10_2 = A0_2
  L9_2 = A0_2.GetDesignator
  L9_2 = L9_2(L10_2)
  L10_2 = L9_2
  L9_2 = L9_2.GetTarget
  L9_2, L10_2, L11_2 = L9_2(L10_2)
  L12_2 = L11_2 - L5_2
  L12_2 = L12_2 * -1
  L13_2 = L9_2 - L3_2
  L14_2 = Math
  L14_2 = L14_2.Normalize
  L15_2 = L12_2
  L16_2 = 0
  L17_2 = L13_2
  L14_2, L15_2, L16_2 = L14_2(L15_2, L16_2, L17_2)
  L14_2 = L14_2 * L1_2
  L16_2 = L16_2 * L1_2
  L17_2 = L3_2 - L9_2
  L18_2 = 0
  L19_2 = L5_2 - L11_2
  L20_2 = Math
  L20_2 = L20_2.Normalize
  L21_2 = L17_2
  L22_2 = 0
  L23_2 = L19_2
  L20_2, L21_2, L22_2 = L20_2(L21_2, L22_2, L23_2)
  L19_2 = L22_2
  L18_2 = L21_2
  L17_2 = L20_2
  L17_2 = L17_2 * L2_2
  L19_2 = L19_2 * L2_2
  L20_2 = Airstrike
  L20_2 = L20_2.Flyby
  L21_2 = A0_2.uDeliveryVehicle
  L22_2 = L3_2
  L23_2 = L5_2
  L24_2 = L6_2
  L25_2 = L8_2
  L26_2 = L7_2
  L27_2 = 200
  L28_2 = DropBomb
  L29_2 = {}
  L30_2 = A0_2
  L29_2[1] = L30_2
  L20_2 = L20_2(L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2)
  A0_2.uJet = L20_2
  L21_2 = MrxSupport
  L21_2 = L21_2.PlayAirstrikeVO
  L22_2 = L20_2
  L23_2 = {}
  L24_2 = "Misha-None-Freeplay-Support-06"
  L25_2 = "Misha-None-Freeplay-Support-07"
  L26_2 = "Misha-None-Freeplay-Support-16"
  L27_2 = "Misha-None-Freeplay-Support-24"
  L23_2[1] = L24_2
  L23_2[2] = L25_2
  L23_2[3] = L26_2
  L23_2[4] = L27_2
  L21_2(L22_2, L23_2)
end

DesignationCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = A0_2.uJet
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  L5_2 = A0_2
  L4_2 = A0_2.GetDesignator
  L4_2 = L4_2(L5_2)
  L5_2 = L4_2
  L4_2 = L4_2.GetTarget
  L4_2, L5_2, L6_2, L7_2, L8_2 = L4_2(L5_2)
  L9_2 = L4_2 - L1_2
  L10_2 = L5_2 - L2_2
  L11_2 = L6_2 - L3_2
  L12_2 = Math
  L12_2 = L12_2.Length
  L13_2 = L9_2
  L14_2 = L10_2
  L15_2 = L11_2
  L12_2 = L12_2(L13_2, L14_2, L15_2)
  L12_2 = L12_2 - 24
  L13_2 = Math
  L13_2 = L13_2.Normalize
  L14_2 = L9_2
  L15_2 = L10_2
  L16_2 = L11_2
  L13_2, L14_2, L15_2 = L13_2(L14_2, L15_2, L16_2)
  L11_2 = L15_2
  L10_2 = L14_2
  L9_2 = L13_2
  L13_2 = 60
  L14_2 = Airstrike
  L14_2 = L14_2.SpawnOrdnance
  L15_2 = "Fuel Air Bomb Projectile"
  L16_2 = L1_2
  L17_2 = L2_2 - 5
  L18_2 = L3_2
  L19_2 = L9_2 * L13_2
  L20_2 = L10_2 * L13_2
  L21_2 = L11_2 * L13_2
  L22_2 = "distance"
  L23_2 = L12_2
  L24_2 = A0_2.uOwner
  L25_2 = BombExplodes
  L26_2 = {}
  L27_2 = A0_2
  L28_2 = "distance"
  L26_2[1] = L27_2
  L26_2[2] = L28_2
  L14_2 = L14_2(L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2)
  A0_2.uSpawnedBomb = L14_2
end

DropBomb = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = A0_2.uSpawnedBomb
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L6_2 = A0_2
  L5_2 = A0_2.GetDesignator
  L5_2 = L5_2(L6_2)
  L6_2 = L5_2
  L5_2 = L5_2.GetTarget
  L5_2, L6_2, L7_2, L8_2, L9_2 = L5_2(L6_2)
  L10_2 = L5_2 - L2_2
  L11_2 = L6_2 - L3_2
  L12_2 = L7_2 - L4_2
  L13_2 = Math
  L13_2 = L13_2.Normalize
  L14_2 = L10_2
  L15_2 = L11_2
  L16_2 = L12_2
  L13_2, L14_2, L15_2 = L13_2(L14_2, L15_2, L16_2)
  L12_2 = L15_2
  L11_2 = L14_2
  L10_2 = L13_2
  L13_2 = Airstrike
  L13_2 = L13_2.SpawnDirectedObject
  L14_2 = "global_particle_airstrike_fuelairbomb"
  L15_2 = L2_2
  L16_2 = L3_2
  L17_2 = L4_2
  L18_2 = -L10_2
  L19_2 = -L11_2
  L20_2 = -L12_2
  L13_2 = L13_2(L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
  L14_2 = Airstrike
  L14_2 = L14_2.SpawnDirectedObject
  L15_2 = "global_particle_explosion_flash_large"
  L16_2 = L2_2
  L17_2 = L3_2
  L18_2 = L4_2
  L19_2 = -L10_2
  L20_2 = -L11_2
  L21_2 = -L12_2
  L14_2 = L14_2(L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
  L15_2 = Event
  L15_2 = L15_2.Create
  L16_2 = Event
  L16_2 = L16_2.TimerRelative
  L17_2 = {}
  L18_2 = 1.6
  L17_2[1] = L18_2
  L18_2 = Ignition
  L19_2 = {}
  L20_2 = L2_2
  L21_2 = L3_2
  L22_2 = L4_2
  L23_2 = L5_2
  L24_2 = L6_2
  L25_2 = L7_2
  L26_2 = L10_2
  L27_2 = L11_2
  L28_2 = L12_2
  L19_2[1] = L20_2
  L19_2[2] = L21_2
  L19_2[3] = L22_2
  L19_2[4] = L23_2
  L19_2[5] = L24_2
  L19_2[6] = L25_2
  L19_2[7] = L26_2
  L19_2[8] = L27_2
  L19_2[9] = L28_2
  L15_2(L16_2, L17_2, L18_2, L19_2)
end

BombExplodes = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L6_2 = Airstrike
  L6_2 = L6_2.SpawnDirectedObject
  L7_2 = "global_particle_airstrike_fuelairbomb"
  L8_2 = A3_2
  L9_2 = A4_2
  L10_2 = A5_2
  L11_2 = A2_2
  L12_2 = A1_2
  L13_2 = A2_2
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
end

Test = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2)
  local L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2
  L9_2 = Pg
  L9_2 = L9_2.Spawn
  L10_2 = "Light_airstrike_fuelairbomb_sml"
  L11_2 = A3_2
  L12_2 = A4_2 + 1
  L13_2 = A5_2
  L9_2(L10_2, L11_2, L12_2, L13_2)
  L9_2 = Pg
  L9_2 = L9_2.Spawn
  L10_2 = "global_particle_exp_falling_debris_airstrike"
  L11_2 = A3_2
  L12_2 = A4_2 + 1
  L13_2 = A5_2
  L9_2(L10_2, L11_2, L12_2, L13_2)
  L9_2 = Event
  L9_2 = L9_2.Create
  L10_2 = Event
  L10_2 = L10_2.TimerRelative
  L11_2 = {}
  L12_2 = 0.15
  L11_2[1] = L12_2
  L12_2 = Fireball
  L13_2 = {}
  L14_2 = A0_2
  L15_2 = A1_2
  L16_2 = A2_2
  L17_2 = A3_2
  L18_2 = A4_2
  L19_2 = A5_2
  L20_2 = A6_2
  L21_2 = A7_2
  L22_2 = A8_2
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L13_2[3] = L16_2
  L13_2[4] = L17_2
  L13_2[5] = L18_2
  L13_2[6] = L19_2
  L13_2[7] = L20_2
  L13_2[8] = L21_2
  L13_2[9] = L22_2
  L9_2(L10_2, L11_2, L12_2, L13_2)
  L9_2 = Sound
  L9_2 = L9_2.CueSound
  L10_2 = 0
  L11_2 = "exp_oiltrucker"
  L9_2(L10_2, L11_2)
end

Ignition = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2)
  local L9_2, L10_2, L11_2, L12_2, L13_2
  L9_2 = Pg
  L9_2 = L9_2.Spawn
  L10_2 = "Explosion (Fuel Air Bomb)"
  L11_2 = A0_2
  L12_2 = A1_2 - 2
  L13_2 = A2_2
  L9_2(L10_2, L11_2, L12_2, L13_2)
  L9_2 = Pg
  L9_2 = L9_2.Spawn
  L10_2 = "Light_airstrike_fuelairbomb_lrg_flash"
  L11_2 = A0_2
  L12_2 = A1_2 - 2
  L13_2 = A2_2
  L9_2(L10_2, L11_2, L12_2, L13_2)
  L9_2 = Pg
  L9_2 = L9_2.Spawn
  L10_2 = "global_particle_exp_shockwave_ground"
  L11_2 = A0_2
  L12_2 = A4_2
  L13_2 = A2_2
  L9_2(L10_2, L11_2, L12_2, L13_2)
end

Fireball = L0_1
