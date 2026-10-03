local L0_1, L1_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L3_2 = Sys
  L3_2 = L3_2.GuidToString
  L4_2 = A2_2
  L3_2 = L3_2(L4_2)
  if L3_2 == "0x7687DF41" then
    L4_2 = ObjectState
    L4_2 = L4_2.GetStringHash
    L5_2 = "fx_EmitFlameOilrigTower"
    L4_2 = L4_2(L5_2)
    L5_2 = ObjectState
    L5_2 = L5_2.StartEmitter
    L6_2 = A0_2
    L7_2 = A1_2
    L8_2 = L4_2
    L5_2(L6_2, L7_2, L8_2)
    L5_2 = Math
    L5_2 = L5_2.randf
    L6_2 = 12
    L7_2 = 20
    L5_2 = L5_2(L6_2, L7_2)
    L6_2 = Event
    L6_2 = L6_2.Create
    L7_2 = Event
    L7_2 = L7_2.TimerRelative
    L8_2 = {}
    L9_2 = L5_2
    L8_2[1] = L9_2
    L9_2 = _StartSmoke
    L10_2 = {}
    L11_2 = A0_2
    L12_2 = A1_2
    L13_2 = L4_2
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L10_2[3] = L13_2
    L6_2(L7_2, L8_2, L9_2, L10_2)
  end
end

OnStateChange = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = ObjectState
  L3_2 = L3_2.StopEmitter
  L4_2 = A0_2
  L5_2 = A1_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = ObjectState
  L3_2 = L3_2.StartEmitter
  L4_2 = A0_2
  L5_2 = A1_2
  L6_2 = ObjectState
  L6_2 = L6_2.GetStringHash
  L7_2 = "fx_EmitSmokeStack"
  L6_2, L7_2 = L6_2(L7_2)
  L3_2(L4_2, L5_2, L6_2, L7_2)
end

_StartSmoke = L0_1
