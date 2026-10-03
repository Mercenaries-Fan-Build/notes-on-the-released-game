local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
L1_1 = "Outpost"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxAchievements"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxStatsManager"
L0_1(L1_1)

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = A0_2
  L2_2 = A0_2.GetOutpostConfig
  L2_2 = L2_2(L3_2)
  L3_2 = {}
  L4_2 = L2_2.sPristineLayer
  if L4_2 then
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L3_2
    L6_2 = L2_2.sPristineLayer
    L4_2(L5_2, L6_2)
  end
  L4_2 = L2_2.sStagingLayer
  if L4_2 then
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L3_2
    L6_2 = L2_2.sStagingLayer
    L4_2(L5_2, L6_2)
  end
  L4_2 = L2_2.sDefenseLayer
  if L4_2 then
    L4_2 = table
    L4_2 = L4_2.insert
    L5_2 = L3_2
    L6_2 = L2_2.sDefenseLayer
    L4_2(L5_2, L6_2)
  end
  L4_2 = MrxLayerManager
  L4_2 = L4_2.Add
  L5_2 = L3_2
  L6_2 = A0_2.AssetsLoaded
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L4_2(L5_2, L6_2, L7_2)
end

LoadAssets = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L3_2 = A0_2
  L2_2 = A0_2.GetOutpostConfig
  L2_2 = L2_2(L3_2)
  L3_2 = Outpost
  L4_2 = L3_2
  L3_2 = L3_2.Create
  L5_2 = {}
  L6_2 = L2_2.sOutpostBldg
  L5_2.sOutpost = L6_2
  L6_2 = L2_2.sCapturePt
  L5_2.sBoundary = L6_2
  L6_2 = L2_2.tCapturePts
  L5_2.tCapturePts = L6_2
  L6_2 = MrxFactionManager
  L6_2 = L6_2.GetFactionTemplateName
  L7_2 = L2_2.sRivalFaction
  L6_2 = L6_2(L7_2)
  L5_2.sDefenders = L6_2
  L6_2 = MrxFactionManager
  L6_2 = L6_2.GetFactionTemplateName
  L7_2 = L1_2.sFactionId
  L6_2 = L6_2(L7_2)
  L5_2.sAttackers = L6_2
  L6_2 = L2_2.tDangerousBldgs
  L5_2.tDBSpawners = L6_2
  L6_2 = L2_2.nStartingHealth
  L5_2.nStartingHealth = L6_2
  L6_2 = L2_2.nRusherQuota
  L5_2.nRusherQuota = L6_2
  
  function L6_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = A0_2
    L0_3 = L0_3.bCompletedFirstTutorial
    if L0_3 == true then
      L0_3 = A0_2
      L0_3 = L0_3._UpdatedTimer
      if L0_3 then
        L0_3 = Event
        L0_3 = L0_3.Delete
        L1_3 = A0_2
        L1_3 = L1_3._UpdatedTimer
        L0_3(L1_3)
      end
      L0_3 = A0_2
      L1_3 = Event
      L1_3 = L1_3.Create
      L2_3 = Event
      L2_3 = L2_3.TimerRelative
      L3_3 = {}
      L4_3 = 6
      L3_3[1] = L4_3
      L4_3 = A0_2
      L4_3 = L4_3.NoProgressMade
      L5_3 = {}
      L6_3 = A0_2
      L5_3[1] = L6_3
      L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3)
      L0_3._UpdatedTimer = L1_3
      L0_3 = A0_2
      L0_3 = L0_3._ShowOutpostTutorial
      if L0_3 then
        L0_3 = MrxTutorialManager
        L0_3 = L0_3.HideMessage
        L1_3 = false
        L2_3 = "OutpostCapture"
        L0_3(L1_3, L2_3)
        L0_3 = Event
        L0_3 = L0_3.Delete
        L1_3 = A0_2
        L1_3 = L1_3._ShowOutpostTutorial
        L0_3(L1_3)
        L0_3 = A0_2
        L1_3 = Event
        L1_3 = L1_3.Create
        L2_3 = Event
        L2_3 = L2_3.TimerRelative
        L3_3 = {}
        L4_3 = 15
        L3_3[1] = L4_3
        L4_3 = A0_2
        L4_3 = L4_3.ShowOutpostTutorial
        L5_3 = {}
        L6_3 = A0_2
        L5_3[1] = L6_3
        L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3)
        L0_3._ShowOutpostTutorial = L1_3
      end
    end
  end
  
  L5_2.fUpdatedCallback = L6_2
  L3_2 = L3_2(L4_2, L5_2)
  _oOutpost = L3_2
  L4_2 = A0_2
  L3_2 = A0_2.CreateChild
  L5_2 = {}
  L5_2.sName = "Outpost"
  L5_2.sModuleName = "MrxTaskObjectiveCaptureOutpost"
  L6_2 = Pg
  L6_2 = L6_2.GetGuidByName
  L7_2 = L2_2.sOutpostBldg
  L6_2 = L6_2(L7_2)
  L5_2.uOutpostBldg = L6_2
  L6_2 = L2_2.tCapturePts
  L5_2.vTgtInclude = L6_2
  L6_2 = L2_2.sDspShortDesc
  if not L6_2 then
    L6_2 = "[Generic.ObjectiveOutpost]"
  end
  L5_2.sDspShortDesc = L6_2
  
  function L6_2()
    local L0_3, L1_3
    L0_3 = MrxStatsManager
    L0_3 = L0_3.IncreaseOutpostCapturedCounter
    L0_3()
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.Complete
    L0_3(L1_3)
  end
  
  L5_2.fOnComplete = L6_2
  
  function L6_2()
    local L0_3, L1_3, L2_3
    L0_3 = _oOutpost
    L0_3 = L0_3.bDestroyed
    if L0_3 then
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3._SetCancelMessage
      L2_3 = "[Fanfare.Cancel.OutpostDestroyed]"
      L0_3(L1_3, L2_3)
    end
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.Cancel
    L0_3(L1_3)
  end
  
  L5_2.fOnCancel = L6_2
  L3_2(L4_2, L5_2)
  L4_2 = A0_2
  L3_2 = A0_2._CreateEvent
  L5_2 = Event
  L5_2 = L5_2.ObjectProximity
  L6_2 = {}
  L7_2 = Player
  L7_2 = L7_2.GetAnyCharacter
  L7_2 = L7_2()
  L8_2 = Pg
  L8_2 = L8_2.GetGuidByName
  L9_2 = L2_2.sOutpostBldg
  L8_2 = L8_2(L9_2)
  L9_2 = "<"
  L10_2 = 100
  L11_2 = false
  L12_2 = false
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L6_2[5] = L11_2
  L6_2[6] = L12_2
  L7_2 = Near
  L8_2 = {}
  L9_2 = A0_2
  L8_2[1] = L9_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2._ShowOutpostTutorial
  if not L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.ShowOutpostTutorial
    L1_2(L2_2)
    A0_2.nTutorialText = 1
  end
