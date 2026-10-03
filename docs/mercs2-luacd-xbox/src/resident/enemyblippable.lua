local L0_1, L1_1, L2_1, L3_1
L0_1 = inherit
L1_1 = "Blippable"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = {}
L1_1 = 0
L2_1 = 127
L3_1 = 255
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
tColorAlly = L0_1
L0_1 = {}
L1_1 = 230
L2_1 = 230
L3_1 = 255
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
tColorNeutral = L0_1
L0_1 = {}
L1_1 = 255
L2_1 = 0
L3_1 = 0
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
tColorEnemy = L0_1
L0_1 = {}
L1_1 = 100
L2_1 = 100
L3_1 = 100
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
tColorEmpty = L0_1
L0_1 = {}
L1_1 = 0
L2_1 = 255
L3_1 = 0
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
tColorPmc = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = GetFromGuid
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L4_2 = Blippable
    L4_2 = L4_2.Create
    L5_2 = A0_2
    L6_2 = A1_2
    L7_2 = A2_2
    L4_2 = L4_2(L5_2, L6_2, L7_2)
    L3_2 = L4_2
  end
  L4_2 = L3_2.DriverEnter
  if not L4_2 then
    L4_2 = Event
    L4_2 = L4_2.CreatePersistent
    L5_2 = Event
    L5_2 = L5_2.ObjectInSeat
    L6_2 = {}
    L7_2 = "human"
    L8_2 = A1_2
    L9_2 = "Driver"
    L10_2 = "enter"
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L6_2[4] = L10_2
    L7_2 = L3_2.PickColor
    L8_2 = {}
    L9_2 = L3_2
    L10_2 = A1_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
    L3_2.DriverEnter = L4_2
  end
  L4_2 = L3_2.DriverExit
  if not L4_2 then
    L4_2 = Event
    L4_2 = L4_2.CreatePersistent
    L5_2 = Event
    L5_2 = L5_2.ObjectInSeat
    L6_2 = {}
    L7_2 = "human"
    L8_2 = A1_2
    L9_2 = "Driver"
    L10_2 = "exit"
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L6_2[4] = L10_2
    
    function L7_2()
      local L0_3, L1_3, L2_3
      L0_3 = L3_2
      L1_3 = L0_3
      L0_3 = L0_3.ClearBlipped
      L2_3 = true
      L0_3(L1_3, L2_3)
    end
    
    L4_2 = L4_2(L5_2, L6_2, L7_2)
    L3_2.DriverExit = L4_2
  end
  L4_2 = MrxUtil
  L4_2 = L4_2.GetFaction
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  L5_2 = MrxFactionManager
  L5_2 = L5_2.GetFactionAbbrev
  L6_2 = L4_2
  L5_2 = L5_2(L6_2)
  L6_2 = L3_2.Attitude
  if not L6_2 then
    L6_2 = MrxFactionManager
    L6_2 = L6_2.CreatePersistentAttitudeChangeEvent
    L7_2 = {}
    L8_2 = L5_2
    L9_2 = "Pmc"
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    
    function L8_2()
      local L0_3, L1_3, L2_3
      L0_3 = L3_2
      L0_3 = L0_3.ClearBlipped
      L1_3 = L3_2
      L2_3 = A1_2
      L0_3(L1_3, L2_3)
      L0_3 = L3_2
      L0_3 = L0_3.PickColor
      L1_3 = L3_2
      L2_3 = A1_2
      L0_3(L1_3, L2_3)
      L0_3 = L3_2
      L0_3 = L0_3.SetBlipped
      L1_3 = L3_2
      L2_3 = A1_2
      L0_3(L1_3, L2_3)
    end
    
    L9_2 = {}
    L6_2 = L6_2(L7_2, L8_2, L9_2)
    L3_2.Attitude = L6_2
  end
  L6_2 = Vehicle
  L6_2 = L6_2.GetDriver
  L7_2 = A1_2
  L6_2 = L6_2(L7_2)
  if L6_2 then
    L8_2 = L3_2
    L7_2 = L3_2.PickColor
    L9_2 = A1_2
    L7_2(L8_2, L9_2)
  end
  return L3_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2.DriverEnter
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2.DriverEnter
    L1_2(L2_2)
    A0_2.DriverEnter = nil
  end
  L1_2 = A0_2.Attitude
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2.Attitude
    L1_2(L2_2)
    A0_2.Attitude = nil
  end
  L1_2 = A0_2.DriverExit
  if L1_2 then
    L1_2 = Event
    L1_2 = L1_2.Delete
    L2_2 = A0_2.DriverExit
    L1_2(L2_2)
    A0_2.DriverExit = nil
  end
  L1_2 = Blippable
  L1_2 = L1_2.Delete
  L2_2 = A0_2
  L1_2(L2_2)
