local L0_1, L1_1, L2_1
L0_1 = import
L1_1 = "MrxUtil"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = import
L1_1 = "MrxTimer"
L2_1 = false
L0_1(L1_1, L2_1)
L0_1 = {}
tPursuitTable = L0_1
L0_1 = {}
tEscalationTable = L0_1

function L0_1(A0_2)
  local L1_2
  L1_2 = Pg
  L1_2 = L1_2.ClearCustomPursuit
  L1_2()
end

ClearPursuit = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = Pg
  L1_2 = L1_2.ClearPursuitRestrictions
  L2_2 = false
  L3_2 = false
  L4_2 = true
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = Pg
  L1_2 = L1_2.SetCustomPursuit
  L2_2 = Pg
  L2_2 = L2_2.GetGuidByName
  L3_2 = "VZ"
  L2_2 = L2_2(L3_2)
  L3_2 = -1
  L4_2 = tPursuitTable
  L1_2(L2_2, L3_2, L4_2)
end

StartPursuit = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = {}
  L2_2 = AddTemplate
  L1_2.AddTemplate = L2_2
  L2_2 = UpdateTemplateWeight
  L1_2.UpdateTemplate = L2_2
  L2_2 = UpdateTypeDensity
  L1_2.UpdateDensity = L2_2
  L2_2 = RemoveTemplate
  L1_2.RemoveTemplate = L2_2
  L2_2 = tEscalationTable
  L2_2 = L2_2[A0_2]
  if L2_2 == nil then
    return
  end
  L2_2 = ipairs
  L3_2 = tEscalationTable
  L3_2 = L3_2[A0_2]
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  for L5_2, L6_2 in L2_2, L3_2, L4_2 do
    L7_2 = L6_2.sCommand
    L8_2 = L1_2[L7_2]
    if L8_2 == nil then
      return
    else
      L8_2 = L1_2[L7_2]
      L9_2 = L6_2
      L8_2(L9_2)
    end
  end
  L2_2 = Pg
  L2_2 = L2_2.SetCustomPursuit
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = "VZ"
  L3_2 = L3_2(L4_2)
  L4_2 = -1
  L5_2 = tPursuitTable
  L2_2(L3_2, L4_2, L5_2)
end

ParseEscalationTable = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L1_2 = A0_2.tSituation
  L2_2 = A0_2.tTemplate
  L3_2 = A0_2.tDensity
  L4_2 = type
  L5_2 = L1_2
  L4_2 = L4_2(L5_2)
  if L4_2 ~= "table" then
    return
  end
  L4_2 = type
  L5_2 = L2_2
  L4_2 = L4_2(L5_2)
  if L4_2 ~= "table" then
    return
  end
  L4_2 = L2_2[1]
  if L4_2 ~= "Car" then
    L4_2 = L2_2[1]
    if L4_2 ~= "Tank" then
      L4_2 = L2_2[1]
      if L4_2 ~= "Boat" then
        L4_2 = L2_2[1]
        if L4_2 ~= "Heli" then
          return
        end
      end
    end
  end
  L4_2 = Pg
  L4_2 = L4_2.GetGuidByName
  L5_2 = L2_2[2]
  L4_2 = L4_2(L5_2)
  if L4_2 == nil then
    return
  end
  L4_2 = ipairs
  L5_2 = L1_2
  L4_2, L5_2, L6_2 = L4_2(L5_2)
  for L7_2, L8_2 in L4_2, L5_2, L6_2 do
    L9_2 = {}
    L10_2 = 0
    L11_2 = ipairs
    L12_2 = tPursuitTable
    L11_2, L12_2, L13_2 = L11_2(L12_2)
    for L14_2, L15_2 in L11_2, L12_2, L13_2 do
      L16_2 = L15_2[1]
      if L16_2 == L8_2 then
        L9_2 = L15_2
      end
    end
    L11_2 = table
    L11_2 = L11_2.getn
    L12_2 = L9_2
    L11_2 = L11_2(L12_2)
    if L11_2 == 0 then
      return
    end
    L11_2 = false
    L12_2 = ipairs
    L13_2 = L9_2[2]
    L12_2, L13_2, L14_2 = L12_2(L13_2)
    for L15_2, L16_2 in L12_2, L13_2, L14_2 do
      L17_2 = L16_2[2]
      L18_2 = L2_2[2]
      if L17_2 == L18_2 then
        L11_2 = true
      end
    end
    if L11_2 == false then
      L12_2 = table
      L12_2 = L12_2.insert
      L13_2 = L9_2[2]
      L14_2 = L2_2
      L12_2(L13_2, L14_2)
    end
    L12_2 = false
    if L3_2 == nil then
      L13_2 = ipairs
      L14_2 = L9_2[3]
      L13_2, L14_2, L15_2 = L13_2(L14_2)
      for L16_2, L17_2 in L13_2, L14_2, L15_2 do
        L18_2 = L17_2[1]
        L19_2 = L2_2[1]
        if L18_2 == L19_2 then
          L12_2 = true
        end
      end
      if L12_2 == false then
        L13_2 = {}
        L14_2 = L2_2[1]
        L15_2 = 1
        L13_2[1] = L14_2
        L13_2[2] = L15_2
        L3_2 = L13_2
        L13_2 = table
        L13_2 = L13_2.insert
        L14_2 = L9_2[3]
        L15_2 = L3_2
        L13_2(L14_2, L15_2)
      end
    else
      L13_2 = L2_2[1]
      L14_2 = L3_2[1]
      if L13_2 ~= L14_2 then
        return
      end
      L13_2 = ipairs
      L14_2 = L9_2[3]
      L13_2, L14_2, L15_2 = L13_2(L14_2)
      for L16_2, L17_2 in L13_2, L14_2, L15_2 do
        L18_2 = L17_2[1]
        L19_2 = L3_2[1]
        if L18_2 == L19_2 then
          L18_2 = L9_2[3]
          L18_2 = L18_2[L16_2]
          L19_2 = L3_2[2]
          L18_2[2] = L19_2
          L12_2 = true
        end
      end
      if L12_2 == false then
        L13_2 = L3_2[1]
        if L13_2 ~= "Car" then
          L13_2 = L3_2[1]
          if L13_2 ~= "Tank" then
            L13_2 = L3_2[1]
            if L13_2 ~= "Boat" then
              L13_2 = L3_2[1]
              if L13_2 ~= "Heli" then
                return
            end
          end
        end
        else
          L13_2 = table
          L13_2 = L13_2.insert
          L14_2 = L9_2[3]
          L15_2 = L3_2
          L13_2(L14_2, L15_2)
        end
      end
    end
    if L10_2 ~= 0 then
      L13_2 = tPursuitTable
      L13_2[L10_2] = L9_2
    end
  end
