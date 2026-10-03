local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = {}
L1_1 = "VZ"
L2_1 = "Allied"
L3_1 = "China"
L4_1 = "Guerilla"
L5_1 = "OC"
L6_1 = "Pirate"
L7_1 = "PMC"
L8_1 = "Civ"
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1
L0_1[5] = L5_1
L0_1[6] = L6_1
L0_1[7] = L7_1
L0_1[8] = L8_1

function L1_1()
  local L0_2, L1_2
end

Init = L1_1

function L1_1()
  local L0_2, L1_2
end

Deinit = L1_1
L1_1 = {}
_tLockedGates = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = Sys
  L2_2 = L2_2.GuidToString
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if A1_2 then
    L3_2 = _tLockedGates
    L3_2[L2_2] = true
  else
    L3_2 = _tLockedGates
    L3_2[L2_2] = nil
  end
  L3_2 = _tGates
  L3_2 = L3_2[A0_2]
  if L3_2 then
    L3_2 = _EvaluateCandidates
    L4_2 = A0_2
    L5_2 = nil
    L6_2 = nil
    L3_2(L4_2, L5_2, L6_2)
  end
end

LockGate = L1_1

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = Sys
  L1_2 = L1_2.GuidToString
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = _tLockedGates
  L2_2 = L2_2[L1_2]
  L2_2 = L2_2 == true
  return L2_2
end

IsGateLocked = L1_1
L1_1 = {}
_tGates = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.ObjectHibernation
  L3_2 = {}
  L4_2 = A0_2
  L5_2 = "awake"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L4_2 = Start
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

OnActivate = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 2
  L3_2[1] = L4_2
  
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = Vehicle
    L0_3 = L0_3.SetParts
    L1_3 = A0_2
    L2_3 = "LightFront"
    L3_3 = false
    L0_3(L1_3, L2_3, L3_3)
    L0_3 = Vehicle
    L0_3 = L0_3.SetParts
    L1_3 = A0_2
    L2_3 = "LightBrake"
    L3_3 = true
    L0_3(L1_3, L2_3, L3_3)
  end
  
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = _tGates
  L1_2 = L1_2[A0_2]
  if L1_2 then
    return
  end
  L1_2 = MrxUtil
  L1_2 = L1_2.GetFaction
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    return
  end
  L2_2 = ObjectFilter
  L2_2 = L2_2.Create
  L2_2 = L2_2()
  L3_2 = ObjectFilter
  L3_2 = L3_2.SetFilter
  L4_2 = L2_2
  L5_2 = "Hero||("
  L6_2 = L1_2
  L7_2 = "&&Vehicle)"
  L5_2 = L5_2 .. L6_2 .. L7_2
  L3_2(L4_2, L5_2)
  L3_2 = CreateProxEvent
  L4_2 = L2_2
  L5_2 = A0_2
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = MrxFactionManager
  L4_2 = L4_2.GetFactionAbbrev
  L5_2 = L1_2
  L4_2 = L4_2(L5_2)
  L5_2 = MrxFactionManager
  L5_2 = L5_2.CreatePersistentAttitudeChangeEvent
  L6_2 = {}
  L7_2 = L4_2
  L8_2 = "Pmc"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = _EvaluateCandidates
  L8_2 = {}
  L9_2 = A0_2
  L10_2 = nil
  L11_2 = nil
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L5_2 = L5_2(L6_2, L7_2, L8_2)
  L6_2 = _tGates
  L7_2 = {}
  L7_2.uNearEvent = L3_2
  L7_2.uAttitudeChangeEvent = L5_2
  L8_2 = {}
  L7_2.tCandidates = L8_2
  L7_2.uFilter = L2_2
  L6_2[A0_2] = L7_2
  L6_2 = _tGates
  L6_2 = L6_2[A0_2]
  L7_2 = Event
  L7_2 = L7_2.Create
  L8_2 = Event
  L8_2 = L8_2.ObjectHealth
  L9_2 = {}
  L10_2 = A0_2
  L11_2 = "piece1a_propattach00"
  L12_2 = "<"
  L13_2 = 1
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L9_2[3] = L12_2
  L9_2[4] = L13_2
  L10_2 = OnDeath
  L11_2 = {}
  L12_2 = A0_2
  L11_2[1] = L12_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
  L6_2.DeathA = L7_2
  L6_2 = _tGates
  L6_2 = L6_2[A0_2]
  L7_2 = Event
  L7_2 = L7_2.Create
  L8_2 = Event
  L8_2 = L8_2.ObjectHealth
  L9_2 = {}
  L10_2 = A0_2
  L11_2 = "piece1a_propattach01"
  L12_2 = "<"
  L13_2 = 1
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L9_2[3] = L12_2
  L9_2[4] = L13_2
  L10_2 = OnDeath
  L11_2 = {}
  L12_2 = A0_2
  L11_2[1] = L12_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
  L6_2.DeathB = L7_2
