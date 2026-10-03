local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxLayerManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "DangerousBuilding"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = {}
  L2_2 = "VZ_state_PirCon004"
  L1_2[1] = L2_2
  L2_2 = MrxLayerManager
  L2_2 = L2_2.Add
  L3_2 = L1_2
  L4_2 = AssetsLoaded
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L2_2(L3_2, L4_2, L5_2)
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = false
  bFinished = L1_2
  L1_2 = Player
  L1_2 = L1_2.GetCurrentPlayers
  L1_2 = L1_2()
  nPlayers = L1_2
  L1_2 = Player
  L1_2 = L1_2.GetPrimaryCharacter
  L1_2 = L1_2()
  uPlayerPrim = L1_2
  L1_2 = {}
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "OrganBox_08"
  L2_2 = L2_2(L3_2)
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "OrganBox_09"
  L3_2 = L3_2(L4_2)
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "OrganBox_10"
  L4_2 = L4_2(L5_2)
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "OrganBox_11"
  L5_2 = L5_2(L6_2)
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "OrganBox_12"
  L6_2 = L6_2(L7_2)
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "OrganBox_13"
  L7_2 = L7_2(L8_2)
  L8_2 = Pg
  L8_2 = L8_2.GetGuidByName
  L9_2 = "OrganBox_14"
  L8_2 = L8_2(L9_2)
  L9_2 = Pg
  L9_2 = L9_2.GetGuidByName
  L10_2 = "OrganBox_15"
  L9_2 = L9_2(L10_2)
  L10_2 = Pg
  L10_2 = L10_2.GetGuidByName
  L11_2 = "OrganBox_16"
  L10_2 = L10_2(L11_2)
  L11_2 = Pg
  L11_2 = L11_2.GetGuidByName
  L12_2 = "OrganBox_17"
  L11_2 = L11_2(L12_2)
  L12_2 = Pg
  L12_2 = L12_2.GetGuidByName
  L13_2 = "OrganBox_18"
  L12_2 = L12_2(L13_2)
  L13_2 = Pg
  L13_2 = L13_2.GetGuidByName
  L14_2 = "OrganBox_19"
  L13_2 = L13_2(L14_2)
  L14_2 = Pg
  L14_2 = L14_2.GetGuidByName
  L15_2 = "OrganBox_20"
  L14_2 = L14_2(L15_2)
  L15_2 = Pg
  L15_2 = L15_2.GetGuidByName
  L16_2 = "OrganBox_21"
  L15_2 = L15_2(L16_2)
  L16_2 = Pg
  L16_2 = L16_2.GetGuidByName
  L17_2 = "OrganBox_22"
  L16_2 = L16_2(L17_2)
  L17_2 = Pg
  L17_2 = L17_2.GetGuidByName
  L18_2 = "OrganBox_23"
  L17_2 = L17_2(L18_2)
  L18_2 = Pg
  L18_2 = L18_2.GetGuidByName
  L19_2 = "OrganBox_24"
  L18_2 = L18_2(L19_2)
  L19_2 = Pg
  L19_2 = L19_2.GetGuidByName
  L20_2 = "OrganBox_25"
  L19_2 = L19_2(L20_2)
  L20_2 = Pg
  L20_2 = L20_2.GetGuidByName
  L21_2 = "OrganBox_26"
  L20_2 = L20_2(L21_2)
  L21_2 = Pg
  L21_2 = L21_2.GetGuidByName
  L22_2 = "OrganBox_27"
  L21_2 = L21_2(L22_2)
  L22_2 = Pg
  L22_2 = L22_2.GetGuidByName
  L23_2 = "OrganBox_28"
  L22_2 = L22_2(L23_2)
  L23_2 = Pg
  L23_2 = L23_2.GetGuidByName
  L24_2 = "OrganBox_29"
  L23_2 = L23_2(L24_2)
  L24_2 = Pg
  L24_2 = L24_2.GetGuidByName
  L25_2 = "OrganBox_31"
  L24_2 = L24_2(L25_2)
  L25_2 = Pg
  L25_2 = L25_2.GetGuidByName
  L26_2 = "OrganBox_32"
  L25_2 = L25_2(L26_2)
  L26_2 = Pg
  L26_2 = L26_2.GetGuidByName
  L27_2 = "OrganBox_33"
  L26_2 = L26_2(L27_2)
  L27_2 = Pg
  L27_2 = L27_2.GetGuidByName
  L28_2 = "OrganBox_34"
  L27_2, L28_2 = L27_2(L28_2)
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L1_2[7] = L8_2
  L1_2[8] = L9_2
  L1_2[9] = L10_2
  L1_2[10] = L11_2
  L1_2[11] = L12_2
  L1_2[12] = L13_2
  L1_2[13] = L14_2
  L1_2[14] = L15_2
  L1_2[15] = L16_2
  L1_2[16] = L17_2
  L1_2[17] = L18_2
  L1_2[18] = L19_2
  L1_2[19] = L20_2
  L1_2[20] = L21_2
  L1_2[21] = L22_2
  L1_2[22] = L23_2
  L1_2[23] = L24_2
  L1_2[24] = L25_2
  L1_2[25] = L26_2
  L1_2[26] = L27_2
  L1_2[27] = L28_2
  tOrganBoxes = L1_2
  L1_2 = {}
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "OrganBox_02"
  L2_2 = L2_2(L3_2)
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "OrganBox_03"
  L3_2 = L3_2(L4_2)
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "OrganBox_04"
  L4_2 = L4_2(L5_2)
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "OrganBox_05"
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2 = L5_2(L6_2)
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L1_2[7] = L8_2
  L1_2[8] = L9_2
  L1_2[9] = L10_2
  L1_2[10] = L11_2
  L1_2[11] = L12_2
  L1_2[12] = L13_2
  L1_2[13] = L14_2
  L1_2[14] = L15_2
  L1_2[15] = L16_2
  L1_2[16] = L17_2
  L1_2[17] = L18_2
  L1_2[18] = L19_2
  L1_2[19] = L20_2
  L1_2[20] = L21_2
  L1_2[21] = L22_2
  L1_2[22] = L23_2
  L1_2[23] = L24_2
  L1_2[24] = L25_2
  L1_2[25] = L26_2
  L1_2[26] = L27_2
  L1_2[27] = L28_2
  tOrganBoxes02 = L1_2
  L1_2 = {}
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "OrganBox_08b"
  L2_2 = L2_2(L3_2)
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "OrganBox_09b"
  L3_2 = L3_2(L4_2)
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "OrganBox_10b"
  L4_2 = L4_2(L5_2)
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "OrganBox_11b"
  L5_2 = L5_2(L6_2)
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "OrganBox_12b"
  L6_2 = L6_2(L7_2)
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "OrganBox_13b"
  L7_2 = L7_2(L8_2)
  L8_2 = Pg
  L8_2 = L8_2.GetGuidByName
  L9_2 = "OrganBox_14b"
  L8_2 = L8_2(L9_2)
  L9_2 = Pg
  L9_2 = L9_2.GetGuidByName
  L10_2 = "OrganBox_15b"
  L9_2 = L9_2(L10_2)
  L10_2 = Pg
  L10_2 = L10_2.GetGuidByName
  L11_2 = "OrganBox_16b"
  L10_2 = L10_2(L11_2)
  L11_2 = Pg
  L11_2 = L11_2.GetGuidByName
  L12_2 = "OrganBox_17b"
  L11_2 = L11_2(L12_2)
  L12_2 = Pg
  L12_2 = L12_2.GetGuidByName
  L13_2 = "OrganBox_18b"
  L12_2 = L12_2(L13_2)
  L13_2 = Pg
  L13_2 = L13_2.GetGuidByName
  L14_2 = "OrganBox_19b"
  L13_2 = L13_2(L14_2)
  L14_2 = Pg
  L14_2 = L14_2.GetGuidByName
  L15_2 = "OrganBox_20b"
  L14_2 = L14_2(L15_2)
  L15_2 = Pg
  L15_2 = L15_2.GetGuidByName
  L16_2 = "OrganBox_21b"
  L15_2 = L15_2(L16_2)
  L16_2 = Pg
  L16_2 = L16_2.GetGuidByName
  L17_2 = "OrganBox_22b"
  L16_2 = L16_2(L17_2)
  L17_2 = Pg
  L17_2 = L17_2.GetGuidByName
  L18_2 = "OrganBox_23b"
  L17_2 = L17_2(L18_2)
  L18_2 = Pg
  L18_2 = L18_2.GetGuidByName
  L19_2 = "OrganBox_24b"
  L18_2 = L18_2(L19_2)
  L19_2 = Pg
  L19_2 = L19_2.GetGuidByName
  L20_2 = "OrganBox_25b"
  L19_2 = L19_2(L20_2)
  L20_2 = Pg
  L20_2 = L20_2.GetGuidByName
  L21_2 = "OrganBox_26b"
  L20_2 = L20_2(L21_2)
  L21_2 = Pg
  L21_2 = L21_2.GetGuidByName
  L22_2 = "OrganBox_27b"
  L21_2 = L21_2(L22_2)
  L22_2 = Pg
  L22_2 = L22_2.GetGuidByName
  L23_2 = "OrganBox_28b"
  L22_2 = L22_2(L23_2)
  L23_2 = Pg
  L23_2 = L23_2.GetGuidByName
  L24_2 = "OrganBox_29b"
  L23_2 = L23_2(L24_2)
  L24_2 = Pg
  L24_2 = L24_2.GetGuidByName
  L25_2 = "OrganBox_31b"
  L24_2 = L24_2(L25_2)
  L25_2 = Pg
  L25_2 = L25_2.GetGuidByName
  L26_2 = "OrganBox_32b"
  L25_2 = L25_2(L26_2)
  L26_2 = Pg
  L26_2 = L26_2.GetGuidByName
  L27_2 = "OrganBox_33b"
  L26_2 = L26_2(L27_2)
  L27_2 = Pg
  L27_2 = L27_2.GetGuidByName
  L28_2 = "OrganBox_34b"
  L27_2, L28_2 = L27_2(L28_2)
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L1_2[7] = L8_2
  L1_2[8] = L9_2
  L1_2[9] = L10_2
  L1_2[10] = L11_2
  L1_2[11] = L12_2
  L1_2[12] = L13_2
  L1_2[13] = L14_2
  L1_2[14] = L15_2
  L1_2[15] = L16_2
  L1_2[16] = L17_2
  L1_2[17] = L18_2
  L1_2[18] = L19_2
  L1_2[19] = L20_2
  L1_2[20] = L21_2
  L1_2[21] = L22_2
  L1_2[22] = L23_2
  L1_2[23] = L24_2
  L1_2[24] = L25_2
  L1_2[25] = L26_2
  L1_2[26] = L27_2
  L1_2[27] = L28_2
  tOrganBoxesB = L1_2
  L1_2 = {}
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "OrganBox_02b"
  L2_2 = L2_2(L3_2)
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "OrganBox_03b"
  L3_2 = L3_2(L4_2)
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "OrganBox_04b"
  L4_2 = L4_2(L5_2)
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "OrganBox_05b"
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2 = L5_2(L6_2)
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L1_2[7] = L8_2
  L1_2[8] = L9_2
  L1_2[9] = L10_2
  L1_2[10] = L11_2
  L1_2[11] = L12_2
  L1_2[12] = L13_2
  L1_2[13] = L14_2
  L1_2[14] = L15_2
  L1_2[15] = L16_2
  L1_2[16] = L17_2
  L1_2[17] = L18_2
  L1_2[18] = L19_2
  L1_2[19] = L20_2
  L1_2[20] = L21_2
  L1_2[21] = L22_2
  L1_2[22] = L23_2
  L1_2[23] = L24_2
  L1_2[24] = L25_2
  L1_2[25] = L26_2
  L1_2[26] = L27_2
  L1_2[27] = L28_2
  tOrganBoxes02B = L1_2
  L1_2 = {}
  tSpawnedItems = L1_2
  L1_2 = 1
  nSpawn = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "PirCon004_OrganTruck"
  L1_2 = L1_2(L2_2)
  uPickup = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "PirCon004_DeliveryRecipient"
  L1_2 = L1_2(L2_2)
  uAccepter = L1_2
  L1_2 = {}
  L2_2 = uPickup
  L1_2[1] = L2_2
  tVeh = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "PirCon004_TruckGoal"
  L1_2 = L1_2(L2_2)
  uVZGoal = L1_2
  L1_2 = true
  bFirstWarn = L1_2
  L1_2 = true
  bSecWarn = L1_2
  L1_2 = true
  bFinal = L1_2
  L1_2 = nPlayers
  if L1_2 == 2 then
    L1_2 = GetPlayers
    L2_2 = A0_2
    L1_2(L2_2)
  end
  L1_2 = GetCompletions
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = uPickup
  L6_2 = "awake"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  
  function L5_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3
    L1_3 = ipairs
    L2_3 = tOrganBoxes
    L1_3, L2_3, L3_3 = L1_3(L2_3)
    for L4_3, L5_3 in L1_3, L2_3, L3_3 do
      L6_3 = Object
      L6_3 = L6_3.GetPosition
      L7_3 = L5_3
      L6_3, L7_3, L8_3 = L6_3(L7_3)
      L9_3 = Object
      L9_3 = L9_3.GetYaw
      L10_3 = L5_3
      L9_3 = L9_3(L10_3)
      L10_3 = nSpawn
      L10_3 = L10_3 + 1
      nSpawn = L10_3
      L10_3 = Pg
      L10_3 = L10_3.Spawn
      L11_3 = "_global_containertransplant"
      L12_3 = L6_3
      L13_3 = L7_3
      L14_3 = L8_3
      L15_3 = L9_3
      L16_3 = true
      L17_3 = true
      L10_3 = L10_3(L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3)
      uSpawn = L10_3
      L10_3 = table
      L10_3 = L10_3.insert
      L11_3 = tSpawnedItems
      L12_3 = uSpawn
      L10_3(L11_3, L12_3)
    end
  end
  
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 0.75
  L4_2[1] = L5_2
  
  function L5_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3
    L1_3 = ipairs
    L2_3 = tOrganBoxes02
    L1_3, L2_3, L3_3 = L1_3(L2_3)
    for L4_3, L5_3 in L1_3, L2_3, L3_3 do
      L6_3 = Object
      L6_3 = L6_3.GetPosition
      L7_3 = L5_3
      L6_3, L7_3, L8_3 = L6_3(L7_3)
      L9_3 = Object
      L9_3 = L9_3.GetYaw
      L10_3 = L5_3
      L9_3 = L9_3(L10_3)
      L10_3 = nSpawn
      L10_3 = L10_3 + 1
      nSpawn = L10_3
      L10_3 = Pg
      L10_3 = L10_3.Spawn
      L11_3 = "_global_containertransplant"
      L12_3 = L6_3
      L13_3 = L7_3
      L14_3 = L8_3
      L15_3 = L9_3
      L16_3 = true
      L17_3 = true
      L10_3 = L10_3(L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3)
      uSpawn = L10_3
      L10_3 = table
      L10_3 = L10_3.insert
      L11_3 = tSpawnedItems
      L12_3 = uSpawn
      L10_3(L11_3, L12_3)
    end
  end
  
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L1_2 = nPlayers
  if L1_2 == 2 then
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.ObjectHibernation
    L4_2 = {}
    L5_2 = uPickupB
    L6_2 = "awake"
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    
    function L5_2(A0_3)
      local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3
      L1_3 = ipairs
      L2_3 = tOrganBoxesB
      L1_3, L2_3, L3_3 = L1_3(L2_3)
      for L4_3, L5_3 in L1_3, L2_3, L3_3 do
        L6_3 = Object
        L6_3 = L6_3.GetPosition
        L7_3 = L5_3
        L6_3, L7_3, L8_3 = L6_3(L7_3)
        L9_3 = Object
        L9_3 = L9_3.GetYaw
        L10_3 = L5_3
        L9_3 = L9_3(L10_3)
        L10_3 = nSpawn
        L10_3 = L10_3 + 1
        nSpawn = L10_3
        L10_3 = Pg
        L10_3 = L10_3.Spawn
        L11_3 = "_global_containertransplant"
        L12_3 = L6_3
        L13_3 = L7_3
        L14_3 = L8_3
        L15_3 = L9_3
        L16_3 = true
        L17_3 = true
        L10_3 = L10_3(L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3)
        uSpawn = L10_3
        L10_3 = table
        L10_3 = L10_3.insert
        L11_3 = tSpawnedItems
        L12_3 = uSpawn
        L10_3(L11_3, L12_3)
      end
    end
    
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.TimerRelative
    L4_2 = {}
    L5_2 = 0.75
    L4_2[1] = L5_2
    
    function L5_2(A0_3)
      local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3
      L1_3 = ipairs
      L2_3 = tOrganBoxes02B
      L1_3, L2_3, L3_3 = L1_3(L2_3)
      for L4_3, L5_3 in L1_3, L2_3, L3_3 do
        L6_3 = Object
        L6_3 = L6_3.GetPosition
        L7_3 = L5_3
        L6_3, L7_3, L8_3 = L6_3(L7_3)
        L9_3 = Object
        L9_3 = L9_3.GetYaw
        L10_3 = L5_3
        L9_3 = L9_3(L10_3)
        L10_3 = nSpawn
        L10_3 = L10_3 + 1
        nSpawn = L10_3
        L10_3 = Pg
        L10_3 = L10_3.Spawn
        L11_3 = "_global_containertransplant"
        L12_3 = L6_3
        L13_3 = L7_3
        L14_3 = L8_3
        L15_3 = L9_3
        L16_3 = true
        L17_3 = true
        L10_3 = L10_3(L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3)
        uSpawn = L10_3
        L10_3 = table
        L10_3 = L10_3.insert
        L11_3 = tSpawnedItems
        L12_3 = uSpawn
        L10_3(L11_3, L12_3)
      end
    end
    
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  end
  L1_2 = DangerousBuilding
  L1_2 = L1_2.SetRarity
  L2_2 = "default"
  L3_2 = "never"
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "PirCon004: Physics Delivery, Organs for transplant"
  L3_2.sModuleName = "MrxTaskObjectiveEnterVehicle"
  L4_2 = tVeh
  L3_2.vTgtInclude = L4_2
  L3_2.nQuota = 1
  L3_2.sDspShortDesc = "[PirCon004.Objectives.Objective01]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = ObjDeliverGoods
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnComplete = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.Cancel
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnCancel = L4_2
  L1_2(L2_2, L3_2)
  L1_2 = nPlayers
  if L1_2 == 1 then
    L2_2 = A0_2
    L1_2 = A0_2._CreateEvent
    L3_2 = Event
    L3_2 = L3_2.ObjectDeath
    L4_2 = {}
    L5_2 = uPickup
    L4_2[1] = L5_2
    L5_2 = A0_2.Cancel
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
    eTruckDeath = L1_2
  end
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L1_2 = Player
  L1_2 = L1_2.GetAnyCharacter
  L1_2 = L1_2()
  L2_2 = 7
  L4_2 = A0_2
  L3_2 = A0_2.GetNumCompletions
  L3_2 = L3_2(L4_2)
  L3_2 = L3_2 * 30
  if not L3_2 then
    L3_2 = 0
  end
  L4_2 = "Deadline"
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "VZBlock_1"
  L5_2 = L5_2(L6_2)
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "PirCon004_Tanker(explode)"
  L6_2 = L6_2(L7_2)
  L7_2 = false
  bCoopComplete = L7_2
  L7_2 = nGoal
  nTargetBoxesDelivered = L7_2
  L7_2 = table
  L7_2 = L7_2.getn
  L8_2 = tSpawnedItems
  L7_2 = L7_2(L8_2)
  nStartingCargo = L7_2
  L7_2 = 0
  nP1Boxes = L7_2
  L7_2 = 0
  nP2Boxes = L7_2
  L7_2 = {}
  tP1Boxes = L7_2
  L7_2 = {}
  tP2Boxes = L7_2
  L7_2 = "fx_Explosion_HugeOil"
  sDetBig = L7_2
  L7_2 = "Explosion (AA Detonation)"
  sDetMid = L7_2
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "PirCon004_Smokestack(explode)01"
  L7_2 = L7_2(L8_2)
  uSmokestack01 = L7_2
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "PirCon004_Smokestack(explode)02"
  L7_2 = L7_2(L8_2)
  uSmokestack02 = L7_2
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "PirCon004_PipeObst01"
  L7_2 = L7_2(L8_2)
  uPipes01 = L7_2
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "PirCon004_PipeObst02"
  L7_2 = L7_2(L8_2)
  uPipes02 = L7_2
  L8_2 = A0_2
  L7_2 = A0_2._CreateEvent
  L9_2 = Event
  L9_2 = L9_2.ObjectProximity
  L10_2 = {}
  L11_2 = L1_2
  L12_2 = L5_2
  L13_2 = "<"
  L14_2 = 100
  L15_2 = false
  L16_2 = false
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L10_2[5] = L15_2
  L10_2[6] = L16_2
  L11_2 = VZBlock
  L12_2 = {}
  L13_2 = A0_2
  L12_2[1] = L13_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L8_2 = A0_2
  L7_2 = A0_2.CreateChild
  L9_2 = {}
  L9_2.sName = "PirCon004: Deliver goods"
  L9_2.sModuleName = "MrxTaskObjectiveDeliver"
  L10_2 = tVeh
  L9_2.vTgtInclude = L10_2
  L10_2 = nPlayers
  L9_2.nQuota = L10_2
  L10_2 = Pg
  L10_2 = L10_2.GetGuidByName
  L11_2 = "PirCon004_Dest_Location"
  L10_2 = L10_2(L11_2)
  L9_2.vDestLoc = L10_2
  L9_2.fDist = 12
  L9_2.bStop = true
  L9_2.bXZOnly = true
  L9_2.sDspShortDesc = "[PirCon004.Objectives.Objective02]"
  
  function L10_2()
    local L0_3, L1_3
    L0_3 = nPlayers
    if L0_3 == 2 then
      L0_3 = bCoopComplete
      if L0_3 == false then
        L0_3 = true
        bCoopComplete = L0_3
        L0_3 = DeliveryAccept
        L1_3 = A0_2
        L0_3(L1_3)
      end
    end
  end
  
  L9_2.fOnPartComplete = L10_2
  L10_2 = {}
  L11_2 = {}
  L12_2 = Delivered
  L13_2 = {}
  L14_2 = A0_2
  L13_2[1] = L14_2
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L10_2[1] = L11_2
  L9_2.tOnComplete = L10_2
  L10_2 = {}
  L11_2 = {}
  L12_2 = A0_2.Cancel
  L13_2 = {}
  L14_2 = A0_2
  L13_2[1] = L14_2
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L10_2[1] = L11_2
  L9_2.tOnCancel = L10_2
  L7_2 = L7_2(L8_2, L9_2)
  oMainDelivery = L7_2
  L7_2 = MrxTimer
  L8_2 = L7_2
  L7_2 = L7_2.Create
  L9_2 = {}
  L10_2 = L2_2 * 60
  L10_2 = L10_2 - L3_2
  L9_2.nStartTime = L10_2
  L9_2.nWarning = 60
  L9_2.iTray = 3
  L10_2 = {}
  L11_2 = {}
  L12_2 = Cancel
  L13_2 = {}
  L14_2 = A0_2
  L13_2[1] = L14_2
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L10_2[1] = L11_2
  L9_2.tDoneCallbacks = L10_2
  L7_2 = L7_2(L8_2, L9_2)
  oMissionTimer = L7_2
  L7_2 = oMissionTimer
  L8_2 = L7_2
  L7_2 = L7_2.Start
  L7_2(L8_2)
  L8_2 = A0_2
  L7_2 = A0_2._CreatePersistentEvent
  L9_2 = Event
  L9_2 = L9_2.TimerRelative
  L10_2 = {}
  L11_2 = 0.5
  L10_2[1] = L11_2
  L11_2 = CheckOrganBoxesLost
  L12_2 = {}
  L13_2 = A0_2
  L14_2 = uPickup
  L15_2 = "P1"
  L12_2[1] = L13_2
  L12_2[2] = L14_2
  L12_2[3] = L15_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  eBoxCheck = L7_2
  L8_2 = A0_2
  L7_2 = A0_2._CreateEvent
  L9_2 = Event
  L9_2 = L9_2.ObjectProximity
  L10_2 = {}
  L11_2 = uPickup
  L12_2 = Pg
  L12_2 = L12_2.GetGuidByName
  L13_2 = "PirCon004_Dest_Location"
  L12_2 = L12_2(L13_2)
  L13_2 = "<"
  L14_2 = 12
  L15_2 = false
  L16_2 = false
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L10_2[5] = L15_2
  L10_2[6] = L16_2
  L11_2 = Event
  L11_2 = L11_2.Delete
  L12_2 = {}
  L13_2 = eBoxCheck
  L12_2[1] = L13_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  eCheckClear = L7_2
  L7_2 = nPlayers
  if L7_2 == 2 then
    L8_2 = A0_2
    L7_2 = A0_2._CreatePersistentEvent
    L9_2 = Event
    L9_2 = L9_2.TimerRelative
    L10_2 = {}
    L11_2 = 0.5
    L10_2[1] = L11_2
    L11_2 = CheckOrganBoxesLost
    L12_2 = {}
    L13_2 = A0_2
    L14_2 = uPickupB
    L15_2 = "P2"
    L12_2[1] = L13_2
    L12_2[2] = L14_2
    L12_2[3] = L15_2
    L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
    eBoxCheck2 = L7_2
    L8_2 = A0_2
    L7_2 = A0_2._CreateEvent
    L9_2 = Event
    L9_2 = L9_2.ObjectProximity
    L10_2 = {}
    L11_2 = uPickupB
    L12_2 = Pg
    L12_2 = L12_2.GetGuidByName
    L13_2 = "PirCon004_Dest_Location"
    L12_2 = L12_2(L13_2)
    L13_2 = "<"
    L14_2 = 12
    L15_2 = false
    L16_2 = false
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L10_2[3] = L13_2
    L10_2[4] = L14_2
    L10_2[5] = L15_2
    L10_2[6] = L16_2
    L11_2 = Event
    L11_2 = L11_2.Delete
    L12_2 = {}
    L13_2 = eBoxCheck2
    L12_2[1] = L13_2
    L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
    eCheckClear2 = L7_2
  end
  L8_2 = A0_2
  L7_2 = A0_2._CreateEvent
  L9_2 = Event
  L9_2 = L9_2.Boundary
  L10_2 = {}
  L11_2 = Player
  L11_2 = L11_2.GetAnyCharacter
  L11_2 = L11_2()
  L12_2 = Pg
  L12_2 = L12_2.GetGuidByName
  L13_2 = "PirCon004_EndPursuit_region"
  L12_2 = L12_2(L13_2)
  L13_2 = "enter"
  L14_2 = false
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L11_2 = Pg
  L11_2 = L11_2.ClearPursuitLock
  L12_2 = {}
  L13_2 = true
  L12_2[1] = L13_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L8_2 = A0_2
  L7_2 = A0_2._CreateEvent
  L9_2 = Event
  L9_2 = L9_2.ObjectProximity
  L10_2 = {}
  L11_2 = L1_2
  L12_2 = L6_2
  L13_2 = "<"
  L14_2 = 50
  L15_2 = false
  L16_2 = false
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L10_2[5] = L15_2
  L10_2[6] = L16_2
  L11_2 = Object
  L11_2 = L11_2.Kill
  L12_2 = {}
  L13_2 = L6_2
  L12_2[1] = L13_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L7_2 = ObstacleDetonate
  L8_2 = A0_2
  L9_2 = uSmokestack01
  L10_2 = "PirCon004_explosion01"
  L11_2 = sDetBig
  L12_2 = 100
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L7_2 = ObstacleDetonate
  L8_2 = A0_2
  L9_2 = uSmokestack02
  L10_2 = "PirCon004_explosion02"
  L11_2 = sDetBig
  L12_2 = 120
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L7_2 = ObstacleDetonate
  L8_2 = A0_2
  L9_2 = uPipes01
  L10_2 = "PirCon004_explosion03"
  L11_2 = sDetMid
  L12_2 = 175
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L7_2 = ObstacleDetonate
  L8_2 = A0_2
  L9_2 = uPipes02
  L10_2 = "PirCon004_explosion04"
  L11_2 = sDetMid
  L12_2 = 150
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L8_2 = A0_2
  L7_2 = A0_2._CreateEvent
  L9_2 = Event
  L9_2 = L9_2.ObjectProximity
  L10_2 = {}
  L11_2 = L1_2
  L12_2 = uVZGoal
  L13_2 = "<"
  L14_2 = 175
  L15_2 = false
  L16_2 = false
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L10_2[5] = L15_2
  L10_2[6] = L16_2
  L11_2 = ObstacleTruck
  L12_2 = {}
  L13_2 = A0_2
  L12_2[1] = L13_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L8_2 = A0_2
  L7_2 = A0_2._CreateEvent
  L9_2 = Event
  L9_2 = L9_2.ObjectDeath
  L10_2 = {}
  L11_2 = Pg
  L11_2 = L11_2.GetGuidByName
  L12_2 = "PirCon004_Smokestack(explode)02"
  L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L11_2(L12_2)
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L10_2[5] = L15_2
  L10_2[6] = L16_2
  
  function L11_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = MrxVoSequence
    L1_3 = L1_3.Start
    L2_3 = {}
    L3_3 = "Fiona-In-Mission-MinorContract-Oil05-03"
    L2_3[1] = L3_3
    L1_3(L2_3)
  end
  
  L12_2 = {}
  L13_2 = A0_2
  L12_2[1] = L13_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L8_2 = A0_2
  L7_2 = A0_2._CreateEvent
  L9_2 = Event
  L9_2 = L9_2.ObjectDeath
  L10_2 = {}
  L11_2 = Pg
  L11_2 = L11_2.GetGuidByName
  L12_2 = "PirCon004_PipeObst01"
  L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L11_2(L12_2)
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L10_2[5] = L15_2
  L10_2[6] = L16_2
  
  function L11_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = MrxVoSequence
    L1_3 = L1_3.Start
    L2_3 = {}
    L3_3 = "Fiona.xfio001"
    L2_3[1] = L3_3
    L1_3(L2_3)
  end
  
  L12_2 = {}
  L13_2 = A0_2
  L12_2[1] = L13_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L8_2 = A0_2
  L7_2 = A0_2._CreateEvent
  L9_2 = Event
  L9_2 = L9_2.ObjectProximity
  L10_2 = {}
  L11_2 = Pg
  L11_2 = L11_2.GetGuidByName
  L12_2 = "PirCon004_OrganTruck"
  L11_2 = L11_2(L12_2)
  L12_2 = Pg
  L12_2 = L12_2.GetGuidByName
  L13_2 = "PirCon004_DelStart_loc"
  L12_2 = L12_2(L13_2)
  L13_2 = ">"
  L14_2 = nPurs
  L15_2 = false
  L16_2 = false
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L10_2[5] = L15_2
  L10_2[6] = L16_2
  L11_2 = StartPursuit
  L12_2 = {}
  L13_2 = A0_2
  L12_2[1] = L13_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  ePursTrigger = L7_2
  L8_2 = A0_2
  L7_2 = A0_2._CreateEvent
  L9_2 = Event
  L9_2 = L9_2.ObjectProximity
  L10_2 = {}
  L11_2 = Pg
  L11_2 = L11_2.GetGuidByName
  L12_2 = "PirCon004_OrganTruck"
  L11_2 = L11_2(L12_2)
  L12_2 = Pg
  L12_2 = L12_2.GetGuidByName
  L13_2 = "PirCon004_DelStart_loc"
  L12_2 = L12_2(L13_2)
  L13_2 = ">"
  L14_2 = nPurs
  L14_2 = L14_2 - 50
  L15_2 = false
  L16_2 = false
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L10_2[5] = L15_2
  L10_2[6] = L16_2
  
  function L11_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = MrxVoSequence
    L1_3 = L1_3.Start
    L2_3 = {}
    L3_3 = "Fiona-In-Mission-MinorContract-Pir04-07"
    L2_3[1] = L3_3
    L1_3(L2_3)
  end
  
  L12_2 = {}
  L13_2 = A0_2
  L12_2[1] = L13_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  ePursWarning = L7_2
  L7_2 = MrxVoSequence
  L7_2 = L7_2.Start
  L8_2 = {}
  L9_2 = "Fiona-Banter-MinorContract-Pir04-01"
  L10_2 = 0.5
  L11_2 = {}
  L11_2.mattias = "Mattias-Banter-MinorContract-Pir04-02"
  L11_2.jennifer = "Jennifer-Banter-MinorContract-Pir04-03"
  L11_2.chris = "Chris-Banter-MinorContract-Pir04-04"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L7_2(L8_2)
  L7_2 = MrxMusic
  L7_2 = L7_2.PlaySpecialMusic
  L8_2 = "mu_mission_pircon004_02"
  L7_2 = L7_2(L8_2)
  eCueMusic = L7_2
