local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1, L18_1, L19_1, L20_1, L21_1
L0_1 = inherit
L1_1 = "Blippable"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPlayState"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTutorialManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxMunitionsPickup"
L0_1(L1_1)
L0_1 = 175
_kDistance = L0_1
L0_1 = {}
L1_1 = "artillery"
L2_1 = "bombingrun"
L3_1 = "bunkerbuster"
L4_1 = "carpetbomb"
L5_1 = "clusterbomb"
L6_1 = "combatairpatrol"
L7_1 = "cruisemissile"
L8_1 = "daisycutter"
L9_1 = "fuelairbomb"
L10_1 = "harm"
L11_1 = "laserguidedbomb"
L12_1 = "moab"
L13_1 = "rocketartillery"
L14_1 = "smartbomb"
L15_1 = "strategicmissile"
L16_1 = "surgicalstrike"
L17_1 = "tankbuster"
L18_1 = {}
L18_1.nFuel = 50
L19_1 = {}
L19_1.nFuel = 500
L20_1 = {}
L20_1.nFuel = 5000
L21_1 = {}
L21_1.nCash = 100000
L0_1[1] = L1_1
L0_1[2] = L2_1
L0_1[3] = L3_1
L0_1[4] = L4_1
L0_1[5] = L5_1
L0_1[6] = L6_1
L0_1[7] = L7_1
L0_1[8] = L8_1
L0_1[9] = L9_1
L0_1[10] = L10_1
L0_1[11] = L11_1
L0_1[12] = L12_1
L0_1[13] = L13_1
L0_1[14] = L14_1
L0_1[15] = L15_1
L0_1[16] = L16_1
L0_1[17] = L17_1
L0_1[18] = L18_1
L0_1[19] = L19_1
L0_1[20] = L20_1
L0_1[21] = L21_1
L1_1 = 0
_nTagged = L1_1

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = Event
  L3_2 = L3_2.Create
  L4_2 = Event
  L4_2 = L4_2.ObjectHibernation
  L5_2 = {}
  L6_2 = A0_2
  L7_2 = "awake"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = Awake
  L7_2 = {}
  L8_2 = A0_2
  L9_2 = A2_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
end

OnActivate = L1_1
L1_1 = {}
_tHideEvents = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = Object
  L2_2 = L2_2.IsAlive
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L2_2 = L0_1
  L2_2 = L2_2[A1_2]
  if not L2_2 then
  end
  L2_2 = getfenv
  L2_2 = L2_2()
  L4_2 = L2_2
  L3_2 = L2_2.Create
  L5_2 = A0_2
  L6_2 = A1_2
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L3_2.nStock = A1_2
  L4_2 = IsSupport
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  if L4_2 then
    L3_2.sTexture = "radar_Munition"
    L4_2 = {}
    L5_2 = 51
    L6_2 = 102
    L7_2 = 51
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L4_2[3] = L7_2
    L3_2.tColor = L4_2
    L4_2 = {}
    L5_2 = 255
    L6_2 = 255
    L7_2 = 255
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L4_2[3] = L7_2
    L3_2.tFlash = L4_2
    L3_2.nSize = 8
    L4_2 = {}
    L4_2.sTexture = "pickup_munitions"
    L5_2 = {}
    L6_2 = 153
    L7_2 = 255
    L8_2 = 153
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L4_2.tColor = L5_2
    L4_2.nSize = 40
    L4_2.nNearDist = 5
    L4_2.nFarDist = 100
    L3_2.tMarker = L4_2
  else
    L4_2 = IsFuel
    L5_2 = A1_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      L3_2.sTexture = "radar_Oil"
      L4_2 = {}
      L5_2 = 51
      L6_2 = 102
      L7_2 = 51
      L4_2[1] = L5_2
      L4_2[2] = L6_2
      L4_2[3] = L7_2
      L3_2.tColor = L4_2
      L4_2 = {}
      L5_2 = 255
      L6_2 = 255
      L7_2 = 255
      L4_2[1] = L5_2
      L4_2[2] = L6_2
      L4_2[3] = L7_2
      L3_2.tFlash = L4_2
      L3_2.nSize = 8
      L4_2 = {}
      L4_2.sTexture = "pickup_fuel_2"
      L5_2 = {}
      L6_2 = 153
      L7_2 = 255
      L8_2 = 153
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      L5_2[3] = L8_2
      L4_2.tColor = L5_2
      L4_2.nSize = 40
      L4_2.nNearDist = 5
      L4_2.nFarDist = 100
      L3_2.tMarker = L4_2
    else
      L4_2 = IsCash
      L5_2 = A1_2
      L4_2 = L4_2(L5_2)
      if L4_2 then
        L3_2.sTexture = "radar_Money"
        L4_2 = {}
        L5_2 = 51
        L6_2 = 102
        L7_2 = 51
        L4_2[1] = L5_2
        L4_2[2] = L6_2
        L4_2[3] = L7_2
        L3_2.tColor = L4_2
        L4_2 = {}
        L5_2 = 255
        L6_2 = 255
        L7_2 = 255
        L4_2[1] = L5_2
        L4_2[2] = L6_2
        L4_2[3] = L7_2
        L3_2.tFlash = L4_2
        L3_2.nSize = 8
        L4_2 = {}
        L4_2.sTexture = "pickup_cash_2"
        L5_2 = {}
        L6_2 = 153
        L7_2 = 255
        L8_2 = 153
        L5_2[1] = L6_2
        L5_2[2] = L7_2
        L5_2[3] = L8_2
        L4_2.tColor = L5_2
        L4_2.nSize = 40
        L4_2.nNearDist = 5
        L4_2.nFarDist = 100
        L3_2.tMarker = L4_2
      end
    end
  end
  L5_2 = L3_2
  L4_2 = L3_2.AddContextAction
  L4_2(L5_2)
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.ObjectProximity
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = Player
  L8_2 = L8_2.GetLocalCharacter
  L8_2 = L8_2()
  L9_2 = "<"
  L10_2 = _kDistance
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L7_2 = L3_2.Near
  L8_2 = {}
  L9_2 = L3_2
  L8_2[1] = L9_2
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L3_2.NearnessEvent = L4_2
end

