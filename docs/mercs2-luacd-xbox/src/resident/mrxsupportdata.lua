local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxsupport"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxartillery"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxboatdelivery"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxbombingrun"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxbunkerbuster"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxcarpetbomb"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxsatclusterbomb"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxclusterbomb"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxcombatairpatrol"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxcratedelivery"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxcruisemissile"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxdaisycutter"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxfuelairbomb"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxgunship"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxharmstrike"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxlaserguidedbomb"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxmoab"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxrocketartillery"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxsatelliteguidedbomb"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxsmartbomb"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSoldierDelivery"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxstrategicmissile"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxsupportpickup"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxsupporttransit"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxsurgicalstrike"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxtankbuster"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxOilCon002Delivery"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxMunitionsPickup"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportPickup"
L0_1(L1_1)
L0_1 = import
L1_1 = "mrxsupportcopterdelivery"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxAchievements"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxShop"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifMissionFlow"
L0_1(L1_1)
L0_1 = 99
_kMaxStock = L0_1
L0_1 = {}
tSupportData = L0_1
L0_1 = {}
tFreebieData = L0_1
L0_1 = {}
tRequirementsObtained = L0_1
L0_1 = {}
tRequirementStrings = L0_1
L0_1 = false
bIgnoreRequirements = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = bIgnoreRequirements
  if L1_2 then
    L1_2 = true
    return L1_2
  end
  if not A0_2 then
    L1_2 = false
    return L1_2
  end
  L1_2 = tSupportData
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L2_2 = L1_2.oSupport
    if L2_2 then
      goto lbl_19
    end
  end
  L2_2 = false
  do return L2_2 end
  ::lbl_19::
  L2_2 = L1_2.oSupport
  L3_2 = L2_2
  L2_2 = L2_2.GetRecruit
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = tRequirementsObtained
    L3_2 = L3_2[L2_2]
    if not L3_2 then
      L3_2 = false
      L4_2 = tRequirementStrings
      L4_2 = L4_2[L2_2]
      return L3_2, L4_2
    end
  end
  L3_2 = L1_2.tRequirementList
  if L3_2 then
    L3_2 = ipairs
    L4_2 = L1_2.tRequirementList
    L3_2, L4_2, L5_2 = L3_2(L4_2)
    for L6_2, L7_2 in L3_2, L4_2, L5_2 do
      L8_2 = tRequirementsObtained
      L8_2 = L8_2[L7_2]
      if not L8_2 then
        L8_2 = false
        L9_2 = tRequirementStrings
        L9_2 = L9_2[L7_2]
        return L8_2, L9_2
      end
    end
  end
  L3_2 = true
  return L3_2
end

IsSupportEquippable = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = tRequirementsObtained
  L1_2.Copter = A0_2
  L1_2 = Net
  L1_2 = L1_2.IsServer
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = Net
    L1_2 = L1_2.SendEvent_RecruitsUnlocked
    L2_2 = tRequirementsObtained
    L1_2(L2_2)
  end
end

SetHeliPilotRecruited = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = tRequirementsObtained
  L1_2.Mechanic = A0_2
  L1_2 = Net
  L1_2 = L1_2.IsServer
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = Net
    L1_2 = L1_2.SendEvent_RecruitsUnlocked
    L2_2 = tRequirementsObtained
    L1_2(L2_2)
  end
end

SetMechanicRecruited = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = tRequirementsObtained
  L1_2.Pilot = A0_2
  L1_2 = Net
  L1_2 = L1_2.IsServer
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = Net
    L1_2 = L1_2.SendEvent_RecruitsUnlocked
    L2_2 = tRequirementsObtained
    L1_2(L2_2)
  end
end

SetJetPilotRecruited = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = tRequirementsObtained
  L2_2[A0_2] = A1_2
  L2_2 = Net
  L2_2 = L2_2.IsServer
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = Net
    L2_2 = L2_2.SendEvent_RecruitsUnlocked
    L3_2 = tRequirementsObtained
    L2_2(L3_2)
  end
end

SetRequirement = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Net
  L1_2 = L1_2.IsServer
  L1_2 = L1_2()
  if L1_2 then
    L1_2 = Net
    L1_2 = L1_2.SendEvent_RecruitsUnlocked
    L2_2 = tRequirementsObtained
    L1_2(L2_2)
  elseif A0_2 then
    L1_2 = SetRequirement
    L2_2 = "Fiona"
    L3_2 = A0_2.Fiona
    L1_2(L2_2, L3_2)
    L1_2 = SetHeliPilotRecruited
    L2_2 = A0_2.Copter
    L1_2(L2_2)
    L1_2 = SetMechanicRecruited
    L2_2 = A0_2.Mechanic
    L1_2(L2_2)
    L1_2 = SetJetPilotRecruited
    L2_2 = A0_2.Pilot
    L1_2(L2_2)
  end
end

SynchNetRecruits = L0_1

function L0_1(A0_2)
  local L1_2
  bIgnoreRequirements = A0_2
end