end

NoProgressMade = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = RemoveTutorialEvents
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L3_2 = A0_2
  L2_2 = A0_2.GetOutpostConfig
  L2_2 = L2_2(L3_2)
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetLocalCharacter
  L6_2 = L6_2()
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = L2_2.sOutpostBldg
  L7_2 = L7_2(L8_2)
  L8_2 = ">"
  L9_2 = 100
  L10_2 = false
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = Far
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  A0_2._Far = L3_2
  L4_2 = A0_2
  L3_2 = A0_2.SetupTutorialTimers
  L3_2(L4_2)
end

Near = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  A0_2.nTutorialText = 1
  L2_2 = A0_2
  L1_2 = A0_2.ShowOutpostTutorial
  L1_2(L2_2)
end

SetupTutorialTimers = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.HideMessage
  L2_2 = false
  L3_2 = "OutpostCapture"
  L1_2(L2_2, L3_2)
  L1_2 = RemoveTutorialEvents
  L2_2 = A0_2
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L3_2 = A0_2
  L2_2 = A0_2.GetOutpostConfig
  L2_2 = L2_2(L3_2)
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectProximity
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetLocalCharacter
  L6_2 = L6_2()
  L7_2 = Pg
  L7_2 = L7_2.GetGuidByName
  L8_2 = L2_2.sOutpostBldg
  L7_2 = L7_2(L8_2)
  L8_2 = "<"
  L9_2 = 100
  L10_2 = false
  L11_2 = false
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L5_2[6] = L11_2
  L6_2 = Near
  L7_2 = {}
  L8_2 = A0_2
  L7_2[1] = L8_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  A0_2._Near = L3_2
