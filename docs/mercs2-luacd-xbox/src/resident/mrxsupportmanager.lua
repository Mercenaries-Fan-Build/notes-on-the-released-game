local L0_1, L1_1
L0_1 = import
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = {}
CurrentlyEquippedSupport = L0_1
L0_1 = CurrentlyEquippedSupport

function L1_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = Player
  L2_2 = L2_2.GetCharacter
  L3_2 = A1_2.uOwner
  L2_2 = L2_2(L3_2)
  A0_2[L2_2] = A1_2
end

L0_1.AddSupport = L1_1
L0_1 = {}
SupportQueue = L0_1
L0_1 = SupportQueue

function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L4_2 = A0_2[A1_2]
  if not L4_2 then
    L4_2 = {}
    A0_2[A1_2] = L4_2
  end
  L4_2 = A0_2[A1_2]
  L4_2 = L4_2[A2_2]
  if not L4_2 then
    L4_2 = A0_2[A1_2]
    L5_2 = {}
    L4_2[A2_2] = L5_2
  end
  L4_2 = false
  L5_2 = pairs
  L6_2 = A0_2[A1_2]
  L6_2 = L6_2[A2_2]
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    if L9_2 == A3_2 then
      L4_2 = true
    end
  end
  if not L4_2 then
    L5_2 = table
    L5_2 = L5_2.insert
    L6_2 = A0_2[A1_2]
    L6_2 = L6_2[A2_2]
    L7_2 = A3_2
    L5_2(L6_2, L7_2)
  end
end

L0_1.Add = L1_1
L0_1 = SupportQueue

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L3_2 = A0_2[A1_2]
  if not L3_2 then
    L4_2 = nil
    return L4_2
  end
  L4_2 = pairs
  L5_2 = L3_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2 in L4_2, L5_2, L6_2 do
    L8_2 = type
    L9_2 = L3_2[L7_2]
    L8_2 = L8_2(L9_2)
    if "table" == L8_2 then
      L8_2 = pairs
      L9_2 = L3_2[L7_2]
      L8_2, L9_2, L10_2 = L8_2(L9_2)
      for L11_2 in L8_2, L9_2, L10_2 do
        L12_2 = L3_2[L7_2]
        L12_2 = L12_2[L11_2]
        if L12_2 == A2_2 then
          return L7_2
        end
      end
    end
  end
  L4_2 = nil
  return L4_2
end

L0_1.GetSupport = L1_1
L0_1 = {}
ValidationQueue = L0_1
L0_1 = ValidationQueue

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2)
  local L7_2, L8_2, L9_2, L10_2
  L7_2 = {}
  L7_2.uPlayerGuid = A1_2
  L7_2.oSupport = A2_2
  L7_2.uDesignatorGuid = A3_2
  L7_2.nX = A4_2
  L7_2.nY = A5_2
  L7_2.nZ = A6_2
  L8_2 = table
  L8_2 = L8_2.insert
  L9_2 = A0_2
  L10_2 = L7_2
  L8_2(L9_2, L10_2)
  L8_2 = table
  L8_2 = L8_2.getn
  L9_2 = A0_2
  L8_2 = L8_2(L9_2)
  if L8_2 < 2 then
    L9_2 = A0_2
    L8_2 = A0_2._Process
    L8_2(L9_2)
  end
end

L0_1.Add = L1_1
L0_1 = ValidationQueue

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = A0_2[1]
  L2_2 = L1_2.oSupport
  L2_2 = L2_2.oDesignator
  L2_2 = L2_2.fValidationFunction
  L3_2 = _ValidationQueueCallback
  L4_2 = L1_2.nX
  L5_2 = L1_2.nY
  L6_2 = L1_2.nZ
  L7_2 = L1_2.oSupport
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end

L0_1._Process = L1_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = ValidationQueue
  L5_2 = L4_2
  L4_2 = L4_2._Callback
  L6_2 = A0_2
  L7_2 = A1_2
  L8_2 = A2_2
  L9_2 = A3_2
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
end