SetIgnoreRequirements = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L0_2 = {}
  L0_2.Fiona = true
  L0_2.Copter = true
  L0_2.Mechanic = true
  L0_2.Pilot = true
  tRequirementsObtained = L0_2
  L0_2 = {}
  L0_2.Fiona = "[PDA.Support.EquipFail.Fiona]"
  L0_2.Copter = "[PDA.Support.EquipFail.Copter]"
  L0_2.Mechanic = "[PDA.Support.EquipFail.Mechanic]"
  L0_2.Pilot = "[PDA.Support.EquipFail.Pilot]"
  tRequirementStrings = L0_2
  L0_2 = nil
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (AA)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[support.supply.aa.name]"
  L2_2.sDescription = "[support.supply.aa.desc]"
  L2_2.sIcon = "supplies_anti_air"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 15000
  L2_2.nFuelCost = 40
  L2_2.oSupport = L0_2
  L2_2.sType = "Supply"
  L1_2.aa = L2_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "AH1Z (Ewan)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[vehicle.ah1z]"
  L2_2.sDescription = "[support.vehicle.ah1z.desc]"
  L2_2.sIcon = "vehicles_heli_ah1z"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 200000
  L2_2.nFuelCost = 180
  L2_2.oSupport = L0_2
  L2_2.sType = "Heli"
  L1_2.ah1z = L2_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (Allied)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[support.supply.al.name]"
  L2_2.sDescription = "[support.supply.al.desc]"
  L2_2.sIcon = "supplies_AN_crate"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 10000
  L2_2.nFuelCost = 40
  L2_2.oSupport = L0_2
  L2_2.sType = "Supply"
  L1_2.al = L2_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Alouette3 Attack (PR) (Ewan)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[vehicle.alouette3attackpr]"
  L2_2.sDescription = "[support.vehicle.alouette3attackpr.desc]"
  L2_2.sIcon = "vehicles_heli_alouette"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 75000
  L2_2.nFuelCost = 140
  L2_2.oSupport = L0_2
  L2_2.sType = "Heli"
  L1_2.alouette3attackpr = L2_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Alouette3 Attack (VZ) (Ewan)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[vehicle.alouette3attackvz]"
  L2_2.sDescription = "[support.vehicle.alouette3attackvz.desc]"
  L2_2.sIcon = "vehicles_heli_alouette"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 75000
  L2_2.nFuelCost = 140
  L2_2.oSupport = L0_2
  L2_2.sType = "Heli"
  L1_2.alouette3attackvz = L2_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Alouette3 Elite (Ewan)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[vehicle.alouette3elite]"
  L2_2.sDescription = "[support.vehicle.alouette3elite.desc]"
  L2_2.sIcon = "vehicles_heli_alouette"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 100000
  L2_2.nFuelCost = 140
  L2_2.oSupport = L0_2
  L2_2.sType = "Heli"
  L1_2.alouette3elite = L2_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Alouette3 Superiority (Ewan)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[vehicle.alouette3superiority]"
  L2_2.sDescription = "[support.vehicle.alouette3superiority.desc]"
  L2_2.sIcon = "vehicles_heli_alouette"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 125000
  L2_2.nFuelCost = 140
  L2_2.oSupport = L0_2
  L2_2.sType = "Heli"
  L1_2.alouette3superiority = L2_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Alouette3 Transport (PR) (Ewan)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[vehicle.alouette3transportpr]"
  L2_2.sDescription = "[support.vehicle.alouette3transportpr.desc]"
  L2_2.sIcon = "vehicles_heli_alouette"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 50000
  L2_2.nFuelCost = 100
  L2_2.oSupport = L0_2
  L2_2.sType = "Heli"
  L1_2.alouette3transportpr = L2_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Alouette3 Transport (VZ) (Ewan)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[vehicle.alouette3transportvz]"
  L2_2.sDescription = "[support.vehicle.alouette3transportvz.desc]"
  L2_2.sIcon = "vehicles_heli_alouette"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 50000
  L2_2.nFuelCost = 100
  L2_2.oSupport = L0_2
  L2_2.sType = "Heli"
  L1_2.alouette3transportvz = L2_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (AM AL)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[support.supply.amal.name]"
  L2_2.sDescription = "[support.supply.amal.desc]"
  L2_2.sIcon = "supplies_anti_material"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 15000
  L2_2.nFuelCost = 40
  L2_2.oSupport = L0_2
  L2_2.sType = "Supply"
  L1_2.amal = L2_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (AM CH)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[support.supply.amch.name]"
  L2_2.sDescription = "[support.supply.amch.desc]"
  L2_2.sIcon = "supplies_anti_material"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 15000
  L2_2.nFuelCost = 40
  L2_2.oSupport = L0_2
  L2_2.sType = "Supply"
  L1_2.amch = L2_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "AMX30"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Mi26 (PMC) (Driver)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[vehicle.amx30]"
  L2_2.sDescription = "[support.vehicle.amx30.desc]"
  L2_2.sIcon = "vehicles_tank_amx30"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 100000
  L2_2.nFuelCost = 160
  L2_2.oSupport = L0_2
  L2_2.sType = "Heavy"
  L1_2.amx30 = L2_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "AMX30 AA"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Mi26 (PMC) (Driver)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[vehicle.amx30aa]"
  L2_2.sDescription = "[support.vehicle.amx30aa.desc]"
  L2_2.sIcon = "vehicles_tank_mosquitoAA"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 125000
  L2_2.nFuelCost = 160
  L2_2.oSupport = L0_2
  L2_2.sType = "Heavy"
  L1_2.amx30aa = L2_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "AMX30 Elite"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Mi26 (PMC) (Driver)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[vehicle.amx30elite]"
  L2_2.sDescription = "[support.vehicle.amx30elite.desc]"
  L2_2.sIcon = "vehicles_tank_amx30"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 150000
  L2_2.nFuelCost = 160
  L2_2.oSupport = L0_2
  L2_2.sType = "Heavy"
  L1_2.amx30elite = L2_2
  L1_2 = mrxartillery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[support.airstrike.artillery.name]"
  L2_2.sDescription = "[support.airstrike.artillery.desc]"
  L2_2.sIcon = "support_artillery"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 150000
  L2_2.nFuelCost = 140
  L2_2.oSupport = L0_2
  L2_2.sType = "Airstrike"
  L1_2.artillery = L2_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (AT AL)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[support.supply.atal.name]"
  L2_2.sDescription = "[support.supply.atal.desc]"
  L2_2.sIcon = "supplies_AN_anti_tank"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 15000
  L2_2.nFuelCost = 40
  L2_2.oSupport = L0_2
  L2_2.sType = "Supply"
  L1_2.atal = L2_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (AT CH)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[support.supply.atch.name]"
  L2_2.sDescription = "[support.supply.atch.desc]"
  L2_2.sIcon = "supplies_CH_anti_tank"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 15000
  L2_2.nFuelCost = 40
  L2_2.oSupport = L0_2
  L2_2.sType = "Supply"
  L1_2.atch = L2_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = {}
  L4_2 = "Sportbike (Civ)"
  L5_2 = "Chopper"
  L6_2 = "Offroad Motorcycle (GR)"
  L7_2 = "Offroad Motorcycle (AL)"
  L8_2 = "Scooter"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L3_2[5] = L8_2
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[vehicle.bike]"
  L2_2.sDescription = "[support.vehicle.bike.desc]"
  L2_2.sIcon = "vehicles_motorcycle_street"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 10000
  L2_2.nFuelCost = 60
  L2_2.oSupport = L0_2
  L2_2.sType = "Civilian"
  L1_2.bike = L2_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (Blanco)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[support.supply.blanco.name]"
  L2_2.sDescription = "[support.supply.blanco.desc]"
  L2_2.sIcon = "supplies_Blanco_crate"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 5000
  L2_2.nFuelCost = 40
  L2_2.oSupport = L0_2
  L2_2.sType = "Supply"
  L1_2.blanco = L2_2
  L1_2 = mrxbombingrun
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[support.airstrike.bombingrun.name]"
  L2_2.sDescription = "[support.airstrike.bombingrun.desc]"
  L2_2.sIcon = "support_bombing_run"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 75000
  L2_2.nFuelCost = 140
  L2_2.oSupport = L0_2
  L2_2.sType = "Airstrike"
  L1_2.bombingrun = L2_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Buggy (Hellfire)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[vehicle.buggyhellfire]"
  L2_2.sDescription = "[support.vehicle.buggyhellfire.desc]"
  L2_2.sIcon = "vehicles_light_buggy_rocket"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 150000
  L2_2.nFuelCost = 60
  L2_2.oSupport = L0_2
  L2_2.sType = "Light"
  L1_2.buggyhellfire = L2_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Buggy (PR)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[vehicle.buggypr]"
  L2_2.sDescription = "[support.vehicle.buggypr.desc]"
  L2_2.sIcon = "vehicles_scorpion"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 25000
  L2_2.nFuelCost = 60
  L2_2.oSupport = L0_2
  L2_2.sType = "Light"
  L1_2.buggypr = L2_2
  L1_2 = mrxbunkerbuster
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[support.airstrike.bunkerbuster.name]"
  L2_2.sDescription = "[support.airstrike.bunkerbuster.desc]"
  L2_2.sIcon = "support_bunker_buster"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 200000
  L2_2.nFuelCost = 300
  L2_2.oSupport = L0_2
  L2_2.sType = "Airstrike"
  L1_2.bunkerbuster = L2_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (C4)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[support.supply.c4.name]"
  L2_2.sDescription = "[support.supply.c4.desc]"
  L2_2.sIcon = "supplies_demolitions"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 10000
  L2_2.nFuelCost = 40
  L2_2.oSupport = L0_2
  L2_2.sType = "Supply"
  L1_2.c4 = L2_2
  L1_2 = mrxcarpetbomb
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[support.airstrike.carpetbomb.name]"
  L2_2.sDescription = "[support.airstrike.carpetbomb.desc]"
  L2_2.sIcon = "support_carpet_bomb"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 250000
  L2_2.nFuelCost = 280
  L2_2.oSupport = L0_2
  L2_2.sType = "Airstrike"
  L1_2.carpetbomb = L2_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (Chinese)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[support.supply.ch.name]"
  L2_2.sDescription = "[support.supply.ch.desc]"
  L2_2.sIcon = "supplies_CH_crate"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 10000
  L2_2.nFuelCost = 40
  L2_2.oSupport = L0_2
  L2_2.sType = "Supply"
  L1_2.ch = L2_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = {}
  L4_2 = "Valiant"
  L5_2 = "Valiant (4door)"
  L6_2 = "RTR (Civ)"
  L7_2 = "Phoenix"
  L8_2 = "CRX"
  L9_2 = "Pony (normal)"
  L10_2 = "Taxi (Tercel)"
  L11_2 = "R90"
  L12_2 = "Thunder"
  L13_2 = "Ridgeline"
  L14_2 = "El Grande"
  L15_2 = "ESV (lowrider)"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L3_2[5] = L8_2
  L3_2[6] = L9_2
  L3_2[7] = L10_2
  L3_2[8] = L11_2
  L3_2[9] = L12_2
  L3_2[10] = L13_2
  L3_2[11] = L14_2
  L3_2[12] = L15_2
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[vehicle.civilian]"
  L2_2.sDescription = "[support.vehicle.civilian.desc]"
  L2_2.sIcon = "vehicles_car_crx"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 15000
  L2_2.nFuelCost = 60
  L2_2.oSupport = L0_2
  L2_2.sType = "Civilian"
  L1_2.civilian = L2_2
  L1_2 = mrxclusterbomb
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[support.airstrike.clusterbomb.name]"
  L2_2.sDescription = "[support.airstrike.clusterbomb.desc]"
  L2_2.sIcon = "support_cluster_bomb"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 75000
  L2_2.nFuelCost = 220
  L2_2.oSupport = L0_2
  L2_2.sType = "Airstrike"
  L1_2.clusterbomb = L2_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Coanda Attack (Ewan)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[vehicle.coandaattack]"
  L2_2.sDescription = "[support.vehicle.coandaattack.desc]"
  L2_2.sIcon = "vehicles_heli_md500"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 75000
  L2_2.nFuelCost = 100
  L2_2.oSupport = L0_2
  L2_2.sType = "Heli"
  L1_2.coandaattack = L2_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Coanda Gunship (Ewan)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[vehicle.coandagunship]"
  L2_2.sDescription = "[support.vehicle.coandagunship.desc]"
  L2_2.sIcon = "vehicles_heli_md500"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 100000
  L2_2.nFuelCost = 100
  L2_2.oSupport = L0_2
  L2_2.sType = "Heli"
  L1_2.coandagunship = L2_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Coanda Superiority (Ewan)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[vehicle.coandasuperiority]"
  L2_2.sDescription = "[support.vehicle.coandasuperiority.desc]"
  L2_2.sIcon = "vehicles_heli_md500"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 75000
  L2_2.nFuelCost = 100
  L2_2.oSupport = L0_2
  L2_2.sType = "Heli"
  L1_2.coandasuperiority = L2_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Coanda Transport (Ewan)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[vehicle.coandatransport]"
  L2_2.sDescription = "[support.vehicle.coandatransport.desc]"
  L2_2.sIcon = "vehicles_heli_md500"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 50000
  L2_2.nFuelCost = 60
  L2_2.oSupport = L0_2
  L2_2.sType = "Heli"
  L1_2.coandatransport = L2_2
  L1_2 = mrxcombatairpatrol
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[support.airstrike.combatairpatrol.name]"
  L2_2.sDescription = "[support.airstrike.combatairpatrol.desc]"
  L2_2.sIcon = "support_combat_air_patrol"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 150000
  L2_2.nFuelCost = 280
  L2_2.oSupport = L0_2
  L2_2.sType = "Airstrike"
  L1_2.combatairpatrol = L2_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (Covert)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[support.supply.covert.name]"
  L2_2.sDescription = "[support.supply.covert.desc]"
  L2_2.sIcon = "supplies_covert"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 10000
  L2_2.nFuelCost = 40
  L2_2.oSupport = L0_2
  L2_2.sType = "Supply"
  L1_2.covert = L2_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (CQB)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[support.supply.cqb.name]"
  L2_2.sDescription = "[support.supply.cqb.desc]"
  L2_2.sIcon = "supplies_cqb"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 5000
  L2_2.nFuelCost = 40
  L2_2.oSupport = L0_2
  L2_2.sType = "Supply"
  L1_2.cqb = L2_2
  L1_2 = mrxcruisemissile
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[support.airstrike.cruisemissile.name]"
  L2_2.sDescription = "[support.airstrike.cruisemissile.desc]"
  L2_2.sIcon = "support_cruise_missle"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 400000
  L2_2.nFuelCost = 160
  L2_2.oSupport = L0_2
  L2_2.sType = "Airstrike"
  L1_2.cruisemissile = L2_2
  L1_2 = mrxdaisycutter
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[support.airstrike.daisycutter.name]"
  L2_2.sDescription = "[support.airstrike.daisycutter.desc]"
  L2_2.sIcon = "support_daisy_cutter"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 250000
  L2_2.nFuelCost = 300
  L2_2.oSupport = L0_2
  L2_2.sType = "Airstrike"
  L1_2.daisycutter = L2_2
  L1_2 = mrxboatdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = {}
  L4_2 = "Dinghy"
  L5_2 = "Small Fishing Boat"
  L6_2 = "turbosquid (civ)"
  L7_2 = "dinghy"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L2_2.sName = "[vehicle.dinghy]"
  L2_2.sDescription = "[support.vehicle.dinghy.desc]"
  L2_2.sIcon = "vehicles_boat_turbosquid"
  L2_2.nMaxStock = 99
  L2_2.nCashCost = 15000
  L2_2.nFuelCost = 60
  L2_2.oSupport = L0_2
  L2_2.sType = "Boat"
  L1_2.dinghy = L2_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "DSV Scout Vehicle"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = {}
  L3_2 = "[vehicle.dsvscoutvehicle]"
  L2_2.sName = L3_2
  L3_2 = "[support.vehicle.dsvscoutvehicle.desc]"
  L2_2.sDescription = L3_2
  L2_2.sIcon = "vehicles_scorpion"
  L3_2 = 99
  L2_2.nMaxStock = L3_2
  L3_2 = 150000
  L2_2.nCashCost = L3_2
  L3_2 = 60
  L2_2.nFuelCost = L3_2
  L2_2.oSupport = L0_2
  L2_2.sType = "Light"
  L1_2.dsvscoutvehicle = L2_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Endriago (Attack) (Ewan)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "endriagoattack"
  L3_2 = {}
  L4_2 = "[vehicle.endriagoattack]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.endriagoattack.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_heli_uh1"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 45000
  L3_2.nCashCost = L4_2
  L4_2 = 140
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heli"
  L1_2[L2_2] = L3_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Endriago (Elite) (Ewan)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "endriagoelite"
  L3_2 = {}
  L4_2 = "[vehicle.endriagoelite]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.endriagoelite.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_heli_uh1"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 60000
  L3_2.nCashCost = L4_2
  L4_2 = 140
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heli"
  L1_2[L2_2] = L3_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Endriago (Superiority) (Ewan)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "endriagosuperiority"
  L3_2 = {}
  L4_2 = "[vehicle.endriagosuperiority]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.endriagosuperiority.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_heli_uh1"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 75000
  L3_2.nCashCost = L4_2
  L4_2 = 140
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heli"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "EXT"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "ext"
  L3_2 = {}
  L4_2 = "[vehicle.ext]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.ext.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_truck_ext"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 20000
  L3_2.nCashCost = L4_2
  L4_2 = 60
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "EXT (GL)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "extgl"
  L3_2 = {}
  L4_2 = "[vehicle.extgl]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.extgl.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_truck_ext"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 20000
  L3_2.nCashCost = L4_2
  L4_2 = 60
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (Fiona)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "fiona"
  L3_2 = {}
  L4_2 = "[support.supply.fiona.name]"
  L3_2.sName = L4_2
  L4_2 = "[support.supply.fiona.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "supplies_PMC_crate"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 5000
  L3_2.nCashCost = L4_2
  L4_2 = 40
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Supply"
  L1_2[L2_2] = L3_2
  L1_2 = mrxfuelairbomb
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L1_2 = tSupportData
  L2_2 = "fuelairbomb"
  L3_2 = {}
  L4_2 = "[support.airstrike.fuelairbomb.name]"
  L3_2.sName = L4_2
  L4_2 = "[support.airstrike.fuelairbomb.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "support_fuel_air_bomb"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 200000
  L3_2.nCashCost = L4_2
  L4_2 = 900
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Airstrike"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (GL)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "gl"
  L3_2 = {}
  L4_2 = "[support.supply.gl.name]"
  L3_2.sName = L4_2
  L4_2 = "[support.supply.gl.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "supplies_grenade_launcher"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 10000
  L3_2.nCashCost = L4_2
  L4_2 = 40
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Supply"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (Guerilla)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "gr"
  L3_2 = {}
  L4_2 = "[support.supply.gr.name]"
  L3_2.sName = L4_2
  L4_2 = "[support.supply.gr.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "supplies_GR_crate"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 5000
  L3_2.nCashCost = L4_2
  L4_2 = 40
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Supply"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Guntruck (OC)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "guntruckoc"
  L3_2 = {}
  L4_2 = "[vehicle.guntruckoc]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.guntruckoc.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_truck_transport"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 20000
  L3_2.nCashCost = L4_2
  L4_2 = 100
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "HMMWV (Armored) (50Cal)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "hmmwvarmored50cal"
  L3_2 = {}
  L4_2 = "[vehicle.hmmwvarmored50cal]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.hmmwvarmored50cal.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_truck_hmmwv"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 20000
  L3_2.nCashCost = L4_2
  L4_2 = 120
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "HMMWV (Armored) (GL)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "hmmwvarmoredgl"
  L3_2 = {}
  L4_2 = "[vehicle.hmmwvarmoredgl]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.hmmwvarmoredgl.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_truck_hmmwv"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 25000
  L3_2.nCashCost = L4_2
  L4_2 = 120
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "HMMWV (Armored) (TOW)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "hmmwvarmoredtow"
  L3_2 = {}
  L4_2 = "[vehicle.hmmwvarmoredtow]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.hmmwvarmoredtow.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_truck_hmmwv"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 35000
  L3_2.nCashCost = L4_2
  L4_2 = 120
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "HMMWV (Avenger)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "hmmwvavenger"
  L3_2 = {}
  L4_2 = "[vehicle.hmmwvavenger]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.hmmwvavenger.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_truck_hmmwv"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 45000
  L3_2.nCashCost = L4_2
  L4_2 = 120
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "HMMWV (Softtop)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "hmmwvsofttop"
  L3_2 = {}
  L4_2 = "[vehicle.hmmwvsofttop]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.hmmwvsofttop.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_truck_hmmwv"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 15000
  L3_2.nCashCost = L4_2
  L4_2 = 120
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Civilian"
  L1_2[L2_2] = L3_2
  L1_2 = mrxboatdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = {}
  L4_2 = "Jetski (Civ)"
  L5_2 = "Jetski (PR)"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "jetskiciv"
  L3_2 = {}
  L4_2 = "[vehicle.jetskiciv]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.jetskiciv.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_boat_jetski"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 5000
  L3_2.nCashCost = L4_2
  L4_2 = 40
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Boat"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = {}
  L4_2 = "Phoenix (crappy)"
  L5_2 = "RTR (crappy)"
  L6_2 = "Valiant (crappy)"
  L7_2 = "Pony (crappy)"
  L8_2 = "Van (crappy)"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L3_2[5] = L8_2
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "junkers"
  L3_2 = {}
  L4_2 = "[vehicle.junkers]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.junkers.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_car_pony"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 5000
  L3_2.nCashCost = L4_2
  L4_2 = 60
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Civilian"
  L1_2[L2_2] = L3_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Ka29b (Ewan)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "ka29b"
  L3_2 = {}
  L4_2 = "[vehicle.ka29b]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.ka29b.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_heli_ka28"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 40000
  L3_2.nCashCost = L4_2
  L4_2 = 160
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heli"
  L1_2[L2_2] = L3_2
  L1_2 = mrxlaserguidedbomb
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L1_2 = tSupportData
  L2_2 = "laserguidedbomb"
  L3_2 = {}
  L4_2 = "[support.airstrike.laserguidedbomb.name]"
  L3_2.sName = L4_2
  L4_2 = "[support.airstrike.laserguidedbomb.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "support_laser_guided_bomb"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 200000
  L3_2.nCashCost = L4_2
  L4_2 = 460
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Airstrike"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "LAVIII (25mm)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "laviii25mm"
  L3_2 = {}
  L4_2 = "[vehicle.laviii25mm]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.laviii25mm.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_apc_lavii"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 25000
  L3_2.nCashCost = L4_2
  L4_2 = 140
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "LAVIII (Minigun)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "laviii50cal"
  L3_2 = {}
  L4_2 = "[vehicle.laviii50cal]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.laviii50cal.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_apc_lavii"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 20000
  L3_2.nCashCost = L4_2
  L4_2 = 140
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "LAVIII (AD)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "laviiiad"
  L3_2 = {}
  L4_2 = "[vehicle.laviiiad]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.laviiiad.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_apc_lavii"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 30000
  L3_2.nCashCost = L4_2
  L4_2 = 140
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "LAVIII (AT)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "laviiiat"
  L3_2 = {}
  L4_2 = "[vehicle.laviiiat]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.laviiiat.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_apc_lavii"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 30000
  L3_2.nCashCost = L4_2
  L4_2 = 140
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "LAVIII (MEWSS)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "laviiimewss"
  L3_2 = {}
  L4_2 = "[vehicle.laviiimewss]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.laviiimewss.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_apc_lavii"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 30000
  L3_2.nCashCost = L4_2
  L4_2 = 140
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "LAVIII (MGS)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "laviiimgs"
  L3_2 = {}
  L4_2 = "[vehicle.laviiimgs]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.laviiimgs.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_apc_lavii"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 40000
  L3_2.nCashCost = L4_2
  L4_2 = 160
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (Light MG)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "lightmg"
  L3_2 = {}
  L4_2 = "[support.supply.lightmg.name]"
  L3_2.sName = L4_2
  L4_2 = "[support.supply.lightmg.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "supplies_light_mg"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 5000
  L3_2.nCashCost = L4_2
  L4_2 = 40
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Supply"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = {}
  L4_2 = "L300"
  L5_2 = "W8 (normal)"
  L6_2 = "W12 (normal)"
  L7_2 = "Vanquish"
  L8_2 = "ESV (Lowrider)"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L3_2[5] = L8_2
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "luxury"
  L3_2 = {}
  L4_2 = "[vehicle.luxury]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.luxury.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_car_l300"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 25000
  L3_2.nCashCost = L4_2
  L4_2 = 60
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Civilian"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "M113 AA (GR)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Mi26 (PMC) (Driver)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "m113aagr"
  L3_2 = {}
  L4_2 = "[vehicle.m113aagr]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.m113aagr.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_apc_m113"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 35000
  L3_2.nCashCost = L4_2
  L4_2 = 100
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heavy"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "M113 AA (VZ)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Mi26 (PMC) (Driver)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "m113aavz"
  L3_2 = {}
  L4_2 = "[vehicle.m113aavz]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.m113aavz.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_apc_m113"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 40000
  L3_2.nCashCost = L4_2
  L4_2 = 100
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heavy"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "M113 (GR)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Mi26 (PMC) (Driver)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "m113gr"
  L3_2 = {}
  L4_2 = "[vehicle.m113gr]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.m113gr.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_apc_m113"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 30000
  L3_2.nCashCost = L4_2
  L4_2 = 100
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heavy"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "M113 Jammer (VZ)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Mi26 (PMC) (Driver)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "m113jammervz"
  L3_2 = {}
  L4_2 = "[vehicle.m113jammervz]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.m113jammervz.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_apc_m113"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 40000
  L3_2.nCashCost = L4_2
  L4_2 = 100
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heavy"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "M113 (VZ)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Mi26 (PMC) (Driver)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "m113vz"
  L3_2 = {}
  L4_2 = "[vehicle.m113vz]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.m113vz.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_apc_m113"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 35000
  L3_2.nCashCost = L4_2
  L4_2 = 100
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heavy"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "M151 (MG) (GR)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "m15150calgr"
  L3_2 = {}
  L4_2 = "[vehicle.m15150calgr]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.m15150calgr.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_truck_m151"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 15000
  L3_2.nCashCost = L4_2
  L4_2 = 60
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "M151 .50Cal (VZ)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "m15150calvz"
  L3_2 = {}
  L4_2 = "[vehicle.m15150calvz]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.m15150calvz.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_truck_m151"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 15000
  L3_2.nCashCost = L4_2
  L4_2 = 60
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "M151 Softtop (GR)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "m151softtopgr"
  L3_2 = {}
  L4_2 = "[vehicle.m151softtopgr]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.m151softtopgr.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_truck_m151"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 10000
  L3_2.nCashCost = L4_2
  L4_2 = 60
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Civilian"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "M151 Softtop (VZ)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "m151softtopvz"
  L3_2 = {}
  L4_2 = "[vehicle.m151softtopvz]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.m151softtopvz.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_truck_m151"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 10000
  L3_2.nCashCost = L4_2
  L4_2 = 60
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Civilian"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "M1A2"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Mi26 (PMC) (Driver)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "m1a2"
  L3_2 = {}
  L4_2 = "[vehicle.m1a2]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.m1a2.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_tank_m1a2"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 425000
  L3_2.nCashCost = L4_2
  L4_2 = 240
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heavy"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "M2A3"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Mi26 (PMC) (Driver)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "m2a3"
  L3_2 = {}
  L4_2 = "[vehicle.m2a3]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.m2a3.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_tank_m6"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 150000
  L3_2.nCashCost = L4_2
  L4_2 = 160
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heavy"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "M35 (AA) (GR)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "m35aagr"
  L3_2 = {}
  L4_2 = "[vehicle.m35aagr]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.m35aagr.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_truck_m35"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 25000
  L3_2.nCashCost = L4_2
  L4_2 = 80
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "M35 (AA) (VZ)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "m35aavz"
  L3_2 = {}
  L4_2 = "[vehicle.m35aavz]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.m35aavz.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_truck_m35"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 30000
  L3_2.nCashCost = L4_2
  L4_2 = 80
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "M35 (Guntruck) (GR)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "m35guntruckgr"
  L3_2 = {}
  L4_2 = "[vehicle.m35guntruckgr]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.m35guntruckgr.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_truck_m35"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 15000
  L3_2.nCashCost = L4_2
  L4_2 = 60
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "M35 (Guntruck) (VZ)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "m35guntruckvz"
  L3_2 = {}
  L4_2 = "[vehicle.m35guntruckvz]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.m35guntruckvz.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_truck_m35"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 20000
  L3_2.nCashCost = L4_2
  L4_2 = 60
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "M551"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Mi26 (PMC) (Driver)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "m551"
  L3_2 = {}
  L4_2 = "[vehicle.m551]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.m551.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_tank_m551"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 45000
  L3_2.nCashCost = L4_2
  L4_2 = 140
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heavy"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Mattias Chopper"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "mattiaschopper"
  L3_2 = {}
  L4_2 = "[vehicle.mattiaschopper]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.mattiaschopper.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_motorcycle_chopper"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 25000
  L3_2.nCashCost = L4_2
  L4_2 = 40
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Civilian"
  L1_2[L2_2] = L3_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "MH53J (Ewan)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "mh53j"
  L3_2 = {}
  L4_2 = "[vehicle.mh53j]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.mh53j.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_heli_mi26"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 50000
  L3_2.nCashCost = L4_2
  L4_2 = 140
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heli"
  L1_2[L2_2] = L3_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Mi26 (CH) (Ewan)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "mi26ch"
  L3_2 = {}
  L4_2 = "[vehicle.mi26ch]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.mi26ch.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_heli_mi26"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 50000
  L3_2.nCashCost = L4_2
  L4_2 = 140
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heli"
  L1_2[L2_2] = L3_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Mi26 (VZ) (Ewan)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "mi26vz"
  L3_2 = {}
  L4_2 = "[vehicle.mi26vz]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.mi26vz.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_heli_mi26"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 50000
  L3_2.nCashCost = L4_2
  L4_2 = 140
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heli"
  L1_2[L2_2] = L3_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Mi35 (Ewan)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "mi35"
  L3_2 = {}
  L4_2 = "[vehicle.mi35]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.mi35.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_heli_mi35"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 250000
  L3_2.nCashCost = L4_2
  L4_2 = 200
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heli"
  L1_2[L2_2] = L3_2
  L1_2 = mrxmoab
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L1_2 = tSupportData
  L2_2 = "moab"
  L3_2 = {}
  L4_2 = "[support.airstrike.moab.name]"
  L3_2.sName = L4_2
  L4_2 = "[support.airstrike.moab.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "support_moab"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 500000
  L3_2.nCashCost = L4_2
  L4_2 = 400
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Airstrike"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = {}
  L4_2 = "Monster Ridgeline"
  L5_2 = "EXT (Monster)"
  L6_2 = "Cougar"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "monster"
  L3_2 = {}
  L4_2 = "[vehicle.monster]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.monster.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_car_monsterTruck"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 20000
  L3_2.nCashCost = L4_2
  L4_2 = 60
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Civilian"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Monster Truck"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "monstertruck"
  L3_2 = {}
  L4_2 = "[vehicle.monstertruck]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.monstertruck.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_car_monsterCar"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 40000
  L3_2.nCashCost = L4_2
  L4_2 = 60
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Civilian"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "NGLV (MG)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "nglv50cal"
  L3_2 = {}
  L4_2 = "[vehicle.nglv50cal]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.nglv50cal.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_truck_nglv"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 35000
  L3_2.nCashCost = L4_2
  L4_2 = 80
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "NGLV (GL)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "nglvgl"
  L3_2 = {}
  L4_2 = "[vehicle.nglvgl]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.nglvgl.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_truck_nglv"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 45000
  L3_2.nCashCost = L4_2
  L4_2 = 80
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (OC)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "oc"
  L3_2 = {}
  L4_2 = "[support.supply.oc.name]"
  L3_2.sName = L4_2
  L4_2 = "[support.supply.oc.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "supplies_OC_crate"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 5000
  L3_2.nCashCost = L4_2
  L4_2 = 40
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Supply"
  L1_2[L2_2] = L3_2
  L1_2 = mrxboatdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Omen"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "omen"
  L3_2 = {}
  L4_2 = "[vehicle.omen]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.omen.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_boat_omen"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 25000
  L3_2.nCashCost = L4_2
  L4_2 = 60
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Boat"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Panhard (Assault)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "panhardassault"
  L3_2 = {}
  L4_2 = "[vehicle.panhardassault]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.panhardassault.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_light_vulcan"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 400000
  L3_2.nCashCost = L4_2
  L4_2 = 60
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxboatdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Patrol Boat (PMC)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "patrolboatpmc"
  L3_2 = {}
  L4_2 = "[vehicle.patrolboatpmc]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.patrolboatpmc.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_boat_cigarette"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 500000
  L3_2.nCashCost = L4_2
  L4_2 = 60
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Boat"
  L1_2[L2_2] = L3_2
  L1_2 = mrxboatdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Patrol Boat (VZ)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "patrolboatvz"
  L3_2 = {}
  L4_2 = "[vehicle.patrolboatvz]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.patrolboatvz.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_boat_Piranha"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 75000
  L3_2.nCashCost = L4_2
  L4_2 = 80
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Boat"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "PGZ95"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Mi26 (PMC) (Driver)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "pgz95"
  L3_2 = {}
  L4_2 = "[vehicle.pgz95]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.pgz95.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_tank_pgz95"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 150000
  L3_2.nCashCost = L4_2
  L4_2 = 160
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heavy"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "PGZ95 Command"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Mi26 (PMC) (Driver)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "pgz95command"
  L3_2 = {}
  L4_2 = "[vehicle.pgz95command]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.pgz95command.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_tank_pgz95"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 165000
  L3_2.nCashCost = L4_2
  L4_2 = 160
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heavy"
  L1_2[L2_2] = L3_2
  L1_2 = mrxboatdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Piranha"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "piranha"
  L3_2 = {}
  L4_2 = "[vehicle.piranha]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.piranha.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_boat_prestes"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 45000
  L3_2.nCashCost = L4_2
  L4_2 = 60
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Boat"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "PLZ45"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Mi26 (PMC) (Driver)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "plz45"
  L3_2 = {}
  L4_2 = "[vehicle.plz45]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.plz45.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_tank_plz45"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 100000
  L3_2.nCashCost = L4_2
  L4_2 = 160
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heavy"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (Pirate)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "pr"
  L3_2 = {}
  L4_2 = "[support.supply.pr.name]"
  L3_2.sName = L4_2
  L4_2 = "[support.supply.pr.desc]"
  L3_2.sDescription = L4_2
  L3_2.sIcon = "supplies_cqb"
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 5000
  L3_2.nCashCost = L4_2
  L4_2 = 40
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Supply"
  L1_2[L2_2] = L3_2
  L1_2 = mrxrocketartillery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L1_2 = tSupportData
  L2_2 = "rocketartillery"
  L3_2 = {}
  L4_2 = "[support.airstrike.rocketartillery.name]"
  L3_2.sName = L4_2
  L4_2 = "[support.airstrike.rocketartillery.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "support_rocket_artillery"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 350000
  L3_2.nCashCost = L4_2
  L4_2 = 280
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Airstrike"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (RPG)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "rpg"
  L3_2 = {}
  L4_2 = "[support.supply.rpg.name]"
  L3_2.sName = L4_2
  L4_2 = "[support.supply.rpg.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "supplies_rpg"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 10000
  L3_2.nCashCost = L4_2
  L4_2 = 40
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Supply"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Scorpion90"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Mi26 (PMC) (Driver)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "scorpion90"
  L3_2 = {}
  L4_2 = "[vehicle.scorpion90]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.scorpion90.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_tank_scorpion"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 75000
  L3_2.nCashCost = L4_2
  L4_2 = 140
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heavy"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Sidecar Motorcycle"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "sidecarmotorcycle"
  L3_2 = {}
  L4_2 = "[vehicle.sidecarmotorcycle]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.sidecarmotorcycle.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_motorcycle_sidecar"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 50000
  L3_2.nCashCost = L4_2
  L4_2 = 40
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxsmartbomb
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L1_2 = tSupportData
  L2_2 = "smartbomb"
  L3_2 = {}
  L4_2 = "[support.airstrike.smartbomb.name]"
  L3_2.sName = L4_2
  L4_2 = "[support.airstrike.smartbomb.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "support_smart_bomb"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 300000
  L3_2.nCashCost = L4_2
  L4_2 = 200
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Airstrike"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (Sniper CH)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "sniperch"
  L3_2 = {}
  L4_2 = "[support.supply.sniperch.name]"
  L3_2.sName = L4_2
  L4_2 = "[support.supply.sniperch.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "supplies_CH_sniper"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 10000
  L3_2.nCashCost = L4_2
  L4_2 = 40
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Supply"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (Sniper RU)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "sniperru"
  L3_2 = {}
  L4_2 = "[support.supply.sniperru.name]"
  L3_2.sName = L4_2
  L4_2 = "[support.supply.sniperru.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "supplies_sniper_kit"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 10000
  L3_2.nCashCost = L4_2
  L4_2 = 40
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Supply"
  L1_2[L2_2] = L3_2
  L1_2 = mrxboatdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Speed Boat"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "speedboat"
  L3_2 = {}
  L4_2 = "[vehicle.speedboat]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.speedboat.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_boat_cigarette"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 10000
  L3_2.nCashCost = L4_2
  L4_2 = 60
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Boat"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = {}
  L4_2 = "Vanquish (racing)"
  L5_2 = "Veyron"
  L6_2 = "W12 (sprint)"
  L7_2 = "W12 (Z12) Racer"
  L8_2 = "W12 (Z12)"
  L9_2 = "Phoenix (racing)"
  L10_2 = "RTR (racing)"
  L11_2 = "L300 (Racing)"
  L12_2 = "CRX (racing)"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L3_2[5] = L8_2
  L3_2[6] = L9_2
  L3_2[7] = L10_2
  L3_2[8] = L11_2
  L3_2[9] = L12_2
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "sports"
  L3_2 = {}
  L4_2 = "[vehicle.sports]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.sports.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_car_phoenix"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 20000
  L3_2.nCashCost = L4_2
  L4_2 = 60
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Civilian"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Stingray II"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Mi26 (PMC) (Driver)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "stingrayii"
  L3_2 = {}
  L4_2 = "[vehicle.stingrayii]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.stingrayii.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_tank_stingray2"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 50000
  L3_2.nCashCost = L4_2
  L4_2 = 140
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heavy"
  L1_2[L2_2] = L3_2
  L1_2 = mrxstrategicmissile
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L1_2 = tSupportData
  L2_2 = "strategicmissile"
  L3_2 = {}
  L4_2 = "[support.airstrike.strategicmissile.name]"
  L3_2.sName = L4_2
  L4_2 = "[support.airstrike.strategicmissile.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "support_strategic_missle"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 400000
  L3_2.nCashCost = L4_2
  L4_2 = 220
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Airstrike"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (Support)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "Support"
  L3_2 = {}
  L4_2 = "[support.supply.Support.name]"
  L3_2.sName = L4_2
  L4_2 = "[support.supply.Support.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "supplies_rpg"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 5000
  L3_2.nCashCost = L4_2
  L4_2 = 40
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Supply"
  L1_2[L2_2] = L3_2
  L1_2 = mrxsurgicalstrike
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L1_2 = tSupportData
  L2_2 = "surgicalstrike"
  L3_2 = {}
  L4_2 = "[support.airstrike.surgicalstrike.name]"
  L3_2.sName = L4_2
  L4_2 = "[support.airstrike.surgicalstrike.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "support_surgical_strike"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 350000
  L3_2.nCashCost = L4_2
  L4_2 = 280
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Airstrike"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "SX2150 (MLRS)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "sx2150mlrs"
  L3_2 = {}
  L4_2 = "[vehicle.sx2150mlrs]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.sx2150mlrs.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_truck_sx2150"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 60000
  L3_2.nCashCost = L4_2
  L4_2 = 120
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "T300 (M60)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "t300m60"
  L3_2 = {}
  L4_2 = "[vehicle.t300m60]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.t300m60.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_truck_t300"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 20000
  L3_2.nCashCost = L4_2
  L4_2 = 60
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Tank Bike"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "tankbike"
  L3_2 = {}
  L4_2 = "[vehicle.tankbike]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.tankbike.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_motorcycle_tankbike"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 750000
  L3_2.nCashCost = L4_2
  L4_2 = 60
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxtankbuster
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L1_2 = tSupportData
  L2_2 = "tankbuster"
  L3_2 = {}
  L4_2 = "[support.airstrike.tankbuster.name]"
  L3_2.sName = L4_2
  L4_2 = "[support.airstrike.tankbuster.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "support_tank_buster"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 100000
  L3_2.nCashCost = L4_2
  L4_2 = 200
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Airstrike"
  L1_2[L2_2] = L3_2
  L1_2 = mrxboatdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Turbosquid (GR)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "turbosquidgr"
  L3_2 = {}
  L4_2 = "[vehicle.turbosquidgr]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.turbosquidgr.desc]"
  L3_2.sDescription = L4_2
  L3_2.sIcon = "vehicles_boat_turbosquid"
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 5000
  L3_2.nCashCost = L4_2
  L4_2 = 40
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Boat"
  L1_2[L2_2] = L3_2
  L1_2 = mrxboatdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Turbosquid (OC)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "turbosquidoc"
  L3_2 = {}
  L4_2 = "[vehicle.turbosquidoc]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.turbosquidoc.desc]"
  L3_2.sDescription = L4_2
  L3_2.sIcon = "vehicles_boat_turbosquid"
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 5000
  L3_2.nCashCost = L4_2
  L4_2 = 40
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Boat"
  L1_2[L2_2] = L3_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "UH1 Transport (GR) (Ewan)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "uh1transportgr"
  L3_2 = {}
  L4_2 = "[vehicle.uh1transportgr]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.uh1transportgr.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_heli_uh1"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 40000
  L3_2.nCashCost = L4_2
  L4_2 = 80
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heli"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = {}
  L4_2 = "Van (Commercial)"
  L5_2 = "Van (Green)"
  L6_2 = "Van (Racing)"
  L7_2 = "Van (Taxi)"
  L8_2 = "Garbage Truck"
  L9_2 = "Impact"
  L10_2 = "Impact (SUT)"
  L11_2 = "Escort"
  L12_2 = "Ambulance"
  L13_2 = "Armored Bank Truck"
  L14_2 = "Transport Truck"
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L3_2[5] = L8_2
  L3_2[6] = L9_2
  L3_2[7] = L10_2
  L3_2[8] = L11_2
  L3_2[9] = L12_2
  L3_2[10] = L13_2
  L3_2[11] = L14_2
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "utility"
  L3_2 = {}
  L4_2 = "[vehicle.utility]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.utility.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_car_van"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 20000
  L3_2.nCashCost = L4_2
  L4_2 = 60
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Civilian"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Valiant (Python)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "valiantpython"
  L3_2 = {}
  L4_2 = "[vehicle.valiantpython]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.valiantpython.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_car_valiant"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 50000
  L3_2.nCashCost = L4_2
  L4_2 = 60
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Civilian"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Veyron (Assault)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "veyronassault"
  L3_2 = {}
  L4_2 = "[vehicle.veyronassault]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.veyronassault.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_light_urban_commando"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 1000000
  L3_2.nCashCost = L4_2
  L4_2 = 60
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Light"
  L1_2[L2_2] = L3_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "WZ10 (Ewan)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "wz10"
  L3_2 = {}
  L4_2 = "[vehicle.wz10]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.wz10.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_heli_wz10"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 350000
  L3_2.nCashCost = L4_2
  L4_2 = 200
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heli"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "WZ551"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Mi26 (PMC) (Driver)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "wz551"
  L3_2 = {}
  L4_2 = "[vehicle.wz551]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.wz551.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_apc_wz551"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 70000
  L3_2.nCashCost = L4_2
  L4_2 = 160
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heavy"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "ZBD2000"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Mi26 (PMC) (Driver)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "zbd2000"
  L3_2 = {}
  L4_2 = "[vehicle.zbd2000]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.zbd2000.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_apc_zbd2000"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 85000
  L3_2.nCashCost = L4_2
  L4_2 = 160
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heavy"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "ZTZ63a"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Mi26 (PMC) (Driver)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "ztz63a"
  L3_2 = {}
  L4_2 = "[vehicle.ztz63a]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.ztz63a.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_tank_ztz63"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 100000
  L3_2.nCashCost = L4_2
  L4_2 = 180
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heavy"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "ZTZ98"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Mi26 (PMC) (Driver)"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "ztz98"
  L3_2 = {}
  L4_2 = "[vehicle.ztz98]"
  L3_2.sName = L4_2
  L4_2 = "[support.vehicle.ztz98.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "vehicles_tank_ztz98"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 425000
  L3_2.nCashCost = L4_2
  L4_2 = 220
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Heavy"
  L1_2[L2_2] = L3_2
  L1_2 = mrxbunkerbuster
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L3_2 = "SetBomb"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "Nuclear Bunker Buster Projectile"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "nuke"
  L3_2 = {}
  L4_2 = "[AllCon003.Terms.Reward]"
  L3_2.sName = L4_2
  L4_2 = "[support.nuke.desc]"
  L3_2.sDescription = L4_2
  L3_2.sIcon = "support_bunker_buster"
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 1000000
  L3_2.nCashCost = L4_2
  L4_2 = 500
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Airstrike"
  L1_2[L2_2] = L3_2
  L1_2 = mrxclusterbomb
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L3_2 = "SetRecruit"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "Fiona"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Support Vehicle (OV10) low altitude"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "upclusterbomb"
  L3_2 = {}
  L4_2 = "[support.airstrike.upclusterbomb.name]"
  L3_2.sName = L4_2
  L3_2.sDescription = "[support.airstrike.clusterbomb.desc]"
  L3_2.sIcon = "support_cluster_bomb"
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 500000
  L3_2.nCashCost = L4_2
  L4_2 = 180
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Airstrike"
  L1_2[L2_2] = L3_2
  L1_2 = mrxtankbuster
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L3_2 = "SetRecruit"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "Fiona"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Support Vehicle (OV10) low altitude"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "uptankbuster"
  L3_2 = {}
  L4_2 = "[support.airstrike.uptankbuster.name]"
  L3_2.sName = L4_2
  L4_2 = "[support.airstrike.tankbuster.desc]"
  L3_2.sDescription = L4_2
  L4_2 = "support_tank_buster"
  L3_2.sIcon = L4_2
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 350000
  L3_2.nCashCost = L4_2
  L4_2 = 180
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Airstrike"
  L1_2[L2_2] = L3_2
  L1_2 = mrxcombatairpatrol
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L3_2 = "SetRecruit"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "Fiona"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Support Vehicle (OV10) low altitude"
  L1_2(L2_2, L3_2)
  L1_2 = tSupportData
  L2_2 = "upcombatairpatrol"
  L3_2 = {}
  L4_2 = "[support.airstrike.upcap.name]"
  L3_2.sName = L4_2
  L3_2.sDescription = "[support.airstrike.combatairpatrol.desc]"
  L3_2.sIcon = "support_combat_air_patrol"
  L4_2 = 99
  L3_2.nMaxStock = L4_2
  L4_2 = 400000
  L3_2.nCashCost = L4_2
  L4_2 = 200
  L3_2.nFuelCost = L4_2
  L3_2.oSupport = L0_2
  L3_2.sType = "Airstrike"
  L1_2[L2_2] = L3_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Ka29b (Ewan)"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "ChiCon001_Copter"
  L3_2 = {}
  L4_2 = "[vehicle.ka29b]"
  L3_2.sName = L4_2
  L4_2 = "vehicles_heli_ka28"
  L3_2.sIcon = L4_2
  L4_2 = "nFreebieQty"
  L5_2 = 1
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxsurgicalstrike
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Support Vehicle (Q5)"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "ChiCon001_Airstrike"
  L3_2 = {}
  L4_2 = "[support.airstrike.surgicalstrike.name]"
  L3_2.sName = L4_2
  L4_2 = "support_surgical_strike"
  L3_2.sIcon = L4_2
  L4_2 = "nFreebieQty"
  L5_2 = 3
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxrocketartillery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L1_2 = tFreebieData
  L2_2 = "ChiCon001_RocketArtillery"
  L3_2 = {}
  L4_2 = "[support.airstrike.rocketartillery.name]"
  L3_2.sName = L4_2
  L4_2 = "support_rocket_artillery"
  L3_2.sIcon = L4_2
  L4_2 = "nFreebieQty"
  L5_2 = 3
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxgunship
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L1_2 = tFreebieData
  L2_2 = "Gunship"
  L3_2 = {}
  L4_2 = "[support.airstrike.gunship.name]"
  L3_2.sName = L4_2
  L4_2 = "vehicles_plane_c130"
  L3_2.sIcon = L4_2
  L4_2 = "nFreebieQty"
  L5_2 = 1
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxlaserguidedbomb
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L3_2 = "SetBomb"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "Practice LGB Projectile"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "Practice Laser"
  L3_2 = {}
  L4_2 = "[support.airstrike.laserguidedbomb.name]"
  L3_2.sName = L4_2
  L4_2 = "support_laser_guided_bomb"
  L3_2.sIcon = L4_2
  L4_2 = "nFreebieQty"
  L5_2 = 2
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxsatelliteguidedbomb
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L3_2 = "SetCost"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = 0
  L1_2(L2_2, L3_2)
  L3_2 = "SetBomb"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "Practice LGB Projectile"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "Practice Satellite"
  L3_2 = {}
  L4_2 = "[support.airstrike.satelliteguidedbomb.name]"
  L3_2.sName = L4_2
  L4_2 = "support_satellite_guided_bomb"
  L3_2.sIcon = L4_2
  L4_2 = "nFreebieQty"
  L5_2 = 1
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxsatelliteguidedbomb
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L3_2 = "SetCost"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = 0
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Support Vehicle (Tucano)"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "VzaCon01_SatBomb"
  L3_2 = {}
  L4_2 = "[support.airstrike.satelliteguidedbomb.name]"
  L3_2.sName = L4_2
  L4_2 = "support_satellite_guided_bomb"
  L3_2.sIcon = L4_2
  L4_2 = "nFreebieQty"
  L5_2 = 1
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxclusterbomb
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Support Vehicle (Tucano)"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "VzaCon001_Airstrike"
  L3_2 = {}
  L3_2.sName = "[support.airstrike.clusterbomb.name]"
  L3_2.sIcon = "support_cluster_bomb"
  L4_2 = "nFreebieQty"
  L5_2 = 3
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxclusterbomb
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Support Vehicle (OV10) low altitude"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "OC_ClusterBomb"
  L3_2 = {}
  L3_2.sName = "[support.airstrike.clusterbomb.name]"
  L3_2.sIcon = "support_cluster_bomb"
  L4_2 = "nFreebieQty"
  L5_2 = 1
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxbombingrun
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Support Vehicle (OV10) low altitude"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "OC_BombingRun"
  L3_2 = {}
  L3_2.sName = "[support.airstrike.bombingrun.name]"
  L3_2.sIcon = "support_bombing_run"
  L4_2 = "nFreebieQty"
  L5_2 = 1
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxartillery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Guerilla Soldier"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "GurCon001_Artillery"
  L3_2 = {}
  L3_2.sName = "[support.airstrike.artillery.name]"
  L3_2.sIcon = "support_artillery"
  L4_2 = "nFreebieQty"
  L5_2 = 1
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxartillery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Guerilla Soldier"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "GurCon002_Artillery"
  L3_2 = {}
  L3_2.sName = "[support.airstrike.artillery.name]"
  L3_2.sIcon = "support_artillery"
  L4_2 = "nFreebieQty"
  L5_2 = 3
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxlaserguidedbomb
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Support Vehicle (Q5)"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "ChiCon002_Bombs"
  L3_2 = {}
  L4_2 = "[support.airstrike.laserguidedbomb.name]"
  L3_2.sName = L4_2
  L4_2 = "support_laser_guided_bomb"
  L3_2.sIcon = L4_2
  L4_2 = "nFreebieQty"
  L5_2 = 4
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (AA)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Coanda Transport (Driver)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "OilCon001_Crate"
  L3_2 = {}
  L3_2.sName = "[support.supply.aa.name]"
  L3_2.sDescription = "[support.supply.aa.desc]"
  L4_2 = "HUD_ICON_support_crate"
  L3_2.sIcon = L4_2
  L4_2 = "nFreebieQty"
  L5_2 = 4
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxbunkerbuster
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L3_2 = "SetBomb"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "Nuclear Bunker Buster Projectile"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "PmcCon004_Nuke"
  L3_2 = {}
  L4_2 = "[AllCon003.Terms.Reward]"
  L3_2.sName = L4_2
  L3_2.sIcon = "support_bunker_buster"
  L4_2 = "nFreebieQty"
  L5_2 = 1
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxbunkerbuster
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L1_2 = tFreebieData
  L2_2 = "Bunker Buster"
  L3_2 = {}
  L3_2.sName = "[support.airstrike.bunkerbuster.name]"
  L3_2.sIcon = "support_bunker_buster"
  L4_2 = "nFreebieQty"
  L5_2 = 1
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "_global_ramp_roadlessrider"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "Ramp Delivery"
  L3_2 = {}
  L4_2 = "TEMP: Ramp Delivery"
  L3_2.sName = L4_2
  L4_2 = "vehicles_heli_uh1"
  L3_2.sIcon = L4_2
  L4_2 = "nFreebieQty"
  L5_2 = 10
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = MrxOilCon002Delivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L1_2 = tFreebieData
  L2_2 = "OilCon002_Delivery"
  L3_2 = {}
  L4_2 = "[support.supply.listeningpost.name]"
  L3_2.sName = L4_2
  L4_2 = "vehicles_heli_uh1"
  L3_2.sIcon = L4_2
  L4_2 = "nFreebieQty"
  L5_2 = nil
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = MrxMunitionsPickup
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "UH1 Transport (GR) (Driver)"
  L1_2(L2_2, L3_2)
  L3_2 = "SetFinalDestination"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "05_gur_hq_lz_playerone"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "GurCon001_Munitions"
  L3_2 = {}
  L4_2 = "[support.munition.name]"
  L3_2.sName = L4_2
  L4_2 = "vehicles_heli_uh1"
  L3_2.sIcon = L4_2
  L4_2 = "nFreebieQty"
  L5_2 = nil
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = MrxMunitionsPickup
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "UH1 Transport (PMC) (Ghost)"
  L1_2(L2_2, L3_2)
  L3_2 = "SetFinalDestination"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "01_pmc_hq_lz_playerone"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "MunitionsPickup"
  L3_2 = {}
  L4_2 = "[support.munition.name]"
  L3_2.sName = L4_2
  L4_2 = "vehicles_heli_uh1"
  L3_2.sIcon = L4_2
  L4_2 = "nFreebieQty"
  L5_2 = nil
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = MrxSupportPickup
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L3_2 = "SetPickupVehicle"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "UH1 Transport (PMC) (Extraction)"
  L1_2(L2_2, L3_2)
  L3_2 = "SetFinalDestination"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "01_pmc_hq_lz_playerone"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "Extraction_PMC"
  L3_2 = {}
  L4_2 = "[support.extraction.name]"
  L3_2.sName = L4_2
  L4_2 = "vehicles_heli_uh1"
  L3_2.sIcon = L4_2
  L4_2 = "nFreebieQty"
  L5_2 = nil
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = MrxSupportPickup
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L3_2 = "SetPickupVehicle"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "MH53J (Extraction)"
  L1_2(L2_2, L3_2)
  L3_2 = "SetFinalDestination"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "07_all_hq_lz_playerone"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "Extraction_AL"
  L3_2 = {}
  L4_2 = "[support.extraction.name]"
  L3_2.sName = L4_2
  L4_2 = "vehicles_heli_uh1"
  L3_2.sIcon = L4_2
  L4_2 = "nFreebieQty"
  L5_2 = nil
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = MrxSupportPickup
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L3_2 = "SetPickupVehicle"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "Ka29b (Extraction)"
  L1_2(L2_2, L3_2)
  L3_2 = "SetFinalDestination"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "12_chi_hq_lz_playerone"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "Extraction_CH"
  L3_2 = {}
  L4_2 = "[support.extraction.name]"
  L3_2.sName = L4_2
  L4_2 = "vehicles_heli_ka28"
  L3_2.sIcon = L4_2
  L4_2 = "nFreebieQty"
  L5_2 = nil
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = MrxSupportPickup
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L3_2 = "SetPickupVehicle"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "UH1 Transport (GR) (Extraction)"
  L1_2(L2_2, L3_2)
  L3_2 = "SetFinalDestination"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "05_gur_hq_lz_playerone"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "Extraction_GR"
  L3_2 = {}
  L4_2 = "[support.extraction.name]"
  L3_2.sName = L4_2
  L4_2 = "vehicles_heli_uh1"
  L3_2.sIcon = L4_2
  L4_2 = "nFreebieQty"
  L5_2 = nil
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = MrxSupportPickup
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L3_2 = "SetPickupVehicle"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "Coanda Transport (Extraction)"
  L1_2(L2_2, L3_2)
  L3_2 = "SetFinalDestination"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "02_oil_hq_lz_playerone"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "Extraction_OC"
  L3_2 = {}
  L4_2 = "[support.extraction.name]"
  L3_2.sName = L4_2
  L3_2.sIcon = "vehicles_heli_md500"
  L4_2 = "nFreebieQty"
  L5_2 = nil
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = MrxSupportPickup
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L3_2 = "SetPickupVehicle"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "Alouette3 Transport (PR) (Extraction)"
  L1_2(L2_2, L3_2)
  L3_2 = "SetFinalDestination"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "08_pir_hq_lz_playerone"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "Extraction_PR"
  L3_2 = {}
  L4_2 = "[support.extraction.name]"
  L3_2.sName = L4_2
  L3_2.sIcon = "vehicles_heli_alouette"
  L4_2 = "nFreebieQty"
  L5_2 = nil
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = MrxSoldierDelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "MH53J (Full)"
  L1_2(L2_2, L3_2)
  L3_2 = "SetFinalDestination"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "07_all_hq_lz_playerone"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "SoldierDelivery_AL"
  L3_2 = {}
  L4_2 = "[support.soldierdelivery.al.name]"
  L3_2.sName = L4_2
  L4_2 = "vehicles_heli_uh1"
  L3_2.sIcon = L4_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = MrxSoldierDelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Ka29b (Full)"
  L1_2(L2_2, L3_2)
  L3_2 = "SetFinalDestination"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "12_chi_hq_lz_playerone"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "SoldierDelivery_CH"
  L3_2 = {}
  L4_2 = "[support.soldierdelivery.ch.name]"
  L3_2.sName = L4_2
  L4_2 = "vehicles_heli_ka28"
  L3_2.sIcon = L4_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = MrxSoldierDelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "UH1 Transport (GR) (Full)"
  L1_2(L2_2, L3_2)
  L3_2 = "SetFinalDestination"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "05_gur_hq_lz_playerone"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "SoldierDelivery_GR"
  L3_2 = {}
  L4_2 = "[support.soldierdelivery.gr.name]"
  L3_2.sName = L4_2
  L4_2 = "vehicles_heli_uh1"
  L3_2.sIcon = L4_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = MrxSoldierDelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Coanda Transport (Full)"
  L1_2(L2_2, L3_2)
  L3_2 = "SetFinalDestination"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "02_oil_hq_lz_playerone"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "SoldierDelivery_OC"
  L3_2 = {}
  L4_2 = "[support.soldierdelivery.oc.name]"
  L3_2.sName = L4_2
  L3_2.sIcon = "vehicles_heli_md500"
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = MrxSoldierDelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Alouette3 Transport (PR) (Full)"
  L1_2(L2_2, L3_2)
  L3_2 = "SetFinalDestination"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "08_pir_hq_lz_playerone"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "SoldierDelivery_PR"
  L3_2 = {}
  L4_2 = "[support.soldierdelivery.pr.name]"
  L3_2.sName = L4_2
  L3_2.sIcon = "vehicles_heli_alouette"
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "AH1Z (Ewan)"
  L1_2(L2_2, L3_2)
  L3_2 = "SetFinalDestination"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "01_pmc_hq_lz_playerone"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "CopterDelivery_AL"
  L3_2 = {}
  L4_2 = "Allied Copter Delivery"
  L3_2.sName = L4_2
  L3_2.sIcon = "vehicles_heli_alouette"
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "WZ10 (Ewan)"
  L1_2(L2_2, L3_2)
  L3_2 = "SetFinalDestination"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "01_pmc_hq_lz_playerone"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "CopterDelivery_CH"
  L3_2 = {}
  L4_2 = "Chinese Copter Delivery"
  L3_2.sName = L4_2
  L3_2.sIcon = "vehicles_heli_alouette"
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxsupportcopterdelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Coanda Superiority (Ewan)"
  L1_2(L2_2, L3_2)
  L3_2 = "SetFinalDestination"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "01_pmc_hq_lz_playerone"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "CopterDelivery_OC"
  L3_2 = {}
  L4_2 = "UP Copter Delivery"
  L3_2.sName = L4_2
  L3_2.sIcon = "vehicles_heli_alouette"
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Coanda Transport (Driver)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (Light MG)"
  L1_2(L2_2, L3_2)
  L3_2 = "SetFinalDestination"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "02_oil_hq_lz_playerone"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "LightMG"
  L3_2 = {}
  L4_2 = "[support.supply.lightmg.name]"
  L3_2.sName = L4_2
  L4_2 = "HUD_ICON_support_crate"
  L3_2.sIcon = L4_2
  L4_2 = "nFreebieQty"
  L5_2 = 1
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Coanda Transport (Driver)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (OC)"
  L1_2(L2_2, L3_2)
  L3_2 = "SetFinalDestination"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "02_oil_hq_lz_playerone"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "OC"
  L3_2 = {}
  L4_2 = "[support.supply.oc.name]"
  L3_2.sName = L4_2
  L4_2 = "HUD_ICON_support_crate"
  L3_2.sIcon = L4_2
  L4_2 = "nFreebieQty"
  L5_2 = 2
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Coanda Transport (Driver)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (OC)"
  L1_2(L2_2, L3_2)
  L3_2 = "SetFinalDestination"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "02_oil_hq_lz_playerone"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "OC"
  L3_2 = {}
  L4_2 = "[support.supply.oc.name]"
  L3_2.sName = L4_2
  L4_2 = "HUD_ICON_support_crate"
  L3_2.sIcon = L4_2
  L4_2 = "nFreebieQty"
  L5_2 = 2
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "UH1 Transport (PMC) (Driver)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "Supply Drop (OC)"
  L1_2(L2_2, L3_2)
  L3_2 = "SetFinalDestination"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "02_oil_hq_lz_playerone"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCareless
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "OilCon002_OC"
  L3_2 = {}
  L4_2 = "[support.supply.oc.name]"
  L3_2.sName = L4_2
  L4_2 = "HUD_ICON_support_crate"
  L3_2.sIcon = L4_2
  L4_2 = "nFreebieQty"
  L5_2 = 2
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxcratedelivery
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "UH1 Transport (PMC) (Driver)"
  L1_2(L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.SetCargo
  L3_2 = "EXT"
  L1_2(L2_2, L3_2)
  L3_2 = "SetFinalDestination"
  L2_2 = L0_2
  L1_2 = L0_2[L3_2]
  L3_2 = "02_oil_hq_lz_playerone"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "OilCon002_EXT"
  L3_2 = {}
  L4_2 = "[vehicle.ext]"
  L3_2.sName = L4_2
  L4_2 = "vehicles_truck_ext"
  L3_2.sIcon = L4_2
  L4_2 = "nFreebieQty"
  L5_2 = 1
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxcruisemissile
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Allied Soldier"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "AL_CruiseMissile"
  L3_2 = {}
  L3_2.sName = "[support.airstrike.cruisemissile.name]"
  L3_2.sIcon = "support_cruise_missle"
  L4_2 = "nFreebieQty"
  L5_2 = 1
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxcruisemissile
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Chinese Soldier"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "CH_CruiseMissile"
  L3_2 = {}
  L3_2.sName = "[support.airstrike.cruisemissile.name]"
  L3_2.sIcon = "support_cruise_missle"
  L4_2 = "nFreebieQty"
  L5_2 = 1
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxdaisycutter
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Support Vehicle (C130)"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "AL_DaisyCutter"
  L3_2 = {}
  L3_2.sName = "[support.airstrike.daisycutter.name]"
  L3_2.sIcon = "support_daisy_cutter"
  L4_2 = "nFreebieQty"
  L5_2 = 1
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxlaserguidedbomb
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.SetDeliveryVehicle
  L3_2 = "Support Vehicle (F35)"
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L2_2 = "AL_LaserGuidedBomb"
  L3_2 = {}
  L4_2 = "[support.airstrike.laserguidedbomb.name]"
  L3_2.sName = L4_2
  L4_2 = "support_laser_guided_bomb"
  L3_2.sIcon = L4_2
  L4_2 = "nFreebieQty"
  L5_2 = 4
  L3_2[L4_2] = L5_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = mrxgunship
  L2_2 = L1_2
  L1_2 = L1_2.Create
  L1_2 = L1_2(L2_2)
  L0_2 = L1_2
  L1_2 = tFreebieData
  L2_2 = "AL_Gunship"
  L3_2 = {}
  L4_2 = "[support.airstrike.gunship.name]"
  L3_2.sName = L4_2
  L4_2 = "support_gunship"
  L3_2.sIcon = L4_2
  L3_2.oSupport = L0_2
  L1_2[L2_2] = L3_2
  L1_2 = pairs
  L2_2 = tSupportData
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = L5_2.oSupport
    if L6_2 then
      L6_2 = L5_2.oSupport
      L8_2 = "SetSupportName"
      L7_2 = L6_2
      L6_2 = L6_2[L8_2]
      L8_2 = L4_2
      L6_2(L7_2, L8_2)
      L6_2 = L5_2.nMaxStock
      if L6_2 then
        L6_2 = _kMaxStock
        L5_2.nMaxStock = L6_2
      end
    end
  end
end

Init = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = tFreebieData
  L1_2 = L1_2[A0_2]
  return L1_2
end

GetFreebie = L0_1
L0_1 = 0
NETEVENT_ADDFREEBIE = L0_1
L0_1 = 1
NETEVENT_REMOVEFREEBIE = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L0_2 = pairs
  L1_2 = tFreebieData
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = AddFreebie
    L6_2 = L3_2
    L7_2 = 1
    L8_2 = nil
    L9_2 = true
    L5_2(L6_2, L7_2, L8_2, L9_2)
  end
end

AddAllFreebies = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  if A0_2 then
    L4_2 = type
    L5_2 = A0_2
    L4_2 = L4_2(L5_2)
    if "table" == L4_2 then
      L3_2 = A0_2
    else
      L4_2 = type
      L5_2 = A0_2
      L4_2 = L4_2(L5_2)
      if "userdata" == L4_2 then
        L4_2 = {}
        L5_2 = A0_2
        L4_2[1] = L5_2
        L3_2 = L4_2
      else
        L4_2 = false
        L5_2 = false
        return L4_2, L5_2
      end
    end
    L4_2 = pairs
    L5_2 = L3_2
    L4_2, L5_2, L6_2 = L4_2(L5_2)
    for L7_2, L8_2 in L4_2, L5_2, L6_2 do
      L9_2 = Player
      L9_2 = L9_2.IsLocal
      L10_2 = L8_2
      L9_2 = L9_2(L10_2)
      if L9_2 then
        L1_2 = true
      else
        L2_2 = true
      end
    end
  else
    L1_2 = true
    L2_2 = true
  end
  L4_2 = L1_2
  L5_2 = L2_2
  return L4_2, L5_2
end

GetLocalRemote = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = tFreebieData
  L4_2 = L4_2[A0_2]
  if not L4_2 then
    return
  end
  L4_2 = tFreebieData
  L4_2 = L4_2[A0_2]
  L4_2.bDontNetSync = A2_2
  L4_2 = tFreebieData
  L4_2 = L4_2[A0_2]
  L4_2 = L4_2.sName
  if A2_2 then
    if A0_2 == "OilCon002_Delivery" then
      L5_2 = MrxOilCon002Delivery
      L5_2 = L5_2.ResetDropZones
      L5_2()
    end
    L4_2 = A0_2
  end
  L5_2 = tFreebieData
  L5_2 = L5_2[A0_2]
  L5_2 = L5_2.bActive
  if L5_2 then
    if not A1_2 then
      A1_2 = 1
    end
    L5_2 = MrxPmc
    L5_2 = L5_2.GetFreebieQty
    L6_2 = L4_2
    L5_2 = L5_2(L6_2)
    if L5_2 then
      if A3_2 then
        L6_2 = L5_2 + A1_2
        if A3_2 < L6_2 then
          A1_2 = A3_2 - L5_2
        end
      end
      L6_2 = MrxPmc
      L6_2 = L6_2.SetFreebieQty
      L7_2 = L4_2
      L8_2 = L5_2 + A1_2
      L6_2(L7_2, L8_2)
      L6_2 = tFreebieData
      L6_2 = L6_2[A0_2]
      L6_2.nInitialQty = A1_2
    else
    end
  else
    L5_2 = tFreebieData
    L5_2 = L5_2[A0_2]
    L5_2 = L5_2.oSupport
    L7_2 = L5_2
    L6_2 = L5_2.SetSupportName
    L8_2 = L4_2
    L6_2(L7_2, L8_2)
    if not A1_2 then
      L6_2 = tFreebieData
      L6_2 = L6_2[A0_2]
      A1_2 = L6_2.nFreebieQty
    end
    if A1_2 then
      if A3_2 and A3_2 < A1_2 then
        A1_2 = A3_2
      end
      L6_2 = MrxPmc
      L6_2 = L6_2.SetFreebieQty
      L7_2 = L4_2
      L8_2 = A1_2
      L6_2(L7_2, L8_2)
      L6_2 = tFreebieData
      L6_2 = L6_2[A0_2]
      L6_2.nInitialQty = A1_2
    else
    end
    L6_2 = Hud
    L6_2 = L6_2.SupportMenu
    L7_2 = L6_2
    L6_2 = L6_2.AddItem
    L8_2 = {}
    L8_2.vPlayer = nil
    L8_2.sName = L4_2
    L9_2 = tFreebieData
    L9_2 = L9_2[A0_2]
    L9_2 = L9_2.sIcon
    L8_2.sIcon = L9_2
    L8_2.oSupport = L5_2
    L8_2.bDontNetSync = true
    L8_2.bAnimate = true
    L6_2(L7_2, L8_2)
    L6_2 = tFreebieData
    L6_2 = L6_2[A0_2]
    L6_2.bActive = true
  end
end

_AddFreebie = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = tFreebieData
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    return
  end
  L1_2 = Hud
  L1_2 = L1_2.SupportMenu
  L2_2 = L1_2
  L1_2 = L1_2.RemoveItem
  L3_2 = {}
  L3_2.vPlayer = nil
  L4_2 = tFreebieData
  L4_2 = L4_2[A0_2]
  L4_2 = L4_2.sName
  L3_2.sName = L4_2
  L3_2.bDontNetSync = true
  L1_2(L2_2, L3_2)
  L1_2 = MrxPmc
  L1_2 = L1_2.SetFreebieQty
  L2_2 = tFreebieData
  L2_2 = L2_2[A0_2]
  L2_2 = L2_2.sName
  L3_2 = nil
  L1_2(L2_2, L3_2)
  L1_2 = tFreebieData
  L1_2 = L1_2[A0_2]
  L1_2.bActive = false
end

_RemoveFreebie = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L5_2 = GetLocalRemote
  L6_2 = A2_2
  L5_2, L6_2 = L5_2(L6_2)
  if L6_2 then
    L7_2 = Net
    L7_2 = L7_2.IsServer
    L7_2 = L7_2()
    if L7_2 and A3_2 == nil then
      L7_2 = Net
      L7_2 = L7_2.SendCustomEvent
      L8_2 = "MrxSupportData"
      L9_2 = NETEVENT_ADDFREEBIE
      L10_2 = {}
      L11_2 = A0_2
      L12_2 = A1_2 or L12_2
      if not A1_2 then
        L12_2 = 0
      end
      L13_2 = A4_2
      L10_2[1] = L11_2
      L10_2[2] = L12_2
      L10_2[3] = L13_2
      L7_2(L8_2, L9_2, L10_2)
    end
  end
  if L5_2 then
    L7_2 = _AddFreebie
    L8_2 = A0_2
    L9_2 = A1_2
    L10_2 = A3_2
    L11_2 = A4_2
    L7_2(L8_2, L9_2, L10_2, L11_2)
  end
end

AddFreebie = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = GetLocalRemote
  L3_2 = A1_2
  L2_2, L3_2 = L2_2(L3_2)
  if L3_2 then
    L4_2 = Net
    L4_2 = L4_2.IsServer
    L4_2 = L4_2()
    if L4_2 then
      L4_2 = Net
      L4_2 = L4_2.SendCustomEvent
      L5_2 = "MrxSupportData"
      L6_2 = NETEVENT_REMOVEFREEBIE
      L7_2 = {}
      L8_2 = A0_2
      L7_2[1] = L8_2
      L4_2(L5_2, L6_2, L7_2)
    end
  end
  if L2_2 then
    L4_2 = _RemoveFreebie
    L5_2 = A0_2
    L4_2(L5_2)
  end
end

RemoveFreebie = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = pairs
  L2_2 = tFreebieData
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = String
    L6_2 = L6_2.GetHash
    L7_2 = L4_2
    L6_2 = L6_2(L7_2)
    if L6_2 == A0_2 then
      return L4_2
    end
  end
  L1_2 = "NO NAME"
  return L1_2
end

GetFreebieStringIndex = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = pairs
  L2_2 = tSupportData
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = String
    L6_2 = L6_2.GetHash
    L7_2 = L4_2
    L6_2 = L6_2(L7_2)
    if L6_2 == A0_2 then
      return L4_2
    end
  end
end

GetSupportStringIndex = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = GetFreebieStringIndex
  L3_2 = A1_2[1]
  L2_2 = L2_2(L3_2)
  L3_2 = NETEVENT_ADDFREEBIE
  if A0_2 == L3_2 then
    L3_2 = A1_2[2]
    if 0 < L3_2 then
      L3_2 = _AddFreebie
      L4_2 = L2_2
      L5_2 = A1_2[2]
      L6_2 = nil
      L7_2 = A1_2[3]
      L3_2(L4_2, L5_2, L6_2, L7_2)
    else
      L3_2 = _AddFreebie
      L4_2 = L2_2
      L3_2(L4_2)
    end
  else
    L3_2 = NETEVENT_REMOVEFREEBIE
    if A0_2 == L3_2 then
      L3_2 = _RemoveFreebie
      L4_2 = L2_2
      L3_2(L4_2)
    end
  end
end

NetEventCallback = L0_1
L0_1 = 1
_knUnlockStatusNew = L0_1
L0_1 = 2
_knUnlockStatusViewed = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = ipairs
  L3_2 = A0_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = tSupportData
    L7_2 = L7_2[L6_2]
    if L7_2 then
      L8_2 = L7_2.tUnlockStatus
      if not L8_2 then
        L8_2 = {}
      end
      L7_2.tUnlockStatus = L8_2
      L8_2 = L7_2.tUnlockStatus
      L8_2 = L8_2[A1_2]
      if not L8_2 then
        L8_2 = L7_2.tUnlockStatus
        L9_2 = _knUnlockStatusNew
        L8_2[A1_2] = L9_2
        L8_2 = WifMissionFlow
        L8_2 = L8_2.RefreshAllPdaMissionDetails
        L8_2()
      end
    end
  end
  L2_2 = MrxFactionManager
  L2_2 = L2_2.GetFactionAbbrevs
  L2_2 = L2_2()
  L3_2 = 0
  L4_2 = 0
  L5_2 = ipairs
  L6_2 = L2_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = MrxShop
    L10_2 = L10_2.GetTotalNumberOfItems
    L11_2 = L9_2
    L10_2 = L10_2(L11_2)
    L11_2 = MrxShop
    L11_2 = L11_2.GetNumberOfUnlockedItems
    L12_2 = L9_2
    L11_2 = L11_2(L12_2)
    if 0 < L10_2 then
      L3_2 = L3_2 + L11_2
      L4_2 = L4_2 + L10_2
    end
  end
  if L3_2 == L4_2 then
    L5_2 = MrxAchievements
    L5_2 = L5_2.NetGrantAchievement
    L6_2 = "ACHIEVEMENT_DIGITAL_MAN"
    L7_2 = Player
    L7_2 = L7_2.GetPrimaryPlayer
    L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L7_2()
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  end
end

Add = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = tSupportData
  L2_2 = L2_2[A0_2]
  L3_2 = L2_2.tUnlockStatus
  if L3_2 then
    L3_2 = L2_2.tUnlockStatus
    L3_2 = L3_2[A1_2]
    L3_2 = L3_2 ~= nil
    return L3_2
  end
  L3_2 = false
  return L3_2
end

IsItemUnlocked = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = tSupportData
  L2_2 = L2_2[A0_2]
  L3_2 = L2_2.tUnlockStatus
  if L3_2 then
    L3_2 = L2_2.tUnlockStatus
    L3_2 = L3_2[A1_2]
    L4_2 = _knUnlockStatusNew
    L3_2 = L3_2 == L4_2
    return L3_2
  end
  L3_2 = false
  return L3_2
end

IsItemNew = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = tSupportData
  L2_2 = L2_2[A0_2]
  L3_2 = L2_2.tUnlockStatus
  if L3_2 then
    L3_2 = L2_2.tUnlockStatus
    L3_2 = L3_2[A1_2]
    L4_2 = _knUnlockStatusNew
    if L3_2 == L4_2 then
      L3_2 = L2_2.tUnlockStatus
      L4_2 = _knUnlockStatusViewed
      L3_2[A1_2] = L4_2
    end
  end
end

SetItemViewed = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = {}
  L1_2 = pairs
  L2_2 = tSupportData
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = {}
    L7_2 = L5_2.tUnlockStatus
    L6_2.tUnlockStatus = L7_2
    L7_2 = L5_2.nGlobalStock
    L6_2.nGlobalStock = L7_2
    L0_2[L4_2] = L6_2
  end
  L1_2 = tRequirementsObtained
  L0_2._tRequirementsObtained = L1_2
  return L0_2
end

SaveSingleton = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  if not A0_2 then
    return
  end
  L1_2 = A0_2._tRequirementsObtained
  tRequirementsObtained = L1_2
  A0_2._tRequirementsObtained = nil
  L1_2 = pairs
  L2_2 = tSupportData
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L6_2 = A0_2[L4_2]
    if L6_2 then
      L6_2 = A0_2[L4_2]
      L6_2 = L6_2.tUnlockStatus
      L5_2.tUnlockStatus = L6_2
      L6_2 = A0_2[L4_2]
      L6_2 = L6_2.nGlobalStock
      L5_2.nGlobalStock = L6_2
    end
  end
end

LoadSingleton = L0_1

function L0_1(A0_2, A1_2)
  local L2_2
  L2_2 = g_bIsDlc
  if not L2_2 then
    L2_2 = nil
    return L2_2
  end
  if A0_2 == nil then
    L2_2 = nil
    return L2_2
  end
  L2_2 = tSupportData
  L2_2[A1_2] = A0_2
  L2_2 = true
  return L2_2
end

AddSupportData = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _kMaxStock
  return L0_2
end

GetMaxQuantity = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = tSupportData
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L2_2 = L1_2.sName
    return L2_2
  end
end

GetPlayerVisibleName = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = tFreebieData
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L2_2 = L1_2.sName
    return L2_2
  end
end

GetFreebieName = L0_1
