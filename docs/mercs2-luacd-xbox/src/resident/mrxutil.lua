local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1, L18_1, L19_1, L20_1, L21_1, L22_1, L23_1, L24_1, L25_1, L26_1, L27_1, L28_1, L29_1, L30_1, L31_1, L32_1, L33_1, L34_1, L35_1, L36_1, L37_1, L38_1, L39_1, L40_1, L41_1
L0_1 = import
L1_1 = "MrxCheatBootstrap"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiShellBootstrap"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxState"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifPmcInterior"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxHqManager"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 == "function" then
    L2_2 = type
    L3_2 = A1_2
    L2_2 = L2_2(L3_2)
    if L2_2 == "table" then
      L2_2 = A0_2
      L3_2 = unpack
      L4_2 = A1_2
      L3_2, L4_2 = L3_2(L4_2)
      return L2_2(L3_2, L4_2)
    else
      L2_2 = A0_2
      return L2_2()
    end
  end
end

CallWithOptionalArgs = L0_1

function L0_1(A0_2, A1_2)
  if A0_2 == nil then
    A0_2 = A1_2
  end
  return A0_2
end

SetDefault = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = {}
  L2_2 = pairs
  L3_2 = A0_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = type
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    if L7_2 == "table" then
      L7_2 = CopyTable
      L8_2 = L6_2
      L7_2 = L7_2(L8_2)
      L1_2[L5_2] = L7_2
    else
      L1_2[L5_2] = L6_2
    end
  end
  return L1_2
end

CopyTable = L0_1

function L0_1(...)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L1_2 = {}
  L2_2 = ipairs
  L3_2 = arg
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = type
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    if L7_2 == "table" then
      L7_2 = ipairs
      L8_2 = L6_2
      L7_2, L8_2, L9_2 = L7_2(L8_2)
      for L10_2, L11_2 in L7_2, L8_2, L9_2 do
        L12_2 = table
        L12_2 = L12_2.insert
        L13_2 = L1_2
        L14_2 = L11_2
        L12_2(L13_2, L14_2)
      end
    end
  end
  return L1_2
end

MergeIndexedTables = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = SetDefault
  L3_2 = A1_2
  L4_2 = 0
  L2_2 = L2_2(L3_2, L4_2)
  A1_2 = L2_2
  L2_2 = ""
  L3_2 = pairs
  L4_2 = A0_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = 0
    L9_2 = A1_2
    L10_2 = 1
    for L11_2 = L8_2, L9_2, L10_2 do
      L12_2 = L2_2
      L13_2 = "\t"
      L2_2 = L12_2 .. L13_2
    end
    L8_2 = type
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    if L8_2 == "table" then
      L8_2 = L2_2
      L9_2 = tostring
      L10_2 = L6_2
      L9_2 = L9_2(L10_2)
      L10_2 = " = {\n"
      L11_2 = GetTableAsString
      L12_2 = L7_2
      L13_2 = A1_2 + 1
      L11_2 = L11_2(L12_2, L13_2)
      L2_2 = L8_2 .. L9_2 .. L10_2 .. L11_2
      L8_2 = 0
      L9_2 = A1_2
      L10_2 = 1
      for L11_2 = L8_2, L9_2, L10_2 do
        L12_2 = L2_2
        L13_2 = "\t"
        L2_2 = L12_2 .. L13_2
      end
      L8_2 = L2_2
      L9_2 = "}\n"
      L2_2 = L8_2 .. L9_2
    else
      L8_2 = L2_2
      L9_2 = tostring
      L10_2 = L6_2
      L9_2 = L9_2(L10_2)
      L10_2 = " = "
      L11_2 = tostring
      L12_2 = L7_2
      L11_2 = L11_2(L12_2)
      L12_2 = "\n"
      L2_2 = L8_2 .. L9_2 .. L10_2 .. L11_2 .. L12_2
    end
  end
  return L2_2
end

GetTableAsString = L0_1
L0_1 = false
_tNumbers = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = 1000
  L2_2 = "[0xe00c096a]"
  if 1.0E15 < A0_2 then
    A0_2 = 1.0E15
  end
  if A0_2 < 0 then
    A0_2 = 0
  end
  L3_2 = pairs
  L4_2 = _tNumbers
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    if L6_2 > L1_2 and L6_2 <= A0_2 then
      L1_2 = L6_2
      L2_2 = L7_2
    end
  end
  L3_2 = string
  L3_2 = L3_2.format
  L4_2 = "[SHELL.Common.Money:%d:%d:%s]"
  L5_2 = A0_2 / L1_2
  L6_2 = A0_2 / L1_2
  L7_2 = math
  L7_2 = L7_2.floor
  L8_2 = A0_2 / L1_2
  L7_2 = L7_2(L8_2)
  L6_2 = L6_2 - L7_2
  L6_2 = 10 * L6_2
  L7_2 = L2_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  return L3_2
end

FormatMoney = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L0_2 = Player
  L0_2 = L0_2.GetPrimaryPlayer
  L0_2 = L0_2()
  L1_2 = Player
  L1_2 = L1_2.GetSecondaryPlayer
  L1_2 = L1_2()
  L2_2 = Player
  L2_2 = L2_2.GetPrimaryCharacter
  L2_2 = L2_2()
  L3_2 = Player
  L3_2 = L3_2.GetSecondaryCharacter
  L3_2 = L3_2()
  L4_2 = Object
  L4_2 = L4_2.GetYaw
  L5_2 = L2_2
  L4_2 = L4_2(L5_2)
  L5_2 = Object
  L5_2 = L5_2.GetPosition
  L6_2 = L2_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L8_2 = Player
  L8_2 = L8_2.GetControlledObject
  L9_2 = L1_2
  L8_2 = L8_2(L9_2)
  if L8_2 and L8_2 ~= L3_2 then
    L9_2 = Vehicle
    L9_2 = L9_2.Exit
    L10_2 = L8_2
    L11_2 = L3_2
    L9_2(L10_2, L11_2)
  end
  L9_2 = Object
  L9_2 = L9_2.IsAlive
  L10_2 = L3_2
  L9_2 = L9_2(L10_2)
  if not L9_2 then
    L9_2 = Object
    L9_2 = L9_2.Revive
    L10_2 = L3_2
    L11_2 = 0.25
    L9_2(L10_2, L11_2)
  end
  L9_2 = Object
  L9_2 = L9_2.DisablePhysics
  L10_2 = L3_2
  L9_2(L10_2)
  L9_2 = Object
  L9_2 = L9_2.SetYaw
  L10_2 = L3_2
  L11_2 = L4_2
  L9_2(L10_2, L11_2)
  L9_2 = Player
  L9_2 = L9_2.GetCamera
  L10_2 = L1_2
  L9_2 = L9_2(L10_2)
  L10_2 = Camera
  L10_2 = L10_2.SetYaw
  L11_2 = L9_2
  L12_2 = 0
  L10_2(L11_2, L12_2)
  L10_2 = Player
  L10_2 = L10_2.SetWaitForInGame
  L11_2 = L3_2
  L10_2(L11_2)
  L10_2 = Object
  L10_2 = L10_2.SetPosition
  L11_2 = L3_2
  L12_2 = L5_2
  L13_2 = L6_2
  L14_2 = L7_2
  L15_2 = false
  L10_2(L11_2, L12_2, L13_2, L14_2, L15_2)
  L10_2 = Player
  L10_2 = L10_2.TeleportCamera
  if L10_2 then
    L10_2 = Player
    L10_2 = L10_2.TeleportCamera
    L11_2 = L1_2
    L10_2(L11_2)
  end
  L10_2 = Sys
  L10_2 = L10_2.RequestGameState
  L11_2 = "waitfortether"
  L10_2 = L10_2(L11_2)
  L11_2 = Event
  L11_2 = L11_2.Create
  L12_2 = Event
  L12_2 = L12_2.GameStateChange
  L13_2 = {}
  L14_2 = "waitfortether"
  L15_2 = "Exit"
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  
  function L14_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = Object
    L0_3 = L0_3.EnablePhysics
    L1_3 = L3_2
    L0_3(L1_3)
    L0_3 = Vehicle
    L0_3 = L0_3.GetFromRider
    L1_3 = L2_2
    L0_3 = L0_3(L1_3)
    L1_3 = EnterBestAvailableSeat
    L2_3 = L3_2
    L3_3 = L0_3
    L4_3 = 0
    L5_3 = true
    L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3)
    if L1_3 then
      L2_3 = Event
      L2_3 = L2_3.Create
      L3_3 = Event
      L3_3 = L3_3.TimerRelative
      L4_3 = {}
      L5_3 = 3
      L6_3 = true
      L4_3[1] = L5_3
      L4_3[2] = L6_3
      
      function L5_3()
        local L0_4, L1_4
        L0_4 = Object
        L0_4 = L0_4.EnablePhysics
        L1_4 = L3_2
        L0_4(L1_4)
        L0_4 = Player
        L0_4 = L0_4.TeleportCamera
        L1_4 = L1_2
        L0_4(L1_4)
      end
      
      L2_3(L3_3, L4_3, L5_3)
    end
  end
  
  L11_2(L12_2, L13_2, L14_2)
