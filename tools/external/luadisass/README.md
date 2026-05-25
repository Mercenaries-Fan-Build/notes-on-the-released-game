# LuaDisAss (optional vendor)

This directory is **intentionally empty** in git.

## Setup

```bash
git clone https://github.com/jcmnn/LuaDisAss.git tools/external/luadisass/upstream
# Follow upstream README for Python 2/3 requirements.

export LUADISASS=/absolute/path/to/LuaDisAss.py   # or the entry script upstream documents
.venv/bin/python tools/lua_script_chunks.py
```

Disassembly output (when `LUADISASS` works) lands beside the `.chunk.bin` files under `output/lua_chunks/scripts_vz/`.
