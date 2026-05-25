@echo off
REM ============================================================================
REM  Mercenaries 2 — Windows Test Environment Auto-Setup
REM
REM  This runs automatically after Windows installation via dockur/windows /oem.
REM  It copies patched game files from the shared folder into the game directory.
REM
REM  Shared folder layout (mounted from host ./output):
REM    C:\Shared\patched\Mercenaries2.exe      — cracked EXE (from make crack-game)
REM    C:\Shared\patched\cruise.dll             — SecuROM spoof DLL
REM    C:\Shared\data\vz-patch.wad              — DLC patch WAD
REM    C:\Shared\data\Audios\*.pws              — DLC audio files
REM    C:\Shared\game-install\                  — full game install (user-provided)
REM ============================================================================

echo ============================================================
echo  Mercenaries 2 Test Environment Setup
echo ============================================================
echo.

set "SHARED=C:\Shared"
set "GAME_DIR=C:\Mercs2"

REM --- Step 1: Copy game install if provided -----------------------------------
if exist "%SHARED%\game-install\Mercenaries2.exe" (
    echo [1/5] Copying game installation from shared folder...
    if not exist "%GAME_DIR%" mkdir "%GAME_DIR%"
    xcopy "%SHARED%\game-install\*" "%GAME_DIR%\" /E /Y /Q
    echo       Done.
) else (
    echo [1/5] No game-install folder found in shared — skipping base game copy.
    echo       Place your game files in: output/game-install/ on the host.
    if not exist "%GAME_DIR%" mkdir "%GAME_DIR%"
    if not exist "%GAME_DIR%\data" mkdir "%GAME_DIR%\data"
)
echo.

REM --- Step 2: Apply cracked EXE -----------------------------------------------
if exist "%SHARED%\patched\Mercenaries2.exe" (
    echo [2/5] Copying patched EXE...
    copy /Y "%SHARED%\patched\Mercenaries2.exe" "%GAME_DIR%\Mercenaries2.exe"
    echo       Done.
) else (
    echo [2/5] No patched EXE found. Run 'make crack-game' on the host first.
)
echo.

REM --- Step 3: Copy cruise.dll (SecuROM spoof) ---------------------------------
if exist "%SHARED%\patched\cruise.dll" (
    echo [3/5] Copying cruise.dll...
    copy /Y "%SHARED%\patched\cruise.dll" "%GAME_DIR%\cruise.dll"
    echo       Done.
) else (
    echo [3/5] No cruise.dll found — SecuROM spoof not available.
)
echo.

REM --- Step 4: Copy vz-patch.wad (DLC content) ---------------------------------
if exist "%SHARED%\data\vz-patch.wad" (
    echo [4/5] Copying vz-patch.wad to game data directory...
    if not exist "%GAME_DIR%\data" mkdir "%GAME_DIR%\data"
    copy /Y "%SHARED%\data\vz-patch.wad" "%GAME_DIR%\data\vz-patch.wad"
    echo       Done.
) else (
    echo [4/5] No vz-patch.wad found. Run 'make dlc-port' on the host first.
)
echo.

REM --- Step 5: Copy DLC audio files (.pws) -------------------------------------
if exist "%SHARED%\data\Audios" (
    echo [5/5] Copying DLC audio files...
    if not exist "%GAME_DIR%\data\Audios" mkdir "%GAME_DIR%\data\Audios"
    xcopy "%SHARED%\data\Audios\*.pws" "%GAME_DIR%\data\Audios\" /Y /Q 2>nul
    echo       Done.
) else (
    echo [5/5] No DLC audio directory found — skipping.
)
echo.

REM --- Summary ------------------------------------------------------------------
echo ============================================================
echo  Setup Complete! Summary:
echo ============================================================
echo.
echo  Game directory: %GAME_DIR%
echo.

if exist "%GAME_DIR%\Mercenaries2.exe" (
    echo  [OK] Mercenaries2.exe
) else (
    echo  [--] Mercenaries2.exe  (missing)
)

if exist "%GAME_DIR%\cruise.dll" (
    echo  [OK] cruise.dll
) else (
    echo  [--] cruise.dll        (missing)
)

if exist "%GAME_DIR%\data\vz-patch.wad" (
    echo  [OK] data\vz-patch.wad
) else (
    echo  [--] data\vz-patch.wad (missing)
)

echo.
echo  To launch the game, open C:\Mercs2\Mercenaries2.exe
echo  or use the desktop shortcut (if created).
echo ============================================================

REM Create a desktop shortcut if the game exe exists
if exist "%GAME_DIR%\Mercenaries2.exe" (
    echo Set oWS = WScript.CreateObject("WScript.Shell") > "%TEMP%\shortcut.vbs"
    echo sLinkFile = oWS.SpecialFolders("Desktop") ^& "\Mercenaries 2.lnk" >> "%TEMP%\shortcut.vbs"
    echo Set oLink = oWS.CreateShortcut(sLinkFile) >> "%TEMP%\shortcut.vbs"
    echo oLink.TargetPath = "%GAME_DIR%\Mercenaries2.exe" >> "%TEMP%\shortcut.vbs"
    echo oLink.WorkingDirectory = "%GAME_DIR%" >> "%TEMP%\shortcut.vbs"
    echo oLink.Save >> "%TEMP%\shortcut.vbs"
    cscript //nologo "%TEMP%\shortcut.vbs"
    del "%TEMP%\shortcut.vbs"
    echo  Desktop shortcut created.
)

pause
