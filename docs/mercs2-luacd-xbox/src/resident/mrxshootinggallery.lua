local L0_1, L1_1
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = {}
  tWeapons = L1_2
  L1_2 = Human
  L1_2 = L1_2.Inventory
  L1_2 = L1_2.GetPrimaryWeapon
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  uPrimaryWeapon = L1_2
  L1_2 = uPrimaryWeapon
  if L1_2 then
    L1_2 = Human
    L1_2 = L1_2.Inventory
    L1_2 = L1_2.DropWeapon
    L2_2 = A0_2
    L3_2 = uPrimaryWeapon
    L1_2(L2_2, L3_2)
    L1_2 = Object
    L1_2 = L1_2.GetPosition
    L2_2 = A0_2
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    z = L3_2
    y = L2_2
    x = L1_2
    L1_2 = Object
    L1_2 = L1_2.DisablePhysics
    L2_2 = uPrimaryWeapon
    L1_2(L2_2)
    L1_2 = Object
    L1_2 = L1_2.SetPosition
    L2_2 = uPrimaryWeapon
    L3_2 = x
    L4_2 = y
    L4_2 = L4_2 - 5
    L5_2 = z
    L1_2(L2_2, L3_2, L4_2, L5_2)
    L1_2 = tWeapons
    L2_2 = uPrimaryWeapon
    L1_2.Primary1 = L2_2
  end
  L1_2 = Human
  L1_2 = L1_2.Inventory
  L1_2 = L1_2.GetPrimaryWeapon
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  uPrimaryWeapon2 = L1_2
  L1_2 = uPrimaryWeapon2
  if L1_2 then
    L1_2 = Human
    L1_2 = L1_2.Inventory
    L1_2 = L1_2.DropWeapon
    L2_2 = A0_2
    L3_2 = uPrimaryWeapon2
    L1_2(L2_2, L3_2)
    L1_2 = Object
    L1_2 = L1_2.GetPosition
    L2_2 = A0_2
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    z = L3_2
    y = L2_2
    x = L1_2
    L1_2 = Object
    L1_2 = L1_2.DisablePhysics
    L2_2 = uPrimaryWeapon2
    L1_2(L2_2)
    L1_2 = Object
    L1_2 = L1_2.SetPosition
    L2_2 = uPrimaryWeapon2
    L3_2 = x
    L4_2 = y
    L4_2 = L4_2 - 5
    L5_2 = z
    L1_2(L2_2, L3_2, L4_2, L5_2)
    L1_2 = tWeapons
    L2_2 = uPrimaryWeapon2
    L1_2.Primary2 = L2_2
  end
  L1_2 = Human
  L1_2 = L1_2.Inventory
  L1_2 = L1_2.GetSecondaryWeapon
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  uSecondaryWeapon = L1_2
  L1_2 = uSecondaryWeapon
  if L1_2 then
    L1_2 = Human
    L1_2 = L1_2.Inventory
    L1_2 = L1_2.DropWeapon
    L2_2 = A0_2
    L3_2 = uSecondaryWeapon
    L1_2(L2_2, L3_2)
    L1_2 = Object
    L1_2 = L1_2.GetPosition
    L2_2 = A0_2
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    z = L3_2
    y = L2_2
    x = L1_2
    L1_2 = Object
    L1_2 = L1_2.DisablePhysics
    L2_2 = uSecondaryWeapon
    L1_2(L2_2)
    L1_2 = Object
    L1_2 = L1_2.SetPosition
    L2_2 = uSecondaryWeapon
    L3_2 = x
    L4_2 = y
    L4_2 = L4_2 - 5
    L5_2 = z
    L1_2(L2_2, L3_2, L4_2, L5_2)
    L1_2 = tWeapons
    L2_2 = uSecondaryWeapon
    L1_2.Secondary1 = L2_2
  end
  L1_2 = Human
  L1_2 = L1_2.Inventory
  L1_2 = L1_2.GetSecondaryWeapon
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  uSecondaryWeapon2 = L1_2
  L1_2 = uSecondaryWeapon2
  if L1_2 then
    L1_2 = Human
    L1_2 = L1_2.Inventory
    L1_2 = L1_2.DropWeapon
    L2_2 = A0_2
    L3_2 = uSecondaryWeapon2
    L1_2(L2_2, L3_2)
    L1_2 = Object
    L1_2 = L1_2.GetPosition
    L2_2 = A0_2
    L1_2, L2_2, L3_2 = L1_2(L2_2)
    z = L3_2
    y = L2_2
    x = L1_2
    L1_2 = Object
    L1_2 = L1_2.DisablePhysics
    L2_2 = uSecondaryWeapon2
    L1_2(L2_2)
    L1_2 = Object
    L1_2 = L1_2.SetPosition
    L2_2 = uSecondaryWeapon2
    L3_2 = x
    L4_2 = y
    L4_2 = L4_2 - 5
    L5_2 = z
    L1_2(L2_2, L3_2, L4_2, L5_2)
    L1_2 = tWeapons
    L2_2 = uSecondaryWeapon2
    L1_2.Secondary2 = L2_2
  end
  L1_2 = tWeapons
  return L1_2
