local L0_1, L1_1, L2_1
L0_1 = import
L1_1 = "MrxSupport"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = "UH1 Transport (PMC) (Driver)"
sDeliveryVehicle = L0_1
L0_1 = "box"
sCargoToDeliver = L0_1
L0_1 = Pg
L0_1 = L0_1.GetGuidByName
L1_1 = sCargoToDeliver
L0_1 = L0_1(L1_1)
uCargoToDeliver = L0_1
L0_1 = 25
nAltitude = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2, A8_2)
  local L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2
  L9_2 = Net
  L9_2 = L9_2.IsClient
  L9_2 = L9_2()
  if L9_2 then
    return
  end
  L9_2 = Pg
  L9_2 = L9_2.GetGuidByName
  L10_2 = A1_2
  L9_2 = L9_2(L10_2)
  if not L9_2 then
  end
  L10_2 = {}
  L10_2.PMC = "UH1 Transport (PMC) (Driver)"
  L10_2.AL = "MH53J (Driver)"
  L10_2.CH = "Ka29b (Driver)"
  L10_2.GR = "UH1 Transport (GR) (Driver)"
  L10_2.OC = "Coanda Transport (Driver)"
  L10_2.PR = "Alouette3 Transport (PR) (Driver)"
  L10_2.VZ = "Alouette3 Transport (VZ) (Driver)"
  L10_2.VZH = "Mi26 (VZ) (Driver)"
  L10_2.VZHF = "Mi26 (VZA Intro) (Driver)"
  L10_2.VZF = "Alouette3 Transport (VZA Intro) (Driver)"
  L11_2 = Pg
  L11_2 = L11_2.GetGuidByName
  L12_2 = L10_2[A0_2]
  L11_2 = L11_2(L12_2)
  if not L11_2 then
    L11_2 = Pg
    L11_2 = L11_2.GetGuidByName
    L12_2 = "Ka29b (Driver)"
    L11_2 = L11_2(L12_2)
  end
  L12_2 = Object
  L12_2 = L12_2.GetHibernationDistance
  L13_2 = L9_2
  L12_2 = L12_2(L13_2)
  if not L12_2 then
    L12_2 = 200
  end
  L13_2 = Math
  L13_2 = L13_2.min
  L14_2 = L12_2 - 5
  L15_2 = 200
  L13_2 = L13_2(L14_2, L15_2)
  L12_2 = L13_2
  L13_2 = Pg
  L13_2 = L13_2.SpawnFromCamera
  L14_2 = L9_2
  L15_2 = L12_2
  L16_2 = 1
  L17_2 = true
  L18_2 = Player
  L18_2 = L18_2.GetLocalCharacter
  L18_2 = L18_2()
  L19_2 = false
  L20_2 = true
  L13_2 = L13_2(L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
  if not L13_2 then
    return
  end
  if not A6_2 then
    L14_2 = Pg
    L14_2 = L14_2.FindPointFromCamera
    L15_2 = L12_2
    L16_2 = nAltitude
    L17_2 = 10
    L14_2, L15_2, L16_2 = L14_2(L15_2, L16_2, L17_2)
    A8_2 = L16_2
    A7_2 = L15_2
    A6_2 = L14_2
    if A3_2 then
      L14_2 = nAltitude
      L14_2 = A3_2 + L14_2
      if A7_2 < L14_2 then
        L14_2 = nAltitude
        A7_2 = A3_2 + L14_2
      end
    end
  end
  L14_2 = Pg
  L14_2 = L14_2.Spawn
  L15_2 = L11_2
  L16_2 = A6_2
  L17_2 = A7_2
  L18_2 = A8_2
  L19_2 = 0
  L20_2 = false
  L21_2 = true
  L14_2 = L14_2(L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
  if not L14_2 then
    L15_2 = Object
    L15_2 = L15_2.Remove
    L16_2 = L13_2
    L15_2(L16_2)
    return
  end
  L15_2 = Event
  L15_2 = L15_2.Create
  L16_2 = Event
  L16_2 = L16_2.ObjectHibernation
  L17_2 = {}
  L18_2 = L14_2
  L19_2 = "awake"
  L17_2[1] = L18_2
  L17_2[2] = L19_2
  L18_2 = _DeployWinch
  L19_2 = {}
  L20_2 = L14_2
  L21_2 = L13_2
  L22_2 = A2_2
  L23_2 = A3_2
  L24_2 = A4_2
  L25_2 = A5_2
  L19_2[1] = L20_2
  L19_2[2] = L21_2
  L19_2[3] = L22_2
  L19_2[4] = L23_2
  L19_2[5] = L24_2
  L19_2[6] = L25_2
  L15_2(L16_2, L17_2, L18_2, L19_2)
  L15_2 = L14_2
  L16_2 = L13_2
  return L15_2, L16_2
end

Create = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L6_2 = Object
  L6_2 = L6_2.SetWinchState
  L7_2 = A0_2
  L8_2 = "deployed"
  L6_2(L7_2, L8_2)
  L6_2 = Event
  L6_2 = L6_2.Create
  L7_2 = Event
  L7_2 = L7_2.TimerRelative
  L8_2 = {}
  L9_2 = 0.1
  L8_2[1] = L9_2
  L9_2 = Event
  L9_2 = L9_2.Create
  L10_2 = {}
  L11_2 = Event
  L11_2 = L11_2.ObjectHibernation
  L12_2 = {}
  L13_2 = A1_2
  L14_2 = "awake"
  L12_2[1] = L13_2
  L12_2[2] = L14_2
  L13_2 = _WaitCallback
  L14_2 = {}
  L15_2 = A0_2
  L16_2 = A1_2
  L17_2 = A2_2
  L18_2 = A3_2
  L19_2 = A4_2
  L20_2 = A5_2
  L14_2[1] = L15_2
  L14_2[2] = L16_2
  L14_2[3] = L17_2
  L14_2[4] = L18_2
  L14_2[5] = L19_2
  L14_2[6] = L20_2
  L10_2[1] = L11_2
  L10_2[2] = L12_2
  L10_2[3] = L13_2
  L10_2[4] = L14_2
  L6_2(L7_2, L8_2, L9_2, L10_2)
end

_DeployWinch = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L6_2 = Object
  L6_2 = L6_2.SetYaw
  L7_2 = A1_2
  L8_2 = Object
  L8_2 = L8_2.GetYaw
  L9_2 = A0_2
  L8_2, L9_2, L10_2, L11_2, L12_2 = L8_2(L9_2)
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L6_2 = Object
  L6_2 = L6_2.AttachCargoToWinch
  L7_2 = A1_2
  L8_2 = A0_2
  L6_2(L7_2, L8_2)
  L6_2 = Ai
  L6_2 = L6_2.Deliver
  L7_2 = Vehicle
  L7_2 = L7_2.GetDriver
  L8_2 = A0_2
  L7_2 = L7_2(L8_2)
  L8_2 = A2_2
  L9_2 = A3_2
  L10_2 = A4_2
  L11_2 = 0.5
  L12_2 = A5_2
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L6_2 = Event
  L6_2 = L6_2.Create
  L7_2 = Event
  L7_2 = L7_2.ObjectWinched
  L8_2 = {}
  L9_2 = A1_2
  L10_2 = A0_2
  L11_2 = "Detach"
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L9_2 = DeliveryComplete
  L10_2 = {}
  L11_2 = A0_2
  L10_2[1] = L11_2
  L6_2(L7_2, L8_2, L9_2, L10_2)
end

_WaitCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Object
  L1_2 = L1_2.DetachCargoFromWinch
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = {}
  self = L1_2
  L1_2 = MrxSupport
  L1_2 = L1_2.GoHome
  L2_2 = self
  L3_2 = A0_2
  L1_2(L2_2, L3_2)
end

DeliveryComplete = L0_1
