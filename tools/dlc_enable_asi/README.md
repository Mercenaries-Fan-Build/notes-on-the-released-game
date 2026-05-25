# dlc_enable.asi — DLC Content Activator

Runtime Lua hook plugin for Mercenaries 2: World in Flames that enables DLC
content without modifying game files on disk.

## What It Does

Default build (`make dlc-asi-native`):

| Feature | Effect |
|---------|--------|
| `Debug.Printf` reg patch | Routes script `Debug.Printf(...)` to `Hook_LogPrintf` → `dlc_enable_crash.log` |
| `print()` reg patch | Same for shell/bootstrap `print(...)` (string-first args only) |
| Net hooks (optional) | `IsOnlineConnected` / unlock / matchmaking → return `true` |

Does **not** inline-hook the shared stub at `0x006D5640` (that hits 60+ unrelated
functions and floods the log). Verify bindings:

```bash
make debug-binding-report OUTPUT=./output
```

On PC retail, `Debug.Printf`, `print`, and `Sys.WriteToConsole` all point at the
same no-op stub — there is no engine console to forward into; the reg patch is the restore path.

## Build Options

### Option 1: Python Generator (Recommended — no compiler needed)

```bash
cd /path/to/mercenaries-game
.venv/bin/python3 tools/build_dlc_asi.py --output scripts/dlc_enable.asi
# or:
make dlc-enable-asi OUTPUT=./output
```

### Option 2: MinGW Cross-Compile

```bash
# macOS: brew install mingw-w64
# Linux: apt install gcc-mingw-w64-i686
cd tools/dlc_enable_asi
make mingw
```

### Option 3: MSVC (Windows)

```bash
cd tools\dlc_enable_asi
make msvc
```

## Installation

```
<game directory>/
├── Mercenaries2.exe       (cracked)
├── dinput8.dll            (ASI Loader — download from ThirteenAG)
├── data/
│   └── vz-patch.wad      (DLC assets — from make dlc-port)
└── scripts/
    ├── global.ini         (DontLoadFromDllMain=0)
    ├── cruise.asi         (SecuROM bypass)
    └── dlc_enable.asi     (THIS PLUGIN)
```

## Technical Details

The plugin uses the `luaL_Reg` table patching technique:

1. DllMain spawns a worker thread (avoids loader lock)
2. Thread sleeps 5s (waits for Lua initialization)
3. Scans `.rdata` (0x00B05000–0x00BF5FFF) for target string bytes
4. Finds `{string_ptr, func_ptr}` pairs in registration tables
5. Overwrites `func_ptr` with `Hook_ReturnTrue` via VirtualProtect
6. `Hook_ReturnTrue` uses direct Lua 5.1 stack manipulation (no API calls)

This is safe because:
- The Lua registration tables are read during `luaL_register()` at startup
- After registration, the tables are not re-read
- But the registered function pointers ARE stored separately in the Lua state
- So we must patch BEFORE the functions are first called (the 5s delay handles this)

See `docs/asi_loader_setup.md` for full documentation.