end

RemoveWeapons = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = Object
  L2_2 = L2_2.SetInfiniteAmmo
  L3_2 = A0_2
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = Human
  L2_2 = L2_2.Inventory
  L2_2 = L2_2.GetPrimaryWeapon
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  uGalleryWeapon = L2_2
  L2_2 = uGalleryWeapon
  if L2_2 then
    L2_2 = Human
    L2_2 = L2_2.Inventory
    L2_2 = L2_2.DropWeapon
    L3_2 = A0_2
    L4_2 = uGalleryWeapon
    L2_2(L3_2, L4_2)
    L2_2 = Object
    L2_2 = L2_2.GetPosition
    L3_2 = A0_2
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    z = L4_2
    y = L3_2
    x = L2_2
    L2_2 = Object
    L2_2 = L2_2.DisablePhysics
    L3_2 = uGalleryWeapon
    L2_2(L3_2)
    L2_2 = Object
    L2_2 = L2_2.SetPosition
    L3_2 = uGalleryWeapon
    L4_2 = x
    L5_2 = y
    L5_2 = L5_2 - 5
    L6_2 = z
    L2_2(L3_2, L4_2, L5_2, L6_2)
  end
  L2_2 = A1_2.Secondary1
  if L2_2 then
    L2_2 = Human
    L2_2 = L2_2.Inventory
    L2_2 = L2_2.EquipWeapon
    L3_2 = A0_2
    L4_2 = A1_2.Secondary1
    L2_2(L3_2, L4_2)
  end
  L2_2 = A1_2.Secondary2
  if L2_2 then
    L2_2 = Human
    L2_2 = L2_2.Inventory
    L2_2 = L2_2.EquipWeapon
    L3_2 = A0_2
    L4_2 = A1_2.Secondary2
    L2_2(L3_2, L4_2)
  end
  L2_2 = A1_2.Primary2
  if L2_2 then
    L2_2 = Human
    L2_2 = L2_2.Inventory
    L2_2 = L2_2.EquipWeapon
    L3_2 = A0_2
    L4_2 = A1_2.Primary2
    L2_2(L3_2, L4_2)
  end
  L2_2 = A1_2.Primary1
  if L2_2 then
    L2_2 = Human
    L2_2 = L2_2.Inventory
    L2_2 = L2_2.EquipWeapon
    L3_2 = A0_2
    L4_2 = A1_2.Primary1
    L2_2(L3_2, L4_2)
  end
end

ReturnWeapons = L0_1
L0_1 = nil

function L1_1()
  local L0_2, L1_2
  L0_2 = Event
  L0_2 = L0_2.Delete
  L1_2 = _evNetSafeSetupBorder
  L0_2(L1_2)
  L0_2 = Event
  L0_2 = L0_2.Delete
  L1_2 = _BorderEventP1
  L0_2(L1_2)
  L0_2 = Event
  L0_2 = L0_2.Delete
  L1_2 = _BorderEventP2
  L0_2(L1_2)
  L0_2 = uFireLockVO
  if L0_2 then
    L0_2 = Event
    L0_2 = L0_2.Delete
    L1_2 = uFireLockVO
    L0_2(L1_2)
  end
  L0_2 = L0_1
  if L0_2 then
    L0_2 = Event
    L0_2 = L0_2.Delete
    L1_2 = L0_1
    L0_2(L1_2)
    L0_2 = nil
    L0_1 = L0_2
  end
end

ClearEvents = L1_1

