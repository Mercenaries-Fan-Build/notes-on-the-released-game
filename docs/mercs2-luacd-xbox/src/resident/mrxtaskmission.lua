local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTask"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSubtitle"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxVoSequence"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifMissionData"
L0_1(L1_1)
L0_1 = import
L1_1 = "WifMissionFlow"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxTaskObjective"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxFactionManager"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxRewardData"
L0_1(L1_1)
L0_1 = 0
_knContract = L0_1
L0_1 = 1
_knJob = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = MrxTask
  L1_2 = L1_2.Activated
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = Graphics
  L1_2 = L1_2.InitTinyGeometry
  L1_2()
  L1_2 = {}
  A0_2._tVo = L1_2
end

Activated = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2.oStarter
  if L2_2 then
    L2_2 = L1_2.oStarter
    L3_2 = L2_2
    L2_2 = L2_2.RemoveMission
    L4_2 = A0_2
    L2_2(L3_2, L4_2)
  end
  L2_2 = A0_2._tVo
  if L2_2 then
    L2_2 = ipairs
    L3_2 = A0_2._tVo
    L2_2, L3_2, L4_2 = L2_2(L3_2)
    for L5_2, L6_2 in L2_2, L3_2, L4_2 do
      L7_2 = VO
      L7_2 = L7_2.Cancel
      L8_2 = L6_2.vSpeaker
      L9_2 = L6_2.sCueHandle
      L7_2(L8_2, L9_2)
    end
  end
  L2_2 = MrxSubtitle
  L2_2 = L2_2.ClearPending
  L2_2()
  L2_2 = MrxTask
  L2_2 = L2_2.Cleanup
  L3_2 = A0_2
  L2_2(L3_2)
end

Cleanup = L0_1

function L0_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2
  L5_2 = VO
  L5_2 = L5_2.Cue
  L6_2 = A1_2
  L7_2 = A2_2
  L8_2 = A3_2
  L9_2 = A4_2
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L6_2 = table
  L6_2 = L6_2.insert
  L7_2 = A0_2._tVo
  L8_2 = {}
  L8_2.vSpeaker = A1_2
  L8_2.sCueHandle = A2_2
  L6_2(L7_2, L8_2)
  return L5_2
end

_PlayVo = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2
  L1_2 = A0_2.GetMissionId
  L1_2 = L1_2(L2_2)
  L2_2 = {}
  L3_2 = 0
  
  function L4_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3
    L2_3 = A0_3
    L1_3 = A0_3.GetChildren
    L1_3 = L1_3(L2_3)
    L2_3 = pairs
    L3_3 = L1_3
    L2_3, L3_3, L4_3 = L2_3(L3_3)
    for L5_3, L6_3 in L2_3, L3_3, L4_3 do
      L7_3 = L6_3.GetDisplayDescription
      if L7_3 then
        L8_3 = L6_3
        L7_3 = L6_3.GetDisplayDescription
        L7_3 = L7_3(L8_3)
        if L7_3 then
          L8_3 = L6_3
          L7_3 = L6_3.IsCompleted
          L7_3 = L7_3(L8_3)
          if not L7_3 then
            L8_3 = L6_3
            L7_3 = L6_3.IsCancelled
            L7_3 = L7_3(L8_3)
            if not L7_3 then
              L7_3 = L6_3.GetDescription
              if L7_3 then
                L7_3 = L6_3.RefreshPdaDisplay
                if L7_3 then
                  L8_3 = L6_3
                  L7_3 = L6_3.GetDescription
                  L9_3 = true
                  L7_3 = L7_3(L8_3, L9_3)
                  if L7_3 then
                    L8_3 = L3_2
                    L8_3 = L8_3 + 1
                    L3_2 = L8_3
                    L8_3 = L2_2
                    L9_3 = L3_2
                    L10_3 = {}
                    L8_3[L9_3] = L10_3
                    L8_3 = L2_2
                    L9_3 = L3_2
                    L8_3 = L8_3[L9_3]
                    L10_3 = L6_3
                    L9_3 = L6_3.GetDescription
                    L9_3 = L9_3(L10_3)
                    L8_3[1] = L9_3
                    L8_3 = L2_2
                    L9_3 = L3_2
                    L8_3 = L8_3[L9_3]
                    L10_3 = L6_3
                    L9_3 = L6_3.GetInlineIcon
                    L9_3 = L9_3(L10_3)
                    L8_3[2] = L9_3
                  end
                  L9_3 = L6_3
                  L8_3 = L6_3.RefreshPdaDisplay
                  L8_3(L9_3)
                end
              end
            end
          end
        end
      end
      L7_3 = L4_2
      L8_3 = L6_3
      L7_3(L8_3)
    end
  end
  
  L5_2 = L4_2
  L6_2 = A0_2
  L5_2(L6_2)
  L5_2 = WifMissionFlow
  L5_2 = L5_2.AddPdaMissionDetails
  L6_2 = L1_2
  L7_2 = L2_2
  L5_2(L6_2, L7_2)
end

RefreshPdaDisplay = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = false
  return L0_2
end

IsContract = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = false
  return L0_2
end

IsJob = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = WifMissionFlow
  L1_2 = L1_2.GetKeyValue
  L3_2 = A0_2
  L2_2 = A0_2.GetMissionId
  L2_2, L3_2 = L2_2(L3_2)
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    L1_2 = 0
  end
  return L1_2
end

GetNumCompletions = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.GetParent
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2
  L1_2 = L1_2.GetName
  return L1_2(L2_2)
end

GetMissionId = L0_1

function L0_1(A0_2)
  local L1_2, L2_2
  L2_2 = A0_2
  L1_2 = A0_2.GetConfig
  L1_2 = L1_2(L2_2)
  L1_2 = L1_2.sFactionId
  return L1_2
end

GetFactionId = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = WifMissionFlow
  L1_2 = L1_2.GetMissionStartLocations
  L3_2 = A0_2
  L2_2 = A0_2.GetMissionId
  L2_2, L3_2 = L2_2(L3_2)
  return L1_2(L2_2, L3_2)
end

GetStartLocations = L0_1