end

Start = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = OnDeactivate
  L3_2 = A0_2
  L2_2(L3_2)
end

OnDeath = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = Vehicle
  L1_2 = L1_2.SetParts
  L2_2 = A0_2
  L3_2 = "LightFront"
  L4_2 = false
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Vehicle
  L1_2 = L1_2.SetParts
  L2_2 = A0_2
  L3_2 = "LightBrake"
  L4_2 = false
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = _tGates
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    return
  end
  L2_2 = Event
  L2_2 = L2_2.Delete
  L3_2 = L1_2.uNearEvent
  L2_2(L3_2)
  L2_2 = Event
  L2_2 = L2_2.Delete
  L3_2 = L1_2.uAttitudeChangeEvent
  L2_2(L3_2)
  L2_2 = Event
  L2_2 = L2_2.Delete
  L3_2 = L1_2.DeathA
  L2_2(L3_2)
  L2_2 = Event
  L2_2 = L2_2.Delete
  L3_2 = L1_2.DeathB
  L2_2(L3_2)
  L1_2.uFilter = nil
  L2_2 = pairs
  L3_2 = L1_2.tCandidates
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2 in L2_2, L3_2, L4_2 do
    L6_2 = _RemoveCandidate
    L7_2 = A0_2
    L8_2 = L5_2
    L6_2(L7_2, L8_2)
  end
  L2_2 = _tGates
  L2_2[A0_2] = nil
end

OnDeactivate = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = A0_2
  L6_2 = A1_2
  L7_2 = "<"
  L8_2 = 20
  L9_2 = false
  L10_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L5_2 = _EvaluateCandidates
  L6_2 = {}
  L7_2 = A1_2
  L8_2 = true
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  return L2_2(L3_2, L4_2, L5_2, L6_2)
end