end

ObjDeliverGoods = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "PirCon004_Player2Truck"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L2_2(L3_2)
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L4_2 = Object
  L4_2 = L4_2.GetYaw
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "PirCon004_Player2Truck"
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L5_2(L6_2)
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L5_2 = Pg
  L5_2 = L5_2.Spawn
  L6_2 = "T300 (empty)"
  L7_2 = L1_2
  L8_2 = L2_2
  L9_2 = L3_2
  L10_2 = L4_2
  L11_2 = true
  L12_2 = true
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  uPickupB = L5_2
  L5_2 = table
  L5_2 = L5_2.insert
  L6_2 = tVeh
  L7_2 = uPickupB
  L5_2(L6_2, L7_2)
end

GetPlayers = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.GetNumCompletions
  L1_2 = L1_2(L2_2)
  if 2 < L1_2 then
    L1_2 = 2
  end
  if L1_2 == 0 then
    L2_2 = 800
    nPurs = L2_2
    L2_2 = 3
    nGoal = L2_2
    L2_2 = 1
    nMod = L2_2
  elseif L1_2 == 1 then
    L2_2 = 550
    nPurs = L2_2
    L2_2 = 5
    nGoal = L2_2
    L2_2 = 1.5
    nMod = L2_2
  elseif L1_2 == 2 then
    L2_2 = 450
    nPurs = L2_2
    L2_2 = 8
    nGoal = L2_2
    L2_2 = 2
    nMod = L2_2
  end