Awake = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = tInstance
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L2_2 = MrxMunitionsPickup
    L2_2 = L2_2.bPickupInProgress
    if L2_2 then
      L2_2 = L1_2.bPickedUp
      if not L2_2 then
        L2_2 = PickupMunitions
        L3_2 = A0_2
        L2_2(L3_2)
      end
    end
  end
  L2_2 = Blippable
  L2_2 = L2_2.OnDeactivate
  L3_2 = A0_2
  L2_2(L3_2)
end

OnDeactivate = L1_1

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxTutorialManager
  L1_2 = L1_2.HideMessage
  L2_2 = true
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = _tHideEvents
  L2_2 = L2_2[A0_2]
  L1_2(L2_2)
  L1_2 = _tHideEvents
  L1_2[A0_2] = nil
end

HideTutorialMessage = L1_1
L1_1 = 30
_nBlippedVOCoolDownTime = L1_1
L1_1 = false
_bAllowBlippedVO = L1_1
L1_1 = nil
_eBlippedVOCoolDown = L1_1

function L1_1(A0_2)
  local L1_2
  _bAllowBlippedVO = A0_2
end

SetAllowBlippedVO = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = _bAllowBlippedVO
  if not L2_2 then
    L2_2 = _eBlippedVOCoolDown
    if L2_2 == nil then
      L2_2 = Event
      L2_2 = L2_2.Create
      L3_2 = Event
      L3_2 = L3_2.TimerRelative
      L4_2 = {}
      L5_2 = 10
      L4_2[1] = L5_2
      L5_2 = SetAllowBlippedVO
      L6_2 = {}
      L7_2 = true
      L6_2[1] = L7_2
      L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
      _eBlippedVOCoolDown = L2_2
    end
    return
  end
  L2_2 = AreMunitionsTaggable
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = _bPlayedCashHint2
    if not L2_2 then
      L2_2 = IsCash
      L3_2 = A0_2
      L2_2 = L2_2(L3_2)
      if L2_2 then
        L1_2 = "Fiona.Misc.Cash01"
    end
    else
      L2_2 = _bPlayedFuelHint2
      if not L2_2 then
        L2_2 = IsFuel
        L3_2 = A0_2
        L2_2 = L2_2(L3_2)
        if L2_2 then
          L1_2 = "Fiona.Misc.Fuel01"
      end
      else
        L2_2 = _bPlayedSupportHint2
        if not L2_2 then
          L2_2 = IsSupport
          L3_2 = A0_2
          L2_2 = L2_2(L3_2)
          if L2_2 then
            L1_2 = "Fiona.Misc.Munition02"
          end
        end
      end
    end
  else
    L2_2 = _bPlayedCashHint1
    if not L2_2 then
      L2_2 = IsCash
      L3_2 = A0_2
      L2_2 = L2_2(L3_2)
      if L2_2 then
        L1_2 = "Fiona.Misc.Cash02"
    end
    else
      L2_2 = _bPlayedFuelHint1
      if not L2_2 then
        L2_2 = IsFuel
        L3_2 = A0_2
        L2_2 = L2_2(L3_2)
        if L2_2 then
          L1_2 = "Fiona.Misc.Fuel02"
      end
      else
        L2_2 = _bPlayedSupportHint1
        if not L2_2 then
          L2_2 = IsSupport
          L3_2 = A0_2
          L2_2 = L2_2(L3_2)
          if L2_2 then
            L1_2 = "Fiona.Misc.Munition01"
          end
        end
      end
    end
  end
  if L1_2 then
    L2_2 = MrxVoSequence
    L2_2 = L2_2.Start
    L3_2 = L1_2
    L4_2 = false
    L5_2 = MrxVoSequence
    L5_2 = L5_2.knPriorityFreeplay
    L6_2 = false
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
    if L2_2 then
      L2_2 = SetAllowBlippedVO
      L3_2 = false
      L2_2(L3_2)
      L2_2 = Event
      L2_2 = L2_2.Create
      L3_2 = Event
      L3_2 = L3_2.TimerRelative
      L4_2 = {}
      L5_2 = _nBlippedVOCoolDownTime
      L4_2[1] = L5_2
      L5_2 = SetAllowBlippedVO
      L6_2 = {}
      L7_2 = true
      L6_2[1] = L7_2
      L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
      _eBlippedVOCoolDown = L2_2
      L2_2 = AreMunitionsTaggable
      L2_2 = L2_2()
      if L2_2 then
        L2_2 = IsCash
        L3_2 = A0_2
        L2_2 = L2_2(L3_2)
        if L2_2 then
          L2_2 = true
          _bPlayedCashHint2 = L2_2
        else
          L2_2 = IsFuel
          L3_2 = A0_2
          L2_2 = L2_2(L3_2)
          if L2_2 then
            L2_2 = true
            _bPlayedFuelHint2 = L2_2
          else
            L2_2 = IsSupport
            L3_2 = A0_2
            L2_2 = L2_2(L3_2)
            if L2_2 then
              L2_2 = true
              _bPlayedSupportHint2 = L2_2
            end
          end
        end
      else
        L2_2 = IsCash
        L3_2 = A0_2
        L2_2 = L2_2(L3_2)
        if L2_2 then
          L2_2 = true
          _bPlayedCashHint1 = L2_2
        else
          L2_2 = IsFuel
          L3_2 = A0_2
          L2_2 = L2_2(L3_2)
          if L2_2 then
            L2_2 = true
            _bPlayedFuelHint1 = L2_2
          else
            L2_2 = IsSupport
            L3_2 = A0_2
            L2_2 = L2_2(L3_2)
            if L2_2 then
              L2_2 = true
              _bPlayedSupportHint1 = L2_2
            end
          end
        end
      end
    end
  end
end

