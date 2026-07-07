local L0_1, L1_1, L2_1
L0_1 = import
L1_1 = "MrxUtil"
L2_1 = false
L0_1(L1_1, L2_1)

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = {}
  L2_2 = {}
  L3_2 = "monster truck"
  L4_2 = 80
  L5_2 = 10
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L3_2 = {}
  L4_2 = "escort"
  L5_2 = 50
  L6_2 = 20
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L4_2 = {}
  L5_2 = "Buggy (Hellfire)"
  L6_2 = 80
  L7_2 = 10
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L2_2 = L1_2[A0_2]
  L3_2 = Pg
  L3_2 = L3_2.SpawnFromCamera
  L4_2 = L2_2[1]
  L5_2 = 12
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.ObjectInSeat
  L6_2 = {}
  L7_2 = Player
  L7_2 = L7_2.GetAnyCharacter
  L7_2 = L7_2()
  L8_2 = L3_2
  L9_2 = "d"
  L10_2 = "ei"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  
  function L7_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = Start
    L1_3 = L3_2
    L2_3 = L2_2
    L2_3 = L2_3[2]
    L3_3 = L2_2
    L3_3 = L3_3[3]
    L0_3 = L0_3(L1_3, L2_3, L3_3)
    gTest = L0_3
  end
  
  L4_2(L5_2, L6_2, L7_2)
end

Test = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = {}
  L3_2.uVeh = A0_2
  L4_2 = Math
  L4_2 = L4_2.abs
  L5_2 = Object
  L5_2 = L5_2.GetVelocity
  L6_2 = A0_2
  L5_2, L6_2, L7_2, L8_2, L9_2 = L5_2(L6_2)
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  L3_2.curSpeed = L4_2
  L4_2 = Sys
  L4_2 = L4_2.MainTimeStamp
  L4_2 = L4_2()
  L3_2.uTimeStamp = L4_2
  L4_2 = MrxUtil
  L4_2 = L4_2.SetDefault
  L5_2 = A2_2
  L6_2 = 10
  L4_2 = L4_2(L5_2, L6_2)
  L3_2.kInitBombTime = L4_2
  L4_2 = L3_2.kInitBombTime
  L3_2.fMarkedTime = L4_2
  L4_2 = L3_2.kInitBombTime
  L3_2.fTimeLeft = L4_2
  L4_2 = MrxUtil
  L4_2 = L4_2.SetDefault
  L5_2 = A1_2
  L6_2 = 80
  L4_2 = L4_2(L5_2, L6_2)
  L4_2 = L4_2 * 10
  L4_2 = L4_2 / 36
  L3_2.kSpeedThreshold = L4_2
  L4_2 = Event
  L4_2 = L4_2.CreatePersistent
  L5_2 = Event
  L5_2 = L5_2.TimerRelative
  L6_2 = {}
  L7_2 = 0.1
  L6_2[1] = L7_2
  L7_2 = Update
  L8_2 = {}
  L9_2 = L3_2
  L8_2[1] = L9_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L3_2.eTimer = L4_2
  return L3_2
end

