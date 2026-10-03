local L0_1, L1_1
L0_1 = {}

function L1_1(A0_2)
  local L1_2
end

L0_1.rgn_atmo_GRstripmine = L1_1

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetSky
  L2_2 = "afternoon"
  L1_2(L2_2)
end

L0_1["rgn_atmo_GR Cave"] = L1_1

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetSky
  L2_2 = "Maracaibo"
  L1_2(L2_2)
end

L0_1.rgn_atmo_Caracas = L1_1

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = Graphics
  L1_2 = L1_2.Atmosphere
  L1_2 = L1_2.SetSky
  L2_2 = "afternoon"
  L1_2(L2_2)
end

L0_1["rgn_atmo_PMC Outpost"] = L1_1
tBoundaryList = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = Graphics
  L0_2 = L0_2.Atmosphere
  L0_2 = L0_2.SetSky
  L1_2 = "afternoon"
  L0_2(L1_2)
end

SetDefaultAtmosphere = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = SetDefaultAtmosphere
  L0_2()
  L0_2 = SetupBoundaryEvents
  L0_2()
end

Start = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L0_2 = Sys
  L0_2 = L0_2.IsLoadingOrStreaming
  if L0_2 then
    L0_2 = Player
    L0_2 = L0_2.GetLocalCharacter
    L0_2 = L0_2()
    if L0_2 then
      L0_2 = Sys
      L0_2 = L0_2.IsLoadingOrStreaming
      L0_2 = L0_2()
      if not L0_2 then
        goto lbl_25
      end
    end
    L0_2 = Event
    L0_2 = L0_2.Create
    L1_2 = Event
    L1_2 = L1_2.TimerRelative
    L2_2 = {}
    L3_2 = 2
    L2_2[1] = L3_2
    L3_2 = SetupBoundaryEvents
    L0_2(L1_2, L2_2, L3_2)
    return
  end
  ::lbl_25::
  L0_2 = pairs
  L1_2 = tBoundaryList
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = Pg
    L5_2 = L5_2.GetGuidByName
    L6_2 = L3_2
    L5_2 = L5_2(L6_2)
    L6_2 = SetupBoundaryEvent
    L7_2 = L5_2
    L8_2 = L3_2
    L9_2 = "enter"
    L6_2(L7_2, L8_2, L9_2)
  end
end

SetupBoundaryEvents = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  if A0_2 then
    L3_2 = Event
    L3_2 = L3_2.Create
    L4_2 = Event
    L4_2 = L4_2.Boundary
    L5_2 = {}
    L6_2 = Player
    L6_2 = L6_2.GetLocalCharacter
    L6_2 = L6_2()
    L7_2 = A0_2
    L8_2 = A2_2
    L9_2 = false
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L5_2[4] = L9_2
    L6_2 = CrossedBoundary
    L7_2 = {}
    L8_2 = A1_2
    L7_2[1] = L8_2
    L3_2(L4_2, L5_2, L6_2, L7_2)
  end
end

SetupBoundaryEvent = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  if not (A1_2 and A0_2) or not A2_2 then
    return
  end
  if A3_2 == "enter" then
    L4_2 = tBoundaryList
    L4_2 = L4_2[A0_2]
    L5_2 = L4_2
    L6_2 = true
    L5_2(L6_2)
    L5_2 = SetupBoundaryEvent
    L6_2 = A2_2
    L7_2 = A0_2
    L8_2 = "exit"
    L5_2(L6_2, L7_2, L8_2)
  elseif A3_2 == "exit" then
    L4_2 = tBoundaryList
    L4_2 = L4_2[A0_2]
    L5_2 = L4_2
    L6_2 = false
    L5_2(L6_2)
    L5_2 = true
    if A1_2 ~= nil then
      L6_2 = pairs
      L7_2 = tBoundaryList
      L6_2, L7_2, L8_2 = L6_2(L7_2)
      for L9_2, L10_2 in L6_2, L7_2, L8_2 do
        L11_2 = Pg
        L11_2 = L11_2.GetGuidByName
        L12_2 = L9_2
        L11_2 = L11_2(L12_2)
        if L11_2 then
          L12_2 = Object
          L12_2 = L12_2.InsideBoundary
          L13_2 = A1_2
          L14_2 = L11_2
          L12_2 = L12_2(L13_2, L14_2)
          if L12_2 then
            L5_2 = false
            break
          end
        end
      end
    end
    if L5_2 then
      L6_2 = SetDefaultAtmosphere
      L6_2()
    end
    L6_2 = SetupBoundaryEvent
    L7_2 = A2_2
    L8_2 = A0_2
    L9_2 = "enter"
    L6_2(L7_2, L8_2, L9_2)
  end
end

CrossedBoundary = L0_1