_ValidationQueueCallback = L0_1
L0_1 = ValidationQueue

function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L6_2 = table
  L6_2 = L6_2.getn
  L7_2 = A0_2
  L6_2 = L6_2(L7_2)
  if 0 < L6_2 then
    L5_2 = A0_2[1]
    L6_2 = table
    L6_2 = L6_2.remove
    L7_2 = A0_2
    L8_2 = 1
    L6_2(L7_2, L8_2)
  else
    L6_2 = nil
    return L6_2
  end
  if not A1_2 then
    L6_2 = Airstrike
    L6_2 = L6_2.RefillDesignator
    L7_2 = L5_2.oSupport
    L7_2 = L7_2.oDesignator
    L7_2 = L7_2.uWeaponGuid
    L6_2(L7_2)
    L6_2 = type
    L7_2 = A2_2
    L6_2 = L6_2(L7_2)
    if L6_2 == "string" then
      L6_2 = MrxSupport
      L6_2 = L6_2.DenialMessage
      L7_2 = A2_2
      L6_2(L7_2)
    else
      L6_2 = MrxSupport
      L6_2 = L6_2.DenialMessage
      L7_2 = "nodrop"
      L6_2(L7_2)
    end
    L6_2 = L5_2.oSupport
    L6_2 = L6_2.oDesignator
    L7_2 = L6_2
    L6_2 = L6_2.OnDeny
    L8_2 = L5_2.uDesignatorGuid
    L6_2(L7_2, L8_2)
  else
    L6_2 = L5_2.oSupport
    L7_2 = L6_2
    L6_2 = L6_2.GetDesignator
    L6_2 = L6_2(L7_2)
    L7_2 = L6_2
    L6_2 = L6_2.SetDesignationParameters
    L8_2 = A2_2
    L9_2 = A3_2
    L10_2 = A4_2
    L11_2 = L5_2.uDesignatorGuid
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
    L6_2 = CompleteDesignation
    L7_2 = L5_2.oSupport
    L8_2 = L5_2.uDesignatorGuid
    L9_2 = L5_2.uPlayerGuid
    L6_2(L7_2, L8_2, L9_2)
  end
  L6_2 = table
  L6_2 = L6_2.getn
  L7_2 = A0_2
  L6_2 = L6_2(L7_2)
  if 0 < L6_2 then
    L7_2 = A0_2
    L6_2 = A0_2._Process
    L6_2(L7_2)
  end
end

L0_1._Callback = L1_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  if not A2_2 then
    return
  end
  if not A0_2 then
    return
  end
  L3_2 = CurrentlyEquippedSupport
  L3_2 = L3_2[A2_2]
  if L3_2 then
    L3_2 = CurrentlyEquippedSupport
    L3_2 = L3_2[A2_2]
    if L3_2 == A0_2 then
      L3_2 = CurrentlyEquippedSupport
      L3_2[A2_2] = nil
      L3_2 = Airstrike
      L3_2 = L3_2.RemoveDesignator
      L4_2 = A2_2
      L3_2(L4_2)
  end
  else
    L3_2 = SupportQueue
    L3_2 = L3_2[A2_2]
    L3_2[A0_2] = nil
  end
  L3_2 = IsRecruitAvailable
  L5_2 = A0_2
  L4_2 = A0_2.GetRecruit
  L4_2, L5_2, L6_2, L7_2, L8_2 = L4_2(L5_2)
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  if not L3_2 then
    L3_2 = A0_2.oDesignator
    L4_2 = L3_2
    L3_2 = L3_2.OnDeny
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
    return
  end
  L4_2 = A0_2
  L3_2 = A0_2.GetFuelCost
  L3_2 = L3_2(L4_2)
  L4_2 = MrxPmc
  L4_2 = L4_2.GetFuelQty
  L4_2 = L4_2()
  if L3_2 > L4_2 then
    L3_2 = A0_2.bUnrestrictedByFuel
    if not L3_2 then
      L3_2 = A0_2.oDesignator
      L4_2 = L3_2
      L3_2 = L3_2.OnDeny
      L5_2 = A1_2
      L3_2(L4_2, L5_2)
      L3_2 = MrxSupport
      L3_2 = L3_2.DenialMessage
      L4_2 = "fuel"
      L3_2(L4_2)
      return
    end
  end
  L4_2 = A0_2
  L3_2 = A0_2.GetDesignator
  L3_2 = L3_2(L4_2)
  L4_2 = L3_2
  L3_2 = L3_2.SetDesignationParameters
  L5_2 = nil
  L6_2 = nil
  L7_2 = nil
  L8_2 = A1_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  L4_2 = A0_2
  L3_2 = A0_2.GetRecruit
  L3_2 = L3_2(L4_2)
  if L3_2 == "Copter" then
    L3_2 = StartRecruitCooldown
    L4_2 = "Copter"
    L5_2 = -1
    L3_2(L4_2, L5_2)
  else
    L3_2 = StartRecruitCooldown
    L5_2 = A0_2
    L4_2 = A0_2.GetRecruit
    L4_2, L5_2, L6_2, L7_2, L8_2 = L4_2(L5_2)
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  end
  L4_2 = A0_2
  L3_2 = A0_2.GetDesignator
  L3_2 = L3_2(L4_2)
  L4_2 = L3_2
  L3_2 = L3_2.CompleteDesignation
  L3_2(L4_2)