end

GetCompletions = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxFactionManager
  L1_2 = L1_2.LockPursuit
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "VZ"
  L2_2 = L2_2(L3_2)
  L3_2 = 1
  L1_2(L2_2, L3_2)
end

StartPursuit = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = ObjectFilter
  L1_2 = L1_2.Create
  L1_2 = L1_2()
  L2_2 = ObjectFilter
  L2_2 = L2_2.SetFilter
  L3_2 = L1_2
  L4_2 = "VZ"
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = L1_2
  L7_2 = uPickup
  L8_2 = "<"
  L9_2 = 50
  L10_2 = false
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = VZChaseDelay
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

SetupChaser = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.TimerRelative
  L5_2 = {}
  L6_2 = 7
  L5_2[1] = L6_2
  L6_2 = VZChase
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A1_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

VZChaseDelay = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = Vehicle
  L2_2 = L2_2.GetDriver
  L3_2 = A1_2[1]
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = Ai
    L3_2 = L3_2.Goal
    L4_2 = {}
    L4_2.AIGuid = L2_2
    L4_2.Goal = "MoveTo"
    L5_2 = Pg
    L5_2 = L5_2.GetGuidByName
    L6_2 = "PirCon004_OrganTruck"
    L5_2 = L5_2(L6_2)
    L4_2.Target = L5_2
    L4_2.Force = true
    L4_2.Priority = "hiPri"
    L5_2 = VZChaseTest
    L4_2.Callback = L5_2
    L5_2 = {}
    L6_2 = A0_2
    L7_2 = A1_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L4_2.CallbackData = L5_2
    L3_2(L4_2)
    L3_2 = Ai
    L3_2 = L3_2.SetHaste
    L4_2 = L2_2
    L5_2 = 0.7
    L3_2(L4_2, L5_2)
    L4_2 = A0_2
    L3_2 = A0_2._CreateEvent
    L5_2 = Event
    L5_2 = L5_2.TimerRelative
    L6_2 = {}
    L7_2 = 10
    L6_2[1] = L7_2
    L7_2 = VZChase
    L8_2 = {}
    L9_2 = A0_2
    L10_2 = A1_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  else
    L3_2 = SetupChaser
    L4_2 = A0_2
    L3_2(L4_2)
  end
