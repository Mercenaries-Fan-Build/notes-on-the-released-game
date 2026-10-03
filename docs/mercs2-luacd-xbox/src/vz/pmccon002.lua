local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxState"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxCinematic"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "DangerousBuilding"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxLayerManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetLocalCharacter
  L5_2 = L5_2()
  L6_2 = "awake"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = Start
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Find Blanco"
  L3_2.sModuleName = "MrxTaskObjectiveAction"
  L3_2.sActionLabel = "[ContextAction.EnterOffice]"
  L3_2.vTgtInclude = "PMC002_Office"
  L3_2.sDspShortDesc = "[PmcCon002.objective.office]"
  L4_2 = {}
  L5_2 = {}
  L6_2 = PlayOfficeCinematic
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnPartComplete = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  oOfficeObjective = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "PMC002 Oilrig"
  L1_2 = L1_2(L2_2)
  uOilRig = L1_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "PmcCon002_OilrigA"
  L1_2 = L1_2(L2_2)
  uBuildingA = L1_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectHibernation
  L4_2 = {}
  L5_2 = uBuildingA
  L6_2 = "awake"
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L5_2 = SetupOfficeEvent
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetAnyCharacter
  L5_2 = L5_2()
  L6_2 = uBuildingA
  L7_2 = "<"
  L8_2 = 300
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = {}
  L7_2 = {}
  L8_2 = {}
  L8_2.mattias = "Mattias-In-Mission-Contract-Pmc02-25"
  L8_2.jennifer = "Jennifer-In-Mission-Contract-Pmc02-26"
  L8_2.chris = "Chris-In-Mission-Contract-Pmc02-27"
  L9_2 = 0.5
  L10_2 = "Fiona-In-Mission-Contract-Pmc02-28"
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectDeath
  L4_2 = {}
  L5_2 = uOilRig
  L4_2[1] = L5_2
  L5_2 = Failure
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = "rig"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  oRigDeath = L1_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-Banter-Contract-Pmc02-01"
  L4_2 = 0.5
  L5_2 = {}
  L5_2.mattias = "mattias-Banter-Contract-Pmc02-02"
  L5_2.jennifer = "jennifer-Banter-Contract-Pmc02-03"
  L5_2.chris = "chris-Banter-Contract-Pmc02-04"
  L6_2 = 0.5
  L7_2 = "Fiona-Banter-Contract-Pmc02-05"
  L8_2 = 1
  L9_2 = {}
  L9_2.mattias = "mattias-Banter-Contract-Pmc02-06"
  L9_2.jennifer = "jennifer-Banter-Contract-Pmc02-07"
  L9_2.chris = "chris-Banter-Contract-Pmc02-08"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L2_2[6] = L8_2
  L2_2[7] = L9_2
  L1_2(L2_2)
end

Start = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2
  L1_2 = A0_2._CreateEvent
  L3_2 = Event
  L3_2 = L3_2.ObjectHealth
  L4_2 = {}
  L5_2 = uBuildingA
  L6_2 = "floor02.piece1b"
  L7_2 = "<"
  L8_2 = 1
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = Failure
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = "rig"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  oOfficeDeath = L1_2
end

SetupOfficeEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  if A1_2 == "rig" then
    L2_2 = oOfficeObjective
    L3_2 = L2_2
    L2_2 = L2_2.Cancel
    L2_2(L3_2)
    L3_2 = A0_2
    L2_2 = A0_2.Cleanup
    L4_2 = true
    L2_2(L3_2, L4_2)
    L3_2 = A0_2
    L2_2 = A0_2._SetCancelMessage
    L4_2 = "[PmcCon002.objective.failed]"
    L2_2(L3_2, L4_2)
    L2_2 = MrxVoSequence
    L2_2 = L2_2.Start
    L3_2 = {}
    L4_2 = "Fiona-In-Mission-Contract-Pmc02-17"
    L5_2 = 0.5
    L6_2 = {}
    L6_2.mattias = "Mattias-In-Mission-Contract-Pmc02-19"
    L6_2.jennifer = "Jennifer-In-Mission-Contract-Pmc02-20"
    L6_2.chris = "Chris-In-Mission-Contract-Pmc02-21"
    L7_2 = {}
    L8_2 = A0_2.Cancel
    L9_2 = {}
    L10_2 = A0_2
    L9_2[1] = L10_2
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L3_2[4] = L7_2
    L2_2(L3_2)
  end
