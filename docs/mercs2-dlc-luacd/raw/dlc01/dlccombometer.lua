local L0_1, L1_1, L2_1
L0_1 = import
L1_1 = "MrxUtil"
L2_1 = false
L0_1(L1_1, L2_1)

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = 0
  nCurDestroyedBldgs = L3_2
  L3_2 = 0
  nTotalBldgCount = L3_2
  L3_2 = 1
  nPeakCombo = L3_2
  L3_2 = 1
  nPrevPeakCombo = L3_2
  L3_2 = {}
  L3_2.uPlayer = A1_2
  L4_2 = Sys
  L4_2 = L4_2.MainTimeStamp
  L4_2 = L4_2()
  L3_2.uTimeStamp = L4_2
  L3_2.nCombo = 1
  L3_2.nScore = 0
  L3_2.fMeter = 0
  L4_2 = MrxUtil
  L4_2 = L4_2.SetDefault
  L5_2 = A2_2
  L6_2 = 5
  L4_2 = L4_2(L5_2, L6_2)
  L3_2.fComboDecayTime = L4_2
  L4_2 = ObjectFilter
  L4_2 = L4_2.Create
  L4_2 = L4_2()
  L3_2.uFilter = L4_2
  L4_2 = ObjectFilter
  L4_2 = L4_2.SetFilter
  L5_2 = L3_2.uFilter
  L6_2 = "Vehicle||Building"
  L4_2(L5_2, L6_2)
  L4_2 = Event
  L4_2 = L4_2.CreatePersistent
  L5_2 = Event
  L5_2 = L5_2.ObjectDeath
  L6_2 = {}
  L7_2 = L3_2.uFilter
  L6_2[1] = L7_2
  L7_2 = Combo_ObjectDestroyed
  L8_2 = {}
  L9_2 = A0_2
  L10_2 = L3_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L3_2.eObjectDestroyed = L4_2
  L4_2 = Combo_Display
  L5_2 = L3_2
  L4_2(L5_2)
  return L3_2
end

