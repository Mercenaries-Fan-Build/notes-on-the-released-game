local L0_1, L1_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = {}
  tFortressNodes = L0_2
  L0_2 = {}
  tAdjacencyTable = L0_2
  L0_2 = tAdjacencyTable
  L1_2 = {}
  L2_2 = "Slice2B"
  L1_2[1] = L2_2
  L0_2["0x024BE2A6"] = L1_2
  L0_2 = tAdjacencyTable
  L1_2 = {}
  L2_2 = "Slice2A"
  L3_2 = "Slice2C"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L0_2["0x84536B11"] = L1_2
  L0_2 = tAdjacencyTable
  L1_2 = {}
  L2_2 = "Slice2B"
  L3_2 = "Slice2D"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L0_2["0x8A5135EC"] = L1_2
  L0_2 = tAdjacencyTable
  L1_2 = {}
  L2_2 = "Slice2C"
  L3_2 = "Slice2E"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L0_2["0x0C58BE57"] = L1_2
  L0_2 = tAdjacencyTable
  L1_2 = {}
  L2_2 = "Slice2D"
  L3_2 = "Slice2F"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L0_2["0xAA55E57A"] = L1_2
  L0_2 = tAdjacencyTable
  L1_2 = {}
  L2_2 = "Slice2E"
  L3_2 = "Slice2G"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L0_2["0x0C5D3B85"] = L1_2
  L0_2 = tAdjacencyTable
  L1_2 = {}
  L2_2 = "Slice2F"
  L3_2 = "Slice2H"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L0_2["0x225B1F90"] = L1_2
  L0_2 = tAdjacencyTable
  L1_2 = {}
  L2_2 = "Slice2G"
  L3_2 = "Slice2I"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L0_2["0x043A9CAB"] = L1_2
  L0_2 = tAdjacencyTable
  L1_2 = {}
  L2_2 = "Slice2H"
  L3_2 = "Slice2J"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L0_2["0x22388D4E"] = L1_2
  L0_2 = tAdjacencyTable
  L1_2 = {}
  L2_2 = "Slice2I"
  L3_2 = "Slice2K"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L0_2["0x843FE359"] = L1_2
  L0_2 = tAdjacencyTable
  L1_2 = {}
  L2_2 = "Slice2J"
  L3_2 = "Slice2L"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L0_2["0x2A3D1714"] = L1_2
  L0_2 = tAdjacencyTable
  L1_2 = {}
  L2_2 = "Slice2K"
  L3_2 = "Slice2M"
  L4_2 = "Slice4A"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L0_2["0x8C446D1F"] = L1_2
  L0_2 = tAdjacencyTable
  L1_2 = {}
  L2_2 = "Slice2L"
  L3_2 = "Slice2N"
  L4_2 = "Slice4A"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L0_2["0xAA425DC2"] = L1_2
  L0_2 = tAdjacencyTable
  L1_2 = {}
  L2_2 = "Slice2M"
  L3_2 = "Slice2O"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L0_2["0x2C49E62D"] = L1_2
  L0_2 = tAdjacencyTable
  L1_2 = {}
  L2_2 = "Slice2N"
  L1_2[1] = L2_2
  L0_2["0x02476578"] = L1_2
end

Init = L0_1

function L0_1()
  local L0_2, L1_2
  tFortressNodes = L0_2
  L0_2 = nil
  tAdjacencyTable = L0_2
end

Deinit = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = tFortressNodes
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L3_2 = Object
    L3_2 = L3_2.IsAlive
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L3_2 = Object
      L3_2 = L3_2.Kill
      L4_2 = A0_2
      L3_2(L4_2)
    end
    L3_2 = pairs
    L4_2 = L2_2
    L3_2, L4_2, L5_2 = L3_2(L4_2)
    for L6_2, L7_2 in L3_2, L4_2, L5_2 do
      L8_2 = type
      L9_2 = L7_2
      L8_2 = L8_2(L9_2)
      if L8_2 == "userdata" then
        L8_2 = Event
        L8_2 = L8_2.Delete
        L9_2 = L7_2
        L8_2(L9_2)
      end
    end
    L3_2 = tFortressNodes
    L3_2[A0_2] = nil
  end
end

OnDeactivate = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = Sys
  L3_2 = L3_2.GuidToString
  L4_2 = A2_2
  L3_2 = L3_2(L4_2)
  L4_2 = Sys
  L4_2 = L4_2.GuidToString
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  if L4_2 == "0xCF37044A" and L3_2 == "0x694683EB" then
    L5_2 = tFortressNodes
    L6_2 = {}
    L5_2[A0_2] = L6_2
    L5_2 = {}
    L6_2 = "Slice2B"
    L7_2 = "Slice2C"
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L6_2 = Math
    L6_2 = L6_2.randi
    L7_2 = #L5_2
    L6_2 = L6_2(L7_2)
    L7_2 = KillNode
    L8_2 = A0_2
    L9_2 = L5_2[L6_2]
    L7_2(L8_2, L9_2)
  end
end

OnStateChange = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = tFortressNodes
  L2_2 = L2_2[A0_2]
  L3_2 = L2_2[A1_2]
  if L3_2 then
    return
  end
  L3_2 = nil
  L4_2 = String
  L4_2 = L4_2.GetHash
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  L5_2 = Object
  L5_2 = L5_2.GetNodeHealth
  L6_2 = A0_2
  L7_2 = A1_2
  L5_2 = L5_2(L6_2, L7_2)
  if 0 < L5_2 then
    L5_2 = ObjectState
    L5_2 = L5_2.SendDamage
    L6_2 = A0_2
    L7_2 = L4_2
    L8_2 = 1
    L5_2(L6_2, L7_2, L8_2)
    L5_2 = Math
    L5_2 = L5_2.randf
    L6_2 = 0.3
    L7_2 = 0.5
    L5_2 = L5_2(L6_2, L7_2)
    L3_2 = L5_2
  else
    L5_2 = Math
    L5_2 = L5_2.randf
    L6_2 = 0.7
    L7_2 = 1
    L5_2 = L5_2(L6_2, L7_2)
    L3_2 = L5_2
  end
  L5_2 = tAdjacencyTable
  L6_2 = Sys
  L6_2 = L6_2.GuidToString
  L7_2 = L4_2
  L6_2 = L6_2(L7_2)
  L5_2 = L5_2[L6_2]
  if L5_2 then
    L6_2 = Event
    L6_2 = L6_2.Create
    L7_2 = Event
    L7_2 = L7_2.TimerRelative
    L8_2 = {}
    L9_2 = L3_2
    L8_2[1] = L9_2
    L9_2 = KillNodeSet
    L10_2 = {}
    L11_2 = A0_2
    L12_2 = L5_2
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
    L2_2[A1_2] = L6_2
  else
    L2_2[A1_2] = true
  end
end

KillNode = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = ipairs
  L3_2 = A1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = KillNode
    L8_2 = A0_2
    L9_2 = L6_2
    L7_2(L8_2, L9_2)
  end
end

KillNodeSet = L0_1
