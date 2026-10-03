local L0_1, L1_1, L2_1
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxLayerManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxMultiPageMenu"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPlayState"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxRewardData"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTaskState"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTransit"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxUtil"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifMissionData"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifMissionFlow"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifVzBoundary"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifCheatStockpile"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxPmc"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSupportData"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifPmcInterior"
L0_1(L1_1)
L0_1 = import
L1_1 = "Munitions"
L0_1(L1_1)
L0_1 = "NoContract"
_sLastCompletedContractName = L0_1

function L0_1(A0_2)
  local L1_2
  _oCurrTask = A0_2
end

SetTaskTreeRoot = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _DisplayRootDialog
  L0_2()
end

DisplayOptions = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = MrxMultiPageMenu
  L0_2 = L0_2.AddOption
  L1_2 = "Return to root menu"
  L2_2 = _DisplayRootDialog
  L3_2 = nil
  L4_2 = true
  L5_2 = true
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2)
end

_AddRootOption = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = MrxMultiPageMenu
  L0_2 = L0_2.AddOption
  L1_2 = "Close this menu"
  L2_2 = nil
  L3_2 = nil
  L4_2 = true
  L5_2 = true
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2)
end

_AddCloseOption = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = MrxMultiPageMenu
  L0_2 = L0_2.Reset
  L0_2()
  L0_2 = WifPmcInterior
  L0_2 = L0_2.IsInside
  L0_2 = L0_2()
  if not L0_2 then
    L0_2 = MrxMultiPageMenu
    L0_2 = L0_2.AddOption
    L1_2 = "Skip to a mission"
    L2_2 = _DisplaySkipDialog
    L3_2 = {}
    L4_2 = false
    L3_2[1] = L4_2
    L0_2(L1_2, L2_2, L3_2)
    L0_2 = MrxMultiPageMenu
    L0_2 = L0_2.AddOption
    L1_2 = "Skip to a briefing"
    L2_2 = _DisplaySkipDialog
    L3_2 = {}
    L4_2 = true
    L3_2[1] = L4_2
    L0_2(L1_2, L2_2, L3_2)
    L0_2 = MrxPlayState
    L0_2 = L0_2.GetCurrentMission
    L0_2 = L0_2()
    if L0_2 then
      L2_2 = L0_2
      L1_2 = L0_2.GetParent
      L1_2 = L1_2(L2_2)
      L3_2 = L1_2
      L2_2 = L1_2.GetName
      L2_2 = L2_2(L3_2)
      L3_2 = MrxMultiPageMenu
      L3_2 = L3_2.AddOption
      L4_2 = "Complete current contract ("
      L5_2 = L2_2
      L6_2 = ")"
      L4_2 = L4_2 .. L5_2 .. L6_2
      L5_2 = _CompleteCurrentContract
      L3_2(L4_2, L5_2)
    end
    L1_2 = MrxMultiPageMenu
    L1_2 = L1_2.AddOption
    L2_2 = "Traverse mission hierarchy"
    L3_2 = _DisplayTraverseDialog
    L1_2(L2_2, L3_2)
  end
  L0_2 = MrxMultiPageMenu
  L0_2 = L0_2.AddOption
  L1_2 = "Add cash"
  L2_2 = _DisplayAddCashDialog
  L0_2(L1_2, L2_2)
  L0_2 = MrxMultiPageMenu
  L0_2 = L0_2.AddOption
  L1_2 = "Add fuel"
  L2_2 = _DisplayAddFuelDialog
  L0_2(L1_2, L2_2)
  L0_2 = MrxMultiPageMenu
  L0_2 = L0_2.AddOption
  L1_2 = "Add support"
  L2_2 = _DisplayAddSupportDialog
  L0_2(L1_2, L2_2)
  L0_2 = MrxMultiPageMenu
  L0_2 = L0_2.AddOption
  L1_2 = "Modify attitude"
  L2_2 = _DisplayModAttitudeDialog
  L3_2 = {}
  L4_2 = nil
  L5_2 = nil
  L6_2 = nil
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L0_2(L1_2, L2_2, L3_2)
  L0_2 = MrxMultiPageMenu
  L0_2 = L0_2.AddOption
  L1_2 = "Unlock all landing zones"
  L2_2 = MrxTransit
  L2_2 = L2_2.UnlockAllLandingZones
  L0_2(L1_2, L2_2)
  L0_2 = MrxMultiPageMenu
  L0_2 = L0_2.AddOption
  L1_2 = "Dispense all rewards"
  L2_2 = MrxRewardData
  L2_2 = L2_2.DispenseAllRewards
  L0_2(L1_2, L2_2)
  L0_2 = _AddCloseOption
  L0_2()
  L0_2 = MrxMultiPageMenu
  L0_2 = L0_2.Display
  L1_2 = "Welcome to the Cheat Menu."
  L0_2(L1_2)
