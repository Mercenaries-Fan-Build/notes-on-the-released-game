local L0_1, L1_1
L0_1 = {}
L1_1 = {}
L1_1.sModuleName = "WifTutorialSwimming"
L0_1.Swimming = L1_1
L1_1 = {}
L1_1.sModuleName = "WifTutorialWheeledVehicleBasic"
L0_1.WheeledVehicleBasic = L1_1
L1_1 = {}
L1_1.sModuleName = "WifTutorialBoat"
L0_1.Boats = L1_1
L1_1 = {}
L1_1.sModuleName = "WifTutorialTank"
L0_1.Tanks = L1_1
L1_1 = {}
L1_1.sModuleName = "WifTutorialHelicopter"
L0_1.Helicopters = L1_1
L1_1 = {}
L1_1.sModuleName = "WifTutorialC4"
L0_1.C4 = L1_1
L1_1 = {}
L1_1.sModuleName = "WifTutorialCollateralDamage"
L0_1.CollateralDamage = L1_1
L1_1 = {}
L1_1.sModuleName = "WifTutorialTrespass"
L0_1.Trespass = L1_1
L1_1 = {}
L1_1.sModuleName = "WifTutorialNoFuel"
L0_1.NoFuel = L1_1
L1_1 = {}
L1_1.sModuleName = "WifTutorialLowFuel"
L0_1.LowFuel = L1_1
L1_1 = {}
L1_1.sModuleName = "WifTutorialAlarm"
L0_1.Alarm = L1_1
L1_1 = {}
L1_1.sModuleName = "WifTutorialAirstrikeInterrupt"
L0_1.AirstrikeInterrupt = L1_1
L1_1 = {}
L1_1.sModuleName = "WifTutorialHeliRepairPad"
L0_1.HeliRepairPad = L1_1
L1_1 = {}
L1_1.sModuleName = "WifTutorialTankHijack"
L0_1.TankHijack = L1_1
L1_1 = {}
L1_1.sModuleName = "WifTutorialCoopTether"
L0_1.CoopTether = L1_1
L1_1 = {}
L1_1.sModuleName = "WifTutorialAPC"
L0_1.APC = L1_1
L1_1 = {}
L1_1.sModuleName = "WifTutorialVehicleDisguise"
L0_1.VehicleDisguise = L1_1
L1_1 = {}
L1_1.sModuleName = "WifTutorialCollectibles"
L0_1.Collectibles = L1_1
L1_1 = {}
L1_1.sModuleName = "WifTutorialGateHonk"
L0_1.GateHonk = L1_1
L1_1 = {}
L1_1.sModuleName = "WifTutorialC4Switch"
L0_1.C4Switch = L1_1
L1_1 = {}
L1_1.sModuleName = "WifTutorialAlliesHonk"
L0_1.AlliesHonk = L1_1
L1_1 = {}
L1_1.sModuleName = "WifTutorialCoopRevive"
L0_1.CoopRevive = L1_1
_tTutorials = L0_1
L0_1 = nil
_sCurrentActiveTutorial = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  _sCurrentActiveTutorial = L0_2
  L0_2 = pairs
  L1_2 = _tTutorials
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = L4_2.oTutorial
    if L5_2 then
      L5_2 = L4_2.oTutorial
      L6_2 = L5_2
      L5_2 = L5_2.DestroyEvents
      L5_2(L6_2)
    end
  end
  L0_2 = HideMessage
  L1_2 = true
  L0_2(L1_2)
end

Reset = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = Reset
  L0_2()
  L0_2 = pairs
  L1_2 = _tTutorials
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = L4_2.bComplete
    if not L5_2 then
      function L5_2(A0_3)
        local L1_3, L2_3, L3_3, L4_3
        
        L2_3 = A0_3
        L1_3 = A0_3.Create
        L3_3 = {}
        L4_3 = L3_2
        L3_3.sName = L4_3
        L1_3 = L1_3(L2_3, L3_3)
        L2_3 = L4_2
        L2_3.oTutorial = L1_3
        L3_3 = L1_3
        L2_3 = L1_3.SetupActivationCriteria
        L2_3(L3_3)
      end
      
      L6_2 = dynamic_import
      L7_2 = L4_2.sModuleName
      L8_2 = L5_2
      L6_2(L7_2, L8_2)
    end
  end
