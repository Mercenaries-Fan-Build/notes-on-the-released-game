local L0_1, L1_1, L2_1, L3_1
L0_1 = inherit
L1_1 = "Blippable"
L0_1(L1_1)
L0_1 = {}
L1_1 = 255
L2_1 = 0
L3_1 = 0
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
tColor = L0_1
L0_1 = {}
L1_1 = 255
L2_1 = 255
L3_1 = 255
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
tFlash = L0_1
L0_1 = nil
sTexture = L0_1
L0_1 = 1
nSize = L0_1
L0_1 = 1
nSortOrder = L0_1

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

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Blippable
  L1_2 = L1_2.SetBlipped
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = A0_2.TimerEvent
  if not L1_2 then
    L1_2 = Event
    L1_2 = L1_2.CreatePersistent
    L2_2 = Event
    L2_2 = L2_2.TimerRelative
    L3_2 = {}
    L4_2 = 0.1
    L3_2[1] = L4_2
    
    function L4_2(A0_3)
      local L1_3, L2_3, L3_3
      L1_3 = A0_3.bFlash
      L1_3 = not L1_3
      A0_3.bFlash = L1_3
      L2_3 = A0_3
      L1_3 = A0_3.AddObjective
      L3_3 = A0_3.bFlash
      L1_3(L2_3, L3_3)
    end
    
    L5_2 = {}
    L6_2 = A0_2
    L5_2[1] = L6_2
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
    A0_2.TimerEvent = L1_2
  end
end

SetBlipped = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2.TimerEvent
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2.TimerEvent
    L1_2(L2_2)
    A0_2.TimerEvent = nil
  end
  L1_2 = Blippable
  L1_2 = L1_2.ClearBlipped
  L2_2 = A0_2
  L1_2(L2_2)
end

ClearBlipped = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = GetFromGuid
  L3_2 = A1_2.uAmmoGuid
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L2_2.bActive = true
  L4_2 = L2_2
  L3_2 = L2_2.SetBlipped
  L3_2(L4_2)
end

_HomingLaunched = L0_1
