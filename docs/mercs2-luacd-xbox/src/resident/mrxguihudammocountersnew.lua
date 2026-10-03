local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGuiBase"
L0_1(L1_1)
L0_1 = 0.4
_knPulseTime = L0_1

function L0_1(A0_2, A1_2)
  if A0_2 < A1_2 then
    return A0_2
  else
    return A1_2
  end
end

Min = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = type
  L3_2 = A1_2.PrimaryCurrentAmmo
  L2_2 = L2_2(L3_2)
  if "number" == L2_2 then
    L2_2 = A1_2.PrimaryCurrentAmmo
    if L2_2 ~= -1 then
      L2_2 = type
      L3_2 = A1_2.PrimaryClipSize
      L2_2 = L2_2(L3_2)
      if "number" == L2_2 then
        L2_2 = A1_2.PrimaryClipSize
        if L2_2 ~= -1 then
          L2_2 = A1_2.PrimaryClipSize
          if L2_2 ~= 0 then
            L3_2 = A0_2
            L2_2 = A0_2.SetText
            L4_2 = A1_2.PrimaryCurrentAmmo
            L2_2(L3_2, L4_2)
            L2_2 = A0_2.CustomData
            L3_2 = L2_2.nPreviousValue
            if L3_2 then
              L3_2 = A1_2.PrimaryClipSize
              if L3_2 then
                L3_2 = L2_2.nRedPoint
                if not L3_2 then
                  L4_2 = A0_2
                  L3_2 = A0_2.AddAnimationPoint
                  L5_2 = {}
                  L5_2.RedLevel = 216
                  L5_2.GreenLevel = 16
                  L5_2.BlueLevel = 16
                  L3_2 = L3_2(L4_2, L5_2)
                  L2_2.nRedPoint = L3_2
                end
                L3_2 = L2_2.nNeutralPoint
                if not L3_2 then
                  L4_2 = A0_2
                  L3_2 = A0_2.GetColor
                  L3_2, L4_2, L5_2 = L3_2(L4_2)
                  L7_2 = A0_2
                  L6_2 = A0_2.AddAnimationPoint
                  L8_2 = {}
                  L8_2.RedLevel = L3_2
                  L8_2.GreenLevel = L4_2
                  L8_2.BlueLevel = L5_2
                  L6_2 = L6_2(L7_2, L8_2)
                  L2_2.nNeutralPoint = L6_2
                end
                L3_2 = A1_2.PrimaryClipSize
                L3_2 = L3_2 / 3
                L4_2 = A1_2.PrimaryCurrentAmmo
                L5_2 = L2_2.bAnimating
                if not L5_2 then
                  if L3_2 > L4_2 then
                    L5_2 = _PulseToRed
                    L6_2 = A0_2
                    L7_2 = _knPulseTime
                    L5_2(L6_2, L7_2)
                    L2_2.bAnimating = true
                    L5_2 = Event
                    L5_2 = L5_2.Post
                    L6_2 = "Ammo low"
                    L7_2 = {}
                    L9_2 = A0_2
                    L8_2 = A0_2.GetOwner
                    L8_2 = L8_2(L9_2)
                    L7_2.uPlayer = L8_2
                    L5_2(L6_2, L7_2)
                  end
                elseif L3_2 <= L4_2 then
                  L6_2 = A0_2
                  L5_2 = A0_2.AnimateToPoint
                  L7_2 = L2_2.nNeutralPoint
                  L8_2 = 0.4
                  L9_2 = true
                  L5_2(L6_2, L7_2, L8_2, L9_2)
                  L2_2.bAnimating = false
                  L5_2 = Event
                  L5_2 = L5_2.Post
                  L6_2 = "Ammo not low"
                  L7_2 = {}
                  L9_2 = A0_2
                  L8_2 = A0_2.GetOwner
                  L8_2 = L8_2(L9_2)
                  L7_2.uPlayer = L8_2
                  L5_2(L6_2, L7_2)
                end
              end
            end
            L3_2 = A1_2.PrimaryCurrentAmmo
            L2_2.nPreviousValue = L3_2
        end
      end
    end
  end
  else
    L3_2 = A0_2
    L2_2 = A0_2.SetText
    L4_2 = " "
    L2_2(L3_2, L4_2)
  end
end

HandleCurrentGunAmmoUpdateEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nRedPoint
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.AnimateToPoint
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.nRedPoint
    L5_2 = A1_2
    L6_2 = true
    L7_2 = _PulseToNeutral
    L8_2 = {}
    L9_2 = A1_2
    L8_2[1] = L9_2
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  end
end

_PulseToRed = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nNeutralPoint
  if L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.AnimateToPoint
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.nNeutralPoint
    L5_2 = A1_2
    L6_2 = true
    L7_2 = _PulseToRed
    L8_2 = {}
    L9_2 = A1_2
    L8_2[1] = L9_2
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  end
end

_PulseToNeutral = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = type
  L3_2 = A1_2.PrimaryClipSize
  L2_2 = L2_2(L3_2)
  if "number" == L2_2 then
    L2_2 = A1_2.PrimaryClipSize
    if L2_2 ~= -1 then
      L2_2 = A1_2.PrimaryClipSize
      if L2_2 ~= 0 then
        L3_2 = A0_2
        L2_2 = A0_2.SetText
        L4_2 = "/"
        L5_2 = A1_2.PrimaryClipSize
        L4_2 = L4_2 .. L5_2
        L2_2(L3_2, L4_2)
    end
  end
  else
    L3_2 = A0_2
    L2_2 = A0_2.SetText
    L4_2 = " "
    L2_2(L3_2, L4_2)
  end
end

HandleCurrentGunClipSizeUpdateEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = type
  L3_2 = A1_2.PrimaryStoredAmmo
  L2_2 = L2_2(L3_2)
  if "number" == L2_2 then
    L2_2 = A1_2.PrimaryStoredAmmo
    if L2_2 ~= -1 then
      L2_2 = type
      L3_2 = A1_2.PrimaryClipSize
      L2_2 = L2_2(L3_2)
      if "number" == L2_2 then
        L2_2 = A1_2.PrimaryClipSize
        if L2_2 ~= -1 then
          L2_2 = A1_2.PrimaryClipSize
          if L2_2 ~= 0 then
            L3_2 = A0_2
            L2_2 = A0_2.SetText
            L4_2 = A1_2.PrimaryStoredAmmo
            L2_2(L3_2, L4_2)
        end
      end
    end
  end
  else
    L3_2 = A0_2
    L2_2 = A0_2.SetText
    L4_2 = " "
    L2_2(L3_2, L4_2)
  end
end

HandleStoredGunAmmoUpdateEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A1_2.PrimaryCurrentAmmo
  if L2_2 then
    L2_2 = A1_2.PrimaryClipSize
    if L2_2 then
      L2_2 = A1_2.PrimaryCurrentAmmo
      if -1 ~= L2_2 then
        L2_2 = A1_2.PrimaryClipSize
        if -1 == L2_2 then
          L3_2 = A0_2
          L2_2 = A0_2.SetText
          L4_2 = A1_2.PrimaryCurrentAmmo
          L2_2(L3_2, L4_2)
      end
      else
        L2_2 = A1_2.PrimaryCurrentAmmo
        if -1 ~= L2_2 then
          L2_2 = A1_2.PrimaryClipSize
          if 0 == L2_2 then
            L3_2 = A0_2
            L2_2 = A0_2.SetText
            L4_2 = A1_2.PrimaryCurrentAmmo
            L2_2(L3_2, L4_2)
        end
        else
          L3_2 = A0_2
          L2_2 = A0_2.SetText
          L4_2 = " "
          L2_2(L3_2, L4_2)
        end
      end
    end
  end
end

HandleUnreloadableGunAmmoUpdateEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = type
  L3_2 = A1_2.ExplosivesStoredAmmo
  L2_2 = L2_2(L3_2)
  if "number" == L2_2 then
    L2_2 = type
    L3_2 = A1_2.ExplosivesCurrentAmmo
    L2_2 = L2_2(L3_2)
    if "number" == L2_2 then
      L2_2 = A1_2.ExplosivesStoredAmmo
      if L2_2 ~= -1 then
        L2_2 = A1_2.ExplosivesCurrentAmmo
        if L2_2 ~= -1 then
          L2_2 = A1_2.ExplosivesCurrentAmmo
          L3_2 = A1_2.ExplosivesStoredAmmo
          L2_2 = L2_2 + L3_2
          L4_2 = A0_2
          L3_2 = A0_2.SetText
          L5_2 = L2_2
          L3_2(L4_2, L5_2)
          L3_2 = A0_2.CustomData
          L4_2 = L3_2.nRedPoint
          if not L4_2 then
            L5_2 = A0_2
            L4_2 = A0_2.AddAnimationPoint
            L6_2 = {}
            L6_2.RedLevel = 216
            L6_2.GreenLevel = 16
            L6_2.BlueLevel = 16
            L4_2 = L4_2(L5_2, L6_2)
            L3_2.nRedPoint = L4_2
          end
          L4_2 = L3_2.nNeutralPoint
          if not L4_2 then
            L5_2 = A0_2
            L4_2 = A0_2.GetColor
            L4_2, L5_2, L6_2 = L4_2(L5_2)
            L8_2 = A0_2
            L7_2 = A0_2.AddAnimationPoint
            L9_2 = {}
            L9_2.RedLevel = L4_2
            L9_2.GreenLevel = L5_2
            L9_2.BlueLevel = L6_2
            L7_2 = L7_2(L8_2, L9_2)
            L3_2.nNeutralPoint = L7_2
          end
          if L2_2 <= 0 then
            L4_2 = L3_2.bAnimating
            if not L4_2 then
              L4_2 = _PulseToRed
              L5_2 = A0_2
              L6_2 = _knPulseTime
              L4_2(L5_2, L6_2)
              L3_2.bAnimating = true
            end
          else
            L4_2 = L3_2.bAnimating
            if L4_2 then
              L5_2 = A0_2
              L4_2 = A0_2.AnimateToPoint
              L6_2 = L3_2.nNeutralPoint
              L7_2 = _knPulseTime
              L8_2 = true
              L4_2(L5_2, L6_2, L7_2, L8_2)
              L3_2.bAnimating = false
            end
          end
      end
    end
  end
  else
    L3_2 = A0_2
    L2_2 = A0_2.SetText
    L4_2 = " "
    L2_2(L3_2, L4_2)
  end
end

HandleExplosivesAmmoUpdateEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nVisibilityTime
  if 0 < L2_2 then
    L2_2 = A0_2.CustomData
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.nRemainingVisibleTime
    L3_2 = L3_2 - A1_2
    L2_2.nRemainingVisibleTime = L3_2
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.nRemainingVisibleTime
    if L2_2 <= 0 then
      L2_2 = A0_2.CustomData
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.nVisibilityTime
      L2_2.nRemainingVisibleTime = L3_2
      L2_2 = A0_2.CustomData
      L2_2 = L2_2.oCounter
      L3_2 = L2_2
      L2_2 = L2_2.AnimateToPoint
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.nFadePoint
      L5_2 = nil
      L6_2 = true
      L7_2 = A0_2.CustomData
      L7_2 = L7_2.oCounter
      L7_2 = L7_2.SetVisible
      L8_2 = {}
      L9_2 = false
      L8_2[1] = L9_2
      L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
      L3_2 = A0_2
      L2_2 = A0_2.SetEventHandler
      L4_2 = "GuiUpdate"
      L5_2 = nil
      L2_2(L3_2, L4_2, L5_2)
    end
  end
end

HandleTopLevelUpdateEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = type
  L3_2 = A1_2.PrimaryStoredAmmo
  L2_2 = L2_2(L3_2)
  if "number" == L2_2 then
    L2_2 = A1_2.PrimaryStoredAmmo
    if L2_2 ~= -1 then
      L2_2 = A1_2.PrimaryStoredAmmo
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.nCachedStoredAmmo
      if L2_2 ~= L3_2 then
        goto lbl_27
      end
    end
  end
  L2_2 = type
  L3_2 = A1_2.PrimaryCurrentAmmo
  L2_2 = L2_2(L3_2)
  if "number" == L2_2 then
    L2_2 = A1_2.PrimaryCurrentAmmo
    if L2_2 ~= -1 then
      L2_2 = A1_2.PrimaryCurrentAmmo
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.nCachedClipAmmo
      ::lbl_27::
      if L2_2 ~= L3_2 then
        L2_2 = A0_2.CustomData
        L3_2 = A1_2.PrimaryCurrentAmmo
        if not L3_2 then
          L3_2 = A0_2.CustomData
          L3_2 = L3_2.nCachedClipAmmo
        end
        L2_2.nCachedClipAmmo = L3_2
        L2_2 = A0_2.CustomData
        L3_2 = A1_2.PrimaryClipSize
        if not L3_2 then
          L3_2 = A0_2.CustomData
          L3_2 = L3_2.nCachedClipSize
        end
        L2_2.nCachedClipSize = L3_2
        L2_2 = A0_2.CustomData
        L3_2 = A1_2.PrimaryStoredAmmo
        L2_2.nCachedStoredAmmo = L3_2
        L2_2 = _ShowForDuration
        L3_2 = A0_2
        L2_2(L3_2)
      end
    end
  end
end

HandleTopLevelGunAmmoUpdateEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = type
  L3_2 = A1_2.ExplosivesStoredAmmo
  L2_2 = L2_2(L3_2)
  if "number" == L2_2 then
    L2_2 = type
    L3_2 = A1_2.ExplosivesCurrentAmmo
    L2_2 = L2_2(L3_2)
    if "number" == L2_2 then
      L2_2 = A1_2.ExplosivesStoredAmmo
      if L2_2 ~= -1 then
        L2_2 = A1_2.ExplosivesCurrentAmmo
        if L2_2 ~= -1 then
          L2_2 = A1_2.ExplosivesStoredAmmo
          L3_2 = A0_2.CustomData
          L3_2 = L3_2.nCachedStoredAmmo
          if L2_2 == L3_2 then
            L2_2 = A1_2.ExplosivesCurrentAmmo
            L3_2 = A0_2.CustomData
            L3_2 = L3_2.nCachedClipAmmo
            if L2_2 == L3_2 then
              goto lbl_36
            end
          end
          L2_2 = A0_2.CustomData
          L3_2 = A1_2.ExplosivesCurrentAmmo
          L2_2.nCachedClipAmmo = L3_2
          L2_2 = A0_2.CustomData
          L3_2 = A1_2.ExplosivesStoredAmmo
          L2_2.nCachedStoredAmmo = L3_2
          L2_2 = _ShowForDuration
          L3_2 = A0_2
          L2_2(L3_2)
        end
      end
    end
  end
  ::lbl_36::
end

HandleTopLevelExplosiveAmmoUpdateEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L3_2 = L2_2[1]
  L4_2 = _WeaponSwitchAccessor
  L3_2.TriggerAnimation = L4_2
  L4_2 = _SetSuppressAnimation
  L3_2.SetSuppressAnimation = L4_2
  L5_2 = L3_2
  L4_2 = L3_2.GetChildren
  L4_2 = L4_2(L5_2)
  L4_2 = L4_2[1]
  L5_2 = L4_2
  L4_2 = L4_2.GetChildren
  L4_2 = L4_2(L5_2)
  L4_2 = L4_2[1]
  L5_2 = L4_2
  L4_2 = L4_2.GetChildren
  L4_2 = L4_2(L5_2)
  L4_2 = L4_2[1]
  L5_2 = MrxGuiBase
  L5_2 = L5_2.PushWidgetToFront
  L6_2 = L4_2
  L5_2(L6_2)
  L5_2 = A0_2.CustomData
  L6_2 = L2_2[1]
  L5_2.oCounter = L6_2
  L5_2 = L2_2[2]
  if L5_2 then
    L5_2 = L2_2[2]
    L6_2 = L5_2.CustomData
    L8_2 = L5_2
    L7_2 = L5_2.AddAnimationPoint
    L9_2 = {}
    L9_2.TranslucencyLevel = 0
    L7_2 = L7_2(L8_2, L9_2)
    L6_2.nFadePoint = L7_2
    L6_2 = L5_2.CustomData
    L8_2 = L5_2
    L7_2 = L5_2.AddAnimationPoint
    L9_2 = {}
    L9_2.TranslucencyLevel = 255
    L7_2 = L7_2(L8_2, L9_2)
    L6_2.nVisiblePoint = L7_2
    L6_2 = A0_2.CustomData
    L6_2.oName = L5_2
    L7_2 = L5_2
    L6_2 = L5_2.SetText
    L8_2 = " "
    L6_2(L7_2, L8_2)
    L7_2 = L5_2
    L6_2 = L5_2.AnimateToPoint
    L8_2 = L5_2.CustomData
    L8_2 = L8_2.nFadePoint
    L9_2 = 0
    L10_2 = true
    L6_2(L7_2, L8_2, L9_2, L10_2)
  end
  L5_2 = _SetUpFadeBehavior
  L6_2 = A0_2
  L5_2(L6_2)
end

HandleTopLevelInitialization = L0_1

function L0_1(A0_2, A1_2)
  local L2_2
  L2_2 = A0_2.CustomData
  L2_2.bSuppress = A1_2
end

_SetSuppressAnimation = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A1_2.bShowGun
  if L2_2 then
    L2_2 = nil
    L3_2 = type
    L4_2 = A1_2.nTime
    L3_2 = L3_2(L4_2)
    if "number" == L3_2 then
      L2_2 = A1_2.nTime
    end
    L3_2 = _ShowForDuration
    L4_2 = A0_2
    L5_2 = L2_2
    L3_2(L4_2, L5_2)
  end
end

HandleGunShowEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A1_2.bShowExplosive
  if L2_2 then
    L2_2 = nil
    L3_2 = type
    L4_2 = A1_2.nTime
    L3_2 = L3_2(L4_2)
    if "number" == L3_2 then
      L2_2 = A1_2.nTime
    end
    L3_2 = _ShowForDuration
    L4_2 = A0_2
    L5_2 = L2_2
    L3_2(L4_2, L5_2)
  end
end

HandleExplosiveShowEvent = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bHaveWeapon
  if not L2_2 then
    return
  end
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nCachedClipAmmo
  if L2_2 then
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.nCachedClipSize
    if L2_2 then
      L2_2 = A0_2.CustomData
      L2_2 = L2_2.nCachedClipAmmo
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.nCachedClipSize
      L3_2 = L3_2 / 3
      if not (L2_2 < L3_2) then
        L2_2 = A0_2.CustomData
        L2_2 = L2_2.nCachedClipAmmo
        if not (L2_2 <= 0) then
          goto lbl_26
        end
      end
      A1_2 = -1
    end
  end
  ::lbl_26::
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oCounter
  L3_2 = L2_2
  L2_2 = L2_2.SetTranslucency
  L4_2 = 255
  L2_2(L3_2, L4_2)
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oCounter
  L3_2 = L2_2
  L2_2 = L2_2.AnimateToPoint
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nVisiblePoint
  L5_2 = 0
  L6_2 = true
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L3_2 = A0_2
  L2_2 = A0_2.SetVisible
  L4_2 = true
  L2_2(L3_2, L4_2)
  if not A1_2 then
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.nVisibilityTime
    if 0 < L2_2 then
      L2_2 = A0_2.CustomData
      L3_2 = A0_2.CustomData
      L3_2 = L3_2.nVisibilityTime
      L2_2.nRemainingVisibleTime = L3_2
      L3_2 = A0_2
      L2_2 = A0_2.SetEventHandler
      L4_2 = "GuiUpdate"
      L5_2 = HandleTopLevelUpdateEvent
      L2_2(L3_2, L4_2, L5_2)
    end
  elseif 0 == A1_2 then
    L3_2 = A0_2
    L2_2 = A0_2.SetEventHandler
    L4_2 = "GuiUpdate"
    L5_2 = nil
    L2_2(L3_2, L4_2, L5_2)
  elseif 0 < A1_2 then
    L2_2 = A0_2.CustomData
    L2_2.nRemainingVisibleTime = A1_2
    L3_2 = A0_2
    L2_2 = A0_2.SetEventHandler
    L4_2 = "GuiUpdate"
    L5_2 = HandleTopLevelUpdateEvent
    L2_2(L3_2, L4_2, L5_2)
  else
    L3_2 = A0_2
    L2_2 = A0_2.SetEventHandler
    L4_2 = "GuiUpdate"
    L5_2 = nil
    L2_2(L3_2, L4_2, L5_2)
  end
end

_ShowForDuration = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A1_2.uNewCurrentGun
  if L2_2 then
    L2_2 = type
    L3_2 = A1_2.uNewCurrentGun
    L2_2 = L2_2(L3_2)
    if "string" ~= L2_2 then
      L2_2 = type
      L3_2 = A1_2.uNewCurrentGun
      L2_2 = L2_2(L3_2)
      if "userdata" ~= L2_2 then
        goto lbl_42
      end
    end
    L2_2 = A0_2.CustomData
    L2_2.bHaveWeapon = true
    L2_2 = _ShowForDuration
    L3_2 = A0_2
    L2_2(L3_2)
    L2_2 = A1_2.uNewCurrentGunGuid
    if L2_2 then
      L2_2 = Object
      L2_2 = L2_2.GetLocalizedName
      L3_2 = A1_2.uNewCurrentGunGuid
      L2_2 = L2_2(L3_2)
      if L2_2 then
        L3_2 = A0_2.CustomData
        L3_2 = L3_2.oName
        L5_2 = L3_2
        L4_2 = L3_2.SetText
        L6_2 = L2_2
        L4_2(L5_2, L6_2)
        L5_2 = L3_2
        L4_2 = L3_2.AnimateToPoint
        L6_2 = L3_2.CustomData
        L6_2 = L6_2.nVisiblePoint
        L7_2 = 0
        L8_2 = true
        L9_2 = _NameDelay
        L10_2 = {}
        L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
        goto lbl_44
        ::lbl_42::
        L2_2 = A0_2.CustomData
        L2_2.bHaveWeapon = false
      end
    end
  end
  ::lbl_44::
end

HandleGunSwitchEvent = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2
  L1_2 = A0_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nVisiblePoint
  L4_2 = 1
  L5_2 = true
  L6_2 = A0_2.AnimateToPoint
  L7_2 = {}
  L8_2 = A0_2.CustomData
  L8_2 = L8_2.nFadePoint
  L9_2 = 1
  L10_2 = true
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L7_2[3] = L10_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
end

_NameDelay = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = A1_2.uNewCurrentExplosive
  if L2_2 then
    L2_2 = type
    L3_2 = A1_2.uNewCurrentExplosive
    L2_2 = L2_2(L3_2)
    if "string" ~= L2_2 then
      L2_2 = type
      L3_2 = A1_2.uNewCurrentExplosive
      L2_2 = L2_2(L3_2)
      if "userdata" ~= L2_2 then
        goto lbl_20
      end
    end
    L2_2 = A0_2.CustomData
    L2_2.bHaveWeapon = true
    L2_2 = _ShowForDuration
    L3_2 = A0_2
    L2_2(L3_2)
    goto lbl_22
    ::lbl_20::
    L2_2 = A0_2.CustomData
    L2_2.bHaveWeapon = false
  end
  ::lbl_22::
end

HandleExplosiveSwitchEvent = L0_1

function L0_1(A0_2)
  local L1_2
  return L1_2
end