end

Failure = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = uMarker
  if L2_2 then
    L2_2 = Marker
    L2_2 = L2_2.Remove
    L3_2 = uMarker
    L2_2(L3_2)
    L2_2 = _G
    L2_2 = L2_2.Minimap
    L3_2 = L2_2
    L2_2 = L2_2.DeleteObjective
    L4_2 = "Enter office"
    L2_2(L3_2, L4_2)
  end
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "oilrig_alarm"
  L2_2 = L2_2(L3_2)
  L3_2 = Vehicle
  L3_2 = L3_2.SetParts
  L4_2 = L2_2
  L5_2 = "LightFront"
  L6_2 = true
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = Vehicle
  L3_2 = L3_2.SetParts
  L4_2 = L2_2
  L5_2 = "CtrlRotation"
  L6_2 = true
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = Sound
  L3_2 = L3_2.StopSound
  L4_2 = L2_2
  L5_2 = "fol_alarm_bldg_01"
  L3_2(L4_2, L5_2)
  L3_2 = Sound
  L3_2 = L3_2.StopSound
  L4_2 = uOilRig
  L5_2 = "fol_alarm_bldg_01"
  L3_2(L4_2, L5_2)
  L3_2 = Sound
  L3_2 = L3_2.StopSound
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "PmcCon002_OilrigD"
  L4_2 = L4_2(L5_2)
  L5_2 = "fol_alarm_bldg_01"
  L3_2(L4_2, L5_2)
  L3_2 = Sound
  L3_2 = L3_2.StopSound
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "PmcCon002_OilrigA"
  L4_2 = L4_2(L5_2)
  L5_2 = "fol_alarm_bldg_01"
  L3_2(L4_2, L5_2)
  L3_2 = Pg
  L3_2 = L3_2.RemoveContextAction
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "PMC002_Office"
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = uBlanco
  if L3_2 then
    L3_2 = Human
    L3_2 = L3_2.SetAllowCorpseCleanup
    L4_2 = uBlanco
    L5_2 = false
    L3_2(L4_2, L5_2)
    L3_2 = Pg
    L3_2 = L3_2.RemoveContextAction
    L4_2 = uBlanco
    L3_2(L4_2)
    L3_2 = Object
    L3_2 = L3_2.Remove
    L4_2 = uBlanco
    L3_2(L4_2)
  end
  if not A1_2 then
    L3_2 = MrxTaskContract
    L3_2 = L3_2.Cleanup
    L4_2 = A0_2
    L3_2(L4_2)
  end
end

