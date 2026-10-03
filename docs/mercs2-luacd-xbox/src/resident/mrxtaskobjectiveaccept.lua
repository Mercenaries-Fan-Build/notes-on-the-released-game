local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskObjectiveAction"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPlayer"
L0_1(L1_1)

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L3_2 = A0_2._bConfPromptDisplayed
  if not L3_2 then
    A0_2._bConfPromptDisplayed = true
    L3_2 = MrxUtil
    L3_2 = L3_2.SetDefault
    L5_2 = A0_2
    L4_2 = A0_2.GetConfig
    L4_2 = L4_2(L5_2)
    L4_2 = L4_2.sDialogText
    L5_2 = "[Generic.Accept]?"
    L3_2 = L3_2(L4_2, L5_2)
    L4_2 = Player
    L4_2 = L4_2.GetCharacter
    L5_2 = A1_2
    L4_2 = L4_2(L5_2)
    L5_2 = MrxGui
    L5_2 = L5_2.DisplayDialogBox
    L6_2 = L4_2
    L7_2 = L3_2
    L8_2 = {}
    L9_2 = "[Generic.Yes]"
    L10_2 = "[Generic.No]"
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L9_2 = 1
    L10_2 = _ConfPromptDismissed
    L11_2 = {}
    L12_2 = A0_2
    L13_2 = A1_2
    L14_2 = A2_2
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L11_2[3] = L14_2
    L12_2 = nil
    L13_2 = nil
    L14_2 = nil
    L15_2 = nil
    L16_2 = nil
    L17_2 = 2
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  end
end

_TargetActioned = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2
  A0_2._bConfPromptDisplayed = false
  if A3_2 == 1 then
    L4_2 = MrxTaskObjectiveAction
    L4_2 = L4_2._TargetActioned
    L5_2 = A0_2
    L6_2 = A1_2
    L7_2 = A2_2
    L4_2(L5_2, L6_2, L7_2)
  end
end

_ConfPromptDismissed = L0_1

function L0_1(A0_2, A1_2)
end

_PrintObjectiveMessage = L0_1