end

VZChase = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  if A3_2 == 0 then
    L5_2 = A0_2
    L4_2 = A0_2._CreateEvent
    L6_2 = Event
    L6_2 = L6_2.TimerRelative
    L7_2 = {}
    L8_2 = 10
    L7_2[1] = L8_2
    L8_2 = VZChase
    L9_2 = {}
    L10_2 = A0_2
    L11_2 = A1_2
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  elseif A3_2 == 1 then
    L5_2 = A0_2
    L4_2 = A0_2._CreateEvent
    L6_2 = Event
    L6_2 = L6_2.TimerRelative
    L7_2 = {}
    L8_2 = 10
    L7_2[1] = L8_2
    L8_2 = VZChase
    L9_2 = {}
    L10_2 = A0_2
    L11_2 = A1_2
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  end
end

VZChaseTest = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L3_2 = Object
  L3_2 = L3_2.GetHardpointPosition
  L4_2 = A1_2
  L5_2 = "HP_Truckbed"
  L3_2, L4_2, L5_2 = L3_2(L4_2, L5_2)
  L6_2 = MrxUtil
  L6_2 = L6_2.GetDistanceBetween
  L7_2 = A1_2
  L8_2 = uPlayerPrim
  L9_2 = false
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  nDistCheck = L6_2
  L6_2 = uPickup
  if A1_2 == L6_2 then
    L6_2 = nDistCheck
    if L6_2 < 65 then
      L6_2 = Object
      L6_2 = L6_2.GetHardpointPosition
      L7_2 = A1_2
      L8_2 = "HP_Truckbed"
      L6_2, L7_2, L8_2 = L6_2(L7_2, L8_2)
      L9_2 = Pg
      L9_2 = L9_2.GetObjectsInArea
      L10_2 = L6_2
      L11_2 = L7_2
      L12_2 = L8_2
      L13_2 = 1
      L14_2 = "Organ Container"
      L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
      L10_2 = table
      L10_2 = L10_2.getn
      L11_2 = L9_2
      L10_2 = L10_2(L11_2)
      nP1Boxes = L10_2
  end
  else
    L6_2 = uPickupB
    if A1_2 == L6_2 then
      L6_2 = nDistCheck
      if L6_2 < 65 then
        L6_2 = Object
        L6_2 = L6_2.GetHardpointPosition
        L7_2 = A1_2
        L8_2 = "HP_Truckbed"
        L6_2, L7_2, L8_2 = L6_2(L7_2, L8_2)
        L9_2 = Pg
        L9_2 = L9_2.GetObjectsInArea
        L10_2 = L6_2
        L11_2 = L7_2
        L12_2 = L8_2
        L13_2 = 1
        L14_2 = "Organ Container"
        L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
        L10_2 = table
        L10_2 = L10_2.getn
        L11_2 = L9_2
        L10_2 = L10_2(L11_2)
        nP2Boxes = L10_2
      end
    end
  end
  L6_2 = DisplayOrganBoxesLost
  L7_2 = A0_2
  L6_2(L7_2)