Cleanup = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L3_2 = A0_2
  L2_2 = A0_2.Cleanup
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = Event
  L2_2 = L2_2.Delete
  L3_2 = oOfficeDeath
  L2_2(L3_2)
  
  function L2_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = MrxState
    L0_3 = L0_3.Exit
    L1_3 = MrxState
    L1_3 = L1_3.STATE_WAITFORGAME
    L2_3 = A0_2
    L2_3 = L2_3.SpawnBlanco
    L3_3 = {}
    L4_3 = A0_2
    L5_3 = A1_2
    L3_3[1] = L4_3
    L3_3[2] = L5_3
    L0_3(L1_3, L2_3, L3_3)
    L0_3 = Object
    L0_3 = L0_3.SetTransformToObject
    L1_3 = A1_2
    L2_3 = Pg
    L2_3 = L2_3.GetGuidByName
    L3_3 = "PmcCon002 Exit"
    L2_3, L3_3, L4_3, L5_3 = L2_3(L3_3)
    L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
    L0_3 = Event
    L0_3 = L0_3.Create
    L1_3 = Event
    L1_3 = L1_3.TimerRelative
    L2_3 = {}
    L3_3 = 0.6
    L2_3[1] = L3_3
    L3_3 = ExplodeHero
    L4_3 = {}
    L5_3 = A1_2
    L4_3[1] = L5_3
    L0_3(L1_3, L2_3, L3_3, L4_3)
  end
  
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = MrxUtil
    L0_3 = L0_3.GetCharacterIdentity
    L1_3 = A1_2
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L1_3 = string
      L1_3 = L1_3.upper
      L2_3 = string
      L2_3 = L2_3.sub
      L3_3 = L0_3
      L4_3 = 1
      L5_3 = 1
      L2_3, L3_3, L4_3, L5_3 = L2_3(L3_3, L4_3, L5_3)
      L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3)
      L0_3 = L1_3
    end
    if L0_3 ~= "M" and L0_3 ~= "J" and L0_3 ~= "C" then
      L0_3 = "M"
    end
    L1_3 = Hud
    L1_3 = L1_3.Cinematic
    L2_3 = L1_3
    L1_3 = L1_3.Show
    L3_3 = {}
    L4_3 = "10_BRV_"
    L5_3 = L0_3
    L4_3 = L4_3 .. L5_3
    L3_3.sMovie = L4_3
    L4_3 = L2_2
    L3_3.fCallback = L4_3
    L3_3.bSubtitles = true
    L1_3(L2_3, L3_3)
  end
  
  L4_2 = MrxState
  L4_2 = L4_2.Enter
  L5_2 = MrxState
  L5_2 = L5_2.STATE_WAITFORGAME
  L6_2 = L3_2
  L4_2(L5_2, L6_2)
end

PlayOfficeCinematic = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = Object
  L1_2 = L1_2.GetPosition
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "PmcCon002 Explosion"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L2_2(L3_2)
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  L4_2 = Pg
  L4_2 = L4_2.Spawn
  L5_2 = "Explosion (Force)"
  L6_2 = L1_2
  L7_2 = L2_2
  L8_2 = L3_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = Pg
  L4_2 = L4_2.Spawn
  L5_2 = "global_particle_explosion_c4"
  L6_2 = L1_2
  L7_2 = L2_2
  L8_2 = L3_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = 0.01
  L6_2[1] = L7_2
  
  function L7_2()
    local L0_3, L1_3, L2_3
    L0_3 = Human
    L0_3 = L0_3.Knockdown
    L1_3 = A0_2
    L2_3 = 0.5
    L0_3(L1_3, L2_3)
  end
  
  L4_2(L5_2, L6_2, L7_2)
end