end

CompleteDesignation = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = A0_2
  L6_2 = "awake"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = FinishOnActivate
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
end

OnActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = Airstrike
  L2_2 = L2_2.FindDesignatorOwner
  if L2_2 then
    L2_2 = Airstrike
    L2_2 = L2_2.FindDesignatorOwner
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    L1_2 = L2_2
  end
  L2_2 = nil
  if L1_2 then
    L3_2 = CurrentlyEquippedSupport
    L2_2 = L3_2[L1_2]
  end
  if not L2_2 then
    return
  end
  L3_2 = SupportQueue
  L4_2 = L3_2
  L3_2 = L3_2.Add
  L5_2 = L1_2
  L6_2 = L2_2
  L7_2 = A0_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
end

FinishOnActivate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = OnActivate
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end

OnInitialize = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  if not A1_2 then
    return
  end
  L5_2 = Object
  L5_2 = L5_2.IsAttached
  L6_2 = A1_2
  L7_2 = A0_2
  L5_2 = L5_2(L6_2, L7_2)
  if L5_2 then
    L5_2 = Airstrike
    L5_2 = L5_2.RemoveDesignator
    L6_2 = A1_2
    L5_2(L6_2)
    return
  end
  L5_2 = type
  L6_2 = A4_2
  L5_2 = L5_2(L6_2)
  if "table" ~= L5_2 then
    L5_2 = type
    L6_2 = A4_2
    L5_2 = L5_2(L6_2)
    if "number" ~= L5_2 then
      goto lbl_27
    end
  end
  A4_2 = false
  ::lbl_27::
  L5_2 = type
  L6_2 = A3_2
  L5_2 = L5_2(L6_2)
  if "table" ~= L5_2 then
    L5_2 = type
    L6_2 = A3_2
    L5_2 = L5_2(L6_2)
    if "number" ~= L5_2 then
      goto lbl_38
    end
  end
  A3_2 = true
  ::lbl_38::
  L5_2 = type
  L6_2 = A2_2
  L5_2 = L5_2(L6_2)
  if "table" ~= L5_2 then
    L5_2 = type
    L6_2 = A2_2
    L5_2 = L5_2(L6_2)
    if "number" ~= L5_2 then
      goto lbl_49
    end
  end
  A2_2 = nil
  ::lbl_49::
  L5_2 = SupportQueue
  L6_2 = L5_2
  L5_2 = L5_2.GetSupport
  L7_2 = A1_2
  L8_2 = A0_2
  L5_2 = L5_2(L6_2, L7_2, L8_2)
  if not L5_2 then
    return
  end
  L7_2 = L5_2
  L6_2 = L5_2.GetDesignator
  L6_2 = L6_2(L7_2)
  L6_2 = L6_2.bDesignateOnDeath
  if not L6_2 and A4_2 then
    return
  end
  L6_2 = L5_2.oDesignator
  L6_2 = L6_2.bDesignated
  if L6_2 then
    return
  end
  L6_2 = L5_2.oDesignator
  L6_2.bDesignated = true
  L6_2 = Object
  L6_2 = L6_2.GetPosition
  L7_2 = A0_2
  L6_2, L7_2, L8_2 = L6_2(L7_2)
  L10_2 = L5_2
  L9_2 = L5_2.GetDesignator
  L9_2 = L9_2(L10_2)
  L10_2 = L9_2
  L9_2 = L9_2.SetDesignationParameters
  L11_2 = L6_2
  L12_2 = L7_2
  L13_2 = L8_2
  L14_2 = A0_2
  L15_2 = A2_2
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  L9_2 = L5_2.oDesignator
  if L9_2 then
    L9_2 = MrxSupport
    L9_2 = L9_2.TestAALevel
    L10_2 = L5_2.oDesignator
    L10_2 = L10_2.sAATestLevel
    L9_2 = L9_2(L10_2)
    if L9_2 then
      L9_2 = Airstrike
      L9_2 = L9_2.RefillDesignator
      L10_2 = L5_2.oDesignator
      L10_2 = L10_2.uWeaponGuid
      L9_2(L10_2)
      L9_2 = L5_2.oDesignator
      L10_2 = L9_2
      L9_2 = L9_2.OnDeny
      L11_2 = A0_2
      L9_2(L10_2, L11_2)
      L9_2 = MrxSupport
      L9_2 = L9_2.DenialMessage
      L10_2 = L5_2.oDesignator
      L10_2 = L10_2.sAATestLevel
      L9_2(L10_2)
      return
    end
  end
  L9_2 = L5_2.oDesignator
  if L9_2 then
    L9_2 = type
    L10_2 = L5_2.oDesignator
    L10_2 = L10_2.fValidationFunction
    L9_2 = L9_2(L10_2)
    if "function" == L9_2 then
      L9_2 = ValidationQueue
      L10_2 = L9_2
      L9_2 = L9_2.Add
      L11_2 = A1_2
      L12_2 = L5_2
      L13_2 = A0_2
      L14_2 = L6_2
      L15_2 = L7_2
      L16_2 = L8_2
      L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
  end
  else
    L9_2 = CompleteDesignation
    L10_2 = L5_2
    L11_2 = A0_2
    L12_2 = A1_2
    L9_2(L10_2, L11_2, L12_2)
  end
