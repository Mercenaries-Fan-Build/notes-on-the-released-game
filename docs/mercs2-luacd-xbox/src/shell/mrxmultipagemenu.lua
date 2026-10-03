local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)

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

_CallWithOptionalArgs = L0_1
L0_1 = 8
_knMaxOptionsPerPage = L0_1
L0_1 = nil
_DialogBox = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = {}
  _tOptions = L0_2
  L0_2 = {}
  _tOptionsOnEveryPage = L0_2
  L0_2 = {}
  _tOptionsToCallbacks = L0_2
  L0_2 = {}
  _tPageOptions = L0_2
  L0_2 = 0
  _nPages = L0_2
  L0_2 = ""
  _sCancelButtonOptionName = L0_2
end

Init = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = Init
  L0_2()
end

Reset = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _DialogBox
  if L0_2 then
    L0_2 = MrxGui
    L0_2 = L0_2.CloseDialogBox
    L1_2 = _DialogBox
    L0_2(L1_2)
    L0_2 = nil
    _DialogBox = L0_2
  end
end

Close = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = _sCancelButtonOptionName
  if L1_2 == "" then
    _sCancelButtonOptionName = A0_2
  end
end

BindOptionToCancelButton = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2
  L5_2 = _tOptions
  if A3_2 then
    L5_2 = _tOptionsOnEveryPage
  end
  if A4_2 then
    L6_2 = BindOptionToCancelButton
    L7_2 = A0_2
    L6_2(L7_2)
  end
  L6_2 = table
  L6_2 = L6_2.insert
  L7_2 = L5_2
  L8_2 = A0_2
  L6_2(L7_2, L8_2)
  L6_2 = _tOptionsToCallbacks
  L7_2 = {}
  L8_2 = A1_2
  L9_2 = A2_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L6_2[A0_2] = L7_2
end

AddOption = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = 0
  _nPages = L1_2
  L1_2 = table
  L1_2 = L1_2.getn
  L2_2 = _tOptions
  L1_2 = L1_2(L2_2)
  L2_2 = table
  L2_2 = L2_2.getn
  L3_2 = _tOptionsOnEveryPage
  L2_2 = L2_2(L3_2)
  L3_2 = _knMaxOptionsPerPage
  L3_2 = L3_2 - L2_2
  while true do
    L4_2 = _nPages
    L4_2 = L4_2 * L3_2
    if not (L1_2 > L4_2) then
      break
    end
    L4_2 = _nPages
    L4_2 = L4_2 + 1
    _nPages = L4_2
  end
  L4_2 = _Display
  L5_2 = 1
  L6_2 = A0_2
  L4_2(L5_2, L6_2)
end

Display = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L2_2 = {}
  _tPageOptions = L2_2
  L2_2 = nil
  L3_2 = _nPages
  if A0_2 < L3_2 then
    L3_2 = table
    L3_2 = L3_2.insert
    L4_2 = _tPageOptions
    L5_2 = "Next page"
    L3_2(L4_2, L5_2)
  end
  if 1 < A0_2 then
    L3_2 = table
    L3_2 = L3_2.insert
    L4_2 = _tPageOptions
    L5_2 = "Previous page"
    L3_2(L4_2, L5_2)
  end
  L3_2 = table
  L3_2 = L3_2.getn
  L4_2 = _tOptionsOnEveryPage
  L3_2 = L3_2(L4_2)
  L4_2 = _knMaxOptionsPerPage
  L4_2 = L4_2 - L3_2
  L5_2 = A0_2 - 1
  L5_2 = L5_2 * L4_2
  L5_2 = L5_2 + 1
  L6_2 = L5_2
  L7_2 = L5_2 + L4_2
  L7_2 = L7_2 - 1
  L8_2 = 1
  for L9_2 = L6_2, L7_2, L8_2 do
    L10_2 = _tOptions
    L10_2 = L10_2[L9_2]
    if L10_2 then
      L11_2 = table
      L11_2 = L11_2.insert
      L12_2 = _tPageOptions
      L13_2 = L10_2
      L11_2(L12_2, L13_2)
      L11_2 = _sCancelButtonOptionName
      if L11_2 == L10_2 then
        L11_2 = table
        L11_2 = L11_2.getn
        L12_2 = _tPageOptions
        L11_2 = L11_2(L12_2)
        L2_2 = L11_2
      end
    else
      break
    end
  end
  L6_2 = ipairs
  L7_2 = _tOptionsOnEveryPage
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  for L9_2, L10_2 in L6_2, L7_2, L8_2 do
    L11_2 = table
    L11_2 = L11_2.insert
    L12_2 = _tPageOptions
    L13_2 = L10_2
    L11_2(L12_2, L13_2)
    L11_2 = _sCancelButtonOptionName
    if L11_2 == L10_2 then
      L11_2 = table
      L11_2 = L11_2.getn
      L12_2 = _tPageOptions
      L11_2 = L11_2(L12_2)
      L2_2 = L11_2
    end
  end
  L6_2 = A1_2
  L7_2 = _nPages
  if 1 < L7_2 then
    L7_2 = L6_2
    L8_2 = " (Page "
    L9_2 = A0_2
    L10_2 = "/"
    L11_2 = _nPages
    L12_2 = ")"
    L6_2 = L7_2 .. L8_2 .. L9_2 .. L10_2 .. L11_2 .. L12_2
  end
  L7_2 = MrxGui
  L7_2 = L7_2.DisplayDialogBox
  L8_2 = Player
  L8_2 = L8_2.GetLocalPlayer
  L8_2 = L8_2()
  L9_2 = L6_2
  L10_2 = _tPageOptions
  L11_2 = nDefaultOption
  if not L11_2 then
    L11_2 = 1
  end
  L12_2 = _ChooseOption
  L13_2 = {}
  L14_2 = A0_2
  L15_2 = A1_2
  L13_2[1] = L14_2
  L13_2[2] = L15_2
  L14_2 = nil
  L15_2 = nil
  L16_2 = nil
  L17_2 = nil
  L18_2 = nil
  L19_2 = L2_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
  _DialogBox = L7_2
end

_Display = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = _tPageOptions
  L3_2 = L3_2[A2_2]
  if L3_2 == "Previous page" then
    L4_2 = _Display
    L5_2 = A0_2 - 1
    L6_2 = A1_2
    L4_2(L5_2, L6_2)
  elseif L3_2 == "Next page" then
    L4_2 = _Display
    L5_2 = A0_2 + 1
    L6_2 = A1_2
    L4_2(L5_2, L6_2)
  else
    L4_2 = nil
    _DialogBox = L4_2
    L4_2 = _tOptionsToCallbacks
    L4_2 = L4_2[L3_2]
    if L4_2 then
      L5_2 = _CallWithOptionalArgs
      L6_2 = L4_2[1]
      L7_2 = L4_2[2]
      L5_2(L6_2, L7_2)
    end
  end
end

_ChooseOption = L0_1