function L1_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = Player
  L0_2 = L0_2.GetPrimaryCharacter
  L0_2 = L0_2()
  L1_2 = Player
  L1_2 = L1_2.GetSecondaryCharacter
  L1_2 = L1_2()
  if L0_2 then
    L2_2 = Human
    L2_2 = L2_2.SetFireLock
    L3_2 = L0_2
    L4_2 = false
    L2_2(L3_2, L4_2)
  end
  if L1_2 then
    L2_2 = Human
    L2_2 = L2_2.SetFireLock
    L3_2 = L1_2
    L4_2 = false
    L2_2(L3_2, L4_2)
  end
  L2_2 = ClearEvents
  L2_2()
end

Reset = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Net
  L1_2 = L1_2.IsClient
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = SetupBorder
    L2_2 = A0_2
    L1_2(L2_2)
    L1_2 = Event
    L1_2 = L1_2.Create
    L2_2 = Event
    L2_2 = L2_2.GameStateChange
    L3_2 = {}
    L4_2 = "WaitForTether"
    L5_2 = "exit"
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L4_2 = SetupBorder
    L5_2 = {}
    L6_2 = A0_2
    L5_2[1] = L6_2
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
    _evNetSafeSetupBorder = L1_2
  end
end

NetSafeSetupBorder = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Player
  L1_2 = L1_2.GetSecondaryCharacter
  L1_2 = L1_2()
  if L1_2 then
    L2_2 = Event
    L2_2 = L2_2.Create
    L3_2 = Event
    L3_2 = L3_2.ObjectHibernation
    L4_2 = {}
    L5_2 = L1_2
    L6_2 = "awake"
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    
    function L5_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
      L0_3 = Event
      L0_3 = L0_3.Create
      L1_3 = Event
      L1_3 = L1_3.Boundary
      L2_3 = {}
      L3_3 = L1_2
      L4_3 = A0_2
      L5_3 = "exit"
      L2_3[1] = L3_3
      L2_3[2] = L4_3
      L2_3[3] = L5_3
      L3_3 = SteppedOut
      L4_3 = {}
      L5_3 = L1_2
      L6_3 = A0_2
      L4_3[1] = L5_3
      L4_3[2] = L6_3
      L0_3 = L0_3(L1_3, L2_3, L3_3, L4_3)
      _BorderEventP2 = L0_3
    end
    
    L2_2(L3_2, L4_2, L5_2)
  end
end

SetupClientBorder = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Net
  L1_2 = L1_2.IsServer
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = Net
    L1_2 = L1_2.SetShootingGalleryBorder
    L2_2 = A0_2
    L1_2(L2_2)
  end
  if not A0_2 then
    L1_2 = Reset
    L1_2()
  else
    L1_2 = Reset
    L1_2()
    L1_2 = Event
    L1_2 = L1_2.CreatePersistent
    L2_2 = Event
    L2_2 = L2_2.ScriptEvent
    L3_2 = {}
    L4_2 = "mpPlayerJoin"
    
    function L5_2(A0_3)
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
    
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L4_2 = SetupClientBorder
    L5_2 = {}
    L6_2 = A0_2
    L5_2[1] = L6_2
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
    L0_1 = L1_2
    L1_2 = Player
    L1_2 = L1_2.GetPrimaryCharacter
    L1_2 = L1_2()
    L2_2 = Player
    L2_2 = L2_2.GetSecondaryCharacter
    L2_2 = L2_2()
    if L1_2 then
      L3_2 = Event
      L3_2 = L3_2.Create
      L4_2 = Event
      L4_2 = L4_2.Boundary
      L5_2 = {}
      L6_2 = L1_2
      L7_2 = A0_2
      L8_2 = "exit"
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      L5_2[3] = L8_2
      L6_2 = SteppedOut
      L7_2 = {}
      L8_2 = L1_2
      L9_2 = A0_2
      L7_2[1] = L8_2
      L7_2[2] = L9_2
      L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
      _BorderEventP1 = L3_2
    end
    if L2_2 then
      L3_2 = Event
      L3_2 = L3_2.Create
      L4_2 = Event
      L4_2 = L4_2.Boundary
      L5_2 = {}
      L6_2 = L2_2
      L7_2 = A0_2
      L8_2 = "exit"
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      L5_2[3] = L8_2
      L6_2 = SteppedOut
      L7_2 = {}
      L8_2 = L2_2
      L9_2 = A0_2
      L7_2[1] = L8_2
      L7_2[2] = L9_2
      L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
      _BorderEventP2 = L3_2
    end
  end
