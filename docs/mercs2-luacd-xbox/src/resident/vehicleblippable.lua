local L0_1, L1_1, L2_1, L3_1
L0_1 = inherit
L1_1 = "OrientedBlippable"
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
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectHibernation
  L5_2 = {}
  L6_2 = A0_2
  L7_2 = "awake"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = Start
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A1_2
  L10_2 = A2_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
end

OnActivate = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = Object
  L3_2 = L3_2.GetHealth
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  L4_2 = type
  L5_2 = L3_2
  L4_2 = L4_2(L5_2)
  if L4_2 == "number" and 0 < L3_2 then
    L4_2 = getfenv
    L4_2 = L4_2()
    L6_2 = L4_2
    L5_2 = L4_2.Create
    L7_2 = A0_2
    L8_2 = A1_2
    L5_2 = L5_2(L6_2, L7_2, L8_2)
  end
end

Start = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = OrientedBlippable
  L3_2 = L3_2.Create
  L4_2 = A0_2
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L4_2 = L3_2.DriverEnter
  if not L4_2 then
    L4_2 = Event
    L4_2 = L4_2.CreatePersistent
    L5_2 = Event
    L5_2 = L5_2.ObjectInSeat
    L6_2 = {}
    L7_2 = "Human"
    L8_2 = A1_2
    L9_2 = "Driver"
    L10_2 = "enter"
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L6_2[4] = L10_2
    L7_2 = L3_2.SetBlipped
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
    L7_2 = "Human"
    L8_2 = A1_2
    L9_2 = "Driver"
    L10_2 = "exit"
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L6_2[4] = L10_2
    L7_2 = L3_2.SetBlipped
    L8_2 = {}
    L9_2 = L3_2
    L10_2 = A1_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
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
    L8_2 = L3_2.SetBlipped
    L9_2 = {}
    L10_2 = L3_2
    L11_2 = A1_2
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L6_2 = L6_2(L7_2, L8_2, L9_2)
    L3_2.Attitude = L6_2
  end
  L7_2 = L3_2
  L6_2 = L3_2.SetBlipped
  L8_2 = A1_2
  L6_2(L7_2, L8_2)
  return L3_2
end

Create = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.DriverEnter
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.DriverExit
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.Attitude
  L1_2(L2_2)
  L1_2 = OrientedBlippable
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
        goto lbl_47
      end
    end
    L2_2 = A0_2.tColorPmc
    A0_2.tColor = L2_2
    goto lbl_70
    ::lbl_47::
    L2_2 = nRelation
    if L2_2 < 60 then
      L2_2 = nRelation
      if -60 < L2_2 then
        L2_2 = A0_2.tColorNeutral
        A0_2.tColor = L2_2
    end
    else
      L2_2 = nRelation
      if L2_2 <= -60 then
        L2_2 = A0_2.tColorEnemy
        A0_2.tColor = L2_2
      else
        L2_2 = nRelation
        if 60 <= L2_2 then
          L2_2 = A0_2.tColorAlly
          A0_2.tColor = L2_2
        end
      end
    end
  else
    L2_2 = A0_2.tColorEmpty
    A0_2.tColor = L2_2
  end
  ::lbl_70::
  L2_2 = OrientedBlippable
  L2_2 = L2_2.SetBlipped
  L3_2 = A0_2
  L2_2(L3_2)
end

SetBlipped = L0_1
