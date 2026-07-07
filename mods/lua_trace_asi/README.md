# lua_trace.asi — Surface-B binding-call oracle

Captures the **ordered stream of Lua → engine C-binding calls** (name + args) that the original
Mercenaries 2 emits at runtime. This is **Surface B** of the modernization regression harness
(`docs/modernization/00_charter.md`): the script ↔ engine boundary.

A reimplemented engine — even one running a **newer Lua** — is correct iff, for the same scenario,
its scripts emit the **same ordered sequence of `(binding, args)`**. We don't care *how* the new VM
computes; only that it calls the engine the same way. That is what makes upgrading Lua (or any other
under-the-hood change) provably safe. **Implementation is free; behavior is gated.**

This is a standalone diagnostic ASI. It does **not** touch `pmc_bb`, `engine_trace`, or any other probe.

## How it works

1. At load (worker thread, after a 2.5 s settle so the cracked exe's `.text` is fully mapped) it walks
   the **main module PE headers** and scans `.rdata` for `luaL_Reg` tables — runs of ≥3 consecutive
   `{ const char* name, lua_CFunction f }` pairs (`name` → an identifier string in `.rdata`,
   `f` → a `.text` VA). **No hardcoded addresses**, so it is robust across exe builds (cracked /
   retail / unpacked). Derefs are bounded to `.rdata`/`.text` only — **never** the SecuROM sections
   (whose pages can be `NO_ACCESS` and would fault) — so the scan cannot crash the game.
2. By default it **skips the Lua stdlib + Scaleform/AS2 tables** (`string`, `table`, `coroutine`,
   `MovieClip`, `Array`, …) — deterministic library funcs, not engine state. `LUA_TRACE_STDLIB=1`
   includes them.
3. For each game binding it generates a 16-byte index thunk (`mov eax,i ; jmp SharedDetour`) and
   **MinHooks** the cfunc. Inline hooks are **timing-independent** — they work regardless of when the
   Lua closures were created, unlike a `luaL_Reg` pointer swap (which only works pre-registration).
4. `SharedDetour` reads the binding index (EAX) and `lua_State*` (cdecl arg), calls `Record`
   (ZERO I/O — reads `argc` + up to 4 args off the Lua stack into a lock-free ring), then tail-jumps
   to the real binding via its MinHook trampoline.
5. A watcher thread drains the ring to **`lua_trace.ndjson`** next to the exe.

Measured surface on the current dump: **~1216 game bindings across 53 tables** (Player 107, Hud 114,
Object 87, World 80, Ai 66, Vehicle 40, Event, Weapon, Debug, …). Full reference, with cfunc RVAs and
namespaces-per-table, is in `reference/binding_map.json` (host-side only; the ASI scans live).

## Build

```bash
# i686 MinGW (C:\Users\Shadow\mingw32\bin) + GnuWin32 make on PATH
make
```

Produces `lua_trace.asi` (32-bit DLL). MinHook is the vendored `submodules/minhook`.

## Deploy

Drop `lua_trace.asi` into `<game>/scripts/` alongside the Ultimate ASI Loader (`dinput8.dll`) and
`cruise.asi` (see `docs/asi_loader_setup.md`). Run the game. The trace appears as
`<game>/lua_trace.ndjson`.

## Output schema (`lua_trace.ndjson`)

One JSON object per binding call, in call order:

```json
{"seq":12041,"ms":58213,"fn":"SetCash","rva":"0x1df480","argc":1,"args":[{"t":"num","v":800000}]}
{"seq":12042,"ms":58213,"fn":"Post","rva":"0x5f69f0","argc":2,"args":[{"t":"str","v":"CashAdded"},{"t":"tt5","p":"0x1a3f2c80"}]}
```

- `seq` — total call order (monotonic). `ms` — ms since load.
- `fn` — binding name. `rva` — cfunc RVA = **unique identity** (disambiguates names shared across
  namespaces, e.g. `Create`, `GetPosition`).
- `args[].t` — `num` (Lua number; this build's `lua_Number` is **float**), `str`, `bool`, `nil`, or
  `tt<N>` (table/func/userdata/thread — pointer only). Up to 4 args captured.
- Lines beginning `{"_log":...}` are diagnostics; `{"warn":...}` flags ring overflow.

## Live offset tuning (env vars)

Lua 5.1 `lua_State` offsets are confirmed where possible and overridable for live x32dbg tuning:

| Env | Default | Meaning |
|-----|---------|---------|
| `LUA_TRACE_TOP_OFF`  | `0x08` | `lua_State.top`  (confirmed via `dlc_enable.asi`) |
| `LUA_TRACE_BASE_OFF` | `0x0C` | `lua_State.base` (inferred; see below) |
| `LUA_TRACE_TSTR_OFF` | `0x10` | `TString` → char data |
| `LUA_TRACE_STDLIB`   | `0`    | `1` = also hook stdlib/Scaleform tables |

**`base` self-check:** if the base offset is wrong, `argc = (top-base)/8` comes out insane; `Record`
detects that (`argc<0 || >250`) and emits the call with `"argc":-1` and **no args** — the name/order
stream stays correct regardless. So a wrong base degrades to name-only tracing, never a crash. To
confirm `base`: capture a known call (e.g. `SetCash`), check `argc` matches the script, adjust env.

## Validation workflow (the point of the tool)

1. **Golden capture** — run a scripted scenario (a mission, the cheat-stockpile menu, a wardrobe swap)
   on the original exe with this ASI loaded → `lua_trace.ndjson` golden.
2. **Replay** — drive the same scenario in the new Rust engine's embedded VM; emit the same NDJSON.
3. **Diff** — compare the `(fn, args)` sequences. Divergence = a behavioral regression localized to an
   exact call. (`num` values use float-equality tolerance, matching the original's float `lua_Number`.)

This gates Phase 3 (ECS + scripting) and de-risks the Lua 5.1 → 5.4 migration: a migrated script that
produces an identical binding trace is, by definition, behavior-preserving.

## Known limits / v2

- **Namespace** isn't recovered from the table alone (`fn`+`rva` are unambiguous; namespace is
  cosmetic). Offline enrichment: resolve `luaL_register(L, "<ns>", tbl)` call sites → annotate
  `binding_map.json`.
- **Args capped at 4**, strings at 23 bytes. Raise `MAX_ARGS`/`STRCAP` if a key binding needs more.
- **Return values** not captured (entry-only). A v2 could hook the trampoline tail for `(ret)`.
- **Alternative design** (one VM-dispatch hook on `luaD_precall` + pointer→name map) would collapse
  ~1216 hooks into 1; deferred until the `CClosure.f` / `CallInfo` offsets are confirmed live, since
  the per-binding inline approach needs no such offsets and is proven (`resprobe.c`).