end

TeleportSecondaryHeroToPrimaryHero = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = Sys
  L0_2 = L0_2.RequestGameState
  L1_2 = "waitfortether"
  L0_2 = L0_2(L1_2)
  L1_2 = Player
  L1_2 = L1_2.GetSecondaryCharacter
  L1_2 = L1_2()
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.GameStateChange
  L4_2 = {}
  L5_2 = "waitfortether"
  L6_2 = "Exit"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  
  function L5_2()
    local L0_3, L1_3
  end
  
  L2_2(L3_2, L4_2, L5_2)
end

PlaceSecondaryPlayer = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2
  L5_2 = MrxCheatBootstrap
  L5_2 = L5_2.IsSkipModeEnabled
  L5_2 = L5_2()
  if L5_2 then
    L5_2 = CallWithOptionalArgs
    L6_2 = A1_2
    L7_2 = A2_2
    L5_2(L6_2, L7_2)
    return
  end
  L5_2 = SetDefault
  L6_2 = A3_2
  L7_2 = true
  L5_2 = L5_2(L6_2, L7_2)
  A3_2 = L5_2
  L5_2 = SetDefault
  L6_2 = A4_2
  L7_2 = true
  L5_2 = L5_2(L6_2, L7_2)
  A4_2 = L5_2
  L5_2 = Player
  L5_2 = L5_2.GetAllPlayers
  L5_2 = L5_2()
  L6_2 = {}
  L7_2 = ipairs
  L8_2 = L5_2
  L7_2, L8_2, L9_2 = L7_2(L8_2)
  for L10_2, L11_2 in L7_2, L8_2, L9_2 do
    L12_2 = Player
    L12_2 = L12_2.GetCharacter
    L13_2 = L11_2
    L12_2 = L12_2(L13_2)
    L13_2 = nil
    L14_2 = table
    L14_2 = L14_2.getn
    L15_2 = A0_2
    L14_2 = L14_2(L15_2)
    if L10_2 <= L14_2 then
      L13_2 = A0_2[L10_2]
    else
      L13_2 = A0_2[1]
    end
    L14_2 = nil
    L15_2 = nil
    L16_2 = nil
    L17_2 = nil
    L18_2 = type
    L19_2 = L13_2
    L18_2 = L18_2(L19_2)
    if 1 < L10_2 then
      L19_2 = L18_2 == "string" or L18_2 == "userdata" or L18_2 == "table"
      if not L19_2 then
        L13_2 = A0_2[1]
        L20_2 = type
        L21_2 = L13_2
        L20_2 = L20_2(L21_2)
        L18_2 = L20_2
      end
    end
    if L18_2 == "string" or L18_2 == "userdata" then
      if L18_2 == "string" then
        L19_2 = Pg
        L19_2 = L19_2.GetGuidByName
        L20_2 = L13_2
        L19_2 = L19_2(L20_2)
        L13_2 = L19_2
      end
      L19_2 = Object
      L19_2 = L19_2.GetPosition
      L20_2 = L13_2
      L19_2, L20_2, L21_2 = L19_2(L20_2)
      L16_2 = L21_2
      L15_2 = L20_2
      L14_2 = L19_2
      L19_2 = Object
      L19_2 = L19_2.GetYaw
      L20_2 = L13_2
      L19_2 = L19_2(L20_2)
      L17_2 = L19_2
    elseif L18_2 == "table" then
      L14_2 = L13_2[1]
      L15_2 = L13_2[2]
      L16_2 = L13_2[3]
      L19_2 = L13_2[4]
      L17_2 = L19_2 or L17_2
      if not L19_2 then
        L17_2 = 0
      end
    end
    if not (L12_2 and L14_2 and L15_2) or not L16_2 then
    else
      L19_2 = table
      L19_2 = L19_2.insert
      L20_2 = L6_2
      L21_2 = {}
      L21_2.uPlayer = L11_2
      L21_2.uHero = L12_2
      L21_2.nX = L14_2
      L21_2.nY = L15_2
      L21_2.nZ = L16_2
      L21_2.nYaw = L17_2
      L19_2(L20_2, L21_2)
      L19_2 = Net
      L19_2 = L19_2.IsServer
      L19_2 = L19_2()
      if L19_2 then
        L19_2 = Net
        L19_2 = L19_2.SetLastHeroTeleportLocation
        L20_2 = L14_2
        L21_2 = L15_2
        L22_2 = L16_2
        L23_2 = L17_2
        L19_2(L20_2, L21_2, L22_2, L23_2)
        L19_2 = Player
        L19_2 = L19_2.IsLocal
        L20_2 = L11_2
        L19_2 = L19_2(L20_2)
        if not L19_2 then
          L19_2 = Player
          L19_2 = L19_2.SetWaitForInGame
          L20_2 = L12_2
          L19_2(L20_2)
          if A3_2 == true then
            L19_2 = Net
            L19_2 = L19_2.SetLoadingScreen
            L20_2 = true
            L19_2(L20_2)
          end
          L19_2 = Net
          L19_2 = L19_2.SendEvent_TeleportPlayer
          L20_2 = L11_2
          L21_2 = L14_2
          L22_2 = L15_2
          L23_2 = L16_2
          L24_2 = L17_2
          L19_2(L20_2, L21_2, L22_2, L23_2, L24_2)
        end
      end
    end
  end
  L7_2 = _TeleportHeroes
  L8_2 = L6_2
  L9_2 = A1_2
  L10_2 = A2_2
  L11_2 = A3_2
  L12_2 = A4_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
end

TeleportHeroesToLocations = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAllPlayers
  L6_2 = L6_2()
  L7_2 = ipairs
  L8_2 = L6_2
  L7_2, L8_2, L9_2 = L7_2(L8_2)
  for L10_2, L11_2 in L7_2, L8_2, L9_2 do
    L12_2 = Player
    L12_2 = L12_2.GetCharacter
    L13_2 = L11_2
    L12_2 = L12_2(L13_2)
    L13_2 = A0_2[L10_2]
    if L13_2 then
      L14_2 = L13_2.vObject
      L15_2 = type
      L16_2 = L14_2
      L15_2 = L15_2(L16_2)
      if L15_2 == "string" then
        L15_2 = Pg
        L15_2 = L15_2.GetGuidByName
        L16_2 = L14_2
        L15_2 = L15_2(L16_2)
        L14_2 = L15_2
      end
      L15_2 = table
      L15_2 = L15_2.insert
      L16_2 = L5_2
      L17_2 = {}
      L17_2.uPlayer = L11_2
      L17_2.uHero = L12_2
      L17_2.uObject = L14_2
      L18_2 = L13_2.sHardpoint
      L17_2.sHardpoint = L18_2
      L15_2(L16_2, L17_2)
    end
  end
  L7_2 = SetDefault
  L8_2 = A3_2
  L9_2 = true
  L7_2 = L7_2(L8_2, L9_2)
  A3_2 = L7_2
  L7_2 = SetDefault
  L8_2 = A4_2
  L9_2 = true
  L7_2 = L7_2(L8_2, L9_2)
  A4_2 = L7_2
  L7_2 = _TeleportHeroes
  L8_2 = L5_2
  L9_2 = A1_2
  L10_2 = A2_2
  L11_2 = A3_2
  L12_2 = A4_2
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
end

