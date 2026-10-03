local L0_1, L1_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2
  if not A1_2 then
    A1_2 = 5
  end
  if not A2_2 then
    A2_2 = 10
  end
  if not A3_2 then
    A3_2 = "Artillery Shell"
  end
  if not A4_2 then
    A4_2 = 4
  end
  L5_2 = Object
  L5_2 = L5_2.GetPosition
  L6_2 = A0_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  if L5_2 then
    L8_2 = math
    L8_2 = L8_2.randf
    L8_2 = L8_2()
    L8_2 = L8_2 * A2_2
    L9_2 = math
    L9_2 = L9_2.randf
    L9_2 = L9_2()
    L9_2 = L9_2 * A2_2
    L8_2 = L8_2 - L9_2
    L5_2 = L5_2 + L8_2
    L8_2 = math
    L8_2 = L8_2.randf
    L8_2 = L8_2()
    L8_2 = L8_2 * A2_2
    L9_2 = math
    L9_2 = L9_2.randf
    L9_2 = L9_2()
    L9_2 = L9_2 * A2_2
    L8_2 = L8_2 - L9_2
    L7_2 = L7_2 + L8_2
    L6_2 = L6_2 + 250
    L8_2 = TriggerFallingMissile
    L9_2 = L5_2
    L10_2 = L6_2
    L11_2 = L7_2
    L12_2 = "Artillery Smoke Shell"
    L8_2(L9_2, L10_2, L11_2, L12_2)
    L8_2 = 1
    L9_2 = A1_2
    L10_2 = 1
    for L11_2 = L8_2, L9_2, L10_2 do
      L12_2 = math
      L12_2 = L12_2.randf
      L12_2 = L12_2()
      L12_2 = L12_2 * A2_2
      L13_2 = math
      L13_2 = L13_2.randf
      L13_2 = L13_2()
      L13_2 = L13_2 * A2_2
      L12_2 = L12_2 - L13_2
      L13_2 = A1_2 + 1
      L13_2 = L13_2 / 2
      L13_2 = L13_2 - L11_2
      L13_2 = L13_2 * A2_2
      L12_2 = L12_2 + L13_2
      L12_2 = -L12_2
      L13_2 = math
      L13_2 = L13_2.randf
      L13_2 = L13_2()
      L13_2 = L13_2 * A2_2
      L14_2 = math
      L14_2 = L14_2.randf
      L14_2 = L14_2()
      L14_2 = L14_2 * A2_2
      L13_2 = L13_2 - L14_2
      L13_2 = -L13_2
      L14_2 = L5_2 + L12_2
      L15_2 = L6_2
      L16_2 = L7_2 + L13_2
      L17_2 = Event
      L17_2 = L17_2.Create
      L18_2 = Event
      L18_2 = L18_2.TimerRelative
      L19_2 = {}
      L20_2 = A4_2 / A1_2
      L20_2 = L11_2 * L20_2
      L20_2 = 5 + L20_2
      L19_2[1] = L20_2
      L20_2 = TriggerFallingMissile
      L21_2 = {}
      L22_2 = L14_2
      L23_2 = L15_2
      L24_2 = L16_2
      L25_2 = A3_2
      L21_2[1] = L22_2
      L21_2[2] = L23_2
      L21_2[3] = L24_2
      L21_2[4] = L25_2
      L17_2(L18_2, L19_2, L20_2, L21_2)
    end
  end
end

Create = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L4_2 = Airstrike
  L4_2 = L4_2.SpawnOrdnance
  L5_2 = A3_2
  L6_2 = A0_2
  L7_2 = A1_2
  L8_2 = A2_2
  L9_2 = 0
  L10_2 = -100
  L11_2 = 0
  L12_2 = "impact"
  L13_2 = 1
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
end

TriggerFallingMissile = L0_1
