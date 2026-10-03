local L0_1, L1_1
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = table
  L3_2 = L3_2.getn
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  L4_2 = A0_2[L3_2]
  L4_2.fCallback = A1_2
  L4_2 = A0_2[L3_2]
  L4_2.tCallbackData = A2_2
  L4_2 = A0_2[L3_2]
  L4_2.nFadeInTime = 0
  L4_2 = L3_2 - 1
  L5_2 = 1
  L6_2 = -1
  for L7_2 = L4_2, L5_2, L6_2 do
    L8_2 = A0_2[L7_2]
    L9_2 = _DisplaySlide
    L8_2.fCallback = L9_2
    L8_2 = A0_2[L7_2]
    L9_2 = {}
    L10_2 = L7_2 + 1
    L10_2 = A0_2[L10_2]
    L9_2[1] = L10_2
    L8_2.tCallbackData = L9_2
    if 1 < L7_2 then
      L8_2 = A0_2[L7_2]
      L8_2.nFadeInTime = 0
    end
    L8_2 = A0_2[L7_2]
    L8_2.nFadeOutTime = 0
  end
  L4_2 = _DisplaySlide
  L5_2 = A0_2[1]
  L4_2(L5_2)
end

PlaceholderSequence = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.sTexture
  if not L1_2 then
    A0_2.sTexture = "temp_placeholder"
  end
  L1_2 = Hud
  L1_2 = L1_2.CinematicPlaceholder
  L2_2 = L1_2
  L1_2 = L1_2.Show
  L3_2 = A0_2
  L1_2(L2_2, L3_2)
end

_DisplaySlide = L0_1