end

CheckOrganBoxesLost = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "PirCon004_Dest_Location"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L2_2(L3_2)
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetObjectsInArea
  L6_2 = L1_2
  L7_2 = L2_2
  L8_2 = L3_2
  L9_2 = 12
  L10_2 = "Organ Container"
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L6_2 = eBoxCheck
  if L6_2 then
    L6_2 = Event
    L6_2 = L6_2.Delete
    L7_2 = eBoxCheck
    L6_2(L7_2)
  end
  L6_2 = eBoxCheck2
  if L6_2 then
    L6_2 = Event
    L6_2 = L6_2.Delete
    L7_2 = eBoxCheck2
    L6_2(L7_2)
  end
  L6_2 = table
  L6_2 = L6_2.getn
  L7_2 = L5_2
  L6_2 = L6_2(L7_2)
  nFinalGoods = L6_2
  L6_2 = DisplayOrganBoxesLost
  L7_2 = A0_2
  L6_2(L7_2)
end

FinalOrganBoxCheck = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = nP1Boxes
  L2_2 = nP2Boxes
  L1_2 = L1_2 + L2_2
  nGoods = L1_2
  L1_2 = nGoods
  nOrganBoxes = L1_2
  L1_2 = nGoods
  L1_2 = L1_2 * 1000
  nOrganBoxMoney = L1_2
  L1_2 = nPlayers
  if L1_2 == 1 then
    L1_2 = "[PirCon004.Display.Cargo]"
    L2_2 = MrxUtil
    L2_2 = L2_2.FormatMoney
    L3_2 = nOrganBoxMoney
    L2_2 = L2_2(L3_2)
    L1_2 = L1_2 .. L2_2
    sHudText = L1_2
  else
    L1_2 = "[PirCon004.Display.CargoCoop]"
    L2_2 = MrxUtil
    L2_2 = L2_2.FormatMoney
    L3_2 = nOrganBoxMoney
    L2_2 = L2_2(L3_2)
    L1_2 = L1_2 .. L2_2
    sHudText = L1_2
  end
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.SetSlotToText
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 1
  L4_2 = sHudText
  L3_2.sText = L4_2
  L1_2(L2_2, L3_2)
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.SetSlotToText
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 2
  L4_2 = "[PirCon004.Display.MinBoxes] "
  L5_2 = MrxUtil
  L5_2 = L5_2.FormatMoney
  L6_2 = nTargetBoxesDelivered
  L6_2 = L6_2 * 1000
  L5_2 = L5_2(L6_2)
  L4_2 = L4_2 .. L5_2
  L3_2.sText = L4_2
  L1_2(L2_2, L3_2)
  L1_2 = bFirstWarn
  if L1_2 then
    L1_2 = nGoods
    if L1_2 <= 25 then
      L1_2 = false
      bFirstWarn = L1_2
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = "Fiona-In-Mission-MinorContract-Pir04-01"
      L2_2[1] = L3_2
      L1_2(L2_2)
  end
  else
    L1_2 = bSecWarn
    if L1_2 then
      L1_2 = nGoods
      L2_2 = nTargetBoxesDelivered
      L2_2 = 5 + L2_2
      if L1_2 <= L2_2 then
        L1_2 = false
        bSecWarn = L1_2
        L1_2 = MrxVoSequence
        L1_2 = L1_2.Start
        L2_2 = {}
        L3_2 = "Fiona-In-Mission-MinorContract-Pir04-02"
        L2_2[1] = L3_2
        L1_2(L2_2)
      end
    end
  end
  L1_2 = bFinal
  if L1_2 then
    L1_2 = nGoods
    L2_2 = nTargetBoxesDelivered
    if L1_2 < L2_2 then
      L1_2 = false
      bFinal = L1_2
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = "Fiona-In-Mission-MinorContract-Pir04-03"
      L4_2 = {}
      L5_2 = A0_2.Cancel
      L6_2 = {}
      L7_2 = A0_2
      L6_2[1] = L7_2
      L4_2[1] = L5_2
      L4_2[2] = L6_2
      L2_2[1] = L3_2
      L2_2[2] = L4_2
      L1_2(L2_2)
    end
  end