PlayBlippedVO = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = A0_2.nStock
  L2_2 = MrxPlayState
  L2_2 = L2_2.IsFree
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = PlayBlippedVO
    L3_2 = L1_2
    L2_2(L3_2)
  end
  L2_2 = Event
  L2_2 = L2_2.Delete
  L3_2 = A0_2.NearnessEvent
  L2_2(L3_2)
  A0_2.NearnessEvent = nil
  L3_2 = A0_2
  L2_2 = A0_2.SetBlipped
  L2_2(L3_2)
  L2_2 = Net
  L2_2 = L2_2.IsClient
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = Net
    L2_2 = L2_2.SendCustomEvent
    L3_2 = "Munitions"
    L4_2 = NETEVENT_ISMUNITIONTAGGED
    L5_2 = {}
    L6_2 = A0_2.uGuid
    L5_2[1] = L6_2
    L2_2(L3_2, L4_2, L5_2)
  end
  L2_2 = Event
  L2_2 = L2_2.Create
  L3_2 = Event
  L3_2 = L3_2.ObjectProximity
  L4_2 = {}
  L5_2 = A0_2.uGuid
  L6_2 = Player
  L6_2 = L6_2.GetLocalCharacter
  L6_2 = L6_2()
  L7_2 = ">"
  L8_2 = _kDistance
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = A0_2.Far
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  A0_2.FarnessEvent = L2_2
end

Near = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = Event
  L1_2 = L1_2.Delete
  L2_2 = A0_2.FarnessEvent
  L1_2(L2_2)
  A0_2.FarnessEvent = nil
  L2_2 = A0_2
  L1_2 = A0_2.ClearBlipped
  L1_2(L2_2)
  L1_2 = Event
  L1_2 = L1_2.Create
  L2_2 = Event
  L2_2 = L2_2.ObjectProximity
  L3_2 = {}
  L4_2 = A0_2.uGuid
  L5_2 = Player
  L5_2 = L5_2.GetLocalCharacter
  L5_2 = L5_2()
  L6_2 = "<"
  L7_2 = _kDistance
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L4_2 = A0_2.Near
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  A0_2.NearnessEvent = L1_2
end

Far = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = Net
  L1_2 = L1_2.IsClient
  L1_2 = L1_2()
  if L1_2 then
    return
  end
  L1_2 = A0_2.uGuid
  L2_2 = A0_2.nStock
  L3_2 = Object
  L3_2 = L3_2.HasLabel
  L4_2 = L1_2
  L5_2 = "Vehicle"
  L3_2 = L3_2(L4_2, L5_2)
  if L3_2 then
    L3_2 = table
    L3_2 = L3_2.getn
    L4_2 = Vehicle
    L4_2 = L4_2.GetRiders
    L5_2 = L1_2
    L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L4_2(L5_2)
    L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
    if 0 < L3_2 then
      L3_2 = Event
      L3_2 = L3_2.Create
      L4_2 = Event
      L4_2 = L4_2.ObjectInSeat
      L5_2 = {}
      L6_2 = "Human"
      L7_2 = L1_2
      L8_2 = "a"
      L9_2 = "x"
      L5_2[1] = L6_2
      L5_2[2] = L7_2
      L5_2[3] = L8_2
      L5_2[4] = L9_2
      
      function L6_2()
        local L0_3, L1_3, L2_3, L3_3
        L0_3 = OnActivate
        L1_3 = L1_2
        L2_3 = nil
        L3_3 = L2_2
        L0_3(L1_3, L2_3, L3_3)
      end
      
      L3_2 = L3_2(L4_2, L5_2, L6_2)
      A0_2.VehicleExitEvent = L3_2
      return
    end
  end
  L3_2 = tostring
  L4_2 = Object
  L4_2 = L4_2.GetLocalizedName
  L5_2 = L1_2
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L4_2(L5_2)
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L4_2 = "[ContextAction.TagMunition:"
  L5_2 = L3_2
  L6_2 = "]"
  L4_2 = L4_2 .. L5_2 .. L6_2
  L5_2 = IsFuel
  L6_2 = L2_2
  L5_2 = L5_2(L6_2)
  if L5_2 then
    L4_2 = "[ContextAction.TagFuel]"
  else
    L5_2 = IsCash
    L6_2 = L2_2
    L5_2 = L5_2(L6_2)
    if L5_2 then
      L4_2 = "[ContextAction.TagCash]"
    end
  end
  L5_2 = AreMunitionsTaggable
  L5_2 = L5_2()
  if not L5_2 then
    L5_2 = "[neut]"
    L6_2 = L4_2
    L4_2 = L5_2 .. L6_2
  end
  L5_2 = Pg
  L5_2 = L5_2.AddContextAction
  L6_2 = L1_2
  L7_2 = L4_2
  L8_2 = -3
  L9_2 = 0
  L10_2 = 0
  L11_2 = 0
  L12_2 = 0
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L5_2 = Event
  L5_2 = L5_2.Create
  L6_2 = Event
  L5_2 = L6_2.CreatePersistent
  L6_2 = L5_2
  L7_2 = Event
  L7_2 = L7_2.ContextAction
  L8_2 = {}
  L9_2 = Player
  L9_2 = L9_2.GetAnyCharacter
  L9_2 = L9_2()
  L10_2 = L1_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L9_2 = A0_2.Actioned
  L10_2 = {}
  L11_2 = A0_2
  L10_2[1] = L11_2
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
  A0_2.TagEvent = L6_2
  L6_2 = Object
  L6_2 = L6_2.HasLabel
  L7_2 = L1_2
  L8_2 = "Vehicle"
  L6_2 = L6_2(L7_2, L8_2)
  if L6_2 then
    L6_2 = Event
    L6_2 = L6_2.CreatePersistent
    L7_2 = Event
    L7_2 = L7_2.ObjectInSeat
    L8_2 = {}
    L9_2 = "Human"
    L10_2 = L1_2
    L11_2 = "a"
    L12_2 = "e"
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L8_2[4] = L12_2
    L9_2 = A0_2.HumanControlled
    L10_2 = {}
    L11_2 = A0_2
    L10_2[1] = L11_2
    L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
    A0_2.VehicleEnterEvent = L6_2
  end
end