end

Delete = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = Vehicle
  L2_2 = L2_2.GetDriver
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  uRider = L2_2
  L2_2 = uRider
  if L2_2 then
    L2_2 = Object
    L2_2 = L2_2.IsPlayerControlled
    L3_2 = uRider
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L3_2 = A0_2
      L2_2 = A0_2.ClearBlipped
      L2_2(L3_2)
      return
    end
  end
  L2_2 = uRider
  if L2_2 then
    L2_2 = Ai
    L2_2 = L2_2.GetRelation
    L3_2 = uRider
    L4_2 = Pg
    L4_2 = L4_2.GetGuidByName
    L5_2 = "PMC"
    L4_2, L5_2 = L4_2(L5_2)
    L2_2 = L2_2(L3_2, L4_2, L5_2)
    nRelation = L2_2
    L2_2 = Object
    L2_2 = L2_2.HasLabel
    L3_2 = A1_2
    L4_2 = "pmc"
    L2_2 = L2_2(L3_2, L4_2)
    if not L2_2 then
      L2_2 = Object
      L2_2 = L2_2.HasLabel
      L3_2 = uRider
      L4_2 = "pmc"
      L2_2 = L2_2(L3_2, L4_2)
      if not L2_2 then
        goto lbl_53
      end
    end
    L2_2 = A0_2.tColorPmc
    A0_2.tColor = L2_2
    L2_2 = A0_2.tMarker
    if L2_2 then
      L2_2 = A0_2.tMarker
      L3_2 = A0_2.tColorPmc
      L2_2.tColor = L3_2
    end
    goto lbl_95
    ::lbl_53::
    L2_2 = nRelation
    if L2_2 < 60 then
      L2_2 = nRelation
      if -60 < L2_2 then
        L2_2 = A0_2.tColorNeutral
        A0_2.tColor = L2_2
        L2_2 = A0_2.tMarker
        if L2_2 then
        end
        L2_2 = A0_2.tMarker
        L3_2 = A0_2.tColorNeutral
        L2_2.tColor = L3_2
    end
    else
      L2_2 = nRelation
      if L2_2 <= -60 then
        A0_2.bHostile = true
        L2_2 = A0_2.tColorEnemy
        A0_2.tColor = L2_2
        L2_2 = A0_2.tMarker
        if L2_2 then
          L2_2 = A0_2.tMarker
          L3_2 = A0_2.tColorEnemy
          L2_2.tColor = L3_2
        end
      else
        L2_2 = nRelation
        if 60 <= L2_2 then
          L2_2 = A0_2.tColorAlly
          A0_2.tColor = L2_2
          L2_2 = A0_2.tMarker
          if L2_2 then
            L2_2 = A0_2.tMarker
            L3_2 = A0_2.tColorAlly
            L2_2.tColor = L3_2
          end
        end
      end
    end
  else
    L2_2 = A0_2.tColorEmpty
    A0_2.tColor = L2_2
  end
  ::lbl_95::
  L2_2 = A0_2.tColor
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.SetBlipped
    L4_2 = true
    L2_2(L3_2, L4_2)
  end
end

PickColor = L0_1
