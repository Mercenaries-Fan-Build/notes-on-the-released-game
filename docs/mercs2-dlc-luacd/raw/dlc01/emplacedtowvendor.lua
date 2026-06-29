local L0_1, L1_1, L2_1
L0_1 = import
L1_1 = "MrxPmc"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxUtil"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = tEvents
if not L0_1 then
  L0_1 = {}
end
tEvents = L0_1
L0_1 = tMarker
if not L0_1 then
  L0_1 = {}
end
tMarker = L0_1
L0_1 = 500000
nCost = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = tEvents
  L3_2 = tEvents
  L3_2 = L3_2[A0_2]
  if not L3_2 then
    L3_2 = {}
  end
  L2_2[A0_2] = L3_2
  L2_2 = tMarker
  L3_2 = tMarker
  L3_2 = L3_2[A0_2]
  if not L3_2 then
    L3_2 = {}
  end
  L2_2[A0_2] = L3_2
  L2_2 = tMarker
  L2_2 = L2_2[A0_2]
  L3_2 = Marker
  L3_2 = L3_2.AddDisc
  L4_2 = A0_2
  L5_2 = 6
  L6_2 = 0
  L7_2 = 255
  L8_2 = 0
  L9_2 = 0.05
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  L2_2.uMarker = L3_2
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = A0_2
  L6_2 = "awake"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  
  function L5_2()
    local L0_3, L1_3
    L0_3 = SetupActivationEvents
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L2_2(L3_2, L4_2, L5_2)
end

OnActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = OnDeactivate
  L2_2 = A0_2
  L1_2(L2_2)
end

OnDeath = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = tEvents
  if not L1_2 then
    L1_2 = {}
  end
  tEvents = L1_2
  L1_2 = tEvents
  L2_2 = tEvents
  L2_2 = L2_2[A0_2]
  if not L2_2 then
    L2_2 = {}
  end
  L1_2[A0_2] = L2_2
  L1_2 = tMarker
  L1_2 = L1_2[A0_2]
  L1_2 = L1_2.uMarker
  if L1_2 then
    L1_2 = Marker
    L1_2 = L1_2.Remove
    L2_2 = tMarker
    L2_2 = L2_2[A0_2]
    L2_2 = L2_2.uMarker
    L1_2(L2_2)
  end
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  L1_2 = L1_2.uCheckEvent
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = tEvents
    L2_2 = L2_2[A0_2]
    L2_2 = L2_2.uCheckEvent
    L1_2(L2_2)
    L1_2 = tEvents
    L1_2 = L1_2[A0_2]
    L1_2.uCheckEvent = nil
  end
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  L1_2 = L1_2.uActivate
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = tEvents
    L2_2 = L2_2[A0_2]
    L2_2 = L2_2.uActivate
    L1_2(L2_2)
    L1_2 = tEvents
    L1_2 = L1_2[A0_2]
    L1_2.uActivate = nil
  end
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  L1_2 = L1_2.uDeactivate
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = tEvents
    L2_2 = L2_2[A0_2]
    L2_2 = L2_2.uDeactivate
    L1_2(L2_2)
    L1_2 = tEvents
    L1_2 = L1_2[A0_2]
    L1_2.uDeactivate = nil
  end
  L1_2 = tEvents
  L1_2[A0_2] = nil
end

OnDeactivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Pg
  L1_2 = L1_2.AddContextAction
  L2_2 = A0_2
  L3_2 = "Purchase Emplaced TOW $"
  L4_2 = MrxUtil
  L4_2 = L4_2.FormatMoney
  L5_2 = nCost
  L4_2 = L4_2(L5_2)
  L3_2 = L3_2 .. L4_2
  L4_2 = 6
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  L2_2 = Event
  L2_2 = L2_2.CreatePersistent
  L3_2 = Event
  L3_2 = L3_2.ContextAction
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = A0_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = PurchaseEmplacement
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.uActivate = L2_2
end