AddContextAction = L1_1

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = Player
  L3_2 = L3_2.GetLocalCharacter
  L3_2 = L3_2()
  if A1_2 ~= L3_2 then
    L3_2 = Net
    L3_2 = L3_2.IsServer
    L3_2 = L3_2()
    if L3_2 then
      L3_2 = Net
      L3_2 = L3_2.SendCustomEvent
      L4_2 = "Munitions"
      L5_2 = NETEVENT_CLIENTSTOCKPILEQUERY
      L6_2 = {}
      L7_2 = A0_2
      L8_2 = A2_2
      L6_2[1] = L7_2
      L6_2[2] = L8_2
      L3_2(L4_2, L5_2, L6_2)
    end
    L3_2 = false
    return L3_2
  end
  L3_2 = L0_1
  L3_2 = L3_2[A2_2]
  L4_2 = AreMunitionsTaggable
  L4_2 = L4_2()
  if not L4_2 then
    L4_2 = _tHideEvents
    L4_2 = L4_2[A0_2]
    if not L4_2 then
      L4_2 = MrxTutorialManager
      L4_2 = L4_2.ShowMessage
      L5_2 = "[support.munition.needpilot]"
      L6_2 = true
      L4_2 = L4_2(L5_2, L6_2)
      if L4_2 then
        L4_2 = _tHideEvents
        L5_2 = Event
        L5_2 = L5_2.Create
        L6_2 = Event
        L6_2 = L6_2.TimerRelative
        L7_2 = {}
        L8_2 = 5
        L7_2[1] = L8_2
        L8_2 = HideTutorialMessage
        L9_2 = {}
        L10_2 = A0_2
        L9_2[1] = L10_2
        L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
        L4_2[A0_2] = L5_2
      end
    end
    L4_2 = false
    return L4_2
  end
  L4_2 = IsFuel
  L5_2 = A2_2
  L4_2 = L4_2(L5_2)
  if L4_2 then
    L4_2 = MrxPmc
    L4_2 = L4_2.GetFuelQty
    L4_2 = L4_2()
    L5_2 = MrxPmc
    L5_2 = L5_2.GetFuelCapacity
    L5_2 = L5_2()
    if L4_2 >= L5_2 then
      L4_2 = MrxTutorialManager
      L4_2 = L4_2.ShowMessage
      L5_2 = "[support.munition.fuelfull]"
      L6_2 = true
      L4_2 = L4_2(L5_2, L6_2)
      if L4_2 then
        L4_2 = _tHideEvents
        L5_2 = Event
        L5_2 = L5_2.Create
        L6_2 = Event
        L6_2 = L6_2.TimerRelative
        L7_2 = {}
        L8_2 = 5
        L7_2[1] = L8_2
        L8_2 = HideTutorialMessage
        L9_2 = {}
        L10_2 = A0_2
        L9_2[1] = L10_2
        L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
        L4_2[A0_2] = L5_2
      end
      L4_2 = false
      return L4_2
    end
  end
  L4_2 = type
  L5_2 = L3_2
  L4_2 = L4_2(L5_2)
  if L4_2 == "string" then
    L4_2 = MrxSupportData
    L4_2 = L4_2.tSupportData
    L4_2 = L4_2[L3_2]
    L5_2 = MrxPmc
    L5_2 = L5_2.GetSupportQty
    L6_2 = L3_2
    L5_2 = L5_2(L6_2)
    if L5_2 then
      L6_2 = L4_2.nMaxStock
      if L5_2 >= L6_2 then
        L6_2 = MrxTutorialManager
        L6_2 = L6_2.ShowMessage
        L7_2 = "[support.munition.full:"
        L8_2 = L4_2.sName
        L9_2 = "]"
        L7_2 = L7_2 .. L8_2 .. L9_2
        L8_2 = true
        L6_2 = L6_2(L7_2, L8_2)
        if L6_2 then
          L6_2 = _tHideEvents
          L7_2 = Event
          L7_2 = L7_2.Create
          L8_2 = Event
          L8_2 = L8_2.TimerRelative
          L9_2 = {}
          L10_2 = 5
          L9_2[1] = L10_2
          L10_2 = HideTutorialMessage
          L11_2 = {}
          L12_2 = A0_2
          L11_2[1] = L12_2
          L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
          L6_2[A0_2] = L7_2
        end
        L6_2 = false
        return L6_2
      end
    end
  end
  L4_2 = true
  return L4_2
end

CanActionTarget = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2.bTagged
  if L2_2 then
    return
  end
  L2_2 = A0_2.uGuid
  L3_2 = A0_2.nStock
  L4_2 = CanActionTarget
  L5_2 = L2_2
  L6_2 = A1_2
  L7_2 = L3_2
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  if L4_2 then
    L4_2 = ActionTarget
    L5_2 = L2_2
    L4_2(L5_2)
  end
end

Actioned = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = tInstance
  L1_2 = L1_2[A0_2]
  L2_2 = Pg
  L2_2 = L2_2.RemoveContextAction
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = GetFromGuid
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L4_2 = L2_2
    L3_2 = L2_2.RemoveObjective
    L3_2(L4_2)
    L3_2 = {}
    L4_2 = 0
    L5_2 = 255
    L6_2 = 0
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L2_2.tColor = L3_2
    L3_2 = L2_2.tMarker
    L4_2 = {}
    L5_2 = 0
    L6_2 = 255
    L7_2 = 0
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L4_2[3] = L7_2
    L3_2.tColor = L4_2
    L4_2 = L2_2
    L3_2 = L2_2.AddObjective
    L5_2 = false
    L3_2(L4_2, L5_2)
  end
  L3_2 = Marker
  L3_2 = L3_2.Pulse
  L4_2 = A0_2
  L5_2 = 0
  L6_2 = 255
  L7_2 = 0
  L3_2(L4_2, L5_2, L6_2, L7_2)
  L3_2 = Net
  L3_2 = L3_2.SendCustomEvent
  L4_2 = "Munitions"
  L5_2 = NETEVENT_MARKERPULSE
  L6_2 = {}
  L7_2 = A0_2
  L6_2[1] = L7_2
  L3_2(L4_2, L5_2, L6_2)
  L1_2.bTagged = true
  L3_2 = _nTagged
  L3_2 = L3_2 + 1
  _nTagged = L3_2
  L3_2 = {}
  L4_2 = "Fiona.Support.Munitions02"
  L5_2 = "Fiona.Support.Munitions03"
  L6_2 = {}
  L6_2.chris = "Chris-In-Mission-Contract-Oil02-55"
  L6_2.mattias = "Mattias-In-Mission-Contract-Oil02-53"
  L6_2.jennifer = "Jennifer-In-Mission-Contract-Oil02-54"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L4_2 = {}
  L5_2 = MrxUtil
  L5_2 = L5_2.GetRandomTableElement
  L6_2 = L3_2
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L5_2 = MrxVoSequence
  L5_2 = L5_2.Start
  L6_2 = L4_2
  L7_2 = nil
  L8_2 = MrxVoSequence
  L8_2 = L8_2.knPriorityFreeplay
  L5_2(L6_2, L7_2, L8_2)
  L5_2 = _nTagged
  if L5_2 == 1 then
    L5_2 = MrxSupportData
    L5_2 = L5_2.AddFreebie
    L6_2 = "MunitionsPickup"
    L5_2(L6_2)
  end
