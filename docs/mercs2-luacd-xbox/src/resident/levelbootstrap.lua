local L0_1, L1_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  if A0_2 == nil then
    L3_2 = Sys
    L3_2 = L3_2.GetLevelName
    L3_2 = L3_2()
    A0_2 = L3_2
  end
  if A1_2 == nil then
    L3_2 = Sys
    L3_2 = L3_2.GetMasterScriptName
    L3_2 = L3_2()
    A1_2 = L3_2
  end
  L3_2 = Sys
  L3_2 = L3_2.SetLevelName
  L4_2 = A0_2
  L3_2(L4_2)
  L3_2 = Sys
  L3_2 = L3_2.SetMasterScriptName
  L4_2 = A1_2
  L3_2(L4_2)
  if A2_2 == nil then
    A2_2 = false
  end
  L3_2 = Sys
  L3_2 = L3_2.RequiredAsset
  L4_2 = A0_2
  L5_2 = "_base"
  L4_2 = L4_2 .. L5_2
  L5_2 = "layer"
  L6_2 = -2
  L7_2 = false
  L3_2(L4_2, L5_2, L6_2, L7_2)
  L3_2 = Sys
  L3_2 = L3_2.RequiredAsset
  L4_2 = A1_2
  L5_2 = "script"
  L6_2 = -3
  L7_2 = false
  L3_2(L4_2, L5_2, L6_2, L7_2)
  L3_2 = Sys
  L3_2 = L3_2.RequestGameState
  L4_2 = "Loading"
  L3_2(L4_2)
end

LoadLevel = L0_1
