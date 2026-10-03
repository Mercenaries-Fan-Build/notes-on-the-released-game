local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifFreePlay"
L0_1(L1_1)

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = _tActiveHints
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L2_2 = #L1_2
    if 0 < L2_2 then
      L2_2 = ipairs
      L3_2 = L1_2
      L2_2, L3_2, L4_2 = L2_2(L3_2)
      for L5_2, L6_2 in L2_2, L3_2, L4_2 do
        L7_2 = _tHints
        L7_2 = L7_2[A0_2]
        L7_2 = L7_2[L6_2]
        L8_2 = _TestHintConstraints
        L9_2 = L7_2
        L8_2 = L8_2(L9_2)
        if L8_2 then
          L8_2 = true
          return L8_2
        end
      end
    end
  end
  L2_2 = false
  return L2_2
end

HasHint = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = _tActiveHints
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    return
  end
  L2_2 = #L1_2
  if L2_2 <= 0 then
    return
  end
  L3_2 = nil
  L4_2 = _tLastPlayed
  L4_2 = L4_2[A0_2]
  if L4_2 then
    L4_2 = _tLastPlayed
    L4_2 = L4_2[A0_2]
    L3_2 = L4_2 + 1
  else
    L3_2 = 1
  end
  L4_2 = false
  L5_2 = 1
  L6_2 = L2_2
  L7_2 = 1
  for L8_2 = L5_2, L6_2, L7_2 do
    L9_2 = L1_2[L3_2]
    if not L9_2 then
      L3_2 = 1
    end
    L9_2 = L1_2[L3_2]
    L10_2 = _tHints
    L10_2 = L10_2[A0_2]
    L10_2 = L10_2[L9_2]
    L11_2 = _TestHintConstraints
    L12_2 = L10_2
    L11_2 = L11_2(L12_2)
    L4_2 = L11_2
    if L4_2 then
      L11_2 = _tLastPlayed
      L11_2[A0_2] = L3_2
      L11_2 = L10_2.sCue
      return L11_2
    else
      L3_2 = L3_2 + 1
    end
  end
end

GetHint = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = true
  L2_2 = A0_2.tFactionAttitudeConstraint
  if L2_2 then
    L2_2 = MrxFactionManager
    L2_2 = L2_2.TestAttitude
    L3_2 = A0_2.tFactionAttitudeConstraint
    L3_2 = L3_2[1]
    L4_2 = A0_2.tFactionAttitudeConstraint
    L4_2 = L4_2[2]
    L5_2 = A0_2.tFactionAttitudeConstraint
    L5_2 = L5_2[3]
    L6_2 = A0_2.tFactionAttitudeConstraint
    L6_2 = L6_2[4]
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
    L1_2 = L2_2
  end
  return L1_2
end

_TestHintConstraints = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = {}
  _tLastPlayed = L0_2
end

Reset = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _tActiveHints
  return L0_2
end

SaveSingleton = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 ~= "table" then
    return
  end
  L1_2 = {}
  _tActiveHints = L1_2
  L1_2 = {}
  _tLastPlayed = L1_2
  L1_2 = pairs
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = type
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    if L6_2 == "table" then
      L6_2 = ipairs
      L7_2 = L5_2
      L6_2, L7_2, L8_2 = L6_2(L7_2)
      for L9_2, L10_2 in L6_2, L7_2, L8_2 do
        L11_2 = AddActiveHint
        L12_2 = L10_2
        L11_2(L12_2)
      end
    end
  end
end

LoadSingleton = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = _FindSpeaker
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    return
  end
  L2_2 = _tActiveHints
  L3_2 = _tActiveHints
  L3_2 = L3_2[L1_2]
  if not L3_2 then
    L3_2 = {}
  end
  L2_2[L1_2] = L3_2
  L2_2 = table
  L2_2 = L2_2.insert
  L3_2 = _tActiveHints
  L3_2 = L3_2[L1_2]
  L4_2 = A0_2
  L2_2(L3_2, L4_2)
  L2_2 = WifFreePlay
  L2_2 = L2_2.StartNag
  L2_2()
end

AddActiveHint = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = _FindSpeaker
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    return
  end
  L2_2 = _tActiveHints
  L2_2 = L2_2[L1_2]
  if not L2_2 then
    return
  end
  L2_2 = ipairs
  L3_2 = _tActiveHints
  L3_2 = L3_2[L1_2]
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    if L6_2 == A0_2 then
      L7_2 = table
      L7_2 = L7_2.remove
      L8_2 = _tActiveHints
      L8_2 = L8_2[L1_2]
      L9_2 = L5_2
      L7_2(L8_2, L9_2)
      L7_2 = table
      L7_2 = L7_2.getn
      L8_2 = _tActiveHints
      L8_2 = L8_2[L1_2]
      L7_2 = L7_2(L8_2)
      if L7_2 == 0 then
        L7_2 = _tActiveHints
        L7_2[L1_2] = nil
      end
      break
    end
  end