FindEquippedSupportTexture = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A1_2.bOn
  if L2_2 then
    L2_2 = A0_2.CustomData
    L2_2.bE3HudMode = true
    L2_2 = MrxGuiBase
    L2_2 = L2_2.RemoveWidgetWithChildren
    L4_2 = A0_2
    L3_2 = A0_2.GetChildren
    L3_2 = L3_2(L4_2)
    L3_2 = L3_2[1]
    L2_2(L3_2)
    L2_2 = MrxGuiBase
    L2_2 = L2_2.RemoveWidgetWithChildren
    L4_2 = A0_2
    L3_2 = A0_2.GetChildren
    L3_2 = L3_2(L4_2)
    L3_2 = L3_2[2]
    L2_2(L3_2)
  else
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.bE3HudMode
    if L2_2 then
      L2_2 = A0_2.CustomData
      L2_2.bE3HudMode = nil
      L2_2 = MrxGuiBase
      L2_2 = L2_2.AddWidgetWithChildren
      L4_2 = A0_2
      L3_2 = A0_2.GetChildren
      L3_2 = L3_2(L4_2)
      L3_2 = L3_2[1]
      L2_2(L3_2)
      L2_2 = MrxGuiBase
      L2_2 = L2_2.AddWidgetWithChildren
      L4_2 = A0_2
      L3_2 = A0_2.GetChildren
      L3_2 = L3_2(L4_2)
      L3_2 = L3_2[2]
      L2_2(L3_2)
    end
  end
end

HandleE3HudModeEvent = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = A0_2.CustomData
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oCounter
  L3_2 = L2_2
  L2_2 = L2_2.AddAnimationPoint
  L4_2 = {}
  L4_2.TranslucencyLevel = 0
  L4_2.nAnimationTime = 1
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.nFadePoint = L2_2
  L1_2 = A0_2.CustomData
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.oCounter
  L3_2 = L2_2
  L2_2 = L2_2.AddAnimationPoint
  L4_2 = {}
  L4_2.TranslucencyLevel = 255
  L2_2 = L2_2(L3_2, L4_2)
  L1_2.nVisiblePoint = L2_2
  L1_2 = A0_2.CustomData
  L1_2.nVisibilityTime = 3
  L1_2 = A0_2.CustomData
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.nVisibilityTime
  L1_2.nRemainingVisibleTime = L2_2
  L1_2 = A0_2.CustomData
  L1_2.nCachedClipAmmo = 0
  L1_2 = A0_2.CustomData
  L1_2.nCachedStoredAmmo = 0
end

_SetUpFadeBehavior = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.nNormalColorPoint
  if not L1_2 then
    L1_2 = A0_2.CustomData
    L3_2 = A0_2
    L2_2 = A0_2.AddAnimationPoint
    L4_2 = {}
    L4_2.RedLevel = 255
    L4_2.GreenLevel = 255
    L4_2.BlueLevel = 255
    L2_2 = L2_2(L3_2, L4_2)
    L1_2.nNormalColorPoint = L2_2
  end
  L2_2 = A0_2
  L1_2 = A0_2.SetColor
  L3_2 = 0
  L4_2 = 216
  L5_2 = 0
  L1_2(L2_2, L3_2, L4_2, L5_2)
  L2_2 = A0_2
  L1_2 = A0_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nNormalColorPoint
  L4_2 = 2
  L5_2 = true
  L1_2(L2_2, L3_2, L4_2, L5_2)
end

_GreenFade = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = A0_2.CustomData
  L2_2.uNewTexture = A1_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bHavePoints
  if not L2_2 then
    L2_2 = _SetUpFlippingPoints
    L3_2 = A0_2
    L2_2(L3_2)
    L2_2 = MrxGuiBase
    L2_2 = L2_2.PushWidgetToFront
    L4_2 = A0_2
    L3_2 = A0_2.GetChildren
    L3_2 = L3_2(L4_2)
    L3_2 = L3_2[1]
    L2_2(L3_2)
  end
  L3_2 = A0_2
  L2_2 = A0_2.AnimateToPoint
  L4_2 = A0_2.CustomData
  L4_2 = L4_2.nClosePoint
  L5_2 = 0.15
  L6_2 = true
  L7_2 = _SwitchTexture
  L8_2 = {}
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
end

_PerformIconSwitchAnimation = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = type
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.uNewTexture
  L1_2 = L1_2(L2_2)
  if "userdata" ~= L1_2 then
    L1_2 = type
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.uNewTexture
    L1_2 = L1_2(L2_2)
    if "string" ~= L1_2 then
      goto lbl_36
    end
  end
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L1_2 = L1_2[1]
  L2_2 = L1_2
  L1_2 = L1_2.SetTexture
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.uNewTexture
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L1_2 = L1_2[1]
  L2_2 = L1_2
  L1_2 = L1_2.SetVisible
  L3_2 = true
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.SetVisible
  L3_2 = true
  L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L1_2 = A0_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nStartPoint
  L4_2 = 0.15
  L5_2 = true
  L1_2(L2_2, L3_2, L4_2, L5_2)
  goto lbl_39
  ::lbl_36::
  L2_2 = A0_2
  L1_2 = A0_2.SetVisible
  L3_2 = false
  L1_2(L2_2, L3_2)
  ::lbl_39::
end

_SwitchTexture = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = A0_2.CustomData
  L1_2.bHavePoints = true
  L2_2 = A0_2
  L1_2 = A0_2.GetLocation
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  L5_2 = L4_2 + L2_2
  L5_2 = L5_2 * 0.5
  L6_2 = A0_2.CustomData
  L8_2 = A0_2
  L7_2 = A0_2.AddAnimationPoint
  L9_2 = {}
  L9_2.x = L1_2
  L9_2.y = L2_2
  L9_2.x2 = L3_2
  L9_2.y2 = L4_2
  L7_2 = L7_2(L8_2, L9_2)
  L6_2.nStartPoint = L7_2
  L6_2 = A0_2.CustomData
  L8_2 = A0_2
  L7_2 = A0_2.AddAnimationPoint
  L9_2 = {}
  L9_2.x = L1_2
  L9_2.y = L5_2
  L9_2.x2 = L3_2
  L9_2.y2 = L5_2
  L7_2 = L7_2(L8_2, L9_2)
  L6_2.nClosePoint = L7_2
