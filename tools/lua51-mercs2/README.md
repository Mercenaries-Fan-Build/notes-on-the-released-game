Lua 5.1.5 (Mercenaries 2 float build)

Patched for Mercenaries 2 bytecode compatibility:
- lua_Number = float (4 bytes, single precision)
- sizeof(size_t) forced to 4 in bytecode format
- Bytecode header: 1b4c75615100010404040400

Usage:
  ./luac -o output.luac input.lua    # compile
  ./lua script.lua                   # run
