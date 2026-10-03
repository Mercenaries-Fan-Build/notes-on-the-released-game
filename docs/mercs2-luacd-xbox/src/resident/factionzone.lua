local L0_1, L1_1
L0_1 = inherit
L1_1 = "Inheritable"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = {}
  L1_2 = String
  L1_2 = L1_2.GetHash
  L2_2 = "Allied"
  L1_2 = L1_2(L2_2)
  L2_2 = {}
  L2_2.sFaction = "All"
  L0_2[L1_2] = L2_2
  L1_2 = String
  L1_2 = L1_2.GetHash
  L2_2 = "China"
  L1_2 = L1_2(L2_2)
  L2_2 = {}
  L2_2.sFaction = "Chi"
  L0_2[L1_2] = L2_2
  L1_2 = String
  L1_2 = L1_2.GetHash
  L2_2 = "Civ"
  L1_2 = L1_2(L2_2)
  L2_2 = {}
  L2_2.sFaction = "Civ"
  L0_2[L1_2] = L2_2
  L1_2 = String
  L1_2 = L1_2.GetHash
  L2_2 = "Guerilla"
  L1_2 = L1_2(L2_2)
  L2_2 = {}
  L2_2.sFaction = "Gur"
  L0_2[L1_2] = L2_2
  L1_2 = String
  L1_2 = L1_2.GetHash
  L2_2 = "OC"
  L1_2 = L1_2(L2_2)
  L2_2 = {}
  L2_2.sFaction = "Oil"
  L0_2[L1_2] = L2_2
  L1_2 = String
  L1_2 = L1_2.GetHash
  L2_2 = "Pirate"
  L1_2 = L1_2(L2_2)
  L2_2 = {}
  L2_2.sFaction = "Pir"
  L0_2[L1_2] = L2_2
  L1_2 = String
  L1_2 = L1_2.GetHash
  L2_2 = "PMC"
  L1_2 = L1_2(L2_2)
  L2_2 = {}
  L2_2.sFaction = "Pmc"
  L0_2[L1_2] = L2_2
  L1_2 = String
  L1_2 = L1_2.GetHash
  L2_2 = "VZ"
  L1_2 = L1_2(L2_2)
  L2_2 = {}
  L2_2.sFaction = "Vz"
  L0_2[L1_2] = L2_2
  _tAssociationMap = L0_2
end

Init = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = getfenv
  L3_2 = L3_2()
  L5_2 = L3_2
  L4_2 = L3_2.Create
  L6_2 = A0_2
  L7_2 = A1_2
  L4_2 = L4_2(L5_2, L6_2, L7_2)
end

OnActivate = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = Inheritable
  L3_2 = L3_2.Create
  L4_2 = A0_2
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L4_2 = Ai
  L4_2 = L4_2.GetFactionGuid
  L5_2 = L3_2.uGuid
  L4_2 = L4_2(L5_2)
  L3_2.uFaction = L4_2
  L4_2 = Object
  L4_2 = L4_2.GetName
  L5_2 = L3_2.uFaction
  L4_2 = L4_2(L5_2)
  L5_2 = pairs
  L6_2 = _tAssociationMap
  L6_2 = L6_2[L4_2]
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L3_2[L8_2] = L9_2
  end
  L5_2 = L3_2.bActive
  if not L5_2 then
    L6_2 = L3_2
    L5_2 = L3_2.Enable
    L5_2(L6_2)
  end
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2.bActive
  if L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.Disable
    L1_2(L2_2)
  end
  L1_2 = Inheritable
  L1_2 = L1_2.Delete
  L2_2 = A0_2
  L1_2(L2_2)
end

Delete = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2
  if A3_2 == "enter" then
    L4_2 = A0_2.bTrespassing
    if not L4_2 then
      goto lbl_11
    end
  end
  if A3_2 == "exit" then
    L4_2 = A0_2.bTrespassing
    ::lbl_11::
    if L4_2 then
      L4_2 = A3_2 == "enter"
      L5_2 = {}
      L5_2.EventType = "TrespassStateChange"
      L5_2.bTrespassing = L4_2
      L6_2 = A0_2.sFaction
      L5_2.sFaction = L6_2
      L6_2 = MrxGui
      L6_2 = L6_2.SendEvent
      L7_2 = L5_2
      L6_2(L7_2)
      A0_2.bTrespassing = L4_2
    end
  end
end

BoundaryCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = {}
  L2_2 = A0_2.uGuid
  L1_2.uGuid = L2_2
  L1_2.nRed = 64
  L1_2.nGreen = 0
  L1_2.nBlue = 0
  L1_2.nAlpha = 160
  L2_2 = Hud
  L2_2 = L2_2.Radar
  L3_2 = L2_2
  L2_2 = L2_2.AddLineRegion
  L4_2 = L1_2
  L2_2(L3_2, L4_2)
  L2_2 = Pda
  L2_2 = L2_2.Map
  L3_2 = L2_2
  L2_2 = L2_2.AddLineRegion
  L4_2 = L1_2
  L2_2(L3_2, L4_2)
  L2_2 = Event
  L2_2 = L2_2.CreatePersistent
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetLocalCharacter
  L5_2 = L5_2()
  L6_2 = A0_2.uGuid
  L7_2 = "any"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = BoundaryCallback
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  A0_2.BoundaryEvent = L2_2
  A0_2.bActive = true
end

Enable = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = {}
  L2_2 = A0_2.uGuid
  L1_2.uGuid = L2_2
  L2_2 = Hud
  L2_2 = L2_2.Radar
  L3_2 = L2_2
  L2_2 = L2_2.RemoveLineRegion
  L4_2 = L1_2
  L2_2(L3_2, L4_2)
  L2_2 = Pda
  L2_2 = L2_2.Map
  L3_2 = L2_2
  L2_2 = L2_2.RemoveLineRegion
  L4_2 = L1_2
  L2_2(L3_2, L4_2)
  L2_2 = Event
  L2_2 = L2_2.Delete
  L3_2 = A0_2.BoundaryEvent
  L2_2(L3_2)
  L2_2 = A0_2.bTrespassing
  if L2_2 then
    L2_2 = {}
    L2_2.EventType = "TrespassStateChange"
    L2_2.bTrespassing = false
    L3_2 = A0_2.sFaction
    L2_2.sFaction = L3_2
    L3_2 = MrxGui
    L3_2 = L3_2.SendEvent
    L4_2 = L2_2
    L3_2(L4_2)
    A0_2.bTrespassing = false
  end
  A0_2.bActive = nil
end

Disable = L0_1
