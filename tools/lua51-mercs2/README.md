Lua 5.1.5 (Mercenaries 2 bytecode-compatible build)

Produces bytecode identical to the Mercenaries 2 game engine
(32-bit, single-precision float, little-endian).

## How It Works

The build system applies patch files to clean upstream Lua 5.1.5 source
(`tools/lua51-src/src/`) and compiles for the host platform. This ensures
reproducibility — the patches are the single source of truth for all
Mercs2-specific modifications.

```
tools/lua51-src/src/          ← Clean upstream Lua 5.1.5 (read-only)
tools/lua51-mercs2/patches/   ← Mercs2 compatibility patches (tracked in git)
tools/lua51-mercs2/build/     ← Build output (gitignored, ephemeral)
```

## Patches

Applied in sorted order:

| Patch | What it does |
|-------|--------------|
| `01-float-number-type.patch` | `luaconf.h`: `lua_Number` = `float` (4-byte single precision), math uses `floorf`/`powf`/`strtof` |
| `02-dump-32bit-size_t.patch` | `ldump.c`: `DumpString()` writes string lengths as `uint32_t` (4 bytes) instead of native `size_t` |
| `03-undump-32bit-size_t.patch` | `lundump.c`: `LoadString()` reads 4-byte string lengths; `luaU_header()` reports `sizeof(size_t)=4` |

## Expected Bytecode Header

```
1b 4c 75 61 51 00 01 04 04 04 04 00
│  │        │  │  │  │  │  │  │  └── integral flag (0 = float)
│  │        │  │  │  │  │  │  └──── sizeof(lua_Number) = 4
│  │        │  │  │  │  │  └────── sizeof(Instruction) = 4
│  │        │  │  │  │  └──────── sizeof(size_t) = 4 (forced)
│  │        │  │  │  └────────── sizeof(int) = 4
│  │        │  │  └──────────── endianness = 1 (little)
│  │        │  └────────────── format = 0 (official)
│  │        └──────────────── version = 0x51 (Lua 5.1)
│  └───────────────────────── LUA_SIGNATURE "\x1bLua"
└──────────────────────────── ESC byte
```

## Building

### macOS / Linux (via project Makefile)

```bash
make build-luac
```

This:
1. Copies upstream source into `tools/lua51-mercs2/build/`
2. Applies all patches from `tools/lua51-mercs2/patches/`
3. Compiles for the detected platform (macosx/linux/posix)
4. Verifies the bytecode header matches expected format

Output: `tools/lua51-mercs2/build/luac`

Rebuilds automatically if any patch file changes.

### Windows (via build.bat — legacy)

```bat
cd tools\lua51-mercs2
build.bat
```

Uses 32-bit MinGW. Produces `luac.exe` and `lua.exe` in `tools/lua51-mercs2/`.
(32-bit Windows naturally produces correct `sizeof(size_t)=4`.)

## Adding New Patches

To add a new modification:

```bash
# 1. Make changes to the file in tools/lua51-mercs2/build/ (after a build)
# 2. Generate a patch against upstream:
diff -u --label a/filename.c --label b/filename.c \
  tools/lua51-src/src/filename.c \
  tools/lua51-mercs2/build/filename.c \
  > tools/lua51-mercs2/patches/04-description.patch

# 3. Rebuild to verify:
rm -rf tools/lua51-mercs2/build && make build-luac
```