TeleportHeroesToHardpoints = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L5_2 = table
  L5_2 = L5_2.getn
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  if L5_2 <= 0 then
    return
  end
  if A3_2 then
    L5_2 = Net
    L5_2 = L5_2.IsClient
    L5_2 = L5_2()
    if L5_2 then
      L5_2 = MrxState
      L5_2 = L5_2.SetQuickFade
      L6_2 = false
      L5_2(L6_2)
    end
    L5_2 = Net
    L5_2 = L5_2.IsServer
    L5_2 = L5_2()
    if L5_2 then
      L5_2 = Net
      L5_2 = L5_2.SetLoadingScreen
      L6_2 = true
      L5_2(L6_2)
    end
    L5_2 = MrxState
    L5_2 = L5_2.Enter
    L6_2 = MrxState
    L6_2 = L6_2.STATE_WAITFORSTREAMING
    L7_2 = _CompleteTeleportHeroes
    L8_2 = {}
    L9_2 = A0_2
    L10_2 = A1_2
    L11_2 = A2_2
    L12_2 = A3_2
    L13_2 = A4_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L8_2[4] = L12_2
    L8_2[5] = L13_2
    L9_2 = _TeleportStreamingComplete
    L10_2 = {}
    L11_2 = A0_2
    L12_2 = A1_2
    L13_2 = A2_2
    L14_2 = A4_2
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L10_2[3] = L13_2
    L10_2[4] = L14_2
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  else
    L5_2 = _TeleportStreamingComplete
    L6_2 = A0_2
    L7_2 = A1_2
    L8_2 = A2_2
    L9_2 = A4_2
    L5_2(L6_2, L7_2, L8_2, L9_2)
    L5_2 = _CompleteTeleportHeroes
    L6_2 = A0_2
    L7_2 = A1_2
    L8_2 = A2_2
    L9_2 = A3_2
    L10_2 = A4_2
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  end
end

_TeleportHeroes = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L5_2 = WifPmcInterior
  L5_2 = L5_2.IsInside
  L5_2 = L5_2()
  if L5_2 then
    L5_2 = WifPmcInterior
    L5_2 = L5_2.IsEntering
    L5_2 = L5_2()
    if not L5_2 then
      L5_2 = WifPmcInterior
      L5_2 = L5_2.Exit
      L6_2 = -1
      L7_2 = false
      L5_2(L6_2, L7_2)
    end
  end
  L5_2 = ipairs
  L6_2 = A0_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = Player
    L10_2 = L10_2.IsLocal
    L11_2 = L9_2.uPlayer
    L10_2 = L10_2(L11_2)
    if L10_2 then
      L10_2 = ExitAllPlayerModes
      L11_2 = L9_2.uPlayer
      L10_2(L11_2)
      L10_2 = Human
      L10_2 = L10_2.IsCarrying
      L11_2 = L9_2.uHero
      L10_2 = L10_2(L11_2)
      if L10_2 then
        L10_2 = Human
        L10_2 = L10_2.Drop
        L11_2 = L9_2.uHero
        L12_2 = true
        L10_2(L11_2, L12_2)
      end
      L10_2 = Human
      L10_2 = L10_2.IsGrappling
      L11_2 = L9_2.uHero
      L10_2 = L10_2(L11_2)
      if L10_2 then
        L10_2 = Human
        L10_2 = L10_2.StopGrappling
        L11_2 = L9_2.uHero
        L10_2(L11_2)
      end
      L10_2 = Player
      L10_2 = L10_2.GetControlledObject
      L11_2 = L9_2.uPlayer
      L10_2 = L10_2(L11_2)
      if L10_2 then
        L11_2 = L9_2.uHero
        if L10_2 ~= L11_2 then
          L11_2 = Vehicle
          L11_2 = L11_2.Exit
          L12_2 = L10_2
          L13_2 = L9_2.uHero
          L14_2 = true
          L11_2(L12_2, L13_2, L14_2)
          L11_2 = Event
          L11_2 = L11_2.Create
          L12_2 = Event
          L12_2 = L12_2.Player
          L13_2 = {}
          L14_2 = L9_2.uPlayer
          L15_2 = "Human"
          L16_2 = "Enter"
          L13_2[1] = L14_2
          L13_2[2] = L15_2
          L13_2[3] = L16_2
          L14_2 = _TeleportHero
          L15_2 = {}
          L16_2 = A0_2
          L17_2 = L8_2
          L18_2 = A4_2
          L19_2 = A1_2
          L20_2 = A2_2
          L15_2[1] = L16_2
          L15_2[2] = L17_2
          L15_2[3] = L18_2
          L15_2[4] = L19_2
          L15_2[5] = L20_2
          L11_2(L12_2, L13_2, L14_2, L15_2)
      end
      else
        L11_2 = Vehicle
        L11_2 = L11_2.GetFromRider
        L12_2 = L9_2.uHero
        L11_2 = L11_2(L12_2)
        if L11_2 then
          L12_2 = Vehicle
          L12_2 = L12_2.Exit
          L13_2 = L11_2
          L14_2 = L9_2.uHero
          L15_2 = true
          L12_2(L13_2, L14_2, L15_2)
        end
        L12_2 = Event
        L12_2 = L12_2.Create
        L13_2 = Event
        L13_2 = L13_2.TimerRelative
        L14_2 = {}
        L15_2 = 0.1
        L16_2 = true
        L14_2[1] = L15_2
        L14_2[2] = L16_2
        L15_2 = _TeleportHero
        L16_2 = {}
        L17_2 = A0_2
        L18_2 = L8_2
        L19_2 = A4_2
        L20_2 = A1_2
        L21_2 = A2_2
        L16_2[1] = L17_2
        L16_2[2] = L18_2
        L16_2[3] = L19_2
        L16_2[4] = L20_2
        L16_2[5] = L21_2
        L12_2(L13_2, L14_2, L15_2, L16_2)
      end
    end
  end
end

_CompleteTeleportHeroes = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  A0_2.bStreamingComplete = true
  L4_2 = _TeleportComplete
  L5_2 = A0_2
  L6_2 = A1_2
  L7_2 = A2_2
  L8_2 = A3_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
end

_TeleportStreamingComplete = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L5_2 = A0_2[A1_2]
  L6_2 = L5_2.nX
  if L6_2 then
    L6_2 = L5_2.nY
    if L6_2 then
      L6_2 = L5_2.nZ
    end
  end
  L6_2 = L6_2 ~= nil
  L7_2 = L5_2.uObject
  if L7_2 then
    L7_2 = L5_2.sHardpoint
  end
  L7_2 = L7_2 ~= nil
  if L6_2 or L7_2 then
    L8_2 = Human
    L8_2 = L8_2.SetState
    L9_2 = Player
    L9_2 = L9_2.GetLocalCharacter
    L9_2 = L9_2()
    L10_2 = "upright"
    L11_2 = "idle"
    L8_2(L9_2, L10_2, L11_2)
    L8_2 = Object
    L8_2 = L8_2.DisablePhysics
    L9_2 = L5_2.uHero
    L8_2(L9_2)
  end
  L8_2 = L5_2.nYaw
  if L8_2 then
    L8_2 = Object
    L8_2 = L8_2.SetYaw
    L9_2 = L5_2.uHero
    L10_2 = L5_2.nYaw
    L8_2(L9_2, L10_2)
  end
  if L6_2 or L7_2 then
    L8_2 = Object
    L8_2 = L8_2.IsAlive
    L9_2 = L5_2.uHero
    L8_2 = L8_2(L9_2)
    if not L8_2 then
      L8_2 = Object
      L8_2 = L8_2.Revive
      L9_2 = L5_2.uHero
      L10_2 = 0.25
      L8_2(L9_2, L10_2)
    end
    L8_2 = Player
    L8_2 = L8_2.SetWaitForInGame
    L9_2 = L5_2.uHero
    L8_2(L9_2)
    if L6_2 then
      L8_2 = Object
      L8_2 = L8_2.SetPosition
      L9_2 = L5_2.uHero
      L10_2 = L5_2.nX
      L11_2 = L5_2.nY
      L12_2 = L5_2.nZ
      L13_2 = false
      L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
    elseif L7_2 then
      L8_2 = L5_2.uObject
      L9_2 = L5_2.sHardpoint
      L10_2 = Object
      L10_2 = L10_2.SetTransformToObject
      L11_2 = L5_2.uHero
      L12_2 = L5_2.uObject
      L13_2 = L5_2.sHardpoint
      L10_2(L11_2, L12_2, L13_2)
      L10_2 = Net
      L10_2 = L10_2.IsServer
      L10_2 = L10_2()
      if L10_2 then
        L10_2 = Player
        L10_2 = L10_2.GetSecondaryPlayer
        L10_2 = L10_2()
        L11_2 = not L10_2
        if L11_2 ~= 0 then
          L11_2 = Player
          L11_2 = L11_2.IsLocal
          L12_2 = L10_2
          L11_2 = L11_2(L12_2)
          if not L11_2 then
            L11_2 = Net
            L11_2 = L11_2.SendEvent_TeleportPlayerToHardPoint
            L12_2 = L10_2
            L13_2 = L8_2
            L14_2 = L9_2
            L11_2(L12_2, L13_2, L14_2)
          end
        end
      end
    end
    L8_2 = Player
    L8_2 = L8_2.TeleportCamera
    L9_2 = L5_2.uPlayer
    L8_2(L9_2)
  end
  L8_2 = Human
  L8_2 = L8_2.PersistTransform
  L9_2 = L5_2.uHero
  L8_2(L9_2)
  L8_2 = A0_2[A1_2]
  L8_2.bComplete = true
  L8_2 = _TeleportComplete
  L9_2 = A0_2
  L10_2 = A3_2
  L11_2 = A4_2
  L12_2 = A2_2
  L8_2(L9_2, L10_2, L11_2, L12_2)