Start = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 2
  L1_2(L2_2, L3_2)
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 3
  L1_2(L2_2, L3_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.eTimer
  L1_2(L2_2)
end

Cleanup = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = A0_2.uVeh
  L2_2 = Math
  L2_2 = L2_2.abs
  L3_2 = Object
  L3_2 = L3_2.GetVelocity
  L4_2 = L1_2
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L3_2 = A0_2.bStartBomb
  if not L3_2 then
    L3_2 = A0_2.kSpeedThreshold
    if L2_2 >= L3_2 then
      A0_2.bStartBomb = true
    end
    L3_2 = UpdateDisplay
    L4_2 = L2_2
    L5_2 = A0_2.fTimeLeft
    L6_2 = A0_2
    L3_2(L4_2, L5_2, L6_2)
    return
  end
  L3_2 = A0_2.kSpeedThreshold
  if L2_2 < L3_2 then
    L3_2 = A0_2.bMarked
    if L3_2 then
      L3_2 = A0_2.fMarkedTime
      L4_2 = Sys
      L4_2 = L4_2.TimeStampGetElapsed
      L5_2 = A0_2.uTimeStamp
      L4_2 = L4_2(L5_2)
      L3_2 = L3_2 - L4_2
      A0_2.fTimeLeft = L3_2
    else
      A0_2.bMarked = true
      L3_2 = Sys
      L3_2 = L3_2.TimeStampMark
      L4_2 = A0_2.uTimeStamp
      L3_2(L4_2)
      L3_2 = A0_2.fTimeLeft
      A0_2.fMarkedTime = L3_2
    end
  else
    A0_2.bMarked = nil
  end
  L3_2 = A0_2.fTimeLeft
  if L3_2 <= 0 then
    A0_2.fTimeLeft = 0
    L3_2 = KillVehicle
    L4_2 = A0_2
    L3_2(L4_2)
  end
  L3_2 = UpdateDisplay
  L4_2 = L2_2
  L5_2 = A0_2.fTimeLeft
  L6_2 = A0_2
  L3_2(L4_2, L5_2, L6_2)
end

Update = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Sound
  L1_2 = L1_2.CueSound
  L2_2 = A0_2.uVeh
  L3_2 = "wpn_bomb_timer_01_finalstage"
  L1_2(L2_2, L3_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.eTimer
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.TimerRelative
  L3_2 = {}
  L4_2 = 1
  L3_2[1] = L4_2
  L4_2 = KillVehicle2
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

KillVehicle = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = A0_2.uVeh
  L2_2 = Sound
  L2_2 = L2_2.StopSound
  L3_2 = L1_2
  L4_2 = "wpn_bomb_timer_01_finalstage"
  L2_2(L3_2, L4_2)
  L2_2 = MrxUtil
  L2_2 = L2_2.SpawnObject
  L3_2 = "fx_Explosion_HugeOil"
  L4_2 = L1_2
  L2_2(L3_2, L4_2)
  L2_2 = Object
  L2_2 = L2_2.Kill
  L3_2 = L1_2
  L2_2(L3_2)
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = 2
  L4_2[1] = L5_2
  L5_2 = Cleanup
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
end

KillVehicle2 = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = "[green]"
  L4_2 = A2_2.bStartBomb
  if not L4_2 then
    L3_2 = "[white]"
  else
    L4_2 = A2_2.kSpeedThreshold
    if A0_2 < L4_2 then
      L3_2 = "[red]"
    else
      L4_2 = A2_2.kSpeedThreshold
      L4_2 = L4_2 + 1.3888888
      if A0_2 < L4_2 then
        L3_2 = "[yellow]"
      end
    end
  end
  L4_2 = 100 * A1_2
  L5_2 = A2_2.kInitBombTime
  L4_2 = L4_2 / L5_2
  L5_2 = Math
  L5_2 = L5_2.floor
  L6_2 = L4_2
  L5_2 = L5_2(L6_2)
  L4_2 = L5_2
  L5_2 = "[white]"
  if not (L4_2 < 10) then
    L6_2 = A2_2.bMarked
    if not L6_2 then
      goto lbl_32
    end
  end
  L5_2 = "[red]"
  ::lbl_32::
  L6_2 = Math
  L6_2 = L6_2.floor
  L7_2 = A0_2 * 3.6
  L6_2 = L6_2(L7_2)
  A0_2 = L6_2
  L6_2 = Hud
  L6_2 = L6_2.ObjectiveTray
  L7_2 = L6_2
  L6_2 = L6_2.SetSlotToText
  L8_2 = {}
  L8_2.nSlot = 2
  L9_2 = L3_2
  L10_2 = A0_2
  L11_2 = " Kph"
  L9_2 = L9_2 .. L10_2 .. L11_2
  L8_2.sText = L9_2
  L6_2(L7_2, L8_2)
  L6_2 = Hud
  L6_2 = L6_2.ObjectiveTray
  L7_2 = L6_2
  L6_2 = L6_2.SetSlotToText
  L8_2 = {}
  L8_2.nSlot = 3
  L9_2 = L5_2
  L10_2 = "[bar"
  L11_2 = L4_2
  L12_2 = "]"
  L9_2 = L9_2 .. L10_2 .. L11_2 .. L12_2
  L8_2.sText = L9_2
  L6_2(L7_2, L8_2)
end

UpdateDisplay = L0_1