end

_DisplayRootDialog = L0_1

function L0_1()
  local L0_2, L1_2, L2_2
  L0_2 = MrxPlayState
  L0_2 = L0_2.GetCurrentMission
  L0_2 = L0_2()
  L2_2 = L0_2
  L1_2 = L0_2.Complete
  L1_2(L2_2)
end

_CompleteCurrentContract = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = MrxMultiPageMenu
  L1_2 = L1_2.Reset
  L1_2()
  L1_2 = {}
  L2_2 = pairs
  L3_2 = WifMissionData
  L3_2 = L3_2.tMissionData
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = table
    L7_2 = L7_2.insert
    L8_2 = L1_2
    L9_2 = L5_2
    L7_2(L8_2, L9_2)
  end
  L2_2 = table
  L2_2 = L2_2.sort
  L3_2 = L1_2
  L2_2(L3_2)
  L2_2 = ipairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = MrxMultiPageMenu
    L7_2 = L7_2.AddOption
    L8_2 = L6_2
    L9_2 = _fMissionSkipDialogCallback
    L10_2 = {}
    L11_2 = L6_2
    L12_2 = A0_2
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L7_2(L8_2, L9_2, L10_2)
  end
  L2_2 = _AddRootOption
  L2_2()
  L2_2 = _AddCloseOption
  L2_2()
  if A0_2 then
    L2_2 = MrxMultiPageMenu
    L2_2 = L2_2.Display
    L3_2 = "Select a briefing:"
    L2_2(L3_2)
  else
    L2_2 = MrxMultiPageMenu
    L2_2 = L2_2.Display
    L3_2 = "Select a mission:"
    L2_2(L3_2)
  end
end

