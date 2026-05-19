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

---

## DLC Enable Plugin (dlc_enable.asi)

### Overview

The `dlc_enable.asi` plugin activates DLC content by hooking the game's Lua
runtime. It intercepts three Lua-callable functions that gate DLC access:

| Function | Original Behavior | Hooked Behavior |
|----------|------------------|-----------------|
| `IsOnlineConnected()` | Checks EA FESL server connection → fails (dead servers) | Always returns `true` |
| `IsDLC()` | Returns session DLC flag (never set without entitlement) | Always returns `true` |
| `IsMatchmakingInternet()` | Secondary online check | Always returns `true` |

### How It Works

1. The ASI Loader calls `DllMain` during process startup (before game code runs)
2. `DllMain` spawns a worker thread (to avoid loader lock issues)
3. The thread sleeps 5 seconds, waiting for the game's Lua state initialization
4. It scans the EXE's `.rdata` section (0x00B05000–0x00BF5FFF) for the target
   function name strings ("IsOnlineConnected", "IsDLC", "IsMatchmakingInternet")
5. For each found string, it locates the `luaL_Reg` table entry — a pair of
   `{const char* name, lua_CFunction func}` — by finding a DWORD in .rdata that
   points to the string, followed by a DWORD pointing into .text
6. It overwrites the C function pointer with `Hook_ReturnTrue` — a minimal function
   that pushes boolean `true` onto the Lua stack using direct stack manipulation:
   ```c
   // Lua 5.1 stack layout (float number type, 32-bit):
   //   lua_State + 8 = top pointer (StkId → TValue*)
   //   TValue = { value: 4 bytes, tt: 4 bytes } = 8 bytes total
   //   LUA_TBOOLEAN type tag = 1
   top->value = 1;  // true
   top->tt = 1;     // LUA_TBOOLEAN
   top++;           // advance stack
   return 1;        // one result
   ```

### Generation

Two methods are available:

**Method 1: Python generator (no compiler needed)**

```bash
.venv/bin/python3 tools/build_dlc_asi.py --output "path/to/game/scripts/dlc_enable.asi"
```

Or via make:

```bash
make dlc-enable-asi OUTPUT=./output
```

**Method 2: Native compilation with MinGW**

```bash
cd tools/dlc_enable_asi
make mingw    # requires: brew install mingw-w64 (macOS)
```

### Installation

```
Mercenaries 2 World in Flames/
├── Mercenaries2.exe          (cracked, UNMODIFIED)
├── dinput8.dll               (← ASI Loader Win32 proxy)
├── data/
│   ├── vz.wad               (base game data)
│   └── vz-patch.wad         (← DLC asset blocks, 2196 blocks)
├── scripts/
│   ├── global.ini            (← ASI Loader config)
│   ├── cruise.asi            (← SecuROM spoof plugin)
│   └── dlc_enable.asi        (← DLC content activator)
└── ...
```

### Requirements

- **Cracked EXE**: The plugin targets the cracked/unpacked 51 MB executable
  (SecuROM removed). String offsets differ in the protected retail EXE.
- **cruise.asi**: Still required for SecuROM inline trigger checks.
- **vz-patch.wad**: Must contain PC-compatible DLC asset blocks.
  Generated by `make dlc-port` from the Xbox 360 DLC archive.
- **DLC Lua scripts**: For DLC contracts to actually register, the patch WAD
  must include PC-endian Lua bytecode for the DLC scripts.
  Use `make dlc-bootstrap` to inject the bootstrap scripts.

### What This Plugin Does NOT Do

- Does not modify any game files on disk
- Does not emulate EA's FESL/content server protocol
- Does not handle DLC script compilation (that's the Lua bootstrap pipeline)
- Does not fix Xbox 360 byte-order issues in DLC asset data (that's `ucfx_be_to_le.py`)

### Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Extras menu still shows "Cannot connect" | Plugin didn't hook in time | Increase sleep delay in `build_dlc_asi.py` |
| Game crashes on startup | DLL loaded at bad address | Rebuild with different IMAGE_BASE |
| DLC contracts don't appear in PDA | Lua scripts not in patch WAD | Run `make dlc-bootstrap` |
| "Invalid hash" errors in log | Missing ASET entries in patch WAD | Rebuild patch WAD with correct hashes |

### Logging

The native C version (`dlc_enable.c`) writes a log file to `scripts/dlc_enable.log`
showing which functions were hooked and at what addresses. The Python-generated
version is smaller and does not include logging.
