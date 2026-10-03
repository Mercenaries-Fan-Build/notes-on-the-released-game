local L0_1, L1_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = String
  L3_2 = L3_2.GetHash
  L4_2 = "Slice00"
  L3_2 = L3_2(L4_2)
  if A1_2 == L3_2 then
    L3_2 = String
    L3_2 = L3_2.GetHash
    L4_2 = "CollapseFireState"
    L3_2 = L3_2(L4_2)
    if A2_2 == L3_2 then
      L3_2 = Event
      L3_2 = L3_2.Create
      L4_2 = Event
      L4_2 = L4_2.ObjectIsReady
      L5_2 = {}
      L6_2 = A0_2
      L5_2[1] = L6_2
      L6_2 = _PlayMaterialAnims
      L7_2 = {}
      L8_2 = A0_2
      L7_2[1] = L8_2
      L3_2(L4_2, L5_2, L6_2, L7_2)
    end
  end
end

OnStateChange = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Object
  L1_2 = L1_2.PlayMaterialAnimation
  L2_2 = A0_2
  L3_2 = "jungle_env_largecanopy01_material_anim"
  L4_2 = false
  L1_2(L2_2, L3_2, L4_2)
end

_PlayMaterialAnims = L0_1
