@echo off
REM Environment setup for Mercenaries 2 recreation project
REM Usage: call env.bat   (from any cmd.exe session)

set "MERCS2_ROOT=%~dp0"

REM bsdiff, bspatch, bzip2
set "PATH=%MERCS2_ROOT%tools\bin;%PATH%"

REM Lua 5.1.5 (Mercs2 float build)
set "PATH=%MERCS2_ROOT%tools\lua51;%PATH%"

REM GNU Make 3.81
set "PATH=C:\Program Files (x86)\GnuWin32\bin;%PATH%"

REM MinGW (i686 gcc)
set "PATH=C:\Users\Shadow\mingw32\bin;%PATH%"

echo [env] PATH updated:
echo        tools\bin       (bsdiff, bspatch, bzip2)
echo        tools\lua51     (lua, luac)
echo        GnuWin32\bin    (make)
echo        mingw32\bin     (gcc)