SetupActivationEvents = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  L4_2 = Object
  L4_2 = L4_2.GetYaw
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  L5_2 = MrxPmc
  L5_2 = L5_2.GetCashQty
  L5_2 = L5_2()
  L6_2 = Pg
  L6_2 = L6_2.GetAwakeObjects
  L7_2 = L1_2
  L8_2 = L2_2
  L9_2 = L3_2
  L10_2 = 4
  L11_2 = "Emplacedweapon"
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  L7_2 = table
  L7_2 = L7_2.getn
  L8_2 = L6_2
  L7_2 = L7_2(L8_2)
  if L7_2 < 1 then
    L8_2 = nCost
    if L5_2 > L8_2 then
      L8_2 = MrxPmc
      L8_2 = L8_2.AddCashQty
      L9_2 = nCost
      L9_2 = -L9_2
      L8_2(L9_2)
      L8_2 = Pg
      L8_2 = L8_2.Spawn
      L9_2 = "Emplaced TOW (Allied) (seatbelt)"
      L10_2 = L1_2
      L11_2 = L2_2 + 3.25
      L12_2 = L3_2
      L13_2 = L4_2
      L14_2 = false
      L15_2 = true
      L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
      L9_2 = Vehicle
      L9_2 = L9_2.GetRiders
      L10_2 = L8_2
      L9_2 = L9_2(L10_2)
      L10_2 = L9_2[1]
      L11_2 = Pg
      L11_2 = L11_2.FastCollectHumans
      L12_2 = L1_2
      L13_2 = L2_2
      L14_2 = L3_2
      L15_2 = 45
      L16_2 = "China && Vehicle"
      L11_2 = L11_2(L12_2, L13_2, L14_2, L15_2, L16_2)
      L12_2 = Ai
      L12_2 = L12_2.Anchor
      L13_2 = {}
      L13_2.AIGuid = L10_2
      L13_2.AnchorRadius = 2
      L13_2.AnchorPosition = L1_2
      L14_2 = L2_2
      L15_2 = L3_2
      L13_2[1] = L14_2
      L13_2[2] = L15_2
      L12_2(L13_2)
      L12_2 = Ai
      L12_2 = L12_2.Goal
      L13_2 = {}
      L13_2.AIGuid = L10_2
      L13_2.Goal = "Attack"
      L14_2 = L11_2[1]
      L13_2.Target = L14_2
      L13_2.Priority = "medPri"
      L12_2(L13_2)
      L12_2 = MrxSubtitle
      L12_2 = L12_2.Add
      L13_2 = "[green]Emplacement Purchased!!!"
      L12_2(L13_2)
      L12_2 = GunnerLeaves
      L13_2 = A0_2
      L14_2 = L8_2
      L15_2 = L10_2
      L12_2(L13_2, L14_2, L15_2)
    else
      L8_2 = MrxSubtitle
      L8_2 = L8_2.Add
      L9_2 = "[red]Insufficient Funds!!!"
      L8_2(L9_2)
    end
  else
    L8_2 = MrxSubtitle
    L8_2 = L8_2.Add
    L9_2 = "[red]Already occupied!!!"
    L8_2(L9_2)
  end
end

PurchaseEmplacement = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectInSeat
  L5_2 = {}
  L6_2 = A2_2
  L7_2 = A1_2
  L8_2 = "a"
  L9_2 = "x"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  
  function L6_2(A0_3, A1_3)
    local L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
    L2_3 = Event
    L2_3 = L2_3.Create
    L3_3 = Event
    L3_3 = L3_3.TimerRelative
    L4_3 = {}
    L5_3 = 10
    L4_3[1] = L5_3
    L5_3 = Object
    L5_3 = L5_3.FadeOut
    L6_3 = {}
    L7_3 = A0_3
    L8_3 = 1
    L9_3 = true
    L6_3[1] = L7_3
    L6_3[2] = L8_3
    L6_3[3] = L9_3
    L2_3 = L2_3(L3_3, L4_3, L5_3, L6_3)
    eFadeOut = L2_3
  end
  
  L7_2 = {}
  L8_2 = A1_2
  L9_2 = A2_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  eGunnerLeaves = L3_2
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectInSeat
  L5_2 = {}
  L6_2 = A2_2
  L7_2 = A1_2
  L8_2 = "a"
  L9_2 = "e"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  
  function L6_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = Event
    L0_3 = L0_3.Delete
    L1_3 = eFadeOut
    L0_3(L1_3)
    L0_3 = GunnerLeaves
    L1_3 = A0_2
    L2_3 = A1_2
    L3_3 = A2_2
    L0_3(L1_3, L2_3, L3_3)
  end
  
  L7_2 = {}
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  eGunnerEnters = L3_2
end

GunnerLeaves = L0_1
