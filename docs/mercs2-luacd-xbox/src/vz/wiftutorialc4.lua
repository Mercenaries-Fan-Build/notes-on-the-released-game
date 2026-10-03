local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTutorial"
L0_1(L1_1)

function L0_1()
  local L0_2, L1_2
  L0_2 = "[Tutorial.C4]"
  return L0_2
end

GetMessage = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2 = L1_2()
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.WeaponEvent
  L5_2 = {}
  L6_2 = L1_2
  L7_2 = "Equip"
  L8_2 = "c4"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L6_2 = A0_2.ActivateTutorial2
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

SetupActivationCriteria = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2 = L1_2()
  L2_2 = Human
  L2_2 = L2_2.Inventory
  L2_2 = L2_2.GetAllWeapons
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = Weapon
    L8_2 = L8_2.GetReserveAmmo
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    if L8_2 then
      L9_2 = Object
      L9_2 = L9_2.HasLabel
      L10_2 = L7_2
      L11_2 = "c4"
      L9_2 = L9_2(L10_2, L11_2)
      if L9_2 and 0 < L8_2 then
        L10_2 = A0_2
        L9_2 = A0_2.ActivateTutorial
        L11_2 = true
        L9_2(L10_2, L11_2)
        return
      end
    end
  end
  L4_2 = A0_2
  L3_2 = A0_2.SetupActivationCriteria
  L3_2(L4_2)
end

ActivateTutorial2 = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2 = L1_2()
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.WeaponEvent
  L5_2 = {}
  L6_2 = L1_2
  L7_2 = "Stow"
  L8_2 = "weapon.c4"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L6_2 = A0_2.EndTutorial
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = false
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

SetupCancellationCriteria = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Player
  L1_2 = L1_2.GetLocalCharacter
  L1_2 = L1_2()
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.HumanStateTransition
  L5_2 = {}
  L6_2 = L1_2
  L7_2 = "*"
  L8_2 = "Upright.TriggerDetonator"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L6_2 = A0_2.EndTutorial
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = true
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L2_2 = MrxTutorial
  L2_2 = L2_2.SetupCompletionCriteria
  L3_2 = A0_2
  L2_2(L3_2)
end

SetupCompletionCriteria = L0_1
