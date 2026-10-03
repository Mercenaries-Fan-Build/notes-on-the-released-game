local L0_1, L1_1
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxHqManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxStarter"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifStarterData"
L0_1(L1_1)
L0_1 = {}
_tStarters = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = MrxFactionManager
  L0_2 = L0_2.CreatePersistentAttitudeChangeEvent
  L1_2 = {}
  L2_2 = nil
  L3_2 = "Pmc"
  L4_2 = nil
  L5_2 = nil
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  
  function L2_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = pairs
    L1_3 = _tStarters
    L0_3, L1_3, L2_3 = L0_3(L1_3)
    for L3_3, L4_3 in L0_3, L1_3, L2_3 do
      L6_3 = L4_3
      L5_3 = L4_3.RefreshBriefingRoomDisplay
      L5_3(L6_3)
    end
  end
  
  L0_2(L1_2, L2_2)
  L0_2 = MrxSupportData
  L0_2 = L0_2.SetHeliPilotRecruited
  L1_2 = false
  L0_2(L1_2)
  L0_2 = MrxSupportData
  L0_2 = L0_2.SetMechanicRecruited
  L1_2 = false
  L0_2(L1_2)
  L0_2 = MrxSupportData
  L0_2 = L0_2.SetJetPilotRecruited
  L1_2 = false
  L0_2(L1_2)
end

Init = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = _tStarters
  L1_2 = L1_2[A0_2]
  return L1_2
end

GetStarter = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _tStarters
  return L0_2
end

GetStarters = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = GetStarter
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    return L2_2
  else
    L3_2 = CreateStarter
    L4_2 = A0_2
    L5_2 = A1_2
    return L3_2(L4_2, L5_2)
  end
end

RequestStarter = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = WifStarterData
  L2_2 = L2_2[A0_2]
  L2_2.sName = A0_2
  L3_2 = MrxStarter
  L4_2 = L3_2
  L3_2 = L3_2.Create
  L5_2 = L2_2
  L3_2 = L3_2(L4_2, L5_2)
  if A1_2 then
    L5_2 = L3_2
    L4_2 = L3_2._SetFanfareDisplayed
    L6_2 = A1_2
    L4_2(L5_2, L6_2)
  end
  L5_2 = L3_2
  L4_2 = L3_2.Activate
  L4_2(L5_2)
  L4_2 = _tStarters
  L4_2[A0_2] = L3_2
  L4_2 = L2_2.bPmcStarter
  if L4_2 then
    if A0_2 == "HelPmcBoss" then
      L4_2 = MrxSupportData
      L4_2 = L4_2.SetHeliPilotRecruited
      L5_2 = true
      L4_2(L5_2)
    elseif A0_2 == "MecPmcBoss" then
      L4_2 = MrxSupportData
      L4_2 = L4_2.SetMechanicRecruited
      L5_2 = true
      L4_2(L5_2)
    elseif A0_2 == "JetPmcBoss" then
      L4_2 = MrxSupportData
      L4_2 = L4_2.SetJetPilotRecruited
      L5_2 = true
      L4_2(L5_2)
    end
  end
  return L3_2
end

CreateStarter = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = _tStarters
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L3_2 = L1_2
    L2_2 = L1_2.Deactivate
    L2_2(L3_2)
    L2_2 = _tStarters
    L2_2[A0_2] = nil
  end
end

DestroyStarter = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = pairs
  L1_2 = _tStarters
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L6_2 = L4_2
    L5_2 = L4_2.Deactivate
    L5_2(L6_2)
  end
  L0_2 = {}
  _tStarters = L0_2
end

DestroyAllStarters = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = 1
  L2_2 = ipairs
  L3_2 = WifStarterData
  L3_2 = L3_2._sStarters
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    if L6_2 == A0_2 then
      return L1_2
    end
    L1_2 = L1_2 + 1
  end
  L2_2 = nil
  return L2_2
end

GetStarterIndexFromName = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = 1
  L2_2 = ipairs
  L3_2 = WifStarterData
  L3_2 = L3_2._sStarters
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    if L1_2 == A0_2 then
      return L6_2
    end
    L1_2 = L1_2 + 1
  end
  L2_2 = nil
  return L2_2
end

GetStarterNameFromIndex = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = {}
  L1_2 = pairs
  L2_2 = _tStarters
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = {}
    L8_2 = L5_2
    L7_2 = L5_2.HasFanfareBeenDisplayed
    L7_2 = L7_2(L8_2)
    L6_2.bFanfareDisplayed = L7_2
    L8_2 = L5_2
    L7_2 = L5_2.HasCardBeenDisplayed
    L7_2 = L7_2(L8_2)
    L6_2.bCardDisplayed = L7_2
    L8_2 = L5_2
    L7_2 = L5_2.GetIntros
    L7_2 = L7_2(L8_2)
    L6_2.tIntros = L7_2
    L8_2 = L5_2
    L7_2 = L5_2.GetOldBriefings
    L7_2 = L7_2(L8_2)
    L6_2.tOldBriefings = L7_2
    L0_2[L4_2] = L6_2
  end
  return L0_2
end

SaveSingleton = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L1_2 = pairs
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = RequestStarter
    L7_2 = L4_2
    L8_2 = L5_2.bFanfareDisplayed
    L6_2 = L6_2(L7_2, L8_2)
    if L6_2 then
      L8_2 = L6_2
      L7_2 = L6_2._SetFanfareDisplayed
      L9_2 = L5_2.bFanfareDisplayed
      L7_2(L8_2, L9_2)
      L8_2 = L6_2
      L7_2 = L6_2._SetCardDisplayed
      L9_2 = L5_2.bCardDisplayed
      L7_2(L8_2, L9_2)
      L7_2 = L5_2.tIntros
      if L7_2 then
        L7_2 = pairs
        L8_2 = L5_2.tIntros
        L7_2, L8_2, L9_2 = L7_2(L8_2)
        for L10_2, L11_2 in L7_2, L8_2, L9_2 do
          if L11_2 == true then
            L13_2 = L6_2
            L12_2 = L6_2.AddIntro
            L14_2 = L10_2
            L12_2(L13_2, L14_2)
            L13_2 = L6_2
            L12_2 = L6_2.SetViewedIntro
            L14_2 = L10_2
            L15_2 = L11_2
            L12_2(L13_2, L14_2, L15_2)
          elseif L11_2 == false then
            L13_2 = L6_2
            L12_2 = L6_2.AddIntro
            L14_2 = L10_2
            L12_2(L13_2, L14_2)
          end
        end
      end
      L7_2 = L5_2.tOldBriefings
      if L7_2 then
        L7_2 = pairs
        L8_2 = L5_2.tOldBriefings
        L7_2, L8_2, L9_2 = L7_2(L8_2)
        for L10_2 in L7_2, L8_2, L9_2 do
          L12_2 = L6_2
          L11_2 = L6_2.SetBriefingOld
          L13_2 = L10_2
          L11_2(L12_2, L13_2)
        end
      end
    end
  end
end

LoadSingleton = L0_1
