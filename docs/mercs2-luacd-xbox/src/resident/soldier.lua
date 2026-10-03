local L0_1, L1_1, L2_1, L3_1
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = 0
L1_1 = {}
L1_1[0] = "Ammo Pickup (Bullet)"
L1_1[1] = "Ammo Pickup (Rocket)"
L2_1 = tEvents
if not L2_1 then
  L2_1 = {}
end

function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2
  L2_2 = L0_1
  L2_2 = L2_2 + 1
  L0_1 = L2_2
  if not A1_2 then
    A1_2 = 0
  end
  L2_2 = Object
  L2_2 = L2_2.InSeat
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    return
  end
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = A0_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L5_2 = false
  L6_2 = "Ammo Pickup (Small)"
  L7_2 = Object
  L7_2 = L7_2.HasLabel
  L8_2 = A0_2
  L9_2 = "HeavySoldier"
  L7_2 = L7_2(L8_2, L9_2)
  if not L7_2 then
    L7_2 = L0_1
    L7_2 = L7_2 / 3
    L8_2 = math
    L8_2 = L8_2.floor
    L9_2 = L0_1
    L9_2 = L9_2 / 3
    L8_2 = L8_2(L9_2)
    if L7_2 ~= L8_2 then
      goto lbl_140
    end
  end
  L7_2 = Object
  L7_2 = L7_2.HasLabel
  L8_2 = A0_2
  L9_2 = "RocketSoldier"
  L7_2 = L7_2(L8_2, L9_2)
  if L7_2 then
    L7_2 = Object
    L7_2 = L7_2.HasLabel
    L8_2 = A0_2
    L9_2 = "MGSoldier"
    L7_2 = L7_2(L8_2, L9_2)
    if not L7_2 then
      L6_2 = "Ammo Pickup (Rocket)"
  end
  else
    L7_2 = Object
    L7_2 = L7_2.HasLabel
    L8_2 = A0_2
    L9_2 = "HeavySoldier"
    L7_2 = L7_2(L8_2, L9_2)
    if L7_2 then
      L6_2 = "Ammo Pickup (Bullet)"
    end
  end
  L7_2 = ipairs
  L8_2 = Player
  L8_2 = L8_2.GetAllPlayers
  L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2 = L8_2()
  L7_2, L8_2, L9_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2)
  for L10_2, L11_2 in L7_2, L8_2, L9_2 do
    L12_2 = Player
    L12_2 = L12_2.GetCharacter
    L13_2 = L11_2
    L12_2 = L12_2(L13_2)
    L13_2 = Human
    L13_2 = L13_2.Inventory
    L13_2 = L13_2.GetAllWeapons
    L14_2 = L12_2
    L13_2 = L13_2(L14_2)
    L14_2 = pairs
    L15_2 = L13_2
    L14_2, L15_2, L16_2 = L14_2(L15_2)
    for L17_2, L18_2 in L14_2, L15_2, L16_2 do
      L19_2 = Weapon
      L19_2 = L19_2.GetReserveAmmo
      L20_2 = L18_2
      L19_2 = L19_2(L20_2)
      if L19_2 then
        L20_2 = Object
        L20_2 = L20_2.HasLabel
        L21_2 = L18_2
        L22_2 = "Grenade"
        L20_2 = L20_2(L21_2, L22_2)
        if L20_2 then
          L20_2 = math
          L20_2 = L20_2.randf
          L21_2 = 8
          L20_2 = L20_2(L21_2)
          if L19_2 < L20_2 then
            L6_2 = "Ammo Pickup (Grenades)"
          end
        end
      end
    end
    L14_2 = math
    L14_2 = L14_2.randf
    L14_2 = L14_2()
    L14_2 = L14_2 * 80
    L15_2 = Object
    L15_2 = L15_2.GetHealth
    L16_2 = L12_2
    L15_2 = L15_2(L16_2)
    if L14_2 > L15_2 then
      L6_2 = "Health Pickup"
      L5_2 = true
    end
  end
  L7_2 = Pg
  L7_2 = L7_2.Spawn
  L8_2 = L6_2
  L9_2 = L2_2
  L10_2 = L3_2 + 0.1
  L11_2 = L4_2
  L12_2 = 0
  L13_2 = false
  L14_2 = true
  L15_2 = A0_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  if L7_2 then
    L8_2 = Object
    L8_2 = L8_2.ApplyImpulse
    L9_2 = L7_2
    L10_2 = 0
    L11_2 = -0.5
    L12_2 = 0
    L8_2(L9_2, L10_2, L11_2, L12_2)
    L8_2 = Object
    L8_2 = L8_2.AddToDisposer
    L9_2 = L7_2
    L10_2 = "pickup"
    L8_2(L9_2, L10_2)
  end
  ::lbl_140::
end

OnDeath = L3_1
