local L0_1, L1_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  if not A0_2 then
    return
  end
  L1_2 = ipairs
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = Pg
    L6_2 = L6_2.SpawnFromCamera
    L7_2 = L5_2
    L8_2 = 10
    L9_2 = 0.5
    L6_2(L7_2, L8_2, L9_2)
  end
end

Multi = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2
  if not A2_2 then
    A2_2 = 0
  end
  if not A3_2 then
    A3_2 = 0
  end
  if not A1_2 then
    A1_2 = 1
  end
  if not A4_2 then
    A4_2 = 10
  end
  if not A5_2 then
    A5_2 = 0.5
  end
  if not A0_2 then
    return
  end
  L6_2 = Pg
  L6_2 = L6_2.FindPointFromCamera
  L7_2 = A4_2
  L8_2 = A5_2
  L6_2, L7_2, L8_2 = L6_2(L7_2, L8_2)
  L9_2 = Pg
  L9_2 = L9_2.Spawn
  L10_2 = A0_2
  L11_2 = L6_2
  L12_2 = L7_2
  L13_2 = L8_2
  L9_2(L10_2, L11_2, L12_2, L13_2)
  L9_2 = 1
  L10_2 = A1_2 - 1
  L11_2 = 1
  for L12_2 = L9_2, L10_2, L11_2 do
    L13_2 = math
    L13_2 = L13_2.randf
    L13_2 = L13_2()
    L13_2 = L13_2 * A2_2
    L14_2 = math
    L14_2 = L14_2.randf
    L14_2 = L14_2()
    L14_2 = L14_2 * A2_2
    L13_2 = L13_2 - L14_2
    L13_2 = L13_2 / 2
    L13_2 = L6_2 + L13_2
    L14_2 = math
    L14_2 = L14_2.randf
    L14_2 = L14_2()
    L14_2 = L14_2 * A2_2
    L15_2 = math
    L15_2 = L15_2.randf
    L15_2 = L15_2()
    L15_2 = L15_2 * A2_2
    L14_2 = L14_2 - L15_2
    L14_2 = L14_2 / 2
    L14_2 = L8_2 + L14_2
    L15_2 = Event
    L15_2 = L15_2.Create
    L16_2 = Event
    L16_2 = L16_2.TimerRelative
    L17_2 = {}
    L18_2 = A3_2 / A1_2
    L18_2 = L18_2 * L12_2
    L17_2[1] = L18_2
    L18_2 = Pg
    L18_2 = L18_2.Spawn
    L19_2 = {}
    L20_2 = A0_2
    L21_2 = L13_2
    L22_2 = L7_2
    L23_2 = L14_2
    L19_2[1] = L20_2
    L19_2[2] = L21_2
    L19_2[3] = L22_2
    L19_2[4] = L23_2
    L15_2(L16_2, L17_2, L18_2, L19_2)
  end
end

Scatter = L0_1
