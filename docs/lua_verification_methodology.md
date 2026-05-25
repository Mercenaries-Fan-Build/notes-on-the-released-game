# Lua Verification Methodology — Mercenaries 2

**Purpose:** Repeatable, evidence-based reverse engineering for embedded Lua 5.1.2 (float build) in the cracked retail EXE and game archives. Prevents naive byte-pattern matching that misaligns on x86 instruction boundaries or VM opcode boundaries.

**Canonical EXE:** `output/patched/Mercenaries2.exe` — **53,482,288 bytes**, image base **0x00400000**.

**Automation:**

| Tool | Role |
|------|------|
| `tools/verify_lua_vas.py` | Pass/fail table for critical C API VAs (E8 callers, prologues, cdecl wrappers) |
| `tools/lua_bytecode_scan.py` | Header-validated chunk parse; aligned `code[]` only |
| `tools/lua_capi_audit_v2.py` | Broad string/registration sweep (discovery, not sole proof) |
| `tools/extract_all_scripts.py` | UCFX `scripts_vz` → per-chunk bytecode + `luac -l -l` |
| `tools/lua_script_chunks.py` | Split `LuaQ` regions in a block file (string harvest; not opcode decode) |

---

## 1. Inventory: Verified vs Speculative Claims

### 1.1 Corrected mistakes (must not regress)

| Wrong VA | Was claimed to be | Actually is | How verified |
|----------|-------------------|---------------|--------------|
| **0x0085F050** | `luaL_loadbuffer` | **`luaL_typerror`** | 52 E8 callers vs 3 for loadbuffer; `"bad argument #%d"` string @ 0x00BE8B84; **not** called from `luaB_loadstring` |
| **0x00868AD0** | `lua_pcall` | **`luaD_pcall`** (internal) | `luaB_pcall` @ 0x008615F0 calls **this** VA, not 0x0085DF50; public `lua_pcall` has more callers (10 vs 4) |

Early agent scripts (`tools/agent_b_lua_va_finder*.py`) already suspected 0x860240 / 0x85DF50 but some docs still propagated the wrong mapping until **2026-05-20** cross-check (`docs/lua_capi_comprehensive_audit.md`, `docs/lua_engine_bindings_audit.md`, `tools/dlc_enable_asi/dlc_enable.c`).

### 1.2 Verified facts (EXE 53,482,288)

| Item | Value | Confidence | Evidence |
|------|-------|------------|----------|
| `luaL_loadbuffer` | **0x00860240** | **High** | 3 E8 callers, all `add esp, 8`; `luaB_loadstring` @ 0x00861048 |
| `lua_pcall` | **0x0085DF50** | **High** | ≥10 E8 callers, stack cleanup `add esp, 4` / `pop` |
| `luaD_pcall` | 0x00868AD0 | High | Called from `luaB_pcall` @ 0x861658, 0x861798 |
| `luaL_typerror` | 0x0085F050 | High | High caller count; arg-error strings |
| `luaB_loadstring` | 0x00860FC0 | High | cdecl wrapper; internal call to loadbuffer |
| `luaB_pcall` | 0x008615F0 | High | Uses `luaD_pcall`, not `lua_pcall` |
| `print` (base lib) | 0x006D5640 | High | **`33 C0 C3`** stub (`xor eax,eax; ret`) |
| LTCG `luaL_loadbuffer` | EAX=name, EDX=L, stack=[buff, sz] | High | Multiple callers agree |
| LTCG `lua_pcall` | EAX=L, ECX=errfunc, EDI=nresults, stack=[nargs] | High | ≥2 callers (`verify_lua_vas.py` uses ≥10) |
| `lua_State` +0x08 = `top` | — | Medium | Used in working `dlc_enable.c` injection |
| `TValue` = 8 bytes (value + tt) | — | Medium | Hook code + Lua 5.1 float build |
| TString payload @ **+16** | — | Medium | `dlc_enable.c` `Hook_Print`; **not** re-derived from `lstring.c` in this pass — treat as hook-validated, re-check if prints garble |
| Game bytecode header | **`\x1bLuaQ`** + LE, 4-byte int/size_t/number | High | `docs/dlc_bootstrap_implementation.md`, pipeline `luac` |
| Scripts live in WAD/UCFX | Not as raw `\x1bLua` in whole `.wad` | High | `vz-patch.wad`: substring `LuaQ` without `\x1b` is **false positive** (85795058); real chunks in decompressed `scripts_vz` blocks |

### 1.3 Speculative or low-confidence (do not hardcode without re-proof)

| Claim | Status | Notes |
|-------|--------|-------|
| Individual `lua_getfield` / `lua_push*` VAs from pattern tables | Speculative | Use string xref or ≥2 call sites |
| `luaL_loadstring` as separate VA | Unclear | May be merged/inlined into `luaL_loadbuffer` (size=0 path); prefer **`luaB_loadstring`** for injection |
| Engine binding VAs from registration tables alone | Medium | Tables in `.rdata` are strong hints; confirm prologue + cdecl `lua_CFunction` |
| `exe_analysis_agent_*.md` call-site counts | Mixed | Useful narrative; **always** re-run `verify_lua_vas.py` on current EXE |
| `plugin_framework_plan_*.md` “hook lua_pcall by signature” | Unimplemented | Signature search is discovery only |
| Byte-scan for `0xE8` in `.text` without target validation | **Invalid** | Rel32 must resolve to known function start |
| Scanning for `LuaQ` / opcode bytes in uncompressed WAD | **Invalid** | Coincidental matches; require `\x1bLuaQ` header parse |