_DisplaySkipDialog = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L0_2 = _oCurrTask
  L1_2 = L0_2
  L0_2 = L0_2.GetParent
  L0_2 = L0_2(L1_2)
  if L0_2 then
    L1_2 = _oCurrTask
    L2_2 = L1_2
    L1_2 = L1_2.IsCompleted
    L1_2 = L1_2(L2_2)
    if L1_2 then
      _oCurrTask = L0_2
      L1_2 = _DisplayTraverseDialog
      L1_2()
  end
  else
    L1_2 = MrxMultiPageMenu
    L1_2 = L1_2.Reset
    L1_2()
    L1_2 = {}
    L2_2 = _oCurrTask
    L3_2 = L2_2
    L2_2 = L2_2.GetChildren
    L2_2 = L2_2(L3_2)
    L3_2 = pairs
    L4_2 = L2_2
    L3_2, L4_2, L5_2 = L3_2(L4_2)
    for L6_2, L7_2 in L3_2, L4_2, L5_2 do
      L9_2 = L7_2
      L8_2 = L7_2.IsActive
      L8_2 = L8_2(L9_2)
      if L8_2 then
        L8_2 = table
        L8_2 = L8_2.insert
        L9_2 = L1_2
        L10_2 = L6_2
        L8_2(L9_2, L10_2)
      end
    end
    L3_2 = table
    L3_2 = L3_2.sort
    L4_2 = L1_2
    L3_2(L4_2)
    L3_2 = ipairs
    L4_2 = L1_2
    L3_2, L4_2, L5_2 = L3_2(L4_2)
    for L6_2, L7_2 in L3_2, L4_2, L5_2 do
      L8_2 = MrxMultiPageMenu
      L8_2 = L8_2.AddOption
      L9_2 = L7_2
      
      function L10_2()
        local L0_3, L1_3, L2_3
        L0_3 = _oCurrTask
        L1_3 = L0_3
        L0_3 = L0_3.GetChild
        L2_3 = L7_2
        L0_3 = L0_3(L1_3, L2_3)
        _oCurrTask = L0_3
        L0_3 = _DisplayTraverseDialog
        L0_3()
      end
      
      L8_2(L9_2, L10_2)
    end
    if L0_2 then
      L3_2 = _oCurrTask
      L4_2 = L3_2
      L3_2 = L3_2._CanCompleteViaCheatMenu
      L3_2 = L3_2(L4_2)
      if L3_2 then
        L3_2 = MrxMultiPageMenu
        L3_2 = L3_2.AddOption
        L4_2 = "Complete"
        
        function L5_2()
          local L0_3, L1_3
          L0_3 = _oCurrTask
          L1_3 = L0_3
          L0_3 = L0_3.Complete
          L0_3(L1_3)
          L0_3 = _oCurrTask
          L1_3 = L0_3
          L0_3 = L0_3.GetParent
          L0_3 = L0_3(L1_3)
          _oCurrTask = L0_3
        end
        
        L3_2(L4_2, L5_2)
      end
      L3_2 = MrxPlayState
      L3_2 = L3_2.Get
      L3_2 = L3_2()
      L4_2 = MrxPlayState
      L4_2 = L4_2._knMission
      if L3_2 == L4_2 then
        L4_2 = MrxMultiPageMenu
        L4_2 = L4_2.AddOption
        L5_2 = "Cancel"
        
        function L6_2()
          local L0_3, L1_3
          L0_3 = _oCurrTask
          L1_3 = L0_3
          L0_3 = L0_3.Cancel
          L0_3(L1_3)
          L0_3 = _oCurrTask
          L1_3 = L0_3
          L0_3 = L0_3.GetParent
          L0_3 = L0_3(L1_3)
          _oCurrTask = L0_3
        end
        
        L4_2(L5_2, L6_2)
      end
      L4_2 = MrxMultiPageMenu
      L4_2 = L4_2.AddOption
      L5_2 = "Up a level"
      
      function L6_2()
        local L0_3, L1_3
        L0_3 = _oCurrTask
        L1_3 = L0_3
        L0_3 = L0_3.GetParent
        L0_3 = L0_3(L1_3)
        _oCurrTask = L0_3
        L0_3 = _DisplayTraverseDialog
        L0_3()
      end
      
      L4_2(L5_2, L6_2)
    end
    L3_2 = _AddRootOption
    L3_2()
    L3_2 = _AddCloseOption
    L3_2()
    L3_2 = MrxMultiPageMenu
    L3_2 = L3_2.Display
    L4_2 = "You are here:\n"
    L5_2 = _oCurrTask
    L6_2 = L5_2
    L5_2 = L5_2.GetLineage
    L5_2 = L5_2(L6_2)
    L4_2 = L4_2 .. L5_2
    L3_2(L4_2)
  end
end

