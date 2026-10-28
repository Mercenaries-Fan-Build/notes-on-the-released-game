# Lua script modules: load, Init, Deinit, ObjectScript calls (PC v1.0)

How retail loads a script resource (`{name hash, 0x42498680}`, ASET type 35), builds its module env,
runs it, and calls an ObjectScript's `OnActivate`/`OnDeactivate`. Decoded 2026-10-22 from the pc-v10
code and the SecuROM-relocated fragments in the clean-load capture
(`game-files/memory-dumps`). Grades: PROVEN unless marked.

## 1. The resource

Container parser `0x59CF90`:
- `INFO`: the name (`res+0x18`), a u16 env presize hint (`+0x2C`), a u8 inherit count (`+0x2A`).
- `BINN`: the bytecode buffer (`+0x24`) and its size (`+0x30`).
- `DEPS`: child resources (`+0x1C`, count `+0x28`); each is found or created and AddRef'd.
- `INVD`: the parse returns 0.

Queueing `0x59CD30` pushes the resource onto the host list `[host+0x20]` (link `+0x4C`, flag `0x20`)
and recurses into its DEPS children.

## 2. The state machine

The pump `0x5A2BC0` runs from the host tick `0x5A1890`, before the event update `0x5EB560`. It steps
each queued resource with `0x59CD70` and unlinks it at state 5, at state F, or at resource status 3.

