local L0_1, L1_1, L2_1, L3_1, L4_1
L0_1 = import
L1_1 = "MrxSoundShellBootstrap"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiShellBootstrap"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxGuiBase"
L0_1(L1_1)
L0_1 = import
L1_1 = "MrxSound"
L0_1(L1_1)
L0_1 = {}
L1_1 = {}
L2_1 = "EA"
L3_1 = -1
L1_1[1] = L2_1
L1_1[2] = L3_1
L2_1 = {}
L3_1 = "Pandemic"
L4_1 = -1
L2_1[1] = L3_1
L2_1[2] = L4_1
L0_1[1] = L1_1
L0_1[2] = L2_1
tMovies = L0_1
L0_1 = nil
_oIntroMovieWidget = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = _nMovie
  if not L0_2 then
    L0_2 = 0
  end
  _nMovie = L0_2
  L0_2 = _nMovie
  L0_2 = L0_2 + 1
  _nMovie = L0_2
  L0_2 = tMovies
  L1_2 = _nMovie
  L0_2 = L0_2[L1_2]
  if L0_2 then
    L0_2 = tMovies
    L1_2 = _nMovie
    L0_2 = L0_2[L1_2]
    L0_2 = L0_2[1]
    if L0_2 then
      L0_2 = _oIntroMovieWidget
      if L0_2 then
        goto lbl_37
      end
    end
  end
  L0_2 = nil
  _nMovie = L0_2
  L0_2 = MrxGuiBase
  L0_2 = L0_2.RemoveWidget
  L1_2 = _oIntroMovieWidget
  L0_2(L1_2)
  L0_2 = _oIntroMovieWidget
  L1_2 = L0_2
  L0_2 = L0_2.delete
  L0_2(L1_2)
  L0_2 = nil
  _oIntroMovieWidget = L0_2
  L0_2 = Start
  L0_2()
  do return end
  ::lbl_37::
  L0_2 = tMovies
  L1_2 = _nMovie
  L0_2 = L0_2[L1_2]
  L0_2 = L0_2[1]
  L1_2 = tMovies
  L2_2 = _nMovie
  L1_2 = L1_2[L2_2]
  L1_2 = L1_2[2]
  L2_2 = -1 < L1_2
  
  function L3_2(A0_3)
    local L1_3, L2_3
    L1_3 = _oIntroMovieWidget
    L2_3 = L1_3
    L1_3 = L1_3.Stop
    L1_3(L2_3)
    L1_3 = _PlayMovie
    L1_3()
  end
  
  L4_2 = _oIntroMovieWidget
  L5_2 = L4_2
  L4_2 = L4_2.SetMovie
  L6_2 = L0_2
  L4_2(L5_2, L6_2)
  L4_2 = _oIntroMovieWidget
  L5_2 = L4_2
  L4_2 = L4_2.SetEndCallback
  L6_2 = L3_2
  L7_2 = {}
  L8_2 = L0_2
  L7_2[1] = L8_2
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = _oIntroMovieWidget
  L5_2 = L4_2
  L4_2 = L4_2.Play
  L4_2(L5_2)
end

_PlayMovie = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = Sys
  L0_2 = L0_2.SetLuaSaveVersion
  L1_2 = GetSaveDataVersion
  L1_2, L2_2, L3_2 = L1_2()
  L0_2(L1_2, L2_2, L3_2)
  L0_2 = Graphics
  L0_2 = L0_2.SetGamma
  L1_2 = 0
  L2_2 = 0.8
  L3_2 = 1
  L0_2(L1_2, L2_2, L3_2)
  L0_2 = Sys
  L0_2 = L0_2.PlayIntroMovies
  L0_2 = L0_2()
  if not L0_2 then
    L0_2 = Start
    L0_2()
    return
  end
  L0_2 = MrxGuiBase
  L0_2 = L0_2.MovieWidget
  L1_2 = L0_2
  L0_2 = L0_2.new
  L0_2 = L0_2(L1_2)
  _oIntroMovieWidget = L0_2
  L0_2 = _oIntroMovieWidget
  L1_2 = L0_2
  L0_2 = L0_2.SetFullscreen
  L2_2 = "Letterbox"
  L0_2(L1_2, L2_2)
  L0_2 = _oIntroMovieWidget
  L1_2 = L0_2
  L0_2 = L0_2.SetIgnoresPause
  L2_2 = true
  L0_2(L1_2, L2_2)
  L0_2 = MrxGuiBase
  L0_2 = L0_2.AddWidget
  L1_2 = _oIntroMovieWidget
  L0_2(L1_2)
  L0_2 = Sound
  L0_2 = L0_2.OverrideUserMusic
  if L0_2 then
    L0_2 = Sound
    L0_2 = L0_2.OverrideUserMusic
    L0_2()
  end
  L0_2 = _PlayMovie
  L0_2()
