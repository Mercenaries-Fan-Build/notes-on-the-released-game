local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignatorSatellite"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = {}
  L3_2 = setmetatable
  L4_2 = L2_2
  L5_2 = A0_2
  L3_2(L4_2, L5_2)
  A0_2.__index = A0_2
  L3_2 = MrxSupportDesignatorSatellite
  L4_2 = L3_2
  L3_2 = L3_2.Create
  L3_2 = L3_2(L4_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetMinigameSectors
  L6_2 = {}
  L7_2 = {}
  L8_2 = 35
  L9_2 = 55
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L8_2 = {}
  L9_2 = 170
  L10_2 = 190
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L9_2 = {}
  L10_2 = 305
  L11_2 = 325
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetDesignator
  L6_2 = L3_2
  L4_2(L5_2, L6_2)
  L3_2.sAATestLevel = nil
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
  L6_2 = "MrxRocketArtillery"
  L4_2(L5_2, L6_2)
  return L2_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2
  L1_2 = Player
  L1_2 = L1_2.GetCharacter
  L2_2 = A0_2.uOwner
  L1_2 = L1_2(L2_2)
  L2_2 = "Rocket Artillery Projectile"
  L3_2 = 100
  L4_2 = 50
  L5_2 = 30
  L6_2 = 8
  L8_2 = A0_2
  L7_2 = A0_2.GetDesignator
  L7_2 = L7_2(L8_2)
  L8_2 = L7_2
  L7_2 = L7_2.GetTarget
  L7_2, L8_2, L9_2 = L7_2(L8_2)
  L10_2 = Object
  L10_2 = L10_2.GetPosition
  L11_2 = L1_2
  L10_2, L11_2, L12_2 = L10_2(L11_2)
  L13_2 = L7_2 - L10_2
  L14_2 = L8_2 - L11_2
  L15_2 = L9_2 - L12_2
  L16_2 = Math
  L16_2 = L16_2.Normalize
  L17_2 = L13_2
  L18_2 = L14_2
  L19_2 = L15_2
  L16_2, L17_2, L18_2 = L16_2(L17_2, L18_2, L19_2)
  L15_2 = L18_2
  L14_2 = L17_2
  L13_2 = L16_2
  L16_2 = L9_2 - L12_2
  L16_2 = -L16_2
  L17_2 = 0
  L18_2 = L7_2 - L10_2
  L19_2 = Math
  L19_2 = L19_2.Normalize
  L20_2 = L16_2
  L21_2 = L17_2
  L22_2 = L18_2
  L19_2, L20_2, L21_2 = L19_2(L20_2, L21_2, L22_2)
  L18_2 = L21_2
  L17_2 = L20_2
  L16_2 = L19_2
  L19_2 = 1
  L20_2 = L5_2
  L21_2 = 1
  for L22_2 = L19_2, L20_2, L21_2 do
    L23_2 = L3_2 / L5_2
    L24_2 = L4_2
    L25_2 = math
    L25_2 = L25_2.randf
    L25_2 = L25_2()
    L25_2 = L25_2 * L23_2
    L26_2 = math
    L26_2 = L26_2.randf
    L26_2 = L26_2()
    L26_2 = L26_2 * L23_2
    L25_2 = L25_2 - L26_2
    L26_2 = L5_2 + 1
    L26_2 = L26_2 / 2
    L26_2 = L26_2 - L22_2
    L26_2 = L26_2 * L23_2
    L25_2 = L25_2 + L26_2
    L25_2 = -L25_2
    L26_2 = math
    L26_2 = L26_2.randf
    L26_2 = L26_2()
    L26_2 = L26_2 * L24_2
    L27_2 = math
    L27_2 = L27_2.randf
    L27_2 = L27_2()
    L27_2 = L27_2 * L24_2
    L26_2 = L26_2 - L27_2
    L26_2 = -L26_2
    L27_2 = {}
    L27_2.sAmmo = L2_2
    L28_2 = L16_2 * L25_2
    L28_2 = L7_2 + L28_2
    L29_2 = L13_2 * L26_2
    L28_2 = L28_2 + L29_2
    L27_2.nTargetX = L28_2
    L28_2 = L8_2 + 250
    L27_2.nTargetY = L28_2
    L28_2 = L18_2 * L25_2
    L28_2 = L9_2 + L28_2
    L29_2 = L15_2 * L26_2
    L28_2 = L28_2 + L29_2
    L27_2.nTargetZ = L28_2
    L28_2 = Event
    L28_2 = L28_2.Create
    L29_2 = Event
    L29_2 = L29_2.TimerRelative
    L30_2 = {}
    L31_2 = L6_2 / L5_2
    L31_2 = L22_2 * L31_2
    L31_2 = 3 + L31_2
    L30_2[1] = L31_2
    L31_2 = TriggerFallingMissile
    L32_2 = {}
    L33_2 = L27_2
    L34_2 = A0_2.uOwner
    L32_2[1] = L33_2
    L32_2[2] = L34_2
    L28_2(L29_2, L30_2, L31_2, L32_2)
  end
  L19_2 = MrxVoSequence
  L19_2 = L19_2.Start
  L20_2 = {}
  L21_2 = MrxUtil
  L21_2 = L21_2.GetRandomTableElement
  L22_2 = {}
  L23_2 = "ChinaSoldier.cp1_artillery_roger"
  L24_2 = "ChinaSoldier01.Support.Artillery01"
  L25_2 = "ChinaSoldier01.Support.Artillery02"
  L26_2 = "ChinaSoldier01.Support.Incoming01"
  L27_2 = "ChinaSoldier01.Support.Incoming02"
  L28_2 = "ChinaSoldier01.Support.Incoming03"
  L22_2[1] = L23_2
  L22_2[2] = L24_2
  L22_2[3] = L25_2
  L22_2[4] = L26_2
  L22_2[5] = L27_2
  L22_2[6] = L28_2
  L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2 = L21_2(L22_2)
  L20_2[1] = L21_2
  L20_2[2] = L22_2
  L20_2[3] = L23_2
  L20_2[4] = L24_2
  L20_2[5] = L25_2
  L20_2[6] = L26_2
  L20_2[7] = L27_2
  L20_2[8] = L28_2
  L20_2[9] = L29_2
  L20_2[10] = L30_2
  L20_2[11] = L31_2
  L20_2[12] = L32_2
  L20_2[13] = L33_2
  L20_2[14] = L34_2
  L21_2 = nil
  L22_2 = MrxVoSequence
  L22_2 = L22_2.knPriorityFreeplay
  L23_2 = false
  L19_2(L20_2, L21_2, L22_2, L23_2)
end

DesignationCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L2_2 = Airstrike
  L2_2 = L2_2.SpawnOrdnance
  L3_2 = A0_2.sAmmo
  L4_2 = A0_2.nTargetX
  L5_2 = A0_2.nTargetY
  L6_2 = A0_2.nTargetZ
  L7_2 = 0
  L8_2 = -100
  L9_2 = 0
  L10_2 = "impact"
  L11_2 = 1
  L12_2 = A1_2
  L13_2 = ActivateDelay
  L14_2 = {}
  L15_2 = A0_2
  L14_2[1] = L15_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
end

TriggerFallingMissile = L0_1