end

_TeleportHero = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L4_2 = ipairs
  L5_2 = A0_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
  end
  L4_2 = A0_2.bStreamingComplete
  if not L4_2 then
    return
  end
  L4_2 = ipairs
  L5_2 = A0_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = Player
    L9_2 = L9_2.IsLocal
    L10_2 = L8_2.uPlayer
    L9_2 = L9_2(L10_2)
    if L9_2 then
      L9_2 = L8_2.bComplete
      if not L9_2 then
        return
      end
    end
  end
  L4_2 = ipairs
  L5_2 = A0_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = Object
    L9_2 = L9_2.EnablePhysics
    L10_2 = L8_2.uHero
    L9_2(L10_2)
    L9_2 = Human
    L9_2 = L9_2.SetState
    L10_2 = L8_2.uHero
    L11_2 = "Upright"
    L12_2 = "Idle"
    L9_2(L10_2, L11_2, L12_2)
    L9_2 = Player
    L9_2 = L9_2.GetCamera
    L10_2 = L8_2.uPlayer
    L9_2 = L9_2(L10_2)
    if L9_2 then
      L10_2 = Camera
      L10_2 = L10_2.SetYaw
      L11_2 = L9_2
      L12_2 = 0
      L10_2(L11_2, L12_2)
      L10_2 = Camera
      L10_2 = L10_2.SetPitch
      L11_2 = L9_2
      L12_2 = 0.302
      L10_2(L11_2, L12_2)
    end
  end
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = 0.75
  L8_2 = true
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  
  function L7_2()
    local L0_3, L1_3, L2_3
    L0_3 = A3_2
    if L0_3 then
      L0_3 = MrxState
      L0_3 = L0_3.Exit
      L1_3 = MrxState
      L1_3 = L1_3.STATE_WAITFORSTREAMING
      L0_3(L1_3)
    end
    L0_3 = CallWithOptionalArgs
    L1_3 = A1_2
    L2_3 = A2_2
    L0_3(L1_3, L2_3)
  end
  
  L4_2(L5_2, L6_2, L7_2)
end

_TeleportComplete = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L4_2 = false
  if A0_2 and A1_2 then
    L5_2 = Vehicle
    L5_2 = L5_2.EnterBySeatGuid
    if L5_2 then
      L5_2 = Vehicle
      L5_2 = L5_2.GetSeatByType
      if L5_2 then
        L5_2 = "d"
        L6_2 = Vehicle
        L6_2 = L6_2.GetSeatByType
        L7_2 = A1_2
        L8_2 = L5_2
        L9_2 = true
        L6_2 = L6_2(L7_2, L8_2, L9_2)
        if not L6_2 or L6_2 == A2_2 then
          L5_2 = "g"
          L7_2 = Vehicle
          L7_2 = L7_2.GetSeatByType
          L8_2 = A1_2
          L9_2 = L5_2
          L10_2 = true
          L7_2 = L7_2(L8_2, L9_2, L10_2)
          L6_2 = L7_2
        end
        if not L6_2 or L6_2 == A2_2 then
          L5_2 = "p"
          L7_2 = Vehicle
          L7_2 = L7_2.GetSeatByType
          L8_2 = A1_2
          L9_2 = L5_2
          L10_2 = true
          L7_2 = L7_2(L8_2, L9_2, L10_2)
          L6_2 = L7_2
        end
        if not L6_2 or L6_2 == A2_2 then
          L5_2 = "c"
          L7_2 = Vehicle
          L7_2 = L7_2.GetSeatByType
          L8_2 = A1_2
          L9_2 = L5_2
          L10_2 = true
          L7_2 = L7_2(L8_2, L9_2, L10_2)
          L6_2 = L7_2
        end
        if L6_2 and L6_2 ~= A2_2 then
          if L5_2 == "d" then
          elseif L5_2 == "g" then
          elseif L5_2 == "p" then
          elseif L5_2 == "c" then
          end
          L7_2 = Vehicle
          L7_2 = L7_2.EnterBySeatGuid
          L8_2 = A1_2
          L9_2 = A0_2
          L10_2 = L6_2
          L11_2 = A3_2
          L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
          L4_2 = L7_2
        end
      end
    end
  end
  return L4_2
end

EnterBestAvailableSeat = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 == "table" then
    L2_2 = ipairs
    L3_2 = A0_2
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2, L6_2 in L2_2, L3_2, L4_2 do
      L7_2 = L6_2[2]
      L8_2 = nil
      L9_2 = type
      L10_2 = L7_2
      L9_2 = L9_2(L10_2)
      L9_2 = L9_2 == "table"
      L10_2 = type
      L11_2 = A1_2
      L10_2 = L10_2(L11_2)
      L10_2 = L10_2 == "table"
      if L9_2 and L10_2 then
        L11_2 = MergeIndexedTables
        L12_2 = L7_2
        L13_2 = A1_2
        L11_2 = L11_2(L12_2, L13_2)
        L8_2 = L11_2
      elseif L9_2 then
        L8_2 = L7_2
      elseif L10_2 then
        L8_2 = A1_2
      end
      L11_2 = CallWithOptionalArgs
      L12_2 = L6_2[1]
      L13_2 = L8_2
      L11_2(L12_2, L13_2)
    end
  end
end

ProcessCallbackTable = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  if not A2_2 then
    L4_2 = Player
    L4_2 = L4_2.GetPrimaryCharacter
    L4_2 = L4_2()
    A2_2 = L4_2
  end
  L4_2 = Player
  L4_2 = L4_2.GetPrimaryCharacter
  L4_2 = L4_2()
  if A2_2 == L4_2 then
    L4_2 = Player
    L4_2 = L4_2.GetSecondaryCharacter
    L4_2 = L4_2()
    L3_2 = L4_2
  else
    L4_2 = Player
    L4_2 = L4_2.GetPrimaryCharacter
    L4_2 = L4_2()
    L3_2 = L4_2
  end
  if L3_2 == nil then
    L3_2 = 0
  end
  L4_2 = Pg
  L4_2 = L4_2.GetDistantSpawnPointOnPath
  L5_2 = A0_2
  L6_2 = A2_2
  L7_2 = L3_2
  L8_2 = A1_2
  return L4_2(L5_2, L6_2, L7_2, L8_2)
end

FindSpawnPointOutOfView = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L3_2 = type
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if L3_2 == "string" then
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = A1_2
    L3_2 = L3_2(L4_2)
    A1_2 = L3_2
  end
  L3_2 = nil
  if A1_2 then
    L4_2 = Object
    L4_2 = L4_2.GetPosition
    L5_2 = A1_2
    L4_2, L5_2, L6_2 = L4_2(L5_2)
    L7_2 = Object
    L7_2 = L7_2.GetYaw
    L8_2 = A1_2
    L7_2 = L7_2(L8_2)
    L8_2 = Pg
    L8_2 = L8_2.Spawn
    L9_2 = A0_2
    L10_2 = L4_2
    L11_2 = L5_2
    L12_2 = L6_2
    L13_2 = L7_2
    L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
    L3_2 = L8_2
    if L3_2 and A2_2 then
      L8_2 = Object
      L8_2 = L8_2.SetName
      L9_2 = L3_2
      L10_2 = A2_2
      L8_2(L9_2, L10_2)
    end
  end
  return L3_2
end