end

SetupBorder = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = Player
  L2_2 = L2_2.GetLocalCharacter
  L2_2 = L2_2()
  if L2_2 == A0_2 then
  end
  L2_2 = Human
  L2_2 = L2_2.SetFireLock
  L3_2 = A0_2
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = Human
  L2_2 = L2_2.Inventory
  L2_2 = L2_2.GetPrimaryWeapon
  L3_2 = Player
  L3_2 = L3_2.GetLocalCharacter
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L3_2()
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  uPrimaryWeapon = L2_2
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.WeaponEvent
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetLocalCharacter
  L5_2 = L5_2()
  L6_2 = "FireLock"
  L7_2 = uPrimaryWeapon
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = {}
  L7_2 = {}
  L8_2 = "Fiona-In-Mission-MinorContract-Pmc31-08"
  L7_2[1] = L8_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  uFireLockVO = L2_2
  L2_2 = Player
  L2_2 = L2_2.GetPrimaryCharacter
  L2_2 = L2_2()
  if A0_2 == L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = _BorderEventP1
    L2_2(L3_2)
    L2_2 = Event
    L2_2 = L2_2.Create
    L3_2 = Event
    L3_2 = L3_2.Boundary
    L4_2 = {}
    L5_2 = A0_2
    L6_2 = A1_2
    L7_2 = "enter"
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L4_2[3] = L7_2
    L5_2 = SteppedIn
    L6_2 = {}
    L7_2 = A0_2
    L8_2 = A1_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
    _BorderEventP1 = L2_2
  else
    L2_2 = Player
    L2_2 = L2_2.GetSecondaryCharacter
    L2_2 = L2_2()
    if A0_2 == L2_2 then
      L2_2 = Event
      L2_2 = L2_2.Delete
      L3_2 = _BorderEventP2
      L2_2(L3_2)
      L2_2 = Event
      L2_2 = L2_2.Create
      L3_2 = Event
      L3_2 = L3_2.Boundary
      L4_2 = {}
      L5_2 = A0_2
      L6_2 = A1_2
      L7_2 = "enter"
      L4_2[1] = L5_2
      L4_2[2] = L6_2
      L4_2[3] = L7_2
      L5_2 = SteppedIn
      L6_2 = {}
      L7_2 = A0_2
      L8_2 = A1_2
      L6_2[1] = L7_2
      L6_2[2] = L8_2
      L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
      _BorderEventP2 = L2_2
    end
  end
end

SteppedOut = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = Human
  L2_2 = L2_2.SetFireLock
  L3_2 = A0_2
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = Player
  L2_2 = L2_2.GetPrimaryCharacter
  L2_2 = L2_2()
  if A0_2 == L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = _BorderEventP1
    L2_2(L3_2)
    L2_2 = Event
    L2_2 = L2_2.Create
    L3_2 = Event
    L3_2 = L3_2.Boundary
    L4_2 = {}
    L5_2 = A0_2
    L6_2 = A1_2
    L7_2 = "exit"
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L4_2[3] = L7_2
    L5_2 = SteppedOut
    L6_2 = {}
    L7_2 = A0_2
    L8_2 = A1_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
    _BorderEventP1 = L2_2
  else
    L2_2 = Player
    L2_2 = L2_2.GetSecondaryCharacter
    L2_2 = L2_2()
    if A0_2 == L2_2 then
      L2_2 = Event
      L2_2 = L2_2.Delete
      L3_2 = _BorderEventP2
      L2_2(L3_2)
      L2_2 = Event
      L2_2 = L2_2.Create
      L3_2 = Event
      L3_2 = L3_2.Boundary
      L4_2 = {}
      L5_2 = A0_2
      L6_2 = A1_2
      L7_2 = "exit"
      L4_2[1] = L5_2
      L4_2[2] = L6_2
      L4_2[3] = L7_2
      L5_2 = SteppedOut
      L6_2 = {}
      L7_2 = A0_2
      L8_2 = A1_2
      L6_2[1] = L7_2
      L6_2[2] = L8_2
      L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
      _BorderEventP2 = L2_2
    end
  end
end

SteppedIn = L1_1