end

Setup = L0_1

function L0_1(A0_2, A1_2)
  local L2_2
  L2_2 = Sys
  L2_2 = L2_2.TutorialsEnabled
  L2_2 = L2_2()
  if L2_2 == false then
    return
  end
  L2_2 = _sCurrentActiveTutorial
  if L2_2 then
    return
  end
  _sCurrentActiveTutorial = A0_2
end

BeginCustomTutorial = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _sCurrentActiveTutorial
  if L2_2 then
    L2_2 = _sCurrentActiveTutorial
    if L2_2 ~= A0_2 then
      return
    end
  end
  L2_2 = HideMessage
  L3_2 = A1_2
  L4_2 = A0_2
  L2_2(L3_2, L4_2)
  L2_2 = nil
  _sCurrentActiveTutorial = L2_2
end

EndCustomTutorial = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = _tTutorials
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L2_2 = _tTutorials
    L2_2 = L2_2[A0_2]
    L2_2 = L2_2.bComplete
    if L2_2 then
      return
    end
  end
  L2_2 = _tTutorials
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L2_2 = _tTutorials
    L2_2 = L2_2[A0_2]
    L2_2 = L2_2.oTutorial
    if L2_2 then
      L2_2 = _tTutorials
      L2_2 = L2_2[A0_2]
      L2_2 = L2_2.oTutorial
      L3_2 = L2_2
      L2_2 = L2_2.ActivateTutorial
      L4_2 = A1_2
      L2_2(L3_2, L4_2)
    end
  end
end

StartTutorial = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = Sys
  L2_2 = L2_2.TutorialsEnabled
  L2_2 = L2_2()
  if L2_2 == false then
    L2_2 = false
    return L2_2
  end
  L3_2 = A0_2
  L2_2 = A0_2.GetName
  L2_2 = L2_2(L3_2)
  L3_2 = _bMessageDisplayed
  if L3_2 then
    L3_2 = false
    return L3_2
  end
  L3_2 = ShowMessage
  L5_2 = A0_2
  L4_2 = A0_2.GetMessage
  L4_2 = L4_2(L5_2)
  L5_2 = A1_2
  L6_2 = L2_2
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  return L3_2
end

SetCurrentTutorial = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  if A0_2 then
    L2_2 = _sCurrentActiveTutorial
    if L2_2 then
      L2_2 = _sCurrentActiveTutorial
      L4_2 = A0_2
      L3_2 = A0_2.GetName
      L3_2 = L3_2(L4_2)
      if L2_2 ~= L3_2 then
        L2_2 = false
        return L2_2
      end
    end
    L3_2 = A0_2
    L2_2 = A0_2.GetName
    L2_2 = L2_2(L3_2)
    L3_2 = nil
    _sCurrentActiveTutorial = L3_2
    L3_2 = ShowMessage
    L5_2 = A0_2
    L4_2 = A0_2.GetMessage
    L4_2 = L4_2(L5_2)
    L5_2 = A1_2
    L6_2 = L2_2
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    _sCurrentActiveTutorial = L2_2
    return L3_2
  else
    L2_2 = false
    return L2_2
  end
end

UpdateCurrentTutorial = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L4_2 = A0_2
  L3_2 = A0_2.GetName
  L3_2 = L3_2(L4_2)
  L4_2 = _sCurrentActiveTutorial
  if L4_2 then
    L4_2 = _sCurrentActiveTutorial
    if L3_2 ~= L4_2 then
      return
    end
  end
  L4_2 = HideMessage
  L5_2 = A2_2
  L6_2 = L3_2
  L4_2(L5_2, L6_2)
  L4_2 = nil
  _sCurrentActiveTutorial = L4_2
  L4_2 = _tTutorials
  L4_2 = L4_2[L3_2]
  L4_2.bComplete = A1_2
  L4_2 = true
  return L4_2
