# ASI Loader Setup for Mercenaries 2: World in Flames

## Overview

**ThirteenAG's Ultimate ASI Loader** is a proxy DLL that loads custom `.asi` plugins
into any game process. For Mercenaries 2, we use it to load `cruise.asi` — a minimal
DLL that creates the SecuROM spoof Event — without needing to patch the game executable.

This approach is **simpler and safer** than exe patching because:
- No modification to the original game files
- Works with both demo (SecuROM v7.38) and retail (SecuROM v7.37) executables
- No need for a cracked donor exe (retail)
- Trivially reversible (delete the proxy DLL)

---

## How It Works

### PE Loader Timing (Why This Works)

The Windows PE loader processes executables in this order:

1. **Map the PE image** into memory
2. **Process the Import Table** — load all imported DLLs (including our proxy `dinput8.dll`)
3. **Call DllMain** for each loaded DLL with `DLL_PROCESS_ATTACH`
4. **Call TLS callbacks** (if any)
5. **Jump to AddressOfEntryPoint** — for SecuROM exes, this is the `Sitext` stub

Because imports are resolved and DllMain fires **before** the entry point runs,
our cruise.asi's DllMain creates the spoof Event before SecuROM's Sitext stub
checks for it. The timing is guaranteed by the Windows loader design.

### SecuROM Check Flow

```
┌─────────────────────────────────────────────────────────────┐
│ Windows Loader                                               │
│  1. Load dinput8.dll (ASI Loader proxy)                      │
│     → DllMain fires → loads cruise.asi via LoadLibrary       │
│       → cruise.asi DllMain fires → creates "v7_XXXX" Event  │
│  2. Load other DLLs (d3d9, dsound, etc.)                     │
│  3. Call entry point → Sitext stub                           │
│     → Decrypts .text section                                 │
│     → Checks "v7_XXXX" Event → SIGNALED ✓                   │
│     → Jumps to OEP → game runs normally                      │
└─────────────────────────────────────────────────────────────┘
```

---

## Download

| Component | URL | Version |
|-----------|-----|---------|
| Ultimate ASI Loader (Win32) | https://github.com/ThirteenAG/Ultimate-ASI-Loader/releases/download/Win32-latest/dinput8-Win32.zip | v9.7.1 (latest) |
| Repository | https://github.com/ThirteenAG/Ultimate-ASI-Loader | MIT License |

**Direct download links for all proxy DLL variants (Win32):**
- `dinput8.dll` — https://github.com/ThirteenAG/Ultimate-ASI-Loader/releases/download/Win32-latest/dinput8-Win32.zip
- `d3d9.dll` — https://github.com/ThirteenAG/Ultimate-ASI-Loader/releases/download/Win32-latest/d3d9-Win32.zip
- `dsound.dll` — https://github.com/ThirteenAG/Ultimate-ASI-Loader/releases/download/Win32-latest/dsound-Win32.zip
- `binkw32.dll` — https://github.com/ThirteenAG/Ultimate-ASI-Loader/releases/download/Win32-latest/binkw32-Win32.zip
- `version.dll` — https://github.com/ThirteenAG/Ultimate-ASI-Loader/releases/download/Win32-latest/version-Win32.zip
- `winmm.dll` — https://github.com/ThirteenAG/Ultimate-ASI-Loader/releases/download/Win32-latest/winmm-Win32.zip
- `xinput1_3.dll` — https://github.com/ThirteenAG/Ultimate-ASI-Loader/releases/download/Win32-latest/xinput1_3-Win32.zip

---

## Mercenaries 2 Import Table

The game imports **all** of the following DLLs that the ASI Loader can proxy:

| DLL | Imported? | Recommended? |
|-----|-----------|-------------|
| **DINPUT8.dll** | ✅ Yes | ✅ **Primary choice** |
| **d3d9.dll** | ✅ Yes | ⚠️ Conflicts with graphics mods (ReShade, DXVK) |
| **DSOUND.dll** | ✅ Yes | ✅ Good alternative |
| **WINMM.dll** | ✅ Yes | ✅ Good alternative |
| **VERSION.dll** | ✅ Yes | ✅ Good alternative |
| **XINPUT1_3.dll** | ✅ Yes | ⚠️ May conflict with controller remapping |
| **binkw32.dll** | ✅ Yes | ⚠️ Must replace original (Bink video codec) |

**Recommendation: Use `dinput8.dll`** — it's the most commonly used proxy for game
modding, has no conflicts, and is imported by Mercenaries 2 in both demo and retail.

---

## Installation

### File Layout

```
Mercenaries 2 World in Flames/
├── Mercenaries2.exe          (original, UNMODIFIED)
├── dinput8.dll               (← ASI Loader, renamed from download)
├── scripts/
│   ├── cruise.asi            (← our SecuROM spoof plugin)
│   └── global.ini            (← configuration, CRITICAL for DRM games)
└── ... (other game files)
```

### Step-by-Step

1. **Download** the ASI Loader Win32 `dinput8.dll`:
   ```
   https://github.com/ThirteenAG/Ultimate-ASI-Loader/releases/download/Win32-latest/dinput8-Win32.zip
   ```

2. **Extract** `dinput8.dll` from the zip into the game directory (next to the .exe)

3. **Create** the `scripts/` folder in the game directory

4. **Generate cruise.asi** (the SecuROM spoof DLL):
   ```bash
   cd /path/to/mercenaries-game
   .venv/bin/python3 tools/remove_securom.py --generate-cruise-asi \
       --asi-output "path/to/game/scripts/cruise.asi"
   ```
   Or simply copy/rename the generated `cruise.dll` to `cruise.asi`:
   ```bash
   .venv/bin/python3 tools/remove_securom.py --generate-cruise \
       "Mercenaries 2 World in Flames DEMO/Merc2-Demo.exe"
   cp "Mercenaries 2 World in Flames DEMO/cruise.dll" \
      "Mercenaries 2 World in Flames DEMO/scripts/cruise.asi"
   ```