Combo_Init = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2
  L3_2 = Object
  L3_2 = L3_2.GetPosition
  L4_2 = A2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  L6_2 = math
  L6_2 = L6_2.randf
  L7_2 = -2
  L8_2 = 2
  L6_2 = L6_2(L7_2, L8_2)
  L7_2 = math
  L7_2 = L7_2.randf
  L8_2 = -2
  L9_2 = 2
  L7_2 = L7_2(L8_2, L9_2)
  L8_2 = ""
  L9_2 = 0
  L10_2 = Object
  L10_2 = L10_2.GetMaxHealth
  L11_2 = A2_2
  L10_2 = L10_2(L11_2)
  L11_2 = Object
  L11_2 = L11_2.HasLabel
  L12_2 = A2_2
  L13_2 = "Vehicle"
  L11_2 = L11_2(L12_2, L13_2)
  if not L11_2 then
    L11_2 = Object
    L11_2 = L11_2.HasLabel
    L12_2 = A2_2
    L13_2 = "Building"
    L11_2 = L11_2(L12_2, L13_2)
    if not L11_2 then
      goto lbl_81
    end
  end
  L11_2 = A1_2.nCombo
  L11_2 = L11_2 + 1
  A1_2.nCombo = L11_2
  L11_2 = A1_2.nCombo
  L12_2 = nPeakCombo
  if L11_2 > L12_2 then
    L11_2 = nPeakCombo
    nPrevPeakCombo = L11_2
    L11_2 = A1_2.nCombo
    nPeakCombo = L11_2
    L11_2 = MessageBox
    L12_2 = L11_2
    L11_2 = L11_2.AddMessage
    L13_2 = "[green][DLCCon004.UI.NewPeakCombo] X"
    L14_2 = nPeakCombo
    L13_2 = L13_2 .. L14_2
    L14_2 = 0
    L15_2 = 3
    L16_2 = 0
    L17_2 = nil
    L18_2 = true
    L19_2 = nil
    L11_2(L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
  end
  L11_2 = nCurDestroyedBldgs
  L11_2 = L11_2 + 1
  nCurDestroyedBldgs = L11_2
  L11_2 = Object
  L11_2 = L11_2.GetParent
  L12_2 = A2_2
  L11_2 = L11_2(L12_2)
  L12_2 = Pg
  L12_2 = L12_2.GetGuidByName
  L13_2 = "_DLC_vzoutpost_bld_guardtower"
  L12_2 = L12_2(L13_2)
  if L11_2 == L12_2 then
    return
  else
    L12_2 = Object
    L12_2 = L12_2.HasLabel
    L13_2 = A2_2
    L14_2 = "uberVehicle"
    L12_2 = L12_2(L13_2, L14_2)
    if not L12_2 then
      L9_2 = L10_2 / 10
    end
  end
  ::lbl_81::
  if 50 <= L9_2 then
    L11_2 = math
    L11_2 = L11_2.floor
    L12_2 = L9_2 / 50
    L11_2 = L11_2(L12_2)
    L12_2 = 1
    L13_2 = L11_2
    L14_2 = 1
    for L15_2 = L12_2, L13_2, L14_2 do
      L16_2 = math
      L16_2 = L16_2.randf
      L17_2 = -2
      L18_2 = 2
      L16_2 = L16_2(L17_2, L18_2)
      L17_2 = math
      L17_2 = L17_2.randf
      L18_2 = -2
      L19_2 = 2
      L17_2 = L17_2(L18_2, L19_2)
      L18_2 = Pg
      L18_2 = L18_2.Spawn
      L19_2 = "DLCCon004_Cash_XXL_05"
      L20_2 = L3_2 + L16_2
      L21_2 = L4_2 + 4
      L22_2 = L5_2 + L17_2
      L18_2(L19_2, L20_2, L21_2, L22_2)
    end
  end
  L11_2 = L9_2 % 50
  if 10 <= L11_2 then
    L12_2 = math
    L12_2 = L12_2.floor
    L13_2 = L11_2 / 10
    L12_2 = L12_2(L13_2)
    L13_2 = 1
    L14_2 = L12_2
    L15_2 = 1
    for L16_2 = L13_2, L14_2, L15_2 do
      L17_2 = math
      L17_2 = L17_2.randf
      L18_2 = -2
      L19_2 = 2
      L17_2 = L17_2(L18_2, L19_2)
      L18_2 = math
      L18_2 = L18_2.randf
      L19_2 = -2
      L20_2 = 2
      L18_2 = L18_2(L19_2, L20_2)
      L19_2 = Pg
      L19_2 = L19_2.Spawn
      L20_2 = "DLCCon004_Cash_L_03"
      L21_2 = L3_2 + L17_2
      L22_2 = L4_2 + 4
      L23_2 = L5_2 + L18_2
      L19_2(L20_2, L21_2, L22_2, L23_2)
    end
  end
  L12_2 = L11_2 % 10
  if 0 < L12_2 then
    L13_2 = 1
    L14_2 = L12_2
    L15_2 = 1
    for L16_2 = L13_2, L14_2, L15_2 do
      L17_2 = math
      L17_2 = L17_2.randf
      L18_2 = -2
      L19_2 = 2
      L17_2 = L17_2(L18_2, L19_2)
      L18_2 = math
      L18_2 = L18_2.randf
      L19_2 = -2
      L20_2 = 2
      L18_2 = L18_2(L19_2, L20_2)
      L19_2 = Pg
      L19_2 = L19_2.Spawn
      L20_2 = "DLCCon004_Cash_S_01"
      L21_2 = L3_2 + L17_2
      L22_2 = L4_2 + 4
      L23_2 = L5_2 + L18_2
      L19_2(L20_2, L21_2, L22_2, L23_2)
    end
  end
  L13_2 = Pg
  L13_2 = L13_2.Spawn
  L14_2 = "Explosion (TEST)"
  L15_2 = L3_2
  L16_2 = L4_2
  L17_2 = L5_2
  L13_2(L14_2, L15_2, L16_2, L17_2)
  L13_2 = Combo_StartDecay
  L14_2 = A1_2
  L13_2(L14_2)
end

Combo_ObjectDestroyed = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Sys
  L1_2 = L1_2.TimeStampMark
  L2_2 = A0_2.uTimeStamp
  L1_2(L2_2)
  L1_2 = A0_2.eTimer
  if not L1_2 then
    L1_2 = Event
    L1_2 = L1_2.CreatePersistent
    L2_2 = Event
    L2_2 = L2_2.TimerRelative
    L3_2 = {}
    L4_2 = 0.1
    L3_2[1] = L4_2
    L4_2 = Combo_Update
    L5_2 = {}
    L6_2 = A0_2
    L5_2[1] = L6_2
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
    A0_2.eTimer = L1_2
  end
end

Combo_StartDecay = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.fComboDecayTime
  L2_2 = Sys
  L2_2 = L2_2.TimeStampGetElapsed
  L3_2 = A0_2.uTimeStamp
  L2_2 = L2_2(L3_2)
  L1_2 = L1_2 - L2_2
  L2_2 = A0_2.fComboDecayTime
  L1_2 = L1_2 / L2_2
  A0_2.fMeter = L1_2
  L1_2 = Math
  L1_2 = L1_2.floor
  L2_2 = A0_2.fMeter
  L2_2 = 100 * L2_2
  L1_2 = L1_2(L2_2)
  A0_2.fMeter = L1_2
  L1_2 = A0_2.fMeter
  if L1_2 <= 0 then
    L1_2 = A0_2.nCombo
    if L1_2 == 1 then
      A0_2.fMeter = 0
      L1_2 = Event
      L1_2 = L1_2.Delete
      L2_2 = A0_2.eTimer
      L1_2(L2_2)
      A0_2.eTimer = nil
    else
      A0_2.fMeter = 100
      L1_2 = Sys
      L1_2 = L1_2.TimeStampMark
      L2_2 = A0_2.uTimeStamp
      L1_2(L2_2)
      L1_2 = A0_2.nCombo
      L1_2 = L1_2 - 1
      A0_2.nCombo = L1_2
    end
  end
  L1_2 = Combo_Display
  L2_2 = A0_2
  L1_2(L2_2)
end

Combo_Update = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = A0_2.nCombo
  if 5 < L1_2 then
    L1_2 = Hud
    L1_2 = L1_2.ObjectiveTray
    L2_2 = L1_2
    L1_2 = L1_2.SetSlotToText
    L3_2 = {}
    L3_2.nSlot = 1
    L4_2 = "x"
    L5_2 = A0_2.nCombo
    L6_2 = "[green][bar"
    L7_2 = A0_2.fMeter
    L8_2 = "]"
    L4_2 = L4_2 .. L5_2 .. L6_2 .. L7_2 .. L8_2
    L3_2.sText = L4_2
    L1_2(L2_2, L3_2)
  else
    L1_2 = A0_2.nCombo
    if 2 < L1_2 then
      L1_2 = A0_2.nCombo
      if L1_2 <= 5 then
        L1_2 = Hud
        L1_2 = L1_2.ObjectiveTray
        L2_2 = L1_2
        L1_2 = L1_2.SetSlotToText
        L3_2 = {}
        L3_2.nSlot = 1
        L4_2 = "x"
        L5_2 = A0_2.nCombo
        L6_2 = "[yellow][bar"
        L7_2 = A0_2.fMeter
        L8_2 = "]"
        L4_2 = L4_2 .. L5_2 .. L6_2 .. L7_2 .. L8_2
        L3_2.sText = L4_2
        L1_2(L2_2, L3_2)
    end
    else
      L1_2 = A0_2.nCombo
      if L1_2 <= 2 then
        L1_2 = Hud
        L1_2 = L1_2.ObjectiveTray
        L2_2 = L1_2
        L1_2 = L1_2.SetSlotToText
        L3_2 = {}
        L3_2.nSlot = 1
        L4_2 = "x"
        L5_2 = A0_2.nCombo
        L6_2 = "[red][bar"
        L7_2 = A0_2.fMeter
        L8_2 = "]"
        L4_2 = L4_2 .. L5_2 .. L6_2 .. L7_2 .. L8_2
        L3_2.sText = L4_2
        L1_2(L2_2, L3_2)
      end
    end
  end
end

Combo_Display = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Event
  L1_2 = L1_2.CreatePersistent
  L2_2 = Event
  L2_2 = L2_2.ScriptEvent
  L3_2 = {}
  L4_2 = "SurvivalMode"
  
  function L5_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = A0_3[1]
    L2_3 = Player
    L2_3 = L2_3.GetCharacter
    L3_3 = A0_2
    L3_3 = L3_3.uPlayer
    L2_3 = L2_3(L3_3)
    L1_3 = L1_3 == L2_3
    return L1_3
  end
  
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L4_2 = Combo_PlayerDamage
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  A0_2.ePlayerDamage = L1_2
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.ObjectDeath
  L3_2 = {}
  L4_2 = Player
  L4_2 = L4_2.GetCharacter
  L5_2 = A0_2.uPlayer
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L4_2 = Combo_PlayerDamage
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  A0_2.ePlayerDeath = L1_2
end

Combo_PlayerDamageSetup = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = MessageBox
  L3_2 = L2_2
  L2_2 = L2_2.AddMessage
  L4_2 = "[red]Combo lost!"
  L5_2 = 0
  L6_2 = 4
  L7_2 = 0
  L8_2 = nil
  L9_2 = true
  L10_2 = nil
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  L2_2 = Combo_Reset
  L3_2 = A0_2
  L2_2(L3_2)
end

Combo_PlayerDamage = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  A0_2.fMeter = 0
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.eTimer
  L1_2(L2_2)
  A0_2.eTimer = nil
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.ePlayerDamage
  L1_2(L2_2)
  A0_2.ePlayerDamage = nil
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.ePlayerDeath
  L1_2(L2_2)
  A0_2.ePlayerDeath = nil
  A0_2.nScore = 0
  A0_2.nCombo = 1
end

Combo_Reset = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.eTimer
  L1_2(L2_2)
  A0_2.eTimer = nil
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.eObjectDestroyed
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.ePlayerDamage
  L1_2(L2_2)
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 1
  L1_2(L2_2, L3_2)
  L1_2 = Hud
  L1_2 = L1_2.ObjectiveTray
  L2_2 = L1_2
  L1_2 = L1_2.ClearSlot
  L3_2 = {}
  L3_2.vPlayer = nil
  L3_2.nSlot = 1
  L1_2(L2_2, L3_2)
end

Combo_Cleanup = L0_1