SpawnObject = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2)
  local L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L9_2 = Pg
  L9_2 = L9_2.GetGuidByName
  L10_2 = A1_2
  L9_2 = L9_2(L10_2)
  if not L9_2 then
    L10_2 = Pg
    L10_2 = L10_2.Spawn
    L11_2 = A0_2
    L12_2 = 0
    L13_2 = 0
    L14_2 = 0
    L15_2 = 0
    L16_2 = false
    L17_2 = true
    L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
    L9_2 = L10_2
    if not L9_2 then
      L10_2 = nil
      return L10_2
    end
  end
  if A1_2 then
    L10_2 = Object
    L10_2 = L10_2.SetName
    L11_2 = L9_2
    L12_2 = A1_2
    L10_2(L11_2, L12_2)
  end
  L10_2 = type
  L11_2 = A2_2
  L10_2 = L10_2(L11_2)
  if L10_2 == "string" then
    L10_2 = Pg
    L10_2 = L10_2.GetGuidByName
    L11_2 = A2_2
    L10_2 = L10_2(L11_2)
    if L10_2 then
      L11_2 = Object
      L11_2 = L11_2.SetTransformToObject
      L12_2 = L9_2
      L13_2 = L10_2
      L14_2 = A3_2
      L11_2(L12_2, L13_2, L14_2)
      if A5_2 == true then
        L11_2 = Object
        L11_2 = L11_2.Attach
        L12_2 = L10_2
        L13_2 = A3_2
        L14_2 = L9_2
        L11_2(L12_2, L13_2, L14_2)
      end
    end
  else
    L10_2 = Object
    L10_2 = L10_2.SetPosition
    L11_2 = L9_2
    L12_2 = A2_2[1]
    L13_2 = A2_2[2]
    L14_2 = A2_2[3]
    L10_2(L11_2, L12_2, L13_2, L14_2)
  end
  L10_2 = type
  L11_2 = A4_2
  L10_2 = L10_2(L11_2)
  if L10_2 == "number" then
    L10_2 = Object
    L10_2 = L10_2.SetYaw
    L11_2 = L9_2
    L12_2 = A4_2
    L10_2(L11_2, L12_2)
  end
  L10_2 = A1_2 == "HqInterior"
  L11_2 = nil
  L12_2 = Event
  L12_2 = L12_2.Create
  L13_2 = Event
  L13_2 = L13_2.ObjectHibernation
  L14_2 = {}
  L15_2 = L9_2
  L16_2 = "awake"
  L17_2 = L11_2
  L14_2[1] = L15_2
  L14_2[2] = L16_2
  L14_2[3] = L17_2
  L15_2 = _SpawnActorComplete
  L16_2 = {}
  L17_2 = L9_2
  L18_2 = A1_2
  L19_2 = L10_2
  L20_2 = A7_2
  L21_2 = A8_2
  L16_2[1] = L17_2
  L16_2[2] = L18_2
  L16_2[3] = L19_2
  L16_2[4] = L20_2
  L16_2[5] = L21_2
  L12_2(L13_2, L14_2, L15_2, L16_2)
  return L9_2
end

SpawnActor = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2
  if not A2_2 then
    L5_2 = Ai
    L5_2 = L5_2.Enable
    L6_2 = A0_2
    L7_2 = false
    L5_2(L6_2, L7_2)
    L5_2 = Object
    L5_2 = L5_2.DisablePhysics
    L6_2 = A0_2
    L5_2(L6_2)
    L5_2 = Vehicle
    L5_2 = L5_2.EnableTurret
    L6_2 = A0_2
    L7_2 = "head"
    L8_2 = false
    L5_2(L6_2, L7_2, L8_2)
  end
  if A3_2 then
    L5_2 = CallWithOptionalArgs
    L6_2 = A3_2
    L7_2 = A4_2
    L5_2(L6_2, L7_2)
  end
end

_SpawnActorComplete = L0_1

function L0_1(A0_2, A1_2, A2_2)
  A0_2._nLoadPending = 0
  A0_2._fLoadCallback = A1_2
  A0_2._tLoadData = A2_2
end

SetupLoadingCallback = L0_1

function L0_1(A0_2)
  local L1_2
  A0_2._nLoadPending = nil
  A0_2._fLoadCallback = nil
  A0_2._tLoadData = nil
end

CleanupLoadingCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = A0_2._nLoadPending
  if L1_2 ~= nil then
    L1_2 = A0_2._nLoadPending
    L1_2 = L1_2 - 1
    A0_2._nLoadPending = L1_2
    L1_2 = A0_2._nLoadPending
    if 0 < L1_2 then
      return
    end
  end
  L1_2 = A0_2._fLoadCallback
  L2_2 = A0_2._tLoadData
  A0_2._nLoadPending = nil
  A0_2._fLoadCallback = nil
  A0_2._tLoadData = nil
  if L1_2 then
    L3_2 = CallWithOptionalArgs
    L4_2 = L1_2
    L5_2 = L2_2
    L3_2(L4_2, L5_2)
  else
  end
end

LoadingCallback = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = {}
  L0_2.mattias = "Mattias"
  L0_2.jennifer = "Jennifer"
  L0_2.chris = "Chris"
  L1_2 = GetCharacterIdentity
  L2_2 = Player
  L2_2 = L2_2.GetPrimaryCharacter
  L2_2 = L2_2()
  L1_2 = L1_2(L2_2)
  L2_2 = L0_2[L1_2]
  return L2_2
end

GetPrimaryCharacterName = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = string
  L1_2 = L1_2.sub
  L2_2 = A0_2
  L3_2 = 1
  L4_2 = 3
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  L2_2 = string
  L2_2 = L2_2.sub
  L3_2 = A0_2
  L4_2 = 4
  L5_2 = 6
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  L3_2 = string
  L3_2 = L3_2.sub
  L4_2 = A0_2
  L5_2 = 7
  L6_2 = 9
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L4_2 = nil
  if L2_2 == "Con" then
    L4_2 = true
  elseif L2_2 == "Job" then
    L4_2 = false
  end
  L5_2 = tonumber
  L6_2 = L3_2
  L5_2 = L5_2(L6_2)
  L6_2 = L1_2
  L7_2 = L4_2
  L8_2 = L5_2
  return L6_2, L7_2, L8_2
end

ExplodeMissionName = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L5_2 = type
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  if L5_2 == "string" then
    L5_2 = Pg
    L5_2 = L5_2.GetGuidByName
    L6_2 = A0_2
    L5_2 = L5_2(L6_2)
    A0_2 = L5_2
  end
  L5_2 = Object
  L5_2 = L5_2.GetDistanceFrom
  L6_2 = A0_2
  L7_2 = A1_2
  L8_2 = A2_2
  L9_2 = A3_2
  L10_2 = A4_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  if not L5_2 then
    return
  end
  return L5_2
end

GetDistanceToObject = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = type
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if L3_2 == "string" then
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
    A0_2 = L3_2
  end
  L3_2 = type
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if L3_2 == "string" then
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = A1_2
    L3_2 = L3_2(L4_2)
    A1_2 = L3_2
  end
  L3_2 = Object
  L3_2 = L3_2.GetDistanceFrom
  L4_2 = A0_2
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  if not L3_2 then
    return
  end
  return L3_2
end

GetDistanceBetween = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = type
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if L3_2 == "string" then
    L3_2 = Pg
    L3_2 = L3_2.GetGuidByName
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
    A0_2 = L3_2
  end
  if not A0_2 or not A1_2 then
    return
  end
  L3_2 = Player
  L3_2 = L3_2.GetAllPlayers
  L3_2 = L3_2()
  L4_2 = ipairs
  L5_2 = L3_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = GetDistanceBetween
    L10_2 = Player
    L10_2 = L10_2.GetCharacter
    L11_2 = L8_2
    L10_2 = L10_2(L11_2)
    L11_2 = A0_2
    L12_2 = A2_2
    L9_2 = L9_2(L10_2, L11_2, L12_2)
    if A1_2 > L9_2 then
      L9_2 = false
      return L9_2
    end
  end
  L4_2 = true
  return L4_2
end

