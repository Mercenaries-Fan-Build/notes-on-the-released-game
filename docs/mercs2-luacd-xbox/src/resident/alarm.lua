local L0_1, L1_1
L0_1 = import
L1_1 = "DangerousBuilding"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)
L0_1 = tEvents
if not L0_1 then
  L0_1 = {}
end
tEvents = L0_1
L0_1 = {}
tLights = L0_1
L0_1 = 0
NETEVENT_ALARMACTIVATE = L0_1
L0_1 = 1
NETEVENT_ALARMDEACTIVATE = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = NETEVENT_ALARMACTIVATE
  if A0_2 == L2_2 then
    L2_2 = NetSafeAlarmActivated
    L3_2 = A1_2[1]
    L2_2(L3_2)
  else
    L2_2 = NETEVENT_ALARMDEACTIVATE
    if A0_2 == L2_2 then
      L2_2 = NetSafeAlarmDeactivated
      L3_2 = A1_2[1]
      L2_2(L3_2)
    end
  end
end

NetEventCallback = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = tEvents
  L3_2 = tEvents
  L3_2 = L3_2[A0_2]
  if not L3_2 then
    L3_2 = {}
  end
  L2_2[A0_2] = L3_2
  L2_2 = tLights
  L2_2[A0_2] = false
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = A0_2
  L6_2 = "awake"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = Vehicle
    L0_3 = L0_3.SetParts
    L1_3 = A0_2
    L2_3 = "LightFront"
    L3_3 = false
    L0_3 = L0_3(L1_3, L2_3, L3_3)
    bLightStart = L0_3
    L0_3 = SetupActivationEvents
    L1_3 = A0_2
    L0_3(L1_3)
  end
  
  L2_2(L3_2, L4_2, L5_2)
end

OnActivate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = tLights
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = Net
    L1_2 = L1_2.SendCustomEvent
    L2_2 = "Alarm"
    L3_2 = NETEVENT_ALARMACTIVATE
    L4_2 = {}
    L5_2 = A0_2
    L4_2[1] = L5_2
    L1_2(L2_2, L3_2, L4_2)
  end
end

SendPlayerJoinEventsAlarm = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = OnDeactivate
  L2_2 = A0_2
  L1_2(L2_2)
end

OnDeath = L0_1

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
  L1_2 = L1_2.uCheckEvent
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = tEvents
    L2_2 = L2_2[A0_2]
    L2_2 = L2_2.uCheckEvent
    L1_2(L2_2)
    L1_2 = tEvents
    L1_2 = L1_2[A0_2]
    L1_2.uCheckEvent = nil
  end
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
  L5_2 = Junk
  L5_2 = L5_2.ToggleAlarm
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.uActivate = L2_2
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  L1_2 = L1_2.uPlayerJoined
  if not L1_2 then
    L1_2 = tEvents
    L1_2 = L1_2[A0_2]
    L2_2 = Event
    L2_2 = L2_2.CreatePersistent
    L3_2 = Event
    L3_2 = L3_2.ScriptEvent
    L4_2 = {}
    L5_2 = "mpPlayerJoin"
    
    function L6_2(A0_3)
      local L1_3, L2_3
      L1_3 = Net
      L1_3 = L1_3.IsServer
      L1_3 = L1_3()
      if L1_3 then
        L1_3 = Player
        L1_3 = L1_3.IsLocal
        L2_3 = A0_3[1]
        L1_3 = L1_3(L2_3)
        L1_3 = not L1_3
      end
      return L1_3
    end
    
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L5_2 = SendPlayerJoinEventsAlarm
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
    L1_2.uPlayerJoined = L2_2
  end
end

SetupActivationEvents = L0_1

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

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  if A1_2 then
    L2_2 = AlarmActivated
    L3_2 = A0_2
    L2_2(L3_2)
  else
    L2_2 = AlarmDeactivated
    L3_2 = A0_2
    L2_2(L3_2)
  end
end

OnUse = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Sound
  L1_2 = L1_2.StopSound
  L2_2 = A0_2
  L3_2 = "fol_alarm_bldg_01"
  L1_2(L2_2, L3_2)
end

MuteAlarm = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  L2_2 = Event
  L2_2 = L2_2.CreatePersistent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 8
  L4_2[1] = L5_2
  L5_2 = CheckAlarm
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.uCheckEvent = L2_2
  L1_2 = Net
  L1_2 = L1_2.SendCustomEvent
  L2_2 = "Alarm"
  L3_2 = NETEVENT_ALARMACTIVATE
  L4_2 = {}
  L5_2 = A0_2
  L4_2[1] = L5_2
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = tLights
  L1_2[A0_2] = true
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  z = L3_2
  y = L2_2
  x = L1_2
  L1_2 = Pg
  L1_2 = L1_2.FastCollectBuildings
  L2_2 = x
  L3_2 = y
  L4_2 = z
  L5_2 = 100
  L6_2 = "Occupied"
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  tBuildings = L1_2
  L1_2 = DangerousBuilding
  L1_2 = L1_2.TurnOn
  L2_2 = tBuildings
  L3_2 = true
  L4_2 = false
  L5_2 = true
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = Sound
  L1_2 = L1_2.CueSound
  L2_2 = A0_2
  L3_2 = "fol_bldg_alarm_activate"
  L1_2(L2_2, L3_2)
  L1_2 = Sound
  L1_2 = L1_2.CueSound
  L2_2 = A0_2
  L3_2 = "fol_alarm_bldg_01"
  L1_2(L2_2, L3_2)
  L1_2 = Vehicle
  L1_2 = L1_2.SetParts
  L2_2 = A0_2
  L3_2 = "LightFront"
  L4_2 = true
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  bLight = L1_2
  L1_2 = Vehicle
  L1_2 = L1_2.SetParts
  L2_2 = A0_2
  L3_2 = "CtrlRotation"
  L4_2 = true
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  bCtrl = L1_2
  L1_2 = Pg
  L1_2 = L1_2.RemoveContextAction
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = SetupDeactivationEvents
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 60
  L3_2[1] = L4_2
  L4_2 = MuteAlarm
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.StartTutorial
  L2_2 = "Alarm"
  L1_2(L2_2)
