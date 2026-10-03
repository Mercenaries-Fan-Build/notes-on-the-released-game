local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskJob"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiHudMessage"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSoundCategories"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxMusic"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = {}
  L3_2 = "vz_state_gua_upperclass_pristine"
  L4_2 = "Vz_State_MecJob"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = MrxLayerManager
  L3_2 = L3_2.Add
  L4_2 = L2_2
  L5_2 = A0_2.AssetsLoaded
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L3_2(L4_2, L5_2, L6_2)
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2._IssueAssetsLoadedCallbacks
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 2
  L4_2[1] = L5_2
  L5_2 = A0_2.Activated
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

AssetsLoaded = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = {}
  L2_2 = "Eva-In-Mission-Contract-Mech01-09"
  L3_2 = "Eva-In-Mission-Contract-Mech01-10"
  L4_2 = "Eva-In-Mission-Contract-Mech01-11"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  A0_2.tMsgWrongVeh = L1_2
  L1_2 = {}
  L2_2 = "Eva-In-Mission-Contract-Mech01-01"
  L3_2 = "Eva-In-Mission-Contract-Mech01-02"
  L4_2 = "Eva-In-Mission-Contract-Mech01-03"
  L5_2 = "Eva-In-Mission-Contract-Mech01-04"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  A0_2.tMsgLowHealth = L1_2
  A0_2.sMsgGarageDestroyed = "Fiona-In-Mission-Contract-Mech01-62"
  A0_2.sMsgExitGarage = "Eva-In-Mission-Contract-Mech01-61"
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "mechanicHQ.rgn.inside"
  L1_2 = L1_2(L2_2)
  A0_2.inRegion = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "mechanicHQ.rgn.outside"
  L1_2 = L1_2(L2_2)
  A0_2.outRegion = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "mechanicHQ"
  L1_2 = L1_2(L2_2)
  A0_2.garage = L1_2
  L1_2 = MrxTaskJob
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = "mc001.propVehicle"
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = Object
    L3_2 = L3_2.Remove
    L4_2 = L2_2
    L3_2(L4_2)
  end
  L3_2 = A0_2.sPropVehTemplate
  if L3_2 then
    L3_2 = MrxUtil
    L3_2 = L3_2.SpawnObject
    L4_2 = A0_2.sPropVehTemplate
    L5_2 = "meccon.loc.inprogress"
    L6_2 = L1_2
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2 = L3_2
  end
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.ObjectDeath
  L6_2 = {}
  L7_2 = A0_2.garage
  L6_2[1] = L7_2
  L7_2 = _GarageDestroyed
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  L4_2 = A0_2
  L3_2 = A0_2._PlayerOutside
  L3_2(L4_2)
  L4_2 = A0_2
  L3_2 = A0_2._SetupJob
  L3_2(L4_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = Sound
  L1_2 = L1_2.TransitionMusic
  L2_2 = "mission_success"
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = Object
  L1_2 = L1_2.GetLocalizedName
  L2_2 = Player
  L2_2 = L2_2.GetPrimaryCharacter
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L2_2()
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  L2_2 = nil
  L3_2 = Player
  L3_2 = L3_2.GetSecondaryCharacter
  L3_2 = L3_2()
  if L3_2 then
    L4_2 = Object
    L4_2 = L4_2.GetLocalizedName
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    L2_2 = L4_2
  end
  L5_2 = A0_2
  L4_2 = A0_2.GetConfig
  L4_2 = L4_2(L5_2)
  L5_2 = Hud
  L5_2 = L5_2.Fanfare
  L6_2 = L5_2
  L5_2 = L5_2.Create
  L7_2 = {}
  L7_2.sType = "mission"
  L7_2.sProfileName1 = L1_2
  L7_2.sProfileName2 = L2_2
  
  function L8_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = MrxSoundCategories
    L1_3 = L1_3.Fade
    L2_3 = "fanfare"
    L3_3 = false
    L1_3(L2_3, L3_3)
    L1_3 = MrxTaskMission
    L1_3 = L1_3.Complete
    L2_3 = A0_2
    L1_3(L2_3)
  end
  
  L7_2.fCallback = L8_2
  L5_2(L6_2, L7_2)
  L5_2 = MrxSoundCategories
  L5_2 = L5_2.Fade
  L6_2 = "fanfare"
  L7_2 = true
  L5_2(L6_2, L7_2)
  L5_2 = Hud
  L5_2 = L5_2.Fanfare
  L6_2 = L5_2
  L5_2 = L5_2.Commence
  L7_2 = {}
  L5_2(L6_2, L7_2)
end

Complete = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = MrxMusic
  L1_2 = L1_2.PlayFanfare
  L2_2 = false
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = Hud
  L2_2 = L2_2.Fanfare
  L3_2 = L2_2
  L2_2 = L2_2.Create
  L4_2 = {}
  L4_2.sType = "mission"
  L4_2.sProfileName1 = "unused"
  L5_2 = bRetryable
  L4_2.bAllowRetry = L5_2
  L5_2 = A0_2._sCancelMsg
  if not L5_2 then
    L5_2 = "[Fanfare.Cancel.Msg]"
  end
  L4_2.sCancelMsg = L5_2
  
  function L5_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = MrxSoundCategories
    L1_3 = L1_3.Fade
    L2_3 = "fanfare"
    L3_3 = false
    L1_3(L2_3, L3_3)
    L1_3 = MrxTaskMission
    L1_3 = L1_3.Cancel
    L2_3 = A0_2
    L1_3(L2_3)
    L1_3 = A0_2
    L2_3 = L1_3
    L1_3 = L1_3.GetParent
    L1_3 = L1_3(L2_3)
    L2_3 = L1_3
    L1_3 = L1_3.Cancel
    L1_3(L2_3)
  end
  
  L4_2.fCallback = L5_2
  L2_2(L3_2, L4_2)
  L2_2 = MrxSoundCategories
  L2_2 = L2_2.Fade
  L3_2 = "fanfare"
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = Hud
  L2_2 = L2_2.Fanfare
  L3_2 = L2_2
  L2_2 = L2_2.Commence
  L4_2 = {}
  L2_2(L3_2, L4_2)
end

Cancel = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = Object
  L1_2 = L1_2.CloseGate
  L2_2 = A0_2.garage
  L1_2(L2_2)
  L1_2 = A0_2.objFilterVehFound
  if L1_2 then
    A0_2.objFilterVehFound = nil
  end
  L1_2 = MrxTaskJob
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = MrxTaskMission
  L2_2 = L2_2.CreateChild
  L3_2 = A0_2
  L4_2 = A1_2
  return L2_2(L3_2, L4_2)
end

CreateChild = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = "MecJob: Deliver "
  L2_2 = A0_2.sVehLabel
  L1_2 = L1_2 .. L2_2
  L3_2 = A0_2
  L2_2 = A0_2.CreateChild
  L4_2 = {}
  L4_2.sName = L1_2
  L4_2.sModuleName = "MrxTaskObjectiveDeliver"
  L4_2.sTgtLabelFilter = "vehicle"
  L4_2.vDestLoc = "mechanicHQ_loc_delivery"
  L4_2.fDist = 3
  L4_2.bStop = true
  L4_2.bXZOnly = false
  L5_2 = A0_2.sObjText
  L4_2.sDspShortDesc = L5_2
  L4_2.bDspMsgUpd = false
  L4_2.bDisplayHelpText = true
  L4_2.bTrackOnActivate = false
  L4_2.nQuota = 1
  L5_2 = A0_2.sIntro
  L4_2.vVoSeqOnAdd = L5_2
  
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = A0_2
    L2_3 = L2_3.sMsgExitGarage
    L1_3[1] = L2_3
    L0_3(L1_3)
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._ExitGarage
    L0_3(L1_3)
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._DeliveryTargetDestroyedBeforeExitingEvent
    L0_3(L1_3)
  end
  
  L4_2.fOnComplete = L5_2
  
  function L5_2()
    local L0_3, L1_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.Cancel
    L0_3(L1_3)
  end
  
  L4_2.fOnCancel = L5_2
  
  function L5_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = A0_2
    L2_3 = L1_3
    L1_3 = L1_3._EvaluateDeliveryTarget
    L3_3 = A0_3
    return L1_3(L2_3, L3_3)
  end
  
  L4_2.fEvaluateTarget = L5_2
  L2_2(L3_2, L4_2)
  A0_2.sIntro = nil
end

_CreateDeliverObjective = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = _DisplayVehicleImg
  L2_2 = A0_2.sVehImg
  L3_2 = Player
  L3_2 = L3_2.GetPrimaryPlayer
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L3_2()
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  L1_2 = _DisplayVehicleImg
  L2_2 = A0_2.sVehImg
  L3_2 = Player
  L3_2 = L3_2.GetSecondaryPlayer
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L3_2()
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateDeliverObjective
  L1_2(L2_2)
  L1_2 = ObjectFilter
  L1_2 = L1_2.Create
  L1_2 = L1_2()
  L2_2 = ObjectFilter
  L2_2 = L2_2.SetFilter
  L3_2 = L1_2
  L4_2 = A0_2.sVehLabel
  L2_2(L3_2, L4_2)
  L3_2 = A0_2
  L2_2 = A0_2._CreateEvent
  L4_2 = Event
  L4_2 = L4_2.ObjectInSeat
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAnyCharacter
  L6_2 = L6_2()
  L7_2 = L1_2
  L8_2 = "a"
  L9_2 = "e"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L6_2 = _VehicleFound
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  A0_2.objFilterVehFound = L1_2
end

_SetupJob = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = false
  L3_2 = Vehicle
  L3_2 = L3_2.GetDriver
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L4_2 = Object
    L4_2 = L4_2.IsPlayerControlled
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    if not L4_2 then
      L4_2 = false
      return L4_2
    end
  end
  A0_2.uVehicle = A1_2
  L4_2 = Object
  L4_2 = L4_2.HasLabel
  L5_2 = A1_2
  L6_2 = A0_2.sVehLabel
  L4_2 = L4_2(L5_2, L6_2)
  if L4_2 then
    L4_2 = Object
    L4_2 = L4_2.GetHealth
    L5_2 = A1_2
    L4_2 = L4_2(L5_2)
    L5_2 = A0_2.iMinHealth
    if L4_2 >= L5_2 then
      L2_2 = true
    else
      L5_2 = A0_2
      L4_2 = A0_2._PlayRandomVO
      L6_2 = A0_2.tMsgLowHealth
      L4_2(L5_2, L6_2)
    end
  else
    L4_2 = A0_2.bFirstWrongVehWarning
    if not L4_2 then
      A0_2.bFirstWrongVehWarning = true
      L5_2 = A0_2
      L4_2 = A0_2._PlayOneVO
      L6_2 = A0_2.sWrongVeh
      L4_2(L5_2, L6_2)
    else
      L5_2 = A0_2
      L4_2 = A0_2._PlayRandomVO
      L6_2 = A0_2.tMsgWrongVeh
      L4_2(L5_2, L6_2)
    end
  end
  return L2_2
end

_EvaluateDeliveryTarget = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L2_2 = A0_2
  L1_2 = A0_2._PlayOneVO
  L3_2 = A0_2.sRightVeh
  L1_2(L2_2, L3_2)
end

_VehicleFound = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = A0_2.sMsgGarageDestroyed
  L4_2 = {}
  L5_2 = Cancel
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L1_2(L2_2)
end

_GarageDestroyed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = A0_2._tEvents
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = A0_2.uVehicle
  L4_2[1] = L5_2
  L5_2 = _DeliveryTargetDestroyedBeforeExiting
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.ePostDeliveryDestroyed = L2_2
end

_DeliveryTargetDestroyedBeforeExitingEvent = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2._tEvents
  L2_2 = L2_2.eDoorTrigger
  L1_2(L2_2)
  L1_2 = A0_2._tEvents
  L1_2.eDoorTrigger = nil
  L2_2 = A0_2
  L1_2 = A0_2._PlayRandomVO
  L3_2 = A0_2.tMsgLowHealth
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateDeliverObjective
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._PlayerInside
  L1_2(L2_2)
end

_DeliveryTargetDestroyedBeforeExiting = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = Object
  L1_2 = L1_2.CloseGate
  L2_2 = A0_2.garage
  L1_2(L2_2)
  L1_2 = A0_2.uVehicle
  if L1_2 then
    L1_2 = A0_2._tEvents
    L2_2 = Event
    L2_2 = L2_2.Create
    L3_2 = Event
    L3_2 = L3_2.ObjectPhysicsEvent
    L4_2 = {}
    L5_2 = A0_2.garage
    L6_2 = "gateFullyClosed"
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L5_2 = _CleanupVehicle
    L6_2 = {}
    L7_2 = A0_2
    L6_2[1] = L7_2
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
    L1_2.eCleanupCar = L2_2
  end
  L1_2 = A0_2._tEvents
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = A0_2.outRegion
  L7_2 = "enter"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = _PlayerInside
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.eDoorTrigger = L2_2
end

_PlayerOutside = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = Object
  L2_2 = L2_2.OpenGate
  L3_2 = A0_2.garage
  L2_2(L3_2)
  L2_2 = A0_2._tEvents
  L2_2 = L2_2.eCleanupCar
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = A0_2._tEvents
    L3_2 = L3_2.eCleanupCar
    L2_2(L3_2)
    L2_2 = A0_2._tEvents
    L2_2.eCleanupCar = nil
  end
  L2_2 = A0_2._tEvents
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.Boundary
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetAllCharacters
  L6_2 = L6_2()
  L7_2 = A0_2.outRegion
  L8_2 = "exit"
  L9_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L6_2 = _PlayerOutside
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2.eDoorTrigger = L3_2
end

_PlayerInside = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2._tEvents
  L2_2 = L2_2.eDoorTrigger
  L1_2(L2_2)
  L1_2 = A0_2._tEvents
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.Boundary
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAllCharacters
  L5_2 = L5_2()
  L6_2 = A0_2.outRegion
  L7_2 = "exit"
  L8_2 = false
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = _VehicleDelivered
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L1_2.eDoorTrigger = L2_2
end

_ExitGarage = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Object
  L1_2 = L1_2.IsAlive
  L2_2 = A0_2.uVehicle
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = Object
    L1_2 = L1_2.InsideBoundary
    L2_2 = A0_2.uVehicle
    L3_2 = A0_2.inRegion
    L1_2 = L1_2(L2_2, L3_2)
    if L1_2 then
      L1_2 = Object
      L1_2 = L1_2.CloseGate
      L2_2 = A0_2.garage
      L1_2(L2_2)
      
      function L1_2()
        local L0_3, L1_3
        L0_3 = A0_2
        L1_3 = L0_3
        L0_3 = L0_3.Complete
        L0_3(L1_3)
      end
      
      L2_2 = A0_2._tEvents
      L3_2 = Event
      L3_2 = L3_2.Create
      L4_2 = Event
      L4_2 = L4_2.ObjectPhysicsEvent
      L5_2 = {}
      L6_2 = A0_2.garage
      L7_2 = "gateFullyClosed"
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      L6_2 = _CleanupVehicle
      L7_2 = {}
      L8_2 = A0_2
      L9_2 = L1_2
      L7_2[1] = L8_2
      L7_2[2] = L9_2
      L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
      L2_2.eGateClosed = L3_2
      L2_2 = A0_2._tEvents
      L3_2 = Event
      L3_2 = L3_2.Create
      L4_2 = Event
      L4_2 = L4_2.ObjectPhysicsEvent
      L5_2 = {}
      L6_2 = A0_2.garage
      L7_2 = "gateStuck"
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      L6_2 = _CleanupVehicle
      L7_2 = {}
      L8_2 = A0_2
      L9_2 = L1_2
      L7_2[1] = L8_2
      L7_2[2] = L9_2
      L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
      L2_2.eGateStuck = L3_2
      L2_2 = A0_2._tEvents
      L3_2 = Event
      L3_2 = L3_2.Create
      L4_2 = Event
      L4_2 = L4_2.ScriptEvent
      L5_2 = {}
      L6_2 = "MedevacComplete"
      
      function L7_2(A0_3)
        local L1_3
        L1_3 = true
        return L1_3
      end
      
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      L6_2 = _CleanupVehicle
      L7_2 = {}
      L8_2 = A0_2
      L9_2 = L1_2
      L7_2[1] = L8_2
      L7_2[2] = L9_2
      L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
      L2_2.eMedevac = L3_2
  end
  else
    L2_2 = A0_2
    L1_2 = A0_2._CreateDeliverObjective
    L1_2(L2_2)
    L2_2 = A0_2
    L1_2 = A0_2._PlayerOutside
    L1_2(L2_2)
  end
end

_VehicleDelivered = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = Event
  L2_2 = L2_2.Delete
  L3_2 = A0_2._tEvents
  L3_2 = L3_2.eGateClosed
  L2_2(L3_2)
  L2_2 = Event
  L2_2 = L2_2.Delete
  L3_2 = A0_2._tEvents
  L3_2 = L3_2.eGateStuck
  L2_2(L3_2)
  L2_2 = Event
  L2_2 = L2_2.Delete
  L3_2 = A0_2._tEvents
  L3_2 = L3_2.eMedevac
  L2_2(L3_2)
  L2_2 = A0_2.uVehicle
  if L2_2 then
    L2_2 = Object
    L2_2 = L2_2.OutsideBoundary
    L3_2 = A0_2.uVehicle
    L4_2 = A0_2.inRegion
    L2_2 = L2_2(L3_2, L4_2)
    if L2_2 then
      L2_2 = false
      return L2_2
    end
    L2_2 = Vehicle
    L2_2 = L2_2.GetRiders
    L3_2 = A0_2.uVehicle
    L2_2 = L2_2(L3_2)
    L3_2 = pairs
    L4_2 = L2_2
    L3_2, L4_2, L5_2 = L3_2(L4_2)
    for L6_2, L7_2 in L3_2, L4_2, L5_2 do
      L8_2 = Object
      L8_2 = L8_2.IsPlayerControlled
      L9_2 = L7_2
      L8_2 = L8_2(L9_2)
      if L8_2 then
        L8_2 = false
        return L8_2
      end
    end
    L3_2 = Object
    L3_2 = L3_2.Remove
    L4_2 = A0_2.uVehicle
    L3_2(L4_2)
    A0_2.uVehicle = nil
  end
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if L2_2 == "function" then
    L2_2 = A1_2
    L2_2()
  end
  L2_2 = true
  return L2_2
end

_CleanupVehicle = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = math
  L2_2 = L2_2.randi
  L3_2 = table
  L3_2 = L3_2.getn
  L4_2 = A1_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  L4_2 = A0_2
  L3_2 = A0_2._PlayOneVO
  L5_2 = A1_2[L2_2]
  L3_2(L4_2, L5_2)
end

_PlayRandomVO = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2.bPlayingVO
  if not L2_2 then
    A0_2.bPlayingVO = true
    L2_2 = MrxVoSequence
    L2_2 = L2_2.Start
    L3_2 = {}
    L4_2 = A1_2
    
    function L5_2()
      local L0_3, L1_3
      L0_3 = A0_2
      L0_3.bPlayingVO = nil
    end
    
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L2_2(L3_2)
  end
end

_PlayOneVO = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = MrxGuiHudMessage
  L2_2 = L2_2.ShowMessage
  L3_2 = A1_2
  L4_2 = A0_2
  L5_2 = nil
  L6_2 = nil
  L7_2 = 320
  L8_2 = 240
  L9_2 = nil
  L10_2 = nil
  L11_2 = 224
  L12_2 = 224
  L13_2 = 4
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
end

_DisplayVehicleImg = L0_1