end

AddTemplate = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L1_2 = A0_2.tSituation
  L2_2 = A0_2.tTemplate
  L3_2 = type
  L4_2 = L1_2
  L3_2 = L3_2(L4_2)
  if L3_2 ~= "table" then
    return
  end
  L3_2 = type
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if L3_2 ~= "table" then
    return
  end
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = L2_2[1]
  L3_2 = L3_2(L4_2)
  if L3_2 == nil then
    return
  end
  L3_2 = ipairs
  L4_2 = L1_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = 0
    L9_2 = {}
    L10_2 = ipairs
    L11_2 = tPursuitTable
    L10_2, L11_2, L12_2 = L10_2(L11_2)
    for L13_2, L14_2 in L10_2, L11_2, L12_2 do
      L15_2 = L14_2[1]
      if L15_2 == L7_2 then
        L9_2 = L14_2
        L8_2 = L13_2
      end
    end
    L10_2 = table
    L10_2 = L10_2.getn
    L11_2 = L9_2
    L10_2 = L10_2(L11_2)
    if L10_2 == 0 then
      return
    end
    L10_2 = false
    L11_2 = ipairs
    L12_2 = L9_2[2]
    L11_2, L12_2, L13_2 = L11_2(L12_2)
    for L14_2, L15_2 in L11_2, L12_2, L13_2 do
      L16_2 = L15_2[2]
      L17_2 = L2_2[1]
      if L16_2 == L17_2 then
        L10_2 = true
        L16_2 = L9_2[2]
        L16_2 = L16_2[L14_2]
        L17_2 = L2_2[2]
        L16_2[3] = L17_2
      end
    end
    if L10_2 == false then
      return
    end
    if L8_2 ~= 0 then
      L11_2 = tPursuitTable
      L11_2[L8_2] = L9_2
    end
  end
end