end

ActionTarget = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2.uGuid
  L3_2 = A0_2.nStock
  L5_2 = A0_2
  L4_2 = A0_2.Delete
  L4_2(L5_2)
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.ObjectInSeat
  L6_2 = {}
  L7_2 = A1_2
  L8_2 = L2_2
  L9_2 = "a"
  L10_2 = "x"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  
  function L7_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = OnActivate
    L1_3 = L2_2
    L2_3 = nil
    L3_3 = L3_2
    L0_3(L1_3, L2_3, L3_3)
  end
  
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  A0_2.VehicleExitEvent = L4_2
end

HumanControlled = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = A0_2.uGuid
  L2_2 = Event
  L2_2 = L2_2.Post
  L3_2 = "UntagMunitions"
  L4_2 = {}
  L5_2 = L1_2
  L4_2[1] = L5_2
  L2_2(L3_2, L4_2)
  L2_2 = Net
  L2_2 = L2_2.IsClient
  L2_2 = L2_2()
  if not L2_2 then
    L2_2 = Pg
    L2_2 = L2_2.RemoveContextAction
    L3_2 = L1_2
    L2_2(L3_2)
  end
  L3_2 = A0_2
  L2_2 = A0_2.ClearBlipped
  L2_2(L3_2)
  L2_2 = A0_2.TagEvent
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = A0_2.TagEvent
    L2_2(L3_2)
    A0_2.TagEvent = nil
  end
  L2_2 = A0_2.VehicleEnterEvent
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = A0_2.VehicleEnterEvent
    L2_2(L3_2)
    A0_2.VehicleEnterEvent = nil
  end
  L2_2 = A0_2.VehicleExitEvent
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = A0_2.VehicleExitEvent
    L2_2(L3_2)
    A0_2.VehicleExitEvent = nil
  end
  L2_2 = A0_2.NearnessEvent
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = A0_2.NearnessEvent
    L2_2(L3_2)
    A0_2.NearnessEvent = nil
  end
  L2_2 = A0_2.FarnessEvent
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = A0_2.FarnessEvent
    L2_2(L3_2)
    A0_2.FarnessEvent = nil
  end
  L2_2 = A0_2.bTagged
  if L2_2 then
    A0_2.bTagged = nil
    L2_2 = _nTagged
    L2_2 = L2_2 - 1
    _nTagged = L2_2
  end
  A0_2.bPickedUp = nil
  L2_2 = A0_2._uHideMessage
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = A0_2._uHideMessage
    L2_2(L3_2)
    A0_2._uHideMessage = nil
  end
  L2_2 = Net
  L2_2 = L2_2.IsClient
  L2_2 = L2_2()
  if not L2_2 then
    L2_2 = _nTagged
    if L2_2 < 1 then
      L2_2 = MrxSupportData
      L2_2 = L2_2.RemoveFreebie
      L3_2 = "MunitionsPickup"
      L2_2(L3_2)
      L2_2 = Event
      L2_2 = L2_2.Post
      L3_2 = "NoMunitions"
      L4_2 = {}
      L2_2(L3_2, L4_2)
    end
  end
  L2_2 = Blippable
  L2_2 = L2_2.Delete
  L3_2 = A0_2
  L2_2(L3_2)
end

Delete = L1_1

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = Inheritable
  L1_2 = L1_2.OnDeath
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Net
  L1_2 = L1_2.IsClient
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = Pg
    L1_2 = L1_2.RemoveContextAction
    L2_2 = A0_2
    L1_2(L2_2)
  end
end

OnDeath = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = L0_1
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L2_2 = type
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    if L2_2 == "table" then
      L2_2 = L1_2.nCash
      if L2_2 then
        L2_2 = true
        return L2_2
      end
    end
  end
  L2_2 = false
  return L2_2
end

IsCash = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = L0_1
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L2_2 = type
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    if L2_2 == "table" then
      L2_2 = L1_2.nFuel
      if L2_2 then
        L2_2 = true
        return L2_2
      end
    end
  end
  L2_2 = false
  return L2_2
end

IsFuel = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = L0_1
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L2_2 = type
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    if L2_2 == "string" then
      L2_2 = true
      return L2_2
    end
  end
  L2_2 = false
  return L2_2
end

IsSupport = L1_1
L1_1 = true
_bMunitionsTaggable = L1_1
L1_1 = false
_bPlayedCashHint1 = L1_1
L1_1 = false
_bPlayedFuelHint1 = L1_1
L1_1 = false
_bPlayedSupportHint1 = L1_1
L1_1 = false
_bPlayedCashHint2 = L1_1
L1_1 = false
_bPlayedFuelHint2 = L1_1
L1_1 = false
_bPlayedSupportHint2 = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 == "boolean" then
    L1_2 = _bMunitionsTaggable
    _bMunitionsTaggable = A0_2
    L2_2 = Net
    L2_2 = L2_2.IsClient
    L2_2 = L2_2()
    if not L2_2 and L1_2 ~= A0_2 then
      L2_2 = RefreshMunitions
      L2_2()
    end
    L2_2 = Net
    L2_2 = L2_2.IsServer
    L2_2 = L2_2()
    if L2_2 then
      L2_2 = 0
      L3_2 = _bMunitionsTaggable
      if L3_2 then
        L2_2 = 1
      end
      L3_2 = Net
      L3_2 = L3_2.SendCustomEvent
      L4_2 = "Munitions"
      L5_2 = NETEVENT_SETTAGGABLE
      L6_2 = {}
      L7_2 = L2_2
      L6_2[1] = L7_2
      L3_2(L4_2, L5_2, L6_2)
    end
  end