end

Far = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = MrxFactionManager
  L2_2 = L2_2.GetShortPlayerVisibleName
  L3_2 = L1_2.sFactionId
  L2_2 = L2_2(L3_2)
  L3_2 = MrxFactionManager
  L3_2 = L3_2.GetAdjective
  L4_2 = L1_2.sFactionId
  L3_2 = L3_2(L4_2)
  L4_2 = MrxFactionManager
  L4_2 = L4_2.GetFactionTemplateName
  L5_2 = L1_2.sFactionId
  L4_2 = L4_2(L5_2)
  L5_2 = Outpost
  L5_2 = L5_2.GetFactionSupportName
  L6_2 = L4_2
  L5_2 = L5_2(L6_2)
  L6_2 = 6
  L7_2 = A0_2.nTutorialText
  if L7_2 == 1 then
    L7_2 = MrxTutorialManager
    L7_2 = L7_2.BeginCustomTutorial
    L8_2 = "OutpostCapture"
    L7_2(L8_2)
    L7_2 = MrxTutorialManager
    L7_2 = L7_2.ShowMessage
    L8_2 = "[Tutorial.OutpostCapture.Key1:"
    L9_2 = L2_2
    L10_2 = "]"
    L8_2 = L8_2 .. L9_2 .. L10_2
    L9_2 = false
    L10_2 = "OutpostCapture"
    L7_2(L8_2, L9_2, L10_2)
    L7_2 = A0_2.nTutorialText
    L7_2 = L7_2 + 1
    A0_2.nTutorialText = L7_2
  else
    L7_2 = A0_2.nTutorialText
    if L7_2 == 2 then
      L7_2 = MrxTutorialManager
      L7_2 = L7_2.ShowMessage
      L8_2 = "[Tutorial.OutpostCapture.Key2:"
      L9_2 = L3_2
      L10_2 = "]"
      L8_2 = L8_2 .. L9_2 .. L10_2
      L9_2 = false
      L10_2 = "OutpostCapture"
      L7_2(L8_2, L9_2, L10_2)
      L7_2 = A0_2.nTutorialText
      L7_2 = L7_2 + 1
      A0_2.nTutorialText = L7_2
    else
      L7_2 = A0_2.nTutorialText
      if L7_2 == 3 then
        L7_2 = MrxTutorialManager
        L7_2 = L7_2.ShowMessage
        L8_2 = "[Tutorial.OutpostCapture.Key3:"
        L9_2 = L5_2
        L10_2 = ":"
        L11_2 = L3_2
        L12_2 = "]"
        L8_2 = L8_2 .. L9_2 .. L10_2 .. L11_2 .. L12_2
        L9_2 = false
        L10_2 = "OutpostCapture"
        L7_2(L8_2, L9_2, L10_2)
        L7_2 = A0_2.nTutorialText
        L7_2 = L7_2 + 1
        A0_2.nTutorialText = L7_2
      else
        L7_2 = A0_2.nTutorialText
        if L7_2 == 4 then
          L7_2 = MrxTutorialManager
          L7_2 = L7_2.ShowMessage
          L8_2 = "[Tutorial.OutpostCapture.Key4]"
          L9_2 = false
          L10_2 = "OutpostCapture"
          L7_2(L8_2, L9_2, L10_2)
          L7_2 = A0_2.nTutorialText
          L7_2 = L7_2 + 1
          A0_2.nTutorialText = L7_2
        else
          L7_2 = MrxTutorialManager
          L7_2 = L7_2.EndCustomTutorial
          L8_2 = "OutpostCapture"
          L7_2(L8_2)
          L6_2 = 29
          A0_2.bCompletedFirstTutorial = true
          A0_2.nTutorialText = 1
        end
      end
    end
  end
  L7_2 = Event
  L7_2 = L7_2.Create
  L8_2 = Event
  L8_2 = L8_2.TimerRelative
  L9_2 = {}
  L10_2 = L6_2
  L9_2[1] = L10_2
  L10_2 = ShowOutpostTutorial
  L11_2 = {}
  L12_2 = A0_2
  L11_2[1] = L12_2
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
  A0_2._ShowOutpostTutorial = L7_2