end

RemoveActiveHint = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  if A0_2 == nil then
    return
  end
  L1_2 = pairs
  L2_2 = _tHints
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L5_2[A0_2]
    if L6_2 then
      return L4_2
    end
  end
end

_FindSpeaker = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = _tHints
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    return
  end
  L1_2 = pairs
  L2_2 = _tHints
  L2_2 = L2_2[A0_2]
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = AddActiveHint
    L7_2 = L4_2
    L6_2(L7_2)
  end
end

UnlockAllHints = L0_1
L0_1 = {}
_tActiveHints = L0_1
L0_1 = {}
_tLastPlayed = L0_1
L0_1 = {}
L1_1 = {}
L2_1 = {}
L2_1.sCue = "Fiona.Hints.01"
L3_1 = {}
L4_1 = "All"
L5_1 = "Pmc"
L6_1 = "<="
L7_1 = "Hostile"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L3_1[4] = L7_1
L2_1.tFactionAttitudeConstraint = L3_1
L1_1.FionaHint01 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.02"
L1_1.FionaHint02 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.03"
L3_1 = {}
L4_1 = "All"
L5_1 = "Pmc"
L6_1 = "<="
L7_1 = "Hostile"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L3_1[4] = L7_1
L2_1.tFactionAttitudeConstraint = L3_1
L1_1.FionaHint03 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.04"
L1_1.FionaHint04 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.05"
L3_1 = {}
L4_1 = "Chi"
L5_1 = "Pmc"
L6_1 = "<="
L7_1 = "Hostile"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L3_1[4] = L7_1
L2_1.tFactionAttitudeConstraint = L3_1
L1_1.FionaHint05 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.06"
L1_1.FionaHint06 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.07"
L1_1.FionaHint07 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.08"
L3_1 = {}
L4_1 = "Chi"
L5_1 = "Pmc"
L6_1 = "<="
L7_1 = "Hostile"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L3_1[4] = L7_1
L2_1.tFactionAttitudeConstraint = L3_1
L1_1.FionaHint08 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.09"
L1_1.FionaHint09 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.10"
L1_1.FionaHint10 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.11"
L3_1 = {}
L4_1 = "Gur"
L5_1 = "Pmc"
L6_1 = "<="
L7_1 = "Hostile"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L3_1[4] = L7_1
L2_1.tFactionAttitudeConstraint = L3_1
L1_1.FionaHint11 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.12"
L1_1.FionaHint12 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.13"
L3_1 = {}
L4_1 = "Gur"
L5_1 = "Pmc"
L6_1 = ">="
L7_1 = "Friendly"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L3_1[4] = L7_1
L2_1.tFactionAttitudeConstraint = L3_1
L1_1.FionaHint13 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.14"
L3_1 = {}
L4_1 = "Gur"
L5_1 = "Pmc"
L6_1 = ">="
L7_1 = "Friendly"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L3_1[4] = L7_1
L2_1.tFactionAttitudeConstraint = L3_1
L1_1.FionaHint14 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.15"
L3_1 = {}
L4_1 = "Gur"
L5_1 = "Pmc"
L6_1 = "<="
L7_1 = "Hostile"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L3_1[4] = L7_1
L2_1.tFactionAttitudeConstraint = L3_1
L1_1.FionaHint15 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.16"
L1_1.FionaHint16 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.17"
L1_1.FionaHint17 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.18"
L1_1.FionaHint18 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.19"
L1_1.FionaHint19 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.20"
L1_1.FionaHint20 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.21"
L1_1.FionaHint21 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.22"
L3_1 = {}
L4_1 = "Oil"
L5_1 = "Pmc"
L6_1 = "<="
L7_1 = "Hostile"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L3_1[4] = L7_1
L2_1.tFactionAttitudeConstraint = L3_1
L1_1.FionaHint22 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.23"
L3_1 = {}
L4_1 = "Oil"
L5_1 = "Pmc"
L6_1 = ">="
L7_1 = "Friendly"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L3_1[4] = L7_1
L2_1.tFactionAttitudeConstraint = L3_1
L1_1.FionaHint23 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.24"
L3_1 = {}
L4_1 = "Oil"
L5_1 = "Pmc"
L6_1 = "<="
L7_1 = "Hostile"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L3_1[4] = L7_1
L2_1.tFactionAttitudeConstraint = L3_1
L1_1.FionaHint24 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.25"
L1_1.FionaHint25 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.26"
L1_1.FionaHint26 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.27"
L1_1.FionaHint27 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.28"
L1_1.FionaHint28 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.29"
L1_1.FionaHint29 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.30"
L1_1.FionaHint30 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.31"
L1_1.FionaHint31 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.32"
L1_1.FionaHint32 = L2_1
L2_1 = {}
L2_1.sCue = "Fiona.Hints.33"
L1_1.FionaHint33 = L2_1
L0_1.Fiona = L1_1
L1_1 = {}
L2_1 = {}
L2_1.sCue = "Ewan.Misc.Hints01"
L1_1.EwanHint01 = L2_1
L2_1 = {}
L2_1.sCue = "Ewan.Misc.Hints02"
L1_1.EwanHint02 = L2_1
L2_1 = {}
L2_1.sCue = "Ewan.Misc.Hints03"
L1_1.EwanHint03 = L2_1
L2_1 = {}
L2_1.sCue = "Ewan.Misc.Hints04"
L1_1.EwanHint04 = L2_1
L2_1 = {}
L2_1.sCue = "Ewan.Misc.Hints05"
L1_1.EwanHint05 = L2_1
L2_1 = {}
L2_1.sCue = "Ewan.Misc.Hints06"
L1_1.EwanHint06 = L2_1
L0_1.Ewan = L1_1
L1_1 = {}
L2_1 = {}
L2_1.sCue = "Eva.Misc.Hint01"
L1_1.EvaHint01 = L2_1
L2_1 = {}
L2_1.sCue = "Eva.Misc.Hint02"
L1_1.EvaHint02 = L2_1
L2_1 = {}
L2_1.sCue = "Eva.Misc.Hint03"
L1_1.EvaHint03 = L2_1
L2_1 = {}
L2_1.sCue = "Eva.Misc.Hint04"
L1_1.EvaHint04 = L2_1
L2_1 = {}
L2_1.sCue = "Eva.Misc.Hint05"
L1_1.EvaHint05 = L2_1
L2_1 = {}
L2_1.sCue = "Eva.Misc.Hint06"
L1_1.EvaHint06 = L2_1
L2_1 = {}
L2_1.sCue = "Eva.Misc.Hint08"
L1_1.EvaHint08 = L2_1
L0_1.Eva = L1_1
L1_1 = {}
L2_1 = {}
L2_1.sCue = "Misha.Misc.Hint01"
L1_1.MishaHint01 = L2_1
L2_1 = {}
L2_1.sCue = "Misha.Misc.Hint02"
L1_1.MishaHint02 = L2_1
L2_1 = {}
L2_1.sCue = "Misha.Misc.Hint03"
L1_1.MishaHint03 = L2_1
L2_1 = {}
L2_1.sCue = "Misha.Misc.Hint04"
L1_1.MishaHint04 = L2_1
L2_1 = {}
L2_1.sCue = "Misha.Misc.Hint05"
L1_1.MishaHint05 = L2_1
L2_1 = {}
L2_1.sCue = "Misha.Misc.Hint06"
L1_1.MishaHint06 = L2_1
L2_1 = {}
L2_1.sCue = "Misha.Misc.Hint07"
L1_1.MishaHint07 = L2_1
L2_1 = {}
L2_1.sCue = "Misha.Misc.Hint08"
L1_1.MishaHint08 = L2_1
L2_1 = {}
L2_1.sCue = "Misha.Misc.Hint09"
L1_1.MishaHint09 = L2_1
L2_1 = {}
L2_1.sCue = "Misha.Misc.Hint10"
L1_1.MishaHint10 = L2_1
L2_1 = {}
L2_1.sCue = "Misha.Misc.Hint11"
L1_1.MishaHint11 = L2_1
L2_1 = {}
L2_1.sCue = "Misha.Misc.Hint12"
L1_1.MishaHint12 = L2_1
L2_1 = {}
L2_1.sCue = "Misha.Misc.Hint13"
L1_1.MishaHint13 = L2_1
L2_1 = {}
L2_1.sCue = "Misha.Misc.Hint14"
L1_1.MishaHint14 = L2_1
L2_1 = {}
L2_1.sCue = "Misha.Misc.Hint15"
L1_1.MishaHint15 = L2_1
L2_1 = {}
L2_1.sCue = "Misha.Misc.Hint16"
L1_1.MishaHint16 = L2_1
L0_1.Misha = L1_1
_tHints = L0_1