end

SetMunitionsTaggable = L1_1

function L1_1()
  local L0_2, L1_2
  L0_2 = _bMunitionsTaggable
  return L0_2
end

AreMunitionsTaggable = L1_1

function L1_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L0_2 = pairs
  L1_2 = tInstance
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = Object
    L5_2 = L5_2.IsAlive
    L6_2 = L3_2
    L5_2 = L5_2(L6_2)
    if L5_2 then
      L5_2 = L4_2.bTagged
      if not L5_2 then
        L5_2 = L4_2.bPickedUp
        if not L5_2 then
          L5_2 = nil
          L6_2 = L4_2.nStock
          L7_2 = IsSupport
          L8_2 = L6_2
          L7_2 = L7_2(L8_2)
          if L7_2 then
            L7_2 = "[ContextAction.TagMunition:"
            L8_2 = tostring
            L9_2 = Object
            L9_2 = L9_2.GetLocalizedName
            L10_2 = L3_2
            L9_2, L10_2, L11_2, L12_2, L13_2, L14_2 = L9_2(L10_2)
            L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
            L9_2 = "]"
            L5_2 = L7_2 .. L8_2 .. L9_2
          else
            L7_2 = IsCash
            L8_2 = L6_2
            L7_2 = L7_2(L8_2)
            if L7_2 then
              L5_2 = "[ContextAction.TagCash]"
            else
              L7_2 = IsFuel
              L8_2 = L6_2
              L7_2 = L7_2(L8_2)
              if L7_2 then
                L5_2 = "[ContextAction.TagFuel]"
              end
            end
          end
          if L5_2 then
            L7_2 = AreMunitionsTaggable
            L7_2 = L7_2()
            if not L7_2 then
              L7_2 = "[neut]"
              L8_2 = L5_2
              L5_2 = L7_2 .. L8_2
            end
            L7_2 = Pg
            L7_2 = L7_2.AddContextAction
            L8_2 = L3_2
            L9_2 = L5_2
            L10_2 = -3
            L11_2 = 0
            L12_2 = 0
            L13_2 = 0
            L14_2 = 0
            L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
          end
        end
      end
    end
  end
end

RefreshMunitions = L1_1

function L1_1()
  local L0_2, L1_2
  L0_2 = {}
  L1_2 = AreMunitionsTaggable
  L1_2 = L1_2()
  L0_2.bMunitionsTaggable = L1_2
  L1_2 = _bPlayedCashHint1
  L0_2.bPlayedCashHint1 = L1_2
  L1_2 = _bPlayedFuelHint1
  L0_2.bPlayedFuelHint1 = L1_2
  L1_2 = _bPlayedSupportHint1
  L0_2.bPlayedSupportHint1 = L1_2
  L1_2 = _bPlayedCashHint2
  L0_2.bPlayedCashHint2 = L1_2
  L1_2 = _bPlayedFuelHint2
  L0_2.bPlayedFuelHint2 = L1_2
  L1_2 = _bPlayedSupportHint2
  L0_2.bPlayedSupportHint2 = L1_2
  L1_2 = _bPlayedFirstFuelPickupVO
  L0_2.bPlayedFirstFuelPickupVO = L1_2
  return L0_2
end

SaveSingleton = L1_1

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 == "table" then
    L1_2 = SetMunitionsTaggable
    L2_2 = A0_2.bMunitionsTaggable
    L1_2(L2_2)
    L1_2 = A0_2.bPlayedCashHint1
    _bPlayedCashHint1 = L1_2
    L1_2 = A0_2.bPlayedFuelHint1
    _bPlayedFuelHint1 = L1_2
    L1_2 = A0_2.bPlayedSupportHint1
    _bPlayedSupportHint1 = L1_2
    L1_2 = A0_2.bPlayedCashHint2
    _bPlayedCashHint2 = L1_2
    L1_2 = A0_2.bPlayedFuelHint2
    _bPlayedFuelHint2 = L1_2
    L1_2 = A0_2.bPlayedSupportHint2
    _bPlayedSupportHint2 = L1_2
    L1_2 = A0_2.bPlayedFirstFuelPickupVO
    _bPlayedFirstFuelPickupVO = L1_2
  end
end

LoadSingleton = L1_1

function L1_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = pairs
  L1_2 = tInstance
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = PickupMunitions
    L6_2 = L3_2
    L5_2(L6_2)
  end
end

