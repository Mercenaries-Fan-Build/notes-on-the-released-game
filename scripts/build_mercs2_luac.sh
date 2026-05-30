#!/usr/bin/env bash
#
# Download Lua 5.1.5, apply Mercenaries 2 compatibility patches, and build luac.
#
# Patches applied:
#   - luaconf.h: lua_Number = float (4-byte single precision, not double)
#   - lundump.c: Read size_t as uint32_t (game uses 4-byte size_t in bytecode)
#   - ldump.c:   Write size_t as uint32_t (matching the game's bytecode format)
#   - lundump.c: Report 4-byte size_t in the bytecode header
#
# Result: lua-5.1.5/src/luac ready for compiling Mercenaries 2-compatible bytecode
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LUA_DIR="$REPO_ROOT/lua-5.1.5"
LUA_TARBALL="lua-5.1.5.tar.gz"
LUA_URL="https://www.lua.org/ftp/$LUA_TARBALL"

if [ -x "$LUA_DIR/src/luac" ]; then
    echo "luac already built at $LUA_DIR/src/luac"
    "$LUA_DIR/src/luac" -v
    exit 0
fi

echo "=== Downloading Lua 5.1.5 ==="
cd "$REPO_ROOT"
if [ ! -f "$LUA_TARBALL" ]; then
    curl -fSL -o "$LUA_TARBALL" "$LUA_URL"
fi

echo "=== Extracting ==="
rm -rf lua-5.1.5
tar xzf "$LUA_TARBALL"
rm -f "$LUA_TARBALL"

echo "=== Patching luaconf.h: lua_Number = float ==="
cd "$LUA_DIR/src"

cat > /tmp/luaconf_patch.py << 'PYEOF'
import re
text = open("luaconf.h").read()

# Replace LUA_NUMBER_DOUBLE + LUA_NUMBER double with float
text = re.sub(
    r'#define LUA_NUMBER_DOUBLE\n#define LUA_NUMBER\s+double',
    '/* Mercenaries 2 uses single-precision float (4-byte lua_Number) */\n'
    '/* #define LUA_NUMBER_DOUBLE */\n'
    '#define LUA_NUMBER\tfloat',
    text
)

# Fix UACNUMBER
text = re.sub(
    r'#define LUAI_UACNUMBER\s+double',
    '#define LUAI_UACNUMBER\tdouble  /* variadic promotion still needs double */',
    text
)

# Fix format strings for float
text = re.sub(r'#define LUA_NUMBER_FMT\s+"%.14g"', '#define LUA_NUMBER_FMT\t\t"%.7g"', text)
text = re.sub(
    r'#define lua_number2str\(s,n\)\s+sprintf\(\(s\), LUA_NUMBER_FMT, \(double\)\(n\)\)',
    '#define lua_number2str(s,n)\tsprintf((s), LUA_NUMBER_FMT, (n))',
    text
)
text = re.sub(
    r'#define lua_str2number\(s,p\)\s+strtod\(\(s\), \(p\)\)',
    '#define lua_str2number(s,p)\tstrtof((s), (p))',
    text
)

open("luaconf.h", "w").write(text)
print("  Patched luaconf.h for float lua_Number")
PYEOF
python3 /tmp/luaconf_patch.py

echo "=== Patching lundump.c: read 4-byte size_t ==="

# Add uint32_t include
sed -i.bak '1s/^/#include <stdint.h>\n/' lundump.c

# Patch LoadString to use uint32_t for size
cat > /tmp/lundump_patch.py << 'PYEOF'
import re, sys
text = open("lundump.c").read()

# Patch LoadString: replace size_t size reading with uint32_t
old = """ size_t size;
 LoadVar(S,size);"""
new = """ /* Mercenaries 2 bytecode uses 4-byte size_t regardless of host platform */
 uint32_t size32;
 size_t size;
 LoadMem(S,&size32,1,sizeof(uint32_t));
 size = (size_t)size32;"""
if old in text:
    text = text.replace(old, new)
    print("  Patched LoadString")
else:
    print("  LoadString already patched or not found")

# Patch luaU_header to report 4-byte size_t
old2 = '*h++=(char)sizeof(size_t);'
new2 = '*h++=(char)4;\t\t\t\t\t/* force 4-byte size_t in bytecode (Mercenaries 2 compat) */'
if old2 in text:
    text = text.replace(old2, new2)
    print("  Patched header size_t")
else:
    print("  Header size_t already patched or not found")

open("lundump.c", "w").write(text)
PYEOF
python3 /tmp/lundump_patch.py

echo "=== Patching ldump.c: write 4-byte size_t ==="

# Add uint32_t include
sed -i.bak '1s/^/#include <stdint.h>\n/' ldump.c

cat > /tmp/ldump_patch.py << 'PYEOF'
import sys
text = open("ldump.c").read()

old = """static void DumpString(const TString* s, DumpState* D)
{
 if (s==NULL || getstr(s)==NULL)
 {
  size_t size=0;
  DumpVar(size,D);
 }
 else
 {
  size_t size=s->tsv.len+1;		/* include trailing '\\0' */
  DumpVar(size,D);
  DumpBlock(getstr(s),size,D);
 }
}"""

new = """static void DumpString(const TString* s, DumpState* D)
{
 /* Mercenaries 2 bytecode uses 4-byte size_t regardless of host platform */
 if (s==NULL || getstr(s)==NULL)
 {
  uint32_t size32=0;
  DumpVar(size32,D);
 }
 else
 {
  uint32_t size32=(uint32_t)(s->tsv.len+1);\t/* include trailing '\\0' */
  DumpVar(size32,D);
  DumpBlock(getstr(s),(size_t)size32,D);
 }
}"""

if old in text:
    text = text.replace(old, new)
    print("  Patched DumpString")
else:
    print("  DumpString already patched or not found")

open("ldump.c", "w").write(text)
PYEOF
python3 /tmp/ldump_patch.py

# Clean up .bak files
rm -f *.bak

echo "=== Building luac ==="
cd "$LUA_DIR"

# Detect platform
case "$(uname -s)" in
    Darwin*) PLAT=macosx ;;
    Linux*)  PLAT=linux ;;
    *)       PLAT=posix ;;
esac

make "$PLAT" 2>&1

echo ""
echo "=== Done ==="
"$LUA_DIR/src/luac" -v
echo "Compiler ready at: $LUA_DIR/src/luac"
echo ""
echo "Bytecode format: Lua 5.1, float (4-byte), 4-byte size_t, little-endian"
echo "Compatible with Mercenaries 2: World in Flames"
