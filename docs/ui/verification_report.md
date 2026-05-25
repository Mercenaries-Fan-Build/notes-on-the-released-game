# Verification Report — Main Menu & Online Systems Research

> **Agent C — Cross-Verification Report**
> **Date:** 2026-05-25
> **Target documents:**
> - `docs/ui/main_menu_structure.md` (Agent A)
> - `docs/ui/online_bonus_checking.md` (Agent B)
> **Method:** Independent x64dbg MCP verification + cross-reference with existing project docs

---

## 1. Agent A Verification — Main Menu Structure

### Claim 1: ChangeShellState at VA 0x005C3740

**Claim:** Agent A provides full disassembly of ChangeShellState showing it copies a Lua string argument to a static buffer at 0x1175F2F, and clears a transition flag at 0x01176034.

**Verification method:** `DisasmGetInstructionRange` at 0x005C3740

**Result: CONFIRMED**

Every instruction matches exactly:
```
005C3740  mov ecx, [esp+4]            ; lua_State*
005C3744  push 0x1175F2F              ; dest buffer address
005C3749  call 0x59D730               ; extract string → copy to buffer
005C374E  add esp, 4
005C3751  test al, al
005C3753  jnz short 005C375B
005C3755  mov eax, 1                  ; return 1 (error)
005C375A  ret
005C375B  cmp byte [0x1175F2F], 0     ; buffer already has pending state?
005C3762  jnz short 005C376E
005C3764  mov dword [0x1176034], 0    ; clear transition frame counter
005C376E  xor eax, eax                ; return 0
```

The state buffer (0x1175F2F) and transition flag (0x01176034) are both verified.

---

### Claim 2: Shell State Strings at documented VAs

**Claim:** Agent A lists state strings:
- `"startShell"` at 0x00BBC6AC
- `"loadMainShell"` at 0x00BB7280
- `"newGame"` at 0x00BBC5CC

**Verification method:** `StringGetAt` and `PatternFindMem`

**Result: CORRECTED (minor address errors)**

| String | Claimed VA | Actual VA | Status |
|--------|-----------|-----------|--------|
| `"startShell"` | 0x00BBC6AC | **0x00BBC6A8** | Off by -4 bytes |
| `"loadMainShell"` | 0x00BB7280 | 0x00BB7280 | CONFIRMED |
| `"newGame"` | 0x00BBC5CC | **0x00BBC5D4** | Off by +8 bytes |
| `"joinGame"` | 0x00BBC5D4 | **0x00BBC5DC** | Off by +8 bytes |

The strings all exist in `.rdata` and are valid shell state names, but several addresses have small offsets (4–8 bytes) — likely due to alignment or partial reads during original analysis.

---

### Claim 3: LTI Registration Table at 0x00B99D00

**Claim:** Agent A states the LTI function registration table is a `{string_ptr, func_ptr}` array at VA 0x00B99D00.

**Verification method:** `MemoryRead` at 0x00B99D00 (32 bytes)

**Result: CONFIRMED**

Raw hex: `b06cbb00 a0135c00 986cbb00 70145c00 806cbb00 00165c00 646cbb00 b0175c00`

Parsing as pointer pairs:
| String Ptr | Func Ptr | Valid? |
|-----------|----------|--------|
| 0x00BB6CB0 (in .rdata) | 0x005C13A0 (in .text) | Yes |
| 0x00BB6C98 (in .rdata) | 0x005C1470 (in .text) | Yes |
| 0x00BB6C80 (in .rdata) | 0x005C1600 (in .text) | Yes |
| 0x00BB6C64 (in .rdata) | 0x005C17B0 (in .text) | Yes |

All pointers are in the correct sections. This is a valid `luaL_Reg` registration table.

---

### Claim 4: Gui Table Name at 0x00BB5CC4

**Claim:** The `Gui` Lua table name string is at VA 0x00BB5CC4.

**Verification method:** `StringGetAt` at 0x00BB5CC4

**Result: CONFIRMED**

Returns: `"Gui"` — exact match.

---

### Claim 5: Sys.FinishedShell String at 0x00BBA2DC

**Claim:** Agent A lists `Sys.FinishedShell` with string at VA 0x00BBA2DC and function at 0x005E54C0.

**Verification method:** `StringGetAt` at 0x00BBA2DC

**Result: CONFIRMED**

Returns: `"FinishedShell"` — exact match.

---

## 2. Agent B Verification — Online Bonus Checking