end

OnDesignate = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L5_2 = type
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  if "userdata" ~= L5_2 then
    A0_2 = nil
  end
  L5_2 = type
  L6_2 = A1_2
  L5_2 = L5_2(L6_2)
  if "userdata" ~= L5_2 then
    A1_2 = nil
  end
  L5_2 = OnDesignate
  L6_2 = A0_2
  L7_2 = A1_2
  L8_2 = A2_2
  L9_2 = A3_2
  L10_2 = A4_2
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
end

OnDeactivate = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L5_2 = type
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  if "userdata" ~= L5_2 then
    A0_2 = nil
  end
  L5_2 = type
  L6_2 = A1_2
  L5_2 = L5_2(L6_2)
  if "userdata" ~= L5_2 then
    A1_2 = nil
  end
  L5_2 = OnDesignate
  L6_2 = A0_2
  L7_2 = A1_2
  L8_2 = A2_2
  L9_2 = A3_2
  L10_2 = A4_2
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
end

OnTimer = L0_1

function L0_1(A0_2, A1_2)
end

OnDeath = L0_1
L0_1 = false
_tRecruitStates = L0_1
L0_1 = false
_tRecruitTimers = L0_1
L0_1 = 12
_nDefaultCooldownTime = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = String
  L1_2 = L1_2.GetHash
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = _tRecruitStates
  L2_2 = L2_2[L1_2]
  if nil == L2_2 then
    L2_2 = RegisterRecruit
    L3_2 = A0_2
    L2_2(L3_2)
  end
  L2_2 = _tRecruitStates
  L2_2 = L2_2[L1_2]
  return L2_2