end

_SetUpFlippingPoints = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.bHavePoints
  if not L3_2 then
    L3_2 = _SetUpFlippingPoints
    L4_2 = A0_2
    L3_2(L4_2)
  end
  L4_2 = A0_2
  L3_2 = A0_2.AnimateToPoint
  L5_2 = A0_2.CustomData
  L5_2 = L5_2.nClosePoint
  L6_2 = 0.15
  L7_2 = true
  L8_2 = A1_2
  L9_2 = A2_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
end

_AnimateFrameClose = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = A0_2.CustomData
  L1_2 = L1_2.bHavePoints
  if not L1_2 then
    L1_2 = _SetUpFlippingPoints
    L2_2 = A0_2
    L1_2(L2_2)
  end
  L2_2 = A0_2
  L1_2 = A0_2.AnimateToPoint
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.nStartPoint
  L4_2 = 0.15
  L5_2 = true
  L6_2 = _SetTextVisible
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = true
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
end

_AnimateFrameOpen = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = A1_2.ParentWidget
  if L3_2 then
    L3_2 = A1_2.ParentWidget
    L3_2 = L3_2.ParentWidget
    if L3_2 then
      L3_2 = A1_2.ParentWidget
      L3_2 = L3_2.ParentWidget
      L4_2 = L3_2
      L3_2 = L3_2.GetChildren
      L3_2 = L3_2(L4_2)
      L4_2 = L3_2[2]
      if L4_2 then
        L4_2 = L3_2[2]
        L4_2 = L4_2.CustomData
        L4_2.bSuppressVisibilityChange = false
        L4_2 = L3_2[2]
        L5_2 = L4_2
        L4_2 = L4_2.SetVisible
        L6_2 = A2_2
        L7_2 = true
        L4_2(L5_2, L6_2, L7_2)
      end
      L4_2 = L3_2[3]
      if L4_2 then
        L4_2 = L3_2[3]
        L4_2 = L4_2.CustomData
        L4_2.bSuppressVisibilityChange = false
        L4_2 = L3_2[3]
        L5_2 = L4_2
        L4_2 = L4_2.SetVisible
        L6_2 = A2_2
        L7_2 = true
        L4_2(L5_2, L6_2, L7_2)
      end
      L4_2 = L3_2[4]
      if L4_2 then
        L4_2 = L3_2[4]
        L4_2 = L4_2.CustomData
        L4_2.bSuppressVisibilityChange = false
        L4_2 = L3_2[4]
        L5_2 = L4_2
        L4_2 = L4_2.SetVisible
        L6_2 = A2_2
        L7_2 = true
        L4_2(L5_2, L6_2, L7_2)
      end
    end
  end
end

_SetTextVisible = L0_1
L0_1 = 0.5
_knRotateTime = L0_1
L0_1 = 0.05
_knRotateDelay = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = L6_2.BasicData
    L7_2 = L7_2.type
    if "image" == L7_2 then
      L8_2 = L6_2
      L7_2 = L6_2.GetRotation
      L7_2 = L7_2(L8_2)
      L8_2 = L6_2.CustomData
      L8_2.nOriginalRotation = L7_2
      if 1 == L5_2 then
        L8_2 = L6_2.CustomData
        L10_2 = L6_2
        L9_2 = L6_2.AddAnimationPoint
        L11_2 = {}
        L12_2 = L7_2 + 180
        L11_2.nRotation = L12_2
        L11_2.nRotationDirection = -1
        L9_2 = L9_2(L10_2, L11_2)
        L8_2.nPoint = L9_2
      else
        L8_2 = L6_2.CustomData
        L10_2 = L6_2
        L9_2 = L6_2.AddAnimationPoint
        L11_2 = {}
        L12_2 = L7_2 + 180
        L11_2.nRotation = L12_2
        L11_2.nRotationDirection = 1
        L9_2 = L9_2(L10_2, L11_2)
        L8_2.nPoint = L9_2
      end
    end
  end
  L2_2 = _AnimateBackgroundRotation
  A0_2.Animate = L2_2
end

_InitializeRotationAnimation = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2
  L1_2 = A0_2.GetChildren
  L1_2 = L1_2(L2_2)
  L1_2 = L1_2[2]
  L3_2 = L1_2
  L2_2 = L1_2.AnimateToPoint
  L4_2 = L1_2.CustomData
  L4_2 = L4_2.nPoint
  L5_2 = _knRotateTime
  L6_2 = true
  L7_2 = L1_2.SetRotation
  L8_2 = {}
  L9_2 = L1_2.CustomData
  L9_2 = L9_2.nOriginalRotation
  L8_2[1] = L9_2
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.TimerRelative
  L4_2 = {}
  L5_2 = _knRotateDelay
  L4_2[1] = L5_2
  L5_2 = _AnimateNext
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = 3
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
end

_AnimateBackgroundRotation = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L2_2 = L2_2[A1_2]
  L3_2 = false
  if not L2_2 then
    L5_2 = A0_2
    L4_2 = A0_2.GetChildren
    L4_2 = L4_2(L5_2)
    L2_2 = L4_2[1]
    L3_2 = true
  end
  if L2_2 then
    L5_2 = L2_2
    L4_2 = L2_2.AnimateToPoint
    L6_2 = L2_2.CustomData
    L6_2 = L6_2.nPoint
    L7_2 = _knRotateTime
    L8_2 = true
    L9_2 = L2_2.SetRotation
    L10_2 = {}
    L11_2 = L2_2.CustomData
    L11_2 = L11_2.nOriginalRotation
    L10_2[1] = L11_2
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
    if not L3_2 then
      L4_2 = Event
      L4_2 = L4_2.Create
      L5_2 = Event
      L5_2 = L5_2.TimerRelative
      L6_2 = {}
      L7_2 = _knRotateDelay
      L6_2[1] = L7_2
      L7_2 = _AnimateNext
      L8_2 = {}
      L9_2 = A0_2
      L10_2 = A1_2 + 1
      L8_2[1] = L9_2
      L8_2[2] = L10_2
      L4_2(L5_2, L6_2, L7_2, L8_2)
    end
  end
