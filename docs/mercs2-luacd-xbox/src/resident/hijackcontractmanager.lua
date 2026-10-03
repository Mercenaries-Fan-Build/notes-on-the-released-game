local L0_1, L1_1

function L0_1(A0_2)
  local L1_2
  _oContract = A0_2
end

SetActiveContract = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _oContract
  L1_2 = L0_2
  L0_2 = L0_2.Complete
  L0_2(L1_2)
end

CompleteActiveContract = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _oContract
  L1_2 = L0_2
  L0_2 = L0_2.Cancel
  L0_2(L1_2)
end

CancelActiveContract = L0_1