TestDistanceToAllPlayers = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = type
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if L3_2 ~= "table" or not A1_2 then
    return
  end
  L3_2 = {}
  tGoodLocs = L3_2
  L3_2 = pairs
  L4_2 = A0_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = L7_2
    L9_2 = type
    L10_2 = L7_2
    L9_2 = L9_2(L10_2)
    if L9_2 == "string" then
      L9_2 = Pg
      L9_2 = L9_2.GetGuidByName
      L10_2 = L7_2
      L9_2 = L9_2(L10_2)
      L8_2 = L9_2
    end
    L9_2 = TestDistanceToAllPlayers
    L10_2 = L8_2
    L11_2 = A1_2
    L12_2 = A2_2
    L9_2 = L9_2(L10_2, L11_2, L12_2)
    if L9_2 then
      L9_2 = table
      L9_2 = L9_2.insert
      L10_2 = tGoodLocs
      L11_2 = L7_2
      L9_2(L10_2, L11_2)
    end
  end
  L3_2 = tGoodLocs
  return L3_2
end

GetDistantLocations = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = {}
  L2_2 = "mattias"
  L3_2 = "jennifer"
  L4_2 = "chris"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = Object
    L7_2 = L7_2.HasLabel
    L8_2 = A0_2
    L9_2 = L6_2
    L7_2 = L7_2(L8_2, L9_2)
    if L7_2 then
      return L6_2
    end
  end
  L2_2 = L1_2[1]
  return L2_2
end

GetCharacterIdentity = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Player
  L1_2 = L1_2.GetPrimaryCharacter
  L1_2 = L1_2()
  L2_2 = Player
  L2_2 = L2_2.GetSecondaryCharacter
  L2_2 = L2_2()
  L3_2 = ipairs
  L4_2 = {}
  L5_2 = L1_2
  L6_2 = L2_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    if L7_2 then
      if A0_2 then
        L8_2 = Human
        L8_2 = L8_2.EnableWeapons
        L9_2 = L7_2
        L8_2(L9_2)
        L8_2 = Player
        L8_2 = L8_2.SetAimMode
        L9_2 = Player
        L9_2 = L9_2.GetLocalPlayer
        L9_2 = L9_2()
        L10_2 = true
        L8_2(L9_2, L10_2)
      else
        L8_2 = Human
        L8_2 = L8_2.DisableWeapons
        L9_2 = L7_2
        L8_2(L9_2)
        L8_2 = Player
        L8_2 = L8_2.SetAimMode
        L9_2 = Player
        L9_2 = L9_2.GetLocalPlayer
        L9_2 = L9_2()
        L10_2 = false
        L8_2(L9_2, L10_2)
      end
    end
  end
end

EnableHeroWeapons = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L2_2 = table
  L2_2 = L2_2.getn
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if 0 < L2_2 then
    L3_2 = Math
    L3_2 = L3_2.randi
    L4_2 = 1
    L5_2 = L2_2
    L3_2 = L3_2(L4_2, L5_2)
    L1_2 = A0_2[L3_2]
  end
  return L1_2
end

GetRandomTableElement = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = {}
  L2_2 = "VZ"
  L3_2 = "Allied"
  L4_2 = "China"
  L5_2 = "Guerilla"
  L6_2 = "OC"
  L7_2 = "Pirate"
  L8_2 = "PMC"
  L9_2 = "Civ"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L1_2[7] = L8_2
  L1_2[8] = L9_2
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = Object
    L7_2 = L7_2.HasLabel
    L8_2 = A0_2
    L9_2 = L6_2
    L7_2 = L7_2(L8_2, L9_2)
    if L7_2 then
      return L6_2
    end
  end
end

GetFaction = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = MrxGui
  L2_2 = L2_2.GetWidgetByNameAndOwner
  L3_2 = "Satellite overlay"
  L4_2 = Player
  L4_2 = L4_2.GetLocalPlayer
  L4_2 = L4_2()
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    L3_2 = L2_2.CustomData
    L3_2 = L3_2.bActivated
    if L3_2 then
      return
    end
  end
  L3_2 = Graphics
  L3_2 = L3_2.SetBoundaryEffect
  L4_2 = A1_2
  L3_2(L4_2)
end

SetBoundaryEffect = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L5_2 = tHealthBar
  if not L5_2 then
    L5_2 = {}
  end
  tHealthBar = L5_2
  L5_2 = tHealthBar
  L6_2 = tHealthBar
  L6_2 = L6_2[A1_2]
  if not L6_2 then
    L6_2 = {}
  end
  L5_2[A1_2] = L6_2
  L5_2 = type
  L6_2 = A1_2
  L5_2 = L5_2(L6_2)
  if L5_2 == "string" then
    L5_2 = Pg
    L5_2 = L5_2.GetGuidByName
    L6_2 = A1_2
    L5_2 = L5_2(L6_2)
    A1_2 = L5_2
  end
  if A4_2 then
    L5_2 = 2
    nBarSlot = L5_2
  else
    L5_2 = 1
    nBarSlot = L5_2
  end
  L5_2 = Object
  L5_2 = L5_2.GetMaxHealth
  L6_2 = A1_2
  L5_2 = L5_2(L6_2)
  L6_2 = Object
  L6_2 = L6_2.GetHealth
  L7_2 = A1_2
  L6_2 = L6_2(L7_2)
  L7_2 = math
  L7_2 = L7_2.floor
  L8_2 = L6_2 / L5_2
  L8_2 = L8_2 * 100
  L7_2 = L7_2(L8_2)
  L8_2 = "[green]"
  if L7_2 < 35 then
    L8_2 = "[red]"
  elseif L7_2 < 75 then
    L8_2 = "[yellow]"
  end
  L9_2 = Object
  L9_2 = L9_2.GetLocalizedName
  L10_2 = A1_2
  L9_2 = L9_2(L10_2)
  L10_2 = ":"
  L11_2 = L8_2
  L12_2 = "[bar"
  L13_2 = L7_2
  L14_2 = "]"
  L9_2 = L9_2 .. L10_2 .. L11_2 .. L12_2 .. L13_2 .. L14_2
  sHudText = L9_2
  L9_2 = Hud
  L9_2 = L9_2.ObjectiveTray
  L10_2 = L9_2
  L9_2 = L9_2.SetSlotToText
  L11_2 = {}
  L12_2 = nBarSlot
  L11_2.nSlot = L12_2
  L12_2 = sHudText
  L11_2.sText = L12_2
  L9_2(L10_2, L11_2)
  if 0 < L6_2 then
    L9_2 = tHealthBar
    L9_2 = L9_2[A1_2]
    L11_2 = A0_2
    L10_2 = A0_2._CreateEvent
    L12_2 = Event
    L12_2 = L12_2.ObjectHealth
    L13_2 = {}
    L14_2 = A1_2
    L15_2 = "<"
    L16_2 = L6_2
    L13_2[1] = L14_2
    L13_2[2] = L15_2
    L13_2[3] = L16_2
    L14_2 = DisplayHealthBar
    L15_2 = {}
    L16_2 = A0_2
    L17_2 = A1_2
    L18_2 = L6_2
    L19_2 = A3_2
    L20_2 = A4_2
    L15_2[1] = L16_2
    L15_2[2] = L17_2
    L15_2[3] = L18_2
    L15_2[4] = L19_2
    L15_2[5] = L20_2
    L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2, L15_2)
    L9_2.HealthEvent = L10_2
  end
  L9_2 = "[yellow]"
  if A3_2 then
    L9_2 = "[green]"
  end
  if A2_2 and A2_2 > L6_2 then
    L10_2 = Hud
    L10_2 = L10_2.ObjectiveTray
    L11_2 = L10_2
    L10_2 = L10_2.SetSlotToText
    L12_2 = {}
    L13_2 = nBarSlot
    L12_2.nSlot = L13_2
    L13_2 = "[red]"
    L14_2 = Object
    L14_2 = L14_2.GetLocalizedName
    L15_2 = A1_2
    L14_2 = L14_2(L15_2)
    L15_2 = ":"
    L16_2 = L9_2
    L17_2 = "[bar"
    L18_2 = L7_2
    L19_2 = "]"
    L13_2 = L13_2 .. L14_2 .. L15_2 .. L16_2 .. L17_2 .. L18_2 .. L19_2
    L12_2.sText = L13_2
    L10_2(L11_2, L12_2)
    L10_2 = tHealthBar
    L10_2 = L10_2[A1_2]
    L12_2 = A0_2
    L11_2 = A0_2._CreateEvent
    L13_2 = Event
    L13_2 = L13_2.TimerRelative
    L14_2 = {}
    L15_2 = 0.35
    L14_2[1] = L15_2
    
    function L15_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
      L0_3 = Hud
      L0_3 = L0_3.ObjectiveTray
      L1_3 = L0_3
      L0_3 = L0_3.SetSlotToText
      L2_3 = {}
      L3_3 = nBarSlot
      L2_3.nSlot = L3_3
      L3_3 = L9_2
      L4_3 = Object
      L4_3 = L4_3.GetLocalizedName
      L5_3 = A1_2
      L4_3 = L4_3(L5_3)
      L5_3 = ":"
      L6_3 = L9_2
      L7_3 = "[bar"
      L8_3 = L7_2
      L9_3 = "]"
      L3_3 = L3_3 .. L4_3 .. L5_3 .. L6_3 .. L7_3 .. L8_3 .. L9_3
      L2_3.sText = L3_3
      L0_3(L1_3, L2_3)
    end
    
    L11_2 = L11_2(L12_2, L13_2, L14_2, L15_2)
    L10_2.TimerEvent = L11_2
  else
    L10_2 = Hud
    L10_2 = L10_2.ObjectiveTray
    L11_2 = L10_2
    L10_2 = L10_2.SetSlotToText
    L12_2 = {}
    L13_2 = nBarSlot
    L12_2.nSlot = L13_2
    L13_2 = L9_2
    L14_2 = Object
    L14_2 = L14_2.GetLocalizedName
    L15_2 = A1_2
    L14_2 = L14_2(L15_2)
    L15_2 = ":"
    L16_2 = L9_2
    L17_2 = "[bar"
    L18_2 = L7_2
    L19_2 = "]"
    L13_2 = L13_2 .. L14_2 .. L15_2 .. L16_2 .. L17_2 .. L18_2 .. L19_2
    L12_2.sText = L13_2
    L10_2(L11_2, L12_2)
  end