end

IsRecruitAvailable = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = String
  L2_2 = L2_2.GetHash
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = _tRecruitStates
  L3_2 = L3_2[L2_2]
  if nil ~= L3_2 then
    if not A1_2 then
      A1_2 = _nDefaultCooldownTime
    end
    L3_2 = _tRecruitStates
    L3_2[L2_2] = false
    L3_2 = Net
    L3_2 = L3_2.SendCustomEvent
    L4_2 = "MrxSupportManager"
    L5_2 = NETEVENT_RECRUITSTATE
    L6_2 = {}
    L7_2 = A0_2
    L8_2 = 0
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L7_2 = true
    L3_2(L4_2, L5_2, L6_2, L7_2)
    if 0 < A1_2 then
      L3_2 = Net
      L3_2 = L3_2.SendCustomEvent
      L4_2 = "MrxSupportManager"
      L5_2 = NETEVENT_STARTTIMER
      L6_2 = {}
      L7_2 = A0_2
      L8_2 = A1_2
      L6_2[1] = L7_2
      L6_2[2] = L8_2
      L7_2 = true
      L3_2(L4_2, L5_2, L6_2, L7_2)
      L3_2 = _tRecruitTimers
      L3_2 = L3_2[L2_2]
      L5_2 = L3_2
      L4_2 = L3_2.SetTotalTime
      L6_2 = A1_2
      L4_2(L5_2, L6_2)
      L5_2 = L3_2
      L4_2 = L3_2.Reset
      L4_2(L5_2)
      L5_2 = L3_2
      L4_2 = L3_2.SetCallback
      L6_2 = MakeRecruitAvailable
      L7_2 = {}
      L8_2 = A0_2
      L7_2[1] = L8_2
      L4_2(L5_2, L6_2, L7_2)
      L5_2 = L3_2
      L4_2 = L3_2.Start
      L4_2(L5_2)
    end
    return A1_2
  end
  L3_2 = nil
  return L3_2
end

StartRecruitCooldown = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = String
  L1_2 = L1_2.GetHash
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = _tRecruitStates
  L2_2 = L2_2[L1_2]
  if nil == L2_2 then
    L2_2 = _tRecruitStates
    L2_2[L1_2] = true
    L2_2 = Net
    L2_2 = L2_2.SendCustomEvent
    L3_2 = "MrxSupportManager"
    L4_2 = NETEVENT_RECRUITSTATE
    L5_2 = {}
    L6_2 = A0_2
    L7_2 = 1
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L6_2 = true
    L2_2(L3_2, L4_2, L5_2, L6_2)
    L2_2 = _tRecruitTimers
    L3_2 = SupportTimer
    L4_2 = L3_2
    L3_2 = L3_2.Create
    L3_2 = L3_2(L4_2)
    L2_2[L1_2] = L3_2
  end
end

RegisterRecruit = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = String
  L1_2 = L1_2.GetHash
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = _tRecruitStates
  L2_2 = L2_2[L1_2]
  if nil ~= L2_2 then
    L2_2 = _tRecruitStates
    L2_2[L1_2] = true
    L2_2 = Net
    L2_2 = L2_2.SendCustomEvent
    L3_2 = "MrxSupportManager"
    L4_2 = NETEVENT_RECRUITSTATE
    L5_2 = {}
    L6_2 = A0_2
    L7_2 = 1
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L6_2 = true
    L2_2(L3_2, L4_2, L5_2, L6_2)
  end
  L2_2 = Event
  L2_2 = L2_2.Post
  L3_2 = "RecruitAvailable"
  L4_2 = {}
  L5_2 = A0_2
  L4_2[1] = L5_2
  L2_2(L3_2, L4_2)
