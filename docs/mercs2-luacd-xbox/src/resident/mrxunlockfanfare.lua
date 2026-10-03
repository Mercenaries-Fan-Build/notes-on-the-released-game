local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxCheatBootstrap"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifStarterData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxStarterManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifEquipmentData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = MrxCheatBootstrap
  L1_2 = L1_2.IsSkipModeEnabled
  L1_2 = L1_2()
  if L1_2 then
    return
  end
  L1_2 = _BuildMessage
  L2_2 = A0_2.sType
  L3_2 = A0_2
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 then
    L2_2 = Hud
    L2_2 = L2_2.EventFanfare
    L3_2 = L2_2
    L2_2 = L2_2.Commence
    L4_2 = {}
    L5_2 = A0_2.sType
    L4_2.sType = L5_2
    L4_2.vText = L1_2
    L2_2(L3_2, L4_2)
  end
  L2_2 = Net
  L2_2 = L2_2.IsServer
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = A0_2.sType
    if L2_2 == "outfit" then
      return
    end
    L2_2 = 0
    L3_2 = A0_2.sSupportId
    if L3_2 then
      L3_2 = String
      L3_2 = L3_2.GetHash
      L4_2 = A0_2.sSupportId
      L3_2 = L3_2(L4_2)
      L2_2 = L3_2
    end
    L3_2 = Net
    L3_2 = L3_2.SendEvent_UnlockFanfare
    L4_2 = A0_2.sType
    L5_2 = A0_2.sName
    L6_2 = A0_2.sFactionId
    L7_2 = MrxStarterManager
    L7_2 = L7_2.GetStarterIndexFromName
    L8_2 = A0_2.sStarterId
    L7_2 = L7_2(L8_2)
    L8_2 = L2_2
    L9_2 = A0_2.nQty
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  end
end

AddUnlockedItem = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L2_2 = MrxCheatBootstrap
  L2_2 = L2_2.IsSkipModeEnabled
  L2_2 = L2_2()
  if L2_2 then
    return
  end
  L2_2 = {}
  L3_2 = ipairs
  L4_2 = A1_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = _BuildMessage
    L9_2 = A0_2
    L10_2 = L7_2
    L8_2 = L8_2(L9_2, L10_2)
    L9_2 = Net
    L9_2 = L9_2.IsServer
    L9_2 = L9_2()
    if L9_2 then
      L9_2 = false
      if L6_2 == 1 then
        L9_2 = true
      end
      L10_2 = Net
      L10_2 = L10_2.SendEvent_BatchUnlockFanfare
      L11_2 = false
      L12_2 = A0_2
      L13_2 = L7_2.sFactionId
      L14_2 = L7_2.sSupportId
      L15_2 = L7_2.nQty
      L16_2 = L9_2
      L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
    end
    if L8_2 then
      L9_2 = table
      L9_2 = L9_2.insert
      L10_2 = L2_2
      L11_2 = L8_2
      L9_2(L10_2, L11_2)
    end
  end
  L3_2 = Net
  L3_2 = L3_2.IsServer
  L3_2 = L3_2()
  if L3_2 then
    L3_2 = Net
    L3_2 = L3_2.SendEvent_BatchUnlockFanfare
    L4_2 = true
    L3_2(L4_2)
  end
  L3_2 = #L2_2
  if 0 < L3_2 then
    L3_2 = Hud
    L3_2 = L3_2.EventFanfare
    L4_2 = L3_2
    L3_2 = L3_2.Commence
    L5_2 = {}
    L5_2.sType = A0_2
    L5_2.vText = L2_2
    L3_2(L4_2, L5_2)
  end
end

AddUnlockedItems = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L8_2 = A1_2.sFactionId
  if L8_2 then
    L8_2 = A1_2.sFactionId
    if L8_2 ~= "" then
      L8_2 = MrxFactionManager
      L8_2 = L8_2.GetPlayerVisibleName
      L9_2 = A1_2.sFactionId
      L8_2 = L8_2(L9_2)
      L3_2 = L8_2
      L8_2 = MrxFactionManager
      L8_2 = L8_2.GetInlineIcon
      L9_2 = A1_2.sFactionId
      L8_2 = L8_2(L9_2)
      L4_2 = L8_2
    end
  end
  L8_2 = A1_2.sStarterId
  if L8_2 then
    L8_2 = WifStarterData
    L8_2 = L8_2.GetPlayerVisibleName
    L9_2 = A1_2.sStarterId
    L8_2 = L8_2(L9_2)
    L5_2 = L8_2
  end
  L8_2 = A1_2.sSupportId
  if L8_2 then
    L8_2 = MrxSupportData
    L8_2 = L8_2.GetPlayerVisibleName
    L9_2 = A1_2.sSupportId
    L8_2 = L8_2(L9_2)
    L6_2 = L8_2
    if not L6_2 then
      L8_2 = A1_2.sSupportId
      L9_2 = " (INVALID SUPPORT ID?)"
      L6_2 = L8_2 .. L9_2
    end
  end
  L8_2 = A1_2.sEquipmentId
  if L8_2 then
    L8_2 = WifEquipmentData
    L8_2 = L8_2.GetPlayerVisibleName
    L9_2 = A1_2.sEquipmentId
    L8_2 = L8_2(L9_2)
    L7_2 = L8_2
    if not L7_2 then
      L8_2 = A1_2.sEquipmentId
      L9_2 = " (INVALID EQUIPMENT ID?)"
      L7_2 = L8_2 .. L9_2
    end
  end
  if A0_2 == "contact" then
    L2_2 = ""
    if L4_2 then
      L8_2 = L2_2
      L9_2 = L4_2
      L10_2 = " "
      L2_2 = L8_2 .. L9_2 .. L10_2
    end
    L8_2 = L2_2
    L9_2 = L5_2
    L2_2 = L8_2 .. L9_2
  elseif A0_2 == "support" then
    L2_2 = ""
    if L6_2 then
      L8_2 = L2_2
      L9_2 = L4_2
      L10_2 = " "
      L11_2 = L6_2
      L2_2 = L8_2 .. L9_2 .. L10_2 .. L11_2
    elseif L7_2 then
      L8_2 = L2_2
      L9_2 = L4_2
      L10_2 = " "
      L11_2 = L7_2
      L2_2 = L8_2 .. L9_2 .. L10_2 .. L11_2
    end
  elseif A0_2 == "stockpile" then
    L8_2 = L6_2
    L9_2 = " (x "
    L10_2 = A1_2.nQty
    L11_2 = ")"
    L2_2 = L8_2 .. L9_2 .. L10_2 .. L11_2
  elseif A0_2 == "landingzone" then
    L2_2 = ""
    if L4_2 then
      L8_2 = L2_2
      L9_2 = L4_2
      L10_2 = " "
      L2_2 = L8_2 .. L9_2 .. L10_2
    end
    L8_2 = A1_2.sName
    if L8_2 then
      L8_2 = L2_2
      L9_2 = A1_2.sName
      L2_2 = L8_2 .. L9_2
    end
  elseif A0_2 == "bounty" then
    L8_2 = L4_2
    L9_2 = " "
    L10_2 = L3_2
    L2_2 = L8_2 .. L9_2 .. L10_2
  elseif A0_2 == "outfit" then
    L2_2 = A1_2.sName
  end
  return L2_2