UpdateTemplateWeight = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L1_2 = A0_2.tSituation
  L2_2 = A0_2.tDensity
  L3_2 = type
  L4_2 = L1_2
  L3_2 = L3_2(L4_2)
  if L3_2 ~= "table" then
    return
  end
  L3_2 = L2_2[1]
  if L3_2 ~= "Car" then
    L3_2 = L2_2[1]
    if L3_2 ~= "Tank" then
      L3_2 = L2_2[1]
      if L3_2 ~= "Boat" then
        L3_2 = L2_2[1]
        if L3_2 ~= "Heli" then
          return
        end
      end
    end
  end
  L3_2 = ipairs
  L4_2 = L1_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = 0
    L9_2 = {}
    L10_2 = ipairs
    L11_2 = tPursuitTable
    L10_2, L11_2, L12_2 = L10_2(L11_2)
    for L13_2, L14_2 in L10_2, L11_2, L12_2 do
      L15_2 = L14_2[1]
      if L15_2 == L7_2 then
        L9_2 = L14_2
        L8_2 = L13_2
      end
    end
    L10_2 = table
    L10_2 = L10_2.getn
    L11_2 = L9_2
    L10_2 = L10_2(L11_2)
    if L10_2 == 0 then
      return
    end
    L10_2 = false
    if L2_2 == nil then
      return
    else
      L11_2 = ipairs
      L12_2 = L9_2[3]
      L11_2, L12_2, L13_2 = L11_2(L12_2)
      for L14_2, L15_2 in L11_2, L12_2, L13_2 do
        L16_2 = L15_2[1]
        L17_2 = L2_2[1]
        if L16_2 == L17_2 then
          L10_2 = true
          L16_2 = L9_2[3]
          L16_2 = L16_2[L14_2]
          L17_2 = L2_2[2]
          L16_2[2] = L17_2
        end
      end
      if L10_2 == false then
        return
      end
    end
    if L8_2 ~= 0 then
      L11_2 = tPursuitTable
      L11_2[L8_2] = L9_2
    end
  end
end

UpdateTypeDensity = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L1_2 = A0_2.tSituation
  L2_2 = A0_2.tTemplate
  L3_2 = type
  L4_2 = L1_2
  L3_2 = L3_2(L4_2)
  if L3_2 ~= "table" then
    return
  end
  L3_2 = Pg
  L3_2 = L3_2.GetGuidByName
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if L3_2 == nil then
    return
  end
  L3_2 = ipairs
  L4_2 = L1_2
  L3_2, L4_2, L5_2 = L3_2(L4_2)
  for L6_2, L7_2 in L3_2, L4_2, L5_2 do
    L8_2 = 0
    L9_2 = ipairs
    L10_2 = tPursuitTable
    L9_2, L10_2, L11_2 = L9_2(L10_2)
    for L12_2, L13_2 in L9_2, L10_2, L11_2 do
      L14_2 = L13_2[1]
      if L14_2 == L7_2 then
        L8_2 = L12_2
      end
    end
    if L8_2 == 0 then
      return
    end
    L9_2 = ""
    L10_2 = ipairs
    L11_2 = tPursuitTable
    L11_2 = L11_2[L8_2]
    L11_2 = L11_2[2]
    L10_2, L11_2, L12_2 = L10_2(L11_2)
    for L13_2, L14_2 in L10_2, L11_2, L12_2 do
      L15_2 = L14_2[2]
      if L15_2 == L2_2 then
        L15_2 = true
        bFoundVehicleTemplate = L15_2
        L9_2 = L14_2[1]
        L15_2 = table
        L15_2 = L15_2.remove
        L16_2 = tPursuitTable
        L16_2 = L16_2[L8_2]
        L16_2 = L16_2[2]
        L17_2 = L13_2
        L15_2(L16_2, L17_2)
      end
    end
    if L9_2 == "" then
      return
    end
    L10_2 = false
    L11_2 = 0
    nTemplateIndex = L11_2
    L11_2 = {}
    tCurTemplate = L11_2
    L11_2 = ipairs
    L12_2 = tPursuitTable
    L12_2 = L12_2[L8_2]
    L12_2 = L12_2[2]
    L11_2, L12_2, L13_2 = L11_2(L12_2)
    for L14_2, L15_2 in L11_2, L12_2, L13_2 do
      L16_2 = L15_2[1]
      if L16_2 == L9_2 then
        L10_2 = true
      end
    end
    if L10_2 == false then
      L11_2 = ipairs
      L12_2 = tPursuitTable
      L12_2 = L12_2[L8_2]
      L12_2 = L12_2[3]
      L11_2, L12_2, L13_2 = L11_2(L12_2)
      for L14_2, L15_2 in L11_2, L12_2, L13_2 do
        L16_2 = L15_2[1]
        if L16_2 == L9_2 then
          L16_2 = table
          L16_2 = L16_2.remove
          L17_2 = tPursuitTable
          L17_2 = L17_2[L8_2]
          L17_2 = L17_2[3]
          L18_2 = L14_2
          L16_2(L17_2, L18_2)
        end
      end
    end
  end
end

RemoveTemplate = L0_1