---

## 2. Instruction-boundary-aware Lua bytecode analysis

### 2.1 Rules

1. **Locate chunks only by full header:** `\x1bLua` or game format **`\x1bLuaQ`**, then version `0x51`, format `0`, endian `1`, sizes `4,4,4,4`, test number `5.0` (float).
2. **Parse structure with `lundump` order:** source name → linedefined → … → **`code[]`** (count + `count × uint32`) → constants → nested protos → debug.
3. **Decode opcodes only inside `code[]`:** each instruction is 4 bytes; opcode = `instr & 0x3F`; sanity-check `opcode < 40`.
4. **Never** scan string constant blobs or UCFX BINN metadata as instructions.
5. **False positive control:** report `invalid_opcodes / total` per proto; reject chunks with bad header or overrun.

### 2.2 Pseudocode

```
for offset in find_all(data, b"\x1bLuaQ") + find_all(data, b"\x1bLua"):
    if not parse_header(data, offset): continue
    pos = after_header
    protos = []
    queue = [pos]
    while queue:
        pos = pop(queue)
        pos = skip_proto_header_strings(pos)
        ncode = read_int32(pos); pos += 4
        for i in 0 .. ncode-1:
            instr = read_uint32_aligned(pos); pos += 4
            opcode = instr & 0x3F
            assert opcode < 40
        pos = skip_constants(pos)
        nproto = read_int32(pos); enqueue child protos
        pos = skip_lineinfo_locvars_upvals(pos)
    report(offset, protos)
```

### 2.3 Where scripts live

| Location | Format |
|----------|--------|
| `batch_vz/blocks/*scripts_vz*.block.bin` | UCFX → per-entry **`LuaQ`** bytecode |
| `fresh-rebuilt/data/vz-patch.wad` | FFCS compressed; scan **decompressed blocks**, not raw WAD grep |
| `output/patched/Mercenaries2.exe` | ~2 `\x1bLua` hits (not game script corpus) |
| `output/placements/pmc_lua_string_harvest.json` | Strings only (from `lua_script_chunks.py`) |

Preferred script analysis path: `extract_all_scripts.py` → `luac -l -l` → `lua_call_site_extractor.py` (already instruction-aligned via official disassembler).

---

## 3. Instruction-boundary-aware x86 scanning (Lua C API)

### 3.1 Algorithm

```
sections = parse_pe(exe)
text = section(".text")

function find_callers(target_va):
    for off in text where bytes[off] == 0xE8:
        dest = va(off) + 5 + rel32(off+1)
        if dest == target_va: yield va(off)

function confidence_function_start(ref_off):
    walk back up to 2KB for padding (CC/C3/C2/90) then prologue:
      55 8B EC | 83 EC xx | 50-57
    return CONFIDENCE_LOW if not found

function verify_convention(call_site, expected):
    window = bytes[call_site-48 : call_site+12]
    score = match_mov_push_pattern(window, expected)
    return score

# Promote to VERIFIED only if:
#   - len(find_callers(va)) >= 2 AND
#   - convention scores agree on >= 2 sites AND
#   - optional: string xref or luaL_Reg table agrees
```

### 3.2 Confidence levels

| Level | Criteria |
|-------|----------|
| **Verified** | ≥2 agreeing E8 call sites + stack cleanup + prologue at target |
| **Probable** | 1 call site + string xref to diagnostic in same function |
| **Speculative** | Registration table or pattern match only |
| **Rejected** | Caller convention contradicts; target is wrong symbol (typerror case) |

### 3.3 Critical VA checklist (run every time)

```bash
.venv/bin/python3 tools/verify_lua_vas.py
```

Expected: all **PASS** on `output/patched/Mercenaries2.exe` (53,482,288 bytes).

---

## 4. Plugin / injection practices (from `dlc_enable.c`)

1. **Gate on EXE size** `53482288` before any hardcoded VA.
2. **Prefer cdecl `luaB_*`** (`luaB_loadstring`, `luaB_pcall`) when stack discipline matches `lua_CFunction`; use raw LTCG only when necessary (bootstrap uses loadbuffer + pcall with inline asm documented in source).
3. **Do not call 0x0085F050** expecting loadbuffer; **do not call 0x00868AD0** expecting public `lua_pcall`.
4. **Log to disk** (`dlc_enable.log` / crash-safe file) when `pmc_log` unavailable.
5. Re-verify after any EXE patch (SecuROM crack, recompile): VAs **will** change.

---

## 5. Agent checklist (copy before editing hooks)

- [ ] EXE size == 53,482,288?
- [ ] Ran `tools/verify_lua_vas.py` — all PASS?
- [ ] Using **0x00860240** / **0x0085DF50** (not old wrong VAs)?
- [ ] LTCG convention evidenced from ≥2 callers?
- [ ] Bytecode: parsed from `\x1bLuaQ` header, not raw `LuaQ` substring?
- [ ] VM opcodes only from `code[]` array inside validated proto?
- [ ] New VA documented with call-site VAs in `docs/lua_capi_comprehensive_audit.md`?

---

## 6. Related docs

- `docs/lua_capi_comprehensive_audit.md` — VA table, base/string libs
- `docs/lua_engine_bindings_audit.md` — engine `Sys.*` / registration
- `docs/dlc_bootstrap_implementation.md` — `\x1bLuaQ` header bytes
- `tools/dlc_enable_asi/dlc_enable.c` — working injection reference