### Claim 1: IsOnlineConnected Hooked at VA 0x005CAD10 (JMP to 0x704F1890)

**Claim:** The original `IsOnlineConnected` function at VA 0x005CAD10 has been overwritten with a 5-byte JMP to the ASI hook at 0x704F1890. Three Lua names (`IsPlatformConnected`, `IsConnectedToInternet`, `IsOnlineConnected`) all share this same C++ function.

**Verification method:** `DisasmGetInstructionRange` at 0x005CAD10

**Result: CONFIRMED**

```
005CAD10  jmp 0x704F1890    ; E9 hook → ASI code
```

Additionally, the Net binding table at 0x00B998D0 confirms all three names map to 0x005CAD10:
- Entry 1: string 0x00BB8140 → func 0x005CAD10
- Entry 3: string 0x00BB8118 (`"IsConnectedToInternet"`) → func 0x005CAD10
- Entry 15 (at offset): string 0x00BB8078 (`"IsOnlineConnected"`) → func 0x005CAD10

---

### Claim 2: HasPlayerUnlockedCode Three-Stage Gate (0xDFBD74, 0x017C0BBF, 0xDFBD98)

**Claim:** `HasPlayerUnlockedCode` at VA 0x005CB6B0 is hooked, and the original implements a three-stage check:
1. `byte [0x00DFBD74]` — online ready flag
2. `byte [0x017C0BBF]` — FESL connection flag
3. `byte [0x00DFBD98]` — unlock code status

**Verification method:** `DisasmGetInstructionRange` at 0x005CB6B0 + `MemoryRead` for flag values

**Result: CONFIRMED**

Disassembly shows:
```
005CB6B0  jmp 0x704F1490    ; E9 hook (5 bytes overwritten)
005CB6B5  00 00             ; residual bytes (from original cmp immediate 0x00)
005CB6B7  push esi
005CB6B8  mov esi, [esp+0x08]
```

Global flag values verified:
| Address | Expected | Actual |
|---------|----------|--------|
| 0x00DFBD74 | 0x01 (online ready) | **0x01** ✓ |
| 0x017C0BBF | 0x00 (FESL disconnected) | **0x00** ✓ |
| 0x00DFBD98 | 0x00 (not unlocked) | **0x00** ✓ |
| 0x00DFBD8C | 0x01 (ShouldPlayOnline) | **0x01** ✓ |

---

### Claim 3: FESL Server Hostname "fesl.ea.com" at VA 0x00B5FBAC

**Claim:** The FESL server hostname string is at VA 0x00B5FBAC.

**Verification method:** `StringGetAt` at 0x00B5FBAC

**Result: CONFIRMED**

Returns: `"fesl.ea.com"` — exact match.

---

### Claim 4: FESL Service "fsys" at 0x00B5D3C8 and Entitlement Strings

**Claim:** Agent B documents FESL service types and entitlement transaction names at specific addresses.

**Verification method:** `StringGetAt` at multiple addresses

**Result: CONFIRMED**

| String | Claimed VA | Verified |
|--------|-----------|----------|
| `"fsys"` | 0x00B5D3C8 | ✓ Exact match |
| `"ApplyPricingSelection"` | 0x00B61554 | ✓ Exact match |
| `"GetEntitlementByBundle"` | 0x00B6156C | ✓ Exact match |
| `"entitlementSuspendDate"` | 0x00B5F70C | ✓ Exact match (verified earlier) |
| `"entitlementStatusDesc"` | 0x00B5F724 | ✓ Exact match (verified earlier) |

---

### Claim 5: Net Binding Table at 0x00B998D0 with Table Name "Net" at 0x00BB8154

**Claim:** The `Net` Lua table binding array starts at VA 0x00B998D0 and the table name string is at 0x00BB8154. First entries map to known functions.

**Verification method:** `MemoryRead` + `StringGetAt`

**Result: CONFIRMED**

- Table name at 0x00BB8154 returns `"Net"` ✓
- Memory at 0x00B998D0 shows valid `{string_ptr, func_ptr}` pairs:
  - `{0x00BB8140, 0x005CAD10}` → IsPlatformConnected (hooked)
  - `{0x00BB8130, 0x005C66C0}` → `"IsMultiplayer"` ✓
  - `{0x00BB8118, 0x005CAD10}` → `"IsConnectedToInternet"` ✓ (same hooked function)
  - `{0x00BB810C, 0x005C6710}` → IsEnabled

