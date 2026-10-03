local L0_1, L1_1
L0_1 = tEvents
if not L0_1 then
  L0_1 = {}
end
tEvents = L0_1

function L0_1(A0_2, A1_2)
  return
end

OnActivate = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = Pg
  L2_2 = L2_2.LoadAsset
  L3_2 = "player_mattias_bare_technoviking"
  L4_2 = "animation"
  L2_2(L3_2, L4_2)
  L2_2 = true
  bAssetLoaded = L2_2
  L2_2 = tEvents
  L3_2 = tEvents
  L3_2 = L3_2[A0_2]
  if not L3_2 then
    L3_2 = {}
  end
  L2_2[A0_2] = L3_2
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = A0_2
  L6_2 = "awake"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = SetupActivationEvents
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
end

OnActivateOld = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = bAssetLoaded
  if L1_2 then
    L1_2 = Pg
    L1_2 = L1_2.UnloadAsset
    L2_2 = "player_mattias_bare_technoviking"
    L3_2 = "animation"
    L1_2(L2_2, L3_2)
    L1_2 = false
    bAssetLoaded = L1_2
  end
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = oEvent
  L1_2(L2_2)
  L1_2 = nil
  oEvent = L1_2
end

OnDeactivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Pg
  L1_2 = L1_2.AddContextAction
  L2_2 = A0_2
  L3_2 = "Dance"
  L4_2 = false
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.ContextAction
  L3_2 = {}
  L4_2 = "hero"
  L5_2 = A0_2
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L4_2 = OnUse
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  oEvent = L1_2
end

SetupActivationEvents = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = Player
  L2_2 = L2_2.GetPrimaryCharacter
  L2_2 = L2_2()
  if A0_2 == L2_2 then
    L2_2 = 1
    iPlayer = L2_2
  else
    L2_2 = Player
    L2_2 = L2_2.GetSecondaryCharacter
    L2_2 = L2_2()
    if A0_2 == L2_2 then
      L2_2 = 2
      iPlayer = L2_2
    end
  end
  L2_2 = Net
  L2_2 = L2_2.IsServer
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = Net
    L2_2 = L2_2.SendCustomEvent
    L3_2 = "DanceRadio"
    L4_2 = NETEVENT_STARTDANCING
    L5_2 = {}
    L6_2 = iPlayer
    L7_2 = A1_2
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L2_2(L3_2, L4_2, L5_2)
  end
  L2_2 = Pg
  L2_2 = L2_2.RemoveContextAction
  L3_2 = A1_2
  L2_2(L3_2)
  L2_2 = Human
  L2_2 = L2_2.DisableWeapons
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = Human
  L2_2 = L2_2.PlayRawAnimation
  L3_2 = A0_2
  L4_2 = "player_mattias_bare_technoviking"
  L5_2 = false
  L6_2 = false
  L7_2 = 0
  L8_2 = false
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 1
  L4_2[1] = L5_2
  L5_2 = Event
  L5_2 = L5_2.Create
  L6_2 = {}
  L7_2 = Event
  L7_2 = L7_2.HumanStateTransition
  L8_2 = {}
  L9_2 = A0_2
  L10_2 = "*"
  L11_2 = "*"
  L12_2 = "complete"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  L9_2 = Finished
  L10_2 = {}
  L11_2 = A1_2
  L12_2 = A0_2
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
end

OnUse = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = Human
  L2_2 = L2_2.EnableWeapons
  L3_2 = A1_2
  L2_2(L3_2)
  L2_2 = SetupActivationEvents
  L3_2 = A0_2
  L2_2(L3_2)
end

Finished = L0_1
L0_1 = 0
NETEVENT_STARTDANCING = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = NETEVENT_STARTDANCING
  if A0_2 == L2_2 then
    L2_2 = A1_2[1]
    if L2_2 == 1 then
      L2_2 = Player
      L2_2 = L2_2.GetPrimaryCharacter
      L2_2 = L2_2()
      uGuid = L2_2
    else
      L2_2 = A1_2[1]
      if L2_2 == 2 then
        L2_2 = Player
        L2_2 = L2_2.GetSecondaryCharacter
        L2_2 = L2_2()
        uGuid = L2_2
      end
    end
    L2_2 = OnUse
    L3_2 = uGuid
    L4_2 = A1_2[2]
    L2_2(L3_2, L4_2)
  end
end

NetEventCallback = L0_1