`0x59CD70` (state nibble `+0x44 & 0xF`) runs once per pass (`+0x48` = pass counter `[0x1175F2C]`). Its
target is min(5, every child's state); a child at F or status 3 sets the parent to F. It then
advances its own state while it is ≤ the target.

| state | step |
|---|---|
| 2 | `0x5A30D0` → `0x246B5A0`: the env. `_MODULES[name]` if it exists (two resources with one name share it), else a new table (`createtable(n, n)`, n = presize + 5) stored there. `env._THIS = env`, `env[1] = name`, `setmetatable(env, _MODULESMETATABLE)`, `env[2] = {}` when the inherit count is > 0, `res+0x40 = luaL_ref(REGISTRY, env)`. |
| 3 | `0x2482C00`: `luaL_loadbuffer(buf, size, INFO name)`, `setfenv(registry[ref])`, `pcall(0, 0, 0)`. An error pops the message silently; the module goes to F. |
| 4 | `0x59CEAC` → `0x5A0DB0` → `0x24629C0`: `pcall(env.Init, env)` when `Init` is a function; the result is ignored, so an Init error still reaches 5. |
| 5 | Ready. The bytecode buffer is freed (`0x59CF0B`). |
| F | Terminal for this resource object. An ObjectScript waiting on it never sees state 5 and sits in the activation queue until the stall breaker removes it (INFERRED from the flag logic). |

There is no `__index = _G` on the env: `_MODULEINDEX` (`0x5AEB90`) searches each base in `env[2]` in
order, then `_G[key]` (whether that last read is raw is not read).

## 3. References, Deinit, reload

- AddRef (vtable `0xBB4498` `+0x30` = `0x59C650`): ObjectScript activation begin `0x66C1F0` calls
  `0x873F20(key, 3)` (find or create, AddRef; u16 count at `+0x12`). With flag `0x40` set, AddRef
  clears it and re-queues the module.
- Release (`+0x34` = `0x59C6B0`): ObjectScript deactivate `0x66C350` → `0x665F10` → `0x873F80`; flag
  `0x10` suppresses the decrement. At count 0, `0x59C730` → `0x649CC0`:
  - `Deinit(env)` through `0x5A0DB0` (pcall, result ignored) while the VM is alive (`[host+0xC42]`)
    and the ref is > 0. The `"Deinit"` pointer is computed (`[0x245A98C] − [0x4935E0] = 0xBB459C`),
    which is why it has no static xref.
  - Flag `0x40`, state 5 → 3 (`0x649D20`), unlinked from the queue.
- The env, its ref and every module global survive a Deinit. The next AddRef re-queues: state 3 → 4
  runs `Init(env)` again and the module returns to 5; the body does not run again (its bytecode was
  freed). This fits the shipped `x = x or {}` Init pattern.
- Full destroy, when all four per-class counts (`+0xC..+0x12`) are 0 and the loader query does not
  return 3: `+0x2C(3)` = `0x2931000` frees name, bytecode and DEPS and releases the children; past
  state 1 it tears the env down (`0x5A35F0`: `_MODULES[name] = nil`, unref, and one more env field
  set to nil whose string is not resolved). A later load builds a fresh env.

## 4. Calling a module function (`0x5A0CC0`)

1. `0x5A0C30` pushes `registry[res+0x40]`; it requires state ≥ 3 and a ref > 0
   (`0x2EE0081..0x2EE0090`).
2. `lua_getfield(env, name)` through `luaV_gettable` (`0x85DB20` → `0x865D60`), so the inherit chain
   and then `_G` are searched.
3. A nil result skips the call.
4. `lua_insert(-2 - nargs)` (`0x5A0370`), `lua_pcall(nargs + 1, 0, 0)` (`0x675DA0` → `0x85DF50`): the
   env goes last, as a hidden extra argument. errfunc is 0 and an error message is popped and dropped
   (`0x675E08..0x675E2C`).

ObjectScript (`0x5A0F10` → `0x6C6F00` → `0x5A0CC0`): settop 0; the guid as lightuserdata
(`0x4B1270`, 0 → nil); RuntimeOwnerGuid or nil (`0x4B2A50`); `(float)iArg` (`cvtsi2ss`, `0x4B29D8`).
The call is skipped when the record or its script hash is 0. So: `OnActivate(guid, owner|nil,
fArg, env)`, and `OnDeactivate` the same.

## 5. The `_SYS` functions

The bootstrap chunk (string at `0xBB4EE0`):

```lua
_G._MODULES = {}; _MODULESMETATABLE = { __index = _SYS._MODULEINDEX };
function _G.import(module) return _SYS._IMPORT(getfenv(2), module); end;
function _G.dynamic_import(module, callbackfunc, callbackdata)
  return _SYS._DYNAMIC_IMPORT(_SYS._GETFENV(2) or _G, module, callbackfunc, callbackdata); end;
function _G.inherit(module) return _SYS._INHERIT(getfenv(2), module); end;
function _G.dynamic_remove(module) return _SYS._DYNAMIC_REMOVE(_SYS._GETFENV(2), module); end;
```

`_MODULES` is a plain table with no metatable; `_MODULESMETATABLE` is set only on module envs (state 2;
no shipped Lua references it). A module name is a string (or a number, through `tostring`); a
lightuserdata value or a userdata address is used directly as the hash.

- **`_IMPORT` (`0x5AE2D0`)**: `rawset(env, name, registry[res+0x40])` for the `{hash(name),
  0x42498680}` resource; it returns nothing (so `local x = import("m")` is nil) and never checks the
  state — a module at state 2 binds its unrun env, one never built binds nil. A name with no resource
  crashes (no null check; AV `0x5AE372`, v1.1 `0x5AE362`).
- **`_INHERIT` (`0x5AE3B0`)**: appends the base env to `env[2]` (`luaL_ref(env[2], base)`, so in call
  order, duplicates appended again) and `rawset(env, name, base)`; nothing is copied, no metatable is
  set, it returns nothing. It finds the caller by `hash(env[1])` and, through `0x59C790` →
  `0x24833A0`, marks the base in the caller's DEPS-children mask (`+0x38`/`+0x3C`, reader not read) and
  adds one class-3 reference to every resource in the base's DEPS subtree (not the base itself;
  purpose SPECULATIVE). A missing base resource crashes (`0x5AE451`); a base never built appends
  nothing and binds nil. With an INFO inherit count of 0, `env[2]` does not exist (luaL_ref on nil,
  INFERRED to crash).
