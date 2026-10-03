local L0_1, L1_1
L0_1 = import
L1_1 = "MrxSoundShellBootstrap"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiBootstrap_ShellOnly"
L0_1(L1_1)
L0_1 = false
_bGuiLoaded = L0_1
L0_1 = false
_bLocalPlayerJoined = L0_1

function L0_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = false
  _bGuiLoaded = L2_2
  L2_2 = false
  _bLocalPlayerJoined = L2_2
  L2_2 = nil
  _sHeroSpawnLocation = L2_2
  _fOnDoneCallback = A0_2
  _tOnDoneCallbackArgs = A1_2
  L2_2 = MrxGuiBootstrap_ShellOnly
  L2_2 = L2_2.SetOnGuiLoadedFunc
  L3_2 = _GuiLoaded
  L2_2(L3_2)
end

Start = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _bGuiLoaded
  return L0_2
end

IsGuiLoaded = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _bGuiLoaded
  if not L0_2 then
    L0_2 = true
    _bGuiLoaded = L0_2
    L0_2 = _End
    L0_2()
  end
end

_GuiLoaded = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _bLocalPlayerJoined
  if not L0_2 then
    return
  end
  L0_2 = _bGuiLoaded
  if not L0_2 then
    return
  end
end

_End = L0_1

function L0_1(A0_2)
  local L1_2
  _sHeroSpawnLocation = A0_2
end

SetHeroSpawnLocation = L0_1