end

HideCurrentTutorial = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = _tTutorials
  L1_2 = L1_2[A0_2]
  L1_2 = L1_2.oTutorial
  return L1_2
end

GetTutorial = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2
  L1_2 = A0_2.GetName
  L1_2 = L1_2(L2_2)
  L2_2 = _tTutorials
  L2_2 = L2_2[L1_2]
  L3_2 = L2_2.sModuleName
  L4_2 = dynamic_remove
  L5_2 = L3_2
  L4_2(L5_2)
  A0_2 = nil
  L2_2.oTutorial = nil
end

DestroyTutorial = L0_1
L0_1 = nil
_sCurrentMessage = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = Net
  L3_2 = L3_2.IsServer
  L3_2 = L3_2()
  if L3_2 and not A1_2 then
    L3_2 = Net
    L3_2 = L3_2.SetTutorialMessage
    L4_2 = A0_2
    L3_2(L4_2)
  end
  L3_2 = Sys
  L3_2 = L3_2.TutorialsEnabled
  L3_2 = L3_2()
  if L3_2 == false then
    L3_2 = false
    return L3_2
  end
  L3_2 = _sCurrentMessage
  if L3_2 then
    L3_2 = _sCurrentMessage
    if L3_2 == A0_2 then
      L3_2 = false
      return L3_2
    end
  end
  L3_2 = _sCurrentActiveTutorial
  if L3_2 then
    L3_2 = _sCurrentActiveTutorial
    if A2_2 ~= L3_2 and A2_2 then
      L3_2 = false
      return L3_2
    end
  end
  _sCurrentActiveTutorial = A2_2
  L3_2 = Hud
  L3_2 = L3_2.Tutorial
  L4_2 = L3_2
  L3_2 = L3_2.SetText
  L5_2 = {}
  L6_2 = Player
  L6_2 = L6_2.GetLocalPlayer
  L6_2 = L6_2()
  L5_2.vPlayer = L6_2
  L5_2.sText = A0_2
  L3_2(L4_2, L5_2)
  L3_2 = true
  _bMessageDisplayed = L3_2
  _sCurrentMessage = A0_2
  L3_2 = true
  return L3_2
end

ShowMessage = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = _sCurrentActiveTutorial
  if L2_2 then
    L2_2 = _sCurrentActiveTutorial
    if L2_2 ~= A1_2 then
      return
    end
  end
  L2_2 = Net
  L2_2 = L2_2.IsServer
  L2_2 = L2_2()
  if L2_2 and not A0_2 then
    L2_2 = Net
    L2_2 = L2_2.SetTutorialMessage
    L2_2()
  end
  L2_2 = Hud
  L2_2 = L2_2.Tutorial
  L3_2 = L2_2
  L2_2 = L2_2.SetText
  L4_2 = {}
  L5_2 = Player
  L5_2 = L5_2.GetLocalPlayer
  L5_2 = L5_2()
  L4_2.vPlayer = L5_2
  L4_2.sText = nil
  L2_2(L3_2, L4_2)
  L2_2 = false
  _bMessageDisplayed = L2_2
  L2_2 = nil
  _sCurrentMessage = L2_2
  if not A1_2 then
    L2_2 = nil
    _sCurrentActiveTutorial = L2_2
  end
end

HideMessage = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = {}
  L1_2 = pairs
  L2_2 = _tTutorials
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L5_2.bComplete
    if L6_2 then
      L6_2 = table
      L6_2 = L6_2.insert
      L7_2 = L0_2
      L8_2 = L4_2
      L6_2(L7_2, L8_2)
    end
  end
  return L0_2
end

SaveSingleton = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = ipairs
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = _tTutorials
    L6_2 = L6_2[L5_2]
    if L6_2 then
      L6_2.bComplete = true
    end
  end
end

LoadSingleton = L0_1
