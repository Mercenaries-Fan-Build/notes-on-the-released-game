local L0_1, L1_1
L0_1 = import
L1_1 = "MrxSupport"
L0_1(L1_1)
L0_1 = tEvents
if not L0_1 then
  L0_1 = {}
end
tEvents = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
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

OnActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = tEvents
  if not L1_2 then
    L1_2 = {}
  end
  tEvents = L1_2
  L1_2 = tEvents
  L2_2 = tEvents
  L2_2 = L2_2[A0_2]
  if not L2_2 then
    L2_2 = {}
  end
  L1_2[A0_2] = L2_2
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  L1_2 = L1_2.uActivate
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = tEvents
    L2_2 = L2_2[A0_2]
    L2_2 = L2_2.uActivate
    L1_2(L2_2)
    L1_2 = tEvents
    L1_2 = L1_2[A0_2]
    L1_2.uActivate = nil
  end
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  L1_2 = L1_2.uDeactivate
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = tEvents
    L2_2 = L2_2[A0_2]
    L2_2 = L2_2.uDeactivate
    L1_2(L2_2)
    L1_2 = tEvents
    L1_2 = L1_2[A0_2]
    L1_2.uDeactivate = nil
  end
  L1_2 = tEvents
  L1_2[A0_2] = nil
end

OnDeactivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Object
  L1_2 = L1_2.PlayMaterialAnimation
  L2_2 = A0_2
  L3_2 = "global_gpsjammer_anim"
  L4_2 = false
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Vehicle
  L1_2 = L1_2.SetParts
  L2_2 = A0_2
  L3_2 = "CtrlRotation"
  L4_2 = false
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Pg
  L1_2 = L1_2.AddContextAction
  L2_2 = A0_2
  L3_2 = "[ContextAction.UseAlarm]"
  L1_2(L2_2, L3_2)
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ContextAction
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = A0_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = OnUse
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.uActivate = L2_2
end

SetupActivationEvents = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  L1_2 = L1_2.uActivate
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = tEvents
    L2_2 = L2_2[A0_2]
    L2_2 = L2_2.uActivate
    L1_2(L2_2)
    L1_2 = tEvents
    L1_2 = L1_2[A0_2]
    L1_2.uActivate = nil
  end
  L1_2 = AlarmActivated
  L2_2 = A0_2
  L1_2(L2_2)
end

OnUse = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Object
  L1_2 = L1_2.PlayMaterialAnimation
  L2_2 = A0_2
  L3_2 = "global_gpsjammer_anim"
  L4_2 = true
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Vehicle
  L1_2 = L1_2.SetParts
  L2_2 = A0_2
  L3_2 = "CtrlRotation"
  L4_2 = true
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Pg
  L1_2 = L1_2.RemoveContextAction
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = SetupDeactivationEvents
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = MrxSupport
  L1_2 = L1_2.AddAntiAir
  L2_2 = A0_2
  L3_2 = "jammer"
  L1_2(L2_2, L3_2)
end

AlarmActivated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Pg
  L1_2 = L1_2.AddContextAction
  L2_2 = A0_2
  L3_2 = "[ContextAction.UseAlarm]"
  L1_2(L2_2, L3_2)
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ContextAction
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = A0_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = AlarmDeactivated
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.uDeactivate = L2_2
end

SetupDeactivationEvents = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Sound
  L1_2 = L1_2.StopSound
  L2_2 = A0_2
  L3_2 = "fol_alarm_bldg_01"
  L1_2(L2_2, L3_2)
  L1_2 = Sound
  L1_2 = L1_2.CueSound
  L2_2 = A0_2
  L3_2 = "fol_bldg_alarm_activate"
  L1_2(L2_2, L3_2)
  L1_2 = Object
  L1_2 = L1_2.PlayMaterialAnimation
  L2_2 = A0_2
  L3_2 = "global_gpsjammer_anim"
  L4_2 = false
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Vehicle
  L1_2 = L1_2.SetParts
  L2_2 = A0_2
  L3_2 = "CtrlRotation"
  L4_2 = false
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Pg
  L1_2 = L1_2.RemoveContextAction
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = SetupActivationEvents
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  L1_2 = L1_2.uDeactivate
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = tEvents
    L2_2 = L2_2[A0_2]
    L2_2 = L2_2.uDeactivate
    L1_2(L2_2)
    L1_2 = tEvents
    L1_2 = L1_2[A0_2]
    L1_2.uDeactivate = nil
  end
  L1_2 = MrxSupport
  L1_2 = L1_2.RemoveAntiAir
  L2_2 = A0_2
  L3_2 = "jammer"
  L1_2(L2_2, L3_2)
end

AlarmDeactivated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxSupport
  L1_2 = L1_2.RemoveAntiAir
  L2_2 = A0_2
  L3_2 = "jammer"
  L1_2(L2_2, L3_2)
end

OnDeath = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = MrxSupport
  L1_2 = L1_2.RemoveAntiAir
  L2_2 = A0_2
  L3_2 = "jammer"
  L1_2(L2_2, L3_2)
end

OnDeactivate = L0_1
