local L0_1, L1_1
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = 8
kiParkingLotLimit = L0_1
L0_1 = 6
kfTutorialTime = L0_1
L0_1 = 6
kiBlipSize = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = Event
  L0_2 = L0_2.CreatePersistent
  L1_2 = Event
  L1_2 = L1_2.ObjectInSeat
  L2_2 = {}
  L3_2 = Player
  L3_2 = L3_2.GetAnyCharacter
  L3_2 = L3_2()
  L4_2 = 0
  L5_2 = "d"
  L6_2 = "xo"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L3_2 = _TrackVehicle
  L0_2 = L0_2(L1_2, L2_2, L3_2)
  eParkingLotTracker = L0_2
  L0_2 = Event
  L0_2 = L0_2.CreatePersistent
  L1_2 = Event
  L1_2 = L1_2.ScriptEvent
  L2_2 = {}
  L3_2 = "parkingLotStart"
  
  function L4_2(A0_3)
    local L1_3
    L1_3 = true
    return L1_3
  end
  
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = _MoveVehicle
  L0_2 = L0_2(L1_2, L2_2, L3_2)
  eParkingLotTriggered = L0_2
  L0_2 = {}
  _tParkingLotCandidates = L0_2
end

Setup = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = Event
  L0_2 = L0_2.Delete
  L1_2 = eParkingLotTracker
  L0_2(L1_2)
  L0_2 = nil
  eParkingLotTracker = L0_2
  L0_2 = Event
  L0_2 = L0_2.Delete
  L1_2 = eParkingLotTriggered
  L0_2(L1_2)
  L0_2 = nil
  eParkingLotTriggered = L0_2
  L0_2 = _UnmarkVehicle
  L0_2()
  L0_2 = nil
  _tParkingLotCandidates = L0_2
end

Cleanup = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _UnmarkVehicle
  L0_2()
  L0_2 = _uNewParkingLotVeh
  if L0_2 then
    L0_2 = _MarkVehicle
    L1_2 = _uNewParkingLotVeh
    L0_2(L1_2)
    L0_2 = nil
    _uNewParkingLotVeh = L0_2
  end
end

MarkLastVehicle = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = Object
  L2_2 = L2_2.IsAlive
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = Object
    L2_2 = L2_2.HasLabel
    L3_2 = uVeh
    L4_2 = "Boat"
    L2_2 = L2_2(L3_2, L4_2)
    if not L2_2 then
      L2_2 = Object
      L2_2 = L2_2.HasLabel
      L3_2 = uVeh
      L4_2 = "Emplacedweapon"
      L2_2 = L2_2(L3_2, L4_2)
      if not L2_2 then
        goto lbl_22
      end
    end
    do return end
    ::lbl_22::
    L2_2 = ipairs
    L3_2 = _tParkingLotCandidates
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2, L6_2 in L2_2, L3_2, L4_2 do
      if L6_2 == A1_2 then
        L7_2 = table
        L7_2 = L7_2.remove
        L8_2 = _tParkingLotCandidates
        L9_2 = L5_2
        L7_2(L8_2, L9_2)
        break
      end
    end
    L2_2 = _tParkingLotCandidates
    L2_2 = #L2_2
    L3_2 = kiParkingLotLimit
    if L2_2 == L3_2 then
      L2_2 = table
      L2_2 = L2_2.remove
      L3_2 = _tParkingLotCandidates
      L2_2(L3_2)
    end
    L2_2 = table
    L2_2 = L2_2.insert
    L3_2 = _tParkingLotCandidates
    L4_2 = 1
    L5_2 = A1_2
    L2_2(L3_2, L4_2, L5_2)
  end
end

_TrackVehicle = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = A0_2[1]
  L2_2 = A0_2[2]
  L3_2 = A0_2[3]
  L4_2 = type
  L5_2 = L1_2
  L4_2 = L4_2(L5_2)
  if L4_2 == "userdata" then
    L4_2 = _GetLastVehicle
    L5_2 = L1_2
    L6_2 = L3_2
    L4_2 = L4_2(L5_2, L6_2)
    if L4_2 then
      L5_2 = nil
      L6_2 = Object
      L6_2 = L6_2.HasLabel
      L7_2 = L4_2
      L8_2 = "helicopter"
      L6_2 = L6_2(L7_2, L8_2)
      if L6_2 then
        L5_2 = L3_2
      else
        L5_2 = L2_2
      end
      L6_2 = MrxUtil
      L6_2 = L6_2.ClearVehiclesNearPoint
      L7_2 = L5_2
      L8_2 = L4_2
      L6_2(L7_2, L8_2)
      L6_2 = Object
      L6_2 = L6_2.SetTransformToObject
      L7_2 = L4_2
      L8_2 = L5_2
      L6_2(L7_2, L8_2)
      _uNewParkingLotVeh = L4_2
    end
  end
  L4_2 = pairs
  L5_2 = _tParkingLotCandidates
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = Object
    L9_2 = L9_2.Remove
    L10_2 = L8_2
    L9_2(L10_2)
    L9_2 = _tParkingLotCandidates
    L9_2[L7_2] = nil
  end