_DisplayTraverseDialog = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L0_2 = MrxMultiPageMenu
  L0_2 = L0_2.Reset
  L0_2()
  L0_2 = ipairs
  L1_2 = {}
  L2_2 = 1000
  L3_2 = 10000
  L4_2 = 100000
  L5_2 = 1000000
  L6_2 = 10000000
  L7_2 = 100000000
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = MrxMultiPageMenu
    L5_2 = L5_2.AddOption
    L6_2 = string
    L6_2 = L6_2.format
    L7_2 = "+$%d"
    L8_2 = L4_2
    L6_2 = L6_2(L7_2, L8_2)
    
    function L7_2(A0_3)
      local L1_3, L2_3
      L1_3 = MrxPmc
      L1_3 = L1_3.AddCashQty
      L2_3 = A0_3
      L1_3(L2_3)
      L1_3 = _DisplayAddCashDialog
      L1_3()
    end
    
    L8_2 = {}
    L9_2 = L4_2
    L8_2[1] = L9_2
    L5_2(L6_2, L7_2, L8_2)
  end
  L0_2 = _AddRootOption
  L0_2()
  L0_2 = _AddCloseOption
  L0_2()
  L0_2 = MrxMultiPageMenu
  L0_2 = L0_2.Display
  L1_2 = [[
Add Cash
($]]
  L2_2 = MrxPmc
  L2_2 = L2_2.GetCashQty
  L2_2 = L2_2()
  L3_2 = ")"
  L1_2 = L1_2 .. L2_2 .. L3_2
  L0_2(L1_2)
end

_DisplayAddCashDialog = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L0_2 = MrxMultiPageMenu
  L0_2 = L0_2.Reset
  L0_2()
  L0_2 = ipairs
  L1_2 = {}
  L2_2 = 10
  L3_2 = 100
  L4_2 = 1000
  L5_2 = 9999
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  for L3_2, L4_2 in L0_2, L1_2, L2_2 do
    L5_2 = MrxMultiPageMenu
    L5_2 = L5_2.AddOption
    L6_2 = string
    L6_2 = L6_2.format
    L7_2 = "+%d"
    L8_2 = L4_2
    L6_2 = L6_2(L7_2, L8_2)
    
    function L7_2(A0_3)
      local L1_3, L2_3, L3_3
      L1_3 = MrxPmc
      L1_3 = L1_3.GetFuelQty
      L1_3 = L1_3()
      L1_3 = A0_3 + L1_3
      L2_3 = MrxPmc
      L2_3 = L2_3.GetFuelCapacity
      L2_3 = L2_3()
      if L1_3 > L2_3 then
        L1_3 = MrxPmc
        L1_3 = L1_3.SetFuelCapacity
        L2_3 = 9999
        L3_3 = true
        L1_3(L2_3, L3_3)
      end
      L1_3 = MrxPmc
      L1_3 = L1_3.AddFuelQty
      L2_3 = A0_3
      L1_3(L2_3)
      L1_3 = _DisplayAddFuelDialog
      L1_3()
    end
    
    L8_2 = {}
    L9_2 = L4_2
    L8_2[1] = L9_2
    L5_2(L6_2, L7_2, L8_2)
  end
  L0_2 = _AddRootOption
  L0_2()
  L0_2 = _AddCloseOption
  L0_2()
  L0_2 = MrxMultiPageMenu
  L0_2 = L0_2.Display
  L1_2 = [[
Add Fuel
(]]
  L2_2 = MrxPmc
  L2_2 = L2_2.GetFuelQty
  L2_2 = L2_2()
  L3_2 = ")"
  L1_2 = L1_2 .. L2_2 .. L3_2
  L0_2(L1_2)
end

_DisplayAddFuelDialog = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L0_2 = MrxSupportData
  L0_2 = L0_2.tSupportData
  L1_2 = {}
  L2_2 = pairs
  L3_2 = L0_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = table
    L7_2 = L7_2.insert
    L8_2 = L1_2
    L9_2 = L5_2
    L7_2(L8_2, L9_2)
  end
  L2_2 = table
  L2_2 = L2_2.sort
  L3_2 = L1_2
  
  function L4_2(A0_3, A1_3)
    local L2_3, L3_3
    L2_3 = L0_2
    L2_3 = L2_3[A0_3]
    L2_3 = L2_3.sName
    L3_3 = L0_2
    L3_3 = L3_3[A1_3]
    L3_3 = L3_3.sName
    L2_3 = L2_3 < L3_3
    return L2_3
  end
  
  L2_2(L3_2, L4_2)
  L2_2 = MrxMultiPageMenu
  L2_2 = L2_2.Reset
  L2_2()
  L2_2 = MrxMultiPageMenu
  L2_2 = L2_2.AddOption
  L3_2 = "The Works! + $ + F"
  
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
    L0_3 = pairs
    L1_3 = L0_2
    L0_3, L1_3, L2_3 = L0_3(L1_3)
    for L3_3, L4_3 in L0_3, L1_3, L2_3 do
      L5_3 = MrxPmc
      L5_3 = L5_3.AddSupportQty
      L6_3 = L3_3
      L7_3 = L4_3.nMaxStock
      L8_3 = MrxPmc
      L8_3 = L8_3.GetSupportQty
      L9_3 = L3_3
      L8_3 = L8_3(L9_3)
      if not L8_3 then
        L8_3 = 0
      end
      L7_3 = L7_3 - L8_3
      L5_3(L6_3, L7_3)
    end
    L0_3 = MrxPmc
    L0_3 = L0_3.AddCashQty
    L1_3 = 10000000
    L0_3(L1_3)
    L0_3 = MrxPmc
    L0_3 = L0_3.SetFuelCapacity
    L1_3 = 9999
    L2_3 = true
    L0_3(L1_3, L2_3)
    L0_3 = MrxPmc
    L0_3 = L0_3.AddFuelQty
    L1_3 = 9999
    L0_3(L1_3)
    L0_3 = MrxSupportData
    L0_3 = L0_3.SetIgnoreRequirements
    L1_3 = true
    L0_3(L1_3)
  end
  
  L2_2(L3_2, L4_2)
  L2_2 = ipairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = MrxMultiPageMenu
    L7_2 = L7_2.AddOption
    L8_2 = string
    L8_2 = L8_2.format
    L9_2 = "%s (%d/%d)"
    L10_2 = L0_2[L6_2]
    L10_2 = L10_2.sName
    L11_2 = MrxPmc
    L11_2 = L11_2.GetSupportQty
    L12_2 = L6_2
    L11_2 = L11_2(L12_2)
    if not L11_2 then
      L11_2 = 0
    end
    L12_2 = L0_2[L6_2]
    L12_2 = L12_2.nMaxStock
    L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
    
    function L9_2(A0_3)
      local L1_3, L2_3, L3_3
      L1_3 = MrxPmc
      L1_3 = L1_3.AddSupportQty
      L2_3 = A0_3
      L3_3 = 1
      L1_3(L2_3, L3_3)
      L1_3 = _DisplayAddSupportDialog
      L1_3()
    end
    
    L10_2 = {}
    L11_2 = L6_2
    L10_2[1] = L11_2
    L7_2(L8_2, L9_2, L10_2)
  end
  L2_2 = _AddRootOption
  L2_2()
  L2_2 = _AddCloseOption
  L2_2()
  L2_2 = MrxMultiPageMenu
  L2_2 = L2_2.Display
  L3_2 = "Add Support"
  L2_2(L3_2)
end

_DisplayAddSupportDialog = L0_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  if not A0_2 then
    L3_2 = _sSubjectAbbrev
    A0_2 = L3_2 or A0_2
    if not L3_2 then
      A0_2 = "All"
    end
  end
  if not A1_2 then
    L3_2 = _sObjectAbbrev
    A1_2 = L3_2 or A1_2
    if not L3_2 then
      A1_2 = "Pmc"
    end
  end
  if A2_2 then
    L3_2 = MrxFactionManager
    L3_2 = L3_2.SetRelation
    L4_2 = A0_2
    L5_2 = A1_2
    L6_2 = A2_2
    L3_2(L4_2, L5_2, L6_2)
  else
    L3_2 = MrxFactionManager
    L3_2 = L3_2.GetRelation
    L4_2 = A0_2
    L5_2 = A1_2
    L3_2 = L3_2(L4_2, L5_2)
    A2_2 = L3_2
  end
  _sSubjectAbbrev = A0_2
  _sObjectAbbrev = A1_2
  L3_2 = MrxMultiPageMenu
  L3_2 = L3_2.Reset
  L3_2()
  L3_2 = MrxMultiPageMenu
  L3_2 = L3_2.AddOption
  L4_2 = "Change subject"
  L5_2 = _DisplayFactionDialog
  L6_2 = {}
  L7_2 = true
  L6_2[1] = L7_2
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = MrxMultiPageMenu
  L3_2 = L3_2.AddOption
  L4_2 = "Change object"
  L5_2 = _DisplayFactionDialog
  L6_2 = {}
  L7_2 = false
  L6_2[1] = L7_2
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = MrxMultiPageMenu
  L3_2 = L3_2.AddOption
  L4_2 = "Change attitude"
  L5_2 = _DisplayAttitudeDialog
  L3_2(L4_2, L5_2)
  L3_2 = _AddRootOption
  L3_2()
  L3_2 = _AddCloseOption
  L3_2()
  L3_2 = MrxFactionManager
  L3_2 = L3_2.ConvertRelationToAttitudeLevel
  L4_2 = A2_2
  L3_2 = L3_2(L4_2)
  L4_2 = MrxFactionManager
  L4_2 = L4_2.GetAttitudeFromLevel
  L5_2 = L3_2
  L4_2 = L4_2(L5_2)
  L5_2 = MrxMultiPageMenu
  L5_2 = L5_2.Display
  L6_2 = [[
Modify faction attitude
Subject: ]]
  L7_2 = A0_2
  L8_2 = [[

Object: ]]
  L9_2 = A1_2
  L10_2 = [[

Attitude: ]]
  L11_2 = L4_2
  L6_2 = L6_2 .. L7_2 .. L8_2 .. L9_2 .. L10_2 .. L11_2
  L5_2(L6_2)
end

_DisplayModAttitudeDialog = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = MrxMultiPageMenu
  L1_2 = L1_2.Reset
  L1_2()
  L1_2 = MrxFactionManager
  L1_2 = L1_2.GetFactionAbbrevs
  L1_2 = L1_2()
  L2_2 = ipairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = MrxMultiPageMenu
    L7_2 = L7_2.AddOption
    L8_2 = L6_2
    L9_2 = _DisplayModAttitudeDialog
    L10_2 = {}
    L11_2 = A0_2 or L11_2
    if A0_2 then
      L11_2 = L6_2
    end
    L12_2 = not A0_2 and L12_2
    L13_2 = nil
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L10_2[3] = L13_2
    L7_2(L8_2, L9_2, L10_2)
  end
  L2_2 = MrxMultiPageMenu
  L2_2 = L2_2.AddOption
  L3_2 = "Back"
  L4_2 = _DisplayModAttitudeDialog
  L5_2 = {}
  L6_2 = nil
  L7_2 = nil
  L8_2 = nil
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L6_2 = true
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L2_2 = _AddRootOption
  L2_2()
  L2_2 = _AddCloseOption
  L2_2()
  L2_2 = MrxMultiPageMenu
  L2_2 = L2_2.Display
  L3_2 = "Choose faction"
  L2_2(L3_2)
end

_DisplayFactionDialog = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L0_2 = MrxMultiPageMenu
  L0_2 = L0_2.Reset
  L0_2()
  L0_2 = MrxFactionManager
  L0_2 = L0_2.GetAttitudes
  L0_2 = L0_2()
  L1_2 = {}
  L2_2 = pairs
  L3_2 = L0_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = table
    L7_2 = L7_2.insert
    L8_2 = L1_2
    L9_2 = {}
    L9_2.sAttitude = L5_2
    L9_2.nRelation = L6_2
    L7_2(L8_2, L9_2)
  end
  L2_2 = table
  L2_2 = L2_2.sort
  L3_2 = L1_2
  
  function L4_2(A0_3, A1_3)
    local L2_3, L3_3
    L2_3 = A0_3.nRelation
    L3_3 = A1_3.nRelation
    L2_3 = L2_3 > L3_3
    return L2_3
  end
  
  L2_2(L3_2, L4_2)
  L2_2 = ipairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = MrxMultiPageMenu
    L7_2 = L7_2.AddOption
    L8_2 = string
    L8_2 = L8_2.format
    L9_2 = "%s (%d)"
    L10_2 = L6_2.sAttitude
    L11_2 = L6_2.nRelation
    L8_2 = L8_2(L9_2, L10_2, L11_2)
    L9_2 = _DisplayModAttitudeDialog
    L10_2 = {}
    L11_2 = nil
    L12_2 = nil
    L13_2 = L6_2.nRelation
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L10_2[3] = L13_2
    L7_2(L8_2, L9_2, L10_2)
  end
  L2_2 = MrxMultiPageMenu
  L2_2 = L2_2.AddOption
  L3_2 = "Back"
  L4_2 = _DisplayModAttitudeDialog
  L5_2 = {}
  L6_2 = nil
  L7_2 = nil
  L8_2 = nil
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L6_2 = true
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L2_2 = _AddRootOption
  L2_2()
  L2_2 = _AddCloseOption
  L2_2()
  L2_2 = MrxMultiPageMenu
  L2_2 = L2_2.Display
  L3_2 = "Choose attitude"
  L2_2(L3_2)
end

_DisplayAttitudeDialog = L0_1
L0_1 = _G
L1_1 = {}
L2_1 = DisplayOptions
L1_1.DisplayOptions = L2_1
L0_1.Cheat = L1_1
L0_1 = _G

function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L3_2 = Player
  L3_2 = L3_2.GetAllPlayers
  L3_2 = L3_2()
  L4_2 = {}
  L5_2 = pairs
  L6_2 = L3_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  for L8_2, L9_2 in L5_2, L6_2, L7_2 do
    L10_2 = table
    L10_2 = L10_2.insert
    L11_2 = L4_2
    L12_2 = {}
    L13_2 = A0_2
    L14_2 = A1_2
    L15_2 = A2_2
    L12_2[1] = L13_2
    L12_2[2] = L14_2
    L12_2[3] = L15_2
    L10_2(L11_2, L12_2)
  end
  L5_2 = MrxUtil
  L5_2 = L5_2.TeleportHeroesToLocations
  L6_2 = L4_2
  L5_2(L6_2)
end

L0_1.DebugTeleport = L1_1

function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  if A0_2 then
    _sSkipToMissionId = A1_2
    _bSkipToBriefing = A2_2
  else
    L3_2 = _sSkipToMissionId
    if L3_2 then
      L3_2 = WifCheatStockpile
      L4_2 = _sSkipToMissionId
      L3_2 = L3_2[L4_2]
      if L3_2 then
        L4_2 = L3_2.tSupport
        if L4_2 then
          L4_2 = pairs
          L5_2 = L3_2.tSupport
          L4_2, L5_2, L6_2 = L4_2(L5_2)
          for L7_2, L8_2 in L4_2, L5_2, L6_2 do
            L9_2 = MrxPmc
            L9_2 = L9_2.AddSupportQty
            L10_2 = L7_2
            L11_2 = L8_2
            L9_2(L10_2, L11_2)
          end
        end
        L4_2 = L3_2.tEquipment
        if L4_2 then
          L4_2 = ipairs
          L5_2 = L3_2.tEquipment
          L4_2, L5_2, L6_2 = L4_2(L5_2)
          for L7_2, L8_2 in L4_2, L5_2, L6_2 do
            L9_2 = MrxPmc
            L9_2 = L9_2.AddEquipment
            L10_2 = L8_2
            L9_2(L10_2)
          end
        end
        L4_2 = L3_2.nCash
        if L4_2 then
          L4_2 = MrxPmc
          L4_2 = L4_2.AddCashQty
          L5_2 = MrxPmc
          L5_2 = L5_2.GetCashQty
          L5_2 = L5_2()
          L5_2 = L5_2 * -1
          L4_2(L5_2)
          L4_2 = MrxPmc
          L4_2 = L4_2.AddCashQty
          L5_2 = L3_2.nCash
          L4_2(L5_2)
        end
        L4_2 = L3_2.nFuel
        if L4_2 then
          L4_2 = MrxPmc
          L4_2 = L4_2.AddFuelQty
          L5_2 = MrxPmc
          L5_2 = L5_2.GetFuelQty
          L5_2 = L5_2()
          L5_2 = L5_2 * -1
          L4_2(L5_2)
          L4_2 = MrxPmc
          L4_2 = L4_2.AddFuelQty
          L5_2 = L3_2.nFuel
          L4_2(L5_2)
        end
      end
    end
    L3_2 = nil
    _sSkipToMissionId = L3_2
    L3_2 = nil
    _bSkipToBriefing = L3_2
  end
end

EnableSkipMode = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _sSkipToMissionId
  L0_2 = L0_2 ~= nil
  return L0_2
end

IsSkipModeEnabled = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _sSkipToMissionId
  L1_2 = _bSkipToBriefing
  return L0_2, L1_2
end

GetMissionSkipData = L0_1

function L0_1(A0_2)
  local L1_2
  _fMissionSkipDialogCallback = A0_2
end

SetMissionSkipDialogCallback = L0_1
