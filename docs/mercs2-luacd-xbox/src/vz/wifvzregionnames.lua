local L0_1, L1_1
L0_1 = import
L1_1 = "MrxPlayState"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxState"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "DangerousBuilding"
L0_1(L1_1)
L0_1 = {}
L1_1 = {}
L1_1.VO = "Fiona.POI.AlliedHQ01"
L0_1.poi_AlliedHQ = L1_1
L1_1 = {}
L0_1.poi_Altagracia = L1_1
L1_1 = {}
L1_1.VO = "Fiona.POI.WestAmazon01"
L0_1.poi_Amazonas = L1_1
L1_1 = {}
L1_1.VO = "Fiona.POI.AngelFalls01"
L0_1.poi_AngelFalls = L1_1
L1_1 = {}
L0_1.poi_Cambias = L1_1
L1_1 = {}
L0_1.poi_cantina = L1_1
L1_1 = {}
L1_1.VO = "Fiona.POI.Caracas01"
L0_1.poi_Caracas = L1_1
L1_1 = {}
L0_1.poi_caracasbridge = L1_1
L1_1 = {}
L0_1.poi_caracasdowntown = L1_1
L1_1 = {}
L0_1.poi_caracashighway = L1_1
L1_1 = {}
L0_1.poi_caracaspark = L1_1
L1_1 = {}
L0_1.poi_caracasport = L1_1
L1_1 = {}
L1_1.VO = "Fiona.POI.ChinaHQ01"
L0_1.poi_ChinaHQ = L1_1
L1_1 = {}
L1_1.VO = "Fiona.POI.Cumana02"
L0_1.poi_Cumana = L1_1
L1_1 = {}
L0_1.poi_CumanaFortress = L1_1
L1_1 = {}
L0_1.poi_maracaibohotel = L1_1
L1_1 = {}
L0_1.poi_CumanaWest = L1_1
L1_1 = {}
L0_1.poi_CumanaMarket = L1_1
L1_1 = {}
L0_1.poi_CumanaTheatre = L1_1
L1_1 = {}
L0_1.poi_CumanaBridgeSouth = L1_1
L1_1 = {}
L0_1.poi_CumanaBridgeNorth = L1_1
L1_1 = {}
L0_1.poi_CumanaPark = L1_1
L1_1 = {}
L0_1.poi_FortressIsland = L1_1
L1_1 = {}
L1_1.VO = "Fiona.POI.Guanare01"
L0_1.poi_Guanare = L1_1
L1_1 = {}
L1_1.VO = "Fiona.POI.GurHQ01"
L0_1.poi_GuerillaHQ = L1_1
L1_1 = {}
L0_1.poi_IslaDeMano = L1_1
L1_1 = {}
L1_1.VO = "Fiona.POI.LakeMaracaibo01"
L0_1.poi_LakeMaracaibo = L1_1
L1_1 = {}
L1_1.VO = "Fiona.POI.Maracaibo02"
L0_1.poi_Maracaibo = L1_1
L1_1 = {}
L1_1.VO = "Fiona.POI.MaracaiboRefinery01"
L0_1.poi_MaracaiboDocks = L1_1
L1_1 = {}
L0_1.poi_MaracaiboPark = L1_1
L1_1 = {}
L1_1.VO = "Fiona.POI.MaracaiboBridge01"
L0_1.poi_maracaibobridge = L1_1
L1_1 = {}
L1_1.VO = "Fiona.POI.MaracaiboHighway01"
L0_1.poi_maracaibohighway = L1_1
L1_1 = {}
L1_1.VO = "Fiona.POI.WestMaracaibo01"
L0_1.poi_maracaibowest = L1_1
L1_1 = {}
L1_1.VO = "Fiona.POI.Isla01"
L0_1.poi_Margarita = L1_1
L1_1 = {}
L1_1.VO = "Fiona.POI.Merida02"
L0_1.poi_Merida = L1_1
L1_1 = {}
L0_1.poi_meridapark = L1_1
L1_1 = {}
L0_1.poi_meridastadium = L1_1
L1_1 = {}
L0_1.poi_OilDepot = L1_1
L1_1 = {}
L1_1.VO = "Fiona.POI.UPHQ01"
L0_1.poi_OilHQ = L1_1
L1_1 = {}
L1_1.VO = "Fiona.POI.Pirates01"
L0_1.poi_PirateHQ = L1_1
L1_1 = {}
L0_1.poi_PMCHQ = L1_1
L1_1 = {}
L1_1.VO = "Fiona.POI.ShantyTown01"
L0_1.poi_ShantyTown = L1_1
tBoundaryList = L0_1
L0_1 = {}
_tBoundaryEvents = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = pairs
  L1_2 = _tBoundaryEvents
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = Event
    L5_2 = L5_2.Delete
    L6_2 = L4_2
    L5_2(L6_2)
    L5_2 = _tBoundaryEvents
    L5_2[L3_2] = nil
  end
  L0_2 = tBoundaryList
  if L0_2 then
    L0_2 = pairs
    L1_2 = tBoundaryList
    L0_2, L1_2, L2_2 = L0_2(L1_2)
    for L3_2, L4_2 in L0_2, L1_2, L2_2 do
      L5_2 = SetupBoundaryEvent
      L6_2 = L3_2
      L7_2 = "enter"
      L5_2(L6_2, L7_2)
    end
  end
  L0_2 = SetupDBBoundary
  L0_2()