end

_MoveVehicle = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = ipairs
  L3_2 = _tParkingLotCandidates
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = Object
    L7_2 = L7_2.IsAlive
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    if L7_2 then
      L7_2 = Object
      L7_2 = L7_2.GetDistanceFrom
      L8_2 = L6_2
      L9_2 = A0_2
      L10_2 = true
      L7_2 = L7_2(L8_2, L9_2, L10_2)
      if not (L7_2 < 65) then
        L7_2 = Object
        L7_2 = L7_2.HasLabel
        L8_2 = L6_2
        L9_2 = "helicopter"
        L7_2 = L7_2(L8_2, L9_2)
        if not L7_2 then
          goto lbl_46
        end
        L7_2 = Object
        L7_2 = L7_2.GetDistanceFrom
        L8_2 = L6_2
        L9_2 = A1_2
        L10_2 = true
        L7_2 = L7_2(L8_2, L9_2, L10_2)
        if not (L7_2 < 15) then
          goto lbl_46
        end
      end
      L7_2 = Vehicle
      L7_2 = L7_2.GetDriver
      L8_2 = L6_2
      L7_2 = L7_2(L8_2)
      if L7_2 == nil then
        L7_2 = table
        L7_2 = L7_2.remove
        L8_2 = _tParkingLotCandidates
        L9_2 = L5_2
        return L7_2(L8_2, L9_2)
      end
    end
    ::lbl_46::
  end
end

_GetLastVehicle = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L1_2 = "HUD_PMC_Fiona"
  L2_2 = MrxUtil
  L2_2 = L2_2.GetPrimaryObjectiveRgb
  L2_2, L3_2, L4_2 = L2_2()
  L5_2 = Marker
  L5_2 = L5_2.AddBlip
  L6_2 = A0_2
  L7_2 = L1_2
  L8_2 = 32
  L9_2 = L2_2
  L10_2 = L3_2
  L11_2 = L4_2
  L12_2 = 255
  L13_2 = 1.25
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  _uWorldMarker = L5_2
  L5_2 = Net
  L5_2 = L5_2.IsServer
  L5_2 = L5_2()
  if L5_2 then
    L5_2 = Net
    L5_2 = L5_2.SendEvent_AddMarkerObjective
    L6_2 = A0_2
    L7_2 = _uWorldMarker
    L8_2 = L2_2
    L9_2 = L3_2
    L10_2 = L4_2
    L11_2 = 1.25
    L12_2 = MrxUtil
    L12_2 = L12_2.MarkerGetIndexByName_World
    L13_2 = L1_2
    L12_2 = L12_2(L13_2)
    L13_2 = 1
    L14_2 = 16
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  end
  L5_2 = "parkinglotVeh "
  L6_2 = Sys
  L6_2 = L6_2.GuidToString
  L7_2 = A0_2
  L6_2 = L6_2(L7_2)
  L5_2 = L5_2 .. L6_2
  L6_2 = Hud
  L6_2 = L6_2.Radar
  L7_2 = L6_2
  L6_2 = L6_2.AddObjective
  L8_2 = {}
  L8_2.sName = L5_2
  L8_2.uGuid = A0_2
  L8_2.nR = 255
  L8_2.nG = 255
  L8_2.nB = 255
  L9_2 = kiBlipSize
  L8_2.nWidth = L9_2
  L9_2 = kiBlipSize
  L8_2.nHeight = L9_2
  L8_2.sTexture = "MiniMap_Icon_Faction_PMC"
  L8_2.bSticky = true
  L6_2(L7_2, L8_2)
  L6_2 = kiBlipSize
  L6_2 = L6_2 * 1.2
  L7_2 = Hud
  L7_2 = L7_2.Radar
  L8_2 = L7_2
  L7_2 = L7_2.AnimateObjectiveSize
  L9_2 = {}
  L9_2.sName = L5_2
  L9_2.nMaxWidth = L6_2
  L9_2.nMaxHeight = L6_2
  L9_2.nSpeedWidth = 20
  L9_2.nSpeedHeight = 20
  L9_2.nDuration = 1.5
  L7_2(L8_2, L9_2)
  L7_2 = Event
  L7_2 = L7_2.Create
  L8_2 = Event
  L8_2 = L8_2.ObjectInSeat
  L9_2 = {}
  L10_2 = Player
  L10_2 = L10_2.GetAnyCharacter
  L10_2 = L10_2()
  L11_2 = A0_2
  L12_2 = "a"
  L13_2 = "ei"
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L9_2[3] = L12_2
  L9_2[4] = L13_2
  L10_2 = _UnmarkVehicle
  L7_2 = L7_2(L8_2, L9_2, L10_2)
  eMarkEnter = L7_2
  L7_2 = Event
  L7_2 = L7_2.Create
  L8_2 = Event
  L8_2 = L8_2.ObjectDeath
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L10_2 = _UnmarkVehicle
  L7_2 = L7_2(L8_2, L9_2, L10_2)
  eMarkDeath = L7_2
  L7_2 = Event
  L7_2 = L7_2.Create
  L8_2 = Event
  L8_2 = L8_2.ObjectHibernation
  L9_2 = {}
  L10_2 = A0_2
  L11_2 = "hibernated"
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L10_2 = _UnmarkVehicle
  L7_2 = L7_2(L8_2, L9_2, L10_2)
  eMarkHibernation = L7_2
  _uParkingLotVeh = A0_2
  L7_2 = _ShowTutorial1
  L7_2()