- **`_MODULEINDEX` (`0x5AEB90`, `__index(t, key)`)**: for i = 1, 2, … over `rawget(t[2], i)` until nil,
  a non-raw `luaV_gettable(base, key)` (so each base's own fields, then its own `env[2]` chain); the
  first non-nil wins; last, a RAW read of the running thread's globals (`l_gt`, `0x5AEC9A`). Every
  base chain ends in that raw globals read, so a global shadows a key only a later base defines. The
  loop grows the stack 2 slots per base without `lua_checkstack` (INFERRED overflow past ~8 bases).
- **`_GETFENV` (`0x5AE160`)**: `getfenv` except: a C function returns its own env; a level with no
  stack frame returns nil (stock raises); a tail call raises `"no function environment for tail call
  at level %d"`; a negative level is an argerror; and `rawget(env, "__fenv")`, when non-nil, is
  returned instead of the env.
- **`_DYNAMIC_IMPORT` (`0x5AE580`)**: the importer is the resource named `rawgeti(env, 1)` (a NULL
  importer crashes in `0x59C820`, v1.1 AV `0x59C81A`). `0x59C820` keeps a dynamic-children array on
  the importer (`+0x20`, `{res*, u8 count}`, count `+0x29`): an existing edge counts up and adds a
  class-3 reference; a new edge find-or-creates the target and AddRefs it. These edges are not DEPS.
  The request `{res, moduleRef, envRef, cbRef, dataRef}` takes one of 128 slots at host `+0x28`
  (`0x5A1ED0`); the callback is kept only if a function and the data only if a table. It returns
  true, or false when all slots are full (the edge stays). The callback never runs in the call.
- **The dynamic-import dispatcher (`0x5A1FA0` → `0x2471CE0`)**, at the end of every pump, per slot:
  at state 5 it pcalls `_SYS._IMPORT(importerEnv, module)` (binding the module into the importer's
  env, errors popped) and then `cb(<data values in lua_next order>, registry[res+0x40])` (`0x5A06B0`);
  at state F or resource status 3, `cb(<data values>, nil)`; at status 2 not yet ready, it queues the
  target. So even an already-loaded module's callback comes on the next pump.
- **`_DYNAMIC_REMOVE` (`0x5AEA50`)**: name string/number, or a module table (its `[1]`); with the
  importer `hash(env[1])` and the edge found (else nothing), the count drops; at 0 every string key of
  the importer env whose pandemic hash equals the target's is set to nil (`0x5A37E0` → `0x2464790`;
  the nil store INFERRED), then one class-3 release (`0x59C4E0(target, flag, 0, -1, 1, 0)`), Deinit at
  0 as in §3.

## 6. Queueing and the pump

- **Boot (`0x4C05C6..0x4C05EC`)**: `gamebootstrap` (`0x40CC2CB3`) when `[0x1175C5A]` is set, else
  `shellbootstrap` (`0x49031655`), queued directly (no AddRef). `gamebootstrap`'s first AddRef gives it
  the permanent flag `0x10`.
- **`Sys.RequiredAsset(name, type, prio, b)`** (`0x5E51F0` → `0x4C28F0`; body from Xbox `0x82218B80`):
  appends `{nameHash, typeHash, prio, b}` to the game state's list (`+0x50`, count `+0x54`), raises
  `+0x5C` to max(prio) + 1, returns true. The processor (`0x4C29C0`) takes one priority level at a
  time from the highest: a missing resource or status 3 is dropped; status 2 or 4 is dropped and, for a
  script, queued; when the level is done the next lower one is requested (`0x873F20(key, 3)`
  find-or-create + AddRef, or `0x8741A0` when `b`). `levelbootstrap` asks for the layer
  `<level>_base` at −2 and the master script at −3, so the master is requested once the base layer
  is done.
- **Queue (`0x59CD30`)**: a no-op when flag `0x20` is set; otherwise the resource goes to the FRONT of
  host `+0x20`, flag `0x20` is set, and its DEPS children are queued too — so children sit ahead of
  their parent.
- **Pump (`0x5A2BC0`)**, once per host tick (`0x5A1890`, single call `0x5A1998`): every queued resource
  is stepped (`step(res, 1)`, one pass counter `[0x1175F2C]` bump per root) and unlinked at state 5,
  F or status 3; then the dynamic-import dispatcher, then the layer request poll (`0x5A28F0`).
- **Stepper (`0x59CD70`)**: a state ≤ 0 is not stepped; a node already visited this pass returns (how
  DEPS cycles terminate). Target = min(5, every child's state), a child at F or status 3 sends the
  parent to F; then `while s ≤ target { s++; run the step for the new state }` — 2 builds the env, 3
  runs the body, 4 runs `Init` and sets 5. So a body runs once its children are ≥ 2 (env built), Init
  once they are ≥ 3; an acyclic graph goes 1 → 5 in one pass, leaves first.
- **DEPS (`0x59CF90`)**: the only source of the `+0x1C` children; each entry, duplicates included,
  adds one class-3 reference (creating + AddRef'ing a missing child); a child takes the parent's
  `0x10` flag. INFO: one u8 (not checked), u16 length, the name, u16 presize (`+0x2C`), u8 inherit
  count (`+0x2A`).
- **Body**: BINN is copied raw (`+0x24`, size `+0x30`) and loaded with `luaL_loadbuffer(buf, size,
  INFO name)` — no `@`/`=` prefix (`0x5A1490`); an empty buffer or a load error pops the message and
  the resource goes to F. The shipped BINN payloads are LuaQ (Lua 5.1, LE, 4-byte float).

## 7. Open

- The string `0x5A35F0` sets to nil (through resolver `0x1A53F50`).
- What reads the `_INHERIT` mask at `+0x38`; who clears the queued flag `0x20` before a re-queue.
- The PC `Sys.RequiredAsset` body past its prefix (the Xbox twin was read).