end

_AnimateNext = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A1_2.uNewCurrentGun
  if L2_2 then
    L2_2 = A0_2.CustomData
    L2_2 = L2_2.bSuppress
    if L2_2 then
      L2_2 = A0_2.CustomData
      L2_2.bSuppress = false
      L2_2 = A0_2.CustomData
      L2_2.bWaitingForSupport = true
    else
      L2_2 = _BeginWeaponSwitchAnimation
      L3_2 = A0_2
      L4_2 = A1_2.uNewCurrentGun
      L2_2(L3_2, L4_2)
      L2_2 = A0_2.CustomData
      L2_2.bWaitingForSupport = false
    end
  end
end

HandleGunSwitchForAnimation = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A1_2.uNewCurrentExplosive
  if L2_2 then
    L2_2 = _BeginWeaponSwitchAnimation
    L3_2 = A0_2
    L4_2 = A1_2.uNewCurrentExplosive
    L2_2(L3_2, L4_2)
  end
end

HandleExplosiveSwitchForAnimation = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bWaitingForSupport
  if L2_2 then
    L2_2 = _BeginWeaponSwitchAnimation
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
    L2_2 = A0_2.CustomData
    L2_2.bWaitingForSupport = false
  end
end

_WeaponSwitchAccessor = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L3_2 = A0_2.CustomData
  L3_2 = L3_2.bAnimating
  if L3_2 then
    L3_2 = A0_2.CustomData
    L3_2 = L3_2.nTime
    if 0.2 <= L3_2 then
      L3_2 = A0_2.CustomData
      L3_2.uNewWeapon = A1_2
      L3_2 = _PerformIconSwitchAnimation
      L4_2 = L2_2[1]
      L5_2 = L4_2
      L4_2 = L4_2.GetChildren
      L4_2 = L4_2(L5_2)
      L4_2 = L4_2[1]
      L5_2 = A0_2.CustomData
      L5_2 = L5_2.uNewWeapon
      L3_2(L4_2, L5_2)
    else
      L3_2 = A0_2.CustomData
      L3_2.uNewWeapon = A1_2
    end
  else
    L4_2 = A0_2
    L3_2 = A0_2.SetEventHandler
    L5_2 = "GuiUpdate"
    L6_2 = _UpdateControllingWidget
    L3_2(L4_2, L5_2, L6_2)
    L3_2 = A0_2.CustomData
    L3_2.nTime = 0
    L3_2 = A0_2.CustomData
    L3_2.uNewWeapon = A1_2
    L3_2 = A0_2.CustomData
    L3_2.bAnimating = true
    L3_2 = type
    L4_2 = A0_2.CustomData
    L4_2 = L4_2.uNewWeapon
    L3_2 = L3_2(L4_2)
    if "userdata" ~= L3_2 then
      L3_2 = type
      L4_2 = A0_2.CustomData
      L4_2 = L4_2.uNewWeapon
      L3_2 = L3_2(L4_2)
      if "string" ~= L3_2 then
        goto lbl_60
      end
    end
    L4_2 = A0_2
    L3_2 = A0_2.GetChildren
    L3_2 = L3_2(L4_2)
    L3_2 = L3_2[1]
    L4_2 = L3_2
    L3_2 = L3_2.GetChildren
    L3_2 = L3_2(L4_2)
    L4_2 = L3_2[2]
    L5_2 = L3_2[4]
    L7_2 = L5_2
    L6_2 = L5_2.SetVisible
    L8_2 = true
    L6_2(L7_2, L8_2)
    L7_2 = L4_2
    L6_2 = L4_2.SetVisible
    L8_2 = true
    L6_2(L7_2, L8_2)
    ::lbl_60::
    L3_2 = _AnimateBullet
    L4_2 = L2_2[1]
    L5_2 = L4_2
    L4_2 = L4_2.GetChildren
    L4_2 = L4_2(L5_2)
    L4_2 = L4_2[4]
    L5_2 = 1
    L3_2(L4_2, L5_2)
    L3_2 = L2_2[2]
    if L3_2 then
      L3_2 = _SetUpCustomTextVisibility
      L4_2 = L2_2[2]
      L3_2(L4_2)
      L3_2 = L2_2[2]
      L4_2 = L3_2
      L3_2 = L3_2.SetVisible
      L5_2 = false
      L3_2(L4_2, L5_2)
      L3_2 = L2_2[2]
      L3_2 = L3_2.CustomData
      L3_2.bSuppressVisibilityChange = true
    end
    L3_2 = L2_2[3]
    if L3_2 then
      L3_2 = _SetUpCustomTextVisibility
      L4_2 = L2_2[3]
      L3_2(L4_2)
      L3_2 = L2_2[3]
      L4_2 = L3_2
      L3_2 = L3_2.SetVisible
      L5_2 = false
      L3_2(L4_2, L5_2)
      L3_2 = L2_2[3]
      L3_2 = L3_2.CustomData
      L3_2.bSuppressVisibilityChange = true
    end
    L3_2 = L2_2[4]
    if L3_2 then
      L3_2 = _SetUpCustomTextVisibility
      L4_2 = L2_2[4]
      L3_2(L4_2)
      L3_2 = L2_2[4]
      L4_2 = L3_2
      L3_2 = L3_2.SetVisible
      L5_2 = false
      L3_2(L4_2, L5_2)
      L3_2 = L2_2[4]
      L3_2 = L3_2.CustomData
      L3_2.bSuppressVisibilityChange = true
    end
  end
end

_BeginWeaponSwitchAnimation = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2.RealSetVisible
  if not L1_2 then
    L1_2 = A0_2.SetVisible
    A0_2.RealSetVisible = L1_2
    L1_2 = _CustomSetVisible
    A0_2.SetVisible = L1_2
  end
end

_SetUpCustomTextVisibility = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A0_2.CustomData
  L2_2 = L2_2.bSuppressVisibilityChange
  if not L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.RealSetVisible
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  end
end