end

AlarmActivated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = false
  L2_2 = Object
  L2_2 = L2_2.GetPosition
  L3_2 = A0_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  z = L4_2
  y = L3_2
  x = L2_2
  L2_2 = Pg
  L2_2 = L2_2.FastCollectBuildings
  L3_2 = x
  L4_2 = y
  L5_2 = z
  L6_2 = 100
  L7_2 = "Occupied"
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  tBuildings = L2_2
  L2_2 = pairs
  L3_2 = tBuildings
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = Object
    L7_2 = L7_2.IsAlive
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    if L7_2 then
      L1_2 = true
      break
    end
  end
  if not L1_2 then
    L2_2 = AlarmDeactivated
    L3_2 = A0_2
    L2_2(L3_2)
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = tEvents
    L3_2 = L3_2[A0_2]
    L3_2 = L3_2.uCheckEvent
    L2_2(L3_2)
    L2_2 = tEvents
    L2_2 = L2_2[A0_2]
    L2_2.uCheckEvent = nil
  end
end

CheckAlarm = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = tEvents
    L1_2 = L1_2[A0_2]
    L1_2 = L1_2.uCheckEvent
    if L1_2 then
      L1_2 = Event
      L1_2 = L1_2.Delete
      L2_2 = tEvents
      L2_2 = L2_2[A0_2]
      L2_2 = L2_2.uCheckEvent
      L1_2(L2_2)
    end
  end
  L1_2 = Net
  L1_2 = L1_2.SendCustomEvent
  L2_2 = "Alarm"
  L3_2 = NETEVENT_ALARMDEACTIVATE
  L4_2 = {}
  L5_2 = A0_2
  L4_2[1] = L5_2
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = tLights
  L1_2[A0_2] = false
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
  L1_2 = Vehicle
  L1_2 = L1_2.SetParts
  L2_2 = A0_2
  L3_2 = "LightFront"
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
  if L1_2 then
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
  end
end

AlarmDeactivated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.ObjectHibernation
  L3_2 = {}
  L4_2 = A0_2
  L5_2 = "awake"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = Object
    L0_3 = L0_3.GetPosition
    L1_3 = A0_2
    L0_3, L1_3, L2_3 = L0_3(L1_3)
    z = L2_3
    y = L1_3
    x = L0_3
    L0_3 = Pg
    L0_3 = L0_3.FastCollectBuildings
    L1_3 = x
    L2_3 = y
    L3_3 = z
    L4_3 = 100
    L5_3 = "Occupied"
    L0_3 = L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
    tBuildings = L0_3
    L0_3 = DangerousBuilding
    L0_3 = L0_3.TurnOn
    L1_3 = tBuildings
    L2_3 = true
    L3_3 = false
    L4_3 = true
    L0_3(L1_3, L2_3, L3_3, L4_3)
    L0_3 = Sound
    L0_3 = L0_3.CueSound
    L1_3 = A0_2
    L2_3 = "fol_bldg_alarm_activate"
    L0_3(L1_3, L2_3)
    L0_3 = Sound
    L0_3 = L0_3.CueSound
    L1_3 = A0_2
    L2_3 = "fol_alarm_bldg_01"
    L0_3(L1_3, L2_3)
    L0_3 = Vehicle
    L0_3 = L0_3.SetParts
    L1_3 = A0_2
    L2_3 = "LightFront"
    L3_3 = true
    L0_3 = L0_3(L1_3, L2_3, L3_3)
    bLight = L0_3
    L0_3 = Vehicle
    L0_3 = L0_3.SetParts
    L1_3 = A0_2
    L2_3 = "CtrlRotation"
    L3_3 = true
    L0_3 = L0_3(L1_3, L2_3, L3_3)
    bCtrl = L0_3
  end
  
  L1_2(L2_2, L3_2, L4_2)
end

NetSafeAlarmActivated = L0_1

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
  L1_2 = Vehicle
  L1_2 = L1_2.SetParts
  L2_2 = A0_2
  L3_2 = "LightFront"
  L4_2 = false
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Vehicle
  L1_2 = L1_2.SetParts
  L2_2 = A0_2
  L3_2 = "CtrlRotation"
  L4_2 = false
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = tEvents
  L1_2 = L1_2[A0_2]
  if L1_2 then
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
  end
end

NetSafeAlarmDeactivated = L0_1