PickupAllMunitions = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = MrxGui
  L1_2 = L1_2.GetWidgetByNameAndOwner
  L2_2 = "PDA"
  L3_2 = Player
  L3_2 = L3_2.GetLocalPlayer
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L3_2()
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  if not L1_2 then
    return
  end
  L2_2 = tInstance
  L2_2 = L2_2[A0_2]
  tThisInstance = L2_2
  L2_2 = tThisInstance
  if not L2_2 then
    return
  end
  L2_2 = tThisInstance
  L2_2 = L2_2.bTagged
  if L2_2 then
    L2_2 = tThisInstance
    L2_2 = L2_2.uGuid
    L3_2 = tThisInstance
    L3_2 = L3_2.nStock
    L4_2 = L0_1
    L4_2 = L4_2[L3_2]
    L5_2 = nil
    L6_2 = IsSupport
    L7_2 = L3_2
    L6_2 = L6_2(L7_2)
    if L6_2 then
      L6_2 = Event
      L6_2 = L6_2.Post
      L7_2 = "MunitionsPickup"
      L8_2 = {}
      L9_2 = L4_2
      L10_2 = L2_2
      L8_2[1] = L9_2
      L8_2[2] = L10_2
      L6_2(L7_2, L8_2)
      L6_2 = MrxPmc
      L6_2 = L6_2.AddSupportQty
      L7_2 = L4_2
      L8_2 = 1
      L9_2 = true
      L6_2(L7_2, L8_2, L9_2)
      L7_2 = L1_2
      L6_2 = L1_2.UpdateSupport
      L8_2 = L4_2
      L9_2 = nil
      L10_2 = nil
      L11_2 = MrxPmc
      L11_2 = L11_2.GetSupportQty
      L12_2 = L4_2
      L11_2, L12_2 = L11_2(L12_2)
      L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
      L5_2 = true
    else
      L6_2 = IsFuel
      L7_2 = L3_2
      L6_2 = L6_2(L7_2)
      if L6_2 then
        L6_2 = _bPlayedFirstFuelPickupVO
        if not L6_2 then
          L6_2 = MrxVoSequence
          L6_2 = L6_2.Start
          L7_2 = {}
          L8_2 = "Fiona-In-Mission-Freeplay-None-25"
          L7_2[1] = L8_2
          L8_2 = nil
          L9_2 = MrxVoSequence
          L9_2 = L9_2.knPriorityFreeplay
          L10_2 = false
          L6_2(L7_2, L8_2, L9_2, L10_2)
          L6_2 = true
          _bPlayedFirstFuelPickupVO = L6_2
        end
        L6_2 = Event
        L6_2 = L6_2.Post
        L7_2 = "MunitionsPickup"
        L8_2 = {}
        L9_2 = "Fuel"
        L10_2 = L2_2
        L8_2[1] = L9_2
        L8_2[2] = L10_2
        L6_2(L7_2, L8_2)
        L6_2 = MrxPmc
        L6_2 = L6_2.AddFuelQty
        L7_2 = L4_2.nFuel
        L6_2(L7_2)
        L5_2 = true
      else
        L6_2 = IsCash
        L7_2 = L3_2
        L6_2 = L6_2(L7_2)
        if L6_2 then
          L6_2 = Event
          L6_2 = L6_2.Post
          L7_2 = "MunitionsPickup"
          L8_2 = {}
          L9_2 = "Cash"
          L10_2 = L2_2
          L8_2[1] = L9_2
          L8_2[2] = L10_2
          L6_2(L7_2, L8_2)
          L6_2 = MrxPmc
          L6_2 = L6_2.AddCashQty
          L7_2 = L4_2.nCash
          L8_2 = nil
          L9_2 = "[Generic.Pickups]"
          L6_2(L7_2, L8_2, L9_2)
          L5_2 = true
        end
      end
    end
    if L5_2 then
      L6_2 = Net
      L6_2 = L6_2.IsServer
      L6_2 = L6_2()
      if L6_2 then
        L6_2 = Net
        L6_2 = L6_2.SendCustomEvent
        L7_2 = "Munitions"
        L8_2 = NETEVENT_PICKUP
        L9_2 = {}
        L10_2 = L3_2
        L9_2[1] = L10_2
        L6_2(L7_2, L8_2, L9_2)
      end
    end
    L6_2 = tThisInstance
    L6_2.bPickedUp = true
    L6_2 = OnDeactivate
    L7_2 = L2_2
    L6_2(L7_2)
    L6_2 = Object
    L6_2 = L6_2.IsWinched
    L7_2 = L2_2
    L6_2 = L6_2(L7_2)
    if not L6_2 then
      L6_2 = Object
      L6_2 = L6_2.IsAwake
      L7_2 = L2_2
      L6_2 = L6_2(L7_2)
      if L6_2 then
        L6_2 = Object
        L6_2 = L6_2.FadeOut
        L7_2 = L2_2
        L8_2 = 2
        L9_2 = true
        L6_2(L7_2, L8_2, L9_2)
      else
        L6_2 = Object
        L6_2 = L6_2.Remove
        L7_2 = L2_2
        L6_2(L7_2)
      end
    else
    end
  end
end

PickupMunitions = L1_1

function L1_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = pairs
  L1_2 = tInstance
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = L4_2.bTagged
    if L5_2 then
      L5_2 = L4_2.uGuid
      return L5_2
    end
  end
end

GetTaggedMunition = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = pairs
  L2_2 = tInstance
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    if L4_2 == A0_2 then
      L6_2 = L5_2.bTagged
      return L6_2
    end
  end
end

IsMunitionTagged = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = GetFromGuid
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L3_2 = L1_2
    L2_2 = L1_2.RemoveObjective
    L2_2(L3_2)
    L2_2 = {}
    L3_2 = 0
    L4_2 = 255
    L5_2 = 0
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
    L1_2.tColor = L2_2
    L2_2 = L1_2.tMarker
    L3_2 = {}
    L4_2 = 0
    L5_2 = 255
    L6_2 = 0
    L3_2[1] = L4_2
    L3_2[2] = L5_2
    L3_2[3] = L6_2
    L2_2.tColor = L3_2
    L3_2 = L1_2
    L2_2 = L1_2.AddObjective
    L4_2 = false
    L2_2(L3_2, L4_2)
  end
  L2_2 = Marker
  L2_2 = L2_2.Pulse
  L3_2 = A0_2
  L4_2 = 0
  L5_2 = 255
  L6_2 = 0
  L2_2(L3_2, L4_2, L5_2, L6_2)
end

ClientTagAndBlip = L1_1

function L1_1()
  local L0_2, L1_2
  L0_2 = _nTagged
  if 0 < L0_2 then
    L0_2 = nTagged
    return L0_2
  else
    L0_2 = false
    L1_2 = "nomunitions"
    return L0_2, L1_2
  end
end