_CustomSetVisible = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  if not A1_2 then
    return
  end
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L2_2 = L2_2[1]
  L3_2 = L2_2
  L2_2 = L2_2.GetChildren
  L2_2 = L2_2(L3_2)
  L3_2 = L2_2[1]
  L4_2 = L2_2[2]
  L5_2 = L2_2[3]
  L6_2 = L2_2[4]
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.nTime
  if not L7_2 then
    L7_2 = A0_2.CustomData
    L7_2.nTime = 0
  end
  L7_2 = A0_2.CustomData
  L7_2 = L7_2.nTime
  L8_2 = L7_2 + A1_2
  L9_2 = _PassedPoint
  L10_2 = L7_2
  L11_2 = L8_2
  L12_2 = 0.05
  L9_2 = L9_2(L10_2, L11_2, L12_2)
  if L9_2 then
    L9_2 = _AnimateBullet
    L10_2 = L6_2
    L11_2 = 2
    L9_2(L10_2, L11_2)
  end
  L9_2 = _PassedPoint
  L10_2 = L7_2
  L11_2 = L8_2
  L12_2 = 0.1
  L9_2 = L9_2(L10_2, L11_2, L12_2)
  if L9_2 then
    L9_2 = _AnimateBullet
    L10_2 = L6_2
    L11_2 = 3
    L9_2(L10_2, L11_2)
  end
  L9_2 = _PassedPoint
  L10_2 = L7_2
  L11_2 = L8_2
  L12_2 = 0.15
  L9_2 = L9_2(L10_2, L11_2, L12_2)
  if L9_2 then
    L9_2 = _AnimateBullet
    L10_2 = L6_2
    L11_2 = 4
    L9_2(L10_2, L11_2)
  end
  L9_2 = _PassedPoint
  L10_2 = L7_2
  L11_2 = L8_2
  L12_2 = 0.2
  L9_2 = L9_2(L10_2, L11_2, L12_2)
  if L9_2 then
    L9_2 = _AnimateBullet
    L10_2 = L6_2
    L11_2 = 5
    L9_2(L10_2, L11_2)
    L9_2 = _PerformIconSwitchAnimation
    L10_2 = L3_2
    L11_2 = A0_2.CustomData
    L11_2 = L11_2.uNewWeapon
    L9_2(L10_2, L11_2)
  end
  L9_2 = _PassedPoint
  L10_2 = L7_2
  L11_2 = L8_2
  L12_2 = 0.25
  L9_2 = L9_2(L10_2, L11_2, L12_2)
  if L9_2 then
    L9_2 = _AnimateBullet
    L10_2 = L6_2
    L11_2 = 0
    L9_2(L10_2, L11_2)
  end
  L9_2 = _PassedPoint
  L10_2 = L7_2
  L11_2 = L8_2
  L12_2 = 0.36
  L9_2 = L9_2(L10_2, L11_2, L12_2)
  if L9_2 then
    L9_2 = type
    L10_2 = A0_2.CustomData
    L10_2 = L10_2.uNewWeapon
    L9_2 = L9_2(L10_2)
    if "userdata" ~= L9_2 then
      L9_2 = type
      L10_2 = A0_2.CustomData
      L10_2 = L10_2.uNewWeapon
      L9_2 = L9_2(L10_2)
      if "string" ~= L9_2 then
        goto lbl_112
      end
    end
    L10_2 = L5_2
    L9_2 = L5_2.SetVisible
    L11_2 = true
    L9_2(L10_2, L11_2)
    L9_2 = _AnimateFrameClose
    L10_2 = L5_2
    L11_2 = _AnimateFrameOpen
    L12_2 = {}
    L13_2 = L5_2
    L12_2[1] = L13_2
    L9_2(L10_2, L11_2, L12_2)
    goto lbl_125
    ::lbl_112::
    L10_2 = L6_2
    L9_2 = L6_2.SetVisible
    L11_2 = false
    L9_2(L10_2, L11_2)
    L10_2 = L4_2
    L9_2 = L4_2.SetVisible
    L11_2 = false
    L9_2(L10_2, L11_2)
    L9_2 = _AnimateFrameClose
    L10_2 = L5_2
    L11_2 = L5_2.SetVisible
    L12_2 = {}
    L13_2 = false
    L12_2[1] = L13_2
    L9_2(L10_2, L11_2, L12_2)
    ::lbl_125::
    L10_2 = A0_2
    L9_2 = A0_2.SetEventHandler
    L11_2 = "GuiUpdate"
    L12_2 = nil
    L9_2(L10_2, L11_2, L12_2)
    L9_2 = A0_2.CustomData
    L9_2.bAnimating = false
  end
  L9_2 = A0_2.CustomData
  L9_2.nTime = L8_2
end

_UpdateControllingWidget = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  A1_2 = A1_2 + 1
  L3_2 = A0_2
  L2_2 = A0_2.GetChildren
  L2_2 = L2_2(L3_2)
  L2_2 = L2_2[A1_2]
  oChild = L2_2
  L2_2 = oChild
  if L2_2 then
    L2_2 = oChild
    L3_2 = L2_2
    L2_2 = L2_2.AnimateToPoint
    L4_2 = oChild
    L4_2 = L4_2.CustomData
    L4_2 = L4_2.nPoint
    L5_2 = _knRotateTime
    L6_2 = true
    L7_2 = oChild
    L7_2 = L7_2.SetRotation
    L8_2 = {}
    L9_2 = oChild
    L9_2 = L9_2.CustomData
    L9_2 = L9_2.nOriginalRotation
    L8_2[1] = L9_2
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  end
end

_AnimateBullet = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2
  if A0_2 < A1_2 then
    if A0_2 < A2_2 and A2_2 <= A1_2 then
      L3_2 = true
      return L3_2
    end
  elseif A1_2 < A0_2 and A2_2 < A0_2 and A1_2 <= A2_2 then
    L3_2 = true
    return L3_2
  end
  L3_2 = false
  return L3_2
end

_PassedPoint = L0_1
