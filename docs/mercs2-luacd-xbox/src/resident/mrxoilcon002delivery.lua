local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxSupportDelivery"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportDesignator"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxOilCon002Delivery"
L0_1(L1_1)
L0_1 = {}
L1_1 = 0
NETEVENT_SETDELIVERYLOCATIONS = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = NETEVENT_SETDELIVERYLOCATIONS
  if A0_2 == L2_2 then
    L2_2 = ResetDropZones
    L2_2()
    L2_2 = table
    L2_2 = L2_2.getn
    L3_2 = L0_1
    L2_2 = L2_2(L3_2)
    while 1 <= L2_2 do
      L3_2 = A1_2[L2_2]
      if L3_2 == 0 then
        L3_2 = RemoveDropZone
        L4_2 = L2_2
        L3_2(L4_2)
      end
      L2_2 = L2_2 - 1
    end
  end
end

NetEventCallback = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = Net
  L1_2 = L1_2.IsServer
  L1_2 = L1_2()
  if not L1_2 then
    return
  end
  L1_2 = 0
  L2_2 = 0
  L3_2 = 0
  L4_2 = ipairs
  L5_2 = L0_1
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    if L8_2 == "oilcon002_loc_postA" then
      L1_2 = 1
    elseif L8_2 == "oilcon002_loc_postB" then
      L2_2 = 1
    elseif L8_2 == "oilcon002_loc_postC" then
      L3_2 = 1
    end
  end
  L4_2 = Net
  L4_2 = L4_2.SendCustomEvent
  L5_2 = "MrxOilCon002Delivery"
  L6_2 = NETEVENT_SETDELIVERYLOCATIONS
  L7_2 = {}
  L8_2 = L1_2
  L9_2 = L2_2
  L10_2 = L3_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L8_2 = true
  L4_2(L5_2, L6_2, L7_2, L8_2)
end

NetSendDropZones = L1_1

function L1_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = {}
  L1_2 = "oilcon002_loc_postA"
  L2_2 = "oilcon002_loc_postB"
  L3_2 = "oilcon002_loc_postC"
  L0_2[1] = L1_2
  L0_2[2] = L2_2
  L0_2[3] = L3_2
  L0_1 = L0_2
  L0_2 = NetSendDropZones
  L0_2()
end

ResetDropZones = L1_1

function L1_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L0_2 = ipairs
  L1_2 = Player
  L1_2 = L1_2.GetAllPlayers
  L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L1_2()
  L0_2, L1_2, L2_2 = L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = MrxGui
    L5_2 = L5_2.GetWidgetByNameAndOwner
    L6_2 = "Support Menu"
    L7_2 = L4_2
    L5_2 = L5_2(L6_2, L7_2)
    if L5_2 then
      L7_2 = L5_2
      L6_2 = L5_2.AddItem
      L8_2 = {}
      L8_2.sName = "[support.supply.listeningpost.name]"
      L8_2.sIcon = "vehicles_helir_uh1"
      L9_2 = MrxOilCon002Delivery
      L10_2 = L9_2
      L9_2 = L9_2.Create
      L11_2 = L4_2
      L9_2 = L9_2(L10_2, L11_2)
      L8_2.oSupport = L9_2
      L6_2(L7_2, L8_2)
    end
  end
end

AddSupport = L1_1

function L1_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = ipairs
  L1_2 = Player
  L1_2 = L1_2.GetAllPlayers
  L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L1_2()
  L0_2, L1_2, L2_2 = L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = MrxGui
    L5_2 = L5_2.GetWidgetByNameAndOwner
    L6_2 = "Support Menu"
    L7_2 = L4_2
    L5_2 = L5_2(L6_2, L7_2)
    if L5_2 then
      L7_2 = L5_2
      L6_2 = L5_2.RemoveItem
      L8_2 = "Listening Post Delivery"
      L6_2(L7_2, L8_2)
    end
  end
end

