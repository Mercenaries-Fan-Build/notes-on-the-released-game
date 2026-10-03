local L0_1, L1_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 == "function" then
    L2_2 = type
    L3_2 = A1_2
    L2_2 = L2_2(L3_2)
    if L2_2 == "table" then
      L2_2 = A0_2
      L3_2 = unpack
      L4_2 = A1_2
      L3_2, L4_2 = L3_2(L4_2)
      return L2_2(L3_2, L4_2)
    else
      L2_2 = A0_2
      return L2_2()
    end
  end
end

CallWithOptionalArgs = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 == "table" then
    L2_2 = ipairs
    L3_2 = A0_2
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2, L6_2 in L2_2, L3_2, L4_2 do
      L7_2 = L6_2[2]
      L8_2 = nil
      L9_2 = type
      L10_2 = L7_2
      L9_2 = L9_2(L10_2)
      L9_2 = L9_2 == "table"
      L10_2 = type
      L11_2 = A1_2
      L10_2 = L10_2(L11_2)
      L10_2 = L10_2 == "table"
      if L9_2 and L10_2 then
        L11_2 = MergeIndexedTables
        L12_2 = L7_2
        L13_2 = A1_2
        L11_2 = L11_2(L12_2, L13_2)
        L8_2 = L11_2
      elseif L9_2 then
        L8_2 = L7_2
      elseif L10_2 then
        L8_2 = A1_2
      end
      L11_2 = CallWithOptionalArgs
      L12_2 = L6_2[1]
      L13_2 = L8_2
      L11_2(L12_2, L13_2)
    end
  end
end

ProcessCallbackTable = L0_1