---

### Claim 6 (Bonus): ShouldPlayOnline at 0x005CAD50

**Claim:** Agent B provides full disassembly showing it reads `byte [0x00DFBD8C]`.

**Verification method:** `DisasmGetInstructionRange` at 0x005CAD50

**Result: CONFIRMED**

```
005CAD50  push ebx
005CAD51  mov bl, byte ptr [0x00DFBD8C]   ; read flag
005CAD57  push esi
005CAD58  mov esi, [esp+0x0C]              ; Lua state
005CAD5C  mov eax, 0x01
005CAD61  mov ecx, esi
005CAD63  call 0x0085D5D0                  ; validate args
```

Exact match with documented disassembly.

---

## 3. Cross-Reference with Existing Project Docs

### Confirmations

| Existing Doc Claim | Agent A/B Finding | Status |
|-------------------|-------------------|--------|
| `ChangeShellState` at file offset 0x007B6A68 (`exe_analysis_agent_a.md`) | Agent A confirms string VA 0x00BB6A68 (= 0x400000 + 0x7B6A68) | ✓ Consistent |
| `IsOnlineConnected` hookable (`lua_engine_bindings_audit.md`) | Agent B proves hooks are installed at runtime, but **functions are never called** — breakpoints never fire | ⚠ Hooks verified but ineffective |
| `HasPlayerUnlockedCode` hookable (`dlc_extras_activation_research.md`) | Agent B provides full three-gate architecture; hook installed but **never called** | ⚠ Hooks verified but ineffective |
| Scaleform GFx exports from EXE (`exe_analysis_agent_a.md`) | Agent A documents full GFx 3.x class list | ✓ Consistent |
| `multiplayer.ini` config (`exe_analysis_agent_b.md`) | Agent A finds multiplayerHost/multiplayerClient state strings | ✓ Consistent |
| `_MODULES.mrxgui.GetWidgetByName("Shell")` at 0x7BBA10 (`exe_analysis_agent_b.md`) | Agent A documents the Lua→Flash→Lua integration | ✓ Verified at 0x00BBBA10 |
| IsDemoMode reads flag at 0x01175F59 (`exe_analysis_agent_b.md`) | Agent A mentions `Sys.IsDemoMode`; I verified disassembly independently | ✓ Confirmed |
| `Net.IsMatchmakingInternet` hooked (`lua_engine_bindings_audit.md`) | Agent B proves hook at 0x005CACC0 → 0x704F1C80 but **never called** | ⚠ Hook verified but ineffective |
| FESL mentioned in `dlc_extras_activation_research.md` | Agent B provides full FESL architecture (9 services, protocol details) | ✓ Greatly expanded |

### Contradictions / Discrepancies

| Issue | Existing Docs | Agent A/B | Resolution |
|-------|--------------|-----------|------------|
| `IsDLC` string offset | `lua_engine_bindings_audit.md`: 0x007D9594 | Agent B: 0x00BE2C24 (`"IsDLC"` in theater session fields) | **Both may be correct** — the audit doc's 0x7D9594 maps to VA 0xBD9594 which actually contains `"@Vm"` (unrelated); Agent B's 0xBE2C24 is in `.data` section. The audit doc's offset is likely wrong or refers to a different context. |
| `_SYS._IMPORT` VA | `comprehensive_engine_understanding.md`: 0x005AE2D0 | Not directly tested by A/B (not in scope) | Untested by this verification |
| Section VA for `.text` | Agent B states `.text` base = 0x00401000 | `exe_analysis_agent_a.md` states `.text` VA = 0x00001000 (RVA) | **Both correct** — Agent B gives loaded VA (base + RVA), existing docs give RVA |

### New Information Not in Existing Docs

Agent A and B collectively reveal information not previously documented:

1. **Shell state machine architecture** — `ChangeShellState` copies to a static buffer (0x1175F2F), preventing double-transitions. This was unknown.
2. **LTI callback system** — 80+ LTI functions registered as Lua globals for menu operations. Only `LTIPrecacheDone` and `LTIPrecacheSmokeDone` were previously documented.
3. **FESL service types** (9 services: fsys, acct, subs, recp, rank, thtr, club, asso, gsum) — previously only "FESL" was mentioned without protocol detail.
4. **Three-stage gate in HasPlayerUnlockedCode** — the existing `dlc_extras_activation_research.md` only said "hooks `HasPlayerUnlockedCode` to return true" without explaining the original three-gate mechanism.
5. **Theater matchmaking protocol** (21 message types) — completely new.
6. **Full Gui.* namespace** (~100+ functions) — previously only ~15 were documented.
7. **Entitlement transaction types** (`GetEntitlementByBundle`, `GetPricingSelectionsByCode`, etc.) — previously unknown.