end

MakeRecruitAvailable = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = String
  L1_2 = L1_2.GetHash
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = _tRecruitTimers
  L2_2 = L2_2[L1_2]
  if L2_2 then
    L2_2 = _tRecruitStates
    L2_2 = L2_2[L1_2]
    if false == L2_2 then
      L2_2 = _tRecruitTimers
      L2_2 = L2_2[L1_2]
      L2_2 = L2_2.oEventHandle
      if L2_2 then
        L2_2 = _tRecruitTimers
        L2_2 = L2_2[L1_2]
        L3_2 = L2_2
        L2_2 = L2_2.GetElapsedTime
        L2_2 = L2_2(L3_2)
        L3_2 = _tRecruitTimers
        L3_2 = L3_2[L1_2]
        L4_2 = L3_2
        L3_2 = L3_2.GetTotalTime
        L3_2, L4_2 = L3_2(L4_2)
        return L2_2, L3_2, L4_2
      else
        L2_2 = -2
        L3_2 = -1
        return L2_2, L3_2
      end
  end
  else
    L2_2 = nil
    L3_2 = nil
    return L2_2, L3_2
  end
end

GetRecruitTimes = L0_1
L0_1 = 0
NETEVENT_RECRUITSTATE = L0_1
L0_1 = 1
NETEVENT_STARTTIMER = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = NETEVENT_RECRUITSTATE
  if A0_2 == L2_2 then
    L2_2 = A1_2[1]
    L3_2 = _tRecruitStates
    L3_2 = L3_2[L2_2]
    if nil == L3_2 then
      L3_2 = _tRecruitTimers
      L4_2 = SupportTimer
      L5_2 = L4_2
      L4_2 = L4_2.Create
      L4_2 = L4_2(L5_2)
      L3_2[L2_2] = L4_2
    end
    L3_2 = A1_2[2]
    if L3_2 == 1 then
      L3_2 = _tRecruitStates
      L3_2[L2_2] = true
    else
      L3_2 = _tRecruitStates
      L3_2[L2_2] = false
    end
  else
    L2_2 = NETEVENT_STARTTIMER
    if A0_2 == L2_2 then
      L2_2 = A1_2[1]
      L3_2 = _tRecruitStates
      L3_2 = L3_2[L2_2]
      if nil == L3_2 then
        L3_2 = _tRecruitTimers
        L4_2 = SupportTimer
        L5_2 = L4_2
        L4_2 = L4_2.Create
        L4_2 = L4_2(L5_2)
        L3_2[L2_2] = L4_2
      end
      L3_2 = _tRecruitTimers
      L3_2 = L3_2[L2_2]
      L5_2 = L3_2
      L4_2 = L3_2.SetTotalTime
      L6_2 = A1_2[2]
      L4_2(L5_2, L6_2)
      L5_2 = L3_2
      L4_2 = L3_2.Reset
      L4_2(L5_2)
      L5_2 = L3_2
      L4_2 = L3_2.Start
      L4_2(L5_2)
    end
  end
end

NetEventCallback = L0_1
L0_1 = {}
L0_1.nElapsedTime = 0
L0_1.nTotalTime = 10
L0_1.oEventHandle = nil
L0_1.fCallback = nil
L1_1 = {}
L0_1.tCallbackData = L1_1
SupportTimer = L0_1
L0_1 = SupportTimer

function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = {}
  L1_2.nElapsedTime = 0
  L1_2.nTotalTime = 10
  L1_2.oEventHandle = nil
  L1_2.fCallback = nil
  L2_2 = {}
  L1_2.tCallbackData = L2_2
  NewTimer = L1_2
  L1_2 = setmetatable
  L2_2 = NewTimer
  L3_2 = A0_2
  L1_2(L2_2, L3_2)
  A0_2.__index = A0_2
  L1_2 = NewTimer
  return L1_2
end