end

DisplayOrganBoxesLost = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-MinorContract-Pir04-03"
  L4_2 = {}
  L5_2 = A0_2.Cancel
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
end

TruckDestroyed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = FinalOrganBoxCheck
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = nFinalGoods
  nOrganBoxesDelivered = L1_2
  L1_2 = nFinalGoods
  L2_2 = nStartingCargo
  if L1_2 == L2_2 then
    L1_2 = nPlayers
    L1_2 = 2000000 * L1_2
    nBonus = L1_2
  else
    L1_2 = nFinalGoods
    L2_2 = nGoal
    L1_2 = L1_2 - L2_2
    L1_2 = L1_2 * 1000
    L2_2 = nMod
    L1_2 = L1_2 * L2_2
    nBonus = L1_2
  end
  L1_2 = ClearTimer
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = true
  bFinished = L1_2
  L1_2 = oTalk
  if L1_2 then
    L1_2 = bFinished
    if L1_2 then
      L1_2 = oTalk
      L2_2 = L1_2
      L1_2 = L1_2.Cancel
      L1_2(L2_2)
    end
  end
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.SetSlotToText
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 3
  L4_2 = "[PirCon004.Display.Delivered] "
  L5_2 = MrxUtil
  L5_2 = L5_2.FormatMoney
  L6_2 = nFinalGoods
  L6_2 = L6_2 * 1000
  L5_2 = L5_2(L6_2)
  L4_2 = L4_2 .. L5_2
  L3_2.sText = L4_2
  L1_2(L2_2, L3_2)
  L1_2 = nPlayers
  if L1_2 == 2 then
    L2_2 = A0_2
    L1_2 = A0_2._SetPlayer1Bonus
    L3_2 = nBonus
    L4_2 = nPlayers
    L3_2 = L3_2 / L4_2
    L1_2(L2_2, L3_2)
    L2_2 = A0_2
    L1_2 = A0_2._SetPlayer2Bonus
    L3_2 = nBonus
    L4_2 = nPlayers
    L3_2 = L3_2 / L4_2
    L1_2(L2_2, L3_2)
    L1_2 = FinalTally
    L2_2 = A0_2
    L1_2(L2_2)
  else
    L2_2 = A0_2
    L1_2 = A0_2._SetPlayer1Bonus
    L3_2 = nBonus
    L1_2(L2_2, L3_2)
    L1_2 = FinalTally
    L2_2 = A0_2
    L1_2(L2_2)
  end
