local L0_1, L1_1
L0_1 = 0
_knLatent = L0_1
L0_1 = 1
_knActive = L0_1
L0_1 = 2
_knCompleted = L0_1
L0_1 = 3
_knCancelled = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = _knLatent
  L1_2 = A0_2 == L1_2
  return L1_2
end

IsValidState = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = _knLatent
  if A0_2 == L2_2 then
    L1_2 = "latent"
  else
    L2_2 = _knActive
    if A0_2 == L2_2 then
      L1_2 = "active"
    else
      L2_2 = _knCompleted
      if A0_2 == L2_2 then
        L1_2 = "completed"
      else
        L2_2 = _knCancelled
        if A0_2 == L2_2 then
          L1_2 = "cancelled"
        end
      end
    end
  end
  return L1_2
end

GetStateDisplayName = L0_1