end

Init = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = Sound
  L0_2 = L0_2.RestoreUserMusic
  if L0_2 then
    L0_2 = Sound
    L0_2 = L0_2.RestoreUserMusic
    L0_2()
  end
  L0_2 = Net
  L0_2 = L0_2.AutoClient
  L0_2 = L0_2()
  if L0_2 then
    L0_2 = MrxGuiShellBootstrap
    L0_2 = L0_2.LoadShell
    L0_2()
    L0_2 = Net
    L0_2 = L0_2.ConnectToServer
    L0_2()
  else
    L0_2 = Net
    L0_2 = L0_2.AutoLobby
    L0_2 = L0_2()
    if L0_2 then
      L0_2 = MrxGuiShellBootstrap
      L0_2 = L0_2.LoadShell
      L0_2()
      L0_2 = Net
      L0_2 = L0_2.EnterLobby
      L0_2()
    else
      L0_2 = Sys
      L0_2 = L0_2.AutoLoad
      L0_2 = L0_2()
      if L0_2 then
        L0_2 = Net
        L0_2 = L0_2.AutoServer
        L0_2 = L0_2()
        if L0_2 then
          L0_2 = MrxGuiShellBootstrap
          L0_2 = L0_2.LoadShell
          L0_2()
          L0_2 = Net
          L0_2 = L0_2.StartServer
          L1_2 = Net
          L1_2 = L1_2.GetHostName
          L1_2 = L1_2()
          L2_2 = Sys
          L2_2 = L2_2.GetLevelName
          L2_2 = L2_2()
          L3_2 = Sys
          L3_2 = L3_2.GetMasterScriptName
          L3_2 = L3_2()
          L0_2(L1_2, L2_2, L3_2)
        else
          L0_2 = MrxGuiShellBootstrap
          L0_2 = L0_2.LoadShell
          L0_2()
        end
      else
        L0_2 = MrxGuiShellBootstrap
        L0_2 = L0_2.EnterShell
        L0_2()
      end
    end
  end
end

Start = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = 3
  return L0_2
end

GetSaveDataVersion = L0_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = MrxSoundShellBootstrap
  L0_2 = L0_2.PreExitShell
  L0_2()
  L0_2 = Event
  L0_2 = L0_2.Create
  L1_2 = Event
  L1_2 = L1_2.TimerRelative
  L2_2 = {}
  L3_2 = MrxSoundShellBootstrap
  L3_2 = L3_2.EXITSHELL_FADELENGTH
  L3_2 = L3_2 + 0.05
  L4_2 = true
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L3_2 = ShellExitComplete
  L0_2(L1_2, L2_2, L3_2)
end

ResetSingleton = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = MrxSoundShellBootstrap
  L0_2 = L0_2.ExitShell
  L0_2()
  L0_2 = MrxGuiShellBootstrap
  L0_2 = L0_2.Reset
  L0_2()
  L0_2 = MrxGuiShellBootstrap
  L0_2 = L0_2.ExitShell
  L0_2()
  L0_2 = Pg
  L0_2 = L0_2.ResetSingletonDone
  L0_2()
end

ShellExitComplete = L0_1
