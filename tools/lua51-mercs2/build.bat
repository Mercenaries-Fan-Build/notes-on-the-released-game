@echo off
setlocal
set "GCC=C:\Users\Shadow\mingw32\bin\gcc.exe"
set "AR=C:\Users\Shadow\mingw32\bin\ar.exe"
set "SRCDIR=%~dp0src"
set "OUTDIR=%~dp0"
set "CFLAGS=-O2 -Wall -DLUA_COMPAT_ALL"

cd /d "%SRCDIR%"

echo === Compiling Lua 5.1.5 (float build) ===

echo [1/4] Compiling library objects...
for %%f in (lapi lauxlib lbaselib lcode ldblib ldebug ldo ldump lfunc lgc linit liolib llex lmathlib lmem loadlib lobject lopcodes loslib lparser lstate lstring lstrlib ltable ltablib ltm lundump lvm lzio) do (
    "%GCC%" %CFLAGS% -c %%f.c -o %%f.o
    if errorlevel 1 (
        echo FAILED: %%f.c
        exit /b 1
    )
)
echo    Done.

echo [2/4] Creating static library...
"%AR%" rcs liblua.a lapi.o lauxlib.o lbaselib.o lcode.o ldblib.o ldebug.o ldo.o ldump.o lfunc.o lgc.o linit.o liolib.o llex.o lmathlib.o lmem.o loadlib.o lobject.o lopcodes.o loslib.o lparser.o lstate.o lstring.o lstrlib.o ltable.o ltablib.o ltm.o lundump.o lvm.o lzio.o
if errorlevel 1 (
    echo FAILED: ar
    exit /b 1
)
echo    Done.

echo [3/4] Building lua.exe...
"%GCC%" %CFLAGS% -c lua.c -o lua.o
if errorlevel 1 (
    echo FAILED: lua.c
    exit /b 1
)
"%GCC%" -o "%OUTDIR%lua.exe" lua.o -L. -llua -lm
if errorlevel 1 (
    echo FAILED: link lua.exe
    exit /b 1
)
echo    Done.

echo [4/4] Building luac.exe...
"%GCC%" %CFLAGS% -c luac.c -o luac.o
if errorlevel 1 (
    echo FAILED: luac.c
    exit /b 1
)
"%GCC%" %CFLAGS% -c print.c -o print.o
if errorlevel 1 (
    echo FAILED: print.c
    exit /b 1
)
"%GCC%" -o "%OUTDIR%luac.exe" luac.o print.o -L. -llua -lm
if errorlevel 1 (
    echo FAILED: link luac.exe
    exit /b 1
)
echo    Done.

echo === Build complete ===
echo Output: %OUTDIR%lua.exe
echo Output: %OUTDIR%luac.exe