end

ShowOutpostTutorial = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = _oOutpost
  if L1_2 then
    L1_2 = _oOutpost
    L1_2 = L1_2.bCaptured
    if not L1_2 then
      L1_2 = _oOutpost
      L1_2 = L1_2.bDestroyed
      if not L1_2 then
        L1_2 = _oOutpost
        L2_2 = L1_2
        L1_2 = L1_2.Captured
        L1_2(L2_2)
      end
    end
  end
  L2_2 = A0_2
  L1_2 = A0_2.GetOutpostConfig
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2.sStagingLayer
  if L2_2 then
    L2_2 = MrxLayerManager
    L2_2 = L2_2.MarkForRemoval
    L3_2 = L1_2.sStagingLayer
    L2_2(L3_2)
  end
  L2_2 = L1_2.sDefenseLayer
  if L2_2 then
    L2_2 = MrxLayerManager
    L2_2 = L2_2.MarkForRemoval
    L3_2 = L1_2.sDefenseLayer
    L2_2(L3_2)
  end
  L2_2 = L1_2.sCapturedLayer
  if L2_2 then
    L2_2 = MrxLayerManager
    L2_2 = L2_2.MarkForAddition
    L3_2 = L1_2.sCapturedLayer
    L2_2(L3_2)
  end
  L2_2 = MrxTaskContract
  L2_2 = L2_2.Complete
  L3_2 = A0_2
  L2_2(L3_2)
end

Complete = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2._ShowOutpostTutorial
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2._ShowOutpostTutorial
    L1_2(L2_2)
    A0_2._ShowOutpostTutorial = nil
  end
  L1_2 = A0_2._TutorialTimer
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2._TutorialTimer
    L1_2(L2_2)
    A0_2._TutorialTimer = nil
  end
  L1_2 = A0_2._Near
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2._Near
    L1_2(L2_2)
    A0_2._Near = nil
  end
  L1_2 = A0_2._Far
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2._Far
    L1_2(L2_2)
    A0_2._Far = nil
  end
  L1_2 = A0_2._UpdatedTimer
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2._UpdatedTimer
    L1_2(L2_2)
    A0_2._UpdatedTimer = nil
  end
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.HideMessage
  L2_2 = false
  L3_2 = "OutpostCapture"
  L1_2(L2_2, L3_2)
end

RemoveTutorialEvents = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = _oOutpost
  if L1_2 then
    L1_2 = _oOutpost
    L1_2 = L1_2.bCaptured
    if not L1_2 then
      L1_2 = _oOutpost
      L1_2 = L1_2.bDestroyed
      if not L1_2 then
        L1_2 = _oOutpost
        L2_2 = L1_2
        L1_2 = L1_2.Delete
        L1_2(L2_2)
      end
    end
  end
  L1_2 = RemoveTutorialEvents
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = MrxTaskContract
  L1_2 = L1_2.Cleanup
  L2_2 = A0_2
  L1_2(L2_2)
end

Cleanup = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2.tOutpostConfig
  return L2_2
end

GetOutpostConfig = L0_1