5. **Create `scripts/global.ini`** with this content:
   ```ini
   [GlobalSets]
   DontLoadFromDllMain=0
   LoadPlugins=1
   LoadFromScriptsOnly=0
   ```

6. **Run the game** normally — no exe patching required!

### Why `DontLoadFromDllMain=0`?

By default (`DontLoadFromDllMain=1`), the ASI Loader defers plugin loading until
after the entry point hooks fire. For DRM-protected games like Mercenaries 2 where
the entry point IS the DRM stub, we need plugins to load **during** DllMain
(which fires before the entry point). Setting this to `0` ensures cruise.asi
loads early enough for the Event to exist when SecuROM checks it.

This setting was specifically added to fix DRM compatibility (GitHub issue #44).

---

## Configuration Reference

### `scripts/global.ini`

```ini
[GlobalSets]
; CRITICAL: Must be 0 for SecuROM-protected games
; Loads ASI plugins during DllMain (before entry point / Sitext stub)
DontLoadFromDllMain=0

; Enable plugin loading (default: 1)
LoadPlugins=1

; Load from game root + scripts/ + plugins/ + update/ folders (default: 0)
LoadFromScriptsOnly=0

; Search subdirectories recursively (default: 1)
LoadRecursively=1
```

### Plugin Search Paths

The ASI Loader searches for `.asi` files in:
1. Game root directory (same folder as the .exe)
2. `scripts/` subfolder
3. `plugins/` subfolder
4. `update/` subfolder

---

## Technical Details

### cruise.asi Internals

The `.asi` file is just a standard Windows DLL with a different extension.
The ASI Loader calls `LoadLibrary("scripts/cruise.asi")` which triggers:

1. Windows loads the DLL into the process
2. `DllMain(hModule, DLL_PROCESS_ATTACH, NULL)` fires
3. DllMain executes:
   - `GetCurrentProcessId()` → PID
   - `PID XOR 0x19EA3FD3` → derived value
   - `sprintf(buf, "v7_%04d", derived)` → Event name
   - `CreateEventA(NULL, TRUE, TRUE, buf)` → named Event, manual-reset, signaled
4. DllMain returns `TRUE`

The Event persists for the lifetime of the process. When SecuROM's Sitext stub
later calls `WaitForSingleObject` on this Event name, it returns immediately
(signaled state) — auth "passes."

### Compatibility Notes

- **Demo (SecuROM v7.38)**: Works perfectly. Sitext decrypts .text, checks Event, passes.
- **Retail (SecuROM v7.37)**: Works for the disc check portion. However, Product
  Activation (PA) may still block — PA phones home to dead servers. For retail,
  you may still need the text-transplant approach OR combine ASI Loader with a
  separate PA bypass.
- **Already-cracked exe**: Not needed (SecuROM stub is already bypassed).

### Why Not Just Use cruise.dll Directly?

The game doesn't import `cruise.dll`, so Windows won't load it automatically.
Options:
1. **Patch the import table** (our current `remove_securom.py` approach) — requires exe modification
2. **ASI Loader proxy** (this document) — no exe modification, just drop files in

---

## Verification

### Check ASI Loader is working

1. Run the game
2. Look for a `dinput8.log` or `asiloader.log` file in the game directory
3. The log should show cruise.asi being loaded

### Check Event creation

Use Process Explorer or a debugger to verify the named Event exists:
- Name pattern: `v7_XXXX` (4-digit number derived from PID)
- Type: Manual-reset
- State: Signaled

### Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Game doesn't start at all | dinput8.dll wrong arch (x64 vs x86) | Use Win32 version |
| SecuROM error on launch | cruise.asi not loading early enough | Ensure `DontLoadFromDllMain=0` in global.ini |
| SecuROM error on launch | cruise.asi not found | Check it's in `scripts/` folder |
| Game crashes after logo | Unrelated to ASI Loader | Known Mercs 2 issue (memory crash) |
| "Please insert disc" | Event not matching | Verify XOR constant matches game version |

---

## Community Status

As of 2026, there are no widely-published Mercenaries 2 PC mods using the ASI Loader
specifically. However:

- ThirteenAG's **WidescreenFixesPack** has an open request (issue #1693) for a
  Mercenaries 2 "Fusion Mod" to fix memory crashes, shadow resolution, draw distance,
  and FPS-related issues
- The game is confirmed to use Direct3D 9, making it fully compatible with ASI Loader
- DXVK has a known issue with Mercs 2 (crashes after first logo, doitsujin/dxvk#1846)
- PCGamingWiki documents the game's technical issues but doesn't mention ASI Loader usage

This makes our project potentially the **first documented use** of ASI Loader with
Mercenaries 2 for SecuROM bypass.

---

## Comparison: ASI Loader vs Exe Patching

| Aspect | ASI Loader | Exe Patching |
|--------|-----------|-------------|
| Modifies exe | No | Yes |
| Reversible | Delete 2 files | Re-download exe |
| Retail PA bypass | Partial (disc only) | Full (text transplant) |
| Demo support | Full | Full |
| Extra files | dinput8.dll + cruise.asi + global.ini | cruise.dll + patched exe |
| Complexity | Drop-in | PE surgery |
| Compatibility | Any version | Version-specific offsets |

**Recommendation**: Use ASI Loader for the demo and for retail disc-check bypass.
For retail Product Activation bypass, the text-transplant approach is still needed.
