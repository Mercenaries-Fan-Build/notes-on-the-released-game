local L0_1, L1_1
L0_1 = {}
_tMsgIds = L0_1
L0_1 = 5
_knDisplayDuration = L0_1
L0_1 = 0.5
_knFadeDuration = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L4_2 = type
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if L4_2 == "string" then
    L5_2 = {}
    L6_2 = A0_2
    L5_2[1] = L6_2
    L3_2 = L5_2
  elseif L4_2 == "table" then
    L3_2 = A0_2
  else
    return
  end
  L5_2 = table
  L5_2 = L5_2.getn
  L6_2 = L3_2
  L5_2 = L5_2(L6_2)
  L6_2 = ipairs
  L7_2 = L3_2
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  for L9_2, L10_2 in L6_2, L7_2, L8_2 do
    L11_2 = {}
    L11_2.sMessage = L10_2
    L12_2 = _knDisplayDuration
    L11_2.nDuration = L12_2
    L12_2 = _knFadeDuration
    L11_2.nFadeTime = L12_2
    L11_2.bClearBuffer = true
    L11_2.bAllowsAppends = false
    if L9_2 == L5_2 then
      L11_2.fCallback = A1_2
      L11_2.tCallbackData = A2_2
    end
    L12_2 = Hud
    L12_2 = L12_2.SubtitleBuffer
    L13_2 = L12_2
    L12_2 = L12_2.AddMessage
    L14_2 = L11_2
    L12_2 = L12_2(L13_2, L14_2)
    if L12_2 then
      L13_2 = table
      L13_2 = L13_2.insert
      L14_2 = _tMsgIds
      L15_2 = L12_2
      L13_2(L14_2, L15_2)
    end
  end
end

Add = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = ipairs
  L1_2 = _tMsgIds
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = Hud
    L5_2 = L5_2.SubtitleBuffer
    L6_2 = L5_2
    L5_2 = L5_2.RemovePendingMessage
    L7_2 = {}
    L7_2.tMessageIds = L4_2
    L5_2(L6_2, L7_2)
  end
  L0_2 = nil
  _tMsgIds = L0_2
  L0_2 = {}
  _tMsgIds = L0_2
end

ClearPending = L0_1