L0_1.Create = L1_1
L0_1 = SupportTimer

function L1_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.Stop
  L1_2(L2_2)
end

L0_1.Delete = L1_1
L0_1 = SupportTimer

function L1_1(A0_2)
  local L1_2
  L1_2 = A0_2.nElapsedTime
  return L1_2
end

L0_1.GetElapsedTime = L1_1
L0_1 = SupportTimer

function L1_1(A0_2)
  local L1_2
  L1_2 = A0_2.nTotalTime
  return L1_2
end

L0_1.GetTotalTime = L1_1
L0_1 = SupportTimer

function L1_1(A0_2, A1_2)
  local L2_2
  L2_2 = A1_2 or nil
  if not A1_2 then
    L2_2 = A0_2.nTotalTime
  end
  A0_2.nTotalTime = L2_2
end

L0_1.SetTotalTime = L1_1
L0_1 = SupportTimer

function L1_1(A0_2)
  local L1_2
  A0_2.nElapsedTime = 0
end

L0_1.Reset = L1_1
L0_1 = SupportTimer

function L1_1(A0_2, A1_2, A2_2)
  local L3_2
  L3_2 = A1_2 or nil
  if not A1_2 then
    L3_2 = A0_2.fCallback
  end
  A0_2.fCallback = L3_2
  L3_2 = A2_2 or L3_2
  if not A2_2 then
    L3_2 = A0_2.tCallbackData
  end
  A0_2.tCallbackData = L3_2
end

L0_1.SetCallback = L1_1
L0_1 = SupportTimer

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = A0_2.oEventHandle
  if not L1_2 then
    L1_2 = A0_2.nElapsedTime
    L2_2 = A0_2.nTotalTime
    if L1_2 >= L2_2 then
      L2_2 = A0_2
      L1_2 = A0_2.Reset
      L1_2(L2_2)
    end
    L1_2 = Event
    L1_2 = L1_2.GuiGameTimer
    if L1_2 then
      L1_2 = Event
      L1_2 = L1_2.CreatePersistent
      L2_2 = Event
      L2_2 = L2_2.GuiGameTimer
      L3_2 = {}
      L4_2 = A0_2._EventCallback
      L5_2 = {}
      L6_2 = A0_2
      L5_2[1] = L6_2
      L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
      A0_2.oEventHandle = L1_2
    else
      L1_2 = Event
      L1_2 = L1_2.CreatePersistent
      L2_2 = Event
      L2_2 = L2_2.GuiUpdate
      L3_2 = {}
      L4_2 = A0_2._EventCallback
      L5_2 = {}
      L6_2 = A0_2
      L5_2[1] = L6_2
      L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
      A0_2.oEventHandle = L1_2
    end
  end
end

L0_1.Start = L1_1
L0_1 = SupportTimer

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2.oEventHandle
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2.oEventHandle
    L1_2(L2_2)
    A0_2.oEventHandle = nil
  end
end

L0_1.Stop = L1_1
L0_1 = SupportTimer

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2.nElapsedTime
  L2_2 = L2_2 + A1_2
  A0_2.nElapsedTime = L2_2
  L2_2 = A0_2.nElapsedTime
  L3_2 = A0_2.nTotalTime
  if L2_2 >= L3_2 then
    L3_2 = A0_2
    L2_2 = A0_2.Stop
    L2_2(L3_2)
    L2_2 = A0_2.fCallback
    if L2_2 then
      L2_2 = A0_2.tCallbackData
      if not L2_2 then
        L2_2 = {}
      end
      L3_2 = A0_2.fCallback
      L4_2 = unpack
      L5_2 = L2_2
      L4_2, L5_2 = L4_2(L5_2)
      L3_2(L4_2, L5_2)
    end
  end
end

L0_1._EventCallback = L1_1

function L0_1()
  local L0_2, L1_2
  L0_2 = {}
  _tRecruitStates = L0_2
  L0_2 = {}
  _tRecruitTimers = L0_2
end

Init = L0_1
