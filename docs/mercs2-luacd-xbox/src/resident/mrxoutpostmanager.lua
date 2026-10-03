local L0_1, L1_1
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = 1
knStatusCaptured = L0_1
L0_1 = 2
knStatusDestroyed = L0_1
L0_1 = {}
_tOutposts = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = _tOutposts
  L1_2 = L1_2[A0_2]
  if L1_2 then
    return
  end
  L1_2 = _tOutposts
  L2_2 = {}
  L3_2 = {}
  L2_2.tCallbacks = L3_2
  L1_2[A0_2] = L2_2
end

RegisterOutpost = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = _tOutposts
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    return
  end
  L1_2 = _tOutposts
  L1_2[A0_2] = nil
end

UnregisterOutpost = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  L3_2 = RegisterOutpost
  L4_2 = A0_2
  L3_2(L4_2)
  L3_2 = table
  L3_2 = L3_2.insert
  L4_2 = _tOutposts
  L4_2 = L4_2[A0_2]
  L4_2 = L4_2.tCallbacks
  L5_2 = {}
  L5_2.fCallback = A1_2
  L5_2.tCallbackArgs = A2_2
  L3_2(L4_2, L5_2)
end

RegisterOutpostEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = _tOutposts
  L2_2 = L2_2[A0_2]
  if not L2_2 then
    return
  end
  L2_2 = ipairs
  L3_2 = _tOutposts
  L3_2 = L3_2[A0_2]
  L3_2 = L3_2.tCallbacks
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = MrxUtil
    L7_2 = L7_2.CallWithOptionalArgs
    L8_2 = L6_2.fCallback
    L9_2 = {}
    L10_2 = unpack
    L11_2 = L6_2.tCallbackArgs
    L10_2 = L10_2(L11_2)
    L11_2 = A0_2
    L12_2 = A1_2
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L7_2(L8_2, L9_2)
  end
  L2_2 = UnregisterOutpost
  L3_2 = A0_2
  L2_2(L3_2)
end

OutpostStatusChange = L0_1