end

_BuildMessage = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2
  L6_2 = MrxSupportData
  L6_2 = L6_2.GetSupportStringIndex
  L7_2 = A4_2
  L6_2 = L6_2(L7_2)
  A4_2 = L6_2
  L6_2 = AddUnlockedItem
  L7_2 = {}
  L7_2.sType = A0_2
  L7_2.sName = A1_2
  L7_2.sFactionId = A2_2
  L8_2 = MrxStarterManager
  L8_2 = L8_2.GetStarterNameFromIndex
  L9_2 = A3_2
  L8_2 = L8_2(L9_2)
  L7_2.sStarterId = L8_2
  L7_2.sSupportId = A4_2
  L7_2.nQty = A5_2
  L6_2(L7_2)
end

SetClientFanfareData = L0_1
L0_1 = {}
tClientMessages = L0_1
L0_1 = ""
_ClientBatchType = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2
  L6_2 = MrxCheatBootstrap
  L6_2 = L6_2.IsSkipModeEnabled
  L6_2 = L6_2()
  if L6_2 then
    return
  end
  L6_2 = tClientMessages
  L6_2 = #L6_2
  if 0 < L6_2 and A0_2 then
    L6_2 = Hud
    L6_2 = L6_2.EventFanfare
    L7_2 = L6_2
    L6_2 = L6_2.Commence
    L8_2 = {}
    L9_2 = _ClientBatchType
    L8_2.sType = L9_2
    L9_2 = tClientMessages
    L8_2.vText = L9_2
    L6_2(L7_2, L8_2)
    return
  end
  if A5_2 then
    L6_2 = {}
    tClientMessages = L6_2
    L6_2 = ""
    _ClientBatchType = L6_2
  end
  _ClientBatchType = A1_2
  L6_2 = _BuildMessage
  L7_2 = A1_2
  L8_2 = {}
  L8_2.sFactionId = A2_2
  L9_2 = MrxSupportData
  L9_2 = L9_2.GetSupportStringIndex
  L10_2 = A3_2
  L9_2 = L9_2(L10_2)
  L8_2.sSupportId = L9_2
  L8_2.nQty = A4_2
  L6_2 = L6_2(L7_2, L8_2)
  if L6_2 then
    L7_2 = table
    L7_2 = L7_2.insert
    L8_2 = tClientMessages
    L9_2 = L6_2
    L7_2(L8_2, L9_2)
  end
end

SetClientBatchFanfareData = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L6_2 = Net
  L6_2 = L6_2.IsClient
  L6_2 = L6_2()
  if not L6_2 then
    return
  end
  if A0_2 == 1 then
    L6_2 = "hvtcapture"
    sFanfareType = L6_2
  elseif A0_2 == 2 then
    L6_2 = "hvtkill"
    sFanfareType = L6_2
  end
  L6_2 = MrxUtil
  L6_2 = L6_2.GetInlineIconNameByIndex
  L7_2 = A3_2
  L6_2 = L6_2(L7_2)
  L7_2 = " "
  L8_2 = A2_2
  L9_2 = " "
  L10_2 = "("
  L11_2 = A4_2
  L12_2 = "/"
  L13_2 = A5_2
  L14_2 = ")"
  L6_2 = L6_2 .. L7_2 .. L8_2 .. L9_2 .. L10_2 .. L11_2 .. L12_2 .. L13_2 .. L14_2
  L7_2 = MrxFactionManager
  L7_2 = L7_2.GetInlineIcon
  L8_2 = A1_2
  L7_2 = L7_2(L8_2)
  L8_2 = " "
  L9_2 = L6_2
  L7_2 = L7_2 .. L8_2 .. L9_2
  L8_2 = Hud
  L8_2 = L8_2.EventFanfare
  L9_2 = L8_2
  L8_2 = L8_2.Commence
  L10_2 = {}
  L11_2 = sFanfareType
  L10_2.sType = L11_2
  L10_2.vText = L7_2
  L8_2(L9_2, L10_2)
end

ClientHVTFanfare = L0_1
