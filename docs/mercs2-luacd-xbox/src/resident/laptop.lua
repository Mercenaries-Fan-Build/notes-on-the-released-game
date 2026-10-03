local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1, L18_1, L19_1, L20_1, L21_1
L0_1 = inherit
L1_1 = "Blippable"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGui"
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
L0_1 = 150
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
_tStatusList = L1_1

function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = getfenv
  L2_2 = L2_2()
  L3_2 = Object
  L3_2 = L3_2.GetHealth
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if L3_2 == 0 then
    return
  end
  L3_2 = L0_1
  L3_2 = L3_2[A1_2]
  if not L3_2 then
  end
  L2_2.sTexture = "radar_Munition"
  L3_2 = {}
  L4_2 = 51
  L5_2 = 102
  L6_2 = 51
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L2_2.tColor = L3_2
  L3_2 = {}
  L4_2 = 255
  L5_2 = 255
  L6_2 = 255
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L2_2.tFlash = L3_2
  L2_2.nSize = 8
  L3_2 = {}
  L3_2.sTexture = "pickup_munitions"
  L4_2 = {}
  L5_2 = 153
  L6_2 = 255
  L7_2 = 153
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L3_2.tColor = L4_2
  L3_2.nSize = 48
  L2_2.tMarker = L3_2
  L4_2 = L2_2
  L3_2 = L2_2.Create
  L5_2 = A0_2
  L6_2 = A1_2
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L5_2 = L3_2
  L4_2 = L3_2.SetBlipped
  L4_2(L5_2)
  L3_2.nStock = A1_2
  L4_2 = Event
  L4_2 = L4_2.Create
  L5_2 = Event
  L5_2 = L5_2.WeaponEvent
  L6_2 = {}
  L7_2 = "hero"
  L8_2 = "pickup"
  L9_2 = "Laptop"
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L7_2 = PickupMunitions
  L8_2 = {}
  L9_2 = L3_2
  L8_2[1] = L9_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
end

Awake = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.uGuid
  L3_2 = A0_2
  L2_2 = A0_2.ClearBlipped
  L2_2(L3_2)
  L2_2 = A0_2.TaggedMarker
  if L2_2 then
    L2_2 = Marker
    L2_2 = L2_2.Remove
    L3_2 = A0_2.TaggedMarker
    L2_2(L3_2)
    L2_2 = Net
    L2_2 = L2_2.IsServer
    L2_2 = L2_2()
    if L2_2 then
      L2_2 = Net
      L2_2 = L2_2.SendEvent_RemoveMarkerObjective
      L3_2 = A0_2.TaggedMarker
      L2_2(L3_2)
    end
    A0_2.TaggedMarker = nil
    L2_2 = _nTagged
    L2_2 = L2_2 - 1
    _nTagged = L2_2
  end
  L2_2 = A0_2._uHideMessage
  if L2_2 then
    L2_2 = Event
    L2_2 = L2_2.Delete
    L3_2 = A0_2._uHideMessage
    L2_2(L3_2)
    A0_2._uHideMessage = nil
  end
  L2_2 = Blippable
  L2_2 = L2_2.Delete
  L3_2 = A0_2
  L2_2(L3_2)
end

Delete = L1_1

function L1_1(A0_2)
  local L1_2, L2_2
  L1_2 = _tStatusList
  if not L1_2 then
    L1_2 = {}
    _tStatusList = L1_2
  end
  L1_2 = Inheritable
  L1_2 = L1_2.OnDeath
  L2_2 = A0_2
  L1_2(L2_2)
end

OnDeath = L1_1

function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = MrxGui
  L1_2 = L1_2.GetWidgetByNameAndOwner
  L2_2 = "PDA"
  L3_2 = Player
  L3_2 = L3_2.GetLocalPlayer
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L3_2()
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  if not L1_2 then
    return
  end
  L2_2 = A0_2.uGuid
  L3_2 = A0_2.nStock
  L4_2 = L0_1
  L4_2 = L4_2[L3_2]
  L5_2 = Event
  L5_2 = L5_2.Post
  L6_2 = "MunitionsPickup"
  L7_2 = {}
  L8_2 = L4_2
  L9_2 = L2_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L5_2(L6_2, L7_2)
  L5_2 = MrxPmc
  L5_2 = L5_2.AddSupportQty
  L6_2 = L4_2
  L7_2 = 1
  L8_2 = true
  L5_2(L6_2, L7_2, L8_2)
  L6_2 = L1_2
  L5_2 = L1_2.UpdateSupport
  L7_2 = L4_2
  L8_2 = nil
  L9_2 = nil
  L10_2 = MrxPmc
  L10_2 = L10_2.GetSupportQty
  L11_2 = L4_2
  L10_2, L11_2 = L10_2(L11_2)
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  L5_2 = {}
  L6_2 = "Fiona.Support.Munitions02"
  L7_2 = "Fiona.Support.Munitions03"
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L6_2 = MrxUtil
  L6_2 = L6_2.GetRandomTableElement
  L7_2 = L5_2
  L6_2 = L6_2(L7_2)
  L7_2 = MrxVoSequence
  L7_2 = L7_2.Start
  L8_2 = L6_2
  L9_2 = nil
  L10_2 = MrxVoSequence
  L10_2 = L10_2.knPriorityFreeplay
  L7_2(L8_2, L9_2, L10_2)
end

PickupMunitions = L1_1