end

DisplayHealthBar = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = tHealthBar
  if L1_2 then
    L1_2 = tHealthBar
    L1_2 = L1_2[A0_2]
    if L1_2 then
      L1_2 = Event
      L1_2 = L1_2.Delete
      L2_2 = tHealthBar
      L2_2 = L2_2[A0_2]
      L2_2 = L2_2.HealthEvent
      L1_2(L2_2)
      L1_2 = Event
      L1_2 = L1_2.Delete
      L2_2 = tHealthBar
      L2_2 = L2_2[A0_2]
      L2_2 = L2_2.TimerEvent
      L1_2(L2_2)
      L1_2 = Hud
      L1_2 = L1_2.ObjectiveTray
      L2_2 = L1_2
      L1_2 = L1_2.SetSlotToText
      L3_2 = {}
      L4_2 = nBarSlot
      L3_2.nSlot = L4_2
      L3_2.sText = " "
      L1_2(L2_2, L3_2)
    else
    end
  end
end

StopHealthBar = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = 255
  L1_2 = 200
  L2_2 = 0
  return L0_2, L1_2, L2_2
end

GetPrimaryObjectiveRgb = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = 51
  L1_2 = 204
  L2_2 = 153
  return L0_2, L1_2, L2_2
end

GetSecondaryObjectiveRgb = L0_1
L0_1 = {}
L1_1 = "[objaction]"
L2_1 = "[objaction2]"
L3_1 = "[objoutpost]"
L4_1 = "[objoutpost2]"
L5_1 = "[objdeliver]"
L6_1 = "[objdeliver2]"
L7_1 = "[objdestroy]"
L8_1 = "[objdestroy2]"
L9_1 = "[objdefend]"
L10_1 = "[objdefend2]"
L11_1 = "[objverify]"
L12_1 = "[objverify2]"
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1
L0_1[5] = L5_1
L0_1[6] = L6_1
L0_1[7] = L7_1
L0_1[8] = L8_1
L0_1[9] = L9_1
L0_1[10] = L10_1
L0_1[11] = L11_1
L0_1[12] = L12_1
tInlineIcons = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = ipairs
  L2_2 = tInlineIcons
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    if A0_2 == L5_2 then
      return L4_2
    end
  end
end

GetInlineIconIndexByName = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = tInlineIcons
  L1_2 = L1_2[A0_2]
  return L1_2
end

GetInlineIconNameByIndex = L0_1
L0_1 = {}
L1_1 = "global_objectivemarker"
L2_1 = "MiniMap_Icon_Symbol_Yellow"
L3_1 = "HUD_objective_action"
L4_1 = "HUD_objective_outpost"
L5_1 = "HUD_objective_defend"
L6_1 = "HUD_objective_destroy"
L7_1 = "HUD_objective_verify"
L8_1 = "HUD_objective_deliverable"
L9_1 = "HUD_objective_timer"
L10_1 = "HUD_faction_GR"
L11_1 = "HUD_faction_OC"
L12_1 = "HUD_faction_PR"
L13_1 = "HUD_faction_AN"
L14_1 = "HUD_faction_CH"
L15_1 = "HUD_Outpost_AN"
L16_1 = "HUD_Outpost_CH"
L17_1 = "HUD_Outpost_GR"
L18_1 = "HUD_Outpost_OC"
L19_1 = "HUD_Outpost_PR"
L20_1 = "HUD_Outpost_AN_locked"
L21_1 = "HUD_Outpost_CH_locked"
L22_1 = "HUD_Outpost_GR_locked"
L23_1 = "HUD_Outpost_OC_locked"
L24_1 = "HUD_Outpost_PR_locked"
L25_1 = "HUD_HQ_GR"
L26_1 = "HUD_HQ_OC"
L27_1 = "HUD_HQ_PMC"
L28_1 = "HUD_HQ_CH"
L29_1 = "HUD_HQ_AN"
L30_1 = "HUD_HQ_AN_locked"
L31_1 = "HUD_HQ_CH_locked"
L32_1 = "HUD_HQ_GR_locked"
L33_1 = "HUD_HQ_OC_locked"
L34_1 = "pickup_fuel"
L35_1 = "pickup_muntions"
L36_1 = "HUD_PMC_Eva"
L37_1 = "HUD_PMC_Ewan"
L38_1 = "HUD_PMC_Fiona"
L39_1 = "HUD_PMC_Misha"
L40_1 = "HUD_exit"
L41_1 = "HUD_wardrobe"
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1
L0_1[5] = L5_1
L0_1[6] = L6_1
L0_1[7] = L7_1
L0_1[8] = L8_1
L0_1[9] = L9_1
L0_1[10] = L10_1
L0_1[11] = L11_1
L0_1[12] = L12_1
L0_1[13] = L13_1
L0_1[14] = L14_1
L0_1[15] = L15_1
L0_1[16] = L16_1
L0_1[17] = L17_1
L0_1[18] = L18_1
L0_1[19] = L19_1
L0_1[20] = L20_1
L0_1[21] = L21_1
L0_1[22] = L22_1
L0_1[23] = L23_1
L0_1[24] = L24_1
L0_1[25] = L25_1
L0_1[26] = L26_1
L0_1[27] = L27_1
L0_1[28] = L28_1
L0_1[29] = L29_1
L0_1[30] = L30_1
L0_1[31] = L31_1
L0_1[32] = L32_1
L0_1[33] = L33_1
L0_1[34] = L34_1
L0_1[35] = L35_1
L0_1[36] = L36_1
L0_1[37] = L37_1
L0_1[38] = L38_1
L0_1[39] = L39_1
L0_1[40] = L40_1
L0_1[41] = L41_1
tObjWorldMarkers = L0_1
L0_1 = {}
L1_1 = "icon_yellow_mc"
L2_1 = "icon_action_1_mc"
L3_1 = "icon_action_2_mc"
L4_1 = "icon_action_3_mc"
L5_1 = "icon_outpost_1_mc"
L6_1 = "icon_outpost_2_mc"
L7_1 = "icon_outpost_3_mc"
L8_1 = "icon_defend_1_mc"
L9_1 = "icon_defend_2_mc"
L10_1 = "icon_defend_3_mc"
L11_1 = "icon_destroy_1_mc"
L12_1 = "icon_destroy_2_mc"
L13_1 = "icon_destroy_3_mc"
L14_1 = "icon_verify_1_mc"
L15_1 = "icon_verify_2_mc"
L16_1 = "icon_verify_3_mc"
L17_1 = "icon_deliverable_1_mc"
L18_1 = "icon_deliverable_2_mc"
L19_1 = "icon_deliverable_3_mc"
L20_1 = "icon_pmc_mc"
L21_1 = "icon_an_mc"
L22_1 = "icon_ch_mc"
L23_1 = "icon_gr_mc"
L24_1 = "icon_oc_mc"
L25_1 = "icon_pr_mc"
L26_1 = "icon_vz_mc"
L27_1 = "icon_an_locked_mc"
L28_1 = "icon_ch_locked_mc"
L29_1 = "icon_gr_locked_mc"
L30_1 = "icon_oc_locked_mc"
L31_1 = "icon_pr_locked_mc"
L32_1 = "icon_vz_locked_mc"
L33_1 = "icon_yellow_mc"
L34_1 = ""
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1
L0_1[5] = L5_1
L0_1[6] = L6_1
L0_1[7] = L7_1
L0_1[8] = L8_1
L0_1[9] = L9_1
L0_1[10] = L10_1
L0_1[11] = L11_1
L0_1[12] = L12_1
L0_1[13] = L13_1
L0_1[14] = L14_1
L0_1[15] = L15_1
L0_1[16] = L16_1
L0_1[17] = L17_1
L0_1[18] = L18_1
L0_1[19] = L19_1
L0_1[20] = L20_1
L0_1[21] = L21_1
L0_1[22] = L22_1
L0_1[23] = L23_1
L0_1[24] = L24_1
L0_1[25] = L25_1
L0_1[26] = L26_1
L0_1[27] = L27_1
L0_1[28] = L28_1
L0_1[29] = L29_1
L0_1[30] = L30_1
L0_1[31] = L31_1
L0_1[32] = L32_1
L0_1[33] = L33_1
L0_1[34] = L34_1
tObjPdaMarker = L0_1
L0_1 = {}
L1_1 = "objective_destroy"
L2_1 = "objective_deliverable"
L3_1 = "objective_action"
L4_1 = "objective_defend"
L5_1 = "objective_verify"
L6_1 = "objective_outpost"
L7_1 = "temp_radar_icon_db"
L8_1 = "temp_radar_icon_dbactive"
L9_1 = "MiniMap_Icon_Faction_PMC"
L10_1 = "MiniMap_Icon_Faction_GR"
L11_1 = "MiniMap_Icon_Faction_OC"
L12_1 = "MiniMap_Icon_Faction_PR"
L13_1 = "MiniMap_Icon_Faction_AN"
L14_1 = "MiniMap_Icon_Faction_CH"
L15_1 = "MiniMap_Icon_Faction_VZ"
L16_1 = "MiniMap_Icon_Faction_GR_locked"
L17_1 = "MiniMap_Icon_Faction_OC_locked"
L18_1 = "MiniMap_Icon_Faction_PR_locked"
L19_1 = "MiniMap_Icon_Faction_AN_locked"
L20_1 = "MiniMap_Icon_Faction_CH_locked"
L21_1 = "MiniMap_Icon_Symbol_Yellow"
L22_1 = "MiniMap_Icon_Misha"
L23_1 = "MiniMap_Icon_Eva"
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1
L0_1[5] = L5_1
L0_1[6] = L6_1
L0_1[7] = L7_1
L0_1[8] = L8_1
L0_1[9] = L9_1
L0_1[10] = L10_1
L0_1[11] = L11_1
L0_1[12] = L12_1
L0_1[13] = L13_1
L0_1[14] = L14_1
L0_1[15] = L15_1
L0_1[16] = L16_1
L0_1[17] = L17_1
L0_1[18] = L18_1
L0_1[19] = L19_1
L0_1[20] = L20_1
L0_1[21] = L21_1
L0_1[22] = L22_1
L0_1[23] = L23_1
tObjRadarMaker = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = ipairs
  L3_2 = A0_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    if A1_2 == L6_2 then
      return L5_2
    end
  end
  L2_2 = 0
  return L2_2