end

Delivered = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "PirCon004: Accept_the_Delivery"
  L3_2.sModuleName = "MrxTaskObjectiveAction"
  L3_2.sActionLabel = "[ContextAction.Talk]"
  L4_2 = uAccepter
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[PirCon004.Objectives.Objective03]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = DeliveryDiag
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnPartComplete = L4_2
  
  function L4_2()
    local L0_3, L1_3
    L0_3 = bFinished
    if L0_3 == false then
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3.Cancel
      L0_3(L1_3)
    end
  end
  
  L3_2.fOnCancel = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  oTalk = L1_2
end

DeliveryAccept = L0_1
L0_1 = 0
selfBackup = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = Net
  L2_2 = L2_2.IsServer
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = Player
    L2_2 = L2_2.GetSecondaryCharacter
    L2_2 = L2_2()
    if A1_2 == L2_2 then
      L2_2 = Net
      L2_2 = L2_2.SendCustomEvent
      L3_2 = "PirCon004"
      L4_2 = NETEVENT_CLIENTDIAGSHOW
      L5_2 = {}
      L2_2(L3_2, L4_2, L5_2)
      selfBackup = A0_2
  end
  else
    L2_2 = DisplayDiag
    L2_2()
  end
  L2_2 = MrxVoSequence
  L2_2 = L2_2.Start
  L3_2 = {}
  L4_2 = {}
  L5_2 = "OilExec-In-Mission-MinorContract-Pir04-05"
  L6_2 = uAccepter
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L3_2[1] = L4_2
  L2_2(L3_2)
end

DeliveryDiag = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L0_2 = {}
  L1_2 = "[PirCon004.Display.DialogOptA]"
  L2_2 = "[PirCon004.Display.DialogOptB]"
  L0_2[1] = L1_2
  L0_2[2] = L2_2
  tDiagOptions = L0_2
  L0_2 = MrxGui
  L0_2 = L0_2.DisplayDialogBox
  L1_2 = Player
  L1_2 = L1_2.GetLocalPlayer
  L1_2 = L1_2()
  L2_2 = "[PirCon004.Display.DialogMain]"
  L3_2 = tDiagOptions
  L4_2 = 1
  L5_2 = DeliveryDiagAction
  L6_2 = {}
  L7_2 = self
  L8_2 = tDiagOptions
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = 0
  L8_2 = 0
  L9_2 = "center"
  L10_2 = "center"
  L11_2 = false
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
end

DisplayDiag = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = Net
  L3_2 = L3_2.IsClient
  L3_2 = L3_2()
  if L3_2 then
    L3_2 = Net
    L3_2 = L3_2.SendCustomEvent
    L4_2 = "PirCon004"
    L5_2 = NETEVENT_CLIENTDIAGSELECT
    L6_2 = {}
    L7_2 = A2_2
    L6_2[1] = L7_2
    L3_2(L4_2, L5_2, L6_2)
    return
  end
  if A2_2 == 1 then
    L3_2 = oMainDelivery
    L3_2 = L3_2.Complete
    L4_2 = oMainDelivery
    L3_2(L4_2)
  elseif A2_2 == 2 then
    L4_2 = A0_2
    L3_2 = A0_2.DeliveryAccept
    L3_2(L4_2)
  end
end

DeliveryDiagAction = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = nOrganBoxesDelivered
  L2_2 = nTargetBoxesDelivered
  if L1_2 >= L2_2 then
    L1_2 = nPlayers
    if L1_2 == 2 then
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = "Fiona-In-Mission-MinorContract-Pir04-04"
      L4_2 = {}
      L5_2 = A0_2.Complete
      L6_2 = {}
      L7_2 = A0_2
      L6_2[1] = L7_2
      L4_2[1] = L5_2
      L4_2[2] = L6_2
      L2_2[1] = L3_2
      L2_2[2] = L4_2
      L1_2(L2_2)
  end
  else
    L1_2 = nOrganBoxesDelivered
    L2_2 = nTargetBoxesDelivered
    if L1_2 >= L2_2 then
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = {}
      L4_2 = "OilExec-In-Mission-MinorContract-Pir04-05"
      L5_2 = uAccepter
      L3_2[1] = L4_2
      L3_2[2] = L5_2
      L4_2 = "Fiona-In-Mission-MinorContract-Pir04-04"
      L5_2 = {}
      L6_2 = A0_2.Complete
      L7_2 = {}
      L8_2 = A0_2
      L7_2[1] = L8_2
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      L2_2[1] = L3_2
      L2_2[2] = L4_2
      L2_2[3] = L5_2
      L1_2(L2_2)
    else
      L1_2 = MrxVoSequence
      L1_2 = L1_2.Start
      L2_2 = {}
      L3_2 = "Fiona-In-Mission-MinorContract-Pir04-03"
      L4_2 = {}
      L5_2 = A0_2.Cancel
      L6_2 = {}
      L7_2 = A0_2
      L6_2[1] = L7_2
      L4_2[1] = L5_2
      L4_2[2] = L6_2
      L2_2[1] = L3_2
      L2_2[2] = L4_2
      L1_2(L2_2)
    end
  end