RemoveSupport = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = MrxSupportDelivery
  L3_2 = L2_2
  L2_2 = L2_2.Create
  L4_2 = A1_2
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = Create
  L2_2.Create = L3_2
  L4_2 = L2_2
  L3_2 = L2_2.SetCargo
  L5_2 = "Listening Post"
  L3_2(L4_2, L5_2)
  L4_2 = L2_2
  L3_2 = L2_2.GetDesignator
  L3_2 = L3_2(L4_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetAATestLevel
  L6_2 = "none"
  L4_2(L5_2, L6_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetValidationFunction
  L6_2 = _ValidateDropZone
  L4_2(L5_2, L6_2)
  L5_2 = L2_2
  L4_2 = L2_2.SetModuleName
  L6_2 = "MrxOilCon002Delivery"
  L4_2(L5_2, L6_2)
  L4_2 = _ePlayerJoin
  if not L4_2 then
    L4_2 = Event
    L4_2 = L4_2.CreatePersistent
    L5_2 = Event
    L5_2 = L5_2.ScriptEvent
    L6_2 = {}
    L7_2 = "mpPlayerJoin"
    
    function L8_2(A0_3)
      local L1_3, L2_3
      L1_3 = Net
      L1_3 = L1_3.IsServer
      L1_3 = L1_3()
      if L1_3 then
        L1_3 = Player
        L1_3 = L1_3.IsLocal
        L2_3 = A0_3[1]
        L1_3 = L1_3(L2_3)
        L1_3 = not L1_3
      end
      return L1_3
    end
    
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L7_2 = NetSendDropZones
    L8_2 = {}
    L9_2 = true
    L8_2[1] = L9_2
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
    _ePlayerJoin = L4_2
  end
  return L2_2
end

Create = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L5_2 = false
  L6_2 = pairs
  L7_2 = GetCurrentDropZones
  L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L7_2()
  L6_2, L7_2, L8_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
  for L9_2, L10_2 in L6_2, L7_2, L8_2 do
    L11_2 = Pg
    L11_2 = L11_2.GetGuidByName
    L12_2 = L10_2
    L11_2 = L11_2(L12_2)
    if L11_2 == nil then
      L5_2 = true
      break
    end
    L12_2 = GetDistanceToObject
    L13_2 = L11_2
    L14_2 = A1_2
    L15_2 = A2_2
    L16_2 = A3_2
    L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2)
    if L12_2 <= 30 then
      L5_2 = true
      L13_2 = Object
      L13_2 = L13_2.GetPosition
      L14_2 = L11_2
      L13_2, L14_2, L15_2 = L13_2(L14_2)
      A3_2 = L15_2
      A2_2 = L14_2
      A1_2 = L13_2
      break
    end
  end
  if L5_2 then
    L6_2 = A0_2
    L7_2 = true
    L8_2 = A1_2
    L9_2 = A2_2
    L10_2 = A3_2
    L11_2 = A4_2
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
    L6_2 = MrxSupportDesignator
    L6_2 = L6_2.ValidateGroundDropZone
    L7_2 = A0_2
    L8_2 = A1_2
    L9_2 = A2_2
    L10_2 = A3_2
    L11_2 = A4_2
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  else
    L6_2 = A0_2
    L7_2 = false
    L8_2 = "oilcon002_toofar"
    L6_2(L7_2, L8_2)
  end
end

_ValidateDropZone = L1_1

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L5_2 = Object
  L5_2 = L5_2.GetPosition
  L6_2 = A0_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L8_2 = L5_2 - A1_2
  L9_2 = L6_2 - A2_2
  L10_2 = L7_2 - A3_2
  if A4_2 then
    L9_2 = 0
  end
  L11_2 = Math
  L11_2 = L11_2.Length
  L12_2 = L8_2
  L13_2 = L9_2
  L14_2 = L10_2
  return L11_2(L12_2, L13_2, L14_2)
end

GetDistanceToObject = L1_1

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L3_2 = Object
  L3_2 = L3_2.GetPosition
  L4_2 = A0_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  L6_2 = Object
  L6_2 = L6_2.GetPosition
  L7_2 = A1_2
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  L9_2 = L3_2 - L6_2
  L10_2 = L4_2 - L7_2
  L11_2 = L5_2 - L8_2
  if A2_2 then
    L10_2 = 0
  end
  L12_2 = Math
  L12_2 = L12_2.Length
  L13_2 = L9_2
  L14_2 = L10_2
  L15_2 = L11_2
  return L12_2(L13_2, L14_2, L15_2)
end

GetDistanceBetween = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = table
  L1_2 = L1_2.remove
  L2_2 = L0_1
  L3_2 = A0_2
  L1_2(L2_2, L3_2)
  L1_2 = NetSendDropZones
  L1_2()
end

RemoveDropZone = L1_1

function L1_1()
  local L0_2, L1_2
  L0_2 = L0_1
  return L0_2
end

GetCurrentDropZones = L1_1
