local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxSupportDesignator"
L0_1(L1_1)
L0_1 = 0
NETEVENT_SMOKEACTIVATE = L0_1
L0_1 = {}
L0_1.red = "0x02f6773f"
L0_1.green = "0x41675d0b"
L0_1.blue = "0x6efe9d26"
L0_1.yellow = "0xf8171566"
tColorList = L0_1
L0_1 = {}
L0_1.red = "global_particle_flaresmoke_fail"
L0_1.green = "global_particle_flaresmoke_green_fail"
L0_1.blue = "global_particle_flaresmoke_lightblue_fail"
L0_1.yellow = "global_particle_flaresmoke_yellow_fail"
tDenialColorList = L0_1
L0_1 = {}
tColorHashToName = L0_1
L0_1 = tColorHashToName
L0_1["0x02f6773f"] = "global_particle_flaresmoke"
L0_1 = tColorHashToName
L0_1["0x41675d0b"] = "global_particle_flaresmoke_green"
L0_1 = tColorHashToName
L0_1["0x6efe9d26"] = "global_particle_flaresmoke_lightblue"
L0_1 = tColorHashToName
L0_1["0xf8171566"] = "global_particle_flaresmoke_yellow"
L0_1 = {}
tSmokeGuids = L0_1
L0_1 = 0
nSmokeGuids = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = Pg
  L0_2 = L0_2.LoadAsset
  L1_2 = "global_weapon_m34wp"
  L2_2 = "model"
  L0_2(L1_2, L2_2)
end

Init = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = Pg
  L0_2 = L0_2.UnloadAsset
  L1_2 = "global_weapon_m34wp"
  L2_2 = "model"
  L0_2(L1_2, L2_2)
end

Deinit = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  if not A1_2 then
    L2_2 = {}
    A1_2 = L2_2
  end
  L2_2 = A0_2.uOwner
  A1_2.uOwner = L2_2
  A1_2.bDesignateOnDeath = false
  L2_2 = A0_2.bDesignationComplete
  A1_2.bDesignationComplete = L2_2
  A1_2.sDesignationType = "Smoke Designator"
  L2_2 = MrxSupportDesignator
  L2_2 = L2_2.ValidateGroundDropZone
  A1_2.fValidationFunction = L2_2
  L2_2 = {}
  A1_2.tCallbackList = L2_2
  L2_2 = A0_2.sSmokeHash
  if not L2_2 then
    L2_2 = "0x02f6773f"
  end
  A1_2.sSmokeHash = L2_2
  L2_2 = A0_2.sDenialSmokeTemplate
  if not L2_2 then
    L2_2 = "global_particle_flaresmoke_fail"
  end
  A1_2.sDenialSmokeTemplate = L2_2
  A1_2.sAATestLevel = "basic"
  L2_2 = A0_2.nX
  A1_2.nX = L2_2
  L2_2 = A0_2.nY
  A1_2.nY = L2_2
  L2_2 = A0_2.nZ
  A1_2.nZ = L2_2
  L2_2 = A0_2.uGuid
  A1_2.uGuid = L2_2
  L2_2 = setmetatable
  L3_2 = A1_2
  L4_2 = A0_2
  L2_2(L3_2, L4_2)
  A0_2.__index = A0_2
  L3_2 = A1_2
  L2_2 = A1_2.AddCompleteCallback
  L4_2 = DesignationCompleteCallback
  L5_2 = {}
  L6_2 = A1_2
  L5_2[1] = L6_2
  L2_2(L3_2, L4_2, L5_2)
  return A1_2
end

Create = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = NETEVENT_SMOKEACTIVATE
  if A0_2 == L2_2 then
    L2_2 = NetSafeDesignationCompleteCallback
    L3_2 = A1_2[1]
    L4_2 = A1_2[2]
    L5_2 = A1_2[3]
    L6_2 = A1_2[4]
    L7_2 = A1_2[5]
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  end
end

NetEventCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = A0_2.uGuid
  if L1_2 then
    L1_2 = StringToGuid
    L2_2 = "0x16516bb1"
    L1_2 = L1_2(L2_2)
    L2_2 = StringToGuid
    L3_2 = A0_2.sSmokeHash
    L2_2 = L2_2(L3_2)
    L3_2 = ObjectState
    L3_2 = L3_2.StartEmitter
    L4_2 = A0_2.uGuid
    L5_2 = L1_2
    L6_2 = L2_2
    L3_2(L4_2, L5_2, L6_2)
    L3_2 = Object
    L3_2 = L3_2.DisablePhysics
    L4_2 = A0_2.uGuid
    L3_2(L4_2)
    L3_2 = Object
    L3_2 = L3_2.GetPosition
    L4_2 = A0_2.uGuid
    L3_2, L4_2, L5_2 = L3_2(L4_2)
    z = L5_2
    y = L4_2
    x = L3_2
    L3_2 = tColorHashToName
    L4_2 = A0_2.sSmokeHash
    L3_2 = L3_2[L4_2]
    sTemplateName = L3_2
    L3_2 = Net
    L3_2 = L3_2.SendCustomEvent
    L4_2 = "MrxSupportDesignatorSmoke"
    L5_2 = NETEVENT_SMOKEACTIVATE
    L6_2 = {}
    L7_2 = sTemplateName
    L8_2 = x
    L9_2 = y
    L10_2 = z
    L11_2 = tostring
    L12_2 = A0_2.uGuid
    L11_2, L12_2 = L11_2(L12_2)
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L6_2[4] = L10_2
    L6_2[5] = L11_2
    L6_2[6] = L12_2
    L3_2(L4_2, L5_2, L6_2)
    L3_2 = Event
    L3_2 = L3_2.Create
    L4_2 = Event
    L4_2 = L4_2.TimerRelative
    L5_2 = {}
    L6_2 = 10
    L5_2[1] = L6_2
    L6_2 = RemoveSmoke
    L7_2 = {}
    L8_2 = A0_2
    L7_2[1] = L8_2
    L3_2(L4_2, L5_2, L6_2, L7_2)
  end
end

DesignationCompleteCallback = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L5_2 = Pg
  L5_2 = L5_2.GetGuidByName
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  L6_2 = tSmokeGuids
  L7_2 = nSmokeGuids
  L8_2 = Pg
  L8_2 = L8_2.Spawn
  L9_2 = L5_2
  L10_2 = A1_2
  L11_2 = A2_2
  L12_2 = A3_2
  L13_2 = 0
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  L6_2[L7_2] = L8_2
  L6_2 = Event
  L6_2 = L6_2.Create
  L7_2 = Event
  L7_2 = L7_2.TimerRelative
  L8_2 = {}
  L9_2 = 10
  L8_2[1] = L9_2
  L9_2 = NetSafeRemoveSmoke
  L10_2 = {}
  L11_2 = nSmokeGuids
  L10_2[1] = L11_2
  L6_2(L7_2, L8_2, L9_2, L10_2)
  L6_2 = nSmokeGuids
  L6_2 = L6_2 + 1
  nSmokeGuids = L6_2
end

NetSafeDesignationCompleteCallback = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = tSmokeGuids
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = Object
    L1_2 = L1_2.Remove
    L2_2 = tSmokeGuids
    L2_2 = L2_2[A0_2]
    L1_2(L2_2)
    L1_2 = tSmokeGuids
    L1_2[A0_2] = nil
  end
end

NetSafeRemoveSmoke = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = A0_2.uGuid
  if L1_2 then
    L1_2 = Object
    L1_2 = L1_2.Remove
    L2_2 = A0_2.uGuid
    L1_2(L2_2)
  end
end

RemoveSmoke = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = Object
  L2_2 = L2_2.Remove
  L3_2 = A1_2
  L2_2(L3_2)
  L2_2 = A0_2.sDenialSmokeTemplate
  if L2_2 then
    L2_2 = Object
    L2_2 = L2_2.GetPosition
    L3_2 = A1_2
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    L5_2 = Pg
    L5_2 = L5_2.Spawn
    L6_2 = A0_2.sDenialSmokeTemplate
    L7_2 = L2_2
    L8_2 = L3_2
    L9_2 = L4_2
    L10_2 = 0
    L11_2 = true
    L12_2 = true
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  end
end

OnDeny = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  if A1_2 and A0_2 then
    L2_2 = tColorList
    L3_2 = string
    L3_2 = L3_2.lower
    L4_2 = A1_2
    L3_2 = L3_2(L4_2)
    L2_2 = L2_2[L3_2]
    if not L2_2 then
      L2_2 = "0x02f6773f"
    end
    A0_2.sSmokeHash = L2_2
    L2_2 = tDenialColorList
    L3_2 = string
    L3_2 = L3_2.lower
    L4_2 = A1_2
    L3_2 = L3_2(L4_2)
    L2_2 = L2_2[L3_2]
    if not L2_2 then
      L2_2 = "global_particle_flaresmoke_fail"
    end
    A0_2.sDenialSmokeTemplate = L2_2
  end
end

SetSmokeColor = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = "smoke"
  return L1_2
end

GetType = L0_1