ExplodeHero = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "oilrig_alarm"
  L2_2 = L2_2(L3_2)
  L3_2 = Vehicle
  L3_2 = L3_2.SetParts
  L4_2 = L2_2
  L5_2 = "LightFront"
  L6_2 = true
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = Vehicle
  L3_2 = L3_2.SetParts
  L4_2 = L2_2
  L5_2 = "CtrlRotation"
  L6_2 = true
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = Sound
  L3_2 = L3_2.CueSound
  L4_2 = L2_2
  L5_2 = "fol_alarm_bldg_01"
  L3_2(L4_2, L5_2)
  L3_2 = Sound
  L3_2 = L3_2.CueSound
  L4_2 = uOilRig
  L5_2 = "fol_alarm_bldg_01"
  L3_2(L4_2, L5_2)
  L3_2 = Sound
  L3_2 = L3_2.CueSound
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "PmcCon002_OilrigD"
  L4_2 = L4_2(L5_2)
  L5_2 = "fol_alarm_bldg_01"
  L3_2(L4_2, L5_2)
  L3_2 = Sound
  L3_2 = L3_2.CueSound
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = "PmcCon002_OilrigA"
  L4_2 = L4_2(L5_2)
  L5_2 = "fol_alarm_bldg_01"
  L3_2(L4_2, L5_2)
  L3_2 = DangerousBuilding
  L3_2 = L3_2.TurnOn
  L4_2 = {}
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = "PmcCon002_OilrigB"
  L5_2 = L5_2(L6_2)
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = "PmcCon002_OilrigC"
  L6_2 = L6_2(L7_2)
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = "PmcCon002_OilrigD"
  L7_2, L8_2 = L7_2(L8_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = true
  L3_2(L4_2, L5_2)
  L3_2 = Pg
  L3_2 = L3_2.SpawnFromCamera
  L4_2 = "Alouette3 Transport (VZ) (Pursuit)"
  L5_2 = 300
  L6_2 = 100
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = Pg
  L3_2 = L3_2.SpawnFromCamera
  L4_2 = "Alouette3 Transport (VZ) (Pursuit)"
  L5_2 = -300
  L6_2 = 100
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = MrxLayerManager
  L3_2 = L3_2.Add
  L4_2 = {}
  L5_2 = "VZ_state_PmcCon002_Blanco"
  L4_2[1] = L5_2
  L5_2 = RunBlancoRun
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = A1_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L3_2(L4_2, L5_2, L6_2)
end

SpawnBlanco = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = Event
  L2_2 = L2_2.Delete
  L3_2 = oRigDeath
  L2_2(L3_2)
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "PmcCon002 Blanco"
  L2_2 = L2_2(L3_2)
  L4_2 = A0_2
  L3_2 = A0_2.CreateChild
  L5_2 = {}
  L5_2.sName = "Verify Blanco"
  L5_2.sModuleName = "MrxTaskObjectiveVerify"
  L6_2 = {}
  L7_2 = L2_2
  L6_2[1] = L7_2
  L5_2.vTgtInclude = L6_2
  L5_2.sDspShortDesc = "[PmcCon002.objective.verifyblanco]"
  L5_2.sFactionId = "Gur"
  
  function L6_2()
    local L0_3, L1_3, L2_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._SetPlayer1Bonus
    L2_3 = 1000000
    L0_3(L1_3, L2_3)
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._SetPlayer2Bonus
    L2_3 = 1000000
    L0_3(L1_3, L2_3)
  end
  
  L5_2.fOnTargetCaptured = L6_2
  
  function L6_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.StopBlancoTaunt
    L0_3(L1_3)
    L0_3 = MrxVoSequence
    L0_3 = L0_3.Start
    L1_3 = {}
    L2_3 = {}
    L3_3 = "Blanco-In-Mission-Contract-Pmc02-37"
    L4_3 = L2_2
    L2_3[1] = L3_3
    L2_3[2] = L4_3
    L1_3[1] = L2_3
    L0_3(L1_3)
  end
  
  L5_2.fOnTargetSubdued = L6_2
  L6_2 = {}
  L7_2 = {}
  L8_2 = StopBlancoTaunt
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L6_2[1] = L7_2
  L5_2.tOnTargetDestroyed = L6_2
  L6_2 = {}
  L7_2 = {}
  L8_2 = StartDestroyRig
  L9_2 = {}
  L10_2 = A0_2
  L9_2[1] = L10_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L6_2[1] = L7_2
  L5_2.tOnComplete = L6_2
  L3_2 = L3_2(L4_2, L5_2)
  oVerifyBlanco = L3_2
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = math
  L7_2 = L7_2.randi
  L8_2 = 5
  L7_2 = L7_2(L8_2)
  L7_2 = L7_2 + 3
  L6_2[1] = L7_2
  L7_2 = PlayBlancoTaunt
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  oTauntTimer = L3_2
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = 1.5
  L6_2[1] = L7_2
  L7_2 = OKVO
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
end

RunBlancoRun = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = {}
  L3_2.mattias = "Fiona-In-Mission-Contract-Pmc02-09"
  L3_2.jennifer = "Fiona-In-Mission-Contract-Pmc02-10"
  L3_2.chris = "Fiona-In-Mission-Contract-Pmc02-11"
  L4_2 = 0.2
  L5_2 = {}
  L5_2.mattias = "mattias-In-Mission-Contract-Pmc02-12"
  L5_2.jennifer = "jennifer-In-Mission-Contract-Pmc02-13"
  L5_2.chris = "chris-In-Mission-Contract-Pmc02-14"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L1_2(L2_2)
end

OKVO = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = Pg
  L1_2 = L1_2.GetGuidByName
  L2_2 = "PmcCon002 Blanco"
  L1_2 = L1_2(L2_2)
  L2_2 = {}
  L3_2 = "Blanco-In-Mission-Contract-Pmc02-32"
  L4_2 = "Blanco-In-Mission-Contract-Pmc02-33"
  L5_2 = "Blanco-In-Mission-Contract-Pmc02-34"
  L6_2 = "Blanco-In-Mission-Contract-Pmc02-35"
  L7_2 = "Blanco-In-Mission-Contract-Pmc02-36"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L2_2[5] = L7_2
  L3_2 = MrxVoSequence
  L3_2 = L3_2.Start
  L4_2 = {}
  L5_2 = {}
  L6_2 = MrxUtil
  L6_2 = L6_2.GetRandomTableElement
  L7_2 = L2_2
  L6_2 = L6_2(L7_2)
  L7_2 = L1_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2(L4_2)
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = math
  L7_2 = L7_2.randi
  L8_2 = 8
  L7_2 = L7_2(L8_2)
  L7_2 = L7_2 + 5
  L6_2[1] = L7_2
  L7_2 = PlayBlancoTaunt
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  oTauntTimer = L3_2
end

PlayBlancoTaunt = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = oTauntTimer
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = oTauntTimer
    L1_2(L2_2)
  end
end

StopBlancoTaunt = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = Object
  L1_2 = L1_2.IsAlive
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "PMC002 Oilrig"
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  if not L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.Complete
    L1_2(L2_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2._PlayVo
  L3_2 = 0
  L4_2 = "Fiona-In-Mission-Contract-Pmc02-15"
  L1_2(L2_2, L3_2, L4_2)
  L2_2 = A0_2
  L1_2 = A0_2.CreateChild
  L3_2 = {}
  L3_2.sName = "Destroy oil rig"
  L3_2.sModuleName = "MrxTaskObjectiveDestroy"
  L4_2 = {}
  L5_2 = "PMC002 Oilrig"
  L4_2[1] = L5_2
  L3_2.vTgtInclude = L4_2
  L3_2.sDspShortDesc = "[PmcCon002.objective.destroyoilrig]"
  
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3._CreateEvent
    L2_3 = Event
    L2_3 = L2_3.TimerRelative
    L3_3 = {}
    L4_3 = 24
    L3_3[1] = L4_3
    L4_3 = RigIsDead
    L5_3 = {}
    L6_3 = A0_2
    L5_3[1] = L6_3
    L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
  end
  
  L3_2.fOnComplete = L4_2
  L4_2 = {}
  L5_2 = {}
  L6_2 = A0_2.Cancel
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2[1] = L5_2
  L3_2.tOnCancel = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  A0_2.DestroyRig = L1_2
end

StartDestroyRig = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = MrxLayerManager
  L1_2 = L1_2.MarkForRemoval
  L2_2 = "vz_state_mer_oilrig_pristine"
  L1_2(L2_2)
  L1_2 = MrxVoSequence
  L1_2 = L1_2.Start
  L2_2 = {}
  L3_2 = "Fiona-In-Mission-Contract-Pmc02-16"
  L4_2 = 1
  L5_2 = {}
  L6_2 = A0_2.Complete
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L1_2(L2_2)
end

RigIsDead = L0_1