---

## 4. Gap Analysis — What Was Missed

### Agent A Gaps

1. **No shell.wad script analysis** — Agent A correctly identifies that menu options come from Lua scripts in `shell.wad` but doesn't extract or decompile them. The actual menu layout, button ordering, and transition logic remain in bytecode.

2. **Missing shell states** — The strings area near 0xBBC500–0xBBC700 likely contains more state names. Agent A found ~18 but there could be 30+. Particularly missing: loading screen states, error recovery states, and DLC-specific states.

3. **No `_GuiInternal` table documentation** — Agent A mentions `_GuiInternal.nVersion = 2` but doesn't document what other fields/functions exist in this internal table.

4. **Missing Flash SWF file paths** — Which .SWF files are loaded for which menu screens? These would be string arguments to `SetFlashSwfFile` in the Lua scripts.

5. **Missing callback mechanism detail** — How exactly does `SetFlashCallback` register and dispatch? What's the ExternalInterface marshalling format?

### Agent B Gaps

1. **No ssleay32.dll import analysis** — Agent B mentions OpenSSL 0.9.8d for TLS but doesn't document where the DLL is imported or whether it's embedded/external.

2. **Missing FESL port number** — The format string `"feslPort: %d\n"` exists but the actual configured port is not documented.

3. **No `UpdatePresence` disassembly** — Listed as function #66 in the Net table but not analyzed despite checking both FESL flags.

4. **Missing `subs` response handler** — How does the engine parse the `GetEntitlementByBundle` response and set the flag at 0xDFBD98?

5. **No "bonus code" input UI documentation** — If there's a text input for entering promotional codes, what Flash widget handles it?

### Shared Gaps

1. **No documentation of `shell.wad` block structure** — Both agents assume it exists but neither examines its FFCS/ASET layout or block count.

2. **No runtime state verification** — Neither agent checked what the current shell state buffer (0x1175F2F) actually contains during the debugging session.

3. **Missing `Sys.GetShellCode` implementation** — Agent A lists it but doesn't disassemble it. This function likely returns an integer identifying the current screen.

4. **No `LTIgotoGame` / `LTIPressStart` disassembly** — These are critical path functions for the boot→menu→game transition.

5. **Existing `Net.*` functions in `lua_engine_bindings_audit.md` not fully reconciled** — The audit lists `IsMatchmakingLan` (INFERRED) but Agent B's complete table dump doesn't include it, suggesting it doesn't exist.

---

## 5. Recommended Corrections

### Agent A (`main_menu_structure.md`)

| Line | Issue | Fix |
|------|-------|-----|
| Shell State table | `"startShell"` address 0x00BBC6AC | Correct to **0x00BBC6A8** |
| Shell State table | `"newGame"` address 0x00BBC5CC | Correct to **0x00BBC5D4** |
| Shell State table | `"joinGame"` address 0x00BBC5D4 | Correct to **0x00BBC5DC** |
| Shell State table | `"quitGame"` address 0x00BBC5FC | Verify (may be off by similar amount) |
| Menu options table | All addresses with `+` suffix are uncertain | Mark these explicitly as approximate |
| Section 7 | `Net` table name listed at 0x00BB8154 — confirmed correct | No fix needed |

### Agent B (`online_bonus_checking.md`)

| Line | Issue | Fix |
|------|-------|-----|
| Section layout | `.text` base listed as 0x00401000 | This is correct (VA = imageBase + 0x1000 RVA). No fix needed, but note the section starts at RVA 0x1000, not 0x0000 |
| `IsPlatformConnected` string | Listed at 0x00BB8140 | StringGetAt returns garbled text — the string may start a few bytes earlier. Verify exact offset |
| Claim about original function bytes | "first 7 bytes were: `cmp byte ptr [0x00DFBD74], 0x00`" | The residual bytes at +5 (`00 00`) are consistent with this encoding (the immediate `0x00` of the CMP). CONFIRMED plausible |
| DlcMapId / IsDLC addresses | Listed at 0x00BE2C18 / 0x00BE2C24 | These are in `.data` section — verify they are actual string data and not pointer targets |