CreateProxEvent = L1_1

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L3_2 = _tGates
  L3_2 = L3_2[A0_2]
  if not L3_2 then
    return
  end
  if A1_2 then
    L3_2.uNearEvent = nil
  end
  L4_2 = L3_2.tCandidates
  L5_2 = MrxUtil
  L5_2 = L5_2.GetFaction
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  L6_2 = type
  L7_2 = A2_2
  L6_2 = L6_2(L7_2)
  if L6_2 == "userdata" then
    L6_2 = {}
    L7_2 = A2_2
    L6_2[1] = L7_2
    A2_2 = L6_2
  end
  if A2_2 then
    L6_2 = ipairs
    L7_2 = A2_2
    L6_2, L7_2, L8_2 = L6_2(L7_2)
    for L9_2, L10_2 in L6_2, L7_2, L8_2 do
      L11_2 = _RemoveCandidate
      L12_2 = A0_2
      L13_2 = L10_2
      L11_2(L12_2, L13_2)
      if A1_2 then
        L11_2 = true
        L12_2 = L3_2.uNearEvent
        if not L12_2 then
          L12_2 = CreateProxEvent
          L13_2 = L3_2.uFilter
          L14_2 = A0_2
          L12_2 = L12_2(L13_2, L14_2)
          L3_2.uNearEvent = L12_2
        end
        L12_2 = Player
        L12_2 = L12_2.GetPrimaryCharacter
        L12_2 = L12_2()
        if L10_2 ~= L12_2 then
          L12_2 = Player
          L12_2 = L12_2.GetSecondaryCharacter
          L12_2 = L12_2()
          if L10_2 ~= L12_2 then
            goto lbl_59
          end
        end
        L12_2 = _TestAttitude
        L13_2 = L5_2
        L14_2 = L10_2
        L12_2 = L12_2(L13_2, L14_2)
        L11_2 = L12_2
        ::lbl_59::
        if L11_2 then
          L12_2 = Event
          L12_2 = L12_2.Create
          L13_2 = Event
          L13_2 = L13_2.ObjectProximity
          L14_2 = {}
          L15_2 = L10_2
          L16_2 = A0_2
          L17_2 = ">"
          L18_2 = 40
          L19_2 = false
          L20_2 = false
          L14_2[1] = L15_2
          L14_2[2] = L16_2
          L14_2[3] = L17_2
          L14_2[4] = L18_2
          L14_2[5] = L19_2
          L14_2[6] = L20_2
          L15_2 = _EvaluateCandidates
          L16_2 = {}
          L17_2 = A0_2
          L18_2 = false
          L16_2[1] = L17_2
          L16_2[2] = L18_2
          L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2)
          L13_2 = Event
          L13_2 = L13_2.Create
          L14_2 = Event
          L14_2 = L14_2.ObjectDeath
          L15_2 = {}
          L16_2 = L10_2
          L15_2[1] = L16_2
          L16_2 = _EvaluateCandidates
          L17_2 = {}
          L18_2 = A0_2
          L19_2 = nil
          L20_2 = nil
          L17_2[1] = L18_2
          L17_2[2] = L19_2
          L17_2[3] = L20_2
          L13_2 = L13_2(L14_2, L15_2, L16_2, L17_2)
          L14_2 = {}
          L14_2.uFarEvent = L12_2
          L14_2.uDeathEvent = L13_2
          L4_2[L10_2] = L14_2
        end
      end
    end
  end
  L6_2 = 0
  L7_2 = pairs
  L8_2 = L4_2
  L7_2, L8_2, L9_2 = L7_2(L8_2)
  for L10_2 in L7_2, L8_2, L9_2 do
    L11_2 = true
    L12_2 = Player
    L12_2 = L12_2.GetPrimaryCharacter
    L12_2 = L12_2()
    if L10_2 ~= L12_2 then
      L12_2 = Player
      L12_2 = L12_2.GetSecondaryCharacter
      L12_2 = L12_2()
      if L10_2 ~= L12_2 then
        goto lbl_119
      end
    end
    L12_2 = _TestAttitude
    L13_2 = L5_2
    L14_2 = L10_2
    L12_2 = L12_2(L13_2, L14_2)
    L11_2 = L12_2
    ::lbl_119::
    if L11_2 then
      L12_2 = Object
      L12_2 = L12_2.IsAlive
      L13_2 = L10_2
      L12_2 = L12_2(L13_2)
      L11_2 = L12_2
    end
    if L11_2 then
      L6_2 = L6_2 + 1
    else
      L12_2 = _RemoveCandidate
      L13_2 = A0_2
      L14_2 = L10_2
      L12_2(L13_2, L14_2)
    end
  end
  L7_2 = 0 < L6_2
  if L7_2 then
    L8_2 = IsGateLocked
    L9_2 = A0_2
    L8_2 = L8_2(L9_2)
    L7_2 = not L8_2
  end
  L8_2 = _ChangeState
  L9_2 = A0_2
  L10_2 = L7_2
  L8_2(L9_2, L10_2)
end

_EvaluateCandidates = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = _tGates
  L2_2 = L2_2[A0_2]
  L3_2 = L2_2.tCandidates
  L4_2 = L3_2[A1_2]
  if L4_2 then
    L4_2 = Event
    L4_2 = L4_2.Delete
    L5_2 = L3_2[A1_2]
    L5_2 = L5_2.uFarEvent
    L4_2(L5_2)
    L4_2 = Event
    L4_2 = L4_2.Delete
    L5_2 = L3_2[A1_2]
    L5_2 = L5_2.uDeathEvent
    L4_2(L5_2)
    L3_2[A1_2] = nil
  end
end