GetMunitionsCount = L1_1
L1_1 = 0
NETEVENT_SETTAGGABLE = L1_1
L1_1 = 1
NETEVENT_CLIENTSTOCKPILEQUERY = L1_1
L1_1 = 2
NETEVENT_CLIENTSTOCKPILEACK = L1_1
L1_1 = 3
NETEVENT_PICKUP = L1_1
L1_1 = 4
NETEVENT_MARKERPULSE = L1_1
L1_1 = 5
NETEVENT_ISMUNITIONTAGGED = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = NETEVENT_SETTAGGABLE
  if A0_2 == L2_2 then
    L2_2 = A1_2[1]
    if L2_2 == 1 then
      L2_2 = SetMunitionsTaggable
      L3_2 = true
      L2_2(L3_2)
    else
      L2_2 = SetMunitionsTaggable
      L3_2 = false
      L2_2(L3_2)
    end
  else
    L2_2 = NETEVENT_CLIENTSTOCKPILEQUERY
    if A0_2 == L2_2 then
      L2_2 = Net
      L2_2 = L2_2.IsClient
      L2_2 = L2_2()
      if L2_2 then
        L2_2 = CanActionTarget
        L3_2 = A1_2[1]
        L4_2 = Player
        L4_2 = L4_2.GetLocalCharacter
        L4_2 = L4_2()
        L5_2 = A1_2[2]
        L2_2 = L2_2(L3_2, L4_2, L5_2)
        if L2_2 then
          L2_2 = Net
          L2_2 = L2_2.SendCustomEvent
          L3_2 = "Munitions"
          L4_2 = NETEVENT_CLIENTSTOCKPILEACK
          L5_2 = {}
          L6_2 = A1_2[1]
          L7_2 = 1
          L5_2[1] = L6_2
          L5_2[2] = L7_2
          L2_2(L3_2, L4_2, L5_2)
        else
          L2_2 = Net
          L2_2 = L2_2.SendCustomEvent
          L3_2 = "Munitions"
          L4_2 = NETEVENT_CLIENTSTOCKPILEACK
          L5_2 = {}
          L6_2 = A1_2[1]
          L7_2 = 0
          L5_2[1] = L6_2
          L5_2[2] = L7_2
          L2_2(L3_2, L4_2, L5_2)
        end
      end
    else
      L2_2 = NETEVENT_CLIENTSTOCKPILEACK
      if A0_2 == L2_2 then
        L2_2 = A1_2[2]
        if L2_2 == 1 then
          L2_2 = ActionTarget
          L3_2 = A1_2[1]
          L2_2(L3_2)
        end
      else
        L2_2 = NETEVENT_PICKUP
        if A0_2 == L2_2 then
          L2_2 = A1_2[1]
          L3_2 = L0_1
          L3_2 = L3_2[L2_2]
          L4_2 = IsSupport
          L5_2 = L2_2
          L4_2 = L4_2(L5_2)
          if L4_2 then
            L4_2 = MrxPmc
            L4_2 = L4_2.AddSupportQty
            L5_2 = L3_2
            L6_2 = 1
            L7_2 = true
            L4_2(L5_2, L6_2, L7_2)
            L4_2 = MrxGui
            L4_2 = L4_2.GetWidgetByNameAndOwner
            L5_2 = "PDA"
            L6_2 = Player
            L6_2 = L6_2.GetLocalPlayer
            L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L6_2()
            L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
            if L4_2 then
              L6_2 = L4_2
              L5_2 = L4_2.UpdateSupport
              L7_2 = L3_2
              L8_2 = nil
              L9_2 = nil
              L10_2 = MrxPmc
              L10_2 = L10_2.GetSupportQty
              L11_2 = L3_2
              L10_2, L11_2 = L10_2(L11_2)
              L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
            end
          else
            L4_2 = IsFuel
            L5_2 = L2_2
            L4_2 = L4_2(L5_2)
            if L4_2 then
              L4_2 = _bPlayedFirstFuelPickupVO
              if not L4_2 then
                L4_2 = MrxVoSequence
                L4_2 = L4_2.Start
                L5_2 = {}
                L6_2 = "Fiona-In-Mission-Freeplay-None-25"
                L5_2[1] = L6_2
                L6_2 = nil
                L7_2 = MrxVoSequence
                L7_2 = L7_2.knPriorityFreeplay
                L8_2 = false
                L4_2(L5_2, L6_2, L7_2, L8_2)
                L4_2 = true
                _bPlayedFirstFuelPickupVO = L4_2
              end
              L4_2 = MrxPmc
              L4_2 = L4_2.AddFuelQty
              L5_2 = L3_2.nFuel
              L4_2(L5_2)
            else
              L4_2 = IsCash
              L5_2 = L2_2
              L4_2 = L4_2(L5_2)
              if L4_2 then
                L4_2 = MrxPmc
                L4_2 = L4_2.AddCashQty
                L5_2 = L3_2.nCash
                L6_2 = nil
                L7_2 = "[Generic.Pickups]"
                L4_2(L5_2, L6_2, L7_2)
              end
            end
          end
        else
          L2_2 = NETEVENT_MARKERPULSE
          if A0_2 == L2_2 then
            L2_2 = Net
            L2_2 = L2_2.IsClient
            L2_2 = L2_2()
            if L2_2 then
              L2_2 = ClientTagAndBlip
              L3_2 = A1_2[1]
              L2_2(L3_2)
            end
          else
            L2_2 = NETEVENT_ISMUNITIONTAGGED
            if A0_2 == L2_2 then
              L2_2 = Net
              L2_2 = L2_2.IsServer
              L2_2 = L2_2()
              if L2_2 then
                L2_2 = IsMunitionTagged
                L3_2 = A1_2[1]
                L2_2 = L2_2(L3_2)
                if L2_2 then
                  L3_2 = Net
                  L3_2 = L3_2.SendCustomEvent
                  L4_2 = "Munitions"
                  L5_2 = NETEVENT_MARKERPULSE
                  L6_2 = {}
                  L7_2 = A1_2[1]
                  L6_2[1] = L7_2
                  L3_2(L4_2, L5_2, L6_2)
                end
              end
            end
          end
        end
      end
    end
  end
end

NetEventCallback = L1_1

function L1_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = Net
  L0_2 = L0_2.IsServer
  L0_2 = L0_2()
  if L0_2 then
    L0_2 = 0
    L1_2 = AreMunitionsTaggable
    L1_2 = L1_2()
    if L1_2 then
      L0_2 = 1
    end
    L1_2 = Net
    L1_2 = L1_2.SendCustomEvent
    L2_2 = "Munitions"
    L3_2 = NETEVENT_SETTAGGABLE
    L4_2 = {}
    L5_2 = L0_2
    L4_2[1] = L5_2
    L1_2(L2_2, L3_2, L4_2)
  end
end

OnPlayerJoined = L1_1
