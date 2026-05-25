# Environment setup for Mercenaries 2 recreation project
# Usage: . .\env.ps1   (dot-source in any PowerShell session)

$root = Split-Path -Parent $MyInvocation.MyCommand.Definition

$env:PATH = "$root\tools\bin;$env:PATH"          # bsdiff, bspatch, bzip2
$env:PATH = "$root\tools\lua51;$env:PATH"        # lua, luac
$env:PATH = "C:\Program Files (x86)\GnuWin32\bin;$env:PATH"  # make
$env:PATH = "C:\Users\Shadow\mingw32\bin;$env:PATH"           # gcc/mingw

Write-Host "[env] PATH updated:" -ForegroundColor Green
Write-Host "       tools\bin       (bsdiff, bspatch, bzip2)"
Write-Host "       tools\lua51     (lua, luac)"
Write-Host "       GnuWin32\bin    (make)"
Write-Host "       mingw32\bin     (gcc)"
