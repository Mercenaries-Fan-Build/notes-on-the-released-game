local L0_1, L1_1, L2_1, L3_1
L0_1 = inherit
L1_1 = "OrientedBlippable"
L0_1(L1_1)
L0_1 = inherit
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = "temp_radar_icon_airplane"
sTexture = L0_1
L0_1 = 5
nSize = L0_1
L0_1 = {}
L1_1 = 0
L2_1 = 127
L3_1 = 255
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
tColorAlly = L0_1
L0_1 = {}
L1_1 = 200
L2_1 = 200
L3_1 = 200
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
tColorNeutral = L0_1
L0_1 = {}
L1_1 = 255
L2_1 = 0
L3_1 = 0
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
tColorEnemy = L0_1
L0_1 = {}
L1_1 = 0
L2_1 = 255
L3_1 = 0
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
tColorPmc = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = getfenv
  L3_2 = L3_2()
  L5_2 = L3_2
  L4_2 = L3_2.Create
  L6_2 = A0_2
  L7_2 = A1_2
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  L5_2 = MrxFactionManager
  L5_2 = L5_2.GetFaction
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  if L5_2 then
    L6_2 = Ai
    L6_2 = L6_2.GetRelation
    L7_2 = Pg
    L7_2 = L7_2.GetGuidByName
    L8_2 = L5_2
    L7_2 = L7_2(L8_2)
    L8_2 = Pg
    L8_2 = L8_2.GetGuidByName
    L9_2 = "PMC"
    L8_2, L9_2 = L8_2(L9_2)
    L6_2 = L6_2(L7_2, L8_2, L9_2)
    nRelation = L6_2
  else
    L6_2 = 0
    nRelation = L6_2
  end
  L6_2 = Object
  L6_2 = L6_2.HasLabel
  L7_2 = A0_2
  L8_2 = "PMC"
  L6_2 = L6_2(L7_2, L8_2)
  if L6_2 then
    L6_2 = Object
    L6_2 = L6_2.SetUnkillable
    L7_2 = A0_2
    L8_2 = true
    L9_2 = "Support"
    L6_2(L7_2, L8_2, L9_2)
  end
  L6_2 = Object
  L6_2 = L6_2.HasLabel
  L7_2 = A0_2
  L8_2 = "pmc"
  L6_2 = L6_2(L7_2, L8_2)
  if L6_2 then
    L6_2 = tColorPmc
    L4_2.tColor = L6_2
  else
    L6_2 = nRelation
    if L6_2 < 60 then
      L6_2 = nRelation
      if -60 < L6_2 then
        L6_2 = tColorNeutral
        L4_2.tColor = L6_2
    end
    else
      L6_2 = nRelation
      if L6_2 <= -60 then
        L6_2 = tColorEnemy
        L4_2.tColor = L6_2
      else
        L6_2 = nRelation
        if 60 <= L6_2 then
          L6_2 = tColorAlly
          L4_2.tColor = L6_2
        end
      end
    end
  end
  L6_2 = Object
  L6_2 = L6_2.HasLabel
  L7_2 = A0_2
  L8_2 = "C130"
  L6_2 = L6_2(L7_2, L8_2)
  if L6_2 then
    L4_2.sTexture = "temp_radar_icon_c130"
  else
    L6_2 = Object
    L6_2 = L6_2.HasLabel
    L7_2 = A0_2
    L8_2 = "Mig27"
    L6_2 = L6_2(L7_2, L8_2)
    if L6_2 then
      L4_2.sTexture = "temp_radar_icon_mig27"
    else
      L6_2 = Object
      L6_2 = L6_2.HasLabel
      L7_2 = A0_2
      L8_2 = "F35"
      L6_2 = L6_2(L7_2, L8_2)
      if L6_2 then
        L4_2.sTexture = "temp_radar_icon_f35"
      else
        L6_2 = Object
        L6_2 = L6_2.HasLabel
        L7_2 = A0_2
        L8_2 = "b2"
        L6_2 = L6_2(L7_2, L8_2)
        if L6_2 then
          L4_2.sTexture = "temp_radar_icon_b2"
        else
          L6_2 = Object
          L6_2 = L6_2.HasLabel
          L7_2 = A0_2
          L8_2 = "f117"
          L6_2 = L6_2(L7_2, L8_2)
          if L6_2 then
            L4_2.sTexture = "temp_radar_icon_f117"
          else
            L6_2 = Object
            L6_2 = L6_2.HasLabel
            L7_2 = A0_2
            L8_2 = "a10"
            L6_2 = L6_2(L7_2, L8_2)
            if L6_2 then
              L4_2.sTexture = "temp_radar_icon_a10"
            else
              L6_2 = Object
              L6_2 = L6_2.HasLabel
              L7_2 = A0_2
              L8_2 = "ov10"
              L6_2 = L6_2(L7_2, L8_2)
              if L6_2 then
                L4_2.sTexture = "temp_radar_icon_ov10"
              else
                L6_2 = Object
                L6_2 = L6_2.HasLabel
                L7_2 = A0_2
                L8_2 = "cruisemissile"
                L6_2 = L6_2(L7_2, L8_2)
                if L6_2 then
                  L4_2.sTexture = "temp_radar_icon_cruisemissile"
                end
              end
            end
          end
        end
      end
    end
  end
  L6_2 = OrientedBlippable
  L6_2 = L6_2.SetBlipped
  L7_2 = L4_2
  L6_2(L7_2)
  L7_2 = L4_2
  L6_2 = L4_2.SetBlipped
  L6_2(L7_2)
end

OnActivate = L0_1