end

_SearchMarkerTable = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = tObjWorldMarkers
  L1_2 = L1_2[A0_2]
  return L1_2
end

MarkerGetNameByIndex_World = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = _SearchMarkerTable
  L2_2 = tObjWorldMarkers
  L3_2 = A0_2
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 ~= 0 or A0_2 ~= "" then
  end
  return L1_2
end

MarkerGetIndexByName_World = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = tObjPdaMarker
  L1_2 = L1_2[A0_2]
  return L1_2
end

MarkerGetNameByIndex_Pda = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = _SearchMarkerTable
  L2_2 = tObjPdaMarker
  L3_2 = A0_2
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 ~= 0 or A0_2 ~= "" then
  end
  return L1_2
end

MarkerGetIndexByName_Pda = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = tObjRadarMaker
  L1_2 = L1_2[A0_2]
  return L1_2
end

MarkerGetNameByIndex_Radar = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = _SearchMarkerTable
  L2_2 = tObjRadarMaker
  L3_2 = A0_2
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 ~= 0 or A0_2 ~= "" then
  end
  return L1_2
end

MarkerGetIndexByName_Radar = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Player
  L1_2 = L1_2.RequestPDAMapModeCancel
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Player
  L1_2 = L1_2.SetCinematicMode
  L2_2 = A0_2
  L3_2 = false
  L1_2(L2_2, L3_2)
  L1_2 = Player
  L1_2 = L1_2.SetSatelliteScanMode
  L2_2 = A0_2
  L3_2 = false
  L4_2 = 0
  L5_2 = 0
  L6_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

ExitAllPlayerModes = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = {}
  _tNumbers = L0_2
  L0_2 = _tNumbers
  L0_2[1.0E15] = "[0x7be2637c]"
  L0_2 = _tNumbers
  L0_2[1.0E12] = "[0x9d96ba8f]"
  L0_2 = _tNumbers
  L0_2[1000000000] = "[0x4cf9c95f]"
  L0_2 = _tNumbers
  L0_2[1000000] = "[0xcd15e5e8]"
  L0_2 = _tNumbers
  L0_2[1000] = "[0xe00c096a]"
end

Init = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  if L1_2 then
    L4_2 = pairs
    L5_2 = Player
    L5_2 = L5_2.GetAllPlayers
    L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2 = L5_2()
    L4_2, L5_2, L6_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
    for L7_2, L8_2 in L4_2, L5_2, L6_2 do
      L9_2 = Player
      L9_2 = L9_2.GetCharacter
      L10_2 = L8_2
      L9_2 = L9_2(L10_2)
      L10_2 = GetDistanceToObject
      L11_2 = L9_2
      L12_2 = L1_2
      L13_2 = L2_2
      L14_2 = L3_2
      L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2)
      if L10_2 < 150 then
        L10_2 = Human
        L10_2 = L10_2.DoAction
        L11_2 = L9_2
        L12_2 = "shieldface"
        L10_2(L11_2, L12_2)
      end
    end
  end
end

ShieldFace = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = 0
  while 10 <= A0_2 do
    A0_2 = A0_2 / 10
    L1_2 = L1_2 + 1
  end
  return L1_2
end

GetNumberOfDigits = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = WifPmcInterior
  L0_2 = L0_2.IsInside
  L0_2 = L0_2()
  if not L0_2 then
    L0_2 = MrxHqManager
    L0_2 = L0_2.IsInside
    L0_2 = L0_2()
  end
  return L0_2
end

IsInside = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 == "string" then
    L2_2 = Pg
    L2_2 = L2_2.GetGuidByName
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    A0_2 = L2_2
  end
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = A0_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L5_2 = Pg
  L5_2 = L5_2.FastCollectGroundVehicles
  L6_2 = L2_2
  L7_2 = L3_2
  L8_2 = L4_2
  L9_2 = 5.5
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = pairs
  L7_2 = L5_2
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  for L9_2, L10_2 in L6_2, L7_2, L8_2 do
    if L10_2 ~= A1_2 then
      L11_2 = Object
      L11_2 = L11_2.Remove
      L12_2 = L10_2
      L11_2(L12_2)
    end
  end
  L6_2 = Pg
  L6_2 = L6_2.FastCollectHelicopters
  L7_2 = L2_2
  L8_2 = L3_2
  L9_2 = L4_2
  L10_2 = 12
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
  L5_2 = L6_2
  L6_2 = pairs
  L7_2 = L5_2
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  for L9_2, L10_2 in L6_2, L7_2, L8_2 do
    if L10_2 ~= A1_2 then
      L11_2 = Object
      L11_2 = L11_2.Remove
      L12_2 = L10_2
      L11_2(L12_2)
    end
  end
end

ClearVehiclesNearPoint = L0_1
