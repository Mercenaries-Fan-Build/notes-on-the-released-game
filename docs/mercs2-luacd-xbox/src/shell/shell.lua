local L0_1, L1_1
L0_1 = import
L1_1 = "MrxShellBootstrap"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGui"
L0_1(L1_1)

function L0_1()
  local L0_2, L1_2
  L0_2 = MrxShellBootstrap
  L0_2 = L0_2.Start
  L1_2 = _MyDummySetup
  L0_2(L1_2)
end

Init = L0_1

function L0_1()
  local L0_2, L1_2
end

_MyDummySetup = L0_1