end

_MarkVehicle = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = type
  L1_2 = _uParkingLotVeh
  L0_2 = L0_2(L1_2)
  if L0_2 == "userdata" then
    L0_2 = Marker
    L0_2 = L0_2.Remove
    L1_2 = _uWorldMarker
    L0_2(L1_2)
    L0_2 = Net
    L0_2 = L0_2.IsServer
    L0_2 = L0_2()
    if L0_2 then
      L0_2 = Net
      L0_2 = L0_2.SendEvent_RemoveMarkerObjective
      L1_2 = _uWorldMarker
      L0_2(L1_2)
    end
    L0_2 = nil
    _uWorldMarker = L0_2
    L0_2 = Hud
    L0_2 = L0_2.Radar
    L1_2 = L0_2
    L0_2 = L0_2.RemoveObjective
    L2_2 = {}
    L3_2 = "parkinglotVeh "
    L4_2 = Sys
    L4_2 = L4_2.GuidToString
    L5_2 = _uParkingLotVeh
    L4_2 = L4_2(L5_2)
    L3_2 = L3_2 .. L4_2
    L2_2.sName = L3_2
    L0_2(L1_2, L2_2)
    L0_2 = Event
    L0_2 = L0_2.Delete
    L1_2 = eMarkEnter
    L0_2(L1_2)
    L0_2 = nil
    eMarkEnter = L0_2
    L0_2 = Event
    L0_2 = L0_2.Delete
    L1_2 = eMarkDeath
    L0_2(L1_2)
    L0_2 = nil
    eMarkDeath = L0_2
    L0_2 = Event
    L0_2 = L0_2.Delete
    L1_2 = eMarkHibernation
    L0_2(L1_2)
    L0_2 = nil
    eMarkHibernation = L0_2
    L0_2 = nil
    _uParkingLotVeh = L0_2
    L0_2 = _HideTutorial
    L0_2()
  end
end

_UnmarkVehicle = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = MrxTutorialManager
  L0_2 = L0_2.ShowMessage
  L1_2 = "[TUTORIAL.ParkingLot.First]"
  L2_2 = false
  L3_2 = "parkingLot"
  L0_2(L1_2, L2_2, L3_2)
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.TimerRelative
  L2_2 = {}
  L3_2 = kfTutorialTime
  L2_2[1] = L3_2
  L3_2 = _ShowTutorial2
  L0_2 = L0_2(L1_2, L2_2, L3_2)
  eTutorial = L0_2
end

_ShowTutorial1 = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = MrxTutorialManager
  L0_2 = L0_2.ShowMessage
  L1_2 = "[TUTORIAL.ParkingLot.Second]"
  L2_2 = false
  L3_2 = "parkingLot"
  L0_2(L1_2, L2_2, L3_2)
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.TimerRelative
  L2_2 = {}
  L3_2 = kfTutorialTime
  L2_2[1] = L3_2
  L3_2 = _HideTutorial
  L0_2 = L0_2(L1_2, L2_2, L3_2)
  eTutorial = L0_2
end

_ShowTutorial2 = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = MrxTutorialManager
  L0_2 = L0_2.HideMessage
  L1_2 = false
  L2_2 = "parkingLot"
  L0_2(L1_2, L2_2)
  L0_2 = Event
  L0_2 = L0_2.Delete
  L1_2 = eTutorial
  L0_2(L1_2)
  L0_2 = nil
  eTutorial = L0_2
end

_HideTutorial = L0_1