_RemoveCandidate = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = _tGates
  L2_2 = L2_2[A0_2]
  L3_2 = L2_2.bOpen
  if L3_2 ~= A1_2 then
    L2_2.bOpen = A1_2
    if A1_2 then
      L3_2 = L2_2.bPlayedVO
      if not L3_2 then
        L2_2.bPlayedVO = true
        L3_2 = {}
        L3_2.Allied = "AlliedSoldier01.Misc.GateYes01"
        L3_2.China = "ChinaSoldier01.Misc.GateYes01"
        L3_2.Guerilla = "GurSoldier01.Misc.GateYes01"
        L3_2.OC = "OCSoldier01.Misc.GateYes01"
        L3_2.VZ = "GurSoldier01.Misc.GateYes01"
        L4_2 = Object
        L4_2 = L4_2.GetPosition
        L5_2 = A0_2
        L4_2, L5_2, L6_2 = L4_2(L5_2)
        L7_2 = MrxUtil
        L7_2 = L7_2.GetFaction
        L8_2 = A0_2
        L7_2 = L7_2(L8_2)
        L8_2 = Pg
        L8_2 = L8_2.FastCollectHumans
        L9_2 = L4_2
        L10_2 = L5_2
        L11_2 = L6_2
        L12_2 = 25
        L13_2 = L7_2
        L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
        tSoldiers = L8_2
        L8_2 = tSoldiers
        if L8_2 then
          L8_2 = tSoldiers
          L8_2 = L8_2[1]
          if L8_2 then
            L8_2 = Object
            L8_2 = L8_2.IsAlive
            L9_2 = tSoldiers
            L9_2 = L9_2[1]
            L8_2 = L8_2(L9_2)
            if L8_2 then
              L8_2 = L3_2[L7_2]
              if L8_2 then
                L8_2 = MrxVoSequence
                L8_2 = L8_2.Start
                L9_2 = {}
                L10_2 = {}
                L11_2 = L3_2[L7_2]
                L12_2 = tSoldiers
                L12_2 = L12_2[1]
                L10_2[1] = L11_2
                L10_2[2] = L12_2
                L9_2[1] = L10_2
                L10_2 = false
                L11_2 = MrxVoSequence
                L11_2 = L11_2.knPriorityFreeplay
                L8_2(L9_2, L10_2, L11_2)
              end
            end
          end
        end
      end
      L3_2 = Object
      L3_2 = L3_2.OpenGate
      L4_2 = A0_2
      L3_2(L4_2)
      L3_2 = Vehicle
      L3_2 = L3_2.SetParts
      L4_2 = A0_2
      L5_2 = "LightFront"
      L6_2 = true
      L3_2(L4_2, L5_2, L6_2)
      L3_2 = Vehicle
      L3_2 = L3_2.SetParts
      L4_2 = A0_2
      L5_2 = "LightBrake"
      L6_2 = false
      L3_2(L4_2, L5_2, L6_2)
    else
      L2_2.bPlayedVO = nil
      L3_2 = Object
      L3_2 = L3_2.CloseGate
      L4_2 = A0_2
      L3_2(L4_2)
      L3_2 = Vehicle
      L3_2 = L3_2.SetParts
      L4_2 = A0_2
      L5_2 = "LightFront"
      L6_2 = false
      L3_2(L4_2, L5_2, L6_2)
      L3_2 = Vehicle
      L3_2 = L3_2.SetParts
      L4_2 = A0_2
      L5_2 = "LightBrake"
      L6_2 = true
      L3_2(L4_2, L5_2, L6_2)
    end
  else
  end
end

_ChangeState = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = MrxFactionManager
  L2_2 = L2_2.GetFactionAbbrev
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = MrxFactionManager
  L3_2 = L3_2.GetPerceivedFaction
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = MrxFactionManager
  L4_2 = L4_2.GetFactionAbbrev
  L5_2 = L3_2
  L4_2 = L4_2(L5_2)
  L5_2 = true
  L6_2 = "Friendly"
  if L4_2 == "Pmc" then
    if L5_2 then
      L7_2 = MrxFactionManager
      L7_2 = L7_2.IsAttitudeMutable
      L8_2 = L2_2
      L7_2 = L7_2(L8_2)
      L5_2 = L7_2
    end
    L6_2 = "Neutral"
  end
  if L5_2 then
    L7_2 = MrxFactionManager
    L7_2 = L7_2.TestAttitude
    L8_2 = L2_2
    L9_2 = L4_2
    L10_2 = ">="
    L11_2 = L6_2
    L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
    L5_2 = L7_2
  end
  return L5_2
end

_TestAttitude = L1_1

function L1_1()
  local L0_2, L1_2
  L0_2 = _tLockedGates
  return L0_2
end

SaveSingleton = L1_1

function L1_1(A0_2)
  local L1_2
  if A0_2 then
    _tLockedGates = A0_2
  end
end

LoadSingleton = L1_1