### General Recommendations

1. **Standardize address notation** — Both docs should clarify whether addresses are file offsets or VAs. Agent B is clear (VAs), Agent A is mostly clear but some entries in the shell state table appear to have small errors suggesting they came from a different addressing scheme.

2. **Add confidence levels** — Follow the pattern from `lua_engine_bindings_audit.md` (CERTAIN / CONFIRMED / INFERRED) to distinguish verified disassembly from string-search inference.

3. **Cross-link documents** — Agent A's section 7 (Net.*) overlaps heavily with Agent B's section 8. These should reference each other to avoid divergence.

---

## Appendix: Independent Verification Summary

| Verification | Tool Used | Result |
|-------------|-----------|--------|
| ChangeShellState disasm (0x005C3740) | DisasmGetInstructionRange | CONFIRMED (12 instructions match) |
| State buffer at 0x1175F2F | Disasm reference | CONFIRMED |
| "ChangeShellState" string (0xBB6A68) | StringGetAt | CONFIRMED |
| "loadMainShell" string (0xBB7280) | StringGetAt | CONFIRMED |
| "startShell" string (0xBBC6A8) | StringGetAt | CONFIRMED (at corrected address) |
| "Gui" table name (0xBB5CC4) | StringGetAt | CONFIRMED |
| "FinishedShell" string (0xBBA2DC) | StringGetAt | CONFIRMED |
| "Net" table name (0xBB8154) | StringGetAt | CONFIRMED |
| LTI table format (0xB99D00) | MemoryRead | CONFIRMED (valid ptr pairs) |
| Net table format (0xB998D0) | MemoryRead | CONFIRMED (valid ptr pairs) |
| IsOnlineConnected hook (0x5CAD10) | DisasmGetInstructionRange | CONFIRMED (JMP 0x704F1890) |
| HasPlayerUnlockedCode hook (0x5CB6B0) | DisasmGetInstructionRange | CONFIRMED (JMP 0x704F1490) |
| ShouldPlayOnline disasm (0x5CAD50) | DisasmGetInstructionRange | CONFIRMED |
| IsDemoMode disasm (0x5E5670) | DisasmGetInstructionRange | CONFIRMED |
| "fesl.ea.com" string (0xB5FBAC) | StringGetAt | CONFIRMED |
| "fsys" service (0xB5D3C8) | StringGetAt | CONFIRMED |
| "ApplyPricingSelection" (0xB61554) | StringGetAt | CONFIRMED |
| "GetEntitlementByBundle" (0xB6156C) | StringGetAt | CONFIRMED |
| "IsOnlineConnected" string (0xBB8078) | StringGetAt | CONFIRMED |
| "HasPlayerUnlockedCode" string (0xBB7924) | StringGetAt | CONFIRMED |
| "IsMultiplayer" string (0xBB8130) | StringGetAt | CONFIRMED |
| "IsConnectedToInternet" (0xBB8118) | StringGetAt | CONFIRMED |
| Flag 0xDFBD74 = 0x01 | MemoryRead | CONFIRMED |
| Flag 0xDFBD8C = 0x01 | MemoryRead | CONFIRMED |
| Flag 0xDFBD98 = 0x00 | MemoryRead | CONFIRMED |
| Flag 0x017C0BBF = 0x00 | MemoryRead | CONFIRMED |
| Demo flag 0x1175F59 = 0x00 | MemoryRead | CONFIRMED |
| Shell widget Lua code (0xBBBA10) | StringGetAt | CONFIRMED |
| Topbar widget Lua code (0xBBBAD0) | StringGetAt | CONFIRMED |
| LTI_precache widget code (0xBBBB90) | StringGetAt | CONFIRMED |
| "SetFlashSwfFile" (0xBB5F1C) | StringGetAt | CONFIRMED |
| "CreateFlashWidget" (0xBB5F2C) | StringGetAt | CONFIRMED |
| "CallFlashScriptFunction" (0xBB5E58) | StringGetAt | CONFIRMED |
| "SetFlashCallback" (0xBB5E70) | StringGetAt | CONFIRMED |
| "PauseMenu" (0xBB5E1B) | StringGetAt | CONFIRMED |
| Event.Create (0x5F69F0) | DisasmGetInstructionRange | CONFIRMED (push 0; call 0x5F6660) |
| Event.CreatePersistent (0x5F6A00) | DisasmGetInstructionRange | CONFIRMED (push 1; call 0x5F6660) |