end

Start = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = DangerousBuilding
  L0_2 = L0_2.SetRarity
  L1_2 = "all"
  L2_2 = "default"
  L0_2(L1_2, L2_2)
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.Boundary
  L2_2 = {}
  L3_2 = Player
  L3_2 = L3_2.GetAnyCharacter
  L3_2 = L3_2()
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "DisableDBs"
  L4_2 = L4_2(L5_2)
  L5_2 = "enter"
  L6_2 = false
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L3_2 = DisableDBs
  L0_2(L1_2, L2_2, L3_2)
end

SetupDBBoundary = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = DangerousBuilding
  L0_2 = L0_2.SetRarity
  L1_2 = "all"
  L2_2 = "never"
  L0_2(L1_2, L2_2)
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.Boundary
  L2_2 = {}
  L3_2 = Player
  L3_2 = L3_2.GetAllCharacters
  L3_2 = L3_2()
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "DisableDBs"
  L4_2 = L4_2(L5_2)
  L5_2 = "exit"
  L6_2 = false
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L3_2 = SetupDBBoundary
  L0_2(L1_2, L2_2, L3_2)
end

DisableDBs = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L3_2 = _tBoundaryEvents
  L3_2 = L3_2[A0_2]
  if L3_2 then
    return
  end
  L3_2 = _tBoundaryEvents
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.Boundary
  L6_2 = {}
  L7_2 = Player
  L7_2 = L7_2.GetLocalCharacter
  L7_2 = L7_2()
  L8_2 = L2_2
  L9_2 = A1_2
  L10_2 = false
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L7_2 = CrossedBoundary
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L3_2[A0_2] = L4_2
end

SetupBoundaryEvent = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  if not A0_2 then
    return
  end
  L4_2 = Event
  L4_2 = L4_2.Delete
  L5_2 = _tBoundaryEvents
  L5_2 = L5_2[A0_2]
  L4_2(L5_2)
  L4_2 = _tBoundaryEvents
  L4_2[A0_2] = nil
  L4_2 = Object
  L4_2 = L4_2.GetLocalizedName
  L5_2 = A2_2
  L4_2 = L4_2(L5_2)
  if A3_2 == "enter" then
    if L4_2 then
      L5_2 = Hud
      L5_2 = L5_2.MapLabel
      L6_2 = L5_2
      L5_2 = L5_2.Show
      L7_2 = {}
      L7_2.sLocation = L4_2
      L7_2.nDuration = 10
      L5_2(L6_2, L7_2)
    end
    L5_2 = tBoundaryList
    L5_2 = L5_2[A0_2]
    L6_2 = Net
    L6_2 = L6_2.IsClient
    L6_2 = L6_2()
    if not L6_2 then
      L6_2 = type
      L7_2 = L5_2
      L6_2 = L6_2(L7_2)
      if L6_2 == "table" then
        L6_2 = L5_2.VO
        if L6_2 then
          L6_2 = L5_2.bVoPlayed
          if not L6_2 then
            L6_2 = MrxPlayState
            L6_2 = L6_2.IsFree
            L6_2 = L6_2()
            if L6_2 then
              L6_2 = MrxState
              L6_2 = L6_2.IsLocked
              L6_2 = L6_2()
              if not L6_2 then
                L5_2.bVoPlayed = true
                L6_2 = MrxVoSequence
                L6_2 = L6_2.Start
                L7_2 = L5_2.VO
                L8_2 = nil
                L9_2 = MrxVoSequence
                L9_2 = L9_2.knPriorityFreeplay
                L6_2(L7_2, L8_2, L9_2)
              end
            end
          end
        end
      end
    end
    L6_2 = SetupBoundaryEvent
    L7_2 = A0_2
    L8_2 = "exit"
    L6_2(L7_2, L8_2)
  elseif A3_2 == "exit" then
    L5_2 = SetupBoundaryEvent
    L6_2 = A0_2
    L7_2 = "enter"
    L5_2(L6_2, L7_2)
  end
end

CrossedBoundary = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = {}
  tSaveData = L0_2
  L0_2 = pairs
  L1_2 = tBoundaryList
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = L4_2.bVoPlayed
    if L5_2 then
      L5_2 = table
      L5_2 = L5_2.insert
      L6_2 = tSaveData
      L7_2 = L3_2
      L5_2(L6_2, L7_2)
    end
  end
  L0_2 = tSaveData
  return L0_2
end

SaveSingleton = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L1_2 = not L1_2
  if L1_2 == "table" then
    return
  end
  L1_2 = ipairs
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = tBoundaryList
    L6_2 = L6_2[L5_2]
    L7_2 = type
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    if L7_2 == "table" then
      L6_2.bVoPlayed = true
    end
  end
end

LoadSingleton = L0_1