end

FinalTally = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = oMissionTimer
  L2_2 = L1_2
  L1_2 = L1_2.Stop
  L1_2(L2_2)
  L1_2 = nil
  oMissionTimer = L1_2
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.SetSlotToText
  L3_2 = {}
  L3_2.nSlot = 3
  L3_2.sText = " "
  L1_2(L2_2, L3_2)
end

ClearTimer = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L5_2 = Object
  L5_2 = L5_2.GetPosition
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = A2_2
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2 = L6_2(L7_2)
  L5_2, L6_2, L7_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  L9_2 = A0_2
  L8_2 = A0_2._CreateEvent
  L10_2 = Event
  L10_2 = L10_2.ObjectProximity
  L11_2 = {}
  L12_2 = tVeh
  L13_2 = A1_2
  L14_2 = "<"
  L15_2 = A4_2
  L16_2 = false
  L17_2 = false
  L11_2[1] = L12_2
  L11_2[2] = L13_2
  L11_2[3] = L14_2
  L11_2[4] = L15_2
  L11_2[5] = L16_2
  L11_2[6] = L17_2
  
  function L12_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L1_3 = Pg
    L1_3 = L1_3.Spawn
    L2_3 = A3_2
    L3_3 = L5_2
    L4_3 = L6_2
    L5_3 = L7_2
    L6_3 = 0
    L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
    uBoom = L1_3
    L1_3 = uBoom
    if L1_3 then
    end
    L2_3 = A0_3
    L1_3 = A0_3._CreateEvent
    L3_3 = Event
    L3_3 = L3_3.TimerRelative
    L4_3 = {}
    L5_3 = 0.1
    L4_3[1] = L5_3
    
    function L5_3(A0_4)
      local L1_4, L2_4, L3_4, L4_4, L5_4, L6_4
      L1_4 = Pg
      L1_4 = L1_4.Spawn
      L2_4 = A3_2
      L3_4 = L5_2
      L4_4 = L6_2
      L5_4 = L7_2
      L6_4 = 0
      L1_4 = L1_4(L2_4, L3_4, L4_4, L5_4, L6_4)
      uSecBoom = L1_4
      L1_4 = uSecBoom
      if L1_4 then
      end
    end
    
    L6_3 = {}
    L7_3 = A0_3
    L6_3[1] = L7_3
    L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
  end
  
  L13_2 = {}
  L14_2 = A0_2
  L13_2[1] = L14_2
  L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
end

ObstacleDetonate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "PirCon004_TruckSpawn"
  L1_2 = L1_2(L2_2)
  uVZSpawn = L1_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = uVZSpawn
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  L4_2 = Object
  L4_2 = L4_2.GetYaw
  L5_2 = uVZSpawn
  L4_2 = L4_2(L5_2)
  L5_2 = Pg
  L5_2 = L5_2.Spawn
  L6_2 = "M35 (Guntruck) (VZ) (Driver)"
  L7_2 = L1_2
  L8_2 = L2_2
  L9_2 = L3_2
  L10_2 = L4_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  uVZTruck = L5_2
  L5_2 = Vehicle
  L5_2 = L5_2.GetDriver
  L6_2 = uVZTruck
  L5_2 = L5_2(L6_2)
  uVZTrucker = L5_2
  L5_2 = table
  L5_2 = L5_2.insert
  L6_2 = tSpawnedItems
  L7_2 = uVZTruck
  L5_2(L6_2, L7_2)
  L6_2 = A0_2
  L5_2 = A0_2._CreateEvent
  L7_2 = Event
  L7_2 = L7_2.ObjectIsReady
  L8_2 = {}
  L9_2 = uVZTrucker
  L8_2[1] = L9_2
  
  function L9_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3
    L1_3 = Ai
    L1_3 = L1_3.Goal
    L2_3 = {}
    L3_3 = uVZTrucker
    L2_3.AIGuid = L3_3
    L2_3.Goal = "MoveTo"
    L3_3 = uVZGoal
    L2_3.Target = L3_3
    L2_3.Haste = 0.7
    L2_3.Priority = "HiPri"
    L3_3 = Ai
    L3_3 = L3_3.Role
    L2_3.Callback = L3_3
    L3_3 = {}
    L4_3 = uVZTrucker
    L3_3.AIGuid = L4_3
    L3_3.Role = "Idle"
    L3_3.Priority = "hiPri"
    L2_3.CallbackData = L3_3
    L1_3(L2_3)
  end
  
  L10_2 = {}
  L11_2 = A0_2
  L10_2[1] = L11_2
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
end

ObstacleTruck = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = oMissionTimer
  if L1_2 then
    L1_2 = ClearTimer
    L2_2 = A0_2
    L1_2(L2_2)
  end
  L1_2 = eCueMusic
  if L1_2 then
    L1_2 = MrxMusic
    L1_2 = L1_2.StopSpecialMusic
    L1_2()
  end
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 1
  L1_2(L2_2, L3_2)
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 2
  L1_2(L2_2, L3_2)
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 3
  L1_2(L2_2, L3_2)
  L1_2 = DangerousBuilding
  L1_2 = L1_2.SetRarity
  L2_2 = "all"
  L3_2 = "default"
  L1_2(L2_2, L3_2)
  L1_2 = MrxLayerManager
  L1_2 = L1_2.MarkForRemoval
  L2_2 = "VZ_state_PirCon004"
  L1_2(L2_2)
  L1_2 = bAddCoopLayer
  if L1_2 then
    L1_2 = MrxLayerManager
    L1_2 = L1_2.MarkForRemoval
    L2_2 = "VZ_state_PirCon004_Coop"
    L1_2(L2_2)
  end
  L1_2 = ipairs
  L2_2 = tSpawnedItems
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Object
    L6_2 = L6_2.Remove
    L7_2 = L5_2
    L6_2(L7_2)
  end
  L1_2 = ipairs
  L2_2 = tVeh
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Event
    L6_2 = L6_2.Create
    L7_2 = Event
    L7_2 = L7_2.ObjectHibernation
    L8_2 = {}
    L9_2 = L5_2
    L10_2 = "hibernated"
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L9_2 = Object
    L9_2 = L9_2.Remove
    L10_2 = {}
    L11_2 = L5_2
    L10_2[1] = L11_2
    L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
    eRemovePickup = L6_2
  end
  L1_2 = MrxFactionManager
  L1_2 = L1_2.ClearPursuitLock
  L1_2()
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1
L0_1 = 0
NETEVENT_CLIENTDIAGSHOW = L0_1
L0_1 = 1
NETEVENT_CLIENTDIAGSELECT = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = NETEVENT_CLIENTDIAGSHOW
  if A0_2 == L2_2 then
    L2_2 = DisplayDiag
    L2_2()
  else
    L2_2 = NETEVENT_CLIENTDIAGSELECT
    if A0_2 == L2_2 then
      L2_2 = selfBackup
      self = L2_2
      L2_2 = DeliveryDiagAction
      L3_2 = self
      L4_2 = {}
      L5_2 = A1_2[1]
      L2_2(L3_2, L4_2, L5_2)
    end
  end
end

NetEventCallback = L0_1
